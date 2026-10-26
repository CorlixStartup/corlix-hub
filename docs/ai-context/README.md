# Corlix Hub · Contexto para IAs

> **Ponto de entrada** para qualquer IA ou agente que for trabalhar neste repositório. Leia este arquivo inteiro e depois abra só os documentos relevantes para a tarefa.
> Gerado em 06/10/2026 a partir da inspeção do código (branch `DEV`, HEAD `bac2d69` + mudanças não commitadas). Versão visual: [`index.html`](./index.html).

## Resumo em 30 segundos

- **Produto:** intranet corporativa SaaS para PMEs. Reúne colaboradores, organograma, histórico de carreira, comunicados, chat, equipes e cadastro multiempresa. Projeto FIAP Enterprise Challenge 2026.
- **Stack:** Oracle APEX 26.1 (Universal Theme, visual Redwood Light) sobre Oracle Database 23ai e ORDS 25.4. Toda a lógica está em SQL/PL/SQL e nas definições declarativas do APEX. Não há Node/Java/Python.
- **App:** ID `100`, alias `CORLIXHUB`, workspace/schema `WKSP_CORLIXHUB`, autenticação por contas APEX, idioma da UI pt-BR (idioma primário técnico `en`).
- **Fonte da app:** `corlixhub/` em formato **APEXlang** (`.apx`). `database/f100.sql` é o mesmo app num export SQL de 12 MB: use só para consultar, nunca edite.
- **Banco:** o DDL das tabelas base (`COLABORADOR`, `CARGO`, `DEPARTAMENTO`, `EMPRESA`, `COMUNICADO`, `EQUIPE`, chat, logs…) está em `database/corlix-hub.sql`. É um snapshot só de estrutura, **sem dados**, e não serve como instalador. O módulo de histórico de carreira tem DDL próprio em `modulos/historico-carreira/`. Dados exportados ficam em `database/dados/` (hoje só `departamento.xlsx`: 6 departamentos da empresa 1).
- **Em andamento:** redesign visual (tokens `--cx-*` em `corlix-tema.css`), módulo de Organograma (`modulos/organograma`, página 3), Histórico de carreira integrado nas páginas 13 e 18–23 (guia `modulos/historico-carreira/Etapas-historico-carreira.md`), redesign da Home numa página nova, a 28, sem apagar a 1 (`modulos/home`, guia `Etapas-home.md`, branch `feature/redesign-home`) e ~28 telas-alvo em `pen_dev/`.

## Documentos

| # | Documento | Quando ler |
|---|---|---|
| 01 | [Arquitetura e ambiente](./01-arquitetura-e-ambiente.md) | Stack, mapa de pastas, Docker, CI, branches/commits, divergências README × código |
| 02 | [Páginas](./02-paginas.md) | Sintaxe APEXlang + cada página (regiões, itens, processos, DAs, SQL), mapa de navegação |
| 03 | [Componentes compartilhados](./03-componentes-compartilhados.md) | `application.apx`, roles/authorizations, app items/processes, menu, breadcrumbs, LOVs, templates do tema, static files |
| 04 | [Tema e estilos](./04-tema-e-estilos.md) | Tokens `--cx-*`, mapeamento Universal Theme, catálogo de classes CSS, como aplicar o tema numa página |
| 05 | [Banco de dados](./05-banco-de-dados.md) | Diagrama ER, tabelas (DDL e inferidas), views, triggers, packages, códigos de erro, testes |
| 06 | [Módulos](./06-modulos.md) | Organograma e Histórico de carreira: arquitetura, integração no APEX, API JS, template de novo módulo |
| 07 | [Design (pen.dev)](./07-design-pen-dev.md) | Descrição detalhada de cada tela-alvo e mapeamento para componentes APEX; features sem backend |
| 08 | [Convenções e pegadinhas](./08-convencoes-e-pegadinhas.md) | **Leia antes de editar qualquer coisa.** Regras de trabalho, lacunas, bugs conhecidos, checklist |
| 09 | [Erros e soluções](./09-erros-e-solucoes.md) | Erros de SQL, PL/SQL e APEX já vistos: como ler a mensagem, causa, correção, prevenção e checklist |
| — | [**Base Oracle APEX 26.1**](../apex-26.1/README.md) | Referência do APEX tirada da documentação oficial (conceitos, páginas, relatórios, segurança, APIs PL/SQL/JS, APEXlang, workflows, REST, admin, novidades). Use para dúvidas sobre o APEX em si |
| 10 | [Cookies e sessão (OCI)](./10-erro-400-cookies.md) | `400 Request Header Or Cookie Too Large` e sessão do Builder caindo/pedindo workspace: causa, diagnóstico, correção |

### Guia por tipo de tarefa
- **Mexer numa página existente:** 08 → 02 (seção da página) → 03 (componentes que ela usa) → 04 (classes CSS).
- **Criar uma página ou tela do pen.dev:** 07 (tela) → 02 §1 (sintaxe) → 04 §8 (aplicar tema) → 08.
- **Mexer no banco ou criar tabela:** 05 → 06 §4 (padrão de módulo) → 08.
- **Integrar organograma ou histórico de carreira:** 06 → 05 → 02 (páginas 3/13).
- **Apareceu um erro (ORA-, PLS-, Access denied):** primeiro `python3 scripts/busca-casos/casos.py buscar "<mensagem ou sintoma>"` (busca de casos com Elasticsearch, cobre o 09, o 10 e as tabelas "Se não funcionar" dos módulos; ver 01 §8.2); depois 09.
- **Dúvida sobre um recurso ou API do APEX:** [`../apex-26.1/`](../apex-26.1/README.md) e `casos.py buscar "…" --fonte apex` (documentação oficial indexada).
- **Ambiente, deploy ou CI:** 01.
- **Erro 400 "Request Header Or Cookie Too Large" ou sessão do Builder caindo:** 10.

## Páginas (visão rápida)

| Nº | Página | Status |
|---|---|---|
| 0 | Global Page (header: busca, sino, config, usuário) | Implementada |
| 1 | Home (dashboard) | Implementada; mantida durante o redesign |
| 2 | Meu Perfil | Placeholder |
| 3 | Organograma | Placeholder; o módulo existe em `modulos/organograma` |
| 4 | Chat | Parcial (leitura, sem envio) |
| 5 / 8 | Notificações (duplicadas) | Placeholder / vazia |
| 6 | Configurações | Placeholder |
| 7 | Monitor de Logs | Implementada (sem authorization!) |
| 11 | Comunicados Oficiais | Placeholder |
| 12 | Colaboradores | Placeholder |
| 13 | Histórico de carreira | Implementada (módulo `modulos/historico-carreira`, §2 do guia) |
| 14 | Cadastro de Usuários (cria usuário APEX e a admissão no histórico) | Implementada (`ADMIN_RH`) |
| 18 | Movimentação (modal do histórico de carreira) | Implementada (§3 do guia) |
| 19 / 21 | Formações e certificações (lista) / Formação (modal) | Implementadas (§4 do guia) |
| 20 | Dashboard RH | Implementada (§5 do guia) |
| 22 | Solicitar correção (modal do colaborador) | Implementada (§6 do guia) |
| 23 | Responder solicitação de correção (modal do Dashboard RH) | Implementada (§5.5 do guia) |
| 15 / 16 | Empresas (lista / modal de cadastro com ViaCEP) | Implementada |
| 17 | Emitir Comunicado (modal wizard) | Implementada, com bugs |
| 26 / 27 | Central de Equipes / Nova Equipe (modal) | Implementada |
| 28 | Início (nova Home) | Em montagem pelo `modulos/home/Etapas-home.md`; vira a Home no §5 do guia |
| 29 | Busca (resultados da busca do header) | Em montagem pelo `modulos/busca/Etapas-busca.md` |
| 9999 | Login | Implementada |

## Regras de ouro (resumo do 08)
1. Edite `corlixhub/**/*.apx`; nunca edite `database/f100.sql`.
2. Use pt-BR em tudo e Conventional Commits; abra PRs para `DEV`.
3. Toda query de negócio deve filtrar por `id_empresa`, e toda página administrativa precisa de `authorizationScheme` na própria página.
4. Gere links com checksum (`apex_page.get_url`).
5. Ao alterar um `.css`, altere também o `.min.css` e registre arquivos novos em `static-files.apx`.
6. Se o README raiz divergir do código, confie no código. O que não estiver confirmado, pergunte ao time (ex.: o ambiente atual, já que `docker-compose.yml` foi apagado, e os dados reais do banco).
7. Ao mudar páginas, schema, tema ou módulos, **atualize o documento correspondente nesta pasta**.
8. Passo a passo do Builder sempre para o **APEX 26.1.5**: caminho não conferido vai marcado "(confirmar no 26.1.5)"; se não existir, peça print em vez de chutar (ver 08 §1, regra 11).
