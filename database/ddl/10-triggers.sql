
  CREATE OR REPLACE EDITIONABLE TRIGGER "TRG_CONFIG_CARREIRA_AUD"
before insert or update on config_carreira
for each row
declare
  l_usuario varchar2(255) := coalesce(sys_context('APEX$SESSION', 'APP_USER'), sys_context('USERENV', 'SESSION_USER'));
begin
  if inserting then
    :new.dt_criacao    := systimestamp;
    :new.usr_criacao   := l_usuario;
    :new.dt_alteracao  := null;
    :new.usr_alteracao := null;
  else
    :new.dt_criacao    := :old.dt_criacao;
    :new.usr_criacao   := :old.usr_criacao;
    :new.dt_alteracao  := systimestamp;
    :new.usr_alteracao := l_usuario;
  end if;
end;
/
ALTER TRIGGER "TRG_CONFIG_CARREIRA_AUD" ENABLE;

  CREATE OR REPLACE EDITIONABLE TRIGGER "TRG_FORMACAO_COLABORADOR_AUD"
before insert or update on formacao_colaborador
for each row
declare
  l_usuario varchar2(255) := coalesce(sys_context('APEX$SESSION', 'APP_USER'), sys_context('USERENV', 'SESSION_USER'));
begin
  if inserting then
    :new.dt_criacao    := systimestamp;
    :new.usr_criacao   := l_usuario;
    :new.dt_alteracao  := null;
    :new.usr_alteracao := null;
  else
    :new.dt_criacao    := :old.dt_criacao;
    :new.usr_criacao   := :old.usr_criacao;
    :new.dt_alteracao  := systimestamp;
    :new.usr_alteracao := l_usuario;
  end if;
end;
/
ALTER TRIGGER "TRG_FORMACAO_COLABORADOR_AUD" ENABLE;

  CREATE OR REPLACE EDITIONABLE TRIGGER "TRG_FORMACAO_COLABORADOR_LOG"
after insert or update or delete on formacao_colaborador
for each row
declare
  -- inserting/updating só valem em PL/SQL; dentro do insert dão ORA-00984
  l_op log_auditoria_carreira.tp_operacao%type :=
    case when inserting then 'I' when updating then 'U' else 'D' end;
begin
  insert into log_auditoria_carreira (
    id_empresa, nm_tabela, id_registro, tp_operacao, usr_criacao
  ) values (
    coalesce(:new.id_empresa, :old.id_empresa),
    'FORMACAO_COLABORADOR',
    coalesce(:new.id_formacao, :old.id_formacao),
    l_op,
    coalesce(sys_context('APEX$SESSION', 'APP_USER'), sys_context('USERENV', 'SESSION_USER'))
  );
end;
/
ALTER TRIGGER "TRG_FORMACAO_COLABORADOR_LOG" ENABLE;

  CREATE OR REPLACE EDITIONABLE TRIGGER "TRG_HISTORICO_CARREIRA_AUD"
before insert or update or delete on historico_carreira
for each row
declare
  l_usuario varchar2(255) := coalesce(sys_context('APEX$SESSION', 'APP_USER'), sys_context('USERENV', 'SESSION_USER'));

  -- Comparações que tratam nulo como valor
  function mudou (p_old in number, p_new in number) return boolean is
  begin
    return (p_old <> p_new) or (p_old is null and p_new is not null) or (p_old is not null and p_new is null);
  end mudou;

  function mudou (p_old in date, p_new in date) return boolean is
  begin
    return (p_old <> p_new) or (p_old is null and p_new is not null) or (p_old is not null and p_new is null);
  end mudou;

  function mudou (p_old in timestamp with time zone, p_new in timestamp with time zone) return boolean is
  begin
    return (p_old <> p_new) or (p_old is null and p_new is not null) or (p_old is not null and p_new is null);
  end mudou;

  function mudou (p_old in varchar2, p_new in varchar2) return boolean is
  begin
    return (p_old <> p_new) or (p_old is null and p_new is not null) or (p_old is not null and p_new is null);
  end mudou;

  function mudou_clob (p_old in clob, p_new in clob) return boolean is
  begin
    if p_old is null and p_new is null then
      return false;
    elsif p_old is null or p_new is null then
      return true;
    end if;
    return dbms_lob.compare(p_old, p_new) <> 0;
  end mudou_clob;
begin
  if inserting then
    :new.dt_criacao    := systimestamp;
    :new.usr_criacao   := l_usuario;
    :new.dt_alteracao  := null;
    :new.usr_alteracao := null;

  elsif updating then
    if :old.st_registro <> 'RASCUNHO' then
      if not (    :old.st_registro = 'EFETIVADO'
              and :new.st_registro = 'ESTORNADO'
              and not mudou(:old.id_empresa,               :new.id_empresa)
              and not mudou(:old.id_colaborador,           :new.id_colaborador)
              and not mudou(:old.id_tipo_movimentacao,     :new.id_tipo_movimentacao)
              and not mudou(:old.dt_efetiva,               :new.dt_efetiva)
              and not mudou(:old.id_cargo_anterior,        :new.id_cargo_anterior)
              and not mudou(:old.id_departamento_anterior, :new.id_departamento_anterior)
              and not mudou(:old.id_gestor_anterior,       :new.id_gestor_anterior)
              and not mudou(:old.id_cargo_novo,            :new.id_cargo_novo)
              and not mudou(:old.id_departamento_novo,     :new.id_departamento_novo)
              and not mudou(:old.id_gestor_novo,           :new.id_gestor_novo)
              and not mudou(:old.vl_salario_anterior,      :new.vl_salario_anterior)
              and not mudou(:old.vl_salario_novo,          :new.vl_salario_novo)
              and not mudou(:old.ds_motivo,                :new.ds_motivo)
              and not mudou_clob(:old.ds_observacao,       :new.ds_observacao)
              and not mudou(:old.id_registro_estornado,    :new.id_registro_estornado)
              and not mudou(:old.id_comunicado,            :new.id_comunicado)
              and not mudou(:old.id_aprovador,             :new.id_aprovador)
              and not mudou(:old.dt_efetivacao,            :new.dt_efetivacao)
              and not mudou(:old.usr_efetivacao,           :new.usr_efetivacao))
      then
        raise_application_error(-20013,
          'Lançamentos efetivados ou estornados não podem ser alterados. '
          || 'Para corrigir, estorne o lançamento e faça um novo.');
      end if;
    end if;

    :new.dt_criacao    := :old.dt_criacao;
    :new.usr_criacao   := :old.usr_criacao;
    :new.dt_alteracao  := systimestamp;
    :new.usr_alteracao := l_usuario;

  elsif deleting then
    if :old.st_registro <> 'RASCUNHO' then
      raise_application_error(-20013,
        'Lançamentos efetivados ou estornados não podem ser excluídos.');
    end if;
  end if;
end;
/
ALTER TRIGGER "TRG_HISTORICO_CARREIRA_AUD" ENABLE;

  CREATE OR REPLACE EDITIONABLE TRIGGER "TRG_HISTORICO_CARREIRA_LOG"
after insert or update or delete on historico_carreira
for each row
declare
  -- inserting/updating só valem em PL/SQL; dentro do insert dão ORA-00984
  l_op log_auditoria_carreira.tp_operacao%type :=
    case when inserting then 'I' when updating then 'U' else 'D' end;
begin
  insert into log_auditoria_carreira (
    id_empresa, nm_tabela, id_registro, tp_operacao, st_anterior, st_novo, usr_criacao
  ) values (
    coalesce(:new.id_empresa, :old.id_empresa),
    'HISTORICO_CARREIRA',
    coalesce(:new.id_historico_carreira, :old.id_historico_carreira),
    l_op,
    :old.st_registro,
    :new.st_registro,
    coalesce(sys_context('APEX$SESSION', 'APP_USER'), sys_context('USERENV', 'SESSION_USER'))
  );
end;
/
ALTER TRIGGER "TRG_HISTORICO_CARREIRA_LOG" ENABLE;

  CREATE OR REPLACE EDITIONABLE TRIGGER "TRG_SOLICITACAO_CORRECAO_AUD"
before insert or update on solicitacao_correcao
for each row
declare
  l_usuario varchar2(255) := coalesce(sys_context('APEX$SESSION', 'APP_USER'), sys_context('USERENV', 'SESSION_USER'));
begin
  if inserting then
    :new.dt_criacao    := systimestamp;
    :new.usr_criacao   := l_usuario;
    :new.dt_alteracao  := null;
    :new.usr_alteracao := null;
  else
    :new.dt_criacao    := :old.dt_criacao;
    :new.usr_criacao   := :old.usr_criacao;
    :new.dt_alteracao  := systimestamp;
    :new.usr_alteracao := l_usuario;
  end if;
end;
/
ALTER TRIGGER "TRG_SOLICITACAO_CORRECAO_AUD" ENABLE;

  CREATE OR REPLACE EDITIONABLE TRIGGER "TRG_SOLICITACAO_CORRECAO_LOG"
after insert or update or delete on solicitacao_correcao
for each row
declare
  -- inserting/updating só valem em PL/SQL; dentro do insert dão ORA-00984
  l_op log_auditoria_carreira.tp_operacao%type :=
    case when inserting then 'I' when updating then 'U' else 'D' end;
begin
  insert into log_auditoria_carreira (
    id_empresa, nm_tabela, id_registro, tp_operacao, st_anterior, st_novo, usr_criacao
  ) values (
    coalesce(:new.id_empresa, :old.id_empresa),
    'SOLICITACAO_CORRECAO',
    coalesce(:new.id_solicitacao, :old.id_solicitacao),
    l_op,
    :old.st_solicitacao,
    :new.st_solicitacao,
    coalesce(sys_context('APEX$SESSION', 'APP_USER'), sys_context('USERENV', 'SESSION_USER'))
  );
end;
/
ALTER TRIGGER "TRG_SOLICITACAO_CORRECAO_LOG" ENABLE;

  CREATE OR REPLACE EDITIONABLE TRIGGER "TRG_TIPO_MOVIMENTACAO_AUD"
before insert or update on tipo_movimentacao
for each row
declare
  l_usuario varchar2(255) := coalesce(sys_context('APEX$SESSION', 'APP_USER'), sys_context('USERENV', 'SESSION_USER'));
begin
  if inserting then
    :new.dt_criacao    := systimestamp;
    :new.usr_criacao   := l_usuario;
    :new.dt_alteracao  := null;
    :new.usr_alteracao := null;
  else
    :new.dt_criacao    := :old.dt_criacao;
    :new.usr_criacao   := :old.usr_criacao;
    :new.dt_alteracao  := systimestamp;
    :new.usr_alteracao := l_usuario;
  end if;
end;
/
ALTER TRIGGER "TRG_TIPO_MOVIMENTACAO_AUD" ENABLE;
