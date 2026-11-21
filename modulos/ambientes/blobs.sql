-- =============================================================================
-- Corlix Hub · Colunas BLOB na carga dos CSVs do backup
-- Guia: modulos/ambientes/Etapas-ambientes.md (3.2 b)
--
-- O backup grava cada BLOB em base64 (apex_web_service.blob2clobbase64, com
-- quebras de linha e sem "=" no fim). O "load table" do SQLcl tenta ler BLOB
-- como hexadecimal e recusa a linha (ORA-01465: invalid hex number).
--
-- Uso, conectado como dono do schema de destino (DEV ou UAT, nunca PRD), entre
-- o "identidades.sql ANTES" e o "identidades.sql DEPOIS":
--   @modulos/ambientes/blobs.sql ANTES    -- cria AMB_STG_<tabela>, com CLOB no lugar do BLOB
--   load table AMB_STG_<tabela> <csv>     -- um por tabela com BLOB (lista no guia)
--   @modulos/ambientes/blobs.sql DEPOIS   -- converte, grava nas tabelas e apaga o que criou
--
-- As tabelas com BLOB precisam estar vazias: não carregue o CSV delas direto.
-- =============================================================================
whenever sqlerror exit failure rollback
set serveroutput on size unlimited
set verify off
set define on

create or replace function amb_b64_blob (p_b64 in clob) return blob is
  l_blob  blob;
  l_buf   varchar2(32767);
  l_parte varchar2(32767);
  l_pos   pls_integer := 1;
  l_tam   pls_integer;
  l_n     pls_integer;
  procedure grava (p_txt in varchar2) is
  begin
    dbms_lob.append(l_blob, to_blob(utl_encode.base64_decode(utl_raw.cast_to_raw(p_txt))));
  end grava;
begin
  if p_b64 is null or dbms_lob.getlength(p_b64) = 0 then
    return null;
  end if;
  dbms_lob.createtemporary(l_blob, true, dbms_lob.call);
  l_tam := dbms_lob.getlength(p_b64);
  while l_pos <= l_tam loop
    l_parte := dbms_lob.substr(p_b64, 8000, l_pos);
    l_pos   := l_pos + 8000;
    -- tira quebras de linha e espaços; decodifica só múltiplos de 4 caracteres
    l_buf := l_buf || translate(l_parte, 'x' || chr(10) || chr(13) || chr(9) || ' ', 'x');
    l_n   := trunc(nvl(length(l_buf), 0) / 4) * 4;
    if l_n > 0 then
      grava(substr(l_buf, 1, l_n));
      l_buf := substr(l_buf, l_n + 1);
    end if;
  end loop;
  -- o backup não grava o "=" final: completa para fechar o último bloco
  if l_buf is not null then
    grava(rpad(l_buf, ceil(length(l_buf) / 4) * 4, '='));
  end if;
  return l_blob;
end amb_b64_blob;
/

declare
  l_fase varchar2(10) := upper('&1');
  l_qt   pls_integer;
  l_stg  varchar2(128);
  l_cols varchar2(32767);
  l_sel  varchar2(32767);
begin
  if l_fase not in ('ANTES', 'DEPOIS') then
    raise_application_error(-20000, 'Use ANTES ou DEPOIS.');
  end if;

  if l_fase = 'ANTES' then
    for t in (select distinct table_name
                from user_tab_cols
               where data_type = 'BLOB'
                 and table_name not like 'AMB\_%' escape '\'
                 and table_name in (select table_name from user_tables)
               order by table_name) loop
      l_stg := 'AMB_STG_' || t.table_name;
      execute immediate 'select count(*) from "' || t.table_name || '"' into l_qt;
      if l_qt > 0 then
        raise_application_error(-20001, t.table_name || ' já tem ' || l_qt
          || ' linha(s). Esvazie a tabela e não carregue o CSV dela direto.');
      end if;
      select count(*) into l_qt from user_tables where table_name = l_stg;
      if l_qt > 0 then
        execute immediate 'drop table "' || l_stg || '" purge';
      end if;
      execute immediate 'create table "' || l_stg || '" as select * from "' || t.table_name || '" where 1 = 0';
      for c in (select column_name
                  from user_tab_cols
                 where table_name = t.table_name and data_type = 'BLOB') loop
        execute immediate 'alter table "' || l_stg || '" drop column "' || c.column_name || '"';
        execute immediate 'alter table "' || l_stg || '" add "' || c.column_name || '" clob';
      end loop;
      dbms_output.put_line('Criada ' || l_stg || ': carregue nela o CSV de ' || t.table_name);
    end loop;

  else
    for s in (select table_name as stg, substr(table_name, 9) as alvo
                from user_tables
               where table_name like 'AMB\_STG\_%' escape '\'
               order by table_name) loop
      l_cols := null;
      l_sel  := null;
      for c in (select column_name, data_type
                  from user_tab_cols
                 where table_name = s.alvo
                   and virtual_column = 'NO'
                   and hidden_column = 'NO'
                 order by column_id) loop
        l_cols := l_cols || case when l_cols is not null then ', ' end || '"' || c.column_name || '"';
        l_sel  := l_sel  || case when l_sel  is not null then ', ' end
               || case when c.data_type = 'BLOB'
                       then 'amb_b64_blob("' || c.column_name || '")'
                       else '"' || c.column_name || '"' end;
      end loop;
      execute immediate 'insert into "' || s.alvo || '" (' || l_cols || ') select ' || l_sel
                     || ' from "' || s.stg || '"';
      dbms_output.put_line(s.alvo || ': ' || sql%rowcount || ' linha(s) gravada(s) com o BLOB convertido');
      commit;
      execute immediate 'drop table "' || s.stg || '" purge';
    end loop;
    execute immediate 'drop function amb_b64_blob';
  end if;
end;
/
