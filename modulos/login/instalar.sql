--------------------------------------------------------------------------------
-- Corlix Hub · Login (página 9999) · instalação (SQLcl)
--
--   cd modulos/login
--   sql <usuario>@<servico> @instalar.sql
--
-- Reexecutável. Depende da tabela COLABORADOR (EMAIL, LOGIN_APEX).
-- No SQL Workshop, rode um arquivo por vez, na ordem abaixo (guia §1).
--------------------------------------------------------------------------------
whenever sqlerror exit failure rollback
set serveroutput on size unlimited
set define off

prompt == Regra de negócio
@@01_pkg_login.pks
@@01_pkg_login.pkb
show errors package body pkg_login

prompt == Package de tela
@@02_pkg_login_ui.pks
@@02_pkg_login_ui.pkb
show errors package body pkg_login_ui

prompt == Conferência
select object_name, object_type, status
  from user_objects
 where object_name in ('PKG_LOGIN', 'PKG_LOGIN_UI')
 order by object_name, object_type;
