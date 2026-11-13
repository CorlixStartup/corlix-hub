# Página 35 · Abrir chamado

> **Estado em 13/11/2026** (backup `84f8625`): criada na app (backup de 10/11/2026, `acd59be`) conforme o §5 de [`Etapas-suporte-ti.md`](../../../modulos/suporte-ti/Etapas-suporte-ti.md). Sem seção "Situação" no guia e sem registro dos testes 7 e 8 do §14.

## Resumo

| Atributo | Valor |
|---|---|
| Alias | `ABRIR-CHAMADO` |
| Modo | Modal Dialog (`@/modal-dialog`), largura padrão (sem `dialog.width`) |
| Page template | `@/modal-dialog` |
| Autorização | `@colaborador`; `argumentsMustHaveChecksum` |
| CSS/JS de arquivo | nenhum |
| Módulo/guia | `modulos/suporte-ti/` · [`Etapas-suporte-ti.md`](../../../modulos/suporte-ti/Etapas-suporte-ti.md) §5 |
| Protótipo | — (não está no protótipo; existe para o botão "Abrir chamado" da p34) |

Modal para abrir um incidente (`INC`) ou uma solicitação (`REQ`), com um anexo opcional.

## Estrutura

```
Page 35: Abrir chamado
├── Content Body
│   ├── P35_TP_CHAMADO  (10, Radio Group, Required-Floating) STATIC: Algo não está funcionando;INC, Quero pedir algo;REQ; default INC
│   ├── P35_ID_ASSUNTO  (20, Select List, Required-Floating) LOV SQL suporte_assunto (empresa, ativos); null "Escolha"
│   ├── P35_DS_TITULO   (30, Text Field, Required-Floating, max 140)
│   ├── P35_DS_TEXTO    (40, Textarea, Required-Floating, max 3500)
│   └── P35_ANEXO       (50, File Upload, Optional-Floating) APEX_APPLICATION_TEMP_FILES, purge End of Request, .png,.jpg,.jpeg,.pdf,.txt,.log
└── Dialog Footer
    └── Botões (10, Buttons Container)
        ├── CANCELAR  (close, Text) Defined by Dynamic Action
        └── ABRIR     (next, Text, hot) "Abrir chamado", Submit
```

## Lógica

- **Computations / Validations:** — (só `valueRequired`/`maxLength` dos itens; o package valida de novo tipo, assunto, título e anexo).
- **Processes:**
  - `Abrir` (seq 10, quando `ABRIR`): `pkg_suporte.abrir_chamado(p_tp_chamado, p_id_assunto, p_ds_titulo, p_ds_texto, p_anexo)`.
  - `Fechar` (seq 20, Close Dialog, quando `ABRIR`): mensagem "Chamado aberto. A equipe de TI vai responder por aqui."
- **Dynamic Actions:** `Cancelar` (click em `CANCELAR`) → Cancel Dialog.
- **JavaScript da página:** —

## Dados

- LOV de `P35_ID_ASSUNTO`: `suporte_assunto where id_empresa = :G_ID_EMPRESA and fl_ativo = 'S' order by nr_ordem`.
- `pkg_suporte.abrir_chamado` (`modulos/suporte-ti/03_pkg_suporte.pkb`): grava `suporte_chamado`, `suporte_mensagem` e `suporte_anexo`. Erros do módulo na faixa -20076 a -20084.
- Multiempresa: LOV por `G_ID_EMPRESA`; o package usa `pkg_historico_carreira.fn_empresa_contexto`.

## Navegação

- Chega pela p34 (`url_abrir` do `pkg_suporte_ui`, pode passar `P35_ID_ASSUNTO`; links da busca "Não resolveu? Abrir chamado").
- Ao fechar, a p34 mostra a mensagem e atualiza `suporte_chamados` (`apexafterclosedialog`).

## Pegadinhas e pendências

- Anexo: um por envio, até 5 MB; o package confere tipo e tamanho de novo (guia §5.2). "O arquivo enviado não foi encontrado" = Storage Type errado ou arquivo já apagado (guia, "Se não funcionar").
- Conta sem colaborador vinculado recebe -20076 ao enviar (guia, "Decisões").
- O LOV do radio está como `STATIC:` no export; o guia pede `STATIC2:` (a ordem fica a mesma dos valores). Sem efeito prático confirmado.
- Testes 7 e 8 do §14: sem registro.

## Referências

- [`Etapas-suporte-ti.md`](../../../modulos/suporte-ti/Etapas-suporte-ti.md) §5, §14
- [Página 34](./p00034-suporte-ti.md)
- [11 · Padrões de páginas](../11-padroes-de-paginas.md) (referência de modal: p31)
