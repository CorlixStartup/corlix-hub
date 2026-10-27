--------------------------------------------------------------------------------
-- Corlix Hub · Busca na intranet (página 29) · corpo
-- Fotos: mesmo padrão da Home (pkg_home_ui). FOTO_URL guarda o nome do arquivo
-- em "Fotos Colaboradores/"; o HTML sai com data-cx-foto e o JS da página 29
-- completa o src com apex.env.APP_FILES. Se a imagem falhar, o onerror remove a
-- <img> e as iniciais ficam visíveis.
-- O termo chega pela URL (friendly URL: ...?session=...&p29_termo=<termo>), por
-- isso a página 29 e o P29_TERMO não exigem checksum. Todo texto do termo que
-- volta para o HTML passa por apex_escape.
--------------------------------------------------------------------------------
create or replace package body pkg_busca_ui as

  c_nls_data    constant varchar2(60) := 'NLS_DATE_LANGUAGE=''BRAZILIAN PORTUGUESE''';
  c_pasta_fotos constant varchar2(30) := 'Fotos Colaboradores/';
  c_item_termo  constant varchar2(30) := 'p29_termo';  -- nome do item na URL
  c_min_letras  constant pls_integer  := 2;
  c_limite      constant pls_integer  := 20;           -- linhas por grupo

  -- Busca sem acento: lower() e depois troca as letras acentuadas.
  -- Tamanhos em CHAR: em UTF-8 cada letra acentuada ocupa 2 bytes.
  c_com_acento  constant varchar2(30 char) := 'áàâãäéèêëíìîïóòôõöúùûüç';
  c_sem_acento  constant varchar2(30 char) := 'aaaaaeeeeiiiiooooouuuuc';

  g_html clob;

  cursor c_pessoas (p_padrao in varchar2, p_empresa in number) is
    select c.id_colaborador,
           c.nome_completo,
           c.foto_url,
           c.login_apex,
           cg.nome as cargo,
           d.nome  as departamento
      from colaborador c
      left join cargo cg
        on cg.id_cargo = c.id_cargo
      left join departamento d
        on d.id_departamento = c.id_departamento
     where c.id_empresa = p_empresa
       and c.status = true
       and (   translate(lower(c.nome_completo), c_com_acento, c_sem_acento) like p_padrao escape '\'
            or translate(lower(cg.nome),         c_com_acento, c_sem_acento) like p_padrao escape '\'
            or translate(lower(d.nome),          c_com_acento, c_sem_acento) like p_padrao escape '\')
     order by c.nome_completo;

  cursor c_comunicados (p_padrao in varchar2, p_empresa in number) is
    select c.id_comunicado,
           c.titulo,
           -- resumo em texto puro: tira as tags do editor e corta em 220 caracteres
           substr(trim(regexp_replace(regexp_replace(dbms_lob.substr(c.conteudo, 1000, 1),
                                                     '<[^>]+>', ' '),
                                      '\s+', ' ')), 1, 220) as resumo,
           'Para: ' || nvl(d.nome, 'Todos') as publico,
           c.data_publicacao
      from comunicado c
      left join departamento d
        on d.id_departamento = c.id_departamento
     where c.id_empresa = p_empresa
       and (   translate(lower(c.titulo), c_com_acento, c_sem_acento) like p_padrao escape '\'
            or translate(lower(dbms_lob.substr(c.conteudo, 2000, 1)), c_com_acento, c_sem_acento)
                 like p_padrao escape '\')
     order by c.data_publicacao desc, c.id_comunicado desc;

  ------------------------------------------------------------------------------
  -- Utilitários
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

  function termo_limpo (p_termo in varchar2) return varchar2 is
  begin
    return substr(trim(regexp_replace(p_termo, '\s+', ' ')), 1, 100);
  end termo_limpo;

  -- Vazio vale: a busca vazia lista todas as pessoas e todos os comunicados
  function termo_valido (p_termo in varchar2) return boolean is
  begin
    return termo_limpo(p_termo) is null or length(termo_limpo(p_termo)) >= c_min_letras;
  end termo_valido;

  -- '%termo%' sem acento, com % e _ do termo escapados (escape '\'); termo vazio vira '%%'
  function padrao (p_termo in varchar2) return varchar2 is
    l_termo varchar2(1000 char) := translate(lower(termo_limpo(p_termo)), c_com_acento, c_sem_acento);
  begin
    l_termo := replace(replace(replace(l_termo, '\', '\\'), '%', '\%'), '_', '\_');
    return '%' || l_termo || '%';
  end padrao;

  function qtd_pessoas (p_padrao in varchar2, p_empresa in number) return pls_integer is
    l_qt pls_integer := 0;
  begin
    for r in c_pessoas(p_padrao, p_empresa) loop
      l_qt := l_qt + 1;
    end loop;
    return l_qt;
  end qtd_pessoas;

  function qtd_comunicados (p_padrao in varchar2, p_empresa in number) return pls_integer is
    l_qt pls_integer := 0;
  begin
    for r in c_comunicados(p_padrao, p_empresa) loop
      l_qt := l_qt + 1;
    end loop;
    return l_qt;
  end qtd_comunicados;

  -- "7 de janeiro" (com o ano quando não for o ano corrente)
  function data_curta (p_data in date) return varchar2 is
  begin
    return to_char(p_data, 'fmdd') || ' de ' || to_char(p_data, 'fmmonth', c_nls_data)
        || case when extract(year from p_data) <> extract(year from sysdate)
                then ' de ' || to_char(p_data, 'yyyy')
           end;
  end data_curta;

  function iniciais (p_nome in varchar2) return varchar2 is
    l_nome varchar2(400 char) := trim(regexp_replace(p_nome, '\s+', ' '));
  begin
    if l_nome is null then
      return '?';
    elsif instr(l_nome, ' ') = 0 then
      return upper(substr(l_nome, 1, 2));
    end if;
    -- primeira letra do primeiro nome + primeira letra do último sobrenome
    return upper(substr(l_nome, 1, 1) || substr(l_nome, instr(l_nome, ' ', -1) + 1, 1));
  end iniciais;

  -- Iniciais com a foto por cima (quando houver)
  function avatar (p_nome in varchar2, p_foto_url in varchar2) return varchar2 is
    l_foto varchar2(4000) := regexp_replace(trim(p_foto_url), '^#APP_FILES#', '');
    l_img  varchar2(4000);
  begin
    if l_foto is null or l_foto = c_pasta_fotos then
      l_img := null;
    elsif regexp_like(l_foto, '^(https?:)?//|^/', 'i') then
      l_img := 'src="' || a(l_foto) || '"';
    else
      if l_foto not like c_pasta_fotos || '%' then
        l_foto := c_pasta_fotos || l_foto;
      end if;
      l_img := 'data-cx-foto="' || a(l_foto) || '"';
    end if;

    return '<span class="cx-avatar" aria-hidden="true">' || e(iniciais(p_nome))
        || case when l_img is not null then
             '<img ' || l_img || ' alt="" onerror="this.remove()">'
           end
        || '</span>';
  end avatar;

  -- Título do card com ícone e contagem: "Pessoas (2)"
  procedure abre_card (p_id in varchar2, p_icone in varchar2, p_titulo in varchar2, p_qt in pls_integer) is
  begin
    p('<section class="cx-busca-card" aria-labelledby="' || p_id || '">');
    p('<h2 id="' || p_id || '" class="cx-busca-card__titulo">'
      || '<span class="fa ' || p_icone || '" aria-hidden="true"></span>' || p_titulo
      || '<span class="cx-busca-card__qtd">' || p_qt || '</span></h2>');
    p('<ul class="cx-busca-lista">');
  end abre_card;

  procedure fecha_card (p_qt in pls_integer, p_rotulo in varchar2) is
  begin
    p('</ul>');
    if p_qt > c_limite then
      p('<p class="cx-busca-card__rodape">Mostrando ' || c_limite || ' de ' || p_qt || ' ' || p_rotulo
        || '. Use um termo mais espec&iacute;fico para ver os outros.</p>');
    end if;
    p('</section>');
  end fecha_card;

  -- Estado vazio: ícone em círculo + título + orientação (textos já em HTML)
  procedure estado_vazio (p_icone in varchar2, p_titulo in varchar2, p_texto in varchar2) is
  begin
    p('<section class="cx-busca-card"><div class="cx-home-vazio">'
      || '<span class="cx-avatar cx-avatar--vazio" aria-hidden="true"><span class="fa ' || p_icone || '"></span></span>'
      || '<div><strong class="cx-home-vazio__titulo">' || p_titulo || '</strong>'
      || '<p class="cx-home-vazio__texto">' || p_texto || '</p></div></div></section>');
  end estado_vazio;

  ------------------------------------------------------------------------------
  -- Públicas
  ------------------------------------------------------------------------------
  function render_campo return clob is
    l_termo varchar2(400 char);
    -- clear_cache: sem isso, a busca vazia herdaria o termo anterior da sessão
    l_url   varchar2(4000) := apex_page.get_url(p_page => c_pagina, p_clear_cache => c_pagina);
  begin
    -- Na própria página de resultados, o campo volta preenchido com o termo
    if v('APP_PAGE_ID') = to_char(c_pagina) then
      l_termo := termo_limpo(v(upper(c_item_termo)));
    end if;

    inicia;
    p('<div class="corlix-header__search" role="search">');
    p('<span class="fa fa-search corlix-header__search-icon" aria-hidden="true"></span>');
    -- Enter leva à página 29 com o termo na URL (vazio: lista tudo); preventDefault impede o
    -- submit da página atual
    p('<input type="search" id="cx-busca-global" class="corlix-header__search-input"'
      || ' placeholder="Buscar na intranet..." aria-label="Buscar na intranet"'
      || ' autocomplete="off" enterkeyhint="search" maxlength="100"'
      || ' value="' || a(l_termo) || '"'
      || ' data-url="' || a(l_url) || '"'
      || ' onkeydown="if (event.key === ''Enter'') { event.preventDefault();'
      || ' var t = this.value.trim(); location.href = this.dataset.url'
      || ' + (t ? (this.dataset.url.indexOf(''?'') < 0 ? ''?'' : ''&amp;'')'
      || ' + ''' || c_item_termo || '='' + encodeURIComponent(t) : ''''); }">');
    p('</div>');
    return g_html;
  end render_campo;

  function render_cabecalho (
    p_termo      in varchar2,
    p_id_empresa in number default to_number(v('G_ID_EMPRESA') default null on conversion error)
  ) return clob is
    l_termo varchar2(400 char) := termo_limpo(p_termo);
    l_qt    pls_integer;
  begin
    inicia;
    p('<div class="cx-busca-cabecalho">');

    if l_termo is null then
      p('<h1 class="cx-busca-cabecalho__titulo">Buscar na intranet</h1>');
      if p_id_empresa is null then
        p('<p class="cx-busca-cabecalho__resumo">Nenhum resultado em Pessoas e Comunicados</p>');
      else
        l_qt := qtd_pessoas(padrao(null), p_id_empresa) + qtd_comunicados(padrao(null), p_id_empresa);
        p('<p class="cx-busca-cabecalho__resumo">'
          || case l_qt when 0 then 'Nenhuma pessoa ou comunicado na sua empresa'
                       when 1 then '1 resultado em Pessoas e Comunicados'
                       else l_qt || ' resultados em Pessoas e Comunicados' end
          || '. Digite um termo no campo de busca para filtrar.</p>');
      end if;
    else
      p('<h1 class="cx-busca-cabecalho__titulo">Resultados para &ldquo;' || e(l_termo) || '&rdquo;</h1>');
      if not termo_valido(l_termo) then
        p('<p class="cx-busca-cabecalho__resumo">Digite pelo menos ' || c_min_letras || ' letras.</p>');
      elsif p_id_empresa is null then
        p('<p class="cx-busca-cabecalho__resumo">Nenhum resultado em Pessoas e Comunicados</p>');
      else
        l_qt := qtd_pessoas(padrao(l_termo), p_id_empresa) + qtd_comunicados(padrao(l_termo), p_id_empresa);
        p('<p class="cx-busca-cabecalho__resumo">'
          || case l_qt when 0 then 'Nenhum resultado'
                       when 1 then '1 resultado'
                       else l_qt || ' resultados' end
          || ' em Pessoas e Comunicados</p>');
      end if;
    end if;

    p('</div>');
    return g_html;
  end render_cabecalho;

  function render_resultados (
    p_termo      in varchar2,
    p_id_empresa in number default to_number(v('G_ID_EMPRESA') default null on conversion error),
    p_login      in varchar2 default v('APP_USER')
  ) return clob is
    l_termo  varchar2(400 char) := termo_limpo(p_termo);
    l_padrao varchar2(400 char);
    l_qt_p   pls_integer;
    l_qt_c   pls_integer;
    l_n      pls_integer;
  begin
    inicia;

    -- Termo curto demais: o cabeçalho já orienta. Termo vazio lista tudo.
    if not termo_valido(l_termo) then
      return g_html;
    end if;

    if p_id_empresa is null then
      estado_vazio('fa-search', 'Nenhum resultado',
        'A busca procura na sua empresa. Seu perfil ainda n&atilde;o est&aacute; vinculado a uma; '
        || 'procure o RH ou a administra&ccedil;&atilde;o do CorlixHub.');
      return g_html;
    end if;

    l_padrao := padrao(l_termo);
    l_qt_p   := qtd_pessoas(l_padrao, p_id_empresa);
    l_qt_c   := qtd_comunicados(l_padrao, p_id_empresa);

    if l_qt_p + l_qt_c = 0 and l_termo is null then
      estado_vazio('fa-search', 'Nenhuma pessoa ou comunicado na sua empresa',
        'Quando houver colaboradores ativos ou comunicados publicados, eles aparecem aqui.');
      return g_html;
    elsif l_qt_p + l_qt_c = 0 then
      estado_vazio('fa-search', 'Nenhum resultado para &ldquo;' || e(l_termo) || '&rdquo;',
        'Confira a grafia ou tente outro termo: nome, cargo ou departamento de uma pessoa, '
        || 'ou parte do t&iacute;tulo de um comunicado.');
      return g_html;
    end if;

    if l_qt_p > 0 then
      abre_card('cx-busca-pessoas', 'fa-users', 'Pessoas', l_qt_p);
      l_n := 0;
      for r in c_pessoas(l_padrao, p_id_empresa) loop
        l_n := l_n + 1;
        exit when l_n > c_limite;
        p('<li class="cx-busca-lista__item">');
        p('<div class="cx-pessoa">' || avatar(r.nome_completo, r.foto_url) || '<div>'
          || '<a class="cx-busca__link" href="'
          || a(apex_page.get_url(p_page => 3, p_items => 'P3_ID_FOCO', p_values => r.id_colaborador))
          || '">' || e(r.nome_completo) || '</a>'
          || case when r.cargo is not null or r.departamento is not null then
               '<span class="cx-pessoa__detalhe">'
               || e(r.cargo || case when r.cargo is not null and r.departamento is not null then ' · ' end
                            || r.departamento)
               || '</span>'
             end
          || '</div></div>');
        -- Não oferece "Conversar" com a própria pessoa
        if upper(trim(r.login_apex)) <> upper(trim(p_login)) or r.login_apex is null then
          p('<a class="t-Button t-Button--icon t-Button--iconLeft" href="' || a(apex_page.get_url(p_page => 4)) || '">'
            || '<span class="t-Icon t-Icon--left fa fa-comment-o" aria-hidden="true"></span>'
            || '<span class="t-Button-label">Conversar</span></a>');
        end if;
        p('</li>');
      end loop;
      fecha_card(l_qt_p, 'pessoas');
    end if;

    if l_qt_c > 0 then
      abre_card('cx-busca-comunicados', 'fa-bullhorn', 'Comunicados', l_qt_c);
      l_n := 0;
      for r in c_comunicados(l_padrao, p_id_empresa) loop
        l_n := l_n + 1;
        exit when l_n > c_limite;
        p('<li class="cx-busca-lista__item cx-busca-comunicado">');
        p('<span class="cx-busca-comunicado__meta"><span class="cx-etiqueta">' || e(r.publico) || '</span>'
          || '<span>' || e(data_curta(r.data_publicacao)) || '</span></span>');
        p('<a class="cx-busca__link cx-busca-comunicado__titulo" href="' || a(apex_page.get_url(p_page => 11)) || '">'
          || e(r.titulo) || '</a>');
        if r.resumo is not null then
          p('<p class="cx-busca-comunicado__resumo">' || e(r.resumo) || '</p>');
        end if;
        p('</li>');
      end loop;
      fecha_card(l_qt_c, 'comunicados');
    end if;

    return g_html;
  end render_resultados;

  function render_ajuda return clob is
  begin
    inicia;
    p('<section class="cx-busca-card cx-busca-ajuda" aria-labelledby="cx-busca-ajuda">');
    p('<h2 id="cx-busca-ajuda" class="cx-busca-card__titulo">O que a busca encontra</h2>');
    p('<ul class="cx-busca-ajuda__lista">');
    p('<li><span class="fa fa-users" aria-hidden="true"></span>Pessoas ativas da sua empresa, por nome, cargo ou departamento</li>');
    p('<li><span class="fa fa-bullhorn" aria-hidden="true"></span>Comunicados da sua empresa, por t&iacute;tulo ou texto</li>');
    p('</ul>');
    p('<p class="cx-busca-ajuda__nota">Contas inativas n&atilde;o aparecem nos resultados. '
      || 'Mai&uacute;sculas e acentos n&atilde;o fazem diferen&ccedil;a.</p>');
    p('</section>');
    return g_html;
  end render_ajuda;

end pkg_busca_ui;
/
