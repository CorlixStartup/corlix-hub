--------------------------------------------------------------------------------
-- Corlix Hub · Holerite digital (página 9) · 03 · job da folha
--
-- Todo dia, às 06:00, gera os holerites que faltam. Roda todo dia para pegar quem
-- foi admitido depois do dia 25. Só o que falta é gerado; o mês atual entra a partir
-- do dia 25 (prc_gerar_holerites_pendentes).
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
    repeat_interval => 'FREQ=DAILY;BYHOUR=6;BYMINUTE=0;BYSECOND=0',
    enabled         => true,
    comments        => 'Corlix Hub: gera os holerites pendentes da página 9 (Holerite digital)');
end;
/
