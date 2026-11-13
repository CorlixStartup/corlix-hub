# Página 27 · Nova Equipe

> **Estado em 13/11/2026** (backup `84f8625`): implementada na versão gerada pelo assistente (Form sobre `EQUIPE`), sem guia de módulo nem registro de teste. A correção de isolamento (`modulos/isolamento-empresas/Etapas-isolamento-empresas.md` §3 e §4.2, CD-61, prioridade Alta) **não foi aplicada**.

## Resumo

| Atributo | Valor |
|---|---|
| Alias | `NOVA-EQUIPE` |
| Modo | Modal Dialog (`@/modal-dialog`) · `chained: false`; largura não definida no export |
| Page template | — (modal) |
| Autorização | nenhuma — qualquer usuário autenticado · `argumentsMustHaveChecksum` |
| CSS/JS de arquivo | nenhum |
| Módulo/guia | sem módulo próprio; isolamento em `modulos/isolamento-empresas/Etapas-isolamento-empresas.md` §3 e §4.2 |
| Protótipo | não há (`07-design-pen-dev.md` §1: "sem tela no pen.dev") |

Modal de criar, editar e excluir uma equipe. DML nativo do APEX na tabela `EQUIPE`.

## Estrutura

```
Page 27: Nova Equipe (Modal Dialog)
├── Content Body
│   └── nova-equipe "Nova Equipe" (10 · Form sobre EQUIPE · @/blank-with-attributes · edit: add/update/delete)
│       ├── P27_ID_EQUIPE       (10 · Hidden · PK · queryOnly · checksum de sessão)
│       ├── P27_ID_EMPRESA      (20 · Select List · LOV EMPRESA.NOME · obrigatório)
│       ├── P27_ID_DEPARTAMENTO (30 · Select List · LOV DEPARTAMENTO.NOME · opcional)
│       ├── P27_ID_CRIADOR      (40 · Select List · LOV COLABORADOR.NOME_COMPLETO · obrigatório)
│       ├── P27_NOME            (50 · Text · obrigatório · max 150)
│       ├── P27_DESCRICAO       (60 · Textarea · max 500)
│       ├── P27_DATA_CRIACAO    (70 · Date Picker · obrigatório · maxLength 255 sobrando, sem format mask)
│       └── P27_STATUS          (80 · Switch · boolean · obrigatório)
└── Dialog Footer
    └── botões (20 · @/buttons-container)
        ├── CANCEL "Cancelar"            (close · Cancel Dialog)
        ├── DELETE "Excluir"             (delete · só com ID · confirma &APP_TEXT$DELETE_MSG!RAW. · sem validações)
        ├── SAVE   "Aplicar Alterações"  (next · hot · só com ID · update)
        └── CREATE "Criar"               (next · hot · só sem ID · insert)
```

## Lógica

- **Computations:** —
- **Validations:** — (só `valueRequired`/`maxLength` dos itens).
- **Processes:**
  - `Inicializar o form Nova Equipe` (Before Header, 10).
  - `Processar o form Nova Equipe` (Processing, 10) · Automatic Row Processing (DML).
  - `Fechar Caixa de Diálogo` (50) · request em `CREATE,SAVE,DELETE`.
- **Dynamic Actions:** — (o Cancelar usa `triggerAction` do botão).
- **JavaScript da página:** —

## Dados

- Tabela `EQUIPE` (DDL em `database/corlix-hub.sql`).
- LOVs `EMPRESA.NOME`, `DEPARTAMENTO.NOME`, `COLABORADOR.NOME_COMPLETO` (tabela inteira, sem filtro).
- Multiempresa: **sem filtro**. Dá para escolher qualquer empresa, departamento e criador, e editar equipe de outra empresa.

## Navegação

- Chega por: página 26 (lápis com `P27_ID_EQUIPE` ou "Criar" com clear 27).
- Sai por: Close Dialog; a página 26 atualiza o relatório.

## Pegadinhas e pendências

- Sem `authorizationScheme` na página.
- Isolamento pendente (`Etapas-isolamento-empresas.md` §4.2): Where Clause na região, default de `P27_ID_EMPRESA` = `G_ID_EMPRESA` e três validações ("Equipe da empresa", "Empresa da sessão", "Departamento e criador da empresa"); LOVs filtradas no §3.
- LOVs sem cascata: departamento de outra empresa pode ser escolhido; o criador é escolhido à mão e a data de criação é digitada (`02-paginas.md`, seção da página 27).
- Labels técnicos alinhados à direita ("Id Criador", "Data Criacao"). A confirmação do DELETE usa `&APP_TEXT$DELETE_MSG!RAW.`, que sai em inglês porque o idioma técnico da app é `en` (mesmo caso corrigido na página 21, guia do histórico §9.8).
- O `02-paginas.md` cita `t-Button--danger` no Excluir como mudança não commitada; o export atual **não** tem essa opção.

## Referências

- [02 · Páginas, seção "Página 27"](../02-paginas.md)
- [Isolamento entre empresas, §3, §4.2 e §7](../../../modulos/isolamento-empresas/Etapas-isolamento-empresas.md)
- [Página 26 · Central de Equipes](./p00026-central-de-equipes.md)
