# Página 20 · Dashboard RH

> **Estado em 13/11/2026** (backup `84f8625`): implementada na versão do `modulos/historico-carreira/Etapas-historico-carreira.md` §5 (gráficos JET + relatórios), validada (§9, "Situação na revalidação de 19/10/2026": §5 ✅). O redesign do `modulos/dashboard-rh/Etapas-dashboard-rh.md` **não foi aplicado**: o export não tem as regiões do `pkg_dashboard_rh_ui`, o `dashboard-rh.css` não está nos Static Files e o package não aparece em `database/ddl/`. O guia do redesign não tem seção "Situação".

## Resumo

| Atributo | Valor |
|---|---|
| Alias | `DASHBOARD-RH` |
| Modo | Normal |
| Page template | `@/standard` (Universal Theme, não o `@corlix-standard-page`) |
| Autorização | `@admin-rh` (`ADMIN_RH`) · `argumentsMustHaveChecksum` |
| CSS/JS de arquivo | `#APP_FILES#historico-carreira#MIN#.css` (o redesign troca por `dashboard-rh#MIN#.css`) |
| Módulo/guia | atual: `modulos/historico-carreira/Etapas-historico-carreira.md` §5 · redesign: `modulos/dashboard-rh/Etapas-dashboard-rh.md` |
| Protótipo | `pen_dev/Dashboard RH.png` (alvo do redesign; não está na tabela do `07-design-pen-dev.md`) |

Painel do RH com promoções, turnover e tempo no cargo por departamento, formações que vencem em 60 dias e solicitações de correção abertas. O período De/Até vale só para promoções e turnover.

## Estrutura

```
Page 20: Dashboard RH
└── Body
    ├── cabeçalho (5 · Static Content · @/blank-with-attributes-no-grid)
    │     HTML <div class="hc" data-hc> com <h1>Dashboard RH</h1>
    ├── período (10 · Static Content · @/standard, cabeçalho oculto)
    │   ├── P20_DT_INICIO "De"  (Date Picker DD/MM/YYYY · obrigatório · default 1º dia de 11 meses atrás, por fn_hoje)
    │   └── P20_DT_FIM    "Até" (Date Picker · mesma linha · minDate = P20_DT_INICIO · default hoje)
    ├── grafico_promocoes "Promoções por departamento" (20 · Chart barra horizontal · 360px)
    │     série: vw_movimentacao_valida cd_tipo = 'PROMOCAO' no período, por departamento novo
    ├── grafico_turnover "Turnover: admissões x desligamentos por mês" (25 · Chart barra · 2 séries)
    │     séries Admissões e Desligamentos: meses do período (rótulo yyyy/mm) × vw_movimentacao_valida
    ├── grafico_tempo_cargo "Tempo médio no cargo por departamento" (35 · Chart barra horizontal)
    │     série: vw_situacao_atual_colaborador, vínculo ativo, média de anos desde dt_inicio_funcao
    ├── rel_formacoes_vencer "Formações a vencer" (45 · Classic Report)
    │     formacao_colaborador + colaborador, validade entre hoje e hoje + 60; COLABORADOR é link → p19
    └── rel_solicitacoes "Solicitações de correção abertas" (55 · Interactive Report)
          solicitacao_correcao ABERTA + colaborador + historico_carreira + tipo_movimentacao;
          COLABORADOR é link → p13; RESPONDER "Responder" → p23 (clear 23)
```

## Lógica

- **Computations:** —
- **Validations:** — (só `valueRequired` nos dois itens de data).
- **Processes:** —
- **Dynamic Actions:**
  - `Período mudou` (change em `P20_DT_INICIO`/`P20_DT_FIM`, condição JS: os dois preenchidos) → Refresh `grafico_promocoes` ("Atualizar promoções") e `grafico_turnover` ("Atualizar turnover").
  - `Atualizar solicitações` (`apexafterclosedialog` na região `rel_solicitacoes`) → Refresh da região ("Atualizar lista").
- **JavaScript da página:** —

## Dados

- Views `vw_movimentacao_valida` e `vw_situacao_atual_colaborador`; tabelas `departamento`, `formacao_colaborador`, `colaborador`, `solicitacao_correcao`, `historico_carreira`, `tipo_movimentacao` (DDL e views em `modulos/historico-carreira/01_ddl_historico_carreira.sql` e `03_views_carreira.sql`).
- `pkg_historico_carreira.fn_hoje` e `fn_data_local` (`modulos/historico-carreira/04_pkg_historico_carreira.pkb`).
- LOV `LOV_TIPO_FORMACAO` na coluna `TIPO`.
- Multiempresa: todas as queries filtram `:G_ID_EMPRESA`.
- Redesign (não instalado): `modulos/dashboard-rh/pkg_dashboard_rh_ui.pks`/`.pkb`, com `render_indicadores`, `render_turnover`, `render_departamentos`, `render_solicitacoes`, `render_formacoes`.

## Navegação

- Chega por: menu "Administração › Dashboard RH" (`@admin-rh`) e link "Ver no painel do RH" da página 13 (`pkg_historico_carreira_ui`, `c_pagina_painel_rh = 20`).
- Vai para: página 19 (nome em "Formações a vencer", `P19_ID_COLABORADOR`), página 13 (nome em "Solicitações", `P13_ID_COLABORADOR`) e modal 23 ("Responder", `P23_ID_SOLICITACAO`, clear 23).

## Pegadinhas e pendências

- Redesign pendente: aplicar o `Etapas-dashboard-rh.md` (package, Static Files, regiões novas, DA `Solicitação respondida` escutando `document`) e apagar as regiões antigas. A versão atual de referência para voltar atrás é o `.apx` do commit `47a2d40` (guia do redesign).
- Gráfico JET com mais de uma série ordena os rótulos como texto: por isso o turnover usa `to_char(mes, 'yyyy/mm')` (`08-convencoes-e-pegadinhas.md` §3, Páginas).
- "Tempo médio no cargo", "Formações a vencer" e "Solicitações" não usam o período (guia §8.4).
- Decisões do time (guia §9.10): "Formações a vencer" inclui desligados; De/Até só limita o calendário, e um fim antes do início esvazia os gráficos.
- Existe entrada de breadcrumb para a página 20, mas a página não tem região de breadcrumb.

## Referências

- [Guia do histórico de carreira, §5, §8.4 e §9](../../../modulos/historico-carreira/Etapas-historico-carreira.md)
- [Guia do redesign do Dashboard RH](../../../modulos/dashboard-rh/Etapas-dashboard-rh.md)
- [Protótipo](../../../pen_dev/Dashboard%20RH.png)
- [02 · Páginas, tabela-resumo](../02-paginas.md) (sem seção própria da 20)
- [Página 23 · Responder solicitação](./p00023-responder-solicitacao.md)
