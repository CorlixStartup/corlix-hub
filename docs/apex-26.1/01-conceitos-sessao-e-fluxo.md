# 01 · Conceitos, sessão, session state e fluxo de página

> Base: documentação oficial Oracle APEX 26.1 (App Builder User's Guide: "App Builder Concepts", "Managing Computations, Validations, and Processes", "Adding Navigation", "Available Conditions", "Oracle APEX Limits", "Correlating APEX Sessions to Database Sessions", e trechos de "Managing Application Security", "Managing Application Controls", "Managing Shared Components"; Developer's Companion: "Understanding Page Flow & Session State", "Referencing Data Values in Pages"; API Reference: `APEX_PAGE`, `APEX_UTIL`, `APEX_SESSION_STATE`; APEXlang API Reference; Administration Guide: Session Timeout). Gerado em 21/10/2026.

**Sumário**

1. Arquitetura: engine, ORDS, metadados, sessão APEX × sessão de banco
2. Ciclo de vida da página: Show Page (renderização) e Accept Page (processamento), pontos de execução e commits implícitos
3. Sessão APEX: session ID, criação, cookie, expiração, Rejoin Sessions, deep linking, zero session ID, clonagem
4. Session state: gravação, leitura, armazenamento (Storage), limpeza (clear cache, RP/RR/CR), Session State Commits, depuração
5. Sintaxe de URL: friendly URL e `f?p`, cada argumento, checksums e Session State Protection, `APEX_PAGE.GET_URL`
6. Formas de referência a valores: `:ITEM`, `&ITEM.`, `V()`, `#COL#`, `APEX_SESSION_STATE`, `SYS_CONTEXT('APEX$SESSION',…)`, filtros de escape, text messages
7. Substitution strings built-in (APP_USER, APP_ID, APP_PAGE_ID, APP_SESSION, REQUEST, DEBUG etc.)
8. Template directives (`{if}`, `{case}`, `{loop}`, `{with}/{apply}`)
9. Itens de página e de aplicação, tipos de dado de bind, valores delimitados, datas e números
10. Computations, validations, processes (página e aplicação), On Demand, background, branches
11. Condições (Server-side Condition, When Button Pressed, tipos)
12. Navegação: navigation menu, navigation bar, breadcrumbs, listas, wizard, modais, AJAX × redirect
13. Correlação sessão APEX × sessão de banco (`client_id`, `module`, `action`)
14. Limites do APEX
15. Problemas conhecidos (formato de caso)
16. Aplicação no Corlix Hub

---

## 1. Arquitetura do APEX

### O que é uma aplicação APEX (Understanding Applications)

Uma aplicação APEX é uma interface HTML montada sobre objetos do banco (tabelas, views, procedures). Ela é um conjunto de **páginas** ligadas por navigation menu, abas, botões ou links. Todas as páginas da aplicação compartilham o mesmo **session state** e a mesma **autenticação**.

- **Página**: unidade básica. Contém **regiões** (containers), **itens** (campos de formulário), **botões** e lógica (**computations**, **validations**, **processes**, **branches**). É editada no *Page Designer*.
- **Região**: pode conter texto, PL/SQL, relatórios, charts, mapas, calendários, formulários etc.
- **Item**: campo do formulário (text field, select list, date picker, checkbox, popup LOV…). Tipos customizados podem vir de plug-ins.
- **Separação entre apresentação e lógica**: a aparência vem do tema e dos templates. Trocar o tema muda o visual sem tocar na lógica.

**Fonte de dados (`Source > Location`)** de um componente:

| Location | Significado |
|---|---|
| Local Database | banco local |
| REST Enabled SQL | banco remoto via REST Enabled SQL |
| REST Data Source | API REST externa |
| JSON Source | JSON Collection Table ou tabela com colunas JSON (local ou remoto) |
| Sample Data | conjunto de dados de exemplo embutido |
| Duality View | Duality View local ou remota |

**`Source > Type`**: `Table / View`, `SQL Query`, `Function Body returning SQL Query` (bloco PL/SQL ou JavaScript MLE que devolve o SQL) e `Property Graph`.

> Duality Views, JSON Collection Tables e Property Graph exigem **Oracle Database 26ai** ou superior. O Corlix Hub roda em 23ai, então esses tipos não estão disponíveis aqui.

Fonte: [Understanding Applications](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-applications.html)

### Como o APEX Engine renderiza e processa páginas (Show Page × Accept Page)

O APEX é **dirigido por metadados**: a definição de cada página (regiões, itens, botões, processos) fica gravada em tabelas do banco, e o **APEX engine** monta a página dinamicamente a cada requisição. Você pede uma página com uma URL, e a engine executa um de dois processos:

| Processo da engine | Quando roda | O que faz |
|---|---|---|
| **Show Page** (renderização) | Requisição de página via URL (GET, link, redirect) | Junta todos os atributos da página (regiões, itens, botões) e gera o HTML. |
| **Accept Page** (processamento) | Submit da página (POST) | Grava os valores submetidos no session state e executa computations, validations, processes e branches. |

No Developer's Companion, o mesmo ciclo é chamado de **render, submit, branch, repeat**: a engine renderiza a página, o usuário submete, o processamento roda, um branch decide a próxima página e o ciclo se repete.

O HTTP é *stateless*: cada requisição é independente. Por isso o APEX guarda o estado do usuário (**session state**) em tabelas do banco entre uma página e outra (ver §4).

Fonte: [How Does Page Processing and Page Rendering Work?](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/how-does-page-processing-and-page-rendering-work.html), [Render, Submit, Branch, Repeat](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/render-submit-branch-repeat.html), [Running an Application or Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/running-an-application-or-page.html)

### ORDS, pool de conexões e o usuário de banco das requisições

As requisições chegam pelo **Oracle REST Data Services (ORDS)**, que mantém um **pool de sessões de banco**. Todas as sessões do pool usam um único usuário de banco (`ORDS_PUBLIC_USER`, `APEX_PUBLIC_USER` ou outro, conforme a configuração da instância). O SQL e o PL/SQL da aplicação são executados como o **Parsing Schema** da aplicação (configurado em *Security > Database Session*; referenciável como `#OWNER#`).

Consequências práticas:

- **Não existe ligação fixa entre uma sessão APEX e uma sessão de banco.** Cada página pedida usa uma sessão do pool, criada ou reaproveitada, que muitas vezes dura uma fração de segundo. Uma sessão APEX (do login ao logout) dura minutos ou horas e passa por várias sessões de banco.
- **Variáveis globais de package PL/SQL não persistem entre requisições.** Para guardar estado use session state (itens), collections ou tabelas.
- Só dá para correlacionar uma sessão APEX com uma sessão de banco **enquanto a requisição está ativa** (ver §13).

Atributos de *Security > Database Session* que participam de toda requisição:

| Atributo | Comportamento |
|---|---|
| Parsing Schema | Schema em que todo SQL/PL/SQL da app é analisado. `#OWNER#` devolve esse valor. |
| Initialization PL/SQL Code | Bloco que roda **muito cedo** em cada requisição de Show ou Accept, logo depois de `APP_USER` ser definido. Pode ler `:APP_USER` e itens que já estavam no session state **antes** da requisição. Uso típico: setar contexto (VPD). |
| Cleanup PL/SQL Code | Bloco que roda no fim do processamento da página. Uso típico: liberar recursos (contextos VPD, database links). |
| Runtime API Usage | Define se a app pode, em runtime, modificar a si mesma (`Modify This Application`), outras apps (`Modify Other Applications`) ou o repositório do workspace, como usuários e grupos (`Modify Workspace Repository`). |

Fonte: [Correlating APEX Sessions to Database Sessions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/correlating-apex-sessions-to-database-sessions.html), [Understanding Session State Management](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-session-state-management.html), [Configuring Security Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-security-attributes.html)

### Templates e temas: como a engine monta a aparência

A engine constrói a aparência de cada página com **templates** (de página, região, relatório, lista, breadcrumb, item/label, botão). Um **tema** é um conjunto de templates. Apps novas usam o **Universal Theme - 42**, que é responsivo e pode ser ajustado de três formas:

- **Theme Styles**: CSS somado ao CSS base.
- **Theme Roller**: editor de CSS ao vivo, no menu *Customize* da Developer Toolbar.
- **Template Options**: modificadores CSS declarativos aplicados a páginas, regiões, relatórios, listas, breadcrumbs, itens e botões.

Os templates aceitam **substitution strings** (`#PLACEHOLDER#` e `&ITEM.`, ver §6) e, em vários casos, **template directives** (§8). Para ver quais substitution strings um template aceita: *Shared Components > User Interface > Templates*, abra o template e procure o relatório **Substitution Strings**.

**Template Components** são um tipo de plug-in para criar componentes de UI reutilizáveis sem PL/SQL. Eles renderizam uma ou várias linhas e suportam paginação, faceted search, smart filters, Order By externo, seleção de linhas e agrupamento. Também podem ser usados como *partial* numa coluna de relatório e ter Actions e menus com condição por linha.

O app **Universal Theme Reference** (hospedado em `https://apex.oracle.com/ut` ou instalável pela Gallery, em *Sample Apps*) traz exemplos de componentes, ícones, Template Directives e boas práticas.

Fonte: [How Oracle APEX Uses Templates](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/how-oracle-apex-uses-templates.html), [Theme Templates](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/theme-templates.html), [Template Components](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/template-components.html), [Viewing Supported Substitution Strings for a Template](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/viewing-supported-substitution-strings-for-a-template.html), [Accessing the Universal Theme Reference App](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/accessing-the-universal-theme-reference-app.html)

### Global Page (página 0): componentes em todas as páginas

A **Global Page** (antes chamada de *Page 0*) funciona como página mestre. Tudo o que estiver nela (regiões, itens, computations, validations, processes) é renderizado ou executado **em todas as páginas** da aplicação. Use condições para restringir. Existe no máximo uma Global Page por interface de usuário, e a opção *Create Page > Component > Global Page* só aparece se a app ainda não tem uma.

Uso típico: cabeçalho, avisos, região com dados do usuário (ex.: carrinho de compras alimentado por um application process em *Before Header*).

No APEXlang, `branch` não pode ser criado na Global Page (a doc condiciona o componente a `app.globalPage NOT_EQUALS #COMPONENT_PAGE_ID#`).

Fonte: [Creating a Global Page to Display Components on Every Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-a-global-page-to-display-components-on-every-page.html), [Example: Application Process](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-application-processes.html), [APEXlang API Reference: branch](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Executar a aplicação ou uma página (Run Application, Run Page)

- **Run Application**: botão na Application home page. Também existe a ação *Run* na visão em relatório (*View Report*) da App Builder home.
- **Run Page**: botão em forma de "play" no canto superior direito do Page Designer e de outras telas. Roda a página atual (ou a última selecionada).
- O app abre em nova aba (Chrome, Safari) ou em nova janela (Edge, Firefox) por padrão. Isso pode ser ajustado nas preferências da conta.
- Quem roda a app a partir do Builder vê a **Developer Toolbar** (por padrão no rodapé), com Session, Debug, Customize (Theme Roller) e outras opções. A opção *Auto Hide*, no ícone de engrenagem da toolbar, deixa a barra escondida até ser clicada.

Fonte: [Running an Application or Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/running-an-application-or-page.html), [Running the List and Edit Pages](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/running-list-and-edit-pages.html)

---

## 2. Ciclo de vida da página: pontos de execução

### Ordem dos pontos de execução na renderização (Show Page / Pre-Rendering)

No Page Designer, a aba **Rendering** agrupa e ordena os componentes **na ordem em que o APEX os processa em runtime**: primeiro *Pre-Rendering* (branches, computations e processes antes de gerar o HTML), depois as regiões e os itens, depois *Post-Rendering*.

Os pontos disponíveis para computations e processes, na ordem listada pela referência APEXlang:

| Ponto (UI) | Valor APEXlang | Para que serve |
|---|---|---|
| On New Instance (new session) | `newSession` | Roda **uma vez**, quando a sessão APEX é criada. |
| After Authentication | `afterAuthentication` | Roda quando a engine processa a requisição de um usuário recém-autenticado (só application process/computation). |
| Before Header | `beforeHeader` | Antes de qualquer HTML. É o ponto típico de *Form - Initialization*, de busca de dados, de branches de pré-renderização e de downloads. |
| After Header | `afterHeader` | Depois do cabeçalho do template de página. |
| Before Regions | `beforeRegions` | Antes de renderizar as regiões. É o default de `computation` (de página) no APEXlang. |
| After Regions | `afterRegions` | Depois das regiões (Post-Rendering). |
| Before Footer | `beforeFooter` | Antes do rodapé (Post-Rendering). |
| After Footer | `afterFooter` | Depois do rodapé (Post-Rendering). |

No *Pre-Rendering*, o Page Designer oferece os nós **Before Header**, **After Header** e **Before Regions** para criar branch, computation ou process (clique direito > *Create Branch / Create Computation / Create Process*).

**O que a engine faz com o session state na renderização** (Developer's Companion):

1. Antes das computations, processes e branches do Pre-Rendering, a engine carrega nos itens da página os valores que já estão no session state, incluindo os que vieram como parâmetros na URL.
2. Executa os componentes de Pre-Rendering na ordem de *Sequence* dentro de cada ponto.
3. Renderiza regiões e itens.
4. Ao terminar, grava no session state os itens com **Storage = Per Session (Persistent)**.

Componentes de renderização com o mesmo *Sequence* podem rodar em ordem diferente depois de exportar e importar a app em outro ambiente. **Use sequências distintas.**

Fonte: [Creating Branches, Validations, Computations, and Processes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-branches-validations-computations-and-processes.html), [Left Pane of Page Designer](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/left-pane-page-designer.html), [How APEX Manages User Session State](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/how-apex-manages-user-session-state.html), [APEXlang API Reference: computation, appProcess](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Ordem dos pontos de execução no processamento (Accept Page / Processing)

Ao submeter a página, o navegador envia os valores de **todos** os itens da página. A engine então percorre, na aba **Processing** do Page Designer:

| Ordem | Ponto (UI atual) | Nome antigo | O que roda |
|---|---|---|---|
| 1 | **After Submit** | Before Computation / On Submit - Before Computation and Validations | Computations "After Submit" (o ponto mais comum de computation), processes e branches que precisam rodar antes das validações. |
| 2 | **Validating** | Before Validation | **Validations**. Também aceita branches. |
| 3 | **Processing** | Before Processing / On Submit - After Computations and Validations | **Page processes** (DML, Execute Code, Invoke API, Close Dialog…). É o default de `process` no APEXlang, que grava `point: AFTER_SUBMIT`: o código interno desse ponto é `AFTER_SUBMIT`, enquanto o After Submit da UI é `ON_SUBMIT_BEFORE_COMPUTATION`. |
| 4 | **After Processing** | After Processing | **Branches** (o default de `branch` no APEXlang é `afterProcessing`). |

Os valores de `point` de um `branch` no APEXlang são `beforeHeader`, `afterSubmit`, `validating`, `processing` e `afterProcessing`. Um application process aceita também `processing` e `ajaxCallback`.

Regras do processamento:

- Dentro de cada ponto, os componentes rodam pela ordem de **Sequence**, e cada um pode ter **Server-side Condition** e **When Button Pressed**.
- O valor de **`REQUEST`** (nome do botão que submeteu) vale durante todas as fases do Accept. Quando a app faz branch para outra página, `REQUEST` volta a ser NULL.
- **Se alguma validação falha**, os processos da fase Processing **não rodam** e a página é re-exibida com os erros (ver a seção sobre falha de validação, em §10).
- Ao terminar o submit, a engine grava os itens **Per Session (Persistent)** da página atual e **"esquece"** os itens **Per Request (Memory Only)**. Isso acontece **antes** de seguir o branch ou de re-renderizar a página.
- Um erro não tratado num process interrompe o processamento e provoca **rollback**. A mensagem aparece conforme o *Error Display Location*.

Fonte: [Controlling Navigation Using Branches](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/controlling-navigation-using-branches.html), [Creating Branches, Validations, Computations, and Processes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-branches-validations-computations-and-processes.html), [Wizard Example Page Lifecycle](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/wizard-example-page-lifecycle.html), [How APEX Manages User Session State](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/how-apex-manages-user-session-state.html), [Using Built-in Substitution Strings (REQUEST)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-available-built-in-substitution-strings.html)

### Diagrama textual do ciclo completo (render → submit → branch)

```
Requisição GET (URL com app/página/sessão/parâmetros)
 └─ Show Page
     ├─ autenticação / sessão (On New Instance na 1ª requisição; After Authentication após login)
     ├─ Initialization PL/SQL Code (logo após APP_USER)
     ├─ parâmetros da URL → session state (clear cache, set items, REQUEST)
     ├─ Pre-Rendering: Before Header → After Header → Before Regions
     │    (branches de pré-renderização, computations, processes como Form - Initialization)
     ├─ regiões / itens / botões (conditions e authorizations avaliadas por componente)
     ├─ Post-Rendering: After Regions → Before Footer → After Footer
     ├─ grava itens Per Session  → COMMIT implícito (fim da renderização)
     └─ Cleanup PL/SQL Code
Usuário clica num botão "Submit Page" (POST com os valores de todos os itens)
 └─ Accept Page
     ├─ valores submetidos → session state; REQUEST = nome do botão
     ├─ After Submit (computations / processes / branches)
     ├─ Validating (validations)
     │    └─ se falhou: COMMIT implícito e re-render da mesma página com os erros
     ├─ Processing (processes)
     ├─ After Processing (branches)  → COMMIT implícito antes do branch
     └─ branch: Page/URL (redirect) ou Page sem redirect → nova Show Page
```

O diagrama é uma síntese das seções desta parte. A posição exata de *Initialization/Cleanup PL/SQL Code* é a descrita em *Database Session*.

Fonte: [How Does Page Processing and Page Rendering Work?](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/how-does-page-processing-and-page-rendering-work.html), [Configuring Security Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-security-attributes.html), [Understanding AJAX and Redirect](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-ajax-and-redirect.html)

### Commits implícitos do APEX (About Implicit Commit Points)

O APEX emite **commit implícito** nos seguintes momentos:

1. Na renderização, **depois que a página termina de renderizar**.
2. No submit, **antes do branch** para outra página.
3. No submit, **se uma ou mais validações falharem**, antes de re-renderizar a página.
4. **Depois de uma computation.**
5. **Depois de alterar o valor de um item**, por exemplo num process PL/SQL que muda um bind (`:P1_X := …`) ou numa chamada a `APEX_UTIL.SET_SESSION_STATE`.
6. Quando `APEX_MAIL.PUSH_QUEUE` é chamado.

Implicações:

- Não conte com transação aberta entre uma requisição e outra. Cada página é uma transação, encerrada pelos commits acima.
- Um process que faz DML e depois atribui um item pode ter o DML confirmado no momento da gravação do session state. O atributo **Session State Commits** controla isso (ver §4): com `Immediate`, cada mudança de session state grava e **commita a transação principal, inclusive as alterações nas suas tabelas**. Com `End Of Request`, as mudanças de session state são aplicadas no fim da requisição.
- Um erro não tratado num process gera **rollback**. O que já foi confirmado por um commit implícito anterior não volta.

Fonte: [How Does Page Processing and Page Rendering Work? (About Implicit Commit Points)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/how-does-page-processing-and-page-rendering-work.html), [Configuring Security Attributes (Session State Commits)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-security-attributes.html)

### Renderização condicional × autorização (conditions e authorization schemes)

- **Condition**: pequena unidade de lógica que decide se um componente é **renderizado** (região, item, botão, aba, entrada de lista) ou **executado** (computation, validation, process, branch). É avaliada no momento em que o componente seria processado. A condição de um botão, por exemplo, é avaliada durante o Show Page.
- **Authorization scheme**: controla o **acesso do usuário** e se baseia na identidade estabelecida pela autenticação. Pode ser aplicado à aplicação inteira, a uma página ou a um componente (região, item, botão, entrada de navegação). Use conditions para regras de exibição e de negócio, e authorizations para regras de privilégio.
- **Authentication**: estabelece a identidade do usuário (usuário e senha, certificado, chave). É modular: há esquemas built-in e esquemas customizados.

Detalhes de segurança estão no documento 05.

Fonte: [How Does Page Processing and Page Rendering Work?](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/how-does-page-processing-and-page-rendering-work.html)

---

## 3. Sessão APEX

### O que é uma sessão APEX e o session ID

- Uma **sessão** é uma construção lógica que dá persistência (comportamento com estado) entre visualizações de página. Cada sessão tem um **session ID** único, que é a chave para buscar e gravar o session state antes e depois de cada página.
- As sessões são independentes. Podem existir muitas ao mesmo tempo, e o mesmo usuário pode rodar várias instâncias da app em navegadores diferentes.
- A sessão APEX é **distinta da sessão de banco** (ver §1).
- O session ID aparece:
  - no **3º argumento** da sintaxe `f?p` (`f?p=392:3:13766599855150`);
  - no parâmetro **`session`** da friendly URL (`…/r/mycompany/hr-app/update-employees?session=13766599855150`);
  - nos dados POST da página;
  - **indiretamente no cookie de sessão**, enviado pela engine na autenticação e mantido durante a vida da sessão do navegador.
- O APEX **gera um novo session ID durante a autenticação**, registra a identidade do usuário junto ao ID e confere, a cada requisição, o session ID da URL ou do POST contra o cookie e o registro de sessão no banco. O session ID é a chave do estado; o cookie e o registro no banco protegem a integridade do ID e o status de autenticação.

Fonte: [Understanding Session State Management](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-session-state-management.html), [Session Context for Temporary Values](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/session-context-temporary-values.html)

### Quando a sessão começa e termina (criação, logout, timeout)

- A sessão começa quando o usuário navega pela primeira vez para uma página (e faz login). Nesse momento rodam os application processes e computations **On New Instance**. Depois do login rodam os de **After Authentication**.
- A sessão termina quando o usuário faz **sign out** ou fica **inativo** tempo suficiente para o **timeout**. Ao terminar, a engine **limpa todo o session state**: itens de página, collections e arquivos temporários.
- Sessões podem ser compartilhadas entre aplicações que usam o **mesmo nome de cookie** no authentication scheme (*Session Cookie Attributes*). Nesse caso, On New Instance dispara quando a engine processa a primeira requisição para **cada** aplicação, e After Authentication quando processa uma requisição de usuário autenticado para a aplicação.

Fonte: [Session Context for Temporary Values](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/session-context-temporary-values.html), [Clearing Session State](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/clearing-session-state.html), [Understanding Application Processes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-application-processes.html)

### Timeout de sessão: Maximum Session Length, Idle Time e Warning

Os atributos de timeout ficam em três níveis. **Aplicação** (*Shared Components > Security Attributes > Session Management*) prevalece sobre **workspace**, que prevalece sobre **instância** (*Manage Instance > Security > Session Timeout*).

| Atributo | Valores | Default da instância |
|---|---|---|
| Maximum Session Length in Seconds | inteiro positivo; `0` = sem limite; vazio = herda | 8 horas (28800 s) |
| Maximum Session Idle Time in Seconds | inteiro positivo (tempo entre a última requisição e a próxima); vazio = herda | 1 hora (3600 s) |
| Session Timeout Warning in Seconds | inteiro positivo; `0` = desliga o aviso; vazio = herda | 5 minutos (300 s) |
| Session Timeout URL (app) | URL para onde ir quando a duração máxima estoura | mensagem "Your session has timed out" + link para a home |
| Session Idle Timeout URL (app) | URL para onde ir quando o idle estoura | idem |

- No aviso de **idle**, o usuário pode estender a sessão. No aviso de **duração máxima**, ele só é avisado para salvar o trabalho.
- As URLs de timeout devem apontar para **página pública**. `#LOGOUT_URL#` executa um logout. Nelas só são aceitas as substituições `&APP_SESSION.`, `&SESSION.` e `&APP_ID.`, e não é preciso incluir a sessão.
- APEXlang: `maxSessionLength`, `maxSessionIdleTime`, `sessionTimeoutWarning`, `sessionTimeoutUrl`, `sessionIdleTimeoutUrl`.

Fonte: [Configuring Security Attributes (Session Management)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-security-attributes.html), [Configuring Session Timeout for an Instance](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuiring-session-timeout.html), [About Utilizing Session Timeout](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/manging-instance-security.html)

### Rejoin Sessions: URLs sem session ID

**Rejoin Sessions** decide se o APEX aceita URLs **sem session ID**. Quando está habilitado, o APEX tenta usar o cookie de sessão para entrar numa sessão existente. Ele pode ser configurado na instância, na aplicação e na página, e **o valor mais restritivo da instância vence**.

| Opção (app) | APEXlang | Efeito |
|---|---|---|
| Application Default | | Vale a configuração da aplicação. |
| Disabled | `false` (default) | URL sem session ID cria uma **nova sessão**. |
| Enabled for Public Sessions | `publicSessions` | Em página pública sem session ID, reaproveita o cookie da app, **só se a sessão ainda não estiver autenticada**. |
| Enabled for All Sessions | `allSessions` | Reaproveita o cookie se: (a) Session State Protection está habilitado e a URL tem checksum válido (para bookmark público, a proteção mais restritiva dos itens deve ser *Unrestricted* ou *Checksum Required - Application Level*); **ou** (b) a URL não traz payload (request, clear cache ou pares item/valor). Exige *Embed in Frames* = *Allow from same origin* ou *Deny*. |

**Riscos documentados:** um atacante pode induzir o usuário a clicar num link que altera session state (por isso o APEX exige checksum para requisições que alteram dados), e duas apps abertas na mesma instância podem interferir uma na outra (por exemplo, uma app com XSS simulando chamadas Ajax na outra). A Oracle recomenda **desabilitar Rejoin Sessions**, a menos que haja isolamento de workspace (atributo *Allow Hostname*).

**Esconder o session ID em páginas públicas:** com *Rejoin Sessions* = *Enabled for Public Sessions* na aplicação e *Security > Authentication* = *Page Is Public* na página, a URL da página pública não mostra o session ID para quem não fez login.

Fonte: [Configuring Security Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-security-attributes.html), [About Rejoin Sessions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/manging-instance-security.html), [Hiding the Session ID on Public Pages](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/hiding-the-session-ID-on-public-pages.html)

### Bookmarks, zero session ID e Deep Linking

- **Bookmarks**: há duas formas de ajudar usuários que salvam favoritos de páginas. A antiga, ainda suportada, é usar **zero como session ID** em páginas públicas. A atual é o **Rejoin Sessions**.
- **Zero session ID**: para usuário público (não autenticado) numa página pública, o session ID visível vira `0`. `APP_SESSION_VISIBLE` sempre devolve `'0'` nesse cenário. `APEX_UTIL.PREPARE_URL` troca o session ID por zero quando o recurso está em uso, o usuário é público e a página-alvo é pública da mesma app.
- **Deep Linking** (*Session Management*; APEXlang `deepLinking`, default `false`):
  - **Enabled**: uma URL para uma página específica acaba chegando nela, possivelmente depois do login.
  - **Disabled**: se a URL não tem session ID válido, o APEX cria uma sessão nova e redireciona para a **home** da aplicação. Isso evita, por exemplo, que o navegador restaure uma aba no meio de um wizard depois de reiniciar.

Fonte: [About Enabling Support for Bookmarks](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-enabling-support-for-bookmarks.html), [APP_SESSION_VISIBLE](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-available-built-in-substitution-strings.html), [PREPARE_URL Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PREPARE_URL-Function.html), [Configuring Security Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-security-attributes.html)

### Session cloning: várias abas com sessões distintas (APEX_CLONE_SESSION)

Abrir várias abas da mesma app compartilha a mesma sessão e o mesmo session state, o que costuma dar resultados imprevisíveis. A **clonagem de sessão** abre uma nova aba com um **novo session ID** e **copia** os valores do session state da sessão original.

Para usar, ofereça um link que abra nova aba com `REQUEST` = `APEX_CLONE_SESSION`:

```
f?p=&APP_ID.:&APP_PAGE_ID.:&APP_SESSION.:APEX_CLONE_SESSION
```

Regras:

- O tempo de **idle** é afetado por qualquer uma das sessões (original ou clones).
- **Logout** em uma delas faz logout de todas.
- A **duração máxima** é calculada a partir da sessão original e do momento em que ela foi criada.
- O administrador liga ou desliga o recurso com:

```sql
apex_instance_admin.set_parameter(
    p_parameter => 'CLONE_SESSION_ENABLED',
    p_value     => 'Y');
```

Fonte: [Managing Session State Values (About Session Cloning)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-session-state-values.html)

---

## 4. Session state

### O que é session state e o que ele inclui

**Session state** é o armazenamento temporário que a engine mantém para cada sessão de usuário. Inclui:

- valores de **itens de página** e **itens de aplicação**;
- **collections** (`APEX_COLLECTION`);
- **arquivos temporários** de upload (`APEX_APPLICATION_TEMP_FILES`);
- atributos da própria sessão (por exemplo, o idle timeout).

O session state fica em **tabelas do banco**. Isso é mais seguro que guardar no cliente e evita manter uma conexão de banco por usuário. A engine grava, para cada valor, **ID da aplicação, número da página, nome do item e valor**, isolados por sessão: uma sessão só enxerga o próprio estado. Desenvolvedores e administradores autenticados no workspace podem consultar o session state de qualquer app do workspace pelas páginas de monitoramento.

**Casos de uso de armazenamento temporário** (Developer's Companion):

1. **Tarefas em várias páginas** (wizard): os valores ficam guardados até o usuário concluir.
2. **Páginas de busca (query-by-example)**: filtros "grudam" durante a sessão sem ir para uma tabela.
3. **Collections temporárias**: por exemplo, um carrinho de compras até o checkout.
4. **Uploads de arquivos**: guardados até a lógica de negócio movê-los para as tabelas.

Fonte: [Understanding Session State Management (apxdc)](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-session-state-management.html), [Use Cases for Temporary Storage](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/use-cases-temporary-storage.html), [About Session State and Security](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-session-state-and-security.html), [How APEX Manages User Session State](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/how-apex-manages-user-session-state.html)

### Como gravar session state (submit, bind, computation, URL, API)

Formas documentadas de definir o valor de um item:

| Forma | Exemplo | Observação |
|---|---|---|
| **Submit do formulário** | usuário digita em `P1_PHONENO` e submete | A engine guarda automaticamente o valor digitado. |
| **Source do item** | *Source* do page item (coluna, SQL, expressão…) | Define o valor na renderização. |
| **Atribuição a bind** em PL/SQL (process, região PL/SQL, DA *Execute Server-side Code*) | `:MY_ITEM := 'novo valor';` | Também vale para colunas da linha corrente de um Interactive Grid (`:JOB := 'ANALYST';`). |
| **Computation** | `TO_CHAR(SYSDATE,'Day DD Month, YYYY')` | Computations existem para isso. |
| **URL** (`f?p` ou friendly URL) | `f?p=100:101:&APP_SESSION.::NO::MY_ITEM:ABC` | Sujeito a Session State Protection (checksum). |
| **API PL/SQL** | `APEX_UTIL.SET_SESSION_STATE('MY_ITEM', SYSDATE);` ou `APEX_SESSION_STATE.SET_VALUE(...)` | Use dentro de functions/procedures armazenadas. |

```sql
-- APEX_SESSION_STATE.SET_VALUE (assinatura VARCHAR2)
APEX_SESSION_STATE.SET_VALUE (
    p_item   IN VARCHAR2,
    p_value  IN VARCHAR2,
    p_commit IN BOOLEAN DEFAULT TRUE );

-- APEX_UTIL.SET_SESSION_STATE
APEX_UTIL.SET_SESSION_STATE (
    p_name   IN VARCHAR2 DEFAULT NULL,
    p_value  IN VARCHAR2 DEFAULT NULL,
    p_commit IN BOOLEAN  DEFAULT TRUE );
```

`p_commit => TRUE` (default) faz commit depois de alterar o session state. Não há commit se for `FALSE` **ou** se o valor não mudou. O parâmetro é **ignorado** quando a app usa **Session State Commits = End Of Request**. `SET_VALUE` tem quatro assinaturas (VARCHAR2 e outras variações tipadas). A lista completa está no documento 06.

Fonte: [Managing Session State Values (About Setting Session State)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-session-state-values.html), [Understanding Page Items (Referencing Item Values)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-page-items.html), [SET_VALUE Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_SESSION_STATE.SET_VALUE-Procedure-Signature-1.html), [SET_SESSION_STATE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_SESSION_STATE-Procedure.html), [Working with Page and App Data Values](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/working-page-and-app-data-values.html)

### Session State > Storage: Per Request (Memory Only), Per Session, Per User

O atributo do page item **Session State > Storage** (antes chamado de *Maintain Session State*) decide onde o valor fica:

| Opção | APEXlang `storage` | Comportamento | Quando usar |
|---|---|---|---|
| **Per Request (Memory Only)** | `request` | Não grava no banco. O valor só existe durante a requisição atual. **Em Ajax, o item precisa estar em *Page Items To Submit*.** | Itens de Form region que são salvos na tabela no mesmo submit; filtros que não precisam persistir. |
| **Per Session (Persistent / Disk)** | `session` (default para itens sem Form region) | Grava no banco e fica acessível em requisições seguintes da mesma sessão. | Wizard em várias páginas, chaves usadas por outras páginas (ex.: `P6_EMPNO` lido na página 7), valores usados em breadcrumbs. |
| **Per User (Persistent / Disk)** | `user` | Grava num repositório de atributos do usuário. O valor volta em **sessões futuras**. | Preferências e filtros "lembrados" entre logins. É mais simples que `APEX_UTIL.SET_PREFERENCE`/`GET_PREFERENCE`. |

- Itens de **Form region** criados por wizard nascem com **Per Request (Memory Only)**, e *Per User* não está disponível para eles (no APEXlang, itens com `formRegion` só aceitam `request` ou `session`, default `request`).
- Efeito colateral do Memory Only: na renderização, o item **começa NULL** antes das computations e processes do Pre-Rendering. Por isso um formulário aberto sem a PK fica vazio.
- **Session State > Data Type** (APEXlang `dataType`): `varchar2` (default), `clob`, `boolean`, `number`.

Fonte: [Managing Session State Values (About Controlling How Items Write Session State)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-session-state-values.html), [Memory Only Storage for Form Page Items](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/memory-only-storage-form-page-items.html), [User-Specific Temporary Storage](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/user-specific-temporary-storage.html), [APEXlang API Reference: pageItem sessionState](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Session State Commits: Immediate × End Of Request

O APEX mantém o session state em **variáveis globais PL/SQL** (acesso rápido) e em **tabelas**. O atributo **Session State Commits** (*Security > Session Management*; APEXlang `sessionStateCommits`, default `endOfRequest`) decide quando as mudanças são gravadas e commitadas:

- **Immediate**: quando o estado muda durante a requisição (por exemplo, um process atribui um bind), a mudança é gravada e **commitada na hora**. Esse commit é da **transação principal**, então leva junto o DML pendente nas tabelas da aplicação.
- **End Of Request**: o APEX acumula as mudanças e as aplica no fim da requisição. Dá melhor controle transacional e funciona com Application Continuity em quedas não planejadas. O `p_commit` de `SET_SESSION_STATE`/`SET_VALUE` é ignorado nesse modo.

Collections fazem parte do session state, mas **não** seguem esse atributo.

Fonte: [Configuring Security Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-security-attributes.html), [APEXlang API Reference: app sessionManagement](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Limpar session state: clear cache por item, página, app e sessão

Limpar o cache de um item faz o valor voltar a **NULL**. Isso pode ser feito por item, pela página inteira, pela aplicação ou pela sessão. Pelo argumento *ClearCache* da URL:

| Valor em ClearCache | Efeito |
|---|---|
| `MY_ITEM` ou `ITEM1,ITEM2` | Limpa só esses itens. |
| `6003` ou `6004,6014` | Limpa todos os itens das páginas listadas. Também **reseta processos stateful** da página. |
| nome de **collection** | Reseta a collection. |
| `RP` | Reseta a **paginação** dos relatórios da página **requisitada**. |
| `RR` | Reseta **Interactive Report, Interactive Grid ou Classic Report e a paginação**. IR/IG voltam ao relatório default (do desenvolvedor ou salvo pelo usuário); o Classic Report volta à ordenação definida pelo desenvolvedor. Desde o APEX 2.1 `RR` cobre "reset report + reset pagination". |
| `CR` | Só Interactive Report: limpa as configurações de sessão (control break, aggregate, flashback, chart, linhas por página, filtros, highlight, computation, group by, pivot) e reseta a paginação. |
| `APP` | Limpa todas as páginas e todos os itens de aplicação da app atual e remove as preferências de ordenação do usuário. |
| `SESSION` | Igual a `APP`, mas para **todas as aplicações** usadas na sessão atual. |

Exemplos:

```
f?p=100:5:&APP_SESSION.::NO:MY_ITEM                          -- limpa um item
f?p=100:5:&APP_SESSION.::NO:THE_EMPNO,THE_DEPTNO             -- limpa dois itens
f?p=6000:6003:&APP_SESSION.::NO:RP,6004,6014                 -- limpa pág. 6004 e 6014 + reseta paginação da 6003
f?p=6000:6003:&APP_SESSION.::NO:6003:MY_ITEM:1234            -- limpa a 6003 e seta MY_ITEM=1234 (form de edição)
f?p=6000:6004:&APP_SESSION.::NO:6003:MY_ITEM1,MY_ITEM2,MY_ITEM3:1234,,5678  -- MY_ITEM2 fica NULL
f?p=6000:6003:&APP_SESSION.::NO:RR                           -- reseta relatórios e paginação
f?p=App:Page:Session::NO:APP                                 -- limpa a aplicação
f?p=6000:6004:12507785108488427528::NO:SESSION               -- limpa a sessão
```

Outras formas declarativas:

- **Clear Cache no Link Builder**: qualquer alvo de link (botão, entrada de lista, coluna de link, breadcrumb) aceita uma lista de páginas, collections e `RP` para limpar.
- **Process "Clear Session State"**: limpa no fim do submit, por exemplo no botão Finish de um wizard, depois de inserir os dados.
- **API**: `APEX_UTIL.CLEAR_PAGE_CACHE(p_page_id IN NUMBER DEFAULT NULL)` (sem parâmetro limpa a página atual) e `APEX_UTIL.CLEAR_APP_CACHE`.

**Boa prática de segurança:** limpe o session state que não é mais necessário como parte do fluxo, com processes de clear cache ou com clear cache nas URLs.

Fonte: [Managing Session State Values (Clearing Session State)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-session-state-values.html), [Understanding f?p URL Syntax](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-legacy-url-syntax.html), [Clearing State with Link Target Settings](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/clearing-state-link-target-settings.html), [Clearing State with a Page Process](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/clearing-state-page-process.html), [CLEAR_PAGE_CACHE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CLEAR_PAGE_CACHE-Procedure.html), [About Session State and Security](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-session-state-and-security.html)

### Resetar uma aplicação por completo (APP não basta)

Limpar o cache da aplicação inteira (`APP`) **não** devolve a app a um estado totalmente zerado. Se houver computations ou processes **On New Instance**, a engine os executa ao criar a sessão, depois processa o clear cache e mostra a página.

Para resetar de verdade:

- **Sem cookie de sessão**: peça a app com uma URL **sem session ID**, ou chame `APEX_UTIL.CLEAR_APP_CACHE` a partir de **outra** aplicação.
- **Com o session ID num cookie**: é preciso **fazer logout**.

Fonte: [Managing Session State Values (About Resetting an Application Completely)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-session-state-values.html)

### Itens sensíveis: password sem estado e session state criptografado

- Use itens do tipo **password que não salvam estado**, para a senha digitada não ir para as tabelas de session state.
- Dados sensíveis que precisam persistir na sessão devem ir **criptografados**: ligue **Store value encrypted in session state** no item. O valor é descriptografado automaticamente na leitura. O limite é de **4000 bytes**; acima disso, dá erro.
- A criptografia impede que outros desenvolvedores ou DBAs leiam o valor nas tabelas de session state, no debug ou nos datafiles. A Oracle recomenda também backups criptografados.

Fonte: [About Session State and Security](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-session-state-and-security.html)

### Inspecionar e sobrescrever session state em runtime (Developer Toolbar)

**Session > View Session State** na Developer Toolbar abre a página de sessão, que mostra:

- Application, Session (ID), User, Workspace (ID) e Browser Language;
- filtros: **Page** (número), **Find** (busca sem distinção de maiúsculas em nome e valor do item ou nome da collection), **Rows** e **View**, que escolhe o relatório: itens de página, itens de aplicação, collections, **Background Executions**…

**Session > Session Overrides** permite, só para o desenvolvedor e só nessa sessão, sobrescrever:

- **Globalization**: Application Language, Document Direction (LTR/RTL), Timezone;
- **File Paths**: `#APP_FILES#`, `#WORKSPACE_FILES#`, `#THEME_FILES#` (por exemplo, apontar para `localhost:PORT` em desenvolvimento local);
- **Additional Files**: JavaScript URLs e CSS URLs extras.

O switch *Enable Session Overrides* liga ou desliga todos de uma vez. Os botões são *Save*, *Reset* e *Cancel*.

Fonte: [Managing Session State](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-session-state.html), [Inspecting Session State for Debugging](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/inspecting-session-state-debugging.html)

### Collections e arquivos temporários como session state

- **Collections**: guardam várias linhas temporárias por sessão, sem definição formal. As colunas são genéricas: `c001`–`c050` (VARCHAR2), `n001`–`n005` (NUMBER), `d001`–`d005` (DATE), `clob001`, `blob001` e `xmltype001`. Você cria com `APEX_COLLECTION.CREATE_COLLECTION`, adiciona membros com `ADD_MEMBER` (o `SEQ_ID` é incremental), altera e remove com `UPDATE_MEMBER`/`DELETE_MEMBER`, lê pela view `APEX_COLLECTIONS ... WHERE collection_name = '...'` e limpa com `TRUNCATE_COLLECTION`. Cada sessão só vê as próprias collections, e elas são apagadas no fim da sessão.
  - **Dica**: crie uma **view** sobre a collection com nomes de coluna significativos e um **package de API** que encapsule `APEX_COLLECTION`.
  - Para usar uma collection com um **Interactive Grid**, guarde uma chave estável (ex.: `SYS_GUID()`) numa coluna, porque o grid precisa de PK que não muda.
- **Arquivos temporários**: os itens *File Upload* e *Image Upload* com *Storage Type* = `Table APEX_APPLICATION_TEMP_FILES` e *Purge File at* = *End of Session* deixam os arquivos consultáveis durante a sessão. A coluna `NAME` identifica o arquivo (é o valor do item); `FILENAME` é o nome original. Com upload múltiplo, o valor do item é uma lista de `NAME` separada por `:`.

```sql
select blob_content, mime_type, filename
  from apex_application_temp_files
 where name in (select column_value
                  from apex_string.split(:P1_MULTI_FILE_UPLOAD, ':'));
```

> O exemplo oficial do Developer's Companion passa o **literal** `'P1_MULTI_FILE_UPLOAD'` para `apex_string.split`. O correto é passar o **valor** do item (`:P1_MULTI_FILE_UPLOAD`), como acima.

Detalhes de `APEX_COLLECTION` estão nos documentos 06 e 11.

Fonte: [Key Collections Concepts](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/key-collections-concepts.html), [Tips for Maintainable Collection Use](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/tips-maintainable-collection-use.html), [Temporary Files](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/temporary-files.html)

---

## 5. Sintaxe de URL

### Friendly URL × f?p: qual a app usa (atributo Friendly URLs)

O APEX aceita duas sintaxes de URL:

- **Friendly URL Syntax**: o padrão de apps criadas a partir do APEX 20.1 (APEXlang `friendlyUrls`, default `true`). Usa hierarquia de diretórios e parâmetros web padrão.
- **f?p Syntax**: sintaxe legada, com os argumentos separados por `:`.

A troca fica em *Application Definition > Properties > Friendly URLs*: **On** usa friendly URL, **Off** usa `f?p=`. Friendly URL não é a mesma coisa que vanity URL ou domínio próprio, que se configuram no servidor web ou no load balancer.

A doc de `f?p` e a de checksums (`APEX_PAGE.GET_URL` devolve uma URL `f?p=`) continuam valendo: os componentes declarativos (Link Builder, branches, listas) e as APIs geram a URL certa para o modo da app.

Fonte: [Understanding URL Syntax](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-url-syntax.html), [Understanding Friendly URL Syntax](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-friendly-url-syntax.html)

### Friendly URL: estrutura e parâmetros suportados

```
https://hostname:port/ords/r/path_prefix/app_alias/page_alias?parameters
https://hostname:port/ords/r/mycompany/hr-app/update-employees?session=13766599855150
```

| Parte | Significado |
|---|---|
| `ords` | nome do serviço configurado no ORDS |
| `r` | atalho do router. É **constante**: nunca altere. |
| `path_prefix` | prefixo de URI do workspace (default = nome do workspace). Muda em *Workspace Administration > Manage Service > Set Workspace Preferences > SQL Workshop > Path Prefix*, que só aparece com RESTful Services habilitado. |
| `app_alias` | **Application Alias** (default = nome da app; único no workspace). Muda na Application Definition. |
| `page_alias` | **Page Alias** (default = nome da página; único na app; se repetir, o APEX acrescenta um número). Muda em *Page Designer > Identification > Page Alias*. |
| `?parameters` | parâmetros web |

Parâmetros suportados depois de `?`:

| Parâmetro | Equivalente |
|---|---|
| `session` | session ID |
| `request` | `REQUEST` |
| `clear` | ClearCache (ex.: `clear=7`, `clear=RP`) |
| `debug` | modo debug |
| `<item>=<valor>` (ex.: `p7_customer_id=377`) | define session state de itens de página ou de aplicação |
| `printerFriendly` | modo de impressão |
| `trace` | SQL trace |
| `timezone`, `lang`, `territory` | globalização |
| `cs` | **checksum** de Session State Protection |
| `dialogCs` | checksum de diálogo |
| `x01` | parâmetro genérico (ver `APEX_PAGE.GET_URL p_x01`) |

Exemplo da doc: `…/page_alias?p7_customer_id=377&clear=7&session=1247058356345&cs=3MdkfQa9…`

Fonte: [Understanding Friendly URL Syntax](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-friendly-url-syntax.html)

### Sintaxe f?p: os nove argumentos (App:Page:Session:Request:Debug:ClearCache:itemNames:itemValues:PrinterFriendly)

```
f?p=App:Page:Session:Request:Debug:ClearCache:itemNames:itemValues:PrinterFriendly
https://hostname:port/ords/f?p=392:3:13766599855150
```

| # | Argumento | Descrição | Como referenciar |
|---|---|---|---|
| 1 | `App` | ID ou **alias** da aplicação | `&APP_ID.`, `&APP_ALIAS.` |
| 2 | `Page` | número ou **alias** da página | `&APP_PAGE_ID.`, `&APP_PAGE_ALIAS.` |
| 3 | `Session` | session ID, para manter o mesmo session state | `&SESSION.`/`&APP_SESSION.`, `V('SESSION')`, `:APP_SESSION` |
| 4 | `Request` | valor de `REQUEST` | `&REQUEST.`, `V('REQUEST')`, `:REQUEST` |
| 5 | `Debug` | `YES`, `NO` ou `LEVELn` (n de 1 a 9; `YES` = `LEVEL4`) | `&DEBUG.`, `V('DEBUG')`, `:DEBUG` |
| 6 | `ClearCache` | páginas, itens, collections, `RP`, `RR`, `CR`, `APP`, `SESSION` (ver §4) | |
| 7 | `itemNames` | nomes de item separados por vírgula | |
| 8 | `itemValues` | valores na mesma ordem | |
| 9 | `PrinterFriendly` | `YES` renderiza com o template printer friendly | `V('PRINTER_FRIENDLY')` |

Regras de valores:

- Valores passados em `f?p=` **não podem conter `:`**, que é o separador dos argumentos.
- Para passar uma **vírgula** dentro de um valor, envolva o valor em **barras invertidas**: `\1234,56\`. Qualquer sequência pode ir entre barras, exceto `\,`.
- No modo printer friendly, o texto dos campos de formulário sai como texto e o template de impressão não precisa de `#FORM_OPEN#`/`#FORM_CLOSE#`.
- Os aliases de app e página precisam ser identificadores Oracle válidos, sem espaço e **sem distinção de maiúsculas**: `f?p=myapp:home:&APP_SESSION.`.
- O alias de aplicação é único **no workspace**. Se outro workspace tem o mesmo alias, informe o workspace com `&c=`: `f?p=common_alias:home:&APP_SESSION.&c=WORKSPACE_A`.

Fonte: [Understanding f?p URL Syntax](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-legacy-url-syntax.html)

### Links entre páginas: Link Builder, botão com URL × botão que submete

- Os wizards e o **Link Builder** (alvo de botões, colunas de link, entradas de lista, breadcrumbs e branches) montam as URLs sozinhos. Nele você define *Page*, *Set Items* (nome e valor), *Clear Cache*, *Request* e *reset pagination*.
- **Botão com URL de redirect** (`f?p=6000:6001:&APP_SESSION.`): funciona como um hyperlink, **sem submeter a página**. O que o usuário digitou não vai para o session state.
- **Botão que submete** (*Action = Submit Page*): envia os valores, roda o Accept e salva o session state.
- **Link Column** de relatório: em *Set Items*, o wizard usa o valor `\#EMPNO#\`. As barras invertidas fazem o valor ser usado **literalmente**, mesmo que contenha delimitadores como `:`. Para chaves simples não são estritamente necessárias, mas não fazem mal.

Fonte: [Understanding f?p URL Syntax (Calling a Page from a Button URL)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-legacy-url-syntax.html), [Linking to the Edit Page](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/linking-edit-page.html)

### Session State Protection e checksums de URL (cs=)

**Session State Protection (SSP)** impede que a URL seja adulterada para alterar session state, lógica ou privacidade. A ativação tem dois passos:

1. Habilitar SSP na aplicação: *Shared Components > Security > Session State Protection > Set Protection > Enable*. APEXlang: `sessionStateProtection { enabled: true }`.
2. Definir os atributos de segurança das páginas e dos itens, por wizard (que aplica um valor a toda a app) ou um por um.

Com SSP ligado, o APEX acrescenta um **checksum** (`&cs=…`) às URLs geradas e o confere na chegada. Com SSP desligado, os atributos são **ignorados** (exceto *Restricted*, ver abaixo) e as URLs geradas não levam checksum.

**Page Access Protection** (atributo da página, *Security*):

| Valor | APEXlang | Efeito |
|---|---|---|
| Unrestricted | `unrestricted` | Aceita URL com ou sem argumentos, sem checksum. |
| **Arguments Must Have Checksum** | `argumentsMustHaveChecksum` | Se a URL trouxer Request, Clear Cache ou pares item/valor, **precisa** de checksum compatível com a proteção mais rígida entre os itens passados. |
| No Arguments Supported | | Aceita URL, mas sem Request, Clear Cache nem itens. |
| No URL Access | | Não abre por URL. Só pode ser alvo de um branch *Branch to Page*, que não faz redirect. |

**Session State Protection do item** (page item ou application item):

| Valor | Quem pode setar pela URL |
|---|---|
| Unrestricted | Qualquer URL ou form, sem checksum. **Obrigatório para itens setados por Ajax** (DA Set Value, *Page Items to Submit*, cascading LOV). |
| Checksum Required: Application Level | URL com checksum da app e do workspace, gerado por qualquer usuário. Checksum de usuário ou de sessão também serve. |
| Checksum Required: User Level | URL com checksum do mesmo usuário nomeado, em qualquer sessão. Checksum de sessão também serve. |
| Checksum Required: Session Level | URL com checksum gerado **nesta sessão**. |
| **Restricted - May not be set from browser** | Ninguém, nem URL nem POST. Só processes, computations etc. **Vale mesmo com SSP desligado.** Default de application item no APEXlang (`restricted`). |

Atributos da aplicação ligados a checksum:

- **Bookmark Hash Function**: algoritmo dos checksums de app e de usuário. APEXlang `bookmarkHashFunction`, default `sha2-512bit`; também `sha1`, `sha2-256bit`, `sha2-384bit`, `md5`.
- **Expire Bookmarks**: troca o *checksum salt* e invalida favoritos com checksums antigos. Também é o caminho para mudar o algoritmo.
- **Allow URLs Created After**: data a partir da qual favoritos com checksum valem.

Fonte: [Preventing URL Tampering](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/preventing-url-tampering.html), [Configuring Security Attributes (Session State Protection)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-security-attributes.html), [Managing Application Items](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-application-items.html), [APEXlang API Reference: appItem, app](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Gerar URLs com checksum em PL/SQL: APEX_PAGE.GET_URL e APEX_UTIL.PREPARE_URL

URL montada à mão com itens **não leva checksum** e falha em páginas *Arguments Must Have Checksum*. Em PL/SQL e SQL, use:

```sql
APEX_PAGE.GET_URL (
    p_application        IN VARCHAR2 DEFAULT NULL,   -- ID ou alias; default = app atual
    p_page               IN VARCHAR2 DEFAULT NULL,   -- ID ou alias; default = página atual
    p_session            IN NUMBER   DEFAULT apex_application.g_instance,
    p_request            IN VARCHAR2 DEFAULT NULL,
    p_debug              IN VARCHAR2 DEFAULT NULL,   -- default = modo debug atual
    p_clear_cache        IN VARCHAR2 DEFAULT NULL,
    p_items              IN VARCHAR2 DEFAULT NULL,   -- nomes separados por vírgula
    p_values             IN VARCHAR2 DEFAULT NULL,   -- valores separados por vírgula
    p_printer_friendly   IN VARCHAR2 DEFAULT NULL,
    p_trace              IN VARCHAR2 DEFAULT NULL,
    p_x01                IN VARCHAR2 DEFAULT NULL,   -- acrescenta &x01=valor
    p_hash               IN VARCHAR2 DEFAULT NULL,   -- acrescenta #hash
    p_triggering_element IN VARCHAR2 DEFAULT 'this', -- seletor jQuery; necessário para modal dialog
    p_plain_url          IN BOOLEAN  DEFAULT FALSE,  -- TRUE: sem o JS de fechar diálogo
    p_absolute_url       IN BOOLEAN  DEFAULT FALSE ) -- TRUE: sempre URL absoluta
    RETURN VARCHAR2;
```

```sql
-- As duas colunas geram a mesma URL (com checksum, se necessário)
select apex_page.get_url(
           p_page   => 1,
           p_items  => 'P1_X,P1_Y',
           p_values => 'somevalue,othervalue') f_url_1,
       apex_util.prepare_url(
           'f?p=&APP_ID.:1:&APP_SESSION.::::P1_X,P1_Y:somevalue,othervalue') f_url_2
  from dual;
```

- A Oracle recomenda **`APEX_PAGE.GET_URL`** em vez de `PREPARE_URL`, pela legibilidade.
- **App de outro workspace**: a URL sai **sem checksum**, por segurança.
- `PREPARE_URL(p_url, p_url_charset, p_checksum_type, p_triggering_element, p_plain_url)`. Em `p_checksum_type`: `PUBLIC_BOOKMARK`/`1` (link para qualquer usuário, como num e-mail), `PRIVATE_BOOKMARK`/`2` (fora da sessão, mesmo usuário) e `SESSION`/`3` (links da própria app).
- O retorno contém `&cs=<hex>`. Em JavaScript ou HTML pode ser preciso escapar o `&`.
- Se a página que chama é um **modal dialog**, a URL vem com o JS de fechar o diálogo. Use `p_plain_url => TRUE` para evitar.
- `PREPARE_URL` também aplica o **zero session ID** para usuário público em página pública.

Fonte: [GET_URL Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_URL-Function.html), [PREPARE_URL Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PREPARE_URL-Function.html)

---

## 6. Como referenciar valores (itens, colunas, built-ins)

### Tabela-resumo: qual sintaxe usar em cada contexto

| Contexto | Sintaxe | Observações |
|---|---|---|
| SQL e PL/SQL **escritos dentro do APEX** (região, LOV, process, validation, condition, DA *Execute Server-side Code*, workflow) | `:MY_ITEM` ou `:"MY-ITEM"` | Bind variable. **Sempre VARCHAR2** (exceções na §9). Nome de até 30 caracteres. Não distingue maiúsculas. Não funciona em DDL. |
| PL/SQL **armazenado** (package, function, trigger, policy de Data Redaction/VPD) | `V('MY_ITEM')`, `NV('MY_NUMERIC_ITEM')`, `APEX_SESSION_STATE.GET_VARCHAR2/GET_NUMBER/GET_TIMESTAMP/GET_CLOB/GET_BOOLEAN/GET_VALUE('MY_ITEM')` | `V()` é atalho de `APEX_SESSION_STATE.GET_VARCHAR2`. **Evite em SQL**: cai o desempenho. Se precisar, use `(select v('my_item') from dual)`. Em código reutilizável, prefira receber parâmetros. |
| Texto estático e atributos que aceitam substituição (título de região, label, HTML, URL, HTML Expression de Cards, Content Row, Template Component, IG) | `&MY_ITEM.` ou `&"MY_ITEM".` | Substituição **exata**, com o **ponto final obrigatório**. **Não use em SQL/PL/SQL** (risco de SQL injection). Itens **CLOB não** funcionam com essa sintaxe. |
| Templates e colunas de **Classic Report / Interactive Report** | `#COLUMN#`, `#"Name"#` | Placeholder de template. |
| Filtro de escape | `&ITEM!HTML.`, `#COL!ATTR#` … | `HTML`, `ATTR`, `JS`, `RAW`, `STRIPHTML` |
| Contexto de banco (queries, VPD) | `SYS_CONTEXT('APEX$SESSION','APP_USER')`, `'APP_SESSION'`, `'APP_ID'`, `'WORKSPACE_ID'` | O APEX monta o contexto `APEX$SESSION` no início de cada requisição. |
| Dentro de template directive | `NAME` sem prefixo nem sufixo: `{if TITLE/}` | O conteúdo usa `&NAME.` ou `#NAME#` conforme o contexto. |
| JavaScript | `$v('P1_ITEM')`, `$s('P1_ITEM','x')`, `apex.item(...)` | O `id` do elemento é o **nome do item**, não o label. |
| Text message (compatibilidade 24.2 ou superior) | `&{MSG.KEY}.` | Com parâmetros, ver abaixo. |

Fonte: [Managing Session State Values (About Referencing Session State)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-session-state-values.html), [Understanding Page Items](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-page-items.html), [Using Data Values in SQL and PL/SQL](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-data-values-sql-and-pl-sql.html), [Using Data Values in Named Program Units](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-data-values-named-program-units.html), [Using Built-in Substitution Strings](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-available-built-in-substitution-strings.html)

### Bind variables (:ITEM): regras, regiões SQL e blocos PL/SQL

Regras:

1. O nome do bind tem de **corresponder a um item** (de página ou de aplicação) ou a uma built-in.
2. Não distingue maiúsculas.
3. **No máximo 30 caracteres** (identificador Oracle válido). Itens podem ter até 255, mas os maiores que 30 **não** podem ser usados como bind.
4. O tipo do bind é o *Session State Data Type* do item, na prática **VARCHAR2**. Para data ou número, converta explicitamente.
5. Bind deixa o banco reutilizar o SQL já analisado e economiza memória.
6. Em região *SQL Query*, *SQL Query (PL/SQL function body returning SQL query)* e LOV: `where department_id = :THE_DEPTNO`.
7. Em regiões, processes, computations, validations e conditions do tipo PL/SQL, o código é um bloco anônimo; leia e atribua com `:ITEM`.

```sql
select * from employees where last_name like '%' || :SEARCH_STRING || '%';
select * from employees where start_date < to_date(:DATE_STRING, 'DD-MON-YYYY');
```

```sql
if :P1_JOB is not null then
  insert into employees (employee_id, first_name, job_id)
  values (:P1_EMP_ID, :P1_NAME, :P1_JOB);
end if;
```

Atenção: `:USER` tem significado especial no banco. Use `:APP_USER`.

Fonte: [Managing Session State Values (Referencing Session State Using Bind Variable Syntax)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-session-state-values.html), [Using Built-in Substitution Strings](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-available-built-in-substitution-strings.html)

### Page Items to Submit / Items to Return: o bind que "vira NULL"

Quando uma região (relatório, chart) usa `:P1_X` na query, coloque `P1_X` (sem os dois-pontos) em **Page Items to Submit** da região. Separe vários com vírgula. Se esquecer, no **refresh** (Ajax) o bind avalia como **NULL**: a query volta vazia ou a lógica toma o caminho errado.

O mesmo vale para a DA **Execute Server-side Code**: os itens e colunas lidos vão em **Items to Submit**, e os que o código altera vão em **Items to Return**. Se esquecer, aparecem erros **No Data Found** ou a página não recebe os valores calculados.

Itens com **Per Request (Memory Only)** só chegam ao servidor em Ajax se estiverem listados em *Page Items To Submit*.

Fonte: [Configure Items to Submit and Return](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configure-items-submit-and-return.html), [Understanding AJAX and Redirect](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-ajax-and-redirect.html), [Managing Session State Values](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-session-state-values.html)

### Substituição &ITEM. (Session State Substitution) e #PLACEHOLDER# (template)

- **Session State Substitution** (`&ITEM.`): nome em maiúsculas, precedido de `&` e terminado em `.` (obrigatório). Funciona em região, título de região, label de item e em qualquer texto estático. Exemplo: `&F101_X.`. Também referencia **colunas** em HTML Expressions de **Interactive Grid, Cards, Map e Content Row** (`&ENAME.`).
- **Placeholder Substitution** (`#ABC#`): usado **dentro de templates** e em colunas de **Classic Report e Interactive Report** (`#ENAME#`).
- **Nome com caractere especial ou case-sensitive**: entre aspas, `&"ITEM-OR-COLUMN-NAME".` e `#"Name"#`. Sintaxe geral: `&"<name>"[!<format>].`. Sem aspas, o nome tem de estar em `A-Z 0-9 _ $ #`. O nome pode ser `APP_TEXT$<message-name>`.
- No lado do cliente, `apex.util.applyTemplate` avalia templates em JavaScript (o filtro `JS` não funciona em substituições feitas no cliente).
- Para saber se um atributo aceita substituições ou directives, veja a aba **Help** do Page Designer ("Additional Information", "Supports Server-side/Client-side Template Directives").

```html
<!-- Cards / Content Row / IG -->
<strong>&DNAME.</strong> → &LOC.
<!-- Classic / Interactive Report: HTML Expression da coluna DNAME (LOC pode ficar Hidden) -->
<strong>#DNAME#</strong> → #LOC#
```

Fonte: [About Using Substitution Strings](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-using-substitution-strings.html), [Basic Templates](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/basic-templates.html), [Using Data Values in HTML Expressions](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-data-values-html-expressions.html), [Using the Context-Sensitive Help Tab](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-context-sensitive-help-tab.html)

### Filtros de escape: !HTML, !ATTR, !JS, !RAW, !STRIPHTML

Acrescente `!FILTRO` ao nome para controlar o escape e evitar **XSS**. O APEX já escapa automaticamente, na medida do possível, em contexto HTML e JS; o filtro dá controle fino.

| Filtro | Efeito | Clássico | Moderno |
|---|---|---|---|
| `HTML` | escapa caracteres reservados de HTML | `#NAME!HTML#` | `&NAME!HTML.` |
| `ATTR` | escapa para **atributo** HTML (ex.: `href`) | `#NAME!ATTR#` | `&NAME!ATTR.` |
| `JS` | escapa para contexto **JavaScript**. **Não funciona em substituições feitas no cliente.** | `#NAME!JS#` | `&NAME!JS.` |
| `STRIPHTML` | remove tags HTML e escapa o resto | `#NAME!STRIPHTML#` | `&NAME!STRIPHTML.` |
| `RAW` | **não escapa** e mantém o valor original | `#NAME!RAW#` | `&NAME!RAW.` |

Usos típicos:

```html
<a href="#TARGET_LINK!ATTR#"><strong>#DNAME#</strong></a>   <!-- valor em atributo -->
<i>#DESCRIPTION_IN_HTML!RAW#</i>                            <!-- coluna que já contém HTML confiável -->
&APP_TEXT$DELETE_MSG!RAW.                                   <!-- mensagem de confirmação com markup -->
```

Equivalentes em PL/SQL: `APEX_ESCAPE.HTML`, `APEX_ESCAPE.HTML_ATTRIBUTE`, `APEX_ESCAPE.JS_LITERAL`. Use `RAW` só com conteúdo confiável.

O atributo de app item **Escape Special Characters** (default `true` no APEXlang) escapa o valor nas substituições `&ITEM.`. Desligue só se precisar renderizar HTML guardado no item. *HTML Escaping Mode* da app: `Basic` (`& " < >`) ou `Extended` (default; acrescenta `'`, `/` e não-ASCII quando o charset não é AL32UTF8).

Fonte: [Controlling Output Escaping in Substitution Strings](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/controlling-output-escaping-in-substitution-strings.html), [Basic Templates (Escape Filters)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/basic-templates.html), [Using Data Values in HTML Expressions](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-data-values-html-expressions.html), [Managing Application Items](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-application-items.html), [Configuring Security Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-security-attributes.html)

### Text messages em substituições: &{MSG}. (24.2 ou superior) e APP_TEXT$ (legado)

**Sintaxe curta (Compatibility Mode 24.2 ou superior):**

```
&{TEXT.MSG}.
```

- O nome pode ter caracteres especiais, exceto espaço e `}`.
- **Parâmetros** vão antes do `}` como `nome=valor`, separados por espaço. O nome especial `$lang` escolhe o idioma.
- O valor pode ser: substituição sem aspas (`&P1_NAME.`) ou com aspas (`&"X-1".`), ambas com escape HTML por padrão; literal sem aspas (sem aspas duplas, espaço nem `}`); ou literal entre aspas, com `""` para inserir uma aspa.

```
&{TEXT->MSG
Unquoted_Substitution=&P1_NAME!RAW.
Quoted_Substitution=&"Quoted name"!RAW.
Unquoted_Literal=how/do.you!do?
Quoted_Literal="Jerry Garcia
Ron ""Pigpen"" McKerhan"
$lang=FR}!HTML.
```

**Sintaxe legada** (ainda suportada, não recomendada): `&APP_TEXT$MY_MESSAGE!HTML.` e, com idioma, `&APP_TEXT$MY_MESSAGE$FR!HTML.`. O nome tem de ser identificador (`A-Z 0-9 $ # _`). Também funciona como bind (`:APP_TEXT$MSG`) e em `V('APP_TEXT$MSG')`.

Mensagens internas do APEX podem ser redefinidas como text message da app. Exemplos: `APEX.GO_TO_ERROR`, o link "Go to Error" das validações (um espaço só remove o link); e `DELETE_MSG`, a confirmação do botão Delete, que precisa de *Used in JavaScript* ligado.

Fonte: [About Using Substitution Strings (Substitutions in Text Messages)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-using-substitution-strings.html), [Basic Templates (Substitutions in Text Messages - Legacy)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/basic-templates.html), [Understanding Validations (Go to Error)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-validations.html), [Conditional Database Action Buttons](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/conditional-database-action-buttons.html)

### Referenciar itens em JavaScript ($v, $s)

Cada item tem no HTML um atributo `id` igual ao **nome do item** (por exemplo, `P1_FIRST_NAME`), não ao label. Para ler e gravar:

```javascript
function showFirstName(){
  alert('First Name is ' + $v('P1_FIRST_NAME'));
}
function setFirstName(pFirstName){
  $s('P1_FIRST_NAME', pFirstName);
}
```

Essas funções podem ser chamadas de outras funções ou de uma DA *Execute JavaScript Code*. Mudar um valor no cliente **não** atualiza o session state no servidor: isso só acontece num submit ou num Ajax que inclua o item (ver §6, *Page Items to Submit*). A API JS completa está no documento 08.

Fonte: [Understanding Page Items (About Referencing Items Using JavaScript)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-page-items.html), [Understanding AJAX and Redirect](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-ajax-and-redirect.html)

---

## 7. Substitution strings built-in

### Built-ins de identificação: APP_ID, APP_ALIAS, APP_PAGE_ID, APP_PAGE_ALIAS, MAIN_APP_ID, WORKSPACE_ID

| Built-in | O que é | Bind | PL/SQL | Substituição | Outras |
|---|---|---|---|---|---|
| `APP_ID` | ID da app em execução | `:APP_ID` | `NV('APP_ID')` | `&APP_ID.` | `APEX_APPLICATION.G_FLOW_ID` (NUMBER); `SYS_CONTEXT('APEX$SESSION','APP_ID')` |
| `APP_ALIAS` | alias alfanumérico (único no workspace; o `APP_ID` é único na instância) | `:APP_ALIAS` | `V('APP_ALIAS')` | `&APP_ALIAS.` | |
| `APP_PAGE_ID` | página atual | `:APP_PAGE_ID` | `NV('APP_PAGE_ID')` | `&APP_PAGE_ID.` | |
| `APP_PAGE_ALIAS` | alias da página atual (opcional; único na app; sem distinção de maiúsculas) | `:APP_PAGE_ALIAS` | `v('APP_PAGE_ALIAS')` | `&APP_PAGE_ALIAS.` | |
| `MAIN_APP_ID` | ID da app principal quando a atual é **working copy**; senão, o ID atual | `:MAIN_APP_ID` | `NV('MAIN_APP_ID')` | `&MAIN_APP_ID.` | |
| `WORKSPACE_ID` | ID do workspace | `:WORKSPACE_ID` | `V('WORKSPACE_ID')` | `&WORKSPACE_ID.` | `SYS_CONTEXT('APEX$SESSION','WORKSPACE_ID')` |
| `APP_REGION_ID` | ID da região em execução | `:APP_REGION_ID` | `v('APP_REGION_ID')` | `&APP_REGION_ID.` | |
| `APP_REGION_DOM_ID` | DOM ID (HTML) da região em execução; NULL se não definido | `:APP_REGION_DOM_ID` | `v(...)` | `&APP_REGION_DOM_ID.` | substitui `APP_REGION_STATIC_ID` (**deprecated**) |

```
f?p=&APP_ID.:&APP_PAGE_ID.:&APP_SESSION.     -- recarregar a página atual
select ... where application_id = sys_context('APEX$SESSION','APP_ID')
```

Fonte: [Using Built-in Substitution Strings](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-available-built-in-substitution-strings.html)

### Built-ins de sessão e usuário: APP_SESSION, SESSION, APP_SESSION_VISIBLE, APP_USER, APP_BUILDER_SESSION

- **`APP_SESSION`** é a built-in mais usada: o session ID, para links que mantêm o session state. **`SESSION`** é sinônimo.
  - Bind `:APP_SESSION`; PL/SQL `V('APP_SESSION')` ou `V('SESSION')`; substituição `&APP_SESSION.`; contexto `SYS_CONTEXT('APEX$SESSION','APP_SESSION')`.
  - Exemplos: `<a href="f?p=100:5:&APP_SESSION.">`, `htf.anchor('f?p=100:5:'||V('APP_SESSION'),'click me')`.
- **`APP_SESSION_VISIBLE`**: como `APP_SESSION`, mas devolve `'0'` para usuário não autenticado quando o Zero Session ID está em uso.
- **`APP_USER`**: o usuário atual. Com autenticação de banco, é igual ao pseudo-coluna `USER`. Com outros esquemas, é o que o esquema definiu, em geral o nome usado no login. Antes do login vale o *Public User* da app (as condições *User is the public user* e *User is authenticated* se baseiam nisso).
  - Bind `:APP_USER`, PL/SQL `V('APP_USER')`, `&APP_USER.`, `SYS_CONTEXT('APEX$SESSION','APP_USER')`. É útil em VPD.
- **`APP_BUILDER_SESSION`**: o session ID do **Builder** se o usuário também está logado como desenvolvedor; senão, NULL. Útil para mostrar elementos só em desenvolvimento.

```sql
select * from some_table where user_id = :APP_USER;
select ... where username = sys_context('APEX$SESSION','APP_USER');
```

Fonte: [Using Built-in Substitution Strings (APP_SESSION, APP_SESSION_VISIBLE, APP_USER, APP_BUILDER_SESSION)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-available-built-in-substitution-strings.html), [Configuring Security Attributes (Public User)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-security-attributes.html)

### Built-ins de requisição: REQUEST, DEBUG, PRINTER_FRIENDLY, APP_UNIQUE_PAGE_ID, APP_REQUEST_DATA_HASH, APP_AJAX_X01–X10

| Built-in | Descrição | Referências |
|---|---|---|
| `REQUEST` | Nome do botão (ou o *Request* do botão ou da aba) que submeteu; ou o 4º argumento de `f?p` / `request=` | `:REQUEST`, `V('REQUEST')`, `&REQUEST.`, `APEX_APPLICATION.G_REQUEST` |
| `DEBUG` | `YES`/`NO` (ou `LEVELn`). Use para emitir debug do seu código só quando estiver ligado. | `:DEBUG`, `V('DEBUG')`, `&DEBUG.`, `APEX_APPLICATION.G_DEBUG` |
| `PRINTER_FRIENDLY` | se a página está em modo de impressão. Use em condições para esconder elementos. | `V('PRINTER_FRIENDLY')`, `&PRINTER_FRIENDLY.`, `APEX_APPLICATION.G_PRINTER_FRIENDLY` |
| `APP_UNIQUE_PAGE_ID` | inteiro de uma sequence, **único por page view**. Evita submissões duplicadas e cache do navegador (coloque no argumento request ou debug). | `:APP_UNIQUE_PAGE_ID`, `V(...)`, `&APP_UNIQUE_PAGE_ID.` |
| `APP_REQUEST_DATA_HASH` | hash das partes request, nomes e valores de itens da URL. Detecta se duas requisições passaram parâmetros diferentes. | `:APP_REQUEST_DATA_HASH`, `V(...)`, `&...` |
| `APP_AJAX_X01`…`APP_AJAX_X10` | valores dos parâmetros `x01`…`x10` passados ou definidos na última requisição show/accept. Uso típico: processos **On Demand** (Ajax). | `:APP_AJAX_X01`, `v('APP_AJAX_X01')`, `&APP_AJAX_X01.`; ver também `APEX_APPLICATION.G_X01…G_X10` |

```
f?p=100:1:&APP_SESSION.::&DEBUG.        -- mantém o modo debug atual no link
```

```sql
select 'f?p=100:1:'||:APP_SESSION||':'||:APP_UNIQUE_PAGE_ID||':::P1_EMPNO:'||employee_id, first_name
  from employees;
```

Fonte: [Using Built-in Substitution Strings](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-available-built-in-substitution-strings.html)

### Usando REQUEST: escopo, When Button Pressed, Show processing e BRANCH_TO_PAGE_ACCEPT

- **Escopo**: no submit, `REQUEST` vale em todas as fases do Accept (computations, validations, processes, branches). Depois do branch para outra página, volta a ser **NULL**. Exemplo: o botão `CHANGE` com label "Apply Change" gera `REQUEST = 'CHANGE'`.
- **When Button Pressed**: validations, processes e branches têm esse atributo, uma lista dos botões da página. Ele associa o componente ao `REQUEST` daquele botão. **Não presuma que o botão foi clicado de fato**: outro botão com o mesmo request ou um JavaScript (`apex.submit`) pode ter submetido com aquele valor.
- **Condição declarativa**: `Request = Value` com valor `GO`, por exemplo, para resetar a paginação.
- **Show processing**: `REQUEST` também pode ser passado numa navegação GET (`f?p=100:1:&APP_SESSION.:GO`) e testado em regiões e processes de renderização:

```sql
if v('REQUEST') = 'GO' then
   htp.p('hello');
end if;
```

- **`BRANCH_TO_PAGE_ACCEPT`**: request especial que, na navegação, **submete a página automaticamente**:

```
f?p=100:1:&APP_SESSION.:BRANCH_TO_PAGE_ACCEPT|SAVE:::P1_DATA:value
```

  É o mesmo que abrir a página 1, digitar `value` em `P1_DATA` e clicar num botão que submete com request `SAVE`.
- **`APEX_CLONE_SESSION`**: request especial de clonagem de sessão (§3).
- **`APPLICATION_PROCESS=<id|nome>`**: request especial que roda um application process On Demand (§10).

Fonte: [Using Built-in Substitution Strings (Using REQUEST)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-available-built-in-substitution-strings.html), [Managing Session State Values (About Session Cloning)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-session-state-values.html)

### Built-ins de arquivos: APEX_FILES, APP_FILES, WORKSPACE_FILES, THEME_FILES, THEME_DB_FILES, DEFAULT_THEME_FILES, JET_*

| Built-in | Para que serve | Nome legado |
|---|---|---|
| `APEX_FILES` | caminho virtual dos arquivos **distribuídos com o APEX** (default `/i/`). Direct PL/SQL: `APEX_APPLICATION.G_IMAGE_PREFIX`. | `IMAGE_PREFIX` |
| `APP_FILES` | arquivos estáticos **da aplicação** (imagens, JS, CSS). **Obrigatório** para arquivos enviados como específicos da app. | `APP_IMAGES` |
| `WORKSPACE_FILES` | arquivos estáticos **do workspace**, compartilhados entre apps | `WORKSPACE_IMAGE` |
| `THEME_FILES` | arquivos guardados com o **tema** (respeita o *File Prefix* do tema) | `THEME_IMAGES` |
| `THEME_DB_FILES` | arquivos do tema **sempre do banco**, ignorando o *File Prefix* | `THEME_DB_IMAGES` |
| `DEFAULT_THEME_FILES` | caminho do parâmetro de instância de mesmo nome (para o *File Prefix* do tema) | |
| `JET_BASE_DIRECTORY`, `JET_CSS_DIRECTORY`, `JET_JS_DIRECTORY` | diretórios do Oracle JET embutido | |

Formas: `#APP_FILES#` (template), `&APP_FILES.` (substituição), `:APP_FILES` (bind), `V('APP_FILES')`. `APP_FILES` e `WORKSPACE_FILES` **não** têm forma "Direct PL/SQL".

`#APP_VERSION#` devolve a versão informada da app. Serve para mostrar na tela ou para acrescentar a URLs de estáticos e invalidar o cache do navegador quando a app muda.

Fonte: [Using Built-in Substitution Strings](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-available-built-in-substitution-strings.html), [Managing Session State (Session Overrides)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-session-state.html)

### Built-ins de navegação e globalização: HOME_LINK, LOGIN_URL, LOGOUT_URL, AUTHENTICATED_URL_PREFIX, PUBLIC_URL_PREFIX, BROWSER_LANGUAGE, APP_NLS_*, APP_DATE_TIME_FORMAT

| Built-in | Descrição |
|---|---|
| `HOME_LINK` | home da app (*User Interface > Attributes > Home URL*). A engine vai para lá quando não há página na URL e o esquema de autenticação não indica outra. `#HOME_LINK#`, `&HOME_LINK.`, `APEX_APPLICATION.G_HOME_LINK` |
| `LOGIN_URL` | link para a página de login, para quem não está logado. `#LOGIN_URL#`, `&LOGIN_URL.`, `APEX_APPLICATION.G_LOGIN_URL` |
| `LOGOUT_URL` | URL de logout. Em entrada de navigation bar use `&LOGOUT_URL.` (com o ponto); em template de página use `#LOGOUT_URL#`. |
| `AUTHENTICATED_URL_PREFIX` | prefixo de URL autenticada, para apps com modo público e logado |
| `PUBLIC_URL_PREFIX` | URL para sair do modo logado para a visão pública |
| `BROWSER_LANGUAGE` | idioma preferido do navegador (`APEX_APPLICATION.G_BROWSER_LANGUAGE`) |
| `APP_NLS_DATE_FORMAT` | *Application Date Format*; se vazio, o `NLS_DATE_FORMAT` da sessão de banco no início da requisição |
| `APP_NLS_TIMESTAMP_FORMAT`, `APP_NLS_TIMESTAMP_TZ_FORMAT` | o mesmo para timestamp e timestamp com fuso |
| `APP_DATE_TIME_FORMAT` | *Application Date Time Format*; se vazio, o formato NLS de data e hora da sessão |
| `APP_TITLE` | título da app: substitution string `APP_TITLE`, senão o Logo (se for texto), senão o nome da app |
| `CURRENT_PARENT_TAB_TEXT` | só para apps com abas de dois níveis (temas antigos); só substituição |
| `SYSDATE_YYYYMMDD` | data atual do servidor em `YYYYMMDD` (`:SYSDATE_YYYYMMDD`; `APEX_APPLICATION.G_SYSDATE` é DATE) |
| `PROXY_SERVER` | atributo de proxy da app (`APEX_APPLICATION.G_PROXY_SERVER`), para chamadas como `utl_http` |

Fonte: [Using Built-in Substitution Strings](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-available-built-in-substitution-strings.html)

### Built-ins de template e de processamento de linhas: APEX_CSP_DISPLAY_NONE, OWNER, SCHEMA OWNER, SQLERRM, APEX$ROW_NUM, APEX$ROW_SELECTOR, APEX$ROW_STATUS

- **`#APEX_CSP_DISPLAY_NONE#`**: gera `style=display:none;` de forma centralizada e compatível com **CSP**, que proíbe CSS inline. É usado, por exemplo, no template de região *Inline Dialog* do Universal Theme.
- **`#OWNER#`**: o **parsing schema** da app. Funciona em SQL, PL/SQL e substituições.
- **SCHEMA OWNER**: o dono do schema do APEX, via `APEX_APPLICATION.G_FLOW_SCHEMA_OWNER` ou `#FLOW_OWNER#` em SQL/PL/SQL. Serve para gerar chamadas à engine a partir do seu código.
- **`#SQLERRM#`**: só no *Region Error Message* das regiões.
- **`APEX$ROW_NUM`**: número da linha em processamento numa tabular form submetida.
- **`APEX$ROW_SELECTOR`**: `X` se o checkbox seletor da linha está marcado, NULL se não.
- **`APEX$ROW_STATUS`**: status da linha (`C` criada, `U` alterada, `D` excluída) em validations, processes e conditions de **Interactive Grid** e de Form region.

Todas as `APEX$ROW_*` têm as formas `:APEX$ROW_STATUS`, `V('APEX$ROW_STATUS')` e `&APEX$ROW_STATUS.`.

```sql
-- process do IG, só para linhas novas
if :APEX$ROW_STATUS = 'C' then
   :CREATED_BY := :APP_USER;
end if;
```

Fonte: [Using Built-in Substitution Strings](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-available-built-in-substitution-strings.html)

---

## 8. Template directives

### Onde template directives funcionam e como são processadas

**Template directives** são tokens especiais que controlam como o texto em volta é processado. Funcionam em:

- **Template Component** plug-ins;
- atributos específicos de **email templates**;
- regiões **Cards, Interactive Grid, Classic Report, Interactive Report** e **Application Search** (em HTML Expressions);
- **theme templates**: botão, label, lista, região e página.

São processadas nas substituições do servidor ou do cliente, conforme o atributo. A ajuda do Page Designer indica "Supports Server-side Template Directives" ou "Supports Client-side Template Directives". Directives **podem ser aninhadas**. A referência de sintaxe para o cliente é `apex.util.applyTemplate`.

Dentro das chaves de uma directive, o nome do valor vai **sem** prefixo ou sufixo (`{if TITLE/}`). No conteúdo, use `&NAME.` em Cards, Content Row, Template Component e IG, e `#COLUMN#` para colunas de Classic e Interactive Report e em templates próprios. É permitido um espaço antes de `/}`.

Fonte: [Template Directives](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/template-directives.html), [Using Template Directives](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-template-directives.html), [Using Data Values in Template Directives](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-data-values-template-directives.html)

### Directive {if}: verdadeiro, vazio e os prefixos ?, = e !

```
{if [!][?|=]NAME/}
TRUE_TEMPLATE_TEXT
{elseif [!][?|=]NAME2/}
ELSE_TRUE_TEMPLATE_TEXT
{else/}
FALSE_TEMPLATE_TEXT
{endif/}
```

O valor é **falso** se, depois do trim, estiver vazio ou for `F`, `N` ou `0`. Qualquer outro valor é verdadeiro. `elseif` (zero ou mais) e `else` são opcionais, mas a ordem é obrigatória.

| Directive | Verdadeiro quando | Equivalente PL/SQL |
|---|---|---|
| `{if MYITEM/}` | tem valor e não é F/N/0 | `:MYITEM is not null and upper(:MYITEM) not in ('F','N','0')` |
| `{if ?MYITEM/}` | tem valor (qualquer um) | `:MYITEM is not null` |
| `{if !MYITEM/}` | vazio ou F/N/0 | `:MYITEM is null or upper(:MYITEM) in ('F','N','0')` |
| `{if !?MYITEM/}` | vazio | `:MYITEM is null` |
| `{if =MYITEM/}` | vazio ou diferente de F/N/0 | `:MYITEM is null or upper(:MYITEM) not in ('F','N','0')` |
| `{if !=MYITEM/}` | F, N ou 0 | `upper(:MYITEM) in ('F','N','0')` |
| `{if MYITEM%assigned/}` | sempre verdadeiro quando houve atribuição (ex.: `&COLUMN.`), mesmo se vazio em algumas linhas | n/a |

**Pegadinha:** `{if X/}` mistura "não vazio" com "booleano". Um valor `'N'` não é vazio, mas é falso. Para testar só presença, use `{if ?X/}`.

```
{if DESCRIPTION/}&DESCRIPTION.{else/}No description.{endif/}
Dear {if HONORIFIC/}#HONORIFIC# #LAST_NAME#{else/}#FIRST_NAME#{endif/},
```

Fonte: [Using Template Directives (If Condition Directives)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-template-directives.html), [Using Data Values in Template Directives](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-data-values-template-directives.html)

### Directives {case}, {loop}, {with}/{apply}, comentários e escape de "{"

**case**: compara o valor, com trim e **distinguindo maiúsculas**, com cada `when`. Se nenhum casar, vale o `otherwise`.

```
{case JOB/}
{when SALESMAN/}&SAL. (&COMM.)
{when PRESIDENT/}--
{otherwise/}&SAL.
{endcase/}
```

**loop**: repete o texto para cada valor de um item ou coluna delimitado. O separador default é `:`; com mais de um caractere, vira **expressão regular**. Dentro do loop: `APEX$ITEM` (valor atual) e `APEX$I` (índice que começa em 1).

```
<ul class="tags">{loop "," TAGS/}<li class="tag-item">&APEX$ITEM.</li>{endloop/}</ul>
{loop ":" TAGS/}<span class="a-Chip">&APEX$ITEM.</span>{endloop/}
```

**with / apply**: atribui valores aos placeholders de um **Template Component** e o aplica (renderização no servidor). Aceita directives dentro dos valores.

```
{with/}
TYPE:=IMAGE
IMAGE:=&IMAGE_URL.
ALT:={if DESCRIPTION/}&DESCRIPTION.{else/}No description.{endif/}
{apply THEME$AVATAR/}
```

**Comentário**: `{!texto/}` é substituído por nada. O texto não pode ter quebra de linha nem `/}`.

**Escape de `{`**: `{{/}`, para quando um `{` solto e outra directive na mesma linha podem ser confundidos.

```
<span>The coordinates {{/}c, d} = {if VAL/}&VAL.{else/}unknown{endif/}</span>
```

**`APEX$DOM_ID`**: gera um DOM ID único e aleatório a cada execução do trecho (ex.: `id="#APEX$DOM_ID#_heading"` + `aria-labelledby`).

Fonte: [Using Template Directives](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-template-directives.html), [Using Data Values in Template Directives](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-data-values-template-directives.html), [Directives Reference in Your Dock](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/directives-reference-your-dock.html)

---

## 9. Itens de página e de aplicação

### Page item × application item: diferenças e quando usar cada um

| | Page item | Application item |
|---|---|---|
| Onde é definido | numa página (Page Designer) | *Shared Components > Application Logic > Application Items* |
| Interface | tem label, template, tipo de exibição (text field, select list…) | **não tem** interface |
| Uso típico | campos de formulário, filtros, chaves da página | "variável global" da sessão: `USER_ID`, empresa do usuário, flags |
| Como recebe valor | source, submit, computation, process, URL, API | computation (inclusive **On New Instance** ou **After Authentication**), process, URL, API |
| Referência | `:P1_X`, `&P1_X.`, `V('P1_X')` | `:G_X`, `&G_X.`, `#G_X#` (em alguns contextos), `V('G_X')` |

Padrão recomendado pelo Developer's Companion: crie um app item `USER_ID` e uma **application computation** com *Computation Point* = **After Authentication**, que faz a busca uma vez só:

```sql
select id from users where username = lower(:APP_USER)
```

Depois, qualquer página usa `:USER_ID` sem consultar de novo. Para alterar o valor em PL/SQL armazenado, use `APEX_SESSION_STATE.SET_VALUE`.

Fonte: [Understanding Page Items (About the Differences Between Page Items and Application Items)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-page-items.html), [Application Items](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/application-items.html), [Managing Application Items](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-application-items.html)

### Regras de nome de itens (Item Naming Conventions)

Nomes de item devem:

- ser **únicos na aplicação** (page items e app items compartilham o espaço de nomes);
- não conter aspas;
- começar com letra ou número; os demais caracteres podem ser letras, números ou `_`;
- não distinguir maiúsculas;
- ter **no máximo 30 caracteres** (acima disso, não dá para usar como bind);
- usar só ASCII básico.

Boa prática: incluir o número da página. Os wizards geram `P<nº>_<NOME>` (ex.: `P1_NAME`).

Fonte: [Understanding Page Items (About Item Naming Conventions)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-page-items.html), [Oracle APEX Limits](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/oracle-apex-limits.html)

### Atributos do application item: Scope, Session State Protection, Escape Special Characters

| Atributo | Valores (APEXlang) | Notas |
|---|---|---|
| Name | até 255 caracteres | Bind só até 30. |
| Scope | `app` (default), `global` | **Global**: o valor é o mesmo em todas as apps que compartilham a sessão (mesmos *Session Cookie Attributes* no authentication scheme). O scope tem de ser igual em todas essas apps. |
| Session State Data Type | `varchar` (default), `number` | |
| Session State Protection | `unrestricted`, `checksumRequiredAppLevel`, `checksumRequiredUserLevel`, `checksumRequiredSessionLevel`, **`restricted` (default)** | Para setar por Ajax (DA Set Value, Page Items to Submit, cascading LOV), precisa ser **Unrestricted**. |
| Escape Special Characters | `true` (default) | Escapa o valor em `&ITEM.`. Desligue só para renderizar HTML confiável. |
| Build Option, Comments | | |

Os relatórios *Utilization* e *History* mostram onde cada app item é usado e as mudanças recentes. Também é possível copiar app items de outra app e assinar (*subscribe*) para mantê-los sincronizados.

Fonte: [Managing Application Items](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-application-items.html), [APEXlang API Reference: appItem](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Binds são strings: tipos de dado de session state (VARCHAR2, CLOB, BOOLEAN)

Mesmo que o item seja **Date Picker** ou **Number Field**, `:P5_START_DATE` e `:P5_MAX_QUANTITY` chegam ao SQL como **VARCHAR2**. As exceções configuráveis em *Session State > Data Type* são:

- **CLOB**: para itens **Hidden**, **Text Area** e **Rich Text Editor**. Leia com `APEX_SESSION_STATE.GET_CLOB`. Item CLOB **não** funciona com `&ITEM.`; para exibir, use item Read Only, Display Only ou região Dynamic Content.
- **BOOLEAN**: para itens **Switch** e **Checkbox**, mas **só no Oracle Database 26ai**.

Para converter com segurança, respeitando a *Format Mask* do item, use as funções tipadas:

```sql
apex_session_state.get_number('P5_MAX_QUANTITY')
apex_session_state.get_timestamp('P34_HIRED_BEFORE')
apex_session_state.get_clob('P1_TEXTO_LONGO')
```

Em SQL, prefira envolver em fast dual: `(select apex_session_state.get_number('P5_X') from dual)`.

Fonte: [Values Bind as Strings](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/values-bind-strings.html), [Managing Session State Values (About Referencing Session State)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-session-state-values.html)

### Valores delimitados (Select Many, Shuttle, checkbox múltiplo): APEX_STRING.SPLIT e SPLIT_NUMBERS

Itens de múltipla seleção (Multiselect List, Shuttle, Select Many…) enviam **uma string delimitada** (por padrão `:`; o item pode usar outro separador, como `|`). `IN (:ITEM)` **não funciona**:

- com números, dá `ORA-01722: unable to convert string value containing ':' to a number`;
- com strings, não dá erro mas **não retorna linhas**, porque compara com o literal inteiro `"SM|MD|XXL"`.

```sql
-- números
select empno, ename, sal from emp
 where empno in (select column_value
                   from apex_string.split_numbers(:P5_SELECTED_EMPNOS, ':'));

-- strings
select id, sku, price from items
 where item_size in (select column_value
                       from apex_string.split(:P5_SELECTED_SIZES, '|'));

-- alternativa clássica
where instr(':'||:P1_DEPTNO||':', ':'||e.deptno||':') > 0
```

```sql
declare
   l_ids apex_t_number;
begin
   l_ids := apex_string.split_numbers(:P5_SELECTED_EMPNOS, ':');
   for j in 1 .. l_ids.count loop
      null; -- l_ids(j)
   end loop;
end;
```

Para strings, o tipo é `apex_t_varchar2` com `apex_string.split`. Uma computation num item com *Multiple Values* formata um resultado de várias linhas com o delimitador ou como array JSON.

Fonte: [Working with Delimited Number Values](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/working-delimited-number-values.html), [Working with Delimited String Values](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/working-delimited-string-values.html), [Understanding Page Items (Working with Multiple Select List Item)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-page-items.html), [Computing Values on Render or Submit](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/computing-values-render-or-submit.html)

### Colunas de Interactive Grid como bind (:COLUMN)

Em validations de coluna, em processes com **Editable Region** apontando para o grid e em DAs *Execute Server-side Code* disparadas por mudança de coluna, `:COLUMNNAME` referencia o valor da **linha corrente**. Ao processar linhas novas ou alteradas, dá para **atribuir**:

```sql
if :JOB = 'CLERK' then
   :JOB := 'ANALYST';
end if;
```

Na DA, liste as colunas em *Items to Submit* e *Items to Return*, sem os dois-pontos. Datas e números de coluna de IG chegam como VARCHAR2: converta com `to_date`, `to_timestamp` ou `to_number` e a máscara adequada.

Fonte: [Working with Column Data Values](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/working-column-data-values.html), [Working with Data Values as Dates](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/working-data-values-dates.html), [Working with Data Values as Numbers](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/working-data-values-numbers.html)

---

## 10. Computations, validations, processes e branches

### Visão geral: o papel de cada componente de lógica

| Componente | O que faz | Onde |
|---|---|---|
| **Computation** | **atribui um valor** a um item (de página ou de aplicação) | página (Pre-Rendering ou After Submit) ou aplicação |
| **Validation** | **checa** um item, a página ou uma coluna antes de processar | página (Validating) |
| **Page process** | **executa uma ação** (PL/SQL, DML, e-mail, fechar diálogo…) num ponto da renderização ou do submit | página |
| **Application process** | bloco de lógica que roda **no mesmo ponto em todas as páginas** (ou On Demand) | Shared Components |
| **Application computation** | computation que roda no mesmo ponto em várias páginas | Shared Components |
| **Branch** | **para onde ir** depois do submit (ou antes de renderizar) | página |

Na prática não há diferença funcional entre process de página e de aplicação: muda só onde ficam definidos. Boa prática: coloque a lógica de negócio em **packages PL/SQL** e chame-a de uma linha (Execute Code) ou com o process **Invoke API**. Isso facilita manutenção e testes.

Fonte: [Managing Computations, Validations, and Processes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-computations-validations-and-processes.html), [About Page Processes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-page-processes.html), [Best Practice Use of Invoke API](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/best-practice-use-invoke-api.html)

### Page computation: pontos, tipos e exemplos

**Criar:** no Page Designer, aba Rendering, nó Pre-Rendering (ou Post-Rendering), clique direito > *Create Computation*. Para submit, use a aba Processing, nó After Submit.

| Atributo | Valores |
|---|---|
| Identification > Item Name | item de página ou de aplicação que recebe o valor |
| Execution > Sequence | ordem de execução |
| Execution > Point | `newSession` (On New Instance), `beforeHeader`, `afterHeader`, **`beforeRegions` (default APEXlang)**, `afterRegions`, `beforeFooter`, `afterFooter`, **`afterSubmit` (o mais comum)** |
| Computation > Type | `staticValue` (Static Value), `item` (Item), `sqlQuerySingleValue` (SQL Query, single value), `sqlQueryMultipleValues` (SQL Query, valores separados por `:`), `expression` (SQL, PL/SQL ou JavaScript MLE), `functionBody` (PL/SQL ou JavaScript MLE), `preference` (User Preference) |
| Error > Error Message | mensagem se a computation falhar |
| Server-side Condition, Security (Authorization), Configuration (Build Option) | |

Escolha do ponto: se o valor muda **o que a página mostra**, use Pre-Rendering. Se afeta o **processamento dos dados submetidos** (campos ocultos, ajuste do que o usuário digitou antes de salvar), use **After Submit**. Lembre que **depois de cada computation há commit implícito**.

Exemplo da doc: juntar código de área, prefixo e número em `P10_PHONE_NUMBER`.

```
-- Static Value
(&P10_AREA_CODE.) &P10_PREFIX.-&P10_LINE_NUMBER.
-- PL/SQL Expression
'('||:P10_AREA_CODE||')'||:P10_PREFIX||'-'||:P10_LINE_NUMBER
-- SQL Query (return colon separated value)
SELECT '('||:P10_AREA_CODE||')'||:P10_PREFIX||'-'||:P10_LINE_NUMBER FROM DUAL
```

```sql
-- PL/SQL Function Body
declare
  l_return_value varchar2(300);
begin
  l_return_value := '('||:P10_AREA_CODE||')'||:P10_PREFIX||'-'||:P10_LINE_NUMBER;
  return l_return_value;
end;
```

Fonte: [Understanding Page Computations](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-page-computations.html), [Computing Values on Render or Submit](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/computing-values-render-or-submit.html), [APEXlang API Reference: computation](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Application computation: On New Instance, After Authentication e "última página visitada"

São criadas em *Shared Components > Application Logic > Application Computations > Create*: Sequence, *Computation Item*, *Computation Point*, *Computation Type*, Computation, *Error Message*, Authorization Scheme, Condition, Build Option, Static ID e Comments.

- **Pontos** (APEXlang `appComputation.point`): `newSession` (default), `afterAuthentication`, `beforeHeader`, `afterHeader`, `beforeRegions`, `afterRegions`, `beforeFooter`, `afterFooter`, `afterSubmit`. Com **After Submit**, a computation só roda depois que a página é exibida e submetida.
- **On New Instance**: roda **uma vez por sessão**. Use para valores que **não dependem do usuário**. Para valores que dependem do usuário, use **After Authentication**.
- **Exemplo da doc**, guardar a última página visitada para um botão "voltar":

```sql
begin
   :LAST_PAGE := nvl(:CURRENT_PAGE, :APP_PAGE_ID);
   :CURRENT_PAGE := :APP_PAGE_ID;
   return :LAST_PAGE;
end;
```

- Há relatório de **History** e é possível **copiar e assinar** (*subscribe*) application computations de outra app.

Fonte: [Understanding Application Computations](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-application-computations.html), [APEXlang API Reference: appComputation](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Validations: tipos, Always Execute, Associated Item e mensagens

Uma **validation** é uma checagem. Há quatro níveis: item (page item validation), página (page validation), coluna de tabular form ou IG (column validation) e linha de tabular form (row validation). É criada na aba Processing, em *Validating*, com clique direito > *Create Validation*. Também dá para criar pelo menu de contexto de um item na aba Rendering, que já preenche o *Associated Item*.

**Validation > Type** (APEXlang, para item):

| Grupo | Tipos |
|---|---|
| SQL | `rowsReturned` (Rows returned), `noRowsReturned` (No Rows returned) |
| PL/SQL | `expression` (Expression; **default**), `plsqlError` (PL/SQL Error), `functionBodyReturningBoolean` (Function Body returning Boolean), `functionBody` (Function Body returning Error Text) |
| Item | `itemIsNotNull`, `itemIsNotNullOrZero`, `itemIsNotZero`, `itemContainsNoSpaces`, `itemIsAlphanumeric`, `itemIsNumeric`, `itemIsAValidDate`, `itemIsAValidTimestamp`, `item=Value`, `item!=Value`, `itemIsContainedInValue`, `itemIsNotContainedInValue`, `itemContainsOnlyCharsInValue`, `itemContainsAtLeastOneOfCharsInValue`, `itemContainsNoneOfCharsInValue`, `itemMatchesRegexp` |
| Coluna (IG) | os mesmos com prefixo `column…` (`columnIsNotNull`, `columnMatchesRegexp`…) |

- A validação **passa** quando o teste é verdadeiro. Ela **falha**, e a mensagem aparece, quando o teste é falso **ou** quando uma *Function Body returning Error Text* devolve texto não vazio.
- **Editable Region**: para validar colunas de IG, aponte para o grid e use as colunas pelo nome.
- **Execution Scope** (em região editável): `forCreatedAndModifiedRows` (default) ou `allSubmittedRows`.
- **Always Execute** (APEXlang `alwaysExecute`, default `false`):
  - **On**: roda sempre, seja qual for o *Execute Validations* do botão. Use para checagens de **segurança** (o usuário pode alterar ou excluir este registro?).
  - **Off**: só roda se o botão ou item que submeteu tem *Execute Validations* = On.
  - Padrão de formulário: Create e Apply Changes com *Execute Validations* On; Delete com Off, para não validar formato de campo ao excluir.
- **Error Message**: aceita `#LABEL#` (label do item associado) e `#COLUMN_HEADER#` (cabeçalho da coluna). Esses placeholders **não funcionam** com *On Error Page*.
- **Display Location** (APEXlang `displayLocation`):

| Valor | Efeito |
|---|---|
| `inlineWithFieldAndInNotification` (default) | abaixo do label do item **e** na área de notificação |
| `inlineWithField` | só junto ao campo |
| `inlineInNotification` | só na notificação do template de página |
| `onErrorPage` | numa página de erro separada. É a única forma de um **erro "duro"** que para tudo, inclusive as demais validações. |

- **Associated Item / Associated Column**: onde o erro inline aparece. Sem *Inline with Field*, não tem efeito visual. Com item associado, a notificação ganha o link **Go to Error**, que põe o foco no campo (texto da mensagem `APEX.GO_TO_ERROR`).
- O texto de uma validação **não pode passar de 3.950 caracteres**.

```sql
-- PL/SQL Expression comparando números como números
apex_session_state.get_number('P1_SAL_RANGE_LOW')
  <= apex_session_state.get_number('P1_SAL_RANGE_HIGH')
```

Fonte: [Understanding Validations](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-validations.html), [Validating Submitted Data](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/validating-submitted-data.html), [APEXlang API Reference: validation](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### O que acontece quando uma validation falha

1. A página é **re-exibida** com todos os erros inline (há commit implícito antes da re-renderização).
2. Nenhum componente da fase **Processing** do submit roda. Depois de uma validation que falha, processes e computations subsequentes não acontecem.
3. Na re-renderização, o APEX **não executa** computations, application processes nem page processes de renderização (todos os pontos "On Load…", como *Form - Initialization* / *Automated Row Fetch*). O motivo: eles poderiam **sobrescrever o que o usuário digitou**. A exceção são componentes com a condição **Inline Validation Errors Displayed**.
4. No debug aparecem as mensagens `Do not perform computation because inline validation errors found.` (computation pulada) e `Skip because inline validation errors found.` (process pulado).

Fonte: [Understanding Validations (What Happens When a Validation Fails?)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-validations.html), [Validating Submitted Data](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/validating-submitted-data.html)

### Page processes: tipos nativos disponíveis no 26.1

Tipos documentados (os plug-ins aparecem como `<Nome> [Plug-in]`):

| Tipo (UI) | APEXlang | Uso |
|---|---|---|
| Clear Session State | `clearSessionState` | limpa session state (páginas, itens) |
| Close Dialog | `closeDialog` | fecha o modal ou não modal atual; pode devolver itens à página que chamou |
| Data Loading | `dataLoading` | carrega dados com uma Data Load Definition |
| Download | `download` | baixa um ou vários arquivos. Funciona em *Before Header* ou no submit. **O processamento para depois dele.** |
| Execute Code | `executeCode` | PL/SQL (ou JavaScript MLE), local ou via REST Enabled SQL |
| Execution Chain | `executionChain` | sequência de processes filhos, em primeiro plano ou em **background** |
| Form - Automatic Row Processing (DML) | `formAutoRowProcessing` | insert/update/delete da Form region |
| Form - Initialization | `formInitialization` | busca a linha pela PK ou inicializa os itens da Form region |
| Generate Text with AI | `generateTextWithAi` | resposta única de um serviço de IA generativa (resumo, tradução…) |
| Human Task - Create / Manage | `humanTaskCreate` / `humanTaskManage` | cria ou gerencia tarefas (Approve, Reject, Claim, Release, Delegate, Forward, Cancel, Comment, Invite Participant) |
| Interactive Grid - Automatic Row Processing (DML) | `interactiveGridAutoRowProcessing` | DML das linhas do IG |
| Invoke API | `invokeApi` | chama procedure ou function (pacote ou avulsa) ou operação de REST Data Source |
| Print Report | `printReport` | imprime usando report query |
| Reset Pagination | `resetPagination` | reseta a paginação dos relatórios da página |
| Send E-Mail | `sendEMail` | e-mail com anexos opcionais |
| Send Push Notification | `sendPushNotification` | push para todos os dispositivos inscritos do usuário |
| Server Side Geocoding | `serverSideGeocoding` | geocodificação (só no Autonomous Database) |
| User Preferences | `userPreferences` | grava preferências do usuário |
| Web Service | `webService` | consome um web service |
| Workflow | `workflow` | inicia, termina, suspende, retoma ou repete instâncias de workflow |

O enum do APEXlang também lista tipos legados ou internos: `autoRowFetch`, `autoRowProcessing`, `legacyAutoRowProcessing`, `formPagination`, `tabformAddRows/Delete/Update`, `legacyWebService`, `parseUploadedData`, `prepareUploadedData`, `loadUploadedData`, e tipos de workflow (`invokeWorkflow`, `parallelFlow`, `switch`, `wait`, `workflowStart`, `workflowEnd`).

Fonte: [About Page Processes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-page-processes.html), [Custom Processing on Render or Submit](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/custom-processing-render-or-submit.html), [APEXlang API Reference: process](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Page process: atributos de execução, Run Process, mensagens de sucesso e erro

| Grupo / atributo | Valores e comportamento |
|---|---|
| Identification > Name / Type | o tipo define os demais atributos |
| Identification > Execution Chain | process pai (para processes filhos de uma chain) |
| Identification > Editable Region | região editável (Form ou IG) para processes de linha |
| Source > Location / Language / Code | Local Database ou REST Enabled SQL; PL/SQL ou JavaScript MLE |
| Execution > Sequence | ordem. **Mesma sequência pode mudar de ordem depois de export/import.** |
| Execution > Point | o ponto de execução (default no APEXlang: `AFTER_SUBMIT`, o ponto Processing) |
| Execution > Run Process | **`Once Per Page Visit (default)`** ou **`Once Per Session or When Reset`** |
| Success Message | aparece na notificação da página resultante se não houver erro. Com branch por **redirect de URL**, pode ser preciso marcar *preserve success message*. Para processes de várias linhas: `#MRI_COUNT#` (inseridas), `#MRU_COUNT#` (alteradas), `#MRD_COUNT#` (excluídas); em Send E-Mail, `#TO#`. |
| Error > Error Message | aparece em exceção **não tratada**: o processamento para, há **rollback** e a mensagem aparece. Aceita `#SQLERRM_TEXT#` (texto sem o número) e `#SQLERRM#` (completo). Com *On Error Page*, o sqlerrm já aparece por padrão. |
| Error > Display Location | `inlineInNotification` (default) ou `onErrorPage`. **Só vale** para processes *On Submit - Before Computation and Validations* (After Submit) e *On Submit - After Computations and Validations* (Processing). **Nos demais pontos, o erro vai sempre para a página de erro.** |
| Server-side Condition | When Button Pressed + Type (§11) |
| Advanced > Static ID | identifica o componente em APIs e exports. Ao mudá-lo, as referências declarativas se ajustam, mas chamadas de API com o ID antigo precisam ser corrigidas à mão. |

Fonte: [Creating Page Processes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-a-page-processes.html), [Editing Page Processes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-page-processes.html), [APEXlang API Reference: process](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Execute Code, Invoke API e Form DML: escolhendo o tipo de process

- **Execute Code**: PL/SQL livre. Exemplo do wizard de onboarding: `insert into emp(...) values (:P43_EMPNO, :P43_ENAME, :P44_DEPTNO, apex_session_state.get_timestamp('P44_HIREDATE'), ...)`, com *When Button Pressed* = `FINISH` e mensagem de sucesso.
- **Invoke API**: chamada declarativa a um package (`Invoke > Type` = PL/SQL Package, PL/SQL Procedure or Function ou REST Source). Os nomes de package e procedure **distinguem maiúsculas**. Depois de escolher a procedure, o Page Designer mostra os **Parameters** e mapeia automaticamente os itens com nome igual. Revise cada um no Property Editor. É a forma recomendada para lógica em package.
- **Form - Initialization** (Before Header): se **todos** os itens marcados como PK da Form region têm valor na renderização, faz o `SELECT ... INTO` dos itens pela PK. Se a PK está vazia, não faz nada (formulário de inclusão). O valor da PK chega pela URL **antes** do Pre-Rendering.
- **Form - Automatic Row Processing (DML)**: executa insert, update ou delete conforme o **Database Action** do botão que submeteu (INSERT, UPDATE, DELETE). **Sem Database Action no botão, nenhuma DML acontece.** Com os defaults: DML na fonte da região, **lost update detection**, **lock** da linha e **retorno da PK** para o item depois do insert. O *Target Type* permite apontar para outra tabela ou view ou fazer a DML em PL/SQL.
- **Close Dialog**: fecha o modal. Pode ser condicionado por `REQUEST` in (`CREATE`,`SAVE`,`DELETE`).

Fonte: [Custom Processing on Render or Submit](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/custom-processing-render-or-submit.html), [Best Practice Use of Invoke API](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/best-practice-use-invoke-api.html), [Creating Page Processes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-a-page-processes.html), [Retrieving Existing Row by Primary Key](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/retrieving-existing-row-primary-key.html), [Saving Changes with a Page Process](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/saving-changes-page-process.html), [Conditional Database Action Buttons](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/conditional-database-action-buttons.html)

### Application processes: pontos, On New Instance, After Authentication e Ajax Callback

São criados em *Shared Components > Application Logic > Application Processes > Create*: Name, Sequence, **Point**, Language, Code, *Do not validate code*, Condition, e depois Error Message e Authorization.

- Por padrão rodam **no mesmo ponto para todas as páginas**. Restrinja com condições (por exemplo, `Current Page is NOT in comma delimited list`).
- **Pontos** (APEXlang `appProcess.point`): `afterAuthentication`, `newSession`, **`beforeHeader` (default)**, `afterHeader`, `beforeRegions`, `afterRegions`, `beforeFooter`, `afterFooter`, `afterSubmit`, `processing`, `ajaxCallback`.
  - **On New Instance**: uma vez por sessão, para dados que não dependem do usuário.
  - **After Authentication**: depois do login, para dados do usuário.
  - **Ajax Callback** (On Demand): só roda quando chamado (ver a próxima seção).
- **Mensagem de erro**: inline ou na página de erro **só** nos pontos *On Submit - Before Computation and Validations* e *After Computations and Validations*. Nos demais, sempre na página de erro. Com tabular form manual (`APEX_ITEM`), escolha *On Error Page*, senão as alterações do usuário se perdem na re-renderização.
- Exemplo da doc: process **On Load: Before Header** que calcula `TOTAL_CART_ITEMS` e `TOTAL_PURCHASE_PRICE` em todas as páginas, exibidos numa região da Global Page.
- **Custo:** um process *Before Header* sem condição roda em **toda renderização de toda página**, inclusive login e páginas públicas.

Fonte: [Understanding Application Processes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-application-processes.html), [APEXlang API Reference: appProcess](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Processos On Demand (Ajax Callback) e chamada por URL APPLICATION_PROCESS=

Um process **On Demand** é um application process (ou de página, no ponto *Ajax Callback*) do tipo PL/SQL que roda **só quando é chamado**: por um process On Demand de página ou por uma chamada **Ajax** do navegador (ex.: `apex.server.process`, documento 08).

- **Prefira criá-lo na página**, não na aplicação. Os de aplicação nascem com a authorization **Must Not Be Public User**, para não serem chamados por sessões não autenticadas.
- Os parâmetros chegam por `APP_AJAX_X01`…`X10` (ou `APEX_APPLICATION.G_X01`…`G_X10`) e por itens enviados no submit da chamada.

**Chamada por URL:**

```
f?p=application_id:page_id:session:APPLICATION_PROCESS=process_id
```

Regras:

- A página na URL é só um marcador de sintaxe: nenhuma página é acessada. Pode ser a atual.
- São respeitados: a authorization do process, a authorization da app e as condições do process.
- Itens podem ser setados na URL, mas **clear cache é ignorado**.
- Falhas de autenticação, autorização ou condição **não mostram erro**: em geral sai uma página em branco. Logado no Builder, o desenvolvedor vê a mensagem.
- Chamada pelo **nome**: vale o primeiro process com aquele nome, que distingue maiúsculas.

Fonte: [Understanding Application Processes (On Demand Application Processes, About Running an On Demand Process from a Page Request)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-application-processes.html), [Using Built-in Substitution Strings (APP_AJAX_X01)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-available-built-in-substitution-strings.html)

### Execution Chain e processamento em background

O process **Execution Chain** agrupa **processes filhos** que rodam em sequência, em primeiro plano ou em **background**. O usuário não espera, o que é útil para cargas e processamentos pesados.

Passos: crie o process Execution Chain, ligue *Settings > Execute in Background* e adicione filhos (clique direito no chain > *Create Child Process*). Chains podem ser aninhadas, com *Identification > Execution Chain* apontando para o chain pai.

| Settings | Efeito |
|---|---|
| Execute in Background | roda no `DBMS_SCHEDULER` |
| Serialize Executions | serializa as execuções de todas as sessões, para evitar concorrência sobre os mesmos recursos (ex.: DML na mesma linha) |
| Return Execution ID into Item | item que recebe o ID da execução, usado para consultar o status |
| Temporary File Handling | `Ignore` (não leva os uploads), `Move` (um chain usa os arquivos) ou `Copy` (vários chains usam) |
| Executions Limit | máximo de execuções em background por usuário; a seguinte dá erro |

- O parsing schema precisa do privilégio **`CREATE JOB`**.
- Limites de jobs simultâneos: instância (default), workspace (*Maximum Background Page Process Jobs*, que é o teto) e aplicação (para distribuir o teto do workspace; um valor acima do workspace é ignorado). Acima do limite, a execução fica **na fila**.
- Monitoramento: *Developer Toolbar > Session > View Session State > View: Background Executions*, com os status Submitted for Execution, Scheduler Job Created, Executing, Finished Successfully, Terminate e Failed, e o botão **Terminate**. Também em *Monitor Activity > Active Sessions* e pela API `APEX_BACKGROUND_PROCESS`.
- Reimportar uma app com background processes pergunta o que fazer com as execuções existentes.

Fonte: [Understanding Background Page Processing](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-background-page-processing.html)

### Branches: pontos, tipos e quando usar branch × redirect

Um **branch** é a instrução de ir para uma página, procedure ou URL, em geral **depois do submit**. É criado com clique direito > *Create Branch* na aba Rendering (pré-renderização) ou Processing.

| Atributo | Valores |
|---|---|
| Execution > Sequence | ordem de avaliação entre os branches |
| Execution > Point | `afterSubmit` (antes "Before Computation"), `validating` (antes "Before Validation"), `processing` (antes "Before Processing"), **`afterProcessing` (default)**, `beforeHeader` (branch de pré-renderização) |
| Behavior > Type | `pageOrUrl` (Page or URL (Redirect), **default**), `page` (Page, sem redirect), `pageIdentifiedByItem`, `urlIdentifiedByItem`, `functionReturningPage`, `functionReturningUrl` (PL/SQL ou JavaScript MLE), `plsqlProcedure`, `pageProcessing` (Branch to Page Accept, com `request`) |
| Behavior > Target | Link Builder: página, itens a setar, clear cache, request |
| Save State Before Branching | em branches de redirect (APEXlang `saveStateBeforeBranching`, default `false`) |
| Server-side Condition | When Button Pressed e Type |

- **Branch × redirect** (Developer's Companion): o **branch** acontece depois de um submit. Os dados vão ao servidor, o session state é atualizado e só então se navega. O **redirect** (botão ou link com URL) navega **sem submeter**: as alterações da página **não** vão para o session state. Por padrão, o redirect mostra o aviso **Warn on Unsaved Changes** se houver mudança não salva. O aviso pode ser controlado na página e em cada item, e no botão Cancel do wizard usa-se *Do Not Check*.
- *Page Access Protection* = **No URL Access** só aceita chegada por um branch do tipo **Page** (sem redirect).
- No APEXlang **não se cria branch na Global Page**.

```
branch (
    name: Limpar formulário após carregamento
    execution {
        sequence: 10
        point: processing
    }
    behavior {
        target: {
            page: 14
            clearCache: 14
        }
    }
)
```

Fonte: [Controlling Navigation Using Branches](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/controlling-navigation-using-branches.html), [About Branches](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-branches.html), [Branches Link Pages to Define Flows](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/branches-link-pages-define-flows.html), [Understanding AJAX and Redirect](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-ajax-and-redirect.html), [Preventing URL Tampering](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/preventing-url-tampering.html), [APEXlang API Reference: branch](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Attribute Dictionary (Utilities)

O **Attribute Dictionary** guarda atributos de colunas (por nome de coluna, com sinônimos) usados ao criar formulários e relatórios. Em *Utilities > Attribute Dictionary* você atualiza os itens e colunas da página a partir do dicionário, ou o dicionário a partir da página. Só aparecem objetos com diferença em ao menos um atributo, e ficam de fora itens ocultos, itens em regiões ocultas e botões.

Fonte: [Using the Attribute Dictionary](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-the-attribute-dictionary.html)

---

## 11. Condições

### Server-side Condition e When Button Pressed: como funcionam

- Quase todo elemento aceita **Server-side Condition**: regiões, itens, colunas, botões, validations, computations, processes, branches, entradas de lista e de breadcrumb. A engine só renderiza ou executa o elemento se a condição for **verdadeira**.
- Os testes possíveis são declarativos, *Expression* (SQL, PL/SQL ou JavaScript MLE), *Function Body* que devolve Boolean, ou SQL que devolve linha (*Rows returned* / *No Rows returned*).
- **When Button Pressed** (validations, processes, branches) limita o componente a **um** botão. Pode ser combinado com a condição Type. Na validação, se nenhum botão foi pressionado, as outras condições são avaliadas.
- **Vários botões:** use `Request is contained in Value` com uma lista (`SAVE,UPDATE,INCREMENT`) ou a expressão PL/SQL `:REQUEST in ('SAVE','UPDATE','INCREMENT')`.
- **Pegadinha de "contido"**: `Request is contained in Value` com o valor `SAVE_ADDRESS,SAVE_ASSIGNMENT` também casa quando o request é `SAVE`, porque `SAVE` está contido no texto. Use `:REQUEST in (...)` quando um nome de botão é prefixo de outro.
- **Never** desliga o componente, mas **apaga a condição que existia**. Para desligar temporariamente, a Oracle recomenda **Build Option**.

Fonte: [Making Almost Any Element Conditional](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/making-almost-any-element-conditional.html), [Understanding Validations (Processing Validations Conditionally)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-validations.html), [Available Conditions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/available-conditions.html)

### Tipos de condição disponíveis (Available Conditions)

| Condição (UI) | APEXlang | Verdadeira quando |
|---|---|---|
| Rows returned / No Rows returned | `rowsReturned` / `noRowsReturned` | a query devolve 1+ linhas / nenhuma |
| SQL Expression, PL/SQL Expression | `expression` (language `sql`/`plsql`/`javaScript-mle`) | a expressão dá TRUE |
| PL/SQL Function Body | `functionBody` | a função devolve TRUE |
| Request = Value / != Value | `request=Value` / `request!=Value` | o `REQUEST` é igual / diferente do valor |
| Request is (NOT) contained in Value | `requestIsContainedInValue` / `requestIsNotContainedInValue` | o `REQUEST` está / não está contido no texto |
| Item = Value / != Value | `item=value` / `item!=value` | o valor do item é igual / diferente |
| Item is NULL / NOT NULL | `itemIsNull` / `itemIsNotNull` | vazio / com valor |
| Item is zero / NOT zero / NULL or zero / NOT NULL and NOT zero | `itemIsZero`, `itemIsNotZero`, `itemIsNullOrZero`, `itemIsNotNullAndNotZero` | testes numéricos |
| Item contains no spaces / is numeric / is NOT numeric / is alphanumeric | `itemContainsNoSpaces`, `itemIsNumeric`, `itemIsNotNumeric`, `itemIsAlphanumeric` | testes de formato |
| Item is (NOT) in colon delimited list | `itemIsInColonDelimitedList` / `itemIsNotInColonDelimitedList` | o valor está (não está) na lista `a:b:c` |
| Text is contained in Item; Text = / != Value; Text is (NOT) contained in Value | `textIsContainedInItem`, `text=value`, `text!=value`, `textIsContainedInValue`, `textIsNotContainedInValue` | comparações de texto |
| User Preference = / != Value | `userPreference=value` / `userPreference!=value` | preferência do usuário |
| Current Page = / != Page | `currentPage=page` / `currentPage!=page` | página atual |
| Current Page is (NOT) in comma delimited list | `currentPageInList` / `currentPageNotInList` | página atual na lista `3,100,203` |
| Current Page = / != Page Submitted | `currentPage=pageSubmitted` / `currentPage!=pageSubmitted` | constam no enum APEXlang, sem descrição na lista da doc |
| Current page is (NOT) in Printer Friendly mode | `currentPageIsInPrinterFriendlyMode` / `…NotIn…` | modo de impressão |
| Page/Region is (NOT) Read Only | `pageRegionIsReadOnly` / `pageRegionIsNotReadOnly` | condição Read Only da página ou região pai |
| User is authenticated (not public) / User is the public user | `userIsAuthenticated` / `userIsPublicUser` | logado / não logado |
| Inline Validation Errors (NOT) Displayed | `inlineValidationErrorsDisplayed` / `…NotDisplayed` | há erro inline na página re-exibida |
| SQL Reports (OK to show forward/back button) | `sqlReportsOkToShowForwardButton` / `…BackButton` | constam no enum APEXlang, sem descrição na lista da doc |
| Current Language = / != / is (NOT) contained in Value | `currentLanguage=value` … | idioma em uso |
| Client Browser…, CGI env (DAD name, server name, HTTP host) | `clientBrowserIs…`, `cgiEnv…` | constam no enum APEXlang, sem descrição na lista da doc |
| Always / Never | `always` / `never` | |

Exemplos:

```sql
-- PL/SQL Expression
nvl(:MY_ITEM, 'NO') = 'YES'
-- Rows returned
select 1 from employees where department_id = :P101_DEPTNO
```

Na lista de *Available Conditions*, a linha "PLSQL Expression" diz "The SQL expression evaluates to TRUE". É um erro de texto da doc: o tipo avalia uma expressão **PL/SQL**.

Fonte: [Available Conditions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/available-conditions.html), [How Does Page Processing and Page Rendering Work? (Understanding Conditional Rendering and Processing)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/how-does-page-processing-and-page-rendering-work.html), [APEXlang API Reference: serverSideCondition](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Exemplo: botões de formulário condicionados pela PK

O wizard de formulário configura assim:

| Botão | Ação | Execute Validations | Database Action | Server-side Condition |
|---|---|---|---|---|
| `CREATE` | Submit Page | Sim | INSERT | `P4_EMPNO` is null |
| `SAVE` | Submit Page | Sim | UPDATE | `P4_EMPNO` is not null |
| `DELETE` | Submit Page | Não | DELETE | `P4_EMPNO` is not null |
| `CANCEL` | Dynamic Action (Cancel Dialog) | Não | | |

O botão Delete pede confirmação com `&APP_TEXT$DELETE_MSG!RAW.`, no estilo Danger. Num formulário sem modal, o Cancel submete e um branch com *When Button Pressed* = `CANCEL` volta à lista.

Fonte: [Conditional Database Action Buttons](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/conditional-database-action-buttons.html)

---

## 12. Navegação

### Formas de navegação: listas, navigation menu, navigation bar, breadcrumbs, branches, tabs

| Mecanismo | O que é | Tema |
|---|---|---|
| **Navigation Menu** | **lista** renderizada no topo (como abas) ou como barra lateral. Mostra as **funções de negócio**. | Universal Theme |
| **Navigation Bar List** | lista renderizada na posição `#NAVIGATION_BAR#` do template de página. Traz as opções da app no menu do usuário (Settings, About, **Sign Out**). | Universal Theme |
| **List** (região do tipo List) | coleção compartilhada de links; a aparência vem do *list template* (ex.: Wizard Progress, Vertical Unordered List with Bullets) | qualquer |
| **Breadcrumb** | links hierárquicos que mostram onde o usuário está | qualquer |
| **Branch** | navegação depois do submit (§10) | qualquer |
| **Tabs** (standard e parent) | navegação por abas de um ou dois níveis | **só temas antigos** (ex.: Theme 26) |
| **Classic Navigation Bar** | entradas de barra de navegação clássica | **só temas antigos**; exige `#NAVIGATION_BAR#` no template |

- O wizard *Create Application* cria a entrada **Sign Out**. Recursos como About Page e Push Notification acrescentam outras. Novas entradas vão em *Shared Components > Navigation Bar List*.
- Ao criar uma página, o wizard oferece **Use Navigation** (cria a entrada no navigation menu, com Parent e Icon, ex.: `fa-users-alt`) e **Use Breadcrumb**.
- Os links de lista e de breadcrumb usam o Link Builder: *Page*, *Set Items*/*With these values*, *Clear Cache*, *Request* e *reset pagination*. Valores via `f?p=` **não podem ter `:`**, e vírgulas precisam de `\…\`.

Fonte: [Adding Navigation](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/adding-navigation.html), [About Using Lists as Navigation](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-creating-lists-as-navigation.html), [Navigating to Business Functions](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/navigating-business-functions.html), [App Options in the Navigation Bar](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/app-options-navigation.html), [Managing Tabs](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-tabs.html), [Managing a Classic Navigation Bar](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-classic-navigation-bar.html)

### Breadcrumbs: criar, entradas, região e breadcrumb dinâmico

**Como criar** (três caminhos):

1. No wizard *Create Page*, com **Use Breadcrumb** e *Breadcrumb Parent Entry*. O nome da página vira o nome da entrada.
2. Em *Shared Components > Navigation and Search > Breadcrumbs > Create Breadcrumb*.
3. No Page Designer, aba *Page Shared Components*: clique direito em *Breadcrumb* > *Create*.

Depois, adicione a **região Breadcrumb**, pelo menu *Create > Breadcrumb Region* ou pela Gallery (*Regions > Breadcrumb > Add To > Breadcrumb Bar*). No Universal Theme, use o template de região **Title Bar** na posição de breadcrumb.

**Atributos da entrada (Breadcrumb Entry):**

| Atributo | Descrição |
|---|---|
| Page | página em que a entrada aparece como atual |
| Parent Entry | entrada pai. **Cada breadcrumb deve ter uma única raiz**, a entrada sem pai. |
| Sequence | ordem |
| Short Name / Long Name | textos usados pelo template de breadcrumb |
| Synchronize page name and title | atualiza Name e Title da página com o short name |
| Target | *Page in this Application* (Page, reset pagination, Request, Clear Cache, Set these items / With these values) ou *URL* |
| Conditions, Authorization Scheme, Build Option, Static ID | |

**Breadcrumb dinâmico:** ponha uma referência a session state no short ou long name, por exemplo `&P6_ENAME.`, para mostrar "Home > Orders > Orders for ACME Inc". Para o valor continuar certo nas páginas seguintes do drill-down, o item (e a PK, como `P6_EMPNO`) precisa ter **Storage = Per Session (Persistent)**. Na página filha, a query pode filtrar por `EMPNO = :P6_EMPNO`.

**Manutenção:** *Grid Edit* (editar nomes em lote), *Utilization* (uso por página e entradas órfãs, removíveis com *Delete Unused*), *History* e *Reparent Entries* (arrastar e soltar ou menu *Reparent*). **Excluir um breadcrumb exclui todas as regiões que o referenciam.**

Fonte: [Creating Breadcrumbs](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-breadcrumbs.html), [About Breadcrumbs](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-breadcrumbs.html), [Creating a Breadcrumb While Creating a Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-breadcrumb-while-creating-page.html), [Creating a Breadcrumb Manually](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-breadcrumb-manually.html), [Editing Breadcrumbs](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-breadcrumbs.html), [Accessing Breadcrumb Reports](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/accessing-breadcrumb-reports.html), [Breadcrumbs Visualize Drilldown Path](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/breadcrumbs-visualize-drillldown-path.html)

### Fluxo de wizard em várias páginas (Wizard Progress + branches + Per Session)

Padrão do Developer's Companion (Onboard New Employee, páginas 43, 44 e 45):

1. **Create Page > Wizard**: define o nome, os passos (label e número de página) e o ícone. O APEX cria as páginas ligadas por **branches** e uma **lista compartilhada** cujas entradas são os passos.
2. Cada página tem uma **região List** com template de região *Wizard Container* e template de lista **Wizard Progress** (o "trem" de passos). Os slots *Previous*, *Close* e *Next* da região recebem os botões.
3. **Branches por botão**: Next vai para a página seguinte, `<` volta para a anterior, Finish vai para a home. Cancel é **redirect** para a home, com *Warn on Unsaved Changes* = *Do Not Check*.
4. **Itens com Storage = Per Session (Persistent)**, para o usuário ir e voltar sem perder dados.
5. **Finish**: um process (Execute Code ou Invoke API com *When Button Pressed* = `FINISH`) grava tudo e, em seguida, um **Clear Session State** limpa as páginas 43, 44 e 45. Também dá para limpar no *Clear Cache* do link que inicia o wizard (`43,44,45`).
6. Considere **Deep Linking = Disabled**, para o navegador não reabrir o meio do wizard.

Fonte: [Configuring a Wizard Page Flow](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configuring-wizard-page-flow.html), [Creating a Multi-Step Wizard](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/creating-multi-step-wizard.html), [Multi-Step Wizard in Page Designer](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/multi-step-wizard-page-designer.html), [Shared List Defines Wizard Pages](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/shared-list-defines-wizard-pages.html), [How APEX Manages User Session State](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/how-apex-manages-user-session-state.html), [Clearing State with a Page Process](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/clearing-state-page-process.html)

### Fluxo lista + edição (Interactive Report + Form em modal/drawer)

O wizard *Create Page > Interactive Report* com **Include Form Page** gera:

1. **Página de lista** com **Link Column** = *Link to Custom Target*. Ela aponta para o form, com *Set Items* `P4_EMPNO` = `\#EMPNO#\` e o ícone `<span role="img" aria-label="Edit" class="fa fa-edit" title="Edit"></span>`. O botão **Create** **não passa parâmetro**.
2. **Página de form**, por padrão um **modal Drawer**:
   - **Form - Initialization** (Before Header) busca a linha pela PK, se ela vier preenchida.
   - Os itens usam **Per Request (Memory Only)**, então o form abre vazio sem PK.
   - **Form - Automatic Row Processing (DML)** usa o *Database Action* dos botões.
   - Os botões CREATE, SAVE e DELETE têm condições pela PK.
   - **Close Dialog**, depois da DML, tem a condição `REQUEST` in `CREATE,SAVE,DELETE`.
3. Na lista, uma **Dynamic Action no evento Dialog Closed**, filtrada pela região que abriu o diálogo, faz **Refresh** do Interactive Report.

Fonte: [Studying a List and Edit Flow](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/studying-list-and-edit-flow.html), [Creating List and Edit Pages](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/creating-list-and-edit-pages.html), [Linking to the Edit Page](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/linking-edit-page.html), [Refreshing List On Dialog Close](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/refreshing-list-dialog-close.html)

### Modal dialogs e drawers: Page Mode, Chained, Close Dialog e retorno de itens

- **Page Mode = Modal Dialog**: a página abre centralizada sobre a que a chamou, e o usuário não interage com a de baixo. Por padrão o tamanho segue o conteúdo; largura e altura podem ser fixadas, ou o diálogo pode ocupar todo o espaço.
- **Dialog Template = Drawer**: o modal ocupa toda a altura e desliza do início ou do fim da janela.
- **Fechar**: DA **Close Dialog** ou process **Close Dialog**. Os dois podem **devolver itens** (*Dialog Return Items*) que a página chamadora lê numa DA do evento **Dialog Closed**. **Cancel Dialog** cancela.
- **Chained**: se o modal faz branch ou redirect para outro modal do mesmo tipo, **On** reaproveita a janela; **Off** abre outra por cima.
- Ao gerar URL para abrir modal em PL/SQL, `APEX_PAGE.GET_URL` precisa de `p_triggering_element`. Dentro de um modal, use `p_plain_url => TRUE` se não quiser o JS de fechamento.

Fonte: [Modal Dialogs and Drawers](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/modal-dialogs-and-drawers.html), [GET_URL Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_URL-Function.html)

### AJAX × redirect × submit: três formas de falar com o servidor

| Mecanismo | O que envia | Atualiza session state? | Exemplo |
|---|---|---|---|
| **Submit + branch** | todos os itens da página | sim (Accept Page) | botão *Submit Page* |
| **Ajax** | só os itens listados (*Page Items to Submit*, *Items to Submit*) | só desses itens | DA *Execute Server-side Code*, DA *Refresh* de região, process On Demand |
| **Redirect** | só os parâmetros da URL (itens, request, clear cache) | só dos parâmetros | botão ou link com URL, `apex.navigation.redirect` |

- Na DA *Refresh*, o APEX faz um Ajax que envia os itens de *Page Items to Submit* da região e recebe o HTML parcial, aplicado automaticamente.
- No **redirect**, as mudanças digitadas na página **não** vão ao servidor. O aviso **Warn on Unsaved Changes** (página e item) avisa o usuário. Um item de filtro com *Per Request (Memory Only)* pode ficar fora do aviso.

Fonte: [Understanding AJAX and Redirect](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-ajax-and-redirect.html), [Additional Page Flow Features](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/additional-page-flow-features.html)

---

## 13. Correlação entre sessão APEX e sessão de banco

### Atributos de sessão de banco que o APEX define (client_id, client_info, module, action, longops)

Durante uma requisição, o APEX preenche atributos visíveis em `v$session`, `v$sqlarea`, `v$session_longops`, auditoria e trace. Servem para diagnosticar desempenho.

| Atributo | Tamanho | Como o APEX preenche (sessão de aplicação) | Ler / gravar |
|---|---|---|---|
| `client_id` | 64 bytes | `app_user || ':' || session-id` (ex.: `jane.doe@example.com:12161645673208`). Antes da autenticação: `'nobody:' || session-id`. Usuário longo é truncado. | `dbms_session.set_identifier`; `sys_context('USERENV','CLIENT_IDENTIFIER')`; coluna `client_identifier` |
| `client_info` | 64 bytes | `workspace-id || ':' || app_user` | `dbms_application_info.set_client_info` / `read_client_info`; `sys_context('USERENV','CLIENT_INFO')` |
| `module` | 48 bytes | `schema || '/APEX:APP ' || app-id || ':' || page-id` (ex.: `MY_DB/APEX:APP 17251:4`) | `dbms_application_info.set_module` / `read_module`; `sys_context('USERENV','MODULE')` |
| `action` | 32 bytes | varia conforme a fase: `'start_page_request'`, `'PAGE ' || page-id`, `'computation and processes'`, `'fetch meta data'`, `'Processes - point: ' || process-point`, `'Validations'`, `'branching'`, `'import app ' || app-id` | `set_module` / `set_action`; `sys_context('USERENV','ACTION')` |
| session longops | | | `dbms_application_info.set_session_longops`; `v$session_longops` |

Recomendações:

- **Não altere** `client_id` nem `client_info` dentro de uma sessão APEX. Não quebra o APEX, mas atrapalha as ferramentas de monitoramento.
- **Defina `module` e `action`** no seu código para mostrar o que está sendo processado.
- Use **longops** em processos longos divisíveis em unidades (ex.: "registros processados").
- O APEX chama a versão **SYS** de `dbms_application_info`. Um wrapper com o mesmo nome no seu schema é ignorado.
- A maioria dos processos do APEX **reseta os valores para NULL** ao terminar, sem restaurar os anteriores.

Fonte: [Correlating APEX Sessions to Database Sessions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/correlating-apex-sessions-to-database-sessions.html)

### Valores de module/action em mail, SQL Workshop, Data Workshop, automations e instalador

| Contexto | `client_id` | `client_info` | `module` | `action` |
|---|---|---|---|---|
| Sessão de e-mail em background | `mail-from || ':' || message-guid` | `workspace-id || ':' || mail-from` | inalterado | inalterado |
| SQL Commands (Autocommit ON) | `app_user:session-id` | `workspace-id:app_user` | `'APEX:SQL Workshop'` | o comando SQL |
| SQL Commands (Autocommit OFF; roda num **job** separado) | idem | idem | `'APEX:SQL Workshop-No Autocommit'` | `Working sql-statement`, `Idle, awaiting work`, `Stopping` |
| SQL Scripts | idem | idem | `'APEX:SQL Workshop:Script'` | nome do script; longops `SQL statement N of M` |
| Data Workshop | inalterado | `workspace-id:app-user` | `schema/APEX:APP<id>:DATA_LOADING` (ou `:DATA_LOADING_SODA`) | `Data Loading Job` |
| Automations | inalterado | `workspace-id:` | módulo da automação | `<static-id>:I` (init), `<static-id>` (fetch), `…:R<n>:B` (before), `…:R<n>:A<seq>` (ação), `…:R<n>` (fim), `…:T` (cleanup); static ID truncado em 16 caracteres |
| Instalador | inalterado | inalterado | `'APEX ' || install-type || ' PHASE ' || phase` | `'upgrade'`, `'recompiling'`… |

O checkbox *Autocommit* do SQL Commands só aparece se *Enable Transactional SQL Commands* estiver habilitado em *Administration Services > Feature Configuration*.

```sql
-- quem está processando o quê agora
select sid, client_identifier, client_info, module, action
  from v$session
 where module like '%/APEX:APP %';
```

Fonte: [Correlating APEX Sessions to Database Sessions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/correlating-apex-sessions-to-database-sessions.html)

---

## 14. Limites do APEX

### Limites de componentes (Component Limits)

| Componente | Limite |
|---|---|
| Data loading (legado) | no máximo **45 colunas** |
| Export de IR ou Classic Report com print server externo | **32k** no sub-template de cabeçalho; cerca de **26 colunas** ou menos, conforme o tamanho dos aliases |
| Forms | **32767 bytes** em text area ou rich text editor. **Duas colunas de PK** com o DML built-in; com mais, use **ROWID**. |
| Interactive Report | **999 linhas** por filtro de cabeçalho de coluna (sem LOV customizada); chart do IR com até **10.000 pontos** |
| Nomes de item | **até 30 caracteres** para usar como bind (o campo aceita 255) |
| PDF e Excel nativos | uma linha de PDF pode quebrar em várias linhas e ter **uma** quebra de página; acima disso, trunca. Célula de Excel com até **32k**, depois trunca. Para layouts avançados, use um report server. |
| Tabular Forms (legado) | **uma** tabular form de wizard (DML built-in) por página; **50 colunas** editáveis (`apex_application.g_f01`–`g_f50`) |
| Validations | o texto não passa de **3.950 caracteres** |

Outros limites citados nesta área: session state criptografado até **4000 bytes** por valor; `client_id`/`client_info` com **64 bytes**, `module` com **48**, `action` com **32**; os atributos de condição, computation e mensagem no APEXlang aceitam `maxLen=4000`, e o código de application process aceita `maxLen=32767`.

Fonte: [Oracle APEX Limits](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/oracle-apex-limits.html), [About Session State and Security](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-session-state-and-security.html), [Correlating APEX Sessions to Database Sessions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/correlating-apex-sessions-to-database-sessions.html), [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

---

## 15. Problemas conhecidos e troubleshooting

### Bind variable vazio no refresh da região (query sem linhas ou lógica errada)

**Sintoma:** a região mostra os dados certos ao abrir a página, mas, depois de mudar um filtro e fazer *Refresh*, volta vazia ou com o resultado errado. Ou uma DA *Execute Server-side Code* dá **No Data Found** e não devolve o valor para a página.
**Causa:** o item usado como `:P1_X` não está em **Page Items to Submit** da região, ou em *Items to Submit* da DA. No Ajax, o bind vale NULL. Valores alterados pelo PL/SQL só voltam à página se estiverem em *Items to Return*.
**Correção:** liste os itens, sem `:`, separados por vírgula, em *Page Items to Submit* ou *Items to Submit*, e os de saída em *Items to Return*.
**Prevenção:** ao escrever `:ITEM` numa região ou DA, preencha o atributo na hora. Itens *Per Request (Memory Only)* dependem disso.

Fonte: [Configure Items to Submit and Return](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configure-items-submit-and-return.html)

### ORA-01858 ou comparação de datas errada com item Date Picker

**Sintoma:** `ORA-01858: A non-numeric character was found instead of a numeric character.` em `HIREDATE < :P34_HIRED_BEFORE`; ou a validação `:P1_INICIO <= :P1_FIM` aceita um intervalo invertido (`22-MAY-2025` > `30-APR-2025`).
**Causa:** o bind é **VARCHAR2**. A máscara do item (`DD-MON-YYYY`) é diferente da máscara default da app (ex.: `DS`), e a comparação de strings segue ordem de texto.
**Correção:** use `apex_session_state.get_timestamp('P34_HIRED_BEFORE')`, que aplica a máscara do item. Em colunas de IG, use `to_date`/`to_timestamp` com a máscara.
**Prevenção:** nunca compare datas de item como string.

Fonte: [Working with Data Values as Dates](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/working-data-values-dates.html)

### ORA-00932 "expression (:1) is of data type CHAR" ou comparação numérica errada

**Sintoma:** `ORA-00932: expression (:1) is of data type CHAR, which is incompatible with expected data type NUMBER` num `CASE ... THEN :P5_MAX_QUANTITY`; ou a validação `:P1_LOW <= :P1_HIGH` passa com 22 e 3.
**Causa:** o bind é string. A conversão implícita funciona em `BETWEEN` com coluna numérica, mas não onde o banco espera NUMBER sem contexto, e a comparação entre dois binds é textual.
**Correção:** `apex_session_state.get_number('P5_MAX_QUANTITY')`. Em IG, `to_number` com máscara.
**Prevenção:** trate todo bind como VARCHAR2 e converta.

Fonte: [Working with Data Values as Numbers](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/working-data-values-numbers.html)

### ORA-01722 com IN (:ITEM) de seleção múltipla, ou nenhuma linha retornada

**Sintoma:** `ORA-01722: unable to convert string value containing ':' to a number` / `ORA-03302 … invalid string value: 7839:7369:7654`; ou, com strings, a query não retorna nada.
**Causa:** o item de múltipla seleção guarda **uma** string delimitada, e `IN (:ITEM)` compara com o literal inteiro.
**Correção:** `where col in (select column_value from apex_string.split_numbers(:ITEM, ':'))` ou `apex_string.split(:ITEM, '|')`, com o delimitador do item.
**Prevenção:** ao usar Select Many, Shuttle ou Checkbox Group, use `apex_string` direto.

Fonte: [Working with Delimited Number Values](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/working-delimited-number-values.html), [Working with Delimited String Values](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/working-delimited-string-values.html)

### Link com parâmetros falha em página "Arguments Must Have Checksum"

**Sintoma:** um link montado à mão (`f?p=&APP_ID.:18:&SESSION.::NO::P18_ID:123` ou `…/r/…/pagina?p18_id=123&session=…`) é recusado com erro de checksum ou de proteção, enquanto o mesmo link do Link Builder funciona.
**Causa:** Session State Protection está habilitado e a página-alvo exige checksum quando a URL traz Request, Clear Cache ou itens. A URL manual não leva o `cs=`.
**Correção:** gere a URL com `apex_page.get_url(p_page => 18, p_items => 'P18_ID', p_values => 123)`, com `apex_util.prepare_url`, ou pelo Link Builder. Em e-mails e links para outros usuários, use `p_checksum_type => 'PUBLIC_BOOKMARK'` do `PREPARE_URL` e item com *Checksum Required - Application Level*.
**Prevenção:** nunca concatene `f?p` com itens em SQL ou PL/SQL.

Fonte: [Preventing URL Tampering](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/preventing-url-tampering.html), [GET_URL Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_URL-Function.html), [PREPARE_URL Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PREPARE_URL-Function.html)

### Item não é alterado por Set Value, cascading LOV ou Ajax (Session State Protection)

**Sintoma:** uma DA *Set Value* ou uma cascading LOV que envia um **application item** (ou page item protegido) não grava o valor no servidor.
**Causa:** o item está com Session State Protection **Restricted - May not be set from browser** (o default de application item no APEXlang) ou com *Checksum Required*. Para ser setado por Ajax, o item precisa estar **Unrestricted**.
**Correção:** mude o item para *Unrestricted*, se for seguro, ou passe o valor a um page item e calcule o app item no servidor (computation ou process).
**Prevenção:** não exponha ao navegador app items que guardam contexto de segurança (empresa, perfil). Mantenha-os *Restricted* e calcule-os no servidor.

Fonte: [Managing Application Items](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-application-items.html), [Preventing URL Tampering](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/preventing-url-tampering.html)

### Dados digitados somem depois de erro de validação (Form - Initialization/Fetch)

**Sintoma:** depois de um erro, o formulário volta com os valores do banco em vez do que o usuário digitou, ou uma computation de renderização "não roda".
**Causa:** é o comportamento documentado. Com erros inline, o APEX pula computations e processes de renderização para não sobrescrever o que foi digitado. O debug mostra `Skip because inline validation errors found.` ou `Do not perform computation because inline validation errors found.`
**Correção:** se um componente de renderização **tem** de rodar mesmo com erro, condicione-o com **Inline Validation Errors Displayed**. Para tabular form manual (`APEX_ITEM`), use erro *On Error Page*.
**Prevenção:** não mova lógica que reescreve itens para pontos de renderização sem pensar nesse caso.

Fonte: [Understanding Validations](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-validations.html), [Understanding Application Processes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-application-processes.html)

### Form não grava (Automatic Row Processing não faz DML)

**Sintoma:** o usuário clica em salvar, a página fecha ou recarrega sem erro, mas a linha não é inserida nem alterada.
**Causa:** o botão que submeteu não tem **Database Action** (INSERT, UPDATE ou DELETE). Sem ela, o process *Form - Automatic Row Processing (DML)* não faz nada.
**Correção:** defina *Behavior > Database Action* no botão (Action = Submit Page), ou faça a DML em PL/SQL (*Target Type*).
**Prevenção:** ao criar botões à mão num form de wizard, copie a configuração de CREATE, SAVE e DELETE.

Fonte: [Saving Changes with a Page Process](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/saving-changes-page-process.html), [Conditional Database Action Buttons](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/conditional-database-action-buttons.html)

### Form de edição abre vazio ou com dados de outro registro

**Sintoma:** o form em modal abre sem dados ao clicar em editar, ou mostra dados do último registro aberto.
**Causa:** (a) o link não passa a PK (`P4_EMPNO`), e o *Form - Initialization* só busca quando **todas** as PKs têm valor; (b) a PK foi definida com *Per Session*, e o valor de uma visita anterior continua no session state.
**Correção:** passe a PK no link (Link Builder, *Set Items* = `\#EMPNO#\`) e mantenha os itens do form com **Per Request (Memory Only)**. No botão Create, limpe a página (*Clear Cache*).
**Prevenção:** siga o padrão do wizard de lista e edição.

Fonte: [Retrieving Existing Row by Primary Key](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/retrieving-existing-row-primary-key.html), [Memory Only Storage for Form Page Items](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/memory-only-storage-form-page-items.html)

### Process roda com o botão errado (Request is contained in Value)

**Sintoma:** a lógica do botão `SAVE_ADDRESS` também dispara quando se clica em `SAVE`.
**Causa:** a condição `Request is contained in Value` com `SAVE_ADDRESS,SAVE_ASSIGNMENT` faz busca de texto, e `SAVE` está contido na string.
**Correção:** use a PL/SQL Expression `:REQUEST in ('SAVE_ADDRESS','SAVE_ASSIGNMENT')`, ou *When Button Pressed* para um único botão.
**Prevenção:** evite nomes de botão que sejam prefixo de outros, ou use sempre `IN`.

Fonte: [Making Almost Any Element Conditional](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/making-almost-any-element-conditional.html)

### On Demand process por URL devolve página em branco

**Sintoma:** `f?p=…:APPLICATION_PROCESS=MEU_PROC` mostra uma página vazia, sem erro (para o usuário final).
**Causa:** falha de autenticação, de autorização (o process de aplicação nasce com *Must Not Be Public User*) ou da condição do process. Nesse caminho os erros não aparecem para o usuário, só para quem está logado no Builder.
**Correção:** rode logado no Builder para ver o erro. Revise a authorization e a condição. Confira o nome, que distingue maiúsculas.
**Prevenção:** prefira processes On Demand de página, chamados por `apex.server.process`.

Fonte: [Understanding Application Processes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-application-processes.html)

### Clear cache "APP" não zera a aplicação

**Sintoma:** depois de `…::NO:APP`, alguns itens continuam com valor.
**Causa:** os processes e computations **On New Instance** rodam de novo ao criar a sessão, antes de o clear cache ser aplicado.
**Correção:** para zerar de verdade, faça logout (sessão em cookie), peça a app sem session ID ou chame `APEX_UTIL.CLEAR_APP_CACHE` de outra app.

Fonte: [Managing Session State Values (About Resetting an Application Completely)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-session-state-values.html)

### Mudança em app item ou session state "não fica" ou commita DML cedo demais

**Sintoma:** (a) com *Immediate*, um DML feito antes de `:ITEM := …` fica confirmado mesmo que um erro posterior aconteça; (b) com *End Of Request*, `apex_util.set_session_state(..., p_commit => true)` não commita na hora.
**Causa:** o atributo **Session State Commits**. Em *Immediate*, cada mudança de estado grava e commita a transação principal. Em *End Of Request* (default no APEXlang), as mudanças são aplicadas no fim e `p_commit` é ignorado. Os commits implícitos também incluem "depois de uma computation" e "depois de alterar o valor de um item".
**Correção:** organize a transação (DML e atribuição no fim, ou DML num package com tratamento próprio) e escolha o modo coerente com a app.
**Prevenção:** documente o modo da app e não dependa de commit implícito para atomicidade.

Fonte: [Configuring Security Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-security-attributes.html), [How Does Page Processing and Page Rendering Work?](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/how-does-page-processing-and-page-rendering-work.html), [SET_SESSION_STATE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_SESSION_STATE-Procedure.html)

### "Your session has timed out" ou sessão que cai

**Sintoma:** o usuário volta depois de um tempo e vê "Your session has timed out" com um link para a home, ou o login aparece de novo.
**Causa:** estourou o **Maximum Session Idle Time** (default 1 h na instância) ou o **Maximum Session Length** (default 8 h). Vale o valor da app, depois o do workspace, depois o da instância.
**Correção:** ajuste os tempos em *Security > Session Management*. Configure *Session Timeout Warning* (default 5 min) e as URLs de timeout, que devem apontar para uma página pública ou para `#LOGOUT_URL#`.
**Prevenção:** um wizard longo deve salvar rascunho. Usuários avisados podem estender a sessão no aviso de idle.

Fonte: [Configuring Security Attributes (Session Management)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-security-attributes.html), [Configuring Session Timeout for an Instance](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuiring-session-timeout.html)

### Duas abas da mesma app se atrapalham

**Sintoma:** o usuário edita registros diferentes em duas abas e os valores se misturam (itens Per Session, wizard).
**Causa:** as abas compartilham a **mesma sessão** e o mesmo session state.
**Correção:** ofereça um link "abrir em nova aba" com `REQUEST` = `APEX_CLONE_SESSION`, que exige `CLONE_SESSION_ENABLED = Y` na instância. Para formulários, use itens *Per Request*.

Fonte: [Managing Session State Values (About Session Cloning)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-session-state-values.html)

### &ITEM. não substitui (CLOB, nome > 30, ponto final esquecido)

**Sintoma:** o texto aparece literalmente como `&P1_X` ou sai vazio.
**Causa:** (a) faltou o **ponto final** (`&P1_X.`); (b) o item é **CLOB**, que não aceita `&ITEM.`; (c) o nome tem caractere especial e precisa de aspas (`&"P1-X".`); (d) o atributo não aceita substituições (veja a aba Help).
**Correção:** corrija a sintaxe. Para CLOB, exiba com item Display Only ou Read Only, ou numa região Dynamic Content. Em SQL e PL/SQL, use `:ITEM`, nunca `&ITEM.`.

Fonte: [Managing Session State Values (About Referencing Session State)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-session-state-values.html), [About Using Substitution Strings](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-using-substitution-strings.html)

---

## 16. Aplicação no Corlix Hub

> O estado do projeto vem de `docs/ai-context/` (README, 02, 03, 08) e dos `.apx` em `corlixhub/`, conferidos em 21/10/2026. Atributos que **não aparecem** no `application.apx` foram interpretados pelo **default documentado no APEXlang**. Antes de afirmar algo ao usuário, confira no Builder 26.1.5 (*Shared Components > Security Attributes*); esses pontos estão marcados "(confirmar no 26.1.5)".

### Corlix Hub: URLs, Session State Protection e links com checksum

- **Friendly URLs**: o `application.apx` não declara `friendlyUrls`, e o default é `true`. Isso bate com os links `r/corlixhub/&APP_ALIAS./notificacoes?session=&SESSION.` da Global Page (`ai-context/02` e `03`). O formato oficial é `/ords/r/<path_prefix>/<app_alias>/<page_alias>`, em que `path_prefix` é o **Path Prefix do workspace**, não um valor fixo. O caminho `r/corlixhub/...` fixo e relativo depende dele e pode duplicar segmentos, como o `ai-context/02` já registra. Prefira o Link Builder ou `apex_page.get_url`.
- **Session State Protection** está ligado (`sessionStateProtection { checksumSalt: … }`; `ai-context/03` registra `p_bookmark_checksum_function=>'SH512'`) e as páginas usam `pageAccessProtection: argumentsMustHaveChecksum`. Pela regra da doc, **toda URL com itens, Request ou Clear Cache precisa de `cs=`**. É por isso que a regra 4 do projeto ("links com `apex_page.get_url`") existe:

```sql
-- link para a movimentação (p18, modal) a partir de um relatório
select apex_page.get_url(
         p_page   => 18,
         p_items  => 'P18_ID_COLABORADOR,P18_ID_HISTORICO_CARREIRA',
         p_values => c.id_colaborador || ',' || h.id_historico_carreira) as link
  from ...
 where c.id_empresa = :G_ID_EMPRESA;
```

- Os itens de PK das páginas 14, 16, 18 e 19 usam `sessionStateProtection: checksumRequiredSessionLevel`: só aceitam valor por URL com checksum **da sessão atual**. Um link enviado por e-mail para outra pessoa precisaria de *Application Level* + `PUBLIC_BOOKMARK`. Não mude isso sem uma decisão de segurança.
- Concatenar `'f?p=&APP_ID.:18:&SESSION.::NO::P18_ID:'||id` num SQL **quebra** nessas páginas. O `ai-context/08` §1 regra 6 já registra isso.

Fonte: [Understanding Friendly URL Syntax](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-friendly-url-syntax.html), [Preventing URL Tampering](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/preventing-url-tampering.html), [GET_URL Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_URL-Function.html)

### Corlix Hub: application items, application processes e o contexto multiempresa

- **App items** (`shared-components/app-items.apx`): `APP_USER_CARGO`, `APP_USER_FOTO`, `APP_USER_INICIAIS`, `APP_USER_NOME`, `G_ID_EMPRESA`, `G_NOME_EMPRESA` e `G_NOME_USUARIO`, todos sem atributos declarados. Pelo default do APEXlang ficam com `scope: app`, `sessionStateProtection: restricted` e `escapeSpecialChars: true`. Para `G_ID_EMPRESA` isso é **desejável**: o navegador não consegue trocar a empresa pela URL nem por POST. Não passe para *Unrestricted*. (confirmar no 26.1.5)
- **App processes** (`app-processes.apx`): `APP_USER_CARGO`, `APP_USER_FOTO`, `G_NOME_EMPRESA` e `G_NOME_USUARIO` não declaram `point`, então ficam no default **`beforeHeader`**. Rodam em **toda renderização de toda página**, inclusive o login, o que bate com o `ai-context/03` e o `08`. `SET_G_ID_EMPRESA` roda em **`afterAuthentication`**: só é preenchido no login, o que explica a pegadinha do `08` ("G_ID_EMPRESA só é preenchido depois de um novo login").
- **Recomendação baseada na doc**: valores que dependem do usuário e não mudam durante a sessão (cargo, foto, nome, empresa) cabem no padrão **app item + application computation (ou process) em After Authentication**. Isso evita 4 queries por página. Se algum precisar refletir mudanças durante a sessão, mantenha em Before Header com condição (por exemplo, `User is authenticated (not public)`).
- **Multiempresa**: use `:G_ID_EMPRESA` como **bind** nas queries (`where x.id_empresa = :G_ID_EMPRESA`), nunca `&G_ID_EMPRESA.` em SQL, por causa do risco de SQL injection apontado pela doc. Lembre que é **VARCHAR2**: a comparação com uma coluna NUMBER funciona por conversão implícita, mas em `CASE` ou entre dois binds use `apex_session_state.get_number('G_ID_EMPRESA')`. Em packages chamados pela app (ex.: `pkg_historico_carreira`), leia com `v('G_ID_EMPRESA')` ou `apex_session_state.get_number(...)`, ou receba como parâmetro, que é a recomendação da doc para código reutilizável. Para uma eventual política VPD, a doc indica `SYS_CONTEXT('APEX$SESSION','APP_USER')`.
- A validação `Empresa do usuário` da p14 (`:P14_EMPRESA = :G_ID_EMPRESA`) compara duas strings. Para igualdade de IDs sem máscara, funciona.

Fonte: [Managing Application Items](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-application-items.html), [Application Items](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/application-items.html), [Understanding Application Processes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-application-processes.html), [Values Bind as Strings](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/values-bind-strings.html), [APEXlang API Reference: appItem, appProcess](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Corlix Hub: fluxo das páginas modais (p16, p18, p21, p27) e condições por REQUEST

- As páginas modais seguem o padrão lista + modal do wizard: *Form - Initialization* em `beforeHeader`, DML no submit e `closeDialog` com `requestIsContainedInValue`. Na p16, p21 e p27 o valor é `CREATE,SAVE,DELETE`; na p18, `SALVAR_RASCUNHO,EFETIVAR,ESTORNAR,EXCLUIR`.
- **Pegadinha de "contido" na p18**: `Request is contained in Value` faz busca de texto. Um botão novo chamado `SALVAR` ou `EXCLUIR_ANEXO` casaria por acidente. Ao criar botões ali, use nomes que não sejam prefixo ou parte de outro, ou troque a condição por `:REQUEST in ('SALVAR_RASCUNHO','EFETIVAR','ESTORNAR','EXCLUIR')`.
- **Datas na p18**: `P18_DT_EFETIVA` é Date Picker com `formatMask: DD/MM/YYYY`, e o process faz `to_date(:P18_DT_EFETIVA, 'DD/MM/YYYY')`. Funciona enquanto a máscara não mudar. A forma robusta indicada pela doc é `apex_session_state.get_timestamp('P18_DT_EFETIVA')`, que acompanha a máscara do item. Isso importa porque a app usa `appFormatMasks: DS` e idioma primário `en` (`ai-context/08`, Configuração).
- **p17 (wizard de comunicado) sem Close Dialog**, registrado no `08`: pelo padrão da doc, o modal precisa de um process **Close Dialog** depois da DML, e a página que chama precisa de uma DA **Dialog Closed** com *Refresh*.
- **Branch da p14** (`point: processing`, `clearCache: 14`): roda **antes** do After Processing. É um branch "Processing", válido no enum do APEXlang. Ele limpa a página toda, inclusive `P14_ID_COLABORADOR`, o que explica por que o botão "Histórico de carreira" nunca aparece (`ai-context/08`).
- **Itens sem `storage` declarado**: a maioria dos itens do projeto usa o default. Itens de Form region ficam com **Per Request**; os demais, com **Per Session**. Filtros e PKs fora de Form region persistem na sessão e podem "vazar" entre visitas. Use o *Clear Cache* do link ou o process *Clear Session State* quando fizer sentido.

Fonte: [Studying a List and Edit Flow](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/studying-list-and-edit-flow.html), [Making Almost Any Element Conditional](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/making-almost-any-element-conditional.html), [Working with Data Values as Dates](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/working-data-values-dates.html), [Refreshing List On Dialog Close](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/refreshing-list-dialog-close.html), [APEXlang API Reference: pageItem sessionState](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Corlix Hub: sessão, timeout, Rejoin e commits

- **Timeout**: a app não define timeout próprio (`ai-context/08`, Configuração), então valem workspace e instância. Os defaults da instância são **1 h de idle** e **8 h de duração**, com aviso 5 min antes. Isso explica a "sessão que cai" descrita no `ai-context/10` §8. Para mudar, use *Security > Session Management* da app (APEXlang `maxSessionIdleTime`, `maxSessionLength`, `sessionTimeoutWarning`).
- **Rejoin Sessions** está desligado (`p_rejoin_existing_sessions=>'N'` em `ai-context/03`), que é o recomendado pela Oracle. URLs sem session ID abrem uma sessão nova.
- **Deep Linking** e **Session State Commits** não estão declarados no `application.apx`. Pelo default do APEXlang seriam *Disabled* e **End Of Request**. Com End Of Request, o `p_commit` de `apex_util.set_session_state` é ignorado e as mudanças de session state são aplicadas no fim da requisição. (confirmar no 26.1.5)
- **Compatibility Mode** não declarado: o default é `26.1`, o que permitiria a sintaxe curta de text messages `&{MSG}.`. A app ainda usa `&APP_TEXT$DELETE_MSG!RAW.` (`ai-context/02`), que continua suportada como legado. (confirmar no 26.1.5)
- **Debug**: `deployments/default.json` está com `debugging: true` (`08`). Em produção, o argumento Debug de `f?p`/`debug=` não deveria ficar ligado por padrão.
- **Logs (p7)**: `APP_LOG.session_id` corresponde ao `APP_SESSION`. Para cruzar com o banco em tempo real, use `v$session.client_identifier` (`APP_USER:session`) e `module` (`<schema>/APEX:APP 100:<página>`), conforme a §13.

Fonte: [Configuring Security Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-security-attributes.html), [Configuring Session Timeout for an Instance](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuiring-session-timeout.html), [Correlating APEX Sessions to Database Sessions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/correlating-apex-sessions-to-database-sessions.html), [APEXlang API Reference: app](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Corlix Hub: checklist de fluxo e session state antes de entregar uma página

- [ ] Links com itens gerados pelo **Link Builder** ou por **`apex_page.get_url`**, nunca concatenados (SSP + `argumentsMustHaveChecksum`)?
- [ ] Toda query de negócio filtra por **`:G_ID_EMPRESA`** como bind e os itens dela estão em **Page Items to Submit** onde há refresh?
- [ ] Datas e números de item lidos com `apex_session_state.get_timestamp`/`get_number` quando comparados ou usados em `CASE`?
- [ ] Seleção múltipla tratada com `apex_string.split`/`split_numbers`?
- [ ] Validations de segurança com **Always Execute = On**; o botão Delete com *Execute Validations* = Off?
- [ ] Botões de form com **Database Action**; Close Dialog e DA *Dialog Closed* + Refresh no modal?
- [ ] Condições por botão com *When Button Pressed* ou `:REQUEST in (...)`, sem depender de "contained in" com nomes parecidos?
- [ ] Itens de form com **Per Request**; itens que precisam sobreviver entre páginas com **Per Session**; e limpeza (*Clear Cache* ou *Clear Session State*) no fim do fluxo?
- [ ] Página administrativa com `authorizationScheme` na própria página (`ai-context/08` regra 8), além da condição ou autorização do menu?
- [ ] Textos de UI em pt-BR; e, se mudou página, fluxo ou shared component, `docs/ai-context/` atualizado?

Fonte: [Preventing URL Tampering](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/preventing-url-tampering.html), [Configure Items to Submit and Return](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configure-items-submit-and-return.html), [Understanding Validations](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-validations.html), [Studying a List and Edit Flow](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/studying-list-and-edit-flow.html)
