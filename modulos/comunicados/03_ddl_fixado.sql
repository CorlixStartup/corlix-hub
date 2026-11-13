--------------------------------------------------------------------------------
-- Corlix Hub · Comunicados · 03 · "Fixar no topo"
-- Reexecutável (confere o dicionário antes de alterar).
--
-- comunicado.fl_fixado -> 'S' aparece primeiro no carrossel da Home e na
--                         lista de comunicados; 'N' (padrão) segue pela data.
-- VARCHAR2 'S'/'N', e não BOOLEAN: o item Checkbox do APEX grava texto
-- (Checked Value 'S', Unchecked Value 'N').
--------------------------------------------------------------------------------
set define off

declare
  l_qt pls_integer;
begin
  select count(*) into l_qt from user_tab_columns
   where table_name = 'COMUNICADO' and column_name = 'FL_FIXADO';
  if l_qt = 0 then
    execute immediate 'alter table comunicado add (fl_fixado varchar2(1) default ''N'' not null)';
  end if;

  select count(*) into l_qt from user_constraints
   where table_name = 'COMUNICADO' and constraint_name = 'CK_COM_FIXADO';
  if l_qt = 0 then
    execute immediate 'alter table comunicado add constraint ck_com_fixado check (fl_fixado in (''S'', ''N''))';
  end if;
end;
/

comment on column comunicado.fl_fixado is 'S = fixado no topo da lista de comunicados e do carrossel da Home.';
