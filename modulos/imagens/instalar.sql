--------------------------------------------------------------------------------
-- Corlix Hub · Imagens · instalação (SQLcl ou Database Actions › Run Script)
--
--   cd modulos/imagens
--   sql <usuario>@<servico> @instalar.sql
--
-- Reexecutável. Depende da tabela COMUNICADO. Cria IMAGEM_ORIGINAL se faltar.
-- No SQL Workshop do APEX, rode os arquivos um por vez (guia, §1).
--------------------------------------------------------------------------------
whenever sqlerror exit failure rollback
set serveroutput on size unlimited
set define off

prompt == Tabela das originais
@@01_ddl_imagens.sql

prompt == Regras
@@02_pkg_imagens.pks
@@02_pkg_imagens.pkb
show errors package body pkg_imagens

prompt == Package de tela
@@03_pkg_imagens_ui.pks
@@03_pkg_imagens_ui.pkb
show errors package body pkg_imagens_ui

prompt == Conferência
select object_name, object_type, status
  from user_objects
 where object_name in ('IMAGEM_ORIGINAL', 'PKG_IMAGENS', 'PKG_IMAGENS_UI')
 order by 1, 2;
