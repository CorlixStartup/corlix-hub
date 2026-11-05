--------------------------------------------------------------------------------
-- Corlix Hub · Holerite digital (página 9) · 01 · geração das folhas pendentes
--
-- Gera, com pkg_holerite.gerar_folha_mensal, os meses que ainda não têm nenhum
-- holerite, de p_inicio até o mês atual. Um mês que já tem folha não é tocado,
-- porque gerar_folha_mensal apaga e recria os holerites com o salário de hoje.
--
-- Substitui a geração que a página fazia ao abrir (pkg_holerite.render).
--------------------------------------------------------------------------------
create or replace procedure prc_gerar_holerites_pendentes (
  p_inicio in date default date '2026-06-01'
) authid definer as
  l_mes date := trunc(p_inicio, 'MM');
  l_qtd number;
begin
  while l_mes <= trunc(sysdate, 'MM') loop
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
