-- =============================================================================
-- Corlix Hub · Arquivos: prefixo por ambiente no bucket das fotos
-- Guia: modulos/ambientes/Etapas-ambientes.md (passo 3.4)
--
-- DEV e UAT usam o mesmo bucket do PRD (corlix-fotos), mas gravam e leem
-- abaixo de um prefixo próprio: dev/empresa/<id>/fotos/... e uat/empresa/<id>/fotos/...
-- Assim um teste nunca apaga nem troca a foto real de alguém.
-- No PRD a coluna fica vazia e o caminho continua empresa/<id>/fotos/...
--
-- Rode ANTES de recompilar pkg_arquivos e pkg_foto_perfil (eles leem a coluna).
-- Pode rodar de novo: se a coluna já existir, não faz nada.
-- =============================================================================
declare
  l_qt pls_integer;
begin
  select count(*) into l_qt
    from user_tab_columns
   where table_name = 'ARQUIVO_CONFIG'
     and column_name = 'DS_PREFIXO';
  if l_qt = 0 then
    execute immediate q'[
      alter table arquivo_config add (
        ds_prefixo varchar2(20),
        constraint ck_arquivo_config_prefixo
          check (ds_prefixo is null or regexp_like(ds_prefixo, '^[a-z]+/$'))
      )]';
    execute immediate q'[comment on column arquivo_config.ds_prefixo is
      'Prefixo do ambiente no bucket (dev/ ou uat/). Vazio no PRD.']';
  end if;
end;
/

-- Em DEV:  update arquivo_config set ds_prefixo = 'dev/' where id_config = 1;
-- Em UAT:  update arquivo_config set ds_prefixo = 'uat/' where id_config = 1;
-- Em PRD:  não rode o update (a coluna fica vazia).
-- commit;
