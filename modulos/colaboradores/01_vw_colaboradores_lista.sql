-- =============================================================================
-- Corlix Hub · Módulo Colaboradores · 01 · View VW_COLABORADORES_LISTA
--
-- Alimenta a página 12 (Colaboradores · visão de administração):
-- Faceted Search + Classic Report conforme protótipo pen_dev/Colaboradores · visão de administração.png
--
-- Trata:
--   - Avatar com foto ou iniciais
--   - Formatação de vínculo (Empresa · Departamento / Cargo ou Sem vínculo)
--   - Resolução do perfil principal (Administrador, Publicador de conteúdo, Colaborador)
--   - Situação (Ativa / Inativa) para o badge
--   - Multiempresa: só devolve a empresa de G_ID_EMPRESA; sem empresa na sessão, nenhuma linha
--   - Equipe do Corlix Hub (papel explícito): vê todas as empresas e quem está sem empresa
-- =============================================================================

create or replace force editionable view vw_colaboradores_lista as
select c.id_colaborador,
       c.nome_completo,
       c.email,
       c.login_apex,
       c.primeiro_nome,
       c.ultimo_nome,
       c.foto_url,
       case
         when c.imagem_perfil is not null then 'S'
         else 'N'
       end as tem_imagem,
       -- Iniciais para o avatar circular
       upper(
         substr(coalesce(trim(c.primeiro_nome), trim(c.nome_completo), 'C'), 1, 1) ||
         coalesce(
           substr(trim(c.ultimo_nome), 1, 1),
           substr(trim(substr(c.nome_completo, instr(c.nome_completo, ' ', -1) + 1)), 1, 1),
           ''
         )
       ) as iniciais,
       -- Empresa
       c.id_empresa,
       nvl(e.nome_fantasia, 'Sem vínculo') as empresa,
       -- Departamento
       c.id_departamento,
       nvl(d.nome, 'Sem departamento') as departamento,
       -- Cargo
       c.id_cargo,
       nvl(cg.nome, 'Sem cargo') as cargo,
       -- Vínculo formatado em duas linhas
       case
         when c.id_empresa is not null and c.id_departamento is not null then
           e.nome_fantasia || ' · ' || d.nome
         when c.id_empresa is not null then
           e.nome_fantasia
         else
           'Sem vínculo'
       end as vinculo_linha1,
       case
         when c.id_empresa is not null and c.id_cargo is not null then
           cg.nome
         else
           'Cadastro incompleto'
       end as vinculo_linha2,
       case
         when c.id_empresa is null or c.id_departamento is null or c.id_cargo is null then
           'S'
         else
           'N'
       end as fl_sem_vinculo,
       case
         when c.id_empresa is null or c.id_departamento is null or c.id_cargo is null then
           'cx-colab-vinculo--alerta'
         else
           ''
       end as classe_vinculo,
       case
         when c.id_empresa is null or c.id_departamento is null or c.id_cargo is null then
           '<span class="fa fa-warning" aria-hidden="true"></span> '
         else
           ''
       end as icone_vinculo,
       -- Perfil de acesso (para faceta do Faceted Search)
       case
         when exists (
           select 1 from cargo_papel cp
            where cp.id_cargo = c.id_cargo
              and cp.cd_papel in ('equipe-do-corlix-hub', 'admin-rh', 'diretoria')
         ) or (fn_colab_tem_papel(c.login_apex, 'equipe-do-corlix-hub', to_number(v('APP_ID') default 100 on conversion error)) = 1 or fn_colab_tem_papel(c.login_apex, 'admin-rh', to_number(v('APP_ID') default 100 on conversion error)) = 1) then 'Administrador'
         when exists (
           select 1 from cargo_papel cp
            where cp.id_cargo = c.id_cargo
              and cp.cd_papel in ('publicador-de-conteudo', 'publicador-de-conteúdo')
         ) or (fn_colab_tem_papel(c.login_apex, 'publicador-de-conteudo', to_number(v('APP_ID') default 100 on conversion error)) = 1 or fn_colab_tem_papel(c.login_apex, 'publicador-de-conteúdo', to_number(v('APP_ID') default 100 on conversion error)) = 1) then 'Publicador de conteúdo'
         else 'Colaborador'
       end as perfil,
       -- HTML do perfil (etiqueta cinza ou texto simples para o relatório)
       case
         when exists (
           select 1 from cargo_papel cp
            where cp.id_cargo = c.id_cargo
              and cp.cd_papel in ('equipe-do-corlix-hub', 'admin-rh', 'diretoria')
         ) or (fn_colab_tem_papel(c.login_apex, 'equipe-do-corlix-hub', to_number(v('APP_ID') default 100 on conversion error)) = 1 or fn_colab_tem_papel(c.login_apex, 'admin-rh', to_number(v('APP_ID') default 100 on conversion error)) = 1) then '<span class="cx-etiqueta">Administrador</span>'
         when exists (
           select 1 from cargo_papel cp
            where cp.id_cargo = c.id_cargo
              and cp.cd_papel in ('publicador-de-conteudo', 'publicador-de-conteúdo')
         ) or (fn_colab_tem_papel(c.login_apex, 'publicador-de-conteudo', to_number(v('APP_ID') default 100 on conversion error)) = 1 or fn_colab_tem_papel(c.login_apex, 'publicador-de-conteúdo', to_number(v('APP_ID') default 100 on conversion error)) = 1) then '<span class="cx-etiqueta">Publicador de conteúdo</span>'
         else 'Colaborador'
       end as perfil_html,
       -- Situação
       case when c.status = true then 'Ativa' else 'Inativa' end as situacao,
       case when c.status = true then 'sucesso' else 'neutro' end as situacao_classe
  from colaborador c
  left join empresa e      on e.id_empresa = c.id_empresa
  left join departamento d on d.id_departamento = c.id_departamento
  left join cargo cg       on cg.id_cargo = c.id_cargo
 where c.id_empresa = to_number(v('G_ID_EMPRESA') default null on conversion error)
    or fn_colab_tem_papel(v('APP_USER'), 'equipe-do-corlix-hub', to_number(v('APP_ID') default 100 on conversion error)) = 1;
