# Página 36 · Chamado

> **Estado em 13/11/2026** (backup `84f8625`): criada na app (backup de 10/11/2026, `acd59be`) a partir do §6 de [`Etapas-suporte-ti.md`](../../../modulos/suporte-ti/Etapas-suporte-ti.md), com diferenças de layout dos botões. Sem seção "Situação" no guia e sem registro dos testes 9, 14, 16 e 17 do §14.

## Resumo

| Atributo | Valor |
|---|---|
| Alias | `CHAMADO` |
| Modo | Modal Dialog (`@/modal-dialog`), `dialog.width: 760` |
| Page template | `@/modal-dialog` |
| Autorização | `@colaborador`; `argumentsMustHaveChecksum` |
| CSS/JS de arquivo | CSS `#APP_FILES#modulos/suporte-ti/suporte#MIN#.css`; JS nenhum |
| Módulo/guia | `modulos/suporte-ti/` · [`Etapas-suporte-ti.md`](../../../modulos/suporte-ti/Etapas-suporte-ti.md) §6 |
| Protótipo | — |

Conversa de um chamado para o solicitante: ler, responder, reabrir um chamado resolvido e baixar anexos (request `BAIXAR_ANEXO`).

## Estrutura

```
Page 36: Chamado
└── Content Body
    ├── Conversa        (10, Dynamic Content, Blank with Attributes) render_conversa(:P36_ID_CHAMADO)
    ├── P36_ID_CHAMADO  (20, Hidden)
    ├── P36_ID_ANEXO    (30, Hidden)
    ├── P36_ST_CHAMADO  (40, Hidden)
    ├── P36_DS_TEXTO    (50, Textarea "Sua mensagem", Optional-Floating, max 3500)   cond.: ST in (ABERTO, EM_ATENDIMENTO, AGUARDANDO_USUARIO, RESOLVIDO)
    ├── P36_ANEXO       (60, File Upload, Optional-Floating, APEX_APPLICATION_TEMP_FILES, sem purgeFileAt)   sem condição
    └── Botões          (70, Buttons Container, slot contentBody)
        ├── CANCELAR   (10, close, Text) "Cancelar", Defined by Dynamic Action
        ├── RESPONDER  (20, regionBody, Text) "Enviar resposta"  cond.: ST in (ABERTO, EM_ATENDIMENTO, AGUARDANDO_USUARIO)
        └── REABRIR    (30, regionBody, Text) "Reabrir chamado"  cond.: ST = 'RESOLVIDO'
```

## Lógica

- **Computations / Validations:** — (o package devolve a mensagem certa para cada botão).
- **Processes:**
  - Before Header 10 `Baixar anexo`: `pkg_suporte.baixar_anexo(:P36_ID_ANEXO)`, só com Request = `BAIXAR_ANEXO`. Entrega o arquivo e encerra a resposta.
  - Before Header 20 `Carregar`: `:P36_ST_CHAMADO := pkg_suporte.fn_situacao(:P36_ID_CHAMADO)`.
  - Processing 10 `Responder` (botão `RESPONDER`): `pkg_suporte.responder(:P36_ID_CHAMADO, :P36_DS_TEXTO, :P36_ANEXO)`.
  - Processing 20 `Reabrir` (botão `REABRIR`): `pkg_suporte.reabrir(:P36_ID_CHAMADO, :P36_DS_TEXTO, :P36_ANEXO)`.
  - Processing 30 `Fechar` (Close Dialog, Request in `RESPONDER,REABRIR`): "Mensagem enviada à equipe de TI."
- **Dynamic Actions:** `Cancelar` (click em `CANCELAR`) → Cancel Dialog.
- **JavaScript da página:** —

## Dados

- `suporte_chamado`, `suporte_mensagem`, `suporte_anexo` (`modulos/suporte-ti/01_ddl_suporte.sql`).
- `pkg_suporte_ui.render_conversa` e `pkg_suporte.fn_situacao`, `responder`, `reabrir`, `baixar_anexo` (`03_pkg_suporte.pkb`, `04_pkg_suporte_ui.pkb`).
- Permissão: `fn_situacao` só devolve a situação para o solicitante ou para quem tem `SUPORTE_TI`, na empresa da sessão; senão -20077. `render_conversa` e `baixar_anexo` chamam `fn_situacao` antes de mostrar ou entregar.

## Navegação

- Chega pela p34 (`url_chamado`: `P36_ID_CHAMADO`, clear cache 36; "Responder", "Não, reabrir", título do chamado).
- Links de anexo da conversa pedem a p36 com `p_request => 'BAIXAR_ANEXO'` e `P36_ID_ANEXO`.
- Ao fechar, a p34 atualiza `suporte_chamados`.

## Pegadinhas e pendências

- Divergências do export com o guia §6.3–§6.4:
  - `P36_ANEXO` não tem a Server-side Condition; no chamado encerrado o campo de anexo aparece sozinho, sem texto e sem botão. Guia pede a mesma condição do `P36_DS_TEXTO`.
  - `P36_ANEXO` sem `purgeFileAt` (padrão do APEX); o guia pede **End of Request** (passo 5.2).
  - Região `Botões` em `contentBody`, e não em Dialog Footer; `RESPONDER`/`REABRIR` no slot `regionBody`, sem Hot; `CANCELAR` com label "Cancelar" (guia: "Fechar"). Fora da regra E2 do [11](../11-padroes-de-paginas.md).
- Os hidden `P36_ID_*` precisam de Value Protected (guia §6.3). O export não mostra o atributo; não confirmado.
- Clicar no anexo e abrir HTML/erro = processo `Baixar anexo` fora de ordem ou sem a condição de request (guia, "Se não funcionar").
- Encerrado é definitivo; reabrir só vale para `RESOLVIDO` (guia, "Decisões").

## Referências

- [`Etapas-suporte-ti.md`](../../../modulos/suporte-ti/Etapas-suporte-ti.md) §6, §14
- [Página 34](./p00034-suporte-ti.md) · [Página 39](./p00039-atender-chamado.md) (mesma conversa, lado da TI)
- [11 · Padrões de páginas](../11-padroes-de-paginas.md)
