-- =============================================================================
-- Corlix Hub · VW_ORG_COLABORADOR só com a empresa da sessão
-- Guia: modulos/isolamento-empresas/Etapas-isolamento-empresas.md
--
-- A view alimenta o organograma (página 3, PKG_ORGANOGRAMA) e o perfil
-- (página 2, PKG_PERFIL). Sem empresa na sessão, ela não devolve ninguém.
-- A coluna ID_EMPRESA entra no fim, para quem precisar filtrar de novo.
-- =============================================================================
create or replace view vw_org_colaborador as
select c.id_colaborador,
       c.id_gestor,
       c.nome_completo,
       c.email,
       c.login_apex,
       c.data_admissao,
       c.data_de_nascimento,
       cg.nome as cargo,
       d.nome  as departamento,
       c.foto_url,
       case when c.imagem_perfil is not null then 'S' else 'N' end as tem_imagem,
       c.id_empresa
  from colaborador  c
  join cargo        cg on cg.id_cargo       = c.id_cargo
  join departamento d  on d.id_departamento = c.id_departamento
 where c.status = true   -- STATUS nulo ou FALSE = conta inativa (não aparece)
   -- subconsulta escalar: v() é avaliada uma vez por consulta, não por linha
   and c.id_empresa = (select to_number(v('G_ID_EMPRESA') default null on conversion error) from dual);

-- O organograma e o perfil usam a view com %ROWTYPE: recompile os dois
alter package pkg_organograma compile body;
alter package pkg_perfil compile body;
