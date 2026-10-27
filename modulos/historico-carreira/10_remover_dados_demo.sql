--------------------------------------------------------------------------------
-- Corlix Hub · Histórico de Carreira
-- 10 · Remove os dados de demonstração criados pelo 09_dados_demo_dashboard.sql
--
-- Apaga só o que é [DEMO] da empresa C_EMPRESA: colaboradores com login
-- DEMO.CARREIRA.*, seus lançamentos, formações, solicitações e acessos salariais,
-- e os cargos "[DEMO] ...".
--
-- Lançamentos efetivados não podem ser apagados por DML (a trigger
-- TRG_HISTORICO_CARREIRA_AUD protege a trilha). Por isso o script desliga a
-- trigger só durante o DELETE e a religa logo depois, inclusive se der erro.
-- Rode como dono do schema em SQL Workshop › SQL Scripts (SQL Commands roda um
-- comando por vez).
--------------------------------------------------------------------------------
set serveroutput on size unlimited

declare
  c_empresa constant number := 1;   -- <<< a mesma empresa usada no 09

  l_qt_hist pls_integer;
  l_qt_col  pls_integer;

  procedure trigger_trilha (p_ligar in boolean) is
  begin
    execute immediate 'alter trigger trg_historico_carreira_aud '
                      || case when p_ligar then 'enable' else 'disable' end;
  end trigger_trilha;
begin
  trigger_trilha(false);
  begin
    delete from solicitacao_correcao
     where id_colaborador in (select id_colaborador from colaborador
                               where id_empresa = c_empresa and login_apex like 'DEMO.CARREIRA.%');

    delete from formacao_colaborador
     where id_colaborador in (select id_colaborador from colaborador
                               where id_empresa = c_empresa and login_apex like 'DEMO.CARREIRA.%');

    delete from log_acesso_salarial
     where id_colaborador in (select id_colaborador from colaborador
                               where id_empresa = c_empresa and login_apex like 'DEMO.CARREIRA.%');

    delete from historico_carreira
     where id_colaborador in (select id_colaborador from colaborador
                               where id_empresa = c_empresa and login_apex like 'DEMO.CARREIRA.%');
    l_qt_hist := sql%rowcount;

    trigger_trilha(true);   -- o ALTER faz commit dos DELETEs acima
  exception
    when others then
      rollback;
      trigger_trilha(true);
      raise;
  end;

  delete from colaborador
   where id_empresa = c_empresa
     and login_apex like 'DEMO.CARREIRA.%';
  l_qt_col := sql%rowcount;

  delete from cargo
   where id_empresa = c_empresa
     and nome like '[DEMO]%';

  commit;

  dbms_output.put_line('Removidos: ' || l_qt_col || ' colaboradores [DEMO] e ' || l_qt_hist || ' lançamentos.');
end;
/

-- Conferência: deve voltar 0 e a trigger deve estar ENABLED
select count(*) as colaboradores_demo
  from colaborador
 where login_apex like 'DEMO.CARREIRA.%';

select trigger_name, status
  from user_triggers
 where trigger_name = 'TRG_HISTORICO_CARREIRA_AUD';
