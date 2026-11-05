--------------------------------------------------------------------------------
-- Corlix Hub · Holerite digital (página 9) · 02 · HTML · corpo
-- Os ícones são SVG Lucide em linha, como no Ponto e no Dashboard RH. Nomes de mês
-- e formato de número são explícitos: o idioma técnico da app é "en".
--------------------------------------------------------------------------------
create or replace package body pkg_holerite_ui as

  c_pagina_holerite constant pls_integer  := 9;
  c_pagina_correcao constant pls_integer  := 22;
  c_item_competencia constant varchar2(30) := 'P9_COMPETENCIA';
  c_item_mensagem    constant varchar2(30) := 'P22_DS_MENSAGEM';
  c_aliquota_fgts   constant number       := 0.08;
  -- O holerite do mês aparece a partir deste dia. A mesma regra está em
  -- prc_gerar_holerites_pendentes.
  c_dia_liberacao   constant pls_integer  := 25;

  type t_holerite is record (
    id_holerite     colaborador_holerite.id_holerite%type,
    competencia     date,
    data_pagamento  colaborador_holerite.data_pagamento%type,
    total_proventos colaborador_holerite.total_proventos%type,
    total_descontos colaborador_holerite.total_descontos%type,
    valor_liquido   colaborador_holerite.valor_liquido%type
  );
  type t_holerites is table of t_holerite index by pls_integer;

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
    l_id number;
  begin
    if p_id is not null then
      return p_id;
    end if;
    select id_colaborador
      into l_id
      from colaborador
     where upper(trim(login_apex)) = upper(trim(v('APP_USER')))
       and id_empresa = pkg_historico_carreira.fn_empresa_contexto;
    return l_id;
  exception
    when no_data_found or too_many_rows then
      return null;
  end id_ou_logado;

  -- "3.500,00"
  function num (p_valor in number) return varchar2 is
  begin
    return to_char(p_valor, 'FM999G999G990D00', 'NLS_NUMERIC_CHARACTERS='',.''');
  end num;

  -- "82,2" (texto) ou "82.2" (CSS)
  function pct (p_valor in number, p_css in boolean default false) return varchar2 is
  begin
    return to_char(p_valor, 'FM990D0',
                   case when p_css then 'NLS_NUMERIC_CHARACTERS=''.,'''
                        else 'NLS_NUMERIC_CHARACTERS='',.''' end);
  end pct;

  -- Valor que o botão "Ocultar valores" esconde
  function v_oculto (p_txt in varchar2) return varchar2 is
  begin
    return '<span data-cx-hol-valor>' || e(p_txt) || '</span>';
  end v_oculto;

  function mes_nome (p_dt in date) return varchar2 is
  begin
    return case to_number(to_char(p_dt, 'MM'))
      when 1 then 'Janeiro' when 2 then 'Fevereiro' when 3 then 'Março' when 4 then 'Abril'
      when 5 then 'Maio' when 6 then 'Junho' when 7 then 'Julho' when 8 then 'Agosto'
      when 9 then 'Setembro' when 10 then 'Outubro' when 11 then 'Novembro' else 'Dezembro' end;
  end mes_nome;

  -- "00.000.000/0001-00"; o que não tiver 14 dígitos sai como está gravado
  function cnpj (p_txt in varchar2) return varchar2 is
    l_digitos constant varchar2(20) := regexp_replace(p_txt, '[^0-9]', '');
  begin
    if length(l_digitos) = 14 then
      return regexp_replace(l_digitos, '^(.{2})(.{3})(.{3})(.{4})(.{2})$', '\1.\2.\3/\4-\5');
    end if;
    return p_txt;
  end cnpj;

  function url_competencia (p_dt in date) return varchar2 is
  begin
    return apex_page.get_url(
             p_page   => c_pagina_holerite,
             p_items  => c_item_competencia,
             p_values => to_char(p_dt, 'YYYYMM'));
  end url_competencia;

  function icone (p_nome in varchar2) return varchar2 is
    l_svg varchar2(1000);
  begin
    l_svg := case p_nome
      when 'olho-fechado' then '<path d="M9.88 9.88a3 3 0 1 0 4.24 4.24"/><path d="M10.73 5.08A10.43 10.43 0 0 1 12 5c7 0 10 7 10 7a13.16 13.16 0 0 1-1.67 2.68"/><path d="M6.61 6.61A13.53 13.53 0 0 0 2 12s3 7 10 7a9.74 9.74 0 0 0 5.39-1.61"/><line x1="2" x2="22" y1="2" y2="22"/>'
      when 'olho'         then '<path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/>'
      when 'download'     then '<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" x2="12" y1="15" y2="3"/>'
      when 'banco'        then '<line x1="3" x2="21" y1="22" y2="22"/><line x1="6" x2="6" y1="18" y2="11"/><line x1="10" x2="10" y1="18" y2="11"/><line x1="14" x2="14" y1="18" y2="11"/><line x1="18" x2="18" y1="18" y2="11"/><polygon points="12 2 20 7 4 7"/>'
      when 'mais'         then '<circle cx="12" cy="12" r="10"/><path d="M8 12h8"/><path d="M12 8v8"/>'
      when 'menos'        then '<circle cx="12" cy="12" r="10"/><path d="M8 12h8"/>'
      when 'info'         then '<circle cx="12" cy="12" r="10"/><path d="M12 16v-4"/><path d="M12 8h.01"/>'
      when 'mensagem'     then '<path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/><path d="M12 7v4"/><path d="M12 14h.01"/>'
      when 'cadeado'      then '<rect width="18" height="11" x="3" y="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/>'
    end;
    return '<svg class="cx-hol-icone" width="18" height="18" viewBox="0 0 24 24" aria-hidden="true" focusable="false">'
        || l_svg || '</svg>';
  end icone;

  -- Holerites que a pessoa pode ver, do mais recente para o mais antigo. Ficam de
  -- fora o mês atual antes do dia 25, os meses futuros e os anteriores à admissão,
  -- que a geração antiga criava.
  function holerites_de (p_id_colaborador in number, p_hoje in date) return t_holerites is
    l_lista  t_holerites;
    l_ultimo constant date := case when to_number(to_char(p_hoje, 'DD')) >= c_dia_liberacao
                                   then trunc(p_hoje, 'MM')
                                   else add_months(trunc(p_hoje, 'MM'), -1) end;
  begin
    select h.id_holerite,
           to_date(to_char(h.ano_referencia * 100 + h.mes_referencia) || '01', 'YYYYMMDD'),
           h.data_pagamento, h.total_proventos, h.total_descontos, h.valor_liquido
      bulk collect into l_lista
      from colaborador_holerite h
      join colaborador c on c.id_colaborador = h.id_colaborador
     where h.id_colaborador = p_id_colaborador
       and to_date(to_char(h.ano_referencia * 100 + h.mes_referencia) || '01', 'YYYYMMDD') <= l_ultimo
       and (c.data_admissao is null
            or to_date(to_char(h.ano_referencia * 100 + h.mes_referencia) || '01', 'YYYYMMDD') >= trunc(c.data_admissao, 'MM'))
     order by h.ano_referencia desc, h.mes_referencia desc;
    return l_lista;
  end holerites_de;

  ------------------------------------------------------------------------------
  -- Textos dos itens: a geração grava "Salário Base" e "Tabela Oficial"
  ------------------------------------------------------------------------------
  function rotulo_item (p_descricao in varchar2) return varchar2 is
  begin
    return case upper(p_descricao)
      when 'SALÁRIO BASE'    then 'Salário base'
      when 'VALE TRANSPORTE' then 'Vale-transporte'
      else p_descricao end;
  end rotulo_item;

  function nota_item (p_descricao in varchar2) return varchar2 is
  begin
    return case upper(p_descricao)
      when 'SALÁRIO BASE'    then 'Salário mensal do cargo'
      when 'INSS'            then 'Contribuição à Previdência Social'
      when 'IRRF'            then 'Imposto de Renda retido na fonte'
      when 'VALE TRANSPORTE' then 'Sua parte no custo do benefício'
    end;
  end nota_item;

  ------------------------------------------------------------------------------
  -- Cabeçalho
  ------------------------------------------------------------------------------
  function render_cabecalho (p_id_colaborador in number default null) return clob is
    l_id    constant number := id_ou_logado(p_id_colaborador);
    l_lista t_holerites;
  begin
    inicia;
    p('<div class="cx-cabecalho-pagina cx-cabecalho-pagina--acoes cx-hol-cabecalho">');
    p('<div class="cx-cabecalho-pagina__texto"><h1 class="cx-cabecalho-pagina__titulo">Holerite digital</h1>');
    p('<p class="cx-cabecalho-pagina__descricao">Seus demonstrativos de pagamento mês a mês. Só você e o RH têm acesso a estes valores.</p></div>');

    if l_id is not null then
      l_lista := holerites_de(l_id, pkg_historico_carreira.fn_hoje(pkg_historico_carreira.fn_empresa_contexto));
      if l_lista.count > 0 then
        p('<div class="cx-cabecalho-pagina__acoes">');
        p('<button type="button" class="t-Button cx-hol-botao" data-cx-hol-ocultar aria-pressed="false">');
        p('<span data-cx-hol-icone-ocultar>' || icone('olho-fechado') || '</span>');
        p('<span data-cx-hol-icone-mostrar hidden>' || icone('olho') || '</span>');
        p('<span class="t-Button-label" data-cx-hol-ocultar-texto>Ocultar valores</span></button>');
        p('<button type="button" class="t-Button cx-hol-botao cx-hol-botao--escuro" data-cx-hol-imprimir>'
          || icone('download') || '<span class="t-Button-label">Baixar PDF</span></button>');
        p('</div>');
      end if;
    end if;

    p('</div>');
    return g_html;
  end render_cabecalho;

  ------------------------------------------------------------------------------
  -- Resumo: líquido, bruto, descontos e barra
  ------------------------------------------------------------------------------
  procedure resumo (
    p_h           in t_holerite,
    p_nome        in varchar2,
    p_empresa     in varchar2,
    p_cnpj        in varchar2,
    p_cargo       in varchar2,
    p_agendado    in boolean
  ) is
    l_pct_liq number := 0;
    l_pct_des number := 0;
  begin
    if p_h.total_proventos > 0 then
      l_pct_liq := round(p_h.valor_liquido / p_h.total_proventos * 100, 1);
      l_pct_des := round(100 - l_pct_liq, 1);
    end if;

    p('<section class="cx-hol-card cx-hol-resumo">');
    p('<header class="cx-hol-resumo__topo"><div>');
    p('<p class="cx-hol-impressao-nome">' || e(p_nome) || '</p>');
    p('<div class="cx-hol-resumo__titulo"><h2>' || e(mes_nome(p_h.competencia)) || ' de '
      || to_char(p_h.competencia, 'YYYY') || '</h2><span class="cx-hol-tag">Folha mensal</span></div>');
    p('<p class="cx-hol-resumo__meta">' || e(p_empresa)
      || case when p_cnpj is not null then ' · CNPJ ' || e(cnpj(p_cnpj)) end
      || case when p_cargo is not null then ' · ' || e(p_cargo) end || '</p></div>');
    p('<span class="cx-hol-selo ' || case when p_agendado then 'is-agendado' else 'is-pago' end || '">'
      || case when p_agendado then 'Pagamento agendado' else 'Pago' end || '</span>');
    p('</header>');

    p('<div class="cx-hol-resumo__corpo"><div class="cx-hol-resumo__numeros">');
    p('<div><p class="cx-hol-resumo__rotulo">Líquido a receber</p>');
    p('<p class="cx-hol-resumo__liquido">' || v_oculto('R$ ' || num(p_h.valor_liquido)) || '</p>');
    p('<p class="cx-hol-resumo__credito">' || icone('banco') || 'Crédito em '
      || to_char(p_h.data_pagamento, 'DD/MM/YYYY') || '</p></div>');
    p('<dl class="cx-hol-resumo__totais">');
    p('<div><dt>Proventos (bruto)</dt><dd>' || v_oculto('R$ ' || num(p_h.total_proventos)) || '</dd></div>');
    p('<div><dt>Descontos</dt><dd>' || v_oculto('– R$ ' || num(p_h.total_descontos)) || '</dd></div>');
    p('</dl></div>');

    p('<div class="cx-hol-barra" aria-hidden="true" data-cx-hol-barra>');
    p('<span class="cx-hol-barra__liquido" style="width:' || pct(l_pct_liq, true) || '%"></span>');
    p('<span class="cx-hol-barra__descontos" style="width:' || pct(l_pct_des, true) || '%"></span></div>');
    p('<ul class="cx-hol-legenda">');
    p('<li><span class="cx-hol-legenda__cor is-liquido"></span><span>Líquido · '
      || v_oculto(pct(l_pct_liq) || '% do bruto') || '</span></li>');
    p('<li><span class="cx-hol-legenda__cor is-descontos"></span><span>Descontos · '
      || v_oculto(pct(l_pct_des) || '%') || '</span></li>');
    p('</ul></div></section>');
  end resumo;

  ------------------------------------------------------------------------------
  -- Detalhamento: itens, líquido, bases e FGTS
  ------------------------------------------------------------------------------
  procedure grupo (p_titulo in varchar2, p_icone in varchar2, p_valor in varchar2) is
  begin
    p('<tr class="cx-hol-tabela__grupo"><th scope="rowgroup" colspan="2"><span class="cx-hol-tabela__grupo-nome">'
      || icone(p_icone) || e(p_titulo) || '</span></th><td class="cx-hol-num">' || v_oculto(p_valor) || '</td></tr>');
  end grupo;

  procedure linha_item (p_descricao in varchar2, p_referencia in varchar2, p_valor in varchar2) is
    l_nota constant varchar2(100) := nota_item(p_descricao);
  begin
    p('<tr class="cx-hol-tabela__item"><td><span class="cx-hol-tabela__nome">' || e(rotulo_item(p_descricao)) || '</span>');
    if l_nota is not null then
      p('<span class="cx-hol-tabela__nota">' || e(l_nota) || '</span>');
    end if;
    p('</td><td class="cx-hol-tabela__referencia">' || p_referencia || '</td>');
    p('<td class="cx-hol-num">' || v_oculto(p_valor) || '</td></tr>');
  end linha_item;

  procedure detalhamento (p_h in t_holerite) is
    l_inss      number := 0;
    l_base_irrf number;
    l_ref       varchar2(200);
  begin
    select nvl(sum(valor), 0)
      into l_inss
      from holerite_itens
     where id_holerite = p_h.id_holerite and tipo = 'D' and upper(descricao) = 'INSS';
    l_base_irrf := p_h.total_proventos - l_inss;

    p('<section class="cx-hol-card cx-hol-detalhe">');
    p('<header class="cx-hol-card__cabecalho"><h2 class="cx-hol-card__titulo">Detalhamento</h2>');
    p('<span class="cx-hol-card__aviso">Valores em R$</span></header>');
    p('<div class="cx-hol-tabela-rolagem"><table class="cx-hol-tabela"><colgroup><col><col class="cx-hol-tabela__col-referencia"><col class="cx-hol-tabela__col-valor"></colgroup>');
    p('<thead><tr><th scope="col">Descrição</th><th scope="col">Referência</th><th scope="col" class="cx-hol-num">Valor</th></tr></thead><tbody>');

    grupo('Proventos', 'mais', num(p_h.total_proventos));
    for i in (select descricao, referencia, valor from holerite_itens
               where id_holerite = p_h.id_holerite and tipo = 'P' order by id_item) loop
      linha_item(i.descricao, nvl(e(i.referencia), '—'), num(i.valor));
    end loop;

    grupo('Descontos', 'menos', '– ' || num(p_h.total_descontos));
    for i in (select descricao, referencia, valor from holerite_itens
               where id_holerite = p_h.id_holerite and tipo = 'D' order by id_item) loop
      l_ref := case upper(i.descricao)
        when 'INSS' then
          case when p_h.total_proventos > 0
               then 'Alíquota efetiva ' || v_oculto(trim(to_char(i.valor / p_h.total_proventos * 100, 'FM990D00', 'NLS_NUMERIC_CHARACTERS='',.''')) || '%')
               else e(i.referencia) end
        when 'IRRF' then 'Base de cálculo ' || v_oculto(num(l_base_irrf))
        when 'VALE TRANSPORTE' then '6% do salário base'
        else nvl(e(i.referencia), '—') end;
      linha_item(i.descricao, l_ref, '– ' || num(i.valor));
    end loop;

    p('</tbody><tfoot><tr><th scope="row" colspan="2">Líquido a receber</th><td class="cx-hol-num">'
      || v_oculto(num(p_h.valor_liquido)) || '</td></tr></tfoot></table></div>');

    p('<div class="cx-hol-bases"><h3 class="cx-hol-bases__titulo">Bases de cálculo e FGTS</h3><dl class="cx-hol-bases__lista">');
    p('<div><dt>Base INSS</dt><dd>' || v_oculto(num(p_h.total_proventos)) || '</dd></div>');
    p('<div><dt>Base IRRF</dt><dd>' || v_oculto(num(l_base_irrf)) || '</dd></div>');
    p('<div><dt>Base FGTS</dt><dd>' || v_oculto(num(p_h.total_proventos)) || '</dd></div>');
    p('<div><dt>FGTS do mês</dt><dd>' || v_oculto(num(round(p_h.total_proventos * c_aliquota_fgts, 2))) || '</dd></div>');
    p('</dl><p class="cx-hol-nota">' || icone('info')
      || '<span>O FGTS é depositado pela empresa na sua conta do FGTS e não é descontado do seu salário.</span></p></div>');
    p('</section>');
  end detalhamento;

  ------------------------------------------------------------------------------
  -- Coluna lateral: holerites do ano e pedido de correção
  ------------------------------------------------------------------------------
  procedure lista (p_lista in t_holerites, p_atual in pls_integer, p_hoje in date) is
    l_ano  constant varchar2(4) := to_char(p_lista(p_atual).competencia, 'YYYY');
    l_ano_i varchar2(4);
    l_ultimo varchar2(4);
    l_agendado boolean;
  begin
    p('<section class="cx-hol-card cx-hol-lista">');
    p('<header class="cx-hol-card__cabecalho"><h2 class="cx-hol-card__titulo">Holerites</h2>');
    p('<label class="cx-hol-ano"><span class="u-VisuallyHidden">Ano</span><select class="cx-hol-ano__select" data-cx-hol-ano>');
    -- A lista está em ordem decrescente: a primeira linha de cada ano é o mês mais recente
    for i in 1 .. p_lista.count loop
      l_ano_i := to_char(p_lista(i).competencia, 'YYYY');
      if l_ultimo is null or l_ultimo != l_ano_i then
        p('<option value="' || a(url_competencia(p_lista(i).competencia)) || '"'
          || case when l_ano_i = l_ano then ' selected' end || '>' || l_ano_i || '</option>');
        l_ultimo := l_ano_i;
      end if;
    end loop;
    p('</select></label></header><ul class="cx-hol-lista__itens">');

    for i in 1 .. p_lista.count loop
      if to_char(p_lista(i).competencia, 'YYYY') = l_ano then
        l_agendado := p_lista(i).data_pagamento > p_hoje;
        p('<li><a class="cx-hol-lista__item' || case when i = p_atual then ' is-atual' end || '" href="'
          || a(url_competencia(p_lista(i).competencia)) || '"'
          || case when i = p_atual then ' aria-current="page"' end || '>');
        p('<span><span class="cx-hol-lista__mes">' || e(mes_nome(p_lista(i).competencia)) || '</span>');
        p('<span class="cx-hol-lista__situacao">'
          || case when l_agendado then 'Pagamento agendado · ' else 'Pago em ' end
          || to_char(p_lista(i).data_pagamento, 'DD/MM') || '</span></span>');
        p('<span class="cx-hol-lista__valor">' || v_oculto('R$ ' || num(p_lista(i).valor_liquido)) || '</span></a></li>');
      end if;
    end loop;
    p('</ul></section>');
  end lista;

  procedure correcao (p_competencia in date) is
  begin
    p('<section class="cx-hol-card cx-hol-correcao">');
    p('<h2 class="cx-hol-card__titulo">Algo errado neste holerite?</h2>');
    p('<p>Peça uma revisão ao RH informando o item e o valor que você esperava.</p>');
    -- Só caracteres seguros em URL: get_url não documenta como trata espaços nos valores
    p('<a class="t-Button cx-hol-botao cx-hol-botao--largo" href="'
      || a(apex_page.get_url(
             p_page        => c_pagina_correcao,
             p_clear_cache => to_char(c_pagina_correcao),
             p_items       => c_item_mensagem,
             p_values      => 'Holerite-' || to_char(p_competencia, 'MM/YYYY')))
      || '">' || icone('mensagem') || '<span class="t-Button-label">Solicitar correção</span></a>');
    p('<p class="cx-hol-nota">' || icone('cadeado') || '<span>Visível só para você e o RH.</span></p>');
    p('</section>');
  end correcao;

  ------------------------------------------------------------------------------
  -- Página
  ------------------------------------------------------------------------------
  function render_pagina (
    p_competencia    in varchar2 default null,
    p_id_colaborador in number default null
  ) return clob is
    l_id        constant number := id_ou_logado(p_id_colaborador);
    l_alvo      date;
    l_atual     pls_integer := 1;
    l_lista     t_holerites;
    l_hoje      date;
    l_nome      colaborador.nome_completo%type;
    l_empresa   empresa.nome%type;
    l_cnpj      empresa.cnpj%type;
    l_cargo     cargo.nome%type;
    l_id_empresa number;
  begin
    inicia;

    if l_id is null then
      p('<p class="cx-hol-card cx-hol-vazio">Sua conta não está vinculada a um colaborador desta empresa. Fale com o RH.</p>');
      return g_html;
    end if;

    select c.id_empresa, c.nome_completo, coalesce(em.nome_fantasia, em.nome), em.cnpj, ca.nome
      into l_id_empresa, l_nome, l_empresa, l_cnpj, l_cargo
      from colaborador c
      join empresa em on em.id_empresa = c.id_empresa
      left join cargo ca on ca.id_cargo = c.id_cargo
     where c.id_colaborador = l_id;

    l_hoje  := pkg_historico_carreira.fn_hoje(l_id_empresa);
    l_lista := holerites_de(l_id, l_hoje);

    if l_lista.count = 0 then
      p('<p class="cx-hol-card cx-hol-vazio">Nenhum holerite disponível ainda. Ele aparece aqui quando a folha do mês for gerada.</p>');
      return g_html;
    end if;

    l_alvo := to_date(p_competencia || '01' default null on conversion error, 'YYYYMMDD');
    if l_alvo is not null then
      for i in 1 .. l_lista.count loop
        if l_lista(i).competencia = l_alvo then
          l_atual := i;
        end if;
      end loop;
    end if;

    p('<div class="cx-hol" data-cx-hol>');
    p('<div class="cx-hol__principal">');
    resumo(l_lista(l_atual), l_nome, l_empresa, l_cnpj, l_cargo, l_lista(l_atual).data_pagamento > l_hoje);
    detalhamento(l_lista(l_atual));
    p('</div><aside class="cx-hol__lateral">');
    lista(l_lista, l_atual, l_hoje);
    correcao(l_lista(l_atual).competencia);
    p('</aside></div>');
    return g_html;
  end render_pagina;

end pkg_holerite_ui;
/
