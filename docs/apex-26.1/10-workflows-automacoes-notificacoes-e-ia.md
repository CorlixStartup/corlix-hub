# 10 · Workflows, tarefas, automações, execução em background, notificações e IA

> Base: documentação oficial Oracle APEX 26.1 (Developer's Companion: "Automating Business Processes", "Grouping Logic and Background Execution", "Executing Repetitive Processing", "Notifying End Users" (e-mail e push), "Applying Artificial Intelligence", "Enhancing Search for End-Users" (só Search Configurations / Search region / `APEX_SEARCH`); App Builder User's Guide: "Managing Workflows and Tasks", "Managing Automations", "Sending Email from an Application", "Managing Email Templates", "Understanding Background Page Processing", "Creating a Progressive Web App", "Managing Generative AI in APEX", "Managing AI Agents and AI Tools", "Managing Vector Providers", "Adding Search to an Application"; API Reference: `APEX_WORKFLOW`, `APEX_HUMAN_TASK`, `APEX_BACKGROUND_PROCESS`, `APEX_AUTOMATION`, `APEX_MAIL`, `APEX_PWA`, `APEX_AI`, `APEX_SEARCH`; JavaScript API: `apex.pwa`; Administration Guide: "Configuring Email", "Configuring Background Jobs", "Configuring Workflow Settings", "DBMS_SCHEDULER Jobs", "Managing Meta Data"; APEXlang API Reference: `automation`, `workflow`, `taskDefinition`, `emailTemplate`, `searchConfig`, `aiAgent`, `vectorProvider`). Gerado em 21/10/2026.

**Sumário**

1. Visão geral: qual recurso usar, pré-requisitos (`CREATE JOB`), jobs `ORACLE_APEX_*` do `DBMS_SCHEDULER`, contexto de execução em background
2. Workflows: conceitos (versões, parâmetros, variáveis, Additional Data, participantes, runtime engine)
3. Workflow Designer e atividades (Start/End, Switch, Wait, Human Task, Invoke Workflow, Parallel Flow, Invoke API, e-mail, push, IA, plug-ins) e conexões
4. Operação de workflows: page process Workflow, `APEX_WORKFLOW`, `CONTINUE_ACTIVITY`, Workflow Console/Details/Dashboard, estados, views, debug, retenção, deploy
5. Human tasks: Task Definitions (aprovação × ação), participantes, vacation rules, prazos/expiração, actions e eventos, Unified Task List, Task Details, `APEX_HUMAN_TASK`, estados, purge
6. Execution Chains e Run in Background (`APEX_BACKGROUND_PROCESS`, progresso, serialização, limites)
7. Automations (agendamento, query, ações, logs, `APEX_AUTOMATION`, import)
8. E-mail (configuração, fila, Email Templates, Send E-Mail, `APEX_MAIL`)
9. PWA e push notifications (`APEX_PWA`, `apex.pwa`)
10. IA generativa (Generative AI Services, atributos de IA da app, AI Agents e AI Tools, Show AI Assistant, Generate Text with AI, `APEX_AI`, Vector Providers)
11. Search Configurations, Search region e `APEX_SEARCH`
12. Problemas conhecidos (formato de caso)
13. Aplicação no Corlix Hub

---

## 1. Visão geral e pré-requisitos

### Qual recurso usar: workflow, task, execution chain, automation ou job

O APEX 26.1 oferece vários mecanismos para lógica que não termina dentro de um request de página. A escolha certa depende de quem dispara, de quanto tempo dura e de quem precisa acompanhar.

| Necessidade | Recurso | Observações |
|---|---|---|
| Processo de negócio com vários passos, decisões, espera por pessoas ou eventos, visível num diagrama | **Workflow** (Shared Components > Workflows and Automations > Workflows) | Roda em background, pode durar dias; tem versões, console e diagrama de progresso. |
| Item de trabalho para uma pessoa aprovar/rejeitar ou concluir, com caixa de entrada, prazo, delegação e histórico | **Task Definition** (human task: Approval Task ou Action Task) | Criada por page process `Human Task - Create`, por atividade de workflow ou por `APEX_HUMAN_TASK.CREATE_TASK`. |
| Tirar do request da página um processamento longo (carga de dados, PDF, IA, e-mail) disparado pelo usuário | **Execution Chain** com **Run in Background** | Clona o session state do usuário para uma sessão privada; permite progresso e serialização. |
| Rotina recorrente (agendada) ou sob demanda, opcionalmente uma vez por linha de uma query | **Automation** | Agendada com sintaxe de calendário do `DBMS_SCHEDULER`; tem log próprio. |
| Avisar usuário | **Send E-Mail** / **Send Push Notification** (process, atividade, task action, automation action) ou `APEX_MAIL` / `APEX_PWA` | E-mail e push são enfileirados e enviados por jobs. |
| Texto gerado, chatbot, agente com ferramentas | **Generative AI Service** + **AI Agent** + `Show AI Assistant` / `Generate Text with AI` / `APEX_AI` | Requer serviço configurado no workspace e atributo de IA na app. |

Regra prática da doc: quando um workflow precisa de entrada do usuário, prefira criar uma human task (inbox, lembretes, prazos, histórico) em vez de só mandar e-mail com link e esperar; a variante "e-mail + Wait + `CONTINUE_ACTIVITY`" é válida, mas o processo pode travar se a mensagem se perder.

Fonte: [Automating a Process with Workflow](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/automating-process-workflow.html), [Evaluating Benefits of Using Tasks Instead](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/evaluating-benefits-using-tasks-instead.html), [Grouping Logic and Background Execution](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/grouping-logic-and-background-execution.html), [Understanding Key Automation Concepts](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-key-automation-concepts.html)

### Pré-requisito comum: privilégio CREATE JOB no parsing schema

Workflows, human tasks, automations agendadas e execuções em background são executados pelo `DBMS_SCHEDULER`. Por isso o **parsing schema da aplicação precisa ter o privilégio `CREATE JOB`**. Sem ele, automations agendadas não rodam e workflows/tasks/background não funcionam. Os pacotes `APEX_WORKFLOW`, `APEX_HUMAN_TASK` e `APEX_AI` também exigem **sessão APEX válida** (em SQL Workshop ou job, crie uma com `APEX_SESSION.CREATE_SESSION`).

```sql
-- executar como DBA (exemplo)
grant create job to WKSP_CORLIXHUB;
```

Fonte: [About Workflows](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-workflows.html), [About Automations](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-automations.html), [Understanding Background Page Processing](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-background-page-processing.html), [APEX_WORKFLOW](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WORKFLOW.html)

### Jobs DBMS_SCHEDULER criados pelo APEX (ORACLE_APEX_*) e suas cadências

A instalação do APEX cria jobs que fazem o trabalho assíncrono. Conhecer as cadências explica "atrasos" aparentes (um e-mail ou uma expiração de task não acontece no instante).

| Job | O que faz | Cadência |
|---|---|---|
| `ORACLE_APEX_AUTOMATIONS` | Executa automations vencidas | a cada 2 min |
| `ORACLE_APEX_BG_PROCESSES` | Dispara execuções de background page processes (execution chains) | a cada 2 min (roda ~1min57s) |
| `ORACLE_APEX_MAIL_QUEUE` | Envia a fila de e-mail | a cada 5 min |
| `ORACLE_APEX_PWA_PUSH_QUEUE` | Envia push notifications | a cada 2 min |
| `ORACLE_APEX_TASKS_EXPIRE` | Expira/renova tasks vencidas, executa ações Before Expire/Expire | de hora em hora |
| `ORACLE_APEX_TASKS_PURGE` | Purga tasks concluídas fora da retenção; purga errored/expired/canceled; salva JSON | diário, 02:00 |
| `ORACLE_APEX_WFS_PURGE` | Purga workflows concluídos fora da retenção e os terminados | diário, 03:00 |
| `ORACLE_APEX_WF_TIMEOUT` | Trata timeouts de atividades de workflow cujo prazo venceu | a cada 5 min |
| `ORACLE_APEX_REST_SOURCE_SYNC` | Sincronizações de REST Data Source | a cada 10 min |
| `ORACLE_APEX_WS_NOTIFICATIONS` | Assinaturas de Interactive Report | a cada 30 min |
| `ORACLE_APEX_PURGE_SESSIONS` | Purga sessões antigas (padrão 12 h) | de hora em hora |
| `ORACLE_APEX_BACKUP`, `ORACLE_APEX_DAILY_*`, `ORACLE_APEX_DICTIONARY_CACHE`, `ORACLE_APEX_ISSUE_EMAILS`, `ORACLE_APEX_DTLD${id}` | Backups, métricas, cache de dicionário, Team Development, cargas do Data Workshop | diversos |

Uma automation agendada roda "alguns minutos depois" do Next Execution Due exibido, porque depende do coordenador `ORACLE_APEX_AUTOMATIONS`. O instance admin define a **Background Job Class** (job class do `DBMS_SCHEDULER` para automations, REST sync e notificações de relatório; padrão `SYS.DEFAULT_JOB_CLASS`) e o **Minimum Execution Cadence (Minutes)** de automations e REST sync em *Manage Instance > Instance Settings > Background Jobs*.

Fonte: [DBMS_SCHEDULER Jobs](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/dbms_scheduler-jobs.html), [Configuring Background Jobs](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-background-jobs.html), [About Automations](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-automations.html)

### Contexto de execução em background: APP_USER = nobody e session state

Os mecanismos assíncronos **não** rodam na sessão do usuário que os disparou, e isso muda o que o código pode ler:

| Mecanismo | Sessão | `APP_USER` | Session state da página |
|---|---|---|---|
| Workflow (cada atividade) | sessão do engine, sem usuário logado | `nobody` | **não** tem acesso |
| Automation agendada (ou `EXECUTE` com `p_run_in_background => true`) | sessão privada de background | `nobody` | não tem; app items servem como armazenamento temporário |
| Automation via `APEX_AUTOMATION.EXECUTE` sem background | sessão atual | usuário atual | sessão atual |
| Execution chain em background | nova sessão com **cópia** (clone) do session state no momento do enfileiramento | o usuário que disparou (a doc usa `APP_USER` em notificações) | cópia privada; alterações não voltam para a sessão do usuário |

Em workflows, tudo de que uma atividade precisa deve vir de: substituições built-in (`APEX$WORKFLOW_INITIATOR`, `APEX$WORKFLOW_DETAIL_PK`…), colunas de Additional Data, tabelas, parâmetros do workflow, variáveis gravadas por atividades anteriores ou parâmetros atualizáveis de task (`APEX_HUMAN_TASK`). Para saber quem iniciou, use `APEX$WORKFLOW_INITIATOR` (ou `APEX$TASK_INITIATOR` numa task), nunca `:APP_USER`.

Fonte: [Understanding Background Execution](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-background-execution.html), [Understanding Key Automation Concepts](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-key-automation-concepts.html), [Isolating Background Session State](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/isolating-background-session-state.html), [Loading Data in the Background](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/loading-data-background.html)

---

## 2. Workflows: conceitos

### O que é um Workflow APEX e seus blocos de construção

Um **workflow** automatiza um processo de negócio em que documentos, informações ou tarefas passam de um participante a outro segundo regras. No APEX 26.1 ele é composto por:

- **Workflow Definition** (shared component): parâmetros, versões; cada versão tem atividades, conexões, variáveis e participantes.
- **Workflow Versions**: uma versão em desenvolvimento e uma ativa podem coexistir.
- **Workflow Designer**: editor visual (árvore + Diagram Builder + paleta de atividades + Property Editor).
- **Workflow Runtime Engine**: executa as instâncias em background.
- **Workflow Console / Workflow Details / Workflow Dashboard**: páginas geradas pelo Create Page Wizard para listar, inspecionar e administrar instâncias.
- **Page process `Workflow`** (Start, Terminate, Suspend, Resume, Retry) e pacote **`APEX_WORKFLOW`**.

Caminho: *Shared Components > Workflows and Automations > Workflows*. Um workflow pode ser copiado de outra app (*Copy from Other App*): versões, parâmetros, atividades, participantes, variáveis e shared components associados vão junto; workflows invocados também são copiados se não existirem.

Quando usar: processo com várias etapas e pessoas, decisões condicionais, espera por evento ou prazo, necessidade de visualizar "onde está" cada caso. Quando não usar: uma única aprovação (basta uma Task Definition) ou um processamento longo disparado pelo usuário sem passos humanos (execution chain em background).

Fonte: [About Workflows](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-workflows.html), [Creating a Workflow](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-a-workflow.html), [Copying a Workflow](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/copying-a-workflow.html)

### Workflow Versions: In Development, Active e Inactive

| Estado | Edição | Uso em runtime |
|---|---|---|
| **In Development** | Totalmente editável. Só **uma** versão pode estar em desenvolvimento por vez. | Só em sessão de desenvolvedor (app rodada a partir do App Builder). |
| **Active** | Parcialmente editável: adicionar activity variables, alterar condições de branches de Switch, adicionar participantes. Não dá para apagar participantes nem a versão. Não volta para In Development. | Usada para novas instâncias fora de sessão de desenvolvedor. Só uma ativa por vez. |
| **Inactive** | Pode ser apagada ou duplicada. Aparece riscada na árvore. | Não inicia novas instâncias; instâncias já em andamento **continuam** até o fim. |

Regras importantes:
- Ativar exige **participantes definidos** (pelo menos Workflow Owner; recomenda-se também Administrator). Se o workflow tem `Invoke Workflow`, os workflows invocados precisam ter versão **Active**.
- Ativar uma versão move a ativa atual para Inactive. Ative pelo menu de contexto (Activate) ou pelo botão ao lado de *State* no Property Editor, e **salve**.
- Com sessão de desenvolvedor aberta, o engine usa a versão In Development (se existir); para testar a ativa, rode em janela anônima. O page process só recebe a definição, não a versão.
- Fora de Development Mode, iniciar um workflow que só tem versão In Development dá o erro `Workflow <static_id> has no Active version`.
- Apagar uma versão apaga as instâncias dela. Não é possível apagar a In Development se ela for usada por `Invoke Workflow` de outro workflow, nem desativar a Active usada por Invoke Workflow sem haver uma In Development.
- Versão nova: *Create Version* no menu do workflow, ou *Duplicate* da Active (a cópia nasce In Development). O nome da versão é livre (`1.0`, `New`). Na versão se define também Additional Data e **Debug Level** (Info padrão, Warning, Error, Trace).
- Na versão em desenvolvimento a engine **não faz checagem de autorização** de participantes (o owner vê Suspend/Edit de variáveis); a checagem só vale na versão ativa.

Fonte: [About Workflow Versions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-workflow-versions.html), [Managing Workflow Versions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-workflow-versions.html), [Activating an In Development Workflow](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/activating-development-workflow.html), [Frequently Asked Questions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/workflow-faqs.html)

### Workflow Parameters: entradas In, Out e In/Out

Parâmetros são definidos **no workflow** (valem para todas as versões) e recebem valor quando a instância é iniciada. Criação: botão direito no workflow > *Create Parameter*.

| Atributo | Valores |
|---|---|
| Static ID | nome único; referência `:P_X` em código, `&P_X.` em textos, `P_X` em propriedades que pedem nome de item |
| Label | aparece na página Workflow Details |
| Data Type | `VARCHAR2`, `NUMBER`, `BOOLEAN`, `CLOB`, `TIMESTAMP`, `TIMESTAMP WITH TIME ZONE`, `TIMESTAMP WITH LOCAL TIME ZONE` |
| Direction | `In` (somente leitura), `Out`, `In/Out` |
| Value > Required, Default Value | se Required, o page process precisa atribuir valor (senão erro ao salvar a página) |
| Session State Format Mask / Application Format Masks | para alguns tipos |

Pegadinhas: parâmetros `Out`/`In/Out` só podem ser ligados a itens do workflow (variáveis/parâmetros) e só têm efeito quando o workflow é chamado por **Invoke Workflow**; `Out` nem aparece na seção de parâmetros do page process. Parâmetro Required com Value Type nulo faz o `Invoke Workflow` lançar exceção em runtime. A doc sugere prefixo `P_` para distinguir de colunas de Additional Data e de variáveis (`V_`).

Fonte: [About Workflow Definitions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-workflow-definitions.html), [Creating a Workflow Parameter](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-workflow-parameters.html), [Creating a Workflow Parameter (Companion)](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/creating-workflow-parameter.html)

### Workflow Variables e Activity Variables

- **Workflow (version) variables**: definidas na versão (*Create Variable*, só em In Development), vivem durante toda a instância, qualquer atividade lê e altera. Tipos iguais aos dos parâmetros. Valor inicial: Static Value, Item, SQL Query (valor único), Expression, Function Body ou Null.
- **Activity variables**: definidas numa atividade (*Create Activity Variable*), existem só durante a execução daquela atividade; costumam buscar dado extra que a atividade usa. Num Parallel Flow, as activity variables da atividade paralela ficam visíveis em todos os ramos.

Uma variável muda quando: uma atividade grava nela (por exemplo, Invoke API com *Function Result* → `V_RESULT`); o administrador chama `APEX_WORKFLOW.UPDATE_VARIABLES` (só com o workflow **Suspended** ou **Faulted**); o administrador edita na página Workflow Details. A página mostra a representação `VARCHAR2`; para `CLOB` maior que o limite use a API.

Quando usar parâmetro × variável × Additional Data (critério da doc): se o valor pode ser consultado numa tabela, consulte (Additional Data do workflow se muitas atividades precisam, da atividade se só uma). Se não pode, receba como parâmetro ou calcule numa variável. Se é um valor "naquele momento" que pode mudar depois, guarde numa variável.

Pegadinha: **não** atualize a mesma variável de workflow em ramos diferentes de um Parallel Flow (ordem não determinística, vence o último; não dá para anular variável num ramo). Use activity variables por ramo e consolide depois com um Execute Code.

Fonte: [Creating a Workflow Variable](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-workflow-variables.html), [Defining Parameters and Variables](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/defining-parameters-and-variables.html), [Creating a Workflow Activity](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-workflow-activities.html), [Frequently Asked Questions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/workflow-faqs.html)

### Additional Data do workflow: tabela ou SQL + Details Primary Key

Um workflow normalmente gira em torno de uma linha de negócio (um pedido, um colaborador). Na **versão** do workflow, configure *Additional Data* como **Table** (indicando a coluna PK) ou **SQL Query** (que deve devolver exatamente uma linha e pode usar `:APEX$WORKFLOW_DETAIL_PK`). Ao iniciar a instância, passe o **Details Primary Key** (item `Details Primary Key Item` no page process ou `p_detail_pk` na API). A partir daí qualquer coluna fica disponível em todo o fluxo:

- `&NOME.` em textos (título, assunto de e-mail),
- `:NOME` em SQL/PL/SQL,
- `NOME` em propriedades que pedem nome de item.

O **Title** do workflow aceita essas substituições (ex.: `Novo paciente &FIRST_NAME. &LAST_NAME.`) e aparece no console, então deve ser significativo.

```sql
-- Additional Data (SQL Query) na versão do workflow
select s.id_solicitacao, s.ds_mensagem, c.nome_completo, c.email, c.id_empresa
  from solicitacao_correcao s
  join colaborador c on c.id_colaborador = s.id_colaborador
 where s.id_solicitacao = :APEX$WORKFLOW_DETAIL_PK
```

Pegadinha vista na doc: iniciar workflow dentro de trigger `AFTER INSERT` da própria tabela faz a query de Additional Data falhar com `ORA-04091` (tabela mutante) e `ORA-20999: Additional data row … not found`.

Fonte: [Associating a Table with a Workflow](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/associating-table-workflow.html), [Configuring a Meaningful Title](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configuring-meaningful-title.html), [Managing Workflow Versions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-workflow-versions.html), [Viewing Debug Trace Information](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/viewing-debug-trace-information.html)

### Additional Data da atividade: dados sob demanda para um passo

Toda atividade aceita uma query opcional de *Additional Data* que devolve **uma linha** com valores de que só aquele passo precisa (pode juntar outras tabelas, chamar funções, referenciar colunas do Additional Data do workflow, parâmetros e variáveis por bind). As colunas ficam disponíveis como `&NOME.`, `:NOME` e `NOME` **apenas na própria atividade**. Para que atividades seguintes usem o valor, coloque a coluna no Additional Data do workflow ou grave numa variável com um Execute Code.

```sql
-- Additional Data de uma atividade Send E-Mail
select prc.description, frc_app.get_sender_email as sender_email
  from frc_patients pat
  left join frc_medical_procedures prc on prc.code = pat.initial_procedure
 where pat.id = :ID
```

Fonte: [Retrieving Data for an Activity](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/retrieving-data-activity.html), [Querying Activity Data On Demand](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/querying-activity-data-demand.html)

### Workflow Participants: Owner, Administrator e Initiator

Participantes ficam na **versão** (não aparecem no diagrama, só na árvore). Criação: *Create Participant*.

| Papel | Pode |
|---|---|
| **Workflow Owner** | iniciar e terminar instâncias; **Retry** de workflow faulted. Vê no console "My Workflows". |
| **Workflow Administrator** | iniciar, terminar, **suspender, retomar**, retry; **alterar variáveis** (com a instância suspensa ou faulted). Vê em "Admin Workflows". |
| **Workflow Initiator** (quem iniciou; não precisa ser participante) | terminar as instâncias que iniciou. Vê em "Initiated by Me". |

Value Type: Static, SQL Query (uma coluna, um username por linha), Expression ou Function Body (lista de usernames separada por vírgula). Pode usar binds de parâmetros, colunas de Additional Data, app items e substituições. Uma versão In Development roda sem participantes; a Active exige. Depois de mudar participantes de uma versão ativa, rode `APEX_WORKFLOW.REFRESH_PARTICIPANTS(p_instance_id)` para atualizar instâncias em andamento.

**Usernames são case-sensitive**: se `:APP_USER` devolve `DAVID`, o participante deve ser `DAVID`, não `david` (contas APEX são gravadas em maiúsculas).

```sql
-- participante dinâmico passado por parâmetro (lista separada por ':')
select column_value from apex_string.split(:P_ASSIGNEE_LIST, ':')
```

Fonte: [About Workflow Definitions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-workflow-definitions.html), [Adding a Workflow Participant](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/adding-workflow-participants.html), [Identifying Workflow Participants](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/identifying-workflow-participants.html), [Determining Participants Dynamically](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/determining-participants-dynamically.html), [Passing in Workflow Participants](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/passing-workflow-participants.html)

### Workflow Runtime Engine: ordem de execução e paralelismo

- A instância começa na atividade **Start**; a ordem é definida pelas **conexões**, nunca pela *Sequence* da árvore (a Sequence só ordena a exibição).
- Quando há várias opções (Case switch, várias error connections), o engine avalia na ordem do *Execution Sequence* de cada conexão.
- Em Parallel Flow, cada ramo começa na sua primeira atividade; a ordem entre ramos é **não determinística** (depende de recursos e de as atividades serem síncronas, como Execute Code/Invoke API, ou assíncronas, como Human Task/Wait). O Parallel Flow fica Completed quando todos os ramos terminam.
- Cada próxima atividade roda numa sessão distinta do engine, sem usuário logado (`APP_USER = nobody`).

Fonte: [About the Workflow Runtime Engine](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-workflow-runtime-engine.html), [Understanding Background Execution](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-background-execution.html)

### Substitution strings e binds de workflow (APEX$WORKFLOW_*)

| Substituição | Conteúdo |
|---|---|
| `APEX$WORKFLOW_ID` | ID da instância |
| `APEX$WORKFLOW_ACTIVITY_ID` | ID da instância de atividade em execução |
| `APEX$WORKFLOW_INITIATOR` | usuário que iniciou (padrão: usuário logado que iniciou) |
| `APEX$WORKFLOW_STATE` | estado atual |
| `APEX$WORKFLOW_DETAIL_PK` | valor do Details Primary Key; como bind: `:APEX$WORKFLOW_DETAIL_PK` em queries de atividades, variáveis e participantes |
| `APEX$WORKFLOW_CREATED_ON` | timestamp de criação (`YYYY-MM-DD"T"HH24:MI:SS.FF3TZH:TZM`) |

Dentro de uma atividade, `v('APEX$WORKFLOW_ID')` devolve o ID da instância (útil para montar URLs). As mesmas constantes existem em `APEX_WORKFLOW` (`c_workflow_id`, `c_workflow_initiator` etc.).

Fonte: [Workflow Substitution Strings](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/workflow-substitution-strings.html), [APEX_WORKFLOW Constants and Data Types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WORKFLOW.Constants-and-Data-Types.html), [Generating Page URL for Notification](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/generating-page-url-notification.html)

---

## 3. Workflow Designer, atividades e conexões

### Workflow Designer: árvore, Diagram Builder, paleta e Show Messages

- **Workflow Designer Tree** (esquerda): workflows, parâmetros, versões; dentro da versão, atividades (com activity variables, conexões de entrada e saída, ramos de Parallel Flow), participantes e variáveis. Menu de contexto: Create Activity Below/After, Create Activity Variable, Create Branch, Create Connection, Duplicate, Delete; na versão: Activate/Deactivate, Create Activity/Variable/Participant.
- **Diagram Builder** (centro): grade de 10 px; cria, move, liga atividades. Não mostra variáveis, parâmetros nem participantes. Ferramentas: Connect (nos quatro lados), Menu, Add Element no meio da conexão, vértices (elbow dots), âncoras, segmentos. Toolbar: Bring to Front/Send to Back, Direct/Orthogonal Connection, zoom, Navigator View, Back (ao abrir um workflow invocado).
- **Activities Palette** (embaixo): arrastar para o canvas. Soltar uma atividade sobre outra liga em sequência; soltar sobre uma conexão insere no meio.
- **Show Messages**: contador de erros de modelagem; **não é possível salvar** enquanto houver erros. Conexão vermelha saindo de Switch = falta configurar a condição.
- *Create Activity Below* cria sem conexão; *Create Activity After* cria já ligada (substituindo a conexão existente).
- Dica de acabamento: use "Bring to Front" nas conexões para que as setas não fiquem escondidas sob as atividades no diagrama de runtime.
- Atalhos: `Alt+Shift+F1` lista atalhos; salvar `Alt+F7` (Mac `Option+F7`); `Ctrl+/, D` diagrama; `Ctrl+/, W` árvore; `Ctrl+/, E` Property Editor; `Ctrl+/, M` mensagens.

Fonte: [About Workflow Designer](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-workflow-designer.html), [Creating a Workflow Activity](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-workflow-activities.html), [Resolving Errors Before Saving a Workflow](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/resolving-errors-saving-workflow.html), [Bringing Connections in Front of Activities](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/bringing-connections-front-activities.html), [About Workflow Keyboard Shortcuts](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/workflow-keyboard-shortcuts.html)

### Tipos de atividade de workflow disponíveis no 26.1

Cada atividade corresponde a um process type (plug-in nativo ou custom). Só se cria atividade em versão In Development; o tipo padrão de uma atividade nova é Execute Code; o nome deve ser único no workflow.

| Atividade | Para quê |
|---|---|
| **Workflow Start** | Início; exatamente uma; sem conexões de entrada. |
| **Workflow End** | Fim do workflow (ou de um caminho); End State `Completed` ou `Terminated`; uma ou várias; sem saída. |
| **Execute Code** | PL/SQL inline. |
| **Invoke API** | Chama procedure/função PL/SQL (ou REST); parâmetros mapeados na árvore; *Function Result* pode ir para variável. |
| **Switch** | Ramificação condicional (4 tipos). |
| **Wait** | Pausa até timeout ou até `APEX_WORKFLOW.CONTINUE_ACTIVITY`. |
| **Human Task - Create** | Cria task a partir de Task Definition e **espera** ela terminar. |
| **Invoke Workflow** | Chama outro workflow da mesma app como sub-rotina. |
| **Parallel Flow** | Vários ramos em paralelo; espera todos. |
| **Send E-Mail** | E-mail (inline ou Email Template). |
| **Send Push Notification** | Push para usuário inscrito. |
| **Generate Text with AI** | Gera texto com um AI Agent. |
| **Server Side Geocoding** | Endereço → coordenadas (**só Oracle APEX em Autonomous AI Database**). |
| **Custom Process Type Plug-in** | Plug-in de processo com *Supported For: Workflow Activities*. |

Propriedades comuns a todas: **Due On** (Deadline/timeout; Wait tem timeout próprio e não mostra Deadline), **Additional Data** (SQL), **Sequence** (só ordem na árvore), **Label** (nome no diagrama), e activity variables. Erros não são tratados na atividade, e sim por **Error connections** que saem dela.

Fonte: [Creating a Workflow Activity](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-workflow-activities.html), [Surveying the Native Activities](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/surveying-native-activities.html), [About Workflow Definitions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-workflow-definitions.html)

### Atividade Switch: True False, Check Workflow Variable, Case e If Elsif Else

As saídas de um Switch são **branches**; cada conexão que sai dele indica qual resultado representa.

| Tipo | Decide por | Conexões de saída |
|---|---|---|
| **True False Check** | Condição única: Rows Returned / Rows Not Returned (SQL), Expression, Function Body, `Workflow Variable = / != Value`, `is NULL`, `is NOT NULL` | Conexão com *When* = True, False ou Null |
| **Check Workflow Variable** | Valor de um parâmetro, variável de versão ou activity variable (*Compare Variable*) | Uma por valor (Operator + valor); "otherwise" avaliada por último |
| **Case** | Resultado de SQL Query, Expression ou Function Body; *Compare Data Type*: `VARCHAR2`, `NUMBER`, `BOOLEAN`, `TIMESTAMP`, `TIMESTAMP WITH (LOCAL) TIME ZONE` | Várias, cada uma com Sequence, Operator e Value; vence a primeira verdadeira |
| **If Elsif Else** | Cada conexão tem sua própria condição (Server-side Condition) | Várias, avaliadas por Execution Sequence; vence a primeira verdadeira |

Uso típico após uma task de aprovação: Switch do tipo Check Workflow Variable sobre `TASK_OUTCOME` com ramos `= APPROVED` e `= REJECTED`. Para condições complexas a doc recomenda If Elsif Else em vez de True False com função. Numa versão Active ainda é possível alterar as condições dos branches.

Fonte: [Creating a Workflow Activity](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-workflow-activities.html), [Switching Path Using a Condition](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/switching-path-using-condition.html), [Configuring a Switch Connection](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configuring-switch-connection.html), [Frequently Asked Questions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/workflow-faqs.html)

### Atividade Wait: timeout ou espera indefinida por sinal

A Wait pausa a instância (o workflow fica **Suspended**/a atividade **Waiting**). Ela sai da espera de dois modos:

1. **Timeout**: *Timeout Type* = Static (duração ISO, ex. `PT2H`, `P3D`), SQL Query, Expression ou Function Body. O job `ORACLE_APEX_WF_TIMEOUT` (a cada 5 min) trata o vencimento.
2. **Sinal da aplicação**: deixe *Timeout Type* vazio para esperar indefinidamente e chame `APEX_WORKFLOW.CONTINUE_ACTIVITY` com o ID da instância e o **Static ID** da atividade Wait. Chaves do mapa `p_activity_params` que coincidirem com Static IDs de variáveis do workflow são atribuídas automaticamente.

Wait não tem seção Deadline nem pode ter conexão Timeout adicional (o timeout já é dela). Plug-ins de atividade com *Wait for Completion* também podem ser continuados com `CONTINUE_ACTIVITY`.

```plsql
-- página que recebe a resposta do usuário (itens ocultos P5_WORKFLOW_ID e P5_ACTIVITY_STATIC_ID)
declare
    l_input apex_application_global.vc_map;
begin
    l_input('V_PROVIDING_USERNAME') := :APP_USER;
    l_input('V_VALUE1')             := :P5_VALUE1;
    apex_workflow.continue_activity(
        p_instance_id     => :P5_WORKFLOW_ID,
        p_static_id       => :P5_ACTIVITY_STATIC_ID,
        p_activity_params => l_input);
end;
```

Fonte: [Creating a Workflow Activity](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-workflow-activities.html), [Waiting Until Application Logic Continues](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/waiting-application-logic-continues.html), [Signaling to Continue and Returning Data](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/signaling-continue-and-returning-data.html), [CONTINUE_ACTIVITY Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WORKFLOW.CONTINUE_ACTIVITY-Procedure-Signature-1.html)

### Atividade Human Task - Create: TASK_OUTCOME, APPROVER e prazos

Cria uma task a partir de uma Task Definition (que precisa existir) e **espera** a task terminar. Settings: *Definition*; *Subject*, *Priority* e *Initiator Can Complete* (sobrepõem a definição); *Initiator Item* (sem valor, a doc diz que vale o usuário logado; como no workflow ele é `nobody`, o exemplo do Developer's Companion passa explicitamente `APEX$WORKFLOW_INITIATOR`); *Task ID Item* (variável que recebe o ID da task); *Details Primary Key Item* (item do workflow com a PK da linha da Actions Source); *Outcome* e *Owner* (variáveis que recebem o resultado e quem concluiu). Os parâmetros da Task Definition aparecem sob a atividade na árvore e podem receber `&P_PARAM.` do workflow.

Ao criar a **primeira** atividade Human Task, o Designer cria as variáveis `TASK_OUTCOME` e `APPROVER`. Ao concluir, `TASK_OUTCOME` recebe `APPROVED` ou `REJECTED` e `APPROVER` o actual owner. Para outras atividades Human Task essas variáveis não são recriadas: reutilize ou crie novas.

Para ler parâmetros atualizáveis preenchidos pelo dono da task, use num Execute Code seguinte:

```plsql
:V_VALUE1 := apex_human_task.get_task_parameter_value(:V_TWO_NUMBERS_TASK_ID, 'P_VALUE1');
```

Interação de prazos (FAQ):
- Prazo na atividade de workflow **prevalece** sobre o da Task Definition; sem prazo na atividade, vale o da definição.
- Task criada por workflow expira mesmo com Expiration Policy `None`; após expirar, o workflow segue a conexão **Timeout**; sem ela, o workflow vai a **Faulted**.
- O business admin **não** pode renovar manualmente nem mudar o prazo de task criada por workflow.
- Task **cancelada**: o workflow segue sem outcome (um Switch sobre o outcome a seguir vai a Faulted). Task **errored**: workflow vai a Faulted (retry após corrigir).
- Workflow terminado com tasks ativas: as tasks vão a **Canceled**.
- Rejeição por engano: com uma Wait logo depois da aprovação, o admin suspende, edita `TASK_OUTCOME` para `APPROVED` na página de detalhes e retoma.

Fonte: [Creating a Workflow Activity](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-workflow-activities.html), [Awaiting Completion of a Human Task](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/awaiting-completion-human-task.html), [Creating the Human Task Instance](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/creating-human-task-instance.html), [Assigning Task Parameters to Variables](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/assigning-task-parameters-variables.html), [Frequently Asked Questions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/workflow-faqs.html)

### Atividade Invoke Workflow: subprocessos

Chama outro workflow **da mesma aplicação** (precisa existir e ter versão Active para ativar o pai). Um workflow não pode invocar a si mesmo nem a quem o chamou (evita ciclo).

| Atributo | Comportamento |
|---|---|
| Definition | workflow invocado |
| Initiator Item | opcional; padrão: iniciador do pai |
| Details Primary Key Item | item com a PK para o filho |
| Workflow ID Item | variável que recebe o ID da instância filha |
| Wait for Completion | **On (padrão)**: o pai espera o filho terminar; Off: segue direto |
| Retry Point | (só com Wait On) `Resume` retenta o filho a partir da atividade com falha; `Start Over` termina o filho com falha e inicia outro (vale quando o Retry é feito no pai faulted) |
| Parameters > Ignore Output | padrão On; desligado, parâmetros Out/In-Out do filho só podem ir para itens do pai |

Terminar um workflow invocado também termina o pai se este estiver esperando por ele. O Designer abre o filho pelo menu *Open* e volta com *Back*. O Workflow Details de um filho tem botão para o pai.

Fonte: [Creating a Workflow Activity](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-workflow-activities.html), [About Using Workflows in Page Processes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-workflows-in-page-processes.html)

### Atividade Parallel Flow: ramos simultâneos

Cria dois ou mais **branches** (dois por padrão, cada um com um Execute Code). Expanda pela seta para editar os ramos (o resto do diagrama fica bloqueado até recolher). *Create Branch* adiciona ramo; *Move Branch left/right* reordena.

Restrições: ramo não começa com Workflow Start nem termina com Workflow End; **não há Parallel Flow dentro de Parallel Flow**. Prazo na atividade paralela: ao vencer, **todas** as atividades de todos os ramos terminam; modele uma conexão **Timeout** para o fluxo continuar. Se uma atividade de um ramo falha, o Parallel Flow vai a Faulted; Retry retenta todas as falhas de todos os ramos (pode ser preciso repetir). Additional Data e activity variables da atividade paralela ficam disponíveis em todos os ramos.

Fonte: [Creating a Workflow Activity](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-workflow-activities.html), [About Workflow Definitions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-workflow-definitions.html), [States and Transitions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/states-and-transitions.html)

### Atividades Invoke API, Execute Code, Send E-Mail, Send Push Notification e Generate Text with AI

- **Invoke API**: aponta para procedure/função de package; cada parâmetro aparece na árvore e recebe valor de item do workflow (coluna de Additional Data como `ID`, parâmetro, variável); o resultado de função vai para uma variável (*Function Result*). Prefira lógica em packages (manutenção) a PL/SQL inline.
- **Execute Code**: PL/SQL inline; pode atribuir variáveis (`:V_X := ...`) e chamar `apex_debug.info`.
- **Send E-Mail**: From (padrão `&APP_EMAIL.`), To, Cc, Bcc, Reply To, Email Template + Placeholders, ou Subject/Body Plain Text/Body HTML, Attachment SQL. Valores vêm de Additional Data (ex.: `&SENDER_EMAIL.`). Em URLs dentro de atributos HTML use `&LINK_TO_PAGE!ATTR.`.
- **Send Push Notification**: To = **username** (case-sensitive) do usuário inscrito; Title, Body, Link Target. Usuário não inscrito é ignorado silenciosamente.
- **Generate Text with AI**: *Generative AI > Agent*; *Input Value* (Type Item + item); *Use Response > Item*. Se o destino for variável de workflow, use tipo `CLOB`. Requer Generative AI Service e atributos de IA configurados (senão erro).

Como o workflow não tem `APP_USER`, a doc recebe o destinatário como parâmetro (`P_REQUESTED_USERNAME`) e busca o e-mail em `APEX_WORKSPACE_APEX_USERS`.

Fonte: [Creating a Workflow Activity](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-workflow-activities.html), [Evaluating Spatial Distance with an API](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/evaluating-spatial-distance-api.html), [Emailing User a Page Link](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/emailing-user-page-link.html), [Delivering Push Notification with Page Link](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/delivering-push-notification-page-link.html), [Emailing Users a Rejection](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/emailing-users-rejection.html)

### Process plug-in como atividade de workflow (Wait for Completion e callbacks)

Para usar um plug-in de processo como atividade: em *Shared Components > Plug-ins*, no plug-in, marque **Supported For > Workflow Activities**. Para que o workflow espere o plug-in terminar:
- *Standard Attributes > Wait for Completion*;
- *Callbacks > Completion function*: executada quando o processo chama `apex_workflow.continue_activity`, antes de o workflow seguir;
- *Callbacks > Termination function*: libera recursos se o workflow for terminado (só com Wait for Completion).

O plug-in aparece na paleta sob *Application Components*. Há também plug-ins de comunidade para atividades.

Fonte: [Creating a Workflow Activity](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-workflow-activities.html), [Surveying the Native Activities](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/surveying-native-activities.html)

### Conexões de workflow: Normal, Timeout e Error

| Tipo | Regra |
|---|---|
| **Normal** | Ligação padrão. Toda atividade precisa de ao menos uma entrada e uma saída normais, exceto Start (sem entrada) e End (sem saída). |
| **Timeout** | Só se a atividade de origem tem *Due On*; Wait não pode ter (já tem timeout). Usada após vencimento do prazo (inclusive de task e Parallel Flow). |
| **Error** | Uma ou várias por atividade; cada uma com *Sequence*, *Operator* e *Value* = código de erro SQL. Em vez de ir a Faulted, o workflow segue para o destino. Sem error connection correspondente, o workflow vai a **Faulted**. |

Exemplo da FAQ: Invoke API que dá `no_data_found` → error connection com operador `=` e valor `01403` levando a uma atividade que cria o registro faltante. Conexões só podem ser criadas com o workflow In Development; o nome da conexão não precisa ser único. (Atenção: a página "Adding a Workflow Connection" cita `-01043` para `NO_DATA_FOUND`; o código correto do `NO_DATA_FOUND` é 01403, como a própria FAQ usa.)

Fonte: [Adding a Workflow Connection](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/adding-workflow-connections.html), [About Workflow Definitions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-workflow-definitions.html), [Frequently Asked Questions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/workflow-faqs.html)

---

## 4. Operação de workflows

### Page process Workflow: Start, Terminate, Suspend, Resume e Retry

Process type **Workflow** (Rendering ou Processing). *Settings > Type*:

| Type | Atributos | Observações |
|---|---|---|
| **Start** | Definition; parâmetros (Static Content, Page Item com format mask, SQL Query, Expression, Function Body, Default, Null); *Details Primary Key* (item com a PK da fonte da versão); *Workflow ID Item* (recebe o ID) | Required não atribuído → erro ao salvar a página |
| **Terminate** | Workflow ID Item | Termina também o pai que espera por ele |
| **Suspend** | Workflow ID Item | |
| **Resume** | Workflow ID Item; *Activity Static ID Item* opcional | Retoma na atividade indicada (a atual é terminada) |
| **Retry** | Workflow ID Item | Só faulted |

Para que o admin escolha onde retomar, a doc sugere um Select List no Workflow Details com a query abaixo e ligá-lo ao *Activity Static ID Item* do processo Resume:

```sql
select wa.name as name, wa.static_id as value
  from apex_appl_workflow_activities wa,
       apex_appl_workflow_versions   wv,
       apex_workflows                wf$
 where wf$.workflow_id         = :P<X>_WORKFLOW_ID
   and wf$.workflow_version_id = wv.version_id
   and wv.version_id           = wa.version_id
   and wv.workflow_static_id   = wa.workflow_static_id
```

Fonte: [About Using Workflows in Page Processes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-workflows-in-page-processes.html)

### Iniciar workflow por PL/SQL: APEX_WORKFLOW.START_WORKFLOW

```plsql
APEX_WORKFLOW.START_WORKFLOW (
    p_application_id IN NUMBER   DEFAULT apex_application.g_flow_id,
    p_static_id      IN VARCHAR2,
    p_parameters     IN t_workflow_parameters DEFAULT c_empty_workflow_parameters,
    p_initiator      IN VARCHAR2 DEFAULT NULL,
    p_detail_pk      IN VARCHAR2 DEFAULT NULL,
    p_debug_level    IN apex_debug_api.t_log_level DEFAULT NULL )
RETURN NUMBER;  -- ID da nova instância
```

`t_workflow_parameter` = (`static_id`, `value apex_session_state.t_value`, `string_value` **deprecated**, `format_mask`).

```plsql
declare
    l_id number;
begin
    l_id := apex_workflow.start_workflow(
                p_static_id   => 'procedure_lifecycle',
                p_detail_pk   => p_procedure_id,
                p_initiator   => 'ADMIN',
                p_parameters  => apex_workflow.t_workflow_parameters(
                    1 => apex_workflow.t_workflow_parameter(static_id => 'P_MOTIVO', string_value => 'Teste')));
end;
```

Pegadinha: é **função**; chamar como procedure dá `PLS-00221: 'START_WORKFLOW' is not a procedure or is undefined`. Atribua a uma variável mesmo que não use.

Fonte: [START_WORKFLOW Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WORKFLOW.START_WORKFLOW-Function.html), [Starting the Lifecycle Workflow](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/starting-lifecycle-workflow.html)

### Padrão "notificar com link + Wait + CONTINUE_ACTIVITY" (deep linking)

Receita da doc para pedir dado a um usuário sem task:

1. Habilite **Deep Linking** em *Shared Components > Security Attributes* (Session Management); sem isso o link leva à home depois do login.
2. Gere URL **absoluta** com `APEX_PAGE.GET_URL(p_absolute_url => true, p_session => 0)`, passando o ID do workflow (`v('APEX$WORKFLOW_ID')`) e o Static ID da Wait em itens ocultos da página destino.
3. Send E-Mail/Push com o link (Additional Data da atividade chama a função).
4. Wait sem Timeout Type.
5. Na página destino, um processo chama `APEX_WORKFLOW.CONTINUE_ACTIVITY`. Alternativamente, a página grava direto na tabela de negócio (o `DETAIL_PK` sai de `APEX_WORKFLOWS`).

```plsql
function absolute_page_url(p_page in number, p_activity_static_id in varchar2) return varchar2 is
begin
    return apex_page.get_url(
        p_page         => p_page,
        p_items        => 'P'||p_page||'_WORKFLOW_ID,P'||p_page||'_ACTIVITY_STATIC_ID',
        p_values       => v('APEX$WORKFLOW_ID')||','||p_activity_static_id,
        p_absolute_url => true,
        p_session      => 0,
        p_debug        => 'NO');
end;
```

Para encontrar a instância a continuar a partir da PK de negócio, consulte `APEX_WORKFLOWS` ⨝ `APEX_WORKFLOW_ACTIVITIES` filtrando `detail_pk`, `workflow_def_static_id`, `static_id` da atividade, `ac.state = 'WAITING'` e `wf.state_code = 'ACTIVE'`. Para exibir título/rótulo na página use `APEX_WORKFLOWS.TITLE` e `APEX_WORKFLOW_ACTIVITIES.LABEL` (com `type_code = 'NATIVE_WORKFLOW_WAIT'`).

Fonte: [Waiting for a Signal to Continue](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/waiting-signal-continue.html), [Enabling Deep Linking to a Specific Page](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/enabling-deep-linking-specific-page.html), [Generating Page URL for Notification](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/generating-page-url-notification.html), [Continuing a Waiting Lifecycle Workflow](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/continuing-waiting-lifecycle-workflow.html), [Retrieving Title and Activity Labels](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/retrieving-title-and-activity-labels.html)

### Padrão "workflow de ciclo de vida": trigger + fila + automation + CONTINUE_ACTIVITY

Para um workflow reagir a mudanças de status de uma linha (ciclo de vida de uma entidade), a doc desacopla:
1. Trigger `AFTER UPDATE FOR EACH ROW` grava um **evento** numa tabela de fila (tipo `STATUS` ou `SCHEDULE`) via package.
2. Uma **automation** agendada (ex. a cada 2 min, *Actions Initiated On* = Query sobre uma função pipelined que devolve um evento por entidade com `ROW_NUMBER() ... WHERE rn = 1`) chama `process_event(:ID)` por linha, com **commit por linha**.
3. `process_event` acha o workflow cuja Wait (`status_or_date_changed`) está WAITING e chama `CONTINUE_ACTIVITY` passando `V_WHAT_CHANGED`; se der certo, apaga o evento.
4. O workflow tem Switches sobre `V_WHAT_CHANGED` e colunas de Additional Data; a maioria dos caminhos volta para a Wait; o status final leva ao End.

Motivo: manter a UI rápida e não chamar a API do workflow de dentro do trigger (risco de tabela mutante).

Fonte: [Notifying Workflow of Data Changes](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/notifying-workflow-data-changes.html), [Understanding Lifecycle Event Strategy](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-lifecycle-event-strategy.html), [Simplifying Event Management](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/simplifying-event-management.html), [Processing Events with an Automation](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/processing-events-automation.html), [Modeling the Medical Procedure Lifecycle](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/modeling-medical-procedure-lifecycle.html)

### Workflow Console, Workflow Details e Workflow Dashboard

Create Page Wizard > *Component > Workflow Console*. Atributos: Page Number, Name, **Report Context**, *Include Dashboard Page*, Form Page Number/Name, Form Page Mode (Normal, Modal Dialog, Drawer), breadcrumb/navegação.

| Report Context | Mostra instâncias em que o usuário é | Constante |
|---|---|---|
| My Workflows | Workflow Owner | `MY_WORKFLOWS` |
| Admin Workflows | Workflow Administrator | `ADMIN_WORKFLOWS` |
| Initiated by Me | iniciador | `INITIATED_BY_ME` |

- **Console**: Content Row com `table(apex_workflow.get_workflows(p_context => ...))`. Por padrão mostra workflows de **todas as apps do workspace**; descomente `p_application_id => :APP_ID` para filtrar. Troque por `select *` para ver todas as colunas.
- **Details**: atividades e estados (início, conclusão, retry, fault, terminate), variáveis (editáveis por admin), parâmetros, histórico/auditoria (inclusive pai), diagrama somente leitura (**Workflow Diagram region**), botões Suspend/Resume/Terminate/Retry conforme contexto.
- **Dashboard**: abas Workflows by State (pizza), Active Workflows (active/suspended por atividade), Faulted Workflows, Performance (tempo médio; Time Unit).
- Em ambiente multi-tenant, console e dashboard respeitam o **Tenant ID da sessão APEX** (`APEX_SESSION.SET_TENANT_ID` / `APP_TENANT_ID`).

A **Workflow Diagram region** pode ser usada em qualquer página (ex.: modal aberto a partir de um relatório) recebendo o ID da instância; destaca as atividades e conexões já percorridas.

Fonte: [About the Workflow Console, Workflow Details, and Workflow Dashboard](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-workflow-console.html), [Creating the Workflow Console…](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-workflow-console.html), [Listing Workflows and Viewing Details](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/listing-workflows-and-viewing-details.html), [Visualizing Workflow Progress](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/visualizing-workflow-progress.html), [SET_TENANT_ID Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_TENANT_ID.html)

### Estados de instância de workflow e transições

| Estado | Significado | Transições possíveis |
|---|---|---|
| **Active** | em execução | Completed (chegou a End); Faulted (parâmetros inválidos, zero ou mais de um Start…); Suspended (API/usuário); Terminated (API/usuário ou End com estado Terminated) |
| **Suspended** | parado numa atividade (tipicamente Wait); Admin retoma | Active (resume); Faulted (atividade assíncrona voltou com erro); Terminated |
| **Faulted** | erro numa atividade ou no próprio workflow (variáveis, sistema) | Active (retry bem-sucedido); Suspended; Terminated |
| **Completed** | terminou normalmente | — |
| **Terminated** | parado por owner/admin ou End Terminated | — (não pode ser retentado) |

Retry × Resume: **Retry** só para Faulted (owner ou admin; reexecuta a atividade que falhou; sem limite de tentativas; **não há auto-retry**). **Resume** só para Suspended (admin). Por padrão retoma na atividade atual; `APEX_WORKFLOW.RESUME(p_activity_static_id)` retoma em outra.

Fonte: [States and Transitions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/states-and-transitions.html), [Frequently Asked Questions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/workflow-faqs.html)

### Estados de atividade de workflow

| Estado | Significado | Transições |
|---|---|---|
| Active | executando | Completed, Faulted, Terminated, Waiting |
| Waiting | esperando resultado (task, workflow invocado, ramos paralelos, Wait) | Active (sinal recebido; pode durar milissegundos), Faulted, Terminated |
| Completed | ok (Parallel Flow só quando todos os ramos terminam) | — |
| Faulted | falhou | Active (retry do workflow) |
| Terminated | estava ativa quando o workflow foi parado | — |

Fonte: [States and Transitions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/states-and-transitions.html)

### APEX_WORKFLOW: referência das procedures e funções

Requer sessão APEX válida.

| Rotina | Função | Restrição |
|---|---|---|
| `START_WORKFLOW(...) return number` | inicia | ver seção própria |
| `CONTINUE_ACTIVITY(p_instance_id, p_static_id, p_activity_params vc_map, p_activity_status default 'SUCCESS')` | continua atividade Waiting | assinatura 2 usa `p_activity_instance_id`; status `c_activity_status_success`/`_failure` |
| `SUSPEND(p_instance_id)` | suspende | só Active ou Faulted |
| `RESUME(p_instance_id, p_activity_static_id default null)` | retoma | só Suspended; em runtime-only só Admin |
| `RETRY(p_instance_id)` | retenta | Faulted |
| `TERMINATE(p_instance_id)` | termina | Active, Suspended ou Faulted |
| `TERMINATE_FAULTED_WORKFLOWS(p_application_id)` | termina todos os faulted | |
| `UPDATE_VARIABLES(p_instance_id, p_changed_params t_workflow_parameters)` | altera variáveis (aplica format mask) | usuário Admin; workflow Suspended ou Faulted |
| `GET_VARIABLE_VALUE(p_instance_id, p_variable_static_id) return varchar2` | lê variável | CLOB grande pode lançar exceção |
| `GET_VARIABLE_CLOB_VALUE(...) return clob` | lê CLOB (ou VARCHAR2) | |
| `GET_WORKFLOW_STATE(p_instance_id)` | estado | |
| `GET_WORKFLOWS(p_context, p_user, p_workflow_id, p_application_id)` pipelined | lista por contexto (`MY_WORKFLOWS`, `ADMIN_WORKFLOWS`, `INITIATED_BY_ME`, `SINGLE_WORKFLOW`) | não devolve nada em SQL Workshop (sem sessão) |
| `IS_ADMIN(p_user, p_application_id)`, `IS_ALLOWED(p_instance_id, p_operation, p_user)`, `IS_OF_PARTICIPANT_TYPE(p_instance_id, p_participant_type, p_user)` | checagens de permissão | operações `SUSPEND`, `RESUME`, `RETRY`, `UPDATE_VARIABLE`, `TERMINATE` |
| `REFRESH_PARTICIPANTS(p_instance_id)` | reavalia participantes | |
| `SET_ACTIVITY_DUE_DATE(p_instance_id, p_activity_static_id, p_due_date)` | muda prazo | workflow Faulted ou Suspended |
| `SET_LOG_LEVEL(p_instance_id, p_debug_level)` | debug da instância (1 error, 2 warn, 4 info, 5 enter, 6 app_trace) | sobrepõe o da versão |
| `REMOVE_DEVELOPMENT_INSTANCES(p_application_id, p_static_id)` | apaga instâncias criadas em DEV | sem arquivar; apaga tasks dependentes |
| `DELETE_WORKFLOWS(p_application_id, p_static_id, p_states apex_t_varchar2, p_include_all_versions default false)` | limpeza | false = só de versões Inactive; usar com cautela |
| `GET_NEXT_PURGE_TIMESTAMP`, `GET_LOV_WORKFLOW_STATE`, `GET_LOV_ACTIVITY_STATE` | utilitários | |

Constantes de estado: `c_state_active`, `_suspended`, `_faulted`, `_completed`, `_terminated`, `_waiting`. Participantes: `c_workflow_owner = 'OWNER'`, `c_workflow_admin = 'ADMIN'`. Divergência: a FAQ menciona `apex_workflow.clear_test_data`, que **não existe** na referência 26.1; use `REMOVE_DEVELOPMENT_INSTANCES`. O exemplo do `IS_ALLOWED` usa `c_workflow_op_suspend`, mas a constante listada é `c_workflow$_op_suspend`.

```sql
select workflow_id, title, state, initiator, workflow_version
  from table(apex_workflow.get_workflows(p_context => 'ADMIN_WORKFLOWS', p_application_id => :APP_ID))
```

Fonte: [APEX_WORKFLOW](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WORKFLOW.html), [Constants and Data Types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WORKFLOW.Constants-and-Data-Types.html), [GET_WORKFLOWS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WORKFLOW.GET_WORKFLOWS-Function.html), [UPDATE_VARIABLES Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WORKFLOW.UPDATE_VARIABLES-Procedure.html), [DELETE_WORKFLOWS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WORKFLOW.DELETE_WORKFLOWS-Procedure.html), [Frequently Asked Questions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/workflow-faqs.html)

### Views de dicionário de workflows (metadados e runtime)

| Metadados (definição) | Runtime (instâncias) |
|---|---|
| `APEX_APPL_WORKFLOWS` (static ID) | `APEX_WORKFLOWS` (`workflow_id`, `title`, `state_code`, `detail_pk`, `workflow_def_static_id`, `workflow_version`, `start_time`…) |
| `APEX_APPL_WORKFLOW_VERSIONS` | `APEX_WORKFLOW_ACTIVITIES` (`static_id`, `state`, `label`, `type_code`) |
| `APEX_APPL_WORKFLOW_ACTIVITIES` | `APEX_WORKFLOW_VARIABLES` |
| `APEX_APPL_WORKFLOW_TRANSITIONS`, `APEX_APPL_WORKFLOW_BRANCHES`, `APEX_APPL_WORKFLOW_ACT_BRANCH` | `APEX_WORKFLOW_ACTIVITY_VARS` |
| `APEX_APPL_WORKFLOW_VARIABLES`, `APEX_APPL_WORKFLOW_ACT_VARS` | `APEX_WORKFLOW_PARAMETERS` |
| `APEX_APPL_WORKFLOW_PARAMS`, `APEX_APPL_WORKFLOW_PARTICIPANT(S)` | `APEX_WORKFLOW_PARTICIPANTS` |
| `APEX_APPL_WORKFLOW_COMP_PARAMS` (valores no page process) | `APEX_WORKFLOW_AUDIT` |
| | `APEX_PURGEABLE_WORKFLOWS`, `_WF_ACTIVITIES`, `_WF_VARIABLES`, `_WF_PARTICIPANT`, `_WF_AUDIT` |

(A doc escreve `APEX_WORKFLOW_PARMETERS` numa tabela e `APEX_APPL_WORKFLOW_PARTICIPANT` noutra; confira o nome no dicionário.) Antes de apagar uma versão, verifique se há instâncias nela:

```sql
select distinct workflow_version
  from apex_workflows
 where application_id = :APP_ID and workflow_def_static_id = 'meu_workflow';
```

Fonte: [Workflow Views](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/workflow-views.html), [Accessing Workflow and Task Data](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/accessing-workflow-and-task-data.html), [Deleting a Workflow with No Instances](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/deleting-workflow-no-instances.html)

### Depurar workflows: Debug Level, SET_LOG_LEVEL e APEX_DEBUG_MESSAGES

- Como workflows rodam em background, ligar debug pela Developer Toolbar não basta: defina **Debug Level** na versão (*Advanced*) ou, para uma instância já em falha, `apex_workflow.set_log_level(id, apex_debug_api.c_log_level_app_trace)` e faça Retry.
- No Debug Viewer, mensagens de workflow não têm página nem usuário: desmarque/limpe o filtro de página e procure pelo usuário `nobody`. Em *Utilities > Debug Messages* adicione a coluna *Workflow Instance*.
- Adicione `apex_debug.info('### x=(%s)', :X)` em Execute Code (até 10 `%s` ou `%0..%9`; mensagem até 32.727 caracteres; valores truncados em 1000 por padrão, `p_max_length` para mais).

```sql
select message_timestamp, message, workflow_instance_id, message_level
  from apex_debug_messages
 where application_id = :APP_ID
   and apex_user = 'nobody'
   and call_stack like '%\%WORKFLOW.%' escape '\'
   and message_level < 9
 order by message_timestamp desc;
```

Teste em runtime se a app está em Development Mode: `v('APP_BUILDER_SESSION') is not null`.

Fonte: [Viewing the Workflow Instance ID in Debug Messages](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/workflow-debug-reports.html), [Querying Recent Debug Messages](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/querying-recent-debug-messages.html), [Enabling Debug Tracing Proactively](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/enabling-debug-tracing-proactively.html), [Adding Custom Debug Messages](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/adding-custom-debug-messages.html), [Recognizing Development Mode](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/recognizing-development-mode.html)

### Retenção e purge de workflows e tasks

| | Workflows | Tasks |
|---|---|---|
| Mantidos | Active, Suspended, Faulted | ativas, Unassigned, Assigned |
| Concluídos | purgados após a retenção (padrão **30 dias**, máx. **100**) | purgados após a retenção (padrão **7 dias**, máx. **30**) |
| Sem retenção (somem em até 24 h) | Terminated (e canceled) | Terminated, Canceled, Errored (e Expired, segundo o job) |
| Job | `ORACLE_APEX_WFS_PURGE` 03:00 | `ORACLE_APEX_TASKS_PURGE` 02:00 (salva JSON) |

Configuração: *Administration Services > Manage Instance > Instance Settings > Workflow Settings* (Retention Period Days de tasks; Workflow Retention Period Days). O relatório **Archive of Purged Task Files** fica na administração do workspace (Monitor Activity) e é limpo a cada 30 dias. Views `APEX_PURGEABLE_TASKS` etc. permitem copiar antes do purge.

Consequência de projeto: **histórico permanente deve ir para tabelas da aplicação** (task action no evento Complete, atividade do workflow, ou automation lendo as views).

```sql
merge into user_task_table u
using apex_purgeable_tasks t on (u.task_id = t.task_id)
when not matched then insert (u.task_id, u.task_type, u.subject, u.priority)
values (t.task_id, t.task_type, t.subject, t.priority);
```

Fonte: [Workflow Instance Retention](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/workflow-retention.html), [About Task Retention and Task Purging](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-the-retention-and-archival-of-tasks.html), [Configuring Workflow Settings](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-workflow-settings.html), [Understanding Task and Workflow Purging](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-task-and-workflow-purging.html)

### Deploy de workflows: versões em produção, import × delete da aplicação

- Altere workflows **só no ambiente de desenvolvimento**: duplique a Active para criar a próxima versão In Development, teste em Development Mode, ative, e promova a app. Nunca duplique/edite versões em produção. Cada instância usa até o fim a versão com que nasceu.
- Atualize a app em produção **importando por cima** (mesmo ID). **Apagar a aplicação apaga todas as instâncias de workflow e task.** Dica: testes que criam instâncias podem ser feitos numa *Working Copy*; ao apagá-la, as instâncias somem.
- Durante o reimport, instâncias em execução são **suspensas**. Divergência na doc: a página "Importing a New Application Version Containing Workflows" diz que elas ficam suspensas até um administrador retomar ou terminar; a FAQ diz que retomam automaticamente ao fim do import. Verifique o console depois de cada deploy.
- Tasks criadas fora de Development Mode não podem ser apagadas; o admin cancela e o purge diário remove.

Fonte: [Deploying Workflows to Production](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/deploying-workflows-production.html), [Importing vs. Deleting an Application](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/importing-vs-deleting-application.html), [Managing Workflow Versions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-workflow-versions.html), [Removing Development Instances](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/removing-development-instances.html), [Frequently Asked Questions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/workflow-faqs.html)

### Relatórios de workflows no Builder (Utilization e History)

Em *Shared Components > Workflows*: **Utilization** lista páginas e componentes que usam cada workflow; **History** mostra modificações recentes. Equivalentes existem para Task Definitions, Email Templates, Search Configurations, AI Agents e Generative AI Services.

Fonte: [About Workflow Reports](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-workflow-reports.html)

### Workflows no APEXlang: componentes workflow e taskDefinition

No export APEXlang (`.apx`), os componentes ficam sob `app`: `workflow` (filhos `parameter`, `version`), `taskDefinition` (filhos `action`, `parameter`, `participant`), `automation` (filhos `action`, `parameter`), `emailTemplate`, `searchConfig` (filho `parameter`), `aiAgent` (filho `tool`) e `vectorProvider`. Consulte o documento 09 (APEXlang) para a sintaxe; os nomes de propriedade seguem a referência APEXlang.

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

---

## 5. Human tasks (Task Definitions, aprovações e tarefas de ação)

### Human tasks: Approval Task × Action Task e os blocos de construção

**Human tasks** são itens de trabalho feitos por pessoas. Há dois tipos, escolhidos **só na criação** (errou, crie outra definição):

| Tipo | Uso | Desfecho | Botões gerados |
|---|---|---|---|
| **Approval Task** | aprovar ou rejeitar (ex.: pedido de laptop) | outcome `APPROVED` / `REJECTED` | Approve / Reject (inclusive como ações rápidas na lista) |
| **Action Task** | executar algo e marcar como feito (ex.: autoavaliação) | sem outcome | Complete (e Save) |

Blocos: **Task Definition** (shared component em *Workflows and Automations > Task Definitions*), **Unified Task List** (tipo de página "inbox"), **Task Details Page**, page processes **Human Task - Create** e **Human Task - Manage**, e pacote **`APEX_HUMAN_TASK`**. Por padrão, numa approval task **o iniciador não pode aprovar a própria task** (mesmo sendo potential owner; o engine o filtra), salvo *Initiator Can Complete*. Numa action task o iniciador pode concluir. Exige `CREATE JOB` no parsing schema.

Alterar uma Task Definition **não afeta tasks já criadas**, só as novas.

Fonte: [About Tasks](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-tasks.html), [About Task Definitions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-task-definitions.html), [Deciding if Task Needs an Outcome](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/deciding-if-task-needs-outcome.html), [Assigning Work to a User's Task Inbox](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/assigning-work-users-task-inbox.html)

### Criar uma Task Definition: atributos de Settings

Wizard (*Create*): Name, Type, **Subject** (aceita `&PARAM.` e colunas da Actions Source, ex. `Requisição do pedido &ORDER_ID.`; não aceita template directives), **Static ID** (usado em `APEX_HUMAN_TASK.CREATE_TASK`), **Priority** (1 Urgent … 5 Lowest; padrão 3 Medium), Potential Owner, Business Admin. Depois, na página de detalhes:

| Atributo | Descrição |
|---|---|
| Initiator Can Complete | (approval) On = iniciador pode aprovar/rejeitar; Off (padrão) |
| Task Details Page Number | página de detalhes existente, ou botão *Create Task Details Page* (vazio = próxima livre). Vira um *Task Details Page URL* `f?p=&APP_ID.:6:&SESSION.::&DEBUG.:RP,6:P6_TASK_ID:&TASK_ID.`; pode acrescentar `&P6_ID=&DETAIL_PK.` |
| Actions Source | Table (+ coluna PK) ou SQL Query (uma linha; pode usar `:APEX$TASK_PK`) |
| Due On Type | Interval (duração ISO/SQL positiva), SQL Query, Function Body, Expression, Scheduler Expression (ex. `first Friday of the month at 4:00 p.m.`) |
| Expiration Policy | None (padrão; continua aprovável após vencer), Expire, Renew (+ Maximum Renewal Count, até **99**) |
| Before Expire Interval | dispara a ação *Before Expire* |
| Vacation Rule Procedure | `[schema.[package]].procedure` |
| Participants, Parameters, Actions | ver seções seguintes |

Copiar (*Copy*, desta ou de outra app) leva settings, prazo, participantes, ações e parâmetros e copia shared components usados (email templates, REST Data Sources), mas **não** a Task Details Page nem subscriptions: reconfigure o número da página depois.

Fonte: [Creating a Task Definition](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-task-definitions.html), [Adding a Task Details Page](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/adding-task-details-page.html), [Copying a Task Definition](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/copying-task-definitions.html), [Computing Subject and Action Values](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/computing-subject-and-action-values.html)

### Actions Source e Details Primary Key: ligar a task a uma linha de negócio

Configure a *Actions Source* (tabela + PK, ou query de uma linha filtrando `:APEX$TASK_PK`) e, ao criar a task, passe o **Details Primary Key** (item no page process, item do workflow, ou `p_detail_pk`). Então, em subject, participantes e ações, qualquer coluna vale como `&NOME.` (texto) e `:NOME` (código). Com query você junta tabelas e **calcula** valores (subject dinâmico, lista de e-mails dos potential owners):

```sql
select r.id as request_id, r.empno, r.new_salary, e.ename, e.sal
  from emp_sal_change_request r
  join emp e on e.empno = r.empno
 where r.id = :APEX$TASK_PK
```

Dica de modelagem da doc: se você está criando muitos parâmetros para uma task, provavelmente falta uma **tabela de solicitação**; grave a solicitação, passe a PK e use só o `APEX$TASK_PK`.

Pegadinha conhecida: `APEX$TASK_ID` **não funciona** na query da Actions Source (o ID só existe depois da criação); use `APEX$TASK_PK`.

Fonte: [Associating a Table with a Task](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/associating-table-task.html), [Accepting Input Values in Parameters](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/accepting-input-values-parameters.html), [Updating Request Columns on Complete](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/updating-request-columns-complete.html), [Troubleshooting Tasks](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/troubleshooting_tasks.html)

### Parâmetros de Task Definition: Required, Visible e Updatable

Cada parâmetro tem Static ID, Label, Data Type (`String`), **Required**, **Visible** (aparece na Task Details; em página custom filtre `is_visible = 'Y'` em `APEX_TASK_PARAMETERS`) e **Updatable** (o actual owner pode editar depois de criada; serve para coletar dados do aprovador). Referência: `&STATIC_ID.` ou `:STATIC_ID`. Parâmetros definidos precisam ser atribuídos no page process/atividade (Required sem valor = erro ao salvar a página).

APIs: `GET_TASK_PARAMETER_VALUE(p_task_id, p_param_static_id, p_ignore_not_found default false)`, `SET_TASK_PARAMETER_VALUES(p_task_id, p_parameters, p_raise_error default true)` (só atualizáveis; owner ou admin), e na ação *Update Parameter*: `HAS_TASK_PARAM_CHANGED`, `GET_TASK_PARAMETER_OLD_VALUE`.

Exemplo (assignee parametrizado): participante Potential Owner do tipo Expression `:P_REQUESTED_USERNAME`.

Fonte: [Creating a Task Definition](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-task-definitions.html), [Defining Updatable Task Parameters](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/defining-updatable-task-parameters.html), [Controlling Parameter Visibility](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/controlling-parameter-visibility.html), [Parameterizing the Task Assignee](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/parameterizing-task-assignee.html)

### Participantes de task: Potential Owner, Business Administrator e exclusões

| Participant Type | Pode |
|---|---|
| **Potential Owner** | ver na "My Tasks", **claim** (vira actual owner); vários possíveis |
| **Actual Owner** (quem reivindicou/foi designado) | aprovar/rejeitar/concluir, pedir informação, atualizar parâmetros, delegar, release |
| **Business Administrator** | renovar expiradas, delegar/reatribuir, convidar/remover potential owners, cancelar, mudar prioridade e prazo |
| **Excluded Owner** / **Excluded Admin** | não podem ser owner/admin daquela definição (identity type sempre User) |
| **Initiator** | cria, responde a pedidos de informação, cancela |

*Identity Type*: **User** (Value Type Static, SQL Query (um username por linha), Function Body ou Expression (lista separada por vírgulas)) ou **Authorization Scheme** (Value Type Static = nome do esquema; funciona como "grupo"). Combine com Excluded Owner/Admin para tirar pessoas do grupo. Usernames **case-sensitive** (contas APEX em maiúsculas). Boa prática: uma função de package genérica `owners_for_task(:APEX$TASK_ID, :APEX$TASK_PK)` e, para notificar, `owner_emails_for_task` lendo `APEX_TASK_PARTICIPANTS` ⨝ `APEX_WORKSPACE_APEX_USERS` (`participant_type = 'POTENTIAL_OWNER'`).

`APEX_TASK_PARTICIPANTS` pode divergir da definição (convites/remoções de admin). `REFRESH_BUSINESS_ADMINS(p_task_id)` reavalia admins (não em Expired, Errored, Completed, Cancelled).

Fonte: [About Task Definitions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-task-definitions.html), [Determining Task Participants](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/determining-task-participants.html), [Assigning Participants Dynamically](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/assigning-participants-dynamically.html), [Editing a Task Definition](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-task-definitions.html), [Studying Generic Assignee Code](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/studying-generic-assignee-code.html)

### Vacation rules: substitutos para participantes ausentes

Procedure PL/SQL que devolve participantes alternativos. Pode ser definida no **nível da aplicação** (vale para todas as definições) ou da Task Definition (que **sobrepõe** a da app). É avaliada na **criação** (os substitutos são adicionados aos participantes) e na **delegação** (delega ao primeiro alternativo). Assinatura exata (nomes, modos e ordem):

```plsql
procedure handle_absences(
    p_param   in  apex_human_task.t_vacation_rule_input,
    p_result  out apex_human_task.t_vacation_rule_result )
is
    function po(p_user varchar2) return apex_human_task.t_task_participant is
    begin
        return apex_human_task.t_task_participant(
                   apex_human_task.c_task_potential_owner,
                   apex_human_task.c_task_identity_type_user,
                   p_user);
    end;
begin
    for j in 1 .. p_param.original_participants.count loop
        if p_param.original_participants(j).type  = apex_human_task.c_task_potential_owner
           and p_param.original_participants(j).value = 'DAVID' then
            p_result.participant_changes(p_result.participant_changes.count + 1) :=
                apex_human_task.t_task_participant_change(po('DAVID'), po('SUSAN'), 'Férias');
            p_result.has_participant_changes := true;
        end if;
    end loop;
end handle_absences;
```

`t_vacation_rule_input` traz `task_def_static_id`, `task_id`, `priority`, `original_participants`, `parameters`, `due_date`, `detail_pk`. O motivo vai para `APEX_TASK_HISTORY.PARTICIPANT_CHANGED_REASON` (não aparece por padrão na Task Details gerada). Em produção, leia as ausências de uma tabela. (A página "Creating a Task Definition" mostra o tipo de saída como `t_vacation_rule_output`; o tipo documentado no pacote é `t_vacation_rule_result`.)

Fonte: [Accounting for Vacations or Absences](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/accounting-vacations-or-absences.html), [Editing a Task Definition](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-task-definitions.html), [APEX_HUMAN_TASK Constants and Data Types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.Constants-and-Data-Types.html)

### Prazos e expiração de tasks: Due On, Expire, Renew e Before Expire

Sem prazo, a task é aberta indefinidamente. Com **Due On** a lista mostra vencimento e permite ordenar por ele; o business admin pode mudar o prazo (`SET_TASK_DUE`, data futura; não em Expired/Errored/Completed/Canceled). Depois do vencimento:
- **None**: só aparece como atrasada.
- **Expire**: fecha como Expired (não pode mais ser aprovada).
- **Renew**: fecha como Expired e cria nova task ligada (`APEX$TASK_PREVIOUS_ID`), até o máximo de renovações; a Task Details mostra a cadeia de renovações. A lógica de participantes pode usar `:APEX$TASK_RENEWAL_COUNT`.

Use ação **Before Expire** para lembrete e **Expire** para reagir. O job `ORACLE_APEX_TASKS_EXPIRE` roda **de hora em hora**; para testar, chame `APEX_HUMAN_TASK.HANDLE_TASK_DEADLINES`. Admin também pode renovar uma task Expired ou Errored com `RENEW_TASK(p_task_id, p_priority, p_due_date) return number`.

Fonte: [Handling Time-Sensitive Tasks](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/handling-time-sensitive-tasks.html), [Creating a Task Definition](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-task-definitions.html), [HANDLE_TASK_DEADLINES Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.HANDLE_TASK_DEADLINES-Procedure.html), [DBMS_SCHEDULER Jobs](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/dbms_scheduler-jobs.html)

### Task Definition Actions: eventos, tipos e tratamento de erro

Ações reagem a eventos do ciclo de vida. Tipos: **Execute Code** (Local Database ou REST Enabled SQL; PL/SQL), **Send E-Mail** (From, To, Cc, Bcc, Reply To, Email Template + placeholders, Subject, Body Plain/HTML, Attachment SQL), **Send Push Notification** (To = username, Title, Body, Link Target) ou plug-in de processo com *Supported For: Task Definition Actions*. Executam em ordem de *Execution Sequence*; podem ter Server-side Condition, Build Option e, no Complete, filtro por *Outcome*.

| Evento | Quando |
|---|---|
| Create | iniciador cria a task |
| Claim | potential owner reivindica |
| Delegate | delegação |
| Update Comment | novo comentário (`APEX$TASK_TEXT`) |
| Update Priority | mudança de prioridade |
| Update Parameter | owner muda parâmetro atualizável |
| Release | owner libera |
| Cancel | cancelamento |
| Request Information / Submit Information | pedido e resposta de informação (`APEX$TASK_TEXT`) |
| Before Expire | faltando menos que o Before Expire Interval |
| Expire | expirou |
| Complete | concluída (`APEX$TASK_OUTCOME` em approval) |

*Error Handling*: **Error Message** (use `#SQLERRM#`), **Stop Execution on Error** (para as próximas ações e leva a task a `ERRORED`), **Log Messages When** None (padrão), Success, Failure, All (grava Success/Error Message no histórico). `APEX_HUMAN_TASK.ADD_TO_HISTORY(p_message)` grava mensagem custom. Ao testar Request/Submit Information, iniciador e owner precisam ser usuários diferentes.

```plsql
-- ação Execute Code no evento Complete
if :APEX$TASK_OUTCOME = 'APPROVED' then
   update emp set sal = :P_PROPOSED_SALARY where empno = :EMPNO;
end if;
```

Fonte: [Creating a Task Definition](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-task-definitions.html), [Choosing Event for an Action](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/choosing-event-action.html), [Managing Task Details](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-task-details.html), [Updating Entity Columns on Complete](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/updating-entity-columns-complete.html), [About Creating a Task Definition Process Plug-in](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-creating-task-definition-process-plugins.html)

### Substitution strings e binds de task (APEX$TASK_*)

| Nome | Conteúdo |
|---|---|
| `APEX$TASK_ID` | ID da task |
| `APEX$TASK_PK` | Details Primary Key (bind `:APEX$TASK_PK` em ações e participantes) |
| `APEX$TASK_STATE` | estado |
| `APEX$TASK_OUTCOME` | `APPROVED`/`REJECTED` (approval concluída) |
| `APEX$TASK_SUBJECT` | assunto |
| `APEX$TASK_CREATED_ON`, `APEX$TASK_DUE_ON` | timestamps `YYYY-MM-DD"T"HH24:MI:SS.FF3TZH:TZM` |
| `APEX$TASK_INITIATOR`, `APEX$TASK_OWNER` | usernames (case-sensitive) |
| `APEX$TASK_RENEWAL_COUNT`, `APEX$TASK_MAX_RENEWAL_COUNT`, `APEX$TASK_PREVIOUS_ID` | renovação |
| `APEX$TASK_TEXT` | texto de comentário / pedido / resposta de informação |

Na URL de Task Details: `&TASK_ID.` e `&DETAIL_PK.`.

Fonte: [Task Substitution Strings and Bind Variables](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/substitution-strings-for-tasks.html), [Accessing Task Information](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/accessing-task-information.html)

### Estados de task e transições (ciclo de vida)

| Estado (código) | Estágio | Transições |
|---|---|---|
| Created | inicial | Unassigned (vários potential owners), Assigned (um só), Errored |
| Unassigned (`UNASSIGNED`) | intermediário | Assigned (claim/delegate), Completed (aprovação direta pela lista), Errored, Canceled, Expired |
| Assigned (`ASSIGNED`) | intermediário | Completed, Unassigned (release), Info Requested, Assigned (delegate), Errored, Canceled, Expired |
| Info Requested (`INFO_REQUESTED`) | intermediário | Assigned (submit information), Expired |
| Completed (`COMPLETED`) | final | — |
| Errored (`ERRORED`) | final (exceção) | renovável pelo admin (nova task) |
| Canceled (`CANCELLED`) | final | — |
| Expired (`EXPIRED`) | final | Renew automático se política Renew e abaixo do máximo; senão admin pode renovar |

Errored: erro de banco, bug, definição inválida ou falha numa ação com *Stop Execution on Error*. O estado é exibido em mixed case ("Information Requested") e o código em maiúsculas. Comentar não muda estado.

Fonte: [About Task States and Transitions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-task-states-and-transitions.html), [Understanding Task States](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-task-states.html)

### Page process Human Task - Create

Process type **Human Task - Create** (exige uma Task Definition). Settings: Definition; Subject, Priority, Initiator Can Complete (sobrepõem a definição); **Initiator Item** (padrão = usuário logado; permite criar em nome de outro); **Task ID Item** (recebe o ID); **Details Primary Key Item** (PK da Actions Source); **Due Date Item** (sobrepõe o prazo). Parâmetros da definição aparecem na árvore (Static Value ou Item). Exemplo típico: Processing, When Button Pressed `SUBMIT_FOR_APPROVAL`, Details Primary Key Item `P7_EMPNO`, parâmetro `New Job` ← `P7_PROPOSED_JOB`.

Equivalente em PL/SQL:

```plsql
APEX_HUMAN_TASK.CREATE_TASK (
    p_application_id         IN NUMBER   DEFAULT apex_application.g_flow_id,
    p_task_def_static_id     IN VARCHAR2,
    p_subject                IN VARCHAR2 DEFAULT NULL,
    p_parameters             IN t_task_parameters DEFAULT c_empty_task_parameters,
    p_priority               IN INTEGER  DEFAULT NULL,
    p_initiator              IN VARCHAR2 DEFAULT NULL,
    p_initiator_can_complete IN BOOLEAN  DEFAULT NULL,
    p_detail_pk              IN VARCHAR2 DEFAULT NULL,
    p_due_date               IN TIMESTAMP WITH TIME ZONE DEFAULT NULL )
RETURN NUMBER;
```

Um potential owner → Assigned; vários → Unassigned; **nenhum → exceção**. `t_task_parameter` = (`static_id`, `string_value`).

Fonte: [Creating Tasks from Task Definitions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-tasks-from-task-definitions.html), [Example: Creating a Human Task from a Form Submission](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-tasks-example.html), [CREATE_TASK Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.CREATE_TASK-Function.html)

### Unified Task List: inbox de tarefas e customização com GET_TASKS

Create Page Wizard > *Unified Task List*. Report Context:

| Contexto | Mostra | Constante |
|---|---|---|
| My Tasks | Assigned ao usuário ou Unassigned em que ele é potential owner (não mostra concluídas); ordena por criação desc. | `MY_TASKS` |
| Admin Tasks | tasks em que é business admin, inclusive Errored, Completed, Canceled; Expired só com "Show expired tasks" | `ADMIN_TASKS` |
| Initiated by Me | tasks que iniciou | `INITIATED_BY_ME` |

Gera Content Row + **Smart Filters** + Order By (criação ou vencimento). Pode ficar em outra app do mesmo workspace (exige **session sharing**, senão "Your session has ended" ao abrir detalhes). Respeita Tenant ID da sessão. Por padrão lista **todas as apps do workspace**: descomente `p_application_id => :APP_ID`.

```sql
select t.task_id, t.subject, t.state, t.badge_state, t.due_on,
       c.nome_completo as colaborador
  from table(apex_human_task.get_tasks(
                 p_context            => 'MY_TASKS',
                 p_show_expired_tasks => :P33_SHOW_EXPIRED,
                 p_application_id     => :APP_ID)) t
  left join colaborador c
    on c.id_colaborador = case t.task_def_static_id when 'CORRECAO' then to_number(t.detail_pk) end
 where t.task_def_static_id in ('CORRECAO')
```

Colunas úteis de `GET_TASKS`: `task_id`, `subject`, `state_code`, `state`, `initiator`, `actual_owner`, `detail_pk`, `task_def_static_id`, `details_link_target`, `due_on`, `priority`, `outcome_code`, `badge_css_classes`, `tenant_id`… `GET_TASKS` só devolve dados com sessão APEX (vazio no SQL Workshop).

Fonte: [Managing Unified Task Lists](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-unified-task-lists.html), [Tailoring Task List to Purpose](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/tailoring-task-list-purpose.html), [Showing Only Current Application Tasks](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/showing-only-current-application-tasks.html), [Joining Extra Tables into Task List](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/joining-extra-tables-task-list.html), [GET_TASKS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.GET_TASKS-Function.html)

### Task Details Page: operações disponíveis e personalização

A página gerada mostra metadados, parâmetros (região Details com `PARAM_LABEL`/`PARAM_VALUE` e link Edit para atualizáveis quando o usuário é o actual owner), comentários, histórico e botões conforme estado e papel: Claim, Release, Delegate, Set Priority, Set Due Date, Request Information, Submit Information, Invite Participant, Remove Participant, Exclude Participant (admin), Cancel, Renew, Approve/Reject (approval), Save/Complete (action), Comment, Update Parameter. A doc recomenda **uma Task Details por Task Definition**, ajustada.

Personalizações documentadas:
- Trocar a região Details por **page items** (Number Field, Value Required, Storage *Per Request (Memory Only)*), carregar com computation Pre-Rendering `apex_human_task.get_task_parameter_value(:P6_TASK_ID,'P_VALUE1')`, validar (condição de request `/SAVE/COMPLETE/`) e gravar com `apex_human_task.set_task_parameter_values(:P6_TASK_ID, apex_human_task.t_task_parameters(1 => apex_human_task.t_task_parameter('P_VALUE1', :P6_VALUE1)))`.
- Read Only condicional: só editável se existir linha em `select task_id from apex_tasks where task_id = :P6_TASK_ID and actual_owner = :APP_USER and state_code = 'ASSIGNED'`.
- Form da entidade: preencher `P6_ID` com `select detail_pk from apex_tasks where task_id = :P6_TASK_ID` (ou URL com `&DETAIL_PK.`) antes do Form - Initialization; Automatic DML condicionado aos botões `SAVE`/`COMPLETE` (em approval: `APPROVE`/`REJECT`).

Fonte: [Managing Task Details](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-task-details.html), [Fine-Tuning a Task Details Page](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/fine-tuning-task-details-page.html), [Loading Parameter Values Into Items](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/loading-parameter-values-items.html), [Making Items Conditionally Read Only](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/making-items-conditionally-read-only.html), [Saving Page Items to Task Parameters](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/saving-page-items-task-parameters.html), [Working with a Business Entity Row](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/working-business-entity-row.html)

### APEX_HUMAN_TASK: operações, quem pode e estados

Pacote do ciclo de vida das tasks; requer sessão APEX.

| Rotina | Quem pode | Pré → pós-estado |
|---|---|---|
| `CLAIM_TASK(p_task_id)` | potential owner | UNASSIGNED → ASSIGNED |
| `APPROVE_TASK(p_task_id, p_autoclaim default false)` / `REJECT_TASK` | potential ou actual owner | ASSIGNED (ou UNASSIGNED com autoclaim) → COMPLETED |
| `COMPLETE_TASK(p_task_id, p_outcome default null, p_autoclaim)` | actual/potential owner | idem; outcome para approval |
| `RELEASE_TASK(p_task_id)` | actual owner | ASSIGNED → UNASSIGNED |
| `DELEGATE_TASK(p_task_id, p_to_user)` | actual owner ou admin | UNASSIGNED/ASSIGNED → ASSIGNED |
| `REQUEST_MORE_INFORMATION(p_task_id, p_text, p_to_user default null)` | actual owner | → INFO_REQUESTED (vai ao iniciador ou a `p_to_user`) |
| `SUBMIT_INFORMATION(p_task_id, p_text)` | iniciador | → ASSIGNED |
| `CANCEL_TASK(p_task_id)` | iniciador ou admin | não COMPLETED/ERRORED → CANCELED |
| `ADD_TASK_COMMENT(p_task_id, p_text)` | potential owner ou admin | — |
| `ADD_TASK_POTENTIAL_OWNER(p_task_id, p_potential_owner, p_identity_type default USER)` | admin | erro se COMPLETED/ERRORED |
| `REMOVE_POTENTIAL_OWNER`, `EXCLUDE_POTENTIAL_OWNER` | admin | |
| `SET_TASK_PRIORITY(p_task_id, p_priority 1..5)` | admin ou iniciador | não COMPLETED/ERRORED |
| `SET_TASK_DUE(p_task_id, p_due_date)` | admin | data futura |
| `SET_INITIATOR_CAN_COMPLETE(p_task_id, boolean)` | admin | |
| `RENEW_TASK(...) return number` | admin | EXPIRED/ERRORED → nova task |
| `SET_TASK_PARAMETER_VALUES`, `GET_TASK_PARAMETER_VALUE`, `GET_TASK_PARAMETER_OLD_VALUE`, `HAS_TASK_PARAM_CHANGED` | | parâmetros |
| `GET_TASKS`, `GET_TASK_HISTORY(p_task_id, p_include_all default 'N')`, `GET_TASK_DELEGATES`, `GET_TASK_PRIORITIES`, `GET_LOV_PRIORITY/STATE/TYPE` | | consultas (exigem sessão) |
| `IS_ALLOWED(p_task_id, p_operation, p_user, p_new_participant)`, `IS_BUSINESS_ADMIN`, `IS_OF_PARTICIPANT_TYPE` | | checagens |
| `ADD_TO_HISTORY(p_message)` | dentro de ação | |
| `HANDLE_TASK_DEADLINES`, `REFRESH_BUSINESS_ADMINS`, `DELETE_TASKS(p_application_id, p_static_id, p_states, p_include_workflow_tasks default false)`, `GET_NEXT_PURGE_TIMESTAMP` | | manutenção |

Constantes: tipos `c_task_type_approval`/`_action`; contextos `c_context_my_tasks`, `_admin_tasks`, `_initiated_by_me`, `_single_task`; participantes `c_task_potential_owner`, `c_task_business_admin`, `c_task_initiator`, `c_task_info_requested_from`, `c_task_excluded_owner`, `c_task_excluded_admin`; identidade `c_task_identity_type_user`/`_auth`; prioridades `c_task_priority_urgent` (1) … `_lowest` (5); estados `c_task_state_*`; outcomes `c_task_outcome_approved`/`_rejected`; operações `c_task_op_*` (`APPROVE_TASK`, `CLAIM_TASK`, `DELEGATE_TASK`…).

Fonte: [APEX_HUMAN_TASK](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.html), [Constants and Data Types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.Constants-and-Data-Types.html), [APPROVE_TASK Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.APPROVE_TASK-Procedure.html), [REQUEST_MORE_INFORMATION Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.REQUEST_MORE_INFORMATION-Procedure.html)

### Views de tasks: definição e runtime

| Definição | Runtime |
|---|---|
| `APEX_APPL_TASKDEFS` | `APEX_TASKS` (propriedades da instância: `task_id`, `detail_pk`, `state_code`, `actual_owner`, `task_def_static_id`, `created_on`…) |
| `APEX_APPL_TASKDEF_PARAMS` | `APEX_TASK_PARAMETERS` (valores em string, `is_visible`) |
| `APEX_APPL_TASKDEF_PARTICIPANTS` | `APEX_TASK_PARTICIPANTS` |
| `APEX_APPL_TASKDEF_ACTIONS` | `APEX_TASK_HISTORY` (operações, usuário, data, `participant_changed_reason`) |
| | `APEX_TASK_COMMENTS` |
| | `APEX_PURGEABLE_TASKS`, `_TASK_HISTORY`, `_TASK_COMMENTS`, `_TASK_PARAMETERS` |

```sql
-- ação no Complete gravando métricas permanentes
insert into eba_demo_appr_metrics(task_def_static_id, outcome_code, approver, days_elapsed, approval_date)
select task_def_static_id, outcome_code, actual_owner, sysdate - cast(created_on as date), sysdate
  from apex_tasks where task_id = :APEX$TASK_ID;
```

Fonte: [Runtime Views for Tasks](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/runtime-views-for-tasks.html), [Accessing Workflow and Task Data](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/accessing-workflow-and-task-data.html), [Editing a Task Definition](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-task-definitions.html)

### Notificar assignees na criação da task (ação Send E-Mail no evento Create)

Padrão: Actions Source Query que calcula `computed_subject` (CASE para partes opcionais) e `potential_owners_emails` (função do package); Subject da definição = `&COMPUTED_SUBJECT.`; ação **Create** do tipo Send E-Mail com To = `&POTENTIAL_OWNERS_EMAILS.`, Email Template e placeholder `NEW_TASK_SUBJECT` = `&APEX$TASK_SUBJECT.` (botão *Set Placeholder Values*).

Fonte: [Notifying Assignees on Create](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/notifying-assignees-create.html), [Sending Email on Task Creation](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/sending-email-task-creation.html), [Formatting Email with Templates](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/formatting-email-templates.html)

### Exemplo de referência: app Sample Workflows, Approvals, and Tasks

A app de galeria **Sample Workflows, Approvals, and Tasks** traz: approval de salário (Task Details customizada), de cargo (Task Details padrão), de conta bancária (*Initiator Can Complete* On), workflow de avaliação (action tasks para empregado, gestor e VP com Invoke API e Switch), workflow de laptop (approval + action task concluída programaticamente na entrega, e-mails, Wait), três listas (My Tasks, My Requests, Task Administration) e console de workflows. A página *More Information* da app explica os recursos. Útil como modelo antes de criar do zero.

Fonte: [Example: Approval Tasks and Action Tasks](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/example-tasks.html), [Example: Workflows](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/example-workflows.html)

---

## 6. Execution Chains e execução em background

### Execution Chain: agrupar processos como um esboço de lógica

O process type **Execution Chain** agrupa processos-filho (qualquer tipo: Execute Code, Invoke API, Send E-Mail, Send Push, Data Loading, Workflow, Generate Text with AI, impressão…) executados **em sequência**. Sua Server-side Condition decide se os filhos rodam; chains podem ser **aninhadas** (*Identification > Execution Chain* = pai; `None` = topo). Com nomes descritivos ("Se enviando boas-vindas...", "Se o usuário é gestor...") a árvore de processamento vira um esboço legível. Filhos são reordenados por drag-and-drop ou *Sequence*; criados com *Create Child Process*.

A chain pode rodar **em foreground** (só organização) ou **em background**.

Fonte: [Grouping Logic and Background Execution](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/grouping-logic-and-background-execution.html), [Outlining Logic Using Execution Chains](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/outlining-logic-using-execution-chains.html), [Nesting Execution Chains](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/nesting-execution-chains.html), [Sequencing Child Processes](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/sequencing-child-processes.html)

### Run in Background: atributos da Execution Chain

| Atributo (Settings) | Comportamento |
|---|---|
| **Execute in Background** (Run in Background) | enfileira um job e segue para o próximo processo da página imediatamente |
| **Return Execution ID into Item** | item que recebe o ID da execução (para consultar status) |
| **Context Value Item** | valor associado ao job (coluna `CONTEXT_VALUE` na view de status), ex. o ID do registro processado |
| **Serialize Executions** | só uma execução por vez daquele chain (de todas as sessões); com Context Value, serializa **por valor** |
| **When Already Running** | `Error` (com *Error Message*) ou esperar a vez |
| **Temporary File Handling** | `Ignore` (arquivos ficam na sessão do usuário), `Move` (vão para a sessão do job; um único chain precisa deles), `Copy` (ficam e são copiados; vários chains) + **Temporary File Items** (lista de File/Image Upload) |
| **Executions Limit** | máximo de execuções em background **por usuário** daquele chain; excedeu → erro |

Fluxo no enfileiramento: gera ID de execução, cria sessão exclusiva e **clona o session state** do usuário. A partir daí o job tem estado próprio; mudanças não afetam a sessão do usuário nem outros jobs. O job vê `APEX_APPLICATION_TEMP_FILES` normalmente se os arquivos foram movidos/copiados. É executado pelo `DBMS_SCHEDULER` (`ORACLE_APEX_BG_PROCESSES`, a cada 2 min), então exige `CREATE JOB`.

Fonte: [Understanding Background Page Processing](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-background-page-processing.html), [Configuring Chain to Run in Background](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configuring-chain-run-background.html), [Serializing Background Process Jobs](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/serializing-background-process-jobs.html), [Configuring Temporary File Handling](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configuring-temporary-file-handling.html), [Isolating Background Session State](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/isolating-background-session-state.html)

### Limites e recursos de jobs em background (chain, app, workspace, instância)

Do mais específico ao mais geral:
1. **Executions Limit** do chain: erro para o usuário que passar do limite.
2. **Maximum Background Page Process Jobs** da aplicação (Application Definition > Properties): enfileira o excedente (ficam esperando). Valor maior que o do workspace é ignorado.
3. **Maximum Background Page Process Jobs** do workspace (Workspace Isolation, instance admin): teto para todas as apps; sobrepõe o parâmetro de instância `MAX_PROCESS_SCHEDULER_JOBS_DEFAULT`.
4. Instância: atributos *Background Jobs* em Instance Settings (padrão para workspaces).

Para dar mais recursos a jobs longos, um DBA (ou `APEX_ADMINISTRATOR_ROLE`) define uma job class própria:

```plsql
begin
   apex_instance_admin.set_parameter(
      p_parameter => 'BACKGROUND_PROCESS_JOB_CLASS',
      p_value     => 'CUSTOM_BG_PROC_CLASS');
end;
```

Fonte: [Limiting and Throttling Background Jobs](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/limiting-and-throttling-background-jobs.html), [Adjusting Resources for Background Jobs](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/adjusting-resources-background-jobs.html), [Understanding Background Page Processing](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-background-page-processing.html)

### Reportar progresso: APEX_BACKGROUND_PROCESS e APEX_APPL_PAGE_BG_PROC_STATUS

No código do job:

```plsql
apex_background_process.set_progress(p_totalwork => 9, p_sofar => 3);
apex_background_process.set_status('Gerando certificado');
```

`SET_PROGRESS(p_totalwork default null, p_sofar)` (total desconhecido: só `p_sofar`) e `SET_STATUS(p_message)` atuam na execução corrente; `GET_CURRENT_EXECUTION` devolve `t_execution` (`id`, `state`, `current_exec_process_id`, `last_status_message`, `sofar`, `totalwork`; vazio fora de background); `GET_EXECUTION(p_application_id, p_execution_id)` consulta outra; `TERMINATE(p_application_id, p_execution_id)` ou `TERMINATE(p_application_id, p_process_id)` (todas do chain). `ABORT` está **deprecated** (use `TERMINATE`).

Na página, consulte a view **`APEX_APPL_PAGE_BG_PROC_STATUS`** (`EXECUTION_ID`, `PROCESS_ID`/`PROCESS_NAME`, `CURRENT_PROCESS_ID`/`_NAME`, `SESSION_ID`, `WORKING_SESSION_ID`, `CONTEXT_VALUE`, `STATUS_CODE`, `STATUS_MESSAGE`, `SOFAR`, `TOTALWORK`, `APPLICATION_ID`, `PAGE_ID`). Status: `ENQUEUED` (aguardando coordenador), `SCHEDULED` (job criado, não iniciado), `EXECUTING`, `SUCCESS`, `FAILED`, `ABORTED` (terminado).

```sql
select bgp.context_value,
       round(bgp.sofar/bgp.totalwork*100)||'%' as progress,
       nvl(bgp.sofar/bgp.totalwork,0)           as progress_bar,  -- Percent Graph espera 0..1
       coalesce(bgp.status_message,'⏳') as status_message
  from apex_appl_page_bg_proc_status bgp
 where bgp.process_name   = 'Revisar (em background)'
   and bgp.application_id = :APP_ID
   and bgp.page_id        = :APP_PAGE_ID
   and bgp.status_code in ('ENQUEUED','SCHEDULED','EXECUTING')
```

Exiba barra com coluna do tipo **Percent Graph** (valor decimal de 0 a 1). Classes `u-lineclamp-1..5` limitam linhas de texto.

Fonte: [Reporting Background Process to Users](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/reporting-background-process-users.html), [Accessing Background Process Status](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/accessing-background-process-status.html), [Querying Progress of Background Process](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/querying-progress-background-process.html), [Showing Background Process Progress Bar](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/showing-background-process-progress.html), [APEX_BACKGROUND_PROCESS](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/apex_background_process.html), [Constants](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_BACKGROUND_PROCESS-Constants.html)

### Monitorar, terminar e depurar jobs em background

- Developer Toolbar > *Session* (View Session State) ou *Debug > View Debug* > aba Session > **View: Background Executions** > Set: lista status, mensagem atual, So far, Total work, Context; filtro por status; botão **Terminate**.
- Falhas: filtre *Failed*, abra o debug trace na aba Debug; os pontos vermelhos na linha do tempo levam ao erro e ao stack.
- Session state do job: *Monitor Activity > Active Sessions > sessão do usuário > Background Processing > Work Session ID > Session State Item Values* (itens criptografados não aparecem; use `apex_debug.info`).

Fonte: [Debugging Background Processes](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/debugging-background-processes.html), [Reviewing App Background Processes](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/reviewing-app-background-processes.html), [Investigating Background Process Errors](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/investigating-background-process-errors.html), [Viewing Background Process Session State](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/viewing-background-process-session-state.html), [Understanding Background Page Processing](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-background-page-processing.html)

### Reimportar aplicação que tem processos em background

Ao reimportar por cima de uma app com execution chains em background, o wizard avisa e oferece **Disable Background Execution** (zera Maximum Scheduler Jobs, impedindo novas execuções, e volta à página) ou **Replace Application** (instala já; execuções em andamento são terminadas e as em espera são apagadas). Planeje deploys fora do horário de uso.

Fonte: [Importing Export Files](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/importing-export-files.html), [Understanding Background Page Processing](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-background-page-processing.html)

### Exemplo: chain em background com PDF, e-mail com anexo e push

Receita da doc (Employee Excellence): chain "Revisar (em background)" com Context Value = ID do empregado, Serialize On + When Already Running = Error; filhos Invoke API (coleta, resumo com IA, predição com ML que devolve em `P34_RESULT`), chain aninhada "Se qualificado..." com: Invoke API que gera o PDF (`apex_print.generate_document` com Report Query por static ID) e guarda numa collection; Send E-Mail com **Attachment SQL**; Send Push Notification.

```sql
-- Attachment SQL: blob, nome, mime, content id (null = anexo normal)
select blob001 as contents, 'certificado.pdf' as file_name,
       'application/pdf' as mime_type, null as content_id
  from apex_collections
 where collection_name = 'EMP_EXCELLENCE_CERTIFICATE'
 fetch first row only
```

Content Id não nulo transforma o anexo em imagem inline referenciável no HTML (`<img src="cid:company_logo">`).

Fonte: [Offloading Work to the Background](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/offloading-work-background.html), [Printing Personalized Certificate](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/printing-personalized-certificate.html), [Emailing User with Attachments](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/emailing-user-attachments.html), [Choosing Descriptive Process Names](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/choosing-descriptive-process-names.html)

---

## 7. Automations

### Automations: conceitos (agendada × sob demanda, por linha × uma vez)

Uma **Automation** (Shared Components > Workflows and Automations > Automations) é um job recorrente ou sob demanda que executa uma sequência de **ações**:
- **Type**: `Scheduled` (roda pelo Schedule Expression) ou `On Demand` (só via `APEX_AUTOMATION.EXECUTE` ou botão no Builder).
- **Actions Initiated On**: `Query` (ações rodam por linha retornada, ou uma vez quando não há linhas), `Function Body Returning Boolean` (uma vez se TRUE) ou `Always`.
- **Source** (com Query): Local Database, REST Enabled SQL ou REST Data Source; Table ou SQL Query; *Execute Actions When* = Rows returned / No rows returned.
- Ações: Execute Code (local ou remoto), Send E-Mail, Send Push Notification, Server Side Geocoding (Autonomous), plug-ins de processo. Cada uma com Server-side Condition (*Execute for Each Row*). Colunas da linha são **binds** nas ações.
- Server-side Condition na própria automation.

Quando usar: varredura periódica (lembretes de vencimento, sincronizações, aprovações automáticas, processar fila de eventos). Quando não usar: trabalho disparado por um clique (use execution chain) ou processo multi-etapa com pessoas (workflow).

Fonte: [About Automations](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-automations.html), [Understanding Key Automation Concepts](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-key-automation-concepts.html), [Creating an Automation](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-an-automation.html)

### Atributos da Automation: Settings, Action Execution e Additional Code

| Seção / atributo | Valores e efeito |
|---|---|
| Name, **Static ID** | Static ID usado em `APEX_AUTOMATION.*` |
| Schedule Expression | sintaxe de calendário do `DBMS_SCHEDULER`; botão **Schedule Builder** (Interval Builder). Fuso: o do **servidor de banco**. `BACKGROUND_MIN_EXECUTION_CADENCE` limita o intervalo mínimo. |
| **Schedule Status** | `Active`, `Disabled` (não agenda, mas executa por API/Builder), `Error` (desabilitada por erro na última execução) |
| Execute Actions When | rows returned / no rows returned |
| Primary Key Column | valor gravado nas mensagens do log para correlacionar |
| **Commit** | após cada linha (`eachRow`) ou uma vez no fim (`once`, padrão) |
| Maximum Rows to Process | para e registra `Incomplete` |
| **Action Error Handling** | `Ignore` (padrão: segue para próxima ação/linha), `Terminate Automation` (para, continua agendada), `Disable Automation` (para e desabilita) |
| Additional Code Execution | PL/SQL inline + *Initialization Procedure*, *Before Row Processing Procedure*, *Cleanup Procedure* (nomes de procedures do schema ou definidas no bloco) |
| Server-Side Condition, Build Option, Comments | |

Após o wizard a automation nasce **Disabled** com uma ação "New Action". *Save and Run* executa em background imediatamente. No Builder, o botão "play" da lista executa uma vez (se Disabled) ou executa e calcula o Next Run (se Active). Em APEXlang: `execution { type, scheduleExpression, scheduleStatus, actionsInitiatedOn }`, `actionExecution { commit: once|eachRow, maxRowsToProcess, actionErrorHandling: ignore|terminate|disable }`, `additionalCodeExecution { plsqlCode, initProcedureName, … }`.

Fonte: [Editing an Existing Automation](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-an-existing-automation.html), [Creating an Automation](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-an-automation.html), [Running an Automation on Demand](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/running-automation-demand.html), [APEXlang: automation](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Ações de automation: binds, colunas temporárias e controle de fluxo

- Colunas da query viram binds (`:EMPNO`, `:ENAME`). Ações podem **atribuir** a colunas da linha (`:NEW_SALARY := ...`) como armazenamento temporário entre ações (sempre `VARCHAR2`, só em memória; o APEX **não grava** no banco: faça o `update` você mesmo). Truque: inclua `null as new_salary` na query.
- App items servem como estado compartilhado: inicialize na *Initialization Procedure* (inline pode usar `:G_ITEM`; externa precisa de `apex_session_state.set_value` e `v('G_ITEM')`).
- `APEX_AUTOMATION.SKIP_CURRENT_ROW(p_log_message)` pula as ações restantes daquela linha; `APEX_AUTOMATION.EXIT(p_log_message)` encerra a automation.
- Log: `LOG_INFO`, `LOG_WARN`, `LOG_ERROR`. `GET_LAST_RUN` (dentro da query/ação) devolve o timestamp da execução anterior, útil para processar só o que mudou.
- Sem `EXECUTE` na sessão atual, `:APP_USER` = `nobody`.

```plsql
if :RN = :G_LOTTERY_PICK then
    apex_automation.log_info(apex_string.format('Processando %s', :ENAME));
else
    apex_automation.skip_current_row('Pulando '||:ENAME);
end if;
```

Fonte: [Defining Automation Actions in Sequence](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/defining-automation-actions-sequence.html), [Identifying Automation Rows to Process](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/identifying-automation-rows-process.html), [Configuring Supporting Automation Logic](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configuring-supporting-automation-logic.html), [GET_LAST_RUN Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AUTOMATION_GET_LAST_RETURN-Function.html)

### Schedule Expression: sintaxe de calendário do DBMS_SCHEDULER

Lista `KEYWORD=VALUE` separada por `;`: `FREQ` (obrigatório: `YEARLY`, `MONTHLY`, `WEEKLY`, `DAILY`, `HOURLY`, `MINUTELY`…), `INTERVAL`, filtros (`BYDAY`, `BYHOUR`, `BYMINUTE`, `BYMONTHDAY`…), operações de conjunto e limites. Exemplos:

| Expressão | Significado |
|---|---|
| `FREQ=HOURLY;INTERVAL=2;BYMINUTE=0` | a cada 2 horas |
| `FREQ=WEEKLY;INTERVAL=1;BYDAY=MON,TUE,WED,THU,FRI;BYHOUR=14;BYMINUTE=30` | dias úteis 14:30 |
| `FREQ=WEEKLY;INTERVAL=1;BYDAY=SAT;BYHOUR=20;BYMINUTE=50` | sábados 20:50 |
| `FREQ=MONTHLY;INTERVAL=1;BYDAY=-1 SAT;BYHOUR=20;BYMINUTE=50` | último sábado do mês |
| `FREQ=MINUTELY;INTERVAL=2` | a cada 2 min |

Teste antes no SQL Commands:

```plsql
declare
    l_next timestamp with time zone;
    l_after timestamp with time zone := systimestamp;
begin
    for i in 1 .. 5 loop
        dbms_scheduler.evaluate_calendar_string(
            calendar_string   => 'FREQ=WEEKLY;BYDAY=SAT;BYHOUR=20;BYMINUTE=50',
            start_date        => systimestamp,
            return_date_after => l_after,
            next_run_date     => l_next);
        dbms_output.put_line(to_char(l_next, 'DY DD-MON-YYYY HH24:MI TZR'));
        l_after := l_next;
    end loop;
end;
```

Lembre: o horário é do **fuso do servidor de banco** (relevante para o Brasil se o banco está em UTC).

Fonte: [Using Interval Builder to Schedule Job](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-interval-builder-schedule-job.html), [Using More Complex Schedule Expressions](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-more-complex-schedule-expressions.html), [Creating an Automation](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-an-automation.html)

### Log de automations: Execution Log, APEX_AUTOMATION_LOG e retenção

Aba **Execution Log** da página Automations: Start Timestamp, Automation, Status, Successful Rows, Error Rows, Messages (drill-down: timestamp, texto, tipo Information/Warning/Error, PK da linha se configurada; IR com download). **Purge Log** limpa por automation. Aba **History** mostra alterações de desenvolvedores. A view **`APEX_AUTOMATION_LOG`** permite consultar por SQL. Retenção padrão: **14 dias** (ajustável em Administration Services > Manage Log Interval; há também *Deleting Automation Log Entries*).

Fonte: [Managing the Automation Execution Log](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-the-automation-execution-log.html), [Viewing the Automation Log](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/viewing-automation-log.html), [Viewing the Automation History Report](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/viewing-the-automation-history-report.html), [Configuring and Deleting Logs and Log Entries](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-and-deleting-logs-and-log-entries.html)

### APEX_AUTOMATION: referência

| Rotina | Uso |
|---|---|
| `EXECUTE(p_application_id, p_static_id, p_filters apex_exec.t_filters, p_order_bys)` | executa na sessão atual com filtros/ordem extras na query |
| `EXECUTE(p_application_id, p_static_id, p_run_in_background boolean)` | `TRUE` = job único do `DBMS_SCHEDULER` em nova sessão |
| `EXECUTE(p_application_id, p_static_id, p_query_context apex_exec.t_context)` | roda as ações para um contexto de query (colunas iguais às da automation) |
| `ENABLE` / `DISABLE(p_application_id, p_static_id)` | liga/desliga o agendamento |
| `RESCHEDULE(p_application_id, p_static_id, p_next_run_at default systimestamp)` | antecipa/define a próxima execução (não reinicia se estiver rodando) |
| `TERMINATE(p_application_id, p_static_id)` | para a execução corrente (`ABORT` deprecated) |
| `IS_RUNNING`, `GET_LAST_RUN_TIMESTAMP` (última bem-sucedida), `GET_SCHEDULER_JOB_NAME` | consultas |
| `GET_LAST_RUN` | dentro de ação/query: timestamp da execução anterior |
| `SKIP_CURRENT_ROW(p_log_message)`, `EXIT(p_log_message)` | controle dentro de ação |
| `LOG_INFO`, `LOG_WARN`, `LOG_ERROR(p_message)` | log |

`p_application_id` tem como padrão a app corrente: fora dela, informe explicitamente.

Fonte: [APEX_AUTOMATION](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AUTOMATION.html), [EXECUTE Procedure Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AUTOMATION_EXECUTE-Procedure-Signature-2.html), [RESCHEDULE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AUTOMATION_RESCHEDULE-Procedure.html)

### Automations ficam desabilitadas depois de importar a aplicação

**Sintoma:** depois de importar/reimportar a app (outro ambiente, nova versão), as automations não rodam mais.
**Causa:** por design o APEX **desabilita automations ao importar**, para evitar várias cópias rodando ao mesmo tempo.
**Correção:** reative em Shared Components > Automations (Schedule Status = Active) ou, em ambiente runtime-only, por PL/SQL com sessão:

```plsql
begin
    apex_session.create_session(p_app_id => 100, p_page_id => 1, p_username => 'ADMIN');
    apex_automation.enable(p_application_id => 100, p_static_id => 'lembrete-formacoes');
    -- ou: apex_automation.reschedule(100, 'lembrete-formacoes', trunc(sysdate + 1));
end;
```

**Prevenção:** inclua a reativação no roteiro de deploy.

Fonte: [About Importing and Exporting Automations](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-importing-and-exporting-automations.html)

### Job próprio com DBMS_SCHEDULER: JOB_CREATOR e contexto de workspace

Às vezes um job próprio é necessário (ex.: `APEX_UTIL.CREATE_USER` precisa rodar fora de uma sessão de app; a doc grava a requisição numa fila e um job processa a cada minuto). Pegadinhas:
- Criado pelo SQL Commands/Scripts do SQL Workshop, o `DBMS_SCHEDULER` registra **`JOB_CREATOR = APEX_PUBLIC_USER`**, que não tem privilégio para as APIs. Crie pelo **SQL Developer Web** (logado como o schema do workspace) ou por outra conexão direta ao schema.
- No job, defina o workspace: `apex_util.set_workspace('MEU_WS')`; para APIs que exigem sessão, `apex_session.create_session`.

```plsql
begin
    dbms_scheduler.create_job(
        job_name        => 'APEX_CREATE_USER_JOB',
        job_type        => 'PLSQL_BLOCK',
        job_action      => 'begin frc_apex_user.handle_new_users_queue; end;',
        repeat_interval => 'FREQ=MINUTELY',
        enabled         => true,
        auto_drop       => true);
end;
```

Prefira uma **automation** quando possível: tem log, Builder, export e controle por app.

Fonte: [Scheduling Create New Account Job](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/scheduling-create-new-account-job.html), [Inserting Account Creation Request](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/inserting-account-creation-request.html), [Handling New Account Requests](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/handling-new-account-requests.html)

---

## 8. E-mail

### Configuração de e-mail da instância (SMTP) e network ACL

O APEX só envia e-mail depois que o **instance administrator** configura *Administration Services > Manage Instance > Instance Settings > Email*:

| Atributo | Descrição |
|---|---|
| Oracle APEX Instance URL | URL da instância com barra final (ex. `https://www.example.com/apex/`); usada em e-mails do sistema e por `APEX_MAIL.GET_INSTANCE_URL` |
| Oracle APEX Images URL | URL das imagens com barra final (`GET_IMAGES_URL`) |
| SMTP Host Address / Port | padrão `localhost` / `25` |
| SMTP Authentication Username / Password | podem ser sobrepostos por workspace (Web Credential) |
| Use SSL/TLS | `Yes` (TLS antes do SMTP), `After connection is established` (`STARTTLS`), `No` |
| Default Email From Address | remetente de e-mails do sistema; **se definido, é sempre usado como From**, mesmo que o código passe outro |
| Maximum Emails per Workspace | limite por 24 h via `APEX_MAIL` |
| Maximum Emails Processed per Workspace | por execução do job `ORACLE_APEX_MAIL_QUEUE` |

Em ambiente runtime-only, use `APEX_INSTANCE_ADMIN.SET_PARAMETER(...)`, `COMMIT`, e valide com `APEX_INSTANCE_ADMIN.VALIDATE_EMAIL_CONFIG`; leia com `APEX_INSTANCE_ADMIN.GET_PARAMETER`. No banco, rede sai bloqueada por padrão: conceda via `DBMS_NETWORK_ACL_ADMIN` ao usuário `APEX_260100` acesso ao host SMTP (sem isso, `APEX_MAIL` aceita a chamada mas o envio falha; também afeta web services e impressão PDF). `APEX_MAIL` usa `UTL_SMTP`, que precisa estar instalado. Em Autonomous AI Database há procedimento próprio (Using Oracle Autonomous AI Database Serverless).

Fonte: [Configuring Email](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-email.html), [Sending Email from an Application](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/sending-email-from-an-application.html), [Configuring Oracle APEX to Send Email](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/Configuring-Oracle-Application-Express-to-Send-Email.html)

### Credenciais SMTP por workspace e remetente padrão da aplicação

- **Workspace**: *Workspace Administration > Manage Service > Set Workspace Preferences > Email*: *Use Workspace SMTP Credentials* liga um Web Credential (Basic Authentication) com usuário/senha SMTP próprios do workspace; o servidor continua o da instância.
- **Aplicação**: *Application Definition > Properties > Application Email From Address* define `APP_EMAIL`, valor padrão do campo From dos Send E-Mail nativos (a doc escreve `&APP_EMAIL.` e, numa página, `&APP_MAIL.`; a substituição documentada é `APP_EMAIL`). `APEX_MAIL.SEND` com template também cai nele quando `p_from` é omitido.

Fonte: [Configuring Workspace Preferences](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-workspace-preferences.html), [Setting Up Default From Email Address](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/setting-default-email-address.html), [Emailing User a Page Link](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/emailing-user-page-link.html)

### Fila de e-mail: APEX_MAIL_QUEUE, APEX_MAIL_LOG, reenvio e PUSH_QUEUE

`APEX_MAIL.SEND` e os componentes nativos **não enviam na hora**: gravam na fila (`APEX_MAIL_QUEUE`), que o job `ORACLE_APEX_MAIL_QUEUE` envia a cada 5 minutos (o End User's Guide fala em 15 minutos; vale a cadência do job na sua instância). Enviados com sucesso vão para `APEX_MAIL_LOG`. Em erro (endereço ruim, servidor fora), a mensagem fica na fila com o último erro e é reenviada **até 14 vezes** com espera exponencial (2, 4, 8, 16 min…); depois sai da fila e o erro fica em `APEX_MAIL_LOG`. O instance admin gerencia em *Manage Instance > Manage Meta Data > Mail Queue* (Delete, Send All Mail, Force Send All Mail).

Para envio imediato (ex. senha temporária), chame `APEX_MAIL.PUSH_QUEUE` após o `SEND` (os parâmetros de host/porta são ignorados; valem os da instância). O e-mail só entra na fila se a transação **comitar**.

Fonte: [Managing Meta Data](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/managing-meta-data.html), [PUSH_QUEUE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PUSH_QUEUE-Procedure.html), [Sending Emails with Templates](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/sending-emails-templates.html), [Troubleshooting Tasks (End User)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeeug/troubleshooting-tasks.html)

### Email Templates: definição, placeholders e escape

*Shared Components > User Interface > Email Templates > Create Email Template* (há modelos de exemplo: Load Order Details, Load Event Reminder, Load Scheduled Outage, com "Sample API Usage").

| Seção | Conteúdo |
|---|---|
| Identification | Template Name, **Static Identifier** (usado em `APEX_MAIL`), Email Subject |
| HTML Format | Header, Body, Footer, *Advanced > HTML Template* (Load Default HTML) |
| Plain Text Format | versão texto |

Placeholders `#NOME#` em subject, HTML e texto. Valores são **escapados conforme o contexto** (HTML escapado no formato HTML, não no texto). Modificadores: `#NOME!RAW#` (sem escape, para HTML confiável) e `#NOME!STRIPHTML#` (remove tags). Atributos específicos aceitam **template directives** (`{if NEW_COMMISSION/}, comissão #NEW_COMMISSION#{endif/}`).

Uso declarativo: no Send E-Mail (processo, atividade, ação de task ou automation) escolha *Email Template* e clique **Set Placeholder Values** (grade com cada placeholder: valor estático, item, `&COLUNA.`, `&APEX$TASK_SUBJECT.`). Templates podem ser copiados e **subscritos** de outra app (Subscribe / Refresh / Unsubscribe); abas Utilization e History.

Fonte: [Managing Email Templates](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-email-templates.html), [Defining Email Template with Directives](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/defining-email-template-directives.html), [Using Email Template and Placeholders](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-email-template-and-placeholders-notifying-end-users.html)

### Send E-Mail nativo (page process, workflow, task action, automation)

Atributos: **From** (padrão `&APP_EMAIL.`), **To**, **Cc**, **Bcc**, **Reply To** (vazio = From), **Email Template** + placeholders **ou** **Subject**, **Body Plain Text**, **Body HTML**, **Attachment SQL**. Campos de endereço aceitam `&P2_EMAIL.` (com ponto final). O comportamento é igual em page process, atividade de workflow, ação de task e ação de automation.

Attachment SQL: query de **quatro colunas, nessa ordem**: BLOB, nome do arquivo, MIME type, Content Id (null = anexo normal; valor = imagem inline `cid:`).

Fonte: [Managing Email Templates](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-email-templates.html), [Sending Email Without a Template](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/sending-email-template.html), [Emailing User with Attachments](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/emailing-user-attachments.html), [Creating a Task Definition](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-task-definitions.html)

### APEX_MAIL.SEND: assinaturas e regras

**Sem template** (função devolve o mail id; há versão procedure):

```plsql
APEX_MAIL.SEND (
    p_to        IN VARCHAR2,
    p_from      IN VARCHAR2,
    p_body      IN [VARCHAR2 | CLOB],
    p_body_html IN [VARCHAR2 | CLOB] DEFAULT NULL,
    p_subj      IN VARCHAR2 DEFAULT NULL,
    p_cc        IN VARCHAR2 DEFAULT NULL,
    p_bcc       IN VARCHAR2 DEFAULT NULL,
    p_replyto   IN VARCHAR2 DEFAULT NULL ) RETURN NUMBER;
```

**Com template**:

```plsql
APEX_MAIL.SEND (
    p_template_static_id IN VARCHAR2,
    p_placeholders       IN CLOB,          -- JSON {"NOME": "valor", ...}
    p_to                 IN VARCHAR2,
    p_cc, p_bcc, p_from, p_replyto IN VARCHAR2 DEFAULT NULL,
    p_application_id     IN NUMBER   DEFAULT apex_application.g_flow_id,
    p_language_override  IN VARCHAR2 DEFAULT NULL ) RETURN NUMBER;
```

Regras:
- Vários destinatários: lista separada por vírgula.
- `p_body` e `p_body_html` devem ter o **mesmo tipo** (ambos VARCHAR2 ou ambos CLOB). Só `p_body` = texto puro; os dois = multipart. `p_body_html` deve ser documento completo com `<html>` e `<body>`.
- **Nenhuma linha pode passar de 1000 caracteres**: insira CR/LF (senão mensagens truncadas ou com "!" estranhos).
- From com template: se omitido, usa Application Email From Address; senão `p_replyto`; senão `p_to`. Com vários endereços em to/replyto, `p_from` é obrigatório. Default Email From Address da instância sempre vence.
- `p_replyto` omitido = From; passado como NULL = suprime Reply-To.
- Fora de app (job/SQLcl), informe `p_application_id`; o usuário de banco precisa estar mapeado a um workspace (ou `APEX_ADMINISTRATOR_ROLE`); com vários workspaces, chame `apex_util.set_workspace` ou `set_security_group_id` antes.
- Evite imagens externas; se usar, inclua `alt`, ou anexe inline com `p_content_id`.

```plsql
apex_mail.send(
   p_to                 => :EMPLOYEE_EMAIL,
   p_template_static_id => 'EMPLOYEE_SALARY_LOTTERY_WINNER',
   p_placeholders       => apex_string.plist_to_json_clob(apex_t_varchar2(
                              'EMPLOYEE_NAME', :ENAME,
                              'NEW_SALARY',    :NEW_SALARY)));
```

(Uma página do Developer's Companion cita "`SEND_MAIL` em `APEX_EMAIL`", mas o código e a referência usam `APEX_MAIL.SEND`.)

Fonte: [SEND Function Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SEND-Function-Signature-1.html), [SEND Function Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SEND-Function-Signature-2.html), [APEX_MAIL](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_MAIL.html), [Sending Emails from Business Logic](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/sending-emails-business-logic.html), [Notifying User of Temporary Password](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/notifying-user-temporary-password.html)

### APEX_MAIL: anexos, PREPARE_TEMPLATE e URLs

- `ADD_ATTACHMENT(p_mail_id, p_attachment BLOB, p_filename, p_mime_type, p_content_id default null)`; versão CLOB sem content id. Chamável várias vezes por mail; depois `COMMIT`.
- `PREPARE_TEMPLATE(p_static_id, p_placeholders, p_application_id, p_subject OUT, p_html OUT, p_text OUT, p_language_override)`: monta o e-mail do template sem enviar (útil para pré-visualização ou outro canal).
- `GET_INSTANCE_URL` / `GET_IMAGES_URL`: dependem dos atributos de e-mail da instância. Para links de página use `APEX_PAGE.GET_URL(..., p_absolute_url => true)`.
- `p_language_override` usa a tradução do template se existir tradução da app naquela língua.

```plsql
declare
    l_id number;
begin
    l_id := apex_mail.send(p_to => 'a@ex.com', p_from => 'rh@ex.com',
                           p_subj => 'Relatório', p_body => 'Segue anexo.');
    apex_mail.add_attachment(p_mail_id => l_id, p_attachment => l_pdf,
                             p_filename => 'relatorio.pdf', p_mime_type => 'application/pdf');
    commit;
end;
```

Fonte: [ADD_ATTACHMENT Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_ATTACHMENT-Procedure-Signature-1.html), [PREPARE_TEMPLATE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PREPARE_TEMPLATE_Procedure.html), [GET_INSTANCE_URL Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_INSTANCE_URL-Function.html)

---

## 9. PWA e push notifications

### Progressive Web App: requisitos e atributos

PWA exige **HTTPS** (ou localhost) e **Friendly URLs = On** (sem isso, os atributos de PWA nem aparecem). *Shared Components > User Interface > Progressive Web App* (ou aba no Edit Application Definition):

| Seção | Atributos |
|---|---|
| General | **Enable Progressive Web App** (cache avançado de arquivos estáticos, página offline, hooks de service worker); **Installable** (entrada "Install App" na navigation bar) |
| Installability | Display (`Fullscreen`, `Standalone`, `Minimal UI`, `Browser`), Screen Orientation, Theme Color, Background Color, iOS Status Bar Style, App Description, Short Name, Custom Manifest (JSON), Screenshots (320–3840 px, mesma proporção, png/jpg; Form Factor Narrow/Wide), Shortcuts (exigem **Rejoin Sessions** habilitado) |
| Push Notifications | ver seção seguinte |
| Service Worker Configuration | `Default` (cache-first, rede, offline page), `Configure Hooks`, `File URL` |

Display e cores são só repassados ao dispositivo (alguns ignoram). Mensagens de PWA (ex. página offline) estão entre as que exigem tradução. No wizard de criação: features *Install Progressive Web App* e *Push Notifications*.

Fonte: [Creating a Progressive Web App (PWA)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-a-progressive-web-app.html), [Configuring Progressive Web App Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-progressive-web-app-attributes.html)

### Push notifications: habilitar, credenciais e opt-in

1. Ligue **Enable Progressive Web App** e **Enable Push Notifications** (em algumas plataformas móveis o push exige app **instalada**, então ligue também Installable).
2. **Generate Credentials**: cria um Web Credential de par de chaves (pública/privada) que cifra e assina as mensagens. Ao **mudar de ambiente** use *Regenerate Credentials* (ou `APEX_PWA.GENERATE_PUSH_CREDENTIALS`). Trocar o par obriga os usuários a se inscreverem de novo.
3. **Settings Page**: *Add Settings Page* cria página e entrada "User Settings" para o usuário ativar push **em cada dispositivo** (Enable push notifications on this device > Allow).
4. **Contact Email**: e-mail (de preferência de grupo) para o provedor de push (Google, Mozilla, Apple).

Envio: Send Push Notification (page process, atividade, ação de task/automation; To = **username**, Title, Body, Link Target). Só usuários inscritos recebem, em todos os seus dispositivos; para os demais o APEX ignora silenciosamente. Link Target padrão: home; para página específica use URL **absoluta** e habilite **Deep Linking**. Fila: view `APEX_PUSH_NOTIFICATIONS_QUEUE`, job `ORACLE_APEX_PWA_PUSH_QUEUE` (2 min), página *Push Notifications Queue* do instance admin.

Fonte: [Delivering Push Notifications](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/delivering-push-notifications.html), [Enabling Push Notifications in an App](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/enabling-push-notifications-app.html), [Generating Key Pairs for Push Notifications](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/generating-key-pairs-push-notifications.html), [Opting-In to Receive Push Notifications](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/opting-receive-push-notifications.html), [Overriding Notification Target Link](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/overriding-notification-target-link.html), [Managing Meta Data](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/managing-meta-data.html)

### APEX_PWA (PL/SQL) e apex.pwa (JavaScript)

PL/SQL:

```plsql
APEX_PWA.SEND_PUSH_NOTIFICATION (
    p_application_id IN NUMBER   DEFAULT [app atual],
    p_user_name      IN VARCHAR2,
    p_title          IN VARCHAR2,
    p_body           IN VARCHAR2 DEFAULT NULL,
    p_icon_url       IN VARCHAR2 DEFAULT NULL,   -- padrão: ícone da app
    p_target_url     IN VARCHAR2 DEFAULT NULL ); -- padrão: home; habilite deep linking ou rejoin
```

Demais: `HAS_PUSH_SUBSCRIPTION(p_application_id, p_user_name) return boolean`, `SUBSCRIBE_PUSH_NOTIFICATIONS(..., p_subscription_interface JSON do browser)`, `UNSUBSCRIBE_PUSH_NOTIFICATIONS(..., p_subscription_interface default null = todas)`, `PUSH_QUEUE` (dispara o envio da fila), `GENERATE_PUSH_CREDENTIALS(p_application_id)`.

JavaScript (`apex.pwa`, só com PWA habilitado): `getDisplayMode()` (`fullscreen`/`standalone`/`minimal-ui`/`browser`), `isInstallable()` (Promise), `openInstallDialog()` (também acionado por `.a-pwaInstall` ou `href="#action$a-pwa-install"`), `hasPushSubscription()`, `getPushSubscription()`, `subscribePushNotifications()`, `unsubscribePushNotifications()`; `getInstallText()` está deprecated.

```js
if (await apex.pwa.hasPushSubscription() === false) {
    await apex.pwa.subscribePushNotifications();
}
```

Fonte: [APEX_PWA](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_PWA.html), [SEND_PUSH_NOTIFICATION Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_PWA.SEND_PUSH_NOTIFICATION-Procedure.html), [apex.pwa](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.pwa.html), [Pushing Notification from Business Logic](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/pushing-notification-business-logic.html)

---

## 10. IA generativa

### Generative AI Services: provedores suportados e onde ficam

Um **Generative AI Service** é definido no **workspace** (*App Builder > Workspace Utilities > Generative AI*) e fica disponível a todas as apps. Provedores: **OCI Generative AI**, **OpenAI**, **Cohere**, **Google Gemini**, **Anthropic Claude**, **Mistral AI**, **Ollama** (local) e **Generic OpenAI-compatible**. O APEX normaliza requisições e respostas (o app não muda ao trocar de provedor), executa as chamadas **no servidor** e guarda a chave como **Web Credential** (nunca exposta ao browser).

Fluxo de uma chamada: componente/API → APEX busca provedor, endpoint e credencial do serviço → monta o payload específico → envia pela infraestrutura REST do APEX → normaliza a resposta → devolve.

Exportação: a app exportada **não leva o segredo** do Web Credential; após importar, defina-o manualmente ou por API. Controles administrativos: *AI Enabled* em *Instance Settings > Security* (Yes/No), suporte por workspace, proxy para AI Services do App Builder, *Maximum AI Tokens* por workspace/instância.

Fonte: [Understanding Generative AI Support in APEX](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-generative-ai-support-in-apex.html), [Creating Generative AI Service Objects](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-generative-ai-service-objects.html), [Configuring a Generative AI Service](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configuring-generative-ai-service.html), [Configuring Service-Level Security Settings](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-service-level-security-settings.html)

### Criar um Generative AI Service: atributos

| Seção | Atributo | Descrição |
|---|---|---|
| Identification | AI Provider, Name | Name e Static ID únicos no workspace |
| Settings | **Used by App Builder** | habilita IA no Builder (Create App/Page com IA, NL em IR no Builder, APEX Assistant nos code editors, SQL Workshop, Data Reporter). **Só um serviço por workspace** pode ter isso ligado. |
| | Default for New Apps | serviço padrão das novas apps |
| | Base URL | endpoint REST; deve bater com a URL do Web Credential |
| Credentials | Credential / API Key, **Test Connection** (`Connection Succeeded!`) | |
| Advanced | Additional Attributes (JSON extra no payload), **Static ID** (para `APEX_AI`), AI Model (vazio = padrão do provedor; ex. `claude-sonnet-4-6`), **Maximum AI Tokens** (por 24 h; nem todo provedor informa uso, então pode não ser imposto), Server Timeout, HTTP Headers (`nome=valor` por linha), Comments | |

Os atributos exatos variam por provedor (veja a ajuda do item). Relatórios: Utilization e History.

Fonte: [Creating Generative AI Service Objects](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-generative-ai-service-objects.html), [Editing a Generative AI Service](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-a-generative-as-service.html), [Viewing Generative AI Service Utilization](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/viewing-generative-ai-service-utilization.html)

### Atributos de IA da aplicação: Service, Request Handler e Response Handler

*Edit Application Definition > AI > Generative AI*:
- **Service**: serviço padrão da app ("Application Default" nos componentes). Sem serviço no workspace aparece `No AI Services available` (botão Configure). Sem isso os componentes de IA dão erro.
- **Request Handler Procedure**: chamada antes de cada requisição (mascarar dados, log, política, detecção de prompt injection, alterar a requisição).
- **Response Handler Procedure**: chamada após cada resposta (mascarar, log, política; não executa tool calls).

```plsql
procedure meu_request_handler (
    p_param  in            apex_ai.t_chat_request_handler_param,
    p_result in out nocopy apex_ai.t_chat_request_handler_result );

procedure meu_response_handler (
    p_param  in            apex_ai.t_chat_response_handler_param,
    p_result in out nocopy apex_ai.t_chat_response_handler_result );
```

Fonte: [Configuring Generative AI Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-generative-ai-attributes.html), [About Including Generative AI in Applications](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-including-generative-ai-in-applications.html)

### AI Agents: shared component com system prompt, ferramentas e formato de resposta

**AI Agent** (*Shared Components > Generative AI > AI Agents*) centraliza a configuração de IA reutilizada por Show AI Assistant, Generate Text with AI (DA, processo, atividade) e `APEX_AI`:

| Atributo | Descrição |
|---|---|
| Name, **Static ID** | Static ID usado em `APEX_AI.GENERATE/CHAT(p_agent_static_id => ...)`; mudar o ID quebra chamadas por API |
| Service | Application Default ou outro serviço |
| System Prompt | papel e regras ("Você é o assistente de RH da Corlix. Só responde sobre..."). Aceita template directives e itens (`#PATIENT#`, `{if X/}…{endif/}`) |
| Welcome Message | só para componentes com UI (Show AI Assistant) |
| Response Format Type | `Text` (Show AI Assistant, Generate Text with AI, API) ou `JSON Object` + JSON Schema (**só API**; no 26ai a resposta é validada contra o schema) |
| Temperature | criatividade × determinismo (interpretação varia por provedor) |
| Tools | System Prompt Augmentation Tools e On Demand Tools |

Copiar/subscrever entre apps; Utilization e History. Agente em uso não pode ser apagado.

Divergência histórica: as assinaturas antigas `APEX_AI.GENERATE/CHAT(p_config_static_id ...)` (da época das "AI Configurations" com "RAG Sources") estão **deprecated**; o parâmetro agora se refere ao **AI Agent** e as fontes RAG viraram **AI Tools**. A doc 26.1 ainda menciona "RAG Sources" em textos de ajuda (Items to Submit) e uma "AI Configuration" num exemplo; trate como AI Agent + tools.

Fonte: [Managing AI Agents and AI Tools](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-ai-agents-and-ai-tools.html), [Defining an Agent to Achieve a Goal](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/defining-agent-achieve-goal.html), [CHAT Function Signature 3 (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AI.CHAT-Function-Signature-3.html), [Discharging Patient After Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/discharging-patient-procedure.html)

### AI Tools: tipos, execution point, parâmetros, confirmação e segurança

Cada tool do agente tem:
- **Name** (minúsculas com underscore, começa com letra, ex. `get_employee_info`).
- **Type**: `Retrieve Data` (SQL Query, Function Body que devolve CLOB, ou Static; *Data Description*; *Maximum Tokens* para SQL, linhas que estourariam são puladas), `Execute Server-side Code` (PL/SQL ou JavaScript MLE; resultado implícito "success", troque com `apex_ai.set_tool_result`), `Execute Client-side Code` (pede entrada ao usuário ou usa APIs do browser; devolve string). Plug-ins do tipo **Generative AI Tool** estendem a lista.
- **Execution Point**: `Augment System Prompt` (roda a cada nova mensagem, antes de enviar ao LLM, e seu resultado vira system prompt extra; só Retrieve Data ou Client-side) ou `On Demand` (o LLM recebe nome, descrição e parâmetros e decide chamar; todos os tipos).
- **Description** e **Parameters** (On Demand): nome, descrição, tipo `VARCHAR2`/`CLOB`/`NUMBER`/`BOOLEAN`, Required, Allowed Values. Em SQL/PL/SQL: `:PARAM`; em JS: `this.data.PARAM`.
- **User Approval > Requires Confirmation**: humano no circuito; a ferramenta só roda se o usuário aprovar.
- **Notification** (Message, Type) ao concluir.
- **Server-side Condition** (inclui *Any User Prompt contains* / *Last User Prompt contains*; binds `APEX$AI_LAST_USER_PROMPT`, `APEX$AI_ALL_USER_PROMPTS`) e **Authorization Scheme**: se falso, a tool On Demand nem é oferecida ao LLM; a Augment é pulada.

Ciclo do "agent loop": APEX roda as Augment tools → envia prompt + histórico (o LLM é stateless, o APEX reenvia toda a conversa) + descrições → o LLM responde ou pede tools → APEX executa e devolve resultados → repete até a resposta final. **O LLM nunca vê a implementação**, só o que a tool devolve. Qualquer tool pode fazer RAG; use Augment para contexto sempre útil e On Demand bem descrita para o resto. Queries de tool podem usar app items como bind (ex. empresa da sessão).

```plsql
-- tool On Demand "give_raise" (Execute Server-side Code), parâmetros P_EMPNO e P_PCT
declare
    l_new number;
begin
    if :P_PCT > 0 and :P_PCT <= 40 then
        update emp set sal = sal * (1 + :P_PCT/100) where empno = :P_EMPNO
        returning sal into l_new;
        apex_ai.set_tool_result(case when sql%rowcount > 0 then 'Novo salário: '||l_new
                                     else 'Empregado '||:P_EMPNO||' não encontrado' end);
    else
        apex_ai.set_tool_result('Percentual deve ser > 0 e <= 40');
    end if;
end;
```

Pegadinha da doc: a tool de consulta não devolvia `EMPNO`, então o LLM não conseguia chamar a tool de ação que exige o ID. Devolva os identificadores que outras tools precisam e descreva-os na Data Description.

Fonte: [Managing AI Agents and AI Tools](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-ai-agents-and-ai-tools.html), [Defining an Agent to Achieve a Goal](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/defining-agent-achieve-goal.html)

### Dynamic action Show AI Assistant: chatbot em diálogo ou inline

True action **Show AI Assistant** (normalmente num clique de botão ou Page Load):

| Grupo | Atributos |
|---|---|
| Generative AI | **Agent** (só agentes com Response Format Text) ou Service + **System Prompt** + **Welcome Message** (aceitam itens e substituições); **Items to Submit** (vão para session state e podem ser usados no system prompt e nas tools) |
| Appearance | **Display As** `Dialog` (com Title) ou `Inline` (aponta para uma região Static Content) |
| Initial Prompt | Type Item ou JavaScript Expression (mensagem "como se fosse do usuário"); *Immediate Action Prompt* para gerar resposta já na abertura |
| Use Response | Type Item ou JavaScript Code; *Button Label* do botão que aplica a resposta; *JavaScript Detection Expression* (ex. extrair um número de `this.fullContent`) |
| Quick Actions | frases pré-definidas clicáveis (aceitam directives e itens) |

Avatares do assistente e do usuário: *Shared Components > Component Settings > Show AI Assistant*. Para UI própria: `APEX_AI.CHAT` + `APEX_COLLECTION` para guardar mensagens + região Comments sobre `APEX_COLLECTIONS`. O APEX pode exibir tela de **consentimento** de uso de IA (`APEX_AI.IS_USER_CONSENT_NEEDED`, `SET_USER_CONSENT`, `REVOKE_USER_CONSENT[_FOR_ALL]`).

Fonte: [About Including Generative AI in Applications](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-including-generative-ai-in-applications.html), [Creating a Dynamic Action to Display AI Assistant](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-a-dynamic-action-to-display-ai-assistant.html), [Creating an AI Assistant to Suggest Salary](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-an-ai-assistant-to-suggest-salary.html), [Creating an Agent-Driven Chatbot](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/creating-agent-driven-chatbot.html), [IS_USER_CONSENT_NEEDED Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AI.IS_USER_CONSENT_NEEDED-Function.html)

### Generate Text with AI: dynamic action, page process e atividade de workflow

Resposta única (não conversa) para resumir, traduzir, extrair palavras-chave, rascunhar e-mail ou carta.

| Forma | Atributos principais |
|---|---|
| **Dynamic Action** (true action) | Agent (ou Application Default) + System Prompt (só na DA), Items to Submit; **Input Value** Type Item ou JavaScript Expression; **Use Response** Type Item (pode disparar change) ou JavaScript Code |
| **Page Process** | Agent; Input Value (Item); Use Response > Item (use session state tipo **CLOB** para respostas grandes); execução/erro como qualquer processo |
| **Workflow Activity** | Agent; Input Value Item; Use Response Item (variável `CLOB`) |

Escolha um Agent quando o texto se beneficia de dados/ações via tools; use o serviço direto quando um prompt fixo basta. Padrão da doc: primeira true action Execute Server-side Code copia campos para app items, segunda Generate Text with AI com agente cujo system prompt usa `#ITEM#` e `{if ITEM/}`, resultado num Rich Text Editor para o usuário revisar.

Fonte: [Creating a Dynamic Action to Generate Text with AI](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-a-dynamic-action-to-generate-text-with-ai.html), [Creating a Page Process to Generate Text with AI](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-a-page-process-to-generate-text-with-ai.html), [Generating Text to Save Users Time](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/generating-text-users-time.html), [Creating a Workflow Activity](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-workflow-activities.html)

### APEX_AI: GENERATE, CHAT, tools e handlers

Requer sessão APEX ligada a uma app com serviço configurado.

```plsql
-- por agente (Shared Components)
apex_ai.generate(p_agent_static_id => 'assistente_rh', p_prompt => l_texto,
                 p_request_handler_procedure => null, p_attachments => null) return clob;
apex_ai.chat(p_agent_static_id => 'assistente_rh', p_prompt => l_pergunta,
             p_messages => l_hist /* in out t_chat_messages */, p_request_handler_procedure => null) return clob;

-- ad hoc
apex_ai.generate(p_prompt, p_system_prompt, p_service_static_id, p_temperature,
                 p_attachments, p_response_json_schema, p_tools,
                 p_response_handler_procedure, p_max_tool_roundtrips) return clob;
apex_ai.chat(p_prompt, p_system_prompt, p_service_static_id, p_temperature,
             p_messages, p_tools, p_response_handler_procedure, p_max_tool_roundtrips) return clob;
```

- `p_messages` acumula a conversa automaticamente (respostas são adicionadas).
- `p_response_json_schema` / agente JSON: devolve JSON stringificado (valide você mesmo antes do 26ai).
- `p_attachments` (`t_attachment`: `mime_type`, `content_blob`/`content_clob`, `file_name`, `detail_level` `auto`/`high`/`low`): suporte depende do provedor/modelo.
- Tools ad hoc: `t_tool(name, description, parameters t_tool_parameters, parameters_json_schema, callback_procedure)`; a callback tem assinatura `(p_param in apex_ai.t_tool_exec_param, p_result in out nocopy apex_ai.t_tool_exec_result)` e lê `p_param.args_json.get_number('amount')`. Alternativa: um response handler que trata `p_param.pending_tool_calls` e chama `apex_ai.set_tool_result(p_response_handler_param, p_response_handler_result, p_tool_call, p_result)`.
- `set_tool_result(p_result, p_notification_message, p_notification_type, p_early_exit, p_is_safe default false)`: `p_is_safe => true` envia o resultado **sem** o invólucro de proteção contra prompt injection (só para dados confiáveis); `p_early_exit` encerra sem voltar ao LLM.
- Outros: `GET_AVAILABLE_TOKENS(p_service_static_id)` (NULL se sem limite), `IS_ENABLED` (IA ligada no workspace), funções de consentimento.
- Tipos de resposta normalizada: `t_chat_response(type complete|error|tool_calls, error content_filter|generic|invalid_response|invalid_tool_call|max_length|refusal, input/output/total_tokens)`.

```plsql
declare
    l clob;
begin
    apex_session.create_session(p_app_id => 100, p_page_id => 1, p_username => 'ADMIN');
    l := apex_ai.generate(p_prompt => 'Resuma: '||l_texto,
                          p_system_prompt => 'Responda em português, em até 3 frases.');
    apex_session.delete_session;
exception when others then apex_session.delete_session; raise;
end;
```

Fonte: [APEX_AI](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AI.html), [GENERATE Function Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AI.GENERATE-Function-Signature-1.html), [GENERATE Function Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AI.GENERATE-Function-Signature-2.html), [CHAT Function Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AI.CHAT-Function-Signature-1.html), [Constants and Data Types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AI.Data-Types.html), [SET_TOOL_RESULT Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AI.SET_TOOL_RESULT-Procedure-Signature-1.html)

### Vector Providers e embeddings (GET_VECTOR_EMBEDDINGS)

Requer **Oracle AI Database 26ai** (tipo `VECTOR`). Um **Vector Provider** (*Workspace Utilities > Vector Providers*) converte texto em embedding:

| Provider Type | Configuração |
|---|---|
| Database ONNX Model | ONNX Model Owner (schemas do workspace com mining models; vazio = parsing schema) e Name. Carregar modelo exige `CREATE MINING MODEL` (`dbms_vector.load_onnx_model`) |
| Generative AI Service | OCI Generative AI, OpenAI, Cohere, Google Gemini, Generic OpenAI compatible |
| Custom PL/SQL | função que recebe `VARCHAR2` e devolve `VECTOR` |

Advanced: Static ID (para a API), Maximum AI Tokens, Additional Attributes. Vector Providers vão no export da app; na importação, se já existir um com o mesmo Static ID no workspace destino ele é usado, senão é criado.

```plsql
apex_ai.get_vector_embeddings(p_value => l_texto, p_service_static_id => 'VP_OCI') return vector;
apex_ai.get_vector_embeddings(p_value, p_local_llm_owner, p_local_llm_name) return vector;  -- ONNX direto
apex_ai.get_vector_embeddings(p_value, p_function_name) return vector;                     -- função custom
```

Use **o mesmo provider** para gerar os vetores dos dados e para a busca (senão as distâncias não fazem sentido).

Fonte: [Managing Vector Providers](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-vector-providers.html), [GET_VECTOR_EMBEDDINGS Function Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AI.GET_VECTOR_EMBEDDINGS-Function-Signature-1.html), [Finding by Meaning with Vector Search](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/finding-meaning-vector-search.html)

### Natural Language em Interactive Reports (Search with AI)

Ligando **Natural Language Support** num Interactive Report, o usuário descreve em linguagem natural e o Assistant aplica recursos normais do IR (filtros, ordenação, highlights, gráficos, breaks), visíveis como chips. *Default Search Mode*: Row Search ou Search with AI. Contexto opcional: **Report Context**, **Column Context** e **Reference Data** (SQL, ex. até 100 nomes) — consomem tokens. O Assistant **não envia dados da aplicação** ao serviço, só o prompt, configurações e metadados de colunas, então o usuário só vê o que já podia ver. Detalhes de IR estão no documento 03.

Fonte: [Exploring Data with Natural Language](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/exploring-data-natural-language.html), [Adding Natural Language Support to Interactive Reports](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/adding-natural-language-support-to-interactive-reports.html)

---

## 11. Search Configurations e Search region

### Search Configurations: tipos de busca e quando usar cada um

**Search Configuration** (*Shared Components > Navigation and Search > Search Configurations*) descreve uma fonte pesquisável e o papel de cada coluna. Tipos:

| Search Type | Como busca | Requisitos |
|---|---|---|
| **Standard** | `LIKE` sobre Table, SQL Query ou REST Data Source (colunas pesquisáveis escolhidas) | nenhum |
| **Oracle TEXT** | Oracle Text (linguístico, fuzzy) | índice `CTXSYS.CONTEXT` existente; *Index Column Name*; *Text Query Function* |
| **Oracle Ubiquitous Search** | índice `DBMS_SEARCH` sobre várias tabelas/views | Oracle AI Database 26ai; índice no **parsing schema** |
| **List** | entradas de uma List do Shared Components | |
| **Oracle Vector Search** | similaridade semântica (`VECTOR_DISTANCE`) | 26ai, coluna `VECTOR`, Vector Provider; para busca aproximada, índice vetorial |

*Text Query Function* (Oracle TEXT): `None` (cada termo entre `{}` exceto `and`/`or`), `Search Engine` (exato, depois stemming e fuzzy, mais relevantes no topo; `APEX_SEARCH.QUERY_SEARCH_ENGINE`), `Expert Search` (AND, OR→ACCUM, NOT, `AROUND(d)`, parênteses, frases entre aspas, `fuzzy+:`, pesos `termo^3`; `APEX_SEARCH.QUERY_EXPERT_SEARCH`), `Custom`.

```sql
create index eba_project_tasks_ctx on eba_project_tasks(description) indextype is ctxsys.context;
begin dbms_search.create_index('MY_SEARCH_INDEX'); dbms_search.add_source('MY_SEARCH_INDEX','EBA_PROJECT_TASKS'); end;
```

Fonte: [About Creating Application Searches](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-creating-application-searches.html), [Creating an Oracle Text Search](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-an-oracle-text-search.html), [Creating a Ubiquitous Search](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-a-ubiquitous-search.html), [Defining a Search Configuration](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/defining-search-configuration.html), [QUERY_EXPERT_SEARCH Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/QUERY_EXPERT_SEARCH-Function.html)

### Atributos de uma Search Configuration

| Seção | Atributos |
|---|---|
| Settings | Search Type, **Label** (sobrescrevível na página), **Search Query Prefix** (ex. `emp:` restringe a busca a configurações com esse prefixo; prefixo desconhecido é ignorado), **Static ID** (para `APEX_SEARCH.SEARCH`) |
| Subscription | assinar uma configuração mestra de outra app |
| Source | Table, SQL Query ou Function Body returning SQL Query (ou REST Data Source no Standard); Order By Clause; colunas pesquisáveis |
| Column Mapping | Primary Key (1 e 2), Title, Subtitle, Description, Badge, Last Modified, Custom Column 1–3; para Vector: Vector Column |
| Icon and Display | Icon Source: Initials, CSS Classes, Class Column (ou BLOB/URL); **Default Result Row Template** |
| Link | Link Type (ex. Redirect to Page in this Application) + página e itens (ex. `P4_EMPNO` ← `EMPNO`) |
| Server-Side Condition, **Authorization Scheme**, Build Option, Comments | |

Copiar dentro da app gera Static ID novo; copiar de outra app permite **Subscribe**. Abas Utilization e History.

Fonte: [Editing a Search Configuration](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-a-search-configuration.html), [Defining a Search Configuration](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/defining-search-configuration.html), [Copying or Subscribing to a Search Configuration](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/copying-or-subscribing-to-a-search-configuration.html), [Custom Unified Search Experience](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/custom-unified-search-experience.html)

### Search page e Search region: atributos e Search Sources

Crie pelo wizard (*Component > Search Page*, escolhendo configurações) ou manualmente: um item de busca (ex. `P6_SEARCH`, *Warn on Unsaved Changes* = Ignore) e uma região do tipo **Search** com **Search Sources** (cada uma aponta para uma Search Configuration; Label, Icon and Badge, *Use as Initial Result* podem ser ajustados por fonte).

Atributos da região (aba Attributes): *Search Page Item* (sem ele há campo integrado), **Search as You Type**, **Minimum Characters**, Use Pagination, Results per Page (Static ou Item), Show Result Count, **Custom Layout** + Result Row Template, Last Modified Format Mask (`TIMESTAMP WITH LOCAL TIME ZONE`), Overall Sort (padrão: ordem das configurações), No Query Entered Message, No Results Found Message, **Lazy Loading**.

Formatação, do mais simples ao mais flexível: CSS, *Default Result Row Template* da configuração (`&COLUNA.` e template directives) ou *Result Row Template* da região (vale para todas as fontes; substituições `TITLE`, `SUBTITLE`, `DESCRIPTION`, `ICON`, `LINK`, `BADGE`…; a lista e o template padrão estão no Help).

Fonte: [Creating a Search Page Manually](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-a-search-page-manually.html), [Editing a Search Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-a-search-page.html), [Using Search Configurations](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-search-configurations.html), [Search Results Formatting Options](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/search-results-formatting-options.html)

### APEX_SEARCH.SEARCH: resultados unificados em qualquer região

```plsql
APEX_SEARCH.SEARCH (
    p_search_static_ids      IN apex_t_varchar2,
    p_search_expression      IN VARCHAR2,
    p_apply_order_bys        IN VARCHAR2 DEFAULT 'Y',
    p_return_total_row_count IN VARCHAR2 DEFAULT 'N' )
RETURN apex_search_result_table PIPELINED;
```

Colunas: `CONFIG_LABEL`, `CONFIG_ID`, `CONFIG_STATIC_ID`, `RESULT_SEQ`, `TOTAL_ROW_COUNT`, `PRIMARY_KEY_1/2`, `TITLE`, `SUBTITLE`, `DESCRIPTION`, `BADGE`, `LAST_MODIFIED`, `CUSTOM_01..03`, `SCORE` (score do Oracle Text), `LINK`, `RESULT_CSS_CLASSES`, `FORMATTED_ROW`, `ICON_TYPE` (CLASS, URL, BLOB, INITIALS), `ICON_VALUE`, `ICON_BLOB`, `ICON_MIMETYPE`; em Vector Search também `DISTANCE`.

```sql
select *
  from table(apex_search.search(
         p_search_expression => :P31_SEARCH,
         p_search_static_ids => apex_t_varchar2('colaboradores','comunicados'),
         p_apply_order_bys   => 'N'))
 order by title
```

Passe `p_apply_order_bys => 'N'` quando a query tem `ORDER BY` próprio. Permite exibir os resultados em Cards, Map, Chart, Classic Report etc. (lembre de *Page Items to Submit* e de um refresh por DA).

Fonte: [SEARCH Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_SEARCH.SEARCH-Function.html), [Custom Unified Search Experience](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/custom-unified-search-experience.html)

### Oracle Vector Search: busca por significado e corte por proximidade

Passos: adicionar coluna `VECTOR` (`alter table t add (vector_column vector)`), criar Vector Provider, popular com `update t set vector_column = apex_ai.get_vector_embeddings(nome||' '||descricao, 'VP_X')`, criar Search Configuration tipo **Oracle Vector Search** (Vector Provider, Source Table/SQL, Primary Key, **Vector Column**, Title, Description, Icon, Link) e uma Search page/região. Em runtime o APEX vetoriza o termo, ordena por `VECTOR_DISTANCE` e usa `FETCH FIRST N ROWS ONLY`. Com Custom Layout dá para mostrar `&DISTANCE.`.

Para evitar resultados semanticamente fracos, a doc propõe um **corte relativo ao melhor resultado** (ex. até 10% acima da menor distância) com uma SQL macro escalar:

```sql
select primary_key_1, title, description, distance
  from table(apex_search.search(
         p_search_expression => :P5_SEARCH,
         p_search_static_ids => apex_t_varchar2('activities-vector')))
 where distance <= best_activity_distance(:P5_SEARCH)   -- macro: min(vector_distance(...)) * 1.10
```

Lembre de atualizar os vetores quando o texto de origem mudar (trigger ou automation).

Fonte: [Creating an Oracle Vector Search](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-an-oracle-vector-search.html), [Finding by Meaning with Vector Search](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/finding-meaning-vector-search.html)

---

## 12. Problemas conhecidos (casos)

### ORA-20987: APEX: Not authorized for Task operations like complete_task, release, delegate, cancel_task

**Sintoma:** ao aprovar, concluir, delegar ou cancelar uma task, erro `ORA-20987 ... Not authorized for Task operations`.
**Causa:** o username do participante (em `APEX_TASK_PARTICIPANTS`) não bate **exatamente** (maiúsculas/minúsculas) com o login; contas APEX ficam em maiúsculas. A maioria desses erros é "falso alarme" de caixa.
**Correção:** gravar participantes em maiúsculas (ex. `upper(login_apex)` na query de participantes) e recriar/atualizar as tasks.
**Prevenção:** compare sempre com `:APP_USER` e normalize usernames nas funções de participantes.

Fonte: [Troubleshooting Tasks](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/troubleshooting_tasks.html), [Determining Task Participants](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/determining-task-participants.html)

### Task Not Found ao aprovar task por job do DBMS_SCHEDULER

**Sintoma:** `APEX_HUMAN_TASK.APPROVE_TASK` chamado num job dá "Task Not Found".
**Causa:** o job não tem sessão APEX; as APIs de task resolvem a task e as permissões pela sessão.
**Correção:** no job, `apex_session.create_session(p_app_id, p_page_id, p_username => '<APROVADOR>')` e só então chamar a API.

Fonte: [Troubleshooting Tasks](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/troubleshooting_tasks.html)

### Task não expira depois de mudar o prazo com SET_TASK_DUE

**Sintoma:** prazo vencido mas a task não vai a Expired nem executa Before Expire/Expire.
**Causa:** o job `ORACLE_APEX_TASKS_EXPIRE` só roda de hora em hora.
**Correção:** para testar, `APEX_HUMAN_TASK.HANDLE_TASK_DEADLINES`.

Fonte: [Troubleshooting Tasks](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/troubleshooting_tasks.html), [HANDLE_TASK_DEADLINES Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.HANDLE_TASK_DEADLINES-Procedure.html)

### APEX$TASK_ID não funciona na Actions SQL Query da Task Definition

**Sintoma:** a query da Actions Source que usa `:APEX$TASK_ID` não traz dados.
**Causa:** o ID só é gerado depois de a task ser criada (bug conhecido).
**Correção:** filtre por `:APEX$TASK_PK`.

Fonte: [Troubleshooting Tasks](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/troubleshooting_tasks.html)

### Usuário não vê a task na Unified Task List ou vê "Your session has ended" ao abrir

**Sintoma:** potential owner não encontra a task; ou a lista abre mas o detalhe dá "Your session has ended".
**Causa:** (1) participante com caixa errada; (2) task já reivindicada por outro potential owner (sai das listas dos demais); (3) iniciador de approval é filtrado; (4) Unified Task List e Task Details em apps diferentes sem session sharing; (5) contexto errado (My Tasks não mostra concluídas).
**Correção:** normalizar usernames; usar Smart Filters; configurar session sharing entre as apps; usar Admin Tasks / Initiated by Me conforme o caso; para aprovar, o usuário precisa **claim** antes (ou usar a ação rápida, que faz autoclaim).

Fonte: [Troubleshooting Tasks (End User)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeeug/troubleshooting-tasks.html), [Managing Unified Task Lists](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-unified-task-lists.html), [Letting an Initiator Approve a Task](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/letting-initiator-approve-task.html)

### Workflow <static_id> has no Active version

**Sintoma:** fora do App Builder, iniciar o workflow dá `Workflow <static_id> has no Active version`.
**Causa:** só existe versão In Development (usada apenas em Development Mode).
**Correção:** definir participantes (Owner/Admin), ativar a versão (Activate) e **salvar**; garantir que workflows invocados também tenham versão Active.

Fonte: [Activating an In Development Workflow](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/activating-development-workflow.html), [Managing Workflow Versions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-workflow-versions.html)

### PLS-00221: 'START_WORKFLOW' is not a procedure or is undefined

**Sintoma:** compilação falha ao chamar `apex_workflow.start_workflow(...)` como instrução.
**Causa:** é função (devolve o ID).
**Correção:** `l_id := apex_workflow.start_workflow(...)`.

Fonte: [Starting the Lifecycle Workflow](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/starting-lifecycle-workflow.html)

### ORA-04091 / ORA-20999 Additional data row not found ao iniciar workflow em trigger

**Sintoma:** debug mostra `ORA-04091` (tabela mutante) e `start_workflow: ORA-20999: Additional data row … not found`.
**Causa:** `START_WORKFLOW` chamado de um trigger `AFTER INSERT` da própria tabela da Additional Data; a query lê a tabela em mutação.
**Correção:** iniciar o workflow depois do DML (processo da página, package chamado após o insert) ou registrar um evento numa fila e iniciar por automation.

Fonte: [Viewing Debug Trace Information](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/viewing-debug-trace-information.html), [Understanding Lifecycle Event Strategy](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-lifecycle-event-strategy.html)

### Workflow vai a Faulted (sem error connection, timeout sem conexão ou task errored)

**Sintoma:** instância Faulted no console.
**Causa:** exceção numa atividade sem Error connection correspondente; prazo vencido sem conexão Timeout (inclusive task expirada); task Errored; Switch sobre outcome após task cancelada.
**Correção:** corrigir a causa (dados/variáveis via `UPDATE_VARIABLES` com o workflow suspenso ou faulted) e **Retry** (console ou `apex_workflow.retry`). Não há auto-retry. Para investigar sem debug configurado: `apex_workflow.set_log_level(id, apex_debug_api.c_log_level_app_trace)`, retry e consultar `APEX_DEBUG_MESSAGES` por `workflow_instance_id`.
**Prevenção:** modelar Error connections (por código SQL) e Timeout connections nas atividades com prazo.

Fonte: [States and Transitions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/states-and-transitions.html), [Frequently Asked Questions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/workflow-faqs.html), [Adding a Workflow Connection](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/adding-workflow-connections.html)

### Workflow ou automation usa :APP_USER e obtém nobody (ou dados de session state vazios)

**Sintoma:** participantes, e-mails ou filtros por usuário/empresa não funcionam dentro de workflow ou automation agendada; `:APP_USER` vale `nobody`; app items vazios.
**Causa:** essas execuções rodam em sessão de background sem usuário e sem o session state da página.
**Correção:** usar `APEX$WORKFLOW_INITIATOR`/`APEX$TASK_INITIATOR`, passar o que for necessário como parâmetro, Details Primary Key ou coluna de Additional Data, ou buscar em tabela.

Fonte: [Understanding Background Execution](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-background-execution.html), [Assigning Participants Dynamically](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/assigning-participants-dynamically.html)

### Debug de workflow não aparece no Debug Viewer

**Sintoma:** não há mensagens do workflow no Debug Viewer.
**Causa:** o viewer filtra pela página atual; atividades de workflow não têm página nem usuário (aparecem como `nobody`), e é preciso Debug Level na versão.
**Correção:** limpar o filtro Page, definir Debug Level na versão ou `SET_LOG_LEVEL` na instância.

Fonte: [Viewing Debug Trace Information](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/viewing-debug-trace-information.html), [Enabling Debug Tracing Proactively](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/enabling-debug-tracing-proactively.html)

### Workflow Console vazio ou workflows/tasks de outras aplicações aparecendo

**Sintoma:** o console ou a lista de tasks mostra instâncias de outras apps do workspace, ou nada aparece.
**Causa:** a query gerada não filtra `p_application_id` (lista o workspace inteiro); em contexto multi-tenant, só aparecem itens do Tenant ID da sessão; `GET_WORKFLOWS`/`GET_TASKS` não devolvem nada fora de sessão APEX (SQL Workshop).
**Correção:** descomentar `p_application_id => :APP_ID`; definir o tenant da sessão de forma consistente; testar pela aplicação.

Fonte: [Listing Workflows and Viewing Details](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/listing-workflows-and-viewing-details.html), [Showing Only Current Application Tasks](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/showing-only-current-application-tasks.html), [GET_WORKFLOWS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WORKFLOW.GET_WORKFLOWS-Function.html)

### Instâncias de workflow e task sumiram depois de reinstalar a aplicação

**Sintoma:** após um deploy, todos os workflows e tasks em andamento desapareceram.
**Causa:** a app foi **apagada** e reimportada; apagar a aplicação apaga as instâncias.
**Correção/Prevenção:** sempre importar por cima (mesmo ID, Replace). Depois do import, conferir no console se instâncias ficaram suspensas e retomá-las.

Fonte: [Importing vs. Deleting an Application](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/importing-vs-deleting-application.html), [Managing Workflow Versions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-workflow-versions.html)

### Execution chain em background não executa, fica ENQUEUED ou dá erro de limite

**Sintoma:** job fica em `ENQUEUED`/`SCHEDULED`, ou o usuário recebe erro ao submeter, ou "já em execução".
**Causa:** falta `CREATE JOB` no parsing schema; limites de *Maximum Background Page Process Jobs* (app/workspace) enfileirando; *Executions Limit* do chain excedido; *Serialize* + *When Already Running = Error* para o mesmo Context Value; coordenador roda a cada 2 min.
**Correção:** conceder `CREATE JOB`; ajustar limites; acompanhar em Session > Background Executions; terminar jobs travados (Terminate ou `APEX_BACKGROUND_PROCESS.TERMINATE`).

Fonte: [Understanding Background Page Processing](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-background-page-processing.html), [Limiting and Throttling Background Jobs](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/limiting-and-throttling-background-jobs.html), [Serializing Background Process Jobs](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/serializing-background-process-jobs.html)

### Job em background não enxerga o arquivo enviado pelo usuário

**Sintoma:** o processo em background não encontra a linha em `APEX_APPLICATION_TEMP_FILES`.
**Causa:** *Temporary File Handling* = Ignore (arquivo ficou na sessão do usuário).
**Correção:** `Move` (um chain) ou `Copy` (vários chains) e listar o item em *Temporary File Items*.

Fonte: [Configuring Temporary File Handling](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configuring-temporary-file-handling.html)

### E-mail não chega (APEX_MAIL ou Send E-Mail)

**Sintoma:** nada chega, ou chega com atraso.
**Causa:** instância sem configuração SMTP; ACL de rede não concedida a `APEX_260100`; transação sem commit (a mensagem não entra na fila); fila ainda não processada (job a cada 5 min); falha de entrega com reenvio exponencial (até 14 tentativas); limite diário do workspace; linhas com mais de 1000 caracteres corrompendo a mensagem; From inválido (mensagem não enviada).
**Correção:** verificar `APEX_MAIL_QUEUE` (erro da última tentativa) e `APEX_MAIL_LOG`; `APEX_MAIL.PUSH_QUEUE` para forçar; `APEX_INSTANCE_ADMIN.VALIDATE_EMAIL_CONFIG`; quebrar linhas do corpo; garantir commit.

Fonte: [Configuring Email](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-email.html), [Managing Meta Data](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/managing-meta-data.html), [SEND Function Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SEND-Function-Signature-1.html)

### O remetente (From) do e-mail não é o que o código passou

**Sintoma:** o e-mail sai com outro From.
**Causa:** *Default Email From Address* da instância está definido e **sempre** prevalece.
**Correção:** pedir ao instance admin para limpar/ajustar o atributo; usar `p_replyto` para respostas.

Fonte: [SEND Function Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SEND-Function-Signature-2.html), [Configuring Email](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-email.html)

### APEX_MAIL ou APEX_AI falham quando chamados de job, SQLcl ou SQL Workshop

**Sintoma:** erro de workspace/aplicação ou de sessão ao chamar as APIs fora da app.
**Causa:** usuário de banco não mapeado a workspace / vários workspaces sem contexto; `APEX_MAIL.SEND` com template precisa de `p_application_id`; `APEX_AI` e `APEX_HUMAN_TASK` precisam de sessão APEX.
**Correção:** `apex_util.set_workspace('WS')`; informar `p_application_id`; `apex_session.create_session(...)` e `delete_session` ao final (inclusive no `exception`).

Fonte: [APEX_MAIL](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_MAIL.html), [About Including Generative AI in Applications](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-including-generative-ai-in-applications.html)

### Push notification não chega ao usuário

**Sintoma:** Send Push Notification roda sem erro mas nada aparece no dispositivo.
**Causa:** usuário não fez opt-in naquele dispositivo (o APEX ignora silenciosamente); username com caixa diferente; credenciais regeneradas (exige nova inscrição); plataforma exige PWA instalada; app sem HTTPS/Friendly URLs; fila ainda não enviada (2 min).
**Correção:** `APEX_PWA.HAS_PUSH_SUBSCRIPTION(p_user_name => ...)`; página de settings para opt-in; Installable ligado; consultar `APEX_PUSH_NOTIFICATIONS_QUEUE`; `APEX_PWA.PUSH_QUEUE`.

Fonte: [Delivering Push Notifications](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/delivering-push-notifications.html), [Enabling Push Notifications in an App](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/enabling-push-notifications-app.html), [Opting-In to Receive Push Notifications](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/opting-receive-push-notifications.html)

### Link de notificação abre a home em vez da página indicada

**Sintoma:** clicar no link do e-mail/push leva à página inicial após o login.
**Causa:** Deep Linking desabilitado ou URL relativa.
**Correção:** habilitar Deep Linking (Security Attributes > Session Management) e gerar URL absoluta (`apex_page.get_url(p_absolute_url => true, p_session => 0)`).

Fonte: [Enabling Deep Linking to a Specific Page](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/enabling-deep-linking-specific-page.html), [Overriding Notification Target Link](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/overriding-notification-target-link.html)

### Componente de IA dá erro: No AI Services available ou serviço não configurado

**Sintoma:** Show AI Assistant / Generate Text with AI / atividade de IA falham; o atributo AI da app mostra `No AI Services available`.
**Causa:** não há Generative AI Service no workspace, a app não tem *Service* no atributo AI, IA desabilitada na instância/workspace, ou o segredo do Web Credential não foi definido após importar.
**Correção:** criar o serviço (Test Connection), definir o serviço da app, conferir *AI Enabled* e redefinir o segredo da credencial após cada import.

Fonte: [Configuring Generative AI Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-generative-ai-attributes.html), [Understanding Generative AI Support in APEX](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-generative-ai-support-in-apex.html), [Creating a Dynamic Action to Display AI Assistant](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-a-dynamic-action-to-display-ai-assistant.html)

### Agente com JSON Object não aparece em Show AI Assistant ou Generate Text with AI

**Sintoma:** o agente não é aceito pelo componente.
**Causa:** só agentes com Response Format **Text** são suportados por esses componentes.
**Correção:** usar `APEX_AI.GENERATE(p_agent_static_id => ...)` para JSON ou criar um agente Text.

Fonte: [Managing AI Agents and AI Tools](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-ai-agents-and-ai-tools.html)

---

## 13. Aplicação no Corlix Hub

### Estado atual do Corlix Hub nesta área (o que existe e o que não existe)

Levantamento em `corlixhub/` e `database/f100.sql` (read-only, via grep) em 21/10/2026:
- **Não há** workflows, Task Definitions, automations, Email Templates, Search Configurations, AI Agents nem Vector Providers definidos (`application.apx` e `shared-components/` não têm esses componentes; o f100 não tem `create_workflow`/`create_task_def`/`create_automation`).
- PWA: `p_is_pwa=>'Y'`, `p_pwa_is_installable=>'N'`, `p_pwa_is_push_enabled=>'N'` (PWA ligada, não instalável, sem push), como já registrado em `ai-context/03` §1. Friendly URLs estão em uso (links `r/corlixhub/...`).
- IA: as regiões têm `p_ai_enabled=>false` e o component setting `showAiAssistant` está no padrão; não há serviço configurado.
- Autenticação por **contas APEX** (usernames em maiúsculas; `COLABORADOR.LOGIN_APEX`), papéis por ACL (`colaborador`, `gestor`, `admin-rh`…) e app item `G_ID_EMPRESA`.
- Fluxos que hoje são manuais e se encaixam nos recursos deste documento: **solicitação de correção** (p22 → `pkg_historico_carreira.solicitar_correcao`; resposta pelo RH na p23 via `responder_solicitacao`), **movimentações** em rascunho → efetivação (`HISTORICO_CARREIRA.ST_REGISTRO`, `ID_APROVADOR`), **formações a vencer** (relatório na p20), **notificações** (p5/p8 placeholders), **busca global** do header da p0 sem comportamento, **comunicados** (`PKG_COMUNICADO`).

Qualquer adoção precisa seguir o `ai-context`: editar `corlixhub/*.apx` (nunca o f100), atualizar o documento correspondente em `docs/ai-context/` e escrever passo a passo para o **26.1.5**, marcando "(confirmar no 26.1.5)" o caminho não conferido na tela.

Fonte: [About Workflows](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-workflows.html), [Configuring Progressive Web App Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-progressive-web-app-attributes.html)

### Corlix Hub: pré-requisitos antes de usar workflow, task, automation ou background

1. Confirmar com o time/DBA o `CREATE JOB` para `WKSP_CORLIXHUB` (sem ele nada assíncrono roda). O ambiente atual não está documentado (ver regra 6 do README do ai-context): pergunte.
2. E-mail depende de SMTP na **instância** (OCI/ADB tem procedimento próprio); não há confirmação no repositório de que esteja configurado.
3. `Application Email From Address` não está definido em `application.apx`; defina antes de usar Send E-Mail com `&APP_EMAIL.`.
4. Push exige Installable + Enable Push Notifications + credenciais (regenerar em cada ambiente) + Deep Linking para links.
5. Toda instância assíncrona roda sem `APP_USER` e sem `G_ID_EMPRESA`: **passe `id_empresa` explicitamente** (parâmetro do workflow, coluna da Additional Data ou da Actions Source) e filtre por ela em toda query de atividade, participante, tool de IA e automation (regra de ouro 3).

Fonte: [About Automations](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-automations.html), [Understanding Background Execution](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-background-execution.html), [Configuring Email](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-email.html)

### Corlix Hub: solicitação de correção como Approval/Action Task (proposta)

Hoje a p22 grava em `SOLICITACAO_CORRECAO` e o RH responde pela p23 aberta do Dashboard RH (p20). Uma alternativa nativa, se o time quiser inbox, prazo e histórico:
- Task Definition **Action Task** (o RH executa a correção e conclui) com *Actions Source* = SQL sobre `SOLICITACAO_CORRECAO` ⨝ `COLABORADOR` filtrando `:APEX$TASK_PK`, Subject `Correção solicitada por &NOME_COMPLETO.`.
- Potential Owners: Authorization Scheme `ADMIN_RH` **não basta para multiempresa** (o scheme é por papel, não por empresa): prefira SQL que devolva `upper(login_apex)` dos RHs **da mesma `id_empresa`** da solicitação.
- Ação no **Complete** chamando `pkg_historico_carreira.responder_solicitacao(...)` (mantém a regra de negócio no package e grava o histórico permanente na tabela da app, já que tasks concluídas são purgadas em 7–30 dias).
- Ação no **Create** com Send E-Mail (template) para os RHs; Unified Task List "My Tasks" protegida por `ADMIN_RH` (authorization **na página**, regra 3 do ai-context) e filtrada por `p_application_id => :APP_ID`.
- Participantes por SQL devem usar o username exato da conta APEX (maiúsculas), senão `ORA-20987`.

Isso é uma proposta: não existe no código. Decida com o time antes de substituir a p23.

Fonte: [Creating a Task Definition](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-task-definitions.html), [Associating a Table with a Task](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/associating-table-task.html), [Understanding Task and Workflow Purging](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-task-and-workflow-purging.html)

### Corlix Hub: automations candidatas (formações a vencer, aniversários, fila de eventos)

- **Formações a vencer**: automation agendada diária (`FREQ=DAILY;BYHOUR=8;BYMINUTE=0` — lembre que o horário é do servidor de banco; o módulo de carreira usa `America/Sao_Paulo` via `CONFIG_CARREIRA`), *Actions Initiated On* = Query em `FORMACAO_COLABORADOR` com validade próxima, **por empresa**, ação Send E-Mail com template e/ou push. Commit por linha, Primary Key Column para o log.
- **Fila de eventos**: se um workflow de movimentação for criado, use o padrão trigger → tabela de eventos → automation → `CONTINUE_ACTIVITY` (não chamar APIs de workflow nos triggers do módulo de carreira, que já têm lógica de imutabilidade e auditoria).
- Após cada import da app (deploy), **reativar as automations** (`APEX_AUTOMATION.ENABLE`), pois o import as desabilita.

Fonte: [Understanding Key Automation Concepts](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-key-automation-concepts.html), [About Importing and Exporting Automations](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-importing-and-exporting-automations.html), [Notifying Workflow of Data Changes](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/notifying-workflow-data-changes.html)

### Corlix Hub: e-mail, push e links com checksum

- O projeto exige links com checksum (`pageAccessProtection: argumentsMustHaveChecksum`): em e-mails e push, gere a URL com `apex_page.get_url(..., p_absolute_url => true)` (que inclui checksum) e habilite Deep Linking; nunca monte `f?p` à mão.
- Comunicados (`PKG_COMUNICADO.CRIAR_COMUNICADO`) poderiam disparar e-mail via `APEX_MAIL.SEND` com template ou push via `APEX_PWA.SEND_PUSH_NOTIFICATION(p_user_name => upper(login_apex))`. Como `CRIAR_COMUNICADO` faz commit, o e-mail enfileirado no mesmo bloco antes do commit entra na fila; chamadas depois exigem novo commit.
- Envio em massa (todos os colaboradores da empresa) deve ir para **execution chain em background** ou automation, não para o request da p17.

Fonte: [Generating Page URL for Notification](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/generating-page-url-notification.html), [APEX_MAIL](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_MAIL.html), [SEND_PUSH_NOTIFICATION Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_PWA.SEND_PUSH_NOTIFICATION-Procedure.html), [Offloading Work to the Background](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/offloading-work-background.html)

### Corlix Hub: busca global do header com Search Configurations

A busca do header (p0) não tem comportamento (`ai-context/08`). Caminho nativo: Search Configurations **Standard** para colaboradores (`VW_ORG_COLABORADOR` — atenção: a view **não filtra `id_empresa`**, então a query da configuração deve juntar `COLABORADOR` e filtrar `id_empresa = :G_ID_EMPRESA`), comunicados e equipes; *Link* para a página de destino passando a PK (o link da configuração é gerado pelo APEX); Search page dedicada ou `APEX_SEARCH.SEARCH` numa região de resultados; *Authorization Scheme* na configuração quando a fonte for restrita (ex. histórico só RH). Oracle TEXT/Ubiquitous/Vector exigem índices e (para os dois últimos) Oracle AI Database 26ai: o projeto roda em **23ai**, então **não estão disponíveis** sem upgrade.

Fonte: [Defining a Search Configuration](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/defining-search-configuration.html), [Editing a Search Configuration](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-a-search-configuration.html), [Creating a Ubiquitous Search](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-a-ubiquitous-search.html), [Creating an Oracle Vector Search](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-an-oracle-vector-search.html)

### Corlix Hub: IA generativa com segurança de dados (salário e multiempresa)

Se o time adotar IA (ex. assistente de RH, rascunho de comunicado):
- Dados salariais só podem sair por caminhos que respeitem `fn_carreira_ve_salario` / `ADMIN_RH` e o log de `LOG_ACESSO_SALARIAL`. Tools de agente que consultam carreira devem usar as views/pacotes do módulo e ter **Authorization Scheme** na tool; o LLM só vê o que a tool devolve.
- Toda tool de Retrieve Data deve filtrar `id_empresa = :G_ID_EMPRESA` (no Show AI Assistant a sessão é a do usuário, então o app item está disponível; em workflow/automation, não).
- Tools que alteram dados: *Requires Confirmation* ligado e chamada a packages existentes (não DML solto).
- Use *Request Handler Procedure* para mascarar CPF/salário se for enviar texto livre; não use `p_is_safe => true` com dados digitados por usuários.
- Vector Search/Vector Providers exigem 26ai (o banco do projeto é 23ai).
- Após importar a app em outro ambiente, redefina o segredo do Web Credential do serviço.

Fonte: [Managing AI Agents and AI Tools](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-ai-agents-and-ai-tools.html), [Configuring Generative AI Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-generative-ai-attributes.html), [SET_TOOL_RESULT Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AI.SET_TOOL_RESULT-Procedure-Signature-1.html), [Managing Vector Providers](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-vector-providers.html)

### Corlix Hub: divergências e pontos a confirmar

- **Multiempresa × Tenant ID**: Workflow Console e Unified Task List filtram pelo Tenant ID da sessão (`APEX_SESSION.SET_TENANT_ID`, `APP_TENANT_ID`), mas o Corlix Hub separa empresas por `G_ID_EMPRESA` e não define tenant. Sem tenant (ou sem filtro próprio por empresa nas queries geradas), um admin veria instâncias de todas as empresas. Confirmar com o time antes de adotar.
- **`CREATE JOB`, SMTP, ACL e AI Enabled** no ambiente atual: não documentados no repositório.
- **Banco 23ai**: recursos marcados "26ai" (Vector Providers, Oracle Vector Search, Ubiquitous Search, validação automática de JSON Schema no `APEX_AI.GENERATE`) não se aplicam.
- Nada nesta seção altera o `ai-context`; se algum recurso for implementado, atualizar `ai-context/02`, `03`, `05` ou `06` conforme o caso.

Fonte: [About the Workflow Console, Workflow Details, and Workflow Dashboard](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-workflow-console.html), [Managing Unified Task Lists](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-unified-task-lists.html), [SET_TENANT_ID Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_TENANT_ID.html)
