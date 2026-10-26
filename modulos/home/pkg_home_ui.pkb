--------------------------------------------------------------------------------
-- Corlix Hub · Home (página 28) · corpo
-- Fotos: FOTO_URL guarda o nome do arquivo em "Fotos Colaboradores/" (Static
-- Application Files). O HTML sai com data-cx-foto e o JS da página completa o
-- src com apex.env.APP_FILES. Se a imagem falhar, o onerror remove a <img> e as
-- iniciais ficam visíveis (mesmo padrão do organograma).
--------------------------------------------------------------------------------
create or replace package body pkg_home_ui as

  c_nls_data    constant varchar2(60) := 'NLS_DATE_LANGUAGE=''BRAZILIAN PORTUGUESE''';
  c_pasta_fotos constant varchar2(30) := 'Fotos Colaboradores/';

  g_html clob;

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

  -- Data de hoje no fuso do Brasil (o banco roda em UTC)
  function hoje return date is
  begin
    return cast(systimestamp at time zone 'America/Sao_Paulo' as date);
  end hoje;

  function mes_por_extenso (p_data in date) return varchar2 is
  begin
    return to_char(p_data, 'fmmonth', c_nls_data);
  end mes_por_extenso;

  -- "Sexta-feira, 25 de setembro de 2026"
  function data_por_extenso (p_data in date) return varchar2 is
    l_dia_semana varchar2(30) := to_char(p_data, 'fmday', c_nls_data);
  begin
    return upper(substr(l_dia_semana, 1, 1)) || substr(l_dia_semana, 2) || ', '
        || to_char(p_data, 'fmdd') || ' de ' || mes_por_extenso(p_data)
        || ' de ' || to_char(p_data, 'yyyy');
  end data_por_extenso;

  function iniciais (p_nome in varchar2) return varchar2 is
    l_nome varchar2(400) := trim(regexp_replace(p_nome, '\s+', ' '));
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

  -- Nome + linha de detalhe, com avatar
  function pessoa (p_nome in varchar2, p_foto_url in varchar2, p_detalhe in varchar2) return varchar2 is
  begin
    return '<div class="cx-pessoa">' || avatar(p_nome, p_foto_url)
        || '<div><strong class="cx-pessoa__nome">' || e(p_nome) || '</strong>'
        || case when p_detalhe is not null then
             '<span class="cx-pessoa__detalhe">' || e(p_detalhe) || '</span>'
           end
        || '</div></div>';
  end pessoa;

  -- Estado vazio: ícone em círculo + título + orientação (textos já em HTML)
  function estado_vazio (p_icone in varchar2, p_titulo in varchar2, p_texto in varchar2) return varchar2 is
  begin
    return '<div class="cx-home-vazio">'
        || '<span class="cx-avatar cx-avatar--vazio" aria-hidden="true"><span class="fa ' || p_icone || '"></span></span>'
        || '<div><strong class="cx-home-vazio__titulo">' || p_titulo || '</strong>'
        || '<p class="cx-home-vazio__texto">' || p_texto || '</p></div></div>';
  end estado_vazio;

  -- Link rápido do hero. Sem destino configurado ainda: o JS da página avisa no clique.
  function atalho (p_icone in varchar2, p_texto in varchar2) return varchar2 is
  begin
    return '<li><a class="cx-home-atalho" href="#" aria-disabled="true" title="Dispon&iacute;vel em breve">'
        || '<span class="cx-home-atalho__icone" aria-hidden="true"><span class="fa ' || p_icone || '"></span></span>'
        || '<span class="cx-home-atalho__texto">' || p_texto || '</span>'
        || '<span class="cx-home-atalho__seta fa fa-chevron-right" aria-hidden="true"></span>'
        || '</a></li>';
  end atalho;

  ------------------------------------------------------------------------------
  -- Públicas
  ------------------------------------------------------------------------------
  function mes_atual return varchar2 is
  begin
    return mes_por_extenso(hoje);
  end mes_atual;

  function render_hero (
    p_login in varchar2 default v('APP_USER')
  ) return clob is
    l_nome varchar2(200);
  begin
    begin
      select coalesce(trim(primeiro_nome), regexp_substr(trim(nome_completo), '^\S+'))
        into l_nome
        from colaborador
       where upper(trim(login_apex)) = upper(trim(p_login))
       fetch first 1 rows only;
    exception
      when no_data_found then
        l_nome := null;
    end;

    -- Contas sem colaborador (equipe do Corlix Hub): nome da conta APEX
    l_nome := initcap(coalesce(l_nome, regexp_substr(trim(v('G_NOME_USUARIO')), '^\S+'), p_login));

    inicia;
    p('<section class="cx-home-hero" aria-labelledby="cx-home-saudacao">');
    p('<div class="cx-home-hero__conteudo">');
    p('<h1 id="cx-home-saudacao" class="cx-home-hero__titulo">Ol&aacute;, ' || e(l_nome) || '</h1>');
    p('<p class="cx-home-hero__data">' || e(data_por_extenso(hoje)) || '</p>');
    p('<ul class="cx-home-atalhos" aria-label="Links r&aacute;pidos">');
    p(atalho('fa-file-text-o', 'Holerite digital'));
    p(atalho('fa-clock-o', 'Ponto eletr&ocirc;nico'));
    p(atalho('fa-headphones', 'Suporte TI'));
    p('</ul></div>');
    p('<div class="cx-home-hero__arte" aria-hidden="true"></div>');
    p('</section>');
    return g_html;
  end render_hero;

  function render_meu_gestor (
    p_login      in varchar2 default v('APP_USER'),
    p_id_empresa in number   default to_number(v('G_ID_EMPRESA') default null on conversion error)
  ) return clob is
    l_qt_colaborador pls_integer;
  begin
    inicia;

    for g in (
      select g.nome_completo,
             g.email,
             g.foto_url,
             cg.nome as cargo,
             d.nome  as departamento
        from colaborador c
        join colaborador g
          on g.id_colaborador = c.id_gestor
         and g.id_empresa     = c.id_empresa
        left join cargo cg
          on cg.id_cargo = g.id_cargo
        left join departamento d
          on d.id_departamento = g.id_departamento
       where upper(trim(c.login_apex)) = upper(trim(p_login))
         and c.id_empresa = p_id_empresa
       fetch first 1 rows only
    ) loop
      p('<div class="cx-home-gestor">');
      p(pessoa(g.nome_completo, g.foto_url,
               g.cargo || case when g.cargo is not null and g.departamento is not null then ' · ' end
                       || g.departamento));
      p('<div class="cx-acoes-card">');
      p('<a class="t-Button t-Button--icon t-Button--iconLeft" href="' || a(apex_page.get_url(p_page => 4)) || '">'
        || '<span class="t-Icon t-Icon--left fa fa-comments-o" aria-hidden="true"></span>'
        || '<span class="t-Button-label">Chat</span></a>');
      if g.email is not null then
        p('<a class="t-Button t-Button--icon t-Button--iconLeft" href="mailto:' || a(g.email) || '">'
          || '<span class="t-Icon t-Icon--left fa fa-envelope-o" aria-hidden="true"></span>'
          || '<span class="t-Button-label">E-mail</span></a>');
      end if;
      p('</div></div>');
      return g_html;
    end loop;

    -- Sem gestor: diferencia "sem vínculo com a empresa" de "vinculado, sem gestor"
    select count(*)
      into l_qt_colaborador
      from colaborador
     where upper(trim(login_apex)) = upper(trim(p_login))
       and id_empresa = p_id_empresa;

    if l_qt_colaborador = 0 then
      p(estado_vazio('fa-user-times', 'Nenhum gestor vinculado',
        'Seu perfil ainda n&atilde;o est&aacute; vinculado a uma empresa. Procure o RH ou a administra&ccedil;&atilde;o do CorlixHub para concluir o cadastro.'));
    else
      p(estado_vazio('fa-user-times', 'Nenhum gestor vinculado',
        'Seu cadastro ainda n&atilde;o tem um gestor definido. Se isso estiver errado, procure o RH.'));
    end if;
    return g_html;
  end render_meu_gestor;

  function render_aniversariantes (
    p_id_empresa in number      default to_number(v('G_ID_EMPRESA') default null on conversion error),
    p_limite     in pls_integer default 3,
    p_ver_todos  in varchar2    default 'S'
  ) return clob is
    l_hoje   constant date := hoje;
    l_limite constant pls_integer := coalesce(p_limite, 1000);
    l_qt     pls_integer := 0;
  begin
    inicia;

    -- Próximos aniversários primeiro; os que já passaram no mês vão para o fim
    for r in (
      select nome_completo,
             foto_url,
             data_de_nascimento,
             to_number(to_char(data_de_nascimento, 'dd')) as dia
        from colaborador
       where id_empresa = p_id_empresa
         and status = true
         and to_char(data_de_nascimento, 'mm') = to_char(l_hoje, 'mm')
       order by case when to_number(to_char(data_de_nascimento, 'dd')) >= to_number(to_char(l_hoje, 'dd'))
                     then 0 else 1 end,
                dia,
                nome_completo
       fetch first l_limite rows only
    ) loop
      l_qt := l_qt + 1;
      if l_qt = 1 then
        p('<ul class="cx-home-lista">');
      end if;
      p('<li class="cx-home-lista__item">'
        || pessoa(r.nome_completo, r.foto_url,
                  r.dia || ' de ' || mes_por_extenso(r.data_de_nascimento))
        || case when r.dia = to_number(to_char(l_hoje, 'dd')) then
             '<span class="cx-badge cx-badge--info">Hoje</span>'
           end
        || '</li>');
    end loop;

    if l_qt = 0 then
      p(estado_vazio('fa-birthday-cake',
        'Nenhum aniversariante em ' || e(mes_por_extenso(l_hoje)),
        case when p_id_empresa is null then
          'Os aniversariantes aparecem aqui quando seu perfil estiver vinculado a uma empresa.'
        else
          'Quando algu&eacute;m da empresa fizer anivers&aacute;rio neste m&ecirc;s, o nome aparece aqui.'
        end));
      return g_html;
    end if;

    p('</ul>');
    if p_ver_todos = 'S' then
      p('<div class="cx-home-card__rodape">'
        || '<button type="button" class="t-Button t-Button--noUI t-Button--iconRight" data-cx-acao="aniversariantes">'
        || '<span class="t-Button-label">Ver todos</span>'
        || '<span class="t-Icon t-Icon--right fa fa-arrow-right" aria-hidden="true"></span>'
        || '</button></div>');
    end if;
    return g_html;
  end render_aniversariantes;

end pkg_home_ui;
/
