-- =============================================================================
-- Corlix Hub · Perfil (página 2): corpo do PKG_PERFIL com restrição de acesso
-- A especificação não muda. Guia: Etapas-perfil-privacidade.md
-- Depende de: PKG_HISTORICO_CARREIRA, PKG_ORGANOGRAMA, VW_ORG_COLABORADOR, COLABORADOR,
-- COLABORADOR_TRAJETORIA e do item de aplicação G_ID_EMPRESA.
-- =============================================================================
create or replace package body pkg_perfil as

  g_html clob;

  procedure inicia is
  begin
    if g_html is not null then
      dbms_lob.freetemporary(g_html);
    end if;
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

  -- Gera o avatar sem nenhuma dependência do PKG_ORGANOGRAMA
  function avatar_perfil (
    p_nome     in varchar2,
    p_foto_url in varchar2,
    p_tamanho  in varchar2 default 'lg'
  ) return varchar2 is
    l_iniciais varchar2(10);
    l_nome_foto varchar2(255);
  begin
    -- Extrai iniciais (Ex: Amanda Nunes -> AN)
    l_iniciais := upper(substr(p_nome, 1, 1) ||
                  case when instr(p_nome, ' ') > 0 then
                    substr(p_nome, instr(p_nome, ' ', -1) + 1, 1)
                  end);

    l_nome_foto := trim(p_foto_url);
    if l_nome_foto like 'Fotos Colaboradores/%' then
      l_nome_foto := substr(l_nome_foto, 21);
    end if;

    return '<span class="perfil-avatar perfil-avatar--' || p_tamanho || '">'
        || '  <span class="perfil-avatar__iniciais">' || e(l_iniciais) || '</span>'
        || case when l_nome_foto is not null then
             '  <img data-perfil-foto="' || e(l_nome_foto) || '" alt="" loading="lazy" onerror="this.remove()">'
           end
        || '</span>';
  end avatar_perfil;

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

  function render (
    p_id_colaborador in number default null
  ) return clob is
    l_emp        constant number := empresa_sessao;
    l_eu         constant number := id_logado(l_emp);
    -- O JS e os links podem mandar vazio ou 0 no próprio perfil
    l_id         constant number := nvl(nullif(p_id_colaborador, 0), l_eu);
    l_c          vw_org_colaborador%rowtype;
    l_gestor     vw_org_colaborador%rowtype;
    l_tem_gestor boolean := false;
    l_e_proprio  boolean;
    l_completo   boolean;
  begin
    inicia;

    -- Outra empresa recebe a mesma mensagem de um ID inexistente
    if l_id is null or not e_da_empresa(l_id, l_emp) then
      p('<div class="perfil-vazio"><p>Colaborador não encontrado.</p></div>');
      return g_html;
    end if;

    begin
      select * into l_c from vw_org_colaborador where id_colaborador = l_id;
    exception
      when no_data_found then
        p('<div class="perfil-vazio"><p>Colaborador não encontrado.</p></div>');
        return g_html;
    end;

    l_e_proprio := l_id = l_eu;
    -- A própria pessoa, a linha de gestão e o RH (mesma regra do histórico de carreira)
    l_completo  := pkg_historico_carreira.fn_pode_ver_colaborador(l_id) = 'S';

    if l_c.id_gestor is not null then
      begin
        select * into l_gestor from vw_org_colaborador where id_colaborador = l_c.id_gestor;
        l_tem_gestor := true;
      exception
        when no_data_found then l_tem_gestor := false;
      end;
    end if;

    p('<div class="perfil-layout">');

    -- HEADER SUPERIOR
    p('<header class="perfil-header">');
    p('  <div class="perfil-header__avatar">');
    p(avatar_perfil(l_c.nome_completo, l_c.foto_url, 'lg'));
    if l_e_proprio then
      p('    <button type="button" class="perfil-header__cam" data-acao="abrir-foto-drawer" title="Alterar foto">');
      p('      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14.5 4h-5L7 7H4a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2h-3l-2.5-3z"/><circle cx="12" cy="13" r="3"/></svg>');
      p('    </button>');
    end if;
    p('  </div>');

    p('  <div class="perfil-header__info">');
    p('    <h1>' || e(l_c.nome_completo) || '</h1>');
    p('    <p class="perfil-header__cargo">' || e(l_c.cargo) || ' &middot; ' || e(l_c.departamento) || '</p>');
    p('    <div class="perfil-header__metas">');
    p('      <span><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg> Na Corlix desde ' || pkg_organograma.tempo_de_casa(l_c.data_admissao) || '</span>');
    p('      <a href="mailto:' || e(l_c.email) || '"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect width="20" height="16" x="2" y="4" rx="2"/><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/></svg> ' || e(l_c.email) || '</a>');
    p('    </div>');
    p('  </div>');

    if l_e_proprio then
      p('  <button type="button" class="perfil-btn-alterar-foto" data-acao="abrir-foto-drawer">');
      p('    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14.5 4h-5L7 7H4a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2h-3l-2.5-3z"/><circle cx="12" cy="13" r="3"/></svg> Alterar foto');
      p('  </button>');
    end if;
    p('</header>');

    -- DASHBOARD PRINCIPAL
    p('<div class="perfil-grid-principal">');

    -- COLUNA ESQUERDA
    p('  <div class="perfil-coluna-esquerda">');
    if l_completo then
      p('    <div class="perfil-tabs">');
      p('      <button type="button" class="perfil-tab-btn is-active" data-tab="trajetoria">Trajetória</button>');
      p('      <button type="button" class="perfil-tab-btn" data-tab="dados-pessoais">Dados pessoais</button>');
      p('    </div>');

      -- ABA 1: TRAJETÓRIA
      p('    <div class="perfil-tab-conteudo is-active" id="tab-trajetoria">');
      p('      <ul class="perfil-timeline">');

      for t in (select * from colaborador_trajetoria
                 where id_colaborador = l_c.id_colaborador
                 order by data_inicio desc)
      loop
        p('        <li class="perfil-timeline__item">');
        p('          <div class="perfil-timeline__ponto ' || case when t.status_atual = 'S' then 'is-atual' end || '"></div>');
        p('          <div class="perfil-timeline__corpo">');
        p('            <div class="perfil-timeline__cab">');
        p('              <strong class="perfil-timeline__titulo">' || e(t.titulo_evento) || '</strong>');
        if t.status_atual = 'S' then
          p('              <span class="perfil-tag perfil-tag--atual">Atual</span>');
        end if;
        p('            </div>');
        p('            <p class="perfil-timeline__sub">' || e(t.departamento) || ' &middot; ' || to_char(t.data_inicio, 'mm/yyyy') || case when t.data_fim is not null then ' - ' || to_char(t.data_fim, 'mm/yyyy') else ' - atual' end || '</p>');
        if t.descricao is not null then
          p('            <p class="perfil-timeline__desc">' || e(t.descricao) || '</p>');
        end if;
        p('          </div>');
        p('        </li>');
      end loop;

      p('        <li class="perfil-timeline__item">');
      p('          <div class="perfil-timeline__ponto"></div>');
      p('          <div class="perfil-timeline__corpo">');
      p('            <strong class="perfil-timeline__titulo">Entrada na Corlix</strong>');
      p('            <p class="perfil-timeline__sub">' || to_char(l_c.data_admissao, 'dd "de" fmmonth "de" yyyy', 'NLS_DATE_LANGUAGE=''BRAZILIAN PORTUGUESE''') || '</p>');
      p('            <p class="perfil-timeline__desc">Início como ' || e(l_c.cargo) || '.</p>');
      p('          </div>');
      p('        </li>');

      p('      </ul>');
      p('    </div>');

      -- ABA 2: DADOS PESSOAIS
      p('    <div class="perfil-tab-conteudo" id="tab-dados-pessoais">');
      p('      <div class="perfil-dados-grid">');
      p('        <div class="perfil-dado-item"><span class="perfil-dado-label">Nome completo</span><span class="perfil-dado-valor">' || e(l_c.nome_completo) || '</span></div>');
      p('        <div class="perfil-dado-item"><span class="perfil-dado-label">E-mail corporativo</span><span class="perfil-dado-valor">' || e(l_c.email) || '</span></div>');
      p('        <div class="perfil-dado-item"><span class="perfil-dado-label">Data de nascimento</span><span class="perfil-dado-valor">' || nvl(to_char(l_c.data_de_nascimento, 'dd/mm/yyyy'), '&mdash;') || '</span></div>');
      p('        <div class="perfil-dado-item"><span class="perfil-dado-label">Login</span><span class="perfil-dado-valor">' || e(l_c.login_apex) || '</span></div>');
      p('        <div class="perfil-dado-item"><span class="perfil-dado-label">Empresa</span><span class="perfil-dado-valor">Corlix</span></div>');
      p('        <div class="perfil-dado-item"><span class="perfil-dado-label">Departamento</span><span class="perfil-dado-valor">' || e(l_c.departamento) || '</span></div>');
      p('        <div class="perfil-dado-item"><span class="perfil-dado-label">Cargo</span><span class="perfil-dado-valor">' || e(l_c.cargo) || '</span></div>');
      p('        <div class="perfil-dado-item"><span class="perfil-dado-label">Gestor direto</span><span class="perfil-dado-valor">' || case when l_tem_gestor then e(l_gestor.nome_completo) else 'Topo da hierarquia' end || '</span></div>');
      p('        <div class="perfil-dado-item"><span class="perfil-dado-label">Data de admissão</span><span class="perfil-dado-valor">' || nvl(to_char(l_c.data_admissao, 'dd/mm/yyyy'), '&mdash;') || '</span></div>');
      p('      </div>');
      p('    </div>');
    else
      p('    <p class="perfil-vazio-texto">A trajetória e os dados pessoais ficam visíveis só para a própria pessoa, a gestão e o RH.</p>');
    end if;

    p('  </div>');

    -- COLUNA DIREITA
    p('  <aside class="perfil-coluna-direita">');

    p('    <div class="perfil-card-sidebar">');
    p('      <h3 class="perfil-card-sidebar__titulo">Gestor direto</h3>');
    if l_tem_gestor then
      p('      <div class="perfil-pessoa-row">');
      p(avatar_perfil(l_gestor.nome_completo, l_gestor.foto_url, 'md'));
      p('        <div class="perfil-pessoa-row__info">');
      p('          <strong>' || e(l_gestor.nome_completo) || '</strong>');
      p('          <span>' || e(l_gestor.cargo) || '</span>');
      p('        </div>');
      p('      </div>');
    else
      p('      <p class="perfil-vazio-texto">Esta pessoa ocupa o topo da hierarquia.</p>');
    end if;
    p('    </div>');

    p('    <div class="perfil-card-sidebar">');
    p('      <h3 class="perfil-card-sidebar__titulo">Colegas de equipe</h3>');
    if l_c.id_gestor is not null then
      for col in (select * from vw_org_colaborador
                   where id_gestor = l_c.id_gestor
                     and id_colaborador <> l_c.id_colaborador
                   order by nome_completo)
      loop
        p('      <div class="perfil-pessoa-row">');
        p(avatar_perfil(col.nome_completo, col.foto_url, 'md'));
        p('        <div class="perfil-pessoa-row__info">');
        p('          <strong>' || e(col.nome_completo) || '</strong>');
        p('          <span>' || e(col.cargo) || '</span>');
        p('        </div>');
        p('      </div>');
      end loop;
    else
      p('      <p class="perfil-vazio-texto">Sem colegas no mesmo nível.</p>');
    end if;
    p('    </div>');

    p('  </aside>');
    p('</div>');
    p('</div>');

    return g_html;
  end render;

  function render_drawer_foto (p_id_colaborador in number) return clob is
    l_eu constant number := id_logado(empresa_sessao);
    l_c  vw_org_colaborador%rowtype;
  begin
    inicia;

    -- Só a própria pessoa troca a foto. O JS manda 0 no próprio perfil.
    if l_eu is null or nvl(nullif(p_id_colaborador, 0), l_eu) <> l_eu then
      p('<div class="perfil-modal-inner">');
      p('  <header class="perfil-modal-cab">');
      p('    <h2>Foto de perfil</h2>');
      p('    <button type="button" class="perfil-modal-fechar" data-acao="fechar-foto">&times;</button>');
      p('  </header>');
      p('  <div class="perfil-modal-corpo">');
      p('    <p class="perfil-modal-instrucoes">Só a própria pessoa pode alterar a foto de perfil.</p>');
      p('  </div>');
      p('</div>');
      return g_html;
    end if;

    select * into l_c from vw_org_colaborador where id_colaborador = l_eu;

    p('<div class="perfil-modal-inner">');
    p('  <header class="perfil-modal-cab">');
    p('    <h2>Foto de perfil</h2>');
    p('    <button type="button" class="perfil-modal-fechar" data-acao="fechar-foto">&times;</button>');
    p('  </header>');

    p('  <div class="perfil-modal-corpo">');
    p('    <div class="perfil-modal-avatar">');
    p(avatar_perfil(l_c.nome_completo, l_c.foto_url, 'lg'));
    p('    </div>');
    p('    <p class="perfil-modal-instrucoes">JPG ou PNG, até 5 MB. A foto aparecerá no seu perfil e no organograma.</p>');
    p('    <label for="input-foto-upload" class="perfil-btn-upload">Escolher foto</label>');
    p('    <input type="file" id="input-foto-upload" accept="image/png, image/jpeg" style="display:none;">');
    p('  </div>');

    p('  <footer class="perfil-modal-rodape">');
    p('    <button type="button" class="perfil-btn-secundario" data-acao="fechar-foto">Cancelar</button>');
    p('    <button type="button" class="perfil-btn-primario">Salvar foto</button>');
    p('  </footer>');
    p('</div>');

    return g_html;
  end render_drawer_foto;

end pkg_perfil;
/
