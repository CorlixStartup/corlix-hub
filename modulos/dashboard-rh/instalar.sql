--------------------------------------------------------------------------------
-- Corlix Hub · Dashboard RH (página 20) · instalação (SQLcl)
--
--   cd modulos/dashboard-rh
--   sql <usuario>@<servico> @instalar.sql
--
-- Só cria o package pkg_dashboard_rh_ui (sem tabelas). Reexecutável.
-- Depende do módulo de histórico de carreira (views e pkg_historico_carreira).
--------------------------------------------------------------------------------
whenever sqlerror exit failure rollback
set serveroutput on size unlimited
set define off

prompt == Package do Dashboard RH
@@pkg_dashboard_rh_ui.pks
@@pkg_dashboard_rh_ui.pkb
show errors package body pkg_dashboard_rh_ui

prompt == Conferência
select object_name, object_type, status
  from user_objects
 where object_name = 'PKG_DASHBOARD_RH_UI'
 order by object_type;
