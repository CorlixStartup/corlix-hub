# Página 26 · Central de Equipes

> **Estado em 13/11/2026** (backup `84f8625`): implementada na versão gerada pelo assistente (Classic Report sobre `EQUIPE`), sem guia de módulo nem registro de teste. A correção de isolamento (`modulos/isolamento-empresas/Etapas-isolamento-empresas.md` §3 e §4.1, CD-61, prioridade Alta) **não foi aplicada**: a região não tem Where Clause e as LOVs leem as tabelas inteiras.

## Resumo

| Atributo | Valor |
|---|---|
| Alias | `CENTRAL-DE-EQUIPES` |
| Modo | Normal |
| Page template | `@corlix-standard-page` |
| Autorização | nenhuma — qualquer usuário autenticado · `argumentsMustHaveChecksum` |
| CSS/JS de arquivo | nenhum |
| Módulo/guia | sem módulo próprio; isolamento em `modulos/isolamento-empresas/Etapas-isolamento-empresas.md` §3 e §4.1 |
| Protótipo | não há (`07-design-pen-dev.md` §1: "sem tela no pen.dev") |

Lista as equipes e abre a modal 27 para criar ou editar.

## Estrutura

```
Page 26: Central de Equipes
├── Breadcrumb Bar
│   └── navegação-estrutural "Navegação Estrutural" (10 · Breadcrumb @breadcrumb · @/title-bar, useBreadcrumbTitle)
└── Body
    └── central-de-equipes (10 · Classic Report sobre a tabela EQUIPE · @/standard, t-Region--noPadding)
        ├── colunas: ID_EQUIPE (link lápis → p27, P27_ID_EQUIPE), ID_EMPRESA (LOV EMPRESA.NOME),
        │            ID_DEPARTAMENTO (LOV DEPARTAMENTO.NOME), ID_CRIADOR (LOV COLABORADOR.NOME_COMPLETO),
        │            NOME, DESCRICAO, DATA_CRIACAO, STATUS (LOV BOOLEAN)
        ├── template do relatório: @/standard (stretch, staticRowColors, rowHighlight, inline, hideNoPagination)
        └── botão CREATE "Criar" (slot edit · hot · → p27, clear 27)
```

## Lógica

- **Computations:** —
- **Validations:** —
- **Processes:** —
- **Dynamic Actions:** `Editar Relatório - Caixa de Diálogo Fechada` (`apexafterclosedialog` na região) → Refresh do relatório.
- **JavaScript da página:** —

## Dados

- Tabela `EQUIPE` (DDL em `database/corlix-hub.sql`).
- LOVs compartilhadas `COLABORADOR.NOME_COMPLETO`, `DEPARTAMENTO.NOME`, `EMPRESA.NOME` (tabela inteira, sem filtro) e `BOOLEAN`.
- Multiempresa: **sem filtro**. Lista equipes de todas as empresas.

## Navegação

- Chega por: menu "Administração › Central de equipes" (sem autorização; `isCurrent` nas páginas 26 e 27).
- Vai para: modal 27 (lápis com `P27_ID_EQUIPE` ou "Criar" com clear 27).

## Pegadinhas e pendências

- Sem `authorizationScheme` na página nem no menu (`08-convencoes-e-pegadinhas.md` §1, regra 8).
- Sem filtro por `id_empresa` na região e nas LOVs. Correção versionada e não aplicada: Where Clause `ID_EMPRESA = :G_ID_EMPRESA` e LOVs por SQL filtradas (`Etapas-isolamento-empresas.md` §3, §4.1; teste 5 da §7).
- Cabeçalhos gerados e sem tradução ("Id Empresa", "Data Criacao", "Descricao"); `STATUS` mostra "Yes"/"No" da LOV `BOOLEAN`; mensagem de vazio "Dados não encontrados.".
- O link da coluna usa a sintaxe `\#ID_EQUIPE#\` (`09-erros-e-solucoes.md` §4.6).

## Referências

- [02 · Páginas, seção "Página 26"](../02-paginas.md)
- [Isolamento entre empresas, §3, §4.1 e §7](../../../modulos/isolamento-empresas/Etapas-isolamento-empresas.md)
- [Página 27 · Nova Equipe](./p00027-nova-equipe.md)
