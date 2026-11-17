# Corlix Hub · Contexto para IAs

> **Ponto de entrada** para qualquer IA ou agente que for trabalhar neste repositório. Leia este arquivo inteiro e depois abra só os documentos relevantes para a tarefa.
> Gerado em 06/10/2026 a partir da inspeção do código (branch `DEV`, HEAD `bac2d69` + mudanças não commitadas). Versão visual: [`index.html`](./index.html).

## Resumo em 30 segundos

- **Produto:** intranet corporativa SaaS para PMEs. Reúne colaboradores, organograma, histórico de carreira, comunicados, chat, equipes e cadastro multiempresa. Projeto FIAP Enterprise Challenge 2026.
- **Stack:** Oracle APEX 26.1 (Universal Theme, visual Redwood Light) sobre Oracle Database 23ai e ORDS 25.4. Toda a lógica está em SQL/PL/SQL e nas definições declarativas do APEX. Não há Node/Java/Python.
- **App:** ID `100`, alias `CORLIXHUB`, workspace/schema `WKSP_CORLIXHUB`, autenticação por contas APEX, idioma da UI pt-BR (idioma primário técnico `en`).
- **Fonte da app:** `corlixhub/` em formato **APEXlang** (`.apx`), **somente leitura** para agentes (ver regra 1 abaixo). `database/f100.sql` é o mesmo app num export SQL de 12 MB: use só para consultar, nunca edite.
- **Banco:** o DDL das tabelas base (`COLABORADOR`, `CARGO`, `DEPARTAMENTO`, `EMPRESA`, `COMUNICADO`, `EQUIPE`, chat, logs…) está em `database/corlix-hub.sql`. É um snapshot só de estrutura, **sem dados**, e não serve como instalador. O módulo de histórico de carreira tem DDL próprio em `modulos/historico-carreira/`. Dados exportados ficam em `database/dados/` (hoje só `departamento.xlsx`: 6 departamentos da empresa 1).
- **Em andamento (13/11/2026):** Home (p1) e Novo comunicado (p17) concluídos; Holerite (p9) aplicado com o PDF pendente; Suporte TI (p34–43) criado e ainda sem menu e sem testes; isolamento por empresa (`modulos/isolamento-empresas`) e redesign do Dashboard RH (p20) e do Login (p9999) versionados e não aplicados. Telas-alvo em `pen_dev/`. Estado por página na tabela abaixo.

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
| 11 | [**Padrões de páginas**](./11-padroes-de-paginas.md) | **Leia antes de criar ou alterar qualquer página.** Qual página copiar, regras obrigatórias, checklist e como propor exceção |
| — | [**Fichas das páginas**](./paginas/README.md) | Uma ficha por página (estado, template, autorização, regiões, lógica, dados, pendências). **Leia a da página antes de mexer nela** |
| — | [**Regras e fluxos para agentes**](../agentes/README.md) | Conduta e fluxos de trabalho para qualquer agente (validar export, testar na app, escrever guia, ficha de página, dividir trabalho) |

### Guia por tipo de tarefa
- **Mexer numa página existente:** ficha da página (`paginas/`) → 11 → 08 → 02 (seção da página) → 03 (componentes que ela usa) → 04 (classes CSS).
- **Criar uma página ou tela do pen.dev:** 11 → 07 (tela) → 02 §1 (sintaxe) → 04 §8 (aplicar tema) → 08.
- **Mexer no banco ou criar tabela:** 05 → 06 §4 (padrão de módulo) → 08.
- **Integrar organograma ou histórico de carreira:** 06 → 05 → 02 (páginas 3/13).
- **Apareceu um erro (ORA-, PLS-, Access denied):** primeiro `python3 scripts/busca-casos/casos.py buscar "<mensagem ou sintoma>"` (busca de casos com Elasticsearch, cobre o 09, o 10 e as tabelas "Se não funcionar" dos módulos; ver 01 §8.2); depois 09.
- **Dúvida sobre um recurso ou API do APEX:** [`../apex-26.1/`](../apex-26.1/README.md) e `casos.py buscar "…" --fonte apex` (documentação oficial indexada).
- **Ambiente, deploy ou CI:** 01.
- **Erro 400 "Request Header Or Cookie Too Large" ou sessão do Builder caindo:** 10.

## Páginas (visão rápida)

Estado em 13/11/2026 (backup de DEV `84f8625`), com link para a **ficha de cada página** ([`paginas/`](./paginas/README.md)), que traz template, autorização, regiões, lógica, dados e pendências. Os guias ficam em `modulos/<pasta>/`.

| Nº | Página | Estado | Guia |
|---|---|---|---|
| 0 | [Global Page](./paginas/p00000-global-page.md) | Implementada: busca do header (`pkg_busca_ui`) e menu do usuário em popover. Sem registro de teste | `busca`, `tema/Etapas-header-e-menu.md` |
| 1 | [Início](./paginas/p00001-início.md) | **§8 concluído** (55/55, testes 1 a 8). Pendentes: Parabenizar, "Disponível agora" e conta sem colaborador | `home/Etapas-home.md` |
| 2 | [Meu Perfil](./paginas/p00002-meu-perfil.md) | Implementada e testada (privacidade e protótipo). "Salvar foto" sem ação | `perfil/` |
| 3 | [Organograma](./paginas/p00003-organograma.md) | Implementada com `pkg_organograma` e drawer; sem registro de isolamento por empresa | `organograma/Etapas-organograma.md` |
| 4 | [Chat](./paginas/p00004-chat.md) | Implementada com envio e polling de 1 s; sem guia no repositório; CSS inline | — |
| 5 | [Notificações](./paginas/p00005-notificacoes.md) | Placeholder (destino do sino) | — |
| 6 | [Configurações](./paginas/p00006-configuracoes.md) | Placeholder, sem autorização | — |
| 7 | [Monitor de Logs](./paginas/p00007-monitor-logs.md) | Implementada com `@admin-rh`; a troca para `EQUIPE_CORLIX_HUB` não foi aplicada | `isolamento-empresas/` §5 |
| 8 | [Notificações (vazia)](./paginas/p00008-notificações.md) | Vazia, duplicada da 5, sem referências | — |
| 9 | [Holerite Digital](./paginas/p00009-holerite-digital.md) | Redesign aplicado e testado (falta o teste 17); PDF "Aviso de crédito" não aplicado | `holerite/Etapas-holerite.md` |
| 11 | [Comunicados Oficiais](./paginas/p00011-comunicados-oficiais.md) | Placeholder; destino de "Ler comunicado" e "Ver todos" | — |
| 12 | [Colaboradores](./paginas/p00012-colaboradores.md) | Implementada e validada (09/11/2026) | `colaboradores/Etapas-colaboradores.md` |
| 13 | [Histórico de carreira](./paginas/p00013-historico-de-carreira.md) | Implementada e validada (19/10/2026) | `historico-carreira/` §2 |
| 14 | [Cadastro de Usuários](./paginas/p00014-cadastros-de-usuarios.md) | Criação e edição; edição validada; criar pelo RH falha (`CREATE_USER`) | `colaboradores/` |
| 15 | [Empresas Cadastradas](./paginas/p00015-empresas-cadastradas.md) | Implementada no visual do protótipo | `tema/Etapas-empresas.md` |
| 16 | [Cadastro de Empresas](./paginas/p00016-cadastro-de-empresas.md) | Modal com BrasilAPI e ViaCEP | `tema/Etapas-cadastro-empresa.md` |
| 17 | [Novo comunicado](./paginas/p00017-comunicado.md) | **Concluída** (48/48, testes da §5). Sem autorização própria na página | `comunicados/Etapas-comunicados.md` |
| 18 | [Movimentação](./paginas/p00018-movimentacao.md) | Implementada e validada; falta o filtro por empresa do isolamento | `historico-carreira/` §3 |
| 19 | [Formações e certificações](./paginas/p00019-formacoes-e-certificacoes.md) | Implementada e validada | `historico-carreira/` §4 |
| 20 | [Dashboard RH](./paginas/p00020-dashboard-rh.md) | Versão antiga validada; redesign não aplicado | `dashboard-rh/Etapas-dashboard-rh.md` |
| 21 | [Formação](./paginas/p00021-formacao.md) | Implementada e validada; falta o filtro por empresa do isolamento | `historico-carreira/` §4.5 |
| 22 | [Solicitar correção](./paginas/p00022-solicitar-correcao.md) | Implementada e validada | `historico-carreira/` §6 |
| 23 | [Responder solicitação](./paginas/p00023-responder-solicitacao.md) | Implementada e validada | `historico-carreira/` §5.5 |
| 26 | [Central de Equipes](./paginas/p00026-central-de-equipes.md) | Versão do assistente, **sem autorização e sem filtro por empresa** | `isolamento-empresas/` §3 e §4.1 |
| 27 | [Nova Equipe](./paginas/p00027-nova-equipe.md) | Modal do assistente, **sem autorização e sem filtro por empresa** | `isolamento-empresas/` §3 e §4.2 |
| 29 | [Busca](./paginas/p00029-busca.md) | Montada conforme o guia; sem registro de teste | `busca/Etapas-busca.md` |
| 30 | [Ponto eletrônico](./paginas/p00030-ponto-eletronico.md) | Implementada e validada (03/11/2026); carrega `ponto.css` sem `#MIN#` | `ponto-eletronico/` |
| 31 | [Solicitar ajuste](./paginas/p00031-solicitar-ajuste.md) | Implementada e validada | `ponto-eletronico/` §5 |
| 32 | [Ajustes de ponto](./paginas/p00032-ajustes-de-ponto.md) | Implementada e validada | `ponto-eletronico/` §7 |
| 33 | [Responder ajuste](./paginas/p00033-responder-ajuste.md) | Implementada e validada | `ponto-eletronico/` §6 |
| 34 | [Suporte TI](./paginas/p00034-suporte-ti.md) | Criada; fora do menu; sem registro de testes | `suporte-ti/Etapas-suporte-ti.md` §4 |
| 35 | [Abrir chamado](./paginas/p00035-abrir-chamado.md) | Criada conforme o guia; sem registro de testes | `suporte-ti/` §5 |
| 36 | [Chamado](./paginas/p00036-chamado.md) | Criada; botões fora do guia; sem registro de testes | `suporte-ti/` §6 |
| 37 | [Base de conhecimento](./paginas/p00037-base-conhecimento.md) | Criada; cabeçalho no slot `body`; sem registro de testes | `suporte-ti/` §7 |
| 38 | [Atendimento TI](./paginas/p00038-atendimento-ti.md) | Criada; fora do menu; sem registro de testes | `suporte-ti/` §9 |
| 39 | [Atender chamado](./paginas/p00039-atender-chamado.md) | Criada sem as condições do guia; sem registro de testes | `suporte-ti/` §8 |
| 40 | [Status dos sistemas](./paginas/p00040-status-dos-sistemas.md) | Criada pelo assistente com os ajustes do §10.2; textos em inglês | `suporte-ti/` §10 |
| 41 | [Sistema](./paginas/p00041-sistema.md) | Criada pelo assistente com os ajustes do §10.3 | `suporte-ti/` §10.3 |
| 42 | [Artigos](./paginas/p00042-artigos.md) | §11.2 concluído no export em 13/11/2026 (16/16, filtra por empresa); sem teste na app | `suporte-ti/` §11 |
| 43 | [Artigo](./paginas/p00043-artigo.md) | Só o assistente; **empresa escolhível** e campos de controle obrigatórios | `suporte-ti/` §11.3 |
| 44 | [Foto](./paginas/p00044-foto.md) | Em uso (entrega as fotos do bucket), validada em 09/11/2026 | `arquivos/Etapas-fotos-object-storage.md` |
| 9999 | [Login](./paginas/p09999-login.md) | Login padrão do APEX, em inglês; redesign proposto, não aplicado | `login/Etapas-login.md` |

Pontos de atenção encontrados ao montar as fichas (isolamento por empresa, autorização, menu do Suporte TI): [`paginas/README.md`](./paginas/README.md#pontos-de-atenção-achados-na-criação-das-fichas).

## Regras de ouro (resumo do 08)
1. **Proibido modificar** `corlixhub/`, `backups/`, `pen_dev/` e `scripts/`: são só leitura; a app muda pelo Builder e o agente escreve guias e docs. Nunca edite `database/f100.sql`.
2. Use pt-BR em tudo e Conventional Commits. Toda alteração vai numa branch `feature/<assunto>` (funcionalidade nova) ou `fix/<assunto>` (as demais), com PR para `DEV` e depois `DEV` → `PROD` (ver 08 §1, regra 13).
3. Toda query de negócio deve filtrar por `id_empresa`, e toda página administrativa precisa de `authorizationScheme` na própria página.
4. Gere links com checksum (`apex_page.get_url`).
5. Quando o time alterar um `.css`, o `.min.css` muda junto e arquivos novos entram em `static-files.apx` (o agente indica isso no guia; não edita `corlixhub/`).
6. Se o README raiz divergir do código, confie no código. O que não estiver confirmado, pergunte ao time (ex.: o ambiente atual, já que `docker-compose.yml` foi apagado, e os dados reais do banco).
7. Ao mudar páginas, schema, tema ou módulos, **atualize o documento correspondente nesta pasta**.
8. Passo a passo do Builder sempre para o **APEX 26.1.5**: caminho não conferido vai marcado "(confirmar no 26.1.5)"; se não existir, peça print em vez de chutar (ver 08 §1, regra 11).
9. **Todo protótipo está em `pen_dev/`** (PNGs das telas-alvo do pen.dev, descritas no 07). Procure lá primeiro; se a tela não existir, pergunte (ver 08 §1, regra 12).

10. Antes de criar ou alterar páginas, siga o [11 · Padrões de páginas](./11-padroes-de-paginas.md) e registre as referências. Sair do padrão exige evidência para o 26.1.5 e aprovação do time (08 §1, regra 14).

11. Ao encerrar cada tarefa ou módulo, documente resultados, evidências e pendências em registro versionado (08 §1, regra 15); a resposta final não substitui esse registro.
