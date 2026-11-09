-- Executar antes de 01_vw_colaboradores_lista.sql.
-- Depende do contexto de workspace APEX; não usa cache de resultados.
create or replace function fn_colab_tem_papel (
    p_login in varchar2,
    p_papel in varchar2,
    p_app_id in number
) return number
authid definer
is
begin
    if p_login is null or p_app_id is null then
        return 0;
    end if;
    if apex_acl.has_user_role(
        p_application_id => p_app_id,
        p_user_name => p_login,
        p_role_static_id => p_papel
    ) then
        return 1;
    end if;
    return 0;
end;
/
