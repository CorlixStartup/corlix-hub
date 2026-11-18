-- =============================================================================
-- Corlix Hub · Imagens · regras
-- Guia: modulos/imagens/Etapas-imagens.md
-- Depende de: COMUNICADO e IMAGEM_ORIGINAL (01_ddl_imagens.sql).
-- =============================================================================
create or replace package body pkg_imagens as

  function eh_jpeg (p_blob in blob) return boolean is
    l_tam pls_integer;
  begin
    if p_blob is null then
      return false;
    end if;
    l_tam := dbms_lob.getlength(p_blob);
    return l_tam >= 4
       and dbms_lob.substr(p_blob, 3, 1) = hextoraw('FFD8FF')
       and dbms_lob.substr(p_blob, 2, l_tam - 1) = hextoraw('FFD9');
  end eh_jpeg;

  procedure obter_comunicado (
    p_id_comunicado in  number,
    p_id_empresa    in  number,
    p_imagem        out blob,
    p_mime          out varchar2
  ) is
  begin
    select imagem, mime_type
      into p_imagem, p_mime
      from comunicado
     where id_comunicado = p_id_comunicado
       and id_empresa = p_id_empresa
       and imagem is not null;
  end obter_comunicado;

  function trocar_comunicado (
    p_id_comunicado in number,
    p_id_empresa    in number,
    p_jpeg          in blob,
    p_usuario       in varchar2
  ) return varchar2 is
    l_atual   blob;
    l_mime    comunicado.mime_type%type;
    l_arquivo comunicado.nome_arquivo%type;
    l_tam     pls_integer;
    l_novo    pls_integer;
  begin
    if not eh_jpeg(p_jpeg) then
      return 'A imagem comprimida chegou incompleta. Tente de novo.';
    end if;

    l_novo := dbms_lob.getlength(p_jpeg);
    if l_novo > c_max_bytes then
      return 'A imagem comprimida passou de 1 MB. Nada foi alterado.';
    end if;

    begin
      select imagem, mime_type, nome_arquivo
        into l_atual, l_mime, l_arquivo
        from comunicado
       where id_comunicado = p_id_comunicado
         and id_empresa = p_id_empresa
         and imagem is not null
         for update;
    exception
      when no_data_found then
        return 'Comunicado não encontrado nesta empresa.';
    end;

    l_tam := dbms_lob.getlength(l_atual);
    if l_novo >= l_tam then
      return 'A imagem atual já é menor que a versão comprimida. Nada foi alterado.';
    end if;

    insert into imagem_original
      (id_empresa, nm_tabela, id_registro, imagem, mime_type, nome_arquivo, nr_bytes, nr_bytes_novo, usr_troca)
    values
      (p_id_empresa, 'COMUNICADO', p_id_comunicado, l_atual, l_mime, l_arquivo, l_tam, l_novo, p_usuario);

    update comunicado
       set imagem       = p_jpeg,
           mime_type    = 'image/jpeg',
           nome_arquivo = case when nome_arquivo is not null
                               then regexp_replace(nome_arquivo, '\.[^.]*$', '') || '.jpg' end
     where id_comunicado = p_id_comunicado
       and id_empresa = p_id_empresa;

    return null;
  end trocar_comunicado;

end pkg_imagens;
/
