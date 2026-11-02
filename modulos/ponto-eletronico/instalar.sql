--------------------------------------------------------------------------------
-- Corlix Hub · Ponto eletrônico · instalação (SQLcl)
--
--   cd modulos/ponto-eletronico
--   sql <usuario>@<servico> @instalar.sql
--
-- Reexecutável. Depende do módulo de histórico de carreira (pkg_historico_carreira,
-- para o fuso da empresa e a empresa da sessão). Não instala os dados de
-- demonstração: esses são o 05_dados_demo.sql.
--------------------------------------------------------------------------------
whenever sqlerror exit failure rollback
set serveroutput on size unlimited
set define off

prompt == Tabelas, trigger e view
@@01_ddl_ponto.sql

prompt == Package de regras
@@03_pkg_ponto.pks
@@03_pkg_ponto.pkb
show errors package body pkg_ponto

prompt == Package de tela
@@04_pkg_ponto_ui.pks
@@04_pkg_ponto_ui.pkb
show errors package body pkg_ponto_ui

prompt == Jornada padrão, vínculos e feriados
@@02_seed_ponto.sql

prompt == Conferência
select object_name, object_type, status
  from user_objects
 where object_name in ('PKG_PONTO', 'PKG_PONTO_UI', 'VW_PONTO_MARCACAO_VIGENTE', 'TRG_PONTO_MARCACAO_IMUTAVEL')
 order by object_name, object_type;

select (select count(*) from ponto_jornada)     as jornadas,
       (select count(*) from ponto_colaborador) as vinculos,
       (select count(*) from ponto_feriado)     as feriados
  from dual;
