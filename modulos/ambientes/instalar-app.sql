-- =============================================================================
-- Corlix Hub · Instala a app (database/f100.sql) num ambiente: UAT ou PRD
-- Guia: modulos/ambientes/Etapas-ambientes.md (3.4, 6.1 e 6.4)
--
-- Uso no SQLcl, conectado como dono do schema do destino, a partir da raiz
-- do repositório:
--   @modulos/ambientes/instalar-app.sql <workspace> <schema> <app_id> <build_status>
--
--   <workspace> é o nome que aparece em Administration Services > Manage Workspaces.
--   DEV (só na criação): @modulos/ambientes/instalar-app.sql CORLIXHUB     WKSP_CORLIXHUB     100 RUN_AND_BUILD
--   UAT:                 @modulos/ambientes/instalar-app.sql CORLIXHUB_UAT WKSP_WKSPCORLIXHUBUAT 200 RUN_ONLY
--   PRD:                 @modulos/ambientes/instalar-app.sql CORLIXHUB     WKSP_CORLIXHUB     100 RUN_ONLY
--
-- O que faz:
--   1. Guarda os papéis (ACL) que cada usuário tem hoje na app de destino.
--   2. Importa database/f100.sql com o ID, o schema e o Build Status do destino.
--      No UAT, o ID 200 recebe um offset novo (o ID é único na instância).
--      No UAT e no PRD, RUN_ONLY mantém o Builder bloqueado depois de cada versão.
--   3. Deixa os papéis como estavam: devolve os que a importação tirou e, no UAT
--      e no PRD (RUN_ONLY), tira os que vieram da origem no export.
--   4. Recompila o schema e lista os objetos inválidos.
--
-- Não roda DDL nem packages: as mudanças de banco de cada versão são aplicadas
-- antes, pelo instalar.sql do módulo (ver o guia, 6.2).
-- =============================================================================
whenever sqlerror exit failure rollback
set serveroutput on size unlimited
set verify off
-- Liga a troca de &1..&4 mesmo se a sessão vier de um "set define off"
set define on

define workspace    = '&1'
define schema_dono  = '&2'
define app_destino  = '&3'
define build_status = '&4'

prompt == Destino: workspace &workspace, schema &schema_dono, app &app_destino, &build_status

-- O export do APEX 26.1 leva os usuários de cada papel (p_users do
-- create_acl_role). A importação os aplica no destino; o passo 3 desfaz isso no
-- UAT e no PRD. Para ver quantos papéis o arquivo traz:
--   grep -c "p_users=>" database/f100.sql

begin
  if '&build_status' not in ('RUN_ONLY', 'RUN_AND_BUILD') then
    raise_application_error(-20000, 'build_status deve ser RUN_ONLY ou RUN_AND_BUILD.');
  end if;
  if upper(user) <> upper('&schema_dono') then
    raise_application_error(-20000, 'Conectado como ' || user || ', mas o destino é &schema_dono.');
  end if;
  apex_util.set_workspace(p_workspace => '&workspace');
end;
/

-- O schema conectado tem de pertencer ao workspace informado
declare
  l_qt pls_integer;
begin
  select count(*) into l_qt
    from apex_workspace_schemas
   where workspace_name = upper('&workspace')
     and schema = user;
  if l_qt = 0 then
    raise_application_error(-20000,
      'O schema ' || user || ' não pertence ao workspace &workspace. Confira o nome em Manage Workspaces.');
  end if;
end;
/

-- 1. Papéis de hoje (tabela temporária só desta sessão; some ao desconectar)
create private temporary table ora$ptt_acl_antes
  on commit preserve definition
as
select user_name, role_static_id
  from apex_appl_acl_user_roles
 where application_id = &app_destino;

select count(*) as papeis_antes from ora$ptt_acl_antes;

-- 2. Importação
begin
  apex_application_install.clear_all;
  apex_application_install.set_workspace(p_workspace => '&workspace');
  apex_application_install.set_application_id(p_application_id => &app_destino);
  if &app_destino <> 100 then
    apex_application_install.generate_offset;
  end if;
  apex_application_install.set_schema(p_schema => '&schema_dono');
  apex_application_install.set_application_alias(p_application_alias => 'CORLIXHUB');
  apex_application_install.set_build_status(p_build_status => '&build_status');
end;
/

@database/f100.sql

whenever sqlerror exit failure rollback
set serveroutput on size unlimited
set verify off

-- 3. Deixa os papéis como estavam antes da importação.
--    O export do APEX 26.1 leva os usuários de cada papel em create_acl_role
--    (p_users), não em create_acl_assignment: a importação dá aos usuários do
--    destino os papéis do ambiente de origem. No UAT e no PRD (RUN_ONLY), tira os
--    que não existiam antes; na criação do DEV (RUN_AND_BUILD), mantém os do PRD.
declare
  l_qt pls_integer := 0;
begin
  apex_util.set_workspace(p_workspace => '&workspace');
  if '&build_status' = 'RUN_ONLY' then
    for r in (
      select d.user_name, d.role_static_id
        from apex_appl_acl_user_roles d
       where d.application_id = &app_destino
         and not exists (
               select 1
                 from ora$ptt_acl_antes a
                where a.user_name = d.user_name
                  and a.role_static_id = d.role_static_id)
    ) loop
      apex_acl.remove_user_role(
        p_application_id => &app_destino,
        p_user_name      => r.user_name,
        p_role_static_id => r.role_static_id);
      l_qt := l_qt + 1;
    end loop;
  end if;
  dbms_output.put_line('Papéis da origem retirados depois da importação: ' || l_qt);
  l_qt := 0;
  for r in (
    select a.user_name, a.role_static_id
      from ora$ptt_acl_antes a
     where not exists (
             select 1
               from apex_appl_acl_user_roles d
              where d.application_id = &app_destino
                and d.user_name = a.user_name
                and d.role_static_id = a.role_static_id)
  ) loop
    apex_acl.add_user_role(
      p_application_id => &app_destino,
      p_user_name      => r.user_name,
      p_role_static_id => r.role_static_id);
    l_qt := l_qt + 1;
  end loop;
  commit;
  dbms_output.put_line('Papéis devolvidos depois da importação: ' || l_qt);
end;
/

select count(*) as papeis_depois
  from apex_appl_acl_user_roles
 where application_id = &app_destino;

-- 4. Recompila e lista o que ficou inválido (não falha: mostra para conferência)
exec dbms_utility.compile_schema(schema => user, compile_all => false);

select object_type, object_name
  from user_objects
 where status = 'INVALID'
 order by object_type, object_name;

select application_id, alias, build_status
  from apex_applications
 where application_id = &app_destino;

drop table ora$ptt_acl_antes;
prompt == Instalação concluída.
