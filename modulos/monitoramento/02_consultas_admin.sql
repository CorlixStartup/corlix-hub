-- =============================================================================
-- Corlix Hub · Monitoramento · consultas do banco inteiro (só leitura)
-- Guia: modulos/monitoramento/Etapas-monitoramento.md (seção 3)
--
-- Rode como ADMIN em Database Actions › SQL (a senha é do time; o agente não
-- entra como ADMIN). Nenhuma consulta grava nada.
-- No Autonomous Database, o painel do OCI (Metrics / Performance Hub) é a fonte
-- oficial de CPU e armazenamento; estas consultas servem para ver detalhes.
-- =============================================================================

-- 1. Armazenamento usado no banco inteiro (limite Always Free: 20 GB)
select round(sum(bytes) / 1024 / 1024 / 1024, 2) as gb_usados,
       20                                        as gb_limite_always_free,
       round(sum(bytes) / 1024 / 1024 / 1024 / 20 * 100, 1) as pct_do_limite
  from dba_segments;

-- 2. Armazenamento por dono (schema)
select owner,
       round(sum(bytes) / 1024 / 1024, 1) as mb
  from dba_segments
 group by owner
 order by mb desc
 fetch first 15 rows only;

-- 3. Uso por tablespace
select tablespace_name,
       round(used_space * t.block_size / 1024 / 1024, 1)      as mb_usados,
       round(tablespace_size * t.block_size / 1024 / 1024, 1) as mb_tamanho,
       round(used_percent, 1)                                 as pct
  from dba_tablespace_usage_metrics m
  join dba_tablespaces t using (tablespace_name)
 order by mb_usados desc;

-- 4. CPU disponível para o banco
select name, value
  from v$parameter
 where name in ('cpu_count', 'sessions', 'processes');

-- 5. CPU e carga na última hora, minuto a minuto
--    "Average Active Sessions" acima de cpu_count = fila de CPU (saturação).
select to_char(begin_time, 'HH24:MI')         as minuto,
       metric_name,
       round(value, 2)                        as valor
  from v$sysmetric_history
 where metric_name in ('Host CPU Utilization (%)',
                       'Average Active Sessions',
                       'Session Count')
   and group_id = 2
 order by begin_time desc, metric_name;

-- 6. CPU por hora nos últimos 7 dias: média e pico (AWR)
select to_char(trunc(begin_time, 'HH24'), 'DD/MM HH24"h"') as hora,
       metric_name,
       round(avg(average), 1)                              as media,
       round(max(maxval), 1)                               as pico
  from dba_hist_sysmetric_summary
 where begin_time >= sysdate - 7
   and metric_name in ('Host CPU Utilization (%)', 'Average Active Sessions')
 group by trunc(begin_time, 'HH24'), metric_name
 order by trunc(begin_time, 'HH24') desc, metric_name;

-- 7. Horas com pico de CPU acima de 80% (para investigar)
select to_char(begin_time, 'DD/MM HH24:MI') as inicio,
       to_char(end_time, 'HH24:MI')         as fim,
       round(average, 1)                    as media_pct,
       round(maxval, 1)                     as pico_pct
  from dba_hist_sysmetric_summary
 where begin_time >= sysdate - 7
   and metric_name = 'Host CPU Utilization (%)'
   and maxval > 80
 order by maxval desc;

-- 8. Memória: SGA (memória compartilhada)
select name, round(bytes / 1024 / 1024) as mb
  from v$sgainfo
 where name in ('Maximum SGA Size', 'Buffer Cache Size', 'Shared Pool Size', 'Free SGA Memory Available');

-- 9. Memória: PGA (memória das sessões), agora e pico desde o último restart
select name, round(value / 1024 / 1024) as mb
  from v$pgastat
 where name in ('aggregate PGA target parameter',
                'total PGA allocated',
                'maximum PGA allocated');

-- 10. PGA média e máxima por dia nos últimos 7 dias (AWR)
select to_char(trunc(s.begin_interval_time), 'DD/MM') as dia,
       round(avg(p.value) / 1024 / 1024)              as pga_media_mb,
       round(max(p.value) / 1024 / 1024)              as pga_max_mb
  from dba_hist_pgastat p
  join dba_hist_snapshot s
    on s.snap_id = p.snap_id
   and s.dbid = p.dbid
   and s.instance_number = p.instance_number
 where p.name = 'total PGA allocated'
   and s.begin_interval_time >= sysdate - 7
 group by trunc(s.begin_interval_time)
 order by trunc(s.begin_interval_time) desc;

-- 11. Sessões abertas agora, por usuário (limite Always Free: ~30 simultâneas)
select username, status, count(*) as sessoes
  from v$session
 where type = 'USER'
 group by username, status
 order by sessoes desc;

-- 12. SQL que mais consumiram CPU nos últimos 7 dias (candidatos a otimização)
select st.sql_id,
       round(sum(st.cpu_time_delta) / 1e6, 1)     as cpu_s,
       sum(st.executions_delta)                   as execucoes,
       round(sum(st.elapsed_time_delta) / greatest(sum(st.executions_delta), 1) / 1e3, 1) as ms_por_execucao,
       max(st.parsing_schema_name)                as schema_,
       substr(max(dbms_lob.substr(t.sql_text, 120, 1)), 1, 120) as sql_inicio
  from dba_hist_sqlstat st
  join dba_hist_snapshot s
    on s.snap_id = st.snap_id
   and s.dbid = st.dbid
   and s.instance_number = st.instance_number
  left join dba_hist_sqltext t
    on t.sql_id = st.sql_id
   and t.dbid = st.dbid
 where s.begin_interval_time >= sysdate - 7
 group by st.sql_id
 order by cpu_s desc
 fetch first 15 rows only;
