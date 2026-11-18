-- =============================================================================
-- Corlix Hub · Monitoramento · consultas do schema da app (só leitura)
-- Guia: modulos/monitoramento/Etapas-monitoramento.md (seções 2 e 4)
--
-- Rode no SQL Workshop › SQL Commands do workspace WKSP_CORLIXHUB, uma consulta
-- por vez. Nenhuma consulta grava nada.
-- =============================================================================

-- 1. Espaço ocupado pelo schema, por tabela (os LOBs entram na tabela dona)
select nvl(l.table_name, s.segment_name)                       as tabela,
       max(l.column_name)                                      as coluna_lob,
       round(sum(s.bytes) / 1024 / 1024, 1)                    as mb
  from user_segments s
  left join user_lobs l
    on l.segment_name = s.segment_name
    or l.index_name   = s.segment_name
 group by nvl(l.table_name, s.segment_name)
 order by mb desc
 fetch first 20 rows only;

-- 2. Total do schema
select round(sum(bytes) / 1024 / 1024, 1) as mb_total_schema
  from user_segments;

-- 3. Tamanho das imagens dos comunicados (o maior peso da Home)
select id_comunicado,
       titulo,
       mime_type,
       round(dbms_lob.getlength(imagem) / 1024) as kb
  from comunicado
 where imagem is not null
 order by kb desc;

-- 4. Tamanho das fotos guardadas no banco (as do bucket não entram aqui)
select count(*)                                                  as fotos_no_banco,
       round(sum(dbms_lob.getlength(imagem_perfil)) / 1024 / 1024, 1) as mb,
       round(max(dbms_lob.getlength(imagem_perfil)) / 1024)      as maior_kb
  from colaborador
 where imagem_perfil is not null;

-- 5. Tempo de geração das páginas (servidor), últimos 14 dias, app 100.
--    elapsed_time é em segundos. Só abertura de página (sem Ajax nem submit).
--    Confirmar no 26.1.5 os valores de PAGE_VIEW_TYPE ('Rendering', 'Processing', 'Ajax').
select page_id,
       max(page_name)                                                    as pagina,
       count(*)                                                          as acessos,
       round(avg(elapsed_time), 2)                                       as media_s,
       round(percentile_cont(0.95) within group (order by elapsed_time), 2) as p95_s,
       round(max(elapsed_time), 2)                                       as max_s
  from apex_workspace_activity_log
 where application_id = 100
   and view_date >= sysdate - 14
   and page_view_type = 'Rendering'
 group by page_id
 order by p95_s desc;

-- 6. Chamadas Ajax mais lentas (busca, carrosséis, callbacks), últimos 14 dias
select page_id,
       request_value,
       count(*)                                                          as chamadas,
       round(avg(elapsed_time), 2)                                       as media_s,
       round(percentile_cont(0.95) within group (order by elapsed_time), 2) as p95_s
  from apex_workspace_activity_log
 where application_id = 100
   and view_date >= sysdate - 14
   and page_view_type = 'Ajax'
 group by page_id, request_value
 having count(*) >= 5
 order by p95_s desc
 fetch first 15 rows only;

-- 7. Picos: as 20 aberturas de página mais lentas dos últimos 7 dias
select view_date, page_id, apex_user, round(elapsed_time, 2) as segundos, error_message
  from apex_workspace_activity_log
 where application_id = 100
   and view_date >= sysdate - 7
 order by elapsed_time desc
 fetch first 20 rows only;

-- 8. Uso por hora (para cruzar com picos de CPU), últimos 7 dias
select to_char(trunc(view_date, 'HH24'), 'DD/MM HH24"h"') as hora,
       count(*)                                           as page_views,
       count(distinct apex_user)                          as usuarios,
       round(avg(elapsed_time), 2)                        as media_s
  from apex_workspace_activity_log
 where application_id = 100
   and view_date >= sysdate - 7
 group by trunc(view_date, 'HH24')
 order by trunc(view_date, 'HH24') desc;

-- 9. Erros registrados, últimos 14 dias
select page_id, error_message, count(*) as vezes, max(view_date) as ultima
  from apex_workspace_activity_log
 where application_id = 100
   and view_date >= sysdate - 14
   and error_message is not null
 group by page_id, error_message
 order by vezes desc
 fetch first 20 rows only;
