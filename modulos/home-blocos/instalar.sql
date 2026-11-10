--------------------------------------------------------------------------------
-- Corlix Hub · Blocos da Home · instalação (SQLcl)
--   cd modulos/home-blocos
--   sql <usuario>@<servico> @instalar.sql
-- Só as tabelas. Os dados de demonstração (02) rodam à parte, depois de trocar
-- c_colaborador. Reexecutável.
--------------------------------------------------------------------------------
whenever sqlerror exit failure rollback
set serveroutput on size unlimited
set define off

prompt == 01 · tabelas
@@01_ddl_blocos.sql

prompt == Conferência
select table_name from user_tables
 where table_name in ('FEEDBACK', 'PESQUISA', 'PESQUISA_RESPOSTA', 'EVENTO', 'CONVERSA_1A1',
                      'FERIAS_PERIODO', 'PDI', 'PDI_OBJETIVO')
 order by table_name;
