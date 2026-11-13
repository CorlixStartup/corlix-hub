# Página 43 · Artigo

> **Estado em 13/11/2026** (backup `84f8625`): criada na app (backup de 10/11/2026, `acd59be`) só pelo assistente. Os ajustes do §11.3 de [`Etapas-suporte-ti.md`](../../../modulos/suporte-ti/Etapas-suporte-ti.md) **não foram aplicados**: ainda tem `P43_DH_ATUALIZACAO`, `P43_USR_ATUALIZACAO` e `P43_NR_ACESSOS`, e `P43_ID_EMPRESA` é uma lista de todas as empresas. Sem seção "Situação" no guia e sem registro do teste 22 do §14.

## Resumo

| Atributo | Valor |
|---|---|
| Alias | `ARTIGO` |
| Modo | Modal Dialog (`@/modal-dialog`), largura padrão, `chained: false` |
| Page template | `@/modal-dialog` |
| Autorização | `@suporte-ti` (`SUPORTE_TI`); `argumentsMustHaveChecksum` |
| CSS/JS de arquivo | nenhum |
| Módulo/guia | `modulos/suporte-ti/` · [`Etapas-suporte-ti.md`](../../../modulos/suporte-ti/Etapas-suporte-ti.md) §11.3 |
| Protótipo | — |

Formulário de um artigo da base de conhecimento: assunto, título, resumo, texto, palavras para a busca, tempo de leitura e publicação.

## Estrutura

```
Page 43: Artigo
├── Content Body
│   └── Artigo (10, Form, tabela SUPORTE_ARTIGO, Blank with Attributes, edit: add/update/delete)
│       ├── P43_ID_ARTIGO       (10, Hidden, PK, queryOnly, checksum por sessão)
│       ├── P43_ID_EMPRESA      (20, Select List "Id Empresa", obrigatório, LOV EMPRESA.NOME)
│       ├── P43_ID_ASSUNTO      (30, Select List "Id Assunto", obrigatório, LOV SUPORTE_ASSUNTO.NM_ASSUNTO)
│       ├── P43_DS_TITULO       (40, Text Field "Ds Titulo", obrigatório, max 150)
│       ├── P43_DS_RESUMO       (50, Textarea "Ds Resumo", max 300)
│       ├── P43_DS_CORPO        (60, Textarea "Ds Corpo", obrigatório, max 4000)
│       ├── P43_DS_PALAVRAS     (70, Textarea "Ds Palavras", max 500)
│       ├── P43_NR_MIN_LEITURA  (80, Number Field "Nr Min Leitura", obrigatório)
│       ├── P43_NR_ACESSOS      (90, Number Field "Nr Acessos", obrigatório)
│       ├── P43_FL_PUBLICADO    (100, Text Field "Fl Publicado")
│       ├── P43_DH_ATUALIZACAO  (110, Date Picker "Dh Atualizacao", obrigatório, timestamp with time zone)
│       └── P43_USR_ATUALIZACAO (120, Text Field "Usr Atualizacao")
└── Dialog Footer
    └── Buttons (20, Buttons Container)
        ├── CANCEL (10, close) "Cancel"
        ├── DELETE (20, delete) "Delete", confirmação danger; se P43_ID_ARTIGO não nulo
        ├── SAVE   (30, next, hot) "Apply Changes"; se P43_ID_ARTIGO não nulo
        └── CREATE (40, next, hot) "Create"; se P43_ID_ARTIGO nulo
```

## Lógica

- **Validations:** `P43_DH_ATUALIZACAO must be timestamp` (seq 100, gerada pelo assistente).
- **Processes:** Before Header 10 `Initialize form Artigo`; Processing 10 `Process form Artigo` (Automatic Row Processing); 50 `Close Dialog` (Request in `CREATE,SAVE,DELETE`).
- **Dynamic Actions:** — (`CANCEL` com `triggerAction` Cancel Dialog).
- **JavaScript da página:** —

## Dados

- Tabela `suporte_artigo` (`modulos/suporte-ti/01_ddl_suporte.sql`): `ds_corpo varchar2(4000)`, `fl_publicado` `S`/`N` com check, `dh_atualizacao` com default. O trigger `trg_suporte_artigo_aud` preenche `dh_atualizacao`/`usr_atualizacao`.
- LOVs `empresa-nome` e `suporte-assunto-nm-assunto` (`shared-components/lovs.apx`), sem filtro por empresa.
- Multiempresa: **não garantida**. O guia pede `P43_ID_EMPRESA` Hidden, protegido, com default `G_ID_EMPRESA`, e a LOV de assunto filtrada (a do passo 5.2).

## Navegação

- Chega pela p42 (ícone de edição ou `CREATE`). Ao fechar, a p42 atualiza o IR.

## Pegadinhas e pendências

- **Aplicar o §11.3 antes de usar:**
  - Itens `DH_`/`USR_` na tela causam erro de conversão de data ao salvar (guia, "Se não funcionar"). `P43_DH_ATUALIZACAO` ainda é obrigatório.
  - `P43_NR_ACESSOS` editável e obrigatório; o contador deveria vir só da p37.
  - `P43_ID_EMPRESA` deixa escolher qualquer empresa, e `P43_ID_ASSUNTO` lista assuntos de todas.
  - `P43_FL_PUBLICADO` é texto livre; o check da tabela só aceita `S`/`N`. O guia pede Select List `Sim;S,Não;N`.
  - Labels técnicos e botões em inglês.
- `DS_CORPO` aceita 4000 no item; o guia pede 3500.

## Referências

- [`Etapas-suporte-ti.md`](../../../modulos/suporte-ti/Etapas-suporte-ti.md) §11, §14
- [Página 42](./p00042-artigos.md) · [Página 37](./p00037-base-conhecimento.md)
- [08 §3](../08-convencoes-e-pegadinhas.md) (formulário editável só pelo assistente)
