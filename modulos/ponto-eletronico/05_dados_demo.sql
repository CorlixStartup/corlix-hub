--------------------------------------------------------------------------------
-- Corlix Hub · Ponto eletrônico · 05 · dados de demonstração (opcional)
-- Monta seis meses de ponto para UM colaborador: dias regulares, horas extras,
-- abono, marcação ausente, crédito perto de vencer e espelho a assinar.
-- Troque 0 em c_id_colaborador pelo colaborador da conta de teste:
--   select id_colaborador, nome_completo, login_apex from colaborador where login_apex is not null
-- Pode rodar de novo: apaga a demonstração anterior desse colaborador antes.
-- Para tirar tudo: 06_remover_dados_demo.sql. Não rode em produção.
--------------------------------------------------------------------------------
set define off

declare
  c_id_colaborador constant number := 0;

  l_empresa number;
  l_jornada number;
  l_hoje    date;
  l_inicio  date;
  l_d       date;
  l_n       pls_integer := 0;
  l_e       number;
  l_i       number;
  l_r       number;
  l_s       number;
  l_ultimo  date;  -- último dia útil antes de hoje: fica sem saída
  l_abonado date;  -- dia útil anterior a ele: abono aprovado

  procedure marca (p_dt in date, p_tipo in varchar2, p_min in number) is
  begin
    insert into ponto_marcacao (id_empresa, id_colaborador, dt_referencia, tp_marcacao, dh_marcacao, ds_origem, usr_registro)
    values (l_empresa, c_id_colaborador, p_dt, p_tipo, p_dt + p_min / 1440, 'DEMO', 'DEMO');
  end marca;

  function util (p_dt in date) return boolean is
    l_f pls_integer;
  begin
    select count(*) into l_f from ponto_feriado where id_empresa = l_empresa and dt_feriado = p_dt;
    return p_dt - trunc(p_dt, 'IW') < 5 and l_f = 0;
  end util;
begin
  begin
    select id_empresa into l_empresa from colaborador where id_colaborador = c_id_colaborador;
  exception
    when no_data_found then
      raise_application_error(-20060, 'Troque c_id_colaborador pelo id de um colaborador que exista.');
  end;
  l_hoje   := pkg_historico_carreira.fn_hoje(l_empresa);
  l_inicio := add_months(trunc(l_hoje, 'MM'), -5);

  select min(id_jornada) into l_jornada from ponto_jornada where id_empresa = l_empresa and fl_padrao = 'S';

  delete from ponto_marcacao where id_colaborador = c_id_colaborador and ds_origem = 'DEMO';
  delete from ponto_ajuste where id_colaborador = c_id_colaborador and ds_motivo like '[DEMO]%';

  merge into ponto_colaborador p
  using (select c_id_colaborador as id from dual) s
     on (p.id_colaborador = s.id)
   when matched then update set dt_inicio_controle = l_inicio
   when not matched then
     insert (id_colaborador, id_empresa, id_jornada, dt_inicio_controle, ds_local)
     values (c_id_colaborador, l_empresa, l_jornada, l_inicio, 'Sede');

  l_ultimo := l_hoje - 1;
  while not util(l_ultimo) loop
    l_ultimo := l_ultimo - 1;
  end loop;
  l_abonado := l_ultimo - 1;
  while not util(l_abonado) loop
    l_abonado := l_abonado - 1;
  end loop;

  l_d := l_inicio;
  while l_d < l_hoje loop
    if util(l_d) then
      l_n := l_n + 1;
      -- 8h dentro da tolerância, com variação pequena
      l_e := 540 - mod(l_n, 4);
      l_i := 720 + mod(l_n, 3);
      l_r := 780 + mod(l_n, 3);
      l_s := 1080 + mod(l_n, 5);

      if l_n = 1 then
        -- Primeiro dia: 2h10 extras, que vencem em breve (aviso do banco de horas)
        l_s := 1210;
        l_e := 540; l_i := 720; l_r := 780;
      elsif mod(l_n, 11) = 0 then
        l_s := 1080 + 75; -- 1h15 extras
      elsif mod(l_n, 17) = 0 then
        l_s := 1080 - 45; -- 45 min a menos
      end if;

      if l_d = l_ultimo then
        marca(l_d, 'ENTRADA', l_e);
        marca(l_d, 'INTERVALO', l_i);
        marca(l_d, 'RETORNO', l_r);
      elsif l_d = l_abonado then
        -- Saiu duas horas mais cedo, com abono aprovado
        marca(l_d, 'ENTRADA', 540);
        marca(l_d, 'INTERVALO', 720);
        marca(l_d, 'RETORNO', 780);
        marca(l_d, 'SAIDA', 960);
        insert into ponto_ajuste (id_empresa, id_colaborador, dt_referencia, tp_ajuste, ds_motivo, st_ajuste, usr_resposta, dh_resposta, ds_resposta)
        values (l_empresa, c_id_colaborador, l_d, 'ABONO', '[DEMO] Consulta médica com atestado', 'APROVADO', 'DEMO', systimestamp, 'Abono aprovado');
      else
        marca(l_d, 'ENTRADA', l_e);
        marca(l_d, 'INTERVALO', l_i);
        marca(l_d, 'RETORNO', l_r);
        marca(l_d, 'SAIDA', l_s);
      end if;
    end if;
    l_d := l_d + 1;
  end loop;

  commit;
  dbms_output.put_line('Demonstração criada a partir de ' || to_char(l_inicio, 'DD/MM/YYYY') || '.');
end;
/
