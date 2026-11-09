-- Padrão de UI de Holerite/Ponto: CLOB e renderização centralizada.
-- A lista e as facetas continuam nos componentes nativos do APEX.
create or replace package body pkg_colaboradores_ui as
  function render_cabecalho return clob is
    l_html clob;

    procedure p(p_texto in varchar2) is
    begin
      if p_texto is not null then
        dbms_lob.writeappend(l_html, length(p_texto), p_texto);
      end if;
    end p;
  begin
    dbms_lob.createtemporary(l_html, true, dbms_lob.call);
    p('<div class="cx-cabecalho-pagina cx-cabecalho-pagina--acoes">');
    p('<div class="cx-cabecalho-pagina__texto">');
    p('<h1 class="cx-cabecalho-pagina__titulo">Colaboradores</h1>');
    p('<p class="cx-cabecalho-pagina__descricao">Encontre pessoas e gerencie contas, vínculos e perfis de acesso.</p></div>');

    -- Mesma autorização exigida pela página 14; não restringe a consulta da p12.
    if apex_authorization.is_authorized('ADMIN_RH') then
      p('<div class="cx-cabecalho-pagina__acoes">');
      p('<a class="t-Button t-Button--hot t-Button--iconLeft" href="'
        || apex_escape.html_attribute(apex_page.get_url(p_page => 14, p_clear_cache => '14'))
        || '">');
      -- O tema mapeia fa-plus para a fonte Lucide já instalada.
      p('<span class="t-Icon t-Icon--left fa fa-plus" aria-hidden="true"></span>');
      p('<span class="t-Button-label">Novo colaborador</span></a></div>');
    end if;

    p('</div>');
    return l_html;
  exception
    when others then
      if dbms_lob.istemporary(l_html) = 1 then
        dbms_lob.freetemporary(l_html);
      end if;
      raise;
  end render_cabecalho;

  -- Cabeçalho da página 14: criação (sem ID) ou edição (nome, situação, login e e-mail).
  function render_cabecalho_cadastro (p_id_colaborador in number) return clob is
    l_nome   colaborador.nome_completo%type;
    l_login  colaborador.login_apex%type;
    l_email  colaborador.email%type;
    l_ativo  pls_integer;
    l_trilha varchar2(4000);
    l_titulo varchar2(4000);
    l_desc   varchar2(4000);

    function escapar (p_texto in varchar2) return varchar2 is
    begin
      return apex_escape.html(p_texto);
    end escapar;
  begin
    if p_id_colaborador is null then
      l_trilha := 'Novo colaborador';
      l_titulo := 'Novo colaborador';
      l_desc   := 'Preencha os dados pessoais, o vínculo profissional e o acesso ao CorlixHub.';
    else
      select nome_completo, login_apex, email, case when status = true then 1 else 0 end
        into l_nome, l_login, l_email, l_ativo
        from colaborador
       where id_colaborador = p_id_colaborador
         and id_empresa = to_number(v('G_ID_EMPRESA') default null on conversion error);

      l_trilha := escapar(l_nome);
      l_titulo := escapar(l_nome)
        || case when l_ativo = 1
             then ' <span class="cx-badge cx-badge--sucesso">Ativa</span>'
             else ' <span class="cx-badge cx-badge--neutro">Inativa</span>'
           end;
      l_desc   := escapar(l_login) || ' · ' || escapar(l_email);
    end if;

    return to_clob('<div class="cx-cabecalho-pagina">')
      || '<nav class="cx-cabecalho-pagina__trilha" aria-label="Trilha de navegação">'
      || '<a href="' || apex_escape.html_attribute(apex_page.get_url(p_page => 12)) || '">Colaboradores</a>'
      || '<span class="fa fa-chevron-right" aria-hidden="true"></span>'
      || '<span aria-current="page">' || l_trilha || '</span></nav>'
      || '<h1 class="cx-cabecalho-pagina__titulo">' || l_titulo || '</h1>'
      || '<p class="cx-cabecalho-pagina__descricao">' || l_desc || '</p></div>';
  exception
    when no_data_found then
      return to_clob('<div class="cx-cabecalho-pagina"><h1 class="cx-cabecalho-pagina__titulo">Colaborador não encontrado</h1></div>');
  end render_cabecalho_cadastro;
end pkg_colaboradores_ui;
/
