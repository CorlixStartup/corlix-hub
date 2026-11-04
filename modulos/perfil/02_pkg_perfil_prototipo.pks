-- =============================================================================
-- Corlix Hub · Perfil (página 2): especificação do PKG_PERFIL
-- Guia: Etapas-perfil-prototipo.md
-- =============================================================================
create or replace package pkg_perfil as

  -- Faixa do topo: avatar, nome, cargo, tempo de casa, e-mail e Alterar foto.
  -- Região na Breadcrumb Bar.
  function render_cabecalho (
    p_id_colaborador in number default null
  ) return clob;

  -- Abas (Trajetória e Dados pessoais) e cards de gestor e colegas.
  function render (
    p_id_colaborador in number default null
  ) return clob;

  -- Conteúdo do painel de alteração de foto
  function render_drawer_foto (
    p_id_colaborador in number
  ) return clob;

end pkg_perfil;
/
