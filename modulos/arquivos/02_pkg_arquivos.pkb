-- =============================================================================
-- Corlix Hub · Arquivos no OCI Object Storage
-- Guia: Etapas-fotos-object-storage.md
-- Depende de: ARQUIVO_CONFIG, COLABORADOR, EMPRESA e do item G_ID_EMPRESA.
-- =============================================================================
create or replace package body pkg_arquivos as

  -- Só o nome do arquivo: sem pasta, sem "..", com extensão de imagem
  c_nome_valido constant varchar2(60) := '^[[:alnum:]_][[:alnum:]._-]*\.(jpg|jpeg|png)$';

  procedure nao_encontrado is
  begin
    htp.init;
    owa_util.status_line(404, 'Not Found', true);
    apex_application.stop_apex_engine;
  end nao_encontrado;

  -- A foto é de alguém desta empresa? FOTO_URL pode vir só com o nome ou com a pasta antiga.
  function e_da_empresa (p_nome in varchar2, p_id_empresa in number) return boolean is
    l_qt pls_integer;
  begin
    select count(*)
      into l_qt
      from colaborador
     where id_empresa = p_id_empresa
       and regexp_substr(trim(foto_url), '[^/]+$') = p_nome;
    return l_qt > 0;
  end e_da_empresa;

  procedure entregar_foto (p_nome in varchar2) is
    l_emp  number := to_number(v('G_ID_EMPRESA') default null on conversion error);
    l_cfg  arquivo_config%rowtype;
    l_blob blob;
    l_mime varchar2(255);
  begin
    -- A equipe do Corlix Hub vê todas as empresas: a pasta vem do dono da foto.
    if apex_authorization.is_authorized('EQUIPE_CORLIX_HUB') then
      select max(id_empresa)
        into l_emp
        from colaborador
       where id_empresa is not null
         and regexp_substr(trim(foto_url), '[^/]+$') = p_nome;
    end if;

    if l_emp is null
       or p_nome is null
       or not regexp_like(p_nome, c_nome_valido, 'i')
       or not e_da_empresa(p_nome, l_emp)
    then
      nao_encontrado;
      return;
    end if;

    begin
      select * into l_cfg from arquivo_config where id_config = 1;
    exception
      when no_data_found then
        -- Sem configuração, não há o que entregar. Erros da chamada ao OCI, como
        -- credencial não encontrada, seguem visíveis e não viram 404.
        nao_encontrado;
        return;
    end;

    apex_web_service.set_request_headers(
      p_name_01  => 'Accept',          p_value_01 => '*/*',
      p_name_02  => 'Accept-Encoding', p_value_02 => 'identity',
      p_reset    => true);

    l_blob := apex_web_service.make_rest_request_b(
      p_url                  => 'https://objectstorage.' || l_cfg.ds_regiao || '.oraclecloud.com'
                                || '/n/' || l_cfg.ds_namespace
                                || '/b/' || l_cfg.nm_bucket_fotos
                                || '/o/empresa/' || l_emp || '/fotos/' || apex_util.url_encode(p_nome),
      p_http_method          => 'GET',
      p_credential_static_id => l_cfg.cd_credencial);

    if apex_web_service.g_status_code <> 200
       or l_blob is null
       or dbms_lob.getlength(l_blob) = 0
    then
      nao_encontrado;
      return;
    end if;

    -- O tipo vem da extensão já validada, e não do que o bucket responder
    l_mime := case when lower(p_nome) like '%.png' then 'image/png' else 'image/jpeg' end;

    -- APEX_HTTP.DOWNLOAD não permite definir cache. "private": só o navegador da pessoa guarda.
    htp.init;
    owa_util.mime_header(l_mime, false);
    htp.p('Content-Length: ' || dbms_lob.getlength(l_blob));
    htp.p('Cache-Control: private, max-age=3600');
    htp.p('X-Content-Type-Options: nosniff');
    owa_util.http_header_close;
    wpg_docload.download_file(l_blob);
    apex_application.stop_apex_engine;
  exception
    when apex_application.e_stop_apex_engine then
      raise;
  end entregar_foto;

end pkg_arquivos;
/
