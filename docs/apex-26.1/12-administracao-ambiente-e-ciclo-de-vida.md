# 12 · Administração, instalação, SQL Workshop, deploy, debug e performance

> Base: documentação oficial Oracle APEX 26.1 (Administration Guide inteiro; Installation Guide inteiro; SQL Workshop Guide: SQL Commands, SQL Scripts, Object Browser, Utilities; App Builder User's Guide: Deploying, Debugging, Managing Application Performance, Managing Team Development, Upgrading Oracle APEX Applications, Directory Structure When Splitting Export Files; Developer's Companion: Understanding Application Lifecycle; Accessibility Guide; Data Reporter; End User's Guide; Licensing Information; API Reference: APEX_DEBUG e APEX_SESSION.SET_DEBUG). Gerado em 21/10/2026.

**Sumário**
1. Mapa rápido: instância × workspace, Autonomous Database e roteiro de diagnóstico
2. Administração do workspace (usuários, grupos, papéis, schemas, quotas, sessões, preferências)
3. Administração da instância (Administration Services: instance settings, segurança, e-mail, wallet, storage, workspaces, export/import, SQLcl)
4. Logs, monitoramento de atividade e purge (Monitor Activity, activity/debug/mail/web service logs, retenção, jobs `DBMS_SCHEDULER`)
5. Instalação, ORDS, multitenant e upgrade da instância
6. Troubleshooting de instalação e upgrade (casos)
7. SQL Commands
8. SQL Scripts
9. Object Browser
10. SQL Workshop Utilities (Data Workshop, Quick SQL, Query Builder, Data Generator, comparação de schemas…)
11. Deploy: export/import, supporting objects, working copies e build options
12. Ciclo de vida da aplicação
13. Debug de aplicações (níveis, Advisor, mensagens, `APEX_DEBUG`)
14. Performance da aplicação
15. Team Development
16. Upgrade de aplicações
17. Estrutura de diretórios do export dividido
18. Acessibilidade · 19. Data Reporter · 20. Guia do usuário final · 21. Licenciamento
22. Aplicação no Corlix Hub

Sintaxe APEXlang dos arquivos `.apx` fica no [09 · APEXlang](./09-apexlang.md); a API `APEX_DEBUG`/`APEX_SESSION` completa, no [06](./06-api-plsql-nucleo.md); Interactive Report/Grid para o usuário final, no [03](./03-relatorios-grids-e-visualizacao.md).

## 1. Mapa rápido: instância × workspace, Autonomous Database e roteiro de diagnóstico

### Três níveis de administração: instância, workspace e aplicação

- **Instância** (*Administration Services*, app separada; on-premises em `/ords/apex_admin`): quem administra é o *Instance Administrator*. Ele cria workspaces, atribui schemas, define quotas, parâmetros de segurança, e-mail, wallet, limites do SQL Workshop (tamanho de script, inatividade do SQL Commands, Transactional SQL Commands), retenção de logs e o nível de debug do sistema. Via PL/SQL: `APEX_INSTANCE_ADMIN` (exige `APEX_ADMINISTRATOR_ROLE` ou SYS).
- **Workspace** (*Workspace Administration*): o *Workspace Administrator* gerencia usuários e grupos, papéis de desenvolvedor, sessões, preferências, Monitor Activity do workspace, purge de logs do workspace e pedidos de serviço (mais schema, mais espaço).
- **Aplicação**: atributos próprios (Debugging, Logging, session timeout da app, build options, build status). A precedência de timeout é **aplicação > workspace > instância**.
- Um desenvolvedor comum do workspace **não** ajusta os limites de instância. Se algo "corta" ou expira (script grande, transação do SQL Commands perdida), a causa pode ser um limite de instância (§3).

Fonte: [What Is an Instance Administrator?](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/what-is-an-instance-administrator.html) · [What is a Workspace Administrator?](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/what-is-a-workspace-administrator.html) · [Configuring Session Timeout for an Instance](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuiring-session-timeout.html)

### APEX no Autonomous Database: o que muda segundo a documentação 26.1

O que a própria documentação diz sobre o APEX hospedado na Oracle Cloud (Autonomous AI Transaction Processing/Lakehouse e APEX Service):
- O APEX já vem instalado, e a Oracle aplica os patch sets e os upgrades. Todos os idiomas vêm instalados. Para controlar o momento do upgrade, a doc remete ao guia do Autonomous (*Control Oracle APEX Upgrades*). Quase todo o §5/§6 (scripts `apexins.sql`, `apxchpwd.sql`, `SYS AS SYSDBA`) vale **só on-premises**.
- Não existe ambiente *runtime-only*. Para endurecer um ambiente, use o parâmetro de instância `RESTRICT_DEV_HEADER`, que bloqueia App Builder e Administration Services.
- Não é preciso configurar ACL de rede: o APEX acessa endpoints externos sem configuração extra. Se uma chamada REST ou e-mail falhar lá, investigue credencial, URL e logs (§4), não a ACL.
- O acesso ao Administration Services e a configuração de e-mail seguem o guia do Autonomous. Várias opções de instância são marcadas como indisponíveis no Oracle Cloud: Web Service Activity Logging, Application Tracing (`&p_trace=YES`), *Unhandled Errors* (HTTP 400), Instance Proxy, workspace isolation por workspace, purge de workspaces inativos e edição do session timeout do workspace pelo Administration Services.
- Os scripts de trace on-premises do debug (d0/d1/ds/d2) não existem lá. A alternativa documentada é *Monitor Activity > Active Sessions* com APEX Trace (LEVEL9) e a coluna *Call Stack* (§13).
- *Load from Cloud* no Data Workshop exige, como ADMIN, `GRANT EXECUTE ON DBMS_CLOUD` e `READ, WRITE ON DIRECTORY DATA_PUMP_DIR` ao schema (§10).

Fonte: [About Accessing APEX in Oracle Cloud](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/accessing-apex-in-oracle-cloud.html) · [Managing Feature Configuration](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-features.html) · [Configuring Service-level Security Settings](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-service-level-security-settings.html)

### Roteiro de diagnóstico de erro numa app APEX hospedada (onde olhar, em ordem)

1. **Reproduza com debug**: rode a página com *Developer Toolbar > Debug* (Info, App Trace) ou `?debug=LEVEL6` na URL; abra *View Debug* e escolha o *View Identifier* da requisição certa (Rendering, Processing ou AJAX; modal é página separada). Detalhes no §13.
2. **Erro de outro usuário**: *Workspace Administration > Monitor Activity > Active Sessions*, abra a sessão e ligue *Debug Level* nela, ou chame `APEX_SESSION.SET_DEBUG` (§13). A mesma tela mostra os itens em session state.
3. **Erros recentes sem reproduzir**: *Monitor Activity > Application Errors* e *Workspace Administration > Dashboards > Activity > Recent Errors* leem o activity log. Erros são gravados no debug log mesmo com debug desligado. Por SQL: `APEX_WORKSPACE_ACTIVITY_LOG` (coluna `DEBUG_PAGE_VIEW_ID`) e `APEX_DEBUG_MESSAGES`.
4. **E-mail que não chegou**: a fila é processada pelo job `ORACLE_APEX_MAIL_QUEUE` a cada 5 minutos, com até 14 tentativas; depois a mensagem sai da fila e o erro fica em `APEX_MAIL_LOG` (§4).
5. **Automation, background process, REST sync atrasados**: dependem dos jobs `DBMS_SCHEDULER` do APEX e de `JOB_QUEUE_PROCESSES` (visível em *Help > About*). Veja os logs de Automation e REST Synchronization (§4).
6. **Erro de compilação de objeto**: *Object Browser* (objetos inválidos, *Utilities > Object Reports > Invalid Objects*) ou `user_errors` (§9).
7. **Lentidão**: debug esquecido ligado, *Monitor Activity* (page views por tempo), Advisor e as recomendações do §14.

Lembre a retenção: os logs têm intervalo padrão de **14 dias** (máximo 180), o activity log alterna entre duas tabelas e perde o bloco antigo de uma vez, e as mensagens de debug têm retenção de pelo menos 2 semanas. Investigue logo.

Fonte: [Monitoring Activity Within a Workspace](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/monitoring-activity-within-a-workspace.html) · [Configuring and Deleting Logs and Log Entries](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-and-deleting-logs-and-log-entries.html) · [DBMS_SCHEDULER Jobs](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/dbms_scheduler-jobs.html)

### SQL Commands × SQL Scripts × SQLcl: qual usar para cada tarefa

| Tarefa | Use | Por quê |
|---|---|---|
| Uma query rápida, testar um `select`, ver `DBMS_OUTPUT` | **SQL Commands** | Mostra até 100.000 linhas (lista *Rows*) e a saída de `DBMS_OUTPUT` inteira; aceita `:bind` (pede o valor) |
| DML que precisa de rollback | SQL Commands com *Autocommit* desmarcado | Só existe se o admin ligou *Transactional SQL Commands*; sair da página ou passar da inatividade máxima (padrão 60 min) faz **rollback** |
| Vários comandos, DDL de módulo, packages | **SQL Scripts** | Guarda o script e o resultado (*Manage Results*); limites de tamanho de script e de resultado definidos pela instância |
| Script com `@`/`@@`, `set define off`, `set serveroutput on`, `show errors` | **SQLcl/SQL Developer** | O SQL Scripts **ignora** comandos SQL*Plus/SQLcl (inclusive `@` e `@@`); o SQL Commands dá erro com eles |
| Export/import de app, deploy reprodutível | **SQLcl** (`apex export`/`apex import`) | Suporta `-split`, APEXlang, `APEX_APPLICATION_INSTALL` (§11) |

Os dois rodam no schema escolhido na lista *Schema* (só aparecem schemas atribuídos ao workspace). A doc do SQL Workshop **não** descreve contexto de sessão de aplicação (app items, `APP_USER` da app) no SQL Workshop: não conte com ele. Código que depende de sessão da app (`APEX_ACL`, app items, `v('APP_USER')`) deve ser testado na própria app ou pelo SQLcl criando a sessão explicitamente. Detalhes nos §7–§8.

Fonte: [Using the Command Editor](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/using-command-editor.html) · [About SQL Scripts](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/sql-scripts.html)

## 2. Administração do workspace (Workspace Administration)

O workspace é a área de trabalho compartilhada onde desenvolvedores entram para criar apps. Ele isola objetos, dados e aplicações de outros workspaces da mesma instalação, e cada workspace pode estar mapeado para um ou mais schemas do banco. A administração do workspace fica no menu **Administration > Administration** do Builder; muitas funções aparecem tanto no menu quanto na página *Workspace Administration*. Regra geral da doc: configurações de instância costumam prevalecer sobre as equivalentes do workspace, e as de aplicação prevalecem sobre as do workspace quando a doc assim indica (ex.: session timeout).

### Papéis de usuário no APEX: end user, developer, workspace administrator e instance administrator

O APEX divide as contas em quatro papéis:

| Papel | O que pode fazer | Onde é gerido |
|---|---|---|
| End user | Só executa apps existentes; não entra no Builder | Workspace Administration > Manage Users and Groups (contas sem flag de admin nem developer) |
| Developer | Cria e edita apps e objetos de banco, monitora atividade do workspace, vê dashboards | Idem, flag *User is a developer* |
| Workspace administrator | Tudo do developer + gerencia contas, grupos, preferências, service requests, logs e sessões do workspace | Idem, flag *User is an administrator* |
| Instance administrator | Superusuário da instância inteira, via aplicação *Administration Services*: cria workspaces, configura features, instance settings e segurança | Administration Services (`/ords/apex_admin` em instalação própria) |

Pontos práticos:
- Para criar um **end user**, desligue os dois flags (administrator e developer).
- Um administrador do workspace sempre tem todos os privilégios de developer, mas componentes desligados pelo instance admin continuam indisponíveis.
- No Autonomous Database / APEX Service, o acesso ao Administration Services é diferente (a doc remete ao guia do Autonomous) e várias funções de instância simplesmente não existem: "some administration functionality is not available in Oracle APEX instances running in Oracle Cloud".

Fonte: [About Oracle APEX User Roles (Managing Users in a Workspace)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/managing-users-in-a-workspace.html), [What is a Workspace Administrator?](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/what-is-a-workspace-administrator.html), [What Is an Instance Administrator?](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/what-is-an-instance-administrator.html)

### Página Workspace Administration: ícones, Tasks e Manage Service

A página *Workspace Administration* tem no topo cinco ícones: **Manage Service**, **Manage Users and Groups**, **Monitor Activity**, **Dashboards** e **Utilization Report**. Abaixo aparecem a *System Message* (definida pelo instance admin) e a *Workspace Message*. À direita, a região **Tasks** traz: Change My Password, About APEX, Manage User Groups, Create User, Create Multiple Users, Delete Multiple Users, Manage Interactive Report Settings, Manage Export Repository e Request a New Workspace.

A página **Manage Service** concentra:
- *Make a Service Request* (schema, storage, término do workspace);
- *Set Workspace Preferences* (login controls, App Builder, SQL Workshop, edição de PL/SQL, REST, Team Development, e-mail, session timeout);
- *Define Workspace Message* e *Define Environment Banner*;
- *Workspace Utilization* e *Manage Extension Links*;
- região **Dashboards** (Workspace, Users, Activity, Developer Activity, Performance, Applications, Database);
- região **Manage Meta Data**: Data Dictionary Cache, Developer Activity and Click Count Logs, Session State, Application Cache, Application Build Status, File Utilization, Interactive Report Settings.

A doc avisa que parte dessas funções não existe em instâncias do Oracle Cloud (caso do Autonomous).

Fonte: [Workspace Administration Page](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/workspace-administration-page.html), [Using the Manage Service Page](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/using-the-manage-service-page.html)

### Criar contas de usuário do workspace (Create User e Create Multiple Users)

Caminho: *Administration > Manage Users and Groups > Create User*. Atributos principais:

| Atributo | Detalhe |
|---|---|
| Username | Até 100 caracteres, sem espaços; só `&` e `.` como especiais. É o valor de `:APP_USER` em apps que usam APEX Accounts |
| Email Address, First/Last Name, Description | Identificação |
| Default Date Format | Formato de data padrão **no SQL Workshop** |
| Default Schema | Schema padrão para navegação, criação de apps e execução de scripts. É preferência, **não** controle de segurança |
| Accessible Schemas (null for all) | Lista separada por `:` que restringe quais schemas do workspace o usuário vê no SQL Workshop |
| User is an administrator / User is a developer | Define o papel |
| App Builder / SQL Workshop / Team Development / Data Reporter Access | Acesso por componente (admin sempre tem); desligado se o componente estiver desligado para o workspace |
| Account Availability | Locked / Unlocked |
| Password, Require Change of Password On First Use | Senha case-sensitive; exigir troca no primeiro uso vale tanto para o Builder quanto para o login em apps |
| Group Assignments | Grupos do usuário |

*Create Multiple Users* aceita uma lista de e-mails separados por vírgula, ponto e vírgula ou quebra de linha; o username pode ser o e-mail completo ou só a parte antes do `@`. Todos recebem a mesma senha e precisam trocá-la no login.

Editar, bloquear/desbloquear, trocar senha e excluir (um ou vários via *Delete Multiple Users*) são feitos na mesma área. Uma conta é bloqueada automaticamente ao exceder *Maximum Login Failures Allowed*.

Fonte: [Managing Users in a Workspace](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/managing-users-in-a-workspace.html)

### Grupos de usuários do workspace (User Groups e Group Grants)

Grupos servem para categorizar usuários e controlar acesso a partes da aplicação; um grupo pode ser membro de outro (*Group Grants*), o que permite atribuir "grupos de aplicação" a "grupos de usuários". Criação em *Manage Users and Groups > Groups > Create User Group*; a associação usuário–grupo é feita no *Edit User* (Group Assignments) e a visão geral em *Group Assignments*.

Pegadinha: os grupos **não são portáveis entre authentication schemes** e são úteis principalmente com APEX Accounts. Se a app usar outro esquema de autenticação, não conte com esses grupos.

Fonte: [Using Groups to Manage Oracle APEX Users (Managing Users in a Workspace)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/managing-users-in-a-workspace.html)

### APEX Accounts: login controls do workspace (expiração, bloqueio, tentativas)

Em *Manage Service > Set Workspace Preferences > Account Login Control*:
- **Account Expiration and Locking** (Enable/Disable): habilita expiração de senha, bloqueio após falhas e senha que expira no primeiro uso, só para contas de end user criadas pela gestão de usuários do APEX. Se o instance admin definir *Require User Account Expiration and Locking = Yes*, o valor fica travado em Enable.
- **Maximum Login Failures Allowed**: inteiro positivo; vazio usa o valor da instância.
- **End User Account Lifetime (days)**: dias de validade da senha; vazio usa *Account Password Lifetime* da instância.

Na instância (Security > Development Environment Settings) os padrões para contas de developer/admin são 4 falhas e 45 dias de vida da senha; esses valores também viram o default das preferências de workspace. A doc observa que, em produção, a Oracle não recomenda APEX Accounts e sugere um provedor de identidade externo.

Fonte: [Configuring Workspace Preferences](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-workspace-preferences.html), [Configuring Authentication Control Development Environment Settings](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-authentication-development-environment-settings.html), [Editing Oracle APEX Accounts](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/editing-apex-accounts.html)

### Preferências do workspace: App Builder, SQL Workshop, edição de PL/SQL, REST e Team Development

Em *Set Workspace Preferences*:
- **Enable App Builder** / **Enable SQL Workshop**: Yes/No. O instance admin pode sobrepor (Manage Component Availability).
- **PL/SQL Editing**: *Allow* ou *Do not allow PL/SQL program unit editing*. Desligar impede editar e compilar packages/procedures pelo Object Browser, mas o desenvolvedor ainda consegue criar/substituir código por **SQL Scripts** ou **SQL Commands**. Serve para desencorajar edição direta no dicionário, não é bloqueio de segurança.
- **Enable RESTful Services** e **Path Prefix**: o prefixo padrão é o nome do workspace e compõe a URL dos serviços ORDS (ex.: `.../apex/qa/hr/employees/`).
- **Team Development**: Enable Team Development, Enable Issue File Repository, Maximum Issue File Size (padrão 15 MB), Enable Feedback File Repository (cria uma tabela local `APEX$` para os arquivos; só editável se a feature estiver liberada na instância).

Fonte: [Configuring Workspace Preferences](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-workspace-preferences.html)

### Credenciais SMTP por workspace (Use Workspace SMTP Credentials)

O envio de e-mail depende de o instance admin ter configurado o e-mail da instância. No workspace, *Set Workspace Preferences > Email* mostra o *Instance SMTP Server* e permite ligar **Use Workspace SMTP Credentials**: aí o APEX autentica no servidor SMTP com uma **Web Credential** do tipo Basic Authentication do próprio workspace (escolhida em *SMTP Authentication Credential* ou criada informando nome, usuário e senha). Há um botão *Test SMTP Credential*. Desligado, valem as credenciais da instância.

Fonte: [Configuring Workspace Preferences](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-workspace-preferences.html)

### Session timeout em três níveis: instância, workspace e aplicação

Três atributos existem em cada nível:

| Atributo | Valores | Default da instância |
|---|---|---|
| Maximum Session Length in Seconds | inteiro > 0; `0` = sem limite; vazio = herda | 28800 s (8 h) |
| Maximum Session Idle Time in Seconds | inteiro > 0; vazio = herda | 3600 s (1 h) |
| Session Timeout Warning in Seconds | inteiro > 0; `0` = sem aviso; vazio = herda | 300 s (5 min) |

Precedência: **aplicação > workspace > instância**. O aviso de idle deixa o usuário estender a sessão; o aviso de duração máxima só pede que salve o trabalho. Em instâncias do Oracle Cloud, a edição de session timeout do workspace pelo Administration Services não está disponível, então no Autonomous o ajuste prático é na própria aplicação (ou nas preferências do workspace, se disponíveis).

Fonte: [Configuring Session Timeout for an Instance](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuiring-session-timeout.html), [Configuring Workspace Preferences](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-workspace-preferences.html), [Viewing Existing Workspace Information](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/viewing-existing-workspace-information.html)

### Service requests do workspace: schema, storage, novo workspace e término

Em *Manage Service > Make a Service Request* o admin do workspace pede: novo schema (ou associar um existente), mais armazenamento, outro workspace, ou término do workspace. Antes de pedir storage, consulte o *Detailed Tablespace Utilization Report* (tablespace, bytes disponíveis, usados, livres, % de uso) e o *Service Request History* (para ver pedidos negados por erro). Os pedidos dependem de o instance admin ter ligado *Enable Service Requests* e são aprovados em *Manage Requests* no Administration Services. *Request a New Workspace* só funciona com Provisioning Method *Request* ou *Automatic*; com *Manual* dá erro.

Fonte: [Making a Service Request](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/making-a-service-request.html), [Requesting a Workspace in Workspace Administration](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/requesting-a-workspace-iniworkspace-administration.html)

### Session State do workspace: ver, remover sessão ou estado, purgar por idade

*Manage Service > Session State* oferece:
- **Recent Sessions** → clicar no ID abre *Session Details*, com dois botões:
  - **Remove State**: apaga o estado (itens e collections) mas mantém o registro da sessão. Equivale a limpar cache com `SESSION` na URL; útil para depurar.
  - **Remove Session**: apaga o registro em `SESSIONS` e o estado; o usuário daquela sessão terá de se autenticar de novo. Útil para tirar o acesso de um usuário específico.
- **Session State for Current Session**: ver o estado da sua sessão.
- **Purge Sessions by Age**: escolher a idade; *Report Sessions* mostra totais antes de *Purge Sessions*.
- **Purge Session State for Current Session**.

As sessões ficam no banco até serem purgadas. Ver a seção 4 sobre o job de purge.

Fonte: [Managing Session State for a Workspace](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/managing-session-state-for-a-workspace.html)

### User preferences: APEX_UTIL.SET_PREFERENCE, GET_PREFERENCE e REMOVE_PREFERENCE

Preferências guardam valores por usuário **entre sessões**. Formas de definir: processo do tipo *User Preferences*, item com Source Type *Preference*, ou PL/SQL:

```sql
APEX_UTIL.SET_PREFERENCE(p_preference => 'NAMED_PREFERENCE', p_value => :ITEM_NAME);
-- leitura com default
NVL(APEX_UTIL.GET_PREFERENCE('NAMED_PREFERENCE'), 15)
-- remoção
APEX_UTIL.REMOVE_PREFERENCE(p_preference => 'NAMED_PREFERENCE');
```

O processo *User Preferences* com *Reset Preferences* apaga todas as preferências do usuário atual. Para limpar a sessão atual, a doc mostra o processo *Clear Session State > Clear Current Session*. O admin vê e purga preferências em *Session State > Preferences by User / Current User Preferences / Purge Preferences by User*.

Fonte: [Managing User Preferences](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/managing-user-preferences.html)

### Cache de páginas e regiões (Application Cache) e Data Dictionary Cache

- **Application Cache** (*Manage Meta Data*): purga regiões em cache por região, página, aplicação ou workspace, e páginas expiradas por aplicação. O cache é configurado pelo atributo *Caching* da página/região. Se uma região "não atualiza" depois de mudar dados ou código, verifique se há cache ligado e purgue aqui.
- **Data Dictionary Cache**: estatísticas e análise das tabelas dos schemas do workspace, usadas pelos wizards *Create Application* / *Create Page* (inclusive para decidir facetas em Faceted Search). O job noturno `ORACLE_APEX_DICTIONARY_CACHE` atualiza; manualmente use *Gather Statistics and Refresh Cache* ou *Refresh Cache Only*. Se um wizard não enxerga uma tabela ou coluna recém-criada, atualize esse cache.

Fonte: [Managing Page and Region Caching](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/managing-page-and-region-caching.html), [Accessing the Data Dictionary Cache Report from Workspace Administration](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/accessing-data-dictionary-cache-from-workspace-administration.html)

### Build Status e Status das aplicações (Run Application Only, Available, Unavailable)

**Build Status** tem dois valores: *Run and Build Application* (roda e edita) e *Run Application Only* (só roda; no nível de instância a app nem aparece na lista do App Builder). Pode ser alterado na app (Edit Application > Availability), para todas as apps do workspace (*Manage Meta Data > Application Build Status*) ou pelo instance admin. Pegadinha: se uma app for implantada como *Run Application Only*, só o instance admin consegue voltar o Build Status (Administration Services > Build Status).

Na mesma página do workspace dá para ajustar o **Status** de cada app: *Available*, *Available with Developer Toolbar* (exige estar logado no Builder no mesmo navegador), *Available to Developers Only*, *Restricted Access* (lista de usuários), *Unavailable*, *Unavailable (Status Shown with PL/SQL)* e *Unavailable (Redirect to URL)*.

Fonte: [Changing Build Status for Multiple Applications](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/changing-build-status-for-multiple-applications.html), [Changing Application Build Status in Administration Services](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/changing-app-build-status-in-administration-services.html)

### Environment banner, workspace message e Extension menu

- **Environment Banner** (*Manage Service > Define Environment Banner*): Enable, Position (Left/Top), Label, Color. Aparece no App Builder e na Developer Toolbar em runtime. O do workspace sobrepõe o da instância. Útil para diferenciar DEV/TEST/PROD.
- **Workspace Message**: texto (aceita HTML) exibido na home do workspace e na Workspace Administration.
- **Extension menu** (*Manage Service > Manage Extension Links*): links customizados no menu do Builder (entre a busca global e o menu Administration), com Sequence, Label, URL, Public, Tab Identifier e Description. As URLs só aceitam as substituições `EXT_WORKSPACE_NAME`, `EXT_WORKSPACE_ID`, `EXT_APP_ID`, `EXT_APP_NAME`, `EXT_APP_ALIAS`, `EXT_PAGE_ID`, `EXT_PAGE_NAME`, `EXT_PAGE_ALIAS`, `APP_USER` e `APP_SESSION_ID`, em sintaxe `&ITEM.`. Para assinar links de outro workspace, o workspace hospedeiro precisa de *Allow Hosting Extension* (Manual ou Automatic Subscription, definido pelo instance admin) e links *Public = Yes*; a assinatura pode conceder *Has Read Access* aos metadados, acessíveis em PL/SQL via `APEX_EXTENSION.SET_WORKSPACE`.

Fonte: [Configuring an Environment Banner for a Workspace](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-environment-banner-for-workspace.html), [Defining a Workspace Message](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/defining-a-workspace-message-in-workspace-administration.html), [About the Extension Menu](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/about-the-extension-menu.html), [Managing Extension Subscriptions](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/managing-extension-subscriptions.html)

### Saved Interactive Reports, Export Repository, File Utilization e About APEX

- **Saved Interactive Reports** (*Tasks > Manage Interactive Report Settings*): há quatro tipos — *Primary Default* e *Alternative* (só developer), *Public* e *Private* (end user). O admin lista e apaga relatórios salvos e assinaturas (*Subscriptions*) de IR.
- **Manage Export Repository**: baixar ou apagar arquivos de export guardados no workspace.
- **File Utilization**: identifica o que mais ocupa a cota de armazenamento do workspace.
- **Workspace Utilization Report**: resumo de schemas, apps, scripts do SQL Workshop, Team Development, atividade e contagem de objetos; pode ser enviado por e-mail.
- **About Oracle APEX** (*Help > About*): Product Build, Schema Compatibility, Host Schema, Application Owner, Workspace ID/Name, hora do servidor, ambiente CGI, versão do banco, character set, `JOB_QUEUE_PROCESSES` e disponibilidade do Multilingual Engine (MLE, 21c+). É o primeiro lugar para confirmar versão exata do APEX e o schema do engine.

Fonte: [Managing Saved Interactive Reports](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/managing-saved-interactive-reports.html), [Managing Export Files in the Current Workspace](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/managing-exported-files.html), [Viewing File Utilization](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/file-utilization.html), [Viewing a Workspace Summary](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/viewing-a-workspace-summary.html), [Viewing the About Oracle APEX Page](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/viewing-the-about-oracle-apex-page.html)

### Dashboards do workspace (Workspace, Users, Activity, Developer Activity, Performance, Applications, Database)

Em *Administration > Dashboards*:
- **Workspace**: serviço, schemas disponíveis, arquivos por tipo, service requests pendentes.
- **Users**: sua conta, estatísticas de usuários, grupos, recém-criados, status (senhas expiradas, contas bloqueadas, contas sem e-mail).
- **Activity**: top usuários, apps e páginas, logins recentes e **Recent Errors** (erros do activity log do workspace) — atalho rápido para achar erros de runtime.
- **Developer Activity**: top developers/apps/páginas, mudanças recentes.
- **Performance**: páginas com pior desempenho, calculado como número de eventos de página (gets, posts, partial page gets) × mediana do tempo de geração no servidor.
- **Applications**: resumo, grupos de apps, recém-criadas, defaults.
- **Database**: program units modificados recentemente, contagem de objetos, tabelas recentes, top tabelas por linhas (com base em estatísticas).

Fonte: [Viewing Workspace Dashboards](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/viewing-workspace-dashboards.html)

## 3. Administração da instância (Administration Services)

O *Administration Services* é uma aplicação separada para quem administra a instância toda. Em instalação própria, fica por padrão em `http://hostname:port/ords/apex_admin` (link "Administration" na tela de login do APEX). No **Autonomous Database** e no **APEX Service** o acesso é diferente e documentado no guia de cada serviço, e muitas funções desta seção estão marcadas como indisponíveis em Oracle Cloud. Para um agente trabalhando no Autonomous, trate esta seção como referência de comportamento: em geral só o administrador do Autonomous (usuário `ADMIN`) tem esse acesso, e algumas opções não aparecem.

### Estrutura do Administration Services: Manage Requests, Manage Instance, Manage Workspaces e Monitor Activity

- **Home**: Pending Requests, System Message, *Instance Tasks* (Jump to workspace/app/user, Feature Configuration, Security, Instance Settings, Workspace Purge Settings), *Workspace Tasks* (Create Workspace, Find a Workspace, Create User, Reset User Password) e *Available Updates* (verifica atualizações do APEX/ORDS enviando versões à Oracle; pode ser desligado).
- **Manage Instance**: Instance Settings (Feature Configuration, Security, Instance Settings, Workspace Purge Settings), Manage Meta Data (Session State, Mail Queue, Installed Translations, Interactive Report Subscriptions), Messages (banner, login message, system message, site-specific resources), **Manage Logs and Files** e Self Service Sign Up.
- **Manage Workspaces**: criar/remover/bloquear workspaces, schema assignments, developers e users, component availability, relatórios, export/import, Application Attributes, Build Status, Parsing Schemas.
- **Monitor Activity**: relatórios de toda a instância (ver seção 4).

Fonte: [Overview: Administration Services UI](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/overview-administration-services-ui.html), [Signing In To Administration Services](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/accessing-oracle-application-express-administration-services.html)

### Feature Configuration: Application Development e backups automáticos de aplicação

*Manage Instance > Feature Configuration > Application Development*:
- **Allow PL/SQL Program Unit Editing** (instância): Yes/No.
- **Create demonstration objects in new workspaces**.
- **Number of backups per application**: backups automáticos das apps alteradas, feitos pelo job `ORACLE_APEX_BACKUP` (diário, 02:00). Os mais antigos são apagados na manutenção diária; no máximo 30 por app; `0` ou nulo desliga o recurso e o job. O resultado aparece no *Backup Log* (Monitor Activity > Logs).
- **Allow External Links**: No esconde links externos (documentação, fóruns) do Builder e SQL Workshop, útil em ambientes desconectados.

Fonte: [Managing Feature Configuration](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-features.html), [DBMS_SCHEDULER Jobs](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/dbms_scheduler-jobs.html)

### Feature Configuration: limites do SQL Workshop (SQL Commands e SQL Scripts)

Na seção *SQL Workshop* da Feature Configuration a instância define os limites que valem para todos os workspaces:

| Atributo | Efeito |
|---|---|
| SQL Commands Maximum Inactivity in minutes | Tempo máximo que um comando **transacional** do SQL Commands espera antes de dar timeout |
| SQL Scripts Maximum Script Output Size in bytes | Saída máxima gerada por um script |
| SQL Scripts Maximum Workspace Output Size in bytes | Espaço total que os resultados de todos os scripts do workspace podem ocupar |
| SQL Scripts Maximum Script Size in bytes | Tamanho máximo de um script |
| Enable Transactional SQL Commands | Yes permite vários comandos na **mesma transação** e adiciona a caixa **Autocommit** no SQL Commands |
| Maximum File size for Data Loading in bytes | Limite geral para Data Loading (XML/XLSX e JSON em bancos antigos têm limites menores) |
| Data Loading Job Class | Job class `DBMS_SCHEDULER` dos jobs de carga (padrão `SYS.DEFAULT_JOB_CLASS`) |
| Enable SQL Developer Web | Mostra o item SQL Developer Web (Database Actions) no menu SQL Workshop; exige ORDS 23.1+ com HTTPS |

Consequência para agentes: se um script "corta" a saída ou falha por tamanho, ou se o SQL Commands perde a transação após inatividade, a causa pode ser um desses limites de instância, que no Autonomous não são ajustáveis pelo desenvolvedor do workspace.

Fonte: [Managing Feature Configuration](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-features.html)

### Feature Configuration: Monitoring (Database Monitoring, Application Activity Logging, Web Service Logging, Application Tracing)

- **Enable Database Monitoring**: libera a página *Database Monitor* do SQL Workshop, que só usuários com conta de banco com role DBA acessam.
- **Application Activity Logging**: *Use Application Settings* (padrão; respeita o atributo *Logging* de cada app), *Never* ou *Always*. Sem logging, page views da app não entram no activity log.
- **Web Service Activity Logging**: *Use Application Settings* (padrão, decide pelo atributo *Log Web Service Requests* do workspace), *Never*, *Always*. **Indisponível em Oracle Cloud.**
- **Enable Application Tracing**: com Yes, apps com Debug habilitado podem gerar trace de banco com `&p_trace=YES` na URL; com No, o pedido é ignorado em silêncio. **Indisponível em Oracle Cloud.** Parâmetro de API: `TRACING_ENABLED`.

Fonte: [Managing Feature Configuration](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-features.html)

### Feature Configuration: REST, Service Requests e Team Development para novos workspaces

- **REST > Enable RESTful Services**: liga/desliga serviços RESTful mapeados para SQL e PL/SQL; **Swagger UI URL** aponta para um servidor Swagger UI 2.0+ usado pelo REST Workshop ao gerar documentação (sem URL, sai JSON cru).
- **Workspace Administration > Enable Service Requests**: permite aos admins de workspace pedir schema, storage ou término.
- **Team Development** (só para workspaces **novos**): Enable Issue File Repository, Maximum File Size (padrão 15 MB), Enable Feedback File Repository, Maximum Feedback File Size (padrão 15 MB).

Fonte: [Managing Feature Configuration](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-features.html)

### Security: cookies persistentes, Persistent Authentication e bloqueios de login

Em *Manage Instance > Security > Security*:
- **Set Workspace Cookie**: controla cookies persistentes `ORA_WWV_REMEMBER_UN` (workspace/usuário no login do Builder), `LOGIN_USERNAME_COOKIE` (usuário no login de apps) e `ORA_WWV_REMEMBER_LANG` (idioma do Builder).
- **Allow Persistent Authentication** + **Persistent Authentication Lifetime Days**: habilita a API de "lembrar login" (`APEX_AUTHENTICATION`); o cookie tem o nome do cookie de sessão com sufixo `$P`, um por app.
- **Disable Administrator Login**: impede acesso ao Administration Services. Para reverter:
  ```sql
  ALTER SESSION SET CURRENT_SCHEMA = APEX_260100;
  BEGIN
    APEX_INSTANCE_ADMIN.SET_PARAMETER('DISABLE_ADMIN_LOGIN', 'N');
    COMMIT;
  END;
  /
  ```
- **Disable Workspace Login**: transforma a instância em "runtime only" na prática (admins da instância ainda entram).
- **Disable Apps Login**: Yes, *Only for Specific Apps* (lista de IDs, ex. `100,101`) ou No.
- **Allow Public File Upload**: se usuários não autenticados podem fazer upload.
- **Restrict Access by IP Address**: lista de IPs (curinga `*` só no final, ex. `141.*`) para Builder e Administration Services.

Fonte: [Configuring Service-level Security Settings](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-service-level-security-settings.html)

### Security: AI Services, proxy, DBMS credentials, checksum hash, Rejoin Sessions e Unhandled Errors

- **AI Enabled** (instância e workspace) e **App Builder Proxy for AI Services** (se vazio, usa o Instance Proxy). O limite **Maximum AI Tokens** por 24 h fica em Workspace Isolation e pode ser refinado no workspace ou no AI Service.
- **Allow DBMS Credentials Usage**: torna credenciais do banco utilizáveis em todos os workspaces; exige que o schema `APEX_NNNNNN` tenha EXECUTE e que exista sinônimo público. Necessário para integrar com Fusion Applications.
- **Instance Proxy** / **Instance No Proxy Domains**: proxy para todo tráfego HTTP(S) de saída (regiões URL, web services, impressão); sobrepõe proxies de app. **Indisponível em Oracle Cloud.**
- **Checksum Hash Function**: recomenda-se *Most Secure* (SHA-2 512 bits em 12c+). Mudar não altera o *Bookmark Hash Function* das apps existentes; a Oracle recomenda expirar bookmarks e então alinhar.
- **Rejoin Sessions**: *Disabled*, *Enabled for Public Sessions* ou *Enabled for All Sessions* (este exige SSP com checksum válido ou URL sem payload, e *Embed in Frames* = same origin ou Deny). O nível de instância mais restritivo vence app e página. A Oracle recomenda deixar desligado salvo com isolamento de workspace por hostname.
- **Unhandled Errors**: *Show Error Page* (padrão) ou *Return HTTP 400*. **Indisponível em Oracle Cloud.**

Fonte: [Configuring Service-level Security Settings](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-service-level-security-settings.html)

### Security: HTTPS, Require Outbound HTTPS e HTTP Response Headers

*Security > HTTP Protocol*:
- **Require HTTPS**: *Always* (tudo, inclusive Builder; exibe *Strict-Transport-Security Max Age*), *Development and Administration* (só apps internas) ou *Application specific* (depende do *Secure* cookie do authentication scheme da app).
- **Require Outbound HTTPS**: todo tráfego de saída deve ser HTTPS.
- **HTTP Response Headers**: cabeçalhos extras enviados em todas as apps (um por linha); é o caminho para Content Security Policy no nível de instância.

Reverter por SQL (como SYS, com `ALTER SESSION SET CURRENT_SCHEMA = APEX_260100`):
```sql
BEGIN APEX_INSTANCE_ADMIN.SET_PARAMETER('REQUIRE_HTTPS', 'N'); COMMIT; END;
/
BEGIN APEX_INSTANCE_ADMIN.SET_PARAMETER('REQUIRE_OUT_HTTPS', 'N'); COMMIT; END;
/
```

Fonte: [Configuring HTTP Protocol Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-http-attributes.html)

### Workspace Isolation: Allow Hostnames, Resource Consumer Group e limites de concorrência

Configurável na instância (Security > Workspace Isolation, como padrão) e por workspace (Edit Workspace Information, que sobrepõe). **Indisponível no nível de workspace em Oracle Cloud.**

| Atributo | O que faz |
|---|---|
| Allow Hostnames | Hostnames aceitos na URL; isola workspaces pela same-origin policy do navegador. Com REST, também exige pool em `url-mapping.xml` do ORDS, que passa a ignorar o *RESTful Path Prefix* |
| Resource Consumer Group | Consumer group do Resource Manager aplicado no início de cada request do APEX. Não vale para jobs do Scheduler criados pelo dev nem para REST do ORDS sem APEX no caminho |
| Maximum Concurrent Workspace Requests | Limite de eventos de página simultâneos no workspace; rastreado por `GV$SESSION.CLIENT_INFO` (não sobrescreva com `DBMS_APPLICATION_INFO.SET_CLIENT_INFO`) |
| Maximum Concurrent Session Requests | Limite por sessão APEX; rastreado por `GV$SESSION.CLIENT_IDENTIFIER` (não sobrescreva com `DBMS_SESSION.SET_IDENTIFIER`) |
| Concurrent Session Requests Kill Timeout | Segundos após os quais o APEX pode matar a sessão de banco mais antiga daquela sessão APEX (pode afetar o pool) |
| Maximum Size of Files in Workspace | Total em bytes de uploads |
| Maximum Email Messages | Limite diário de `APEX_MAIL` por workspace |
| Maximum Web Service Requests | Limite em janela móvel de 24 h |
| Content Cache target size / maximum entry size | Cache usado por Web Source e REST Enabled SQL (limite "soft", mantido pelos jobs) |
| Maximum Background Page Process Jobs | Jobs simultâneos para processos de página em background |
| Maximum AI Tokens (instância) | Tokens de IA por 24 h por workspace |

Fonte: [Isolating All Workspaces in an Instance](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/isolating-workspaces-in-an-instance.html), [Isolating a Workspace to Prevent Browser Attacks](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/isolating-workspace-to-prevent-browser-attacks.html)

### Excluded Domains e Authorized URLs (APEX_UTIL.COUNT_CLICK)

- **Region and Web Service Excluded Domains** (*Domain Must Not Contain*): domínios separados por `:` que regiões do tipo URL e web services não podem acessar; o usuário recebe erro de domínio restrito.
- **Authorized URLs**: lista de URLs aceitas como parâmetro em certas APIs, como `P_NEXT_URL` de `APEX_UTIL.COUNT_CLICK`. Se a URL não for relativa nem do host atual, precisa casar com o início de uma URL autorizada.

Fonte: [Defining Excluded Domains for Regions and Web Services](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/defining-excluded-domains-for-regions-and-web-services.html), [Managing Authorized URLs](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/managing-authorized-urls.html)

### Authentication Controls e esquemas de autenticação do Builder (resumo)

- **General Settings**: *Delay after failed login attempts in Seconds* (`0` desliga), *Method for computing the Delay* (baseado no Login Access Log), *Inbound Proxy Servers* (para calcular o IP real via `X-Forwarded-For`/`REMOTE_ADDR`), *Single Sign-On Logout URL*.
- **Development Environment Settings**: *Username Validation Expression* (regex; `*` desliga), *Require User Account Expiration and Locking*, *Maximum Login Failures Allowed* (padrão 4, contas dev/admin), *Account Password Lifetime (days)* (padrão 45), *Data Reporter Authentication Scheme*.
- **Development Environment Authentication Schemes**: o esquema marcado *Current* autentica instance admins, workspace admins e developers. Opções: Oracle APEX Accounts, Database Accounts (valida contra usuários do banco, sem abrir sessão para eles), HTTP Header Variable (padrão `OAM_REMOTE_USER`), LDAP Directory (porta padrão 389; SSL com autenticação exige wallet; `%LDAP_USER%` no DN), Oracle Application Server SSO, SAML Sign In e Social Sign-In (OpenID Connect/OAuth2). Todos aceitam código PL/SQL com *Pre-* e *Post-Authentication Procedure*. Mesmo com esquema externo, os usuários precisam existir como developers/admins no workspace. Também configurável via parâmetro `APEX_BUILDER_AUTHENTICATION` de `APEX_INSTANCE_ADMIN`.
- **Data Reporter** exige SAML, Social Sign-In ou HTTP Header Variable.
- **Password Policy**: hash, tamanho mínimo, diferenças mínimas, exigência de letra/número/pontuação/maiúscula/minúscula, não conter username/nome do workspace/lista de palavras; para *service administrators*, pode usar a política padrão forte (6+ caracteres, mistura de classes, sem username nem "Internal").
- **Allow Real Application Security**: se o authentication scheme usar RAS, o APEX cria e anexa uma sessão RAS.

Fonte: [Configuring Authentication Control General Settings](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-authentication-control-general-settings.html), [About Configuring Authentication Schemes](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/about-configuring-authentication-schemes.html), [Creating Strong Password Policies](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/creating-strong-password-policies.html), [Enabling Real Application Security](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/enabling-real-application-security.html)

### SAML rejeitado com "Invalid value for parameter"

**Sintoma:** login via SAML falha e o APEX rejeita o payload com `Invalid value for parameter`.
**Causa:** o Identity Provider assina só a *SAML Assertion*; o APEX exige assinatura tanto da Assertion quanto da *SAML Response*.
**Correção:** configurar o IdP para assinar Assertion e Response. Além disso, o ORDS precisa aceitar requisições cross-origin do IdP: defina `security.externalSessionTrustedOrigins` com a origem do IdP.
**Prevenção:** SAML exige Oracle Database 19c RU 19.9+ ou 26ai; se o esquema SAML não aparecer mesmo com a versão correta, rode como SYSDBA `set serveroutput on` e `exec sys.validate_apex`.

Fonte: [Editing SAML Sign In](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/editing-saml-sign-in.html)

### Instance Settings: provisionamento de workspaces e Service Signup Wizard (resumo)

*Instance Settings > Workspace Creation > Provisioning Method*: **Manual** (instance admin cria e avisa), **Request** (usuário pede, admin aprova, usuário confirma por link de e-mail) ou **Automatic** (aprovação automática). Request/Automatic exigem e-mail configurado e fazem aparecer o link de pedido na tela de login. **Email Provisioning = Disabled** desliga o provisionamento e mostra uma mensagem. O *New Service Signup Wizard* pode exigir justificativa, aceite de termo e pesquisa, e há bloqueio por padrão de e-mail (ex. `%@example.com`). Seleção do método de provisionamento é **indisponível em Oracle Cloud**. Se a criação falhar, o pedido volta a `Requested` e o usuário recebe "Please contact administrator."; mudar um pedido `Approved` para `Requested` sem terminar o serviço antes pode corromper dados.

Fonte: [About Configuring Workspace Provisioning](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/about-configuring-workspace-provisioning.html), [Managing Requests](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/managing-workspace-and-change-requests.html), [Creating a Service Signup Wizard](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/including-an-agreement-or-survey-when-running-the-signup-wizard.html)

### Instance Settings: Storage (tablespaces, quotas e exclusão automática de arquivos enviados)

*Instance Settings > Storage*:
- **Require New Schema**: obriga pedido de schema novo ao pedir workspace.
- **Instance Tablespace**: tablespace(s) existente(s) para os usuários de novos workspaces; vazio cria tablespace nova.
- **Auto Extend Tablespaces**: datafile criado com 1/10 do tamanho pedido e crescendo até o tamanho pedido.
- **Bigfile Tablespaces** e **Encrypted Tablespaces** (TDE; exige wallet de criptografia aberta antes de provisionar).
- **Automatically Approve Requests**: aprova pedidos de storage até um tamanho; só com Provisioning Method Automatic.
- **Delete Uploaded Files After (days)**: apaga automaticamente, em todos os workspaces, exports de aplicação/página/CSS/imagens/static files/temas/plug-ins/scripts/workspace, imports de planilha/texto/XML e UI defaults. Nulo = nunca. O resultado fica no *Automatic File Delete Log*.
- **New Workspace Request Size / Workspace Change Request Size**: opções de tamanho (MB) oferecidas nos pedidos.

Ao criar workspace com schema novo, o APEX cria tablespace e datafile; com Oracle-Managed Files, o local vem de `DB_CREATE_FILE_DEST`.

Fonte: [Configuring Storage](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-storage.html), [Configuring Workspace Size Requests](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-workspace-size-requests.html), [Creating Workspaces in Administration Services](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/creating-workspaces.html)

### Instance Settings: e-mail (SMTP, limites e ACL de rede)

Atributos de *Instance Settings > Email* (ambiente de desenvolvimento completo):

| Atributo | Detalhe |
|---|---|
| Oracle APEX Instance URL | URL da instância com barra final (usada em e-mails do sistema) |
| Oracle APEX Images URL | URL completa de `/i/` com barra final |
| SMTP Host Address | Padrão `localhost` |
| SMTP Host Port | Padrão 25 |
| SMTP Authentication Username / Password | Podem ser sobrepostos por Web Credential no workspace |
| Use SSL/TLS | Yes, *After connection is established* (`STARTTLS`) ou No |
| Default Email From Address | Remetente de e-mails do sistema |
| Maximum Emails per Workspace | Limite de `APEX_MAIL` por workspace em 24 h |
| Maximum Emails Processed per Workspace | Quantos e-mails da fila são processados por execução do job `ORACLE_APEX_MAIL_QUEUE` |

Em ambiente runtime, use `APEX_INSTANCE_ADMIN.SET_PARAMETER`, valide com `APEX_INSTANCE_ADMIN.VALIDATE_EMAIL_CONFIG` e consulte com `APEX_INSTANCE_ADMIN.GET_PARAMETER`. Sem ACL de rede (`DBMS_NETWORK_ACL_ADMIN`) para o schema `APEX_260100`, falham envio de e-mail, consumo de web services, LDAP de saída e impressão via BI Publisher. **No Autonomous Database**, a doc remete à página "Send Email from APEX" do guia do Autonomous: a configuração de e-mail é feita de outra forma.

Fonte: [Configuring Email](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-email.html)

### APEX_MAIL não entrega: erro em web service, e-mail ou LDAP por falta de ACL

**Sintoma:** `APEX_MAIL` aceita a chamada mas o e-mail não sai; chamadas a web services, LDAP ou impressão BI Publisher falham.
**Causa:** desde o 11gR2 o acesso a serviços de rede vem desligado; o schema do engine (`APEX_260100`) não tem privilégio de connect no host.
**Correção:** o DBA concede o acesso com `DBMS_NETWORK_ACL_ADMIN` para o host/porta necessários; depois confira a fila em *Manage Instance > Mail Queue* e o `APEX_MAIL_LOG`.
**Prevenção:** validar a configuração com `APEX_INSTANCE_ADMIN.VALIDATE_EMAIL_CONFIG` após mudanças. No Autonomous, siga o procedimento próprio do serviço.

Fonte: [Configuring Email](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-email.html)

### Instance Settings: Wallet para chamadas HTTPS, SMTP seguro e LDAP com SSL

A wallet guarda certificados e chaves usados por SSL. É necessária para: chamar URL HTTPS (web service), região URL HTTPS, SMTP com *Use SSL/TLS*, LDAP com *SSL with Authentication*. O DBA cria a wallet no servidor do banco; o instance admin informa **Wallet Path** (`file:/home/<user>/wallets`), **Auto-login Wallet** ou **Wallet Password**. Em runtime: parâmetros `WALLET_PATH` e `WALLET_PWD` via `APEX_INSTANCE_ADMIN.SET_PARAMETER`. A doc 26.1 observa que, em **Oracle AI Database 26ai ou superior, a configuração de wallet pode ficar vazia** (ver `SET_WALLET` no guia de pacotes PL/SQL).

Fonte: [Configuring Wallet Information](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-wallet-information.html)

### Instance Settings: Report Printing (Native, Apache FOP, BI Publisher, APEX Office Print, Document Generator)

A impressão é configurada em três níveis: instância (Print Server), aplicação (*Print Server Type* na Application Definition, que sobrepõe) e região (habilitar impressão do relatório). Opções de servidor:
- **None (Native)**: CSV, HTML, PDF e XLSX sem servidor externo.
- **External (Apache FOP)**: templates XSL-FO; host/porta padrão `localhost:8888`, script `/xmlpserver/convert`, *Print Timeout*.
- **Oracle BI Publisher**: exige licença; templates RTF ou XSL-FO.
- **APEX Office Print**: templates MS Office; *API Key* só para AOP Cloud.
- **Oracle Document Generator Pre-built Function** (OCI): exige banco com `DBMS_CLOUD`, credencial de nuvem (criável com `APEX_INSTANCE_ADMIN.CREATE_CLOUD_CREDENTIAL`), namespace e bucket do Object Storage, OCID e endpoint da função.

Em runtime, parâmetro `PRINT_BIB_LICENSED` aceita `STANDARD`, `ADVANCED`, `DOCUMENT_GENERATOR`, `AOP`, `NONE`, além de `PRINT_SVR_HOST`, `PRINT_SVR_PORT`, `PRINT_SVR_PROTOCOL`, `PRINT_SVR_SCRIPT`.

Fonte: [Configuring Report Printing for an Instance](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-report-printing-for-an-instance.html)

### Instance Settings: retenção de tasks e workflows, Background Jobs, Application ID Range, Gallery e Help

- **Workflow Settings**: *Retention Period Days* de human tasks concluídas (máx. 30, padrão 7) e *Workflow Retention Period Days* (máx. 100, padrão 30). Workflows terminados/cancelados saem na próxima purga; ativos, suspensos e com falha não são purgados.
- **Background Jobs**: *Background Job Class* (job class do `DBMS_SCHEDULER` para Automations, REST Synchronization e Report Notification; padrão `SYS.DEFAULT_JOB_CLASS`) e *Minimum Execution Cadence (Minutes)* para Automations e REST Sync.
- **Application ID Range**: ID Minimum/Maximum para novas apps, útil para mover workspaces entre instâncias mantendo IDs.
- **Application Gallery**: Sample/Starter Apps vêm do GitHub; *Enable Background Installation* pode ser desligado se jobs estiverem desabilitados; `manifest.json` permite hospedar apps internamente ou incluir Custom Apps (o servidor precisa enviar `Access-Control-Allow-Origin`).
- **Help URL**: destino do menu Help do Builder.

Fonte: [Configuring Workflow Settings](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-workflow-settings.html), [Configuring Background Jobs](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-background-jobs.html), [Managing Application ID Range](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/managing-application-id-range.html), [Configuring the Application Gallery](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-the-application-gallery.html), [Configuring the Help Menu](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-the-help-menu.html)

### Schemas: engine schema APEX_260100, parsing schema e schemas restritos

- O **APEX engine schema** desta versão é `APEX_260100`. Para descobri-lo:
  ```sql
  SELECT DISTINCT table_owner FROM all_synonyms
   WHERE synonym_name = 'WWV_FLOW' AND owner = 'PUBLIC';
  ```
- O **parsing schema** é o schema cujos privilégios o APEX usa ao executar o SQL e PL/SQL da app em runtime. O relatório *Manage Applications > Parsing Schemas* mostra o de cada app; *Application Attributes* lista parsing schema, páginas, idioma, logging, build status, status e alias.
- Schemas padrão da Oracle (ex. `RMAN`) não podem ser atribuídos a workspaces até o DBA rodar `APEX_INSTANCE_ADMIN.UNRESTRICT_SCHEMA(p_schema => 'RMAN')`; `RESTRICT_SCHEMA` volta a restringir (sem afetar workspaces que já usam o schema). Exceções: `CREATE_SCHEMA_EXCEPTION`, `REMOVE_SCHEMA_EXCEPTIONS`, `REMOVE_WORKSPACE_EXCEPTIONS`. `SYS` e `SYSTEM` não podem ser parsing schema desde a 3.1.
- Pegadinha: os nomes passados ao `APEX_INSTANCE_ADMIN` são usados exatamente como digitados; `'system'` minúsculo não é `SYSTEM`.
- Estado das restrições: script `report_instance_configuration.sql` no diretório `utilities`.

Fonte: [Managing Schemas](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/managing-schemas.html), [Viewing the Parsing Schemas Report](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/viewing-parsing-schemas-report.html), [Viewing the Application Attributes Report](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/viewing-the-application-attributes-report.html)

### Workspace to Schema Assignments: associar e remover schemas de um workspace

Cada workspace pode ter vários schemas mapeados; só neles os developers criam objetos e baseiam apps. Em *Manage Workspaces > Manage Workspace to Schema Assignments*: listar, editar, e *Add Schema* (existente ou novo, com tablespace padrão e temporária; deixar *Grant APEX Privileges* ligado). Em runtime:

```sql
ALTER SESSION SET CURRENT_SCHEMA = APEX_260100;
SELECT APEX_INSTANCE_ADMIN.GET_SCHEMAS('MEU_WS') FROM dual;
BEGIN APEX_INSTANCE_ADMIN.ADD_SCHEMA('MEU_WS', 'MEU_SCHEMA', 'Y'); END;  -- 'Y' concede privilégios do APEX
BEGIN APEX_INSTANCE_ADMIN.REMOVE_SCHEMA('MEU_WS', 'MEU_SCHEMA'); END;
```

Ao criar workspace reutilizando schema, o wizard mostra *Suggested Additional Privileges*; conceda-os para evitar erros de privilégio quando o schema for parsing schema.

Fonte: [Managing Workspace to Schema Assignments](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/managing-workspace-to-schema-assignments.html), [Creating Workspaces in Administration Services](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/creating-workspaces.html)

### Criar, bloquear, remover e purgar workspaces (instância)

- **Criar**: *Create Workspace* (nome, ID opcional > 100000, schema novo ou existente, *Space Quota (MB)*, admin) ou *Create Multiple Workspaces*. Em runtime: `APEX_INSTANCE_ADMIN.ADD_WORKSPACE(p_workspace_id, p_workspace, p_primary_schema, p_additional_schemas => 'HR:OE')`. Esses caminhos **não se aplicam a Oracle Cloud**.
- **Bloquear** (*Lock Workspace*): bloqueia todas as contas e deixa todas as apps *Unavailable*; a doc avisa que torna o workspace permanentemente inacessível.
- **Remover**: não apaga schemas nem objetos; o DBA remove depois. Runtime: `APEX_INSTANCE_ADMIN.REMOVE_WORKSPACE(nome, drop_user 'Y'/'N', drop_tablespace 'Y'/'N')` (padrões `N`).
- **Purgar inativos** (*Workspace Purge Settings*, **indisponível em Oracle Cloud**): Enabled, idioma, e-mail remetente, resumo diário, *Days Until Purge*, *Reminder Days in Advance*, *Days Inactive*, *Grace Period*, limites por execução. O admin do workspace recebe e-mail com link para evitar a purga.
- **Component Availability** por workspace: App Builder, SQL Workshop, PL/SQL Editing, Team Development, Data Reporter (e REST, Hosting Extensions na edição do workspace).

Fonte: [Creating Workspaces in Administration Services](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/creating-workspaces.html), [Locking a Workspace](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/locking-a-workspace.html), [Deleting a Workspace](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/deleting-a-workspace.html), [Purging Inactive Workspaces](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/purging-inactive-workspaces.html), [Managing Component Availability for an Instance](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/managing-component-availability-for-an-instance.html)

### Usuários na instância (Manage Developers and Users)

O instance admin cria e edita contas de qualquer workspace em *Manage Workspaces > Manage Developers and Users*, com os mesmos atributos do workspace mais o campo *Workspace* e *Data Reporter Role* (aqui só é possível definir administrador do Data Reporter; outros papéis vêm de *Data Reporter Manage Users*). Developers precisam ter acesso a pelo menos App Builder, SQL Workshop ou Data Reporter.

Fonte: [Managing Users Across an Oracle APEX Instance](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/managing-users-across-an-application-express-instance.html)

### Exportar e importar workspace (o que vai e o que não vai)

O export de workspace gera um `.sql` com definição do workspace, usuários e grupos. **Não inclui** schemas, objetos de banco, aplicações, imagens, CSS e arquivos estáticos, que são exportados à parte. Tipos no Administration Services: **Minimal** (metadados, grupos, usuários) ou **Full** (também SQL Scripts, histórico do SQL Commands, SQL salvos, preferências, histórico de login, logs de e-mail, UI defaults); opção de incluir Team Development e escolher o character set (o mesmo é exigido na importação). A Oracle recomenda criar ambientes novos (teste, produção) **importando** o workspace.

Fonte: [Exporting and Importing a Workspace](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/exporting-and-importing-a-workspace.html)

### SQLcl com APEX: apex list, apex export (-split, -expComponents) e apex log

SQLcl (exige Java 17 ou 21) conecta como o schema do workspace ou como usuário com `DBA` ou `APEX_ADMINISTRATOR_ROLE`. O antigo utilitário `APEXExport` foi **descontinuado**. Comandos:

```sql
SQL> apex list                                   -- apps acessíveis
SQL> apex list -workspaceid 1908816359534887 -changesSince 2022-01-15 -changesBy jane.green
SQL> apex list -applicationid 113 -changesSince 2022-01-22   -- componentes TYPE:ID
SQL> apex export -applicationid 113              -- f113.sql
SQL> apex export -applicationid 113 -split       -- diretório f113/ com install.sql
SQL> apex export -applicationid 113 -split -expComponents "PAGE:3 PAGE:11"  -- install_component.sql
SQL> apex export -workspaceid 1908816359534887   -- todas as apps do workspace
SQL> apex export -expWorkspace -workspaceId 1908816359534887 [-expMinimal]
SQL> apex export -expFiles -workspaceid 1908816359534887     -- static files do workspace
SQL> apex log                                    -- page views e tempos por app
```

Opções úteis de `apex export`: `-expType` (`APPLICATION_SOURCE`, `READABLE_YAML`, `EMBEDDED_CODE`, `CHECKSUM-SH1`, `CHECKSUM-SH256`), `-skipExportDate`, `-expSavedReports`, `-expPubReports`, `-expIRNotif`, `-expTranslations`, `-expOriginalIds`, `-expNoSubscriptions`, `-expComments`, `-expSupportingObjects Y|N|I`, `-dir`, `-nochecksum`, `-debug`. O `-split` é o recomendado para controle de versão, porque o diff mostra páginas e componentes alterados em arquivos separados. `apex log` também mostra as apps internas do Builder (IDs 4000+); dá para aprofundar consultando `APEX_WORKSPACE_LOG_SUMMARY`. A doc 26.1 também cita que o SQLcl sincroniza *skills* para agentes de IA que geram APEXlang (`skills sync`).

Fonte: [Exporting One or More Applications](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/exporting-one-or-more-applications.html), [Listing Applications](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/listing-applications.html), [Listing Components in an Application](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/listing-components-in-an-application.html), [Displaying Application Usage](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/displaying-application-usage.html), [Downloading and Installing SQLcl](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/downloading-and-installing-sqlcl.html), [Exporting and Importing from a Command Line](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/exporting-and-importing-from-a-command-line.html)

### Instalar aplicação por SQLcl: apex import (APEXlang) e APEX_APPLICATION_INSTALL

- **Export APEXlang**: `apex import -input myapp.zip` ou `apex import -input caminho/myapp` (precisa de SQLcl com suporte a `apex import`; `help apex import` lista opções).
- **Alvo igual à origem** (mesmo workspace, ID, schema e alias): rodar `f1234.sql`, `f1234/install.sql` ou `f1234/install_component.sql`; a app com o mesmo ID é sobrescrita (num export parcial, só os componentes incluídos).
- **Alvo diferente**: preparar o contexto antes do script:

```sql
begin
  apex_application_install.set_workspace('TARGET_WORKSPACE');
  apex_application_install.set_application_id(5678);
  apex_application_install.generate_offset();
  -- ou: apex_application_install.generate_application_id; generate_offset;
  apex_application_install.set_schema('HRAPP_PROD');
  apex_application_install.set_application_alias('hrapp');
end;
/
@f1234.sql
```

Para importar workspace ou static files: conectar com `APEX_ADMINISTRATOR_ROLE` ou DBA e rodar o script gerado. Em **ambiente runtime** (sem Builder, recomendado para produção sensível) importa-se primeiro o workspace e depois a app, conectado como `APEX_260100`, `SYS`, `SYSTEM` ou usuário com `APEX_ADMINISTRATOR_ROLE` (este caminho de runtime é indisponível em Oracle Cloud).

Fonte: [Installing an Application](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/installing-an-application.html), [Installing Exported Applications in a Runtime Environment](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/installing-exported-applications-in-a-runtime-environment.html), [Importing a Workspace](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/importing-a-workspace.html)

### Sincronizar feedback entre DEV, TEST e PROD (apex export -expFeedback)

Ambientes com o mesmo nome e ID de workspace são diferenciados por *Feedback Synchronization Source Identifier* (ex. `DEV`, `TEST`, `PROD`, em Edit Workspace Information) e por environment banner. Fluxo: em PROD, `apex export -expFeedback -workspaceid <id>` gera `fb<id>.sql` (contém `wwv_flow_api.set_feedback_origin('PROD', ...)`), que é rodado em DEV no schema do workspace; depois, em DEV, `-deploymentSystem PROD` exporta só o feedback originado em PROD para devolver. `-expFeedbackSince YYYYMMDD` faz export incremental.

Fonte: [Synchronizing Feedback Among Environments](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/synchronizing-feedback-among-environments.html)

### Mensagens da instância: login message, system message e site-specific resources

*Manage Instance > Messages*: **Login Message** (abaixo da tela de login do APEX, aceita HTML), **System Message** (na home do workspace, Workspace Administration e home do Administration Services), **Workspace Message** por workspace (via Component Availability), **Environment Banner** da instância e **Site-Specific Resources** (links na home e no login do workspace; indisponível em Oracle Cloud).

Fonte: [Communicating Using Messages, Banners, and Resources List](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/communicating-using-messages-banners-task-lists.html), [Defining a Login Message](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/defining-login-message.html), [Defining a System Message](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/defining-system-message.html)

## 4. Logs, monitoramento de atividade e purge

Esta seção junta tudo que serve para diagnosticar: relatórios de Monitor Activity (workspace e instância), os logs mantidos pelo APEX, retenção e purga, e os jobs `DBMS_SCHEDULER` que fazem a manutenção. Para debug de página (níveis, `APEX_DEBUG`, Advisor) veja a seção de Debugging deste documento.

### Monitor Activity do workspace: page views, developer activity, sessões, logins e Application Errors

*Administration > Monitor Activity* (developers e admins do workspace) tem:

| Seção | Relatórios |
|---|---|
| Page Views | By View, By User, By User and Hour, By Application, By Application and Page, By Day, By Hour |
| Developer Activity | By Developer (+ gráfico), By Developer by Hour, By Day, By Application, Application Changes (detailed), By Day (Monthly View), Component Utilization Chart |
| Sessions | Active Sessions, Bar Chart of Active Session by Hour |
| Page View Analysis | Most Viewed Pages, calendário mensal, linha de uso por dia, **By Weighted Page Performance** |
| Environment | By User Agent, By Browser, By External Click, By Operating System |
| Login Attempts | Login Attempts, by Authentication Result, Developer Login Summary |
| Application Errors | relatório de erros das apps |
| Workspace Schema & Other Reports | Schema Tablespace Utilization, Database Privileges by Schema, Workspace Schemas, Report Tablespace Utilization, **Web Service Activity Log**, Archive of Purged Task Files |
| Archived Activity | By Application by Month/Day, Application Hash by Day, Chart of Workspace Activity by Day |

Os relatórios de page view dependem do activity logging da app estar ligado. Para relatórios próprios, a doc remete ao uso de `APEX_ACTIVITY_LOG` (App Builder User's Guide).

Fonte: [Monitoring Activity Within a Workspace](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/monitoring-activity-within-a-workspace.html)

### Active Sessions e Session Details: ligar Debug Level e SQL Trace numa sessão de usuário

Em *Monitor Activity > Sessions > Active Sessions*, clicar no ID abre *Session Details*, que mostra page views, background processing, valores de itens em session state e dados do navegador, e permite configurar a sessão de outro usuário:

**Enable Debug**:
| Valor | Conteúdo |
|---|---|
| Disabled | sem debug |
| Error (LEVEL1) | erros |
| Warn (LEVEL2) | avisos |
| Info (LEVEL4) | informativo (padrão quando o debug é ligado sem nível) |
| Application Enter (LEVEL5) | entrada/saída de métodos da aplicação |
| Application Trace (LEVEL6) | detalhe da aplicação |
| APEX Enter (LEVEL8) | entrada/saída de métodos do engine |
| APEX Trace (LEVEL9) | detalhe do engine |

A Oracle recomenda não passar de **LEVEL6** salvo pedido do Suporte: níveis altos geram muitas mensagens e pesam no desempenho.

**Trace Mode**: Disabled ou SQL Trace (gera arquivo temporário para análise com TKPROF; depende de *Enable Application Tracing*, indisponível em Oracle Cloud).

É a forma de depurar o problema de um usuário específico sem pedir que ele altere a URL.

Fonte: [Monitoring Activity Within a Workspace](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/monitoring-activity-within-a-workspace.html)

### O que é sessão ativa e quando ela é purgada (ORACLE_APEX_PURGE_SESSIONS)

Toda execução de app mantém um registro de sessão no schema do APEX (ID, usuário autenticado ou público, data de criação etc.). **Sessão ativa** é qualquer sessão ainda não purgada da tabela; **sessão expirada** é a que passou do tempo máximo de vida ou ficou ociosa além do idle time. Um job remove as expiradas periodicamente.

Divergência na própria doc 26.1 sobre a periodicidade:
- *Monitoring Activity Within a Workspace*: um job roda **a cada hora** e purga sessões expiradas.
- *List of DBMS_SCHEDULER Jobs*: `ORACLE_APEX_PURGE_SESSIONS` roda **a cada hora** e purga sessões **com mais de 12 horas** (padrão).
- *Managing Session State for an Instance*: um processo automático remove sessões com **mais de 24 horas a cada 8 horas**.

Na prática: a frequência é horária segundo a tabela de jobs; não presuma tempo de vida exato e use os relatórios de sessão para confirmar. O instance admin também purga manualmente (*Manage Instance > Session State > Purge Sessions*, com limite de quantidade e idade, e *Session State Statistics*).

Fonte: [Monitoring Activity Within a Workspace](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/monitoring-activity-within-a-workspace.html), [DBMS_SCHEDULER Jobs](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/dbms_scheduler-jobs.html), [Managing Meta Data](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/managing-meta-data.html)

### Monitor Activity da instância e Administrator Digest

No Administration Services, *Monitor Activity* cobre todos os workspaces (algumas partes indisponíveis em Oracle Cloud):
- **Activity Summary**: Administrator Digest, Top Applications, Top Workspaces, Activity Summary.
- **Page Views**: Dashboard, By View, By Application and User, By User, by Day, By Application, By Workspace, faceted search.
- **Workspace Purge**: Dashboard, Inactive Workspaces, Workspaces Purged, que ficaram ativos, Purge Log.
- **Logs**: **Mail Log**, **Web Service Activity Log**, **Automation Log**, **REST Synchronization Log**, **Jobs**, **Automatic File Delete Log**, **Backup Log**.
- **Environment**, **Login Attempts** (Login Attempts, Developer Last Login), **Calendar Reports**, **Developer Activity** (inclui **Data Loading Jobs** em execução, jobs `ORACLE_APEX_DTLD${job-id}`), **Archived Activity**.

O **Administrator Digest** reúne métricas diárias de instância (workspaces e DB links criados/removidos), workspace (contas, usuários distintos, page events, logins, apps, requests de web service) e schema (DB links, jobs de usuário, espaço usado × livre), com regiões para Workspaces, Applications, Users, User/System Scheduler Jobs, Database Links e "Workspaces with 10% Free Space Remaining" (limite ajustável pelo parâmetro de instância `WORKSPACE_FREE_SPACE_LIMIT`). Os eventos operacionais dos instance admins também podem ser consultados em `APEX_EVENTS_LOG`.

Fonte: [Monitoring Activity Across an Instance](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/monitoring-activity-across-an-instance.html), [Configuring and Deleting Logs and Log Entries](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-and-deleting-logs-and-log-entries.html)

### Localizar app, página e sessão a partir do log do servidor web (p_context)

Em GET de página, aplicação, página e sessão estão na própria URL. Em **POST** (submit) e **AJAX**, essas informações vêm no parâmetro de query `p_context`:
- com Friendly URLs: `app-alias/page-alias/session-id`;
- com sintaxe legada `f?p`: `app_id:page_number:session_id`.

Com isso dá para cruzar um erro 4xx/5xx dos access/error logs do servidor web (Apache, Tomcat, Jetty… cada um tem seu local) com a sessão no APEX e então abrir *Session Details* ou o debug daquela sessão.

Fonte: [Monitoring Activity Across an Instance](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/monitoring-activity-across-an-instance.html)

### Catálogo de logs do APEX e retenção (Manage Log Interval)

*Manage Instance > Manage Logs and Files > Manage Log Interval* define a retenção mínima em dias, **padrão 14, máximo 180**; reter mais degrada o runtime. Logs cobertos:

| Log | O que registra |
|---|---|
| Access Log (Login Access) | Autenticações de developers/admins e de end users que usam as APIs de login embutidas |
| Activity Log (Page View) | Page views, submits e partial page refreshes; exige logging habilitado na app |
| Automation | Execuções de automations |
| Debug Messages | Mensagens de debug emitidas enquanto o debug está ligado |
| Events | Operações de instance admins (Administrator Digest ou `APEX_EVENTS_LOG`) |
| External Click Count | Cliques para sites externos via `APEX_UTIL.COUNT_CLICK` |
| REST Synchronization | Execuções de REST Source Synchronization |
| Web Service | Todas as requisições de web service iniciadas pela instância, se o logging de web service estiver ligado |

Também há o API `SET_LOG_SWITCH_INTERVAL` (API Reference). Outros logs com tela própria: SQL Workshop Log, Developer Activity Log (com *Developer Log Retention Days*, apagado na manutenção diária), Mail Log (fila e `APEX_MAIL_LOG`), Backup Log, Automatic File Delete Log, Install/Upgrade Logs. Configurar retenção e apagar logs são funções de instance admin; parte delas é indisponível em Oracle Cloud.

Fonte: [Configuring and Deleting Logs and Log Entries](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-and-deleting-logs-and-log-entries.html)

### Page View Activity Log: duas tabelas alternadas (log switch)

O engine usa **dois logs** de atividade. Um é o corrente e recebe uma linha por page view renderizado. No *log switch* (intervalo definido em Manage Log Interval) o engine **esvazia o log não corrente** e o torna corrente. Por isso o histórico disponível fica entre um e dois intervalos e "some" em bloco. O admin pode truncar manualmente *Log 1* ou *Log 2* em *Page View Activity Log > Truncate Logs*. A coleta depende do atributo *Logging* da aplicação (Edit Application Definition) ou do *Application Activity Logging = Always* na instância. *Archive Activity Log* resume o activity log em um log arquivado (o job `ORACLE_APEX_DAILY_METRICS` também arquiva o resumo diariamente).

Fonte: [Configuring and Deleting Logs and Log Entries](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-and-deleting-logs-and-log-entries.html)

### Purga manual de logs: SQL Workshop, Developer Activity, Click Count, Login Access, Web Service, REST Sync, Automation

- **SQL Workshop Log** (instância): dois tipos — execuções de Script File e histórico do SQL Command Processor (aba *History* do SQL Commands). *Truncate Log* apaga tudo; *Delete Entries* apaga por idade.
- **Developer Activity Log**: alterações em apps. No workspace, *Manage Meta Data > Developer Activity and Click Count Logs > Purge Developer Log*; na instância, apagar por idade e definir *Developer Log Retention Days*. A doc do workspace informa que entradas com mais de **um mês** são apagadas automaticamente.
- **External Click Count Log**: no workspace (*Purge Click Log*) ou na instância por idade.
- **Login Access Log**, **Web Service Activity Log**, **REST Synchronization Log** (status, linhas processadas, número de requests HTTP, com drill-down para o Web Service log) e **Automation Log**: na instância, apagar entradas com N dias ou mais.
- **Install / Upgrade Logs**: só leitura, com detalhes e erros de cada fase de instalação/upgrade.

Fonte: [Configuring and Deleting Logs and Log Entries](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-and-deleting-logs-and-log-entries.html), [Purging the Developer Activity and Click Count Log Files](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/purging-the-developer-activity-and-click-count-log-files.html)

### Mail Queue e Mail Log: reenvio automático e onde ver o erro (APEX_MAIL_LOG)

E-mails de `APEX_MAIL` vão para uma fila processada pelo job `ORACLE_APEX_MAIL_QUEUE` a cada 5 minutos. Se o envio falha (endereço inválido, servidor indisponível), a mensagem fica na fila com o último erro e é reenviada **até 14 vezes** com intervalo crescendo exponencialmente (2, 4, 8, 16 min…). Esgotadas as tentativas, sai da fila e o erro fica em **`APEX_MAIL_LOG`**. Na *Mail Queue* (instance admin): *Delete*, *Send All Mail* (respeita o atraso calculado) e *Force Send All Mail* (ignora o atraso). O *Mail Log* também está em Monitor Activity > Logs. Limites diários: *Maximum Emails per Workspace* (instância) e *Maximum Email Messages* (workspace).

A *Push Notifications Queue* (PWA) funciona de modo parecido: *Push Queue* e *Force Push Queue*; job `ORACLE_APEX_PWA_PUSH_QUEUE` a cada 2 minutos.

Fonte: [Managing Meta Data](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/managing-meta-data.html), [Configuring Email](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-email.html)

### E-mail enviado pelo APEX_MAIL não chega e some da fila

**Sintoma:** a app chama `APEX_MAIL.SEND`, nada chega ao destinatário e, depois de um tempo, a mensagem não está mais na Mail Queue.
**Causa:** falha repetida de entrega (endereço inválido, SMTP indisponível, credencial errada, falta de ACL/wallet); após 14 tentativas com backoff exponencial a mensagem é descartada.
**Correção:** consultar `APEX_MAIL_LOG` (ou Monitor Activity > Logs > Mail Log) para ver o último erro; corrigir SMTP, credencial do workspace, ACL ou wallet; reenviar. Enquanto ainda estiver na fila, *Force Send All Mail* tenta de imediato.
**Prevenção:** testar credenciais com *Test SMTP Credential*; lembrar que o envio é assíncrono (job a cada 5 min) e que há limite diário por workspace.

Fonte: [Managing Meta Data](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/managing-meta-data.html)

### Jobs DBMS_SCHEDULER criados pelo APEX (manutenção, fila, automations, background)

| Job | Função | Frequência |
|---|---|---|
| `ORACLE_APEX_AUTOMATIONS` | Executa automations vencidas | 2 min |
| `ORACLE_APEX_BACKUP` | Backup de apps alteradas e purga conforme *Number of backups per application* (desligado com 0) | diário 02:00 |
| `ORACLE_APEX_BG_PROCESSES` | Dispara processos de página em background | 2 min (dura ~1 min 57 s) |
| `ORACLE_APEX_DICTIONARY_CACHE` | Estatísticas e cache do dicionário para wizards | diário 01:00 |
| `ORACLE_APEX_DAILY_METRICS` | Descrito como manutenção noturna: arquiva o resumo de atividade e roda a purga de workspaces | diário 01:00 |
| `ORACLE_APEX_DAILY_MAINTENANCE` | Descrito como inserção das métricas diárias de instância, workspace e schema | diário 02:00 |
| `ORACLE_APEX_DTLD${job-id}` | Cargas de dados do SQL Workshop; purgados ao terminar; visíveis em Monitor Activity > Developer Activity > Data Loading Jobs | sob demanda |
| `ORACLE_APEX_ISSUE_EMAILS` | Notificações do Team Development | 1 h |
| `ORACLE_APEX_MAIL_QUEUE` | Envia a fila de e-mail | 5 min |
| `ORACLE_APEX_PURGE_SESSIONS` | Purga sessões com mais de 12 h (padrão) | 1 h |
| `ORACLE_APEX_PWA_PUSH_QUEUE` | Push notifications | 2 min |
| `ORACLE_APEX_REST_SOURCE_SYNC` | REST Source Synchronizations vencidas | 10 min |
| `ORACLE_APEX_TASKS_EXPIRE` | Expira/renova human tasks vencidas e executa ações Before Expire/Expire | 1 h |
| `ORACLE_APEX_TASKS_PURGE` | Purga tasks concluídas fora da retenção e as com erro/expiradas/canceladas; guarda detalhes em JSON | diário 02:00 |
| `ORACLE_APEX_WFS_PURGE` | Purga workflows concluídos fora da retenção e terminados | diário 03:00 |
| `ORACLE_APEX_WF_TIMEOUT` | Timeout de atividades de workflow vencidas | 5 min |
| `ORACLE_APEX_WS_NOTIFICATIONS` | Envia assinaturas de Interactive Report | 30 min |

Observação: as descrições de `ORACLE_APEX_DAILY_METRICS` e `ORACLE_APEX_DAILY_MAINTENANCE` parecem trocadas entre si na tabela oficial (o nome "metrics" está com a manutenção e vice-versa); registre-as como estão e confirme pelo comportamento. Consequência prática: automations, REST sync, background processes, e-mail e IR subscriptions são **assíncronos** e dependem do scheduler; se `JOB_QUEUE_PROCESSES` estiver em zero ou os jobs desabilitados, nada disso roda (o valor aparece em *Help > About*). O *Minimum Execution Cadence* e a *Background Job Class* da instância afetam esses jobs.

Fonte: [DBMS_SCHEDULER Jobs](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/dbms_scheduler-jobs.html), [Configuring Background Jobs](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-background-jobs.html), [Viewing the About Oracle APEX Page](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/viewing-the-about-oracle-apex-page.html)

### Automation, REST Sync ou envio de e-mail não executam no horário

**Sintoma:** uma automation agendada, uma REST Source Synchronization, a fila de e-mail ou processos de página em background ficam parados ou atrasados.
**Causa:** essas tarefas dependem dos jobs `ORACLE_APEX_AUTOMATIONS` (2 min), `ORACLE_APEX_REST_SOURCE_SYNC` (10 min), `ORACLE_APEX_MAIL_QUEUE` (5 min) e `ORACLE_APEX_BG_PROCESSES` (2 min). Jobs desabilitados, `JOB_QUEUE_PROCESSES` sem capacidade, *Minimum Execution Cadence* maior que o esperado ou o limite *Maximum Background Page Process Jobs* do workspace atingido atrasam a execução.
**Correção:** conferir `JOB_QUEUE_PROCESSES` em *Help > About*; ver Monitor Activity > Logs (Automation Log, REST Synchronization Log, Jobs); no nível de instância, revisar *Background Jobs* e o limite de background jobs do workspace.
**Prevenção:** não tratar esses recursos como síncronos; registrar e monitorar resultados nos respectivos logs.

Fonte: [DBMS_SCHEDULER Jobs](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/dbms_scheduler-jobs.html), [Isolating a Workspace to Prevent Browser Attacks](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/isolating-workspace-to-prevent-browser-attacks.html), [Configuring Background Jobs](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-background-jobs.html)

### Wizard de criação de página não mostra tabela ou coluna nova

**Sintoma:** *Create Page* / *Create Application* não lista uma tabela ou coluna criada há pouco, ou sugere facetas erradas.
**Causa:** os wizards usam o Data Dictionary Cache, atualizado pelo job noturno `ORACLE_APEX_DICTIONARY_CACHE` (01:00).
**Correção:** *Administration > Manage Service > Data Dictionary Cache* > *Gather Statistics and Refresh Cache* (ou *Refresh Cache Only*), no workspace ou na tabela.

Fonte: [Accessing the Data Dictionary Cache Report from Workspace Administration](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/accessing-data-dictionary-cache-from-workspace-administration.html)

### Limite de concorrência atingido: APEX mostra erro em vez de processar a página

**Sintoma:** sob carga, usuários recebem mensagem de erro do APEX em vez da página, ou sessões de banco são mortas.
**Causa:** *Maximum Concurrent Workspace Requests* ou *Maximum Concurrent Session Requests* atingidos (instância ou workspace); com *Concurrent Session Requests Kill Timeout*, o APEX executa `alter system kill session` na sessão mais antiga daquela sessão APEX. A contagem usa `GV$SESSION.CLIENT_INFO` e `CLIENT_IDENTIFIER`; código que sobrescreve esses campos quebra o rastreamento.
**Correção:** revisar os limites em Workspace Isolation; remover chamadas a `DBMS_APPLICATION_INFO.SET_CLIENT_INFO` / `DBMS_SESSION.SET_IDENTIFIER` do código da app.

Fonte: [Isolating All Workspaces in an Instance](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/isolating-workspaces-in-an-instance.html)

### Arquivos de export/import somem do workspace

**Sintoma:** um export de aplicação, página, tema ou um arquivo de carga de dados enviado antes não está mais no Export Repository.
**Causa:** *Delete Uploaded Files After (days)* da instância apaga automaticamente esses arquivos em todos os workspaces.
**Correção:** baixar exports logo após gerá-los e versioná-los fora do APEX; o instance admin consulta o *Automatic File Delete Log*.

Fonte: [Configuring Storage](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-storage.html)
## 5. Instalação, ORDS, multitenant e upgrade da instância (Installation Guide)

> **Escopo, leia primeiro.** O *Oracle APEX Installation Guide* trata de bancos **self-managed** (on-premises, laptop, data center) e de bancos *co-managed* na nuvem (Database Cloud Service, Exadata Cloud Service). Em bancos **totalmente gerenciados**, como o **Autonomous AI Database** e o **APEX Service**, o APEX já vem instalado e configurado, e a própria doc diz que os passos de instalação podem ser pulados. No Corlix Hub (APEX 26.1.5 hospedado no Autonomous) quase tudo desta seção **não é executável pelo time**: serve para entender a arquitetura, ler mensagens de erro e saber o que a Oracle faz por baixo. Cada subseção marca **[on-prem]** quando só vale para instalação própria, e **[Autonomous]** quando a doc afirma algo específico do Autonomous.

### Arquitetura do APEX: navegador, ORDS e banco (About APEX Architecture)

- O APEX gera as páginas dinamicamente a partir de **metadados guardados no próprio banco**. A arquitetura tem três peças: navegador, **Oracle REST Data Services (ORDS)** como servidor web e o banco Oracle com o APEX instalado.
- O ORDS (antigo *Oracle Application Express Listener*) é uma aplicação J2EE que traduz requisições HTTP em chamadas a procedures do motor APEX, via conexão SQL*Net. Roda em modo *standalone* (suportado) ou dentro de Oracle WebLogic Server ou Apache Tomcat. WebLogic tem custo de licença.
- A vantagem dessa separação é isolar a camada intermediária da camada de banco. Para o usuário basta um navegador e a URL: não há cliente a instalar.
- **Consequência prática para um agente:** toda lógica que você escreve (PL/SQL de processos, validações, SQL de regiões) roda **no banco**, dentro do schema de parsing do workspace. O ORDS só repassa a requisição.

Fonte: [About APEX Architecture](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/about-apex-architecture.html)

### Contas de banco criadas pelo APEX (APEX_260100, FLOWS_FILES, APEX_PUBLIC_USER, APEX_PUBLIC_ROUTER)

| Conta | Papel | Observação |
|---|---|---|
| `APEX_260100` | Dono do schema da plataforma e dos metadados do APEX 26.1 | *Schema-only*, sempre bloqueada |
| `FLOWS_FILES` | Dono dos arquivos enviados ao APEX que não ficam nos schemas dos workspaces | *Schema-only*, sempre bloqueada |
| `APEX_PUBLIC_USER` | Conta com privilégio mínimo usada na configuração com ORDS | |
| `APEX_PUBLIC_ROUTER` | Conta com privilégio mínimo usada por um módulo REST do ORDS para resolver *friendly URLs* | Pode esgotar sessões em sistemas muito ativos (ver caso em §6) |
| `APEX_REST_PUBLIC_USER` | Usada ao invocar definições de RESTful Services guardadas no APEX | Só se RESTful Web services foram configurados |
| `APEX_LISTENER` | Usada para consultar definições de RESTful Services guardadas no APEX | Idem |

- Num upgrade, todas podem já existir, **exceto** `APEX_260100` (cada release maior cria um schema novo, por exemplo `APEX_240200` para 24.2).
- Dica para agentes: o nome do schema da plataforma aparece em mensagens de erro e em `ALL_SYNONYMS`; no código use `APEX_APPLICATION.g_flow_schema_owner` em vez de fixar `APEX_260100`, como a própria doc faz no exemplo de ACL.

Fonte: [About APEX Database Accounts](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/about-apex-database-accounts.html)

### APEX na Oracle Cloud e no Autonomous Database (About Accessing APEX in Oracle Cloud)

- Na Oracle Cloud o APEX vem **instalado, habilitado e pronto** no *Oracle APEX AI Application Generator Service* (APEX Service) e no *APEX AI Application Generator* sobre **Autonomous AI Transaction Processing** ou **Autonomous AI Lakehouse**.
- No Exadata Cloud Service e no Database Cloud Service o APEX está disponível, mas é preciso instalá-lo e habilitá-lo seguindo o processo self-managed (ou ferramentas como Terraform).
- O que a doc afirma explicitamente sobre bancos totalmente gerenciados (Autonomous / APEX Service):
  - APEX pré-instalado e pré-configurado; os passos de download e instalação podem ser pulados.
  - **Patch set bundles aplicados automaticamente pela Oracle.**
  - Todos os idiomas de tradução já vêm instalados; não é preciso rodar `load_<lang>.sql`.
  - `apxchpwd.sql` **não é suportado** (não há conta de instância `ADMIN` gerenciada pelo cliente desse jeito).
  - **Ambiente runtime-only não está disponível** no Autonomous; para endurecer instâncias de teste/produção use o parâmetro de instância `RESTRICT_DEV_HEADER`, que desabilita o acesso ao App Builder e ao Administration Services.
  - A conversão de ambiente completo para runtime (`apxdevrm.sql`) não está disponível em instâncias APEX na Oracle Cloud.
  - **Network services/ACL não se aplicam**: o APEX no Autonomous fala com endpoints externos na internet sem configuração adicional.
  - Para controlar quando o upgrade acontece, a doc aponta para o tópico *Control Oracle APEX Upgrades* do guia *Using Oracle Autonomous Database Serverless* (fora desta base).

Fonte: [About Accessing APEX in Oracle Cloud](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/accessing-apex-in-oracle-cloud.html), [Downloading and Installing Oracle APEX](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/downloading-installing-apex.html), [About the APEX Runtime Environment](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/about-apex-runtime-environment.html), [Enabling Network Services in Oracle Database](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/enabling-network-services.html), [Understanding the Installation Process](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/understanding-installation-process.html)

### Requisitos de instalação do APEX 26.1: banco, navegador, ORDS, disco, XML DB [on-prem]

**Banco de dados**
- Oracle Database **19c com Release Update 19.18 (jan/2023) ou superior**; no **Oracle AI Database 26ai**, no mínimo a versão **23.26.0 (out/2025)**.
- Roda em todas as edições (EE, SE2, 26ai Free), em instância única e em Oracle RAC.
- Memória: **SGA ≥ 1200 MB** e **PGA ≥ 300 MB**. Confira com `SHOW PARAMETER SGA_TARGET` / `SHOW PARAMETER PGA_AGGREGATE_TARGET`. Se `SGA_TARGET` for `0`, o banco usa *automatic memory management* e o ajuste é via `MEMORY_TARGET`. Com spfile:
  ```sql
  ALTER SYSTEM SET SGA_TARGET='1200M' SCOPE=spfile;
  ALTER SYSTEM SET PGA_AGGREGATE_TARGET='300M' SCOPE=spfile;
  -- depois SHUTDOWN / STARTUP e confira de novo
  ```
- `WORKAREA_SIZE_POLICY` precisa ser `AUTO` na sessão da instalação/upgrade (`ALTER SESSION SET WORKAREA_SIZE_POLICY = AUTO;`). Em CDB, precisa ser no sistema todo: `ALTER SYSTEM SET WORKAREA_SIZE_POLICY=AUTO SCOPE=BOTH;` (pode voltar a `MANUAL` depois).
- Com **Database Vault** habilitado há passos extras (inclusive para provisionamento de workspace e SQL Workshop), descritos no guia do Database Vault.

**Navegador:** com JavaScript habilitado; suporta a versão atual e a anterior de Chrome, Firefox, Safari e Edge.

**Servidor web:** **ORDS 26.1.1 ou superior**. A partir do 26.1 a Oracle recomenda, em instalações novas, **instalar o ORDS antes do APEX**. Os REST Services baseados em APEX foram descontinuados no 22.1; o ORDS 21.4.2+ traz scripts de migração para ORDS-based Services.

**Disco**
| Item | Espaço |
|---|---|
| Arquivos do APEX (só inglês, `apex_26.1_en.zip`) | 670 MB |
| Arquivos do APEX (completo, `apex_26.1.zip`) | 1.178 MB |
| Tablespace do APEX | 260 MB |
| Tablespace `SYSTEM` | 128 MB |
| Cada idioma extra no tablespace do APEX | 60 MB |

**Oracle XML DB:** obrigatório para ambiente de desenvolvimento completo; o instalador verifica e aborta se faltar. O XML DB cria o usuário `ANONYMOUS`, que **não pode ser removido** ou o provisionamento de workspaces deixa de funcionar.

> **Divergência interna da doc:** a página de requisitos exige ORDS 26.1.1+, mas a página "Viewing the Oracle REST Data Services Release Number" ainda diz "ORDS 23.3 or later". Considere 26.1.1 como o requisito vigente do 26.1.

Fonte: [Oracle APEX Installation Requirements](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/apex-installation-requirements.html), [Upgrading from a Previous APEX Release](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/upgrading-from-previous-apex-release.html)

### Ambiente de desenvolvimento completo × runtime-only (About the APEX Runtime Environment)

- A Oracle recomenda ambientes separados para desenvolvimento, teste/QA e produção. Para teste e produção pode-se instalar **só o runtime**: menor footprint e menos privilégios, e ninguém altera a app em produção por acidente.
- O runtime executa apps mas **não tem interface web de administração**; administra-se com a API `APEX_INSTANCE_ADMIN` via SQL Developer ou SQLcl.
- Conversões [on-prem], conectado como `SYS AS SYSDBA` no diretório `apex`:
  - runtime → completo: `@apxdvins.sql` e depois `apxchpwd.sql` para a conta de administrador da instância;
  - completo → runtime: `@apxdevrm.sql` (indisponível na Oracle Cloud).
- **[Autonomous]** runtime-only não existe; use `RESTRICT_DEV_HEADER` para bloquear App Builder e Administration Services.

Fonte: [About the APEX Runtime Environment](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/about-apex-runtime-environment.html), [Converting Between Runtime and Full Development Environments](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/converting-between-runtime-and-full-development-environments.html)

### Processo de instalação: planejamento, patch sets, scripts e papéis de usuário (Understanding the Installation Process)

- **O mesmo procedimento serve para instalação nova e upgrade.** Passos: (1) decidir entre ambiente completo ou runtime; (2) verificar requisitos; (3) instalar/atualizar o ORDS; (4) instalar/atualizar o APEX a partir do ZIP.
- O script de instalação acha o schema APEX mais recente e **copia metadados da instância, workspaces e apps** para o schema novo; o schema antigo fica intacto. Boa prática: tablespaces novos para cada release.
- **Patch sets** trazem só correções e não exigem recertificação. **[Autonomous]** A Oracle aplica os bundles automaticamente; nos demais ambientes eles vêm do My Oracle Support. Histórico de patches:
  ```sql
  select patch_number, patch_version, installed_on
    from APEX_PATCHES
   order by installed_on;
  ```
- **Quatro papéis**: *Instance administrators* (superusuários; usam o Administration Services; provisionamento, configurações e segurança), *Workspace administrators* (preferências do workspace, contas, monitoramento, logs), *Developers* (criam e editam apps) e *End users* (só executam apps).
- **Provisioning Method** (definido em Instance Settings): `Manual` (o admin de instância cria o workspace), `Request` (o usuário pede, o admin aprova e um e-mail de verificação cria o workspace) e `Automatic` (como Request, mas aprovado sem revisão). O link "Request a Workspace" só aparece na tela de login com Request ou Automatic e e-mail configurado.
- Pela tela de login também dá para **Reset Password** (informando e-mail e workspace) e **Find My Workspace** (recebe por e-mail a lista de workspaces associados ao endereço).

Fonte: [Understanding the Installation Process](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/understanding-installation-process.html), [APEX Installation Overview](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/apex-installation-overview.html)

### Pré-instalação: backup, parar acessos e verificar sessões [on-prem]

1. Confira e atenda os requisitos.
2. Se o APEX está em uso e você vai fazer upgrade, **desligue** as instâncias do banco (normal ou immediate; em RAC, todas as instâncias de cada nó). Alternativa, recomendada só em produção de alta disponibilidade sem janela: impedir o acesso ao APEX desligando o servidor de aplicação onde o ORDS roda e conferir em `V$SESSION` que não há sessões longas que atrapalhem.
3. Faça backup do banco (por exemplo com RMAN).
4. Suba a instância do banco de destino.

Fonte: [Performing Pre-installation Tasks for APEX](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/performing-pre-installation-tasks-for-apex.html)

### Instalar e configurar o ORDS para o APEX: PL/SQL Gateway, imagens, CDN, static files, segurança [on-prem]

**Download e instalação**
- O ORDS dispensa Oracle home (usa um driver JDBC embutido). Descompacte `ords.<versão>.zip`, copie `apex/images` para onde o ORDS vai servir os arquivos (opcional se usar a CDN) e siga o guia de instalação do ORDS.
- O context root padrão é `/ords`. Para usar `/apex`, renomeie `ords.war` para `apex.war` **antes** de instalar.
- Em multitenant, configure a conexão com o *service name* do **PDB**, não do `CDB$ROOT` (a menos que o ORDS deva endereçar PDBs pela URL).
- Atrás de *reverse proxy* ou *load balancer*, o hostname e o protocolo originais (os que o navegador vê) precisam chegar ao motor do APEX; sem isso as URLs geradas e os redirects quebram. A configuração depende do servidor (no WebLogic, via Proxy Plug-Ins).

**PL/SQL Gateway em modo proxied** (obrigatório para o APEX):
```sh
ords config get plsql.gateway.enabled      # deve retornar: proxied
ords config set plsql.gateway.mode proxied
# pool não padrão:
ords --config <config path> config --db-pool <pool name> set plsql.gateway.mode proxied
```

**Imagens e recursos estáticos**
- Opção 1: copiar o diretório de imagens para o sistema de arquivos do ORDS. Num upgrade ele é sobrescrito; **antes**, faça cópia identificada pela release (por exemplo `images_24_2`) para poder reverter.
- Opção 2: **CDN de recursos estáticos da Oracle**, configurada uma vez e atualizada automaticamente em patches e upgrades. Rode como usuário com `APEX_ADMINISTRATOR_ROLE`:
  ```sql
  begin
      for c1 in (select version_no from APEX_RELEASE)
      loop
          APEX_INSTANCE_ADMIN.set_parameter(
              p_parameter => 'IMAGE_PREFIX',
              p_value     => 'https://static.oracle.com/cdn/apex/' || c1.version_no || '/');
      end loop;
      commit;
  end;
  ```
- Com ORDS 21.2.1 ou anterior, valide a instalação do ORDS após instalar/atualizar o APEX: `ords validate [--database <dbname>]`.
- **Static files** (de workspace, app, plug-in e tema) são servidos por um módulo RESTful embutido no APEX; por isso rode **`apex_rest_config.sql`** após uma instalação nova.
- **Segurança:** configure `security.requestValidationFunction` = `ords_util.authorize_plsql_gateway`, que ativa a *allow list* de procedures do APEX e bloqueia chamadas a qualquer outra.
- **SSL:** a Oracle recomenda HTTPS para que senhas e dados sensíveis não trafeguem em claro (ver *Configuring HTTP Protocol Attributes* no guia de administração).
- **Performance:** habilite compressão gzip para o diretório virtual de imagens (`/i/`) e para as respostas do *database access descriptor*, e cache no navegador dos arquivos de `/i/` por **no mínimo 12 horas** (`Cache-Control`).

**Limite de POST (não upload)**
- ORDS standalone 19.4.6 ou anterior: 200 KB por padrão; aumente com `java -Dorg.eclipse.jetty.server.Request.maxFormContentSize=3000000 -jar ords.war`.
- Tomcat: 2 MB por padrão; ajuste `maxPostSize`.
- O limite aparece ao colar dados no SQL Workshop ou ao criar app a partir de planilha por copiar e colar.

Fonte: [Downloading and Installing Oracle REST Data Services (ORDS)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/downloading-installing-ords.html), [Configuring Oracle REST Data Services](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/configuring-ords.html), [Performing Security Tasks](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/performing-security-tasks.html), [About Performance Optimization Tasks](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/performance-optimization-tasks.html)

### Instalar o APEX: apexins.sql, apxrtins.sql, apxchpwd.sql e APEX_PUBLIC_USER [on-prem]

1. Baixe `apex_26.1_en.zip` (só inglês) ou `apex_26.1.zip` (com outros idiomas). Descompacte preservando os diretórios, num caminho **curto, sem espaços** e **gravável** (o log é escrito ali).
2. Entre no diretório `apex`, conecte no SQLcl como `SYS AS SYSDBA` (o SQLcl é a CLI recomendada para todos os scripts do guia) e desabilite regras de complexidade de senha do profile padrão.
3. Rode o script do tipo de ambiente:
   ```sql
   -- desenvolvimento completo
   @apexins.sql tablespace_apex tablespace_files tablespace_temp images
   @apexins.sql SYSAUX SYSAUX TEMP /i/
   -- runtime-only
   @apxrtins.sql SYSAUX SYSAUX TEMP /i/
   ```
   Use `/i/` como diretório virtual de imagens para facilitar upgrades futuros.
4. **Conta de administrador da instância** (só em instalação nova; no upgrade ela é preservada): `@apxchpwd.sql` pede usuário, senha e e-mail e cria a conta se não existir. Serve também para trocar a senha ou **desbloquear** o admin da instância. **Não suportado no Autonomous nem no APEX Service.**
5. Reinicie os processos que parou antes da instalação.
6. **`APEX_PUBLIC_USER`** é criado sem autenticação. Só é preciso definir senha (`ALTER USER APEX_PUBLIC_USER IDENTIFIED BY new_password`, conectado ao `CDB$ROOT` se o APEX estiver no CDB) se o ORDS for configurado para conectar como `APEX_PUBLIC_USER` em vez de `ORDS_PUBLIC_USER`.
7. **`APEX_PUBLIC_ROUTER`**: com ORDS 24.x ou superior, todo GET em `/r/` (friendly URLs) passa por um módulo REST do ORDS. Se o ORDS foi instalado ou atualizado **depois** do APEX, rode como SYS:
   ```sql
   set serveroutput on
   begin
       sys.validate_apex;
   end;
   /
   ```

**Instalação automatizada (`apxsilentins.sql`)**: substitui de uma vez a instalação, a criação do admin, a configuração do `APEX_PUBLIC_USER`, a ACL de rede e o `apex_rest_config.sql`. Recebe oito argumentos na ordem:
```sql
@apxsilentins.sql tablespace_apex tablespace_files tablespace_temp images
    password_apex_pub_user password_apex_listener password_apex_rest_pub_user
    password_internal_admin
@apxsilentins.sql SYSAUX SYSAUX TEMP /i/ Passw0rd!1 Passw0rd!2 Passw0rd!3 Passw0rd!4
```
A senha do `ADMIN` precisa ter no mínimo 6 caracteres, um dígito, uma pontuação e uma maiúscula. Depois disso, siga a instalação e configuração do ORDS (exceto *Configuring Static File Support*) e crie o workspace.

Fonte: [Downloading and Installing Oracle APEX](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/downloading-installing-apex.html), [Automating the APEX Installation Process](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/automating-the-apex-installation-process.html), [About SQLcl Support](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/about-sqlcl-support.html)

### Network services e ACL para APEX_MAIL, REST, LDAP e impressão (DBMS_NETWORK_ACL_ADMIN) [on-prem]

- **[Autonomous] Não se aplica:** o APEX no Autonomous acessa endpoints externos sem configuração adicional.
- On-prem, o acesso à rede vem **desabilitado** por padrão. Sem conceder `connect` ao dono do schema do APEX (`APEX_260100`) falham: envio de e-mail (`APEX_MAIL` aceita a chamada, mas o envio dá problema), consumo de REST e web services, chamadas LDAP e servidor de impressão remoto.
- A concessão vale para a instância inteira (todas as apps de todos os workspaces). Os schemas dos workspaces só precisam de grant próprio se usarem `UTL_HTTP`/`UTL_SMTP` diretamente.
- No upgrade, a configuração de rede da versão anterior é aplicada automaticamente. Requer `compatible` ≥ `11.1.0.0.0`.
```sql
-- qualquer host
BEGIN
    DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
        host => '*',
        ace  => xs$ace_type(privilege_list => xs$name_list('connect'),
                            principal_name => APEX_APPLICATION.g_flow_schema_owner,
                            principal_type => xs_acl.ptype_db));
END;
/
-- só localhost (servidor de e-mail ou impressão na mesma máquina): troque host => 'localhost'
```

Fonte: [Enabling Network Services in Oracle Database](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/enabling-network-services.html)

### JOB_QUEUE_PROCESSES: jobs concorrentes exigidos por SQL Scripts e transações

- `JOB_QUEUE_PROCESSES` limita quantos jobs rodam ao mesmo tempo. O APEX usa jobs no suporte transacional e na execução de **SQL Scripts**: se o parâmetro não estiver habilitado e funcionando, **scripts do SQL Workshop não executam**.
- Onde ver: no log de instalação; no App Builder em **Help > About** (fim da página); ou via SQL `SELECT VALUE FROM v$parameter WHERE NAME = 'job_queue_processes'`.
- Alterar [on-prem], como SYS: `ALTER SYSTEM SET JOB_QUEUE_PROCESSES = 20`.
- No Autonomous o time não ajusta esse parâmetro, mas a página **About** continua sendo um bom ponto de diagnóstico se SQL Scripts ficarem presos.

Fonte: [Controlling the Number of Concurrent Jobs](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/controlling-number-of-concurrent-jobs.html)

### Idiomas do Builder e do runtime; instalar traduções (load_lang.sql)

- O **Builder e o Administration Services** estão traduzidos em 9 idiomas, entre eles **Portuguese (Brazil)**. O desenvolvedor escolhe o idioma na tela de login ou na home.
- As **mensagens de runtime** do motor (paginação, mensagens de relatório etc.) existem em cerca de 34 idiomas, incluindo português do Brasil e de Portugal. Para outros idiomas, a equipe traduz as mensagens internas (ver *Translating Messages Used Internally by APEX* no App Builder User's Guide).
- [on-prem] Exige `apex_26.1.zip`. Defina `NLS_LANG` com charset `AL32UTF8` (por exemplo `American_America.AL32UTF8`) **antes** de abrir o SQLcl, entre em `apex/builder/<código>` e rode `@load_<código>.sql` (por exemplo `load_de.sql`). O banco precisa de um charset compatível com o idioma; `AL32UTF8` atende todos. Depois de aplicar um patch set, reexecute o patch se instalar traduções depois.
- **[Autonomous]** Todos os idiomas já vêm instalados.

Fonte: [About Running APEX in Other Languages](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/running-apex-in-other-languages.html), [Installing Translated Versions of APEX](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/installing-translated-versions-of-apex.html)

### Criar workspace e usuários após a instalação (Administration Services, apex_admin)

- O Administration Services fica, por padrão, em `http://hostname:port/ords/apex_admin` (porta padrão 8080), com login do admin da instância.
- **Create Workspace** (Manage Workspaces > Create Workspace): nome único; *Workspace ID* em branco para gerar automaticamente (se informado, inteiro positivo **> 100000**); reutilizar schema existente ou criar um novo com senha e **quota de espaço**; dados do admin do workspace.
- **Create User** (Manage Developers and Users): username com até **100 caracteres**, sem espaços, aceitando só `&` e `.` como especiais. Atributos relevantes:
  - *Default Date Format*: formato de data padrão no SQL Workshop;
  - *Default Schema*: só preferência, **não é controle de segurança**;
  - *Accessible Schemas (null for all)*: lista separada por `:` que restringe os schemas visíveis ao usuário no SQL Workshop;
  - *User is an administrator* / *User is a developer*, *App Builder Access*, *SQL Workshop Access*, *Team Development Access*, *Data Reporter Builder Access* (o administrador sempre tem acesso; o atributo fica desabilitado se o componente estiver desligado no workspace);
  - *Account Availability* (Locked/Unlocked; bloqueia sozinho ao exceder as falhas de login definidas em Workspace Preferences);
  - *Require Change of Password On First Use*: vale para Builder **e** para apps que usam contas APEX.
- Login no workspace: `http://hostname:port/apex/` com Workspace, Username e Password (case-sensitive).

Fonte: [Creating a Workspace and Adding APEX Users](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/creating-workspace-and-adding-apex-users.html)

### Multitenant: APEX no CDB$ROOT × local em cada PDB × application container [on-prem]

- **Conceitos:** um CDB tem `CDB$ROOT` (objetos comuns via *metadata links*/*object links*), `PDB$SEED` (modelo para PDBs novos) e PDBs.
- **Recomendação da Oracle:** instalar o APEX **em cada PDB** na maioria dos casos. Instalar no CDB só faz sentido para hosting ou quando todos os PDBs usam APEX na **mesma release e patch**. Mesmo com APEX no CDB, as apps rodam nos PDBs: executar apps ou usar o Builder no `CDB$ROOT` **não é suportado**.
- **APEX local em PDBs:** sem metadata links; tudo fica em `APEX_260100` dentro de cada PDB, o que permite versões diferentes por PDB. Para isso, remova antes o APEX do CDB com `@apxremov.sql` (exige **conexão local**; remove de todos os PDBs, do `CDB$ROOT` e do `PDB$SEED`, **apagando todas as apps**). Depois: `ALTER SESSION SET CONTAINER = <PDB_name>;` e `@apexins.sql SYSAUX SYSAUX TEMP /i/`.
- **APEX no CDB:** conecte ao `CDB$ROOT` (conexão local) e rode `apexins.sql`/`apxrtins.sql`.
- **Application container:** `CREATE PLUGGABLE DATABASE apex_approot1 AS APPLICATION CONTAINER ...`, depois `ALTER SESSION SET CONTAINER = apex_approot1;` e `@apxappcon.sql SYSAUX SYSAUX TEMP /i/ <senha APEX_PUBLIC_USER>` (5º argumento ignorado no upgrade). Instala o APEX como *application* `APEX` no root. Patch/upgrade é feito no root, e cada PDB continua na versão antiga até fazer `ALTER PLUGGABLE DATABASE application APEX sync`. Verificação: procure `ORA-`/`PLS-` no log, recompile com `sys.dbms_utility.compile_schema('APEX_260100', false)` e `('FLOWS_FILES', false)` e consulte `dba_applications` (esperado `APEX 26.1 NORMAL`) e `dba_app_errors` (esperado nenhuma linha). Dá para criar um *application seed* (`CREATE PLUGGABLE DATABASE as seed ...`) e PDBs a partir dele já com o APEX instalado.

Fonte: [Utilizing Multitenant Architecture](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/multitenant-architecture.html), [Understanding the Installation Choices](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/understanding-installation-choices.html), [Installing APEX into Different PDBs](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/installing-apex-into-different-pdbs.html), [Installing APEX into an Application Container](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/installing-apex-into-application-container.html)

### Plugar PDB ou non-CDB com e sem APEX no root: cenários e scripts [on-prem]

**Destino com APEX no `CDB$ROOT` (padrão)**
| Origem | O que fazer |
|---|---|
| Non-CDB com APEX | Rodar `$ORACLE_HOME/rdbms/admin/noncdb_to_pdb.sql` (cria metadata links e recompila); configurar o servidor web |
| PDB com APEX comum de outro CDB | Nada além de configurar o servidor web, se a versão for igual |
| PDB com APEX **local** de outro CDB | No PDB: `ALTER SESSION SET CONTAINER = <PDB_name>;` e `@apex_to_common.sql` (de `$ORACLE_HOME/rdbms/admin`) para trocar objetos locais por metadata links |
| Origem sem APEX | Instalar na origem a **mesma versão** do destino **antes** de plugar |

**Destino sem APEX no root**
| Origem | Resultado |
|---|---|
| Non-CDB ou PDB com APEX local | `noncdb_to_pdb.sql` não cria links para o APEX; basta configurar o servidor web |
| PDB com APEX comum de outro CDB | **Erro ao abrir o PDB** (links para um root sem APEX). Remova o APEX do PDB ou instale-o no root de destino. Instalar no root com PDBs que já têm APEX local **não é suportado** |
| PDB com APEX local | Nada além do servidor web |
| Sem APEX | Nada a fazer |

**Versões incompatíveis** entre root e PDB: veja o caso correspondente em §6.

Fonte: [Plugging in a PDB When APEX Is Installed in the Root Container](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/plugging-in-pdb-when-apex-installed-in-root-container.html), [Plugging in a PDB When APEX Is Not in the Root Container of the Target CDB](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/plugging-in-pdb-when-apex-is-not-in-root-container-of-target-cdb.html)

### Upgrade de release anterior: caminhos suportados, numeração, testes e limpeza

- O upgrade **cria um schema novo** (`APEX_260100`) e migra os metadados das apps. **Upgrade direto só a partir do 18.1.** Antes disso: primeiro para 24.2 e depois para 26.1, ou exportar workspaces e apps e importar numa instância 26.1 nova.
- **Cuidado documentado:** de 18.1 para 24.2, passe antes pelo 24.1.
- **Numeração:** desde 2018 a release acompanha o ano (18.1, 18.2…). Não há mais *patch set releases* do tipo 5.1.1, só releases completas; ainda podem sair **PSEs** (*patch set exceptions*) para defeitos graves (ver a página *Known Issues* da 26.1).
- **Versões:** a release do APEX aparece no canto inferior direito da home do workspace e em **Help > About** (*Product Build*); a do ORDS em **Help > About**, seção *CGI Environment*, variável `APEX_LISTENER_VERSION`.
- **Bancos que trazem APEX** (19c → 18.1; 18c → 5.1; 12.2 → 5.0; 12.1 → 4.2; 11.2 → 3.2; 11.1 → 3.0): a Oracle recomenda atualizar para a última release e **não alterar arquivos do APEX dentro do Oracle home**.
- **Apps existentes** funcionam sem modificação após o upgrade, mas não ganham a UI nem os componentes novos sozinhas. Para isso, veja *Upgrading APEX Applications* no App Builder User's Guide (coberto em outra seção deste documento).
- **Testes de regressão:** priorize páginas complexas (muito JavaScript ou muito PL/SQL), as páginas ajustadas pelo *Upgrade Application*/*Advisor*, uma amostra de relatórios, gráficos e formulários e **toda app cujo *compatibility mode* foi alterado**. Ordem sugerida: desenvolvimento → QA/teste (com build das apps vindas de dev) → produção (idem). Não prolongue demais a fase de testes.
- **Limpeza:** mantenha o schema antigo por algumas semanas e depois remova-o em dev, teste e produção. Isso libera espaço e evita que alguém acesse o schema velho pelo SQL Developer ou SQLcl.
- **Reverter** é relativamente simples, porque cada release tem seu schema: basicamente apontar sinônimos públicos e grants de volta ao schema anterior. **Tudo o que foi alterado na instância nova se perde.**
- **Logs de instalação/upgrade** no Administration Services: **Manage Instance > Manage Logs and Files > Install / Upgrade Logs** (fases, métricas e erros por fase).
- **[Autonomous]** Upgrades e patches são da Oracle. Para controlar o momento do upgrade, a doc remete ao tópico *Control Oracle APEX Upgrades* do guia do Autonomous Database Serverless.

Fonte: [Upgrading from a Previous APEX Release](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/upgrading-from-previous-apex-release.html)

### Upgrade com uptime máximo: scripts em fases apexins1/2/3 [on-prem]

O upgrade tem quatro fases:
1. criar schemas e objetos (tabelas, packages): não afeta ninguém;
2. migrar metadados das apps: **desenvolvimento desabilitado**, runtime funciona, mas *background processes* novos de *Page Processes* não rodam;
3. migrar dados alterados pelo runtime e trocar de versão: **APEX indisponível**;
4. migrar logs e resumos: roda em background por um scheduler job iniciado ao fim da fase 3, sem afetar usuários.

Em vez de `apexins.sql`/`apxrtins.sql` numa tacada só, rode em sequência:
```sql
@apexins1.sql sysaux sysaux temp /i/   -- runtime: @apxrtins1.sql
@apexins2.sql sysaux sysaux temp /i/   -- runtime: @apxrtins2.sql
-- desabilite o acesso web no ORDS
@apexins3.sql sysaux sysaux temp /i/   -- runtime: @apxrtins3.sql
-- instale as imagens da versão nova (pode ser antes, se o diretório for diferente, ex. /i212/ × /i211/)
-- reabilite o acesso web e reinicie o ORDS; a fase 4 termina em background
```
Reduz a indisponibilidade de horas para alguns minutos. **Não suportado com APEX no `CDB$ROOT`.**

Fonte: [Maximizing Uptime During an APEX Upgrade](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/maximizing-uptime-during-apex-upgrade.html)

### Pós-upgrade: remover schemas e objetos SYS de releases anteriores [on-prem]

- Os usuários de releases antigas são privilegiados e devem ser removidos quando não forem mais necessários.
- Candidatos (padrão `FLOWS_XXXXXX`/`APEX_XXXXXX`, com seis dígitos):
  ```sql
  SELECT username
    FROM dba_users
   WHERE (  username LIKE 'FLOWS\_______' ESCAPE '\'
         OR username LIKE 'APEX\_______' ESCAPE '\' )
     AND username NOT IN ( SELECT schema FROM dba_registry WHERE comp_id = 'APEX' );
  ```
- Remoção (non-CDB):
  ```sql
  DROP USER APEX_240200 CASCADE;
  DROP PACKAGE SYS.WWV_DBMS_SQL_APEX_240200;
  ```
- Em CDB, via `catcon.pl`:
  ```sh
  $ORACLE_HOME/perl/bin/perl -I $ORACLE_HOME/rdbms/admin $ORACLE_HOME/rdbms/admin/catcon.pl -b drop_apex240200 -- --x'drop user APEX_240200 cascade'
  $ORACLE_HOME/perl/bin/perl -I $ORACLE_HOME/rdbms/admin $ORACLE_HOME/rdbms/admin/catcon.pl -b drop_wwv_dbms_sql -- --x'drop package SYS.WWV_DBMS_SQL_APEX_240200'
  ```
- Se a release antiga tinha network services, pode ficar uma ACL inválida: `EXEC DBMS_NETWORK_ACL_ADMIN.DELETE_PRIVILEGE('power_users.xml', 'APEX_240200');`.

Fonte: [Performing Post Installation Tasks for Upgrade Installations](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/performing-post-installation-tasks-for-upgrade-installations.html)

## 6. Troubleshooting de instalação e upgrade (casos)

> Os casos abaixo vêm do apêndice *APEX Installation Troubleshooting* e das notas de troubleshooting espalhadas no Installation Guide. Quase todos exigem acesso `SYS AS SYSDBA` e valem só **on-prem**; no Autonomous, a instalação é da Oracle e o caminho é abrir chamado. Os casos marcados como relevantes para o Autonomous podem aparecer também em runtime.

### Como saber se a instalação do APEX deu certo: log installYYYY-MM-DD_HH24-MI-SS.log

**Sintoma:** você não sabe se o `apexins.sql` terminou bem, ou viu alguns erros no log.
**Causa:** o script grava um log no diretório `apex` com o nome `installYYYY-MM-DD_HH24-MI-SS.log`, e o diretório precisa ser **gravável**.
**Correção:** procure no fim do log o banner `Thank you for installing Oracle APEX.` e `Oracle APEX is installed in the APEX_260100 schema.`. Alguns erros no log **não significam falha**: os aceitáveis vêm marcados como tal no próprio log.
**Prevenção:** instale a partir de um diretório gravável, com caminho curto e sem espaços.

Fonte: [Reviewing a Log of an Installation Session](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/reviewing-log-of-installation-session.html), [Cleaning Up After a Failed Installation](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/cleaning-up-after-failed-installation.html)

### Verificar se a instalação do APEX está VALID (DBA_REGISTRY)

**Sintoma:** dúvida se o APEX está íntegro depois de instalar, atualizar ou plugar um PDB.
**Causa:** objetos inválidos ou instalação incompleta.
**Correção:**
```sql
SELECT STATUS FROM DBA_REGISTRY WHERE COMP_ID = 'APEX';
```
`VALID` indica instalação bem-sucedida. Em application container, recompile com `sys.dbms_utility.compile_schema('APEX_260100', false)` e `('FLOWS_FILES', false)` e confira `dba_app_errors`.

Fonte: [Verifying the Validity of an APEX Installation](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/verifying-validity-of-an-apex-installation.html), [Installing APEX into an Application Container](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/installing-apex-into-application-container.html)

### SP2-0310: unable to open file "apexins.sql"

**Sintoma:** o SQLcl retorna `SP2-0310: unable to open file "apexins.sql"`.
**Causa:** o SQLcl foi aberto fora do diretório onde o ZIP foi descompactado.
**Correção:** saia do SQLcl, mude para o diretório da instalação (por exemplo `C:\TEMP\apex`) e abra o SQLcl de novo.

Fonte: [Downloading and Installing Oracle APEX](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/downloading-installing-apex.html)

### Instalação nova falhou: limpar e reinstalar (apxremov.sql)

**Sintoma:** o banner de sucesso não aparece e você quer reinstalar do zero.
**Causa:** instalação nova incompleta (não um upgrade).
**Correção:** confirme antes que **não** há release anterior (próximo caso). Depois, no diretório `apex`, como `SYS AS SYSDBA`, rode `@apxremov.sql`. **Saia do SQLcl e reconecte** antes de rodar `apexins.sql` de novo.
**Prevenção:** **não use `apxremov.sql` se o banco foi atualizado e você ainda quer a release anterior**: nesse caso reverta (casos seguintes). Em CDB, `apxremov.sql` remove o APEX de todos os PDBs e apaga todas as apps.

Fonte: [Removing APEX from the Database](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/removing-apex-from-the-database.html), [Cleaning Up After a Failed Installation](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/cleaning-up-after-failed-installation.html)

### Upgrade falhou: verificar se existe release anterior do APEX no banco

**Sintoma:** upgrade com erro e dúvida se dá para voltar.
**Causa:** o schema da release anterior continua intacto após o upgrade.
**Correção:**
```sql
select username from dba_users
 where regexp_like(username,'(FLOWS|APEX)_\d{6}')
   and username <> (select table_owner from all_synonyms
                     where synonym_name = 'WWV_FLOW' and owner = 'PUBLIC');
```
Se voltar alguma linha, existe release anterior e é possível reverter.

Fonte: [Verifying If You Have a Previous Release of APEX](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/verifying-if-have-previous-release-of-apex.html), [Reverting to a Previous Release After a Failed Upgrade Installation](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/reverting-to-previous-release-after-failed-upgrade-installation.html)

### Upgrade falhou: reverter para a release anterior (apxdwngrd.sql) e remover o schema APEX_260100

**Sintoma:** upgrade para 26.1 falhou e é preciso voltar à release anterior.
**Causa:** o upgrade cria `APEX_260100` ao lado do schema antigo; reverter significa reapontar sinônimos e grants.
**Correção:**
1. Se alterou o diretório de imagens, aponte o alias `/i/` de volta para as imagens da release de destino.
2. Releases **19.1 a 24.2**, non-CDB ou PDB com APEX local: no diretório `apex` **da release de destino**, como `SYS AS SYSDBA`, rode `@apxdwngrd.sql`. Em CDB, crie um `apxdwngrd_cdb.sql` que chama `catcon.pl -b apx<versão>dgrd apxdwngrd.sql` (o script da doc lê o `ORACLE_HOME` com `sys.dbms_system.get_env`). Para 18.x e anteriores a doc traz scripts específicos por release (até 3.x, com `wwv_flow_upgrade.switch_schemas('APEX_260100','FLOWS_0x0x00')`).
3. Remova o schema da 26.1: non-CDB, `DROP USER APEX_260100 CASCADE;`; em CDB, crie `remove_apx261_usr1.sql` (`alter session set current_schema = SYS; drop user APEX_260100 cascade;`) e um `remove_apx261_usr.sql` que o executa via `catcon.pl -b remove_apx261_usr`, depois rode `@remove_apx261_usr.sql`.
4. Se a **REST Administration Interface** era usada antes do upgrade, recrie o usuário: `create user apex_instance_admin_user no authentication` (ou `identified by <random-password> password expire`, se havia autenticação).
5. Tente o upgrade de novo.
**Prevenção:** antes do upgrade, guarde uma cópia do diretório de imagens com o número da release (`images_24_2`) e faça backup do banco.

Fonte: [Reverting to a Previous Release](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/reverting-to-a-previous-release.html), [Reverting the Images Directory](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/reverting-the-images-directory.html), [Removing the APEX Release Schema](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/removing-the-apex-release-schema.html)

### Imagens, CSS ou ícones do APEX não aparecem (alias /i/ duplicado)

**Sintoma:** Builder ou apps sem imagens e estilos, com layout quebrado.
**Causa:** há **mais de uma definição do alias `/i/`** no servidor web, ou o diretório de imagens não corresponde à versão instalada (por exemplo, não foi atualizado no upgrade).
**Correção:** renomeie a primeira definição de `/i/` para outro alias ou copie as imagens da versão instalada para o diretório da primeira definição de `/i/`. Alternativa: usar a CDN da Oracle (`IMAGE_PREFIX` = `https://static.oracle.com/cdn/apex/<versão>/`).
**Prevenção:** use `/i/` como diretório virtual e atualize as imagens a cada upgrade, ou use a CDN, que se atualiza sozinha.

Fonte: [About Images Displaying Incorrectly in APEX](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/images-displaying-incorrectly.html), [Configuring Oracle REST Data Services](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/configuring-ords.html)

### Page protection violation ao entrar no APEX logo após a instalação

**Sintoma:** erro *page protection violation* ao tentar fazer login no APEX depois de instalar.
**Causa:** em geral, alteração manual de itens de página protegidos. Logo após a instalação, a doc associa o erro ao ORDS.
**Correção:** pare e reinicie o ORDS. Se a causa não for clara, procure o administrador da aplicação.
**Observação para apps (vale também no Autonomous):** em runtime, a mesma mensagem aparece quando algo altera um item protegido (*Session State Protection*), por exemplo JavaScript mudando o valor de um item *Display Only*/protegido ou um link sem checksum. Gere links com `apex_page.get_url`.

Fonte: [About Page Protection Violation](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/page-protection.html)

### ORA-44416: Invalid ACL ao conceder network services

**Sintoma:** `DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE` falha com `ORA-44416: Invalid ACL`.
**Causa:** a ACL atribuída a `'*'` referencia usuários que já foram removidos (*dangling references*).
**Correção:** identifique:
```sql
SELECT ACL, PRINCIPAL
  FROM DBA_NETWORK_ACLS NACL, XDS_ACE ACE
 WHERE HOST = '*' AND LOWER_PORT IS NULL AND UPPER_PORT IS NULL
   AND NACL.ACLID = ACE.ACLID
   AND NOT EXISTS (SELECT NULL FROM ALL_USERS WHERE USERNAME = PRINCIPAL);
```
Depois rode o bloco da doc, que pega o `ACLID` em `DBA_NETWORK_ACLS`. Se ainda existem principais válidos, ele remove só os inválidos com `UPDATE XDB.XDB$ACL SET OBJECT_VALUE = DELETEXML(OBJECT_VALUE,'/ACL/ACE[PRINCIPAL="..."]')`; senão, apaga a ACL com `DELETE FROM XDB.XDB$ACL WHERE OBJECT_ID = ACL_ID`. Faça `COMMIT` e rode de novo o `APPEND_HOST_ACE` para `APEX_260100`.
**Prevenção:** depois de remover schemas de releases antigas, limpe os privilégios deles (`DBMS_NETWORK_ACL_ADMIN.DELETE_PRIVILEGE('power_users.xml', 'APEX_240200')`). **[Autonomous]** não se aplica.

Fonte: [Enabling Network Services in Oracle Database](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/enabling-network-services.html), [Performing Post Installation Tasks for Upgrade Installations](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/performing-post-installation-tasks-for-upgrade-installations.html)

### APEX_MAIL, REST ou LDAP não funcionam on-prem (network services desabilitados)

**Sintoma:** `APEX_MAIL.SEND` executa sem erro, mas o e-mail não sai; chamadas REST, REST Enabled SQL, LDAP ou impressão remota falham.
**Causa:** on-prem, o banco não concede `connect` de rede ao schema do APEX por padrão.
**Correção:** `DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE` para `APEX_APPLICATION.g_flow_schema_owner` (ver §5). Se o código do workspace usa `UTL_HTTP`/`UTL_SMTP` direto, conceda também ao schema do workspace.
**Prevenção:** **[Autonomous]** a doc diz que não é preciso configurar nada para endpoints externos; se o problema aparecer lá, investigue credenciais, URL ou o log de e-mail e web service (outras seções deste documento), não a ACL.

Fonte: [Enabling Network Services in Oracle Database](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/enabling-network-services.html)

### Instância APEX inutilizável após 180 dias: senha do APEX_PUBLIC_USER expirada

**Sintoma:** de repente o APEX para de responder ou o ORDS não conecta, cerca de 180 dias após a instalação.
**Causa:** no profile padrão, `PASSWORD_LIFE_TIME` = 180; a senha do `APEX_PUBLIC_USER` expira e a instância fica inutilizável até a troca.
**Correção:** `ALTER USER APEX_PUBLIC_USER IDENTIFIED BY new_password` e atualize a senha na configuração do ORDS.
**Prevenção:** crie um profile com `PASSWORD_LIFE_TIME UNLIMITED` e atribua ao `APEX_PUBLIC_USER`. Só se aplica se o ORDS conecta como `APEX_PUBLIC_USER` (e não como `ORDS_PUBLIC_USER`).

Fonte: [Downloading and Installing Oracle APEX](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/downloading-installing-apex.html)

### Service Unavailable HTTP 503 em friendly URLs (/r/): APEX_PUBLIC_ROUTER sem sessões

**Sintoma:** HTTP 503 *Service Unavailable* em sistemas muito ativos, nas URLs amigáveis `/r/...`.
**Causa:** `APEX_PUBLIC_ROUTER` atingiu o máximo de sessões permitido pelo profile (`SESSIONS_PER_USER`). Com ORDS 24.x ou superior, todo GET em `/r/` passa por um módulo REST do ORDS que usa essa conta.
**Correção:** crie um profile com `SESSIONS_PER_USER UNLIMITED` e atribua ao `APEX_PUBLIC_ROUTER`.
**Prevenção:** se o ORDS for instalado ou atualizado depois do APEX, rode `sys.validate_apex` como SYS.

Fonte: [Downloading and Installing Oracle APEX](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/downloading-installing-apex.html)

### Friendly URLs (/r/) quebradas após atualizar o ORDS: rodar sys.validate_apex

**Sintoma:** depois de instalar ou atualizar o ORDS, as URLs `/r/<workspace>/<app>/<page>` deixam de resolver.
**Causa:** o ORDS foi instalado ou atualizado **depois** do APEX, e o módulo de roteamento não foi validado.
**Correção:** como SYS:
```sql
set serveroutput on
begin
    sys.validate_apex;
end;
/
```
**Prevenção:** rode após **cada** upgrade de ORDS.

Fonte: [Downloading and Installing Oracle APEX](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/downloading-installing-apex.html)

### SQL Scripts do SQL Workshop não executam (JOB_QUEUE_PROCESSES)

**Sintoma:** ao rodar um script em **SQL Workshop > SQL Scripts**, nada acontece ou a execução não termina.
**Causa:** SQL Scripts e o suporte transacional do APEX dependem de jobs do banco; com `JOB_QUEUE_PROCESSES` desabilitado ou baixo, o script não roda.
**Correção:** veja o valor em **Help > About** ou em `v$parameter`; on-prem, `ALTER SYSTEM SET JOB_QUEUE_PROCESSES = 20` (exemplo da doc). No Autonomous o parâmetro é da Oracle; se persistir, abra chamado.

Fonte: [Controlling the Number of Concurrent Jobs](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/controlling-number-of-concurrent-jobs.html)

### Erro ao colar muitos dados no SQL Workshop ou ao criar app a partir de planilha (limite de POST)

**Sintoma:** falha ao colar um volume grande de dados (*copy and paste*) no SQL Workshop ou no assistente de app a partir de planilha.
**Causa:** o ORDS standalone (200 KB por padrão até o 19.4.6) ou o Tomcat (2 MB) limitam POSTs que não são upload de arquivo.
**Correção:** standalone, aumente `org.eclipse.jetty.server.Request.maxFormContentSize` (por exemplo `java -Dorg.eclipse.jetty.server.Request.maxFormContentSize=3000000 -jar ords.war`); Tomcat, aumente `maxPostSize`.
**Prevenção:** para volumes grandes, prefira **upload de arquivo** (que não sofre esse limite) a copiar e colar.

Fonte: [Downloading and Installing Oracle REST Data Services (ORDS)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/downloading-installing-ords.html)

### PDB não abre ou só abre em modo restrito: versão do APEX diferente entre CDB$ROOT e PDB

**Sintoma:** erro ao abrir o PDB, que só abre em modo restrito (usuários com `RESTRICTED SESSION`).
**Causa:** a versão do APEX no `CDB$ROOT` difere da do PDB, ou o PDB veio de um CDB com APEX comum para um root sem APEX.
**Correção:**
- PDB **mais novo** que o root: aplique patch no root (`@apxpatch_con.sql`) se for diferença de versão menor, ou faça upgrade do APEX no CDB se for versão maior.
- PDB **mais antigo** que o root: patch no PDB via `catcon.pl -b apxpatch -c '<PDB_name>' apxpatch.sql`, ou upgrade via `catcon.pl -b apexins -c '<PDB_name>' apexins_nocdb.sql --pSYSAUX --pSYSAUX --pTEMP --p/i/ --p1,2,3` (`apxrtins_nocdb.sql` para runtime). Depois siga as notas do patch para o diretório de imagens.
- PDB com APEX comum plugado em root sem APEX: remova o APEX do PDB ou instale-o no root de destino.
**Prevenção:** antes de plugar, confira se a versão do APEX na origem é a mesma do destino. Se a origem não tem APEX e o root tem, instale a mesma versão na origem antes.

Fonte: [Plugging in a PDB When APEX Is Installed in the Root Container](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/plugging-in-pdb-when-apex-installed-in-root-container.html), [Plugging in a PDB When APEX Is Not in the Root Container of the Target CDB](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/plugging-in-pdb-when-apex-is-not-in-root-container-of-target-cdb.html)

### Instalação ou upgrade falha por memória ou WORKAREA_SIZE_POLICY

**Sintoma:** instalação ou upgrade com erros de memória ou desempenho muito ruim.
**Causa:** SGA < 1200 MB, PGA < 300 MB ou `WORKAREA_SIZE_POLICY` = `MANUAL`.
**Correção:** ajuste `SGA_TARGET`/`PGA_AGGREGATE_TARGET` (ou `MEMORY_TARGET`) e reinicie; rode `ALTER SESSION SET WORKAREA_SIZE_POLICY = AUTO;` na mesma sessão da instalação (em CDB, `ALTER SYSTEM ... SCOPE=BOTH`).

Fonte: [Oracle APEX Installation Requirements](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/apex-installation-requirements.html)

### Provisionamento de workspace parou de funcionar após remover o usuário ANONYMOUS

**Sintoma:** pedidos ou criação de workspace falham.
**Causa:** o usuário `ANONYMOUS`, criado pelo Oracle XML DB, foi removido; o provisionamento depende dele.
**Correção:** restaure o XML DB ou o usuário (ver *Administration of Oracle XML DB* no XML DB Developer's Guide).
**Prevenção:** nunca remova `ANONYMOUS` num banco com APEX.

Fonte: [Oracle APEX Installation Requirements](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/apex-installation-requirements.html)

### Administrador da instância bloqueado ou senha esquecida (apxchpwd.sql)

**Sintoma:** não é possível entrar no Administration Services com o `ADMIN`.
**Causa:** conta bloqueada por tentativas erradas ou senha esquecida.
**Correção:** on-prem, no diretório `apex`, como `SYS AS SYSDBA`, rode `@apxchpwd.sql` (cria, troca senha ou desbloqueia). **[Autonomous]** `apxchpwd.sql` não é suportado: a administração da instância segue o modelo do serviço.

Fonte: [Downloading and Installing Oracle APEX](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/downloading-installing-apex.html)
## 7. SQL Commands

O SQL Workshop reúne cinco ferramentas na página inicial: Object Browser, SQL Commands, SQL Scripts, Utilities e RESTful Services. Esta seção cobre o SQL Commands, o editor de comandos avulsos. As seções 8 a 10 tratam das outras ferramentas, exceto RESTful Services, que fica em outro documento.

### SQL Workshop: schema da sessão (Schema list) e onde os comandos executam

- Toda ferramenta do SQL Workshop trabalha sobre um **schema padrão da sessão do SQL Workshop**. Esse schema é escolhido na lista **Schema**, no lado direito da página inicial do SQL Workshop. A lista mostra **somente os schemas atribuídos ao workspace** (ver a seção sobre schemas do workspace neste documento).
- O SQL Commands, o Object Browser, o Query Builder, as Object Reports e a Table Finder também têm a sua própria lista Schema. Trocar o schema muda os objetos visíveis e o schema em que o comando roda.
- O **History** do SQL Commands guarda o schema em que cada comando foi executado. Ao carregar um comando do histórico, o editor também volta para aquele schema. Antes de rodar DDL ou DML carregado do histórico, confira o schema selecionado.
- A documentação do SQL Workshop **não descreve** o contexto de sessão da aplicação (itens de app, `APP_USER`, `v('...')`, application items) dentro do SQL Commands ou do SQL Scripts. Ela não diz que esses valores existem nem que não existem. Não conte com eles: código que depende de estado de sessão da aplicação deve ser testado na própria app ou numa ferramenta externa (ver o caso abaixo e a seção "Aplicação no Corlix Hub").
- O único ponto da doc do SQL Workshop que toca em contexto APEX é o Quick SQL. Com a opção *APEX Enabled*, as triggers de auditoria geradas usam `coalesce(sys_context('APEX$SESSION','APP_USER'),user)`, ou seja, caem para `user` quando não há usuário APEX no contexto.

Fonte: [Getting Started with SQL Workshop](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/getting-started.html) · [Using SQL Command History](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/sql-command-history.html) · [Configuring Quick SQL Settings](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/configuring-quick-sql-settings.html)

### SQL Commands: o que é e regras gerais (About SQL Commands)

O SQL Commands executa SQL ad hoc ou blocos PL/SQL anônimos para criar, editar, consultar, executar e remover objetos. Regras da doc:
- Comandos salvos no **Query Builder** aparecem no SQL Commands (Saved SQL).
- Comandos salvos precisam de **nome único no workspace**. O nome também não pode repetir entre SQL Commands e Query Builder.
- **Não há interação entre SQL Commands e SQL Scripts.** Um não enxerga o histórico, os resultados ou as variáveis do outro. Para passar um comando de um para o outro, copie e cole.
- Acesso: Workspace home > **SQL Workshop** > **SQL Commands**.

Quando usar: consultas rápidas, `describe`, explain plan, um `create or replace` de cada vez, conferir o resultado de um DML antes de confirmar (no modo transacional). Quando **não** usar: instalar um módulo com vários arquivos (use SQL Scripts ou SQLcl), rodar comandos SQL*Plus (não são suportados) ou exportar resultado grande para arquivo.

Fonte: [About SQL Commands](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/sql-commands.html) · [Accessing SQL Commands](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/accessing-sql-commands.html) · [Using SQL Commands](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/using-sql-commands.html)

### SQL Commands: página inicial, Command Editor e controles (About the SQL Commands Home Page)

A página tem dois blocos: o **Command Editor** (em cima) e o **Display pane** (embaixo).

| Controle do Command Editor | O que faz |
|---|---|
| Language | Linguagem usada para executar o texto digitado |
| **Rows** | Quantas linhas de saída exibir, **até no máximo 100.000**. A saída de DBMS Output aparece inteira, **independentemente** desse valor |
| Clear Command | Limpa o editor |
| Find Tables | Abre a Table Finder do schema selecionado |
| Save | Salva o conteúdo do editor (ou o trecho selecionado) com nome e descrição opcional; vai para Saved SQL |
| **Run** (Ctrl+Enter) | Executa o comando do editor ou **somente o trecho selecionado** |

Recursos do editor de texto: Undo (Ctrl+Z), Redo (Ctrl+Shift+Z), Find (Ctrl+F), botão Query Builder, Auto Complete (Ctrl+Space), menu de contexto (Change All Occurrences Ctrl+F2, Cut, Copy, Command Palette F1 com mais de 80 comandos, como Replace Ctrl+H), multicursor (Shift+Alt+clique; Ctrl+Alt+Up/Down) e menu Settings (indentação, tema Automatic/Light/Dark/High Contrast Dark, Show Ruler).

Abas do Display pane:
- **Results**: resultado do último comando executado com sucesso. O link **DBMS Output** aparece no rodapé quando há saída de `DBMS_OUTPUT`. **Download** exporta CSV.
- **Explain**: plano de execução do otimizador; os objetos têm links para o Object Browser.
- **Describe**: `describe nome_objeto` + Run mostra colunas de tabela/view ou a assinatura de função/procedure. Os links inserem `owner.tabela`, a coluna ou a chamada com parâmetros no editor.
- **Saved SQL**: comandos salvos no workspace.
- **History**: os **últimos 200 comandos executados** (salvos automaticamente, mesmo sem Save).

Fonte: [About the SQL Commands Home Page](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/sql-commands-home-page.html)

### SQL Commands: executar um comando e terminadores aceitos (Running a SQL Command, Terminating a Command)

1. SQL Workshop > SQL Commands.
2. Digite o comando e clique em **Run** (Ctrl+Enter). Para rodar só um comando entre vários no editor, **selecione o trecho** e clique em Run.
3. O resultado aparece em Results; **Download** gera `.csv`.

Terminadores válidos, segundo a doc: ponto e vírgula, barra em linha própria, ou nenhum terminador.

```sql
SELECT * from emp;
```
```sql
SELECT * from emp
/
```
```sql
SELECT * from emp
```

Pegadinha: a doc fala sempre em executar "o comando" (singular) ou o trecho destacado. Para vários comandos em sequência, use o SQL Scripts. Com vários comandos no editor, selecione um de cada vez.

Fonte: [Using the Command Editor](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/using-command-editor.html)

### SQL Commands: modo transacional, COMMIT/ROLLBACK e autocommit (About Transactions in SQL Commands)

- O **modo transacional** é stateful: dá para fazer um `UPDATE`, consultar o resultado e depois decidir entre `COMMIT` e `ROLLBACK`. A doc diz que ele é implementado com `DBMS_JOBS`.
- No modo transacional:
  - nada é gravado até um `COMMIT` explícito;
  - **sair do SQL Commands encerra e desfaz (rollback)** a transação atual;
  - **timeout de sessão também encerra e desfaz** a transação. O tempo vem da configuração de instância **SQL Commands Maximum Inactivity in minutes**, cujo **padrão é 60 minutos**;
  - a exportação **CSV não fica disponível**.
- O modo depende do atributo de instância **Enable Transactional SQL Commands** (Administration Services > Manage Instance > Feature Configuration > SQL Workshop). Quando ele está `Yes`, o SQL Commands passa a mostrar uma caixa **Autocommit**. Com Autocommit marcado, cada comando é confirmado por conta própria. Desmarcado, vale o modo transacional descrito acima.
- No Autonomous Database/OCI, quem altera esse atributo é o administrador da instância. O desenvolvedor só vê o efeito: a caixa Autocommit aparece ou não.

Quando usar o modo transacional: correções de dados em que você quer ver o efeito antes de confirmar. Quando evitar: operações longas (o timeout de inatividade desfaz tudo) ou quando você vai sair da página antes de confirmar.

Fonte: [Using the Command Editor](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/using-command-editor.html) · [Managing Feature Configuration](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-features.html)

### SQL Commands: bind variables (Using Bind Variables)

O SQL Commands **suporta** bind variables, que começam com dois-pontos. Na execução, ele pede o valor de cada uma:

```sql
SELECT * FROM emp WHERE deptno = :dept
```

Uso típico: testar a query de uma região que usa `:P1_ITEM`. O SQL Commands pede o valor de `:P1_ITEM`, e você informa um valor de teste. O valor digitado não vem do estado de sessão de nenhuma app. O **SQL Scripts não suporta bind variables**.

Fonte: [Using the Command Editor](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/using-command-editor.html) · [About SQL Scripts](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/sql-scripts.html)

### SQL Commands: resultados, DBMS Output e download CSV (Viewing Results)

- Results mostra a saída como **tabela HTML**, seguida do número de linhas retornadas e do tempo gasto.
- A saída de `DBMS_OUTPUT` aparece como **texto puro depois do resultado HTML**. O painel escolhe sozinho entre HTML e DBMS Output conforme o tipo de comando (SQL ou bloco PL/SQL com DBMS Output). O link **DBMS Output** só aparece quando há saída.
- O resultado do último comando fica disponível **até você executar outro comando ou sair do SQL Commands**.
- **Download** exporta CSV e **só vale para a saída HTML**. A saída do DBMS Output não é exportada.

```sql
begin
  dbms_output.put_line('linhas afetadas: ' || sql%rowcount);
end;
```

Fonte: [Viewing Results](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/viewing-results.html) · [About the SQL Commands Home Page](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/sql-commands-home-page.html)

### SQL Commands: Explain Plan (Using Explain Plan)

Explain analisa a query e mostra o plano escolhido pelo otimizador **sem executar o comando**. Serve para ver se os índices certos estão sendo usados e como as tabelas são juntadas. Para usar: digite ou carregue o comando e clique na aba **Explain**. O painel mostra o *Query Plan*, as *Index Columns* e as *Table Columns*. Clicar no nome de um objeto ou índice abre a definição no Object Browser.

Fonte: [Using Explain Plan](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/explain-plan.html)

### SQL Commands: salvar, copiar, Saved SQL e History (Saving an SQL Command, Using Saved Commands, Using SQL Command History)

- **Salvar**: Save > nome + descrição > Save. O comando vai para Saved SQL.
- **Copiar**: Saved SQL > clique no comando (ele carrega no editor) > Save com outro nome.
- **Saved SQL** lista todos os comandos salvos **no workspace**, inclusive os do Query Builder, com dono, nome, descrição, começo do SQL e última atualização. Dá para filtrar por Owner (ou `-All Users-`), procurar por nome ou trecho de código (Find), definir quantas linhas exibir e apagar (Delete Checked). Os comandos salvos ficam visíveis para os outros desenvolvedores do workspace: não salve SQL com dados sensíveis.
- **History** guarda os comandos executados **mesmo sem salvar** (os últimos 200), com horário, começo do comando e **schema** de execução. Clicar no SQL carrega o comando e volta para o schema em que ele rodou.

Fonte: [Saving an SQL Command](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/saving-sql-command.html) · [Copying a Command](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/copying-command.html) · [Using Saved Commands](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/saved-commands.html) · [Using SQL Command History](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/sql-command-history.html)

### SQL Commands: Find Tables (Table Finder)

**Find Tables** abre a Table Finder do schema selecionado. Ela permite buscar por nome (sem diferenciar maiúsculas), incluir views (caixa *Views*) e escolher o número de linhas. O relatório traz nome, número de linhas, data do último *analyze* e tipo. Ao abrir uma tabela, aparecem colunas, tipo, tamanho, precisão, escala e o **SQL que recria a tabela**. **Append** acrescenta esse SQL ao editor e **Replace** substitui o conteúdo do editor.

Fonte: [Using the Command Editor](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/using-command-editor.html)

### Erro ao usar SET ECHO, DEFINE ou outro comando SQL*Plus no SQL Commands

**Sintoma:** ao rodar `SET ECHO ON`, `DEFINE x = 1`, `SET SERVEROUTPUT ON` ou outro comando de SQL*Plus/SQL Command Line no SQL Commands, aparece uma mensagem de erro.
**Causa:** o SQL Commands **não suporta comandos SQL*Plus**. Ele só aceita SQL e PL/SQL.
**Correção:** remova os comandos SQL*Plus. Para ver saída de `DBMS_OUTPUT` não é preciso `SET SERVEROUTPUT`: o SQL Commands mostra a saída sozinho, no link DBMS Output. Para variáveis, use bind variables (`:nome`), que o SQL Commands pede na execução. Scripts que dependem de comandos SQL*Plus devem rodar no SQLcl.
**Prevenção:** antes de colar um script de instalação no SQL Commands, retire `set`, `define`, `prompt`, `spool` e `@arquivo`.

Fonte: [Using the Command Editor](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/using-command-editor.html)

### Alterações feitas no SQL Commands "sumiram" depois de sair da página ou de um tempo parado

**Sintoma:** um `UPDATE`/`INSERT` feito no SQL Commands não aparece para outros usuários, ou some depois que você sai da página ou fica um tempo sem usar.
**Causa:** o SQL Commands estava em **modo transacional** (Autocommit desmarcado, com *Enable Transactional SQL Commands* = Yes na instância). Nesse modo nada é confirmado sem `COMMIT`, e **sair do SQL Commands ou estourar o timeout de inatividade** (*SQL Commands Maximum Inactivity in minutes*, padrão 60) **faz rollback**.
**Correção:** execute `COMMIT` explicitamente antes de sair, ou marque **Autocommit**.
**Prevenção:** em correções de dados, rode o DML, confira com `SELECT`, faça `COMMIT` e só depois saia da página.

Fonte: [Using the Command Editor](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/using-command-editor.html) · [Managing Feature Configuration](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-features.html)

### Botão Download (CSV) não aparece no SQL Commands

**Sintoma:** depois de rodar uma query, não há opção de exportar CSV.
**Causa:** (a) em modo transacional a exportação CSV não fica disponível; (b) a saída é de DBMS Output, e o Download só existe para a saída HTML.
**Correção:** use Autocommit, ou rode a query no Query Builder (Results > Download) ou no Data Workshop > Unload Data. Para PL/SQL, transforme a saída numa query.

Fonte: [Using the Command Editor](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/using-command-editor.html) · [Viewing Results](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/viewing-results.html)

### SQL Commands mostra menos linhas do que a query retorna

**Sintoma:** a query retorna mais linhas do que as exibidas.
**Causa:** a lista **Rows** limita quantas linhas aparecem (máximo 100.000).
**Correção:** aumente Rows ou use `count(*)` para conferir o total. A saída de DBMS Output não é afetada por Rows.

Fonte: [About the SQL Commands Home Page](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/sql-commands-home-page.html)

## 8. SQL Scripts

### SQL Scripts: o que é e restrições (About SQL Scripts)

Um SQL script é um conjunto de comandos SQL e/ou blocos PL/SQL guardado como arquivo no **Script Repository** do workspace. Regras da doc:
- **Comandos SQLcl** (e SQL*Plus) no script são **ignorados na execução**. A página Run Script lista o que será ignorado.
- **Não há interação entre SQL Commands e SQL Scripts.**
- O SQL Scripts **não suporta bind variables**.
- Acesso: Workspace home > SQL Workshop > **SQL Scripts**. O Quick SQL também tem botão nessa página.

Quando usar: instalar DDL de um módulo arquivo por arquivo, criar packages com vários objetos, rodar scripts gerados pelo Quick SQL ou pelo AI e guardar histórico de execução com resultado por comando. Quando não usar: scripts que dependem de `@`/`@@`, `define`, `spool` ou `set` (são ignorados) e testes de query com `:binds`.

Fonte: [About SQL Scripts](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/sql-scripts.html) · [Using SQL Scripts](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/using-sql-scripts.html) · [Accessing SQL Scripts](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/accessing-sql-scripts.html)

### SQL Commands × SQL Scripts: comparação (segundo a documentação 26.1)

| Aspecto | SQL Commands | SQL Scripts |
|---|---|---|
| Unidade de trabalho | Um comando (ou o trecho selecionado) por Run | Script com um ou mais comandos/blocos, executado inteiro |
| Persistência do código | Saved SQL (opcional) + History automático (200 últimos) | Script Repository (cada script tem nome, dono, tamanho, nº de execuções) |
| Bind variables (`:x`) | Suportadas; pede o valor na execução | **Não suportadas** |
| Comandos SQL*Plus/SQLcl | **Não suportados**: dá erro | **Ignorados** na execução e listados na página Run Script |
| Transação | Autocommit ou modo transacional (`COMMIT`/`ROLLBACK` explícitos; sair ou timeout = rollback) | A doc não descreve modo transacional para scripts |
| Saída de `DBMS_OUTPUT` | Exibida como texto após o resultado, toda, sem limite de Rows | A doc **não menciona** exibição de `DBMS_OUTPUT` nos resultados |
| Resultado | Só do último comando; some ao rodar outro ou sair | Guardado em Manage Results (status, comandos executados, Detail/Summary) |
| Limite de linhas exibidas | Rows, até 100.000 | Não há limite de linhas; os limites são de bytes (quotas abaixo) |
| Limites de tamanho | — | *Maximum Script Size*, *Maximum Script Result Size*, *Quota for All Script Results*, definidos pelo admin da instância |
| Exportar | Download CSV (só saída HTML, fora do modo transacional) | Export de scripts para `workspace_name_script.sql`; Download do script |
| Explain/Describe | Sim (abas Explain e Describe) | Não |
| Criar app | Não | **Create App** (se o script cria tabelas já existentes no schema) |
| Escopo de visibilidade | Saved SQL: todo o workspace | Lista: scripts do usuário; o administrador do workspace vê os de todos |

Fonte: [About SQL Commands](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/sql-commands.html) · [About SQL Scripts](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/sql-scripts.html) · [Using the Command Editor](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/using-command-editor.html) · [Viewing Script and Result Quotas](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/viewing-script-and-result-quotas.html)

### SQL Scripts: página de scripts, visões e Tasks list (About the SQL Scripts Page, About the Tasks List)

- A página SQL Scripts é um **interactive report** com os scripts **do usuário atual**. Um **administrador do workspace** vê os scripts de todos os usuários. O report aceita filtros, destaques, ordenação, quebras, agregações, gráficos e computações.
- **View Icons** mostra um ícone por script. **View Report** mostra uma linha por script, com checkbox, nome, dono, última atualização (quem e quando), **tamanho em bytes**, **número de execuções** (com link para os resultados) e os ícones Copy e Run. Clicar no nome abre o Script Editor.
- **Delete Checked** apaga em lote (Reports view). **Upload** envia um arquivo local. **Create** abre o Script Editor vazio.
- **Tasks list** (à direita):
  - **Manage Results**: ver, procurar e exibir resultados;
  - **Show Quotas**: limites de tamanho;
  - **Export**: empacota vários scripts num único arquivo, por padrão `workspace_name_script.sql`;
  - **Import**: importa **somente** arquivos gerados pelo Export.

Fonte: [About the SQL Scripts Page](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/about-sql-scripts-page.html) · [About the Tasks List](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/about-tasks-list.html)

### SQL Scripts: criar no Script Editor ou fazer upload (Creating a SQL Script)

- **Script Editor**: SQL Scripts > **Create** > *Script Name* (a extensão é opcional) > digite SQL/PL/SQL > **Create**. Comandos SQLcl são ignorados na execução.
- **Upload**: SQL Scripts > **Upload** > *File*, *Script Name* (opcional, é o nome no repositório), **File Character Set** (a codificação do arquivo) > Upload.
- O script **só é analisado na execução**. Nesse momento, os comandos ignorados (SQLcl) são listados, e **SQL inválido só aparece nos resultados**. Se já existir um script com o mesmo nome, você precisa renomear.

Pegadinha de codificação: para arquivos com acentos (pt-BR), escolha o *File Character Set* certo (normalmente UTF-8) no upload. Senão, literais e comentários chegam corrompidos.

Fonte: [Creating a SQL Script](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/creating-sql-script.html)

### SQL Scripts: Script Editor e seus botões (Using the Script Editor)

O editor indenta cada linha nova na coluna da anterior e tem Undo, Redo, Find, Replace, Auto Complete, menu de contexto, Command Palette (F1), multicursor e Settings (indentação, tema, régua).

| Botão | Comportamento |
|---|---|
| Cancel | Sai sem salvar o que mudou desde o último save |
| Download | Baixa o script atual para o computador |
| Delete | Remove o script do repositório |
| Save | Salva o script. **Fica desabilitado se você mudou o Script Name**; nesse caso use **Apply Changes** |
| Create App | Abre o Create App Wizard com base nas tabelas. Só funciona com scripts que criam tabelas, e **o script precisa ter sido executado antes** |
| Run | Envia o script para execução |

Dá para testar o script durante a edição, rodando-o para ver os erros.

Fonte: [Using the Script Editor](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/using-script-editor.html)

### SQL Scripts: executar e a página Run Script (Executing a SQL Script)

- Pode-se executar pelo **Run** do Script Editor ou pelo ícone Run da Reports view.
- A página **Run Script** mostra nome, criação e última atualização (quem e quando), **número de comandos**, **tamanho em bytes** e a lista de **comandos desconhecidos/ignorados** (SQLcl/SQL*Plus) e dos **comandos com erro que impedem a execução**.
- Se o script não tem nenhum comando executável, o botão Run não aparece (no Reports view aparece um ícone de erro).
- **Run Now** envia o script. Em seguida aparece a página **Manage Script Results**, e **View Results** abre o resultado.
- Os status possíveis do resultado são **Complete**, **Canceled**, **Executing** e **Submitted**. O script vai para uma fila de execução: um status Submitted/Executing não quer dizer que terminou.
- Execuções longas podem ser acompanhadas em *Long Operations* (Database Monitor; exige DBA, ver §10).

Fonte: [Executing a SQL Script](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/executing-sql-script.html) · [Viewing SQL Script Results](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/viewing-sql-script-results.html)

### SQL Scripts: ver resultados (Manage Results, Detail e Summary)

Tasks list > **Manage Results** > ícone **View Results**. A página Results mostra o nome do script, o status e os comandos executados. Há duas visões (escolha e clique em Go):
- **Detail**: report com cada comando e o retorno dele;
- **Summary**: resumo, com seleção de linhas e ordenação por coluna.

Botões: **Edit Script** (volta ao editor) e **Create App** (abre o Create Application Wizard com base no script). Os resultados ocupam a quota de resultados do workspace: apague os antigos para liberar espaço.

Fonte: [Viewing SQL Script Results](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/viewing-sql-script-results.html)

### SQL Scripts: quotas de tamanho de script e de resultado (Viewing Script and Result Quotas)

Tasks list > **Show Quotas** abre a página *Script Quotas*:

| Limite | Significado | Quem define |
|---|---|---|
| Maximum Script Result Size | Tamanho máximo em bytes de **um** resultado | Admin da instância |
| Quota for All Script Results | Tamanho máximo em bytes de **todos** os resultados do workspace | Admin da instância |
| Used / Free / Quota | Bytes usados, livres e barra de uso | (informativo) |
| Maximum Script Size | Tamanho máximo em bytes de **um** script | Admin da instância |

No workspace esses valores só podem ser **consultados**, nunca alterados. Na instância eles correspondem aos atributos *SQL Scripts Maximum Script Output Size in bytes*, *SQL Scripts Maximum Workspace Output Size in bytes* e *SQL Scripts Maximum Script Size in bytes* (Feature Configuration > SQL Workshop). A doc 26.1 não informa valores padrão. No Autonomous Database, veja os valores reais em Show Quotas.

Fonte: [Viewing Script and Result Quotas](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/viewing-script-and-result-quotas.html) · [Managing Feature Configuration](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-features.html)

### SQL Scripts: copiar, apagar, exportar e importar entre workspaces

- **Copiar**: abra o script, mude o *Script Name* e clique em **Apply Changes** (o Save fica desabilitado quando o nome muda).
- **Apagar**: Reports view > marque > **Delete Checked** > OK. Ou, no editor, **Delete**. A remoção é **permanente**.
- **Exportar**: Tasks list > **Export**. Em *Scripts*, marque os scripts e clique em **Add to Export**. Em *Scripts to Export*, ajuste o *File Name* (padrão `workspace_name_script.sql`) e clique em **Export All**. Por padrão a lista mostra os scripts do usuário atual.
- **Importar**: entre no workspace de destino > Tasks list > **Import** > *Import file* + *File Character Set* > Next. A coluna **Action** diz se cada script é novo ou se **substitui um script de mesmo nome**. Confirme com **Import Script(s)**.

Fonte: [Copying a SQL Script](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/copying-sql-script.html) · [Deleting a SQL Script](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/deleting-sql-script.html) · [Exporting and Importing SQL Scripts](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/exporting-and-importing-sql-scripts.html)

### SQL Scripts: criar uma aplicação a partir de um script (Creating an Application from a Script)

Pré-requisito: as tabelas citadas no script já precisam existir no workspace. Rode o script ou carregue as tabelas antes. Passos: SQL Scripts > (Upload, se preciso) > ícone de lápis > **Create App** (ou Run e depois Create App) > confirme **Create Application**. O Create Application Wizard abre no App Builder já com as tabelas do script e gera páginas de report e de form para cada uma.

Fonte: [Creating an Application from a Script](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/creating-application-from-script.html) · [Creating an Application from a Generated SQL Script](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/creating-an-app-from-generated-sql-script.html)

### Comandos @, @@, SET, DEFINE, SPOOL ou PROMPT do script não fazem nada no SQL Scripts

**Sintoma:** um `instalar.sql` que chama outros arquivos com `@arquivo.sql`/`@@arquivo.sql`, ou que usa `set define off`, `prompt` ou `spool`, "roda", mas os arquivos chamados não são executados ou as configurações não valem.
**Causa:** o SQL Scripts **ignora comandos SQLcl/SQL*Plus**. A página Run Script lista esses comandos como desconhecidos/ignorados.
**Correção:** suba e execute **um arquivo por vez**, na ordem do instalador, ou rode o instalador no SQLcl.
**Prevenção:** antes do Run Now, leia a lista de comandos ignorados na página Run Script.

Fonte: [About SQL Scripts](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/sql-scripts.html) · [Executing a SQL Script](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/executing-sql-script.html)

### Script com :variavel falha ou não substitui o valor no SQL Scripts

**Sintoma:** um script com `:p_id` (ou `&var`) dá erro ou não pede valor.
**Causa:** o SQL Scripts **não suporta bind variables**, e `define`/substituição são comandos SQL*Plus, que ele ignora.
**Correção:** troque o bind por um literal ou por uma variável PL/SQL declarada num bloco anônimo. Para testar com binds, use o SQL Commands.

Fonte: [About SQL Scripts](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/sql-scripts.html) · [Using the Command Editor](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/using-command-editor.html)

### Script com erro de sintaxe "subiu" sem aviso no SQL Scripts

**Sintoma:** o upload ou o save não acusa erro, mas a execução falha.
**Causa:** o script **só é analisado na execução**. SQL inválido só aparece nos resultados.
**Correção:** depois do Run, abra **View Results** (visão Detail) e veja o erro de cada comando. Para PL/SQL compilado (packages, triggers), confira também os erros do objeto no Object Browser (aba **Errors**).
**Prevenção:** rode o script logo depois de criá-lo, para revelar os erros cedo.

Fonte: [Creating a SQL Script](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/creating-sql-script.html) · [Using the Script Editor](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/using-script-editor.html) · [Managing Packages](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/managing-packages.html)

### Upload ou execução de script recusado por tamanho, ou quota de resultados cheia

**Sintoma:** não é possível subir ou rodar um script grande, ou os resultados deixam de ser gravados.
**Causa:** o script passou de *Maximum Script Size*, o resultado passou de *Maximum Script Result Size* ou o workspace atingiu a *Quota for All Script Results*.
**Correção:** confira em **Show Quotas**; apague resultados antigos em **Manage Results**; divida o script em arquivos menores. Para aumentar os limites, peça ao administrador da instância (no workspace eles não podem ser alterados).

Fonte: [Viewing Script and Result Quotas](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/viewing-script-and-result-quotas.html)

### Botão Run não aparece, ou ícone de erro no lugar do Run, no SQL Scripts

**Sintoma:** o script não tem o botão Run, ou mostra um ícone de erro na Reports view.
**Causa:** o script **não tem nenhum comando executável**, por exemplo porque só tem comentários e comandos SQLcl.
**Correção:** inclua comandos SQL/PL/SQL válidos. Blocos PL/SQL e `create or replace` de PL/SQL devem terminar com `/` em linha própria.

Fonte: [Executing a SQL Script](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/executing-sql-script.html)

### Create App do Script Editor não funciona ou não traz tabelas

**Sintoma:** **Create App** não aparece, falha ou abre sem tabelas.
**Causa:** o botão só funciona com scripts que criam tabelas, e as tabelas **precisam existir**, ou seja, o script precisa ter sido executado.
**Correção:** rode o script (Run Now), confira o resultado e só depois clique em Create App.

Fonte: [Using the Script Editor](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/using-script-editor.html) · [Creating an Application from a Script](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/creating-application-from-script.html)

## 9. Object Browser

### Object Browser: o que é, Object Tree e Object Detail View (Understanding Object Browser)

O Object Browser permite navegar, criar e editar objetos do banco nos schemas do workspace. Acesso: SQL Workshop > **Object Browser**.
- **Object Tree** (à esquerda): objetos do tipo escolhido **no schema atual**. A lista **Schema** troca o schema. O filtro acima da árvore **persiste durante a sessão APEX**. O botão Left Splitter esconde ou mostra a árvore.
- **Object Detail View** (à direita): abas específicas de cada tipo, cada uma com as suas ações.
- No primeiro acesso aparece um **cards region** com um card por tipo de objeto, cada um abrindo o assistente de criação. Depois ele some; para trazê-lo de volta, clique num tipo de objeto na árvore.
- Menu de contexto de um tipo na árvore: Create, Refresh, Expand All, Collapse All.
- **Objetos inválidos aparecem em vermelho** na árvore, com a marca *Invalid* na visão de detalhe.
- O Object Browser **lembra o último objeto visto** e a posição da linha.
- Os diálogos de alteração (por exemplo, adicionar coluna) **mostram o SQL gerado**, que pode ser copiado.

Fonte: [Accessing Object Browser](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/accessing-object-browser.html) · [Understanding Object Browser](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/understanding-object-browser.html) · [Managing Database Objects with Object Browser](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/managing-db-objects-with-object-browser.html)

### Object Browser: Code Editor (DDL, Code, Specification/Body)

Várias abas (DDL, Code, Specification, Body) usam o Code Editor completo: Undo/Redo, Find, Auto Complete (Ctrl+Space), Change All Occurrences (Ctrl+F2), Command Palette (F1, mais de 80 comandos, como Replace Ctrl+H) e Settings (indentação, tema, **Minimap** On/Off/"Only when >100 lines", Accessibility Mode, números de linha, régua, sugestões, espaços em branco, Bracket Pair Colorization). Se o workspace tiver Generative AI configurado, os Code Editors trazem o chat **APEX Assistant**.

Fonte: [Understanding Object Browser](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/understanding-object-browser.html)

### Object Browser: criar objetos e a conversão de nomes para maiúsculas (Creating Database Objects)

Há três caminhos para criar: o menu **Create Database Objects (+)**, o clique direito num nó da árvore ou o card da página inicial. Todos abrem o diálogo Create do tipo. **O APEX converte o nome do objeto para maiúsculas e troca espaços por underscore.** Para nomes em caixa mista, crie o objeto à mão no SQL Commands. Os nomes seguem as regras da Oracle: sem espaços e sem começar por número ou underscore.

Fonte: [Understanding Object Browser](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/understanding-object-browser.html)

### Object Browser: criar tabela (Create Table Wizard)

Campos: **Table Name**, **Semantics** (Default/BYTE/CHAR para colunas texto), **Comments**. Na grade **Columns**: Add Column, Move Up/Down (Alt+Up/Down), Delete Column e o modo Edit (um clique para editar). Atributos de cada coluna:
- **Column Name**, **Data Type**;
- **Precision**: só para `NUMBER`, `FLOAT`, `INTERVAL YEAR TO MONTH` e `INTERVAL DAY TO SECOND`; precisão 4 em `NUMBER` aceita de 0 a 9999;
- **Scale**: casas decimais em `NUMBER`; número de caracteres em `VARCHAR2`/`CHAR`; fração de segundos (0 a 9) em `TIMESTAMP`;
- **Not Null**, **Primary Key**. Se **só uma** coluna for PK e o tipo for `NUMBER` ou `FLOAT`, ela é criada como **identity column**;
- **Default Expression**: expressão SQL válida, **sem funções customizadas**;
- **Comment**.

**Preview SQL** mostra o DDL antes do **Create Table**.

Fonte: [Managing Tables](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/managing-tables.html)

### Object Browser: abas e ações de uma tabela (Viewing a Table)

| Aba | Conteúdo e ações |
|---|---|
| Columns | Nome, tipo, nullable, default, PK, comentário, identity. Add/Modify/Rename/Drop Column, Refresh. **More**: Rename Table, Copy Table, Drop Table, Truncate Table, Table Comment, Create Lookup Table, Create App, UI Defaults |
| Data | Insert Row, Columns, Filter, Count Rows, Load Data, Download (XLSX), Refresh; edição linha a linha (Edit Row > Save/Delete) |
| Indexes | Create, Drop, Refresh |
| Constraints | Create, Drop, Enable, Disable, Refresh |
| Grants | Grant, Revoke, Refresh |
| Statistics | Estatísticas de tabela e colunas; Gather Statistics, Refresh |
| Triggers | Lista e link para a trigger; Create, Drop, Enable, Disable |
| Dependencies | Objetos que dependem da tabela e de que ela depende |
| DDL | DDL completo (chaves, índices, triggers, comentários); Download |
| Sample Queries | Queries de exemplo com Copy e Run |

Detalhes úteis:
- **Count Rows** conta **sempre o total** da tabela; os filtros aplicados não mudam a contagem.
- **Modify Column** pode mostrar a região *Data Redaction* se o schema tiver `EXECUTE` em `DBMS_REDACT`.
- **Gather Statistics** usa `DBMS_STATS` **em segundo plano**. Enquanto roda, *Last Analyzed* mostra "Gather statistics in progress...". Clique em Refresh depois. **Refresh** só relê `USER_TABLES`/`USER_TAB_COLUMNS`.
- **Drop Table**: a opção *Cascade Constraints* remove as FKs que apontam para a tabela. Sem ela, se houver FKs, o banco devolve erro e cancela. O SQL gerado aparece e pode ser copiado.

Fonte: [Managing Tables](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/managing-tables.html)

### Object Browser: criar app a partir de uma tabela (Create App no More menu)

Columns > **More** > **Create App**. O APEX analisa a tabela com `DBMS_STATS` e propõe: página de gráfico (se houver recomendação), calendário (se houver coluna de data/timestamp), interactive report + form, dashboard com gráficos (com links para o IR) e faceted search (se houver facetas válidas).

Fonte: [Managing Tables](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/managing-tables.html)

### Create App Wizard dá erro depois de alterar a estrutura da tabela

**Sintoma:** depois de renomear colunas ou mudar a estrutura de uma tabela, o Create Application Wizard (aberto pelo Object Browser) gera erro.
**Causa:** o **Data Dictionary Cache** do APEX ficou desatualizado em relação à tabela.
**Correção:** atualize o Data Dictionary Cache (Administration Services, ou o atalho *Navigating to Data Dictionary Cache* em SQL Workshop Utilities) e rode o assistente de novo.

Fonte: [Managing Tables](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/managing-tables.html) · [Navigating to Data Dictionary Cache](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/Navigating-Data-Dictionary-Cache.html)

### Object Browser: views (criar, editar, compilar)

Uma view não guarda dados: ela deriva das tabelas-base, e operações nela afetam essas tabelas. Para ser atualizável, não pode ter construções como `DISTINCT`, operadores de conjunto, funções de agregação ou analíticas, entre outras. Para criar: **View Name** + **SQL Query** (Code Editor com Query Builder) > *Preview SQL* ou **Create View**. **Ao editar, é preciso compilar** (Save and Compile) para gravar. As abas de view seguem o padrão: colunas, dados, grants, dependências, DDL e erros.

Fonte: [Managing Views](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/managing-views.html)

### Object Browser: packages, procedures e functions (Save and Compile, Errors)

- **Package**: aba **Specification** (interface, o que pode ser referenciado de fora) e aba **Body** (implementação), as duas com Code Editor e as ações Download, **Save and Compile**, Drop, Refresh. Também há **Dependencies**, **Errors** e **Grants**. Para criar: Name + *Include Sample Code*.
- **Procedure/Function**: abas **Code** (Download, Save and Compile, Drop, Refresh), **Dependencies**, **Errors** e **Grants**.
- **Compilar recria o objeto no banco.** Se falhar, a mensagem de erro aparece acima do código. Corrija e compile de novo.
- **Download** salva em `.sql`.
- O **Drop** pela aba Body remove o package body; pela aba Specification, remove o package. O diálogo mostra o SQL gerado.
- A edição de PL/SQL pelo Object Browser pode estar **desabilitada**: na instância (*Allow PL/SQL Program Unit Editing* = No) ou no workspace (*Set Workspace Preferences* > *SQL Workshop, PL/SQL Editing*).

Fonte: [Managing Packages](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/managing-packages.html) · [Managing Procedures](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/managing-procedures.html) · [Managing Functions](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/managing-functions.html) · [Managing Feature Configuration](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-features.html) · [Configuring Workspace Preferences](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-workspace-preferences.html)

### Não consigo editar ou compilar package/procedure no Object Browser

**Sintoma:** o código do package aparece só para leitura, ou não há Save and Compile.
**Causa:** a edição de unidades PL/SQL foi desligada na instância (*Allow PL/SQL Program Unit Editing* = No, em Feature Configuration) ou no workspace (*Do not allow PL/SQL program unit editing*, em Set Workspace Preferences).
**Correção:** peça ao administrador do workspace/instância para reativar, ou recrie o objeto via SQL Scripts/SQL Commands com `create or replace`.

Fonte: [Managing Feature Configuration](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-features.html) · [Configuring Workspace Preferences](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-workspace-preferences.html)

### Object Browser: triggers (criar, compilar, habilitar/desabilitar)

Para criar: escolha a **Table**; o **Trigger Name** é sugerido a partir da tabela; **Firing Point** é *Before* ou *After*. Abas: **Code** (Download, Save and Compile, Drop), **Errors**, **Object Details** (Compile, Drop, **Enable**, **Disable**; o *Trigger Status* mostra `ENABLED`/`DISABLED`) e **DDL**. A compilação pode ser feita no Code (Save and Compile) ou no Object Details (Compile).

Fonte: [Managing Triggers](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/managing-triggers.html)

### Object Browser: índices, sequences, types, synonyms, database links, materialized views e SODA

- **Índices**: tipos **Normal** (`NUMBER`/`VARCHAR`), **Text** (`CLOB`) e **Spatial** (`SDO_GEOMETRY`); *Unique* ou não. Um índice Normal aceita **até 4 colunas**; Text e Spatial aceitam **uma só**.
- **Sequences**: Start With, Increment By (≠ 0), *Number to Cache* (inteiro > 1), Minimum/Maximum Value e Cycle (desligado por padrão).
- **Types**: o APEX **só suporta definições de coleção**: `VARRAY` (com *Limit*) e nested `TABLE`.
- **Synonyms**: criar, ver e remover alias de objetos.
- **Database Links**: nome, *Connect To Schema* (**diferencia maiúsculas**), senha, host/IP, porta (normalmente 1521), *Service Name* ou *SID*. A visão de detalhe tem a ação **Test**. Uso: `tabela@dblink`.
- **Materialized Views**: só ver e remover. Abas: Columns, Data, Details (`DBA_SNAPSHOTS`), Grants, Dependencies, DDL.
- **SODA Collections**: exigem Database 18.3+ e o papel **`SODA_APP`** para o usuário. Aceitam arquivos JSON (array), JSON list (um documento por linha, **até 32.767 bytes por linha**) e ZIP. *JSON Selector Type*: Auto-Detect, Custom ou Linefeed. Carga em coleção nova ou existente (append ou replace).

Fonte: [Managing Indexes](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/managing-indexes.html) · [Managing Sequences](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/managing-sequences.html) · [Managing Types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/managing-types.html) · [Managing Synonyms](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/managing-synonyms.html) · [Managing Database Links](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/managing-db-links.html) · [Managing Materialized Views](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/managing-materialized-views.html) · [Managing SODA Collections](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/managing-soda-collections.html)

### Objeto aparece em vermelho (Invalid) no Object Browser

**Sintoma:** um package, view ou trigger aparece em vermelho na árvore, com a marca *Invalid*.
**Causa:** o objeto está inválido: erro de compilação ou dependência alterada.
**Correção:** abra o objeto, veja a aba **Errors**, corrija e use **Save and Compile** (ou Compile, em triggers). Para uma visão geral, use *Object Reports > Invalid Objects* (§10).

Fonte: [Understanding Object Browser](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/understanding-object-browser.html) · [Viewing Object Reports](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/viewing-object-reports.html)

## 10. SQL Workshop Utilities (Data Workshop, Quick SQL, Query Builder, Data Generator, comparação de schemas e outros)

### SQL Workshop Utilities: visão geral das ferramentas

SQL Workshop > **Utilities** reúne: Data Workshop, Data Generator, Query Builder, Quick SQL, Sample Datasets, Generate DDL, Describe Tables, UI Defaults, Schema Comparison, atalho para o Data Dictionary Cache, Methods on Tables, Recycle Bin, Object Reports, Create Data Model Using AI, About Database e Database Monitor.

Fonte: [Using SQL Workshop Utilities](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/using-sql-workshop-utilities.html)

### Data Workshop: Load Data e Unload Data (recursos e limites)

Acesso: Utilities > **Data Workshop** > **Load Data** / **Unload Data**.
- Carga por arrastar e soltar **CSV, TXT (tab), XLSX, JSON e XML**, colando CSV/tab ou usando um *sample data set*. O parser detecta tipos, máscaras e separador decimal sozinho.
- A carga **roda em segundo plano**: dá para fechar o diálogo. Linhas com erro vão para uma **tabela de erros**, sem perder a carga inteira. Se não houver erro, a tabela de erros é **removida automaticamente**. Depois da carga aparecem até 10 linhas rejeitadas, e *Open in Object Browser* mostra o resto. *Drop Table and Reload* tenta de novo.
- PK: **Identity Column** (compacta e previsível) ou **SYS_GUID** (única e imprevisível, ocupa mais espaço).
- *Use Column Data Types*: se desmarcado, as colunas são criadas como `VARCHAR2(4000)`.
- O preview principal mostra até 10 colunas × 5 linhas. **Configure** mostra até 100 × 100 e define *Rows to Sample*, as colunas a carregar e os valores tratados como `NULL` (por exemplo `"n/a"`, `"-"`).
- Os nomes de tabela são **convertidos para maiúsculas**.
- Restrições: carrega/descarrega **só dados de tabela**, **uma tabela por vez**, e **só do schema do próprio usuário**, mesmo para administradores. Não há filtro de dados no upload.
- Limites por formato: **XML até 10 MB** (só estrutura plana); **XLSX até 20 MB** (primeira planilha por padrão, *Select Sheet* para outra); **JSON** só plano (sem limite em DB 12.2+; 20 MB em 11g/12.1). Arquivo ≥ 2.097.152 bytes com *sample All Rows* pede confirmação. O limite geral vem de *Maximum File size for Data Loading* (instância), e os jobs usam a *Data Loading Job Class* (padrão `SYS.DEFAULT_JOB_CLASS`).
- **Unload**: texto (separador, *Optionally Enclosed By*, nomes de coluna, fim de linha DOS/UNIX, character set, cláusula `WHERE`) ou XML canônico. **`BLOB` e `BFILE` não são suportados** no unload texto.

Fonte: [About the Load Data and Unload Data Wizards](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/about-the-load-data-and-unload-data-wizards.html) · [Loading Data](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/loading-data.html) · [Unloading Data](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/unloading-data.html) · [Accessing the Load Data and Unload Data Wizards](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/accessing-load-data-and-unload-data-wizards.html) · [Managing Feature Configuration](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-features.html)

### Data Workshop × SQL*Loader × Data Pump: qual usar (Import, Export, Load, and Unload Options)

| Cenário | Opção recomendada |
|---|---|
| Menos de 10 tabelas, dados em planilha/CSV/TSV, sem tipos complexos | Load/Unload Data do APEX |
| Registros de largura fixa, sem delimitador | SQL*Loader |
| Texto tabulado com mais de 10 tabelas | SQL*Loader |
| Carregar só registros que atendem a um critério | SQL*Loader |
| Mover um schema inteiro entre bancos Oracle | Data Pump (`expdp`/`impdp`) |
| Dados com XMLType, sem `FLOAT`/`DOUBLE` | `exp`/`imp` (Data Pump é preferível) |

Vocabulário: *export/import* = formato binário proprietário, só entre bancos Oracle; *unload/load* = texto padrão (CSV, TSV) legível por outras ferramentas.

Fonte: [Import, Export, Load, and Unload Options](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/import-export-load-and-unload-options.html) · [About Importing, Exporting, Loading, and Unloading Data](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/about-importing-exporting-loading-unloading-data.html)

### Data Workshop: Load from Cloud no Autonomous Database (Object Store References, DBMS_CLOUD)

Só existe para usuários do **Autonomous Database**: aparece um botão extra, **Load from Cloud**.
- Pré-requisito (rodar como `ADMIN`):
  ```sql
  GRANT EXECUTE ON DBMS_CLOUD TO <schema_do_workspace>;
  GRANT READ, WRITE ON DIRECTORY DATA_PUMP_DIR TO <schema_do_workspace>;
  ```
- Uma **Object Store Reference** guarda a URL do bucket (sem o nome do arquivo) e a credencial: *Username/Password* (na AWS: Access Key ID/Secret), *OCI Native* (User OCID, Private Key, Tenancy OCID, Fingerprint), *Web Credential* existente ou *DBMS_CLOUD Credential*. *Create a Web Credential* torna a credencial reutilizável.
- **External table**: escolha os arquivos (vários, separados por vírgula), *File Type* (Avro, Parquet ou Other), *Derive Data Definition* (First File ou All Files) e o nome. O APEX usa `DBMS_CLOUD.CREATE_EXTERNAL_TABLE`.
- Avro/Parquet → *Review External Table* → carga local (New/Existing Table, *Commit Interval*, *Monitor Progress*, *Drop External Table after Load*).
- Outros formatos: **até 50 MB**, via *Import* → diálogo Load Data.

Fonte: [Loading Data From the Oracle Cloud (Autonomous Database Only)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/loading-data-from-cloud.html)

### Load from Cloud falha por falta de privilégio no Autonomous Database

**Sintoma:** ao usar *Load from Cloud*, a criação da external table ou o acesso ao bucket falha.
**Causa:** o schema do workspace não tem `EXECUTE ON DBMS_CLOUD` e/ou `READ, WRITE ON DIRECTORY DATA_PUMP_DIR`, ou a credencial da Object Store Reference está errada.
**Correção:** como `ADMIN`, conceda os dois privilégios ao schema do workspace. Revise a URL (sem nome de arquivo) e o tipo de credencial.

Fonte: [Loading Data From the Oracle Cloud (Autonomous Database Only)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/loading-data-from-cloud.html)

### Carga de dados termina com linhas rejeitadas (tabela de erros) no Data Workshop

**Sintoma:** a carga conclui, mas aparecem linhas rejeitadas e uma tabela de erros fica no schema.
**Causa:** linhas que não couberam no tipo ou violaram constraint. Elas vão para a *Error Table*, que só é removida sozinha quando não há erro.
**Correção:** veja até 10 linhas no diálogo, ou todas via *Open in Object Browser*. Ajuste tipos e valores nulos no **Configure** (por exemplo, *Use Column Data Types* desligado → `VARCHAR2(4000)`) e use **Drop Table and Reload**. Remova a tabela de erros depois.

Fonte: [Loading Data](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/loading-data.html)

### Quick SQL: o que é, requisitos e regras da sintaxe abreviada

O Quick SQL gera o SQL de um modelo relacional (tabelas, triggers, índices, views, dados de exemplo e APIs) a partir de **texto indentado**. Ele não substitui a modelagem de dados: é um ponto de partida. **Exige ORDS 23.3.0 ou superior.** Acesso: Utilities > Quick SQL, ou o botão no SQL Scripts.

Regras:
- tabelas-pai sem indentação;
- colunas com indentação uniforme de **2 ou mais espaços**;
- tabelas-filhas indentadas no nível das colunas do pai, o que gera a FK;
- **não declare a PK**: ela é gerada.

```text
departments /insert 4
   name /nn
   location
   country
   employees /insert 14
      name /nn vc50
      email /lower
      cost center num
      date hired
      job vc255
view emp_v departments employees
```

Diretivas vistas nos exemplos da doc: `/insert N` (dados aleatórios), `/nn` (NOT NULL), `/lower`, `/check`, `/values`, `/api` (gera package de API da tabela), tipos abreviados `vc50`, `vc255`, `num`, e comentário de coluna entre colchetes. A **Help** (abas About, Data Types, Table Directives, Column Directives, Views, Settings, Samples) é a referência completa.

Tipos suportados: `NUMBER`, `INTEGER`, `DATE`, `TIMESTAMP`, `TIMESTAMP WITH LOCAL TIME ZONE`, `VARCHAR2(4000)`, `VARCHAR2(n)` (1 a 32767), `VARCHAR2(32767)`, `CLOB`, `BLOB`, `CLOB CHECK (col IS JSON)`.

Fonte: [Getting Started with Quick SQL](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/getting-started-with-quick-sql.html) · [Using Quick SQL](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/using-quick-sql.html) · [Accessing Quick SQL Help](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/accessing-quick-sql-help.html) · [About Supported Data Types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/about-supported-data-types.html) · [Loading Quick SQL Sample Models](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/loading-quick-sql-sample-models.html)

### Quick SQL: página, modelos, diagrama e envio para SQL Scripts

- Painel esquerdo: Help, **Settings** e menu de ações (Load, Save Model, Save Model As, Reset, Properties).
- Painel direito: abas **SQL** e **Diagram** (ER), botão **Review and Run** (leva ao SQL Scripts) e menu com *Save SQL Script* e *Download*.
- **Modelos**: *Save Model*/*Update Model* (nome + descrição); *Load* com as abas Samples, **My Models** e **Workspace Models** (modelos de todos os desenvolvedores do workspace). Para editar nome e descrição ou apagar, clique no nome do modelo.
- Amostras: Departments and Employees, Employee Skills, Product Sales (star schema), Project Management e ToDos.
- Depois de rodar o script salvo, o **Create App** gera páginas de report e de form para as tabelas.

Fonte: [About the Quick SQL Page](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/about-the-quick-sql-page.html) · [Managing Quick SQL Models and Scripts](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/managing-quick-sql-models-and-scripts.html) · [Generating SQL with SQL Shorthand Syntax](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/generating-quick-sql-with-sql-shorthand-syntax.html)

### Quick SQL: Settings (prefixo, PK, auditoria, APEX Enabled, API, drops)

Settings declarativos:

| Grupo | Opções |
|---|---|
| Table | *Object Prefix* (com underscore), *Schema* (prefixo de schema; padrão nenhum), *Compression*, *Generate Inserts* (desligar acelera o refinamento) |
| Primary Key | *Add Primary Key* (coluna ID); *Population Method*: **SYS_GUID**, **Identity Column**, **Sequence** (via trigger) ou **None**; *Prefix primary keys with table name* (ex.: `EMPLOYEE_ID`) |
| Column | *Date Data Type* (Date, Timestamp, Timestamp with time zone, Timestamp with local time zone); *Semantics* (Default, CHAR, BYTE) |
| Additional Columns | Audit Columns, Row Version Number, Row Key |
| Options | *PL/SQL API* (On = package por tabela; Off = só tabelas com `/api`); *Include Drops* (`drop table X including contents;`); *Editionable*; **APEX Enabled**; *Compatibility* (versão do banco) |
| Audit Columns | Nomes das colunas created, created_by, updated e updated_by |

Com **APEX Enabled**, as triggers de auditoria usam `coalesce(sys_context('APEX$SESSION','APP_USER'),user)`. Sem ele, usam `user`. Settings inline (no fim do script, para preservar a configuração ao colar de volta):

```text
# settings = { prefix: "test", schema: "OBE" }
# prefix: "test"
# schema: "OBE"
# verbose: true
```

As regras inline: cada setting começa em linha nova; os valores não diferenciam maiúsculas; colchetes, espaços e vírgulas são ignorados.

Fonte: [Configuring Quick SQL Settings](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/configuring-quick-sql-settings.html)

### Quick SQL: recomendações de modelagem (Recommendations When Using Quick SQL)

Tabelas no plural e colunas no singular; toda tabela com PK numérica chamada `ID`; NOT NULL e UNIQUE declarados no banco; integridade referencial declarada com PK/FK. Para modelagem séria, a doc recomenda o Oracle SQL Data Modeler.

Fonte: [Recommendations When Using Quick SQL](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/recommendations-when-using-quick-sql.html) · [Database Terminology Used in Quick SQL](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/database-terminology-used-in-quick-sql.html)

### Create Data Model Using AI (SQL Workshop)

Gera um script a partir de linguagem natural usando o **Generative AI Service** do workspace. A opção exige um serviço configurado e com **Used by App Builder** habilitado; sem isso, ela fica oculta. Formato: **Oracle SQL** (vai para o Script Editor via *Create SQL Script*) ou **Quick SQL** (vai para o Quick SQL via *Review Quick SQL*). A escolha fica salva como preferência do usuário. Acesso: Utilities > Create Data Model Using AI, ou pela Tasks list do SQL Workshop.

Fonte: [Creating a Data Model Using AI](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/creating-data-model-ai.html)

### Query Builder: montar queries graficamente

Acesso: Utilities > Query Builder, ou o botão Query Builder nos code editors de atributos SQL. Painéis: **Object Selection** (tabelas, views e MVs **do schema atual**, com busca sem diferenciar maiúsculas), **Design** e **Output** (abas Conditions, SQL, Results, Saved SQL).
- Fluxo: escolher objetos > marcar colunas > (joins) > (condições) > Run (Ctrl+Enter).
- **Limite: 60 colunas por query.** Não são selecionáveis: `BLOB`, `NCLOB`, `RAW`, `LONG`, `LONG RAW`, `XMLType` e outros tipos não escalares.
- *Check All* marca as **20 primeiras colunas**.
- **Conditions**: Alias; Condition com operador + operando (`>=10`, `='VA'`, `IN (SELECT ...)`, `BETWEEN SYSDATE AND SYSDATE + 15`); Sort Type/Order; **Show** (desmarque para filtrar sem exibir); Function (agregações para NUMBER; `INITCAP`/`UPPER`/`TRIM` etc. para texto; `TO_CHAR` por ano, trimestre, mês etc. para datas); Group By.
- **Joins**: inner, outer, left e right. Manual (coluna Join, ou arrastar uma coluna sobre a outra) ou automático (*Add Parent*/*Add Child* pelas FKs).
- **SQL**: visão só leitura e formatada, para copiar. **Results**: Download CSV.
- **Saved SQL**: os nomes não podem se repetir. Salvar com o mesmo nome **sobrescreve**; com outro nome, cria uma cópia. As queries salvas aparecem também no SQL Commands.

Fonte: [Using Query Builder](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/using-query-builder.html) · [Using the Design Pane](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/using-the-design-pane.html) · [Specifying Query Conditions](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/specifying-query-conditions.html) · [Creating Relationships Between Objects](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/creating-relationships-between-objects.html) · [Working with Saved Queries](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/working-with-saved-queries.html) · [Viewing Query Results](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/viewing-query-results.html)

### Coluna não aparece ou não pode ser marcada no Query Builder

**Sintoma:** não dá para marcar uma coluna, ou a query para de aceitar novas colunas.
**Causa:** a coluna é de tipo não suportado (`BLOB`, `NCLOB`, `RAW`, `LONG`, `LONG RAW`, `XMLType` ou outro não escalar) ou a query já tem **60 colunas**.
**Correção:** escreva a query à mão no SQL Commands, ou divida a consulta.

Fonte: [Using the Design Pane](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/using-the-design-pane.html)

### Data Generator: blueprints JSON e geração de dados de teste

- Um **blueprint** é um JSON que define tabelas, colunas (cada uma com um *Data Source type*) e *custom data sources*. Formas de criar: **Use Existing Tables** (*Select from list* ou *Copy and Paste* no formato `PRODUCTS:10,CUSTOMERS:50,SALES:1000`; *Rows* padrão `50`; *Excluded Columns* `col1,col2`), **From Scratch** (com *Add Starter Table*) ou **Import JSON File** (upload ou colar; *Override Name* exige o switch *Replace*).
- **Blueprint Designer**: árvore à esquerda, atributos no centro. Menu de contexto Add/Delete Table e Add/Delete Column. **Não salva sozinho**: clique em Save. *Generate* também salva.
- O home mostra só os blueprints do **Data Generation Schema** selecionado.
- **Preview Data** mostra poucas linhas (*Table List*, *Preview Size*).
- **Generate Data**:
  - **File Export**: JSON, CSV (um arquivo, ou ZIP com um CSV por tabela) ou SQL de inserts; *Row Scaling* (padrão 1x; ex.: .25x, 100x);
  - **Insert Into Database**: *Insert Method* **Insert Into** (linha a linha; descarta as que falham) ou **Fast Insert Into** (tudo de uma vez; se falhar, a tabela fica sem nenhum registro).
- **Export** baixa o JSON do blueprint. **Delete** fica no ícone de chave inglesa.

Fonte: [Using Data Generator](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/using-data-generator.html) · [About JSON Blueprints](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/about-blueprints.html) · [Creating JSON Blueprints](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/creating-blueprints.html) · [Running JSON Blueprints](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/running-blueprints.html) · [Modifying JSON Blueprints](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/modifying-blueprints.html) · [Previewing JSON Blueprints](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/previewing-blueprints.html) · [Exporting JSON Blueprints](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/exporting-blueprints.html) · [Deleting JSON Blueprints](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/deleting-blueprints.html)

### Data Generator: Insert Into Database sobrescreve dados ou falha por constraint

**Sintoma:** depois de *Insert Into Database*, os dados que já estavam na tabela somem, ou os inserts falham.
**Causa:** a opção **sobrescreve os dados existentes**. Além disso, o Data Generator **não considera as constraints** da tabela, e triggers também podem barrar os inserts.
**Correção:** nunca use em tabelas com dados reais. Ajuste os *data sources* das colunas para respeitar PK, FK, CHECK e NOT NULL. Prefira *File Export* (SQL) para revisar antes. Com *Fast Insert Into*, um erro deixa a tabela sem nenhum registro; com *Insert Into*, só a linha com erro é descartada.
**Prevenção:** gere dados num schema ou ambiente de teste.

Fonte: [Running JSON Blueprints](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/running-blueprints.html) · [About JSON Blueprints](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/about-blueprints.html)

### Comparar schemas (Schema Comparison)

Utilities > **Schema Comparison**. Escolha **Schema 1** e **Schema 2**, que precisam estar **disponíveis no workspace**, o tipo de objeto (ou All), um filtro por nome (sem diferenciar maiúsculas, ex.: `DEMO_`) e o número de linhas. Depois, *Show Differences Only* ou *Show Details*. O relatório diz se cada objeto existe nos dois schemas e mostra diferenças de detalhe, como um índice com uma coluna a mais ou uma coluna de tipo diferente. Serve para comparar ambientes DEV × PROD **quando os dois schemas estão no mesmo workspace**.

Fonte: [Comparing Schemas](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/comparing-schemas.html)

### Generate DDL e Describe Tables (descrição de tabelas para IA)

- **Generate DDL**: Create Script > schema > *Output* (**Display Inline** ou **Save As Script File**, que vai para SQL Scripts) > tipos de objeto (*Check All*) > (objetos específicos) > Generate DDL. O DDL vem do dicionário de dados e serve para recriar o schema.
- **Describe Tables**: gera a descrição de tabelas e views em formato legível por LLM (**Markdown** ou **Plain Text**), com opções de incluir constraints, índices e comentários. Tem Copy e Download. A doc indica o uso do arquivo como prompt de IA que documenta as tabelas.

Fonte: [Generating DDL](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/generating-ddl.html) · [Describing Tables](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/describing-tables.html)

### UI Defaults: Table Dictionary e Attribute Dictionary

UI Defaults dão rótulos, ajuda e propriedades iniciais para forms e reports criados por assistentes, e também ajudam a IA a entender as tabelas.
- **Table Dictionary** (por tabela e coluna do schema) **tem prioridade** sobre o **Attribute Dictionary**, que vale por nome de coluna e aceita sinônimos.
- *Create Defaults* gera os defaults a partir do dicionário do banco. A sincronização cria defaults para as tabelas que não têm e atualiza as que têm.
- Remover uma coluna do Table Dictionary faz o assistente usar o Attribute Dictionary, por exemplo para padronizar `CREATED_BY`.
- Exportação: todos os defaults do schema vão para um script com chamadas de API, que é importado e instalado no destino pelo Export Repository.

Fonte: [Managing User Interface Defaults (UI Defaults)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/managing-ui-defaults.html)

### Methods on Tables, Recycle Bin e Sample Datasets

- **Methods on Tables**: gera um package de API (*Create Table API*) para uma ou mais tabelas. *Preserve Case* mantém a caixa do nome. Antes de criar, dá para ver ou baixar a especificação e o body.
- **Recycle Bin**: exige **Flashback Drop** habilitado no banco. *Dropped Objects* lista os objetos removidos (filtro por tipo e *Original Name*), com **Restore Object** ou **Purge Object**. *Purge Recycle Bin* esvazia tudo.
- **Sample Datasets**: instala, atualiza, troca o schema ou remove conjuntos de exemplo. **Só um idioma por vez**: escolher outro substitui os dados. Depois, *Create Application* abre o assistente pré-preenchido. Alguns datasets não são compatíveis com bancos mais antigos.

Fonte: [Managing Methods on Tables](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/managing-methods-on-tables.html) · [Using the Recycle Bin](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/using-recycle-bin.html) · [Using Sample Datasets](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/using-sample-datasets.html)

### Restaurar uma tabela apagada por engano (Recycle Bin)

**Sintoma:** uma tabela foi removida com Drop Table (Object Browser ou SQL).
**Causa:** o drop renomeia a tabela e a coloca na Recycle Bin, mas só quando **Flashback Drop** está ativo.
**Correção:** Utilities > Recycle Bin > Dropped Objects > clique no objeto > **Restore Object**. Se a Recycle Bin estiver vazia ou indisponível, o Flashback Drop não está habilitado, e a recuperação depende de backup.
**Prevenção:** não use *Purge Recycle Bin* sem conferir a lista.

Fonte: [Using the Recycle Bin](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/using-recycle-bin.html) · [Managing Tables](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/managing-tables.html)

### Object Reports: tabelas, PL/SQL, exceções, segurança e objetos inválidos

Utilities > **Object Reports** (interactive reports, com lista Schema):
- **Table Reports**: Columns, Comments, Constraints, Statistics, Storage Sizes.
- **PL/SQL Reports**: *Program Unit Arguments*; *Unit Line Counts* (acha as maiores unidades); **Search PL/SQL Source Code** (busca texto no código, com faixa de linhas; útil antes de remover uma tabela ou função).
- **Exception Reports**: Tables without Primary Keys, Tables without Indexes, **Unindexed Foreign Keys**, Tables without Triggers.
- **Security Reports**: Object Grants, Column Privileges, Role Privileges, System Privileges.
- **All Object Reports**: All Objects (criação e último DDL), **Invalid Objects**, Object Creation Calendar, Object Counts by Type, Data Dictionary.

Fonte: [Viewing Object Reports](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/viewing-object-reports.html)

### About Database e Database Monitor (exigem DBA)

- **About Database**: Version, Settings, Options, National Language Support, CGI Environment, Parameters. Exige conta com papel DBA.
- **Database Monitor**: **Sessions** (abas Sessions, Locks, Waits, I/O, SQL, Open Cursors; detalhe pelo SID com **Kill Session**), **System Statistics** (salvar e ver delta), **Top SQL** (SQL Plan com explain colorido e colunas sem índice em vermelho) e **Long Operations** (operações com mais de **6 segundos**, baseado em `V$SESSION_LONGOPS`).
- Requisitos: (1) conta de banco com papel **DBA**; (2) *Database Monitoring* habilitado na instância (Feature Configuration ou `APEX_INSTANCE_ADMIN.SET_PARAMETER` com `ALLOW_DB_MONITOR`); (3) login com o nome de usuário **EM MAIÚSCULAS**.

Fonte: [Viewing Database Details](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/viewing-db-details.html) · [Monitoring the Database](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/monitoring-db.html) · [About Database Monitor Access Requirements](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/about-database-monitor-access-requirements.html) · [Accessing Session Page Reports](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/accessing-session-page-reports.html) · [Viewing Top SQL Page](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/viewing-top-sql-page.html) · [About Long Operations Page](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/about-long-operations-page.html)

### Database Monitor pede login e recusa o acesso

**Sintoma:** ao abrir Sessions, Top SQL ou Long Operations, aparece um login que não aceita as credenciais, ou o ícone não está disponível.
**Causa:** falta um dos requisitos: a conta não tem papel DBA, o *Database Monitoring* (`ALLOW_DB_MONITOR`) não está habilitado na instância, ou o usuário foi digitado em minúsculas.
**Correção:** use uma conta com DBA e digite o nome **em maiúsculas**. Peça ao administrador da instância para habilitar o Database Monitoring. No Autonomous, a doc do SQL Workshop não diz qual conta usar; em geral só o administrador do banco tem DBA. Sem isso, consulte as views do dicionário do próprio schema.

Fonte: [About Database Monitor Access Requirements](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/about-database-monitor-access-requirements.html) · [Managing Feature Configuration](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-features.html)

### SQL Developer Web (Database Actions) a partir do menu SQL Workshop

Desenvolvedores com acesso ao SQL Workshop podem abrir uma sessão do **SQL Developer Web** (Database Actions) para qualquer schema do workspace pelo menu SQL Workshop. Requisitos: ORDS 23.1.0+ em HTTPS e o atributo de instância **Enable SQL Developer Web** (Feature Configuration > SQL Workshop). Com isso, o menu passa a mostrar a opção. É uma alternativa no navegador ao SQL Commands e ao SQL Scripts para executar queries e scripts, carregar dados e monitorar o banco.

Fonte: [Accessing SQL Developer Web Directly from APEX](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/accessing-sql-developer-web-from-sql-workshop-menu.html) · [Managing Feature Configuration](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-features.html)
## 11. Deploy: export/import, supporting objects, working copies e build options

Deploy é levar a aplicação do ambiente de desenvolvimento/teste para produção. No APEX a aplicação é metadado no banco; o deploy consiste em gerar um **arquivo de export** (SQL ou APEXlang), levá-lo ao destino e importá-lo, junto com os objetos de banco que ele usa (tabelas, packages, dados-semente), que **não** fazem parte do export da aplicação a menos que você use *Supporting Objects*.

### Deploy: ambientes recomendados (DEV, TEST, PROD) e runtime environment

A Oracle recomenda três ambientes: **development**, **testing** e **production**. Regras práticas da doc:

- Altere aplicação e objetos de banco **só em DEV**.
- Em TEST e PROD use uma instância **runtime** (sem App Builder e sem SQL Workshop), o que impede desenvolvedores de editar ali.
- Quem atualiza TEST/PROD deve ser o DBA, importando por interface SQL (SQLcl ou SQL Developer) com as APIs fornecidas, e não pelo navegador.

Quando usar: sempre que houver usuários reais. Quando não usar runtime: em ambientes onde ainda se precisa do Builder para depurar (o custo é o risco de edição direta em produção).

Fonte: [Understanding the Deployment Process](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-the-deployment-process.html)

### Deploy: cenários de workspace, schema e banco (mesmo workspace × outro workspace × outra instância)

A doc lista quatro cenários, do mais simples ao mais isolado:

| # | Cenário | Quando faz sentido |
|---|---|---|
| 1 | Mesmo workspace e mesmo schema, importando com **outro application ID** | Poucas mudanças em objetos de banco, muitas mudanças de funcionalidade |
| 2 | Outro workspace, mesmo schema | Impedir que desenvolvedores mexam na app de produção |
| 3 | Outro workspace e outro schema | O novo schema precisa ter todos os objetos que a app usa |
| 4 | Outro banco/instância APEX (com outro workspace, schema e banco) | Isolamento completo |

Decisões associadas:

- **Copiar o workspace?** Vale a pena quando você quer manter os mesmos identificadores entre ambientes, ou quando a app usa autenticação *Oracle APEX Accounts*: copiar o workspace leva junto os usuários.
- **Copiar o banco?** O schema de execução no destino precisa enxergar os mesmos objetos que em DEV. O **nome** do schema não importa, pois pode ser trocado no import.
- **Application ID:** não precisa ser igual entre DEV e PROD. Boa prática: **nunca** escrever o ID fixo no código. Use o alias da aplicação ou as substitution strings `APP_ID` / `APP_ALIAS`, sendo a substitution string a opção preferida.

Fonte: [Understanding the Deployment Process](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-the-deployment-process.html)

### Export e import: visão geral do processo e formatos (SQL × APEXlang)

O processo tem dois passos:

1. **Criar o arquivo de export**, de uma aplicação, página, componentes, tema, plug-in, UI Defaults, feedback, REST Source Catalog ou workspace. Há dois formatos:
   - **SQL**: script legível `.sql` (ou ZIP com vários `.sql`).
   - **APEXlang**: versão legível e editável entregue em ZIP com nome `APPLICATION-ALIAS.ZIP`, otimizada para geração por IA, leitura humana e controle de versão.
2. **Importar** no destino: subir o arquivo e importar na hora, ou subir e importar depois pelo **Export Repository**. Também dá para importar pela linha de comando, e a Oracle recomenda o **SQLcl**.

Regras gerais:
- Uma app exportada de uma versão **não** pode ser importada numa versão anterior do APEX.
- Importe **primeiro a aplicação** e **depois os arquivos relacionados**.
- Pelo App Builder, o export pode ser feito em *App Builder > Workspace Utilities > Export* ou em *Aplicação > Export/Import > Export*.

Fonte: [Understanding the Export and Import Process](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-the-export-and-import-process.html) · [Importing Export Files](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/importing-export-files.html) · [Exporting and Importing from App Builder](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/exporting-and-importing-from-app-builder.html)

### Exportar uma aplicação: Type (Standard, Runtime, Full, Custom) e opções avançadas

Caminho: *App Builder > Workspace Utilities > Export > aba Application* (ou *Aplicação > Export/Import > Export*). A Oracle recomenda exportar a **aplicação inteira**, e não componentes soltos. Para esconder páginas que ainda não estão prontas, use **Build Options**. Arquivos estáticos (CSS, imagens, JS) podem precisar de export próprio.

**Format:** `SQL` ou `APEXlang`.

**Type:**

| Type | O que inclui / exclui | Uso |
|---|---|---|
| **Standard Export** (padrão) | Inclui comentários de desenvolvedor e auditoria; exclui dados de runtime (instâncias de workflow e task, relatórios salvos públicos e privados) | Controle de versão |
| **Runtime Export** | Define build status *Run Application Only*; exclui comentários, auditoria e dados de runtime | TEST/PROD |
| **Full Export** | Inclui tudo, inclusive dados de runtime e relatórios salvos | Migração para novo ambiente; **não** recomendado para controle de versão |
| **Custom Export** | Abre *Advanced Options* com controle fino | Casos específicos |

**Advanced Options (Format SQL + Custom Export):**

| Opção | Valores e efeito |
|---|---|
| Split into Multiple Files | On = ZIP com um arquivo por página/componente; Off = um `.sql` único |
| Build Status Override | *Run Application Only* ou *Run and Build Application*. Com *Run Application Only*, não é possível usar `p_trace=Yes`, e a volta só é feita em Administration Services. Esse override pode ser trocado no import web, **não** no import por linha de comando |
| Supporting Object Definitions | `Yes` (inclui, mas não instala sozinho na linha de comando), `No`, `Yes and Install on Import Automatically` (inclui e chama a instalação; vale só para import por linha de comando) |
| Public Reports / Private Reports | Inclui ou não os relatórios salvos (públicos/privados) de IR/IG |
| Report Subscriptions | Inclui assinaturas não expiradas de IR/IG |
| Comments | Comentários de desenvolvedor |
| Translations | Mapeamentos de tradução e repositório. *Text Messages* e *Dynamic Translations* sempre vão |
| Debugging | Yes/No. A Oracle recomenda `No` em produção, para não expor lógica |
| Original IDs | On = IDs da última importação; Off = IDs atuais. On reduz ruído em diffs e mantém subscriptions ligadas à app-mestre |
| Owner Override | Faz a app ser importada com outro schema dono |
| Audit Information | `None` (padrão), `Names and Dates`, `Dates Only` |
| As of | Volta N minutos no tempo via `DBMS_FLASHBACK` (útil para recuperar algo apagado) |
| Workflow Instances | On inclui instâncias; as que estiverem *Active* vão como *Suspended* |
| Task Instances | On/Off |

Com **Format APEXlang + Custom**, as opções se reduzem a Build Status Override, Comments, Debugging, Owner Override e As of.

Pegadinha do *As of*: o mapeamento timestamp→SCN é atualizado a cada ~5 minutos, e o quanto dá para voltar depende do *undo* disponível (`UNDO_RETENTION`, padrão de 3 horas, que influencia o tamanho do tablespace de undo). Bancos com menos transações conseguem voltar mais.

Fonte: [Exporting an Application](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/exporting-an-application.html)

### Exportar uma página isolada: restrições de IDs e Shared Components

Export de página única (pela aba *Page* do Export ou por *Page Designer > Utilities > Export*) é técnica **avançada** com restrições rígidas:

- Origem e destino precisam ter **o mesmo application ID e o mesmo workspace ID**.
- Os **IDs dos Shared Components** precisam ser iguais nos dois lados.
- Shared Components novos ou alterados que a página usa precisam ser exportados e importados **antes**.

Se alguma condição falhar, o import falha. Opções: Format (SQL/APEXlang), Split into Multiple Files, Original IDs, Audit Information, As of e File Character Set. Só uma página por vez. O arquivo se chama `f<app>_page_<n>.sql` ou `.zip`.

Fonte: [Exporting an Application Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/exporting-an-application-page.html)

### Exportar componentes (Component Export) como backup ou patch

*Export > aba Components*: selecione componentes de aplicação e build options, clique em *Add to Export* e depois em *Export*. Serve como backup antes de editar um componente ou como **patch** para outra instância.

- **Export Format:** `SQL` ou `ZIP`. No ZIP, **Include Installation Files** On gera `install.sql`, `set_environment.sql` e `end_environment.sql` só para aqueles componentes. Off omite esses arquivos, o que a Oracle recomenda ao salvar em controle de versão para não sobrescrever os instaladores da aplicação.
- Também tem Audit Information, As of e File Character Set.
- Nome do arquivo com vários componentes: `f<app>_components.sql` ou `.zip`.
- Para apps traduzidas aparece **Export Translations**. Sincronize as traduções antes.

Fonte: [Exporting Application Components](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/exporting-application-components.html)

### Exportar temas, plug-ins, UI Defaults, feedback, REST Source Catalog e scripts

Todos ficam em *App Builder > Workspace Utilities > Export*, cada um na sua aba, e geram `.sql`. Quase todos têm *Audit Information* (`None` padrão / `Names and Dates` / `Dates Only`) e *File Character Set*.

- **Themes:** escolha aplicação e tema (conjunto de templates).
- **Plug-ins:** escolha aplicação e plug-in. Também dá para exportar pela página *Plug-ins > Export Plug-in*.
- **UI Defaults:** *Table Dictionary* (por schema, vale para tabelas e colunas e tem prioridade) e *Attribute Dictionary* (por nome de coluna, com sinônimos). Também dá para exportar por *SQL Workshop > Utilities > UI Defaults*, escolhendo o formato de fim de linha DOS ou UNIX.
- **Feedback** (Team Development): opção *Changes Since* define a data inicial.
- **REST Source Catalog:** aba *Catalog*.
- **Script Repository:** exportado pelo SQL Workshop (ver doc de SQL Scripts).

Fonte: [Exporting Themes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/exporting-themes.html) · [Exporting Plug-ins](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/exporting-plug-ins.html) · [Exporting UI Defaults](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/exporting-ui-defaults.html) · [Exporting Team Development Feedback](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/exporting-team-development-feedback.html) · [Exporting a REST Source Catalog](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/exporting-a-REST-source-catalog.html) · [Exporting Script Files from the Script Repository](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/exporting-script-files-from-the-script-repository.html)

### Exportar um workspace: o que vai (usuários, Team Development) e o que não vai (aplicações)

O export de workspace gera um `.sql` com grupos de usuários, usuários, dados de Team Development e artefatos do workspace. Ele **não inclui aplicações**.

- **Include Team Development:** desligue só se o destino for instância runtime.
- **Include Extension Links:** inclui os links do menu *Extension*.
- **Export Type:** `Minimal` (padrão, o recomendado na maioria dos casos) ou `Full`, que replica também SQL Scripts, histórico do SQL Commands, SQL salvo, preferências de usuário, histórico de login de desenvolvedor, logs de e-mail e UI Defaults.
- O import é feito em **Administration Services**.

A Oracle **não recomenda** exportar o workspace inteiro, a não ser para migrar usuários ou replicar Shared Component subscriptions.

Fonte: [Exporting a Workspace](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/exporting-a-workspace.html)

### Exportar arquivos estáticos (application e workspace static files)

Os static files (imagens, CSS, JS) são gerenciados à parte. Há duas formas de exportar: gerar um ZIP em *Shared Components > Static Application Files*, ou gerar scripts de instalação via **Component Export**. No export dividido, eles ficam em `application/shared_components/files` (app) e `workspace/files` (workspace).

Fonte: [About Exporting Static Files](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-exporting-static-files.html)

### Importar uma aplicação (SQL ou APEXlang): Parsing Schema, Build Status e Install As Application

Caminho: *App Builder > Import*. Arraste o arquivo, escolha **File Type** (*Application, Page or Component Export*), confira **File Character Set** e clique em *Next*.

**Requisitos para importar APEXlang pelo App Builder:** **ORDS 26.1.1 ou posterior** e **pelo menos um schema REST-enabled** no workspace. Sem isso, aparece erro.

No passo *Import Application*:

| Campo | Opções |
|---|---|
| **Parsing Schema** | Schema que será o dono da app após a instalação |
| **Build Status** | *Run Application Only* (só executa; protege contra edição, e voltar exige Administration Services) ou *Run and Build Application* |
| **Import As Application** | *Auto Assign New Application ID*; *Reuse Application ID XX From Imported Application* (se já existir app com esse ID **no workspace atual**, ela é **apagada e substituída**); *Change Application ID* (o ID precisa ser único em **todos** os workspaces da instância) |
| **Subscriptions** (condicional) | *Subscription Mode*: `Strict`, `Ignore Errors`, `Remove`, `Legacy`, mais o mapeamento de master application |

Depois do import, se o arquivo tiver **Credentials** ou **Remote Servers**, o assistente pede a configuração deles. Se houver **supporting objects**, o assistente oferece *Install Supporting Objects*. A tela final tem os botões *Upgrade Application*, *Edit Application* e *Run Application*.

Grupos de aplicação: o import reaproveita o grupo de mesmo ID. Se não houver, procura um grupo de mesmo nome. Se também não houver, cria um novo grupo, mantendo o ID se estiver livre ou gerando outro.

Fonte: [Importing Export Files](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/importing-export-files.html)

### Importar página, componentes, temas, plug-ins, UI Defaults, feedback, REST catalog e blueprint

- **Página (SQL):** escolha *Import Into Application*. Se for a mesma app, aparece *Confirm Replace Page > Replace Page*. **Importar página APEXlang pelo App Builder não está disponível nesta versão.** A Oracle indica SQLcl ou SQL Developer for VS Code.
- **Componentes:** os componentes existentes são **apagados e reinstalados**. Se todos os comandos funcionarem, faz commit; se houver qualquer erro, faz **rollback total**. Na mesma app aparece *Replace Application Components*. **Importar templates para outra app ou workspace não é suportado.**
- **Tema:** File Type *Theme Export* e aplicação de destino; pode ter Subscription Mode.
- **Plug-in:** substitui o plug-in de **mesmo nome**. Erro causa rollback.
- **UI Defaults:** pode ir para qualquer schema do workspace. O *Table Dictionary* **sobrescreve** os defaults antigos; o *Attribute Dictionary* substitui os atributos correspondentes, mas não remove os que não vierem no arquivo.
- **Team Development Feedback** e **REST Source Catalog:** File Type próprio e botão *Import Feedback* / *Import REST Catalog*.
- **Application Blueprint:** formato Markdown para *Spec-Driven Development* com assistentes de IA. No import você escolhe o *Generative AI Service*, o *Parsing Schema* e um *Application ID* novo. IDs de **3000 a 9000 são reservados** ao APEX.

Fonte: [Importing Export Files](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/importing-export-files.html)

### Reimportar aplicação que tem processos em background (Disable Background Execution × Replace Application)

Ao reimportar por cima de uma app que tem page processes com *background execution*, escolha *Change Application ID* com o ID da primeira importação. O APEX mostra um aviso de que a app a ser substituída tem execuções em background e oferece:

- **Disable Background Execution:** impede que novas execuções comecem (zera *Maximum Scheduler Jobs*) e volta para a página.
- **Replace Application:** instala na hora. Execuções em andamento são **encerradas** e as que estão em espera são **apagadas**.

Fonte: [Importing Export Files](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/importing-export-files.html)

### Export Repository: instalar depois ou apagar arquivos importados

Todo arquivo importado fica guardado no **Export Repository** (*Aplicação > Utilities > Export Repository*). Dali você pode:
- **Install** um application export, com o mesmo assistente (Parsing Schema, Build Status, Install As Application).
- **Install** outros tipos de export, com passos que variam por tipo.
- **Delete Checked** para remover arquivos.

Também dá para instalar exports pelo SQLcl.

Fonte: [Managing Export Files from the Export Repository](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-export-files-from-the-export-repository.html)

### Import falha com "application is locked" (página, componente, tema ou plug-in)

**Sintoma:** ao importar uma aplicação, página ou componente, você é levado a uma página de notificação dizendo que a aplicação está bloqueada. Ao instalar tema ou plug-in, aparece um erro de validação.
**Causa:** a aplicação de destino está **bloqueada por outro usuário** (lock de aplicação). O import em app bloqueada não é permitido.
**Correção:** peça ao dono do lock que o libere (ou libere você mesmo, se for o dono) e repita o import.
**Prevenção:** coordene os locks antes de deploys em workspaces compartilhados.

Fonte: [Importing Export Files](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/importing-export-files.html)

### Import de página ou componente falha por Shared Component ou tabela inexistente no destino

**Sintoma:** o import de uma página dá erro de referência a componente ou tabela que não existe.
**Causa:** a página referencia um Shared Component ou uma tabela que não está no workspace de destino, ou os IDs de app, workspace ou Shared Components diferem entre os ambientes.
**Correção:** importe antes os componentes e as tabelas necessários. Para export de página, garanta o mesmo application ID, o mesmo workspace ID e os mesmos IDs de Shared Components. Se não der para garantir, exporte a **aplicação inteira**.
**Prevenção:** prefira exportar a aplicação completa e use Build Options para esconder o que não está pronto.

Fonte: [Importing Export Files](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/importing-export-files.html) · [Exporting an Application Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/exporting-an-application-page.html)

### Conflito de application ID no import (ID já usado ou app substituída sem querer)

**Sintoma:** o import recusa o ID escolhido, ou uma aplicação existente "some" e é trocada pela importada.
**Causa:** application IDs são **únicos na instância inteira**. Com *Reuse Application ID*, se já houver app com o mesmo ID no workspace atual, ela é apagada e substituída.
**Correção:** use *Auto Assign New Application ID* ou *Change Application ID* com um ID livre (evite 3000 a 9000, que são reservados). Para atualizar de propósito uma app existente, use *Reuse*, mas exporte um backup antes.
**Prevenção:** não escreva o ID fixo no código; use `APP_ID` / `APP_ALIAS`.

Fonte: [Importing Export Files](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/importing-export-files.html) · [Understanding the Deployment Process](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-the-deployment-process.html)

### Import de APEXlang pelo App Builder dá erro (ORDS antigo ou schema não REST-enabled)

**Sintoma:** o import de um ZIP APEXlang em *App Builder > Import* falha com erro.
**Causa:** a instância não roda **ORDS 26.1.1+**, ou nenhum schema do workspace está **REST enabled**. Para página APEXlang, o import pelo App Builder simplesmente não existe nesta versão.
**Correção:** habilite REST no schema (SQL Workshop > RESTful Services) ou atualize o ORDS. Para página APEXlang, use SQLcl ou SQL Developer for VS Code.

Fonte: [Importing Export Files](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/importing-export-files.html)

### Build status "Run Application Only" depois do import: não consigo editar a app

**Sintoma:** depois de importar, a aplicação não abre para edição no App Builder.
**Causa:** o import (ou o export do tipo *Runtime Export*, ou o *Build Status Override*) definiu *Run Application Only*.
**Correção:** só um administrador de instância muda isso, em **Administration Services** (*Changing Application Build Status*). Em Autonomous Database, isso depende de acesso de instance admin.
**Prevenção:** use *Run and Build Application* em DEV e *Runtime Export* só para TEST/PROD.

Fonte: [Exporting an Application](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/exporting-an-application.html) · [Importing Export Files](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/importing-export-files.html)

### Supporting Objects: empacotar DDL, dados-semente e pré-requisitos com a aplicação (custom application)

Uma **custom application** é uma app que carrega seus objetos de banco nos **Supporting Objects** (*Aplicação > Supporting Objects*). Vantagens segundo a doc:
- Os objetos são criados na ordem certa.
- O deploy é feito em poucos passos.
- O usuário escolhe instalar os objetos junto com a app ou depois.
- A remoção (app, arquivos e objetos) é simples.
- Há um caminho de upgrade.

O topo da página mostra *Check for Objects*, *Verify System Privileges*, *Required Free KB*, *Prompt for License* e **Include in Export** (Yes/No).

**Installation:**
- **Prerequisites:** espaço livre, privilégios de sistema e restrições de objetos.
- **Application Substitution Strings:** podem virar prompts no momento da instalação.
- **Build Options:** podem virar prompts na instalação.
- **Pre-installation Validations:** funcionam como validations e bloqueiam a instalação se a condição falhar.
- **Installation Scripts:** vários scripts, com **Lock** para impedir edição por outro desenvolvedor. O tipo *Data Package* exige Oracle Database 18c+.
- **Messages:** mensagens de instalação e desinstalação, com HTML limitado (`<b> <i> <u> <p> <br> <hr> <ul> <ol> <li> <pre>`) por proteção contra XSS.

**Upgrade:** *Upgrade Scripts* e *Upgrade Message*. **Deinstallation:** *Deinstallation Script* (drop de objetos e arquivos) e *Deinstallation Message*.

**Tarefas:**
- *Install Supporting Objects*, com *preview the installation details*.
- *Remove All Supporting Objects*: apaga só o **metadado** dos scripts.
- *Deinstall Supporting Objects*: roda o script de desinstalação, com *Preview Deinstallation Script*. Também é acionado por *Delete this Application*.
- *View Install Summary*: mostra apenas a última instalação ou desinstalação **da sessão APEX atual**.

Fonte: [How to Create a Custom Application](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/how-to-create-a-custom-packaged-application.html)

### Supporting Objects: upgrade de custom application (Query to Detect Existing Supporting Objects)

Em *Supporting Objects > Upgrade Scripts*, preencha **Query to Detect Existing Supporting Objects**, uma query que retorna **pelo menos uma linha** se os objetos já existem. É essa query que decide se o instalador vai rodar os scripts de **instalação** ou os de **upgrade**. Os scripts de upgrade podem ter condições (em *Script Properties*) para suportar upgrade a partir de várias versões anteriores. Para testar, use *Tasks > Upgrade Supporting Objects*, depois de importar a nova versão, se for o caso.

Exemplo de query de detecção (ilustrativo):

```sql
select 1 from user_tables where table_name = 'COLABORADOR'
```

Fonte: [How to Create a Custom Application](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/how-to-create-a-custom-packaged-application.html)

### Build Options: Include/Exclude, Default on Export, On Upgrade Keep Status e APIs

**Build options** ligam ou desligam componentes (páginas, regiões, itens, validations, Shared Components etc.). Com `Include`, o componente faz parte da app em runtime. Com `Exclude`, o engine age **como se ele não existisse**.

Atributos (*Shared Components > Application Logic > Build Options > Create/Edit*):

| Atributo | Descrição |
|---|---|
| Build Option | Nome |
| Status | `Include` / `Exclude` |
| Default on Export | Status gravado no export |
| On Upgrade Keep Status | On preserva o status já vigente na app implantada no upgrade, útil quando o status é configurado em produção via `APEX_UTIL.SET_BUILD_OPTION_STATUS` |
| Comments | Nunca aparecem em runtime |
| Advanced > Static ID | ID estável para APIs e export. Ao trocá-lo, os componentes dependentes continuam ligados, mas chamadas de API com o ID antigo precisam ser corrigidas à mão |

APIs: `APEX_UTIL.GET_BUILD_OPTION_STATUS` (duas assinaturas) e `APEX_UTIL.SET_BUILD_OPTION_STATUS`.

Casos de uso da doc:
1. Ligar ou desligar funções por tipo de instalação.
2. Esconder funcionalidade incompleta em TEST/PROD.
3. "Comentar" uma função antes de removê-la de vez.

A build option **Commented Out** vem por padrão em apps novas e alimenta o menu *Comment Out / Uncomment* do Page Designer. Apagá-la remove esse recurso.

Para aplicar: no Page Designer, selecione o componente e use *Property Editor > Configuration > Build Option*. Depois disso, dá para alternar pelo menu de contexto da aba Rendering.

Fonte: [About Build Options](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-build-options.html) · [Creating and Editing Build Options](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-and-editiing-build-options.html) · [Including or Excluding Build Options](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/including-excluding-build-options.html) · [Selecting a Build Option](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/selecting-build-option.html)

### Build Options: copiar, assinar, apagar, relatórios e export de status (feature oculta em produção)

- **Copiar/assinar:** *Copy* (na mesma app) ou *Copy from another app*, com a opção *Subscribe*. Em *Subscription > Subscribe From* você aponta a build option mestre; há também *Refresh Build Option* e *Unsubscribe*.
- **Apagar:** apagar a build option **não apaga** os componentes associados. Para apagá-los de vez, use *Associated Components > Remove Components* antes.
- **Relatórios:** *Utilization* (aparece só depois que existe ao menos uma build option) e *History*.
- **Exportar status:** em *Shared Components > Export Application Components > aba Build Options Status*. Padrão de "feature escondida": publique em produção com a build option em `EXCLUDE`; para ativar, mude para `INCLUDE` e exporte e aplique apenas o **Build Option Status**. Export as Zip On gera um arquivo por componente.

Fonte: [Copying or Subscribing to Build Options](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-build-options-to-control-configuration.html) · [Deleting Build Options and Associated Components](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/deleting-build-options-associated-components.html) · [Viewing Build Option Reports](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/viewing-build-option-reports.html) · [Exporting Build Options or Build Option Status](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/exporting-build-options-or-status.html)

### Working Copies: criar, comparar, refresh, merge e limitações

Uma **Working Copy** é uma cópia especial da app (a **Main application**) no mesmo workspace, para mudar isoladamente e depois fazer merge. Criação: *Application home > side bar Working Copy Tasks > Create Working Copy*, informando nome e descrição.

O menu **Working Copy: \<Nome\>** (no Application home e no Page Designer) oferece:
- *Switch to Main*
- *Merge into Main*: indisponível se a Main estiver bloqueada por outro usuário.
- *Refresh Working Copy*: traz as mudanças da Main.
- *Compare Working Copy with Main*
- *View Working Copy Details*
- *Delete Working Copy*
- No Page Designer, também *Compare Current Page with Main*.

Como funciona: a comparação gera um export **YAML dividido** das duas apps, com a working copy exportada com **original IDs**, e compara checksums por arquivo. Isso roda em **background job**, então `JOB_QUEUE_PROCESSES` precisa ser maior que 0 (em multitenant, o valor do CDB pode sobrepor o do PDB). O **merge** importa as páginas e componentes selecionados na Main, **substituindo** os existentes. Mudanças feitas na Main e ausentes na cópia são sobrescritas. O diálogo de merge permite desmarcar linhas e oferece *Backup target app first* e *Delete Working Copy after merge*.

Não têm merge automático: traduções, temas, theme templates, supporting objects, propriedades da aplicação e componentes de workspace (App Groups, Credentials, Remote Servers).

Limitações:
- Não existe working copy de working copy.
- Páginas e componentes apagados na cópia precisam ser apagados à mão na Main.
- *Missing* pode significar removido na cópia ou existente só na Main.
- Ao criar a cópia, **todas as automations ficam desabilitadas**; desmarque-as no merge ou reative-as depois.
- Em working copy, use `MAIN_APP_ID` (e não `APP_ID`) quando a lógica depender do ID da app principal.

Fonte: [About Working Copies](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-working-copies.html) · [About Working Copy Menus and Tasks](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-working-copy-menus-and-tasks.html) · [Merging Changes from a Working Copy into Main](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/merging-changes-from-a-working-copy-into-main.html) · [Refreshing a Working Copy with Changes from Main](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/refreshing-a-working-copy-with-changes-from-main.html)

### Working copy: comparar, fazer merge ou refresh não mostra progresso (barra parada)

**Sintoma:** em *Compare*, *Merge into Main* ou *Refresh*, a barra de progresso não anda.
**Causa:** a comparação roda em background job e `JOB_QUEUE_PROCESSES` está em 0 (ou o CDB está limitando o PDB).
**Correção:** o DBA deve definir `JOB_QUEUE_PROCESSES` maior que 0, conferindo CDB e PDB.

Fonte: [About Working Copies](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-working-copies.html)

### ORA-00001 ao fazer merge de working copy (nomes de componentes duplicados)

**Sintoma:** o merge da working copy na Main falha com `ORA-00001` (unique constraint).
**Causa:** há componentes com **nomes não únicos** entre a working copy e a Main (por exemplo, dois Shared Components criados com o mesmo nome nos dois lados).
**Correção:** renomeie um dos componentes para nomes únicos e repita o merge. Se o conflito persistir, exporte as duas apps em APEXlang, resolva o conflito com ferramentas externas, valide com `apex validate`, importe o resultado por cima da Main e apague a working copy conflitada.
**Prevenção:** coordene a nomenclatura de Shared Components entre working copies e Main. Bloqueie (lock) na Main as páginas que você está mudando na cópia.

Fonte: [About Working Copies](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-working-copies.html) · [Isolating Changes with Working Copies](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/isolating-changes-working-copies.html)

### "Server Error" / ORA-00600 [qjsnplsDecDomRefCnt:noValP] em working copy no Database 19c

**Sintoma:** em Merge into Main, Refresh from Main ou Compare Changes aparece "Server Error", com um `ORA-00600: internal error code, arguments: [qjsnplsDecDomRefCnt:noValP]` por trás.
**Causa:** bug do Oracle Database 19c anterior à 19.16.
**Correção:** atualize o banco para 19.16 ou posterior. Não afeta o 23ai deste projeto.

Fonte: [About Working Copies](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-working-copies.html)

### One-click Remote Application Deployment (via REST Enabled SQL)

Faz deploy direto para outra instância usando uma **REST Enabled SQL reference** (serviço REST Enabled SQL do ORDS). A autenticação pode ser Basic (first party), *Schema Authentication* (usuário e senha do banco) ou OAuth2 Client Credentials. A Oracle recomenda **credenciais vazias** em ambientes compartilhados, para que só quem conhece o segredo consiga implantar.

Caminho: *Aplicação > Export/Import > Remote Deployment*.
- **Endpoint URL:** `https://host:port/ords/schema`, **sem** `/_/sql`.
- **Client ID:** usuário do banco, convertido em maiúsculas; prefixe `!` para manter maiúsculas e minúsculas.
- **Client Secret:** fica armazenado criptografado.

**Opções de deploy:**
- Build Status.
- As of.
- Export Supporting Object Definitions (`Yes` / `No` / `Yes and Install on Import Automatically`).
- Public/Private Reports, Report Subscriptions, Developer Comments, Translations.

**Overrides:**
- *Owner Override*: se vier vazio, a conexão não está mapeada a workspace.
- *Workspace Override*.
- *Overwrite Existing Application*: On mantém o mesmo ID e sobrescreve.
- *Application ID Override* e *Application Alias Override*.

Fonte: [Understanding One-Click Remote Application Deployment](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/one-click-remote-application-deployment.html)

### Publicar a URL de produção (Friendly URL × f?p, sem session ID)

Para descobrir a URL: clique com o botão direito em *Run* e copie o link (o valor vem do atributo *Home link* em Security Attributes), ou rode a app e copie a URL.

Friendly URL: `https://servidor/ords/<path_prefix>/r/<app-alias>/<page-alias>?session=…`.
- `ords`: nome do serviço do ORDS.
- `path_prefix`: por padrão, o nome do workspace.
- `r`: atalho do router.
- O alias da app e o da página nascem do nome de cada uma.

Formato antigo: `f?p=<app>:<page>:<session>`. **Nunca publique a URL com o número de sessão**: outro usuário que abrir essa URL recebe erro.

Fonte: [About Publishing an Application URL](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-publishing-an-application-url.html)

### Metodologias de SDLC citadas pela doc (Waterfall, Spiral, RAD)

O App Builder favorece desenvolvimento iterativo: wizards para prototipar, protótipos liberados a usuários e mudanças em tempo real. A doc contrasta:
- **Waterfall:** planejamento → requisitos → design → desenvolvimento → integração e testes → instalação e aceite → manutenção. Supõe requisitos fixos.
- **Spiral:** série de pequenas cascatas. Acomoda mudança, mas tem gestão complexa e risco de não terminar.
- **RAD:** protótipo próximo do produto final. Ciclos rápidos, com risco de *scope creep*.

Spiral e RAD são os modelos que combinam com o APEX.

Fonte: [System Development Life Cycle Methodologies to Consider](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/system-development-life-cycle-methodologies-to-consider.html)

## 12. Ciclo de vida da aplicação (Developer's Companion)

O capítulo *Understanding Application Lifecycle* do Developer's Companion trata o ciclo de vida (ALM) como um ritmo: escolher o trabalho, dividir tarefas, testar e liberar pequenos lotes de mudanças de qualidade com regularidade. Ele se apoia em quatro pilares: artefatos exportados, múltiplos ambientes, working copies e Git.

### Artefatos da aplicação: o banco guarda só o estado atual, o export é o histórico

Uma app APEX é **metadado** no banco, lido pelo engine para renderizar páginas. O dicionário mostra sempre e só o **estado atual**, sem histórico de versões: ao mudar um componente, a definição antiga é perdida. Para ter histórico, é preciso **exportar** a app como texto. Esses exports são os **application artifacts**, snapshots legíveis que se comparam, versionam e restauram.

O export padrão é um `f<app-id>.sql` único. O **split export** gera um arquivo por componente, o que é melhor para controle de versão porque só o arquivo alterado aparece no diff. A doc sugere avaliar o **APEXlang** para controle de versão: é editável, pode ser validado sem conexão ao banco com `apex validate` (SQLcl) e funciona bem com agentes de IA.

Fonte: [Identifying Application Artifacts](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/identifying-application-artifacts.html)

### Export/import pelo SQLcl: apex export, -split, -skipExportDate, -expOriginalIds, -expType

Pelo App Builder: *Export/Import > Export* (com *Split Export* opcional). Pelo **SQLcl** (precisa de Java), conecte como o **parsing schema** do workspace:

```
sql> apex export -applicationid 12345
```

Isso gera `f12345.sql` no diretório atual. Opções recomendadas pela doc:

| Opção | Efeito |
|---|---|
| `-split` | Pasta organizada com um arquivo por componente |
| `-skipExportDate` | Omite timestamps e evita falsos diffs |
| `-expOriginalIds` | Preserva IDs internos entre ambientes |
| `-expSupportingObjects Y` | Inclui os Supporting Objects |
| `-expType` | `APPLICATION_SOURCE` (padrão, SQL), `APEXLANG`, `EMBEDDED_CODE` (extrai SQL, PL/SQL e JS); dá para combinar com vírgula |

```
sql> apex export -applicationid 12345 -split -skipExportDate -expOriginalIds -expSupportingObjects Y -expType APPLICATION_SOURCE,APEXLANG
```

O resultado é um diretório `<alias>/` com os `.apx` e um diretório `f12345/` com os SQL.

**Import por linha de comando (formato SQL):** antes de rodar o script, defina o contexto com `APEX_APPLICATION_INSTALL`:

```sql
begin
   apex_application_install.set_workspace('MyWorkspace');
   apex_application_install.set_application_id(56789);
   -- opcional: instalar Supporting Objects automaticamente
   -- apex_application_install.set_auto_install_sup_obj(true);
end;
/
@f12345/install.sql
```

Mesma instância com outro workspace exige **outro ID**, porque IDs são únicos por instância; a API pode gerar o ID novo e ajustar alias e parsing schema. Entre instâncias diferentes, geralmente dá para manter ID e alias.

Pegadinha: o export **cobre só a definição da app**. Tabelas, views e packages migram à parte, com scripts ou ferramentas de migração de schema. A doc cita *SQLcl Projects* para coordenar os dois.

Fonte: [Exporting and Importing Applications](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/exporting-and-importing-applications.html)

### Múltiplos ambientes: instâncias separadas × workspaces separados e Environment Banner

Há duas formas de montar DEV/TEST/PROD:
- **Instâncias APEX separadas** (um banco ou PDB por ambiente): isolamento total, e dá para manter o **mesmo app ID, alias e nome de workspace** em todas.
- **Workspaces separados numa instância** (ex.: `MYAPP_DEV`, `MYAPP_TEST`, `MYAPP_PROD`, cada um com seu schema): os IDs e aliases precisam ser únicos na instância (ex.: 100 → 1100 → 2100). O import permite trocar ID, alias e schema.

Use o **Environment Banner** (faixa colorida com texto no App Builder) para diferenciar os ambientes e evitar editar produção por engano.

Fluxo típico:
1. Desenvolver em DEV.
2. Exportar a app e os scripts de dados.
3. Importar em TEST e validar.
4. Corrigir em DEV e retestar se preciso.
5. Importar **o mesmo arquivo** em PROD.

Incremente o *Version Number* da app a cada release.

Fonte: [Working with Multiple Environments](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/working-multiple-environments.html)

### Working copies e page locks no ciclo de vida (com APEXlang para conflitos)

Para mudanças maiores, use uma **working copy**: um sandbox no mesmo workspace, parecido com uma branch Git. Compare com a Main (ou com outra cópia), faça refresh, merge ou descarte. O merge e o refresh atuam por **página e componente**: cópias que mexem em páginas diferentes fazem merge limpo, enquanto a mesma página alterada nos dois lados pode gerar conflito. Para evitar, **bloqueie (lock) a página na Main** com um comentário enquanto trabalha nela na cópia, e desbloqueie depois do merge.

Também dá para exportar a working copy em APEXlang, editá-la fora (editor, agente de IA, diff/merge), reimportá-la e então fazer o merge normal. Se um conflito impedir o merge, exporte a Main e a cópia em APEXlang, resolva manualmente, rode `apex validate`, importe por cima da Main e apague a cópia. Em equipes que usam working copies, normalmente só a **Main** vai para o Git.

Fonte: [Isolating Changes with Working Copies](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/isolating-changes-working-copies.html) · [Tracking Changes with Source Control](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/tracking-changes-source-control.html)

### Source control com Git e pipeline recomendado (SQLcl + Git)

Como o APEX não guarda histórico, o Git vira a "máquina do tempo". Cada commit de export registra quem mudou, o quê, quando e por quê. Um padrão comum é ter uma pessoa responsável por exportar periodicamente e fazer commit e push com mensagem descritiva. O diff dos artefatos mostra exatamente o que mudou entre releases. O Git também abre caminho para CI (Jenkins, GitHub Actions) ou para scripts simples de SQLcl e shell nos dois sentidos.

Pipeline resumido pela doc:
1. SQLcl exporta a app e os scripts de banco regularmente.
2. Git versiona.
3. Os arquivos exportados são importados em TEST e PROD.

Equipes maiores podem usar um clone Git privado por desenvolvedor e uma "branch instance" isolada, com code review por feature.

Fonte: [Tracking Changes with Source Control](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/tracking-changes-source-control.html) · [Summarizing Lifecycle Recommendations](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/summarizing-lifecycle-recommendations.html) · [Understanding Application Lifecycle](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-application-lifecycle.html)

## 13. Debug de aplicações (debug levels, Advisor, mensagens, APEX_DEBUG)

O capítulo *Debugging an Application* reúne revisão de session state, Debug mode, isolamento de componentes, monitoramento via `V$SESSION`, SQL trace com TKPROF e o Advisor.

### Debug levels do APEX: LEVEL1 a LEVEL9 (Error, Warn, Info, Enter, Trace)

São **sete níveis**, cumulativos: cada nível inclui as mensagens dos anteriores.

| Nível | Nome | O que registra | Debug URL | API que grava nesse nível |
|---|---|---|---|---|
| `LEVEL1` | Error | Erros | `LEVEL1` | `APEX_DEBUG.ERROR` |
| `LEVEL2` | Warn | Avisos | `LEVEL2` | `APEX_DEBUG.WARN` |
| `LEVEL4` | Info | Informativas; **padrão** quando o debug é ligado sem nível | `YES` ou `LEVEL4` | `APEX_DEBUG.INFO` |
| `LEVEL5` | Application Enter | Entrada e saída de métodos e operações da aplicação | `LEVEL5` | `APEX_DEBUG.ENTER` |
| `LEVEL6` | Application Trace | Detalhe de métodos e operações da aplicação | `LEVEL6` | `APEX_DEBUG.TRACE` |
| `LEVEL8` | APEX Engine Enter | Entrada e saída de métodos do engine | `LEVEL8` | (engine) |
| `LEVEL9` | APEX Engine Trace | Detalhe do engine **e planos de execução** das queries da app | `LEVEL9` | (engine) |

Não existem os níveis 3 e 7. A Oracle recomenda depurar em **LEVEL6 ou menos**, a não ser que o Oracle Support peça mais, porque os níveis altos geram muitas mensagens, deixam a app lenta e dão mais trabalho para analisar. **Erros são registrados mesmo com o debug desligado.**

Fonte: [Available Debug Levels](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/available-debug-levels.html)

### Habilitar Debug para usuários finais: atributo Debugging da aplicação

Em *Edit Application Definition > Definition > Properties > Debugging* (ou *Shared Components > Application Definition*):
- `Yes` permite ligar o debug pelo navegador em runtime.
- `No` impede isso.

Em produção, a Oracle recomenda `No`, para não expor a lógica. Exceções: **desenvolvedores logados no workspace** da app sempre podem depurar, e o debug **programático** (APIs) funciona com qualquer valor desse atributo. No export, a opção *Debugging* (Yes/No) grava esse atributo.

Fonte: [Enabling and Disabling Debug Mode for an Application](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/enabling-and-disabling-debug-mode-for-an-application.html)

### Ligar Debug pela Developer Toolbar (Info, App Trace, Full Trace, View Debug)

Rode a app a partir do App Builder; a **Developer Toolbar** aparece no rodapé das páginas editáveis. Em **Debug**:
- **Enable Debug:** `Off`; `Info` (padrão, = `LEVEL4` / `YES`); `App Trace` (até nível 6, = `LEVEL6`); `Full Trace` (máximo, = `LEVEL9`, deixa as requisições mais lentas).
- **View Debug:** mostra o debug da página atual.

Com o debug ligado, a captura roda em segundo plano e vale **enquanto a aba ou janela do navegador continuar aberta**, mantendo modo e nível.

Fonte: [Controlling Debug Mode for a Page at Runtime](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/controlling-debug-mode-for-a-page-at-runtime.html)

### Ligar Debug pela URL: debug=YES / LEVELn (Friendly URL e f?p)

Na **Friendly URL**, use o parâmetro `debug` com `YES` ou `LEVELn` (n = 1, 2, 4, 5, 6, 8 ou 9). `YES` equivale a `LEVEL4`.

```
https://<host>:<porta>/ords/r/<workspace>/<app>/<pagina>?session=&APP_SESSION.&debug=YES
https://<host>:<porta>/ords/r/<workspace>/<app>/<pagina>?session=&APP_SESSION.&debug=LEVEL9
```

Na sintaxe **f?p**, o debug é o 5º argumento:

```
f?p=100:1:&APP_SESSION.::YES
```

Fonte: [Using URL Parameters to Control Debug Mode](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/Using-url-parameters-to-control-debug-mode.html)

### Debug de uma sessão específica: Session Detail report e APEX_SESSION.SET_DEBUG

- **Pela UI:** *Administration > Monitor Activity > Active Sessions*, clique na sessão e, em *Session Detail*, ajuste **Debug Level** e **Trace Mode** da sessão ativa.
- **Programaticamente:** `APEX_SESSION.SET_DEBUG` define o nível de debug para **todas as requisições futuras** daquela sessão. Isso serve para reproduzir problemas que só acontecem com **outro usuário**. Quanto maior o nível, mais pesadas e lentas ficam as páginas.

```sql
-- APEX_SESSION.SET_DEBUG(p_session_id IN NUMBER DEFAULT apex_application.g_instance,
--                         p_level IN apex_debug.t_log_level)  -- NULL desliga; 1-9 define o nível
begin
  apex_session.set_debug(p_session_id => 1234567890,
                         p_level      => apex_debug.c_log_level_app_trace); -- 6
  commit;
end;
/
-- desligar: p_level => null. A sessão precisa ser do workspace atual.
```

Fonte: [SET_DEBUG Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_DEBUG-Procedure.html) · [Configuring Debug Mode Using the Session Detail Report](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-debug-mode-using-the-session-detail-report.html) · [Configuring the Debug Level Programatically](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-the-debug-level-programatically.html) · [Using APEX_DEBUG When Developing Your Application](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-APEX_DEBUG-when-developing-your-application.html)

### Debug na instância inteira: APEX_INSTANCE_ADMIN.SET_PARAMETER('SYSTEM_DEBUG_LEVEL')

Muda o nível de debug padrão de **toda a instância**. Exige `SYS` ou um usuário com a role `APEX_ADMINISTRATOR_ROLE`:

```sql
begin
  apex_instance_admin.set_parameter(
    p_parameter => 'SYSTEM_DEBUG_LEVEL',
    p_value     => '6');   -- Application Trace
  commit;
end;
/
-- desligar: p_value => null
```

Isso gera muitas mensagens e afeta o desempenho da instância inteira. Use só por períodos curtos. Em APEX hospedado (Autonomous), normalmente o desenvolvedor do workspace não tem essa role; prefira debug por sessão ou por URL.

Fonte: [Controlling the Debug Level for an Instance](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/controlling-the-debug-level-for-an-instance.html)

### APEX_DEBUG: ENABLE/DISABLE e mensagens (ERROR, WARN, INFO, ENTER, TRACE, MESSAGE, LOG_LONG_MESSAGE)

O pacote `APEX_DEBUG` grava **mensagens próprias da aplicação** no *APEX Debug Log*, ao lado das mensagens do engine.

**Ligar e desligar na chamada:** `APEX_DEBUG.ENABLE` (aceita o nível) e `APEX_DEBUG.DISABLE`. Basta chamar `ENABLE` **uma vez** para valer durante toda a requisição APEX.

**Server-side:** as mensagens só são gravadas quando o debug está ligado na sessão ou na instância. Podem ser usadas em processes, dynamic content regions e packages.

| API | Nível | Uso |
|---|---|---|
| `APEX_DEBUG.ERROR` | 1 | Erro irrecuperável |
| `APEX_DEBUG.WARN` | 2 | Erro recuperável |
| `APEX_DEBUG.INFO` | 4 | Status de processo ou operação |
| `APEX_DEBUG.ENTER` | 5 | Nome e parâmetros do método; tipicamente a 1ª linha do `begin` |
| `APEX_DEBUG.TRACE` | 6 | Detalhe fino |
| `APEX_DEBUG.MESSAGE` | variável | Quando o nível só é conhecido em runtime |
| `APEX_DEBUG.LOG_LONG_MESSAGE` | — | Mensagem com mais de 4.000 caracteres |

```sql
procedure registrar_movimentacao(p_id_colaborador in number, p_id_empresa in number) is
begin
  apex_debug.enter('registrar_movimentacao',
                   'p_id_colaborador', p_id_colaborador,
                   'p_id_empresa',     p_id_empresa);
  -- ...
  apex_debug.info('Movimentação gravada para %s', p_id_colaborador);
exception
  when others then
    apex_debug.error('Falha em registrar_movimentacao: %s', sqlerrm);
    raise;
end;
```

Assinaturas (API Reference): `APEX_DEBUG.INFO(p_message, p0 … p9, p_max_length DEFAULT 1000)` — cada `%` (ou `%s`) de `p_message` é trocado por `p0`, `p1`…, `%<n>` por `p<n>` e `%%` vira `%`; valores maiores que `p_max_length` são truncados com `~`. `ERROR`, `WARN` e `TRACE` seguem o mesmo formato. `APEX_DEBUG.ENTER(p_routine_name, p_name01, p_value01 … p_name10, p_value10, p_value_max_length DEFAULT 1000)` recebe até 10 pares nome/valor.

**Client-side:** a API JS `apex.debug` instrumenta o JavaScript (inclusive de Dynamic Actions) para escrever no console do navegador **apenas quando o nível de debug adequado estiver ligado**.

Fonte: [Using APEX_DEBUG When Developing Your Application](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-APEX_DEBUG-when-developing-your-application.html) · [INFO Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/INFO-Procedure.html) · [ENTER Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ENTER-Procedure.html)

### Ver mensagens de debug: View Debug, Utilities > Debug Messages e purge

- **Pela app:** *Developer Toolbar > Debug > View Debug* (ou pelo ícone *Find* da toolbar, aba *Debug* do Item Finder). Clique no **View Identifier** da requisição. Um gráfico acima do relatório destaca os passos mais demorados; passe o mouse para ver detalhes e clique na barra para ir ao passo.
- **Por Utilities:** *Aplicação > Utilities > Debug Messages*, com a lista de todas as mensagens da app e o *View Identifier*.
- **Purge Debug Messages:** *Purge all messages*, *Purge messages by age* (Older than N dias ou semanas), *Purge current session messages* ou *Purge by View Identifier*.
- **Retenção:** as sessões de debug ficam **pelo menos 2 semanas** e expiram junto com o activity log.

Fonte: [Viewing Debug Messages](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/viewing-debug-messages.html)

### Consultar debug por SQL: APEX_WORKSPACE_ACTIVITY_LOG.DEBUG_PAGE_VIEW_ID e APEX_DEBUG_MESSAGES

Funciona em instâncias de desenvolvimento e também nas runtime-only. Primeiro, ache o `DEBUG_PAGE_VIEW_ID`:

```sql
select *
  from apex_workspace_activity_log
 where application_id = :APP_ID_ALVO
   and page_id        = :PAGINA
 order by view_timestamp desc;
```

Depois, leia as mensagens (a view mostra tudo do workspace atual):

```sql
select *
  from apex_debug_messages
 where page_view_id = :DEBUG_PAGE_VIEW_ID
 order by message_timestamp asc;
```

A coluna de mensagem é a que mais interessa. Isso pode ser rodado no **SQL Commands** do SQL Workshop, o que é útil no Autonomous, onde os scripts de debug do servidor não existem.

Fonte: [Viewing Debug Messages](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/viewing-debug-messages.html)

### Scripts de debug apex/utilities/debug (d0, d1, ds, d2, activity): indisponíveis no Autonomous

A distribuição do APEX traz scripts em `apex/utilities/debug`, que exigem `SYSDBA`. **Eles não estão disponíveis no APEX do Autonomous AI Database.**

| Script | Função |
|---|---|
| `activity.sql` | Últimas entradas do activity log (`@activity help` mostra o uso) |
| `d0.sql` | Alterna entre debug desligado e `LEVEL9` **na instância inteira** (impacta todos; desligue logo) |
| `d1.sql` | Últimas 30 requisições com debug e seus `PAGE_VIEW_ID` |
| `ds.sql <SESSION_ID>` | Requisições com debug de uma sessão APEX |
| `d2.sql <PAGE_VIEW_ID>` | Grava os detalhes em arquivo e abre no editor (`define _editor=vim`) |

Fluxo típico: `@d0` (liga), reproduzir o problema, `@d0` (desliga), `@d1` ou `@ds`, `@d2 <id>`.

Fonte: [Viewing Debug Messages](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/viewing-debug-messages.html)

### Depurar uma sessão pela UI quando não há scripts (ex.: erro no login SSO, APEX_AUTHENTICATION.CALLBACK)

Esta é a alternativa aos scripts, útil no Autonomous. A doc usa como exemplo um erro no retorno do login SSO:

1. Garanta uma **página pública** (crie uma Blank Page com *Security > Authentication = Page is Public*) e rode-a para abrir uma sessão APEX.
2. Na aba de desenvolvimento, vá em *Administration > Monitor Activity > Active Sessions*, clique na sessão e, em **Session Attributes > Debug Level**, escolha **APEX Trace (LEVEL9)**. Clique em *Apply Changes*. A partir daí, cada requisição da sessão é registrada, inclusive `APEX_AUTHENTICATION.CALLBACK`.
3. Na app, navegue até uma página protegida, faça login no SSO e continue até a página de erro.
4. Volte ao *Session Details*, abra a região *Page View* (Go) e clique no **Debug ID** da requisição com erro. O conteúdo equivale ao do `d2.sql`. Em *Actions > Columns*, inclua **Call Stack**.

Apague a página pública de debug quando terminar.

Fonte: [Viewing Debug Messages](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/viewing-debug-messages.html)

### Escolher o Page View ID certo e compartilhar a saída de debug (Rendering, Processing, AJAX, modal)

- **Nível:** comportamento da app → `LEVEL6`; engine ou planos de execução → `LEVEL9`. Em `LEVEL9`, inclua a coluna **Call Stack** (essencial para o Oracle Support).
- **Qual page view escolher:**
  - Problema na renderização: a última page view do tipo **Rendering**.
  - Problema no submit (botão): a última do tipo **Processing**.
  - Problema intermediário (partial page refresh, gráfico, ação AJAX): a última do tipo **AJAX**.
  - **Modal dialogs são páginas separadas**: procure pelo número da página do diálogo, não da página-mãe.
- **Exportar:** no relatório interativo, use *Actions > Download* em **HTML** ou **Excel**, os formatos mais úteis para revisão offline. Sem App Builder, use `d2.sql`.

Fonte: [Viewing Debug Messages](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/viewing-debug-messages.html)

### Session State: revisar valores pela Developer Toolbar (Session)

O session state guarda valores do usuário entre páginas, e muitos comportamentos dependem dele (ex.: um botão condicional). O link **Session** da Developer Toolbar mostra o estado atual. Para a gestão do session state em nível de workspace e de instância, veja a Administration Guide.

Fonte: [Reviewing Session State](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/reviewing-session-state.html)

### Isolar o problema: Comment Out/Uncomment (build option Commented Out) e Server-side Condition Never

Remova controles e componentes um a um até achar o culpado:
- **Comment Out / Uncomment:** menu de contexto do Page Designer (abas Rendering, Dynamic Actions e Processing), disponível em apps criadas a partir do 23.2. Ele usa a build option **Commented Out**. Se o menu não aparecer, defina a build option em *Property Editor > Configuration > Build Option*.
- **Server-side Condition = Never:** impede o componente de renderizar ou executar, mas **apaga a condição que já existia**. Para desligar temporariamente, a Oracle prefere a **build option**.

Fonte: [Removing Controls and Components to Isolate a Problem](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/removing-controls-and-components-to-isolate-a-problem.html)

### Monitorar recurso por app e página: DBMS_APPLICATION_INFO, V$SESSION e V$SQLAREA

Ao renderizar ou processar uma página, o engine chama `DBMS_APPLICATION_INFO` e define o *module* como `APEX`, com o application ID e o número da página. Com isso dá para consultar `V$SESSION` e `V$SQLAREA` e ver o que cada app ou página consome. Isso exige privilégio de leitura em views `V$`, que no Autonomous dependem dos grants do usuário.

Fonte: [About Monitoring Application and Page Resource Use](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-monitoring-application-and-page-resource-use.html)

### SQL trace de uma requisição: p_trace=YES e TKPROF

Cada requisição de página é uma sessão de banco. Com `p_trace=YES` na URL `f?p`, o APEX gera um trace file:

```
http://.../f?p=100:1&p_trace=YES
```

Para analisar:
1. No SQLcl, como usuário privilegiado, rode `show parameter USER_DUMP_DEST`.
2. Vá ao diretório do trace.
3. Rode `tkprof <entrada> <saida> [waits=yes|no] [sort=...] [explain=user/senha] ...`. Só a entrada e a saída são obrigatórias.

Restrições: com build status *Run Application Only*, não é possível usar `p_trace=Yes`. O acesso ao sistema de arquivos do servidor costuma não existir em ambiente gerenciado (Autonomous), então lá a opção prática é o debug `LEVEL9`, que inclui planos de execução.

Fonte: [Enabling SQL Tracing and Using TKPROF](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/enabling-sql-tracing-and-using-tkprof.html) · [Exporting an Application](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/exporting-an-application.html)

### APEX Advisor: checar integridade, segurança, performance e acessibilidade antes do deploy

O **Advisor** funciona como um compilador ou LINT sobre o metadado da app. Ele aponta erros, problemas de segurança, gargalos de performance, itens de QA, boas práticas, checagens de **acessibilidade** e uso de atributos **deprecated** (útil depois de upgrade).

- **App inteira:** *Aplicação > Utilities > Advisor*. Ajuste *Checks to Perform*, informe *Page(s)* (lista separada por vírgula; vazio = todas) e clique em **Perform Check**. As configurações ficam salvas para a próxima vez. Para refinar o resultado, use *Filter Result > Apply Filter*.
- **Uma página:** *Page Designer > menu Utilities > Advisor*.

Fonte: [Running Advisor to Check Application Integrity](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/running-advisor-to-check-application-integrity.html)

### Debug não aparece para o usuário final (opção Debug ausente ou ignorada)

**Sintoma:** um usuário que não é desenvolvedor adiciona `debug=YES` na URL, mas nada é registrado ou o debug não liga.
**Causa:** o atributo **Debugging** da aplicação está em `No`, ou a app foi exportada e importada com *Debugging = No*. Só desenvolvedores logados no workspace ignoram essa trava.
**Correção:** para investigar a sessão de um usuário específico, use `APEX_SESSION.SET_DEBUG` ou o *Session Detail* em Monitor Activity, que funcionam com qualquer valor do atributo. Evite ligar Debugging = Yes em produção.

Fonte: [Enabling and Disabling Debug Mode for an Application](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/enabling-and-disabling-debug-mode-for-an-application.html) · [Using APEX_DEBUG When Developing Your Application](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-APEX_DEBUG-when-developing-your-application.html)

### Mensagens APEX_DEBUG do meu código não aparecem no Debug Log

**Sintoma:** chamadas `apex_debug.info(...)` em processes ou packages não aparecem em *View Debug*.
**Causa:** o debug não está ligado na sessão nem na instância (as APIs só gravam com debug ativo), ou o nível ligado é menor que o da mensagem (ex.: `TRACE` é nível 6 e não aparece em `YES`, que é nível 4).
**Correção:** ligue o debug com um nível suficiente (`LEVEL6` para `TRACE`) pela toolbar, pela URL, por `APEX_DEBUG.ENABLE` ou por `APEX_SESSION.SET_DEBUG`. Procure no *Page View* certo: Processing para submit, AJAX para Dynamic Actions e refresh, e a página do modal para diálogos.

Fonte: [Using APEX_DEBUG When Developing Your Application](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-APEX_DEBUG-when-developing-your-application.html) · [Available Debug Levels](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/available-debug-levels.html) · [Viewing Debug Messages](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/viewing-debug-messages.html)

### App lenta depois de ligar debug (LEVEL9 ou SYSTEM_DEBUG_LEVEL esquecido)

**Sintoma:** páginas e o App Builder ficam lentos para todos os usuários.
**Causa:** o debug instance-wide (`SYSTEM_DEBUG_LEVEL`, `d0.sql`) ou o `LEVEL9` ficou ligado, gerando um volume enorme de mensagens.
**Correção:** `APEX_INSTANCE_ADMIN.SET_PARAMETER('SYSTEM_DEBUG_LEVEL', NULL)` (ou `@d0` de novo), ou desligue o debug na sessão. Depois, faça purge das mensagens em *Utilities > Debug Messages*.
**Prevenção:** prefira `LEVEL6` ou menos e debug por sessão; ligue o debug de instância só por pouco tempo.

Fonte: [Controlling the Debug Level for an Instance](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/controlling-the-debug-level-for-an-instance.html) · [Viewing Debug Messages](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/viewing-debug-messages.html)

## 14. Performance da aplicação

### Boas práticas de performance: bind variables e monitoramento (Monitor Activity, APEX_WORKSPACE_ACTIVITY_LOG)

- Use **bind variables** (`:P1_ITEM`) em SQL e PL/SQL (processes, validations). É a forma mais eficiente de ler session state. Evite substituições `&ITEM.` dentro de SQL.
- Acompanhe o tempo de renderização em *Workspace Administration > Monitor Activity* ou consultando `APEX_WORKSPACE_ACTIVITY_LOG`. Esses dados só existem com o **activity logging** da app ligado.

Fonte: [About Best Practices to Improve Performance](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-best-practices-to-improve-performance.html)

### Identificar gargalos: onde está a lentidão e passo a passo de diagnóstico

1. Compare o tempo que o **banco** leva para responder à requisição com o tempo total no navegador. Se o banco for rápido, o problema está em outro lugar: cliente, rede, middle-tier, disco. No banco, confira SGA, CPU, locks, parâmetros e outras cargas (batch, jobs, DW).
2. Na maioria das vezes, a culpa é do **SQL e PL/SQL escritos pelo desenvolvedor**, e não de bug do APEX ou do banco. Use as técnicas normais de tuning.
3. Roteiro: identificar a janela de tempo → isolar os maiores consumidores de DB time → identificar workspace e app → correlacionar o SQL com o ponto da app → rodar as páginas lentas em **Debug** para ver os componentes que mais consomem.
4. Teste a query fora da app (SQLcl, SQL Developer ou **SQL Commands**) para isolar o problema.
5. Query que já está otimizada e ainda passa de 1 s: mostre uma barra de progresso e impeça submit duplicado (atributo da página *Advanced > Enable duplicate page submissions*). Cada submit repetido abre uma nova execução no banco e pode causar locks, principalmente com Interactive Reports. Alternativa: guardar o resultado em **APEX collections**, para que a query cara rode uma vez por usuário e não a cada paginação ou filtro.

Fonte: [Identifying Performance Issues](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/identifying-performance-issues.html)

### Logs e relatórios para achar páginas problemáticas (Monitor Activity e Dashboard)

O engine registra **activity logs** com uso e desempenho. *Administration > Monitor Activity* tem:
- **Page Views:** por view, usuário, usuário e hora, app, app e página, dia, hora.
- **Developer Activity:** por desenvolvedor, dia, app, *Application Changes*, utilização de componentes.
- **Sessions:** *Active Sessions* e gráfico por hora.
- **Page View Analysis:** páginas mais vistas, calendário, *By Weighted Page Performance*.
- **Environment:** user agent, browser, SO, cliques externos.
- **Login Attempts:** inclui *Developer Login Summary*.
- **Application Errors**.
- **Workspace Schema Reports:** tablespace, privilégios por schema, *Web Service Activity Log*, entre outros.
- **Archived Activity Report**.

O **Dashboard** do App Builder mostra contagem de apps e páginas, atividade de desenvolvedores nos últimos 2 dias, *Page Events*, *Most Active Pages* e uso de regiões nativas. Para guardar logs para sempre, crie um job que copie o activity log para uma tabela própria; o purge e a retenção são definidos pelo administrador de instância.

Fonte: [Utilizing Logs and Reports](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/utilizing-logs-and-reports.html)

### Activity log da aplicação: atributo Logging e view APEX_ACTIVITY_LOG

- **Ligar:** *Edit Application Definition > Properties > Logging* = Yes registra **cada page view**. Em apps de altíssimo volume, pode valer desligar. Esse atributo só é editável se o *Application Activity Logging* da instância estiver em *Use Application Setting*.
- **`APEX_ACTIVITY_LOG`:** toda a atividade do workspace (desenvolvimento e runtime). Colunas principais:

| Coluna | Significado |
|---|---|
| `time_stamp` | Fim da page view |
| `component_attribute` | Título da página |
| `elap` | Tempo decorrido (s) |
| `num_rows` | Linhas processadas |
| `userid`, `ip_address`, `user_agent` | Quem e de onde (IP e user agent só na 1ª entrada de cada sessão) |
| `ir_report_id`, `ir_search` | Interactive Report e busca digitada |
| `flow_id`, `step_id`, `session_id` | App, página, sessão |
| `sqlerrm` | Mensagem de erro SQL |

Exemplo: page views e tempo médio nas últimas 24 h por usuário.

```sql
select count(*), avg(elap), userid
  from apex_activity_log
 where time_stamp > sysdate - 1
   and flow_id = :APP_ID
 group by userid;
```

Pegadinha: o log **gira entre duas tabelas**, então o histórico vai só até a entrada mais antiga ainda disponível. Para guardar para sempre, copie para uma tabela própria ou faça o log na própria aplicação.

Fonte: [Creating Custom Activity Reports Using APEX_ACTIVITY_LOG](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-custom-activity-reports-using-apex_activity_log.html)

### Relatórios do banco: APEX_PUBLIC_USER, V$SESSION, AWR/ASH e roles APEX_ADMINISTRATOR_READ_ROLE

- O ORDS conecta pelo pool como `APEX_PUBLIC_USER`, que chama o engine. O engine usa `SYS.DBMS_SYS_SQL` para fazer o parse como o **parsing schema**. Em `V$SESSION`, *client info*, *client identifier* e *module* trazem dados do APEX, o que ajuda a localizar o SQL em traces (TKPROF). Também dá para usar `&p_trace=YES` ou `ALTER SESSION`.
- **AWR** (snapshot por hora, por padrão) e **ASH** identificam SQL caro. O **PL/SQL hierarchical profiler** mede PL/SQL aninhado.
- As views do APEX podem ser consultadas por SQL Developer, SQLcl ou SQL Commands. Com `APEX_ADMINISTRATOR_READ_ROLE` (para monitoramento) ou `APEX_ADMINISTRATOR_ROLE` (para instance admins), a consulta cobre a instância inteira, e não só o workspace.

Fonte: [About Utilizing Database Reporting](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-utilizing-database-reporting.html)

### Parâmetros de banco, Resource Manager e static files no web server

- **Memória:** revise `MEMORY_TARGET`, `SGA_TARGET`, `PGA_AGGREGATE_TARGET` e `SHARED_POOL_SIZE`. A SGA deve caber na RAM; uma SGA pequena derruba o APEX, que precisa de shared pool para PL/SQL e de buffer cache para o metadado. Colete **estatísticas no schema `APEX_260100`**.
- **Resource Manager** (opção da Enterprise Edition): limita `CPU_PER_CALL` e `LOGICAL_READS_PER_CALL` e troca de perfil automaticamente (ex.: APEX_HIGH 70% de CPU por 10 s → APEX_MEDIUM 8% por 120 s → APEX_LOW 2% por 1800 s → cancelar). O instance admin pode definir perfis por workspace.
- **Static files:** sirva-os pelo web server com **gzip** e cabeçalhos de expiração para cache no navegador.

Em Autonomous, parâmetros de memória e Resource Manager são gerenciados pela Oracle e pelo serviço; o desenvolvedor atua no SQL e PL/SQL.

Fonte: [About Database Parameters that Impact Performance](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-database-parameters-that-impact-performance.html) · [About Limiting Resources](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-limiting-resources.html) · [About Uploading Static Files to Your Web Server](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-uploading-static-files-to-your-web-server.html)

### Usuários reenviam a página lenta e geram locks (submit duplicado)

**Sintoma:** a página demora, o usuário clica de novo, a lentidão piora e aparecem locks.
**Causa:** cada novo submit dispara uma nova execução no banco, que vai até o fim. Isso é comum com Interactive Reports pesados.
**Correção:** otimize a query; desligue *Enable duplicate page submissions* na página; mostre um indicador de progresso; ou guarde o resultado em APEX collections.

Fonte: [Identifying Performance Issues](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/identifying-performance-issues.html)

## 15. Team Development

**Team Development** é o rastreador de *issues* do workspace: issues em formato de conversa, labels, milestones, templates, notificações e o feedback dos usuários finais. Acesso: link na região direita do Workspace home, ou *App Builder > Workspace Utilities > Team Development*.

### Team Development: setup inicial e toolbar

No primeiro acesso, uma tela de boas-vindas oferece *Install Sample Labels*, *Install Sample Templates*, *Install Sample Milestones* e *Sample Data Language*; finalize com **Complete Setup**. A toolbar tem:
- **Notifications**.
- **Jump to:** Issues, View My Profile, Manage Labels, Manage Milestones, Manage Templates, Utilities.
- **New Issue**.

Fonte: [Getting Started with Team Development](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/getting-started-team-development.html) · [Managing Team Development](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-team-development.html)

### Team Development: issues (criar, atualizar em lote, timeline, comentários e anexos)

- **Issues page:** busca por colunas; visões **Cards** (padrão) ou **Grid** (interactive grid); menu *Update* para Status, Assignees, Labels e Milestones de várias issues de uma vez; *Reset*. Regiões de resumo *Open Issues* (Total/Owned/Assigned/Subscribed) e *Feedback*.
- **Criar:** *New Issue*, com um template ou *Continue without a template*, título e *Issue Text* em Markdown com *Preview*.
- **Issue Details:** uma **Issue Timeline** de eventos, com os mais novos no topo. O menu *Actions* tem Edit Title, Edit Issue Text, Set Assignees, Set Labels, Set Milestones, Associate App or Page, Mark as Duplicate, Delete Issue e Close/Reopen Issue. Só o dono da issue ou um admin muda título e texto ou apaga a issue. *Subscribe* liga as notificações.
- **Comentários:** *Add Comment* aceita template de resposta, Markdown e *Attach Files* (este último só se o workspace tiver *Enable Issue File Repository*). Editar e apagar é permitido ao autor e ao admin; esconder (*Hide*), só ao admin.
- **Assignees** são usuários do workspace. **Milestones** mudam de cor: vermelho se já passou, amarelo se faltam menos de 2 semanas, verde se faltam mais de 2 semanas.
- **Apagadas:** ficam em *Utilities > Manage Deleted Issues*, com *Reinstate Selected*, *Permanently Delete Selected* e *Purge All*.

Fonte: [Issues Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/issues-page.html) · [Creating an Issue](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-an-issue.html) · [Issue Details Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/issue-details-page.html) · [Managing Comments](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-comments.html) · [Setting Milestones](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/setting-milestones.html) · [Managing Deleted Issues](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-deleted-issues.html)

### Team Development: labels, milestones, templates e notificações

- **Label groups** têm cor e podem ser **exclusivos** (uma label do grupo por issue; aplicar outra substitui a anterior) ou não. Exemplos de amostra: *Importance* (exclusivo: Critical, Important, Normal, Backlog, Will Not Address) e *Functional Area* (não exclusivo: Bug, Enhancement Request, Security Issue, Performance Issue…). As labels são editadas num interactive grid (Sequence, Name, Slug, Desc).
- **Milestones:** Name, Slug (usado em URLs), Date, Status Open/Closed e Description.
- **Templates:** tipo *Issue* (issue nova) ou *Response* (comentário), em Markdown.
- **Notificações:** cada interação gera um **evento**, e as notificações são o registro desses eventos. Preferências: *Receives Emails*, *Frequency* (Immediately, Hourly Summary, Daily Summary) e tipos de evento. Admins gerenciam as preferências de todos em *Utilities > Manage User Notification Preferences*.

Fonte: [Managing Labels](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-labels.html) · [Managing Milestones](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-milestones.html) · [Managing Templates](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-issue-templates.html) · [Managing Notification Preferences](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-notification-preferences.html) · [Viewing Your User Profile](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/viewing-your-user-profile.html)

### Team Development Utilities (admin): purge, reatribuição em massa e arquivos

Em *Jump to > Utilities*, só para quem é admin:
- Manage Deleted Issues, Templates, Milestones e Labels.
- **View Files:** baixar arquivos; apagar só como admin.
- **Purge Data:** apaga **todos** os dados dos componentes selecionados.
- **Update Assignees** e **Reassign Owner:** de um usuário para outro, só nas issues abertas ou em todas. Aparece *Orphan* para usuários APEX removidos.
- **Remove Milestone from All Issues** e **Remove Labels from All Issues**.
- Manage User Notification Preferences.

Fonte: [Team Development Utilities](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/utilities-page.html) · [Purging Data](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/purging-data.html) · [Reassigning Issues to Another Assignee](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/reassigning-issues-to-another-assignee.html) · [Reassigning the Issue Owner](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/reassigning-the-issue-owner.html) · [Managing Uploaded Files](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/manging-uploaded-files.html)

### Feedback de usuários finais: página Feedback, Administration e acompanhamento no Team Development

O **Feedback** captura comentários, pedidos e bugs vindos dos usuários, junto com contexto de sessão: app, página, data, usuário.
- **Adicionar:** pela *Feature Feedback* no Create Application Wizard, ou por *Create Page > Feature > Feedback Report*, que cria várias páginas a partir de um número inicial, com build option, entrada na navigation bar e lista na página de Administration.
- **Usuário:** usa o ícone *Feedback* na navigation bar; escolhe a experiência (Positive, Neutral ou Negative), escreve o comentário e anexa arquivo.
- **Na app:** *Administration > User Feedback*, com Response e Status (No Action, Acknowledged, Open, Closed). Em *Feedback Settings > Enable Attachments*, os anexos só funcionam se o workspace tiver **Enable Feedback File Repository = Yes**.
- **Team Development > Feedback:** Dashboard, Report, By Filing User e Calendar. Em cada entrada: *Type* (General Comment, Enhancement Request, Bug), *Disposition* (Log as Bug, To Do, Feature ou Issue) e *Status* (0 No Status a 4 Closed).
- O feedback é exportado e importado entre ambientes pelo Export de feedback (ver seção 11).

Fonte: [Managing Feedback](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-feedback.html) · [Tracking Feedback](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/tracking-feedback.html)

## 16. Upgrade de aplicações (Upgrade Application)

Instalar uma nova versão do APEX atualiza as apps existentes, que **continuam funcionando sem mudança**, mas a UI e os componentes não são alterados. Para manter a app atualizada e aproveitar as novidades, faça os passos abaixo depois de cada upgrade de instância ou depois de importar uma app exportada de versão anterior. **Teste a app depois de cada passo.**

### Depois do upgrade: Release Notes (Changed Behavior, Deprecated, Desupported)

Revise nas Release Notes:
- **Changed Behavior**.
- **Deprecated Features:** ainda funcionam, mas serão removidas; comece a migrar.
- **Deprecated in Previous Releases**.
- **Desupported Features:** não existem mais, e apps que dependem delas podem quebrar.
- **Desupported in Previous Releases**.

Rode o **Advisor** para localizar atributos deprecated.

Fonte: [Upgrading Oracle APEX Applications](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/upgrading-apex-applications.html)

### Refresh do Universal Theme e Compatibility Mode

- **Refresh Theme:** se o Universal Theme estiver desatualizado, o Application home mostra um banner ("There is a new version of Universal Theme available!…"); clique em **Refresh Theme**. Faça backup antes, exportando ou copiando a app.
- **Compatibility Mode** (*Edit Application Definition > Definition > Properties*): controla a compatibilidade do engine de runtime com comportamentos antigos. O upgrade ajusta esse valor sozinho quando necessário, para não quebrar nada. Depois de revisar o *Changed Behavior* e adaptar a app, defina-o com a versão atual.

Fonte: [Upgrading Oracle APEX Applications](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/upgrading-apex-applications.html)

### Application Upgrade Wizard (Utilities > Upgrade Application)

Atualiza componentes em massa para aproveitar novos recursos (ex.: *Update Button Dynamic Actions to Trigger Actions*). Acesso: notificação **New Features Available** na side bar do Application home (*View Details*), ou *Utilities > Upgrade Application*. A tela lista os tipos de upgrade e a quantidade de objetos. Selecione um tipo ou abra *Details*, marque os objetos e clique em **Update**. Repita até zerar. Quando ao menos um tipo é aplicado, a notificação some da home, mas a página continua acessível por Utilities.

Fonte: [Upgrading Oracle APEX Applications](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/upgrading-apex-applications.html)

### JavaScript legado: Include Deprecated or Desupported Javascript Functions e Include jQuery Migrate

Em *Edit Application Definition > User Interface > JavaScript*:
- **Include Deprecated or Desupported Javascript Functions:** escolha as versões cujas funções antigas devem ser carregadas. Se a app não usa nenhuma, não selecione nada, o que reduz o JS carregado.
- **Include jQuery Migrate:** restaura APIs antigas do jQuery e registra avisos no console. O jQuery 3.x quebra a compatibilidade com o 2.x; APIs do jQuery 1.x removidas **não funcionam mais desde o APEX 18.1**, e o código precisa usar jQuery 3.5+. Desligue se não precisar, porque isso melhora a performance.

Fonte: [Upgrading Oracle APEX Applications](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/upgrading-apex-applications.html)

## 17. Estrutura de diretórios ao dividir o export em scripts

### Split export: nomes de arquivos, install.sql, set_environment.sql e patch incremental

Dividir o export (*Split into Multiple Files* na aplicação, *Export as Zip* em páginas e componentes) gera um ZIP com um arquivo por página e componente. Vantagens:
- Commit só do que mudou no Git ou SVN.
- **Deploy incremental**: rodar no destino só o arquivo com a correção.

Nomes:
- App: `f326.sql` ou `f326.zip`.
- Página: `f326_page_4.sql` ou `.zip`.
- Componentes: `f326_components.sql` ou `.zip`.
- Componentes individuais usam o nome dado no App Builder, sem caracteres especiais e com espaços trocados por `_`. **Renomear o componente muda o nome do arquivo** (`menu.sql` → `main_menu.sql`), e cabe a você fazer o `git mv` para manter o histórico.

Instaladores gerados: `install.sql` (app), `install_page.sql` (página), `install_component.sql` (componente), mais `set_environment.sql` e `end_environment.sql`. Esses dois definem variáveis internas e fazem as checagens de segurança **uma única vez** por import; sem eles, cada arquivo repete as checagens. Exemplo de patch customizado:

```
@@application/set_environment.sql
@@application/pages/page_00001.sql
@@application/pages/page_00023.sql
@@application/end_environment.sql
```

Fonte: [Splitting Export Files into Separate SQL Scripts](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/splitting-export-files-into-separate-sql-scripts.html)

### Mapa de diretórios do export dividido (application/pages, shared_components, workspace)

A estrutura é a mesma tanto para *Split into Multiple Files* quanto para *Export as Zip*:

| Componente | Diretório |
|---|---|
| Supporting Objects | `application/deployment` |
| Páginas / Page Groups | `application/pages` / `application/pages/page_groups` |
| Plug-in Settings | `application/plugin_settings` |
| Data Loading / Data Profiles | `application/shared_components/data_loading/tables` / `.../data_profiles` |
| Email Templates | `application/shared_components/email/templates` |
| Application Static Files | `application/shared_components/files` |
| Text Messages | `application/shared_components/globalization/messages` |
| App Computations / Items / Processes / Settings | `application/shared_components/logic/application_{computations,items,processes,settings}` |
| Build Options / Build Option Status | `application/shared_components/logic/build_options` / `.../build_options/status` |
| Web Services | `application/shared_components/logic/webservices` |
| Breadcrumbs / entradas | `application/shared_components/navigation/breadcrumbs` / `.../breadcrumbentry` |
| Lists / Navigation Bar / Tabs / Trees | `application/shared_components/navigation/{lists,navigation_bar,tabs/parent,tabs/standard,trees}` |
| Plug-ins | `application/shared_components/plugins` |
| PWA Screenshots / Shortcuts | `application/shared_components/pwa/{screenshots,shortcuts}` |
| Report Layouts / Queries | `application/shared_components/reports/{report_layouts,report_queries}` |
| Access Control Roles / Authentications / Authorizations | `application/shared_components/security/{app_access_control,authentications,authorizations}` |
| LOVs / Shortcuts | `application/shared_components/user_interface/{lovs,shortcuts}` |
| Templates (breadcrumb, button, calendar, label, list, page, popuplov, region, report) | `application/shared_components/user_interface/templates/<tipo>` |
| REST Data Sources | `application/shared_components/web_sources` |
| Concatenated Files | `application/user_interfaces/combined_files` |
| Credentials / Workspace Static Files / Remote Servers | `workspace/credentials` / `workspace/files` / `workspace/remote_servers` |

Essa estrutura é a do **export SQL** dividido. O layout do **APEXlang** (`.apx`) é outro e está documentado na referência APEXlang.

Fonte: [Directory Structure When Splitting Export Files into Separate Scripts](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/directory-structure-when-splitting-export-files.html)
## 18. Acessibilidade (Accessibility Guide)

O *Accessibility Guide* tem duas metades: como usar o próprio APEX com teclado e leitor de tela (JAWS) e como construir apps acessíveis. A referência normativa é a WCAG 2.1 (princípios: perceptível, operável, compreensível e robusto). A Oracle registra o grau de conformidade do produto (Section 508, WCAG) no *Accessibility Conformance Report* (ACR). O guia vale para o **Universal Theme** e não cobre temas customizados.

### Acessibilidade: responsabilidade do desenvolvedor e onde achar ajuda no Page Designer
- O framework é testado para acessibilidade, mas a conformidade da **sua** app é responsabilidade sua: conhecer as diretrizes exigidas, conhecer os defeitos conhecidos do APEX (no ACR) e testar por conta própria.
- No Page Designer, a aba **Help** de vários atributos traz um bloco "Accessibility" (marcado com ícone), com orientação sobre alt text, contraste, row headers de relatórios, labels e descrições. Consulte esse bloco sempre que configurar um desses atributos.
- Na UI do Builder, `Alt+F1` (Mac `Option+F1`) abre a ajuda do campo em foco, incluindo as orientações de acessibilidade.

Fonte: [About This Accessibility Guide](https://docs.oracle.com/en/database/oracle/apex/26.1/aeacc/about-accessibility.html), [Accessibility Help Text in APEX](https://docs.oracle.com/en/database/oracle/apex/26.1/aeacc/accessibility-help-text.html), [Testing Apps for Accessibility](https://docs.oracle.com/en/database/oracle/apex/26.1/aeacc/testing-apps-for-accessibility.html)

### Universal Theme, Theme Styles acessíveis e checagem de contraste no Theme Roller
- A Oracle recomenda o **Universal Theme** (Theme 42) para apps acessíveis e sugere migrar temas antigos para ele.
- **Theme Style**: o estilo padrão **Vita** é o recomendado e já vem marcado como *accessibility tested*. Você pode marcar um estilo próprio como *accessibility tested* quando tiver certeza de que ele atende às normas da sua organização. O Advisor avisa quando o estilo em uso não tem essa marca.
- **Theme Roller** verifica o contraste das combinações de cor contra a WCAG 2.0 e mostra um check com a razão de contraste quando o mínimo é atingido. Se uma cor customizada reprovar, ajuste-a antes de publicar.
- Pegadinha: CSS próprio (tokens, `custom.css`) **não** passa por essa checagem. Valide o contraste manualmente.

Fonte: [Themes](https://docs.oracle.com/en/database/oracle/apex/26.1/aeacc/developing-accessible-themes.html)

### Páginas acessíveis: Title, Page Mode, Cursor Focus e Reload on Submit
| Atributo | Recomendação | Por quê |
|---|---|---|
| *Identification > Title* | Título único e significativo; em forms, inclua o registro: `Editar Colaborador: &P13_NOME.` (com o ponto final) | O título é a primeira coisa anunciada pelo leitor de tela |
| Processo *Fetch Row* (form) | Se o título usa item do registro, mude o ponto de execução de *After Header* para **Before Header** | Senão o item ainda está vazio quando o título é renderizado |
| *Page Mode* | *Normal*, *Modal Dialog* e *Non-Modal Dialog* são todos acessíveis | O modal prende o foco do teclado e isola o leitor de tela da página base |
| *Navigation > Cursor Focus* | Padrão: *Do not focus cursor*. Use *First item on page* só quando o primeiro campo for obrigatório (ex.: wizard) | Foco inesperado desorienta |
| *Reload on Submit* | **Only for Success** | Os erros aparecem no cliente sem recarregar a página e são anunciados na hora (ARIA `role=alert`). Tabular forms só aceitam *Always* |

Dica: o utilitário **Page Attributes** (cross page utilities) lista os títulos de todas as páginas, o que ajuda a achar títulos nulos ou repetidos.

Fonte: [Pages](https://docs.oracle.com/en/database/oracle/apex/26.1/aeacc/pages.html)

### Regiões: landmarks (Use Landmark, Landmark Type, Landmark Label)
Landmarks complementam os headings e expõem a estrutura da página: *Banner*, *Navigation*, *Main*, *Complementary*, *Content Info*, *Form*, *Region* e *Search*. *Banner*, *Main* e *Content Info* normalmente vêm do page template, uma vez por página. O tipo mais comum em regiões é *Region*.

Atributos da região no Page Designer:
- **Use Landmark**: liga ou desliga a exposição da região como landmark. Desligue em regiões que só servem de layout.
- **Landmark Type**: o padrão do template ou um tipo customizado.
- **Landmark Label**: por padrão usa o título da região. Um bom label é único na página, curto (até ~3 palavras) e descreve o conteúdo. **Não repita o papel no label**: use "Aplicação" e não "Navegação da aplicação", senão o leitor diz "navegação" duas vezes.

Regras de revisão:
- *Banner*, *Main*, *Complementary* e *Content Info* ficam no topo da hierarquia, nunca aninhados em outro landmark.
- Todo conteúdo perceptível (itens, botões, regiões, menus) deve estar dentro de algum landmark.
- Itens de formulário ficam num landmark *Form*, e a busca num *Search*.
- Com o template option **Header = Hidden**, o APEX entende que o título não deve ser exposto e esconde o landmark.
- Para conferir, use **Developer Toolbar > Show Landmarks**, que mostra tipo e label sobre a página em execução.

**Sintoma:** as opções Use Landmark / Landmark Type / Landmark Label não aparecem na região.
**Causa:** o template da região não define a substitution string `#REGION_LANDMARK_ATTRIBUTES#` em *Template > Definition*. É comum em temas antigos ou em cópias desatualizadas.
**Correção:** faça refresh do Universal Theme para a versão mais recente, que define esses atributos em todos os region templates. Em tema próprio, defina *Default Landmark Type* e *Region Title HTML ID* no template.

Fonte: [Regions](https://docs.oracle.com/en/database/oracle/apex/26.1/aeacc/regions.html)

### Regiões: headings (H1 único, H2 por região, H3 em sub-regiões) e títulos ocultos acessíveis
- **H1**: deve haver um único H1 por página. Por padrão, a última entrada da **Breadcrumb** é o H1. A alternativa é o template de região **Hero**, que renderiza o título como H1 (use só um Hero por página).
- **H2**: a maioria dos region templates do UT envolve o título da região em H2.
- **Sub-regiões**: o template *Standard* também usa H2 nas sub-regiões, o que achata a hierarquia. A saída documentada é duplicar o template *Standard* (*As a Copy of an Existing Template*) e trocar H2 por H3 no Code Editor. A mudança é só estrutural, sem efeito visual.
  - Pegadinha: a cópia mantém a subscription do tema, mas **não** é atualizada automaticamente no refresh. Também é preciso uma cópia por nível adicional (H4, H5…).
- **Título oculto**: nunca deixe a região sem título. Para escondê-lo visualmente, use **Template Options > Header = Hidden but accessible**. Faça o mesmo em região com um único gráfico, para não duplicar o *Chart Title*.
- O utilitário **Edit Region Titles** lista os títulos para revisão.

Fonte: [Regions](https://docs.oracle.com/en/database/oracle/apex/26.1/aeacc/regions.html)

### Relatórios acessíveis: Value Identifies Row, links de edição por linha e template components
- **Value Identifies Row** (atributo de coluna em Classic Report, Interactive Report e Interactive Grid) define as colunas usadas como *row header*. O leitor de tela as anuncia ao entrar em cada linha. Exemplo: o nome do colaborador. O Advisor sinaliza regiões sem row header.
- **Link de edição**: o "Edit" padrão gerado por *Report and Form* é igual em todas as linhas. Personalize o alt text do ícone com uma substituição da linha, por exemplo `Editar colaborador: #NOME#`, em *Attributes > Link > Link Icon* (com *Link Column = Link to Single Row View / Link to Custom Target*). Como o link não tem texto visível, o alt da imagem vira o texto do link.
- **Interactive Report**: gera automaticamente um SUMMARY com região, relatório salvo, view e faixa de linhas. Com seleção de linhas, ligue *Value Identifies Row* e **não esconda** o controle de seleção.
- **Classic Report**: o SUMMARY padrão é o título da região.
- **Template Component (report)**: use o markup de layout grid com `APEX$TITLE`, como `<div role="grid" aria-label="#APEX$TITLE# grid" ...>`. Com *Value Identifies Row*, o `aria-label` é sempre renderizado. Se o seletor for checkbox, defina `accLabelColumn` para evitar label duplicado.
- **Interactive Grid**: tudo que se faz com o mouse também se faz pelo teclado (modos Navigation e Edit; ver §20).

Fonte: [Regions](https://docs.oracle.com/en/database/oracle/apex/26.1/aeacc/regions.html)

### Gráficos JET, Carousel e Workflow Diagram: configurações que afetam acessibilidade
- **JET Chart**: o *Chart Title* é o label acessível da seção do gráfico. O **Tooltip** (*Show = Yes*) é o label anunciado em cada ponto. Ajuste *Show Series Name*/*Group Name*/*Value*/*Label*, por exemplo escondendo o nome da série quando só há uma, ou use uma coluna de tooltip customizada no nó *Series*. **Evite *Automatic Refresh*:** o refresh automático atrapalha muito quem usa tecnologia assistiva.
- **Carousel Container** (UT): mantenha o template option **Timer = No Timer**. Com intervalo, o usuário não consegue pausar a animação.
- **Workflow Diagram**: a região **não** é acessível a leitores de tela. Ofereça a mesma informação em outra forma, como relatório ou lista de atividades.

Fonte: [Regions](https://docs.oracle.com/en/database/oracle/apex/26.1/aeacc/regions.html)

### Itens de formulário: labels, templates Hidden/Required, Value Required e alt text de imagens
- Todo item precisa de **label** significativo. O *Value Placeholder* sozinho não basta: o Advisor reprova.
- Templates de label do UT:
  - **Hidden**: esconde visualmente e mantém o label no markup. Prefira-o a deixar o label vazio.
  - **Optional / Optional - Above**: sem decoração.
  - **Required / Required - Above**: mostra o asterisco, mas o leitor de tela ignora o asterisco e ouve "Label (Value Required)". O texto vai no fim, para que a busca por nome do campo continue funcionando.
- **Value Required = Yes** combinado com o template *Required* faz o estado obrigatório ser anunciado duas vezes. A Oracle não recomenda isso por acessibilidade e sugere uma validação do tipo **Not Null** no item para o caso simples.
- **Select List / Radio Group com *Page Action on Selection*** (submit ou redirect na mudança) causa uma mudança de contexto inesperada. Prefira uma **Dynamic Action on Change** que dê refresh na região, uma *cascading LOV* ou um botão explícito. Se não tiver como evitar, avise no label, por exemplo "Selecionar colaborador (recarrega a página)".
- **Display Image**: defina *Alternative Text Column* (quando *Based On = BLOB Column*) ou *Alternative Text* (quando *Based On = Image URL stored in Page Item Value*). Este último aceita `&P1_ALT.`.
- O utilitário **All Page Items** lista labels nulos ou repetidos.
- **Erros de validação**: o APEX renderiza um H2 "n error has occurred" seguido de uma lista. Cada erro ligado a um item vira link que leva o foco ao campo, e o item recebe `aria-invalid="true"` e `aria-describedby="<ITEM>_error"`, de modo que o leitor anuncia a mensagem junto com o campo.

Fonte: [Form Pages and Items](https://docs.oracle.com/en/database/oracle/apex/26.1/aeacc/form-pages-and-items.html), [Accessing Form Pages Using JAWS](https://docs.oracle.com/en/database/oracle/apex/26.1/aeacc/accessing-form-pages-using-jaws.html)

### Botões acessíveis: label, template e Type
- O **label** do botão é o que o leitor de tela anuncia e o que o reconhecimento de voz usa para acioná-lo. Ele precisa ser claro e único na página.
- Os templates **Icon**, **Text** e **Text with Icon** são todos acessíveis: no *Icon*, o label fica escondido visualmente, mas continua no markup.
- O template option **Type** (ex.: *Danger*, vermelho) não pode ser a única pista do significado: o texto precisa explicar a ação. Informação passada só por cor é falha de acessibilidade.
- O utilitário **Page Buttons** serve para revisar os labels.

Fonte: [Buttons](https://docs.oracle.com/en/database/oracle/apex/26.1/aeacc/buttons.html)

### Testes de acessibilidade com o Advisor (página ou aplicação inteira)
Estratégia recomendada: testar durante todo o ciclo, com todo o time, com pessoas de habilidades diferentes e tecnologias assistivas, e com atenção especial a plug-ins e bibliotecas de terceiros. Corrija primeiro o que o **Advisor** apontar e só depois teste com tecnologias assistivas.

Checks de acessibilidade do Advisor:
| Check | O que verifica |
|---|---|
| Theme Style tested for accessibility | O estilo está marcado como *accessibility tested* |
| Page has page title | O título existe (exclui a Global Page e páginas sem regiões) |
| Region has Row Header | Existe coluna com *Value Identifies Row = Yes* |
| Page item has label | O item tem label, não só placeholder |
| Page item does not cause an unexpected context change | O item não faz submit/redirect ao mudar de valor |
| Display Image item has image ALT text defined | O alt text ou a coluna de alt está definido |

Como rodar:
- **Numa página:** *Utilities > Advisor*, ajuste *Checks to Perform* e clique em *Perform Check*. Os resultados podem ser filtrados (*Filter Result > Apply Filter*).
- **Na aplicação:** *App Builder > aplicação > Utilities > Advisor*. Em *Page(s)*, informe uma lista separada por vírgula ou deixe em branco para todas. As preferências ficam salvas para a próxima execução.
- No Page Designer, o atalho é `Ctrl+/, U, A`.

Fonte: [Testing Apps for Accessibility](https://docs.oracle.com/en/database/oracle/apex/26.1/aeacc/testing-apps-for-accessibility.html)

### Tecnologias assistivas: configuração recomendada, PDF acessível e teclado no Builder
- A Oracle recomenda a versão mais recente do **JAWS** com a do **Google Chrome**. Para PDFs exportados (dados de relatórios), recomenda o Adobe Acrobat Reader DC.
- **PDF acessível**: `APEX_UTIL.SET_PREFERENCE(p_preference => 'APEX_PDF_ACCESSIBLE', p_value => 'Y')` adiciona tags de acessibilidade na impressão PDF nativa. O arquivo fica maior, e `'N'` desliga. Ligar *Include Accessibility Tags* no download de IR/IG define essa mesma preferência.
- A UI do APEX pressupõe o layout de teclado **US**. Em outros layouts, teclas de número e símbolos (como `'`) podem não bater.
- Atalhos gerais do Builder:

| Ação | Teclas |
|---|---|
| Lista de atalhos da página | `Alt+Shift+F1` |
| Global Search | `Ctrl+'` |
| Próximo/anterior splitter | `Ctrl+F6` / `Ctrl+Shift+F6` |
| Page Designer: salvar / salvar e rodar | `Alt+F7` / `Alt+F8` |
| Page Designer: ir para Rendering / Dynamic Actions / Processing | `Ctrl+/, R` / `Ctrl+/, A` / `Ctrl+/, P` |
| Page Designer: Property Editor / Messages / Page Search | `Ctrl+/, E, M` / `Ctrl+/, M` / `Ctrl+/, F` |
| Page Designer: próxima/anterior página | `Alt+Shift+PgDn` / `Alt+Shift+PgUp` |
| Expandir/restaurar painel central | `Alt+F11` |
| SQL Commands: executar | `Ctrl+Enter` |
| Code Editor: todos os comandos / Suggest / alternar Tab move foco | `F1` / `Ctrl+Space` / `Ctrl+M` |

Fonte: [Recommended Configuration](https://docs.oracle.com/en/database/oracle/apex/26.1/aeacc/recommended-configuration.html), [Accessing Oracle APEX Using a Keyboard](https://docs.oracle.com/en/database/oracle/apex/26.1/aeacc/accessing-oracle-apex-using-a-keyboard.html)

### Problemas de acessibilidade conhecidos do APEX (ACR)
Os defeitos conhecidos ficam nos **Accessibility Conformance Reports**, separados por área do produto (Development Environment, Components, Documentation…), e não no guia. Exemplos que o próprio guia registra: a região *Workflow Diagram* não é acessível a leitores de tela; *Value Required* combinado com o template *Required* duplica o anúncio do estado obrigatório; tabular forms não aceitam *Reload on Submit = Only for Success*.

Fonte: [Open Bugs and Known Issues](https://docs.oracle.com/en/database/oracle/apex/26.1/aeacc/open-bugs-known-issues.html), [Further Reading](https://docs.oracle.com/en/database/oracle/apex/26.1/aeacc/further-reading.html)

## 19. Data Reporter

### Data Reporter: o que é, tipos de relatório e papéis
**Data Reporter** é um módulo self-service em que usuários de negócio montam "reporting applications" e relatórios sem usar o Page Designer nem escrever SQL. Um administrador agrupa tabelas e views do workspace em **datasets**, e os relatórios são construídos sobre esses datasets.
- Tipos de relatório: **Interactive Report**, **Faceted Search with Table** e **Faceted Search with List**.
- Papéis:
  - **Administrator**: conta de desenvolvedor que gerencia datasets, usuários e apps e monitora a atividade.
  - **Editor**: conta de usuário final que cria e edita relatórios nas apps a que tem acesso.
  - **Viewer**: só vê os relatórios publicados das apps a que tem acesso.
- Quando usar: relatórios ad hoc para áreas de negócio sobre tabelas já existentes. Quando não usar: telas transacionais, regras de negócio ou páginas que exigem filtros de segurança customizados (essas pertencem ao App Builder).

Fonte: [Introduction to Data Reporter](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdr/introduction-to-data-reporter.html)

### Data Reporter: pré-requisitos, acesso e habilitação (authentication scheme, Data Reporter Access)
- **Pré-requisito**: um authentication scheme de instância **SAML**, **Social Sign-In** ou **HTTP Header Variable**. Quem configura é o administrador da instância, e todas as reporting apps herdam o scheme.
- **Acesso de usuário APEX**: precisa ter o privilégio *Administrator*, ou *Developer* mais **Data Reporter Access**. Esse atributo é ligado automaticamente quando se cria um usuário com privilégio de desenvolvedor e é editado em *Workspace Administration > Manage Users and Groups* ou em *Administration Services > Manage Developers and Users*.
- **Por workspace**: *Administration Services > Manage Workspaces > Manage Component Availability > Data Reporter* (Yes/No; vem habilitado por padrão).
- Por onde cada papel entra:
  - Administradores entram pelo login normal do APEX e caem na home do Data Reporter. Não acessam o restante do Builder, a menos que recebam privilégios extras.
  - Editors e Viewers entram pela página de login da própria reporting app, cuja URL aparece no ícone *Run*.
- Para a experiência completa, a Oracle recomenda configurar um **Generative AI Service**.

Fonte: [Disabling and Enabling Data Reporter](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdr/disabling-enabling-data-reporter.html), [Introduction to Data Reporter](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdr/introduction-to-data-reporter.html)

### Data Reporter: datasets (criar, editar colunas, sincronizar, excluir)
- Um dataset é um grupo de tabelas e views no nível do **workspace**. Não dá para excluir um dataset em uso por um relatório, nem remover um objeto referenciado em relatório.
- Atributos de coluna:
  - *Display*, *Value Identifies Row*, *Label*, *Description*, *Format Mask* e *Facet* (inline ou em filter dialog).
  - Uma coluna presente numa tabela e numa view tem atributos independentes em cada uma.
- **Synchronize Columns**: depois de alterar a estrutura de uma tabela ou view, sincronize o dataset object. A página de edição avisa com "needs to be synchronized".
- Existem sample datasets instaláveis pelo SQL Workshop.

Fonte: [Managing Datasets](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdr/managing-datasets.html)

### Data Reporter: reporting applications e relatórios (publicação, draft, drill down, IA)
- **App**: tem nome, alias, descrição (gerada por IA quando habilitada), ícone e logo, datasets e authentication. A opção *Any authenticated user may access this application* libera a app para qualquer usuário autenticado; sem ela, só editors e viewers vinculados entram. O *AI Service* padrão faz os novos IRs aceitarem linguagem natural, e *Enable Diction* liga a Web Speech API.
- **Relatório**: a origem é uma tabela/view ou uma *SQL Query*. *Convert to SQL Query* não tem volta.
  - Colunas: *Label*, *Display*, *Enable Sorting*/*Filtering*, *Value Identifies Row* (herdado do dataset) e *Enable Drill Down*, que liga a outro relatório com *Target Report*, *Target Column* e *Source Column*.
  - *Format Mask* só se aplica a `NUMBER`/`DATE`; em outra coluna, causa erro em runtime.
  - *Descriptors* são frases curtas que melhoram a busca semântica.
- **Publicação**:
  - Todo relatório nasce *Unpublished*, visível só para admin e editor. *Publish* o libera aos viewers, e só existe uma versão publicada por vez.
  - Para mudar um relatório publicado, use *Create Draft*, edite e depois *Publish Draft* (com a opção *Delete User's Saved Reports*) ou *Discard Draft*.
- Ao rodar uma app com preview, aparece a **Developer toolbar** própria do Data Reporter (Home, App XX, Page XX).
- **Atividade**: o *Monitor Activity* mostra top usuários, apps/relatórios e views. Na home, só o Administrator acessa; na app, Administrator e Editor.

Fonte: [Managing Data Reporter Reporting Applications](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdr/managing-reporting-applications.html), [Managing Reports](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdr/managing-reports.html), [Managing Data Reporter Activity](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdr/managing-data-reporter-activity.html)

### Data Reporter: usuários e export/import de reporting applications
- **Usuários**:
  - Administrator é criado em *Manage Users* na home. Editor e Viewer são criados dentro da reporting app.
  - Username: até 100 caracteres, sem espaços, e os únicos especiais aceitos são `&` e `.`. Há opção *Require Change of Password On First Use*.
  - Na edição: *Account Availability* (Locked/Unlocked), *User is administrator* e, por app, *Switch to Viewer/Editor* ou *Remove User*.
- **Export/Import**: o export é um script `.sql` (*Export / Import > Export*), com opções *Include User Access Controls*, *Include Private Reports* e *Include Report Subscriptions* (só as não expiradas). O import no workspace de destino usa *File Type = Reporting Application*, confere o *File Character Set* e termina em *Install Application*.

Fonte: [Managing Users](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdr/managing-users.html), [Exporting and Importing Applications](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdr/exporting-and-importing-applications.html)

## 20. Guia do usuário final (End User's Guide: tarefas, workflows, atalhos)

O *End User's Guide* descreve o que o usuário final faz numa app APEX: Interactive Reports e Interactive Grids (cobertos em outro documento), **Tasks**, **Workflows** e **atalhos de teclado**. O navegador precisa ter JavaScript habilitado; são suportadas a versão atual e a anterior de Chrome, Firefox, Safari e Edge.

Fonte: [Getting Started](https://docs.oracle.com/en/database/oracle/apex/26.1/aeeug/getting-started.html)

### Tasks para o usuário final: approval × action, participantes e ações permitidas
- **Approval Task**: o owner aprova ou rejeita (ex.: pedido de notebook). **Action Task**: precisa ser executada, sem aprovação (ex.: autoavaliação). Cada task segue uma *task definition* criada pelo desenvolvedor, e o usuário altera só a instância, nunca a definição.
- **Participantes**:
  - **Initiator**: cancela, muda a prioridade e envia informação.
  - **Potential Owner**: faz *Claim*. Se for o único, a task é atribuída a ele automaticamente.
  - **Actual Owner**: aprova, rejeita ou completa, delega, libera (*Release*), pede informação e atualiza parâmetros *updatable*.
  - **Business Administrator**: prioridade, due date, adicionar, remover ou excluir participantes, cancelar, renovar e delegar.
  - Toda task tem ao menos um potential owner e um business administrator.

| Ação | Initiator | Potential Owner | Actual Owner | Business Admin |
|---|---|---|---|---|
| Claim | só se também for potential owner | sim, se *Unassigned* | não | não |
| Approve/Reject/Complete | só se também for actual owner | sim (após claim, ou direto na lista para approval) | sim | não |
| Delegate | não | não | sim | sim |
| Release | se também for actual owner | não | sim | não |
| Cancel | sim | não | não | sim |
| Add Potential Owner / Remove Participant | não | não | não | sim |
| Set Priority | sim | não | não | sim |
| Update Parameter | não | não | sim | sim |
| Request Information / Submit Information | — / sim | não | sim / — | não |
| Update Due Date / Renew | não | não | não | sim (Renew só se expirada) |
| Add Comment | sim | sim | sim | sim |

- **Due date**: ao vencer, a task fica *Overdue*, *Expired* (some das listas; o admin vê com *Show expired tasks*) ou é renovada automaticamente até um limite de renovações. Tasks completed, errored ou canceled não podem ser alteradas, e ninguém aprova a própria approval task, salvo se a configuração permitir.
- **Unified Task List**: funciona como caixa de entrada, com os contextos *Initiated by Me*, *My Tasks* e *Admin Tasks* e busca por smart filters. Aprovar pela lista faz o claim automático, mas não permite comentar. A página de detalhes mostra os dados, os comentários e o *History* da task.

Fonte: [About Tasks](https://docs.oracle.com/en/database/oracle/apex/26.1/aeeug/about-tasks.html), [Working with Tasks](https://docs.oracle.com/en/database/oracle/apex/26.1/aeeug/working-with-tasks.html), [About Unified Task Lists](https://docs.oracle.com/en/database/oracle/apex/26.1/aeeug/about-the-unified-task-list.html)

### "Your session has ended" ao abrir o detalhe de uma task (e outras dúvidas de tasks)
**Sintoma:** a task aparece na Unified Task List, mas ao clicar surge "Your session has ended."
**Causa:** a lista e a página Task Details ficam em aplicações diferentes, sem sessão compartilhada.
**Correção:** o desenvolvedor configura **Session Sharing** entre as apps.

Outras perguntas frequentes:
- **Não aparece o botão Approve/Reject:** a task ainda não foi reivindicada; é preciso fazer *Claim*.
- **Reivindicou por engano:** *Delegate* para outra pessoa ou *Release* para devolver ao grupo.
- **E-mail de conclusão não chegou:** o APEX envia a fila de e-mail **a cada 15 minutos**. Espere e, se não chegar, acione o desenvolvedor ou o administrador da instância.
- **O owner saiu da empresa:** o Business Administrator delega a outro potential owner.
- **Tasks antigas sumiram:** tasks completed, canceled ou errored são purgadas automaticamente. A retenção é definida por aplicação, e o workspace admin tem um relatório de tasks purgadas.

Fonte: [Troubleshooting Tasks](https://docs.oracle.com/en/database/oracle/apex/26.1/aeeug/troubleshooting-tasks.html)

### Workflows para o usuário final: estados, participantes, console e operações
- *Workflow Definition* é o modelo, e *Workflow Instance* é cada execução. *Parameters* são entradas somente leitura. *Variables* são dados que as atividades usam e que só o admin edita.
- **Estados do workflow**: *Active*, *Suspended*, *Completed*, *Terminated* e *Faulted*. **Estados da atividade**: *Active*, *Waiting*, *Completed*, *Terminated* e *Faulted*. Se uma atividade falha num ramo de *parallel flow*, o parallel inteiro falha, e pode ser preciso fazer vários retries.
- **Participantes**:
  - **Initiator** (não precisa estar nomeado na definição): inicia e encerra.
  - **Owner**: inicia, encerra e faz retry.
  - **Administrator**: inicia, encerra, suspende, retoma, faz retry e edita variáveis (só com o workflow *suspended* ou *faulted*).
- **Páginas**: *Workflow Console* (contextos *Initiated by Me*, *My Workflows*, *Admin Workflows*), *Workflow Details* (atividades, variáveis, parâmetros, histórico e diagrama somente leitura) e, opcionalmente, *Workflow Dashboard* (por estado, ativos, com falha e performance).
- **Operações**:
  - *Terminate* cancela também as tasks pendentes e, se for o caso, o workflow pai que estava aguardando.
  - *Retry* reexecuta a atividade que falhou. Não existe auto-retry, nem limite de tentativas manuais.
  - *Resume* vale só para workflows suspensos.
  - Variável `CLOB` maior que o limite de `VARCHAR2`: use `apex_workflow.update_variables()`.
- Pegadinha: **ao atualizar a aplicação, as instâncias em execução ficam *Suspended*** e precisam ser retomadas ou encerradas pelo administrador.
- **Prazos**:
  - O deadline da atividade do workflow tem precedência sobre o da task definition.
  - Uma task gerada por workflow expira mesmo com política `NONE`, e o business admin não consegue renová-la manualmente.
  - Se a task expira e não há conexão de timeout, o workflow vai para *Faulted*.
  - Uma task cancelada não tem outcome, e um *switch* sobre esse outcome falha.
  - Para corrigir uma rejeição por engano: suspenda na *wait activity*, edite `TASK_OUTCOME` e retome.

Fonte: [About Workflows](https://docs.oracle.com/en/database/oracle/apex/26.1/aeeug/about-workflows.html), [Working with Workflows](https://docs.oracle.com/en/database/oracle/apex/26.1/aeeug/working-with-workflows.html), [Frequently Asked Questions](https://docs.oracle.com/en/database/oracle/apex/26.1/aeeug/workflow-faqs.html)

### Atalhos de teclado do usuário final (gerais e por componente)
- **Gerais**: `Alt+Shift+F1` lista os atalhos da página; `Alt+F1` abre a ajuda do campo; `Alt+F6` volta ao campo sem fechar a ajuda; `Esc` fecha diálogos; as setas trocam abas do *Region Display Selector*.
- **Interactive Grid**:
  - Geral: `F8` alterna entre seleção de linha e de célula; `Ctrl+C`/`X`/`V` copiam, recortam e colam; `Ctrl+Shift+V` faz *paste insert*; `Alt+↑/↓` ordena pelo cabeçalho.
  - Modo Navigation: `Enter`/`F2` entra em edição; `Insert` adiciona linha; `Delete` apaga as linhas selecionadas.
  - Modo Edit: `Tab`/`Enter` andam entre células; `Esc` volta ao modo Navigation.
- **Date Picker**: `↓` abre o popup; as setas andam por dia ou semana; `PgUp`/`PgDn` mudam o mês e, com `Shift`, o ano; `Enter`/`Space` selecionam.
- **Select One/Many e Combobox**: `↓` abre as sugestões; `Enter` seleciona (no *Many*, mantém o dropdown aberto); `←/→` navegam pelos chips; `Backspace`/`Delete` removem chip.
- **Chart**: as setas navegam pelos pontos (com `Shift`, seleção múltipla; com `Ctrl`, movem sem selecionar); `+`/`-` dão zoom; `Enter` faz drill.
- **Rich Text Editor**: `Shift+Enter` insere quebra de linha (`<br>`); `Ctrl+Shift+V` cola como texto puro; `Ctrl+K` cria link; `Alt+0` abre a ajuda de acessibilidade; `Alt+F10` leva ao toolbar.
- **Markdown Editor**: `Ctrl+Shift+.` e `Ctrl+Shift+,` saem do editor para a próxima ou a anterior tab stop.
- **Tree**: `→`/`←` expandem e recolhem; digitar letras pula para o nó; `Enter` ativa o nó.
- **Map**: `+`/`-` dão zoom; as setas fazem pan de 100 px; `Shift+setas` controlam rotação e inclinação.
- **Workflow Diagram**: as setas rolam a área; `Ctrl+0` reseta o zoom.

Fonte: [Keyboard Shortcuts](https://docs.oracle.com/en/database/oracle/apex/26.1/aeeug/keyboard-shortcuts.html), [Accessing Oracle APEX Using a Keyboard](https://docs.oracle.com/en/database/oracle/apex/26.1/aeacc/accessing-oracle-apex-using-a-keyboard.html)

## 21. Licenciamento (essencial)

### Licenciamento do APEX 26.1: software de terceiros e serviços de IA generativa
- O *Licensing Information User Manual* faz parte da documentação do programa dentro do contrato Oracle. Dúvidas sobre direitos de uso vão para o representante de vendas ou para o License Management Services.
- **Software comercial de terceiros:** não há nenhum incluído no APEX 26.1.
- **Open source incluído** (com avisos de licença, e algumas versões variando entre 26.1, 26.1.2 e 26.1.3+): jQuery, jquery-migrate, jQuery UI, Oracle JET, DOMPurify, FullCalendar, MapLibre GL, monaco-editor, marked, prism.js, Less.js, terser, Turndown, cropperjs, Pako, Oracle Rich Text Library (CKSource), fontes Noto, pacotes `@opentelemetry/*` e as especificações de API de provedores de IA (Anthropic, Cohere, Google Gemini, Mistral, Ollama, OpenAI).
- **Serviços de IA generativa de terceiros:** quando ligados no App Builder ou nas apps, podem usar metadados do schema (nomes de tabelas e colunas) para enriquecer os prompts, salvo configuração em contrário. Exigem conta no provedor, podem gerar cobrança (consumo de tokens), e o cumprimento dos termos do provedor fica por conta do cliente. A Oracle não se responsabiliza pelo uso desses serviços.

Fonte: [Introduction](https://docs.oracle.com/en/database/oracle/apex/26.1/aelim/introduction.html), [Third-Party Notices and/or Licenses for Oracle APEX](https://docs.oracle.com/en/database/oracle/apex/26.1/aelim/third-party.html)

## 22. Aplicação no Corlix Hub

### Ambiente do Corlix Hub: APEX 26.1.5 no Autonomous, workspace WKSP_CORLIXHUB

- A app 100 (`CORLIXHUB`) roda no APEX do Autonomous Database da OCI, workspace e schema `WKSP_CORLIXHUB` (`docs/ai-context/01` §5.1.1). Instalação, patch e upgrade do APEX são da Oracle: as seções §5–§6 servem só para entender mensagens, não para agir. Não sugira `apexins.sql`, `apxchpwd.sql`, ACL de rede ou `ALTER SYSTEM` como correção.
- Parâmetros de instância (timeouts, `SYSTEM_DEBUG_LEVEL`, limites do SQL Workshop) exigem ADMIN do banco ou `APEX_ADMINISTRATOR_ROLE`. O projeto já tem `scripts/apex-sessao-timeouts.sql`, que lê e ajusta `MAX_SESSION_IDLE_SEC`/`MAX_SESSION_LENGTH_SEC` por `APEX_INSTANCE_ADMIN.GET_PARAMETER`/`SET_WORKSPACE_PARAMETER` e roda em *Database Actions > SQL* como ADMIN. Os padrões que ele cita (3.600 s de inatividade e 28.800 s de duração) batem com a doc (1 h e 8 h, §2).
- O erro `400 Request Header Or Cookie Too Large` e a sessão do Builder que cai são do proxy da OCI, fora do APEX: veja `docs/ai-context/10-erro-400-cookies.md`.
- Para passo a passo no Builder, siga o 26.1.5 e marque "(confirmar no 26.1.5)" o que não foi conferido (`ai-context/08` §1, regra 11).

Fonte: [About Accessing APEX in Oracle Cloud](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/accessing-apex-in-oracle-cloud.html) · [Configuring Session Timeout for an Instance](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuiring-session-timeout.html)

### SQL Workshop no projeto: regras práticas e divergências com o docs/ai-context

- **Instalar módulos** (`modulos/<nome>/instalar.sql`): o `instalar.sql` usa `@@`, que o SQL Scripts ignora (§8). No SQL Scripts, envie e rode os arquivos numerados um a um, na ordem do `instalar.sql`, ou use o SQLcl conectado como `WKSP_CORLIXHUB`, que é o caminho preferido.
- **`set serveroutput on`** e outros comandos SQL*Plus: o SQL Commands não aceita (o comentário de `scripts/apex-limpar-sql-scripts.sql` registra `ORA-00922`) e já mostra o `DBMS_OUTPUT`. A doc oficial confirma que comandos SQL*Plus não são suportados no SQL Commands.
- **Contexto de sessão**: o `ai-context/08` registra que `apex_acl` falha no SQL Commands (`ORA-01403`, sem sessão da app) e que `apex_session.create_session` é bloqueado (`ORA-20987`). O `ai-context/09` §3.3 registra que o SQL Workshop roda numa sessão APEX, mas sem os app items da app 100 (`G_ID_EMPRESA`), e por isso as chamadas a `pkg_historico_carreira` falham com `-20012`. A doc oficial 26.1 não fala de contexto de sessão no SQL Workshop, nem para confirmar nem para negar: trate esses pontos como comportamento observado no projeto. Atribuição de papéis vai pela P14, pelo Builder ou pelo SQLcl.
- **Divergência a registrar**: o `ai-context/08` diz "um comando por vez (sem `;` final…) e só 10 linhas por padrão". A doc 26.1 aceita `;`, `/` ou nenhum terminador, executa o comando inteiro ou só o trecho selecionado, e a lista *Rows* vai até 100.000 (a doc não informa o padrão). A regra "um comando por vez" continua valendo como prática segura. Se `commit` for necessário (Autocommit desmarcado), rode-o num Run separado.
- **DBMS_OUTPUT no SQL Scripts**: o `ai-context` diz que o SQL Scripts não mostra o resumo do `dbms_output`. A doc não menciona `DBMS_OUTPUT` nos resultados do SQL Scripts, então não há contradição: para ver a saída, use o SQL Commands ou o SQLcl.
- **Limpeza de scripts**: `scripts/apex-limpar-sql-scripts.sql` apaga os SQL Scripts do workspace em `APEX_APPLICATION_FILES` (`FILE_TYPE = 'SCRIPT'`). Os resultados (*Manage Results*) contam na quota *Quota for All Script Results* e se removem pela UI (§8).
- **Antes de `drop` ou de alterar uma tabela base** (`COLABORADOR`, `EMPRESA`…): use *Object Browser > Dependencies* e *Utilities > Object Reports > Search PL/SQL Source Code* (§9–§10). Para tabelas novas com `id_empresa`, confira *Unindexed Foreign Keys*.
- **Quick SQL / Data Generator**: dá para usá-los para rascunhar DDL ou gerar dados de teste. O DDL final, porém, vai num script numerado e idempotente do módulo (`create table if not exists`), em `snake_case` e com `id_empresa` (`ai-context/08`). O *Insert Into Database* do Data Generator sobrescreve dados e ignora constraints: não use no schema de produção.

Fonte: [About SQL Scripts](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/sql-scripts.html) · [Using the Command Editor](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/using-command-editor.html) · [Viewing Object Reports](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/viewing-object-reports.html)

### Debug e logs para diagnosticar erros da app 100

- A app usa `errorHandlingFunctionName: log_pkg.apex_error_handler` (`corlixhub/application.apx`), que delega os códigos -20001 a -20099 para `pkg_historico_carreira.fn_tratar_erro`. A mensagem mostrada ao usuário pode esconder o `ORA-` original: o erro completo fica no debug log (erros são gravados mesmo com debug desligado) e na seção *Technical Info* da página de erro (`ai-context/09` §1.2).
- Para instrumentar os packages do projeto (`pkg_historico_carreira`, `pkg_organograma`), prefira `apex_debug.enter`/`info`/`error` a `dbms_output`: as mensagens aparecem no *View Debug* junto das do engine, só quando o debug está ligado (§13).
- Para depurar a sessão de um colaborador (por exemplo "SEM VINCULO" ou `-20012` por `G_ID_EMPRESA` vazio), use *Monitor Activity > Active Sessions > Session Details*: ali se veem os app items em session state e se liga o debug daquela sessão.
- **Divergência a registrar**: o `ai-context/08` diz que `deployments/default.json` está com `debugging: true`. Hoje o arquivo só contém `{"app": {"id": 100}}`, e `application.apx` não declara o atributo de debugging. Confira no Builder (*Edit Application Properties > Properties > Debugging*, "(confirmar no 26.1.5)") antes de assumir qualquer valor. Lembre que esse atributo só bloqueia o debug por URL do usuário final: o desenvolvedor logado no workspace continua conseguindo depurar (§13).
- O Monitor de Logs (p7) é a tela de logs **da própria app** (tabelas do `log_pkg`), diferente dos logs do APEX descritos no §4. Ela continua sem `authorizationScheme` (`ai-context/08`).

Fonte: [Using APEX_DEBUG When Developing Your Application](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-APEX_DEBUG-when-developing-your-application.html) · [Monitoring Activity Within a Workspace](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/monitoring-activity-within-a-workspace.html)

### Deploy, export e ciclo de vida no projeto (APEXlang, backup e branches)

- A fonte da app é `corlixhub/` em APEXlang (export `-split` em formato APEXlang; estrutura no [09](./09-apexlang.md)). `database/f100.sql` é o export SQL de arquivo único, só para consulta. Isso corresponde ao que o §11–§12 descrevem: o banco guarda só o estado atual e o export versionado é o histórico.
- O backup diário (Jenkins, `scripts/backup/`) usa o SQLcl com wallet para exportar a app em APEXlang e em SQL, além dos usuários e grupos do workspace, e publica em `DEV` por PR (`ai-context/01` §8.1). Ou seja, o fluxo de export do projeto é o da linha de comando (§11), não o do Builder.
- Para importar o APEXlang pelo App Builder, a doc exige ORDS 26.1.1+ e schema REST-enabled, e não aceita página isolada em APEXlang (§11). No Autonomous o ORDS é da Oracle; se o import der erro, use o SQLcl (`apex import`).
- **Supporting objects** estão vazios (`supporting-objects.apx` só tem `includeInAppExport: true`): o export da app não instala nada do schema. O DDL vem de `database/corlix-hub.sql`, que é só um snapshot, e dos `modulos/*/instalar.sql`.
- **Build options**: só existe a padrão `Commented Out` (`build-options.apx`). Para esconder uma feature ainda incompleta em PROD (por exemplo telas do pen.dev sem backend), dá para criar uma build option com status Exclude no ambiente de produção (§11).
- **Branches × ambientes**: `DEV` → `UAT` → `PROD` (`ai-context/01` §7). Ao importar em outro ambiente, mantenha o ID 100 só se for para substituir a app (o import com "Reuse ID" apaga e substitui a existente) e confira o *Parsing Schema* e o *Build Status* (§11). *Working copies* (§11) servem para mudanças isoladas dentro de um mesmo ambiente, mas o merge sobrescreve a Main e deixa de fora temas e supporting objects.

Fonte: [Exporting an Application](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/exporting-an-application.html) · [Understanding Application Lifecycle](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-application-lifecycle.html)

### Acessibilidade e usuário final no Corlix Hub

- A UI é em pt-BR, mas o idioma primário técnico da app é `en`: textos de acessibilidade (labels, `aria`, títulos de região usados como landmarks) precisam estar em pt-BR, e nenhuma região fica sem título: para escondê-lo, use *Template Options > Header = Hidden but accessible*, porque `Hidden` também esconde o landmark (§18).
- A política visual do tema `--cx-*` (sem sombras, foco visível) precisa preservar o contraste e o indicador de foco do Universal Theme. O Theme Roller checa contraste WCAG, mas `corlix-tema.css`/`custom.css` não passam por essa checagem: valide à mão. Rode o Advisor com os checks de acessibilidade antes de entregar uma página nova (§18).
- Data Reporter, Tasks e Workflows (§19–§20) não são usados hoje pela app 100.

Fonte: [Developing Accessible Apps](https://docs.oracle.com/en/database/oracle/apex/26.1/aeacc/developing-accessible-apps.html)
