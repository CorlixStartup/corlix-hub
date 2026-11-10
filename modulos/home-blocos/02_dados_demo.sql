--------------------------------------------------------------------------------
-- Corlix Hub · Blocos da Home · 02 · dados de demonstração
--
-- Troque c_colaborador (abaixo) pelo login (LOGIN_APEX) ou pelo ID_COLABORADOR de
-- quem vai ver os blocos na Home. Cria, para essa pessoa e a empresa dela:
--   2 feedbacks recebidos (do gestor e de um colega), a pesquisa de clima aberta,
--   3 eventos, a próxima conversa 1:1 com o gestor, o período de férias e um PDI
--   com 5 objetivos (2 concluídos).
-- Datas relativas a hoje. Reexecutável: não duplica. Para remover: 03.
--------------------------------------------------------------------------------
set define off
set serveroutput on

declare
  c_colaborador constant varchar2(255) := 'TROQUE_PELO_LOGIN';  -- login ou ID_COLABORADOR

  -- Textos fixos: identificam os dados de demonstração para o script 03
  c_fb_gestor  constant varchar2(1000) := 'A apresentação dos indicadores na reunião de segunda foi clara e ajudou o time a decidir rápido o que priorizar.';
  c_fb_colega  constant varchar2(1000) := 'Vale automatizar a planilha de filas. Posso mostrar como fiz no relatório mensal.';
  c_pesquisa   constant varchar2(150)  := 'Pesquisa de clima 2026';
  c_pdi        constant varchar2(150)  := 'PDI 2026 · demonstração';

  l_id       number;
  l_empresa  number;
  l_gestor   number;
  l_colega   number;
  l_admissao date;
  l_hoje     constant date := trunc(cast(systimestamp at time zone 'America/Sao_Paulo' as date));
  l_id_pdi   number;
  l_inicio   date;
  l_qt       pls_integer;
begin
  begin
    select id_colaborador, id_empresa, id_gestor, data_admissao
      into l_id, l_empresa, l_gestor, l_admissao
      from colaborador
     where upper(trim(login_apex)) = upper(trim(c_colaborador))
        or id_colaborador = to_number(c_colaborador default null on conversion error)
     order by case when id_colaborador = to_number(c_colaborador default null on conversion error) then 0 else 1 end
     fetch first 1 rows only;
  exception
    when no_data_found then
      raise_application_error(-20000, '"' || c_colaborador
        || '" não é login nem ID de colaborador. Troque c_colaborador no início do script.');
  end;

  -- Colega: outra pessoa ativa da empresa (nem a própria, nem o gestor)
  select max(id_colaborador) keep (dense_rank first order by nome_completo)
    into l_colega
    from colaborador
   where id_empresa = l_empresa
     and status = true
     and id_colaborador <> l_id
     and id_colaborador <> nvl(l_gestor, -1);

  -- Sem gestor cadastrado: o "gestor" dos exemplos é o colega
  l_gestor := coalesce(l_gestor, l_colega);
  if l_gestor is null then
    raise_application_error(-20000, 'A empresa precisa de pelo menos mais um colaborador ativo para os exemplos.');
  end if;

  -- Feedbacks recebidos
  select count(*) into l_qt from feedback where id_destinatario = l_id and ds_texto = c_fb_gestor;
  if l_qt = 0 then
    insert into feedback (id_empresa, id_autor, id_destinatario, tp_feedback, ds_texto, dh_criacao)
    values (l_empresa, l_gestor, l_id, 'RECONHECIMENTO', c_fb_gestor, systimestamp - interval '19' day);
  end if;
  if l_colega is not null and l_colega <> l_gestor then
    select count(*) into l_qt from feedback where id_destinatario = l_id and ds_texto = c_fb_colega;
    if l_qt = 0 then
      insert into feedback (id_empresa, id_autor, id_destinatario, tp_feedback, ds_texto, dh_criacao)
      values (l_empresa, l_colega, l_id, 'SUGESTAO', c_fb_colega, systimestamp - interval '9' day);
    end if;
  end if;

  -- Pesquisa de clima aberta (troque o ds_link pelo formulário de verdade)
  select count(*) into l_qt from pesquisa where id_empresa = l_empresa and ds_titulo = c_pesquisa;
  if l_qt = 0 then
    insert into pesquisa (id_empresa, ds_titulo, ds_descricao, dt_abertura, dt_fechamento, fl_anonima, nr_minutos, ds_link)
    values (l_empresa, c_pesquisa,
            'É anônima e leva cerca de 8 minutos. Sua opinião ajuda a construir um lugar melhor.',
            l_hoje - 5, l_hoje + 10, true, 8, 'https://www.example.com/pesquisa-de-clima');
  end if;

  -- Eventos (os feriados vêm de ponto_feriado)
  for r in (select 'Café com a diretoria' t, 1 d, '09:30' h, 'Auditório e on-line' l from dual union all
            select 'Palestra Novembro Azul',  3, '15:00', 'Auditório e on-line' from dual union all
            select 'Inventário trimestral',   6, '08:00', 'Centro de distribuição' from dual) loop
    select count(*) into l_qt from evento where id_empresa = l_empresa and ds_titulo = r.t;
    if l_qt = 0 then
      insert into evento (id_empresa, ds_titulo, dh_inicio, dh_fim, ds_local)
      values (l_empresa, r.t,
              l_hoje + r.d + to_number(substr(r.h, 1, 2)) / 24 + to_number(substr(r.h, 4, 2)) / 1440,
              case when r.t = 'Inventário trimestral' then l_hoje + r.d + 14 / 24 end,
              r.l);
    end if;
  end loop;

  -- Próxima conversa 1:1 com o gestor
  select count(*) into l_qt from conversa_1a1
   where id_colaborador = l_id and st_conversa = 'AGENDADA' and dh_conversa > sysdate;
  if l_qt = 0 then
    insert into conversa_1a1 (id_empresa, id_gestor, id_colaborador, dh_conversa, ds_pauta)
    values (l_empresa, l_gestor, l_id, l_hoje + 2 + 10 / 24, 'Acompanhamento do PDI e prioridades do mês');
  end if;

  -- Férias: último período aquisitivo completo pela data de admissão (ou o ano passado)
  l_inicio := add_months(nvl(l_admissao, add_months(l_hoje, -24)),
                         12 * greatest(floor(months_between(l_hoje, nvl(l_admissao, add_months(l_hoje, -24))) / 12) - 1, 0));
  select count(*) into l_qt from ferias_periodo where id_colaborador = l_id and dt_inicio_aquisitivo = l_inicio;
  if l_qt = 0 then
    insert into ferias_periodo (id_empresa, id_colaborador, dt_inicio_aquisitivo, dt_fim_aquisitivo, dt_limite_gozo, nr_dias_gozados)
    values (l_empresa, l_id, l_inicio, add_months(l_inicio, 12) - 1, add_months(l_inicio, 23) - 1, 12);
  end if;

  -- PDI com 5 objetivos, 2 concluídos
  select max(id_pdi) into l_id_pdi from pdi where id_colaborador = l_id and ds_titulo = c_pdi;
  if l_id_pdi is null then
    insert into pdi (id_empresa, id_colaborador, ds_titulo, dt_prazo, st_pdi)
    values (l_empresa, l_id, c_pdi, add_months(l_hoje, 4), 'APROVADO')
    returning id_pdi into l_id_pdi;
    insert into pdi_objetivo (id_pdi, ds_titulo, dt_prazo, st_objetivo)
    select l_id_pdi, t, l_hoje + d, s from (
      select 'Concluir o curso de análise de dados'      t, -20 d, 'CONCLUIDO'    s from dual union all
      select 'Apresentar os indicadores do trimestre',      -5,    'CONCLUIDO'      from dual union all
      select 'Automatizar o relatório mensal de filas',     30,    'EM_ANDAMENTO'   from dual union all
      select 'Conduzir uma reunião de planejamento',        60,    'NAO_INICIADO'   from dual union all
      select 'Mentorar uma pessoa recém-chegada ao time',   90,    'NAO_INICIADO'   from dual);
  end if;

  commit;
  dbms_output.put_line('Dados de demonstração prontos para o colaborador ' || l_id || ' (empresa ' || l_empresa
    || ', gestor ' || l_gestor || ', colega ' || nvl(to_char(l_colega), '-') || ').');
end;
/
