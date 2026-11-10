--------------------------------------------------------------------------------
-- Corlix Hub · Home · remove os comunicados de demonstração
-- Apaga só os criados pelo 01_comunicados_demo.sql (NOME_ARQUIVO demo-comunicado-N.jpg),
-- de todas as empresas. As leituras saem junto (FK com ON DELETE CASCADE).
--------------------------------------------------------------------------------
set serveroutput on

begin
  delete from comunicado
   where nome_arquivo in ('demo-comunicado-1.jpg', 'demo-comunicado-2.jpg', 'demo-comunicado-3.jpg',
                          'demo-comunicado-4.jpg', 'demo-comunicado-5.jpg');
  dbms_output.put_line(sql%rowcount || ' comunicado(s) de demonstração removido(s).');
  commit;
end;
/
