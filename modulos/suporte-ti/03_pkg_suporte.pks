--------------------------------------------------------------------------------
-- Corlix Hub · Suporte TI · 03 · regras de negócio · especificação
--
-- Erros (-20076 a -20084) saem sem "ORA-" pelo log_pkg.apex_error_handler, que
-- trata a faixa -20001..-20099.
--   -20076 conta sem colaborador        -20081 só a equipe de TI pode fazer isto
--   -20077 chamado não encontrado       -20082 mensagem obrigatória
--   -20078 dados do chamado inválidos   -20083 previsão inválida
--   -20079 anexo inválido               -20084 ação inválida
--   -20080 situação do chamado mudou
--
-- Situações:
--   ABERTO -> EM_ATENDIMENTO <-> AGUARDANDO_USUARIO -> RESOLVIDO -> ENCERRADO
--   RESOLVIDO volta para atendimento quando o colaborador reabre.
--   ENCERRADO é definitivo: se o problema voltar, abre-se outro chamado.
--------------------------------------------------------------------------------
create or replace package pkg_suporte authid definer as

  c_aberto     constant varchar2(20) := 'ABERTO';
  c_atendimento constant varchar2(20) := 'EM_ATENDIMENTO';
  c_aguardando constant varchar2(20) := 'AGUARDANDO_USUARIO';
  c_resolvido  constant varchar2(20) := 'RESOLVIDO';
  c_encerrado  constant varchar2(20) := 'ENCERRADO';

  -- Tamanho máximo de um anexo, em bytes (5 MB)
  c_max_anexo constant number := 5242880;

  -- Colaborador da conta logada na empresa da sessão. Sem vínculo: -20076.
  function fn_colaborador_logado return number;

  -- 'S' se a conta logada tem a autorização SUPORTE_TI nesta sessão.
  function fn_e_ti return varchar2;

  -- "INC-4821"
  function fn_codigo (p_tp_chamado in varchar2, p_id_chamado in number) return varchar2;

  -- Situação do chamado, se a conta logada pode vê-lo: o solicitante ou a TI da
  -- mesma empresa. Caso contrário: -20077, sem dizer se o chamado existe.
  function fn_situacao (p_id_chamado in number) return varchar2;

  -- p_tp_chamado: INC (algo não funciona) ou REQ (pedido). p_anexo é o NAME do
  -- item File Upload (apex_application_temp_files), ou nulo.
  function abrir_chamado (
    p_tp_chamado in varchar2,
    p_id_assunto in number,
    p_ds_titulo  in varchar2,
    p_ds_texto   in varchar2,
    p_anexo      in varchar2 default null
  ) return number;

  -- Colaborador responde no próprio chamado
  procedure responder (
    p_id_chamado in number,
    p_ds_texto   in varchar2,
    p_anexo      in varchar2 default null
  );

  -- "Sim, encerrar"
  procedure confirmar_solucao (p_id_chamado in number);

  -- "Não, reabrir". O motivo é obrigatório.
  procedure reabrir (
    p_id_chamado in number,
    p_ds_texto   in varchar2,
    p_anexo      in varchar2 default null
  );

  -- Ação da TI. p_acao:
  --   ASSUMIR   -> fica com quem está atendendo; mensagem opcional
  --   RESPONDER -> mensagem ao colaborador, segue em atendimento
  --   PEDIR     -> mensagem que espera o colaborador (Aguardando você)
  --   RESOLVER  -> a mensagem é a solução; abre o prazo de confirmação
  -- p_dt_previsao em DD/MM/YYYY; nula apaga a previsão.
  procedure atender (
    p_id_chamado    in number,
    p_acao          in varchar2,
    p_ds_texto      in varchar2,
    p_tp_prioridade in varchar2,
    p_dt_previsao   in varchar2,
    p_anexo         in varchar2 default null
  );

  -- Encerra os resolvidos cujo prazo de confirmação chegou. Roda pelo job
  -- SUPORTE_ENCERRAR_VENCIDOS (fora de sessão APEX). Devolve quantos encerrou.
  function encerrar_vencidos return number;

  -- Soma um acesso, se o artigo é publicado e da empresa da sessão.
  procedure registrar_acesso_artigo (p_id_artigo in number);

  -- Envia o arquivo ao navegador, se a conta logada pode ver o chamado.
  procedure baixar_anexo (p_id_anexo in number);

end pkg_suporte;
/
