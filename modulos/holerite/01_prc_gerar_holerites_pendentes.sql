--------------------------------------------------------------------------------
-- Corlix Hub · Holerite digital (página 9) · 01 · geração dos holerites pendentes
--
-- Para cada colaborador, gera os holerites que faltam, do mês da admissão até o
-- último mês liberado. Um holerite que já existe não é tocado, porque
-- pkg_holerite.gerar_holerite o recriaria com o salário de hoje.
--
-- O holerite do mês só existe a partir do dia 25. Antes disso, o último mês liberado
-- é o anterior. A mesma regra está em pkg_holerite_ui (c_dia_liberacao).
-- Quem ainda não foi admitido, ou não tem data de admissão, fica de fora.
--
-- Substitui a geração que a página fazia ao abrir (pkg_holerite.render).
--------------------------------------------------------------------------------
create or replace procedure prc_gerar_holerites_pendentes (
  p_hoje in date default sysdate
) authid definer as
  c_dia_liberacao constant pls_integer := 25;
  l_ultimo constant date := case when to_number(to_char(p_hoje, 'DD')) >= c_dia_liberacao
                                 then trunc(p_hoje, 'MM')
                                 else add_months(trunc(p_hoje, 'MM'), -1) end;
begin
  for r in (
    select c.id_colaborador, m.competencia
      from colaborador c
     cross join lateral (
             select add_months(trunc(c.data_admissao, 'MM'), level - 1) as competencia
               from dual
            connect by level <= months_between(l_ultimo, trunc(c.data_admissao, 'MM')) + 1
           ) m
     where c.data_admissao <= p_hoje
       and trunc(c.data_admissao, 'MM') <= l_ultimo
       and not exists (
             select 1
               from colaborador_holerite h
              where h.id_colaborador = c.id_colaborador
                and h.ano_referencia = to_number(to_char(m.competencia, 'YYYY'))
                and h.mes_referencia = to_number(to_char(m.competencia, 'MM')))
  ) loop
    pkg_holerite.gerar_holerite(
      p_id_colaborador => r.id_colaborador,
      p_mes            => to_number(to_char(r.competencia, 'MM')),
      p_ano            => to_number(to_char(r.competencia, 'YYYY')));
  end loop;
  commit;
end prc_gerar_holerites_pendentes;
/
