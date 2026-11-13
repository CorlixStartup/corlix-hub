# Página 32 · Ajustes de ponto

> **Estado em 13/11/2026** (backup `84f8625`): implementada, com `Pedido em` em hora local (`Etapas-meus-pedidos.md` §2), e validada na app em 03/11/2026 no DEV (`modulos/ponto-eletronico/Etapas-ajustes-validacao.md`, "Resultado na app": não mostra o pedido da própria conta; mostra ao gestor direto).

## Resumo

| Atributo | Valor |
|---|---|
| Alias | `AJUSTES-DE-PONTO` |
| Modo | Normal |
| Page template | `@corlix-standard-page` |
| Autorização | `@aprovador-ponto` (`APROVADOR_PONTO`: `pkg_ponto.fn_e_aprovador = 'S'`, RH ou quem tem subordinado) · `argumentsMustHaveChecksum` |
| CSS/JS de arquivo | nenhum; classes `cx-cabecalho-pagina` e `cx-relatorio` vêm do `custom.css` global |
| Módulo/guia | `modulos/ponto-eletronico/` · `Etapas-ponto-eletronico.md` §7 |
| Protótipo | não há em `pen_dev/` |

Fila dos pedidos de ajuste e abono pendentes que a conta logada pode responder (gestor direto ou RH, nunca o próprio colaborador).

## Estrutura

```
Page 32: Ajustes de ponto
├── Breadcrumb Bar
│   └── cabeçalho (10 · Static Content · @/blank-with-attributes-no-grid · CSS class cx-cabecalho-pagina)
│         HTML: título "Ajustes de ponto" e descrição
└── Body
    └── pedidos-pendentes "Pedidos pendentes" (10 · Interactive Report · @/interactive-report, cabeçalho oculto · cx-relatorio)
        ├── fonte: ponto_ajuste PENDENTE da G_ID_EMPRESA + colaborador, filtrado por pkg_ponto.fn_pode_aprovar = 'S'
        ├── colunas: ID_AJUSTE (oculta), COLABORADOR, DIA (DD/MM/YYYY), PEDIDO, HORARIO, MOTIVO,
        │            PEDIDO_EM (fn_data_local, DD/MM/YYYY HH24:MI), RESPONDER (link "Responder" → p33)
        └── relatório Primary: 50 linhas
```

## Lógica

- **Computations / Validations / Processes:** —
- **Dynamic Actions:** `Pedido respondido` (`apexafterclosedialog` na região) → Refresh do IR.
- **JavaScript da página:** —

## Dados

- Tabelas `ponto_ajuste`, `colaborador` (`modulos/ponto-eletronico/01_ddl_ponto.sql`).
- `pkg_ponto.fn_pode_aprovar` e `fn_e_aprovador` (`03_pkg_ponto.pkb`); `pkg_historico_carreira.fn_data_local`.
- Multiempresa: a query filtra `:G_ID_EMPRESA`.

## Navegação

- Chega por: menu "Administração › Ajustes de ponto" (seq 67, `@aprovador-ponto`) e Início (`pkg_home_ui.render_pendencias`).
- Vai para: modal 33 (coluna `RESPONDER`, `P33_ID_AJUSTE`, clear 33).

## Pegadinhas e pendências

- `APROVADOR_PONTO` devolve falso para conta sem colaborador (`-20012` tratado na authorization) e é avaliada por sessão: depois de mudar papel ou gestor, sair e entrar.
- O guia §7.1 diz alias `AJUSTES-PONTO`; o export tem `AJUSTES-DE-PONTO`. Os links usam o número da página.
- O guia §8 pede "Current" `32:33` na entrada do menu; o `lists.apx` atual não tem `isCurrent` nessa entrada (nem em "Ponto eletrônico").
- Sem mensagem de vazio própria; textos do IR em inglês ("Search", "Go", "Actions") ainda sem correção (`Etapas-ajustes-validacao.md`, "Resultado na app").

## Referências

- [Guia do ponto, §7 e §8](../../../modulos/ponto-eletronico/Etapas-ponto-eletronico.md)
- [Ajustes da validação, §3 e "Resultado na app"](../../../modulos/ponto-eletronico/Etapas-ajustes-validacao.md)
- [Meus pedidos, §2](../../../modulos/ponto-eletronico/Etapas-meus-pedidos.md)
- [02 · Páginas, seção "Páginas 30 a 33"](../02-paginas.md)
- [Página 33 · Responder ajuste](./p00033-responder-ajuste.md)
