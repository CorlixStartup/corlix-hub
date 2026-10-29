--------------------------------------------------------------------------------
-- Corlix Hub · Dashboard RH (página 20) · corpo
-- Cada função devolve um card completo (classes cx-dash-*, dashboard-rh.css).
-- Os ícones são SVG Lucide em linha: o app só mapeia para Lucide parte das
-- classes Font APEX, e trending-up / user-minus não estão no mapa.
-- O gráfico de turnover é HTML/CSS (não JET) para poder cortar a barra fora de
-- escala, como no protótipo; os mesmos números saem numa tabela ("Ver em tabela").
--------------------------------------------------------------------------------
create or replace package body pkg_dashboard_rh_ui as

  c_nls_data   constant varchar2(60) := 'NLS_DATE_LANGUAGE=''BRAZILIAN PORTUGUESE''';
  c_nls_numero constant varchar2(60) := 'NLS_NUMERIC_CHARACTERS='',.''';
  -- Barra "fora de escala": maior valor > c_fator_corte x o segundo maior
  c_fator_corte constant pls_integer := 4;
  -- Janela das formações a vencer (mesma regra da versão anterior da página)
  c_dias_formacao constant pls_integer := 60;

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

  function data_txt (p_txt in varchar2) return date is
  begin
    return to_date(p_txt default null on conversion error, 'DD/MM/YYYY');
  end data_txt;

  -- "1.234"
  function numero (p_valor in number) return varchar2 is
  begin
    return to_char(p_valor, 'fm999G999G990', c_nls_numero);
  end numero;

  -- "1,5"
  function decimal1 (p_valor in number) return varchar2 is
  begin
    return to_char(round(p_valor, 1), 'fm999G990D0', c_nls_numero);
  end decimal1;

  -- Porcentagem para variáveis CSS (ponto decimal, nunca vírgula)
  function pct (p_parte in number, p_todo in number) return varchar2 is
  begin
    if nvl(p_todo, 0) = 0 then
      return '0%';
    end if;
    return to_char(round(least(p_parte, p_todo) / p_todo * 100, 2), 'fm990D00', 'NLS_NUMERIC_CHARACTERS=''.,''') || '%';
  end pct;

  -- "nov/25"
  function mes_curto (p_data in date) return varchar2 is
  begin
    return to_char(p_data, 'mon', c_nls_data) || '/' || to_char(p_data, 'yy');
  end mes_curto;

  -- "jun/2026"
  function mes_ano (p_data in date) return varchar2 is
  begin
    return to_char(p_data, 'mon', c_nls_data) || '/' || to_char(p_data, 'yyyy');
  end mes_ano;

  function plural (p_qt in number, p_singular in varchar2, p_plural in varchar2) return varchar2 is
  begin
    return numero(p_qt) || ' ' || case when abs(p_qt) = 1 then p_singular else p_plural end;
  end plural;

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

  -- Ícones Lucide (traço 2, viewBox 24)
  function icone (p_nome in varchar2) return varchar2 is
    l_svg varchar2(1000);
  begin
    l_svg := case p_nome
      when 'trending-up' then
        '<polyline points="22 7 13.5 15.5 8.5 10.5 2 17"/><polyline points="16 7 22 7 22 13"/>'
      when 'user-plus' then
        '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/>'
        || '<line x1="19" x2="19" y1="8" y2="14"/><line x1="22" x2="16" y1="11" y2="11"/>'
      when 'user-minus' then
        '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/>'
        || '<line x1="22" x2="16" y1="11" y2="11"/>'
      when 'chevron-right' then '<path d="m9 18 6-6-6-6"/>'
      when 'arrow-right'   then '<path d="M5 12h14"/><path d="m12 5 7 7-7 7"/>'
      when 'info'          then '<circle cx="12" cy="12" r="10"/><path d="M12 16v-4"/><path d="M12 8h.01"/>'
    end;
    return '<svg class="cx-dash-icone" width="18" height="18" viewBox="0 0 24 24" aria-hidden="true" focusable="false">'
        || l_svg || '</svg>';
  end icone;

  function tipo_formacao (p_tipo in varchar2) return varchar2 is
  begin
    return case p_tipo
      when 'GRADUACAO'    then 'Graduação'
      when 'POS'          then 'Pós-graduação'
      when 'MBA'          then 'MBA'
      when 'CURSO'        then 'Curso'
      when 'CERTIFICACAO' then 'Certificação'
      when 'IDIOMA'       then 'Idioma'
      else initcap(p_tipo)
    end;
  end tipo_formacao;

  -- "5 meses", "1 mês", "3,2 anos", "2 anos"
  function tempo_no_cargo (p_meses in number) return varchar2 is
    l_meses pls_integer;
    l_anos  number;
  begin
    if p_meses is null then
      return null;
    elsif p_meses < 1 then
      return 'menos de 1 mês';
    end if;
    l_meses := round(p_meses);
    if l_meses < 12 then
      return plural(l_meses, 'mês', 'meses');
    end if;
    l_anos := round(p_meses / 12, 1);
    if l_anos = trunc(l_anos) then
      return plural(l_anos, 'ano', 'anos');
    end if;
    return decimal1(l_anos) || ' anos';
  end tempo_no_cargo;

  -- Passo "bonito" do eixo (1, 2, 5, 10, 20...) para ~4 divisões; só inteiros
  function passo_eixo (p_ref in number) return number is
    l_bruto number := greatest(p_ref / 4, 1);
    l_pot   number := power(10, floor(log(10, l_bruto)));
    l_frac  number := l_bruto / l_pot;
  begin
    return case when l_frac <= 1 then 1 when l_frac <= 2 then 2 when l_frac <= 5 then 5 else 10 end * l_pot;
  end passo_eixo;

  -- Cabeçalho de card: título, selo opcional e subtítulo
  procedure cabecalho (
    p_titulo    in varchar2,
    p_subtitulo in varchar2 default null,
    p_selo      in varchar2 default null
  ) is
  begin
    p('<header class="cx-dash-card__cabecalho"><div class="cx-dash-card__linha">');
    p('<h2 class="cx-dash-card__titulo">' || e(p_titulo) || '</h2>');
    if p_selo is not null then
      p('<span class="cx-dash-selo">' || e(p_selo) || '</span>');
    end if;
    p('</div>');
    if p_subtitulo is not null then
      p('<p class="cx-dash-card__subtitulo">' || e(p_subtitulo) || '</p>');
    end if;
    p('</header>');
  end cabecalho;

  procedure estado_vazio (p_titulo in varchar2, p_texto in varchar2 default null) is
  begin
    p('<div class="cx-dash-vazio"><strong>' || e(p_titulo) || '</strong>');
    if p_texto is not null then
      p('<p>' || e(p_texto) || '</p>');
    end if;
    p('</div>');
  end estado_vazio;

  -- Rodapé "Ver todas ... →" que abre um Inline Dialog (JS da página)
  procedure rodape_dialogo (p_texto in varchar2, p_id_dialogo in varchar2) is
  begin
    p('<div class="cx-dash-card__rodape"><button type="button" class="cx-dash-link" data-cx-dash-dialogo="'
      || a(p_id_dialogo) || '">' || e(p_texto) || icone('arrow-right') || '</button></div>');
  end rodape_dialogo;

  -- Valida empresa e período. Devolve a mensagem de erro (ou nulo se ok).
  function problema_periodo (
    p_id_empresa in number,
    p_ini        in date,
    p_fim        in date
  ) return varchar2 is
  begin
    if p_id_empresa is null then
      return 'Empresa não identificada na sessão. Saia e entre de novo.';
    elsif p_ini is null or p_fim is null then
      return 'Informe as datas De e Até no formato DD/MM/AAAA.';
    elsif p_ini > p_fim then
      return 'A data De precisa ser anterior ou igual à data Até.';
    end if;
    return null;
  end problema_periodo;

  procedure aviso (p_texto in varchar2) is
  begin
    p('<p class="cx-dash-aviso" role="status">' || icone('info') || '<span>' || e(p_texto) || '</span></p>');
  end aviso;

  ------------------------------------------------------------------------------
  -- Indicadores
  ------------------------------------------------------------------------------
  procedure kpi (
    p_icone   in varchar2,
    p_rotulo  in varchar2,
    p_valor   in number,
    p_detalhe in varchar2,
    p_destino in varchar2
  ) is
  begin
    p('<a class="cx-dash-kpi" href="#' || a(p_destino) || '">');
    p('<span class="cx-dash-kpi__topo"><span class="cx-dash-kpi__rotulo">' || icone(p_icone)
      || e(p_rotulo) || '</span>' || icone('chevron-right') || '</span>');
    p('<strong class="cx-dash-kpi__valor">' || numero(p_valor) || '</strong>');
    p('<span class="cx-dash-kpi__detalhe">' || p_detalhe || '</span>');
    p('</a>');
  end kpi;

  function render_indicadores (
    p_dt_inicio  in varchar2,
    p_dt_fim     in varchar2,
    p_id_empresa in number default to_number(v('G_ID_EMPRESA') default null on conversion error)
  ) return clob is
    l_ini          date := data_txt(p_dt_inicio);
    l_fim          date := data_txt(p_dt_fim);
    l_problema     varchar2(200) := problema_periodo(p_id_empresa, l_ini, l_fim);
    l_promocoes    pls_integer;
    l_deptos_promo pls_integer;
    l_deptos       pls_integer;
    l_admissoes    pls_integer;
    l_desligam     pls_integer;
    l_meses_adm    pls_integer;
    l_pico_mes     date;
    l_pico_qt      pls_integer;
    l_saldo        pls_integer;
    l_detalhe      varchar2(400);
  begin
    inicia;
    if l_problema is not null then
      aviso(l_problema);
      return g_html;
    end if;

    select count(case when v.cd_tipo = 'PROMOCAO'     then 1 end),
           count(distinct case when v.cd_tipo = 'PROMOCAO' then v.id_departamento_novo end),
           count(case when v.cd_tipo = 'ADMISSAO'     then 1 end),
           count(case when v.cd_tipo = 'DESLIGAMENTO' then 1 end),
           count(distinct case when v.cd_tipo = 'ADMISSAO' then trunc(v.dt_efetiva, 'mm') end)
      into l_promocoes, l_deptos_promo, l_admissoes, l_desligam, l_meses_adm
      from vw_movimentacao_valida v
     where v.id_empresa  = p_id_empresa
       and v.cd_tipo    in ('PROMOCAO', 'ADMISSAO', 'DESLIGAMENTO')
       and v.dt_efetiva >= l_ini
       and v.dt_efetiva <  l_fim + 1;

    select count(*) into l_deptos from departamento d where d.id_empresa = p_id_empresa;

    p('<div class="cx-dash-kpis">');

    -- Promoções: "Em 4 de 6 departamentos"
    l_detalhe := case
      when l_promocoes = 0 then 'Nenhuma no período'
      when l_deptos > 0    then 'Em ' || numero(l_deptos_promo) || ' de ' || plural(l_deptos, 'departamento', 'departamentos')
      else 'Em ' || plural(l_deptos_promo, 'departamento', 'departamentos')
    end;
    kpi('trending-up', 'Promoções', l_promocoes, e(l_detalhe), 'cx-dash-departamentos');

    -- Admissões: o mês de pico quando ele concentra metade ou mais; senão, a média mensal
    if l_admissoes = 0 then
      l_detalhe := 'Nenhuma no período';
    else
      select mes, qt
        into l_pico_mes, l_pico_qt
        from (select trunc(v.dt_efetiva, 'mm') as mes, count(*) as qt
                from vw_movimentacao_valida v
               where v.id_empresa  = p_id_empresa
                 and v.cd_tipo     = 'ADMISSAO'
                 and v.dt_efetiva >= l_ini
                 and v.dt_efetiva <  l_fim + 1
               group by trunc(v.dt_efetiva, 'mm')
               order by qt desc, mes)
       fetch first 1 row only;

      if l_meses_adm > 1 and l_pico_qt * 2 >= l_admissoes then
        l_detalhe := numero(l_pico_qt) || case when l_pico_qt = 1 then ' dela' else ' delas' end
                  || ' em ' || mes_ano(l_pico_mes);
      else
        l_detalhe := 'Média de ' || decimal1(l_admissoes / (months_between(trunc(l_fim, 'mm'), trunc(l_ini, 'mm')) + 1))
                  || ' por mês';
      end if;
    end if;
    kpi('user-plus', 'Admissões', l_admissoes, e(l_detalhe), 'cx-dash-turnover');

    -- Desligamentos: saldo do período (admissões - desligamentos)
    l_saldo := l_admissoes - l_desligam;
    kpi('user-minus', 'Desligamentos', l_desligam,
        'Saldo no período: '
        || case when l_saldo > 0 then '+' when l_saldo < 0 then '&minus;' end
        || e(case when l_saldo = 0 then '0' else plural(abs(l_saldo), 'pessoa', 'pessoas') end),
        'cx-dash-turnover');

    p('</div>');
    return g_html;
  end render_indicadores;

  ------------------------------------------------------------------------------
  -- Turnover
  ------------------------------------------------------------------------------
  function render_turnover (
    p_dt_inicio  in varchar2,
    p_dt_fim     in varchar2,
    p_id_empresa in number default to_number(v('G_ID_EMPRESA') default null on conversion error)
  ) return clob is
    type t_mes is record (mes date, admissoes pls_integer, desligamentos pls_integer);
    type t_meses is table of t_mes index by pls_integer;

    l_ini      date := data_txt(p_dt_inicio);
    l_fim      date := data_txt(p_dt_fim);
    l_problema varchar2(200) := problema_periodo(p_id_empresa, l_ini, l_fim);
    l_meses    t_meses;
    l_v1       pls_integer := 0;  -- maior valor
    l_qt_v1    pls_integer := 0;  -- quantas barras têm o maior valor
    l_v2       pls_integer := 0;  -- segundo maior valor
    l_cortar   boolean;
    l_ref      number;
    l_passo    number;
    l_topo     number;
    l_total_a  pls_integer := 0;
    l_total_d  pls_integer := 0;
    l_nota     varchar2(400);

    procedure considera (p_valor in pls_integer) is
    begin
      if p_valor > l_v1 then
        l_v2 := l_v1; l_v1 := p_valor; l_qt_v1 := 1;
      elsif p_valor = l_v1 then
        l_qt_v1 := l_qt_v1 + 1;
      elsif p_valor > l_v2 then
        l_v2 := p_valor;
      end if;
    end considera;

    procedure barra (p_valor in pls_integer, p_serie in varchar2, p_rotulo in varchar2, p_mes in date) is
    begin
      if p_valor = 0 then
        return;
      end if;
      p('<span class="cx-dash-barra cx-dash-serie--' || p_serie
        || case when p_valor > l_topo then ' is-cortada' end
        || '" style="--h:' || pct(p_valor, l_topo) || '" title="'
        || a(mes_ano(p_mes) || ': ' || numero(p_valor) || ' ' || p_rotulo) || '">');
      if p_valor > l_topo then
        p('<span class="cx-dash-barra__valor">' || numero(p_valor) || '</span>');
        l_nota := initcap(mes_ano(p_mes)) || ' está fora de escala (' || numero(p_valor) || ' ' || p_rotulo
               || ' no mês). A barra foi cortada para manter legíveis os demais meses.';
      end if;
      p('</span>');
    end barra;
  begin
    inicia;
    p('<section class="cx-dash-card cx-dash-turnover" id="cx-dash-turnover" aria-labelledby="cx-dash-turnover-titulo">');

    if l_problema is not null then
      p('<header class="cx-dash-card__cabecalho"><h2 class="cx-dash-card__titulo" id="cx-dash-turnover-titulo">'
        || 'Turnover: admissões x desligamentos</h2></header>');
      aviso(l_problema);
      p('</section>');
      return g_html;
    end if;

    with meses as (
      select add_months(trunc(l_ini, 'mm'), level - 1) as mes
        from dual
     connect by level <= months_between(trunc(l_fim, 'mm'), trunc(l_ini, 'mm')) + 1
    )
    select m.mes,
           count(case when v.cd_tipo = 'ADMISSAO'     then 1 end),
           count(case when v.cd_tipo = 'DESLIGAMENTO' then 1 end)
      bulk collect into l_meses
      from meses m
      left join vw_movimentacao_valida v
             on v.id_empresa  = p_id_empresa
            and v.cd_tipo    in ('ADMISSAO', 'DESLIGAMENTO')
            and v.dt_efetiva >= greatest(m.mes, l_ini)
            and v.dt_efetiva <  least(add_months(m.mes, 1), l_fim + 1)
     group by m.mes
     order by m.mes;

    for i in 1 .. l_meses.count loop
      considera(l_meses(i).admissoes);
      considera(l_meses(i).desligamentos);
      l_total_a := l_total_a + l_meses(i).admissoes;
      l_total_d := l_total_d + l_meses(i).desligamentos;
    end loop;
    if l_qt_v1 > 1 then
      l_v2 := l_v1;
    end if;

    -- Cabeçalho: título, legenda e alternância gráfico/tabela
    p('<header class="cx-dash-card__cabecalho">');
    p('<div class="cx-dash-card__linha">');
    p('<h2 class="cx-dash-card__titulo" id="cx-dash-turnover-titulo">Turnover: admissões x desligamentos</h2>');
    if l_v1 > 0 then
      p('<div class="cx-dash-turnover__acoes">');
      p('<ul class="cx-dash-legenda" aria-hidden="true">'
        || '<li><span class="cx-dash-legenda__cor cx-dash-serie--adm"></span>Admissões</li>'
        || '<li><span class="cx-dash-legenda__cor cx-dash-serie--desl"></span>Desligamentos</li></ul>');
      p('<button type="button" class="cx-dash-link" data-cx-dash-alternar aria-pressed="false">Ver em tabela</button>');
      p('</div>');
    end if;
    p('</div>');
    p('<p class="cx-dash-card__subtitulo">Pessoas por mês de movimentação, de '
      || e(mes_ano(l_ini)) || ' a ' || e(mes_ano(l_fim)) || '.</p>');
    p('</header>');

    if l_v1 = 0 then
      estado_vazio('Nenhuma admissão ou desligamento no período.', 'Mude as datas De e Até para ver outro intervalo.');
      p('</section>');
      return g_html;
    end if;

    -- Escala: com uma barra muito acima das outras, o eixo segue o segundo maior valor
    l_cortar := l_v2 > 0 and l_v1 > c_fator_corte * l_v2;
    l_ref    := case when l_cortar then l_v2 else l_v1 end;
    l_passo  := passo_eixo(l_ref);
    l_topo   := ceil(l_ref / l_passo) * l_passo;
    if l_cortar and l_topo <= l_ref then
      l_topo := l_topo + l_passo;  -- folga para a barra cortada passar das demais
    end if;

    -- Gráfico (o leitor de tela usa a tabela)
    p('<div class="cx-dash-grafico" data-cx-dash-grafico aria-hidden="true">');
    p('<div class="cx-dash-grafico__eixo">');
    for t in 0 .. round(l_topo / l_passo) loop
      p('<span style="--y:' || pct(t * l_passo, l_topo) || '">' || numero(t * l_passo) || '</span>');
    end loop;
    p('</div>');
    p('<div class="cx-dash-grafico__area">');
    for t in 0 .. round(l_topo / l_passo) loop
      p('<span class="cx-dash-grafico__guia" style="--y:' || pct(t * l_passo, l_topo) || '"></span>');
    end loop;
    p('<ol class="cx-dash-grafico__meses' || case when l_meses.count > 12 then ' is-denso' end || '">');
    for i in 1 .. l_meses.count loop
      p('<li class="cx-dash-grafico__mes'
        || case when greatest(l_meses(i).admissoes, l_meses(i).desligamentos) > l_topo then ' is-destaque' end
        || '"><div class="cx-dash-grafico__barras">');
      barra(l_meses(i).admissoes,     'adm',  case when l_meses(i).admissoes = 1 then 'admissão' else 'admissões' end, l_meses(i).mes);
      barra(l_meses(i).desligamentos, 'desl', case when l_meses(i).desligamentos = 1 then 'desligamento' else 'desligamentos' end, l_meses(i).mes);
      p('</div><span class="cx-dash-grafico__rotulo">' || e(mes_curto(l_meses(i).mes)) || '</span></li>');
    end loop;
    p('</ol></div></div>');

    if l_nota is not null then
      p('<p class="cx-dash-nota" data-cx-dash-grafico>' || icone('info') || '<span>' || e(l_nota) || '</span></p>');
    end if;

    -- Tabela (escondida até clicar em "Ver em tabela")
    p('<div class="cx-dash-turnover__tabela" data-cx-dash-tabela hidden>');
    p('<table class="cx-dash-tabela"><caption class="u-VisuallyHidden">Admissões e desligamentos por mês, de '
      || e(mes_ano(l_ini)) || ' a ' || e(mes_ano(l_fim)) || '</caption>');
    p('<thead><tr><th scope="col">Mês</th><th scope="col" class="cx-dash-num">Admissões</th>'
      || '<th scope="col" class="cx-dash-num">Desligamentos</th><th scope="col" class="cx-dash-num">Saldo</th></tr></thead><tbody>');
    for i in 1 .. l_meses.count loop
      p('<tr><th scope="row">' || e(mes_ano(l_meses(i).mes)) || '</th>'
        || '<td class="cx-dash-num">' || numero(l_meses(i).admissoes) || '</td>'
        || '<td class="cx-dash-num">' || numero(l_meses(i).desligamentos) || '</td>'
        || '<td class="cx-dash-num">' || numero(l_meses(i).admissoes - l_meses(i).desligamentos) || '</td></tr>');
    end loop;
    p('</tbody><tfoot><tr><th scope="row">Total</th>'
      || '<td class="cx-dash-num">' || numero(l_total_a) || '</td>'
      || '<td class="cx-dash-num">' || numero(l_total_d) || '</td>'
      || '<td class="cx-dash-num">' || numero(l_total_a - l_total_d) || '</td></tr></tfoot></table></div>');

    p('</section>');
    return g_html;
  end render_turnover;

  ------------------------------------------------------------------------------
  -- Promoções e tempo no cargo por departamento
  ------------------------------------------------------------------------------
  function render_departamentos (
    p_dt_inicio  in varchar2,
    p_dt_fim     in varchar2,
    p_id_empresa in number default to_number(v('G_ID_EMPRESA') default null on conversion error)
  ) return clob is
    l_ini      date := data_txt(p_dt_inicio);
    l_fim      date := data_txt(p_dt_fim);
    l_problema varchar2(200) := problema_periodo(p_id_empresa, l_ini, l_fim);
    l_hoje     date;
    l_linhas   pls_integer := 0;
  begin
    inicia;
    p('<section class="cx-dash-card" id="cx-dash-departamentos">');
    cabecalho('Promoções e tempo no cargo por departamento',
              'Promoções no período e tempo médio no cargo atual. Ordenado por número de promoções.');

    if l_problema is not null then
      aviso(l_problema);
      p('</section>');
      return g_html;
    end if;

    l_hoje := trunc(pkg_historico_carreira.fn_hoje(p_id_empresa));

    for r in (
      with promo as (
        select v.id_departamento_novo as id_departamento, count(*) as qt
          from vw_movimentacao_valida v
         where v.id_empresa  = p_id_empresa
           and v.cd_tipo     = 'PROMOCAO'
           and v.dt_efetiva >= l_ini
           and v.dt_efetiva <  l_fim + 1
         group by v.id_departamento_novo
      ),
      tempo as (
        select s.id_departamento, avg(months_between(l_hoje, s.dt_inicio_funcao)) as meses
          from vw_situacao_atual_colaborador s
         where s.id_empresa       = p_id_empresa
           and s.fl_vinculo_ativo = 'S'
         group by s.id_departamento
      ),
      deptos as (
        select d.id_departamento, d.nome
          from departamento d
         where d.id_empresa = p_id_empresa
        union all
        select null, '(sem departamento)'
          from dual
         where exists (select 1 from promo where id_departamento is null)
            or exists (select 1 from tempo where id_departamento is null)
      )
      select dp.nome,
             nvl(pr.qt, 0)                   as promocoes,
             tp.meses,
             max(nvl(pr.qt, 0)) over ()      as max_promocoes,
             max(tp.meses)      over ()      as max_meses
        from deptos dp
        -- decode compara nulo com nulo (linha "sem departamento")
        left join promo pr on decode(pr.id_departamento, dp.id_departamento, 1) = 1
        left join tempo tp on decode(tp.id_departamento, dp.id_departamento, 1) = 1
       order by promocoes desc, dp.nome
    ) loop
      if l_linhas = 0 then
        p('<div class="cx-dash-rolagem"><table class="cx-dash-tabela cx-dash-tabela--deptos">');
        p('<thead><tr><th scope="col">Departamento</th><th scope="col">Promoções</th>'
          || '<th scope="col">Tempo médio no cargo</th></tr></thead><tbody>');
      end if;
      l_linhas := l_linhas + 1;

      p('<tr><th scope="row">' || e(r.nome) || '</th><td>');
      if r.promocoes > 0 then
        p('<span class="cx-dash-medida"><span class="cx-dash-medida__barra" style="--w:'
          || pct(r.promocoes, r.max_promocoes) || '"></span><strong>' || numero(r.promocoes) || '</strong></span>');
      else
        p('<span class="cx-dash-medida is-zero">0</span>');
      end if;
      p('</td><td>');
      if r.meses is not null then
        p('<span class="cx-dash-medida"><span class="cx-dash-medida__barra" style="--w:'
          || pct(r.meses, r.max_meses) || '"></span><strong>' || e(tempo_no_cargo(r.meses)) || '</strong></span>');
      else
        p('<span class="cx-dash-medida is-zero">Sem colaboradores ativos</span>');
      end if;
      p('</td></tr>');
    end loop;

    if l_linhas = 0 then
      estado_vazio('Nenhum departamento cadastrado.', 'Cadastre os departamentos da empresa para ver este quadro.');
    else
      p('</tbody></table></div>');
    end if;

    p('</section>');
    return g_html;
  end render_departamentos;

  ------------------------------------------------------------------------------
  -- Solicitações de correção abertas
  ------------------------------------------------------------------------------
  function render_solicitacoes (
    p_id_empresa in number      default to_number(v('G_ID_EMPRESA') default null on conversion error),
    p_limite     in pls_integer default 3,
    p_ver_todas  in varchar2    default 'S'
  ) return clob is
    l_card   boolean := p_ver_todas = 'S';
    l_total  pls_integer;
    l_limite pls_integer := nvl(p_limite, 100000);
    l_hoje   date;
    l_dias   pls_integer;
  begin
    inicia;
    if p_id_empresa is null then
      aviso('Empresa não identificada na sessão. Saia e entre de novo.');
      return g_html;
    end if;

    select count(*)
      into l_total
      from solicitacao_correcao s
     where s.id_empresa     = p_id_empresa
       and s.st_solicitacao = 'ABERTA';

    if l_card then
      p('<section class="cx-dash-card cx-dash-card--lateral">');
      cabecalho('Solicitações de correção', 'Aguardando resposta · mais antigas primeiro',
                case when l_total > 0 then plural(l_total, 'aberta', 'abertas') end);
    end if;

    if l_total = 0 then
      estado_vazio('Nenhuma solicitação aberta.', 'Quando um colaborador pedir correção do histórico, o pedido aparece aqui.');
    else
      l_hoje := trunc(pkg_historico_carreira.fn_hoje(p_id_empresa));
      p('<ul class="cx-dash-lista">');
      for r in (
        select s.id_solicitacao,
               c.nome_completo,
               s.ds_mensagem,
               pkg_historico_carreira.fn_data_local(s.id_empresa, s.dt_criacao) as aberta_em
          from solicitacao_correcao s
          join colaborador c on c.id_colaborador = s.id_colaborador
         where s.id_empresa     = p_id_empresa
           and s.st_solicitacao = 'ABERTA'
         order by s.dt_criacao, s.id_solicitacao
         fetch first l_limite rows only
      ) loop
        l_dias := l_hoje - trunc(r.aberta_em);
        p('<li class="cx-dash-solicitacao">');
        p('<span class="cx-avatar" aria-hidden="true">' || e(iniciais(r.nome_completo)) || '</span>');
        p('<div class="cx-dash-solicitacao__corpo">');
        p('<div class="cx-dash-solicitacao__topo"><strong>' || e(r.nome_completo) || '</strong>'
          || '<span class="cx-dash-tempo">'
          || case when l_dias <= 0 then 'hoje' else 'há ' || plural(l_dias, 'dia', 'dias') end
          || '</span></div>');
        p('<p class="cx-dash-solicitacao__texto">' || e(r.ds_mensagem) || '</p>');
        p('<div class="cx-dash-solicitacao__rodape"><span>Aberta em '
          || to_char(r.aberta_em, 'DD/MM/YYYY, HH24:MI') || '</span>'
          || '<a class="cx-dash-link" href="'
          || a(apex_page.get_url(p_page        => 23,
                                 p_clear_cache => '23',
                                 p_items       => 'P23_ID_SOLICITACAO',
                                 p_values      => r.id_solicitacao))
          || '" aria-label="' || a('Responder à solicitação de ' || r.nome_completo) || '">Responder</a></div>');
        p('</div></li>');
      end loop;
      p('</ul>');

      if l_card and l_total > l_limite then
        rodape_dialogo('Ver todas as solicitações', 'dash_solicitacoes_todas');
      end if;
    end if;

    if l_card then
      p('</section>');
    end if;
    return g_html;
  end render_solicitacoes;

  ------------------------------------------------------------------------------
  -- Formações a vencer
  ------------------------------------------------------------------------------
  function render_formacoes (
    p_id_empresa in number      default to_number(v('G_ID_EMPRESA') default null on conversion error),
    p_limite     in pls_integer default 5,
    p_ver_todas  in varchar2    default 'S'
  ) return clob is
    l_card   boolean := p_ver_todas = 'S';
    l_total  pls_integer;
    l_limite pls_integer := nvl(p_limite, 100000);
    l_hoje   date;
  begin
    inicia;
    if p_id_empresa is null then
      aviso('Empresa não identificada na sessão. Saia e entre de novo.');
      return g_html;
    end if;

    l_hoje := trunc(pkg_historico_carreira.fn_hoje(p_id_empresa));

    select count(*)
      into l_total
      from formacao_colaborador f
     where f.id_empresa  = p_id_empresa
       and f.dt_validade between l_hoje and l_hoje + c_dias_formacao;

    if l_card then
      p('<section class="cx-dash-card cx-dash-card--lateral">');
      cabecalho('Formações a vencer', 'Próximos vencimentos, a partir de hoje',
                case when l_total > 0 then numero(l_total) || ' a vencer' end);
    end if;

    if l_total = 0 then
      estado_vazio('Nenhuma formação vence nos próximos ' || c_dias_formacao || ' dias.');
    else
      p('<ul class="cx-dash-lista">');
      for r in (
        select f.id_colaborador,
               c.nome_completo,
               f.ds_titulo,
               f.tp_formacao,
               f.ds_instituicao,
               f.dt_validade,
               trunc(f.dt_validade) - l_hoje as dias
          from formacao_colaborador f
          join colaborador c on c.id_colaborador = f.id_colaborador
         where f.id_empresa  = p_id_empresa
           and f.dt_validade between l_hoje and l_hoje + c_dias_formacao
         order by f.dt_validade, c.nome_completo
         fetch first l_limite rows only
      ) loop
        p('<li class="cx-dash-formacao">');
        p('<div class="cx-dash-formacao__topo"><a class="cx-dash-formacao__nome" href="'
          || a(apex_page.get_url(p_page   => 19,
                                 p_items  => 'P19_ID_COLABORADOR',
                                 p_values => r.id_colaborador))
          || '">' || e(r.nome_completo) || '</a>'
          || '<span class="cx-dash-prazo'
          || case when r.dias <= 7 then ' is-urgente' when r.dias <= 30 then ' is-atencao' end
          || '">' || case when r.dias = 0 then 'Hoje' else plural(r.dias, 'dia', 'dias') end || '</span></div>');
        p('<p class="cx-dash-formacao__titulo">' || e(r.ds_titulo) || '</p>');
        p('<p class="cx-dash-formacao__detalhe">'
          || e(tipo_formacao(r.tp_formacao) || ' · ' || r.ds_instituicao
               || ' · vence em ' || to_char(r.dt_validade, 'DD/MM/YYYY')) || '</p>');
        p('</li>');
      end loop;
      p('</ul>');

      if l_card and l_total > l_limite then
        rodape_dialogo('Ver todas as formações', 'dash_formacoes_todas');
      end if;
    end if;

    if l_card then
      p('</section>');
    end if;
    return g_html;
  end render_formacoes;

end pkg_dashboard_rh_ui;
/
