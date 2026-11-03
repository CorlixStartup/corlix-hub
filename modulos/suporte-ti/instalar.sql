--------------------------------------------------------------------------------
-- Corlix Hub · Suporte TI · instalação (SQLcl)
--
--   cd modulos/suporte-ti
--   sql <usuario>@<servico> @instalar.sql
--
-- Reexecutável. Depende do módulo de histórico de carreira (pkg_historico_carreira,
-- para o fuso da empresa e a empresa da sessão).
--------------------------------------------------------------------------------
whenever sqlerror exit failure rollback
set serveroutput on size unlimited
set define off

prompt == Tabelas, triggers e view
@@01_ddl_suporte.sql

prompt == Package de regras
@@03_pkg_suporte.pks
@@03_pkg_suporte.pkb
show errors package body pkg_suporte

prompt == Package de tela
@@04_pkg_suporte_ui.pks
@@04_pkg_suporte_ui.pkb
show errors package body pkg_suporte_ui

prompt == Assuntos, sistemas, artigos e contatos
@@02_seed_suporte.sql

prompt == Job de encerramento
@@05_job_suporte.sql

prompt == Conferência
select object_name, object_type, status
  from user_objects
 where object_name in ('PKG_SUPORTE', 'PKG_SUPORTE_UI', 'VW_SUPORTE_FILA',
                       'TRG_SUPORTE_SISTEMA_AUD', 'TRG_SUPORTE_ARTIGO_AUD')
 order by object_name, object_type;

select (select count(*) from suporte_assunto) as assuntos,
       (select count(*) from suporte_sistema) as sistemas,
       (select count(*) from suporte_artigo)  as artigos,
       (select count(*) from suporte_config)  as configuracoes
  from dual;

select job_name, enabled, state, next_run_date
  from user_scheduler_jobs
 where job_name = 'SUPORTE_ENCERRAR_VENCIDOS';
