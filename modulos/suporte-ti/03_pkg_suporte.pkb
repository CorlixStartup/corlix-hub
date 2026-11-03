--------------------------------------------------------------------------------
-- Corlix Hub · Suporte TI · 03 · regras de negócio · corpo
--------------------------------------------------------------------------------
create or replace package body pkg_suporte as

  c_err_vinculo   constant pls_integer := -20076;
  c_err_chamado   constant pls_integer := -20077;
  c_err_dados     constant pls_integer := -20078;
  c_err_anexo     constant pls_integer := -20079;
  c_err_situacao  constant pls_integer := -20080;
  c_err_permissao constant pls_integer := -20081;
  c_err_mensagem  constant pls_integer := -20082;
  c_err_previsao  constant pls_integer := -20083;
  c_err_acao      constant pls_integer := -20084;

  c_msg_chamado constant varchar2(100) := 'Chamado não encontrado.';

  ------------------------------------------------------------------------------
  -- Utilitários
  ------------------------------------------------------------------------------
  function em_sessao_apex return boolean is
  begin
    return sys_context('APEX$SESSION', 'APP_SESSION') is not null;
  end em_sessao_apex;

  function usuario_atual return varchar2 is
  begin
    return coalesce(sys_context('APEX$SESSION', 'APP_USER'), sys_context('USERENV', 'SESSION_USER'));
  end usuario_atual;

  function exige_texto (p_texto in varchar2, p_erro in varchar2) return varchar2 is
    l_texto constant varchar2(32767) := trim(p_texto);
  begin
    if l_texto is null then
      raise_application_error(c_err_mensagem, p_erro);
    end if;
    if lengthb(l_texto) > 4000 then -- a coluna é em bytes; acento ocupa mais de um
      raise_application_error(c_err_mensagem, 'O texto ficou longo demais. Resuma em até cerca de 3.500 caracteres.');
    end if;
    return l_texto;
  end exige_texto;

  -- Tipos aceitos. O tipo gravado vem da extensão, e não do que o navegador
  -- informou; o download sempre sai como anexo, nunca aberto na página.
  function mime_permitido (p_arquivo in varchar2) return varchar2 is
    l_extensao constant varchar2(255) := lower(regexp_substr(p_arquivo, '\.([^.]+)$', 1, 1, null, 1));
  begin
    return case l_extensao
      when 'png'  then 'image/png'
      when 'jpg'  then 'image/jpeg'
      when 'jpeg' then 'image/jpeg'
      when 'pdf'  then 'application/pdf'
      when 'txt'  then 'text/plain'
      when 'log'  then 'text/plain'
    end;
  end mime_permitido;

  procedure guardar_anexo (p_id_chamado in number, p_id_mensagem in number, p_anexo in varchar2) is
    l_nome  apex_application_temp_files.filename%type;
    l_blob  blob;
    l_bytes number;
    l_mime  varchar2(100);
    l_usr   constant varchar2(255) := usuario_atual;
  begin
    if p_anexo is null then
      return;
    end if;

    begin
      select filename, blob_content
        into l_nome, l_blob
        from apex_application_temp_files
       where name = p_anexo;
    exception
      when no_data_found then
        raise_application_error(c_err_anexo, 'O arquivo enviado não foi encontrado. Envie de novo.');
    end;

    l_nome  := regexp_replace(l_nome, '^.*[\\/]', '');
    l_mime  := mime_permitido(l_nome);
    l_bytes := dbms_lob.getlength(l_blob);

    if l_mime is null then
      raise_application_error(c_err_anexo, 'Envie uma imagem PNG ou JPG, um PDF ou um arquivo TXT ou LOG.');
    end if;
    if l_bytes > c_max_anexo then
      raise_application_error(c_err_anexo, 'O arquivo pode ter até 5 MB.');
    end if;

    insert into suporte_anexo (id_chamado, id_mensagem, nm_arquivo, ds_mime, nr_bytes, bl_arquivo, usr_envio)
    values (p_id_chamado, p_id_mensagem, substr(l_nome, 1, 255), l_mime, l_bytes, l_blob, l_usr);
  end guardar_anexo;

  function grava_mensagem (
    p_id_chamado in number,
    p_id_autor   in number,
    p_tp_autor   in varchar2,
    p_texto      in varchar2
  ) return number is
    l_id number;
  begin
    insert into suporte_mensagem (id_chamado, id_autor, tp_autor, ds_texto)
    values (p_id_chamado, p_id_autor, p_tp_autor, p_texto)
    returning id_mensagem into l_id;
    return l_id;
  end grava_mensagem;

  -- Trava o chamado, se for da empresa da sessão. Quem pode agir é conferido por
  -- quem chama.
  function chamado_travado (p_id_chamado in number) return suporte_chamado%rowtype is
    l_c       suporte_chamado%rowtype;
    l_empresa constant number := pkg_historico_carreira.fn_empresa_contexto;
  begin
    select *
      into l_c
      from suporte_chamado
     where id_chamado = p_id_chamado
       and id_empresa = l_empresa
       for update;
    return l_c;
  exception
    when no_data_found then
      raise_application_error(c_err_chamado, c_msg_chamado);
  end chamado_travado;

  -- Só o próprio solicitante. Para a TI, o chamado de outra pessoa é tratado na p39.
  function chamado_do_solicitante (p_id_chamado in number, p_id_colaborador in number) return suporte_chamado%rowtype is
    l_c suporte_chamado%rowtype := chamado_travado(p_id_chamado);
  begin
    if l_c.id_solicitante <> p_id_colaborador then
      raise_application_error(c_err_chamado, c_msg_chamado);
    end if;
    return l_c;
  end chamado_do_solicitante;

  ------------------------------------------------------------------------------
  -- Públicas: conta e permissões
  ------------------------------------------------------------------------------
  function fn_colaborador_logado return number is
    l_id      number;
    l_usuario constant varchar2(255) := usuario_atual;
    l_empresa constant number := pkg_historico_carreira.fn_empresa_contexto;
  begin
    select id_colaborador
      into l_id
      from colaborador
     where upper(trim(login_apex)) = upper(trim(l_usuario))
       and id_empresa = l_empresa;
    return l_id;
  exception
    when no_data_found or too_many_rows then
      raise_application_error(c_err_vinculo, 'Sua conta não está vinculada a um colaborador desta empresa. Fale com o RH.');
  end fn_colaborador_logado;

  function fn_e_ti return varchar2 is
  begin
    return case when em_sessao_apex and apex_authorization.is_authorized('SUPORTE_TI') then 'S' else 'N' end;
  end fn_e_ti;

  function fn_codigo (p_tp_chamado in varchar2, p_id_chamado in number) return varchar2 is
  begin
    return p_tp_chamado || '-' || p_id_chamado;
  end fn_codigo;

  function fn_situacao (p_id_chamado in number) return varchar2 is
    l_st         suporte_chamado.st_chamado%type;
    l_solicitante number;
    l_empresa    constant number := pkg_historico_carreira.fn_empresa_contexto;
  begin
    select st_chamado, id_solicitante
      into l_st, l_solicitante
      from suporte_chamado
     where id_chamado = p_id_chamado
       and id_empresa = l_empresa;

    if fn_e_ti = 'S' or l_solicitante = fn_colaborador_logado then
      return l_st;
    end if;
    raise_application_error(c_err_chamado, c_msg_chamado);
  exception
    when no_data_found then
      raise_application_error(c_err_chamado, c_msg_chamado);
  end fn_situacao;

  ------------------------------------------------------------------------------
  -- Públicas: colaborador
  ------------------------------------------------------------------------------
  function abrir_chamado (
    p_tp_chamado in varchar2,
    p_id_assunto in number,
    p_ds_titulo  in varchar2,
    p_ds_texto   in varchar2,
    p_anexo      in varchar2 default null
  ) return number is
    l_autor   constant number := fn_colaborador_logado;
    l_empresa constant number := pkg_historico_carreira.fn_empresa_contexto;
    l_titulo  constant varchar2(32767) := trim(p_ds_titulo);
    l_texto   constant varchar2(4000) := exige_texto(p_ds_texto, 'Descreva o que está acontecendo.');
    l_qt      pls_integer;
    l_id      number;
  begin
    if p_tp_chamado is null or p_tp_chamado not in ('INC', 'REQ') then
      raise_application_error(c_err_dados, 'Escolha o tipo do chamado.');
    end if;
    if l_titulo is null or lengthb(l_titulo) > 150 then
      raise_application_error(c_err_dados, 'Informe um título curto, de até 140 caracteres.');
    end if;

    select count(*)
      into l_qt
      from suporte_assunto
     where id_assunto = p_id_assunto
       and id_empresa = l_empresa
       and fl_ativo = 'S';
    if l_qt = 0 then
      raise_application_error(c_err_dados, 'Escolha um assunto da lista.');
    end if;

    insert into suporte_chamado (id_empresa, id_solicitante, tp_chamado, id_assunto, ds_titulo, ds_descricao)
    values (l_empresa, l_autor, p_tp_chamado, p_id_assunto, l_titulo, l_texto)
    returning id_chamado into l_id;

    guardar_anexo(l_id, null, p_anexo);
    return l_id;
  end abrir_chamado;

  procedure responder (
    p_id_chamado in number,
    p_ds_texto   in varchar2,
    p_anexo      in varchar2 default null
  ) is
    l_autor constant number := fn_colaborador_logado;
    l_c     suporte_chamado%rowtype := chamado_do_solicitante(p_id_chamado, l_autor);
    l_texto constant varchar2(4000) := exige_texto(p_ds_texto, 'Escreva a sua resposta.');
    l_msg   number;
    l_novo  suporte_chamado.st_chamado%type := l_c.st_chamado;
  begin
    if l_c.st_chamado not in (c_aberto, c_atendimento, c_aguardando) then
      raise_application_error(c_err_situacao, 'Este chamado não aceita mais respostas. Atualize a página.');
    end if;

    if l_c.st_chamado = c_aguardando then
      l_novo := case when l_c.id_atendente is null then c_aberto else c_atendimento end;
    end if;

    l_msg := grava_mensagem(p_id_chamado, l_autor, 'COLABORADOR', l_texto);
    guardar_anexo(p_id_chamado, l_msg, p_anexo);

    update suporte_chamado
       set st_chamado = l_novo, dh_atualizacao = systimestamp
     where id_chamado = p_id_chamado;
  end responder;

  procedure confirmar_solucao (p_id_chamado in number) is
    l_autor constant number := fn_colaborador_logado;
    l_c     suporte_chamado%rowtype := chamado_do_solicitante(p_id_chamado, l_autor);
    l_msg   number;
  begin
    if l_c.st_chamado <> c_resolvido then
      raise_application_error(c_err_situacao, 'Este chamado não está aguardando confirmação. Atualize a página.');
    end if;

    l_msg := grava_mensagem(p_id_chamado, null, 'SISTEMA', 'Solução confirmada pelo colaborador. Chamado encerrado.');

    update suporte_chamado
       set st_chamado = c_encerrado,
           tp_encerramento = 'CONFIRMADO',
           dh_encerramento = systimestamp,
           dh_atualizacao = systimestamp
     where id_chamado = p_id_chamado;
  end confirmar_solucao;

  procedure reabrir (
    p_id_chamado in number,
    p_ds_texto   in varchar2,
    p_anexo      in varchar2 default null
  ) is
    l_autor constant number := fn_colaborador_logado;
    l_c     suporte_chamado%rowtype := chamado_do_solicitante(p_id_chamado, l_autor);
    l_texto constant varchar2(4000) := exige_texto(p_ds_texto, 'Conte o que ainda não funcionou.');
    l_msg   number;
  begin
    if l_c.st_chamado <> c_resolvido then
      raise_application_error(c_err_situacao, 'Só um chamado resolvido pode ser reaberto. Atualize a página.');
    end if;

    l_msg := grava_mensagem(p_id_chamado, l_autor, 'COLABORADOR', l_texto);
    guardar_anexo(p_id_chamado, l_msg, p_anexo);

    update suporte_chamado
       set st_chamado = case when id_atendente is null then c_aberto else c_atendimento end,
           ds_solucao = null,
           dt_limite_confirmacao = null,
           dh_resolucao = null,
           nr_reaberturas = nr_reaberturas + 1,
           dh_atualizacao = systimestamp
     where id_chamado = p_id_chamado;
  end reabrir;

  ------------------------------------------------------------------------------
  -- Públicas: TI
  ------------------------------------------------------------------------------
  procedure atender (
    p_id_chamado    in number,
    p_acao          in varchar2,
    p_ds_texto      in varchar2,
    p_tp_prioridade in varchar2,
    p_dt_previsao   in varchar2,
    p_anexo         in varchar2 default null
  ) is
    l_autor    number;
    l_c        suporte_chamado%rowtype;
    l_texto    varchar2(4000);
    l_previsao date;
    l_hoje     date;
    l_dias     suporte_config.nr_dias_confirmacao%type;
    l_msg      number;
    l_novo     suporte_chamado.st_chamado%type;
  begin
    if fn_e_ti <> 'S' then
      raise_application_error(c_err_permissao, 'Só a equipe de TI pode atender chamados.');
    end if;
    l_autor := fn_colaborador_logado;
    l_c     := chamado_travado(p_id_chamado);
    l_hoje  := pkg_historico_carreira.fn_hoje(l_c.id_empresa);

    if l_c.st_chamado not in (c_aberto, c_atendimento, c_aguardando) then
      raise_application_error(c_err_situacao, 'Este chamado já foi resolvido ou encerrado. Atualize a página.');
    end if;
    if p_tp_prioridade is null or p_tp_prioridade not in ('BAIXA', 'MEDIA', 'ALTA') then
      raise_application_error(c_err_dados, 'Escolha a prioridade.');
    end if;

    if trim(p_dt_previsao) is not null then
      l_previsao := to_date(p_dt_previsao default null on conversion error, 'DD/MM/YYYY');
      if l_previsao is null or l_previsao < l_hoje then
        raise_application_error(c_err_previsao, 'Informe uma previsão válida, a partir de hoje.');
      end if;
    end if;

    case p_acao
      when 'ASSUMIR' then
        l_texto := case when trim(p_ds_texto) is not null then exige_texto(p_ds_texto, null) end;
        l_novo  := c_atendimento;
        l_c.id_atendente := l_autor;
      when 'RESPONDER' then
        l_texto := exige_texto(p_ds_texto, 'Escreva a mensagem ao colaborador.');
        l_novo  := c_atendimento;
      when 'PEDIR' then
        l_texto := exige_texto(p_ds_texto, 'Escreva o que você precisa do colaborador.');
        l_novo  := c_aguardando;
      when 'RESOLVER' then
        l_texto := exige_texto(p_ds_texto, 'Descreva a solução para o colaborador.');
        l_novo  := c_resolvido;
      else
        raise_application_error(c_err_acao, 'Escolha o que fazer com o chamado.');
    end case;

    l_c.id_atendente := nvl(l_c.id_atendente, l_autor);

    if l_texto is not null then
      l_msg := grava_mensagem(p_id_chamado, l_autor, 'TI', l_texto);
    elsif p_anexo is not null then
      raise_application_error(c_err_mensagem, 'Escreva uma mensagem para enviar o arquivo.');
    end if;
    guardar_anexo(p_id_chamado, l_msg, p_anexo);

    if p_acao = 'RESOLVER' then
      begin
        select nr_dias_confirmacao into l_dias from suporte_config where id_empresa = l_c.id_empresa;
      exception
        when no_data_found then
          l_dias := 3;
      end;
    end if;

    update suporte_chamado
       set st_chamado = l_novo,
           id_atendente = l_c.id_atendente,
           tp_prioridade = p_tp_prioridade,
           dt_previsao = l_previsao,
           ds_solucao = case when p_acao = 'RESOLVER' then l_texto end,
           dh_resolucao = case when p_acao = 'RESOLVER' then systimestamp end,
           dt_limite_confirmacao = case when p_acao = 'RESOLVER' then l_hoje + l_dias end,
           dh_atualizacao = systimestamp
     where id_chamado = p_id_chamado;
  end atender;

  function encerrar_vencidos return number is
    l_qt  pls_integer := 0;
    l_msg number;
  begin
    for r in (
      select id_chamado
        from suporte_chamado
       where st_chamado = c_resolvido
         and dt_limite_confirmacao <= pkg_historico_carreira.fn_hoje(id_empresa)
         for update
    ) loop
      l_msg := grava_mensagem(r.id_chamado, null, 'SISTEMA', 'Encerrado automaticamente: o prazo de confirmação terminou sem resposta.');
      update suporte_chamado
         set st_chamado = c_encerrado,
             tp_encerramento = 'AUTOMATICO',
             dh_encerramento = systimestamp,
             dh_atualizacao = systimestamp
       where id_chamado = r.id_chamado;
      l_qt := l_qt + 1;
    end loop;
    commit;
    return l_qt;
  end encerrar_vencidos;

  ------------------------------------------------------------------------------
  -- Públicas: artigos e anexos
  ------------------------------------------------------------------------------
  procedure registrar_acesso_artigo (p_id_artigo in number) is
    l_empresa constant number := pkg_historico_carreira.fn_empresa_contexto;
  begin
    update suporte_artigo
       set nr_acessos = nr_acessos + 1
     where id_artigo = p_id_artigo
       and id_empresa = l_empresa
       and fl_publicado = 'S';
  end registrar_acesso_artigo;

  procedure baixar_anexo (p_id_anexo in number) is
    l_blob    blob;
    l_mime    suporte_anexo.ds_mime%type;
    l_nome    suporte_anexo.nm_arquivo%type;
    l_chamado number;
    l_st      suporte_chamado.st_chamado%type;
  begin
    begin
      select id_chamado, bl_arquivo, ds_mime, nm_arquivo
        into l_chamado, l_blob, l_mime, l_nome
        from suporte_anexo
       where id_anexo = p_id_anexo;
    exception
      when no_data_found then
        raise_application_error(c_err_chamado, 'Arquivo não encontrado.');
    end;

    l_st := fn_situacao(l_chamado); -- -20077 se a conta não pode ver o chamado

    apex_http.download(
      p_blob         => l_blob,
      p_content_type => l_mime,
      p_filename     => l_nome,
      p_is_inline    => false);
  end baixar_anexo;

end pkg_suporte;
/
