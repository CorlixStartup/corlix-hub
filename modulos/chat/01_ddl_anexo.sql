--------------------------------------------------------------------------------
-- Corlix Hub · Chat (página 4) · anexos (guia Etapas-chat.md §4)
-- A tabela CANAL_MENSAGEM_ANEXO já existe (database/ddl/03-tabelas.sql), mas não
-- tem índice pela mensagem. O índice é único: o chat aceita 1 anexo por mensagem,
-- e a região Mensagens junta mensagem e anexo sem duplicar linhas. Reexecutável.
--------------------------------------------------------------------------------
create unique index if not exists idx_canalanexo_msg
    on canal_mensagem_anexo (id_canal_mensagem);
