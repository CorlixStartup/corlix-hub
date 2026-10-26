--------------------------------------------------------------------------------
-- Corlix Hub · Busca na intranet (página 29) · especificação
-- HTML do campo de busca do header e da página de resultados
-- (protótipo pen_dev/Busca (resultados).png):
--   render_campo      -> campo "Buscar na intranet..." do header (Global Page)
--   render_cabecalho  -> "Resultados para “termo”" + contagem
--   render_resultados -> cards Pessoas e Comunicados (ou estado vazio)
--   render_ajuda      -> card "O que a busca encontra"
-- A busca ignora maiúsculas e acentos. Pessoas: colaboradores ativos da empresa,
-- por nome, cargo ou departamento. Comunicados: da empresa, por título ou texto.
-- Empresa vem da sessão (G_ID_EMPRESA) quando não informada.
--------------------------------------------------------------------------------
create or replace package pkg_busca_ui authid definer as

  -- Página de resultados e item que recebe o termo pela URL
  c_pagina constant pls_integer := 29;

  function render_campo return clob;

  function render_cabecalho (
    p_termo      in varchar2,
    p_id_empresa in number default to_number(v('G_ID_EMPRESA') default null on conversion error)
  ) return clob;

  function render_resultados (
    p_termo      in varchar2,
    p_id_empresa in number default to_number(v('G_ID_EMPRESA') default null on conversion error),
    p_login      in varchar2 default v('APP_USER')
  ) return clob;

  function render_ajuda return clob;

end pkg_busca_ui;
/
