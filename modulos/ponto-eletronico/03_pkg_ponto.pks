--------------------------------------------------------------------------------
-- Corlix Hub · Ponto eletrônico · 03 · regras de negócio · especificação
--
-- Erros (-20060 a -20075) saem sem "ORA-" pelo log_pkg.apex_error_handler, que
-- trata a faixa -20001..-20099.
--   -20060 conta sem colaborador      -20068 recusa sem mensagem
--   -20061 marcação imutável/sem jornada  -20069 horários fora de ordem
--   -20062 marcação fora da sequência -20070 mês já assinado
--   -20063 marcação repetida          -20071 competência inválida
--   -20064 menos de 1 minuto          -20072 assinatura repetida
--   -20065 pedido de ajuste inválido  -20073 colaborador de outra empresa
--   -20066 ajuste já respondido       -20074 assinatura com pedido em análise
--   -20067 sem permissão para aprovar
--------------------------------------------------------------------------------
create or replace package pkg_ponto authid definer as

  -- Situações do dia
  c_regular      constant varchar2(15) := 'REGULAR';
  c_andamento    constant varchar2(15) := 'ANDAMENTO';
  c_ausente      constant varchar2(15) := 'AUSENTE';
  c_abonado      constant varchar2(15) := 'ABONADO';
  c_falta        constant varchar2(15) := 'FALTA';
  c_sem_marcacao constant varchar2(15) := 'SEM_MARCACAO';
  c_feriado      constant varchar2(15) := 'FERIADO';
  c_analise      constant varchar2(15) := 'ANALISE';

  type t_jornada is record (
    id_jornada         ponto_jornada.id_jornada%type,
    nr_min_entrada     ponto_jornada.nr_min_entrada%type,
    nr_min_saida       ponto_jornada.nr_min_saida%type,
    nr_min_intervalo   ponto_jornada.nr_min_intervalo%type,
    nr_min_diarios     ponto_jornada.nr_min_diarios%type,
    nr_min_semanais    ponto_jornada.nr_min_semanais%type,
    nr_min_tolerancia  ponto_jornada.nr_min_tolerancia%type,
    nr_meses_validade  ponto_jornada.nr_meses_validade%type,
    dt_inicio_controle date,
    ds_local           ponto_colaborador.ds_local%type
  );

  type t_dia is record (
    dt             date,
    dh_entrada     date,
    dh_intervalo   date,
    dh_retorno     date,
    dh_saida       date,
    nr_trabalhados number,        -- minutos; nulo se não há marcação
    nr_saldo       number,        -- minutos; nulo enquanto o dia não fecha
    cd_situacao    varchar2(15),
    nm_feriado     varchar2(100),
    nr_saldo_banco number         -- saldo acumulado depois do dia (só calcular_banco)
  );
  type t_dias is table of t_dia index by pls_integer;

  -- Colaborador da conta logada na empresa da sessão. Sem vínculo: -20060.
  function fn_colaborador_logado return number;

  function fn_jornada (p_id_colaborador in number) return t_jornada;

  -- Dias do período em ordem crescente, de início do controle até hoje. Fins de
  -- semana sem marcação ficam de fora; feriados entram com a situação FERIADO.
  function fn_dias (p_id_colaborador in number, p_dt_inicio in date, p_dt_fim in date) return t_dias;

  -- Banco de horas: créditos vencem ao fim do mês, nr_meses_validade depois;
  -- débitos consomem primeiro os créditos mais antigos. p_extrato traz os dias
  -- com saldo diferente de zero e o acumulado depois de cada um.
  procedure calcular_banco (
    p_id_colaborador in  number,
    p_saldo          out number,
    p_min_vencendo   out number,
    p_dt_vencimento  out date,
    p_extrato        out t_dias
  );

  -- Próxima marcação esperada hoje (ENTRADA, INTERVALO, RETORNO, SAIDA) ou nula
  -- se a jornada já foi concluída.
  function fn_proxima_marcacao (p_id_colaborador in number) return varchar2;

  -- Registra a marcação do colaborador logado. p_tp_marcacao é o que a tela
  -- mostrava: se já mudou (outra aba, clique duplo), dá erro e não registra.
  function registrar_marcacao (p_tp_marcacao in varchar2) return number;

  -- p_dt_referencia em DD/MM/YYYY e p_hr_marcacao em HH24:MI.
  function solicitar_ajuste (
    p_dt_referencia in varchar2,
    p_tp_ajuste     in varchar2,
    p_tp_marcacao   in varchar2,
    p_hr_marcacao   in varchar2,
    p_ds_motivo     in varchar2
  ) return number;

  -- p_st_ajuste: APROVADO ou RECUSADO
  procedure responder_ajuste (
    p_id_ajuste   in number,
    p_st_ajuste   in varchar2,
    p_ds_resposta in varchar2
  );

  -- 'S' se a conta logada pode responder ao ajuste: gestor direto do colaborador
  -- ou RH, nunca o próprio colaborador. Usada no SQL da página 32.
  function fn_pode_aprovar (p_id_ajuste in number) return varchar2;

  -- 'S' se a conta logada é RH ou tem alguém sob sua gestão (autorização APROVADOR_PONTO).
  function fn_e_aprovador return varchar2;

  -- Mês mais antigo sem assinatura e ainda no prazo (1º dia do mês) ou nulo: o
  -- retrasado até o dia 5 e, depois dele, o anterior.
  function fn_competencia_a_assinar (p_id_colaborador in number) return date;

  -- Prazo para assinar: dia 5 do segundo mês depois da competência.
  function fn_prazo_assinatura (p_dt_competencia in date) return date;

  -- p_competencia em YYYYMM.
  procedure assinar_espelho (p_competencia in varchar2);

  -- "4h33"
  function fn_horas (p_minutos in number) return varchar2;

  -- "+0h17", "-2h10", "0h00"
  function fn_saldo (p_minutos in number) return varchar2;

end pkg_ponto;
/
