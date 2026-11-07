--------------------------------------------------------------------------------
-- Corlix Hub · Colaboradores · Instalação (SQLcl / SQL Workshop)
--
--   cd modulos/colaboradores
--   sql <usuario>@<servico> @instalar.sql
--
-- No SQL Commands do APEX, rode o script 01 sozinho, sem a "/" final.
--------------------------------------------------------------------------------
whenever sqlerror exit failure rollback
set serveroutput on size unlimited
set define off

prompt == 01 · View VW_COLABORADORES_LISTA
@@01_vw_colaboradores_lista.sql

prompt == Concluído!
