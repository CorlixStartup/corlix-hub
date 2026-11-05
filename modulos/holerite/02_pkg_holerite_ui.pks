--------------------------------------------------------------------------------
-- Corlix Hub · Holerite digital (página 9) · 02 · HTML · especificação
-- Protótipo: pen_dev/Holerite digital.png. Classes cx-hol-* em holerite.css.
--
-- Este package só lê. Sem p_id_colaborador, usa o colaborador da conta logada.
-- O parâmetro só existe para testar no SQL Commands; a página nunca o recebe da
-- URL, e é isso que garante que cada pessoa veja apenas os próprios valores.
--
-- p_competencia é o mês em YYYYMM (P9_COMPETENCIA). Vazio, inválido ou de um mês
-- sem holerite = holerite mais recente.
--------------------------------------------------------------------------------
create or replace package pkg_holerite_ui authid definer as

  -- Título, descrição e botões "Ocultar valores" e "Baixar PDF"
  function render_cabecalho (p_id_colaborador in number default null) return clob;

  -- Resumo, detalhamento, lista de holerites e "Algo errado neste holerite?"
  function render_pagina (
    p_competencia    in varchar2 default null,
    p_id_colaborador in number default null
  ) return clob;

end pkg_holerite_ui;
/
