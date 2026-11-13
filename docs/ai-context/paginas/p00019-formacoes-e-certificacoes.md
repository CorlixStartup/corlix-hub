# Página 19 · Formações e certificações

> **Estado em 13/11/2026** (backup `84f8625`): implementada e validada. O guia `modulos/historico-carreira/Etapas-historico-carreira.md` marca §4 e a etapa 1 da §9.10 como ✅ ("A página 19 ficou completa", Situação de 19/10/2026), e o export atual confere.

## Resumo

| Atributo | Valor |
|---|---|
| Alias | `FORMACOES-E-CERTIFICACOES` |
| Modo | Normal |
| Page template | `@corlix-standard-page` |
| Autorização | `@admin-rh` (`ADMIN_RH`) · `argumentsMustHaveChecksum` |
| CSS/JS de arquivo | `#APP_FILES#historico-carreira#MIN#.css` |
| Módulo/guia | `modulos/historico-carreira/` · `Etapas-historico-carreira.md` §4 (4.3 e 4.4) |
| Protótipo | não há em `pen_dev/` |

Lista do RH com as formações, cursos e certificações de um colaborador. Destaca as vencidas e as que vencem em até 60 dias. A edição é na modal da página 21.

## Estrutura

```
Page 19: Formações e certificações
└── Body
    ├── header "Cabeçalho" (5 · Static Content · @/blank-with-attributes-no-grid)
    │     HTML <div class="hc" data-hc> com <h1> e o nome &P19_NM_COLABORADOR!HTML.
    ├── formações-e-certificações (20 · Interactive Report · @/interactive-report, cabeçalho oculto)
    │   ├── fonte: SQL em formacao_colaborador do P19_ID_COLABORADOR e da G_ID_EMPRESA,
    │   │          com DS_ALERTA_VALIDADE = 'VENCIDA' / 'A VENCER' (fn_hoje + 60)
    │   ├── Link Column: lápis "Editar" → página 21 (P21_ID_FORMACAO, clear 21)
    │   ├── colunas: TP_FORMACAO (LOV_TIPO_FORMACAO), DS_TITULO, DS_INSTITUICAO, DT_INICIO,
    │   │            DT_CONCLUSAO, DT_VALIDADE, NR_CARGA_HORARIA, DS_LINK (link URL "Abrir"),
    │   │            DS_NOME_ARQUIVO, DS_ALERTA_VALIDADE; ID_FORMACAO oculto (PK)
    │   ├── relatório Primary: 50 linhas, destaques "Vencida" (vermelho) e "A vencer" (âmbar)
    │   ├── botão NOVA_FORMACAO "Nova formação" (rightOfInteractiveReportSearchBar · hot · ADMIN_RH)
    │   └── botão VOLTAR_AO_HISTORICO "Voltar ao histórico" (rightOfInteractiveReportSearchBar)
    ├── P19_ID_COLABORADOR (30 · Hidden · checksum de sessão)
    └── P19_NM_COLABORADOR (40 · Hidden)
```

## Lógica

- **Computations:** —
- **Validations:** —
- **Processes:** `Validar acesso` (Before Header, 10): falha com `-20012` se `P19_ID_COLABORADOR` for nulo ou `pkg_historico_carreira.fn_pode_ver_colaborador` devolver `N`; depois lê o `nome_completo` em `P19_NM_COLABORADOR` (filtra `G_ID_EMPRESA`).
- **Dynamic Actions:** `Edit Report - Dialog Closed` (`apexafterclosedialog` na região do IR) → Refresh do IR.
- **JavaScript da página:** —

## Dados

- Tabela `formacao_colaborador`; `colaborador` (nome).
- `pkg_historico_carreira.fn_hoje(:G_ID_EMPRESA)` e `fn_pode_ver_colaborador` (`modulos/historico-carreira/04_pkg_historico_carreira.pkb`).
- LOV `LOV_TIPO_FORMACAO` (valores estáticos).
- Multiempresa: a query e o processo filtram `:G_ID_EMPRESA`.

## Navegação

- Chega por: botão `FORMACOES` da barra do RH na página 13 (`P19_ID_COLABORADOR`) e coluna `COLABORADOR` de "Formações a vencer" na página 20.
- Vai para: página 21 (lápis da linha ou "Nova formação" com `P21_ID_COLABORADOR`, clear 21) e página 13 ("Voltar ao histórico", sem parâmetro: usa o `P13_ID_COLABORADOR` da sessão).

## Pegadinhas e pendências

- O lápis é o **Link Icon da região** (`link { linkIcon }`), não `Appearance › Icon` nem a coluna `DS_LINK`. O caminho exato do campo no 26.1.5 ainda não foi registrado (guia §9.10, etapa 1.2: "confirmar no 26.1.5").
- Formação sem link mostra "Abrir" sem destino (guia §9.10, nota "Linhas sem link").
- Sem `G_ID_EMPRESA` na sessão, o `select ... into` do processo dá `ORA-01403` (guia §4.7).
- O cabeçalho depende do `historico-carreira.css` e do `div class="hc" data-hc`; o nome vem do processo, não de Source/Default (guia §4.7).
- O destaque só aparece se o relatório Primary foi salvo com ele (guia §4.7).

## Referências

- [Guia do módulo, §4, §8.3 e §9.10](../../../modulos/historico-carreira/Etapas-historico-carreira.md)
- [02 · Páginas, tabela-resumo](../02-paginas.md) (sem seção própria da 19)
- [Página 21 · Formação](./p00021-formacao.md)
