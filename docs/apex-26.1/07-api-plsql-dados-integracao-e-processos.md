# 07 · API PL/SQL (dados, integração, e-mail, IA, processos e administração)

> Base: documentação oficial Oracle APEX 26.1 (API Reference/aeapi: capítulos APEX_WEB_SERVICE, APEX_CREDENTIAL, APEX_HTTP, APEX_JWT, APEX_EXEC, APEX_REST_SOURCE_SYNC, APEX_DATA_EXPORT, APEX_DATA_PARSER, APEX_DATA_LOADING, APEX_DATA_INSTALL, APEX_DG_DATA_GEN, APEX_MAIL, APEX_PRINT, APEX_ZIP, APEX_BARCODE, APEX_SPATIAL, APEX_SEARCH, APEX_AI, APEX_WORKFLOW, APEX_HUMAN_TASK, APEX_APPROVAL, APEX_BACKGROUND_PROCESS, APEX_AUTOMATION, APEX_PWA, APEX_EXPORT, APEX_APPLICATION_INSTALL, APEX_APPLICATION_ADMIN, APEX_INSTANCE_ADMIN, APEX_INSTANCE_DEBUG, APEX_EXTENSION, APEX_GENDEV e Changes in Release 26.1; App Builder User's Guide/htmdb: e-mail, Email Templates, Web Credentials, Data Synchronization; Administration/aeadm: Configuring Email; Developer's Companion/apxdc: e-mail; Release Notes/htmrn: New Features, Changed Behavior, Deprecated Features, Fixed Bugs). Gerado em 21/10/2026.

Este documento cobre os packages PL/SQL do APEX 26.1 usados para **integração** (REST, credenciais, JWT, download HTTP), **acesso genérico a dados** (`APEX_EXEC`), **importação/exportação de dados**, **e-mail**, **documentos** (impressão, ZIP, códigos de barras), **busca, mapas e IA**, **processos** (workflow, human tasks, background, automations) e **administração** (export/instalação de apps, instância). Cada package tem: propósito e quando usar, tabela completa de rotinas/constantes/tipos, assinaturas detalhadas das rotinas principais com exemplos, e casos de problema no formato Sintoma/Causa/Correção. APIs **deprecated** estão marcadas.

## Sumário

| § | Package / tema | Para quê |
|---|---|---|
| 2 | `APEX_WEB_SERVICE` | Chamar REST/SOAP (`MAKE_REST_REQUEST`, headers, status code, OAuth) |
| 3 | `APEX_CREDENTIAL` | Gerenciar Web Credentials e tokens OAuth |
| 4 | `APEX_HTTP` | Enviar BLOB/CLOB como download |
| 5 | `APEX_JWT` | Gerar, ler e validar JSON Web Tokens |
| 6 | `APEX_EXEC` | Consultar e fazer DML em SQL local, REST Enabled SQL e REST Data Sources |
| 7 | `APEX_REST_SOURCE_SYNC` | Sincronizar REST Data Sources com tabela local |
| 8 | `APEX_DATA_EXPORT` | Exportar dados em CSV/XLSX/PDF/HTML/JSON/XML |
| 9 | `APEX_DATA_PARSER` | Ler CSV, XLSX, JSON e XML como tabela |
| 10 | `APEX_DATA_LOADING` | Executar Data Load Definitions |
| 11 | `APEX_DATA_INSTALL` | Carregar dados de supporting objects |
| 12 | `APEX_DG_DATA_GEN` | Gerar dados de teste (Data Generator) |
| 13 | `APEX_MAIL` + configuração de e-mail | Enviar e-mails, anexos, templates; fila; SMTP |
| 14 | `APEX_PRINT` | Gerar documentos a partir de templates |
| 15 | `APEX_ZIP` | Criar e ler arquivos ZIP |
| 16 | `APEX_BARCODE` | Gerar QR Code e códigos de barras |
| 17 | `APEX_SPATIAL` | Utilitários de geometria (Oracle Spatial) |
| 18 | `APEX_SEARCH` | Executar Search Configurations |
| 19 | `APEX_AI` | IA generativa: `GENERATE`, `CHAT`, embeddings, tools |
| 20 | `APEX_WORKFLOW` | Iniciar e controlar workflows |
| 21 | `APEX_HUMAN_TASK` | Criar e operar tarefas de aprovação/ação |
| 22 | `APEX_APPROVAL` **(Deprecated)** | API antiga de tarefas |
| 23 | `APEX_BACKGROUND_PROCESS` | Progresso/status de execution chains em background |
| 24 | `APEX_AUTOMATION` | Executar e controlar automations |
| 25 | `APEX_PWA` | Push notifications de PWA |
| 26 | `APEX_EXPORT` | Exportar apps e workspaces |
| 27 | `APEX_APPLICATION_INSTALL` | Instalar apps com outro ID/workspace/schema |
| 28 | `APEX_APPLICATION_ADMIN` | Alterar atributos de apps instaladas |
| 29 | `APEX_INSTANCE_ADMIN` | Administrar instância, parâmetros, workspaces |
| 30 | `APEX_INSTANCE_DEBUG` | Ler debug/activity logs via SQL |
| 31 | `APEX_EXTENSION` | Extension apps e menu de extensões |
| 32 | `APEX_GENDEV` | Geração de apps (blueprints) |
| 33 | Changes in Release 26.1 | O que mudou nas APIs, deprecated, bugs corrigidos |
| 34 | Aplicação no Corlix Hub | Como estas APIs se aplicam ao projeto |

## 1. Visão geral: qual package usar para cada tarefa

| Tarefa | Package principal | Apoio |
|---|---|---|
| Chamar uma API REST externa a partir de PL/SQL | `APEX_WEB_SERVICE.MAKE_REST_REQUEST` | `APEX_CREDENTIAL` (segredos), `APEX_JSON`/`JSON_TABLE` (resposta) |
| Ler um REST Data Source já definido na app (com filtros/paginação) | `APEX_EXEC.OPEN_REST_SOURCE_QUERY` | `APEX_REST_SOURCE_SYNC` para cache local |
| Gerar arquivo Excel/PDF/CSV de uma consulta | `APEX_DATA_EXPORT.EXPORT` | `APEX_EXEC.OPEN_QUERY_CONTEXT`, `APEX_DATA_EXPORT.DOWNLOAD` ou `APEX_MAIL.ADD_ATTACHMENT` |
| Importar planilha enviada pelo usuário | `APEX_DATA_PARSER.PARSE` | `APEX_DATA_LOADING` se houver Data Load Definition |
| Enviar e-mail | `APEX_MAIL.SEND` | Email Templates, `APEX_MAIL.PUSH_QUEUE`, `APEX_BARCODE` para QR inline |
| Fluxo com aprovação humana | `APEX_HUMAN_TASK` | `APEX_WORKFLOW` para fluxos com várias etapas |
| Processamento longo iniciado pelo usuário | Execution Chain em background | `APEX_BACKGROUND_PROCESS` |
| Processamento agendado/por condição | Automation | `APEX_AUTOMATION` |
| Texto gerado por IA | `APEX_AI.GENERATE` / `CHAT` | AI Agents, `APEX_AI.GET_VECTOR_EMBEDDINGS` |
| Exportar/instalar a app por script | `APEX_EXPORT` / `APEX_APPLICATION_INSTALL` | SQLcl `apex export` |

Pré-requisitos que se repetem em vários packages:
- **Sessão APEX:** `APEX_WORKFLOW`, `APEX_HUMAN_TASK`, `APEX_EXEC` com REST Data Sources, `APEX_AUTOMATION`, `APEX_MAIL` fora de app (que precisa do workspace) e as funções pipelined de listas só funcionam com sessão/workspace definidos (`apex_session.create_session` ou `apex_util.set_workspace` em scripts).
- **Rede:** chamadas externas (`APEX_WEB_SERVICE`, REST Data Sources, `APEX_MAIL` via SMTP, impressão remota, IA) exigem ACL de rede concedida ao schema do APEX, exceto no Autonomous Database.
- **`CREATE JOB`:** workflows, human tasks e sincronização REST usam jobs do scheduler.

Fonte: [Oracle APEX API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/index.html), [Changed Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html)


## 02. APEX_WEB_SERVICE: chamar serviços REST e SOAP a partir de PL/SQL

### APEX_WEB_SERVICE: propósito, quando usar e quando não usar

`APEX_WEB_SERVICE` é o package para chamar serviços web externos (REST e SOAP) em qualquer ponto do APEX onde se escreve PL/SQL: processos de página, processos *On Demand* chamados por Ajax, validações, esquemas de autenticação, automations, jobs do `DBMS_SCHEDULER` ou um script no SQLcl. Ele cobre o ciclo inteiro de uma chamada HTTP:

- **Envio:** `MAKE_REST_REQUEST` (resposta em `CLOB`) e `MAKE_REST_REQUEST_B` (resposta em `BLOB`) para REST; `MAKE_REQUEST` (function que devolve `XMLTYPE`, ou procedure que grava numa collection) para SOAP.
- **Cabeçalhos e cookies:** globals `g_request_headers` e `g_request_cookies` (o que vai na requisição), `g_headers` e `g_response_cookies` (o que voltou), além de `SET_REQUEST_HEADERS`, `REMOVE_REQUEST_HEADER`, `CLEAR_REQUEST_HEADERS`, `CLEAR_REQUEST_COOKIES`, `GET_REQUEST_HEADER` e `SET_REQUEST_ECID_CONTEXT`.
- **Resultado:** `g_status_code` e `g_reason_phrase` são preenchidos depois de cada requisição (200 = OK, 400 = Bad Request etc.).
- **Autenticação:** usuário e senha (`p_username`/`p_password`/`p_scheme`), **Web Credentials** (`p_credential_static_id`, com `p_token_url` e `p_oauth_scope` nos fluxos OAuth2) e as rotinas OAuth `OAUTH_AUTHENTICATE`, `OAUTH_AUTHENTICATE_CREDENTIAL`, `OAUTH_GET_LAST_TOKEN` e `OAUTH_SET_TOKEN`.
- **Utilitários:** `BLOB2CLOBBASE64`/`CLOBBASE642BLOB` (base64 para binários em SOAP/JSON), `PARSE_XML`/`PARSE_XML_CLOB`/`PARSE_RESPONSE`/`PARSE_RESPONSE_CLOB` (XPath sobre respostas XML) e `APPEND_TO_MULTIPART`/`GENERATE_REQUEST_BODY` (corpo `multipart/form-data`).

**Quando usar:** chamadas pontuais e imperativas, ou seja, quando o código precisa decidir a URL, montar o corpo, ler o status e reagir (integrar com um ERP, consultar um CEP, enviar um arquivo, validar algo num serviço externo, obter um token). Também serve quando se precisa de um binário de resposta (PDF, imagem), via `MAKE_REST_REQUEST_B`.

**Quando não usar:** se o objetivo é exibir ou editar dados de um serviço REST em relatórios, formulários ou grids, o caminho declarativo do APEX é a REST Data Source (com cache e Data Synchronization; ver `APEX_REST_SOURCE_SYNC` neste documento). Para baixar arquivos *do* APEX *para o navegador* do usuário, o package certo é `APEX_HTTP`, não este.

**Pré-requisitos:**
- **Rede (ACL):** em bancos *on-premises*, os serviços de rede vêm desabilitados. O DBA precisa conceder privilégio `connect` via `DBMS_NETWORK_ACL_ADMIN` ao usuário dono do schema do APEX (`APEX_260100` na 26.1). Esse grant vale para a instância inteira; só é preciso conceder ao schema da aplicação quando ela usa `UTL_HTTP`/`UTL_SMTP` direto ou quando a Web Credential referencia uma *database credential* (ver caso adiante). No Oracle Autonomous AI Database isso não se aplica: o APEX já fala com a internet sem configuração.
- **HTTPS:** a chamada precisa de um wallet com os certificados. O wallet padrão é o configurado nas *instance settings*; `p_wallet_path`/`p_wallet_pwd` o sobrescrevem por chamada.
- **Contexto de workspace:** para usar Web Credentials fora de uma sessão APEX (SQLcl, job), o usuário de banco precisa estar mapeado a um workspace. Se estiver mapeado a vários, chame `APEX_UTIL.SET_WORKSPACE` ou `APEX_UTIL.SET_SECURITY_GROUP_ID` antes. Um usuário sem nenhum workspace só consegue usar o package se tiver a role `APEX_ADMINISTRATOR_ROLE`.

**Pegadinhas gerais:**
- Os globals são **variáveis de package**: valem para a sessão de banco e são compartilhados entre todas as chamadas feitas nela. Monte os headers logo antes de cada chamada (`SET_REQUEST_HEADERS` com `p_reset => true`, que é o padrão, ou `CLEAR_REQUEST_HEADERS`) para não herdar um `Authorization` ou `Content-Type` de uma chamada anterior.
- O `p_proxy_override` sobrescreve o proxy definido nos atributos da aplicação; o `p_wallet_path` sobrescreve o wallet da instância.
- O tempo limite padrão (`p_transfer_timeout`) é de **180 segundos** em todas as rotinas que fazem HTTP. Num processo de página, isso pode deixar o usuário esperando três minutos: reduza o valor em chamadas interativas.
- A doc 26.1 só fala em `g_status_code` e `g_reason_phrase` como forma de saber o resultado. Ela não diz que um 4xx/5xx gera exceção. Por isso, confira `g_status_code` explicitamente depois de toda chamada.

Fonte: [APEX_WEB_SERVICE](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WEB_SERVICE.html) · [About the APEX_WEB_SERVICE API](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/About-the-APEX_WEB_SERVICE-API.html) · [About Web Credentials and APEX_WEB_SERVICE](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/about-web-credentials-APEX_WEB_SERVICE.html) · [Enabling Network Services in Oracle Database](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/enabling-network-services.html)

### APEX_WEB_SERVICE: referência completa de procedures, functions, globals e tipos

| Nome | Tipo | O que faz |
|---|---|---|
| `header` | tipo (record) | Par `name varchar2(256)` / `value varchar2(32767)` de um cabeçalho HTTP |
| `header_table` | tipo (table of `header` index by binary_integer) | Lista de cabeçalhos; tipo de `g_headers` e `g_request_headers` |
| `t_multipart_parts` | tipo | Corpo `multipart/form-data` em construção, usado por `APPEND_TO_MULTIPART` e `GENERATE_REQUEST_BODY` (a página *Data Types* da 26.1 não detalha sua estrutura) |
| `g_request_headers` | global (`header_table`) | Cabeçalhos a enviar na próxima requisição |
| `g_request_cookies` | global (`sys.utl_http.cookie_table`) | Cookies a enviar na próxima requisição |
| `g_headers` | global (`header_table`) | Cabeçalhos recebidos na resposta |
| `g_response_cookies` | global (`sys.utl_http.cookie_table`) | Cookies recebidos na resposta |
| `g_status_code` | global (`pls_integer`) | Código HTTP da última resposta |
| `g_reason_phrase` | global (`varchar2(32767)`) | Texto do status da última resposta (ex.: `OK`, `Not Found`) |
| `APPEND_TO_MULTIPART` (Signature 1) | procedure | Acrescenta uma parte `BLOB` a um corpo multipart |
| `APPEND_TO_MULTIPART` (Signature 2) | procedure | Acrescenta uma parte `CLOB` a um corpo multipart |
| `BLOB2CLOBBASE64` | function | Converte `BLOB` em `CLOB` base64 |
| `CLEAR_REQUEST_COOKIES` | procedure | Limpa os cookies de requisição (nos globals do APEX e do `UTL_HTTP`) |
| `CLEAR_REQUEST_HEADERS` | procedure | Limpa `g_request_headers` |
| `CLOBBASE642BLOB` | function | Converte `CLOB` base64 em `BLOB` |
| `GENERATE_REQUEST_BODY` | function | Gera o `BLOB` `multipart/form-data` a partir de `t_multipart_parts` |
| `GET_REQUEST_HEADER` | function | Lê o valor de um cabeçalho de `g_request_headers` (nome sem distinção de caixa) |
| `MAKE_REQUEST` (Function Signature 1) | function | SOAP com usuário/senha; retorna `XMLTYPE` |
| `MAKE_REQUEST` (Function Signature 2) | function | SOAP com Web Credential; retorna `XMLTYPE` |
| `MAKE_REQUEST` (Procedure Signature 1) | procedure | SOAP com usuário/senha; grava a resposta numa collection |
| `MAKE_REQUEST` (Procedure Signature 2) | procedure | SOAP com Web Credential; grava a resposta numa collection |
| `MAKE_REST_REQUEST` | function | REST; retorna a resposta em `CLOB` |
| `MAKE_REST_REQUEST_B` | function | REST; retorna a resposta em `BLOB` |
| `OAUTH_AUTHENTICATE` (Signature 1) | procedure | Obtém token OAuth2 (Client Credentials) com client id/secret explícitos |
| `OAUTH_AUTHENTICATE` (Signature 2) **(Deprecated)** | procedure | Obtém token a partir de uma Web Credential; substituída por `OAUTH_AUTHENTICATE_CREDENTIAL` |
| `OAUTH_AUTHENTICATE_CREDENTIAL` | procedure | Obtém token OAuth2 a partir de uma Web Credential |
| `OAUTH_GET_LAST_TOKEN` | function | Devolve o último token obtido (NULL se expirou ou se nunca houve) |
| `OAUTH_SET_TOKEN` | procedure | Define manualmente o token usado nas próximas chamadas `MAKE_REST_REQUEST` |
| `PARSE_RESPONSE` | function | XPath sobre resposta SOAP guardada em collection; retorna `VARCHAR2` |
| `PARSE_RESPONSE_CLOB` | function | Idem, retornando `CLOB` |
| `PARSE_XML` | function | XPath sobre um `XMLTYPE`; retorna `VARCHAR2` |
| `PARSE_XML_CLOB` | function | Idem, retornando `CLOB` |
| `REMOVE_REQUEST_HEADER` | procedure | Remove um cabeçalho de `g_request_headers` (sem erro se não existir) |
| `SET_REQUEST_ECID_CONTEXT` | procedure | Adiciona/suprime o cabeçalho `ECID-Context`, sobrescrevendo o atributo *Pass ECID* da aplicação |
| `SET_REQUEST_HEADERS` | procedure | Define até 5 cabeçalhos de requisição numa só chamada |

Fonte: [APEX_WEB_SERVICE](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WEB_SERVICE.html) · [Data Types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WEB_SERVICE.Data-Types.html) · [Global Variables](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WEB_SERVICE.Global-Variables.html)

### APEX_WEB_SERVICE.MAKE_REST_REQUEST: chamar um serviço REST e receber a resposta em CLOB

Esta é a rotina mais usada do package. Ela envia uma requisição HTTP com o método escolhido e devolve o corpo da resposta como `CLOB`. O conteúdo enviado pode ser de três tipos: pares nome/valor (`p_parm_name`/`p_parm_value`), um corpo texto (`p_body`, ex.: JSON) ou um corpo binário (`p_body_blob`, ex.: um arquivo).

```sql
APEX_WEB_SERVICE.MAKE_REST_REQUEST (
    p_url                   IN  VARCHAR2,
    p_http_method           IN  VARCHAR2,
    p_username              IN  VARCHAR2 DEFAULT NULL,
    p_password              IN  VARCHAR2 DEFAULT NULL,
    p_scheme                IN  VARCHAR2 DEFAULT 'Basic',
    p_proxy_override        IN  VARCHAR2 DEFAULT NULL,
    p_transfer_timeout      IN  NUMBER   DEFAULT 180,
    p_body                  IN  CLOB     DEFAULT EMPTY_CLOB(),
    p_body_blob             IN  BLOB     DEFAULT EMPTY_BLOB(),
    p_parm_name             IN  apex_application_global.vc_arr2
                                    DEFAULT empty_vc_arr,
    p_parm_value            IN  apex_application_global.vc_arr2
                                    DEFAULT empty_vc_arr,
    p_wallet_path           IN  VARCHAR2 DEFAULT NULL,
    p_wallet_pwd            IN  VARCHAR2 DEFAULT NULL,
    p_https_host            IN  VARCHAR2 DEFAULT NULL,
    p_credential_static_id  IN  VARCHAR2 DEFAULT NULL,
    p_token_url             IN  VARCHAR2 DEFAULT NULL,
    p_oauth_scope           IN  VARCHAR2 DEFAULT NULL )
    RETURN CLOB;
```

| Parâmetro | Tipo / padrão | Significado |
|---|---|---|
| `p_url` | `VARCHAR2` (obrigatório) | Endpoint do serviço |
| `p_http_method` | `VARCHAR2` (obrigatório) | `PUT`, `POST`, `GET`, `HEAD` ou `DELETE` (são os métodos listados na doc) |
| `p_username` | `NULL` | Usuário, quando o serviço exige autenticação básica |
| `p_password` | `NULL` | Senha da autenticação básica |
| `p_scheme` | `'Basic'` | Esquema de autenticação: `Basic` (padrão), `AWS`, `Digest` ou `OAUTH_CLIENT_CRED`, conforme o que a versão do banco suportar |
| `p_proxy_override` | `NULL` | Proxy desta chamada; sobrescreve o proxy dos atributos da aplicação |
| `p_transfer_timeout` | `180` | Tempo máximo de espera pela resposta, em segundos |
| `p_body` | `EMPTY_CLOB()` | Corpo da requisição como texto (JSON, XML, form-urlencoded…) |
| `p_body_blob` | `EMPTY_BLOB()` | Corpo da requisição binário (ex.: upload de arquivo, corpo multipart) |
| `p_parm_name` | `empty_vc_arr` | Nomes dos parâmetros nome/valor (`apex_application_global.vc_arr2`) |
| `p_parm_value` | `empty_vc_arr` | Valores correspondentes, na mesma ordem |
| `p_wallet_path` | `NULL` | Caminho do wallet para HTTPS (ex.: `file:/usr/home/oracle/WALLETS`); sobrescreve o wallet das *instance settings* |
| `p_wallet_pwd` | `NULL` | Senha do wallet |
| `p_https_host` | `NULL` | Nome de host a comparar com o CN do certificado do servidor remoto |
| `p_credential_static_id` | `NULL` | Static ID da Web Credential (configurada em *Workspace Utilities*) |
| `p_token_url` | `NULL` | URL do servidor de token em fluxos baseados em token (OAuth2) |
| `p_oauth_scope` | `NULL` | Escopo OAuth desta chamada; o APEX usa ou solicita um token com esse escopo. Vários escopos separados por espaço |

**Retorno:** `CLOB` com o corpo da resposta. Depois da chamada, `g_status_code`, `g_reason_phrase`, `g_headers` e `g_response_cookies` ficam preenchidos.

**Comportamento e combinações de autenticação:**
- **Sem autenticação:** só `p_url` e `p_http_method`.
- **Básica explícita:** `p_username` + `p_password` (com `p_scheme => 'Basic'`, o padrão). Evite: a senha fica no código. Prefira uma Web Credential do tipo Basic.
- **Web Credential:** `p_credential_static_id`. Se a credencial for OAuth2 Client Credentials, informe também `p_token_url`. O APEX troca client id/secret por um access token e, quando o token expira, pede outro sozinho. A credencial também pode ser do tipo HTTP Header ou URL Query String (API key): o APEX injeta o segredo como cabeçalho ou parâmetro de URL e não o grava no debug.
- **Token já obtido:** chame `OAUTH_AUTHENTICATE`/`OAUTH_AUTHENTICATE_CREDENTIAL` ou `OAUTH_SET_TOKEN` antes; as próximas chamadas `MAKE_REST_REQUEST` usam esse token.

**Exemplo da doc (parâmetros nome/valor):**

```sql
DECLARE
    l_clob CLOB;
BEGIN
    l_clob := apex_web_service.make_rest_request(
        p_url         => 'http://us.music.yahewapis.com/video/v1/list/published/popular',
        p_http_method => 'GET',
        p_parm_name   => apex_string.string_to_table('appid:format'),
        p_parm_value  => apex_string.string_to_table('xyz:xml'));
END;
```

**Pegadinhas:**
- `p_parm_name` e `p_parm_value` são arrays paralelos do tipo `apex_application_global.vc_arr2`. Os exemplos oficiais os montam com `apex_string.string_to_table('a:b')`, que separa por `:` por padrão; um valor que contenha `:` quebra o par. Nesse caso, monte o array elemento a elemento.
- `p_body` e `p_body_blob` têm como padrão `EMPTY_CLOB()`/`EMPTY_BLOB()`, não `NULL`. Para enviar JSON, passe-o em `p_body` e defina o `Content-Type` com `SET_REQUEST_HEADERS` antes.
- Se a credencial tiver *Valid for URLs* e a `p_url` não começar por um deles, a chamada falha com `Credential is not allowed to be used for this URL endpoint` (ver caso adiante).
- A resposta pode ser grande: em processos Ajax, a doc a escreve com `htp.p` em blocos de 32000 caracteres lidos com `dbms_lob.read` (exemplo em "Invoking a RESTful-style Web Service").

Fonte: [MAKE_REST_REQUEST Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/MAKE_REST_REQUEST-Function.html) · [Invoking a RESTful-style Web Service](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/Invoking-a-RESTful-Style-Web-Service.html) · [Understanding Web Credentials](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-web-credentials.html)

### APEX_WEB_SERVICE.MAKE_REST_REQUEST_B: chamar um serviço REST e receber a resposta em BLOB

Tem os mesmos parâmetros e defaults de `MAKE_REST_REQUEST`. A única diferença é o retorno, que é `BLOB`. Use quando a resposta for binária (PDF, imagem, ZIP) ou quando não se quer conversão de charset no corpo recebido.

```sql
APEX_WEB_SERVICE.MAKE_REST_REQUEST_B (
    p_url                   IN  VARCHAR2,
    p_http_method           IN  VARCHAR2,
    p_username              IN  VARCHAR2 DEFAULT NULL,
    p_password              IN  VARCHAR2 DEFAULT NULL,
    p_scheme                IN  VARCHAR2 DEFAULT 'Basic',
    p_proxy_override        IN  VARCHAR2 DEFAULT NULL,
    p_transfer_timeout      IN  NUMBER   DEFAULT 180,
    p_body                  IN  CLOB     DEFAULT EMPTY_CLOB(),
    p_body_blob             IN  BLOB     DEFAULT EMPTY_BLOB(),
    p_parm_name             IN  apex_application_global.vc_arr2
                                         DEFAULT empty_vc_arr,
    p_parm_value            IN  apex_application_global.vc_arr2
                                         DEFAULT empty_vc_arr,
    p_wallet_path           IN  VARCHAR2 DEFAULT NULL,
    p_wallet_pwd            IN  VARCHAR2 DEFAULT NULL,
    p_https_host            IN  VARCHAR2 DEFAULT NULL,
    p_credential_static_id  IN  VARCHAR2 DEFAULT NULL,
    p_token_url             IN  VARCHAR2 DEFAULT NULL,
    p_oauth_scope           IN  VARCHAR2 DEFAULT NULL )
RETURN BLOB;
```

Os parâmetros têm o mesmo significado da tabela de `MAKE_REST_REQUEST`.

**Exemplo combinado: baixar um PDF de um serviço e entregá-lo ao navegador** (usa `APEX_HTTP.DOWNLOAD`, descrito neste documento):

```sql
DECLARE
    l_pdf BLOB;
BEGIN
    l_pdf := apex_web_service.make_rest_request_b(
                 p_url                  => 'https://api.example.com/relatorios/123/pdf',
                 p_http_method          => 'GET',
                 p_credential_static_id => 'API_RELATORIOS',
                 p_transfer_timeout     => 30 );

    IF apex_web_service.g_status_code = 200 THEN
        apex_http.download(
            p_blob         => l_pdf,
            p_content_type => 'application/pdf',
            p_filename     => 'relatorio-123.pdf' );
    ELSE
        raise_application_error(-20001,
            'Falha ao obter PDF: HTTP ' || apex_web_service.g_status_code
            || ' ' || apex_web_service.g_reason_phrase );
    END IF;
END;
```

Fonte: [MAKE_REST_REQUEST_B Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/MAKE_REST_REQUEST_B-Function.html) · [DOWNLOAD Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HTTP.DOWNLOAD-Procedure-Signature-1.html)

### APEX_WEB_SERVICE: globals de requisição e resposta (g_request_headers, g_headers, g_status_code, g_reason_phrase, cookies)

| Global | Tipo | Direção | Quando é preenchido |
|---|---|---|---|
| `g_request_headers` | `header_table` | envio | Por você (atribuição direta ou `SET_REQUEST_HEADERS`) antes da chamada |
| `g_request_cookies` | `sys.utl_http.cookie_table` | envio | Por você, antes da chamada |
| `g_headers` | `header_table` | resposta | Pelo APEX, se a resposta trouxer cabeçalhos |
| `g_response_cookies` | `sys.utl_http.cookie_table` | resposta | Pelo APEX, se a resposta trouxer cookies |
| `g_status_code` | `pls_integer` | resposta | Pelo APEX, após toda requisição |
| `g_reason_phrase` | `varchar2(32767)` | resposta | Pelo APEX, após toda requisição |

Esses globals valem para qualquer forma de chamada suportada pelo APEX: tanto as rotinas deste package quanto os processos declarativos do tipo Web Service. Ou seja, um processo PL/SQL anterior pode preparar cabeçalhos/cookies para um processo declarativo, e um processo posterior pode ler o que voltou.

**Exemplo da doc: guardar cookies e cabeçalhos da resposta em collections**

```sql
DECLARE
  secure varchar2(1);
BEGIN
  apex_collection.create_or_truncate_collection('P31_RESP_COOKIES');
  FOR i in 1 .. apex_web_service.g_response_cookies.count LOOP
    IF (apex_web_service.g_response_cookies(i).secure) THEN
      secure := 'Y';
    ELSE
      secure := 'N';
    END IF;
    apex_collection.add_member(p_collection_name => 'P31_RESP_COOKIES',
      p_c001 => apex_web_service.g_response_cookies(i).name,
      p_c002 => apex_web_service.g_response_cookies(i).value,
      p_c003 => apex_web_service.g_response_cookies(i).domain,
      p_c004 => apex_web_service.g_response_cookies(i).expire,
      p_c005 => apex_web_service.g_response_cookies(i).path,
      p_c006 => secure,
      p_c007 => apex_web_service.g_response_cookies(i).version );
  END LOOP;

  apex_collection.create_or_truncate_collection('P31_RESP_HEADERS');
  FOR i in 1 .. apex_web_service.g_headers.count LOOP
    apex_collection.add_member(p_collection_name => 'P31_RESP_HEADERS',
      p_c001 => apex_web_service.g_headers(i).name,
      p_c002 => apex_web_service.g_headers(i).value,
      p_c003 => apex_web_service.g_status_code);
  END LOOP;
END;
```

**Exemplo da doc: reenviar cookies e cabeçalhos guardados** (preenchendo os globals de requisição antes do processo que chama o serviço):

```sql
FOR c1 IN (select seq_id, c001, c002, c003, c004, c005, c006, c007
             from apex_collections
            where collection_name = 'P31_RESP_COOKIES') LOOP
  apex_web_service.g_request_cookies(c1.seq_id).name    := c1.c001;
  apex_web_service.g_request_cookies(c1.seq_id).value   := c1.c002;
  apex_web_service.g_request_cookies(c1.seq_id).domain  := c1.c003;
  apex_web_service.g_request_cookies(c1.seq_id).expire  := c1.c004;
  apex_web_service.g_request_cookies(c1.seq_id).path    := c1.c005;
  apex_web_service.g_request_cookies(c1.seq_id).secure  := (c1.c006 = 'Y');
  apex_web_service.g_request_cookies(c1.seq_id).version := c1.c007;
END LOOP;

FOR c1 IN (select seq_id, c001, c002
             from apex_collections
            where collection_name = 'P31_RESP_HEADERS') LOOP
  apex_web_service.g_request_headers(c1.seq_id).name  := c1.c001;
  apex_web_service.g_request_headers(c1.seq_id).value := c1.c002;
END LOOP;
```

**Pegadinhas:**
- `g_headers` é uma tabela indexada; para achar um cabeçalho de resposta (ex.: `Location`, `ETag`), percorra-a comparando `upper(name)`. `GET_REQUEST_HEADER` só lê os cabeçalhos de **requisição**.
- Um cookie de resposta tem os campos `name`, `value`, `domain`, `expire`, `path`, `secure` (BOOLEAN) e `version` (estrutura de `utl_http.cookie`).

Fonte: [Global Variables](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WEB_SERVICE.Global-Variables.html) · [Retrieving Cookies and HTTP Headers](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/Retrieving-Cookies-and-HTTP-Headers.html) · [Setting Cookies and HTTP Headers](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/Setting-Cookies-and-HTTP-Headers.html)

### APEX_WEB_SERVICE.SET_REQUEST_HEADERS: definir cabeçalhos HTTP para as próximas chamadas

Preenche `g_request_headers` para as próximas chamadas `MAKE_REQUEST` ou `MAKE_REST_REQUEST`, com até cinco pares por chamada.

```sql
APEX_WEB_SERVICE.SET_REQUEST_HEADERS (
    p_name_01            IN VARCHAR2,
    p_value_01           IN VARCHAR2,
    p_name_02            IN VARCHAR2 DEFAULT NULL,
    p_value_02           IN VARCHAR2 DEFAULT NULL,
    p_name_03            IN VARCHAR2 DEFAULT NULL,
    p_value_03           IN VARCHAR2 DEFAULT NULL,
    p_name_04            IN VARCHAR2 DEFAULT NULL,
    p_value_04           IN VARCHAR2 DEFAULT NULL,
    p_name_05            IN VARCHAR2 DEFAULT NULL,
    p_value_05           IN VARCHAR2 DEFAULT NULL,
    p_reset              IN BOOLEAN  DEFAULT TRUE,
    p_skip_if_exists     IN BOOLEAN  DEFAULT FALSE );
```

| Parâmetro | Padrão | Significado |
|---|---|---|
| `p_name_01` … `p_name_05` | 01 obrigatório; demais `NULL` | Nome do cabeçalho N |
| `p_value_01` … `p_value_05` | 01 obrigatório; demais `NULL` | Valor do cabeçalho N |
| `p_reset` | `TRUE` | Limpa o array de cabeçalhos antes de gravar |
| `p_skip_if_exists` | `FALSE` | Se `TRUE`, um cabeçalho que já existe com o mesmo nome **não** é sobrescrito |

```sql
-- Substitui todos os cabeçalhos atuais
begin
    apex_web_service.set_request_headers(
        p_name_01  => 'Content-Type',
        p_value_01 => 'application/json',
        p_name_02  => 'User-Agent',
        p_value_02 => 'APEX' );
end;

-- Acrescenta aos existentes, sem sobrescrever o que já estiver definido
begin
    apex_web_service.set_request_headers(
        p_name_01        => 'Content-Type',
        p_value_01       => 'application/json',
        p_name_02        => 'User-Agent',
        p_value_02       => 'APEX',
        p_reset          => false,
        p_skip_if_exists => true );
end;
```

**Pegadinha:** com o padrão `p_reset => true`, uma segunda chamada a `SET_REQUEST_HEADERS` apaga os cabeçalhos da primeira. Para somar cabeçalhos em etapas, use `p_reset => false`. Para mais de cinco cabeçalhos, faça várias chamadas com `p_reset => false` ou atribua direto em `g_request_headers(n)`.

Fonte: [SET_REQUEST_HEADERS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_REQUEST_HEADERS-Procedure.html)

### APEX_WEB_SERVICE: limpar, remover e ler cabeçalhos e cookies (CLEAR_REQUEST_HEADERS, REMOVE_REQUEST_HEADER, GET_REQUEST_HEADER, CLEAR_REQUEST_COOKIES)

```sql
APEX_WEB_SERVICE.CLEAR_REQUEST_HEADERS;              -- esvazia g_request_headers

APEX_WEB_SERVICE.REMOVE_REQUEST_HEADER (
    p_name  IN VARCHAR2 );                           -- remove um cabeçalho; sem erro se não existir

APEX_WEB_SERVICE.GET_REQUEST_HEADER (
    p_header_name   VARCHAR2 )
    RETURN VARCHAR2;                                 -- busca normaliza a caixa do nome

APEX_WEB_SERVICE.CLEAR_REQUEST_COOKIES;              -- limpa cookies no APEX_WEB_SERVICE e no UTL_HTTP
```

| Rotina | Detalhe |
|---|---|
| `CLEAR_REQUEST_HEADERS` | Sem parâmetros. Zera os cabeçalhos de requisição atuais |
| `REMOVE_REQUEST_HEADER` | `p_name`: nome do cabeçalho. **Cuidado:** pode reordenar as entradas de `g_request_headers`, então não guarde índices dela |
| `GET_REQUEST_HEADER` | `p_header_name`: nome procurado (a caixa é normalizada). Pode ser usada em SQL |
| `CLEAR_REQUEST_COOKIES` | Sem parâmetros. A próxima `MAKE_REST_REQUEST` sai sem cookies; limpa os globals do APEX e também os do `UTL_HTTP` |

```sql
BEGIN
    apex_web_service.remove_request_header(p_name => 'Metadata-Context');
    apex_web_service.clear_request_cookies;
END;

select apex_web_service.get_request_header('ECID-Context') from dual;
```

Fonte: [CLEAR_REQUEST_HEADERS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CLEAR_REQUEST_HEADERS-Procedure.html) · [REMOVE_REQUEST_HEADER Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/REMOVE_REQUEST_HEADER-Procedure.html) · [GET_REQUEST_HEADER Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_REQUEST_HEADER-Function.html) · [CLEAR_REQUEST_COOKIES Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CLEAR_REQUEST_COOKIES-Procedure.html)

### APEX_WEB_SERVICE.SET_REQUEST_ECID_CONTEXT: enviar ou suprimir o cabeçalho ECID-Context

O ECID (*Execution Context ID*) serve para correlacionar uma requisição do APEX com os logs do serviço chamado. Esta rotina coloca o cabeçalho `ECID-Context` em `g_request_headers` e, com isso, se sobrepõe à configuração de segurança *Pass ECID* da aplicação.

```sql
APEX_WEB_SERVICE.SET_REQUEST_ECID_CONTEXT (
    p_ecid  IN VARCHAR2 DEFAULT AUTO_ECID )
```

| Valor de `p_ecid` | Efeito |
|---|---|
| `AUTO_ECID` (padrão) | Adiciona um ECID determinado automaticamente |
| `NULL` | Não adiciona cabeçalho ECID (mesmo com *Pass ECID* ligado na aplicação) |
| Outro texto | Usa `substrb(p_ecid, 1, 64)` como ECID |

```sql
BEGIN
    apex_web_service.set_request_ecid_context;                      -- força ECID automático
    apex_web_service.set_request_ecid_context(p_ecid => 'my-123456'); -- ECID próprio
    apex_web_service.set_request_ecid_context(p_ecid => null);        -- suprime o cabeçalho
END;
```

Fonte: [SET_REQUEST_ECID_CONTEXT Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_REQUEST_ECID_CONTEXT-Procedure.html)

### APEX_WEB_SERVICE: tratar o status HTTP da resposta (g_status_code e g_reason_phrase)

Depois de cada requisição, o APEX grava em `g_status_code` o código numérico (200, 201, 204, 400, 401, 404, 500…) e em `g_reason_phrase` o texto correspondente. A doc não descreve exceção para respostas de erro HTTP, então o padrão seguro é sempre conferir o status antes de usar o corpo.

```sql
DECLARE
    l_resp CLOB;
BEGIN
    l_resp := apex_web_service.make_rest_request(
                  p_url              => 'https://api.example.com/v1/pedidos/42',
                  p_http_method      => 'GET',
                  p_transfer_timeout => 20 );

    CASE
      WHEN apex_web_service.g_status_code BETWEEN 200 AND 299 THEN
          NULL; -- sucesso: processar l_resp
      WHEN apex_web_service.g_status_code = 404 THEN
          apex_error.add_error(
              p_message          => 'Pedido não encontrado no sistema externo.',
              p_display_location => apex_error.c_inline_in_notification );
      WHEN apex_web_service.g_status_code IN (401, 403) THEN
          raise_application_error(-20010, 'Acesso negado pelo serviço externo ('
              || apex_web_service.g_status_code || ').');
      ELSE
          raise_application_error(-20011, 'Erro no serviço externo: HTTP '
              || apex_web_service.g_status_code || ' '
              || apex_web_service.g_reason_phrase);
    END CASE;
END;
```

**Dicas:**
- Falhas de rede, ACL ou wallet impedem que haja resposta HTTP. Nesse caso não existe status a ler e o problema surge como erro na própria chamada (ver os casos no fim desta seção). Trate as duas situações: exceção e status de erro.
- Muitos serviços devolvem detalhes do erro no corpo (JSON). Antes de tratar o erro, faça o parse do corpo para extrair a mensagem.

Fonte: [Global Variables](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WEB_SERVICE.Global-Variables.html) · [Retrieving Cookies and HTTP Headers](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/Retrieving-Cookies-and-HTTP-Headers.html)

### APEX_WEB_SERVICE: exemplo completo de GET JSON e parse com APEX_JSON ou JSON_TABLE

Padrão recomendado: autenticar com Web Credential, definir o `Accept`, conferir o status e fazer o parse do `CLOB`.

```sql
DECLARE
    l_resp  CLOB;
    l_count PLS_INTEGER;
BEGIN
    apex_web_service.set_request_headers(
        p_name_01  => 'Accept',
        p_value_01 => 'application/json' );

    l_resp := apex_web_service.make_rest_request(
                  p_url                  => 'https://api.example.com/v1/clientes',
                  p_http_method          => 'GET',
                  p_parm_name            => apex_string.string_to_table('status:limit'),
                  p_parm_value           => apex_string.string_to_table('ATIVO:50'),
                  p_credential_static_id => 'API_CLIENTES',
                  p_transfer_timeout     => 30 );

    IF apex_web_service.g_status_code <> 200 THEN
        raise_application_error(-20001, 'HTTP ' || apex_web_service.g_status_code
                                || ' ' || apex_web_service.g_reason_phrase);
    END IF;

    -- Opção 1: APEX_JSON
    apex_json.parse(l_resp);
    l_count := apex_json.get_count(p_path => 'items');
    FOR i IN 1 .. nvl(l_count, 0) LOOP
        sys.dbms_output.put_line(
            apex_json.get_varchar2(p_path => 'items[%d].nome', p0 => i));
    END LOOP;

    -- Opção 2: JSON_TABLE do SQL (melhor para gravar em tabela)
    INSERT INTO cliente_externo (id_externo, nome, email)
    SELECT jt.id, jt.nome, jt.email
      FROM json_table(l_resp, '$.items[*]'
             COLUMNS (id    NUMBER        PATH '$.id',
                      nome  VARCHAR2(200) PATH '$.nome',
                      email VARCHAR2(200) PATH '$.email')) jt;
END;
```

**Pegadinhas:**
- A doc 26.1 não detalha como `p_parm_name`/`p_parm_value` são codificados (query string ou corpo) em cada método. Se o serviço exigir um formato específico, monte a URL ou o corpo você mesmo e confira a requisição real no debug.
- `APEX_JSON` serve para navegar no JSON em PL/SQL; `JSON_TABLE` serve para projetar o JSON como linhas em SQL (por exemplo, num `INSERT ... SELECT`).

Fonte: [MAKE_REST_REQUEST Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/MAKE_REST_REQUEST-Function.html) · [SET_REQUEST_HEADERS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_REQUEST_HEADERS-Procedure.html)

### APEX_WEB_SERVICE: exemplo completo de POST/PUT JSON com cabeçalhos

```sql
DECLARE
    l_body CLOB;
    l_resp CLOB;
BEGIN
    -- 1) Montar o JSON (APEX_JSON em modo CLOB, ou JSON_OBJECT do SQL)
    SELECT json_object(
             'nome'  VALUE :P10_NOME,
             'email' VALUE :P10_EMAIL,
             'ativo' VALUE 'true' FORMAT JSON
             RETURNING CLOB)
      INTO l_body
      FROM dual;

    -- 2) Cabeçalhos (p_reset => true limpa restos de chamadas anteriores)
    apex_web_service.set_request_headers(
        p_name_01  => 'Content-Type',
        p_value_01 => 'application/json',
        p_name_02  => 'Accept',
        p_value_02 => 'application/json' );

    -- 3) Enviar
    l_resp := apex_web_service.make_rest_request(
                  p_url                  => 'https://api.example.com/v1/clientes',
                  p_http_method          => 'POST',   -- ou 'PUT' para atualizar
                  p_body                 => l_body,
                  p_credential_static_id => 'API_CLIENTES',
                  p_transfer_timeout     => 30 );

    -- 4) Conferir
    IF apex_web_service.g_status_code NOT IN (200, 201) THEN
        raise_application_error(-20002, 'Falha ao criar cliente: HTTP '
            || apex_web_service.g_status_code || ' - ' || dbms_lob.substr(l_resp, 2000, 1));
    END IF;

    :P10_ID_EXTERNO := json_value(l_resp, '$.id');
END;
```

**Pegadinhas:**
- Defina o `Content-Type` adequado ao corpo; serviços que o validam recusam a requisição sem ele, e o erro aparece em `g_status_code`.
- Não monte JSON concatenando strings com valores de itens: use `json_object` ou `apex_json`, que fazem o *escape*.

Fonte: [MAKE_REST_REQUEST Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/MAKE_REST_REQUEST-Function.html) · [SET_REQUEST_HEADERS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_REQUEST_HEADERS-Procedure.html)

### APEX_WEB_SERVICE.APPEND_TO_MULTIPART e GENERATE_REQUEST_BODY: montar um upload multipart/form-data

Para enviar arquivos e campos no mesmo formulário (`multipart/form-data`), crie uma variável `t_multipart_parts`, acrescente cada parte com `APPEND_TO_MULTIPART` (BLOB ou CLOB), gere o corpo binário com `GENERATE_REQUEST_BODY` e o envie em `p_body_blob`.

```sql
-- Signature 1: parte binária
APEX_WEB_SERVICE.APPEND_TO_MULTIPART (
    p_multipart     IN OUT NOCOPY t_multipart_parts,
    p_name          IN            VARCHAR2,
    p_filename      IN            VARCHAR2 DEFAULT NULL,
    p_content_type  IN            VARCHAR2 DEFAULT 'application/octet-stream',
    p_body_blob     IN            BLOB );

-- Signature 2: parte texto
APEX_WEB_SERVICE.APPEND_TO_MULTIPART (
    p_multipart     IN OUT NOCOPY t_multipart_parts,
    p_name          IN            VARCHAR2,
    p_filename      IN            VARCHAR2 DEFAULT NULL,
    p_content_type  IN            VARCHAR2 DEFAULT 'application/octet-stream',
    p_body          IN            CLOB );

APEX_WEB_SERVICE.GENERATE_REQUEST_BODY(
    p_multipart      IN t_multipart_parts,
    p_to_charset     IN VARCHAR2 DEFAULT wwv_flow_lang.get_db_charset )
    RETURN BLOB;
```

| Parâmetro | Significado |
|---|---|
| `p_multipart` | A coleção de partes (`t_multipart_parts`), alterada in-place |
| `p_name` | Nome do campo do formulário |
| `p_filename` | Nome do arquivo da parte, quando houver (faz a parte ser tratada como arquivo) |
| `p_content_type` | Tipo MIME da parte; padrão `application/octet-stream` |
| `p_body_blob` / `p_body` | Conteúdo da parte (BLOB na Signature 1, CLOB na Signature 2) |
| `p_to_charset` | (`GENERATE_REQUEST_BODY`) Charset de destino das partes CLOB; padrão é o charset do banco |

**Exemplo completo: enviar um arquivo do item File Browse mais um campo JSON**

```sql
DECLARE
    l_multipart apex_web_service.t_multipart_parts;
    l_file      BLOB;
    l_filename  VARCHAR2(400);
    l_mime      VARCHAR2(255);
    l_body      BLOB;
    l_resp      CLOB;
BEGIN
    SELECT blob_content, filename, mime_type
      INTO l_file, l_filename, l_mime
      FROM apex_application_temp_files
     WHERE name = :P20_ARQUIVO;

    apex_web_service.append_to_multipart(
        p_multipart    => l_multipart,
        p_name         => 'metadata',
        p_content_type => 'application/json',
        p_body         => to_clob('{"origem":"corlix"}') );

    apex_web_service.append_to_multipart(
        p_multipart    => l_multipart,
        p_name         => 'file',
        p_filename     => l_filename,
        p_content_type => l_mime,
        p_body_blob    => l_file );

    l_body := apex_web_service.generate_request_body(
                  p_multipart  => l_multipart,
                  p_to_charset => 'AL32UTF8' );

    l_resp := apex_web_service.make_rest_request(
                  p_url                  => 'https://api.example.com/v1/documentos',
                  p_http_method          => 'POST',
                  p_body_blob            => l_body,
                  p_credential_static_id => 'API_DOCS' );

    IF apex_web_service.g_status_code NOT IN (200, 201) THEN
        raise_application_error(-20003, 'Upload falhou: HTTP ' || apex_web_service.g_status_code);
    END IF;
END;
```

**Pegadinha (lacuna da doc):** a doc 26.1 não explica como fica o cabeçalho `Content-Type: multipart/form-data; boundary=…` nesse fluxo. Não sobrescreva o `Content-Type` sem necessidade e, se o servidor recusar o corpo, confira a requisição real no debug ou no log de Web Services do workspace.

Fonte: [APPEND_TO_MULTIPART Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WEB_SERVICE.APPEND_TO_MULTIPART-Procedure-1.html) · [APPEND_TO_MULTIPART Procedure Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WEB_SERVICE.APPEND_TO_MULTIPART-Procedure-2.html) · [GENERATE_REQUEST_BODY Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GENERATE_REQUEST_BODY-Function.html)

### APEX_WEB_SERVICE e Web Credentials: autenticar sem senha no código

Web Credentials guardam segredos criptografados no **workspace** (visíveis para todas as aplicações dele) e não podem ser lidos de volta em texto claro. Basta passar o *static ID* em `p_credential_static_id` de `MAKE_REST_REQUEST`, `MAKE_REST_REQUEST_B` ou `MAKE_REQUEST` (Signature 2).

**Tipos de autenticação de uma Web Credential (App Builder 26.1):**

| Tipo | O que o APEX faz na chamada |
|---|---|
| Basic Authentication | Envia usuário/senha em Base64 no cabeçalho `Authorization` |
| OAuth2 Client Credentials | Troca client id/secret por access token no `p_token_url`; renova sozinho quando expira |
| OCI Native Authentication | Assina a requisição para a API REST da OCI |
| HTTP Header | Envia o segredo como cabeçalho (nome da credencial = nome do cabeçalho); não vai para o debug |
| URL Query String | Acrescenta `?nome=valor` à URL (bom para API keys); proxies intermediários podem registrar o valor nos logs |
| OAuth2 Password Flow | Client id/secret mais usuário/senha (este par fica numa segunda credencial Basic) |
| Signed User Assertion | Como Client Credentials, mas também afirma a identidade do usuário com um JWT assinado (exige cliente OAuth *Trusted* no IdP) |
| User Assertion Signing Certificate | Certificado público e chave privada usados para assinar os JWTs de *Signed User Assertion* |
| Key Pair / Certificate Pair | Par de chaves; o Certificate Pair é para SAML |

Se o servidor de token devolver um *refresh token*, ele é usado para renovar o access token expirado.

**Fora de uma sessão APEX** (SQLcl, job), defina o workspace antes:

```sql
apex_util.set_workspace(p_workspace => 'MY_WORKSPACE');
-- ou, a partir do ID da aplicação
FOR c1 IN (select workspace_id from apex_applications where application_id = 100) LOOP
    apex_util.set_security_group_id(p_security_group_id => c1.workspace_id);
END LOOP;
```

**Valid for URLs:** limita a credencial a URLs que **comecem** com uma das entradas cadastradas. Isso evita mandar o segredo, por engano, para outro servidor. Vale configurar sempre (pela UI ou por `APEX_CREDENTIAL.SET_ALLOWED_URLS`).

**Export/import:** as credenciais usadas pela aplicação vão no arquivo de export. No import, se o workspace de destino já tiver uma credencial com o mesmo static ID, ela é reaproveitada; se não tiver, é criada a partir do arquivo. O *Prompt on Install* faz o instalador pedir os segredos.

Fonte: [About Web Credentials and APEX_WEB_SERVICE](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/about-web-credentials-APEX_WEB_SERVICE.html) · [Understanding Web Credentials](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-web-credentials.html)

### APEX_WEB_SERVICE.OAUTH_AUTHENTICATE_CREDENTIAL: obter um token OAuth2 a partir de uma Web Credential

Executa o fluxo OAuth com os dados de uma Web Credential e guarda o access token e sua validade num global do package. As chamadas `MAKE_REST_REQUEST` seguintes usam esse token. É a substituta recomendada da Signature 2 (obsoleta) de `OAUTH_AUTHENTICATE`.

```sql
APEX_WEB_SERVICE.OAUTH_AUTHENTICATE_CREDENTIAL (
    p_token_url              IN VARCHAR2,
    p_credential_static_id   IN VARCHAR2,
    p_proxy_override         IN VARCHAR2 DEFAULT NULL,
    p_transfer_timeout       IN NUMBER   DEFAULT 180,
    p_wallet_path            IN VARCHAR2 DEFAULT NULL,
    p_wallet_pwd             IN VARCHAR2 DEFAULT NULL,
    p_https_host             IN VARCHAR2 DEFAULT NULL,
    p_scope                  IN VARCHAR2 DEFAULT NULL );
```

| Parâmetro | Significado |
|---|---|
| `p_token_url` | Endpoint do serviço de token OAuth |
| `p_credential_static_id` | Web Credential com client id/secret |
| `p_proxy_override` | Proxy desta chamada |
| `p_transfer_timeout` | Tempo máximo de espera (s), padrão 180 |
| `p_wallet_path` / `p_wallet_pwd` | Wallet para HTTPS e sua senha |
| `p_https_host` | Host a comparar com o CN do certificado |
| `p_scope` | Escopo(s) OAuth, separados por espaço |

```sql
BEGIN
    apex_web_service.oauth_authenticate_credential(
        p_token_url            => 'https://api.example.com/ords/scott/oauth/token',
        p_credential_static_id => '[web-credential]');
END;
```

**Quando usar:** quando se quer o token separado da chamada (para reaproveitá-lo em várias chamadas, inspecioná-lo com `OAUTH_GET_LAST_TOKEN` ou mandá-lo para outro sistema). Se só for chamar o serviço, basta passar `p_credential_static_id` + `p_token_url` direto na `MAKE_REST_REQUEST`.

Fonte: [OAUTH_AUTHENTICATE_CREDENTIAL Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/OAUTH_AUTHENTICATE_CREDENTIAL.html)

### APEX_WEB_SERVICE.OAUTH_AUTHENTICATE: obter token OAuth2 Client Credentials (Signature 1 e Signature 2 obsoleta)

**Signature 1:** recebe client id e secret explícitos. Só o fluxo Client Credentials é suportado.

```sql
APEX_WEB_SERVICE.OAUTH_AUTHENTICATE (
    p_token_url         IN VARCHAR2,
    p_client_id         IN VARCHAR2,
    p_client_secret     IN VARCHAR2,
    p_flow_type         IN VARCHAR2 DEFAULT oauth_client_cred,
    p_proxy_override    IN VARCHAR2 DEFAULT NULL,
    p_transfer_timeout  IN NUMBER   DEFAULT 180,
    p_wallet_path       IN VARCHAR2 DEFAULT NULL,
    p_wallet_pwd        IN VARCHAR2 DEFAULT NULL,
    p_https_host        IN VARCHAR2 DEFAULT NULL,
    p_scope             IN VARCHAR2 DEFAULT NULL );
```

| Parâmetro | Significado |
|---|---|
| `p_token_url` | Endpoint do serviço de token |
| `p_client_id` / `p_client_secret` | Credenciais do cliente OAuth |
| `p_flow_type` | Tipo de fluxo; hoje só `OAUTH_CLIENT_CRED` |
| `p_proxy_override`, `p_transfer_timeout`, `p_wallet_path`, `p_wallet_pwd`, `p_https_host` | Como em `MAKE_REST_REQUEST` |
| `p_scope` | Escopo(s) solicitados ao provedor (a doc exemplifica `profile,email`) |

```sql
BEGIN
    apex_web_service.oauth_authenticate(
        p_token_url     => 'https://api.example.com/ords/scott/oauth/token',
        p_client_id     => '[client-id]',
        p_client_secret => '[client-secret]');
END;
```

**Signature 2 (Deprecated):** recebe `p_credential_static_id` em vez de id/secret. Foi marcada como obsoleta porque `p_wallet_path` e `p_wallet_pwd` não têm valor padrão, o que obriga a passá-los (mesmo `null`). Use `OAUTH_AUTHENTICATE_CREDENTIAL`.

```sql
APEX_WEB_SERVICE.OAUTH_AUTHENTICATE(
    p_token_url              IN VARCHAR2,
    p_credential_static_id   IN VARCHAR2,
    p_proxy_override         IN VARCHAR2 DEFAULT NULL,
    p_transfer_timeout       IN NUMBER   DEFAULT 180,
    p_wallet_path            IN VARCHAR2,
    p_wallet_pwd             IN VARCHAR2,
    p_https_host             IN VARCHAR2 DEFAULT NULL,
    p_scope                  IN VARCHAR2 DEFAULT NULL );
```

**Pegadinha:** a Signature 1 deixa o *client secret* no código ou num item. Em produção, prefira uma Web Credential OAuth2 Client Credentials com `OAUTH_AUTHENTICATE_CREDENTIAL` ou direto na `MAKE_REST_REQUEST`.

Fonte: [OAUTH_AUTHENTICATE Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/OAUTH_AUTHENTICATE-Procedure-Signature-1.html) · [OAUTH_AUTHENTICATE Procedure Signature 2 (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/OAUTH_AUTHENTICATE-Procedure-Signature-2.html)

### APEX_WEB_SERVICE.OAUTH_GET_LAST_TOKEN e OAUTH_SET_TOKEN: ler ou injetar o access token

```sql
FUNCTION OAUTH_GET_LAST_TOKEN RETURN VARCHAR2;

APEX_WEB_SERVICE.OAUTH_SET_TOKEN (
    p_token   IN VARCHAR2,
    p_expires IN DATE DEFAULT NULL );
```

- `OAUTH_GET_LAST_TOKEN` devolve o token recebido no último `OAUTH_AUTHENTICATE`. Retorna `NULL` se o token já expirou ou se `OAUTH_AUTHENTICATE` nunca foi chamado. Pode ser usada em SQL: `select apex_web_service.oauth_get_last_token from dual;`
- `OAUTH_SET_TOKEN` define o token das próximas chamadas `MAKE_REST_REQUEST` quando ele foi obtido por outro meio (código próprio, outro fluxo). `p_expires` é opcional; sem ele, o token fica sem validade.

```sql
BEGIN
    apex_web_service.oauth_set_token(p_token => '{oauth access token}');
END;
```

Fonte: [OAUTH_GET_LAST_TOKEN Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/OAUTH_GET_LAST_TOKEN-Function.html) · [OAUTH_SET_TOKEN Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/OAUTH_SET_TOKEN-Procedure.html)

### APEX_WEB_SERVICE: exemplo completo de OAuth2 Client Credentials (três formas)

```sql
-- Forma A (recomendada): Web Credential OAuth2 + token_url direto na chamada.
-- O APEX obtém, guarda e renova o token sozinho.
DECLARE
    l_resp CLOB;
BEGIN
    l_resp := apex_web_service.make_rest_request(
                  p_url                  => 'https://api.example.com/v1/recursos',
                  p_http_method          => 'GET',
                  p_credential_static_id => 'API_OAUTH',
                  p_token_url            => 'https://auth.example.com/oauth2/token',
                  p_oauth_scope          => 'leitura' );
END;

-- Forma B: obter o token antes e reaproveitá-lo em várias chamadas.
DECLARE
    l_resp1 CLOB;
    l_resp2 CLOB;
BEGIN
    apex_web_service.oauth_authenticate_credential(
        p_token_url            => 'https://auth.example.com/oauth2/token',
        p_credential_static_id => 'API_OAUTH',
        p_scope                => 'leitura' );

    IF apex_web_service.oauth_get_last_token IS NULL THEN
        raise_application_error(-20020, 'Não foi possível obter o token OAuth.');
    END IF;

    l_resp1 := apex_web_service.make_rest_request(
                   p_url => 'https://api.example.com/v1/a', p_http_method => 'GET');
    l_resp2 := apex_web_service.make_rest_request(
                   p_url => 'https://api.example.com/v1/b', p_http_method => 'GET');
END;

-- Forma C: token obtido por código próprio (ex.: outro provedor).
BEGIN
    apex_web_service.oauth_set_token(
        p_token   => :G_TOKEN_EXTERNO,
        p_expires => sysdate + 50/1440 );
    -- próximas make_rest_request usam esse token
END;
```

Fonte: [MAKE_REST_REQUEST Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/MAKE_REST_REQUEST-Function.html) · [OAUTH_AUTHENTICATE_CREDENTIAL Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/OAUTH_AUTHENTICATE_CREDENTIAL.html) · [OAUTH_GET_LAST_TOKEN Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/OAUTH_GET_LAST_TOKEN-Function.html) · [OAUTH_SET_TOKEN Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/OAUTH_SET_TOKEN-Procedure.html)

### APEX_WEB_SERVICE.MAKE_REQUEST: invocar um serviço SOAP (function com XMLTYPE e procedure com collection)

Para SOAP, você monta o envelope XML e o envia com `MAKE_REQUEST`. Há quatro variantes:

| Variante | Autenticação | Resposta |
|---|---|---|
| Function Signature 1 | `p_username`/`p_password`/`p_scheme` | Retorna `sys.xmltype` |
| Function Signature 2 | `p_credential_static_id` (obrigatório) + `p_token_url`, `p_oauth_scope` | Retorna `sys.xmltype` |
| Procedure Signature 1 | `p_username`/`p_password`/`p_scheme` | Grava na collection `p_collection_name` |
| Procedure Signature 2 | `p_credential_static_id` (obrigatório) + `p_token_url`, `p_oauth_scope` | Grava na collection `p_collection_name` |

```sql
-- Function Signature 1
APEX_WEB_SERVICE.MAKE_REQUEST (
    p_url                  IN VARCHAR2,
    p_action               IN VARCHAR2 DEFAULT NULL,
    p_version              IN VARCHAR2 DEFAULT '1.1',
    p_envelope             IN CLOB,
    p_username             IN VARCHAR2 DEFAULT NULL,
    p_password             IN VARCHAR2 DEFAULT NULL,
    p_scheme               IN VARCHAR2 DEFAULT 'Basic',
    p_proxy_override       IN VARCHAR2 DEFAULT NULL,
    p_transfer_timeout     IN NUMBER   DEFAULT 180,
    p_wallet_path          IN VARCHAR2 DEFAULT NULL,
    p_wallet_pwd           IN VARCHAR2 DEFAULT NULL,
    p_https_host           IN VARCHAR2 DEFAULT NULL )
RETURN sys.xmltype;

-- Function Signature 2
APEX_WEB_SERVICE.MAKE_REQUEST (
    p_url                  IN VARCHAR2,
    p_action               IN VARCHAR2 DEFAULT NULL,
    p_version              IN VARCHAR2 DEFAULT '1.1',
    p_envelope             IN CLOB,
    p_credential_static_id IN VARCHAR2,
    p_token_url            IN VARCHAR2 DEFAULT NULL,
    p_proxy_override       IN VARCHAR2 DEFAULT NULL,
    p_transfer_timeout     IN NUMBER   DEFAULT 180,
    p_wallet_path          IN VARCHAR2 DEFAULT NULL,
    p_wallet_pwd           IN VARCHAR2 DEFAULT NULL,
    p_https_host           IN VARCHAR2 DEFAULT NULL,
    p_oauth_scope          IN VARCHAR2 DEFAULT NULL )
    RETURN sys.xmltype;

-- Procedure Signature 1
APEX_WEB_SERVICE.MAKE_REQUEST (
    p_url               IN VARCHAR2,
    p_action            IN VARCHAR2 DEFAULT NULL,
    p_version           IN VARCHAR2 DEFAULT '1.1',
    p_collection_name   IN VARCHAR2 DEFAULT NULL,
    p_envelope          IN CLOB,
    p_username          IN VARCHAR2 DEFAULT NULL,
    p_password          IN VARCHAR2 DEFAULT NULL,
    p_scheme            IN VARCHAR2 DEFAULT 'Basic',
    p_proxy_override    IN VARCHAR2 DEFAULT NULL,
    p_transfer_timeout  IN NUMBER   DEFAULT 180,
    p_wallet_path       IN VARCHAR2 DEFAULT NULL,
    p_wallet_pwd        IN VARCHAR2 DEFAULT NULL,
    p_https_host        IN VARCHAR2 DEFAULT NULL );

-- Procedure Signature 2
APEX_WEB_SERVICE.MAKE_REQUEST (
    p_url                  IN VARCHAR2,
    p_action               IN VARCHAR2 DEFAULT NULL,
    p_version              IN VARCHAR2 DEFAULT '1.1',
    p_collection_name      IN VARCHAR2 DEFAULT NULL,
    p_envelope             IN CLOB,
    p_credential_static_id IN VARCHAR2,
    p_token_url            IN VARCHAR2 DEFAULT NULL,
    p_proxy_override       IN VARCHAR2 DEFAULT NULL,
    p_transfer_timeout     IN NUMBER   DEFAULT 180,
    p_wallet_path          IN VARCHAR2 DEFAULT NULL,
    p_wallet_pwd           IN VARCHAR2 DEFAULT NULL,
    p_https_host           IN VARCHAR2 DEFAULT NULL,
    p_oauth_scope          IN VARCHAR2 DEFAULT NULL );
```

| Parâmetro | Significado |
|---|---|
| `p_url` | Endpoint do serviço |
| `p_action` | SOAP Action da operação |
| `p_version` | Versão SOAP: `1.1` (padrão) ou `1.2` |
| `p_collection_name` | (procedures) Collection APEX onde a resposta é gravada |
| `p_envelope` | Envelope SOAP completo (CLOB) |
| `p_username` / `p_password` | Autenticação básica (Signatures 1) |
| `p_scheme` | `Basic` (padrão), `AWS`, `Digest`; na Function Signature 1 a doc lista também `OAUTH_CLIENT_CRED` |
| `p_credential_static_id` / `p_token_url` / `p_oauth_scope` | Web Credential, URL de token e escopo (Signatures 2) |
| `p_proxy_override`, `p_transfer_timeout`, `p_wallet_path`, `p_wallet_pwd`, `p_https_host` | Como em `MAKE_REST_REQUEST` |

**Function (XMLTYPE) + PARSE_XML:**

```sql
DECLARE
    l_envelope CLOB;
    l_xml      XMLTYPE;
    l_movie    VARCHAR2(4000);
BEGIN
    l_envelope := '<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
               xmlns:tns="http://www.ignyte.com/whatsshowing">
  <soap:Body>
    <tns:GetTheatersAndMovies>
      <tns:zipCode>43221</tns:zipCode>
      <tns:radius>5</tns:radius>
    </tns:GetTheatersAndMovies>
  </soap:Body>
</soap:Envelope>';

    l_xml := apex_web_service.make_request(
        p_url      => 'http://www.ignyte.com/webservices/ignyte.whatsshowing.webservice/moviefunctions.asmx',
        p_action   => 'http://www.ignyte.com/whatsshowing/GetTheatersAndMovies',
        p_envelope => l_envelope );

    l_movie := apex_web_service.parse_xml(
        p_xml   => l_xml,
        p_xpath => '//GetTheatersAndMoviesResponse/GetTheatersAndMoviesResult/Theater/Movies/Movie/Name[1]',
        p_ns    => 'xmlns="http://www.ignyte.com/whatsshowing"' );
END;
```

**Procedure (collection) com Web Credential:**

```sql
BEGIN
    apex_web_service.make_request(
        p_url                  => 'http://{host}:{port}/path/to/soap/service/',
        p_collection_name      => 'MY_RESPONSE_COLLECTION',
        p_action               => 'doSoapRequest',
        p_envelope             => '{SOAP envelope in XML format}',
        p_credential_static_id => 'My_Credentials',
        p_token_url            => 'http://{host}:{port}/ords/scott/oauth/token' );
END;
```

**Pegadinhas:**
- Nas Signatures 2, `p_credential_static_id` **não tem default**: a presença dele é o que faz o PL/SQL escolher essa sobrecarga.
- As tabelas de parâmetros das Signatures 2 escrevem `p_oath_scope`, mas a assinatura real é `p_oauth_scope`. Use o nome da assinatura na notação nomeada.
- Os exemplos oficiais trazem espaços no início de `p_url`, `p_action` e `p_xpath` (`' http://...'`). Isso é defeito de diagramação: não copie os espaços.

Fonte: [MAKE_REQUEST Function Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/MAKE_REQUEST-Function.html) · [MAKE_REQUEST Function Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/MAKE_REQUEST-Function-Signature-2.html) · [MAKE_REQUEST Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/MAKE_REQUEST-Procedure.html) · [MAKE_REQUEST Procedure Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/MAKE_REQUEST-Procedure-Signature-2.html) · [Invoking a SOAP-style Web Service](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/Invoking-a-SOAP-Style-Web-Service.html)

### APEX_WEB_SERVICE: extrair valores de respostas XML (PARSE_XML, PARSE_XML_CLOB, PARSE_RESPONSE, PARSE_RESPONSE_CLOB)

Use `PARSE_XML*` quando a resposta veio como `XMLTYPE` (function `MAKE_REQUEST`) e `PARSE_RESPONSE*` quando ela foi gravada numa collection (procedure `MAKE_REQUEST`). As variantes `_CLOB` servem para valores maiores que um `VARCHAR2`, como um binário em base64.

```sql
APEX_WEB_SERVICE.PARSE_XML (
    p_xml    IN XMLTYPE,
    p_xpath  IN VARCHAR2,
    p_ns     IN VARCHAR2 DEFAULT NULL )
RETURN VARCHAR2;

APEX_WEB_SERVICE.PARSE_XML_CLOB (
    p_xml    IN XMLTYPE,
    p_xpath  IN VARCHAR2,
    p_ns     IN VARCHAR2 DEFAULT NULL )
RETURN CLOB;

APEX_WEB_SERVICE.PARSE_RESPONSE (
    p_collection_name IN VARCHAR2,
    p_xpath           IN VARCHAR2,
    p_ns              IN VARCHAR2 DEFAULT NULL )
RETURN VARCHAR2;

APEX_WEB_SERVICE.PARSE_RESPONSE_CLOB (
    p_collection_name IN VARCHAR2,
    p_xpath           IN VARCHAR2,
    p_ns              IN VARCHAR2 DEFAULT NULL )
RETURN CLOB;
```

| Parâmetro | Significado |
|---|---|
| `p_xml` | Documento `XMLTYPE` a analisar |
| `p_collection_name` | Collection que guarda a resposta |
| `p_xpath` | Expressão XPath do nó desejado (use `/text()` para o texto) |
| `p_ns` | Declaração de namespace, ex.: `'xmlns:idc="http://www.stellent.com/CheckIn/"'` |

```sql
DECLARE
    l_msg VARCHAR2(4000);
BEGIN
    l_msg := apex_web_service.parse_response(
        p_collection_name => 'STELLENT_CHECKIN',
        p_xpath => '//idc:CheckInUniversalResponse/idc:CheckInUniversalResult/idc:StatusInfo/idc:statusMessage/text()',
        p_ns    => 'xmlns:idc="http://www.stellent.com/CheckIn/"');
END;
```

**Pegadinha:** quando o XML tem namespace padrão (`xmlns="..."`), o XPath só encontra os nós se você passar o mesmo namespace em `p_ns`; sem isso, o retorno vem `NULL`.

Fonte: [PARSE_XML Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PARSE_XML-Function.html) · [PARSE_XML_CLOB Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PARSE_XML_CLOB-Function.html) · [PARSE_RESPONSE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PARSE_RESPONSE-Function.html) · [PARSE_RESPONSE_CLOB Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PARSE_RESPONSE_CLOB-Function.html)

### APEX_WEB_SERVICE.BLOB2CLOBBASE64 e CLOBBASE642BLOB: converter binários de e para base64

```sql
APEX_WEB_SERVICE.BLOB2CLOBBASE64 (
    p_blob      IN BLOB,
    p_newlines  IN VARCHAR2 DEFAULT 'Y',
    p_padding   IN VARCHAR2 DEFAULT 'N' )
RETURN CLOB;

APEX_WEB_SERVICE.CLOBBASE642BLOB (
    p_clob IN CLOB)
RETURN BLOB;
```

| Parâmetro | Padrão | Significado |
|---|---|---|
| `p_blob` | — | Binário a codificar |
| `p_newlines` | `'Y'` | Se o base64 gerado tem quebras de linha |
| `p_padding` | `'N'` | Se completa com `=` até o tamanho ser múltiplo de 4 |
| `p_clob` | — | Texto base64 a decodificar |

**Uso típico:** mandar um arquivo dentro de um envelope SOAP ou de um JSON (`BLOB2CLOBBASE64`) e receber um binário dentro de um XML/JSON (`CLOBBASE642BLOB`).

```sql
DECLARE
    l_b64  CLOB;
    l_blob BLOB;
BEGIN
    SELECT blob_content INTO l_blob
      FROM apex_application_files
     WHERE name = :P1_FILE;

    -- base64 contínuo e com padding, para embutir num JSON
    l_b64 := apex_web_service.blob2clobbase64(
                 p_blob     => l_blob,
                 p_newlines => 'N',
                 p_padding  => 'Y');
END;
```

**Pegadinhas:**
- Com o padrão `p_newlines => 'Y'`, o texto sai com quebras de linha. Se o destino espera base64 contínuo (comum em JSON), use `'N'`.
- Com o padrão `p_padding => 'N'`, o texto sai sem `=` no final. Se o decodificador do destino exigir comprimento múltiplo de 4, use `'Y'`.

Fonte: [BLOB2CLOBBASE64 Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/BLOB2CLOBBASE64-Function.html) · [CLOBBASE642BLOB Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CLOBBASE642BLOB-Function.html) · [Invoking a SOAP-style Web Service](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/Invoking-a-SOAP-Style-Web-Service.html)

### Credential is not allowed to be used for this URL endpoint (APEX_WEB_SERVICE com Web Credential)

**Sintoma:** a chamada `MAKE_REST_REQUEST`/`MAKE_REQUEST` com `p_credential_static_id` falha com o erro de execução `Credential is not allowed to be used for this URL endpoint`.

**Causa:** a Web Credential tem *Valid for URLs* preenchido, e a URL chamada (ou a `p_token_url`) não começa com nenhuma das entradas. A comparação é por prefixo e considera o esquema: `http://` não casa com `https://`, e um subdomínio diferente também não casa.

**Correção:** acrescente o prefixo correto em *Valid for URLs* (Workspace Utilities > Web Credentials) ou via `APEX_CREDENTIAL.SET_ALLOWED_URLS`. Lembre que essa rotina exige o segredo de novo; sem ele, o segredo é apagado. Em credenciais OAuth, inclua também a URL do servidor de token.

**Prevenção:** cadastre os prefixos de todos os endpoints (API e token) junto com a criação da credencial.

Fonte: [Understanding Web Credentials](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-web-credentials.html) · [SET_ALLOWED_URLS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_ALLOWED_URLS-Procedure.html)

### APEX_WEB_SERVICE falha por rede/ACL ao chamar serviço externo (banco on-premises)

**Sintoma:** chamadas `APEX_WEB_SERVICE` (e também `APEX_MAIL`, impressão remota, LDAP) falham com erro de acesso à rede, sem chegar a ter status HTTP.

**Causa:** o banco vem com serviços de rede desabilitados, e o usuário dono do APEX (`APEX_260100`) não tem privilégio `connect` no host de destino. Quando a Web Credential referencia uma *database credential*, a requisição roda no contexto do **parsing schema** da aplicação, e aí o ACL precisa ser concedido a esse schema.

**Correção:** como `SYS`/`SYSDBA`, conceda o ACE:

```sql
BEGIN
    DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
        host => 'api.example.com',
        ace  => xs$ace_type(privilege_list => xs$name_list('connect'),
                            principal_name => APEX_APPLICATION.g_flow_schema_owner,
                            principal_type => xs_acl.ptype_db));
END;
/
```

(A doc mostra `host => '*'` para liberar qualquer host e `host => 'localhost'` para liberar só o próprio servidor.) Se o script falhar com `ORA-44416: Invalid ACL`, siga o procedimento de limpeza de ACL da doc de instalação e rode o grant de novo.

**Prevenção:** no Autonomous AI Database esse passo não é necessário. No *upgrade* do APEX, a configuração de rede da versão anterior é migrada automaticamente.

Fonte: [Enabling Network Services in Oracle Database](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/enabling-network-services.html) · [Understanding Web Credentials](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-web-credentials.html)

### APEX_WEB_SERVICE com Web Credential não funciona em job ou SQLcl (sem workspace)

**Sintoma:** fora de uma sessão APEX (job do Scheduler, SQLcl, trigger), a chamada com `p_credential_static_id` falha porque não acha a credencial, ou o package recusa o uso.

**Causa:** Web Credentials pertencem a um workspace. O usuário de banco precisa estar mapeado a um workspace e, se estiver mapeado a mais de um, o contexto tem de ser definido. Usuários sem nenhum workspace só podem usar o package com a role `APEX_ADMINISTRATOR_ROLE`.

**Correção:** antes da chamada, rode `apex_util.set_workspace(p_workspace => 'WKSP_X')` ou `apex_util.set_security_group_id(...)` com o `workspace_id` vindo de `apex_applications`.

Fonte: [About Web Credentials and APEX_WEB_SERVICE](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/about-web-credentials-APEX_WEB_SERVICE.html)


## 03. APEX_CREDENTIAL: criar e manter Web Credentials e tokens por PL/SQL

### APEX_CREDENTIAL: propósito, quando usar e quando não usar

`APEX_CREDENTIAL` é a API das **Web Credentials**, os segredos guardados criptografados no workspace e usados por REST Data Sources, REST Enabled SQL, autenticação social e chamadas `APEX_WEB_SERVICE` com `p_credential_static_id`. Com ela é possível:

- **Criar e remover** definições de credencial (`CREATE_CREDENTIAL`, `DROP_CREDENTIAL`).
- **Gravar segredos persistentes**, válidos para todas as sessões atuais e futuras (`SET_PERSISTENT_CREDENTIALS`, três sobrecargas: client id/secret, usuário/senha, chave/valor).
- **Gravar segredos só da sessão APEX atual** (`SET_SESSION_CREDENTIALS`, três sobrecargas), por exemplo quando o próprio usuário final informa o login de um sistema externo.
- **Gravar ou limpar tokens OAuth** (`SET_PERSISTENT_TOKEN`, `SET_SESSION_TOKEN`, `CLEAR_TOKENS`).
- **Ajustar atributos**: escopo OAuth (`SET_SCOPE`), URLs permitidas (`SET_ALLOWED_URLS`) e referência a uma *database credential* (`SET_DATABASE_CREDENTIAL`).

**Quando usar:** em scripts de instalação ou deploy (criar a credencial e injetar o segredo do ambiente sem passar pelo Builder), na rotação de segredos, em telas onde o usuário informa a própria credencial de um sistema externo (sessão) e em fluxos OAuth em que o token foi obtido por fora.

**Quando não usar:** para *ler* um segredo. As credenciais não podem ser recuperadas em texto claro. Também não é a ferramenta para autenticar usuários na aplicação; isso cabe aos *authentication schemes*.

**Pré-requisitos e regras gerais:**
- As credenciais pertencem ao **workspace** e são visíveis para todas as aplicações dele. Fora de uma sessão APEX, defina o workspace antes (`apex_util.set_workspace(p_workspace => '...')`), como fazem os exemplos oficiais de `CREATE_CREDENTIAL`, `DROP_CREDENTIAL` e `SET_DATABASE_CREDENTIAL`.
- Várias rotinas **apagam tokens já obtidos** ou **limpam segredos** como efeito colateral (ver cada uma). Leia as notas antes de chamar em produção.
- Ao exportar uma aplicação, as credenciais usadas vão no arquivo. No import, uma credencial com o mesmo static ID que já exista no workspace de destino é reaproveitada.

Fonte: [APEX_CREDENTIAL](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_CREDENTIAL.html) · [Understanding Web Credentials](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-web-credentials.html)

### APEX_CREDENTIAL: referência completa de procedures, constantes e tipos

| Nome | Tipo | O que faz |
|---|---|---|
| `CLEAR_TOKENS` | procedure | Apaga todos os tokens obtidos para a credencial (só faz sentido em OAuth) |
| `CREATE_CREDENTIAL` (Signature 1) | procedure | Cria uma credencial (tipos básicos) |
| `CREATE_CREDENTIAL` (Signature 2) | procedure | Cria uma credencial com opções extras: database credential, named scopes, credencial referenciada, método de requisição de token |
| `DROP_CREDENTIAL` | procedure | Remove a definição da credencial |
| `SET_ALLOWED_URLS` | procedure | Define as URLs (por prefixo) em que a credencial pode ser usada; exige o segredo de novo |
| `SET_DATABASE_CREDENTIAL` | procedure | Faz a credencial referenciar uma database credential (`DBMS_CREDENTIAL`) |
| `SET_PERSISTENT_CREDENTIALS` (Signature 1) | procedure | Grava client id/secret (OAuth) ou User OCID/chave privada/tenancy/fingerprint (OCI) de forma persistente |
| `SET_PERSISTENT_CREDENTIALS` (Signature 2) | procedure | Grava usuário/senha (Basic) de forma persistente |
| `SET_PERSISTENT_CREDENTIALS` (Signature 3) | procedure | Grava chave/valor (HTTP Header, cookie, query string) de forma persistente |
| `SET_PERSISTENT_TOKEN` | procedure | Grava um token (access/refresh/ID) de forma persistente |
| `SET_SCOPE` | procedure | Muda o escopo OAuth e os *named scopes*; apaga os tokens existentes |
| `SET_SESSION_CREDENTIALS` (Signature 1) | procedure | Usuário/senha só para a sessão APEX atual |
| `SET_SESSION_CREDENTIALS` (Signature 2) | procedure | Client id/secret (ou dados OCI) só para a sessão atual |
| `SET_SESSION_CREDENTIALS` (Signature 3) | procedure | Chave/valor só para a sessão atual |
| `SET_SESSION_TOKEN` | procedure | Token só para a sessão atual |
| `C_TYPE_BASIC` | constante | Tipo de autenticação: Basic |
| `C_TYPE_OAUTH_CLIENT_CRED` | constante | Tipo: OAuth2 Client Credentials |
| `C_TYPE_JWT` | constante | Tipo: JWT |
| `C_TYPE_OCI` | constante | Tipo: OCI Native Authentication |
| `C_TYPE_HTTP_HEADER` | constante | Tipo: HTTP Header |
| `C_TYPE_HTTP_QUERY_STRING` | constante | Tipo: URL Query String |
| `C_TYPE_OAUTH_PASSWORD` | constante | Tipo: OAuth2 Password Flow (só na Signature 2 de `CREATE_CREDENTIAL`) |
| `C_TYPE_SIGNED_USER_ASSERTION` | constante | Tipo: Signed User Assertion (só na Signature 2) |
| `C_TYPE_USER_ASSERT_CERTIFICATE` | constante | Tipo: User Assertion Signing Certificate (só na Signature 2) |
| `C_TOKEN_ACCESS` / `C_TOKEN_REFRESH` / `C_TOKEN_ID` | constantes (`t_token_type`) | Tipo de token para `SET_PERSISTENT_TOKEN`/`SET_SESSION_TOKEN` |
| `t_token_type` | tipo | Tipo do parâmetro `p_token_type` |
| `C_OAUTH_TOKEN_REQT_BODY`, `C_OAUTH_TOKEN_REQT_BASIC`, `C_OAUTH_TOKEN_REQT_CLIENT_ID`, `C_OAUTH_TOKEN_REQT_BASIC_CLID` | constantes | Valores de `p_oauth_token_request_type`: forma de autenticar a chamada ao token URL (a doc lista os nomes sem descrever cada um) |

Fonte: [APEX_CREDENTIAL](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_CREDENTIAL.html) · [CREATE_CREDENTIAL Procedure Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CREATE_CREDENTIAL-Procedure-Signature-2.html) · [SET_PERSISTENT_TOKEN Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_PERSISTENT_TOKEN-Procedure.html)

### APEX_CREDENTIAL.CREATE_CREDENTIAL: criar uma Web Credential por PL/SQL (Signatures 1 e 2)

Cria a *definição* da credencial: nome, static ID, tipo, escopo, URLs permitidas e comentário. O segredo **não** é informado aqui: em seguida, chame `SET_PERSISTENT_CREDENTIALS`, como mostram os próprios exemplos oficiais.

```sql
-- Signature 1
PROCEDURE CREATE_CREDENTIAL (
    p_credential_name       IN VARCHAR2,
    p_credential_static_id  IN VARCHAR2,
    p_authentication_type   IN VARCHAR2,
    p_scope                 IN VARCHAR2         DEFAULT NULL,
    p_allowed_urls          IN apex_t_varchar2  DEFAULT NULL,
    p_prompt_on_install     IN BOOLEAN          DEFAULT FALSE,
    p_credential_comment    IN VARCHAR2         DEFAULT NULL )

-- Signature 2
PROCEDURE CREATE_CREDENTIAL (
    p_credential_name           IN VARCHAR2,
    p_credential_static_id      IN VARCHAR2,
    p_authentication_type       IN VARCHAR2,
    p_scope                     IN VARCHAR2         DEFAULT NULL,
    p_allowed_urls              IN apex_t_varchar2  DEFAULT NULL,
    p_prompt_on_install         IN BOOLEAN          DEFAULT FALSE,
    p_credential_comment        IN VARCHAR2         DEFAULT NULL,
    --
    p_db_credential_name        IN VARCHAR2         DEFAULT NULL,
    p_db_credential_is_instance IN BOOLEAN          DEFAULT NULL,
    p_named_scopes              IN VARCHAR2         DEFAULT NULL,
    p_referenced_static_id      IN VARCHAR2         DEFAULT NULL,
    p_oauth_token_request_type  IN VARCHAR2         DEFAULT NULL );
```

| Parâmetro | Sig. | Significado |
|---|---|---|
| `p_credential_name` | 1, 2 | Nome de exibição |
| `p_credential_static_id` | 1, 2 | Static ID, usado em `p_credential_static_id` das outras APIs |
| `p_authentication_type` | 1, 2 | Sig. 1: `C_TYPE_BASIC`, `C_TYPE_OAUTH_CLIENT_CRED`, `C_TYPE_JWT`, `C_TYPE_OCI`, `C_TYPE_HTTP_HEADER`, `C_TYPE_HTTP_QUERY_STRING`. Sig. 2 acrescenta `C_TYPE_OAUTH_PASSWORD`, `C_TYPE_SIGNED_USER_ASSERTION`, `C_TYPE_USER_ASSERT_CERTIFICATE` |
| `p_scope` | 1, 2 | Escopo OAuth 2.0 das requisições de token |
| `p_allowed_urls` | 1, 2 | URLs (`apex_t_varchar2`) em que a credencial pode ser usada |
| `p_prompt_on_install` | 1, 2 | Se o instalador deve pedir esta credencial ao importar a app em outra instância |
| `p_credential_comment` | 1, 2 | Comentário |
| `p_db_credential_name` | 2 | Database credential referenciada (o segredo passa a ficar no banco) |
| `p_db_credential_is_instance` | 2 | Se a database credential está disponível no nível da instância; só com o parâmetro de instância `INSTANCE_DBMS_CREDENTIAL_ENABLED` ligado |
| `p_named_scopes` | 2 | Lista JSON de *named scopes* (sem descrição nesta página; o formato está em `SET_SCOPE`) |
| `p_referenced_static_id` | 2 | Outra credencial referenciada. Só para `C_TYPE_OAUTH_PASSWORD` (referencia uma `c_type_basic`) e `C_TYPE_SIGNED_USER_ASSERTION` (referencia uma `c_type_user_assert_certificate`) |
| `p_oauth_token_request_type` | 2 | Método de autenticação na chamada ao token URL: `C_OAUTH_TOKEN_REQT_BODY`, `C_OAUTH_TOKEN_REQT_BASIC`, `C_OAUTH_TOKEN_REQT_CLIENT_ID`, `C_OAUTH_TOKEN_REQT_BASIC_CLID` |

**Exemplo (doc): credencial OAuth2 Client Credentials com segredo persistente**

```sql
BEGIN
    apex_util.set_workspace(p_workspace => 'MY_WORKSPACE');

    apex_credential.create_credential (
        p_credential_name      => 'OAuth Login',
        p_credential_static_id => 'OAUTH_LOGIN',
        p_authentication_type  => apex_credential.c_type_oauth_client_cred,
        p_scope                => 'email',
        p_allowed_urls         => apex_t_varchar2(
                                      'https://tokenserver.mycompany.com/oauth2/token',
                                      'https://www.oracle.com' ),
        p_prompt_on_install    => false,
        p_credential_comment   => 'Credential for OAuth Login' );

    apex_credential.set_persistent_credentials (
        p_credential_static_id => 'OAUTH_LOGIN',
        p_client_id            => 'dnkjq237o8832ndj98098-..',
        p_client_secret        => '<client_secret>' );
END;
```

**Exemplo combinado: OAuth2 Password Flow** (a credencial Basic guarda usuário/senha; a OAuth referencia a Basic pela Signature 2):

```sql
BEGIN
    apex_util.set_workspace(p_workspace => 'MY_WORKSPACE');

    apex_credential.create_credential(
        p_credential_name      => 'ERP Usuario',
        p_credential_static_id => 'ERP_USER',
        p_authentication_type  => apex_credential.c_type_basic );
    apex_credential.set_persistent_credentials(
        p_credential_static_id => 'ERP_USER',
        p_username             => 'integracao',
        p_password             => '***' );

    apex_credential.create_credential(
        p_credential_name      => 'ERP OAuth',
        p_credential_static_id => 'ERP_OAUTH',
        p_authentication_type  => apex_credential.c_type_oauth_password,
        p_referenced_static_id => 'ERP_USER',
        p_allowed_urls         => apex_t_varchar2('https://erp.example.com/') );
    apex_credential.set_persistent_credentials(
        p_credential_static_id => 'ERP_OAUTH',
        p_client_id            => '...',
        p_client_secret        => '***' );
END;
```

**Pegadinhas:**
- Sem `p_allowed_urls`, a credencial pode ser mandada para qualquer URL. Preencha-o sempre, incluindo o token URL.
- Ao usar uma database credential (`p_db_credential_name`), o *Valid for URLs* é desabilitado (o APEX não tem acesso ao segredo) e as requisições rodam no contexto do parsing schema, que então precisa do ACL de rede. Esse recurso exige Oracle Database 26ai ou Autonomous Database 19c ou posterior e vale para os tipos Basic, OAuth2 Client Credentials e Signed User Assertion.

Fonte: [CREATE_CREDENTIAL Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CREATE_CREDENTIAL-Procedure-Signature-1.html) · [CREATE_CREDENTIAL Procedure Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CREATE_CREDENTIAL-Procedure-Signature-2.html) · [Understanding Web Credentials](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-web-credentials.html)

### APEX_CREDENTIAL.SET_PERSISTENT_CREDENTIALS: gravar o segredo de forma persistente (Signatures 1, 2 e 3)

Grava os atributos da credencial para além da sessão atual, ou seja, para todas as sessões atuais e futuras. Há uma sobrecarga para cada família de tipo.

```sql
-- Signature 1: OAuth2 Client Credentials ou OCI
PROCEDURE SET_PERSISTENT_CREDENTIALS (
    p_credential_static_id  IN VARCHAR2,
    p_client_id             IN VARCHAR2,
    p_client_secret         IN VARCHAR2,
    p_namespace             IN VARCHAR2 DEFAULT NULL,
    p_fingerprint           IN VARCHAR2 DEFAULT NULL );

-- Signature 2: Basic
PROCEDURE SET_PERSISTENT_CREDENTIALS (
    p_credential_static_id  IN VARCHAR2,
    p_username              IN VARCHAR2,
    p_password              IN VARCHAR2 );

-- Signature 3: chave/valor (HTTP Header, cookie)
APEX_CREDENTIAL.SET_PERSISTENT_CREDENTIALS (
    p_credential_static_id  IN VARCHAR2,
    p_key                   IN VARCHAR2,
    p_value                 IN VARCHAR2 )
```

| Parâmetro | Sig. | OAuth | OCI |
|---|---|---|---|
| `p_client_id` | 1 | Client ID | User OCID |
| `p_client_secret` | 1 | Client Secret | Private Key |
| `p_namespace` | 1 | — | Tenancy OCID |
| `p_fingerprint` | 1 | — | Public Key Fingerprint |
| `p_username` / `p_password` | 2 | Usuário e senha (Basic) | |
| `p_key` / `p_value` | 3 | Nome (ex.: cabeçalho HTTP ou cookie) e valor | |

**Comportamento:** a Signature 1 **apaga** os tokens de acesso, refresh e ID já guardados para a credencial. Assim, a troca de client secret força a obtenção de um token novo.

```sql
-- OAuth
BEGIN
    apex_credential.set_persistent_credentials (
        p_credential_static_id => 'OAuth Login',
        p_client_id            => 'dnkjq237o8832ndj98098-..',
        p_client_secret        => '<client_secret>' );
END;

-- OCI
BEGIN
    apex_credential.set_persistent_credentials (
        p_credential_static_id => 'OCI Login',
        p_client_id            => 'ocid1.user.oc1...',
        p_client_secret        => 'MIIEowIBAAKCAQEAsjhTVL...',
        p_namespace            => 'ocid1.tenancy.oc1...',
        p_fingerprint          => 'ff:ff:ee:00:...' );
END;

-- Basic
BEGIN
    apex_credential.set_persistent_credentials (
        p_credential_static_id => 'Login',
        p_username             => 'scott',
        p_password             => 'tiger' );
END;

-- API key em cabeçalho
BEGIN
    apex_credential.set_persistent_credentials (
        p_credential_static_id => 'my_API_key',
        p_key                  => 'api_key',
        p_value                => 'lsjkgjw4908902ru9fj879q367891hdaw' );
END;
```

**Pegadinhas:**
- No exemplo oficial da Signature 2, falta o apóstrofo de fechamento em `'tiger`. A versão acima está corrigida.
- Não deixe o segredo literal em código versionado. Num script de instalação, receba-o por substituição de variável do SQLcl ou use *Prompt on Install*.

Fonte: [SET_PERSISTENT_CREDENTIALS Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_PERSISTENT_CREDENTIAL-Procedure-Signature-1.html) · [SET_PERSISTENT_CREDENTIALS Procedure Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_PERSISTENT_CREDENTIAL-Procedure-Signature-2.html) · [SET_PERSISTENT_CREDENTIALS Procedure Signature 3](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_CREDENTIAL.SET_PERSISTENT_CREDENTIALS-Procedure-Signature-3.html)

### APEX_CREDENTIAL.SET_SESSION_CREDENTIALS: segredo válido só na sessão APEX atual (Signatures 1, 2 e 3)

Mesmos formatos de `SET_PERSISTENT_CREDENTIALS`, mas o valor vale apenas para a sessão APEX corrente. O caso típico é o usuário final informar as próprias credenciais de um sistema externo (Basic). Assim, cada usuário chama o serviço com a sua identidade, e nada fica gravado para os demais.

```sql
-- Signature 1: Basic
APEX_CREDENTIAL.SET_SESSION_CREDENTIALS (
    p_credential_static_id  IN VARCHAR2,
    p_username              IN VARCHAR2,
    p_password              IN VARCHAR2 );

-- Signature 2: OAuth2 Client Credentials / OCI
APEX_CREDENTIAL.SET_SESSION_CREDENTIALS (
    p_credential_static_id  IN VARCHAR2,
    p_client_id             IN VARCHAR2,
    p_client_secret         IN VARCHAR2,
    p_namespace             IN VARCHAR2 DEFAULT NULL,
    p_fingerprint           IN VARCHAR2 DEFAULT NULL );

-- Signature 3: chave/valor (HTTP Header ou Query String)
APEX_CREDENTIAL.SET_SESSION_CREDENTIALS (
    p_credential_static_id IN VARCHAR2,
    p_key                  IN VARCHAR2,
    p_value                IN VARCHAR2 );
```

**Exemplo combinado: o usuário digita login e senha do sistema externo, e a chamada usa a credencial da sessão**

```sql
-- Processo "Conectar" (After Submit)
BEGIN
    apex_credential.set_session_credentials(
        p_credential_static_id => 'ERP_USUARIO',
        p_username             => :P30_LOGIN,
        p_password             => :P30_SENHA );
    :P30_SENHA := null; -- não deixar a senha no session state
END;

-- Em outro processo da mesma sessão
DECLARE
    l_resp CLOB;
BEGIN
    l_resp := apex_web_service.make_rest_request(
                  p_url                  => 'https://erp.example.com/api/meus-dados',
                  p_http_method          => 'GET',
                  p_credential_static_id => 'ERP_USUARIO' );
END;
```

**Pegadinha:** o exemplo oficial da Signature 1 tem o mesmo apóstrofo faltando em `'tiger`. O da Signature 3 diz "for the current APEX session persistently", o que é contraditório: o que vale é o título da rotina (sessão atual).

Fonte: [SET_SESSION_CREDENTIALS Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_SESSION_CREDENTIALS-Procedure-Signature-1.html) · [SET_SESSION_CREDENTIALS Procedure Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_SESSION_CREDENTIALS-Procedure-Signature-2.html) · [SET_SESSION_CREDENTIALS Procedure Signature 3](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_SESSION_CREDENTIALS-Procedure-Signature-3.html)

### APEX_CREDENTIAL.SET_PERSISTENT_TOKEN e SET_SESSION_TOKEN: gravar tokens OAuth obtidos por fora

Gravam um token (access, refresh ou ID) dentro da credencial, criptografado. `SET_PERSISTENT_TOKEN` vale além da sessão; `SET_SESSION_TOKEN` só pode ser usado pela sessão APEX atual. **Nenhuma das duas** grava client id ou client secret.

```sql
APEX_CREDENTIAL.SET_PERSISTENT_TOKEN (
    p_credential_static_id  IN   VARCHAR2,
    p_token_type            IN   t_token_type,
    p_token_value           IN   VARCHAR2,
    p_token_expires         IN   DATE,
    p_token_scope           IN   VARCHAR2         DEFAULT NULL );

APEX_CREDENTIAL.SET_SESSION_TOKEN (
    p_credential_static_id  IN VARCHAR2,
    p_token_type            IN t_token_type,
    p_token_value           IN VARCHAR2,
    p_token_expires         IN DATE,
    p_token_scope           IN VARCHAR2         DEFAULT NULL );
```

| Parâmetro | Significado |
|---|---|
| `p_credential_static_id` | Static ID da credencial |
| `p_token_type` | `apex_credential.c_token_access`, `c_token_refresh` ou `c_token_id` |
| `p_token_value` | Valor do token |
| `p_token_expires` | Data de expiração (obrigatória) |
| `p_token_scope` | Escopo(s) do token, separados por espaço; se omitido, vale o escopo padrão da credencial |

```sql
begin
    apex_credential.set_persistent_token (
        p_credential_static_id => 'OAuth Login',
        p_token_type           => apex_credential.c_token_access,
        p_token_value          => '<token>',
        p_token_expires        => to_date('2023-10-31', 'YYYY-MM-DD'),
        p_token_scope          => 'profile email' );
end;
```

**Quando usar:** quando o token vem de um fluxo que o APEX não executa sozinho (por exemplo, devolvido por outro sistema). Gravar um `c_token_refresh` deixa o APEX renovar o access token quando ele expirar, pois a doc de Web Credentials diz que o refresh token emitido pelo servidor é usado para isso.

Fonte: [SET_PERSISTENT_TOKEN Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_PERSISTENT_TOKEN-Procedure.html) · [SET_SESSION_TOKEN Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_SESSION_TOKEN-Procedure.html) · [Understanding Web Credentials](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-web-credentials.html)

### APEX_CREDENTIAL.CLEAR_TOKENS: forçar a obtenção de um novo token OAuth

```sql
PROCEDURE CLEAR_TOKENS( p_credential_static_id IN VARCHAR2 );
```

Apaga todos os tokens obtidos para a credencial e só faz sentido em fluxos OAuth. Use quando o servidor revogou o token, quando um token ficou com escopo errado ou após uma troca de permissões no provedor: a próxima chamada pede um token novo.

```sql
BEGIN
    apex_credential.clear_tokens(p_credential_static_id => 'OAuth Login');
END;
```

Fonte: [CLEAR_TOKENS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CLEAR_TOKENS-Procedure.html)

### APEX_CREDENTIAL.SET_SCOPE: alterar o escopo OAuth e os named scopes da credencial

```sql
APEX_CREDENTIAL.SET_SCOPE (
    p_credential_static_id      IN VARCHAR2,
    p_scope                     IN VARCHAR2,
    p_named_scopes              IN VARCHAR2 DEFAULT NULL );
```

| Parâmetro | Significado |
|---|---|
| `p_credential_static_id` | Static ID |
| `p_scope` | Novo escopo |
| `p_named_scopes` | Array JSON `[{"name":"sales","value":"fusion-x-sls-scope"}, …]`. `NULL` mantém a lista atual, `[]` a esvazia e um array preenchido a substitui por inteiro (não há *merge*). Limite de 32K, pois o parâmetro é `VARCHAR2` |

Quando quem chama especifica um *named scope*, o APEX usa o valor correspondente da lista. **Todos os tokens existentes da credencial são apagados** ao chamar `SET_SCOPE`.

```sql
declare
    l_named_scopes varchar2(32767) := '[ {"name":"sales", "value":"fusion-x-sls-scope"}'
                                   || ' ,{"name":"hr",    "value":"fusion-x-hr-scope" } ]';
begin
    apex_credential.set_scope (
        p_credential_static_id => 'OAuth_Login',
        p_scope                => 'hr',
        p_named_scopes         => l_named_scopes );
end;
```

Fonte: [SET_SCOPE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_CREDENTIAL.SET_SCOPE-Procedure.html)

### APEX_CREDENTIAL.SET_ALLOWED_URLS: restringir em que URLs a credencial pode ser usada

```sql
PROCEDURE SET_ALLOWED_URLS (
    p_credential_static_id  IN VARCHAR2,
    p_allowed_urls          IN apex_t_varchar2,
    p_client_secret         IN VARCHAR2 );
```

A credencial só é usada numa requisição cuja URL **comece com** uma das entradas. Com `https://www.oracle.com` e `https://apex.oracle.com/ords/` cadastrados:

| URL da requisição | Permitida? |
|---|---|
| `https://www.oracle.com/myrest/service` | sim |
| `https://apex.oracle.com/ords/secret/workspace` | sim |
| `https://web.oracle.com` | não (outro host) |
| `https://apex.oracle.com/apex/workspace` | não (outro caminho) |
| `http://www.oracle.com/` | não (outro esquema) |

**Regra de segurança:** é obrigatório passar o segredo (Client Secret, Password ou Private Key) junto. Se ele for omitido ou vier `NULL`, **o segredo é apagado**.

```sql
BEGIN
  apex_credential.set_allowed_urls (
    p_credential_static_id => 'OAuth Login',
    p_allowed_urls         => apex_t_varchar2(
                                'https://tokenserver.example.com/oauth2/token',
                                'https://www.oracle.com' ),
    p_client_secret        => '<client_secret>' );
END;
```

Fonte: [SET_ALLOWED_URLS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_ALLOWED_URLS-Procedure.html) · [Understanding Web Credentials](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-web-credentials.html)

### APEX_CREDENTIAL.SET_DATABASE_CREDENTIAL: guardar o segredo numa database credential (DBMS_CREDENTIAL)

```sql
APEX_CREDENTIAL.SET_DATABASE_CREDENTIAL (
    p_credential_static_id      IN VARCHAR2,
    p_db_credential_name        IN VARCHAR2,
    p_db_credential_is_instance IN BOOLEAN DEFAULT FALSE )
```

Faz a Web Credential referenciar uma database credential (mantida com `DBMS_CREDENTIAL` ou `DBMS_CLOUD`). Assim, o segredo fica no banco, fora do APEX.

**Efeitos colaterais:** apaga client IDs, client secrets, todos os tokens e o atributo *Valid for URLs*. Se o banco não suportar database credentials em requisições HTTP e a credencial ainda não referenciava uma, a procedure gera erro.

| Parâmetro | Significado |
|---|---|
| `p_db_credential_name` | Nome da database credential |
| `p_db_credential_is_instance` | `TRUE` se ela estiver disponível no nível da instância (exige `INSTANCE_DBMS_CREDENTIAL_ENABLED` = `Y`; a credencial precisa ser acessível ao schema `APEX_NNNNNN`) |

```sql
BEGIN
    apex_util.set_workspace(p_workspace => 'MY_WORKSPACE');
    apex_credential.set_database_credential (
        p_credential_static_id => 'OAUTH_LOGIN',
        p_db_credential_name   => 'USE_THIS_DB_CREDENTIAL' );
END;
```

**Pegadinha:** com database credential, as requisições HTTP rodam no contexto do **parsing schema** da aplicação, não no do engine do APEX. O ACL de rede (`DBMS_NETWORK_ACL_ADMIN`) precisa então ser concedido a esse schema. O recurso exige Oracle Database 26ai ou Autonomous Database 19c ou posterior.

Fonte: [SET_DATABASE_CREDENTIAL Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_DATABASE_CREDENTIAL-Procedure.html) · [Understanding Web Credentials](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-web-credentials.html)

### APEX_CREDENTIAL.DROP_CREDENTIAL: remover uma Web Credential

```sql
APEX_CREDENTIAL.DROP_CREDENTIAL (
    p_credential_static_id  IN VARCHAR2 )
```

```sql
BEGIN
   apex_util.set_workspace(p_workspace => 'MY_WORKSPACE');
   apex_credential.drop_credential(p_credential_static_id => 'OAUTH_LOGIN');
END;
```

**Pegadinha:** a credencial é do workspace. Removê-la quebra todas as aplicações e REST Data Sources que a usam. Antes, confira o uso no relatório *Utilization* (App Builder > Workspace Utilities > Web Credentials > Utilization, ou Shared Components > Workspace Objects > Credentials), que lista credencial, tipo de componente, aplicação e componente, e mostra as não usadas no final.

Fonte: [DROP_CREDENTIAL Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/DROP_CREDENTIAL-Procedure.html) · [Viewing Credential Utilization](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/viewing-credential-utilization.html)

### Segredo da Web Credential sumiu depois de SET_ALLOWED_URLS ou SET_DATABASE_CREDENTIAL (APEX_CREDENTIAL)

**Sintoma:** depois de ajustar as URLs permitidas ou a database credential, as chamadas que usam a credencial passam a falhar na autenticação (401, ou token não obtido).

**Causa:** `SET_ALLOWED_URLS` apaga o segredo quando `p_client_secret` vem `NULL` ou é omitido. `SET_DATABASE_CREDENTIAL` apaga client id/secret, tokens e *Valid for URLs*. `SET_PERSISTENT_CREDENTIALS` (Signature 1) e `SET_SCOPE` apagam os tokens, o que é esperado e se resolve sozinho num fluxo Client Credentials.

**Correção:** chame `SET_PERSISTENT_CREDENTIALS` de novo com o segredo, ou repita `SET_ALLOWED_URLS` passando `p_client_secret`.

**Prevenção:** em scripts de manutenção, sempre regrave o segredo na mesma transação lógica em que muda URLs ou referências.

Fonte: [SET_ALLOWED_URLS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_ALLOWED_URLS-Procedure.html) · [SET_DATABASE_CREDENTIAL Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_DATABASE_CREDENTIAL-Procedure.html) · [SET_SCOPE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_CREDENTIAL.SET_SCOPE-Procedure.html)


## 04. APEX_HTTP: enviar arquivos (BLOB/CLOB) do banco para o navegador

### APEX_HTTP: propósito, quando usar e quando não usar

`APEX_HTTP` tem uma única finalidade: **fazer o download de um arquivo para o cliente**, ou seja, mandar um `BLOB` ou `CLOB` como resposta HTTP para o navegador do usuário, como anexo ou para exibição inline. Ele substitui o código manual com `owa_util.mime_header`, `htp.p` e `wpg_docload`.

**Quando usar:** num processo *Before Header* ou *After Submit* (ou num processo *On Demand* acionado por um link) que entrega um PDF gerado, uma imagem guardada em tabela, um CSV montado em `CLOB` ou um arquivo enviado pelo usuário e guardado em `apex_application_temp_files`.

**Quando não usar:** para *chamar* um serviço externo, use `APEX_WEB_SERVICE`. Para arquivos estáticos da aplicação (CSS/JS/imagens), use *Static Application Files*. Não chame no meio de uma renderização de página que você queira concluir: o download encerra o processamento.

**Comportamento importante (vale para as duas assinaturas):**
- **Limpa todo o conteúdo já escrito no buffer HTP** antes de enviar o arquivo.
- **Chama `APEX_APPLICATION.STOP_APEX_ENGINE`** depois do download. Por isso, o código e os processos após a chamada não rodam. Esse encerramento é feito com a exceção interna `APEX_APPLICATION.E_STOP_APEX_ENGINE`: se a chamada estiver dentro de um bloco com `WHEN OTHERS` que não a relance, a parada é engolida (ver o caso abaixo).

Fonte: [APEX_HTTP](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HTTP.html) · [DOWNLOAD Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HTTP.DOWNLOAD-Procedure-Signature-1.html)

### APEX_HTTP: referência completa de procedures

| Nome | Tipo | O que faz |
|---|---|---|
| `DOWNLOAD` (Signature 1) | procedure | Envia um `BLOB` ao cliente |
| `DOWNLOAD` (Signature 2) | procedure | Envia um `CLOB` ao cliente |

Fonte: [APEX_HTTP](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HTTP.html)

### APEX_HTTP.DOWNLOAD: baixar um BLOB ou CLOB no navegador (Signatures 1 e 2)

```sql
-- Signature 1: binário
APEX_HTTP.DOWNLOAD (
    p_blob              IN OUT NOCOPY   BLOB,
    p_content_type      IN              VARCHAR2,
    p_filename          IN              VARCHAR2     DEFAULT NULL,
    p_is_inline         IN              BOOLEAN      DEFAULT FALSE )

-- Signature 2: texto
APEX_HTTP.DOWNLOAD (
    p_clob              IN OUT NOCOPY   CLOB,
    p_content_type      IN              VARCHAR2,
    p_filename          IN              VARCHAR2     DEFAULT NULL,
    p_is_inline         IN              BOOLEAN      DEFAULT FALSE )
```

| Parâmetro | Padrão | Significado |
|---|---|---|
| `p_blob` / `p_clob` | — | Conteúdo a enviar (`IN OUT NOCOPY`: passe uma **variável**, não uma expressão nem um literal) |
| `p_content_type` | — | Tipo MIME (ex.: `application/pdf`, `text/csv`, `image/png`) |
| `p_filename` | `NULL` | Nome do arquivo sugerido ao navegador |
| `p_is_inline` | `FALSE` | `FALSE`: o navegador abre o diálogo de salvar arquivo. `TRUE`: exibe o conteúdo dentro da janela |

**Exemplo (doc): baixar um arquivo enviado por um item File Browse**

```sql
DECLARE
    l_file         blob;
    l_content_type varchar2(4000);
    l_filename     varchar2(4000);
BEGIN
    SELECT blob_content, mime_type, filename
      INTO l_file, l_content_type, l_filename
      FROM apex_application_temp_files
     WHERE name = :P1_FILE;

    apex_http.download(
        p_blob         => l_file,
        p_content_type => l_content_type,
        p_filename     => l_filename );
END;
```

**Exemplo (doc): baixar um texto**

```sql
DECLARE
    l_text clob;
BEGIN
    l_text := 'Hello World';
    apex_http.download(
        p_clob         => l_text,
        p_content_type => 'text/plain',
        p_filename     => 'hello.txt' );
END;
```

**Exemplo combinado: exibir inline uma imagem guardada em tabela, com filtro por empresa**

```sql
-- Processo On Demand / Before Header de uma página só de download
DECLARE
    l_foto BLOB;
    l_mime VARCHAR2(255);
BEGIN
    SELECT foto, foto_mime
      INTO l_foto, l_mime
      FROM colaborador
     WHERE id_colaborador = :P50_ID
       AND id_empresa     = :G_ID_EMPRESA;

    apex_http.download(
        p_blob         => l_foto,
        p_content_type => l_mime,
        p_is_inline    => true );
END;
```

**Pegadinhas:**
- Como `p_blob`/`p_clob` são `IN OUT NOCOPY`, um literal (`p_clob => 'abc'`) não compila: atribua a uma variável antes.
- Nada depois de `DOWNLOAD` é executado (`STOP_APEX_ENGINE`). Faça logs e auditoria **antes** da chamada.
- Num botão que faz *submit*, a página não é redesenhada depois do download. Se a tela precisar continuar utilizável, dispare o download por um link para uma página/processo dedicado.

Fonte: [DOWNLOAD Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HTTP.DOWNLOAD-Procedure-Signature-1.html) · [DOWNLOAD Procedure Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HTTP.DOWNLOAD-Procedure-Signature-2.html)

### Arquivo baixado vem corrompido ou com HTML da página junto (APEX_HTTP.DOWNLOAD)

**Sintoma:** o download vem com HTML da página misturado, a página continua a renderizar depois do download ou um erro aparece em seguida.

**Causa:** `APEX_HTTP.DOWNLOAD` limpa o buffer HTP e encerra o engine com `APEX_APPLICATION.STOP_APEX_ENGINE`. Se a chamada estiver dentro de um `EXCEPTION WHEN OTHERS` que não relança a exceção, o encerramento é engolido e o APEX segue processando, escrevendo mais conteúdo na resposta.

**Correção:** não envolva `apex_http.download` em `WHEN OTHERS` genérico. Se precisar de tratamento, relance a exceção de parada do engine (`WHEN apex_application.e_stop_apex_engine THEN RAISE;`) antes do `WHEN OTHERS`.

**Prevenção:** coloque o download como último passo do processo e faça validações e logs antes dele.

Fonte: [DOWNLOAD Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HTTP.DOWNLOAD-Procedure-Signature-1.html) · [DOWNLOAD Procedure Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HTTP.DOWNLOAD-Procedure-Signature-2.html) · [STOP_APEX_ENGINE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/STOP_APEX_ENGINE-Procedure.html)


## 05. APEX_JWT: gerar, decodificar e validar JSON Web Tokens (HS256)

### APEX_JWT: propósito, quando usar e quando não usar

`APEX_JWT` trabalha com **JSON Web Tokens** (RFC 7519): strings seguras para URL com três partes separadas por `.`, que são *header* (indica o algoritmo da assinatura), *payload* (as *claims*) e *signature*. O package oferece:

- `ENCODE`: monta um token com as claims padrão (`iss`, `sub`, `aud`, `nbf`, `iat`, `exp`, `jti`) e claims extras, e opcionalmente o assina com HS256.
- `DECODE`: separa um token nas três partes (record `t_token`) e, se receber uma chave, confere a assinatura.
- `VALIDATE`: confere `iss`, `aud` e as datas (`exp`, `nbf`, `iat`) com uma tolerância.

**Quando usar:** para emitir tokens curtos e assinados com segredo compartilhado, que outro sistema seu vai validar (ex.: link assinado para um serviço ORDS ou para um parceiro que compartilha a chave). Também para ler as claims de um ID token OpenID já recebido e checar `aud`/`iss`/validade.

**Quando não usar:**
- **Tokens assinados com chave assimétrica (RS256 etc.) não são suportados.** O package só assina e verifica **HS256** (chave simétrica). Se um token recebido de um provedor externo vier assinado com RS256 ou outro algoritmo assimétrico, `APEX_JWT` não consegue verificar a assinatura dele. Para login social, use os *authentication schemes* do APEX.
- Também não serve para criptografar o conteúdo. O payload é apenas codificado em base64 e qualquer um pode lê-lo, então não coloque segredos nas claims.

**Pré-requisito:** a assinatura HS256 exige Oracle Database 12c ou superior.

Fonte: [APEX_JWT](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_JWT.html)

### APEX_JWT: referência completa de functions, procedures e tipos

| Nome | Tipo | O que faz |
|---|---|---|
| `t_token` | tipo (record) | Partes decodificadas: `header`, `payload`, `signature` (cada uma `VARCHAR2(32767)`) |
| `ENCODE` | function | Gera o token (`VARCHAR2`), com assinatura HS256 opcional |
| `DECODE` | function | Decodifica o token em `t_token`; verifica a assinatura se receber chave |
| `VALIDATE` | procedure | Valida `iss`, `aud`, `exp`, `nbf`, `iat`; gera `VALUE_ERROR` se falhar |

```sql
type t_token is record (
    header      VARCHAR2(32767),   -- cabeçalho JOSE (parâmetros criptográficos)
    payload     VARCHAR2(32767),   -- claims afirmadas pelo token
    signature   VARCHAR2(32767) ); -- assinatura de header + payload
```

Fonte: [t_token Record](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/T_TOKEN.html) · [APEX_JWT](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_JWT.html)

### APEX_JWT.ENCODE: gerar um JWT com claims e assinatura HS256

```sql
FUNCTION ENCODE (
     p_iss           IN VARCHAR2                 DEFAULT NULL,
     p_sub           IN VARCHAR2                 DEFAULT NULL,
     p_aud           IN VARCHAR2                 DEFAULT NULL,
     p_nbf_ts        IN timestamp with time zone DEFAULT NULL,
     p_iat_ts        IN timestamp with time zone DEFAULT SYSTIMESTAMP,
     p_exp_sec       IN PLS_INTEGER              DEFAULT NULL,
     p_jti           IN VARCHAR2                 DEFAULT NULL,
     p_other_claims  IN VARCHAR2                 DEFAULT NULL,
     p_signature_key IN RAW                      DEFAULT NULL )
     RETURN VARCHAR2
```

| Parâmetro | Claim | Significado |
|---|---|---|
| `p_iss` | `iss` | Emissor |
| `p_sub` | `sub` | Assunto (normalmente o usuário) |
| `p_aud` | `aud` | Destinatário |
| `p_nbf_ts` | `nbf` | Não válido antes deste instante |
| `p_iat_ts` | `iat` | Emitido em (padrão `SYSTIMESTAMP`) |
| `p_exp_sec` | `exp` | Validade **em segundos**, contada a partir de `nbf`, ou de `iat`, ou da hora atual |
| `p_jti` | `jti` | Identificador único do token |
| `p_other_claims` | — | JSON **cru** com claims adicionais, sem as chaves externas: `'"nome": "valor", "x": 1'` |
| `p_signature_key` | — | Chave MAC (`RAW`). Se não for nula, adiciona assinatura HS256 (requer 12c+); outros algoritmos não são suportados |

**Retorno:** `VARCHAR2` com o token codificado.

**Exemplo (baseado na doc): token de 5 minutos com claims extras**

```sql
DECLARE
    l_jwt varchar2(32767);
BEGIN
    l_jwt := apex_jwt.encode (
                 p_iss           => 'Example Issuer',
                 p_sub           => 'Example User',
                 p_aud           => 'Example JWT Recipient',
                 p_exp_sec       => 60*5,
                 p_other_claims  => '"name1": ' || apex_json.stringify('value1') ||
                                    ',"name2": ' || apex_json.stringify('value2'),
                 p_signature_key => utl_raw.cast_to_raw('segredo-compartilhado-longo') );
    sys.dbms_output.put_line(l_jwt);
END;
```

**Pegadinhas:**
- `p_other_claims` é concatenado ao JSON das claims. Use `apex_json.stringify` em cada valor para fazer o *escape* correto, como no exemplo oficial.
- `p_signature_key` é `RAW`. Converta o segredo texto com `utl_raw.cast_to_raw`; quem valida precisa usar exatamente os mesmos bytes.
- Sem `p_signature_key`, o token sai **sem assinatura** e qualquer pessoa pode forjá-lo.

Fonte: [ENCODE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ENCODE.html)

### APEX_JWT.DECODE: decodificar um JWT e verificar a assinatura

```sql
APEX_JWT.DECODE (
    p_value         IN VARCHAR2,
    p_signature_key IN RAW      DEFAULT NULL )
RETURN t_token;
```

| Parâmetro | Significado |
|---|---|
| `p_value` | Token bruto: três partes base64 (header, payload, signature) separadas por `.` |
| `p_signature_key` | Se não for nulo, verifica a assinatura com esta chave e o algoritmo indicado no header. São suportados `HS256` (12c+) e `none` |

**Retorno:** `t_token`. **Erros:** `VALUE_ERROR` (token inválido) e `WWV_FLOW_CRYPTO.UNSUPPORTED_FUNCTION` (assinado com algoritmo não suportado, ex.: RS256).

**Exemplo (doc): listar as claims do header e do payload com APEX_JSON**

```sql
declare
    l_token apex_jwt.t_token;
    l_keys  apex_t_varchar2;
begin
    l_token := apex_jwt.decode (
        p_value => '<jwt_assinado: header.payload.assinatura>' );

    apex_json.parse(l_token.header);
    l_keys := apex_json.get_members('.');
    for i in 1 .. l_keys.count loop
        sys.dbms_output.put_line(l_keys(i)||'='||apex_json.get_varchar2(l_keys(i)));
    end loop;   -- alg=HS256, typ=JWT

    apex_json.parse(l_token.payload);
    l_keys := apex_json.get_members('.');
    for i in 1 .. l_keys.count loop
        sys.dbms_output.put_line(l_keys(i)||'='||apex_json.get_varchar2(l_keys(i)));
    end loop;   -- loggedInAs=admin, iat=1422779638
end;
```

**Pegadinha de segurança:** sem `p_signature_key`, o `DECODE` **não verifica a assinatura**, só separa as partes. Para confiar num token que você mesmo emitiu, passe a chave no `DECODE` e depois chame `VALIDATE`. `VALIDATE` não recebe chave e confere apenas claims e datas.

Fonte: [DECODE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/DECODE.html)

### APEX_JWT.VALIDATE: conferir emissor, destinatário e validade de um JWT

```sql
APEX_JWT.VALIDATE (
     p_token          IN t_token,
     p_iss            IN VARCHAR2    DEFAULT NULL,
     p_aud            IN VARCHAR2    DEFAULT NULL,
     p_leeway_seconds IN PLS_INTEGER DEFAULT 0 );
```

| Parâmetro | Significado |
|---|---|
| `p_token` | Token já decodificado (`t_token`) |
| `p_iss` | Se não for nulo, exige `iss` = `p_iss` |
| `p_aud` | Se não for nulo, exige que o `aud` único seja igual a `p_aud`. Se `aud` for um array, exige `azp` (Authorized Party, extensão OpenID) = `p_aud` |
| `p_leeway_seconds` | Tolerância em segundos ao comparar `exp`, `nbf` e `iat` (diferença de relógio entre servidores) |

**Erro:** `VALUE_ERROR` quando a validação falha; o motivo aparece no **debug log**.

**Exemplo completo: emitir e depois validar um token próprio**

```sql
DECLARE
    c_key   constant raw(64) := utl_raw.cast_to_raw('segredo-compartilhado-longo');
    l_jwt   varchar2(32767);
    l_token apex_jwt.t_token;
BEGIN
    l_jwt := apex_jwt.encode(
                 p_iss           => 'corlix-hub',
                 p_aud           => 'servico-relatorios',
                 p_sub           => :APP_USER,
                 p_exp_sec       => 300,
                 p_signature_key => c_key );

    -- do lado que recebe:
    l_token := apex_jwt.decode(p_value => l_jwt, p_signature_key => c_key);  -- assinatura
    apex_jwt.validate(p_token          => l_token,
                      p_iss            => 'corlix-hub',
                      p_aud            => 'servico-relatorios',
                      p_leeway_seconds => 30);                                -- claims e datas
    apex_json.parse(l_token.payload);
    sys.dbms_output.put_line('Usuário: ' || apex_json.get_varchar2('sub'));
EXCEPTION
    WHEN value_error THEN
        raise_application_error(-20030, 'Token inválido ou expirado.');
END;
```

Fonte: [VALIDATE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/VALIDATE.html) · [DECODE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/DECODE.html) · [ENCODE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ENCODE.html)

### WWV_FLOW_CRYPTO.UNSUPPORTED_FUNCTION ao decodificar um JWT (APEX_JWT.DECODE)

**Sintoma:** `APEX_JWT.DECODE` com `p_signature_key` gera `WWV_FLOW_CRYPTO.UNSUPPORTED_FUNCTION`.

**Causa:** o token foi assinado com um algoritmo diferente de HS256 (ex.: RS256). O `APEX_JWT` só suporta HS256 e `none`.

**Correção:** para tokens RS256, não é possível verificar a assinatura com `APEX_JWT`. Use o fluxo declarativo de autenticação (Social Sign-In) do APEX ou valide o token no componente que o emitiu. O `DECODE` sem chave ainda permite ler as claims, mas sem nenhuma garantia de autenticidade.

Fonte: [DECODE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/DECODE.html) · [APEX_JWT](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_JWT.html)

### VALUE_ERROR em APEX_JWT.VALIDATE com token aparentemente correto

**Sintoma:** `APEX_JWT.VALIDATE` gera `VALUE_ERROR` para um token recém-emitido.

**Causa:** `iss` ou `aud` diferentes do esperado. Também pode ser `aud` em array sem uma `azp` igual a `p_aud`, ou datas fora da janela por diferença de relógio entre servidores (`iat`/`nbf` no futuro, ou `exp` já passado).

**Correção:** veja o motivo exato no debug log da sessão. Ajuste `p_iss`/`p_aud` ou aumente `p_leeway_seconds` (ex.: 30 a 60 s) para absorver a diferença de relógio.

Fonte: [VALIDATE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/VALIDATE.html)


## 06. APEX_EXEC: consultar, gravar e executar código em qualquer fonte de dados (local, REST Enabled SQL, REST Data Source, Duality View, JSON Source)

### APEX_EXEC: propósito, quando usar e quando não usar

`APEX_EXEC` é a camada de abstração de fontes de dados que o próprio APEX usa por baixo dos componentes (relatórios, grids, plug-ins). Ele oferece **uma única API** para:

- **consultar** dados (abrir um "cursor" lógico, o *context*, iterar linhas e ler colunas) de: banco local, banco remoto via ORDS **REST Enabled SQL**, **REST Data Sources** definidas em *Shared Components*, *Duality View sources* e *JSON sources*;
- **gravar** (DML: insert/update/delete) nessas mesmas fontes, com detecção de *lost update* e status por linha;
- **executar** PL/SQL local ou remoto e operações de REST Data Source (POST, GET, DELETE etc.), passando *bind variables* e recebendo valores `OUT`.

O código fica igual independentemente de onde o dado mora: trocar uma tabela local por uma REST Data Source muda só a chamada `OPEN_*`. Filtros (`ADD_FILTER`), ordenação (`ADD_ORDER_BY`), seleção de colunas (`ADD_COLUMN`), agregação e paginação (`p_first_row`/`p_max_rows`) são declarados em PL/SQL e o APEX os traduz para a fonte (SQL, parâmetros da API REST ou pós-processamento local).

**Quando usar**
- Desenvolvimento de **plug-ins** (região, processo, REST Data Source plug-in) que precisam ler a fonte da região sem saber se é SQL ou REST (`OPEN_QUERY_CONTEXT` Signature 2, `DESCRIBE_QUERY` Signature 1, `EXECUTE_PLSQL`).
- Ler uma **REST Data Source** em PL/SQL (processo, job, package) reaproveitando a definição de *Shared Components* (URL, autenticação, *data profile*, parâmetros, cache), em vez de chamar `APEX_WEB_SERVICE` e fazer parse de JSON manualmente.
- Rodar SQL ou PL/SQL num **servidor remoto REST Enabled SQL** (`OPEN_REMOTE_SQL_QUERY`, `EXECUTE_REMOTE_PLSQL`, `OPEN_REMOTE_DML_CONTEXT`).
- Gravar em lote numa fonte REST ou remota com controle de erro por linha (`EXECUTE_DML` + `HAS_ERROR`/`GET_DML_STATUS_*`).
- Copiar dados entre fontes diferentes (`COPY_DATA`: local para remoto, remoto para REST etc.).

**Quando não usar**
- Para SQL local simples dentro de um package de negócio, um cursor PL/SQL comum é mais direto e legível. `APEX_EXEC` brilha quando a fonte é REST/remota, quando o código precisa ser genérico (plug-in) ou quando se quer o mesmo modelo de filtros/ordenação dos componentes APEX.
- Fora de uma sessão APEX sem preparar o ambiente: **todas** as rotinas exigem uma sessão APEX existente. Em SQL*Plus, SQLcl, job do scheduler ou trigger, crie uma com `APEX_SESSION` antes (exemplo: `apex_session.create_session( 100, 1, 'ADMIN' );`, como aparece nos exemplos da própria doc 26.1).

**Pré-requisitos**
- Sessão APEX ativa (ver acima).
- REST Data Source, servidor REST Enabled SQL, Duality View source ou JSON source **cadastrados na aplicação corrente** e referenciados pelo **Static ID**.
- Para `OPEN_REST_SOURCE_DML_CONTEXT`, a REST Data Source precisa ter operações mapeadas para pelo menos uma das ações *Insert Rows*, *Update Rows* ou *Delete Rows*. Para consulta, é usada a operação mapeada para `FETCH_COLLECTION`.

**Pegadinhas gerais**
- **Sempre feche o contexto**, inclusive em exceção. O contexto segura cursores e LOBs temporários no servidor; a doc pede explicitamente um *exception handler* que chame `APEX_EXEC.CLOSE`. Padrão:

```sql
EXCEPTION
    WHEN others THEN
        apex_debug.log_exception;
        apex_exec.close( l_context );
        RAISE;
```

- Os índices de coluna (`GET_COLUMN_POSITION`) devem ser obtidos **uma vez, antes** do loop `NEXT_ROW`; ler por nome dentro do loop funciona, mas repete a busca a cada linha.
- Vários exemplos oficiais do capítulo têm erros de digitação ou usam a API antiga (`open_web_source_*`, parâmetro `p_module_static_id` em `open_rest_source_query`, `set_value` sem `p_context`). Os casos estão registrados no fim desta parte; use as **assinaturas** como verdade, não os exemplos.
- As APIs `*_WEB_SOURCE_*` são **Deprecated**: use as equivalentes `*_REST_SOURCE_*`.

Fonte: [APEX_EXEC](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.html), [Call Sequences for APEX_EXEC](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/call-sequences-for-APEX_EXEC.html)

### APEX_EXEC: referência completa de procedures, functions, constantes e tipos

| Nome | Tipo | Descrição |
|---|---|---|
| `ADD_COLUMN` | procedure | Adiciona uma coluna a um `t_columns` (projeção de consulta ou colunas de DML; marca PK, checksum, returning, query-only, coluna filha de array). |
| `ADD_DML_ARRAY_ROW` | procedure | Adiciona uma linha filha num array aninhado (só DML em REST Data Source). |
| `ADD_DML_ROW` | procedure | Adiciona uma linha ao contexto DML com a operação (insert/update/delete). |
| `ADD_FILTER` | procedure (23 assinaturas) | Adiciona filtro a um `t_filters`: valor único, faixa, lista, intervalo de datas, busca em linha, SQL, espacial, Oracle TEXT, Ubiquitous Search, vetorial, booleano. |
| `ADD_ORDER_BY` | procedure (2 assinaturas) | Adiciona ordenação por posição ou por nome de coluna. |
| `ADD_PARAMETER` | procedure (15 assinaturas) | Adiciona *bind variable* / parâmetro de REST Data Source a um `t_parameters` (VARCHAR2, NUMBER, DATE, TIMESTAMP*, INTERVAL*, BLOB, BFILE, CLOB, ANYDATA, `t_value`, SDO_GEOMETRY, BOOLEAN). |
| `CLEAR_DML_ROWS` | procedure | Remove todas as linhas DML já adicionadas ao contexto. |
| `CLOSE` | procedure | Fecha o contexto e libera recursos. Obrigatório, inclusive em exceção. |
| `CLOSE_ARRAY` | procedure | Sai do array aninhado corrente e volta ao elemento pai. |
| `COLUMN_EXISTS` | function | Indica se uma coluna já existe num `t_columns`. |
| `COPY_DATA` | procedure | Lê todas as linhas de um contexto de consulta e grava num contexto DML. |
| `DESCRIBE_QUERY` (Signature 1) | function | Descreve as colunas da fonte da região corrente (plug-ins). |
| `DESCRIBE_QUERY` (Signature 2) | function | Descreve as colunas de uma fonte arbitrária (local, remota, REST, Duality View, JSON). |
| `ENQUOTE_LITERAL` | function | Coloca aspas e escapa um literal de string para o banco alvo (Oracle ou MySQL). |
| `ENQUOTE_NAME` | function | Coloca aspas num nome de objeto para o banco alvo. |
| `EXECUTE_DML` | procedure | Executa as linhas DML adicionadas ao contexto. |
| `EXECUTE_PLSQL` (Signature 1) | procedure | Executa PL/SQL conforme a localização do processo/plug-in corrente, com binds `IN OUT`. |
| `EXECUTE_PLSQL` (Signature 2) | procedure | Mesma coisa, só com o código (binds de itens automáticos). |
| `EXECUTE_REMOTE_PLSQL` (Signature 1) | procedure | Executa PL/SQL num servidor REST Enabled SQL, com binds `IN OUT`. |
| `EXECUTE_REMOTE_PLSQL` (Signature 2) | procedure | Mesma coisa, só com servidor e código. |
| `EXECUTE_REST_SOURCE` (Signature 1) | procedure | Executa uma operação de REST Data Source por nome da operação (+ URL pattern). |
| `EXECUTE_REST_SOURCE` (Signature 2) | procedure | Executa uma operação de REST Data Source pelo Static ID da operação. |
| `EXECUTE_WEB_SOURCE` | procedure **(Deprecated)** | Antecessora de `EXECUTE_REST_SOURCE`. |
| `GET_VARCHAR2`, `GET_NUMBER`, `GET_DATE`, `GET_TIMESTAMP`, `GET_TIMESTAMP_TZ`, `GET_TIMESTAMP_LTZ`, `GET_CLOB`, `GET_BLOB`, `GET_INTERVALD2S`, `GET_INTERVALY2M`, `GET_ANYDATA`, `GET_SDO_GEOMETRY`, `GET_BOOLEAN` | functions ("GET Function") | Leem o valor de uma coluna da linha corrente, por índice ou por nome (`GET_SDO_GEOMETRY` só por nome). |
| `GET_ARRAY_ROW_DML_OPERATION` | function | Operação DML do elemento de array corrente (plug-ins de REST Data Source). |
| `GET_ARRAY_ROW_VERSION_CHECKSUM` | function | Checksum de versão do elemento de array corrente. |
| `GET_COLUMN` | function | Metadados (`t_column`) de uma coluna do resultado, por índice. |
| `GET_COLUMNS` | function | Todos os metadados de colunas (`t_columns`) do contexto. |
| `GET_COLUMN_COUNT` | function | Número de colunas do resultado. |
| `GET_COLUMN_POSITION` | function | Índice de uma coluna pelo nome/alias, com validação opcional de obrigatoriedade e tipo. |
| `GET_DATA_TYPE` | function (2 assinaturas) | Converte constante `t_data_type` em nome SQL e vice-versa. |
| `GET_DML_STATUS_CODE` | function | Código de status da linha DML corrente (ORA- local/remoto, HTTP em REST). |
| `GET_DML_STATUS_MESSAGE` | function | Mensagem de status da linha DML corrente (mensagem ORA- ou *reason phrase* HTTP). |
| `GET_PARAMETER_VARCHAR2`, `GET_PARAMETER_NUMBER`, `GET_PARAMETER_DATE`, `GET_PARAMETER_TIMESTAMP`, `GET_PARAMETER_TIMESTAMP_TZ`, `GET_PARAMETER_TIMESTAMP_LTZ`, `GET_PARAMETER_CLOB`, `GET_PARAMETER_INTERVAL_D2S`, `GET_PARAMETER_INTERVAL_Y2M` | functions ("GET_PARAMETER Functions") | Leem um valor de `t_parameters` pelo nome, tipicamente binds `OUT` após execução. |
| `GET_ROW_VERSION_CHECKSUM` | function | Checksum de versão da linha corrente (coluna designada ou calculado). |
| `GET_TOTAL_ROW_COUNT` | function | Total de linhas do resultado (se solicitado na abertura); `NULL` se desconhecido. |
| `HAS_ERROR` | function | `TRUE` se a DML da linha corrente falhou. |
| `HAS_MORE_ARRAY_ROWS` | function | Se o array aninhado corrente tem mais filhos. |
| `HAS_MORE_ROWS` | function | Após o loop, se a fonte tinha mais linhas que `p_max_rows`. |
| `IS_GROUP_END` | function | Se a linha corrente fecha um grupo de *control break*. |
| `IS_REMOTE_SQL_AUTH_VALID` | function | Testa se as credenciais atuais são válidas para um servidor REST Enabled SQL. |
| `NEXT_ARRAY_ROW` | function | Avança o cursor dentro do array aninhado. |
| `NEXT_ROW` | function | Avança o cursor de um contexto de consulta ou DML (pós-execução). |
| `OPEN_ARRAY` (Signatures 1 e 2) | procedure | Entra num array aninhado por nome ou posição de coluna (contextos de REST Data Source). |
| `OPEN_DUALITY_VIEW_DML_CONTEXT` | function | Abre contexto DML sobre uma Duality View source. |
| `OPEN_JSON_SOURCE_DML_CONTEXT` | function | Abre contexto DML sobre uma JSON source. |
| `OPEN_LOCAL_DML_CONTEXT` | function | Abre contexto DML sobre o banco local (tabela, SQL ou função que retorna SQL). |
| `OPEN_QUERY_CONTEXT` (Signature 1) | function | Abre consulta em qualquer localização (`p_location`): local, remota, REST, Duality View, JSON source. |
| `OPEN_QUERY_CONTEXT` (Signature 2) | function | Abre consulta sobre a fonte da região corrente (plug-ins). |
| `OPEN_REMOTE_DML_CONTEXT` | function | Abre contexto DML num servidor REST Enabled SQL. |
| `OPEN_REMOTE_SQL_QUERY` | function | Abre consulta SQL num servidor REST Enabled SQL. |
| `OPEN_REST_SOURCE_DML_CONTEXT` | function | Abre contexto DML sobre uma REST Data Source. |
| `OPEN_REST_SOURCE_QUERY` | function | Abre consulta sobre uma REST Data Source (operação `FETCH_COLLECTION`). |
| `OPEN_WEB_SOURCE_DML_CONTEXT` | function **(Deprecated)** | Antecessora de `OPEN_REST_SOURCE_DML_CONTEXT`. |
| `OPEN_WEB_SOURCE_QUERY` | function **(Deprecated)** | Antecessora de `OPEN_REST_SOURCE_QUERY`. |
| `PURGE_DUALITY_VIEW_CACHE` | procedure | Limpa o cache local de uma Duality View source. |
| `PURGE_JSON_SOURCE_CACHE` | procedure | Limpa o cache local de uma JSON source. |
| `PURGE_REST_SOURCE_CACHE` | procedure | Limpa o cache local de uma REST Data Source. |
| `PURGE_WEB_SOURCE_CACHE` | procedure **(Deprecated)** | Antecessora de `PURGE_REST_SOURCE_CACHE`. |
| `SET_ARRAY_CURRENT_ROW` | procedure | Posiciona o cursor numa linha do array corrente. |
| `SET_ARRAY_ROW_VERSION_CHECKSUM` | procedure | Define o checksum do elemento de array corrente. |
| `SET_CURRENT_ROW` | procedure | Posiciona o ponteiro de linha corrente do contexto DML. |
| `SET_NULL` | procedure (2 assinaturas) | Define `NULL` numa coluna da linha DML corrente. |
| `SET_ROW_VERSION_CHECKSUM` | procedure | Define o checksum de *lost update* da linha DML corrente. |
| `SET_VALUE` | procedure (13 assinaturas × posição/nome) | Define o valor de uma coluna da linha DML corrente. |
| `SET_VALUES` | procedure | Copia todos os valores da linha corrente de um contexto de consulta para a linha DML corrente. |
| `t_location` e `c_location_*` | subtype + constantes | Onde a consulta/DML roda. |
| `t_query_type` e `c_query_type_*` | subtype + constantes | Tipo de fonte para contextos DML (`TABLE`, `SQL`, `FUNC_BODY_RETURNING_SQL`). |
| `t_dml_operation` e `c_dml_operation_*` | subtype + constantes | Insert (1), update (2), delete (3). |
| `t_target_type` e `c_target_type_*` | subtype + constantes | Tipos de alvo (`REGION_SOURCE`, `TABLE`, `SQL`, `PLSQL_CODE`). |
| `t_post_processing` e `c_postprocess_*` | subtype + constantes | Pós-processamento de dados de REST Data Source. |
| `c_lov_shared`, `c_lov_sql_query`, `c_lov_static` | constantes (`t_lov_type`) | Tipos de LOV. |
| `t_data_type` e `c_data_type_*` | subtype + constantes | Tipos de dado de coluna/filtro/parâmetro (1..18; `c_data_type_json` = 11). |
| `t_filter_type` e `c_filter_*` | subtype + constantes | Tipos de filtro (1..39). |
| `t_order_direction`/`c_order_asc`/`c_order_desc`, `t_order_nulls`/`c_order_nulls_first`/`c_order_nulls_last` | subtypes + constantes | Direção e posição de nulos na ordenação. |
| `t_supports_orderby_nulls_as` e `c_orderby_nulls_*` | subtype + constantes | Como a fonte REST trata nulos na ordenação (para plug-ins de REST Source). |
| `c_empty_columns`, `c_empty_filters`, `c_empty_order_bys`, `c_empty_parameters`, `c_empty_aggregation` | constantes | Coleções vazias usadas como default. |
| `t_database_type`, `c_database_oracle`, `c_database_mysql` | subtype + constantes | Banco alvo para `ENQUOTE_*`. |
| `t_aggregation_type`/`c_aggregation_*`, `t_column_role`/`c_column_role_*`, `t_aggregate_function`/`c_aggregate_*` | subtypes + constantes | Agregação (`GROUP BY`, `DISTINCT`) sobre a consulta. |
| `t_aggregation_column`, `t_aggregation_columns`, `t_aggregation` | tipos | Definição de agregação passada em `p_aggregation`. |
| `t_vector_search_type`/`c_vector_search_*`, `t_vector_distance_type`/`c_vector_distance_*`, `t_vector_distance`/`c_vector_dist_str_*` | subtypes + constantes | Busca vetorial (Database 23ai). |
| `t_column_name` | subtype | `varchar2(32767)`. |
| `t_value`, `t_values` | tipos | Valor polimórfico (um campo por tipo) e sua coleção. |
| `t_parameter`, `t_parameters` | tipos | Bind variable (nome, tipo, valor) e coleção. |
| `t_filter`, `t_filters`, `t_filter_interval_type` | tipos | Filtro e coleção. |
| `t_order_by`, `t_order_bys` | tipos | Ordenação e coleção. |
| `t_column`, `t_columns` | tipos | Metadados de coluna e coleção. |
| `t_context` | subtype | Handle do contexto (`pls_integer`). |
| `t_source_capabilities` | tipo | Capacidades de uma fonte (paginação, filtro, ordenação...); atributos `filter_*` e `orderby_*` **(Deprecated)**. |

Constantes e tipos citados nas assinaturas, mas **não listados** nas páginas *Global Constants*/*Data Types* da doc 26.1: `t_language`/`c_lang_*` (`c_lang_plsql` é o default de `p_function_body_language`), `t_control_break`/`c_empty_control_break` (o exemplo de `IS_GROUP_END` usa o campo `control_break_columns`), `t_lost_update_detection`/`c_lost_update_implicit`/`c_lost_update_explicit`/`c_lost_update_none`, `t_lock_rows`/`c_lock_rows_automatic`/`c_lock_rows_plsql`/`c_lock_rows_none`, `t_filter_buckets` e `t_search_operator`. Use-os pelos nomes que aparecem nas descrições de parâmetros.

Fonte: [APEX_EXEC](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.html), [Global Constants](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.Global-Constants.html), [Data Types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.Data-Types.html)

### APEX_EXEC: sequência de chamadas para consultar, gravar e executar (call sequences)

A doc define três roteiros canônicos. Siga-os na ordem.

**1. Consultar uma fonte de dados**
1. (Opcional) Montar a projeção: variável `apex_exec.t_columns` + `ADD_COLUMN` para cada coluna. Sem colunas, vêm todas as colunas da fonte.
2. (Opcional) Montar binds: `apex_exec.t_parameters` + `ADD_PARAMETER`.
3. (Opcional) Montar filtros: `apex_exec.t_filters` + `ADD_FILTER` (e ordenação com `t_order_bys` + `ADD_ORDER_BY`).
4. Abrir: `OPEN_REST_SOURCE_QUERY` (REST Data Source), `OPEN_REMOTE_SQL_QUERY` (REST Enabled SQL) ou `OPEN_QUERY_CONTEXT` passando a localização.
5. Metadados: `GET_COLUMN_COUNT`, `GET_COLUMN`, `GET_COLUMN_POSITION`.
6. Loop: `NEXT_ROW` + `GET_VARCHAR2`/`GET_NUMBER`/...
7. `CLOSE` no fim **e** no *exception handler*.

**2. Executar DML numa fonte de dados**
1. Colunas DML: `t_columns` + `ADD_COLUMN` (marcar `p_is_primary_key`, `p_is_checksum`, `p_is_returning` conforme o caso).
2. (Opcional) Binds: `t_parameters` + `ADD_PARAMETER`.
3. Abrir: `OPEN_REST_SOURCE_DML_CONTEXT`, `OPEN_REMOTE_DML_CONTEXT` ou `OPEN_LOCAL_DML_CONTEXT` (também `OPEN_DUALITY_VIEW_DML_CONTEXT`/`OPEN_JSON_SOURCE_DML_CONTEXT`).
4. Para cada linha: `ADD_DML_ROW` + `SET_VALUE` (ou `SET_VALUES`, `SET_NULL`, `SET_ROW_VERSION_CHECKSUM`).
5. `EXECUTE_DML`.
6. Percorrer o resultado: `NEXT_ROW`, `HAS_ERROR`, `GET_DML_STATUS_CODE` (NULL = sucesso) e `GET_*` para valores de *DML RETURNING*.
7. `CLOSE` no fim e na exceção.

**3. Executar procedimento remoto ou API REST**
1. (Opcional) Binds: `t_parameters` + `ADD_PARAMETER` (inclusive os `OUT`, com valor vazio).
2. Executar: `EXECUTE_REST_SOURCE` (REST Data Source), `EXECUTE_REMOTE_PLSQL` (REST Enabled SQL) ou `EXECUTE_PLSQL` (local/conforme o processo).
3. `p_parameters`/`p_sql_parameters` é `IN OUT`: após a chamada, leia os `OUT` com as funções `GET_PARAMETER_*` (a página de call sequences fala em "`GET_PARAMETER_VALUE`", mas as funções efetivamente documentadas são `GET_PARAMETER_VARCHAR2`, `GET_PARAMETER_NUMBER`, `GET_PARAMETER_CLOB` etc.).

Esse terceiro roteiro não abre contexto, então não há `CLOSE`.

Fonte: [Call Sequences for APEX_EXEC](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/call-sequences-for-APEX_EXEC.html)

### APEX_EXEC: constantes de localização, tipo de consulta, operação DML e pós-processamento (c_location_*, c_query_type_*, c_dml_operation_*)

```sql
subtype t_location is varchar2(12);

c_location_local_db       constant t_location  := 'LOCAL';
c_location_remote_db      constant t_location  := 'REMOTE';
c_location_rest_source    constant t_location  := 'REST_SOURCE';
c_location_region_source  constant t_location  := 'REGION_SOURCE';
c_location_duality_view   constant t_location  := 'DUALITY_VIEW';
c_location_json_source    constant t_location  := 'JSON_COLLECTION';
c_location_sample_data    constant t_location  := 'SAMPLE_DATA';

c_lov_shared              constant t_lov_type  := 1;
c_lov_sql_query           constant t_lov_type  := 2;
c_lov_static              constant t_lov_type  := 3;

subtype t_query_type is varchar2(23);
c_query_type_table           constant t_query_type := 'TABLE';
c_query_type_sql_query       constant t_query_type := 'SQL';
c_query_type_func_return_sql constant t_query_type := 'FUNC_BODY_RETURNING_SQL';

subtype t_dml_operation is pls_integer range 1..3;
c_dml_operation_insert constant t_dml_operation := 1;
c_dml_operation_update constant t_dml_operation := 2;
c_dml_operation_delete constant t_dml_operation := 3;

subtype t_target_type is varchar2(13);
c_target_type_region_source constant t_target_type := 'REGION_SOURCE';
c_target_type_table         constant t_target_type := 'TABLE';
c_target_type_sql_query     constant t_target_type := 'SQL';
c_target_type_plsql         constant t_target_type := 'PLSQL_CODE';

subtype t_post_processing is pls_integer range 1..3;
c_postprocess_where_orderby    constant t_post_processing := 1;
c_postprocess_sql              constant t_post_processing := 2;
c_postprocess_func_return_sql  constant t_post_processing := 3;
```

| Constante | Uso típico |
|---|---|
| `c_location_local_db` | `OPEN_QUERY_CONTEXT` / `DESCRIBE_QUERY` no schema local (com `p_sql_query`, `p_table_name` ou `p_function_body`). |
| `c_location_remote_db` | Idem num servidor REST Enabled SQL; exige `p_server_static_id`. |
| `c_location_rest_source` | REST Data Source; exige `p_module_static_id`. |
| `c_location_duality_view` / `c_location_json_source` | Exigem `p_duality_view_static_id` / `p_json_source_static_id`. |
| `c_location_region_source`, `c_location_sample_data` | Localizações adicionais listadas pela doc, sem detalhamento de uso no capítulo. |
| `c_query_type_*` | Parâmetro `p_query_type` dos contextos DML local e remoto. |
| `c_dml_operation_*` | `ADD_DML_ROW.p_operation`, `ADD_DML_ARRAY_ROW.p_operation`, retorno de `GET_ARRAY_ROW_DML_OPERATION`. |
| `c_postprocess_*` | `p_post_process_type` de `OPEN_QUERY_CONTEXT`/`DESCRIBE_QUERY` para REST Data Sources (pós-processar com WHERE/ORDER BY, SQL ou função que retorna SQL). |

Fonte: [Global Constants](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.Global-Constants.html)

### APEX_EXEC: constantes de tipo de dado (c_data_type_*)

Usadas em `ADD_COLUMN`, `ADD_FILTER`, `ADD_PARAMETER` (Signature 13), `GET_COLUMN_POSITION` e no campo `data_type` de `t_column`/`t_parameter`/`t_filter`.

```sql
subtype t_data_type is pls_integer range 1..18;

c_data_type_varchar2      constant t_data_type := 1;
c_data_type_number        constant t_data_type := 2;
c_data_type_date          constant t_data_type := 3;
c_data_type_timestamp     constant t_data_type := 4;
c_data_type_timestamp_tz  constant t_data_type := 5;
c_data_type_timestamp_ltz constant t_data_type := 6;
c_data_type_interval_y2m  constant t_data_type := 7;
c_data_type_interval_d2s  constant t_data_type := 8;
c_data_type_blob          constant t_data_type := 9;
c_data_type_bfile         constant t_data_type := 10;
c_data_type_clob          constant t_data_type := 11;
c_data_type_rowid         constant t_data_type := 12;
c_data_type_user_defined  constant t_data_type := 13;
c_data_type_binary_number constant t_data_type := 14;
c_data_type_sdo_geometry  constant t_data_type := 15;
c_data_type_boolean       constant t_data_type := 16;
c_data_type_array         constant t_data_type := 17;
c_data_type_vector        constant t_data_type := 18;

-- só para colunas do tipo JSON (Database 21c+); hoje equivale a CLOB
c_data_type_json constant t_data_type := 11;
```

Pegadinhas:
- `c_data_type_json` tem o **mesmo valor** de `c_data_type_clob` (11): a doc avisa que hoje o comportamento é idêntico ao de CLOB e pode ser estendido no futuro. Use-o só para colunas de tipo JSON.
- `c_data_type_binary_number` só é devolvido em `OPEN_QUERY_CONTEXT` quando `p_supports_binary_number => TRUE`; caso contrário colunas BINARY NUMBER aparecem como `c_data_type_number`.
- `c_data_type_array` marca uma coluna-array do *data profile* de REST Data Source (ver `ADD_DML_ARRAY_ROW`/`OPEN_ARRAY`).
- `GET_DATA_TYPE` converte entre a constante e o nome SQL do tipo (ver seção de metadados).

Fonte: [Global Constants](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.Global-Constants.html)

### APEX_EXEC: constantes de filtro (c_filter_*)

Valores de `p_filter_type` em `ADD_FILTER` (`subtype t_filter_type is pls_integer range 1..39`).

| Constante | Valor | Significado / observação da doc |
|---|---|---|
| `c_filter_eq` | 1 | igual |
| `c_filter_not_eq` | 2 | diferente |
| `c_filter_gt` | 3 | maior que |
| `c_filter_gte` | 4 | maior ou igual |
| `c_filter_lt` | 5 | menor que |
| `c_filter_lte` | 6 | menor ou igual |
| `c_filter_null` | 7 | é nulo (use Signature 1, sem valor) |
| `c_filter_not_null` | 8 | não é nulo (Signature 1) |
| `c_filter_starts_with` | 9 | começa com |
| `c_filter_not_starts_with` | 10 | não começa com |
| `c_filter_ends_with` | 11 | termina com |
| `c_filter_not_ends_with` | 12 | não termina com |
| `c_filter_contains` | 13 | contém |
| `c_filter_not_contains` | 14 | não contém |
| `c_filter_in` | 15 | em lista (`p_values`) |
| `c_filter_not_in` | 16 | fora da lista |
| `c_filter_between` | 17 | entre (`p_from_value`/`p_to_value`) |
| `c_filter_not_between` | 18 | fora da faixa |
| `c_filter_regexp` | 19 | expressão regular |
| `c_filter_last` | 20 | filtro de data: últimos N dias/meses/... |
| `c_filter_not_last` | 21 | filtro de data |
| `c_filter_next` | 22 | filtro de data: próximos N |
| `c_filter_not_next` | 23 | filtro de data |
| `c_filter_like` | 24 | filtro de Interactive Report |
| `c_filter_not_like` | 25 | filtro de Interactive Report |
| `c_filter_search` | 26 | filtro de Interactive Report (busca em linha) |
| `c_filter_sql_expression` | 27 | filtro de Interactive Report (expressão SQL) |
| `c_filter_oracletext` | 28 | Oracle TEXT `CONTAINS` |
| `c_filter_between_lbe` | 29 | filtro de Interactive Report |
| `c_filter_between_ube` | 30 | filtro de Interactive Report |
| `c_filter_sdo_filter` | 31 | espacial |
| `c_filter_sdo_anyinteract` | 32 | espacial |
| `c_filter_dbms_search` | 33 | Oracle Ubiquitous Search `CONTAINS` |
| `c_filter_vector_type` | 34 | busca vetorial |
| `c_filter_true` | 35 | booleano verdadeiro |
| `c_filter_false` | 36 | booleano falso |
| `c_filter_not_between_lbe` | 37 | — |
| `c_filter_not_between_ube` | 38 | — |
| `c_filter_sdo_releate` | 39 | espacial (grafia exatamente assim na doc) |

Fonte: [Global Constants](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.Global-Constants.html)

### APEX_EXEC: constantes de ordenação, coleções vazias, banco alvo, agregação e busca vetorial

```sql
-- Ordenação (ADD_ORDER_BY)
c_order_asc           constant t_order_direction := 1;
c_order_desc          constant t_order_direction := 2;
c_order_nulls_first   constant t_order_nulls := 1;
c_order_nulls_last    constant t_order_nulls := 2;

-- Como a fonte REST trata nulos (plug-ins de REST Source)
subtype t_supports_orderby_nulls_as is pls_integer range 1..5;
c_orderby_nulls_flexible        constant t_supports_orderby_nulls_as := 1;
c_orderby_nulls_are_lowest      constant t_supports_orderby_nulls_as := 2;
c_orderby_nulls_are_highest     constant t_supports_orderby_nulls_as := 3;
c_orderby_nulls_always_last     constant t_supports_orderby_nulls_as := 4;
c_orderby_nulls_always_first    constant t_supports_orderby_nulls_as := 5;

-- Coleções vazias (defaults)
c_empty_columns         t_columns;
c_empty_filters         t_filters;
c_empty_order_bys       t_order_bys;
c_empty_parameters      t_parameters;

-- Banco alvo (ENQUOTE_LITERAL / ENQUOTE_NAME)
subtype t_database_type is pls_integer range 1..2;
c_database_oracle constant t_database_type := 1;
c_database_mysql  constant t_database_type := 2;

-- Agregação
subtype t_aggregation_type is pls_integer range 1..3;
c_aggregation_none constant     t_aggregation_type := 1;
c_aggregation_group_by constant t_aggregation_type := 2;
c_aggregation_distinct constant t_aggregation_type := 3;

subtype t_column_role is pls_integer range 1..2;
c_column_role_aggregate constant t_column_role := 1;
c_column_role_group_by  constant t_column_role := 2;

subtype t_aggregate_function is pls_integer range 1..11;
c_aggregate_sum              constant t_aggregate_function := 1;
c_aggregate_avg              constant t_aggregate_function := 2;
c_aggregate_median           constant t_aggregate_function := 3;
c_aggregate_cnt              constant t_aggregate_function := 4;
c_aggregate_distinct_cnt     constant t_aggregate_function := 5;
c_aggregate_approx_dist_cnt  constant t_aggregate_function := 6;
c_aggregate_min              constant t_aggregate_function := 7;
c_aggregate_max              constant t_aggregate_function := 8;
c_aggregate_ratio_report_sum constant t_aggregate_function := 9;
c_aggregate_ratio_report_cnt constant t_aggregate_function := 10;
c_aggregate_listagg          constant t_aggregate_function := 11;

type t_aggregation_column is record(
    attributes         t_column,
    aggr_role          t_column_role,
    aggr_function      t_aggregate_function,
    total_column_name  t_column_name,
    total_function     t_aggregate_function );

type t_aggregation_columns is table of t_aggregation_column index by pls_integer;

type t_aggregation is record(
    aggregation_type        t_aggregation_type,
    column_info             t_aggregation_columns,
    order_bys               t_order_bys,
    order_by_expr           varchar2(32767),
    row_count_column        t_column_name );

c_empty_aggregation t_aggregation;

-- Busca vetorial (ADD_FILTER Signature 22)
subtype t_vector_search_type is pls_integer range 1..3;
c_vector_search_exact  constant t_vector_search_type := 1;
c_vector_search_approx constant t_vector_search_type := 2;
c_vector_search_multi  constant t_vector_search_type := 3;

subtype t_vector_distance_type is pls_integer range 1..6;
c_vector_distance_cosine       constant t_vector_distance_type := 1;
c_vector_distance_dot          constant t_vector_distance_type := 2;
c_vector_distance_euclidean    constant t_vector_distance_type := 3;
c_vector_distance_eucl_squared constant t_vector_distance_type := 4;
c_vector_distance_hamming      constant t_vector_distance_type := 5;
c_vector_distance_manhattan    constant t_vector_distance_type := 6;

subtype t_vector_distance is varchar2(17);
c_vector_dist_str_cosine       constant t_vector_distance  := 'COSINE';
c_vector_dist_str_dot          constant t_vector_distance  := 'DOT';
c_vector_dist_str_euclidean    constant t_vector_distance  := 'EUCLIDEAN';
c_vector_dist_str_eucl_squared constant t_vector_distance  := 'EUCLIDEAN_SQUARED';
c_vector_dist_str_hamming      constant t_vector_distance  := 'HAMMING';
c_vector_dist_str_manhattan    constant t_vector_distance  := 'MANHATTAN';
```

Notas:
- A agregação (`p_aggregation` em `OPEN_QUERY_CONTEXT`/`OPEN_REST_SOURCE_QUERY`) é aplicada **por cima** da consulta: `aggregation_type` escolhe nenhuma/`GROUP BY`/`DISTINCT`; cada `t_aggregation_column` diz se a coluna é de agrupamento (`c_column_role_group_by`) ou agregada (`c_column_role_aggregate` + `aggr_function`), com total opcional (`total_column_name`/`total_function`). A doc não traz exemplo completo de agregação.
- `c_empty_aggregation` é o default de `p_aggregation`.

Fonte: [Global Constants](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.Global-Constants.html)

### APEX_EXEC: tipos de dados (t_context, t_value, t_parameter, t_filter, t_order_by, t_column, t_source_capabilities)

```sql
subtype t_column_name is varchar2(32767);

type t_value is record (
    varchar2_value      varchar2(32767),
    number_value        number,
    binary_number_value binary_double,
    date_value          date,
    boolean_value       boolean,
    timestamp_value     timestamp,
    timestamp_tz_value  timestamp with time zone,
    timestamp_ltz_value timestamp with local time zone,
    interval_y2m_value  yminterval_unconstrained,
    interval_d2s_value  dsinterval_unconstrained,
    blob_value          blob,
    bfile_value         bfile,
    clob_value          clob,
    sdo_geometry_value  mdsys.sdo_geometry,   -- só se SDO_GEOMETRY estiver instalado
    vector_value        vector,
    array_value         sys.json_array_t,
    anydata_value       sys.anydata );
type t_values is table of t_value index by pls_integer;

-- Bind variables
type t_parameter is record (
    name      t_column_name,
    data_type t_data_type,
    value     t_value );
type t_parameters is table of t_parameter index by pls_integer;

-- Filtros
subtype t_filter_type is pls_integer range 1..39;
subtype t_filter_interval_type is varchar2(2);
type t_filter is record (
    column_name       t_column_name,
    data_type         t_data_type,
    filter_type       t_filter_type,
    filter_values     t_values,
    filter_buckets    t_filter_buckets,
    sql_expression    varchar2(32767),
    search_columns    t_columns,
    search_operator   t_search_operator,
    null_result       boolean default false,
    is_case_sensitive boolean default true );
type t_filters is table of t_filter index by pls_integer;

-- Ordenação
subtype t_order_direction is pls_integer range 1..2;
subtype t_order_nulls     is pls_integer range 1..2;
type t_order_by is record (
    column_name   t_column_name,
    direction     t_order_direction,
    order_nulls   t_order_nulls );
type t_order_bys is table of t_order_by index by pls_integer;

-- Colunas (versão detalhada da seção "Column Meta Data")
type t_column is record (
    name                      t_column_name,
    parent_column_position    pls_integer,
    data_type                 t_data_type,
    data_type_length          pls_integer,
    sql_expression            varchar2(32767),
    format_mask               varchar2(4000),
    is_required               boolean default false,
    is_primary_key            boolean default false,
    is_query_only             boolean default false,
    is_checksum               boolean default false,
    is_returning              boolean default false );
type t_columns is table of t_column index by pls_integer;

-- Handle do contexto
subtype t_context is pls_integer;
```

Atributos de `t_column`:

| Atributo | Significado |
|---|---|
| `name` | Nome ou alias da coluna. |
| `parent_column_position` | Referência à coluna pai (colunas filhas de array). |
| `data_type` | Constante `c_data_type_*`. |
| `data_type_length` | Tamanho para VARCHAR2. |
| `sql_expression` | Expressão SQL de coluna derivada. |
| `format_mask` | Máscara para NUMBER, DATE ou TIMESTAMP. |
| `is_required` | Coluna obrigatória (NOT NULL). |
| `is_primary_key` | Parte da chave primária. |
| `is_query_only` | Fica fora das operações DML. |
| `is_checksum` | É a coluna de versão da linha (lost update explícito). |
| `is_returning` | O novo valor deve ser devolvido após a DML. |

`t_source_capabilities` (relevante para plug-ins de REST Source) tem `location`, `pagination`, `page_size_is_stable`, `allow_fetch_all_rows`, `filtering`, `order_by`, `group_by` e `orderby_nulls_as` (todos booleanos com default `false`, exceto `location` e `orderby_nulls_as`), mais uma série de atributos `filter_*` (eq, not_eq, gt, ..., not_next) e `orderby_*` (asc, desc, nulls) que a doc marca **(Deprecated)**: "não use, serão removidos".

Pegadinhas:
- `t_context` é apenas um `pls_integer`: não há "objeto" a destruir, mas os recursos associados no servidor só são liberados com `CLOSE`.
- As coleções são *associative arrays* (`index by pls_integer`) e começam vazias ao declarar; não precisam de construtor.
- O campo `filter_values` de `t_filter` é um `t_values`, por isso uma lista para `c_filter_in` é passada via `apex_t_varchar2`/`apex_t_number` em `ADD_FILTER` e convertida internamente.

Fonte: [Data Types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.Data-Types.html)

### APEX_EXEC.OPEN_QUERY_CONTEXT (Signature 1): abrir consulta em banco local, remoto, REST Data Source, Duality View ou JSON source

Função "coringa": abre um contexto de consulta para qualquer localização indicada em `p_location` e executa a consulta.

```sql
APEX_EXEC.OPEN_QUERY_CONTEXT (
    p_location               in apex_exec_api.t_location,
    --
    p_table_owner            IN VARCHAR2                       DEFAULT NULL,
    p_table_name             IN VARCHAR2                       DEFAULT NULL,
    p_where_clause           IN VARCHAR2                       DEFAULT NULL,
    p_match_clause           IN VARCHAR2                       DEFAULT NULL,
    p_columns_clause         IN VARCHAR2                       DEFAULT NULL,
    p_order_by_clause        IN VARCHAR2                       DEFAULT NULL,
    p_include_rowid_column   IN BOOLEAN                        DEFAULT FALSE,
    --
    p_sql_query              IN VARCHAR2                       DEFAULT NULL,
    p_function_body          IN VARCHAR2                       DEFAULT NULL,
    p_function_body_language IN t_language                     DEFAULT c_lang_plsql,
    p_plsql_function_body    IN VARCHAR2                       DEFAULT NULL, -- Deprecated:
    p_optimizer_hint         IN VARCHAR2                       DEFAULT NULL,
    --
    p_server_static_id       IN VARCHAR2                       DEFAULT NULL,
    --
    p_module_static_id       IN VARCHAR2                       DEFAULT NULL,
    p_web_src_parameters     IN t_parameters                   DEFAULT c_empty_parameters,
    p_external_filter_expr   IN VARCHAR2                       DEFAULT NULL,
    p_external_order_by_expr IN VARCHAR2                       DEFAULT NULL,
    --
    p_sql_parameters         IN t_parameters                   DEFAULT c_empty_parameters,
    p_auto_bind_items        IN BOOLEAN                        DEFAULT TRUE,
    --
    p_columns                IN t_columns                      DEFAULT c_empty_columns,
    --
    p_filters                IN t_filters                      DEFAULT c_empty_filters,
    p_order_bys              IN t_order_bys                    DEFAULT c_empty_order_bys,
    p_aggregation            IN t_aggregation                  DEFAULT c_empty_aggregation,
    p_control_break          IN t_control_break                DEFAULT c_empty_control_break,
    --
    p_post_process_type      IN t_post_processing              DEFAULT NULL,
    --
    p_first_row              IN NUMBER                         DEFAULT NULL,
    p_max_rows               IN NUMBER                         DEFAULT NULL,
    --
    p_total_row_count        IN BOOLEAN                        DEFAULT FALSE,
    p_total_row_count_limit  IN NUMBER                         DEFAULT NULL,
    --
    p_supports_binary_number IN BOOLEAN                        DEFAULT FALSE,
    --
    p_array_column_name      IN VARCHAR2                       DEFAULT NULL,
    --
    p_duality_view_static_id IN VARCHAR2                       DEFAULT NULL,
    p_json_source_static_id  IN VARCHAR2                       DEFAULT NULL )
    RETURN t_context;
```

| Parâmetro | Descrição |
|---|---|
| `p_location` | Onde executar: constante `c_location_*` (local, remoto, REST Data Source, Duality View, JSON source). |
| `p_table_owner`, `p_table_name` | Dono e nome da tabela quando o tipo de consulta é TABLE. |
| `p_where_clause` | WHERE anexado nos tipos TABLE ou GRAPH. |
| `p_match_clause`, `p_columns_clause` | Cláusulas MATCH e COLUMNS no tipo GRAPH (SQL property graph). |
| `p_order_by_clause` | ORDER BY anexado no tipo TABLE. |
| `p_include_rowid_column` | Default `FALSE`. Inclui `ROWID` no SELECT no tipo TABLE. |
| `p_sql_query` | Consulta SQL (tipo *SQL Query*). |
| `p_function_body` | Corpo de função que retorna a consulta SQL. |
| `p_function_body_language` | Linguagem de `p_function_body` (`c_lang_*`, default `c_lang_plsql`). |
| `p_plsql_function_body` | **Deprecated**: use `p_function_body`. |
| `p_optimizer_hint` | Hint aplicado ao SELECT mais externo gerado pelo APEX. |
| `p_server_static_id` | Static ID do *Remote Server* quando `p_location = c_location_remote_db`. |
| `p_module_static_id` | Static ID da REST Data Source quando `p_location = c_location_rest_source`. |
| `p_web_src_parameters` | Parâmetros para a REST Data Source. |
| `p_external_filter_expr`, `p_external_order_by_expr` | Filtro e ordenação repassados à REST Data Source. |
| `p_sql_parameters` | Binds adicionais da consulta SQL. |
| `p_auto_bind_items` | Default `TRUE`: faz bind automático de itens de página e de aplicação. |
| `p_columns` | Colunas a selecionar. |
| `p_filters`, `p_order_bys` | Filtros e ordenação. |
| `p_aggregation` | `GROUP BY`/`DISTINCT` por cima da consulta. |
| `p_control_break` | Retornar *control breaks* ao iterar (ver `IS_GROUP_END`). |
| `p_post_process_type` | Pós-processamento do resultado de REST Data Source (`c_postprocess_*`). |
| `p_first_row`, `p_max_rows` | Primeira linha e máximo de linhas (paginação). |
| `p_total_row_count` | Calcular o total de linhas (lido com `GET_TOTAL_ROW_COUNT`). |
| `p_total_row_count_limit` | Limite superior para a contagem. |
| `p_supports_binary_number` | Devolver BINARY NUMBER como `c_data_type_binary_number` em vez de `c_data_type_number`. |
| `p_array_column_name` | Coluna-array do *data profile* da REST Source a ser "achatada" como linhas. |
| `p_duality_view_static_id`, `p_json_source_static_id` | Static ID da Duality View source / JSON source. |

**Retorno:** o `t_context` que representa o "cursor" da consulta.

**Comportamento:** cada localização usa um subconjunto dos parâmetros: local usa `p_sql_query` (ou TABLE/`p_function_body`); remoto adiciona `p_server_static_id`; REST usa `p_module_static_id` + `p_web_src_parameters` + `p_external_*`. Filtros, ordenação, agregação e paginação valem para todas. Note que, para REST, o nome do parâmetro aqui é `p_module_static_id`, enquanto em `OPEN_REST_SOURCE_QUERY` é `p_static_id`.

Exemplo da doc (consulta local; pode ser usado numa região *Execute PL/SQL*):

```sql
DECLARE
    l_context apex_exec.t_context;
    l_idx_empno    pls_integer;
    l_idx_ename    pls_integer;
    l_idx_mgr      pls_integer;
BEGIN
    l_context := apex_exec.open_query_context(
        p_location          => apex_exec.c_location_local_db,
        p_sql_query         => 'select * from emp' );

    l_idx_empno    := apex_exec.get_column_position( l_context, 'EMPNO');
    l_idx_ename    := apex_exec.get_column_position( l_context, 'ENAME');
    l_idx_mgr      := apex_exec.get_column_position( l_context, 'MGR');

    WHILE apex_exec.next_row( l_context ) LOOP
        sys.dbms_output.put_line( 'EMPNO: ' || apex_exec.get_number  ( l_context, l_idx_empno ) );
        sys.dbms_output.put_line( 'ENAME: ' || apex_exec.get_varchar2( l_context, l_idx_ename ) );
        sys.dbms_output.put_line( 'MGR:   ' || apex_exec.get_number  ( l_context, l_idx_mgr   ) );
    END LOOP;

    apex_exec.close( l_context );
    RETURN;
EXCEPTION
    WHEN others THEN
        apex_exec.close( l_context );
        RAISE;
END;
```

Exemplo próprio (REST Data Source via `OPEN_QUERY_CONTEXT`, com parâmetro, filtro, paginação e total), usando só parâmetros documentados:

```sql
DECLARE
    l_context  apex_exec.t_context;
    l_params   apex_exec.t_parameters;
    l_filters  apex_exec.t_filters;
    l_total    pls_integer;
BEGIN
    apex_exec.add_parameter( l_params, 'STATUS', 'ATIVO' );

    apex_exec.add_filter(
        p_filters     => l_filters,
        p_filter_type => apex_exec.c_filter_starts_with,
        p_column_name => 'NOME',
        p_value       => 'Ana' );

    l_context := apex_exec.open_query_context(
        p_location           => apex_exec.c_location_rest_source,
        p_module_static_id   => 'COLABORADORES_API',
        p_web_src_parameters => l_params,
        p_filters            => l_filters,
        p_first_row          => 1,
        p_max_rows           => 50,
        p_total_row_count    => true );

    l_total := apex_exec.get_total_row_count( l_context );  -- NULL se desconhecido

    WHILE apex_exec.next_row( l_context ) LOOP
        apex_debug.info( 'Nome: %s', apex_exec.get_varchar2( l_context, 'NOME' ) );
    END LOOP;

    apex_exec.close( l_context );
EXCEPTION
    WHEN others THEN
        apex_debug.log_exception;
        apex_exec.close( l_context );
        RAISE;
END;
```

Pegadinhas:
- `p_auto_bind_items` é `TRUE` por default: qualquer `:P1_X` na consulta é preenchido com o valor da sessão. Se a consulta tiver binds que **não** são itens, passe-os em `p_sql_parameters`.
- `p_total_row_count` em REST Data Sources só é suportado quando a fonte tem *allow fetch all rows* = Yes (ver `OPEN_REST_SOURCE_QUERY`).
- O tipo do primeiro parâmetro aparece como `apex_exec_api.t_location` na assinatura publicada; use `apex_exec.c_location_*`.

Fonte: [OPEN_QUERY_CONTEXT Function Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.OPEN_QUERY_CONTEXT-Function-1.html)

### APEX_EXEC.OPEN_QUERY_CONTEXT (Signature 2): consultar a fonte da região corrente em plug-ins

Para desenvolvedores de plug-in de região: abre um contexto sobre a **fonte da região do plug-in**, buscando toda a informação de fonte (tabela, SQL, REST, localização) dos metadados da região. O código do plug-in não precisa saber onde o dado está.

```sql
APEX_EXEC.OPEN_QUERY_CONTEXT (
    p_columns                     IN t_columns        DEFAULT c_empty_columns,
    --
    p_filters                     IN t_filters        DEFAULT c_empty_filters,
    p_order_bys                   IN t_order_bys      DEFAULT c_empty_order_bys,
    p_aggregation                 IN t_aggregation    DEFAULT c_empty_aggregation,
    p_control_break               IN t_control_break  DEFAULT c_empty_control_break,
    --
    p_first_row                   IN NUMBER           DEFAULT NULL,
    p_max_rows                    IN NUMBER           DEFAULT NULL,
    --
    p_total_row_count             IN BOOLEAN          DEFAULT FALSE,
    p_total_row_count_limit       IN NUMBER           DEFAULT NULL,
    --
    p_sql_parameters              IN t_parameters     DEFAULT c_empty_parameters )
    RETURN t_context;
```

| Parâmetro | Descrição |
|---|---|
| `p_columns` | Colunas a selecionar da fonte. |
| `p_filters` / `p_order_bys` | Filtros e ordenação adicionais. |
| `p_aggregation` | `GROUP BY` / `DISTINCT` sobre a consulta. |
| `p_control_break` | Retornar *control breaks* no loop. |
| `p_first_row` / `p_max_rows` | Paginação. |
| `p_total_row_count` / `p_total_row_count_limit` | Contagem total e seu limite. |
| `p_sql_parameters` | Binds. |

**Retorno:** `t_context`.

Quando usar: dentro da função de *render*/AJAX de um plug-in de região que declara suporte a fonte de dados. Fora de um plug-in de região (processo comum, package), não há "região corrente": use a Signature 1 ou as funções específicas. Combine com `DESCRIBE_QUERY` (Signature 1) para descobrir as colunas antes de abrir.

Fonte: [OPEN_QUERY_CONTEXT Function Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC-OPEN_QUERY_CONTEXT-Function-2.html)

### APEX_EXEC.OPEN_REST_SOURCE_QUERY: ler uma REST Data Source em PL/SQL

Abre um contexto de consulta sobre uma REST Data Source de *Shared Components*, usando a operação mapeada para a ação de banco `FETCH_COLLECTION`.

```sql
APEX_EXEC.OPEN_REST_SOURCE_QUERY (
    p_static_id              IN VARCHAR2,
    p_parameters             IN t_parameters     DEFAULT c_empty_parameters,
    --
    p_filters                IN t_filters        DEFAULT c_empty_filters,
    p_order_bys              IN t_order_bys      DEFAULT c_empty_order_bys,
    p_aggregation            IN t_aggregation    DEFAULT c_empty_aggregation,
    p_control_break          IN t_control_break  DEFAULT c_empty_control_break,
    p_columns                IN t_columns        DEFAULT c_empty_columns,
    --
    p_external_filter_expr   IN VARCHAR2         DEFAULT NULL,
    p_external_order_by_expr IN VARCHAR2         DEFAULT NULL,
    --
    p_first_row              IN PLS_INTEGER      DEFAULT NULL,
    p_max_rows               IN PLS_INTEGER      DEFAULT NULL,
    --
    p_total_row_count        IN BOOLEAN          DEFAULT FALSE,
    --
    p_array_column_name      IN VARCHAR2         DEFAULT NULL )
    RETURN t_context;
```

| Parâmetro | Descrição |
|---|---|
| `p_static_id` | Static ID da REST Data Source. |
| `p_parameters` | Valores dos parâmetros declarados na REST Data Source. |
| `p_filters`, `p_order_bys` | Filtros e ordenação (traduzidos para a API quando a fonte suporta; senão aplicados pelo APEX). |
| `p_aggregation` | `GROUP BY`/`DISTINCT` sobre o resultado. |
| `p_control_break` | *Control breaks* no loop. |
| `p_columns` | Subconjunto de colunas do *data profile*. |
| `p_external_filter_expr` | Expressão de filtro repassada **1:1** ao serviço externo; a sintaxe depende do serviço. |
| `p_external_order_by_expr` | Ordenação repassada 1:1 ao serviço externo. |
| `p_first_row`, `p_max_rows` | Paginação. |
| `p_total_row_count` | Total de linhas; **só suportado quando o atributo *allow fetch all rows* = Yes**. |
| `p_array_column_name` | Coluna-array do *data profile*. |

**Retorno:** `t_context`.

Exemplo da doc (REST Data Source `USGS` sobre o feed GeoJSON de terremotos):

```sql
DECLARE
    l_context apex_exec.t_context;
    l_magidx  pls_integer;
    l_titidx  pls_integer;
    l_plcidx  pls_integer;
    l_timidx  pls_integer;
    l_ididx   pls_integer;
BEGIN
    l_context := apex_exec.open_rest_source_query(
        p_static_id     => 'USGS',
        p_max_rows      => 1000 );

    l_titidx := apex_exec.get_column_position( l_context, 'TITLE' );
    l_magidx := apex_exec.get_column_position( l_context, 'MAG' );
    l_plcidx := apex_exec.get_column_position( l_context, 'PLACE' );
    l_timidx := apex_exec.get_column_position( l_context, 'TIME' );
    l_ididx  := apex_exec.get_column_position( l_context, 'ID' );

    WHILE apex_exec.next_row( l_context ) LOOP
        htp.p( 'ID:    ' || apex_exec.get_varchar2( l_context, l_ididx  ) );
        htp.p( 'MAG:   ' || apex_exec.get_varchar2( l_context, l_magidx ) );
        htp.p( 'PLACE: ' || apex_exec.get_varchar2( l_context, l_plcidx ) );
        htp.p( 'TITLE: ' || apex_exec.get_varchar2( l_context, l_titidx ) );
        htp.p( 'TIME:  ' || apex_exec.get_varchar2( l_context, l_timidx ) );
    END LOOP;

    apex_exec.close( l_context );
EXCEPTION
    WHEN others THEN
        apex_exec.close( l_context );
        RAISE;
END;
```

Exemplo próprio completo (REST Data Source com colunas, filtros, ordenação, paginação e detecção de "há mais"), gravando o resultado numa tabela local:

```sql
DECLARE
    l_context   apex_exec.t_context;
    l_columns   apex_exec.t_columns;
    l_filters   apex_exec.t_filters;
    l_order_bys apex_exec.t_order_bys;
    l_idx_id    pls_integer;
    l_idx_mag   pls_integer;
    l_idx_place pls_integer;
BEGIN
    -- 1. projeção: só o que vou usar
    apex_exec.add_column( p_columns => l_columns, p_column_name => 'ID' );
    apex_exec.add_column( p_columns => l_columns, p_column_name => 'MAG' );
    apex_exec.add_column( p_columns => l_columns, p_column_name => 'PLACE' );

    -- 2. filtros: magnitude >= 4,5 e lugar contendo "Chile" (sem diferenciar maiúsculas)
    apex_exec.add_filter(
        p_filters     => l_filters,
        p_filter_type => apex_exec.c_filter_gte,
        p_column_name => 'MAG',
        p_value       => 4.5 );

    apex_exec.add_filter(
        p_filters           => l_filters,
        p_filter_type       => apex_exec.c_filter_contains,
        p_column_name       => 'PLACE',
        p_value             => apex_t_varchar2( 'Chile' ),
        p_is_case_sensitive => false );

    -- 3. ordenação: maiores primeiro, nulos no fim
    apex_exec.add_order_by(
        p_order_bys   => l_order_bys,
        p_column_name => 'MAG',
        p_direction   => apex_exec.c_order_desc,
        p_order_nulls => apex_exec.c_order_nulls_last );

    -- 4. abrir
    l_context := apex_exec.open_rest_source_query(
        p_static_id => 'USGS',
        p_columns   => l_columns,
        p_filters   => l_filters,
        p_order_bys => l_order_bys,
        p_max_rows  => 200 );

    -- 5. índices uma vez, antes do loop
    l_idx_id    := apex_exec.get_column_position( l_context, 'ID' );
    l_idx_mag   := apex_exec.get_column_position( l_context, 'MAG',
                       p_data_type => apex_exec.c_data_type_number );
    l_idx_place := apex_exec.get_column_position( l_context, 'PLACE' );

    WHILE apex_exec.next_row( l_context ) LOOP
        insert into tremores( id, magnitude, local )
        values ( apex_exec.get_varchar2( l_context, l_idx_id ),
                 apex_exec.get_number  ( l_context, l_idx_mag ),
                 apex_exec.get_varchar2( l_context, l_idx_place ) );
    END LOOP;

    IF apex_exec.has_more_rows( l_context ) THEN
        apex_debug.warn( 'Havia mais de 200 linhas; resultado truncado.' );
    END IF;

    apex_exec.close( l_context );
EXCEPTION
    WHEN others THEN
        apex_debug.log_exception;
        apex_exec.close( l_context );
        RAISE;
END;
```

Pegadinhas:
- O parâmetro chama-se `p_static_id` (o exemplo oficial de `ADD_COLUMN` usa `p_module_static_id` aqui por engano: isso não compila).
- Os parâmetros HTTP (headers, URL pattern, query string) são tipicamente strings; a doc recomenda converter explicitamente para VARCHAR2 antes de `ADD_PARAMETER` (dito em `EXECUTE_REST_SOURCE`, mas vale para qualquer parâmetro de REST).
- Se a REST Data Source tem cache habilitado, a consulta pode vir do cache; para forçar nova chamada use `PURGE_REST_SOURCE_CACHE`.

Fonte: [OPEN_REST_SOURCE_QUERY Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.OPEN_REST_SOURCE_QUERY-Function.html), [ADD_COLUMN Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.ADD_COLUMN-Procedure.html), [HAS_MORE_ROWS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.HAS_MORE_ROWS-Function.html)

### APEX_EXEC.OPEN_REMOTE_SQL_QUERY: executar SELECT num servidor REST Enabled SQL

Abre um contexto e executa a consulta numa instância ORDS **REST Enabled SQL** cadastrada em *Shared Components* (Remote Server).

```sql
APEX_EXEC.OPEN_REMOTE_SQL_QUERY (
    p_server_static_id      IN VARCHAR2,
    p_sql_query             IN VARCHAR2,
    p_sql_parameters        IN t_parameters DEFAULT c_empty_parameters,
    p_auto_bind_items       IN BOOLEAN      DEFAULT TRUE,
    --
    p_columns               IN t_columns    DEFAULT c_empty_columns,
    --
    p_first_row             IN NUMBER       DEFAULT NULL,
    p_max_rows              IN NUMBER       DEFAULT NULL,
    --
    p_total_row_count       IN BOOLEAN      DEFAULT FALSE,
    p_total_row_count_limit IN NUMBER       DEFAULT NULL )
RETURN t_context;
```

| Parâmetro | Descrição |
|---|---|
| `p_server_static_id` | Static ID da instância REST Enabled SQL. |
| `p_sql_query` | Consulta a executar no remoto. |
| `p_sql_parameters` | Binds enviados ao servidor remoto. |
| `p_auto_bind_items` | Bind automático de todos os itens de página (default `TRUE`). |
| `p_columns` | Colunas a devolver. |
| `p_first_row`, `p_max_rows` | Paginação. |
| `p_total_row_count`, `p_total_row_count_limit` | Contagem total e limite. |

**Retorno:** `t_context`.

Exemplo da doc (servidor `My_Remote_SQL_Instance`):

```sql
DECLARE
    l_context      apex_exec.t_context;
    l_idx_empno    pls_integer;
    l_idx_ename    pls_integer;
    l_idx_mgr      pls_integer;
BEGIN
    l_context := apex_exec.open_remote_sql_query(
         p_server_static_id   => 'My_Remote_SQL_Instance',
         p_sql_query          => 'select * from emp' );

    l_idx_empno    := apex_exec.get_column_position( l_context, 'EMPNO');
    l_idx_ename    := apex_exec.get_column_position( l_context, 'ENAME');
    l_idx_mgr      := apex_exec.get_column_position( l_context, 'MGR');

    WHILE apex_exec.next_row( l_context ) LOOP
        htp.p( 'EMPNO: ' || apex_exec.get_number  ( l_context, l_idx_empno ) );
        htp.p( 'ENAME: ' || apex_exec.get_varchar2( l_context, l_idx_ename ) );
        htp.p( 'MGR:   ' || apex_exec.get_number  ( l_context, l_idx_mgr   ) );
    END LOOP;

    apex_exec.close( l_context );
    RETURN;
EXCEPTION
    WHEN others THEN
        apex_debug.log_exception;
        apex_exec.close( l_context );
        RAISE;
END;
```

Pegadinhas:
- Com `p_auto_bind_items => TRUE` (default), valores de itens de página referenciados viajam ao servidor remoto. Para binds que não são itens, passe `p_sql_parameters` (e considere `p_auto_bind_items => false`).
- A assinatura publicada mostra o default como `c_empty columns` (sem sublinhado): é erro tipográfico, o valor é `c_empty_columns`.
- Antes de chamar, é possível validar credenciais com `IS_REMOTE_SQL_AUTH_VALID`.

Fonte: [OPEN_REMOTE_SQL_QUERY Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.OPEN_REMOTE_SQL_QUERY-Function.html)

### APEX_EXEC.OPEN_WEB_SOURCE_QUERY (Deprecated): antiga consulta a Web Source Module

**Deprecated**, será removida: use `OPEN_REST_SOURCE_QUERY`. Mesma semântica (operação `FETCH_COLLECTION`), mas identifica a fonte por `p_module_static_id`.

```sql
FUNCTION OPEN_WEB_SOURCE_QUERY (
    p_module_static_id       IN VARCHAR2,
    p_parameters             IN t_parameters     DEFAULT c_empty_parameters,
    --
    p_filters                IN t_filters        DEFAULT c_empty_filters,
    p_order_bys              IN t_order_bys      DEFAULT c_empty_order_bys,
    p_aggregation            IN t_aggregation    DEFAULT c_empty_aggregation,
    p_control_break          IN t_control_break  DEFAULT c_empty_control_break,
    p_columns                IN t_columns        DEFAULT c_empty_columns,
    --
    p_first_row              IN PLS_INTEGER      DEFAULT NULL,
    p_max_rows               IN PLS_INTEGER      DEFAULT NULL,
    --
    p_external_filter_expr   IN VARCHAR2         DEFAULT NULL,
    p_external_order_by_expr IN VARCHAR2         DEFAULT NULL,
    --
    p_total_row_count        IN BOOLEAN          DEFAULT FALSE,
    --
    p_array_column_name      IN VARCHAR2         DEFAULT NULL )
    RETURN t_context;
```

Migração: troque `open_web_source_query( p_module_static_id => X, ...)` por `open_rest_source_query( p_static_id => X, ...)`; os demais parâmetros têm o mesmo nome. Código novo não deve usar esta função (e o exemplo de `ADD_ORDER_BY` na doc ainda a usa).

Fonte: [OPEN_WEB_SOURCE_QUERY Function (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.OPEN_WEB_SOURCE_QUERY-Function.html)

### APEX_EXEC.ADD_COLUMN: selecionar colunas e definir colunas de DML (t_columns)

Adiciona uma coluna a uma coleção `t_columns`. Em consultas, restringe as colunas buscadas (útil sobretudo em REST Data Sources, que não têm SELECT); sem colunas (ou com coleção vazia) todas as colunas da fonte são trazidas. Em contextos DML, define quais colunas participam e seus papéis.

```sql
APEX_EXEC.ADD_COLUMN (
    p_columns               IN OUT NOCOPY   t_columns,
    p_column_name           IN              VARCHAR2,
    p_data_type             IN              t_data_type DEFAULT NULL,
    p_sql_expression        IN              VARCHAR2    DEFAULT NULL,
    p_format_mask           IN              VARCHAR2    DEFAULT NULL,
    p_is_primary_key        IN              BOOLEAN     DEFAULT FALSE,
    p_is_query_only         IN              BOOLEAN     DEFAULT FALSE,
    p_is_returning          IN              BOOLEAN     DEFAULT FALSE,
    p_is_checksum           IN              BOOLEAN     DEFAULT FALSE,
    p_parent_column_path    IN              VARCHAR2    DEFAULT NULL );
```

| Parâmetro | Descrição |
|---|---|
| `p_columns` | Coleção de colunas (IN OUT). |
| `p_column_name` | Nome da coluna. |
| `p_data_type` | Tipo (`c_data_type_*`). |
| `p_sql_expression` | Expressão SQL para derivar a coluna de outras. |
| `p_format_mask` | Máscara de formato da coluna. |
| `p_is_primary_key` | Coluna de chave primária (default `FALSE`). Necessária para update/delete. |
| `p_is_query_only` | Não é escrita em contexto DML (default `FALSE`). |
| `p_is_returning` | Recuperar o valor *RETURNING* após a DML (default `FALSE`). |
| `p_is_checksum` | Coluna de checksum/versão da linha (default `FALSE`); usada com `c_lost_update_explicit`. |
| `p_parent_column_path` | Caminho da coluna pai, para colunas filhas de um array. |

Exemplo (correção do exemplo oficial, que usa `p_module_static_id` e esquece uma vírgula):

```sql
DECLARE
    l_columns     apex_exec.t_columns;
    l_context     apex_exec.t_context;
BEGIN
    apex_exec.add_column( p_columns => l_columns, p_column_name => 'ENAME' );
    apex_exec.add_column( p_columns => l_columns, p_column_name => 'SAL' );

    l_context := apex_exec.open_rest_source_query(
        p_static_id => '{REST Data Source static ID}',
        p_columns   => l_columns,
        p_max_rows  => 1000 );

    WHILE apex_exec.next_row( l_context ) LOOP
        NULL; -- processar linhas
    END LOOP;

    apex_exec.close( l_context );
EXCEPTION
    WHEN others THEN
        apex_exec.close( l_context );
        RAISE;
END;
```

Coluna filha de array (do exemplo de `ADD_DML_ARRAY_ROW`): declare a coluna-array com `p_data_type => apex_exec.c_data_type_array` e as filhas com `p_parent_column_path => 'ORDER_ITEMS'`.

Pegadinhas: a **ordem** de `ADD_COLUMN` define a posição usada por `SET_VALUE( p_column_position => n )` nos contextos DML; se mudar a ordem, mude as posições (ou use `p_column_name`). Para checar duplicidade antes de adicionar, use `COLUMN_EXISTS`.

Fonte: [ADD_COLUMN Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.ADD_COLUMN-Procedure.html), [ADD_DML_ARRAY_ROW Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.ADD_DML_ARRAY_ROW-Procedure.html)

### APEX_EXEC.COLUMN_EXISTS: verificar se a coluna já está na coleção

```sql
APEX_EXEC.COLUMN_EXISTS (
    p_columns            IN t_columns,
    p_column_name        IN VARCHAR2,
    p_parent_column_path IN VARCHAR2 DEFAULT NULL )
    RETURN BOOLEAN;
```

| Parâmetro | Descrição |
|---|---|
| `p_columns` | Coleção de colunas. |
| `p_column_name` | Nome procurado. |
| `p_parent_column_path` | Caminho da coluna pai (para colunas dentro de array). |

**Retorno:** `TRUE` se existe, `FALSE` caso contrário.

```sql
DECLARE
    l_columns apex_exec.t_columns;
BEGIN
    apex_exec.add_column( p_columns => l_columns, p_column_name => 'ENAME' );
    apex_exec.add_column( p_columns => l_columns, p_column_name => 'SAL' );

    IF apex_exec.column_exists( p_columns => l_columns, p_column_name => 'SAL' ) THEN
        NULL; -- a coluna existe
    END IF;
END;
```

Útil em plug-ins que montam a lista de colunas a partir de atributos configuráveis (evita adicionar a mesma coluna duas vezes).

Fonte: [COLUMN_EXISTS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.COLUMN_EXISTS-Function.html)

### APEX_EXEC.ADD_FILTER: filtrar consultas (23 assinaturas, t_filters)

Adiciona um filtro a uma coleção `t_filters`, depois passada em `p_filters` de `OPEN_QUERY_CONTEXT`, `OPEN_REST_SOURCE_QUERY` etc. Os filtros são combinados entre si (a doc não detalha o operador; na prática cada filtro restringe o resultado).

Assinaturas:

```sql
-- 1: filtros sem valor (c_filter_null, c_filter_not_null, c_filter_true, c_filter_false...)
PROCEDURE ADD_FILTER (
    p_filters           IN OUT NOCOPY t_filters,
    p_filter_type       IN            t_filter_type,
    p_column_name       IN            t_column_name );

-- 2: valor(es) texto, com sensibilidade a maiúsculas e tipo
PROCEDURE ADD_FILTER (
    p_filters           IN OUT NOCOPY t_filters,
    p_filter_type       IN            t_filter_type,
    p_column_name       IN            t_column_name,
    p_value             IN            apex_t_varchar2,
    p_null_result       IN            BOOLEAN  DEFAULT FALSE,
    p_is_case_sensitive IN            BOOLEAN  DEFAULT TRUE,
    p_data_type         IN            t_data_type DEFAULT c_data_type_varchar2 );

-- 3: faixa texto
PROCEDURE ADD_FILTER (
    p_filters           IN OUT NOCOPY t_filters,
    p_filter_type       IN            t_filter_type,
    p_column_name       IN            t_column_name,
    p_from_value        IN            VARCHAR2,
    p_to_value          IN            VARCHAR2,
    p_null_result       IN            BOOLEAN DEFAULT FALSE );

-- 4: lista texto (IN / NOT IN)
PROCEDURE ADD_FILTER (
    p_filters           IN OUT NOCOPY t_filters,
    p_filter_type       IN            t_filter_type,
    p_column_name       IN            t_column_name,
    p_values            IN            apex_t_varchar2,
    p_null_result       IN            BOOLEAN          DEFAULT FALSE );

-- 5: número
PROCEDURE ADD_FILTER (
    p_filters           IN OUT NOCOPY t_filters,
    p_filter_type       IN            t_filter_type,
    p_column_name       IN            t_column_name,
    p_value             IN            number,
    p_null_result       IN            BOOLEAN DEFAULT FALSE );

-- 6: faixa numérica
PROCEDURE ADD_FILTER (
    p_filters           IN OUT NOCOPY t_filters,
    p_filter_type       IN            t_filter_type,
    p_column_name       IN            t_column_name,
    p_from_value        IN            NUMBER,
    p_to_value          IN            NUMBER,
    p_null_result       IN            BOOLEAN DEFAULT FALSE );

-- 7: lista numérica
PROCEDURE ADD_FILTER (
    p_filters           IN OUT NOCOPY t_filters,
    p_filter_type       IN            t_filter_type,
    p_column_name       IN            t_column_name,
    p_values            IN            apex_t_number,
    p_null_result       IN            BOOLEAN DEFAULT FALSE );

-- 8 / 9: DATE (valor / faixa)
PROCEDURE ADD_FILTER (
    p_filters           IN OUT NOCOPY t_filters,
    p_filter_type       IN            t_filter_type,
    p_column_name       IN            t_column_name,
    p_value             IN            DATE,
    p_null_result       IN            BOOLEAN DEFAULT FALSE );

PROCEDURE ADD_FILTER (
    p_filters           IN OUT NOCOPY t_filters,
    p_filter_type       IN            t_filter_type,
    p_column_name       IN            t_column_name,
    p_from_value        IN            DATE,
    p_to_value          IN            DATE,
    p_null_result       IN            BOOLEAN DEFAULT FALSE );

-- 10 / 11: TIMESTAMP (valor / faixa)
PROCEDURE ADD_FILTER (
    p_filters           IN OUT NOCOPY t_filters,
    p_filter_type       IN            t_filter_type,
    p_column_name       IN            t_column_name,
    p_value             IN            TIMESTAMP,
    p_null_result       in            BOOLEAN DEFAULT FALSE );

PROCEDURE ADD_FILTER (
    p_filters           IN OUT NOCOPY t_filters,
    p_filter_type       IN            t_filter_type,
    p_column_name       IN            t_column_name,
    p_from_value        IN            TIMESTAMP,
    p_to_value          IN            TIMESTAMP,
    p_null_result       IN            BOOLEAN DEFAULT FALSE );

-- 12 / 13: TIMESTAMP WITH TIME ZONE (valor / faixa)
PROCEDURE ADD_FILTER (
    p_filters           IN OUT NOCOPY t_filters,
    p_filter_type       IN            t_filter_type,
    p_column_name       IN            t_column_name,
    p_value             IN            TIMESTAMP WITH TIME ZONE,
    p_null_result       IN            BOOLEAN DEFAULT FALSE );

PROCEDURE ADD_FILTER (
    p_filters           IN OUT NOCOPY t_filters,
    p_filter_type       IN            t_filter_type,
    p_column_name       IN            t_column_name,
    p_from_value        IN            TIMESTAMP WITH TIME ZONE,
    p_to_value          IN            TIMESTAMP WITH TIME ZONE,
    p_null_result       IN            BOOLEAN DEFAULT FALSE );

-- 14 / 15: TIMESTAMP WITH LOCAL TIME ZONE (valor / faixa)
PROCEDURE ADD_FILTER (
    p_filters           IN OUT NOCOPY t_filters,
    p_filter_type       IN            t_filter_type,
    p_column_name       IN            t_column_name,
    p_value             IN            TIMESTAMP WITH LOCAL TIME ZONE,
    p_null_result       IN            BOOLEAN DEFAULT FALSE );

PROCEDURE ADD_FILTER (
    p_filters           IN OUT NOCOPY t_filters,
    p_filter_type       IN            t_filter_type,
    p_column_name       IN            t_column_name,
    p_from_value        IN            TIMESTAMP WITH LOCAL TIME ZONE,
    p_to_value          IN            TIMESTAMP WITH LOCAL TIME ZONE,
    p_null_result       IN            BOOLEAN DEFAULT FALSE );

-- 16: intervalo relativo de datas (c_filter_last / not_last / next / not_next)
PROCEDURE ADD_FILTER (
    p_filters           IN OUT NOCOPY t_filters,
    p_filter_type       IN            t_filter_type,
    p_column_name       IN            t_column_name,
    p_interval          IN            PLS_INTEGER,
    p_interval_type     IN            t_filter_interval_type,
    p_null_result       IN            BOOLEAN     DEFAULT FALSE,
    p_data_type         IN            t_data_type DEFAULT c_data_type_date );

-- 17: busca em linha (row search) sobre várias colunas
PROCEDURE ADD_FILTER (
    p_filters           IN OUT NOCOPY t_filters,
    p_search_columns    IN            t_columns,
    p_is_case_sensitive IN            BOOLEAN           DEFAULT FALSE,
    p_value             IN            VARCHAR2,
    p_tokenize          IN            BOOLEAN           DEFAULT NULL );

-- 18: expressão SQL genérica
PROCEDURE ADD_FILTER (
    p_filters           IN OUT NOCOPY t_filters,
    p_sql_expression    IN            VARCHAR2 );

-- 19: espacial (só com SDO_GEOMETRY / Oracle Locator instalado)
PROCEDURE ADD_FILTER (
    p_filters           IN OUT NOCOPY t_filters,
    p_filter_type       IN            t_filter_type,
    p_column_name       IN            VARCHAR2,
    p_value             IN            mdsys.sdo_geometry
    p_param             IN            VARCHAR2                  DEFAULT NULL );

-- 20: Ubiquitous Database Search
PROCEDURE ADD_FILTER (
    p_filters             IN OUT NOCOPY t_filters,
    p_search_index_owner  IN            VARCHAR2,
    p_search_index_table  IN            VARCHAR2,
    p_text_column_name    IN            VARCHAR2,
    p_text_query_function IN            VARCHAR2,
    p_value               IN            VARCHAR2 );

-- 21: Oracle TEXT
PROCEDURE ADD_FILTER (
    p_filters             IN OUT NOCOPY t_filters,
    p_text_column_name    IN            VARCHAR2,
    p_text_query_function IN            VARCHAR2,
    p_value               IN            VARCHAR2 );

-- 22: busca vetorial (Database 23ai; exige apex_exec.add_vector_distance_column( p_columns => l_columns ))
PROCEDURE ADD_FILTER (
    p_filters             IN OUT NOCOPY t_filters,
    p_vector_column_name  IN            VARCHAR2,
    --
    p_vector_search_type  IN            t_vector_search_type    DEFAULT c_vector_search_exact,
    p_distance_metric     IN            t_vector_distance_type  DEFAULT c_vector_distance_euclidean,
    --
    -- só para p_vector_search_type = c_vector_search_approx
    p_target_accuracy     IN            NUMBER                  DEFAULT NULL,
    --
    p_max_results         IN            NUMBER,
    p_max_dist            IN            NUMBER                  DEFAULT NULL,
    p_search_vector       IN            VECTOR );

-- 23: booleano
PROCEDURE ADD_FILTER (
    p_filters           IN OUT NOCOPY t_filters,
    p_filter_type       IN            t_filter_type,
    p_column_name       IN            t_column_name,
    p_value             IN            BOOLEAN,
    p_null_result       IN            BOOLEAN DEFAULT FALSE );
```

| Parâmetro | Descrição |
|---|---|
| `p_filters` | Coleção de filtros (IN OUT). |
| `p_filter_type` | Constante `c_filter_*`. |
| `p_column_name` | Coluna filtrada. |
| `p_value` | Valor para filtros de um valor (igual, maior que...). |
| `p_values` | Lista para `IN`/`NOT IN`. |
| `p_from_value`, `p_to_value` | Limites para filtros de faixa (between). |
| `p_interval`, `p_interval_type` | Quantidade e unidade para filtros relativos de data (últimos X meses, dias...). |
| `p_sql_expression` | Expressão SQL usada como filtro. |
| `p_null_result` | Resultado quando o valor da coluna é `NULL` (default `FALSE`: linha com nulo não passa). |
| `p_is_case_sensitive` | Sensível a maiúsculas/minúsculas (default `TRUE` na Signature 2; `FALSE` na 17). |
| `p_search_columns` | Colunas em que a busca em linha atua. |
| `p_tokenize` | Quebrar o termo de busca em palavras. |
| `p_text_column_name`, `p_text_query_function` | Coluna e função do `CONTAINS` (Oracle TEXT ou Ubiquitous Search). |
| `p_search_index_owner`, `p_search_index_table` | Dono e nome da fonte do índice Ubiquitous Search. |
| `p_vector_column_name` | Coluna vetorial. |
| `p_vector_search_type` | `c_vector_search_*`. |
| `p_distance_metric` | `c_vector_distance_*`. |
| `p_target_accuracy` | Só quando a busca é aproximada (`c_vector_search_approx`). |
| `p_max_results` | Quantidade de linhas a buscar. |
| `p_max_dist` | Distância vetorial máxima. |
| `p_search_vector` | Vetor de busca. |
| `p_data_type` | Tipo da coluna filtrada. |

Exemplo da doc (corrigida a vírgula faltante):

```sql
DECLARE
    l_filters     apex_exec.t_filters;
    l_context     apex_exec.t_context;
BEGIN
    apex_exec.add_filter(
        p_filters     => l_filters,
        p_filter_type => apex_exec.c_filter_eq,
        p_column_name => 'ENAME',
        p_value       => 'KING' );

    apex_exec.add_filter(
        p_filters     => l_filters,
        p_filter_type => apex_exec.c_filter_gt,
        p_column_name => 'SAL',
        p_value       => 2000 );

    l_context := apex_exec.open_rest_source_query(
        p_static_id => '{REST source static ID}',
        p_filters   => l_filters,
        p_max_rows  => 1000 );

    WHILE apex_exec.next_row( l_context ) LOOP
        NULL; -- processar linhas
    END LOOP;

    apex_exec.close( l_context );
EXCEPTION
    WHEN others THEN
        apex_exec.close( l_context );
        RAISE;
END;
```

Mais exemplos (próprios, com assinaturas documentadas):

```sql
-- IN numérico (Signature 7)
apex_exec.add_filter(
    p_filters     => l_filters,
    p_filter_type => apex_exec.c_filter_in,
    p_column_name => 'DEPTNO',
    p_values      => apex_t_number( 10, 20 ) );

-- faixa de datas (Signature 9)
apex_exec.add_filter(
    p_filters     => l_filters,
    p_filter_type => apex_exec.c_filter_between,
    p_column_name => 'HIREDATE',
    p_from_value  => date '2026-01-01',
    p_to_value    => date '2026-06-30' );

-- é nulo (Signature 1)
apex_exec.add_filter(
    p_filters     => l_filters,
    p_filter_type => apex_exec.c_filter_null,
    p_column_name => 'COMM' );

-- busca em linha em ENAME e JOB, sem diferenciar maiúsculas (Signature 17)
DECLARE
    l_search_cols apex_exec.t_columns;
BEGIN
    apex_exec.add_column( p_columns => l_search_cols, p_column_name => 'ENAME' );
    apex_exec.add_column( p_columns => l_search_cols, p_column_name => 'JOB' );
    apex_exec.add_filter(
        p_filters        => l_filters,
        p_search_columns => l_search_cols,
        p_value          => 'clerk' );
END;

-- expressão SQL (Signature 18): só faz sentido em fontes SQL
apex_exec.add_filter(
    p_filters        => l_filters,
    p_sql_expression => 'SAL + NVL(COMM,0) > 3000' );
```

Pegadinhas:
- Atenção à **resolução de sobrecarga**: um literal `'KING'` em `p_value` cai numa assinatura de VARCHAR2; número cai na Signature 5; para listas use `p_values` (não `p_value`). Em caso de ambiguidade, use notação nomeada e tipos explícitos (`apex_t_varchar2(...)`, `apex_t_number(...)`, `date '...'`).
- Signature 19 só existe com Oracle Locator/SDO_GEOMETRY instalado; Signature 22 exige Database 23ai e `add_vector_distance_column`.
- `c_filter_sql_expression`/Signature 18 injeta SQL: nunca concatene entrada do usuário nela.
- Para REST Data Sources, a tradução do filtro para a API depende das capacidades da fonte; `p_external_filter_expr` é a alternativa para mandar a sintaxe nativa do serviço.

Fonte: [ADD_FILTER Procedures](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.ADD_FILTER-Procedure.html), [Global Constants](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.Global-Constants.html)

### APEX_EXEC.ADD_ORDER_BY: ordenar o resultado (t_order_bys)

```sql
-- Signature 1: por posição
APEX_EXEC.ADD_ORDER_BY (
    p_order_bys         IN OUT NOCOPY t_order_bys,
    p_position          IN            PLS_INTEGER,
    p_direction         IN            t_order_direction DEFAULT c_order_asc,
    p_order_nulls       IN            t_order_nulls     DEFAULT NULL )

-- Signature 2: por nome
APEX_EXEC.ADD_ORDER_BY (
    p_order_bys         IN OUT NOCOPY t_order_bys,
    p_column_name       IN            t_column_name,
    p_direction         IN            t_order_direction DEFAULT c_order_asc,
    p_order_nulls       IN            t_order_nulls     DEFAULT NULL )
```

| Parâmetro | Descrição |
|---|---|
| `p_order_bys` | Coleção de ordenações (IN OUT). |
| `p_position` | Coluna da fonte referenciada pela posição. |
| `p_column_name` | Coluna referenciada por nome ou alias. |
| `p_direction` | `c_order_asc` (default) ou `c_order_desc`. |
| `p_order_nulls` | `NULL` (automático conforme a direção), `c_order_nulls_first` ou `c_order_nulls_last`. |

Exemplo (versão atualizada do exemplo da doc, que usa a API deprecated `open_web_source_query`):

```sql
DECLARE
    l_order_bys   apex_exec.t_order_bys;
    l_context     apex_exec.t_context;
BEGIN
    apex_exec.add_order_by(
        p_order_bys   => l_order_bys,
        p_column_name => 'ENAME',
        p_direction   => apex_exec.c_order_asc );

    l_context := apex_exec.open_rest_source_query(
        p_static_id => '{REST Data Source static ID}',
        p_order_bys => l_order_bys,
        p_max_rows  => 1000 );

    WHILE apex_exec.next_row( l_context ) LOOP
        NULL; -- processar linhas
    END LOOP;

    apex_exec.close( l_context );
EXCEPTION
    WHEN others THEN
        apex_exec.close( l_context );
        RAISE;
END;
```

Pegadinhas: a ordem das chamadas define a precedência (primeira = chave principal). Ordenação também é pré-requisito para *control breaks* fazerem sentido (ver `IS_GROUP_END`). A página tem o arquivo `APEX_EXEC.ADD_ORDERBY-Procedure` (sem sublinhado na URL).

Fonte: [ADD_ORDER_BY Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.ADD_ORDERBY-Procedure.html)

### APEX_EXEC.ADD_PARAMETER: bind variables e parâmetros de REST Data Source (t_parameters)

Adiciona um parâmetro à coleção `t_parameters`. A mesma coleção serve para binds SQL/PL/SQL (`p_sql_parameters`) e para parâmetros de REST Data Source (`p_parameters`, `p_web_src_parameters`). Monte a coleção antes e passe-a na chamada de execução.

```sql
APEX_EXEC.ADD_PARAMETER ( p_parameters IN OUT NOCOPY t_parameters, p_name IN t_column_name, p_value IN VARCHAR2 )                       -- 1
APEX_EXEC.ADD_PARAMETER ( p_parameters IN OUT NOCOPY t_parameters, p_name IN t_column_name, p_value IN NUMBER )                         -- 2
APEX_EXEC.ADD_PARAMETER ( p_parameters IN OUT NOCOPY t_parameters, p_name IN t_column_name, p_value IN DATE )                           -- 3
APEX_EXEC.ADD_PARAMETER ( p_parameters IN OUT NOCOPY t_parameters, p_name IN t_column_name, p_value IN TIMESTAMP )                      -- 4
APEX_EXEC.ADD_PARAMETER ( p_parameters IN OUT NOCOPY t_parameters, p_name IN t_column_name, p_value IN TIMESTAMP WITH TIME ZONE )       -- 5
APEX_EXEC.ADD_PARAMETER ( p_parameters IN OUT NOCOPY t_parameters, p_name IN t_column_name, p_value IN TIMESTAMP WITH LOCAL TIME ZONE ) -- 6
APEX_EXEC.ADD_PARAMETER ( p_parameters IN OUT NOCOPY t_parameters, p_name IN t_column_name, p_value IN INTERVAL YEAR TO MONTH )         -- 7
APEX_EXEC.ADD_PARAMETER ( p_parameters IN OUT NOCOPY t_parameters, p_name IN t_column_name, p_value IN INTERVAL DAY TO SECOND )         -- 8
APEX_EXEC.ADD_PARAMETER ( p_parameters IN OUT NOCOPY t_parameters, p_name IN t_column_name, p_value IN BLOB )                           -- 9
APEX_EXEC.ADD_PARAMETER ( p_parameters IN OUT NOCOPY t_parameters, p_name IN t_column_name, p_value IN bfile )                          -- 10
APEX_EXEC.ADD_PARAMETER ( p_parameters IN OUT NOCOPY t_parameters, p_name IN t_column_name, p_value IN CLOB )                           -- 11
APEX_EXEC.ADD_PARAMETER ( p_parameters IN OUT NOCOPY t_parameters, p_name IN t_column_name, p_value IN sys.anydata )                    -- 12
APEX_EXEC.ADD_PARAMETER ( p_parameters IN OUT NOCOPY t_parameters, p_name IN t_column_name,
                          p_data_type  IN t_data_type, p_value IN t_value )                                                             -- 13
APEX_EXEC.ADD_PARAMETER ( p_parameters IN OUT NOCOPY t_parameters, p_name IN t_column_name, p_value IN mdsys.sdo_geometry )             -- 14 (só com SDO_GEOMETRY)
APEX_EXEC.ADD_PARAMETER ( p_parameters IN OUT NOCOPY t_parameters, p_name IN t_column_name, p_value IN BOOLEAN )                        -- 15
```

| Parâmetro | Descrição |
|---|---|
| `p_parameters` | Coleção de parâmetros (IN OUT). |
| `p_name` | Nome do parâmetro (o nome do bind sem `:` ou o nome do parâmetro da REST Data Source). |
| `p_value` | Valor. |
| `p_data_type` | (Signature 13) tipo explícito, com valor num `t_value`. |

Exemplo da doc (binds para PL/SQL remoto):

```sql
DECLARE
    l_parameters     apex_exec.t_parameters;
BEGIN
    apex_exec.add_parameter( l_parameters, 'ENAME',    'SCOTT' );
    apex_exec.add_parameter( l_parameters, 'SAL',      2000 );
    apex_exec.add_parameter( l_parameters, 'HIREDATE', sysdate );

    apex_exec.execute_remote_plsql(
        p_server_static_id => '{static ID of the REST Enabled SQL Service}',
        p_auto_bind_items  => false,
        p_plsql_code       => q'#begin insert into emp values (:ENAME, :SAL, :HIREDATE ); end;#',
        p_sql_parameters   => l_parameters );
END;
```

Pegadinhas:
- Para receber um valor `OUT`, adicione o parâmetro antes (com valor vazio, ex.: `''`) e leia-o depois com `GET_PARAMETER_*`.
- `EXECUTE_PLSQL` faz bind de **todos** os `p_sql_parameters` como VARCHAR2 (NUMBER/DATE convertidos implicitamente); prefira converter você mesmo com máscara explícita para não depender de NLS.
- Para REST Data Sources a doc recomenda passar tudo como VARCHAR2.

Fonte: [ADD_PARAMETER Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.ADD_ORDER_BY-Procedure.html)

### APEX_EXEC.GET_PARAMETER_*: ler valores OUT de t_parameters

Leem um parâmetro da coleção pelo nome; usadas sobretudo para pegar binds `OUT` depois de `EXECUTE_PLSQL`, `EXECUTE_REMOTE_PLSQL` ou `EXECUTE_REST_SOURCE`.

```sql
APEX_EXEC.GET_PARAMETER_VARCHAR2 (
    p_parameters      IN t_parameters,
    p_name            IN VARCHAR2,
    p_format_mask     IN VARCHAR2 DEFAULT NULL ) RETURN VARCHAR2;

APEX_EXEC.GET_PARAMETER_NUMBER        ( p_parameters IN t_parameters, p_name IN VARCHAR2 ) RETURN NUMBER;
APEX_EXEC.GET_PARAMETER_DATE          ( p_parameters IN t_parameters, p_name IN VARCHAR2 ) RETURN DATE;
APEX_EXEC.GET_PARAMETER_TIMESTAMP     ( p_parameters IN t_parameters, p_name IN VARCHAR2 ) RETURN TIMESTAMP;
APEX_EXEC.GET_PARAMETER_TIMESTAMP_TZ  ( p_parameters IN t_parameters, p_name IN VARCHAR2 ) RETURN TIMESTAMP WITH TIME ZONE;
APEX_EXEC.GET_PARAMETER_TIMESTAMP_LTZ ( p_parameters IN t_parameters, p_name IN VARCHAR2 ) RETURN TIMESTAMP WITH LOCAL TIME ZONE;
APEX_EXEC.GET_PARAMETER_CLOB          ( p_parameters IN t_parameters, p_name IN VARCHAR2 ) RETURN CLOB;
APEX_EXEC.GET_PARAMETER_INTERVAL_D2S  ( p_parameters IN t_parameters, p_name IN VARCHAR2 ) RETURN INTERVAL DAY TO SECOND;
APEX_EXEC.GET_PARAMETER_INTERVAL_Y2M  ( p_parameters IN t_parameters, p_name IN VARCHAR2 ) RETURN INTERVAL YEAR TO MONTH;
```

| Parâmetro | Descrição |
|---|---|
| `p_parameters` | Coleção (a mesma passada como IN OUT na execução). |
| `p_name` | Nome do parâmetro. |
| `p_format_mask` | Se o parâmetro é DATE/TIMESTAMP, máscara usada para gerar a representação VARCHAR2. |

**Retorno:** o valor do parâmetro no tipo pedido.

Uso típico: `:P2_RESPONSE := apex_exec.get_parameter_clob( l_params, 'RESPONSE' );` após `EXECUTE_REST_SOURCE` (resposta da API num parâmetro OUT do tipo Request Body).

Fonte: [GET_PARAMETER Functions](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.GET_PARAMETERS-Function.html)

### APEX_EXEC.NEXT_ROW e HAS_MORE_ROWS: iterar o resultado e detectar truncamento

```sql
APEX_EXEC.NEXT_ROW (
    p_context   IN t_context )
RETURN BOOLEAN;

APEX_EXEC.HAS_MORE_ROWS (
    p_context   IN t_context )
RETURN BOOLEAN;
```

`NEXT_ROW` avança o cursor de um contexto **de consulta ou de DML (após a execução)** em uma linha. Retorna `FALSE` ao chegar ao fim, `TRUE` caso contrário. O padrão é `WHILE apex_exec.next_row( l_context ) LOOP ... END LOOP;`. Em contextos DML, o loop após `EXECUTE_DML` percorre as linhas processadas para ler status e valores *RETURNING*.

`HAS_MORE_ROWS` indica se a fonte tinha mais dados além de `p_max_rows`. Só tem valor **depois** que o loop de `NEXT_ROW` termina (só então dá para saber que havia mais do que o pedido). Retorna `TRUE` (há mais), `FALSE` (não há) ou `NULL` (detecção de "mais dados" não foi solicitada).

Exemplo da doc (máximo de 10 linhas, aviso se houver mais):

```sql
DECLARE
    l_context      apex_exec.t_context;
BEGIN
    l_context := apex_exec.open_query_context(
        p_location          => apex_exec.c_location_local_db,
        p_max_rows          => 10,
        p_sql_query         => 'select * from emp' );

    WHILE apex_exec.next_row( l_context ) LOOP
        htp.p( 'EMPNO: ' || apex_exec.get_number  ( l_context, 'EMPNO' ) );
        htp.p( 'ENAME: ' || apex_exec.get_varchar2( l_context, 'ENAME' ) );
        htp.p( '<br>' );
    END LOOP;

    IF apex_exec.has_more_rows( l_context ) THEN
        htp.p( 'there are more rows ...' );
    END IF;

    apex_exec.close( l_context );
    RETURN;
EXCEPTION
    WHEN others THEN
        apex_exec.close( l_context );
        RAISE;
END;
```

Pegadinha: chamar `HAS_MORE_ROWS` antes de terminar o loop não dá a resposta correta. Ao imprimir com `htp.p`, escape valores (`apex_escape.html`) se forem exibidos ao usuário.

Fonte: [NEXT_ROW Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.NEXT_ROW-Function.html), [HAS_MORE_ROWS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.HAS_MORE_ROWS-Function.html)

### APEX_EXEC.GET_COLUMN_POSITION: obter o índice de uma coluna (antes do loop)

Devolve o índice da coluna no resultado a partir do nome/alias. A Oracle recomenda chamar **antes** do loop `NEXT_ROW`, para fazer a busca uma única vez.

```sql
APEX_EXEC.GET_COLUMN_POSITION (
    p_context               IN t_context,
    p_column_name           IN VARCHAR2,
    p_attribute_label       IN VARCHAR2  DEFAULT NULL,
    p_is_required           IN BOOLEAN   DEFAULT FALSE,
    p_data_type             IN VARCHAR2  DEFAULT c_data_type_varchar2,
    p_parent_column_path    IN VARCHAR2  DEFAULT NULL )
    RETURN PLS_INTEGER;
```

| Parâmetro | Descrição |
|---|---|
| `p_context` | Contexto aberto por um `OPEN_*`. |
| `p_column_name` | Nome da coluna. |
| `p_attribute_label` | Rótulo do atributo usado para formatar mensagens de erro (útil em plug-ins: "a coluna configurada em *Label* ..."). |
| `p_is_required` | Se a coluna é obrigatória. |
| `p_data_type` | Tipo de dado requerido. |
| `p_parent_column_path` | Caminho da coluna pai (colunas dentro de array). |

**Retorno:** posição da coluna. **Lança exceção** quando os pré-requisitos de `p_is_required` ou `p_data_type` não são atendidos.

```sql
l_idx_sal := apex_exec.get_column_position(
                 p_context         => l_context,
                 p_column_name     => 'SAL',
                 p_attribute_label => 'Coluna de salário',
                 p_is_required     => true,
                 p_data_type       => apex_exec.c_data_type_number );
```

Pegadinha: o tipo publicado de `p_data_type` é `VARCHAR2` com default `c_data_type_varchar2` (uma constante numérica); passe a constante `c_data_type_*` como nos demais lugares. Validar com `p_is_required`/`p_data_type` é a forma limpa de um plug-in falhar com mensagem clara quando o desenvolvedor configurou a coluna errada.

Fonte: [GET_COLUMN_POSITION Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.GET_COLUMN_POSITION-FUNCTION.html)

### APEX_EXEC.GET_VARCHAR2, GET_NUMBER, GET_DATE, GET_CLOB, GET_TIMESTAMP e demais GET: ler valores da linha corrente

Cada função lê uma coluna da linha corrente, por **índice** (`p_column_idx`) ou por **nome** (`p_column_name`).

```sql
APEX_EXEC.GET_VARCHAR2      ( p_context IN t_context, p_column_idx  IN PLS_INTEGER ) RETURN VARCHAR2;
APEX_EXEC.GET_VARCHAR2      ( p_context IN t_context, p_column_name IN VARCHAR2 )    RETURN VARCHAR2;
APEX_EXEC.GET_NUMBER        ( p_context IN t_context, p_column_idx  IN PLS_INTEGER ) RETURN NUMBER;
APEX_EXEC.GET_NUMBER        ( p_context IN t_context, p_column_name IN VARCHAR2 )    RETURN NUMBER;
APEX_EXEC.GET_DATE          ( p_context IN t_context, p_column_idx  IN PLS_INTEGER ) RETURN DATE;
APEX_EXEC.GET_DATE          ( p_context IN t_context, p_column_name IN VARCHAR2 )    RETURN DATE;
APEX_EXEC.GET_TIMESTAMP     ( p_context IN t_context, p_column_idx  IN PLS_INTEGER ) RETURN TIMESTAMP;
APEX_EXEC.GET_TIMESTAMP     ( p_context IN t_context, p_column_name IN VARCHAR2 )    RETURN TIMESTAMP;
APEX_EXEC.GET_TIMESTAMP_TZ  ( p_context IN t_context, p_column_idx  IN PLS_INTEGER ) RETURN TIMESTAMP WITH TIME ZONE;
APEX_EXEC.GET_TIMESTAMP_TZ  ( p_context IN t_context, p_column_name IN VARCHAR2 )    RETURN TIMESTAMP WITH TIME ZONE;
APEX_EXEC.GET_TIMESTAMP_LTZ ( p_context IN t_context, p_column_idx  IN PLS_INTEGER ) RETURN TIMESTAMP WITH LOCAL TIME ZONE;
APEX_EXEC.GET_TIMESTAMP_LTZ ( p_context IN t_context, p_column_name IN VARCHAR2 )    RETURN TIMESTAMP WITH LOCAL TIME ZONE;
APEX_EXEC.GET_CLOB          ( p_context IN t_context, p_column_idx  IN PLS_INTEGER ) RETURN CLOB;
APEX_EXEC.GET_CLOB          ( p_context IN t_context, p_column_name IN VARCHAR2 )    RETURN CLOB;
APEX_EXEC.GET_BLOB          ( p_context IN t_context, p_column_idx  IN PLS_INTEGER ) RETURN BLOB;
APEX_EXEC.GET_BLOB          ( p_context IN t_context, p_column_name IN VARCHAR2 )    RETURN BLOB;
APEX_EXEC.GET_INTERVALD2S   ( p_context IN t_context, p_column_idx  IN PLS_INTEGER ) RETURN DSINTERVAL_UNCONSTRAINED;
APEX_EXEC.GET_INTERVALD2S   ( p_context IN t_context, p_column_name IN VARCHAR2 )    RETURN DSINTERVAL_UNCONSTRAINED;
APEX_EXEC.GET_INTERVALY2M   ( p_context IN t_context, p_column_idx  IN PLS_INTEGER ) RETURN YMINTERVAL_UNCONSTRAINED;
APEX_EXEC.GET_INTERVALY2M   ( p_context IN t_context, p_column_name IN VARCHAR2 )    RETURN YMINTERVAL_UNCONSTRAINED;
APEX_EXEC.GET_ANYDATA       ( p_context IN t_context, p_column_idx  IN PLS_INTEGER ) RETURN SYS.ANYDATA;
APEX_EXEC.GET_ANYDATA       ( p_context IN t_context, p_column_name IN VARCHAR2 )    RETURN SYS.ANYDATA;
APEX_EXEC.GET_SDO_GEOMETRY  ( p_context IN t_context, p_column_name IN VARCHAR2 )    RETURN MDSYS.SDO_GEOMETRY;  -- só com SDO_GEOMETRY; só por nome
APEX_EXEC.GET_BOOLEAN       ( p_context IN t_context, p_column_idx  IN PLS_INTEGER ) RETURN BOOLEAN;
APEX_EXEC.GET_BOOLEAN       ( p_context IN t_context, p_column_name IN VARCHAR2 )    RETURN BOOLEAN;
```

| Parâmetro | Descrição |
|---|---|
| `p_context` | Contexto obtido com um `OPEN_*`. |
| `p_column_idx` | Índice da coluna (de `GET_COLUMN_POSITION`). |
| `p_column_name` | Nome da coluna. |

**Retorno:** o valor da coluna no tipo da função.

Comportamento e dicas:
- Use a função que corresponde ao tipo da coluna (veja `GET_COLUMN(...).data_type`). Os exemplos oficiais com REST Data Source leem quase tudo com `GET_VARCHAR2`, o que funciona para exibição; para cálculos, defina o tipo no *data profile* e use `GET_NUMBER`/`GET_DATE`.
- Leitura por índice é a forma eficiente dentro do loop; por nome é conveniente em código curto (ex.: `HAS_MORE_ROWS` da doc).
- Depois de `EXECUTE_DML`, os mesmos `GET_*` devolvem valores das colunas marcadas `p_is_returning`.
- Não há `GET_VECTOR` nem `GET_ARRAY` nesta página da doc 26.1.

Fonte: [GET Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.GET-Functions.html)

### APEX_EXEC: metadados do resultado (GET_COLUMN, GET_COLUMNS, GET_COLUMN_COUNT, GET_DATA_TYPE)

```sql
APEX_EXEC.GET_COLUMN (
    p_context       IN t_context,
    p_column_idx    IN PLS_INTEGER )
RETURN t_column;

APEX_EXEC.GET_COLUMNS (
    p_context    IN t_context )
    RETURN t_columns;

APEX_EXEC.GET_COLUMN_COUNT (
    p_context   IN t_context )
RETURN PLS_INTEGER;

-- Signature 1: constante -> nome SQL
APEX_EXEC.GET_DATA_TYPE (
    p_datatype_num      IN apex_exec.t_data_type )
RETURN VARCHAR2;

-- Signature 2: nome SQL -> constante
APEX_EXEC.GET_DATA_TYPE (
    p_datatype      IN VARCHAR2 )
RETURN apex_exec.t_data_type;
```

| Rotina | Retorno |
|---|---|
| `GET_COLUMN` | `t_column` com os metadados da coluna de índice `p_column_idx` (nome, tipo, tamanho, máscara, flags). |
| `GET_COLUMNS` | `t_columns` com todas as colunas do contexto. |
| `GET_COLUMN_COUNT` | Número de colunas do resultado. |
| `GET_DATA_TYPE` (1) | Nome SQL do tipo para a constante `t_data_type`. |
| `GET_DATA_TYPE` (2) | Constante `t_data_type` para o nome SQL do tipo. |

Exemplo próprio: listar estrutura de qualquer contexto (útil para depurar uma REST Data Source):

```sql
FOR i IN 1 .. apex_exec.get_column_count( l_context ) LOOP
    apex_debug.info( 'Coluna %s: %s (%s)',
        i,
        apex_exec.get_column( l_context, i ).name,
        apex_exec.get_data_type( apex_exec.get_column( l_context, i ).data_type ) );
END LOOP;
```

Fonte: [GET_COLUMN Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.GET_COLUMN-FUNCTION.html), [GET_COLUMNS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.GET_COLUMNS-Function.html), [GET_COLUMN_COUNT Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.GET_COLUMN_COUNT-FUNCTION.html), [GET_DATA_TYPE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.GET_DATA_TYPE-Function.html)

### APEX_EXEC.GET_TOTAL_ROW_COUNT: total de linhas do resultado

```sql
APEX_EXEC.GET_TOTAL_ROW_COUNT (
    p_context       IN t_context )
RETURN PLS_INTEGER;
```

Retorna o total de linhas da consulta ou `NULL` se desconhecido. Só é calculado quando o contexto foi aberto com `p_total_row_count => TRUE` (opcionalmente limitado por `p_total_row_count_limit`). Em REST Data Sources, o total só é suportado se a fonte tiver *allow fetch all rows* = Yes.

Uso típico: paginação ("linhas 1–50 de 1.234") num plug-in ou numa região PL/SQL; combine com `p_first_row`/`p_max_rows`. Se só precisa saber se "há mais", `HAS_MORE_ROWS` é mais barato que contar tudo.

Fonte: [GET_TOTAL_ROW_COUNT Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.GET_TOTAL_ROW_COUNT-FUNCTION.html), [OPEN_REST_SOURCE_QUERY Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.OPEN_REST_SOURCE_QUERY-Function.html)

### APEX_EXEC.IS_GROUP_END: control breaks (quebras de grupo) ao iterar

```sql
APEX_EXEC.IS_GROUP_END (
    p_context   IN t_context )
    RETURN BOOLEAN;
```

Indica se a linha corrente encerra um grupo de *control break*: `TRUE` se houve fim de grupo, `FALSE` se não. As colunas de grupo **não podem ser NULL**.

Para usar: declare um `apex_exec.t_control_break`, adicione as colunas de quebra em `l_control_break.control_break_columns` com `ADD_COLUMN`, ordene pelas mesmas colunas (`ADD_ORDER_BY`) e passe `p_control_break` na abertura.

```sql
DECLARE
    l_context       apex_exec.t_context;
    l_columns       apex_exec.t_columns;
    l_control_break apex_exec.t_control_break;
    l_order_bys     apex_exec.t_order_bys;
BEGIN
    apex_exec.add_column( p_columns => l_columns, p_column_name => 'EMPNO' );
    apex_exec.add_column( p_columns => l_columns, p_column_name => 'ENAME' );
    apex_exec.add_column( p_columns => l_columns, p_column_name => 'JOB' );
    apex_exec.add_column( p_columns => l_columns, p_column_name => 'DEPTNO' );

    apex_exec.add_order_by( p_order_bys => l_order_bys, p_column_name => 'JOB',    p_direction => apex_exec.c_order_asc );
    apex_exec.add_order_by( p_order_bys => l_order_bys, p_column_name => 'DEPTNO', p_direction => apex_exec.c_order_asc );

    apex_exec.add_column( p_columns => l_control_break.control_break_columns, p_column_name => 'JOB' );
    apex_exec.add_column( p_columns => l_control_break.control_break_columns, p_column_name => 'DEPTNO' );

    l_context := apex_exec.open_query_context(
        p_location      => apex_exec.c_location_local_db,
        p_sql_query     => 'select * from emp',
        p_columns       => l_columns,
        p_order_bys     => l_order_bys,
        p_control_break => l_control_break );

    WHILE apex_exec.next_row( l_context ) LOOP
        sys.dbms_output.put_line( 'EMPNO: ' || apex_exec.get_number  ( l_context, 'EMPNO' ) );
        sys.dbms_output.put_line( 'ENAME: ' || apex_exec.get_varchar2( l_context, 'ENAME' ) );
        IF apex_exec.is_group_end( p_context => l_context ) THEN
            sys.dbms_output.put_line( 'Is end of Control Break' );
        END IF;
    END LOOP;

    apex_exec.close( l_context );
    RETURN;
EXCEPTION
    WHEN others THEN
        apex_exec.close( l_context );
        RAISE;
END;
```

Fonte: [IS_GROUP_END Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.IS_GROUP_END-Function.html)

### APEX_EXEC.CLOSE: fechar o contexto e liberar recursos (inclusive em exceção)

```sql
APEX_EXEC.CLOSE (
    p_context IN t_context )
```

Fecha o contexto de consulta ou DML e libera cursores e LOBs temporários. A doc insiste: chame **sempre**, ao terminar o trabalho **e** quando ocorrer exceção.

Padrão recomendado (um contexto):

```sql
BEGIN
    l_context := apex_exec.open_...( ... );
    -- trabalho
    apex_exec.close( l_context );
EXCEPTION
    WHEN others THEN
        apex_debug.log_exception;
        apex_exec.close( l_context );
        RAISE;
END;
```

Com dois contextos (padrão de `COPY_DATA` e `SET_ROW_VERSION_CHECKSUM`), feche ambos nos dois caminhos:

```sql
    apex_exec.close( l_dml_context );
    apex_exec.close( l_query_context );
EXCEPTION
    WHEN others THEN
        apex_exec.close( l_dml_context );
        apex_exec.close( l_query_context );
        RAISE;
```

Pegadinhas: não engula a exceção (sempre `RAISE` após fechar). O `CLOSE` no handler é chamado mesmo quando o erro aconteceu dentro do `OPEN_*`, e os exemplos oficiais fazem isso sem checagem prévia. `EXECUTE_PLSQL`/`EXECUTE_REMOTE_PLSQL`/`EXECUTE_REST_SOURCE` não abrem contexto e não precisam de `CLOSE`.

Fonte: [CLOSE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.CLOSE-Procedure.html), [APEX_EXEC](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.html)

### APEX_EXEC.DESCRIBE_QUERY: descobrir colunas e tipos de uma fonte sem executá-la

```sql
-- Signature 1: fonte da região corrente (plug-ins)
APEX_EXEC.DESCRIBE_QUERY (
    p_columns                IN t_columns          DEFAULT c_empty_columns )
    RETURN t_columns;

-- Signature 2: fonte arbitrária
APEX_EXEC.DESCRIBE_QUERY (
    p_location               IN t_location,
    --
    p_table_owner            IN VARCHAR2           DEFAULT NULL,
    p_table_name             IN VARCHAR2           DEFAULT NULL,
    p_match_clause           IN VARCHAR2           DEFAULT NULL,
    p_columns_clause         IN VARCHAR2           DEFAULT NULL,
    p_test_for_rowid         IN BOOLEAN            DEFAULT FALSE,
    --
    p_sql_query              IN VARCHAR2           DEFAULT NULL,
    p_function_body          IN VARCHAR2           DEFAULT NULL,
    p_function_body_language IN t_language         DEFAULT c_lang_plsql,
    --
    p_optimizer_hint         IN VARCHAR2           DEFAULT NULL,
    --
    p_server_static_id       IN VARCHAR2           DEFAULT NULL,
    --
    p_module_static_id       IN VARCHAR2           DEFAULT NULL,
    p_post_process_type      IN t_post_processing  DEFAULT NULL,
    --
    p_columns                IN t_columns          DEFAULT c_empty_columns,
    --
    p_duality_view_static_id IN VARCHAR2           DEFAULT NULL,
    p_json_source_static_id  IN VARCHAR2           DEFAULT NULL )
    RETURN t_columns;
```

| Parâmetro (Signature 2) | Descrição |
|---|---|
| `p_location` | `c_location_*`. |
| `p_table_owner`, `p_table_name` | Tipo TABLE. |
| `p_match_clause`, `p_columns_clause` | Tipo GRAPH. |
| `p_test_for_rowid` | Tentar incluir `ROWID` na consulta descrita. |
| `p_sql_query` | Tipo SQL Query. |
| `p_function_body`, `p_function_body_language` | Função que retorna SQL e sua linguagem. |
| `p_optimizer_hint` | Hint no SELECT mais externo gerado. |
| `p_server_static_id` | Servidor REST Enabled SQL. |
| `p_module_static_id` | REST Data Source. |
| `p_post_process_type` | Pós-processamento do resultado REST. |
| `p_columns` | Colunas a selecionar. |
| `p_duality_view_static_id`, `p_json_source_static_id` | Duality View / JSON source. |

**Retorno:** `t_columns` com nomes e tipos.

```sql
DECLARE
    l_columns apex_exec.t_columns;
BEGIN
    l_columns := apex_exec.describe_query(
        p_location  => apex_exec.c_location_local_db,
        p_sql_query => 'select * from emp' );

    FOR i IN 1 .. l_columns.count LOOP
        htp.p( 'Col #' || i || ': ' || apex_escape.html( l_columns( i ).name ));
    END LOOP;
END;
```

A Signature 1 (`l_columns := apex_exec.describe_query;`) faz o mesmo para a fonte da região do plug-in. Note que `DESCRIBE_QUERY` não abre contexto (não precisa de `CLOSE`).

Fonte: [DESCRIBE_QUERY Function Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.DESCRIBE_QUERY-Function-Signature-1.html), [DESCRIBE_QUERY Function Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.DESCRIBE_QUERY-Function-Signature-2.html)

### APEX_EXEC.OPEN_LOCAL_DML_CONTEXT: gravar no banco local com lost-update detection

Abre um contexto DML sobre o banco local. A "fonte" (tabela, SQL ou função que retorna SQL) define o conjunto de linhas atualizável; opcionalmente as DMLs vão para outra tabela (`p_dml_table_*`) ou para PL/SQL customizado (`p_dml_plsql_code`).

```sql
FUNCTION OPEN_LOCAL_DML_CONTEXT (
    p_columns                 IN t_columns               DEFAULT c_empty_columns,
    p_query_type              IN t_query_type,
    --
    p_table_owner             IN VARCHAR2                DEFAULT NULL,
    p_table_name              IN VARCHAR2                DEFAULT NULL,
    p_where_clause            IN VARCHAR2                DEFAULT NULL,
    --
    p_sql_query               IN VARCHAR2                DEFAULT NULL,
    p_function_body           IN VARCHAR2                DEFAULT NULL,
    p_function_body_language  IN t_language              DEFAULT c_lang_plsql,
    p_plsql_function_body     IN VARCHAR2                DEFAULT NULL,
    --
    p_with_check_option       IN BOOLEAN                 DEFAULT TRUE,
    p_optimizer_hint          IN VARCHAR2                DEFAULT NULL,
    --
    p_dml_table_owner         IN VARCHAR2                DEFAULT NULL,
    p_dml_table_name          IN VARCHAR2                DEFAULT NULL,
    p_dml_plsql_code          IN VARCHAR2                DEFAULT NULL,
    --
    p_lost_update_detection   IN t_lost_update_detection DEFAULT NULL,
    p_lock_rows               IN t_lock_rows             DEFAULT NULL,
    p_lock_plsql_code         IN VARCHAR2                DEFAULT NULL,
    --
    p_sql_parameters          IN t_parameters            DEFAULT c_empty_parameters )
    RETURN t_context;
```

| Parâmetro | Descrição |
|---|---|
| `p_columns` | Colunas DML. |
| `p_query_type` | `c_query_type_table` (tabela), `c_query_type_sql_query` (SQL) ou `c_query_type_func_return_sql` (SQL retornado por função PL/SQL). Obrigatório. |
| `p_table_owner`, `p_table_name`, `p_where_clause` | Para o tipo TABLE. |
| `p_sql_query` | Para o tipo SQL QUERY. |
| `p_function_body` | Função que retorna o SQL; o SQL precisa gerar resultado **atualizável**. |
| `p_function_body_language` | Linguagem de `p_function_body` (`c_lang_*`). |
| `p_plsql_function_body` | Forma antiga (PL/SQL que retorna SQL); nos contextos remotos a doc a marca Deprecated em favor de `p_function_body`. |
| `p_with_check_option` | Default `TRUE`: adiciona "WITH CHECK", então linhas inseridas/alteradas não podem violar o WHERE da fonte. |
| `p_optimizer_hint` | Hints adicionados à DML. |
| `p_dml_table_owner`, `p_dml_table_name` | Se informados, as DMLs são executadas contra esta tabela. |
| `p_dml_plsql_code` | PL/SQL executado **em vez** das DMLs. |
| `p_lost_update_detection` | `c_lost_update_implicit` (APEX calcula checksum dos valores), `c_lost_update_explicit` (uma coluna com `is_checksum`) ou `c_lost_update_none`. |
| `p_lock_rows` | Travar as linhas entre a checagem de lost update e a DML: `c_lock_rows_automatic` (`SELECT ... FOR UPDATE`), `c_lock_rows_plsql` (PL/SQL próprio), `c_lock_rows_none`. |
| `p_lock_plsql_code` | PL/SQL para travar as linhas (a tabela da doc o lista, por engano, como um segundo `p_dml_plsql_code`). |
| `p_sql_parameters` | Binds. |

**Retorno:** o handle do contexto DML.

Exemplo (da doc, com o `p_context` que falta em uma chamada corrigido; o texto da doc diz "REST Enabled SQL", mas a função é local):

```sql
DECLARE
    l_columns        apex_exec.t_columns;
    l_context        apex_exec.t_context;
BEGIN
    -- I. Colunas DML (a ordem define as posições 1..8)
    apex_exec.add_column( p_columns => l_columns, p_column_name => 'EMPNO',
                          p_data_type => apex_exec.c_data_type_number, p_is_primary_key => true );
    apex_exec.add_column( p_columns => l_columns, p_column_name => 'ENAME',
                          p_data_type => apex_exec.c_data_type_varchar2 );
    apex_exec.add_column( p_columns => l_columns, p_column_name => 'JOB',
                          p_data_type => apex_exec.c_data_type_varchar2 );
    apex_exec.add_column( p_columns => l_columns, p_column_name => 'HIREDATE',
                          p_data_type => apex_exec.c_data_type_date );
    apex_exec.add_column( p_columns => l_columns, p_column_name => 'MGR',
                          p_data_type => apex_exec.c_data_type_number );
    apex_exec.add_column( p_columns => l_columns, p_column_name => 'SAL',
                          p_data_type => apex_exec.c_data_type_number );
    apex_exec.add_column( p_columns => l_columns, p_column_name => 'COMM',
                          p_data_type => apex_exec.c_data_type_number );
    apex_exec.add_column( p_columns => l_columns, p_column_name => 'DEPTNO',
                          p_data_type => apex_exec.c_data_type_number );

    -- II. Abrir o contexto
    l_context := apex_exec.open_local_dml_context(
        p_columns               => l_columns,
        p_query_type            => apex_exec.c_query_type_sql_query,
        p_sql_query             => 'select * from emp where deptno = 10',
        p_lost_update_detection => apex_exec.c_lost_update_none );

    -- III. Linha a inserir
    apex_exec.add_dml_row( p_context => l_context, p_operation => apex_exec.c_dml_operation_insert );
    apex_exec.set_value( p_context => l_context, p_column_position => 1, p_value => 4711 );
    apex_exec.set_value( p_context => l_context, p_column_position => 2, p_value => 'DOE' );
    apex_exec.set_value( p_context => l_context, p_column_position => 3, p_value => 'DEVELOPR' );
    apex_exec.set_value( p_context => l_context, p_column_position => 4, p_value => sysdate );
    apex_exec.set_value( p_context => l_context, p_column_position => 6, p_value => 1000 );
    apex_exec.set_value( p_context => l_context, p_column_position => 8, p_value => 10 );

    -- IV. Executar
    apex_exec.execute_dml( p_context => l_context, p_continue_on_error => false );

    apex_exec.close( l_context );
EXCEPTION
    WHEN others THEN
        apex_exec.close( l_context );
        RAISE;
END;
```

Pegadinhas:
- Com `p_with_check_option => TRUE` (default) e fonte `... where deptno = 10`, inserir `DEPTNO = 20` falha: a linha violaria o WHERE da fonte. Isso é proteção (inclusive multi-tenant), não bug.
- Para update/delete é obrigatório ter colunas `p_is_primary_key => true`.
- `APEX_EXEC` local faz sentido quando se quer o mesmo comportamento dos componentes APEX (lost update, check option, status por linha). Para um insert simples num package, um `INSERT` direto é mais claro.

Fonte: [OPEN_LOCAL_DML_CONTEXT Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.OPEN_LOCAL_DML_CONTEXT-Function.html)

### APEX_EXEC.OPEN_REMOTE_DML_CONTEXT: gravar num banco remoto via REST Enabled SQL

Mesma ideia de `OPEN_LOCAL_DML_CONTEXT`, mas executada numa instância ORDS REST Enabled SQL.

```sql
APEX_EXEC.OPEN_REMOTE_DML_CONTEXT (
    p_server_static_id      IN VARCHAR2,
    --
    p_columns                 IN t_columns               DEFAULT c_empty_columns,
    p_query_type              IN t_query_type,
    --
    p_table_owner             IN VARCHAR2                DEFAULT NULL,
    p_table_name              IN VARCHAR2                DEFAULT NULL,
    p_where_clause            IN VARCHAR2                DEFAULT NULL,
    --
    p_sql_query               IN VARCHAR2                DEFAULT NULL,
    p_function_body           IN VARCHAR2                DEFAULT NULL,
    p_function_body_language  IN t_language              DEFAULT c_lang_plsql,
    p_plsql_function_body     IN VARCHAR2                DEFAULT NULL, -- Deprecated:
    --
    p_with_check_option       IN BOOLEAN                 DEFAULT TRUE,
    p_optimizer_hint          IN VARCHAR2                DEFAULT NULL,
    --
    p_dml_table_owner         IN VARCHAR2                DEFAULT NULL,
    p_dml_table_name          IN VARCHAR2                DEFAULT NULL,
    p_dml_plsql_code          IN VARCHAR2                DEFAULT NULL,
    --
    p_lost_update_detection   IN t_lost_update_detection DEFAULT NULL,
    p_lock_rows               IN t_lock_rows             DEFAULT NULL,
    p_lock_plsql_code         IN VARCHAR2                DEFAULT NULL,
    --
    p_sql_parameters          IN t_parameters            DEFAULT c_empty_parameters )
RETURN t_context;
```

Parâmetros: idênticos aos de `OPEN_LOCAL_DML_CONTEXT` (ver seção anterior), mais `p_server_static_id` (Static ID da instância REST Enabled SQL). `p_plsql_function_body` é **Deprecated**: use `p_function_body`.

**Retorno:** handle do contexto DML.

Exemplo (inserção remota; mesmas colunas do exemplo local):

```sql
    l_context := apex_exec.open_remote_dml_context(
        p_server_static_id      => '{remote server static id}',
        p_columns               => l_columns,
        p_query_type            => apex_exec.c_query_type_sql_query,
        p_sql_query             => 'select * from emp where deptno = 10',
        p_lost_update_detection => apex_exec.c_lost_update_none );

    apex_exec.add_dml_row( p_context => l_context, p_operation => apex_exec.c_dml_operation_insert );
    apex_exec.set_value( p_context => l_context, p_column_position => 1, p_value => 4711 );
    apex_exec.set_value( p_context => l_context, p_column_position => 2, p_value => 'DOE' );
    -- ... demais colunas ...
    apex_exec.execute_dml( p_context => l_context, p_continue_on_error => false );
    apex_exec.close( l_context );
EXCEPTION
    WHEN others THEN
        apex_exec.close( l_context );
        RAISE;
```

Ver também o exemplo completo de update com checksum em `SET_ROW_VERSION_CHECKSUM` (que usa contexto remoto).

Fonte: [OPEN_REMOTE_DML_CONTEXT Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.OPEN_REMOTE_DML_CONTEXT-Function.html)

### APEX_EXEC.OPEN_REST_SOURCE_DML_CONTEXT: inserir, alterar e excluir via REST Data Source

Abre um contexto DML sobre uma REST Data Source. A fonte precisa ter operações para pelo menos uma das ações *Insert Rows*, *Update Rows* ou *Delete Rows*.

```sql
FUNCTION OPEN_REST_SOURCE_DML_CONTEXT (
    p_static_id             IN VARCHAR2,
    p_parameters            IN t_parameters            DEFAULT c_empty_parameters,
    --
    p_columns               IN t_columns               DEFAULT c_empty_columns,
    p_lost_update_detection IN t_lost_update_detection DEFAULT NULL,
    --
    p_fetch_rows_parameters IN t_parameters            DEFAULT c_empty_parameters,
    p_fetch_row_parameters  IN t_parameters            DEFAULT c_empty_parameters,
    p_insert_row_parameters IN t_parameters            DEFAULT c_empty_parameters,
    p_update_row_parameters IN t_parameters            DEFAULT c_empty_parameters,
    p_delete_row_parameters IN t_parameters            DEFAULT c_empty_parameters,
    --
    p_array_column_name     IN VARCHAR2                DEFAULT NULL )
    RETURN t_context;
```

(A assinatura publicada tem um `)` sobrando depois de `p_lost_update_detection`; acima está a forma coerente com a lista de parâmetros.)

| Parâmetro | Descrição |
|---|---|
| `p_static_id` | Static ID da REST Data Source. |
| `p_parameters` | Valores de parâmetros da REST Data Source para todo o contexto. |
| `p_columns` | Colunas DML. |
| `p_lost_update_detection` | `c_lost_update_implicit`, `c_lost_update_explicit` ou `c_lost_update_none`. |
| `p_fetch_rows_parameters` | Parâmetros usados só na operação *Fetch Rows*. |
| `p_fetch_row_parameters` | Parâmetros usados só na operação *Fetch Single Row*. |
| `p_insert_row_parameters` | Parâmetros só para a operação de **insert** (a doc troca as descrições de insert e update; o nome manda). |
| `p_update_row_parameters` | Parâmetros só para a operação de **update**. |
| `p_delete_row_parameters` | Parâmetros só para a operação *Delete*. |
| `p_array_column_name` | Coluna-array do *data profile*. |

**Retorno:** handle do contexto DML.

Exemplo próprio completo (DML via REST: inserir dois registros, atualizar um, verificar status HTTP por linha). O exemplo oficial desta página chama por engano `open_web_source_dml_context( p_server_static_id => ...)`; abaixo a chamada correta:

```sql
DECLARE
    l_columns apex_exec.t_columns;
    l_context apex_exec.t_context;
    l_erros   pls_integer := 0;
BEGIN
    -- I. Colunas DML
    apex_exec.add_column( p_columns => l_columns, p_column_name => 'EMPNO',
                          p_data_type => apex_exec.c_data_type_number, p_is_primary_key => true );
    apex_exec.add_column( p_columns => l_columns, p_column_name => 'ENAME',
                          p_data_type => apex_exec.c_data_type_varchar2 );
    apex_exec.add_column( p_columns => l_columns, p_column_name => 'SAL',
                          p_data_type => apex_exec.c_data_type_number );

    -- II. Contexto DML sobre a REST Data Source
    l_context := apex_exec.open_rest_source_dml_context(
        p_static_id             => 'ORDS_EMP',
        p_columns               => l_columns,
        p_lost_update_detection => apex_exec.c_lost_update_none );

    -- III. Linhas
    apex_exec.add_dml_row( p_context => l_context, p_operation => apex_exec.c_dml_operation_insert );
    apex_exec.set_value( p_context => l_context, p_column_name => 'EMPNO', p_value => 4711 );
    apex_exec.set_value( p_context => l_context, p_column_name => 'ENAME', p_value => 'DOE' );
    apex_exec.set_value( p_context => l_context, p_column_name => 'SAL',   p_value => 1000 );

    apex_exec.add_dml_row( p_context => l_context, p_operation => apex_exec.c_dml_operation_insert );
    apex_exec.set_value( p_context => l_context, p_column_name => 'EMPNO', p_value => 4712 );
    apex_exec.set_value( p_context => l_context, p_column_name => 'ENAME', p_value => 'ROE' );
    apex_exec.set_null ( p_context => l_context, p_column_name => 'SAL' );

    apex_exec.add_dml_row( p_context => l_context, p_operation => apex_exec.c_dml_operation_update );
    apex_exec.set_value( p_context => l_context, p_column_name => 'EMPNO', p_value => 7839 );
    apex_exec.set_value( p_context => l_context, p_column_name => 'SAL',   p_value => 9500 );

    -- IV. Executar sem parar no primeiro erro
    apex_exec.execute_dml( p_context => l_context, p_continue_on_error => true );

    -- V. Status por linha (em REST: código HTTP e reason phrase)
    WHILE apex_exec.next_row( l_context ) LOOP
        IF apex_exec.has_error( l_context ) THEN
            l_erros := l_erros + 1;
            apex_debug.error( 'Linha falhou: HTTP %s %s',
                apex_exec.get_dml_status_code( l_context ),
                apex_exec.get_dml_status_message( l_context ) );
        END IF;
    END LOOP;

    apex_exec.close( l_context );

    IF l_erros > 0 THEN
        raise_application_error( -20001, l_erros || ' linha(s) não foram gravadas.' );
    END IF;
EXCEPTION
    WHEN others THEN
        apex_debug.log_exception;
        apex_exec.close( l_context );
        RAISE;
END;
```

Pegadinhas:
- Em REST, `GET_DML_STATUS_CODE` é o **código HTTP** e `GET_DML_STATUS_MESSAGE` a *reason phrase*; em SQL local/remoto são o código e a mensagem ORA- (NULL em sucesso).
- Parâmetros por operação (`p_insert_row_parameters` etc.) servem para APIs que exigem, por exemplo, um header ou query parameter só no POST.
- Hierarquia (arrays aninhados) só funciona se o tipo de REST Source ou o plug-in suportar essas estruturas (ver `ADD_DML_ARRAY_ROW`).

Fonte: [OPEN_REST_SOURCE_DML_CONTEXT Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.OPEN_REST_SOURCE_DML_CONTEXT-Function.html), [GET_DML_STATUS_CODE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.GET_DML_STATUS_CODE-Function.html), [Call Sequences for APEX_EXEC](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/call-sequences-for-APEX_EXEC.html)

### APEX_EXEC.OPEN_WEB_SOURCE_DML_CONTEXT (Deprecated): antiga DML em Web Source Module

**Deprecated**, será removida: use `OPEN_REST_SOURCE_DML_CONTEXT`.

```sql
FUNCTION OPEN_WEB_SOURCE_DML_CONTEXT (
    p_module_static_id      IN VARCHAR2,
    p_parameters            IN t_parameters            DEFAULT c_empty_parameters,
    --
    p_columns               IN t_columns               DEFAULT c_empty_columns,
    p_lost_update_detection IN t_lost_update_detection DEFAULT NULL,
    --
    p_array_column_name     IN VARCHAR2                DEFAULT NULL )
    RETURN t_context;
```

Parâmetros: `p_module_static_id` (módulo com operações de Insert/Update/Delete Rows), `p_parameters`, `p_columns`, `p_lost_update_detection` (`c_lost_update_*`), `p_array_column_name`. Não tem os parâmetros por operação da versão nova. Migração: `open_rest_source_dml_context( p_static_id => ... )`. O exemplo oficial desta página passa `p_server_static_id`, que não existe na assinatura.

Fonte: [OPEN_WEB_SOURCE_DML_CONTEXT Function (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.OPEN_WEB_SOURCE_DML_CONTEXT-Function.html)

### APEX_EXEC.OPEN_DUALITY_VIEW_DML_CONTEXT e OPEN_JSON_SOURCE_DML_CONTEXT: DML em Duality View e JSON source

```sql
APEX_EXEC.OPEN_DUALITY_VIEW_DML_CONTEXT (
    p_static_id             IN VARCHAR2,
    p_array_column_name     IN VARCHAR2                DEFAULT NULL,
    --
    p_columns               IN t_columns               DEFAULT c_empty_columns,
    p_lost_update_detection IN t_lost_update_detection DEFAULT NULL )
    RETURN t_context;

APEX_EXEC.OPEN_JSON_SOURCE_DML_CONTEXT (
    p_static_id             IN VARCHAR2,
    p_array_column_name     IN VARCHAR2                DEFAULT NULL,
    --
    p_columns               IN t_columns               DEFAULT c_empty_columns,
    p_lost_update_detection IN t_lost_update_detection DEFAULT NULL )
    RETURN t_context;
```

| Parâmetro | Descrição |
|---|---|
| `p_static_id` | Static ID da Duality View source / JSON source. |
| `p_array_column_name` | Coluna-array do *data profile*. |
| `p_columns` | Colunas DML. |
| `p_lost_update_detection` | `c_lost_update_*`. |

**Retorno:** handle do contexto DML.

Uso: idêntico ao das outras DMLs (`ADD_COLUMN` → abrir → `ADD_DML_ROW` + `SET_VALUE` → `EXECUTE_DML` → `CLOSE`). O exemplo oficial (Duality View) é o mesmo de `OPEN_LOCAL_DML_CONTEXT`, trocando a abertura por:

```sql
l_context := apex_exec.open_duality_view_dml_context(
    p_static_id             => '{duality view static id}',
    p_columns               => l_columns,
    p_lost_update_detection => apex_exec.c_lost_update_none );
```

A página de JSON source remete ao mesmo exemplo. Para consultar essas fontes, use `OPEN_QUERY_CONTEXT` com `c_location_duality_view`/`c_location_json_source` e os parâmetros `p_duality_view_static_id`/`p_json_source_static_id`.

Fonte: [OPEN_DUALITY_VIEW_DML_CONTEXT Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.OPEN_DUALITY_VIEW_DML_CONTEXT-Function.html), [OPEN_JSON_SOURCE_DML_CONTEXT Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.OPEN_JSON_SOURCE_DML_CONTEXT-Function.html)

### APEX_EXEC.ADD_DML_ROW e CLEAR_DML_ROWS: adicionar e limpar linhas do contexto DML

```sql
APEX_EXEC.ADD_DML_ROW (
    p_context               IN t_context,
    p_operation             IN t_dml_operation );

APEX_EXEC.CLEAR_DML_ROWS (
    p_context               IN t_context )
```

| Parâmetro | Descrição |
|---|---|
| `p_context` | Contexto DML aberto. |
| `p_operation` | `c_dml_operation_insert`, `c_dml_operation_update` ou `c_dml_operation_delete`. |

`ADD_DML_ROW` é chamada depois de abrir o contexto DML e antes de `EXECUTE_DML`, quantas vezes forem necessárias (uma por linha). Todas as colunas da nova linha começam `NULL`; preencha com `SET_VALUE`, `SET_NULL`, `SET_VALUES` e `SET_ROW_VERSION_CHECKSUM`. A linha recém-adicionada vira a **linha corrente** para os `SET_*` seguintes (para voltar a uma linha anterior, `SET_CURRENT_ROW`).

`CLEAR_DML_ROWS` descarta todas as linhas adicionadas, permitindo reaproveitar o mesmo contexto para outro lote.

Para delete, basta adicionar a linha com `c_dml_operation_delete` e setar a(s) coluna(s) de PK.

Fonte: [ADD_DML_ROW Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.ADD_DML_ROW-Procedure.html), [CLEAR_DML_ROWS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.CLEAR_DML_ROWS-Procedure.html)

### APEX_EXEC.SET_VALUE, SET_NULL, SET_VALUES e SET_CURRENT_ROW: preencher as linhas DML

```sql
-- SET_VALUE: 13 assinaturas, cada uma por posição ou por nome
PROCEDURE SET_VALUE( p_context IN t_context, p_column_position IN PLS_INTEGER, p_value IN VARCHAR2 );
PROCEDURE SET_VALUE( p_context IN t_context, p_column_name     IN VARCHAR2,    p_value IN VARCHAR2 );
-- Tipos de p_value nas demais assinaturas:
--   2 NUMBER | 3 DATE | 4 TIMESTAMP | 5 TIMESTAMP WITH TIME ZONE | 6 TIMESTAMP WITH LOCAL TIME ZONE
--   7 DSINTERVAL_UNCONSTRAINED | 8 YMINTERVAL_UNCONSTRAINED | 9 CLOB | 10 BLOB | 11 SYS.ANYDATA
--   12 mdsys.sdo_geometry (só com SDO_GEOMETRY instalado) | 13 BOOLEAN

APEX_EXEC.SET_NULL (
    p_context               IN t_context,
    p_column_position       IN PLS_INTEGER )

APEX_EXEC.SET_NULL (
    p_context               IN t_context,
    p_column_name           IN VARCHAR2 )

APEX_EXEC.SET_VALUES (
    p_context               IN t_context,
    p_source_context        IN t_context )

APEX_EXEC.SET_CURRENT_ROW (
    p_context   IN t_context,
    p_row_idx   IN PLS_INTEGER )
```

| Rotina | O que faz |
|---|---|
| `SET_VALUE` | Define o valor de uma coluna da linha DML corrente; chamada após `ADD_DML_ROW`, por coluna, com `p_column_position` (posição no `t_columns` do contexto) ou `p_column_name`. |
| `SET_NULL` | Define `NULL` numa coluna; útil quando a linha foi inicializada com `SET_VALUES` e uma coluna deve ficar nula. |
| `SET_VALUES` | Copia **todos** os valores da linha corrente de um contexto de consulta (`p_source_context`) para a linha DML corrente: padrão "ler a linha, mudar uma coluna, gravar de volta". |
| `SET_CURRENT_ROW` | Move o ponteiro de linha corrente do contexto DML para `p_row_idx`; os `SET_VALUE` seguintes afetam essa linha. |

Exemplos (corrigido o `p_columns_name` do exemplo oficial):

```sql
apex_exec.set_value( p_context => l_dml_context, p_column_name     => 'SAL',      p_value => 9500 );
apex_exec.set_value( p_context => l_dml_context, p_column_position => 6,          p_value => 9500 );
apex_exec.set_value( p_context => l_dml_context, p_column_name     => 'HIREDATE', p_value => trunc( sysdate ) );
apex_exec.set_null ( p_context => l_dml_context, p_column_position => 6 );
apex_exec.set_null ( p_context => l_dml_context, p_column_name     => 'SAL' );
```

Pegadinhas:
- `p_context` não tem default: esquecê-lo (como em alguns exemplos oficiais) gera erro de compilação.
- A sobrecarga é escolhida pelo tipo de `p_value`; para evitar ambiguidade com literais, use variáveis tipadas ou conversões explícitas (`to_number`, `to_date`).

Fonte: [SET_VALUE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.SET_VALUE-Procedure.html), [SET_NULL Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.SET_NULL-Procedure.html), [SET_VALUES Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.SET_VALUES-Procedure.html), [SET_CURRENT_ROW Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.SET_CURRENT_ROW-Procedure.html)

### APEX_EXEC.SET_ROW_VERSION_CHECKSUM e GET_ROW_VERSION_CHECKSUM: update com detecção de lost update

```sql
APEX_EXEC.SET_ROW_VERSION_CHECKSUM (
    p_context               IN t_context,
    p_checksum              IN VARCHAR2 )

APEX_EXEC.GET_ROW_VERSION_CHECKSUM (
    p_context     IN t_context )
RETURN VARCHAR2;
```

- `GET_ROW_VERSION_CHECKSUM` devolve o checksum de versão da linha corrente de um contexto de consulta: o valor da coluna designada como checksum (`is_checksum`) ou um checksum calculado a partir de todas as colunas.
- `SET_ROW_VERSION_CHECKSUM` define, após `ADD_DML_ROW`, o checksum que a DML usará para detectar se a linha mudou desde a leitura (lost update).

Exemplo da doc (ler `EMPNO=7839` num servidor remoto e atualizar `SAL` com detecção implícita; corrigido `1_dml_context` → `l_dml_context`):

```sql
DECLARE
    l_columns        apex_exec.t_columns;
    l_dml_context    apex_exec.t_context;
    l_query_context  apex_exec.t_context;
BEGIN
    -- I. Colunas (EMPNO PK, ENAME, JOB, HIREDATE, MGR, SAL, COMM, DEPTNO)
    apex_exec.add_column( p_columns => l_columns, p_column_name => 'EMPNO',
                          p_data_type => apex_exec.c_data_type_number, p_is_primary_key => true );
    apex_exec.add_column( p_columns => l_columns, p_column_name => 'ENAME',    p_data_type => apex_exec.c_data_type_varchar2 );
    apex_exec.add_column( p_columns => l_columns, p_column_name => 'JOB',      p_data_type => apex_exec.c_data_type_varchar2 );
    apex_exec.add_column( p_columns => l_columns, p_column_name => 'HIREDATE', p_data_type => apex_exec.c_data_type_date );
    apex_exec.add_column( p_columns => l_columns, p_column_name => 'MGR',      p_data_type => apex_exec.c_data_type_number );
    apex_exec.add_column( p_columns => l_columns, p_column_name => 'SAL',      p_data_type => apex_exec.c_data_type_number );
    apex_exec.add_column( p_columns => l_columns, p_column_name => 'COMM',     p_data_type => apex_exec.c_data_type_number );
    apex_exec.add_column( p_columns => l_columns, p_column_name => 'DEPTNO',   p_data_type => apex_exec.c_data_type_number );

    -- II. Consulta da linha atual
    l_query_context := apex_exec.open_remote_sql_query(
        p_server_static_id => 'DevOps_Remote_SQL',
        p_sql_query        => 'select * from emp where empno = 7839',
        p_columns          => l_columns );

    -- III. Contexto DML com lost update implícito
    l_dml_context := apex_exec.open_remote_dml_context(
        p_server_static_id      => '{remote server static id}',
        p_columns               => l_columns,
        p_query_type            => apex_exec.c_query_type_sql_query,
        p_sql_query             => 'select * from emp where deptno = 10',
        p_lost_update_detection => apex_exec.c_lost_update_implicit );

    IF apex_exec.next_row( p_context => l_query_context ) THEN
        apex_exec.add_dml_row(
            p_context   => l_dml_context,
            p_operation => apex_exec.c_dml_operation_update );

        apex_exec.set_row_version_checksum(
            p_context  => l_dml_context,
            p_checksum => apex_exec.get_row_version_checksum( p_context => l_query_context ) );

        apex_exec.set_values(
            p_context        => l_dml_context,
            p_source_context => l_query_context );

        apex_exec.set_value(
            p_context     => l_dml_context,
            p_column_name => 'SAL',
            p_value       => 8000 );
    ELSE
        raise_application_error( -20000, 'EMPNO #4711 is not present!' );
    END IF;

    apex_exec.execute_dml(
        p_context           => l_dml_context,
        p_continue_on_error => false );

    apex_exec.close( l_dml_context );
    apex_exec.close( l_query_context );
EXCEPTION
    WHEN others THEN
        apex_exec.close( l_dml_context );
        apex_exec.close( l_query_context );
        RAISE;
END;
```

Pegadinhas:
- Os dois contextos precisam ter as **mesmas colunas** para `SET_VALUES` mapear corretamente; o exemplo reutiliza o mesmo `l_columns`.
- `c_lost_update_explicit` exige uma coluna `ADD_COLUMN( ..., p_is_checksum => true )`; com `implicit`, o APEX calcula o checksum dos valores.
- Combine com `p_lock_rows => c_lock_rows_automatic` (local/remoto) para travar a linha entre a checagem e a DML.

Fonte: [SET_ROW_VERSION_CHECKSUM Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.SET_ROW_VERSION_CHECKSUM-Procedure.html), [GET_ROW_VERSION_CHECKSUM Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.GET_ROW_VERSION_CHECKSUM-Function.html)

### APEX_EXEC.EXECUTE_DML: executar as linhas DML e tratar erros por linha (HAS_ERROR, GET_DML_STATUS_CODE, GET_DML_STATUS_MESSAGE)

```sql
APEX_EXEC.EXECUTE_DML (
    p_context               IN t_context,
    p_continue_on_error     IN BOOLEAN DEFAULT FALSE )

APEX_EXEC.HAS_ERROR (
    p_context               IN t_context )
RETURN BOOLEAN;

APEX_EXEC.GET_DML_STATUS_CODE (
    p_context               IN t_context )
RETURN NUMBER;

APEX_EXEC.GET_DML_STATUS_MESSAGE (
    p_context       IN t_context )
RETURN VARCHAR2;
```

| Rotina / parâmetro | Descrição |
|---|---|
| `EXECUTE_DML.p_context` | Contexto DML já aberto, com linhas (`ADD_DML_ROW`) e valores (`SET_VALUES`/`SET_NULL`/`SET_VALUE`). |
| `EXECUTE_DML.p_continue_on_error` | Default `FALSE`. `TRUE` continua executando as linhas restantes após um erro. |
| `HAS_ERROR` | `TRUE` se a DML da linha corrente falhou. |
| `GET_DML_STATUS_CODE` | Local/remoto: código ORA- em erro, `NULL` em sucesso. REST: código HTTP. |
| `GET_DML_STATUS_MESSAGE` | Local/remoto: mensagem ORA- em erro, `NULL` em sucesso. REST: *reason phrase* HTTP. |

Fluxo pós-execução (call sequence): `WHILE apex_exec.next_row( l_context ) LOOP` percorre as linhas processadas; dentro do loop use `HAS_ERROR`, `GET_DML_STATUS_CODE`, `GET_DML_STATUS_MESSAGE` e `GET_*` para valores *RETURNING* (colunas com `p_is_returning => true`, por exemplo uma PK gerada por identity/sequence).

Exemplo próprio (insert local com PK gerada e retorno do ID):

```sql
DECLARE
    l_columns apex_exec.t_columns;
    l_context apex_exec.t_context;
BEGIN
    apex_exec.add_column( p_columns => l_columns, p_column_name => 'ID',
                          p_data_type => apex_exec.c_data_type_number,
                          p_is_primary_key => true, p_is_returning => true );
    apex_exec.add_column( p_columns => l_columns, p_column_name => 'TITULO',
                          p_data_type => apex_exec.c_data_type_varchar2 );

    l_context := apex_exec.open_local_dml_context(
        p_columns               => l_columns,
        p_query_type            => apex_exec.c_query_type_table,
        p_table_name            => 'AVISOS',
        p_lost_update_detection => apex_exec.c_lost_update_none );

    apex_exec.add_dml_row( p_context => l_context, p_operation => apex_exec.c_dml_operation_insert );
    apex_exec.set_value  ( p_context => l_context, p_column_name => 'TITULO', p_value => 'Manutenção sábado' );

    apex_exec.execute_dml( p_context => l_context, p_continue_on_error => false );

    WHILE apex_exec.next_row( l_context ) LOOP
        IF apex_exec.has_error( l_context ) THEN
            apex_debug.error( 'ORA%s: %s',
                apex_exec.get_dml_status_code( l_context ),
                apex_exec.get_dml_status_message( l_context ) );
        ELSE
            apex_debug.info( 'Novo ID: %s', apex_exec.get_number( l_context, 'ID' ) );
        END IF;
    END LOOP;

    apex_exec.close( l_context );
EXCEPTION
    WHEN others THEN
        apex_debug.log_exception;
        apex_exec.close( l_context );
        RAISE;
END;
```

Pegadinhas: com `p_continue_on_error => FALSE`, um erro interrompe o processamento; com `TRUE`, você **precisa** percorrer as linhas e checar `HAS_ERROR`, senão falhas passam despercebidas. A doc não detalha o controle de transação (commit/rollback) feito por `EXECUTE_DML`.

Fonte: [EXECUTE_DML Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.EXECUTE_DML-Procedure.html), [HAS_ERROR Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.HAS_ERROR-Function.html), [GET_DML_STATUS_CODE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.GET_DML_STATUS_CODE-Function.html), [GET_DML_STATUS_MESSAGE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.GET_DML_STATUS_MESSAGE-Function.html), [Call Sequences for APEX_EXEC](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/call-sequences-for-APEX_EXEC.html)

### APEX_EXEC.COPY_DATA: copiar linhas de uma fonte para outra (local, remoto, REST)

Busca todas as linhas do contexto de origem (consulta) e grava no contexto de destino (DML). Serve para mover dados entre fontes diferentes (local → remoto, remoto → REST etc.).

```sql
APEX_EXEC.COPY_DATA (
    p_from_context          IN OUT NOCOPY t_context,
    p_to_context            IN OUT NOCOPY t_context,
    p_operation_column_name IN            VARCHAR2 DEFAULT NULL );
```

| Parâmetro | Descrição |
|---|---|
| `p_from_context` | Contexto de consulta de onde as linhas são lidas. |
| `p_to_context` | Contexto DML onde as linhas são gravadas. |
| `p_operation_column_name` | Coluna do contexto de consulta que diz a operação por linha: `"I"` (insert), `"U"` (update), `"D"` (delete). Sem ela, as linhas são inseridas. |

Limitação: **colunas array não são suportadas** por `COPY_DATA` por enquanto (a doc diz que no futuro serão tratadas como CLOB em JSON).

Exemplo da doc (remoto → remoto):

```sql
DECLARE
    l_columns        apex_exec.t_columns;
    l_dml_context    apex_exec.t_context;
    l_query_context  apex_exec.t_context;
BEGIN
    -- I. Colunas DML (EMPNO PK, ENAME, JOB, HIREDATE, MGR, SAL, COMM, DEPTNO)
    apex_exec.add_column( p_columns => l_columns, p_column_name => 'EMPNO',
                          p_data_type => apex_exec.c_data_type_number, p_is_primary_key => true );
    apex_exec.add_column( p_columns => l_columns, p_column_name => 'ENAME',    p_data_type => apex_exec.c_data_type_varchar2 );
    apex_exec.add_column( p_columns => l_columns, p_column_name => 'JOB',      p_data_type => apex_exec.c_data_type_varchar2 );
    apex_exec.add_column( p_columns => l_columns, p_column_name => 'HIREDATE', p_data_type => apex_exec.c_data_type_date );
    apex_exec.add_column( p_columns => l_columns, p_column_name => 'MGR',      p_data_type => apex_exec.c_data_type_number );
    apex_exec.add_column( p_columns => l_columns, p_column_name => 'SAL',      p_data_type => apex_exec.c_data_type_number );
    apex_exec.add_column( p_columns => l_columns, p_column_name => 'COMM',     p_data_type => apex_exec.c_data_type_number );
    apex_exec.add_column( p_columns => l_columns, p_column_name => 'DEPTNO',   p_data_type => apex_exec.c_data_type_number );

    -- II. Origem
    l_query_context := apex_exec.open_remote_sql_query(
        p_server_static_id => 'DevOps_Remote_SQL',
        p_sql_query        => 'select * from emp',
        p_columns          => l_columns );

    -- III. Destino
    l_dml_context := apex_exec.open_remote_dml_context(
        p_server_static_id => '{remote server static id}',
        p_columns          => l_columns,
        p_query_type       => apex_exec.c_query_type_sql_query,
        p_sql_query        => 'select * from emp' );

    -- IV. Copiar
    apex_exec.copy_data(
        p_from_context => l_query_context,
        p_to_context   => l_dml_context );

    -- V. Fechar
    apex_exec.close( l_dml_context );
    apex_exec.close( l_query_context );
EXCEPTION
    WHEN others THEN
        apex_exec.close( l_dml_context );
        apex_exec.close( l_query_context );
        RAISE;
END;
```

Fonte: [COPY_DATA Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.COPY_DATA-Procedure.html)

### APEX_EXEC.EXECUTE_PLSQL: executar PL/SQL local ou conforme a localização do processo/plug-in

Executa PL/SQL **de acordo com as configurações de localização do processo ou plug-in de processo corrente**: localmente ou num servidor remoto, sem o código precisar saber.

```sql
-- Signature 1: com binds IN OUT
APEX_EXEC.EXECUTE_PLSQL (
    p_plsql_code      IN     VARCHAR2,
    p_auto_bind_items IN     BOOLEAN      DEFAULT TRUE,
    p_sql_parameters  IN OUT t_parameters )

-- Signature 2: só o código
APEX_EXEC.EXECUTE_PLSQL (
    p_plsql_code      IN     VARCHAR2 )
```

| Parâmetro | Descrição |
|---|---|
| `p_plsql_code` | Bloco PL/SQL; executado local ou remotamente conforme o processo/plug-in. |
| `p_auto_bind_items` | Default `TRUE`: faz bind automático de itens de página em IN e OUT. **Se o código referencia binds que não são itens, deve ser `FALSE`.** |
| `p_sql_parameters` | Binds adicionais (IN OUT). Todos são ligados como **VARCHAR2**; NUMBER e DATE são convertidos implicitamente. |

Exemplo da doc (bind de entrada e saída arbitrários):

```sql
DECLARE
    l_sql_parameters apex_exec.t_parameters;
    l_out_value      varchar2(32767);
BEGIN
    apex_exec.add_parameter( l_sql_parameters, 'MY_BIND_IN_VAR',  '{some value}' );
    apex_exec.add_parameter( l_sql_parameters, 'MY_BIND_OUT_VAR', ''             );

    apex_exec.execute_plsql(
        p_plsql_code      => q'#begin :MY_BIND_OUT_VAR := some_plsql( p_parameter => :MY_BIND_IN_VAR ); end;#',
        p_auto_bind_items => false,
        p_sql_parameters  => l_sql_parameters );

    l_out_value := apex_exec.get_parameter_varchar2(
        p_parameters => l_sql_parameters,
        p_name       => 'MY_BIND_OUT_VAR');
END;
```

Signature 2 (itens de página como binds, inclusive de saída):

```sql
BEGIN
    apex_exec.execute_plsql(
        p_plsql_code => q'#begin :P10_NEW_SAL := salary_pkg.raise_sal( p_empno => :P10_EMPNO ); end;#' );
END;
```

Quando usar: em plug-ins de processo que oferecem *Location* (local/remoto), para respeitar a configuração. Num package comum que só roda localmente, chamar o PL/SQL diretamente é mais simples e tipado.

Fonte: [EXECUTE_PLSQL Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.EXECUTE_PLSQL-Procedure-Signature-1.html), [EXECUTE_PLSQL Procedure Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.EXECUTE_PLSQL-Procedure-Signature-2.html)

### APEX_EXEC.EXECUTE_REMOTE_PLSQL: executar PL/SQL num servidor remoto REST Enabled SQL

```sql
-- Signature 1: com binds IN OUT
APEX_EXEC.EXECUTE_REMOTE_PLSQL (
    p_server_static_id     IN     VARCHAR2,
    p_plsql_code           IN     VARCHAR2,
    p_auto_bind_items      IN     BOOLEAN      DEFAULT TRUE,
    p_sql_parameters       IN OUT t_parameters )

-- Signature 2: só servidor e código
APEX_EXEC.EXECUTE_REMOTE_PLSQL (
    p_server_static_id     IN     VARCHAR2,
    p_plsql_code           IN     VARCHAR2 )
```

| Parâmetro | Descrição |
|---|---|
| `p_server_static_id` | Static ID da instância ORDS REST Enabled SQL. |
| `p_plsql_code` | Bloco PL/SQL a executar no remoto. |
| `p_auto_bind_items` | Default `TRUE`: bind automático de itens de página em IN e OUT; `FALSE` obrigatório se houver binds que não são itens. |
| `p_sql_parameters` | (Opcional) binds adicionais, IN OUT. |

Exemplo completo (próprio, baseado no da doc, com validação de credencial e leitura de OUT):

```sql
DECLARE
    l_params  apex_exec.t_parameters;
    l_status  varchar2(4000);
BEGIN
    IF NOT apex_exec.is_remote_sql_auth_valid( p_server_static_id => 'ERP_REMOTO' ) THEN
        raise_application_error( -20010, 'Credenciais do servidor ERP_REMOTO inválidas.' );
    END IF;

    apex_exec.add_parameter( l_params, 'EMPNO',  7839 );
    apex_exec.add_parameter( l_params, 'STATUS', '' );   -- OUT

    apex_exec.execute_remote_plsql(
        p_server_static_id => 'ERP_REMOTO',
        p_plsql_code       => q'#begin :STATUS := folha_pkg.recalcular( p_empno => :EMPNO ); end;#',
        p_auto_bind_items  => false,
        p_sql_parameters   => l_params );

    l_status := apex_exec.get_parameter_varchar2( p_parameters => l_params, p_name => 'STATUS' );
    apex_debug.info( 'Status remoto: %s', l_status );
END;
```

Signature 2 (binds = itens de página):

```sql
BEGIN
    apex_exec.execute_remote_plsql(
        p_server_static_id => '{Static ID of the REST Enabled SQL Service}',
        p_plsql_code       => q'#begin :P10_NEW_SAL := salary_pkg.raise_sal( p_empno => :P10_EMPNO ); end;#' );
END;
```

Pegadinha: com `p_auto_bind_items => TRUE`, binds como `:EMPNO` que não são itens não são resolvidos; desligue o auto-bind e passe-os em `p_sql_parameters`.

Fonte: [EXECUTE_REMOTE_PLSQL Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.EXECUTE_REMOTE_PLSQL-Procedure.html), [EXECUTE_REMOTE_PLSQL Procedure Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.EXECUTE_REMOTE_PLSQL-Procedure-Signature-2.html), [ADD_PARAMETER Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.ADD_ORDER_BY-Procedure.html)

### APEX_EXEC.EXECUTE_REST_SOURCE: chamar uma operação de REST Data Source (POST, GET, DELETE...)

Executa uma operação específica de uma REST Data Source definida em *Shared Components* (URL, autenticação, parâmetros e corpo vêm da definição). Os valores dos parâmetros declarados vão em `t_parameters`; os `OUT` voltam na mesma coleção.

```sql
-- Signature 1: por nome da operação (+ URL pattern se houver mais de uma com o mesmo nome)
APEX_EXEC.EXECUTE_REST_SOURCE (
    p_static_id     IN      VARCHAR2,
    p_operation     IN      VARCHAR2,
    p_url_pattern   IN      VARCHAR2 DEFAULT NULL,
    p_parameters    IN OUT  t_parameters );

-- Signature 2: pelo Static ID da operação
APEX_EXEC.EXECUTE_REST_SOURCE (
    p_static_id             IN            VARCHAR2,
    p_operation_static_id   IN            VARCHAR2,
    p_parameters            IN OUT NOCOPY t_parameters );
```

| Parâmetro | Descrição |
|---|---|
| `p_static_id` | Static ID da REST Data Source. |
| `p_operation` | Nome da operação (ex.: `POST`, `GET`, `DELETE`). |
| `p_url_pattern` | Se existem várias operações com o mesmo nome, o URL pattern (como em *Shared Components*) identifica qual. |
| `p_operation_static_id` | (Signature 2) Static ID da operação dentro da REST Data Source. |
| `p_parameters` | Valores para a API (IN) e, após a chamada, os valores `OUT` recebidos. Headers, URL patterns e outros parâmetros são tipicamente strings: a doc recomenda converter tudo para VARCHAR2 antes de adicionar. |

Exemplo da doc: REST Data Source "ORDS EMP" (Static ID `ORDS_EMP`) sobre um serviço Auto-REST (`ORDS.ENABLE_OBJECT`) da tabela EMP. A operação POST tem o *Request Body Template*:

```
{"empno": "#EMPNO#", "ename": "#ENAME#", "job": "#JOB#", "sal": #SAL#}
```

e os parâmetros:

| Nome | Direção | Tipo | Default |
|---|---|---|---|
| `EMPNO` | IN | Request Body | n/a |
| `ENAME` | IN | Request Body | n/a |
| `SAL` | IN | Request Body | n/a |
| `JOB` | IN | Request Body | n/a |
| `RESPONSE` | OUT | Request Body | n/a |
| `Content-Type` | IN | HTTP Header | application/json |

```sql
DECLARE
    l_params apex_exec.t_parameters;
BEGIN
    apex_exec.add_parameter( l_params, 'ENAME', :P2_ENAME );
    apex_exec.add_parameter( l_params, 'EMPNO', :P2_EMPNO );
    apex_exec.add_parameter( l_params, 'SAL',   :P2_SAL   );
    apex_exec.add_parameter( l_params, 'JOB',   :P2_JOB   );

    apex_exec.execute_rest_source(
        p_static_id  => 'ORDS_EMP',
        p_operation  => 'POST',
        p_parameters => l_params );

    :P2_RESPONSE := apex_exec.get_parameter_clob( l_params, 'RESPONSE' );
END;
```

Variante pela Signature 2 (útil quando há várias operações POST com URL patterns diferentes):

```sql
apex_exec.execute_rest_source(
    p_static_id           => 'ORDS_EMP',
    p_operation_static_id => 'criar_empregado',
    p_parameters          => l_params );
```

Quando usar: ações pontuais (criar, disparar, excluir) numa API já modelada como REST Data Source. Para ler coleções, `OPEN_REST_SOURCE_QUERY`; para DML em lote com status por linha, `OPEN_REST_SOURCE_DML_CONTEXT`.

Pegadinha: itens de página (`:P2_ENAME`) são strings; como a doc recomenda, mantenha tudo VARCHAR2 (um `SAL` numérico vira texto no template sem aspas, `#SAL#`).

Fonte: [EXECUTE_REST_SOURCE Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.EXECUTE_REST_SOURCE-Procedure-Signature-1.html), [EXECUTE_REST_SOURCE Procedure Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.EXECUTE_REST_SOURCE-Procedure-Signature-2.html)

### APEX_EXEC.EXECUTE_WEB_SOURCE (Deprecated): antiga chamada de operação de Web Source Module

**Deprecated**, será removida: use `EXECUTE_REST_SOURCE`.

```sql
APEX_EXEC.EXECUTE_WEB_SOURCE (
    p_module_static_id IN VARCHAR2,
    p_operation        IN VARCHAR2,
    p_url_pattern      IN VARCHAR2         DEFAULT NULL,
    p_parameters       IN OUT t_parameters )
```

Mesma semântica de `EXECUTE_REST_SOURCE` Signature 1 (operação por nome, URL pattern para desambiguar, `p_parameters` IN OUT com os `OUT` do serviço). Migração: `execute_web_source( p_module_static_id => X, ...)` → `execute_rest_source( p_static_id => X, ...)`.

Fonte: [EXECUTE_WEB_SOURCE Procedure (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.EXECUTE_WEB_SOURCE-Procedure.html)

### APEX_EXEC.PURGE_REST_SOURCE_CACHE, PURGE_DUALITY_VIEW_CACHE e PURGE_JSON_SOURCE_CACHE: limpar o cache local

```sql
APEX_EXEC.PURGE_REST_SOURCE_CACHE (
    p_static_id            IN VARCHAR2,
    p_current_session_only IN BOOLEAN DEFAULT FALSE )

APEX_EXEC.PURGE_DUALITY_VIEW_CACHE (
    p_static_id            IN VARCHAR2,
    p_current_session_only IN BOOLEAN DEFAULT FALSE );

APEX_EXEC.PURGE_JSON_SOURCE_CACHE (
    p_static_id            IN VARCHAR2,
    p_current_session_only IN BOOLEAN DEFAULT FALSE );

-- Deprecated: use PURGE_REST_SOURCE_CACHE
APEX_EXEC.PURGE_WEB_SOURCE_CACHE (
    p_module_static_id     IN VARCHAR2,
    p_current_session_only IN BOOLEAN DEFAULT FALSE )
```

| Parâmetro | Descrição |
|---|---|
| `p_static_id` | Static ID da REST Data Source / Duality View source / JSON source (deve existir na aplicação corrente). |
| `p_current_session_only` | Default `FALSE`. `TRUE` limpa só as entradas gravadas para a sessão corrente. |
| `p_module_static_id` | (Deprecated) Static ID do Web Source Module. |

Comportamento: se o cache estiver desligado ou não houver entradas, nada acontece (não dá erro). Duality View e JSON source referem-se a fontes baseadas em REST Enabled SQL.

```sql
BEGIN
    apex_exec.purge_rest_source_cache( p_static_id => 'USGS' );
END;
```

Uso típico: depois de gravar via `EXECUTE_REST_SOURCE`/DML numa API cuja leitura está cacheada, limpar o cache para a próxima consulta refletir a mudança.

Pegadinha: o exemplo oficial de `PURGE_JSON_SOURCE_CACHE` chama `purge_duality_view_cache` (copiado da outra página); para JSON source use `apex_exec.purge_json_source_cache( p_static_id => ... )`.

Fonte: [PURGE_REST_SOURCE_CACHE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.PURGE_REST_SOURCE_CACHE-procedure.html), [PURGE_DUALITY_VIEW_CACHE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.PURGE_DUALITY_VIEW_CACHE-Procedure.html), [PURGE_JSON_SOURCE_CACHE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.PURGE_JSON_SOURCE_CACHE-Procedure.html), [PURGE_WEB_SOURCE_CACHE Procedure (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.PURGE_WEB_SOURCE_CACHE-Procedure.html)

### APEX_EXEC.IS_REMOTE_SQL_AUTH_VALID: testar credenciais de um servidor REST Enabled SQL

```sql
function IS_REMOTE_SQL_AUTH_VALID (
    p_server_static_id  IN    VARCHAR2 )
RETURN BOOLEAN;
```

Retorna `TRUE` se as credenciais atuais funcionam na instância REST Enabled SQL indicada, `FALSE` caso contrário. Combina com `APEX_CREDENTIAL.SET_SESSION_CREDENTIALS` para testar credenciais informadas pelo usuário só para a sessão.

Exemplo (o da doc chama o nome antigo `check_rest_enabled_sql_auth`; use o nome documentado da função):

```sql
BEGIN
    apex_credential.set_session_credentials(
        p_application_id  => {application-id},
        p_credential_name => 'SCOTT_Credentials',
        p_username        => 'SCOTT',
        p_password        => '' );

    IF apex_exec.is_remote_sql_auth_valid( p_server_static_id => 'My_Remote_SQL' ) THEN
        sys.dbms_output.put_line( 'credentials are correct!' );
    ELSE
        sys.dbms_output.put_line( 'credentials are NOT correct!' );
    END IF;
END;
```

(O exemplo oficial escreve `apex_credentials` e chama `check_rest_enabled_sql_auth`; o package documentado é `APEX_CREDENTIAL`, cuja `SET_SESSION_CREDENTIALS` está no capítulo APEX_CREDENTIAL.)

Fonte: [IS_REMOTE_SQL_AUTH_VALID Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.IS_REMOTE_SQL_AUTH_VALID-Function.html)

### APEX_EXEC.ENQUOTE_LITERAL e ENQUOTE_NAME: montar SQL dinâmico seguro para Oracle e MySQL remotos

```sql
APEX_EXEC.ENQUOTE_LITERAL (
    p_str               IN VARCHAR2,
    p_for_database      IN t_database_type DEFAULT NULL )
RETURN VARCHAR2;

APEX_EXEC.ENQUOTE_NAME (
    p_str               IN VARCHAR2,
    p_for_database      IN t_database_type DEFAULT NULL )
RETURN VARCHAR2;
```

| Parâmetro | Descrição |
|---|---|
| `p_str` | Literal (ENQUOTE_LITERAL) ou nome de objeto (ENQUOTE_NAME). |
| `p_for_database` | `c_database_oracle` ou `c_database_mysql`. Omitido: usa o banco alvo da região em execução. |

Funcionam para todos os tipos de banco suportados pelo APEX via REST Enabled SQL. `ENQUOTE_LITERAL` põe aspas simples e escapa as internas; `ENQUOTE_NAME` põe o delimitador de identificador do banco (aspas duplas no Oracle, crase no MySQL).

```sql
DECLARE
    l_txt varchar2(32767);
BEGIN
    l_txt := apex_exec.enquote_literal( p_str => q'#O'Neil \n#', p_for_database => apex_exec.c_database_oracle );
    -- 'O''Neil \n'
    l_txt := apex_exec.enquote_literal( p_str => q'#O'Neil \n#', p_for_database => apex_exec.c_database_mysql );
    -- 'O''Neil \\n'   (MySQL também escapa a barra invertida)
    l_txt := apex_exec.enquote_name( p_str => 'emp', p_for_database => apex_exec.c_database_oracle );
    -- "emp"
    l_txt := apex_exec.enquote_name( p_str => 'emp', p_for_database => apex_exec.c_database_mysql );
    -- `emp`
END;
```

Quando usar: plug-ins que geram SQL para fontes remotas de banco variável. Preferir sempre binds (`p_sql_parameters`) a literais; use `ENQUOTE_*` quando precisar mesmo concatenar. Os exemplos oficiais trazem literais `q'...'` malformados (`q'emp'`) e constantes sem o prefixo `apex_exec.`; acima estão corrigidos.

Fonte: [ENQUOTE_LITERAL Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.ENQUOTE_LITERAL-Function.html), [ENQUOTE_NAME Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.ENQUOTE_NAME-Function.html)

### APEX_EXEC: arrays aninhados em REST Data Sources (OPEN_ARRAY, NEXT_ARRAY_ROW, HAS_MORE_ARRAY_ROWS, CLOSE_ARRAY, SET_ARRAY_CURRENT_ROW)

Quando o *data profile* de uma REST Data Source tem colunas do tipo array (JSON aninhado, ex.: pedido com itens), dá para navegar pelos elementos de cada linha. **Atualmente só suportado em contextos sobre REST Data Sources.**

```sql
APEX_EXEC.OPEN_ARRAY (                       -- Signature 1: por nome
    p_context               IN t_context,
    p_column_name           IN VARCHAR2 )

APEX_EXEC.OPEN_ARRAY (                       -- Signature 2: por posição
    p_context               IN t_context,
    p_column_position       IN PLS_INTEGER )

APEX_EXEC.NEXT_ARRAY_ROW (
    p_context   IN t_context )
    RETURN BOOLEAN;

APEX_EXEC.HAS_MORE_ARRAY_ROWS (
    p_context   IN t_context )
    RETURN BOOLEAN;

APEX_EXEC.CLOSE_ARRAY (
    p_context               IN t_context )

APEX_EXEC.SET_ARRAY_CURRENT_ROW (
    p_context               IN t_context,
    p_current_row_idx       IN PLS_INTEGER )
```

| Rotina | Comportamento |
|---|---|
| `OPEN_ARRAY` | Entra no array da coluna indicada e posiciona o cursor **antes** do primeiro elemento, para que `NEXT_ARRAY_ROW` aponte para o primeiro. |
| `NEXT_ARRAY_ROW` | Avança uma linha dentro do array; `TRUE` se avançou, `FALSE` no fim. Erro se chamada fora de uma coluna array. |
| `HAS_MORE_ARRAY_ROWS` | Se o array corrente tem mais filhos; erro se fora de array. |
| `CLOSE_ARRAY` | Fecha o array corrente e volta ao elemento pai; os `SET_VALUE`/`GET_*` seguintes voltam a atuar no pai/linha raiz. Só após `ADD_DML_ARRAY_ROW` ou `OPEN_ARRAY`; erro se o cursor já estiver na raiz. |
| `SET_ARRAY_CURRENT_ROW` | Posiciona o cursor na linha `p_current_row_idx` do array corrente. |

Exemplo da doc (ler linhas e dois arrays, `SOURCES` e `REPORTERS`, de cada linha):

```sql
DECLARE
    l_context apex_exec.t_context;
BEGIN
    l_context := apex_exec.open_rest_source_query(
        p_static_id => '{REST Source static ID}',
        p_max_rows  => 1000 );

    <<rest_rows_loop>>
    WHILE apex_exec.next_row( l_context ) LOOP
        sys.dbms_output.put_line( 'TITLE: ' || apex_exec.get_varchar2( l_context, 'TITLE' ) );

        apex_exec.open_array( p_context => l_context, p_column_name => 'SOURCES' );
        <<sources_loop>>
        WHILE apex_exec.next_array_row( l_context ) LOOP
            sys.dbms_output.put_line( '-- ID:   ' || apex_exec.get_varchar2( l_context, 'SOURCE_ID'   ) );
            sys.dbms_output.put_line( '-- NAME: ' || apex_exec.get_varchar2( l_context, 'SOURCE_NAME' ) );
        END LOOP sources_loop;
        apex_exec.close_array( l_context );

        apex_exec.open_array( p_context => l_context, p_column_name => 'REPORTERS' );
        <<reporters_loop>>
        WHILE apex_exec.next_array_row( l_context ) LOOP
            sys.dbms_output.put_line( '-- NAME: ' || apex_exec.get_varchar2( l_context, 'REPORTER_NAME' ) );
        END LOOP reporters_loop;
        apex_exec.close_array( l_context );
    END LOOP rest_rows_loop;

    apex_exec.close( l_context );
EXCEPTION
    WHEN others THEN
        apex_exec.close( l_context );
        RAISE;
END;
```

Pegadinhas: sempre feche o array (`CLOSE_ARRAY`) antes de abrir outro ou de ir para a próxima linha; `GET_*` dentro do array lê as colunas filhas pelo nome delas. Alternativa: `p_array_column_name` em `OPEN_REST_SOURCE_QUERY` para tratar um único array como as linhas do resultado.

Fonte: [OPEN_ARRAY Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.OPEN_ARRAY-Procedure-Signature-1.html), [OPEN_ARRAY Procedure Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.OPEN_ARRAY-Procedure-Signature-2.html), [NEXT_ARRAY_ROW Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.NEXT_ARRAY_ROW-Function.html), [HAS_MORE_ARRAY_ROWS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.HAS_MORE_ARRAY_ROWS-Function.html), [CLOSE_ARRAY Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.CLOSE_ARRAY-Procedure.html), [SET_ARRAY_CURRENT_ROW Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.SET_ARRAY_CURRENT_ROW-Procedure.html)

### APEX_EXEC.ADD_DML_ARRAY_ROW: DML hierárquica (pai e filhos) em REST Data Sources

```sql
APEX_EXEC.ADD_DML_ARRAY_ROW (
    p_context               IN t_context,
    p_column_name           IN VARCHAR2        DEFAULT NULL,
    p_column_position       IN PLS_INTEGER,
    p_operation             IN t_dml_operation DEFAULT NULL )
```

| Parâmetro | Descrição |
|---|---|
| `p_context` | Contexto DML de REST Data Source. |
| `p_column_name` | Coluna array (deve existir no contexto) em que adicionar a linha. Omitida: usa o array corrente. |
| `p_column_position` | Posição da coluna no contexto DML. |
| `p_operation` | `c_dml_operation_*`. Omitido: a linha filha **herda** a operação do pai. |

Comportamento:
- Adiciona uma linha filha no array corrente ou no indicado; o cursor passa para esse novo elemento e os `SET_VALUE` seguintes atuam nos atributos dele.
- **Só em contextos DML de REST Data Sources**, e só se o tipo de REST Source ou plug-in lidar com estruturas hierárquicas. DML local ou via REST Enabled SQL **ignora** colunas array.
- O array informado deve ser filho **direto** do array corrente: não há sintaxe de caminho nem salto para outra posição da hierarquia.

Exemplo da doc (pedido com itens, condensado):

```sql
DECLARE
    l_columns apex_exec.t_columns;
    l_context apex_exec.t_context;
BEGIN
    -- colunas da linha
    apex_exec.add_column( p_columns => l_columns, p_column_name => 'CUSTOMER_NAME', p_data_type => apex_exec.c_data_type_varchar2 );
    apex_exec.add_column( p_columns => l_columns, p_column_name => 'ORDER_DATE',    p_data_type => apex_exec.c_data_type_date );
    apex_exec.add_column( p_columns => l_columns, p_column_name => 'ORDER_ITEMS',   p_data_type => apex_exec.c_data_type_array );
    -- colunas filhas do array ORDER_ITEMS
    apex_exec.add_column( p_columns => l_columns, p_column_name => 'PRODUCT_ID',     p_data_type => apex_exec.c_data_type_number,   p_parent_column_path => 'ORDER_ITEMS' );
    apex_exec.add_column( p_columns => l_columns, p_column_name => 'PRODUCT_NAME',   p_data_type => apex_exec.c_data_type_varchar2, p_parent_column_path => 'ORDER_ITEMS' );
    apex_exec.add_column( p_columns => l_columns, p_column_name => 'UNIT_PRICE',     p_data_type => apex_exec.c_data_type_number,   p_parent_column_path => 'ORDER_ITEMS' );
    apex_exec.add_column( p_columns => l_columns, p_column_name => 'AMOUNT_ORDERED', p_data_type => apex_exec.c_data_type_number,   p_parent_column_path => 'ORDER_ITEMS' );

    l_context := apex_exec.open_rest_source_dml_context(
        p_columns   => l_columns,
        p_static_id => '{module static id}' );

    -- pedido 1
    apex_exec.add_dml_row( p_context => l_context, p_operation => apex_exec.c_dml_operation_insert );
    apex_exec.set_value( p_context => l_context, p_column_name => 'CUSTOMER_NAME', p_value => 'John Doe' );
    apex_exec.set_value( p_context => l_context, p_column_name => 'ORDER_DATE',    p_value => date'2024-03-15' );

    -- item 1.1
    apex_exec.add_dml_array_row( p_context => l_context, p_operation => apex_exec.c_dml_operation_insert,
                                 p_column_name => 'ORDER_ITEMS' );
    apex_exec.set_value( p_context => l_context, p_column_name => 'PRODUCT_ID',     p_value => 100 );
    apex_exec.set_value( p_context => l_context, p_column_name => 'AMOUNT_ORDERED', p_value => 10 );

    -- item 1.2 (mesmo array corrente; operação herdada)
    apex_exec.add_dml_array_row( p_context => l_context );
    apex_exec.set_value( p_context => l_context, p_column_name => 'PRODUCT_ID',     p_value => 101 );
    apex_exec.set_value( p_context => l_context, p_column_name => 'AMOUNT_ORDERED', p_value => 10 );

    -- voltar ao primeiro item e corrigir a quantidade
    apex_exec.set_array_current_row( p_context => l_context, p_current_row_idx => 1 );
    apex_exec.set_value( p_context => l_context, p_column_name => 'AMOUNT_ORDERED', p_value => 20 );

    apex_exec.execute_dml( p_context => l_context, p_continue_on_error => false );
    apex_exec.close( l_context );
EXCEPTION
    WHEN others THEN
        apex_exec.close( l_context );
        RAISE;
END;
```

Na doc, o exemplo também adiciona um segundo pedido com `ADD_DML_ROW` diretamente após os itens: o novo `ADD_DML_ROW` volta o cursor para o nível raiz.

Pegadinha: a assinatura publicada mostra `p_column_position` **sem default**, mas o exemplo oficial chama `add_dml_array_row` sem ele. Trate como divergência da doc; se der erro de compilação, informe a posição ou use a forma que compilar no seu ambiente.

Fonte: [ADD_DML_ARRAY_ROW Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.ADD_DML_ARRAY_ROW-Procedure.html)

### APEX_EXEC: checksum e operação de elementos de array para plug-ins de REST Data Source (GET/SET_ARRAY_ROW_VERSION_CHECKSUM, GET_ARRAY_ROW_DML_OPERATION)

```sql
APEX_EXEC.SET_ARRAY_ROW_VERSION_CHECKSUM (
    p_context               IN t_context,
    p_checksum              IN VARCHAR2 );

APEX_EXEC.GET_ARRAY_ROW_VERSION_CHECKSUM (
    p_context               IN t_context )
    RETURN VARCHAR2;

APEX_EXEC.GET_ARRAY_ROW_DML_OPERATION (
    p_context               IN t_context )
    RETURN t_dml_operation;
```

| Rotina | Descrição |
|---|---|
| `SET_ARRAY_ROW_VERSION_CHECKSUM` | Define o checksum de lost update do elemento de array corrente. |
| `GET_ARRAY_ROW_VERSION_CHECKSUM` | Lê o checksum do elemento de array corrente. |
| `GET_ARRAY_ROW_DML_OPERATION` | Devolve a operação DML (`c_dml_operation_*`) do elemento de array corrente. |

As três só funcionam com o cursor **dentro** de uma coluna array (caso contrário, erro). São destinadas a **plug-ins de REST Data Source** que executam ações por elemento de array: o plug-in lê a operação e o checksum de cada item para decidir que chamada HTTP fazer.

Fonte: [SET_ARRAY_ROW_VERSION_CHECKSUM Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.SET_ARRAY_ROW_VERSION_CHECKSUM-Procedure.html), [GET_ARRAY_ROW_VERSION_CHECKSUM Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.GET_ARRAY_ROW_VERSION_CHECKSUM-Function.html), [GET_ARRAY_ROW_DML_OPERATION Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.GET_ARRAY_ROW_DML_OPERATION-Function.html)

### APEX_EXEC falha fora de uma sessão APEX (SQL*Plus, job, trigger)

**Sintoma:** chamadas a `APEX_EXEC` (abrir contexto, executar REST Source) falham quando executadas de um script SQL, job do scheduler ou bloco anônimo fora do APEX.
**Causa:** todas as rotinas de `APEX_EXEC` exigem uma sessão APEX existente (de onde vêm a aplicação corrente, os Static IDs de REST Data Sources/servidores e as credenciais).
**Correção:** criar a sessão antes com `APEX_SESSION`, por exemplo `apex_session.create_session( 100, 1, 'ADMIN' );` (aplicação, página, usuário), e então chamar `APEX_EXEC`.
**Prevenção:** em jobs e packages chamados fora do APEX, encapsular a criação da sessão no início do processamento.

Fonte: [APEX_EXEC](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.html), [Call Sequences for APEX_EXEC](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/call-sequences-for-APEX_EXEC.html)

### APEX_EXEC: cursores abertos / LOBs temporários acumulando (contexto não fechado)

**Sintoma:** recursos do servidor (cursores de banco e LOBs temporários) ficam presos na sessão depois que o processamento termina, especialmente após erros.
**Causa:** o contexto aberto por `OPEN_*` não foi fechado, em geral porque uma exceção saiu do bloco antes de `APEX_EXEC.CLOSE`.
**Correção:** chamar `apex_exec.close( l_context )` no fim do bloco **e** num `EXCEPTION WHEN others THEN ... apex_exec.close( l_context ); RAISE;`. Com vários contextos, fechar todos nos dois caminhos.
**Prevenção:** usar sempre o padrão de handler da doc; revisar todo `OPEN_*` em busca do `CLOSE` correspondente.

Fonte: [CLOSE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.CLOSE-Procedure.html), [APEX_EXEC](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.html)

### APEX_EXEC: bind variable que não é item de página não recebe valor (EXECUTE_PLSQL / EXECUTE_REMOTE_PLSQL)

**Sintoma:** um bind como `:MY_BIND_IN_VAR` ou `:EMPNO` no bloco PL/SQL fica nulo ou dá erro de bind, embora tenha sido adicionado com `ADD_PARAMETER`.
**Causa:** com `p_auto_bind_items => TRUE` (default), o APEX trata os binds como itens de página; a doc diz que, se o código usa binds que não são itens, o parâmetro **precisa** ser `FALSE`.
**Correção:** chamar com `p_auto_bind_items => false` e passar todos os binds em `p_sql_parameters`.
**Prevenção:** usar nomes de bind distintos dos itens e decidir explicitamente o modo de bind.

Fonte: [EXECUTE_PLSQL Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.EXECUTE_PLSQL-Procedure-Signature-1.html), [EXECUTE_REMOTE_PLSQL Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.EXECUTE_REMOTE_PLSQL-Procedure.html)

### APEX_EXEC.EXECUTE_PLSQL: NUMBER ou DATE chegam como texto / conversão errada de data

**Sintoma:** valores numéricos ou de data passados em `p_sql_parameters` chegam ao PL/SQL convertidos de forma inesperada (formato de data ou separador decimal errado).
**Causa:** `EXECUTE_PLSQL` faz bind de **todos** os `p_sql_parameters` como VARCHAR2; NUMBER e DATE são convertidos implicitamente (dependendo de NLS).
**Correção:** converter explicitamente com máscara antes de `ADD_PARAMETER` (ex.: `to_char( l_data, 'YYYY-MM-DD' )`) e converter de volta no bloco (`to_date( :P_DATA, 'YYYY-MM-DD' )`).
**Prevenção:** tratar todos os binds de `EXECUTE_PLSQL` como texto com formato fixo.

Fonte: [EXECUTE_PLSQL Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.EXECUTE_PLSQL-Procedure-Signature-1.html)

### APEX_EXEC.OPEN_REST_SOURCE_QUERY: GET_TOTAL_ROW_COUNT retorna NULL

**Sintoma:** `GET_TOTAL_ROW_COUNT` devolve `NULL` mesmo com dados.
**Causa:** o total só é calculado se o contexto foi aberto com `p_total_row_count => TRUE`; em REST Data Sources, isso só é suportado quando o atributo *allow fetch all rows* da fonte é Yes. Fora disso o total é "desconhecido" (NULL).
**Correção:** abrir com `p_total_row_count => true` e, em REST, habilitar *allow fetch all rows* na REST Data Source; ou usar `HAS_MORE_ROWS` após o loop se só precisa saber se há mais páginas.
**Prevenção:** não montar paginação "X de Y" sobre REST sem confirmar a capacidade da fonte.

Fonte: [GET_TOTAL_ROW_COUNT Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.GET_TOTAL_ROW_COUNT-FUNCTION.html), [OPEN_REST_SOURCE_QUERY Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.OPEN_REST_SOURCE_QUERY-Function.html)

### APEX_EXEC.HAS_MORE_ROWS retorna NULL ou resultado errado

**Sintoma:** `HAS_MORE_ROWS` devolve `NULL` ou não reflete a existência de mais linhas.
**Causa:** a função só tem valor **depois** que o loop de `NEXT_ROW` termina, e devolve `NULL` quando a detecção de "mais dados" não foi solicitada (sem `p_max_rows`).
**Correção:** abrir com `p_max_rows` e chamar `HAS_MORE_ROWS` somente após sair do `WHILE apex_exec.next_row(...)`.

Fonte: [HAS_MORE_ROWS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.HAS_MORE_ROWS-Function.html)

### APEX_EXEC.GET_COLUMN_POSITION lança exceção ao abrir o plug-in

**Sintoma:** erro ao obter a posição de uma coluna, antes de qualquer linha ser lida.
**Causa:** `GET_COLUMN_POSITION` lança exceção quando a coluna marcada `p_is_required => TRUE` não existe no resultado ou quando o tipo não corresponde a `p_data_type`.
**Correção:** conferir o nome/alias da coluna na fonte (use `DESCRIBE_QUERY` ou `GET_COLUMNS`) e o tipo no *data profile*; informar `p_attribute_label` para a mensagem indicar qual atributo do plug-in está errado.

Fonte: [GET_COLUMN_POSITION Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.GET_COLUMN_POSITION-FUNCTION.html)

### APEX_EXEC DML: insert/update rejeitado porque a linha sai do WHERE da fonte (p_with_check_option)

**Sintoma:** DML local ou remota falha ao inserir/alterar uma linha cujos valores não satisfazem o WHERE da fonte (ex.: fonte `where deptno = 10`, linha com `DEPTNO = 20`).
**Causa:** `p_with_check_option` é `TRUE` por default em `OPEN_LOCAL_DML_CONTEXT` e `OPEN_REMOTE_DML_CONTEXT`: linhas inseridas ou atualizadas não podem violar a cláusula WHERE da fonte.
**Correção:** ajustar a fonte para abranger as linhas a gravar, ou usar `p_with_check_option => false` conscientemente (ou apontar a DML para outra tabela com `p_dml_table_name`).
**Prevenção:** manter o check option ligado quando a fonte implementa isolamento (ex.: filtro por empresa); é uma proteção.

Fonte: [OPEN_LOCAL_DML_CONTEXT Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.OPEN_LOCAL_DML_CONTEXT-Function.html), [OPEN_REMOTE_DML_CONTEXT Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.OPEN_REMOTE_DML_CONTEXT-Function.html)

### APEX_EXEC.EXECUTE_DML com p_continue_on_error => TRUE: erros passam despercebidos

**Sintoma:** algumas linhas não foram gravadas, mas o bloco terminou sem exceção.
**Causa:** com `p_continue_on_error => TRUE`, `EXECUTE_DML` segue para as linhas restantes após um erro; os erros ficam registrados por linha.
**Correção:** após `EXECUTE_DML`, percorrer `WHILE apex_exec.next_row( l_context )` e checar `HAS_ERROR`, lendo `GET_DML_STATUS_CODE`/`GET_DML_STATUS_MESSAGE` (ORA- em SQL, HTTP em REST); decidir se levanta erro.
**Prevenção:** usar `FALSE` (default) quando o lote deve ser "tudo ou nada"; usar `TRUE` só com o loop de verificação.

Fonte: [EXECUTE_DML Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.EXECUTE_DML-Procedure.html), [HAS_ERROR Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.HAS_ERROR-Function.html), [Call Sequences for APEX_EXEC](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/call-sequences-for-APEX_EXEC.html)

### APEX_EXEC.COPY_DATA ou DML local/remota ignora colunas array

**Sintoma:** ao copiar ou gravar dados de uma REST Data Source com colunas aninhadas, os elementos dos arrays não chegam ao destino.
**Causa:** `COPY_DATA` não suporta colunas array atualmente; DML em tabela local ou via REST Enabled SQL **ignora** colunas array; hierarquia só é suportada em DML de REST Data Source cujo tipo/plug-in saiba lidar com ela.
**Correção:** para destinos relacionais, ler o array com `OPEN_ARRAY`/`NEXT_ARRAY_ROW` e gravar os filhos numa tabela própria; para destino REST, usar `ADD_DML_ARRAY_ROW`.

Fonte: [COPY_DATA Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.COPY_DATA-Procedure.html), [ADD_DML_ARRAY_ROW Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.ADD_DML_ARRAY_ROW-Procedure.html)

### APEX_EXEC: erro "chamado fora de uma coluna array" em NEXT_ARRAY_ROW, CLOSE_ARRAY ou GET_ARRAY_*

**Sintoma:** erro ao chamar `NEXT_ARRAY_ROW`, `HAS_MORE_ARRAY_ROWS`, `CLOSE_ARRAY`, `SET/GET_ARRAY_ROW_VERSION_CHECKSUM` ou `GET_ARRAY_ROW_DML_OPERATION`.
**Causa:** essas rotinas só funcionam com o cursor **dentro** de uma coluna array (após `OPEN_ARRAY` ou `ADD_DML_ARRAY_ROW`); `CLOSE_ARRAY` dá erro se o cursor já estiver na raiz. Além disso, arrays só são suportados em contextos de REST Data Sources.
**Correção:** abrir o array antes (`OPEN_ARRAY`/`ADD_DML_ARRAY_ROW`), fechar uma única vez por abertura e não usar essas rotinas em contextos locais/remotos.

Fonte: [NEXT_ARRAY_ROW Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.NEXT_ARRAY_ROW-Function.html), [CLOSE_ARRAY Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.CLOSE_ARRAY-Procedure.html), [OPEN_ARRAY Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.OPEN_ARRAY-Procedure-Signature-1.html)

### APEX_EXEC: exemplos oficiais que não compilam (erros da documentação 26.1)

**Sintoma:** copiar um exemplo do capítulo APEX_EXEC gera PLS-00306 (número/tipo de argumentos errado), PLS-00103 ou identificador inválido.
**Causa:** vários exemplos da doc 26.1 têm erros:
- `ADD_COLUMN`: chama `open_rest_source_query( p_module_static_id => ...)`; o parâmetro é `p_static_id`. Falta vírgula depois de `p_columns`/`p_filters` (também em `ADD_FILTER`).
- `ADD_ORDER_BY`: usa `open_web_source_query` (Deprecated).
- `OPEN_REST_SOURCE_DML_CONTEXT`: chama `open_web_source_dml_context( p_server_static_id => ...)`; deveria ser `open_rest_source_dml_context( p_static_id => ...)`. A assinatura publicada tem um `)` sobrando, e as descrições de `p_insert_row_parameters`/`p_update_row_parameters` estão trocadas.
- `OPEN_WEB_SOURCE_DML_CONTEXT`: passa `p_server_static_id`, inexistente (é `p_module_static_id`).
- `OPEN_LOCAL_DML_CONTEXT`, `OPEN_REMOTE_DML_CONTEXT`, `OPEN_WEB_SOURCE_DML_CONTEXT`, `OPEN_DUALITY_VIEW_DML_CONTEXT`: uma chamada `set_value` sem `p_context`.
- `SET_VALUE`: `p_columns_name` (o nome é `p_column_name`). `SET_ROW_VERSION_CHECKSUM`: `1_dml_context` em vez de `l_dml_context`.
- `IS_REMOTE_SQL_AUTH_VALID`: o exemplo chama `apex_exec.check_rest_enabled_sql_auth`.
- `PURGE_JSON_SOURCE_CACHE`: o exemplo chama `purge_duality_view_cache`.
- `ENQUOTE_NAME`/`ENQUOTE_LITERAL`: literais `q'emp'` malformados e constantes sem `apex_exec.`.
- `OPEN_REMOTE_SQL_QUERY`: default `c_empty columns` (sem sublinhado).
- `OPEN_LOCAL_DML_CONTEXT`/`OPEN_REMOTE_DML_CONTEXT`: a tabela de parâmetros lista `p_dml_plsql_code` duas vezes; a segunda descreve `p_lock_plsql_code`.
- Call sequences: cita `GET_PARAMETER_VALUE`, que não está documentada; as funções são `GET_PARAMETER_VARCHAR2`, `GET_PARAMETER_NUMBER`, `GET_PARAMETER_CLOB` etc.
**Correção:** seguir as **assinaturas** (blocos *Syntax*) e as versões corrigidas nesta parte.
**Prevenção:** sempre usar notação nomeada e conferir o nome de cada parâmetro na assinatura.

Fonte: [ADD_COLUMN Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.ADD_COLUMN-Procedure.html), [OPEN_REST_SOURCE_DML_CONTEXT Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.OPEN_REST_SOURCE_DML_CONTEXT-Function.html), [SET_VALUE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.SET_VALUE-Procedure.html), [SET_ROW_VERSION_CHECKSUM Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.SET_ROW_VERSION_CHECKSUM-Procedure.html), [IS_REMOTE_SQL_AUTH_VALID Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.IS_REMOTE_SQL_AUTH_VALID-Function.html), [PURGE_JSON_SOURCE_CACHE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.PURGE_JSON_SOURCE_CACHE-Procedure.html), [Call Sequences for APEX_EXEC](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/call-sequences-for-APEX_EXEC.html)

### APEX_EXEC: chamada a OPEN_WEB_SOURCE_* / EXECUTE_WEB_SOURCE / PURGE_WEB_SOURCE_CACHE em código novo

**Sintoma:** o código usa as APIs *Web Source* (legado de quando REST Data Sources se chamavam Web Source Modules).
**Causa:** `OPEN_WEB_SOURCE_QUERY`, `OPEN_WEB_SOURCE_DML_CONTEXT`, `EXECUTE_WEB_SOURCE` e `PURGE_WEB_SOURCE_CACHE` estão **Deprecated** e serão removidas numa versão futura.
**Correção:** migrar para `OPEN_REST_SOURCE_QUERY`, `OPEN_REST_SOURCE_DML_CONTEXT`, `EXECUTE_REST_SOURCE` e `PURGE_REST_SOURCE_CACHE`, trocando `p_module_static_id` por `p_static_id`.

Fonte: [OPEN_WEB_SOURCE_QUERY Function (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.OPEN_WEB_SOURCE_QUERY-Function.html), [EXECUTE_WEB_SOURCE Procedure (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.EXECUTE_WEB_SOURCE-Procedure.html), [PURGE_WEB_SOURCE_CACHE Procedure (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.PURGE_WEB_SOURCE_CACHE-Procedure.html)


## 07. APEX_REST_SOURCE_SYNC: controlar por PL/SQL a sincronização de REST Data Sources com tabelas locais

### APEX_REST_SOURCE_SYNC: propósito, quando usar e quando não usar

**REST Data Source Synchronization** mantém uma tabela local alimentada com os dados de um serviço REST, seja sob demanda, seja num agendamento (job do Scheduler). A sincronização é configurada no Builder (Shared Components > REST Data Sources > *Manage Synchronization*), com tabela de destino, tipo (Append, Merge ou Replace), agenda, *steps*, *commit interval* e limite de requisições. O package `APEX_REST_SOURCE_SYNC` é a parte programática: ligar e desligar a sincronização, executá-la agora, reagendá-la, rodar uma sincronização dinâmica com parâmetros próprios, consultar o estado e alinhar a tabela local com o *Data Profile*.

**Quando usar a sincronização (e este package):**
- Relatórios eficientes sobre conjuntos grandes vindos de REST paginado. Na tabela local dá para usar índices; sem ela, cada consulta faria várias requisições HTTP.
- Dados que precisam ser processados por PL/SQL ou cruzados com tabelas locais.
- APIs que só devolvem uma janela recente de dados, para acumular histórico (exige *merge* por chave primária).
- Um cache melhor que o cache de JSON da REST Data Source, porque elimina o parse de JSON a cada uso.

**Quando não usar:** para uma chamada pontual com lógica própria, use `APEX_WEB_SERVICE`. Para ler dados sempre frescos e pouco volumosos, a REST Data Source direta (com ou sem cache) basta.

**Pré-requisitos e regras:**
- **Contexto de sessão APEX:** `SYNCHRONIZE_DATA` exige uma sessão APEX, e todos os exemplos oficiais criam uma com `apex_session.create_session(p_app_id, p_page_id, p_username)` antes de chamar o package fora do Builder.
- **`CREATE JOB`:** para rodar a sincronização agendada, o parsing schema da aplicação precisa do privilégio `CREATE JOB`.
- **Após importar a aplicação, as sincronizações ficam desabilitadas.** Isso evita várias instâncias da mesma sincronização rodando em paralelo. Reative pela UI ou com `ENABLE`/`RESCHEDULE` (ver o caso adiante).
- O `p_application_id` padrão é a aplicação atual (`apex_application.g_flow_id`), e o `p_module_static_id` é o *static ID* da REST Data Source.

Fonte: [APEX_REST_SOURCE_SYNC](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_REST_SOURCE_SYNC.html) · [Managing Data Synchronization](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-data-synchronization.html)

### APEX_REST_SOURCE_SYNC: referência completa de procedures e functions

| Nome | Tipo | O que faz |
|---|---|---|
| `DISABLE` | procedure | Desliga a sincronização automática da REST Data Source |
| `DYNAMIC_SYNCHRONIZE_DATA` | procedure | Executa uma sincronização com filtro e parâmetros próprios, sem os *steps* predefinidos |
| `ENABLE` | procedure | Liga a sincronização (agenda) da REST Data Source |
| `GET_LAST_SYNC_TIMESTAMP` | function | Timestamp da última sincronização **bem-sucedida** |
| `GET_SYNC_TABLE_DEFINITION_SQL` | function | Gera o DDL para alinhar a tabela local ao Data Profile (sem executar) |
| `IS_RUNNING` | function | `TRUE` se a sincronização está em execução agora |
| `RESCHEDULE` | procedure | Define o próximo instante de execução agendada |
| `SYNCHRONIZE_DATA` | procedure | Executa a sincronização configurada, agora ou em background |
| `SYNCHRONIZE_TABLE_DEFINITION` | procedure | Executa o DDL (`CREATE`/`ALTER TABLE`) que alinha a tabela ao Data Profile |

Fonte: [APEX_REST_SOURCE_SYNC](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_REST_SOURCE_SYNC.html)

### APEX_REST_SOURCE_SYNC.SYNCHRONIZE_DATA: executar a sincronização configurada agora

```sql
APEX_REST_SOURCE_SYNC.SYNCHRONIZE_DATA (
    p_module_static_id      IN VARCHAR2,
    p_run_in_background     IN BOOLEAN  DEFAULT FALSE,
    p_application_id        IN NUMBER   DEFAULT {current application id} );
```

| Parâmetro | Padrão | Significado |
|---|---|---|
| `p_module_static_id` | — | Static ID da REST Data Source |
| `p_run_in_background` | `FALSE` | `TRUE`: roda como job único do `DBMS_SCHEDULER` e retorna na hora. `FALSE`: roda na sessão atual e só retorna ao final |
| `p_application_id` | aplicação atual | Aplicação que contém a REST Data Source |

Executa a sincronização com a configuração do Builder (tipo, steps, commit interval, limite de requisições), independentemente da próxima execução agendada. **Exige contexto de sessão APEX.**

```sql
BEGIN
    apex_session.create_session(
        p_app_id   => 100,
        p_page_id  => 1,
        p_username => '...' );

    apex_rest_source_sync.synchronize_data(
        p_module_static_id  => 'rest_movie',
        p_run_in_background => true );
END;
```

**Pegadinhas:**
- Num botão de página, prefira `p_run_in_background => true`. Em modo síncrono, o usuário espera todas as requisições HTTP terminarem.
- Combine com `IS_RUNNING` para não disparar uma segunda execução enquanto a primeira ainda roda.

Fonte: [SYNCHRONIZE_DATA Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SYNCHRONIZE_DATA-Procedure.html)

### APEX_REST_SOURCE_SYNC.DYNAMIC_SYNCHRONIZE_DATA: sincronizar com filtro e parâmetros definidos em tempo de execução

```sql
APEX_REST_SOURCE_SYNC.DYNAMIC_SYNCHRONIZE_DATA (
    p_module_static_id          IN VARCHAR2,
    --
    p_sync_static_id            IN VARCHAR2,
    p_sync_external_filter_expr IN VARCHAR2               DEFAULT NULL,
    p_sync_parameters           IN apex_exec.t_parameters DEFAULT apex_exec.c_empty_parameters,
    --
    p_application_id            IN NUMBER                 DEFAULT apex_application.g_flow_id );
```

| Parâmetro | Significado |
|---|---|
| `p_module_static_id` | Static ID da REST Data Source |
| `p_sync_static_id` | Static ID que você dá a esta sincronização dinâmica |
| `p_sync_external_filter_expr` | Expressão de filtro externo (enviada ao serviço) para esta execução |
| `p_sync_parameters` | Parâmetros da REST Data Source (`apex_exec.t_parameters`, montados com `apex_exec.add_parameter`) |
| `p_application_id` | Aplicação que contém a REST Data Source |

Os *steps* predefinidos no Builder **não** são executados; vale só o que for passado aqui.

```sql
DECLARE
    l_parameters apex_exec.t_parameters;
BEGIN
    apex_exec.add_parameter(
        p_parameters => l_parameters,
        p_name       => 'query',
        p_value      => 'Oracle APEX' );

    apex_session.create_session(
        p_app_id   => 100,
        p_page_id  => 1,
        p_username => '...' );

    apex_rest_source_sync.dynamic_synchronize_data(
        p_module_static_id => 'rest_movie',
        p_sync_static_id   => 'Sync_Oracle_APEX',
        p_sync_parameters  => l_parameters );
END;
```

Fonte: [DYNAMIC_SYNCHRONIZE_DATA Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/DYNAMIC_SYNCHRONIZE_DATA-Procedure.html)

### APEX_REST_SOURCE_SYNC.ENABLE, DISABLE e RESCHEDULE: ligar, desligar e reagendar a sincronização

```sql
APEX_REST_SOURCE_SYNC.ENABLE (
  p_application_id    IN NUMBER    DEFAULT {current application id},
  p_module_static_id  IN VARCHAR2 )

APEX_REST_SOURCE_SYNC.DISABLE (
  p_application_id    IN NUMBER   DEFAULT {current application id},
  p_module_static_id  IN VARCHAR2 )

APEX_REST_SOURCE_SYNC.RESCHEDULE (
    p_application_id    IN NUMBER   DEFAULT apex_application.g_flow_id,
    p_module_static_id  IN VARCHAR2,
    p_next_run_at       IN timestamp with time zone DEFAULT systimestamp );
```

| Rotina | Efeito |
|---|---|
| `ENABLE` | Liga a sincronização agendada da REST Data Source (pela doc do App Builder, o agendamento começa imediatamente) |
| `DISABLE` | Desliga a sincronização automática |
| `RESCHEDULE` | Define quando será a próxima execução (`p_next_run_at`; padrão = agora, ou seja, roda já) |

```sql
BEGIN
    apex_rest_source_sync.enable(
        p_application_id   => 152,
        p_module_static_id => 'rest_movie' );

    apex_rest_source_sync.disable(
        p_application_id   => 152,
        p_module_static_id => 'rest_movie' );

    -- próxima execução à meia-noite
    apex_rest_source_sync.reschedule(
        p_application_id   => 152,
        p_module_static_id => 'rest_movie',
        p_next_run_at      => trunc(systimestamp + 1) );
END;
```

**Pegadinhas (erros nos exemplos oficiais):**
- O exemplo de `RESCHEDULE` da API Reference usa `p_static_id => 'rest_movie'`, mas o parâmetro da assinatura é `p_module_static_id`. Use o nome da assinatura.
- O exemplo equivalente no App Builder User's Guide fecha o parêntese antes de `p_next_run_at` e deixa uma vírgula sobrando. A versão correta é a mostrada acima.

Fonte: [ENABLE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_REST_SOURCE_SYNC-ENABLE-Procedure.html) · [DISABLE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_REST_SOURCE_SYNC-DISABLE-Procedure.html) · [RESCHEDULE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_REST_SOURCE_SYNC-RESCHEDULE-Procedure.html) · [Managing Data Synchronization](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-data-synchronization.html)

### APEX_REST_SOURCE_SYNC.IS_RUNNING e GET_LAST_SYNC_TIMESTAMP: consultar o estado da sincronização

```sql
APEX_REST_SOURCE_SYNC.IS_RUNNING (
    p_application_id    IN  NUMBER DEFAULT apex_application.g_flow_id,
    p_module_static_id  IN  VARCHAR2 )
    RETURN BOOLEAN;

APEX_REST_SOURCE_SYNC.GET_LAST_SYNC_TIMESTAMP (
    p_module_static_id  IN VARCHAR2,
    p_application_id    IN NUMBER   DEFAULT {current application id} )
    RETURN timestamp with time zone;
```

- `IS_RUNNING` retorna `TRUE` se a sincronização da REST Data Source está em execução neste momento. A tabela de parâmetros da doc fala em "automation", mas é texto herdado: o parâmetro é o static ID da REST Data Source.
- `GET_LAST_SYNC_TIMESTAMP` retorna o timestamp da última sincronização **bem-sucedida**. Falhas não atualizam esse valor.

```sql
DECLARE
    l_last timestamp with time zone;
BEGIN
    apex_session.create_session(p_app_id => 100, p_page_id => 1, p_username => '...');

    IF NOT apex_rest_source_sync.is_running(p_module_static_id => 'rest_movie') THEN
        l_last := apex_rest_source_sync.get_last_sync_timestamp(p_module_static_id => 'rest_movie');
        IF l_last IS NULL OR l_last < systimestamp - interval '1' hour THEN
            apex_rest_source_sync.synchronize_data(
                p_module_static_id  => 'rest_movie',
                p_run_in_background => true );
        END IF;
    END IF;
END;
```

**Dica:** para mostrar a "última atualização" numa página, use `GET_LAST_SYNC_TIMESTAMP`. Antes de disparar uma execução manual, consulte `IS_RUNNING` para não sobrepor execuções.

Fonte: [IS_RUNNING Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_REST_SOURCE_SYNC-IS_RUNNING-Function.html) · [GET_LAST_SYNC_TIMESTAMP Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_LAST_SYNC_TIMESTAMP-Function.html)

### APEX_REST_SOURCE_SYNC.SYNCHRONIZE_TABLE_DEFINITION e GET_SYNC_TABLE_DEFINITION_SQL: alinhar a tabela local ao Data Profile

Quando a REST Data Source muda (colunas novas ou removidas no *Data Profile*), a tabela local fica defasada. A sincronização continua funcionando para as colunas que existem nos dois lados e ignora as demais. Estas rotinas geram ou aplicam o DDL de alinhamento.

```sql
APEX_REST_SOURCE_SYNC.SYNCHRONIZE_TABLE_DEFINITION (
    p_module_static_id      IN VARCHAR2,
    p_application_id        IN NUMBER   DEFAULT {current application id},
    p_drop_unused_columns   IN BOOLEAN  DEFAULT FALSE );

APEX_REST_SOURCE_SYNC.GET_SYNC_TABLE_DEFINITION_SQL (
    p_module_static_id      IN VARCHAR2,
    p_application_id        IN NUMBER   DEFAULT {current application id},
    p_include_drop_columns  IN BOOLEAN  DEFAULT FALSE )
    RETURN VARCHAR2;
```

| Rotina | Comportamento |
|---|---|
| `SYNCHRONIZE_TABLE_DEFINITION` | **Executa** o DDL. Se a tabela não existir, faz `CREATE TABLE` com as colunas **visíveis** do Data Profile; se existir, aplica uma série de `ALTER TABLE`. Com `p_drop_unused_columns => true`, também remove colunas que saíram do Data Profile |
| `GET_SYNC_TABLE_DEFINITION_SQL` | Só **gera** o SQL (`VARCHAR2`), sem executar. Com `p_include_drop_columns => true`, inclui `ALTER TABLE DROP COLUMN` |

```sql
DECLARE
    l_sql varchar2(32767);
BEGIN
    apex_session.create_session(p_app_id => 100, p_page_id => 1, p_username => '...');

    -- revisar antes de aplicar
    l_sql := apex_rest_source_sync.get_sync_table_definition_sql(
                 p_module_static_id     => 'rest_movie',
                 p_include_drop_columns => true );
    sys.dbms_output.put_line(l_sql);

    -- aplicar
    apex_rest_source_sync.synchronize_table_definition(
        p_module_static_id    => 'rest_movie',
        p_drop_unused_columns => false );
END;
```

**Pegadinhas:**
- `p_drop_unused_columns => true` apaga dados de colunas que você pode ter acrescentado à mão na tabela. A doc permite adicionar índices e colunas próprias à tabela de sincronização. Revise com `GET_SYNC_TABLE_DEFINITION_SQL` antes.
- Em ambientes versionados, prefira gerar o SQL e colocá-lo nos *supporting objects* ou num script de migração, como a doc sugere, em vez de aplicar DDL direto em produção.

Fonte: [SYNCHRONIZE_TABLE_DEFINITION Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SYNCHRONIZE_TABLE_DEFINITION-Procedure.html) · [GET_SYNC_TABLE_DEFINITION_SQL Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_SYNC_TABLE_DEFINITION_SQL-Function.html) · [Managing Data Synchronization](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-data-synchronization.html)

### Sincronização de REST Data Source parou de rodar depois de importar a aplicação (APEX_REST_SOURCE_SYNC)

**Sintoma:** após importar a aplicação (novo ambiente, nova versão ou outro ID), a tabela local deixa de ser atualizada e o log de sincronização não mostra novas execuções.

**Causa:** comportamento proposital. O APEX **desabilita as sincronizações no import** para não ter várias cópias da mesma aplicação sincronizando ao mesmo tempo.

**Correção:** reative em Shared Components > REST Data Sources > Manage Synchronization ou, em ambientes *Runtime Only*, por PL/SQL:

```sql
declare
    l_app_id number := 100;  -- ID da aplicação importada
begin
    apex_session.create_session(
        p_app_id   => l_app_id,
        p_page_id  => 1,
        p_username => '{workspace user}');

    apex_rest_source_sync.enable(
        p_application_id   => l_app_id,
        p_module_static_id => '{REST Source static ID}');
    -- ou, para escolher o próximo horário:
    -- apex_rest_source_sync.reschedule(
    --     p_application_id   => l_app_id,
    --     p_module_static_id => '{REST Source static ID}',
    --     p_next_run_at      => trunc(systimestamp + 1));
end;
```

**Prevenção:** inclua esse bloco no script de deploy de cada ambiente onde a sincronização deve rodar. Confira também se o parsing schema tem `CREATE JOB`.

Fonte: [Managing Data Synchronization](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-data-synchronization.html) · [ENABLE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_REST_SOURCE_SYNC-ENABLE-Procedure.html)

### Sincronização agendada não executa ou termina como Incomplete (APEX_REST_SOURCE_SYNC)

**Sintoma:** a sincronização agendada não roda, ou o log mostra o status `Incomplete`.

**Causa:** sem o privilégio `CREATE JOB` no parsing schema, a execução agendada não acontece. O status `Incomplete` aparece quando o **HTTP Request Limit** do step é ultrapassado. Por causa do método de execução, a parada acontece uma requisição depois do limite (com limite 10, ela para após a 11ª).

**Correção:** conceda `CREATE JOB` ao parsing schema. Aumente o *HTTP Request Limit* ou restrinja o volume com filtros e parâmetros nos *steps* (ou com `DYNAMIC_SYNCHRONIZE_DATA`). Use o log de sincronização, que permite descer até o log de Web Services de cada requisição, para ver quantas requisições foram feitas.

Fonte: [Managing Data Synchronization](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-data-synchronization.html)


## 08. APEX_DATA_EXPORT: exportar resultados de consultas para PDF, XLSX, CSV, HTML, JSON e XML

### APEX_DATA_EXPORT: propósito, quando usar e quando não usar

`APEX_DATA_EXPORT` gera arquivos a partir de um *query context* do `APEX_EXEC`. O fluxo é sempre o mesmo: abrir um contexto (`APEX_EXEC.OPEN_QUERY_CONTEXT`), chamar `EXPORT` (que devolve um registro `t_export` com o conteúdo num LOB, o MIME type e o nome do arquivo), fechar o contexto (`APEX_EXEC.CLOSE`) e então entregar o resultado: baixar no navegador (`DOWNLOAD`), anexar a um e-mail, gravar numa tabela etc. Formatos suportados: PDF, XLSX, HTML, CSV, XML e JSON, mais as variantes `PXML` e `PJSON`, otimizadas para impressão.

As rotinas `ADD_COLUMN`, `ADD_COLUMN_GROUP`, `ADD_HIGHLIGHT` e `ADD_AGGREGATE` montam coleções PL/SQL que você passa para `EXPORT` para escolher colunas e cabeçalhos, agrupar colunas sob um cabeçalho extra, destacar linhas/células e incluir linhas de totais (com ou sem quebra de controle). `GET_PRINT_CONFIG` prepara a formatação (papel, orientação, fontes, cores, bordas) usada em PDF e XLSX.

- **Quando usar:** relatório PDF/Excel gerado por botão ou processo sem depender de uma região na tela; exportação agendada (automation/job) que anexa o arquivo a um e-mail; gerar um BLOB para guardar numa tabela; CSV/JSON para integração. Funciona com qualquer fonte que o `APEX_EXEC` abra (banco local, banco remoto via REST-enabled SQL, REST Data Source).
- **Quando não usar:** para exportar exatamente o que o usuário vê numa região nativa (Interactive Report, Interactive Grid, Classic Report, com os filtros e o relatório salvo dele), prefira `APEX_REGION.EXPORT_DATA`, que devolve o mesmo `apex_data_export.t_export` mas parte da definição da região. Para documentos com layout livre (modelo de Word/RTF), o pacote certo é o de impressão (`APEX_PRINT`), não este.
- **Pré-requisitos:** `DOWNLOAD` entrega o arquivo ao navegador e encerra o engine (`APEX_APPLICATION.STOP_APEX_ENGINE`), então só faz sentido dentro de um request de página (processo, Ajax callback). Em job/automation, use o conteúdo do `t_export` diretamente (e-mail, tabela).
- **Pegadinha geral:** feche sempre o contexto com `APEX_EXEC.CLOSE`, inclusive no `EXCEPTION`; todos os exemplos oficiais seguem esse padrão. E chame `CLOSE` **antes** de `DOWNLOAD`, porque `DOWNLOAD` para o engine por padrão e o código seguinte não roda.

Fonte: [APEX_DATA_EXPORT](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_EXPORT.html), [EXPORT Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_EXPORT-EXPORT-Function.html), [APEX_REGION.EXPORT_DATA Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_REGION-EXPORT_DATA-Function.html)

### APEX_DATA_EXPORT: referência completa de procedures, functions, constantes e tipos

| Item | Tipo | O que faz |
|---|---|---|
| `ADD_AGGREGATE` | procedure | Acrescenta uma definição de agregado (linha de total por quebra e/ou total geral) a um `t_aggregates` |
| `ADD_COLUMN` | procedure | Acrescenta uma coluna (nome, cabeçalho, máscara, alinhamento, largura, quebra, congelada, grupo) a um `t_columns` |
| `ADD_COLUMN_GROUP` | procedure | Acrescenta um grupo de colunas (cabeçalho extra, multinível) a um `t_column_groups` e devolve o índice |
| `ADD_HIGHLIGHT` | procedure | Acrescenta um destaque de linha ou célula (cor do texto/fundo) a um `t_highlights` |
| `DOWNLOAD` | procedure | Envia o `t_export` ao navegador (attachment/inline) e, por padrão, chama `APEX_APPLICATION.STOP_APEX_ENGINE` |
| `EXPORT` | function | Lê o query context e gera o arquivo no formato pedido; retorna `t_export` |
| `GET_PRINT_CONFIG` | function | Monta um `t_print_config` (papel, unidades, orientação, cabeçalho/rodapé de página, fontes, cores, bordas) |
| `c_format_csv` / `_html` / `_pdf` / `_xlsx` / `_xml` / `_pxml` / `_json` / `_pjson` | constantes `t_format` | `'CSV'`, `'HTML'`, `'PDF'`, `'XLSX'`, `'XML'`, `'PXML'`, `'JSON'`, `'PJSON'` (`PXML` e `PJSON` otimizados para impressão) |
| `c_align_start` / `c_align_center` / `c_align_end` | constantes `t_alignment` | `'LEFT'`, `'CENTER'`, `'RIGHT'` (usadas em `ADD_COLUMN`, `ADD_COLUMN_GROUP`, `GET_PRINT_CONFIG`) |
| `c_attachment` / `c_inline` | constantes `t_content_disposition` | `'attachment'`, `'inline'` (usadas em `DOWNLOAD`) |
| `c_unit_inches` / `_millimeters` / `_centimeters` / `_points` | constantes `t_unit` | `'INCHES'`, `'MILLIMETERS'`, `'CENTIMETERS'`, `'POINTS'` |
| `c_size_letter` / `_legal` / `_tabloid` / `c_size_A4` / `c_size_A3` / `c_size_custom` | constantes `t_size` | `'LETTER'`, `'LEGAL'`, `'TABLOID'`, `'A4'`, `'A3'`, `'CUSTOM'` |
| `c_width_unit_percentage` / `_points` / `_pixels` | constantes `t_width_unit` | `'PERCENTAGE'`, `'POINTS'`, `'PIXELS'` (unidade de `p_width` das colunas) |
| `c_orientation_portrait` / `c_orientation_landscape` | constantes `t_orientation` | `'VERTICAL'`, `'HORIZONTAL'` |
| `c_font_family_helvetica` / `_times` / `_courier` | constantes `t_font_family` | `'Helvetica'`, `'Times'`, `'Courier'` |
| `c_font_weight_normal` / `c_font_weight_bold` | constantes `t_font_weight` | `'normal'`, `'bold'` |
| `c_empty_columns`, `c_empty_column_groups`, `c_empty_aggregates`, `c_empty_highlights`, `c_empty_print_config` | constantes (defaults) | Coleções/registro vazios usados como default dos parâmetros de `EXPORT` |
| `t_export` | tipo (record) | Resultado: `file_name`, `format`, `mime_type`, `as_clob`, `content_blob`, `content_clob` |
| `t_column` / `t_columns` | tipo (record / table index by pls_integer) | Definição de coluna |
| `t_column_group` / `t_column_groups` | tipo | Definição de grupo de colunas |
| `t_highlight` / `t_highlights` | tipo | Definição de destaque |
| `t_aggregate` / `t_aggregates` | tipo | Definição de agregado |
| `t_print_config` | tipo (record) | Configuração de impressão |
| `t_alignment`, `t_label`, `t_color`, `t_format`, `t_content_disposition`, `t_unit`, `t_size`, `t_width_unit`, `t_orientation`, `t_font_family`, `t_font_weight` | subtypes | `varchar2` de 20 a 4000 (`t_format` = varchar2(20); `t_alignment`, `t_label`, `t_width_unit` = 255; os demais 30 ou 4000) |

Nenhum item do capítulo está marcado como deprecated na doc 26.1.

Fonte: [Global Constants](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_EXPORT-Global-Constants.html), [Data Types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_EXPORT-Data-Types.html)

### APEX_DATA_EXPORT: tipos t_export, t_columns, t_column_groups, t_highlights, t_aggregates e t_print_config

```sql
type t_export is record (
    file_name               varchar2(32767),
    format                  t_format,
    mime_type               varchar2(32767),
    as_clob                 boolean,
    content_blob            blob,
    content_clob            clob );

type t_column_group is record (
    name                    varchar2(255),
    alignment               t_alignment,
    parent_group_idx        pls_integer );
type t_column_groups        is table of t_column_group  index by pls_integer;

type t_column is record (
    name                    apex_exec.t_column_name,
    heading                 varchar2(255),
    format_mask             varchar2(4000),
    heading_alignment       t_alignment,
    value_alignment         t_alignment,
    width                   number,
    is_column_break         boolean,
    is_frozen               boolean,
    column_group_idx        pls_integer );
type t_columns              is table of t_column        index by pls_integer;

type t_highlight is record (
    id                      number,
    name                    varchar2(4000),
    value_column            apex_exec.t_column_name,
    display_column          apex_exec.t_column_name,
    text_color              t_color,
    background_color        t_color );
type t_highlights           is table of t_highlight     index by pls_integer;

type t_aggregate is record (
    label                   t_label,
    format_mask             varchar2(4000),
    display_column          apex_exec.t_column_name,
    value_column            apex_exec.t_column_name,
    overall_label           t_label,
    overall_value_column    apex_exec.t_column_name );
type t_aggregates           is table of t_aggregate     index by pls_integer;
```

`t_print_config` tem os campos `units`, `paper_size`, `width_units`, `width`, `height`, `orientation`, os grupos `page_header*` e `page_footer*` (texto, `_font_color`, `_font_family`, `_font_weight`, `_font_size`, `_alignment`), `header_bg_color`, `header_font_color`, `header_font_family`, `header_font_weight`, `header_font_size` (cabeçalho da tabela), `body_bg_color`, `body_font_color`, `body_font_family`, `body_font_weight`, `body_font_size`, `border_width` e `border_color`. Os tamanhos de fonte são `varchar2(4000)` no registro, mas `GET_PRINT_CONFIG` os recebe como `NUMBER`.

**Como ler o `t_export`:** se `as_clob` for `TRUE`, o conteúdo está em `content_clob`; senão, em `content_blob`. `mime_type` e `file_name` vêm prontos para `DOWNLOAD`, `APEX_MAIL.ADD_ATTACHMENT` ou um `INSERT` numa tabela de arquivos.

Fonte: [Data Types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_EXPORT-Data-Types.html)

### APEX_DATA_EXPORT.EXPORT: gerar o arquivo a partir de um query context do APEX_EXEC

```sql
FUNCTION EXPORT (
  p_context                 IN apex_exec.t_context,
  p_format                  IN t_format,
  p_as_clob                 IN BOOLEAN          DEFAULT false,
  p_columns                 IN t_columns        DEFAULT c_empty_columns,
  p_column_groups           IN t_column_groups  DEFAULT c_empty_column_groups,
  p_aggregates              IN t_aggregates     DEFAULT c_empty_aggregates,
  p_highlights              IN t_highlights     DEFAULT c_empty_highlights,
  --
  p_file_name               IN VARCHAR2         DEFAULT NULL,
  p_print_config            IN t_print_config   DEFAULT c_empty_print_config,
  p_page_header             IN VARCHAR2         DEFAULT NULL,
  p_page_footer             IN VARCHAR2         DEFAULT NULL,
  p_supplemental_text       IN VARCHAR2         DEFAULT NULL,
  --
  p_csv_enclosed_by         IN VARCHAR2         DEFAULT NULL,
  p_csv_separator           IN VARCHAR2         DEFAULT NULL,
  --
  p_pdf_accessible          IN BOOLEAN          DEFAULT NULL,
  --
  p_xml_include_declaration IN BOOLEAN          DEFAULT false )
  RETURN t_export
```

| Parâmetro | Descrição |
|---|---|
| `p_context` | Contexto aberto por `APEX_EXEC` (consulta local, remota ou REST Data Source) |
| `p_format` | Formato: use `c_format_*` (`XLSX`, `PDF`, `HTML`, `CSV`, `XML`, `JSON`, e as variantes de impressão `PXML`, `PJSON`) |
| `p_as_clob` | `TRUE` gera em CLOB (`content_clob`) em vez de BLOB; default `FALSE` |
| `p_columns` | Colunas a exportar: primeiro as de quebra de controle, depois na ordem de exibição. Vazio = todas as colunas do contexto |
| `p_column_groups` | Grupos de colunas, na ordem dos níveis e de exibição |
| `p_aggregates` | Agregados do relatório (linhas de total) |
| `p_highlights` | Destaques do relatório |
| `p_file_name` | Nome do arquivo gerado |
| `p_print_config` | Atributos de impressão para Excel e PDF (`GET_PRINT_CONFIG`) |
| `p_page_header` | Texto do cabeçalho da página; **sobrepõe** o `page_header` do `p_print_config` |
| `p_page_footer` | Texto do rodapé da página; **sobrepõe** o `page_footer` do `p_print_config` |
| `p_supplemental_text` | Texto exibido no topo, em todos os formatos de download |
| `p_csv_enclosed_by` | CSV: caractere que envolve os valores |
| `p_csv_separator` | CSV: separador de colunas |
| `p_pdf_accessible` | PDF: gera PDF acessível (com tags) |
| `p_xml_include_declaration` | XML: inclui a declaração XML na primeira linha; default `FALSE` |

**Retorno:** `t_export` com o conteúdo, o MIME type e o nome do arquivo.

**Comportamento:** o arquivo inteiro volta num LOB dentro do `t_export`; nada é baixado nem gravado até você usar o resultado. Quando `p_columns` é vazio, todas as colunas do contexto entram. Colunas auxiliares usadas por destaques e agregados (ex.: `HIGHLIGHT1`, `AGGREGATE1`) entram no arquivo se você não passar `p_columns`; para escondê-las, liste só as colunas visíveis em `p_columns`.

Exemplo mínimo (PDF baixado no navegador):

```sql
declare
    l_context apex_exec.t_context;
    l_export  apex_data_export.t_export;
begin
    l_context := apex_exec.open_query_context(
        p_location  => apex_exec.c_location_local_db,
        p_sql_query => 'select * from emp' );

    l_export := apex_data_export.export(
        p_context => l_context,
        p_format  => apex_data_export.c_format_pdf );

    apex_exec.close( l_context );
    apex_data_export.download( p_export => l_export );
exception
    when others then
        apex_exec.close( l_context );
        raise;
end;
```

**Pegadinhas:**
- A tabela de parâmetros lista só seis valores para `p_format`, mas as constantes `c_format_pxml` e `c_format_pjson` também existem e são aceitas como formatos de impressão.
- `p_as_clob => TRUE` só faz sentido para formatos texto (CSV, HTML, JSON, XML). A doc de `APEX_REGION.EXPORT_DATA`, que usa o mesmo tipo, avisa que CLOB não funciona com formatos binários como PDF e XLSX.
- `p_page_header`/`p_page_footer` passados em `EXPORT` vencem os do `p_print_config`.
- `p_width` das colunas e quase tudo de `p_print_config` (papel, largura/altura, orientação, unidade de largura) valem só para PDF; `p_is_frozen` só para XLSX.

Fonte: [EXPORT Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_EXPORT-EXPORT-Function.html), [Global Constants](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_EXPORT-Global-Constants.html), [APEX_REGION.EXPORT_DATA Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_REGION-EXPORT_DATA-Function.html)

### APEX_DATA_EXPORT.ADD_COLUMN: escolher colunas, cabeçalhos, máscaras e larguras da exportação

```sql
PROCEDURE ADD_COLUMN (
  p_columns             IN OUT NOCOPY t_columns,
  p_name                IN            apex_exec.t_column_name,
  p_heading             IN            VARCHAR2                  DEFAULT NULL,
  p_format_mask         IN            VARCHAR2                  DEFAULT NULL,
  p_heading_alignment   IN            t_alignment               DEFAULT NULL,
  p_value_alignment     IN            t_alignment               DEFAULT NULL,
  p_width               IN            NUMBER                    DEFAULT NULL,
  p_is_column_break     IN            BOOLEAN                   DEFAULT FALSE,
  p_is_frozen           IN            BOOLEAN                   DEFAULT FALSE,
  p_column_group_idx    IN            PLS_INTEGER               DEFAULT NULL );
```

| Parâmetro | Descrição |
|---|---|
| `p_columns` | Coleção de colunas (IN OUT) |
| `p_name` | Nome da coluna no contexto (como sai do SELECT, normalmente em maiúsculas) |
| `p_heading` | Texto do cabeçalho |
| `p_format_mask` | Máscara de formato; útil no XLSX, que usa tipos nativos |
| `p_heading_alignment` / `p_value_alignment` | `LEFT`, `CENTER`, `RIGHT` (constantes `c_align_*`) |
| `p_width` | Só PDF. Largura da coluna; por padrão em porcentagem, mudável pelo `width_units` do print config |
| `p_is_column_break` | Usa a coluna como quebra de controle |
| `p_is_frozen` | Só XLSX. Congela a coluna |
| `p_column_group_idx` | Índice de um grupo criado com `ADD_COLUMN_GROUP` |

**Comportamento:** a coleção define o subconjunto e a ordem das colunas exportadas. Coleção vazia (ou não passada) = todas as colunas do contexto. Colunas de quebra devem vir primeiro na coleção (regra de `p_columns` em `EXPORT`).

```sql
apex_data_export.add_column( p_columns => l_columns, p_name => 'NOME',    p_heading => 'Nome' );
apex_data_export.add_column( p_columns => l_columns, p_name => 'CARGO',   p_heading => 'Cargo' );
apex_data_export.add_column( p_columns => l_columns, p_name => 'SALARIO', p_heading => 'Salário',
                             p_format_mask => 'FML999G999G999G999G990D00',
                             p_value_alignment => apex_data_export.c_align_end );
```

Fonte: [ADD_COLUMN Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_EXPORT-ADD_COLUMN-Procedure.html)

### APEX_DATA_EXPORT.ADD_COLUMN_GROUP: agrupar colunas sob um cabeçalho extra (multinível)

```sql
APEX_DATA_EXPORT.ADD_COLUMN_GROUP (
    p_column_groups     IN OUT NOCOPY   t_column_groups,
    p_idx               OUT             PLS_INTEGER,
    p_name              IN              VARCHAR2,
    p_alignment         IN              t_alignment         DEFAULT c_align_center,
    p_parent_group_idx  IN              PLS_INTEGER         DEFAULT NULL )
```

| Parâmetro | Descrição |
|---|---|
| `p_column_groups` | Coleção de grupos (IN OUT) |
| `p_idx` | OUT: índice gerado, que você passa em `ADD_COLUMN.p_column_group_idx` |
| `p_name` | Texto do grupo |
| `p_alignment` | `LEFT`, `CENTER` (default), `RIGHT` |
| `p_parent_group_idx` | Índice do grupo pai, para criar níveis |

**Comportamento:** cada grupo vira uma linha extra de cabeçalho acima das colunas que apontam para ele. Sem coleção (ou vazia), não há grupos. Passe a coleção em `EXPORT.p_column_groups` junto com `p_columns`.

```sql
declare
    l_context  apex_exec.t_context;
    l_export   apex_data_export.t_export;
    l_groups   apex_data_export.t_column_groups;
    l_columns  apex_data_export.t_columns;
    l_g_ident  pls_integer;
    l_g_remun  pls_integer;
begin
    l_context := apex_exec.open_query_context(
        p_location  => apex_exec.c_location_local_db,
        p_sql_query => 'select * from emp' );

    apex_data_export.add_column_group( p_column_groups => l_groups, p_idx => l_g_ident, p_name => 'Identificação' );
    apex_data_export.add_column_group( p_column_groups => l_groups, p_idx => l_g_remun, p_name => 'Remuneração' );

    apex_data_export.add_column( p_columns => l_columns, p_name => 'ENAME', p_heading => 'Nome',     p_column_group_idx => l_g_ident );
    apex_data_export.add_column( p_columns => l_columns, p_name => 'JOB',   p_heading => 'Cargo',    p_column_group_idx => l_g_ident );
    apex_data_export.add_column( p_columns => l_columns, p_name => 'SAL',   p_heading => 'Salário',  p_column_group_idx => l_g_remun );
    apex_data_export.add_column( p_columns => l_columns, p_name => 'COMM',  p_heading => 'Comissão', p_column_group_idx => l_g_remun );

    l_export := apex_data_export.export(
        p_context       => l_context,
        p_format        => apex_data_export.c_format_html,
        p_columns       => l_columns,
        p_column_groups => l_groups,
        p_file_name     => 'colaboradores' );

    apex_exec.close( l_context );
    apex_data_export.download( p_export => l_export );
exception
    when others then
        apex_exec.close( l_context );
        raise;
end;
```

Fonte: [ADD_COLUMN_GROUP Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_EXPORT-ADD_COLUMN_GROUP-Procedure.html)

### APEX_DATA_EXPORT.ADD_HIGHLIGHT: destacar linhas ou células com cores

```sql
PROCEDURE ADD_HIGHLIGHT (
  p_highlights        IN OUT NOCOPY t_highlights,
  p_id                IN            pls_integer,
  p_value_column      IN            apex_exec.t_column_name,
  p_display_column    IN            apex_exec.t_column_name DEFAULT NULL,
  p_text_color        IN            t_color                 DEFAULT NULL,
  p_background_color  IN            t_color                 DEFAULT NULL );
```

| Parâmetro | Descrição |
|---|---|
| `p_highlights` | Coleção de destaques (IN OUT) |
| `p_id` | ID do destaque |
| `p_value_column` | Coluna do SELECT onde o ID é procurado |
| `p_display_column` | Coluna que recebe o destaque; vazio = linha inteira |
| `p_text_color` | Cor do texto em hexa (`#FF0000`) |
| `p_background_color` | Cor do fundo em hexa |

**Comportamento:** o destaque não tem condição própria; a condição vai no SELECT. Você cria uma coluna auxiliar que vale o `p_id` quando a linha deve ser destacada e `NULL` caso contrário. Sem coleção, nada é destacado.

```sql
apex_data_export.add_highlight(
    p_highlights     => l_highlights,
    p_id             => 1,
    p_value_column   => 'HIGHLIGHT1',
    p_display_column => 'SAL',
    p_text_color     => '#FF0000' );

l_context := apex_exec.open_query_context(
    p_location  => apex_exec.c_location_local_db,
    p_sql_query => 'select empno, ename, sal,
                           case when sal >= 3000 then 1 end as HIGHLIGHT1
                      from emp' );
```

**Pegadinha:** se você não passar `p_columns`, a coluna auxiliar `HIGHLIGHT1` aparece no arquivo. Liste as colunas visíveis com `ADD_COLUMN`.

Fonte: [ADD_HIGHLIGHT Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_EXPORT-ADD_HIGHLIGHT-Procedure.html)

### APEX_DATA_EXPORT.ADD_AGGREGATE: linhas de total por quebra de controle e total geral

```sql
PROCEDURE ADD_AGGREGATE(
  p_aggregates            IN OUT NOCOPY t_aggregates,
  p_label                 IN            t_label,
  p_format_mask           IN            VARCHAR2                  DEFAULT NULL,
  p_display_column        IN            apex_exec.t_column_name,
  p_value_column          IN            apex_exec.t_column_name,
  p_overall_label         IN            t_label                   DEFAULT NULL,
  p_overall_value_column  IN            apex_exec.t_column_name   DEFAULT NULL );
```

| Parâmetro | Descrição |
|---|---|
| `p_aggregates` | Coleção de agregados (IN OUT) |
| `p_label` | Rótulo do agregado (ex.: `Soma`) |
| `p_format_mask` | Máscara aplicada ao valor |
| `p_display_column` | Coluna embaixo da qual o total aparece |
| `p_value_column` | Coluna do SELECT com o valor do agregado da quebra corrente |
| `p_overall_label` | Rótulo do total geral |
| `p_overall_value_column` | Coluna do SELECT com o valor do total geral |

**Comportamento:** o pacote não calcula a soma; ele exibe valores que a própria consulta já traz, normalmente com funções analíticas (`sum(...) over (partition by ...)` para a quebra e `sum(...) over ()` para o geral). Funciona com quebras de controle (`ADD_COLUMN ... p_is_column_break => true`) ou sozinho, só com o total geral. Sem coleção, nenhuma linha de agregado é gerada.

```sql
declare
  l_aggregates  apex_data_export.t_aggregates;
  l_columns     apex_data_export.t_columns;
  l_context     apex_exec.t_context;
  l_export      apex_data_export.t_export;
begin
  apex_data_export.add_aggregate(
    p_aggregates           => l_aggregates,
    p_label                => 'Soma',
    p_format_mask          => 'FML999G999G999G999G990D00',
    p_display_column       => 'SAL',
    p_value_column         => 'AGGREGATE1',
    p_overall_label        => 'Total geral',
    p_overall_value_column => 'OVERALL1' );

  -- colunas de quebra primeiro
  apex_data_export.add_column( p_columns => l_columns, p_name => 'DEPTNO', p_is_column_break => true );
  apex_data_export.add_column( p_columns => l_columns, p_name => 'EMPNO' );
  apex_data_export.add_column( p_columns => l_columns, p_name => 'ENAME' );
  apex_data_export.add_column( p_columns => l_columns, p_name => 'SAL' );

  l_context := apex_exec.open_query_context(
    p_location  => apex_exec.c_location_local_db,
    p_sql_query => 'select deptno, empno, ename, sal,
                           sum(sal) over (partition by deptno) as AGGREGATE1,
                           sum(sal) over ()                    as OVERALL1
                      from emp
                     order by deptno' );

  l_export := apex_data_export.export(
                p_context    => l_context,
                p_format     => apex_data_export.c_format_pdf,
                p_columns    => l_columns,
                p_aggregates => l_aggregates );

  apex_exec.close( l_context );
  apex_data_export.download( p_export => l_export );
exception
  when others then
      apex_exec.close( l_context );
      raise;
end;
```

**Pegadinha:** ordene a consulta pela coluna de quebra (`order by deptno`), senão os grupos saem fragmentados.

Fonte: [ADD_AGGREGATE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_EXPORT-ADD_AGGREGATE-Procedure.html)

### APEX_DATA_EXPORT.GET_PRINT_CONFIG: papel, orientação, fontes, cores e bordas do PDF/XLSX

```sql
FUNCTION GET_PRINT_CONFIG(
    p_units                       IN t_unit         DEFAULT c_unit_inches,
    p_paper_size                  IN t_size         DEFAULT c_size_letter,
    p_width_units                 IN t_width_unit   DEFAULT c_width_unit_percentage,
    p_width                       IN NUMBER         DEFAULT 11,
    p_height                      IN NUMBER         DEFAULT 8.5,
    p_orientation                 IN t_orientation  DEFAULT c_orientation_landscape,
    --
    p_page_header                 IN VARCHAR2       DEFAULT NULL,
    p_page_header_font_color      IN t_color        DEFAULT '#000000',
    p_page_header_font_family     IN t_font_family  DEFAULT c_font_family_helvetica,
    p_page_header_font_weight     IN t_font_weight  DEFAULT c_font_weight_normal,
    p_page_header_font_size       IN NUMBER         DEFAULT 12,
    p_page_header_alignment       IN t_alignment    DEFAULT c_align_center,
    --
    p_page_footer                 IN VARCHAR2       DEFAULT NULL,
    p_page_footer_font_color      IN t_color        DEFAULT '#000000',
    p_page_footer_font_family     IN t_font_family  DEFAULT c_font_family_helvetica,
    p_page_footer_font_weight     IN t_font_weight  DEFAULT c_font_weight_normal,
    p_page_footer_font_size       IN NUMBER         DEFAULT 12,
    p_page_footer_alignment       IN t_alignment    DEFAULT c_align_center,
    --
    p_header_bg_color             IN t_color        DEFAULT '#EEEEEE',
    p_header_font_color           IN t_color        DEFAULT '#000000',
    p_header_font_family          IN t_font_family  DEFAULT c_font_family_helvetica,
    p_header_font_weight          IN t_font_weight  DEFAULT c_font_weight_bold,
    p_header_font_size            IN NUMBER         DEFAULT 10,
    --
    p_body_bg_color               IN t_color        DEFAULT '#FFFFFF',
    p_body_font_color             IN t_color        DEFAULT '#000000',
    p_body_font_family            IN t_font_family  DEFAULT c_font_family_helvetica,
    p_body_font_weight            IN t_font_weight  DEFAULT c_font_weight_normal,
    p_body_font_size              IN NUMBER         DEFAULT 10,
    --
    p_border_width                IN NUMBER         DEFAULT .5,
    p_border_color                IN t_color        DEFAULT '#666666' )
RETURN t_print_config;
```

| Parâmetro | Descrição |
|---|---|
| `p_units` | Unidade de largura/altura da página: Inches, Millimeters, Centimeters, Points |
| `p_paper_size` | Só PDF. Letter, Legal, Tabloid, A4, A3 ou Custom (Custom usa `p_width`/`p_height`) |
| `p_width_units` | Só PDF. Unidade da largura das colunas: Percentage, Points, Pixels |
| `p_width` / `p_height` | Só PDF. Largura/altura da página (default 11 × 8.5) |
| `p_orientation` | Só PDF. Vertical (portrait) ou Horizontal (landscape); default landscape |
| `p_page_header`, `p_page_header_font_color`, `_font_family`, `_font_weight`, `_font_size`, `_alignment` | Texto e estilo do cabeçalho da página |
| `p_page_footer`, `p_page_footer_font_color`, `_font_family`, `_font_weight`, `_font_size`, `_alignment` | Texto e estilo do rodapé da página |
| `p_header_bg_color`, `p_header_font_color`, `_font_family`, `_font_weight`, `_font_size` | Estilo do cabeçalho da tabela |
| `p_body_bg_color`, `p_body_font_color`, `_font_family`, `_font_weight`, `_font_size` | Estilo do corpo da tabela |
| `p_border_width` / `p_border_color` | Espessura e cor das bordas |

Cores aceitam hexadecimal, RGB ou nomes de cor HTML. Fontes: Helvetica, Times, Courier; pesos: normal, bold.

```sql
l_print_config := apex_data_export.get_print_config(
    p_paper_size     => apex_data_export.c_size_A4,
    p_orientation    => apex_data_export.c_orientation_portrait,
    p_page_header    => 'Colaboradores ativos',
    p_page_footer    => 'Gerado em ' || to_char(sysdate, 'DD/MM/YYYY HH24:MI'),
    p_header_bg_color=> '#1F3A5F',
    p_header_font_color => '#FFFFFF',
    p_border_width   => 0.5 );

l_export := apex_data_export.export(
    p_context      => l_context,
    p_format       => apex_data_export.c_format_pdf,
    p_print_config => l_print_config );
```

**Pegadinhas:** os defaults são de papel Carta americano deitado (Letter, 11 × 8.5 polegadas, landscape); para A4 retrato passe `c_size_A4` e `c_orientation_portrait`. As constantes de orientação valem `'VERTICAL'`/`'HORIZONTAL'`, não `'PORTRAIT'`/`'LANDSCAPE'`.

Fonte: [GET_PRINT_CONFIG Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_EXPORT-GET_PRINT_CONFIG-Procedure.html), [Global Constants](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_EXPORT-Global-Constants.html)

### APEX_DATA_EXPORT.DOWNLOAD: enviar o arquivo ao navegador (attachment ou inline)

```sql
APEX_DATA_EXPORT.DOWNLOAD (
    p_export                IN OUT NOCOPY t_export,
    p_content_disposition   IN t_content_disposition    DEFAULT c_attachment,
    p_add_file_extension    IN BOOLEAN                  DEFAULT TRUE,
    p_stop_apex_engine      IN BOOLEAN                  DEFAULT TRUE )
```

| Parâmetro | Descrição |
|---|---|
| `p_export` | Resultado de `EXPORT` |
| `p_content_disposition` | `c_attachment` (baixar) ou `c_inline` (abrir no navegador, ex.: PDF numa aba) |
| `p_add_file_extension` | `TRUE` acrescenta a extensão conforme o formato ao nome do arquivo |
| `p_stop_apex_engine` | `TRUE` chama `APEX_APPLICATION.STOP_APEX_ENGINE` ao final |

**Comportamento:** grava os cabeçalhos HTTP e o conteúdo na resposta. Com `p_stop_apex_engine => TRUE` (default), o processamento da página termina ali: processos posteriores, branches e mensagens de sucesso não rodam. Use num processo de página *Before Header* ou *After Submit* acionado por um botão/request específico, ou num Ajax callback chamado por URL.

```sql
-- processo "Exportar CSV" (Point: Before Header, condição: Request = EXPORTAR_CSV)
declare
    l_context apex_exec.t_context;
    l_export  apex_data_export.t_export;
begin
    l_context := apex_exec.open_query_context(
        p_location  => apex_exec.c_location_local_db,
        p_sql_query => 'select * from emp' );

    l_export := apex_data_export.export(
        p_context   => l_context,
        p_format    => apex_data_export.c_format_csv,
        p_file_name => 'employees' );   -- vira employees.csv

    apex_exec.close( l_context );
    apex_data_export.download( p_export => l_export );
exception
    when others then
        apex_exec.close( l_context );
        raise;
end;
```

**Pegadinha:** como `p_add_file_extension` existe e é `TRUE` por padrão, passe `p_file_name` **sem** extensão (com extensão, o nome tende a sair duplicado, como `relatorio.xlsx.xlsx`). Em código que usa o `t_export` fora do `DOWNLOAD` (e-mail, tabela), acrescente a extensão você mesmo.

Fonte: [DOWNLOAD Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_EXPORT-DOWNLOAD-Procedure.html)

### APEX_DATA_EXPORT: exemplo completo com bind variables, XLSX formatado e download

Consulta com bind explícito via `p_sql_parameters` (`APEX_EXEC.ADD_PARAMETER`), colunas escolhidas, coluna congelada, total geral e print config. Em `OPEN_QUERY_CONTEXT`, `p_auto_bind_items` é `TRUE` por padrão, então itens de página/aplicação referenciados como `:P12_X` também seriam ligados automaticamente; o parâmetro explícito deixa o código independente de session state (útil em jobs).

```sql
declare
    l_params   apex_exec.t_parameters;
    l_context  apex_exec.t_context;
    l_columns  apex_data_export.t_columns;
    l_aggs     apex_data_export.t_aggregates;
    l_export   apex_data_export.t_export;
begin
    apex_exec.add_parameter( l_params, 'ID_EMPRESA', to_number(:G_ID_EMPRESA) );

    l_context := apex_exec.open_query_context(
        p_location       => apex_exec.c_location_local_db,
        p_sql_query      => q'[select c.nome, d.nome as departamento, g.nome as cargo,
                                      c.data_admissao,
                                      count(*) over () as total_geral
                                 from colaborador c
                                 join departamento d on d.id_departamento = c.id_departamento
                                 join cargo g        on g.id_cargo        = c.id_cargo
                                where c.id_empresa = :ID_EMPRESA
                                order by d.nome, c.nome]',
        p_sql_parameters => l_params );

    apex_data_export.add_column( l_columns, p_name => 'NOME',          p_heading => 'Colaborador', p_is_frozen => true );
    apex_data_export.add_column( l_columns, p_name => 'DEPARTAMENTO',  p_heading => 'Departamento' );
    apex_data_export.add_column( l_columns, p_name => 'CARGO',         p_heading => 'Cargo' );
    apex_data_export.add_column( l_columns, p_name => 'DATA_ADMISSAO', p_heading => 'Admissão', p_format_mask => 'DD/MM/YYYY' );

    apex_data_export.add_aggregate(
        p_aggregates           => l_aggs,
        p_label          => 'Total de colaboradores',
        p_display_column => 'NOME',
        p_value_column   => 'TOTAL_GERAL' );   -- sem quebra: o valor é o total geral

    l_export := apex_data_export.export(
        p_context      => l_context,
        p_format       => apex_data_export.c_format_xlsx,
        p_columns      => l_columns,
        p_aggregates   => l_aggs,
        p_file_name    => 'colaboradores',
        p_page_header  => 'Colaboradores' );

    apex_exec.close( l_context );
    apex_data_export.download( p_export => l_export );
exception
    when others then
        apex_exec.close( l_context );
        raise;
end;
```

Assinatura de `APEX_EXEC.ADD_PARAMETER` (há sobrecargas para `VARCHAR2`, `NUMBER`, `DATE`, `TIMESTAMP`, `TIMESTAMP WITH TIME ZONE` etc.):

```sql
APEX_EXEC.ADD_PARAMETER (
    p_parameters IN OUT NOCOPY t_parameters,
    p_name       IN            t_column_name,
    p_value      IN            VARCHAR2 )   -- ou NUMBER, DATE, TIMESTAMP...
```

Fonte: [EXPORT Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_EXPORT-EXPORT-Function.html), [APEX_EXEC.OPEN_QUERY_CONTEXT Function Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.OPEN_QUERY_CONTEXT-Function-1.html), [APEX_EXEC.ADD_PARAMETER](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.ADD_ORDER_BY-Procedure.html)

### APEX_DATA_EXPORT: gerar BLOB (PDF/XLSX) e enviar como anexo de e-mail com APEX_MAIL

Sem `DOWNLOAD`: o `t_export.content_blob` vai direto para `APEX_MAIL.ADD_ATTACHMENT` (assinatura BLOB: `p_mail_id`, `p_attachment`, `p_filename`, `p_mime_type`, `p_content_id` opcional). Serve para automations e jobs, onde não há navegador.

```sql
declare
    l_context  apex_exec.t_context;
    l_export   apex_data_export.t_export;
    l_mail_id  number;
begin
    l_context := apex_exec.open_query_context(
        p_location  => apex_exec.c_location_local_db,
        p_sql_query => 'select empno, ename, job, sal from emp order by ename' );

    l_export := apex_data_export.export(
        p_context      => l_context,
        p_format       => apex_data_export.c_format_pdf,      -- BLOB (p_as_clob = false)
        p_file_name    => 'relatorio_semanal',
        p_print_config => apex_data_export.get_print_config(
                              p_paper_size  => apex_data_export.c_size_A4,
                              p_orientation => apex_data_export.c_orientation_portrait ) );
    apex_exec.close( l_context );

    l_mail_id := apex_mail.send(
        p_to        => 'rh@example.com',
        p_from      => 'noreply@example.com',
        p_subj      => 'Relatório semanal',
        p_body      => 'Segue o relatório em anexo.',
        p_body_html => '<p>Segue o relatório em anexo.</p>' );

    apex_mail.add_attachment(
        p_mail_id    => l_mail_id,
        p_attachment => l_export.content_blob,
        p_filename   => l_export.file_name || '.pdf',  -- DOWNLOAD é quem acrescenta a extensão
        p_mime_type  => l_export.mime_type );
exception
    when others then
        apex_exec.close( l_context );
        raise;
end;
```

O mesmo BLOB pode ir para uma tabela (`insert into arquivo(nome, mime_type, conteudo) values (l_export.file_name || '.xlsx', l_export.mime_type, l_export.content_blob)`). Para CSV/JSON em texto, passe `p_as_clob => true` e use `content_clob`.

Fonte: [EXPORT Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_EXPORT-EXPORT-Function.html), [Data Types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_EXPORT-Data-Types.html), [APEX_MAIL.ADD_ATTACHMENT Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_ATTACHMENT-Procedure-Signature-1.html)

### Código depois de APEX_DATA_EXPORT.DOWNLOAD não executa (processos, branches e mensagens somem)

**Sintoma:** após o download, o processo seguinte, a mensagem de sucesso ou o branch não acontecem; ou o `APEX_EXEC.CLOSE` posto depois do `DOWNLOAD` nunca roda.
**Causa:** `DOWNLOAD` chama `APEX_APPLICATION.STOP_APEX_ENGINE` por padrão (`p_stop_apex_engine => TRUE`), encerrando o request.
**Correção:** feche o contexto antes do `DOWNLOAD` e deixe o download como último passo de um processo dedicado. Se precisar de controle próprio, `p_stop_apex_engine => FALSE` evita a chamada ao `STOP_APEX_ENGINE`; aí o encerramento do request fica por sua conta.
**Prevenção:** siga o padrão oficial `export` → `apex_exec.close` → `download`, com `apex_exec.close` também no `EXCEPTION`.

Fonte: [DOWNLOAD Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_EXPORT-DOWNLOAD-Procedure.html)

### Colunas auxiliares (HIGHLIGHT1, AGGREGATE1, OVERALL1) aparecem no arquivo exportado

**Sintoma:** o PDF/XLSX traz colunas técnicas usadas para destaque ou total.
**Causa:** sem `p_columns`, `EXPORT` inclui todas as colunas do query context.
**Correção:** monte `t_columns` com `ADD_COLUMN` apenas para as colunas visíveis e passe em `p_columns`; as colunas auxiliares continuam no SELECT para alimentar `ADD_HIGHLIGHT`/`ADD_AGGREGATE`.

Fonte: [ADD_COLUMN Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_EXPORT-ADD_COLUMN-Procedure.html), [ADD_HIGHLIGHT Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_EXPORT-ADD_HIGHLIGHT-Procedure.html)

### Exportação PDF ou XLSX com p_as_clob => TRUE vem vazia ou corrompida

**Sintoma:** `content_clob` de um PDF/XLSX não abre ou `content_blob` está nulo.
**Causa:** PDF e XLSX são binários; o modo CLOB serve a formatos texto (a doc de `APEX_REGION.EXPORT_DATA`, que usa o mesmo `t_export`, diz que CLOB não funciona com PDF e XLSX).
**Correção:** use `p_as_clob => FALSE` (default) e leia `content_blob` para PDF/XLSX; reserve CLOB para CSV, HTML, JSON e XML.

Fonte: [EXPORT Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_EXPORT-EXPORT-Function.html), [APEX_REGION.EXPORT_DATA Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_REGION-EXPORT_DATA-Function.html)


## 09. APEX_DATA_PARSER: ler arquivos CSV, XLSX, XML e JSON como tabela em SQL

### APEX_DATA_PARSER: propósito, quando usar e quando não usar

`APEX_DATA_PARSER` é o parser de arquivos do APEX (o mesmo usado pelo Data Loading nativo). Sua peça central é a table function pipelined `PARSE`, que recebe o arquivo como BLOB e devolve linhas do tipo `APEX_T_PARSER_ROW`: `LINE_NUMBER` mais `COL001` … `COL300` (valores em `VARCHAR2`, até 4000 bytes) e até 20 colunas `CLOB01`… para valores grandes. Formatos: CSV, XLSX, XML e JSON (a constante de tipo também prevê ICS). O parsing acontece no momento da consulta: nada é escrito em collection ou tabela temporária.

Durante o `PARSE` (sem profile informado) o pacote calcula um **file profile** em JSON: tipo do arquivo, encoding, delimitador CSV, planilha, se a primeira linha é cabeçalho e, por coluna, nome, tipo detectado (`NUMBER`, `DATE`, `TIMESTAMP`, `VARCHAR2`) e máscara de formato. `GET_FILE_PROFILE` lê esse profile, `DISCOVER` faz parse + profile numa chamada, `GET_COLUMNS` mostra as colunas do profile como tabela e `JSON_TO_PROFILE` converte para o record `t_file_profile`.

- **Quando usar:** pré-visualizar um arquivo enviado por *File Upload* (lendo `APEX_APPLICATION_TEMP_FILES`) num Classic Report; importar planilhas com regras próprias em PL/SQL (`INSERT ... SELECT ... FROM TABLE(apex_data_parser.parse(...))`); ler um JSON/XML vindo de um web service; validar a extensão de um arquivo (`ASSERT_FILE_TYPE`); listar planilhas de um XLSX (`GET_XLSX_WORKSHEETS`).
- **Quando não usar:** se a estrutura é fixa e o destino é uma tabela/collection com Append/Merge/Replace e tratamento de erro padrão, crie uma *Data Load Definition* e use o processo nativo *Data Loading* ou `APEX_DATA_LOADING.LOAD_DATA` (seção 10). O parser continua útil para o preview, combinando `p_file_profile => apex_data_loading.get_file_profile(...)`.
- **Limites:** 300 colunas por linha; 4000 bytes por coluna `VARCHAR2`; 20 colunas podem ser CLOB; sem limite de tamanho de linha.
- **Pegadinha geral:** os nomes de coluna do resultado são sempre `COL001`… e a linha de cabeçalho do arquivo vem como dado (linha 1). Filtre `line_number > 1` quando o arquivo tem cabeçalho, ou use o profile para saber os nomes reais.

Fonte: [APEX_DATA_PARSER](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_PARSER.html), [PARSE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_PARSER.PARSE-Function.html), [Parsing Data Without Data Load Definition](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/parsing-data-data-load-definition.html)

### APEX_DATA_PARSER: referência completa de procedures, functions, constantes e tipos

| Item | Tipo | O que faz |
|---|---|---|
| `ASSERT_FILE_TYPE` | function | `TRUE` se a extensão do nome do arquivo corresponde ao `t_file_type` informado |
| `DISCOVER` | function | Faz o parse (até `p_max_rows`, default 200) e devolve o file profile em JSON (CLOB) |
| `GET_COLUMNS` | function pipelined | Colunas de um profile como linhas `apex_t_parser_columns` (posição, nome, tipo, máscara) |
| `GET_FILE_PROFILE` | function | Profile JSON calculado pela última chamada de `PARSE` |
| `GET_FILE_TYPE` | function | Deduz o `t_file_type` pela extensão do nome do arquivo |
| `GET_XLSX_WORKSHEETS` | function | Lista as planilhas de um XLSX (`apex_t_parser_worksheets`) |
| `JSON_TO_PROFILE` | function | Converte o profile JSON no record `t_file_profile` |
| `PARSE` | function pipelined | Lê o arquivo e devolve `apex_t_parser_table` (linhas `LINE_NUMBER`, `COL001`…`COL300`) |
| `SET_PARSER_FLAGS` | procedure | Define flags de comportamento (hoje: `CSV_BACKSLASH_ESCAPING`) |
| `t_file_type` | subtype | `pls_integer range 1..5` |
| `c_file_type_xlsx` | constante | `1` |
| `c_file_type_csv` | constante | `2` |
| `c_file_type_xml` | constante | `3` |
| `c_file_type_json` | constante | `4` |
| `c_file_type_ics` | constante | `5` |
| `t_file_profile` | tipo (record) | Profile do arquivo (ver seção de tipos) |
| `t_file_column` / `t_file_columns` | tipo (record / table index by pls_integer) | Coluna do profile |

Tipos de resultado (objetos SQL do APEX): `apex_t_parser_row`/`apex_t_parser_table` (`PARSE`), `apex_t_parser_columns` (`GET_COLUMNS`), `apex_t_parser_worksheet`/`apex_t_parser_worksheets` (`GET_XLSX_WORKSHEETS`). Nada está marcado como deprecated na doc 26.1.

Fonte: [APEX_DATA_PARSER](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_PARSER.html), [Global Constants](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_PARSER.Global-Constants.html), [Data Types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_PARSER.Data-Types.html)

### APEX_DATA_PARSER: tipos t_file_profile e t_file_column (estrutura do file profile)

```sql
type t_file_profile is record(
    file_type               t_file_type,
    file_charset            VARCHAR2(128),
    row_selector            VARCHAR2(32767),
    is_single_row           BOOLEAN,
    first_row_headings      BOOLEAN,
    xlsx_worksheet          VARCHAR2(128),
    xml_namespaces          VARCHAR2(4000),
    csv_delimiter           VARCHAR2(4),
    csv_enclosed            VARCHAR2(4),
    null_if                 VARCHAR2(20),
    force_trim_whitespace   BOOLEAN,
    skip_rows               PLS_INTEGER,
    file_columns            t_file_columns
);

type t_file_columns is table of t_file_column index by pls_integer;

type t_file_column is record(
    col_seq         PLS_INTEGER,
    name            VARCHAR2(128),
    data_type       apex_exec_api.t_data_type,
    data_type_len   PLS_INTEGER,
    is_json         BOOLEAN,
    selector        VARCHAR2(32767),
    decimal_char    VARCHAR2(4),
    group_char      VARCHAR2(4),
    format_mask     VARCHAR2(128),
    clob_column     PLS_INTEGER
);
```

O mesmo profile em JSON (o que `DISCOVER`/`GET_FILE_PROFILE` devolvem) usa chaves como `"file-type"`, `"file-encoding"`, `"csv-delimiter"`, `"xlsx-worksheet"`, `"headings-in-first-row"`, `"single-row"`, `"parsed-rows"`, `"row-selector"` e `"columns"` (cada uma com `"name"`, `"data-type"`, `"format-mask"`, `"selector"`). Nos exemplos oficiais, `data-type` 1 aparece para texto, 2 para número e 3 para data.

Fonte: [Data Types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_PARSER.Data-Types.html), [DISCOVER Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_PARSER.DISCOVER-Function.html)

### APEX_DATA_PARSER.PARSE: ler um arquivo BLOB e devolver linhas COL001…COL300

```sql
APEX_DATA_PARSER.PARSE (
    p_content                      IN BLOB,
    p_file_name                    IN VARCHAR2     DEFAULT NULL,
    p_file_type                    in t_file_type  DEFAULT NULL,
    p_file_profile                 IN CLOB         DEFAULT NULL,
    --
    p_detect_data_types            IN VARCHAR2     DEFAULT 'Y',
    p_decimal_char                 IN VARCHAR2     DEFAULT NULL,
    --
    p_xlsx_sheet_name              IN VARCHAR2     DEFAULT NULL,
    --
    p_row_selector                 IN VARCHAR2     DEFAULT NULL,
    --
    p_csv_row_delimiter            IN VARCHAR2     DEFAULT LF,
    p_csv_col_delimiter            IN VARCHAR2     DEFAULT NULL,
    p_csv_enclosed                 IN VARCHAR2     DEFAULT '"',
    --
    p_skip_rows                    IN PLS_INTEGER  DEFAULT NULL,
    p_add_headers_row              IN VARCHAR2     DEFAULT 'N',
    --
    p_nullif                       IN VARCHAR2     DEFAULT NULL,
    p_force_trim_whitespace        IN VARCHAR2     DEFAULT 'N',
    --
    p_file_charset                 IN VARCHAR2     DEFAULT 'AL32UTF8',
    p_max_rows                     IN NUMBER       DEFAULT NULL,
    p_return_rows                  IN NUMBER       DEFAULT NULL,
    --
    p_store_profile_to_collection  IN VARCHAR2     DEFAULT NULL,
    p_xml_namespaces               IN VARCHAR2     DEFAULT NULL,
    --
    p_fix_excel_precision          IN VARCHAR2     DEFAULT 'N' )
    RETURN apex_t_parser_table pipelined;
```

| Parâmetro | Descrição |
|---|---|
| `p_content` | Conteúdo do arquivo (BLOB) |
| `p_file_name` | Nome do arquivo, usado só para deduzir o tipo pela extensão |
| `p_file_type` | Tipo explícito (`c_file_type_*`). É obrigatório passar `p_file_name`, `p_file_type` **ou** `p_file_profile` |
| `p_file_profile` | Profile calculado antes (`parse`/`discover`/Data Load Definition). Pula parte da detecção e melhora a performance |
| `p_detect_data_types` | `Y` (default) detecta `NUMBER`, `DATE`, `TIMESTAMP` e grava no profile; `N` = tudo `VARCHAR2(4000)` |
| `p_decimal_char` | Separador decimal para detectar números; nulo = autodetecção |
| `p_xlsx_sheet_name` | XLSX: planilha a ler (nome de arquivo interno, ex.: `sheet1.xml`); nulo = primeira |
| `p_row_selector` | JSON/XML: caminho até o array/lista de linhas. Nulo: XML usa `/*/*`; JSON usa o primeiro array encontrado |
| `p_csv_row_delimiter` | Delimitador de linha (1 caractere). Default LF, que também trata CRLF |
| `p_csv_col_delimiter` | Delimitador de coluna; nulo = detectado pela primeira linha |
| `p_csv_enclosed` | Caractere de enclausuramento; default `"` |
| `p_skip_rows` | Pula as N primeiras linhas |
| `p_add_headers_row` | XML/JSON: emite os nomes (tags, atributos) como primeira linha |
| `p_nullif` | Como `NULLIF` do SQL: esse valor vira `NULL` |
| `p_force_trim_whitespace` | Remove espaços dentro de valores entre aspas; default `N` |
| `p_file_charset` | Encoding; nulo ou omitido = `AL32UTF8` |
| `p_max_rows` | Para de fazer parse após devolver N linhas |
| `p_return_rows` | Quantas linhas devolver; o parse continua (refinando os tipos) até `p_max_rows` ou até o `rownum` da consulta cortar |
| `p_store_profile_to_collection` | Grava o profile calculado numa collection (limpa se já existir); só para profiles calculados |
| `p_xml_namespaces` | Namespaces para XML |
| `p_fix_excel_precision` | XLSX: arredonda números para 15 dígitos significativos (corrige ruído de ponto flutuante do Excel); default `N` |

**Comportamento em tempo de execução:**
- Sem `p_file_profile`, o profile é calculado durante o parse e fica disponível em `GET_FILE_PROFILE` ao final (sequência recomendada: `PARSE` para preview → `GET_FILE_PROFILE` → processar os dados com SQL gerado a partir do profile).
- XLSX é lido em fases: `APEX_ZIP` extrai os XMLs do arquivo e `XMLTABLE` faz o parse.
- **CLOB:** CSV e XLSX suportam CLOB até 32K e detectam colunas CLOB na descoberta; XML suporta mais de 32K e também detecta. Com profile descoberto, valores pequenos vêm em `COLnnn`; valores grandes vêm em `CLOBnn` e os primeiros 1000 caracteres em `COLnnn`. Se você passar um profile com coluna CLOB definida, os valores vêm só em `CLOBnn`. JSON não detecta CLOB na descoberta: o suporte só liga se o profile passado tiver coluna CLOB, e aí o parser usa processamento baseado em XMLTYPE, bem mais lento.
- **CSV grande:** abaixo de 50 MB o BLOB é copiado para um LOB temporário em cache e o parse é em memória; acima disso o parse usa o locator original (pode ir a disco e ficar bem mais lento). Para forçar memória em arquivos maiores, crie um LOB temporário com `DBMS_LOB.CREATETEMPORARY(..., cache => TRUE)`, copie com `DBMS_LOB.COPY` e passe-o ao `PARSE`.

Exemplos oficiais (XLSX com planilha escolhida e JSON com detecção automática):

```sql
select line_number, col001, col002, col003, col004, col005, col006, col007, col008
  from table( apex_data_parser.parse(
                  p_content         => :blob_xlsx,
                  p_file_name       => 'test.xlsx',
                  p_xlsx_sheet_name => 'sheet1.xml' ) );

select line_number, col001, col002, col003, col004, col005
  from table( apex_data_parser.parse(
                  p_content   => :blob_json,
                  p_file_name => 'test.json' ) );
```

Fonte: [PARSE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_PARSER.PARSE-Function.html)

### APEX_DATA_PARSER.PARSE com APEX_APPLICATION_TEMP_FILES: preview e importação de arquivo enviado por File Upload

Um item *File Upload* com *Storage Type* = *Table APEX_APPLICATION_TEMP_FILES* guarda o arquivo na view `APEX_APPLICATION_TEMP_FILES` (coluna `BLOB_CONTENT`, `FILENAME`), identificado pelo valor do item (`NAME`). O APEX apaga o arquivo no fim da sessão ou do request, conforme *Purge File At*.

**Preview num Classic Report** (condição: item não nulo), no padrão da página gerada pelo assistente de Data Loading:

```sql
select p.line_number,
       p.col001, p.col002, p.col003, p.col004, p.col005,
       p.col006, p.col007, p.col008, p.col009, p.col010
  from apex_application_temp_files f,
       table( apex_data_parser.parse(
                  p_content         => f.blob_content,
                  p_file_name       => f.filename,
                  p_xlsx_sheet_name => case when :P32_XLSX_WORKSHEET is not null
                                            then :P32_XLSX_WORKSHEET end,
                  p_max_rows        => 100 ) ) p
 where f.name = :P32_FILE
```

Ordene a coluna `LINE_NUMBER` de forma ascendente no relatório para manter a ordem do arquivo.

**Importação com regras próprias** (processo PL/SQL após submit), pulando o cabeçalho e convertendo tipos:

```sql
begin
    insert into colaborador_import (id_empresa, nome, email, data_admissao, salario)
    select :G_ID_EMPRESA,
           p.col001,
           lower(p.col002),
           to_date(p.col003, 'DD/MM/YYYY'),
           to_number(p.col004, '999999D99', 'NLS_NUMERIC_CHARACTERS='',.''')
      from apex_application_temp_files f,
           table( apex_data_parser.parse(
                      p_content           => f.blob_content,
                      p_file_name         => f.filename,
                      p_csv_col_delimiter => ';',
                      p_detect_data_types => 'N' ) ) p
     where f.name = :P40_ARQUIVO
       and p.line_number > 1;          -- linha 1 = cabeçalho
end;
```

**Usar o profile de uma Data Load Definition** para o preview (os tipos e a planilha vêm da definição):

```sql
table( apex_data_parser.parse(
           p_content      => f.blob_content,
           p_file_name    => f.filename,
           p_file_profile => apex_data_loading.get_file_profile( p_static_id => 'my-load-definition' ),
           p_max_rows     => 100 ) )
```

Fonte: [PARSE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_PARSER.PARSE-Function.html), [Previewing External Data Before Loading](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/previewing-external-data-loading.html), [APEX_DATA_LOADING.GET_FILE_PROFILE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_LOADING.GET_FILE_PROFILE-Function.html), [About Item Types](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-item-types.html)

### APEX_DATA_PARSER.DISCOVER: descobrir o profile (colunas e tipos) de um arquivo numa chamada

```sql
APEX_DATA_PARSER.DISCOVER (
    p_content                   IN BLOB,
    p_file_name                 IN VARCHAR2,
    --
    p_decimal_char              IN VARCHAR2     DEFAULT NULL,
    --
    p_xlsx_sheet_name           IN VARCHAR2     DEFAULT NULL,
    --
    p_row_selector              IN VARCHAR2     DEFAULT NULL,
    --
    p_csv_row_delimiter         IN VARCHAR2     DEFAULT LF,
    p_csv_col_delimiter         IN VARCHAR2     DEFAULT NULL,
    p_csv_enclosed              IN VARCHAR2     DEFAULT '"',
    --
    p_skip_rows                 IN PLS_INTEGER  DEFAULT NULL,
    --
    p_nullif                    IN VARCHAR2     DEFAULT NULL,
    p_force_trim_whitespace     IN VARCHAR2     DEFAULT 'Y',
    --
    p_file_charset              IN VARCHAR2     DEFAULT 'AL32UTF8',
    p_max_rows                  IN NUMBER       DEFAULT 200,
    --
    p_xml_namespaces            IN VARCHAR2     DEFAULT NULL )
    RETURN CLOB;
```

Os parâmetros têm o mesmo significado que em `PARSE`. Diferenças: `p_file_name` é obrigatório (não há `p_file_type`), `p_max_rows` tem default **200** (a descoberta para depois de 200 linhas), `p_force_trim_whitespace` tem default **`Y`** (no `PARSE` é `N`), e `p_skip_rows` existe também para XML/JSON, para igualar o comportamento de CSV/XLSX.

**Retorno:** CLOB com o profile em JSON. É um atalho para `PARSE` seguido de `GET_FILE_PROFILE`.

```sql
select apex_data_parser.discover(
           p_content   => f.blob_content,
           p_file_name => f.filename ) as profile_json
  from apex_application_temp_files f
 where f.name = :P40_ARQUIVO;
```

**Pegadinha:** como os defaults de `p_force_trim_whitespace` diferem, um profile descoberto com `DISCOVER` e um parse feito sem profile podem tratar espaços de forma diferente. Passe o profile de volta em `PARSE.p_file_profile` para manter coerência.

Fonte: [DISCOVER Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_PARSER.DISCOVER-Function.html)

### APEX_DATA_PARSER.GET_FILE_PROFILE, GET_COLUMNS e JSON_TO_PROFILE: ler o profile calculado

```sql
APEX_DATA_PARSER.GET_FILE_PROFILE RETURN CLOB;

APEX_DATA_PARSER.GET_COLUMNS (
    p_profile             IN CLOB )
    RETURN apex_t_parser_columns PIPELINED;

APEX_DATA_PARSER.JSON_TO_PROFILE (
    p_json  IN CLOB )
    RETURN t_file_profile;
```

- `GET_FILE_PROFILE` (sem parâmetros) devolve o profile JSON calculado pela **última** execução de `PARSE` (o profile só é calculado quando nenhum é passado). Chame-o depois de consumir o `PARSE`.
- `GET_COLUMNS` devolve uma linha por coluna do profile, com `COLUMN_POSITION`, `COLUMN_NAME`, `DATA_TYPE` e `FORMAT_MASK` — útil para mostrar ao usuário o mapeamento "COL001 = NOME" ou montar SQL dinâmico.
- `JSON_TO_PROFILE` converte o JSON no record `t_file_profile`, para ler `csv_delimiter`, `first_row_headings`, `file_columns(i).name` etc. em PL/SQL.

```sql
-- nomes e tipos detectados num XLSX enviado
select c.column_position, c.column_name, c.data_type, c.format_mask
  from apex_application_temp_files f,
       table( apex_data_parser.get_columns(
                  apex_data_parser.discover(
                      p_content   => f.blob_content,
                      p_file_name => f.filename ) ) ) c
 where f.name = :P40_ARQUIVO;

-- profile em PL/SQL
declare
    l_profile apex_data_parser.t_file_profile;
begin
    l_profile := apex_data_parser.json_to_profile('{"file-type": 2, "csv-delimiter": ","}');
    if l_profile.first_row_headings then
        null;
    end if;
end;
```

Exemplo de saída de `GET_COLUMNS`: `1 C0 NUMBER`, `2 FIRST_NAME VARCHAR2`, …, `7 DATE_ DATE DD"/"MM"/"YYYY`. No exemplo oficial, os cabeçalhos aparecem normalizados: "First Name" vira `FIRST_NAME` e "Date" vira `DATE_`.

**Pegadinha:** o exemplo oficial de `JSON_TO_PROFILE` declara `l_profile t_file_profile;` sem prefixo; fora do pacote é preciso `apex_data_parser.t_file_profile`.

Fonte: [GET_FILE_PROFILE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_PARSER.GET_FILE_PROFILE-Function.html), [GET_COLUMNS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_PARSER.GET_COLUMNS-Function.html), [JSON_TO_PROFILE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_PARSER.JSON_TO_PROFILE-Function.html)

### APEX_DATA_PARSER.GET_XLSX_WORKSHEETS: listar planilhas de um XLSX (LOV e condição)

```sql
APEX_DATA_PARSER.GET_XLSX_WORKSHEETS (
    p_content   IN BLOB )
RETURN apex_t_parser_worksheets;
```

Devolve uma linha por planilha com `SHEET_SEQUENCE`, `SHEET_DISPLAY_NAME` (nome visível, ex.: `Sheet1`), `SHEET_FILE_NAME` (ex.: `sheet1.xml`) e `SHEET_PATH` (ex.: `worksheets/sheet1.xml`). O valor que `PARSE.p_xlsx_sheet_name` espera é o `SHEET_FILE_NAME`.

LOV de um Select List para o usuário escolher a planilha (padrão da página de Data Loading gerada):

```sql
select p.sheet_display_name d,
       p.sheet_file_name    r
  from apex_application_temp_files f,
       table( apex_data_parser.get_xlsx_worksheets( p_content => f.blob_content ) ) p
 where f.name = :P32_FILE
```

Condição do Select List (*Function Body*) para só exibi-lo quando há mais de uma planilha:

```sql
declare
    l_sheet_count number;
begin
    select count(*)
      into l_sheet_count
      from apex_application_temp_files f,
           table( apex_data_parser.get_xlsx_worksheets( p_content => f.blob_content ) ) p
     where f.name = :P32_FILE;
    return l_sheet_count > 1;
exception
    when others then
        return false;
end;
```

Uma Dynamic Action *Change* no Select List com *Submit Page* re-renderiza o preview com a planilha escolhida.

Fonte: [GET_XLSX_WORKSHEETS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_PARSER.GET_XLSX_WORKSHEETS-Function.html), [Letting User Select Worksheet](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/letting-user-select-worksheet.html)

### APEX_DATA_PARSER.ASSERT_FILE_TYPE e GET_FILE_TYPE: validar e deduzir o tipo pela extensão

```sql
APEX_DATA_PARSER.ASSERT_FILE_TYPE (
    p_file_name IN VARCHAR2,
    p_file_type IN t_file_type )
RETURN BOOLEAN;

APEX_DATA_PARSER.GET_FILE_TYPE (
    p_file_name IN VARCHAR2 )
RETURN t_file_type;
```

`ASSERT_FILE_TYPE` retorna `TRUE` quando a extensão do nome casa com o tipo; `GET_FILE_TYPE` devolve o tipo (1 = XLSX, 2 = CSV, 3 = XML, 4 = JSON, 5 = ICS) a partir da extensão.

Validação *PL/SQL Function Body (returning Boolean)* num item File Upload, como na página gerada pelo assistente:

```sql
if apex_data_parser.assert_file_type(
       p_file_name => :P32_FILE_NAME,
       p_file_type => apex_data_parser.c_file_type_xlsx )
then
    return true;
else
    :P32_FILE := null;
    return false;
end if;
```

**Pegadinha:** as duas funções olham só a **extensão** do nome, não o conteúdo; um arquivo renomeado passa. Trate exceções do `PARSE` para arquivos com conteúdo inválido.

Fonte: [ASSERT_FILE_TYPE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_PARSER.ASSERT_FILE_TYPE-Function.html), [GET_FILE_TYPE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_PARSER.GET_FILE_TYPE-Function.html), [Validating the Uploaded File Type](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/validating-uploaded-file-type.html)

### APEX_DATA_PARSER.SET_PARSER_FLAGS: desligar o escape por barra invertida no CSV

```sql
APEX_DATA_PARSER.SET_PARSER_FLAGS (
    p_name  IN VARCHAR2,
    p_value IN VARCHAR2 )
```

Única flag documentada: `CSV_BACKSLASH_ESCAPING`. Com `Y` (default, por compatibilidade) a barra invertida funciona como escape adicional do caractere de enclausuramento. Desligue quando o CSV contém `\` literal antes de aspas (caminhos Windows, por exemplo):

```sql
begin
    apex_data_parser.set_parser_flags( p_name => 'CSV_BACKSLASH_ESCAPING', p_value => 'N' );
end;
```

Fonte: [SET_PARSER_FLAGS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_PARSER.SET_PARSER_FLAGS-Procedure.html)

### APEX_DATA_PARSER.PARSE lento com CSV acima de 50 MB

**Sintoma:** o parse de CSVs grandes fica muito mais lento a partir de ~50 MB.
**Causa:** abaixo de 50 MB o APEX copia o BLOB para um LOB temporário em cache (parse em memória); acima, usa o locator original, que pode ler do disco.
**Correção:** crie um LOB temporário com cache e passe-o ao `PARSE`:

```sql
declare
    l_src blob;
    l_tmp blob;
begin
    select blob_content into l_src from apex_application_temp_files where name = :P40_ARQUIVO;
    dbms_lob.createtemporary( l_tmp, cache => true );
    dbms_lob.copy( l_tmp, l_src, dbms_lob.getlength(l_src) );
    insert into staging (c1, c2)
    select col001, col002 from table( apex_data_parser.parse( p_content => l_tmp, p_file_name => 'x.csv' ) );
    dbms_lob.freetemporary( l_tmp );
end;
```

Fonte: [PARSE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_PARSER.PARSE-Function.html)

### APEX_DATA_PARSER.PARSE com JSON corta textos longos ou não preenche CLOBnn

**Sintoma:** em arquivos JSON, valores com mais de 4000 bytes vêm truncados/ausentes e `CLOB01` fica vazio.
**Causa:** para JSON, colunas CLOB não são detectadas na descoberta; o suporte só é ativado quando um profile com coluna CLOB é passado em `p_file_profile`.
**Correção:** monte (ou ajuste) um profile JSON com a coluna marcada como CLOB e passe-o em `p_file_profile`. Espere processamento bem mais lento, porque o parser passa a usar XMLTYPE em vez de `JSON_TABLE`.

Fonte: [PARSE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_PARSER.PARSE-Function.html)

### Números de XLSX com dígitos espúrios de ponto flutuante no APEX_DATA_PARSER

**Sintoma:** valores numéricos de um XLSX chegam com muitos dígitos espúrios.
**Causa:** o Excel guarda números como ponto flutuante com no máximo 15 dígitos significativos; resultados de fórmulas podem ter ruído de arredondamento.
**Correção:** passe `p_fix_excel_precision => 'Y'` em `PARSE`, que arredonda para 15 dígitos significativos.

Fonte: [PARSE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_PARSER.PARSE-Function.html)

### APEX_DATA_PARSER.PARSE chamado sem p_file_name, p_file_type nem p_file_profile

**Sintoma:** chamada de `PARSE` só com `p_content` não funciona.
**Causa:** o parser precisa saber o formato; é obrigatório informar `p_file_name` (extensão), `p_file_type` ou `p_file_profile`.
**Correção:** passe `p_file_name => f.filename` da `APEX_APPLICATION_TEMP_FILES`, ou `p_file_type => apex_data_parser.c_file_type_csv` quando o nome não tiver extensão (ex.: conteúdo baixado de um web service).

Fonte: [PARSE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_PARSER.PARSE-Function.html)


## 10. APEX_DATA_LOADING: executar Data Load Definitions por PL/SQL

### APEX_DATA_LOADING: propósito, quando usar e quando não usar

`APEX_DATA_LOADING` executa, por código, uma *Data Load Definition* da aplicação (Shared Components > Data Load Definitions), no lugar do processo nativo *Data Loading*. A definição concentra tudo: destino (tabela ou APEX collection), método de carga, intervalo de commit, tratamento de erros e o *Data Profile* (como o arquivo é lido e mapeado em colunas). A API só tem duas operações: `LOAD_DATA` (carrega um BLOB ou CLOB e devolve quantas linhas foram processadas e quantas deram erro) e `GET_FILE_PROFILE` (devolve o profile da definição em JSON, para usar no `APEX_DATA_PARSER.PARSE` de pré-visualização).

Atributos da Data Load Definition que determinam o comportamento da API:

| Atributo | Valores / efeito |
|---|---|
| **Static ID** | Identificador usado em `p_static_id` |
| **Target Type** | Tabela ou APEX collection |
| **Loading Method** | *Append* (insere; se o profile tem PK, linhas existentes não mudam), *Merge* (exige PK no profile; atualiza se existe, insere se não; só para tabela), *Replace* (apaga o conteúdo do destino antes de carregar) |
| **Commit Interval** | Vazio = uma transação só, commit no final; com valor = commit a cada N linhas |
| **When on Error** | *Ignore* (ignora linhas com erro), *Stop* (para no primeiro erro e levanta exceção), *Log Error into Collection*, *Log into Error Log* (tabela de DML error logging; só tabela, *Append* e sem PK) |
| **Data Profile** | Formato, *Row Selector* (XML/JSON), colunas e mapeamentos |

- **Quando usar:** carga a partir de um processo PL/SQL próprio (validações antes/depois, vários arquivos, orquestração), carga em job/automation, ou carga de dados colados num Textarea (CLOB).
- **Quando não usar:** se a página só precisa de "upload e carregar", o processo nativo *Data Loading* faz o mesmo sem código. Para regras de importação que não cabem num Data Profile, use `APEX_DATA_PARSER.PARSE` e escreva o `INSERT`/`MERGE` você mesmo (seção 09).
- **Pré-requisito:** sessão APEX da aplicação que contém a definição. Os exemplos oficiais chamam `apex_session.create_session(100, 1, 'ADMIN')` quando o código roda fora da app (SQL Workshop, job).

Fonte: [APEX_DATA_LOADING](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_LOADING.html), [Creating Applications with Data Loading Capability](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-applications-with-data-loading-capability.html)

### APEX_DATA_LOADING: referência completa de functions e tipos

| Item | Tipo | O que faz |
|---|---|---|
| `GET_FILE_PROFILE` | function | Retorna o file profile (JSON, CLOB) da Data Load Definition |
| `LOAD_DATA` (Signature 1) | function | Carrega um **BLOB** (arquivo) pela definição; retorna `t_data_load_result` |
| `LOAD_DATA` (Signature 2) | function | Carrega um **CLOB** (texto) pela definição; retorna `t_data_load_result` |
| `t_data_load_result` | tipo (record) | `processed_rows PLS_INTEGER`, `error_rows PLS_INTEGER` |

```sql
type t_data_load_result is record(
    processed_rows    PLS_INTEGER,
    error_rows        PLS_INTEGER );
```

Nada está marcado como deprecated na doc 26.1.

Fonte: [Data Types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_LOADING-Data-Types.html)

### APEX_DATA_LOADING.LOAD_DATA: carregar arquivo (BLOB) ou texto (CLOB) por uma Data Load Definition

```sql
-- Signature 1: BLOB
APEX_DATA_LOADING.LOAD_DATA (
    p_application_id   IN NUMBER      DEFAULT apex_application.g_flow_id,
    p_static_id        IN VARCHAR2,
    p_data_to_load     IN BLOB,
    p_xlsx_sheet_name  IN VARCHAR2    DEFAULT NULL )
    RETURN t_data_load_result;

-- Signature 2: CLOB
APEX_DATA_LOADING.LOAD_DATA (
    p_application_id   IN NUMBER      DEFAULT apex_application.g_flow_id,
    p_static_id        IN VARCHAR2,
    p_data_to_load     IN CLOB,
    p_xlsx_sheet_name  IN VARCHAR2    DEFAULT NULL )
    RETURN t_data_load_result;
```

| Parâmetro | Descrição |
|---|---|
| `p_application_id` | Aplicação dona da Data Load Definition; default a app corrente |
| `p_static_id` | Static ID da definição |
| `p_data_to_load` | Conteúdo: BLOB (arquivo enviado) ou CLOB (texto colado) |
| `p_xlsx_sheet_name` | XLSX: planilha a extrair |

**Retorno:** `t_data_load_result` com `processed_rows` e `error_rows`. O que acontece com as linhas com erro depende de *When on Error* da definição (ignoradas, exceção, collection ou tabela de erro).

Arquivo enviado por File Upload (BLOB):

```sql
declare
    l_file        blob;
    l_load_result apex_data_loading.t_data_load_result;
begin
    select blob_content
      into l_file
      from apex_application_temp_files
     where name = :P40_ARQUIVO;

    l_load_result := apex_data_loading.load_data(
                         p_static_id       => 'carga-colaboradores',
                         p_data_to_load    => l_file,
                         p_xlsx_sheet_name => :P40_PLANILHA );

    :P40_RESULTADO :=
        l_load_result.processed_rows || ' linhas processadas, ' ||
        l_load_result.error_rows     || ' com erro.';
end;
```

Texto colado num Textarea (CLOB), executado fora da app (por isso a sessão):

```sql
declare
    l_load_result apex_data_loading.t_data_load_result;
begin
    apex_session.create_session( 100, 1, 'ADMIN' );
    l_load_result := apex_data_loading.load_data(
                         p_static_id    => 'my-load-definition',
                         p_data_to_load => :PX_DATA );
    dbms_output.put_line( 'Processed ' || l_load_result.processed_rows || ' rows.' );
end;
```

**Pegadinhas:**
- Com *Replace*, o destino é esvaziado antes da carga: não use em tabelas compartilhadas entre empresas/tenants sem isolar o destino (ex.: tabela de staging).
- *Merge* exige PK no Data Profile e só existe para tabelas; *Log into Error Log* só vale com *Append* sem PK.
- Sem *Commit Interval*, a carga inteira é uma transação só.
- Para cargas longas, a doc recomenda uma *execution chain* com *Run in Background*, *Temporary File Handling* = *Move* ou *Copy* e um processo filho *Data Loading*; o job vê uma cópia do session state e pode notificar o usuário (e-mail, push) ao final.

Fonte: [LOAD_DATA Function Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/LOAD_DATA-Function-Signature-1.html), [LOAD_DATA Function Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/LOAD_DATA-Function-Signature-2.html), [Creating Applications with Data Loading Capability](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-applications-with-data-loading-capability.html), [Loading Data in the Background](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/loading-data-background.html)

### APEX_DATA_LOADING.GET_FILE_PROFILE: obter o profile da Data Load Definition para pré-visualizar com APEX_DATA_PARSER

```sql
APEX_DATA_LOADING.GET_FILE_PROFILE (
    p_application_id    IN NUMBER   DEFAULT apex_application.g_flow_id,
    p_static_id         IN VARCHAR2 )
    RETURN CLOB;
```

| Parâmetro | Descrição |
|---|---|
| `p_application_id` | Aplicação dona da definição |
| `p_static_id` | Static ID da definição |

**Retorno:** o file profile em JSON, no formato aceito por `APEX_DATA_PARSER.PARSE.p_file_profile`. Assim o preview usa exatamente os mesmos tipos, delimitadores e planilha da carga real.

```sql
select p.line_number,
       p.col001, p.col002, p.col003, p.col004, p.col005,
       p.col006, p.col007, p.col008, p.col009, p.col010
  from apex_application_temp_files f,
       table( apex_data_parser.parse(
                  p_content      => f.blob_content,
                  p_file_name    => f.filename,
                  p_file_profile => apex_data_loading.get_file_profile(
                                        p_static_id => 'my-load-definition' ),
                  p_max_rows     => 100 ) ) p
 where f.name = :P1_FILE;
```

Fonte: [GET_FILE_PROFILE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_LOADING.GET_FILE_PROFILE-Function.html), [Previewing External Data Before Loading](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/previewing-external-data-loading.html)

### APEX_DATA_LOADING.LOAD_DATA para na primeira linha inválida e nada é carregado

**Sintoma:** a carga levanta erro logo na primeira linha com tipo inválido (ex.: texto numa coluna `NUMBER`) e o usuário não vê quais linhas falharam.
**Causa:** *When on Error* da Data Load Definition está em *Stop*.
**Correção:** mude para *Ignore* (só conta em `error_rows`), *Log Error into Collection* ou *Log into Error Log*. Para a última, crie a tabela de erro com `dbms_errlog.create_error_log( dml_table_name => 'EMP' )` (gera `ERR$_EMP`), selecione-a em *Error Logging Table* e use *Append* sem PK no profile.

Fonte: [Creating Applications with Data Loading Capability](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-applications-with-data-loading-capability.html)


## 11. APEX_DATA_INSTALL: carregar dados migrados nos Supporting Objects

### APEX_DATA_INSTALL: propósito, quando usar e quando não usar

`APEX_DATA_INSTALL` é a API de migração de dados do APEX. Tem uma única rotina, `LOAD_SUPPORTING_OBJECT_DATA`, que pega os dados que acompanham uma exportação de aplicação (guardados como static files da aplicação, numa *data migration export*) e os insere numa tabela, normalmente como parte da instalação dos *Supporting Objects*. Também pode ser chamada depois, do SQL Workshop, para reinstalar só os dados migrados sem reinstalar todos os supporting objects.

- **Quando usar:** num script de instalação dos Supporting Objects que precisa popular tabelas com dados exportados junto da app; ou para recarregar esses dados manualmente em outro ambiente.
- **Quando não usar:** para carga de arquivos de usuários (use `APEX_DATA_LOADING`/`APEX_DATA_PARSER`) ou para gerar dados de teste (use `APEX_DG_DATA_GEN`).

| Item | Tipo | O que faz |
|---|---|---|
| `LOAD_SUPPORTING_OBJECT_DATA` | procedure | Carrega os dados de supporting objects da aplicação na tabela indicada |

Fonte: [APEX_DATA_INSTALL](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_INSTALL.html), [Exporting an Application](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/exporting-an-application.html)

### APEX_DATA_INSTALL.LOAD_SUPPORTING_OBJECT_DATA: instalar os dados migrados numa tabela

```sql
APEX_DATA_INSTALL.LOAD_SUPPORTING_OBJECT_DATA (
    p_table_name            IN  VARCHAR2,
    p_delete_after_install  IN  BOOLEAN,
    p_app_id                IN  NUMBER  DEFAULT NULL );
```

| Parâmetro | Descrição |
|---|---|
| `p_table_name` | Tabela que recebe os dados |
| `p_delete_after_install` | Se os arquivos de dados são removidos depois da instalação dos supporting objects. A doc chama o default de `TRUE`, mas na assinatura o parâmetro não tem default: passe sempre explicitamente |
| `p_app_id` | ID da aplicação que contém os static files da exportação de dados. Permite rodar do SQL Workshop, fora da instalação dos supporting objects |

```sql
-- dentro do script de instalação dos Supporting Objects
begin
    apex_data_install.load_supporting_object_data(
        p_table_name           => 'DEPARTAMENTO',
        p_delete_after_install => true );
end;

-- reinstalar só os dados, pelo SQL Workshop, mantendo os arquivos
begin
    apex_data_install.load_supporting_object_data(
        p_table_name           => 'DEPARTAMENTO',
        p_delete_after_install => false,
        p_app_id               => 100 );
end;
```

**Pegadinhas:**
- Com `p_delete_after_install => TRUE` os arquivos de dados deixam de existir na app após a instalação, então uma reinstalação posterior só dos dados não será possível. Use `FALSE` se quiser poder recarregar.
- Fora da instalação dos supporting objects (ex.: SQL Workshop), informe `p_app_id`: a doc descreve esse parâmetro justamente para esse uso.
- O exemplo oficial passa uma variável `l_table_name` não inicializada; na prática informe o nome da tabela.

Fonte: [LOAD_SUPPORTING_OBJECT_DATA Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/LOAD_SUPPORTING_OBJECT_DATA-Procedure.html)


## 12. APEX_DG_DATA_GEN: gerar dados de exemplo a partir de blueprints

### APEX_DG_DATA_GEN: propósito, quando usar e quando não usar

`APEX_DG_DATA_GEN` é a API do **Data Generator** (SQL Workshop > Utilities > Data Generator). O conceito central é o **blueprint**: uma definição (exportável como JSON) com tabelas de destino, suas colunas e, para cada coluna, de onde vêm os valores. A API permite criar blueprints (do zero, de um arquivo JSON ou a partir de tabelas existentes no dicionário de dados), adicionar/alterar/remover tabelas, colunas e *data sources*, validar, pré-visualizar, exportar/importar o JSON e gerar os dados: como script `SQL INSERT`, `CSV` (um arquivo ou ZIP com vários), `JSON`, ou inserindo direto no schema (`INSERT INTO` / `FAST INSERT INTO`).

Tipos de fonte de valores de uma coluna (`p_data_source_type`):

| Tipo | `p_data_source` | Uso |
|---|---|---|
| `BUILTIN` | nome exato de um built-in, ex.: `car.make`, `animal.family` | Valores de catálogos embutidos (nomes, cidades etc.), no idioma do blueprint |
| `INLINE` | `VALOR,PESO;VALOR,PESO`, ex.: `PART_TIME,3;FULL_TIME,7` | Lista fixa com frequência aproximada |
| `SEQUENCE` | nulo; usa `p_sequence_start_with` / `p_sequence_increment` | Chaves sequenciais |
| `BLUEPRINT` | `TABELA.COLUNA` de uma tabela do blueprint com sequência menor | Chaves estrangeiras coerentes com dados já gerados |
| `DATA_SOURCE` | `NOME_DATA_SOURCE.COLUNA` | Valores vindos de uma tabela/consulta sua (`ADD_DATA_SOURCE`) |
| `FORMULA` | nulo; usa `p_formula` | Expressão PL/SQL com `{COLUNA}` de outras colunas da mesma linha |

- **Quando usar:** popular um ambiente de desenvolvimento/teste com volume realista; gerar massa para testar performance de relatórios; manter um blueprint versionado (JSON) que recria os dados de demo.
- **Quando não usar:** para dados reais ou de produção, para migrar dados entre ambientes (use exportação/`APEX_DATA_INSTALL`) ou para carregar arquivos (use `APEX_DATA_LOADING`/`APEX_DATA_PARSER`).
- **Pré-requisito:** as APIs exigem uma **sessão APEX**; fora do App Builder, crie uma com `APEX_SESSION`. `PREVIEW_BLUEPRINT` e `STOP_DATA_GENERATION` dependem explicitamente de sessão ativa (usam APEX collections).
- **Nomes e maiúsculas:** nomes de blueprint, tabelas, colunas e data sources são convertidos para maiúsculas, salvo `p_preserve_case => 'Y'`. Várias referências (`p_blueprint_table`, `BLUEPRINT` como fonte, `{COLUNA}` em fórmulas) são *case-sensitive*: com `preserve_case = 'N'`, use maiúsculas.

Fonte: [APEX_DG_DATA_GEN](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DG_DATA_GEN.html), [ADD_COLUMN Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DG_DATA_GEN.ADD_COLUMN-Procedure.html), [Using Data Generator](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/using-data-generator.html)

### APEX_DG_DATA_GEN: referência completa de procedures e functions

| Item | Tipo | O que faz |
|---|---|---|
| `ADD_BLUEPRINT` | procedure | Cria um blueprint vazio (nome + idioma únicos); devolve o ID |
| `ADD_BLUEPRINT_FROM_FILE` | procedure | Importa um blueprint JSON de um arquivo da aplicação ou do workspace |
| `ADD_BLUEPRINT_FROM_TABLES` | procedure | Cria um blueprint com tabelas existentes, deduzindo colunas do dicionário de dados |
| `ADD_COLUMN` | procedure | Adiciona uma coluna a uma tabela do blueprint, com sua fonte de valores |
| `ADD_DATA_SOURCE` | procedure | Registra uma tabela ou consulta sua como fonte de valores |
| `ADD_TABLE` | procedure | Adiciona uma tabela de destino ao blueprint (nova ou existente) |
| `EXPORT_BLUEPRINT` | function | Exporta o blueprint em JSON (CLOB) |
| `GENERATE_DATA` (Signature 1) | procedure | Gera os dados; saída em **BLOB** (ou insere no schema) |
| `GENERATE_DATA` (Signature 2) | procedure | Igual, com saída em **CLOB** |
| `GENERATE_DATA_INTO_COLLECTION` | procedure | Gera e guarda o resultado na collection `APEX$DG$[BLUEPRINT_NAME]` |
| `GET_BLUEPRINT_ID` | function | ID do blueprint pelo nome |
| `GET_BP_TABLE_ID` | function | ID de uma tabela do blueprint (busca exata, depois em maiúsculas) |
| `GET_EXAMPLE` | function | Exemplos de valores de um built-in (`wwv_flow_t_varchar2`) |
| `GET_WEIGHTED_INLINE_DATA` | function | Expande uma lista inline ponderada em linhas |
| `IMPORT_BLUEPRINT` | procedure | Importa um blueprint a partir de um CLOB JSON |
| `PREVIEW_BLUEPRINT` | procedure | Gera até 50 linhas de prévia em APEX collections |
| `REMOVE_BLUEPRINT` | procedure | Remove o blueprint (metadados) |
| `REMOVE_COLUMN` | procedure | Remove uma coluna de uma tabela do blueprint |
| `REMOVE_DATA_SOURCE` | procedure | Remove um data source do blueprint |
| `REMOVE_TABLE` | procedure | Remove uma tabela do blueprint |
| `RESEQUENCE_BLUEPRINT` | procedure | Renumera tabelas e colunas com intervalos fixos, mantendo a ordem |
| `STOP_DATA_GENERATION` | procedure | Interrompe a geração em andamento (sessão APEX) |
| `UPDATE_BLUEPRINT` | procedure | Altera nome, display name, descrição, idioma, schema padrão |
| `UPDATE_COLUMN` | procedure | Altera uma coluna (inclusive renomear) |
| `UPDATE_DATA_SOURCE` | procedure | Altera um data source (inclusive renomear) |
| `UPDATE_TABLE` | procedure | Altera uma tabela do blueprint (inclusive renomear, linhas) |
| `VALIDATE_BLUEPRINT` | procedure | Valida o SQL que seria gerado para um formato |
| `VALIDATE_INSTANCE_SETTING` | procedure | Valida configurações de instância (tabela, coluna, nível de geração) num JSON |

Constantes citadas nas assinaturas (sem valor publicado na doc): `c_empty_t_varchar2`, `c_json_date_format` (default de `p_format_mask`), `c_max_error_count` (default de `p_stop_after_errors`), `c_default_seq_offset` (default de `p_offset`). Nada está marcado como deprecated.

Fonte: [APEX_DG_DATA_GEN](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DG_DATA_GEN.html)

### APEX_DG_DATA_GEN: criar blueprint (ADD_BLUEPRINT, ADD_BLUEPRINT_FROM_TABLES, ADD_BLUEPRINT_FROM_FILE)

```sql
APEX_DG_DATA_GEN.ADD_BLUEPRINT (
    p_name                  IN VARCHAR2,
    p_display_name          IN VARCHAR2 DEFAULT NULL,
    p_description           IN VARCHAR2 DEFAULT NULL,
    p_lang                  IN VARCHAR2 DEFAULT 'en',
    p_default_schema        IN VARCHAR2 DEFAULT NULL,
    p_blueprint_id          OUT NUMBER )

APEX_DG_DATA_GEN.ADD_BLUEPRINT_FROM_TABLES (
    p_name              IN VARCHAR2,
    p_tables            IN wwv_flow_t_varchar2,
    p_preserve_case     IN VARCHAR2 DEFAULT 'N',
    p_exclude_columns   IN wwv_flow_t_varchar2 DEFAULT c_empty_t_varchar2,
    p_description       IN VARCHAR2 DEFAULT NULL,
    p_lang              IN VARCHAR2 DEFAULT 'en',
    p_default_schema    IN VARCHAR2 DEFAULT NULL,
    p_blueprint_id      OUT NUMBER );

APEX_DG_DATA_GEN.ADD_BLUEPRINT_FROM_FILE (
    p_filename          IN VARCHAR2,
    p_application_id    IN NUMBER   DEFAULT NULL,
    p_override_name     IN VARCHAR2 DEFAULT NULL,
    p_replace           IN BOOLEAN  DEFAULT FALSE,
    p_blueprint_id      OUT NUMBER );
```

| Parâmetro | Descrição |
|---|---|
| `p_name` | Identificador; nome + idioma são únicos. Vai para maiúsculas e perde caracteres especiais |
| `p_display_name` / `p_description` | Nome amigável / descrição |
| `p_lang` | Idioma dos built-ins; se o built-in não tiver registros no idioma, usa `en` |
| `p_default_schema` | Schema padrão do blueprint |
| `p_tables` | `apex_t_varchar2('TABELA:LINHAS', ...)`, ex.: `apex_t_varchar2('PRODUCTS:10','CUSTOMERS:50','SALES:1000')`. **Ordem: tabelas mestre antes das filhas** (FKs) |
| `p_exclude_columns` | Colunas a ignorar na geração automática (vale para todas as tabelas de `p_tables`) |
| `p_filename` | Nome do arquivo em `apex_application_files.filename` |
| `p_application_id` | App dona do arquivo, ou nulo para arquivo do workspace |
| `p_override_name` | Substitui o nome que está no JSON |
| `p_replace` | `FALSE` = erro se o blueprint já existe; `TRUE` = substitui |
| `p_blueprint_id` | OUT: ID do blueprint |

`ADD_BLUEPRINT_FROM_TABLES` lê cada tabela do schema corrente com colunas, tipos e atributos do dicionário de dados e aplica as mesmas regras automáticas de `ADD_TABLE ... p_use_existing_table => 'Y'` (FKs, `CHECK ... IN`, mapeamento por nome/tipo/tamanho, 5% de nulos em colunas anuláveis).

```sql
declare
    l_bp_id number;
begin
    apex_dg_data_gen.add_blueprint_from_tables(
        p_name            => 'Corlix Demo',
        p_tables          => apex_t_varchar2('DEPARTAMENTO:6', 'CARGO:15', 'COLABORADOR:200'),
        p_exclude_columns => apex_t_varchar2('CRIADO_POR', 'CRIADO_EM'),
        p_lang            => 'en',
        p_blueprint_id    => l_bp_id );
end;
```

Fonte: [ADD_BLUEPRINT Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_BLUEPRINT-Procedure.html), [ADD_BLUEPRINT_FROM_TABLES Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_BLUEPRINT_FROM_TABLES-Procedure.html), [ADD_BLUEPRINT_FROM_FILE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_BLUEPRINT_FROM_FILE-Procedure.html)

### APEX_DG_DATA_GEN.ADD_TABLE: adicionar tabela de destino (nova ou existente) ao blueprint

```sql
APEX_DG_DATA_GEN.ADD_TABLE (
    p_blueprint             IN VARCHAR2,
    p_sequence              IN PLS_INTEGER,
    p_table_name            IN VARCHAR2,
    p_preserve_case         IN VARCHAR2             DEFAULT 'N',
    p_display_name          IN VARCHAR2             DEFAULT NULL,
    p_singular_name         IN VARCHAR2             DEFAULT NULL,
    p_plural_name           IN VARCHAR2             DEFAULT NULL,
    p_rows                  IN NUMBER               DEFAULT 0,
    p_max_rows              IN NUMBER               DEFAULT NULL,
    p_use_existing_table    IN VARCHAR2             DEFAULT 'N',
    p_exclude_columns       IN wwv_flow_t_varchar2  DEFAULT c_empty_t_varchar2,
    p_table_id              OUT NUMBER )
```

| Parâmetro | Descrição |
|---|---|
| `p_blueprint` | Blueprint |
| `p_sequence` | Ordem de geração (1 = primeira). Tabelas mestre com sequência menor |
| `p_table_name` | Nome da tabela (pode existir ou não) |
| `p_preserve_case` | `N` (default) = maiúsculas |
| `p_display_name` / `p_singular_name` / `p_plural_name` | Nomes amigáveis |
| `p_rows` | Linhas a gerar |
| `p_max_rows` | Nulo = exatamente `p_rows`; senão um número aleatório entre `p_rows` e `p_max_rows` |
| `p_use_existing_table` | `Y` = cria as colunas automaticamente pelo dicionário de dados |
| `p_exclude_columns` | Colunas a ignorar na criação automática |
| `p_table_id` | OUT: ID da tabela no blueprint |

**Regras automáticas com `p_use_existing_table => 'Y'`:** FKs recebem chaves da tabela mestre; `CHECK` com `IN` simples vira dado inline; mapeamento para built-ins pelo nome de tabela/coluna; mapeamento por nome, tipo e tamanho da coluna; colunas anuláveis recebem 5% de `NULL`.

```sql
declare
    l_table_id number;
begin
    apex_dg_data_gen.add_table(
        p_blueprint          => 'Cars',
        p_sequence           => 1,
        p_table_name         => 'my_cars',
        p_rows               => 50,
        p_use_existing_table => 'Y',
        p_exclude_columns    => apex_t_varchar2('CREATED_BY','CREATED_DATE'),
        p_table_id           => l_table_id );
end;
```

Fonte: [ADD_TABLE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_TABLE-Procedure.html)

### APEX_DG_DATA_GEN.ADD_COLUMN e UPDATE_COLUMN: definir a fonte de valores de cada coluna

```sql
APEX_DG_DATA_GEN.ADD_COLUMN (
    p_blueprint             IN VARCHAR2,
    p_sequence              IN PLS_INTEGER,
    p_table_name            IN VARCHAR2,
    p_column_name           IN VARCHAR2,
    p_preserve_case         IN VARCHAR2 DEFAULT 'N',
    p_display_name          IN VARCHAR2 DEFAULT NULL,
    p_max_length            IN NUMBER   DEFAULT 4000,
    p_multi_value           IN VARCHAR2 DEFAULT 'N',
    p_mv_format             IN VARCHAR2 DEFAULT 'JSON',
    p_mv_unique             IN VARCHAR2 DEFAULT 'Y',
    p_mv_delimiter          IN VARCHAR2 DEFAULT ':',
    p_mv_min_entries        IN INTEGER  DEFAULT 1,
    p_mv_max_entries        IN INTEGER  DEFAULT 2,
    p_mv_partition_by       IN VARCHAR2 DEFAULT NULL,
    p_lang                  IN VARCHAR2 DEFAULT 'en',
    p_data_source_type      IN VARCHAR2,
    p_data_source           IN VARCHAR2 DEFAULT NULL,
    p_ds_preserve_case      IN VARCHAR2 DEFAULT 'N',
    p_min_numeric_value     IN NUMBER   DEFAULT 1,
    p_max_numeric_value     IN NUMBER   DEFAULT 10,
    p_numeric_precision     IN NUMBER   DEFAULT 0,
    p_min_date_value        IN DATE     DEFAULT NULL,
    p_max_date_value        IN DATE     DEFAULT NULL,
    p_format_mask           IN VARCHAR2 DEFAULT c_json_date_format,
    p_sequence_start_with   IN NUMBER   DEFAULT 1,
    p_sequence_increment    IN NUMBER   DEFAULT 1,
    p_formula               IN VARCHAR2 DEFAULT NULL,
    p_formula_lang          IN VARCHAR2 DEFAULT 'PLSQL',
    p_custom_attributes     IN VARCHAR2 DEFAULT NULL,
    p_percent_blank         IN NUMBER   DEFAULT 0,
    p_column_id             OUT NUMBER )
```

`UPDATE_COLUMN` tem os mesmos parâmetros (sem `p_column_id`) mais `p_new_column_name IN VARCHAR2 DEFAULT NULL` para renomear; `p_sequence` e `p_data_source_type` continuam obrigatórios.

| Parâmetro | Descrição |
|---|---|
| `p_sequence` | Ordem da coluna (1, 2, …) |
| `p_table_name` | Tabela no blueprint (busca exata, depois em maiúsculas) |
| `p_max_length` | Corta textos gerados (ex.: latim) nesse tamanho |
| `p_multi_value` | `Y`/`N`; só para `BUILTIN` (valores distintos) e `INLINE` (distintos se cada valor tem peso 1) |
| `p_mv_format` | `DELIMITED` (usa `p_mv_delimiter`) ou `JSON` |
| `p_mv_unique` | `Y` = sem repetição dentro da lista |
| `p_mv_min_entries` / `p_mv_max_entries` | Quantidade de valores na lista (1 a 2 por padrão) |
| `p_mv_partition_by` | Coluna do mesmo built-in para coerência (ex.: `make` quando a fonte é `car.model`) |
| `p_data_source_type` | `BLUEPRINT`, `BUILTIN`, `DATA_SOURCE`, `FORMULA`, `INLINE`, `SEQUENCE` |
| `p_data_source` | Conforme o tipo (ver tabela da seção de propósito); nulo para `FORMULA` e `SEQUENCE` |
| `p_ds_preserve_case` | Para `DATA_SOURCE`/`BLUEPRINT`: `N` põe `tabela.coluna` em maiúsculas |
| `p_min_numeric_value` / `p_max_numeric_value` | Faixa inclusiva para built-ins numéricos (default 1–10) |
| `p_numeric_precision` | `0` = inteiro; `-1` = arredonda para dezena; N > 0 = casas decimais |
| `p_min_date_value` / `p_max_date_value` | Faixa inclusiva para built-ins de data |
| `p_format_mask` | Máscara para datas |
| `p_sequence_start_with` / `p_sequence_increment` | Para `SEQUENCE` |
| `p_formula` | Expressão PL/SQL com `{COLUNA}` (case-sensitive), ex.: `{FIRST_NAME}\|\|'.'\|\|{LAST_NAME}\|\|'@example.com'`. Aplicada **por último**, depois de `p_percent_blank`; vale para qualquer tipo de fonte |
| `p_formula_lang` | Default `'PLSQL'`; aceita funções de texto, data e numéricas |
| `p_custom_attributes` | Reservado para uso futuro |
| `p_percent_blank` | 0–100: porcentagem de nulos, aplicada antes das fórmulas |

```sql
declare
    l_col_id number;
begin
    -- built-in
    apex_dg_data_gen.add_column(
        p_blueprint => 'Cars', p_sequence => 1, p_table_name => 'MY_CARS',
        p_column_name => 'make', p_data_source_type => 'BUILTIN',
        p_data_source => 'car.make', p_column_id => l_col_id );

    -- lista ponderada
    apex_dg_data_gen.add_column(
        p_blueprint => 'Cars', p_sequence => 2, p_table_name => 'MY_CARS',
        p_column_name => 'regime', p_data_source_type => 'INLINE',
        p_data_source => 'PART_TIME,3;FULL_TIME,7', p_column_id => l_col_id );

    -- FK para tabela gerada antes (sequência menor)
    apex_dg_data_gen.add_column(
        p_blueprint => 'Cars', p_sequence => 3, p_table_name => 'MY_CARS',
        p_column_name => 'deptno', p_data_source_type => 'BLUEPRINT',
        p_data_source => 'DEPT.DEPTNO', p_column_id => l_col_id );

    -- fórmula
    apex_dg_data_gen.add_column(
        p_blueprint => 'Cars', p_sequence => 4, p_table_name => 'MY_CARS',
        p_column_name => 'descricao', p_data_source_type => 'FORMULA',
        p_formula => q'[{MAKE}||' - '||{REGIME}]', p_column_id => l_col_id );
end;
```

**Pegadinhas:** como a fórmula roda depois do `p_percent_blank`, uma coluna com 100% em branco mas fórmula `sysdate` sai preenchida. Na fonte `INLINE`, os pesos são aproximados; a doc recomenda os menores números que deem a distribuição desejada.

Fonte: [ADD_COLUMN Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DG_DATA_GEN.ADD_COLUMN-Procedure.html), [UPDATE_COLUMN Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/UPDATE_COLUMN-Procedure.html)

### APEX_DG_DATA_GEN.ADD_DATA_SOURCE e UPDATE_DATA_SOURCE: usar tabelas ou consultas próprias como fonte

```sql
APEX_DG_DATA_GEN.ADD_DATA_SOURCE (
    p_blueprint             IN VARCHAR2,
    p_name                  IN VARCHAR2,
    p_data_source_type      IN VARCHAR2,
    p_table                 IN VARCHAR2 DEFAULT NULL,
    p_preserve_case         IN VARCHAR2 DEFAULT 'N',
    p_sql_query             IN VARCHAR2 DEFAULT NULL,
    p_where_clause          IN VARCHAR2 DEFAULT NULL,
    p_inline_data           IN CLOB     DEFAULT NULL,
    p_order_by_column       IN VARCHAR2 DEFAULT NULL,
    p_data_source_id        OUT NUMBER )

APEX_DG_DATA_GEN.UPDATE_DATA_SOURCE (
    p_blueprint             IN VARCHAR2,
    p_name                  IN VARCHAR2,
    p_new_name              IN VARCHAR2 DEFAULT NULL,
    p_data_source_type      IN VARCHAR2,
    p_table                 IN VARCHAR2 DEFAULT NULL,
    p_preserve_case         IN VARCHAR2 DEFAULT 'N',
    p_sql_query             IN VARCHAR2 DEFAULT NULL,
    p_where_clause          IN VARCHAR2 DEFAULT NULL,
    p_inline_data           IN CLOB     DEFAULT NULL,
    p_order_by_column       IN VARCHAR2 DEFAULT NULL )
```

| Parâmetro | Descrição |
|---|---|
| `p_name` / `p_new_name` | Nome do data source (maiúsculas, **até 26 caracteres**) |
| `p_data_source_type` | `TABLE` ou `SQL_QUERY` (o parâmetro `p_inline_data` é descrito para `JSON_DATA`) |
| `p_table` | Para `TABLE`; normalmente igual a `p_name` |
| `p_sql_query` | Para `SQL_QUERY` |
| `p_where_clause` | Para `TABLE`, sem a palavra `where` (ex.: `deptno <= 20`) |
| `p_order_by_column` | Não usado |
| `p_data_source_id` | OUT: ID do data source |

As colunas referenciam o data source com `p_data_source_type => 'DATA_SOURCE'` e `p_data_source => 'NOME_DS.COLUNA'`.

```sql
declare
    l_ds_id number;
begin
    apex_dg_data_gen.add_data_source(
        p_blueprint        => 'Cars',
        p_name             => 'apex_dg_builtin_cars',
        p_data_source_type => 'TABLE',
        p_table            => 'apex_dg_builtin_cars',
        p_data_source_id   => l_ds_id );
end;
```

Fonte: [ADD_DATA_SOURCE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_DATA_SOURCE-Procedure.html), [UPDATE_DATA_SOURCE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/UPDATE_DATA_SOURCE-Procedure.html)

### APEX_DG_DATA_GEN.GENERATE_DATA: gerar SQL, CSV, JSON ou inserir direto nas tabelas

```sql
-- Signature 1: saída em BLOB
APEX_DG_DATA_GEN.GENERATE_DATA (
    p_blueprint             IN          VARCHAR2,
    p_format                IN          VARCHAR2,
    p_blueprint_table       IN          VARCHAR2 DEFAULT NULL,
    p_row_scaling           IN          NUMBER DEFAULT 100,
    p_stop_after_errors     IN          NUMBER DEFAULT c_max_error_count,
    p_output                OUT NOCOPY  BLOB,
    p_file_ext              OUT NOCOPY  VARCHAR2,
    p_mime_type             OUT NOCOPY  VARCHAR2,
    p_errors                OUT NOCOPY  CLOB )

-- Signature 2: saída em CLOB
APEX_DG_DATA_GEN.GENERATE_DATA (
    p_blueprint             IN         VARCHAR2,
    p_format                IN         VARCHAR2,
    p_blueprint_table       IN         VARCHAR2 DEFAULT NULL,
    p_row_scaling           IN         NUMBER DEFAULT 100,
    p_stop_after_errors     IN         NUMBER DEFAULT c_max_error_count,
    p_output                OUT NOCOPY CLOB,
    p_file_ext              OUT NOCOPY VARCHAR2,
    p_mime_type             OUT NOCOPY VARCHAR2,
    p_errors                OUT NOCOPY CLOB )
```

| Parâmetro | Descrição |
|---|---|
| `p_blueprint` | Nome do blueprint |
| `p_format` | `SQL INSERT` (script), `CSV` (um CSV para uma tabela, ZIP de CSVs para várias), `JSON`, `INSERT INTO` (gera os INSERTs e executa no schema corrente), `FAST INSERT INTO` (gera numa tabela temporária e faz um único `INSERT ... SELECT`) |
| `p_blueprint_table` | Nulo = todas; senão só essa tabela (**case-sensitive**) |
| `p_row_scaling` | Porcentagem aplicada às quantidades de linhas do blueprint (100 = como definido) |
| `p_stop_after_errors` | Quantos erros tolerar antes de parar; só para `INSERT INTO` |
| `p_output` | Conteúdo gerado (BLOB ou CLOB); nulo em `INSERT INTO`/`FAST INSERT INTO` |
| `p_file_ext` / `p_mime_type` | Extensão e MIME type do arquivo; nulos nos modos de inserção |
| `p_errors` | JSON com erros; `NULL` em caso de sucesso |

```sql
declare
    l_output    blob;
    l_file_ext  varchar2(255);
    l_mime_type varchar2(255);
    l_errors    clob;
begin
    -- inserir direto nas tabelas do schema
    apex_dg_data_gen.generate_data(
        p_blueprint         => 'Cars',
        p_format            => 'FAST INSERT INTO',
        p_output            => l_output,
        p_file_ext          => l_file_ext,
        p_mime_type         => l_mime_type,
        p_errors            => l_errors );
    if l_errors is not null then
        raise_application_error(-20001, 'Data Generator: ' || dbms_lob.substr(l_errors, 3000, 1));
    end if;
end;
```

**Pegadinhas:** os exemplos oficiais de `GENERATE_DATA`, `GENERATE_DATA_INTO_COLLECTION`, `PREVIEW_BLUEPRINT`, `STOP_DATA_GENERATION` e `VALIDATE_BLUEPRINT` chamam `apex_dg_output.*`, omitem `p_format` (obrigatório) e têm vírgulas faltando/sobrando; use `apex_dg_data_gen.*` conforme as assinaturas. Os modos `INSERT INTO`/`FAST INSERT INTO` gravam no schema corrente: rode só em ambiente de desenvolvimento/teste.

Fonte: [GENERATE_DATA Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GENERATE_DATA-Procedure-Signature-1.html), [GENERATE_DATA Procedure Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GENERATE_DATA-Procedure-Signature-2.html)

### APEX_DG_DATA_GEN.GENERATE_DATA_INTO_COLLECTION, PREVIEW_BLUEPRINT e STOP_DATA_GENERATION: geração com APEX collections

```sql
APEX_DG_DATA_GEN.GENERATE_DATA_INTO_COLLECTION (
    p_blueprint            IN         VARCHAR2,
    p_format               IN         VARCHAR2,
    p_blueprint_table      IN         VARCHAR2 DEFAULT NULL,
    p_row_scaling          IN         NUMBER DEFAULT 100,
    p_stop_after_errors    IN         NUMBER DEFAULT c_max_error_count,
    p_errors               OUT NOCOPY CLOB )

APEX_DG_DATA_GEN.STOP_DATA_GENERATION (
    p_blueprint         IN VARCHAR2 )
```

`GENERATE_DATA_INTO_COLLECTION` aceita os mesmos formatos de `GENERATE_DATA` e grava na collection `APEX$DG$[BLUEPRINT_NAME]`: `CLOB001`/`BLOB001` com a saída, `C006` com a extensão, `C007` com o MIME type (nulos nos modos de inserção); uma linha com `C001 = 'ERROR'` traz o JSON de erros em `CLOB001`.

`STOP_DATA_GENERATION` interrompe a geração em andamento e só funciona numa sessão APEX: a mesma collection `APEX$DG$[BLUEPRINT_NAME]` registra o progresso (`d001` timestamp do passo, `c001` blueprint, `c002` formato, `c003` tabela em geração, `c004`/`c005` nome e descrição do passo, `n001` ID do passo) e reage à instrução de parada.

`PREVIEW_BLUEPRINT` gera dados de prévia em collections e exige sessão ativa. A assinatura publicada está quebrada (`parameter_1 IN NUMBER, parameter_2 IN VARCHAR2, parameter_3 IN NUMBER`); a tabela de parâmetros da doc lista `p_blueprint`, `p_table_name` (nulo = todas), `p_number_of_rows` (**máximo 50**), `p_data_collection` e `p_header_collection`:

```sql
begin
    apex_dg_data_gen.preview_blueprint(
        p_blueprint         => 'Cars',
        p_table_name        => 'MY_CARS',
        p_data_collection   => 'CARS_DATA',
        p_header_collection => 'CARS_HEADERS' );
end;
-- select * from apex_collections where collection_name = 'CARS_DATA';
```

Fonte: [GENERATE_DATA_INTO_COLLECTION Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GENERATE_DATA_INTO_COLLECTION-Procedure.html), [PREVIEW_BLUEPRINT Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PREVIEW_BLUEPRINT-Procedure.html), [STOP_DATA_GENERATION Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/STOP_DATA_GENERATION-Procedure.html)

### APEX_DG_DATA_GEN: exportar, importar, validar e manter blueprints (EXPORT_BLUEPRINT, IMPORT_BLUEPRINT, VALIDATE_BLUEPRINT, UPDATE/REMOVE, RESEQUENCE)

```sql
APEX_DG_DATA_GEN.EXPORT_BLUEPRINT (
    p_name                  IN VARCHAR2,
    p_pretty                IN VARCHAR2 DEFAULT 'Y' )
RETURN CLOB;

APEX_DG_DATA_GEN.IMPORT_BLUEPRINT (
    p_clob              IN CLOB,
    p_override_name     IN VARCHAR2 DEFAULT NULL,
    p_replace           IN BOOLEAN  DEFAULT FALSE,
    p_blueprint_id      OUT NUMBER )

APEX_DG_DATA_GEN.VALIDATE_BLUEPRINT (
    p_blueprint          IN     VARCHAR2,
    p_format             IN     VARCHAR2,
    p_errors             OUT    CLOB )

APEX_DG_DATA_GEN.UPDATE_BLUEPRINT (
    p_name                  IN VARCHAR2,
    p_new_name              IN VARCHAR2 DEFAULT NULL,
    p_display_name          IN VARCHAR2 DEFAULT NULL,
    p_description           IN VARCHAR2 DEFAULT NULL,
    p_lang                  IN VARCHAR2 DEFAULT 'en',
    p_default_schema        IN VARCHAR2 DEFAULT NULL )

APEX_DG_DATA_GEN.UPDATE_TABLE (
    p_blueprint         IN VARCHAR2,
    p_table_name        IN VARCHAR2,
    p_new_table_name    IN VARCHAR2     DEFAULT NULL,
    p_sequence          IN PLS_INTEGER,
    p_preserve_case     IN VARCHAR2     DEFAULT 'N',
    p_display_name      IN VARCHAR2     DEFAULT NULL,
    p_singular_name     IN VARCHAR2     DEFAULT NULL,
    p_plural_name       IN VARCHAR2     DEFAULT NULL,
    p_rows              IN NUMBER       DEFAULT 0,
    p_max_rows          IN VARCHAR2     DEFAULT NULL )

APEX_DG_DATA_GEN.REMOVE_BLUEPRINT   ( p_name IN VARCHAR2 )
APEX_DG_DATA_GEN.REMOVE_TABLE       ( p_blueprint IN VARCHAR2, p_table_name IN VARCHAR2 )
APEX_DG_DATA_GEN.REMOVE_COLUMN      ( p_blueprint IN VARCHAR2, p_table_name IN VARCHAR2, p_column_name IN VARCHAR2 )
APEX_DG_DATA_GEN.REMOVE_DATA_SOURCE ( p_blueprint IN VARCHAR2, p_name IN VARCHAR2 )

APEX_DG_DATA_GEN.RESEQUENCE_BLUEPRINT (
    p_blueprint IN VARCHAR2,
    p_offset    IN NUMBER   DEFAULT c_default_seq_offset )
```

- `EXPORT_BLUEPRINT`: JSON do blueprint; `p_pretty = 'Y'` formata. Combine com `IMPORT_BLUEPRINT` para copiar/versionar (`p_replace => TRUE` sobrescreve; `FALSE` dá erro se já existe).
- `VALIDATE_BLUEPRINT`: verifica o SQL que seria gerado para um formato: `CSV`, `SQL INSERT`, `JSON`, `PRETTY JSON`, `INSERT INTO` ou `FAST INSERT INTO`; erros em `p_errors`.
- `UPDATE_BLUEPRINT`: `p_new_name` renomeia (vai para maiúsculas, sem caracteres especiais).
- `UPDATE_TABLE`: chave lógica = `p_blueprint` + `p_table_name`; `p_sequence` é obrigatório; `p_new_table_name` renomeia (com `p_preserve_case` aplicado ao novo nome).
- `REMOVE_*`: removem metadados (blueprint, tabela, coluna, data source), não dados gerados.
- `RESEQUENCE_BLUEPRINT`: renumera tabelas e colunas com intervalos de `p_offset` (10, 100, 1000…), mantendo a ordem — útil antes de inserir itens no meio.

```sql
declare
    l_json  clob;
    l_id    number;
    l_err   clob;
begin
    l_json := apex_dg_data_gen.export_blueprint( p_name => 'Cars' );
    apex_dg_data_gen.import_blueprint( p_clob => l_json, p_override_name => 'Cars Copy',
                                       p_replace => true, p_blueprint_id => l_id );
    apex_dg_data_gen.validate_blueprint( p_blueprint => 'CARS COPY', p_format => 'JSON', p_errors => l_err );
end;
```

**Pegadinha:** o segundo exemplo oficial de `UPDATE_TABLE` usa `p_use_existing_table`, que não existe na assinatura de `UPDATE_TABLE` (só em `ADD_TABLE`).

Fonte: [EXPORT_BLUEPRINT Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/EXPORT_BLUEPRINT-Function.html), [IMPORT_BLUEPRINT Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/IMPORT_BLUEPRINT-Procedure.html), [VALIDATE_BLUEPRINT Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/VALIDATE_BLUEPRINT-Procedure.html), [UPDATE_BLUEPRINT Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/UPDATE_BLUEPRINT-Procedure.html), [UPDATE_TABLE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/UPDATE_TABLE-Procedure.html), [REMOVE_BLUEPRINT Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/REMOVE_BLUEPRINT-Procedure.html), [REMOVE_TABLE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/REMOVE_TABLE-Procedure.html), [REMOVE_COLUMN Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/REMOVE_COLUMN-Procedure.html), [REMOVE_DATA_SOURCE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/REMOVE_DATA_SOURCE-Procedure.html), [RESEQUENCE_BLUEPRINT Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/RESEQUENCE_BLUEPRINT-Procedure.html)

### APEX_DG_DATA_GEN: funções utilitárias (GET_BLUEPRINT_ID, GET_BP_TABLE_ID, GET_EXAMPLE, GET_WEIGHTED_INLINE_DATA, VALIDATE_INSTANCE_SETTING)

```sql
APEX_DG_DATA_GEN.GET_BLUEPRINT_ID ( p_name IN VARCHAR2 ) RETURN NUMBER;

APEX_DG_DATA_GEN.GET_BP_TABLE_ID (
    p_bp_id         IN NUMBER,
    p_table_name    IN VARCHAR2 )
    RETURN NUMBER;

APEX_DG_DATA_GEN.GET_EXAMPLE (
    p_friendly_name     IN  VARCHAR2,
    p_lang              IN  VARCHAR2 DEFAULT 'en',
    p_rows              IN  NUMBER DEFAULT 5 )
    RETURN wwv_flow_t_varchar2;

APEX_DG_DATA_GEN.GET_WEIGHTED_INLINE_DATA (
    p_data  IN VARCHAR2 )
    RETURN wwv_flow_t_varchar2

APEX_DG_DATA_GEN.VALIDATE_INSTANCE_SETTING (
    p_json      IN          CLOB,
    p_valid     OUT NOCOPY  VARCHAR2,
    p_message   OUT NOCOPY  CLOB )
```

- `GET_BLUEPRINT_ID`: ID pelo nome (tipo `apex_dg_blueprints.id%TYPE` no exemplo).
- `GET_BP_TABLE_ID`: ID da tabela no blueprint; tenta o nome exato e, se não achar, em maiúsculas.
- `GET_EXAMPLE`: amostra de valores de um built-in, para escolher a fonte certa: `select * from apex_dg_data_gen.get_example( p_friendly_name => 'animal.family' );`
- `GET_WEIGHTED_INLINE_DATA`: expande `VALOR,PESO;...` (ex.: `F,45;M,30`) em linhas: `select * from apex_dg_data_gen.get_weighted_inline_data( p_data => 'F;M' );`
- `VALIDATE_INSTANCE_SETTING`: valida um JSON de configurações de instância (tabela, coluna, nível de geração); `p_valid` indica validade e `p_message` detalha (a tabela de parâmetros da doc chama esse OUT de `p_result`).

Fonte: [GET_BLUEPRINT_ID Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_BLUEPRINT_ID-Function.html), [GET_BP_TABLE_ID Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_BP_TABLE_ID-Function.html), [GET_EXAMPLE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_EXAMPLE-Function.html), [GET_WEIGHTED_INLINE_DATA Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_WEIGHTED_INLINE_DATA-Function.html), [VALIDATE_INSTANCE_SETTING Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/VALIDATE_INSTANCE_SETTING-Procedure.html)

### APEX_DG_DATA_GEN rejeita p_percent_blank = 100

**Sintoma:** chamada de `ADD_COLUMN`/`UPDATE_COLUMN` com `p_percent_blank => 100` falha, embora a doc aceite 0–100.
**Causa:** problema conhecido da API do Data Generator listado nas Release Notes 26.1.
**Correção:** use no máximo 99, ou gere a coluna como `FORMULA` que devolve `NULL`.

Fonte: [Known Issues for Data Generator](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/open-bugs-known-issues.html)

### APEX_DG_DATA_GEN ignora mínimo, máximo e precisão em alguns built-ins numéricos

**Sintoma:** os valores gerados ficam fora de `p_min_numeric_value`/`p_max_numeric_value` ou com casas decimais diferentes de `p_numeric_precision`.
**Causa:** problema conhecido: alguns built-ins que retornam `NUMBER` ignoram esses parâmetros.
**Correção:** use uma `FORMULA` (ex.: `round(dbms_random.value(1, 100), 2)`) ou `INLINE` para controlar a faixa.

Fonte: [Known Issues for Data Generator](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/open-bugs-known-issues.html)

### APEX_DG_DATA_GEN gera uma linha a mais com p_row_scaling diferente de 100

**Sintoma:** com escala diferente de 1x, a quantidade gerada passa em uma linha do esperado.
**Causa:** problema conhecido do Data Generator.
**Correção:** não dependa da contagem exata ao usar `p_row_scaling`; ajuste `p_rows` na tabela quando a contagem precisar ser exata.

Fonte: [Known Issues for Data Generator](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/open-bugs-known-issues.html)

### PREVIEW_BLUEPRINT do APEX_DG_DATA_GEN omite colunas totalmente nulas

**Sintoma:** a prévia não mostra uma coluna do blueprint.
**Causa:** problema conhecido: o preview ignora colunas em que todos os valores saíram nulos (ex.: `p_percent_blank` alto e poucas linhas).
**Correção:** reduza `p_percent_blank` temporariamente ou confira a coluna gerando de fato (`GENERATE_DATA` em `JSON`).

Fonte: [Known Issues for Data Generator](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/open-bugs-known-issues.html)

### APEX_DG_DATA_GEN não acha a tabela ou a coluna referenciada (diferença de maiúsculas)

**Sintoma:** `p_blueprint_table`, fonte `BLUEPRINT` (`dept.deptno`) ou `{first_name}` numa fórmula não resolvem.
**Causa:** com `p_preserve_case = 'N'` (default) os nomes são gravados em maiúsculas, e essas referências são *case-sensitive*.
**Correção:** use maiúsculas (`DEPT.DEPTNO`, `{FIRST_NAME}`, `p_blueprint_table => 'MY_CARS'`) ou crie tudo com `p_preserve_case => 'Y'` de forma consistente. Fontes `BLUEPRINT` só podem apontar para tabelas com `p_sequence` menor.

Fonte: [ADD_COLUMN Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DG_DATA_GEN.ADD_COLUMN-Procedure.html), [GENERATE_DATA Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GENERATE_DATA-Procedure-Signature-1.html)


## 13. APEX_MAIL: enviar e-mails (texto, HTML, templates, anexos) pela fila do APEX

### APEX_MAIL: propósito, quando usar e quando não usar

`APEX_MAIL` é a API PL/SQL para enviar e-mails a partir de uma aplicação APEX. Ela é construída sobre o package `UTL_SMTP` do banco, que precisa estar instalado e funcionando. As três rotinas centrais são:

- `APEX_MAIL.SEND`: monta a mensagem (texto puro, HTML ou a partir de um *Email Template* de Shared Components) e a grava na fila do APEX.
- `APEX_MAIL.ADD_ATTACHMENT`: anexa arquivos (BLOB ou CLOB) a uma mensagem já criada, inclusive imagens *inline* referenciadas por `cid:`.
- `APEX_MAIL.PUSH_QUEUE`: força a entrega imediata das mensagens que estão na fila (`APEX_MAIL_QUEUE`).

**Como funciona a entrega:** `SEND` não fala com o servidor SMTP na hora; ele coloca a mensagem na fila. O APEX instala o job de banco `ORACLE_APEX_MAIL_QUEUE`, que roda **a cada 5 minutos** e envia o que estiver na fila. Mensagens enviadas com sucesso vão para `APEX_MAIL_LOG`. Se você precisa que o e-mail saia agora (ex.: teste, fluxo de "esqueci a senha"), chame `APEX_MAIL.PUSH_QUEUE` depois do `SEND`.

**Pré-requisitos (resumo; detalhes nas seções de configuração abaixo):**

1. O administrador da instância configura o e-mail em *Administration Services > Manage Instance > Instance Settings > Email* (host/porta SMTP, autenticação, SSL/TLS, *Default Email From Address*, limites) ou via `APEX_INSTANCE_ADMIN.SET_PARAMETER`.
2. O DBA libera rede para o schema do APEX (`APEX_260100`) com `DBMS_NETWORK_ACL_ADMIN` (não se aplica ao Autonomous Database).
3. Para SMTP com SSL/TLS, é preciso um wallet com o certificado do servidor (a partir do Oracle AI Database 26ai a configuração de wallet pode ficar vazia).
4. Opcional: o workspace pode usar credenciais SMTP próprias (Web Credential), se a instância permitir.

**Uso fora de uma aplicação (SQLcl, job do Scheduler):** funciona desde que o usuário de banco esteja mapeado para um workspace APEX. Se estiver mapeado para vários, defina antes o workspace com `APEX_UTIL.SET_WORKSPACE` ou `APEX_UTIL.SET_SECURITY_GROUP_ID`. Usuários de banco sem nenhum workspace só conseguem usar `APEX_MAIL` se tiverem o role `APEX_ADMINISTRATOR_ROLE`. Ao usar a assinatura com template fora do contexto de uma app, passe `p_application_id` explicitamente.

```sql
-- Opção 1: pelo nome do workspace
apex_util.set_workspace(p_workspace => 'MY_WORKSPACE');

-- Opção 2: pelo ID do workspace dono da aplicação 100
for c1 in (select workspace_id
             from apex_applications
            where application_id = 100) loop
    apex_util.set_security_group_id(p_security_group_id => c1.workspace_id);
end loop;
```

**Quando usar:** e-mails disparados por lógica de negócio em PL/SQL (processos *Execute Code*, packages, automations, jobs), envio com anexos montados dinamicamente, envio em lote a partir de cursores, e quando o conteúdo vem de um *Email Template* com placeholders.

**Quando não usar (prefira o declarativo):** para um envio simples disparado por botão, use o processo nativo **Send E-Mail** (página, workflow, task definition, automation), que já aceita template, placeholders e *Attachment SQL*. Para notificar o usuário no dispositivo, use *Send Push Notification*. `APEX_MAIL` também não é a ferramenta para validar endereços nem para receber e-mails.

**Pegadinhas gerais:**

- Nenhuma linha do corpo pode passar de **1000 caracteres** (regra SMTP/MIME); quebre com `utl_tcp.crlf`.
- `p_body` e `p_body_html` precisam ser do **mesmo tipo** (ambos `VARCHAR2` ou ambos `CLOB`).
- Se a instância tiver um *Default Email From Address*, ele **sempre** vence o `p_from` que você passar.
- Há limite diário por workspace (`WORKSPACE_EMAIL_MAXIMUM`, padrão 1000 em 24 h) e limite de tamanho por anexo (`EMAIL_ATTACHMENT_MAX_SIZE_MB`).
- Os exemplos oficiais com `ADD_ATTACHMENT` terminam com `COMMIT`.

Fonte: [APEX_MAIL](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_MAIL.html), [Sending Email from an Application](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/sending-email-from-an-application.html), [DBMS_SCHEDULER Jobs](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/dbms_scheduler-jobs.html)

### APEX_MAIL: referência completa de procedures, functions e objetos relacionados

| Item | Tipo | O que faz |
|---|---|---|
| `SEND` (Function Signature 1) | function | Envia e-mail com `p_body`/`p_body_html` (texto/HTML) e devolve o ID (`NUMBER`) da mensagem na fila |
| `SEND` (Function Signature 2) | function | Envia e-mail baseado em *Email Template* (`p_template_static_id` + `p_placeholders` JSON) e devolve o ID; aceita `p_language_override` |
| `SEND` (Procedure Signature 1) | procedure | Igual à Function Signature 1, sem devolver o ID |
| `SEND` (Procedure Signature 2) | procedure | Igual à Function Signature 2, sem devolver o ID (sem `p_language_override` na doc) |
| `ADD_ATTACHMENT` (Signature 1) | procedure | Anexa um `BLOB`; com `p_content_id` não nulo, o anexo vira *inline* (referência `cid:` no HTML) |
| `ADD_ATTACHMENT` (Signature 2) | procedure | Anexa um `CLOB` (conteúdo texto, ex.: CSV) |
| `GET_IMAGES_URL` | function | Devolve a URL do diretório de imagens da instância (para `<img src>` no e-mail) |
| `GET_INSTANCE_URL` | function | Devolve a URL da instância (para links absolutos no e-mail); exige *Oracle APEX Instance URL* configurado |
| `PREPARE_TEMPLATE` | procedure | Processa um *Email Template* com placeholders e devolve assunto, HTML e texto, **sem enviar** |
| `PUSH_QUEUE` | procedure | Entrega imediatamente as mensagens da fila `APEX_MAIL_QUEUE` ao SMTP |
| `APEX_INSTANCE_ADMIN.VALIDATE_EMAIL_CONFIG` | procedure (outro package) | Testa a conexão com o servidor SMTP configurado; levanta erro se falhar |
| `APEX_MAIL_QUEUE` | view de dicionário | Mensagens aguardando envio (com o último erro encontrado) |
| `APEX_MAIL_LOG` | view de dicionário | Mensagens enviadas (timestamp na hora local do servidor) e erro final das que desistiram |
| `ORACLE_APEX_MAIL_QUEUE` | job do DBMS_SCHEDULER | Envia a fila a cada 5 minutos |

O package não define constantes nem tipos públicos na doc 26.1.

Fonte: [APEX_MAIL](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_MAIL.html), [VALIDATE_EMAIL_CONFIG Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/VALIDATE_EMAIL_CONFIG-Procedure.html), [Sending Emails with Templates](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/sending-emails-templates.html)

### APEX_MAIL.SEND (Signature 1, function e procedure): e-mail em texto puro ou HTML

Monta e enfileira um e-mail cujo conteúdo é passado diretamente. A versão **function** devolve o ID numérico único da mensagem (necessário para `ADD_ATTACHMENT`); a versão **procedure** tem os mesmos parâmetros e não devolve nada.

```sql
-- Function Signature 1
APEX_MAIL.SEND (
    p_to                IN    VARCHAR2,
    p_from              IN    VARCHAR2,
    p_body              IN  [ VARCHAR2 | CLOB ],
    p_body_html         IN  [ VARCHAR2 | CLOB ] DEFAULT NULL,
    p_subj              IN    VARCHAR2 DEFAULT NULL,
    p_cc                IN    VARCHAR2 DEFAULT NULL,
    p_bcc               IN    VARCHAR2 DEFAULT NULL,
    p_replyto           IN    VARCHAR2 DEFAULT NULL )
RETURN NUMBER;

-- Procedure Signature 1
APEX_MAIL.SEND (
    p_to                IN    VARCHAR2,
    p_from              IN    VARCHAR2,
    p_body              IN  [ VARCHAR2 | CLOB ],
    p_body_html         IN  [ VARCHAR2 | CLOB ] DEFAULT NULL,
    p_subj              IN    VARCHAR2 DEFAULT NULL,
    p_cc                IN    VARCHAR2 DEFAULT NULL,
    p_bcc               IN    VARCHAR2 DEFAULT NULL,
    p_replyto           IN    VARCHAR2 DEFAULT NULL );
```

| Parâmetro | Descrição |
|---|---|
| `p_to` | **Obrigatório.** Destinatário(s); vários endereços separados por vírgula |
| `p_from` | **Obrigatório.** Remetente; precisa ser um endereço válido, senão a mensagem não é enviada. Se a instância tiver *Default Email From Address*, ele é sempre usado no lugar |
| `p_body` | **Obrigatório.** Corpo em texto puro (não HTML). Se `p_body_html` também for passado, o texto só aparece em clientes sem HTML ou com HTML desligado. Inclua CRLF a cada 1000 caracteres |
| `p_body_html` | Corpo em HTML; deve ser um documento completo com `<html>` e `<body>`. Nenhuma linha acima de 1000 caracteres sem CRLF |
| `p_subj` | Assunto |
| `p_cc` | Cópia; lista separada por vírgula |
| `p_bcc` | Cópia oculta; lista separada por vírgula |
| `p_replyto` | Endereço para onde o cliente de e-mail deve mandar respostas humanas, em vez de `p_from` |

**Retorno (function):** `NUMBER`, o identificador único da mensagem na fila.

**Comportamento:**

- Só `p_body` → mensagem texto puro. `p_body` + `p_body_html` → mensagem *multipart* com as duas versões; o cliente do destinatário escolhe qual mostrar.
- `p_body` e `p_body_html` aceitam `VARCHAR2` ou `CLOB`, mas os dois têm de ser do mesmo tipo na mesma chamada.
- A mensagem vai para a fila; a entrega ocorre no próximo ciclo do job `ORACLE_APEX_MAIL_QUEUE` ou num `PUSH_QUEUE`.

**Exemplo 1: texto puro, guardando o ID**

```sql
declare
    l_body clob;
    l_id   number;
begin
    l_body := 'Obrigado pelo interesse no Corlix Hub.' || utl_tcp.crlf || utl_tcp.crlf;
    l_body := l_body || '  Atenciosamente,' || utl_tcp.crlf;
    l_body := l_body || '  Equipe Corlix' || utl_tcp.crlf;

    l_id := apex_mail.send(
        p_to   => 'destinatario@example.com',
        p_from => 'remetente@example.com',
        p_body => l_body,
        p_subj => 'Mensagem em texto puro');
end;
/
```

**Exemplo 2: texto + HTML (multipart), com CC, BCC e Reply-To**

```sql
declare
    l_body      clob;
    l_body_html clob;
begin
    l_body := 'Para ver esta mensagem, use um cliente de e-mail com suporte a HTML.' || utl_tcp.crlf;

    l_body_html := '<html><head><style type="text/css">'
                || 'body{font-family:Arial,Helvetica,sans-serif;font-size:10pt;}'
                || '</style></head><body>' || utl_tcp.crlf;
    l_body_html := l_body_html || '<p>Obrigado pelo interesse no <strong>Corlix Hub</strong>.</p>' || utl_tcp.crlf;
    l_body_html := l_body_html || '<p>Atenciosamente,<br />Equipe Corlix</p>' || utl_tcp.crlf;
    l_body_html := l_body_html || '</body></html>';

    apex_mail.send(
        p_to        => 'destinatario@example.com',
        p_from      => 'remetente@example.com',
        p_cc        => 'gestor@example.com',
        p_bcc       => 'auditoria@example.com',
        p_replyto   => 'rh@example.com',
        p_body      => l_body,
        p_body_html => l_body_html,
        p_subj      => 'Mensagem em HTML');
end;
/
```

**Pegadinhas:**

- Linha com mais de 1000 caracteres gera mensagem errada: corpo cortado ou pontos de exclamação estranhos no texto. Concatene `utl_tcp.crlf` com frequência, principalmente em HTML gerado por loop.
- Imagens referenciadas por URL (`<img src="http://...">`) não são anexadas: o destinatário precisa alcançar a URL. Imagem atrás de firewall não aparece. A alternativa é a imagem *inline* com `ADD_ATTACHMENT(p_content_id => ...)`, que aumenta o tamanho do e-mail e nem todo cliente exibe automaticamente. A doc recomenda evitar imagens e sempre colocar `alt`.
- Muitos usuários desligam HTML por segurança: mande sempre um `p_body` útil.

Fonte: [SEND Function Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SEND-Function-Signature-1.html), [SEND Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SEND-Procedure-Signature-1.html)

### APEX_MAIL.SEND (Signature 2, function e procedure): e-mail a partir de Email Template com placeholders JSON

Enfileira um e-mail cujo assunto e corpos (HTML e texto) vêm de um **Email Template** de Shared Components, identificado pelo *Static Identifier*. Os valores dos placeholders `#NOME#` do template vão num JSON. A versão function devolve o ID da mensagem (para anexar arquivos depois).

```sql
-- Function Signature 2
APEX_MAIL.SEND (
    p_template_static_id    IN VARCHAR2,
    p_placeholders          IN CLOB,
    p_to                    IN VARCHAR2,
    p_cc                    IN VARCHAR2 DEFAULT NULL,
    p_bcc                   IN VARCHAR2 DEFAULT NULL,
    p_from                  IN VARCHAR2 DEFAULT NULL,
    p_replyto               IN VARCHAR2 DEFAULT NULL,
    p_application_id        IN NUMBER   DEFAULT apex_application.g_flow_id,
    p_language_override     IN VARCHAR2 DEFAULT NULL )
    RETURN NUMBER;

-- Procedure Signature 2
APEX_MAIL.SEND (
    p_template_static_id IN VARCHAR2,
    p_placeholders       IN CLOB,
    p_to                 IN VARCHAR2,
    p_cc                 IN VARCHAR2 DEFAULT NULL,
    p_bcc                IN VARCHAR2 DEFAULT NULL,
    p_from               IN VARCHAR2 DEFAULT NULL,
    p_replyto            IN VARCHAR2 DEFAULT NULL,
    p_application_id     IN NUMBER   DEFAULT apex_application.g_flow_id );
```

(Na página oficial da function, a sintaxe traz um `;` sobrando antes de `RETURN NUMBER`; é erro tipográfico da doc.)

| Parâmetro | Descrição |
|---|---|
| `p_template_static_id` | *Static Identifier* do Email Template (Shared Components) |
| `p_placeholders` | JSON com pares nome/valor dos placeholders a substituir |
| `p_to` | **Obrigatório.** Destinatário(s), separados por vírgula |
| `p_cc` / `p_bcc` | Cópia / cópia oculta, separados por vírgula |
| `p_from` | Remetente. Se omitido: usa o *Application Email From Address* da Application Definition; senão `p_replyto` (se informado); senão `p_to`. Se `p_to` ou `p_replyto` tiverem vários endereços, `p_from` passa a ser obrigatório. O *Default Email From Address* da instância, se existir, sempre vence |
| `p_replyto` | Omitido → o cabeçalho Reply-To recebe `p_from`. Passado explicitamente como `NULL` → Reply-To fica nulo, o que suprime respostas automáticas. Passado com endereço → respostas vão para ele |
| `p_application_id` | Aplicação onde o template está definido. Padrão: a aplicação corrente. **Obrigatório fora do contexto de uma app** (ex.: job do Scheduler) |
| `p_language_override` | (só na function) Código de idioma de um template traduzido (`en`, `fr`, `de-at`…). Precisa existir tradução da aplicação nesse idioma; senão é ignorado |

**Retorno (function):** `NUMBER`, ID da mensagem na fila, utilizável em `ADD_ATTACHMENT`.

**Comportamento dos placeholders:** os valores substituídos são **escapados conforme o contexto**: no formato HTML recebem escape de HTML; no texto puro, não. Para inserir HTML de propósito, use os modificadores no template: `#NOME!RAW#` (substitui como veio) ou `#NOME!STRIPHTML#` (remove as tags). Os campos do template também aceitam *Template Directives* como `{if NOME/}…{endif/}`.

**Exemplo 1: procedure com JSON literal e envio imediato**

```sql
begin
    apex_mail.send (
        p_to                 => 'steven.king@example.com',
        p_template_static_id => 'ORDER_CONFIRMATION',
        p_placeholders       => q'~
        {
            "CUSTOMER_NAME": "Steven King",
            "ORDER_NUMBER": 1234,
            "ORDER_DATE": "02-Feb-2018",
            "ORDER_TOTAL": "$ 1,200.99"
        }~' );
    apex_mail.push_queue;
end;
```

**Exemplo 2: montar o JSON com `APEX_STRING.PLIST_TO_JSON_CLOB` (recomendado; evita JSON inválido e cuida do escape)**

```sql
apex_mail.send(
   p_to                 => :EMPLOYEE_EMAIL,
   p_template_static_id => 'EMPLOYEE_SALARY_LOTTERY_WINNER',
   p_placeholders       => apex_string.plist_to_json_clob(apex_t_varchar2(
                              'EMPLOYEE_NAME' , :ENAME,
                              'NEW_SALARY'    , :NEW_SALARY,
                              'NEW_COMMISSION', :NEW_COMMISSION)));
```

Na lista `apex_t_varchar2`, as posições ímpares são os nomes das propriedades JSON e as pares, os valores. Sem `p_from`, o remetente sai do `APP_EMAIL` (*Application Email From Address*).

**Exemplo 3: function + anexo, chamada de um job (fora da app)**

```sql
declare
    l_mail_id number;
begin
    apex_util.set_workspace(p_workspace => 'WKSP_CORLIXHUB');
    l_mail_id := apex_mail.send (
        p_template_static_id => 'ORDER',
        p_placeholders       => '{ "ORDER_NUMBER": 5321, "ORDER_DATE": "01-Feb-2018", "ORDER_TOTAL": "$12,000" }',
        p_to                 => 'some_user@example.com',
        p_application_id     => 100 );          -- obrigatório fora do contexto da app

    apex_mail.add_attachment (
        p_mail_id    => l_mail_id,
        p_attachment => to_clob('col1,col2' || utl_tcp.crlf || '1,2'),
        p_filename   => 'dados.csv',
        p_mime_type  => 'text/csv' );
    commit;
end;
```

A página do template, em *Sample API Usage*, mostra a mesma ideia com `apex_json.stringify( valor )` para cada placeholder ao montar o JSON por concatenação.

Fonte: [SEND Function Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SEND-Function-Signature-2.html), [SEND Procedure Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SEND-Procedure-Signature-2.html), [Managing Email Templates](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-email-templates.html), [Sending Emails from Business Logic](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/sending-emails-business-logic.html)

### APEX_MAIL.ADD_ATTACHMENT: anexar BLOB, CLOB ou imagem inline (p_content_id) a um e-mail

Anexa um arquivo a uma mensagem criada por `APEX_MAIL.SEND` (versão function, que devolve o `p_mail_id`). Pode ser chamada várias vezes para o mesmo e-mail.

```sql
-- Signature 1: conteúdo binário (BLOB), com anexo inline opcional
APEX_MAIL.ADD_ATTACHMENT (
    p_mail_id           IN NUMBER,
    p_attachment        IN BLOB,
    p_filename          IN VARCHAR2,
    p_mime_type         IN VARCHAR2,
    p_content_id        IN VARCHAR2    DEFAULT NULL );

-- Signature 2: conteúdo texto (CLOB)
APEX_MAIL.ADD_ATTACHMENT (
    p_mail_id                   IN    NUMBER,
    p_attachment                IN    CLOB,
    p_filename                  IN    VARCHAR2,
    p_mime_type                 IN    VARCHAR2 );
```

(A sintaxe oficial da Signature 1 omite a vírgula depois de `p_mime_type`; use a forma acima.)

| Parâmetro | Descrição |
|---|---|
| `p_mail_id` | ID devolvido por `APEX_MAIL.SEND` |
| `p_attachment` | Conteúdo: `BLOB` (Signature 1, binário) ou `CLOB` (Signature 2, texto) |
| `p_filename` | Nome do arquivo anexado |
| `p_mime_type` | MIME type válido (ex.: `application/pdf`, `text/csv`, `image/png`) |
| `p_content_id` | (Só BLOB) Identificador opcional. Se não nulo, o arquivo é anexado **inline** e pode ser referenciado no HTML como `cid:<p_content_id>`. Nem todo cliente exibe imagens inline automaticamente |

`p_content_id` só existe na assinatura BLOB, então imagem inline precisa vir em `BLOB`.

**Exemplo 1: anexar vários arquivos de uma tabela/view (BLOB)**

```sql
declare
    l_id number;
begin
    l_id := apex_mail.send(
        p_to        => 'fred@example.com',
        p_from      => 'barney@example.com',
        p_subj      => 'Documentos anexos',
        p_body      => 'Veja os anexos.',
        p_body_html => '<html><body><b>Veja</b> os anexos.</body></html>');

    for c1 in (select filename, blob_content, mime_type
                 from apex_application_files
                where id in (123, 456)) loop
        apex_mail.add_attachment(
            p_mail_id    => l_id,
            p_attachment => c1.blob_content,
            p_filename   => c1.filename,
            p_mime_type  => c1.mime_type);
    end loop;
    commit;
end;
/
```

**Exemplo 2: anexo CLOB (CSV gerado em memória)**

```sql
declare
    l_id   number;
    l_clob clob := 'Value1,Value2,Value3,42';
begin
    l_id := apex_mail.send(
        p_to        => 'fred@example.com',
        p_from      => 'barney@example.com',
        p_subj      => 'Exportação CSV',
        p_body      => 'Segue o CSV.',
        p_body_html => '<html><body>Segue o <b>CSV</b>.</body></html>');

    apex_mail.add_attachment(
        p_mail_id    => l_id,
        p_attachment => l_clob,
        p_filename   => 'data.csv',
        p_mime_type  => 'text/csv');
    commit;
end;
/
```

**Exemplo 3: imagem inline referenciada por `cid:`**

```sql
declare
    l_id         number;
    l_body       clob;
    l_body_html  clob;
    l_content_id varchar2(100) := 'logo-empresa';
    l_filename   varchar2(100);
    l_mime_type  varchar2(100);
    l_image      blob;
begin
    l_body := 'Para ver esta mensagem, use um cliente com suporte a HTML.' || utl_tcp.crlf;

    l_body_html := '<html><body>' || utl_tcp.crlf ||
                   '<p>Segue a imagem solicitada.</p>' || utl_tcp.crlf ||
                   '<p><img src="cid:' || l_content_id || '" alt="Logo da empresa"></p>' || utl_tcp.crlf ||
                   '</body></html>';

    l_id := apex_mail.send(
        p_to        => 'some_user@example.com',
        p_from      => 'some_sender@example.com',
        p_body      => l_body,
        p_body_html => l_body_html,
        p_subj      => 'Imagem inline');

    select filename, mime_type, blob_content
      into l_filename, l_mime_type, l_image
      from apex_application_files
     where id = 123;

    apex_mail.add_attachment(
        p_mail_id    => l_id,
        p_attachment => l_image,
        p_filename   => l_filename,
        p_mime_type  => l_mime_type,
        p_content_id => l_content_id);
    commit;
end;
```

**Equivalente declarativo (processo Send E-Mail, *Attachment SQL*):** a consulta deve devolver quatro colunas, nesta ordem: BLOB do conteúdo, nome do arquivo, MIME type e *Content Id* (`null` para anexo normal; um valor distinto e não nulo por linha para cada imagem inline referenciada por `cid:` no *Body HTML*). Exemplo oficial, anexando um ZIP guardado numa collection:

```sql
select blob001                      as contents,
       'woods_newhire_notices.zip'  as file_name,
       'application/zip'            as mime_type,
       null /* Normal Attachment */ as content_id
  from apex_collections
 where collection_name = 'NOTICES_ZIP'
 fetch first row only
```

**Pegadinhas:** o tamanho de cada anexo é limitado pelo parâmetro de instância `EMAIL_ATTACHMENT_MAX_SIZE_MB` (vale para `APEX_MAIL` e para o processo Send E-Mail). Imagens inline aumentam muito o tamanho da mensagem.

Fonte: [ADD_ATTACHMENT Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_ATTACHMENT-Procedure-Signature-1.html), [ADD_ATTACHMENT Procedure Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_ATTACHMENT-Procedure-Signature-2.html), [Emailing User with Attachments](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/emailing-user-attachments.html), [Choosing Descriptive Process Names](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/choosing-descriptive-process-names.html), [Available Parameter Values](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_INSTANCE_ADMIN.Available-Parameter-Values.html)

### APEX_MAIL.PUSH_QUEUE: forçar o envio imediato da fila APEX_MAIL_QUEUE

Entrega na hora, ao gateway SMTP, as mensagens que estão na fila (`APEX_MAIL_QUEUE`), sem esperar o job `ORACLE_APEX_MAIL_QUEUE` (que roda a cada 5 minutos). Mensagens entregues são registradas em `APEX_MAIL_LOG`, com timestamp na hora local do servidor.

```sql
APEX_MAIL.PUSH_QUEUE (
    p_smtp_hostname     IN VARCHAR2 DEFAULT NULL,
    p_smtp_portno       IN NUMBER   DEFAULT NULL );
```

| Parâmetro | Descrição |
|---|---|
| `p_smtp_hostname` | Host do gateway SMTP. **Ignorado**: existe só por compatibilidade |
| `p_smtp_portno` | Porta do gateway SMTP. **Ignorado**: existe só por compatibilidade |

Host e porta vêm exclusivamente das *Instance Settings* (Administration Services) ou de `APEX_INSTANCE_ADMIN` (`SMTP_HOST_ADDRESS`, `SMTP_HOST_PORT`).

```sql
begin
    apex_mail.send(p_to => 'a@example.com', p_from => 'b@example.com',
                   p_body => 'Teste', p_subj => 'Teste imediato');
    apex_mail.push_queue;
end;
```

Exemplo oficial em shell (UNIX/Linux):

```sql
sql / <<EOF
APEX_MAIL.PUSH_QUEUE;
DISCONNECT
EXIT
EOF
```

**Quando usar:** testes, e-mails sensíveis a tempo (código de verificação, redefinição de senha), scripts. **Quando não usar:** em envios em massa dentro de loops; deixe o job processar a fila, que respeita `MAX_MAIL_QUEUE_ROWS` por workspace.

Fonte: [PUSH_QUEUE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PUSH_QUEUE-Procedure.html), [DBMS_SCHEDULER Jobs](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/dbms_scheduler-jobs.html)

### APEX_MAIL.PREPARE_TEMPLATE: processar um Email Template sem enviar (assunto, HTML e texto)

Aplica os placeholders JSON a um Email Template e devolve o resultado em parâmetros `OUT`, **sem enfileirar nada**. Útil para pré-visualizar o e-mail numa página, gravar o conteúdo num histórico ou enviar por outro canal.

```sql
APEX_MAIL.PREPARE_TEMPLATE (
    p_static_id         IN  VARCHAR2,
    p_placeholders      IN  CLOB,
    p_application_id    IN  NUMBER   DEFAULT apex_application.g_flow_id,
    p_subject           OUT VARCHAR2,
    p_html              OUT CLOB,
    p_text              OUT CLOB,
    p_language_override IN  VARCHAR2 DEFAULT NULL );
```

| Parâmetro | Descrição |
|---|---|
| `p_static_id` | *Static Identifier* do template |
| `p_placeholders` | JSON com nome/valor dos placeholders |
| `p_application_id` | Aplicação do template; padrão: a corrente |
| `p_subject` (OUT) | Assunto já com substituições |
| `p_html` (OUT) | HTML final do e-mail |
| `p_text` (OUT) | Texto puro final |
| `p_language_override` | Idioma de um template traduzido (`en`, `fr`, `de-at`…); ignorado se não houver tradução da aplicação |

```sql
declare
    l_subject varchar2(4000);
    l_html    clob;
    l_text    clob;
begin
    apex_mail.prepare_template (
        p_static_id    => 'ORDER',
        p_placeholders => '{ "ORDER_NUMBER": 5321, "ORDER_DATE": "01-Feb-2018", "ORDER_TOTAL": "$12,000" }',
        p_subject      => l_subject,
        p_html         => l_html,
        p_text         => l_text );
end;
```

Fonte: [PREPARE_TEMPLATE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PREPARE_TEMPLATE_Procedure.html)

### APEX_MAIL.GET_INSTANCE_URL e GET_IMAGES_URL: links absolutos e imagens da instância no e-mail

E-mails são lidos fora do navegador da sessão APEX, então links e imagens precisam de URL absoluta. Essas funções devolvem as URLs configuradas na seção Email das *Instance Settings*.

```sql
APEX_MAIL.GET_INSTANCE_URL return VARCHAR2;
APEX_MAIL.GET_IMAGES_URL   return VARCHAR2;
```

| Função | Devolve | Configuração necessária |
|---|---|---|
| `GET_INSTANCE_URL` | URL da instância, com barra final (ex.: `https://www.example.com/apex/`) | *Email, Oracle APEX Instance URL* (parâmetro `EMAIL_INSTANCE_URL`) **precisa** estar preenchido |
| `GET_IMAGES_URL` | URL do diretório de imagens da instância, com barra final (ex.: `https://www.example.com/i/`) | *Email, Oracle APEX Images URL* (parâmetro `EMAIL_IMAGES_URL`) |

Nenhuma das duas tem parâmetros.

```sql
declare
    l_body      clob;
    l_body_html clob;
begin
    l_body := 'Para ver esta mensagem, use um cliente com suporte a HTML.' || utl_tcp.crlf;
    l_body_html := '<html><body>' || utl_tcp.crlf ||
                   '<p>Confirme seu pedido na <a href="' ||
                   apex_mail.get_instance_url || 'f?p=100:10">página de confirmação</a>.</p>' || utl_tcp.crlf ||
                   '<p><img src="' || apex_mail.get_images_url || 'oracle.gif" alt="Logo"></p>' || utl_tcp.crlf ||
                   '</body></html>';
    apex_mail.send(
        p_to        => 'some_user@example.com',
        p_from      => 'some_sender@example.com',
        p_body      => l_body,
        p_body_html => l_body_html,
        p_subj      => 'Confirmação de pedido');
end;
```

**Pegadinha:** o exemplo oficial concatena `f?p=100:10` à URL da instância. Um link desses abre sem sessão; no fluxo "Navigating to Page Using Email Link" do Developer's Companion, o usuário faz login e só chega à página de destino porque a app tem *Deep Linking* habilitado.

Fonte: [GET_INSTANCE_URL Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_INSTANCE_URL-Function.html), [GET_IMAGES_URL Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_IMAGES_URL-Function.html), [Navigating to Page Using Email Link](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/navigating-page-using-email-link.html)

### APEX_MAIL: fila APEX_MAIL_QUEUE, log APEX_MAIL_LOG e política de reenvio

- **Fila:** `SEND` grava em `APEX_MAIL_QUEUE`. O job `ORACLE_APEX_MAIL_QUEUE` processa a fila a cada 5 minutos, até `MAX_MAIL_QUEUE_ROWS` mensagens por workspace por execução (*Maximum Emails Processed per Workspace*).
- **Reenvio automático:** se o envio falha (endereço inválido, servidor fora do ar), a mensagem fica na fila com o último erro. O APEX tenta de novo **até 14 vezes**, com intervalo crescendo exponencialmente (2, 4, 8, 16 minutos…). Esgotadas as tentativas, a mensagem sai da fila e o último erro fica em `APEX_MAIL_LOG`.
- **Erros permanentes:** o parâmetro `SMTP_RETRY_PERMANENT_ERROR_PATTERNS` (lista de regex separada por quebra de linha) define quais "erros permanentes" do SMTP devem ser tratados como temporários (reenviar no próximo ciclo). Erro tratado como permanente remove a mensagem da fila na hora. O padrão `.*` trata todos como temporários.
- **Log:** `APEX_MAIL_LOG` registra mensagens enviadas (timestamp na hora local do servidor). Na UI: *Administration Services > Monitor Activity > Logs > Mail Log*.
- **Administração da fila (UI):** *Administration Services > Manage Instance > Manage Meta Data > Mail Queue*. Botões: **Delete** (apaga as selecionadas), **Send All Mail** (envia respeitando o atraso calculado das que deram erro) e **Force Send All Mail** (ignora o atraso e tenta todas).

```sql
-- Diagnóstico rápido (views de dicionário citadas pela doc)
select * from apex_mail_queue;   -- pendentes, com último erro
select * from apex_mail_log;     -- enviadas / desistidas
```

(A doc não lista as colunas dessas views nas páginas lidas; consulte com `describe`.)

Fonte: [Managing Meta Data](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/managing-meta-data.html), [PUSH_QUEUE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PUSH_QUEUE-Procedure.html), [Available Parameter Values](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_INSTANCE_ADMIN.Available-Parameter-Values.html), [Monitoring Activity Across an Instance](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/monitoring-activity-across-an-instance.html)

### APEX_MAIL: configurar o e-mail da instância (Instance Settings > Email, ambiente de desenvolvimento completo)

Antes de qualquer envio, o administrador da instância precisa configurar o e-mail e o DBA precisa liberar a rede. Num *full development environment*: *Administration Services > Manage Instance > Instance Settings*, seção **Email**:

| Atributo (UI) | Parâmetro `APEX_INSTANCE_ADMIN` | Significado / padrão |
|---|---|---|
| *Oracle APEX Instance URL* | `EMAIL_INSTANCE_URL` | URL da instância com barra final (`https://www.example.com/apex/`); usada em e-mails do sistema e por `GET_INSTANCE_URL` |
| *Oracle APEX Images URL* | `EMAIL_IMAGES_URL` | URL do diretório de imagens com barra final (`https://www.example.com/i/`) |
| *SMTP Host Address* | `SMTP_HOST_ADDRESS` | Servidor SMTP; padrão `localhost`. Troque se usar relay |
| *SMTP Host Port* | `SMTP_HOST_PORT` | Porta; padrão `25` |
| *SMTP Authentication Username* | `SMTP_USERNAME` | Usuário SMTP (padrão `NULL` = sem autenticação). Pode ser sobreposto por Web Credential do workspace |
| *SMTP Password* / *Confirm SMTP Password* | `SMTP_PASSWORD` | Senha SMTP |
| *Use SSL/TLS* | `SMTP_TLS_MODE` | **Yes** (`Y`: conexão criptografada antes do SMTP), **After connection is established** (`STARTTLS`: envia `EHLO` e `STARTTLS` logo após conectar), **No** (`N`, padrão: sem criptografia) |
| *Default Email From Address* | `SMTP_FROM` | Remetente de tarefas administrativas (aprovação de provisionamento, reset de senha) e, se definido, remetente forçado de todos os `APEX_MAIL.SEND` |
| *Maximum Emails per Workspace* | `WORKSPACE_EMAIL_MAXIMUM` | Máximo de e-mails por workspace em 24 h via `APEX_MAIL` (padrão 1000) |
| *Maximum Emails Processed per Workspace* | `MAX_MAIL_QUEUE_ROWS` | Quantos e-mails da fila por workspace cada execução do job processa |

Outros parâmetros de instância ligados a e-mail (só via API):

| Parâmetro | Uso |
|---|---|
| `EMAIL_ATTACHMENT_MAX_SIZE_MB` | Tamanho máximo de um anexo (`APEX_MAIL` e processo Send E-Mail) |
| `SMTP_ALLOW_WORKSPACE_CREDENTIALS` | `Y` permite que workspaces usem Web Credential própria para o SMTP |
| `SMTP_CLIENT_DOMAIN` | Domínio enviado no HELO/EHLO |
| `SMTP_CONNECTION_REUSE_COUNT` | Quantos e-mails o job envia antes de reabrir a conexão (padrão 1) |
| `SMTP_ENVELOPE_FROM` | Endereço "MAIL FROM" do envelope; se vazio, usa `p_from` |
| `SMTP_SECURE_HOST` | Hosts aceitos no certificado quando há TLS |
| `SMTP_REST_EMAIL_MODE` / `SMTP_REST_EMAIL_URL` | `Y` entrega via OCI Notification Service em vez de relay SMTP (padrão `N`) |
| `SMTP_RETRY_PERMANENT_ERROR_PATTERNS` | Regex de erros "permanentes" a tratar como temporários (padrão `.*`) |
| `DB_SIGNATURE` | Se não nulo e diferente de `APEX_INSTANCE_ADMIN.DB_SIGNATURE`, desliga envio de e-mails (útil em bancos clonados) |
| `WALLET_PATH` / `WALLET_PWD` | Wallet para TLS |
| `SMTP_CREDENTIAL_STATIC_ID` (parâmetro de workspace) | Static ID da Web Credential usada pelo workspace no SMTP |

Para Autonomous AI Database, a doc remete a "Sending Email from APEX" no guia do Autonomous.

Fonte: [Configuring Email](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-email.html), [Configuring Oracle APEX to Send Email](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/Configuring-Oracle-Application-Express-to-Send-Email.html), [Available Parameter Values](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_INSTANCE_ADMIN.Available-Parameter-Values.html)

### APEX_MAIL: configurar e consultar o e-mail em ambiente runtime (APEX_INSTANCE_ADMIN) e validar com VALIDATE_EMAIL_CONFIG

Em *runtime environment* (sem a UI de Administration Services), conecte como `SYS` (SQLcl, `CONNECT SYS as SYSDBA`) e use a API:

```sql
begin
    apex_instance_admin.set_parameter('SMTP_HOST_ADDRESS', 'smtp.example.com');
    apex_instance_admin.set_parameter('SMTP_HOST_PORT',    '587');
    apex_instance_admin.set_parameter('SMTP_TLS_MODE',     'STARTTLS');
    apex_instance_admin.set_parameter('SMTP_USERNAME',     'usuario');
    apex_instance_admin.set_parameter('SMTP_PASSWORD',     'senha');
    commit;
end;
/

-- consultar
select apex_instance_admin.get_parameter('SMTP_HOST_ADDRESS') from dual;
```

Depois de configurar, **valide**:

```sql
APEX_INSTANCE_ADMIN.VALIDATE_EMAIL_CONFIG   -- sem parâmetros

begin
    apex_instance_admin.validate_email_config;
end;
```

`VALIDATE_EMAIL_CONFIG` tenta abrir conexão com o servidor de e-mail configurado. Se conectar, termina sem fazer nada; se falhar, **levanta erro**. A falha pode indicar parâmetros SMTP errados, **Network ACL ausente**, **certificado SSL ausente no Oracle Wallet** ou problema no próprio servidor. Corrija e rode de novo para confirmar.

Fonte: [Configuring Email](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-email.html), [VALIDATE_EMAIL_CONFIG Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/VALIDATE_EMAIL_CONFIG-Procedure.html)

### APEX_MAIL: liberar rede para o SMTP (DBMS_NETWORK_ACL_ADMIN) e wallet para SSL/TLS

**Network ACL.** Por padrão o banco bloqueia chamadas de rede. O DBA precisa conceder `connect` ao usuário dono do schema APEX (`APEX_260100`) com `DBMS_NETWORK_ACL_ADMIN`. Sem isso, as chamadas a `APEX_MAIL` funcionam (a mensagem entra na fila), mas o **envio falha**. A mesma liberação atende REST/web services, LDAP de saída e impressão em servidor remoto. O privilégio vale para a instância inteira (todos os workspaces); schemas de workspace só precisam de ACL própria se usarem `UTL_HTTP`/`UTL_SMTP` diretamente. Upgrades do APEX copiam a configuração da versão anterior. Não se aplica ao Autonomous Database.

```sql
-- Como SYS (SYSDBA): qualquer host
begin
    dbms_network_acl_admin.append_host_ace(
        host => '*',
        ace  => xs$ace_type(privilege_list => xs$name_list('connect'),
                            principal_name => apex_application.g_flow_schema_owner,
                            principal_type => xs_acl.ptype_db));
end;
/

-- Mais restrito: só servidores no próprio host do banco (SMTP local, impressão)
begin
    dbms_network_acl_admin.append_host_ace(
        host => 'localhost',
        ace  => xs$ace_type(privilege_list => xs$name_list('connect'),
                            principal_name => apex_application.g_flow_schema_owner,
                            principal_type => xs_acl.ptype_db));
end;
/
```

O parâmetro `compatible` do banco precisa ser pelo menos `11.1.0.0.0` para esses exemplos.

**Wallet.** É obrigatório criar um wallet (com o certificado confiável do servidor) quando *Use SSL/TLS* = Yes no SMTP. Configure-o em *Instance Settings > Wallet* ou com `WALLET_PATH` (ex.: `file:/home/<username>/wallets`) e `WALLET_PWD`. No Oracle AI Database 26ai ou superior, a configuração de wallet pode ficar vazia (ver `SET_WALLET` na referência PL/SQL do banco).

Fonte: [Enabling Network Services in Oracle Database](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/enabling-network-services.html), [Configuring Email (About Enabling Network Services)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-email.html), [Configuring Wallet Information](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-wallet-information.html)

### APEX_MAIL: credenciais SMTP por workspace (Web Credential)

Se a instância permitir (`SMTP_ALLOW_WORKSPACE_CREDENTIALS = Y`), o administrador do workspace pode usar usuário/senha SMTP próprios: *Administration > Manage Service > Set Workspace Preferences*, seção **Email**:

- *Instance SMTP Server*: mostra o servidor da instância (só leitura).
- *Use Workspace SMTP Credentials*: liga o uso de credenciais do workspace; desligado, valem as da instância.
- *SMTP Authentication Credential*: escolhe uma Web Credential do tipo *Basic Authentication* do workspace; ou crie uma nova com *SMTP Web Credential Name*, *SMTP Username* e *SMTP Password*.
- O botão **Test SMTP Credential** verifica se as credenciais estão corretas.

Em API, o parâmetro de workspace correspondente é `SMTP_CREDENTIAL_STATIC_ID`.

Fonte: [Configuring Workspace Preferences (Configuring Email Credentials for a Workspace)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-workspace-preferences.html), [Available Parameter Values](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_INSTANCE_ADMIN.Available-Parameter-Values.html)

### APEX_MAIL: e-mail de provisionamento de workspace e como desativá-lo (Email Provisioning)

O APEX pode mandar automaticamente por e-mail as credenciais quando um pedido de workspace é aprovado. Para isso, conclua a configuração de e-mail e escolha o modo de provisionamento *Request with Email Verification* (parâmetro `SERVICE_REQUEST_FLOW`: `MANUAL` padrão, `EMAIL` pedido com aprovação, `AUTO` aprovação automática).

Para **desativar** o provisionamento por e-mail (usado junto do método *Automatic*): *Administration Services > Manage Instance > Instance Settings*, em *Email Provisioning* selecione **Disabled** e preencha *Message* com o texto explicativo exibido ao usuário. Disabled desliga totalmente o provisionamento de workspaces. Na API: `DISABLE_WS_PROV = 'Y'` e `DISABLE_WS_MSG` com a mensagem.

Fonte: [Disabling Email Provisioning](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/disabling-email-provisioning.html), [Sending Email from an Application (About Email Provisioning)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/sending-email-from-an-application.html), [Available Parameter Values](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_INSTANCE_ADMIN.Available-Parameter-Values.html)

### APEX_MAIL: criar Email Templates em Shared Components (placeholders, !RAW, !STRIPHTML, directives, APEXlang)

Caminho: *App Builder > aplicação > Shared Components > User Interface > Email Templates > Create Email Template*.

| Campo | Uso |
|---|---|
| *Identification > Template Name* | Nome descritivo |
| *Identification > Static Identifier* | ID usado em `APEX_MAIL.SEND(p_template_static_id)` e `PREPARE_TEMPLATE(p_static_id)` |
| *Identification > Email Subject* | Assunto; aceita `#STRING_NAME#` |
| *HTML Format > Header / Body / Footer* | Partes do HTML; aceitam `#STRING_NAME#` e marcação básica |
| *HTML Format > Advanced, HTML Template* | Esqueleto HTML que envolve header/body/footer; botão *Load Default HTML* carrega o padrão |
| *Plain Text Format* | Versão texto; aceita `#STRING_NAME#` |
| *Comments* | Comentários |

- **Templates de exemplo:** na lateral, *Sample Templates*: *Load Order Details*, *Load Event Reminder*, *Load Scheduled Outage*. A região *Sample API Usage* mostra a chamada `apex_mail.send` pronta com todos os placeholders.
- **Escape automático:** valores substituídos em HTML recebem escape de HTML; em texto, não. Para HTML intencional use `#NOME!RAW#`; para remover tags, `#NOME!STRIPHTML#`.
- **Template Directives:** suportadas em atributos específicos do template, ex.: `{if NEW_COMMISSION/}, e sua comissão agora é #NEW_COMMISSION#{endif/}`.
- **Copiar / assinar:** copiar dentro da app (novo nome e Static ID) ou *Copy from another app*, com opção *Subscribe*. Na página do template, região *Subscription*: *Subscribe From*, *Refresh Email Template*, *Unsubscribe*.
- **Relatórios:** abas *Utilization* (onde o template é usado) e *History* (mudanças recentes).

No APEXlang, o componente é `emailTemplate` (filho de `app`):

````
emailTemplate "pedido_confirmado" (
  name: Pedido confirmado
  emailSubject: Pedido #ORDER_NUMBER# confirmado
  htmlFormat {
    header: ```
    <h1>Olá, #CUSTOMER_NAME#</h1>
    ```
    body: ```
    <p>Seu pedido #ORDER_NUMBER# foi confirmado.</p>
    ```
  }
  plainTextFormat {
    content: ```
    Olá, #CUSTOMER_NAME#. Seu pedido #ORDER_NUMBER# foi confirmado.
    ```
  }
  advanced {
    staticId: ORDER_CONFIRMATION
  }
)
````

Propriedades: `name` e `emailSubject` (obrigatórios, até 255), `htmlFormat.header/body/footer` (`body` obrigatório, até 32767), `plainTextFormat.content`, `advanced.staticId` (obrigatório), `advanced.versionNumber` (`1` ou `2`), `advanced.htmlTemplate`, `subscription.master`, `comments.comments`.

Fonte: [Managing Email Templates](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-email-templates.html), [Defining Email Template with Directives](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/defining-email-template-directives.html), [APEXlang API Reference (emailTemplate)](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### APEX_MAIL: alternativa declarativa, processo e ação Send E-Mail (página, workflow, task, automation)

O processo nativo **Send E-Mail** (APEXlang `type: sendEMail`) envia e-mail com anexos opcionais sem PL/SQL. Ele existe como processo de página, atividade de workflow, ação de *Task Definition* e ação de *Automation*, todos com o mesmo comportamento. Por baixo usa a mesma fila do `APEX_MAIL`.

- **Remetente:** o *From* tem como padrão `&APP_EMAIL.`, cujo valor vem de *Shared Components > Application Definition > Properties > Application Email From Address*. (Uma página do Developer's Companion escreve `&APP_MAIL.`; a outra, e o sistema, usam `APP_EMAIL`.)
- **Endereços** (*To, Cc, Bcc, Reply To*) aceitam substituições como `&P2_CUST_EMAIL.` (com o ponto final).
- **Com template:** em *Settings > Email Template* escolha o template e clique em **Set Placeholder Values** para mapear cada placeholder a um valor estático, item de página/aplicação, coluna (automation), variável de workflow ou substituição de sistema (ex.: `&APEX$TASK_SUBJECT.` em task).
- **Sem template:** preencha *Subject*, *Body Plain Text* e/ou *Body HTML* com substituições.
- **Anexos:** *Attachment SQL* com 4 colunas (BLOB, nome, MIME type, content id), ver seção do `ADD_ATTACHMENT`.
- **Mensagem de sucesso:** no Send E-Mail, a substituição `#TO#` traz os destinatários.
- **Workflows rodam em background:** lá `APP_USER` vale `nobody`; passe o usuário como parâmetro e busque o e-mail numa *Additional Data* query (ex.: `apex_workspace_apex_users`). Em atributos `href`, use `&LINK_TO_PAGE!ATTR.` para o escape correto.

Prefira o processo declarativo para envios únicos ligados a um botão; use `APEX_MAIL` quando o envio estiver dentro de lógica PL/SQL maior, em loops ou fora de uma página.

Fonte: [Sending Emails with Templates](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/sending-emails-templates.html), [Setting Up Default From Email Address](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/setting-default-email-address.html), [Using Email Template and Placeholders](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-email-template-and-placeholders-notifying-end-users.html), [Emailing User a Page Link](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/emailing-user-page-link.html), [Sending Email on Task Creation](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/sending-email-task-creation.html), [Managing Email Templates](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-email-templates.html), [About Page Processes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-page-processes.html)

### E-mail do APEX_MAIL fica parado na fila APEX_MAIL_QUEUE e nunca chega

**Sintoma:** `APEX_MAIL.SEND` executa sem erro, mas o e-mail não chega; a mensagem continua em `APEX_MAIL_QUEUE` (ou na tela *Mail Queue*) com um erro registrado.
**Causa:** a entrega para o SMTP falha. Causas descritas pela doc: parâmetros SMTP incorretos (host/porta/usuário/senha/TLS), **Network ACL ausente** para `APEX_260100`, certificado SSL ausente no wallet ao usar TLS, endereço inválido ou servidor de e-mail indisponível.
**Correção:** rode `APEX_INSTANCE_ADMIN.VALIDATE_EMAIL_CONFIG` para ver o erro de conexão; corrija os parâmetros (*Instance Settings > Email* ou `SET_PARAMETER`), crie a ACL com `DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE` e/ou configure o wallet; depois use *Force Send All Mail* ou `APEX_MAIL.PUSH_QUEUE`.
**Prevenção:** valide a configuração após qualquer mudança de SMTP; monitore `APEX_MAIL_QUEUE`.

Fonte: [VALIDATE_EMAIL_CONFIG Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/VALIDATE_EMAIL_CONFIG-Procedure.html), [Managing Meta Data](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/managing-meta-data.html), [Enabling Network Services in Oracle Database](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/enabling-network-services.html)

### E-mail do APEX_MAIL demora até 5 minutos para sair

**Sintoma:** o e-mail chega, mas com atraso de alguns minutos.
**Causa:** `SEND` só enfileira; o job `ORACLE_APEX_MAIL_QUEUE` processa a fila a cada 5 minutos. Mensagens que já falharam esperam um intervalo exponencial (2, 4, 8, 16 min…) antes da nova tentativa.
**Correção:** chame `APEX_MAIL.PUSH_QUEUE` logo depois do `SEND` quando precisar de envio imediato (ou use *Send All Mail* / *Force Send All Mail* na tela *Mail Queue*).

Fonte: [DBMS_SCHEDULER Jobs](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/dbms_scheduler-jobs.html), [PUSH_QUEUE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PUSH_QUEUE-Procedure.html), [Managing Meta Data](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/managing-meta-data.html)

### Mensagem sumiu da fila do APEX_MAIL sem ser entregue (erro só no APEX_MAIL_LOG)

**Sintoma:** a mensagem saiu de `APEX_MAIL_QUEUE`, mas o destinatário não recebeu.
**Causa:** após 14 tentativas sem sucesso, o APEX remove a mensagem da fila e grava o último erro em `APEX_MAIL_LOG`. Também pode ser um erro SMTP tratado como permanente (conforme `SMTP_RETRY_PERMANENT_ERROR_PATTERNS`), que remove a mensagem imediatamente.
**Correção:** leia o erro em `APEX_MAIL_LOG` (ou *Monitor Activity > Logs > Mail Log*), corrija a causa (endereço, servidor, ACL) e reenvie a mensagem.

Fonte: [Managing Meta Data](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/managing-meta-data.html), [Available Parameter Values](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_INSTANCE_ADMIN.Available-Parameter-Values.html)

### ORA-44416: Invalid ACL ao liberar rede para o APEX_MAIL

**Sintoma:** o script `DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE` para `host => '*'` falha com `ORA-44416: Invalid ACL`.
**Causa:** a ACL já atribuída a `'*'` referencia usuários de banco que foram removidos.
**Correção:** identifique as referências órfãs e depois remova os principals inválidos (ou a ACL inteira) e rode de novo o `APPEND_HOST_ACE`:

```sql
select acl, principal
  from dba_network_acls nacl, xds_ace ace
 where host = '*' and lower_port is null and upper_port is null
   and nacl.aclid = ace.aclid
   and not exists (select null from all_users where username = principal);
```

O script completo de correção (que atualiza `XDB.XDB$ACL` com `DELETEXML` ou apaga a ACL) está na página oficial; execute-o como `SYS` e faça `COMMIT`.

Fonte: [Enabling Network Services in Oracle Database (Troubleshooting an Invalid ACL Error)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/enabling-network-services.html)

### SMTP com SSL/TLS falha no APEX_MAIL (certificado / wallet)

**Sintoma:** com *Use SSL/TLS* = Yes ou `STARTTLS`, a validação ou o envio falham na conexão.
**Causa:** falta o wallet com o certificado do servidor SMTP, ou `WALLET_PATH`/`WALLET_PWD` não foram configurados (em bancos anteriores ao 26ai).
**Correção:** o DBA cria o wallet com o certificado confiável; configure em *Instance Settings > Wallet* ou `WALLET_PATH`/`WALLET_PWD`; se necessário, ajuste `SMTP_SECURE_HOST`; rode `VALIDATE_EMAIL_CONFIG`.

Fonte: [Configuring Wallet Information](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-wallet-information.html), [VALIDATE_EMAIL_CONFIG Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/VALIDATE_EMAIL_CONFIG-Procedure.html)

### E-mail do APEX_MAIL chega cortado ou com pontos de exclamação no meio do texto

**Sintoma:** o corpo chega truncado ou com `!` inseridos em lugares aleatórios.
**Causa:** alguma linha de `p_body` ou `p_body_html` passou de 1000 caracteres sem CRLF, violando a especificação SMTP/MIME.
**Correção:** insira `utl_tcp.crlf` pelo menos a cada 1000 caracteres (ex.: após cada tag de bloco ou linha de tabela HTML gerada em loop).

Fonte: [SEND Function Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SEND-Function-Signature-1.html)

### APEX_MAIL.SEND ignora o p_from e usa outro remetente

**Sintoma:** o destinatário vê um remetente diferente do passado em `p_from`.
**Causa:** a instância tem *Default Email From Address* (`SMTP_FROM`) definido; ele é usado sempre, independentemente de `p_from`. Na assinatura com template, sem `p_from` o APEX usa `APP_EMAIL`, depois `p_replyto`, depois `p_to`.
**Correção:** combine com o administrador da instância; use `p_replyto` para direcionar as respostas. Defina o *Application Email From Address* da aplicação.

Fonte: [SEND Function Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SEND-Function-Signature-1.html), [SEND Function Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SEND-Function-Signature-2.html)

### APEX_MAIL com template falha quando chamado de job do Scheduler ou SQLcl

**Sintoma:** chamada a `APEX_MAIL.SEND(p_template_static_id => …)` funciona na página, mas falha num job, script ou package chamado fora de sessão APEX.
**Causa:** fora do contexto de uma aplicação, `apex_application.g_flow_id` não aponta para a app, então o template não é encontrado; ou o usuário de banco não está mapeado/definido para o workspace.
**Correção:** passe `p_application_id` explicitamente; antes, defina o workspace com `APEX_UTIL.SET_WORKSPACE` ou `APEX_UTIL.SET_SECURITY_GROUP_ID`. Usuários sem nenhum workspace precisam de `APEX_ADMINISTRATOR_ROLE`.

Fonte: [APEX_MAIL](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_MAIL.html), [SEND Procedure Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SEND-Procedure-Signature-2.html)

### Imagens não aparecem no e-mail enviado pelo APEX_MAIL

**Sintoma:** o e-mail chega com imagens quebradas.
**Causa:** imagens referenciadas por URL não vão anexadas; se a URL está atrás de firewall (ex.: servidor interno), o destinatário externo não a alcança. Imagens inline (`cid:`) podem não ser exibidas automaticamente por alguns clientes.
**Correção:** use URLs públicas (`APEX_MAIL.GET_IMAGES_URL` com *Images URL* configurada) ou anexe inline com `ADD_ATTACHMENT(p_content_id => …)`. Sempre inclua `alt`.
**Prevenção:** a doc recomenda evitar imagens em e-mails.

Fonte: [SEND Function Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SEND-Function-Signature-1.html), [ADD_ATTACHMENT Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_ATTACHMENT-Procedure-Signature-1.html)

### HTML aparece como texto (tags escapadas) num placeholder de Email Template

**Sintoma:** um placeholder que deveria renderizar `<strong>` mostra `&lt;strong&gt;` no e-mail.
**Causa:** valores de placeholder são escapados automaticamente no formato HTML, por segurança.
**Correção:** no template, use `#NOME!RAW#` para inserir o valor como veio (garanta que ele é seguro) ou `#NOME!STRIPHTML#` na versão texto para remover tags.

Fonte: [Managing Email Templates (About Including Dynamic Text)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-email-templates.html)

### APEX_MAIL para de enviar: limite diário do workspace ou banco clonado

**Sintoma:** depois de muitos envios no dia, ou num banco recém-clonado, os e-mails param de sair.
**Causa:** `WORKSPACE_EMAIL_MAXIMUM` (padrão 1000 por 24 h por workspace) foi atingido; ou o parâmetro `DB_SIGNATURE` está preenchido e difere de `APEX_INSTANCE_ADMIN.DB_SIGNATURE` (recurso para desligar e-mails em clones).
**Correção:** peça ao administrador da instância para ajustar *Maximum Emails per Workspace*; em clone legítimo que deve enviar, ajuste `DB_SIGNATURE`.

Fonte: [Available Parameter Values](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_INSTANCE_ADMIN.Available-Parameter-Values.html), [Configuring Email](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-email.html)

### APEX_MAIL.SEND não compila ou não acha a assinatura (p_body CLOB e p_body_html VARCHAR2)

**Sintoma:** erro de compilação/chamada ao misturar tipos nos corpos.
**Causa:** `p_body` e `p_body_html` precisam ser do mesmo tipo (`VARCHAR2` com `VARCHAR2` ou `CLOB` com `CLOB`).
**Correção:** declare as duas variáveis como `CLOB` (o mais seguro para corpos grandes).

Fonte: [SEND Function Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SEND-Function-Signature-1.html), [SEND Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SEND-Procedure-Signature-1.html)


## 14. APEX_PRINT: gerar documentos (PDF, Office, HTML…) a partir de templates e dados via servidor de impressão

### APEX_PRINT: propósito, quando usar e quando não usar

`APEX_PRINT` gera documentos chamando o **servidor de impressão remoto** configurado na instância, combinando um template com dados. O resultado vem sempre como `BLOB`, que você pode baixar (`APEX_HTTP.DOWNLOAD`), anexar a um e-mail (`APEX_MAIL.ADD_ATTACHMENT`), guardar numa tabela ou compactar (`APEX_ZIP`).

Há dois "modos" de uso:

1. **Com componentes da aplicação** (Signatures 2 e 3): usa *Report Queries* e/ou *Report Layouts* de Shared Components, identificados pelo Static ID. Funciona com o servidor de impressão configurado.
2. **Com template próprio, fora dos Report Layouts** (Signatures 1, 4, 5, 6 + `UPLOAD_TEMPLATE`/`REMOVE_TEMPLATE`): **só funciona** quando o servidor de impressão da instância é o **Oracle Document Generator Pre-built Function** (OCI). O template pode vir como BLOB, ser enviado uma vez ao Object Storage e reutilizado pelo ID, ou já estar num bucket do OCI Object Storage.

**Pré-requisitos:**

- Servidor de impressão configurado em *Administration Services > Manage Instance > Instance Settings > Report Printing*. Opções: *None (Native)* (CSV, HTML, PDF, XLSX básicos), *External (Apache FOP)*, *Oracle BI Publisher* (exige licença), *APEX Office Print*, *Oracle Document Generator Pre-built Function*. O desenvolvedor também pode definir o *Print Server Type* na Application Definition.
- Para o Document Generator: o banco precisa ter `DBMS_CLOUD`, uma credencial de nuvem (crie com `APEX_INSTANCE_ADMIN.CREATE_CLOUD_CREDENTIAL`) e os atributos *Cloud Credential*, *Object Storage Namespace*, *Object Storage Bucket Compartment OCID*, *Object Storage Bucket Endpoint*, *Function OCID* e *Function Endpoint*.
- Servidores remotos exigem rede liberada (ACL via `DBMS_NETWORK_ACL_ADMIN`, ver a seção de e-mail/rede).

**Quando usar:** gerar PDF/DOCX/XLSX em processos PL/SQL (ex.: certificado, contracheque, relatório para anexar a e-mail), gerar documentos em lote ou com dados JSON montados livremente.

**Quando não usar:** se o usuário só precisa baixar o conteúdo de um relatório na tela, use os recursos declarativos de impressão/download das regiões (Interactive Report/Grid, Report Queries com URL de impressão). Sem Document Generator, as assinaturas de template próprio não funcionam.

**Pegadinhas:**

- `p_output_password` protege o documento com senha **só para PDF**.
- `p_data` nas assinaturas de Document Generator aceita **apenas JSON** por enquanto; na Signature 3, o formato depende do tipo de servidor.
- Na Signature 4, `p_output_type` aceita atualmente só `c_output_pdf`.
- Nas constantes de saída, `c_output_html = 4` e `c_output_pptx = 5` (a ordem na doc não é numérica); use sempre os nomes, nunca os números.

Fonte: [APEX_PRINT](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_PRINT.html), [Configuring Report Printing for an Instance](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-report-printing-for-an-instance.html)

### APEX_PRINT: referência completa de functions, procedures, constantes e tipos

| Item | Tipo | O que faz |
|---|---|---|
| `GENERATE_DOCUMENT` (Signature 1) | function | Dados JSON + template em `BLOB` → documento. Só Document Generator |
| `GENERATE_DOCUMENT` (Signature 2) | function | *Report Query* (Static ID) + *Report Layout* opcional → documento |
| `GENERATE_DOCUMENT` (Signature 3) | function | Dados (`CLOB`) + *Report Layout* (Static ID) → documento |
| `GENERATE_DOCUMENT` (Signature 4) | function | Dados JSON + template já enviado (`p_template_id` de `UPLOAD_TEMPLATE`) → documento. Só Document Generator |
| `GENERATE_DOCUMENT` (Signature 5) | function | Dados JSON + template num bucket do OCI Object Storage → documento. Só Document Generator |
| `GENERATE_DOCUMENT` (Signature 6) | function | *Report Query* (Static ID) + template no OCI Object Storage → documento. Só Document Generator |
| `UPLOAD_TEMPLATE` | function | Envia um template ao OCI Object Storage e devolve o ID. Só Document Generator |
| `REMOVE_TEMPLATE` | procedure | Remove do Object Storage um template enviado com `UPLOAD_TEMPLATE`. Só Document Generator |
| `t_template_type` | subtipo | `pls_integer range 1..12` |
| `c_template_docx` (1), `c_template_xlsx` (2), `c_template_pptx` (3), `c_template_html` (4), `c_template_markdown` (5), `c_template_csv` (6), `c_template_txt` (7), `c_template_ods` (8), `c_template_odt` (9), `c_template_odp` (10), `c_template_rtf` (11), `c_template_xslfo` (12) | constantes `t_template_type` | Tipos de template |
| `t_output_type` | subtipo | `pls_integer range 1..15` |
| `c_output_pdf` (1), `c_output_docx` (2), `c_output_xlsx` (3), `c_output_html` (4), `c_output_pptx` (5), `c_output_markdown` (6), `c_output_csv` (7), `c_output_txt` (8), `c_output_odt` (9), `c_output_ods` (10), `c_output_odp` (11), `c_output_htm` (12), `c_output_rtf` (13), `c_output_xls` (14), `c_output_xml` (15) | constantes `t_output_type` | Formatos de saída |

```sql
subtype t_template_type is pls_integer range 1..12;
subtype t_output_type   is pls_integer range 1..15;
```

Fonte: [APEX_PRINT Constants](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_PRINT.Constants.html), [APEX_PRINT](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_PRINT.html)

### APEX_PRINT.GENERATE_DOCUMENT (Signatures 2 e 3): gerar documento com Report Query e Report Layout da aplicação

Usam componentes de Shared Components. A **Signature 2** parte de uma *Report Query* (a consulta fornece os dados) e opcionalmente de um *Report Layout*. A **Signature 3** recebe os dados prontos em `p_data` e aplica um *Report Layout*.

```sql
-- Signature 2
APEX_PRINT.GENERATE_DOCUMENT (
    p_application_id            IN NUMBER,
    p_report_query_static_id    IN VARCHAR2,
    p_report_layout_static_id   IN VARCHAR2         DEFAULT NULL,
    p_output_type               IN t_output_type    DEFAULT c_output_pdf,
    p_output_password           IN VARCHAR2         DEFAULT NULL )
    RETURN BLOB;

-- Signature 3
APEX_PRINT.GENERATE_DOCUMENT (
    p_application_id            IN NUMBER,
    p_data                      IN CLOB,
    p_report_layout_static_id   IN VARCHAR2,
    p_output_type               IN t_output_type    DEFAULT c_output_pdf,
    p_output_password           IN VARCHAR2         DEFAULT NULL )
    RETURN BLOB;
```

| Parâmetro | Descrição |
|---|---|
| `p_application_id` | Aplicação onde estão a Report Query / Report Layout |
| `p_report_query_static_id` | (Sig. 2) Static ID da Report Query |
| `p_report_layout_static_id` | Static ID do Report Layout (opcional na Sig. 2, obrigatório na Sig. 3) |
| `p_data` | (Sig. 3) Dados do relatório; o formato depende do tipo de servidor de impressão |
| `p_output_type` | Formato de saída (`t_output_type`); padrão `c_output_pdf` |
| `p_output_password` | Senha para abrir o documento (só PDF) |

**Retorno:** `BLOB` com o documento gerado.

```sql
-- Signature 2: Report Query + Report Layout, download direto
declare
    l_document blob;
begin
    l_document := apex_print.generate_document (
        p_application_id          => 100,
        p_report_query_static_id  => 'MY_REPORT_QUERY',
        p_report_layout_static_id => 'MY_REPORT_LAYOUT',
        p_output_type             => apex_print.c_output_pdf );

    apex_http.download(
        p_blob         => l_document,
        p_content_type => 'application/pdf',
        p_filename     => 'my-report.pdf' );
end;

-- Signature 3: JSON montado no código + Report Layout
declare
    l_document blob;
    l_json     sys.json_object_t := sys.json_object_t();
begin
    l_json.put( 'title', 'Hello World' );

    l_document := apex_print.generate_document (
        p_application_id          => 100,
        p_data                    => l_json.to_clob(),
        p_report_layout_static_id => 'MY_REPORT_LAYOUT',
        p_output_type             => apex_print.c_output_pdf );

    apex_http.download(
        p_blob         => l_document,
        p_content_type => 'application/pdf',
        p_filename     => 'hello-world.pdf' );
end;
```

**Pegadinhas:** o Static ID dos Report Layouts é gerado a partir do nome ao copiar sem assinatura ou dentro da mesma app, então confira o ID depois de copiar. Para relatórios de região (Classic/Interactive Report), o *data loop name* do layout define o nome do array no JSON gerado.

Fonte: [GENERATE_DOCUMENT Function Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_PRINT.GENERATE_DOCUMENT-Function-Signature-2.html), [GENERATE_DOCUMENT Function Signature 3](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_PRINT.GENERATE_DOCUMENT-Function-Signature-3.html), [Formatting a Report Region or Report Query Using Report Layouts](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/formatting-using-report-layouts.html)

### APEX_PRINT.GENERATE_DOCUMENT (Signature 1): documento com template BLOB avulso (Document Generator)

Gera um único documento com um template personalizado que **não** está salvo como Report Layout (ex.: DOCX enviado pelo usuário). Só funciona com *Oracle Document Generator Pre-built Function* como servidor de impressão.

```sql
APEX_PRINT.GENERATE_DOCUMENT (
    p_data               IN CLOB,
    p_template           IN BLOB,
    p_template_type      IN t_template_type  DEFAULT c_template_docx,
    p_output_type        IN t_output_type    DEFAULT c_output_pdf,
    p_output_password    IN VARCHAR2         DEFAULT NULL )
    RETURN BLOB;
```

(A sintaxe oficial tem um `)` sobrando antes de `RETURN BLOB`; erro tipográfico da doc.)

| Parâmetro | Descrição |
|---|---|
| `p_data` | Dados do documento; **só JSON** por enquanto |
| `p_template` | Conteúdo do template |
| `p_template_type` | Tipo do template; padrão `c_template_docx` |
| `p_output_type` | Formato de saída; padrão `c_output_pdf` |
| `p_output_password` | Senha do PDF |

**Retorno:** `BLOB` com o documento.

```sql
declare
    l_template blob;
    l_data     sys.json_object_t := sys.json_object_t();
    l_document blob;
begin
    select blob_content
      into l_template
      from apex_application_temp_files
     where name = :P1_TEMPLATE;          -- arquivo enviado por um File Upload

    l_data.put( 'name', 'Scott' );

    l_document := apex_print.generate_document(
                      p_data     => l_data.to_clob,
                      p_template => l_template );
end;
```

Fonte: [GENERATE_DOCUMENT Function Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_PRINT.GENERATE_DOCUMENT-Function-Signature-1.html)

### APEX_PRINT.UPLOAD_TEMPLATE, GENERATE_DOCUMENT (Signature 4) e REMOVE_TEMPLATE: reutilizar um template em vários documentos (Document Generator)

Quando o mesmo template personalizado vai gerar muitos documentos, envie-o **uma vez** ao OCI Object Storage com `UPLOAD_TEMPLATE`, gere cada documento pela Signature 4 usando o ID devolvido e remova o template no fim com `REMOVE_TEMPLATE`. Tudo exige o Document Generator como servidor de impressão.

```sql
APEX_PRINT.UPLOAD_TEMPLATE (
    p_template      IN BLOB,
    p_template_type IN t_template_type  DEFAULT c_template_docx )
    RETURN NUMBER;

-- Signature 4
APEX_PRINT.GENERATE_DOCUMENT (
    p_data            IN CLOB,
    p_template_id     IN NUMBER,
    p_output_type     IN t_output_type    DEFAULT c_output_pdf,
    p_output_password IN VARCHAR2         DEFAULT NULL )
    RETURN BLOB;

APEX_PRINT.REMOVE_TEMPLATE (
    p_template_id IN NUMBER );
```

| Rotina / parâmetro | Descrição |
|---|---|
| `UPLOAD_TEMPLATE.p_template` | Conteúdo do template |
| `UPLOAD_TEMPLATE.p_template_type` | Tipo do template; padrão `c_template_docx` |
| `UPLOAD_TEMPLATE` retorno | `NUMBER`: ID único do template para as chamadas seguintes |
| `GENERATE_DOCUMENT.p_data` | Dados JSON |
| `GENERATE_DOCUMENT.p_template_id` | ID devolvido por `UPLOAD_TEMPLATE` |
| `GENERATE_DOCUMENT.p_output_type` | Atualmente só `c_output_pdf` |
| `GENERATE_DOCUMENT.p_output_password` | Senha do PDF |
| `REMOVE_TEMPLATE.p_template_id` | ID do template a remover do Object Storage |

```sql
declare
    l_template    blob;
    l_template_id number;
    l_data        sys.json_object_t := sys.json_object_t();
    l_document    blob;
begin
    select blob_content
      into l_template
      from apex_application_temp_files
     where name = :P1_TEMPLATE;

    l_template_id := apex_print.upload_template( p_template => l_template );

    l_data.put( 'name', 'Scott' );

    l_document := apex_print.generate_document(
                      p_data        => l_data.to_clob,
                      p_template_id => l_template_id );

    apex_print.remove_template( p_template_id => l_template_id );
exception
    when others then
        apex_print.remove_template( p_template_id => l_template_id );
        raise;   -- o exemplo oficial só remove; relançar evita esconder o erro
end;
```

**Pegadinha:** sempre remova o template também no caminho de erro (como no exemplo oficial), senão ele fica órfão no bucket.

Fonte: [UPLOAD_TEMPLATE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_PRINT.UPLOAD_TEMPLATE-Function.html), [GENERATE_DOCUMENT Function Signature 4](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_PRINT.GENERATE_DOCUMENT-Function-Signature-4.html), [REMOVE_TEMPLATE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_PRINT.REMOVE_TEMPLATE-Procedure.html)

### APEX_PRINT.GENERATE_DOCUMENT (Signatures 5 e 6): template armazenado num bucket do OCI Object Storage

Quando o template já está num bucket do OCI Object Storage, indique bucket, namespace e nome do objeto. A **Signature 5** recebe os dados em JSON; a **Signature 6** obtém os dados de uma *Report Query* da aplicação. Ambas só com Document Generator.

```sql
-- Signature 5
APEX_PRINT.GENERATE_DOCUMENT (
    p_data                   IN              CLOB,
    p_template_type          IN              t_template_type,
    p_template_bucket        IN              VARCHAR2,
    p_template_namespace     IN              VARCHAR2,
    p_template_object        IN              VARCHAR2,
    p_output_type            IN              t_output_type DEFAULT c_output_pdf,
    p_output_password        IN              VARCHAR2      DEFAULT NULL)
    RETURN BLOB;

-- Signature 6
APEX_PRINT.GENERATE_DOCUMENT (
    p_application_id         IN              NUMBER,
    p_report_query_static_id IN              VARCHAR2,
    p_template_type          IN              t_template_type,
    p_template_bucket        IN              VARCHAR2,
    p_template_namespace     IN              VARCHAR2,
    p_template_object        IN              VARCHAR2,
    p_output_type            IN              t_output_type    DEFAULT c_output_pdf,
    p_output_password        IN              VARCHAR2         DEFAULT NULL)
    RETURN BLOB;
```

| Parâmetro | Descrição |
|---|---|
| `p_data` | (Sig. 5) Dados JSON |
| `p_application_id` / `p_report_query_static_id` | (Sig. 6) Aplicação e Static ID da Report Query |
| `p_template_type` | Tipo do template (obrigatório, sem default) |
| `p_template_bucket` | Nome do bucket |
| `p_template_namespace` | Namespace do Object Storage |
| `p_template_object` | Nome do objeto (arquivo de template) no bucket |
| `p_output_type` | Formato de saída; padrão `c_output_pdf` |
| `p_output_password` | Senha do PDF |

```sql
declare
    l_document blob;
    l_json     sys.json_object_t := sys.json_object_t();
begin
    l_json.put( 'title', 'Hello World' );

    l_document := apex_print.generate_document (
        p_data               => l_json.to_clob(),
        p_template_type      => apex_print.c_template_docx,
        p_template_bucket    => 'mybucket',
        p_template_namespace => 'mynamespace',
        p_template_object    => 'mytemplate.docx',
        p_output_type        => apex_print.c_output_pdf,
        p_output_password    => '...senha...' );

    apex_http.download(
        p_blob         => l_document,
        p_content_type => 'application/pdf',
        p_filename     => 'hello-world.pdf' );
end;
```

A Signature 6 é igual, trocando `p_data` por `p_application_id => 100, p_report_query_static_id => 'MY_REPORT_QUERY'`.

Fonte: [GENERATE_DOCUMENT Function Signature 5](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_PRINT.GENERATE_DOCUMENT-Function-Signature-5.html), [GENERATE_DOCUMENT Function Signature 6](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_PRINT.GENERATE_DOCUMENT-Function-Signature-6.html)

### APEX_PRINT com template próprio falha porque o servidor de impressão não é o Document Generator

**Sintoma:** chamadas a `UPLOAD_TEMPLATE`, `REMOVE_TEMPLATE` ou `GENERATE_DOCUMENT` com `p_template`, `p_template_id` ou `p_template_bucket` não funcionam.
**Causa:** essas assinaturas só podem ser usadas quando o servidor de impressão da instância é o *Oracle Document Generator Pre-built Function*.
**Correção:** configure o Document Generator em *Instance Settings > Report Printing* (banco com `DBMS_CLOUD`, credencial criada com `APEX_INSTANCE_ADMIN.CREATE_CLOUD_CREDENTIAL`, namespace, compartment OCID, endpoints do bucket e da função). Sem OCI, use as Signatures 2/3 com Report Queries/Layouts no servidor disponível.

Fonte: [GENERATE_DOCUMENT Function Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_PRINT.GENERATE_DOCUMENT-Function-Signature-1.html), [Configuring Report Printing for an Instance](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-report-printing-for-an-instance.html)


## 15. APEX_ZIP: compactar e descompactar arquivos ZIP em BLOB

### APEX_ZIP: propósito, quando usar e quando não usar

`APEX_ZIP` cria e lê arquivos ZIP inteiramente em PL/SQL, trabalhando com `BLOB`s. Para **criar**, chame `ADD_FILE` uma vez por arquivo e, no fim, **obrigatoriamente** `FINISH`. Para **ler**, obtenha o diretório do ZIP com `GET_DIR_ENTRIES` e extraia cada arquivo com `GET_FILE_CONTENT` (Signature 2, que recebe o registro do diretório).

- **Quando usar:** baixar vários documentos de uma vez (ex.: anexos de um colaborador), anexar um pacote a um e-mail (`APEX_MAIL.ADD_ATTACHMENT` ou *Attachment SQL* do Send E-Mail), importar um ZIP enviado pelo usuário e gravar cada arquivo numa tabela.
- **Quando não usar:** para um único arquivo que não precisa de compressão, entregue o BLOB direto. As páginas da doc não mencionam senha/criptografia de ZIP nem limites de tamanho.
- **Itens deprecated:** `GET_FILES`, `GET_FILE_CONTENT` Signature 1 e o tipo `t_files` serão removidos numa versão futura. Use `GET_DIR_ENTRIES`, `GET_FILE_CONTENT` Signature 2 e `t_dir_entries`.

Fonte: [APEX_ZIP](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_ZIP.html)

### APEX_ZIP: referência completa de procedures, functions e tipos

| Item | Tipo | O que faz |
|---|---|---|
| `ADD_FILE` | procedure | Adiciona um arquivo (nome com caminho + BLOB) ao ZIP em construção |
| `FINISH` | procedure | Fecha o ZIP depois de todos os `ADD_FILE` (obrigatório) |
| `GET_DIR_ENTRIES` | function | Devolve `t_dir_entries` com todos os arquivos do ZIP, indexado pelo nome completo |
| `GET_FILE_CONTENT` (Signature 1) **(Deprecated)** | function | Extrai um arquivo pelo nome (`p_file_name`) |
| `GET_FILE_CONTENT` (Signature 2) | function | Extrai um arquivo a partir de um registro `t_dir_entry` |
| `GET_FILES` **(Deprecated)** | function | Devolve `t_files` (array de nomes); substituída por `GET_DIR_ENTRIES` |
| `t_dir_entry` | tipo record | `file_name`, `uncompressed_length`, `is_directory` |
| `t_dir_entries` | tipo tabela associativa | `table of t_dir_entry index by VARCHAR2(32767)` |
| `t_files` **(Deprecated)** | tipo tabela associativa | `table of varchar2(32767) index by binary_integer` |

```sql
type t_dir_entry is record (
    file_name           VARCHAR2(32767),   -- nome com caminho dentro do ZIP
    uncompressed_length NUMBER,            -- tamanho descompactado em bytes
    is_directory        BOOLEAN );         -- TRUE se a entrada é um diretório

type t_dir_entries is table of t_dir_entry index by VARCHAR2(32767);

-- Deprecated
type t_files is table of varchar2(32767) index by binary_integer;
```

Fonte: [APEX_ZIP Data Types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_ZIP.Data-Types.html), [APEX_ZIP](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_ZIP.html)

### APEX_ZIP.ADD_FILE e FINISH: criar um ZIP com vários arquivos

```sql
APEX_ZIP.ADD_FILE (
    p_zipped_blob IN OUT NOCOPY BLOB,
    p_file_name   IN VARCHAR2,
    p_content     IN BLOB );

APEX_ZIP.FINISH (
    p_zipped_blob IN OUT NOCOPY BLOB );
```

| Parâmetro | Descrição |
|---|---|
| `p_zipped_blob` | BLOB do ZIP em construção (`IN OUT`; o mesmo em todas as chamadas) |
| `p_file_name` | Nome do arquivo dentro do ZIP, **incluindo o caminho** (ex.: `docs/contrato.pdf`) |
| `p_content` | BLOB com o conteúdo do arquivo |

**Comportamento:** cada `ADD_FILE` acrescenta um arquivo; `FINISH` completa a estrutura do ZIP. Sem `FINISH`, o BLOB não é um ZIP válido.

```sql
declare
    l_zip_file blob;
begin
    for l_file in (select file_name, file_content
                     from my_files)
    loop
        apex_zip.add_file (
            p_zipped_blob => l_zip_file,
            p_file_name   => l_file.file_name,
            p_content     => l_file.file_content );
    end loop;

    apex_zip.finish ( p_zipped_blob => l_zip_file );

    -- exemplo de entrega: download
    apex_http.download(
        p_blob         => l_zip_file,
        p_content_type => 'application/zip',
        p_filename     => 'arquivos.zip' );
end;
```

Para anexar o ZIP a um e-mail, use `APEX_MAIL.ADD_ATTACHMENT(p_mime_type => 'application/zip')`, ou guarde-o numa collection e devolva-o no *Attachment SQL* do processo Send E-Mail (exemplo oficial com `blob001` de `apex_collections`).

**Pegadinha:** no exemplo oficial a variável BLOB começa nula e é passada a todas as chamadas; use uma variável nova para cada ZIP.

Fonte: [ADD_FILE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_ZIP.ADD_FILE-Procedure-2.html), [FINISH Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_ZIP.FINISH-Procedure.html), [Choosing Descriptive Process Names](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/choosing-descriptive-process-names.html)

### APEX_ZIP.GET_DIR_ENTRIES e GET_FILE_CONTENT (Signature 2): listar e extrair arquivos de um ZIP

```sql
APEX_ZIP.GET_DIR_ENTRIES (
    p_zipped_blob IN BLOB,
    p_only_files  IN BOOLEAN  DEFAULT TRUE,
    p_encoding    IN VARCHAR2 DEFAULT NULL )
    RETURN t_dir_entries;

APEX_ZIP.GET_FILE_CONTENT (
    p_zipped_blob   IN BLOB,
    p_dir_entry     IN t_dir_entry )
    RETURN BLOB;
```

| Parâmetro | Descrição |
|---|---|
| `p_zipped_blob` | BLOB com o ZIP |
| `p_only_files` | `TRUE` (padrão): só arquivos; `FALSE`: inclui entradas de diretório |
| `p_encoding` | Codificação usada ao compactar (para nomes de arquivo) |
| `p_dir_entry` | Registro `t_dir_entry` do arquivo desejado (obtido de `GET_DIR_ENTRIES`) |

**Retorno:** `GET_DIR_ENTRIES` devolve a tabela de entradas indexada pelo nome completo; `GET_FILE_CONTENT` devolve o BLOB do arquivo descrito.

Como a coleção é indexada por `VARCHAR2`, percorra-a com `.first`/`.next`, não com `for i in 1..count`:

```sql
declare
    l_zip_file      blob;
    l_unzipped_file blob;
    l_dir           apex_zip.t_dir_entries;
    l_file_path     varchar2(32767);
begin
    select file_content
      into l_zip_file
      from my_zip_files
     where file_name = 'my_file.zip';

    l_dir := apex_zip.get_dir_entries ( p_zipped_blob => l_zip_file );

    l_file_path := l_dir.first;
    while l_file_path is not null loop
        l_unzipped_file := apex_zip.get_file_content (
                               p_zipped_blob => l_zip_file,
                               p_dir_entry   => l_dir(l_file_path) );

        insert into my_files ( file_name, file_content )
        values ( l_file_path, l_unzipped_file );

        l_file_path := l_dir.next(l_file_path);
    end loop;
end;
```

`uncompressed_length` permite recusar arquivos grandes demais **antes** de extrair; `is_directory` só vem `TRUE` se `p_only_files => FALSE`.

Fonte: [GET_DIR_ENTRIES Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_ZIP.GET_DIR_ENTRIES-Function.html), [GET_FILE_CONTENT Function Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_ZIP.GET_FILE_CONTENT-Function-Signature-2.html)

### APEX_ZIP: GET_FILES e GET_FILE_CONTENT Signature 1 (Deprecated) e como migrar

As duas rotinas antigas ainda existem, mas serão removidas:

```sql
-- Deprecated: use GET_DIR_ENTRIES
APEX_ZIP.GET_FILES (
    p_zipped_blob IN BLOB,
    p_only_files  IN BOOLEAN DEFAULT TRUE,
    p_encoding    IN VARCHAR2 DEFAULT NULL )
RETURN t_files;

-- Deprecated: use GET_FILE_CONTENT Signature 2
APEX_ZIP.GET_FILE_CONTENT (
    p_zipped_blob IN BLOB,
    p_file_name   IN VARCHAR2,
    p_encoding    IN VARCHAR2 DEFAULT NULL )
RETURN BLOB;
```

`GET_FILES` devolve um array (`t_files`, índice `binary_integer`) com os nomes e caminhos; com `p_only_files => TRUE` exclui diretórios vazios. `GET_FILE_CONTENT` Signature 1 extrai pelo nome.

**Migração:** troque `l_files := apex_zip.get_files(...)` + `for i in 1..l_files.count` + `get_file_content(p_file_name => l_files(i))` por `l_dir := apex_zip.get_dir_entries(...)` + laço `.first/.next` + `get_file_content(p_dir_entry => l_dir(l_path))`, como na seção anterior.

Fonte: [GET_FILES Function (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_ZIP.GET_FILES-Function.html), [GET_FILE_CONTENT Function Signature 1 (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_ZIP.GET_FILE_CONTENT-Function-Signature-1.html)

### ZIP gerado pelo APEX_ZIP chega corrompido ou não abre

**Sintoma:** o arquivo `.zip` baixado ou anexado não abre ("arquivo inválido/corrompido").
**Causa:** `APEX_ZIP.FINISH` não foi chamado depois do último `ADD_FILE`; a doc exige essa chamada para completar o ZIP.
**Correção:** chame `apex_zip.finish(p_zipped_blob => l_zip)` antes de usar o BLOB (download, e-mail, insert).

Fonte: [ADD_FILE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_ZIP.ADD_FILE-Procedure-2.html), [FINISH Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_ZIP.FINISH-Procedure.html)


## 16. APEX_BARCODE: gerar QR Code, Code 128 e EAN 8 em SVG ou PNG

### APEX_BARCODE: propósito, quando usar e quando não usar

`APEX_BARCODE` gera códigos de barras em PL/SQL em dois formatos: **SVG** (função `*_SVG`, devolve `CLOB` com o markup SVG) e **PNG** (função `*_PNG`, devolve `BLOB` com a imagem). Tipos suportados: **QR Code**, **Code 128** e **EAN 8**.

- **SVG** é texto: serve para inserir direto no HTML de uma região, de um relatório ou de um e-mail HTML. A doc observa que `GET_QRCODE_SVG` é a função usada normalmente na renderização do item de página QR Code.
- **PNG** é binário: serve quando é preciso um **arquivo de imagem** (download, anexo de e-mail com `APEX_MAIL.ADD_ATTACHMENT`, imagem inline `cid:`, gravação numa tabela, inclusão num ZIP com `APEX_ZIP`).
- **Quando não usar:** para só exibir um QR Code numa página a partir de um valor, o item de página QR Code é declarativo e dispensa PL/SQL. A doc 26.1 não lista outros formatos (EAN 13, DataMatrix etc.) nem rotina de leitura de códigos.

**Pegadinhas gerais:**

- Cores sempre em **hex** (`#000000`). Fundo `NULL` (padrão) = **transparente**; em e-mail ou impressão, defina um fundo explícito (ex.: `#ffffff`) para garantir contraste.
- Nas funções PNG o tamanho é dado por `p_scale` (inteiro 1–10, multiplica o tamanho original, que depende do tamanho do valor); nas SVG, por `p_size` em pixels (padrão 256).
- Os exemplos oficiais de SVG chamam `sys.dbms_outout.put_line` (erro de digitação da doc; o correto é `sys.dbms_output.put_line`). O exemplo do QR PNG usa `c_eclevel_type_high` sem prefixo; fora do package, qualifique como `apex_barcode.c_eclevel_type_high`.

Fonte: [APEX_BARCODE](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_BARCODE.html), [GET_QRCODE_SVG Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_QRCODE_SVG-Function.html)

### APEX_BARCODE: referência completa de functions e constantes

| Item | Tipo | O que faz |
|---|---|---|
| `GET_CODE128_PNG` | function | Code 128 em PNG (`BLOB`) |
| `GET_CODE128_SVG` | function | Code 128 em SVG (`CLOB`) |
| `GET_EAN8_PNG` | function | EAN 8 em PNG (`BLOB`); valor numérico, até 8 caracteres |
| `GET_EAN8_SVG` | function | EAN 8 em SVG (`CLOB`); valor numérico, até 8 dígitos |
| `GET_QRCODE_PNG` | function | QR Code em PNG (`BLOB`), com zona de silêncio e nível de correção |
| `GET_QRCODE_SVG` | function | QR Code em SVG (`CLOB`), com zona de silêncio e nível de correção |
| `c_default_scale` | constante (default) | Escala padrão dos PNG: `1` |
| `c_default_size` | constante (default) | Tamanho padrão dos SVG: 256 px |
| `c_default_foreground_color` | constante (default) | Cor padrão de frente: `#000000` |
| `c_default_quiet` | constante (default) | Zona de silêncio padrão do QR Code: `1` |
| `c_default_eclevel` | constante (default) | Nível de correção padrão do QR Code: `c_eclevel_type_high` |
| `t_eclevel_type` | tipo | Tipo do nível de correção de erro do QR Code |
| `c_eclevel_type_low` / `c_eclevel_type_medium` / `c_eclevel_type_quartile` / `c_eclevel_type_high` | constantes `t_eclevel_type` | Recuperam 7% / 15% / 25% / 30% dos dados se o código estiver sujo ou danificado |
| `WWV_FLOW_BARCODE_API.NUMERIC_INPUT_ERROR` | exceção | Levantada pelas funções EAN 8 quando `p_value` passa de 8 caracteres/dígitos |

Os valores numéricos das constantes `c_default_*` não aparecem na doc; acima estão os padrões que ela descreve nos parâmetros.

Fonte: [APEX_BARCODE](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_BARCODE.html), [GET_QRCODE_PNG Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_QRCODE_PNG-Function.html), [GET_EAN8_PNG Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_EAN8_PNG-Function.html)

### APEX_BARCODE.GET_QRCODE_SVG e GET_QRCODE_PNG: gerar QR Code

```sql
APEX_BARCODE.GET_QRCODE_SVG (
    p_value             IN VARCHAR2,
    p_size              IN NUMBER         DEFAULT c_default_size,
    p_quiet             IN NUMBER         DEFAULT c_default_quiet,
    p_eclevel           IN t_eclevel_type DEFAULT c_default_eclevel,
    p_foreground_color  IN VARCHAR2       DEFAULT c_default_foreground_color,
    p_background_color  IN VARCHAR2       DEFAULT NULL )
    RETURN CLOB;

APEX_BARCODE.GET_QRCODE_PNG (
    p_value             IN VARCHAR2,
    p_scale             IN NUMBER         DEFAULT c_default_scale,
    p_quiet             IN NUMBER         DEFAULT c_default_quiet,
    p_eclevel           IN t_eclevel_type DEFAULT c_default_eclevel,
    p_foreground_color  IN VARCHAR2       DEFAULT c_default_foreground_color,
    p_background_color  IN VARCHAR2       DEFAULT NULL )
    RETURN BLOB;
```

| Parâmetro | Descrição |
|---|---|
| `p_value` | Valor codificado (URL, texto, ID…) |
| `p_size` | (SVG) Tamanho em pixels; padrão 256 |
| `p_scale` | (PNG) Multiplicador inteiro 1–10 sobre o tamanho original (definido pelo tamanho do valor); padrão 1 |
| `p_quiet` | Margem em branco (inteiro positivo) ao redor do código, para facilitar a leitura pelo scanner; padrão 1 |
| `p_eclevel` | Nível de correção: `c_eclevel_type_low` (7%), `c_eclevel_type_medium` (15%), `c_eclevel_type_quartile` (25%), `c_eclevel_type_high` (30%, padrão) |
| `p_foreground_color` | Cor de frente em hex; padrão `#000000` |
| `p_background_color` | Cor de fundo em hex; padrão `NULL` (transparente) |

**Retorno:** SVG em `CLOB` ou PNG em `BLOB`.

```sql
-- SVG para inserir no HTML
declare
    l_output clob;
begin
    l_output := apex_barcode.get_qrcode_svg(
                    p_value            => 'https://apex.example.com',
                    p_foreground_color => '#000000',
                    p_background_color => '#ffffff' );
    sys.dbms_output.put_line( l_output );
end;

-- PNG com margem maior e correção máxima
declare
    l_output blob;
begin
    l_output := apex_barcode.get_qrcode_png(
                    p_value            => 'https://apex.example.com',
                    p_scale            => 4,
                    p_quiet            => 5,
                    p_eclevel          => apex_barcode.c_eclevel_type_high,
                    p_foreground_color => '#000000',
                    p_background_color => '#ffffff' );
end;
```

Fonte: [GET_QRCODE_SVG Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_QRCODE_SVG-Function.html), [GET_QRCODE_PNG Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_QRCODE_PNG-Function.html)

### APEX_BARCODE.GET_CODE128_SVG e GET_CODE128_PNG: gerar código de barras Code 128

Code 128 codifica texto livre (o exemplo oficial usa `'apex.oracle.com'`).

```sql
APEX_BARCODE.GET_CODE128_SVG (
    p_value             IN VARCHAR2,
    p_size              IN NUMBER   DEFAULT c_default_size,
    p_foreground_color  IN VARCHAR2 DEFAULT c_default_foreground_color,
    p_background_color  IN VARCHAR2 DEFAULT NULL )
    RETURN CLOB;

APEX_BARCODE.GET_CODE128_PNG (
    p_value             IN VARCHAR2,
    p_scale             IN NUMBER   DEFAULT c_default_scale,
    p_foreground_color  IN VARCHAR2 DEFAULT c_default_foreground_color,
    p_background_color  IN VARCHAR2 DEFAULT NULL )
    RETURN BLOB;
```

| Parâmetro | Descrição |
|---|---|
| `p_value` | Valor a codificar |
| `p_size` | (SVG) Tamanho em pixels; padrão 256 |
| `p_scale` | (PNG) Multiplicador inteiro 1–10; padrão 1 |
| `p_foreground_color` | Hex; padrão `#000000` |
| `p_background_color` | Hex; padrão `NULL` (transparente) |

```sql
declare
    l_svg clob;
    l_png blob;
begin
    l_svg := apex_barcode.get_code128_svg(
                 p_value            => 'COLAB-000123',
                 p_foreground_color => '#000000',
                 p_background_color => '#ffffff' );

    l_png := apex_barcode.get_code128_png(
                 p_value            => 'COLAB-000123',
                 p_scale            => 2,
                 p_background_color => '#ffffff' );
end;
```

Fonte: [GET_CODE128_SVG Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_CODE128_SVG-Function.html), [GET_CODE128_PNG Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_CODE128_PNG-Function.html)

### APEX_BARCODE.GET_EAN8_SVG e GET_EAN8_PNG: gerar código de barras EAN 8 (numérico, até 8 dígitos)

```sql
APEX_BARCODE.GET_EAN8_SVG (
    p_value             IN VARCHAR2,
    p_size              IN NUMBER   DEFAULT c_default_size,
    p_foreground_color  IN VARCHAR2 DEFAULT c_default_foreground_color,
    p_background_color  IN VARCHAR2 DEFAULT NULL )
    RETURN CLOB;

APEX_BARCODE.GET_EAN8_PNG (
    p_value             IN VARCHAR2,
    p_scale             IN NUMBER   DEFAULT c_default_scale,
    p_foreground_color  IN VARCHAR2 DEFAULT c_default_foreground_color,
    p_background_color  IN VARCHAR2 DEFAULT NULL )
    RETURN BLOB;
```

| Parâmetro | Descrição |
|---|---|
| `p_value` | Valor **numérico**, no máximo 8 dígitos |
| `p_size` | (SVG) Pixels; padrão 256 |
| `p_scale` | (PNG) Multiplicador inteiro 1–10; padrão 1 |
| `p_foreground_color` | Hex; padrão `#000000` |
| `p_background_color` | Hex; padrão `NULL` (transparente) |

**Exceção:** `WWV_FLOW_BARCODE_API.NUMERIC_INPUT_ERROR` quando `p_value` passa de 8 caracteres.

```sql
declare
    l_svg clob;
begin
    l_svg := apex_barcode.get_ean8_svg(
                 p_value            => '12345678',
                 p_foreground_color => '#000000',
                 p_background_color => '#ffffff' );
    sys.dbms_output.put_line( l_svg );
end;
```

Fonte: [GET_EAN8_SVG Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_EAN8_SVG-Function.html), [GET_EAN8_PNG Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_EAN8_PNG-Function.html)

### APEX_BARCODE: usar o código gerado no e-mail, no download ou no ZIP

O PNG (`BLOB`) se combina com outras APIs deste documento:

```sql
declare
    l_png blob;
    l_id  number;
begin
    l_png := apex_barcode.get_qrcode_png(
                 p_value            => 'https://www.example.com/apex/',
                 p_scale            => 4,
                 p_background_color => '#ffffff' );

    l_id := apex_mail.send(
        p_to        => 'colaborador@example.com',
        p_from      => 'rh@example.com',
        p_subj      => 'Seu QR Code de acesso',
        p_body      => 'Use um cliente com suporte a HTML para ver o QR Code.' || utl_tcp.crlf,
        p_body_html => '<html><body><p>Seu QR Code:</p>'
                    || '<img src="cid:qr-acesso" alt="QR Code de acesso">'
                    || '</body></html>');

    apex_mail.add_attachment(
        p_mail_id    => l_id,
        p_attachment => l_png,
        p_filename   => 'qrcode.png',
        p_mime_type  => 'image/png',
        p_content_id => 'qr-acesso');   -- inline
    commit;
end;
```

Para download direto, use `apex_http.download(p_blob => l_png, p_content_type => 'image/png', p_filename => 'qrcode.png')`. Para vários códigos num pacote, `apex_zip.add_file` + `apex_zip.finish`.

Fonte: [GET_QRCODE_PNG Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_QRCODE_PNG-Function.html), [ADD_ATTACHMENT Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_ATTACHMENT-Procedure-Signature-1.html)

### WWV_FLOW_BARCODE_API.NUMERIC_INPUT_ERROR ao gerar EAN 8 com APEX_BARCODE

**Sintoma:** `GET_EAN8_PNG` ou `GET_EAN8_SVG` levanta `WWV_FLOW_BARCODE_API.NUMERIC_INPUT_ERROR`.
**Causa:** `p_value` tem mais de 8 caracteres (EAN 8 aceita só números, no máximo 8 dígitos).
**Correção:** valide o valor antes (numérico, até 8 dígitos); para textos ou códigos maiores, use `GET_CODE128_*` ou `GET_QRCODE_*`.

Fonte: [GET_EAN8_PNG Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_EAN8_PNG-Function.html), [GET_EAN8_SVG Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_EAN8_SVG-Function.html)

### Código de barras do APEX_BARCODE some ou fica ilegível em fundo escuro, impressão ou e-mail

**Sintoma:** o QR Code/código de barras não aparece ou o scanner não lê em tema escuro, PDF ou e-mail.
**Causa:** o fundo padrão é transparente (`p_background_color => NULL`); sobre fundo escuro, as barras pretas perdem contraste. Uma zona de silêncio pequena (`p_quiet` padrão 1) também dificulta a leitura.
**Correção:** passe `p_background_color => '#ffffff'` e, no QR Code, aumente `p_quiet` (o exemplo oficial usa 5).

Fonte: [GET_QRCODE_PNG Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_QRCODE_PNG-Function.html), [GET_CODE128_SVG Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_CODE128_SVG-Function.html)


## 17. APEX_SPATIAL: metadados espaciais e geometrias (Oracle Locator / Spatial) no APEX

### APEX_SPATIAL: propósito, quando usar e quando não usar

`APEX_SPATIAL` é a ponte entre o APEX e o Oracle Locator / Spatial Option. Ele faz duas coisas:

1. **Mantém `USER_SDO_GEOM_METADATA` como o usuário APEX corrente.** Numa sessão APEX, o usuário logado no banco costuma ser `APEX_PUBLIC_USER` ou `ANONYMOUS`. O trigger da view de metadados espaciais executa o DML como esse usuário de logon, mas o DML precisa rodar como dono da aplicação ou do workspace. Por isso um `INSERT` direto na view, por exemplo no SQL Commands do SQL Workshop, não funciona. `INSERT_GEOM_METADATA`, `INSERT_GEOM_METADATA_LONLAT`, `CHANGE_GEOM_METADATA` e `DELETE_GEOM_METADATA` resolvem isso.
2. **Oferece utilitários** para montar geometrias comuns em WGS 84: `POINT`, `RECTANGLE` e `CIRCLE_POLYGON`.

- **Disponibilidade:** se o tipo `SDO_GEOMETRY` não existe no banco, o package contém apenas `SPATIAL_IS_AVAILABLE`, que retorna `FALSE`. As demais rotinas só existem quando o tipo está disponível.
- **Quando usar:** criar ou ajustar metadados e índice espacial de uma coluna `SDO_GEOMETRY` a partir do SQL Workshop ou de scripts de instalação que rodam na sessão APEX, e montar pontos, retângulos ou círculos para consultas de proximidade e para regiões de mapa.
- **Quando não usar:** para operações espaciais avançadas (relações, distâncias, buffers), use direto o `MDSYS` (`SDO_UTIL`, operadores `SDO_*`). O `APEX_SPATIAL` não os substitui.

Fonte: [APEX_SPATIAL](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_SPATIAL.html)

### APEX_SPATIAL: referência completa de procedures, functions, constantes e tipos

| Item | Tipo | O que faz |
|---|---|---|
| `t_srid` | tipo (subtype de `number`) | Identificador do sistema de referência (SRID) |
| `c_no_reference_system` | constante (`t_srid`) | `null`: sem sistema de referência |
| `c_wgs_84` | constante (`t_srid`) | `4326`: World Geodetic System (EPSG:4326), padrão das funções de geometria |
| `CHANGE_GEOM_METADATA` | procedure | Altera um registro de metadados (tabela, coluna, dimensões, SRID) |
| `CIRCLE_POLYGON` | function | Polígono que aproxima um círculo (raio em metros) |
| `DELETE_GEOM_METADATA` | procedure | Remove o registro de metadados (e, opcionalmente, o índice espacial) |
| `INSERT_GEOM_METADATA` | procedure | Insere metadados com dimensões e SRID livres; cria índice opcionalmente |
| `INSERT_GEOM_METADATA_LONLAT` | procedure | Insere metadados prontos para longitude/latitude; cria índice opcionalmente |
| `POINT` | function | Ponto em (`lon`, `lat`) |
| `RECTANGLE` | function | Retângulo entre dois cantos |
| `SPATIAL_IS_AVAILABLE` | function | `SDO_GEOMETRY` está disponível no banco? |

```sql
subtype t_srid is number;
c_no_reference_system constant t_srid := null;
c_wgs_84              constant t_srid := 4326; -- EPSG:4326
```

Fonte: [Data Types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_SPATIAL-Data-Types.html), [APEX_SPATIAL](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_SPATIAL.html)

### APEX_SPATIAL.INSERT_GEOM_METADATA e INSERT_GEOM_METADATA_LONLAT: registrar coluna espacial e criar índice

```sql
APEX_SPATIAL.INSERT_GEOM_METADATA (
    p_table_name        IN VARCHAR2,
    p_column_name       IN VARCHAR2,
    p_diminfo           IN mdsys.sdo_dim_array,
    p_srid              IN t_srid,
    p_create_index_name IN VARCHAR2 DEFAULT NULL );

APEX_SPATIAL.INSERT_GEOM_METADATA_LONLAT (
    p_table_name        IN VARCHAR2,
    p_column_name       IN VARCHAR2,
    p_tolerance         IN NUMBER   DEFAULT 1,
    p_create_index_name IN VARCHAR2 DEFAULT NULL );
```

| Parâmetro | Descrição |
|---|---|
| `p_table_name` | Tabela de *features* |
| `p_column_name` | Coluna do tipo `mdsys.sdo_geometry` |
| `p_diminfo` | Array de `SDO_DIM_ELEMENT`, uma entrada por dimensão, na ordem das dimensões |
| `p_srid` | SRID de todas as geometrias da coluna |
| `p_tolerance` | (`_LONLAT`) Tolerância por dimensão, **em metros** (padrão 1) |
| `p_create_index_name` | Se informado, cria um índice espacial com esse nome |

**Comportamento:** a versão `_LONLAT` já monta as dimensões e o SRID adequados a longitude/latitude, e você só escolhe a tolerância. A versão genérica pede o `SDO_DIM_ARRAY` e o SRID explicitamente.

```sql
create table cities (
    city_id   number primary key,
    city_name varchar2(30),
    shape     mdsys.sdo_geometry );

-- opção 1: lon/lat, criando o índice junto
begin
    apex_spatial.insert_geom_metadata_lonlat(
        p_table_name        => 'CITIES',
        p_column_name       => 'SHAPE',
        p_create_index_name => 'CITIES_IDX_SHAPE' );
end;
/

-- opção 2: dimensões explícitas e índice criado à mão
begin
    apex_spatial.insert_geom_metadata(
        p_table_name  => 'CITIES',
        p_column_name => 'SHAPE',
        p_diminfo     => sdo_dim_array(
                             sdo_dim_element('X', -180, 180, 1),
                             sdo_dim_element('Y',  -90,  90, 1) ),
        p_srid        => apex_spatial.c_wgs_84 );
end;
/
create index cities_idx_shape on cities(shape) indextype is mdsys.spatial_index;
```

**Pegadinha:** `p_create_index_name` só funciona para nome de coluna simples. Índices baseados em função ou em atributos de objeto dão erro. Nesses casos, deixe o parâmetro nulo e crie o índice manualmente.

Fonte: [INSERT_GEOM_METADATA Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/INSERT_GEOM_METADATA-Procedure.html), [INSERT_GEOM_METADATA_LONLAT Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/INSERT_GEOM_METADATA_LONLAT-Procedure.html)

### APEX_SPATIAL.CHANGE_GEOM_METADATA e DELETE_GEOM_METADATA: alterar ou remover metadados espaciais

```sql
APEX_SPATIAL.CHANGE_GEOM_METADATA (
    p_table_name        IN VARCHAR2,
    p_column_name       IN VARCHAR2,
    p_new_table_name    IN VARCHAR2 DEFAULT NULL,
    p_new_column_name   IN VARCHAR2 DEFAULT NULL,
    p_diminfo           IN mdsys.sdo_dim_array,
    p_srid              IN t_srid );

APEX_SPATIAL.DELETE_GEOM_METADATA (
    p_table_name        IN VARCHAR2,
    p_column_name       IN VARCHAR2,
    p_drop_index        IN BOOLEAN DEFAULT FALSE );
```

| Parâmetro | Descrição |
|---|---|
| `p_new_table_name` / `p_new_column_name` | Novo nome. Nulo mantém o atual |
| `p_diminfo` / `p_srid` | Obrigatórios no `CHANGE`: as dimensões e o SRID finais |
| `p_drop_index` | `TRUE` também apaga o índice espacial da coluna (padrão `FALSE`) |

```sql
-- alterar a tolerância das dimensões preservando o SRID atual
begin
    for m in ( select * from user_sdo_geom_metadata
                where table_name = 'CITIES' and column_name = 'SHAPE' ) loop
        apex_spatial.change_geom_metadata(
            p_table_name  => m.table_name,
            p_column_name => m.column_name,
            p_diminfo     => sdo_dim_array(
                                 sdo_dim_element('X', -180, 180, 0.1),
                                 sdo_dim_element('Y',  -90,  90, 0.1) ),
            p_srid        => m.srid );
    end loop;
end;

-- remover metadados e índice
begin
    apex_spatial.delete_geom_metadata(
        p_table_name  => 'CITIES',
        p_column_name => 'SHAPE',
        p_drop_index  => true );
end;
```

**Pegadinha:** `p_diminfo` e `p_srid` não têm default no `CHANGE`. Para mudar só o nome, releia os valores atuais de `USER_SDO_GEOM_METADATA` e repasse-os, como no exemplo.

Fonte: [CHANGE_GEOM_METADATA Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CHANGE_GEOM_METADATA-Procedure.html), [DELETE_GEOM_METADATA Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/DELETE_GEOM_METADATA-Procedure.html)

### APEX_SPATIAL.POINT, RECTANGLE e CIRCLE_POLYGON: montar geometrias em WGS 84

```sql
APEX_SPATIAL.POINT (
    p_lon        IN NUMBER,
    p_lat        IN NUMBER,
    p_srid       IN t_srid DEFAULT c_wgs_84 )
RETURN mdsys.sdo_geometry;

APEX_SPATIAL.RECTANGLE (
    p_lon1        IN NUMBER,   -- canto inferior esquerdo
    p_lat1        IN NUMBER,
    p_lon2        IN NUMBER,   -- canto superior direito
    p_lat2        IN NUMBER,
    p_srid        IN t_srid DEFAULT c_wgs_84 )
RETURN mdsys.sdo_geometry;

APEX_SPATIAL.CIRCLE_POLYGON (
    p_lon           IN NUMBER,
    p_lat           IN NUMBER,
    p_radius        IN NUMBER,           -- metros
    p_arc_tolerance IN NUMBER DEFAULT 20,
    p_srid          IN t_srid DEFAULT c_wgs_84 )
RETURN mdsys.sdo_geometry;
```

**Equivalências documentadas:**
- `apex_spatial.point(10, 50)` = `mdsys.sdo_geometry(2001, 4326, sdo_point_type(10, 50, null), null, null)`.
- `apex_spatial.rectangle(10, 50, 11, 51)` = um polígono `2003` com `sdo_elem_info_array(1, 1003, 1)` e as ordenadas `(10,50, 11,50, 11,51, 10,51, 10,50)`.
- `CIRCLE_POLYGON` delega a `mdsys.sdo_util.circle_polygon`. Consulte essa função para a semântica de `p_arc_tolerance`.

```sql
select apex_spatial.point(-46.63, -23.55)            from dual;  -- São Paulo
select apex_spatial.rectangle(10, 50, 11, 51)        from dual;
select apex_spatial.circle_polygon(-46.63, -23.55, 5000) from dual;  -- raio de 5 km
```

**Pegadinhas**
- A ordem é **longitude primeiro**, depois latitude.
- O raio de `CIRCLE_POLYGON` é em metros, e o exemplo oficial (`circle_polygon(0, 0, 1)`) gera um círculo de só 1 metro.

Fonte: [POINT Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/POINT-Function.html), [RECTANGLE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/RECTANGLE-Function.html), [CIRCLE_POLYGON Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CIRCLE_POLYGON-Function.html)

### APEX_SPATIAL.SPATIAL_IS_AVAILABLE: verificar se SDO_GEOMETRY existe no banco

```sql
APEX_SPATIAL.SPATIAL_IS_AVAILABLE
RETURN BOOLEAN;
```

Retorna `TRUE` quando o tipo `SDO_GEOMETRY` está disponível no banco e `FALSE` caso contrário. É a única rotina que sempre existe no package.

```sql
begin
    sys.dbms_output.put_line(
        case when apex_spatial.spatial_is_available then 'TRUE' else 'FALSE' end );
end;
```

**Pegadinha:** a sintaxe na doc aparece como `SPATIAL_IS_AVAILABLE ( spatial_is_available )`, mas a função não recebe parâmetro. Chame sem argumentos, como no exemplo.

Fonte: [SPATIAL_IS_AVAILABLE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SPATIAL_IS_AVAILABLE-Function.html)

### INSERT em USER_SDO_GEOM_METADATA falha no SQL Commands do APEX

**Sintoma:** um `INSERT INTO user_sdo_geom_metadata ...` no SQL Workshop (ou num processo de página) dá erro ou não grava.
**Causa:** na sessão APEX, o usuário de logon é `APEX_PUBLIC_USER`/`ANONYMOUS`, e o trigger da view faz o DML como esse usuário, não como o schema dono da aplicação.
**Correção:** use `APEX_SPATIAL.INSERT_GEOM_METADATA` (ou `_LONLAT`), `CHANGE_GEOM_METADATA` e `DELETE_GEOM_METADATA`, que operam como o usuário APEX corrente.
**Prevenção:** em scripts de instalação que rodam pelo APEX, teste `apex_spatial.spatial_is_available` antes e use sempre a API.

Fonte: [APEX_SPATIAL](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_SPATIAL.html)


## 18. APEX_SEARCH: busca da aplicação (Search Configurations) e conversão de consultas para Oracle Text

### APEX_SEARCH: propósito, quando usar e quando não usar

`APEX_SEARCH` dá acesso em PL/SQL/SQL à **busca da aplicação** (*Search Configurations* de Shared Components, as mesmas usadas pela região *Search*) e a dois conversores de texto de busca para a sintaxe do Oracle Text.

- `SEARCH` é uma função *pipelined* que roda uma ou mais *Search Configurations* (pelo *Static ID*) e devolve linhas num formato padronizado: título, subtítulo, badge, link, ícone, score etc.
- `QUERY_EXPERT_SEARCH` converte uma expressão "avançada" do usuário (AND, OR, NOT, AROUND, aspas, fuzzy, pesos) numa consulta Oracle Text.
- `QUERY_SEARCH_ENGINE` converte uma busca simples numa consulta Oracle Text com *query relaxation*: tenta primeiro a forma mais exata e vai relaxando (stem, fuzzy, OR).

- **Quando usar:** montar a sua própria UI de resultados (Cards, Classic Report, JSON para JS) reaproveitando as search configurations, buscar em várias fontes ao mesmo tempo, ou gerar a cláusula `CONTAINS` a partir de texto digitado pelo usuário.
- **Quando não usar:** se a região *Search* nativa atende, não precisa da API. Os conversores só fazem sentido com colunas indexadas pelo Oracle Text (`CONTAINS`). Em `LIKE`/`INSTR` eles não servem.

Fonte: [APEX_SEARCH](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_SEARCH.html)

### APEX_SEARCH: referência completa de functions

| Item | Tipo | O que faz |
|---|---|---|
| `QUERY_EXPERT_SEARCH` | function (`CLOB`) | Converte expressão com operadores para sintaxe Oracle Text |
| `QUERY_SEARCH_ENGINE` | function (`CLOB`) | Converte busca simples em consulta Oracle Text com relaxamento progressivo |
| `SEARCH` | function pipelined (`apex_search_result_table`) | Executa Search Configurations e devolve os resultados padronizados |

O package não declara constantes nem tipos próprios. O retorno de `SEARCH` usa o object type `apex_search_result_table`.

Fonte: [APEX_SEARCH](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_SEARCH.html)

### APEX_SEARCH.SEARCH: executar Search Configurations em SQL

```sql
APEX_SEARCH.SEARCH (
    p_search_static_ids      IN apex_t_varchar2,
    p_search_expression      IN VARCHAR2,
    p_apply_order_bys        IN VARCHAR2           DEFAULT 'Y',
    --
    p_return_total_row_count IN VARCHAR2           DEFAULT 'N' )
    RETURN apex_search_result_table pipelined;
```

| Parâmetro | Descrição |
|---|---|
| `p_search_static_ids` | Lista de Static IDs das Search Configurations em que buscar |
| `p_search_expression` | Termos da busca |
| `p_apply_order_bys` | `Y` aplica a ordenação definida em cada configuração. Passe `N` quando a sua query tiver `ORDER BY` próprio |
| `p_return_total_row_count` | `Y` preenche `TOTAL_ROW_COUNT` |

**Colunas retornadas**

| Coluna | Conteúdo |
|---|---|
| `CONFIG_LABEL`, `CONFIG_ID`, `CONFIG_STATIC_ID` | Rótulo, ID interno e Static ID da configuração de origem |
| `RESULT_SEQ` | Posição do resultado dentro da configuração |
| `TOTAL_ROW_COUNT` | Total de resultados (se pedido) |
| `PRIMARY_KEY_1`, `PRIMARY_KEY_2` | Colunas de chave mapeadas |
| `TITLE`, `SUBTITLE`, `DESCRIPTION`, `BADGE` | Campos de exibição mapeados |
| `LAST_MODIFIED` | Timestamp da última modificação |
| `CUSTOM_01` .. `CUSTOM_03` | Atributos customizados |
| `SCORE` | Score/rank. Com Oracle Text, é o score do Text |
| `LINK`, `RESULT_CSS_CLASSES` | Link e classes CSS do resultado |
| `FORMATTED_ROW` | HTML da linha, se a configuração tiver row template |
| `ICON_TYPE` | `CLASS`, `URL`, `BLOB` ou `INITIALS` |
| `ICON_VALUE`, `ICON_BLOB`, `ICON_MIMETYPE` | Valor do ícone conforme o tipo, BLOB e mimetype |

Os campos de conteúdo seguem o mapeamento feito em cada Search Configuration.

```sql
select config_label, title, subtitle, badge, link
  from table( apex_search.search(
                 p_search_static_ids => apex_t_varchar2( 'COLABORADORES', 'COMUNICADOS' ),
                 p_search_expression => :P0_BUSCA,
                 p_apply_order_bys   => 'N' ) )
 order by score desc nulls last;
```

**Pegadinhas**
- Use `p_apply_order_bys => 'N'` sempre que houver `ORDER BY` externo, senão as duas ordenações competem.
- O filtro por empresa ou permissão precisa estar **dentro** da fonte de cada Search Configuration. A função só devolve o que a configuração permitir.
- `LINK` vem da configuração. Se o link aponta para uma página com *Session State Protection*, gere-o com checksum na própria configuração.

Fonte: [SEARCH Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_SEARCH.SEARCH-Function.html)

### APEX_SEARCH.QUERY_EXPERT_SEARCH: converter busca com operadores para Oracle Text

```sql
APEX_SEARCH.QUERY_EXPERT_SEARCH (
    p_search_expression IN VARCHAR2 )
RETURN CLOB;
```

**Sintaxe aceita em `p_search_expression`**

| Elemento | Exemplo | Efeito |
|---|---|---|
| `AND` | `red AND blue` | Ambos os termos |
| `OR` | `red OR blue` | Vira `ACCUM`: qualquer termo, com score maior se casar com os dois |
| `NOT` | `red NOT blue` | Exclui o segundo termo |
| `AROUND(d)` | `red AROUND(3) blue` | Abstração de `NEAR`: no máximo *d* palavras entre os termos; mais perto, maior score |
| Parênteses | `(red OR blue) AND green` | Agrupamento |
| Aspas | `"red apple"` | Frase exata |
| Fuzzy | `fuzzy+: red apple` / `fuzzy-: ...` | Busca aproximada; `+`/`-` aumenta/diminui a tolerância |
| Peso | `red^3 apple` | Peso maior para o termo |

```sql
select apex_search.query_expert_search('(red or white) "summer shorts"') from dual;
-- ({red} ACCUM {white}) AND {summer shorts}

select apex_search.query_expert_search('fuzzy-: catz dogz') from dual;
-- FUZZY({catz},80,100,W) AND FUZZY({dogz},80,100,W)

select apex_search.query_expert_search('oracle^3 apex') from dual;
-- {oracle}*3 AND {apex}
```

Uso típico:

```sql
select id, titulo, score(1) relevancia
  from comunicado
 where contains( corpo, apex_search.query_expert_search(:P11_BUSCA), 1 ) > 0
   and id_empresa = :G_ID_EMPRESA
 order by relevancia desc;
```

**Pegadinha:** termos soltos sem operador viram `AND` (ver exemplo 3). Os termos saem escapados com `{}`, então você não precisa escapar caracteres especiais do Text.

Fonte: [QUERY_EXPERT_SEARCH Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/QUERY_EXPERT_SEARCH-Function.html)

### APEX_SEARCH.QUERY_SEARCH_ENGINE: busca simples com query relaxation (Oracle Text)

```sql
APEX_SEARCH.QUERY_SEARCH_ENGINE (
    p_search_expression IN VARCHAR2 )
    RETURN CLOB;
```

Gera uma consulta Oracle Text em XML (`<query><textquery><progression>…`) que o Text executa em sequência, da forma mais restrita para a mais solta:
1. frase exata (`{red} {shorts}`);
2. stem (`${red} ${shorts}`);
3. fuzzy;
4. depois o mesmo com `AND`;
5. por fim com `ACCUM`.

Isso maximiza o número de resultados e mantém os mais exatos com score mais alto.

```sql
select apex_search.query_search_engine('red shorts') from dual;
-- <query><textquery><progression>
--   <seq>{red} {shorts}</seq>
--   <seq>${red} ${shorts}</seq>
--   <seq>FUZZY({red},40,1000,W) FUZZY({shorts},40,1000,W)</seq>
--   ... AND ... ACCUM ...
-- </progression></textquery></query>
```

**Quando escolher:** `QUERY_SEARCH_ENGINE` serve para caixas de busca de usuário leigo, sem operadores. `QUERY_EXPERT_SEARCH` serve quando o usuário quer controlar a busca com operadores.

Fonte: [QUERY_SEARCH_ENGINE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/QUERY_SEARCH_ENGINE-Function.html)


## 19. APEX_AI: Generative AI em PL/SQL (generate, chat, tools, embeddings e consentimento)

### APEX_AI: propósito, quando usar e quando não usar

`APEX_AI` é a API PL/SQL do Generative AI do APEX. Com ela você manda um prompt a um *Generative AI Service* (OCI Generative AI, OpenAI, Cohere, Google Gemini, Anthropic Claude, Mistral AI, Ollama ou qualquer serviço compatível com a API da OpenAI) e recebe a resposta em `CLOB`. Também cobre conversas com histórico (`CHAT`), *function calling* (tools), anexos (imagens, PDFs, áudio), saída estruturada em JSON (JSON Schema), embeddings vetoriais (`GET_VECTOR_EMBEDDINGS`), cota de tokens (`GET_AVAILABLE_TOKENS`) e o consentimento do usuário para usar IA.

- **Pré-requisito obrigatório:** o package **exige uma sessão APEX válida**. Fora de uma página (job, SQL Workshop, script), crie a sessão com `apex_session.create_session` e apague com `apex_session.delete_session`, inclusive no `exception`. Os exemplos oficiais de tools fazem isso.
- **Configuração necessária:**
  1. Um *Generative AI Service* em *Workspace Utilities > Generative AI* (também acessível por Shared Components). Ele é do workspace, visível a todas as apps, e guarda a chave do provedor como *Web Credential*. O *Static ID* do serviço é o valor de `p_service_static_id`.
  2. (Opcional) Um serviço padrão da app em *Edit Application Definition > AI > Generative AI, Service*. Quando `p_service_static_id` é omitido, as assinaturas "ad hoc" usam esse padrão.
  3. (Opcional) Um *AI Agent* em *Shared Components > Generative AI > AI Agents*. O agente reúne serviço, *System Prompt*, *Welcome Message*, *Temperature*, tools e *Response Format* (Text ou JSON Object com JSON Schema). O *Static ID* do agente é o `p_agent_static_id`.
  4. (Opcional) Um *Vector Provider* em *Workspace Utilities* para embeddings. Requer Oracle AI Database 26ai ou posterior.
- **Duas famílias de assinatura:**
  - **Baseada em agente** (`GENERATE` assinatura 1, `CHAT` assinatura 1): system prompt, temperatura, tools e formato vêm do AI Agent declarativo. Quando o serviço chama as tools do agente, o APEX as executa sozinho.
  - **Ad hoc** (`GENERATE` assinatura 2, `CHAT` assinatura 2): você passa `p_system_prompt`, `p_temperature`, `p_tools`, `p_response_json_schema` e `p_attachments` no código.
- **Quando usar:** resumir ou classificar texto, gerar rascunhos (por exemplo, um comunicado), extrair dados em JSON a partir de texto livre ou de um anexo, assistentes com acesso a dados via tools, busca semântica com embeddings.
- **Quando não usar:** quando a regra é determinística (um SQL resolve), em lógica crítica sem validação humana, ou em loops por linha sobre muitos registros, já que cada chamada é uma requisição de rede ao provedor e consome tokens. Para um chat pronto na UI, prefira as dynamic actions *Show AI Assistant* e *Generate Text With AI*, que usam o mesmo AI Agent.
- **Administração:** o instance administrator pode habilitar ou desabilitar o suporte a AI Services por workspace ou para a instância. Teste com `APEX_AI.IS_ENABLED` antes de chamar.
- **Export/import:** o export da app omite o segredo da Web Credential. Depois de importar, preencha o segredo manualmente ou por API. Vector Providers usados vão no export. No import, se já existir um provider com o mesmo static ID no workspace de destino, ele é reaproveitado; senão, é criado.
- **Deprecated:** `CHAT` assinatura 3 e `GENERATE` assinatura 3 usam `p_config_static_id`. Troque pelas assinaturas 1 (`p_agent_static_id`).

Fonte: [APEX_AI](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AI.html), [Understanding Generative AI Support in APEX](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-generative-ai-support-in-apex.html), [Configuring a Generative AI Service](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configuring-generative-ai-service.html), [Managing AI Agents and AI Tools](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-ai-agents-and-ai-tools.html), [Configuring AI Attributes for an Application](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-ai-attributes-for-an-application.html), [Managing Vector Providers](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-vector-providers.html)

### APEX_AI: referência completa de procedures, functions, constantes e tipos

| Item | Tipo | O que faz |
|---|---|---|
| `CHAT` (Signature 1) | function | Conversa com um AI Agent (`p_agent_static_id`), mantendo o histórico em `p_messages` |
| `CHAT` (Signature 2) | function | Conversa ad hoc com um serviço: system prompt, temperatura, tools, response handler |
| `CHAT` (Signature 3) **(Deprecated)** | function | Igual à 1, com `p_config_static_id` |
| `GENERATE` (Signature 1) | function | Resposta única a partir de um AI Agent, com anexos e request handler opcionais |
| `GENERATE` (Signature 2) | function | Resposta única ad hoc: system prompt, temperatura, anexos, JSON Schema, tools, response handler |
| `GENERATE` (Signature 3) **(Deprecated)** | function | Igual à 1, com `p_config_static_id` |
| `GET_AVAILABLE_TOKENS` | function | Tokens que ainda podem ser consumidos antes do limite configurado (NULL se não houver limite) |
| `GET_VECTOR_EMBEDDINGS` (Signature 1) | function | Embedding (`VECTOR`) via Vector Provider (static ID) |
| `GET_VECTOR_EMBEDDINGS` (Signature 2) | function | Embedding via modelo ONNX local (owner + nome) |
| `GET_VECTOR_EMBEDDINGS` (Signature 3) | function | Embedding via função PL/SQL própria |
| `IS_ENABLED` | function | Generative AI está habilitado no workspace atual? |
| `IS_USER_CONSENT_NEEDED` | function | O usuário ainda precisa aceitar a mensagem de consentimento? |
| `REVOKE_USER_CONSENT` | procedure | Remove o consentimento de um usuário numa app |
| `REVOKE_USER_CONSENT_FOR_ALL` | procedure | Remove o consentimento de todos os usuários de uma app |
| `SET_TOOL_RESULT` (Signature 1) | procedure | Dentro de uma tool declarativa (*Execute Server-side Code* / *Retrieve Data*): muda resultado, notificação, early exit, `is_safe` |
| `SET_TOOL_RESULT` (Signature 2) | procedure | Dentro de um response handler: registra o resultado de uma tool call específica |
| `SET_USER_CONSENT` | procedure | Marca que o usuário consentiu |
| `c_chat_messages` | constante | Coleção vazia para inicializar `t_chat_messages` (usada nos exemplos oficiais) |
| `c_role_system`, `c_role_user`, `c_role_assistant`, `c_role_tool` | constantes (`t_chat_role`) | `'system'`, `'user'`, `'assistant'`, `'tool'` |
| `c_detail_level_auto` / `_high` / `_low` | constantes (`t_detail_level`) | `'auto'`, `'high'`, `'low'` (detalhe ao processar anexos) |
| `c_notification_type_error` / `_generic` / `_info` / `_success` / `_warning` | constantes (`t_notification_type`) | `'error'`, `null`, `'info'`, `'success'`, `'warning'` |
| `c_resp_err_content_filter` / `_generic` / `_invalid_response` / `_invalid_tool_call` / `_max_length` / `_refusal` | constantes (`t_response_error`) | Tipos de erro recuperável da resposta |
| `c_response_type_complete` / `_error` / `_tool_calls` | constantes (`t_response_type`) | `'complete'`, `'error'`, `'tool_calls'` |
| `c_tool_param_type_boolean` / `_clob` / `_number` / `_varchar2` | constantes (`t_tool_parameter_data_type`) | `'BOOLEAN'`, `'CLOB'`, `'NUMBER'`, `'VARCHAR2'` |
| `t_agent` | tipo (record) | Agente que disparou o handler (`id`, `static_id`) |
| `t_attachment` / `t_attachments` | tipo (record / table) | Anexo (mime, blob/clob, nome, detail level) / coleção |
| `t_chat_message` / `t_chat_messages` | tipo (record / assoc. array) | Uma mensagem do histórico / histórico (`index by pls_integer`) |
| `t_chat_message_tool` | tipo (record) | Resposta de tool no histórico (`id`, `content`) |
| `t_chat_message_tool_call` / `t_chat_message_tool_calls` | tipo (record / table) | Chamada de tool emitida pelo modelo / coleção |
| `t_chat_request` | tipo (record) | Requisição normalizada |
| `t_chat_request_handler_param` / `_result` | tipo (record) | Entrada só-leitura / saída editável do request handler |
| `t_chat_response` | tipo (record) | Resposta normalizada (tipo, erro, recusa, mensagem, tokens) |
| `t_chat_response_handler_param` / `_result` | tipo (record) | Entrada só-leitura / saída editável do response handler |
| `t_chat_role`, `t_detail_level`, `t_notification_type`, `t_response_error`, `t_response_type`, `t_tool_parameter_data_type` | subtypes | varchar2(10), (15), (10), (20), (10), (8) |
| `t_notification` / `t_notifications` | tipo (record / table) | Notificação devolvida pela execução de uma tool |
| `t_tool` / `t_tools` | tipo (record / table) | Definição de tool para `CHAT`/`GENERATE` |
| `t_tool_exec_param` / `t_tool_exec_result` | tipo (record) | Entrada / saída da callback de uma tool |
| `t_tool_parameter` / `t_tool_parameters` | tipo (record / table) | Parâmetro de tool / coleção |

Fonte: [APEX_AI](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AI.html), [Constants and Data Types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AI.Data-Types.html)

### APEX_AI: tipos de mensagem, anexo e histórico de chat (t_chat_message, t_attachment)

```sql
subtype t_chat_role    is varchar2(10);   -- c_role_system | c_role_user | c_role_assistant | c_role_tool
subtype t_detail_level is varchar2(15);   -- c_detail_level_auto | _high | _low

type t_attachment is record (
    mime_type     varchar2(255),   -- obrigatório
    content_blob  blob,            -- imagens, áudio, PDF...
    content_clob  clob,            -- arquivos de texto
    file_name     varchar2(255),   -- alguns provedores/tipos exigem
    detail_level  t_detail_level   -- opcional
);
type t_attachments is table of t_attachment;

type t_chat_message_tool is record (
    id       varchar2(255),
    content  clob
);
type t_chat_message_tool_call is record (
    id        varchar2(255),
    name      varchar2(255),
    args      clob,
    args_json sys.json_object_t
);
type t_chat_message_tool_calls is table of t_chat_message_tool_call;

type t_chat_message is record (
    chat_role    t_chat_role,
    message      clob,
    tool_calls   t_chat_message_tool_calls,
    tool         t_chat_message_tool,
    attachments  t_attachments
);
type t_chat_messages is table of t_chat_message index by pls_integer;
```

Campos usados por papel:
- `system`, `user` e `assistant` usam `chat_role` e `message`.
- `assistant` também pode trazer `tool_calls`.
- `tool` usa o campo `tool` (o `id` da chamada e o `content` do resultado).

**Pegadinhas**
- `t_chat_messages` é *associative array* (`index by pls_integer`). Inicialize com `apex_ai.c_chat_messages` e não com construtor.
- `t_attachments` e `t_tools` são *nested tables*: use o construtor (`apex_ai.t_attachments( ... )`).
- Ao montar um anexo, preencha só um entre `content_blob` e `content_clob`, conforme o tipo do arquivo. Se o provedor e o modelo aceitam um formato, isso depende deles, não do APEX.

Fonte: [Constants and Data Types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AI.Data-Types.html)

### APEX_AI: tipos de tools, handlers e resposta normalizada (t_tool, t_chat_response, handlers)

```sql
subtype t_tool_parameter_data_type is varchar2(8); -- 'BOOLEAN' | 'CLOB' | 'NUMBER' | 'VARCHAR2'

type t_tool_parameter is record (
    name            varchar2(64),
    description     varchar2(32767),
    data_type       t_tool_parameter_data_type,
    is_required     boolean,
    allowed_values  apex_t_varchar2
);
type t_tool_parameters is table of t_tool_parameter;

type t_tool is record (
    name                    varchar2(64),
    description             varchar2(32767),
    parameters              t_tool_parameters,
    parameters_json_schema  clob,             -- alternativa: schema JSON dos argumentos
    callback_procedure      varchar2(255)     -- procedure que executa a tool
);
type t_tools is table of t_tool;

type t_tool_exec_param is record (
    tool       t_tool,
    args       clob,
    args_json  sys.json_object_t
);
type t_tool_exec_result is record (
    result      clob,
    early_exit  boolean,
    is_safe     boolean default false
);

type t_agent is record ( id number, static_id varchar2(255) );
-- id preenchido para AI Agents de Shared Components; NULL para agentes ad hoc/programáticos

type t_chat_request is record (
    service_id            number,
    system_prompt         clob,
    messages              t_chat_messages,
    tools                 t_tools,
    temperature           number,
    response_json_schema  clob
);
type t_chat_request_handler_param  is record ( agent t_agent, invocation pls_integer );
type t_chat_request_handler_result is record ( request t_chat_request );

type t_chat_response is record (
    type           t_response_type,     -- 'complete' | 'error' | 'tool_calls'
    error          t_response_error,
    refusal        varchar2(32767),
    message        t_chat_message,
    input_tokens   number,
    output_tokens  number,
    total_tokens   number
);
type t_chat_response_handler_param is record (
    agent               t_agent,
    invocation          pls_integer,
    request             t_chat_request,
    pending_tool_calls  t_chat_message_tool_calls
);
type t_chat_response_handler_result is record (
    response    t_chat_response,
    messages    t_chat_messages,
    early_exit  boolean
);

type t_notification is record ( type t_notification_type, content varchar2(32767) );
type t_notifications is table of t_notification;
```

**Erros recuperáveis da resposta (`t_response_error`) e a exceção correspondente:**

| Constante | Valor | Exceção mapeada |
|---|---|---|
| `c_resp_err_content_filter` | `'content_filter'` | `e_content_filter` (filtro de conteúdo do provedor) |
| `c_resp_err_generic` | `'generic'` | `e_service_error` (quando nenhum tipo mais específico se aplica) |
| `c_resp_err_invalid_response` | `'invalid_response'` | `e_invalid_json_response` (JSON inválido) |
| `c_resp_err_invalid_tool_call` | `'invalid_tool_call'` | `e_invalid_json_tool_call` (payload de tool call inválido) |
| `c_resp_err_max_length` | `'max_length'` | `e_max_length` (modelo bateu no limite de tamanho) |
| `c_resp_err_refusal` | `'refusal'` | `e_refusal_filter` (modelo recusou) |

**Notificações (`t_notification_type`):** `c_notification_type_error` (`'error'`), `c_notification_type_generic` (`null`, sem severidade), `c_notification_type_info` (`'info'`), `c_notification_type_success` (`'success'`), `c_notification_type_warning` (`'warning'`).

**Pegadinhas**
- Na doc, o record `t_tool_exec_result` aparece sem vírgula entre `early_exit` e `is_safe`. É um erro tipográfico: os três campos existem.
- Os nomes de exceção (`e_content_filter` etc.) aparecem só na tabela de mapeamento da doc, sem declaração própria. Capture-os qualificados pelo package (`apex_ai.e_...`) só depois de conferir que compilam na sua instância. Na dúvida, use `when others` e registre `sqlerrm`.
- `name` da tool tem no máximo 64 caracteres. Por convenção vai em minúsculas com underscore e precisa começar com letra (ex.: `send_invoice`).

Fonte: [Constants and Data Types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AI.Data-Types.html), [Managing AI Agents and AI Tools](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-ai-agents-and-ai-tools.html)

### APEX_AI.GENERATE (Signature 1): gerar resposta a partir de um AI Agent

```sql
FUNCTION apex_ai.generate (
    p_agent_static_id              IN               VARCHAR2,
    p_prompt                       IN               CLOB,
    p_request_handler_procedure    IN               VARCHAR2        DEFAULT NULL,
    p_attachments                  IN               t_attachments   DEFAULT NULL )
    RETURN CLOB;
```

| Parâmetro | Descrição |
|---|---|
| `p_agent_static_id` | Static ID do AI Agent em Shared Components |
| `p_prompt` | Prompt do usuário |
| `p_request_handler_procedure` | Avançado. Procedure PL/SQL chamada para inspecionar ou alterar a requisição antes do envio ao provedor |
| `p_attachments` | Anexos opcionais. O suporte a cada tipo de arquivo depende do provedor e do modelo |

**Retorno:** a resposta (`CLOB`).

**Comportamento:**
- O serviço, o system prompt, a temperatura e as tools vêm do agente. As tools *Augment System Prompt* rodam a cada requisição. As *On Demand* só rodam quando o modelo as pede, e o APEX as executa automaticamente.
- Se o agente tem *Response Format* = **JSON Object**, o retorno é um JSON em texto. A partir do **Oracle AI Database 26ai**, o JSON recebido é validado automaticamente contra o JSON Schema do agente. Em versões anteriores do banco, a Oracle recomenda validar o JSON no código antes de usar.
- Agentes JSON Object hoje só funcionam via `APEX_AI` (não nas DAs de UI).

```sql
declare
    l_resumo clob;
begin
    l_resumo := apex_ai.generate(
        p_agent_static_id => 'resumidor_comunicados',
        p_prompt          => 'Resuma em 3 tópicos: ' || :P17_CORPO );
    :P17_RESUMO := l_resumo;
end;
```

Com anexo (por exemplo, extrair dados de um PDF enviado num *File Browse* gravado em `APEX_APPLICATION_TEMP_FILES`):

```sql
declare
    l_anexos apex_ai.t_attachments := apex_ai.t_attachments();
    l_json   clob;
begin
    for f in ( select blob_content, mime_type, filename
                 from apex_application_temp_files
                where name = :P21_ARQUIVO ) loop
        l_anexos.extend;
        l_anexos(l_anexos.last).mime_type    := f.mime_type;
        l_anexos(l_anexos.last).content_blob := f.blob_content;
        l_anexos(l_anexos.last).file_name    := f.filename;
        l_anexos(l_anexos.last).detail_level := apex_ai.c_detail_level_auto;
    end loop;

    l_json := apex_ai.generate(
        p_agent_static_id => 'extrator_certificado',   -- agente com Response Format = JSON Object
        p_prompt          => 'Extraia instituição, curso e data de conclusão.',
        p_attachments     => l_anexos );
end;
```

**Pegadinhas**
- Se você mudar o *Static ID* do agente, componentes declarativos dependentes continuam funcionando, mas as chamadas de API com o ID antigo precisam ser corrigidas à mão.
- Um agente em uso não pode ser excluído.

Fonte: [GENERATE Function Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AI.GENERATE-Function-Signature-1.html), [Managing AI Agents and AI Tools](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-ai-agents-and-ai-tools.html)

### APEX_AI.GENERATE (Signature 2): gerar resposta ad hoc com system prompt, JSON Schema, anexos e tools

```sql
FUNCTION apex_ai.generate (
    p_prompt                         IN   CLOB,
    p_system_prompt                  IN   CLOB             DEFAULT NULL,
    p_service_static_id              IN   VARCHAR2         DEFAULT NULL,
    p_temperature                    IN   NUMBER           DEFAULT NULL,
    p_attachments                    IN   t_attachments    DEFAULT NULL,
    p_response_json_schema           IN   CLOB             DEFAULT NULL,
    p_tools                          IN   t_tools          DEFAULT NULL,
    p_response_handler_procedure     IN   VARCHAR2         DEFAULT NULL,
    p_max_tool_roundtrips            IN   PLS_INTEGER      DEFAULT NULL )
    RETURN CLOB;
```

| Parâmetro | Descrição |
|---|---|
| `p_prompt` | Prompt do usuário |
| `p_system_prompt` | (Opcional) Papel, regras e comportamento da IA |
| `p_service_static_id` | Static ID do Generative AI Service. Se omitido, usa o serviço padrão da app |
| `p_temperature` | Temperatura. A interpretação e a faixa válida dependem do provedor; valores maiores dão respostas mais "criativas" |
| `p_attachments` | Anexos opcionais (suporte depende do provedor e do modelo) |
| `p_response_json_schema` | JSON Schema que o provedor deve seguir na resposta (modo JSON) |
| `p_tools` | Tools que o modelo pode chamar (*function calling*) para buscar dados ou disparar ações |
| `p_response_handler_procedure` | Avançado. Procedure que pós-processa as respostas do provedor (tool calls, respostas parciais) |
| `p_max_tool_roundtrips` | (Opcional) Limite de idas e voltas de rede para responder a tool calls |

**Retorno:** a resposta em `CLOB`. Em modo JSON, um JSON em texto.

**Exemplo 1: texto simples**

```sql
declare
    l_response clob;
begin
    l_response := apex_ai.generate(
        p_prompt            => 'O que é Oracle APEX?',
        p_system_prompt     => 'Você é especialista em plataformas low-code. Responda em pt-BR.',
        p_service_static_id => 'MY_AI_SERVICE' );
end;
```

**Exemplo 2: saída estruturada com JSON Schema**

```sql
declare
    l_response clob;
    l_obj      json_object_t;
begin
    l_response := apex_ai.generate(
        p_prompt               => 'Classifique este texto: ' || :P22_DESCRICAO,
        p_system_prompt        => 'Você classifica solicitações de RH.',
        p_service_static_id    => 'MY_AI_SERVICE',
        p_response_json_schema => q'~{
            "type": "object",
            "properties": {
                "categoria":  { "type": "string", "enum": ["CARGO","SALARIO","DADOS_PESSOAIS","OUTRO"] },
                "urgente":    { "type": "boolean" },
                "resumo":     { "type": "string" }
            },
            "required": ["categoria","urgente","resumo"],
            "additionalProperties": false
        }~' );

    l_obj := json_object_t.parse( l_response );   -- valide antes de confiar
    :P22_CATEGORIA := l_obj.get_string('categoria');
end;
```

**Exemplo 3: tool com `callback_procedure`.** Cada tool precisa de um `callback_procedure` com a procedure armazenada que trata a chamada. A assinatura da callback é fixa:

```sql
create or replace procedure convert_currency (
    p_param  in            apex_ai.t_tool_exec_param,
    p_result in out nocopy apex_ai.t_tool_exec_result )
as
begin
    p_result.result := to_char(
        my_pkg.convert_currency(
            p_amount => p_param.args_json.get_number( 'amount' ),
            p_from   => p_param.args_json.get_string( 'from_currency' ),
            p_to     => p_param.args_json.get_string( 'to_currency' ),
            p_date   => nvl( to_date( p_param.args_json.get_string( 'as_of_date' ), 'YYYY-MM-DD' ), sysdate ) ) );
end convert_currency;
/

declare
    l_response clob;
begin
    apex_session.create_session( p_app_id => 100, p_page_id => 1, p_username => 'USER' );

    l_response := apex_ai.generate(
        p_service_static_id => 'MY_AI_SERVICE',
        p_prompt            => 'How much is 100 USD in Euros?',
        p_tools             => apex_ai.t_tools(
            apex_ai.t_tool(
                name        => 'convert_currency',
                description => 'Converts money between currencies using an exchange rate for a given date (or latest available)',
                parameters  => apex_ai.t_tool_parameters(
                    apex_ai.t_tool_parameter( name => 'amount', data_type => apex_ai.c_tool_param_type_number ),
                    apex_ai.t_tool_parameter( name => 'from_currency', description => 'ISO 4217 code, e.g. "USD".' ),
                    apex_ai.t_tool_parameter( name => 'to_currency',   description => 'ISO 4217 code, e.g. "EUR".' ),
                    apex_ai.t_tool_parameter( name => 'as_of_date',
                                              description => 'Optional date YYYY-MM-DD.',
                                              is_required => false ) ),
                callback_procedure => 'convert_currency' ) ) );

    sys.dbms_output.put_line( l_response );
    apex_session.delete_session;
exception
    when others then
        apex_session.delete_session;
        raise;
end;
/
```

**Exemplo 4: response handler no lugar de callbacks.** O handler trata todas as tool calls pendentes e registra cada resultado com `SET_TOOL_RESULT` (Signature 2):

```sql
create or replace procedure response_handler_proc (
    p_param   in            apex_ai.t_chat_response_handler_param,
    p_result  in out nocopy apex_ai.t_chat_response_handler_result )
as
    l_result clob;
begin
    if p_result.response.type = apex_ai.c_response_type_tool_calls then
        for i in 1 .. p_param.pending_tool_calls.count loop
            if p_param.pending_tool_calls(i).name = 'convert_currency' then
                l_result := to_char( my_pkg.convert_currency(
                    p_amount => p_param.pending_tool_calls(i).args_json.get_number('amount'),
                    p_from   => p_param.pending_tool_calls(i).args_json.get_string('from_currency'),
                    p_to     => p_param.pending_tool_calls(i).args_json.get_string('to_currency'),
                    p_date   => sysdate ) );
            end if;
            apex_ai.set_tool_result(
                p_response_handler_param  => p_param,
                p_response_handler_result => p_result,
                p_tool_call               => p_param.pending_tool_calls(i),
                p_result                  => l_result );
        end loop;
    end if;
end response_handler_proc;
/
-- e na chamada: p_tools => (as mesmas tools, sem callback_procedure),
--               p_response_handler_procedure => 'response_handler_proc'
```

**Pegadinhas**
- Os parâmetros de tool sem `data_type` nos exemplos oficiais (`from_currency`, `to_currency`) são texto. Para não depender de padrão implícito, declare `c_tool_param_type_varchar2`.
- `is_required` é `boolean`. Os exemplos só o informam (`false`) para os parâmetros opcionais.
- Sem `p_max_tool_roundtrips`, o número de idas e voltas de tool fica a cargo do APEX e do provedor. Defina um teto quando as tools forem caras.
- Os argumentos chegam como JSON gerado pelo modelo (`args`/`args_json`). Valide tipo, faixa e permissão dentro da callback, e nunca concatene esses argumentos em SQL dinâmico.

Fonte: [GENERATE Function Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AI.GENERATE-Function-Signature-2.html)

### APEX_AI.CHAT (Signature 1): conversa com um AI Agent mantendo o histórico

```sql
APEX_AI.CHAT (
    p_agent_static_id           IN              VARCHAR2,
    p_prompt                    IN              CLOB,
    p_messages                  IN OUT NOCOPY   t_chat_messages,
    p_request_handler_procedure IN              VARCHAR2        default null )
    RETURN CLOB;
```

| Parâmetro | Descrição |
|---|---|
| `p_agent_static_id` | Static ID do AI Agent em Shared Components |
| `p_prompt` | Prompt do usuário |
| `p_messages` | Histórico da conversa. O prompt e a resposta são **acrescentados automaticamente**, o que permite encadear chamadas |
| `p_request_handler_procedure` | Procedure opcional para inspecionar ou alterar a requisição antes do envio |

**Retorno:** a resposta ao prompt.

```sql
declare
    l_messages  apex_ai.t_chat_messages := apex_ai.c_chat_messages;
    l_r1 clob;
    l_r2 clob;
begin
    l_r1 := apex_ai.chat(
        p_agent_static_id => 'my-oracle-assistant',
        p_prompt          => 'What is Oracle APEX',
        p_messages        => l_messages );
    l_r2 := apex_ai.chat(                       -- o contexto vem de l_messages
        p_agent_static_id => 'my-oracle-assistant',
        p_prompt          => 'What is new in the latest release',
        p_messages        => l_messages );
end;
```

**Pegadinhas**
- O histórico vive só na variável PL/SQL. Entre requisições de página (cada clique é uma chamada nova), você mesmo precisa persisti-lo (por exemplo, numa tabela ou coleção). Também precisa remontar o `t_chat_messages` com `chat_role` e `message` antes da próxima chamada.
- O histórico cresce a cada volta e é reenviado inteiro ao provedor, então o consumo de tokens aumenta. Corte as mensagens antigas quando necessário.

Fonte: [CHAT Function Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AI.CHAT-Function-Signature-1.html)

### APEX_AI.CHAT (Signature 2): conversa ad hoc com serviço, system prompt e tools

```sql
APEX_AI.CHAT (
    p_prompt                     IN              CLOB,
    p_system_prompt              IN              CLOB                DEFAULT NULL,
    p_service_static_id          IN              VARCHAR2            DEFAULT NULL,
    p_temperature                IN              NUMBER              DEFAULT NULL,
    p_messages                   IN OUT NOCOPY   t_chat_messages,
    p_tools                      IN              t_tools             DEFAULT NULL,
    p_response_handler_procedure IN              VARCHAR2            DEFAULT NULL,
    p_max_tool_roundtrips        IN              PLS_INTEGER         DEFAULT NULL )
    RETURN CLOB;
```

| Parâmetro | Descrição |
|---|---|
| `p_prompt` | Prompt do usuário |
| `p_system_prompt` | (Opcional) Papel e regras da IA |
| `p_service_static_id` | Static ID do serviço. Se omitido, usa o padrão da app |
| `p_temperature` | Temperatura (semântica do provedor) |
| `p_messages` | Histórico, atualizado automaticamente |
| `p_tools` | Tools disponíveis para *function calling* |
| `p_response_handler_procedure` | Pós-processamento das respostas (tool calls, parciais) |
| `p_max_tool_roundtrips` | Limite de idas e voltas para tool calls |

```sql
declare
    l_messages apex_ai.t_chat_messages := apex_ai.c_chat_messages;
    l_r1 clob;
    l_r2 clob;
begin
    l_r1 := apex_ai.chat(
        p_prompt            => 'O que é Oracle APEX?',
        p_system_prompt     => 'Sou especialista em plataformas low-code.',
        p_service_static_id => 'MY_AI_SERVICE',
        p_messages          => l_messages );
    l_r2 := apex_ai.chat(
        p_prompt            => 'O que há de novo na última versão?',
        p_service_static_id => 'MY_AI_SERVICE',
        p_messages          => l_messages );
end;
```

**Pegadinhas**
- O `p_system_prompt` só precisa ir na primeira chamada: o exemplo oficial o omite na segunda e mantém o contexto via `p_messages`.
- `CHAT` não tem `p_attachments` nem `p_response_json_schema`. Para anexos ou saída JSON, use `GENERATE`, ou acrescente anexos via campo `attachments` de um `t_chat_message`.
- **(Deprecated)** Signature 3: `apex_ai.chat(p_config_static_id, p_prompt, p_messages)`. Migre para a Signature 1 trocando o nome do parâmetro para `p_agent_static_id`.

Fonte: [CHAT Function Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AI.CHAT-Function-Signature-2.html), [CHAT Function Signature 3 (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AI.CHAT-Function-Signature-3.html)

### APEX_AI: assinaturas deprecated de GENERATE e CHAT (p_config_static_id)

```sql
APEX_AI.GENERATE ( p_config_static_id IN VARCHAR2, p_prompt IN CLOB ) RETURN CLOB;                       -- Signature 3
APEX_AI.CHAT ( p_config_static_id IN VARCHAR2, p_prompt IN CLOB,
               p_messages IN OUT NOCOPY t_chat_messages ) RETURN CLOB;                                  -- Signature 3
```

Ambas estão **deprecated** e serão removidas numa versão futura. O `p_config_static_id` é o static ID do AI Agent. Substitua por `GENERATE`/`CHAT` Signature 1 com `p_agent_static_id`, que também aceitam request handler (e, no `GENERATE`, anexos).

Fonte: [GENERATE Function Signature 3 (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AI.GENERATE-Function-Signature-3.html), [CHAT Function Signature 3 (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AI.CHAT-Function-Signature-3.html)

### APEX_AI.SET_TOOL_RESULT: resultado de tools declarativas e de response handlers

**Signature 1:** uso dentro do código de uma tool declarativa do AI Agent (*Execute Server-side Code* ou *Retrieve Data*).

```sql
PROCEDURE apex_ai.set_tool_result (
    p_result                 IN   CLOB                 DEFAULT NULL,
    p_notification_message   IN   VARCHAR2             DEFAULT NULL,
    p_notification_type      IN   t_notification_type  DEFAULT NULL,
    p_early_exit             IN   BOOLEAN              DEFAULT FALSE,
    p_is_safe                IN   BOOLEAN              DEFAULT FALSE );
```

| Parâmetro | Descrição |
|---|---|
| `p_result` | Resultado dinâmico. Só faz sentido em *Execute Server-side Code*, que por padrão devolve "success" ao modelo |
| `p_notification_message` | Substitui a mensagem de notificação declarativa da tool |
| `p_notification_type` | Substitui o tipo da notificação (`c_notification_type_*`) |
| `p_early_exit` | `TRUE` encerra o ciclo sem voltar ao AI Service depois da tool (economiza uma requisição) |
| `p_is_safe` | `TRUE` envia o resultado sem o invólucro de proteção contra *prompt injection*. Padrão `FALSE` |

```sql
-- dentro de uma tool "Execute Server-side Code" que envia e-mail
begin
    enviar_email(:P_DESTINO);
exception
    when others then
        apex_ai.set_tool_result(
            p_result               => 'Email could not be sent',
            p_notification_message => 'Não foi possível enviar o e-mail',
            p_notification_type    => apex_ai.c_notification_type_error,
            p_early_exit           => true );
end;
```

A doc recomenda, quando a ação falha, dar tanto a notificação visual quanto uma mensagem de resultado. Assim o histórico do chat fica consistente para as próximas requisições.

**Signature 2:** uso dentro de um response handler (`p_response_handler_procedure`).

```sql
PROCEDURE apex_ai.set_tool_result (
    p_response_handler_param     IN               t_chat_response_handler_param,
    p_response_handler_result    IN OUT NOCOPY    t_chat_response_handler_result,
    p_tool_call                  IN               t_chat_message_tool_call,
    p_result                     IN               CLOB,
    p_is_safe                    IN               BOOLEAN    DEFAULT FALSE );
```

Chame uma vez para cada item de `p_param.pending_tool_calls` quando `p_result.response.type = apex_ai.c_response_type_tool_calls` (ver o Exemplo 4 de `GENERATE`). Um exemplo mínimo da doc é uma tool `get_secret_number` sem parâmetros (`apex_ai.t_tool(name => 'get_secret_number')`), cujo handler responde `'42'`.

**Pegadinhas**
- Deixe `p_is_safe => false` (padrão) sempre que o resultado contiver texto vindo de usuários ou do banco. Só marque `TRUE` para valores controlados pelo seu código.
- Se o handler não registrar resultado para uma tool call pendente, a conversa fica sem resposta da tool. Responda a todas, mesmo com uma mensagem de erro.

Fonte: [SET_TOOL_RESULT Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AI.SET_TOOL_RESULT-Procedure-Signature-1.html), [SET_TOOL_RESULT Procedure Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AI.SET_TOOL_RESULT-Procedure-Signature-2.html)

### APEX_AI: tools declarativas do AI Agent (Retrieve Data, Execute Server-side Code, condições)

Resumo do que o Builder oferece para tools de um AI Agent, útil para decidir entre tool declarativa e `p_tools` em código:

- **Type:** *Retrieve Data*, *Execute Server-side Code* ou *Execute Client-side Code* (genéricas), além de plug-ins de Generative AI Tool criados em Shared Components.
- **Execution Point:** *Augment System Prompt* roda a cada nova mensagem e complementa o system prompt. *On Demand* só roda quando o modelo pede, e exige *Description* e *Parameters* (nome, descrição, data type, required, allowed values).
- **Retrieve Data, Settings > Type:** *SQL Query*, *Function Body* (retorna `CLOB`) ou *Static*. Com SQL Query existe *Maximum Tokens*: uma linha que estoure o restante do limite é descartada inteira. A conta de tokens é só uma estimativa.
- **User Approval > Requires Confirmation** (On Demand): o usuário aprova antes da execução.
- **Notification > Message / Type** (On Demand): o padrão declarativo que `SET_TOOL_RESULT` pode sobrescrever.
- **Server-Side Condition:** inclui *Any User Prompt contains* e *Last User Prompt contains* (lista de palavras separadas por vírgula). As binds `APEX$AI_LAST_USER_PROMPT` e `APEX$AI_ALL_USER_PROMPTS` dão acesso aos prompts.
- **Authorization Scheme:** a tool só roda ou fica disponível se a autorização der TRUE. Use em tools que acessam dados sensíveis.

Fonte: [Managing AI Agents and AI Tools](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-ai-agents-and-ai-tools.html)

### APEX_AI.GET_VECTOR_EMBEDDINGS: obter embeddings (Vector Provider, ONNX local ou função PL/SQL)

```sql
-- Signature 1: Vector Provider do workspace
APEX_AI.GET_VECTOR_EMBEDDINGS (
    p_value                 IN CLOB,
    p_service_static_id     IN VARCHAR2 )
    RETURN VECTOR;

-- Signature 2: modelo ONNX carregado no banco
APEX_AI.GET_VECTOR_EMBEDDINGS (
    p_value                 IN CLOB,
    p_local_llm_owner       IN VARCHAR2,
    p_local_llm_name        IN VARCHAR2 )
    RETURN VECTOR;

-- Signature 3: função PL/SQL própria
APEX_AI.GET_VECTOR_EMBEDDINGS (
    p_value                 IN CLOB,
    p_function_name         IN VARCHAR2 )
    RETURN VECTOR;
```

| Parâmetro | Descrição |
|---|---|
| `p_value` | Texto a converter em embedding |
| `p_service_static_id` | Static ID do **Vector Provider** (não do Generative AI Service) |
| `p_local_llm_owner` / `p_local_llm_name` | Owner e nome do modelo ONNX local |
| `p_function_name` | Função PL/SQL que recebe o texto como `VARCHAR2` e devolve `VECTOR` |

**Retorno:** o embedding (`VECTOR`).

```sql
declare
    l_vec vector;
begin
    l_vec := apex_ai.get_vector_embeddings(
        p_value             => 'Política de férias da empresa',
        p_service_static_id => 'MY_ONNX_VECTOR_PROVIDER' );

    update comunicado
       set embedding = l_vec
     where id_comunicado = :P11_ID
       and id_empresa    = :G_ID_EMPRESA;
end;
```

**Comportamento e uso:**
- Vector Providers ficam no workspace e são usados por todas as apps. Exigem **Oracle AI Database 26ai** ou posterior, assim como o tipo `VECTOR`.
- O embedding obtido serve para buscas semânticas e para configurar uma *Oracle Vector Search* (search configuration) baseada no Vector Provider.

**Pegadinhas**
- Gere o embedding dos documentos e o da consulta com o **mesmo** provider ou modelo. Vetores de modelos diferentes não são comparáveis.
- Na Signature 3, a função recebe `VARCHAR2` embora `p_value` seja `CLOB`, então textos longos podem não caber. Divida o texto antes.

Fonte: [GET_VECTOR_EMBEDDINGS Function Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AI.GET_VECTOR_EMBEDDINGS-Function-Signature-1.html), [GET_VECTOR_EMBEDDINGS Function Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AI.GET_VECTOR_EMBEDDINGS-Function-Signature-2.html), [GET_VECTOR_EMBEDDINGS Function Signature 3](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AI.GET_VECTOR_EMBEDDINGS-Function-Signature-3.html), [Managing Vector Providers](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-vector-providers.html)

### APEX_AI.GET_AVAILABLE_TOKENS e IS_ENABLED: checar cota de tokens e se a IA está habilitada

```sql
APEX_AI.GET_AVAILABLE_TOKENS (
    p_service_static_id     IN VARCHAR2    DEFAULT NULL )
RETURN NUMBER;

APEX_AI.IS_ENABLED
RETURN BOOLEAN;
```

**`GET_AVAILABLE_TOKENS`:**
- Devolve quantos tokens ainda podem ser consumidos antes de atingir o limite configurado, e **NULL se não houver limite**.
- Com `p_service_static_id`, vale para aquele serviço. Sem ele, vale para o serviço padrão da app atual. A doc também menciona o escopo do workspace atual, e o exemplo 2 da doc chama isso de "todos os serviços" mas imprime "default AI service". Trate a semântica sem parâmetro como "serviço padrão da app" e confira na sua instância.

**`IS_ENABLED`:** `TRUE` se os recursos de Generative AI estão habilitados para o workspace atual.

```sql
declare
    l_tokens number;
begin
    if not apex_ai.is_enabled then
        raise_application_error(-20001, 'IA desabilitada neste workspace.');
    end if;

    l_tokens := apex_ai.get_available_tokens( p_service_static_id => 'MY_AI_SERVICE' );
    if l_tokens is not null and l_tokens < 2000 then
        apex_error.add_error(
            p_message          => 'Cota de IA quase esgotada. Tente mais tarde.',
            p_display_location => apex_error.c_inline_in_notification );
    end if;
end;
```

Fonte: [GET_AVAILABLE_TOKENS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AI.GET_AVAILABLE_TOKENS-Function.html), [IS_ENABLED Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AI.IS_ENABLED-Function.html)

### APEX_AI: consentimento do usuário (IS_USER_CONSENT_NEEDED, SET_USER_CONSENT, REVOKE_USER_CONSENT, REVOKE_USER_CONSENT_FOR_ALL)

```sql
APEX_AI.IS_USER_CONSENT_NEEDED (
    p_user_name         IN  VARCHAR2    DEFAULT {the current user},
    p_application_id    IN  NUMBER      DEFAULT {the current application} )
    RETURN BOOLEAN;

APEX_AI.SET_USER_CONSENT (
    p_user_name         IN  VARCHAR2,
    p_application_id    IN  NUMBER );

APEX_AI.REVOKE_USER_CONSENT (
    p_user_name         IN  VARCHAR2,
    p_application_id    IN  NUMBER );

APEX_AI.REVOKE_USER_CONSENT_FOR_ALL (
    p_application_id    IN  NUMBER );
```

**Como funciona:**
- Em *Edit Application Definition > AI > Generative AI, Consent Message* você define um texto de consentimento. Na primeira vez que o usuário acessa o AI Service, o APEX mostra esse texto, e o usuário precisa aceitar antes de interagir.
- A escolha (Accept/Deny) fica gravada como **preferência de usuário**, então a pergunta aparece só uma vez.
- `IS_USER_CONSENT_NEEDED` retorna `TRUE` só se existir uma mensagem de consentimento **e** o usuário ainda não tiver consentido.
- `SET_USER_CONSENT` marca o consentimento (equivale a aceitar na UI).
- `REVOKE_USER_CONSENT` e `REVOKE_USER_CONSENT_FOR_ALL` apagam a preferência, para um usuário ou para todos os usuários da app. Isso força a pergunta de novo, por exemplo depois de mudar o texto ou o provedor.

```sql
-- após mudar o texto do termo de uso da IA, pedir consentimento a todos de novo
begin
    apex_ai.revoke_user_consent_for_all( p_application_id => 100 );
end;

-- em código que chama APEX_AI fora dos componentes com UI
begin
    if apex_ai.is_user_consent_needed then
        apex_error.add_error(
            p_message          => 'Aceite o termo de uso da IA antes de continuar.',
            p_display_location => apex_error.c_inline_in_notification );
        return;
    end if;
    -- ... apex_ai.generate(...)
end;
```

**Pegadinha:** `SET_USER_CONSENT` em nome do usuário pula o termo. Use apenas quando o aceite foi colhido por outro meio auditável.

Fonte: [IS_USER_CONSENT_NEEDED Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AI.IS_USER_CONSENT_NEEDED-Function.html), [SET_USER_CONSENT Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AI.SET_USER_CONSENT-Procedure.html), [REVOKE_USER_CONSENT Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AI.REVOKE_USER_CONSENT-Procedure.html), [REVOKE_USER_CONSENT_FOR_ALL Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AI.REVOKE_USER_CONSENT_FOR_ALL-Procedure.html), [Configuring AI Attributes for an Application](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-ai-attributes-for-an-application.html)

### APEX_AI falha fora de página (job, SQL Workshop, script) por falta de sessão APEX

**Sintoma:** `APEX_AI.GENERATE`/`CHAT` funciona num processo de página, mas dá erro num job do `DBMS_SCHEDULER`, num script SQL ou no SQL Commands.
**Causa:** o package exige uma sessão APEX válida, de onde vêm a app (serviço padrão, agentes), o workspace e o usuário.
**Correção:** envolva a chamada em `apex_session.create_session( p_app_id => ..., p_page_id => ..., p_username => ... )` e finalize com `apex_session.delete_session`, também no bloco `exception` (padrão dos exemplos oficiais). Para jobs recorrentes, prefira uma *Automation* da app, que já roda com contexto APEX.
**Prevenção:** encapsule as chamadas de IA num package que valide `apex_ai.is_enabled` e a existência de sessão.

Fonte: [APEX_AI](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AI.html), [GENERATE Function Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AI.GENERATE-Function-Signature-2.html)

### APEX_AI: chamada falha depois de importar a app em outro ambiente (credencial vazia)

**Sintoma:** depois de importar a app (ou instalar num novo workspace), as chamadas de IA falham na autenticação com o provedor.
**Causa:** o Generative AI Service guarda a chave como Web Credential, e o export da app **omite o segredo** da credencial.
**Correção:** depois do import, preencha o segredo da Web Credential manualmente (Workspace Utilities) ou por API, e use *Test Connection* no serviço.
**Prevenção:** inclua o passo "definir segredo da credencial de IA" no checklist de deploy. Nunca grave a chave em código ou em arquivo versionado.

Fonte: [Understanding Generative AI Support in APEX](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-generative-ai-support-in-apex.html), [Configuring a Generative AI Service](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configuring-generative-ai-service.html)

### APEX_AI.GENERATE com JSON: resposta não segue o schema ou JSON inválido

**Sintoma:** `json_object_t.parse` falha, ou faltam campos no JSON devolvido por `GENERATE`.
**Causa:** a validação automática contra o JSON Schema do agente só existe a partir do **Oracle AI Database 26ai**. Em versões anteriores do banco, o APEX não valida, e o modelo pode devolver JSON fora do formato. Erros de JSON também podem chegar como `c_resp_err_invalid_response` (`e_invalid_json_response`).
**Correção:** valide o JSON no código (parse e checagem dos campos `required`) antes de gravar ou usar. Use `"additionalProperties": false` e `required` no schema. Trate a exceção e ofereça "tentar de novo".
**Prevenção:** prefira um AI Agent com *Response Format* = JSON Object, ou `p_response_json_schema`, a pedir JSON só no prompt. Confira a versão do banco do ambiente antes de contar com a validação automática.

Fonte: [GENERATE Function Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AI.GENERATE-Function-Signature-1.html), [Constants and Data Types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AI.Data-Types.html)

### APEX_AI: p_service_static_id omitido usa outro serviço (ou nenhum)

**Sintoma:** uma chamada sem `p_service_static_id` usa um provedor inesperado ou falha por falta de serviço.
**Causa:** sem esse parâmetro, as assinaturas ad hoc usam o **serviço padrão da aplicação** (*Application Definition > AI*). *Default for New Apps* (no serviço) só pré-seleciona o serviço para apps novas, e *Used by App Builder* vale só para o Builder (APEX Assistant, wizards), não para a sua app. Só um serviço por workspace pode ter *Used by App Builder* ligado.
**Correção:** defina o serviço padrão da app, ou passe sempre `p_service_static_id` (ou use um AI Agent, que fixa o serviço).
**Prevenção:** centralize o static ID numa constante de package ou num agente.

Fonte: [Configuring AI Attributes for an Application](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-ai-attributes-for-an-application.html), [Understanding Generative AI Support in APEX](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-generative-ai-support-in-apex.html), [Editing a Generative AI Service](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-a-generative-as-service.html), [GENERATE Function Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AI.GENERATE-Function-Signature-2.html)


## 20. APEX_WORKFLOW: iniciar, controlar e consultar instâncias de Workflow

### APEX_WORKFLOW: propósito, quando usar e quando não usar

`APEX_WORKFLOW` é a API PL/SQL para gerenciar **instâncias** de Workflows definidos em *Shared Components > Workflows*: iniciar (`START_WORKFLOW`), suspender, retomar, repetir após falha, encerrar, continuar atividades que estão esperando (`CONTINUE_ACTIVITY`), ler e alterar variáveis, consultar listas de workflows (função *pipelined* `GET_WORKFLOWS`) e fazer limpeza.

- **Pré-requisitos:** exige **sessão APEX válida** (não funciona solta no SQL Workshop sem sessão; `GET_WORKFLOWS` não devolve linhas ali). O *parsing schema* da aplicação precisa do privilégio **`CREATE JOB`** para usar workflows e tarefas (Human Tasks).
- **Quando usar:** iniciar um workflow a partir de um processo de página, automação ou trigger lógico de negócio; montar painéis de "meus workflows"; tarefas administrativas (retry de falhados, limpeza de instâncias de desenvolvimento).
- **Quando não usar:** para lógica de aprovação simples com uma única pessoa decidindo, um *Human Task* (`APEX_HUMAN_TASK`) sozinho costuma bastar; para processamento em lote sem participantes humanos, uma *Automation* ou *Background Execution Chain* é mais leve.
- **Permissões:** várias operações (`RESUME` em sessão runtime-only, `UPDATE_VARIABLES`) exigem que o usuário seja *Workflow Administrator* (participante `ADMIN`). Use `IS_ALLOWED` antes de exibir botões de operação.
- **Estados:** `ACTIVE`, `SUSPENDED`, `FAULTED`, `WAITING`, `COMPLETED`, `TERMINATED`. Cada operação aceita só alguns estados de origem (tabela abaixo).

| Operação | Estados de origem aceitos |
|---|---|
| `SUSPEND` | `ACTIVE`, `FAULTED` |
| `RESUME` | `SUSPENDED` |
| `RETRY` | instância falhada (`FAULTED`); reexecuta a atividade onde a falha ocorreu |
| `TERMINATE` | `ACTIVE`, `SUSPENDED`, `FAULTED` |
| `UPDATE_VARIABLES` | `SUSPENDED`, `FAULTED` (e o usuário precisa ser admin) |
| `SET_ACTIVITY_DUE_DATE` | workflow em `FAULTED` ou `SUSPENDED` |
| `CONTINUE_ACTIVITY` | atividade em `WAITING` |

Fonte: [APEX_WORKFLOW](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WORKFLOW.html)

### APEX_WORKFLOW: referência completa de procedures, functions, constantes e tipos

| Item | Tipo | O que faz |
|---|---|---|
| `CONTINUE_ACTIVITY` (Signature 1: por `p_static_id`) | procedure | Continua o workflow numa atividade em `WAITING`, identificada pelo Static ID da atividade |
| `CONTINUE_ACTIVITY` (Signature 2: por `p_activity_instance_id`) | procedure | Igual, identificando a instância da atividade pelo ID |
| `DELETE_WORKFLOWS` | procedure | Remove instâncias de workflow de uma aplicação (limpeza; use com cuidado) |
| `GET_LOV_ACTIVITY_STATE` | function | Dados de LOV (`apex_t_temp_lov_data`) para o estado de instâncias de atividade |
| `GET_LOV_WORKFLOW_STATE` | function | Dados de LOV para o estado de instâncias de workflow |
| `GET_NEXT_PURGE_TIMESTAMP` | function | Timestamp da próxima execução do purge |
| `GET_VARIABLE_CLOB_VALUE` | function | Valor CLOB de uma variável (ou o VARCHAR2, se for desse tipo) |
| `GET_VARIABLE_VALUE` | function | Valor string de uma variável, aplicando a máscara de formato |
| `GET_WORKFLOW_STATE` | function | Estado atual da instância (`t_workflow_state`) |
| `GET_WORKFLOWS` | function pipelined | Lista workflows por contexto (`MY_WORKFLOWS`, `ADMIN_WORKFLOWS`, `INITIATED_BY_ME`, `SINGLE_WORKFLOW`) |
| `IS_ADMIN` | function | Usuário é Business Admin de ao menos um workflow da app? |
| `IS_ALLOWED` | function | Usuário pode executar a operação na instância? |
| `IS_OF_PARTICIPANT_TYPE` | function | Usuário é participante do tipo dado (`OWNER`/`ADMIN`)? |
| `REFRESH_PARTICIPANTS` | procedure | Recalcula os participantes da instância |
| `REMOVE_DEVELOPMENT_INSTANCES` | procedure | Remove instâncias criadas em modo DEV (iniciadas pelo App Builder) |
| `RESUME` | procedure | Retoma um workflow suspenso (opcionalmente numa atividade específica) |
| `RETRY` | procedure | Reexecuta um workflow falhado a partir da atividade com falha |
| `SET_ACTIVITY_DUE_DATE` | procedure | Muda a data de vencimento de uma atividade |
| `SET_LOG_LEVEL` | procedure | Define o nível de debug da instância (sobrepõe o da versão) |
| `START_WORKFLOW` | function | Inicia um workflow e devolve o ID da instância |
| `SUSPEND` | procedure | Suspende um workflow `ACTIVE`/`FAULTED` |
| `TERMINATE` | procedure | Encerra um workflow |
| `TERMINATE_FAULTED_WORKFLOWS` | procedure | Encerra todas as instâncias falhadas de uma aplicação |
| `UPDATE_VARIABLES` | procedure | Atualiza variáveis (só admin, só em `SUSPENDED`/`FAULTED`) |
| `c_workflow_system_user` | constante | `'system'` |
| `c_state_active` / `c_state_terminated` / `c_state_completed` / `c_state_faulted` / `c_state_suspended` / `c_state_waiting` | constantes `t_workflow_state` | Estados de workflow e de atividade |
| `c_workflow$_op_suspend` / `_resume` / `_retry` / `_update_var` / `_terminate` | constantes `t_workflow_operation` | Operações (`SUSPEND`, `RESUME`, `RETRY`, `UPDATE_VARIABLE`, `TERMINATE`) para `IS_ALLOWED` |
| `c_workflow_id`, `c_workflow_activity_id`, `c_workflow_initiator`, `c_workflow_state`, `c_workflow_detail_pk`, `c_workflow_created_on` | constantes | Nomes das substitution strings `APEX$WORKFLOW_ID`, `APEX$WORKFLOW_ACTIVITY_ID`, `APEX$WORKFLOW_INITIATOR`, `APEX$WORKFLOW_STATE`, `APEX$WORKFLOW_DETAIL_PK`, `APEX$WORKFLOW_CREATED_ON` |
| `c_activity_status_success` / `c_activity_status_failure` | constantes `t_activity_status` | Status de conclusão de atividade (`SUCCESS`/`FAILURE`) |
| `c_empty_workflow_parameters` | constante `t_workflow_parameters` | Coleção vazia (default de `p_parameters`) |
| `c_workflow_owner` / `c_workflow_admin` | constantes `t_workflow_participant_type` | `OWNER` / `ADMIN` |
| `c_context_my_workflows` / `c_context_admin_workflows` / `c_context_initiated_by_me` / `c_context_single_workflow` | constantes `t_workflow_list_context` | Contextos de `GET_WORKFLOWS` |
| `t_workflow_state` (varchar2(10)), `t_activity_status` (varchar2(15)), `t_workflow_participant_type` (varchar2(15)), `t_workflow_list_context` (varchar2(15)), `t_workflow_operation` (varchar2(30)) | subtypes | Tipos escalares |
| `t_workflow_parameter` | record | `static_id`, `value` (`apex_session_state.t_value`), `string_value` (**Deprecated**), `format_mask` |
| `t_workflow_parameters` | table of `t_workflow_parameter` index by pls_integer | Parâmetros/variáveis |
| `t_workflow_participant_types` | table index by pls_integer | Coleção de tipos de participante |

Fonte: [APEX_WORKFLOW](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WORKFLOW.html), [Constants and Data Types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WORKFLOW.Constants-and-Data-Types.html)

### APEX_WORKFLOW.START_WORKFLOW: iniciar uma instância de workflow com parâmetros

```sql
APEX_WORKFLOW.START_WORKFLOW (
    p_application_id  IN NUMBER                      DEFAULT apex_application.g_flow_id,
    p_static_id       IN VARCHAR2,
    p_parameters      IN t_workflow_parameters       DEFAULT c_empty_workflow_parameters,
    p_initiator       IN VARCHAR2                    DEFAULT NULL,
    p_detail_pk       IN VARCHAR2                    DEFAULT NULL,
    p_debug_level     IN apex_debug_api.t_log_level  DEFAULT NULL )
RETURN NUMBER;
```

| Parâmetro | Descrição |
|---|---|
| `p_application_id` | Aplicação dona da definição (default: a app corrente) |
| `p_static_id` | Static ID da definição do workflow |
| `p_parameters` | Parâmetros do workflow; o `static_id` de cada um precisa casar com o parâmetro definido no workflow |
| `p_initiator` | (Opcional) quem iniciou |
| `p_detail_pk` | (Opcional) chave primária do registro de detalhe (disponível como `APEX$WORKFLOW_DETAIL_PK`) |
| `p_debug_level` | (Opcional) nível de log da instância |

**Retorno:** ID da nova instância. Inicia sempre a versão ativa da definição.

**Pegadinha:** o campo `string_value` do record `t_workflow_parameter` está **Deprecated**; prefira `value` (tipo `apex_session_state.t_value`). O exemplo oficial ainda usa `string_value` e índices não contíguos (1, 3, 4, 5), o que é aceito por ser `index by pls_integer`.

```sql
declare
    l_workflow_id number;
begin
    l_workflow_id := apex_workflow.start_workflow (
        p_static_id   => 'REQUISITIONWORKFLOW',
        p_detail_pk   => :P10_REQ_ID,
        p_parameters  => apex_workflow.t_workflow_parameters(
            1 => apex_workflow.t_workflow_parameter(static_id => 'REQ_AMOUNT', string_value => :P10_AMOUNT),
            2 => apex_workflow.t_workflow_parameter(static_id => 'REQ_ITEM',   string_value => :P10_ITEM)),
        p_debug_level => apex_debug_api.c_log_level_info );
end;
```

Fonte: [START_WORKFLOW Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WORKFLOW.START_WORKFLOW-Function.html)

### APEX_WORKFLOW.CONTINUE_ACTIVITY: retomar uma atividade em espera (WAITING) com resultado

Duas sobrecargas: a atividade é identificada pelo Static ID ou pelo ID da instância da atividade.

```sql
APEX_WORKFLOW.CONTINUE_ACTIVITY (
    p_instance_id      IN NUMBER,
    p_static_id        IN VARCHAR2,
    p_activity_params  IN wwv_flow_global.vc_map,
    p_activity_status  IN t_activity_status DEFAULT c_activity_status_success );

APEX_WORKFLOW.CONTINUE_ACTIVITY (
    p_instance_id          IN NUMBER,
    p_activity_instance_id IN NUMBER,
    p_activity_params      IN wwv_flow_global.vc_map,
    p_activity_status      IN t_activity_status DEFAULT c_activity_status_success );
```

- A atividade precisa estar em `WAITING` (ex.: uma atividade que aguarda um evento externo ou uma tarefa).
- `p_activity_params` é um mapa nome→valor; as chaves que coincidirem com variáveis do workflow **atualizam essas variáveis** antes de o fluxo avançar.
- `p_activity_status` = `SUCCESS` (default) ou `FAILURE` (`c_activity_status_failure`), o que influencia o caminho seguido.

```sql
declare
    l_params apex_global.vc_map;
begin
    l_params('TASK_OUTCOME') := 'APPROVED';
    apex_workflow.continue_activity(
        p_instance_id     => 1234,
        p_static_id       => 'REQUEST_LEAVE_APPROVAL',
        p_activity_params => l_params);
end;
```

**Pegadinha:** o exemplo oficial declara `l_activity_params` mas atribui em `l_activity_result`, o que não compila. Use a mesma variável nas duas linhas, como acima.

Fonte: [CONTINUE_ACTIVITY Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WORKFLOW.CONTINUE_ACTIVITY-Procedure-Signature-1.html), [CONTINUE_ACTIVITY Procedure Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WORKFLOW.CONTINUE_ACTIVITY-Procedure-Signature-2.html)

### APEX_WORKFLOW: controlar o ciclo de vida (SUSPEND, RESUME, RETRY, TERMINATE, TERMINATE_FAULTED_WORKFLOWS)

```sql
APEX_WORKFLOW.SUSPEND   ( p_instance_id IN NUMBER );
APEX_WORKFLOW.RESUME    ( p_instance_id IN NUMBER, p_activity_static_id IN VARCHAR2 DEFAULT NULL );
APEX_WORKFLOW.RETRY     ( p_instance_id IN NUMBER );
APEX_WORKFLOW.TERMINATE ( p_instance_id IN NUMBER );
APEX_WORKFLOW.TERMINATE_FAULTED_WORKFLOWS ( p_application_id IN NUMBER );
```

- `SUSPEND`: só instâncias `ACTIVE` ou `FAULTED`.
- `RESUME`: só instâncias `SUSPENDED`. Com `p_activity_static_id` nulo retoma na atividade corrente; informando o Static ID, retoma naquela atividade. Em sessão *runtime-only*, só Workflow Administrators podem retomar.
- `RETRY`: para instância falhada; reexecuta a atividade onde ocorreu a falha (corrija a causa antes, por exemplo com `UPDATE_VARIABLES`).
- `TERMINATE`: instâncias `ACTIVE`, `SUSPENDED` ou `FAULTED`.
- `TERMINATE_FAULTED_WORKFLOWS`: encerra todas as falhadas de uma aplicação.

Padrão para consertar uma instância falhada:

```sql
begin
    -- 1) corrigir o dado que causou a falha (exige admin; estado FAULTED/SUSPENDED)
    apex_workflow.update_variables(
        p_instance_id    => 1234,
        p_changed_params => apex_workflow.t_workflow_parameters(
            1 => apex_workflow.t_workflow_parameter(static_id => 'NEW_SALARY', string_value => '2,560.50')));
    -- 2) reexecutar a atividade que falhou
    apex_workflow.retry(p_instance_id => 1234);
end;
```

Fonte: [SUSPEND Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WORKFLOW.SUSPEND-Procedure.html), [RESUME Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WORKFLOW.RESUME-Procedure.html), [RETRY Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WORKFLOW.RETRY-Procedure.html), [TERMINATE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WORKFLOW.TERMINATE-Procedure.html), [TERMINATE_FAULTED_WORKFLOWS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WORKFLOW.TERMINATE_FAULTED_WORKFLOWS-Procedure.html)

### APEX_WORKFLOW: ler e alterar variáveis (GET_VARIABLE_VALUE, GET_VARIABLE_CLOB_VALUE, UPDATE_VARIABLES, GET_WORKFLOW_STATE)

```sql
APEX_WORKFLOW.GET_VARIABLE_VALUE (
    p_instance_id        IN NUMBER,
    p_variable_static_id IN VARCHAR2 ) RETURN VARCHAR2;

APEX_WORKFLOW.GET_VARIABLE_CLOB_VALUE (
    p_instance_id        IN NUMBER,
    p_variable_static_id IN VARCHAR2 ) RETURN CLOB;

APEX_WORKFLOW.UPDATE_VARIABLES (
    p_instance_id    IN NUMBER,
    p_changed_params IN t_workflow_parameters );

APEX_WORKFLOW.GET_WORKFLOW_STATE (
    p_instance_id IN NUMBER ) RETURN t_workflow_state;
```

- `GET_VARIABLE_VALUE` aplica a máscara de formato da variável. Para variável CLOB maior que o limite de VARCHAR2, a doc diz que é levantada exceção (quando `p_raise` está ligado, embora esse parâmetro não apareça na assinatura publicada).
- `GET_VARIABLE_CLOB_VALUE` devolve o CLOB, o VARCHAR2 se a variável for VARCHAR2, e `NULL` para outros tipos.
- `UPDATE_VARIABLES`: só para Workflow Administrator e instância `SUSPENDED`/`FAULTED`; a máscara da variável é aplicada ao valor informado.

```sql
declare
    l_state  apex_workflow.t_workflow_state;
    l_resp   clob;
begin
    l_state := apex_workflow.get_workflow_state(p_instance_id => 1234);
    if l_state = apex_workflow.c_state_faulted then
        l_resp := apex_workflow.get_variable_clob_value(1234, 'REST_RESPONSE');
        apex_debug.info('Resposta: %s', dbms_lob.substr(l_resp, 200, 1));
    end if;
end;
```

Fonte: [GET_VARIABLE_VALUE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WORKFLOW.GET_VARIABLE_VALUE-Function.html), [GET_VARIABLE_CLOB_VALUE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WORKFLOW.GET_VARIABLE_CLOB_VALUE-Function.html), [UPDATE_VARIABLES Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WORKFLOW.UPDATE_VARIABLES-Procedure.html), [GET_WORKFLOW_STATE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WORKFLOW.GET_WORKFLOW_STATE-Function.html)

### APEX_WORKFLOW.GET_WORKFLOWS: listar workflows do usuário em relatórios (função pipelined)

```sql
APEX_WORKFLOW.GET_WORKFLOWS (
    p_context        IN VARCHAR2 DEFAULT apex_workflow_api.c_context_my_workflows,
    p_user           IN VARCHAR2 DEFAULT apex_security.g_user,
    p_workflow_id    IN NUMBER   DEFAULT NULL,
    p_application_id IN NUMBER   DEFAULT NULL )
RETURN apex_t_workflow_instances pipelined;
```

- `p_context`: `MY_WORKFLOWS` (default), `ADMIN_WORKFLOWS`, `INITIATED_BY_ME` (usam `p_user`) ou `SINGLE_WORKFLOW` (usa `p_workflow_id`).
- `p_application_id` nulo = todas as aplicações.
- Só retorna dados dentro de uma sessão APEX válida (em SQL Workshop volta vazio).
- Colunas: `badge_css_classes`, `badge_state`, `badge_text`, `created_ago`, `created_ago_hours`, `created_by`, `created_on`, `duration_seconds`, `end_time`, `initiator`, `initiator_lower`, `is_completed`, `is_dev_mode`, `is_terminated`, `last_updated_by`, `last_updated_on`, `parent_activity_id`, `parent_id`, `start_time`, `state`, `state_code`, `tenant_id`, `title`, `workflow_def_app_id`, `workflow_def_app_name`, `workflow_def_id`, `workflow_def_name`, `workflow_def_static_id`, `workflow_id`, `workflow_version`, `workflow_version_id`.

```sql
select workflow_id, title, state, badge_css_classes, created_ago
  from table ( apex_workflow.get_workflows (
                   p_context        => 'INITIATED_BY_ME',
                   p_application_id => :APP_ID ) )
 order by created_on desc
```

LOVs prontas para filtros de estado: `select disp, val from table(apex_workflow.get_lov_workflow_state)` e `get_lov_activity_state` (retornam `apex_t_temp_lov_data`).

Fonte: [GET_WORKFLOWS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WORKFLOW.GET_WORKFLOWS-Function.html), [GET_LOV_WORKFLOW_STATE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WORKFLOW.GET_LOV_WORKFLOW_STATE-Function.html), [GET_LOV_ACTIVITY_STATE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WORKFLOW.GET_LOV_ACTIVITY_STATE-Function.html)

### APEX_WORKFLOW: checar permissões e participantes (IS_ADMIN, IS_ALLOWED, IS_OF_PARTICIPANT_TYPE, REFRESH_PARTICIPANTS)

```sql
APEX_WORKFLOW.IS_ADMIN (
    p_user           IN VARCHAR2 DEFAULT apex_security.g_user,
    p_application_id IN NUMBER   DEFAULT NULL ) RETURN BOOLEAN;

APEX_WORKFLOW.IS_ALLOWED (
    p_instance_id IN NUMBER,
    p_operation   IN wwv_flow_workflow_api.t_workflow_operation,
    p_user        IN VARCHAR2 DEFAULT wwv_flow_security.g_user ) RETURN BOOLEAN;

APEX_WORKFLOW.IS_OF_PARTICIPANT_TYPE (
    p_instance_id      IN NUMBER,
    p_participant_type IN t_workflow_participant_type,
    p_user             IN VARCHAR2 ) RETURN BOOLEAN;

APEX_WORKFLOW.REFRESH_PARTICIPANTS ( p_instance_id IN NUMBER );
```

- `IS_ADMIN`: TRUE se o usuário é *Business Admin* de pelo menos um workflow; sem `p_application_id`, considera todas as apps do workspace.
- `IS_ALLOWED`: use como *Server-side Condition* de botões (Suspender, Retomar, Encerrar).
- `REFRESH_PARTICIPANTS`: reavalia owners/admins (útil quando a regra de participantes depende de dados que mudaram).

**Pegadinha:** as constantes de operação estão declaradas como `c_workflow$_op_suspend` etc., mas o exemplo oficial usa `apex_workflow.c_workflow_op_suspend`. Confira o nome na sua instância (`describe apex_workflow`) ou passe o literal (`'SUSPEND'`).

```sql
-- Server-side Condition (PL/SQL Function Body returning Boolean) do botão "Suspender"
return apex_workflow.is_allowed(
           p_instance_id => :P30_WORKFLOW_ID,
           p_operation   => 'SUSPEND');
```

Fonte: [IS_ADMIN Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WORKFLOW.IS_ADMIN-Function.html), [IS_ALLOWED Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WORKFLOW.IS_ALLOWED-Function.html), [IS_OF_PARTICIPANT_TYPE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WORKFLOW.IS_OF_PARTICIPANT_TYPE-Function.html), [REFRESH_PARTICIPANTS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WORKFLOW.REFRESH_PARTICIPANTS-Procedure.html)

### APEX_WORKFLOW: due date, log e limpeza (SET_ACTIVITY_DUE_DATE, SET_LOG_LEVEL, DELETE_WORKFLOWS, REMOVE_DEVELOPMENT_INSTANCES, GET_NEXT_PURGE_TIMESTAMP)

```sql
APEX_WORKFLOW.SET_ACTIVITY_DUE_DATE (
    p_instance_id        IN NUMBER,
    p_activity_static_id IN VARCHAR2,
    p_due_date           IN TIMESTAMP WITH TIME ZONE );

APEX_WORKFLOW.SET_LOG_LEVEL (
    p_instance_id IN NUMBER,
    p_debug_level IN apex_debug_api.t_log_level );

PROCEDURE apex_workflow.delete_workflows (
    p_application_id       IN NUMBER           DEFAULT apex_application.g_flow_id,
    p_static_id            IN VARCHAR2         DEFAULT NULL,
    p_states               IN apex_t_varchar2  DEFAULT NULL,
    p_include_all_versions IN BOOLEAN          DEFAULT FALSE );

APEX_WORKFLOW.REMOVE_DEVELOPMENT_INSTANCES (
    p_application_id IN NUMBER   DEFAULT apex_application.g_flow_id,
    p_static_id      IN VARCHAR2 DEFAULT NULL );

APEX_WORKFLOW.GET_NEXT_PURGE_TIMESTAMP RETURN timestamp with time zone;
```

- `SET_ACTIVITY_DUE_DATE`: o workflow precisa estar `FAULTED` ou `SUSPENDED`.
- `SET_LOG_LEVEL`: valores 1 (`c_log_level_error`), 2 (`warn`), 4 (`info`), 5 (`enter`), 6 (`app_trace`) de `apex_debug_api`; sobrepõe o nível da versão do workflow.
- `DELETE_WORKFLOWS`: só para limpeza de dados. Com `p_include_all_versions => FALSE` (default) apaga só instâncias de versões **inativas**; `p_states` filtra por estado.
- `REMOVE_DEVELOPMENT_INSTANCES`: apaga instâncias iniciadas em modo DEV pelo App Builder.

```sql
begin
  apex_workflow.delete_workflows(
    p_application_id       => 100,
    p_states               => apex_t_varchar2(apex_workflow.c_state_faulted,
                                              apex_workflow.c_state_terminated),
    p_include_all_versions => true);
end;
```

Fonte: [SET_ACTIVITY_DUE_DATE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WORKFLOW.SET_ACTIVITY_DUE_DATE-Procedure.html), [SET_LOG_LEVEL Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WORKFLOW.SET_LOG_LEVEL-Procedure.html), [DELETE_WORKFLOWS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WORKFLOW.DELETE_WORKFLOWS-Procedure.html), [REMOVE_DEVELOPMENT_INSTANCES Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WORKFLOW.REMOVE_DEVELOPMENT_INSTANCES-Procedure.html), [GET_NEXT_PURGE_TIMESTAMP Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WORKFLOW.GET_NEXT_PURGE_TIMESTAMP-Function.html)

### Workflow não inicia ou falha ao criar jobs (privilégio CREATE JOB ausente)

**Sintoma:** workflows ou tarefas não são processados/iniciados na aplicação.
**Causa:** o *parsing schema* da aplicação não tem o privilégio `CREATE JOB`, exigido por workflows e Human Tasks.
**Correção:** como DBA, `grant create job to <schema>;`.
**Prevenção:** inclua o grant no script de provisionamento do schema.

Fonte: [APEX_WORKFLOW](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WORKFLOW.html)

### APEX_WORKFLOW.GET_WORKFLOWS não retorna linhas no SQL Workshop

**Sintoma:** `select * from table(apex_workflow.get_workflows)` volta vazio no SQL Workshop ou numa sessão SQL comum.
**Causa:** a função só retorna dados no contexto de uma sessão APEX válida (usuário e app definidos).
**Correção:** teste dentro da aplicação (região de relatório) ou crie uma sessão com `apex_session.create_session` antes da consulta.

Fonte: [GET_WORKFLOWS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WORKFLOW.GET_WORKFLOWS-Function.html)


## 21. APEX_HUMAN_TASK: criar e operar Human Tasks (aprovações e ações)

### APEX_HUMAN_TASK: propósito, quando usar e quando não usar

`APEX_HUMAN_TASK` é a API das *Task Definitions* (Shared Components > Task Definitions) e da *Unified Task List*. Permite criar instâncias de tarefa (`CREATE_TASK`), agir sobre elas (aprovar, rejeitar, concluir, assumir, liberar, delegar, pedir/enviar informação, cancelar, renovar), alterar prioridade, prazo, parâmetros e participantes, consultar listas (`GET_TASKS`, pipelined) e histórico, e checar permissões.

- **Pré-requisitos:** sessão APEX válida; o *parsing schema* precisa do privilégio **`CREATE JOB`** (vale para workflows e tasks). `GET_TASKS`, `GET_TASK_HISTORY`, `GET_TASK_DELEGATES` e `GET_TASK_PRIORITIES` só retornam dados dentro de uma sessão APEX (vazias no SQL Workshop).
- **Tipos de tarefa:** `APPROVAL` (tem *outcome* `APPROVED`/`REJECTED`) e `ACTION` (só concluída).
- **Participantes:** `POTENTIAL_OWNER`, `BUSINESS_ADMIN`, `INITIATOR`, `INFO_REQUESTED_FROM`, `EXCLUDED_OWNER`, `EXCLUDED_ADMIN`. Identidade: `USER` (`ADD_TASK_POTENTIAL_OWNER` só aceita `USER` nesta versão) e `AUTH`.
- **Quando usar:** aprovação de solicitações (férias, correções de cadastro, compras) por uma pessoa ou grupo, com caixa de entrada pronta (*Unified Task List*), prazos, expiração e histórico. Também como atividade *Human Task* dentro de um Workflow.
- **Quando não usar:** processos sem pessoa decidindo (automations), ou fluxos multi-etapas com ramificações, onde o Workflow orquestra e a tarefa é só uma atividade.
- **Substitui `APEX_APPROVAL`**, que está deprecated (ver seção 22).

**Estados e transições principais**

| Estado | Significado | Como chega / sai |
|---|---|---|
| `UNASSIGNED` | vários potential owners; ninguém assumiu | `CREATE_TASK` com >1 owner; `RELEASE_TASK` → aqui; `CLAIM_TASK` → `ASSIGNED` |
| `ASSIGNED` | tem actual owner | `CREATE_TASK` com 1 owner; `CLAIM_TASK`; `DELEGATE_TASK` |
| `INFO_REQUESTED` | owner pediu informação | `REQUEST_MORE_INFORMATION`; volta com `SUBMIT_INFORMATION` |
| `COMPLETED` | concluída (com outcome em aprovações) | `APPROVE_TASK`, `REJECT_TASK`, `COMPLETE_TASK`; sujeita a purge/arquivo |
| `CANCELLED` | cancelada | `CANCEL_TASK` (não vale para `COMPLETED`/`ERRORED`) |
| `EXPIRED` / `ERRORED` / `FAILED` | prazo vencido / erro | `RENEW_TASK` (admin) cria nova tarefa ligada à antiga |

Fonte: [APEX_HUMAN_TASK](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.html), [Constants and Data Types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.Constants-and-Data-Types.html)

### APEX_HUMAN_TASK: referência completa de procedures e functions

| Item | Tipo | Quem pode / o que faz |
|---|---|---|
| `ADD_TASK_COMMENT` | procedure | Potential owner ou business admin adiciona comentário |
| `ADD_TASK_POTENTIAL_OWNER` | procedure | Business admin adiciona potential owner (erro se `COMPLETED`/`ERRORED`) |
| `ADD_TO_HISTORY` | procedure | Grava entrada no histórico da tarefa (usar no código de *Task Actions*) |
| `APPROVE_TASK` | procedure | Owner/potential owner aprova (= `COMPLETE_TASK` com `APPROVED`) |
| `CANCEL_TASK` | procedure | Initiator ou business admin cancela |
| `CLAIM_TASK` | procedure | Potential owner assume tarefa `UNASSIGNED` |
| `COMPLETE_TASK` | procedure | Conclui com outcome opcional |
| `CREATE_TASK` | function | Cria a tarefa e devolve o ID |
| `DELEGATE_TASK` | procedure | Actual owner ou business admin atribui a outro potential owner |
| `DELETE_TASKS` | procedure | Limpeza de instâncias (com cautela) |
| `EXCLUDE_POTENTIAL_OWNER` | procedure | Business admin exclui um potential owner |
| `GET_LOV_PRIORITY` | function pipelined | LOV de prioridades |
| `GET_LOV_STATE` | function pipelined | LOV de estados |
| `GET_LOV_TYPE` | function | LOV de tipos de tarefa |
| `GET_NEXT_PURGE_TIMESTAMP` | function | Próximo purge |
| `GET_TASK_DELEGATES` | function pipelined | Possíveis novos owners (exclui o atual) |
| `GET_TASK_HISTORY` | function pipelined | Log/histórico da tarefa |
| `GET_TASK_PARAMETER_OLD_VALUE` | function | Valor anterior de um parâmetro alterado nesta sessão |
| `GET_TASK_PARAMETER_VALUE` | function | Valor de um parâmetro (em SQL ou PL/SQL) |
| `GET_TASK_PRIORITIES` | function pipelined | Prioridades possíveis (exclui a atual) |
| `GET_TASKS` | function pipelined | Lista por contexto (`MY_TASKS`, `ADMIN_TASKS`, `INITIATED_BY_ME`, `SINGLE_TASK`) |
| `HANDLE_TASK_DEADLINES` | procedure | Processa prazos/expiração agora (o job faz isso de hora em hora) |
| `HAS_TASK_PARAM_CHANGED` | function | Parâmetro foi alterado nesta sessão? |
| `IS_ALLOWED` | function | Usuário pode executar a operação? |
| `IS_BUSINESS_ADMIN` | function | Usuário é business admin de ao menos uma definição? |
| `IS_OF_PARTICIPANT_TYPE` | function | Usuário é potential owner/business admin da tarefa? |
| `REFRESH_BUSINESS_ADMINS` | procedure | Recalcula business admins |
| `REJECT_TASK` | procedure | Rejeita (= `COMPLETE_TASK` com `REJECTED`) |
| `RELEASE_TASK` | procedure | Actual owner devolve para `UNASSIGNED` |
| `REMOVE_POTENTIAL_OWNER` | procedure | Business admin remove potential owner |
| `RENEW_TASK` | function | Business admin renova tarefa `EXPIRED`/`ERRORED` (cria nova) |
| `REQUEST_MORE_INFORMATION` | procedure | Actual owner pede informação ao initiator (ou outro usuário) |
| `SET_INITIATOR_CAN_COMPLETE` | procedure | Business admin muda se o initiator pode concluir |
| `SET_TASK_DUE` | procedure | Business admin muda o prazo (precisa ser futuro) |
| `SET_TASK_PARAMETER_VALUES` | procedure | Business admin ou owner altera parâmetros marcados *updatable* |
| `SET_TASK_PRIORITY` | procedure | Business admin ou initiator muda prioridade |
| `SUBMIT_INFORMATION` | procedure | Initiator responde ao pedido de informação |

Fonte: [APEX_HUMAN_TASK](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.html)

### APEX_HUMAN_TASK: constantes e tipos (estados, outcomes, operações, prioridades, t_task_parameters)

| Grupo | Constantes |
|---|---|
| Tipos de tarefa | `c_task_type_approval` = `'APPROVAL'`, `c_task_type_action` = `'ACTION'` |
| Contextos de lista | `c_context_my_tasks`, `c_context_admin_tasks`, `c_context_initiated_by_me`, `c_context_single_task` |
| Participantes | `c_task_potential_owner`, `c_task_business_admin`, `c_task_initiator`, `c_task_info_requested_from`, `c_task_excluded_owner`, `c_task_excluded_admin` |
| Identidade | `c_task_identity_type_user` = `'USER'`, `c_task_identity_type_auth` = `'AUTH'` |
| Prioridade | `c_task_priority_urgent` = 1, `_high` = 2, `_medium` = 3, `_low` = 4, `_lowest` = 5 |
| Estados | `c_task_state_unassigned`, `_assigned`, `_completed`, `_cancelled`, `_failed`, `_errored`, `_expired`, `_info_requested` |
| Outcomes | `c_task_outcome_approved` = `'APPROVED'`, `c_task_outcome_rejected` = `'REJECTED'` |
| Operações (para `IS_ALLOWED`) | `c_task_op_approve`, `_reject`, `_complete`, `_claim`, `_delegate`, `_renew`, `_release`, `_cancel`, `_set_priority`, `_add_comment`, `_add_owner`, `_request_info`, `_submit_info`, `_set_due_date`, `_remove_owner`, `_set_params`, `c_task_op_initiator_can_comp`, `c_task_op_exclude_owner`, `c_task_op_refresh_b_admin` |
| Data | `c_canonical_date_format` = `'YYYYMMDDHH24MISS'` |
| Default | `c_empty_task_parameters` |

Tipos: subtypes `t_task_participant_type` (varchar2(15)), `t_task_identity_type` (32), `t_task_type` (32), `t_task_outcome` (32), `t_task_state` (15), `t_task_operation` (30), `t_task_list_context` (15).

```sql
type t_task_parameter is record (
    static_id    varchar2(32767),   -- deve casar com o parâmetro da Task Definition
    string_value varchar2(32767) );
type t_task_parameters is table of t_task_parameter index by pls_integer;
```

*Vacation rules* (regras de ausência, que trocam participantes): entrada `t_vacation_rule_input` (`task_def_static_id`, `task_id`, `priority`, `original_participants`, `parameters`, `due_date`, `detail_pk`) e saída `t_vacation_rule_result` (`has_participant_changes`, `participant_changes` do tipo `t_task_participant_changes`, com registros `old_participant`/`new_participant`/`change_reason`).

**Pegadinhas:** o estado é escrito `CANCELLED` na constante, embora o texto da doc use "CANCELED". O exemplo de `SET_TASK_PRIORITY` usa `c_task_priority_highest`, que não existe na lista; a prioridade máxima é `c_task_priority_urgent` (1).

Fonte: [Constants and Data Types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.Constants-and-Data-Types.html)

### APEX_HUMAN_TASK.CREATE_TASK: criar uma tarefa de aprovação ou ação

```sql
APEX_HUMAN_TASK.CREATE_TASK (
    p_application_id         IN NUMBER                   DEFAULT apex_application.g_flow_id,
    p_task_def_static_id     IN VARCHAR2,
    p_subject                IN VARCHAR2                 DEFAULT NULL,
    p_parameters             IN t_task_parameters        DEFAULT c_empty_task_parameters,
    p_priority               IN INTEGER                  DEFAULT NULL,
    p_initiator              IN VARCHAR2                 DEFAULT NULL,
    p_initiator_can_complete IN BOOLEAN                  DEFAULT NULL,
    p_detail_pk              IN VARCHAR2                 DEFAULT NULL,
    p_due_date               IN TIMESTAMP WITH TIME ZONE DEFAULT NULL )
RETURN NUMBER;
```

| Parâmetro | Descrição |
|---|---|
| `p_task_def_static_id` | Static ID da Task Definition |
| `p_subject` | Assunto exibido na task list |
| `p_parameters` | Parâmetros da definição (`static_id` + `string_value`) |
| `p_priority` | 1–5; nulo usa a prioridade da definição |
| `p_initiator` | Quem iniciou (nulo: usuário corrente, conforme a definição) |
| `p_initiator_can_complete` | Se o initiator pode aprovar/concluir; nulo usa a definição |
| `p_detail_pk` | PK do registro de negócio (usada na página de detalhes) |
| `p_due_date` | Sobrepõe o prazo da definição |

**Comportamento:** com um único potential owner a tarefa nasce `ASSIGNED`; com vários, `UNASSIGNED` (qualquer um pode assumir). **Exceção** se a definição não resolver nenhum potential owner.

```sql
declare
    l_task_id number;
begin
    insert into solicitacao_correcao (id_empresa, id_colaborador, descricao)
    values (:G_ID_EMPRESA, :P22_ID_COLABORADOR, :P22_DESCRICAO)
    returning id into :P22_ID;

    l_task_id := apex_human_task.create_task(
        p_task_def_static_id     => 'CORRECAO_CADASTRO',
        p_subject                => 'Correção de cadastro #' || :P22_ID,
        p_detail_pk              => :P22_ID,
        p_initiator_can_complete => false,
        p_parameters             => apex_human_task.t_task_parameters(
            1 => apex_human_task.t_task_parameter(static_id => 'DESCRICAO',
                                                  string_value => :P22_DESCRICAO)));
end;
```

(Tabela, Static ID e itens do exemplo são ilustrativos.)

Fonte: [CREATE_TASK Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.CREATE_TASK-Function.html)

### APEX_HUMAN_TASK: concluir tarefas (APPROVE_TASK, REJECT_TASK, COMPLETE_TASK)

```sql
APEX_HUMAN_TASK.APPROVE_TASK (
    p_task_id   IN NUMBER,
    p_autoclaim IN BOOLEAN DEFAULT FALSE );

APEX_HUMAN_TASK.REJECT_TASK (
    p_task_id   IN NUMBER,
    p_autoclaim IN BOOLEAN DEFAULT FALSE );

APEX_HUMAN_TASK.COMPLETE_TASK (
    p_task_id   IN NUMBER,
    p_outcome   IN t_task_outcome DEFAULT NULL,
    p_autoclaim IN BOOLEAN        DEFAULT FALSE );
```

- Quem pode: actual owner ou potential owner.
- Pré-estado `ASSIGNED`; ou `UNASSIGNED` quando `p_autoclaim => TRUE` (assume implicitamente). Pós-estado `COMPLETED`.
- `APPROVE_TASK`/`REJECT_TASK` são atalhos de `COMPLETE_TASK` com `c_task_outcome_approved`/`c_task_outcome_rejected`. Para tarefas `ACTION`, use `COMPLETE_TASK` sem outcome.
- Concluída, a tarefa passa a ser elegível a purge/arquivamento.

```sql
begin
    apex_human_task.approve_task(p_task_id => :P23_TASK_ID, p_autoclaim => true);
end;
```

**Pegadinha:** a página de `APPROVE_TASK` cita a constante como `apex_approval.c_task_outcome_approved` (package deprecated); use `apex_human_task.c_task_outcome_approved`.

Fonte: [APPROVE_TASK Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.APPROVE_TASK-Procedure.html), [REJECT_TASK Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.REJECT_TASK-Procedure.html), [COMPLETE_TASK Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.COMPLETE_TASK-Procedure.html)

### APEX_HUMAN_TASK: atribuição (CLAIM_TASK, RELEASE_TASK, DELEGATE_TASK, GET_TASK_DELEGATES)

```sql
APEX_HUMAN_TASK.CLAIM_TASK   ( p_task_id IN NUMBER );                       -- UNASSIGNED -> ASSIGNED
APEX_HUMAN_TASK.RELEASE_TASK ( p_task_id IN NUMBER );                       -- ASSIGNED -> UNASSIGNED
APEX_HUMAN_TASK.DELEGATE_TASK( p_task_id IN NUMBER, p_to_user IN VARCHAR2 ); -- UNASSIGNED/ASSIGNED -> ASSIGNED
APEX_HUMAN_TASK.GET_TASK_DELEGATES ( p_task_id IN NUMBER )
    RETURN wwv_flow_t_temp_lov_data pipelined;
```

- `CLAIM_TASK`: só potential owners; o actual owner passa a ser quem assumiu.
- `RELEASE_TASK`: só o actual owner.
- `DELEGATE_TASK`: actual owner ou business admin; o destino deve ser um participante (use `GET_TASK_DELEGATES` como LOV, que já exclui o owner atual).

```sql
-- LOV de delegação
select disp, val from table(apex_human_task.get_task_delegates(p_task_id => :P23_TASK_ID))
```

Fonte: [CLAIM_TASK Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.CLAIM_TASK-Procedure.html), [RELEASE_TASK Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.RELEASE_TASK-Procedure.html), [DELEGATE_TASK Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.DELEGATE_TASK-Procedure.html), [GET_TASK_DELEGATES Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.GET_TASK_DELEGATES-Function.html)

### APEX_HUMAN_TASK: pedir e enviar informação (REQUEST_MORE_INFORMATION, SUBMIT_INFORMATION, ADD_TASK_COMMENT, ADD_TO_HISTORY)

```sql
APEX_HUMAN_TASK.REQUEST_MORE_INFORMATION (
    p_task_id IN NUMBER,
    p_text    IN VARCHAR2,
    p_to_user IN VARCHAR2 DEFAULT NULL );

APEX_HUMAN_TASK.SUBMIT_INFORMATION (
    p_task_id IN NUMBER,
    p_text    IN VARCHAR2 );

APEX_HUMAN_TASK.ADD_TASK_COMMENT (
    p_task_id IN NUMBER,
    p_text    IN VARCHAR2 );

APEX_HUMAN_TASK.ADD_TO_HISTORY (
    p_message IN VARCHAR2 );
```

- `REQUEST_MORE_INFORMATION`: chamada pelo actual owner; a tarefa vai para `INFO_REQUESTED` e é endereçada ao initiator, ou a `p_to_user` se informado. O owner só volta a agir depois do `SUBMIT_INFORMATION`.
- `ADD_TASK_COMMENT`: potential owners e business admins.
- `ADD_TO_HISTORY`: para uso dentro do código das *Task Actions* (binds = colunas da *action source query*).

**Pegadinha:** o exemplo oficial de `ADD_TASK_COMMENT` chama `add_task_comment(...)` sem o prefixo do package; qualifique como `apex_human_task.add_task_comment`.

Fonte: [REQUEST_MORE_INFORMATION Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.REQUEST_MORE_INFORMATION-Procedure.html), [SUBMIT_INFORMATION Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.SUBMIT_INFORMATION-Procedure.html), [ADD_TASK_COMMENT Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.ADD_TASK_COMMENT-Procedure.html), [ADD_TO_HISTORY Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.ADD_TO_HISTORY-Procedure.html)

### APEX_HUMAN_TASK.GET_TASKS: caixa de entrada de tarefas em relatórios (função pipelined)

```sql
APEX_HUMAN_TASK.GET_TASKS (
    p_context            IN VARCHAR2 DEFAULT apex_human_task.c_context_my_tasks,
    p_user               IN VARCHAR2 DEFAULT apex_application.g_user,
    p_task_id            IN NUMBER   DEFAULT NULL,
    p_application_id     IN NUMBER   DEFAULT NULL,
    p_show_expired_tasks IN VARCHAR2 DEFAULT 'N' )
RETURN apex_t_approval_tasks pipelined;
```

- `MY_TASKS`: tarefas em que o usuário é owner ou potential owner; `ADMIN_TASKS`: é business admin; `INITIATED_BY_ME`: é initiator; `SINGLE_TASK`: a tarefa `p_task_id`.
- `p_show_expired_tasks => 'Y'` inclui `EXPIRED`.
- Colunas: `actual_owner`, `actual_owner_lower`, `app_id`, `badge_css_classes`, `badge_text`, `created_ago`, `created_ago_hours`, `created_by`, `created_on`, `detail_pk`, `details_app_id`, `details_app_name`, `details_link_target`, `due_code`, `due_in`, `due_in_hours`, `due_on`, `initiator`, `initiator_can_complete`, `initiator_lower`, `is_completed`, `last_updated_by`, `last_updated_on`, `outcome`, `outcome_code`, `priority`, `priority_level`, `state`, `state_code`, `subject`, `task_def_id`, `task_def_name`, `task_def_static_id`, `task_id`, `task_type`, `tenant_id`.

```sql
select task_id, subject, state, priority_level, due_in, details_link_target
  from table(apex_human_task.get_tasks(
                 p_context        => apex_human_task.c_context_my_tasks,
                 p_application_id => :APP_ID))
 order by priority, due_on
```

Outras pipelined úteis: `GET_TASK_HISTORY(p_task_id, p_include_all => 'N')` (retorna `apex_t_approval_log`; com `'Y'` inclui tarefas ligadas, como as expiradas que foram renovadas), `GET_TASK_PRIORITIES(p_task_id)` e as LOVs `GET_LOV_PRIORITY`, `GET_LOV_STATE`, `GET_LOV_TYPE`.

**Pegadinha:** o exemplo oficial de `GET_TASK_HISTORY` escreve `apex_human_error.get_task_history`; o correto é `apex_human_task.get_task_history`.

Fonte: [GET_TASKS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.GET_TASKS-Function.html), [GET_TASK_HISTORY Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.GET_TASK_HISTORY-Function.html), [GET_TASK_PRIORITIES Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.GET_TASK_PRIORITIES-Function.html), [GET_LOV_PRIORITY Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.GET_LOV_PRIORITY-Function.html), [GET_LOV_STATE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.GET_LOV_STATE-Function.html), [GET_LOV_TYPE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.GET_LOV_TYPE-Function.html)

### APEX_HUMAN_TASK: parâmetros da tarefa (GET_TASK_PARAMETER_VALUE, SET_TASK_PARAMETER_VALUES, HAS_TASK_PARAM_CHANGED, GET_TASK_PARAMETER_OLD_VALUE)

```sql
APEX_HUMAN_TASK.GET_TASK_PARAMETER_VALUE (
    p_task_id          IN NUMBER,
    p_param_static_id  IN VARCHAR2,
    p_ignore_not_found IN BOOLEAN DEFAULT FALSE ) RETURN VARCHAR2;

APEX_HUMAN_TASK.SET_TASK_PARAMETER_VALUES (
    p_task_id     IN NUMBER,
    p_parameters  IN t_task_parameters,
    p_raise_error IN BOOLEAN DEFAULT TRUE );

APEX_HUMAN_TASK.HAS_TASK_PARAM_CHANGED (
    p_task_id         IN NUMBER,
    p_param_static_id IN VARCHAR2 ) RETURN BOOLEAN;

APEX_HUMAN_TASK.GET_TASK_PARAMETER_OLD_VALUE (
    p_task_id         IN NUMBER,
    p_param_static_id IN VARCHAR2,
    p_raise_error     IN BOOLEAN DEFAULT TRUE );   -- retorna VARCHAR2
```

- `GET_TASK_PARAMETER_VALUE`: `no_data_found` se o parâmetro não existir e `p_ignore_not_found = FALSE`; com `TRUE`, devolve `NULL`. Pode ser usada em SQL.
- `SET_TASK_PARAMETER_VALUES`: só altera parâmetros marcados como *updatable* na definição; business admin ou owner. Com `p_raise_error => TRUE` (default) qualquer erro cancela tudo; com `FALSE`, ignora static IDs inválidos/não atualizáveis e atualiza o resto.
- `HAS_TASK_PARAM_CHANGED` (NULL se o parâmetro não existe) e `GET_TASK_PARAMETER_OLD_VALUE` (`No Data Found` se não existir e `p_raise_error`) referem-se a mudanças **na sessão atual**, úteis em Task Actions do evento de atualização de parâmetros.

```sql
select t.task_id, t.subject,
       apex_human_task.get_task_parameter_value(t.task_id, 'DESCRICAO', p_ignore_not_found => true) descricao
  from table(apex_human_task.get_tasks(p_context => 'ADMIN_TASKS')) t
```

Fonte: [GET_TASK_PARAMETER_VALUE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.GET_TASK_PARAMETER_VALUE-Function.html), [SET_TASK_PARAMETER_VALUES Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.SET_TASK_PARAMETER_VALUES-Procedure.html), [HAS_TASK_PARAM_CHANGED Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.HAS_TASK_PARAM_CHANGED-Function.html), [GET_TASK_PARAMETER_OLD_VALUE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.GET_TASK_PARAMETER_OLD_VALUE-Function.html)

### APEX_HUMAN_TASK: prioridade, prazo, cancelamento e renovação (SET_TASK_PRIORITY, SET_TASK_DUE, CANCEL_TASK, RENEW_TASK, HANDLE_TASK_DEADLINES, SET_INITIATOR_CAN_COMPLETE)

```sql
APEX_HUMAN_TASK.SET_TASK_PRIORITY ( p_task_id IN NUMBER, p_priority IN INTEGER );
APEX_HUMAN_TASK.SET_TASK_DUE      ( p_task_id IN NUMBER, p_due_date IN timestamp with time zone );
APEX_HUMAN_TASK.CANCEL_TASK       ( p_task_id IN NUMBER );
APEX_HUMAN_TASK.RENEW_TASK (
    p_task_id  IN NUMBER,
    p_priority IN INTEGER DEFAULT NULL,
    p_due_date IN timestamp with time zone ) RETURN NUMBER;
APEX_HUMAN_TASK.HANDLE_TASK_DEADLINES;
APEX_HUMAN_TASK.SET_INITIATOR_CAN_COMPLETE (
    p_task_id                IN NUMBER,
    p_initiator_can_complete IN BOOLEAN );
```

| Rotina | Quem | Restrições |
|---|---|---|
| `SET_TASK_PRIORITY` | business admin ou initiator | 1 (mais alta) a 5; não em `COMPLETED`/`ERRORED` |
| `SET_TASK_DUE` | business admin | não em `EXPIRED`/`ERRORED`/`COMPLETED`/`CANCELLED`; data no futuro, senão exceção |
| `CANCEL_TASK` | initiator ou business admin | não em `COMPLETED`/`ERRORED`; vai para `CANCELLED` |
| `RENEW_TASK` | business admin | só `EXPIRED`/`ERRORED`; cria nova tarefa associada e retorna o novo ID |
| `SET_INITIATOR_CAN_COMPLETE` | business admin | não em `COMPLETED`/`ERRORED` |
| `HANDLE_TASK_DEADLINES` | — | processa prazos de todas as tarefas do workspace (um job faz isso de hora em hora); use para testar políticas de expiração e as ações *Before Expire*/*Expire* |

```sql
declare
    l_new_id number;
begin
    l_new_id := apex_human_task.renew_task(
                    p_task_id  => 1234,
                    p_priority => apex_human_task.c_task_priority_high,
                    p_due_date => systimestamp + interval '10' day);
end;
```

Fonte: [SET_TASK_PRIORITY Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.SET_TASK_PRIORITY-Procedure.html), [SET_TASK_DUE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.SET_TASK_DUE-Procedure.html), [CANCEL_TASK Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.CANCEL_TASK-Procedure.html), [RENEW_TASK Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.RENEW_TASK-Function.html), [HANDLE_TASK_DEADLINES Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.HANDLE_TASK_DEADLINES-Procedure.html), [SET_INITIATOR_CAN_COMPLETE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.SET_INITIATOR_CAN_COMPLETE-Procedure.html)

### APEX_HUMAN_TASK: participantes e permissões (ADD_TASK_POTENTIAL_OWNER, REMOVE_POTENTIAL_OWNER, EXCLUDE_POTENTIAL_OWNER, REFRESH_BUSINESS_ADMINS, IS_ALLOWED, IS_BUSINESS_ADMIN, IS_OF_PARTICIPANT_TYPE)

```sql
APEX_HUMAN_TASK.ADD_TASK_POTENTIAL_OWNER (
    p_task_id         IN NUMBER,
    p_potential_owner IN VARCHAR2,
    p_identity_type   IN t_task_identity_type default c_task_identity_type_user );
APEX_HUMAN_TASK.REMOVE_POTENTIAL_OWNER  ( p_task_id IN NUMBER, p_potential_owner IN VARCHAR2 );
APEX_HUMAN_TASK.EXCLUDE_POTENTIAL_OWNER ( p_task_id IN NUMBER, p_potential_owner IN VARCHAR2 );
APEX_HUMAN_TASK.REFRESH_BUSINESS_ADMINS ( p_task_id IN NUMBER );

APEX_HUMAN_TASK.IS_ALLOWED (
    p_task_id         IN NUMBER,
    p_operation       IN wwv_flow_approval_api.t_task_operation,
    p_user            IN VARCHAR2 DEFAULT wwv_flow_security.g_user,
    p_new_participant IN VARCHAR2 DEFAULT NULL ) RETURN BOOLEAN;
APEX_HUMAN_TASK.IS_BUSINESS_ADMIN (
    p_user           IN VARCHAR2 DEFAULT wwv_flow_security.g_user,
    p_application_id IN NUMBER   DEFAULT NULL ) RETURN BOOLEAN;
APEX_HUMAN_TASK.IS_OF_PARTICIPANT_TYPE (
    p_task_id          IN NUMBER,
    p_participant_type IN t_task_participant_type DEFAULT c_task_potential_owner,
    p_user             IN VARCHAR2 DEFAULT wwv_flow_security.g_user ) RETURN BOOLEAN;
```

- Adicionar/remover/excluir owners: só business admin; `ADD_`/`EXCLUDE_` falham em tarefa `COMPLETED`/`ERRORED`; `REMOVE_` levanta exceção se o usuário não for potential owner.
- `REFRESH_BUSINESS_ADMINS`: não pode em `EXPIRED`, `ERRORED`, `COMPLETED` ou `CANCELLED`.
- `IS_ALLOWED`: use com as constantes `c_task_op_*`; para `DELEGATE` informe `p_new_participant`. Ideal como condição de botões.
- `IS_BUSINESS_ADMIN`: bom para um *Authorization Scheme* que libera a visão administrativa da task list.

```sql
-- Authorization Scheme "Administrador de tarefas" (PL/SQL Function Returning Boolean)
return apex_human_task.is_business_admin(p_application_id => :APP_ID);
```

**Pegadinha:** o exemplo oficial de `IS_ALLOWED` esquece a vírgula depois de `p_operation`.

Fonte: [ADD_TASK_POTENTIAL_OWNER Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.ADD_TASK_POTENTIAL_OWNER-Procedure.html), [REMOVE_POTENTIAL_OWNER Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.REMOVE_POTENTIAL_OWNER-Procedure.html), [EXCLUDE_POTENTIAL_OWNER Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.EXCLUDE_POTENTIAL_OWNER-Procedure.html), [REFRESH_BUSINESS_ADMINS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.REFRESH_BUSINESS_ADMINS-Procedure.html), [IS_ALLOWED Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.IS_ALLOWED-Function.html), [IS_BUSINESS_ADMIN Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.IS_BUSINESS_ADMIN-Function.html), [IS_OF_PARTICIPANT_TYPE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.IS_OF_PARTICIPANT_TYPE-Function.html)

### APEX_HUMAN_TASK: limpeza (DELETE_TASKS, GET_NEXT_PURGE_TIMESTAMP)

```sql
PROCEDURE apex_human_task.delete_tasks (
    p_application_id         IN NUMBER          DEFAULT apex_application.g_flow_id,
    p_static_id              IN VARCHAR2        DEFAULT NULL,
    p_states                 IN apex_t_varchar2 DEFAULT NULL,
    p_include_workflow_tasks IN BOOLEAN         DEFAULT FALSE );

APEX_HUMAN_TASK.GET_NEXT_PURGE_TIMESTAMP RETURN timestamp with time zone;
```

Por padrão (`p_include_workflow_tasks => FALSE`) `DELETE_TASKS` não apaga tarefas criadas por workflows. Use só como limpeza de dados.

```sql
begin
  apex_human_task.delete_tasks(
    p_application_id         => 100,
    p_states                 => apex_t_varchar2(apex_human_task.c_task_state_cancelled,
                                                apex_human_task.c_task_state_errored),
    p_include_workflow_tasks => true);
end;
```

Fonte: [DELETE_TASKS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.DELETE_TASKS-Procedure.html), [GET_NEXT_PURGE_TIMESTAMP Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.GET_NEXT_PURGE_TIMESTAMP-Function.html)

### APEX_HUMAN_TASK.CREATE_TASK levanta exceção "no potential owners"

**Sintoma:** `CREATE_TASK` falha ao criar a tarefa.
**Causa:** a Task Definition não resolveu nenhum potential owner (a consulta/expressão de participantes voltou vazia para os dados informados).
**Correção:** revise a definição de participantes (*Participants*) da Task Definition e os parâmetros passados; garanta ao menos um `POTENTIAL_OWNER`.

Fonte: [CREATE_TASK Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.CREATE_TASK-Function.html)

### APEX_HUMAN_TASK.SET_TASK_DUE levanta exceção ao alterar o prazo

**Sintoma:** erro ao chamar `SET_TASK_DUE`.
**Causa:** a data informada não está no futuro, a tarefa está `EXPIRED`/`ERRORED`/`COMPLETED`/`CANCELLED`, ou o usuário não é business admin.
**Correção:** passe um timestamp futuro; para tarefas expiradas use `RENEW_TASK`.

Fonte: [SET_TASK_DUE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.SET_TASK_DUE-Procedure.html)


## 22. APEX_APPROVAL (Deprecated): API antiga de tarefas, substituída por APEX_HUMAN_TASK

### APEX_APPROVAL (Deprecated): o que é e por que não usar em código novo

`APEX_APPROVAL` é o nome antigo da API de tarefas humanas e aprovações. **Todo o package está deprecated** e será removido numa versão futura; a doc manda usar **`APEX_HUMAN_TASK`** no lugar. As rotinas têm os mesmos nomes e, quase sempre, as mesmas assinaturas, então a migração é trocar o prefixo `apex_approval.` por `apex_human_task.` (inclusive nas constantes, como `c_task_outcome_approved`).

Diferenças relevantes encontradas na doc 26.1:

| Ponto | `APEX_APPROVAL` (deprecated) | `APEX_HUMAN_TASK` |
|---|---|---|
| `REQUEST_MORE_INFORMATION` | só `p_task_id`, `p_text` (sempre vai para o initiator) | também `p_to_user` (redireciona para outro usuário) |
| Rotinas exclusivas da nova API | — | `DELETE_TASKS`, `EXCLUDE_POTENTIAL_OWNER`, `GET_LOV_TYPE`, `REFRESH_BUSINESS_ADMINS` |
| Default de `p_user` em `IS_ALLOWED`/`IS_BUSINESS_ADMIN` | `apex_application.g_user` | `wwv_flow_security.g_user` |
| `GET_TASK_HISTORY` | retorna `apex_t_approval_log_table` | retorna `wwv_flow_t_approval_log_table` |

**Prevenção:** ao achar `apex_approval.` em código legado (processos, Task Actions, relatórios com `table(apex_approval.get_tasks)`), migre para `apex_human_task.`.

Fonte: [APEX_APPROVAL (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPROVAL.html), [REQUEST_MORE_INFORMATION Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/REQUEST_MORE_INFORMATION-Procedure.html)

### APEX_APPROVAL (Deprecated): referência completa de procedures, functions, constantes e tipos

Todas as linhas abaixo são **(Deprecated)**; o equivalente tem o mesmo nome em `APEX_HUMAN_TASK` (seção 21).

| Item | Tipo | O que faz |
|---|---|---|
| Constants and Data Types | constantes/tipos | Mesmos grupos de `APEX_HUMAN_TASK`: tipos de tarefa, contextos, participantes, prioridades, estados, outcomes, operações, `t_task_parameter(s)` |
| `ADD_TASK_COMMENT` | procedure | Adiciona comentário |
| `ADD_TASK_POTENTIAL_OWNER` | procedure | Adiciona potential owner (business admin) |
| `ADD_TO_HISTORY` | procedure | Grava no histórico (código de Task Action) |
| `APPROVE_TASK` | procedure | Aprova (`p_task_id`, `p_autoclaim DEFAULT FALSE`) |
| `CANCEL_TASK` | procedure | Cancela |
| `CLAIM_TASK` | procedure | Assume tarefa `UNASSIGNED` |
| `COMPLETE_TASK` | procedure | Conclui (`p_outcome` obrigatório em aprovações; ações não têm outcome) |
| `CREATE_TASK` | function | Cria tarefa (mesma assinatura de `APEX_HUMAN_TASK.CREATE_TASK`) |
| `DELEGATE_TASK` | procedure | Delega a outro potential owner |
| `GET_LOV_PRIORITY` | function pipelined | LOV de prioridades |
| `GET_LOV_STATE` | function pipelined | LOV de estados |
| `GET_NEXT_PURGE_TIMESTAMP` | function | Próximo purge |
| `GET_TASK_DELEGATES` | function pipelined | Possíveis delegados |
| `GET_TASK_HISTORY` | function pipelined | Histórico (`apex_t_approval_log_table`) |
| `GET_TASK_PARAMETER_OLD_VALUE` | function | Valor anterior na sessão |
| `GET_TASK_PARAMETER_VALUE` | function | Valor de parâmetro |
| `GET_TASK_PRIORITIES` | function pipelined | Prioridades possíveis |
| `GET_TASKS` | function pipelined | Lista por contexto (default `apex_approval.c_context_my_tasks`) |
| `HANDLE_TASK_DEADLINES` | procedure | Processa prazos agora |
| `HAS_TASK_PARAM_CHANGED` | function | Parâmetro mudou nesta sessão? |
| `IS_ALLOWED` | function | Pode executar a operação? |
| `IS_BUSINESS_ADMIN` | function | É business admin? |
| `IS_OF_PARTICIPANT_TYPE` | function | É do tipo de participante? |
| `REJECT_TASK` | procedure | Rejeita |
| `RELEASE_TASK` | procedure | Libera para `UNASSIGNED` |
| `REMOVE_POTENTIAL_OWNER` | procedure | Remove potential owner |
| `RENEW_TASK` | function | Renova tarefa expirada/errada |
| `REQUEST_MORE_INFORMATION` | procedure | Pede informação ao initiator (sem `p_to_user`) |
| `SET_INITIATOR_CAN_COMPLETE` | procedure | Muda se o initiator pode concluir |
| `SET_TASK_DUE` | procedure | Muda prazo |
| `SET_TASK_PARAMETER_VALUES` | procedure | Altera parâmetros *updatable* |
| `SET_TASK_PRIORITY` | procedure | Muda prioridade |
| `SUBMIT_INFORMATION` | procedure | Initiator envia a informação pedida |

Exemplo de migração:

```sql
-- antes (deprecated)
apex_approval.complete_task(p_task_id => l_id, p_outcome => apex_approval.c_task_outcome_rejected);
-- depois
apex_human_task.complete_task(p_task_id => l_id, p_outcome => apex_human_task.c_task_outcome_rejected);
```

Fonte: [APEX_APPROVAL (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPROVAL.html), [Constants and Data Types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPROVAL.Constants-and-Data-Types.html), [COMPLETE_TASK Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/COMPLETE_TASK-Procedure.html), [GET_TASKS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_TASKS-Function.html)


## 23. APEX_BACKGROUND_PROCESS: status, progresso e término de Execution Chains em background

### APEX_BACKGROUND_PROCESS: propósito, quando usar e quando não usar

`APEX_BACKGROUND_PROCESS` serve para processos de página que rodam **em background** (uma *Execution Chain* marcada para executar em segundo plano). Com ele o código do processo informa **status** e **progresso** ao motor do APEX, e a página (ou um administrador) pode consultar o andamento de uma execução e **terminar** execuções à força.

- **Quando usar:** importações grandes, geração de relatórios pesados, chamadas REST em lote; qualquer processamento que não deva prender a requisição HTTP do usuário. O processo reporta progresso com `SET_PROGRESS`/`SET_STATUS` e a página consulta com `GET_EXECUTION`.
- **Quando não usar:** processamento recorrente agendado (use *Automations*) ou fluxos com etapas humanas (use *Workflow*/*Human Task*).
- **Ciclo de vida da execução (`t_execution_state`):** `ENQUEUED` (submetida, o job coordenador ainda não pegou) → `SCHEDULED` (o coordenador criou o job executor no DBMS_SCHEDULER, mas ele ainda não começou) → `EXECUTING` → `SUCCESS`, `FAILED` (erro não tratado) ou `ABORTED` (terminada).
- `SET_PROGRESS` e `SET_STATUS` só fazem sentido dentro de código PL/SQL que roda na execução em background.

Fonte: [APEX_BACKGROUND_PROCESS](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/apex_background_process.html), [Constants](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_BACKGROUND_PROCESS-Constants.html)

### APEX_BACKGROUND_PROCESS: referência completa de procedures, functions, constantes e tipos

| Item | Tipo | O que faz |
|---|---|---|
| `ABORT` Signature 1 (`p_process_id`) **(Deprecated)** | procedure | Abortava todas as execuções de uma chain; use `TERMINATE` |
| `ABORT` Signature 2 (`p_execution_id`) **(Deprecated)** | procedure | Abortava uma execução; use `TERMINATE` |
| `GET_CURRENT_EXECUTION` | function | Dentro do processo em background, devolve o `t_execution` da própria execução (registro vazio fora dele) |
| `GET_EXECUTION` | function | Status de uma execução pelo ID |
| `SET_PROGRESS` | procedure | Informa unidades processadas (`p_sofar`) e total (`p_totalwork`) |
| `SET_STATUS` | procedure | Grava uma mensagem de status corrente |
| `TERMINATE` Signature 1 (`p_process_id`) | procedure | Termina todas as execuções de uma execution chain |
| `TERMINATE` Signature 2 (`p_execution_id`) | procedure | Termina uma execução específica |
| `c_status_enqueued` | constante | `'ENQUEUED'` |
| `c_status_scheduled` | constante | `'SCHEDULED'` |
| `c_status_executing` | constante | `'EXECUTING'` |
| `c_status_success` | constante | `'SUCCESS'` |
| `c_status_failed` | constante | `'FAILED'` |
| `c_status_terminated` | constante | `'ABORTED'` |
| `c_status_aborted` **(Deprecated)** | constante | `'ABORTED'`; use `c_status_terminated` |
| `t_execution_state` | subtype | `varchar2(9)` |
| `t_execution` | record | `id`, `state`, `current_exec_process_id`, `last_status_message`, `sofar`, `totalwork` |

**Pegadinha:** a tabela de atributos da doc cita `execution_id` e `context_value`, mas o record publicado tem `id` e não tem `context_value`. Use `l_exec.id` (como nos exemplos oficiais).

Fonte: [Data Types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_BACKGROUND_PROCESS-Data-Types.html), [Constants](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_BACKGROUND_PROCESS-Constants.html)

### APEX_BACKGROUND_PROCESS.SET_PROGRESS e SET_STATUS: reportar andamento de dentro do processo

```sql
APEX_BACKGROUND_PROCESS.SET_PROGRESS (
    p_totalwork IN NUMBER DEFAULT NULL,
    p_sofar     IN NUMBER );

APEX_BACKGROUND_PROCESS.SET_STATUS (
    p_message   IN VARCHAR2 );
```

- `p_totalwork` pode ficar nulo quando o total é desconhecido; informe só `p_sofar`.
- `SET_STATUS` grava `last_status_message`, útil para fases ("Parte A: importando", "Parte B: validando").
- Os valores ficam disponíveis via `GET_EXECUTION` (`sofar`, `totalwork`, `last_status_message`).

```sql
-- Processo PL/SQL dentro de uma Execution Chain em background
declare
    l_total pls_integer;
    l_i     pls_integer := 0;
begin
    select count(*) into l_total from colaborador where id_empresa = :G_ID_EMPRESA;
    apex_background_process.set_status('Recalculando indicadores');
    for r in (select id_colaborador from colaborador where id_empresa = :G_ID_EMPRESA) loop
        recalcula(r.id_colaborador);
        l_i := l_i + 1;
        apex_background_process.set_progress(p_totalwork => l_total, p_sofar => l_i);
    end loop;
    apex_background_process.set_status('Concluído');
end;
```

(No exemplo, `colaborador`, `recalcula` e `:G_ID_EMPRESA` são ilustrativos.)

Fonte: [SET_PROGRESS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_BACKGROUND_PROCESS.SET_PROGRESS-Procedure.html), [SET_STATUS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_BACKGROUND_PROCESS.SET_STATUS-Procedure.html)

### APEX_BACKGROUND_PROCESS.GET_EXECUTION e GET_CURRENT_EXECUTION: consultar o estado de uma execução

```sql
APEX_BACKGROUND_PROCESS.GET_EXECUTION (
    p_application_id IN NUMBER DEFAULT apex_application.g_flow_id,
    p_execution_id   IN NUMBER )
    RETURN t_execution;

APEX_BACKGROUND_PROCESS.GET_CURRENT_EXECUTION
    RETURN t_execution;
```

- `GET_EXECUTION`: usado pela página "de acompanhamento" (ex.: um processo Ajax ou um item calculado que a página atualiza periodicamente).
- `GET_CURRENT_EXECUTION`: chamado **de dentro** do processo em background para descobrir o próprio ID; fora dele devolve registro vazio.

```sql
-- Ajax Callback que devolve o percentual para a página
declare
    l_exec apex_background_process.t_execution;
begin
    l_exec := apex_background_process.get_execution(p_execution_id => :P50_EXECUTION_ID);
    apex_json.open_object;
    apex_json.write('state',   l_exec.state);
    apex_json.write('message', l_exec.last_status_message);
    apex_json.write('pct', case when l_exec.totalwork > 0
                                then round(100 * l_exec.sofar / l_exec.totalwork) end);
    apex_json.close_object;
end;
```

Fonte: [GET_EXECUTION Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_BACKGROUND_PROCESS.GET_EXECUTION-Function.html), [GET_CURRENT_EXECUTION Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_BACKGROUND_PROCESS.GET_CURRENT_EXECUTION-Function.html)

### APEX_BACKGROUND_PROCESS.TERMINATE: cancelar execuções (substitui ABORT, deprecated)

```sql
-- Signature 1: todas as execuções de uma execution chain
APEX_BACKGROUND_PROCESS.TERMINATE (
    p_application_id IN NUMBER DEFAULT apex_application.g_flow_id,
    p_process_id     IN NUMBER );

-- Signature 2: uma execução
APEX_BACKGROUND_PROCESS.TERMINATE (
    p_application_id IN NUMBER DEFAULT apex_application.g_flow_id,
    p_execution_id   IN NUMBER );
```

`p_process_id` é o ID do processo *Execution Chain* (componente da página); `p_execution_id` é o ID de uma execução. Após terminar, o estado passa a `ABORTED` (`c_status_terminated`). `ABORT` (duas assinaturas idênticas) está **deprecated** e será removido.

```sql
begin
    apex_background_process.terminate(
        p_application_id => 100,
        p_execution_id   => :P50_EXECUTION_ID );
end;
```

Fonte: [TERMINATE Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_BACKGROUND_PROCESS.TERMINATE-Procedure-Signature-1.html), [TERMINATE Procedure Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_BACKGROUND_PROCESS.TERMINATE-Procedure-Signature-2.html), [ABORT Procedure Signature 1 (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_BACKGROUND_PROCESS.ABORT-Procedure-Signature-1.html)

### Execução em background parada em ENQUEUED ou SCHEDULED

**Sintoma:** `GET_EXECUTION` mostra `state = 'ENQUEUED'` ou `'SCHEDULED'` por muito tempo.
**Causa:** `ENQUEUED` significa que o job coordenador ainda não pegou a execução; `SCHEDULED`, que o executor foi criado no DBMS_SCHEDULER mas o scheduler ainda não o iniciou (fila de jobs, limites do scheduler).
**Correção:** verifique os jobs do scheduler do schema/instância; quando o executor iniciar, o estado vira `EXECUTING`. Para desistir, use `TERMINATE`.

Fonte: [Constants](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_BACKGROUND_PROCESS-Constants.html)


## 24. APEX_AUTOMATION: executar, controlar e instrumentar Automations

### APEX_AUTOMATION: propósito, quando usar e quando não usar

*Automations* são sequências de ações disparadas pelo resultado de uma consulta (ou agendadas): monitoram dados e agem, por exemplo aprovando pedidos automaticamente ou mandando alertas por e-mail. `APEX_AUTOMATION` permite **executar** uma automation sob demanda (com filtros extras, em background ou sobre outro *query context*), **ligar/desligar**, **terminar**, **reagendar**, consultar a **última execução** e, dentro do código das ações, **registrar log**, **pular a linha** ou **sair**.

- **Quando usar:** disparar a automation a partir de um botão ou de outra rotina; testar uma automation num script com `apex_session.create_session`; filtrar o lote processado; desligar uma automation durante manutenção.
- **Quando não usar:** processamento único e pesado iniciado pelo usuário com acompanhamento de progresso (prefira *Execution Chain* em background, `APEX_BACKGROUND_PROCESS`).
- **Sessão:** rotinas chamadas fora da aplicação precisam de sessão APEX (os exemplos oficiais começam com `apex_session.create_session(100, 1, 'ADMIN')`).
- **Default de `p_application_id`:** a aplicação corrente.
- **Bind variables:** no código das ações, as colunas da *automation query* ficam disponíveis como binds (`:EMPNO`, `:SAL`...).

Fonte: [APEX_AUTOMATION](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AUTOMATION.html)

### APEX_AUTOMATION: referência completa de procedures e functions

| Item | Tipo | O que faz |
|---|---|---|
| `ABORT` **(Deprecated)** | procedure | Terminava a automation em execução; use `TERMINATE` |
| `DISABLE` | procedure | Impede a execução automática da automation |
| `ENABLE` | procedure | Habilita a automation para execução normal |
| `EXECUTE` Signature 1 (`p_filters`, `p_order_bys`) | procedure | Executa a automation com filtros/ordem adicionais na query |
| `EXECUTE` Signature 2 (`p_run_in_background`) | procedure | Executa; com `TRUE`, como job único do DBMS_SCHEDULER |
| `EXECUTE` for Query Context (`p_query_context`) | procedure | Executa as ações sobre outro `apex_exec.t_context` |
| `EXIT` | procedure | (Em ações) encerra o processamento, inclusive das linhas restantes |
| `GET_LAST_RUN` | function | (Em ações/query) timestamp da execução anterior |
| `GET_LAST_RUN_TIMESTAMP` | function | Timestamp da última execução bem-sucedida de uma automation |
| `GET_SCHEDULER_JOB_NAME` | function | Nome do job do scheduler usado pela automation (ex.: `APEX$AUTOMATION_<id>`) |
| `IS_RUNNING` | function | A automation está executando agora? |
| `LOG_ERROR` | procedure | Grava entrada `ERROR` no log da automation |
| `LOG_INFO` | procedure | Grava entrada `INFO` |
| `LOG_WARN` | procedure | Grava entrada `WARN` |
| `RESCHEDULE` | procedure | Antecipa a próxima execução de uma automation de *polling* |
| `SKIP_CURRENT_ROW` | procedure | (Em ações) pula a linha atual e segue para a próxima |
| `TERMINATE` | procedure | Termina a automation em execução (nada acontece se não estiver rodando) |

Fonte: [APEX_AUTOMATION](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AUTOMATION.html)

### APEX_AUTOMATION.EXECUTE: rodar uma automation sob demanda (filtros, background, query context)

```sql
-- Signature 1
APEX_AUTOMATION.EXECUTE (
    p_application_id IN NUMBER                DEFAULT {current application id},
    p_static_id      IN VARCHAR2,
    p_filters        IN apex_exec.t_filters   DEFAULT apex_exec.c_empty_filters,
    p_order_bys      IN apex_exec.t_order_bys DEFAULT apex_exec.c_empty_order_bys );

-- Signature 2
APEX_AUTOMATION.EXECUTE (
    p_application_id    IN NUMBER DEFAULT {current application id},
    p_static_id         IN VARCHAR2,
    p_run_in_background IN BOOLEAN );

-- for Query Context
APEX_AUTOMATION.EXECUTE (
    p_application_id IN NUMBER   DEFAULT {current application id},
    p_static_id      IN VARCHAR2,
    p_query_context  IN apex_exec.t_context );
```

- **Signature 1:** roda na sessão atual; os filtros (`apex_exec.add_filter`) e ordenações se somam à *automation query*.
- **Signature 2:** com `p_run_in_background => TRUE`, cria um job único do DBMS_SCHEDULER.
- **Query Context:** usa as **ações** da automation, mas sobre as linhas de outro contexto de consulta. As colunas do contexto devem corresponder às da query original, principalmente as usadas como bind no código das ações.

```sql
declare
    l_filters apex_exec.t_filters;
begin
    apex_session.create_session(100, 1, 'ADMIN');
    apex_exec.add_filter(
        p_filters     => l_filters,
        p_column_name => 'DEPTNO',
        p_filter_type => apex_exec.c_filter_eq,
        p_value       => 10 );
    apex_automation.execute(
        p_static_id => 'my_emp_table_automation',
        p_filters   => l_filters );
end;
```

```sql
declare
    l_context apex_exec.t_context;
begin
    apex_session.create_session(100, 1, 'ADMIN');
    l_context := apex_exec.open_query_context(
                     p_location  => apex_exec.c_location_local_db,
                     p_sql_query => 'select * from emp_copy_table' );
    apex_automation.execute(
        p_static_id     => 'my_emp_table_automation',
        p_query_context => l_context );
end;
```

**Pegadinha:** o exemplo oficial do *query context* tem `apex_exec.t_context:` (dois-pontos no lugar de ponto e vírgula); corrija ao copiar.

Fonte: [EXECUTE Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AUTOMATION_EXECUTE-Procedure-Signature-1.html), [EXECUTE Procedure Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AUTOMATION_EXECUTE-Procedure-Signature-2.html), [EXECUTE for Query Context Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AUTOMATION_EXECUTE-for-Query-Context.html)

### APEX_AUTOMATION: controle no código das ações (SKIP_CURRENT_ROW, EXIT, LOG_INFO, LOG_WARN, LOG_ERROR, GET_LAST_RUN)

```sql
APEX_AUTOMATION.SKIP_CURRENT_ROW ( p_log_message IN VARCHAR2 DEFAULT NULL );
APEX_AUTOMATION.EXIT             ( p_log_message IN VARCHAR2 DEFAULT NULL );
APEX_AUTOMATION.LOG_INFO  ( p_message IN VARCHAR2 );
APEX_AUTOMATION.LOG_WARN  ( p_message IN VARCHAR2 );
APEX_AUTOMATION.LOG_ERROR ( p_message IN VARCHAR2 );
APEX_AUTOMATION.GET_LAST_RUN RETURN timestamp with time zone;
```

- `SKIP_CURRENT_ROW`: abandona o resto do processamento só da linha atual.
- `EXIT`: encerra a automation inteira, incluindo as linhas que ainda não foram processadas.
- `LOG_*`: gravam no log da automation (visível no Builder, em *Automations*), com severidade INFO/WARN/ERROR.
- `GET_LAST_RUN`: use na própria *automation query* para processar só o que é novo desde a execução anterior.

```sql
-- Automation query
select * from pedidos where criado_em > apex_automation.get_last_run;

-- Código da ação (PL/SQL)
begin
    if :VALOR is null then
        apex_automation.skip_current_row(p_log_message => 'Pedido '||:ID||' sem valor');
    elsif :VALOR > 1000000 then
        apex_automation.exit(p_log_message => 'Valor suspeito; automation encerrada');
    else
        apex_automation.log_info('Aprovando pedido '||:ID);
        aprova_pedido(:ID);
    end if;
end;
```

**Pegadinha:** o exemplo oficial de `EXIT` usa `:SQL` onde deveria ser `:SAL`; os binds precisam ter o nome exato de colunas da query.

Fonte: [SKIP_CURRENT_ROW Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AUTOMATION_SKIP_CURRENT_ROW-Procedure.html), [EXIT Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AUTOMATION_EXIT-Procedure.html), [LOG_INFO Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AUTOMATION_LONG_INFO-Procedure.html), [LOG_WARN Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AUTOMATION_LOG_WARN-Procedure.html), [LOG_ERROR Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AUTOMATION_LOG_ERROR-Procedure.html), [GET_LAST_RUN Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AUTOMATION_GET_LAST_RETURN-Function.html)

### APEX_AUTOMATION: administrar (ENABLE, DISABLE, TERMINATE, RESCHEDULE, IS_RUNNING, GET_LAST_RUN_TIMESTAMP, GET_SCHEDULER_JOB_NAME)

```sql
APEX_AUTOMATION.ENABLE    ( p_application_id IN NUMBER DEFAULT {current application id}, p_static_id IN VARCHAR2 );
APEX_AUTOMATION.DISABLE   ( p_application_id IN NUMBER DEFAULT {current application id}, p_static_id IN VARCHAR2 );
APEX_AUTOMATION.TERMINATE ( p_application_id IN NUMBER DEFAULT {current application id}, p_static_id IN VARCHAR2 );

APEX_AUTOMATION.RESCHEDULE (
  p_application_id IN NUMBER                   DEFAULT {current application id},
  p_static_id      IN VARCHAR2,
  p_next_run_at    IN timestamp with time zone DEFAULT systimestamp );

APEX_AUTOMATION.IS_RUNNING (
    p_application_id IN NUMBER DEFAULT {current application id},
    p_static_id      IN VARCHAR2 ) RETURN BOOLEAN;

APEX_AUTOMATION.GET_LAST_RUN_TIMESTAMP (
    p_application_id IN NUMBER DEFAULT {current application id},
    p_static_id      IN VARCHAR2 ) RETURN timestamp with time zone;

APEX_AUTOMATION.GET_SCHEDULER_JOB_NAME (
    p_application_id IN NUMBER DEFAULT {current application id},
    p_static_id      IN VARCHAR2 ) RETURN VARCHAR2;
```

- `RESCHEDULE` vale para automations de *polling*: põe a próxima execução em `p_next_run_at` (default agora), para o job principal executá-la assim que possível. Se já estiver rodando, não reinicia.
- `TERMINATE` sem execução em curso não faz nada. `ABORT` é o nome antigo, **deprecated**.
- `GET_LAST_RUN_TIMESTAMP` considera a última execução **bem-sucedida**.
- `GET_SCHEDULER_JOB_NAME` ajuda a localizar o job em `USER_SCHEDULER_JOBS`/logs do scheduler.

```sql
begin
    apex_session.create_session(100, 1, 'ADMIN');
    if not apex_automation.is_running(p_static_id => 'sincroniza_pedidos') then
        apex_automation.reschedule(p_static_id => 'sincroniza_pedidos');
    end if;
end;
```

**Pegadinha:** o exemplo oficial de `GET_LAST_RUN_TIMESTAMP` declara `l_last_run_ts` e usa `l_last_run`; ajuste o nome.

Fonte: [ENABLE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AUTOMATION_ENABLE-Procedure.html), [DISABLE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AUTOMATION_DISABLE-Procedure.html), [TERMINATE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AUTOMATION_TERMINATE-Procedure.html), [ABORT Procedure (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AUTOMATION_ABORT-Procedure.html), [RESCHEDULE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AUTOMATION_RESCHEDULE-Procedure.html), [IS_RUNNING Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AUTOMATION_IS_RUNNING-Function.html), [GET_LAST_RUN_TIMESTAMP Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AUTOMATION_GET_LAST_RUN_TIMESTAMP-Procedure.html), [GET_SCHEDULER_JOB_NAME Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AUTOMATION_GET_SCHEDULER_JOB_NAME-Function.html)

### APEX_AUTOMATION.EXECUTE chamado de script SQL falha ou não acha a automation

**Sintoma:** chamar `apex_automation.execute` (ou `reschedule`, `get_last_run_timestamp`) num script SQL/SQLcl não funciona.
**Causa:** a rotina depende do contexto de uma aplicação APEX (o default de `p_application_id` é a aplicação corrente) e de uma sessão.
**Correção:** antes, crie uma sessão: `apex_session.create_session(p_app_id => 100, p_page_id => 1, p_username => 'ADMIN');` ou passe `p_application_id` explicitamente.

Fonte: [EXECUTE Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AUTOMATION_EXECUTE-Procedure-Signature-1.html), [RESCHEDULE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AUTOMATION_RESCHEDULE-Procedure.html)


## 25. APEX_PWA: push notifications de apps Progressive Web App

### APEX_PWA: propósito, quando usar e quando não usar

`APEX_PWA` reúne utilitários para aplicações com **Progressive Web App (PWA)** habilitado:
- inscrever e desinscrever usuários (dispositivos) em push notifications;
- verificar se o usuário tem inscrição;
- enviar notificações push;
- disparar a fila de envio;
- regenerar as credenciais de push da aplicação.

- **Fluxo típico:**
  1. No navegador, a API JavaScript (`apex.pwa.subscribePushNotifications`, `apex.pwa.getPushSubscription`, `apex.pwa.unsubscribePushNotifications`) gera o objeto de inscrição (JSON com `endpoint`, `expirationTime` e `keys.p256dh`/`keys.auth`).
  2. No servidor, `SUBSCRIBE_PUSH_NOTIFICATIONS` grava a inscrição.
  3. `SEND_PUSH_NOTIFICATION` enfileira a mensagem para **todos os dispositivos** inscritos do usuário.
  4. Um job do banco envia a fila. `PUSH_QUEUE` dispara esse job na hora.
- **Quando usar:** avisar o usuário fora da aba aberta, por exemplo de novo comunicado, tarefa atribuída ou resposta a uma solicitação.
- **Quando não usar:** para avisos só dentro da página aberta, use mensagens ou notificações da própria UI. Push depende de o usuário ter aceitado e inscrito o dispositivo.

Fonte: [APEX_PWA](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_PWA.html)

### APEX_PWA: referência completa de procedures e functions

| Item | Tipo | O que faz |
|---|---|---|
| `GENERATE_PUSH_CREDENTIALS` | procedure | Regenera as chaves de credencial de push da aplicação |
| `HAS_PUSH_SUBSCRIPTION` | function (`BOOLEAN`) | O usuário tem ao menos um dispositivo inscrito? |
| `PUSH_QUEUE` | procedure | Dispara o job que envia todas as notificações da fila |
| `SEND_PUSH_NOTIFICATION` | procedure | Envia notificação a todos os dispositivos inscritos de um usuário |
| `SUBSCRIBE_PUSH_NOTIFICATIONS` | procedure | Grava a inscrição (JSON do navegador) de um usuário |
| `UNSUBSCRIBE_PUSH_NOTIFICATIONS` | procedure | Remove uma inscrição ou todas |

O package não declara constantes nem tipos.

Fonte: [APEX_PWA](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_PWA.html)

### APEX_PWA.SEND_PUSH_NOTIFICATION e PUSH_QUEUE: enviar push a um usuário

```sql
APEX_PWA.SEND_PUSH_NOTIFICATION (
    p_application_id IN NUMBER   DEFAULT [current application id],
    p_user_name      IN VARCHAR2,
    p_title          IN VARCHAR2,
    p_body           IN VARCHAR2 DEFAULT NULL,
    p_icon_url       IN VARCHAR2 DEFAULT NULL,
    p_target_url     IN VARCHAR2 DEFAULT NULL );

APEX_PWA.PUSH_QUEUE;
```

| Parâmetro | Descrição |
|---|---|
| `p_application_id` | App do usuário destinatário (padrão: app atual) |
| `p_user_name` | Usuário que recebe (todos os seus dispositivos inscritos) |
| `p_title` | Título |
| `p_body` | Corpo |
| `p_icon_url` | Ícone. Padrão: ícone da aplicação |
| `p_target_url` | Página aberta ao clicar. Padrão: home da aplicação. A Oracle recomenda habilitar *deep linking* ou *rejoin session* na app |

```sql
begin
    if apex_pwa.has_push_subscription( p_user_name => l_destinatario ) then
        apex_pwa.send_push_notification(
            p_user_name  => l_destinatario,
            p_title      => 'Novo comunicado',
            p_body       => substr(l_titulo, 1, 200),
            p_target_url => apex_page.get_url( p_page => 11 ) );
        apex_pwa.push_queue;   -- opcional: envia agora em vez de esperar o job
    end if;
end;
```

**Pegadinhas**
- O envio é assíncrono, por fila e job de banco. Sem `PUSH_QUEUE`, a entrega ocorre quando o job rodar.
- `p_user_name` precisa ser o mesmo nome de usuário usado na inscrição.
- Sem *deep linking* ou *rejoin session*, o clique pode cair no login em vez da página alvo.

Fonte: [SEND_PUSH_NOTIFICATION Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_PWA.SEND_PUSH_NOTIFICATION-Procedure.html), [PUSH_QUEUE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_PWA.PUSH_QUEUE-Procedure.html)

### APEX_PWA.SUBSCRIBE_PUSH_NOTIFICATIONS, UNSUBSCRIBE_PUSH_NOTIFICATIONS e HAS_PUSH_SUBSCRIPTION: gerenciar inscrições

```sql
APEX_PWA.SUBSCRIBE_PUSH_NOTIFICATIONS (
    p_application_id         IN NUMBER   DEFAULT [current application id],
    p_user_name              IN VARCHAR2 DEFAULT [current user],
    p_subscription_interface IN VARCHAR2 );

APEX_PWA.UNSUBSCRIBE_PUSH_NOTIFICATIONS (
    p_application_id         IN NUMBER   DEFAULT [current application id],
    p_user_name              IN VARCHAR2 DEFAULT [current user],
    p_subscription_interface IN VARCHAR2 DEFAULT NULL );

APEX_PWA.HAS_PUSH_SUBSCRIPTION (
    p_application_id IN NUMBER   DEFAULT [current application id],
    p_user_name      IN VARCHAR2 DEFAULT [current user] )
    RETURN BOOLEAN;
```

| Parâmetro | Descrição |
|---|---|
| `p_subscription_interface` | Objeto de inscrição (JSON) gerado pelo navegador. No `UNSUBSCRIBE`, se informado remove só essa inscrição; se nulo, remove **todas** as do usuário |

```sql
-- processo AJAX chamado pelo JS depois de apex.pwa.subscribePushNotifications
begin
    apex_pwa.subscribe_push_notifications(
        p_subscription_interface => apex_application.g_x01 );  -- JSON {endpoint, expirationTime, keys{p256dh, auth}}
end;

-- "sair de todos os dispositivos"
begin
    apex_pwa.unsubscribe_push_notifications;
end;
```

**Pegadinha:** o exemplo oficial de `HAS_PUSH_SUBSCRIPTION` chama a função como se fosse uma instrução, o que não compila em PL/SQL. Use o resultado numa expressão (`if apex_pwa.has_push_subscription(...) then`).

Fonte: [SUBSCRIBE_PUSH_NOTIFICATIONS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_PWA.SUBSCRIBE_PUSH_NOTIFICATIONS-Procedure.html), [UNSUBSCRIBE_PUSH_NOTIFICATIONS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_PWA.UNSUBSCRIBE_PUSH_NOTIFICATIONS-Procedure.html), [HAS_PUSH_SUBSCRIPTION Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_PWA.HAS_PUSH_SUBSCRIPTION-Function.html)

### APEX_PWA.GENERATE_PUSH_CREDENTIALS: regenerar as chaves de push da aplicação

```sql
APEX_PWA.GENERATE_PUSH_CREDENTIALS (
    p_application_id IN NUMBER DEFAULT [current application id] );
```

Regenera as chaves de credencial de push da aplicação indicada (padrão: a atual).

```sql
begin
    apex_pwa.generate_push_credentials( p_application_id => 100 );
end;
```

**Pegadinha:** as inscrições dos navegadores ficam ligadas às chaves da aplicação. Depois de regenerar, espere que os dispositivos precisem se inscrever de novo e teste o envio.

Fonte: [GENERATE_PUSH_CREDENTIALS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_PWA.GENERATE_PUSH_CREDENTIALS-Procedure.html)


## 26. APEX_EXPORT: exportar app, workspace, arquivos e feedback por PL/SQL (SQL, APEXlang, checksum, zip)

### APEX_EXPORT: propósito, quando usar e quando não usar

`APEX_EXPORT` gera, a partir do banco, as mesmas definições que o Builder exporta: aplicações, definição e usuários de um workspace, os *static files* do workspace e o feedback de usuários. O resultado nunca é escrito em disco pelo package: as funções devolvem uma coleção em memória (`apex_t_export_files`), em que cada elemento tem um nome de arquivo e o conteúdo (CLOB, ou BLOB para binários do APEXlang). Quem grava no disco é o chamador (por exemplo, `spool` no SQLcl, um processo que monta um zip para download, ou um job que envia o arquivo a um repositório).

Quando usar:
- Automatizar backup/versionamento da app (job agendado, pipeline de CI via SQLcl) sem abrir o Builder.
- Exportar no formato **APEXlang** (legível, editável e importável) ou **SQL** (o formato clássico `fNNN.sql`), com ou sem *split* em vários arquivos.
- Comparar a mesma app entre instâncias/workspaces sem gerar o export inteiro: tipos `CHECKSUM-SH1` e `CHECKSUM-SH256` produzem um hash independente de IDs.
- Extrair só o código embutido (SQL, PL/SQL, JavaScript) com `EMBEDDED_CODE`, útil para revisão de código ou análise estática.
- Exportar só alguns componentes (`p_components`, ex.: `PAGE:42`, `LOV:%`).
- Empacotar o resultado com `ZIP` ou desempacotar um zip recebido com `UNZIP` para instalar via `APEX_APPLICATION_INSTALL`.

Quando não usar:
- Para importar/instalar: isso é `APEX_APPLICATION_INSTALL` (ver capítulo seguinte). `APEX_EXPORT` só lê.
- Para dados de negócio das tabelas: o export cobre metadados do APEX (e, opcionalmente, supporting objects, relatórios salvos, traduções, instâncias de runtime como workflows), não o conteúdo das suas tabelas.

Pré-requisitos e pegadinhas gerais:
- Os tipos `APEX_T_EXPORT_FILE` (tupla nome + conteúdo) e `APEX_T_EXPORT_FILES` (tabela deles) são tipos utilitários usados também por `APEX_APPLICATION_INSTALL.GET_INFO`/`INSTALL`.
- No formato `APEXLANG`, arquivos binários vêm em `contents_blob` e `contents` fica nulo; nos textuais é o contrário. Sempre teste qual dos dois está preenchido antes de gravar.
- Sem `p_split => true`, `GET_APPLICATION` devolve um único arquivo (`l_files(1)`).
- O identificador do workspace nas funções é o **ID numérico** (`p_workspace_id`), não o nome.

Fonte: [APEX_EXPORT](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXPORT.html) · [Constants and Data Types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXPORT.Constants_Data_Types.html)

### APEX_EXPORT: referência completa de procedures, functions, constantes e tipos

| Nome | Tipo | Descrição |
|---|---|---|
| `c_type_apexlang` = `'APEXLANG'` | constante (`t_export_type`) | Export em APEXlang (legível, modificável e importável). |
| `c_type_sql` = `'SQL'` | constante (`t_export_type`) | Export em SQL importável (padrão de `p_type`). |
| `c_type_embedded_code` = `'EMBEDDED_CODE'` | constante (`t_export_type`) | Só o código embutido (SQL, PL/SQL, JS); ignora as demais opções. |
| `c_type_checksum_sh1` = `'CHECKSUM-SH1'` | constante (`t_export_type`) | Checksum SHA1 independente de IDs. |
| `c_type_checksum_sh256` = `'CHECKSUM-SH256'` | constante (`t_export_type`) | Checksum SHA-256 independente de IDs. |
| `c_audit_dates_only` = `'DATES_ONLY'` | constante (`t_audit_type`) | Auditoria só com datas (sem nomes de usuário). |
| `c_audit_names_dates` = `'NAMES_AND_DATES'` | constante (`t_audit_type`) | Auditoria com Created/Updated On e By. |
| `t_export_file` | tipo (object) | `name`, `contents` (CLOB), `contents_blob` (BLOB), `component_display_name`, `component_type`, `component_type_label`, `component_id`. |
| `t_export_files` | tipo (table of `t_export_file`) | Coleção devolvida pelas funções de export. |
| `t_export_type` | subtype (`varchar2(255)`) | Tipo de export. |
| `t_audit_type` | subtype (`varchar2(255)`) | Nível de auditoria. |
| `GET_APPLICATION` | function | Exporta uma aplicação (com split, formatos e opções `p_with_%`). |
| `GET_FEEDBACK` | function | Exporta feedback de usuários (ou de desenvolvedores para um sistema de deploy). |
| `GET_WORKSPACE` | function | Exporta a definição e os usuários de um workspace. |
| `GET_WORKSPACE_FILES` | function | Exporta os static files do workspace. |
| `UNZIP` | function | Extrai os arquivos (texto UTF-8) de um zip em BLOB. |
| `ZIP` | function | Compacta uma coleção de arquivos (mais extras) num BLOB zip. |

Fonte: [Constants and Data Types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXPORT.Constants_Data_Types.html) · [APEX_EXPORT](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXPORT.html)

### APEX_EXPORT: tipos t_export_file / apex_t_export_files e o par contents × contents_blob

```sql
type t_export_file is object (
   name                    varchar2(1024),
   contents                clob,
   contents_blob           blob,
   component_display_name  varchar2(1024),
   component_type          varchar2(255),
   component_type_label    varchar2(1024),
   component_id            varchar2(255) );

type t_export_files is table of t_export_file;

subtype t_export_type     is varchar2( 255 );
subtype t_audit_type      is varchar2( 255 );
```

- `name`: caminho/nome do arquivo sugerido (com split, cada componente vira um arquivo com seu próprio caminho).
- `contents` × `contents_blob`: sempre exatamente um dos dois tem valor. `contents_blob` só aparece em export `APEXLANG` de arquivos binários (ex.: static files de imagem). Código que consome a coleção deve tratar os dois casos.
- `component_*`: metadados do componente que originou o arquivo (nome de exibição, tipo, rótulo do tipo, ID).
- Para montar uma coleção à mão (ex.: arquivos extras para `ZIP`, ou uma app baixada para `GET_INFO`), use o construtor: `apex_t_export_files( apex_t_export_file( name => 'README.md', contents => '...' ) )`.

```sql
-- Percorrer a coleção tratando texto e binário
declare
    l_files apex_t_export_files;
begin
    l_files := apex_export.get_application(
                   p_application_id => 100,
                   p_type           => apex_export.c_type_apexlang,
                   p_split          => true );
    for i in 1 .. l_files.count loop
        if l_files(i).contents is not null then
            sys.dbms_output.put_line('texto  : ' || l_files(i).name
                || ' (' || sys.dbms_lob.getlength(l_files(i).contents) || ' chars)');
        else
            sys.dbms_output.put_line('binário: ' || l_files(i).name
                || ' (' || sys.dbms_lob.getlength(l_files(i).contents_blob) || ' bytes)');
        end if;
    end loop;
end;
```

Fonte: [Constants and Data Types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXPORT.Constants_Data_Types.html)

### APEX_EXPORT.GET_APPLICATION: exportar uma aplicação (SQL, APEXlang, embedded code, checksum, split, componentes)

```sql
APEX_EXPORT.GET_APPLICATION (
    p_application_id            IN NUMBER,
    p_type                      IN t_export_type    DEFAULT c_type_sql,
    p_split                     IN BOOLEAN          DEFAULT FALSE,
    p_with_date                 IN BOOLEAN          DEFAULT FALSE,
    p_with_ir_public_reports    IN BOOLEAN          DEFAULT FALSE,
    p_with_ir_private_reports   IN BOOLEAN          DEFAULT FALSE,
    p_with_ir_notifications     IN BOOLEAN          DEFAULT FALSE,
    p_with_translations         IN BOOLEAN          DEFAULT FALSE,
    p_with_original_ids         IN BOOLEAN          DEFAULT FALSE,
    p_with_no_subscriptions     IN BOOLEAN          DEFAULT FALSE,
    p_with_comments             IN BOOLEAN          DEFAULT FALSE,
    p_with_supporting_objects   IN VARCHAR2         DEFAULT NULL,
    p_with_acl_assignments      IN BOOLEAN          DEFAULT FALSE,
    p_components                IN apex_t_varchar2  DEFAULT NULL,
    p_with_audit_info           IN t_audit_type     DEFAULT NULL,
    p_with_runtime_instances    IN apex_t_varchar2  DEFAULT NULL )
    RETURN apex_t_export_files;
```

| Parâmetro | Significado |
|---|---|
| `p_application_id` | ID da aplicação. |
| `p_type` | **Lista separada por vírgula** de tipos: `APEXLANG` (formato legível/editável/importável; se for passado `READABLE_YAML`, que está deprecated, gera APEXlang), `SQL` (formato SQL importável, padrão), `EMBEDDED_CODE` (só código SQL/PL/SQL/JS; todas as outras opções são ignoradas), `CHECKSUM-SH1` e `CHECKSUM-SH256` (hash independente de IDs, comparável entre instâncias e workspaces). |
| `p_split` | `TRUE`: quebra a definição em elementos discretos, um arquivo cada. `FALSE` (padrão): um único arquivo. |
| `p_with_date` | `TRUE`: inclui data/hora do export no conteúdo. |
| `p_with_ir_public_reports` | `TRUE`: inclui relatórios públicos salvos por usuários (Interactive Report). |
| `p_with_ir_private_reports` | `TRUE`: inclui relatórios privados salvos por usuários. |
| `p_with_ir_notifications` | `TRUE`: inclui as notificações de relatórios. |
| `p_with_translations` | `TRUE`: inclui mapeamentos de tradução e todo o texto do repositório de tradução. |
| `p_with_original_ids` | `TRUE`: exporta com os IDs que os componentes tinham quando a app foi importada. |
| `p_with_no_subscriptions` | Com `FALSE` (padrão), os componentes mantêm as referências de subscription. |
| `p_with_comments` | `TRUE`: inclui todos os comentários de desenvolvedor. |
| `p_with_supporting_objects` | `'Y'`: exporta os supporting objects. `'I'`: exporta e marca para instalar automaticamente na importação. `'N'`: não exporta. `NULL` (padrão): usa o valor de *Include in Export* configurado na app (Deployment). |
| `p_with_acl_assignments` | `TRUE`: exporta as atribuições de papéis (ACL user role assignments). |
| `p_components` | Se não nulo, exporta só os componentes listados, no formato `tipo:nome` (ex.: `PAGE:42`, `MESSAGE:12345`). `%` vale para todos do tipo (ex.: `LOV:%`). Os componentes exportáveis estão na view `APEX_APPL_EXPORT_COMPS`. |
| `p_with_audit_info` | `NULL` (padrão): sem auditoria. `NAMES_AND_DATES`: Created On/By e Updated On/By. `DATES_ONLY`: só as datas, sem nomes de usuário. |
| `p_with_runtime_instances` | Array de componentes cujas instâncias de runtime também são exportadas; ex.: `WORKFLOW` exporta as instâncias de Workflow junto com a app. |

Retorno: `apex_t_export_files`. Sem `p_split => true`, a coleção tem um único arquivo.

Comportamento e pegadinhas:
- `p_type` é uma lista separada por vírgula, então é possível pedir mais de um tipo na mesma chamada (ex.: `'SQL,APEXLANG'`).
- `EMBEDDED_CODE` descarta todos os outros parâmetros de opção.
- O checksum serve para responder "a app mudou?" entre ambientes sem comparar arquivos enormes e, por não depender de IDs, pode ser comparado entre instâncias e workspaces.
- Para exportar só uma página para revisão, combine `p_components => apex_t_varchar2('PAGE:42')`.
- `p_with_supporting_objects => 'I'` faz a instalação dos supporting objects acontecer automaticamente ao importar; útil para instaladores, perigoso se o script de supporting objects for destrutivo.

Exemplo 1 (SQLcl): gravar o export SQL da app 100 em `f100.sql` (o nome vem do próprio export).

```sql
variable name     varchar2(255)
variable contents clob
declare
    l_files apex_t_export_files;
begin
    l_files   := apex_export.get_application(p_application_id =>100);
    :name     := l_files(1).name;
    :contents := l_files(1).contents;
end;
/
set feed off echo off head off flush off termout off trimspool on
set long 100000000 longchunksize 32767
col name new_val name
select :name name from sys.dual;
spool &name.
print contents
spool off
```

Exemplo 2: APEXlang dividido em arquivos, com auditoria só de datas e sem relatórios salvos.

```sql
declare
    l_files apex_t_export_files;
begin
    l_files := apex_export.get_application(
                   p_application_id  => 100,
                   p_type            => apex_export.c_type_apexlang,
                   p_split           => true,
                   p_with_audit_info => apex_export.c_audit_dates_only );
    sys.dbms_output.put_line(l_files.count || ' arquivos gerados');
end;
```

Exemplo 3: comparar a app entre ambientes via checksum.

```sql
declare
    l_files apex_t_export_files;
begin
    l_files := apex_export.get_application(
                   p_application_id => 100,
                   p_type           => apex_export.c_type_checksum_sh256 );
    sys.dbms_output.put_line(l_files(1).contents);
end;
```

Exemplo 4: só as LOVs e a página 1.

```sql
declare
    l_files apex_t_export_files;
begin
    l_files := apex_export.get_application(
                   p_application_id => 100,
                   p_split          => true,
                   p_components     => apex_t_varchar2('LOV:%', 'PAGE:1') );
end;
```

Fonte: [GET_APPLICATION Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_APPLICATION_Function.html) · [Constants and Data Types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXPORT.Constants_Data_Types.html)

### APEX_EXPORT.GET_APPLICATION com READABLE_YAML: o tipo legado agora gera APEXlang

**Sintoma:** um script antigo chama `apex_export.get_application(..., p_type => 'READABLE_YAML')` e o resultado não é mais YAML.
**Causa:** `READABLE_YAML` está deprecated; no 26.1 o APEX gera `APEXLANG` quando esse valor é recebido.
**Correção:** passe `p_type => apex_export.c_type_apexlang` explicitamente e ajuste o consumidor para o formato APEXlang (incluindo o tratamento de `contents_blob` para binários).
**Prevenção:** use sempre as constantes `c_type_*` em vez de literais.

Fonte: [GET_APPLICATION Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_APPLICATION_Function.html)

### APEX_EXPORT.GET_WORKSPACE: exportar definição e usuários do workspace

```sql
APEX_EXPORT.GET_WORKSPACE (
    p_workspace_id          IN NUMBER,
    p_with_date             IN BOOLEAN  DEFAULT FALSE,
    p_with_team_development IN BOOLEAN  DEFAULT FALSE,
    p_with_misc             IN BOOLEAN  DEFAULT FALSE )
    RETURN apex_t_export_files;
```

| Parâmetro | Significado |
|---|---|
| `p_workspace_id` | ID numérico do workspace. |
| `p_with_date` | `TRUE`: inclui data/hora do export. |
| `p_with_team_development` | `TRUE`: inclui dados de Team Development. |
| `p_with_misc` | `TRUE`: inclui dados de SQL Workshop, logs de e-mail etc. |

Todas as opções `p_with_%` têm padrão `FALSE`. O export cobre a definição do workspace e seus usuários (não as aplicações; para elas use `GET_APPLICATION`, e para os static files `GET_WORKSPACE_FILES`).

```sql
declare
    l_files apex_t_export_files;
begin
    l_files := apex_export.get_workspace(
                   p_workspace_id => 12345678,
                   p_with_misc    => true );
end;
```

Pegadinha: o exemplo oficial declara `l_file` e atribui a `l_files`, o que não compila; use o mesmo nome na declaração e na atribuição.

Fonte: [GET_WORKSPACE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_WORKSPACE_Function.html)

### APEX_EXPORT.GET_WORKSPACE_FILES: exportar os static files do workspace

```sql
FUNCTION GET_WORKSPACE_FILES (
    p_workspace_id     IN NUMBER,
    p_with_date        IN BOOLEAN  DEFAULT FALSE )
    RETURN apex_t_export_files;
```

| Parâmetro | Significado |
|---|---|
| `p_workspace_id` | ID do workspace. |
| `p_with_date` | `TRUE`: inclui data/hora do export. |

Retorna um único arquivo (a doc diz que a divisão em vários arquivos fica para uma versão futura).

```sql
declare
    l_file apex_t_export_files;
begin
    l_file := apex_export.get_workspace_files(p_workspace_id => 12345678);
end;
```

Fonte: [GET_WORKSPACE _FILES Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_WORKSPACE.html)

### APEX_EXPORT.GET_FEEDBACK: exportar feedback de usuários ou de desenvolvedores

```sql
APEX_EXPORT.GET_FEEDBACK (
    p_workspace_id      IN NUMBER,
    p_with_date         IN BOOLEAN  DEFAULT FALSE,
    p_since             IN DATE     DEFAULT NULL,
    p_deployment_system IN VARCHAR2 DEFAULT NULL )
    RETURN apex_t_export_files;
```

| Parâmetro | Significado |
|---|---|
| `p_workspace_id` | ID do workspace. |
| `p_with_date` | `TRUE`: inclui data/hora do export. |
| `p_since` | Se informado, só o feedback coletado a partir dessa data. |
| `p_deployment_system` | `NULL`: exporta o feedback dos usuários (para levar ao ambiente de desenvolvimento). Não nulo: exporta o feedback dos desenvolvedores para o sistema de deploy indicado. |

```sql
-- Feedback de usuários para o ambiente de desenvolvimento
declare
    l_file apex_t_export_files;
begin
    l_file := apex_export.get_feedback(p_workspace_id => 12345678);
end;

-- Feedback de desenvolvedores desde 08/03/2010 para o deployment EA2
declare
    l_file apex_t_export_files;
begin
    l_file := apex_export.get_feedback (
                  p_workspace_id      => 12345678,
                  p_since             => date'2010-03-08',
                  p_deployment_system => 'EA2' );
end;
```

Fonte: [GET_FEEDBACK Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_FEEDBACK_Function.html)

### APEX_EXPORT.ZIP: compactar o export (e arquivos extras) num BLOB .zip

```sql
APEX_EXPORT.ZIP (
    p_source_files  apex_t_export_files,
    p_extra_files   apex_t_export_files DEFAULT apex_t_export_files() )
    RETURN BLOB;
```

| Parâmetro | Significado |
|---|---|
| `p_source_files` | Coleção de arquivos, normalmente saída de `apex_export.get_application`. |
| `p_extra_files` | Arquivos adicionais (README, licença etc.). Padrão: coleção vazia. |

Comportamento:
- Todo texto do zip é gravado em UTF-8.
- Os nomes dentro do arquivo precisam ser únicos; nome repetido gera exceção (proteção contra sobrescrever arquivos do export).
- Combine com `p_split => true` para ter a estrutura de pastas do export dentro do zip.

```sql
declare
  l_source_files apex_t_export_files;
  l_extra_files  apex_t_export_files;
  l_zip          blob;
begin
  l_source_files := apex_export.get_application(
                        p_application_id => 100,
                        p_split          => true );

  l_extra_files := apex_t_export_files(
    apex_t_export_file( name => 'README.md',   contents => 'Export de exemplo.' ),
    apex_t_export_file( name => 'LICENSE.txt', contents => 'UPL 1.0' ) );

  l_zip := apex_export.zip(
             p_source_files => l_source_files,
             p_extra_files  => l_extra_files );

  sys.dbms_output.put_line('zip com ' || sys.dbms_lob.getlength(l_zip) || ' bytes');
end;
```

Fonte: [ZIP Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ZIP-Function.html)

### APEX_EXPORT.UNZIP: extrair um zip para instalar com APEX_APPLICATION_INSTALL

```sql
APEX_EXPORT.UNZIP (
    p_source_zip    IN BLOB )
    RETURN apex_t_export_files;
```

| Parâmetro | Significado |
|---|---|
| `p_source_zip` | BLOB com o arquivo zip. |

Retorna uma `apex_t_export_files` com nome e conteúdo (convertido para texto) de cada arquivo do zip.

Restrições:
- Pensada para alimentar `APEX_APPLICATION_INSTALL.GET_INFO` / `INSTALL`.
- Supõe que **todos** os arquivos do zip são texto (scripts SQL, que precisam ter extensão `.sql`, ou READMEs simples) e codificados em UTF-8.

```sql
declare
   l_zip  blob;
   l_info apex_application_install.t_file_info;
begin
   l_zip := apex_web_service.make_rest_request_b (
                p_url         => 'https://www.example.com/apps/f100.zip',
                p_http_method => 'GET' );
   l_info := apex_application_install.get_info (
                p_source => apex_export.unzip ( p_source_zip => l_zip ) );
   sys.dbms_output.put_line('Tipo: ' || l_info.file_type || ' / App: ' || l_info.app_name);
end;
```

Fonte: [UNZIP Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/UNZIP-Function.html)

### APEX_EXPORT.UNZIP retorna conteúdo corrompido ou o install falha com arquivos do zip

**Sintoma:** depois de `apex_export.unzip`, o conteúdo de alguns arquivos vem ilegível, ou `get_info`/`install` rejeitam o resultado.
**Causa:** `UNZIP` converte tudo para texto e espera UTF-8; arquivos binários, scripts com outra codificação ou sem extensão `.sql` não se encaixam no que a função assume.
**Correção:** gere o zip com `APEX_EXPORT.ZIP` (que já grava UTF-8) a partir de um export SQL; mantenha no zip só scripts `.sql` e textos simples.
**Prevenção:** não use `UNZIP` para pacotes que contenham imagens ou outros binários.

Fonte: [UNZIP Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/UNZIP-Function.html) · [ZIP Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ZIP-Function.html)

### APEX_EXPORT.ZIP levanta exceção por nome de arquivo duplicado

**Sintoma:** `apex_export.zip` falha ao montar o arquivo.
**Causa:** dois arquivos (do export ou de `p_extra_files`) têm o mesmo `name`; a função exige nomes únicos para não sobrescrever arquivos do export.
**Correção:** renomeie os extras (ex.: `docs/README.md`) ou remova duplicatas antes de chamar `ZIP`.

Fonte: [ZIP Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ZIP-Function.html)


## 27. APEX_APPLICATION_INSTALL: instalar/importar apps por script mudando workspace, ID, alias, schema e outros atributos

### APEX_APPLICATION_INSTALL: propósito, quando usar e quando não usar

Há duas formas de importar uma aplicação: pelo upload do arquivo no Builder ou executando o export como script SQL (tipicamente no SQLcl). Pelo Builder dá para trocar ID da app, workspace e parsing schema; pela linha de comando, sem esta API, isso só seria possível editando o arquivo exportado. `APEX_APPLICATION_INSTALL` resolve isso: todo export gerado pelo APEX já referencia os valores definidos neste package, então basta chamar os `SET_%` **antes** de rodar o `@fNNN.sql` na mesma sessão, e o import usa esses valores em vez dos gravados no arquivo. Os métodos só sobrescrevem o comportamento padrão; sem chamá-los, o import segue o que está no arquivo.

Há também um caminho 100% PL/SQL: montar uma `apex_t_export_files` (de `APEX_EXPORT.GET_APPLICATION`, de `APEX_EXPORT.UNZIP` ou baixada via `APEX_WEB_SERVICE`), inspecionar com `GET_INFO` e instalar com `INSTALL`.

Quando usar:
- Deploy por linha de comando/CI em outro workspace, schema ou instância.
- Instalar a mesma app várias vezes (ex.: treinamento em vários workspaces) com IDs e aliases gerados.
- Ajustar na instalação atributos que variam por ambiente: alias, nome, image prefix, proxy, remote servers (Base URL, HTTPS host, IA), esquema de autenticação ativo, build status, max scheduler jobs, ECID, supporting objects automáticos, preservação de sessões e de background executions, subscriptions, datasets do Data Reporter.
- Remover uma app (`REMOVE_APPLICATION`) ou suspender execuções em background antes de um upgrade.

Quando não usar:
- Para exportar: use `APEX_EXPORT`.
- Para alterar atributos de uma app já instalada (fora do processo de import): veja `APEX_APPLICATION_ADMIN`.

Pegadinhas gerais:
- Os valores ficam guardados no estado do package durante a sessão; eles continuam valendo para os próximos imports da mesma sessão. Use `CLEAR_ALL` entre instalações diferentes (ou zere individualmente, como o exemplo de `SET_AUTHENTICATION_SCHEME` com `null`).
- Para ver o log da instalação no SQLcl, ative `set serveroutput on unlimited`.
- `SET_WORKSPACE` recebe o **nome** do workspace; `SET_WORKSPACE_ID` recebe o ID numérico.

Fonte: [About the APEX_APPLICATION_INSTALL API](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/Package-Overview.html) · [APEX_APPLICATION_INSTALL](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_INSTALL.html)

### APEX_APPLICATION_INSTALL: referência completa de procedures, functions, constantes e tipos

| Nome | Tipo | Descrição |
|---|---|---|
| `t_file_type` / `c_file_type_workspace` (1), `c_file_type_app` (2), `c_file_type_websheet` (3, não é mais usado), `c_file_type_plugin` (4), `c_file_type_css` (5), `c_file_type_apexlang_app` (6) | subtype + constantes | Tipo do arquivo de instalação. |
| `t_app_usage` / `c_app_usage_not_used` (1), `c_app_usage_current_workspace` (2), `c_app_usage_other_workspace` (3) | subtype + constantes | Se o ID/alias já é usado e onde. |
| `t_dataset_import_mode` / `c_dataset_keep` (1), `c_dataset_overwrite` (2) | subtype + constantes | Manter ou sobrescrever datasets do Data Reporter. |
| `t_subscription_mode` / `c_subscription_strict` (1), `c_subscription_ignore_errors` (2), `c_subscription_remove` (3), `c_subscription_legacy` (4) | subtype + constantes | Tratamento de subscriptions na instalação. |
| `t_file_info` | tipo (record) | Informações lidas do arquivo por `GET_INFO`. |
| `ADD_DATA_REPORTER_REMAP` | procedure | Remapeia o owner de objetos do Data Reporter. |
| `CLEAR_ALL` | procedure | Limpa todos os valores guardados no package. |
| `CLEAR_DATASET_IMPORT_MODES` | procedure | Limpa os modos de import de datasets. |
| `CLEAR_DATA_REPORTER_REMAP` | procedure | Limpa os remapeamentos de schema do Data Reporter. |
| `GENERATE_APPLICATION_ID` | procedure | Gera um ID de app livre na instância e o define. |
| `GENERATE_OFFSET` | procedure | Gera o offset de IDs de metadados. |
| `GET_APPLICATION_ALIAS` | function | Lê o alias definido. |
| `GET_APPLICATION_ID` | function | Lê o ID de app definido. |
| `GET_APPLICATION_NAME` | function | Lê o nome definido. |
| `GET_AUTHENTICATION_SCHEME` | function | Lê o esquema de autenticação a ativar. |
| `GET_AUTO_INSTALL_SUP_OBJ` | function | Lê a flag de instalação automática de supporting objects. |
| `GET_BUILD_STATUS` | function | Lê o build status a aplicar. |
| `GET_DATA_REPORTER_REMAP` | function | Lê o schema remapeado de um schema de origem. |
| `GET_DATASET_IMPORT_MODE` | function | Lê o modo de import de um dataset. |
| `GET_IMAGE_PREFIX` | function | Lê o image prefix. |
| `GET_INFO` | function | Lê informações de instalação de um export. |
| `GET_KEEP_BACKGROUND_EXECS` | function | Lê se background executions serão preservadas. |
| `GET_KEEP_SESSIONS` | function | Lê se sessões serão preservadas. |
| `GET_MAX_SCHEDULER_JOBS` | function | Lê o máximo de jobs de background. |
| `GET_NO_PROXY_DOMAINS` | function | Lê os No Proxy Domains. |
| `GET_OFFSET` | function | Lê o offset. |
| `GET_PASS_ECID` | function | Lê a flag de Pass ECID. |
| `GET_PROXY` | function | Lê o proxy. |
| `GET_REMOTE_SERVER_AI_ATTRS` | function | Lê os AI attributes (CLOB) de um remote server. |
| `GET_REMOTE_SERVER_AI_HEADERS` | function | Lê os AI HTTP headers (CLOB) de um remote server. |
| `GET_REMOTE_SERVER_AI_MAXTOKENS` | function | Lê o máximo de tokens de um servidor de IA/Vector Provider. |
| `GET_REMOTE_SERVER_AI_MODEL` | function | Lê o nome do modelo de IA. |
| `GET_REMOTE_SERVER_BASE_URL` | function | Lê o Base URL. |
| `GET_REMOTE_SERVER_DEFAULT_DB` | function | Lê o default database (MySQL). |
| `GET_REMOTE_SERVER_HTTPS_HOST` | function | Lê o HTTPS Host. |
| `GET_REMOTE_SERVER_SQL_MODE` | function | Lê o SQL mode (MySQL). |
| `GET_REST_SOURCE_CATALOG_GROUP` | function | Lê o grupo de REST Source Catalog. |
| `GET_SCHEMA` | function | Lê o parsing schema. |
| `GET_SUBSCRIPTION_MAPPING` | function | Lê o novo app de origem de subscription. |
| `GET_SUBSCRIPTION_MODE` | function | Lê o modo de subscription. |
| `GET_THEME_ID` | function | Lê o Theme ID de Template Components. |
| `GET_WORKSPACE_ID` | function | Lê o workspace ID. |
| `INSTALL` | procedure | Instala a app a partir de uma `apex_t_export_files`. |
| `REMOVE_APPLICATION` | procedure | Remove uma app do workspace. |
| `SET_APPLICATION_ALIAS` | procedure | Define o alias. |
| `SET_APPLICATION_ID` | procedure | Define o ID da app. |
| `SET_APPLICATION_NAME` | procedure | Define o nome. |
| `SET_AUTHENTICATION_SCHEME` | procedure | Define qual authentication scheme fica ativo. |
| `SET_AUTO_INSTALL_SUP_OBJ` | procedure | Liga/desliga a instalação automática de supporting objects. |
| `SET_BUILD_STATUS` | "function" (assinatura de procedure) | Define o build status. |
| `SET_DATASET_IMPORT_MODE` | procedure | Define manter/sobrescrever um dataset. |
| `SET_IMAGE_PREFIX` | procedure | Define o image prefix. |
| `SET_KEEP_BACKGROUND_EXECS` | procedure | Preserva background executions no upgrade. |
| `SET_KEEP_SESSIONS` | procedure | Preserva sessões no upgrade. |
| `SET_MAX_SCHEDULER_JOBS` | procedure | Define o máximo de jobs de background. |
| `SET_OFFSET` | procedure | Define o offset manualmente. |
| `SET_PASS_ECID` | procedure | Define Pass ECID. |
| `SET_PROXY` | procedure | Define proxy e No Proxy Domains. |
| `SET_REMOTE_SERVER` | procedure | Define Base URL, HTTPS host, MySQL, ORDS timezone e atributos de IA de um remote server. |
| `SET_REST_SOURCE_CATALOG_GROUP` | procedure | Define o grupo de destino de REST Source Catalogs. |
| `SET_SCHEMA` | procedure | Define o parsing schema. |
| `SET_SUBSCRIPTION_MAPPING` | procedure | Remapeia o app de origem de subscriptions. |
| `SET_SUBSCRIPTION_MODE` | procedure | Define o modo de subscription. |
| `SET_THEME_ID` | procedure | Define o Theme ID de Template Components. |
| `SET_WORKSPACE_ID` | procedure | Define o workspace pelo ID. |
| `SET_WORKSPACE` | procedure | Define o workspace pelo nome. |
| `SUSPEND_BACKGROUND_EXECS` | procedure | Suspende background executions até o fim da transação. |

Atributos principais manipulados pela API (doc "Attributes Manipulated"): Workspace ID, Application ID, Offset, Schema, Name, Alias, Image Prefix e Proxy; os demais `SET_%` acima cobrem atributos adicionais.

Fonte: [APEX_APPLICATION_INSTALL](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_INSTALL.html) · [Attributes Manipulated by APEX_APPLICATION_INSTALL](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/Attributes-Manipulated-by-APEX_APPLICATION_INSTALL.html) · [Import Data Types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_INSTALL-Data-Types.html)

### APEX_APPLICATION_INSTALL: tipos t_file_info, t_file_type, t_app_usage, t_subscription_mode e t_dataset_import_mode

```sql
subtype t_file_type is pls_integer range 1 .. 6;
c_file_type_workspace           constant t_file_type := 1;
c_file_type_app                 constant t_file_type := 2;
c_file_type_websheet            constant t_file_type := 3;   -- não é mais usado
c_file_type_plugin              constant t_file_type := 4;
c_file_type_css                 constant t_file_type := 5;
c_file_type_apexlang_app        constant t_file_type := 6;

subtype t_app_usage is pls_integer range 1..3;
c_app_usage_not_used            constant t_app_usage := 1;
c_app_usage_current_workspace   constant t_app_usage := 2;
c_app_usage_other_workspace     constant t_app_usage := 3;

subtype t_dataset_import_mode is pls_integer range 1..2;
c_dataset_keep            constant t_app_usage := 1;
c_dataset_overwrite       constant t_app_usage := 2;

type t_file_info is record (
     file_type                   t_file_type,
     workspace_id                number,
     workspace_name              varchar2(4000),
     version                     varchar2(10),
     app_id                      number,
     app_name                    varchar2(4000),
     app_alias                   varchar2(4000),
     app_owner                   varchar2(4000),
     build_status                varchar2(4000),
     has_install_script          boolean,
     app_id_usage                t_app_usage,
     app_alias_usage             t_app_usage,
     master_app_ids              t_number );

subtype t_subscription_mode is pls_integer range 1..4;
```

| Constante de subscription | Valor | Efeito |
|---|---|---|
| `c_subscription_strict` | 1 | Instala com as subscriptions; se não conseguir resolver um componente pelo static id, dá erro. **Padrão.** |
| `c_subscription_ignore_errors` | 2 | Instala com as subscriptions; componentes não resolvidos são ignorados. |
| `c_subscription_remove` | 3 | Remove as subscriptions na instalação. |
| `c_subscription_legacy` | 4 | Modo legado: usa o Subscription ID do arquivo como está, sem resolver por App ID + Component Static ID. |

Leitura prática de `t_file_info`: `app_id_usage`/`app_alias_usage` dizem se o ID/alias do arquivo está livre (1), já usado no workspace atual (2, um upgrade) ou usado em outro workspace (3, vai conflitar). `has_install_script` indica supporting objects. `file_type = 6` identifica um export APEXlang.

Fonte: [Import Data Types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_INSTALL-Data-Types.html)

### APEX_APPLICATION_INSTALL: exemplos de import no SQLcl com ID, alias, workspace e schema diferentes

Cenário da doc: app 645 exportada do workspace `FRED_DEV` como `f645.sql`, conectado no SQLcl.

Importar sem alterar nada (mesmo workspace, mesmo ID):

```sql
@f645.sql
```

Mesmo workspace, com ID 702 (precisa de offset novo e de alias novo, porque o alias é único no workspace):

```sql
begin
  apex_application_install.set_application_id( 702);
  apex_application_install.generate_offset;
  apex_application_install.set_application_alias( 'F' || apex_application_install.get_application_id );
end;
/
@f645.sql
```

Mesmo workspace, com ID gerado pelo APEX:

```sql
begin
  apex_application_install.generate_application_id;
  apex_application_install.generate_offset;
  apex_application_install.set_application_alias( 'F' || apex_application_install.get_application_id );
end;
/
@f645.sql
```

Outro workspace (`FRED_PROD`, em produção, com workspace ID diferente) e outro schema (`FREDDY`):

```sql
begin
    apex_application_install.set_workspace('FRED_PROD');
    apex_application_install.generate_offset;
    apex_application_install.set_schema( 'FREDDY' );
    apex_application_install.set_application_alias( 'FREDPROD_APP' );
end;
/
@f645.sql
```

Instância de treinamento, três workspaces (repetir o bloco para `TRAINING2`/`STUDENT2` e `TRAINING3`/`STUDENT3`):

```sql
begin
    apex_application_install.set_workspace('TRAINING1');
    apex_application_install.generate_application_id;
    apex_application_install.generate_offset;
    apex_application_install.set_schema( 'STUDENT1' );
    apex_application_install.set_application_alias( 'F' || apex_application_install.get_application_id );
end;
/
@f645.sql
```

Observação: no exemplo oficial com ID 702 o script chamado é `@645.sql` (sem o `f`), o que parece erro de digitação; o arquivo exportado é `f645.sql`.

Fonte: [Import Script Examples](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/Import-Script-Examples.html)

### APEX_APPLICATION_INSTALL.GET_INFO: ler workspace, ID, alias, versão e uso de IDs de um export antes de instalar

```sql
FUNCTION GET_INFO (
    p_source    IN  apex_t_export_files )
    RETURN t_file_info;
```

| Parâmetro | Significado |
|---|---|
| `p_source` | Coleção (nome, conteúdo): um registro para export normal ou vários para export com split. Passar **várias aplicações** não é suportado. |

Retorna `t_file_info`. Pode levantar `WWV_FLOW_IMP_PARSER.RUN_STMT_ERROR` quando o fonte contém comandos inválidos. A fonte lida fica guardada: `INSTALL` chamado depois com `p_source => null` instala esse mesmo conteúdo.

```sql
declare
    l_source apex_t_export_files;
    l_info   apex_application_install.t_file_info;
begin
    l_source := apex_t_export_files (
                    apex_t_export_file (
                        name     => 'f100.sql',
                        contents => apex_web_service.make_rest_request (
                                        p_url         => 'https://www.example.com/apps/f100.sql',
                                        p_http_method => 'GET' )));
    l_info := apex_application_install.get_info ( p_source => l_source );
    sys.dbms_output.put_line (apex_string.format (
         p_message => q'!Type ................. %0
                      !Workspace ............ %1
                      !Version .............. %2
                      !App ID ............... %3
                      !App Name ............. %4
                      !Alias ................ %5
                      !Owner ................ %6
                      !Build Status ......... %7
                      !Has Install Script ... %8
                      !App ID Usage ......... %9
                      !App Alias Usage ...... %10!',
       p0  => l_info.file_type,
       p1  => l_info.workspace_id,
       p2  => l_info.version,
       p3  => l_info.app_id,
       p4  => l_info.app_name,
       p5  => l_info.app_alias,
       p6  => l_info.app_owner,
       p7  => l_info.build_status,
       p8  => apex_debug.tochar(l_info.has_install_script),
       p9  => l_info.app_id_usage,
       p10 => l_info.app_alias_usage,
       p_prefix => '!' ));
end;
```

Fonte: [GET_INFO Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_INFO-Function.html)

### APEX_APPLICATION_INSTALL.INSTALL: instalar uma app a partir de apex_t_export_files em PL/SQL

```sql
PROCEDURE INSTALL (
    p_source             IN apex_t_export_files    DEFAULT NULL,
    p_overwrite_existing IN BOOLEAN                DEFAULT FALSE );
```

| Parâmetro | Significado |
|---|---|
| `p_source` | Coleção com um registro (export normal) ou vários (export com split). Várias aplicações não são suportadas. `NULL` (padrão): instala o fonte passado antes a `GET_INFO`. |
| `p_overwrite_existing` | `FALSE` (padrão): erro se a app já existe, em vez de sobrescrever. `TRUE`: sobrescreve. |

Antes de chamar, configure os atributos com os `SET_%`/`GENERATE_%`.

Exceções:

| Exceção | Quando |
|---|---|
| `WWV_FLOW_IMP_PARSER.RUN_STMT_ERROR` | O fonte contém comandos inválidos. |
| `SECURITY_GROUP_ID_INVALID` | O workspace corrente conflita com o workspace de instalação. |
| `WWV_FLOW_API.FLOW_ID_RESERVED_FOR_OTHER_WORKSPACE` | O ID da app é usado em outro workspace. |
| `WWV_FLOW_API.FLOW_ID_RANGE_RESERVED` | O ID está na faixa reservada para uso interno. |
| `WWV_FLOW_API.FLOW_ID_OUT_OF_RANGE` | O ID não está numa faixa válida. |
| `APPLICATION_ID_RESERVED` | O ID já é usado no workspace corrente e `p_overwrite_existing` é `FALSE`. |

```sql
-- Baixar a app e instalar com ID e offsets novos no workspace EXAMPLE
declare
    l_source apex_t_export_files;
begin
    l_source := apex_t_export_files (
                    apex_t_export_file (
                         name     => 'f100.sql',
                         contents => apex_web_service.make_rest_request (
                                          p_url         => 'https://www.example.com/apps/f100.sql',
                                          p_http_method => 'GET' )));
    apex_util.set_workspace('EXAMPLE');
    apex_application_install.generate_application_id;
    apex_application_install.generate_offset;
    apex_application_install.install ( p_source => l_source );
end;
```

```sql
-- Copiar a app 100 como nova app no mesmo workspace (export + install em memória)
declare
    l_files apex_t_export_files;
begin
    l_files := apex_export.get_application( p_application_id => 100 );
    apex_application_install.clear_all;
    apex_application_install.generate_application_id;
    apex_application_install.generate_offset;
    apex_application_install.set_application_alias( 'F' || apex_application_install.get_application_id );
    apex_application_install.install( p_source => l_files );
end;
```

Fonte: [INSTALL Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/INSTALL-Procedure.html) · [GET_APPLICATION Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_APPLICATION_Function.html)

### APEX_APPLICATION_INSTALL.INSTALL falha com APPLICATION_ID_RESERVED

**Sintoma:** `install` levanta `APPLICATION_ID_RESERVED`.
**Causa:** o ID da app já existe no workspace corrente e `p_overwrite_existing` ficou no padrão `FALSE`.
**Correção:** para upgrade, passe `p_overwrite_existing => true`; para cópia, gere um ID novo (`generate_application_id` + `generate_offset` + alias novo).
**Prevenção:** consulte `get_info(...).app_id_usage` antes: `c_app_usage_current_workspace` (2) indica que será upgrade.

Fonte: [INSTALL Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/INSTALL-Procedure.html) · [Import Data Types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_INSTALL-Data-Types.html)

### APEX_APPLICATION_INSTALL.INSTALL falha com FLOW_ID_RESERVED_FOR_OTHER_WORKSPACE

**Sintoma:** `WWV_FLOW_API.FLOW_ID_RESERVED_FOR_OTHER_WORKSPACE` ao instalar.
**Causa:** o ID de app está em uso em outro workspace da instância (IDs de app são únicos na instância; a app só pode ser sobrescrita no workspace onde já existe).
**Correção:** `set_application_id` com um ID livre ou `generate_application_id`, sempre com `generate_offset`.
**Prevenção:** verificar `get_info(...).app_id_usage = c_app_usage_other_workspace` (3).

Fonte: [INSTALL Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/INSTALL-Procedure.html) · [GET_APPLICATION_ID Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_APPLICATION_ID-Function.html)

### APEX_APPLICATION_INSTALL.INSTALL falha com FLOW_ID_RANGE_RESERVED ou FLOW_ID_OUT_OF_RANGE

**Sintoma:** erro `WWV_FLOW_API.FLOW_ID_RANGE_RESERVED` ou `WWV_FLOW_API.FLOW_ID_OUT_OF_RANGE`.
**Causa:** o ID escolhido está na faixa reservada do APEX (3000–8999) ou não é um inteiro positivo válido.
**Correção:** use um ID menor que 3000 ou maior ou igual a 9000, ou deixe o APEX escolher com `generate_application_id`.

Fonte: [SET_APPLICATION_ID Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_APPLICATION_ID-Procedure.html) · [INSTALL Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/INSTALL-Procedure.html)

### APEX_APPLICATION_INSTALL.INSTALL falha com SECURITY_GROUP_ID_INVALID

**Sintoma:** `SECURITY_GROUP_ID_INVALID` ao instalar.
**Causa:** o workspace corrente da sessão é diferente do workspace de instalação configurado.
**Correção:** alinhe os dois: defina o workspace de destino com `apex_application_install.set_workspace` (ou `apex_util.set_workspace`, como no exemplo oficial) antes do `install`, e use `clear_all` para descartar configurações de uma instalação anterior na mesma sessão.

Fonte: [INSTALL Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/INSTALL-Procedure.html)

### APEX_APPLICATION_INSTALL.SET_WORKSPACE e SET_WORKSPACE_ID: escolher o workspace de destino

```sql
APEX_APPLICATION_INSTALL.SET_WORKSPACE (
   p_workspace IN VARCHAR2 );          -- nome do workspace

APEX_APPLICATION_INSTALL.SET_WORKSPACE_ID (
    p_workspace_id  IN NUMBER );       -- ID do workspace

APEX_APPLICATION_INSTALL.GET_WORKSPACE_ID
RETURN NUMBER;
```

```sql
begin
  apex_application_install.set_workspace ( p_workspace => 'FRED_PROD' );
end;
/
@f100.sql
```

Use `SET_WORKSPACE` quando o ID do workspace difere entre ambientes (caso típico DEV → PROD); o nome é o que costuma ser estável.

Fonte: [SET_WORKSPACE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_INSTALL.SET_WORKSPACE_Procedure.html) · [SET_WORKSPACE_ID Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_WORKSPACE_ID-Procedure.html) · [GET_WORKSPACE_ID Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_WORKSPACE_ID-Function.html)

### APEX_APPLICATION_INSTALL.SET_APPLICATION_ID e GENERATE_APPLICATION_ID: definir ou gerar o ID da app

```sql
APEX_APPLICATION_INSTALL.SET_APPLICATION_ID (
    p_application_id IN NUMBER);

APEX_APPLICATION_INSTALL.GENERATE_APPLICATION_ID;

APEX_APPLICATION_INSTALL.GET_APPLICATION_ID
RETURN NUMBER;
```

Regras do ID: inteiro positivo, fora da faixa reservada 3000–8999 (menor que 3000 ou maior/igual a 9000). Ele não pode existir na instância, a menos que exista justamente no workspace de destino (aí é um upgrade). `GENERATE_APPLICATION_ID` escolhe um ID disponível na instância e já o define no package; leia-o com `GET_APPLICATION_ID` (por exemplo, para montar o alias `'F' || id`).

Pegadinha: ao trocar o ID, chame também `GENERATE_OFFSET` (ou `SET_OFFSET`), senão os IDs internos dos componentes podem colidir com os da app original.

Fonte: [SET_APPLICATION_ID Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_APPLICATION_ID-Procedure.html) · [GENERATE_APPLICATION_ID Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GENERATE_APPLICATION_ID-Procedure.html) · [GET_APPLICATION_ID Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_APPLICATION_ID-Function.html)

### APEX_APPLICATION_INSTALL.GENERATE_OFFSET e SET_OFFSET: evitar colisão de IDs de metadados

```sql
APEX_APPLICATION_INSTALL.GENERATE_OFFSET;

APEX_APPLICATION_INSTALL.SET_OFFSET (
    p_offset IN NUMBER );

APEX_APPLICATION_INSTALL.GET_OFFSET
RETURN NUMBER;
```

O offset é somado aos IDs dos metadados da app para que não colidam com outros metadados da instância. Para instalação nova, `GENERATE_OFFSET` (que gera um valor aleatório grande) costuma bastar. `SET_OFFSET` aceita um inteiro positivo escolhido por você:

```sql
declare
  l_offset number;
begin
  l_offset := dbms_random.value(100000000000, 999999999999);
  apex_application_install.set_offset( p_offset => l_offset );
end;
/
@f100.sql
```

Fonte: [GENERATE_OFFSET Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GENERATE_OFFSET-Procedure.html) · [SET_OFFSET Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_OFFSET-Procedure.html) · [GET_OFFSET Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_OFFSET-Function.html)

### APEX_APPLICATION_INSTALL.SET_SCHEMA: trocar o parsing schema da app na importação

```sql
APEX_APPLICATION_INSTALL.SET_SCHEMA (
    p_schema  IN VARCHAR2 );

APEX_APPLICATION_INSTALL.GET_SCHEMA
RETURN VARCHAR2;
```

O usuário de banco do schema precisa existir **e** já estar associado ao workspace de destino. Caso contrário, associe antes (por exemplo com `APEX_INSTANCE_ADMIN.ADD_SCHEMA`).

Fonte: [SET_SCHEMA Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_SCHEMA-Procedure.html) · [GET_SCHEMA Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_SCHEMA-Function.html)

### APEX_APPLICATION_INSTALL.SET_APPLICATION_ALIAS e SET_APPLICATION_NAME: alias e nome da app importada

```sql
APEX_APPLICATION_INSTALL.SET_APPLICATION_ALIAS (
    p_application_alias IN VARCHAR2 );
APEX_APPLICATION_INSTALL.GET_APPLICATION_ALIAS
RETURN VARCHAR2;

APEX_APPLICATION_INSTALL.SET_APPLICATION_NAME (
    p_application_name  IN VARCHAR2 );
APEX_APPLICATION_INSTALL.GET_APPLICATION_NAME
RETURN VARCHAR2;
```

- Alias: identificador alfanumérico, menos de 255 caracteres, único no workspace (recomendado único na instância). Só tem efeito se a app importada tiver alias.
- Nome: não pode ser nulo, até 255 caracteres.

```sql
begin
  apex_application_install.set_application_name( p_application_name => 'Executive Dashboard' );
end;
/
@f100.sql
```

Fonte: [SET_APPLICATION_ALIAS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_INSTALL.SET_APPLICATION_ALIAS-Procedure.html) · [GET_APPLICATION_ALIAS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_INSTALL.GET_APPLICATION_ALIAS-Function.html) · [SET_APPLICATION_NAME Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_INSTALL.SET_APPLICATION_NAME-Procedure.html) · [GET_APPLICATION_NAME Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_INSTALL.GET_APPLICATION_NAME-Function.html)

### APEX_APPLICATION_INSTALL.SET_IMAGE_PREFIX e SET_PROXY: image prefix, proxy e No Proxy Domains

```sql
APEX_APPLICATION_INSTALL.SET_IMAGE_PREFIX(
    p_image_prefix  IN VARCHAR2);
APEX_APPLICATION_INSTALL.GET_IMAGE_PREFIX
RETURN VARCHAR2;

APEX_APPLICATION_INSTALL.SET_PROXY (
    p_proxy            IN VARCHAR2,
    p_no_proxy_domains IN VARCHAR2 DEFAULT NULL );
APEX_APPLICATION_INSTALL.GET_PROXY
RETURN VARCHAR2;
APEX_APPLICATION_INSTALL.GET_NO_PROXY_DOMAINS
RETURN VARCHAR2;
```

- Image prefix: a maioria das instâncias usa `/i/`; pode ser um domínio completo (CDN, outro servidor web) ou só um caminho; até 255 caracteres.
- Proxy: sem default, menos de 255 caracteres, **sem prefixo de protocolo** (`www-proxy.example.com`, não `http://...`). `p_no_proxy_domains` lista domínios que não passam pelo proxy.

```sql
begin
  apex_application_install.set_image_prefix( p_image_prefix => '/i/' );
  apex_application_install.set_proxy( p_proxy => 'www-proxy.example.com' );
end;
/
@f100.sql
```

Pegadinha: a página de `GET_NO_PROXY_DOMAINS` mostra na sintaxe `GET_PROXY` por engano; o nome correto, usado no exemplo, é `get_no_proxy_domains`.

Fonte: [SET_IMAGE_PREFIX Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_INSTALL.SET_IMAGE_PREFIX-Procedure.html) · [GET_IMAGE_PREFIX Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_INSTALL.GET_IMAGE_PREFIX-Function.html) · [SET_PROXY Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_PROXY-Procedure.html) · [GET_PROXY Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_PROXY-Function.html) · [GET_NO_PROXY_DOMAINS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_INSTALL.GET_NO_PROXY_DOMAINS-Function.html)

### APEX_APPLICATION_INSTALL.SET_REMOTE_SERVER: trocar Base URL, HTTPS host, MySQL e IA de remote servers por ambiente

```sql
APEX_APPLICATION_INSTALL.SET_REMOTE_SERVER (
    p_static_id         IN VARCHAR2,
    p_base_url          IN VARCHAR2,
    p_https_host        IN VARCHAR2 DEFAULT NULL,
    --
    p_default_database  IN VARCHAR2 DEFAULT NULL,
    p_mysql_sql_modes   IN VARCHAR2 DEFAULT NULL,
    --
    p_ords_timezone     IN VARCHAR2 DEFAULT NULL,
    --
    p_ai_model_name     IN VARCHAR2 DEFAULT NULL,
    p_ai_http_headers   IN CLOB     DEFAULT NULL,
    p_ai_attributes     IN CLOB     DEFAULT NULL,
    p_ai_max_tokens     IN NUMBER   DEFAULT NULL );
```

| Parâmetro | Significado |
|---|---|
| `p_static_id` | Static ID do remote server (é por ele que o server é identificado). |
| `p_base_url` | Novo Base URL. |
| `p_https_host` | Novo HTTPS Host; só relevante com Base URL `https://` e banco 12.2 ou superior. |
| `p_default_database` | Database padrão ao conectar (por ora só MySQL). |
| `p_mysql_sql_modes` | SQL modes ao conectar em MySQL. |
| `p_ords_timezone` | Fuso horário do ORDS de uma referência REST-enabled SQL usada pela app. |
| `p_ai_model_name` | Modelo de IA a usar num Generative AI Service. |
| `p_ai_http_headers` | Headers HTTP para as requisições ao serviço de IA. |
| `p_ai_attributes` | Atributos em JSON para as requisições ao serviço de IA. |
| `p_ai_max_tokens` | Máximo de tokens numa janela móvel de 24 h que o APEX pode usar nesse serviço. |

Leitura dos valores configurados (todas recebem `p_static_id IN VARCHAR2`):

```sql
GET_REMOTE_SERVER_BASE_URL     (p_static_id) RETURN VARCHAR2;
GET_REMOTE_SERVER_HTTPS_HOST   (p_static_id) RETURN VARCHAR2;
GET_REMOTE_SERVER_DEFAULT_DB   (p_static_id) RETURN VARCHAR2;
GET_REMOTE_SERVER_SQL_MODE     (p_static_id) RETURN VARCHAR2;
GET_REMOTE_SERVER_AI_MODEL     (p_static_id) RETURN VARCHAR2;
GET_REMOTE_SERVER_AI_HEADERS   (p_static_id) RETURN CLOB;
GET_REMOTE_SERVER_AI_ATTRS     (p_static_id) RETURN CLOB;
GET_REMOTE_SERVER_AI_MAXTOKENS (p_static_id) RETURN NUMBER;  -- Generative AI ou Vector Provider
```

```sql
begin
    apex_application_install.set_remote_server(
        p_static_id => 'MY_REMOTE_SERVER',
        p_base_url  => 'http://production.example.com' );
end;
/
@f100.sql
```

Quando usar: a app aponta para endpoints REST/IA diferentes em DEV e PROD; em vez de editar o export, o script de deploy de cada ambiente chama `set_remote_server` para cada static id.

Fonte: [SET_REMOTE_SERVER Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_REMOTE_SERVER-Procedure.html) · [GET_REMOTE_SERVER_BASE_URL Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_REMOTE_SERVER_BASE_URL-Function.html) · [GET_REMOTE_SERVER_HTTPS_HOST Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_REMOTE_SERVER_HTTPS_HOST-Function.html) · [GET_REMOTE_SERVER_DEFAULT_DB Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_REMOTE_SERVER_DEFAULT_DB-Function.html) · [GET_REMOTE_SERVER_SQL_MODE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_REMOTE_SERVER_SQL_MODE-Function.html) · [GET_REMOTE_SERVER_AI_MODEL Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_REMOTE_SERVER_AI_MODEL-Function.html) · [GET_REMOTE_SERVER_AI_HEADERS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_REMOTE_SERVER_AI_HEADERS-Function.html) · [GET_REMOTE_SERVER_AI_ATTRS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_REMOTE_SERVER_AI_ATTRS-Function.html) · [GET_REMOTE_SERVER_AI_MAXTOKENS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_INSTALL.GET_REMOTE_SERVER_AI_MAXTOKENS-Function.html)

### APEX_APPLICATION_INSTALL.SET_AUTHENTICATION_SCHEME: ativar outro authentication scheme na instalação

```sql
APEX_APPLICATION_INSTALL.SET_AUTHENTICATION_SCHEME (
      p_name IN VARCHAR2 );
APEX_APPLICATION_INSTALL.GET_AUTHENTICATION_SCHEME
    RETURN VARCHAR2;
```

`p_name` é o nome de um authentication scheme que **já existe** na app; ele vira o ativo. `NULL` mantém o scheme ativo do arquivo. Como o valor persiste na sessão, zere-o antes de instalar a próxima app:

```sql
begin
  apex_application_install.set_authentication_scheme ( p_name => 'SSO-Production' );
end;
/
@f100.sql
begin
  apex_application_install.set_authentication_scheme ( p_name => null );
end;
/
@f101.sql
```

Fonte: [SET_AUTHENTICATION_SCHEME Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_INSTALL.SET_AUTHENTICATION_SCHEME-Procedure.html) · [GET_AUTHENTICATION_SCHEME Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_INSTALL.GET_AUTHENTICATION_SCHEME-Function.html)

### APEX_APPLICATION_INSTALL.SET_BUILD_STATUS: instalar como RUN_ONLY ou RUN_AND_BUILD

```sql
APEX_APPLICATION_INSTALL.SET_BUILD_STATUS (
    p_build_status  IN  wwv_flow_application_admin_api.t_build_status );
APEX_APPLICATION_INSTALL.GET_BUILD_STATUS
    RETURN VARCHAR2;
```

Valores: `apex_application_admin.c_build_status_run_and_build` (desenvolvedores editam e usuários executam) e `apex_application_admin.c_build_status_run_only` (só execução; desenvolvedores não editam). A doc classifica como "Function", mas a assinatura não tem `RETURN`: use como procedure.

```sql
begin
    apex_application_install.set_build_status ( p_build_status => 'RUN_ONLY' );
end;
/
@f100.sql
```

Fonte: [SET_BUILD_STATUS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_INSTALL.SET_BUILD_STATUS-Function.html) · [GET_BUILD_STATUS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_INSTALL.GET_BUILD_STATUS-Function.html)

### APEX_APPLICATION_INSTALL.SET_AUTO_INSTALL_SUP_OBJ: instalar supporting objects automaticamente no import por linha de comando

```sql
APEX_APPLICATION_INSTALL.SET_AUTO_INSTALL_SUP_OBJ (
    p_auto_install_sup_obj IN BOOLEAN );
APEX_APPLICATION_INSTALL.GET_AUTO_INSTALL_SUP_OBJ
RETURN BOOLEAN;
```

Só vale para instalação pela **linha de comando**. Com `TRUE`, se o export tiver supporting objects, eles são instalados (ou atualizados, num upgrade) junto com a app.

```sql
begin
  apex_application_install.set_auto_install_sup_obj( p_auto_install_sup_obj => true );
end;
/
@f100.sql
```

Fonte: [SET_AUTO_INSTALL_SUP_OBJ Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_AUTO_INSTALL_SUP_OBJ-Procedure.html) · [GET_AUTO_INSTALL_SUP_OBJ Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_AUTO_INSTALL_SUP_OBJ-Function.html)

### APEX_APPLICATION_INSTALL.SET_KEEP_SESSIONS: preservar sessões e session state no upgrade

```sql
procedure SET_KEEP_SESSIONS (
    p_keep_sessions IN BOOLEAN );
function GET_KEEP_SESSIONS
    RETURN BOOLEAN;
```

Padrão `FALSE`: num upgrade, as sessões da app são apagadas (usuários conectados perdem o estado). `TRUE` as preserva. O padrão da instância vem do parâmetro de instância `KEEP_SESSIONS_ON_UPGRADE` (`N` por padrão).

```sql
begin
  apex_application_install.set_workspace(p_workspace => 'FRED_PROD');
  apex_application_install.set_keep_sessions(p_keep_sessions => true);
end;
/
@f100.sql
```

Fonte: [SET_KEEP_SESSIONS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_KEEP_SESSIONS-Procedure.html) · [GET_KEEP_SESSIONS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_KEEP_SESSIONS-Function.html)

### APEX_APPLICATION_INSTALL: background executions no upgrade (SET_KEEP_BACKGROUND_EXECS, SUSPEND_BACKGROUND_EXECS, SET_MAX_SCHEDULER_JOBS)

```sql
APEX_APPLICATION_INSTALL.SET_KEEP_BACKGROUND_EXECS (
    p_keep_background_execs IN BOOLEAN );
APEX_APPLICATION_INSTALL.GET_KEEP_BACKGROUND_EXECS
    RETURN BOOLEAN;

APEX_APPLICATION_INSTALL.SUSPEND_BACKGROUND_EXECS (
    p_application_id     IN NUMBER );

APEX_APPLICATION_INSTALL.SET_MAX_SCHEDULER_JOBS (
    p_max_scheduler_jobs IN NUMBER );
APEX_APPLICATION_INSTALL.GET_MAX_SCHEDULER_JOBS
    RETURN NUMBER;
```

- `SET_KEEP_BACKGROUND_EXECS`: o padrão (`FALSE`) aborta e apaga todas as background executions da app no upgrade; `TRUE` as preserva.
- `SUSPEND_BACKGROUND_EXECS`: para usar antes do upgrade. Espera terminarem as execuções `SCHEDULED` ou `EXECUTING` e bloqueia novas até o fim da transação (`COMMIT` ou `ROLLBACK`). Enquanto isso, novas execuções podem ser enfileiradas, mas só rodam depois que o lock é liberado.
- `SET_MAX_SCHEDULER_JOBS`: número máximo de jobs de background processing da app importada.

```sql
begin
   apex_application_install.suspend_background_execs( p_application_id => 100 );
   apex_application_install.set_workspace(p_workspace => 'FRED_PROD');
   apex_application_install.set_keep_background_execs(p_keep_background_execs => true);
   apex_application_install.set_max_scheduler_jobs( p_max_scheduler_jobs => 5 );
end;
/
@f100.sql
```

Pegadinha: o lock de `SUSPEND_BACKGROUND_EXECS` é liberado no fim da transação; um `COMMIT` antes de o upgrade terminar libera as execuções antes da hora.

Fonte: [SET_KEEP_BACKGROUND_EXECS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_KEEP_BACKGROUND_EXECS-Procedure.html) · [GET_KEEP_BACKGROUND_EXECS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_KEEP_BACKGROUND_EXECS-Function.html) · [SUSPEND_BACKGROUND_EXECS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SUSPEND_BACKGROUND_EXECS-Procedure.html) · [SET_MAX_SCHEDULER_JOBS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_INSTALL.SET_MAX_SCHEDULER_JOBS-Procedure.html) · [GET_MAX_SCHEDULER_JOBS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_INSTALL.GET_MAX_SCHEDULER_JOBS-Function.html)

### APEX_APPLICATION_INSTALL.SET_PASS_ECID: repassar o Execution Context ID a web services

```sql
APEX_APPLICATION_INSTALL.SET_PASS_ECID (
    p_pass_ecid IN BOOLEAN );
APEX_APPLICATION_INSTALL.GET_PASS_ECID
    RETURN BOOLEAN;
```

`TRUE`: o ECID é enviado aos web services externos para rastreamento ponta a ponta. `FALSE`: não envia.

```sql
begin
   apex_application_install.set_pass_ecid ( p_pass_ecid => true );
end;
/
@f100.sql
```

Fonte: [SET_PASS_ECID Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_INSTALL.SET_PASS_ECID-Procedure.html) · [GET_PASS_ECID Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_INSTALL.GET_PASS_ECID-Function.html)

### APEX_APPLICATION_INSTALL: subscriptions na instalação (SET_SUBSCRIPTION_MODE, SET_SUBSCRIPTION_MAPPING)

```sql
APEX_APPLICATION_INSTALL.SET_SUBSCRIPTION_MODE (
    p_mode                   IN              t_subscription_mode);
APEX_APPLICATION_INSTALL.GET_SUBSCRIPTION_MODE
    RETURN t_subscription_mode;

APEX_APPLICATION_INSTALL.SET_SUBSCRIPTION_MAPPING (
    p_from_application_id    IN              NUMBER,
    p_to_application_id      IN              NUMBER);
APEX_APPLICATION_INSTALL.GET_SUBSCRIPTION_MAPPING (
    p_from_application_id    IN              NUMBER)
    RETURN NUMBER;
```

- Modo padrão: `c_subscription_strict`; o padrão da instância pode ser trocado pelo parâmetro `IMP_DEFAULT_SUBSCRIPTION_MODE`. Veja a tabela de modos em "tipos".
- `SET_SUBSCRIPTION_MAPPING`: troca o app de origem das subscriptions (ex.: Component Library App ou Theme App 100 → 200). Pode ser chamado várias vezes. A app de destino precisa existir no workspace alvo. **Não** serve para trocar a subscription de tema do Universal Theme nativo para um tema local, nem o inverso.
- `GET_SUBSCRIPTION_MAPPING` devolve o ID mapeado ou, se não houver mapeamento, o próprio ID de entrada.

```sql
begin
    apex_application_install.clear_all;
    apex_application_install.set_workspace('TARGET_WORKSPACE');
    apex_application_install.set_subscription_mapping( p_from_application_id => 100, p_to_application_id => 200 );
    apex_application_install.set_subscription_mapping( p_from_application_id => 110, p_to_application_id => 210 );
    -- ou, para descartar todas as subscriptions:
    -- apex_application_install.set_subscription_mode( p_mode => apex_application_install.c_subscription_remove );
end;
```

Fonte: [SET_SUBSCRIPTION_MODE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_INSTALL.SET_SUBSCRIPTION_MODE-Procedure.html) · [GET_SUBSCRIPTION_MODE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_INSTALL.GET_SUBSCRIPTION_MODE-Function.html) · [SET_SUBSCRIPTION_MAPPING Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_INSTALL.SET_SUBSCRIPTION_MAPPING-Procedure.html) · [GET_SUBSCRIPTION_MAPPING Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_INSTALL.GET_SUBSCRIPTION_MAPPING-Function.html)

### Import falha porque um componente subscrito não é resolvido (subscription strict)

**Sintoma:** a instalação para com erro relacionado a subscription de componente.
**Causa:** no modo padrão `c_subscription_strict`, se o instalador não encontra o componente mestre pelo static id, ele levanta erro (por exemplo, a Component Library/Theme App não existe no workspace de destino ou tem outro ID).
**Correção:** mapeie a app mestre com `set_subscription_mapping` para o ID existente no destino; ou use `c_subscription_ignore_errors` para ignorar os não resolvidos; ou `c_subscription_remove` para instalar sem subscriptions.
**Prevenção:** antes de instalar, confira com `get_info` o campo `master_app_ids` (pelo nome, os IDs das apps mestras referenciadas) e garanta que essas apps existam no destino.

Fonte: [Import Data Types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_INSTALL-Data-Types.html) · [SET_SUBSCRIPTION_MAPPING Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_INSTALL.SET_SUBSCRIPTION_MAPPING-Procedure.html)

### APEX_APPLICATION_INSTALL: Data Reporter na instalação (ADD_DATA_REPORTER_REMAP, SET_DATASET_IMPORT_MODE e afins)

```sql
PROCEDURE apex_application_install.add_data_reporter_remap (
    p_schema_from    IN   VARCHAR2,
    p_schema_to      IN   VARCHAR2 );
FUNCTION apex_application_install.get_data_reporter_remap (
    p_schema_from    IN   VARCHAR2 )
    RETURN VARCHAR2;                     -- devolve o próprio schema se não houver mapeamento
PROCEDURE apex_application_install.clear_data_reporter_remap;

PROCEDURE apex_application_install.set_dataset_import_mode (
    p_static_id  IN   VARCHAR2,
    p_mode       IN   t_dataset_import_mode );
FUNCTION apex_application_install.get_dataset_import_mode (
    p_static_id  IN   VARCHAR2 )
    RETURN t_dataset_import_mode;        -- null se não definido
PROCEDURE apex_application_install.clear_dataset_import_modes;
```

- Remap: troca o owner dos objetos do Data Reporter ao importar um dataset ou uma app de relatórios.
- Dataset import mode: por padrão o dataset existente é **mantido** no import; marque `c_dataset_overwrite` para sobrescrever.

```sql
begin
    apex_application_install.set_workspace('EXAMPLE');
    apex_application_install.add_data_reporter_remap ( 'HR', 'DEMO' );
    apex_application_install.add_data_reporter_remap ( 'SALES', 'PROJECTS' );
    apex_application_install.set_dataset_import_mode( p_static_id => 'HR',    p_mode => apex_application_install.c_dataset_keep );
    apex_application_install.set_dataset_import_mode( p_static_id => 'SALES', p_mode => apex_application_install.c_dataset_overwrite );
end;
/
@dr_dataset_example.sql
```

Fonte: [ADD_DATA_REPORTER_REMAP Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_INSTALL-ADD_DATA_REPORTER_REMAP-Procedure.html) · [GET_DATA_REPORTER_REMAP Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_INSTALL.GET_DATA_REPORTER_REMAP-Function.html) · [CLEAR_DATA_REPORTER_REMAP Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_INSTALL.CLEAR_DATA_REPORTER_REMAP-Procedure.html) · [SET_DATASET_IMPORT_MODE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_INSTALL.SET_DATASET_IMPORT_MODE-Function.html) · [GET_DATASET_IMPORT_MODE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_INSTALL.GET_DATASET_IMPORT_MODE-Function.html) · [CLEAR_DATASET_IMPORT_MODES Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_INSTALL.CLEAR_DATASET_IMPORT_MODES-Procedure.html)

### APEX_APPLICATION_INSTALL: SET_THEME_ID e SET_REST_SOURCE_CATALOG_GROUP para plug-ins e catálogos REST

```sql
APEX_APPLICATION_INSTALL.SET_THEME_ID (
    p_theme_id  IN NUMBER );
APEX_APPLICATION_INSTALL.GET_THEME_ID
    RETURN NUMBER;

APEX_APPLICATION_INSTALL.SET_REST_SOURCE_CATALOG_GROUP (
    p_name  IN VARCHAR2 );
APEX_APPLICATION_INSTALL.GET_REST_SOURCE_CATALOG_GROUP
    RETURN VARCHAR2;
```

- `SET_THEME_ID`: sobrescreve o Theme ID dos Template Components (plug-ins) que serão instalados.
- `SET_REST_SOURCE_CATALOG_GROUP`: grupo (que precisa existir no workspace) onde os novos REST Source Catalogs importados serão colocados.

```sql
begin
    apex_application_install.set_theme_id ( p_theme_id => 42 );
end;
/
@plugin.sql

begin
    apex_application_install.set_rest_source_catalog_group ( p_name => 'Financial Services Catalogs' );
end;
/
@rest-service-catalog-financial.sql
```

Fonte: [SET_THEME_ID Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_THEME_ID-Procedure.html) · [GET_THEME_ID Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_THEME_ID-Function.html) · [SET_REST_SOURCE_CATALOG_GROUP Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_REST_SOURCE_CATALOG_GROUP-Procedure.html) · [GET_REST_SOURCE_CATALOG_GROUP Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_REST_SOURCE_CATALOG_GROUP-Function.html)

### APEX_APPLICATION_INSTALL.CLEAR_ALL e REMOVE_APPLICATION: limpar configurações e remover uma app

```sql
APEX_APPLICATION_INSTALL.CLEAR_ALL;

APEX_APPLICATION_INSTALL.REMOVE_APPLICATION (
    p_application_id IN NUMBER );
```

- `CLEAR_ALL` zera todos os valores guardados no package; chame no início de cada script de instalação para não herdar configurações da sessão.
- `REMOVE_APPLICATION` remove a app do workspace e respeita os `SET_%` (workspace, keep sessions).

| Exceção de `REMOVE_APPLICATION` | Quando |
|---|---|
| `WWV_FLOW_API.DELETE_APP_IN_DIFFERENT_WORKSPACE` | A app não está neste workspace. |
| `WWV_FLOW_API.FLOW_NOT_DELETED` | A app não foi apagada. |
| `WWV_FLOW.APP_NOT_FOUND_ERR` | O ID não foi encontrado. |

```sql
begin
    apex_application_install.set_workspace('EXAMPLE');
    apex_application_install.set_keep_sessions(false);
    apex_application_install.remove_application(100);
end;
```

Fonte: [CLEAR_ALL Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CLEAR_ALL-Procedure.html) · [REMOVE_APPLICATION Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_INSTALL.REMOVE_APPLICATION-Procedure.html)

### Configuração de uma instalação anterior "vaza" para a próxima importação na mesma sessão

**Sintoma:** a segunda app instalada no mesmo script/sessão sai com alias, schema, authentication scheme ou workspace da primeira.
**Causa:** os valores dos `SET_%` ficam no estado do package durante a sessão e valem para todo import seguinte.
**Correção:** chame `apex_application_install.clear_all` entre instalações (ou zere o valor específico, como `set_authentication_scheme(p_name => null)`).
**Prevenção:** comece todo script de deploy com `clear_all`.

Fonte: [CLEAR_ALL Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CLEAR_ALL-Procedure.html) · [SET_AUTHENTICATION_SCHEME Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_INSTALL.SET_AUTHENTICATION_SCHEME-Procedure.html)

### Usuários perdem a sessão depois de um deploy (upgrade de app)

**Sintoma:** após reinstalar a app por cima, usuários conectados são deslogados ou perdem dados de session state.
**Causa:** no upgrade, o padrão é apagar as sessões da app (`SET_KEEP_SESSIONS` padrão `FALSE`; parâmetro de instância `KEEP_SESSIONS_ON_UPGRADE` = `N`).
**Correção:** `apex_application_install.set_keep_sessions(true)` antes do `@fNNN.sql`, ou ajuste `KEEP_SESSIONS_ON_UPGRADE` na instância.
**Prevenção:** decidir no script de deploy se sessões devem sobreviver.

Fonte: [SET_KEEP_SESSIONS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_KEEP_SESSIONS-Procedure.html)


## 28. APEX_APPLICATION_ADMIN: alterar atributos de uma aplicação já instalada (status, build, alias, schema, proxy, file storage)

### APEX_APPLICATION_ADMIN: propósito, quando usar e quando não usar

`APEX_APPLICATION_ADMIN` lê e altera atributos de aplicações **já instaladas**, sem reimportar e sem abrir o Builder. Cobre disponibilidade (status: disponível, só desenvolvedores, acesso restrito, indisponível com mensagem/redirect/PL/SQL), build status (`RUN_ONLY` × `RUN_AND_BUILD`), build options, alias, nome, versão, authentication scheme ativo, global notification, image prefix, parsing schema, proxy, Pass ECID, Maximum Scheduler Jobs, remote servers e onde ficam os arquivos da app (banco ou OCI Object Storage).

Quando usar:
- Janela de manutenção: pôr a app `UNAVAILABLE` com mensagem (ou redirecionar) e depois voltar a `AVAILABLE`, por script.
- Travar produção como `RUN_ONLY` depois do deploy.
- Ligar/desligar features marcadas com build options sem reimportar.
- Exibir um aviso global (`#GLOBALNOTIFICATION#`) em todas as páginas.
- Trocar endpoints de remote servers, proxy ou schema depois da instalação.

Quando não usar:
- Durante a importação por script: os equivalentes que valem para o import ficam em `APEX_APPLICATION_INSTALL` (`SET_BUILD_STATUS`, `SET_APPLICATION_ALIAS`, `SET_REMOTE_SERVER`...).
- Para atributos de instância/workspace: `APEX_INSTANCE_ADMIN`.

Pegadinhas gerais:
- Os exemplos oficiais chamam `apex_util.set_workspace('...')` antes de `get/set_application_status`, ou seja, a sessão precisa estar no contexto do workspace dono da app quando chamada de fora do APEX (SQLcl, job).
- O exemplo de `SET_APPLICATION_STATUS` faz `COMMIT` explícito: as alterações são DML em metadados e seguem a transação.
- Para build options e authentication schemes, a busca é pelo **Static ID** e, se não achar, pelo nome (compatibilidade).

Fonte: [APEX_APPLICATION_ADMIN](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_ADMIN.html) · [SET_APPLICATION_STATUS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_ADMIN.SET_APPLICATION_STATUS-Procedure.html)

### APEX_APPLICATION_ADMIN: referência completa de procedures, functions, constantes e tipos

| Nome | Tipo | Descrição |
|---|---|---|
| `t_app_status` + `c_app_available` (`AVAILABLE`), `c_app_available_with_edit_link` (`AVAILABLE_W_EDIT_LINK`), `c_app_available_devs_only` (`DEVELOPERS_ONLY`), `c_app_restricted_access` (`RESTRICTED_ACCESS`), `c_app_unavailable` (`UNAVAILABLE`), `c_app_unavailable_redirect` (`UNAVAILABLE_URL`), `c_app_unavailable_show_plsql` (`UNAVAILABLE_PLSQL`) | subtype `varchar2(30)` + constantes | Status da aplicação. |
| `t_build_status` + `c_build_status_run_and_build` (`RUN_AND_BUILD`), `c_build_status_run_only` (`RUN_ONLY`) | subtype + constantes | Build status. |
| `t_build_option_status` + `c_build_option_status_include` (`INCLUDE`), `c_build_option_status_exclude` (`EXCLUDE`) | subtype + constantes | Status de build option. |
| `t_storage_type` + `c_file_storage_oci` (`OBJECT_STORE`), `c_file_storage_db` (`DB`) | subtype + constantes | Onde guardar os arquivos da app. |
| `GET_APPLICATION_ALIAS` / `SET_APPLICATION_ALIAS` | function / procedure | Alias da app. |
| `GET_APPLICATION_NAME` / `SET_APPLICATION_NAME` | function / procedure | Nome da app. |
| `GET_APPLICATION_STATUS` / `SET_APPLICATION_STATUS` | function / procedure | Disponibilidade da app. |
| `GET_APPLICATION_VERSION` / `SET_APPLICATION_VERSION` | function / procedure | Versão (texto livre). |
| `GET_AUTHENTICATION_SCHEME` / `SET_AUTHENTICATION_SCHEME` | function / procedure | Authentication scheme ativo. |
| `GET_BUILD_OPTION_STATUS` (Signature 1: por ID; Signature 2: por Static ID) | function | Status de uma build option. |
| `SET_BUILD_OPTION_STATUS` (Signature 1: por ID; Signature 2: por Static ID) | procedure | Inclui/exclui uma build option. |
| `GET_BUILD_STATUS` / `SET_BUILD_STATUS` | function / procedure | `RUN_ONLY` ou `RUN_AND_BUILD`. |
| `GET_GLOBAL_NOTIFICATION` / `SET_GLOBAL_NOTIFICATION` | function / procedure | Mensagem de `#GLOBALNOTIFICATION#`. |
| `GET_FILE_STORAGE` / `SET_FILE_STORAGE` | function / procedure | Armazenamento de arquivos (DB ou OCI Object Store). |
| `GET_IMAGE_PREFIX` / `SET_IMAGE_PREFIX` | function / procedure | Image prefix. |
| `GET_MAX_SCHEDULER_JOBS` / `SET_MAX_SCHEDULER_JOBS` | function / procedure | Jobs simultâneos de background page processing. |
| `GET_NO_PROXY_DOMAINS` | function | Domínios fora do proxy. |
| `GET_PROXY_SERVER` / `SET_PROXY_SERVER` | function / procedure | Proxy da app. |
| `GET_PARSING_SCHEMA` / `SET_PARSING_SCHEMA` | function / procedure | Parsing schema (owner). |
| `GET_PASS_ECID` / `SET_PASS_ECID` | function / procedure | Atributo de segurança Pass ECID. |
| `SET_REMOTE_SERVER` | procedure | Base URL, HTTPS host, MySQL, ORDS timezone e IA de um remote server. |

Fonte: [Constants and Data Types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_ADMIN.Constants-and-Data-Types.html) · [APEX_APPLICATION_ADMIN](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_ADMIN.html)

### APEX_APPLICATION_ADMIN.SET_APPLICATION_STATUS: disponibilidade da app (manutenção, acesso restrito, redirect)

```sql
APEX_APPLICATION_ADMIN.SET_APPLICATION_STATUS (
    p_application_id            IN NUMBER,
    p_application_status        IN t_app_status,
    --
    p_allowed_users_list        IN apex_t_varchar2 DEFAULT NULL,
    --
    p_message                   IN VARCHAR2 DEFAULT NULL,
    p_plsql_code                IN VARCHAR2 DEFAULT NULL,
    p_redirect_url              IN VARCHAR2 DEFAULT NULL );

APEX_APPLICATION_ADMIN.GET_APPLICATION_STATUS (
    p_application_id    IN  NUMBER )
    RETURN t_app_status;
```

| Status | Efeito | Parâmetro usado |
|---|---|---|
| `c_app_available` | Disponível sem restrições. | — |
| `c_app_available_with_edit_link` | Disponível; a Developer Toolbar aparece para desenvolvedores. | — |
| `c_app_available_devs_only` | Só desenvolvedores acessam. | — |
| `c_app_restricted_access` | Só os usuários listados acessam. | `p_allowed_users_list` |
| `c_app_unavailable` | Indisponível; mostra mensagem. | `p_message` |
| `c_app_unavailable_redirect` | Indisponível; redireciona. | `p_redirect_url` |
| `c_app_unavailable_show_plsql` | Indisponível; mensagem gerada por bloco PL/SQL. | `p_plsql_code` |

```sql
-- Acesso restrito a USER1 e USER2
begin
  apex_util.set_workspace('YOUR_WORKSPACE_NAME');
  apex_application_admin.set_application_status (
      p_application_id     => 100,
      p_application_status => apex_application_admin.c_app_restricted_access,
      p_allowed_users_list => apex_t_varchar2('USER1','USER2') );
  commit;
end;

-- Janela de manutenção e volta
begin
  apex_util.set_workspace('YOUR_WORKSPACE_NAME');
  apex_application_admin.set_application_status (
      p_application_id     => 100,
      p_application_status => apex_application_admin.c_app_unavailable,
      p_message            => 'Sistema em manutenção. Volte em 30 minutos.' );
  commit;
end;
/
-- ... deploy ...
begin
  apex_util.set_workspace('YOUR_WORKSPACE_NAME');
  apex_application_admin.set_application_status (
      p_application_id     => 100,
      p_application_status => apex_application_admin.c_app_available );
  commit;
end;

-- Ler e reagir
declare
  l_app_status apex_application_admin.t_app_status;
begin
  apex_util.set_workspace('YOUR_WORKSPACE_NAME');
  l_app_status := apex_application_admin.get_application_status ( p_application_id => 100 );
  if l_app_status = apex_application_admin.c_app_available_with_edit_link then
    dbms_output.put_line(l_app_status);
  end if;
end;
```

Fonte: [SET_APPLICATION_STATUS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_ADMIN.SET_APPLICATION_STATUS-Procedure.html) · [GET_APPLICATION_STATUS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_ADMIN.GET_APPLICATION_STATUS-Function.html)

### APEX_APPLICATION_ADMIN.SET_BUILD_STATUS: travar a app em produção como RUN_ONLY

```sql
APEX_APPLICATION_ADMIN.SET_BUILD_STATUS (
    p_application_id IN NUMBER,
    p_build_status   IN t_build_status );

APEX_APPLICATION_ADMIN.GET_BUILD_STATUS (
    p_application_id    IN  NUMBER )
    RETURN t_build_status;
```

`RUN_AND_BUILD`: desenvolvedores e usuários executam e desenvolvem. `RUN_ONLY`: usuários só executam e desenvolvedores não conseguem editar a app.

```sql
begin
    apex_application_admin.set_build_status (
        p_application_id => 100,
        p_build_status   => apex_application_admin.c_build_status_run_only );
end;
/
```

Fonte: [SET_BUILD_STATUS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_ADMIN.SET_BUILD_STATUS-Procedure.html) · [GET_BUILD_STATUS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_ADMIN.GET_BUILD_STATUS-Function.html)

### APEX_APPLICATION_ADMIN.SET_BUILD_OPTION_STATUS e GET_BUILD_OPTION_STATUS: ligar/desligar build options (por ID ou Static ID)

```sql
-- Signature 1: por ID
APEX_APPLICATION_ADMIN.SET_BUILD_OPTION_STATUS (
    p_application_id   IN NUMBER,
    p_id               IN NUMBER,
    p_build_status     IN t_build_option_status );
APEX_APPLICATION_ADMIN.GET_BUILD_OPTION_STATUS (
    p_application_id   IN NUMBER,
    p_id               IN NUMBER )
RETURN t_build_option_status;

-- Signature 2: por Static ID
APEX_APPLICATION_ADMIN.SET_BUILD_OPTION_STATUS (
    p_application_id     IN   NUMBER,
    p_static_id          IN   VARCHAR2,
    p_build_status       IN   t_build_option_status );
APEX_APPLICATION_ADMIN.GET_BUILD_OPTION_STATUS (
    p_application_id    IN NUMBER,
    p_build_option_name IN VARCHAR2 )      -- recebe o Static ID
RETURN t_build_option_status;
```

Valores: `c_build_option_status_include` / `c_build_option_status_exclude`. Na leitura por Static ID, se não houver correspondência, o APEX tenta pelo nome da build option (compatibilidade). Repare que o parâmetro da Signature 2 de `GET_` se chama `p_build_option_name`, mas recebe o Static ID.

```sql
begin
    apex_application_admin.set_build_option_status (
        p_application_id => 100,
        p_static_id      => 'test_apps',
        p_build_status   => apex_application_admin.c_build_option_status_include );
    htp.p( apex_application_admin.get_build_option_status (
               p_application_id    => 100,
               p_build_option_name => 'test_apps' ) );
end;
```

Pegadinha: o exemplo oficial de `SET_BUILD_OPTION_STATUS` (Signature 2) omite a vírgula depois de `p_static_id => 'test_apps'`; corrigido acima.

Fonte: [SET_BUILD_OPTION_STATUS Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_ADMIN.SET_BUILD_OPTION_STATUS-Procedure-Signature-1.html) · [SET_BUILD_OPTION_STATUS Procedure Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_ADMIN.SET_BUILD_OPTION_STATUS-Procedure-Signature-2.html) · [GET_BUILD_OPTION_STATUS Function Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_ADMIN.GET_BUILD_OPTION_STATUS-Function-Signature-1.html) · [GET_BUILD_OPTION_STATUS Function Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_ADMIN.GET_BUILD_OPTION_STATUS-Function-Signature-2.html)

### APEX_APPLICATION_ADMIN.SET_AUTHENTICATION_SCHEME: trocar o authentication scheme ativo de uma app instalada

```sql
APEX_APPLICATION_ADMIN.SET_AUTHENTICATION_SCHEME (
    p_application_id IN NUMBER,
    p_name           IN VARCHAR2 );
APEX_APPLICATION_ADMIN.GET_AUTHENTICATION_SCHEME (
    p_application_id    IN  NUMBER )
    RETURN VARCHAR2;
```

Informe o **Static ID** do scheme (se não achar, o APEX procura pelo nome). O scheme precisa existir na app; `p_name` nulo mantém o ativo.

```sql
begin
    apex_application_admin.set_authentication_scheme (
        p_application_id => 100,
        p_name           => 'SSO-Production' );
end;
```

Fonte: [SET_AUTHENTICATION_SCHEME Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_ADMIN.SET_AUTHENTICATION_SCHEME-Procedure.html) · [GET_AUTHENTICATION_SCHEME Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_ADMIN.GET_AUTHENTICATION_SCHEME-Function.html)

### APEX_APPLICATION_ADMIN: alias, nome, versão e global notification (SET/GET_APPLICATION_ALIAS, _NAME, _VERSION, _GLOBAL_NOTIFICATION)

```sql
APEX_APPLICATION_ADMIN.SET_APPLICATION_ALIAS (
    p_application_id    IN NUMBER,
    p_application_alias IN VARCHAR2 );   -- até 255, não nulo
APEX_APPLICATION_ADMIN.GET_APPLICATION_ALIAS ( p_application_id IN NUMBER ) RETURN VARCHAR2;

APEX_APPLICATION_ADMIN.SET_APPLICATION_NAME (
    p_application_id   IN NUMBER,
    p_application_name IN VARCHAR2 );    -- até 255, não nulo
APEX_APPLICATION_ADMIN.GET_APPLICATION_NAME ( p_application_id IN NUMBER ) RETURN VARCHAR2;

APEX_APPLICATION_ADMIN.SET_APPLICATION_VERSION (
   p_application_id IN NUMBER,
   p_version        IN VARCHAR2 );       -- até 255
APEX_APPLICATION_ADMIN.GET_APPLICATION_VERSION ( p_application_id IN NUMBER ) RETURN VARCHAR2;

APEX_APPLICATION_ADMIN.SET_GLOBAL_NOTIFICATION (
    p_application_id              IN NUMBER,
    p_global_notification_message IN VARCHAR2 );
APEX_APPLICATION_ADMIN.GET_GLOBAL_NOTIFICATION ( p_application_id IN NUMBER ) RETURN VARCHAR2;
```

A global notification é o texto exibido onde o page template usa a substituição `#GLOBALNOTIFICATION#`; serve para avisos como "manutenção hoje às 22h".

```sql
begin
    apex_application_admin.set_application_alias  ( p_application_id => 100, p_application_alias => 'EXECUTIVE-DASHBOARD' );
    apex_application_admin.set_application_name   ( p_application_id => 100, p_application_name  => 'Executive Dashboard' );
    apex_application_admin.set_application_version( p_application_id => 100, p_version           => 'Release 1.0' );
    apex_application_admin.set_global_notification( p_application_id => 100,
        p_global_notification_message => 'Manutenção programada hoje às 22h.' );
end;
select apex_application_admin.get_application_version(100) from sys.dual;
```

Fonte: [SET_APPLICATION_ALIAS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_ADMIN.SET_APPLICATION_ALIAS-Procedure.html) · [GET_APPLICATION_ALIAS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_ADMIN.GET_APPLICATION_ALIAS-Function.html) · [SET_APPLICATION_NAME Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_ADMIN.SET_APPLICATION_NAME-Procedure.html) · [GET_APPLICATION_NAME Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_ADMIN.GET_APPLICATION_NAME-Function.html) · [SET_APPLICATION_VERSION Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_ADMIN.SET_APPLICATION_VERSION-Procedure.html) · [GET_APPLICATION_VERSION Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_ADMIN.GET_APPLICATION_VERSION-Function.html) · [SET_GLOBAL_NOTIFICATION Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_ADMIN.SET_GLOBAL_NOTIFICATION-Procedure.html) · [GET_GLOBAL_NOTIFICATION Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_ADMIN.GET_GLOBAL_NOTIFICATION-Function.html)

### APEX_APPLICATION_ADMIN.SET_PARSING_SCHEMA: trocar o owner de uma app instalada

```sql
APEX_APPLICATION_ADMIN.SET_PARSING_SCHEMA (
    p_application_id IN NUMBER,
    p_schema         IN VARCHAR2 );
APEX_APPLICATION_ADMIN.GET_PARSING_SCHEMA (
    p_application_id    IN  NUMBER )
    RETURN VARCHAR2;
```

O usuário do schema precisa existir e já estar mapeado ao workspace (ver `APEX_INSTANCE_ADMIN.ADD_SCHEMA`).

```sql
begin
    apex_application_admin.set_parsing_schema ( p_application_id => 100, p_schema => 'EXAMPLE' );
end;
```

Fonte: [SET_PARSING_SCHEMA Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_ADMIN.SET_PARSING_SCHEMA-Procedure.html) · [GET_PARSING_SCHEMA Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_ADMIN.GET_PARSING_SCHEMA-Function.html)

### APEX_APPLICATION_ADMIN: image prefix, proxy, Pass ECID e Maximum Scheduler Jobs

```sql
APEX_APPLICATION_ADMIN.SET_IMAGE_PREFIX (
    p_application_id IN NUMBER,
    p_image_prefix   IN VARCHAR2 );           -- até 255
APEX_APPLICATION_ADMIN.GET_IMAGE_PREFIX ( p_application_id IN NUMBER ) RETURN VARCHAR2;

APEX_APPLICATION_ADMIN.SET_PROXY_SERVER (
    p_application_id   IN NUMBER,
    p_proxy_server     IN VARCHAR2 ,
    p_no_proxy_domains IN VARCHAR2 DEFAULT NULL );
APEX_APPLICATION_ADMIN.GET_PROXY_SERVER     ( p_application_id IN NUMBER ) RETURN VARCHAR2;
APEX_APPLICATION_ADMIN.GET_NO_PROXY_DOMAINS ( p_application_id IN NUMBER ) RETURN VARCHAR2;

APEX_APPLICATION_ADMIN.SET_PASS_ECID (
    p_application_id IN NUMBER,
    p_pass_ecid      IN BOOLEAN );
APEX_APPLICATION_ADMIN.GET_PASS_ECID ( p_application_id IN NUMBER ) RETURN BOOLEAN;

APEX_APPLICATION_ADMIN.SET_MAX_SCHEDULER_JOBS (
    p_application_id        IN NUMBER,
    p_max_scheduler_jobs    IN NUMBER );
APEX_APPLICATION_ADMIN.GET_MAX_SCHEDULER_JOBS ( p_application_id IN NUMBER ) RETURN NUMBER;
```

| Atributo | Regras |
|---|---|
| Image prefix | Até 255 caracteres (ex.: `/static/`). |
| Proxy server | Sem default, menos de 255 caracteres, sem prefixo de protocolo (`www-proxy.example.com`). |
| No proxy domains | Lista separada por vírgula de domínios que não usam o proxy, até 500 caracteres. |
| Pass ECID | Atributo de segurança: `TRUE` envia o Execution Context ID a web services externos (rastreamento ponta a ponta). |
| Maximum Scheduler Jobs | Quantos scheduler jobs podem rodar ao mesmo tempo para executar background page processes da app. |

```sql
begin
    apex_application_admin.set_image_prefix ( p_application_id => 100, p_image_prefix => '/static/' );
    apex_application_admin.set_proxy_server ( p_application_id => 100, p_proxy_server => 'www-proxy.example.com' );
    apex_application_admin.set_pass_ecid(100, true);
    apex_application_admin.set_max_scheduler_jobs(100, 5);
end;
```

Pegadinha: o exemplo oficial de `SET_PROXY_SERVER` não passa `p_application_id`, que é obrigatório na assinatura; inclua-o.

Fonte: [SET_IMAGE_PREFIX Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_ADMIN.SET_IMAGE_PREFIX-Procedure.html) · [GET_IMAGE_PREFIX Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_ADMIN.GET_IMAGE_PREFIX-Function.html) · [SET_PROXY_SERVER Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_ADMIN.SET_PROXY_SERVER-Procedure.html) · [GET_PROXY_SERVER Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_ADMIN.GET_PROXY_SERVER-Function.html) · [GET_NO_PROXY_DOMAINS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_ADMIN.GET_NO_PROXY_DOMAINS-Function.html) · [SET_PASS_ECID Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_ADMIN.SET_PASS_ECID-Procedure.html) · [GET_PASS_ECID Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_ADMIN.GET_PASS_ECID-Function.html) · [SET_MAX_SCHEDULER_JOBS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_ADMIN.SET_MAX_SCHEDULER_JOBS-Procedure.html) · [GET_MAX_SCHEDULER_JOBS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_ADMIN.GET_MAX_SCHEDULER_JOBS-Function.html)

### APEX_APPLICATION_ADMIN.SET_REMOTE_SERVER: alterar Base URL, HTTPS host e IA de remote servers já instalados

```sql
APEX_APPLICATION_ADMIN.SET_REMOTE_SERVER (
    p_static_id        IN VARCHAR2,
    p_base_url         IN VARCHAR2,
    p_https_host       IN VARCHAR2 DEFAULT NULL,
    --
    p_default_database IN VARCHAR2 DEFAULT NULL,
    p_mysql_sql_modes  IN VARCHAR2 DEFAULT NULL,
    --
    p_ords_timezone    IN VARCHAR2 DEFAULT NULL,
    --
    p_ai_model_name    IN VARCHAR2 DEFAULT NULL,
    p_ai_http_headers  IN CLOB     DEFAULT NULL,
    p_ai_attributes    IN CLOB     DEFAULT NULL,
    p_ai_max_tokens    IN NUMBER   DEFAULT NULL );
```

| Parâmetro | Significado |
|---|---|
| `p_static_id` | Static ID do remote server. |
| `p_base_url` | Novo Base URL. |
| `p_https_host` | Novo HTTPS host. |
| `p_default_database` | Database padrão (só MySQL por enquanto). |
| `p_mysql_sql_modes` | SQL modes para MySQL. |
| `p_ords_timezone` | Fuso do ORDS remoto; só relevante para REST-Enabled SQL quando o ORDS remoto não roda em UTC. |
| `p_ai_model_name` / `p_ai_http_headers` / `p_ai_attributes` | Modelo, headers e atributos JSON para o serviço de IA generativa. |
| `p_ai_max_tokens` | Máximo de tokens numa janela de 24 h para esse serviço. |

Diferente das demais rotinas do package, a assinatura **não tem `p_application_id`**: o remote server é identificado só pelo Static ID.

```sql
begin
    apex_application_admin.set_remote_server(
        p_static_id => 'MY_REMOTE_SERVER',
        p_base_url  => 'http://production.example.com' );
end;
```

Fonte: [SET_REMOTE_SERVER Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_ADMIN.SET_REMOTE_SERVER-Procedure.html)

### APEX_APPLICATION_ADMIN.SET_FILE_STORAGE: guardar arquivos da app no banco ou no OCI Object Storage

```sql
APEX_APPLICATION_ADMIN.SET_FILE_STORAGE (
    p_application_id            IN  NUMBER,
    p_storage_type              t_storage_type,
    p_remote_server_static_id   IN  VARCHAR2 DEFAULT NULL,
    p_migrate_files             IN  BOOLEAN DEFAULT FALSE );

APEX_APPLICATION_ADMIN.GET_FILE_STORAGE (
    p_application_id    IN  NUMBER )
RETURN VARCHAR2;
```

| Parâmetro | Significado |
|---|---|
| `p_application_id` | ID da app. |
| `p_storage_type` | `c_file_storage_db` (`DB`) ou `c_file_storage_oci` (`OBJECT_STORE`). |
| `p_remote_server_static_id` | Quando o storage é OCI, é preciso informar o Static ID do remote server que aponta para o bucket. |
| `p_migrate_files` | `TRUE`: envia os arquivos da app contidos no export para o storage indicado. |

`GET_FILE_STORAGE` devolve o Static ID do remote server quando a app usa OCI e `NULL` quando usa o banco.

```sql
begin
    apex_application_admin.set_file_storage(
        p_application_id          => 100,
        p_storage_type            => apex_application_admin.c_file_storage_oci,
        p_remote_server_static_id => 'bucket-app-files-myapp',
        p_migrate_files           => true );
end;
select apex_application_admin.get_file_storage(100) from sys.dual;
```

Fonte: [SET_FILE_STORAGE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_FILE_STORAGE-Procedure.html) · [GET_FILE_STORAGE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_FILE_STORAGE-Function.html)


## 29. APEX_INSTANCE_ADMIN: administrar a instância APEX por PL/SQL (parâmetros, e-mail, workspaces, schemas, logs)

### APEX_INSTANCE_ADMIN: propósito, quando usar e quando não usar

`APEX_INSTANCE_ADMIN` é a API de administração do ambiente de runtime do APEX. Com ela se leem e alteram **parâmetros de instância** (e-mail/SMTP, wallet, impressão de relatórios, segurança, senhas, HTTPS, autenticação do Builder, SAML/Social, limites, logs, upgrades no Autonomous), **parâmetros de workspace**, se criam e removem workspaces, se mapeiam schemas a workspaces, se restringem schemas, se gerenciam web entry points, credenciais de nuvem, usuários administradores, relatórios salvos de Interactive Report e logs.

Privilégios: só pode ser executado por `SYS`, `SYSTEM` ou usuários com a role `APEX_ADMINISTRATOR_ROLE`. Não é uma API para código de aplicação comum: o parsing schema de uma app não deve precisar dela.

Quando usar:
- Configurar a instância por script (SMTP, wallet, proxy, HTTPS, política de senha) em vez de clicar em Administration Services.
- Provisionar ambientes: `ADD_WORKSPACE`, `ADD_SCHEMA`, `SET_WORKSPACE_PARAMETER`.
- Diagnosticar e-mail (`VALIDATE_EMAIL_CONFIG`) e travar envio em bancos clonados (`DB_SIGNATURE`).
- Higiene: `TRUNCATE_LOG`, `SET_LOG_SWITCH_INTERVAL`, `REMOVE_SAVED_REPORTS`.

Quando não usar:
- Para alterar atributos de uma app instalada: `APEX_APPLICATION_ADMIN`. Para instalar: `APEX_APPLICATION_INSTALL`.
- Em ambientes gerenciados onde você não tem `APEX_ADMINISTRATOR_ROLE` (ex.: workspace comum de desenvolvimento): as chamadas falharão por privilégio.

Pegadinhas gerais:
- **`SET_PARAMETER` só tem efeito depois de `COMMIT`.** Quase todos os exemplos oficiais terminam com `COMMIT`.
- Os valores atuais podem ser consultados na view `APEX_INSTANCE_PARAMETERS`, exceto parâmetros que contêm senha.
- Parâmetros de workspace sobrescrevem o de mesmo nome da instância para aquele workspace.

Fonte: [APEX_INSTANCE_ADMIN](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_INSTANCE_ADMIN.html) · [Available Parameter Values](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_INSTANCE_ADMIN.Available-Parameter-Values.html) · [SET_PARAMETER Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_PARAMETER-Procedure.html)

### APEX_INSTANCE_ADMIN: referência completa de procedures e functions

| Nome | Tipo | Descrição |
|---|---|---|
| `ADD_AUTO_PROV_RESTRICTIONS` | procedure | Adiciona padrões de e-mail bloqueados para auto/self-provisioning de workspaces. |
| `ADD_SCHEMA` | procedure | Mapeia um schema a um workspace (opcionalmente concedendo privilégios do APEX). |
| `ADD_WEB_ENTRY_POINT` | procedure | Libera uma procedure pública para ser chamada pela URL. |
| `ADD_WORKSPACE` | procedure | Cria um workspace. |
| `CREATE_CLOUD_CREDENTIAL` | procedure | Cria credencial OCI API Key no `DBMS_CLOUD`. |
| `CREATE_OR_UPDATE_ADMIN_USER` | procedure | Cria/desbloqueia um administrador da instância (equivalente a `apxchpwd.sql`). |
| `CREATE_SCHEMA_EXCEPTION` | procedure | Permite atribuir um schema restrito a um workspace específico. |
| `DB_SIGNATURE` | function | Calcula a assinatura atual do banco. |
| `DROP_CLOUD_CREDENTIAL` | procedure | Remove credencial OCI do `DBMS_CLOUD`. |
| `FREE_WORKSPACE_APP_IDS` | procedure | Desfaz a reserva de IDs de app de um workspace. |
| `GET_PARAMETER` | function | Lê um parâmetro de instância. |
| `GET_SCHEMAS` | function | Lista (separada por vírgula) os schemas mapeados a um workspace. |
| `GET_WORKSPACE_PARAMETER` | "procedure" (usada como function) | Lê um parâmetro de workspace. |
| `GRANT_EXTENSION_WORKSPACE` | procedure | Concede acesso a um workspace de extensões (Builder Extension menu). |
| `IS_DB_SIGNATURE_VALID` | function | `TRUE` se `DB_SIGNATURE` confere com o banco (ou não está definido). |
| `REMOVE_APPLICATION` | procedure | Remove uma app da instância. |
| `REMOVE_AUTO_PROV_RESTRICTIONS` | procedure | Remove padrões de e-mail bloqueados. |
| `REMOVE_SAVED_REPORT` | procedure | Remove um relatório salvo de IR de um usuário. |
| `REMOVE_SAVED_REPORTS` | procedure | Remove todos os relatórios salvos de IR de uma app ou da instância. |
| `REMOVE_SCHEMA` | procedure | Remove o mapeamento schema–workspace. |
| `REMOVE_SCHEMA_EXCEPTION` | procedure | Remove uma exceção de schema restrito para um workspace. |
| `REMOVE_SCHEMA_EXCEPTIONS` | procedure | Remove todas as exceções de um schema restrito. |
| `REMOVE_SUBSCRIPTION` | procedure | Remove uma subscription de Interactive Report. |
| `REMOVE_WEB_ENTRY_POINT` | procedure | Retira uma procedure da lista de chamáveis pela URL. |
| `REMOVE_WORKSPACE` | procedure | Remove um workspace (opcionalmente usuários de banco e tablespaces). |
| `REMOVE_WORKSPACE_EXCEPTIONS` | procedure | Remove todas as exceções de schemas restritos de um workspace. |
| `RESERVE_WORKSPACE_APP_IDS` | procedure | Reserva permanentemente os IDs de app de um workspace. |
| `RESTRICT_SCHEMA` | procedure | Proíbe atribuir um schema a workspaces. |
| `REVOKE_EXTENSION_WORKSPACE` | procedure | Revoga a concessão a um workspace de extensões. |
| `SET_LOG_SWITCH_INTERVAL` | procedure | Define o intervalo de troca de cada log do APEX. |
| `SET_PARAMETER` | procedure | Define um parâmetro de instância. |
| `SET_WORKSPACE_CONSUMER_GROUP` | procedure | Associa um Resource Manager Consumer Group a um workspace. |
| `SET_WORKSPACE_PARAMETER` | procedure | Define um parâmetro de workspace. |
| `TRUNCATE_LOG` | procedure | Apaga as entradas de um log. |
| `UNLOCK_USER` | procedure | Desbloqueia um usuário de workspace (e opcionalmente troca a senha). |
| `UNRESTRICT_SCHEMA` | procedure | Volta a permitir atribuir um schema a workspaces. |
| `VALIDATE_EMAIL_CONFIG` | procedure | Testa a conexão com o servidor de e-mail configurado. |

Parâmetro `p_methods` de `ADD_WEB_ENTRY_POINT` está **(Deprecated)**.

Fonte: [APEX_INSTANCE_ADMIN](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_INSTANCE_ADMIN.html)

### APEX_INSTANCE_ADMIN.SET_PARAMETER e GET_PARAMETER: ler e alterar parâmetros de instância

```sql
APEX_INSTANCE_ADMIN.SET_PARAMETER (
    p_parameter     IN VARCHAR2,
    p_value         IN VARCHAR2 DEFAULT 'N',
    p_force         IN BOOLEAN  DEFAULT FALSE );

APEX_INSTANCE_ADMIN.GET_PARAMETER (
    p_parameter     IN VARCHAR2 )
RETURN VARCHAR2;
```

| Parâmetro | Significado |
|---|---|
| `p_parameter` | Nome do parâmetro de instância (ver tabelas abaixo). |
| `p_value` | Valor. **Padrão `'N'`**: chamar sem `p_value` grava `N`. |
| `p_force` | `FALSE` (padrão). `TRUE` aceita valores que não passam em critérios de qualidade (só validação básica de tipo). Só se aplica a `SAML_APEX_CERTIFICATE`, `SAML_APEX_CERTIFICATE2`, `SAML_IP_SIGNING_CERTIFICATE`, `SAML_IP_SIGNING_CERTIFICATE2`: força gravar o certificado mesmo se a checagem de qualidade falhar (ex.: certificado SHA-1 ou com menos de 2048 bits; nesse caso `ALLOW_HASH_FUNCTIONS` também precisa admitir SHA-1). |

```sql
begin
    apex_instance_admin.set_parameter('SMTP_HOST_ADDRESS', 'mail.example.com');
    commit;   -- sem commit a mudança não vale
end;

declare
    l_val varchar2(4000);
begin
    l_val := apex_instance_admin.get_parameter('SMTP_HOST_ADDRESS');
    dbms_output.put_line('SMTP host: ' || l_val);
end;

-- Consultar vários de uma vez (senhas não aparecem)
select name, value from apex_instance_parameters where name like 'SMTP%';
```

Fonte: [SET_PARAMETER Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_PARAMETER-Procedure.html) · [GET_PARAMETER Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_PARAMETER-Function.html) · [Available Parameter Values](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_INSTANCE_ADMIN.Available-Parameter-Values.html)

### APEX_INSTANCE_ADMIN.SET_PARAMETER não tem efeito

**Sintoma:** `set_parameter` roda sem erro, mas o comportamento da instância não muda e `get_parameter` em outra sessão mostra o valor antigo.
**Causa:** a alteração só passa a valer depois de `COMMIT`.
**Correção:** faça `COMMIT` logo após `set_parameter`.
**Prevenção:** sempre inclua `p_value` explicitamente: o padrão é `'N'`, então omitir o valor desliga/zera o parâmetro.

Fonte: [SET_PARAMETER Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_PARAMETER-Procedure.html)

### APEX_INSTANCE_ADMIN: parâmetros de e-mail (SMTP_*, EMAIL_*, WORKSPACE_EMAIL_MAXIMUM)

Todos são de instância (via `SET_PARAMETER`), salvo indicação.

| Parâmetro | Função / valores |
|---|---|
| `SMTP_HOST_ADDRESS` | Endereço do servidor SMTP (ou relay). Padrão `localhost`. |
| `SMTP_HOST_PORT` | Porta SMTP. Padrão `25`. |
| `SMTP_USERNAME` | Usuário para autenticar no SMTP (padrão `NULL` = sem autenticação). A partir do banco 11.2.0.2 usa o `AUTH` de `UTL_MAIL`, que negocia o modo de autenticação. |
| `SMTP_PASSWORD` | Senha do SMTP (junto com `SMTP_USERNAME`). Não aparece em `APEX_INSTANCE_PARAMETERS`. |
| `SMTP_TLS_MODE` | `N` (padrão, sem criptografia), `Y` (conexão criptografada antes de enviar dados), `STARTTLS` (envia `EHLO [SMTP_CLIENT_DOMAIN]` e `STARTTLS` antes de criptografar). |
| `SMTP_SECURE_HOST` | Hosts aceitáveis apresentados pelo certificado quando há TLS. |
| `SMTP_CLIENT_DOMAIN` | Domínio enviado no HELO/EHLO; se vazio usa o do servidor. |
| `SMTP_FROM` | Remetente de e-mails administrativos (aprovação de provisionamento, reset de senha). |
| `SMTP_ENVELOPE_FROM` | Endereço "MAIL FROM" do envelope SMTP; se vazio, `APEX_MAIL` usa `p_from`. |
| `SMTP_CONNECTION_REUSE_COUNT` | Quantos e-mails o job envia antes de reabrir a conexão SMTP (padrão 1). |
| `SMTP_RETRY_PERMANENT_ERROR_PATTERNS` | Regex (uma por linha) de "erros permanentes" do SMTP que devem ser tratados como temporários (reenvio no próximo ciclo do job). Padrão `.*` = tudo é temporário. Erro tratado como permanente sai da fila na hora. |
| `SMTP_ALLOW_WORKSPACE_CREDENTIALS` | `Y`: workspaces podem usar sua própria Web Credential no SMTP; `N`: só a configuração da instância. |
| `SMTP_CREDENTIAL_STATIC_ID` | **Só workspace**: Static ID da Web Credential usada para autenticar no SMTP ao enviar e-mails desse workspace. |
| `SMTP_REST_EMAIL_MODE` | `N` (padrão): entrega via relay SMTP. Caso contrário, entrega via Oracle Cloud Notification Service. |
| `SMTP_REST_EMAIL_URL` | URL do Oracle Cloud Notification Service (só quando `SMTP_REST_EMAIL_MODE = Y`). |
| `EMAIL_ATTACHMENT_MAX_SIZE_MB` | Tamanho máximo (MB) de um anexo enviado por `APEX_MAIL` ou pelo processo *Send E-Mail*. |
| `EMAIL_IMAGES_URL` | URL completa do diretório de imagens (com barra final), usada em e-mails gerados pelo APEX. Ex.: `http://example_server/i/`. |
| `EMAIL_INSTANCE_URL` | URL completa da instância (com barra final após o DAD), usada em e-mails do sistema. |
| `MAX_MAIL_QUEUE_ROWS` | Quantas mensagens por workspace são processadas da fila a cada execução do job `ORACLE_APEX_MAIL_QUEUE`. |
| `WORKSPACE_EMAIL_MAXIMUM` | Instância **e** workspace: máximo de e-mails por workspace via `APEX_MAIL` em 24 h. Padrão 1000. |
| `DB_SIGNATURE` | Desativa envio de e-mails em bancos clonados (ver seção própria). |

```sql
begin
    apex_instance_admin.set_parameter('SMTP_HOST_ADDRESS', 'smtp.example.com');
    apex_instance_admin.set_parameter('SMTP_HOST_PORT',    '587');
    apex_instance_admin.set_parameter('SMTP_TLS_MODE',     'STARTTLS');
    apex_instance_admin.set_parameter('SMTP_USERNAME',     'apex@example.com');
    apex_instance_admin.set_parameter('SMTP_PASSWORD',     '********');
    apex_instance_admin.set_parameter('SMTP_FROM',         'apex@example.com');
    commit;
    apex_instance_admin.validate_email_config;  -- erro se não conectar
end;
```

Fonte: [Available Parameter Values](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_INSTANCE_ADMIN.Available-Parameter-Values.html) · [VALIDATE_EMAIL_CONFIG Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/VALIDATE_EMAIL_CONFIG-Procedure.html)

### APEX_INSTANCE_ADMIN.VALIDATE_EMAIL_CONFIG: testar a conexão com o servidor de e-mail

```sql
APEX_INSTANCE_ADMIN.VALIDATE_EMAIL_CONFIG;
```

Sem parâmetros. Tenta conectar ao servidor de e-mail configurado na instância; termina normalmente se conectar e levanta erro se não conseguir.

```sql
begin
    apex_instance_admin.validate_email_config;
end;
```

Fonte: [VALIDATE_EMAIL_CONFIG Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/VALIDATE_EMAIL_CONFIG-Procedure.html)

### APEX_INSTANCE_ADMIN.VALIDATE_EMAIL_CONFIG levanta erro: e-mails do APEX não saem

**Sintoma:** `apex_instance_admin.validate_email_config` levanta exceção; e-mails de `APEX_MAIL` ficam na fila.
**Causa:** segundo a doc, as causas típicas são: parâmetros `SMTP_*` incorretos, falta de Network ACL para o host/porta do SMTP, certificado SSL ausente no Oracle Wallet (quando há TLS) ou problema do lado do servidor de e-mail.
**Correção:** revise `SMTP_HOST_ADDRESS`, `SMTP_HOST_PORT`, `SMTP_TLS_MODE`, `SMTP_USERNAME`/`SMTP_PASSWORD`; crie a ACL de rede; importe o certificado no wallet (`WALLET_PATH`/`WALLET_PWD`); faça `COMMIT` e rode `validate_email_config` de novo até passar.
**Prevenção:** rode `validate_email_config` em todo script de configuração de ambiente.

Fonte: [VALIDATE_EMAIL_CONFIG Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/VALIDATE_EMAIL_CONFIG-Procedure.html) · [Available Parameter Values](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_INSTANCE_ADMIN.Available-Parameter-Values.html)

### APEX_INSTANCE_ADMIN.DB_SIGNATURE e IS_DB_SIGNATURE_VALID: não enviar e-mails a partir de banco clonado

```sql
APEX_INSTANCE_ADMIN.DB_SIGNATURE
    RETURN VARCHAR2;

APEX_INSTANCE_ADMIN.IS_DB_SIGNATURE_VALID
    RETURN BOOLEAN;
```

Mecanismo: grave no parâmetro de instância `DB_SIGNATURE` a assinatura atual do banco. Se o banco for clonado (ex.: produção copiada para homologação), a assinatura calculada passa a diferir do valor gravado e o APEX desativa recursos como o envio de e-mails. `IS_DB_SIGNATURE_VALID` devolve `TRUE` quando o parâmetro confere com `db_signature` **ou** quando o parâmetro não está definido (padrão `NULL`, nada desativado).

```sql
begin
     apex_instance_admin.set_parameter (
         p_parameter => 'DB_SIGNATURE',
         p_value     => apex_instance_admin.db_signature );
     commit;
end;

begin
    sys.dbms_output.put_line (
        case when apex_instance_admin.is_db_signature_valid
        then 'assinatura válida, recursos habilitados'
        else 'assinatura difere (banco clonado), recursos desabilitados'
        end );
end;
```

Fonte: [DB_SIGNATURE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/DB_SIGNATURE-Function.html) · [IS_DB_SIGNATURE_VALID Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/IS_DB_SIGNATURE_VALID-Function.html) · [Available Parameter Values](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_INSTANCE_ADMIN.Available-Parameter-Values.html)

### APEX_INSTANCE_ADMIN: parâmetros ALLOW_* e de recursos habilitáveis

| Parâmetro | Função / valores |
|---|---|
| `ALLOW_DB_MONITOR` | `Y` habilita o monitoramento de banco no SQL Workshop; `N` (padrão) desabilita. |
| `ALLOW_EXTERNAL_LINKS` | `Y` (padrão) mostra links externos no Builder; `N` para ambientes desconectados. |
| `ALLOW_HASH_FUNCTIONS` | Lista de algoritmos de hash suportados (padrão `SH256`,`SH384`,`SH512`). |
| `ALLOW_PERSISTENT_AUTHENTICATION` | `Y` habilita a API de persistent authentication para todas as apps. |
| `ALLOW_PUBLIC_FILE_UPLOAD` | `Y` permite upload de arquivo sem autenticação; `N` (padrão) não. |
| `ALLOW_RAS` | `Y` habilita Real Application Security nas apps; `N` (padrão) não. |
| `ALLOW_REST` | `Y` (padrão) deixa expor report regions como RESTful services. |
| `ALLOW_SQL_DEVELOPER_WEB` | `Y` permite abrir o SQL Developer Web pelo menu do Builder; padrão `N`. |
| `ALLOW_HOSTING_EXTENSIONS` | Instância/workspace. Padrão `N`; `Y` deixa o workspace publicar Builder Extension apps. |
| `ALLOW_HOSTNAMES` | Instância/workspace. Se definido, a app só abre se o hostname da URL contiver esse valor. |
| `ENABLE_DICTATION` | `Y` habilita a Web Speech API (fala → texto) em componentes suportados. |
| `ENABLE_LEGACY_WEB_ENTRY_POINTS` | `Y` (padrão `N`) permite chamar pela URL procedures de versões antigas (ex.: `HTMLDB_UTIL.%`). |
| `ENABLE_TRANSACTIONAL_SQL` | `Y` (padrão) habilita comandos SQL transacionais na instância. |
| `PLSQL_EDITING` | `Y` (padrão) permite editar/compilar PL/SQL no Object Browser. |
| `RESTFUL_SERVICES_ENABLED` | `Y` (padrão) habilita o desenvolvimento de RESTful services. |
| `TRACING_ENABLED` | `Y` (padrão): app com Debug habilitado pode gerar trace no servidor com `&p_trace=YES`. |
| `CLONE_SESSION_ENABLED` | `Y` (padrão): o usuário pode criar várias sessões no navegador. |
| `GETTING_STARTED_ENABLED` | `Y` mostra informações de "getting started". |
| `CHECK_FOR_UPDATES` | `N` desliga a checagem de updates do APEX/ORDS para toda a instância. Padrão `Y`. |
| `MLE_LANGUAGES` | Linguagens MLE disponíveis (padrão `JAVASCRIPT`; vazio = só SQL e PL/SQL). Os schemas ainda precisam dos grants de MLE (`EXECUTE ON sys.JAVASCRIPT` ≥21c; `CREATE MLE` ≥26ai para environments/modules). |
| `INSTANCE_DBMS_CREDENTIAL_ENABLED` | `Y`: credenciais de banco acessíveis ao engine (`APEX_NNNNNN`) podem ser usadas em todos os workspaces. |
| `AI_IS_ENABLED` | Instância/workspace. `Y` (padrão) permite configurar AI Services; `N` desliga IA em todos os workspaces. |

Fonte: [Available Parameter Values](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_INSTANCE_ADMIN.Available-Parameter-Values.html)

### APEX_INSTANCE_ADMIN: parâmetros de segurança HTTP, HTTPS, cookies e acesso (REQUIRE_*, RESTRICT_*, HTTP_*)

| Parâmetro | Função / valores |
|---|---|
| `REQUIRE_HTTPS` | `A` força HTTPS em toda a instância; `I` só no Builder e na administração; `N` aceita HTTP e HTTPS. (Também é possível exigir HTTPS por app via atributo Secure do cookie.) |
| `HTTP_STS_MAX_AGE` | Só com `REQUIRE_HTTPS = A`: emite `Strict-Transport-Security` com `max-age` e redireciona HTTP para HTTPS. |
| `REQUIRE_OUT_HTTPS` | `Y`: todo tráfego HTTP de saída deve ser HTTPS. |
| `REQUIRE_OUT_LDAPS` | `Y`: todo LDAP de saída com TLS. |
| `HTTP_RESPONSE_HEADERS` | Headers (separados por `chr(10)`) escritos em toda requisição antes de renderizar; `#CDN#` vira a lista de CDNs conhecidas. |
| `HTTP_TRUSTED_ORIGINS` | Origens remotas (uma por linha) que podem acessar recursos; usar junto com `security.externalSessionTrustedOrigins` do ORDS. |
| `HTTP_ERROR_STATUS_ON_ERROR_PAGE_ENABLED` | `N` (padrão) mostra página de erro; `Y` devolve HTTP 400 em erro não tratado. |
| `HTTP_ERROR_STATUS_ON_AJAX_ERROR_ENABLED` | `N` (padrão) devolve JSON de erro ao AJAX; `Y` devolve HTTP 400; vazio segue o parâmetro anterior. |
| `RESTRICT_RESPONSE_HEADERS` | `Y`/`NULL` (padrão): HTTP 500 quando a página tem headers não suportados (301, 308, 410, cache em POST). |
| `SAMESITE_COOKIE` | Valor padrão do atributo `samesite` dos cookies. |
| `PROTECTED_COOKIES` | Cookies (lista) que o APEX filtra dos arrays OWA. |
| `WORKSPACE_NAME_USER_COOKIE` | `Y`/`NULL` (padrão) envia cookies persistentes de workspace, usuário e idioma no login; `N` não. |
| `REJOIN_EXISTING_SESSIONS` | `P` (padrão): rejoin só para não autenticados/páginas públicas; `Y` também autenticados; `N` desliga na instância. Sobrepõe configurações mais permissivas de app/página. Habilitar sem restrição tem sérias implicações de segurança (sequestro de sessão via XSS). |
| `RESTRICT_IP_RANGE` | IPs (lista, `*` como curinga sem números depois) que podem acessar o ambiente de desenvolvimento. |
| `RESTRICT_DEV_HEADER` | Nome de header HTTP que, se presente, bloqueia o Builder e a administração (normalmente adicionado pelo load balancer). |
| `RESTRICT_APPS_HEADER` | Nome de header com lista de IDs de app permitidos; se o header existir, só essas apps aceitam login. |
| `INBOUND_PROXIES` | IPs dos proxies pelos quais chegam as requisições. |
| `IGNORED_FRIENDLY_URL_PARAMETERS` | Parâmetros ignorados ao interpretar friendly URLs (padrão `utm_campaign,utm_source,utm_medium,utm_term,utm_content,fbclid`). |
| `CHECKSUM_HASH_FUNCTION` | Algoritmo dos checksums de URL: `MD5`/`SH1` (deprecated), `SH256`, `SH384`, `SH512` ou `NULL` (o mais seguro disponível; padrão). |
| `SUBSCRIPTION_HASH_FUNCTION` | Algoritmo dos checksums de subscription: `SH256` (padrão), `SH384`, `SH512`, `NULL`. |
| `PWA_PUSH_NOTIFICATIONS_ALLOWED_ENDPOINTS` | URLs adicionais permitidas para push notifications (além das padrão do Google, Mozilla, Windows e Apple). |
| `DISABLE_ADMIN_LOGIN` | `Y` desabilita Administration Services. |
| `DISABLE_WORKSPACE_LOGIN` | `Y` desabilita o login de workspace. |
| `DISABLE_APPS_LOGIN` | `Y` desabilita login em todas as apps; ou lista de IDs para só essas. |

Fonte: [Available Parameter Values](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_INSTANCE_ADMIN.Available-Parameter-Values.html)

### APEX_INSTANCE_ADMIN: parâmetros de autenticação do Builder, SAML, Social Sign-In e header

| Parâmetro | Função / valores |
|---|---|
| `APEX_BUILDER_AUTHENTICATION` | Autenticação do Builder e da administração: `APEX` (contas de workspace, padrão), `DB`, `HEADER`, `SSO`, `LDAP`, `SAML`, `SOCIAL`. |
| `DATA_REPORTER_AUTHENTICATION` | Autenticação das apps de Data Reporter: `HEADER`, `SAML`, `SOCIAL`. |
| `AUTHENTICATION_SUBSTITUTIONS` | JSON plano de substituições (`{"SUBST_NAME":"valor"}`) visíveis a todos os authentication schemes como `#SUBST_NAME#`. |
| `HEADER_AUTHENTICATION` | JSON com `http_header_variable`, `action_if_username_empty`, `url`, `error_message`, `verify_username`, `logout_url_sso_server`. |
| `HEADER_AUTH_CALLBACK` / `SOCIAL_AUTH_CALLBACK` | Procedure de callback (padrão `APEX_AUTHENTICATION.CALLBACK`). |
| `SOCIAL_AUTHENTICATION` | JSON com `client_id`, `authentication_provider`, `discovery_url`, endpoints, `scope`, `username`, etc. |
| `SOCIAL_CLIENT_SECRET` | Client secret (guardado na credencial interna `AUTHN_SOCIAL`). |
| `SAML_ENABLED` | `Y` permite apps dos workspaces usarem SAML. |
| `SAML_APEX_CERTIFICATE(2)`, `SAML_APEX_PRIVATE_KEY(2)` | Certificado e chave privada do lado APEX (os "2" são alternativos, opcionais). |
| `SAML_IP_ISSUER`, `SAML_IP_SIGNING_CERTIFICATE(2)`, `SAML_SIGN_IN_URL`, `SAML_SIGN_OUT_URL` | Metadados do identity provider. |
| `SAML_SP_ISSUER`, `SAML_NAMEID_FORMAT`, `SAML_USERNAME_ATTRIBUTE`, `SAML_APEX_CALLBACK_URLS` | Issuer do APEX, formato de NameID (padrão `...:nameid-format:persistent`), atributo de username, URLs de callback aceitas. |
| `SAML_C14N_SKIP_UNUSED_INCLUSIVE_NS`, `SAML_C14N_SKIP_UTILIZED_XMLNS` | Ajustes de canonicalização de XML. |
| `SSO_LOGOUT_URL` | URL de logout do SSO (o APEX acrescenta `?p_done_url=...`). |
| `LOGIN_THROTTLE_DELAY` / `LOGIN_THROTTLE_METHODS` | Atraso crescente após falhas de login; métodos de contagem `USERNAME_IP`, `USERNAME`, `IP`. |
| `MAX_LOGIN_FAILURES` | Instância/workspace: tentativas antes de bloquear conta de desenvolvedor/administrador. |
| `PERSISTENT_AUTHENTICATION_MAX_DAYS` | Dias até expirar a persistent authentication. |
| `LOGIN_MESSAGE` | Texto (HTML) na página de login. |

Fonte: [Available Parameter Values](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_INSTANCE_ADMIN.Available-Parameter-Values.html) · [SET_PARAMETER Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_PARAMETER-Procedure.html)

### APEX_INSTANCE_ADMIN: parâmetros de política de senha e contas (PASSWORD_*, SERVICE_ADMIN_PASSWORD_*, ACCOUNT_*)

| Parâmetro | Função |
|---|---|
| `PASSWORD_MIN_LENGTH` | Tamanho mínimo de senha das contas APEX (admins, desenvolvedores, usuários finais). |
| `PASSWORD_NEW_DIFFERS_BY` | Diferenças mínimas, posição a posição, entre senha antiga e nova. |
| `PASSWORD_HISTORY_DAYS` | Dias em que uma senha usada não pode ser reutilizada. |
| `PASSWORD_NOT_LIKE_USERNAME` | `Y` (padrão `N`) proíbe conter o username. |
| `PASSWORD_NOT_LIKE_WS_NAME` | `Y` proíbe conter o nome do workspace. |
| `PASSWORD_NOT_LIKE_WORDS` | Palavras (separadas por `:`) proibidas, sem diferenciar caixa. |
| `PASSWORD_ONE_ALPHA` / `_ONE_LOWER_CASE` / `_ONE_UPPER_CASE` / `_ONE_NUMERIC` / `_ONE_PUNCTUATION` | `Y` exige ao menos um caractere da classe. |
| `PASSWORD_ALPHA_CHARACTERS` / `PASSWORD_PUNCTUATION_CHARACTERS` | Conjuntos de caracteres das regras acima. |
| `PASSWORD_HASH_FUNCTION` | Hash das senhas de workspace: `MD5`/`SH1` (deprecated), `SH256`, `SH384`, `SH512`, `NULL` (mais seguro; padrão). |
| `PASSWORD_HASH_ITERATIONS` | Iterações do hash (padrão 10000). |
| `STRONG_SITE_ADMIN_PASSWORD` | `Y` (padrão): senha do admin da instância segue regras fortes. |
| `SERVICE_ADMIN_PASSWORD_*` (`MIN_LENGTH`, `NEW_DIFFERS_BY`, `NOT_LIKE_USERNAME`, `NOT_LIKE_WORDS`, `NOT_LIKE_WS_NAME`, `ONE_ALPHA`, `ONE_LOWER_CASE`, `ONE_NUMERIC`, `ONE_PUNCTUATION`, `ONE_UPPER_CASE`) | As mesmas regras, aplicadas quando `STRONG_SITE_ADMIN_PASSWORD` está ativo. |
| `USERNAME_VALIDATION` | Regex (sensível a caixa) para validar username de desenvolvedores/admins. Padrão `*` (desligado). |
| `ACCOUNT_LIFETIME_DAYS` | Instância/workspace: dias de validade da senha de conta de usuário final. |
| `EXPIRE_FND_USER_ACCOUNTS` | Instância/workspace: `Y` habilita expiração de contas APEX. |

Fonte: [Available Parameter Values](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_INSTANCE_ADMIN.Available-Parameter-Values.html)

### APEX_INSTANCE_ADMIN: parâmetros de wallet, proxy, impressão e Document Generator

| Parâmetro | Função / valores |
|---|---|
| `WALLET_PATH` | Caminho do wallet no sistema de arquivos, ex.: `file:/home/<username>/wallets`. |
| `WALLET_PWD` | Senha do wallet. |
| `INSTANCE_PROXY` | Proxy de todo HTTP(S) de saída; **sobrepõe** o proxy definido nas apps. |
| `INSTANCE_NO_PROXY_DOMAINS` | Domínios que não usam o proxy da instância. |
| `AI_BUILDER_PROXY` | Proxy para tráfego do App Builder aos Generative AI Services. |
| `PRINT_BIB_LICENSED` | Servidor de impressão: `STANDARD` (Apache FOP), `DOCUMENT_GENERATOR` (Oracle Document Generator Pre-built Function), `ADVANCED` (BI Publisher), `AOP` (APEX Office Print), `NONE` (impressão nativa). |
| `PRINT_SVR_PROTOCOL` / `PRINT_SVR_HOST` / `PRINT_SVR_PORT` / `PRINT_SVR_SCRIPT` | `http`/`https`, host, porta (inteiro positivo) e script (ex.: `/xmlpserver/convert`) do servidor de impressão. |
| `PRINT_SVR_USERNAME` / `PRINT_SVR_PASSWORD` | Credenciais do servidor de impressão (username `NULL` = sem autenticação). |
| `PRINT_SVR_TIMEOUT` | Timeout em segundos. |
| `DOCGEN_CREDENTIAL`, `DOCGEN_FUNCTION_OCID`, `DOCGEN_INVOKE_ENDPOINT`, `DOCGEN_OS_BUCKET_COMPARTMENT_OCID`, `DOCGEN_OS_ENDPOINT`, `DOCGEN_OS_NAMESPACE`, `DOCGEN_INSTANCEID_OVERRIDE` | Configuração do Oracle Document Generator e do bucket de Object Storage (credencial, OCIDs, endpoints, namespace, override do instance ID no nome do bucket). |
| `MAX_DATA_EXPORT_IMAGES` | Máximo de imagens únicas num data export/download de relatório. |
| `CSV_DOWNLOAD_CRLF_LINE_BREAKS` / `CSV_DOWNLOAD_WITH_BOM_ENABLED` / `CSV_DOWNLOAD_ESCAPE_FORMULAS` | CSV com CRLF, com BOM (ajuda o Excel) e com escape de fórmulas em `apex_escape.csv`. |

Fonte: [Available Parameter Values](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_INSTANCE_ADMIN.Available-Parameter-Values.html)

### APEX_INSTANCE_ADMIN: parâmetros de aplicações, background jobs, sessões, logs e retenção

| Parâmetro | Função / valores |
|---|---|
| `APPLICATION_ID_MIN` / `APPLICATION_ID_MAX` | Faixa de IDs de app permitida na instância. |
| `KEEP_SESSIONS_ON_UPGRADE` | `N` (padrão) apaga sessões da app no upgrade; `Y` mantém. |
| `IMP_DEFAULT_SUBSCRIPTION_MODE` | Modo padrão de subscription no import (constantes de `APEX_APPLICATION_INSTALL`). |
| `IMAGE_PREFIX` | Image prefix da instância (ex.: `/i/`). |
| `DEFAULT_THEME_FILES` | Caminho virtual de arquivos de tema (para temas que usam `#DEFAULT_THEME_FILES#`). |
| `MAX_APPLICATION_BACKUPS` | Backups automáticos por app (padrão 25, máximo 30, `0` desliga). |
| `GALLERY_BACKGROUND_INSTALL` / `GALLERY_FILE_URLS` | Instalação em background da galeria; URLs JSON da galeria (aceita `#APEX_BASE_VERSION#`). |
| `BACKGROUND_JOB_CLASS` | Job class do `DBMS_SCHEDULER` para Automations, sincronização de REST Data Sources e notificações de IR. |
| `BACKGROUND_PROCESS_JOB_CLASS` | Job class para background page processes. |
| `BACKGROUND_MIN_EXECUTION_CADENCE` | Minutos mínimos entre duas execuções de jobs como automations e sincronizações. |
| `MAX_PROCESS_SCHEDULER_JOBS_DEFAULT` | Padrão de jobs de background processing (4). |
| `MAX_PROCESS_SCHEDULER_JOBS` | Instância/workspace: máximo de jobs de background; o de workspace sobrepõe o padrão da instância. |
| `MAX_SESSION_IDLE_SEC` / `MAX_SESSION_LENGTH_SEC` / `SESSION_TIMEOUT_WARNING_SEC` | Instância/workspace: ociosidade, duração máxima e aviso antes do timeout (apps internas). |
| `QOS_MAX_SESSION_REQUESTS` / `QOS_MAX_WORKSPACE_REQUESTS` / `QOS_MAX_SESSION_KILL_TIMEOUT` | Instância/workspace: requisições concorrentes por sessão e por workspace; segundos até matar a sessão mais antiga quando o limite é atingido. |
| `RM_CONSUMER_GROUP` | Instância/workspace: consumer group do Resource Manager para eventos de página. |
| `MAX_WEBSERVICE_REQUESTS` | Instância/workspace: web service requests de saída por workspace em 24 h (padrão 1000). |
| `AI_MAX_TOKENS` / `AI_MAX_TOOL_ROUNDTRIPS` | Tokens de IA por workspace em 24 h; máximo de idas e voltas para tool calls. |
| `WEBSERVICE_LOGGING` | Instância/workspace: `A`, `N`, `U` (usar config do workspace). |
| `APPLICATION_ACTIVITY_LOGGING` | `A` (sempre), `N` (nunca), `U` (usar config da app), `O` (desligado para apps novas). |
| `AUTOMATION_LOG_MESSAGE_LIMIT` | Instância/workspace: máximo de mensagens por execução de automation. |
| `AUDIT_LOG_RETENTION` | Dias de retenção do audit log. |
| `DEBUG_MESSAGE_PAGE_VIEW_LIMIT` | Máximo de mensagens de debug por page view (padrão 50000). |
| `SYSTEM_DEBUG_LEVEL` | Nível de debug padrão para todas as requisições (`NULL`, 1–9); o script `utilities/debug/d0.sql` alterna entre `NULL` e 9. |
| `TRACE_HEADER_NAME` | Header (maiúsculo, padrão `ECID-CONTEXT`) gravado na coluna `ECID` do activity log. |
| `TASK_RETENTION_PERIOD_DAYS` / `WORKFLOW_RETENTION_PERIOD_DAYS` | Retenção de Tasks e Workflows concluídos (tasks são arquivadas em JSON zip antes do purge). |
| `DELETE_UPLOADED_FILES_AFTER_DAYS` | Apaga arquivos enviados (exports, data load) após N dias (padrão 14). |
| `CONTENT_CACHE_SIZE_TARGET` / `CONTENT_CACHE_MAX_FILE_SIZE` | Instância/workspace: tamanho alvo do content cache e limite por arquivo. |
| `WORKSPACE_MAX_FILE_BYTES` | Instância/workspace: bytes máximos de arquivos enviados por workspace. |
| `ZIP_FILE_MAX_EXPANSION_FACTOR` / `ZIP_FILE_MAX_UNCOMPRESSED_SIZE_MB` | Proteção contra zip bomb: fator de expansão (200) e tamanho descompactado (4096 MB). |
| `MAX_MAP_AJAX_REQUESTS_PER_SESSION` / `MAX_OBJECTS_MAP_LAYER_TILE` | Limites de Vector Tiles em mapas. |
| `SQL_SCRIPT_MAX_OUTPUT_SIZE` / `WORKSPACE_MAX_OUTPUT_SIZE` | Limites de resultado de scripts no SQL Workshop. |

Fonte: [Available Parameter Values](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_INSTANCE_ADMIN.Available-Parameter-Values.html)

### APEX_INSTANCE_ADMIN: parâmetros de provisionamento de workspaces, banner de ambiente, mensagens e upgrades no Autonomous

| Parâmetro | Função / valores |
|---|---|
| `SERVICE_REQUEST_FLOW` | Modo de provisionamento: `MANUAL` (padrão), `EMAIL` (pedido com aprovação), `AUTO` (aprovação automática). |
| `SERVICE_REQUESTS_ENABLED` | `Y` (padrão): pedidos de schema, storage e encerramento habilitados. |
| `DISABLE_WS_PROV` / `DISABLE_WS_MSG` | Desliga criação de workspace por pedido de e-mail / mensagem exibida nesse caso. |
| `REQ_NEW_SCHEMA` | `Y` permite pedir schema novo no pedido de workspace. |
| `SELF_SERVICE_SCHEMA_PREFIX` | Prefixo dos schemas criados no self-service. |
| `INSTANCE_TABLESPACE`, `AUTOEXTEND_TABLESPACES`, `BIGFILE_TABLESPACES_ENABLED`, `ENCRYPTED_TABLESPACES_ENABLED` | Tablespaces usados/criados no provisionamento (autoextend, bigfile, criptografia). |
| `WORKSPACE_PROVISION_DEMO_OBJECTS` | `Y` (padrão) cria apps e objetos de demonstração em workspaces novos. |
| `WORKSPACE_FREE_SPACE_LIMIT` | % de espaço livre abaixo do qual o workspace aparece no Administrator Digest. |
| `WORKSPACE_ISSUE_FILES_YN` / `WORKSPACE_ISSUE_FS_LIMIT` / `WORKSPACE_TEAM_DEV_FILES_YN` / `WORKSPACE_TEAM_DEV_FS_LIMIT` | Uploads em Issues e Team Development e seus limites (5–25 MB, padrão 15 MB). |
| `ADMIN_DIGEST_DEFAULT_REPORTING_PERIOD` / `ADMIN_DIGEST_MAX_REPORTING_PERIOD` | Períodos do Administrator Digest. |
| `ENV_BANNER_ENABLE` / `ENV_BANNER_LABEL` / `ENV_BANNER_COLOR` / `ENV_BANNER_POS` | Instância/workspace: banner de ambiente no Builder (`Y`/`N`, rótulo, `accent-1`…`accent-16`, `LEFT`/`TOP`). Em `GET_WORKSPACE_PARAMETER` o nome listado é `ENV_BANNER_YN`. |
| `SYSTEM_MESSAGE` | Texto (HTML) na home do ambiente de desenvolvimento. |
| `SYSTEM_HELP_URL` | Link de ajuda do Builder (ex.: `http://oracleapex.com/doc261`). |
| `SWAGGER_UI_URL` | Servidor Swagger UI usado pelo REST Workshop. |
| `UPGRADE_DATE` / `UPGRADE_VERSION` | Somente leitura (Autonomous): data (ISO 8601, UTC) e versão do próximo upgrade agendado. |
| `UPGRADE_DEFERRED` | Autonomous: `N` (padrão) janela padrão; `Y` janela estendida (reagenda upgrade já marcado). |
| `UPGRADE_STATUS` | Autonomous: `UP-TO-DATE`, `SCHEDULED`, `RUNNING`; gravar `RUN` dispara o upgrade. |
| `OPENTELEMETRY_CLS_URL` / `OPENTELEMETRY_TOKEN_RELAY_URL` | **Só workspace**: URL do Client Logging Service e serviço REST que obtém token do usuário. |
| `PATH_PREFIX` | **Só workspace**: prefixo de URI dos RESTful Services do workspace (padrão = nome do workspace). |

Fonte: [Available Parameter Values](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_INSTANCE_ADMIN.Available-Parameter-Values.html)

### APEX_INSTANCE_ADMIN.SET_WORKSPACE_PARAMETER e GET_WORKSPACE_PARAMETER: sobrescrever parâmetros por workspace

```sql
APEX_INSTANCE_ADMIN.SET_WORKSPACE_PARAMETER (
    p_workspace     IN VARCHAR2,
    p_parameter     IN VARCHAR2,
    p_value         IN VARCHAR2 );

APEX_INSTANCE_ADMIN.GET_WORKSPACE_PARAMETER (
    p_workspace     IN VARCHAR2,
    p_parameter     IN VARCHAR2 )      -- usada como function (retorna o valor)
```

`p_parameter` aceita os parâmetros das listas "Instance and Workspace Parameters" e "Workspace Parameters"; o valor definido no workspace sobrepõe o de mesmo nome na instância. Parâmetros "Instance and Workspace": `ACCOUNT_LIFETIME_DAYS`, `AI_IS_ENABLED`, `AI_MAX_TOKENS`, `ALLOW_HOSTING_EXTENSIONS`, `ALLOW_HOSTNAMES`, `AUTOMATION_LOG_MESSAGE_LIMIT`, `CONTENT_CACHE_MAX_FILE_SIZE`, `CONTENT_CACHE_SIZE_TARGET`, `ENV_BANNER_COLOR`, `ENV_BANNER_ENABLE`, `ENV_BANNER_LABEL`, `ENV_BANNER_POS`, `EXPIRE_FND_USER_ACCOUNTS`, `MAX_LOGIN_FAILURES`, `MAX_PROCESS_SCHEDULER_JOBS`, `MAX_SESSION_IDLE_SEC`, `MAX_SESSION_LENGTH_SEC`, `MAX_WEBSERVICE_REQUESTS`, `QOS_MAX_SESSION_KILL_TIMEOUT`, `QOS_MAX_SESSION_REQUESTS`, `QOS_MAX_WORKSPACE_REQUESTS`, `RM_CONSUMER_GROUP`, `SESSION_TIMEOUT_WARNING_SEC`, `WEBSERVICE_LOGGING`, `WORKSPACE_EMAIL_MAXIMUM`, `WORKSPACE_MAX_FILE_BYTES`. Só de workspace: `OPENTELEMETRY_CLS_URL`, `OPENTELEMETRY_TOKEN_RELAY_URL`, `PATH_PREFIX`, `SMTP_CREDENTIAL_STATIC_ID`.

```sql
-- Restringir as apps do workspace HR a URLs com hr.example.com
begin
  apex_instance_admin.set_workspace_parameter (
    p_workspace => 'HR',
    p_parameter => 'ALLOW_HOSTNAMES',
    p_value     => 'hr.example.com' );
  commit;
end;

begin
    dbms_output.put_line (
        apex_instance_admin.get_workspace_parameter (
            p_workspace => 'HR',
            p_parameter => 'ALLOW_HOSTNAMES' ));
end;

-- Banner de ambiente e limite de e-mails para um workspace de homologação
begin
  apex_instance_admin.set_workspace_parameter('WKSP_HML', 'ENV_BANNER_ENABLE', 'Y');
  apex_instance_admin.set_workspace_parameter('WKSP_HML', 'ENV_BANNER_LABEL',  'HOMOLOGAÇÃO');
  apex_instance_admin.set_workspace_parameter('WKSP_HML', 'WORKSPACE_EMAIL_MAXIMUM', '200');
  commit;
end;
```

Pegadinha: a doc classifica `GET_WORKSPACE_PARAMETER` como "Procedure" e a assinatura não mostra `RETURN`, mas o exemplo oficial a usa dentro de `dbms_output.put_line`, ou seja, como function que devolve o valor.

Fonte: [SET_WORKSPACE_PARAMETER Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_WORKSPACE_PARAMETER.html) · [GET_WORKSPACE_PARAMETER Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_WORKSPACE_PARAMETER.html) · [Available Parameter Values](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_INSTANCE_ADMIN.Available-Parameter-Values.html)

### APEX_INSTANCE_ADMIN.ADD_WORKSPACE e REMOVE_WORKSPACE: criar e remover workspaces

```sql
APEX_INSTANCE_ADMIN.ADD_WORKSPACE (
    p_workspace_id        IN NUMBER DEFAULT NULL,
    p_workspace           IN VARCHAR2,
    p_source_identifier   IN VARCHAR2 DEFAULT NULL,
    p_primary_schema      IN VARCHAR2,
    p_additional_schemas  IN VARCHAR2,
    p_rm_consumer_group   IN VARCHAR2 DEFAULT NULL,
    p_host_prefix         IN VARCHAR2 DEFAULT NULL );

APEX_INSTANCE_ADMIN.REMOVE_WORKSPACE (
    p_workspace         IN VARCHAR2,
    p_drop_users        IN VARCHAR2 DEFAULT 'N',
    p_drop_tablespaces  IN VARCHAR2 DEFAULT 'N' );
```

| Parâmetro (`ADD_WORKSPACE`) | Significado |
|---|---|
| `p_workspace_id` | ID único na instância; nulo = gera um novo. |
| `p_workspace` | Nome do workspace. |
| `p_source_identifier` | Identificador curto usado para sincronizar feedback entre instâncias. |
| `p_primary_schema` | Schema principal. |
| `p_additional_schemas` | Schemas adicionais, **separados por dois-pontos** (`'HR:OE'`). Sem default: passe `null` se não houver. |
| `p_rm_consumer_group` | Consumer group do Resource Manager para executar as apps do workspace. |
| `p_host_prefix` | Se definido, as apps só abrem se o hostname da URL contiver esse valor. |

| Parâmetro (`REMOVE_WORKSPACE`) | Significado |
|---|---|
| `p_drop_users` | `'Y'` também apaga o usuário de banco associado. Padrão `'N'`. |
| `p_drop_tablespaces` | `'Y'` também apaga o tablespace do usuário. Padrão `'N'`. |

```sql
begin
    apex_instance_admin.add_workspace (
        p_workspace_id       => 8675309,
        p_workspace          => 'MY_WORKSPACE',
        p_primary_schema     => 'SCOTT',
        p_additional_schemas => 'HR:OE' );
    commit;
end;

begin
    apex_instance_admin.remove_workspace('MY_WORKSPACE', 'Y', 'Y');  -- destrutivo: apaga usuário e tablespace
end;
```

Fonte: [ADD_WORKSPACE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_WORKSPACE-Procedure.html) · [REMOVE_WORKSPACE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/REMOVE_WORKSPACE-Procedure.html)

### APEX_INSTANCE_ADMIN: mapear schemas a workspaces (ADD_SCHEMA, REMOVE_SCHEMA, GET_SCHEMAS)

```sql
APEX_INSTANCE_ADMIN.ADD_SCHEMA (
    p_workspace             IN VARCHAR2,
    p_schema                IN VARCHAR2,
    p_grant_apex_privileges IN VARCHAR2 DEFAULT FALSE );

APEX_INSTANCE_ADMIN.REMOVE_SCHEMA (
    p_workspace     IN VARCHAR2,
    p_schema        IN VARCHAR2 );

APEX_INSTANCE_ADMIN.GET_SCHEMAS (
    p_workspace     IN VARCHAR2 )
RETURN VARCHAR2;        -- lista separada por vírgula
```

`p_grant_apex_privileges` concede ao schema os privilégios de que o APEX precisa (padrão "falso"). A assinatura declara o tipo como `VARCHAR2` com default `FALSE`, e o exemplo oficial passa `true`; siga o exemplo.

```sql
begin
    apex_instance_admin.add_schema('MY_WORKSPACE', 'FRANK', true);
    dbms_output.put_line('Schemas: ' || apex_instance_admin.get_schemas('MY_WORKSPACE'));
    -- apex_instance_admin.remove_schema('MY_WORKSPACE', 'FRANK');
end;
```

Uso típico: antes de `APEX_APPLICATION_INSTALL.SET_SCHEMA` ou `APEX_APPLICATION_ADMIN.SET_PARSING_SCHEMA`, que exigem o schema já mapeado ao workspace.

Fonte: [ADD_SCHEMA Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_SCHEMA-Procedure.html) · [REMOVE_SCHEMA Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/REMOVE_SCHEMA-Procedure.html) · [GET_SCHEMAS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_SCHEMAS-Function.html)

### APEX_INSTANCE_ADMIN: restringir schemas e exceções (RESTRICT_SCHEMA, UNRESTRICT_SCHEMA, CREATE/REMOVE_SCHEMA_EXCEPTION(S), REMOVE_WORKSPACE_EXCEPTIONS)

```sql
APEX_INSTANCE_ADMIN.RESTRICT_SCHEMA   ( p_schema IN VARCHAR2 );
APEX_INSTANCE_ADMIN.UNRESTRICT_SCHEMA ( p_schema IN VARCHAR2 );

APEX_INSTANCE_ADMIN.CREATE_SCHEMA_EXCEPTION (
    p_schema    IN VARCHAR2,
    p_workspace IN VARCHAR2 );
APEX_INSTANCE_ADMIN.REMOVE_SCHEMA_EXCEPTION (
    p_schema    IN VARCHAR2,
    p_workspace IN VARCHAR2 );
APEX_INSTANCE_ADMIN.REMOVE_SCHEMA_EXCEPTIONS (
      p_schema IN VARCHAR2 );
APEX_INSTANCE_ADMIN.REMOVE_WORKSPACE_EXCEPTIONS (
    p_workspace IN VARCHAR2 );
```

Fluxo: `RESTRICT_SCHEMA` revoga o privilégio de atribuir o schema a workspaces; `CREATE_SCHEMA_EXCEPTION` libera um workspace específico; `REMOVE_SCHEMA_EXCEPTION` tira a exceção de um par; `REMOVE_SCHEMA_EXCEPTIONS` tira todas as exceções do schema; `REMOVE_WORKSPACE_EXCEPTIONS` tira todas as exceções do workspace; `UNRESTRICT_SCHEMA` devolve o privilégio.

```sql
begin
    apex_instance_admin.restrict_schema(p_schema => 'HR');
    apex_instance_admin.create_schema_exception ( p_schema => 'HR', p_workspace => 'HR_WORKSPACE' );
    commit;
end;

begin
    apex_instance_admin.remove_workspace_exceptions ( p_workspace => 'HR_WORKSPACE' );
    apex_instance_admin.unrestrict_schema(p_schema => 'HR');
    commit;
end;
```

Pegadinha: o exemplo oficial de `REMOVE_WORKSPACE_EXCEPTIONS` chama, por engano, `remove_schema_exceptions(p_workspace => ...)`, que não tem esse parâmetro; use `remove_workspace_exceptions`.

Fonte: [RESTRICT_SCHEMA Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/RESTRICT_SCHEMA-Procedure.html) · [UNRESTRICT_SCHEMA Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/UNRESTRICT_SCHEMA-Procedure.html) · [CREATE_SCHEMA_EXCEPTION Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CREATE_SCHEMA_EXCEPTION-Procedure.html) · [REMOVE_SCHEMA_EXCEPTION Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/REMOVE_SCHEMA_EXCEPTION-Procedure.html) · [REMOVE_SCHEMA_EXCEPTIONS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/REMOVE_SCHEMA_EXCEPTIONS-Procedure.html) · [REMOVE_WORKSPACE_EXCEPTIONS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/REMOVE_WORKSPACE_EXCEPTIONS-Procedure.html)

### APEX_INSTANCE_ADMIN: reservar e liberar IDs de app de um workspace (RESERVE_WORKSPACE_APP_IDS, FREE_WORKSPACE_APP_IDS)

```sql
APEX_INSTANCE_ADMIN.RESERVE_WORKSPACE_APP_IDS ( p_workspace_id IN NUMBER );
APEX_INSTANCE_ADMIN.FREE_WORKSPACE_APP_IDS    ( p_workspace_id IN NUMBER );
```

`RESERVE_WORKSPACE_APP_IDS` reserva **permanentemente** os IDs das apps do workspace: mesmo depois de remover o workspace, ninguém cria apps com esses IDs na instância. `FREE_WORKSPACE_APP_IDS` desfaz (reserva por engano ou workspace que não existe mais).

Cenário da doc (mover workspace entre instâncias com faixas de ID distintas):

```sql
-- Instância 1
begin
    apex_instance_admin.set_parameter('APPLICATION_ID_MIN', 100000);
    apex_instance_admin.set_parameter('APPLICATION_ID_MAX', 199999);
end;
-- Instância 2
begin
    apex_instance_admin.set_parameter('APPLICATION_ID_MIN', 200000);
    apex_instance_admin.set_parameter('APPLICATION_ID_MAX', 299999);
end;
-- Na instância 1, depois de exportar workspace, apps e dados:
begin
    apex_instance_admin.reserve_workspace_app_ids(1234567890);
    apex_instance_admin.remove_workspace('MY_WORKSPACE');
end;
-- Em seguida, importar tudo na instância 2.
```

Fonte: [RESERVE_WORKSPACE_APP_IDS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/RESERVE_WORKSPACE_APP_IDS-Procedure.html) · [FREE_WORKSPACE_APP_IDS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/FREE_WORKSPACE_APP_IDS-Procedure.html)

### APEX_INSTANCE_ADMIN: web entry points (ADD_WEB_ENTRY_POINT, REMOVE_WEB_ENTRY_POINT)

```sql
APEX_INSTANCE_ADMIN.ADD_WEB_ENTRY_POINT (
    p_name    IN VARCHAR2,
    p_methods IN VARCHAR2 DEFAULT 'GET' );   -- p_methods: deprecated

APEX_INSTANCE_ADMIN.REMOVE_WEB_ENTRY_POINT (
    p_name   IN VARCHAR2 );
```

Libera (ou retira) uma procedure pública para ser chamada diretamente pela URL, ex.: `https://www.example.com/apex/myschema.mypkg.proc`. `p_name` vai com schema e package, a menos que exista sinônimo público. O parsing schema (ex.: `APEX_PUBLIC_USER`) precisa poder executá-la: conceda `EXECUTE` a `PUBLIC` ou ao parsing schema. `p_methods` (lista de métodos HTTP, padrão `GET`) está deprecated e será removido.

```sql
begin
    apex_instance_admin.add_web_entry_point (
        p_name    => 'MYSCHEMA.MYPKG.PROC',
        p_methods => 'GET,POST' );
    commit;
end;

begin
    apex_instance_admin.remove_web_entry_point ( p_name => 'MYSCHEMA.MYPKG.PROC' );
    commit;
end;
```

Pegadinha: o exemplo oficial de `REMOVE_WEB_ENTRY_POINT` está sem o `=>`; use `p_name => '...'`. Procedures legadas (ex.: `HTMLDB_UTIL.%`) só são chamáveis pela URL com `ENABLE_LEGACY_WEB_ENTRY_POINTS = Y`.

Fonte: [ADD_WEB_ENTRY_POINT Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_WEB_ENTRY_POINT-procedure.html) · [REMOVE_WEB_ENTRY_POINT Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/REMOVE_WEB_ENTRY_POINT-Procedure.html) · [Available Parameter Values](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_INSTANCE_ADMIN.Available-Parameter-Values.html)

### APEX_INSTANCE_ADMIN: usuários administradores e desbloqueio (CREATE_OR_UPDATE_ADMIN_USER, UNLOCK_USER)

```sql
APEX_INSTANCE_ADMIN.CREATE_OR_UPDATE_ADMIN_USER (
    p_username  IN  VARCHAR2 );

APEX_INSTANCE_ADMIN.UNLOCK_USER (
    p_workspace    IN  VARCHAR2,
    p_username     IN  VARCHAR2,
    p_password     IN  VARCHAR2 DEFAULT NULL );
```

- `CREATE_OR_UPDATE_ADMIN_USER`: cria um administrador da instância (usuário do workspace `INTERNAL`). Se já existir, desbloqueia e define uma senha aleatória (não usada quando a autenticação do Builder é Database Accounts). É o equivalente procedural do script `apxchpwd.sql`.
- `UNLOCK_USER`: desbloqueia um usuário de workspace; com `p_password`, também troca a senha.

```sql
begin
    apex_instance_admin.create_or_update_admin_user ( p_username => 'ADMIN' );
    commit;
end;

begin
    apex_instance_admin.unlock_user (
        p_workspace => 'INTERNAL',
        p_username  => 'ADMIN',
        p_password  => 'example password' );
    commit;
end;

begin
    apex_instance_admin.unlock_user ( p_workspace => 'SOME_WORKSPACE', p_username => 'EXAMPLE_USER' );
    commit;
end;
```

Pegadinha: o exemplo oficial de `CREATE_OR_UPDATE_ADMIN_USER` não fecha o parêntese antes do `COMMIT`; corrigido acima.

Fonte: [CREATE_OR_UPDATE_ADMIN_USER Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CREATE_OR_UPDATE_ADMIN_USER-Procedure.html) · [UNLOCK_USER Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/UNLOCK_USER-Procedure.html)

### Conta de administrador ou desenvolvedor bloqueada após tentativas de login

**Sintoma:** um desenvolvedor, o admin do workspace ou o `ADMIN` da instância não consegue mais entrar (conta bloqueada).
**Causa:** excedeu `MAX_LOGIN_FAILURES` (falhas consecutivas antes do bloqueio).
**Correção:** como usuário com `APEX_ADMINISTRATOR_ROLE`, `apex_instance_admin.unlock_user(p_workspace => ..., p_username => ..., p_password => ...)` + `COMMIT`; para o admin da instância, também `create_or_update_admin_user('ADMIN')`.

Fonte: [UNLOCK_USER Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/UNLOCK_USER-Procedure.html) · [CREATE_OR_UPDATE_ADMIN_USER Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CREATE_OR_UPDATE_ADMIN_USER-Procedure.html) · [Available Parameter Values](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_INSTANCE_ADMIN.Available-Parameter-Values.html)

### APEX_INSTANCE_ADMIN: logs (TRUNCATE_LOG, SET_LOG_SWITCH_INTERVAL)

```sql
APEX_INSTANCE_ADMIN.TRUNCATE_LOG (
    p_log     IN VARCHAR2 );

APEX_INSTANCE_ADMIN.SET_LOG_SWITCH_INTERVAL(
    p_log_name              IN VARCHAR2,
    p_log_switch_after_days IN NUMBER );
```

| `p_log` de `TRUNCATE_LOG` | Apaga |
|---|---|
| `ACTIVITY` | Acessos a páginas. |
| `AUTOMATION` | Logs de automations. |
| `CLICKS` | Cliques rastreados para sites externos. |
| `DEBUG` | Mensagens de debug. |
| `FILE` | Purga automática de arquivos. |
| `LOCK_INSTALL_SCRIPT` / `LOCK_PAGE` | Travas de script de supporting objects / de páginas por desenvolvedores. |
| `MAIL` | E-mails enviados. |
| `PURGE` | Purga automática de workspaces. |
| `REST_SYNCHRONIZATION` | Sincronizações de REST Source. |
| `SCRIPT` / `SQL` | Resultados de scripts e histórico de SQL Commands do SQL Workshop. |
| `USER_ACCESS` | Logins de usuários. |
| `WEB_SERVICES` | Chamadas de web service iniciadas pela instância. |
| `WORKSPACE_HIST` | Resumo diário de workspaces. |

`SET_LOG_SWITCH_INTERVAL`: `p_log_name` em `ACCESS`, `ACTIVITY`, `AUTOMATION`, `CLICKTHRU`, `DEBUG`, `WEBSERVICE`, `WEBSOURCESYNC`; intervalo inteiro de 1 a 180 dias.

```sql
begin
    apex_instance_admin.set_log_switch_interval( p_log_name => 'ACTIVITY', p_log_switch_after_days => 30 );
    commit;
    apex_instance_admin.truncate_log('DEBUG');
end;
```

Fonte: [TRUNCATE_LOG Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/TRUNCATE_LOG-Procedure.html) · [SET_LOG_SWITCH_INTERVAL Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_LOG_SWITCH_INTERVAL-Procedure.html)

### APEX_INSTANCE_ADMIN: relatórios salvos e subscriptions de Interactive Report (REMOVE_SAVED_REPORT(S), REMOVE_SUBSCRIPTION)

```sql
APEX_INSTANCE_ADMIN.REMOVE_SAVED_REPORT (
    p_application_id     IN NUMBER,
    p_report_id          IN NUMBER );

APEX_INSTANCE_ADMIN.REMOVE_SAVED_REPORTS (
    p_application_id     IN NUMBER DEFAULT NULL );   -- NULL = instância inteira!

APEX_INSTANCE_ADMIN.REMOVE_SUBSCRIPTION (
    p_subscription_id     IN NUMBER );
```

- `REMOVE_SAVED_REPORT`: apaga um relatório salvo de IR de um usuário numa app.
- `REMOVE_SAVED_REPORTS`: apaga todos os relatórios salvos de uma app; sem argumento, de **toda a instância**.
- `REMOVE_SUBSCRIPTION`: apaga uma subscription de IR; o ID pode ser encontrado na view `APEX_APPLICATION_PAGE_IR_SUB`.

```sql
begin
    apex_instance_admin.remove_saved_report(100, 123);
    apex_instance_admin.remove_saved_reports(100);
    apex_instance_admin.remove_subscription ( p_subscription_id => 12345 );
end;
```

Fonte: [REMOVE_SAVED_REPORT Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/REMOVE_SAVED_REPORT-Procedure.html) · [REMOVE_SAVED_REPORTS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/REMOVE_SAVED_REPORTS-Procedure.html) · [REMOVE_SUBSCRIPTION Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/REMOVE_SUBSCRIPTION-Procedure.html)

### APEX_INSTANCE_ADMIN.REMOVE_APPLICATION: remover uma app da instância

```sql
APEX_INSTANCE_ADMIN.REMOVE_APPLICATION (
    p_application_id IN NUMBER );
```

Remove a app indicada da instância APEX. Compare com `APEX_APPLICATION_INSTALL.REMOVE_APPLICATION`, que remove a app de um workspace, respeita os `SET_%` daquele package e falha se a app estiver em outro workspace.

```sql
begin
    apex_instance_admin.remove_application(100);
end;
```

Fonte: [REMOVE_APPLICATION Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/REMOVE_APPLICATION-Procedure.html)

### APEX_INSTANCE_ADMIN: credenciais OCI no DBMS_CLOUD (CREATE_CLOUD_CREDENTIAL, DROP_CLOUD_CREDENTIAL)

```sql
APEX_INSTANCE_ADMIN.CREATE_CLOUD_CREDENTIAL (
    p_credential_name       IN VARCHAR2,
    p_user_ocid             IN VARCHAR2,
    p_tenancy_ocid          IN VARCHAR2,
    p_private_key           IN VARCHAR2,
    p_fingerprint           IN VARCHAR2 );

APEX_INSTANCE_ADMIN.DROP_CLOUD_CREDENTIAL (
    p_credential_name       IN VARCHAR2 );
```

Cria (via `DBMS_CLOUD.CREATE_CREDENTIAL`) ou remove (via `DBMS_CLOUD.DROP_CREDENTIAL`, no schema interno do APEX) uma credencial OCI API Key: nome, OCID do usuário, OCID da tenancy, chave privada e fingerprint. Útil, por exemplo, para o parâmetro `DOCGEN_CREDENTIAL`.

```sql
begin
    apex_instance_admin.create_cloud_credential (
        p_credential_name => 'MY_CREDENTIAL',
        p_user_ocid       => 'ocid1.user.oc1...',
        p_tenancy_ocid    => 'ocid1.tenancy.oc1..',
        p_private_key     => 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
        p_fingerprint     => '12:34:56:78:90:ab:cd:ef:12:34:56:78:90:ab:cd:ef' );
end;
```

Fonte: [CREATE_CLOUD_CREDENTIAL Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CREATE_CLOUD_CREDENTIAL-Procedure.html) · [DROP_CLOUD_CREDENTIAL Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/DROP_CLOUD_CREDENTIAL-Procedure.html) · [Available Parameter Values](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_INSTANCE_ADMIN.Available-Parameter-Values.html)

### APEX_INSTANCE_ADMIN: Builder extensions e consumer groups (GRANT/REVOKE_EXTENSION_WORKSPACE, SET_WORKSPACE_CONSUMER_GROUP)

```sql
APEX_INSTANCE_ADMIN.GRANT_EXTENSION_WORKSPACE (
    p_from_workspace    IN  VARCHAR2,
    p_to_workspace      IN  VARCHAR2,
    p_read_access       IN  BOOLEAN  DEFAULT FALSE,
    p_menu_label        IN  VARCHAR2 DEFAULT NULL );

APEX_INSTANCE_ADMIN.REVOKE_EXTENSION_WORKSPACE (
    p_from_workspace      IN VARCHAR2,
    p_to_workspace        IN VARCHAR2 );

SET_WORKSPACE_CONSUMER_GROUP (
    p_workspace IN VARCHAR2,
    p_rm_consumer_group IN VARCHAR2 );
```

- `GRANT_EXTENSION_WORKSPACE`: os links do Builder Extension menu do workspace de extensões (`p_to_workspace`) passam a aparecer no workspace concedente (`p_from_workspace`). `p_read_access => TRUE` dá ao workspace de extensões leitura das views de repositório do concedente. `p_menu_label` troca o rótulo do menu (senão usa o nome do workspace de extensões).
- `SET_WORKSPACE_CONSUMER_GROUP`: associa um consumer group do Resource Manager ao workspace; `NULL` limpa.

```sql
begin
    apex_instance_admin.grant_extension_workspace(
        p_from_workspace => 'MY_WORKSPACE',
        p_to_workspace   => 'EXTENSIONS',
        p_read_access    => true,
        p_menu_label     => 'Tools' );
    apex_instance_admin.set_workspace_consumer_group(
        p_workspace         => 'MY_WORKSPACE',
        p_rm_consumer_group => 'CUSTOM_GROUP1' );
    commit;
end;
```

Fonte: [GRANT_EXTENSION_WORKSPACE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GRANT_EXTENSION_WORKSPACE-Procedure.html) · [REVOKE_EXTENSION_WORKSPACE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/REVOKE_EXTENSION_WORKSPACE-Procedure.html) · [SET_WORKSPACE_CONSUMER_GROUP Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_WORKSPACE_CONSUMER_GROUP-Procedure.html)

### Ninguém consegue entrar no workspace depois de SET_WORKSPACE_CONSUMER_GROUP

**Sintoma:** após definir o consumer group, login no workspace e execução de qualquer app dele passam a dar erro.
**Causa:** o consumer group não precisa existir quando a procedure é chamada, mas se não existir, o APEX levanta erro em todo login e execução de app do workspace.
**Correção:** crie o consumer group no Resource Manager ou limpe a associação com `set_workspace_consumer_group(p_workspace => ..., p_rm_consumer_group => null)` + `COMMIT`.

Fonte: [SET_WORKSPACE_CONSUMER_GROUP Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_WORKSPACE_CONSUMER_GROUP-Procedure.html)

### APEX_INSTANCE_ADMIN: bloquear domínios de e-mail no auto-provisioning (ADD/REMOVE_AUTO_PROV_RESTRICTIONS)

```sql
APEX_INSTANCE_ADMIN.ADD_AUTO_PROV_RESTRICTIONS (
    p_block_email_patterns IN apex_t_varchar2 DEFAULT NULL );

APEX_INSTANCE_ADMIN.REMOVE_AUTO_PROV_RESTRICTIONS (
    p_block_email_patterns IN apex_t_varchar2 DEFAULT NULL );
```

Adicionam/removem padrões de e-mail (tabela `apex_auto_prov_email_patterns`) bloqueados quando a instância permite auto ou self-provisioning de workspaces. Sem provisioning automático habilitado, não têm efeito em runtime. (Na doc, as descrições do parâmetro das duas procedures estão trocadas; o nome da procedure é o que vale.)

```sql
begin
    apex_instance_admin.add_auto_prov_restrictions (
        p_block_email_patterns => apex_t_varchar2('%@gmail.com','%@example.com') );
end;
```

Fonte: [ADD_AUTO_PROV_RESTRICTIONS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_AUTO_PROV_RESTRICTIONS-Procedure.html) · [REMOVE_AUTO_PROV_RESTRICTIONS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/REMOVE_AUTO_PROV_RESTRICTIONS-Procedure.html)


## 30. APEX_INSTANCE_DEBUG: debug de toda a instância e leitura de page views, mensagens e activity log no SQLcl

### APEX_INSTANCE_DEBUG: propósito, quando usar e quando não usar

`APEX_INSTANCE_DEBUG` reúne APIs de debug **para administradores da instância**: ligar e desligar o debug de toda a instância e imprimir, no console do SQLcl/SQL*Plus (via `serveroutput`), as page views recentes que tiveram debug, as mensagens de debug de uma page view e as entradas recentes do activity log, com filtros.

Quando usar:
- Investigar um problema em produção que não se reproduz com debug por app/sessão: liga-se o debug na instância por um período curto, reproduz-se o erro e lê-se o resultado direto no SQLcl, sem abrir o Builder.
- Ver rapidamente erros recentes no activity log (`LIST_ACTIVITY` com `p_error => '%'`).

Quando não usar:
- Para instrumentar o próprio código (gravar mensagens): isso é `APEX_DEBUG` (`apex_debug.message`, `apex_debug.enable` etc.).
- Para deixar ligado de forma permanente: o debug de instância vale para todas as requisições; desligue assim que terminar.

Pegadinhas gerais:
- Os exemplos oficiais fazem `COMMIT` depois de `enable`/`disable`: a mudança segue a transação.
- As rotinas `LIST_%` escrevem com `dbms_output`; ative `set serveroutput on size unlimited` (e `set lines 190` para leitura).
- O nível de debug padrão de toda requisição também pode ser definido pelo parâmetro de instância `SYSTEM_DEBUG_LEVEL` (`APEX_INSTANCE_ADMIN`); o script SQLcl `utilities/debug/d0.sql` alterna esse parâmetro entre `NULL` e 9, e a doc cita os scripts `d1.sql` e `ds.sql` como usuários de `LIST_PAGE_VIEWS(p_show_d2 => true)`.

Fonte: [APEX_INSTANCE_DEBUG](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_INSTANCE_DEBUG.html) · [ENABLE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_INSTANCE_DEBUG.ENABLE-Procedure.html) · [Available Parameter Values](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_INSTANCE_ADMIN.Available-Parameter-Values.html)

### APEX_INSTANCE_DEBUG: referência completa de procedures e functions

| Nome | Tipo | Descrição |
|---|---|---|
| `ENABLE` | procedure | Liga o nível de debug da instância. |
| `DISABLE` | procedure | Desliga o nível de debug da instância. |
| `IS_ENABLED` | function (`BOOLEAN`) | Indica se o debug de instância está ligado. |
| `LIST_PAGE_VIEWS` | procedure | Relatório das requisições recentes que tiveram debug. |
| `LIST_MESSAGES` | procedure | Todas as mensagens de debug de uma page view. |
| `LIST_ACTIVITY` | procedure | Entradas recentes do activity log, com filtros. |

Fonte: [APEX_INSTANCE_DEBUG](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_INSTANCE_DEBUG.html)

### APEX_INSTANCE_DEBUG.ENABLE, DISABLE e IS_ENABLED: ligar e desligar o debug da instância

```sql
APEX_INSTANCE_DEBUG.ENABLE;
APEX_INSTANCE_DEBUG.DISABLE;
APEX_INSTANCE_DEBUG.IS_ENABLED
    RETURN BOOLEAN;
```

```sql
SQL> set lines 190 serveroutput on size unlimited
SQL> exec apex_instance_debug.enable;
SQL> commit;
-- reproduzir o problema ...
SQL> exec apex_instance_debug.disable;
SQL> commit;
```

```sql
-- Desligar se estiver ligado
begin
    if apex_instance_debug.is_enabled then
        apex_instance_debug.disable;
        commit;
    end if;
end;
```

Fonte: [ENABLE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_INSTANCE_DEBUG.ENABLE-Procedure.html) · [DISABLE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_INSTANCE_DEBUG.DISABLE-Procedure.html) · [IS_ENABLED Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_INSTANCE_DEBUG.IS_ENABLED-Function.html)

### APEX_INSTANCE_DEBUG.LIST_PAGE_VIEWS e LIST_MESSAGES: achar a page view com debug e ler suas mensagens

```sql
APEX_INSTANCE_DEBUG.LIST_PAGE_VIEWS (
    p_session_id             IN              NUMBER DEFAULT NULL,
    p_max_rows               IN              NUMBER DEFAULT 30,
    p_show_d2                IN              BOOLEAN DEFAULT FALSE);

APEX_INSTANCE_DEBUG.LIST_MESSAGES (
    p_page_view_id           IN              NUMBER);
```

| Parâmetro | Significado |
|---|---|
| `p_session_id` | Restringe a uma sessão APEX. |
| `p_max_rows` | Número de linhas (padrão 30; entre 1 e 10.000). |
| `p_show_d2` | `TRUE` prefixa cada page view ID com `@d2`, para copiar e colar no SQLcl; os scripts `d1.sql` e `ds.sql` usam essa opção. |
| `p_page_view_id` | ID da page view. Cada requisição com debug recebe um page view ID único. |

Fluxo típico: listar as page views recentes, pegar o ID da requisição com problema e despejar suas mensagens num arquivo.

```sql
SQL> set lines 190 serveroutput on size unlimited
SQL> exec apex_instance_debug.list_page_views;
SQL> spool 1234.lst
SQL> exec apex_instance_debug.list_messages(1234);
SQL> spool off
SQL> ed 1234.lst
```

Fonte: [LIST_PAGE_VIEWS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_INSTANCE_DEBUG.LIST_PAGE_VIEWS-Procedure.html) · [LIST_MESSAGES Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_INSTANCE_DEBUG.LIST_MESSAGES-Procedure.html)

### APEX_INSTANCE_DEBUG.LIST_ACTIVITY: imprimir o activity log recente com filtros (erros, app, página, usuário, IP)

```sql
APEX_INSTANCE_DEBUG.LIST_ACTIVITY (
    p_from_date      IN DATE     DEFAULT sysdate-5,
    p_to_date        IN DATE     DEFAULT sysdate,
    p_app_id         IN NUMBER   DEFAULT NULL,
    p_page_id        IN NUMBER   DEFAULT NULL,
    p_workspace_name IN VARCHAR2 DEFAULT NULL,
    p_session_id     IN NUMBER   DEFAULT NULL,
    p_user           IN VARCHAR2 DEFAULT NULL,
    p_ip_address     IN VARCHAR2 DEFAULT NULL,
    p_not_ip_address IN VARCHAR2 DEFAULT NULL,
    p_error          IN VARCHAR2 DEFAULT NULL,
    p_debug          IN NUMBER   DEFAULT NULL );
```

| Parâmetro | Filtro |
|---|---|
| `p_from_date` / `p_to_date` | Janela de tempo das entradas (ver pegadinha do default abaixo). |
| `p_app_id` / `p_page_id` | Aplicação e página. |
| `p_workspace_name` | Nome do workspace. |
| `p_session_id` | Sessão APEX. |
| `p_user` | Usuário. |
| `p_ip_address` / `p_not_ip_address` | IP que casa / não casa com o padrão (`LIKE`). |
| `p_error` | Mensagem de erro que casa com o padrão (`LIKE`); `'%'` = qualquer erro. |
| `p_debug` | Só entradas com nível de debug `<= p_debug`. |

```sql
-- Erros dos últimos dois dias
exec apex_instance_debug.list_activity(p_from_date => sysdate-2, p_error => '%')

-- Erros da app 100, página 13, no último dia
exec apex_instance_debug.list_activity(p_from_date => sysdate-1, p_app_id => 100, p_page_id => 13, p_error => '%')
```

Pegadinha: a assinatura declara `p_from_date DEFAULT sysdate-5` (cinco **dias**, em aritmética de datas Oracle), mas a tabela de parâmetros da doc fala em "sysdate - 5 min". Passe `p_from_date` explicitamente para não depender do default. A doc também descreve `p_to_date` como "start date/time" e `p_page_id` como "application ID", o que parece erro de redação: pelos nomes, são o fim da janela e o ID da página.

Fonte: [LIST_ACTIVITY Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_INSTANCE_DEBUG.LIST_ACTIVITY-Procedure.html)

### APEX_INSTANCE_DEBUG.LIST_PAGE_VIEWS ou LIST_MESSAGES não imprime nada no SQLcl

**Sintoma:** `exec apex_instance_debug.list_page_views` (ou `list_messages`, `list_activity`) termina sem erro e sem saída.
**Causa:** as rotinas escrevem via `dbms_output`; sem `serveroutput` ligado, nada aparece. Para `list_page_views`/`list_messages`, também é preciso que alguma requisição tenha rodado com debug.
**Correção:** `set lines 190 serveroutput on size unlimited` antes da chamada; se a lista vier vazia, ligue o debug (`apex_instance_debug.enable` + `commit`), reproduza a requisição e liste de novo.

Fonte: [LIST_PAGE_VIEWS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_INSTANCE_DEBUG.LIST_PAGE_VIEWS-Procedure.html) · [LIST_MESSAGES Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_INSTANCE_DEBUG.LIST_MESSAGES-Procedure.html) · [ENABLE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_INSTANCE_DEBUG.ENABLE-Procedure.html)


## 31. APEX_EXTENSION: Builder Extensions (menu de extensões e acesso a outro workspace)

### APEX_EXTENSION: propósito, quando usar e quando não usar

`APEX_EXTENSION` reúne utilitários para **aplicações de extensão do Builder**, ou seja, apps que ficam num workspace de extensão e são abertas a partir do menu *Extensions* do Builder de outros workspaces. O uso pressupõe três condições:

1. a sessão APEX é de um workspace com o atributo *Component Availability* `Allow Hosting Extensions` habilitado (um *extension workspace*);
2. esse workspace criou links no seu *Extension Menu* com `public` = `Yes`;
3. outro workspace assinou o menu publicado e deu acesso de leitura ao workspace de extensão.

A API pode ser chamada em *Automations* ou em sessões de banco com contexto APEX criado por `APEX_SESSION.CREATE_SESSION`. Depois de `SET_WORKSPACE` com o nome ou ID do workspace assinante, as views públicas do dicionário APEX (`APEX_APPLICATIONS`, `APEX_APPLICATION_*` …) passam a mostrar os metadados **desse** workspace, e não mais os do próprio workspace de extensão.

- **Quando usar:** ferramentas internas de qualidade e governança (auditoria de apps, relatórios de componentes, links de volta ao Builder) oferecidas a vários workspaces.
- **Quando não usar:** em apps de negócio comuns. Elas não precisam de nada deste package.

Fonte: [APEX_EXTENSION](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXTENSION.html)

### APEX_EXTENSION: referência completa de procedures e functions

| Item | Tipo | O que faz |
|---|---|---|
| `ADD_MENU_ENTRY` | procedure | Adiciona link ao menu de extensões do Builder (exige `APEX_ADMINISTRATOR_ROLE`) |
| `GET_BUILDER_LINK` | function | Gera fragmento de ação (href) ou data attributes que abrem o Builder focado num componente |
| `GET_GRANTOR_WORKSPACE` | function | Nome do workspace que invocou a extensão (o *grantor*) |
| `REMOVE_MENU_ENTRY` | procedure | Remove link do menu de extensões (exige `APEX_ADMINISTRATOR_ROLE`) |
| `SET_WORKSPACE` (Signature 1) | procedure | Troca o workspace corrente pelo ID |
| `SET_WORKSPACE` (Signature 2) | procedure | Troca o workspace corrente pelo nome |

O package não declara constantes nem tipos.

Fonte: [APEX_EXTENSION](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXTENSION.html)

### APEX_EXTENSION.ADD_MENU_ENTRY e REMOVE_MENU_ENTRY: gerenciar o menu de extensões do Builder

```sql
APEX_EXTENSION.ADD_MENU_ENTRY (
    p_label            IN VARCHAR2,
    p_url              IN VARCHAR2,
    p_display_sequence IN NUMBER    DEFAULT NULL,
    p_description      IN VARCHAR2  DEFAULT NULL,
    p_is_public        IN BOOLEAN   DEFAULT FALSE,
    p_tab_identifier   IN VARCHAR2  DEFAULT NULL,
    p_workspace        IN VARCHAR2  DEFAULT NULL );

APEX_EXTENSION.REMOVE_MENU_ENTRY (
    p_label       IN VARCHAR2,
    p_workspace   IN VARCHAR2  DEFAULT NULL );
```

| Parâmetro | Descrição |
|---|---|
| `p_label` | Rótulo, **único no workspace** (também é a chave para remover) |
| `p_url` | URL do link |
| `p_display_sequence` | Ordem. Nulo calcula o valor e põe o link no fim |
| `p_description` | Descrição |
| `p_is_public` | `TRUE` disponibiliza o link aos workspaces assinantes. Só vale em workspace de extensão; caso contrário, é gravado `FALSE` |
| `p_tab_identifier` | Nome da aba do navegador onde o link abre (reutilizada se existir; vários links podem compartilhá-la). Nulo gera um nome único por link |
| `p_workspace` | Workspace alvo. Nulo usa o atual |

```sql
begin
    apex_extension.add_menu_entry(
        p_label       => 'Auditoria de Apps',
        p_url         => 'https://exemplo.com/ords/r/ext/auditoria',
        p_description => 'Relatórios de qualidade das aplicações',
        p_is_public   => true,
        p_workspace   => 'MY_EXT_WORKSPACE' );
end;

begin
    apex_extension.remove_menu_entry( p_label => 'Auditoria de Apps' );
end;
```

**Pegadinhas**
- As duas procedures exigem `APEX_ADMINISTRATOR_ROLE`.
- O exemplo oficial de `ADD_MENU_ENTRY` não tem vírgulas entre alguns parâmetros e passa `' MY_WORKSPACE'` com espaço inicial. Não copie literalmente.

Fonte: [ADD_MENU_ENTRY Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXTENSION.ADD_MENU_ENTRY-Procedure.html), [REMOVE_MENU_ENTRY Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXTENSION.REMOVE_MENU_ENTRY-Procedure.html)

### APEX_EXTENSION.SET_WORKSPACE e GET_GRANTOR_WORKSPACE: ler os metadados do workspace assinante

```sql
APEX_EXTENSION.SET_WORKSPACE ( p_id   IN NUMBER );    -- Signature 1
APEX_EXTENSION.SET_WORKSPACE ( p_name IN VARCHAR2 );  -- Signature 2 (nome de exibição)

APEX_EXTENSION.GET_GRANTOR_WORKSPACE
    RETURN VARCHAR2;
```

**Comportamento:**
- `SET_WORKSPACE` define qual workspace a app de extensão ou a automation está processando. Depois da chamada, todas as views do dicionário APEX mostram os metadados desse workspace.
- `GET_GRANTOR_WORKSPACE` devolve o nome do workspace que invocou a extensão, num contexto de builder extension.

```sql
-- numa página da app de extensão: analisar o workspace que abriu a extensão
begin
    apex_extension.set_workspace( p_name => apex_extension.get_grantor_workspace );
end;

select application_id, application_name
  from apex_applications;   -- agora lista as apps do workspace assinante
```

**Pegadinha:** depois de `SET_WORKSPACE`, as views deixam de mostrar o próprio workspace de extensão. Separe as consultas de antes e de depois da troca.

Fonte: [SET_WORKSPACE Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXTENSION.SET_WORKSPACE-Procedure-Signature-1.html), [SET_WORKSPACE Procedure Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXTENSION.SET_WORKSPACE-Procedure-Signature-2.html), [GET_GRANTOR_WORKSPACE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXTENSION.GET_GRANTOR_WORKSPACE-Function.html)

### APEX_EXTENSION.GET_BUILDER_LINK: link que abre o Builder focado num componente

```sql
APEX_EXTENSION.GET_BUILDER_LINK (
    p_app_id          IN NUMBER,
    p_page_id         IN NUMBER   DEFAULT NULL,
    p_view_name       IN VARCHAR2 DEFAULT NULL,
    p_component_id    IN NUMBER   DEFAULT NULL,
    p_as_data_action  IN VARCHAR2 DEFAULT 'N' )
RETURN VARCHAR2;
```

| Parâmetro | Descrição |
|---|---|
| `p_app_id` | Aplicação a abrir no Builder |
| `p_page_id` | Página. Nulo para shared components; **obrigatório** para componentes de página (itens, regiões, colunas de relatório) |
| `p_view_name` | View do dicionário APEX do componente (ex.: `APEX_APPLICATION_LIST_ENTRIES`) |
| `p_component_id` | ID do componente a focar no Designer, ou a abrir na página de edição |
| `p_as_data_action` | `N` (padrão) gera um *action fragment* para `href`; `Y` gera data attributes para a ação de um botão |

```sql
select application_name, list_name, entry_text,
       apex_extension.get_builder_link(
           p_app_id       => application_id,
           p_view_name    => 'APEX_APPLICATION_LIST_ENTRIES',
           p_component_id => list_entry_id ) as backlink
  from apex_application_list_entries;
```

**Pegadinha:** com `p_as_data_action => 'Y'`, se o valor for usado como substituição numa coluna, desligue *Escape Special Characters* nessa coluna, senão os atributos saem escapados.

Fonte: [GET_BUILDER_LINK Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXTENSION.GET_BUILDER_LINK-Function.html)


## 32. APEX_GENDEV: processar blueprints e gerar arquivos APEXlang

### APEX_GENDEV: propósito, quando usar e quando não usar

`APEX_GENDEV` é a API para trabalhar com **blueprints**: descrições de aplicação que o APEX converte nos arquivos **APEXlang** necessários para importar e instalar uma app. Na 26.1 o package tem uma única rotina, `PROCESS_BLUEPRINT`, que faz o parse do blueprint e devolve um log de erros (se houver) e um ZIP com os arquivos APEXlang.

- **Quando usar:** gerar uma app (ou o esqueleto dela) por código a partir de um blueprint, por exemplo num pipeline que valida o blueprint e entrega o ZIP para importação.
- **Quando não usar:** para editar uma app existente. Nesse caso, trabalhe nos próprios arquivos APEXlang (`.apx`) da app.
- A doc da API não descreve o formato do blueprint. Não presuma uma estrutura e valide sempre pelo `p_parsing_log`.

| Item | Tipo | O que faz |
|---|---|---|
| `PROCESS_BLUEPRINT` | procedure | Faz o parse do blueprint e devolve log de erros (JSON) e ZIP APEXlang |

Fonte: [APEX_GENDEV](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_GENDEV.html)

### APEX_GENDEV.PROCESS_BLUEPRINT: validar um blueprint e obter o ZIP APEXlang

```sql
APEX_GENDEV.PROCESS_BLUEPRINT (
    p_blueprint      in  clob,
    p_parsing_log    out clob,
    p_apexlang_zip   out blob );
```

| Parâmetro | Direção | Descrição |
|---|---|---|
| `p_blueprint` | in | Conteúdo do blueprint |
| `p_parsing_log` | out | Se houver problemas no parse, um documento JSON com todos os erros |
| `p_apexlang_zip` | out | ZIP com todos os arquivos APEXlang para instalar a app |

**Comportamento:** se `p_parsing_log` volta nulo, o blueprint é válido e o ZIP pode ser usado. Se volta preenchido, analise os erros e não use o ZIP.

```sql
declare
    l_blueprint     clob := :P1_BLUEPRINT;
    l_apexlang_blob blob;
    l_parsing_log   clob;
begin
    apex_gendev.process_blueprint(
        p_blueprint    => l_blueprint,
        p_parsing_log  => l_parsing_log,
        p_apexlang_zip => l_apexlang_blob );

    if l_parsing_log is not null then
        sys.dbms_output.put_line( 'Erro: ' || l_parsing_log );   -- JSON com os erros
    else
        apex_http.download(
            p_blob         => l_apexlang_blob,
            p_content_type => 'application/zip',
            p_filename     => 'app.zip' );
    end if;
end;
```

**Pegadinha:** o teste de sucesso é `p_parsing_log is null`. Não confie só em o BLOB vir preenchido.

Fonte: [PROCESS_BLUEPRINT Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_GENDEV.PROCESS_BLUEPRINT-Procedure.html)


## 33. Mudanças nas APIs PL/SQL no APEX 26.1 (Changes in Release 26.1)

### Changes in Release 26.1 do API Reference: onde ver o que mudou

O capítulo "Changes in Release 26.1" do API Reference é só um ponteiro: diz que o livro foi atualizado para a 26.1, manda usar o app **APEX Diff** (apex.oracle.com/apexdiff) para comparar especificações de packages entre versões (19.2 a 26.1) e remete às seções *PL/SQL API Updates*, *Deprecated Features* e *Desupported Features* das Release Notes. O resumo abaixo junta o que essas seções dizem sobre os packages deste documento.

Fonte: [Changes in Release 26.1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/changes-in-this-release.html), [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### APIs novas no 26.1 (APEX_INSTANCE_DEBUG, REFRESH_BUSINESS_ADMINS, DELETE_TASKS, SET_ACTIVITY_DUE_DATE, SET_TOOL_RESULT, subscription mode)

| Package | Novidade | Para quê |
|---|---|---|
| `APEX_INSTANCE_DEBUG` (package novo) | Listar debug logs e activity logs em SQL*Plus/SQLcl | Usuários de banco com `APEX_ADMINISTRATOR_READ_ROLE` ou `APEX_ADMINISTRATOR_ROLE`; antes exigia `SYS`. Os scripts de `apex/utilities/debug` passaram a usá-lo |
| `APEX_HUMAN_TASK.REFRESH_BUSINESS_ADMINS` | procedure nova | Recalcular business admins de tarefas pendentes quando os admins atuais saíram do papel |
| `APEX_HUMAN_TASK.DELETE_TASKS` | procedure nova | Apagar instâncias de tarefa que não interessam mais |
| `APEX_WORKFLOW` (exclusão de instâncias) | procedure nova | As Release Notes chamam de `APEX_WORKFLOW.DELETE_TASKS`, mas a página do API Reference documenta **`APEX_WORKFLOW.DELETE_WORKFLOWS`**; use o nome do API Reference |
| `APEX_WORKFLOW.SET_ACTIVITY_DUE_DATE` | procedure nova | Ajustar o vencimento de uma atividade, por exemplo para workflows importados que ficariam presos com o prazo vencido |
| `APEX_AI.SET_TOOL_RESULT` | procedures novas | Devolver o resultado de ferramentas (tools) ao modelo |
| `APEX_AI.GENERATE`/`CHAT` | novas sobrecargas com `p_agent_static_id`; anexos (`t_attachments`, com `detail_level` `low`/`high`/`auto`); resposta em JSON (`p_response_json_schema`); tools definidas em tempo de execução | Ver seção 19 |
| `APEX_APPLICATION_INSTALL.SET_SUBSCRIPTION_MODE` / `SET_SUBSCRIPTION_MAPPING` | procedures novas | Controlar como as assinaturas (*subscriptions*) são tratadas na instalação e remapear assinaturas para outra app; só para arquivos exportados no 26.1 ou depois |
| `APEX_DB_DICTIONARY` (package novo, fora deste documento) | descrição de tabelas/views legível por humanos e LLMs | Usa `DBMS_DEVELOPER` (Oracle AI Database 26ai e patches recentes do 19c) |
| `APEX_SHARED_COMPONENT.REFRESH`/`PUBLISH` (fora deste documento) | passam a valer para temas | |

Também houve correções de documentação: valores de parâmetros de `APEX_INSTANCE_ADMIN` e tipos de dados de `APEX_EXEC` e `APEX_EXPORT`.

Fonte: [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### Mudanças de comportamento no 26.1 que afetam estas APIs (APEX_EXPORT, APEX_EXEC/OData, APEX_AI, REST Data Sources, workflows)

- **`APEX_EXPORT` e APEXlang:** o export APEXlang inclui os static files binários. Quem consome `APEX_EXPORT` por programa deve olhar `APEX_T_EXPORT_FILE.contents_blob` para arquivos binários, e não só `contents`.
- **OData com DML:** REST Data Sources do tipo OData passam a aceitar insert/update/delete, inclusive via `APEX_EXEC`.
- **AI Configurations viraram AI Agents:** `APEX_AI.GENERATE` e `APEX_AI.CHAT` com `p_config_static_id` estão **deprecated** (Signature 3 de cada); use as sobrecargas com `p_agent_static_id`. *RAG Sources* viraram *Augment System Prompts*. As views `apex_appl_ai_configs` e `apex_appl_ai_config_rag_srcs` estão deprecated (use `apex_appl_ai_agents` e `apex_appl_ai_agent_tools`).
- **Agentes com ferramentas que pedem aprovação do usuário** só podem ser usados por componentes de front-end (Show AI Assistant, Generate Text with AI); chamá-los pelas APIs `APEX_AI` não é suportado.
- **OAuth em REST:** Web Credentials *OAuth2 Client Credentials* aceitam escopo na invocação (parâmetro novo `P_SCOPE` nas APIs PL/SQL; o escopo da credencial vira "default scope"); Client Credentials com refresh token; novo tipo *OAuth2 Password Flow*; atributo *Token Authentication Method*.
- **Workflows e tasks:** fluxos paralelos; *Data Segregation* por Tenant ID da sessão APEX nas tabelas de instâncias; instâncias suspensas durante upgrade de app são retomadas automaticamente; Authorization Scheme como participante de tarefa; *Excluded Owner/Admin*; pedir informação a outro usuário (`p_to_user`).
- **SMTP por workspace:** as credenciais SMTP podem ser configuradas por workspace (Workspace Preferences), não só na instância.
- **Network services:** fora do Autonomous Database, o DBA precisa conceder ACL de rede (`DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE`) ao dono do schema do APEX (`APEX_260100`) para `APEX_MAIL`, `APEX_WEB_SERVICE`, REST Data Sources, LDAP e impressão remota. No Autonomous Database isso não é necessário.

Fonte: [Changed Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html), [Deprecated Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/deprecated-features.html), [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### APIs deprecated relacionadas a este documento (consolidado)

| API | Status | Use no lugar |
|---|---|---|
| `APEX_APPROVAL` (package inteiro) | Deprecated desde 24.1 | `APEX_HUMAN_TASK` |
| `APEX_AUTOMATION.ABORT` | Deprecated desde 24.1 | `APEX_AUTOMATION.TERMINATE` |
| `APEX_BACKGROUND_PROCESS.ABORT` (2 assinaturas) e `c_status_aborted` | Deprecated | `APEX_BACKGROUND_PROCESS.TERMINATE`, `c_status_terminated` |
| `APEX_AI.GENERATE` Signature 3 e `APEX_AI.CHAT` Signature 3 (`p_config_static_id`) | Deprecated no 26.1 | Sobrecargas com `p_agent_static_id` |
| `APEX_PLUGIN_UTIL.EXECUTE_PLSQL_CODE` | Deprecated | `APEX_EXEC.EXECUTE_PLSQL` |
| `APEX_WORKFLOW.t_workflow_parameter.string_value` | Deprecated | campo `value` |
| Modelos Cohere `command-r-08-2024`, `command-r-plus-08-2024`, `command-latest`, `command-plus-latest` (OCI Generative AI) | Deprecated | `cohere.command-a-03-2025` |
| Export Repository | Deprecated | — |

Fonte: [Deprecated Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/deprecated-features.html), [Deprecated in Previous Releases](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/deprecated-previous-releases.html)

### Bugs corrigidos no 26.1 que mudam o comportamento destas APIs

Itens da lista *Fixed Bugs* que dizem respeito aos packages deste documento (se você já contornava o problema, revise o contorno):

| Bug | Correção |
|---|---|
| 37242841 | `APEX_WEB_SERVICE` passa a respeitar o proxy ao seguir um redirect HTTP 302 |
| 37282977 | `APEX_EXPORT` deixava de considerar `p_csv_enclosed_by` com `p_format` CSV |
| 37466233 | `APEX_INSTANCE_ADMIN.SET_PARAMETER` com `LOGIN_MESSAGE` dava `APEX.INSTANCE_ADMIN.PARAMETER_REGEXP_MISMATCH` |
| 37466556 | Data Export XLSX: limite de 32K por tabela |
| 37727402 | `APEX_DATA_PARSER` podia devolver conteúdo incompleto com cabeçalhos pulados via `p_skip_rows` |
| 37775131 | `APEX_SEARCH.SEARCH` passa a devolver o Static ID da search config |
| 38484067 | `APEX_AUTOMATION.LOG_*` não tinham efeito nos códigos *Init*, *Before Rows* e *Cleanup* |
| 38623845 | `APEX_INSTANCE_ADMIN` não aceitava `system:` como wallet path |

Fonte: [Fixed Bugs](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/fixed-bugs.html)


## 34. Aplicação no Corlix Hub

O Corlix Hub (app 100, `CORLIXHUB`, workspace/schema `WKSP_CORLIXHUB`, APEX 26.1.5 no Autonomous Database da OCI) **ainda não usa nenhum dos packages deste documento**: a busca em `corlixhub/` e `modulos/` só encontra `APEX_UTIL.CREATE_USER`, `APEX_ACL`, `APEX_AUTHORIZATION`, `APEX_PAGE.GET_URL`, `APEX_ESCAPE`, `APEX_ERROR` e `APEX_SESSION`. As seções abaixo indicam onde cada API se encaixa no projeto e que regras do projeto valem para elas. São propostas: antes de implementar, confirme com o time e siga `docs/ai-context/08-convencoes-e-pegadinhas.md`.

### Corlix Hub: regras do projeto aplicadas às APIs de dados, integração e processos

- **Multiempresa:** toda query que alimenta `APEX_EXEC.OPEN_QUERY_CONTEXT`, `APEX_DATA_EXPORT`, *automation queries*, `GET_TASKS`/`GET_WORKFLOWS` filtradas e relatórios de fila de e-mail precisa filtrar por `id_empresa` (no app, o item `G_ID_EMPRESA`, preenchido pelo app process `SET_G_ID_EMPRESA`). Atenção em código que roda **fora da requisição do usuário** (automations, execution chains em background, jobs): o valor de `G_ID_EMPRESA` vem da sessão; em automations não há usuário logado, então a empresa tem de vir dos próprios dados (coluna `id_empresa` da linha) e não de item de sessão.
- **Tarefas e workflows multiempresa:** o 26.1 grava o *Tenant ID* da sessão APEX nas instâncias de workflow e de tarefa (*Data Segregation*) e a Unified Task List respeita esse tenant. Isso é diferente do filtro por `id_empresa` do projeto; se adotar tasks/workflows, decida com o time se o tenant da sessão vai espelhar `id_empresa`.
- **Páginas administrativas com `authorizationScheme`:** páginas que exponham operações administrativas destas APIs (ex.: Monitor de e-mails, administração de tarefas, terminar automations/execuções em background, exportar dados) devem ter `authorizationScheme` na própria página, como a p14 e a p23 (`@admin-rh`). Para a visão de admin de tarefas, `APEX_HUMAN_TASK.IS_BUSINESS_ADMIN` pode compor um authorization scheme.
- **Links com checksum:** URLs colocadas em e-mails (`APEX_MAIL`), em `p_subject`/detalhes de tarefas ou devolvidas por Ajax devem ser geradas com `apex_page.get_url`, nunca concatenadas à mão.
- **pt-BR:** assuntos e corpos de e-mail, mensagens de `SET_STATUS`, `LOG_INFO`, `ADD_TO_HISTORY` e textos de tarefa em português.
- **Network ACL:** o ambiente é Autonomous Database; segundo as Release Notes do 26.1, ali o APEX acessa endpoints externos sem configurar ACL. Num ambiente local (o antigo Docker), `APEX_MAIL`, `APEX_WEB_SERVICE` e REST Data Sources exigiriam o `DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE` para `APEX_260100`.

Fonte: [Changed Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html), [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### Corlix Hub: onde cada package se encaixa

| Necessidade no Corlix Hub | API sugerida | Observações |
|---|---|---|
| Solicitação de correção do histórico (p22 envia, p23 responde, hoje via `pkg_historico_carreira.solicitar_correcao`/`responder_solicitacao`) | `APEX_HUMAN_TASK` (Task Definition de aprovação; `CREATE_TASK` com `p_detail_pk` = ID da solicitação; `APPROVE_TASK`/`REJECT_TASK`) | Ganha caixa de entrada, prazos, delegação e histórico. Exige `CREATE JOB` no schema. Manteria a regra de negócio no package e usaria a tarefa para o fluxo. Não use `APEX_APPROVAL` (deprecated) |
| Movimentação de carreira com várias aprovações (p18) | `APEX_WORKFLOW` | Só se o fluxo passar a ter etapas (gestor → RH); para uma aprovação única, Human Task basta |
| Avisar colaborador de comunicado (p17), resposta da correção (p23), novo usuário (p14) | `APEX_MAIL.SEND` com *Email Template* + `APEX_MAIL.PUSH_QUEUE` só quando precisar envio imediato | SMTP pode ser configurado por workspace no 26.1. Link do e-mail com `apex_page.get_url` |
| Exportar o Dashboard RH (p20) ou listas para Excel/PDF | `APEX_DATA_EXPORT.EXPORT` + `DOWNLOAD`, com `APEX_EXEC.OPEN_QUERY_CONTEXT` sobre query filtrada por `id_empresa` | Para anexar em e-mail, gere o BLOB e use `APEX_MAIL.ADD_ATTACHMENT` |
| Carga de colaboradores/departamentos a partir de planilha (hoje só existe `database/dados/departamento.xlsx`) | `APEX_DATA_PARSER.PARSE` sobre `apex_application_temp_files` | Validar e gravar sempre com o `id_empresa` da sessão |
| ViaCEP na p16 (hoje `fetch` no navegador) | Opcionalmente `APEX_WEB_SERVICE.MAKE_REST_REQUEST` no servidor | O `fetch` atual não passa pelo servidor; a versão PL/SQL permitiria validar o CEP no submit |
| Rotinas periódicas (ex.: lembrar formações a vencer, p19/p21) | *Automation* + `APEX_AUTOMATION` (`LOG_*`, `SKIP_CURRENT_ROW`) | Query da automation sempre por `id_empresa` vindo dos dados |
| Recalcular indicadores pesados do Dashboard RH | *Execution Chain* em background + `APEX_BACKGROUND_PROCESS.SET_PROGRESS` | A página consulta `GET_EXECUTION` |
| Resumir comunicados, sugerir textos | `APEX_AI.GENERATE` com AI Agent (`p_agent_static_id`) | Não use as sobrecargas com `p_config_static_id` (deprecated no 26.1) |
| Notificações (p5/p8 placeholders) | Push notifications de PWA (`APEX_PWA`) e/ou e-mail | Depende de habilitar PWA na app |

Fonte: [APEX_HUMAN_TASK](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HUMAN_TASK.html), [APEX_MAIL](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_MAIL.html), [APEX_DATA_EXPORT](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_EXPORT.html)

### Corlix Hub: export e instalação da app (APEX_EXPORT, APEX_APPLICATION_INSTALL e o backup)

- O backup (`scripts/backup/backup.sql`, via SQLcl) usa o comando `apex export` do SQLcl, não o package: `-exptype APEXLANG` para gerar o mesmo formato de `corlixhub/` e `-exptype SQL,CHECKSUM-SH256` para o `database/f100.sql`, além de `-expworkspace` para o workspace. Se alguém trocar por `APEX_EXPORT.GET_APPLICATION` em PL/SQL, lembre da mudança do 26.1: no export APEXlang os static files binários vêm em `APEX_T_EXPORT_FILE.contents_blob`, e não em `contents`.
- `database/f100.sql` continua sendo só consulta (regra 1 do projeto); para instalar a app em outro ID/workspace a partir dele, `APEX_APPLICATION_INSTALL` (`SET_WORKSPACE`, `SET_APPLICATION_ID`, `GENERATE_OFFSET`, `SET_SCHEMA`, `SET_APPLICATION_ALIAS`) é o caminho documentado. Os supporting objects da app estão vazios, então a instalação não cria tabelas; o DDL fica em `database/` e `modulos/*/instalar.sql`.

Fonte: [Changed Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html), [APEX_APPLICATION_INSTALL](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_INSTALL.html)

### Corlix Hub: checklist ao introduzir um destes packages

1. Confirme o privilégio necessário (`CREATE JOB` para workflow/tasks; SMTP configurado para e-mail; Web Credential para REST/IA).
2. Filtre por `id_empresa` em toda query; em código sem sessão de usuário, tire a empresa dos dados.
3. Coloque `authorizationScheme` na página que expõe a operação.
4. Gere links com `apex_page.get_url`.
5. Trate erros com o `log_pkg.apex_error_handler` existente (não recrie o handler sem as três linhas do módulo de carreira, ver `08`).
6. Use só APIs não deprecated (seção 33).
7. Atualize `docs/ai-context/` (02 para páginas, 05 para objetos de banco, 06 para módulos), conforme a regra 7 do projeto.
8. Passo a passo do Builder para criar Task Definitions, Workflows, Automations, Email Templates ou AI Agents vai para o **26.1.5**; caminho não conferido marcado "(confirmar no 26.1.5)".

Fonte: [APEX_WORKFLOW](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WORKFLOW.html)

