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
  g_qt_pendencias pls_integer := 0;  -- itens do último render_pendencias

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
    -- Tira marcadores entre colchetes ("[DEMO] Karen Dias" -> "Karen Dias" -> "KD") e
    -- depois tudo que não for letra ou espaço
    l_nome varchar2(400) := trim(regexp_replace(regexp_replace(regexp_replace(p_nome, '\[[^]]*\]', ' '),
                                                               '[^[:alpha:][:space:]]', ''), '\s+', ' '));
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
      when 'wallet'    then '<path d="M19 7V4a1 1 0 0 0-1-1H5a2 2 0 0 0 0 4h15a1 1 0 0 1 1 1v4h-3a2 2 0 0 0 0 4h3a1 1 0 0 0 1-1v-2a1 1 0 0 0-1-1"/><path d="M3 5v14a2 2 0 0 0 2 2h15a1 1 0 0 0 1-1v-4"/>'
      when 'palm'      then '<path d="M13 8c0-2.76-2.46-5-5.5-5S2 5.24 2 8h2l1-1 1 1h4"/><path d="M13 7.14A5.82 5.82 0 0 1 16.5 6c3.04 0 5.5 2.24 5.5 5h-3l-1-1-1 1h-3"/><path d="M5.89 9.71c-2.15 2.15-2.3 5.47-.35 7.43l4.24-4.25.7-.7.71-.71 2.12-2.12c-1.95-1.96-5.27-1.8-7.42.35"/><path d="M11 15.5c.5 2.5-.17 4.5-1 6.5h4c2-5.5-.5-12-1-14"/>'
      when 'target'    then '<circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="6"/><circle cx="12" cy="12" r="2"/>'
      when 'eye'       then '<path d="M2.06 12.35a1 1 0 0 1 0-.7 10.75 10.75 0 0 1 19.88 0 1 1 0 0 1 0 .7 10.75 10.75 0 0 1-19.88 0"/><circle cx="12" cy="12" r="3"/>'
      when 'calendar'  then '<rect width="18" height="18" x="3" y="4" rx="2"/><path d="M16 2v4"/><path d="M8 2v4"/><path d="M3 10h18"/>'
      when 'calendar-clock' then '<path d="M21 7.5V6a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h3.5"/><path d="M16 2v4"/><path d="M8 2v4"/><path d="M3 10h5"/><path d="M17.5 17.5 16 16.3V14"/><circle cx="16" cy="16" r="6"/>'
      when 'message'   then '<path d="M7.9 20A9 9 0 1 0 4 16.1L2 22Z"/>'
      when 'feedback'  then '<path d="M14 9a2 2 0 0 1-2 2H6l-4 4V4a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2z"/><path d="M18 9h2a2 2 0 0 1 2 2v11l-4-4h-6a2 2 0 0 1-2-2v-1"/>'
      when 'party'     then '<path d="M5.8 11.3 2 22l10.7-3.79"/><path d="M4 3h.01"/><path d="M22 8h.01"/><path d="M15 2h.01"/><path d="M22 20h.01"/><path d="m22 2-2.24.75a2.9 2.9 0 0 0-1.96 3.12c.1.86-.57 1.63-1.45 1.63h-.38c-.86 0-1.6.6-1.76 1.44L14 10"/><path d="m22 13-.82-.33c-.86-.34-1.82.2-1.98 1.11c-.11.7-.72 1.22-1.43 1.22H17"/><path d="m11 2 .33.82c.34.86-.2 1.82-1.11 1.98C9.52 4.9 9 5.52 9 6.23V7"/><path d="M11 13c1.93 1.93 2.83 4.17 2 5-.83.83-3.07-.07-5-2-1.93-1.93-2.83-4.17-2-5 .83-.83 3.07.07 5 2Z"/>'
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

  -- "Quinta", "Sexta"... (sem NLS: o idioma técnico da app é "en")
  function dia_semana (p_dt in date) return varchar2 is
  begin
    -- trunc: com hora (ex.: 1:1 às 10:00) a diferença não é inteira e caía no "Domingo"
    return case trunc(p_dt) - trunc(p_dt, 'IW')
      when 0 then 'Segunda' when 1 then 'Terça' when 2 then 'Quarta' when 3 then 'Quinta'
      when 4 then 'Sexta' when 5 then 'Sábado' else 'Domingo' end;
  end dia_semana;

  -- "NOV"
  function mes_curto (p_dt in date) return varchar2 is
  begin
    return case to_number(to_char(p_dt, 'MM'))
      when 1 then 'JAN' when 2 then 'FEV' when 3 then 'MAR' when 4 then 'ABR' when 5 then 'MAI'
      when 6 then 'JUN' when 7 then 'JUL' when 8 then 'AGO' when 9 then 'SET' when 10 then 'OUT'
      when 11 then 'NOV' else 'DEZ' end;
  end mes_curto;

  -- "2.875,44"
  function moeda (p_valor in number) return varchar2 is
  begin
    return to_char(p_valor, 'FM999G999G990D00', 'NLS_NUMERIC_CHARACTERS='',.''');
  end moeda;

  -- Resposta dos Ajax Callbacks: {"ok":true|false,"mensagem":"..."}
  procedure responder (p_ok in boolean, p_mensagem in varchar2) is
  begin
    apex_json.open_object;
    apex_json.write('ok', p_ok);
    apex_json.write('mensagem', p_mensagem);
    apex_json.close_object;
  end responder;

  -- Erro de regra (-20000 a -20999) sai com a mensagem; o resto, genérico
  procedure responder_erro (p_codigo in number, p_mensagem in varchar2) is
  begin
    if p_codigo between -20999 and -20000 then
      responder(false, regexp_replace(p_mensagem, '^ORA-\d+: '));
    else
      apex_debug.error('pkg_home_ui: %s', p_mensagem);
      responder(false, 'Não foi possível concluir agora. Tente de novo em instantes.');
    end if;
  end responder_erro;

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
    l_ultimo   date;
    l_qt_obj   pls_integer;
    l_qt_ok    pls_integer;
    l_dias     number;
    l_limite   date;

    procedure indicador (p_icone in varchar2, p_rotulo in varchar2, p_valor in varchar2,
                         p_detalhe in varchar2, p_extra in varchar2 default null,
                         p_classe in varchar2 default null) is
    begin
      p('<li class="cx-home-indicador">'
        || '<span class="cx-home-indicador__icone">' || icone(p_icone) || '</span>'
        || '<div class="cx-home-indicador__texto"><p class="cx-home-indicador__rotulo">' || e(p_rotulo) || '</p>'
        || '<p class="cx-home-indicador__valor' || case when p_classe is not null then ' ' || p_classe end || '">'
        || p_valor || '</p>'
        || p_extra
        || '<p class="cx-home-indicador__detalhe">' || p_detalhe || '</p></div>'
        || '</li>');
    end indicador;
  begin
    inicia;
    if l_id is null then
      return g_html;
    end if;
    l_hoje := trunc(hoje);
    p('<ul class="cx-home-indicadores" aria-label="Indicadores">');

    -- Banco de horas (ponto). Empresa sem jornada (-20061): sem o indicador
    begin
      pkg_ponto.calcular_banco(l_id, l_saldo, l_vencendo, l_dt_venc, l_extrato);
      l_hoje := trunc(agora_ponto(l_id));
      -- O dia de hoje só entra no banco quando fecha: o saldo é "até ontem"
      l_detalhe := case when l_dt_venc is not null and l_vencendo > 0
                         and l_dt_venc - l_hoje <= c_dias_alerta_banco
                        then pkg_ponto.fn_horas(l_vencendo) || ' vencem em ' || to_char(l_dt_venc, 'DD/MM/YYYY')
                        else 'Saldo até ontem' end;
      indicador('hourglass', 'Banco de horas', pkg_ponto.fn_saldo(l_saldo),
        e(l_detalhe) || ' · <a href="' || a(apex_page.get_url(p_page => 30)) || '">ver espelho</a>',
        p_classe => case when l_saldo > 0 then 'is-positivo' when l_saldo < 0 then 'is-negativo' end);
    exception
      when others then
        if sqlcode <> -20061 then
          raise;
        end if;
    end;

    -- Pagamento (holerite). Mesmas regras da página 9 (pkg_holerite_ui.holerites_de):
    -- o mês atual só a partir do dia 25, nada antes da admissão. Se o dia mudar
    -- lá (c_dia_liberacao), mude aqui também. O valor chega oculto, como na p9.
    l_ultimo := case when to_number(to_char(l_hoje, 'DD')) >= 25
                     then trunc(l_hoje, 'MM') else add_months(trunc(l_hoje, 'MM'), -1) end;
    for h in (select h.data_pagamento, h.valor_liquido
                from colaborador_holerite h
                join colaborador c on c.id_colaborador = h.id_colaborador
               where h.id_colaborador = l_id
                 and to_date(to_char(h.ano_referencia * 100 + h.mes_referencia) || '01', 'YYYYMMDD') <= l_ultimo
                 and (c.data_admissao is null or c.data_admissao <= l_hoje)
                 and (c.data_admissao is null
                      or to_date(to_char(h.ano_referencia * 100 + h.mes_referencia) || '01', 'YYYYMMDD') >= trunc(c.data_admissao, 'MM'))
               order by h.ano_referencia desc, h.mes_referencia desc
               fetch first 1 rows only) loop
      indicador('wallet',
        case when h.data_pagamento > l_hoje then 'Próximo pagamento' else 'Último pagamento' end,
        'R$ <span data-cx-home-valor data-cx-home-original="' || a(moeda(h.valor_liquido)) || '">••••••</span>',
        case when h.data_pagamento > l_hoje then 'Crédito previsto em ' else 'Creditado em ' end
          || to_char(h.data_pagamento, 'DD/MM')
          || ' · <a href="' || a(apex_page.get_url(p_page => 9)) || '">ver holerite</a>',
        p_extra => '<button type="button" class="cx-home-indicador__olho" data-cx-home-mostrar aria-pressed="false"'
                || ' aria-label="Mostrar valor" title="Mostrar valor">' || icone('eye') || '</button>');
    end loop;

    -- Férias: saldo dos períodos aquisitivos completos e ainda no prazo
    select sum(nr_dias_direito - nr_dias_gozados),
           min(case when nr_dias_direito > nr_dias_gozados then dt_limite_gozo end)
      into l_dias, l_limite
      from ferias_periodo
     where id_colaborador = l_id
       and dt_fim_aquisitivo < l_hoje
       and dt_limite_gozo >= l_hoje;
    if l_dias is not null then
      indicador('palm', 'Férias disponíveis', l_dias || case when l_dias = 1 then ' dia' else ' dias' end,
        case when l_limite is not null then 'Período vence em ' || to_char(l_limite, 'DD/MM/YYYY')
             else 'Nenhum período a vencer' end);
    end if;

    -- PDI vigente: objetivos concluídos
    select count(o.id_objetivo), count(case when o.st_objetivo = 'CONCLUIDO' then 1 end)
      into l_qt_obj, l_qt_ok
      from pdi d
      join pdi_objetivo o on o.id_pdi = d.id_pdi
     where d.id_pdi = (select max(id_pdi) keep (dense_rank last order by id_pdi)
                         from pdi
                        where id_colaborador = l_id
                          and st_pdi in ('APROVADO', 'AGUARDANDO', 'AJUSTES'));
    if l_qt_obj > 0 then
      indicador('target', 'Meu PDI', l_qt_ok || ' de ' || l_qt_obj || ' objetivos',
        '<progress class="cx-home-progresso" value="' || l_qt_ok || '" max="' || l_qt_obj || '">'
          || round(100 * l_qt_ok / l_qt_obj) || '%</progress>'
          || '<span class="cx-home-progresso__pct">' || round(100 * l_qt_ok / l_qt_obj) || '%</span>');
    end if;

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

    g_qt_pendencias := l_qt;
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
    l_agora constant date := hoje;  -- horário de Brasília (as conversas estão em hora local)
  begin
    inicia;

    for g in (
      select g.id_colaborador,
             g.nome_completo,
             g.email,
             g.foto_url,
             cg.nome as cargo,
             d.nome  as departamento,
             c.id_colaborador as id_eu,
             -- Mesma regra da presença do chat (página 4)
             case when pr.data_ultimo_ping > systimestamp - interval '5' minute
                   and upper(pr.status_presenca) = 'ONLINE' then 'S' else 'N' end as disponivel,
             (select min(x.dh_conversa)
                from conversa_1a1 x
               where x.id_colaborador = c.id_colaborador
                 and x.id_gestor      = g.id_colaborador
                 and x.st_conversa    = 'AGENDADA'
                 and x.dh_conversa   >= l_agora) as proxima_1a1
        from colaborador c
        join colaborador g
          on g.id_colaborador = c.id_gestor
         and g.id_empresa     = c.id_empresa
        left join cargo cg
          on cg.id_cargo = g.id_cargo
        left join departamento d
          on d.id_departamento = g.id_departamento
        left join presenca_colaborador pr
          on pr.id_colaborador = g.id_colaborador
       where upper(trim(c.login_apex)) = upper(trim(p_login))
         and c.id_empresa = p_id_empresa
       fetch first 1 rows only
    ) loop
      p('<div class="cx-home-gestor">');
      p('<div class="cx-home-gestor__pessoa' || case when g.disponivel = 'S' then ' is-disponivel' end || '">');
      p(pessoa(g.nome_completo, g.foto_url,
               g.cargo || case when g.cargo is not null and g.departamento is not null then ' · ' end
                       || g.departamento));
      if g.disponivel = 'S' then
        p('<span class="cx-home-gestor__status">Disponível agora</span>');
      end if;
      p('</div>');

      if g.proxima_1a1 is not null then
        p('<div class="cx-home-gestor__conversa">' || icone('calendar-clock')
          || '<div><span>Próxima conversa 1:1</span><strong>'
          || dia_semana(g.proxima_1a1) || ', ' || to_char(g.proxima_1a1, 'DD/MM') || ' às '
          || to_char(g.proxima_1a1, 'HH24:MI') || '</strong></div></div>');
      end if;

      p('<div class="cx-acoes-card cx-home-gestor__acoes">');
      p('<a class="t-Button" href="' || a(apex_page.get_url(p_page => 4)) || '">'
        || icone('message') || '<span class="t-Button-label">Mensagem</span></a>');
      p('<button type="button" class="t-Button" data-cx-home-feedback="' || g.id_colaborador || '"'
        || ' data-cx-home-feedback-nome="' || a(g.nome_completo) || '" data-cx-home-feedback-tipo="RECONHECIMENTO">'
        || icone('feedback') || '<span class="t-Button-label">Dar feedback</span></button>');
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
    l_eu      constant number := colaborador_ponto(null);
  begin
    inicia;

    -- Aniversário (nascimento) e tempo de empresa (admissão há 1 ano ou mais)
    -- no mês atual. Próximos primeiro; os que já passaram no mês vão para o fim.
    for r in (
      with celebracao as (
        select id_colaborador, nome_completo, foto_url, 'ANIVERSARIO' as tipo,
               to_number(to_char(data_de_nascimento, 'dd')) as dia,
               cast(null as number) as anos
          from colaborador
         where id_empresa = p_id_empresa
           and status = true
           and to_char(data_de_nascimento, 'mm') = to_char(l_hoje, 'mm')
        union all
        select id_colaborador, nome_completo, foto_url, 'EMPRESA',
               to_number(to_char(data_admissao, 'dd')),
               extract(year from l_hoje) - extract(year from data_admissao)
          from colaborador
         where id_empresa = p_id_empresa
           and status = true
           and to_char(data_admissao, 'mm') = to_char(l_hoje, 'mm')
           and extract(year from data_admissao) < extract(year from l_hoje)
      )
      select id_colaborador, nome_completo, foto_url, tipo, dia, anos
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
        -- "Parabenizar" só para quem celebra hoje, e nunca para si mesmo
        || case when r.dia = l_dia_hoj and l_eu is not null and r.id_colaborador <> l_eu then
             '<button type="button" class="t-Button cx-home-parabenizar" data-cx-home-feedback="' || r.id_colaborador || '"'
             || ' data-cx-home-feedback-nome="' || a(r.nome_completo) || '" data-cx-home-feedback-tipo="RECONHECIMENTO"'
             || ' data-cx-home-feedback-texto="' || a(case r.tipo when 'ANIVERSARIO' then 'Feliz aniversário! '
                                                       else 'Parabéns pelos ' || r.anos || case when r.anos = 1 then ' ano' else ' anos' end || ' de empresa! ' end) || '">'
             || icone('party') || '<span class="t-Button-label">Parabenizar</span></button>'
           end
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

  ------------------------------------------------------------------------------
  -- Títulos das regiões (computações da página 1)
  ------------------------------------------------------------------------------
  function qt_pendencias return varchar2 is
    l_html clob;
  begin
    l_html := render_pendencias;
    return case when g_qt_pendencias > 0 then to_char(g_qt_pendencias) end;
  end qt_pendencias;

  function nao_lidos_texto return varchar2 is
    l_id constant number := colaborador_ponto(null);
    l_qt number;
  begin
    if l_id is null then
      return null;
    end if;
    l_qt := pkg_comunicado.qtd_nao_lidos(l_id);
    return case when l_qt = 1 then ' · 1 não lido'
                when l_qt > 1 then ' · ' || l_qt || ' não lidos' end;
  end nao_lidos_texto;

  ------------------------------------------------------------------------------
  -- Feedbacks recebidos
  ------------------------------------------------------------------------------
  function render_feedbacks (
    p_id_colaborador in number default null
  ) return clob is
    l_id constant number := colaborador_ponto(p_id_colaborador);
    l_qt pls_integer := 0;
  begin
    inicia;
    if l_id is not null then
      for f in (select f.tp_feedback, f.ds_texto, cast(f.dh_criacao as date) as dt,
                       a.nome_completo, a.foto_url,
                       case when a.id_colaborador = eu.id_gestor then 'Gestão direta'
                            when a.id_gestor = eu.id_gestor then 'Colega de equipe'
                            when eu.id_colaborador = a.id_gestor then 'Pessoa da sua equipe'
                            else 'Colega' end as relacao
                  from feedback f
                  join colaborador a  on a.id_colaborador = f.id_autor
                  join colaborador eu on eu.id_colaborador = f.id_destinatario
                 where f.id_destinatario = l_id
                   and f.dh_exclusao is null
                 order by f.dh_criacao desc
                 fetch first 2 rows only) loop
        l_qt := l_qt + 1;
        if l_qt = 1 then
          p('<ul class="cx-home-feedbacks">');
        end if;
        p('<li class="cx-home-feedback">'
          || '<div class="cx-home-feedback__topo">'
          || pessoa(f.nome_completo, f.foto_url, f.relacao || ' · ' || to_char(f.dt, 'DD/MM'))
          || case f.tp_feedback when 'RECONHECIMENTO' then selo('Reconhecimento', 'sucesso')
                                else selo('Sugestão', 'info') end
          || '</div>'
          || '<blockquote class="cx-home-feedback__texto">“' || e(f.ds_texto) || '”</blockquote>'
          || '</li>');
      end loop;
    end if;
    if l_qt = 0 then
      p(estado_vazio('fa-comments-o', 'Nenhum feedback ainda',
        'Os reconhecimentos e sugest&otilde;es que voc&ecirc; receber aparecem aqui.'));
    else
      p('</ul>');
    end if;
    return g_html;
  end render_feedbacks;

  ------------------------------------------------------------------------------
  -- Pesquisa de clima aberta (some depois que a pessoa responde)
  ------------------------------------------------------------------------------
  function render_pesquisa (
    p_id_colaborador in number default null
  ) return clob is
    l_id   constant number := colaborador_ponto(p_id_colaborador);
    l_hoje constant date   := trunc(hoje);  -- função privada não pode ir no SQL
  begin
    inicia;
    if l_id is null then
      return g_html;
    end if;
    for q in (select q.id_pesquisa, q.ds_titulo, q.ds_descricao, q.dt_fechamento, q.ds_link
                from pesquisa q
                join colaborador c on c.id_colaborador = l_id and c.id_empresa = q.id_empresa
               where l_hoje between q.dt_abertura and q.dt_fechamento
                 and not exists (select 1 from pesquisa_resposta r
                                  where r.id_pesquisa = q.id_pesquisa and r.id_colaborador = l_id)
               order by q.dt_fechamento
               fetch first 1 rows only) loop
      p('<section class="cx-home-pesquisa" aria-labelledby="cx-home-pesquisa-titulo">');
      p('<div class="cx-home-pesquisa__arte" aria-hidden="true"></div>');
      p('<div class="cx-home-pesquisa__conteudo">');
      p(selo('Aberta até ' || to_char(q.dt_fechamento, 'DD/MM'), 'atencao'));
      p('<h2 id="cx-home-pesquisa-titulo" class="cx-home-pesquisa__titulo">' || e(q.ds_titulo) || '</h2>');
      if q.ds_descricao is not null then
        p('<p class="cx-home-pesquisa__texto">' || e(q.ds_descricao) || '</p>');
      end if;
      p('<a class="t-Button t-Button--hot cx-home-pesquisa__botao" href="' || a(q.ds_link) || '"'
        || ' target="_blank" rel="noopener" data-cx-home-pesquisa="' || q.id_pesquisa || '">'
        || '<span class="t-Button-label">Responder pesquisa</span></a>');
      p('</div></section>');
    end loop;
    return g_html;
  end render_pesquisa;

  ------------------------------------------------------------------------------
  -- Próximos eventos (agenda da empresa + feriados do ponto)
  ------------------------------------------------------------------------------
  function render_eventos (
    p_id_empresa in number default to_number(v('G_ID_EMPRESA') default null on conversion error)
  ) return clob is
    l_hoje constant date := trunc(hoje);
    l_qt   pls_integer := 0;
  begin
    inicia;
    for ev in (select dh_inicio, dh_fim, ds_titulo, ds_local, 'N' as feriado
                 from evento
                where id_empresa = p_id_empresa
                  and dh_inicio >= l_hoje
               union all
               select dt_feriado, null, nm_feriado, null, 'S'
                 from ponto_feriado
                where id_empresa = p_id_empresa
                  and dt_feriado >= l_hoje
                order by 1
                fetch first 4 rows only) loop
      l_qt := l_qt + 1;
      if l_qt = 1 then
        p('<ul class="cx-home-eventos">');
      end if;
      p('<li class="cx-home-evento">'
        || '<span class="cx-home-evento__data" aria-hidden="true"><span>' || mes_curto(ev.dh_inicio) || '</span>'
        || '<strong>' || to_char(ev.dh_inicio, 'DD') || '</strong></span>'
        || '<div class="cx-home-evento__texto"><strong>' || e(ev.ds_titulo) || '</strong>'
        || '<span>'
        || case when ev.feriado = 'S' then 'Feriado'
                else to_char(ev.dh_inicio, 'HH24:MI')
                     || case when ev.dh_fim is not null then ' às ' || to_char(ev.dh_fim, 'HH24:MI') end
                     || case when ev.ds_local is not null then ' · ' || e(ev.ds_local) end
           end
        || '</span></div>'
        || case when trunc(ev.dh_inicio) = l_hoje     then selo('Hoje', 'info')
                when trunc(ev.dh_inicio) = l_hoje + 1 then selo('Amanhã', 'neutro')
                when ev.feriado = 'S'                 then selo('Feriado', 'neutro') end
        || '</li>');
    end loop;
    if l_qt = 0 then
      p(estado_vazio('fa-calendar-o', 'Nenhum evento agendado',
        'Eventos e feriados da empresa aparecem aqui.'));
    else
      p('</ul>');
    end if;
    return g_html;
  end render_eventos;

  ------------------------------------------------------------------------------
  -- Ajax Callbacks da página 1
  ------------------------------------------------------------------------------
  procedure ajax_marcar_lido (p_id_comunicado in varchar2) is
    l_id  constant number := colaborador_ponto(null);
    l_com number;
  begin
    if l_id is null then
      responder(true, null);  -- conta sem colaborador: só segue para o comunicado
      return;
    end if;
    -- Só comunicado da empresa da pessoa
    select c.id_comunicado
      into l_com
      from comunicado c
      join colaborador col on col.id_colaborador = l_id and col.id_empresa = c.id_empresa
     where c.id_comunicado = to_number(p_id_comunicado default null on conversion error);
    pkg_comunicado.marcar_como_lido(l_com, l_id);
    responder(true, null);
  exception
    when no_data_found then
      responder(false, 'Comunicado não encontrado.');
    when others then
      responder_erro(sqlcode, sqlerrm);
  end ajax_marcar_lido;

  procedure ajax_responder_pesquisa (p_id_pesquisa in varchar2) is
    l_id  constant number := colaborador_ponto(null);
  begin
    if l_id is null then
      responder(true, null);
      return;
    end if;
    -- Registra só a participação (a resposta fica no formulário externo, anônimo)
    merge into pesquisa_resposta r
    using (select q.id_pesquisa
             from pesquisa q
             join colaborador c on c.id_colaborador = l_id and c.id_empresa = q.id_empresa
            where q.id_pesquisa = to_number(p_id_pesquisa default null on conversion error)) s
       on (r.id_pesquisa = s.id_pesquisa and r.id_colaborador = l_id)
     when not matched then insert (id_pesquisa, id_colaborador) values (s.id_pesquisa, l_id);
    commit;
    responder(true, null);
  exception
    when others then
      responder_erro(sqlcode, sqlerrm);
  end ajax_responder_pesquisa;

  procedure ajax_salvar_feedback (
    p_id_destinatario in varchar2,
    p_tp_feedback     in varchar2,
    p_ds_texto        in varchar2
  ) is
    l_autor   constant number := colaborador_ponto(null);
    l_dest    number;
    l_empresa number;
    l_texto   constant varchar2(4000) := trim(p_ds_texto);
  begin
    if l_autor is null then
      raise_application_error(-20090, 'Sua conta não está vinculada a um colaborador desta empresa.');
    elsif p_tp_feedback not in ('RECONHECIMENTO', 'SUGESTAO') or p_tp_feedback is null then
      raise_application_error(-20091, 'Escolha se é um reconhecimento ou uma sugestão.');
    elsif l_texto is null then
      raise_application_error(-20092, 'Escreva o feedback antes de enviar.');
    elsif length(l_texto) > 1000 then
      raise_application_error(-20093, 'O feedback pode ter no máximo 1000 caracteres.');
    end if;

    begin
      select d.id_colaborador, d.id_empresa
        into l_dest, l_empresa
        from colaborador d
        join colaborador eu on eu.id_colaborador = l_autor and eu.id_empresa = d.id_empresa
       where d.id_colaborador = to_number(p_id_destinatario default null on conversion error)
         and d.status = true;
    exception
      when no_data_found then
        raise_application_error(-20094, 'Essa pessoa não foi encontrada na sua empresa.');
    end;
    if l_dest = l_autor then
      raise_application_error(-20095, 'Não é possível enviar feedback para você mesmo.');
    end if;

    insert into feedback (id_empresa, id_autor, id_destinatario, tp_feedback, ds_texto)
    values (l_empresa, l_autor, l_dest, p_tp_feedback, l_texto);
    commit;
    responder(true, 'Feedback enviado.');
  exception
    when others then
      rollback;
      responder_erro(sqlcode, sqlerrm);
  end ajax_salvar_feedback;

end pkg_home_ui;
/
