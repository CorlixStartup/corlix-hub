# Página 41 · Sistema

> **Estado em 13/11/2026** (backup `84f8625`): criada na app (backup de 10/11/2026, `acd59be`) pelo assistente, com os ajustes do §10.3 de [`Etapas-suporte-ti.md`](../../../modulos/suporte-ti/Etapas-suporte-ti.md) aplicados (itens `DH_`/`USR_` apagados, labels, LOV e ajudas). Botões seguem em inglês. Sem seção "Situação" no guia e sem registro dos testes 19 a 21 do §14.

## Resumo

| Atributo | Valor |
|---|---|
| Alias | `SISTEMA` |
| Modo | Modal Dialog (`@/modal-dialog`), largura padrão, `chained: false` |
| Page template | `@/modal-dialog` |
| Autorização | `@suporte-ti` (`SUPORTE_TI`); `argumentsMustHaveChecksum` |
| CSS/JS de arquivo | nenhum |
| Módulo/guia | `modulos/suporte-ti/` · [`Etapas-suporte-ti.md`](../../../modulos/suporte-ti/Etapas-suporte-ti.md) §10.3 |
| Protótipo | — |

Formulário de um sistema: nome, ordem, situação, detalhe e o aviso de instabilidade mostrado no topo da p34.

## Estrutura

```
Page 41: Sistema
├── Content Body
│   └── Sistema (10, Form, tabela SUPORTE_SISTEMA, Blank with Attributes, edit: add/update/delete)
│       ├── P41_ID_SISTEMA      (10, Hidden, PK, queryOnly, checksum por sessão)
│       ├── P41_ID_EMPRESA      (20, Hidden, default item G_ID_EMPRESA)
│       ├── P41_NM_SISTEMA      (30, Text Field "Sistema", obrigatório, max 100)
│       ├── P41_NR_ORDEM        (40, Number Field "Ordem na lista", obrigatório)
│       ├── P41_ST_SISTEMA      (50, Select List "Situação", obrigatório)
│       │                       STATIC: Operando;OPERANDO, Instável;INSTAVEL, Em manutenção;MANUTENCAO, Fora do ar;FORA
│       ├── P41_DS_DETALHE      (60, Text Field "Detalhe", max 140)
│       ├── P41_DS_AVISO_TITULO (70, Text Field "Título do aviso", max 140)
│       └── P41_DS_AVISO_TEXTO  (80, Textarea "Texto do aviso", max 450)
└── Dialog Footer
    └── Buttons (20, Buttons Container)
        ├── CANCEL (10, close) "Cancel", Cancel Dialog
        ├── DELETE (20, delete) "Delete", confirmação danger; se P41_ID_SISTEMA não nulo
        ├── SAVE   (30, next, hot) "Apply Changes"; se P41_ID_SISTEMA não nulo
        └── CREATE (40, next, hot) "Create"; se P41_ID_SISTEMA nulo
```

## Lógica

- **Computations / Validations:** — (só os atributos dos itens).
- **Processes:** Before Header 10 `Initialize form Sistema`; Processing 10 `Process form Sistema` (Form - Automatic Row Processing); 50 `Close Dialog` (Request in `CREATE,SAVE,DELETE`).
- **Dynamic Actions:** — (o `CANCEL` usa `triggerAction` Cancel Dialog).
- **JavaScript da página:** —

## Dados

- Tabela `suporte_sistema` (`modulos/suporte-ti/01_ddl_suporte.sql`); `dh_atualizacao`/`usr_atualizacao` pelo trigger `trg_suporte_sistema_aud`.
- Multiempresa: `P41_ID_EMPRESA` recebe `G_ID_EMPRESA` por padrão. A busca do registro é só pela PK; a proteção contra trocar o id é o checksum do item e da página.

## Navegação

- Chega pela p40 (ícone de edição ou `CREATE`). Ao fechar, a p40 atualiza o IR.

## Pegadinhas e pendências

- Botões e confirmação em inglês ("Cancel", "Delete", "Apply Changes", "Create").
- O guia pede `P41_ID_EMPRESA` com Value Protected **Yes**. O export não mostra o atributo; não confirmado.
- `ID_EMPRESA` vazio dá `ORA-01400`: sessão sem `G_ID_EMPRESA` (guia, "Se não funcionar").
- Quando o sistema volta a **Operando**, o aviso some mesmo com título e texto preenchidos; limpe os campos para não reaparecerem (guia §10.3).
- O "x" do aviso na p34 só volta a mostrar o aviso quando o sistema for alterado aqui (guia, "Do protótipo para o app").

## Referências

- [`Etapas-suporte-ti.md`](../../../modulos/suporte-ti/Etapas-suporte-ti.md) §10, §14
- [Página 40](./p00040-status-dos-sistemas.md)
