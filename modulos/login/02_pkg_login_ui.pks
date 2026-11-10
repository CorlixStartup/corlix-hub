--------------------------------------------------------------------------------
-- Corlix Hub · Login (página 9999) · HTML das regiões · especificação
-- Protótipo: pen_dev/Login.png. Textos fixos, sem dado de sessão: a página é
-- pública e não há usuário logado.
--   render_cabecalho       -> marca "CorlixHub", "Acesse sua conta" e subtítulo
--   render_primeiro_acesso -> bloco "Primeiro acesso?" abaixo do botão Entrar
--   render_esqueci         -> conteúdo do diálogo "Esqueci minha senha"
--   render_rodape          -> "Problemas para entrar?" e o ano
--   render_destaque        -> card "Intranet Corlix" sobre a arte
--------------------------------------------------------------------------------
create or replace package pkg_login_ui authid definer as

  function render_cabecalho return clob;

  function render_primeiro_acesso return clob;

  function render_esqueci return clob;

  function render_rodape return clob;

  function render_destaque return clob;

end pkg_login_ui;
/
