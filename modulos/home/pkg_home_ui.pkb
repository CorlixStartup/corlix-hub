--------------------------------------------------------------------------------
-- Corlix Hub · Home (página 1, "Início") · corpo
-- Fotos: FOTO_URL guarda o nome do arquivo em "Fotos Colaboradores/" (Static
-- Application Files). O HTML sai com data-cx-foto e o JS da página completa o
-- src com apex.env.APP_FILES. Se a imagem falhar, o onerror remove a <img> e as
-- iniciais ficam visíveis (mesmo padrão do organograma).
-- Ponto (guia §7): dados e regras vêm do pkg_ponto; aqui só a apresentação, no
-- mesmo formato do pkg_ponto_ui (página 30). Os ícones dos blocos do ponto são SVG
-- Lucide em linha (icone()), como no pkg_ponto_ui; os blocos anteriores seguem
-- com as classes fa-* que já usavam.
--------------------------------------------------------------------------------
create or replace package body pkg_home_ui as

  c_nls_data    constant varchar2(60) := 'NLS_DATE_LANGUAGE=''BRAZILIAN PORTUGUESE''';
  c_pasta_fotos constant varchar2(30) := 'Fotos Colaboradores/';

  -- Ponto (guia §7): mesmas janelas do pkg_ponto_ui
  c_dias_pendencia    constant pls_integer := 30;  -- busca de marcações ausentes e faltas
  c_max_pendencias    constant pls_integer := 5;
  c_dias_alerta_banco constant pls_integer := 60;  -- aviso de horas a vencer

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

  -- Hora atual no fuso do Brasil, para a saudação
  function hora_atual return pls_integer is
  begin
    return to_number(to_char(systimestamp at time zone 'America/Sao_Paulo', 'hh24'));
  end hora_atual;

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

  -- Nome + linha de detalhe, com avatar. p_classe_detalhe destaca a linha (ex.: "hoje").
  function pessoa (p_nome in varchar2, p_foto_url in varchar2, p_detalhe in varchar2,
                   p_classe_detalhe in varchar2 default null) return varchar2 is
  begin
    return '<div class="cx-pessoa">' || avatar(p_nome, p_foto_url)
        || '<div><strong class="cx-pessoa__nome">' || e(p_nome) || '</strong>'
        || case when p_detalhe is not null then
             '<span class="cx-pessoa__detalhe'
             || case when p_classe_detalhe is not null then ' ' || p_classe_detalhe end
             || '">' || e(p_detalhe) || '</span>'
           end
        || '</div></div>';
  end pessoa;

  -- Rodapé "Ver todos" dos cards da coluna lateral (o JS abre o diálogo)
  function rodape_ver_todos (p_acao in varchar2) return varchar2 is
  begin
    return '<div class="cx-home-card__rodape">'
        || '<button type="button" class="t-Button t-Button--noUI t-Button--iconRight" data-cx-acao="' || a(p_acao) || '">'
        || '<span class="t-Button-label">Ver todos</span>'
        || '<span class="t-Icon t-Icon--right fa fa-arrow-right" aria-hidden="true"></span>'
        || '</button></div>';
  end rodape_ver_todos;

  -- Estado vazio: ícone em círculo + título + orientação (textos já em HTML)
  function estado_vazio (p_icone in varchar2, p_titulo in varchar2, p_texto in varchar2) return varchar2 is
  begin
    return '<div class="cx-home-vazio">'
        || '<span class="cx-avatar cx-avatar--vazio" aria-hidden="true"><span class="fa ' || p_icone || '"></span></span>'
        || '<div><strong class="cx-home-vazio__titulo">' || p_titulo || '</strong>'
        || '<p class="cx-home-vazio__texto">' || p_texto || '</p></div></div>';
  end estado_vazio;

  -- Link rápido do hero. Sem página (p_pagina nula): o JS da página avisa no clique.
  function atalho (p_icone in varchar2, p_texto in varchar2, p_pagina in number default null) return varchar2 is
  begin
    return '<li><a class="cx-home-atalho" '
        || case when p_pagina is not null then
             'href="' || a(apex_page.get_url(p_page => p_pagina)) || '"'
           else
             'href="#" aria-disabled="true" title="Dispon&iacute;vel em breve"'
           end
        || '>'
        || '<span class="cx-home-atalho__icone" aria-hidden="true"><span class="fa ' || p_icone || '"></span></span>'
        || '<span class="cx-home-atalho__texto">' || p_texto || '</span>'
        || '<span class="cx-home-atalho__seta fa fa-chevron-right" aria-hidden="true"></span>'
        || '</a></li>';
  end atalho;

  ------------------------------------------------------------------------------
  -- Ponto eletrônico (guia §7)
  ------------------------------------------------------------------------------
  function icone (p_nome in varchar2) return varchar2 is
    l_svg varchar2(1000);
  begin
    l_svg := case p_nome
      when 'clock'     then '<circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/>'
      when 'log-in'    then '<path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4"/><polyline points="10 17 15 12 10 7"/><line x1="15" x2="3" y1="12" y2="12"/>'
      when 'log-out'   then '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" x2="9" y1="12" y2="12"/>'
      when 'coffee'    then '<path d="M17 8h1a4 4 0 0 1 0 8h-1"/><path d="M3 8h14v9a4 4 0 0 1-4 4H7a4 4 0 0 1-4-4Z"/><line x1="6" x2="6" y1="2" y2="4"/><line x1="10" x2="10" y1="2" y2="4"/><line x1="14" x2="14" y1="2" y2="4"/>'
      when 'check'     then '<path d="M20 6 9 17l-5-5"/>'
      when 'hourglass' then '<path d="M5 22h14"/><path d="M5 2h14"/><path d="M17 22v-4.172a2 2 0 0 0-.586-1.414L12 12l-4.414 4.414A2 2 0 0 0 7 17.828V22"/><path d="M7 2v4.172a2 2 0 0 0 .586 1.414L12 12l4.414-4.414A2 2 0 0 0 17 6.172V2"/>'
      when 'calendar-x' then '<rect width="18" height="18" x="3" y="4" rx="2"/><path d="M16 2v4"/><path d="M8 2v4"/><path d="M3 10h18"/><path d="m14 14-4 4"/><path d="m10 14 4 4"/>'
      when 'assinar'   then '<path d="M12 3H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.4 2.6a2.1 2.1 0 0 1 3 3L12 15l-4 1 1-4Z"/>'
      when 'users'     then '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>'
    end;
    return '<svg class="cx-home-icone" width="18" height="18" viewBox="0 0 24 24" aria-hidden="true" focusable="false">'
        || l_svg || '</svg>';
  end icone;

  -- Colaborador informado ou o da conta logada; nulo se a conta não tem vínculo
  -- (equipe do Corlix Hub, RH sem cadastro de colaborador)
  function colaborador_ponto (p_id in number) return number is
  begin
    if p_id is not null then
      return p_id;
    end if;
    return pkg_ponto.fn_colaborador_logado;
  exception
    when others then
      if sqlcode = -20060 then
        return null;
      end if;
      raise;
  end colaborador_ponto;

  -- Agora no fuso da empresa do colaborador (o mesmo que o ponto usa)
  function agora_ponto (p_id_colaborador in number) return date is
    l_empresa number;
  begin
    select id_empresa into l_empresa from colaborador where id_colaborador = p_id_colaborador;
    return pkg_historico_carreira.fn_data_local(l_empresa, systimestamp);
  end agora_ponto;

  function hora (p_dh in date) return varchar2 is
  begin
    return to_char(p_dh, 'HH24:MI');
  end hora;

  -- Hora prevista de saída. Mesma conta do saida_prevista do pkg_ponto_ui, que é
  -- privado; se a regra mudar lá, mude aqui também.
  function saida_prevista (p_dia in pkg_ponto.t_dia, p_j in pkg_ponto.t_jornada, p_hoje in date) return date is
    l_manha number;
  begin
    if p_dia.dh_entrada is null then
      return p_hoje + p_j.nr_min_saida / 1440;
    elsif p_dia.dh_intervalo is null then
      return p_dia.dh_entrada + (p_j.nr_min_diarios + p_j.nr_min_intervalo) / 1440;
    end if;
    l_manha := round((p_dia.dh_intervalo - p_dia.dh_entrada) * 1440);
    if p_dia.dh_retorno is null then
      return p_dia.dh_intervalo + (p_j.nr_min_intervalo + p_j.nr_min_diarios - l_manha) / 1440;
    end if;
    return p_dia.dh_retorno + (p_j.nr_min_diarios - l_manha) / 1440;
  end saida_prevista;

  function selo (p_texto in varchar2, p_tipo in varchar2) return varchar2 is
  begin
    return '<span class="cx-home-selo cx-home-selo--' || p_tipo || '">' || e(p_texto) || '</span>';
  end selo;

  -- Painel "Ponto de hoje", à direita do hero. Nulo quando a conta não tem
  -- colaborador ou a empresa não tem jornada cadastrada.
  function painel_ponto (p_id_colaborador in number) return varchar2 is
    l_id       constant number := colaborador_ponto(p_id_colaborador);
    l_j        pkg_ponto.t_jornada;
    l_agora    date;
    l_hoje     date;
    l_dias     pkg_ponto.t_dias;
    l_dia      pkg_ponto.t_dia;
    l_proxima  varchar2(10);
    l_prevista date;
    l_trab     number;
    l_correndo varchar2(1);
    l_tipos    apex_t_varchar2;
    l_valor    date;
    l_classe   varchar2(20);
    l_rotulo   varchar2(60);
    l_icone    varchar2(20);
    l_resumo   varchar2(200);
    l_html     varchar2(32767);
  begin
    if l_id is null then
      return null;
    end if;

    l_j       := pkg_ponto.fn_jornada(l_id);
    l_agora   := agora_ponto(l_id);
    l_hoje    := trunc(l_agora);
    l_dias    := pkg_ponto.fn_dias(l_id, l_hoje, l_hoje);
    if l_dias.count > 0 then
      l_dia := l_dias(1);
    end if;
    l_proxima  := pkg_ponto.fn_proxima_marcacao(l_id);
    l_prevista := saida_prevista(l_dia, l_j, l_hoje);
    l_trab     := nvl(l_dia.nr_trabalhados, 0);
    l_correndo := case when l_dia.dh_entrada is not null and l_dia.dh_saida is null
                        and (l_dia.dh_intervalo is null or l_dia.dh_retorno is not null)
                       then 'S' else 'N' end;

    -- "4h33 trabalhadas · faltam 3h27" (o JS da página mantém atualizado)
    l_resumo := case
      when l_dia.dh_entrada is null then
        'Entrada prevista às ' || hora(l_hoje + l_j.nr_min_entrada / 1440)
      else
        pkg_ponto.fn_horas(l_trab) || ' trabalhadas · '
        || case when l_trab >= l_j.nr_min_diarios then 'jornada completa'
                when l_proxima is null then 'jornada encerrada'
                else 'faltam ' || pkg_ponto.fn_horas(l_j.nr_min_diarios - l_trab) end
    end;

    l_html := '<aside class="cx-home-ponto" aria-labelledby="cx-home-ponto-titulo" data-cx-home-ponto'
      || ' data-segundos="' || to_char((l_agora - l_hoje) * 86400, 'fm99990') || '"'
      || ' data-trabalhados="' || l_trab || '"'
      || ' data-meta="' || l_j.nr_min_diarios || '"'
      || ' data-correndo="' || l_correndo || '">';

    l_html := l_html || '<header class="cx-home-ponto__cabecalho">'
      || '<h2 id="cx-home-ponto-titulo" class="cx-home-ponto__titulo"><a href="'
      || a(apex_page.get_url(p_page => 30)) || '">' || icone('clock') || '<span>Ponto de hoje</span></a></h2>'
      || case
           when l_proxima is null              then selo('Jornada concluída', 'neutro')
           when l_proxima = 'RETORNO'          then selo('Em intervalo', 'atencao')
           when l_dia.dh_entrada is not null   then selo('Em jornada', 'sucesso')
           when l_dia.cd_situacao = pkg_ponto.c_feriado then selo(l_dia.nm_feriado, 'neutro')
           else selo('Não iniciada', 'neutro')
         end
      || '</header>';

    l_html := l_html || '<div class="cx-home-ponto__agora"><div>'
      || '<p class="cx-home-ponto__hora" data-cx-home-ponto-hora>' || hora(l_agora) || '</p>'
      || '<p class="cx-home-ponto__resumo" data-cx-home-ponto-resumo>' || e(l_resumo) || '</p></div>';
    if l_proxima is not null then
      case l_proxima
        when 'ENTRADA'   then l_rotulo := 'Registrar entrada';   l_icone := 'log-in';
        when 'INTERVALO' then l_rotulo := 'Iniciar intervalo';   l_icone := 'coffee';
        when 'RETORNO'   then l_rotulo := 'Voltar do intervalo'; l_icone := 'log-in';
        else                  l_rotulo := 'Registrar saída';     l_icone := 'log-out';
      end case;
      l_html := l_html || '<button type="button" class="t-Button t-Button--hot cx-home-ponto__registrar"'
        || ' data-cx-home-registrar="' || l_proxima || '">' || icone(l_icone)
        || '<span class="t-Button-label">' || l_rotulo || '</span></button>';
    end if;
    l_html := l_html || '</div>';

    -- Linha do dia: Entrada → Intervalo → Retorno → Saída (sem intervalo, só 2)
    l_tipos := case when l_j.nr_min_intervalo = 0
                    then apex_t_varchar2('ENTRADA', 'SAIDA')
                    else apex_t_varchar2('ENTRADA', 'INTERVALO', 'RETORNO', 'SAIDA') end;
    l_html := l_html || '<ol class="cx-home-ponto__linha" aria-label="Marcações de hoje">';
    for i in 1 .. l_tipos.count loop
      l_valor := case l_tipos(i)
        when 'ENTRADA'   then l_dia.dh_entrada
        when 'INTERVALO' then l_dia.dh_intervalo
        when 'RETORNO'   then l_dia.dh_retorno
        else l_dia.dh_saida
      end;
      l_classe := case when l_valor is not null then 'is-feita'
                       when l_tipos(i) = l_proxima then 'is-atual' end;
      l_html := l_html || '<li class="cx-home-ponto__passo ' || l_classe || '">'
        || '<span class="cx-home-ponto__marca">' || case when l_valor is not null then icone('check') end || '</span>'
        || '<span class="cx-home-ponto__rotulo">'
        || case l_tipos(i)
             when 'ENTRADA'   then 'Entrada'
             when 'INTERVALO' then 'Intervalo'
             when 'RETORNO'   then 'Retorno'
             else case when l_valor is null then 'Saída prev.' else 'Saída' end
           end || '</span>'
        || case
             when l_valor is not null   then '<strong class="cx-home-ponto__horario">' || hora(l_valor) || '</strong>'
             when l_tipos(i) = 'SAIDA'  then '<strong class="cx-home-ponto__horario is-prevista">' || hora(l_prevista) || '</strong>'
             else '<strong class="cx-home-ponto__horario is-prevista">—</strong>'
           end
        || '</li>';
    end loop;
    l_html := l_html || '</ol></aside>';
    return l_html;
  exception
    when others then
      -- -20061: empresa sem jornada cadastrada. O hero aparece sem o painel.
      if sqlcode = -20061 then
        return null;
      end if;
      raise;
  end painel_ponto;

  procedure pendencia (
    p_icone   in varchar2,
    p_titulo  in varchar2,
    p_detalhe in varchar2,
    p_selo    in varchar2,
    p_tipo    in varchar2,
    p_acao    in varchar2,
    p_url     in varchar2
  ) is
  begin
    p('<li class="cx-home-pendencia">'
      || '<span class="cx-home-pendencia__icone">' || icone(p_icone) || '</span>'
      || '<div class="cx-home-pendencia__texto"><strong>' || e(p_titulo) || '</strong>'
      || '<span>' || e(p_detalhe) || '</span></div>'
      || selo(p_selo, p_tipo)
      || '<a class="t-Button cx-home-pendencia__acao" href="' || a(p_url) || '">'
      || '<span class="t-Button-label">' || e(p_acao) || '</span></a>'
      || '</li>');
  end pendencia;

  ------------------------------------------------------------------------------
  -- Públicas
  ------------------------------------------------------------------------------
  function mes_atual return varchar2 is
  begin
    return mes_por_extenso(hoje);
  end mes_atual;

  function render_hero (
    p_login          in varchar2 default v('APP_USER'),
    p_id_colaborador in number   default null
  ) return clob is
    l_nome     varchar2(200);
    l_ponto    varchar2(32767);
    l_hora     constant pls_integer := hora_atual;
    l_saudacao constant varchar2(20) := case when l_hora < 12 then 'Bom dia'
                                             when l_hora < 18 then 'Boa tarde'
                                             else 'Boa noite' end;
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

    l_ponto := painel_ponto(p_id_colaborador);

    inicia;
    p('<section class="cx-home-hero' || case when l_ponto is not null then ' cx-home-hero--ponto' end
      || '" aria-labelledby="cx-home-saudacao">');
    p('<div class="cx-home-hero__conteudo">');
    p('<h1 id="cx-home-saudacao" class="cx-home-hero__titulo">' || l_saudacao || ', ' || e(l_nome) || '</h1>');
    p('<p class="cx-home-hero__data">' || e(data_por_extenso(hoje)) || '</p>');
    p('<ul class="cx-home-atalhos" aria-label="Links r&aacute;pidos">');
    -- Página de destino de cada link; nula enquanto a página não existir
    p(atalho('fa-file-text-o', 'Holerite',    p_pagina => 9));
    p(atalho('fa-sitemap',     'Organograma', p_pagina => 3));
    p(atalho('fa-headphones',  'Suporte TI',  p_pagina => 34));
    p(atalho('fa-comments-o',  'Chat',        p_pagina => 4));
    p('</ul></div>');
    -- "Ponto de hoje" à direita; sem colaborador, o hero ocupa a largura toda
    p(l_ponto);
    p('</section>');
    return g_html;
  end render_hero;

  function render_indicadores (
    p_id_colaborador in number default null
  ) return clob is
    l_id       constant number := colaborador_ponto(p_id_colaborador);
    l_hoje     date;
    l_saldo    number;
    l_vencendo number;
    l_dt_venc  date;
    l_extrato  pkg_ponto.t_dias;
    l_detalhe  varchar2(200);
  begin
    inicia;
    if l_id is null then
      return g_html;
    end if;

    begin
      pkg_ponto.calcular_banco(l_id, l_saldo, l_vencendo, l_dt_venc, l_extrato);
    exception
      when others then
        if sqlcode = -20061 then  -- empresa sem jornada
          return g_html;
        end if;
        raise;
    end;
    l_hoje := trunc(agora_ponto(l_id));

    -- O dia de hoje só entra no banco quando fecha: o saldo é "até ontem"
    l_detalhe := case when l_dt_venc is not null and l_vencendo > 0
                       and l_dt_venc - l_hoje <= c_dias_alerta_banco
                      then pkg_ponto.fn_horas(l_vencendo) || ' vencem em ' || to_char(l_dt_venc, 'DD/MM/YYYY')
                      else 'Saldo até ontem' end;

    p('<ul class="cx-home-indicadores" aria-label="Indicadores">');
    p('<li class="cx-home-indicador">'
      || '<span class="cx-home-indicador__icone">' || icone('hourglass') || '</span>'
      || '<div><p class="cx-home-indicador__rotulo">Banco de horas</p>'
      || '<p class="cx-home-indicador__valor'
      || case when l_saldo > 0 then ' is-positivo' when l_saldo < 0 then ' is-negativo' end || '">'
      || pkg_ponto.fn_saldo(l_saldo) || '</p>'
      || '<p class="cx-home-indicador__detalhe">' || e(l_detalhe) || ' · <a href="'
      || a(apex_page.get_url(p_page => 30)) || '">ver espelho</a></p></div>'
      || '</li>');
    p('</ul>');
    return g_html;
  end render_indicadores;

  function render_pendencias (
    p_id_colaborador in number default null
  ) return clob is
    l_id       constant number := colaborador_ponto(p_id_colaborador);
    l_hoje     date;
    l_dias     pkg_ponto.t_dias;
    l_mes      date;
    l_prazo    date;
    l_faltante varchar2(10);
    l_qt_ponto pls_integer := 0;
    l_qt       pls_integer := 0;
    l_qt_aprov pls_integer := 0;
  begin
    inicia;

    if l_id is not null then
      begin
        l_hoje := trunc(agora_ponto(l_id));
        l_dias := pkg_ponto.fn_dias(l_id, l_hoje - c_dias_pendencia, l_hoje - 1);
        l_mes  := pkg_ponto.fn_competencia_a_assinar(l_id);
      exception
        when others then
          if sqlcode = -20061 then  -- empresa sem jornada: nada do ponto
            l_dias.delete;
            l_mes := null;
          else
            raise;
          end if;
      end;
    end if;

    -- Pedidos de ajuste que a conta pode responder (gestor direto ou RH)
    if pkg_ponto.fn_e_aprovador = 'S' then
      select count(*)
        into l_qt_aprov
        from ponto_ajuste a
       where a.id_empresa = pkg_historico_carreira.fn_empresa_contexto
         and a.st_ajuste  = 'PENDENTE'
         and pkg_ponto.fn_pode_aprovar(a.id_ajuste) = 'S';
    end if;

    -- Dias com marcação faltando ou sem marcação, do mais recente para trás
    for i in reverse 1 .. l_dias.count loop
      exit when l_qt_ponto >= c_max_pendencias;
      if l_dias(i).cd_situacao in (pkg_ponto.c_ausente, pkg_ponto.c_falta) then
        l_qt_ponto := l_qt_ponto + 1;
        l_qt := l_qt + 1;
        if l_qt = 1 then
          p('<ul class="cx-home-pendencias">');
        end if;
        if l_dias(i).cd_situacao = pkg_ponto.c_falta then
          pendencia('calendar-x',
            'Dia sem marcação em ' || to_char(l_dias(i).dt, 'DD/MM'),
            'Ponto eletrônico · nenhuma marcação no dia',
            'Pendente', 'erro', 'Justificar',
            apex_page.get_url(p_page => 31, p_clear_cache => '31',
              p_items  => 'P31_DT_REFERENCIA,P31_TP_AJUSTE',
              p_values => to_char(l_dias(i).dt, 'DD/MM/YYYY') || ',ABONO'));
        else
          l_faltante := case when l_dias(i).dh_entrada is null   then 'ENTRADA'
                             when l_dias(i).dh_intervalo is null then 'INTERVALO'
                             when l_dias(i).dh_retorno is null   then 'RETORNO'
                             else 'SAIDA' end;
          pendencia('clock',
            'Marcação incompleta em ' || to_char(l_dias(i).dt, 'DD/MM'),
            'Ponto eletrônico · falta registrar '
              || case l_faltante
                   when 'ENTRADA'   then 'a entrada'
                   when 'INTERVALO' then 'a saída para o intervalo'
                   when 'RETORNO'   then 'o retorno do intervalo'
                   else 'a saída do dia' end,
            'Pendente', 'erro', 'Justificar',
            apex_page.get_url(p_page => 31, p_clear_cache => '31',
              p_items  => 'P31_DT_REFERENCIA,P31_TP_AJUSTE,P31_TP_MARCACAO',
              p_values => to_char(l_dias(i).dt, 'DD/MM/YYYY') || ',MARCACAO,' || l_faltante));
        end if;
      end if;
    end loop;

    -- Espelho do mês a assinar: a assinatura é feita no diálogo da página 30
    if l_mes is not null then
      l_qt := l_qt + 1;
      if l_qt = 1 then
        p('<ul class="cx-home-pendencias">');
      end if;
      l_prazo := pkg_ponto.fn_prazo_assinatura(l_mes);
      pendencia('assinar',
        'Assinar o espelho de ' || mes_por_extenso(l_mes),
        'Ponto eletrônico · prazo ' || to_char(l_prazo, 'DD/MM/YYYY'),
        case when l_prazo - l_hoje <= 0 then 'Vence hoje'
             when l_prazo - l_hoje = 1  then 'Vence amanhã'
             else 'Vence em ' || (l_prazo - l_hoje) || ' dias' end,
        'atencao', 'Assinar',
        apex_page.get_url(p_page => 30));
    end if;

    if l_qt_aprov > 0 then
      l_qt := l_qt + 1;
      if l_qt = 1 then
        p('<ul class="cx-home-pendencias">');
      end if;
      pendencia('users',
        case when l_qt_aprov = 1 then '1 pedido de ajuste de ponto'
             else l_qt_aprov || ' pedidos de ajuste de ponto' end,
        'Ponto eletrônico · ' || case when l_qt_aprov = 1 then 'aguarda' else 'aguardam' end || ' sua resposta',
        'Para responder', 'info', 'Responder',
        apex_page.get_url(p_page => 32));
    end if;

    if l_qt = 0 then
      p(estado_vazio('fa-check-circle', 'Nenhuma pend&ecirc;ncia',
        'Quando algo precisar de uma a&ccedil;&atilde;o sua, aparece aqui.'));
    else
      p('</ul>');
    end if;
    return g_html;
  end render_pendencias;

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
      p('<div class="cx-acoes-card cx-home-gestor__acoes">');
      p('<a class="t-Button t-Button--icon t-Button--iconLeft" href="' || a(apex_page.get_url(p_page => 4)) || '">'
        || '<span class="t-Icon t-Icon--left fa fa-comments-o" aria-hidden="true"></span>'
        || '<span class="t-Button-label">Mensagem</span></a>');
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
      p(rodape_ver_todos('aniversariantes'));
    end if;
    return g_html;
  end render_aniversariantes;

  function render_celebracoes (
    p_id_empresa in number      default to_number(v('G_ID_EMPRESA') default null on conversion error),
    p_limite     in pls_integer default 4,
    p_ver_todos  in varchar2    default 'S'
  ) return clob is
    l_hoje    constant date := hoje;
    l_dia_hoj constant pls_integer := to_number(to_char(l_hoje, 'dd'));
    l_limite  constant pls_integer := coalesce(p_limite, 1000);
    l_qt      pls_integer := 0;
    l_detalhe varchar2(200);
  begin
    inicia;

    -- Aniversário (nascimento) e tempo de empresa (admissão há 1 ano ou mais)
    -- no mês atual. Próximos primeiro; os que já passaram no mês vão para o fim.
    for r in (
      with celebracao as (
        select nome_completo, foto_url, 'ANIVERSARIO' as tipo,
               to_number(to_char(data_de_nascimento, 'dd')) as dia,
               cast(null as number) as anos
          from colaborador
         where id_empresa = p_id_empresa
           and status = true
           and to_char(data_de_nascimento, 'mm') = to_char(l_hoje, 'mm')
        union all
        select nome_completo, foto_url, 'EMPRESA',
               to_number(to_char(data_admissao, 'dd')),
               extract(year from l_hoje) - extract(year from data_admissao)
          from colaborador
         where id_empresa = p_id_empresa
           and status = true
           and to_char(data_admissao, 'mm') = to_char(l_hoje, 'mm')
           and extract(year from data_admissao) < extract(year from l_hoje)
      )
      select nome_completo, foto_url, tipo, dia, anos
        from celebracao
       order by case when dia >= l_dia_hoj then 0 else 1 end,
                dia,
                case tipo when 'ANIVERSARIO' then 0 else 1 end,
                nome_completo
       fetch first l_limite rows only
    ) loop
      l_qt := l_qt + 1;
      if l_qt = 1 then
        p('<ul class="cx-home-lista">');
      end if;

      -- "Aniversário · hoje", "Aniversário · 28 de outubro", "2 anos de empresa · 27 de outubro"
      l_detalhe := case r.tipo
                     when 'ANIVERSARIO' then 'Aniversário'
                     else r.anos || case when r.anos = 1 then ' ano' else ' anos' end || ' de empresa'
                   end
                || ' · '
                || case when r.dia = l_dia_hoj then 'hoje'
                        else r.dia || ' de ' || mes_por_extenso(l_hoje) end;

      p('<li class="cx-home-lista__item">'
        || pessoa(r.nome_completo, r.foto_url, l_detalhe,
                  case when r.dia = l_dia_hoj then 'cx-home-celebracao--hoje' end)
        || '</li>');
    end loop;

    if l_qt = 0 then
      p(estado_vazio('fa-birthday-cake',
        'Nenhuma celebração em ' || e(mes_por_extenso(l_hoje)),
        case when p_id_empresa is null then
          'As celebra&ccedil;&otilde;es aparecem aqui quando seu perfil estiver vinculado a uma empresa.'
        else
          'Anivers&aacute;rios e anos de empresa de quem trabalha com voc&ecirc; aparecem aqui.'
        end));
      return g_html;
    end if;

    p('</ul>');
    if p_ver_todos = 'S' then
      p(rodape_ver_todos('aniversariantes'));
    end if;
    return g_html;
  end render_celebracoes;

end pkg_home_ui;
/
