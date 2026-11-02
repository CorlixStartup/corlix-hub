--------------------------------------------------------------------------------
-- Corlix Hub · Ponto eletrônico (página 30) · 04 · HTML e callbacks · especificação
-- Protótipo: pen_dev/Ponto eletrônico.png. Classes cx-ponto-* em ponto.css.
--
-- Sem p_id_colaborador, cada função usa o colaborador da conta logada. O parâmetro
-- só existe para testar no SQL Commands; a página nunca o recebe da URL.
-- Conta sem colaborador: render_relogio mostra o aviso e as outras não mostram nada.
--
-- p_competencia é o mês em YYYYMM (P30_COMPETENCIA). Vazio = mês atual.
--------------------------------------------------------------------------------
create or replace package pkg_ponto_ui authid definer as

  -- Título, descrição e botões "Baixar espelho" e "Solicitar ajuste"
  function render_cabecalho (p_id_colaborador in number default null) return clob;

  -- Relógio, botão de registrar, linha do tempo do dia e horas trabalhadas
  function render_relogio (p_id_colaborador in number default null) return clob;

  -- p_limite: últimos N dias (nulo = mês inteiro). p_completo = 'S' mostra o
  -- seletor de mês e o link "Ver mês completo".
  function render_espelho (
    p_competencia    in varchar2 default null,
    p_limite         in pls_integer default 7,
    p_completo       in varchar2 default 'S',
    p_id_colaborador in number default null
  ) return clob;

  function render_banco (p_id_colaborador in number default null) return clob;

  function render_pendencias (p_id_colaborador in number default null) return clob;

  function render_jornada (p_id_colaborador in number default null) return clob;

  -- Conteúdo dos diálogos
  function render_comprovantes (p_id_colaborador in number default null) return clob;

  function render_extrato (p_id_colaborador in number default null) return clob;

  function render_assinatura (p_id_colaborador in number default null) return clob;

  -- Ajax Callbacks da página 30. Respondem {"ok":true|false,"mensagem":"..."}.
  procedure ajax_registrar (p_tp_marcacao in varchar2);

  procedure ajax_assinar (p_competencia in varchar2);

  -- Responde também "nome" e "conteudo" (CSV separado por ponto e vírgula)
  procedure ajax_baixar_espelho (p_competencia in varchar2);

end pkg_ponto_ui;
/
