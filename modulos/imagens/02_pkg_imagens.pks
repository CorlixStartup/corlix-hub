-- =============================================================================
-- Corlix Hub · Imagens · regras (troca da imagem por uma versão comprimida)
-- Guia: modulos/imagens/Etapas-imagens.md
-- =============================================================================
create or replace package pkg_imagens as

  -- Abaixo deste tamanho a imagem já é leve e não aparece na lista
  c_limite_bytes constant pls_integer := 409600;    -- 400 KB
  -- Maior JPEG aceito na volta (o navegador manda ~150-300 KB em 1280 x 720)
  c_max_bytes    constant pls_integer := 1048576;   -- 1 MB

  -- O conteúdo começa e termina como um JPEG
  function eh_jpeg (p_blob in blob) return boolean;

  -- Imagem atual de um comunicado da empresa. Sem comunicado ou sem imagem: no_data_found.
  procedure obter_comunicado (
    p_id_comunicado in  number,
    p_id_empresa    in  number,
    p_imagem        out blob,
    p_mime          out varchar2);

  -- Troca a imagem do comunicado pelo JPEG comprimido e guarda a original em
  -- IMAGEM_ORIGINAL. Devolve nulo se trocou, ou o motivo da recusa. Não faz commit.
  function trocar_comunicado (
    p_id_comunicado in number,
    p_id_empresa    in number,
    p_jpeg          in blob,
    p_usuario       in varchar2) return varchar2;

end pkg_imagens;
/
