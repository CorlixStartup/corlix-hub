--------------------------------------------------------------------------------
-- Corlix Hub · Login (página 9999) · HTML das regiões · corpo
-- Decisões da usuária em 09/11/2026: "Esqueci minha senha" mostra orientação;
-- "Primeiro acesso" diz só o que o sistema faz hoje; o Suporte TI aparece em
-- texto, sem link, porque a página 34 exige login.
--------------------------------------------------------------------------------
create or replace package body pkg_login_ui as

  g_html clob;

  ------------------------------------------------------------------------------
  -- Utilitários (mesma base do pkg_holerite_ui)
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

  function icone (p_nome in varchar2) return varchar2 is
    l_svg varchar2(1000);
  begin
    l_svg := case p_nome
      when 'info' then '<circle cx="12" cy="12" r="10"/><path d="M12 16v-4"/><path d="M12 8h.01"/>'
    end;
    return '<svg class="cx-login-icone" width="20" height="20" viewBox="0 0 24 24" aria-hidden="true" focusable="false">'
        || l_svg || '</svg>';
  end icone;

  ------------------------------------------------------------------------------
  -- Regiões
  ------------------------------------------------------------------------------
  function render_cabecalho return clob is
  begin
    inicia;
    p('<div class="cx-login-topo">');
    p('<p class="cx-login-marca">' || e('CorlixHub') || '</p>');
    p('<h1 class="cx-login-titulo">' || e('Acesse sua conta') || '</h1>');
    p('<p class="cx-login-descricao">'
      || e('Entre com seu login corporativo ou e-mail e a sua senha.') || '</p>');
    p('</div>');
    return g_html;
  end render_cabecalho;

  function render_primeiro_acesso return clob is
  begin
    inicia;
    p('<div class="cx-login-aviso">');
    p(icone('info'));
    p('<div>');
    p('<p class="cx-login-aviso__titulo">' || e('Primeiro acesso?') || '</p>');
    p('<p class="cx-login-aviso__texto">'
      || e('Entre com a senha que o RH enviou. Em caso de dúvida, procure o RH.') || '</p>');
    p('</div>');
    p('</div>');
    return g_html;
  end render_primeiro_acesso;

  function render_esqueci return clob is
  begin
    inicia;
    p('<div class="cx-login-esqueci-texto">');
    p('<p>' || e('Por segurança, a senha não é redefinida por esta tela.') || '</p>');
    p('<p>' || e('Peça a redefinição ao RH ou ao Suporte TI da sua empresa. '
              || 'Você recebe uma nova senha para entrar.') || '</p>');
    p('</div>');
    return g_html;
  end render_esqueci;

  function render_rodape return clob is
    l_ano varchar2(4) := to_char(systimestamp at time zone 'America/Sao_Paulo', 'yyyy');
  begin
    inicia;
    p('<div class="cx-login-rodape">');
    p('<p>' || e('Problemas para entrar? Procure o Suporte TI ou o RH.') || '</p>');
    p('<p>' || e('© ' || l_ano || ' Corlix') || '</p>');
    p('</div>');
    return g_html;
  end render_rodape;

  function render_destaque return clob is
  begin
    inicia;
    p('<aside class="cx-login-destaque" aria-label="' || e('Sobre o CorlixHub') || '">');
    p('<p class="cx-login-destaque__selo">' || e('Intranet Corlix') || '</p>');
    p('<p class="cx-login-destaque__titulo">'
      || e('Comunicados, holerite, ponto e a sua carreira em um só lugar.') || '</p>');
    p('<p class="cx-login-destaque__texto">'
      || e('Um único acesso para tudo o que você usa no dia a dia.') || '</p>');
    p('</aside>');
    return g_html;
  end render_destaque;

end pkg_login_ui;
/
