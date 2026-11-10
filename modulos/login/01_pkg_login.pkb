--------------------------------------------------------------------------------
-- Corlix Hub · Login (página 9999) · regra de negócio · corpo
--------------------------------------------------------------------------------
create or replace package body pkg_login as

  function resolver_login (p_usuario in varchar2) return varchar2 is
    l_usuario varchar2(255) := trim(p_usuario);
    l_login   colaborador.login_apex%type;
  begin
    if l_usuario is null or instr(l_usuario, '@') = 0 then
      return l_usuario;
    end if;

    select c.login_apex
      into l_login
      from colaborador c
     where lower(trim(c.email)) = lower(l_usuario)
       and c.login_apex is not null;

    return l_login;
  exception
    when no_data_found or too_many_rows then
      return l_usuario;
  end resolver_login;

end pkg_login;
/
