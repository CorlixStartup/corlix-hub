--------------------------------------------------------------------------------
-- Corlix Hub · Comunicados · 02 · categoria dos comunicados de demonstração
-- Dá categoria aos 5 comunicados criados por modulos/home/dados-demo/01_comunicados_demo.sql
-- (identificados pelo NOME_ARQUIVO). Rode depois do 01. Reexecutável.
--------------------------------------------------------------------------------
set serveroutput on

begin
  for r in (select 'demo-comunicado-1.jpg' arq, 'Saúde e bem-estar' cat from dual union all
            select 'demo-comunicado-2.jpg', 'Institucional' from dual union all
            select 'demo-comunicado-3.jpg', 'Treinamentos'  from dual union all
            select 'demo-comunicado-4.jpg', 'Eventos'       from dual union all
            select 'demo-comunicado-5.jpg', 'Resultados'    from dual) loop
    update comunicado c
       set c.id_categoria = (select k.id_categoria
                               from categoria_comunicado k
                              where k.id_empresa = c.id_empresa
                                and k.nm_categoria = r.cat)
     where c.nome_arquivo = r.arq;
    dbms_output.put_line(r.arq || ' -> ' || r.cat || ': ' || sql%rowcount || ' linha(s)');
  end loop;
  commit;
end;
/
