--------------------------------------------------------------------------------
-- Corlix Hub · Empresas · 01 · Data de abertura opcional
--
-- EMPRESA.DATA_CRIACAO é a "Data de abertura" do cadastro (página 16). No
-- protótipo pen_dev/Nova empresa (modal).png ela é opcional, mas a coluna é
-- NOT NULL: com o campo vazio, o form grava NULL explícito e o insert falha
-- com ORA-01400. O DEFAULT SYSDATE continua para inserts que omitem a coluna.
--
-- Idempotente: só altera se a coluna ainda for NOT NULL.
--------------------------------------------------------------------------------
declare
    l_nullable user_tab_columns.nullable%type;
begin
    select nullable
      into l_nullable
      from user_tab_columns
     where table_name = 'EMPRESA'
       and column_name = 'DATA_CRIACAO';

    if l_nullable = 'N' then
        execute immediate 'alter table empresa modify (data_criacao null)';
        dbms_output.put_line('EMPRESA.DATA_CRIACAO agora aceita NULL.');
    else
        dbms_output.put_line('EMPRESA.DATA_CRIACAO já aceita NULL; nada a fazer.');
    end if;
end;
/
