--------------------------------------------------------------------------------
-- Corlix Hub · Ponto eletrônico · 03 · regras de negócio · corpo
--------------------------------------------------------------------------------
create or replace package body pkg_ponto as

  -- Janela do pedido de ajuste, em dias
  c_dias_ajuste constant pls_integer := 60;

  ------------------------------------------------------------------------------
  -- Utilitários
  ------------------------------------------------------------------------------
  function em_sessao_apex return boolean is
  begin
    return sys_context('APEX$SESSION', 'APP_SESSION') is not null;
  end em_sessao_apex;

  function usuario_atual return varchar2 is
  begin
    return coalesce(sys_context('APEX$SESSION', 'APP_USER'), sys_context('USERENV', 'SESSION_USER'));
  end usuario_atual;

  function e_rh return boolean is
  begin
    return em_sessao_apex and apex_authorization.is_authorized('ADMIN_RH');
  end e_rh;

  function cgi (p_nome in varchar2) return varchar2 is
  begin
    return substr(owa_util.get_cgi_env(p_nome), 1, 400);
  exception
    when others then
      return null; -- fora de uma requisição web (scripts e testes)
  end cgi;

  -- Atrás do proxy da OCI, o IP do usuário é o primeiro do X-Forwarded-For
  function ip_origem return varchar2 is
  begin
    return substr(coalesce(trim(regexp_substr(cgi('HTTP_X_FORWARDED_FOR'), '[^,]+', 1, 1)),
                           cgi('REMOTE_ADDR')), 1, 64);
  end ip_origem;

  function empresa_do_colaborador (p_id_colaborador in number) return number is
    l_id       number;
    l_contexto constant number := pkg_historico_carreira.fn_empresa_contexto;
  begin
    select id_empresa into l_id from colaborador where id_colaborador = p_id_colaborador;
    if l_contexto is not null and l_id <> l_contexto then
      raise_application_error(-20073, 'Colaborador não encontrado nesta empresa.');
    end if;
    return l_id;
  exception
    when no_data_found then
      raise_application_error(-20073, 'Colaborador não encontrado nesta empresa.');
  end empresa_do_colaborador;

  function minutos (p_de in date, p_ate in date) return number is
  begin
    return round((p_ate - p_de) * 1440);
  end minutos;

  function dia_util (p_dt in date) return boolean is
  begin
    return p_dt - trunc(p_dt, 'IW') < 5; -- segunda = 0; independe de NLS
  end dia_util;

  function chave (p_dt in date, p_tipo in varchar2 default null) return varchar2 is
  begin
    return to_char(p_dt, 'YYYYMMDD') || p_tipo;
  end chave;

  ------------------------------------------------------------------------------
  -- Públicas: formatação
  ------------------------------------------------------------------------------
  function fn_horas (p_minutos in number) return varchar2 is
    l_abs constant number := abs(nvl(p_minutos, 0));
  begin
    return trunc(l_abs / 60) || 'h' || to_char(mod(l_abs, 60), 'fm00');
  end fn_horas;

  function fn_saldo (p_minutos in number) return varchar2 is
  begin
    return case when p_minutos > 0 then '+' when p_minutos < 0 then '-' end || fn_horas(p_minutos);
  end fn_saldo;

  ------------------------------------------------------------------------------
  -- Públicas: colaborador e jornada
  ------------------------------------------------------------------------------
  function fn_colaborador_logado return number is
    l_id      number;
    l_usuario constant varchar2(255) := usuario_atual;
    l_empresa constant number := pkg_historico_carreira.fn_empresa_contexto;
  begin
    select id_colaborador
      into l_id
      from colaborador
     where upper(trim(login_apex)) = upper(trim(l_usuario))
       and id_empresa = l_empresa;
    return l_id;
  exception
    when no_data_found or too_many_rows then
      raise_application_error(-20060, 'Sua conta não está vinculada a um colaborador desta empresa. Fale com o RH.');
  end fn_colaborador_logado;

  function fn_jornada (p_id_colaborador in number) return t_jornada is
    l_j       t_jornada;
    l_empresa constant number := empresa_do_colaborador(p_id_colaborador);
  begin
    begin
      select j.id_jornada, j.nr_min_entrada, j.nr_min_saida, j.nr_min_intervalo, j.nr_min_diarios,
             j.nr_min_semanais, j.nr_min_tolerancia, j.nr_meses_validade, p.dt_inicio_controle, p.ds_local
        into l_j.id_jornada, l_j.nr_min_entrada, l_j.nr_min_saida, l_j.nr_min_intervalo, l_j.nr_min_diarios,
             l_j.nr_min_semanais, l_j.nr_min_tolerancia, l_j.nr_meses_validade, l_j.dt_inicio_controle, l_j.ds_local
        from ponto_colaborador p
        join ponto_jornada j on j.id_jornada = p.id_jornada
       where p.id_colaborador = p_id_colaborador;
    exception
      when no_data_found then
        -- Colaborador admitido depois da instalação: usa a jornada padrão e o
        -- controle começa hoje. O vínculo é gravado na primeira marcação.
        select j.id_jornada, j.nr_min_entrada, j.nr_min_saida, j.nr_min_intervalo, j.nr_min_diarios,
               j.nr_min_semanais, j.nr_min_tolerancia, j.nr_meses_validade
          into l_j.id_jornada, l_j.nr_min_entrada, l_j.nr_min_saida, l_j.nr_min_intervalo, l_j.nr_min_diarios,
               l_j.nr_min_semanais, l_j.nr_min_tolerancia, l_j.nr_meses_validade
          from ponto_jornada j
         where j.id_empresa = l_empresa
           and j.fl_padrao  = 'S'
           and rownum = 1;
        l_j.dt_inicio_controle := pkg_historico_carreira.fn_hoje(l_empresa);
        select 'Sede ' || cidade into l_j.ds_local from empresa where id_empresa = l_empresa;
    end;
    return l_j;
  exception
    when no_data_found then
      raise_application_error(-20061, 'Sua empresa ainda não tem jornada de trabalho cadastrada. Fale com o RH.');
  end fn_jornada;

  ------------------------------------------------------------------------------
  -- Públicas: cálculo dos dias
  ------------------------------------------------------------------------------
  function fn_dias (p_id_colaborador in number, p_dt_inicio in date, p_dt_fim in date) return t_dias is
    type t_mapa_data is table of date index by varchar2(20);
    type t_mapa_texto is table of varchar2(100) index by varchar2(20);

    l_empresa constant number    := empresa_do_colaborador(p_id_colaborador);
    l_j       constant t_jornada := fn_jornada(p_id_colaborador);
    l_hoje    constant date      := pkg_historico_carreira.fn_hoje(l_empresa);
    l_agora   constant date      := pkg_historico_carreira.fn_data_local(l_empresa, systimestamp);
    l_ini     constant date      := greatest(trunc(p_dt_inicio), l_j.dt_inicio_controle);
    l_fim     constant date      := least(trunc(p_dt_fim), l_hoje);

    l_marcas    t_mapa_data;
    l_tem_marca t_mapa_data;
    l_feriados  t_mapa_texto;
    l_abonos    t_mapa_texto;
    l_pedidos   t_mapa_texto;
    l_dias      t_dias;
    l_d         date;
    l_dia       t_dia;
    l_k         varchar2(20);
    l_completo  boolean;
    l_diff      number;

    -- marcação do dia ou nula
    function marca (p_tipo in varchar2) return date is
    begin
      return case when l_marcas.exists(chave(l_d, p_tipo)) then l_marcas(chave(l_d, p_tipo)) end;
    end marca;
  begin
    -- Marcações anteriores ao início do controle (dados migrados) também contam
    for r in (select dt_referencia, tp_marcacao, dh_marcacao
                from vw_ponto_marcacao_vigente
               where id_colaborador = p_id_colaborador
                 and dt_referencia between trunc(p_dt_inicio) and l_fim) loop
      l_marcas(chave(r.dt_referencia, r.tp_marcacao)) := r.dh_marcacao;
      l_tem_marca(chave(r.dt_referencia)) := r.dt_referencia;
    end loop;

    for r in (select dt_feriado, nm_feriado
                from ponto_feriado
               where id_empresa = l_empresa
                 and dt_feriado between trunc(p_dt_inicio) and l_fim) loop
      l_feriados(chave(r.dt_feriado)) := r.nm_feriado;
    end loop;

    for r in (select dt_referencia, tp_ajuste, st_ajuste
                from ponto_ajuste
               where id_colaborador = p_id_colaborador
                 and dt_referencia between trunc(p_dt_inicio) and l_fim
                 and st_ajuste in ('PENDENTE', 'APROVADO')) loop
      if r.st_ajuste = 'PENDENTE' then
        l_pedidos(chave(r.dt_referencia)) := 'S';
      elsif r.tp_ajuste = 'ABONO' then
        l_abonos(chave(r.dt_referencia)) := 'S';
      end if;
    end loop;

    l_d := trunc(p_dt_inicio);
    while l_d <= l_fim loop
      l_k := chave(l_d);

      if l_tem_marca.exists(l_k) or l_d >= l_ini then
        l_dia := null;
        l_dia.dt           := l_d;
        l_dia.dh_entrada   := marca('ENTRADA');
        l_dia.dh_intervalo := marca('INTERVALO');
        l_dia.dh_retorno   := marca('RETORNO');
        l_dia.dh_saida     := marca('SAIDA');
        if l_feriados.exists(l_k) then
          l_dia.nm_feriado := l_feriados(l_k);
        end if;

        if l_tem_marca.exists(l_k) then
          l_dia.nr_trabalhados := 0;
          if l_dia.dh_entrada is not null and l_dia.dh_intervalo is not null then
            l_dia.nr_trabalhados := l_dia.nr_trabalhados + minutos(l_dia.dh_entrada, l_dia.dh_intervalo);
          end if;
          if l_dia.dh_retorno is not null and l_dia.dh_saida is not null then
            l_dia.nr_trabalhados := l_dia.nr_trabalhados + minutos(l_dia.dh_retorno, l_dia.dh_saida);
          end if;
          if l_dia.dh_entrada is not null and l_dia.dh_saida is not null
             and l_dia.dh_intervalo is null and l_dia.dh_retorno is null then
            l_dia.nr_trabalhados := minutos(l_dia.dh_entrada, l_dia.dh_saida);
          end if;
          -- Hoje, com o relógio correndo
          if l_d = l_hoje and l_dia.dh_saida is null then
            if l_dia.dh_retorno is not null then
              l_dia.nr_trabalhados := l_dia.nr_trabalhados + minutos(l_dia.dh_retorno, l_agora);
            elsif l_dia.dh_entrada is not null and l_dia.dh_intervalo is null then
              l_dia.nr_trabalhados := l_dia.nr_trabalhados + minutos(l_dia.dh_entrada, l_agora);
            end if;
          end if;

          l_completo := l_dia.dh_entrada is not null and l_dia.dh_saida is not null
                        and ((l_dia.dh_intervalo is not null and l_dia.dh_retorno is not null)
                             or (l_j.nr_min_intervalo = 0 and l_dia.dh_intervalo is null and l_dia.dh_retorno is null));

          if l_completo then
            if dia_util(l_d) and not l_feriados.exists(l_k) then
              l_diff := l_dia.nr_trabalhados - l_j.nr_min_diarios;
              l_dia.nr_saldo := case when abs(l_diff) <= l_j.nr_min_tolerancia then 0 else l_diff end;
              if l_dia.nr_saldo < 0 and l_abonos.exists(l_k) then
                l_dia.nr_saldo    := 0;
                l_dia.cd_situacao := c_abonado;
              end if;
            else
              l_dia.nr_saldo := l_dia.nr_trabalhados; -- folga ou feriado trabalhado
            end if;
            l_dia.cd_situacao := case
              when l_pedidos.exists(l_k) then c_analise
              else nvl(l_dia.cd_situacao, c_regular)
            end;
          elsif l_d = l_hoje then
            l_dia.cd_situacao := c_andamento;
          elsif l_abonos.exists(l_k) then
            l_dia.cd_situacao := c_abonado;
            l_dia.nr_saldo    := 0;
          elsif l_pedidos.exists(l_k) then
            l_dia.cd_situacao := c_analise;
          else
            l_dia.cd_situacao := c_ausente;
          end if;

        elsif l_feriados.exists(l_k) then
          l_dia.cd_situacao := c_feriado;
        elsif dia_util(l_d) then
          if l_d = l_hoje then
            l_dia.cd_situacao := c_sem_marcacao;
          elsif l_abonos.exists(l_k) then
            l_dia.cd_situacao := c_abonado;
            l_dia.nr_saldo    := 0;
          elsif l_pedidos.exists(l_k) then
            l_dia.cd_situacao := c_analise;
          else
            l_dia.cd_situacao := c_falta;
            l_dia.nr_saldo    := -l_j.nr_min_diarios;
          end if;
        end if;

        if l_dia.cd_situacao is not null then
          l_dias(l_dias.count + 1) := l_dia;
        end if;
      end if;

      l_d := l_d + 1;
    end loop;

    return l_dias;
  end fn_dias;

  procedure calcular_banco (
    p_id_colaborador in  number,
    p_saldo          out number,
    p_min_vencendo   out number,
    p_dt_vencimento  out date,
    p_extrato        out t_dias
  ) is
    type t_numeros is table of number index by pls_integer;
    type t_datas is table of date index by pls_integer;

    l_empresa constant number    := empresa_do_colaborador(p_id_colaborador);
    l_j       constant t_jornada := fn_jornada(p_id_colaborador);
    l_hoje    constant date      := pkg_historico_carreira.fn_hoje(l_empresa);
    l_dias    constant t_dias    := fn_dias(p_id_colaborador, l_j.dt_inicio_controle, l_hoje);

    l_credito t_numeros;
    l_vence   t_datas;
    l_inicio  pls_integer := 1;
    l_fim     pls_integer := 0;
    l_total   number := 0;
    l_debito  number := 0;
    l_resto   number;
    l_uso     number;

    procedure descartar_vencidos (p_em in date) is
    begin
      while l_inicio <= l_fim and l_vence(l_inicio) < p_em loop
        l_total  := l_total - l_credito(l_inicio);
        l_inicio := l_inicio + 1;
      end loop;
    end descartar_vencidos;
  begin
    for i in 1 .. l_dias.count loop
      descartar_vencidos(l_dias(i).dt);
      l_resto := nvl(l_dias(i).nr_saldo, 0);

      if l_resto > 0 then
        l_uso    := least(l_resto, l_debito);
        l_debito := l_debito - l_uso;
        l_resto  := l_resto - l_uso;
        if l_resto > 0 then
          l_fim := l_fim + 1;
          l_credito(l_fim) := l_resto;
          l_vence(l_fim)   := last_day(add_months(l_dias(i).dt, l_j.nr_meses_validade));
          l_total          := l_total + l_resto;
        end if;
      elsif l_resto < 0 then
        l_resto := -l_resto;
        while l_resto > 0 and l_inicio <= l_fim loop
          l_uso := least(l_resto, l_credito(l_inicio));
          l_credito(l_inicio) := l_credito(l_inicio) - l_uso;
          l_total := l_total - l_uso;
          l_resto := l_resto - l_uso;
          if l_credito(l_inicio) = 0 then
            l_inicio := l_inicio + 1;
          end if;
        end loop;
        l_debito := l_debito + l_resto;
      end if;

      if nvl(l_dias(i).nr_saldo, 0) <> 0 then
        p_extrato(p_extrato.count + 1) := l_dias(i);
        p_extrato(p_extrato.count).nr_saldo_banco := l_total - l_debito;
      end if;
    end loop;

    descartar_vencidos(l_hoje);
    p_saldo := l_total - l_debito;

    if l_inicio <= l_fim then
      p_dt_vencimento := l_vence(l_inicio);
      p_min_vencendo  := 0;
      for i in l_inicio .. l_fim loop
        exit when l_vence(i) <> p_dt_vencimento;
        p_min_vencendo := p_min_vencendo + l_credito(i);
      end loop;
    end if;
  end calcular_banco;

  function fn_proxima_marcacao (p_id_colaborador in number) return varchar2 is
    l_empresa   constant number    := empresa_do_colaborador(p_id_colaborador);
    l_j         constant t_jornada := fn_jornada(p_id_colaborador);
    l_hoje      constant date      := pkg_historico_carreira.fn_hoje(l_empresa);
    l_entrada   pls_integer;
    l_intervalo pls_integer;
    l_retorno   pls_integer;
    l_saida     pls_integer;
  begin
    select count(case when tp_marcacao = 'ENTRADA'   then 1 end),
           count(case when tp_marcacao = 'INTERVALO' then 1 end),
           count(case when tp_marcacao = 'RETORNO'   then 1 end),
           count(case when tp_marcacao = 'SAIDA'     then 1 end)
      into l_entrada, l_intervalo, l_retorno, l_saida
      from vw_ponto_marcacao_vigente
     where id_colaborador = p_id_colaborador
       and dt_referencia  = l_hoje;

    return case
      when l_saida > 0 then null
      when l_entrada = 0 then 'ENTRADA'
      when l_j.nr_min_intervalo = 0 then 'SAIDA'
      when l_intervalo = 0 then 'INTERVALO'
      when l_retorno = 0 then 'RETORNO'
      else 'SAIDA'
    end;
  end fn_proxima_marcacao;

  ------------------------------------------------------------------------------
  -- Públicas: marcação
  ------------------------------------------------------------------------------
  function registrar_marcacao (p_tp_marcacao in varchar2) return number is
    l_id_colab   constant number    := fn_colaborador_logado;
    l_empresa    constant number    := empresa_do_colaborador(l_id_colab);
    l_j          constant t_jornada := fn_jornada(l_id_colab);
    l_agora      constant date      := pkg_historico_carreira.fn_data_local(l_empresa, systimestamp);
    l_proxima    constant varchar2(10) := fn_proxima_marcacao(l_id_colab);
    l_usuario    constant varchar2(255) := usuario_atual;
    l_ip         constant varchar2(64)  := ip_origem;
    l_navegador  constant varchar2(400) := cgi('HTTP_USER_AGENT');
    l_ultima     date;
    l_id         number;
  begin
    if l_proxima is null or p_tp_marcacao is null or p_tp_marcacao <> l_proxima then
      raise_application_error(-20062,
        'Esta marcação não é a próxima da sua jornada de hoje. Atualize a página e confira.');
    end if;

    select max(dh_marcacao)
      into l_ultima
      from vw_ponto_marcacao_vigente
     where id_colaborador = l_id_colab
       and dt_referencia  = trunc(l_agora);

    if l_ultima is not null and (l_agora - l_ultima) * 1440 < 1 then
      raise_application_error(-20064, 'Sua última marcação foi há menos de um minuto. Aguarde para registrar a próxima.');
    end if;

    -- Primeira marcação de quem foi admitido depois da instalação
    merge into ponto_colaborador p
    using (select l_id_colab as id_colaborador from dual) s
       on (p.id_colaborador = s.id_colaborador)
     when not matched then
       insert (id_colaborador, id_empresa, id_jornada, dt_inicio_controle, ds_local)
       values (l_id_colab, l_empresa, l_j.id_jornada, trunc(l_agora), l_j.ds_local);

    insert into ponto_marcacao (
      id_empresa, id_colaborador, dt_referencia, tp_marcacao, dh_marcacao,
      ds_origem, ds_ip, ds_navegador, usr_registro
    ) values (
      l_empresa, l_id_colab, trunc(l_agora), p_tp_marcacao, l_agora,
      'NAVEGADOR', l_ip, l_navegador, l_usuario
    ) returning id_marcacao into l_id;

    return l_id;
  exception
    when dup_val_on_index then
      raise_application_error(-20063, 'Esta marcação já foi registrada hoje.');
  end registrar_marcacao;

  ------------------------------------------------------------------------------
  -- Públicas: ajustes
  ------------------------------------------------------------------------------
  procedure validar_mes_aberto (p_id_colaborador in number, p_dt in date) is
    l_qt pls_integer;
    l_competencia constant date := trunc(p_dt, 'MM');
  begin
    select count(*)
      into l_qt
      from ponto_espelho_assinatura
     where id_colaborador = p_id_colaborador
       and dt_competencia = l_competencia;
    if l_qt > 0 then
      raise_application_error(-20070, 'O espelho deste mês já foi assinado e não aceita ajustes. Fale com o RH.');
    end if;
  end validar_mes_aberto;

  -- Os quatro horários do dia, com o novo no lugar, têm de ficar em ordem.
  -- No dia de hoje, o pedido também não pode pular marcações: uma saída aprovada
  -- sem entrada encerraria a jornada e travaria o botão de registrar até o fim do dia.
  procedure validar_ordem (
    p_id_colaborador in number,
    p_dt             in date,
    p_tipo           in varchar2,
    p_dh             in date
  ) is
    type t_horarios is table of date index by varchar2(10);
    l_h t_horarios;
    l_anterior date;
    l_hoje          constant date    := pkg_historico_carreira.fn_hoje(empresa_do_colaborador(p_id_colaborador));
    l_tem_intervalo constant boolean := fn_jornada(p_id_colaborador).nr_min_intervalo > 0;

    procedure conferir (p_t in varchar2) is
    begin
      if l_h.exists(p_t) then
        if l_anterior is not null and l_h(p_t) <= l_anterior then
          raise_application_error(-20069,
            'Os horários do dia ficariam fora de ordem (entrada, intervalo, retorno e saída). Confira o horário.');
        end if;
        l_anterior := l_h(p_t);
      end if;
    end conferir;

    procedure exigir (p_t in varchar2) is
    begin
      if not l_h.exists(p_t) then
        raise_application_error(-20069,
          'Para o dia de hoje, as marcações anteriores precisam estar registradas. Peça primeiro o ajuste delas.');
      end if;
    end exigir;
  begin
    for r in (select tp_marcacao, dh_marcacao
                from vw_ponto_marcacao_vigente
               where id_colaborador = p_id_colaborador
                 and dt_referencia  = p_dt) loop
      l_h(r.tp_marcacao) := r.dh_marcacao;
    end loop;

    if p_dt = l_hoje then
      if p_tipo <> 'ENTRADA' then
        exigir('ENTRADA');
      end if;
      if l_tem_intervalo and p_tipo in ('RETORNO', 'SAIDA') then
        exigir('INTERVALO');
      end if;
      if l_tem_intervalo and p_tipo = 'SAIDA' then
        exigir('RETORNO');
      end if;
    end if;

    l_h(p_tipo) := p_dh;

    conferir('ENTRADA');
    conferir('INTERVALO');
    conferir('RETORNO');
    conferir('SAIDA');
  end validar_ordem;

  function solicitar_ajuste (
    p_dt_referencia in varchar2,
    p_tp_ajuste     in varchar2,
    p_tp_marcacao   in varchar2,
    p_hr_marcacao   in varchar2,
    p_ds_motivo     in varchar2
  ) return number is
    l_id_colab constant number := fn_colaborador_logado;
    l_empresa  constant number := empresa_do_colaborador(l_id_colab);
    l_agora    constant date   := pkg_historico_carreira.fn_data_local(l_empresa, systimestamp);
    l_hoje     constant date   := trunc(l_agora);
    l_dt       constant date   := to_date(p_dt_referencia default null on conversion error, 'DD/MM/YYYY');
    l_tipo     constant varchar2(10) := case when p_tp_ajuste = 'MARCACAO' then p_tp_marcacao end;
    l_dh       date;
    l_qt       pls_integer;
    l_id       number;
  begin
    if l_dt is null then
      raise_application_error(-20065, 'Informe o dia no formato DD/MM/AAAA.');
    elsif l_dt > l_hoje or l_dt < l_hoje - c_dias_ajuste then
      raise_application_error(-20065, 'O ajuste precisa ser de um dia dos últimos ' || c_dias_ajuste || ' dias, até hoje.');
    elsif p_tp_ajuste is null or p_tp_ajuste not in ('MARCACAO', 'ABONO') then
      raise_application_error(-20065, 'Escolha o tipo de ajuste.');
    elsif trim(p_ds_motivo) is null then
      raise_application_error(-20065, 'Explique o motivo do ajuste.');
    end if;

    if p_tp_ajuste = 'MARCACAO' then
      if l_tipo is null or l_tipo not in ('ENTRADA', 'INTERVALO', 'RETORNO', 'SAIDA') then
        raise_application_error(-20065, 'Escolha qual marcação quer incluir ou corrigir.');
      end if;
      if p_hr_marcacao is null or not regexp_like(p_hr_marcacao, '^([01][0-9]|2[0-3]):[0-5][0-9]$') then
        raise_application_error(-20065, 'Informe o horário no formato HH:MM, por exemplo 18:05.');
      end if;
      l_dh := to_date(to_char(l_dt, 'YYYYMMDD') || p_hr_marcacao, 'YYYYMMDDHH24:MI');
      if l_dh > l_agora then
        raise_application_error(-20065, 'O horário informado ainda não aconteceu.');
      end if;
      validar_ordem(l_id_colab, l_dt, l_tipo, l_dh);
    end if;

    validar_mes_aberto(l_id_colab, l_dt);

    select count(*)
      into l_qt
      from ponto_ajuste
     where id_colaborador = l_id_colab
       and dt_referencia  = l_dt
       and st_ajuste      = 'PENDENTE'
       and tp_ajuste      = p_tp_ajuste
       and (tp_marcacao = l_tipo or (tp_marcacao is null and l_tipo is null));
    if l_qt > 0 then
      raise_application_error(-20065, 'Já existe um pedido igual em análise para este dia.');
    end if;

    insert into ponto_ajuste (
      id_empresa, id_colaborador, dt_referencia, tp_ajuste, tp_marcacao, dh_solicitada, ds_motivo
    ) values (
      l_empresa, l_id_colab, l_dt, p_tp_ajuste, l_tipo, l_dh, trim(p_ds_motivo)
    ) returning id_ajuste into l_id;

    return l_id;
  end solicitar_ajuste;

  function fn_pode_aprovar (p_id_ajuste in number) return varchar2 is
    l_aprovador number;
    l_colab     number;
    l_gestor    number;
    l_empresa   constant number := pkg_historico_carreira.fn_empresa_contexto;
  begin
    select a.id_colaborador, c.id_gestor
      into l_colab, l_gestor
      from ponto_ajuste a
      join colaborador c on c.id_colaborador = a.id_colaborador
     where a.id_ajuste  = p_id_ajuste
       and a.id_empresa = l_empresa;

    begin
      l_aprovador := fn_colaborador_logado;
    exception
      when others then
        if sqlcode = -20060 then
          l_aprovador := null; -- conta do RH sem colaborador
        else
          raise;
        end if;
    end;

    if l_aprovador = l_colab then
      return 'N';
    end if;
    return case when l_aprovador = l_gestor or e_rh then 'S' else 'N' end;
  exception
    when no_data_found then
      return 'N';
  end fn_pode_aprovar;

  function fn_e_aprovador return varchar2 is
    l_qt      pls_integer;
    l_usuario constant varchar2(255) := usuario_atual;
    l_empresa constant number := pkg_historico_carreira.fn_empresa_contexto;
  begin
    if e_rh then
      return 'S';
    end if;
    select count(*)
      into l_qt
      from colaborador s
      join colaborador g on g.id_colaborador = s.id_gestor
     where upper(trim(g.login_apex)) = upper(trim(l_usuario))
       and g.id_empresa = l_empresa;
    return case when l_qt > 0 then 'S' else 'N' end;
  end fn_e_aprovador;

  procedure responder_ajuste (
    p_id_ajuste   in number,
    p_st_ajuste   in varchar2,
    p_ds_resposta in varchar2
  ) is
    l_a        ponto_ajuste%rowtype;
    l_usuario  constant varchar2(255) := usuario_atual;
    l_aprovador number;
    l_ip       constant varchar2(64) := ip_origem;
  begin
    begin
      select * into l_a from ponto_ajuste where id_ajuste = p_id_ajuste for update;
    exception
      when no_data_found then
        raise_application_error(-20066, 'Pedido de ajuste não encontrado.');
    end;

    if fn_pode_aprovar(p_id_ajuste) <> 'S' then
      raise_application_error(-20067, 'Você não pode responder a este pedido: ele cabe ao gestor direto ou ao RH.');
    elsif l_a.st_ajuste <> 'PENDENTE' then
      raise_application_error(-20066, 'Este pedido já foi respondido.');
    elsif p_st_ajuste is null or p_st_ajuste not in ('APROVADO', 'RECUSADO') then
      raise_application_error(-20068, 'Escolha aprovar ou recusar.');
    elsif p_st_ajuste = 'RECUSADO' and trim(p_ds_resposta) is null then
      raise_application_error(-20068, 'Explique ao colaborador por que o pedido foi recusado.');
    end if;

    if p_st_ajuste = 'APROVADO' then
      validar_mes_aberto(l_a.id_colaborador, l_a.dt_referencia);
      if l_a.tp_ajuste = 'MARCACAO' then
        validar_ordem(l_a.id_colaborador, l_a.dt_referencia, l_a.tp_marcacao, l_a.dh_solicitada);
        insert into ponto_marcacao (
          id_empresa, id_colaborador, dt_referencia, tp_marcacao, dh_marcacao,
          ds_origem, id_ajuste, ds_ip, usr_registro
        ) values (
          l_a.id_empresa, l_a.id_colaborador, l_a.dt_referencia, l_a.tp_marcacao, l_a.dh_solicitada,
          'AJUSTE', l_a.id_ajuste, l_ip, l_usuario
        );
      end if;
    end if;

    begin
      l_aprovador := fn_colaborador_logado;
    exception
      when others then
        if sqlcode <> -20060 then
          raise;
        end if;
    end;

    update ponto_ajuste
       set st_ajuste    = p_st_ajuste,
           id_aprovador = l_aprovador,
           usr_resposta = l_usuario,
           dh_resposta  = systimestamp,
           ds_resposta  = trim(p_ds_resposta)
     where id_ajuste = p_id_ajuste;
  end responder_ajuste;

  ------------------------------------------------------------------------------
  -- Públicas: assinatura do espelho
  ------------------------------------------------------------------------------
  function fn_prazo_assinatura (p_dt_competencia in date) return date is
  begin
    return add_months(trunc(p_dt_competencia, 'MM'), 2) + 4;
  end fn_prazo_assinatura;

  function fn_competencia_a_assinar (p_id_colaborador in number) return date is
    l_empresa constant number    := empresa_do_colaborador(p_id_colaborador);
    l_j       constant t_jornada := fn_jornada(p_id_colaborador);
    l_hoje    constant date      := pkg_historico_carreira.fn_hoje(l_empresa);
    l_atual   constant date      := trunc(l_hoje, 'MM');

    function pendente (p_mes in date) return boolean is
      l_qt pls_integer;
    begin
      if l_j.dt_inicio_controle > last_day(p_mes) then
        return false;
      end if;
      select count(*)
        into l_qt
        from ponto_espelho_assinatura
       where id_colaborador = p_id_colaborador
         and dt_competencia = p_mes;
      return l_qt = 0;
    end pendente;
  begin
    -- O mês retrasado continua pendente até o dia 5 (fn_prazo_assinatura)
    if l_hoje <= fn_prazo_assinatura(add_months(l_atual, -2)) and pendente(add_months(l_atual, -2)) then
      return add_months(l_atual, -2);
    elsif pendente(add_months(l_atual, -1)) then
      return add_months(l_atual, -1);
    end if;
    return null;
  end fn_competencia_a_assinar;

  procedure assinar_espelho (p_competencia in varchar2) is
    l_id_colab constant number := fn_colaborador_logado;
    l_empresa  constant number := empresa_do_colaborador(l_id_colab);
    l_hoje     constant date   := pkg_historico_carreira.fn_hoje(l_empresa);
    l_mes      constant date   := to_date(p_competencia || '01' default null on conversion error, 'YYYYMMDD');
    l_j        constant t_jornada := fn_jornada(l_id_colab);
    l_usuario  constant varchar2(255) := usuario_atual;
    l_ip       constant varchar2(64)  := ip_origem;
    l_dias     t_dias;
    l_texto    varchar2(4000);
    l_hash     varchar2(64);
  begin
    if l_mes is null or l_mes >= trunc(l_hoje, 'MM') then
      raise_application_error(-20071, 'Só é possível assinar o espelho de um mês já encerrado.');
    elsif l_mes < trunc(l_j.dt_inicio_controle, 'MM') then
      raise_application_error(-20071, 'Não há espelho deste mês para assinar: o controle de ponto começou depois.');
    end if;

    -- O hash registra o que estava no espelho na hora da assinatura
    l_dias := fn_dias(l_id_colab, l_mes, last_day(l_mes));
    for i in 1 .. l_dias.count loop
      l_texto := substr(l_texto
        || to_char(l_dias(i).dt, 'YYYYMMDD')
        || to_char(l_dias(i).dh_entrada, 'HH24MI') || to_char(l_dias(i).dh_intervalo, 'HH24MI')
        || to_char(l_dias(i).dh_retorno, 'HH24MI') || to_char(l_dias(i).dh_saida, 'HH24MI')
        || l_dias(i).nr_saldo || ';', 1, 4000);
    end loop;

    select rawtohex(standard_hash(l_id_colab || '|' || p_competencia || '|' || l_texto, 'SHA256'))
      into l_hash
      from dual;

    insert into ponto_espelho_assinatura (
      id_empresa, id_colaborador, dt_competencia, ds_hash, ds_ip, usr_assinatura
    ) values (
      l_empresa, l_id_colab, l_mes, l_hash, l_ip, l_usuario
    );
  exception
    when dup_val_on_index then
      raise_application_error(-20072, 'Este espelho já foi assinado.');
  end assinar_espelho;

end pkg_ponto;
/
