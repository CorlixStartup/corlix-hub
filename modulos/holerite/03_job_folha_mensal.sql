--------------------------------------------------------------------------------
-- Corlix Hub · Holerite digital (página 9) · 03 · job da folha mensal
--
-- Todo dia 25, às 06:00, gera a folha do mês se ela ainda não existir.
-- Reexecutável: recria o job. Para desligar:
--   begin dbms_scheduler.drop_job('JOB_FOLHA_MENSAL'); end;
--------------------------------------------------------------------------------
begin
  begin
    dbms_scheduler.drop_job(job_name => 'JOB_FOLHA_MENSAL');
  exception
    when others then
      if sqlcode != -27475 then -- o job ainda não existe
        raise;
      end if;
  end;

  dbms_scheduler.create_job(
    job_name        => 'JOB_FOLHA_MENSAL',
    job_type        => 'PLSQL_BLOCK',
    job_action      => 'begin prc_gerar_holerites_pendentes; end;',
    repeat_interval => 'FREQ=MONTHLY;BYMONTHDAY=25;BYHOUR=6;BYMINUTE=0;BYSECOND=0',
    enabled         => true,
    comments        => 'Corlix Hub: gera a folha do mês para a página 9 (Holerite digital)');
end;
/
