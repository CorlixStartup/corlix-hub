-- =============================================================================
-- Corlix Hub · Arquivos no OCI Object Storage: configuração
-- Guia: Etapas-fotos-object-storage.md
-- Só guarda nomes públicos. Chaves e OCIDs ficam na Web Credential do APEX.
-- =============================================================================
create table arquivo_config (
  id_config       number(1)     default 1 not null,
  ds_regiao       varchar2(50)  not null,
  ds_namespace    varchar2(100) not null,
  nm_bucket_fotos varchar2(100) not null,
  cd_credencial   varchar2(255) not null,
  constraint pk_arquivo_config primary key (id_config),
  constraint ck_arquivo_config_unica check (id_config = 1)
);

comment on table  arquivo_config               is 'Onde ficam os arquivos no OCI Object Storage. Linha única.';
comment on column arquivo_config.cd_credencial is 'Static ID da Web Credential do APEX. A credencial em si não fica no banco da aplicação.';
