-- =============================================================================
-- Corlix Hub · Imagens · página "Otimizar imagens"
-- Guia: modulos/imagens/Etapas-imagens.md
-- =============================================================================
create or replace package pkg_imagens_ui as

  -- Região "Cabeçalho" (Breadcrumb Bar)
  function render_cabecalho return clob;

  -- Região "Imagens" (Body): imagens de comunicado da empresa acima de 400 KB
  function render_lista return clob;

  -- Ajax Callback OBTER_IMAGEM. x01 = ID_COMUNICADO.
  -- Responde {ok, mime, imagem (base64)} ou {ok:false, mensagem}.
  procedure ajax_obter;

  -- Ajax Callback SALVAR_IMAGEM. x01 = ID_COMUNICADO; f01 = JPEG em base64, em pedaços.
  -- Responde {ok, mensagem, antes, depois}.
  procedure ajax_salvar;

end pkg_imagens_ui;
/
