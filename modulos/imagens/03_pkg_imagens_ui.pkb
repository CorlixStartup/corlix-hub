-- =============================================================================
-- Corlix Hub · Imagens · página "Otimizar imagens"
-- Guia: modulos/imagens/Etapas-imagens.md
-- A compressão acontece no navegador (imagens-pagina.js): o servidor só entrega a
-- imagem atual e grava a versão comprimida, conferindo papel, empresa e conteúdo.
-- =============================================================================
create or replace package body pkg_imagens_ui as

  c_papel      constant varchar2(30) := 'ADMIN_RH';
  c_max_partes constant pls_integer  := 180;   -- 8000 caracteres cada: ~1 MB em base64

  g_html clob;

  e_recusado exception;
  g_mensagem varchar2(400);

  ------------------------------------------------------------------------------
  -- Base
  ------------------------------------------------------------------------------
  procedure inicia is
  begin
    dbms_lob.createtemporary(g_html, true, dbms_lob.call);
  end inicia;

  procedure p (p_txt in varchar2) is
  begin
    if p_txt is not null then
      dbms_lob.writeappend(g_html, length(p_txt), p_txt);
    end if;
  end p;

  function e (p_txt in varchar2) return varchar2 is
  begin
    return apex_escape.html(p_txt);
  end e;

  function a (p_txt in varchar2) return varchar2 is
  begin
    return apex_escape.html_attribute(p_txt);
  end a;

  function icone (p_nome in varchar2) return varchar2 is
    l_svg varchar2(1000);
  begin
    l_svg := case p_nome
      when 'imagem'  then '<rect width="18" height="18" x="3" y="3" rx="2" ry="2"/><circle cx="9" cy="9" r="2"/><path d="m21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21"/>'
      when 'reduzir' then '<polyline points="4 14 10 14 10 20"/><polyline points="20 10 14 10 14 4"/><line x1="14" x2="21" y1="10" y2="3"/><line x1="3" x2="10" y1="21" y2="14"/>'
      when 'ok'      then '<path d="M20 6 9 17l-5-5"/>'
    end;
    return '<svg class="cx-img-icone" width="18" height="18" viewBox="0 0 24 24" aria-hidden="true" focusable="false">'
        || l_svg || '</svg>';
  end icone;

  -- 4,6 MB / 320 KB, com vírgula decimal (idioma técnico da app é en)
  function tamanho (p_bytes in number) return varchar2 is
  begin
    if p_bytes >= 1048576 then
      return to_char(p_bytes / 1048576, 'FM9990D0', 'NLS_NUMERIC_CHARACTERS='',.''') || ' MB';
    end if;
    return to_char(round(p_bytes / 1024), 'FM999990') || ' KB';
  end tamanho;

  function empresa return number is
  begin
    return to_number(v('G_ID_EMPRESA') default null on conversion error);
  end empresa;

  procedure recusar (p_mensagem in varchar2) is
  begin
    g_mensagem := p_mensagem;
    raise e_recusado;
  end recusar;

  procedure confere_acesso is
  begin
    if not apex_authorization.is_authorized(c_papel) then
      recusar('Só o RH pode otimizar imagens.');
    end if;
    if empresa is null then
      recusar('Sua sessão não está vinculada a uma empresa. Saia e entre novamente.');
    end if;
  end confere_acesso;

  procedure responde_erro (p_mensagem in varchar2) is
  begin
    apex_json.open_object;
    apex_json.write('ok', false);
    apex_json.write('mensagem', p_mensagem);
    apex_json.close_object;
  end responde_erro;

  ------------------------------------------------------------------------------
  -- Regiões
  ------------------------------------------------------------------------------
  function render_cabecalho return clob is
  begin
    inicia;
    p('<div class="cx-cabecalho-pagina cx-img-cabecalho">');
    p('<div class="cx-cabecalho-pagina__texto"><h1 class="cx-cabecalho-pagina__titulo">Otimizar imagens</h1>');
    p('<p class="cx-cabecalho-pagina__descricao">Imagens de comunicado acima de '
      || tamanho(pkg_imagens.c_limite_bytes)
      || '. A versão nova é gerada no seu navegador, em JPEG de até 1280 × 720 px, e a original fica guardada.</p></div>');
    p('</div>');
    return g_html;
  end render_cabecalho;

  function render_lista return clob is
    l_emp   constant number := empresa;
    l_qt    pls_integer := 0;
    l_total number := 0;
  begin
    inicia;

    for r in (
      select id_comunicado,
             titulo,
             data_publicacao,
             mime_type,
             dbms_lob.getlength(imagem) as bytes
        from comunicado
       where id_empresa = l_emp
         and imagem is not null
         and dbms_lob.getlength(imagem) > pkg_imagens.c_limite_bytes
       order by dbms_lob.getlength(imagem) desc
    ) loop
      if l_qt = 0 then
        p('<div class="cx-img-lista" data-cx-img-lista>');
        p('<table class="cx-img-tabela"><caption class="u-VisuallyHidden">Imagens de comunicado acima de '
          || tamanho(pkg_imagens.c_limite_bytes) || '</caption>');
        p('<thead><tr><th scope="col">Comunicado</th><th scope="col">Publicado em</th>'
          || '<th scope="col" class="cx-img-num">Tamanho</th><th scope="col">Situação</th>'
          || '<th scope="col"><span class="u-VisuallyHidden">Ação</span></th></tr></thead><tbody>');
      end if;
      l_qt := l_qt + 1;
      l_total := l_total + r.bytes;

      p('<tr data-cx-img-linha="' || r.id_comunicado || '">');
      p('<th scope="row" class="cx-img-titulo">' || e(r.titulo)
        || '<span class="cx-img-tipo">' || e(lower(regexp_replace(nvl(r.mime_type, '?'), '^image/', ''))) || '</span></th>');
      p('<td>' || to_char(r.data_publicacao, 'DD/MM/YYYY') || '</td>');
      p('<td class="cx-img-num">' || tamanho(r.bytes) || '</td>');
      p('<td class="cx-img-status" data-cx-img-status aria-live="polite">Aguardando</td>');
      p('<td class="cx-img-acao"><button type="button" class="t-Button t-Button--small" data-cx-img-otimizar data-id="'
        || r.id_comunicado || '">' || icone('reduzir') || '<span class="t-Button-label">Otimizar</span></button></td>');
      p('</tr>');
    end loop;

    if l_qt = 0 then
      p('<div class="cx-img-vazio">' || icone('ok')
        || '<p>Nenhuma imagem de comunicado acima de ' || tamanho(pkg_imagens.c_limite_bytes) || '.</p></div>');
    else
      p('</tbody></table>');
      p('<div class="cx-img-rodape"><p class="cx-img-resumo">' || l_qt
        || case when l_qt = 1 then ' imagem, ' else ' imagens, ' end
        || tamanho(l_total) || ' no total.</p>');
      p('<button type="button" class="t-Button t-Button--hot" data-cx-img-todas>' || icone('reduzir')
        || '<span class="t-Button-label">Otimizar todas</span></button></div>');
      p('</div>');
    end if;

    return g_html;
  end render_lista;

  ------------------------------------------------------------------------------
  -- Ajax
  ------------------------------------------------------------------------------
  procedure ajax_obter is
    l_id     constant number := to_number(apex_application.g_x01 default null on conversion error);
    l_imagem blob;
    l_mime   varchar2(255);
  begin
    confere_acesso;
    begin
      pkg_imagens.obter_comunicado(l_id, empresa, l_imagem, l_mime);
    exception
      when no_data_found then
        recusar('Comunicado não encontrado nesta empresa.');
    end;

    apex_json.open_object;
    apex_json.write('ok', true);
    apex_json.write('mime', nvl(l_mime, 'image/png'));
    apex_json.write('imagem', apex_web_service.blob2clobbase64(l_imagem, p_newlines => 'N', p_padding => 'Y'));
    apex_json.close_object;
  exception
    when e_recusado then
      responde_erro(g_mensagem);
    when others then
      apex_debug.error('pkg_imagens_ui.ajax_obter: %s', sqlerrm);
      responde_erro('Não foi possível ler a imagem agora. Tente de novo em alguns minutos.');
  end ajax_obter;

  procedure ajax_salvar is
    l_id     constant number := to_number(apex_application.g_x01 default null on conversion error);
    l_emp    constant number := empresa;   -- função privada não pode ir dentro do SQL
    l_clob   clob;
    l_blob   blob;
    l_antes  number;
    l_erro   varchar2(400);
  begin
    confere_acesso;

    if apex_application.g_f01.count = 0 then
      recusar('A imagem comprimida não chegou ao servidor. Tente de novo.');
    elsif apex_application.g_f01.count > c_max_partes then
      recusar('A imagem comprimida passou de 1 MB. Nada foi alterado.');
    end if;

    dbms_lob.createtemporary(l_clob, true, dbms_lob.call);
    for i in 1 .. apex_application.g_f01.count loop
      if apex_application.g_f01(i) is not null then
        dbms_lob.writeappend(l_clob, length(apex_application.g_f01(i)), apex_application.g_f01(i));
      end if;
    end loop;
    l_blob := apex_web_service.clobbase642blob(l_clob);

    select dbms_lob.getlength(imagem)
      into l_antes
      from comunicado
     where id_comunicado = l_id
       and id_empresa = l_emp;

    l_erro := pkg_imagens.trocar_comunicado(l_id, l_emp, l_blob, v('APP_USER'));
    if l_erro is not null then
      rollback;
      recusar(l_erro);
    end if;
    commit;

    apex_json.open_object;
    apex_json.write('ok', true);
    apex_json.write('mensagem', tamanho(l_antes) || ' → ' || tamanho(dbms_lob.getlength(l_blob)));
    apex_json.write('antes', l_antes);
    apex_json.write('depois', dbms_lob.getlength(l_blob));
    apex_json.close_object;
  exception
    when e_recusado then
      responde_erro(g_mensagem);
    when no_data_found then
      responde_erro('Comunicado não encontrado nesta empresa.');
    when others then
      rollback;
      apex_debug.error('pkg_imagens_ui.ajax_salvar: %s', sqlerrm);
      responde_erro('Não foi possível salvar a imagem agora. Tente de novo em alguns minutos.');
  end ajax_salvar;

end pkg_imagens_ui;
/
