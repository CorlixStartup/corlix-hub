--------------------------------------------------------------------------------
-- Corlix Hub · Home (página 28) · instalação (SQLcl)
--
--   cd modulos/home
--   sql <usuario>@<servico> @instalar.sql
--
-- Só cria o package pkg_home_ui (sem tabelas). Reexecutável.
--------------------------------------------------------------------------------
whenever sqlerror exit failure rollback
set serveroutput on size unlimited
set define off

prompt == Package da Home
@@pkg_home_ui.pks
@@pkg_home_ui.pkb
show errors package body pkg_home_ui

prompt == Conferência
select object_name, object_type, status
  from user_objects
 where object_name = 'PKG_HOME_UI'
 order by object_type;
