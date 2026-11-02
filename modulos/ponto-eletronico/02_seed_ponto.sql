--------------------------------------------------------------------------------
-- Corlix Hub · Ponto eletrônico · 02 · dados iniciais
-- Reexecutável: só insere o que falta e não altera o que já existe.
--
-- 1. Uma jornada padrão por empresa (seg a sex, 09:00 às 18:00, 1h de intervalo).
-- 2. Vínculo de cada colaborador com a jornada padrão. O controle começa hoje,
--    para que os dias anteriores à implantação não virem falta.
-- 3. Feriados nacionais de 2026 e 2027. Estaduais, municipais e pontos
--    facultativos são incluídos pela empresa (ver o guia, §1).
--------------------------------------------------------------------------------
set define off

begin
  for e in (select id_empresa from empresa) loop
    insert into ponto_jornada (id_empresa, nm_jornada, nr_min_entrada, nr_min_saida, fl_padrao)
    select e.id_empresa, 'Comercial 40h', 540, 1080, 'S'
      from dual
     where not exists (select 1 from ponto_jornada j where j.id_empresa = e.id_empresa);

    insert into ponto_colaborador (id_colaborador, id_empresa, id_jornada, dt_inicio_controle, ds_local)
    select c.id_colaborador,
           c.id_empresa,
           (select min(j.id_jornada) from ponto_jornada j
             where j.id_empresa = e.id_empresa and j.fl_padrao = 'S'),
           pkg_historico_carreira.fn_hoje(e.id_empresa),
           (select 'Sede ' || x.cidade from empresa x where x.id_empresa = e.id_empresa)
      from colaborador c
     where c.id_empresa = e.id_empresa
       and not exists (select 1 from ponto_colaborador p where p.id_colaborador = c.id_colaborador);
  end loop;
  commit;
end;
/

declare
  type t_feriado is record (dt date, nm varchar2(100));
  type t_feriados is table of t_feriado index by pls_integer;
  l t_feriados;

  procedure add (p_dt in varchar2, p_nm in varchar2) is
    l_i constant pls_integer := l.count + 1;
  begin
    l(l_i).dt := to_date(p_dt, 'DD/MM/YYYY');
    l(l_i).nm := p_nm;
  end add;
begin
  for a in 2026 .. 2027 loop
    add('01/01/' || a, 'Confraternização Universal');
    add('21/04/' || a, 'Tiradentes');
    add('01/05/' || a, 'Dia do Trabalho');
    add('07/09/' || a, 'Independência do Brasil');
    add('12/10/' || a, 'Nossa Senhora Aparecida');
    add('02/11/' || a, 'Finados');
    add('15/11/' || a, 'Proclamação da República');
    add('20/11/' || a, 'Dia da Consciência Negra');
    add('25/12/' || a, 'Natal');
  end loop;
  add('03/04/2026', 'Sexta-feira Santa');
  add('26/03/2027', 'Sexta-feira Santa');

  for e in (select id_empresa from empresa) loop
    for i in 1 .. l.count loop
      begin
        insert into ponto_feriado (id_empresa, dt_feriado, nm_feriado)
        values (e.id_empresa, l(i).dt, l(i).nm);
      exception
        when dup_val_on_index then null;
      end;
    end loop;
  end loop;
  commit;
end;
/
