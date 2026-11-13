# Página 40 · Status dos sistemas

> **Estado em 13/11/2026** (backup `84f8625`): criada na app (backup de 10/11/2026, `acd59be`) pelo assistente de Interactive Report + formulário, com os ajustes do §10.2 de [`Etapas-suporte-ti.md`](../../../modulos/suporte-ti/Etapas-suporte-ti.md) aplicados (filtro por empresa, ordem, colunas e headings). Textos do assistente seguem em inglês. Sem seção "Situação" no guia, sem menu (§12) e sem registro dos testes 19 a 21 do §14.

## Resumo

| Atributo | Valor |
|---|---|
| Alias | `STATUS-DOS-SISTEMAS` |
| Modo | Normal |
| Page template | `@corlix-standard-page` |
| Autorização | `@suporte-ti` (`SUPORTE_TI`); `argumentsMustHaveChecksum` |
| CSS/JS de arquivo | nenhum |
| Módulo/guia | `modulos/suporte-ti/` · [`Etapas-suporte-ti.md`](../../../modulos/suporte-ti/Etapas-suporte-ti.md) §10 |
| Protótipo | — (alimenta o card "Status dos sistemas" e o aviso de `pen_dev/Suporte TI.png`) |

Lista dos sistemas da empresa, mantida pela TI. O que se grava aqui aparece na p34: selo de situação, detalhe e aviso de instabilidade.

## Estrutura

```
Page 40: Status dos sistemas
├── Breadcrumb Bar
│   └── Breadcrumb (10, Breadcrumb, template Title Bar, useBreadcrumbTitle) breadcrumb compartilhado, entrada "Status dos sistemas" (p40)
└── Body
    └── Status dos sistemas (10, Interactive Report, hideHeader, paginação X a Y)
        Fonte: tabela SUPORTE_SISTEMA, where id_empresa = :G_ID_EMPRESA, order by nr_ordem
        Link de linha: ícone fa-edit → p41 (P41_ID_SISTEMA = #ID_SISTEMA#)
        Visíveis: NM_SISTEMA "Sistema", ST_SISTEMA "Situação", DS_DETALHE "Detalhe", DS_AVISO_TITULO "Aviso"
        Ocultas: ID_SISTEMA, ID_EMPRESA, NR_ORDEM, DS_AVISO_TEXTO, DH_ATUALIZACAO, USR_ATUALIZACAO
        Botão CREATE (rightOfInteractiveReportSearchBar, hot) "Create" → p41, clear cache 41
```

## Lógica

- **Computations / Validations / Processes:** —
- **Dynamic Actions:** `Edit Report - Dialog Closed`: `apexafterclosedialog` na região → Refresh da região.
- **JavaScript da página:** —

## Dados

- Tabela `suporte_sistema` (`modulos/suporte-ti/01_ddl_suporte.sql`); trigger `trg_suporte_sistema_aud` preenche `dh_atualizacao` e `usr_atualizacao`.
- Lida na p34 por `pkg_suporte_ui.render_status` e `render_aviso`.
- Multiempresa: `whereClause: id_empresa = :G_ID_EMPRESA`.

## Navegação

- Chega pela URL. O menu "Administração › Status dos sistemas" do §12 não existe em `lists.apx`.
- Vai para a p41 (modal) pelo ícone de edição e pelo botão `CREATE`.

## Pegadinhas e pendências

- Textos do assistente em inglês: botão "Create", mensagens "No data found." e de limite de linhas, ícone com `aria-label="Edit"`.
- `ST_SISTEMA` aparece com o código (`OPERANDO`, `INSTAVEL`, `MANUTENCAO`, `FORA`), sem LOV de exibição.
- Página usa a região Breadcrumb do assistente, e não o cabeçalho `cx-cabecalho-pagina` da regra E3 do [11](../11-padroes-de-paginas.md).
- Sem entrada de menu (§12).

## Referências

- [`Etapas-suporte-ti.md`](../../../modulos/suporte-ti/Etapas-suporte-ti.md) §10, §12, §14
- [Página 41](./p00041-sistema.md) · [Página 34](./p00034-suporte-ti.md)
- [08 §3](../08-convencoes-e-pegadinhas.md) (formulário editável só pelo assistente no 26.1.5)
