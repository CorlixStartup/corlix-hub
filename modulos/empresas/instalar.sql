--------------------------------------------------------------------------------
-- Corlix Hub · Empresas · instalação (SQLcl)
--
--   cd modulos/empresas
--   sql <usuario>@<servico> @instalar.sql
--
-- No SQL Commands do APEX, rode cada bloco (01, 02) sozinho, sem a "/" final.
--------------------------------------------------------------------------------
whenever sqlerror exit failure rollback
set serveroutput on size unlimited
set define off

prompt == 01 · Data de abertura opcional
@@01_data_criacao_opcional.sql

prompt == 02 · Complemento com 100 caracteres
@@02_complemento_100.sql
