--------------------------------------------------------------------------------
-- Corlix Hub · Suporte TI · 04 · HTML e callbacks · especificação
-- Protótipo: pen_dev/Suporte TI.png. Classes cx-sup-* em suporte.css.
--
-- Tudo usa a conta logada e a empresa da sessão; nenhuma função recebe o
-- colaborador da URL. Conta sem colaborador: render_ajuda mostra o aviso e as
-- outras regiões não mostram nada.
--------------------------------------------------------------------------------
create or replace package pkg_suporte_ui authid definer as

  -- Página 34 · Suporte TI
  function render_cabecalho return clob;
  function render_aviso return clob;
  function render_ajuda return clob;
  function render_chamados return clob;
  function render_status return clob;
  function render_artigos return clob;
  function render_contato return clob;

  -- Páginas 36 e 39: resumo do chamado e conversa, com os anexos.
  function render_conversa (p_id_chamado in number) return clob;

  -- Página 37 · Base de conhecimento. Com p_id_artigo mostra o artigo; sem ele,
  -- os artigos do assunto ou, sem assunto, todos, agrupados.
  function render_base (p_id_assunto in number default null, p_id_artigo in number default null) return clob;

  -- Ajax Callbacks da página 34. Respondem {"ok":true|false,"mensagem":"..."}.
  -- ajax_buscar responde também "html", com os artigos encontrados.
  procedure ajax_buscar (p_termo in varchar2);
  procedure ajax_confirmar (p_id_chamado in number);

end pkg_suporte_ui;
/
