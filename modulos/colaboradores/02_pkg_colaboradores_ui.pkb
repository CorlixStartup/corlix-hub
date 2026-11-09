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
end pkg_colaboradores_ui;
/
