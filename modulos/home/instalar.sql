--------------------------------------------------------------------------------
-- Corlix Hub · Home (página 1, "Início") · instalação (SQLcl)
--
--   cd modulos/home
--   sql <usuario>@<servico> @instalar.sql
--
-- Só cria o package pkg_home_ui (sem tabelas). Reexecutável.
-- Depende do pkg_ponto (modulos/ponto-eletronico) e do pkg_historico_carreira.
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
