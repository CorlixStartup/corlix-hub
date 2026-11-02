--------------------------------------------------------------------------------
-- Corlix Hub · Home (página 1, "Início") · especificação
-- HTML das regiões Dynamic Content da Home (protótipo pen_dev/Início.png):
--   render_hero            -> "Boa tarde, <nome>", data por extenso e links rápidos
--   render_meu_gestor      -> card "Meu gestor" (preenchido ou estado vazio)
--   render_celebracoes     -> aniversários e tempo de empresa do mês (card e diálogo)
--   render_aniversariantes -> versão anterior (só aniversários); fica até a
--                             página trocar para render_celebracoes (guia §6)
--   mes_atual              -> "outubro" (título "Celebrações de ...")
-- Login e empresa vêm da sessão (APP_USER, G_ID_EMPRESA) quando não informados.
--------------------------------------------------------------------------------
create or replace package pkg_home_ui authid definer as

  function mes_atual return varchar2;

  function render_hero (
    p_login in varchar2 default v('APP_USER')
  ) return clob;

  function render_meu_gestor (
    p_login      in varchar2 default v('APP_USER'),
    p_id_empresa in number   default to_number(v('G_ID_EMPRESA') default null on conversion error)
  ) return clob;

  -- p_limite nulo = todos do mês. p_ver_todos = 'S' mostra o rodapé "Ver todos".
  function render_aniversariantes (
    p_id_empresa in number      default to_number(v('G_ID_EMPRESA') default null on conversion error),
    p_limite     in pls_integer default 3,
    p_ver_todos  in varchar2    default 'S'
  ) return clob;

  -- Aniversários e anos de empresa (admissão) do mês. Mesmos parâmetros acima.
  function render_celebracoes (
    p_id_empresa in number      default to_number(v('G_ID_EMPRESA') default null on conversion error),
    p_limite     in pls_integer default 4,
    p_ver_todos  in varchar2    default 'S'
  ) return clob;

end pkg_home_ui;
/
