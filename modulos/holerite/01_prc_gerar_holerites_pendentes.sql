--------------------------------------------------------------------------------
-- Corlix Hub · Holerite digital (página 9) · 01 · geração das folhas pendentes
--
-- Gera, com pkg_holerite.gerar_folha_mensal, os meses que ainda não têm nenhum
-- holerite, de p_inicio até o último mês liberado. Um mês que já tem folha não é
-- tocado, porque gerar_folha_mensal apaga e recria os holerites com o salário de hoje.
--
-- O holerite do mês só existe a partir do dia 25. Antes disso, o último mês liberado
-- é o anterior. A mesma regra está em pkg_holerite_ui (c_dia_liberacao).
--
-- Substitui a geração que a página fazia ao abrir (pkg_holerite.render).
--------------------------------------------------------------------------------
create or replace procedure prc_gerar_holerites_pendentes (
  p_inicio in date default date '2026-06-01',
  p_hoje   in date default sysdate
) authid definer as
  c_dia_liberacao constant pls_integer := 25;
  l_mes    date := trunc(p_inicio, 'MM');
  l_ultimo constant date := case when to_number(to_char(p_hoje, 'DD')) >= c_dia_liberacao
                                 then trunc(p_hoje, 'MM')
                                 else add_months(trunc(p_hoje, 'MM'), -1) end;
  l_qtd    number;
begin
  while l_mes <= l_ultimo loop
    select count(*)
      into l_qtd
      from colaborador_holerite
     where ano_referencia = to_number(to_char(l_mes, 'YYYY'))
       and mes_referencia = to_number(to_char(l_mes, 'MM'));

    if l_qtd = 0 then
      pkg_holerite.gerar_folha_mensal(
        p_mes => to_number(to_char(l_mes, 'MM')),
        p_ano => to_number(to_char(l_mes, 'YYYY')));
    end if;

    l_mes := add_months(l_mes, 1);
  end loop;
end prc_gerar_holerites_pendentes;
/
