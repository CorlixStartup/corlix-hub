# Página 38 · Atendimento TI

> **Estado em 13/11/2026** (backup `84f8625`): criada na app (backup de 10/11/2026, `acd59be`) conforme o §9 de [`Etapas-suporte-ti.md`](../../../modulos/suporte-ti/Etapas-suporte-ti.md), com o relatório padrão do §9.5 salvo. Sem seção "Situação" no guia, sem entrada de menu (§12) e sem registro dos testes 10 a 13 e 23 do §14.

## Resumo

| Atributo | Valor |
|---|---|
| Alias | `ATENDIMENTO-TI` |
| Modo | Normal |
| Page template | `@corlix-standard-page` |
| Autorização | `@suporte-ti` (`SUPORTE_TI`, papel "Suporte TI"); `argumentsMustHaveChecksum` |
| CSS/JS de arquivo | nenhum (a classe `cx-relatorio` vem do tema) |
| Módulo/guia | `modulos/suporte-ti/` · [`Etapas-suporte-ti.md`](../../../modulos/suporte-ti/Etapas-suporte-ti.md) §9 |
| Protótipo | — |

Fila de chamados da empresa para a equipe de TI, com link "Atender" para a p39.

## Estrutura

```
Page 38: Atendimento TI
├── Breadcrumb Bar
│   └── Cabeçalho (10, Static Content, Blank with Attributes (No Grid), css cx-cabecalho-pagina) HTML fixo: h1 + descrição
└── Body
    └── Chamados  (10, Interactive Report, template Interactive Report, css cx-relatorio,
                   t-IRR-region--hideHeader, paginação X a Y)
        Fonte: SQL sobre vw_suporte_fila where id_empresa = :G_ID_EMPRESA
        Colunas: ID_CHAMADO (hidden), CD_CHAMADO "Chamado", DS_TITULO "Título", DS_TIPO "Tipo",
                 NM_ASSUNTO "Assunto", NM_SOLICITANTE "Colaborador", NM_ATENDENTE "Atendente",
                 DS_STATUS "Situação", DS_PRIORIDADE "Prioridade", NR_PRIORIDADE (hidden),
                 DT_PREVISAO "Previsão" (DD/MM/YYYY), ABERTO_EM / ATUALIZADO_EM (DD/MM/YYYY HH24:MI),
                 ATENDER "Ação" (link → p39, P39_ID_CHAMADO = #ID_CHAMADO#, clear cache 39)
        Relatório Primary: 50 linhas, filtro DS_STATUS != 'Encerrado', ordem ABERTO_EM
```

## Lógica

- **Computations / Validations / Processes:** —
- **Dynamic Actions:** `Chamado atendido`: `apexafterclosedialog` na região `Chamados` → Refresh `Chamados`.
- **JavaScript da página:** —

## Dados

- View `vw_suporte_fila` (`modulos/suporte-ti/01_ddl_suporte.sql`), sobre `suporte_chamado`, `suporte_assunto` e `colaborador`.
- `pkg_historico_carreira.fn_data_local(id_empresa, dh_*)` converte para a hora local da empresa.
- Multiempresa: `where id_empresa = :G_ID_EMPRESA` na SQL.

## Navegação

- Chega pela URL. O menu "Administração › Atendimento TI" do §12 não existe em `lists.apx`.
- Vai para a p39 (modal) pela coluna `ATENDER`; ao fechar, o IR é atualizado.

## Pegadinhas e pendências

- Sem entrada de menu: a equipe de TI não tem como chegar à página pela navegação. Aplicar o §12 do guia.
- O papel `Suporte TI` vai para pessoas escolhidas, nunca por `cargo_papel` (guia §3.3). Quem atende precisa de colaborador vinculado.
- Não ordene por `Prioridade` (texto); a ordem padrão é `ABERTO_EM` crescente (guia §9.5).
- Autorização avaliada uma vez por sessão: depois de dar o papel, a pessoa sai e entra de novo (09 §4.1).

## Referências

- [`Etapas-suporte-ti.md`](../../../modulos/suporte-ti/Etapas-suporte-ti.md) §3, §9, §12, §14
- [Página 39](./p00039-atender-chamado.md)
- [11 · Padrões de páginas](../11-padroes-de-paginas.md) (relatório operacional: p32)
