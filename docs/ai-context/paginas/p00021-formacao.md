# Página 21 · Formação

> **Estado em 13/11/2026** (backup `84f8625`): implementada e validada. O guia `modulos/historico-carreira/Etapas-historico-carreira.md` marca §4 e a etapa 2 da §9.10 como ✅ ("Situação na revalidação de 19/10/2026"). O isolamento por empresa do formulário (`Etapas-isolamento-empresas.md` §6) ainda não foi aplicado.

## Resumo

| Atributo | Valor |
|---|---|
| Alias | `FORMACAO` |
| Modo | Modal Dialog (`@/modal-dialog`) · `chained: false`; largura não definida no export |
| Page template | — (modal) |
| Autorização | `@admin-rh` (`ADMIN_RH`) · `argumentsMustHaveChecksum` |
| CSS/JS de arquivo | nenhum |
| Módulo/guia | `modulos/historico-carreira/` · `Etapas-historico-carreira.md` §4.5 |
| Protótipo | não há em `pen_dev/` |

Formulário em modal, criado pelo assistente, para criar, editar e excluir uma formação de um colaborador, com anexo (PDF ou imagem). Grava direto em `FORMACAO_COLABORADOR` pelo DML nativo do APEX.

## Estrutura

```
Page 21: Formação (Modal Dialog)
├── Content Body
│   └── formação (10 · Form sobre FORMACAO_COLABORADOR · @/blank-with-attributes · edit: add/update/delete)
│       ├── P21_ID_FORMACAO      (10 · Hidden · PK · queryOnly · checksum de sessão)
│       ├── P21_ID_EMPRESA       (20 · Hidden · preenchido pelo processo "Empresa da sessão")
│       ├── P21_ID_COLABORADOR   (30 · Hidden · checksum de sessão)
│       ├── P21_TP_FORMACAO      (40 · Select List · LOV_TIPO_FORMACAO · "- Selecione -" · obrigatório)
│       ├── P21_DS_TITULO        (50 · Text · obrigatório · max 300)
│       ├── P21_DS_INSTITUICAO   (70 · Text · obrigatório · max 200)
│       ├── P21_DT_INICIO        (80 · Date Picker DD/MM/YYYY)
│       ├── P21_DT_CONCLUSAO     (90 · Date Picker)
│       ├── P21_DT_VALIDADE      (100 · Date Picker)
│       ├── P21_NR_CARGA_HORARIA (110 · Number)
│       ├── P21_DS_LINK          (120 · Text · max 1000)
│       └── P21_BL_ANEXO         (130 · File Upload · BLOB · .pdf,image/* · 5120 KB · "Baixar anexo")
└── Dialog Footer
    └── buttons "Botões" (20 · @/buttons-container)
        ├── CANCEL "Cancelar" (close · Cancel Dialog)
        ├── DELETE "Excluir"  (delete · só com ID · confirma "O anexo também será apagado." · sem validações)
        ├── SAVE   "Salvar"   (next · hot · só com ID · update)
        └── CREATE "Criar"    (next · hot · só sem ID · insert)
```

Todos os botões têm `authorizationScheme: @admin-rh`.

## Lógica

- **Computations:** —
- **Validations** (na ordem):
  - `Formação da empresa` (10) · Function Body · confere que a formação (ou o colaborador, ao criar) é da `G_ID_EMPRESA` · `alwaysExecute: true` (vale também no DELETE).
  - `Data obrigatória` (20) · início ou conclusão.
  - `Conclusão depois do início` (30).
  - `Validade` (40) · validade ≥ conclusão (ou início).
  - `Carga horária` (50) · maior que zero.
  - `Link` (60) · começa com `http://` ou `https://`.
- **Processes:**
  - `Initialize form Formação` (Before Header, 10).
  - `Empresa da sessão` (Processing, 10) · `:P21_ID_EMPRESA := :G_ID_EMPRESA`.
  - `Process form Formação` (20) · Automatic Row Processing (DML).
  - `Close Dialog` (30) · request em `CREATE,SAVE,DELETE`.
- **Dynamic Actions:** — (o Cancelar usa `triggerAction` do próprio botão).
- **JavaScript da página:** —

## Dados

- Tabela `formacao_colaborador` (DDL em `modulos/historico-carreira/01_ddl_historico_carreira.sql`; triggers de auditoria e log em `05_triggers_auditoria.sql` preenchem criação/alteração).
- Tabela `colaborador` (validação).
- Multiempresa: `P21_ID_EMPRESA` vem da sessão e a validação `Formação da empresa` barra registro ou colaborador de outra empresa. A região de Form não tem Where Clause por empresa.

## Navegação

- Chega por: página 19, lápis da linha (`P21_ID_FORMACAO`, clear 21) ou botão "Nova formação" (`P21_ID_COLABORADOR`, clear 21).
- Sai por: Close Dialog; a página 19 atualiza o IR pela DA `Edit Report - Dialog Closed`.

## Pegadinhas e pendências

- Sem `P21_ID_COLABORADOR` (aberta fora do botão "Nova formação"), criar dá "Formação não encontrada." (guia §4.7).
- O DELETE tem `executeValidations: false`; só a validação com `alwaysExecute` roda nele (guia §4.5, passo 5).
- O anexo depende do Storage do File Upload (colunas `DS_MIME_TYPE` e `DS_NOME_ARQUIVO`); não criar itens para essas colunas (guia §4.5).
- Constraints da tabela barram dados errados com mensagem técnica; cada regra precisa da validação correspondente (guia §4.7).
- Pendente: Where Clause `id_empresa = :G_ID_EMPRESA` na região do form (`modulos/isolamento-empresas/Etapas-isolamento-empresas.md` §6).

## Referências

- [Guia do módulo, §4.5 a §4.7, §8.3 e §9.10](../../../modulos/historico-carreira/Etapas-historico-carreira.md)
- [Isolamento entre empresas, §6](../../../modulos/isolamento-empresas/Etapas-isolamento-empresas.md)
- [02 · Páginas, tabela-resumo](../02-paginas.md) (sem seção própria da 21)
- [Página 19 · Formações e certificações](./p00019-formacoes-e-certificacoes.md)
