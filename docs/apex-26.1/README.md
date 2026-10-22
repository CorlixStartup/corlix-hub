# Oracle APEX 26.1 · Base de conhecimento para IAs

> Referência técnica do Oracle APEX 26.1 em pt-BR, escrita a partir da **documentação oficial** ([docs.oracle.com/en/database/oracle/apex/26.1](https://docs.oracle.com/en/database/oracle/apex/26.1/index.html), biblioteca de 10/08/2026). Gerada em 21/10/2026.
> **Versão:** o projeto roda o **APEX 26.1.5** (export em `database/f100.sql`). A Oracle publica uma documentação por release (26.1) e entrega os patches 26.1.x só como correções de bugs, então esta base vale para o 26.1.5. O que muda até o 26.1.5 está no [14](./14-patch-set-26-1-5.md).
> Complementa o [`docs/ai-context/`](../ai-context/README.md): lá está **este projeto** (páginas, schema, convenções), aqui está **o APEX**. Se os dois divergirem sobre o projeto, vale o `ai-context` e o código. Se divergirem sobre o comportamento do APEX, vale a documentação oficial (confira pelo link `Fonte:` de cada seção).

## Como usar

1. **Busque primeiro, leia depois.** Todos os documentos desta pasta são indexados por seção no Elasticsearch, junto com os casos do projeto:
   ```sh
   python3 scripts/busca-casos/casos.py buscar "interactive grid salvar linhas" --modulo apex-26.1
   ```
2. **Para detalhe exato** (assinatura completa, todos os atributos, texto original), busque na **documentação oficial inteira** (3.340 páginas, índice `apex-docs`, em inglês):
   ```sh
   python3 scripts/busca-casos/casos.py buscar "APEX_COLLECTION.ADD_MEMBER" --fonte apex
   python3 scripts/busca-casos/casos.py buscar "authorization evaluation point" --fonte todas
   ```
   Cada resultado traz o link oficial e o caminho do texto local em `.cache/apex-docs/md/`. Para montar o cache e o índice: [`scripts/busca-casos/README.md`](../../scripts/busca-casos/README.md).
3. Cada `###` termina com `Fonte:` apontando para a página oficial. Passo a passo do Builder deve seguir o **26.1.5**: caminho não conferido leva "(confirmar no 26.1.5)" (ver `ai-context/08` §1, regra 11).

## Documentos

| # | Documento | Conteúdo | Livros-fonte |
|---|---|---|---|
| 01 | [Conceitos, sessão e fluxo](./01-conceitos-sessao-e-fluxo.md) | Arquitetura, renderização × processamento, sessão, session state, URLs, substitution strings, computations/validations/processes/branches, condições, limites | App Builder, Developer's Companion |
| 02 | [Páginas, formulários e itens](./02-paginas-formularios-e-itens.md) | Tipos de página, Page Designer, layout, Form region e DML, tipos de item, botões, Dynamic Actions, master-detail, modais | App Builder, Developer's Companion |
| 03 | [Relatórios, grids e visualização](./03-relatorios-grids-e-visualizacao.md) | Interactive Report, Interactive Grid (inclusive editável), Classic Report, Cards, charts, Faceted Search, Smart Filters, mapas, calendário | App Builder, Developer's Companion, End User's Guide |
| 04 | [Shared Components, tema e plug-ins](./04-componentes-compartilhados-tema-e-plugins.md) | LOVs, app items/processes, build options, static files, templates e Template Options, Universal Theme, Theme Styles, Template Components, globalização, plug-ins | App Builder, Developer's Companion |
| 05 | [Segurança](./05-seguranca.md) | Authentication e authorization schemes, ACL, Session State Protection, checksums, escaping, CSP | App Builder, Developer's Companion, Administration |
| 06 | [API PL/SQL: núcleo](./06-api-plsql-nucleo.md) | APEX_UTIL, APEX_PAGE, APEX_SESSION, APEX_ERROR, APEX_DEBUG, APEX_ESCAPE, APEX_STRING, APEX_JSON, APEX_COLLECTION, APEX_ACL, APEX_REGION, APEX_IR/IG… | API Reference |
| 07 | [API PL/SQL: dados, integração e processos](./07-api-plsql-dados-integracao-e-processos.md) | APEX_WEB_SERVICE, APEX_EXEC, APEX_MAIL, APEX_DATA_*, APEX_AI, APEX_WORKFLOW, APEX_HUMAN_TASK, APEX_BACKGROUND_PROCESS, APEX_AUTOMATION, APEX_EXPORT… | API Reference |
| 08 | [API JavaScript](./08-api-javascript.md) | apex.item, apex.region, apex.server, apex.message, apex.navigation, apex.page, model e widgets (Interactive Grid), eventos | JavaScript API Reference |
| 09 | [APEXlang](./09-apexlang.md) | Sintaxe dos `.apx`, estrutura do export e referência por componente. **Leia antes de editar `corlixhub/`** | APEXlang API Reference, Developer's Companion |
| 10 | [Workflows, automações, notificações e IA](./10-workflows-automacoes-notificacoes-e-ia.md) | Workflows, Task Definitions e aprovações, Execution Chains, background, automations, e-mail, push/PWA, IA generativa, Search | Developer's Companion, App Builder |
| 11 | [Dados, REST, arquivos e PDF](./11-dados-rest-arquivos-e-relatorios-pdf.md) | REST Data Sources, Web Credentials, ORDS/RESTful Services, data loading, upload/download de arquivos, collections, relatórios PDF, geocoding | App Builder, Developer's Companion, SQL Workshop |
| 12 | [Administração, ambiente e ciclo de vida](./12-administracao-ambiente-e-ciclo-de-vida.md) | Instância × workspace, instalação/ORDS, SQL Workshop, deploy e export/import, debug, performance, logs; acessibilidade, Data Reporter, End User | Administration, Installation, SQL Workshop, App Builder… |
| 13 | [Novidades e deprecações do 26.1](./13-novidades-mudancas-e-deprecacoes-26-1.md) | New features, changed behavior, deprecated/desupported, known issues, checklist do que evitar | Release Notes + "Changes in Release 26.1" |
| 14 | [Patch set 26.1.5](./14-patch-set-26-1-5.md) | Por que a doc 26.1 vale para o 26.1.5 em uso; as 124 correções dos patches 26.1.1–26.1.5 e as que afetam o projeto | Known Issues (oracle.com, 30/09/2026) |

### Guia rápido por tarefa
- **Editar um `.apx`:** 09 → 02/03 (o componente) → `ai-context/02` (a página do projeto).
- **Escrever PL/SQL de página ou package:** 01 (session state, bind vars) → 06/07 (API) → `ai-context/09` (erros já vistos).
- **JavaScript ou Dynamic Action:** 02 (DAs) → 08.
- **Permissão, login ou "Access denied":** 05 → `ai-context/09` §4.1.
- **Integração REST, e-mail, arquivos:** 11 → 07.
- **Erro de ambiente, SQL Workshop ou debug:** 12 → `ai-context/09` e `10`.
- **Antes de usar um recurso ou API:** confira o 13 (está deprecated no 26.1?).

## Manutenção
- Ao atualizar o APEX, troque `VERSAO` em `scripts/busca-casos/apex_docs.py`, rode `baixar`, `extrair` e `indexar` e revise o 13 e os links `Fonte:`.
- Depois de editar qualquer documento desta pasta, rode `python3 scripts/busca-casos/casos.py indexar`.
- O texto oficial da Oracle **não** é versionado: fica no cache local (`.cache/`, no `.gitignore`) e no índice. Esta pasta contém só síntese própria, com links para a fonte.
