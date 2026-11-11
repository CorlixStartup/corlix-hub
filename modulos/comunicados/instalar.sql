--------------------------------------------------------------------------------
-- Corlix Hub · Comunicados · instalação (SQLcl)
--   cd modulos/comunicados
--   sql <usuario>@<servico> @instalar.sql
-- Reexecutável. Pelo SQL Workshop: rode 01, 02 e 03 em SQL Scripts.
--------------------------------------------------------------------------------
whenever sqlerror exit failure rollback
set serveroutput on size unlimited
set define off

prompt == 01 · categorias
@@01_ddl_categoria.sql
prompt == 02 · categoria dos comunicados de demonstração
@@02_categoria_demo.sql
prompt == 03 · fixar no topo
@@03_ddl_fixado.sql

prompt == Conferência
select e.id_empresa, count(k.id_categoria) as categorias
  from empresa e left join categoria_comunicado k on k.id_empresa = e.id_empresa
 group by e.id_empresa order by e.id_empresa;
