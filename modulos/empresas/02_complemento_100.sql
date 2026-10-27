--------------------------------------------------------------------------------
-- Corlix Hub · Empresas · 02 · Complemento com 100 caracteres
--
-- EMPRESA.COMPLEMENTO tem 30 caracteres, mas a consulta do CNPJ na página 16
-- (BrasilAPI) traz complementos maiores: o do Banco do Brasil tem 67. Com o
-- campo preenchido pela Receita, "Criar empresa" falhava no tamanho máximo.
-- Na página, o P16_COMPLEMENTO passa para Maximum Length 100 junto.
--
-- Idempotente: só altera se a coluna ainda tiver menos de 100 caracteres.
--------------------------------------------------------------------------------
declare
    l_tamanho user_tab_columns.char_length%type;
begin
    select char_length
      into l_tamanho
      from user_tab_columns
     where table_name = 'EMPRESA'
       and column_name = 'COMPLEMENTO';

    if l_tamanho < 100 then
        execute immediate 'alter table empresa modify (complemento varchar2(100 byte))';
        dbms_output.put_line('EMPRESA.COMPLEMENTO agora tem 100 caracteres.');
    else
        dbms_output.put_line('EMPRESA.COMPLEMENTO já tem ' || l_tamanho || ' caracteres; nada a fazer.');
    end if;
end;
/
