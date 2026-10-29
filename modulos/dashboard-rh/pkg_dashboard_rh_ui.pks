--------------------------------------------------------------------------------
-- Corlix Hub · Dashboard RH (página 20) · especificação
-- HTML das regiões Dynamic Content do redesign (protótipo pen_dev/Dashboard RH.png):
--   render_indicadores    -> 3 cards: promoções, admissões, desligamentos
--   render_turnover       -> barras admissões x desligamentos por mês + tabela
--   render_departamentos  -> promoções e tempo médio no cargo por departamento
--   render_solicitacoes   -> solicitações de correção abertas (card e diálogo)
--   render_formacoes      -> formações a vencer nos próximos 60 dias (card e diálogo)
-- Período em texto 'DD/MM/YYYY' (P20_DT_INICIO / P20_DT_FIM). A empresa vem de
-- G_ID_EMPRESA quando não informada. Datas de "hoje" usam
-- pkg_historico_carreira.fn_hoje (fuso da empresa).
--------------------------------------------------------------------------------
create or replace package pkg_dashboard_rh_ui authid definer as

  function render_indicadores (
    p_dt_inicio  in varchar2,
    p_dt_fim     in varchar2,
    p_id_empresa in number default to_number(v('G_ID_EMPRESA') default null on conversion error)
  ) return clob;

  function render_turnover (
    p_dt_inicio  in varchar2,
    p_dt_fim     in varchar2,
    p_id_empresa in number default to_number(v('G_ID_EMPRESA') default null on conversion error)
  ) return clob;

  function render_departamentos (
    p_dt_inicio  in varchar2,
    p_dt_fim     in varchar2,
    p_id_empresa in number default to_number(v('G_ID_EMPRESA') default null on conversion error)
  ) return clob;

  -- p_limite nulo = todas (diálogo). p_ver_todas = 'S' mostra o rodapé "Ver todas".
  function render_solicitacoes (
    p_id_empresa in number      default to_number(v('G_ID_EMPRESA') default null on conversion error),
    p_limite     in pls_integer default 3,
    p_ver_todas  in varchar2    default 'S'
  ) return clob;

  function render_formacoes (
    p_id_empresa in number      default to_number(v('G_ID_EMPRESA') default null on conversion error),
    p_limite     in pls_integer default 5,
    p_ver_todas  in varchar2    default 'S'
  ) return clob;

end pkg_dashboard_rh_ui;
/
