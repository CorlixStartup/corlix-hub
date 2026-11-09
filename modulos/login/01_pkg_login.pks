--------------------------------------------------------------------------------
-- Corlix Hub · Login (página 9999) · regra de negócio · especificação
--   resolver_login -> aceita o login APEX ou o e-mail corporativo no campo
--                     "Login ou e-mail corporativo" e devolve o login APEX.
-- A página é pública: a função não devolve nada além do login e não indica
-- se o e-mail existe. A credencial continua sendo validada por
-- APEX_AUTHENTICATION.LOGIN, com a mesma mensagem para qualquer erro.
--------------------------------------------------------------------------------
create or replace package pkg_login authid definer as

  -- Sem "@", devolve o texto sem espaços nas pontas. Com "@", procura um único
  -- colaborador com esse e-mail e login preenchido; sem correspondência única
  -- (nenhuma ou mais de uma), devolve o texto digitado e o login falha
  -- normalmente.
  function resolver_login (p_usuario in varchar2) return varchar2;

end pkg_login;
/
