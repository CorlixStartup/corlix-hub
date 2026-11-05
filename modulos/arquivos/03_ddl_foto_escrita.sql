-- =============================================================================
-- Corlix Hub · Envio da foto de perfil: credencial de gravação
-- Guia: Etapas-upload-foto-perfil.md
-- =============================================================================
alter table arquivo_config add (cd_credencial_escrita varchar2(255));

comment on column arquivo_config.cd_credencial_escrita is 'Static ID da Web Credential que grava fotos. Separada da credencial de leitura.';
