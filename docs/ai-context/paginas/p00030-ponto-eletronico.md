# Página 30 · Ponto eletrônico

> **Estado em 13/11/2026** (backup `84f8625`): implementada, com os ajustes de `Etapas-ajustes-validacao.md` e `Etapas-meus-pedidos.md` aplicados, e validada na app em 03/11/2026 no DEV (`modulos/ponto-eletronico/Etapas-ajustes-validacao.md`, "Resultado na app"). Falta testar na app a mensagem "Marcação registrada: ..." e o CSV de meses anteriores.

## Resumo

| Atributo | Valor |
|---|---|
| Alias | `PONTO-ELETRONICO` |
| Modo | Normal |
| Page template | `@corlix-standard-page` |
| Autorização | `@colaborador` (`COLABORADOR`) · `argumentsMustHaveChecksum` |
| CSS/JS de arquivo | `#APP_FILES#ponto-eletronico/ponto.css` (sem `#MIN#`); JS inline igual a `modulos/ponto-eletronico/ponto-pagina.js` |
| Módulo/guia | `modulos/ponto-eletronico/` · `Etapas-ponto-eletronico.md` §4 |
| Protótipo | `pen_dev/Ponto eletrônico.png` |

Tela do colaborador para registrar o ponto e acompanhar marcações do dia, espelho do mês, banco de horas, pendências, pedidos e jornada. Todo o HTML vem do `pkg_ponto_ui`.

## Estrutura

```
Page 30: Ponto eletrônico
├── Breadcrumb Bar
│   └── cabeçalho (10 · Dynamic Content · pkg_ponto_ui.render_cabecalho · @/blank-with-attributes-no-grid)
├── Body
│   ├── coluna-principal (10 · Static Content · @/blank-with-attributes · span 8)
│   │   ├── P30_COMPETENCIA (Hidden · valueProtected: false · mês YYYYMM)
│   │   ├── ponto_relogio  (10 · Dynamic Content · render_relogio · htmlDomId ponto_relogio)
│   │   └── ponto_espelho  (20 · Dynamic Content · render_espelho(:P30_COMPETENCIA) · submit P30_COMPETENCIA · htmlDomId ponto_espelho)
│   └── coluna-lateral (20 · Static Content · span 4 · mesma linha)
│       ├── ponto_banco      (10 · render_banco · htmlDomId ponto_banco)
│       ├── ponto_pendencias (20 · render_pendencias · htmlDomId ponto_pendencias; inclui "Meus pedidos")
│       └── ponto_jornada    (30 · render_jornada · htmlDomId ponto_jornada)
└── Dialogs, Drawers and Popups (todas @/inline-dialog, js-dialog-autoheight, 720x480)
    ├── ponto_dlg_comprovantes "Comprovantes de marcação" (30 · render_comprovantes)
    ├── ponto_dlg_mes          "Espelho do mês"           (40 · render_espelho(:P30_COMPETENCIA, null, 'N'))
    ├── ponto_dlg_extrato      "Extrato do banco de horas" (50 · render_extrato)
    └── ponto_dlg_assinatura   "Assinar espelho"          (60 · render_assinatura)
```

Os botões ("Registrar …", "Baixar espelho", "Solicitar ajuste", "Justificar", "Ver …", "Revisar e assinar") são HTML do package com atributos `data-cx-ponto-*`; não há botões nativos.

## Lógica

- **Computations / Validations:** —
- **Processes (Ajax Callback, sem authorization própria; a página exige `COLABORADOR`):**
  - `REGISTRAR_MARCACAO` (10) · `pkg_ponto_ui.ajax_registrar(apex_application.g_x01)` (x01 = tipo de marcação mostrado na tela).
  - `ASSINAR_ESPELHO` (20) · `pkg_ponto_ui.ajax_assinar(g_x01)` (x01 = competência).
  - `BAIXAR_ESPELHO` (30) · `pkg_ponto_ui.ajax_baixar_espelho(g_x01)`; devolve `nome` e `conteudo` (CSV com `;`).
  - Todos respondem `{ok, mensagem}`.
- **Dynamic Actions:** — (eventos no JS da página).
- **JavaScript da página (Execute when Page Loads):**
  - `cxPontoAtualizar(regioes)`: refresh das regiões pelo HTML DOM ID.
  - `cxPontoChamar(processo, valor, ...)`: `apex.server.process` com x01 e tratamento de `{ok, mensagem}`.
  - Clique em `[data-cx-ponto-registrar]` → `REGISTRAR_MARCACAO`, mensagem e refresh de tudo.
  - Clique em `[data-cx-ponto-dialogo]` → `apex.theme.openRegion(<id do diálogo>)`.
  - Clique em `[data-cx-ponto-assinar]` → confirmação e `ASSINAR_ESPELHO`; fecha o diálogo e atualiza pendências.
  - Change em `[data-cx-ponto-competencia]` → grava `P30_COMPETENCIA` e atualiza espelho e diálogo do mês.
  - Clique em `[data-cx-ponto-baixar]` → `BAIXAR_ESPELHO` e download do CSV com BOM.
  - `apexafterclosedialog` em `document` → atualiza espelho, pendências e diálogo do mês (volta da página 31).
  - Relógio: a cada segundo atualiza hora e "trabalhadas hoje" a partir da hora do servidor (`data-segundos`).

## Dados

- Packages `pkg_ponto` (`03_pkg_ponto.pks`/`.pkb`, regras) e `pkg_ponto_ui` (`04_pkg_ponto_ui.pks`/`.pkb`, HTML e callbacks), em `modulos/ponto-eletronico/`.
- Tabelas `ponto_jornada`, `ponto_colaborador`, `ponto_feriado`, `ponto_ajuste`, `ponto_marcacao` (trigger `trg_ponto_marcacao_imutavel`), `ponto_espelho_assinatura` e view `vw_ponto_marcacao_vigente` (`01_ddl_ponto.sql`).
- Depende de `pkg_historico_carreira.fn_hoje`, `fn_data_local` e `fn_empresa_contexto`.
- Multiempresa: sem `p_id_colaborador`, cada função usa o colaborador da conta logada (spec do `pkg_ponto_ui`).

## Navegação

- Chega por: menu "Ponto eletrônico" (seq 35, `@colaborador`) e links da Início (`pkg_home_ui.render_indicadores` "ver espelho" e `render_pendencias`).
- Vai para: modal 31 ("Solicitar ajuste" do cabeçalho com clear 31; "Justificar" com `P31_DT_REFERENCIA`, `P31_TP_AJUSTE` e, se marcação, `P31_TP_MARCACAO`), por `apex_page.get_url`.

## Pegadinhas e pendências

- Os 9 HTML DOM IDs são obrigatórios: o JS abre diálogos e atualiza regiões pelo id (`Etapas-ajustes-validacao.md` §2.1; `08-convencoes-e-pegadinhas.md` §3, "Static ID ≠ id do HTML").
- A página carrega `ponto.css`, não `ponto#MIN#.css`: o `.min.css` não é usado. O `ponto.css` dos Static Files difere do do módulo só em espaços e quebras de linha (conferido em 13/11/2026).
- A hora gravada é a do servidor; o relógio da tela só acompanha.
- Contas sem colaborador (SARAHSILVA, EDUARDOMARINS, ALAIRTONROCHA) veem só o aviso de conta sem vínculo (guia, "Conta de teste").
- Não é REP-P homologado; férias, turnos noturnos e cadastros de jornada ficam de fora (guia, "Fica de fora").
- `pkg_ponto_ui.render_comprovantes` aceita `p_id_colaborador` sem comparar com a sessão (`Etapas-isolamento-empresas.md`, "Fica para depois"); a página não passa o parâmetro.
- Textos do APEX em inglês ("1 error has occurred", "Required"...) ainda sem correção (`Etapas-ajustes-validacao.md`, "Resultado na app").
- Dados de teste ficaram no DEV para a conta `TESTE.RH` (colaborador 292); `06_remover_dados_demo.sql` remove só os de demonstração.

## Referências

- [Guia do ponto, §4](../../../modulos/ponto-eletronico/Etapas-ponto-eletronico.md)
- [Ajustes da validação e "Resultado na app"](../../../modulos/ponto-eletronico/Etapas-ajustes-validacao.md)
- [Meus pedidos](../../../modulos/ponto-eletronico/Etapas-meus-pedidos.md)
- [Protótipo](../../../pen_dev/Ponto%20eletr%C3%B4nico.png)
- [02 · Páginas, seção "Páginas 30 a 33"](../02-paginas.md)
