--------------------------------------------------------------------------------
-- Corlix Hub · Chat (página 4) · instalação (SQLcl)
--
--   cd modulos/chat
--   sql <usuario>@<servico> @instalar.sql
--
-- Cria o índice dos anexos e o package pkg_chat_ui. Reexecutável.
-- Depende do pkg_equipe_canal e das tabelas presenca_colaborador e
-- canal_mensagem_anexo, que já existem no schema (database/ddl/).
--------------------------------------------------------------------------------
whenever sqlerror exit failure rollback
set serveroutput on size unlimited
set define off

prompt == Índice dos anexos
@@01_ddl_anexo.sql

prompt == Package do chat
@@pkg_chat_ui.pks
@@pkg_chat_ui.pkb
show errors package body pkg_chat_ui

prompt == Conferência
select object_name, object_type, status
  from user_objects
 where object_name in ('PKG_CHAT_UI', 'IDX_CANALANEXO_MSG')
 order by object_type;
