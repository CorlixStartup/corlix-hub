-- =============================================================================
-- Corlix Hub · Envio da foto de perfil para o bucket privado
-- Guia: Etapas-upload-foto-perfil.md
-- Depende de: ARQUIVO_CONFIG, COLABORADOR e do item G_ID_EMPRESA.
-- =============================================================================
create or replace package body pkg_foto_perfil as

  c_max_bytes  constant pls_integer := 1048576;  -- o navegador manda bem menos: 512 x 512 px
  c_max_partes constant pls_integer := 180;      -- 8000 caracteres cada: cerca de 1 MB em base64

  e_recusado exception;
  g_mensagem varchar2(400);

  procedure recusar (p_mensagem in varchar2) is
  begin
    g_mensagem := p_mensagem;
    raise e_recusado;
  end recusar;

  function url_objeto (
    p_cfg in arquivo_config%rowtype,
    p_emp in number,
    p_nome in varchar2
  ) return varchar2 is
  begin
    return 'https://objectstorage.' || p_cfg.ds_regiao || '.oraclecloud.com'
        || '/n/' || p_cfg.ds_namespace
        || '/b/' || p_cfg.nm_bucket_fotos
        || '/o/empresa/' || p_emp || '/fotos/' || apex_util.url_encode(p_nome);
  end url_objeto;

  function le_imagem return blob is
    l_clob clob;
    l_blob blob;
  begin
    if apex_application.g_f01.count = 0 or apex_application.g_f01.count > c_max_partes then
      recusar('Escolha uma imagem de até 5 MB.');
    end if;

    dbms_lob.createtemporary(l_clob, true, dbms_lob.call);
    for i in 1 .. apex_application.g_f01.count loop
      if apex_application.g_f01(i) is not null then
        dbms_lob.writeappend(l_clob, length(apex_application.g_f01(i)), apex_application.g_f01(i));
      end if;
    end loop;

    l_blob := apex_web_service.clobbase642blob(l_clob);

    -- O tipo vem do conteúdo: início e fim de um JPEG
    if l_blob is null
       or dbms_lob.getlength(l_blob) < 4
       or dbms_lob.getlength(l_blob) > c_max_bytes
       or dbms_lob.substr(l_blob, 3, 1) <> hextoraw('FFD8FF')
       or dbms_lob.substr(l_blob, 2, dbms_lob.getlength(l_blob) - 1) <> hextoraw('FFD9')
    then
      recusar('Não foi possível ler essa imagem. Tente outra, em JPG ou PNG.');
    end if;

    return l_blob;
  end le_imagem;

  -- A foto anterior só é apagada se foi gerada pelo sistema para esta pessoa.
  -- Se a exclusão falhar, a foto nova continua valendo.
  procedure apaga_anterior (
    p_cfg      in arquivo_config%rowtype,
    p_emp      in number,
    p_id       in number,
    p_anterior in varchar2
  ) is
    l_nome     constant varchar2(4000) := regexp_substr(trim(p_anterior), '[^/]+$');
    l_resposta clob;
  begin
    if regexp_like(l_nome, '^' || p_id || '_[0-9]+\.jpg$') then
      apex_web_service.clear_request_headers;
      l_resposta := apex_web_service.make_rest_request(
        p_url                  => url_objeto(p_cfg, p_emp, l_nome),
        p_http_method          => 'DELETE',
        p_credential_static_id => p_cfg.cd_credencial_escrita);
    end if;
  exception
    when others then
      apex_debug.error('Foto anterior não apagada: %s', sqlerrm);
  end apaga_anterior;

  procedure ajax_salvar is
    l_emp      constant number := to_number(v('G_ID_EMPRESA') default null on conversion error);
    l_usuario  constant varchar2(255) := v('APP_USER');
    l_id       colaborador.id_colaborador%type;
    l_anterior colaborador.foto_url%type;
    l_cfg      arquivo_config%rowtype;
    l_blob     blob;
    l_nome     varchar2(100);
    l_resposta clob;
  begin
    begin
      select id_colaborador, foto_url
        into l_id, l_anterior
        from colaborador
       where upper(trim(login_apex)) = upper(trim(l_usuario))
         and id_empresa = l_emp;
    exception
      when no_data_found or too_many_rows then
        recusar('Sua conta não está vinculada a um colaborador desta empresa.');
    end;

    l_blob := le_imagem;

    begin
      select * into l_cfg from arquivo_config where id_config = 1;
    exception
      when no_data_found then
        recusar('O envio de fotos ainda não foi configurado. Fale com a TI.');
    end;

    if l_cfg.cd_credencial_escrita is null then
      recusar('O envio de fotos ainda não foi configurado. Fale com a TI.');
    end if;

    -- Nome novo a cada envio: o navegador guarda a foto anterior por até 1 hora
    l_nome := l_id || '_' || to_char(systimestamp, 'yyyymmddhh24missff3') || '.jpg';

    apex_web_service.set_request_headers(
      p_name_01  => 'Content-Type',
      p_value_01 => 'image/jpeg',
      p_reset    => true);

    l_resposta := apex_web_service.make_rest_request(
      p_url                  => url_objeto(l_cfg, l_emp, l_nome),
      p_http_method          => 'PUT',
      p_body_blob            => l_blob,
      p_credential_static_id => l_cfg.cd_credencial_escrita);

    if apex_web_service.g_status_code not in (200, 201) then
      apex_debug.error('Envio da foto recusado pelo bucket: HTTP %s', apex_web_service.g_status_code);
      recusar('Não foi possível salvar a foto agora. Tente de novo em alguns minutos.');
    end if;

    update colaborador
       set foto_url = l_nome
     where id_colaborador = l_id
       and id_empresa = l_emp;
    commit;

    apaga_anterior(l_cfg, l_emp, l_id, l_anterior);

    apex_json.open_object;
    apex_json.write('ok', true);
    apex_json.write('mensagem', 'Foto salva.');
    apex_json.close_object;
  exception
    when e_recusado then
      apex_json.open_object;
      apex_json.write('ok', false);
      apex_json.write('mensagem', g_mensagem);
      apex_json.close_object;
    when others then
      apex_debug.error('Falha ao salvar a foto: %s', sqlerrm);
      apex_json.open_object;
      apex_json.write('ok', false);
      apex_json.write('mensagem', 'Não foi possível salvar a foto agora. Tente de novo em alguns minutos.');
      apex_json.close_object;
  end ajax_salvar;

end pkg_foto_perfil;
/
