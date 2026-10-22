# 14 · APEX 26.1.5: versão do projeto × documentação e correções dos patches 26.1.1 a 26.1.5

> Base: página oficial [Oracle APEX 26.1 Known Issues](https://www.oracle.com/tools/downloads/apex-downloads/apex-261-known-issues/) (atualizada em 30/09/2026), [Oracle APEX Downloads](https://www.oracle.com/tools/downloads/apex-261-downloads/), Release Notes 26.1 e o export do projeto. Gerado em 21/10/2026.
> Os títulos dos bugs estão em inglês, como a Oracle publica, para facilitar a busca pelo número ou pelo texto.

## 1. A documentação vale para o 26.1.5?

### Versão em uso no Corlix Hub: APEX 26.1.5
O backup mais recente do app (`database/f100.sql`, commit de 20/10/2026) registra `p_release=>'26.1.5'` e `Version: 26.1.5`, com `p_compatibility_mode=>'26.1'`. O export APEXlang (`corlixhub/.apex/apexlang.json`) registra `"mmdVersion" : "26.1.0+3102"`, que é o mesmo valor do exemplo da documentação 26.1. Ou seja, o formato APEXlang não mudou entre o 26.1.0 e o 26.1.5. No ambiente, para conferir: *Help > About* (Product Build e Patch Version) ou
```sql
select patch_version, installed_on from apex_patches where patch_number = 39179920 order by installed_on;
```
O Autonomous AI Database aplica os Patch Set Bundles automaticamente logo depois de publicados, por isso o projeto já está no patch mais recente.

Fonte: [Oracle APEX 26.1 Known Issues](https://www.oracle.com/tools/downloads/apex-downloads/apex-261-known-issues/)

### Por que a documentação "26.1" cobre o 26.1.5
A Oracle publica **uma biblioteca de documentação por release** (26.1), e não uma por patch. Desde o fim dos *patch set releases*, o APEX só entrega releases completas; correções de defeitos graves chegam como **PSEs** reunidos no *Patch Set Bundle* 39179920 ("PSE BUNDLE FOR APEX 26.1 (PSES ON TOP OF 26.1.0)"). Cada nova versão do bundle sobe o terceiro número (26.1.1, …, 26.1.5) e é cumulativa. Os bundles corrigem bugs, sem novas features nem mudanças de API. Logo:
- a biblioteca baixada (`apex_26.1_20260810`, gerada em 10/08/2026) é a documentação **correta e atual** para o 26.1.5. Não existe uma documentação "26.1.5" separada;
- o que muda do 26.1.0 para o 26.1.5 é só a lista de correções abaixo. Quando a documentação ou as Release Notes descreverem um bug que um patch já corrigiu, **vale a correção** (ver §2);
- os passos do Builder seguem a regra do projeto: o que não foi conferido no 26.1.5 leva "(confirmar no 26.1.5)" (`ai-context/08` §1, regra 11).

Fonte: [Release Notes: About These Release Notes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/about-release-notes.html) · [Oracle APEX Downloads](https://www.oracle.com/tools/downloads/apex-261-downloads/)

### Recursos do CDN por versão
Cada versão do bundle tem um caminho próprio no CDN, de `https://static.oracle.com/cdn/apex/26.1.0/` a `https://static.oracle.com/cdn/apex/26.1.5/`. Em instalação própria, o CDN precisa acompanhar a versão do bundle aplicado. No Autonomous, a Oracle cuida disso.

Fonte: [Oracle APEX 26.1 Known Issues](https://www.oracle.com/tools/downloads/apex-downloads/apex-261-known-issues/)

## 2. Correções e known issues que importam para este projeto

### APEXlang import/export corrigidos nos patches (o projeto versiona APEXlang)
Como a fonte do app é APEXlang (`corlixhub/`), estas correções afetam o fluxo de export, import e backup do projeto. Todas já estão no 26.1.5:
- **26.1.1:** INVALID PROPERTY no import quando há *column groups* de IG em regiões que não são IG (39402028); o import não preservava o link da working copy (39344501); o export trata errado expressões SQL com vírgula ao gerar `f?p` (39474195); o import pela UI não encontrava `install.sql`/`application.apx` (39359824); a APEXlang View não mostrava alguns slots (39322631).
- **26.1.3:** o export pulava a *format mask* de facets (39716106); o `^M` final nos arrays de URL de CSS/JS no APEXlang foi removido (39547705).
- **26.1.4:** filtros de IR em colunas de data perdiam a exibição da condição no import APEXlang (39834991); valor de propriedade com um único `[` confundia o compilador APEXlang (39832528).

Fonte: [Oracle APEX 26.1 Known Issues](https://www.oracle.com/tools/downloads/apex-downloads/apex-261-known-issues/)

### ORA-01403 ao importar app com atribuições ACL de papéis removidos (corrigido no 26.1.5)
**Sintoma:** o import da aplicação falha com `ORA-01403` ao restaurar as atribuições usuário × papel da ACL.
**Causa:** havia atribuições para papéis que já tinham sido removidos da app (bug 39904260).
**Correção:** corrigido no patch 5 (26.1.5). Em versões anteriores, remova as atribuições órfãs antes de exportar.
**Prevenção:** o projeto usa papéis ACL (`acl-roles.apx`, módulo `perfis-acesso`). Ao remover um papel, remova também as atribuições dele.

Fonte: [Oracle APEX 26.1 Known Issues](https://www.oracle.com/tools/downloads/apex-downloads/apex-261-known-issues/)

### Authorization/authentication scheme com `:APP_COMPONENT_TYPE` quebra no 26.1 (corrigido no 26.1.5)
**Sintoma:** depois do upgrade para o 26.1, schemes que usam o bind `:APP_COMPONENT_TYPE` deixam de funcionar.
**Causa:** regressão do 26.1 (bug 39959449).
**Correção:** corrigido no 26.1.5. Hoje o projeto não usa esse bind (nenhuma ocorrência em `corlixhub/` ou `modulos/`).

Fonte: [Oracle APEX 26.1 Known Issues](https://www.oracle.com/tools/downloads/apex-downloads/apex-261-known-issues/)

### File Browse com extensões em maiúsculas falhava (corrigido no 26.1.2)
**Sintoma:** um item *File Browse/File Upload* com *supported file extensions* em maiúsculas rejeitava os arquivos.
**Causa:** regressão do 26.1 (bug 39575309).
**Correção:** corrigido no 26.1.2. A p21 usa `fileTypes: .pdf,image/*` (minúsculas), então não era afetada.

Fonte: [Oracle APEX 26.1 Known Issues](https://www.oracle.com/tools/downloads/apex-downloads/apex-261-known-issues/)

### E-mail de workspace inexistente "enviado" mas nunca entregue (known issue, sem correção)
**Sintoma:** `APEX_MAIL` aceita a mensagem, mas ela nunca chega.
**Causa:** no 26.1, a fila de e-mail exige que cada mensagem esteja associada a um workspace existente. Apps ou jobs do scheduler que informavam um workspace ID inventado ou obsoleto deixam de entregar (bug 40074079).
**Correção:** use o ID de um workspace válido e existente (em job, defina o workspace com `apex_util.set_workspace` / `apex_session.create_session` antes de chamar `APEX_MAIL`).

Fonte: [Oracle APEX 26.1 Known Issues](https://www.oracle.com/tools/downloads/apex-downloads/apex-261-known-issues/)

### Instalação no 19c SE2 falha com ORA-00439 (resolvido)
**Sintoma:** `ORA-439: feature not enabled: Basic Compression` ao instalar o 26.1 no 19c SE2 (bug 39397271), ou `ORA-00439: feature not enabled: Online Index Build` ao aplicar o 26.1.3 no SE2 (bug 39872578).
**Causa:** os scripts usavam recursos de Enterprise Edition.
**Correção:** baixe de novo o zip do 26.1 (republicado em 25/05/2026). A correção do patch saiu no 26.1.4. Não afeta o Autonomous.

Fonte: [Oracle APEX 26.1 Known Issues](https://www.oracle.com/tools/downloads/apex-downloads/apex-261-known-issues/)

### Outras correções relevantes para o tipo de app do Corlix Hub
- **CSP:** violações de nonce no refresh AJAX de Classic Report (39548318) e no Rich Text Editor (39563236), corrigidas no 26.1.2. Importa caso o projeto ative CSP (ver `05-seguranca.md` e `13` §4).
- **Login social:** `APEX_AUTHENTICATION.LOGOUT` devolvia página em branco com Social Sign-In OAuth2 (39406703), corrigido no 26.1.2.
- **Debug:** URLs longas causavam `ORA-06502` no debug (39493465), corrigido no 26.1.2.
- **Global Page:** botão do tipo *Menu* na Global Page não abria o menu (39722171), corrigido no 26.1.3. A p0 tem o header do projeto.
- **Import:** o import não preservava *application locks* (39557252), corrigido no 26.1.3.
- **Exportação:** `APEX_DATA_EXPORT` repetia o conteúdo de CLOB em todas as páginas do PDF (39490226), corrigido no 26.1.5.
- **REST e web service:** `APEX_WEB_SERVICE` escrevia uma página de erro no buffer HTP com credenciais OAuth (39764851) e parâmetro estático não-string com substituição em REST Data Source parou de funcionar (39983352), ambos corrigidos no 26.1.5.
- **Upgrade:** o job `ORACLE_APEX_DAILY_METRICS` falhava com `ORA-01555` após o upgrade (39416789), corrigido no 26.1.2.

Fonte: [Oracle APEX 26.1 Known Issues](https://www.oracle.com/tools/downloads/apex-downloads/apex-261-known-issues/)

## 3. Lista completa de correções por patch

Cada patch inclui todos os anteriores. No total são 124 correções: 50 no 26.1.1, 23 no 26.1.2, 27 no 26.1.3, 6 no 26.1.4 e 18 no 26.1.5.

### Correções do patch 1 (26.1.1)

| Bug | Título oficial |
|---|---|
| 39393807 | APEXLANG IMPORT FAILS FOR WORKFLOWS HAVING PARALLEL FLOW ACTIVITY |
| 39253802 | INTERACTIVE REPORT: GROUP BY AND PIVOT DIALOGS CONTAIN POOR ACC LABELS |
| 39370733 | PAGE DESIGNER: TEMPLATE COMPONENT GROUP ATTRIBUTES NOT VISIBLE |
| 39314519 | REGRESSION : HUMAN TASK CREATION FAILS IF TASK PARAMETER VALUE IS LONGER THAN 255 CHARACTERS |
| 39402028 | INVALID PROPERTY ERROR ON APEXLANG IMPORT WHEN IG COLUMN GROUPS ARE PRESENT IN REGIONS OTHER THAN INTERACTIVE GRID |
| 39335842 | OBJECT BROWSER DATA TAB INSERT ROW FAILS FOR ANY TABLE WITH A CLOB COLUMN |
| 39348655 | OCI GEMINI AI CHAT REQUESTS FAIL WHEN TOOL CALLS ARE PRESENT |
| 39351143 | AI ASSISTANT UI/COLOR ISSUES |
| 39289752 | COPY AND SUBSCRIBE REST DATA SOURCE LEADS TO SUBSCRIPTION STATUS NEEDS REFRESH |
| 39344085 | IMPORTING REST SOURCE CATALOG THROWS UNIQUE CONSTRAINT ERROR (WWV_FLOW_COLLECTIONS_UK), BUT IMPORTS SUCCESSFULLY |
| 39322631 | APEXLANG VIEW IN PAGE DESIGNER FAILS TO SHOW SOME APEXLANG SLOT NAMES |
| 39393826 | WHEN P_INCLUDE_SESSION_STATE IS SET TO 'N' THEN SESSION STATE SHOULD BE CLEARED IN IMPORT |
| 39411363 | MONACO EDITOR CANNOT LOAD WORKERS VIA CDN |
| 39390907 | REGRESSION - PAGE DESIGNER: JS ERROR IS THROWN WHEN UPDATING BACKGROUND PAGE PROCESS |
| 39344241 | CORRECT MASTER/DETAIL WIZARD REMEMBER_SELECTION RDS PROPERTY VALUE |
| 39411937 | NEXT LINK IS NOT WORKING ON THE MAIL QUEUE REPORT |
| 39344501 | APEXLANG IMPORT DOES NOT PRESERVE WORKING COPY LINK |
| 39378321 | REGRESSION: ERROR USING MAP LAYER WITH POINT CLUSTERING ENABLED |
| 39288075 | ADMIN DIGEST > SUMMARY DASHBOARD SHOWS 0 COUNTS |
| 39427432 | SQL SCRIPT IMPORT NULLS OUT THE CONTENT AND RAISES ORA-06502 IF EDIT CLICKED |
| 36767291 | SELECT ONE/MANY VALUE HTML EXPR SUBSTS FAIL IF LOV ADDL COL NAMES CLASH W/ CLASSIC REPORT COLS |
| 39383767 | REGRESSION: MAP REGION USING "ICON" STYLE W SUBSTITUTION FOR POINT LAYER FAILS WITH JS ERROR |
| 39325666 | UNABLE TO SET ROWS PER PAGE FROM ACTION MENU WHEN SET USING AN EARLIER NATURAL LANGUAGE REQUEST |
| 39427696 | REGRESSION: ERROR IMPORTING WORKSPACE FILES EXPORT FROM APEX VERSION BEFORE 26.1 |
| 39420516 | MASTER COMPONENT CHECKSUM NOT CALCULATED ON APP IMPORT |
| 39359834 | APEXLANG UI IMPORT | DURING IMPORT EXPORTED FROM ORACLE APEX VERSION FIELD HAS NO VALUE |
| 39465239 | EXPOSE APEX AUTHENTICATION AS DATA REPORTER AUTHENTICATION SCHEME |
| 39474195 | APEXLANG EXPORT: F?P URL PARSING MISHANDLES QUOTED UNALIASED SQL COLUMN EXPRESSION WITH COMMAS |
| 39397271 | APEX 26.1 INSTALLATION FAILS ON 19C SE2 DATABASE - ORA-439: FEATURE NOT ENABLED: BASIC COMPRESSION |
| 39359824 | APEXLANG UI IMPORT ERROR - UNABLE TO FIND APEX CONTENT INSTALL.SQL OR APPLICATION.APX |

Mais 20 correções publicadas só como "Fix for bug <número>", sem descrição.

Fonte: [Oracle APEX 26.1 Known Issues](https://www.oracle.com/tools/downloads/apex-downloads/apex-261-known-issues/)

### Correções do patch 2 (26.1.2)

| Bug | Título oficial |
|---|---|
| 39416789 | APEX DAILY JOB ORACLE_APEX_DAILY_METRICS FAILED WITH ORA-01555 AFTER UPGRADE TO APEX 26.1 |
| 39467407 | IN TEXT MSG TRANSLATION APP, ALT IR SAVED RPT SHOWS &{NAME}. UNEXPECTEDLY |
| 39483916 | REGRESSION: DATA LOAD CREATE WIZARD DOES NOT ALLOW TAB AS COLUMN DELIMITER |
| 39401806 | APP IMPORT FAILS WITH "ORA-20111: FOR PROCESS AND ITEM TYPE PLUGINS..." ERROR |
| 39552100 | REGRESSION: WORKSPACE IMPORT IN APP 4050 ALWAYS RAISES "SCHEMA IS RESTRICTED" WHEN SCHEMA ALREADY EXISTS |
| 39540365 | WORKFLOW COMPONENT: ASYNC WORKFLOW ACTIVITY CAN BE RESET TO WAITING AFTER IT FAULTS DURING EXECUTION |
| 39548318 | CSP NONCE VIOLATION DURING CLASSIC REPORT AJAX REFRESH DUE TO SERVER-GENERATED STYLE |
| 39587362 | ADMIN DIGEST - SYSTEM SCHEDULER JOBS REPORT INCLUDES USER-GENERATED APEX SCHEDULER JOBS |
| 39426028 | SUBSCRIPTION IS LOST WHEN REFRESHING AN APPLICATION COMPUTATION |
| 39539076 | REGRESSION: IR COLUMN TYPE LIST INCLUDE UNSUPPORTED TEMPLATE COMPONENTS |
| 39575309 | REGRESSION: FILE BROWSE W/ SUPPORTED FILE EXTENSIONS IN UPPERCASE FAILS IN 26.1 |
| 39411057 | FULL EXPORT GENERATES INVALID SQL FOR WORKFLOW LINKED TASK INSTANCES |
| 39552165 | APEX SHIPS JET LIBRARY CONTAINING (OUTDATED) DEVELOPMENT ARTIFACTS |
| 39493465 | LONG URLS CAUSE DEBUG ERROR: ORA-06502: PL/SQL: VALUE OR CONVERSION ERROR: CHARACTER STRING BUFFER TOO SMALL |
| 39537216 | AI AGENT SYSTEM PROMPT TEMPLATE DIRECTIVES NOT WORKING AS DOCUMENTED |
| 39563236 | CSP NONCE VIOLATION DURING USE OF RICH TEXT EDITOR |
| 39406703 | APEX_AUTHENTICATION.LOGOUT RETURNS BLANK PAGE AND DOES NOT REDIRECT FOR SOCIAL SIGN-IN OAUTH2 AFTER 26.1 UPGRADE |
| 39595332 | REGRESSION: DYNAMIC ACTIONS GENERATED IN WORKFLOW CONSOLE AND TASK DETAILS PAGES ARE INCOMPLETE |
| 39683227 | APEX 26.1 - REGRESSION UNGUARDED CLIPBOARDITEM.SUPPORTS() CALL IN DESKTOP_ALL.MIN.JS THROWS UNCAUGHT TYPEERROR ON SAFARI |

Mais 4 correções publicadas só como "Fix for bug <número>", sem descrição.

Fonte: [Oracle APEX 26.1 Known Issues](https://www.oracle.com/tools/downloads/apex-downloads/apex-261-known-issues/)

### Correções do patch 3 (26.1.3)

| Bug | Título oficial |
|---|---|
| 39716106 | APEXLANG EXPORT SKIPS FORMAT MASK FOR FACETS AND HAS SPARTIAL INDEX FOR MAPS |
| 39718475 | CREATE A LEGACY PAGE FORM ENDS WITH ERROR-ORA-20001 |
| 39623051 | CREATE PAGE WIZ CAN CREATE EDITABLE GRID W/ MORE SELECT LISTS THAN EXPECTED |
| 39735488 | ORA-6502 CONVERTING APPLICATION TEXT WITH OVER 1000 MESSAGES |
| 39699404 | THEME ROLLER SAVE FAILS WITH ORA-28461 ON FIPS-ENABLED DATABASES |
| 39700366 | REGRESSION: STAR RATING COL IN INTERACTIVE GRID ALWAYS SHOWS ONE STAR IN 26.1 |
| 39659750 | REGRESSION: SEARCH CONFIG ON DBMS_SEARCH RAISES NULL INDEX TABLE KEY VALUE |
| 39689808 | APEX REGION PLUG-IN: INCONSISTENT HANDLING OF DEPRECATED STATIC IDS AFFECTING MULTI-VERSION BACKWARD COMPATIBILITY |
| 39779736 | CANNOT USE AGENT WITH TOOLS AND GPT-5.6 |
| 39547705 | AVOID TRAILING ^M CHARACTER IN CSS AND JS URL STRING ARRAYS IN APEXLANG |
| 39664657 | ADB: CREATED DATA REPORTER ADMIN OR EDITOR CANNOT SIGN IN TO WORKSPACE |
| 39664718 | ADB: IN DATA REPORTER, SWITCHING ROLE TYPE FROM VIEWER TO EDITOR THROWS "ERROR PROCESSING VALIDATION" ERROR |
| 39664758 | ADB: IN DATA REPORTER, SWITCHING USER ROLE THROWS ERROR "REQUIRE CHANGE OF PASSWORD ON FIRST USE MUST MATCH THE VALUES Y AND N" |
| 39781640 | REGRESSION IN 24.2: PAGE DESIGNER DOES NOT CREATE "PARAMETERS" NODE FOR MAP LAYERS / CHART SERIES ON REST SOURCE |
| 39722171 | BUTTON OF TYPE MENU ON GLOBAL PAGE DOES NOT SHOW THE MENU ON CLICK |
| 39804519 | REGRESSION IN 26.1.2: RICH TEXT EDITOR IN MARKDOWN MODE ESCAPES VARIOUS SPECIAL CHARACTERS |
| 39792845 | IT TAKES LONGER TO IMPORT TEXT MESSAGES IN APEX 26.1 THAN BEFORE |
| 39803148 | APP UNAVAILABLE MESSAGE CANNOT BE SET FOR STATUS UNAVAILABLE (REDIRECT TO URL) |
| 39749091 | MERGING CHANGED WORKFLOW FROM WORKING COPY TO MAIN DELETES EXISTING INSTANCES |
| 39768927 | REGRESSION: RICH TEXT EDITOR UNEXPECTEDLY SAVES UNESCAPED SPACES IN MARKDOWN URLS |
| 39557252 | APEX IMPORT DOES NOT PRESERVE APPLICATION LOCKS |
| 39800372 | LEGACY DATA LOAD - UNABLE TO NAVIGATE TO ADDITIONAL TRANSFORMATION RULES PAGES |
| 39741741 | ORA-6502 DURING TRANSLATE AND SYNC MESSAGES |
| 39772421 | PLUGIN ATTRIBUTE STATIC IDS ARE INCORRECT AFTER UPGRADE FROM PRE-23.2 APEX |
| 39816636 | REGRESSION: ORA-1426 NUMERIC OVERFLOW ON GETPAGEDATA IF APPID > 2147483647 |

Mais 2 correções publicadas só como "Fix for bug <número>", sem descrição.

Fonte: [Oracle APEX 26.1 Known Issues](https://www.oracle.com/tools/downloads/apex-downloads/apex-261-known-issues/)

### Correções do patch 4 (26.1.4)

| Bug | Título oficial |
|---|---|
| 39847677 | ORA-1400 CONVERTING APP TEXT TO MESSAGES WITH TRANSLATABLE REPORT TEMPLATES |
| 39834991 | IR FILTERS ON DATE COLUMN LOSE CONDITION DISPLAY UNEXPECTEDLY ON APEXLANG IMPORT |
| 39830923 | REGRESSION: ORA-6502 OPENING PAGE DESIGNER IF PLUGIN HAS LONG ATTR GROUP APEXLANG NAME |
| 39872578 | UNABLE TO INSTALL APEX 26.1.3 PATCH ON SE2 DATABASE - ORA-00439: FEATURE NOT ENABLED: ONLINE INDEX BUILD |
| 39832528 | PROPERTY VALUE OF SINGLE LEFT SQUARE BRACKET CAN CONFUSE APEXLANG COMPILER |

Mais 1 correções publicadas só como "Fix for bug <número>", sem descrição.

Fonte: [Oracle APEX 26.1 Known Issues](https://www.oracle.com/tools/downloads/apex-downloads/apex-261-known-issues/)

### Correções do patch 5 (26.1.5)

| Bug | Título oficial |
|---|---|
| 39849397 | REGRESSION: RUNNING WORKFLOW INSTANCES HAVING ACTIVITY VARIABLES FAULT POST UPGRADE TO 26.1 |
| 39904260 | APP IMPORT FAILS WITH ORA-01403 WHEN RESTORING ACL USER-ROLE ASSIGNMENTS FOR REMOVED ROLES |
| 38473500 | INTERACTIVE REPORT WITH STICKY HEADERS JUMPING BACK HORIZONTALLY |
| 39842103 | REGRESSION: INSTANCE ADMIN: EDIT BUILDER AUTH SCHEME IN JAPANESE LANGUAGE THROWS ORA-1403 |
| 38951507 | LOVS WITH ADDITIONAL DISPLAY COLUMNS DONT SUPPORT SUBSTITUTIONS IN COLUMN HEADINGS |
| 39603760 | DATA REPORTER APP IMPORT IGNORES INSTANCE-LEVEL AUTHENTICATION OVERRIDE FOR APEX SCHEMES |
| 39490226 | APEX DATA EXPORT REPEATS CLOB CELL CONTENT ACROSS PDF PAGES |
| 39743519 | REGRESSION: DUPLICATING IR IN PD REUSES SAME INTERNAL_UID UNEXPECTEDLY |
| 39536622 | APEX - PREVENT URL ENCODING OF XML AND RTF FILES WHEN RENDER IS USED |
| 39619592 | DATA REPORTER "FACETED SEARCH WITH TABLE" REPORT SHOWS ONLY 15 ROWS WITHOUT PAGINATION |
| 39901095 | REGRESSION: APEX$AI_LAST_USER_PROMPT BINDS AS NULL IN AUG SYS PROMPT TOOL IMPLS |
| 39957804 | ORA-1426 NUMERIC OVERFLOW ON APEX_APP_INSTALL.SET_SUBSCRIPTION_MAPPING IF APPID > 2147483647 |
| 39947541 | REGRESSION: AFTER 26.1 UPGRADE ERROR EDITING TASK PARAMS OF EXISTING TASK INSTANCES |
| 39959449 | REGRESSION: AUTH SCHEMES USING :APP_COMPONENT_TYPE BIND CAN BREAK IN 26.1 |
| 39945659 | WORKFLOW COMPONENT: WORKFLOW INSTANCE IMPORT FAILED FOR WORKFLOW INSTANCES WITH NULL CRYPTO SALT |
| 39983352 | REGRESSION: NON-STRING REST DS STATIC PARAM W/ SUBSTITUTION STOPS WORKING |
| 40015638 | – Fix for bug 40015638 |
| 39764851 | APEX_WEB_SERVICE EMITS ERROR PAGE TO HTP BUFFER WHEN OAUTH CREDENTIALS ARE USED |

Mais 0 correções publicadas só como "Fix for bug <número>", sem descrição.

Fonte: [Oracle APEX 26.1 Known Issues](https://www.oracle.com/tools/downloads/apex-downloads/apex-261-known-issues/)

## Aplicação no Corlix Hub

- A documentação em `docs/apex-26.1/` e o índice `apex-docs` (biblioteca 26.1 de 10/08/2026) valem para o 26.1.5 em uso. A diferença do 26.1.0 para o 26.1.5 são só as correções acima.
- Antes de registrar um "bug do APEX" no `ai-context/09`, procure-o aqui (`casos.py buscar "<sintoma>" --modulo apex-26.1`). Se já estiver corrigido até o 26.1.5, a causa é outra.
- Quando a Oracle publicar um novo bundle (26.1.6+), atualize este documento a partir da página Known Issues e reindexe.

Fonte: [Oracle APEX 26.1 Known Issues](https://www.oracle.com/tools/downloads/apex-downloads/apex-261-known-issues/)
