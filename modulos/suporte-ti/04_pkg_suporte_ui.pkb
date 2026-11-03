--------------------------------------------------------------------------------
-- Corlix Hub · Suporte TI · 04 · HTML e callbacks · corpo
-- Os ícones são SVG Lucide em linha, como no ponto eletrônico. Datas com
-- to_char explícito: o idioma técnico da app é "en". Todo texto do banco passa
-- por e() ou a() antes de entrar no HTML.
--------------------------------------------------------------------------------
create or replace package body pkg_suporte_ui as

  c_pag_abrir   constant pls_integer := 35;
  c_pag_chamado constant pls_integer := 36;
  c_pag_base    constant pls_integer := 37;
  c_pag_chat    constant pls_integer := 4;

  c_max_encerrados constant pls_integer := 20;
  c_max_artigos    constant pls_integer := 5;
  c_max_busca      constant pls_integer := 5;

  c_com_acento constant varchar2(60) := 'áàâãäéèêëíìîïóòôõöúùûüçñ';
  c_sem_acento constant varchar2(60) := 'aaaaaeeeeiiiiooooouuuucn';

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

  -- Texto livre com as quebras de linha preservadas
  function texto (p_txt in varchar2) return varchar2 is
  begin
    return replace(e(replace(p_txt, chr(13))), chr(10), '<br>');
  end texto;

  -- Colaborador da conta logada; nulo sem vínculo ou sem empresa na sessão
  function id_logado return number is
  begin
    return pkg_suporte.fn_colaborador_logado;
  exception
    when others then
      if sqlcode in (-20076, -20012) then
        return null;
      end if;
      raise;
  end id_logado;

  function empresa_de (p_id_colaborador in number) return number is
    l_empresa number;
  begin
    select id_empresa into l_empresa from colaborador where id_colaborador = p_id_colaborador;
    return l_empresa;
  end empresa_de;

  function dia_mes (p_dt in date) return varchar2 is
  begin
    return to_char(p_dt, 'DD/MM');
  end dia_mes;

  -- "agora", "há 15 min", "há 2 h", "há 3 dias"
  function ha_quanto (p_dh in timestamp with time zone) return varchar2 is
    l_min constant number := round(
      (cast(sys_extract_utc(systimestamp) as date) - cast(sys_extract_utc(p_dh) as date)) * 1440);
  begin
    return case
      when l_min < 1    then 'agora'
      when l_min < 60   then 'há ' || l_min || ' min'
      when l_min < 1440 then 'há ' || trunc(l_min / 60) || ' h'
      when l_min < 2880 then 'há 1 dia'
      else 'há ' || trunc(l_min / 1440) || ' dias'
    end;
  end ha_quanto;

  function iniciais (p_nome in varchar2) return varchar2 is
    l_nome constant varchar2(200) := trim(p_nome);
    l_esp  constant pls_integer := instr(l_nome, ' ', -1);
  begin
    if l_esp = 0 then
      return upper(substr(l_nome, 1, 2));
    end if;
    return upper(substr(l_nome, 1, 1) || substr(l_nome, l_esp + 1, 1));
  end iniciais;

  -- "Marina Costa": primeiro e último nome
  function nome_curto (p_nome in varchar2) return varchar2 is
    l_nome constant varchar2(200) := trim(p_nome);
    l_ini  constant pls_integer := instr(l_nome, ' ');
    l_fim  constant pls_integer := instr(l_nome, ' ', -1);
  begin
    if l_ini = 0 then
      return l_nome;
    end if;
    return substr(l_nome, 1, l_ini - 1) || substr(l_nome, l_fim);
  end nome_curto;

  function icone (p_nome in varchar2) return varchar2 is
    l_svg varchar2(1000);
  begin
    l_svg := case p_nome
      when 'key'      then '<path d="m15.5 7.5 2.3 2.3a1 1 0 0 0 1.4 0l2.1-2.1a1 1 0 0 0 0-1.4L19 4"/><path d="m21 2-9.6 9.6"/><circle cx="7.5" cy="15.5" r="5.5"/>'
      when 'mail'     then '<rect width="20" height="16" x="2" y="4" rx="2"/><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/>'
      when 'laptop'   then '<rect width="18" height="12" x="3" y="4" rx="2"/><line x1="2" x2="22" y1="20" y2="20"/>'
      when 'wifi'     then '<path d="M12 20h.01"/><path d="M2 8.82a15 15 0 0 1 20 0"/><path d="M5 12.86a10 10 0 0 1 14 0"/><path d="M8.5 16.43a5 5 0 0 1 7 0"/>'
      when 'janela'   then '<rect width="20" height="16" x="2" y="4" rx="2"/><path d="M2 9h20"/><path d="M6 6.5h.01"/><path d="M10 6.5h.01"/>'
      when 'printer'  then '<path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"/><path d="M6 9V3a1 1 0 0 1 1-1h10a1 1 0 0 1 1 1v6"/><rect width="12" height="8" x="6" y="14" rx="1"/>'
      when 'busca'    then '<circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/>'
      when 'chevron'  then '<path d="m9 18 6-6-6-6"/>'
      when 'seta'     then '<path d="M5 12h14"/><path d="m12 5 7 7-7 7"/>'
      when 'voltar'   then '<path d="m12 19-7-7 7-7"/><path d="M19 12H5"/>'
      when 'mais'     then '<path d="M5 12h14"/><path d="M12 5v14"/>'
      when 'alerta'   then '<path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z"/><path d="M12 9v4"/><path d="M12 17h.01"/>'
      when 'fechar'   then '<path d="M18 6 6 18"/><path d="m6 6 12 12"/>'
      when 'artigo'   then '<path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z"/><path d="M14 2v4a2 2 0 0 0 2 2h4"/><path d="M16 13H8"/><path d="M16 17H8"/><path d="M10 9H8"/>'
      when 'responder' then '<polyline points="9 17 4 12 9 7"/><path d="M20 18v-2a4 4 0 0 0-4-4H4"/>'
      when 'check'    then '<path d="M20 6 9 17l-5-5"/>'
      when 'pessoa'   then '<path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/>'
      when 'calendario' then '<path d="M8 2v4"/><path d="M16 2v4"/><rect width="18" height="18" x="3" y="4" rx="2"/><path d="M3 10h18"/><path d="m12 14v3l2 1"/>'
      when 'chat'     then '<path d="M14 9a2 2 0 0 1-2 2H6l-4 4V4a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2Z"/><path d="M18 9h2a2 2 0 0 1 2 2v11l-4-4h-6a2 2 0 0 1-2-2v-1"/>'
      when 'telefone' then '<path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92Z"/>'
      when 'relogio'  then '<circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/>'
      when 'anexo'    then '<path d="m21.44 11.05-9.19 9.19a6 6 0 0 1-8.49-8.49l8.57-8.57A4 4 0 1 1 18 8.84l-8.59 8.57a2 2 0 0 1-2.83-2.83l8.49-8.48"/>'
    end;
    return '<svg class="cx-sup-icone" width="18" height="18" viewBox="0 0 24 24" aria-hidden="true" focusable="false">'
        || l_svg || '</svg>';
  end icone;

  procedure cabecalho_card (p_titulo in varchar2, p_extra in varchar2 default null) is
  begin
    p('<header class="cx-sup-card__cabecalho"><h2 class="cx-sup-card__titulo">' || e(p_titulo) || '</h2>');
    p(p_extra);
    p('</header>');
  end cabecalho_card;

  function selo_chamado (p_st in varchar2) return varchar2 is
    l_txt    varchar2(40);
    l_classe varchar2(20);
  begin
    case p_st
      when pkg_suporte.c_aberto      then l_txt := 'Na fila';         l_classe := 'is-neutro';
      when pkg_suporte.c_atendimento then l_txt := 'Em atendimento';  l_classe := 'is-info';
      when pkg_suporte.c_aguardando  then l_txt := 'Aguardando você'; l_classe := 'is-atencao';
      when pkg_suporte.c_resolvido   then l_txt := 'Resolvido';       l_classe := 'is-sucesso';
      else                                l_txt := 'Encerrado';       l_classe := 'is-neutro';
    end case;
    return '<span class="cx-sup-selo ' || l_classe || '">' || l_txt || '</span>';
  end selo_chamado;

  function selo_sistema (p_st in varchar2) return varchar2 is
  begin
    return case p_st
      when 'OPERANDO'   then '<span class="cx-sup-status is-sucesso">Operando</span>'
      when 'INSTAVEL'   then '<span class="cx-sup-selo is-atencao">Instável</span>'
      when 'MANUTENCAO' then '<span class="cx-sup-selo is-info">Manutenção</span>'
      else '<span class="cx-sup-selo is-erro">Fora do ar</span>'
    end;
  end selo_sistema;

  function url_chamado (p_id_chamado in number) return varchar2 is
  begin
    return apex_page.get_url(
      p_page        => c_pag_chamado,
      p_clear_cache => to_char(c_pag_chamado),
      p_items       => 'P36_ID_CHAMADO',
      p_values      => to_char(p_id_chamado));
  end url_chamado;

  function url_artigo (p_id_artigo in number) return varchar2 is
  begin
    return apex_page.get_url(
      p_page        => c_pag_base,
      p_clear_cache => to_char(c_pag_base),
      p_items       => 'P37_ID_ARTIGO',
      p_values      => to_char(p_id_artigo));
  end url_artigo;

  function url_assunto (p_id_assunto in number) return varchar2 is
  begin
    return apex_page.get_url(
      p_page        => c_pag_base,
      p_clear_cache => to_char(c_pag_base),
      p_items       => 'P37_ID_ASSUNTO',
      p_values      => to_char(p_id_assunto));
  end url_assunto;

  function url_abrir (p_id_assunto in number default null) return varchar2 is
  begin
    return apex_page.get_url(
      p_page        => c_pag_abrir,
      p_clear_cache => to_char(c_pag_abrir),
      p_items       => case when p_id_assunto is not null then 'P35_ID_ASSUNTO' end,
      p_values      => to_char(p_id_assunto));
  end url_abrir;

  -- Busca sem acento e sem diferença de maiúsculas
  function normaliza (p_txt in varchar2) return varchar2 is
  begin
    return translate(lower(p_txt), c_com_acento, c_sem_acento);
  end normaliza;

  function linha_artigo (p_id in number, p_titulo in varchar2, p_min in number) return varchar2 is
  begin
    return '<li><a class="cx-sup-artigo" href="' || a(url_artigo(p_id)) || '">' || icone('artigo')
        || '<span class="cx-sup-artigo__titulo">' || e(p_titulo) || '</span>'
        || '<span class="cx-sup-artigo__tempo">' || p_min || ' min</span></a></li>';
  end linha_artigo;

  ------------------------------------------------------------------------------
  -- Página 34
  ------------------------------------------------------------------------------
  function render_cabecalho return clob is
    l_id constant number := id_logado;
  begin
    inicia;
    p('<div class="cx-cabecalho-pagina cx-cabecalho-pagina--acoes">');
    p('<div class="cx-cabecalho-pagina__texto"><h1 class="cx-cabecalho-pagina__titulo">Suporte TI</h1>');
    p('<p class="cx-cabecalho-pagina__descricao">Encontre respostas rápidas ou abra um chamado para a equipe de TI.</p></div>');
    if l_id is not null then
      p('<div class="cx-cabecalho-pagina__acoes">');
      p('<a class="t-Button cx-sup-botao cx-sup-botao--primario" href="' || a(url_abrir) || '">'
        || icone('mais') || '<span class="t-Button-label">Abrir chamado</span></a>');
      p('</div>');
    end if;
    p('</div>');
    return g_html;
  end render_cabecalho;

  -- O "x" esconde o aviso até ele mudar: a chave leva a data da última alteração.
  function render_aviso return clob is
    l_id      constant number := id_logado;
    l_empresa number;
  begin
    inicia;
    if l_id is null then
      return g_html;
    end if;
    l_empresa := empresa_de(l_id);
    for r in (
      select s.id_sistema, s.ds_aviso_titulo, s.ds_aviso_texto,
             to_char(s.dh_atualizacao at time zone 'UTC', 'YYYYMMDDHH24MISS') as cd_versao
        from suporte_sistema s
       where s.id_empresa = l_empresa
         and s.st_sistema <> 'OPERANDO'
         and s.ds_aviso_titulo is not null
       order by s.nr_ordem, s.nm_sistema
    ) loop
      p('<div class="cx-sup-aviso" role="status" data-cx-sup-aviso="' || r.id_sistema || '-' || r.cd_versao || '">');
      p(icone('alerta'));
      p('<div class="cx-sup-aviso__texto"><strong>' || e(r.ds_aviso_titulo) || '</strong>');
      if r.ds_aviso_texto is not null then
        p('<p>' || e(r.ds_aviso_texto) || '</p>');
      end if;
      p('</div>');
      p('<button type="button" class="cx-sup-aviso__fechar" data-cx-sup-fechar-aviso aria-label="Fechar aviso">'
        || icone('fechar') || '</button>');
      p('</div>');
    end loop;
    return g_html;
  end render_aviso;

  function render_ajuda return clob is
    l_id      constant number := id_logado;
    l_nome    varchar2(200);
    l_empresa number;
  begin
    inicia;
    if l_id is null then
      p('<section class="cx-sup-card cx-sup-vazio"><p>Sua conta não está vinculada a um colaborador desta empresa. '
        || 'O suporte fica disponível depois que o RH fizer esse vínculo.</p></section>');
      return g_html;
    end if;

    select id_empresa, coalesce(trim(primeiro_nome), regexp_substr(trim(nome_completo), '^[^ ]+'))
      into l_empresa, l_nome
      from colaborador
     where id_colaborador = l_id;

    p('<section class="cx-sup-card cx-sup-ajuda">');
    p('<h2 class="cx-sup-ajuda__titulo">Como podemos ajudar, ' || e(l_nome) || '?</h2>');
    p('<p class="cx-sup-ajuda__texto">Muitas dúvidas se resolvem em poucos minutos com os artigos da base de conhecimento.</p>');
    p('<div class="cx-sup-busca">' || icone('busca'));
    p('<input type="search" class="cx-sup-busca__campo" data-cx-sup-busca maxlength="200" autocomplete="off" '
      || 'aria-label="Descreva o problema" aria-controls="cx_sup_resultados" '
      || 'placeholder="Descreva o problema. Ex.: esqueci minha senha, a VPN não conecta">');
    p('</div>');
    p('<div id="cx_sup_resultados" class="cx-sup-resultados" aria-live="polite"></div>');
    p('<h3 class="cx-sup-ajuda__subtitulo">Ou escolha um assunto</h3>');
    p('<ul class="cx-sup-assuntos">');
    for r in (
      select id_assunto, nm_assunto, cd_icone
        from suporte_assunto
       where id_empresa = l_empresa
         and fl_ativo = 'S'
       order by nr_ordem, nm_assunto
    ) loop
      p('<li><a class="cx-sup-assunto" href="' || a(url_assunto(r.id_assunto)) || '">'
        || '<span class="cx-sup-assunto__icone">' || icone(r.cd_icone) || '</span>'
        || '<span class="cx-sup-assunto__nome">' || e(r.nm_assunto) || '</span>'
        || icone('chevron') || '</a></li>');
    end loop;
    p('</ul></section>');
    return g_html;
  end render_ajuda;

  -- Corpo de cada chamado em aberto, conforme a situação
  procedure chamado_aberto (r in suporte_chamado%rowtype, p_nm_assunto in varchar2, p_nm_atendente in varchar2) is
    l_url constant varchar2(4000) := url_chamado(r.id_chamado);
    l_ti  boolean := false;
  begin
    p('<li class="cx-sup-chamado">');
    p('<div class="cx-sup-chamado__topo"><a class="cx-sup-chamado__titulo" href="' || a(l_url) || '">' || e(r.ds_titulo) || '</a>');
    p(selo_chamado(r.st_chamado) || '</div>');
    p('<p class="cx-sup-chamado__meta">' || e(pkg_suporte.fn_codigo(r.tp_chamado, r.id_chamado)) || ' · ' || e(p_nm_assunto) || ' · ');
    if r.st_chamado = pkg_suporte.c_resolvido then
      p('resolvido em ' || dia_mes(pkg_historico_carreira.fn_data_local(r.id_empresa, r.dh_resolucao)));
    else
      p('aberto em ' || dia_mes(pkg_historico_carreira.fn_data_local(r.id_empresa, r.dh_abertura)));
    end if;
    p('</p>');

    if r.st_chamado = pkg_suporte.c_aguardando then
      for m in (
        select *
          from (select m.ds_texto, m.dh_envio, c.nome_completo
                  from suporte_mensagem m
                  left join colaborador c on c.id_colaborador = m.id_autor
                 where m.id_chamado = r.id_chamado
                   and m.tp_autor = 'TI'
                 order by m.id_mensagem desc)
         where rownum = 1
      ) loop
        l_ti := true;
        p('<div class="cx-sup-mensagem">');
        p('<span class="cx-sup-avatar" aria-hidden="true">' || e(iniciais(m.nome_completo)) || '</span>');
        p('<div class="cx-sup-mensagem__corpo"><p class="cx-sup-mensagem__autor">' || e(nome_curto(m.nome_completo))
          || ' · TI · ' || e(ha_quanto(m.dh_envio)) || '</p>');
        p('<p class="cx-sup-mensagem__texto">' || texto(m.ds_texto) || '</p></div></div>');
      end loop;
      p('<div class="cx-sup-chamado__acoes"><a class="t-Button cx-sup-botao" href="' || a(l_url) || '">'
        || icone('responder') || '<span class="t-Button-label">Responder</span></a></div>');

    elsif r.st_chamado = pkg_suporte.c_resolvido then
      p('<p class="cx-sup-chamado__solucao">Solução: ' || texto(r.ds_solucao) || '</p>');
      p('<div class="cx-sup-chamado__confirmar"><p>A solução funcionou? Sem resposta, o chamado é encerrado em '
        || dia_mes(r.dt_limite_confirmacao) || '.</p>');
      p('<div class="cx-sup-chamado__botoes"><a class="cx-sup-link" href="' || a(l_url) || '">Não, reabrir</a>');
      p('<button type="button" class="t-Button cx-sup-botao" data-cx-sup-confirmar="' || r.id_chamado || '">'
        || icone('check') || '<span class="t-Button-label">Sim, encerrar</span></button></div></div>');

    elsif p_nm_atendente is not null or r.dt_previsao is not null then
      p('<ul class="cx-sup-chamado__dados">');
      if p_nm_atendente is not null then
        p('<li>' || icone('pessoa') || e(nome_curto(p_nm_atendente)) || ' · TI</li>');
      end if;
      if r.dt_previsao is not null then
        p('<li>' || icone('calendario') || 'Previsão: até ' || dia_mes(r.dt_previsao) || '</li>');
      end if;
      p('</ul>');
    end if;
    p('</li>');
  end chamado_aberto;

  function render_chamados return clob is
    l_id      constant number := id_logado;
    l_abertos pls_integer;
    l_fim     pls_integer;
    l_c       suporte_chamado%rowtype;
  begin
    inicia;
    if l_id is null then
      return g_html;
    end if;

    select count(case when st_chamado <> pkg_suporte.c_encerrado then 1 end),
           count(case when st_chamado =  pkg_suporte.c_encerrado then 1 end)
      into l_abertos, l_fim
      from suporte_chamado
     where id_solicitante = l_id;

    p('<section class="cx-sup-card">');
    p('<header class="cx-sup-card__cabecalho cx-sup-card__cabecalho--abas"><h2 class="cx-sup-card__titulo">Meus chamados</h2>');
    p('<div class="cx-sup-abas" role="tablist" aria-label="Meus chamados">');
    p('<button type="button" role="tab" id="cx_sup_aba_abertos" class="cx-sup-aba is-ativa" aria-selected="true" aria-controls="cx_sup_abertos" data-cx-sup-aba="cx_sup_abertos">Em aberto · ' || l_abertos || '</button>');
    p('<button type="button" role="tab" id="cx_sup_aba_resolvidos" class="cx-sup-aba" aria-selected="false" aria-controls="cx_sup_resolvidos" data-cx-sup-aba="cx_sup_resolvidos" tabindex="-1">Resolvidos · ' || l_fim || '</button>');
    p('</div></header>');

    p('<div id="cx_sup_abertos" role="tabpanel" aria-labelledby="cx_sup_aba_abertos">');
    if l_abertos = 0 then
      p('<p class="cx-sup-vazio">Você não tem chamados em aberto.</p>');
    else
      p('<ul class="cx-sup-chamados">');
      -- Primeiro o que depende da pessoa; depois o que está com a TI
      for r in (
        select c.id_chamado, a.nm_assunto, t.nome_completo as nm_atendente
          from suporte_chamado c
          join suporte_assunto a on a.id_assunto = c.id_assunto
          left join colaborador t on t.id_colaborador = c.id_atendente
         where c.id_solicitante = l_id
           and c.st_chamado <> pkg_suporte.c_encerrado
         order by case c.st_chamado
                    when pkg_suporte.c_aguardando then 1
                    when pkg_suporte.c_resolvido  then 2
                    else 3
                  end,
                  c.id_chamado desc
      ) loop
        select * into l_c from suporte_chamado where id_chamado = r.id_chamado;
        chamado_aberto(l_c, r.nm_assunto, r.nm_atendente);
      end loop;
      p('</ul>');
    end if;
    p('</div>');

    p('<div id="cx_sup_resolvidos" role="tabpanel" aria-labelledby="cx_sup_aba_resolvidos" hidden>');
    if l_fim = 0 then
      p('<p class="cx-sup-vazio">Nenhum chamado encerrado por aqui.</p>');
    else
      p('<ul class="cx-sup-chamados">');
      for r in (
        select *
          from (select c.id_chamado, c.id_empresa, c.tp_chamado, c.ds_titulo, c.st_chamado, c.ds_solucao, c.dh_encerramento, a.nm_assunto
                  from suporte_chamado c
                  join suporte_assunto a on a.id_assunto = c.id_assunto
                 where c.id_solicitante = l_id
                   and c.st_chamado = pkg_suporte.c_encerrado
                 order by c.dh_encerramento desc)
         where rownum <= c_max_encerrados
      ) loop
        p('<li class="cx-sup-chamado"><div class="cx-sup-chamado__topo"><a class="cx-sup-chamado__titulo" href="'
          || a(url_chamado(r.id_chamado)) || '">' || e(r.ds_titulo) || '</a>' || selo_chamado(r.st_chamado) || '</div>');
        p('<p class="cx-sup-chamado__meta">' || e(pkg_suporte.fn_codigo(r.tp_chamado, r.id_chamado)) || ' · ' || e(r.nm_assunto)
          || ' · encerrado em ' || dia_mes(pkg_historico_carreira.fn_data_local(r.id_empresa, r.dh_encerramento)) || '</p>');
        if r.ds_solucao is not null then
          p('<p class="cx-sup-chamado__solucao">Solução: ' || texto(r.ds_solucao) || '</p>');
        end if;
        p('</li>');
      end loop;
      p('</ul>');
      if l_fim > c_max_encerrados then
        p('<p class="cx-sup-nota">Mostrando os ' || c_max_encerrados || ' mais recentes.</p>');
      end if;
    end if;
    p('</div></section>');
    return g_html;
  end render_chamados;

  function render_status return clob is
    l_id      constant number := id_logado;
    l_empresa number;
    l_ultima  date;
    l_hoje    date;
  begin
    inicia;
    if l_id is null then
      return g_html;
    end if;
    l_empresa := empresa_de(l_id);
    l_hoje    := pkg_historico_carreira.fn_hoje(l_empresa);

    select pkg_historico_carreira.fn_data_local(l_empresa, max(dh_atualizacao))
      into l_ultima
      from suporte_sistema
     where id_empresa = l_empresa;

    if l_ultima is null then
      return g_html; -- empresa sem sistemas cadastrados
    end if;

    p('<section class="cx-sup-card">');
    cabecalho_card('Status dos sistemas',
      '<span class="cx-sup-card__nota">Atualizado '
      || case when trunc(l_ultima) = l_hoje then 'às ' || to_char(l_ultima, 'HH24:MI')
              else 'em ' || to_char(l_ultima, 'DD/MM') end
      || '</span>');
    p('<ul class="cx-sup-sistemas">');
    for r in (
      select nm_sistema, st_sistema, ds_detalhe
        from suporte_sistema
       where id_empresa = l_empresa
       order by nr_ordem, nm_sistema
    ) loop
      p('<li class="cx-sup-sistema"><div><span class="cx-sup-sistema__nome">' || e(r.nm_sistema) || '</span>');
      if r.st_sistema <> 'OPERANDO' and r.ds_detalhe is not null then
        p('<span class="cx-sup-sistema__detalhe">' || e(r.ds_detalhe) || '</span>');
      end if;
      p('</div>' || selo_sistema(r.st_sistema) || '</li>');
    end loop;
    p('</ul></section>');
    return g_html;
  end render_status;

  function render_artigos return clob is
    l_id      constant number := id_logado;
    l_qt      pls_integer := 0;
    l_empresa number;
  begin
    inicia;
    if l_id is null then
      return g_html;
    end if;
    l_empresa := empresa_de(l_id);
    p('<section class="cx-sup-card">');
    cabecalho_card('Artigos mais acessados');
    p('<ul class="cx-sup-artigos">');
    for r in (
      select *
        from (select id_artigo, ds_titulo, nr_min_leitura
                from suporte_artigo
               where id_empresa = l_empresa
                 and fl_publicado = 'S'
               order by nr_acessos desc, ds_titulo)
       where rownum <= c_max_artigos
    ) loop
      l_qt := l_qt + 1;
      p(linha_artigo(r.id_artigo, r.ds_titulo, r.nr_min_leitura));
    end loop;
    p('</ul>');
    if l_qt = 0 then
      p('<p class="cx-sup-vazio">Ainda não há artigos publicados.</p>');
    end if;
    p('<footer class="cx-sup-card__rodape"><a class="cx-sup-link" href="'
      || a(apex_page.get_url(p_page => c_pag_base, p_clear_cache => to_char(c_pag_base)))
      || '">Ver base de conhecimento' || icone('seta') || '</a></footer>');
    p('</section>');
    return g_html;
  end render_artigos;

  function render_contato return clob is
    l_id      constant number := id_logado;
    l_c       suporte_config%rowtype;
    l_empresa number;
  begin
    inicia;
    if l_id is null then
      return g_html;
    end if;
    l_empresa := empresa_de(l_id);
    begin
      select * into l_c from suporte_config where id_empresa = l_empresa;
    exception
      when no_data_found then
        null; -- sem configuração: só o chat
    end;

    p('<section class="cx-sup-card cx-sup-contato">');
    p('<h2 class="cx-sup-card__titulo">Prefere falar com alguém?</h2>');
    p('<p class="cx-sup-contato__texto">Converse com a equipe de TI pelo chat do CorlixHub.</p>');
    p('<a class="t-Button cx-sup-botao cx-sup-botao--largo" href="' || a(apex_page.get_url(p_page => c_pag_chat))
      || '">' || icone('chat') || '<span class="t-Button-label">Conversar com a TI</span></a>');
    if l_c.ds_ramal is not null or l_c.ds_telefone is not null then
      p('<p class="cx-sup-contato__linha">' || icone('telefone') || '<span>Sem acesso ao computador? '
        || case when l_c.ds_ramal is not null then 'Ramal ' || e(l_c.ds_ramal) end
        || case when l_c.ds_ramal is not null and l_c.ds_telefone is not null then ' ou ' end
        || e(l_c.ds_telefone) || '</span></p>');
    end if;
    if l_c.ds_horario is not null then
      p('<p class="cx-sup-contato__linha">' || icone('relogio') || '<span>' || e(l_c.ds_horario) || '</span></p>');
    end if;
    p('</section>');
    return g_html;
  end render_contato;

  ------------------------------------------------------------------------------
  -- Conversa (páginas 36 e 39)
  ------------------------------------------------------------------------------
  procedure anexos_de (p_id_chamado in number, p_id_mensagem in number) is
    l_qt pls_integer := 0;
  begin
    for r in (
      select id_anexo, nm_arquivo, nr_bytes
        from suporte_anexo
       where id_chamado = p_id_chamado
         and ((p_id_mensagem is null and id_mensagem is null) or id_mensagem = p_id_mensagem)
       order by id_anexo
    ) loop
      l_qt := l_qt + 1;
      if l_qt = 1 then
        p('<ul class="cx-sup-anexos">');
      end if;
      -- URL simples (p_plain_url): é download, e a página de origem é um modal
      p('<li><a class="cx-sup-link" href="'
        || a(apex_page.get_url(
               p_page      => c_pag_chamado,
               p_request   => 'BAIXAR_ANEXO',
               p_items     => 'P36_ID_ANEXO',
               p_values    => to_char(r.id_anexo),
               p_plain_url => true))
        || '">' || icone('anexo') || e(r.nm_arquivo) || '</a> <span class="cx-sup-anexos__tamanho">'
        || greatest(round(r.nr_bytes / 1024), 1) || ' KB</span></li>');
    end loop;
    if l_qt > 0 then
      p('</ul>');
    end if;
  end anexos_de;

  function render_conversa (p_id_chamado in number) return clob is
    l_st      varchar2(20);
    l_c       suporte_chamado%rowtype;
    l_assunto suporte_assunto.nm_assunto%type;
    l_solic   colaborador.nome_completo%type;
  begin
    inicia;
    l_st := pkg_suporte.fn_situacao(p_id_chamado); -- -20077 se a conta não pode ver

    select * into l_c from suporte_chamado where id_chamado = p_id_chamado;
    select nm_assunto into l_assunto from suporte_assunto where id_assunto = l_c.id_assunto;
    select nome_completo into l_solic from colaborador where id_colaborador = l_c.id_solicitante;

    p('<div class="cx-sup-conversa">');
    p('<div class="cx-sup-chamado__topo"><h2 class="cx-sup-card__titulo">' || e(l_c.ds_titulo) || '</h2>'
      || selo_chamado(l_st) || '</div>');
    p('<p class="cx-sup-chamado__meta">' || e(pkg_suporte.fn_codigo(l_c.tp_chamado, l_c.id_chamado)) || ' · ' || e(l_assunto)
      || ' · aberto em ' || to_char(pkg_historico_carreira.fn_data_local(l_c.id_empresa, l_c.dh_abertura), 'DD/MM/YYYY')
      || '</p>');

    if l_st = pkg_suporte.c_resolvido then
      p('<p class="cx-sup-nota">Sem resposta, o chamado é encerrado em ' || to_char(l_c.dt_limite_confirmacao, 'DD/MM/YYYY') || '.</p>');
    end if;

    p('<ol class="cx-sup-linha">');
    p('<li class="cx-sup-mensagem"><span class="cx-sup-avatar" aria-hidden="true">' || e(iniciais(l_solic)) || '</span>');
    p('<div class="cx-sup-mensagem__corpo"><p class="cx-sup-mensagem__autor">' || e(nome_curto(l_solic)) || ' · '
      || to_char(pkg_historico_carreira.fn_data_local(l_c.id_empresa, l_c.dh_abertura), 'DD/MM HH24:MI') || '</p>');
    p('<p class="cx-sup-mensagem__texto">' || texto(l_c.ds_descricao) || '</p>');
    anexos_de(l_c.id_chamado, null);
    p('</div></li>');

    for r in (
      select m.id_mensagem, m.tp_autor, m.ds_texto, m.dh_envio, c.nome_completo
        from suporte_mensagem m
        left join colaborador c on c.id_colaborador = m.id_autor
       where m.id_chamado = p_id_chamado
       order by m.id_mensagem
    ) loop
      if r.tp_autor = 'SISTEMA' then
        p('<li class="cx-sup-evento">' || e(r.ds_texto) || ' '
          || to_char(pkg_historico_carreira.fn_data_local(l_c.id_empresa, r.dh_envio), 'DD/MM HH24:MI') || '</li>');
      else
        p('<li class="cx-sup-mensagem' || case when r.tp_autor = 'TI' then ' cx-sup-mensagem--ti' end || '">');
        p('<span class="cx-sup-avatar" aria-hidden="true">' || e(iniciais(r.nome_completo)) || '</span>');
        p('<div class="cx-sup-mensagem__corpo"><p class="cx-sup-mensagem__autor">' || e(nome_curto(r.nome_completo))
          || case when r.tp_autor = 'TI' then ' · TI' end || ' · '
          || to_char(pkg_historico_carreira.fn_data_local(l_c.id_empresa, r.dh_envio), 'DD/MM HH24:MI') || '</p>');
        p('<p class="cx-sup-mensagem__texto">' || texto(r.ds_texto) || '</p>');
        anexos_de(l_c.id_chamado, r.id_mensagem);
        p('</div></li>');
      end if;
    end loop;
    p('</ol></div>');
    return g_html;
  end render_conversa;

  ------------------------------------------------------------------------------
  -- Base de conhecimento (página 37)
  ------------------------------------------------------------------------------
  procedure mostra_artigo (p_empresa in number, p_id_artigo in number) is
    l_titulo  suporte_artigo.ds_titulo%type;
    l_corpo   suporte_artigo.ds_corpo%type;
    l_min     suporte_artigo.nr_min_leitura%type;
    l_assunto number;
    l_nome    suporte_assunto.nm_assunto%type;
  begin
    select t.ds_titulo, t.ds_corpo, t.nr_min_leitura, t.id_assunto, s.nm_assunto
      into l_titulo, l_corpo, l_min, l_assunto, l_nome
      from suporte_artigo t
      join suporte_assunto s on s.id_assunto = t.id_assunto
     where t.id_artigo = p_id_artigo
       and t.id_empresa = p_empresa
       and t.fl_publicado = 'S';

    p('<article class="cx-sup-card cx-sup-leitura">');
    p('<a class="cx-sup-link" href="' || a(url_assunto(l_assunto)) || '">' || icone('voltar') || e(l_nome) || '</a>');
    p('<h2 class="cx-sup-leitura__titulo">' || e(l_titulo) || '</h2>');
    p('<p class="cx-sup-chamado__meta">Leitura de ' || l_min || ' min</p>');
    p('<div class="cx-sup-leitura__corpo">' || texto(l_corpo) || '</div>');
    p('<footer class="cx-sup-leitura__rodape"><p>Não resolveu?</p>');
    p('<a class="t-Button cx-sup-botao" href="' || a(url_abrir(l_assunto)) || '">'
      || icone('mais') || '<span class="t-Button-label">Abrir chamado</span></a></footer>');
    p('</article>');
  exception
    when no_data_found then
      p('<section class="cx-sup-card cx-sup-vazio"><p>Artigo não encontrado.</p></section>');
  end mostra_artigo;

  function render_base (p_id_assunto in number default null, p_id_artigo in number default null) return clob is
    l_id      constant number := id_logado;
    l_empresa number;
    l_ultimo  number := -1;
    l_qt      pls_integer := 0;
  begin
    inicia;
    if l_id is null then
      p('<section class="cx-sup-card cx-sup-vazio"><p>Sua conta não está vinculada a um colaborador desta empresa.</p></section>');
      return g_html;
    end if;
    l_empresa := empresa_de(l_id);

    if p_id_artigo is not null then
      mostra_artigo(l_empresa, p_id_artigo);
      return g_html;
    end if;

    for r in (
      select s.id_assunto, s.nm_assunto, t.id_artigo, t.ds_titulo, t.ds_resumo, t.nr_min_leitura
        from suporte_artigo t
        join suporte_assunto s on s.id_assunto = t.id_assunto
       where t.id_empresa = l_empresa
         and t.fl_publicado = 'S'
         and (p_id_assunto is null or t.id_assunto = p_id_assunto)
       order by s.nr_ordem, s.nm_assunto, t.nr_acessos desc, t.ds_titulo
    ) loop
      if r.id_assunto <> l_ultimo then
        if l_ultimo <> -1 then
          p('</ul></section>');
        end if;
        p('<section class="cx-sup-card">');
        cabecalho_card(r.nm_assunto);
        p('<ul class="cx-sup-artigos cx-sup-artigos--resumo">');
        l_ultimo := r.id_assunto;
      end if;
      l_qt := l_qt + 1;
      p('<li><a class="cx-sup-artigo" href="' || a(url_artigo(r.id_artigo)) || '">' || icone('artigo')
        || '<span class="cx-sup-artigo__titulo">' || e(r.ds_titulo));
      if r.ds_resumo is not null then
        p('<small>' || e(r.ds_resumo) || '</small>');
      end if;
      p('</span><span class="cx-sup-artigo__tempo">' || r.nr_min_leitura || ' min</span></a></li>');
    end loop;

    if l_qt > 0 then
      p('</ul></section>');
    else
      p('<section class="cx-sup-card cx-sup-vazio"><p>Ainda não há artigos publicados sobre este assunto.</p></section>');
    end if;

    p('<section class="cx-sup-card cx-sup-leitura__rodape cx-sup-leitura__rodape--solto"><p>Não encontrou o que procurava?</p>');
    p('<a class="t-Button cx-sup-botao" href="' || a(url_abrir(p_id_assunto)) || '">'
      || icone('mais') || '<span class="t-Button-label">Abrir chamado</span></a></section>');
    return g_html;
  end render_base;

  ------------------------------------------------------------------------------
  -- Ajax Callbacks
  ------------------------------------------------------------------------------
  procedure responder_erro (p_codigo in number, p_mensagem in varchar2) is
  begin
    rollback;
    apex_debug.error('pkg_suporte_ui: %s', p_mensagem);
    apex_json.open_object;
    apex_json.write('ok', false);
    apex_json.write('mensagem',
      case when p_codigo between -20099 and -20001
           then regexp_substr(regexp_replace(p_mensagem, '^ORA-[0-9]+: *'), '^[^' || chr(10) || ']*')
           else 'Não foi possível concluir agora. Atualize a página e tente de novo.' end);
    apex_json.close_object;
  end responder_erro;

  -- Soma 3 pontos por palavra no título e 1 no resumo, nas palavras-chave ou no
  -- corpo. Vale a palavra que aparece; "não", "com" e parecidas ficam de fora.
  procedure ajax_buscar (p_termo in varchar2) is
    c_ignorar constant varchar2(200) :=
      ' nao sim com sem para por uma uns umas meu minha meus minhas que dos das nos nas esta este isso aqui como tem ';
    type t_achado is record (id number, titulo varchar2(150), minutos number, pontos number, acessos number);
    type t_achados is table of t_achado index by pls_integer;

    l_id       constant number := pkg_suporte.fn_colaborador_logado;
    l_termos   apex_t_varchar2 := apex_t_varchar2();
    l_achados  t_achados;
    l_a        t_achado;
    l_titulo   varchar2(1000);
    l_resto    varchar2(32767);
    l_pontos   number;
    l_i        pls_integer;
    l_palavra  varchar2(200);
    l_qt       pls_integer := 0;
    l_empresa  constant number := empresa_de(l_id);
  begin
    l_i := 1;
    loop
      l_palavra := regexp_substr(normaliza(substr(p_termo, 1, 200)), '[a-z0-9]+', 1, l_i);
      exit when l_palavra is null;
      if length(l_palavra) >= 3 and instr(c_ignorar, ' ' || l_palavra || ' ') = 0 then
        l_termos.extend;
        l_termos(l_termos.count) := l_palavra;
      end if;
      l_i := l_i + 1;
    end loop;

    inicia;
    if l_termos.count > 0 then
      for r in (
        select id_artigo, ds_titulo, ds_resumo, ds_palavras, ds_corpo, nr_min_leitura, nr_acessos
          from suporte_artigo
         where id_empresa = l_empresa
           and fl_publicado = 'S'
      ) loop
        l_titulo := normaliza(r.ds_titulo);
        l_resto  := normaliza(r.ds_resumo || ' ' || r.ds_palavras || ' ' || r.ds_corpo);
        l_pontos := 0;
        for t in 1 .. l_termos.count loop
          if instr(l_titulo, l_termos(t)) > 0 then
            l_pontos := l_pontos + 3;
          elsif instr(l_resto, l_termos(t)) > 0 then
            l_pontos := l_pontos + 1;
          end if;
        end loop;
        if l_pontos > 0 then
          -- Inserção ordenada: mais pontos, depois mais acessos
          l_a.id := r.id_artigo; l_a.titulo := r.ds_titulo; l_a.minutos := r.nr_min_leitura;
          l_a.pontos := l_pontos; l_a.acessos := r.nr_acessos;
          l_i := l_achados.count;
          while l_i > 0
            and (l_achados(l_i).pontos < l_pontos
                 or (l_achados(l_i).pontos = l_pontos and l_achados(l_i).acessos < r.nr_acessos)) loop
            l_achados(l_i + 1) := l_achados(l_i);
            l_i := l_i - 1;
          end loop;
          l_achados(l_i + 1) := l_a;
        end if;
      end loop;

      l_qt := least(l_achados.count, c_max_busca);
      if l_qt > 0 then
        p('<ul class="cx-sup-artigos">');
        for i in 1 .. l_qt loop
          p(linha_artigo(l_achados(i).id, l_achados(i).titulo, l_achados(i).minutos));
        end loop;
        p('</ul>');
      end if;
    end if;

    p('<p class="cx-sup-resultados__rodape">'
      || case when l_qt = 0 then 'Nenhum artigo encontrado. ' else 'Não resolveu? ' end
      || '<a class="cx-sup-link" href="' || a(url_abrir) || '">Abrir chamado</a></p>');

    apex_json.open_object;
    apex_json.write('ok', true);
    apex_json.write('html', g_html);
    apex_json.close_object;
  exception
    when others then
      responder_erro(sqlcode, sqlerrm);
  end ajax_buscar;

  procedure ajax_confirmar (p_id_chamado in number) is
  begin
    pkg_suporte.confirmar_solucao(p_id_chamado);
    apex_json.open_object;
    apex_json.write('ok', true);
    apex_json.write('mensagem', 'Chamado encerrado. Obrigado por confirmar.');
    apex_json.close_object;
  exception
    when others then
      responder_erro(sqlcode, sqlerrm);
  end ajax_confirmar;

end pkg_suporte_ui;
/
