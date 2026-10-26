--------------------------------------------------------------------------------
-- Corlix Hub · Busca na intranet (página 29) · instalação (SQLcl)
--
--   cd modulos/busca
--   sql <usuario>@<servico> @instalar.sql
--
-- Só cria o package pkg_busca_ui (sem tabelas). Reexecutável.
--------------------------------------------------------------------------------
whenever sqlerror exit failure rollback
set serveroutput on size unlimited
set define off

prompt == Package da busca
@@pkg_busca_ui.pks
@@pkg_busca_ui.pkb
show errors package body pkg_busca_ui

prompt == Conferência
select object_name, object_type, status
  from user_objects
 where object_name = 'PKG_BUSCA_UI'
 order by object_type;
