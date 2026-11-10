--------------------------------------------------------------------------------
-- Corlix Hub · Blocos da Home · 03 · remove os dados de demonstração do 02
-- Apaga só o que o 02 cria (pelos textos e títulos fixos), em todas as empresas.
--------------------------------------------------------------------------------
set serveroutput on

begin
  delete from feedback
   where ds_texto in ('A apresentação dos indicadores na reunião de segunda foi clara e ajudou o time a decidir rápido o que priorizar.',
                      'Vale automatizar a planilha de filas. Posso mostrar como fiz no relatório mensal.');
  dbms_output.put_line('feedback: ' || sql%rowcount);
  delete from pesquisa where ds_titulo = 'Pesquisa de clima 2026' and ds_link = 'https://www.example.com/pesquisa-de-clima';
  dbms_output.put_line('pesquisa: ' || sql%rowcount);
  delete from evento where ds_titulo in ('Café com a diretoria', 'Palestra Novembro Azul', 'Inventário trimestral');
  dbms_output.put_line('evento: ' || sql%rowcount);
  delete from conversa_1a1 where ds_pauta = 'Acompanhamento do PDI e prioridades do mês';
  dbms_output.put_line('conversa_1a1: ' || sql%rowcount);
  delete from pdi where ds_titulo = 'PDI 2026 · demonstração';
  dbms_output.put_line('pdi: ' || sql%rowcount);
  -- ferias_periodo fica: não há como separar o exemplo de um período real
  commit;
end;
/
