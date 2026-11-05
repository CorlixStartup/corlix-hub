--------------------------------------------------------------------------------
-- Corlix Hub · Holerite digital (página 9) · 00 · cálculo da folha · especificação
-- Substitui a versão do banco (database/ddl/08-plsql-especificacoes.sql).
--------------------------------------------------------------------------------
create or replace package pkg_holerite as

  -- Apaga e recria o holerite de uma pessoa no mês, com o salário atual do cargo.
  -- Não faz commit. Sem cargo ou com salário zerado, não gera nada.
  procedure gerar_holerite (p_id_colaborador in number, p_mes in number, p_ano in number);

  -- Gera o mês para todos os colaboradores já admitidos até o fim dele
  procedure gerar_folha_mensal (p_mes in number, p_ano in number);

  -- Versão antiga da página 9. Só fica aqui para o caso de voltar atrás.
  function render (p_mes in number, p_ano in number) return clob;

end pkg_holerite;
/
