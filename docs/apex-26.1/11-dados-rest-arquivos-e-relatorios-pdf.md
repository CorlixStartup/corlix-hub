# 11 · Dados, REST, integrações, arquivos e relatórios PDF

> Base: documentação oficial Oracle APEX 26.1 (App Builder User's Guide › *Managing Application Data*, *Developing Reports* › *Printing Report Regions* e *Understanding BLOB Support*, *Managing Shared Components* › *Report Queries* e *Report Layouts*, *About Item Types*; Developer's Companion › *Integrating Remote Data*, *Exposing APIs for Integration*, *Loading External Data*, *Uploading, Viewing, and Downloading Files*, *Producing Pixel-Perfect Reports*, *Working with Local Data*, *Geocoding Addresses*, *Using Temporary Collections*; SQL Workshop Guide › *Enabling Data Exchange with RESTful Services*; API Reference: `APEX_EXEC`, `APEX_WEB_SERVICE`, `APEX_CREDENTIAL`, `APEX_REST_SOURCE_SYNC`, `APEX_DATA_PARSER`, `APEX_DATA_LOADING`, `APEX_HTTP`, `APEX_PRINT`, `APEX_COLLECTION`, `APEX_UTIL.GET_BLOB_FILE_SRC`; Administration Guide › *Configuring Report Printing for an Instance*). Gerado em 21/10/2026.

**Sumário**

1. Escolher a fonte de dados (local, DB link, REST Enabled SQL, REST Data Source, Duality View, JSON Source)
2. Web Credentials
3. Remote Servers
4. REST Enabled SQL
5. REST Data Sources (tipos, Data Profile, paginação, operações, parâmetros, cache, sincronização, pós-processamento local, Fusion/BOSS/ORDS/OData, uso em código)
6. Duality Views e JSON Sources
7. Expor APIs com ORDS (módulos, templates, handlers, bind variables, paginação, OAuth2, AutoREST)
8. Carga de dados (Data Load Definition, Data Loading page/process, `APEX_DATA_PARSER`, `APEX_DATA_LOADING`, ZIP)
9. Upload, exibição e download de arquivos (File Upload, Image Upload, BLOB, `APEX_APPLICATION_TEMP_FILES`, `APEX_HTTP.DOWNLOAD`, Object Storage)
10. Collections para dados locais e temporários
11. Relatórios PDF e impressão (Report Query, Report Layout, print server, Document Generator, `APEX_PRINT`)
12. Geocoding (Geocoded Address, Display Map, geocoding no servidor)
13. Recursos legados (Legacy Web Services, Legacy Data Loading)
14. Problemas conhecidos e troubleshooting
15. Aplicação no Corlix Hub

> Detalhes de assinatura das APIs PL/SQL ficam no [07 · API PL/SQL: dados, integração e processos](./07-api-plsql-dados-integracao-e-processos.md) e no [06 · API núcleo](./06-api-plsql-nucleo.md) (`APEX_COLLECTION`). Aqui o foco é *como usar o recurso numa app real*, com as chamadas mais usadas.

---

## 1. Escolher a fonte de dados

### Comparação: tabela local × Database Link × REST Enabled SQL × REST Data Source

O engine do APEX roda dentro do Oracle Database, então tabelas e views do schema de parse têm acesso com latência zero, índices e todo o SQL. Qualquer dado remoto (outro banco ou REST API) passa pela rede e é bem mais lento. Por isso a doc recomenda considerar **replicar dados remotos em tabelas locais** com um algoritmo de atualização, em vez de consultar o remoto a cada page view.

| Opção | Como acessa | Pode juntar com tabela local na mesma query? | DML | Quando usar |
|---|---|---|---|---|
| Tabela/view local | SQL direto | Sim | Sim | Padrão. Sempre que possível. |
| Database Link (`tabela@dblink`) | SQL*Net | **Sim** (opera no nível do SQL) | Sim | Banco Oracle remoto na mesma rede. SQL*Net costuma ser problemático pela internet ou até a nuvem. |
| REST Enabled SQL | JSON sobre HTTP(S), via ORDS remoto | **Não** (a região inteira roda no remoto) | Sim no Oracle; MySQL só leitura | Banco Oracle ou MySQL remoto acessível só por HTTP (nuvem, internet). |
| REST Data Source | HTTP(S) para qualquer REST API | Só via *Local Post-Processing* (`#APEX$SOURCE_DATA#`) | Se definir operações de insert/update/delete | APIs REST de terceiros, Fusion Apps, ORDS, OData, feeds JSON. |
| Duality View / JSON Source | SQL local ou via REST Enabled SQL | — | Sim (DML context) | Dados JSON-relacionais no 26ai (duality) ou tabelas com colunas JSON. |

- O privilégio `CREATE DATABASE LINK` **não** é concedido por padrão ao schema de um workspace provisionado: um DBA precisa conceder. Cria-se o link em SQL Workshop › Object Browser › Create › Database Link (o nome segue as regras de nomes Oracle: sem espaço e sem começar com número ou `_`).
- REST Enabled SQL é definido no nível do workspace e pode ser usado por qualquer app do workspace.

Fonte: [Accessing Data with Database Links](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/accessing-data-with-database-links.html), [Understanding REST Enabled SQL Service References](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-rest-enabled-sql-service-references.html), [Database Concepts Primer](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/database-concepts-primer.html)

### Sample Data e Sample Datasets (dados de exemplo)

- **Sample Data** (somente leitura): conjuntos embutidos *Employees*, *Geolocation* e *Time-Based*, escolhidos no Create Page Wizard (Data Source = Sample Data) ou no Page Designer (Source › Location = Sample Data). Dá para montar forms e grids editáveis sobre eles, mas qualquer INSERT/UPDATE/DELETE gera erro, porque os dados são read-only. No Page Designer dá para trocar o conjunto (Products por padrão, Employees, Tasks ou Projects).
- **Sample Datasets** (editáveis): instalados em SQL Workshop › Utilities › Sample Datasets (Countries, Customer Orders, EMP/DEPT, HR Data, Health Updates, Project Data, Tasks Spreadsheet). EMP/DEPT pode ser instalado em vários idiomas.
- **Data Workshop** importa Excel, CSV, JSON ou XML para uma tabela nova ou existente, inferindo tipos de dado. Aceita arquivo local ou de um bucket do OCI Object Storage.

Fonte: [Working with Sample Data (App Builder)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/working-with-sample-data.html), [Installing a Sample Dataset](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/installing-sample-dataset.html), [Importing Data from a File](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/importing-data-file.html)

### Modelagem local: Quick SQL e Create Data Model Using AI

O Quick SQL descreve tabelas em notação abreviada: uma entidade por linha, atributos indentados com tipo (`vc100`, `num`, `date`), PK `ID` criada automaticamente e FKs com `/fk tabela` ou `/references tabela`. A aba Diagram atualiza enquanto você digita, e *Review and Run* salva o script e cria as tabelas. O assistente *Create Data Model Using AI* (APEX AI Assistant) devolve uma proposta em Quick SQL a partir de um texto em linguagem natural; exige um Generative AI Service configurado (ver doc 10).

```text
sessions
    title vc100
    starts date
    duration num
    room_id /fk rooms
```

Fonte: [Creating Data Models with Quick SQL](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/creating-data-models-quick-sql.html), [Creating a Data Model Using Natural Language](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/creating-data-model-using-natural-language.html)

---

## 2. Web Credentials

### Web Credentials: o que são, escopo e armazenamento

Uma **Web Credential** guarda de forma segura os dados de autenticação usados por componentes e APIs do APEX para chamar REST APIs, REST Enabled SQL, print servers etc.

- É definida no **nível do workspace**: fica visível para todas as apps do workspace. Acesso: App Builder › Workspace Utilities › Web Credentials, ou Shared Components › Workspace Objects › Credentials.
- Segredos (password, client secret, private key) são **criptografados e nunca podem ser lidos de volta em texto claro**. Client ID / username **não** são criptografados.
- O APEX **não grava segredos nos logs de debug** quando a credencial é do tipo HTTP Header ou URL Query String. Por isso, para tokens e API keys, use uma credencial em vez de um parâmetro estático da REST Data Source.
- Uma credencial pode ser definida no Remote Server (vale para todas as REST Data Sources que usam aquele servidor) ou na própria REST Data Source; a da REST Data Source **prevalece**.
- **Static ID**: usado em chamadas de API (`p_credential_static_id`) e nos arquivos de export. Se mudar o Static ID, os componentes dependentes mantêm a referência, mas chamadas de API com o ID antigo precisam ser corrigidas à mão.

Fonte: [Understanding Web Credentials](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-web-credentials.html), [About Authentication and Credentials in REST Data Sources](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-rest-data-sources.html), [Supply and Return Values with Parameters](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/supply-and-return-values-parameters.html)

### Web Credentials: tipos de autenticação suportados

| Authentication Type | Como funciona | Atributos principais |
|---|---|---|
| **Basic Authentication** | Envia usuário e senha em Base64 no header `Authorization`. | Client ID or Username, Client Secret or Password, Valid for URLs |
| **OAuth2 Client Credentials** | Troca client ID + secret por um access token no token server; renova sozinho quando expira. | OAuth Scope, Client ID, Client Secret, Token Authentication Method, Valid for URLs, Named Scopes |
| **OCI Native Authentication** | Assina as requisições para as REST APIs do Oracle Cloud Infrastructure. | OCI User ID (OCID), OCI Private Key (PEM), OCI Tenancy ID, OCI Public Key Fingerprint |
| **HTTP Header** | Coloca a credencial num header HTTP: nome = Credential Name, valor = Credential Secret. | Credential Name, Credential Secret |
| **URL Query String** | Acrescenta `?nome=valor` na URL (útil para API keys). Proxies e servidores intermediários **vão logar** esse valor. | Credential Name, Credential Secret |
| **OAuth2 Password Flow** | Troca client ID/secret + usuário/senha por token. Usuário e senha ficam numa segunda credencial do tipo Basic. | OAuth Scope, Client ID, Client Secret, Token Authentication Method, Authentication Credential |
| **Signed User Assertion** | Como Client Credentials, mas também afirma a identidade do usuário atual com um JWT assinado. O OAuth client precisa estar configurado como *Trusted* no Identity Provider. | Signing Credential, Audience List, Certificate Alias, Username Expression (PL/SQL sobre `:APP_USER`) |
| **User Assertion Signing Certificate** | Certificado público + chave privada usados para assinar os JWTs do tipo anterior. | Certificate, Private Key (sem as linhas `BEGIN/END`), Audience List, Certificate Alias |
| **Key Pair** | Par de chaves pública/privada (push notifications e assinatura de assertion). | Public Key, Private Key |
| **Certificate Pair** | Certificado + chave privada para autenticação SAML. Só aparece se o SAML estiver habilitado na instância. | — |

**Token Authentication Method** (OAuth2): *Basic Authentication* (client ID/secret no header Basic), *Basic Authentication and Client ID in Body*, *Client ID and Client Secret in Body* ou *Client ID in Body*. Se o token server exigir escopo, o token é pedido com o corpo `grant_type=client_credentials&scope={scope}`. **Named Scopes** são apelidos: quando uma chamada usa o nome, o APEX usa o valor real do escopo. Se o token server emitir um Refresh Token, ele é usado para renovar o access token vencido.

O Developer's Companion resume os usos: Basic para a maioria dos REST Enabled SQL; OAuth2 também serve ao fluxo Authorization Code quando usado com o Social Sign-in; OCI Native para Database Tools Connections e APIs do OCI; HTTP Header para token ou API key em header; URL Query String para API key na URL; Key Pair para push e assinatura de assertion.

Fonte: [About Supported Authentication Types in Web Credentials](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-web-credentials.html), [Creating Web Credentials](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-web-credentials.html), [Configuring Secure Web Credentials](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configuring-secure-web-credentials.html)

### Web Credentials: Valid for URLs (proteção contra vazamento)

O atributo **Valid for URLs** (uma URL por linha) impede que o APEX envie a credencial, por engano, para outro servidor. A cada uso, o APEX confere se a URL chamada **começa com** uma das URLs da lista; se não começar, a chamada falha com `Credential is not allowed to be used for this URL endpoint`. Exemplo para restringir a um namespace do OCI Object Storage:

```text
https://objectstorage.eu-frankfurt-1.oraclecloud.com/n/x1y2z3a4b5c6/b/
```

Quando a credencial usa uma *database credential*, o APEX não tem acesso ao segredo e **não consegue aplicar** o Valid for URLs; o atributo fica desabilitado.

Fonte: [Protecting Web Credentials by Defining Valid URLs](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-web-credentials.html), [Defining OCI Web Credential for REST APIs](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/defining-oci-web-credential-rest-apis.html)

### Web Credentials com Database Credential (DBMS_CREDENTIAL / DBMS_CLOUD)

Disponível só no Oracle Database 26ai ou no Autonomous Database 19c ou superior. Vale para os tipos Basic, OAuth2 Client Credentials e Signed User Assertion (switch **Use Database Credential**). Efeitos:

- O client ID e o segredo ficam numa credencial mantida pelo banco (`DBMS_CREDENTIAL` ou `DBMS_CLOUD`); o APEX não vê o segredo, e os campos Client ID, Client Secret e Valid for URLs somem.
- As requisições HTTP passam a ser feitas **no contexto do schema de parse da app**, e não do engine do APEX. Portanto **as ACLs de rede (`DBMS_NETWORK_ACL_ADMIN`) precisam ser concedidas ao schema de parse**.
- A database credential precisa ser acessível ao schema de parse. Se o parâmetro de instância `INSTANCE_DBMS_CREDENTIAL_ENABLED` = `Y`, uma credencial acessível ao schema do engine (`APEX_NNNNNN`) pode ser usada em todos os workspaces.

Fonte: [Using a Database Credential with Web Credentials](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-web-credentials.html)

### Web Credentials: export, import, Prompt on Install e exclusão

- Ao exportar uma app, as credenciais **usadas** entram no arquivo, mas **sem segredos** (o APEX nunca exporta senhas nem client secrets). No import, se o workspace de destino já tiver uma credencial com o mesmo Static ID, ela é reaproveitada; senão, é criada.
- **Prompt On Install**: pede os valores da credencial na instalação em outra instância. Quando há Client ID/Username informado, os prompts são sempre gerados.
- Não é possível excluir uma credencial que esteja referenciada no workspace. O relatório **Utilization** lista onde cada uma é usada e tem o botão *Delete Unused*; **History** mostra alterações recentes.

Fonte: [Exporting and Importing Web Credentials](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-web-credentials.html), [Editing or Deleting Credentials](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-or-deleting-credentials.html), [Viewing Credential Utilization](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/viewing-credential-utilization.html)

### Web Credentials em PL/SQL (APEX_CREDENTIAL)

O pacote `APEX_CREDENTIAL` altera credenciais de forma persistente ou só para a sessão APEX atual.

```sql
-- Credencial do usuário só nesta sessão (ex.: Basic informado pelo usuário final)
apex_credential.set_session_credentials(
    p_credential_static_id => 'LOGIN_ERP',
    p_username             => :P10_USUARIO,
    p_password             => :P10_SENHA);

-- Trocar client id/secret de forma persistente (todas as sessões).
-- Tokens já guardados para a credencial são apagados.
apex_credential.set_persistent_credentials(
    p_credential_static_id => 'OAUTH_ERP',
    p_client_id            => '...',
    p_client_secret        => '...');

-- Criar a definição (depois chame set_persistent_credentials)
apex_util.set_workspace(p_workspace => 'MEU_WORKSPACE');
apex_credential.create_credential(
    p_credential_name      => 'OAuth ERP',
    p_credential_static_id => 'OAUTH_ERP',
    p_authentication_type  => apex_credential.c_type_oauth_client_cred,
    p_scope                => 'email',
    p_allowed_urls         => apex_t_varchar2('https://erp.example.com/'));

-- Trocar o escopo (limpa os tokens existentes); p_named_scopes é um array JSON
apex_credential.set_scope(
    p_credential_static_id => 'OAUTH_ERP',
    p_scope                => 'hr');
```

Tipos aceitos em `create_credential`: `C_TYPE_BASIC`, `C_TYPE_OAUTH_CLIENT_CRED`, `C_TYPE_JWT`, `C_TYPE_OCI`, `C_TYPE_HTTP_HEADER`, `C_TYPE_HTTP_QUERY_STRING`. Para OCI, `set_persistent_credentials` usa `p_client_id` = OCID do usuário, `p_client_secret` = chave privada, `p_namespace` = OCID do tenancy e `p_fingerprint` = fingerprint.

Uma REST Enabled SQL com **Store Credentials** desligado cria a credencial vazia; nesse caso a app precisa chamar `APEX_CREDENTIAL.SET_SESSION_CREDENTIALS` antes de usar a referência.

Fonte: [APEX_CREDENTIAL](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_CREDENTIAL.html), [SET_SESSION_CREDENTIALS Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_SESSION_CREDENTIALS-Procedure-Signature-1.html), [SET_PERSISTENT_CREDENTIALS Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_PERSISTENT_CREDENTIAL-Procedure-Signature-1.html), [CREATE_CREDENTIAL Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CREATE_CREDENTIAL-Procedure-Signature-1.html), [SET_SCOPE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_CREDENTIAL.SET_SCOPE-Procedure.html)

### Web Credentials fora de uma sessão APEX (SQLcl, jobs)

`APEX_WEB_SERVICE` pode usar Web Credentials fora de uma app (SQLcl, job do Scheduler) desde que o usuário do banco esteja mapeado a um workspace. Se estiver mapeado a vários, chame antes `apex_util.set_workspace(p_workspace => 'X')` ou `apex_util.set_security_group_id(...)`. Usuários de banco sem workspace não conseguem usar o pacote, a não ser que tenham o papel `APEX_ADMINISTRATOR_ROLE`.

Fonte: [About Web Credentials and APEX_WEB_SERVICE](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/about-web-credentials-APEX_WEB_SERVICE.html)

---

## 3. Remote Servers

### Remote Server: Base URL + Service URL Path, tipos e escopo

O APEX divide a URL de uma REST Data Source em duas partes:

- **Base URL**, guardada num objeto **Remote Server** (servidor, porta e prefixo de caminho/contexto);
- **Service URL Path**, específica da REST Data Source.

Na execução, a URL final é `Base URL` + `Service URL Path`. Vários REST Data Sources compartilham o mesmo Remote Server, e mudar a Base URL redireciona todos de uma vez (de teste para produção, por exemplo). Remote Servers são **objetos do workspace** (visíveis em todas as apps). Ao criar uma REST Data Source, o wizard detecta se a URL bate com a Base URL de um Remote Server existente e propõe reaproveitá-lo.

**Server Type**:

| Tipo | Uso |
|---|---|
| REST Data Source | Consumir uma REST API |
| Authentication | Servidor de autenticação (token server, Social Sign-in) |
| Print Server | Print server externo no workspace (por padrão vale a configuração da instância) |
| File Server | Armazenamento remoto de arquivos (ex.: Static Application Files no OCI Object Storage) |

Atributos: Name (único na app), Static Identifier (usado em APIs e no import), Endpoint URL, **Prompt on Install** (pede a URL ao instalar a app em outro workspace), HTTPS Host Name (nome a comparar com o CN do certificado; aceita `*.example.com`), PL/SQL Code e **Configuration Procedure** (Flexible Remote Server).

Boa prática para DEV × PROD: estude as URLs e coloque **na Base URL só a parte que muda entre ambientes**, deixando no Service URL Path o que é igual nos dois. O valor da Base URL é "grudado" ao ambiente: reimportar a app em PROD não sobrescreve a Base URL configurada lá.

Fonte: [Understanding Remote Servers](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-remote-servers.html), [Creating a Remote Server](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-a-remote-server.html), [Service URL Uses Remote Server](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/service-url-uses-remote-server.html), [Best Practices for Configuring REST Service Base URL](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/best-practices-for-configuring-rest-service-base-url.html)

### Flexible Remote Server: Base URL calculada em tempo de execução (Configuration Procedure)

Se o atributo **Configuration Procedure** estiver preenchido (procedure do banco, de package ou do campo PL/SQL Code), o engine a executa a cada invocação e usa o resultado para montar a URL. A assinatura é fixa:

```sql
procedure cfg_servidor(
    p_info   in            apex_plugin.t_remote_server_info,
    p_config in out apex_plugin.t_remote_server_config)   -- os exemplos da doc usam "out"
is
begin
    -- base_url troca a URL; substitutions troca #NOME# na base url/endpoint
    p_config.base_url      := 'https://app#app_id#.example.com/#tenant#';
    p_config.substitutions := apex_t_varchar2();
    apex_string.plist_put(p_config.substitutions, 'app_id', v('APP_ID'));
    apex_string.plist_put(p_config.substitutions, 'tenant', v('G_TENANT'));
end;
```

- Casos de uso: URL dependente do ambiente (DEV/TEST/PROD) e URL dependente de dados da app ou do usuário (tabela de configuração, itens de sessão, application items).
- O resultado é **cacheado dentro do mesmo request** (page view ou page processing).
- Só vale para Remote Servers do tipo REST Data Source, Authentication e para os usados por REST Enabled SQL.
- Alternativa em script de deploy: `APEX_APPLICATION_ADMIN.SET_REMOTE_SERVER` (app já instalada) ou `APEX_APPLICATION_INSTALL.SET_REMOTE_SERVER` (durante o import), que mudam Base URL e HTTPS host pelo Static ID; para REST Enabled SQL aceitam também `p_ords_timezone`, `p_default_database` e `p_mysql_sql_modes`.

```sql
begin
    apex_application_admin.set_remote_server(
        p_static_id => 'API_ERP',
        p_base_url  => 'https://erp.prod.example.com/');
end;
```

Fonte: [About Flexible Remote Servers](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-remote-servers.html), [APEX_APPLICATION_ADMIN.SET_REMOTE_SERVER Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_ADMIN.SET_REMOTE_SERVER-Procedure.html), [APEX_APPLICATION_INSTALL.SET_REMOTE_SERVER Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_REMOTE_SERVER-Procedure.html)

### Remote Servers: export/import, exclusão e relatórios

Na exportação da app, os Remote Servers referenciados vão junto. No import, se já existir no workspace de destino um Remote Server com o mesmo Static ID, ele é usado; senão é criado a partir do arquivo. Um Remote Server referenciado por alguma app não pode ser excluído. Os relatórios **Utilization** e **History** (Workspace Utilities › Remote Servers) mostram uso e alterações.

Fonte: [Exporting and Importing Remote Server Information](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-remote-servers.html), [Editing or Deleting a Remote Server](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-or-deleting-a-remote-server.html)

---

## 4. REST Enabled SQL

### REST Enabled SQL: o que é e requisitos

Uma **REST Enabled SQL Service reference** permite executar SQL e PL/SQL de componentes num banco remoto através do recurso REST-Enabled SQL do ORDS: o APEX envia o SQL por HTTP e recebe um JSON auto-descritivo com metadados, linhas e paginação. É uma definição de workspace e pode ser usada em Interactive Reports, Interactive Grids, Classic Reports, forms, master-detail, calendários, JET charts, trees, Cards, mapas, LOVs, automations e processos PL/SQL.

Requisitos:
1. Banco remoto Oracle (ou MySQL) com ORDS à frente. A seção de requisitos mínimos pede **ORDS 23.3 ou superior** (a página "Before You Begin" ainda cita 20.x; siga o 23.3). Esse ORDS é independente do ORDS que serve o APEX.
2. O recurso REST Enabled SQL configurado e habilitado no ORDS remoto.
3. No schema remoto, rodar `ORDS.ENABLE_SCHEMA` (e `commit`).
4. RESTful Services habilitado no workspace ou na instância local.

URL: `https://host[:porta]/ords/<schema_alias>`. **Não acrescente** `/_/sql`, o APEX adiciona sozinho. Para OCI Database Tools Connection (inclusive MySQL HeatWave no OCI), a URL tem o OCID da conexão: `https://sql.dbtools.<região>.oci.oraclecloud.com/20201005/ords/<connection_ocid>`, com uma credencial OCI Native Authentication.

```sql
-- no schema remoto
begin
    ords.enable_schema;
end;
/
commit;
```

Fonte: [Before You Begin: REST Enabled SQL Service Requirements](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/rest-enabled-sql-requirements.html), [REST Enabled SQL Service Reference Requirements](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-rest-enabled-sql-service-references.html), [REST-Enabled SQL Service URL](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/rest-enabled-sql-service-url.html)

### REST Enabled SQL: criar a referência e atributos

Caminho: App Builder › Workspace Utilities › REST Enabled SQL Services › Create (ou Shared Components › Workspace Objects › REST Enabled SQL Databases).

- **General**: Name, Endpoint URL.
- **Authentication**: credencial existente ou nova. Para Oracle: Basic (Client ID = usuário do banco, **convertido para maiúsculas**; prefixe com `!` para manter o caso) ou OAuth2 Client. Para MySQL, ligue **Case Sensitive User Name** (usuários MySQL costumam ser minúsculos) e escolha a **Default Database** depois do teste.
- **Session attributes**: *Initialization Code* (roda logo após conectar, antes do SQL do componente) e *Cleanup Code* (roda depois).
- **Advanced**: Static ID (identifica a referência no export/import) e **Server Time Zone** (fuso usado pelo serviço para DATE/TIMESTAMP; é atualizado a cada *Save and Test*).
- Ao clicar em Create, o APEX testa URL e credencial e mostra uma confirmação.
- Não é possível excluir uma referência usada por algum componente. Há relatórios Utilization e History.

Fonte: [Creating a REST Enabled SQL Service Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-a-rest-enabled-sql-service-reference.html), [Editing a REST Enabled SQL Service Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-rest-enabled-sql-service-reference.html), [Example: Creating REST Enabled SQL Service Reference on MySQL](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-rest-enabled-sql-example-mysql.html)

### REST Enabled SQL: usar em regiões e componentes

No Create Page Wizard escolha Data Source = REST Enabled SQL e a referência; em componentes existentes, no Page Designer: **Source › Location = REST Enabled SQL**, **Remote Server** = referência, **Type** = Table/View ou SQL Query (também Function Body Returning SQL Query). Em charts, configure isso na **Series**. No Oracle remoto todas as operações de leitura e escrita funcionam; o filtro do usuário em IR/IG é convertido em SQL do dialeto remoto e empurrado para lá.

Limites com **MySQL** (só leitura):

| Componente | Não suportado |
|---|---|
| Interactive Grid / Form | Edição (DML). Control breaks exigem PK definida. |
| Interactive Report / IG / Charts | Pivot, Flashback, algumas agregações (Ratio To Report, Median, Approx Count Distinct); LOV estática para exibir coluna; box plot |
| Faceted Search / Smart Filters | Facets multivalor |
| Calendar | Drag and drop |
| Map | Tipo geometry nativo do MySQL; a query precisa devolver GeoJSON |
| Tree | Coluna de Order Siblings By precisa ser `VARCHAR` |
| Execute Code / Automations | MySQL não aparece como alvo do Execute Code; em automations só serve para a query |
| BLOB | Não suportado em IR/Classic Report via REST Enabled SQL; suportado em Cards e Form (exibição) |

Fonte: [Specifying a REST Enabled SQL Reference in an Existing Component](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/rest-enabled-sql-updating-components.html), [About MySQL Support](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-rest-enabled-sql-service-references.html), [Using a REST-Enabled SQL Service](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-rest-enabled-sql-service.html)

### REST Enabled SQL: Flexible Remote Server, export e import

A Configuration Procedure dos Remote Servers (ver §3) também vale para REST Enabled SQL. No export, as referências usadas vão no arquivo; no import, o APEX reaproveita uma referência com o mesmo Static ID ou cria uma nova.

Fonte: [Populating the Endpoint URL Dynamically](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-rest-enabled-sql-service-references.html), [Exporting and Importing REST Enabled SQL Services](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-rest-enabled-sql-service-references.html)

---

## 5. REST Data Sources

### REST Data Source: conceito e tipos (Simple HTTP, ORDS, REST Enabled SQL Query, SaaS, BOSS, OCI, OData)

Uma **REST Data Source** (Shared Components › Data Sources › REST Data Sources) descreve uma REST API ou feed JSON para uso declarativo em qualquer região, LOV, Report Query, sincronização, Invoke API ou código (`APEX_EXEC`). Ela contém uma ou mais **Operations** (handlers concretos) e um **Data Profile**; configurações no nível da REST Data Source valem para todas as operações.

| REST Data Source Type | Comportamento |
|---|---|
| **Simple HTTP** | O mais genérico. O APEX assume que tudo vem na primeira resposta e que o servidor **não** filtra nem ordena: filtragem e ordenação são feitas **no banco do APEX depois de buscar todas as linhas**. Tudo é configurado à mão (ou por discovery). |
| **Oracle REST Data Services** | Serviços ORDS (AutoREST e collection queries). GET/POST/PUT/DELETE padronizados; filtro e ordenação são delegados ao servidor. |
| **REST Enabled SQL Query** | REST Source sobre uma query executada numa referência REST Enabled SQL. Filtro e paginação sim, **DML não**. Útil para compartilhar a mesma query remota entre componentes e para sincronizar dados remotos com tabela local. |
| **Oracle Cloud Applications (SaaS) REST Service** | APIs de Fusion Apps cujas URLs contêm `RestApi/resources/` (`/hcmRestApi/resources/`, `/fscmRestApi/resources/`, `/crmRestApi/resources/`), Visual Builder e apps ADF BC. |
| **Oracle Cloud Applications (BOSS) REST Service** | Endpoints Business Object Spectra Service, com `/api/boss/` na URL. |
| **Oracle Cloud Infrastructure (OCI) REST Service** | APIs do OCI (ex.: Object Storage), com paginação. |
| **OData REST Service** | Protocolo OData 4.0.1 ou superior (Microsoft Graph, Dynamics 365, SAP…). |
| Plug-in | Tipos definidos por um REST Source Plug-in. |

Os tipos "por convenção" (SaaS, BOSS, ORDS, OData) descobrem automaticamente operações e colunas, montam parâmetros e payloads em tempo de execução e **delegam filtro, ordenação e paginação ao backend**, o que aproveita índices remotos. Os tipos Oracle Cloud Applications também pedem só os atributos usados pela região, mostram erros de validação do business object como erros do APEX e suportam DML em lote (útil no Interactive Grid).

Fonte: [About REST Data Source Types](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-rest-data-sources.html), [Extra Fusion Apps, ORDS, OData Features](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/extra-fusion-apps-ords-odata-features.html), [Using REST APIs as Data Sources](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-rest-apis-data-sources.html)

### REST Data Source: criar com o wizard (discovery, Advanced, manual)

Shared Components › REST Data Sources › Create › From Scratch (ou *As copy of an existing REST Data Source*, ou a partir de um REST Source Catalog).

1. **General**: REST Data Source Type, Name, **URL Endpoint** (`http://` ou `https://`), Open API URL (se informado, usa OpenAPI/Swagger na descoberta), HTTPS Host Name. **Não** coloque query string (`?a=1&b=2`) na URL: parâmetros vão no passo Advanced.
2. **Remote Server**: escolha/crie o Remote Server e ajuste o **Service URL Path**.
3. **Settings** (Simple HTTP): Pagination Type (ver seção de paginação).
4. **Authentication**: Authentication Required, credencial existente ou nova.
5. Botões finais:
   - **Discover**: faz requisições ao serviço (inclusive para buscar OpenAPI), amostra o JSON/XML e propõe um Data Profile. A prévia tem as abas *Data* (relatório com os dados), *Data Profile/Columns* (nomes, tipos e selectors; remova colunas com o "X") e *Response Body*; *More Detail* mostra corpo, headers e operações.
   - **Advanced**: define parâmetros iniciais necessários à descoberta (ex.: header `User-Agent`, query string obrigatória) e permite subir um **Response Sample** (JSON ou XML) para discovery offline.
   - **Create REST Source Manually**: cria operações e Data Profile de exemplo, **incompletos e inutilizáveis** até você ajustá-los. Use quando a API não tem GET nem OpenAPI (ex.: só POST).

Também é possível copiar de outra app (*Copy from another app*), com a opção **Copy and Subscribe** (assina o componente-mestre).

Fonte: [Creating a REST Data Source](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-a-REST-data-source.html), [Configuring REST Source for Invocation](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configuring-rest-source-invocation.html), [Copying or Subscribing to a REST Data Source](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/copying-or-subscribing-to-REST-data-source.html)

### REST Data Source: editar (atributos da fonte, autenticação, OpenAPI, avançado)

Na página da REST Data Source:

- **REST Data Source**: Name, Type, Remote Server, Base URL (somente exibição), **URL Path Prefix** (prefixo comum a todas as operações).
- **Settings**: paginação (Simple HTTP) ou SQL Query (REST Enabled SQL Query).
- **Authentication**: Credentials e **Authentication Server** (Remote Server separado, se a autenticação for em outro servidor).
- **Data Profile**: *Edit Data Profile*.
- **Operations** e **Parameters** (ver seções próprias).
- **Open API**: Use OpenAPI, *Endpoint is relative to Base URL*, OpenAPI URL.
- **REST Source Catalog**: *Save to Catalog*.
- **Advanced**: Static ID (usado em `APEX_EXEC` e `APEX_REST_SOURCE_SYNC`), **Pass ECID** (envia o Execution Context ID para rastreio ponta a ponta), **HTTP Transfer Timeout** (equivale a `UTL_HTTP.SET_TRANSFER_TIMEOUT`, evita travar a página com servidor lento), Comments.
- Operations têm um botão de **teste** ("play") na coluna Test Operation, útil para validar a fonte.
- Uma REST Data Source só pode ser excluída se nenhum componente a referenciar. Relatórios **Utilization** e **History** existem na lista.

Fonte: [Editing a REST Data Source](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-or-deleting-a-REST-data-source.html), [Listing Buckets with REST Data Source](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/listing-buckets-rest-data-sources.html)

### Data Profile: transformar JSON/XML/CSV em linhas e colunas

O **Data Profile** descreve como interpretar a resposta:

- **Format**: JSON, XML ou CSV. XML e CSV são sempre tratados como estrutura plana.
- **Row Selector**: caminho JSON/XML até o array de linhas (ex.: `items`). Se a resposta é **um único objeto** (busca por PK), deixe o Row Selector vazio e ligue **Contains Single Row**.
- **Colunas**: nome, tipo de dado, **Selector** (atributo na resposta, sensível a maiúsculas), **Format Mask** para datas, **Primary Key**, Visible, Additional Info (anotações).
- **Array Columns** (JSON): representam arrays aninhados; colunas filhas apontam para a coluna array como *Parent Column*. Referências cíclicas são proibidas. Numa região baseada na fonte, o Page Designer deixa escolher **uma** coluna array; ficam disponíveis os filhos diretos dela e as colunas pai.
- **Use Raw Selectors** (em Duality/JSON Sources): usa os selectors exatamente como escritos, sem sanitização.
- **Rediscover Data Profile** traz atributos novos (por exemplo, campos customizados num sandbox Fusion).

Pegadinhas:
- Marque o **Primary Key** na coluna certa do Data Profile: forms, grids e todas as operações de DML dependem disso, e as regiões herdam a marcação.
- Ajuste tipos errados após o discovery. Exemplo: data ISO 8601 sem fração nem fuso → tipo `DATE`, máscara `YYYY-MM-DD"T"HH24:MI:SS"Z"`; se a API não manda o `Z`, use `YYYY-MM-DD"T"HH24:MI:SS`.

Em tempo de execução, o APEX monta um `SELECT ... FROM JSON_TABLE(response_payload, '$."items"[*]' COLUMNS (... PATH '$."empno"'))`, extraindo cada coluna como `VARCHAR2(4000)` e convertendo para o tipo declarado (com `TO_NUMBER`, `TO_DATE` com a máscara etc.).

Fonte: [Understanding Data Profiles](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-rest-data-sources.html), [Data Profile Helps Turn JSON Into Rows](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/data-profiles-helps-turn-json-rows.html), [Understanding the JSON_TABLE Query](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-json_table-query.html), [Updating a REST Source Row in Code](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/updating-rest-source-row-code.html)

### Data Profile: colunas calculadas (SQL Expression, SQL Query, Lookup)

No editor do Data Profile, *Add Column* com Column Type **SQL Expression**, **SQL Query (return single value)** ou **Lookup** cria uma coluna derivada, somente leitura, que pode referenciar outras colunas do profile pelo nome. Ela fica disponível em todo lugar onde a REST Data Source é usada (regiões, LOVs, código).

```sql
-- coluna FULL_NAME (SQL Expression)
FIRST_NAME || ' ' || LAST_NAME
-- coluna DISPLAY_FILESIZE
apex_string_util.to_display_filesize( FILE_SIZE )
-- coluna URL que serve o arquivo por uma página da app
apex_page.get_url(p_page => 9003, p_x01 => NAME, p_absolute_url => true, p_plain_url => true)
```

Fonte: [Adding Computed Data Profile Columns](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/adding-computed-data-profile-columns.html), [Enhancing REST Data with SQL Expressions](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/enhancing-rest-data-sql-expressions.html)

### Data Profile: anotações em Additional Info (SaaS e BOSS)

O campo **Additional Information** de cada coluna aceita uma lista separada por vírgulas de tags (sensíveis a maiúsculas) que ajustam a comunicação:

| Tag | Efeito |
|---|---|
| `RemotePK` | Omite PK remota nula no payload de criação (o serviço gera o valor) |
| `CreateOnly` | Exclui a coluna do payload de update |
| `ReadOnly` | Exclui a coluna de todos os payloads de DML |
| `HasDefault` | Omite a coluna nula no create, para valer o default do servidor |
| `Required` | Informativo (ainda não aplicado) |
| `ETag` (BOSS) | Marca a coluna de versão da linha |
| `Subtype` (BOSS) | Exclui o campo da lista `$fields` e dos payloads se nulo |
| `Sortable` (BOSS) | A coluna pode ser ordenada no servidor |
| `AccessorFK` (BOSS) | FK de acesso para atribuir um objeto de referência |

O wizard infere quase todas; `HasDefault` e `Subtype` precisam ser incluídas à mão.

Fonte: [Data Profile Column Annotations](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/data-profile-column-annotations.html), [About the BOSS REST Data Source Definition](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-the-boss-rest-data-source-definition.html)

### REST Data Source Simple HTTP: tipos de paginação

| Pagination Type | Como pede a próxima página | Exemplo de URL |
|---|---|---|
| No Pagination | Tudo numa resposta (também para respostas de um só objeto) | — |
| Page Size and Fetch Offset | Tamanho da página + "começar na linha" | `...?limit=100&offset=100` |
| Page Size and Page Number | Tamanho + número da página | `...?size=100&page=2` |
| Page Number | Só número; tamanho fixo definido pela API | `...?page=2` |
| Page Size and Page Token | Tamanho + token devolvido no corpo da resposta anterior | `...?token=ApEx=&limit=100` |

Os nomes dos parâmetros (`limit`, `offset`, `page`…) são livres e dependem da API; a tela muda conforme o tipo escolhido e pede, por exemplo, o atributo que indica se há mais linhas (`hasMore` no ORDS). Uma vez configurada, regiões com paginação (Interactive Report etc.) usam a estratégia automaticamente; no debug (nível Info) aparecem linhas como `making GET request to https://.../emp/?offset=5&limit=5`.

A operação tem ainda **Fixed Page Size** (tamanho da janela de paginação do serviço).

Fonte: [Creating a REST Data Source](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-a-REST-data-source.html), [Retrieving Remote Data Page by Page](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/retrieving-remote-data-page-page.html)

### Operations e Database Actions (GET, POST, PUT, PATCH, DELETE)

Cada **Operation** = **URL Pattern** (fim da URL) + **HTTP Method** (GET, POST, PUT, PATCH, DELETE); a combinação identifica a operação. A **Database Operation** (Database Action) liga a operação ao que o componente precisa: *Fetch rows* (Fetch Multiple Rows), *Fetch single row*, *Insert row*, *Update row*, *Delete row*. **Cada Database Action só pode ser atribuída a uma operação** da REST Data Source.

- Uma fonte Simple HTTP descoberta começa só com `GET` = Fetch rows: já serve para qualquer região e LOV **somente leitura**.
- Para Form e Interactive Grid editáveis são necessárias também Fetch single row, Insert, Update e Delete. O processo de DML automático usa **Fetch single row** para a proteção contra lost update.
- Em Simple HTTP, o URL Pattern pode referenciar o **Selector da coluna PK** como parâmetro implícito: `:empno` ou `{empno}` (nome do selector, sensível a maiúsculas). Cuidado: **não defina um parâmetro URL Pattern com o mesmo nome**, porque ele substitui o implícito.
- Confira que o item de PK do form tem o switch **Primary Key** ligado.

Atributos da operação: Name, Static ID (para `EXECUTE_REST_SOURCE`), URL Pattern, HTTP Method, Database Operation, Request Body Template, *Supports Template Directives*, **Caching** e **Invalidate When**, Operation Parameters, Fixed Page Size, Comment.

Fonte: [REST Operations and Database Actions](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/rest-operations-and-database-actions.html), [How REST Data Sources Differ from Legacy Web Service References](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-rest-data-sources.html), [Editing a REST Data Source](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-or-deleting-a-REST-data-source.html)

### Request Body Template: substituições #COL#, !NULL e !RAW

Operações de Insert e Update enviam o corpo definido em **Request Body Template**, uma mistura de JSON com substituições `#NOME#`:

- Em operações usadas por Form/IG (Database Action), as colunas da fonte já estão disponíveis e **não se coloca aspas** em volta da substituição: o APEX insere o valor já escapado e com aspas quando necessário.
- `#COMM!NULL#` envia a palavra JSON `null` em vez de `""` quando o valor é nulo.
- `#PAYLOAD!RAW#` insere o valor **sem** o escape JSON. Padrão para corpo 100% dinâmico: um parâmetro Request Body chamado `PAYLOAD` e o template inteiro igual a `#PAYLOAD!RAW#`; o valor é atribuído por expressão PL/SQL onde a fonte é usada.
- Em operações chamadas por **Invoke API** ou `EXECUTE_REST_SOURCE`, cada valor do payload é um parâmetro Request Body explícito e **as aspas não são automáticas**: escreva `"#P_ISBN#"` para strings.

```json
{
    "job"     :"#P_JOB#"
   ,"sal"     : #P_SAL!NULL#
   ,"ename"   :"#P_ENAME#"
   ,"hiredate": #P_HIREDATE!RAW#
}
```

Muitas APIs exigem o header `Content-Type: application/json`: crie um parâmetro HTTP Header estático.

Fonte: [Configuring a Request Body Template](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configuring-request-body-template.html), [Invoking a REST Operation Declaratively](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/invoking-rest-operation-declaratively.html), [Configuring REST Source for Invocation](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configuring-rest-source-invocation.html)

### Parâmetros da REST Data Source (URL Pattern, Query String, Header, Body, Data Profile Column)

Parâmetros podem ser definidos na fonte (todas as operações) ou na operação. Cada um tem valor default, *Required* e *Static*; os não estáticos aparecem sob o nó **Parameters** da região/LOV no Page Designer, onde recebem valor de item, expressão etc.

| Tipo | Direção | Uso |
|---|---|---|
| URL Pattern | IN | `:Nome` ou `{Nome}` no URL Pattern |
| URL Query String | IN | Vira `Nome=Valor` na query string |
| HTTP Header | IN, OUT, IN/OUT | Envia e/ou devolve um header |
| Request/Response Body | IN, IN/OUT | `#Nome#`, `#Nome!NULL#`, `#Nome!RAW#` no template |
| Request/Response Body | OUT, IN/OUT | Devolve o corpo inteiro da resposta |
| Data Profile Column | OUT | Devolve uma coluna de uma resposta de 1 linha |

Regra de segurança: **não** use parâmetro para token, API key ou senha. Defina uma **Web Credential** do tipo adequado e associe à fonte, para o segredo ser guardado criptografado e ocultado no debug.

Fonte: [Supply and Return Values with Parameters](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/supply-and-return-values-parameters.html)

### Filter parameters para QBE e cascata (attrName_operator$behavior)

Nas fontes Oracle Cloud Applications (SaaS e BOSS), parâmetros URL Pattern na operação GET de *Fetch rows* com nome no formato `attrName_operator$behavior` viram filtros declarativos:

- **attrName**: atributo remoto (sensível a maiúsculas).
- **operator**: `eq` (igual), `contains` (contém, sem caso), `startswith` (começa com, sem caso).
- **behavior** quando o valor é nulo: `ignoreifnull` (ignora o filtro), `norowsifnull` (nenhuma linha), `matchifnull` (casa com nulo).

Exemplos: `componentId_eq$norowsifnull` numa LOV de Select List em cascata (item pai em *Parent Item*); `firstName_contains$ignoreifnull` e `lastName_contains$ignoreifnull` numa página de busca por exemplo, com os itens listados em *Page Items to Submit* da região.

Fonte: [Filter Parameters for Query By Example and Parent and Child Use Cases (SaaS)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/filter-parameters-for-query-by-example-and-parent-and-child-use-cases.html), [Filter Parameters (BOSS)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/filter-parameters-for-query-by-example.html)

### Cache de respostas GET (Caching, Invalidate When, PURGE_REST_SOURCE_CACHE)

O cache é **no servidor** (não depende do browser) e vale **só para GET**. Opções: compartilhado por todos os usuários, por usuário ou por sessão. **Invalidate When**: minutos ou uma expressão de calendário do `DBMS_SCHEDULER` (ex.: no início de cada hora, à meia-noite). Valor `0` = cache só durante a execução da página atual, útil quando várias regiões da mesma página usam a mesma fonte. As respostas JSON ficam como CLOB numa tabela de cache, mas ainda precisam ser parseadas a cada uso.

Se a app altera dados remotos que estão em cache, invalide-o no mesmo processamento:

```sql
apex_exec.purge_rest_source_cache(
    p_static_id            => 'USGS',
    p_current_session_only => false);
```

Fonte: [Caching a GET Operation's Response](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/caching-get-operations-response.html), [Editing a REST Data Source](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-or-deleting-a-REST-data-source.html), [PURGE_REST_SOURCE_CACHE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.PURGE_REST_SOURCE_CACHE-procedure.html)

### REST Source Synchronization: sincronizar uma REST API com tabela local

A **Data Synchronization** mantém uma tabela local em sincronia com uma REST Data Source, manualmente ou por agendamento (job do Scheduler: o schema de parse precisa do privilégio **`CREATE JOB`**).

Quando usar: relatórios sobre grandes volumes paginados (evita muitas requisições e permite índices), dados consumidos por PL/SQL, APIs que só guardam um período recente (acumular histórico com *Merge*) e um "cache inteligente" melhor que o cache de resposta, porque o JSON não precisa mais ser parseado.

Configuração (REST Data Source › **Manage Synchronization**):
- **Local Table Owner** (padrão: schema de parse) e **Synchronize to**: *New Table* (o APEX cria a tabela a partir das colunas visíveis do Data Profile; clique *Create Table*) ou *Existing Table*. Opção **Nested Rows**.
- **Synchronization Type**: *Append* (típico sem PK), *Merge* (exige PK no Data Profile: atualiza se existe, insere se não), *Replace* (esvazia antes de carregar).
- **Synchronization Schedule**: sintaxe de calendário do `DBMS_SCHEDULER` (ex.: toda terça e sexta às 16h), digitada ou pelo *Interval Builder* (ícone de chave inglesa).
- **Steps**: sem steps, a fonte é chamada uma vez com os parâmetros default; com steps, é chamada uma vez por step, com os parâmetros/filtros externos configurados.
- **Advanced**: *Commit Interval* (sem valor = uma transação só), **HTTP Request Limit** por step (se exceder, para e registra *Incomplete*; na prática para **uma requisição depois** do limite: limite 10 → para após a 11ª) e *Enable Simple Rate Limiting* (limita requisições por intervalo, sem olhar headers de rate limit da API).
- *Save and Run* executa na hora.

A tabela é um objeto comum do schema: pode ganhar índices, colunas extras etc. Se divergir do Data Profile, a sincronização segue para as colunas presentes nos dois, e o APEX gera o DDL para realinhar (que pode virar Supporting Object).

Para usar a tabela local: em LOVs ligue **Use Synchronization Table?**; em regiões ligue **Use Local Table** na seção REST Synchronization. *Clear Settings* desfaz a sincronização e volta os componentes para a REST API; *Synchronize Usage* lista quem usa a tabela local. O **log** (status, linhas, número de requisições, drill-down até o Web Services log) tem *Purge Log*.

Fonte: [Managing Data Synchronization](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-data-synchronization.html), [Synchronizing Data Locally](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/synchronizing-data-locally.html)

### REST Source Synchronization em PL/SQL e após importar a app (APEX_REST_SOURCE_SYNC)

**Depois de importar uma app, as sincronizações ficam desabilitadas** (para não haver várias instâncias rodando ao reimportar versões). Reative em Shared Components › REST Data Sources › Manage Synchronizations ou, num ambiente Runtime Only, por PL/SQL. As chamadas exigem contexto de sessão APEX:

```sql
declare
    l_app_id number := 100;
begin
    apex_session.create_session(
        p_app_id   => l_app_id,
        p_page_id  => 1,
        p_username => 'ADMIN');
    -- reativar e iniciar o agendamento
    apex_rest_source_sync.enable(
        p_application_id   => l_app_id,
        p_module_static_id => 'rest_movie');
    -- ou definir a próxima execução
    apex_rest_source_sync.reschedule(
        p_application_id   => l_app_id,
        p_module_static_id => 'rest_movie',
        p_next_run_at      => trunc(sysdate + 1));
    -- executar agora (em background = job único do DBMS_SCHEDULER)
    apex_rest_source_sync.synchronize_data(
        p_module_static_id  => 'rest_movie',
        p_run_in_background => true);
end;
```

Observação: o exemplo 18-2 da doc tem um erro de sintaxe (`p_next_run_at` depois do `);`); o bloco acima mostra a forma correta da chamada. O pacote tem também `DISABLE`, `IS_RUNNING`, `DYNAMIC_SYNCHRONIZE_DATA` e `SYNCHRONIZE_TABLE_DEFINITION` (ver doc 07).

Fonte: [About Importing and Exporting REST Source Synchronizations](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-data-synchronization.html), [SYNCHRONIZE_DATA Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SYNCHRONIZE_DATA-Procedure.html), [ENABLE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_REST_SOURCE_SYNC-ENABLE-Procedure.html)

### Usar REST Data Source em regiões e LOVs (Location = REST Source)

Em qualquer região ou LOV: **Source › Location = REST Source** e escolha a fonte. As colunas do Data Profile aparecem como colunas da região. Recursos adicionais por região:

- **Parameters**: nó na árvore de renderização para atribuir valores aos parâmetros (inclusive URL Pattern de recursos aninhados, ex.: `/orders/:orderId/orderLines`).
- **External Filter and Order By** (switch): cláusulas enviadas 1:1 ao backend, na sintaxe de cada tipo. Exemplos Fusion: filtro `StatusCode = 'OPEN' and WinProb >= 75`; ordenação `WinProb:desc,PrimaryContactPartyName:asc`. Para ORDS e OData, consulte a sintaxe do próprio serviço.
- **Local Post-Processing** (ver abaixo).
- **Use Local Table** (se houver sincronização).
- Para reduzir tráfego em fontes com centenas de atributos: apague colunas do Data Profile, marque como não Visible, ou deixe na região só as colunas necessárias (Commented Out, Server-side Condition = Never ou excluir). *Synchronize Columns* (menu de contexto da região) traz colunas novas mantendo as comentadas.

Fonte: [Using REST APIs as Data Sources](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-rest-apis-data-sources.html), [Configuring Default Filtering and Sorting](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configuring-default-filtering-and-sorting.html), [Working with Parent and Child Data in Regions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/working-with-parent-and-child-data-in-regions.html), [REST Data Source Definitions for Oracle Cloud SaaS Apps](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/rest-data-source-definitions-for-oracle-cloud-saas-apps.html)

### Local Post-Processing: filtrar, ordenar, juntar e agregar dados remotos com SQL (#APEX$SOURCE_DATA#)

Quando a API não filtra nem ordena, a região/LOV pode processar localmente **depois** de receber o JSON:

- **Where/Order By Clause**: `WHERE` e `ORDER BY` são acrescentados à query externa do `JSON_TABLE`, então só podem usar colunas **presentes no SELECT** da região (inclua a coluna e deixe-a oculta, se preciso).
- **SQL Query**: o APEX troca `#APEX$SOURCE_DATA#` pela query `JSON_TABLE` inteira; você escreve qualquer SELECT válido que referencie esse placeholder, com joins a tabelas locais, agregações, colunas novas. Para SQL dinâmico, use *PL/SQL Function Body Returning SQL Query*.

```sql
select r.empno, r.ename, c.name as course_name, t.status
  from #APEX$SOURCE_DATA# r
  join emp_training t on r.empno = t.empno
  join emp_course   c on t.course_id = c.id
 where t.status in ('COMPLETED','CERTIFIED')
```

Lembre: em Simple HTTP, **todas as linhas** já são buscadas antes desse filtro local. Para volumes grandes, prefira sincronização.

Fonte: [Locally Filtering and Sorting Remote Data](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/locally-filtering-and-sorting-remote-data.html), [Using Custom SQL Involving Remote Data](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-custom-sql-involving-remote-data.html), [Example: Creating a REST Data Source on Top of a SQL Query](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-example-rest-data-source-on-sql-query.html)

### Invoke API: chamar uma operação REST sem código

Processo de página (ou atividade de workflow) **Invoke API** com **API Type = REST Source**, escolhendo a REST Data Source e a operação. Sob o processo aparece o nó **Parameters**: cada parâmetro recebe valor de item (ex.: `P_SAL` ← `P57_SAL`), expressão PL/SQL, etc., e parâmetros OUT podem ser gravados em itens. Uma REST Data Source usada só para Invoke API pode ter **zero colunas** no Data Profile se você não precisa ler a resposta.

Helper sugerido pela doc para datas ISO em payloads (devolve `null` sem aspas ou a data entre aspas):

```sql
create or replace function json_date(p_item in varchar2) return varchar2 is
    l_value varchar2(255) := apex_session_state.get_timestamp(p_item);
begin
    return case when l_value is null then 'null'
                else apex_string.format('"%s"',
                       to_char(apex_session_state.get_timestamp(p_item),
                               apex_json.c_date_iso8601))
           end;
end;
-- no template: "hiredate": #P_HIREDATE!RAW#
```

Fonte: [Invoking a REST Operation Declaratively](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/invoking-rest-operation-declaratively.html)

### REST Data Source em PL/SQL: consultar linhas (APEX_EXEC.OPEN_REST_SOURCE_QUERY)

`OPEN_REST_SOURCE_QUERY` executa a operação de *Fetch rows* e devolve um contexto que funciona como cursor. Sempre feche o contexto, inclusive no `exception`.

```sql
declare
    l_cols apex_exec.t_columns;
    l_prm  apex_exec.t_parameters;
    l_ctx  apex_exec.t_context;
begin
    apex_exec.add_column(p_columns => l_cols, p_column_name => 'EMPNO');
    apex_exec.add_column(p_columns => l_cols, p_column_name => 'ENAME');
    apex_exec.add_parameter(p_parameters => l_prm, p_name => 'MY_PARAM', p_value => 1234);
    l_ctx := apex_exec.open_rest_source_query(
                 p_static_id  => 'employees_simple_http',
                 p_columns    => l_cols,
                 p_parameters => l_prm,
                 p_max_rows   => 100);
    while apex_exec.next_row(l_ctx) loop
        dbms_output.put_line(apex_exec.get_number(l_ctx,'EMPNO')||' '||
                             apex_exec.get_varchar2(l_ctx,'ENAME'));
    end loop;
    apex_exec.close(l_ctx);
exception
    when others then
        apex_exec.close(l_ctx);
        raise;
end;
```

Parâmetros opcionais: `p_filters` (`t_filters`), `p_order_bys`, `p_aggregation`, `p_control_break`, `p_external_filter_expr` e `p_external_order_by_expr` (repassados 1:1 ao serviço), `p_first_row`/`p_max_rows`, `p_total_row_count`, `p_array_column_name`. Em Simple HTTP, filtros e ordenações são aplicados **localmente após buscar tudo**; em SaaS, BOSS, ORDS e OData vão para o servidor. Para arrays aninhados use `apex_exec.open_array(ctx,'COL')` / `next_array_row` / `close_array`, declarando colunas filhas com `p_parent_column_path => '"PAI"'` em `add_column`.

Fonte: [Querying REST Source Rows in Code](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/querying-rest-source-rows-code.html), [OPEN_REST_SOURCE_QUERY Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.OPEN_REST_SOURCE_QUERY-Function.html), [Reading Business Objects with Nested Collections](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/reading-business-objects-with-nested-collections.html)

### REST Data Source em PL/SQL: inserir, atualizar e excluir (OPEN_REST_SOURCE_DML_CONTEXT)

Sequência: declarar colunas com `ADD_COLUMN` (sempre com `p_data_type` e **pelo menos uma** com `p_is_primary_key => true`) → `OPEN_REST_SOURCE_DML_CONTEXT` → para cada linha `ADD_DML_ROW` (constante `apex_exec.c_dml_operation_insert|update|delete`) e `SET_VALUE` → `EXECUTE_DML` → `CLOSE`.

```sql
declare
    l_cols apex_exec.t_columns;
    l_dml  apex_exec.t_context;
begin
    apex_exec.add_column(p_columns => l_cols, p_column_name => 'EMPNO',
        p_data_type => apex_exec.c_data_type_number, p_is_primary_key => true);
    apex_exec.add_column(p_columns => l_cols, p_column_name => 'ENAME',
        p_data_type => apex_exec.c_data_type_varchar2);
    l_dml := apex_exec.open_rest_source_dml_context(
                 p_static_id => 'employees_simple_http',
                 p_columns   => l_cols);
    apex_exec.add_dml_row(l_dml, apex_exec.c_dml_operation_insert);
    apex_exec.set_value(l_dml, 'EMPNO', 1234);
    apex_exec.set_value(l_dml, 'ENAME', 'LUCY');
    apex_exec.execute_dml(l_dml);
    apex_exec.close(l_dml);
exception
    when others then
        apex_exec.close(l_dml);
        raise;
end;
```

**Update com proteção contra lost update**: busque antes a linha atual com um contexto de query, abra o DML com `p_lost_update_detection => apex_exec.c_lost_update_implicit`, faça `ADD_DML_ROW(update)`, `SET_ROW_VERSION_CHECKSUM(p_context => l_dml, p_checksum => apex_exec.get_row_version_checksum(l_qry))`, copie os valores com `SET_VALUES(p_context => l_dml, p_source_context => l_qry)` e só então altere as colunas. Para busca por PK numa Simple HTTP, a doc usa uma segunda REST Data Source com Data Profile de **linha única** (sem Row Selector, *Contains Single Row*). Delete só precisa da coluna PK. Em BOSS, use `c_lost_update_none` em inserts e marque a coluna ETag com `p_is_checksum => true`.

Fonte: [Modifying REST Source Rows in Code](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/modifying-rest-source-rows-code.html), [Inserting a REST Source Row in Code](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/inserting-rest-source-row-code.html), [Updating a REST Source Row in Code](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/updating-rest-source-row-code.html), [Deleting a REST Source Row in Code](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/deleting-rest-source-row-code.html)

### REST Data Source em PL/SQL: chamar uma operação como função (APEX_EXEC.EXECUTE_REST_SOURCE)

Para APIs "de ação" (ex.: um POST que cria um pedido e devolve número e data), trate a operação como chamada de função:

```sql
declare
    l_prm apex_exec.t_parameters;
begin
    apex_exec.add_parameter(p_parameters => l_prm, p_name => 'P_ISBN',     p_value => '978-1565926912');
    apex_exec.add_parameter(p_parameters => l_prm, p_name => 'P_QUANTITY', p_value => 1);
    apex_exec.execute_rest_source(
        p_static_id           => 'single_book_order',
        p_operation_static_id => 'single_book_create',
        p_parameters          => l_prm);
    :P55_PEDIDO := apex_exec.get_parameter_varchar2(l_prm, 'ORDER_NUMBER');
end;
```

- Há uma assinatura que identifica a operação pelo nome/método (`p_operation => 'POST'`) e, se houver várias com o mesmo nome, pelo `p_url_pattern`.
- Parâmetros OUT: tipo *Data Profile Column* (valor de uma resposta de 1 linha) ou *Response Body* (corpo inteiro, leia com `GET_PARAMETER_CLOB`).
- Converta valores para `VARCHAR2` antes de `ADD_PARAMETER`: headers, URL Patterns e afins são strings.

Fonte: [Invoking REST Operation in Code](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/invoking-rest-operation-code.html), [EXECUTE_REST_SOURCE Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.EXECUTE_REST_SOURCE-Procedure-Signature-1.html)

### Chamar REST sem REST Data Source (APEX_WEB_SERVICE.MAKE_REST_REQUEST e _B)

`APEX_WEB_SERVICE` dá controle total, mas exige codificar o que a REST Data Source faz declarativamente (parse, paginação, erros). É **obrigatório** para payload ou resposta binária, porque operações de REST Data Source **não suportam corpo binário** em nenhuma direção:

- enviar binário: `p_body_blob` (em vez de `p_body`);
- receber binário: `MAKE_REST_REQUEST_B` (retorna BLOB) em vez de `MAKE_REST_REQUEST` (CLOB).

```sql
declare
    l_resp clob;
    l_json json_object_t;
begin
    apex_web_service.set_request_headers(
        p_name_01 => 'Content-Type', p_value_01 => 'application/json',
        p_reset   => true);
    l_resp := apex_web_service.make_rest_request(
                  p_url                  => 'https://api.example.com/orders',
                  p_http_method          => 'POST',
                  p_body                 => '{"isbn":"978-1565926912","quantity":1}',
                  p_credential_static_id => 'API_EXEMPLO');   -- Web Credential
    if apex_web_service.g_status_code in (200, 201)
       and dbms_lob.getlength(l_resp) > 0 then
        l_json := json_object_t(l_resp);
        :P55_PEDIDO := l_json.get_number('orderNumber');
    else
        raise_application_error(-20001, 'HTTP '||apex_web_service.g_status_code);
    end if;
end;
```

Parâmetros úteis: `p_transfer_timeout` (default 180 s), `p_parm_name`/`p_parm_value` (pares nome/valor), `p_wallet_path`/`p_wallet_pwd`, `p_https_host`, `p_token_url` e `p_oauth_scope` (OAuth2), `p_proxy_override`. Globais após cada chamada: `g_status_code`, `g_reason_phrase`, `g_headers` (headers da resposta), `g_request_headers`, `g_request_cookies`, `g_response_cookies`. Para ler um header de resposta, a doc usa `apex_web_service.get_request_header('Content-Type')` após `MAKE_REST_REQUEST_B`.

Fonte: [Calling REST APIs Without a Data Source](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/calling-rest-apis-data-source.html), [MAKE_REST_REQUEST Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/MAKE_REST_REQUEST-Function.html), [MAKE_REST_REQUEST_B Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/MAKE_REST_REQUEST_B-Function.html), [Global Variables (APEX_WEB_SERVICE)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_WEB_SERVICE.Global-Variables.html), [Serving Inline File from Object Bucket](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/serving-inline-file-object-bucket.html)

### Ler metadados da REST Data Source em código (APEX_APPL_WEB_SRC_*)

Para não fixar URL e credencial no código, a doc consulta as views de metadados:

```sql
select replace(m.url_endpoint || o.url_pattern, ':filename', :nome_arquivo) as url,
       m.credential_static_id
  from apex_appl_web_src_operations o
  join apex_appl_web_src_modules    m on o.module_id = m.module_id
 where o.operation_static_id = 'get_file'
   and m.module_static_id    = 'bucket_objects'
   and o.application_id      = sys_context('APEX$SESSION','APP_ID');
```

Fonte: [Serving Inline File from Object Bucket](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/serving-inline-file-object-bucket.html)

### REST Source Catalogs: catálogo reutilizável de REST Data Sources

Um **REST Source Catalog** (Workspace Utilities › REST Source Catalogs) guarda metadados de REST Data Sources para qualquer app do workspace criar fontes a partir dele. Catálogos ficam em **grupos** (crie o grupo primeiro em *Manage Catalog Groups*).

- **Create Catalog** e depois, em cada REST Data Source, *Save to Catalog*. Nome do catálogo é único no workspace; o **Internal Name** identifica o catálogo entre instâncias: importar um catálogo com o mesmo Internal Name **sobrescreve** o existente.
- **Create from OpenAPI**: sobe um arquivo OpenAPI (ou URL) e gera um template de REST Source por API, com *Default REST Source Type*, *Default Authentication* (No Authentication, Basic, OAuth2 Client Credentials, OCI, Certificate/Private Key Pair, HTTP Header, URL Query String: cria uma credencial vazia ao instanciar), *Default Token Server URL*, **Catalog Refresh URL** (com proxy e Web Credential opcionais).
- No catálogo só se editam nome e descrição dos serviços; o resto se edita na REST Data Source original.
- Exportar/importar: exporte o catálogo, importe na outra instância e instale (na hora ou pelo Export Repository). A Oracle publica um catálogo das APIs Fusion em `github.com/oracle/apex/tree/rest-source-catalogs/fusion`.

Fonte: [Managing REST Source Catalogs](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-REST-source-catalogs.html), [Extra Fusion Apps, ORDS, OData Features](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/extra-fusion-apps-ords-odata-features.html)

### REST Source Plug-in: novo tipo de REST Data Source

Para APIs com convenções que o APEX não conhece, um plug-in do tipo REST Data Source cria um novo tipo no wizard. Contratos PL/SQL:

| Procedure | Função |
|---|---|
| Capabilities | Diz se há filtro, ordenação e paginação no servidor |
| Discover | Deduz operações, parâmetros e colunas a partir de metadados próprios |
| Fetch | Busca dados (com ou sem filtro/ordenação/paginação no servidor) |
| DML | Grava as linhas de DML vindas de form, grid ou `APEX_EXEC` |
| Execute | Atende Invoke API e `EXECUTE_REST_SOURCE` |

Há um exemplo funcional no GitHub da Oracle APEX, em `plugins/rest-source` da versão correspondente (implementa Capabilities, Discover e Fetch).

Fonte: [Creating a Custom REST Source Plug-in](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/creating-custom-rest-source-plug.html)

### Oracle Cloud Applications (SaaS): definição, recursos de runtime e sandbox

Criar: tipo *Oracle Cloud Applications (SaaS) REST Service*, aceitar o Remote Server proposto e a paginação default. A fonte criada tem todas as operações suportadas (GET com filtro/ordem/paginação, GET por chave, POST, PATCH, DELETE), coluna PK **`APEX$RESOURCEKEY`** mapeada à resource key e **Root Resource Name** (inferido; obrigatório em recursos filhos como `.../employees/:empid/child/VacationRequests`, cujo root é `employees`).

- O wizard cria colunas para todos os atributos, mas deixa no máximo **150 visíveis**, priorizando campos customizados (`_c`). Centenas de atributos numa região podem gerar exceção (o limite depende do tamanho dos nomes).
- **Runtime**: paginação; **Use Total Results?** (para "1-20 de 200"); **Use Pagination?** = No se o endpoint não pagina; filtro e ordenação delegados; External Filter com `upper(lastName) = &P3_NAME.`; **lost update em lote** (todas as linhas numa ida); **Batch DML** (tudo ou nada; desligue *Use Batch DML?* se a API se comportar mal); erros de validação viram erros APEX, separados por `<br>`.
- **External filters não aceitam bind variables**, só substituições `&ITEM.`, sempre do lado direito; o valor é colocado entre aspas simples automaticamente (números também, o servidor aceita).
- **Sandbox**: defina o nome em Shared Components › Component Settings › Oracle Cloud Applications (SaaS) REST Service; o App Builder passa a usar os business objects do sandbox. Depois de publicar, limpe o nome. Para uma fonte específica, sobrescreva com parâmetro Header `Metadata-Context` = `sandbox="OutroSandbox"` (ou vazio para não usar sandbox).
- Versão do REST framework: o APEX usa a **6** por padrão; para outra, parâmetro Header `REST-Framework-Version` = `7`.

Fonte: [REST Data Source Definitions for Oracle Cloud SaaS Apps](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/rest-data-source-definitions-for-oracle-cloud-saas-apps.html), [REST Data Source Runtime Features for Oracle Cloud SaaS Apps](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/rest-data-source-runtime-features-for-oracle-cloud-saas-apps.html), [Working Against a Sandbox](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/working-against-a-sandbox.html), [Overriding Default Runtime Headers If Necessary](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/overriding-default-runtime-headers-if-necessary.html)

### Oracle Cloud Applications (BOSS): ETag, lost update, Bulk DML, filtros e coleções aninhadas

- **Criação**: settings **Discover References** (inclui atributos read-only do primeiro nível de objetos referenciados e FKs de acesso), **Use Bulk DML**, **Use Total Results**, **Use Pagination** (No se o endpoint não aceita `$offset`).
- **Data Profile**: PK `APEX$RESOURCEKEY` (para Business Object/View e Search View) e **`APEX$ETAG`** (selector `$context.etag`, anotação `ETag`).
- **ETag obrigatório** se o business object tiver atributo `historyType='versionNumber'`: inclua `APEX$ETAG` nas colunas de forms, grids e `APEX_EXEC` (marcado com `p_is_checksum => true`). Em forms/grids configure **Lost Update Type = Row Version Column** com `APEX$ETAG`, ou desligue a proteção do APEX e deixe o BOSS cuidar. Sem esse atributo, o ETag é sempre nulo e a coluna pode ser excluída.
- **Lost update**: o APEX busca cada linha alterada/excluída pela resource key; com ETag a verificação é mais eficiente.
- **Bulk DML**: todas as linhas numa ida. Só funciona em business objects de nível superior: em recursos filhos aninhados, **Use Bulk DML = No**. Para gravar pai + filhos num payload (`APEX_EXEC.ADD_DML_ARRAY_ROW`), a fonte de topo precisa de Use Bulk DML = Yes.
- **Filtros**: busca de linha vira `like` sem caso (Business Object/View, Extraction View) ou keyword search (Search View). External Filter tipo SQL com `and/or`, parênteses e operadores `~=`/`~like` (sem caso), ex.: `lastName ~= &P3_NAME.`. Um parâmetro URL Pattern chamado **`additionalExternalFilter`** permite filtro dinâmico; precisa ter parênteses balanceados, senão dá `invalid filter`.
- **Ordenação**: External Order Bys `departmentNumber:asc,dateHired:desc`. Ordenar por atributo não *sortable* gera erro da API: use Local Post-Processing.
- **Custom actions** de business object: use uma fonte Simple HTTP com parâmetros, template e Data Profile manuais e parâmetros OUT do tipo Data Profile Column.

Fonte: [About the BOSS REST Data Source Definition](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-the-boss-rest-data-source-definition.html), [Lost Update Protection](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/lost-update-protection.html), [ETag Support](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/etag-support.html), [Bulk DML](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/bulk-dmll.html), [Data Filtering](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/data-filtering.html), [Data Ordering](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/data-ordering.html), [Writing Business Objects with Nested Collections](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/writing-business-objects-with-nested-collections.html), [Invoking BOSS Business Object Custom Actions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/invoking-boss-business-object-custom-actions.html)

### Depurar erros de REST API com o debug do APEX

1. Na barra de desenvolvedor: Debug › Current Debug Level › **Info** (a página recarrega gravando traces). Cada requisição seguinte gera uma entrada.
2. Debug › **View Debug**: IR filtrado por app e página, ordenado do mais recente. A coluna **Path Info** ajuda: `show` (renderização), `accept REQUEST/BOTAO` (submit), `ajax`, `ajax plugin` ou `ajax process` (refresh parcial).
3. No detalhe, a timeline marca erros com pontos vermelhos (clique para ir à linha).
4. Procure a linha `making GET request to https://...` antes do erro: ela mostra a URL real, inclusive filtros e ordenações delegados (ex.: `&orderBy=WinProb:desc,...`), e a mensagem do corpo de erro da API (ex.: `fetch_adfbc: HTTP 400 - The attribute AssignmentMode is not sortable`).

Fonte: [Debugging REST API Errors](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/debugging-rest-api-errors.html)

---

## 6. Duality Views e JSON Sources

### Duality View Source (Shared Components): dados JSON-relacionais como fonte de componentes

Requer **Oracle AI Database 26ai** ou superior. Uma *JSON-Relational Duality View* expõe tabelas relacionadas como documentos JSON, de forma legível e (se anotada) gravável. No APEX, uma **Duality View Source** (Shared Components › Data Sources › Duality Views) guarda dono e nome da view e um **Data Profile** gerado a partir do JSON Schema que o banco devolve.

- Create: Name, **Location** (Local Database ou REST Enabled SQL Service), Owner, Duality View; depois marque as colunas de **Primary Key** no Data Profile.
- Edit: Static ID (para PL/SQL), Data Profile (Format, Row Selector, colunas, *Rediscover*, JSON Schema opcional, *Use Raw Selectors*).
- Uso: regiões (relatórios, charts, forms…), LOVs, automations e `APEX_EXEC` (ex.: `OPEN_DUALITY_VIEW_DML_CONTEXT`, `PURGE_DUALITY_VIEW_CACHE`).
- Copy/Subscribe, Utilization e History como nos demais componentes.

Fonte: [Managing Duality Views](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-duality-views.html)

### JSON Source: tabelas com colunas JSON e JSON Collection Tables

Uma **JSON Source** aponta para uma tabela comum com colunas JSON (Oracle 19c/21c em diante) ou para uma **JSON Collection Table** (`CREATE JSON COLLECTION TABLE`, só 26ai+), local ou via REST Enabled SQL.

- **JSON Source Type**: *JSON Collection Table* ou *Table with JSON columns* (até **três** colunas JSON, dos tipos `VARCHAR2`, `CLOB`, `BLOB` ou `JSON`).
- Para cada coluna dá para subir um **JSON Schema**; sem ele, o APEX amostra os dados existentes (útil fornecer o schema quando a tabela está vazia ou pouco representativa). Só é aceito **um** schema autocontido: imports/bundles não são suportados e `$id` é ignorado; o APEX só aproveita nomes, tipos e hierarquia.
- Marque a PK em **cada nível** da hierarquia. Edit permite um **Where Clause** para restringir linhas.
- Uso igual ao da Duality View; em PL/SQL há `OPEN_JSON_SOURCE_DML_CONTEXT` e `PURGE_JSON_SOURCE_CACHE`.

Fonte: [Managing JSON Sources](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-json-sources.html)

### Duality View na prática: definição, consulta, DML e ETAG

```sql
create json relational duality view action_items_dv as
action_items @insert @update @delete
{
  _id: id,
  name: name,
  status: status,
  team: action_item_team_members @insert @update @delete
  {
    team_assignment_id: id,
    role: role,
    staff @unnest { staff_id: id, name: name }
  }
};
```

- As anotações `@insert`, `@update`, `@delete` dizem que DML é permitido em cada tabela; sem anotação (como `staff`), a parte é **somente leitura**. Os relacionamentos vêm das FKs. `@unnest` sobe os atributos para o nível do pai.
- A view tem uma coluna `DATA` do tipo `JSON`: `select data from action_items_dv where json_value(data,'$._id') = 14`.
- Um único `INSERT INTO action_items_dv(data) VALUES (:json)` grava pai e filhos e pode resolver chaves por colunas únicas (ex.: `name` do staff). O documento devolvido tem `_metadata.etag` e `_metadata.asof`.
- **ETAG**: um update com etag antigo falha (`ORA-42699`). Colunas com `@nocheck` ficam fora do cálculo. A pseudo-coluna `RESID` (RAW) é uma alternativa a `_id` em `WHERE` de update/delete.
- Defaults, check constraints, integridade referencial e triggers das tabelas continuam valendo, e as mudanças aparecem imediatamente tanto no JSON quanto nas tabelas.

Fonte: [Defining JSON Relational Duality View](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/defining-json-relational-duality-view.html), [Querying JSON Relational Duality View](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/querying-json-relational-duality-view.html), [Modifying JSON Using a Duality View](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/modifying-json-using-duality-view.html), [Preventing Lost Updates with ETAG](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/preventing-lost-updates-etag.html), [Comparing _id and RESID in Duality View](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/comparing-_id-and-resid-duality-view.html)

---

## 7. Expor APIs com ORDS (RESTful Services)

### RESTful Services: ORDS, onde definir e a deprecação no SQL Workshop 26.1

APIs REST do seu schema são definidas no **ORDS** (Oracle REST Data Services) e guardadas no repositório do ORDS ("ORDS-based REST Services"). As antigas *APEX-based REST Services* (metadados no schema do APEX, antes da 18.1) foram **dessuportadas na 22.1**; o ORDS 21.4.2+ tem scripts de migração.

> **Atenção 26.1**: definir REST APIs pela tela **SQL Workshop › RESTful Services** está **deprecated no APEX 26.1** e será removido numa versão futura. A definição declarativa continua suportada no **SQL Developer Web** (Database Actions), que é o caminho usado pelo Developer's Companion.

Requisitos: ORDS 20.x+ na configuração do APEX e RESTful Services habilitado pelo administrador (workspace ou instância). Para abrir o SQL Developer Web a partir do APEX (menu SQL Workshop › SQL Developer Web): ORDS 23.1.0 em HTTPS e o atributo *Enable SQL Developer Web* ligado pelo administrador da instância (Manage Instance › Feature Configuration › SQL Workshop). Abrir uma nova aba do SQL Developer Web **encerra as outras sessões** dele no mesmo browser. No SQL Developer Web, o REST Designer fica em menu "hambúrguer" › REST.

Fonte: [Enabling Data Exchange with RESTful Services](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/using-restful-services.html), [Accessing SQL Developer Web Directly from APEX](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/accessing-sql-developer-web-from-sql-workshop-menu.html), [Accessing SQL Developer Web REST Designer](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/accessing-sql-developer-web-rest-designer.html)

### Registrar o schema no ORDS e escolher o Schema Alias

Antes de criar serviços, o schema precisa estar **registrado no ORDS** (SQL Workshop › RESTful Services › *Register Schema with ORDS*, ou ao abrir o SQL Developer Web):

- **Enable RESTful Access** (On/Off), **Schema Alias** (forma a URL; sensível a maiúsculas), **Install Sample Service** (módulo `oracle.example.hr`), **Authorization Required for Metadata Access** (exige autorização para ler o catálogo de metadados do ORDS).
- Cuidado: habilitar no ORDS um schema que é o schema default de **mais de um workspace** causa problemas com static files do workspace (a doc recomenda não fazer isso antes do ORDS 18.3).
- O dashboard mostra versão do ORDS, De-Register, Reset Sample Service, Import/Export (com opções *Include Enable Schema* e *Include Privileges* no ORDS 18.3+), módulos, privilégios, roles, objetos habilitados e status publicado/protegido.

Escolha um alias diferente do nome do schema (ex.: schema `WKSP_COMPANION` → alias `cloudcompanion`); as URLs começam com `https://servidor/ords/cloudcompanion/...`.

Fonte: [How to Access RESTful Services](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/accessing-restful-services.html), [Choosing a Schema Alias](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/choosing-schema-alias.html)

### Modelo do ORDS: Resource Module, Resource Template e Resource Handler

| Peça | O que é | Regras |
|---|---|---|
| **Resource Module** | Agrupa serviços relacionados; define o **Base Path** (único no schema). | Atributos: Module Name, Base Path, Is Published, Pagination Size, Origins Allowed (CORS, lista separada por vírgula), Comments. |
| **Resource Template** | Um serviço endereçável, definido por um **URI Template/Pattern** (ex.: `employees/:id`). | Pode ter **no máximo um handler por método**. Atributos: Priority (maior é avaliado primeiro quando dois padrões casam), HTTP Entity Tag. Template sem handler é "funcionalmente incompleto". |
| **Resource Handler** | A lógica de **um** método HTTP (GET, POST, PUT, DELETE). | Source Type, Format, Pagination Size, Source (SQL ou PL/SQL), parâmetros. |

Anatomia da URL: `https://servidor/ords/<schema_alias>/<base_path_do_modulo>/<uri_template>`, ex.: `https://example.com/ords/anyco/hr/employees/7978`. Padrões de URI: *URI Template* (`employees/:id`) ou *Route Pattern* (`/:object/:id?`, onde `?` torna o parâmetro opcional). Bind variables no padrão são passadas implicitamente ao handler.

Mapeamento CRUD: `GET` = SELECT (coleção ou item), `POST` = INSERT, `PUT` = UPDATE (nova versão), `DELETE` = DELETE; `PATCH` (atualização parcial) é menos comum. Um desenho típico: módulo `v1` com `/actionitems` (GET lista/busca, POST cria) e `/actionitems/:id` (GET, PUT, DELETE).

Fonte: [About Oracle RESTful Services in Oracle APEX](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/about-oracle-restful-services-in-apex.html), [Managing RESTful Service Modules](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/managing-restful-service-modules.html), [Managing Resource Templates](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/managing-resource-templates.html), [Identifying URL Templates in a Module](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/identifying-url-templates-module.html), [Providing Complete Set of ORDS Handlers](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/providing-complete-set-ords-handlers.html)

### Source Types de handler: Collection Query, Collection Item, PL/SQL, Media Resource, Feed, CSV

| Source Type (nomes do SQL Developer Web / SQL Workshop) | Resultado |
|---|---|
| **Collection Query** / *Query* (Format JSON) | SQL → JSON com `items`, `count`, `limit`, `offset`, `hasMore` e `links`. Suporta `q` (filtro), `limit` e `offset`. Com Format **CSV**, devolve CSV. |
| **Collection Item** / *Query One Row* | SQL que devolve **uma** linha, sem `items` e sem propriedades de paginação. Só para GET. |
| **PL/SQL** | Bloco anônimo com controle total (status, headers, corpo). |
| **Media Resource** | Query de 1 linha e 2 colunas: MIME type e BLOB. Forma simples de devolver binário. |
| **Feed** | JSON Feed: a 1ª coluna é o identificador único e vira link `caminho/{id}`; as demais resumem o recurso. Defina outro template para a representação completa. |

Aliases de coluna que mudam o JSON: `id as "_id"` define o nome da propriedade; `team as "{}team"` indica que a coluna **já é JSON** (não vira string). No exemplo do SQL Workshop, `empno "$uri"` gera links. Paginação nos exemplos antigos: bind variables `:row_offset` e `:row_count`.

```sql
-- Collection Query em /v0/actionitems
select id as "_id", name, status, team as "{}team"
  from action_items_with_team_jv
 order by name, id          -- sempre ORDER BY: paginação previsível

-- Collection Item em /v0/actionitems/:id
select id as "_id", name, status, team as "{}team"
  from action_items_with_team_jv
 where id = :id

-- Media Resource em /attachments/:id
select mime_type, file_contents from attachments where id = :id
```

Fonte: [Defining a Read-Only Collection Query](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/defining-read-only-collection-query.html), [Configuring a Collection Item Handler](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configuring-collection-item-handler.html), [Reading and Writing Binary Content](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/reading-and-writing-binary-content.html), [How to Create the ORDS Based RESTful Services Module Example](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/how-to-create-restful-service-module-example.html)

### Filtrar e paginar Collection Query (q, limit, offset, hasMore)

- `q` recebe um predicado de filtro JSON do ORDS: `?q={"name":{"$like":"%Party%"}}`.
- `limit` = tamanho da página; `offset` = linhas puladas (default `0`). Pegue a próxima página enquanto `hasMore` for `true`: `?offset=10&limit=10`.
- Combine: `?limit=5&q={"name":{"$like":"Feature:%"}}`.
- Propriedades da resposta: `count` (linhas nesta página), `limit`, `offset`, `hasMore`.

Uma REST Data Source do tipo *Oracle REST Data Services* do lado consumidor usa exatamente esse protocolo (filtro e paginação delegados).

Fonte: [Filtering/Paging Collection Query Endpoints](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/filtering-paging-collection-query-endpoints.html)

### Bind variables do handler (:id, :body, :body_text, :content_type, parâmetros explícitos)

- **Variáveis do URI** (`:id` de `/actionitems/:id`).
- **Implícitas**: `:body` (BLOB) e `:body_text` (CLOB) com o corpo da requisição; `:content_type`.
- **Explícitas** (aba Parameters do handler): nome, bind variable, *source type* (HTTP Header, query string…), *access method* e tipo de dado. Ex.: header `app$debug` → bind `:debug`. Parâmetros explícitos também servem para converter um parâmetro do URI para um tipo específico.

**Regra crítica**: o handler só pode ler **`:body` ou `:body_text`, uma única vez**. A segunda leitura devolve `null`. Copie para uma variável local logo no início.

```sql
-- PUT /v1/actionitems/:id : handler de uma linha, lógica no package
begin
    action_items_api_rest.update_object(:id, :body_text, :debug);
end;

-- POST /attachments : grava upload binário
declare
    l_conteudo blob := :body;          -- lê uma única vez
begin
    meu_pkg.insert_attachment(p_mime_type => :content_type, p_file_contents => l_conteudo);
    commit;
end;
```

Fonte: [Using Handler Bind Variables](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-handler-bind-variables.html), [Keeping PL/SQL Handlers Maintainable](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/keeping-pl-sql-handlers-maintainable.html), [Defining Explicit Handler Parameters](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/defining-explicit-handler-parameters.html), [Managing Resource Handlers](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/managing-resource-handlers.html)

### Handler PL/SQL: status HTTP, MIME type, resposta e erros

Todo handler PL/SQL, no fim, define o MIME type (e outros headers), define o status se não for 200, fecha o header e escreve o corpo com `HTP.P`/`HTP.PRN`. Um helper comum evita repetição:

```sql
procedure commit_and_send_response(p_json in json_element_t default null) is
    l_tem_json boolean := p_json is not null;
begin
    commit;
    owa_util.mime_header('application/json', l_tem_json);
    if l_tem_json then
        htp.p(p_json.stringify);
    else
        owa_util.status_line(204, 'No content', true);
    end if;
end;

procedure handle_error(p_msg in varchar2, p_http in number default 400) is
    l_err json_object_t := json_object_t();
begin
    owa_util.mime_header('application/json', p_msg is null);
    owa_util.status_line(p_http, 'Error', true);
    if p_msg is not null then
        l_err.put('$error', regexp_replace(p_msg, '^ORA-[0-9]+:\s'));
        htp.p(l_err.stringify);
    end if;
    rollback;
end;
```

Erro de regra de negócio → HTTP **400** com `{"$error":"..."}`. Com um header de debug ligado, o exemplo da doc acrescenta `debug$error` com `dbms_utility.format_error_stack` e `format_error_backtrace` (só para desenvolvedores).

Fonte: [Reusing Common REST API Handler Code](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/reusing-common-rest-api-handler-code.html), [Receiving Validation Error in REST API](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/receiving-validation-error-rest-api.html)

### Mesma regra de negócio na página e na API (camadas de package e Text Messages)

Se um sistema externo pode alterar dados, a API precisa aplicar **as mesmas validações e defaults** da interface. Padrão recomendado:

- `*_COMMON`: funções de validação que devolvem `null` (ok) ou mensagem de erro; checagens agregadas (ex.: "exatamente um líder", "sem membros duplicados") rodam **depois de gravar e antes do commit**, então podem usar `COUNT(*)`/`GROUP BY ... HAVING`.
- `APP_COMMON`: `error_message` (busca Text Message traduzível com `APEX_LANG.GET_MESSAGE`), `report_if_error` (dentro do APEX usa `APEX_ERROR.ADD_ERROR`; fora, `raise_application_error(-20001, ...)`; detecta o contexto por `apex_application.g_flow_id is not null`). Fora de uma sessão, `apex_util.set_workspace` antes de `get_message` com `p_application_id`.
- `*_API` (núcleo: JSON → records → before_save → save → after_save → get_object) e `*_API_REST` (converte CLOB em `JSON_OBJECT_T`, chama o núcleo e responde com o helper REST).
- Páginas chamam as mesmas funções por **Invoke API** ou validações. Text Messages: `&{TEAM_MAX_ONE_LEAD}.` em páginas, com tokens `&{MSG name="&P3_NAME."}.`; em PL/SQL `apex_lang.get_message(p_name => ..., p_params => apex_t_varchar2('name', valor))`.

Fonte: [Enforcing Business Logic in REST APIs](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/enforcing-business-logic-rest-apis.html), [Handling Errors in a Common Way](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/handling-errors-common-way.html), [Coding Business Rules for Reuse](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/coding-business-rules-reuse.html), [Studying API Handler Package Layers](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/studying-api-handler-package-layers.html), [Using Text Messages in Pages and PL/SQL](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-text-messages-pages-and-pl-sql.html)

### JSON em SQL e PL/SQL para APIs (JSON_OBJECT, JSON_ARRAYAGG, JSON_OBJECT_T, JSON_TRANSFORM)

- **SQL**: `JSON_OBJECT('_id' value id, name, ...)` e `JSON_ARRAYAGG(JSON_OBJECT(...) ORDER BY ...)`. Use `RETURNING CLOB` no `JSON_ARRAYAGG` e no `JSON_OBJECT` externo para não ficar limitado a 4000 caracteres. Uma view com o array aninhado simplifica os GET handlers.
- **PL/SQL**: `JSON_OBJECT_T(clob)` para parsear; `get_string`, `get_number`, `get_array`; `JSON_ARRAY_T.get(i)` devolve `JSON_ELEMENT_T`, use `TREAT(... AS JSON_OBJECT_T)`. Monte arrays com `append` e só depois `put` no objeto. Serialize com `stringify` (até 32767 caracteres; acima dá `ORA-40478`) ou `to_clob` (qualquer tamanho). Chamar método em variável nula dá `ORA-30625`.
- **26ai**: tipo `JSON`, `JSON_TRANSFORM` (`set`/`remove` com filtros de path, ex.: default de `role` = `'MEMBER'` onde nulo ou ausente), `JSON_VALUE`/`JSON_TABLE` sem reparsear, interoperabilidade `json_object_t(l_json)` ↔ `.to_json`. Com duality view, a API do exemplo ficou 51% menor (158 × 325 linhas).

Fonte: [Constructing JSON in SQL](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/constructing-json-sql.html), [Parsing JSON in PL/SQL](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/parsing-json-pl-sql.html), [Serializing JSON in PL/SQL](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/serializing-json-pl-sql.html), [Storing and Accessing JSON Type Data](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/storing-and-accessing-json-type-data.html), [Seeing How Duality View Simplifies Logic](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/seeing-how-duality-view-simplifies-logic.html)

### Paginação feita à mão num handler PL/SQL

Padrão do `get_objects` da doc: `COUNT(*) OVER()` para o total, `ORDER BY` determinístico, `OFFSET n ROWS FETCH FIRST m ROWS ONLY`, defaults `offset 0` e `limit 25`, e resposta `{"items":[...], "hasMore": offset+linhas < total, "totalRows": total}`.

```sql
for r in (select id, count(*) over() as total
            from action_items
           where upper(name) like upper('%'||p_search||'%')
           order by upper(name)
          offset l_offset rows fetch first l_limit rows only)
loop
    ...
end loop;
```

Fonte: [Retrieving Action Items with Paging](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/retrieving-action-items-paging.html)

### AutoREST: expor tabela, view ou duality view sem escrever handlers

- **SQL Workshop › RESTful Services › Enabled Objects › Create AutoREST Object**: Object Type, Object, **Object Alias** (substitui o nome na URL; por segurança use um alias diferente do nome real), **Authorization Required**, Full URL. Requer schema registrado e objeto compatível com AutoREST.
- **Sem autorização, o objeto fica público na internet.** Com *Authorization Required = Yes*, aparece o **Authorization Role** criado pelo ORDS, que você precisa conceder aos usuários/clientes no ORDS.
- No SQL Developer Web: menu REST › Enable... do objeto (inclusive duality views).
- Uma duality view com AutoREST herda defaults, checks, integridade referencial e triggers das tabelas e só permite o DML anotado. Regras mais complexas (ex.: "um líder por equipe") exigem handlers PL/SQL que passem por um package "porteiro".

Fonte: [Enabling REST Objects](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/enabling-rest-objects-from-object-browser.html), [Enabling Authorization for REST-enabled Objects](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/enabling-authorization-for-rest-enabled-objects.html), [Enabling AutoREST for a Duality View](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/enabling-autorest-duality-view.html), [Exercising Duality View AutoREST Endpoint](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/exercising-duality-view-autorest-endpoint.html), [Enforcing More Complex Business Logic](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/enforcing-more-complex-business-logic.html)

### Segurança de APIs ORDS: Privileges, Roles e OAuth2 Client Credentials

Para uso em produção, proteja as APIs com controle de acesso por papel e entregue a cada sistema parceiro um **OAuth 2.0 client** próprio.

1. **Role** (SQL Developer Web › REST › Security › Roles): agrupa privilégios, ex.: "External Application Integration".
2. **Privilege**: protege módulos inteiros (*Protected Modules*) e/ou padrões de URL (*Protected Resources*) e é concedido a roles. No SQL Workshop: Privileges › Create Privilege (Name, Title, Description, Roles, Protected Modules, Protected Resources). **Excluir um privilégio deixa os módulos desprotegidos.**
3. **OAuth Client** (Security › OAuth Clients): Grant Type **`CLIENT_CRED`**, nome, e-mail de suporte, roles. O ORDS gera client id e secret **mostrados uma única vez**: guarde num cofre. O menu do client permite revogar ou rotacionar o secret. Crie **um client por sistema externo**.

Uso pelo parceiro:

```sh
# obter token (POST form-urlencoded grant_type=client_credentials)
curl --user "<client_id>:<client_secret>" --data "grant_type=client_credentials" \
     https://example.com/ords/cloudcompanion/oauth/token
# {"access_token":"...","token_type":"bearer","expires_in":3600}

# chamar a API
curl -H "Authorization: Bearer <access_token>" \
     https://example.com/ords/cloudcompanion/v1/actionitems/14
```

O token vale `expires_in` segundos (ex.: 3600); depois disso a API responde **401 Unauthorized** e o cliente deve pedir outro token. Do lado APEX consumidor, isso corresponde a uma Web Credential **OAuth2 Client Credentials**, que renova o token sozinha.

Fonte: [Securing APIs with Role-Based Access Control](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/securing-apis-role-based-access-control.html), [Defining ORDS Role and Privileges](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/defining-ords-role-and-privileges.html), [Issuing OAuth Client for Authentication](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/issuing-oauth-client-authentication.html), [Using REST API with an OAuth Client](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-rest-api-oauth-client.html), [Creating an ORDS RESTful Service Privilege](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/managing-restful-service-modules.html)

### Testar, documentar, exportar e importar módulos ORDS

- **Testar**: `curl https://.../v0/actionitems | jq` (formata o JSON) ou Postman. O REST Designer tem botão para copiar a URL do template.
- **Swagger**: *Generate Swagger Doc* no módulo. Se a instância tiver uma URL de Swagger UI configurada, o APEX abre a UI com o documento; senão mostra o JSON gerado pelo ORDS.
- **Export**: módulo único ou *All Services*, em script SQL. **Import**: escolha arquivo e charset; se já existir serviço com o mesmo nome, ele é **apagado e substituído**. Um export de APEX-based REST Services não importa ("wrong type").
- O módulo de exemplo `oracle.example.hr` só pode ser instalado ao criar o workspace/registrar o schema, ou por *Install Sample Service*; *Reset Sample Service* apaga e recria.

Fonte: [Testing Handler with curl or Postman](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/testing-handler-curl-or-postman.html), [Managing RESTful Service Modules](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/managing-restful-service-modules.html)

---

## 8. Carga de dados (Data Loading)

### Data Load Definition: o que é, formatos, limites e tipos suportados

Uma **Data Load Definition** (Shared Components › Other Components › Data Load Definitions) descreve como carregar arquivos externos para uma **tabela** ou **collection**. É composta pela definição, um **Data Profile** e suas colunas, e é usada pelo processo nativo **Data Loading** e pela API `APEX_DATA_LOADING`.

- Formatos: **CSV, XLSX, XML e JSON**. O formato do arquivo de exemplo vira o formato do profile e **restringe o que o usuário pode subir**: definição criada com CSV aceita `TXT`/`CSV`; criada com XLSX aceita só `XLSX`. Copy & paste só existe para profile CSV.
- Mapeamento de colunas é feito **em design time** (por nome simples ou expressão regular), com regras de transformação, lookups, SQL Expression ou SQL Query por coluna.
- Até **300 colunas** (o legado aceitava 45). Tipos: `VARCHAR2`, `NUMBER`, `DATE`, `TIMESTAMP`, `TIMESTAMP WITH LOCAL TIME ZONE`, `TIMESTAMP WITH TIME ZONE`, `CLOB`.
- **Não** foi feita para centenas de milhares de linhas: para volumes grandes, use SQL Developer ou SQL*Loader.
- App de exemplo: *Sample Data Loading* (Gallery).

Fonte: [About Creating a Page with Data Loading Capability](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-applications-with-data-loading-capability.html), [Loading External Data](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/loading-external-data.html)

### Criar e editar a Data Load Definition (Loading Method, Commit Interval, Error Handling)

Wizard: **Method** (From Scratch ou cópia) › **Target** (Name, Target Type = Table ou Collection, Table Owner (default: schema de parse), Table Name, sensível a maiúsculas se digitado) › **Sample Data** (Upload a File ou Copy and Paste; para XLSX com várias abas, *Select Sheet*) › **Map Columns** (mapeamento automático por nome; deixe *Map To* vazio para ignorar uma coluna; marque a **Primary Key**) › Preview › *Create Data Load* ou *Create and Add Page*.

Atributos editáveis:

| Grupo | Atributo | Valores |
|---|---|---|
| Data Load | Name, **Static ID** (usado nas APIs) | |
| Target | Target Type, Table Owner, Table Name | Table / Collection |
| Settings | **Loading Method** | **Append** (com PK: não altera existentes e só acrescenta novos; sem PK: acrescenta tudo) · **Merge** (exige PK; atualiza ou insere; só para tabelas) · **Replace** (apaga o destino antes) |
| Settings | **Commit Interval** | vazio = uma transação com commit no fim; N = commit a cada N linhas |
| Error Handling | **When on Error** | **Ignore** (pula a linha) · **Stop** (para no 1º erro) · **Log Error into Collection** · **Log into Error Log** (tabela de DML Error Logging; só para tabela e só com Append sem PK) |
| Data Profile | Format, Row Selector (XML/JSON), colunas | |

Exemplo de error log: `begin dbms_errlog.create_error_log(dml_table_name => 'EMP'); end;` cria `ERR$_EMP`; depois escolha *Log into Error Log* e a tabela em *Error Logging Table*.

Copy/Subscribe de outra app funciona como nos outros shared components.

Fonte: [Creating a Data Load Definition](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-applications-with-data-loading-capability.html), [Editing a Data Load Definition](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-applications-with-data-loading-capability.html), [Example: Log Errors to a DML Error Log](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-applications-with-data-loading-capability.html), [Creating a Data Load Definition (Companion)](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/creating-data-load-definition.html)

### Colunas calculadas na carga (SQL Expression, SQL Query, valores de sessão)

No Data Profile da definição, *Add Column* do tipo **SQL Expression** ou **SQL Query** gera valores derivados. Para transformar uma coluna do arquivo, renomeie a original (ex.: `ENAME` → `ORIG_ENAME`) e crie uma nova `ENAME` com `upper(ORIG_ENAME)`. A expressão pode ser constante ou ler um application item com `V('G_APP_USER_EMPNO')`: uma coluna SQL Expression com o nome da coluna de destino carrega esse valor nela.

> Nota: o exemplo da doc escreve `upper( ORIG_NAME )` depois de renomear para `ORIG_ENAME`; use o nome que você deu de fato à coluna.

Fonte: [Augmenting Data Load Profile Columns](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/augmenting-data-load-profile-columns.html)

### Página de Data Loading gerada pelo wizard: como funciona por dentro

Create Page › Component › **Data Loading** (Data Load, *Upload Data From* = File ou Copy and Paste, **Maximum File Size (MB)**, breadcrumb e menu). A página gerada combina:

1. **File Upload** (`P32_FILE`) em *Block Dropzone*, storage **Table APEX_APPLICATION_TEMP_FILES** com purge no fim da sessão, um arquivo por vez.
2. DA no **Change** do item que faz **Submit Page** imediato (sobe o arquivo). Uma computação After Submit preenche o nome original a partir de `APEX_APPLICATION_TEMP_FILES.FILENAME`.
3. **Validação** do tipo com `apex_data_parser.assert_file_type(p_file_name => ..., p_file_type => apex_data_parser.c_file_type_xlsx)`; se falhar, limpa o item e retorna false.
4. Select List de **planilha**, visível só se `apex_data_parser.get_xlsx_worksheets` devolver mais de uma; mudar a planilha submete a página.
5. **Preview** (Classic Report, até 100 linhas) com `apex_data_parser.parse(... p_file_profile => apex_data_loading.get_file_profile(p_static_id => '...'))`, ordenado por `LINE_NUMBER`.
6. Processo nativo **Data Loading** (condição: botão `LOAD`) apontando para a definição; fonte = item File Upload (ou textarea, ou SQL que devolve CLOB/BLOB) e item da planilha. Sem *Success Message*, mostra a mensagem default com o número de linhas.

O load default da página testada pela doc usa o método **Merge**.

```sql
select p.line_number, p.col001, p.col002, p.col003
  from apex_application_temp_files f,
       table(apex_data_parser.parse(
                 p_content         => f.blob_content,
                 p_file_name       => f.filename,
                 p_xlsx_sheet_name => :P32_XLSX_WORKSHEET,
                 p_file_profile    => apex_data_loading.get_file_profile(
                                          p_static_id => 'load_employees_from_excel'),
                 p_max_rows        => 100)) p
 where f.name = :P32_FILE
```

Fonte: [Creating a Data Loading Page Using the Create Page Wizard](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-applications-with-data-loading-capability.html), [Understanding Data Loading Pages](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-data-loading-pages.html), [Specifying the File and Uploading It](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/specifying-file-and-uploading-it.html), [Validating the Uploaded File Type](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/validating-uploaded-file-type.html), [Letting User Select Worksheet](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/letting-user-select-worksheet.html), [Previewing External Data Before Loading](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/previewing-external-data-loading.html), [Loading Data with Native Page Process](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/loading-data-native-page-process.html)

### APEX_DATA_PARSER.PARSE: ler CSV, XLSX, XML e JSON sem gravar nada

Função *pipelined* que devolve `LINE_NUMBER, COL001 ... COL300` (tudo em `VARCHAR2`, até 4000 bytes; 20 das 300 colunas podem ser CLOB). O parse acontece na hora; nada vai para collection ou tabela temporária.

Parâmetros principais: `p_content` (BLOB), `p_file_name` ou `p_file_type` ou `p_file_profile` (um deles é obrigatório), `p_detect_data_types` (`Y` default), `p_decimal_char`, `p_xlsx_sheet_name` (default: primeira planilha), `p_row_selector` (JSON/XML; default XML `/*/*`, JSON = primeiro array), `p_csv_col_delimiter` (auto), `p_csv_row_delimiter` (LF, cobre CRLF), `p_csv_enclosed` (`"`), `p_skip_rows`, `p_add_headers_row`, `p_nullif`, `p_force_trim_whitespace`, `p_file_charset` (`AL32UTF8`), `p_max_rows`, `p_return_rows`, `p_store_profile_to_collection`, `p_xml_namespaces`, `p_fix_excel_precision` (arredonda para 15 dígitos significativos do Excel).

Fluxo sem definição: `PARSE` (descobre a estrutura) → `GET_FILE_PROFILE` (JSON com tipo de arquivo, delimitador, planilha, cabeçalho, colunas, tipos e máscaras) → `GET_COLUMNS` (lista estruturada) → processamento. `JSON_TO_PROFILE` converte o JSON no record `T_FILE_PROFILE`. Constantes de tipo: `c_file_type_xlsx` (1), `csv` (2), `xml` (3), `json` (4), `ics` (5).

Desempenho: BLOBs < 50 MB são copiados para um LOB temporário em cache (parse em memória); acima disso o parse usa o LOB original e pode ficar lento. Para arquivos grandes, crie um LOB temporário com `DBMS_LOB.CREATETEMPORARY(cache => TRUE)` + `DBMS_LOB.COPY`. XLSX é aberto com `APEX_ZIP` e lido com `XMLTABLE`. CLOB: em CSV/XLSX até 32K; em JSON só se o profile passado tiver coluna CLOB (e aí fica bem mais lento).

Fonte: [PARSE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_PARSER.PARSE-Function.html), [GET_FILE_PROFILE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_PARSER.GET_FILE_PROFILE-Function.html), [Global Constants](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DATA_PARSER.Global-Constants.html), [Parsing Data Without Data Load Definition](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/parsing-data-data-load-definition.html)

### APEX_DATA_LOADING.LOAD_DATA: carregar por código, vários arquivos e ZIP

```sql
declare
    l_res apex_data_loading.t_data_load_result;   -- processed_rows, error_rows
begin
    for f in (select blob_content, filename
                from apex_application_temp_files
               where name in (select column_value
                                from apex_string.split(:P33_FILE, ':'))) loop
        l_res := apex_data_loading.load_data(
                     p_static_id    => 'load_employees_from_csv',
                     p_data_to_load => f.blob_content);      -- BLOB ou CLOB
        -- l_res.processed_rows / l_res.error_rows
    end loop;
end;
```

- Assinaturas: `p_data_to_load` BLOB (arquivo) ou CLOB (texto colado); `p_xlsx_sheet_name`; `p_application_id` (default: app atual). Fora de uma página, crie sessão com `apex_session.create_session`.
- Para **vários formatos**, crie uma definição por formato (Excel, CSV, JSON, XML), todas mapeando para a mesma tabela, e escolha a definição pela extensão ou MIME type.
- **ZIP**: `apex_zip.get_files(l_zip)` lista os arquivos e `apex_zip.get_file_content(l_zip, l_files(i))` devolve cada um, que segue para a mesma rotina.
- O File Upload da página usa *Allow Multiple Files* e **Purge File at = End of Request** (o arquivo só precisa existir durante o submit). Mensagem de sucesso traduzível com `apex_lang.get_message` e placeholders `%0`, `%1`.

Fonte: [LOAD_DATA Function Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/LOAD_DATA-Function-Signature-1.html), [LOAD_DATA Function Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/LOAD_DATA-Function-Signature-2.html), [Processing Multiple Uploaded Files](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/processing-multiple-uploaded-files.html), [Setting File Upload to Handle Multiple Files](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/setting-file-upload-handle-multiple-files.html), [Adding XML, CSV, JSON Data Load Definitions](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/adding-xml-csv-json-data-load-definitions.html)

---

## 9. Upload, exibição e download de arquivos

### Visão geral: Image Upload, File Upload, BLOB e download nativo

- **Image Upload**: imagens, com opções próprias (recorte, redimensionamento no cliente, preview). Grava num BLOB, em `APEX_APPLICATION_TEMP_FILES` ou, com código, num bucket do OCI Object Storage.
- **File Upload** (antigo *File Browse*): qualquer tipo de arquivo (PDF etc.), um ou vários.
- **Download**: processo de página ou Dynamic Action nativos **Download** (um arquivo ou ZIP de vários), coluna *Download BLOB* em relatórios, ou página/processo que chama `APEX_HTTP.DOWNLOAD` para servir arquivos inline.
- Nenhum dos dois itens de upload é suportado como coluna de Interactive Grid.

Recomendação de segurança da doc: envie arquivos para **uma tabela do seu schema** (BLOB) ou, se precisar de acesso programático, para `APEX_APPLICATION_TEMP_FILES`. A view `APEX_APPLICATION_FILES` (tabela comum de arquivos do workspace) nem sempre exige autenticação no acesso programático, então outros usuários podem ver os arquivos. Com os métodos nativos, as authorizations da página valem também para o acesso ao arquivo, e a tabela própria permite gerir o storage (TRUNCATE, mover segmento LOB).

Fonte: [Uploading, Viewing, and Downloading Files](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/uploading-viewing-and-downloading-files.html), [About Securing File Uploads](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-securing-file-uploads.html), [About Item Types: File Upload](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-item-types.html)

### File Upload: atributos (Display, Storage, File Types, Maximum File Size, Purge File at)

| Grupo › Atributo | Valores e comportamento |
|---|---|
| Display › **Display As** | *Inline File Browse*, *Inline Dropzone*, *Block Dropzone* (estilo wizard, com botão), *Native File Browse* (controle nativo do browser). |
| Display › Dropzone Title / Description | Vazios usam as Text Messages `APEX.ITEM.FILE.DROP_FILE(S)`, `APEX.ITEM.FILE.DROP_OR_CHOOSE_FILE(S)` (Block) e `APEX.ITEM.FILE.DROP_OR_SELECT_FILE(S)` (Inline). |
| Display › **Capture Using** | Abre a câmera principal ou a selfie no celular. Com isso configurado, no celular o usuário **não consegue escolher arquivos** (só fotos/câmera); no desktop nada muda. |
| Display › Display Download Link, Download Link Text, Content Disposition | Link de download ao editar uma linha existente. |
| **Allow Copy & Paste** | Colar arquivo da área de transferência. Ligue em **um só** item de upload por página. |
| Storage › **Type** | *BLOB column specified in Item Source attribute* (grava na coluna BLOB da tabela do processo de DML automático; o download usa a tabela do Automatic Row Fetch) ou *Table APEX_APPLICATION_TEMP_FILES*. |
| Storage › **Purge File at** (temp files) | *End of Session* ou *End of Request*. |
| Storage › **Allow Multiple Files** (temp files) | O valor do item vira lista de nomes únicos separados por `:`. |
| Storage › MIME Type Column, Filename Column, **Character Set Column**, BLOB Last Updated Column (coluna BLOB) | Nomes dos itens/colunas que guardam metadados. O charset **não** é detectado no upload: precisa de um item para o usuário informar. O Last Updated serve ao cache do browser. |
| Storage › **File Types** | Lista separada por vírgulas de extensões e MIME types (ex.: `.pdf,application/pdf`), usada pelo seletor de arquivos do sistema. |
| Storage › **Maximum File Size** | Em **KB**. Excedeu: erro de validação amigável (ex.: "File is too large. Maximum file size is 3MB."). |

Existe ainda a opção legada *Table WWV_FLOW_FILES*, mantida só por compatibilidade e não recomendada.

Fonte: [About Item Types: File Upload](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-item-types.html), [Configuring File Upload to a BLOB Column](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configuring-file-upload-blob-column.html), [Controlling File Upload Item Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/controlling-file-upload-item-behavior.html), [About Uploading and Downloading Files into a BLOB](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-blob-support-in-forms.html)

### Image Upload: recorte, redimensionamento, preview e câmera

Mesmos atributos de storage do File Upload, mais:

- **Display As**: *Inline File Browse*, **Icon Dropzone** (default; só ícone, trocado pelo preview), *Inline Dropzone*, *Block Dropzone*, *Native File Browse*. **Preview Size**: Auto (default), Extra Small … Extra Large; tamanhos novos com a classe `apex-item-image--{size}` no tema. Para um tamanho livre, a variável CSS `--a-filedrop-icon-size` (no item `#P6_IMAGE { --a-filedrop-icon-size: 25rem; }` ou em `:root`).
- **Cropping › Allow Cropping** e **Aspect Ratio** (Original, 1:1, 16:9, 4:3, 2:1, Custom com *Custom Aspect Ratio* tipo `3:2`). **Recorte não funciona com Allow Multiple Files.**
- **Resize To › Maximum File Size (KB), Maximum Width, Maximum Height (px)**: a imagem é reduzida **no cliente**, em segundo plano, antes do upload (evita fotos de vários megapixels).
- Capture Using, Allow Copy & Paste e Display Download Link como no File Upload.

Fonte: [About Item Types: Image Upload](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-item-types.html), [Controlling Image Upload User Experience](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/controlling-image-upload-user-experience.html), [Enlarging Image Upload Icon Preview](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/enlarging-image-upload-icon-preview.html)

### Gravar upload numa coluna BLOB com Form region (DML automático)

1. Form region sobre a tabela (ou view) que tem a coluna BLOB. O item da coluna vira File Upload/Image Upload (forms gerados por wizard já fazem isso).
2. Storage Type = **BLOB column specified in Item Source attribute**; confira em Source a coluna BLOB.
3. Preencha **MIME Type Column**, **Filename Column** e **BLOB Last Updated Column**: sem eles o browser não sabe tratar o arquivo ao exibir/baixar. Recomenda-se acrescentar essas colunas à tabela:

```sql
alter table emp add (
    attach_mimetype    varchar2(255),
    attach_filename    varchar2(255),
    attach_last_update date,
    attach_charset     varchar2(128));
```

4. Marque o switch **Primary Key** nos itens de PK.
5. Na aba Processing: processo **Form - Automatic Row Processing (DML)** com *Form Region* apontando para o form e **antes** do *Close Dialog* (em modal/drawer).
6. O botão que submete (ex.: `CREATE`) precisa de **Database Action = SQL INSERT action**. O Create Page Wizard faz os passos 5 e 6; ao adicionar um Form numa página existente, você faz à mão.

Não existe "setar para nulo" pelo File Browse: para remover o arquivo, crie um botão/processo que faça `UPDATE ... SET blob = NULL, mimetype = NULL, filename = NULL, ...`.

Fonte: [Configuring Upload Image Item Source](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configuring-upload-image-item-source.html), [Ensuring the Automatic DML Process](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/ensuring-automatic-dml-process.html), [Understanding BLOB Support in Forms](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-blob-support-in-forms.html)

### APEX_APPLICATION_TEMP_FILES: estrutura, retenção e acesso por nome único

Com Storage = *Table APEX_APPLICATION_TEMP_FILES*, o APEX grava o arquivo nessa view, isolada por sessão (o usuário só vê o que subiu na sessão atual).

| Coluna | Tipo | Conteúdo |
|---|---|---|
| `NAME` | VARCHAR2 | Nome **único** gerado (é o valor do item) |
| `BLOB_CONTENT` | BLOB | Conteúdo |
| `FILENAME` | VARCHAR2 | Nome original |
| `MIME_TYPE` | VARCHAR2 | MIME type |
| `APPLICATION_ID` | NUMBER | App |
| `CREATED_ON` | DATE | Criação |

- **End of Request**: use quando o processamento para o armazenamento definitivo acontece no **mesmo submit**. **End of Session**: quando o processamento vem depois (fluxo de vários passos).
- Valor do item: um nome único, ou lista separada por `:` se *Allow Multiple Files*.
- A view aceita `DELETE` (apagar antes do purge automático); não aceita INSERT/UPDATE.

```sql
-- um arquivo
select blob_content, filename, mime_type
  from apex_application_temp_files
 where name = :P1_ARQUIVO;

-- vários arquivos
for f in (select blob_content, filename, mime_type
            from apex_application_temp_files
           where application_id = :APP_ID
             and name in (select column_value
                            from apex_string.split(:P17_IMAGE, ':')))
loop
    insert into meus_arquivos(conteudo, nome, mime_type)
    values (f.blob_content, f.filename, f.mime_type);
end loop;

-- limpar cedo
delete from apex_application_temp_files
 where application_id = :APP_ID
   and name in (select column_value from apex_string.split(:P17_IMAGE, ':'));
```

Fonte: [Controlling Retention of Temporary Files](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/controlling-retention-temporary-files.html), [Referencing Temp Files by Unique Name](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/referencing-temp-files-unique-names.html), [Processing Temporary Uploaded Files](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/processing-temporary-uploaded-files.html), [Deleting Temporary Uploaded Files](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/deleting-temporary-uploaded-files.html)

### Upload de várias imagens com dados extras (temp files + collection + grid)

Padrão da doc (página *Add Break Room Photos*):

1. Image Upload com *Allow Multiple Files*, temp files, **End of Session**.
2. Uma **collection** "lateral" (`UPLOADED_PHOTOS`) guarda o nome único em `C001` e o título em `C002`.
3. Uma **view** junta `APEX_APPLICATION_TEMP_FILES` e `APEX_COLLECTIONS` pelo nome único (com `NV('APP_ID')` e `NV('G_...')` numa CTE `/*+ NO_MERGE */`).
4. Processos em **execution chains** condicionais: ao abrir (`:P17_CLEAR = 'Y' or not pkg.uploaded_photos`) limpa temp files e faz `apex_collection.create_or_truncate_collection`; no botão `UPLOAD` adiciona os nomes à collection (`apex_string.split(:P17_IMAGE, ':')` + `add_member`); o *Close Dialog* só roda no botão `SAVE`.
5. Regiões alternam por condição (há fotos pendentes ou não): upload × **Interactive Grid** de preview com `<img src>` vindo de uma página que serve o temp file inline.
6. O IG grava na collection com **Target Type = PL/SQL Code** (`:APEX$ROW_STATUS` = `U` → `update_member_attribute`; `D` → `delete_member`), depois um processo insere tudo na tabela final e outro limpa a collection.

Pegadinha do IG: coluna *Value Required* **não** valida células consultadas e não editadas. Para forçar o título, "suje" as linhas vazias por JavaScript no evento *Selection Changed*: `model.setValue(rec,'TITLE',' ',true); model.setValue(rec,'TITLE',valor,true);`.

Fonte: [Posting Multiple Break Room Photos](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/posting-multiple-break-room-photos.html), [Joining Collection with Temp Files Table](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/joining-collection-temp-files-table.html), [Clearing Collection to Start the Process](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/clearing-collection-start-process.html), [Writing Grid Updates to Collection](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/writing-grid-updates-collection.html), [Invalidating Required Queried-Null Titles](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/invalidating-required-queried-null-titles.html)

### Exibir imagens BLOB em Cards, Form, Classic/Interactive Report, Content Row e Search

Regiões que leem BLOB direto: Form, Cards, Classic Report, Interactive Report, Template Component (Content Row) e Search. O Interactive Grid **não** tem coluna de imagem (ver próxima seção).

- **Cards**: Media › Source = BLOB Column; em *BLOB Attributes* informe **Mime Type Column** e **Last Updated Column** (para o browser recarregar só quando muda).
- **Form**: item **Display Image** baseado em BLOB, com Alternative Text Column (acessibilidade e tooltip), Filename, MIME Type e BLOB Last Updated. Para esconder o rótulo: Label vazio, Template Hidden, Label Column Span 0.
- **Classic e Interactive Report**: por padrão um BLOB aparece como `[unsupported data type]`. Selecione o **tamanho** em vez do BLOB (`dbms_lob.getlength(image) as image`) e mude o tipo da coluna para **Display Image** (ou **Download BLOB** para link de download), preenchendo em *BLOB Attributes*: Table Name, BLOB Column, Primary Key Column(s) (mais de duas colunas de PK → use `ROWID`), Mime Type, Filename, Last Updated, Character Set. Tamanho 0 = sem imagem/link. Download BLOB tem *Download Text* e *Content Disposition* (Attachment ou Inline).
- **Content Row**: Avatar › Type = Image, configure as colunas no diálogo Media; tamanho com `.t-Avatar--image { --ut-avatar-size: 10rem; }`.
- **Search Configuration**: Icon Source = Image BLOB Column + Mime Type Column.
- Tamanho das miniaturas por CSS, mantendo proporção: `.a-IRR-table img { height: 90px; object-fit: contain; }` (IR), `.t-Report-report img {...}` (Classic), `.a-ResultsItem-image img {...}` (Search).
- Wizards **não** incluem colunas BLOB em relatórios; configure depois de gerar.

Fonte: [Displaying BLOB Column Images](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/displaying-blob-column-images.html), [Showing BLOB Column Images on Cards](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/showing-blob-column-images-cards.html), [Previewing Image in a Form Region](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/previewing-image-form-region.html), [Displaying BLOB Images in Classic Reports](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/displaying-blob-images-classic-reports.html), [Understanding BLOB Support in Forms and Reports](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-blob-support-in-forms-and-reports.html), [About Item Types: Display Image](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-item-types.html)

### Imagens no Interactive Grid e URLs de imagem (APEX_UTIL.GET_BLOB_FILE_SRC)

O IG precisa de uma tag `<img>` com `src` que o browser consiga buscar. Opção 1: **`APEX_UTIL.GET_BLOB_FILE_SRC`**.

```sql
select id, title,
       case when image is not null and dbms_lob.getlength(image) > 0
            then apex_string.format('<img alt="%s" title="%s" src="%s">',
                     apex_escape.html_attribute(title),
                     apex_escape.html_attribute(title),
                     apex_util.get_blob_file_src('P12_IMAGE', id))
       end as image
  from eba_demo_emp_breakroom_photo_v
```

- Assinatura: `GET_BLOB_FILE_SRC(p_item_name, p_v1, p_v2, p_content_disposition)` (`p_v1`/`p_v2` = valores da PK; disposition `INLINE` ou `ATTACHMENT`). Exige sessão APEX válida.
- `p_item_name` é um item de **formulário** cujo source é a coluna BLOB: a função deduz dele as colunas de BLOB, MIME e Last Updated e, da região Form, a tabela. O item pode ficar invisível (slot *Dialogs, Drawers and Popups* ou classe `u-hidden`).
- No IG: coluna **Display Only** com Format **HTML**; se o grid for editável, ligue **Query Only** na coluna. Sempre escape textos com `apex_escape.html_attribute`.
- Se passar a URL para `APEX_UTIL.PREPARE_URL` num modal, use `p_plain_url => true`.

Fonte: [Using GET_BLOB_FILE_SRC for Image URL](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-get_blob_file_src-image-url.html), [Configuring Reference Image Page Item](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configuring-reference-image-page-item.html), [GET_BLOB_FILE_SRC Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_BLOB_FILE_SRC-Function.html)

### Página que serve arquivo inline (APEX_HTTP.DOWNLOAD) e X01 × item com checksum

Opção 2 (mais flexível): uma página só para servir o arquivo. Processo **Invoke API** em *Pre-Rendering › Before Header* chamando uma procedure:

```sql
procedure download_foto(p_id in number) is
    l_blob blob;
    l_mime varchar2(255);
begin
    select image, mime_type into l_blob, l_mime
      from fotos where id = p_id;
    apex_http.download(
        p_blob         => l_blob,
        p_content_type => l_mime,
        p_is_inline    => true);   -- false = diálogo "salvar"
end;
```

`APEX_HTTP.DOWNLOAD` (BLOB ou CLOB, com `p_filename` opcional) **limpa o buffer HTP** e chama `APEX_APPLICATION.STOP_APEX_ENGINE` no fim. A URL vem de `apex_page.get_url(p_page => 9000, p_x01 => id)`; dentro de modal/drawer passe `p_plain_url => true` (senão entra JavaScript de fechar diálogo); dentro de `iframe` use `p_absolute_url => true`.

**X01 × item protegido**: `p_x01` (lido com `apex_application.g_x01`) é cômodo, mas **não tem checksum**: um usuário autenticado pode copiar a URL e trocar o ID. Se o arquivo é sensível ou por usuário, use um **item oculto** na página servidora e `apex_page.get_url(p_page => 9005, p_items => 'P9005_ID', p_values => id)`; com *Page Access Protection = Arguments Must Have Checksum* (default), a URL ganha o parâmetro `cs` e qualquer alteração dá erro. PK composta: `p_items => 'P9005_ID1,P9005_ID2'`, `p_values => id1||','||id2`. Também é preciso que a página servidora tenha a authorization adequada.

Fonte: [Serving Inline BLOB Images with a Page](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/serving-inline-blob-images-page.html), [Using an Inline Image Serving Page](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-inline-image-serving-page.html), [Weighing X01 Against a Secure Page Item](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/weighing-x01-secure-page-item.html), [Generating Image URL with Secure Item](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/generating-image-url-secure-item.html), [APEX_HTTP.DOWNLOAD Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HTTP.DOWNLOAD-Procedure-Signature-1.html)

### Download declarativo: processo e Dynamic Action "Download" (um arquivo ou ZIP)

- **Um arquivo**: SQL com três colunas, nesta ordem: BLOB, nome do arquivo, MIME type, retornando **uma** linha. Na DA, liste em **Items to Submit** os itens usados como bind; no processo não há Items to Submit (roda no servidor).
- **Vários arquivos**: ligue **Multiple Files**, informe o nome do ZIP (aceita substituições, ex.: `cvs_&P11_JOB_ID..zip`) e use uma query com duas colunas (BLOB e nome do arquivo), várias linhas.
- O processo Download funciona em *Before Header* (renderização) ou no processamento do submit; **o processamento para depois dele**.

```sql
select candidate_cv_resume, file_name, mime_type
  from eba_demo_emp_job_referrals
 where id = :P11_REFERRAL_CANDIDATE_ID
```

Fonte: [Downloading a File for Offline Use](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/downloading-file-offline-use.html), [Configuring Single-File Download Action](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configuring-single-file-download-action.html), [Downloading ZIP Archive of Multiple Files](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/downloading-zip-archive-multiple-files.html), [About Page Processes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-page-processes.html)

### Visualizar PDF inline (iframe, Template Component e Embed in Frames)

1. **Template Component** "PDF Viewer" (*Available As* = Single (Partial)) com HTML: `{if PDF_URL/}<iframe style="height: calc(100vh - #OTHER_CONTENT_HEIGHT#rem)" src="#PDF_URL#" width="100%" height="100%"></iframe>{endif/}`.
2. Página servidora com `APEX_HTTP.DOWNLOAD(... p_is_inline => true)`.
3. Região com SQL de uma linha que gera a URL **absoluta** (`p_absolute_url => true`, porque URLs relativas num iframe se resolvem contra o próprio iframe); itens usados como bind em *Page Items to Submit*; DA de Change no seletor faz Refresh da região.
4. Shared Components › Security › Browser Security › **Embed in Frames** = **Allow from same origin**. Com o default *Deny*, o iframe falha com `Refused to display ... because it set 'X-Frame-Options' to 'deny'`.

Fonte: [Previewing BLOB Column PDF Files Inline](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/previewing-blob-column-pdf-files-inline.html), [Creating PDF Viewer Template Component](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/creating-pdf-viewer-template-component.html), [Using PDF Viewer in Job Referrals Page](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-pdf-viewer-job-referrals-page.html), [Allowing Embedding from Same Domain](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/allowing-embedding-same-domain.html)

### Abrir modal passando valor dinâmico do cliente (URL com checksum)

Para abrir um modal de upload passando um valor que muda no browser (ex.: a vaga selecionada):

- **Com checksum (recomendado)**: uma ação *Execute Server-side Code* gera a URL com `:P29_URL := apex_page.get_url(p_page => 31, p_items => 'P31_JOB_ID', p_values => :P29_JOB_ID, p_plain_url => true);` (Items to Submit / Items to Return), e uma ação JavaScript abre com `apex.navigation.dialog(url, {title:..., modal:true}, 't-Dialog-page--standard', triggeringElement)` (para drawer: classes `t-Drawer-page--standard t-Drawer--pullOutEnd`).
- **Sem round trip**: gere um *template* de URL com `p_values => '$P11_JOB_ID$'` e troque `%24P11_JOB_ID%24` pelo valor no JavaScript. Exige **Page Access Protection = Unrestricted** na página de destino e **Session State Protection = Unrestricted** nos itens que recebem o valor (os outros itens podem manter o checksum).

Fonte: [Passing Client-Side Data to Dialogs](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/passing-client-side-data-dialogs.html), [Generating Dialog URL on the Server](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/generating-dialog-url-server.html), [Opening Dialog URL Passing Client Data](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/opening-dialog-url-passing-client-data.html), [Unprotecting Dynamic Client Arguments](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/unprotecting-dynamic-client-arguments.html)

### Arquivos no OCI Object Storage (bucket) em vez de BLOB

Guardar arquivos num bucket alivia o banco transacional, ao custo de mais código.

- URL: `https://objectstorage.<região>.oraclecloud.com/n/<namespace>/b/<bucket>/o/<objeto>`.
- **Credencial**: Web Credential *OCI Native Authentication* (OCID do usuário, chave privada `.pem`, fingerprint), com Valid for URLs restrito ao namespace.
- **REST Data Sources** do tipo OCI: listar buckets (`.../n/<ns>/b/` com parâmetro query string `compartmentId`) e objetos (`.../b/:bucketname/o/`, parâmetro `fields=name,size,md5,timeCreated`, operação GET `o/:filename` com Static ID `get_file` e POST `p/` para PAR).
- **Ler/servir**: `MAKE_REST_REQUEST_B` com headers `Accept: */*` e `Accept-Encoding: identity`, MIME vindo do header `Content-Type` da resposta, e `APEX_HTTP.DOWNLOAD` inline.
- **Gravar**: `MAKE_REST_REQUEST` com `p_http_method => 'PUT'` e `p_body_blob`, header `Content-Type` = MIME do arquivo; guarde só o nome do objeto na tabela.
- **Buckets privados** para tudo que não seja asset público. Para entregar arquivos direto do OCI, crie **Pre-Authenticated Requests** (PAR) curtos (`accessType: ObjectRead`, `timeExpires` em ISO 8601) e, se quiser, uma tabela de cache de PAR + automation para limpar os expirados.
- Uma Content Row sobre a REST Data Source de objetos dá um navegador de arquivos com seleção múltipla (*Current Selection Page Item* recebe as PKs separadas por `:`).
- *Static Application Files* também podem ficar no Object Storage (Application Definition › Application File Storage, Remote Server do tipo **File Server**).

Fonte: [Using an OCI Object Bucket for Files](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-oci-object-bucket-files.html), [Storing an Uploaded File in Object Bucket](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/storing-uploaded-file-object-bucket.html), [Creating Pre-Authenticated Requests](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/creating-authenticated-requests.html), [Using Pre-Authenticated Requests](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-authenticated-requests.html), [Managing Static Application Files in Remote Storage](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-static-application-files-in-remote-storage.html)

---

## 10. Collections para dados locais e temporários

### APEX Collections: conceito, colunas e quando usar

Uma **collection** é um "balde" nomeado de linhas temporárias **na sessão do usuário**, manipulado pelo pacote `APEX_COLLECTION` e lido pela view `APEX_COLLECTIONS`. Não precisa de definição: cada membro tem colunas genéricas fixas.

| Tipo | Colunas | Qtde |
|---|---|---|
| VARCHAR2(4000) | `C001`–`C050` | 50 |
| NUMBER | `N001`–`N005` | 5 |
| DATE | `D001`–`D005` | 5 |
| CLOB / BLOB / XMLTYPE | `CLOB001`, `BLOB001`, `XMLTYPE001` | 1 cada |

Mais `COLLECTION_NAME`, `SEQ_ID` e `MD5_ORIGINAL`. Com `MAX_STRING_SIZE=EXTENDED` (instalação em 12c+), as colunas `C` aceitam até 32.767 bytes.

Usos típicos: wizard que junta várias linhas antes da gravação final; página que edita várias linhas de detalhe e aplica tudo no fim; carrinho de compras; dados extras para arquivos temporários; resultados de geocoding no servidor; destino de Data Load Definition (*Target Type = Collection*). Cada sessão vê só as próprias collections, que são limpas automaticamente quando a sessão termina. App de exemplo: *Sample Collections*.

Fonte: [About Using Collections](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-using-collections.html), [Using Temporary Collections](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-temporary-collections.html), [Key Collections Concepts](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/key-collections-concepts.html), [About the APEX_COLLECTION API](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/About-the-APEX_COLLECTION-API.html)

### Collections: criar, adicionar, ler, atualizar, apagar

```sql
-- criar (erro se já existir) ou garantir
if not apex_collection.collection_exists('CARRINHO') then
    apex_collection.create_collection('CARRINHO');
end if;
apex_collection.create_or_truncate_collection('CARRINHO');   -- alternativa

-- adicionar (erro se a collection não existir)
apex_collection.add_member(
    p_collection_name => 'CARRINHO',
    p_c001 => 'COMP-16', p_c002 => sys_guid(),
    p_n001 => 2, p_d001 => date '2025-05-27');

-- a partir de uma query (até 50 colunas → C001..C050)
apex_collection.create_collection_from_query(
    p_collection_name    => 'AUTO',
    p_query              => 'select make, model, year from autos',
    p_truncate_if_exists => 'YES');

-- ler (nome SEMPRE em maiúsculas na view)
select seq_id, c001 as item, n001 as qtde, d001 as data_limite
  from apex_collections
 where collection_name = 'CARRINHO';

-- alterar / remover por SEQ_ID
apex_collection.update_member_attribute(p_collection_name => 'CARRINHO',
    p_seq => 3, p_attr_number => 2, p_attr_value => 'novo');
apex_collection.delete_member(p_collection_name => 'CARRINHO', p_seq => 3);
apex_collection.truncate_collection('CARRINHO');
```

Regras: nomes de collection são convertidos para maiúsculas; `ADD_MEMBER` usa `max(SEQ_ID)+1` (não reaproveita lacunas); valores `C` acima de 4000 caracteres são truncados (use `CLOB001`); `CREATE_COLLECTION_FROM_QUERY` dá erro se a collection já existe, a menos que `p_truncate_if_exists => 'YES'`; `p_generate_md5 => 'YES'` permite detectar mudanças com `GET_MEMBER_MD5`. Também dá para limpar pela 6ª posição do `f?p` (`f?p=App:Page:Session::NO:NOME_COLLECTION`).

Fonte: [Key Collections Concepts](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/key-collections-concepts.html), [ADD_MEMBER Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_MEMBER-Procedure.html), [CREATE_COLLECTION_FROM_QUERY Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CREATE_COLLECTION_FROM_QUERY-Procedure.html), [Accessing a Collection](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/Accessing-a-Collection.html), [Clearing Collection Session State](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/Clearing-Collection-Session-State.html)

### Collections de forma sustentável: view com nomes reais e package de API

- Crie uma **view** sobre `APEX_COLLECTIONS` com aliases significativos (`c001 as item_code`, `c002 as id`…) e use-a nas regiões e no PL/SQL.
- Encapsule `APEX_COLLECTION` num **package de negócio** (`clear_cart`, `add_item` devolvendo o id, `remove_item`, `update_item`), com um `ensure_collection` privado.
- **Interactive Grid sobre collection**: o grid precisa de uma PK estável. Gere um `SYS_GUID()` numa coluna (ex.: `C002`) e procure o `SEQ_ID` por ela; salve com Target Type = PL/SQL Code no processo do grid.

Fonte: [Tips for Maintainable Collection Use](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/tips-maintainable-collection-use.html)

---

## 11. Relatórios PDF e impressão

### Opções de impressão: nativa × print server (Document Generator, AOP, BI Publisher, FOP)

| Print Server Type | Layouts aceitos | Observações |
|---|---|---|
| **None (Native)** | — (sem layout customizado) | CSV, HTML, PDF e XLSX básicos para IR, IG e Classic Report. |
| **Oracle Document Generator Pre-built Function** (OCI) | DOCX, XLSX | Saída PDF, DOCX, XLSX. Exige `DBMS_CLOUD`, credencial de nuvem e configuração **na instância**. |
| **APEX Office Print (AOP)** | DOCX, XLSX, PPTX, HTML, Markdown, CSV, TXT, ODS, ODT, ODP | Também PowerPoint, Markdown, CSV e formatos Open Document na saída. API Key para a versão cloud. |
| **Oracle BI Publisher / Analytics Publisher** | RTF, XSL-FO | Requer licença. |
| **External (Apache FOP)** | XSL-FO | Servidor J2EE externo. |

Document Generator e AOP **não** suportam XSL-FO nem layouts *Generic Columns*. Limites da impressão nativa: uma linha do relatório pode ocupar várias linhas e ter **uma** quebra de página no PDF (o resto é truncado); célula de Excel até 32k caracteres. Com print server externo, a rede do banco precisa estar liberada ("Enabling Network Services in Oracle Database").

Configuração em três níveis:
1. **Instância** (Administration Services › Manage Instance › Instance Settings › Report Printing): escolhe o servidor. Em runtime, `APEX_INSTANCE_ADMIN.SET_PARAMETER` com `PRINT_BIB_LICENSED` (`STANDARD`, `ADVANCED`, `DOCUMENT_GENERATOR`, `AOP`, `NONE`), `PRINT_SVR_HOST`, `PRINT_SVR_PORT`, `PRINT_SVR_PROTOCOL`, `PRINT_SVR_SCRIPT` (default `/xmlpserver/convert`). Document Generator pede Cloud Credential (`APEX_INSTANCE_ADMIN.CREATE_CLOUD_CREDENTIAL`), namespace, compartment OCID, endpoint do bucket, OCID e endpoint da função.
2. **Aplicação** (Application Definition › Report Printing › **Print Server Type**): *Native Printing*, *Remote Print Server* (Remote Server do tipo Print Server, com credencial: Analytics Publisher ou AOP) ou **Use Instance Settings**. Sobrepõe a instância. **Document Generator não pode ser escolhido no nível da app**: configure na instância e use *Use Instance Settings*.
3. **Página/região**: habilitar impressão na região ou usar Report Query.

Fonte: [Printing Report Regions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/printing-report-regions.html), [Formatting a Report Region or Report Query Using Report Layouts](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/formatting-using-report-layouts.html), [Configuring Report Printing for an Instance](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-report-printing-for-an-instance.html), [Setting Your App's Remote Print Server](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/setting-your-apps-remote-print-server.html)

### Report Layout: Generic Columns × Named Columns e Data Loop Name

Shared Components › Files and Reports › **Report Layouts**.

- **Generic Columns (XSL-FO)**: funciona com qualquer query, ajusta o número de colunas sozinho; editável direto no APEX (Report Layout e Report Column Heading). Sem layout escolhido, região e query usam um XSL-FO default.
- **Named Columns**: layout feito para uma lista fixa de colunas (arquivo RTF, XSL-FO, DOCX, XLSX…). Para editar: *Download*, alterar e subir de novo.
- **Data Loop Name** (Document Generator e AOP): nome do array no JSON de dados. No layout ligado a uma **região** (Classic/IR), é definido **no próprio layout**; em Report Query, em cada fonte. Só se aplica a layouts named column que não sejam RTF/XSL-FO.
- Static ID: usado em `APEX_PRINT.GENERATE_DOCUMENT`. Copiar/assinar entre apps é possível (cópia sem assinatura gera Static ID novo).

Fonte: [Formatting a Report Region or Report Query Using Report Layouts](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/formatting-using-report-layouts.html), [Creating Layout for Document Template](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/creating-layout-document-template.html), [Setting Layout Data Loop Name](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/setting-layout-data-loop-name.html)

### Tags do Document Generator em Word e Excel ({#loop}, {campo}, {:loop})

- Cada fonte de dados ganha um nome curto (o **Data Loop Name**). No documento, `{#nome}` … `{/nome}` repete o trecho para cada linha e `{campo}` insere o valor; os nomes de campo são os **nomes das colunas em minúsculas**.
- Excel: `{#emp_t}{ename}({empno}) | {tenure} | {job}{/emp_t}` repete **linhas** (repetição horizontal); `{:emp_n}{ename} — {hiredate} — {job}{/emp_n}` repete **colunas** (repetição vertical).
- Word: tabela com uma linha `{#dir}{ename} | {job} | {mgr} | {deptno}{/dir}`.
- Outros print servers podem ter tags diferentes; consulte o guia do Document Generator para a lista completa.

JSON que o layout recebe: cada Data Loop Name é uma propriedade do topo com um array de objetos (propriedades em minúsculas):

```json
{ "dep":   [ { "deptno": 20, "dname": "RESEARCH", "loc": "DALLAS" } ],
  "emp_t": [ { "empno": 7566, "ename": "JONES", "job": "MANAGER", "tenure": "44 years, 6 months" } ] }
```

Fonte: [Formatting Data in Excel with Tags](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/formatting-data-excel-tags.html), [Formatting Data in Word with Tags](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/formatting-data-word-tags.html), [Inspecting the Report Query JSON](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/inspecting-report-query-json.html)

### Report Query: várias fontes, formatos de saída e impressão a partir da página

Shared Components › Files and Reports › **Report Queries** › Create:

- **Report Query Name** (faz parte do request quando usada como link), **Report Layout** (pode definir depois).
- **Output Format**: Derive from Item, PDF, Word (RTF), Excel, HTML, XML (+ formatos do AOP; Document Generator: PDF, DOCX, XLSX). **View File As**: Attachment ou Inline. **Include Application and Session Information** para usar session state (valores de itens) no relatório.
- **Source**: Local Database, REST Enabled SQL, REST Source, Duality View ou JSON Source; Table ou SQL Query. **Só SQL** (Function Returning SQL não é aceito). *Add Query* acrescenta fontes. Com layout genérico e várias fontes, **só a primeira** entra no documento.
- Para Document Generator/AOP, **edite a query e defina o Data Loop Name de cada fonte**, igual às tags do documento.
- *Set Bind Values* define valores de exemplo para binds; *Download* gera o JSON de exemplo; *Test Report* manda JSON + layout ao print server.
- Fontes podem usar qualquer SQL, inclusive funções de package (ex.: formatar tempo de casa).

Na página: botão que submete, computação After Submit que grava um **application item** usado nas queries (ex.: `G_DEPTNO_FOR_REPORT`) e processo nativo **Print Report** (Report Query + Filename com substituições, ex.: `relatorio_&P35_DEPTNO..pdf`). Há também a DA **Print Report**. O processo funciona em Pre-Rendering ou em Processing; neste caso, ligue **Reload on Submit = Always** na página. A URL da query (mostrada no wizard) pode ser alvo de botões, listas e links. *Utilization* lista processos e DAs que imprimem a query.

Fonte: [Printing a Report Region by Defining a Report Query](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/printing-report-region-by-defining-report-query.html), [Defining Report Query Sources](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/defining-report-query-sources.html), [Assigning Sources a Data Loop Name](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/assigning-sources-data-loop-name.html), [Printing Report from a Page](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/printing-report-page.html), [Using SQL Features in Report Sources](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-sql-features-report-sources.html)

### PDF personalizado no download de Interactive Report e Classic Report

- **Interactive Report**: aba **Printing** do Property Editor › selecione o Report Layout. O PDF de *Actions › Download* passa a usar o layout e **respeita filtros e ordenação** atuais do usuário.
- **Classic Report**: ligue *Printing* nos atributos da região e, na aba Printing, escolha o Layout e os demais atributos (orientação, tamanho, cabeçalhos…). Esses atributos valem só para aquela região.
- Pegadinha: se o usuário **remover uma coluna** do IR, ela some do JSON enviado ao layout e as áreas que dependem dela saem em branco.
- No layout ligado a região, os nomes das tags são os nomes das colunas em minúsculas e o Data Loop Name é o definido no layout.

Fonte: [Overriding PDF Layout of Report Regions](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/overriding-pdf-layout-report-regions.html), [Downloading Customized Report PDF](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/downloading-customized-report-pdf.html), [Configuring Classic Report Printing Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/printing-report-regions.html)

### Gerar documentos por PL/SQL (APEX_PRINT.GENERATE_DOCUMENT)

Só funciona com **Oracle Document Generator Pre-built Function** configurado como print server da instância. Seis assinaturas: template num BLOB, em Report Layout (Static ID), em bucket do Object Storage etc.

```sql
declare
    l_tpl  blob;
    l_doc  blob;
    l_data json_object_t := json_object_t();
begin
    select blob_content into l_tpl
      from apex_application_temp_files where name = :P1_TEMPLATE;
    l_data.put('nome', 'Scott');
    l_doc := apex_print.generate_document(
                 p_data            => l_data.to_clob,      -- só JSON
                 p_template        => l_tpl,
                 p_template_type   => apex_print.c_template_docx,
                 p_output_type     => apex_print.c_output_pdf,
                 p_output_password => null);               -- senha só para PDF
    apex_http.download(p_blob => l_doc, p_content_type => 'application/pdf',
                       p_filename => 'documento.pdf');
end;
```

Constantes: templates `c_template_docx`, `xlsx`, `pptx`, `html`, `markdown`, `csv`, `txt`, `ods`, `odt`, `odp`, `rtf`, `xslfo`; saídas `c_output_pdf`, `docx`, `xlsx`, `pptx`, `html`, `markdown`, `csv`, `txt`, `odt`, `ods`, `odp`, `htm`, `rtf`, `xls`, `xml`. O pacote tem ainda `UPLOAD_TEMPLATE`/`REMOVE_TEMPLATE`. Para os print servers clássicos, `APEX_UTIL.GET_PRINT_DOCUMENT` (devolve BLOB) e `APEX_UTIL.DOWNLOAD_PRINT_DOCUMENT` (dispara o download) geram o documento a partir de uma Report Query e um Report Layout predefinidos, ou de dados XML com layout RTF/XSL-FO (ver doc 07).

Fonte: [GENERATE_DOCUMENT Function Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_PRINT.GENERATE_DOCUMENT-Function-Signature-1.html), [GENERATE_DOCUMENT Function Signature 5](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_PRINT.GENERATE_DOCUMENT-Function-Signature-5.html), [APEX_PRINT Constants](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_PRINT.Constants.html)

---

## 12. Geocoding

### Geocoded Address: item que converte endereço em coordenada com confirmação do usuário

O item **Geocoded Address** aparece como mapa e trabalha com um ou mais itens de texto de endereço. Ao submeter com endereço alterado, abre um diálogo com as correspondências prováveis; o valor do item vira um **ponto GeoJSON** (`{"type":"Point","coordinates":[lon,lat]}`; só a parte *geometry*, só pontos).

- Serviço: **Oracle Elocation**, chamado **pelo browser** do usuário (precisa de internet no cliente), sem setup nem custo adicional. A doc alerta que isso pode ter **consequências de proteção de dados** (o endereço sai do browser para o serviço da Oracle).
- **Structured Address = Off**: um só item (`Address Item`) com as partes separadas por vírgula; sem correção de endereço. **On**: itens para Street, House Number, Postal Code, City, City Sub Area; **Sanitize Address** devolve o endereço corrigido aos itens; resultado mais preciso. Precisa de pelo menos 1 e no máximo 8 itens de entrada.
- **Country Type**: Static ou Item; o serviço precisa do país.
- **Match Vector Item**: recebe o vetor de 17 dígitos que descreve como cada parte casou.
- **Trigger Geocoding**: *Automatic* (default; intercepta o submit), *Dynamic Action* (ação nativa **Trigger Geocoding**) ou *jQuery Selector*.
- Título do diálogo: Text Message `APEX.ITEM.GEOCODE.DIALOG_TITLE` com *Used in JavaScript*.
- **Display Map**: item que só mostra um ponto GeoJSON (Background, Zoom Level 1–18, Show Marker, Marker Color, Tooltip com template directives, Show Map Controls, Interactive Map, Height).

Fonte: [About Item Types: Geocoded Address e Display Map](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-item-types.html), [Geocoding with User Confirmation](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/geocoding-user-confirmation.html), [Identifying Address Text Fields](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/identifying-address-text-fields.html), [Confirming an Address Interactively](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/confirming-address-interactively.html)

### Geocoded Address com latitude e longitude em colunas separadas

Se a tabela guarda coordenadas em `SDO_GEOMETRY` ou GeoJSON (`VARCHAR2`/`CLOB`), o item lê e grava direto. Com duas colunas `NUMBER`:

1. Mude o Form para SQL Query e acrescente a coluna calculada (use `JSON_OBJECT`/`JSON_ARRAY`, que formatam decimais com ponto em qualquer idioma):

```sql
case when longitude is not null and latitude is not null then
     json_object('type' value 'Point',
                 'coordinates' value json_array(longitude, latitude))
end as geo_json_point
```

2. Ligue **Query Only** nessa coluna/item, senão o submit tenta atualizá-la (`ORA-01733: virtual column not allowed here`).
3. DA no evento **Result Selection [Geocoded Address]** com JavaScript: `$s('P60_LONGITUDE', this.data.longitude); apex.items.P60_LATITUDE.value = this.data.latitude;` (`this.data` traz também `matchCode`, `matchVector`, `houseNumber`, `street`, `municipality`, `region`, `country`, `postalCode` etc.).
4. Nos itens ocultos de lat/long setados por JS, **desligue Value Protected**, senão: `Session state protection violation: ... manual alteration of protected page item`.

Não monte GeoJSON com `apex_string.format('[%s,%s]', lon, lat)`: em idiomas com vírgula decimal (italiano, português) o JSON quebra; se precisar de string, use `TO_CHAR` com `'NLS_NUMERIC_CHARACTERS=.,'`.

Fonte: [Producing GeoJSON from Coordinates](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/producing-geojson-coordinates.html), [Avoiding SQL Expression Update Error](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/avoiding-sql-expression-update-error.html), [Extracting Coordinates for Storage](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/extracting-coordinates-storage.html), [Unprotecting Client-Set Hidden Items](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/unprotecting-client-set-hidden-items.html)

### Geocoding no servidor (só Autonomous Database): processo, workflow e automation

No **Autonomous Database** dá para geocodificar em background: atividade nativa de **Workflow**, processo nativo em **Execution Chain** e ação **Server-side Geocoding** em **Automations**.

- Entrada: endereço não estruturado (um item; **termine com a sigla ISO de 2 letras do país**) ou estruturado (vários itens).
- Saída: **Coordinates Item** (GeoJSON do melhor resultado) e/ou **Collection Name** (todas as correspondências).
- Itens conforme o contexto: workflow (Additional Data, parâmetros, variáveis), processo (itens de página ou de aplicação), automation (colunas da query, que podem ser atribuídas como bind, ou application items).
- **Match Mode** (Shared Components › Component Settings › Server Side Geocoding): rigor do casamento; só vale para endereço estruturado.

```sql
-- coordenadas
l_lon := json_value(:COORDINATES, '$.coordinates[0]');
l_lat := json_value(:COORDINATES, '$.coordinates[1]');
-- ou: sdo_util.from_geojson(:COORDINATES).sdo_point.x / .y

-- todas as correspondências, melhor primeiro
select c001 street, c002 house_number, c003 postalcode, c004 municipality,
       c005 settlement, c006 region, c007 country, c011 matchvector,
       n001 longitude, n002 latitude, d001 geocoding_timestamp
  from apex_collections
 where collection_name = 'GEOCODE_RESULTS'
 order by seq_id;
```

Fonte: [Geocoding in the Background](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/geocoding-background.html), [Referencing Coordinates Item Values](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/referencing-coordinates-item-values.html), [Processing Collection of Matches](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/processing-collection-matches.html), [Configuring Match Mode](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configuring-match-mode.html), [Selecting Items for Server-side Geocoding](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/selecting-items-server-side-geocoding.html)

### Técnicas de página do exemplo de geocoding (mapa, diálogo, Enter, título dinâmico)

- **Ponto do mapa abre o diálogo**: na camada do Map, Link › Target com o Link Builder (página e item de PK = coluna).
- **Refresh ao fechar o diálogo**: DA *Dialog Closed* com Selection Type = jQuery Selector `body` (pega diálogos abertos por qualquer elemento) e ação Refresh no mapa.
- **Esticar na vertical**: CSS inline `height: calc(100vh - 5rem) !important;` na classe que fixa a altura (`.a-MapRegion-container`; no Geocoded Address em diálogo, `.a-GeoCoder-map` com `100vh - 14rem`). Use `rem` para funcionar com zoom.
- **Enter não submeter**: página com um único campo de texto submete no Enter; adicione um Text Field oculto com a classe `u-hidden` (template Hidden, sem label). Para geocodificar no Enter: DA *Key Press* com condição `this.browserEvent.key === "Enter"` e ação **Trigger Geocoding** condicionada a `apex.items.P60_ADDRESS.isChanged()`.
- **Título do diálogo com contexto**: `&P60_ENAME.` no título sai vazio (o título é resolvido antes); defina no Page Load com `apex.util.getTopApex().jQuery(".ui-dialog-content").dialog("option","title", ...)`, ou com um helper `app.setDialogTitle()` num `app.js` (namespace IIFE) referenciado em User Interface › JavaScript › File URLs (`#APP_FILES#app#MIN#.js`), usando `apex.lang.formatMessage('MSG', valor)` com Text Message *Used in JavaScript*. Para não piscar um título estático, use uma substituição inexistente como `&INITIALLY_BLANK.`.

Fonte: [Exploring Additional Page Features](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/exploring-additional-page-features.html), [Refreshing Region on Dialog Close](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/refreshing-region-dialog-close.html), [Preventing Enter Key from Submitting](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/preventing-enter-key-submitting.html), [Triggering Geocoding with Enter Key](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/triggering-geocoding-enter-key.html), [Including Context Info in Dialog Title](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/including-context-info-dialog-title.html), [Using Translatable Text in JavaScript](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-translatable-text-javascript.html)

---

## 13. Recursos legados

### Legacy Web Service References e Legacy Data Loading: não usar em código novo

- **Legacy Web Services** (SOAP/WSDL e RESTful "legados", em *Managing Application Legacy Components*): ao contrário deles, a REST Data Source guarda metadados (operações, Data Profile) que componentes e `APEX_EXEC` usam diretamente. Para código novo, use REST Data Source ou `APEX_WEB_SERVICE`.
- **Legacy Data Loading**: substituída pela Data Load Definition (até 300 colunas contra 45, mapeamento em design time, XLSX/XML/JSON).
- **APEX-based RESTful Services**: dessuportados desde a 22.1 (migre para ORDS). Definir REST APIs no SQL Workshop está **deprecated na 26.1** (use SQL Developer Web).

Fonte: [Managing Legacy Web Services](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/implementing-web-services.html), [How REST Data Sources Differ from Legacy Web Service References](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-rest-data-sources.html), [Managing Applications with Legacy Data Loading Capability](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-legacy-data-loading-capability.html), [Enabling Data Exchange with RESTful Services](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/using-restful-services.html)

---

## 14. Problemas conhecidos e troubleshooting

### Credential is not allowed to be used for this URL endpoint

**Sintoma:** chamada REST (REST Data Source, `APEX_WEB_SERVICE`, print server) falha com `Credential is not allowed to be used for this URL endpoint`.
**Causa:** a URL chamada não começa com nenhuma das URLs do atributo *Valid for URLs* da Web Credential.
**Correção:** inclua o prefixo correto em *Valid for URLs* (uma URL por linha) ou corrija a URL/Remote Server.
**Prevenção:** cadastre sempre o prefixo mais específico possível do serviço; revise ao trocar a Base URL de ambiente.

Fonte: [Protecting Web Credentials by Defining Valid URLs](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-web-credentials.html)

### ORA-20999: REST Data Source returned an HTTP error: HTTP 400: Bad request

**Sintoma:** ao ordenar/filtrar um Interactive Report sobre REST Data Source (ex.: Fusion Apps), aparece `ORA-20999: REST Data Source returned an HTTP error: HTTP 400`.
**Causa:** o APEX delegou a ordenação/filtro ao servidor e a API recusou (ex.: `The attribute AssignmentMode is not sortable`).
**Correção:** ligue o debug em nível Info, abra View Debug, ache a linha `making GET request to ...` e a mensagem de erro do corpo da resposta. Desligue *Enable Users To › Sort* (ou filtro) na coluna problemática, ou use Local Post-Processing.
**Prevenção:** em fontes BOSS/SaaS, confira a anotação `Sortable` dos atributos.

Fonte: [Debugging REST API Errors](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/debugging-rest-api-errors.html), [Data Ordering](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/data-ordering.html)

### Discovery error: Oracle APEX cannot compute a data profile from the response data

**Sintoma:** no wizard de REST Data Source para Fusion Apps, Discover falha com `Discovery error: Oracle APEX cannot compute a data profile from the response data of type: application/vnd.oracle.adf.resourcecollection+json`.
**Causa:** o endpoint exige pelo menos um atributo "seletivamente obrigatório" (ex.: `OrganizationId`) para devolver dados.
**Correção:** volte ao passo Authentication › *Advanced*, crie um parâmetro URL Query String `q` = `OrganizationId='0'` e rode Discover. Depois de criar, apague o `q` fixo e, na operação GET de Fetch rows, adicione o parâmetro URL Pattern `OrganizationId_eq$norowsifnull` para ligar a um item.

Fonte: [Example: Creating a REST Data Source Against a Fusion Applications Endpoint](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/example-creating-rest-data-source-against-fusion-apps-endpoint.html)

### invalid filter em REST Data Source BOSS (additionalExternalFilter)

**Sintoma:** erro `invalid filter` em tempo de execução numa fonte BOSS.
**Causa:** o valor do parâmetro `additionalExternalFilter` não é um predicado BOSS válido ou tem parênteses desbalanceados.
**Correção:** valide a sintaxe e o balanceamento de parênteses antes de atribuir o valor.

Fonte: [Data Filtering](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/data-filtering.html)

### REST Synchronization parou de rodar depois de importar a app

**Sintoma:** após importar/atualizar a app em outro ambiente, a tabela local deixa de ser sincronizada.
**Causa:** o APEX **desabilita** as sincronizações no import, para evitar execuções duplicadas.
**Correção:** reative em Shared Components › REST Data Sources › Manage Synchronizations, ou com `apex_rest_source_sync.enable` (após `apex_session.create_session`). Confira também se o schema de parse tem `CREATE JOB`.
**Prevenção:** inclua o `enable` no script de deploy.

Fonte: [About Importing and Exporting REST Source Synchronizations](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-data-synchronization.html)

### Sincronização termina como Incomplete

**Sintoma:** log da REST Synchronization mostra status *Incomplete*.
**Causa:** o *HTTP Request Limit* do step foi excedido (a execução para uma requisição depois do limite).
**Correção:** aumente o limite, reduza o volume por step (parâmetros/filtros) ou aumente o page size da API.

Fonte: [Configuring REST Synchronization](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-data-synchronization.html)

### Form/IG sobre REST Data Source não grava ou não protege contra lost update

**Sintoma:** Form ou Interactive Grid sobre REST Data Source não salva, ou a verificação de lost update falha.
**Causa:** faltam operações com as Database Actions *Fetch single row*, *Insert row*, *Update row*, *Delete row*; a coluna PK não está marcada no Data Profile ou no item; ou há um parâmetro URL Pattern com o mesmo nome do selector da PK, sobrescrevendo o implícito. Em BOSS com `historyType='versionNumber'`, falta a coluna `APEX$ETAG` como Row Version Column.
**Correção:** complete as operações, marque a PK, remova o parâmetro duplicado; em BOSS, inclua `APEX$ETAG` e configure *Lost Update Type = Row Version Column*.

Fonte: [REST Operations and Database Actions](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/rest-operations-and-database-actions.html), [ETag Support](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/etag-support.html)

### Edição não funciona em região sobre REST Enabled SQL com MySQL

**Sintoma:** Form/IG sobre MySQL via REST Enabled SQL não permite gravar; Execute Code não lista o servidor MySQL.
**Causa:** MySQL é suportado **só para leitura** (DML automático não suportado; Execute Code não aceita MySQL).
**Correção:** grave por outro caminho (API REST do sistema de origem) ou use banco Oracle remoto.

Fonte: [About MySQL Support](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-rest-enabled-sql-service-references.html)

### Handler ORDS recebe corpo nulo na segunda leitura de :body

**Sintoma:** em um handler PL/SQL, o corpo da requisição aparece `null` em parte do código.
**Causa:** `:body`/`:body_text` só podem ser lidos **uma vez**; leituras seguintes devolvem `null`. Também não dá para usar os dois no mesmo handler.
**Correção:** copie para uma variável local no início do handler e use a variável.

Fonte: [Using Handler Bind Variables](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-handler-bind-variables.html)

### HTTP 401 Unauthorized ao chamar API ORDS protegida

**Sintoma:** chamadas que funcionavam passam a responder `401` com `{"code":"Unauthorized",...}`.
**Causa:** o bearer token expirou (ex.: 3600 s) ou o client não tem role com o privilégio do módulo.
**Correção:** peça novo token em `/ords/<alias>/oauth/token`; confira as roles do OAuth client. No APEX consumidor, use Web Credential OAuth2 Client Credentials (renova sozinha).

Fonte: [Using REST API with an OAuth Client](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-rest-api-oauth-client.html)

### ORA-42699: Cannot update JSON Relational Duality View ... ETAG did not match

**Sintoma:** update em duality view falha com `ORA-42699 ... The ETAG of document with ID '...' in the database did not match the ETAG passed in`.
**Causa:** o documento foi alterado por outro caminho depois de lido; o `_metadata.etag` enviado está velho.
**Correção:** leia a versão atual, reaplique a mudança e reenvie. Use `@nocheck` em colunas que não devem participar do ETAG.

Fonte: [Preventing Lost Updates with ETAG](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/preventing-lost-updates-etag.html)

### ORA-40937: Cannot insert into table ... Missing INSERT annotation

**Sintoma:** POST num AutoREST de duality view falha com `ORA-40937: Cannot insert into table 'STAFF' in JSON Relational Duality View ... Missing INSERT annotation`.
**Causa:** o documento referencia um registro filho inexistente (ex.: staff por nome) e a view não permite inserir naquela tabela.
**Correção:** envie um valor existente ou anote a tabela com `@insert` se a criação for desejada.

Fonte: [Exercising Duality View AutoREST Endpoint](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/exercising-duality-view-autorest-endpoint.html)

### ORA-30625 e ORA-40478 ao montar JSON em PL/SQL

**Sintoma:** `ORA-30625: method dispatch on NULL SELF argument is disallowed` ou `ORA-40478: output value too large`.
**Causa:** método chamado em variável `JSON_OBJECT_T`/`JSON_ARRAY_T` nula (30625); `stringify` com texto acima de 32767 caracteres (40478).
**Correção:** inicialize as variáveis (`json_object_t()`) e verifique nulos; use `to_clob` em vez de `stringify` para JSON grande.

Fonte: [Constructing JSON in PL/SQL](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/constructing-json-pl-sql.html), [Serializing JSON in PL/SQL](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/serializing-json-pl-sql.html)

### PDF não aparece no iframe: Refused to display ... X-Frame-Options 'deny'

**Sintoma:** o visualizador de PDF inline mostra erro; o console diz `Refused to display '...' in a frame because it set 'X-Frame-Options' to 'deny'`.
**Causa:** *Embed in Frames* da app está em **Deny** (default).
**Correção:** Shared Components › Security › Browser Security › Embed in Frames = **Allow from same origin** (só se o conteúdo vem da própria app). Use URL absoluta no `src`.

Fonte: [Allowing Embedding from Same Domain](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/allowing-embedding-same-domain.html)

### File is too large. Maximum file size is …

**Sintoma:** ao enviar um arquivo, o usuário vê `File is too large. Maximum file size is 3MB.`
**Causa:** o arquivo excede o *Maximum File Size* (em KB) do item.
**Correção:** é o comportamento esperado; ajuste o limite se fizer sentido. Para imagens, prefira *Resize To* (o Image Upload reduz no cliente).

Fonte: [Configuring File Upload to a BLOB Column](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configuring-file-upload-blob-column.html)

### Arquivo enviado não é gravado na coluna BLOB do formulário

**Sintoma:** o upload parece funcionar, mas a coluna BLOB continua vazia.
**Causa:** o item usa Storage = *Table APEX_APPLICATION_TEMP_FILES* (o arquivo vai para a tabela temporária e é apagado no purge) e não há processo copiando para a tabela; ou o processo Automatic Row Processing não aponta para o form, roda depois do Close Dialog, ou o botão não tem *Database Action*.
**Correção:** para gravar direto, use Storage = *BLOB column specified in Item Source attribute* com MIME/Filename/Last Updated; ou mantenha temp files e escreva um processo que leia `APEX_APPLICATION_TEMP_FILES` pelo nome do item e faça o UPDATE. Revise a ordem dos processos e a Database Action do botão.

Fonte: [About Item Types: File Upload](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-item-types.html), [Ensuring the Automatic DML Process](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/ensuring-automatic-dml-process.html)

### Coluna BLOB aparece como [unsupported data type] no relatório

**Sintoma:** Classic/Interactive Report mostra `[unsupported data type]`.
**Causa:** relatórios não exibem BLOB diretamente.
**Correção:** selecione `dbms_lob.getlength(col)` e mude o tipo da coluna para *Download BLOB* ou *Display Image*, preenchendo os BLOB Attributes.

Fonte: [Including a Download Link](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-blob-support-in-forms-and-reports.html)

### Session state protection violation em item oculto setado por JavaScript

**Sintoma:** ao submeter: `Session state protection violation: This may be caused by manual alteration of protected page item P60_LATITUDE.`
**Causa:** item Hidden com *Value Protected* ligado teve o valor alterado no cliente (ex.: coordenadas do geocoding).
**Correção:** desligue *Value Protected* nesses itens (avaliando o risco), ou calcule o valor no servidor.

Fonte: [Unprotecting Client-Set Hidden Items](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/unprotecting-client-set-hidden-items.html)

### ORA-01733: virtual column not allowed here ao salvar formulário

**Sintoma:** submit de form com coluna calculada (ex.: GeoJSON) falha com `ORA-01733`.
**Causa:** o DML tenta atualizar uma coluna SQL Expression.
**Correção:** ligue **Query Only** no item/coluna calculada.

Fonte: [Avoiding SQL Expression Update Error](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/avoiding-sql-expression-update-error.html)

### PDF de Interactive Report sai com áreas em branco

**Sintoma:** download PDF com layout personalizado mostra campos vazios.
**Causa:** o usuário removeu colunas do IR; elas não vão no JSON enviado ao layout.
**Correção:** oriente os usuários a manter as colunas usadas pelo layout ou trate campos ausentes no template.

Fonte: [Downloading Customized Report PDF](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/downloading-customized-report-pdf.html)

### Document Generator não aparece como print server da aplicação

**Sintoma:** no Application Definition não há opção de Document Generator; `APEX_PRINT.GENERATE_DOCUMENT` falha.
**Causa:** Document Generator só é configurado na **instância** (Administration Services), com `DBMS_CLOUD` e credencial de nuvem.
**Correção:** peça ao administrador da instância para configurar e use *Print Server Type = Use Instance Settings* na app.

Fonte: [Configuring Report Printing at the Application Level](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/printing-report-regions.html), [Configuring Report Printing for an Instance](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-report-printing-for-an-instance.html)

### Não consigo excluir Web Credential, Remote Server, REST Data Source ou REST Enabled SQL

**Sintoma:** o botão Delete recusa a exclusão.
**Causa:** o componente está referenciado por alguma app/componente.
**Correção:** veja o relatório **Utilization** do componente, remova as referências e exclua. Para credenciais, *Delete Unused* apaga as sem uso.

Fonte: [Editing or Deleting Credentials](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-or-deleting-credentials.html), [Deleting a REST Data Source](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-or-deleting-a-REST-data-source.html)

### Data Loading recusa o arquivo ou não oferece copiar e colar

**Sintoma:** o usuário não consegue subir um XLSX numa página de carga criada com CSV (ou vice-versa); não aparece opção de colar texto.
**Causa:** o formato do Data Profile (vindo do arquivo de exemplo) restringe os tipos aceitos; copy & paste só existe para profile CSV.
**Correção:** crie uma definição por formato e escolha pela extensão/MIME (ver §8), ou recrie a definição com o formato desejado.

Fonte: [Creating a Data Load Definition](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-applications-with-data-loading-capability.html)

### Import de módulo ORDS falha com "wrong type"

**Sintoma:** ao importar em SQL Workshop › RESTful Services, aparece erro de tipo de arquivo errado.
**Causa:** o arquivo é um export de APEX-based RESTful Services (formato antigo, dessuportado).
**Correção:** migre os serviços para ORDS (scripts do ORDS 21.4.2+) e exporte de novo.

Fonte: [Importing an ORDS RESTful Service Module](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/managing-restful-service-modules.html)

### Static files do workspace com problema após habilitar o schema no ORDS

**Sintoma:** arquivos estáticos do workspace passam a falhar depois de registrar o schema no ORDS.
**Causa:** o schema é o default de mais de um workspace.
**Correção/Prevenção:** não habilite no ORDS schemas compartilhados por vários workspaces (a doc liga o problema a versões do ORDS anteriores à 18.3).

Fonte: [Registering Schema with ORDS](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/accessing-restful-services.html)

### Título do modal com &ITEM. sai vazio

**Sintoma:** título do diálogo definido como `Endereço de &P60_ENAME.` aparece sem o nome.
**Causa:** o título é determinado antes de o item ser preenchido.
**Correção:** defina o título no Page Load por JavaScript (`apex.util.getTopApex().jQuery(".ui-dialog-content").dialog("option","title", ...)`).

Fonte: [Including Context Info in Dialog Title](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/including-context-info-dialog-title.html)

---

## 15. Aplicação no Corlix Hub

> Estado do projeto conforme `docs/ai-context/` (README, 02, 05, 06, 08) e os `.apx` em `corlixhub/` em 21/10/2026. Regras do projeto: toda query de negócio filtra por `id_empresa`; páginas administrativas têm `authorizationScheme` na própria página; links com `apex_page.get_url`; UI em pt-BR; Builder 26.1.5 (caminho não conferido vai marcado "(confirmar no 26.1.5)").

### Corlix Hub: o que a app usa hoje desta área

| Recurso | Onde | Situação |
|---|---|---|
| REST Data Source / Web Credential / Remote Server | — | **Nenhum** no app (`shared-components/` não tem esses componentes). |
| Chamada a API externa | p16 Cadastro de Empresas, DA `endereço-por-cep` | `fetch('https://viacep.com.br/ws/${cep}/json/')` **no browser**, sem passar pelo APEX. |
| Image Upload | `P16_LOGOTIPO_EMPRESA` (p16), `P17_IMAGEM` (p17) | p16 usa `storage { type: appTempFiles }` sobre a coluna BLOB `EMPRESA.LOGOTIPO_EMPRESA`; p17 grava na coluna `COMUNICADO.IMAGEM` com `mimeTypeColumn: MIME_TYPE` e `filenameColumn: NOME_ARQUIVO`. |
| File Upload | `P21_BL_ANEXO` (p21 Formação) | Coluna `FORMACAO_COLABORADOR.BL_ANEXO`, `mimeTypeColumn: DS_MIME_TYPE`, `filenameColumn: DS_NOME_ARQUIVO`, `fileTypes: .pdf,image/*`, `maxFileSize: 5120` (KB = 5 MB), `downloadLinkText: Baixar anexo`. |
| Imagem BLOB em Cards | p1 Home, lista de comunicados | `media { source: blobColumn, blobColumn: IMAGEM }` + `blobAttributes { mimeTypeColumn: MIME_TYPE }`. |
| Foto de colaborador | App process `APP_USER_FOTO`, organograma | Arquivo em `#APP_FILES#Fotos Colaboradores/<FOTO_URL>`; o organograma também pede `APPLICATION_PROCESS=DOWNLOAD_FOTO` com o item `ID_COLABORADOR`, que **não existem** no app (ver `ai-context/06` e `08` §2). |
| Data Load / Report Query / Report Layout / collections / ORDS | — | Não usados. |

Fonte: [About Item Types](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-item-types.html), [Understanding BLOB Support in Forms and Reports](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-blob-support-in-forms-and-reports.html)

### Corlix Hub: logotipo da empresa (p16) não é salvo em EMPRESA.LOGOTIPO_EMPRESA

O `ai-context/02` (p16) já registra o risco: o item usa `appTempFiles` e não há processo copiando o arquivo. Pela doc 26.1, com Storage = *Table APEX_APPLICATION_TEMP_FILES* o arquivo **só** vai para a tabela temporária e é apagado no purge. Duas correções possíveis:

1. **Declarativa (preferida)**: Storage › Type = *BLOB column specified in Item Source attribute* (em APEXlang, remover `type: appTempFiles`). Para o browser tratar bem o arquivo, a doc recomenda colunas de MIME type, nome e última alteração; `EMPRESA` hoje só tem `LOGOTIPO_EMPRESA` (ver `ai-context/05` §3.1). Exige DDL novo (ex.: `logotipo_mime_type`, `logotipo_nome_arquivo`, `logotipo_dt_atualizacao`) e preencher MIME Type Column, Filename Column e BLOB Last Updated Column. Combine com o time antes de alterar a tabela.
2. **Manter temp files**: processo *Execute Code* depois do *Process form* (e antes do *Close Dialog*):

```sql
update empresa e
   set e.logotipo_empresa = (select f.blob_content
                               from apex_application_temp_files f
                              where f.name = :P16_LOGOTIPO_EMPRESA)
 where e.id_empresa = :P16_ID_EMPRESA
   and :P16_LOGOTIPO_EMPRESA is not null;
```

Em ambos os casos, lembre que a p16 ainda não tem authorization própria (`ai-context/08` §3) e que os itens de endereço desabilitados não são submetidos.

Fonte: [About Item Types: Image Upload](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-item-types.html), [Configuring Upload Image Item Source](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configuring-upload-image-item-source.html), [Controlling Retention of Temporary Files](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/controlling-retention-temporary-files.html)

### Corlix Hub: anexos e imagens BLOB (p17, p21, p1) — ajustes recomendados pela doc

- **p21 `P21_BL_ANEXO`**: está alinhado com a doc (BLOB column + MIME + filename + `fileTypes` + limite em KB). Falta só a coluna de **BLOB Last Updated** (usada para cache do browser); `FORMACAO_COLABORADOR` tem colunas de auditoria (`ai-context/05` §5.4) que podem servir se representarem a alteração do arquivo. Como aceita imagem, considere `Capture Using` apenas se o RH quiser foto pelo celular (lembrando que, com ele, o celular não deixa escolher arquivo).
- **p17 `P17_IMAGEM`**: sem *Resize To*. Para capas de comunicado, `Maximum Width/Height` evita gravar fotos enormes (o redimensionamento é no cliente). Pode ganhar *Allow Cropping* com aspect ratio fixo para os cards da Home.
- **p1 Home (cards de comunicado)**: acrescentar **Last Updated Column** em *BLOB Attributes* faz o browser só recarregar a imagem quando ela muda (`COMUNICADO` não tem coluna de atualização da imagem hoje).
- **Exibir anexos em relatório** (p19 lista de formações): BLOB não aparece em IR. Use `dbms_lob.getlength(bl_anexo) as anexo` com tipo *Download BLOB* (Table `FORMACAO_COLABORADOR`, BLOB `BL_ANEXO`, PK `ID_FORMACAO`, Mime `DS_MIME_TYPE`, Filename `DS_NOME_ARQUIVO`) e mantenha o filtro por `id_empresa` na query.
- **Pré-visualizar o PDF do diploma**: template component com `iframe`, página servidora com `APEX_HTTP.DOWNLOAD(p_is_inline => true)` e **Embed in Frames = Allow from same origin**. O ID do arquivo deve ir num **item oculto com checksum** (`p_items/p_values`), não em `X01`: anexos de colaborador são dados pessoais; a página servidora precisa de authorization e de filtrar `id_empresa` (e o próprio colaborador ou `ADMIN_RH`).

Fonte: [Configuring File Upload to a BLOB Column](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configuring-file-upload-blob-column.html), [Controlling Image Upload User Experience](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/controlling-image-upload-user-experience.html), [Including a Download Link](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-blob-support-in-forms-and-reports.html), [Weighing X01 Against a Secure Page Item](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/weighing-x01-secure-page-item.html), [Previewing BLOB Column PDF Files Inline](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/previewing-blob-column-pdf-files-inline.html)

### Corlix Hub: servir a foto BLOB do colaborador (DOWNLOAD_FOTO)

O organograma espera um Application Process `DOWNLOAD_FOTO` (On Demand) e um Application Item `ID_COLABORADOR`, chamados com `apex_page.get_url(p_request => 'APPLICATION_PROCESS=DOWNLOAD_FOTO', p_items => 'ID_COLABORADOR', p_values => ...)`. `COLABORADOR` já tem `IMAGEM_PERFIL`, `MIME_TYPE`, `FILE_NAME` e `UPDATED` (`ai-context/05`). Um corpo compatível com a doc:

```sql
declare
    l_blob blob;
    l_mime varchar2(255);
begin
    select c.imagem_perfil, nvl(c.mime_type, 'image/jpeg')
      into l_blob, l_mime
      from colaborador c
     where c.id_colaborador = to_number(:ID_COLABORADOR)
       and c.id_empresa     = to_number(:G_ID_EMPRESA);   -- regra multiempresa
    apex_http.download(p_blob => l_blob, p_content_type => l_mime, p_is_inline => true);
exception
    when no_data_found then null;   -- <img onerror> volta às iniciais
end;
```

`APEX_HTTP.DOWNLOAD` limpa o buffer e para o engine sozinho. Alternativa sem processo: `apex_util.get_blob_file_src` exige um item de **formulário** sobre a coluna BLOB, o que não existe numa região Dynamic Content. A criação do item e do processo continua pendente (ver `ai-context/06`); ao criar, documente no `06`.

Fonte: [Serving Inline BLOB Images with a Page](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/serving-inline-blob-images-page.html), [APEX_HTTP.DOWNLOAD Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_HTTP.DOWNLOAD-Procedure-Signature-1.html), [GET_BLOB_FILE_SRC Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_BLOB_FILE_SRC-Function.html)

### Corlix Hub: ViaCEP no browser × REST Data Source no servidor

Hoje o CEP é consultado pelo JavaScript da p16 (funciona sem configurar nada no APEX, mas fica fora do debug e depende do browser). Se o time quiser levar para o servidor, o caminho documentado é:

1. **Remote Server** `viacep` (Server Type REST Data Source, Endpoint `https://viacep.com.br/`). Sem credencial: a API é pública.
2. **REST Data Source** Simple HTTP, Service URL Path `ws/:cep/json/` (o `:cep` vira parâmetro URL Pattern), **Pagination Type = No Pagination**, Data Profile com **Contains Single Row** (resposta é um objeto) e colunas `LOGRADOURO`, `BAIRRO`, `LOCALIDADE`, `UF`, `ERRO`.
3. Na p16, processo **Invoke API** (API Type = REST Source) ou uma DA *Execute Server-side Code* com `apex_exec.open_rest_source_query`, devolvendo os itens.
4. Requisitos a confirmar com o time: o banco (Autonomous Database na OCI, conforme `ai-context/01`) precisa permitir a saída HTTPS para o domínio; em ambiente local Docker, isso depende das ACLs de rede (confirmar).

Não há ganho de segurança (API pública), mas o servidor passa a validar o CEP e os erros aparecem no debug do APEX. Mantendo o `fetch`, continue tratando `data.erro`, e corrija o problema já registrado de itens desabilitados não submetidos (`ai-context/02`, p16).

Fonte: [Using a Simple HTTP REST Data Source](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-simple-http-rest-data-source.html), [Service URL Uses Remote Server](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/service-url-uses-remote-server.html), [Updating a REST Source Row in Code (Contains Single Row)](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/updating-rest-source-row-code.html), [Invoking a REST Operation Declaratively](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/invoking-rest-operation-declaratively.html)

### Corlix Hub: carga de dados de cadastros (departamentos, cargos, colaboradores)

`database/dados/departamento.xlsx` é o único export de dados (`ai-context/05`). Para o RH carregar planilhas pelo app:

- **Data Load Definition** por tabela (Target Type = Table, ex.: `DEPARTAMENTO`), criada com um XLSX de exemplo (então só aceita XLSX; para CSV, outra definição).
- Coluna **SQL Expression** `ID_EMPRESA` = `V('G_ID_EMPRESA')` no Data Profile: a carga fica sempre na empresa do usuário (regra multiempresa) e o usuário não escolhe a empresa no arquivo.
- *Loading Method* = **Merge** só se a PK do profile identificar a linha de forma estável; senão **Append**. Para auditoria de erros, *Log Error into Collection* ou tabela `ERR$_` com `DBMS_ERRLOG` (só com Append sem PK).
- Página gerada pelo wizard (Create Page › Data Loading) com `authorizationScheme: @admin-rh` **na página** e entrada de menu com a mesma authorization.
- Volumes grandes (centenas de milhares de linhas) não são o alvo do recurso.

Fonte: [Creating a Data Load Definition](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-applications-with-data-loading-capability.html), [Augmenting Data Load Profile Columns](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/augmenting-data-load-profile-columns.html)

### Corlix Hub: relatórios PDF (histórico de carreira, Dashboard RH)

- **Sem print server** (Native), o download PDF de IR/IG/Classic Report já funciona com layout padrão e respeita filtros do usuário; os limites são os do PDF nativo (uma quebra de página por linha, truncamento).
- **Layout próprio** (ex.: "ficha do colaborador" com dados do histórico) exige print server. O Document Generator só é configurável pelo **administrador da instância** (OCI, `DBMS_CLOUD`) e então a app usa *Use Instance Settings*. **Não está confirmado** se a instância do projeto tem print server: pergunte ao time antes de propor Report Layouts DOCX/XLSX ou `APEX_PRINT`.
- Se houver Document Generator: Report Query com fontes que filtram `id_empresa` por um application item (ex.: `G_ID_EMPRESA`) e pelo colaborador escolhido, Data Loop Names iguais às tags do DOCX, processo **Print Report** com *Reload on Submit = Always* quando estiver em Processing, e página com `authorizationScheme`.

Fonte: [Printing Report Regions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/printing-report-regions.html), [Printing Report from a Page](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/printing-report-page.html), [Configuring Report Printing for an Instance](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-report-printing-for-an-instance.html)

### Corlix Hub: expor APIs, collections e geocoding (se surgirem requisitos)

- **APIs ORDS** (integração com sistemas de RH/ponto): crie no **SQL Developer Web** (o SQL Workshop RESTful Services está deprecated no 26.1), proteja os módulos com **privilege + role + OAuth client** (`CLIENT_CRED`), um client por sistema, e reaproveite os packages de regra (`pkg_historico_carreira`, `pkg_equipe_canal`) nos handlers, para a API aplicar as mesmas validações da UI. Toda query de handler precisa filtrar `id_empresa`; como o OAuth client não tem `:APP_USER`, a empresa precisa vir de um mapeamento client → empresa definido pelo time (a doc não define isso: decisão do projeto).
- **AutoREST** de tabelas como `COLABORADOR` expõe dados pessoais e de todas as empresas: só com *Authorization Required* e alias diferente do nome da tabela; em geral, prefira handlers.
- **Collections**: úteis para o wizard da p17 (Emitir Comunicado) ou para seleção múltipla temporária (ex.: destinatários). Use view + package de API e nomes em maiúsculas.
- **Geocoding** do endereço da empresa (p16): o Geocoded Address envia o endereço do browser para o serviço Oracle Elocation (a doc alerta para proteção de dados) e precisa do país (estático `BR`). No Autonomous Database, o geocoding também pode rodar no servidor (processo/automation), devolvendo GeoJSON ou collection.

Fonte: [Securing APIs with Role-Based Access Control](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/securing-apis-role-based-access-control.html), [Enabling REST Objects](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/enabling-rest-objects-from-object-browser.html), [Tips for Maintainable Collection Use](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/tips-maintainable-collection-use.html), [Geocoding Addresses](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/geocoding-addresses.html)

### Corlix Hub: checklist ao implementar integração, upload ou relatório

1. Componentes de workspace (Web Credential, Remote Server, REST Enabled SQL) ganham **Static ID** estável e *Prompt on Install* quando a URL ou o segredo mudam por ambiente; segredos nunca vão em parâmetro estático nem no repositório (o export não leva segredos).
2. Queries de REST Data Source com Local Post-Processing, Report Queries, processos de download e Data Loads filtram `id_empresa`.
3. Páginas de upload, download, carga e impressão têm `authorizationScheme` próprio; links para páginas que servem arquivos usam `apex_page.get_url` com item protegido (não `X01`) quando o conteúdo é sensível.
4. Uploads: storage coerente com o processo (BLOB column × temp files), metadados MIME/nome/data preenchidos, limite em KB e tipos aceitos definidos.
5. Ao mudar páginas, schema ou criar componentes desta área, atualize o documento correspondente em `docs/ai-context/` (02, 03, 05 ou 06).

Fonte: [Exporting and Importing Web Credentials](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-web-credentials.html), [About Securing File Uploads](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-securing-file-uploads.html)
