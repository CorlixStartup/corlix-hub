# Página 7 · Monitor de Logs

> **Estado em 13/11/2026** (backup `84f8625`): implementada (3 Interactive Reports em abas). Ainda exige `@admin-rh`: o §5 de `modulos/isolamento-empresas/Etapas-isolamento-empresas.md` (passar página e menu para `EQUIPE_CORLIX_HUB`) **não está aplicado** neste export. O guia não tem seção "Situação".

## Resumo

| Atributo | Valor |
|---|---|
| Alias | `MONITOR_LOGS` |
| Modo | Normal |
| Page template | `@corlix-standard-page` |
| Autorização | `@admin-rh` (`ADMIN_RH`) · `argumentsMustHaveChecksum`. Alvo do guia: `@administration-rights` (`EQUIPE_CORLIX_HUB`) |
| CSS/JS de arquivo | nenhum; classes `log-descricao`, `log-tag`, `log-detalhe` vêm do tema global |
| Módulo/guia | `modulos/isolamento-empresas/Etapas-isolamento-empresas.md` §5 (autorização); sem guia de layout |
| Protótipo | `pen_dev/Monitor de logs.png` e `pen_dev/Monitor de logs · detalhe em Drawer.png` (`07` §4.15 e §4.16), não implementados |

Tela técnica de observabilidade: log da aplicação (`APP_LOG`), erros de página do APEX e debug do APEX.

## Estrutura

```
Page 7: Monitor de Logs
├── Breadcrumb Bar
│   └── navegação-estrutural (10 · Breadcrumb @breadcrumb · @/title-bar)
└── Body
    └── logs "Logs da aplicação" (20 · Static Content · @/tabs-container, js-useLocalStorage, mod--simple)
        ├── app_log "Log da aplicação" (10 · IR · @/interactive-report, header oculto)
        │     SQL: app_log (log_ts em America/Sao_Paulo, nivel + nivel_css, app/página/usuário/sessão,
        │     origem, mensagem, detalhe); NIVEL como t-Badge; DETALHE em <details class="log-detalhe">;
        │     header com explicação e tags (log_pkg)
        ├── apex_workspace_activity_log "Erros de página (APEX)" (20 · IR)
        │     SQL: apex_workspace_activity_log where error_message is not null (UTC → São Paulo)
        └── apex_debug_messages "Debug detalhado (APEX)" (30 · IR)
              SQL: apex_debug_messages, nível 1/2/4 → ERRO/AVISO/INFO, senão DEBUG; badge igual
```

## Lógica

- **Computations / Validations / Processes / Dynamic Actions / JavaScript:** —
- Os três IRs têm relatório Primary ordenado pela data desc.

## Dados

- Tabela `APP_LOG` e package `LOG_PKG` (DDL em `database/corlix-hub.sql`; ver `05` §4.9).
- Views do APEX `APEX_WORKSPACE_ACTIVITY_LOG` e `APEX_DEBUG_MESSAGES`.
- Multiempresa: **não filtra** (logs de todas as empresas e do workspace inteiro). Por isso o guia restringe a página à equipe do Corlix Hub.

## Navegação

- Chega por: menu Administração › Monitor de logs (entrada `terminal`, `@admin-rh`).
- Vai para: —

## Pegadinhas e pendências

- **Pendente (`Etapas-isolamento-empresas.md` §5):** trocar `Security › Authorization Scheme` da página e da entrada do menu para `EQUIPE_CORLIX_HUB`. Testes 7 e 8 do §7 desse guia sem registro.
- As views do APEX não filtram `application_id`: mostram o workspace inteiro (`02-paginas.md`, página 7).
- Colunas de data declaradas `DATE` com SQL que retorna `TIMESTAMP WITH TIME ZONE` (`02-paginas.md`).
- O protótipo tem drawer de detalhe por registro; hoje o detalhe é um `<details>` dentro da linha.
- Destino antigo do link rápido "Suporte TI" da Home antiga; a Início atual leva à página 34.

## Referências

- [Isolamento entre empresas, §5 e §7](../../../modulos/isolamento-empresas/Etapas-isolamento-empresas.md)
- [02 · Páginas, página 7](../02-paginas.md)
- [05 · Banco de dados, APP_LOG/LOG_PKG](../05-banco-de-dados.md)
- [07 · Design, §4.15 e §4.16](../07-design-pen-dev.md)
