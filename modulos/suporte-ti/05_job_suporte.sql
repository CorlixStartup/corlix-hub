--------------------------------------------------------------------------------
-- Corlix Hub · Suporte TI · 05 · job de encerramento
-- Reexecutável: recria o job. Todo dia às 23:30 (horário de Brasília), encerra os
-- chamados resolvidos cujo prazo de confirmação termina hoje ou já terminou.
--------------------------------------------------------------------------------
begin
  begin
    dbms_scheduler.drop_job(job_name => 'SUPORTE_ENCERRAR_VENCIDOS', force => true);
  exception
    when others then
      if sqlcode <> -27475 then -- job ainda não existe
        raise;
      end if;
  end;

  dbms_scheduler.create_job(
    job_name        => 'SUPORTE_ENCERRAR_VENCIDOS',
    job_type        => 'PLSQL_BLOCK',
    job_action      => 'declare l_qt number; begin l_qt := pkg_suporte.encerrar_vencidos; end;',
    start_date      => to_timestamp_tz('2026-01-01 23:30:00 America/Sao_Paulo', 'YYYY-MM-DD HH24:MI:SS TZR'),
    repeat_interval => 'FREQ=DAILY',
    enabled         => true,
    comments        => 'Suporte TI: encerra chamados resolvidos sem confirmação do colaborador');
end;
/
