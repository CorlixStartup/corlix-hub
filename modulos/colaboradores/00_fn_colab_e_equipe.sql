-- Executar antes de 01_vw_colaboradores_lista.sql.
-- Usa a mesma autorização do menu; fora da app 100 (SQL Commands, backup) devolve 0.
create or replace function fn_colab_e_equipe
return number
authid definer
is
begin
    if nvl(v('APP_ID'), '0') <> '100' then
        return 0;
    end if;
    return case when apex_authorization.is_authorized('EQUIPE_CORLIX_HUB') then 1 else 0 end;
end;
/
