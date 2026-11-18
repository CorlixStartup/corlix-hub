--------------------------------------------------------------------------------
-- Corlix Hub · Chat (página 4) · especificação
-- Presença (guia modulos/chat/Etapas-chat.md §2):
--   situacao_presenca -> 'online' | 'ausente' | 'offline', a mesma regra da
--                        região "Contatos" da página 4 e do pkg_home_ui
--   ajax_ping         -> Application Process CX_PRESENCA_PING (todas as páginas)
--   ajax_presencas    -> Ajax Callback CH_PRESENCAS da página 4
-- Anexos (guia §4):
--   ajax_enviar_anexo -> Ajax Callback CH_ENVIAR_ANEXO da página 4
--   baixar_anexo      -> processo Before Header da página 4 (BAIXAR_ANEXO / VER_ANEXO)
--   html_anexo        -> HTML do anexo na bolha (coluna ANEXO_HTML da região Mensagens)
-- O colaborador vem sempre da sessão (APP_USER + G_ID_EMPRESA), nunca do navegador.
-- Depende de: pkg_equipe_canal, presenca_colaborador, colaborador, canal_mensagem,
-- canal_mensagem_anexo e canal_participante.
--------------------------------------------------------------------------------
create or replace package pkg_chat_ui authid definer as

  function situacao_presenca (
    p_status      in varchar2,
    p_ultimo_ping in timestamp
  ) return varchar2;

  -- {"ok":true} quando gravou; {"ok":false} para conta sem colaborador ativo
  procedure ajax_ping;

  -- {"presencas":{"12":"online","15":"ausente",...}}
  procedure ajax_presencas;

  -- x01 = canal, x02 = nome do arquivo, x03 = texto opcional, p_clob_01 = arquivo em base64.
  -- Responde {"ok":true} ou {"ok":false,"mensagem":"..."}
  procedure ajax_enviar_anexo;

  -- Entrega o arquivo e encerra a página. p_inline só vale para imagem (miniatura).
  procedure baixar_anexo (
    p_id_anexo in varchar2,
    p_inline   in boolean default false
  );

  function html_anexo (
    p_id_anexo in number,
    p_nome     in varchar2,
    p_tamanho  in number
  ) return varchar2;

end pkg_chat_ui;
/
