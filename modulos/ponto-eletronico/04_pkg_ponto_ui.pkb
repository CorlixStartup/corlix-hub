--------------------------------------------------------------------------------
-- Corlix Hub · Ponto eletrônico (página 30) · 04 · HTML e callbacks · corpo
-- Os ícones são SVG Lucide em linha, como no Dashboard RH. Nomes de dia e mês
-- vêm de listas próprias: o idioma técnico da app é "en" e o NLS não ajuda.
--------------------------------------------------------------------------------
create or replace package body pkg_ponto_ui as

  -- Aviso de banco de horas: créditos que vencem nos próximos N dias
  c_dias_alerta_banco constant pls_integer := 60;
  -- Procura de marcações ausentes e faltas, em dias
  c_dias_pendencia    constant pls_integer := 30;
  c_max_pendencias    constant pls_integer := 5;
  c_max_extrato       constant pls_integer := 60;

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

  -- Colaborador informado ou o da conta logada; nulo se a conta não tem vínculo
  function id_ou_logado (p_id in number) return number is
  begin
    return nvl(p_id, pkg_ponto.fn_colaborador_logado);
  exception
    when others then
      if sqlcode = -20060 then
        return null;
      end if;
      raise;
  end id_ou_logado;

  function hoje_de (p_id_colaborador in number) return date is
    l_empresa number;
  begin
    select id_empresa into l_empresa from colaborador where id_colaborador = p_id_colaborador;
    return pkg_historico_carreira.fn_hoje(l_empresa);
  end hoje_de;

  function agora_de (p_id_colaborador in number) return date is
    l_empresa number;
  begin
    select id_empresa into l_empresa from colaborador where id_colaborador = p_id_colaborador;
    return pkg_historico_carreira.fn_data_local(l_empresa, systimestamp);
  end agora_de;

  function dia_semana (p_dt in date, p_curto in boolean default false) return varchar2 is
    l_i constant pls_integer := p_dt - trunc(p_dt, 'IW');
  begin
    if p_curto then
      return case l_i when 0 then 'seg' when 1 then 'ter' when 2 then 'qua' when 3 then 'qui'
                      when 4 then 'sex' when 5 then 'sáb' else 'dom' end;
    end if;
    return case l_i when 0 then 'Segunda-feira' when 1 then 'Terça-feira' when 2 then 'Quarta-feira'
                    when 3 then 'Quinta-feira' when 4 then 'Sexta-feira' when 5 then 'Sábado' else 'Domingo' end;
  end dia_semana;

  function mes_nome (p_dt in date) return varchar2 is
  begin
    return case to_number(to_char(p_dt, 'MM'))
      when 1 then 'janeiro' when 2 then 'fevereiro' when 3 then 'março' when 4 then 'abril'
      when 5 then 'maio' when 6 then 'junho' when 7 then 'julho' when 8 then 'agosto'
      when 9 then 'setembro' when 10 then 'outubro' when 11 then 'novembro' else 'dezembro' end;
  end mes_nome;

  -- "Segunda-feira, 26 de outubro de 2026"
  function data_extenso (p_dt in date) return varchar2 is
  begin
    return dia_semana(p_dt) || ', ' || to_char(p_dt, 'fmDD') || ' de ' || mes_nome(p_dt)
        || ' de ' || to_char(p_dt, 'YYYY');
  end data_extenso;

  -- "seg, 26/10"
  function dia_curto (p_dt in date) return varchar2 is
  begin
    return dia_semana(p_dt, true) || ', ' || to_char(p_dt, 'DD/MM');
  end dia_curto;

  -- "Outubro de 2026"
  function mes_ano (p_dt in date) return varchar2 is
    l_mes constant varchar2(20) := mes_nome(p_dt);
  begin
    return upper(substr(l_mes, 1, 1)) || substr(l_mes, 2) || ' de ' || to_char(p_dt, 'YYYY');
  end mes_ano;

  function hora (p_dh in date) return varchar2 is
  begin
    return to_char(p_dh, 'HH24:MI');
  end hora;

  function hora_ou_traco (p_dh in date) return varchar2 is
  begin
    return nvl(hora(p_dh), '—');
  end hora_ou_traco;

  -- "8h", "1h30" (sem o "00" das horas cheias)
  function duracao (p_minutos in number) return varchar2 is
  begin
    return regexp_replace(pkg_ponto.fn_horas(p_minutos), 'h00$', 'h');
  end duracao;

  function competencia (p_txt in varchar2, p_hoje in date) return date is
    l_dt constant date := to_date(p_txt || '01' default null on conversion error, 'YYYYMMDD');
  begin
    if l_dt is null or l_dt > trunc(p_hoje, 'MM') then
      return trunc(p_hoje, 'MM');
    end if;
    return l_dt;
  end competencia;

  function rotulo_marcacao (p_tipo in varchar2) return varchar2 is
  begin
    return case p_tipo
      when 'ENTRADA'   then 'Entrada'
      when 'INTERVALO' then 'Saída para intervalo'
      when 'RETORNO'   then 'Retorno do intervalo'
      when 'SAIDA'     then 'Saída'
    end;
  end rotulo_marcacao;

  function icone (p_nome in varchar2) return varchar2 is
    l_svg varchar2(1000);
  begin
    l_svg := case p_nome
      when 'log-in'     then '<path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4"/><polyline points="10 17 15 12 10 7"/><line x1="15" x2="3" y1="12" y2="12"/>'
      when 'log-out'    then '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" x2="9" y1="12" y2="12"/>'
      when 'coffee'     then '<path d="M17 8h1a4 4 0 0 1 0 8h-1"/><path d="M3 8h14v9a4 4 0 0 1-4 4H7a4 4 0 0 1-4-4Z"/><line x1="6" x2="6" y1="2" y2="4"/><line x1="10" x2="10" y1="2" y2="4"/><line x1="14" x2="14" y1="2" y2="4"/>'
      when 'check'      then '<path d="M20 6 9 17l-5-5"/>'
      when 'map-pin'    then '<path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"/><circle cx="12" cy="10" r="3"/>'
      when 'timer'      then '<line x1="10" x2="14" y1="2" y2="2"/><line x1="12" x2="15" y1="14" y2="11"/><circle cx="12" cy="14" r="8"/>'
      when 'arrow'      then '<path d="M5 12h14"/><path d="m12 5 7 7-7 7"/>'
      when 'download'   then '<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" x2="12" y1="15" y2="3"/>'
      when 'history'    then '<path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/><path d="M12 7v5l4 2"/>'
      when 'hourglass'  then '<path d="M5 22h14"/><path d="M5 2h14"/><path d="M17 22v-4.172a2 2 0 0 0-.586-1.414L12 12l-4.414 4.414A2 2 0 0 0 7 17.828V22"/><path d="M7 2v4.172a2 2 0 0 0 .586 1.414L12 12l4.414-4.414A2 2 0 0 0 17 6.172V2"/>'
      when 'alerta'     then '<path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z"/><path d="M12 9v4"/><path d="M12 17h.01"/>'
      when 'assinar'    then '<path d="M12 3H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.4 2.6a2.1 2.1 0 0 1 3 3L12 15l-4 1 1-4Z"/>'
      when 'cadeado'    then '<rect width="18" height="11" x="3" y="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/>'
    end;
    return '<svg class="cx-ponto-icone" width="18" height="18" viewBox="0 0 24 24" aria-hidden="true" focusable="false">'
        || l_svg || '</svg>';
  end icone;

  procedure cabecalho_card (p_titulo in varchar2, p_extra in varchar2 default null) is
  begin
    p('<header class="cx-ponto-card__cabecalho"><h2 class="cx-ponto-card__titulo">' || e(p_titulo) || '</h2>');
    p(p_extra);
    p('</header>');
  end cabecalho_card;

  function selo_situacao (p_dia in pkg_ponto.t_dia) return varchar2 is
    l_txt    varchar2(120);
    l_classe varchar2(20);
  begin
    case p_dia.cd_situacao
      when pkg_ponto.c_regular      then return '<span class="cx-ponto-regular">Regular</span>';
      when pkg_ponto.c_andamento    then l_txt := 'Em andamento';     l_classe := 'is-info';
      when pkg_ponto.c_sem_marcacao then l_txt := 'Sem marcação';     l_classe := 'is-neutro';
      when pkg_ponto.c_ausente      then l_txt := 'Marcação ausente'; l_classe := 'is-atencao';
      when pkg_ponto.c_analise      then l_txt := 'Ajuste em análise'; l_classe := 'is-atencao';
      when pkg_ponto.c_falta        then l_txt := 'Falta';            l_classe := 'is-erro';
      when pkg_ponto.c_abonado      then l_txt := 'Abonado';          l_classe := 'is-sucesso';
      when pkg_ponto.c_feriado      then l_txt := p_dia.nm_feriado;   l_classe := 'is-neutro';
      else return null;
    end case;
    return '<span class="cx-ponto-selo ' || l_classe || '">' || e(l_txt) || '</span>';
  end selo_situacao;

  -- Hora prevista de saída, conforme as marcações do dia
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

  ------------------------------------------------------------------------------
  -- Cabeçalho
  ------------------------------------------------------------------------------
  function render_cabecalho (p_id_colaborador in number default null) return clob is
    l_id constant number := id_ou_logado(p_id_colaborador);
  begin
    inicia;
    p('<div class="cx-cabecalho-pagina cx-cabecalho-pagina--acoes">');
    p('<div class="cx-cabecalho-pagina__texto"><h1 class="cx-cabecalho-pagina__titulo">Ponto eletrônico</h1>');
    p('<p class="cx-cabecalho-pagina__descricao">Registre suas marcações e acompanhe sua jornada, o espelho de ponto e o banco de horas.</p></div>');
    if l_id is not null then
      p('<div class="cx-cabecalho-pagina__acoes">');
      p('<button type="button" class="t-Button cx-ponto-botao" data-cx-ponto-baixar>' || icone('download')
        || '<span class="t-Button-label">Baixar espelho</span></button>');
      p('<a class="t-Button cx-ponto-botao" href="' || a(apex_page.get_url(p_page => 31, p_clear_cache => '31')) || '">'
        || icone('history') || '<span class="t-Button-label">Solicitar ajuste</span></a>');
      p('</div>');
    end if;
    p('</div>');
    return g_html;
  end render_cabecalho;

  ------------------------------------------------------------------------------
  -- Relógio e marcações de hoje
  ------------------------------------------------------------------------------
  function render_relogio (p_id_colaborador in number default null) return clob is
    l_id      constant number := id_ou_logado(p_id_colaborador);
    l_j       pkg_ponto.t_jornada;
    l_agora   date;
    l_hoje    date;
    l_dias    pkg_ponto.t_dias;
    l_dia     pkg_ponto.t_dia;
    l_proxima varchar2(10);
    l_prevista date;
    l_trab    number;
    l_correndo varchar2(1);
    l_tipos   apex_t_varchar2;
    l_valor   date;
    l_classe  varchar2(20);
    l_rotulo  varchar2(60);
    l_icone   varchar2(20);
  begin
    inicia;
    if l_id is null then
      p('<section class="cx-ponto-card cx-ponto-vazio"><p>Sua conta não está vinculada a um colaborador desta empresa. '
        || 'O ponto eletrônico fica disponível depois que o RH fizer esse vínculo.</p></section>');
      return g_html;
    end if;

    l_j       := pkg_ponto.fn_jornada(l_id);
    l_agora   := agora_de(l_id);
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

    p('<section class="cx-ponto-card cx-ponto-relogio" data-cx-ponto-relogio'
      || ' data-segundos="' || to_char((l_agora - l_hoje) * 86400, 'fm99990') || '"'
      || ' data-trabalhados="' || l_trab || '"'
      || ' data-meta="' || l_j.nr_min_diarios || '"'
      || ' data-correndo="' || l_correndo || '">');

    p('<div class="cx-ponto-relogio__topo"><div>');
    p('<p class="cx-ponto-relogio__data">' || e(data_extenso(l_hoje)) || '</p>');
    p('<p class="cx-ponto-relogio__hora" data-cx-ponto-hora>' || hora(l_agora) || '</p>');
    p('<p class="cx-ponto-relogio__local">' || icone('map-pin') || '<span>'
      || e(l_j.ds_local || case when l_j.ds_local is not null then ' · ' end || 'registro pelo navegador')
      || '</span></p></div>');

    p('<div class="cx-ponto-relogio__acao">');
    if l_proxima is null then
      p('<button type="button" class="cx-ponto-registrar" disabled>' || icone('check') || '<span>Jornada concluída</span></button>');
      p('<p class="cx-ponto-relogio__previsao">Saída registrada às ' || hora(l_dia.dh_saida) || '.</p>');
    else
      case l_proxima
        when 'ENTRADA'   then l_rotulo := 'Registrar entrada'; l_icone := 'log-in';
        when 'INTERVALO' then l_rotulo := 'Iniciar intervalo'; l_icone := 'coffee';
        when 'RETORNO'   then l_rotulo := 'Voltar do intervalo'; l_icone := 'log-in';
        else                  l_rotulo := 'Registrar saída';   l_icone := 'log-out';
      end case;
      p('<button type="button" class="cx-ponto-registrar" data-cx-ponto-registrar="' || l_proxima || '">'
        || icone(l_icone) || '<span>' || l_rotulo || '</span></button>');
      p('<p class="cx-ponto-relogio__previsao">Saída prevista às ' || hora(l_prevista)
        || ' para completar ' || duracao(l_j.nr_min_diarios) || '</p>');
    end if;
    p('</div></div>');

    -- Linha do tempo
    l_tipos := case when l_j.nr_min_intervalo = 0
                    then apex_t_varchar2('ENTRADA', 'SAIDA')
                    else apex_t_varchar2('ENTRADA', 'INTERVALO', 'RETORNO', 'SAIDA') end;
    p('<ol class="cx-ponto-linha" aria-label="Marcações de hoje">');
    for i in 1 .. l_tipos.count loop
      l_valor := case l_tipos(i)
        when 'ENTRADA'   then l_dia.dh_entrada
        when 'INTERVALO' then l_dia.dh_intervalo
        when 'RETORNO'   then l_dia.dh_retorno
        else l_dia.dh_saida
      end;
      l_classe := case when l_valor is not null then 'is-feita'
                       when l_tipos(i) = l_proxima then 'is-atual' end;
      p('<li class="cx-ponto-passo ' || l_classe || '">');
      p('<span class="cx-ponto-passo__marca">' || case when l_valor is not null then icone('check') end || '</span>');
      p('<span class="cx-ponto-passo__rotulo">' || rotulo_marcacao(l_tipos(i)) || '</span>');
      if l_valor is not null then
        p('<strong class="cx-ponto-passo__hora">' || hora(l_valor) || '</strong>');
      elsif l_tipos(i) = 'SAIDA' then
        p('<span class="cx-ponto-passo__prevista">Prevista ' || hora(l_prevista) || '</span>');
      else
        p('<span class="cx-ponto-passo__prevista">—</span>');
      end if;
      p('</li>');
    end loop;
    p('</ol>');

    p('<footer class="cx-ponto-card__rodape"><p class="cx-ponto-resumo">' || icone('timer'));
    p('<strong data-cx-ponto-trabalhadas>' || pkg_ponto.fn_horas(l_trab) || ' trabalhadas hoje</strong>');
    p('<span data-cx-ponto-faltam> · '
      || case when l_trab >= l_j.nr_min_diarios then 'jornada completa'
              else 'faltam ' || pkg_ponto.fn_horas(l_j.nr_min_diarios - l_trab) || ' para completar a jornada' end
      || '</span></p>');
    p('<button type="button" class="cx-ponto-link" data-cx-ponto-dialogo="ponto_dlg_comprovantes">Ver comprovantes'
      || icone('arrow') || '</button></footer>');
    p('</section>');
    return g_html;
  end render_relogio;

  ------------------------------------------------------------------------------
  -- Espelho de ponto
  ------------------------------------------------------------------------------
  function render_espelho (
    p_competencia    in varchar2 default null,
    p_limite         in pls_integer default 7,
    p_completo       in varchar2 default 'S',
    p_id_colaborador in number default null
  ) return clob is
    l_id     constant number := id_ou_logado(p_id_colaborador);
    l_hoje   date;
    l_mes    date;
    l_mes_i  date;
    l_dias   pkg_ponto.t_dias;
    l_j      pkg_ponto.t_jornada;
    l_saldo  number := 0;
    l_qt     pls_integer := 0;
    l_seletor varchar2(32767);
  begin
    inicia;
    if l_id is null then
      return g_html;
    end if;

    l_hoje := hoje_de(l_id);
    l_mes  := competencia(p_competencia, l_hoje);
    l_j    := pkg_ponto.fn_jornada(l_id);
    l_dias := pkg_ponto.fn_dias(l_id, l_mes, last_day(l_mes));

    p('<section class="cx-ponto-card cx-ponto-espelho">');
    if p_completo = 'S' then
      -- Meses disponíveis: do início do controle (no máximo 12) até o atual
      l_seletor := '<select class="cx-ponto-seletor" data-cx-ponto-competencia aria-label="Mês do espelho">';
      l_mes_i := trunc(l_hoje, 'MM');
      for i in 1 .. 12 loop
        exit when l_mes_i < trunc(l_j.dt_inicio_controle, 'MM');
        l_seletor := l_seletor || '<option value="' || to_char(l_mes_i, 'YYYYMM') || '"'
                  || case when l_mes_i = l_mes then ' selected' end || '>' || e(mes_ano(l_mes_i)) || '</option>';
        l_mes_i := add_months(l_mes_i, -1);
      end loop;
      cabecalho_card('Espelho de ponto', l_seletor || '</select>');
    else
      cabecalho_card(mes_ano(l_mes));
    end if;

    if l_dias.count = 0 then
      p('<p class="cx-ponto-vazio">Nenhuma marcação neste mês.</p>');
    else
      p('<div class="cx-ponto-tabela-rolagem"><table class="cx-ponto-tabela"><thead><tr>'
        || '<th scope="col">Dia</th><th scope="col">Entrada</th><th scope="col">Intervalo</th>'
        || '<th scope="col">Retorno</th><th scope="col">Saída</th>'
        || '<th scope="col" class="is-num">Trabalhadas</th><th scope="col" class="is-num">Saldo</th>'
        || '<th scope="col">Situação</th></tr></thead><tbody>');

      for i in reverse 1 .. l_dias.count loop
        l_saldo := l_saldo + nvl(l_dias(i).nr_saldo, 0);
        if p_limite is null or l_qt < p_limite then
          l_qt := l_qt + 1;
          p('<tr' || case when l_dias(i).dt = l_hoje then ' class="is-hoje"' end || '>');
          p('<th scope="row">' || e(dia_curto(l_dias(i).dt))
            || case when l_dias(i).dt = l_hoje then ' <span class="cx-ponto-hoje">Hoje</span>' end || '</th>');
          p('<td>' || hora_ou_traco(l_dias(i).dh_entrada) || '</td><td>' || hora_ou_traco(l_dias(i).dh_intervalo)
            || '</td><td>' || hora_ou_traco(l_dias(i).dh_retorno) || '</td><td>' || hora_ou_traco(l_dias(i).dh_saida) || '</td>');
          if l_dias(i).cd_situacao = pkg_ponto.c_ausente then
            p('<td class="is-num cx-ponto-apagado">Incompleto</td>');
          elsif l_dias(i).nr_trabalhados is null then
            p('<td class="is-num">—</td>');
          else
            p('<td class="is-num"><strong>' || pkg_ponto.fn_horas(l_dias(i).nr_trabalhados) || '</strong></td>');
          end if;
          p('<td class="is-num">' || case when l_dias(i).nr_saldo is null then '—' else pkg_ponto.fn_saldo(l_dias(i).nr_saldo) end || '</td>');
          p('<td>' || selo_situacao(l_dias(i)) || '</td></tr>');
        end if;
      end loop;
      p('</tbody></table></div>');
    end if;

    p('<footer class="cx-ponto-card__rodape"><p>Saldo de ' || e(mes_nome(l_mes))
      || case when l_mes = trunc(l_hoje, 'MM') then ' até hoje' end
      || ': <strong>' || pkg_ponto.fn_saldo(l_saldo) || '</strong></p>');
    if p_completo = 'S' and p_limite is not null and l_dias.count > p_limite then
      p('<button type="button" class="cx-ponto-link" data-cx-ponto-dialogo="ponto_dlg_mes">Ver mês completo'
        || icone('arrow') || '</button>');
    end if;
    p('</footer></section>');
    return g_html;
  end render_espelho;

  ------------------------------------------------------------------------------
  -- Banco de horas
  ------------------------------------------------------------------------------
  function render_banco (p_id_colaborador in number default null) return clob is
    l_id       constant number := id_ou_logado(p_id_colaborador);
    l_hoje     date;
    l_saldo    number;
    l_vencendo number;
    l_dt_venc  date;
    l_extrato  pkg_ponto.t_dias;
    l_dias_mes pkg_ponto.t_dias;
    l_mes      number := 0;
  begin
    inicia;
    if l_id is null then
      return g_html;
    end if;
    l_hoje := hoje_de(l_id);
    pkg_ponto.calcular_banco(l_id, l_saldo, l_vencendo, l_dt_venc, l_extrato);
    l_dias_mes := pkg_ponto.fn_dias(l_id, trunc(l_hoje, 'MM'), l_hoje);
    for i in 1 .. l_dias_mes.count loop
      l_mes := l_mes + nvl(l_dias_mes(i).nr_saldo, 0);
    end loop;

    p('<section class="cx-ponto-card cx-ponto-lateral">');
    cabecalho_card('Banco de horas');
    p('<div class="cx-ponto-card__corpo">');
    p('<p class="cx-ponto-rotulo">Saldo atual</p><p class="cx-ponto-saldo">' || pkg_ponto.fn_saldo(l_saldo) || '</p>');
    p('<p class="cx-ponto-par"><span>Acumulado em ' || e(mes_nome(l_hoje)) || '</span><strong>' || pkg_ponto.fn_saldo(l_mes) || '</strong></p>');
    if l_dt_venc is not null and l_dt_venc - l_hoje <= c_dias_alerta_banco then
      p('<div class="cx-ponto-aviso">' || icone('hourglass') || '<div><strong>'
        || pkg_ponto.fn_horas(l_vencendo) || ' vencem em ' || to_char(l_dt_venc, 'DD/MM/YYYY') || '</strong>'
        || '<p>Combine a compensação com a sua gestão.</p></div></div>');
    end if;
    p('<button type="button" class="cx-ponto-link" data-cx-ponto-dialogo="ponto_dlg_extrato">Ver extrato do banco de horas'
      || icone('arrow') || '</button>');
    p('</div></section>');
    return g_html;
  end render_banco;

  function render_extrato (p_id_colaborador in number default null) return clob is
    l_id       constant number := id_ou_logado(p_id_colaborador);
    l_saldo    number;
    l_vencendo number;
    l_dt_venc  date;
    l_extrato  pkg_ponto.t_dias;
    l_qt       pls_integer := 0;
  begin
    inicia;
    if l_id is null then
      return g_html;
    end if;
    pkg_ponto.calcular_banco(l_id, l_saldo, l_vencendo, l_dt_venc, l_extrato);
    if l_extrato.count = 0 then
      p('<p class="cx-ponto-vazio">Ainda não há lançamentos no banco de horas.</p>');
      return g_html;
    end if;

    p('<div class="cx-ponto-tabela-rolagem"><table class="cx-ponto-tabela"><thead><tr><th scope="col">Dia</th>'
      || '<th scope="col" class="is-num">Lançamento</th><th scope="col" class="is-num">Saldo depois</th></tr></thead><tbody>');
    for i in reverse 1 .. l_extrato.count loop
      exit when l_qt >= c_max_extrato;
      l_qt := l_qt + 1;
      p('<tr><th scope="row">' || e(dia_curto(l_extrato(i).dt)) || '/' || to_char(l_extrato(i).dt, 'YYYY') || '</th>'
        || '<td class="is-num">' || pkg_ponto.fn_saldo(l_extrato(i).nr_saldo) || '</td>'
        || '<td class="is-num"><strong>' || pkg_ponto.fn_saldo(l_extrato(i).nr_saldo_banco) || '</strong></td></tr>');
    end loop;
    p('</tbody></table></div>');
    p('<p class="cx-ponto-nota">Crédito vence ao fim do mês, ' || pkg_ponto.fn_jornada(l_id).nr_meses_validade
      || ' meses depois do dia em que entrou. Horas vencidas saem do saldo e são tratadas com o RH.</p>');
    return g_html;
  end render_extrato;

  ------------------------------------------------------------------------------
  -- Pendências
  ------------------------------------------------------------------------------
  function render_pendencias (p_id_colaborador in number default null) return clob is
    l_id      constant number := id_ou_logado(p_id_colaborador);
    l_hoje    date;
    l_dias    pkg_ponto.t_dias;
    l_mes     date;
    l_total   pls_integer := 0;
    l_qt      pls_integer := 0;
    l_faltante varchar2(10);
    l_url     varchar2(4000);
    l_detalhe varchar2(200);
  begin
    inicia;
    if l_id is null then
      return g_html;
    end if;
    l_hoje := hoje_de(l_id);
    l_dias := pkg_ponto.fn_dias(l_id, l_hoje - c_dias_pendencia, l_hoje - 1);
    l_mes  := pkg_ponto.fn_competencia_a_assinar(l_id);

    for i in 1 .. l_dias.count loop
      if l_dias(i).cd_situacao in (pkg_ponto.c_ausente, pkg_ponto.c_falta) then
        l_total := l_total + 1;
      end if;
    end loop;
    if l_mes is not null then
      l_total := l_total + 1;
    end if;

    p('<section class="cx-ponto-card cx-ponto-lateral">');
    cabecalho_card('Pendências',
      case when l_total > 0 then '<span class="cx-ponto-selo is-atencao">' || l_total || ' para resolver</span>' end);

    if l_total = 0 then
      p('<p class="cx-ponto-vazio">Nada para resolver.</p></section>');
      return g_html;
    end if;

    p('<ul class="cx-ponto-pendencias">');
    for i in reverse 1 .. l_dias.count loop
      if l_dias(i).cd_situacao in (pkg_ponto.c_ausente, pkg_ponto.c_falta) and l_qt < c_max_pendencias then
        l_qt := l_qt + 1;
        if l_dias(i).cd_situacao = pkg_ponto.c_falta then
          l_detalhe := 'nenhuma marcação no dia.';
          l_url := apex_page.get_url(p_page => 31, p_clear_cache => '31',
                     p_items  => 'P31_DT_REFERENCIA,P31_TP_AJUSTE',
                     p_values => to_char(l_dias(i).dt, 'DD/MM/YYYY') || ',ABONO');
        else
          l_faltante := case when l_dias(i).dh_entrada is null then 'ENTRADA'
                             when l_dias(i).dh_intervalo is null then 'INTERVALO'
                             when l_dias(i).dh_retorno is null then 'RETORNO'
                             else 'SAIDA' end;
          l_detalhe := case l_faltante
                         when 'ENTRADA'   then 'a entrada não foi registrada.'
                         when 'INTERVALO' then 'a saída para o intervalo não foi registrada.'
                         when 'RETORNO'   then 'o retorno do intervalo não foi registrado.'
                         else 'a saída não foi registrada.' end;
          l_url := apex_page.get_url(p_page => 31, p_clear_cache => '31',
                     p_items  => 'P31_DT_REFERENCIA,P31_TP_AJUSTE,P31_TP_MARCACAO',
                     p_values => to_char(l_dias(i).dt, 'DD/MM/YYYY') || ',MARCACAO,' || l_faltante);
        end if;
        p('<li class="cx-ponto-pendencia">' || icone('alerta') || '<div>');
        p('<strong>' || case when l_dias(i).cd_situacao = pkg_ponto.c_falta then 'Dia sem marcação' else 'Marcação ausente' end || '</strong>');
        p('<p>' || e(dia_curto(l_dias(i).dt)) || ' · ' || l_detalhe || '</p>');
        p('<a class="t-Button cx-ponto-botao" href="' || a(l_url) || '">Justificar</a></div></li>');
      end if;
    end loop;

    if l_mes is not null then
      p('<li class="cx-ponto-pendencia">' || icone('assinar') || '<div>');
      p('<strong>Espelho de ' || e(mes_nome(l_mes)) || '</strong>');
      p('<p>Confira e assine até ' || to_char(pkg_ponto.fn_prazo_assinatura(l_mes), 'DD/MM/YYYY') || '.</p>');
      p('<button type="button" class="t-Button cx-ponto-botao" data-cx-ponto-dialogo="ponto_dlg_assinatura">Revisar e assinar</button></div></li>');
    end if;
    p('</ul></section>');
    return g_html;
  end render_pendencias;

  function render_assinatura (p_id_colaborador in number default null) return clob is
    l_id  constant number := id_ou_logado(p_id_colaborador);
    l_mes date;
  begin
    inicia;
    if l_id is null then
      return g_html;
    end if;
    l_mes := pkg_ponto.fn_competencia_a_assinar(l_id);
    if l_mes is null then
      p('<p class="cx-ponto-vazio">Nenhum espelho aguardando assinatura.</p>');
      return g_html;
    end if;

    -- render_espelho recomeça g_html; o botão entra depois dele
    g_html := render_espelho(to_char(l_mes, 'YYYYMM'), null, 'N', l_id);
    p('<div class="cx-ponto-assinar"><button type="button" class="t-Button t-Button--hot" data-cx-ponto-assinar="'
      || to_char(l_mes, 'YYYYMM') || '">Assinar espelho de ' || e(mes_nome(l_mes)) || '</button></div>');
    return g_html;
  end render_assinatura;

  ------------------------------------------------------------------------------
  -- Sua jornada
  ------------------------------------------------------------------------------
  function render_jornada (p_id_colaborador in number default null) return clob is
    l_id     constant number := id_ou_logado(p_id_colaborador);
    l_j      pkg_ponto.t_jornada;
    l_gestor varchar2(200);

    procedure par (p_rotulo in varchar2, p_valor in varchar2) is
    begin
      p('<div class="cx-ponto-par"><dt>' || e(p_rotulo) || '</dt><dd>' || e(p_valor) || '</dd></div>');
    end par;

    function hhmi (p_minutos in number) return varchar2 is
    begin
      return to_char(trunc(p_minutos / 60), 'fm00') || ':' || to_char(mod(p_minutos, 60), 'fm00');
    end hhmi;
  begin
    inicia;
    if l_id is null then
      return g_html;
    end if;
    l_j := pkg_ponto.fn_jornada(l_id);

    select max(g.nome_completo)
      into l_gestor
      from colaborador c
      left join colaborador g on g.id_colaborador = c.id_gestor
     where c.id_colaborador = l_id;

    p('<section class="cx-ponto-card cx-ponto-lateral">');
    cabecalho_card('Sua jornada');
    p('<div class="cx-ponto-card__corpo"><dl class="cx-ponto-pares">');
    par('Horário', 'Seg a sex, ' || hhmi(l_j.nr_min_entrada) || ' às ' || hhmi(l_j.nr_min_saida));
    par('Intervalo', case when l_j.nr_min_intervalo = 0 then 'Sem intervalo' else duracao(l_j.nr_min_intervalo) || ' por dia' end);
    par('Carga semanal', duracao(l_j.nr_min_semanais));
    par('Tolerância', 'Até ' || l_j.nr_min_tolerancia || ' min por dia');
    par('Aprova ajustes', nvl(l_gestor, 'RH'));
    p('</dl><p class="cx-ponto-nota">' || icone('cadeado')
      || '<span>Suas marcações são visíveis para você, sua gestão e o RH.</span></p></div></section>');
    return g_html;
  end render_jornada;

  ------------------------------------------------------------------------------
  -- Comprovantes
  ------------------------------------------------------------------------------
  function render_comprovantes (p_id_colaborador in number default null) return clob is
    l_id constant number := id_ou_logado(p_id_colaborador);
    l_qt pls_integer := 0;
  begin
    inicia;
    if l_id is null then
      return g_html;
    end if;

    for r in (select id_marcacao, dt_referencia, dh_marcacao, tp_marcacao, ds_origem
                from ponto_marcacao
               where id_colaborador = l_id
               order by id_marcacao desc
               fetch first 60 rows only) loop
      if l_qt = 0 then
        p('<div class="cx-ponto-tabela-rolagem"><table class="cx-ponto-tabela"><thead><tr><th scope="col">Comprovante</th>'
          || '<th scope="col">Data e hora</th><th scope="col">Marcação</th><th scope="col">Origem</th></tr></thead><tbody>');
      end if;
      l_qt := l_qt + 1;
      p('<tr><th scope="row">Nº ' || r.id_marcacao || '</th><td>' || to_char(r.dh_marcacao, 'DD/MM/YYYY HH24:MI')
        || '</td><td>' || rotulo_marcacao(r.tp_marcacao) || '</td><td>'
        || case r.ds_origem when 'AJUSTE' then 'Ajuste aprovado'
                            when 'DEMO' then 'Demonstração'
                            else 'Navegador' end || '</td></tr>');
    end loop;

    if l_qt = 0 then
      p('<p class="cx-ponto-vazio">Nenhuma marcação registrada ainda.</p>');
    else
      p('</tbody></table></div>');
    end if;
    return g_html;
  end render_comprovantes;

  ------------------------------------------------------------------------------
  -- Ajax Callbacks
  ------------------------------------------------------------------------------
  procedure responder_erro (p_codigo in number, p_mensagem in varchar2) is
  begin
    rollback;
    apex_debug.error('pkg_ponto_ui: %s', p_mensagem);
    apex_json.open_object;
    apex_json.write('ok', false);
    apex_json.write('mensagem',
      case when p_codigo between -20099 and -20001
           then regexp_substr(regexp_replace(p_mensagem, '^ORA-[0-9]+: *'), '^[^' || chr(10) || ']*')
           else 'Não foi possível concluir agora. Atualize a página e tente de novo.' end);
    apex_json.close_object;
  end responder_erro;

  procedure ajax_registrar (p_tp_marcacao in varchar2) is
    l_id number;
  begin
    l_id := pkg_ponto.registrar_marcacao(p_tp_marcacao);
    apex_json.open_object;
    apex_json.write('ok', true);
    apex_json.write('mensagem', rotulo_marcacao(p_tp_marcacao) || ' registrada. Comprovante nº ' || l_id || '.');
    apex_json.close_object;
  exception
    when others then
      responder_erro(sqlcode, sqlerrm);
  end ajax_registrar;

  procedure ajax_assinar (p_competencia in varchar2) is
  begin
    pkg_ponto.assinar_espelho(p_competencia);
    apex_json.open_object;
    apex_json.write('ok', true);
    apex_json.write('mensagem', 'Espelho assinado.');
    apex_json.close_object;
  exception
    when others then
      responder_erro(sqlcode, sqlerrm);
  end ajax_assinar;

  procedure ajax_baixar_espelho (p_competencia in varchar2) is
    l_id    number;
    l_hoje  date;
    l_mes   date;
    l_dias  pkg_ponto.t_dias;
    l_csv   varchar2(32767);
    l_saldo number := 0;
    l_sit   varchar2(100);
    c_nl    constant varchar2(2) := chr(13) || chr(10);
  begin
    l_id   := pkg_ponto.fn_colaborador_logado;
    l_hoje := hoje_de(l_id);
    l_mes  := competencia(p_competencia, l_hoje);
    l_dias := pkg_ponto.fn_dias(l_id, l_mes, last_day(l_mes));

    l_csv := 'Dia;Entrada;Intervalo;Retorno;Saída;Trabalhadas;Saldo;Situação' || c_nl;
    for i in 1 .. l_dias.count loop
      l_sit := case l_dias(i).cd_situacao
        when pkg_ponto.c_regular      then 'Regular'
        when pkg_ponto.c_andamento    then 'Em andamento'
        when pkg_ponto.c_sem_marcacao then 'Sem marcação'
        when pkg_ponto.c_ausente      then 'Marcação ausente'
        when pkg_ponto.c_analise      then 'Ajuste em análise'
        when pkg_ponto.c_falta        then 'Falta'
        when pkg_ponto.c_abonado      then 'Abonado'
        when pkg_ponto.c_feriado      then replace(l_dias(i).nm_feriado, ';', ',')
      end;
      l_saldo := l_saldo + nvl(l_dias(i).nr_saldo, 0);
      l_csv := l_csv || to_char(l_dias(i).dt, 'DD/MM/YYYY') || ';' || hora(l_dias(i).dh_entrada) || ';'
            || hora(l_dias(i).dh_intervalo) || ';' || hora(l_dias(i).dh_retorno) || ';' || hora(l_dias(i).dh_saida) || ';'
            || case when l_dias(i).nr_trabalhados is not null then pkg_ponto.fn_horas(l_dias(i).nr_trabalhados) end || ';'
            || case when l_dias(i).nr_saldo is not null then pkg_ponto.fn_saldo(l_dias(i).nr_saldo) end || ';'
            || l_sit || c_nl;
    end loop;
    l_csv := l_csv || 'Saldo do mês;;;;;;' || pkg_ponto.fn_saldo(l_saldo) || ';' || c_nl;

    apex_json.open_object;
    apex_json.write('ok', true);
    apex_json.write('nome', 'espelho-ponto-' || to_char(l_mes, 'YYYY-MM') || '.csv');
    apex_json.write('conteudo', l_csv);
    apex_json.close_object;
  exception
    when others then
      responder_erro(sqlcode, sqlerrm);
  end ajax_baixar_espelho;

end pkg_ponto_ui;
/
