--------------------------------------------------------------------------------
-- Corlix Hub · Colaboradores · Instalação (SQLcl / SQL Workshop)
--
--   cd modulos/colaboradores
--   sql <usuario>@<servico> @instalar.sql
--
-- No SQL Commands, execute 00, 01, 02 spec e 02 body, um comando por vez, sem "/" isolada.
--------------------------------------------------------------------------------
whenever sqlerror exit failure rollback
set serveroutput on size unlimited
set define off

prompt == 00 · Função FN_COLAB_TEM_PAPEL
@@00_fn_colab_tem_papel.sql

prompt == 01 · View VW_COLABORADORES_LISTA
@@01_vw_colaboradores_lista.sql

prompt == 02 · Package de interface
@@02_pkg_colaboradores_ui.pks
show errors package pkg_colaboradores_ui
@@02_pkg_colaboradores_ui.pkb
show errors package body pkg_colaboradores_ui

prompt == Concluído!
