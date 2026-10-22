# 05 · Segurança: autenticação, autorização, ACL e proteção da aplicação

> Base: documentação oficial Oracle APEX 26.1 (App Builder User's Guide: "Managing Application Security", "Configuring Security Attributes", "Controlling Output Escaping in Substitution Strings", "About Granted Privileges"; Developer's Companion: "Controlling Access with Users and Roles" e trechos de "Uploading, Viewing, and Downloading Files"/"Geocoding Addresses"; Administration Guide: "Configuring Security" e "Managing Workspace Account Login Controls"; API Reference: APEX_AUTHENTICATION, APEX_AUTHORIZATION, APEX_ACL, APEX_ESCAPE, APEX_CUSTOM_AUTH, APEX_JWT, APEX_PAGE.GET_URL, APEX_UTIL.PREPARE_URL; APEXlang API Reference: componentes `authentication`, `authorization`, `app`, `page`, `pageItem`). Gerado em 21/10/2026.

**Sumário**
1. Visão geral e mapa das configurações
2. Autenticação (authentication schemes, login, logout, sessão, deep linking)
3. Autorização (authorization schemes, Evaluation Point, onde aplicar, "Access denied")
4. Access Control (ACL), roles e `APEX_ACL`
5. Session State Protection, checksums e URLs
6. Gerenciamento de sessão (timeout, Rejoin Sessions, commits)
7. XSS e escaping
8. SQL injection
9. Senhas, dados sensíveis e uploads
10. Browser Security, HTTP headers e Content Security Policy
11. Database Session, Runtime API Usage e privilégios
12. Segurança da instância e do workspace (resumo)
13. APIs de segurança (mapa)
14. Divergências encontradas na documentação oficial
15. Aplicação no Corlix Hub

Convenção: nomes da interface e atributos ficam em inglês como no Builder; entre parênteses aparece o nome da propriedade APEXlang (`.apx`) quando existe. Caminhos de menu do Builder seguem a documentação 26.1; os que não foram conferidos no 26.1.5 estão marcados "(confirmar no 26.1.5)".

---

## 1. Visão geral e mapa das configurações

### Responsabilidades: administrador protege a instância, desenvolvedor protege a aplicação

A documentação divide a segurança em duas frentes. **Administradores** (de instância e de workspace) cuidam da instalação: HTTPS, controles de login, políticas de senha, isolamento de workspaces, timeouts padrão, ORDS. **Desenvolvedores** cuidam da aplicação: authentication scheme, authorization schemes nas páginas e componentes, Session State Protection, escaping de saída, itens de senha, CSP e headers. Algumas funções administrativas não existem em instâncias Oracle Cloud.

Camadas que um agente deve sempre considerar numa app real:

| Camada | Pergunta que responde | Onde se configura |
|---|---|---|
| Authentication | Quem é o usuário? (`APP_USER`) | Shared Components > Authentication Schemes; Security Attributes > Authentication |
| Authorization | O que ele pode ver/fazer? | Shared Components > Authorization Schemes; atributo *Authorization Scheme* de app, página e componentes |
| Access Control (ACL) | Quais papéis ele tem? | Shared Components > Application Access Control; `APEX_ACL` |
| Session State Protection | A URL ou o POST foram adulterados? | Shared Components > Session State Protection; *Page Access Protection* e *Session State Protection* de itens |
| Escaping | Dados viram HTML/JS executável? | *Escape special characters*, filtros `!HTML`, `APEX_ESCAPE` |
| Browser Security | O navegador pode cachear, emoldurar, carregar scripts de terceiros? | Security Attributes > Browser Security (Cache, Embed in Frames, HTTP Response Headers/CSP) |
| Dados | Cada linha só para quem pode? | Filtros nas queries, VPD (`DBMS_RLS`) |

Fonte: [Managing Application Security](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-application-security.html), [Understanding Developer Security Best Practices](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-developer-security-best-practices.html), [Understanding Administrator Security Best Practices](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-administrator-security-best-practices.html)

### Security Attributes da aplicação: seções e propriedades APEXlang

Acesso: App Builder > aplicação > *Edit Application Definition* > aba **Security**, ou Shared Components > Security > **Security Attributes**. A página tem as seções Authentication, Authorization, Session Management, Session State Protection, Browser Security, Database Session e Advanced.

| Seção (Builder) | Atributo | APEXlang (`app`) | Valores / padrão APEXlang |
|---|---|---|---|
| Authentication | Public User | `authentication.publicUser` | texto |
| Authentication | Authentication Scheme | `authentication.scheme` | referência `@...` (obrigatório) |
| Authentication | Configuration Procedure | `authentication.configProcedureName` | nome de procedure |
| Authorization | Authorization Scheme | `authorization.scheme` | referência |
| Authorization | Run on Public Pages | `authorization.runOnPublicPages` | boolean, padrão `false` |
| Authorization | Run on Background Job | `authorization.runOnBackgroundJob` | boolean, padrão `true` (quando há scheme) |
| Authorization | Source for Role or Group Schemes | `authorization.sourceForRoleOrGroupSchemes` | `accessControlUserRoleAssignments` (padrão), `authenticationScheme`, `customCode` |
| Session Management | Rejoin Sessions | `sessionManagement.rejoinSessions` | `false` (padrão), `publicSessions`, `allSessions` |
| Session Management | Session State Commits | `sessionManagement.sessionStateCommits` | `immediate`, `endOfRequest` (padrão APEXlang) |
| Session Management | Maximum Session Length / Idle Time / Timeout URLs / Warning | `maxSessionLength`, `maxSessionIdleTime`, `sessionTimeoutUrl`, `sessionIdleTimeoutUrl`, `sessionTimeoutWarning` | inteiros em segundos / URLs |
| Session Management | Deep Linking | `security.deepLinking` | `true`/`false`, padrão `false` |
| Session State Protection | Session State Protection | `sessionStateProtection.enabled` | boolean, padrão `true` |
| Session State Protection | Bookmark Hash Function | `sessionStateProtection.bookmarkHashFunction` | `sha1`, `sha2-256bit`, `sha2-384bit`, `sha2-512bit` (padrão), `md5` |
| Session State Protection | Allow URLs Created After | `sessionStateProtection.allowUrlsCreatedAfter` | datetime |
| Session State Protection | (salt oculto) | `sessionStateProtection.checksumSalt` | texto |
| Session State Protection | — | `sessionStateProtection.acceptPre202UrlChecksums` | boolean, padrão `false` |
| Browser Security | Cache | `security.browserCache` | padrão `false` |
| Browser Security | Embed in Frames | `security.embedInFrames` | `deny` (padrão), `allowSameOrigin`, `allow` |
| Browser Security | Referrer Policy | `security.referrerPolicy` | `noReferrer`, `noReferrerWhenDowngrade`, `origin`, `originWhenCrossOrigin`, `sameOrigin`, `strictOrigin` (padrão), `strictOriginWhenCrossOrigin`, `unsafeUrl` |
| Browser Security | HTML Escaping Mode | `security.htmlEscapingMode` | `basic`, `extended` (padrão) |
| Browser Security | HTTP Response Headers | `security.httpResponseHeaders` | texto multilinha, até 4000 |
| Database Session | Parsing Schema, Initialization/Cleanup PL/SQL Code | `databaseSession.parsingSchema`, `initPlsqlCode`, `cleanupPlsqlCode` | |
| Advanced | Runtime API Usage | `security.runtimeApiUsage` | lista: `modifyThisApp`, `modifyOtherApps`, `modifyWorkspaceRepository` |
| Advanced | Pass ECID | — | |

Exemplo APEXlang (bloco dentro de `app`):

````
authentication {
    scheme: @oracle-apex-accounts
}
authorization {
    scheme: @must-be-employee
    runOnPublicPages: false
}
security {
    deepLinking: true
    embedInFrames: deny
    htmlEscapingMode: extended
    httpResponseHeaders: ```
        Content-Security-Policy: default-src 'self' #APEX_CSP_NONCE#; object-src 'none'; img-src 'self' data:;
        ```
}
sessionStateProtection {
    enabled: true
    bookmarkHashFunction: sha2-512bit
}
````

Fonte: [Configuring Security Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-security-attributes.html), [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Atributos de segurança de página e de item (APEXlang)

Página (`page` > grupo `security`; não se aplica à Global Page):

| Propriedade | Valores | Padrão |
|---|---|---|
| `authorizationScheme` | referência a authorization | — |
| `authentication` | `required` (*Page Requires Authentication*), `public` (*Page Is Public*) | `required` |
| `deepLinking` | `true`/`false` (vazio = Application Default) | — |
| `pageAccessProtection` | `unrestricted`, `argumentsMustHaveChecksum`, `noArgumentsSupported`, `noUrlAccess` | `unrestricted` |
| `formAutoComplete` | `true`/`false` | `true` |
| `browserCache` | `true`/`false` (vazio = Application Default) | — |
| `sessionManagement.rejoinSessions` | `false`, `publicSessions`, `allSessions` (vazio = Application Default) | — |

Item de página (`pageItem` > `security`):

| Propriedade | Valores | Padrão |
|---|---|---|
| `authorizationScheme` | referência | — |
| `sessionStateProtection` | `unrestricted`, `checksumRequiredAppLevel`, `checksumRequiredUserLevel`, `checksumRequiredSessionLevel`, `restricted` | `unrestricted` |
| `encryptSessionState` | boolean (tipos que suportam criptografia) | `true` |
| `escapeSpecialChars` | boolean (tipos que suportam) | `true` |
| `restrictedChars` | `alphanumWithSpace`, `webSafe`, `noSpecialChar`, `noSpecialCharNoNewline`, `workspaceSchema`, `workspaceUserSchema`, `workspaceUserSchemaId` | vazio (sem restrição) |

Application item (`appItem` > `security`): `sessionStateDataType` (`varchar`/`number`), `sessionStateProtection` (padrão **`restricted`**), `escapeSpecialChars` (padrão `true`).

```
page 14 (
    ...
    security {
        authorizationScheme: @admin-rh
        pageAccessProtection: argumentsMustHaveChecksum
        formAutoComplete: false
    }
)
```

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html), [Preventing URL Tampering](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/preventing-url-tampering.html)

---

## 2. Autenticação

### Como a autenticação funciona: APP_USER, usuário público e sessão

Authentication estabelece a identidade do usuário. Depois de identificado, o engine coloca o nome em `APP_USER`, que também compõe a chave de rastreamento do session state. Formas de ler:

```sql
:APP_USER                               -- SQL e PL/SQL de página
V('APP_USER')                           -- packages e triggers
sys_context('APEX$SESSION', 'APP_USER') -- contexto de aplicação APEX$SESSION
```

O mesmo contexto `APEX$SESSION` expõe `APP_ID`, `APP_SESSION` e `APP_TENANT_ID` (útil em políticas VPD).

- **Public User** (Security Attributes): o schema usado pelo DAD. Se `APP_USER` é igual a esse valor, a sessão é "pública" (não logada). Condições prontas: `USER_IS_PUBLIC_USER` / `USER_IS_NOT_PUBLIC_USER` (em APEXlang `userIsPublicUser`, `userIsAuthenticated`). Em PL/SQL: `APEX_APPLICATION.G_PUBLIC_USER`, `apex_authentication.is_public_user`, `apex_authentication.is_authenticated`. Uso típico: mostrar botão de login para público e logout para logado.
- Na doc, o usuário não logado aparece como `nobody` em `APP_USER` (contexto de authorization rules).
- Apenas **um** authentication scheme é *Current* por vez, embora vários possam existir (troca em runtime via *Switch in Session* ou Configuration Procedure).

Fonte: [Understanding Authentication](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-authentication.html), [Configuring Security Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-security-attributes.html), [Referencing Other Context Information](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/referencing-other-context-information.html)

### Escolher o tipo de autenticação: tabela comparativa dos authentication schemes

Opções de alto nível: não exigir autenticação (todas as páginas acessíveis), usar um scheme pré-configurado da galeria, ou escrever um custom (função PL/SQL executada pelo engine antes de cada requisição; o booleano decide entre processar a página ou mostrar falha). Authentication schemes também aceitam plug-ins.

| Scheme Type (Builder) | APEXlang `type` | Quando usar | Quando evitar / observações |
|---|---|---|---|
| Oracle APEX Accounts | `oracleApexAccounts` | Controle próprio do repositório, usuário/senha suficiente, sem SSO, colocar um grupo no ar rápido | Oracle **não recomenda em produção**: credenciais podem coincidir com as do workspace; preferir IdP externo (ex.: IDCS) |
| Database Accounts | `databaseAccounts` | Uma conta de banco por usuário é viável e manutenção via `ALTER USER` serve | Não abre sessão de banco do usuário: o código roda como parsing schema |
| Social Sign-In | `socialSignIn` | App na internet, usuários de redes sociais, ou empresa padronizada em OIDC/OAuth2 (IDCS, Google, Facebook) | Qualquer um registrado no provedor entra: combine com authorization |
| SAML Sign-In | `samlSignIn` | SSO corporativo SAML | Exige DB 19c RU 19.9+ ou 23ai/26ai; configurado antes pelo Instance Admin |
| LDAP Directory | `ldapDirectory` | Validar usuário/senha num LDAP (`SIMPLE_BIND_S`) | SSL with Authentication exige wallet |
| HTTP Header Variable | `httpHeaderVariable` | SSO feito pelo web server (ex.: Oracle Access Manager) passando o usuário num header | Só é seguro se o header for garantido pelo servidor |
| Custom | `custom` | Login e sessão totalmente próprios, auditoria, limites, integração com apps não APEX, várias apps | Para várias apps, prefira plug-in de autenticação |
| No Authentication (using DAD) | `noAuth` | Adota o usuário de banco do DAD (basic auth) | Demonstrações/protótipos; manutenção de contas pesada |
| Open Door Credentials | `openDoorCredentials` | Desenvolvimento: login só pede o nome | Nunca em produção (qualquer nome entra) |
| Oracle Application Server Single Sign-On | `oracleAppServerSSO` | Legado com SDK 9iAS | Oracle recomenda SAML ou Social Sign-In |
| Builder Extension Sign-in | `internalAppExtension` | Apps de Builder Extension abertas a partir de uma sessão APEX | Só para workspaces que hospedam extensions |
| Plug-in | `plugin/<nome>` | Scheme reutilizável | — |

Fonte: [Understanding Preconfigured Authentication Schemes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/preconfigured-authentication-schemes.html), [Understanding Authentication](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-authentication.html), [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Criar, ativar (Make Current Scheme), copiar e assinar authentication schemes

1. Shared Components > Security > **Authentication Schemes** > *Create*.
2. *Based on a pre-configured scheme from the gallery* ou *As a copy of an existing authentication scheme*.
3. Informe *Name* e *Scheme Type*, preencha *Settings* e clique *Create Authentication Scheme*.
4. **Um scheme novo não fica ativo.** Abra-o e clique **Make Current Scheme**. Para ver o atual: Security Attributes > Authentication.

Copiar de outra app: Tasks > *Copy from another app*; a opção *Copy and Subscribe* cria a cópia e define a referência mestre (subscription). Na edição, região *Subscription*: *Subscribe From*, *Refresh Scheme*, *Unsubscribe*. A página de schemes tem abas de relatório *Subscription* e *History*.

Em APEXlang a assinatura fica em `subscription { master: ... }` e o scheme atual é `app.authentication.scheme`.

Fonte: [Creating an Authentication Scheme](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-an-authentication-scheme.html), [Changing the Authentication Scheme Associated with an Application](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/changing-authentication-scheme.html), [Copying or Subscribing to an Authentication Scheme](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/copying-or-subscribing-to-an-authentication-scheme.html), [Subscribing to an Authentication Scheme](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/subscribing-to-an-authentication-scheme.html), [Viewing Authentication Scheme Reports](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/viewing-authentication-scheme-reports.html)

### Oracle APEX Accounts: repositório nativo de usuários

Valida usuário e senha contra o repositório interno do workspace. É o scheme padrão de uma app nova. As contas são criadas pelo Workspace Administrator (menu de administração > *Manage Users and Groups*); cada conta tem tipo: Workspace Administrator, Developer ou usuário final (este só entra nas apps, não no App Builder).

- Os controles de login do workspace/instância (expiração, bloqueio após N falhas, vida útil da senha, política de senha) **só se aplicam a contas APEX** (§12).
- Com APEX Accounts, o tipo *Is In Group* também enxerga **grupos do workspace** atribuídos ao usuário (com *Source for Role or Group Schemes* = *Authentication Scheme*).
- Criar contas por código exige *Runtime API Usage* = *Modify Workspace Repository* (ex.: `APEX_UTIL.CREATE_USER`).
- Pegadinha: Oracle não recomenda em produção, porque as credenciais da app podem ser as mesmas do workspace.

Fonte: [Oracle APEX Accounts](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/apex-accounts.html), [Authenticating Access with APEX Accounts](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/authenticating-access-apex-accounts.html), [Configuring Security Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-security-attributes.html)

### Database Accounts: autenticar contra usuários do banco

Exige que exista um usuário (schema) desbloqueado no banco local para cada usuário final. As credenciais são validadas contra as contas do banco, mas **não** é aberta uma sessão de banco desse usuário: o código da app continua rodando como o parsing schema. Escolha quando ter uma conta de banco por pessoa é viável e a manutenção por ferramentas de banco (ex.: `ALTER USER` para trocar senha) atende. Com este scheme, *Is In Group* também considera **database roles** concedidas ao usuário.

Fonte: [Database Accounts](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/database-accounts.html), [About Authorization Scheme Types](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-authorization-scheme-types.html)

### Social Sign-In: OpenID Connect, OAuth2, Google e Facebook

Delegação a provedores que suportam OpenID Connect ou OAuth2. Pré-requisito: obter Client ID/Secret no provedor, configurar o redirect e guardar as credenciais como **Web Credential** (Workspace Utilities ou Shared Components). Boa prática: preencher *Valid for URLs* da credencial com a URL do domínio do IdP.

URL de callback a registrar no provedor (a partir da URL da app, ex. `https://www.example.com/apex/f?p=100`):

```
https://www.example.com/apex/apex_authentication.callback
https://www.example.com/apex/apex_authentication.callback2
```

Atributos (*Settings*):

| Atributo | O que faz |
|---|---|
| Credential Store | Web Credential com Client ID e Secret |
| Authentication Provider | *OpenID Connect Provider* (informe Discovery URL), *Generic OAuth2 Provider* (URLs de authorization, token e userinfo), *Google*, *Facebook* |
| Discovery URL | ex.: `https://accounts.example.com/.well-known/openid-configuration` |
| Scope | Lista separada por vírgula; para OIDC e Google o APEX adiciona `openid` automaticamente |
| Authentication URI Parameters | Parâmetros extras, ex. `prompt=consent` |
| Username | Atributo do usuário ou texto com substituições `#attr#`; `#APEX_AUTH_NAME#` = nome do scheme. Ex.: `#email# (#APEX_AUTH_NAME#)`, `#sub#` |
| Convert Username To Upper Case | Sim/Não |
| Additional User Attributes | Lista de atributos extras (dependem do Scope) |
| Map Additional User Attributes To | Lista de application items que recebem os valores, ex. `G_EMAIL,G_PROFILE,G_PICTURE` |
| Verify Attributes | Ignora atributos com `"<nome>_verified": false` (ex.: `email_verified`). Se o atributo ignorado for o Username, a autenticação falha. Impede que dados não verificados sejam usados para se passar por outro usuário |

- Os dados do usuário ficam acessíveis no **post-authentication procedure** via `APEX_JSON.GET_%` (o JSON mais recente parseado pelo `APEX_JSON`).
- Pode haver vários schemes de Social Sign-In na mesma app (ver *Switch in Session*).
- **Pegadinha:** como quem verifica a credencial é o provedor, qualquer pessoa registrada nele consegue entrar. Proteja com authorization schemes (ex.: na aplicação).

Exemplo do Developer's Companion (OCI IAM Domain): Provider *OpenID Connect Provider*, Discovery URL do domínio, Scope `profile,groups`, Username `#sub#`, upper case Yes, Additional User Attributes `groups`; no IAM, app confidencial com grant *Authorization code* e redirect para `/ords/apex_authentication.callback`.

Fonte: [Social Sign-In](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/social-sign-in.html), [Configuring Confidential App for APEX](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configuring-confidential-app-apex.html), [Defining Credential for Identity Provider](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/defining-credential-identity-provider.html), [Authenticating with an External Provider](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/authenticating-external-provider.html)

### SAML Sign-In

SAML é um protocolo XML entre *asserting party* e *relying party* que dá SSO. Requisitos: Oracle Database 19c (RU 19.9.0.0.0 ou mais nova) ou 23ai/26ai; sem isso o tipo não aparece. O **Instance Administrator configura o SAML em Administration Services** antes (Editing SAML Sign-In). Na app: *Settings* > *Use SAML Attributes of* = *Instance* e *Convert Username To Upper Case*. A API tem `APEX_AUTHENTICATION.SAML_CALLBACK` e `SAML_METADATA`.

Fonte: [SAML Sign-In](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/saml-sign-in.html), [APEX_AUTHENTICATION](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AUTHENTICATION.html)

### LDAP Directory: validar senha por SIMPLE_BIND_S

Qualquer scheme com página de login pode validar usuário/senha via LDAP. O wizard grava host, porta, DN, uso de SSL, DN exato ou não e filtro de busca.

| Atributo | Detalhe |
|---|---|
| Host / Port | Porta padrão `389` |
| Use SSL | *SSL with Authentication* exige wallet na instância com o certificado raiz do LDAP como trusted |
| Distinguished Name (DN) String | Padrão com `%LDAP_USER%`. Exato: `cn=%LDAP_USER%,l=amer,dc=yourdomain,dc=com`; não exato = search base |
| Use Distinguished Name (DN) | Exato ou não; se não exato, informe Search Filter |
| LDAP Username Edit Function | Código que transforma `:USERNAME`, ex.: `return apex_custom_auth.ldap_dnprep(p_username => :USERNAME);` |
| Username Escaping | Como escapar caracteres especiais em `%LDAP_USER%`; depende do servidor e de a edit function já escapar |

Para escapar manualmente: `APEX_ESCAPE.LDAP_DN` (RFC 4514) e `APEX_ESCAPE.LDAP_SEARCH_FILTER` (RFC 4515). `APEX_LDAP.AUTHENTICATE` existe para validação programática.

Fonte: [LDAP Directory](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/ldap-directory.html), [LDAP_DN Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/LDAP_DN-Function.html), [LDAP_SEARCH_FILTER Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/LDAP_SEARCH_FILTER-Function.html)

### HTTP Header Variable: SSO feito pelo web server (Oracle Access Manager)

O sistema central de autenticação valida o usuário e repassa o nome num header HTTP (padrão `REMOTE_USER`); o APEX cria a sessão a partir dele.

| Atributo | Opções |
|---|---|
| HTTP Header Variable Name | Padrão `REMOTE_USER` |
| Action if Username is Empty | *Redirect to Built-In URL* (`/apex/apex_authentication.callback`, que o web server deve proteger para forçar login); *Redirect to URL* (login externo que volta pela URL do placeholder `#CALLBACK#`); *Display Error* |
| Verify Username | *Each Request* (mais seguro: se o usuário do header mudar, a sessão é invalidada e novo login é iniciado; detecta logout); *After Login* (só verifica no callback) |
| Logout URL of SSO Server | ex. OAM: `/oamsso/logout.html?end_url=%POST_LOGOUT_URL%` |

Pegadinha: este scheme confia no header. Só use quando o web server garante que o cliente não consegue injetar esse header.

Fonte: [HTTP Header Variable](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/http.header-variable.html)

### Custom Authentication: quando e como

Use quando: os outros métodos não servem; você quer login e métodos próprios; quer controlar a segurança da sessão; precisa registrar/auditar atividade por usuário ou sessão; quer impor limites de atividade/expiração; precisa de redirecionamento condicional antes do processamento da página; integra com apps não APEX num framework de sessão comum; a solução tem várias apps (vários IDs) operando juntas. Se o mesmo scheme servirá várias apps, prefira um **plug-in de autenticação**.

Criação: galeria > *Scheme Type* = *Custom*, preencha os campos (ver help de cada campo). O fluxo de `APEX_AUTHENTICATION.LOGIN` mostra o papel da função de autenticação: ela recebe as credenciais (`p_username`, `p_password`) e retorna `TRUE` em caso de sucesso.

```sql
-- esboço de função de autenticação de um scheme Custom
function autenticar_usuario (
    p_username in varchar2,
    p_password in varchar2 )
    return boolean
is
begin
    return minha_pkg_usuarios.senha_confere(p_username, p_password); -- sua regra
end;
```

Fonte: [Custom Authentication](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/custom-authentication.html), [LOGIN Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/LOGIN-Procedure.html)

### Custom Authentication: proteção do gerenciamento de sessão

O APEX tenta evitar dois problemas com custom auth: (1) usuário tentando acessar session state de outra pessoa (ainda é possível digitar um session ID qualquer na URL); (2) acesso acidental a session state antigo, comum com bookmarks. O engine confere se o token de identidade definido pela função custom é igual à identidade registrada quando a sessão foi criada. Se o usuário ainda não foi autenticado e a identidade não é conhecida, a sessão não é de outra pessoa. Se o session ID da requisição não puder ser usado, o engine redireciona para a mesma página com um session ID adequado.

Fonte: [Custom Authentication](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/custom-authentication.html)

### No Authentication (using DAD) e Open Door Credentials

**No Authentication (using DAD)**: adota o usuário do banco da sessão. Combinado com um DAD configurado para basic authentication (sem conta gravada), o usuário recebe um desafio de usuário/senha por sessão de browser e o nome vai para `APP_USER`. Cada usuário precisa de conta no banco. Útil para poucos usuários e uso curto (demonstração, protótipo); desvantagem: manutenção de contas. Atributo *Settings > Username*: se vazio, usa o usuário da sessão de banco (tipicamente `APEX_PUBLIC_USER`).

**Open Door Credentials**: qualquer pessoa entra digitando só um nome numa página de login embutida. Útil apenas em desenvolvimento.

Fonte: [No Authentication (using DAD)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/no-authentication.html), [Understanding Preconfigured Authentication Schemes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/preconfigured-authentication-schemes.html)

### Builder Extension Sign-in e Oracle Application Server SSO (legado)

- **Builder Extension Sign-in**: abre uma app de Builder Extension a partir de uma sessão APEX sem pedir login de novo (verifica se há sessão APEX válida). O workspace precisa permitir hospedar extensions (*Allow Hosting Extensions*, em Edit Workspace Information).
- **Oracle Application Server Single Sign-On**: só aparece com o SDK do 9iAS SSO instalado. A app (ou o engine APEX) é registrada como *partner application*; o login acontece no SSO, que redireciona de volta com a identidade. Atributos: *Partner Application Name* (vazio se o APEX for o parceiro registrado) e *Logout URL of SSO Server* (o APEX concatena `?p_done_url=` e a URL de login). Oracle recomenda SAML ou Social Sign-In.

Fonte: [Builder Extension Sign-in](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/builder-extension-sign-in.html), [Oracle Application Server Single Sign-On Server](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/oracle-application-server-single-sign-on-server.html)

### Atributos comuns do authentication scheme: sentry, Session Not Valid, login, logout e sessão

Além dos *Settings* de cada tipo, todo authentication scheme tem "program hooks" que ajustam login, logout e compartilhamento de sessão (detalhes no help de cada campo, Shared Components > Authentication Schemes > scheme). Em APEXlang (`authentication`):

| Grupo | Propriedade | Valores / significado |
|---|---|---|
| `source` | `plsqlCode` | Bloco PL/SQL onde ficam as procedures/funções referenciadas pelos hooks |
| `sessionNotValid` | `verifyFunctionName` | Função de verificação de sessão chamada nas requisições (*Verify Function Name*) |
| `sessionNotValid` | `redirectTo` | `loginPage` (padrão), `builtInLoginPage`, `url`: para onde ir quando a sessão não é válida |
| `sessionNotValid` | `invalidSessionUrl` | URL quando `redirectTo = url` |
| `loginProcessing` | `preAuthenticationProcedureName` | Roda antes de verificar credenciais |
| `loginProcessing` | `postAuthenticationProcedureName` | Roda após sucesso (ex.: carregar grupos, tenant, itens de aplicação) |
| `loginProcessing` | `switchInSession` | boolean, padrão `false`: permite trocar para este scheme durante a sessão |
| `postLogout` | `redirectTo` / `url` | `homePage` (padrão) ou `url` |
| `sessionSharing` | `type` | `app` (padrão), `workspaceSharing`, `custom` |
| `sessionSharing` | `cookieName`, `cookiePath`, `cookieDomain`, `secure` | Cookie de sessão personalizado (`secure` padrão `false`) |
| `realAppSecurity` | `rasMode` | `disabled` (padrão), `externalUsers`, `internalUsers`; mais `dynamicRoles`, `namespaces` |
| `advanced` | `staticId` | Identificador estático |

Comportamentos documentados:
- **Sentry**: `APEX_CUSTOM_AUTH.IS_SESSION_VALID` retorna o resultado do *page sentry* do scheme atual. Em plug-ins de autenticação o callback é `sessionSentryProcedureName`.
- **Ordem do login** (`APEX_AUTHENTICATION.LOGIN`): pre-authentication → função de autenticação → se `TRUE`: post-authentication, grava usuário na sessão, redireciona para o deep link; se `FALSE`: volta para a página atual com erro em `notification_msg` → registra o resultado → redireciona.
- **Secure cookie e HTTPS**: com *Require HTTPS* = *Application specific* na instância, o HTTPS passa a depender do atributo *Secure* do cookie de sessão dos authentication schemes.
- `APEX_CUSTOM_AUTH.GET_COOKIE_PROPS` lê nome, path, domínio e flag secure do cookie da app.

```
authentication sso-corporativo (
    name: SSO Corporativo
    type: socialSignIn
    loginProcessing {
        postAuthenticationProcedureName: pkg_auth.pos_autenticacao
        switchInSession: true
    }
    postLogout {
        redirectTo: url
        url: https://login.example.com/logout
    }
    sessionSharing {
        type: app
        secure: true
    }
)
```

Fonte: [Configuring an Existing Authentication Scheme](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-an-existing-authentication-schemes.html), [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html), [IS_SESSION_VALID Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/IS_SESSION_VALID-Function.html), [LOGIN Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/LOGIN-Procedure.html), [Configuring HTTP Protocol Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-http-attributes.html)

### Post-authentication procedure: carregar grupos, tenant e dados do usuário

O post-authentication é o lugar certo para:
- Habilitar **grupos dinâmicos** com `APEX_AUTHORIZATION.ENABLE_DYNAMIC_GROUPS` (deve ser chamado durante ou logo após a autenticação).
- Definir o **tenant** com `APEX_SESSION.SET_TENANT_ID` (lido depois via `SYS_CONTEXT('APEX$SESSION','APP_TENANT_ID')`), alternativa a um application process *After Authentication*.
- Ler o JSON do IdP (Social Sign-In) com `APEX_JSON`; se o IdP exigir outra chamada para obter grupos, use `APEX_WEB_SERVICE.MAKE_REST_REQUEST` ou um REST Data Source.

Exemplo resumido do Developer's Companion (grupos `groups[].name` vindos do OCI IAM):

```sql
procedure post_authentication is
    l_auth json_object_t;
    l_arr  json_array_t;
    l_grp  apex_t_varchar2 := apex_t_varchar2();
begin
    if apex_json.g_values.count > 0 then
        apex_json.initialize_clob_output;
        apex_json.write(p_values => apex_json.g_values);
        l_auth := json_object_t(apex_json.get_clob_output);
        apex_json.free_output;
    else
        l_auth := json_object_t();
    end if;
    if l_auth.has('groups') and l_auth.get('groups').is_array then
        l_arr := l_auth.get_array('groups');
        for i in 0 .. l_arr.get_size - 1 loop
            apex_string.push(l_grp,
                treat(l_arr.get(i) as json_object_t).get_string('name'));
        end loop;
        if l_grp.count > 0 then
            apex_authorization.enable_dynamic_groups(l_grp);
        end if;
    end if;
end post_authentication;
```

Depois: Security Attributes > Authorization > *Source for Role or Group Schemes* = **Custom Code**, e nos authorization schemes *Is In Role or Group* troque o tipo de verificação para *Custom*.

Fonte: [Enabling Groups in Post-Auth Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/enabling-groups-auth-procedure.html), [Sourcing App Groups from Custom Code](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/sourcing-app-groups-custom-code.html), [Switching Authorization Rules to Custom](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/switching-authorization-rules-custom.html), [ENABLE_DYNAMIC_GROUPS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ENABLE_DYNAMIC_GROUPS-Procedure.html)

### Configuration Procedure: escolher scheme e credenciais em runtime (multi-tenant)

Security Attributes > Authentication > **Configuration Procedure**: nome de uma procedure com assinatura `(p_conf in out nocopy apex_authentication.t_configuration)`. Roda pelo menos uma vez por sessão (no primeiro request) e pode ser chamada de novo: **deve devolver os mesmos valores a cada chamada**. Com ela, o scheme não pode ser trocado pela URL (ex.: `f?p=100:1:1234:APEX_AUTHENTICATION=myauth`).

Campos opcionais de `p_conf`:
- `authentication_name`: scheme da app a usar no lugar do padrão (esse scheme precisa ter **Switch In Session** habilitado).
- `substitutions`: pares nome/valor (`apex_t_varchar2`); cada `#NOME#` nos atributos do scheme é substituído. O Social Sign-In usa `CREDENTIAL_STATIC_ID` para trocar a credencial.
- `tenant_id`: define o tenant da sessão (como `APEX_SESSION.SET_TENANT_ID`).

```sql
procedure my_auth_config (
    p_conf in out nocopy apex_authentication.t_configuration )
is
    l_host varchar2(32767) := sys.owa_util.get_cgi_env('HTTP_HOST');
begin
    for i in ( select discovery_url, auth_scheme_name, credential, tenant_id
                 from customer_tenants
                where hostname = l_host )
    loop
        p_conf.authentication_name := i.auth_scheme_name;
        p_conf.substitutions := apex_t_varchar2(
            'DISCOVERY_URL'       , i.discovery_url,
            'CREDENTIAL_STATIC_ID', i.credential );
        p_conf.tenant_id := i.tenant_id;
    end loop;
end my_auth_config;
```

Fonte: [Using a Procedure to Configure Authentication at Runtime](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-procedure-to-configure-authentication-at-runtime.html), [Making Social Sign-in the Current Scheme](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/making-social-sign-current-scheme.html)

### Página de login (alias LOGIN) e processos de login

Toda app criada ganha uma página de login com alias `LOGIN`, que pode ser a "invalid session page" do scheme. Ela tem processos que chamam a API de login (verificação de credenciais e registro de sessão). Você pode criar a sua a partir dela: *Create Page* > *Login Page*. A página de login criada pelo Builder é **pública** (*Page Is Public*); as demais devem, em regra, exigir autenticação.

APIs usadas em logins próprios:

```sql
-- processo de submit da página de login
apex_authentication.send_login_username_cookie(
    p_username => :P9999_USERNAME,
    p_consent  => :P9999_REMEMBER = 'Y' );
apex_authentication.login(
    p_username => :P9999_USERNAME,
    p_password => :P9999_PASSWORD );
-- Before Header: preencher o usuário lembrado
:P9999_USERNAME := apex_authentication.get_login_username_cookie;
```

- `LOGIN(p_username, p_password, p_uppercase_username default true, p_set_persistent_auth default false)`: fluxo completo.
- `POST_LOGIN(p_username, p_password, p_uppercase_username)`: só a parte após a verificação (credencial checada fora do APEX).
- `LOGOUT(p_session_id, p_app_id)`: fecha a sessão e vai para a home; chamada diretamente do browser.
- `APEX_CUSTOM_AUTH.LOGIN` / `POST_LOGIN` são as variantes antigas (`p_app_page => :APP_ID||':1'`; não use bind em `p_session_id`).

Fonte: [Creating a Login Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-a-login-page.html), [Requiring Authenticated Access to a Page](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/requiring-authenticated-access-page.html), [LOGIN Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/LOGIN-Procedure.html), [POST_LOGIN Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/POST_LOGIN-Procedure.html), [LOGOUT Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/LOGOUT-Procedure.html)

### Lembrar usuário (LOGIN_USERNAME_COOKIE) e Persistent Authentication

- **Cookie de usuário**: `SEND_LOGIN_USERNAME_COOKIE(p_username, p_cookie_name default 'LOGIN_USERNAME_COOKIE', p_consent default false)`. Sem consentimento, não envia e zera um cookie existente; nada é enviado se `PERSISTENT_COOKIES_ENABLED` for falso (instância com *Set Workspace Cookie* = No).
- **Persistent Authentication** ("lembrar de mim"): a instância precisa ter *Allow Persistent Authentication* = Yes e *Persistent Authentication Lifetime Days*. Então `LOGIN(..., p_set_persistent_auth => true)` grava um cookie persistente com hash (mesmo nome do cookie de sessão + `$P`), conferido com o valor no banco. `PERSISTENT_AUTH_ENABLED` informa se está ligado; `REMOVE_PERSISTENT_AUTH(p_username)` remove as entradas do usuário (ou de todos, se `NULL`) e encerra as sessões dele no workspace; `REMOVE_CURRENT_PERSISTENT_AUTH` remove a atual.

Fonte: [SEND_LOGIN_USERNAME_COOKIE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SEND_LOGIN_USERNAME_COOKIE-Procedure.html), [REMOVE_PERSISTENT_AUTH Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/REMOVE_PERSISTENT_AUTH-Procedure.html), [Configuring Service-level Security Settings](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-service-level-security-settings.html)

### Logout, Logout URL e timeouts que fazem logout

- Atributo *Post-Logout* do scheme (`postLogout.redirectTo` = `homePage` ou `url`).
- Para SSO, informe a URL de logout do servidor central (HTTP Header Variable: `%POST_LOGOUT_URL%`; Oracle AS SSO: `?p_done_url=` é concatenado). Na instância, *Single Sign-On Logout URL* (Authentication Control) também acrescenta `?p_done_url=...`.
- Em *Session Timeout URL* e *Session Idle Timeout URL*, o valor `#LOGOUT_URL#` faz o APEX executar o logout como se o usuário clicasse em sair.
- Programaticamente: `apex_authentication.logout(p_session_id => :APP_SESSION, p_app_id => :APP_ID)`.

Fonte: [HTTP Header Variable](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/http.header-variable.html), [Configuring Security Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-security-attributes.html), [Configuring Authentication Control General Settings](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-authentication-control-general-settings.html), [LOGOUT Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/LOGOUT-Procedure.html)

### Plug-ins de autenticação e callback para login externo

Um plug-in do tipo authentication define callbacks: `sessionSentryProcedureName`, `invalidSessionProcedureName`, `authenticationProcedureName`, `postLogoutProcedureName`, `ajaxProcedureName`. Para login em página externa:

- `APEX_AUTHENTICATION.GET_CALLBACK_URL(p_x01..p_x10, p_callback_name)` gera a URL de retorno (padrão `apex_authentication.callback`), que dispara o callback Ajax do plug-in.
- `APEX_AUTHENTICATION.CALLBACK` (e `CALLBACK2`) é o recurso de chegada, chamado pelo browser; parâmetros `p_session_id`, `p_app_id`, `p_page_id`, `p_ajax_identifier`, `p_x01..p_x10` (custom) e os OAuth2 (`state`, `code`, `error`...), que não devem ser usados em callbacks custom.

```sql
declare
    l_callback varchar2(4000) := apex_application.get_callback_url;
begin
    sys.owa_util.redirect_url(
        'https://single-signon.example.com/my_custom_sso.login?p_on_success='||
        sys.utl_url.escape(url => l_callback, escape_reserved_chars => true));
    apex_application.stop_apex_engine;
end;
```

Fonte: [CALLBACK Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CALLBACK-Procedure.html), [GET_CALLBACK_URL Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_CALLBACK_URL-Function.html), [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Página pública × página que exige autenticação (atributo Authentication da página)

Na página: Property Editor > Security > **Authentication**: *Page Requires Authentication* (`required`, padrão) ou *Page Is Public* (`public`). Por padrão todas as páginas exigem autenticação; a de login é pública. Uma página pública vista por usuário não logado não mostra session ID na URL. `APEX_CUSTOM_AUTH.CURRENT_PAGE_IS_PUBLIC` informa o estado em PL/SQL.

Relação com autorização de aplicação: *Run on Public Pages* decide se a authorization da app é checada também nas públicas (§3).

Fonte: [Requiring Authenticated Access to a Page](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/requiring-authenticated-access-page.html), [Hiding the Session ID on Public Pages](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/hiding-the-session-ID-on-public-pages.html), [CURRENT_PAGE_IS_PUBLIC Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CURRENT_PAGE_IS_PUBLIC-Function.html)

### Deep Linking: abrir uma página específica a partir de um link externo

Deep linking é abrir uma página "fora de contexto" (link em e-mail, notificação de workflow). Se a app exige login, o usuário vai à página de login e, após autenticar, o engine mostra a página do link original.

- **Desabilitado por padrão** (`security.deepLinking: false`). Habilite na app (Security Attributes > Session Management > Deep Linking) ou por página (Property Editor > Security > Deep Linking; vazio = padrão da app).
- *Enabled*: a URL redireciona para a página, possivelmente após login. *Disabled*: sem session ID válido, cria nova sessão e vai para a **home**.
- Quando desabilitar: navegadores restauram abas após reinício e geram deep links; isso é ruim, por exemplo, para uma página no meio de um wizard.
- Links enviados por e-mail com parâmetros precisam de checksum adequado (ver `PREPARE_URL` com `PUBLIC_BOOKMARK`, §5).

Fonte: [Understanding Authentication](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-authentication.html), [Configuring Security Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-security-attributes.html), [Enabling Deep Linking to a Specific Page](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/enabling-deep-linking-specific-page.html)

### Instância: authentication scheme do ambiente de desenvolvimento

O Instance Administrator escolhe como administradores e desenvolvedores entram no próprio APEX: Administration Services > Manage Instance > Security > Authentication Control > *Development Environment Authentication Schemes* (editar e *Make Current Scheme*). Para qualquer scheme, inclusive externos como HTTP Header Variable, todos os usuários precisam existir como developers/administradores no workspace, senão o APEX não sabe em que workspace o usuário trabalha. Alternativa por API: parâmetro `APEX_BUILDER_AUTHENTICATION` de `APEX_INSTANCE_ADMIN`. Data Reporter tem scheme próprio (SAML, Social Sign-In ou HTTP Header Variable).

Fonte: [About Configuring Authentication Schemes](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/about-configuring-authentication-schemes.html), [Configuring Authentication Control Development Environment Settings](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-authentication-development-environment-settings.html)

---

## 3. Autorização

### Como authorization schemes funcionam (e a diferença para conditions)

Authorization controla acesso a recursos conforme privilégios do usuário. Conditions controlam se algo é renderizado/processado; authorization schemes controlam **quem** acessa. Um scheme tem nome único, é definido uma vez em Shared Components e anexado a qualquer componente pelo atributo *Authorization Scheme*. Ele passa ou falha:
- Em **componente** (região, item, botão, coluna, entrada de lista...): se falhar, o componente não é mostrado (nem processado).
- Em **aplicação ou página**: se falhar, o APEX mostra a mensagem de erro definida no scheme e a página não é exibida.

Fonte: [How Authorization Schemes Work](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/how-authorization-schemes-work.html), [Providing Security Through Authorization](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/providing-security-through-authorization.html)

### Tipos de authorization scheme (Scheme Type)

| Scheme Type | APEXlang `type` | Passa quando |
|---|---|---|
| Exists SQL Query | `existsSqlQuery` | A query retorna pelo menos uma linha |
| NOT Exists SQL Query | `notExistsSqlQuery` | A query não retorna linhas |
| PL/SQL Function Returning Boolean | `plSqlFunctionBody` | O corpo retorna `TRUE` |
| Item in Expression 1 is NULL | `itemIsNull` | O item é nulo |
| Item in Expression 1 is NOT NULL | `itemIsNotNull` | O item não é nulo |
| Value of Item in Expression 1 Equals Expression 2 | `itemEqualsValue` | Valor do item = valor informado |
| Value of Item in Expression 1 Does NOT Equal Expression 2 | `itemNotEqualsValue` | Diferente |
| Value of Preference in Expression 1 Equals / Does NOT Equal Expression 2 | `preferenceEqualsValue` / `preferenceNotEqualsValue` | Preferência do usuário igual / diferente |
| Is In Role or Group (*Is In Group*) | `isInRoleOrGroup` | O papel/grupo está habilitado para a sessão |
| Is Not In Role or Group | `isNotInRoleOrGroup` | Não está |
| Plug-in | `plugin/<nome>` | Regra do plug-in |

Exemplos (Developer's Companion):

```sql
-- Exists SQL Query: "Manages Others" (o usuário é gestor de alguém)
select 1
  from eba_demo_emp
 where mgr = (select empno from eba_demo_emp where ename = :APP_USER)
fetch first row only
```

```sql
-- PL/SQL Function Returning Boolean: combina outros schemes
return    apex_authorization.is_authorized('HR Representatives Only')
       or apex_authorization.is_authorized('Manages Others');
```

Há também o scheme embutido **Must Not Be Public User** (exige login), usado, por exemplo, em entradas de menu.

Fonte: [About Authorization Scheme Types](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-authorization-scheme-types.html), [Defining Authorization Rule with SQL](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/defining-authorization-rule-sql.html), [Using PL/SQL for an Authorization Rule](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-pl-sql-authorization-rule.html), [Authorizing Menu Access](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/authorizing-menu-access.html)

### Is In Role or Group e Source for Role or Group Schemes

O tipo *Is In Role or Group* verifica papéis/grupos. O campo *Name(s)* aceita **lista separada por vírgula**: basta pertencer a um deles. O tipo de verificação (ex.: *Application Role*, ou *Custom* para grupos dinâmicos) é escolhido no scheme. A origem dos papéis é definida na aplicação (Security Attributes > Authorization > **Source for Role or Group Schemes**):

| Valor | Origem |
|---|---|
| Access Control User Role Assignments (padrão) | Papéis atribuídos em Shared Components > Application Access Control |
| Authentication Scheme | APEX Accounts: grupos do workspace do usuário; Database Accounts: database roles; com Real Application Security: RAS Dynamic Roles |
| Custom Code | Grupos dinâmicos habilitados por código no post-authentication (`ENABLE_DYNAMIC_GROUPS`) |

O scheme *Is In Group* sempre considera os grupos dinâmicos habilitados na sessão. Grupos dinâmicos da sessão podem ser lidos em `APEX_WORKSPACE_SESSION_GROUPS`.

```
authorization admin-rh (
    name: ADMIN_RH
    type: isInRoleOrGroup
    settings {
        names: Admin RH
    }
    error {
        errorMessage: Acesso restrito ao RH.
    }
    advanced {
        evaluationType: perSession
    }
)
```

Fonte: [Configuring Security Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-security-attributes.html), [Declaring Authorization Scheme Rules](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/declaring-authorization-scheme-rules.html), [About Authorization Scheme Types](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-authorization-scheme-types.html), [Referencing Other Context Information](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/referencing-other-context-information.html)

### Criar um authorization scheme: atributos

Shared Components > Security > **Authorization Schemes** > *Create* > *From Scratch* (ou cópia):

| Atributo | APEXlang | Observação |
|---|---|---|
| Name | `name` | Único; nomeie pela regra ("HR Representatives Only"). É o nome usado em `IS_AUTHORIZED` |
| Scheme Type | `type` | Ver tabela de tipos |
| Identify error message displayed when scheme violated | `error.errorMessage` | Texto mostrado quando o scheme falha em app/página |
| Validate Authorization Scheme (Evaluation Point) | `advanced.evaluationType` | `perSession`, `perPageView`, `perComponent`, `always` |
| Static ID | `advanced.staticId` | Usado por `APEX_AUTHORIZATION.HAS_ACCESS` |
| Comments | `comments` | Nunca exibido |

Fonte: [Creating an Authorization Scheme](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-an-authorization-scheme.html), [Editing an Authorization Scheme](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-authorization-scheme.html), [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Evaluation Point: Once per session, Once per page view, Once per component, Always

Authorization schemes são avaliados no primeiro uso na sessão; o *Evaluation Point* define quando reavaliar ou usar o resultado memorizado:

| Opção (Builder) | APEXlang | Comportamento | Quando usar |
|---|---|---|---|
| Once per session | `perSession` | Avalia uma vez; usa o resultado memorizado pelo resto da sessão | Regra depende só do usuário e de seus papéis. Mais eficiente |
| Once per page view | `perPageView` | Avalia uma vez por requisição; reaproveita dentro da mesma página | Regra sensível (ex.: administração) ou dependente de session state que muda |
| Once per component | `perComponent` | Avalia uma vez por componente que referencia o scheme, guardando o resultado na sessão para aquele componente | Regra depende do componente (`APP_COMPONENT_*`) |
| Always (No Caching) | `always` | Avalia sempre | Regra que muda a qualquer momento |

- A doc do App Builder diz que o **padrão** é *Once per session* e recomenda outra opção quando a verificação depende de session state ou de fatores que mudam durante a sessão. A referência APEXlang indica `perPageView` como padrão da propriedade `evaluationType` (ver §14). **Declare sempre o valor** no `.apx`.
- Consequência prática de *Once per session*: se o usuário ganha um papel durante o dia, precisa **sair e entrar de novo** (ou a app chama `APEX_AUTHORIZATION.RESET_CACHE`).
- O exemplo da Oracle usa *Once per page view* para "Administrators Only" e *Once per session* para os demais.

Fonte: [Editing an Authorization Scheme](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-authorization-scheme.html), [Declaring Authorization Scheme Rules](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/declaring-authorization-scheme-rules.html), [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Variáveis de contexto disponíveis nas regras, por Evaluation Point

Em schemes SQL/PL/SQL avaliados *Once per page view* (e também nos demais) você pode usar binds de contexto: `APP_USER` (`nobody` se não logado), `APP_ID`, `APP_ALIAS`, `APP_PAGE_ID`, `APP_PAGE_ALIAS`, `WORKSPACE_ID`.

Com *Once per component* ou *Always (No Caching)* há mais três: `APP_COMPONENT_TYPE` (view do dicionário que contém o componente), `APP_COMPONENT_NAME`, `APP_COMPONENT_ID`. Isso permite regras genéricas guiadas por dados (ex.: tabela de permissões por componente configurável por um admin). Para desempenho, considere cachear o resultado por combinação de fatores.

```sql
-- PL/SQL Function Returning Boolean, Evaluation Point = Once per component
return exists_permissao(
           p_usuario    => :APP_USER,
           p_tipo       => :APP_COMPONENT_TYPE,
           p_componente => :APP_COMPONENT_ID );
```

Fonte: [Exploring Context for Authorization Rules](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/exploring-context-authorization-rules.html)

### Onde aplicar: authorization da aplicação (Run on Public Pages, Run on Background Job)

Security Attributes > Authorization > **Authorization Scheme**: todas as páginas precisam passar. Falha em qualquer página mostra página de erro.

- **Run on Public Pages** (`runOnPublicPages`, padrão `false`): *On* = a authorization da app também é checada em páginas públicas; *Off* = ignorada nelas. Ignorado quando o scheme é *Must Not Be Public User*.
- **Run on Background Job** (`runOnBackgroundJob`): checa os schemes de aplicação, página, região e coluna em jobs de fundo (ex.: subscriptions de Interactive Report). Usa **session state clonado**, que **não** inclui collections, configurações de relatório nem session state definido no post-authentication; a verificação pode falhar se o estado não estiver no clone.

Fonte: [Attaching an Authorization Scheme to an Application, Page, or Components](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/attaching-an-authorization-scheme.html), [Configuring Security Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-security-attributes.html)

### Onde aplicar: página, região, item, coluna, botão, processo e menu

- **Página**: Page Designer > nó da página > Security > *Authorization Scheme*. É a proteção real: acesso pela URL de quem não passa mostra erro ("Access Denied by Page security check").
- **Entrada de menu (Navigation Menu)**: por padrão visível a todos, inclusive não autenticados. Use o mesmo scheme da página de destino para que o usuário não veja o que não pode abrir. Menu sozinho **não protege**: quem digita a URL ainda chega na página se ela não tiver scheme.
- **Região, item, coluna de relatório/grid**: o elemento simplesmente some (ex.: colunas `SAL`/`COMM` só para RH).
- **Botão**: o botão some. Se ele submete para um processo, aplique o mesmo scheme ao **processo** como verificação adicional.
- **Link Column de Interactive Report** (edit link): some a coluna; a página de destino também deve ter scheme.
- **Processos, validações, computations, Dynamic Actions** e demais componentes com grupo Security aceitam scheme.

Padrão recomendado pela Oracle (defesa em profundidade): menu + página + botão + processo com o mesmo scheme.

Fonte: [Authorizing Page Access](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/authorizing-page-access.html), [Authorizing Menu Access](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/authorizing-menu-access.html), [Authorizing Page Item or Column Access](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/authorizing-page-item-or-column-access.html), [Authorizing Button Access](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/authorizing-button-access.html), [Authorizing Edit Link Column Access](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/authorizing-edit-link-column-access.html), [Attaching an Authorization Scheme to an Application, Page, or Components](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/attaching-an-authorization-scheme.html)

### Usar authorization em PL/SQL: IS_AUTHORIZED, HAS_ACCESS e Read Only

- `APEX_AUTHORIZATION.IS_AUTHORIZED(p_authorization_name) return boolean`: avalia pelo **nome** do scheme, para o usuário atual; o resultado pode vir do cache (respeita o Evaluation Point).
- `APEX_AUTHORIZATION.HAS_ACCESS(p_static_id) return boolean`: o mesmo, pelo **Static ID**.
- Uso típico: condição de *Read Only* de colunas/itens:

```sql
-- Read Only > Type: PL/SQL Expression
not apex_authorization.is_authorized('HR Representatives Only')
```

Pegadinha: `IS_AUTHORIZED` usa o **nome** (`name`), não o identificador do `.apx`. Renomear o scheme quebra quem o chama por nome.

Fonte: [IS_AUTHORIZED Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/IS_AUTHORIZED-Function.html), [HAS_ACCESS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AUTHORIZATION.HAS_ACCESS-Function.html), [Driving Read-Only with Authorization Rule](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/driving-read-only-authorization-rule.html)

### Segurança por linha (row-level, VPD/DBMS_RLS) reutilizando authorization schemes

Quando cada usuário deve ver só algumas linhas, use uma política do banco: a região que lê a tabela/view protegida herda a regra automaticamente.

1. O parsing schema precisa de `EXECUTE` em `DBMS_RLS` (`grant execute on dbms_rls to <schema>`).
2. Função de política `(schema_var in varchar2, table_var in varchar2) return varchar2` que devolve o predicado: `'1=1'` (tudo), `'1=0'` (nada) ou um filtro.
3. `DBMS_RLS.ADD_POLICY` na tabela ou view.

```sql
function only_own_reports(schema_var in varchar2, table_var in varchar2)
    return varchar2
is
    l_user varchar2(255) := sys_context('APEX$SESSION','APP_USER');
begin
    if l_user is null then return '1=0'; end if;           -- fora do APEX: nada
    if apex_authorization.is_authorized('HR Representatives Only') then
        return '1=1';
    end if;
    return 'empno in (select empno from eba_demo_emp
                       start with mgr = (select empno from eba_demo_emp where ename = '''
           || replace(l_user, '''', '''''') || ''')
                       connect by prior empno = mgr)';
end;
```
```sql
begin
    dbms_rls.add_policy(
        object_schema   => sys_context('USERENV','CURRENT_USER'),
        object_name     => 'EBA_DEMO_EMP_V',
        policy_name     => 'ONLY_OWN_REPORTS_POLICY',
        function_schema => sys_context('USERENV','CURRENT_USER'),
        policy_function => 'ONLY_OWN_REPORTS',
        statement_types => 'SELECT,INSERT,UPDATE,DELETE',
        update_check    => true,
        enable          => true);
end;
```

Consulte políticas em `USER_POLICIES`. A função pode usar `APP_ID`, `APP_SESSION`, `APP_TENANT_ID` de `APEX$SESSION`, os papéis em `APEX_APPL_ACL_USER_ROLES` e os grupos dinâmicos em `APEX_WORKSPACE_SESSION_GROUPS`. O exemplo Oracle cria uma view sobre a tabela para aplicar a política só na página que precisa (a lista geral continua lendo a tabela). Nota: o exemplo original concatena o número do gestor; acima, por segurança, foi adaptado o literal com `replace` para não abrir brecha de injeção ao usar texto.

Fonte: [Enabling Row-Level Data Security](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/enabling-row-level-data-security.html), [Ensuring Execute Privilege on DBMS_RLS](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/ensuring-execute-privilege-dbms_rls.html), [Defining the Security Policy Function](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/defining-security-policy-function.html), [Adding and Enabling the Security Policy](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/adding-and-enabling-security-policy.html), [Referencing Other Context Information](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/referencing-other-context-information.html), [Switching to Data Security-Enabled View](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/switching-data-security-enabled-view.html)

### Resetar o cache de autorização (APEX_AUTHORIZATION.RESET_CACHE)

Schemes *Once per session* guardam o resultado no cache da sessão. `APEX_AUTHORIZATION.RESET_CACHE` (sem parâmetros) limpa os caches da sessão atual e força reavaliação na próxima verificação. Use depois de alterar papéis **do próprio usuário** na sessão atual (ex.: tela onde o usuário troca de empresa/perfil). Não afeta outras sessões: outros usuários continuam precisando de novo login.

Fonte: [Editing an Authorization Scheme](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-authorization-scheme.html), [RESET_CACHE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/RESET_CACHE-Procedure.html)

### Relatórios, cópia e assinatura de authorization schemes

- Shared Components > Authorization Schemes, abas: *Subscription*, *Utilization* (onde cada scheme é usado), *History*. Em Tasks: **Report Pages With Authorization Schemes** e **Report Pages Without Authorization Schemes**: use o segundo para auditar páginas desprotegidas.
- Copiar de outra app: *Copy from another app*, com *Copy and Subscribe*. Na edição, região *Subscription* (*Subscribe From*, *Refresh Scheme*, *Unsubscribe*).
- Workspace Utilities > Cross Application Reports > **Security Profiles** lista, por app, parsing schema, authorization de aplicação, authentication, schemes, páginas, itens criptografados e itens de senha em risco.

Fonte: [Viewing Authorization Reports](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/viewing-authorization-reports.html), [Copying or Subscribing to an Authorization Scheme](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/copying-or-subscribing-to-an-authorization-scheme.html), [Identifying At Risk Password Items](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/identifying-at-risk-passwords.html)

### "Access Denied by Page security check"

**Sintoma:** ao abrir uma página (pela URL ou link), aparece a página de erro com "Access Denied by Page security check" ou a mensagem definida em *Identify error message displayed when scheme violated*.

**Causa:** o authorization scheme da página (ou da aplicação) avaliou `FALSE` para o usuário atual. Variações: (a) o usuário realmente não tem o papel; (b) o papel foi dado depois do login e o scheme é *Once per session* (resultado memorizado); (c) o scheme depende de session state (item, app item) que ainda estava nulo na primeira avaliação; (d) o scheme é do tipo errado ou referencia um nome de papel inexistente; (e) a authorization da aplicação está sendo checada numa página pública (*Run on Public Pages* = On).

**Correção:**
1. Confira qual scheme está na página e na aplicação (Page Designer > Security; Security Attributes > Authorization; relatório *Utilization*).
2. Confira papéis: `select role_name from apex_appl_acl_user_roles where application_id = :app and user_name = :usuario`.
3. Peça novo login (ou chame `APEX_AUTHORIZATION.RESET_CACHE` na sessão do próprio usuário).
4. Se a regra depende de estado que muda, troque o Evaluation Point para *Once per page view*.
5. Na função de erro da app (`APEX_ERROR`), esses erros são "common runtime errors" (`p_error.is_common_runtime_error`): o exemplo oficial não os mascara, então a mensagem chega ao usuário.

**Prevenção:** aplique o mesmo scheme ao menu e à página; declare `evaluationType` explicitamente; para regras que dependem de itens definidos no login, garanta que o item é preenchido antes (ex.: processo *After Authentication*).

Fonte: [Authorizing Page Access](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/authorizing-page-access.html), [Editing an Authorization Scheme](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-authorization-scheme.html), [Example of an Error Handling Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/Example-of-an-Error-Handling-Function.html), [Declaring Authorization Scheme Rules](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/declaring-authorization-scheme-rules.html)

### Papel atribuído, mas o usuário continua sem ver a página ou o menu

**Sintoma:** o admin adicionou o papel em Application Access Control (ou por `APEX_ACL`), mas o usuário logado continua sem a entrada de menu e recebe acesso negado.

**Causa:** o scheme é *Once per session*: o resultado `FALSE` da primeira avaliação foi memorizado na sessão do usuário.

**Correção:** o usuário sai e entra de novo (um refresh não basta), ou a própria sessão chama `apex_authorization.reset_cache`.

**Prevenção:** documente o comportamento para os administradores; para schemes sensíveis, use *Once per page view*.

Fonte: [Declaring Authorization Scheme Rules](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/declaring-authorization-scheme-rules.html), [RESET_CACHE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/RESET_CACHE-Procedure.html)

### Página restrita acessível pela URL apesar do menu escondido

**Sintoma:** usuário sem papel não vê o item no menu, mas abre a página digitando a URL (ou alterando o número da página).

**Causa:** o authorization scheme foi aplicado apenas à entrada da lista (Navigation Menu), não à página.

**Correção:** defina *Authorization Scheme* na página (`page > security > authorizationScheme`). Se a página tem botões que disparam processos, coloque o scheme também nos processos.

**Prevenção:** rode periodicamente *Report Pages Without Authorization Schemes*.

Fonte: [Authorizing Page Access](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/authorizing-page-access.html), [Viewing Authorization Reports](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/viewing-authorization-reports.html)

### Authorization falha em subscription de relatório ou job de fundo

**Sintoma:** e-mails de subscription de Interactive Report não chegam ou vêm vazios; job de fundo falha na autorização.

**Causa:** com *Run on Background Job* = On, os schemes de app, página, região e coluna são verificados com **session state clonado**, que não inclui collections, report settings nem o que foi definido no post-authentication.

**Correção:** faça a regra não depender desses dados (ex.: consulte tabelas a partir de `APP_USER`) ou, se aceitável, desligue *Run on Background Job*.

Fonte: [Attaching an Authorization Scheme to an Application, Page, or Components](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/attaching-an-authorization-scheme.html)

---

## 4. Access Control (ACL), roles e APEX_ACL

### Application Access Control: roles e User Role Assignments

Shared Components > Security > **Application Access Control**:
- **Roles**: *Add Role* com *Name* (só alfanuméricos e `_`), *Static Identifier* e *Description*. Crie os papéis antes de atribuir usuários. Podem ser copiados de outra app (*Copy Role from another app*, com *Subscribe*) e assinados (*Subscribe From*, *Refresh Role*, *Unsubscribe*).
- **User Role Assignments**: *Add User Role Assignment* com *User Name* e *Application Role*; editar troca o papel; *Delete* remove.
- Views: `APEX_APPL_ACL_ROLES`, `APEX_APPL_ACL_USERS`, `APEX_APPL_ACL_USER_ROLES`.
- Os papéis valem com APEX Accounts ou com IdP externo: o modelo de papéis é o mesmo.

**Export/import:** papéis fazem parte da definição da app (exportados/importados); **atribuições de usuários não** são exportadas. Ao importar uma versão nova, as atribuições existentes no ambiente de destino permanecem. Em ambientes novos (inclusive runtime), atribua por `APEX_ACL` ou por script em Supporting Objects.

```
role admin-rh (
    name: Admin RH
    description {
        description: Equipe de RH.
    }
)
```

Fonte: [Managing Roles and User Assignments](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-roles-and-user-assignments.html), [Assigning Users to Roles](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/assigning-users-roles.html), [Controlling Access with Users and Roles](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/controlling-access-users-and-roles.html)

### Feature Access Control do Create Page Wizard (Administrator, Contributor, Reader)

*Create Page* > *Feature* > **Access Control** (ou no Create Application Wizard). Requer `CREATE TABLE`, `CREATE TRIGGER` e `CREATE SEQUENCE` no schema. Cria:
- região Access Control na página de administração escolhida (nova ou existente) e páginas a partir do *Starting Page Number*;
- papéis `Administrator`, `Contributor`, `Reader` (privilégios Administration, Edit, View);
- schemes `Administration Rights`, `Contribution Rights`, `Reader Rights` (só se o nome ainda não existir, comparação sensível a maiúsculas; senão reusa);
- build option `Feature: Access Control` e Application Setting `ACCESS_CONTROL_SCOPE`.

Schemes gerados (PL/SQL Function Returning Boolean):

```sql
-- Administration Rights
return apex_acl.has_user_role(p_application_id => :APP_ID,
                              p_user_name      => :APP_USER,
                              p_role_static_id => 'ADMINISTRATOR');
-- Reader Rights
if nvl(apex_app_setting.get_value(p_name => 'ACCESS_CONTROL_SCOPE'),'x') = 'ALL_USERS' then
    return true;   -- qualquer autenticado
else
    return apex_acl.has_user_any_roles(p_application_id => :APP_ID,
                                       p_user_name      => :APP_USER);
end if;
```

`Contribution Rights` = ADMINISTRATOR ou CONTRIBUTOR. Para páginas e componentes, a doc descreve: *Administration Rights* (só admin), *Contribution Rights* (edit + admin; View não vê), *Reader Rights* (admin, edit ou view), e os inversos *Not Administration Rights*, *Not Contribution Rights*, *Not Reader Rights* (esses perfis **não** veem o componente).

Fonte: [Creating an Access Control Using the Create Page Wizard](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-access-control-create-page-wizard.html), [Understanding Access Control](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/how-access-control-works.html), [About Controlling Access for Pages and Page Components](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-access-pages-and-components.html), [Controlling Access to Applications, Pages, and Page Components](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/controlling-access-to-applications-pages-and-page-components.html)

### Administrar o Access Control em runtime (Users e "Any authenticated user")

Na app em execução, página de Administração > região Access Control:
- **Users** (*Manage User Access*): adicionar usuário (Username, Email, Role), editar (incluindo *Account Locked*), adicionar vários de uma vez (nomes separados por vírgula, ponto e vírgula ou espaço; duplicados ignorados), excluir.
- **Access Control** > *Any authenticated user may access this application*: *Off* = só quem está na lista; *On* = autenticados fora da lista também usam a app (grava `ACCESS_CONTROL_SCOPE`).
- Após deploy de uma app com a feature, a entrada de menu da Administração não aparece até que alguém receba papel; atribua via Shared Components ou `APEX_ACL`.
- Remover a feature: use a build option (Include/Exclude); para remover de vez, exclua os componentes ligados à build option e depois a build option.

```sql
begin
    apex_acl.add_user_role(p_application_id => 255,
                           p_user_name      => 'SCOTT',
                           p_role_static_id => 'ADMINISTRATOR');
end;
```

Fonte: [Managing User Access](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-user-access.html), [Configuring Access Control](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-access-control.html), [Understanding Access Control](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/how-access-control-works.html), [About Removing an Access Control Created with a Wizard](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/removing-access-control.html)

### APEX_ACL: atribuir, remover e consultar papéis por código

Fora de um contexto APEX (SQLcl, job), defina antes o workspace com `APEX_UTIL.SET_WORKSPACE` ou `APEX_UTIL.SET_SECURITY_GROUP_ID`. Também é possível editar papéis com DML na view `APEX_APPL_ACL_USERS` (trigger `INSTEAD OF`).

| Subprograma | Uso |
|---|---|
| `ADD_USER_ROLE(p_application_id, p_user_name, p_role_id)` / `(..., p_role_static_id)` | Atribui um papel (por ID ou Static ID). `p_application_id` padrão = app atual; nomes sem distinção de maiúsculas |
| `REMOVE_USER_ROLE` (2 assinaturas) | Remove um papel |
| `REPLACE_USER_ROLES(p_application_id, p_user_name, p_role_ids apex_t_number)` (2 assinaturas) | Substitui todos os papéis |
| `REMOVE_ALL_USER_ROLES(p_application_id, p_user_name)` | Remove todos |
| `HAS_USER_ROLE(p_application_id, p_user_name default usuário atual, p_role_static_id) return boolean` | Tem o papel? |
| `HAS_USER_ANY_ROLES(p_application_id, p_user_name) return boolean` | Tem algum papel? (acesso à app) |
| `IS_ROLE_REMOVED_FROM_USER(p_application_id, p_user_name, p_role_static_id, p_role_ids) return boolean` | Impede que o usuário retire de si mesmo um papel (ex.: ADMINISTRATOR) |

```sql
-- validação: o admin não pode tirar o próprio papel ADMINISTRATOR
if :P1_USER_NAME = :APP_USER
   and apex_acl.is_role_removed_from_user(
           p_application_id => :APP_ID,
           p_user_name      => :APP_USER,
           p_role_static_id => 'ADMINISTRATOR',
           p_role_ids       => apex_string.split_numbers(
                                   case when :REQUEST = 'DELETE' then null else :P1_ROLE_IDS end, ':'))
then
    raise_application_error(-20001, 'Você não pode remover o papel de administrador de si mesmo.');
end if;
```

Fonte: [APEX_ACL](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_ACL.html), [ADD_USER_ROLE Procedure Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_USER_ROLE-Procedure-Signature2.html), [IS_ROLE_REMOVED_FROM_USER Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/IS_ROLE_REMOVED_FROM_USER-Function.html), [HAS_USER_ROLE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/HAS_USER_ROLE-Function.html)

---

## 5. Session State Protection, checksums e URLs

### Session State Protection: o que é e como funciona

Recurso embutido que impede adulteração de URLs (`f?p=` e friendly URLs), que poderia afetar lógica, session state e privacidade. Funciona em duas etapas: (1) habilitar na aplicação; (2) definir atributos de página (*Page Access Protection*) e de item (*Session State Protection*). Quando habilitado, o APEX inclui um **checksum** (`cs=`) nas URLs geradas e o confere nas requisições. Quando desabilitado, os atributos de página/item são ignorados (exceto *Restricted*) e as URLs não levam checksum.

Habilitar/desabilitar: Shared Components > Security > **Session State Protection** > *Set Protection* > *Select Action* = *Enable*/*Disable*. Desabilitar não apaga os atributos, só os ignora. Também em Security Attributes > Session State Protection. APEXlang: `app.sessionStateProtection.enabled` (padrão `true`).

Fonte: [Preventing URL Tampering](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/preventing-url-tampering.html), [Configuring Security Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-security-attributes.html)

### Page Access Protection: Unrestricted, Arguments Must Have Checksum, No Arguments, No URL Access

Page Designer > página > Security > **Page Access Protection** (`pageAccessProtection`):

| Opção | APEXlang | Efeito |
|---|---|---|
| Unrestricted | `unrestricted` (padrão APEXlang) | URL com ou sem argumentos (Request, Clear Cache, nome/valor), sem checksum |
| Arguments Must Have Checksum | `argumentsMustHaveChecksum` | Se houver Request, Clear Cache ou pares nome/valor na URL, precisa de checksum compatível com a proteção **mais rígida** dos itens passados |
| No Arguments Supported | `noArgumentsSupported` | Pode abrir pela URL, mas sem nenhum argumento |
| No URL Access | `noUrlAccess` | Não abre por URL; só como destino de branch *Branch to Page* (que não faz redirect) |

Quando usar: *Arguments Must Have Checksum* é o padrão sensato para páginas que recebem IDs (formulários de edição, modais). *No URL Access* para páginas intermediárias que só devem ser alcançadas por branch. *Unrestricted* apenas quando o cliente precisa montar a URL dinamicamente (ver diálogos).

Fonte: [Preventing URL Tampering](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/preventing-url-tampering.html), [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Session State Protection de itens: níveis de checksum (Application, User, Session) e Restricted

Item > Security > **Session State Protection** (`sessionStateProtection`):

| Opção | APEXlang | Quem pode setar o item pela URL |
|---|---|---|
| Unrestricted | `unrestricted` | Qualquer um, por URL ou form, sem checksum |
| Checksum Required - Application Level | `checksumRequiredAppLevel` | URL com checksum gerado por **qualquer usuário** da mesma app/workspace (checksum de usuário ou sessão também serve) |
| Checksum Required - User Level | `checksumRequiredUserLevel` | Checksum gerado pelo **mesmo usuário** nomeado, em qualquer sessão (de sessão também serve) |
| Checksum Required - Session Level | `checksumRequiredSessionLevel` | Checksum gerado **na sessão atual** |
| Restricted - May not be set from browser | `restricted` | Ninguém pelo browser (nem URL nem POST); só processos, computations etc. |

**Restricted** vale mesmo com Session State Protection desabilitada e se aplica a itens que não são de entrada de dados (Display Only com Save State = No, Text Field disabled sem salvar estado, Display as Text..., Stop and Start Grid Layout) e a application items. Para application items (Shared Components > Application Items > Security), o padrão APEXlang é `restricted`.

O wizard (*Set Protection* > *Configure*) aplica de uma vez valores para quatro categorias em toda a app: *Page Access Protection*, *Page Data Entry Item Protection*, *Page Display-Only Item Protection*, *Application Item Protection*. Na primeira tela do wizard há resumos: *Page Level Session State Protection Summary*, *Page Item Session State Protection Summary*, *Application Item Session State Protection*.

Fonte: [Preventing URL Tampering](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/preventing-url-tampering.html), [About Items of Type Password](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-items-of-type-password.html), [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Gerar URLs com checksum: APEX_PAGE.GET_URL e APEX_UTIL.PREPARE_URL

Com Session State Protection, URLs com parâmetros devem ser **geradas pelo APEX** (link builder de colunas/botões/branches, `APEX_PAGE.GET_URL`, `APEX_UTIL.PREPARE_URL`). Concatenar `f?p=...` à mão em SQL não produz checksum e falha em páginas com *Arguments Must Have Checksum*.

```sql
select apex_page.get_url(
           p_page   => 18,
           p_items  => 'P18_ID_COLABORADOR',
           p_values => c.id_colaborador ) as link_editar
  from colaborador c
 where c.id_empresa = :G_ID_EMPRESA;
```

- `GET_URL(p_application, p_page, p_session, p_request, p_debug, p_clear_cache, p_items, p_values, p_printer_friendly, p_trace, p_x01, p_hash, p_triggering_element default 'this', p_plain_url default false, p_absolute_url default false)`. Recomendada pela Oracle (mais legível). Sem checksum se a app de destino estiver em outro workspace. `p_triggering_element` é necessário para abrir modal dialog; `p_plain_url` omite o JS de fechar diálogo quando chamado de dentro de um modal.
- `PREPARE_URL(p_url, p_url_charset, p_checksum_type, p_triggering_element, p_plain_url)`: devolve a URL com `&cs=`. `p_checksum_type`: `PUBLIC_BOOKMARK`/`1` (qualquer usuário: links em e-mail), `PRIVATE_BOOKMARK`/`2` (mesmo usuário, fora da sessão), `SESSION`/`3` (só a sessão atual). Ao usar a URL em JavaScript, pode ser preciso escapar o `&`.

Fonte: [GET_URL Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_URL-Function.html), [PREPARE_URL Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PREPARE_URL-Function.html)

### Expire Bookmarks, Bookmark Hash Function e Allow URLs Created After

- Um **salt** oculto (`checksumSalt`) entra no cálculo dos checksums das URLs geradas.
- **Expire Bookmarks** troca o salt: bookmarks com checksums antigos deixam de funcionar. Também é o caminho para mudar a *Bookmark Hash Function*.
- **Allow URLs Created After** mostra a data/hora a partir da qual bookmarks com checksum são aceitos. Bookmarks sem checksum ou com checksum desnecessário não são afetados.
- **Bookmark Hash Function**: algoritmo dos checksums de nível aplicação e usuário. Na instância, *Checksum Hash Function* define o padrão para apps novas (*Most Secure* = SHA-2 512 no 12c+; MD5 é deprecated). Mudar a função da instância não altera apps existentes; a Oracle recomenda expirar os bookmarks e igualar a função da app à da instância.

Fonte: [Configuring Security Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-security-attributes.html), [Configuring Service-level Security Settings](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-service-level-security-settings.html)

### Hidden items com Value Protected

Itens *Hidden* têm *Settings > Value Protected*: impede que o valor seja manipulado no POST da página. Bom para IDs que o servidor definiu. Se o valor é alterado no cliente (Dynamic Action, JavaScript), desligue *Value Protected* daquele item, senão o submit falha.

Fonte: [About Item Types](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-item-types.html), [Unprotecting Client-Set Hidden Items](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/unprotecting-client-set-hidden-items.html)

### "Session state protection violation: This may be caused by manual alteration of protected page item"

**Sintoma:** ao submeter a página aparece `Session state protection violation: This may be caused by manual alteration of protected page item P60_LATITUDE.`

**Causa:** um item Hidden com *Value Protected* = On teve o valor alterado no browser (por Dynamic Action/JS legítimo ou por adulteração).

**Correção:** se a alteração no cliente é intencional, desligue *Value Protected* no item; se não é, investigue o código que muda o valor.

**Prevenção:** mantenha *Value Protected* ligado em IDs definidos pelo servidor; desligue só nos itens que o cliente precisa preencher e valide-os no servidor.

Fonte: [Unprotecting Client-Set Hidden Items](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/unprotecting-client-set-hidden-items.html)

### Link ou modal com parâmetros falha com erro de checksum

**Sintoma:** um link montado manualmente (`f?p=&APP_ID.:18:&SESSION.::NO::P18_ID:123` em SQL/HTML, ou URL alterada pelo usuário) dá erro de checksum/página de erro em vez de abrir; ou a URL copiada com outro ID é recusada.

**Causa:** a página destino usa *Arguments Must Have Checksum* (ou o item tem *Checksum Required*) e a URL não tem `cs=` válido para aqueles valores. Comportamento esperado: é exatamente o que impede trocar o ID na URL.

**Correção:** gere a URL com `APEX_PAGE.GET_URL` (ou link builder / `PREPARE_URL`). Para modais cujo parâmetro só é conhecido no cliente (sem ida ao servidor), o Developer's Companion recomenda: *Page Access Protection* = *Unrestricted* na página do diálogo e *Session State Protection* = *Unrestricted* **somente** nos itens que recebem o valor dinâmico; os demais itens mantêm checksum. Valide no servidor (authorization/filtro por dono) esses parâmetros.

**Prevenção:** nunca concatene URLs com parâmetros; para links em e-mail use `PUBLIC_BOOKMARK`.

Fonte: [Unprotecting Dynamic Client Arguments](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/unprotecting-dynamic-client-arguments.html), [Experiencing URL Checksum Protection](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/experiencing-url-checksum-protection.html), [PREPARE_URL Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PREPARE_URL-Function.html)

### Parâmetro X01 × item de página protegido (download de imagem/arquivo)

`p_x01` em `GET_URL` é prático, mas **não é protegido por checksum**: um usuário autenticado pode trocar o valor (ex.: ID de imagem) e ver arquivos de outros. Para dados sensíveis/de usuário, passe o ID num item de página (hidden) com Session State Protection e gere a URL com `p_items`/`p_values`; cada URL ganha um `cs` diferente e a adulteração gera página de erro.

Fonte: [Weighing X01 Against a Secure Page Item](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/weighing-x01-secure-page-item.html), [Experiencing URL Checksum Protection](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/experiencing-url-checksum-protection.html)

### Page and Application Checksums (Utilities) não são checksums de URL

App Builder > Utilities > *Application Checksum* / *Page Checksum*: identificadores que permitem comparar se a mesma app ou página está implantada em workspaces diferentes. Nada a ver com Session State Protection.

Fonte: [Viewing Page and Application Checksums](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/viewing-page-and-app-checksums.html)

---

## 6. Gerenciamento de sessão: timeout, Rejoin Sessions e commits

### Session Management: duração máxima, ociosidade e aviso de timeout

Usuários deixam o navegador aberto; o timeout reduz a exposição. Configurável por aplicação (Security Attributes > Session Management), workspace e instância; o mais específico prevalece (app > workspace > instância).

| Atributo | Comportamento |
|---|---|
| Maximum Session Length in Seconds | Inteiro positivo; `0` = indefinido; vazio = herda workspace/instância. Padrão da instância: 8 h (28800) |
| Session Timeout URL | Destino ao exceder a duração. Deve ser página pública. Sem valor: mensagem "Your session has timed out" com link para a home. `#LOGOUT_URL#` faz logout. Só `&APP_SESSION.`, `&SESSION.` e `&APP_ID.` são substituídos |
| Maximum Session Idle Time in Seconds | Tempo entre requisições; vazio = herda. Padrão da instância: 1 h (3600) |
| Session Idle Timeout URL | Igual à anterior, para ociosidade |
| Session Timeout Warning in Seconds | Antecedência do aviso; `0` desliga; vazio = herda. Padrão da instância: 5 min (300). No aviso de ociosidade o usuário pode estender a sessão; no de duração, é avisado para salvar |

Fonte: [Configuring Security Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-security-attributes.html), [Managing Instance Security](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/manging-instance-security.html), [Configuring Session Timeout for an Instance](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuiring-session-timeout.html)

### Rejoin Sessions: URLs sem session ID e seus riscos

Com Rejoin Sessions, se a URL não tem session ID, o APEX tenta reaproveitar a sessão pelo cookie. Níveis: instância, aplicação, página; **o nível mais restritivo da instância prevalece** e, para usar na app/página, a instância precisa permitir.

| Valor | Efeito |
|---|---|
| Disabled (`false`) | Sem session ID, cria sessão nova |
| Enabled for Public Sessions (`publicSessions`) | Em páginas públicas sem session ID, usa o cookie; só junta se a sessão ainda não está autenticada |
| Enabled for All Sessions (`allSessions`) | Junta se: SSP habilitado e a URL tem checksum válido (para bookmarks públicos, a proteção mais restritiva dos itens deve ser Unrestricted ou Checksum Required - Application Level); **ou** a URL não tem payload (request, clear cache, pares nome/valor). Exige *Embed in Frames* = *Allow from same origin* ou *Deny* |
| Application Default (página) | Herda da app |

Riscos documentados: um link malicioso clicado pelo usuário pode alterar session state ou dados (por isso o checksum em requisições que alteram dados); com duas apps abertas na mesma instância, uma (maliciosa ou com XSS) pode, via Ajax, simular ações na outra. **Oracle recomenda desabilitar** Rejoin Sessions a menos que haja isolamento de workspace por *Allow Hostnames*.

Bookmarks: antes usava-se session ID `0` em páginas públicas; ainda é suportado, mas Rejoin Sessions é o mecanismo atual. Para esconder o session ID em páginas públicas: app com *Enabled for Public Sessions* + página *Page Is Public*.

Fonte: [Managing Instance Security](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/manging-instance-security.html), [Configuring Security Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-security-attributes.html), [Editing Page Attributes in Page Designer](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-page-attributes-in-page-designer.html), [About Enabling Support for Bookmarks](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-enabling-support-for-bookmarks.html), [Hiding the Session ID on Public Pages](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/hiding-the-session-ID-on-public-pages.html), [Configuring Service-level Security Settings](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-service-level-security-settings.html)

### Session State Commits: Immediate × End Of Request

Session state vive em variáveis globais PL/SQL e em tabelas. *Session State Commits* define quando as mudanças são gravadas:
- **Immediate**: grava e faz commit assim que o estado muda (ex.: um processo altera um bind). **Isso faz commit da transação principal**, incluindo alterações em tabelas da app.
- **End Of Request**: acumula e aplica no fim da requisição; melhor controle transacional e suporte a Application Continuity. Padrão APEXlang.

Abrange itens e atributos da sessão (ex.: idle timeout); collections não são afetadas.

Fonte: [Configuring Security Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-security-attributes.html)

---

## 7. XSS e escaping

### Cross-Site Scripting (XSS) no APEX: onde o risco aparece

XSS: o atacante faz um script ser enviado à app e executado no navegador de outro usuário, podendo roubar dados e credenciais de sessão. Em APEX, código malicioso pode ser renderizado em regiões HTML e outras áreas. O engine escapa caracteres em vários casos, mas o desenvolvedor decide quando **não** escapar e responde por isso.

Áreas estáticas onde se referencia session state com `&ITEM.` e `#ABC#`: regiões HTML, cabeçalhos/rodapés de página e região, títulos, labels de botão, help, labels e post-element text, templates, textos de radiogroup, mensagens de sucesso/erro, navigation bar, substitution strings da app, labels/legendas de chart, breadcrumbs, listas, textos de calendário.

Fonte: [Understanding Cross-Site Scripting Protection](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/cross-site-scripting-protection.html)

### Escaping inteligente de &ITEM. e itens "safe"

Ao referenciar `&ITEM.` em área estática:
- **Não** escapa `<`, `>`, `&`, `"` se o item é *Display Only* com *Format* = HTML, ou se o tipo expõe *Escape special characters* e ele está *No*. Application items também são tratados como "safe".
- Escapa se o item tem outro tipo de exibição (ex.: Display Only com Save Session State = No).

Regra que torna isso seguro: valores enviados a itens "safe" pela URL (`f?p`) são **escapados ao entrar** no session state; e itens safe não podem ser postados no submit. Valores definidos por computations, processes, source, default não são escapados (o desenvolvedor controla o conteúdo). Assim é possível guardar `<b>ABABABAB</b>` num item safe e emiti-lo como HTML.

Fonte: [Understanding Cross-Site Scripting Protection](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/cross-site-scripting-protection.html)

### Filtros de escape em substituições: !HTML, !ATTR, !JS, !RAW, !STRIPHTML

Acrescente `!` + filtro a item de página/app, coluna de relatório ou outra substitution string:

| Filtro | Contexto | Exemplos |
|---|---|---|
| `HTML` | Texto HTML | `&P1_DEPTNO!HTML.`, `&ENAME!HTML.` (IG), `#ENAME!HTML#` |
| `ATTR` | Valor de atributo HTML | `&ENAME!ATTR.`, `#ENAME!ATTR#` |
| `JS` | String JavaScript (não suportado em substituições feitas no cliente) | `&P1_DEPTNO!JS.`, `#ENAME!JS#` |
| `RAW` | Sem escape (use só para conteúdo confiável) | `&P1_DEPTNO!RAW.` |
| `STRIPHTML` | Remove tags e escapa o resto | `#ENAME!STRIPHTML#` |

Equivalentes PL/SQL: `APEX_ESCAPE.HTML`, `HTML_ATTRIBUTE`, `JS_LITERAL`, `STRIPHTML`.

Fonte: [Controlling Output Escaping in Substitution Strings](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/controlling-output-escaping-in-substitution-strings.html), [About Using Escaping Syntax in Substitution Strings](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-escaping-syntax-in-substitution-strings.html)

### Relatórios: Escape special characters e HTML Expression

O corpo dos relatórios é escapado. Referências a session state em cabeçalhos e mensagens seguem o escaping inteligente. Cada coluna tem *Security > Escape special characters* (`escapeSpecialChars`): **mantenha On**.

Para mostrar HTML (destaque, links, ícones) **não** concatene HTML na query (isso obriga a desligar o escape). Use o atributo **HTML Expression** da coluna, com HTML estático e `#COLUNA#` escapadas pelo filtro certo:

```sql
select empno, ename, null delete_link from emp
```
```html
<!-- HTML Expression da coluna DELETE_LINK -->
<a href="javascript:if (confirm('Deseja excluir #ENAME!JS#?')) doSubmit('DELETE-#EMPNO#');">Excluir</a>
```

Com `#ENAME#` em vez de `#ENAME!JS#`, um nome como `O'Neill` quebraria o JavaScript e abriria brecha de XSS.

Fonte: [Understanding Cross-Site Scripting Protection](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/cross-site-scripting-protection.html)

### Form items: Escape special characters e Restricted Characters

- Itens de formulário (inclusive hidden) têm o valor escapado ao renderizar, salvo exceções dos tipos safe.
- Tipos que expõem *Security > Escape special characters*: **sempre On**. Se desligar para exibir HTML guardado no item ou nas entradas de uma LOV, garanta que a entrada do usuário seja escapada ao entrar e antes de salvar.
- *Security > Restricted Characters* limita o que pode ir para o session state (erro se violar):
  - All characters can be saved (sem restrição)
  - Allowlist for a-Z, 0-9 and space
  - Blocklist HTML command characters (`<>"`)
  - Blocklist `&<>"/;,*|=%` and `--`
  - Blocklist `&<>"/;,*|=%` or `--` and new line

  Em APEXlang (`restrictedChars`) os valores são `alphanumWithSpace`, `webSafe`, `noSpecialChar`, `noSpecialCharNoNewline` (mais `workspaceSchema`, `workspaceUserSchema`, `workspaceUserSchemaId`, não descritos no capítulo de segurança). A correspondência nome a nome não está explícita na doc; pelo nome, `alphanumWithSpace` = allowlist, `webSafe` = blocklist HTML, `noSpecialChar`/`noSpecialCharNoNewline` = as duas blocklists maiores (confirmar no 26.1.5).

Fonte: [Understanding Cross-Site Scripting Protection](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/cross-site-scripting-protection.html), [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Saída dinâmica (htp.p em PL/SQL Dynamic Content): sempre escapar

Valores de session state emitidos com `htp.p` ou similares devem ser escapados explicitamente. Regra: **nunca emita um item lido do session state sem escapar, a menos que seja de tipo safe**. Mesmo itens invisíveis podem receber valores maliciosos postados por um atacante.

```sql
-- errado
htp.p(v('SOME_ITEM'));
-- certo
htp.p(apex_escape.html(:SOME_ITEM));
-- atributo HTML, texto, texto truncado
sys.htp.p('<li><span class="'||apex_escape.html_attribute(l.cls)||'">'
          ||apex_escape.html(l.titulo)||'</span>'||apex_escape.html_trunc(l.corpo)||'</li>');
-- intenção explícita de não escapar
sys.htp.p(apex_escape.noop('Cats & Dogs'));
```

Fonte: [Understanding Cross-Site Scripting Protection](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/cross-site-scripting-protection.html), [HTML_ATTRIBUTE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/HTML_ATTRIBUTE-Function.html), [NOOP Function Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/NOOP-Function-Signature-1.html)

### HTML Escaping Mode: Basic × Extended

Security Attributes > Browser Security > **HTML Escaping Mode** (`htmlEscapingMode`, padrão `extended`):
- **Basic**: escapa `&`, `"`, `<`, `>` (como `sys.htf.escape_sc`).
- **Extended**: escapa também `'` (`&#x27;`), `/` (`&#x2F;`) e caracteres não ASCII se o charset do banco não for `AL32UTF8`.

Afeta `APEX_ESCAPE.HTML` e afins; pode ser trocado em runtime por `APEX_ESCAPE.SET_HTML_ESCAPING_MODE('B'|'E')`. Prefira Extended.

Fonte: [Configuring Security Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-security-attributes.html), [HTML Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/HTML-Function.html), [SET_HTML_ESCAPING_MODE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_HTML_ESCAPING_MODE-Procedure.html)

### APEX_ESCAPE: qual função usar em cada contexto

| Contexto de saída | Função |
|---|---|
| Texto HTML | `HTML(p_string)`, `HTML_CLOB`; truncado: `HTML_TRUNC(p_string, p_length default 4000)` |
| HTML simples permitido (rich text vindo do usuário) | `HTML_ALLOWLIST(p_html, p_allowlist_tags default c_html_allowlist_tags)` (padrão: h1–h4, p, b, strong, i, ul, ol, li, br, hr); `HTML_ALLOWLIST_CLOB` |
| Atributo HTML | `HTML_ATTRIBUTE` / `_CLOB`. A doc recomenda `APEX_PLUGIN_UTIL.GET_HTML_ATTR` para atributos e alerta para não usar `HTML_ATTRIBUTE` em `aria-label`, `alt`, `summary`, `title`, `placeholder` (expõe código HTML a usuários/leitores de tela) |
| String JavaScript | `JS_LITERAL(p_string, p_quote default '''')` / `_CLOB` (com `p_quote => null` não envolve em aspas) |
| JSON | `JSON` / `JSON_CLOB` |
| Seletor CSS/jQuery | `CSS_SELECTOR` |
| Expressão regular | `REGEXP` |
| LDAP | `LDAP_DN`, `LDAP_SEARCH_FILTER` |
| CSV | `CSV` (2 assinaturas), `SET_CSV_PARAMETERS`, `GET_CSV_ENCLOSED_BY`, `GET_CSV_SEPARATED_BY` |
| Remover tags | `STRIPHTML` (2 assinaturas) |
| Não escapar de propósito | `NOOP` (2 assinaturas) |
| Modo | `SET_HTML_ESCAPING_MODE` |

```sql
-- JS inline seguro
sys.htp.p('<script>alert('||apex_escape.js_literal(l_nome)||');</script>');
-- seletor jQuery seguro
apex_javascript.add_onload_code(
  '$("#'||apex_escape.js_literal(apex_escape.css_selector(l_id), null)||'").hide();');
```

Fonte: [APEX_ESCAPE](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_ESCAPE.html), [HTML_ALLOWLIST Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/HTML_ALLOWLIST-Function.html), [JS_LITERAL Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/JS_LITERAL-Function.html), [CSS_SELECTOR Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CSS_SELECTOR-Function.html), [APEX_ESCAPE Constants](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_ESCAPE-Constants.html)

### Conteúdo HTML aparece como texto escapado (ou XSS ao desligar o escape)

**Sintoma:** uma coluna mostra `&lt;span ...&gt;` em vez do HTML; o desenvolvedor desliga *Escape special characters* e a coluna passa a renderizar qualquer HTML vindo dos dados.

**Causa:** HTML foi concatenado na query; com escape ligado ele aparece literal; desligado, dados do usuário viram HTML executável (XSS).

**Correção:** mova o HTML para a **HTML Expression** da coluna (ou template), com `#COL!HTML#`/`#COL!ATTR#`/`#COL!JS#`; se precisar montar na query, escape cada valor de dado com `apex_escape.html(...)` antes de concatenar e só então desligue o escape da coluna.

**Prevenção:** revise toda coluna/item com `escapeSpecialChars: false`.

Fonte: [Understanding Cross-Site Scripting Protection](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/cross-site-scripting-protection.html)

---

## 8. SQL injection

### Substituição &ITEM. em SQL e PL/SQL causa SQL injection: use bind variables

Formas de referenciar itens:

| Contexto | Sintaxe | Observação |
|---|---|---|
| SQL e PL/SQL de página | `:MY_ITEM` | Bind variable (itens até 30 bytes). **Use esta** |
| PL/SQL em packages/procedures | `V('MY_ITEM')`, `NV('MY_NUMERIC_ITEM')` | Evite dentro de SQL (desempenho) |
| Texto estático | `&MY_ITEM.` | Substituição exata. **Evite em SQL/PL/SQL: pode gerar SQL injection** |

Em SQL dinâmico (`execute immediate`, `APEX_EXEC`, regiões *Function Body returning SQL Query*), passe valores como binds, nunca concatenando valores digitados. `APEX_ESCAPE.NOOP` existe para silenciar detectores automáticos de injeção quando a não-escapada é intencional (análogo a `dbms_assert.noop`).

Fonte: [Understanding Page Items](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-page-items.html), [NOOP Function Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/NOOP-Function-Signature-1.html)

---

## 9. Senhas, dados sensíveis e uploads

### Itens do tipo Password: atributos recomendados

- *Session State > Storage* = **Per Request (Memory Only)**: o valor não vai para o banco; preferível para valores muito sensíveis.
- Se usar *Per Session (Persistent)*, ligue **Store value encrypted in session state**.
- *Settings > Submit when Enter pressed*; *Template Options > Hide Password Visibility* (desativa o botão "mostrar senha"); *Validation > Value Required*; *Security > Authorization Scheme* e *Session State Protection*.
- Em páginas com senha, ponha *Form Auto Complete* = Off (`formAutoComplete: false`).

Fonte: [About Items of Type Password](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-items-of-type-password.html), [Identifying At Risk Password Items](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/identifying-at-risk-passwords.html)

### Session state criptografado e boas práticas de session state

- O session state fica em tabelas no servidor (mais seguro que no cliente). Desenvolvedores e administradores do workspace conseguem ver o session state das apps do workspace.
- Limpe valores desnecessários com processos de clear cache ou com o Clear Cache das URLs.
- Para dado sensível que precisa persistir na sessão, ligue **Store value encrypted in session state** (`encryptSessionState`); a leitura decifra automaticamente. Objetivo: impedir leitura por outros devs/DBAs nas tabelas de sessão, debug ou datafiles. Limite: **4000 bytes** (acima disso dá erro). Faça backups criptografados.

Fonte: [About Session State and Security](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-session-state-and-security.html)

### Relatórios Security Profiles e Password Items (itens de senha "At Risk")

Workspace Utilities > Cross Application Reports:
- **Security Profiles**: por app, parsing schema, authorization da app, authentication, schemes, páginas, itens criptografados, itens de senha em risco.
- **Password Items**: todos os itens de senha, se criptografam e se salvam estado. Os que não fazem nenhum dos dois aparecem como **At Risk**.

Fonte: [Identifying At Risk Password Items](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/identifying-at-risk-passwords.html)

### Uploads de arquivos seguros

A tabela comum de arquivos (`APEX_APPLICATION_FILES`) nem sempre exige autenticação para acesso programático, então outros podem ver arquivos. Recomendação: gravar uploads direto numa tabela do schema da app (BLOB em forms/reports), ou em `APEX_APPLICATION_TEMP_FILES` se precisar de acesso programático. Usando os métodos embutidos, as authorizations da página valem também para o acesso ao arquivo; tabela própria dá controle de storage (TRUNCATE, mover LOB). `APEX_APPLICATION_FILES` aceita INSERT/UPDATE/DELETE; `APEX_APPLICATION_TEMP_FILES`, DELETE. A instância controla upload por não autenticados (*Allow Public File Upload*).

Fonte: [About Securing File Uploads](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-securing-file-uploads.html), [Configuring Service-level Security Settings](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-service-level-security-settings.html)

---

## 10. Browser Security, HTTP headers e Content Security Policy

### Browser Security: Cache e Embed in Frames (clickjacking)

- **Cache** (`browserCache`, padrão desabilitado; também por página): habilitado, o navegador guarda as páginas em memória/disco e o "voltar" pode mostrar a cópia. Desabilitado, o APEX envia `cache-control: no-store`. **Oracle recomenda desabilitado**: evita ver conteúdo de sessão anterior após logout e problemas com partial page refresh (ex.: Interactive Reports).
- **Embed in Frames** (`embedInFrames`): *Deny* (padrão; nunca em frame), *Allow from same origin*, *Allow* (qualquer frame). Frames permitem **clickjacking** (camadas que desviam cliques/teclas). Rejoin Sessions *Enabled for All Sessions* exige Deny ou Same origin. O APEX implementa via `X-Frame-Options`.
- **Referrer Policy** (`referrerPolicy`, padrão APEXlang `strictOrigin`).

Fonte: [Configuring Security Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-security-attributes.html), [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### HTTP Response Headers (aplicação e instância)

*Browser Security > HTTP Response Headers*: headers extras enviados em cada resposta, para o que o APEX não suporta de outro jeito (ex.: não use para `X-Frame-Options`, que é *Embed in Frames*). Um por linha. Exemplos da doc: `X-XSS-Protection: 1; mode=block`, `X-Content-Type-Options: nosniff`, e os headers de CSP. A instância também tem *HTTP Response Headers* (Manage Instance > Security > HTTP Protocol) aplicados a todas as apps. Suporte varia entre navegadores.

Fonte: [Configuring Security Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-security-attributes.html), [Configuring HTTP Protocol Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-http-attributes.html)

### Content Security Policy (CSP): conceitos, violações e nonce

CSP é um padrão web em que headers de resposta dizem ao navegador de onde pode carregar/executar recursos; o resto é bloqueado. Ajuda contra XSS e injeção de dados. O APEX avança para conformidade eliminando a necessidade de `'unsafe-inline'` (nonce em `<script>`/`<style>` e menos JS/CSS inline), mas **nem todos os componentes são compatíveis** ainda (legados podem quebrar).

Violações típicas de `'unsafe-inline'`:
1. `<script>` inline sem nonce válido;
2. atributo `style="..."` em elementos;
3. `<style>` inline sem nonce;
4. atributos de evento (`onclick`, `onmouseover`...);
5. recurso externo de origem não listada (ex.: `<script src="https://cdn.example.com/...">` sem esse host em `script-src`).

**Nonce**: valor criptográfico gerado por requisição, colocado no header; só scripts/estilos inline com esse nonce executam. As violações aparecem no console do navegador.

```html
<script nonce="random12345">console.log('executa');</script>
<script>console.log('bloqueado');</script>
```

Fonte: [Understanding Content Security Policy (CSP)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-content-security-policy-csp.html)

### Habilitar CSP na aplicação: Content-Security-Policy, Report-Only e substitution strings

Security Attributes > Browser Security > **HTTP Response Headers**:

```
Content-Security-Policy: default-src 'self' #APEX_CSP_NONCE#; object-src 'none'; img-src 'self' data:;
```

Para testar sem bloquear, use primeiro:

```
Content-Security-Policy-Report-Only: default-src 'self' #APEX_CSP_NONCE#; object-src 'none'; img-src 'self' data:;
```

Diretivas do exemplo: `default-src 'self'` (tudo só da mesma origem), `#APEX_CSP_NONCE#` (nonce da requisição), `object-src 'none'` (proíbe `<object>`, `<embed>`, `<applet>`), `img-src 'self' data:` (imagens da origem e `data:`). O header vale para a app toda.

Substitution strings:

| String | Resolve para |
|---|---|
| `#APEX_CSP_NONCE#` | No header: `'nonce-<valor>'` da requisição |
| `#APEX_CSP_NONCE_ATTRIBUTE#` | Atributo HTML `nonce="<valor>"` |
| `#APEX_CSP_NONCE_VALUE#` | Só o valor |
| `#APEX_CSP_DISPLAY_NONE#` | `display: none` (esconder antes do carregamento sem style inline) |

```html
<script #APEX_CSP_NONCE_ATTRIBUTE#>
  /* script inline permitido pela CSP */
</script>
```

Boas práticas: evitar scripts e estilos inline (usar arquivos estáticos), usar as substitution strings quando inline for inevitável, testar no DevTools e iterar (Report-Only antes de impor).

Fonte: [Using Content Security Policy (CSP) in APEX](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-csp-in-apex.html), [Understanding the CSP Header](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-the-csp-header.html), [Best Practices for CSP Compliant Development](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/best-practices-for-csp-compliant-development.html)

### Depois de ativar CSP, scripts, estilos ou plug-ins param de funcionar

**Sintoma:** com `Content-Security-Policy` ativo, Dynamic Actions de JS inline, botões com `onclick`, `style=""` em HTML de regiões, CDNs ou plug-ins deixam de funcionar; o console mostra "Refused to execute inline script/apply inline style".

**Causa:** o recurso não atende à política (sem nonce, inline, origem não permitida); alguns componentes APEX/plug-ins ainda não são compatíveis.

**Correção:** volte para `Content-Security-Policy-Report-Only` enquanto ajusta; mova JS/CSS para static files; troque `onclick` por Dynamic Actions/listeners; use `#APEX_CSP_NONCE_ATTRIBUTE#` em `<script>`/`<style>` inevitáveis; acrescente hosts confiáveis às diretivas.

**Prevenção:** teste cada página no console antes de impor; prefira classes CSS a `style` inline.

Fonte: [About Content Security Policy (CSP) Headers](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-csp-in-apex.html), [Best Practices for CSP Compliant Development](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/best-practices-for-csp-compliant-development.html)

---

## 11. Database Session, Runtime API Usage e privilégios

### Database Session: parsing schema, Initialization e Cleanup PL/SQL

- **Parsing Schema**: schema em que todo SQL/PL/SQL da app é analisado; referenciável como `#OWNER#`.
- **Initialization PL/SQL Code**: roda bem cedo em cada requisição (show/accept), logo após `APP_USER` ser definido; serve para preparar contexto (ex.: VPD). Pode ler `APP_USER` e itens que já estavam no session state antes da requisição.
- **Cleanup PL/SQL Code**: roda no fim; libera recursos (contextos VPD, database links).

Fonte: [Configuring Security Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-security-attributes.html)

### Runtime API Usage: permitir que a app altere apps e o repositório do workspace

Controla se a app pode, em execução, chamar APIs que modificam apps e dados do workspace:
- **Modify This Application** (`modifyThisApp`): ex. `APEX_APPLICATION_ADMIN` mudar status de build option da própria app.
- **Modify Other Applications** (`modifyOtherApps`): o mesmo em outras apps do workspace.
- **Modify Workspace Repository** (`modifyWorkspaceRepository`): alterar usuários e grupos do workspace, ex. `APEX_UTIL.CREATE_USER`.

Princípio do menor privilégio: habilite só o necessário e proteja com authorization as páginas que usam essas APIs.

Fonte: [Configuring Security Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-security-attributes.html)

### Privilégios do schema do workspace e objetos públicos do APEX (About Granted Privileges)

Ao criar workspace sobre schema existente, nenhum privilégio é concedido. Para criar objetos típicos, a Oracle recomenda grants diretos: `CREATE SESSION`, `CREATE CLUSTER`, `CREATE DIMENSION`, `CREATE INDEXTYPE`, `CREATE JOB`, `CREATE MATERIALIZED VIEW`, `CREATE OPERATOR`, `CREATE PROCEDURE`, `CREATE SEQUENCE`, `CREATE SNAPSHOT`, `CREATE SYNONYM`, `CREATE TABLE`, `CREATE TRIGGER`, `CREATE TYPE`, `CREATE VIEW`. Recursos específicos pedem mais (ex.: `EXECUTE` em `DBMS_RLS` para VPD; Access Control wizard exige `CREATE TABLE/TRIGGER/SEQUENCE`).

O schema do produto (ex.: `APEX_260100`) concede a `PUBLIC` (com sinônimos públicos) pacotes (`HTMLDB_UTIL`, `WWV_FLOW_*`...), procedures (`F`, `P`, `Z`, `APEX`...), funções `V` e `NV`, views `APEX_*` de dicionário (inclusive `APEX_APPL_ACL_*`, `APEX_APPLICATION_AUTHORIZATION`, `APEX_WORKSPACE_ACCESS_LOG`), sequências e tipos. **Não crie objetos com esses nomes** nos schemas dos workspaces, para não conflitar com o engine.

Fonte: [About Granted Privileges](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-granted-privileges.html)

---

## 12. Segurança da instância e do workspace (resumo)

### Administradores, runtime environment e ORDS

- **Workspace administrators** gerenciam contas, atividade e logs do workspace; **Instance administrators** gerenciam a instância inteira em Administration Services (não existe em Database Cloud Service (Database Schema)).
- Produção sensível: prefira **instalação runtime** (sem App Builder/SQL Workshop; menos objetos e privilégios). Indisponível em instâncias Oracle Cloud. Alternativa: *Disable Workspace Login* (efeito de runtime-only).
- ORDS: configure `security.requestValidationFunction` = `ords_util.authorize_plsql_gateway` para permitir só as procedures da allowlist do APEX.
- Workspaces: mapeamento workspace × schemas, papéis (admin, developer, end user), bloqueio de contas e disponibilidade de componentes (App Builder, SQL Workshop, edição de PL/SQL, Team Development).

Fonte: [About Oracle APEX Administrator Roles](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/administrator-roles.html), [About the Advantages of the Oracle APEX Runtime Environment](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/advantages-of-runtime-environment.html), [Web Server Security Considerations](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/web-server-security-considerations.html), [Understanding Workspace Management](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-workspace-management.html)

### Controles de login: expiração, bloqueio de conta (lockout) e falhas de login

Só para contas criadas no gerenciamento de usuários do APEX (APEX Accounts).

- **Instância** (Manage Instance > Security > Authentication Control):
  - *General Settings*: *Delay after failed login attempts in Seconds* (contagem regressiva; `0` desliga), *Method for computing the Delay* (baseado no Login Access Log), *Inbound Proxy Servers* (para calcular o IP real via `X-Forwarded-For`), *Single Sign-On Logout URL*.
  - *Development Environment Settings*: *Username Validation Expression* (regex; `*` desliga), *Require User Account Expiration and Locking* (Yes impõe a todos os workspaces), *Maximum Login Failures Allowed* (padrão 4, para devs/admins; default do workspace), *Account Password Lifetime (days)* (padrão 45, para devs/admins; default do workspace).
- **Workspace** (Administration > Manage Service > Set Workspace Preferences > Account Login Control): *Account Expiration and Locking* (Enable/Disable; com Enable as senhas expiram, a conta trava após N falhas e pode expirar após o primeiro uso), *Maximum Login Failures Allowed* e *End User Account Lifetime (days)* para usuários finais (vazio = valor da instância).

Fonte: [About Authentication Controls](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/about-authentication-controls.html), [Configuring Authentication Control General Settings](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-authentication-control-general-settings.html), [Configuring Authentication Control Development Environment Settings](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-authentication-development-environment-settings.html), [Configuring Workspace Preferences](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-workspace-preferences.html)

### Políticas de senha fortes e histórico de senhas

Manage Instance > Security > Password Policy (vale para admins, devs e usuários finais de todos os workspaces): *Password Hash Function*, *Minimum Password Length*, *Minimum Password Differences*, exigir alfabético/numérico/pontuação/maiúscula/minúscula, *Must Not Contain Username*, *Must Not Contain Workspace Name*, *Must Not Contain* (palavras separadas por `:`), conjuntos de caracteres alfabéticos e de pontuação. *Service Administrator Password Policy*: usar a do workspace ou a política forte padrão (≥ 6 caracteres, minúscula, maiúscula, dígito e pontuação, sem o username, sem "Internal", sem as palavras proibidas).

Histórico: como `SYS`, `ALTER SESSION SET CURRENT_SCHEMA = APEX_260100;` e `APEX_INSTANCE_ADMIN.SET_PARAMETER('PASSWORD_HISTORY_DAYS', 365)` (0 desliga). `APEX_ADMINISTRATOR_ROLE` deve ser concedido diretamente. Validação em código: `APEX_UTIL.STRONG_PASSWORD_CHECK` / `STRONG_PASSWORD_VALIDATION`.

Fonte: [Creating Strong Password Policies](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/creating-strong-password-policies.html), [Managing Instance Security](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/manging-instance-security.html)

### HTTPS: Require HTTPS, Require Outbound HTTPS e HSTS

Oracle recomenda rodar apps com SSL/HTTPS. Manage Instance > Security > HTTP Protocol:
- **Require HTTPS**: *Always* (todas as apps, inclusive Builder/Admin; aparece *Strict-Transport-Security Max Age*), *Development and Administration* (só apps internas), *Application specific* (depende do atributo *Secure* do cookie dos authentication schemes).
- **Require Outbound HTTPS**: todo tráfego de saída via HTTPS.
- Habilite HTTPS no web server antes: *Require HTTPS* torna o APEX inacessível por HTTP. Reverter: `APEX_INSTANCE_ADMIN.SET_PARAMETER('REQUIRE_HTTPS','N')` / `('REQUIRE_OUT_HTTPS','N')` com schema `APEX_260100`.
- Chamar URLs HTTPS (web services, regiões URL, SMTP com SSL/TLS, LDAP com SSL) exige **wallet** configurada na instância (exceto Autonomous Database, que já acessa a internet sem configurar network services).

Fonte: [Configuring HTTP Protocol Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-http-attributes.html), [Managing Instance Security](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/manging-instance-security.html), [Configuring Instance Settings](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-instance-settings.html), [Enabling Network Services in Oracle Database](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/enabling-network-services.html)

### Service-level security settings da instância (cookies, logins, uploads, IP, erros)

Manage Instance > Security > Security:

| Atributo | Efeito |
|---|---|
| Set Workspace Cookie | Permite cookies persistentes (`ORA_WWV_REMEMBER_UN`, `LOGIN_USERNAME_COOKIE`, `ORA_WWV_REMEMBER_LANG`) |
| Allow Persistent Authentication / Lifetime Days | Habilita "lembrar login" (API `APEX_AUTHENTICATION`) |
| Disable Administrator Login | Bloqueia Administration Services (reabrir: `SET_PARAMETER('DISABLE_ADMIN_LOGIN','N')`) |
| Disable Workspace Login | Efeito runtime-only (devs não alteram apps) |
| Disable Apps Login | *Yes*, *Only for Specific Apps* (lista de IDs) ou *No* |
| Allow Public File Upload | Upload por não autenticados |
| AI Enabled | Liga/desliga serviços de IA |
| Restrict Access by IP Address | Lista de IPs (com `*`) para Builder e Admin |
| Instance Proxy / No Proxy Domains | Proxy de saída (prevalece sobre o da app) |
| Allow DBMS Credentials Usage | Credenciais de banco em todos os workspaces |
| Checksum Hash Function | Algoritmo de checksums (padrão de Bookmark Hash Function) |
| Rejoin Sessions | Limite superior para apps e páginas |
| Unhandled Errors | *Show Error Page* (padrão) ou *Return HTTP 400* (não expõe detalhes) |

Fonte: [Configuring Service-level Security Settings](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-service-level-security-settings.html)

### Isolamento de workspaces (Allow Hostnames) contra ataques de navegador

A única forma real de isolar workspaces no navegador é usar **domínios diferentes** (*Allow Hostnames*, na instância ou por workspace): a same-origin policy separa as apps. Ex.: workspace HR acessível só por `hr.example.com`. Com RESTful services é preciso também um pool em `url-mapping.xml` do ORDS. A mesma tela tem limites de recursos (requisições concorrentes por workspace/sessão, tamanho de arquivos, e-mails, web service requests, jobs de background). Desnecessário se você confia em todas as apps do host.

Fonte: [Isolating a Workspace to Prevent Browser Attacks](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/isolating-workspace-to-prevent-browser-attacks.html), [Isolating All Workspaces in an Instance](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/isolating-workspaces-in-an-instance.html), [Managing Instance Security](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/manging-instance-security.html)

### REST, Authorized URLs, Real Application Security e outros controles

- **Allow RESTful Access**: se devs podem expor regiões de relatório como REST. **Enable RESTful Services** (workspace: Set Workspace Preferences > SQL Workshop; instância: Feature Configuration > REST): criar/editar serviços REST via ORDS.
- **Authorized URLs**: lista de URLs absolutas aceitas como parâmetro de certas APIs (ex.: `P_NEXT_URL` de `APEX_UTIL.COUNT_CLICK`); evita open redirect. Comparação por prefixo exato.
- **Real Application Security**: *Allow Real Application Security* na instância; se o authentication scheme usar RAS, o APEX cria e anexa uma sessão RAS a cada sessão APEX (grupos dinâmicos viram RAS dynamic/external roles).
- **Excluded Domains**: domínios proibidos para regiões URL e web services.
- **Workspace provisioning** (Manual/Request/Automatic), e-mail com SSL/TLS, purge de workspaces inativos, BI Publisher via HTTPS e wallet.

Fonte: [Managing Instance Security](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/manging-instance-security.html), [Managing Authorized URLs](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/managing-authorized-urls.html), [Enabling Real Application Security](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/enabling-real-application-security.html), [Configuring Security](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-security.html), [Configuring Instance Settings](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-instance-settings.html)

---

## 13. APIs de segurança (mapa)

Assinaturas completas estão no documento 06 e na API Reference; aqui, o papel de cada subprograma na segurança.

### APEX_AUTHENTICATION: login, logout, callbacks e persistência

| Subprograma | Para que serve |
|---|---|
| `LOGIN` | Autentica na sessão atual (pre-auth → função → post-auth → deep link); `p_set_persistent_auth` |
| `POST_LOGIN` | Finaliza login quando a credencial foi verificada fora do APEX |
| `LOGOUT(p_session_id, p_app_id)` | Fecha a sessão e redireciona |
| `IS_AUTHENTICATED` / `IS_PUBLIC_USER` | Usuário logado? / público? |
| `CALLBACK`, `CALLBACK2`, `GET_CALLBACK_URL` | Retorno de login externo (Social Sign-In, plug-ins) |
| `SAML_CALLBACK`, `SAML_METADATA` | SAML |
| `SEND_LOGIN_USERNAME_COOKIE`, `GET_LOGIN_USERNAME_COOKIE`, constante `c_default_username_cookie` | Lembrar usuário (com consentimento) |
| `PERSISTENT_COOKIES_ENABLED`, `PERSISTENT_AUTH_ENABLED` | O que a instância permite |
| `REMOVE_PERSISTENT_AUTH`, `REMOVE_CURRENT_PERSISTENT_AUTH` | Revogar "lembrar login" |
| tipo `t_configuration` | Parâmetro da Configuration Procedure |

Fonte: [APEX_AUTHENTICATION](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AUTHENTICATION.html)

### APEX_AUTHORIZATION: consultar e cachear autorizações

| Subprograma | Para que serve |
|---|---|
| `IS_AUTHORIZED(p_authorization_name)` | Avalia scheme por nome (usa cache) |
| `HAS_ACCESS(p_static_id)` | Avalia scheme por Static ID |
| `ENABLE_DYNAMIC_GROUPS(p_group_names apex_t_varchar2)` | Habilita grupos na sessão (no post-auth); grupos do repositório trazem grupos concedidos; com RAS viram roles RAS |
| `RESET_CACHE` | Limpa cache de autorizações da sessão |

Deprecated em `APEX_UTIL`: `PUBLIC_CHECK_AUTHORIZATION`, `RESET_AUTHORIZATIONS`: use os acima.

Fonte: [APEX_AUTHORIZATION](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AUTHORIZATION.html)

### APEX_ACL: papéis do Application Access Control

`ADD_USER_ROLE` (2), `REMOVE_USER_ROLE` (2), `REPLACE_USER_ROLES` (2), `REMOVE_ALL_USER_ROLES`, `HAS_USER_ROLE`, `HAS_USER_ANY_ROLES`, `IS_ROLE_REMOVED_FROM_USER`. Detalhes no §4.

Fonte: [APEX_ACL](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_ACL.html)

### APEX_ESCAPE: escaping por contexto

`HTML`, `HTML_CLOB`, `HTML_TRUNC` (2), `HTML_ALLOWLIST`, `HTML_ALLOWLIST_CLOB`, `HTML_ATTRIBUTE`, `HTML_ATTRIBUTE_CLOB`, `JS_LITERAL`, `JS_LITERAL_CLOB`, `JSON`, `JSON_CLOB`, `CSS_SELECTOR`, `REGEXP`, `LDAP_DN`, `LDAP_SEARCH_FILTER`, `CSV` (2), `SET_CSV_PARAMETERS`, `GET_CSV_ENCLOSED_BY`, `GET_CSV_SEPARATED_BY`, `STRIPHTML` (2), `NOOP` (2), `SET_HTML_ESCAPING_MODE`; constantes `c_ldap_dn_reserved_chars`, `c_ldap_search_reserved_chars`, `c_html_allowlist_tags`. Detalhes no §7.

Fonte: [APEX_ESCAPE](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_ESCAPE.html)

### APEX_CUSTOM_AUTH: sessão e autenticação de baixo nível

| Subprograma | Para que serve |
|---|---|
| `IS_SESSION_VALID` | Resultado do page sentry do scheme atual |
| `CURRENT_PAGE_IS_PUBLIC` | Página atual é pública? |
| `LOGIN` / `POST_LOGIN` | API de login antiga (autenticação + registro de sessão / só registro) |
| `LOGOUT` | **Deprecated** (use `APEX_AUTHENTICATION.LOGOUT`) |
| `GET_USER`, `GET_USERNAME`, `SET_USER` | Ler/definir `APEX_APPLICATION.G_USER` |
| `GET_SESSION_ID`, `SET_SESSION_ID`, `GET_NEXT_SESSION_ID`, `SET_SESSION_ID_TO_NEXT_VALUE`, `SESSION_ID_EXISTS`, `GET_SESSION_ID_FROM_COOKIE`, `DEFINE_USER_SESSION` | Gerência de session ID |
| `GET_COOKIE_PROPS` | Propriedades do cookie de sessão (nome, path, domínio, secure) |
| `GET_LDAP_PROPS`, `LDAP_DNPREP` | Atributos LDAP do scheme; preparar DN |
| `GET_SECURITY_GROUP_ID`, `APPLICATION_PAGE_ITEM_EXISTS` | Utilitários |

Fonte: [APEX_CUSTOM_AUTH](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_CUSTOM_AUTH.html)

### APEX_JWT: emitir e validar JSON Web Tokens (HS256)

Tokens com 3 partes (header, payload, assinatura). **Só HS256** (simétrico); RS256 e outros assimétricos não são suportados.

| Subprograma | Para que serve |
|---|---|
| `ENCODE(p_iss, p_sub, p_aud, p_nbf_ts, p_iat_ts default systimestamp, p_exp_sec, p_jti, p_other_claims, p_signature_key raw) return varchar2` | Gera token; com chave, assina HS256 |
| `DECODE(p_value, p_signature_key default null) return t_token` | Decodifica; com chave, valida a assinatura (`HS256` ou `none`). Erros: `VALUE_ERROR`, `WWV_FLOW_CRYPTO.UNSUPPORTED_FUNCTION` |
| `VALIDATE(p_token, p_iss, p_aud, p_leeway_seconds default 0)` | Confere `iss`, `aud` (ou `azp` se `aud` for array), `exp`/`nbf`/`iat`; `VALUE_ERROR` se falhar |
| `t_token` | Record `header`, `payload`, `signature` |

```sql
declare
    l_token apex_jwt.t_token;
begin
    l_token := apex_jwt.decode(p_value => :P_TOKEN, p_signature_key => l_chave);
    apex_jwt.validate(p_token => l_token, p_iss => 'corlix', p_aud => 'api-interna');
end;
```

Pegadinha: `DECODE` sem `p_signature_key` **não verifica a assinatura**; sempre passe a chave (ou valide de outra forma) antes de confiar nos claims.

Fonte: [APEX_JWT](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_JWT.html), [ENCODE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ENCODE.html), [DECODE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/DECODE.html), [VALIDATE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/VALIDATE.html)

---

## 14. Divergências encontradas na documentação oficial

### Divergências e ambiguidades da doc 26.1 sobre segurança

1. **Padrão do Evaluation Point**: o App Builder Guide diz que o padrão é *Once per session*; a APEXlang Reference lista `evaluationType` com padrão `perPageView`. No `.apx`, declare sempre `evaluationType`.
2. **Grupos dinâmicos**: a tabela de Security Attributes manda chamar `apex_authentication.enable_dynamic_groups`; na API Reference e no Developer's Companion a procedure é **`APEX_AUTHORIZATION.ENABLE_DYNAMIC_GROUPS`**. Use a de `APEX_AUTHORIZATION`.
3. **Rejoin Sessions na página**: o texto da página diz que *Enabled for Public Sessions* exige *Embed in Frames* restrito; nas páginas de aplicação e instância essa exigência aparece em *Enabled for All Sessions*.
4. **Restricted Characters**: a doc lista 5 opções por descrição; o APEXlang tem 7 valores (`workspaceSchema`, `workspaceUserSchema`, `workspaceUserSchemaId` não descritos no capítulo). A correspondência exata deve ser conferida no 26.1.5.
5. **Page Access Protection**: o wizard chama a terceira opção de *No Arguments Allowed*; o Page Designer, de *No Arguments Supported* (`noArgumentsSupported`).
6. **Developer's Companion** diz que *Page Access Protection* "defaults to Arguments Must Have Checksum" (para páginas criadas pelo Builder); a APEXlang Reference dá `unrestricted` como padrão da propriedade. Não confie no padrão: declare.
7. **Cache e Embed in Frames**: o tip diz que ambos dependem de navegadores com suporte a `X-Frame-Options`, mas o Cache usa `cache-control: no-store`.

Fonte: [Editing an Authorization Scheme](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-authorization-scheme.html), [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html), [Configuring Security Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-security-attributes.html), [ENABLE_DYNAMIC_GROUPS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ENABLE_DYNAMIC_GROUPS-Procedure.html), [Editing Page Attributes in Page Designer](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-page-attributes-in-page-designer.html), [Unprotecting Dynamic Client Arguments](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/unprotecting-dynamic-client-arguments.html)

---

## 15. Aplicação no Corlix Hub

### Estado atual da segurança no Corlix Hub (app 100, conferido nos .apx em 21/10/2026)

- **Autenticação**: `authentication oracle-apex-accounts` (`oracleApexAccounts`), sem hooks (sem post-authentication, sem Configuration Procedure). Os itens de sessão (`G_ID_EMPRESA`, `G_NOME_EMPRESA`, `APP_USER_CARGO`...) são preenchidos por **application processes**; `SET_G_ID_EMPRESA` roda em `point: afterAuthentication`. Página 9999 é `authentication: public`.
  - Doc oficial: APEX Accounts não é recomendado em produção (credenciais iguais às do workspace). Para o projeto acadêmico serve; para produção, avaliar Social Sign-In/IdP.
- **Aplicação** (`application.apx`): só declara `security { runtimeApiUsage: modifyWorkspaceRepository }` (necessário para `APEX_UTIL.CREATE_USER` na P14) e `sessionStateProtection { checksumSalt: ... }`. Todo o resto usa os **padrões APEXlang**: SSP habilitado, `bookmarkHashFunction sha2-512bit`, `deepLinking false`, `embedInFrames deny`, `browserCache false`, `htmlEscapingMode extended`, `rejoinSessions false`, `referrerPolicy strictOrigin`, nenhuma authorization de aplicação, nenhum header CSP.
- **Páginas**: todas com `pageAccessProtection: argumentsMustHaveChecksum` e `formAutoComplete: false`. Com `authorizationScheme`: p7 (`@admin-rh`), p13 e p22 (`@colaborador`), p14, p18, p19, p20, p21, p23 (`@admin-rh`). **Sem** authorization de página: 1–6, 8, 11, 12, 15, 16, 17, 26, 27.
- **Authorizations** (`authorizations.apx`), todas `evaluationType: perSession`: `ADMIN_RH`, `EQUIPE_CORLIX_HUB`, `PUBLICADOR_DE_CONTEUDO`, `SOMENTE_DIRETORIA` (`isInRoleOrGroup`), e `COLABORADOR`, `GESTOR` (`plSqlFunctionBody`, consultam `colaborador` filtrando `id_empresa = :G_ID_EMPRESA`).
- **Roles ACL** (`acl-roles.apx`): Admin RH, Colaborador, Diretoria, Equipe do Corlix Hub, Gestor, Publicador de Conteúdo. Atribuição pela P14 via `pkg_perfis_acesso.atribuir_papeis` (usa `APEX_ACL`).
- **Itens com checksum de sessão** (`checksumRequiredSessionLevel`) nas páginas 13, 14, 16, 17, 18, 19, 21, 22, 27.
- **Escaping**: P4 (Chat) tem colunas `CAB_DEPT` e `SEP_DIA` com `escapeSpecialChars: false`; o HTML montado na query escapa o nome do departamento com `apex_escape.html(d.nome)`. Os módulos organograma e histórico de carreira têm wrappers de `apex_escape.html`/`html_attribute`.

**Divergência com `docs/ai-context/`**: `README.md` (tabela de páginas: "Monitor de Logs ... sem authorization!"), `03-componentes-compartilhados.md` §2.3 ("nenhuma página tem `authorizationScheme`") e `08-convencoes-e-pegadinhas.md` §Segurança ("Nenhuma página tem authorization própria") estão **desatualizados** em relação ao código: hoje p7, p13, p14, p18–p23 têm scheme de página. Continua verdade que **p15, p16 (empresas) e p17 (emitir comunicado)** só são protegidas pelo menu. O mesmo §2.2 do 03 diz "todas `isInRoleOrGroup`", mas `COLABORADOR` e `GESTOR` são `plSqlFunctionBody`. Vale o código; o `ai-context` deve ser corrigido por quem mantém aquela pasta.

Fonte: [Configuring Security Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-security-attributes.html), [Oracle APEX Accounts](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/apex-accounts.html), [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Regras de segurança do projeto traduzidas em recursos do APEX

| Regra do projeto (`ai-context/08`) | Recurso APEX | Como aplicar |
|---|---|---|
| Página administrativa tem `authorizationScheme` na página | Authorization de página | `page > security > authorizationScheme: @admin-rh` (ou o scheme adequado); repetir na entrada do menu, botões e **processos** |
| Links com checksum | SSP + `argumentsMustHaveChecksum` | `apex_page.get_url(p_page => .., p_items => .., p_values => ..)` ou link builder; nunca `'f?p=...'` concatenado |
| Toda query filtra `id_empresa` | Filtro em SQL com bind; opcionalmente VPD | `where id_empresa = :G_ID_EMPRESA` (bind, não `&G_ID_EMPRESA.`); `G_ID_EMPRESA` é application item, portanto **Restricted** (o browser não consegue setar) |
| UI pt-BR | `error.errorMessage` dos schemes | Mensagens já em pt-BR ("Acesso restrito ao RH.") |
| Versão 26.1.5 | Caminhos do Builder | Usar os caminhos deste documento; marcar "(confirmar no 26.1.5)" quando não conferido |

Fonte: [Preventing URL Tampering](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/preventing-url-tampering.html), [GET_URL Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_URL-Function.html), [Understanding Page Items](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-page-items.html)

### Pontos de atenção e melhorias recomendadas para o Corlix Hub

1. **Proteger p15, p16 e p17 na página**: `@administration-rights` em 15/16 e `@publicador-de-conteudo` em 17 (o mesmo do menu), e nos processos de DML dessas páginas. Rode *Report Pages Without Authorization Schemes* para conferir.
2. **`perSession` + papéis dados pela P14**: o usuário cujo papel foi alterado só vê a mudança após novo login (já registrado em `ai-context/09` §4.1). Para o próprio admin, `apex_authorization.reset_cache` após a alteração resolve na sessão dele.
3. **`COLABORADOR`/`GESTOR` dependem de `G_ID_EMPRESA`**: como são `perSession`, se o item estiver nulo na primeira avaliação (conta sem vínculo, ou item ainda não preenchido), o `FALSE` fica memorizado até novo login. Hoje o item é preenchido em `afterAuthentication`, antes de qualquer página; se essa ordem mudar, considere `perPageView`.
4. **Subscriptions/background**: se algum relatório com subscription usar esses schemes, lembre que *Run on Background Job* usa session state clonado **sem** o que foi definido após a autenticação (`G_ID_EMPRESA` incluso).
5. **Escape**: mantenha `escapeSpecialChars: true` como padrão; nas colunas da P4 que já estão `false`, todo valor vindo de tabela deve passar por `apex_escape.html` antes de concatenar (hoje `d.nome` passa; revise os demais campos se a query mudar). Prefira HTML Expression com `#COL!HTML#`.
6. **CSP**: o tema usa static files (`corlix-tema.css`, `custom.css`), bom para CSP; mas há CSS inline na P4 (`.ch-*`) e HTML com links na Global Page. Antes de impor `Content-Security-Policy`, teste com `Content-Security-Policy-Report-Only` e o placeholder `#APEX_CSP_NONCE#`.
7. **Debug no deploy** (`deployments/default.json` com `debugging: true`) e mensagens de erro: em produção, desligar; avaliar *Unhandled Errors* = *Return HTTP 400* na instância (o `log_pkg.apex_error_handler` já centraliza erros).
8. **Senhas na P14**: o item de senha do cadastro deve usar *Storage* = *Per Request (Memory Only)* ou criptografia; conferir no relatório *Password Items*.
9. **Deep linking** está desligado (padrão): links de e-mail/notificação levam à home após login. Se a funcionalidade de notificações precisar abrir a página exata, habilitar `deepLinking` nas páginas-alvo e gerar URLs com checksum `PUBLIC_BOOKMARK`/`PRIVATE_BOOKMARK` via `APEX_UTIL.PREPARE_URL`.
10. **Links hardcoded da Global Page** (`r/corlixhub/&APP_ALIAS./notificacoes?session=&SESSION.`) não têm parâmetros de item, então passam pelo `argumentsMustHaveChecksum`; se ganharem parâmetros, troque por `apex_page.get_url`.

Fonte: [Viewing Authorization Reports](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/viewing-authorization-reports.html), [Attaching an Authorization Scheme to an Application, Page, or Components](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/attaching-an-authorization-scheme.html), [Using Content Security Policy (CSP) in APEX](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-csp-in-apex.html), [About Items of Type Password](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-items-of-type-password.html), [Configuring Service-level Security Settings](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-service-level-security-settings.html)

### Receita: proteger uma nova página administrativa do Corlix Hub

1. Escolha ou crie o scheme em `shared-components/authorizations.apx` (declare `evaluationType` e `errorMessage` em pt-BR).
2. Na página: `security { authorizationScheme: @admin-rh  pageAccessProtection: argumentsMustHaveChecksum }`.
3. Na entrada de `lists.apx` (menu), o mesmo scheme.
4. Botões e processos de DML: o mesmo scheme (defesa em profundidade).
5. Itens que recebem ID pela URL: `sessionStateProtection: checksumRequiredSessionLevel`; hidden definidos pelo servidor com *Value Protected*.
6. Todas as queries: `where id_empresa = :G_ID_EMPRESA`.
7. Links para a página: `apex_page.get_url(...)`.
8. Saídas HTML: `apex_escape.html` / filtros `!HTML`.
9. Teste com um usuário **sem** o papel: abrir pela URL deve dar "Access denied"; depois atribua o papel, **saia e entre**, e teste de novo.
10. Atualize `docs/ai-context/02` (página) e `03` (uso das authorizations).

Fonte: [Shaping Experience with Rules and Roles](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/shaping-experience-rules-and-roles.html), [Experiencing Authorization in Action](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/experiencing-authorization-action.html)
