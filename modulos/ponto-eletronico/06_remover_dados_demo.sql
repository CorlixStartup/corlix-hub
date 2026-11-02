--------------------------------------------------------------------------------
-- Corlix Hub · Ponto eletrônico · 06 · remove os dados de demonstração
-- Apaga só o que o 05_dados_demo.sql criou e, para quem o usou, faz o controle
-- de ponto recomeçar hoje (os meses sem marcação não viram falta).
-- O espelho assinado durante o teste também sai. Marcações de ajustes aprovados
-- no teste ficam: são imutáveis (trigger) e continuam no espelho daquele dia.
--------------------------------------------------------------------------------
set define off

begin
  for c in (select distinct m.id_colaborador, m.id_empresa
              from ponto_marcacao m
             where m.ds_origem = 'DEMO') loop
    delete from ponto_espelho_assinatura
     where id_colaborador = c.id_colaborador;

    update ponto_colaborador
       set dt_inicio_controle = pkg_historico_carreira.fn_hoje(c.id_empresa)
     where id_colaborador = c.id_colaborador;
  end loop;

  delete from ponto_marcacao where ds_origem = 'DEMO';
  delete from ponto_ajuste where ds_motivo like '[DEMO]%';
  commit;
end;
/
