-- =============================================================================
-- Corlix Hub · Arquivos no OCI Object Storage
-- Guia: Etapas-fotos-object-storage.md
-- =============================================================================
create or replace package pkg_arquivos as

  -- Entrega a foto ao navegador, se ela for de alguém da empresa da sessão.
  -- Sem permissão, nome inválido ou arquivo ausente: HTTP 404, e a tela mostra as iniciais.
  procedure entregar_foto (p_nome in varchar2);

end pkg_arquivos;
/
