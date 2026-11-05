--------------------------------------------------------------------------------
-- Corlix Hub · Holerite digital · instalação (SQLcl)
--
--   cd modulos/holerite
--   sql <usuario>@<servico> @instalar.sql
--
-- Reexecutável. Depende de pkg_holerite (tabelas COLABORADOR_HOLERITE e
-- HOLERITE_ITENS) e de pkg_historico_carreira (empresa da sessão e fuso).
-- Não gera holerites nem cria o job: esses são os passos 1.2 e 1.3 do guia.
--------------------------------------------------------------------------------
whenever sqlerror exit failure rollback
set serveroutput on size unlimited
set define off

prompt == Geração das folhas pendentes
@@01_prc_gerar_holerites_pendentes.sql
show errors procedure prc_gerar_holerites_pendentes

prompt == Package de tela
@@02_pkg_holerite_ui.pks
@@02_pkg_holerite_ui.pkb
show errors package body pkg_holerite_ui

prompt == Conferência
select object_name, object_type, status
  from user_objects
 where object_name in ('PKG_HOLERITE_UI', 'PRC_GERAR_HOLERITES_PENDENTES')
 order by object_name, object_type;
