# Página 13 · Histórico de carreira

> **Estado em 13/11/2026** (backup `84f8625`): implementada e validada. O `modulos/historico-carreira/Etapas-historico-carreira.md` §9 ("Situação na revalidação de 19/10/2026") marca o §2 (página 13) como ✅ no export; o export atual tem os mesmos processos, regiões, barra do RH e DA.

## Resumo

| Atributo | Valor |
|---|---|
| Alias | `HISTORICO-DE-CARREIRA` (sem acento desde 19/10/2026) |
| Modo | Normal |
| Page template | `@/standard` (divergência E1 do `11` §6) |
| Autorização | `@colaborador` (`COLABORADOR`) · `argumentsMustHaveChecksum`; barra do RH, Lançamentos (RH) e botões com `@admin-rh` |
| CSS/JS de arquivo | `#APP_FILES#historico-carreira#MIN#.css`; JS na própria página (namespace `hc`) |
| Módulo/guia | `modulos/historico-carreira/` (`Etapas-historico-carreira.md` §2) |
| Protótipo | `pen_dev/Histórico de carreira — nova página.png` (`07` §4.13) |

Linha do tempo da carreira de uma pessoa (resumo, cargos ao longo do tempo, eventos com abas e filtro de ano, posição atual). O colaborador vê o próprio; o gestor, a equipe; o RH, qualquer pessoa da empresa, com lançamentos e salários.

## Estrutura

```
Page 13: Histórico de carreira
└── Body
    ├── hc_barra_rh "Barra do RH" (10 · Static Content · @/blank-with-attributes-no-grid · hc-barra-rh · @admin-rh)
    │   ├── P13_COLABORADOR_SELECIONADO "Ver histórico de" (10 · Popup LOV · @admin-rh)
    │   │     LOV: colaborador da G_ID_EMPRESA (" (inativo)" nos inativos); source/default = P13_ID_COLABORADOR
    │   ├── botão FORMACOES "Formações" (20 · @admin-rh) → página 19 (P19_ID_COLABORADOR)
    │   └── botão NOVA_MOVIMENTACAO "Nova movimentação" (30 · @admin-rh) → página 18 (P18_ID_COLABORADOR)
    ├── historico_carreira "Histórico de carreira" (20 · Dynamic Content · @/blank-with-attributes
    │     · DOM id historico_carreira) → return pkg_historico_carreira_ui.render(:P13_ID_COLABORADOR);
    ├── lançamentos-rh "Lançamentos (RH)" (30 · IR · @/collapsible fechado · @admin-rh)
    │     SQL: vw_historico_carreira do P13_ID_COLABORADOR e da G_ID_EMPRESA; link "Editar" → página 18
    │     (P18_ID_HISTORICO_CARREIRA, P18_ID_COLABORADOR, clear 18); colunas de salário com @admin-rh
    └── P13_ID_COLABORADOR (40 · Hidden · checksum de sessão)
```

## Lógica

- **Computations / Validations:** —
- **Processes:**
  - `Trocar colaborador` (Processing, 5, request `TROCAR_COLABORADOR`, `@admin-rh`): `P13_ID_COLABORADOR := P13_COLABORADOR_SELECIONADO`.
  - `Colaborador padrão` (Before Header, 10): sem ID, usa o colaborador do `APP_USER` na `G_ID_EMPRESA`; senão `-20012`.
  - `Validar acesso` (Before Header, 20): `-20012` se `pkg_historico_carreira.fn_pode_ver_colaborador` devolver `N`.
  - `Registrar acesso salarial` (Before Header, 30, `@admin-rh`): `pkg_historico_carreira.registrar_acesso_salarial`.
  - Branch `Recarregar` (request `TROCAR_COLABORADOR`) → página 13.
- **Dynamic Actions:** `Atualizar depois da modal` (`apexafterclosedialog`) → refresh de `historico_carreira` e `lançamentos-rh`; `Trocar colaborador` (change no seletor, se não nulo) → Submit Page com request `TROCAR_COLABORADOR`.
- **JavaScript da página:** `hc.filtrar` (abas e ano, cabeçalhos por ano, estado vazio), `hc.iniciar` (cliques, setas entre abas, "Exportar" = `window.print()`, mostra tudo ao imprimir), `hc.preparar` no Page Load e no `apexafterrefresh` de `#historico_carreira`.

## Dados

- `pkg_historico_carreira_ui.render` (`modulos/historico-carreira/08_pkg_historico_carreira_ui.sql`); `pkg_historico_carreira` (`04_pkg_historico_carreira.pks`/`.pkb`): `fn_pode_ver_colaborador`, `registrar_acesso_salarial`.
- View `vw_historico_carreira` (`03_views_carreira.sql`); tabelas do módulo em `01_ddl_historico_carreira.sql`.
- Multiempresa: processos, LOV e IR filtram `:G_ID_EMPRESA`.

## Navegação

- Chega por: menu Minha carreira › Histórico de carreira (`@colaborador`); botão `HISTORICO` da página 14 (`P13_ID_COLABORADOR`); links das páginas 19 e 20.
- Vai para: páginas 18 (modal de movimentação) e 19 (formações); pelos links do package (constantes `c_pagina_*` em `08_pkg_historico_carreira_ui.sql`): 22 ("Solicitar correção", só para o próprio), 3 ("Ver no organograma", `P3_ID_FOCO`), 11 ("Ver comunicado", sem item) e 20 (painel RH). `c_pagina_holerite` está nulo ("ainda não existe no app"), embora a página 9 já exista: o link do holerite não aparece.

## Pegadinhas e pendências

- O `htmlDomId` `historico_carreira` é obrigatório: o JS e a DA usam esse id (08 §3, "Static ID ≠ id do HTML").
- Salário nunca aparece na região do package; só no IR do RH, com log de acesso (`Etapas-historico-carreira.md` §2).
- O protótipo mostra PDI, Resultados 360, "Aprovado por" e "CLT · efetivado" sem dado no app (§2.9 do guia).
- `fn_pode_ver_colaborador` filtra a empresa só depois do `CONNECT BY` (`Etapas-isolamento-empresas.md`, "Fica para depois").
- O `08` §3 ainda lista a página como placeholder; vale este `.apx`.

## Referências

- [Guia do histórico de carreira, §2, §8 e §9](../../../modulos/historico-carreira/Etapas-historico-carreira.md)
- [02 · Páginas, página 13](../02-paginas.md)
- [Página 18 · Movimentação](./p00018-movimentacao.md) · [Página 19 · Formações e certificações](./p00019-formacoes-e-certificacoes.md)
