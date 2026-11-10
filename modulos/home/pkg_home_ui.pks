--------------------------------------------------------------------------------
-- Corlix Hub · Home (página 1, "Início") · especificação
-- HTML das regiões Dynamic Content da Home (protótipo pen_dev/Início.png):
--   render_hero            -> "Boa tarde, <nome>", data por extenso, links rápidos
--                             e o painel "Ponto de hoje" (guia §7)
--   render_indicadores     -> faixa de indicadores; hoje só o banco de horas (guia §7)
--   render_pendencias      -> "Suas pendências"; hoje só as do ponto (guia §7)
--   render_meu_gestor      -> card "Meu gestor": presença, próxima 1:1, Mensagem e Dar feedback
--   render_feedbacks       -> "Feedbacks recebidos" (os 2 mais recentes)
--   render_pesquisa        -> pesquisa de clima aberta e ainda não respondida
--   render_eventos         -> "Próximos eventos" (agenda + feriados do ponto)
--   qt_pendencias / nao_lidos_texto -> números dos títulos das regiões (computações)
--   ajax_*                 -> Ajax Callbacks da página 1 ({"ok":...,"mensagem":...})
--   render_celebracoes     -> aniversários e tempo de empresa do mês (card e diálogo)
--   render_aniversariantes -> versão anterior (só aniversários); fica até a
--                             página trocar para render_celebracoes (guia §6)
--   mes_atual              -> "outubro" (título "Celebrações de ...")
-- Login e empresa vêm da sessão (APP_USER, G_ID_EMPRESA) quando não informados.
-- Depende de: pkg_ponto (modulos/ponto-eletronico), pkg_comunicado, tabelas de
-- modulos/home-blocos (feedback, pesquisa, evento, conversa_1a1, ferias_periodo,
-- pdi) e colaborador_holerite. Instale esses antes deste package.
-- Sem p_id_colaborador, vale o colaborador da conta logada; o parâmetro só existe
-- para testar no SQL Commands e a página nunca o recebe da URL.
--------------------------------------------------------------------------------
create or replace package pkg_home_ui authid definer as

  function mes_atual return varchar2;

  -- Conta sem colaborador ou empresa sem jornada: hero sem o painel do ponto
  function render_hero (
    p_login          in varchar2 default v('APP_USER'),
    p_id_colaborador in number   default null
  ) return clob;

  -- Banco de horas. Conta sem colaborador: não devolve nada.
  function render_indicadores (
    p_id_colaborador in number default null
  ) return clob;

  -- Marcações ausentes e faltas dos últimos 30 dias, espelho a assinar e, para
  -- quem aprova (APROVADOR_PONTO), os pedidos de ajuste aguardando resposta.
  function render_pendencias (
    p_id_colaborador in number default null
  ) return clob;

  function render_meu_gestor (
    p_login      in varchar2 default v('APP_USER'),
    p_id_empresa in number   default to_number(v('G_ID_EMPRESA') default null on conversion error)
  ) return clob;

  -- p_limite nulo = todos do mês. p_ver_todos = 'S' mostra o rodapé "Ver todos".
  function render_aniversariantes (
    p_id_empresa in number      default to_number(v('G_ID_EMPRESA') default null on conversion error),
    p_limite     in pls_integer default 3,
    p_ver_todos  in varchar2    default 'S'
  ) return clob;

  -- Aniversários e anos de empresa (admissão) do mês. Mesmos parâmetros acima.
  function render_celebracoes (
    p_id_empresa in number      default to_number(v('G_ID_EMPRESA') default null on conversion error),
    p_limite     in pls_integer default 4,
    p_ver_todos  in varchar2    default 'S'
  ) return clob;

  -- Número de pendências para o título "Suas pendências" (nulo se não houver)
  function qt_pendencias return varchar2;

  -- " · 3 não lidos" para o subtítulo de Comunicados (nulo se não houver)
  function nao_lidos_texto return varchar2;

  function render_feedbacks (
    p_id_colaborador in number default null
  ) return clob;

  function render_pesquisa (
    p_id_colaborador in number default null
  ) return clob;

  function render_eventos (
    p_id_empresa in number default to_number(v('G_ID_EMPRESA') default null on conversion error)
  ) return clob;

  -- "Ler comunicado": marca como lido antes de abrir (x01 = id do comunicado)
  procedure ajax_marcar_lido (p_id_comunicado in varchar2);

  -- "Responder pesquisa": registra a participação (x01 = id da pesquisa)
  procedure ajax_responder_pesquisa (p_id_pesquisa in varchar2);

  -- "Dar feedback" e "Parabenizar" (x01 destinatário, x02 tipo, x03 texto)
  procedure ajax_salvar_feedback (
    p_id_destinatario in varchar2,
    p_tp_feedback     in varchar2,
    p_ds_texto        in varchar2
  );

end pkg_home_ui;
/
