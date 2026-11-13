# Página 39 · Atender chamado

> **Estado em 13/11/2026** (backup `84f8625`): criada na app (backup de 10/11/2026, `acd59be`) a partir do §8 de [`Etapas-suporte-ti.md`](../../../modulos/suporte-ti/Etapas-suporte-ti.md), mas sem as condições dos itens e do botão e com a região de botões diferente. Sem seção "Situação" no guia e sem registro dos testes 10 a 17 do §14.

## Resumo

| Atributo | Valor |
|---|---|
| Alias | `ATENDER-CHAMADO` |
| Modo | Modal Dialog (`@/modal-dialog`), `dialog.width: 760` |
| Page template | `@/modal-dialog` |
| Autorização | `@suporte-ti` (`SUPORTE_TI`); `argumentsMustHaveChecksum` |
| CSS/JS de arquivo | CSS `#APP_FILES#modulos/suporte-ti/suporte#MIN#.css`; JS nenhum |
| Módulo/guia | `modulos/suporte-ti/` · [`Etapas-suporte-ti.md`](../../../modulos/suporte-ti/Etapas-suporte-ti.md) §8 |
| Protótipo | — |

Modal da TI para assumir, responder, pedir informação ou resolver um chamado, com prioridade, previsão e anexo.

## Estrutura

```
Page 39: Atender chamado
└── Content Body
    ├── Conversa          (10, Dynamic Content, Blank with Attributes) render_conversa(:P39_ID_CHAMADO)
    ├── P39_ID_CHAMADO    (20, Hidden)
    ├── P39_ST_CHAMADO    (30, Hidden)
    ├── P39_ACAO          (40, Radio Group "O que fazer", Optional-Floating, obrigatório, default RESPONDER)
    │                     STATIC: Assumir o chamado;ASSUMIR, Responder ao colaborador;RESPONDER,
    │                             Pedir informação ao colaborador;PEDIR, Resolver;RESOLVER
    ├── P39_TP_PRIORIDADE (50, Select List "Prioridade", obrigatório) STATIC: Alta;ALTA, Média;MEDIA, Baixa;BAIXA
    ├── P39_DT_PREVISAO   (60, Date Picker "Previsão", DD/MM/YYYY)
    ├── P39_DS_TEXTO      (70, Textarea "Mensagem ao colaborador", max 3500)
    ├── P39_ANEXO         (80, File Upload, APEX_APPLICATION_TEMP_FILES, sem purgeFileAt)
    └── Botões            (90, Static Content, template Standard, t-Region--scrollBody)
        ├── CANCELAR (10, regionBody, Text) "Fechar", Defined by Dynamic Action
        └── SALVAR   (20, regionBody, Text, hot) "Salvar", Submit
```

Nenhum item nem botão tem Server-side Condition no export.

## Lógica

- **Computations / Validations:** — (o package valida ação, texto, previsão e situação).
- **Processes:**
  - Before Header 10 `Carregar`: `select st_chamado, tp_prioridade, to_char(dt_previsao,'DD/MM/YYYY') into :P39_ST_CHAMADO, :P39_TP_PRIORIDADE, :P39_DT_PREVISAO from suporte_chamado where id_chamado = :P39_ID_CHAMADO and id_empresa = :G_ID_EMPRESA`; sem linha → -20077 "Chamado não encontrado."
  - Processing 10 `Atender` (botão `SALVAR`): `pkg_suporte.atender(p_id_chamado, p_acao, p_ds_texto, p_tp_prioridade, p_dt_previsao, p_anexo)`.
  - Processing 20 `Fechar` (Close Dialog, botão `SALVAR`): "Chamado atualizado."
- **Dynamic Actions:** `Cancelar` (click em `CANCELAR`) → Cancel Dialog.
- **JavaScript da página:** —

## Dados

- `suporte_chamado`, `suporte_mensagem`, `suporte_anexo` (`modulos/suporte-ti/01_ddl_suporte.sql`).
- `pkg_suporte.atender` (`03_pkg_suporte.pkb`): recusa quem não tem `SUPORTE_TI` (-20081) e chamado já resolvido ou encerrado (-20080); previsão passada dá erro sem "ORA-" (teste 12).
- `pkg_suporte_ui.render_conversa` (`04_pkg_suporte_ui.pkb`).
- Multiempresa: `Carregar` filtra por `G_ID_EMPRESA`; o package usa `fn_empresa_contexto`.

## Navegação

- Chega pela p38, coluna `ATENDER` (`P39_ID_CHAMADO`, clear cache 39).
- Ao fechar, a p38 atualiza o IR (DA `Chamado atendido`).

## Pegadinhas e pendências

- Divergências do export com o guia §8.2–§8.3:
  - Itens visíveis e `SALVAR` sem a condição `:P39_ST_CHAMADO in ('ABERTO','EM_ATENDIMENTO','AGUARDANDO_USUARIO')`. Num chamado resolvido ou encerrado, o formulário aparece, e salvar volta o erro -20080 do package.
  - `Botões` usa template **Standard** em `contentBody`, e não **Buttons Container** em Dialog Footer (regra E2 do [11](../11-padroes-de-paginas.md)); a região pode mostrar o título "Botões" (não conferido na tela).
  - `P39_ACAO` e `P39_TP_PRIORIDADE` são obrigatórios com template Optional-Floating.
  - `P39_ANEXO` sem `purgeFileAt` (guia pede End of Request).
- Quem atende precisa de colaborador vinculado (`-20076`).
- Toda mensagem é vista pelo colaborador; não escrever senhas (guia, "Fica de fora").

## Referências

- [`Etapas-suporte-ti.md`](../../../modulos/suporte-ti/Etapas-suporte-ti.md) §8, §14
- [Página 38](./p00038-atendimento-ti.md) · [Página 36](./p00036-chamado.md)
- [11 · Padrões de páginas](../11-padroes-de-paginas.md)
