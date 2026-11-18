--------------------------------------------------------------------------------
-- Corlix Hub · Chat (página 4) · corpo
-- Ver pkg_chat_ui.pks e modulos/chat/Etapas-chat.md §2 (presença) e §4 (anexos).
--------------------------------------------------------------------------------
create or replace package body pkg_chat_ui as

  -- Mesmos limites da região "Contatos" da página 4 e do pkg_home_ui
  c_online_min  constant pls_integer := 5;   -- ping ONLINE há menos de 5 min: online
  c_ausente_min constant pls_integer := 30;  -- qualquer ping há menos de 30 min: ausente

  -- Anexos
  c_max_anexo   constant pls_integer := 10 * 1024 * 1024;  -- 10 MB
  c_err_anexo   constant pls_integer := -20120;            -- mensagem que pode ir para a tela

  ------------------------------------------------------------------------------
  -- Colaborador ativo da conta logada, na empresa da sessão.
  -- Sem empresa na sessão, nenhum (empresa nula nunca libera nada).
  ------------------------------------------------------------------------------
  function colaborador_logado return number is
    l_empresa constant number := to_number(v('G_ID_EMPRESA') default null on conversion error);
    l_id      colaborador.id_colaborador%type;
  begin
    if l_empresa is null then
      return null;
    end if;

    select c.id_colaborador
      into l_id
      from colaborador c
     where upper(trim(c.login_apex)) = upper(trim(v('APP_USER')))
       and c.id_empresa = l_empresa
       and c.status     = true
     fetch first 1 row only;

    return l_id;
  exception
    when no_data_found then
      return null;
  end colaborador_logado;

  ------------------------------------------------------------------------------
  function situacao_presenca (
    p_status      in varchar2,
    p_ultimo_ping in timestamp
  ) return varchar2 is
  begin
    if p_ultimo_ping > systimestamp - numtodsinterval(c_online_min, 'MINUTE')
       and upper(p_status) = 'ONLINE' then
      return 'online';
    elsif p_ultimo_ping > systimestamp - numtodsinterval(c_ausente_min, 'MINUTE') then
      return 'ausente';
    end if;
    return 'offline';
  end situacao_presenca;

  ------------------------------------------------------------------------------
  -- Ajax Callbacks
  ------------------------------------------------------------------------------
  procedure ajax_ping is
    l_id constant number := colaborador_logado;
  begin
    if l_id is not null then
      pkg_equipe_canal.atualizar_presenca(l_id, 'ONLINE');  -- faz o commit
    end if;

    apex_json.open_object;
    apex_json.write('ok', l_id is not null);
    apex_json.close_object;
  exception
    when others then
      -- o ping não pode mostrar erro para quem está usando a app: só registra no debug
      apex_debug.error('pkg_chat_ui.ajax_ping: %s', sqlerrm);
      apex_json.open_object;
      apex_json.write('ok', false);
      apex_json.close_object;
  end ajax_ping;

  procedure ajax_presencas is
    l_id constant number := colaborador_logado;
  begin
    apex_json.open_object;
    apex_json.open_object('presencas');

    if l_id is not null then
      -- mesmos colegas da região "Contatos": ativos, da minha empresa, menos eu
      for r in (
        select c.id_colaborador,
               p.status_presenca,
               p.data_ultimo_ping
          from colaborador c
          join colaborador eu
            on eu.id_colaborador = l_id
           and eu.id_empresa     = c.id_empresa
          left join presenca_colaborador p
            on p.id_colaborador = c.id_colaborador
         where c.status         = true
           and c.id_colaborador <> l_id
      ) loop
        apex_json.write(to_char(r.id_colaborador),
                        situacao_presenca(r.status_presenca, r.data_ultimo_ping));
      end loop;
    end if;

    apex_json.close_object;
    apex_json.close_object;
  end ajax_presencas;

  ------------------------------------------------------------------------------
  -- Anexos: tipos aceitos
  -- O tipo gravado vem da extensão, e não do que o navegador informou.
  ------------------------------------------------------------------------------
  function extensao (p_nome in varchar2) return varchar2 is
  begin
    -- no máximo 10 caracteres: nenhuma extensão aceita passa disso
    return substr(lower(regexp_substr(p_nome, '\.([^.\\/]+)$', 1, 1, null, 1)), 1, 10);
  end extensao;

  function mime_anexo (p_extensao in varchar2) return varchar2 is
  begin
    return case p_extensao
      -- Excel
      when 'xlsx' then 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      when 'xlsm' then 'application/vnd.ms-excel.sheet.macroEnabled.12'
      when 'xlsb' then 'application/vnd.ms-excel.sheet.binary.macroEnabled.12'
      when 'xltx' then 'application/vnd.openxmlformats-officedocument.spreadsheetml.template'
      when 'xls'  then 'application/vnd.ms-excel'
      when 'csv'  then 'text/csv'
      -- Word
      when 'docx' then 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
      when 'docm' then 'application/vnd.ms-word.document.macroEnabled.12'
      when 'dotx' then 'application/vnd.openxmlformats-officedocument.wordprocessingml.template'
      when 'doc'  then 'application/msword'
      when 'rtf'  then 'application/rtf'
      -- PowerPoint
      when 'pptx' then 'application/vnd.openxmlformats-officedocument.presentationml.presentation'
      when 'pptm' then 'application/vnd.ms-powerpoint.presentation.macroEnabled.12'
      when 'ppsx' then 'application/vnd.openxmlformats-officedocument.presentationml.slideshow'
      when 'potx' then 'application/vnd.openxmlformats-officedocument.presentationml.template'
      when 'ppt'  then 'application/vnd.ms-powerpoint'
      when 'pps'  then 'application/vnd.ms-powerpoint'
      -- Imagens (sem SVG: pode conter script)
      when 'jpg'  then 'image/jpeg'
      when 'jpeg' then 'image/jpeg'
      when 'png'  then 'image/png'
      when 'gif'  then 'image/gif'
      when 'webp' then 'image/webp'
      when 'bmp'  then 'image/bmp'
    end;
  end mime_anexo;

  function e_imagem (p_extensao in varchar2) return boolean is
  begin
    return p_extensao in ('jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp');
  end e_imagem;

  -- Formatos com macro e os antigos do Office, que também podem trazer macro
  function pode_ter_macro (p_extensao in varchar2) return boolean is
  begin
    return p_extensao in ('xlsm', 'xlsb', 'docm', 'pptm', 'xls', 'doc', 'ppt', 'pps');
  end pode_ter_macro;

  function familia (p_extensao in varchar2) return varchar2 is
  begin
    return case
      when p_extensao in ('xlsx', 'xlsm', 'xlsb', 'xltx', 'xls', 'csv')         then 'excel'
      when p_extensao in ('docx', 'docm', 'dotx', 'doc', 'rtf')                 then 'word'
      when p_extensao in ('pptx', 'pptm', 'ppsx', 'potx', 'ppt', 'pps')         then 'powerpoint'
      else 'arquivo'
    end;
  end familia;

  -- Confere os primeiros bytes: um .exe renomeado para .docx é recusado
  function conteudo_confere (p_blob in blob, p_extensao in varchar2) return boolean is
    l_hex constant varchar2(32) := nvl(rawtohex(dbms_lob.substr(p_blob, 16, 1)), '-');
    l_nul number;
  begin
    if p_extensao in ('xlsx', 'xlsm', 'xlsb', 'xltx', 'docx', 'docm', 'dotx',
                      'pptx', 'pptm', 'ppsx', 'potx') then
      return l_hex like '504B0304%';                   -- Office novo = ZIP ("PK")
    elsif p_extensao in ('xls', 'doc', 'ppt', 'pps') then
      return l_hex like 'D0CF11E0A1B11AE1%';           -- Office antigo (OLE Compound File)
    elsif p_extensao = 'png' then
      return l_hex like '89504E470D0A1A0A%';
    elsif p_extensao in ('jpg', 'jpeg') then
      return l_hex like 'FFD8FF%';
    elsif p_extensao = 'gif' then
      return l_hex like '47494638%';                   -- "GIF8"
    elsif p_extensao = 'webp' then
      return l_hex like '52494646________57454250%';   -- "RIFF" .... "WEBP"
    elsif p_extensao = 'bmp' then
      return l_hex like '424D%';                       -- "BM"
    elsif p_extensao = 'rtf' then
      return l_hex like '7B5C727466%';                 -- "{\rtf"
    elsif p_extensao = 'csv' then
      -- texto: nenhum byte zero no começo do arquivo
      l_nul := dbms_lob.instr(p_blob, hextoraw('00'), 1, 1);
      return l_nul = 0 or l_nul > 8192;
    end if;
    return false;
  end conteudo_confere;

  function tamanho_texto (p_bytes in number) return varchar2 is
  begin
    if p_bytes < 1024 * 1024 then
      return greatest(1, round(p_bytes / 1024)) || ' KB';
    end if;
    return to_char(p_bytes / 1024 / 1024, 'FM990D0', 'NLS_NUMERIC_CHARACTERS='',.''') || ' MB';
  end tamanho_texto;

  procedure responder_anexo (p_ok in boolean, p_mensagem in varchar2 default null) is
  begin
    apex_json.open_object;
    apex_json.write('ok', p_ok);
    if p_mensagem is not null then
      apex_json.write('mensagem', p_mensagem);
    end if;
    apex_json.close_object;
  end responder_anexo;

  ------------------------------------------------------------------------------
  -- Anexos: envio, download e HTML
  ------------------------------------------------------------------------------
  procedure ajax_enviar_anexo is
    l_eu    constant number := colaborador_logado;
    l_canal constant number := to_number(apex_application.g_x01 default null on conversion error);
    l_nome  constant varchar2(400) :=
      substr(regexp_replace(trim(apex_application.g_x02), '^.*[\\/]', ''), 1, 400);
    l_texto constant varchar2(4000) := substrb(trim(apex_application.g_x03), 1, 4000);
    l_ext   constant varchar2(30) := extensao(l_nome);
    l_qtd   number;
    l_blob  blob;
    l_bytes number;
    l_msg   canal_mensagem.id_canal_mensagem%type;
    l_mime  canal_mensagem_anexo.mime_type%type;
  begin
    if l_eu is null then
      raise_application_error(c_err_anexo, 'Seu usuário não está vinculado a um colaborador.');
    end if;

    -- o canal vem do navegador: só grava se eu participo dele
    select count(*)
      into l_qtd
      from canal_participante
     where id_canal       = l_canal
       and id_colaborador = l_eu;
    if l_qtd = 0 then
      raise_application_error(c_err_anexo, 'Você não participa desta conversa.');
    end if;

    if l_nome is null or mime_anexo(l_ext) is null then
      raise_application_error(c_err_anexo,
        'Tipo de arquivo não aceito. Envie Excel, Word, PowerPoint ou imagem (JPG, PNG, GIF, WEBP ou BMP).');
    end if;

    if apex_application.g_clob_01 is null or dbms_lob.getlength(apex_application.g_clob_01) = 0 then
      raise_application_error(c_err_anexo, 'O arquivo chegou vazio. Tente de novo.');
    end if;
    -- 10 MB em base64 dão cerca de 13,4 milhões de caracteres: recusa antes de decodificar
    if dbms_lob.getlength(apex_application.g_clob_01) > ceil(c_max_anexo / 3) * 4 + 4 then
      raise_application_error(c_err_anexo, 'O arquivo pode ter até 10 MB.');
    end if;

    l_blob  := apex_web_service.clobbase642blob(apex_application.g_clob_01);
    l_bytes := dbms_lob.getlength(l_blob);

    if l_bytes = 0 then
      raise_application_error(c_err_anexo, 'O arquivo chegou vazio. Tente de novo.');
    end if;
    if l_bytes > c_max_anexo then
      raise_application_error(c_err_anexo, 'O arquivo pode ter até 10 MB.');
    end if;
    if not conteudo_confere(l_blob, l_ext) then
      raise_application_error(c_err_anexo,
        'O conteúdo do arquivo não corresponde à extensão .' || l_ext || '.');
    end if;

    -- função privada do package não pode ser chamada dentro do SQL (PLS-00231)
    l_mime := mime_anexo(l_ext);

    -- sem texto, o corpo leva o nome do arquivo (CORPO é obrigatório); a região esconde
    insert into canal_mensagem (id_canal, id_colaborador, corpo)
    values (l_canal, l_eu, nvl(l_texto, substrb(l_nome, 1, 4000)))
    returning id_canal_mensagem into l_msg;

    insert into canal_mensagem_anexo (id_canal_mensagem, nome_arquivo, mime_type, tamanho, conteudo)
    values (l_msg, l_nome, l_mime, l_bytes, l_blob);

    commit;
    responder_anexo(true);
  exception
    when others then
      rollback;
      if sqlcode = c_err_anexo then
        responder_anexo(false, regexp_replace(sqlerrm, '^ORA-\d+: ', ''));
      else
        apex_debug.error('pkg_chat_ui.ajax_enviar_anexo: %s', sqlerrm);
        responder_anexo(false, 'Não foi possível enviar o arquivo. Tente de novo.');
      end if;
  end ajax_enviar_anexo;

  procedure baixar_anexo (
    p_id_anexo in varchar2,
    p_inline   in boolean default false
  ) is
    l_eu   constant number := colaborador_logado;
    l_blob blob;
    l_mime canal_mensagem_anexo.mime_type%type;
    l_nome canal_mensagem_anexo.nome_arquivo%type;
  begin
    -- só quem participa da conversa baixa, e mensagem excluída não entrega o anexo
    select a.conteudo, a.mime_type, a.nome_arquivo
      into l_blob, l_mime, l_nome
      from canal_mensagem_anexo a
      join canal_mensagem m
        on m.id_canal_mensagem = a.id_canal_mensagem
     where a.id_anexo = to_number(p_id_anexo default null on conversion error)
       and nvl(m.excluida, false) = false
       and exists (
             select 1
               from canal_participante cp
              where cp.id_canal       = m.id_canal
                and cp.id_colaborador = l_eu
           );

    apex_http.download(
      p_blob         => l_blob,
      p_content_type => l_mime,
      p_filename     => l_nome,
      p_is_inline    => p_inline and e_imagem(extensao(l_nome)));
  exception
    when no_data_found then
      raise_application_error(c_err_anexo, 'Arquivo não encontrado.');
  end baixar_anexo;

  function html_anexo (
    p_id_anexo in number,
    p_nome     in varchar2,
    p_tamanho  in number
  ) return varchar2 is
    l_ext  constant varchar2(30)  := extensao(p_nome);
    l_nome constant varchar2(120) := substr(p_nome, 1, 120);
    l_url  varchar2(4000);
    l_html varchar2(4000);
  begin
    if e_imagem(l_ext) then
      -- miniatura; clicar abre a imagem inteira numa aba nova
      l_url := apex_page.get_url(
                 p_page    => 4,
                 p_request => 'VER_ANEXO',
                 p_items   => 'P4_ID_ANEXO',
                 p_values  => to_char(p_id_anexo));
      return '<a class="ch-anexo ch-anexo--img" href="' || apex_escape.html_attribute(l_url)
          || '" target="_blank" rel="noopener" title="' || apex_escape.html_attribute(l_nome) || '">'
          || '<img src="' || apex_escape.html_attribute(l_url) || '" alt="'
          || apex_escape.html_attribute(l_nome) || '" loading="lazy"></a>';
    end if;

    l_url := apex_page.get_url(
               p_page    => 4,
               p_request => 'BAIXAR_ANEXO',
               p_items   => 'P4_ID_ANEXO',
               p_values  => to_char(p_id_anexo));

    l_html := '<a class="ch-anexo ch-anexo--arquivo ch-anexo--' || familia(l_ext) || '" href="'
           || apex_escape.html_attribute(l_url) || '" title="Baixar ' || apex_escape.html_attribute(l_nome) || '">'
           || '<span class="ch-anexo-ext">' || apex_escape.html(upper(l_ext)) || '</span>'
           || '<span class="ch-anexo-info"><b>' || apex_escape.html(l_nome) || '</b>'
           || '<small>' || tamanho_texto(p_tamanho) || ' · clique para baixar</small></span></a>';

    if pode_ter_macro(l_ext) then
      l_html := l_html || '<span class="ch-anexo-aviso">&#9888; Pode conter macros: só abra se confiar em quem enviou.</span>';
    end if;

    return l_html;
  end html_anexo;

end pkg_chat_ui;
/
