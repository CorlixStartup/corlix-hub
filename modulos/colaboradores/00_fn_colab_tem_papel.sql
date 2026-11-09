-- Executar antes de 01_vw_colaboradores_lista.sql.
-- Consulta o papel dentro da função, isolada da agregação das facetas.
-- APEX_ACL.HAS_USER_ROLE foi substituída: não reconheceu papéis atribuídos na app.
create or replace function fn_colab_tem_papel (
    p_login in varchar2,
    p_papel in varchar2,
    p_app_id in number
) return number
authid definer
is
    l_qt pls_integer;
begin
    if p_login is null or p_app_id is null then
        return 0;
    end if;
    select count(*)
      into l_qt
      from apex_appl_acl_user_roles
     where application_id = p_app_id
       and upper(user_name) = upper(trim(p_login))
       and role_static_id = p_papel;
    return case when l_qt > 0 then 1 else 0 end;
end;
/
