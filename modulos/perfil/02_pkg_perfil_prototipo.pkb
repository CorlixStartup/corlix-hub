-- =============================================================================
-- Corlix Hub · Perfil (página 2): corpo do PKG_PERFIL fiel ao protótipo do pen.dev
-- Mantém a restrição de acesso de Etapas-perfil-privacidade.md.
-- Guia: Etapas-perfil-prototipo.md
-- Depende de: PKG_HISTORICO_CARREIRA, PKG_ORGANOGRAMA, VW_ORG_COLABORADOR,
-- COLABORADOR, CARGO, DEPARTAMENTO, EMPRESA, HISTORICO_CARREIRA, VW_MOVIMENTACAO_VALIDA
-- e do item G_ID_EMPRESA.
-- =============================================================================
create or replace package body pkg_perfil as

  c_pagina_perfil      constant pls_integer  := 2;
  c_item_perfil        constant varchar2(30) := 'P2_ID_COLABORADOR';
  c_pagina_chat        constant pls_integer  := 4;
  c_pagina_organograma constant pls_integer  := 3;
  c_item_organograma   constant varchar2(30) := 'P3_ID_FOCO';
  c_max_colegas        constant pls_integer  := 6;

  c_svg constant varchar2(200) :=
    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">';
  c_ico_camera  constant varchar2(400) := c_svg
    || '<path d="M14.5 4h-5L7 7H4a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2h-3l-2.5-3z"/><circle cx="12" cy="13" r="3"/></svg>';
  c_ico_agenda  constant varchar2(400) := c_svg
    || '<rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>';
  c_ico_email   constant varchar2(400) := c_svg
    || '<rect width="20" height="16" x="2" y="4" rx="2"/><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/></svg>';
  c_ico_cadeado constant varchar2(400) := c_svg
    || '<rect width="18" height="11" x="3" y="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>';
  c_ico_info    constant varchar2(400) := c_svg
    || '<circle cx="12" cy="12" r="10"/><path d="M12 16v-4"/><path d="M12 8h.01"/></svg>';
  c_ico_chat    constant varchar2(400) := c_svg
    || '<path d="M7.9 20A9 9 0 1 0 4 16.1L2 22Z"/></svg>';
  c_ico_org     constant varchar2(500) := c_svg
    || '<rect x="16" y="16" width="6" height="6" rx="1"/><rect x="2" y="16" width="6" height="6" rx="1"/><rect x="9" y="2" width="6" height="6" rx="1"/><path d="M5 16v-3a1 1 0 0 1 1-1h12a1 1 0 0 1 1 1v3"/><path d="M12 12V8"/></svg>';

  g_html clob;

  -- O CLOB devolvido a uma região não pode ser liberado pela região seguinte
  procedure inicia is
  begin
    g_html := null;
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

  function url_perfil (p_id in number) return varchar2 is
  begin
    return e(apex_page.get_url(p_page => c_pagina_perfil, p_items => c_item_perfil, p_values => to_char(p_id)));
  end url_perfil;

  function avatar_perfil (
    p_nome     in varchar2,
    p_foto_url in varchar2,
    p_tamanho  in varchar2 default 'lg'
  ) return varchar2 is
    l_iniciais  varchar2(10);
    l_nome_foto varchar2(255);
  begin
    l_iniciais := upper(substr(p_nome, 1, 1) ||
                  case when instr(p_nome, ' ') > 0 then
                    substr(p_nome, instr(p_nome, ' ', -1) + 1, 1)
                  end);

    l_nome_foto := trim(p_foto_url);
    if l_nome_foto like 'Fotos Colaboradores/%' then
      l_nome_foto := substr(l_nome_foto, 21);
    end if;

    return '<span class="perfil-avatar perfil-avatar--' || p_tamanho || '">'
        || '<span class="perfil-avatar__iniciais">' || e(l_iniciais) || '</span>'
        || case when l_nome_foto is not null then
             '<img data-perfil-foto="' || e(l_nome_foto) || '" alt="" loading="lazy" onerror="this.remove()">'
           end
        || '</span>';
  end avatar_perfil;

  function mes_ano (p_data in date) return varchar2 is
  begin
    return to_char(p_data, 'fmmonth "de" yyyy', 'NLS_DATE_LANGUAGE=''BRAZILIAN PORTUGUESE''');
  end mes_ano;

  function plural (p_n in pls_integer, p_um in varchar2, p_varios in varchar2) return varchar2 is
  begin
    return p_n || ' ' || case when p_n = 1 then p_um else p_varios end;
  end plural;

  -- "2 anos e 6 meses"
  function duracao (p_inicio in date, p_fim in date) return varchar2 is
    l_meses constant pls_integer :=
      floor(months_between(trunc(coalesce(p_fim, current_date)), trunc(p_inicio)));
    l_anos  constant pls_integer := trunc(l_meses / 12);
    l_resto constant pls_integer := mod(l_meses, 12);
  begin
    return case
             when l_meses < 1 then 'menos de 1 mês'
             when l_anos  = 0 then plural(l_resto, 'mês', 'meses')
             when l_resto = 0 then plural(l_anos, 'ano', 'anos')
             else plural(l_anos, 'ano', 'anos') || ' e ' || plural(l_resto, 'mês', 'meses')
           end;
  end duracao;

  -- Empresa da sessão. Sem ela, nada é mostrado.
  function empresa_sessao return number is
  begin
    return to_number(v('G_ID_EMPRESA') default null on conversion error);
  end empresa_sessao;

  -- Colaborador do usuário logado, dentro da empresa da sessão
  function id_logado (p_id_empresa in number) return number is
    l_usuario constant varchar2(255) := v('APP_USER');
    l_id      number;
  begin
    select id_colaborador
      into l_id
      from colaborador
     where upper(trim(login_apex)) = upper(trim(l_usuario))
       and id_empresa = p_id_empresa;
    return l_id;
  exception
    when no_data_found or too_many_rows then
      return null;
  end id_logado;

  function e_da_empresa (p_id_colaborador in number, p_id_empresa in number) return boolean is
    l_qt pls_integer;
  begin
    select count(*)
      into l_qt
      from colaborador
     where id_colaborador = p_id_colaborador
       and id_empresa = p_id_empresa;
    return l_qt > 0;
  end e_da_empresa;

  -- Resolve quem está sendo aberto. Outra empresa recebe a mesma resposta de um ID inexistente.
  function carrega (
    p_id_colaborador in number,
    p_c              out vw_org_colaborador%rowtype,
    p_eu             out number
  ) return boolean is
    l_emp constant number := empresa_sessao;
    l_id  number;
  begin
    p_eu := id_logado(l_emp);
    -- Os links e o JS podem mandar vazio ou 0 no próprio perfil
    l_id := nvl(nullif(p_id_colaborador, 0), p_eu);

    if l_id is null or not e_da_empresa(l_id, l_emp) then
      return false;
    end if;

    select * into p_c from vw_org_colaborador where id_colaborador = l_id;
    return true;
  exception
    when no_data_found then
      return false;
  end carrega;

  function render_cabecalho (
    p_id_colaborador in number default null
  ) return clob is
    l_c          vw_org_colaborador%rowtype;
    l_eu         number;
    l_e_proprio  boolean;
    l_nome_curto empresa.nome_fantasia%type;
    l_emp        constant number := empresa_sessao;  -- função privada não pode ser chamada dentro de SQL
  begin
    inicia;

    if not carrega(p_id_colaborador, l_c, l_eu) then
      p('<div class="perfil-header"><h1>Perfil</h1></div>');
      return g_html;
    end if;

    l_e_proprio := l_c.id_colaborador = l_eu;

    select nome_fantasia into l_nome_curto from empresa where id_empresa = l_emp;

    p('<header class="perfil-header">');
    p('<div class="perfil-header__avatar">');
    p(avatar_perfil(l_c.nome_completo, l_c.foto_url, 'lg'));
    if l_e_proprio then
      p('<button type="button" class="perfil-header__cam" data-acao="abrir-foto-drawer" title="Alterar foto" aria-label="Alterar foto">' || c_ico_camera || '</button>');
    end if;
    p('</div>');

    p('<div class="perfil-header__info">');
    p('<h1>' || e(l_c.nome_completo) || '</h1>');
    p('<p class="perfil-header__cargo">' || e(l_c.cargo) || ' &middot; ' || e(l_c.departamento) || '</p>');
    p('<div class="perfil-header__metas">');
    p('<span>' || c_ico_agenda || 'Na ' || e(l_nome_curto) || ' desde ' || pkg_organograma.tempo_de_casa(l_c.data_admissao) || '</span>');
    p('<a href="mailto:' || e(l_c.email) || '">' || c_ico_email || e(l_c.email) || '</a>');
    p('</div>');
    p('</div>');

    if l_e_proprio then
      p('<button type="button" class="perfil-btn perfil-header__acao" data-acao="abrir-foto-drawer">' || c_ico_camera || '<span>Alterar foto</span></button>');
    end if;
    p('</header>');

    return g_html;
  end render_cabecalho;

  -- Períodos de cargo e área vindos do histórico de carreira. Só entram movimentações
  -- efetivadas, sem estorno e que mudam cargo ou área: reajuste, afastamento e retorno
  -- nunca aparecem, e a view usada não tem salário.
  procedure render_trajetoria (
    p_c          in vw_org_colaborador%rowtype,
    p_nome_curto in varchar2,
    p_id_empresa in number
  ) is
    type t_periodo is record (
      cargo  varchar2(400),
      depto  varchar2(400),
      tipo   varchar2(100),
      motivo varchar2(1000),
      ini    date,
      fim    date,
      atual  boolean
    );
    type t_periodos is table of t_periodo index by pls_integer;

    l_hoje      constant date := pkg_historico_carreira.fn_hoje(p_id_empresa);
    l_id        constant number := p_c.id_colaborador;
    l_per       t_periodos;
    l_n         pls_integer := 0;
    l_aberto    boolean := false;
    l_id_cargo  number;
    l_id_depto  number;
    l_nm_cargo  varchar2(400);
    l_nm_depto  varchar2(400);
    l_cargo_ini varchar2(400);
  begin
    for r in (
      select v.cd_tipo, v.ds_tipo, v.dt_efetiva, v.id_cargo_novo, v.id_departamento_novo,
             cg.nome as nm_cargo, dp.nome as nm_depto, h.ds_motivo
        from vw_movimentacao_valida v
        join historico_carreira h on h.id_historico_carreira = v.id_historico_carreira
        left join cargo cg on cg.id_cargo = v.id_cargo_novo
        left join departamento dp on dp.id_departamento = v.id_departamento_novo
       where v.id_colaborador = l_id
         and v.id_empresa = p_id_empresa
         and v.dt_efetiva <= l_hoje
         and v.cd_tipo in ('ADMISSAO', 'PROMOCAO', 'MUDANCA_CARGO', 'TRANSFERENCIA_DEPTO', 'DESLIGAMENTO')
       order by v.dt_efetiva, v.id_historico_carreira
    ) loop
      if r.cd_tipo = 'DESLIGAMENTO' then
        if l_aberto then
          l_per(l_n).fim := r.dt_efetiva;
          l_aberto := false;
        end if;
      elsif r.cd_tipo = 'ADMISSAO'
         or not l_aberto
         or coalesce(r.id_cargo_novo, l_id_cargo) <> l_id_cargo
         or coalesce(r.id_departamento_novo, l_id_depto) <> l_id_depto
      then
        if l_aberto then
          -- O período anterior vai até a véspera da mudança
          l_per(l_n).fim := greatest(r.dt_efetiva - 1, l_per(l_n).ini);
        end if;

        -- Transferência ou promoção pode não informar um dos dois: vale o que já estava
        l_id_cargo := coalesce(r.id_cargo_novo, l_id_cargo);
        l_id_depto := coalesce(r.id_departamento_novo, l_id_depto);
        l_nm_cargo := coalesce(r.nm_cargo, l_nm_cargo);
        l_nm_depto := coalesce(r.nm_depto, l_nm_depto);

        l_n := l_n + 1;
        l_per(l_n).cargo  := coalesce(l_nm_cargo, p_c.cargo);
        l_per(l_n).depto  := coalesce(l_nm_depto, p_c.departamento);
        l_per(l_n).tipo   := case when r.cd_tipo <> 'ADMISSAO' then r.ds_tipo end;
        l_per(l_n).motivo := case when r.cd_tipo <> 'ADMISSAO' then substr(r.ds_motivo, 1, 1000) end;
        l_per(l_n).ini    := r.dt_efetiva;
        l_aberto := true;
      end if;
    end loop;

    if l_aberto then
      l_per(l_n).atual := true;
    elsif l_n = 0 then
      -- Quem ainda não tem histórico mostra o cargo atual, desde a admissão
      l_n := 1;
      l_per(1).cargo := p_c.cargo;
      l_per(1).depto := p_c.departamento;
      l_per(1).ini   := p_c.data_admissao;
      l_per(1).atual := true;
    end if;

    l_cargo_ini := l_per(1).cargo;

    p('<div class="perfil-tab-conteudo is-active" id="tab-trajetoria" role="tabpanel">');
    p('<ul class="perfil-timeline">');

    for i in reverse 1 .. l_n loop
      p('<li class="perfil-timeline__item">');
      p('<div class="perfil-timeline__ponto' || case when l_per(i).atual then ' is-atual' end || '"></div>');
      p('<div class="perfil-timeline__corpo">');
      p('<div class="perfil-timeline__cab">');
      p('<strong class="perfil-timeline__titulo">' || e(l_per(i).cargo) || '</strong>');
      if l_per(i).atual then
        p('<span class="perfil-tag perfil-tag--atual">Atual</span>');
      end if;
      if l_per(i).tipo is not null then
        p('<span class="perfil-tag">' || e(l_per(i).tipo) || '</span>');
      end if;
      p('</div>');
      if l_per(i).ini is not null then
        p('<p class="perfil-timeline__sub">'
          || case when l_per(i).depto is not null then e(l_per(i).depto) || ' &middot; ' end
          || mes_ano(l_per(i).ini)
          || case when l_per(i).atual then ' &ndash; atual' else ' &ndash; ' || mes_ano(l_per(i).fim) end
          || ' &middot; ' || duracao(l_per(i).ini, case when l_per(i).atual then l_hoje else l_per(i).fim end) || '</p>');
      end if;
      if l_per(i).motivo is not null then
        p('<p class="perfil-timeline__desc">' || e(l_per(i).motivo) || '</p>');
      end if;
      p('</div>');
      p('</li>');
    end loop;

    p('<li class="perfil-timeline__item">');
    p('<div class="perfil-timeline__ponto"></div>');
    p('<div class="perfil-timeline__corpo">');
    p('<div class="perfil-timeline__cab"><strong class="perfil-timeline__titulo">Entrada na ' || e(p_nome_curto) || '</strong></div>');
    if p_c.data_admissao is not null then
      p('<p class="perfil-timeline__sub">' || to_char(p_c.data_admissao, 'fmdd "de" month "de" yyyy', 'NLS_DATE_LANGUAGE=''BRAZILIAN PORTUGUESE''') || '</p>');
    end if;
    p('<p class="perfil-timeline__desc">Início como ' || e(l_cargo_ini) || '.</p>');
    p('</div>');
    p('</li>');

    p('</ul>');
    p('</div>');
  end render_trajetoria;

  procedure dado (p_rotulo in varchar2, p_valor in varchar2, p_restrito in boolean default false) is
  begin
    p('<div class="perfil-dado-item"><span class="perfil-dado-label">' || p_rotulo
      || case when p_restrito then c_ico_cadeado end
      || '</span><span class="perfil-dado-valor">' || nvl(p_valor, '&mdash;') || '</span></div>');
  end dado;

  procedure render_dados (
    p_c            in vw_org_colaborador%rowtype,
    p_nome_empresa in varchar2,
    p_nome_gestor  in varchar2
  ) is
  begin
    p('<div class="perfil-tab-conteudo" id="tab-dados-pessoais" role="tabpanel">');
    p('<div class="perfil-dados-grid">');
    dado('Nome completo', e(p_c.nome_completo));
    dado('E-mail corporativo', e(p_c.email));
    dado('Data de nascimento', to_char(p_c.data_de_nascimento, 'dd/mm/yyyy'), true);
    dado('Login', e(p_c.login_apex), true);
    dado('Empresa', e(p_nome_empresa));
    dado('Departamento', e(p_c.departamento));
    dado('Cargo', e(p_c.cargo));
    dado('Gestor direto', e(p_nome_gestor));
    dado('Data de admissão', to_char(p_c.data_admissao, 'dd/mm/yyyy'));
    p('</div>');
    p('<p class="perfil-nota">' || c_ico_cadeado || '<span>Visível só para você, sua linha de gestão e a administração. Colegas veem apenas dia e mês do aniversário.</span></p>');
    p('<div class="perfil-alerta">' || c_ico_info || '<div><strong>Esses dados são mantidos pela administração.</strong><br>Encontrou algo errado? Fale com o RH. A foto pode ser alterada por você, pelo avatar.</div></div>');
    p('</div>');
  end render_dados;

  procedure render_pessoa (p_c in vw_org_colaborador%rowtype) is
  begin
    p('<div class="perfil-pessoa-row">');
    p(avatar_perfil(p_c.nome_completo, p_c.foto_url, 'md'));
    p('<div class="perfil-pessoa-row__info">');
    p('<a href="' || url_perfil(p_c.id_colaborador) || '">' || e(p_c.nome_completo) || '</a>');
    p('<span>' || e(p_c.cargo) || '</span>');
    p('</div>');
    p('</div>');
  end render_pessoa;

  function render (
    p_id_colaborador in number default null
  ) return clob is
    l_c            vw_org_colaborador%rowtype;
    l_eu           number;
    l_gestor       vw_org_colaborador%rowtype;
    l_tem_gestor   boolean := false;
    l_completo     boolean;
    l_nome_empresa empresa.nome%type;
    l_nome_curto   empresa.nome_fantasia%type;
    l_qt_colegas   pls_integer := 0;
    l_mostrados    pls_integer := 0;
    l_emp          constant number := empresa_sessao;  -- função privada não pode ser chamada dentro de SQL
  begin
    inicia;

    if not carrega(p_id_colaborador, l_c, l_eu) then
      p('<div class="perfil-vazio"><p>Colaborador não encontrado.</p></div>');
      return g_html;
    end if;

    -- A própria pessoa, a linha de gestão e o RH (mesma regra do histórico de carreira)
    l_completo := pkg_historico_carreira.fn_pode_ver_colaborador(l_c.id_colaborador) = 'S';

    select nome, nome_fantasia
      into l_nome_empresa, l_nome_curto
      from empresa
     where id_empresa = l_emp;

    if l_c.id_gestor is not null then
      begin
        select * into l_gestor from vw_org_colaborador where id_colaborador = l_c.id_gestor;
        l_tem_gestor := true;
      exception
        when no_data_found then l_tem_gestor := false;
      end;
    end if;

    p('<div class="perfil-grid-principal">');

    -- COLUNA PRINCIPAL
    p('<div class="perfil-coluna-esquerda perfil-card">');
    if l_completo then
      p('<div class="perfil-tabs" role="tablist">');
      p('<button type="button" class="perfil-tab-btn is-active" role="tab" data-tab="trajetoria">Trajetória</button>');
      p('<button type="button" class="perfil-tab-btn" role="tab" data-tab="dados-pessoais">Dados pessoais</button>');
      p('</div>');
      render_trajetoria(l_c, l_nome_curto, l_emp);
      render_dados(l_c, l_nome_empresa, case when l_tem_gestor then l_gestor.nome_completo end);
    else
      p('<p class="perfil-nota perfil-nota--bloco">' || c_ico_cadeado || '<span>A trajetória e os dados pessoais ficam visíveis só para a própria pessoa, a gestão e o RH.</span></p>');
    end if;
    p('</div>');

    -- COLUNA LATERAL
    p('<aside class="perfil-coluna-direita">');

    p('<section class="perfil-card">');
    p('<h2 class="perfil-card__titulo">Gestor direto</h2>');
    p('<div class="perfil-card__corpo">');
    if l_tem_gestor then
      render_pessoa(l_gestor);
      p('<div class="perfil-card__acoes">');
      p('<a class="perfil-btn" href="' || e(apex_page.get_url(p_page => c_pagina_chat)) || '">' || c_ico_chat || '<span>Conversar</span></a>');
      p('<a class="perfil-btn" href="' || e(apex_page.get_url(p_page => c_pagina_organograma, p_items => c_item_organograma, p_values => to_char(l_gestor.id_colaborador))) || '">' || c_ico_org || '<span>Organograma</span></a>');
      p('</div>');
    else
      p('<p class="perfil-vazio-texto">Esta pessoa ocupa o topo da hierarquia.</p>');
    end if;
    p('</div>');
    p('</section>');

    p('<section class="perfil-card">');
    p('<h2 class="perfil-card__titulo">Colegas de equipe</h2>');
    p('<div class="perfil-card__corpo">');
    if l_c.id_gestor is not null then
      select count(*)
        into l_qt_colegas
        from vw_org_colaborador
       where id_gestor = l_c.id_gestor
         and id_colaborador <> l_c.id_colaborador;

      for col in (select * from vw_org_colaborador
                   where id_gestor = l_c.id_gestor
                     and id_colaborador <> l_c.id_colaborador
                   order by nome_completo
                   fetch first c_max_colegas rows only)
      loop
        render_pessoa(col);
        l_mostrados := l_mostrados + 1;
      end loop;
    end if;

    if l_qt_colegas = 0 then
      p('<p class="perfil-vazio-texto">Sem colegas no mesmo nível.</p>');
    else
      if l_qt_colegas > l_mostrados then
        p('<a class="perfil-card__mais" href="' || e(apex_page.get_url(p_page => c_pagina_organograma, p_items => c_item_organograma, p_values => to_char(l_c.id_gestor))) || '">e mais ' || (l_qt_colegas - l_mostrados) || ' na equipe</a>');
      end if;
      p('<p class="perfil-card__rodape">Pessoas com o mesmo gestor direto.</p>');
    end if;
    p('</div>');
    p('</section>');

    p('</aside>');
    p('</div>');

    return g_html;
  end render;

  function render_drawer_foto (p_id_colaborador in number) return clob is
    l_eu constant number := id_logado(empresa_sessao);
    l_c  vw_org_colaborador%rowtype;
  begin
    inicia;

    p('<div class="perfil-modal-inner">');
    p('<header class="perfil-modal-cab">');
    p('<h2>Foto de perfil</h2>');
    p('<button type="button" class="perfil-modal-fechar" data-acao="fechar-foto" aria-label="Fechar">&times;</button>');
    p('</header>');

    -- Só a própria pessoa troca a foto. O JS manda 0 no próprio perfil.
    if l_eu is null or nvl(nullif(p_id_colaborador, 0), l_eu) <> l_eu then
      p('<div class="perfil-modal-corpo">');
      p('<p class="perfil-modal-instrucoes">Só a própria pessoa pode alterar a foto de perfil.</p>');
      p('</div>');
      p('</div>');
      return g_html;
    end if;

    select * into l_c from vw_org_colaborador where id_colaborador = l_eu;

    p('<div class="perfil-modal-corpo">');
    p('<div class="perfil-modal-avatar">');
    p(avatar_perfil(l_c.nome_completo, l_c.foto_url, 'xl'));
    p('</div>');
    p('<p class="perfil-modal-instrucoes">JPG ou PNG, até 5 MB. A foto aparece no cabeçalho, em Colaboradores, no Organograma e em Aniversariantes.</p>');
    p('<label for="input-foto-upload" class="perfil-btn">' || c_ico_camera || '<span>Escolher foto</span></label>');
    p('<input type="file" id="input-foto-upload" accept="image/png, image/jpeg" class="perfil-modal-arquivo">');
    p('<div class="perfil-alerta">' || c_ico_info || '<div><strong>Nome, cargo, departamento e e-mail são mantidos pela administração.</strong><br>Encontrou algo errado? Fale com o RH.</div></div>');
    p('</div>');

    p('<footer class="perfil-modal-rodape">');
    p('<button type="button" class="perfil-btn" data-acao="fechar-foto">Cancelar</button>');
    p('<button type="button" class="perfil-btn perfil-btn--primario">Salvar foto</button>');
    p('</footer>');
    p('</div>');

    return g_html;
  end render_drawer_foto;

end pkg_perfil;
/
