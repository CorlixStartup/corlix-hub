-- =============================================================================
-- Corlix Hub · Envio da foto de perfil para o bucket privado
-- Guia: Etapas-upload-foto-perfil.md
-- =============================================================================
create or replace package pkg_foto_perfil as

  -- Processo Ajax SALVAR_FOTO da página 2. Recebe o JPEG em base64, em pedaços, no f01.
  -- Grava sempre a foto de quem está logado. Responde {ok, mensagem}.
  procedure ajax_salvar;

end pkg_foto_perfil;
/
