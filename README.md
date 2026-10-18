# Corlix Hub

**Core logic, smart solutions.**

Intranet corporativa SaaS para pequenas e médias empresas (10 a 250 colaboradores). Reúne em um só lugar o organograma, o histórico de carreira, os comunicados oficiais e o chat interno, com a estrutura da empresa sempre atualizada a partir do cadastro de colaboradores.

Projeto do **Enterprise Challenge (StartupOne) — FIAP, turma 4ESOA, 2026**. Construído em **Oracle APEX 26.1.5** sobre o **Oracle Autonomous AI Database**, na Oracle Cloud (região São Paulo).

---

## Experimente

| | |
|---|---|
| Aplicação no ar | https://gfe80286062641f-corlixhub.adb.sa-saopaulo-1.oraclecloudapps.com/ords/r/corlixhub/corlixhub/home |
| Layout das telas (pen.dev, só leitura) | https://app.pen.dev/s/PlssXzG4SKpa2Q1RWgBkUFb4TudN1CYP2en5pN3D-ME |

Contas de teste, todas com dados fictícios e a senha `CorlixHub2026@`:

| Usuário | Pessoa | Perfil |
|---|---|---|
| `RAFAELNUNES` | Rafael Nunes, analista de operações | Colaborador |
| `ANASOUZA` | Ana Beatriz Souza, gerente de operações | Publicadora de conteúdo e gestora |
| `FERNANDALIMA` | Fernanda Lima | Administração de RH |
| `AMANDANUNES` | Amanda Nunes, CEO | Diretoria |

> A instância usa o plano gratuito da Oracle Cloud e pode levar alguns segundos para responder no primeiro acesso.

---

## O problema

PMEs em crescimento enfrentam três problemas recorrentes:

1. **Estrutura desorganizada.** O organograma vive em um PDF desatualizado, e ninguém sabe a quem recorrer.
2. **Carreira sem registro.** Promoções e mudanças de cargo ficam em planilhas ou na memória do RH, o que gera risco trabalhista e desmotivação.
3. **Comunicação fragmentada.** Avisos oficiais se perdem entre WhatsApp, e-mail e grupos informais, sem saber quem leu.

Plataformas como SAP SuccessFactors, Workday e Oracle HCM resolvem isso, mas custam acima de R$ 100 por usuário por mês e foram desenhadas para empresas com milhares de pessoas.

## A solução

| Módulo | O que faz |
|---|---|
| Organograma | Hierarquia calculada a partir do cadastro (cada pessoa aponta para o seu gestor), com navegação nível a nível e detalhes de cada pessoa |
| Histórico de carreira | Linha do tempo de admissões, promoções, transferências e mudanças de gestão. O RH registra e efetiva a movimentação, o cadastro é atualizado, e o lançamento efetivado não muda mais (correção por estorno, com auditoria) |
| Comunicados | Mural oficial por empresa ou departamento, com confirmação e taxa de leitura |
| Chat interno | Conversas por departamento com indicador de presença |
| Dashboard RH | Promoções por departamento e indicadores do período |
| Cadastros | Empresas, departamentos, cargos e colaboradores, com seis papéis de acesso atribuídos conforme o cargo |

---

## Status (outubro de 2026)

| Item | Situação |
|---|---|
| Página inicial, cadastros de empresas e colaboradores, emissão de comunicados | No ar |
| Organograma por níveis (testado com 292 colaboradores fictícios) | No ar |
| Histórico de carreira, formações e certificações, Dashboard RH | Em desenvolvimento |
| Chat interno | Em desenvolvimento |
| Seis papéis de acesso (ACL do APEX) | Criados; aplicação por página até a entrega |
| Log de erros da aplicação (`APP_LOG`, error handler do APEX) | No ar |

A meta é o MVP completo até o início de novembro de 2026 (ver [Roadmap](#roadmap)).

---

## Como funciona

- **Uma aplicação APEX e um schema por empresa cliente**, gerados a partir de um template. Os dados de cada cliente ficam isolados.
- **Regras de negócio no banco, em PL/SQL.** As páginas só chamam os packages:
  - `PKG_ORGANOGRAMA` monta a árvore com `CONNECT BY` e renderiza o organograma;
  - `PKG_HISTORICO_CARREIRA` registra, efetiva e estorna movimentações;
  - `PKG_COMUNICADO` publica e mede a leitura;
  - `PKG_PERFIS_ACESSO` atribui os papéis conforme o cargo.
- **ORDS** serve as páginas e, no roadmap, a API REST (`/v1/organograma`, `/v1/colaboradores/:id`, `/v1/comunicados`, com OAuth2) para app mobile e integrações.
- **Oracle Cloud, região São Paulo:** os dados ficam no Brasil.

---

## Stack

| Camada | Tecnologia |
|---|---|
| Aplicação e interface | Oracle APEX 26.1.5, Universal Theme com tema próprio sobre o Redwood Light |
| Banco | Oracle Autonomous AI Database (Oracle Database 23ai), schema `WKSP_CORLIXHUB` |
| Servidor HTTP e API | Oracle REST Data Services (ORDS) |
| Lógica | SQL e PL/SQL (packages, views, triggers). Não há backend fora do banco |
| Front-end próprio | CSS do tema (`corlix-tema.css`, `custom.css`) e JavaScript do APEX, sem bundler |
| Versionamento e backup | Git, SQLcl e Jenkins |

---

## Estrutura do repositório

```
corlix-hub/
├── corlixhub/             # Código-fonte da aplicação APEX em APEXlang (.apx): fonte principal
│   ├── application.apx    #   definição global (autenticação, menu, CSS, error handler)
│   ├── pages/             #   uma página por arquivo
│   └── shared-components/ #   papéis, autorizações, listas, LOVs, tema e arquivos estáticos
├── database/
│   ├── f100.sql           # Export da aplicação 100 em arquivo único (gerado; não editar à mão)
│   └── ddl/               # Estrutura do schema exportada pelo backup diário (um arquivo por tipo)
├── modulos/               # Módulos desenvolvidos fora do Builder
│   ├── organograma/       #   VW_ORG_COLABORADOR e PKG_ORGANOGRAMA
│   └── historico-carreira/#   tabelas, packages, auditoria, testes e guia de instalação
├── docs/ai-context/       # Contexto técnico do projeto para agentes de IA
├── scripts/
│   ├── backup/            # Pipeline de backup (SQLcl + Jenkins) e restauração
│   └── git-hooks/         # Validação de Conventional Commits
└── .github/workflows/     # CI
```

---

## Qualidade e segurança

- **Pull request em tudo:** nenhum commit direto em `DEV`, `UAT` ou `PROD`.
- **Conventional Commits**, validados pelo hook em `scripts/git-hooks/commit-msg`.
- **CI no GitHub Actions** em cada PR para `DEV`, `UAT` e `PROD`:
  - varredura de segredos com gitleaks;
  - bloqueio de arquivos que não podem ir para o Git (distribuição do APEX, datafiles, configuração do ORDS).
- **Testes automatizados no banco:** `modulos/historico-carreira/07_testes.sql` cria duas empresas fictícias, roda um teste por regra e prova o isolamento entre elas. Termina em rollback.
- **Backup diário:**
  - um job Jenkins exporta a aplicação, o DDL e os dados do Autonomous Database;
  - aplicação e DDL são publicados na `DEV`, com PR para a `PROD`;
  - os dados ficam fora do Git.
- **Dados fictícios:** a base de teste (292 colaboradores com e-mails `@corlixhub.com`) é fictícia. Nenhuma senha ou wallet é versionada.

### Desenvolvimento assistido por IA

A equipe usa agentes de IA para acelerar a escrita de SQL, PL/SQL e páginas. Antes de qualquer tarefa, os agentes leem `AGENTS.md` e a pasta `docs/ai-context/`, que descreve arquitetura, páginas, banco, tema, módulos, convenções e erros já resolvidos.

Tudo o que a IA gera passa por QA da equipe antes de entrar por pull request. Cada erro encontrado é corrigido e registrado na base de contexto, para não se repetir.

---

## Fluxo de trabalho

1. Crie a branch a partir da `DEV`: `feature/<nome>` ou `bugfix/<nome>`.
2. Ative o hook de commits uma vez por clone: `git config core.hooksPath scripts/git-hooks`.
3. Commite no padrão `tipo(escopo): descrição`, por exemplo `feat(organograma): adiciona busca no topo`.
4. Abra o PR para a `DEV`. Depois da validação, ele segue `DEV` → `UAT` → `PROD`.

Hotfix crítico sai de `PROD` (`hotfix/<nome>`) e depois é replicado para `UAT` e `DEV`.

## Instalação em outro workspace

O desenvolvimento acontece no APEX do Autonomous Database da OCI. Para instalar a aplicação em outro workspace APEX 26.1:

1. Crie a estrutura do schema. O passo a passo de restauração está em [`scripts/backup/README.md`](scripts/backup/README.md).
2. Instale os módulos:
   - organograma: `modulos/organograma/organograma.sql`;
   - histórico de carreira: `modulos/historico-carreira/instalar.sql`.
3. Importe a aplicação pelo SQLcl, conectado como dono do schema: `@database/f100.sql`. Também dá para importar pelo App Builder.

---

## Roadmap

Até o início de novembro de 2026:

| Sprint | Entregas |
|---|---|
| 1 · 13 a 19/10 | Organograma fechado (busca no topo, perfil organizacional, bloqueio de ciclo), medição do consumo do chat, correção do layout instável (CLS) e teste de usabilidade |
| 2 · 20 a 26/10 | Histórico de carreira concluído (formações, PDF, Dashboard RH), chat por departamento com presença, fotos no Object Storage |
| 3 · 27/10 a 02/11 | LGPD com os seis papéis por página e visibilidade por campo, design alinhado ao pen.dev, comunicados com público e categoria |
| 4 · 03 a 06/11 | QA, desempenho acima de 90 e acessibilidade 100 no Lighthouse, polimento e entrega |

Depois do MVP: piloto com uma empresa real. Em seguida, app mobile, PDI, feedbacks, avaliação 360 e integração com a folha.

---

## Equipe

| Nome | RM | Frente |
|---|---|---|
| Sarah Ribeiro da Silva (tech lead) | 97747 | Histórico de carreira |
| Alairton Rocha Scabelli | 551454 | Organograma |
| Eduardo Marins | 551892 | Chat interno |
| Leonardo Nicastro Mansur Castillo | 551659 | Comunicados internos |
| Mateus Iago Sousa Conceição | 550270 | Marketing |

Desempenho, acessibilidade e LGPD ficam com cada responsável, nas páginas da própria frente. O QA é cruzado: cada integrante testa a frente de outro.

---

## Documentação

- [`docs/ai-context/`](docs/ai-context/): arquitetura, páginas, banco, tema, módulos, convenções e erros conhecidos
- [`modulos/historico-carreira/README-historico-carreira.md`](modulos/historico-carreira/README-historico-carreira.md): regras e modelo de dados do histórico de carreira
- [`scripts/backup/README.md`](scripts/backup/README.md): backup, publicação no Git e restauração

## Uso

Projeto acadêmico desenvolvido para a FIAP. Todos os direitos reservados aos autores.
