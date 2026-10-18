--------------------------------------------------------------------------------
-- Corlix Hub · Histórico de Carreira
-- 09 · Dados de demonstração para o Dashboard RH (página 20)
--
-- Cria, na empresa informada em C_EMPRESA, uma massa marcada como [DEMO]:
--   - 2 cargos "[DEMO] Analista I/II" em cada um dos (até) 4 primeiros departamentos;
--   - 4 colaboradores "[DEMO] ..." por departamento (login DEMO.CARREIRA.*);
--   - histórico efetivado: admissões, promoções e desligamentos espalhados nos
--     últimos 12 meses, com quantidades diferentes por departamento;
--   - formações com validade vencida, a vencer e sem validade;
--   - 2 solicitações de correção abertas.
--
-- O que cada gráfico mostra com esta massa (período padrão: últimos 12 meses):
--   5.1 Promoções por departamento: 4, 3, 2 e 1 promoções (1º ao 4º departamento)
--   5.2 Turnover: 7 admissões (em 5 meses diferentes) e 4 desligamentos nos últimos 4 meses
--   5.3 Tempo médio no cargo: médias diferentes por departamento
--   5.4 Formações a vencer: 5 linhas (validade entre hoje e +60 dias)
--   5.5 Solicitações abertas: 2 linhas
--
-- Por que DML direto e não o package: em SQL Workshop o código roda na sessão do
-- Builder (sem G_ID_EMPRESA), e o package deve recusar com -20012 (dedução pelo
-- código de em_sessao_apex/fn_empresa_contexto, não testada).
-- Os lançamentos são montados como o package os grava (snapshot completo de
-- anterior/novo, EFETIVADO), sem comunicado automático para a intranet.
--
-- Como rodar: SQL Workshop › SQL Scripts › Upload (ou Create, colando o conteúdo) › Run,
-- como dono do schema. SQL Commands não serve: ele roda um comando por vez.
-- Troque C_EMPRESA pela empresa do seu usuário RH (G_ID_EMPRESA):
--   select id_empresa, nome from empresa order by id_empresa;
--
-- Para apagar tudo depois: 10_remover_dados_demo.sql.
-- Não é reexecutável: se já houver dados [DEMO], o script para sem gravar nada.
--------------------------------------------------------------------------------
set serveroutput on size unlimited

declare
  c_empresa constant number := 1;   -- <<< troque pela empresa do seu usuário RH

  type t_num  is table of number        index by pls_integer;
  type t_nome is table of varchar2(100) index by pls_integer;

  l_hoje   date;
  l_deps   t_num;
  l_nomes  t_nome;
  l_qt     pls_integer;
  l_cargo1 number;
  l_cargo2 number;
  l_col    number;
  l_n      pls_integer := 0;
  l_adm    date;
  l_promo  date;
  l_desl   date;
  l_cargo_atual number;
  l_ativo  boolean;
  l_dep    number;          -- escalares: o SQL recebe valores simples, não elementos de coleção
  l_nome   varchar2(100);
  l_qt_promo pls_integer := 0;
  l_qt_adm   pls_integer := 0;
  l_qt_desl  pls_integer := 0;

  -- Data no mês "p_meses_atras", no dia "p_dia" (1 a 25): datas sempre no passado
  function data_em (p_meses_atras in pls_integer, p_dia in pls_integer) return date is
  begin
    return trunc(add_months(l_hoje, -p_meses_atras), 'mm') + (p_dia - 1);
  end data_em;

  function id_tipo (p_cd in varchar2) return number is
  begin
    return pkg_historico_carreira.fn_id_tipo(c_empresa, p_cd);
  end id_tipo;

  -- Lançamento efetivado no mesmo formato que o package grava
  procedure lancar (
    p_col        in number,
    p_cd         in varchar2,
    p_dt         in date,
    p_cargo_ant  in number,
    p_dep_ant    in number,
    p_cargo_novo in number,
    p_dep_novo   in number,
    p_motivo     in varchar2
  ) is
    -- Função local não pode ser chamada dentro de SQL (PLS-00231): resolve antes
    l_id_tipo constant number := id_tipo(p_cd);
  begin
    insert into historico_carreira (
      id_empresa, id_colaborador, id_tipo_movimentacao, dt_efetiva,
      id_cargo_anterior, id_departamento_anterior, id_gestor_anterior,
      id_cargo_novo, id_departamento_novo, id_gestor_novo,
      ds_motivo, st_registro, dt_efetivacao, usr_efetivacao
    ) values (
      c_empresa, p_col, l_id_tipo, p_dt,
      p_cargo_ant, p_dep_ant, null,
      p_cargo_novo, p_dep_novo, null,
      '[DEMO] ' || p_motivo, 'EFETIVADO', systimestamp, 'DEMO'
    );
  end lancar;

  procedure formacao (
    p_col in number, p_tp in varchar2, p_titulo in varchar2, p_inst in varchar2,
    p_conclusao in date, p_validade in date, p_horas in number
  ) is
  begin
    insert into formacao_colaborador (
      id_empresa, id_colaborador, tp_formacao, ds_titulo, ds_instituicao,
      dt_conclusao, dt_validade, nr_carga_horaria
    ) values (
      c_empresa, p_col, p_tp, '[DEMO] ' || p_titulo, p_inst,
      p_conclusao, p_validade, p_horas
    );
  end formacao;

begin
  ------------------------------------------------------------------------------
  -- Conferências antes de gravar
  ------------------------------------------------------------------------------
  select count(*) into l_qt from empresa where id_empresa = c_empresa;
  if l_qt = 0 then
    raise_application_error(-20099, 'Empresa ' || c_empresa || ' não existe. Ajuste C_EMPRESA.');
  end if;

  select count(*) into l_qt
    from colaborador
   where id_empresa = c_empresa
     and login_apex like 'DEMO.CARREIRA.%';
  if l_qt > 0 then
    raise_application_error(-20099, 'Já existem dados [DEMO] nesta empresa. Rode 10_remover_dados_demo.sql antes.');
  end if;

  select count(*) into l_qt from tipo_movimentacao where id_empresa = c_empresa;
  if l_qt = 0 then
    prc_seed_tipo_movimentacao(c_empresa);
  end if;

  select id_departamento
    bulk collect into l_deps
    from (select id_departamento
            from departamento
           where id_empresa = c_empresa
           order by id_departamento)
   where rownum <= 4;
  if l_deps.count = 0 then
    raise_application_error(-20099, 'A empresa ' || c_empresa || ' não tem departamentos.');
  end if;

  l_hoje := pkg_historico_carreira.fn_hoje(c_empresa);

  l_nomes(1)  := 'Ana Lima';      l_nomes(2)  := 'Bruno Costa';   l_nomes(3)  := 'Carla Souza';  l_nomes(4)  := 'Diego Alves';
  l_nomes(5)  := 'Elisa Rocha';   l_nomes(6)  := 'Fabio Nunes';   l_nomes(7)  := 'Gabi Martins'; l_nomes(8)  := 'Hugo Pires';
  l_nomes(9)  := 'Iris Melo';     l_nomes(10) := 'Joao Teixeira'; l_nomes(11) := 'Karen Dias';   l_nomes(12) := 'Lucas Ramos';
  l_nomes(13) := 'Marina Prado';  l_nomes(14) := 'Nico Barros';   l_nomes(15) := 'Olivia Reis';  l_nomes(16) := 'Paulo Viana';

  ------------------------------------------------------------------------------
  -- Departamento i: 4 colaboradores. O departamento i tem (5 - i) promoções no
  -- período, e cada um tem 1 desligamento recente.
  --   j = 1: admitido há 36+i meses
  --   j = 2: admitido há 18+i meses
  --   j = 3: admitido há  8+i meses (dentro do período)
  --   j = 4: admitido há 11-i meses (dentro do período) e desligado há i meses
  -- Promoção (se j <= 5 - i): há j+i-1 meses, sempre depois da admissão.
  ------------------------------------------------------------------------------
  for i in 1 .. l_deps.count loop
    l_dep := l_deps(i);

    insert into cargo (id_empresa, id_departamento, nome, nivel)
    values (c_empresa, l_dep, '[DEMO] Analista I', 'Júnior')
    returning id_cargo into l_cargo1;

    insert into cargo (id_empresa, id_departamento, nome, nivel)
    values (c_empresa, l_dep, '[DEMO] Analista II', 'Pleno')
    returning id_cargo into l_cargo2;

    for j in 1 .. 4 loop
      l_n   := l_n + 1;
      l_adm := data_em(case j when 1 then 36 + i when 2 then 18 + i when 3 then 8 + i else 11 - i end,
                       2 + 5 * j);
      l_promo := case when j <= 5 - i then data_em(j + i - 1, 3 + 4 * i) end;
      l_desl  := case when j = 4 then data_em(i, 20) end;
      -- A promoção do j=4 (só no 1º departamento) precisa vir antes do desligamento
      if l_promo is not null and l_desl is not null and l_promo >= l_desl then
        l_promo := l_desl - 15;
      end if;
      l_cargo_atual := case when l_promo is not null then l_cargo2 else l_cargo1 end;
      l_ativo       := l_desl is null;
      l_nome        := l_nomes(l_n);

      insert into colaborador (
        id_empresa, id_departamento, id_cargo, id_gestor,
        nome_completo, primeiro_nome, ultimo_nome,
        email, login_apex, data_admissao, data_de_nascimento, status
      ) values (
        c_empresa, l_dep, l_cargo_atual, null,
        '[DEMO] ' || l_nome, regexp_substr(l_nome, '^\S+'), regexp_substr(l_nome, '\S+$'),
        'demo.carreira.' || i || '.' || j || '@demo.invalid', 'DEMO.CARREIRA.' || i || '.' || j,
        l_adm, null, l_ativo
      )
      returning id_colaborador into l_col;

      lancar(l_col, 'ADMISSAO', l_adm, null, null, l_cargo1, l_dep, 'Admissão de demonstração.');
      l_qt_adm := l_qt_adm + 1;

      if l_promo is not null then
        lancar(l_col, 'PROMOCAO', l_promo, l_cargo1, l_dep, l_cargo2, l_dep, 'Promoção de demonstração.');
        l_qt_promo := l_qt_promo + 1;
      end if;

      if l_desl is not null then
        lancar(l_col, 'DESLIGAMENTO', l_desl, l_cargo_atual, l_dep, l_cargo_atual, l_dep, 'Desligamento de demonstração.');
        l_qt_desl := l_qt_desl + 1;
      end if;

      --------------------------------------------------------------------------
      -- Formações (só em colaboradores ativos)
      --------------------------------------------------------------------------
      if j = 1 then
        formacao(l_col, 'CERTIFICACAO', 'Certificação a vencer', 'Instituto Demo',
                 l_hoje - 340, l_hoje + 10 * i, 40);          -- A VENCER (10 a 40 dias)
      end if;
      if i = 1 and j = 1 then
        formacao(l_col, 'CERTIFICACAO', 'Certificação vencida', 'Instituto Demo',
                 l_hoje - 400, l_hoje - 15, 32);              -- VENCIDA
        formacao(l_col, 'CURSO', 'NR-10 (curso com validade)', 'Escola Demo',
                 l_hoje - 700, l_hoje + 45, 40);              -- A VENCER, tipo Curso
        formacao(l_col, 'IDIOMA', 'Inglês intermediário', 'Escola Demo',
                 l_hoje - 200, null, 120);                    -- sem validade
      end if;

      --------------------------------------------------------------------------
      -- Solicitações de correção abertas (2)
      --------------------------------------------------------------------------
      if j = 2 and i <= 2 then
        insert into solicitacao_correcao (id_empresa, id_colaborador, ds_mensagem)
        values (c_empresa, l_col, '[DEMO] A data da minha admissão está diferente da do contrato.');
      end if;
    end loop;
  end loop;

  commit;

  dbms_output.put_line('Dados [DEMO] criados na empresa ' || c_empresa
                       || ' | departamentos: ' || l_deps.count
                       || ' | colaboradores: ' || l_n
                       || ' | admissões: ' || l_qt_adm
                       || ' | promoções: ' || l_qt_promo
                       || ' | desligamentos: ' || l_qt_desl);
exception
  when others then
    rollback;
    raise;
end;
/

-- Conferência: promoções por departamento no período padrão do dashboard
select coalesce(d.nome, '(sem departamento)') as departamento,
       count(*)                               as promocoes
  from vw_movimentacao_valida v
  left join departamento d on d.id_departamento = v.id_departamento_novo
 where v.cd_tipo = 'PROMOCAO'
   and v.dt_efetiva >= add_months(trunc(sysdate, 'mm'), -11)
   and exists (select 1 from colaborador c
                where c.id_colaborador = v.id_colaborador
                  and c.login_apex like 'DEMO.CARREIRA.%')
 group by d.id_departamento, d.nome
 order by promocoes desc;
