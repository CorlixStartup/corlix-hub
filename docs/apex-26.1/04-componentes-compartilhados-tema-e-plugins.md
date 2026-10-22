# 04 · Shared Components, temas, Universal Theme, globalização e plug-ins

> Base: documentação oficial Oracle APEX 26.1 (App Builder User's Guide/htmdb: *Managing Shared Components*, *Managing Application Components*, *Using Themes and Theme Styles*, *Managing Application Globalization*, *Extending Application Capabilities*, *Managing Application Legacy Components*, e como apoio *App Builder Concepts* (templates, substitution strings, template directives), *Managing Computations, Validations, and Processes* (application processes/computations), *Deploying an Application* (build options, export de temas/plug-ins), *Creating Applications* (User Interface e Globalization attributes) e *Managing Application Security* (CSP); Developer's Companion/apxdc: *Adding Functionality with Plug-ins*, *Translating Your Application*, *Simplifying User Experience Design* (partes de tema, Universal Theme, templates e design system); API Reference/aeapi: `APEX_APP_SETTING`, `APEX_APPLICATION_ADMIN`, `APEX_SHARED_COMPONENT`, `APEX_THEME`, `APEX_LANG`, `APEX_PLUGIN`, `APEX_PLUGIN_UTIL`; APEXlang API Reference/apxln; Release Notes 26.1/htmrn). Gerado em 21/10/2026.

**Sumário**

1. Shared Components: mapa, subscriptions, component groups e Static ID
2. Lógica de aplicação: Application Items, Processes, Computations, Settings, Build Options, Component Settings e Shortcuts
3. Lists of Values (LOV) como shared component
4. Lists, Navigation Menu e Navigation Bar
5. Arquivos estáticos, Email Templates, Report Queries/Layouts e demais componentes
6. Temas e Universal Theme (UT 42)
7. Theme Styles, Theme Roller e a API `APEX_THEME`
8. Templates (page, region, button, label, list, breadcrumb, report, popup LOV), substitution strings e template directives
9. Template Options
10. CSS e JavaScript customizados (File URLs, `#MIN#`, `#APP_FILES#`, `#WORKSPACE_FILES#`, inline, variáveis CSS do UT, CSP)
11. Template Components
12. Plug-ins (tipos, callbacks PL/SQL, atributos, arquivos, eventos, distribuição)
13. Globalização (idioma primário, idioma derivado, formatos, time zone, códigos)
14. Tradução (Application-Based × Text Message-Based, text messages, `APEX_LANG`, mensagens internas)
15. Application Components (help, JET) e componentes legados
16. Aplicação no Corlix Hub

Convenção: nomes de interface, atributos e APIs ficam em inglês, como aparecem na documentação. "Grupo, Atributo" segue a notação da Oracle para o Property Editor. Trechos APEXlang usam a sintaxe dos arquivos `.apx` deste repositório.

---

## 1. Shared Components: mapa, subscriptions, component groups e Static ID

### Página Shared Components: o que fica em cada região

Shared components são definições de nível de aplicação que qualquer página pode usar. A página **Shared Components** (App Builder > aplicação > Shared Components, ou o botão de mesmo nome no topo do Page Designer) agrupa os links em regiões. Os badges ao lado de alguns links mostram quantos componentes existem.

| Região | Componentes |
|---|---|
| **Application Logic** | Application Definition, Application Items, Application Processes, Application Computations, Application Settings, Build Options |
| **Security** | Security Attributes, Authentication Schemes, Authorization Schemes, Application Access Control (roles), Session State Protection |
| **Other Components** | Lists of Values, Plug-ins, Component Settings, Shortcuts, Component Groups, Data Load Definitions |
| **Navigation and Search** | Lists, Navigation Menu, Tabs (só em temas antigos), Breadcrumbs, Navigation Bar List, Search Configurations |
| **User Interface** | User Interface Attributes, Progressive Web App, Themes, Templates, Email Templates, Map Backgrounds |
| **Files and Reports** | Static Application Files, Static Workspace Files, Report Queries, Report Layouts |
| **Data Sources** | REST Data Sources, Duality Views, JSON Sources, Legacy Web Service References (SOAP) |
| **Workflows and Automations** | Task Definitions, Automations, Workflows |
| **Globalization** | Globalization Attributes, Text Messages, Application Translations |
| **Generative AI** | AI Attributes, AI Agents, AI Services (estes ficam no workspace) |
| **Tasks** (lateral) | Export Application Components, Manage Supporting Objects, REST Synchronizations, Application Comments, Developer Comments |
| **Workspace Objects** (lateral) | Credentials, REST Enabled SQL Databases, Remote Servers: objetos do workspace, visíveis em todas as apps |

Quando usar: tudo que se repete em várias páginas (lógica que roda em toda página, listas de opções, menus, arquivos CSS/JS, mensagens traduzíveis) deve virar shared component. Quando não usar: lógica de uma única página fica na própria página (processos, computations e LOVs locais), porque shared components de lógica rodam em todas as páginas e custam em cada request.

Dica: as listas de shared components abrem em modo ícone ou relatório. O modo relatório (View Table) mostra as colunas **Subscribed From**, **Subscription Status** e **Subscribers**, além das abas *Utilization* (onde o componente é usado) e *History* (alterações recentes).

Fonte: [Shared Components Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/shared-components-page.html), [Accessing the Shared Components Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/accessing-shared-components-page.html), [Managing Shared Components](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-shared-components.html)

### Shared Component Subscriptions: copiar, assinar, refresh, publish e unsubscribe

Uma **subscription** liga um shared component de uma app (o *subscriber*) a um componente *master* em outra app do mesmo workspace. É o mecanismo de reuso entre aplicações.

Componentes que aceitam subscription: Application Access Control (roles), Application Computations, Application Items, Application Processes, Application Settings, Authentication Schemes, Authorization Schemes, Build Options, Component Groups, Data Load Definitions, Email Templates, Lists, Lists of Values, Map Backgrounds, Plug-ins, REST Data Source, Report Layouts, Search Configuration, Shortcuts e Text Messages. Temas e templates têm um mecanismo próprio (seção 6).

O que acontece ao assinar:
- O conteúdo do master e dos shared components de que ele depende é copiado para a app assinante.
- A cópia assinante fica **somente leitura**. Só o master é editável.
- Para propagar mudanças: edite o master e clique **Publish** (empurra para todos os assinantes) ou, no assinante, clique **Refresh** (puxa do master). Na lista de um tipo de componente, *Tasks > Refresh Subscriptions > Refresh All* faz um refresh em lote.

Formas de assinar:
1. Durante a cópia: *Tasks > Copy from another app*, escolha a app de origem e, na coluna de ação, **Copy and Subscribe** (as outras opções são *Yes* = só copiar e *No* = ignorar).
2. Na página de edição do componente: região **Subscription**, atributo *Subscribe From*, selecione o master e Apply Changes. O componente é atualizado imediatamente a partir do master. Isso não vale para REST Data Sources nem Data Load Definitions.

Status de subscription: `Up to date` (igual ao master) ou `Needs refresh` (o master mudou). O botão Refresh só aparece com `Needs refresh`. Publish ignora apps travadas por outros desenvolvedores. Para desfazer o vínculo, use **Unsubscribe** na região Subscription; a cópia passa a ser editável.

Via PL/SQL, `APEX_SHARED_COMPONENT.REFRESH` e `PUBLISH` fazem o mesmo (ver adiante). Na instalação de apps exportadas do 26.1, `apex_application_install.set_subscription_mode` e `set_subscription_mapping` controlam como as subscriptions são resolvidas.

Fonte: [Using Shared Component Subscriptions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-shared-component-subscriptions.html), [New Features: Subscription Mode](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### Resolução de dependências e Static ID ao copiar, assinar ou publicar (26.1)

Um shared component que referencia outro (uma LOV usada por uma lista, um build option num app item) tem **dependências**. O APEX resolve dependências automaticamente ao copiar, assinar, dar refresh e publicar:

1. Na app de destino, o APEX procura um componente com o **mesmo Static ID**. Se não achar, e o tipo tiver nome confiável como identificador, procura pelo **mesmo nome**. Se achar, reutiliza.
2. Se não achar, copia o componente dependente. Quando a cópia é feita com Subscribe ligado, os dados de subscription também são copiados.

Mudanças do 26.1 que afetam isso:
- **Static ID virou o identificador primário** para casar componentes entre apps. Todos os componentes referenciáveis têm Static ID. Application Computation, Email Template, Search Configuration e Plug-in **só casam por Static ID** (o nome deles não é único o bastante).
- Static ID agora existe em todos os shared components, page components e templates. No Builder ele é **somente leitura por padrão** (ícone de cadeado para editar). Apps importadas de versões anteriores recebem Static IDs legíveis gerados a partir do nome.
- Mudar o Static ID do master se propaga ao assinante no refresh/publish. Copiar **sem** subscription gera Static ID novo a partir do novo nome. Copiar **com** subscription reaproveita o Static ID do master (vale para REST Data Sources, Email Templates, Search Configurations, Data Load Definitions, JSON Sources). Report Layouts copiados para outra app recebem Static ID novo.
- A Oracle recomenda tratar Static ID como identificador permanente: trocar exige corrigir manualmente chamadas de API que usam o ID antigo, e ferramentas de comparação perdem a correlação entre versões.

Fonte: [About the Logic Resolving Dependencies](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-shared-component-subscriptions.html), [Changed Behavior: Matching Shared Components Across Applications / Static ID Changes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html), [New Features: Static ID Added](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### Component Groups: copiar e assinar vários shared components de uma vez

Um **Component Group** é uma coleção de shared components já existentes na app, usada para copiar, assinar e dar refresh em lote. Pode conter: Application Items, Processes, Computations, Settings, Build Options, Lists, Search Configurations, Data Load Definitions, REST Data Sources, Authentication e Authorization Schemes, roles de Application Access Control, Email Templates, LOVs, Plug-ins, Component Settings (só de componentes nativos), Shortcuts, Map Backgrounds, Report Layouts e Text Messages.

Fluxo:
- **Criar**: *Other Components > Component Groups > Create*, nome único na app; depois *Assign Components*, escolha o tipo e os componentes. Pegadinha documentada: atribua (Assign ou Assign and Assign More) **antes** de trocar o tipo de componente; trocar o tipo sem atribuir descarta a seleção.
- **Copiar de outra app**: *Copy from another app*, marque **Subscribe** nesse passo (depois de copiado não dá mais para assinar o grupo). Revise a coluna de ações: *Add* (cria), *Refresh* (reaproveita existente após refresh), *Replace* (substitui pelo master), *Reuse* (reaproveita como está).
- **Refresh** do grupo atualiza só os membros com status `Needs refresh`; ações possíveis incluem também *Refresh and Assign* e *Unassign*.
- **Publish** exige que algum membro tenha mudado.
- **Unsubscribe** do grupo desfaz a subscription de todos os membros. **Delete** apaga o grupo e as atribuições, não os componentes.

Fonte: [Using Component Groups](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-component-groups.html)

### Theme Applications e Library Applications

O 26.1 tem tipos de aplicação para centralizar reuso:
- **Library application**: contém component groups de shared components (listas, LOVs, workflows…). Apps *Standard* ou *Boilerplate* assinam esses grupos e são avisadas para dar refresh quando o grupo de origem muda.
- **Theme application**: contém tudo do tema. Apps assinantes usam esse tema e recebem aviso quando ele muda.

Criar uma Theme application: crie uma app, apague todas as páginas (*Utilities > Cross Page Utilities > Delete Multiple Pages*), em *Edit Application Definition > Properties* mude **Application Type** para *Theme*, crie os shared components e agrupe-os em component groups.

Fonte: [Managing Theme and Library Applications](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/theme-library-pattern-apps.html), [Creating Theme Applications](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/theme-applications.html)

### APEX_SHARED_COMPONENT: refresh e publish por PL/SQL

O pacote `APEX_SHARED_COMPONENT` (só em instalações completas do APEX) automatiza refresh e publish. No 26.1 as duas APIs também aceitam temas.

```sql
APEX_SHARED_COMPONENT.PUBLISH ( p_component_type IN t_component_type, p_component_id IN NUMBER );
APEX_SHARED_COMPONENT.REFRESH ( p_component_type IN t_component_type, p_component_id IN NUMBER );
```

Constantes de tipo (`t_component_type`): `c_app_computation`, `c_app_item`, `c_app_process`, `c_app_setting`, `c_authentication`, `c_authorization`, `c_build_option`, `c_component_group`, `c_component_setting` (`PLUGIN_SETTINGS`), `c_custom_map_bkg`, `c_data_load`, `c_email_template`, `c_list`, `c_lov`, `c_message`, `c_plugin`, `c_report_layout`, `c_search_config`, `c_shortcut`, `c_user_group` (`APP_ACL`), `c_rest_data_source` (`WEB_SOURCE`), `c_duality_view`, `c_json_source`, `c_ai_config`. Status: `c_status_up_to_date`, `c_status_needs_refresh`, `c_status_unknown`.

Exemplo (refresh de tudo que está desatualizado na app 100, a partir da view `apex_subscribed_components`):

```sql
begin
    apex_util.set_workspace( p_workspace => 'WKSP_EXEMPLO' ); -- só fora de uma sessão APEX
    for l in ( select component_type, component_id
                 from apex_subscribed_components
                where application_id = 100
                  and subscription_status <> apex_shared_component.c_status_up_to_date )
    loop
        apex_shared_component.refresh( p_component_type => l.component_type,
                                       p_component_id   => l.component_id );
    end loop;
    commit;
end;
/
```

Fonte: [APEX_SHARED_COMPONENT Global Constants](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_SHARED_COMPONENT.Global-Constants.html), [REFRESH Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_SHARED_COMPONENT.REFRESH-Procedure.html), [PUBLISH Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_SHARED_COMPONENT.PUBLISH-Procedure.html)

### Subscription Status "Could not determine, needs refresh" depois de upgrade ou import

**Sintoma:** após atualizar para o 26.1 (ou importar uma app de versão anterior), componentes assinados aparecem com status "Could not determine, needs refresh".
**Causa:** a nova coluna Static ID muda o cálculo do status. Afeta Authentication e Authorization Schemes, Component Groups, Computations, LOVs, Map Backgrounds, Build Options, Application Processes, Lists, Plug-ins (com Action Templates ou Attribute Groups), REST Data Sources, JSON Sources e Data Load Definitions.
**Correção:** clique **Refresh** no componente assinante ou **Publish** no master para recalcular o status.

Fonte: [Changed Behavior: Subscription Status Changes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html)

### Import falha porque o master de uma subscription não existe no workspace

**Sintoma:** a instalação de uma app exportada no 26.1 termina com erro de componentes master ausentes.
**Causa:** o export agora leva o ID da app master, o Static ID e o ID interno do master. No import, o APEX verifica se a app e os componentes master existem no workspace de destino; se faltar algum, a instalação falha.
**Correção:** na página de mapeamento de subscriptions do import, escolha o **Subscription Mode** adequado ou remapeie para outra app; por script, use `apex_application_install.set_subscription_mode` e `set_subscription_mapping` antes de instalar.
**Prevenção:** instale primeiro a app master (Theme/Library application) no workspace de destino.

Fonte: [Changed Behavior: Exporting and Importing Applications with Subscribed Components](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html)

---

## 2. Lógica de aplicação: Application Items, Processes, Computations, Settings, Build Options, Component Settings e Shortcuts

### Application Items: o que são, escopo, Session State Protection e escape

**Application items** guardam session state que não aparece na tela e não pertence a uma página. São preenchidos por computations, processes ou valores passados na URL; leia-os como `:NOME` (SQL/PL/SQL), `&NOME.` (substituição) ou `v('NOME')`.

Atributos (Shared Components > Application Logic > Application Items > Create):

| Atributo | Valores | Observações |
|---|---|---|
| Name | texto | nome do item, usado como bind variable |
| Scope | *Application* (padrão) / *Global* | *Global*: o valor é o mesmo em todas as apps que compartilham a sessão APEX (mesmos Session Cookie Attributes na autenticação). O escopo tem que ser igual em todas essas apps |
| Security, Session State Protection | *Unrestricted*, *Restricted - May not be set from browser*, *Checksum Required: Application Level*, *User Level*, *Session Level* | ver abaixo |
| Security, Escape Special Characters | On (padrão) / Off | controla o escape automático na substituição `&ITEM.`; deixe On contra XSS, desligue só se o item guarda HTML intencional |
| Configuration, Build Option | build option | liga/desliga o item |

Session State Protection em detalhe:
- **Unrestricted**: pode ser setado pela URL ou por formulário sem checksum. É **obrigatório** quando o valor precisa ser enviado por Ajax (Dynamic Action *Set Value*, *Page Items to Submit*, *Items to Submit* de cascading LOV).
- **Restricted - May not be set from browser**: só processos e computations do servidor alteram o valor; nem URL nem POST. Vale mesmo com Session State Protection desligada na app. Recomendado para itens de contexto (ID da empresa, perfil do usuário).
- **Checksum Required** (Application/User/Session Level): aceita valor na URL somente com checksum gerado pela app (qualquer usuário), pelo mesmo usuário ou pela mesma sessão, respectivamente. Um checksum de nível mais restrito também satisfaz os níveis mais amplos.

Em APEXlang (`appItem`), os padrões são `scope: app`, `sessionStateDataType: varchar` (ou `number`), `sessionStateProtection: restricted` e `escapeSpecialChars: true`. Por isso um `appItem X ( )` vazio no `.apx` já é Restricted.

```
appItem G_ID_EMPRESA (
    security {
        sessionStateDataType: number
        sessionStateProtection: restricted
    }
)
```

As abas *Utilization* e *History* da página Application Items mostram onde cada item é usado e as últimas alterações.

Fonte: [Managing Application Items](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-application-items.html), [APEXlang API Reference: appItem](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Application Item como variável global entre aplicações

Apps grandes muitas vezes são divididas em várias aplicações no mesmo workspace que compartilham a sessão (mesmo nome de cookie na autenticação). Para compartilhar poucas variáveis globais entre elas (dados do usuário, empresa atual numa app multi-tenant):

1. Crie um application item **com o mesmo nome** em cada app.
2. **Scope** = *Global*.
3. **Session State Protection** = *Restricted*.

A documentação recomenda manter o número de variáveis globais pequeno.

Fonte: [About Creating an Application Item that Functions as a Global Variable](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-application-items.html)

### Application Processes: pontos de execução e quando usar

Um **application process** roda um bloco de código (PL/SQL ou JavaScript MLE) no mesmo ponto em **todas** as páginas da app, a menos que uma condição restrinja. Exemplo clássico: um processo *On Load: Before Header* que calcula `TOTAL_CART_ITEMS` para uma região da Global Page mostrar em toda página.

Atributos de criação (Shared Components > Application Processes > Create): *Name*, *Sequence* (ordem entre processos do mesmo ponto), *Point*, *Language*, *Code*, *Do not validate code (parse at runtime only)*, *Condition Type* + *Expression 1*. Depois de criado também há Authorization Scheme, Build Option e mensagens de erro.

Pontos de execução no APEXlang (`appProcess > execution > point`, padrão `beforeHeader`): `afterAuthentication`, `newSession` (On New Instance), `beforeHeader`, `afterHeader`, `beforeRegions`, `afterRegions`, `beforeFooter`, `afterFooter`, `afterSubmit`, `processing`, `ajaxCallback` (On Demand). O tipo (`type`) aceita quase todos os tipos de processo de página (`executeCode`, `sendEMail`, `invokeApi`, `plugin/<nome>` etc.).

Quando usar cada um:
- **On New Instance** (`newSession`): roda uma vez quando a sessão nasce. Bom para valores que não dependem do usuário logado.
- **After Authentication**: roda após o login. Bom para carregar dados do usuário (perfil, empresa, permissões) uma vez por sessão.
- **On Load / On Submit**: só quando o valor precisa ser recalculado a cada página. Custa uma execução por request.
- Com várias apps na mesma sessão (cookie compartilhado), On New Instance e After Authentication disparam na primeira requisição de cada app e na primeira requisição autenticada.

Quando não usar: lógica de uma só página (crie processo de página). Processos sem condição em *Before Header* rodam inclusive na página de login (usuário `nobody`).

Fonte: [Understanding Application Processes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-application-processes.html), [APEXlang API Reference: appProcess](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### On Demand application process: chamada por Ajax e por URL

Um processo **On Demand** (ponto `ajaxCallback`) só roda quando chamado: por um processo de página do tipo On Demand ou por Ajax do navegador (por exemplo, `apex.server.process`). A documentação recomenda criar On Demand **na página** sempre que possível. Os criados no nível da app nascem com a authorization **Must Not Be Public User**, para não poderem ser chamados por sessões não autenticadas.

Chamada por URL:

```
f?p=application_id:page_id:session:APPLICATION_PROCESS=process_id
```

Regras: o page_id é só um marcador sintático (pode ser a página atual ou o alias); valem a authorization do processo, a da app e as condições; session state pode ser passado na URL, mas *clear cache* é ignorado; o processo pode ser referenciado pelo ID ou pelo nome (case-preserved; usa o primeiro com aquele nome).

Fonte: [On Demand Application Processes / About Running an On Demand Process from a Page Request](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-application-processes.html)

### On Demand process por URL devolve página em branco

**Sintoma:** a chamada `f?p=...:APPLICATION_PROCESS=...` retorna uma página vazia, sem erro.
**Causa:** falhas de autenticação, authorization ou condição do processo não geram mensagem visível para o usuário final. Só quem está logado no App Builder vê o erro.
**Correção:** teste logado como desenvolvedor para ver a mensagem; confira a authorization (o padrão *Must Not Be Public User* bloqueia sessão pública), a condição e se o nome/ID está correto.

Fonte: [About Running an On Demand Process from a Page Request](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-application-processes.html)

### Mensagens de erro de application process

*Source, Process Error Message* define o texto exibido quando o processo gera exceção não tratada. Onde a mensagem aparece depende do ponto:
- Pontos *On Submit - After Page Submission - Before Computation and Validations* e *... After Computations and Validations*: escolha **Inline in Notification** (área de notificação do page template, padrão) ou **On Error Page**.
- Demais pontos: sempre numa página de erro separada.

Com tabular form manual (chamadas `APEX_ITEM` no SQL), use *On Error Page*, senão as alterações do usuário se perdem quando a página é renderizada de novo; na página de erro o botão Voltar do navegador preserva os valores.

Fonte: [Creating Application Process Error Messages](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-application-processes.html)

### Application Computations: atribuir valor a item em todas as páginas

Uma **application computation** atribui valor a **um** item (de aplicação ou de página) no mesmo ponto em várias páginas. Os tipos são os mesmos da computation de página: valor estático, item, SQL (valor único ou vários valores separados por dois-pontos), expressão, function body, preference.

Atributos: *Item, Sequence*; *Item, Computation Item*; *Frequency, Computation Point* (no APEXlang: `newSession` (padrão), `afterAuthentication`, `beforeHeader`, `afterHeader`, `beforeRegions`, `afterRegions`, `beforeFooter`, `afterFooter`, `afterSubmit`; *After Submit* só roda depois que a página é exibida e enviada); *Computation Type* e *Computation*; *Computation Error Message*; *Authorization Scheme*; *Condition*; *Build Option*; *Advanced, Static ID*.

Exemplo da documentação (guardar a última página visitada, para um botão "voltar"):

```plsql
begin
   :LAST_PAGE    := nvl(:CURRENT_PAGE, :APP_PAGE_ID);
   :CURRENT_PAGE := :APP_PAGE_ID;
   return :LAST_PAGE;
end;
```

Quando preferir computation a processo: quando o objetivo é só setar um item. Processo é para lógica com efeitos colaterais ou vários itens.

Fonte: [Understanding Application Computations](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-application-computations.html), [APEXlang API Reference: appComputation](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Application Settings e a API APEX_APP_SETTING

**Application Settings** são opções de configuração nomeadas no nível da app (feature flags de valor, URLs de integração, limites). Ao contrário de substitution strings, podem ser lidas e alteradas em runtime via API e sobreviver a upgrades.

Atributos: *Static ID* (identificador usado nas APIs; trocar quebra chamadas existentes), *Value* (padrão), *Value Required* (On/Off), *Valid Values* (lista separada por vírgula; se definida, só esses valores são aceitos ao mudar), *On Upgrade Keep Value* (On = mantém o valor do ambiente instalado num upgrade; use quando o valor é configurado em produção por `SET_VALUE`), *Build Option*, *Comments*.

```sql
APEX_APP_SETTING.GET_VALUE ( p_name IN VARCHAR2, p_raise_error IN BOOLEAN DEFAULT FALSE ) RETURN VARCHAR2;
APEX_APP_SETTING.SET_VALUE ( p_name IN VARCHAR2, p_value IN VARCHAR2, p_raise_error IN BOOLEAN DEFAULT FALSE );
```

```plsql
declare
    l_value varchar2(4000);
begin
    l_value := apex_app_setting.get_value( p_name => 'ACCESS_CONTROL_ENABLED' );
    apex_app_setting.set_value( p_name => 'ACCESS_CONTROL_ENABLED', p_value => 'Y' );
end;
```

Regras: o nome é case-insensitive. Erro se o setting não existe ou se o build option dele está desligado. `SET_VALUE` falha se o valor for nulo num setting obrigatório ou fora dos *Valid Values*; nunca grava quando há erro; com `p_raise_error => false` os erros são silenciados. **Settings assinados de outra app não são alterados por `SET_VALUE`** (com `p_raise_error => true`, gera erro).

APEXlang: `appSetting` com `staticId`, `value { staticValue, onUpgradeKeepValue }`, `validation { required, validValues }`, `config { buildOption }`.

Fonte: [Managing Application Settings](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-app-settings.html), [APEX_APP_SETTING.GET_VALUE](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APP_SETTING.GET_VALUE-Function.html), [APEX_APP_SETTING.SET_VALUE](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APP_SETTING.SET_VALUE-Procedure.html)

### APEX_APP_SETTING.SET_VALUE não altera o valor

**Sintoma:** `apex_app_setting.set_value` executa sem erro, mas o valor não muda.
**Causa:** com `p_raise_error` no padrão `FALSE`, os erros são suprimidos. Os casos documentados: setting inexistente, build option associado desligado, valor nulo num setting *Value Required*, valor fora de *Valid Values* ou setting assinado de outra app.
**Correção:** chame com `p_raise_error => true` para ver o motivo; corrija o valor ou altere o master, no caso de setting assinado.

Fonte: [SET_VALUE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APP_SETTING.SET_VALUE-Procedure.html)

### Build Options: incluir ou excluir componentes por ambiente

**Build options** ligam ou desligam componentes (páginas, regiões, itens, validações, processos, entradas de lista, LOVs, breadcrumbs, app items, settings…). Com status **Include** o componente faz parte da app em runtime; com **Exclude** o engine age como se ele não existisse.

Atributos: *Build Option* (nome), *Status* (Include/Exclude; padrão APEXlang `exclude`), *Default on Export* (status gravado no export), *On Upgrade Keep Status* (mantém o status do ambiente instalado), *Static ID*, *Comments*. Para aplicar: no Page Designer, selecione o componente e escolha *Configuration, Build Option*. Depois de aplicado, o menu de contexto da árvore Rendering permite alternar o build option.

Casos de uso documentados: funcionalidades por tipo de instalação; esconder funcionalidade incompleta em teste/produção; "comentar" funcionalidade antes de apagar de vez.

O build option **Commented Out** vem em toda app nova e é o que permite comentar componentes pelo menu de contexto do Page Designer; apagá-lo remove esse recurso.

APIs (26.1): use `APEX_APPLICATION_ADMIN.GET_BUILD_OPTION_STATUS` / `SET_BUILD_OPTION_STATUS`. As equivalentes em `APEX_UTIL` estão marcadas como deprecated na API Reference, embora o capítulo de build options do App Builder ainda cite `APEX_UTIL`.

```plsql
begin
    apex_application_admin.set_build_option_status (
        p_application_id => 100,
        p_static_id      => 'novo_modulo',
        p_build_status   => apex_application_admin.c_build_option_status_include );
end;
```

`GET_BUILD_OPTION_STATUS (p_application_id, p_build_option_name)` aceita o Static ID e, por compatibilidade, cai para o nome se não achar.

Outros pontos:
- **Remove Components** (na página do build option, região *Associated Components*) **apaga** os componentes associados. Apagar o build option **não** apaga os componentes.
- *Export Application Components > Build Options Status* exporta só o status, útil para ligar em produção uma funcionalidade publicada como Exclude.
- Abas *Utilization* (aparece depois do primeiro build option) e *History*.

Fonte: [About Build Options](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-build-options.html), [Creating and Editing Build Options](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-and-editiing-build-options.html), [Selecting a Build Option](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/selecting-build-option.html), [Deleting Build Options and Associated Components](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/deleting-build-options-associated-components.html), [Exporting Build Options or Build Option Status](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/exporting-build-options-or-status.html), [SET_BUILD_OPTION_STATUS Procedure Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION_ADMIN.SET_BUILD_OPTION_STATUS-Procedure-Signature-2.html)

### Component Settings: padrões de app para componentes nativos e plug-ins

**Component Settings** (Other Components > Component Settings) definem valores de nível de aplicação para componentes nativos e plug-ins instalados. A lista varia conforme a app. Todos aceitam subscription (*Subscribe From*, *Refresh Component Settings*). Os documentados no 26.1:

| Componente | Configurações |
|---|---|
| Checkbox | *Checked Value* e *Unchecked Value* (até 255 caracteres; Unchecked vazio grava NULL) |
| Color Picker | *Display As* (Popup, Inline, Color-only Popup, Native Color Picker); *Mode* (Simple ou Full com Hex/HSL/RGB) |
| Date Picker | *Appearance & Behavior* (Show Week, Month Picker, Year Picker, Paginate by Multiple Months, Show Today Button, Show Clear Button); *Days Outside Month* (Hidden, Selectable, Visible); *Time Increment*; *Show On* (Item Focus ou Icon Click) |
| Geocoded Address | *Geocoder Match Mode* (Exact, Relax Street Type, Relax House Number, Relax Street Name, Relax Postal Code, Relax All); *Display As* (List/Grid View); *Map Preview*; *Background*; *Height* |
| Interactive Report | *Actions Menu Structure*: Interactive Grid (igual ao IG) ou Legacy |
| Maps | *Use Vector Tile Layers* (padrão em apps criadas a partir do 22.2) |
| Oracle Cloud Applications (BOSS) REST Service | *Advanced Settings* (com orientação do Suporte) |
| Oracle Cloud Applications (SaaS) REST Service | *Sandbox Name* |
| Region Display Selector | *Include Slider* quando os nomes não cabem |
| Select Many | *Display Value As*: Chips ou Comma-separated list |
| Server Side Geocoding | *Match Mode* |
| Show AI Assistant | *AI Avatar Type* e *User Avatar Type* (Default, Icon Classes, Image URL, Initials) |
| Star Rating | *Default Icon*, *Active/Inactive Color*, *Tooltip* com `#VALUE#` |
| Switch | *Display Style* (Switch, Pill Button, Select List), *On/Off Value* e *On/Off Label* |

Pegadinha: o valor gravado por Checkbox e Switch é o definido aqui (por exemplo `Y`/`N`), independentemente do tipo da coluna no banco.

Fonte: [Managing Component Settings](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-component-settings.html)

### Shortcuts: trechos reutilizáveis de HTML, texto ou PL/SQL

**Shortcuts** guardam uma vez um trecho usado em muitos lugares e são referenciados por `"STATIC_ID"` (entre aspas duplas, case-insensitive). Onde funcionam: Region Source de regiões HTML Text (with shortcuts), Header/Footer Text de regiões, Label, Pre/Post Element Text e Default Value de itens, atributos de Region Templates, e o atributo *Function and Global Variable Declaration* de páginas e page templates.

Tipos: *Function Body returning VARCHAR2* (PL/SQL Function Body), *HTML Text*, *HTML Text with Escaped Special Chars*, *Image*, *Text with JavaScript Escaped Single Quotes* (para usar dentro de string JavaScript), *Message* (o nome do shortcut é o nome de uma text message e expande para o texto no idioma atual; não tem corpo) e *Message with JavaScript Escaped Special Quotes*. Limite: corpo com menos de 30.000 caracteres. Atributos: *Static ID*, *Type*, *Shortcut*, *Error Text*, *Build Option*.

Quando não usar: para HTML reutilizável com dados e parâmetros, prefira Template Components (seção 11) ou text messages com parâmetros (seção 14).

Fonte: [Using Shortcuts](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-shortcuts.html)

---

## 3. Lists of Values (LOV) como shared component

> O uso de LOVs em itens de página e o detalhe dos itens list-driven também aparecem no documento 02 desta pasta (seção 12). Aqui o foco é o shared component.

### O que é uma LOV, estática × dinâmica e onde é usada

Uma **List of Values (LOV)** define o conjunto de escolhas válidas de itens do tipo Select List, Select One, Select Many, Radio Group, Checkbox Group, Combobox, Popup LOV, Shuttle, List Manager, Text Field with Autocomplete e de colunas de relatório/IG.

- **Estática**: valores digitados pelo desenvolvedor (display, return e sequência).
- **Dinâmica**: valores de uma fonte de dados: banco local (Table, SQL Query, Function Returning SQL), REST Enabled SQL, REST Data Source, Duality View, JSON Source ou Sample Data.

Cada escolha tem **Display Value** (o que o usuário vê) e **Return Value** (o que vai para o item). Item de seleção única guarda o return value; item multisseleção guarda os return values separados por `:` (separador configurável). Exemplo: escolher ACCOUNTING e RESEARCH num multisseleção grava `10:20`.

Vantagens da LOV compartilhada: reuso em qualquer página, manutenção num só lugar e recursos que a LOV local não tem: várias colunas de exibição, coluna de ícone, coluna de agrupamento, condição por entrada estática e fontes remotas.

Fonte: [About Lists of Values](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-lists-of-values.html), [Defining the List of Values](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/defining-list-values.html), [Additional Shared LOV Features](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/additional-shared-lov-features.html)

### Criar LOV estática compartilhada e usá-la num item

1. Shared Components > Other Components > **Lists of Values** > Create > *From Scratch*.
2. *Name* e *Type* = **Static**.
3. Digite Display Value e Return Value por sequência. Sem Return Value, ele é igual ao Display Value. Os valores aparecem na ordem digitada.
4. Depois de criada, a LOV pode ganhar, por entrada, **build option** e **condição de exibição** (só na versão compartilhada).
5. No Page Designer, no item: *List of Values, Type* = **Shared Component**; *List of Values* = a LOV; ajuste *Display Extra Values* e *Display Null Value*.

LOV estática **local** (definida no item, *Type: Static Values*) tem a opção **Sort at Runtime**, que ordena alfabeticamente pelo display. Desligue quando a ordem digitada importa (Sim antes de Não, faixas numéricas).

APEXlang de uma LOV estática (cada `entry` tem `sequence`, `display`, `return` e opcionalmente `serverSideCondition`, `config.buildOption` e `globalization.template`):

```
lov status (
    name: STATUS
    source {
        location: staticValues
    }
    entry pendente (
        sequence: 1
        display: Pendente
        return: PENDENTE
    )
    entry fechado (
        sequence: 2
        display: Fechado
        return: FECHADO
    )
)
```

Edição em massa: a aba **Grid Edit** da página Lists of Values edita o display text de todas as LOVs estáticas de uma vez (útil para padronizar textos).

Fonte: [Creating a Static List of Values at the Application-Level](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-static-list-of-values-at-application-level.html), [Creating a Static List of Values](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-static-List-of-values.html), [Editing an Existing List of Values](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-existing-list-of-values.html), [APEXlang API Reference: lov/entry](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Criar LOV dinâmica e mapear colunas de retorno, exibição, ordenação, grupo e ícone

1. Create > *From Scratch* > *Type* = **Dynamic**.
2. *List of Values Source*: **Data Source** (Local Database, REST Enabled SQL, REST Data Source…) e **Source Type** (Table, SQL Query ou PL/SQL Function Returning SQL).
3. **Column Mappings**: *Return Column* e *Display Column*. Colunas de exibição adicionais se definem depois, para itens que mostram várias colunas (Popup LOV).

Mapeamentos disponíveis (APEXlang `columnMapping` da `lov`):

| Propriedade | Função |
|---|---|
| `return` | coluna de retorno (obrigatória) |
| `display` | coluna exibida |
| `defaultSort` + `sortDirection` | ordenação padrão (`ascNullsLast`, `ascNullsFirst`, `descNullsLast`, `descNullsFirst`) |
| `group` + `groupSortDirection` | coluna de agrupamento (exige `defaultSort`) |
| `icon` | coluna com a classe do ícone (ex.: `fa-user`) |
| `quickPickRank` | ranking para quick picks (fontes locais/remotas) |
| `oracleTextIndex` | índice Oracle Text para busca |

Colunas adicionais são filhos `column` da `lov` (com `columnName`, `show`, heading e layout). Na Popup LOV elas podem ser exibidas, pesquisadas e devolvidas para outros itens. Em Select One, Select Many e Combobox, as colunas extras e o ícone entram na formatação customizada de cada entrada.

Exemplo de LOV dinâmica por SQL com ícone:

```sql
select ename as d,
       empno as r,
       case job when 'MANAGER' then 'fa-user' else 'fa-user-o' end as icon
  from emp
 where deptno = :P2_DEPARTMENT
 order by ename
```

Outras propriedades da `lov` no APEXlang: `source.whereClause` (para tipo Table), `source.optimizerHint`, `remoteCache` (fontes remotas: `allUsers`, `user`, `session` + `timeout`), `externalFilterAndOrderBy` e `localPostProcessing` (REST Data Source, Duality View, JSON Source), `advanced.staticId` e `subscription.master`.

Fonte: [Creating a Dynamic List of Values at the Application-Level](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-dynamic-list-of-values-at-application-level.html), [Configuring Cascading Lists](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configuring-cascading-lists.html), [APEXlang API Reference: lov](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### LOV local × compartilhada, conversão e relatórios de LOV

- LOV **local**: definida no próprio item (Static Values ou SQL Query). A consulta deve ter duas colunas: **a primeira é o display e a segunda o return** (é comum, mas não obrigatório, usar os aliases `d` e `r`). Não é reutilizável. A Oracle recomenda criar LOVs como shared components sempre que possível.
- LOV **compartilhada**: mapeia colunas por nome (`columnMapping`), aceita várias colunas, ícone, grupo e fontes remotas.

Converter local em compartilhada: Lists of Values > aba **Locally Defined** > botão **Convert** na linha. O App Builder cria a LOV compartilhada e ajusta o item original para usá-la.

Abas da página Lists of Values: *Lists of Values*, *Edit Null Text* (texto nulo de todas as LOVs), *Locally Defined*, *Grid Edit*, *Conditional Entries*, *Subscription*, *Utilization*, *History*.

Fonte: [Defining a Local List of Values](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/defining-local-list-values.html), [Converting Local LOVs to Shared](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/converting-local-lovs-shared.html), [Accessing Lists of Values Reports](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/accessing-lists-of-values-reports.html)

### Session state dentro da LOV: bind variables

Para filtrar a LOV por um item, use bind variable:

```sql
select ename, empno from emp where deptno = :P1_DEPTNO
```

A documentação reconhece que referenciar session state deixa a LOV menos reutilizável, mas recomenda essa abordagem como boa prática (em vez de concatenar valores). A LOV só funciona se o item tiver valor válido. Para LOVs compartilhadas usadas em várias páginas, prefira application items (iguais em todas as páginas) a page items.

Fonte: [About Referencing Session State Within a List of Values](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-referencing-session-state-within-list-of-values.html)

### Cascading LOV: Parent Items, Items to Submit e Parent Columns no Interactive Grid

Num **cascading LOV** o valor de um item determina as opções de outro. Tipos com suporte: Select List, Shuttle, Checkbox, Radio Group, Popup LOV, List Manager (e os novos Select One/Select Many/Combobox).

Configuração:
1. A LOV do item filho referencia o pai por bind variable (`where deptno = :P2_DEPARTMENT`).
2. No item filho, em *Cascading List of Values*, preencha **Parent Item(s)** com o pai.

Comportamento em runtime: quando o pai muda, o filho é **limpo** e a lista é **recarregada**. Itens adicionais usados na query vão em **Items to Submit**: são enviados no refresh, mas a mudança deles **não** dispara limpeza nem recarga. Vale para vários níveis (marca > modelo > motor). Para usar ícone ou colunas extras no filho, ele precisa referenciar uma LOV **compartilhada**.

No Interactive Grid editável é igual: a LOV da coluna referencia a coluna pai pelo nome como bind variable e a propriedade é **Parent Column(s)**.

Fonte: [Configuring Cascading Lists](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configuring-cascading-lists.html), [Creating a Cascading List of Values](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-cascading-list-of-values.html)

### Cascading LOV não traz as opções certas (item não chega ao servidor)

**Sintoma:** o filho recarrega, mas a lista vem vazia ou filtrada pelo valor antigo do pai ou de outro item usado na query.
**Causa:** (1) o item usado na query não está em *Parent Item(s)* nem em *Items to Submit*, então o servidor usa o session state antigo; (2) o item tem Session State Protection diferente de *Unrestricted*: itens cujo valor é enviado por Ajax (Cascading LOV, Page Items to Submit, Set Value) precisam ser *Unrestricted*.
**Correção:** liste todos os itens da query em Parent Items ou Items to Submit e deixe esses itens com SSP *Unrestricted*.

Fonte: [Configuring Cascading Lists](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configuring-cascading-lists.html), [Creating an Application Item (Session State Protection)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-application-items.html)

### Itens list-driven: tipos, Null Display Value e Display Extra Values

| Seleção | Itens | Destaques |
|---|---|---|
| Única | Select List, Select One, Radio Group | Select One busca ao digitar, aceita ícones e formatação da entrada |
| Única ou múltipla | Checkbox Group, Combobox, Popup LOV | Combobox aceita valor digitado fora da lista; Popup LOV mostra e pesquisa colunas extras e devolve colunas a outros itens |
| Múltipla | Select Many, List Manager, Shuttle | Select Many filtra ao digitar; Shuttle tem controles de mover e reordenar |
| Texto livre | Text Field with Autocomplete | usa só a coluna de retorno |

Select List, Radio Group e Popup LOV aceitam uma entrada para `NULL`: *Display Null Value* = On e *Null Display Value* = texto (por exemplo `- Selecione -` ou `Todos` em filtros). **Display Extra Values** decide se um valor de session state que não está na LOV ainda aparece. No 26.1, Select One, Select Many, Combobox e Autocomplete têm rolagem infinita e não ficam limitados a *Maximum Values in List*.

Fonte: [List-Driven Items Available](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/list-driven-items-available.html), [Creating a Dynamic List of Values at the Application-Level](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-dynamic-list-of-values-at-application-level.html), [New Features: Infinite Scroll](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### Traduzir dados de uma LOV dinâmica: Dynamic Translations e APEX_LANG.LANG

Texto que vem do banco (como os nomes de uma LOV por SQL) não entra no XLIFF. Para traduzi-lo, use **Dynamic Translations**: Shared Components > Application Translations > *Translation Utilities* > *Dynamic Translations* > Create, informando *Language*, *Translate From Text* e *Translate To Text*. Na query, aplique `APEX_LANG.LANG`:

```sql
select apex_lang.lang(nome) d, id r from cor order by 1
```

`APEX_LANG.LANG (p_primary_text_string, p0..p9, p_primary_language)` devolve o texto traduzido para o idioma atual (definido pelo *Application Language Derived From*), com substituição de `%0`..`%9`.

Fonte: [Translating Data That Supports List of Values](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/translating-data-that-supports-list-of-values.html), [LANG Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/LANG_Function.html)

---

## 4. Lists, Navigation Menu e Navigation Bar

### Lists: coleção compartilhada de links, estática ou dinâmica

Uma **List** é uma coleção compartilhada de links exibida por uma região do tipo **List**, com aparência dada pelo **list template** (menus, abas, badges, cards, wizard progress…). Duas formas:
- **Static list**: entradas definidas no Builder (label + destino página/URL), cada uma com condição, authorization e build option.
- **Dynamic list**: entradas vindas de uma SQL Query ou Function Returning SQL Query, executada em runtime.

Passos: criar a lista (Create List Wizard, *Type* Static ou Dynamic), adicionar entradas e colocar numa página como região List (*Source, List*). O wizard pode criar a região na página atual ou em cada página de destino. **Apagar uma lista apaga as regiões que a usam.**

Fonte: [About Static and Dynamic Lists](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-static-and-dynamic-lists.html), [Creating Lists](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-lists.html), [Adding a List to a Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/adding-list-to-page.html), [Deleting a List](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/deleting-a-list.html)

### Atributos de uma entrada de lista estática

| Grupo | Atributo | Notas |
|---|---|---|
| Entry | *Parent List Entry* | cria hierarquia (sublista) |
| | *List Entry Label*, *Sequence* | texto e ordem |
| | *Icon* | classe Font APEX, ex.: `fa-cloud`, `fa-exclamation-circle u-danger-text` |
| | *Icon Attributes*, *Alt Attribute* | aceitam `#LIST_LABEL#` |
| Target | *Target Type* | *Page in this Application* ou *URL* |
| | Page, reset pagination, Printer Friendly, Request, Clear Cache, Set these items / With these values | valores de item não podem conter `:`; vírgulas exigem o valor entre barras invertidas (`\1234,56\`) |
| Subentries | *List* | lista que alimenta as subentradas |
| Current List Entry | *List Entry Current for Pages Type* + condição | decide quando a entrada usa o template *current* |
| Conditions / Authorization / Configuration | Condition Type, Authorization Scheme, Build Option | |
| Click Counting | Count Clicks, Click Count Category | para links externos |
| Advanced | Static ID | |
| User Defined Attributes | atributos `#A01#`…`#A10#` | usados pelo list template (ex.: badge) |
| (26.1) | **Link Attributes** | atributos HTML extras do link (em listas dinâmicas, coluna `link_attributes`) |

Utilitários da lista (Tasks): copiar entradas entre listas, reparentar entradas, limpar entradas órfãs (com pai fora da lista), resequenciar de 10 em 10.

Fonte: [Creating Static Lists](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-static-lists.html), [Editing List Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-list-attributes.html), [New Features: List Entry Custom Link Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### Dynamic list: sintaxe posicional da consulta (até 17 colunas)

A consulta de uma dynamic list é interpretada **pela posição** das colunas no `SELECT`; os aliases são ignorados. Mínimo de 2 colunas, máximo de 17; use `NULL` como marcador para pular posições.

| Col | Função | Tipo | Obrigatória |
|---|---|---|---|
| 1 | Level (profundidade; `NULL` se não hierárquica; raiz ≥ 1; nível 0 é pulado) | NUMBER | sim |
| 2 | Label | VARCHAR2 | sim |
| 3 | Target URL | VARCHAR2 | não |
| 4 | Is Current? (`'YES'`, `'NO'`, NULL) | VARCHAR2 | não |
| 5 | Icon Name | VARCHAR2 | não |
| 6 | Image attributes | VARCHAR2 | não |
| 7 | Image ALT text | VARCHAR2 | não |
| 8–17 | User attribute 1..10 (`#A01#`..`#A10#`) | VARCHAR2 | não |

Exemplo com link com checksum, ícone e badge (coluna 8 é usada pelo template *Badge List*):

```sql
select null      c1_level,
       ename     c2_label,
       apex_page.get_url(p_page => 10, p_items => 'P10_EMPNO', p_values => empno) c3_target,
       null      c4_is_current,
       'fa-user' c5_icon,
       null      c6_icon_attrs,
       null      c7_alt,
       sal       c8_badge
  from emp
 order by ename
```

Hierarquia: devolva `level` na coluna 1 com `connect by prior empno = mgr start with mgr is null`. Para Function Returning SQL, o literal `q'[ ... ]'` facilita consultas multilinha.

Fonte: [Understanding Dynamic List Syntax](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-dynamic-lists.html)

### Listas hierárquicas e list templates "with Sublist"

Para hierarquia: (1) use um list template que suporte sublistas (convenção de nome "with Sublist"; tecnicamente, o atributo *List Template Current with Sub List Items* do template não é nulo) e (2) defina o *Parent List Entry* de cada entrada (ou a coluna Level na dynamic list).

Problema conhecido do 26.1: entradas de sublista não entram nos resultados de uma **List Search** configurada sobre a lista que referencia a sublista (correção prevista para versão futura).

Fonte: [About Adding Entries and Sublists to a Static List](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-static-lists.html), [List Templates](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/list-templates.html), [Open Bugs and Known Issues: Sublists](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/open-bugs-known-issues.html)

### Navigation Menu: side, top e mega menu

O **Navigation Menu** é uma lista hierárquica usada como navegação principal (só no Universal Theme 42). O Create Application Wizard cria a lista com as páginas geradas. Ela é editada como qualquer lista (Shared Components > Navigation Menu ou Lists).

Onde e como aparece é definido em *User Interface Attributes > Navigation Menu*:
- **Display Navigation**: On/Off.
- **Navigation Menu List**: qual lista.
- **Position**: *Side* (renderiza em `#SIDE_GLOBAL_NAVIGATION_LIST#` do page template) ou *Top* (`#TOP_GLOBAL_NAVIGATION_LIST#`).
- **List Template** e **Template Options**.

Estilos: **Side Navigation Menu** (árvore expansível; recolhe para barra de ícones conforme o espaço; Template Options controlam se fica oculta ou em ícones quando recolhida), **Top Navigation Tabs** (até ~6 abas; em telas pequenas vai para baixo), **Top Navigation Menu** (barra de menus para hierarquias maiores) e **Top Navigation Mega Menu** (painel que mostra tudo de uma vez).

Migração de temas antigos com tabs só é possível se a app usava um nível de tabs; com dois níveis, converta para um antes.

Fonte: [Managing Navigation Menus](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-navigation-menus.html), [Editing User Interface Attributes: Navigation Menu](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-user-interface-attributes.html)

### Navigation Bar List

A **navigation bar** (canto superior direito no UT) é renderizada no `#NAVIGATION_BAR#` do page template. Em *User Interface Attributes > Navigation Bar*:
- **Implementation**: *List* (usa a lista e o list template escolhidos) ou *Classic* (navigation bar clássica, com entradas próprias em *Classic Navigation Bar Entries*).
- **Navigation Bar List**, **List Template**, **Template Options**.

Fonte: [Managing Navigation Bar Lists](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-navigation-bar.html)

---

## 5. Arquivos estáticos, Email Templates, Report Queries/Layouts e demais componentes

### Static Application Files: upload, diretórios e referência com #APP_FILES#

**Static Application Files** são imagens, CSS, JS e outros arquivos que pertencem a uma aplicação. Ficam no banco junto com a definição da app (ou em armazenamento remoto, ver a seguir).

Criar: Files and Reports > Static Application Files > **Create File**: *Directory* (ex.: `css` ou `css/images`; vazio = raiz), *File Name* (para criar arquivo em branco, como `script.js`) e *Content* (arrastar o arquivo). Editar permite renomear e mudar o diretório. Também dá para baixar um arquivo, **Download as Zip** de todos, *Delete Checked* e *Delete All*.

Referência: use `#APP_FILES#` (em template e HTML), `&APP_FILES.` (substituição), `:APP_FILES` ou `v('APP_FILES')`. A coluna **Reference** do relatório mostra a sintaxe pronta para cada arquivo; para JS ela já inclui `#MIN#`. `APP_IMAGES` é o nome legado de `APP_FILES` (ainda aceito).

```html
<img src="#APP_FILES#icons/app-icon-512.png" alt="">
```

*#APP_FILES# Path* (User Interface Attributes > Advanced): vazio = arquivos guardados com a app no banco. Pode apontar para um diretório do web server ou CDN (`/myFiles/`, `https://cdn.example.com/myFiles/`) por desempenho.

Fonte: [Managing Static Application Files](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-static-application-files.html), [Managing Static Application Files in the Database](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-static-application-files-in-the-database.html), [Specifying the Location of Static Application Files](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/specifying-the-location-of-static-application-files.html), [APP_FILES](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-available-built-in-substitution-strings.html)

### Static Application Files em OCI Object Storage

A app pode guardar os static files num bucket do **OCI Object Storage**. Pré-requisitos: conta OCI e uma Web Credential OCI. Em *Edit Application Definition > Add Object Storage* (wizard *Add Remote File Storage*): *Name* (único no workspace), *Static ID*, *Bucket URL* (`https://objectstorage.<region>.oraclecloud.com/n/<namespace>/b/<bucket>`), *Create Bucket*, *OCI Credential*, *Compartment OCID*. No fim, **Migrate Files to Object Storage** copia os arquivos do banco.

Depois: *Tasks > View Object Storage Files* (mostra os primeiros 1000 arquivos; filtre com *Name starts with*) e *Synchronize Files* (do Object Storage para o banco ou ao contrário).

Fonte: [Managing Static Application Files in Remote Storage](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-static-application-files-in-remote-storage.html)

### Static Workspace Files e #WORKSPACE_FILES#

**Static Workspace Files** funcionam como os de aplicação, mas pertencem ao workspace e servem a **todas** as apps dele (logo corporativo, CSS comum). Referência: `#WORKSPACE_FILES#`, `&WORKSPACE_FILES.`, `:WORKSPACE_FILES` (`WORKSPACE_IMAGES` é o nome legado). Mesma interface: Create File com Directory, Download as Zip, Delete Checked/All.

Quando usar: arquivo comum a várias apps do workspace. Quando não usar: arquivo de uma app só (use Application Files, que vão no export da app).

Fonte: [Managing Static Workspace Files](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-static-workspace-files.html), [WORKSPACE_FILES](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-available-built-in-substitution-strings.html)

### Exportar arquivos estáticos e desempenho no web server

- Export: ZIP pela página de Static Files ou scripts de instalação via *Export Application Components*. No 26.1 o export APEXlang **inclui os static files binários**; quem consome `APEX_EXPORT` deve ler `APEX_T_EXPORT_FILE.contents_blob` para binários, e não só `contents`.
- Desempenho: a recomendação é servir arquivos estáticos pelo web server, com **gzip** habilitado e **cabeçalhos de expiração** para cache no navegador.

Fonte: [About Exporting Static Files](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-exporting-static-files.html), [About Uploading Static Files to Your Web Server](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-uploading-static-files-to-your-web-server.html), [Changed Behavior: APEX_EXPORT Changes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html)

### Email Templates e envio com APEX_MAIL

**Email Templates** (User Interface > Email Templates) definem assunto, formato HTML e texto puro de e-mails, com placeholders `#NOME#`. Pré-requisito: e-mail configurado pelo administrador da instância (no 26.1 as credenciais SMTP também podem ser configuradas no workspace, em Workspace Preferences). `APEX_MAIL` usa `UTL_SMTP`, que precisa estar instalado e funcionando, e o usuário `APEX_260100` precisa de ACL de rede para o host SMTP.

Atributos: *Template Name*, *Static Identifier* (usado pela API), *Email Subject*; *HTML Format* (Header, Body, Footer, e *Advanced, HTML Template* com o esqueleto; *Load Default HTML* traz o padrão); *Plain Text Format*; *Comments*. Há três exemplos prontos (Order Details, Event Reminder, Scheduled Outage), com exemplo de chamada de API.

Uso: processo de página **Send E-Mail** com *Email Template* e o diálogo **Placeholder Values** (valor estático ou item), ou PL/SQL:

```plsql
begin
    apex_mail.send (
        p_to                 => 'pessoa@example.com',
        p_template_static_id => 'CONFIRMACAO_PEDIDO',
        p_placeholders       => q'~{ "NOME_CLIENTE": "Ana", "NUMERO_PEDIDO": 1234 }~' );
    apex_mail.push_queue;
end;
```

Escape: os valores dos placeholders são escapados conforme o contexto (HTML no formato HTML, nada no texto puro). Para HTML intencional use `#NOME!RAW#`; para tirar tags, `#NOME!STRIPHTML#`. Atributos específicos dos email templates aceitam **template directives**. Endereços (To, Cc, Bcc, Reply To) do processo aceitam `&P2_EMAIL.`. A fila e o log de e-mails são acompanhados pelo administrador da instância.

Fonte: [Managing Email Templates](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-email-templates.html), [Sending Email from an Application](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/sending-email-from-an-application.html), [New Features: SMTP Credentials at Workspace Level](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### Report Queries: impressão de relatórios

Uma **Report Query** é uma consulta SQL compartilhada para gerar documentos (PDF, Word, Excel, HTML, XML; com APEX Office Print também PowerPoint, Markdown, CSV e ODF; com Document Generator, PDF/DOCX/XLSX). Só aceita SQL; Function Returning SQL não é suportado.

Criar (Files and Reports > Report Queries > Create): *Report Query Name* (vira parte do request ao usar como destino de link), *Report Layout*, *Output Format* (incluindo *Derive from Item*), *View File As* (Attachment ou Inline), *Include Application and Session Information* (permite usar session state), fonte (Local Database, REST Enabled SQL, REST Source, Duality View, JSON Source) e consultas adicionais (*Add Query*). O passo final mostra a **URL** a usar como destino de botão, entrada de lista ou branch.

Sem layout, o APEX usa um layout genérico (com várias consultas, só o primeiro result set entra). Document Generator e APEX Office Print não suportam layout genérico e exigem o **Data Loop Name** igual ao nome da consulta.

Fonte: [Printing a Report Region by Defining a Report Query](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/printing-report-region-by-defining-report-query.html)

### Report Layouts: formatar Classic Report, Interactive Report e Report Query

Um **Report Layout** formata a saída impressa de regiões classic/interactive report ou de report queries. Sem layout, usa-se o XSL-FO padrão.

| Print server | Tipos de layout |
|---|---|
| Oracle Document Generator Pre-built Function | DOCX, XLSX |
| Oracle Analytics (BI) Publisher | RTF, XSL-FO |
| APEX Office Print | DOCX, XLSX, PPTX, HTML, Markdown, CSV, TXT, ODS, ODT, ODP |
| External (Apache FOP) | XSL-FO |

Tipos: **Generic Columns (XSL-FO)** (funciona com qualquer result set; editável no APEX) e **Named Columns** (layout preso a uma lista de colunas, feito por upload; para editar, baixe, altere e suba como novo layout). Document Generator e AOP não suportam Generic Columns nem XSL-FO. Para eles, informe o *Data Loop Name* (nome do array no JSON). Layouts aceitam subscription; copiar sem subscription gera Static ID novo.

Fonte: [Formatting a Report Region or Report Query Using Report Layouts](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/formatting-using-report-layouts.html)

### Search Configurations (busca declarativa)

Uma **Search Configuration** descreve uma fonte pesquisável. Uma **Search Page** (Create Page Wizard > Search Page, ou manualmente) tem um item de busca e uma região **Search Results** com **Search Sources** que apontam para as configurações. Tipos:
- **Standard**: tabela, SQL Query ou REST Data Source; busca com `LIKE`.
- **Oracle TEXT**: tabela/consulta com índice Oracle Text; busca linguística e fuzzy.
- **Oracle Ubiquitous Search**: índice `DBMS_SEARCH` (exige Oracle AI Database 26ai; índice no parsing schema).
- **List**: busca dentro de uma List de Shared Components.
- **Oracle Vector Search**: busca semântica.

Aceitam subscription e têm abas *Utilization* e *History*. No 26.1 só casam entre apps por Static ID.

Fonte: [Adding Search to an Application](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/adding-search-to-an-application.html), [About Creating Application Searches](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-creating-application-searches.html), [Creating a Ubiquitous Search](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-a-ubiquitous-search.html)

### Data Load Definitions e Map Backgrounds (referência rápida)

- **Data Load Definitions** (Other Components): definem tabela de destino, perfil de dados e regras para o processo/página de carga de dados (CSV, XLSX etc.). Aceitam subscription (mas não pelo *Subscribe From* da página de edição). O detalhe fica no capítulo *Managing Application Data*. A carga legada está na seção 15.
- **Map Backgrounds** (User Interface): fundos de mapa customizados para regiões Map, itens Display Map e Geocoded Address, escolhidos em Component Settings ou no componente como *Shared Component*.

Fonte: [Shared Components Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/shared-components-page.html), [Creating Custom Map Backgrounds](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-custom-map-backgrounds.html)

---

## 6. Temas e Universal Theme (UT 42)

### Tema, tipos de template e template class

Um **theme** é uma coleção nomeada de templates que define layout e estilo da aplicação inteira. Templates são organizados por **tipo** (page, region, report, list, button, label/field, breadcrumb, popup LOV e, no UT moderno, template components) e, dentro do tipo, por **template class** (a finalidade: região de formulário, região de relatório etc.). A template class é o que permite ao APEX mapear templates entre temas ao trocar de tema.

O engine monta cada página a partir dos templates: o page template dá a estrutura, region templates envolvem cada região, label templates envolvem cada item, e assim por diante. Administradores de instância podem publicar **public themes**, disponíveis a todos os workspaces.

Fonte: [About Themes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-themes.html), [How Oracle APEX Uses Templates](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/how-oracle-apex-uses-templates.html), [Theme Templates](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/theme-templates.html)

### Universal Theme 42: o design system padrão

O **Universal Theme - 42** é o tema de toda app criada pelo Create Application Wizard. Tecnicamente reúne templates HTML, CSS, ícones (Font APEX), imagens e JavaScript que cooperam para dar aparência consistente em qualquer tela. Características:
- **Design responsivo**: o mesmo layout se adapta a smartphone, tablet e desktop; usa gráficos vetoriais e CSS3. A documentação lembra que escolher templates não basta: o desenvolvedor precisa montar a página de forma responsiva (grid de 12 colunas, regiões aninhadas).
- **UI versátil**: componentes para quase qualquer tipo de app de negócio.
- **Customização fácil**: **Theme Styles** + **Theme Roller** para cores e marca; **Template Options** para variações de cada componente.
- Navegação: side menu em árvore ou top menu.

O **Universal Theme Reference app** (`https://apex.oracle.com/ut` ou `oracleapex.com/ut`; também instalável pela Gallery > Sample Apps) é a referência viva: *Design* (cores, navegação, grid, page templates, theme styles, padrões mobile), *Components* (cada componente com exemplo e template options interativas, às vezes com SQL de exemplo), *Icons* e *Reference* (migração, construtor de botões, cores, **variáveis CSS**, classes utilitárias, template directives). Na barra dele dá para alternar direção de escrita e theme style.

Estilos que acompanham o UT 26.1: **Redwood Light** (inspirado no Fusion Applications, mais espaçoso), a família **Vita** (mais compacta, cores sólidas; inclui Vita - Dark e variantes) e **Iris** (combina aspectos dos dois; novo estilo padrão no 26.1). Todos foram desenhados com acessibilidade em mente.

Novidades do UT no 26.1: template components Metric Card e Blank Page; grupos para Avatars, Timeline, Comments e Media List; Drawers e Dialogs com posições Top/Bottom e slot de Footer em Inline Drawer/Dialog; customizações avançadas no Theme Roller; Font APEX 2.5 (66+ ícones novos); badge em botões via atributo `data-count`; classes utilitárias de overflow, números tabulares e flex; alinhamento vertical em page templates; estilos inbound/outbound em Comments; opção para tirar ícones padrão do menu recolhido; mais variáveis CSS em componentes core (ex.: cor de fundo do nó selecionado na árvore). jQuery Mobile foi descontinuado; apps mobile antigas devem migrar para o UT.

Fonte: [Understanding the Universal Theme](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-the-universal-theme.html), [Advantages of the Universal Theme](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/advantages-of-the-universal-theme.html), [Universal Theme Design System](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/universal-theme-design-system.html), [Universal Theme Reference App](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/universal-theme-reference-app.html), [Theme Styles (apxdc)](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/theme-styles.html), [New Features: Universal Theme Enhancements](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### Refresh do Universal Theme e migração de outros temas

Quando o UT da app está desatualizado, a home da aplicação mostra um banner ("There is a new version of Universal Theme available!…"). Clique **Refresh Theme**, rode e teste a app. Antes, exporte ou copie a app como backup. Para migrar de temas antigos, use *Switch Theme* e o *Migration Guide* do UT Reference app (*Reference > Migration Guide*).

O que o refresh atualiza: templates, opções e arquivos **assinados** do master. Templates criados localmente (cópias) não são tocados (ver theme subscriptions).

Fonte: [Refreshing the Universal Theme](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-the-universal-theme.html), [About Updating or Migrating to the Universal Theme](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-the-universal-theme.html)

### Theme subscriptions: master, somente leitura, cópias locais, verify e refresh

Ao criar app pelo wizard com tema built-in, ou ao criar tema a partir do repositório, a app **assina** um master theme. Assim o tema pode ser atualizado em releases futuros do APEX.

Consequências:
- Atributos do tema, template options assinadas e templates assinados ficam **somente leitura**; só os *default templates* do tema podem ser trocados.
- Para customizar sem quebrar a assinatura: crie uma **cópia local** do template (fica editável e não é assinada). O mesmo vale para theme styles: um style local adicionado ao tema assinado é editável, mas **fica de fora dos refreshes**.
- **Verify** (Create/Edit Theme > Theme Subscription > Verify) roda o *Verify Theme Subscription Wizard*: lista atributos, templates e template options fora de sincronia com o master e templates do master ainda não publicados. No fim, *Refresh* aplica.
- **Refresh Theme** (mesma região) atualiza a partir do master. Não aparece se o tema não é assinado.
- **Unsubscribe** remove a assinatura de todos os templates, styles e arquivos do tema e impede atualizações futuras.
- **Re-subscribe** a um tema built-in: (1) mudar o ID do tema atual (*Change Identification Number*), (2) criar o tema de novo pelo Create Theme Wizard, (3) *Switch Theme* para o novo, (4) apagar o antigo.

Fonte: [Managing Theme Subscriptions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-theme-subscriptions.html)

### Criar, copiar, trocar (Switch), mudar ID, apagar e exportar temas

- **Criar/acessar tema**: Themes > Create: *From the Repository*, *As a copy from another application*, *From Scratch* ou *From Export*. A app assina o tema criado. A página Themes só mostra os temas associados à app; a coluna *Is Current* marca o ativo.
- **Switch Theme**: precisa de pelo menos dois temas instalados. O wizard mapeia cada template pelo **tipo + classe** (com vários candidatos, usa tipo, classe e nome). Na tela *Verify Compatibility*: check = mapeado; warning = mais de um template com aquela classe (escolha na lista); erro = classe sem correspondente. Sem template do mesmo tipo, a troca é bloqueada. Warnings não resolvidos podem quebrar funcionalidade e visual. Faça backup antes.
- **Change Identification Number**: muda o número do tema (útil para exportar com outro número ou re-assinar).
- **Copy Theme**: copia com novo ID, com a opção *Subscribe Theme*; bom para experimentar.
- **Delete Theme**: remove só temas inativos. Modificações de template se perdem, então exporte antes.
- **Export/Import**: *Workspace Utilities > Export > Themes* (opções de audit info e character set) e importação na instância de destino.
- **Master Theme Application**: a Oracle recomenda partir de uma app de exemplo com UT 42: copie a app ou copie o tema com *Subscribe* e troque para ele.
- **Instance themes**: só o administrador da instância adiciona ou remove temas do repositório.

Fonte: [Accessing New Themes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/accessing-new-themes.html), [Switching Themes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/switching-themes.html), [Changing a Theme Identification Number](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/changing-theme-id-number.html), [Copying a Theme](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/copying-a-theme.html), [Deleting a Theme](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/deleting-a-theme.html), [Exporting Themes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/exporting-themes.html), [Creating a Master Theme Application](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-master-theme-application.html)

### Atributos do tema (Create/Edit Theme)

| Seção | Atributos principais |
|---|---|
| **Name** | Application, Theme Number, Name, Identifier (interno), Navigation Type (Tabs ou List), Navigation Bar Implementation (Classic ou List), Description |
| **Theme Subscription** | master assinado; Verify, Refresh Theme, Unsubscribe |
| **JavaScript and Cascading Style Sheets** | *JavaScript File URLs* (substituem `#THEME_JAVASCRIPT#` no page template) e *CSS File URLs* (substituem `#THEME_CSS#`), um URL por linha, com `#MIN#`, `#MIN_DIRECTORY#` e `#APP_VERSION#` |
| **Component Defaults** | template padrão de Page, Navigation Bar List, Navigation Menu List Position e List (Top/Side), Login Page, Error Page (só para páginas Normal), Printer Friendly Page, Breadcrumb, Button, Legacy Calendar, Default/Optional/Required Label, List, Region, Classic Report, Header/Footer Toolbar |
| **Region Defaults** | template padrão por tipo de região criada pelos wizards: Breadcrumb, Charts, Forms, Lists, Reports, Wizards, Interactive Reports |
| **Dialog Defaults** | Dialog Content Region, Dialog Button Region, Dialog Page (também usado para erros em página separada em diálogos) |
| **Global Template Options** | template options válidas para todos os componentes de um tipo |
| **Icons** | *Library* (ex.: Font APEX; também popula o picker de ícones), *Custom Library File URLs*, *Custom Classes* (aparecem no picker), *Custom Prefix Class*, *Date Picker Icon Name/Attributes* |
| **Styles** | theme styles do tema e o *Current Theme Style* (`#THEME_STYLE_CSS#`) |
| **Files** | *File Prefix* (caminho virtual dos arquivos do tema; vazio = arquivos do tema no banco; pode ser `#APEX_FILES#...` ou URL) e upload de arquivos do tema. Com File Prefix preenchido, use `#THEME_DB_FILES#` para forçar arquivos do banco em vez de `#THEME_FILES#` |

O **default page template** do tema é usado por toda página que não escolhe outro (*Appearance, Page Template* no Page Designer).

Fonte: [Editing Themes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-themes.html), [Selecting a Default Page Template](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/selecting-defaul-page-template.html)

### Relatórios de tema e de templates

Themes > **Reports**:
- *Application Templates*: todos os templates do tema, com tipo, nome e classe.
- *Theme Template Counts*: quais template classes têm templates.
- *File References*: arquivos referenciados por templates, shared components e componentes de página (com ou sem contexto; exporta CSV).
- *Class References*: classes CSS referenciadas.
- *Template Substitution Strings*: substitution strings suportadas por componente.

Templates > abas *Subscription*, *Publish* (templates que outros assinam; *Publish Checked*), *Utilization* (quantas páginas usam cada template) e *History*. Tasks: *Replace Templates* (troca o template de todos os componentes de um tipo), *Replace templates in this application with templates from another application* (Replace ou Replace/Subscribe), *View page template region position utilization*, *Unsubscribe Templates*.

Fonte: [Viewing Theme Reports](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/viewing-theme-reports.html), [Viewing Template Reports](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/viewing-template-reports.html), [Managing Templates](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-templates.html)

### Refresh do tema filho não copia templates locais do tema master (theme decoupling)

**Sintoma:** uma app filha assina uma Master theme app, que por sua vez assina o UT. Templates criados localmente na Master não chegam à filha depois do refresh.
**Causa:** problema conhecido do 26.1: no refresh do tema da filha, os templates locais da Master (que não existem na app central) não são copiados.
**Correção:** copie esses templates manualmente para a app filha.

Fonte: [Open Bugs and Known Issues: Theme Decoupling](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/open-bugs-known-issues.html)

---

## 7. Theme Styles, Theme Roller e a API APEX_THEME

### Theme Style: o que é e como é carregado

Um **theme style** é uma folha de estilo somada ao CSS base do tema. Temas modernos como o UT têm um CSS base e um CSS de style, referenciado no page template por `#THEME_STYLE_CSS#`. O engine troca essa string pelos *File URLs* do style atual. Serve para trocar o esquema de cores, aplicar visual flat etc. Um tema pode ter vários styles, com um **current**.

Atributos (Themes > tema > aba Styles > **Add Style**):

| Atributo | Função |
|---|---|
| Name | nome curto (APEXlang: até 30 caracteres) |
| Is Public | o usuário final pode escolher este style |
| Accessibility Tested | indica se foi testado contra as diretrizes de acessibilidade |
| File URLs | CSS carregados quando o style é o atual (um por linha; `#MIN#`, `#MIN_DIRECTORY#`, `#APP_VERSION#`); substituem `#THEME_STYLE_CSS#` |
| CSS Classes | classes somadas a `#PAGE_CSS_CLASSES#` em todas as páginas quando o style está ativo |
| Theme Roller: Read Only | On impede que o Theme Roller sobrescreva o style |
| Theme Roller: Input Parameter File URLs | arquivos LESS de entrada do Theme Roller |
| Theme Roller: Output CSS File URL | CSS gerado pelo Theme Roller |
| Theme Roller JSON Configuration | gerado pelo Theme Roller ao salvar; não edite à mão (pode copiar de outro style) |

APEXlang (`theme > style`): `css { fileUrls, cssClasses }`, `themeRollerAttributes { readOnly, inputParameterFileUrls, outputCssFileUrl, jsonConfig }`, `advanced { staticId, endUserCanPick, accessibilityTested }`.

Selecionar o style atual: no wizard de criação de app, em Create/Edit Theme (*Current Theme Style*) ou em *User Interface Attributes > Attributes > Theme Style*.

Fonte: [Using Theme Styles](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/theme-styles.html), [APEXlang API Reference: style](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Deixar o usuário final escolher o theme style

1. Tenha pelo menos dois theme styles marcados como **Is Public**.
2. *User Interface Attributes > Attributes > Enable End Users to choose Theme Style* = On.

Um link **Customize** aparece na app (normalmente no canto inferior esquerdo). A escolha é gravada como **preferência do usuário** e vale nas sessões seguintes. Por API: `APEX_THEME.ENABLE_USER_STYLE` / `DISABLE_USER_STYLE`, que só afetam o link Customize; as demais chamadas de `APEX_THEME` funcionam de forma independente.

Fonte: [Enabling Users to Select a Theme Style](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/theme-styles.html), [ENABLE_USER_STYLE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ENABLE_USER_STYLE-Procedure.html)

### API APEX_THEME: style da sessão, do usuário e da aplicação

| Procedimento/função | Efeito |
|---|---|
| `SET_CURRENT_STYLE (p_application_id, p_theme_number, p_id)` | muda o style atual da **aplicação** (persistente). Exige *Runtime API usage* = "Modify this Application" nos Security Attributes |
| `SET_SESSION_STYLE (p_application_id, p_theme_number, p_name)` | style só para a **sessão**; `p_name` = Static ID do style (por compatibilidade, cai para o nome). Normalmente chamado após a autenticação |
| `SET_SESSION_STYLE_CSS (p_application_id, p_theme_number, p_css_file_urls, p_page_css_classes)` | aplica URLs de CSS à sessão sem precisar de style persistente; as classes vão para `PAGE_CSS_CLASSES` |
| `SET_USER_STYLE (p_application_id, p_user, p_theme_number, p_id)` / `GET_USER_STYLE` / `CLEAR_USER_STYLE` / `CLEAR_ALL_USERS_STYLE` | preferência por usuário; a preferência do usuário **tem precedência** sobre `SET_SESSION_STYLE` |
| `ENABLE_USER_STYLE` / `DISABLE_USER_STYLE` | liga/desliga a escolha pelo usuário final |

`APEX_UTIL.SET_CURRENT_THEME_STYLE` está deprecated; use `APEX_THEME.SET_CURRENT_STYLE`.

```plsql
declare
    l_theme_number number;
begin
    select theme_number into l_theme_number
      from apex_application_themes
     where application_id = :APP_ID;
    apex_theme.set_session_style( p_theme_number => l_theme_number, p_name => 'Vita' );
end;
```

Views úteis: `apex_application_themes`, `apex_application_theme_styles` (colunas `theme_style_id`, `is_current`).

Fonte: [APEX_THEME](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_THEME.html), [SET_CURRENT_STYLE](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_CURRENT_STYLE-Procedure.html), [SET_SESSION_STYLE](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_SESSION_STYLE-Procedure.html), [SET_SESSION_STYLE_CSS](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_SESSION_STYLE_CSS-Procedure.html), [SET_USER_STYLE](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_USER_STYLE-Procedure.html), [SET_CURRENT_THEME_STYLE (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_CURRENT_THEME_STYLE-Procedure.html)

### Theme Roller: editor visual de styles

O **Theme Roller** é um editor de CSS ao vivo, aberto em *Developer Toolbar > Customize > Theme Roller* numa página em execução. Altera style, cores, cantos arredondados e outros atributos sem código.

Uso:
1. Rode a página e abra o Theme Roller.
2. *Theme, Select Theme*: escolha o style base. Use a busca para achar atributos e expanda/recolha seções. Undo/Redo ficam no rodapé.
3. **Custom CSS**: CSS ou LESS (para LESS, ligue *Enable LESS Compilation*).
4. **Save** grava no style se ele for editável e o torna o current. **Save As** cria um novo style e o torna o current. Os styles nativos não podem ser sobrescritos; salve como novo.
5. *Additional Options* (ao lado de Save As): **Reset** (descarta o que não foi salvo), **Import** e **Export** (JSON).

Atalho: `Ctrl+Fn+M` e depois Tab para navegar pelo teclado. Theme Roller, Live Template Options e Logo Editor **não podem ser usados ao mesmo tempo**.

Com **Redwood Light**, o Theme Roller oferece opções próprias: *Pillar* (imagens de fundo e de cabeçalho), *Layout* (Edge to Edge, Floating, Contained) e *Appearance* (Header, Navigation, Body Header, Background).

Fonte: [Using Theme Roller](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-theme-roller.html)

### Importar e exportar Theme Roller (JSON) e compatibilidade Vita × Redwood

O JSON de import/export do Theme Roller tem estas chaves obrigatórias:

```json
{ "classes": [], "vars": {}, "customCSS": "", "useCustomLess": "" }
```

| Chave | Tipo | Conteúdo |
|---|---|---|
| `classes` | array | classes adicionadas à página |
| `vars` | objeto | variáveis do style com valores |
| `customCSS` | string | CSS customizado |
| `useCustomLess` | string | `"Y"` compila como LESS, `"N"` não |

Pelo console do navegador: `apex.utr.config()` sem parâmetros devolve a configuração atual; `apex.utr.config({...})` carrega uma configuração (o `customCSS` entra no Code Editor e é aplicado na hora).

Compatibilidade: styles da família **Vita** (incluindo o de alto contraste **Iris**) compartilham o mesmo conjunto de variáveis e trocam exports entre si. **Redwood Light** usa outro conjunto de variáveis.

Fonte: [Importing and Exporting Theme Styles / Style Compatibility / About Developer Console Integration](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-theme-roller.html)

### Theme Roller não aparece no menu Customize da Developer Toolbar

**Sintoma:** o item Theme Roller não aparece em *Customize*.
**Causa:** o Theme Roller só aparece se houver theme styles definidos **e** pelo menos um style com *Input Parameter File URLs* (arquivos LESS) preenchido.
**Correção:** use um style do UT (que traz os arquivos LESS) ou preencha *Theme Roller Attributes, Input Parameter File URLs* no style.

Fonte: [About Theme Roller](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-theme-roller.html)

### Import de configuração do Theme Roller não muda nada na tela

**Sintoma:** você importa um JSON exportado de outra app e nada muda.
**Causa:** o JSON foi exportado de um style de outra família. Exports Vita (e Iris) usam variáveis que não existem no Redwood Light, e vice-versa; as variáveis desconhecidas são ignoradas.
**Correção:** importe só entre styles da mesma família ou recrie as cores no style de destino.

Fonte: [Style Compatibility](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-theme-roller.html)

---

## 8. Templates, substitution strings e template directives

### Sintaxe de substituição em templates e filtros de escape

Templates combinam HTML estático com substituições:

| Tipo | Sintaxe | Uso |
|---|---|---|
| Placeholder (template substitution) | `#NOME#` | valores do componente dentro do template (`#TITLE#`, `#BODY#`, `#BUTTON_CSS_CLASSES#`); **sempre em maiúsculas**, entre `#` |
| Session state | `&ITEM.` | page/application items e built-ins (`&APP_USER.`); maiúsculas, `&` antes e `.` depois |
| Nome com caractere especial ou caixa | `#"Nome"#`, `&"Nome".` | entre aspas duplas |

**Escape filters** (`!FILTRO`) evitam XSS:

| Filtro | Efeito | Clássico | Moderno |
|---|---|---|---|
| `HTML` | escapa caracteres HTML | `#NAME!HTML#` | `&NAME!HTML.` |
| `ATTR` | escapa para atributo HTML | `#NAME!ATTR#` | `&NAME!ATTR.` |
| `JS` | escapa para contexto JavaScript | `#NAME!JS#` | `&NAME!JS.` |
| `STRIPHTML` | remove tags e escapa | `#NAME!STRIPHTML#` | `&NAME!STRIPHTML.` |
| `RAW` | sem escape | `#NAME!RAW#` | `&NAME!RAW.` |

No cliente, `apex.util.applyTemplate` avalia templates em JavaScript. Para ver as substitution strings aceitas por um template, abra o template e consulte o relatório **Substitution Strings** (ou *Theme Reports > Template Substitution Strings*).

Substitution strings deprecated no 26.1 (ainda funcionam): `#REGION_STATIC_ID#` e `#BUTTON_ID#` (use `#DOM_ID#`), `APP_REGION_STATIC_ID` (use `APP_REGION_DOM_ID`).

Fonte: [Basic Templates](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/basic-templates.html), [About Using Escaping Syntax in Substitution Strings](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-escaping-syntax-in-substitution-strings.html), [Deprecated Features: Deprecated Substitution Strings](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/deprecated-features.html)

### Page Templates: estrutura, JavaScript, CSS, subtemplates, layout, posições e diálogo

O **page template** define a estrutura da página e os *slots* (posições) onde entram regiões, itens e botões. Os page templates do UT estão em *Design > Page Templates* do UT Reference app. **Standard** é o padrão e um dos cinco que mostram o menu de navegação.

| Seção | Atributos |
|---|---|
| Name | Name, Theme, **Template Class** (mapeamento entre temas), *Translatable*, **Template Type**: *Dialog Page* (só para páginas Modal/Non-Modal) ou *Normal Page* |
| Definition | **Header** (o `<head>`; inclua pelo menos `#TITLE#` e `#HEAD#`), **Body** (com `#BODY#` e posições), **Footer** |
| JavaScript | *File URLs* (em `#TEMPLATE_JAVASCRIPT#`), *Function and Global Variable Declaration* (em `#TEMPLATE_JAVASCRIPT#`; aceita `"SHORTCUT"`), *Execute when Page Loads* (em `#GENERATED_JAVASCRIPT#`, roda depois do JS gerado pelo APEX); em Dialog Page também *Dialog Initialization/Closure/Cancel Code*. Sem tags `<script>` |
| Cascading Style Sheet | *File URLs* e *Inline* (em `#TEMPLATE_CSS#`). Sem tags `<link>`/`<style>` |
| Subtemplate | *Success Message* (`#SUCCESS_MESSAGE#`), *Navigation Bar* (`#NAVIGATION_BAR#`, com `#BAR_BODY#`), *Navigation Bar Entry*, *Notification* (`#NOTIFICATION_MESSAGE#`) |
| Image Based Tab Attributes | Current/Non Current Image Tab com `#TAB_TEXT#` (temas antigos) |
| Layout | *HTML Table*, *Fixed Number of Columns* ou *Variable Number of Columns* (grid) |
| Positions | slots do template. A substitution string de uma posição não pode ser reservada (ex.: `NOTIFICATION_MESSAGE`); a aba Positions lista as reservadas |
| Dialog | Width, Height, Maximum Width, CSS Classes, Allow Embed in Frames (o nível de página sobrescreve) |
| Error Page Template Control | quando o template serve como página de erro |

Pegadinha: uma posição só aparece se o placeholder correspondente estiver no HTML do template. Declarar o slot sem pôr o `#...#` no Body faz as regiões daquele slot não renderizarem.

No 26.1 page templates aceitam **template directives** em atributos específicos. Os modais são renderizados em iframe: com *Browser Frame* = Deny na app, marcar *Allow Embed in Frame* para Modal Dialog usa *Allow from same origin* nas páginas de diálogo desse template.

Fonte: [Page Templates](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/page-templates.html), [Page Template Sets the Scene](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/page-template-sets-scene.html), [Page Layout Based on Template with Slots](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/page-layout-based-template-slots.html)

### Dialog page template: atributos obrigatórios

Para um page template de diálogo funcionar:

| Atributo | Requisito |
|---|---|
| Name, Template Type | *Dialog Page* |
| JavaScript, Dialog Initialization Code | JS que inicializa a página como diálogo |
| JavaScript, Dialog Closure Code | JS que fecha |
| JavaScript, Dialog Cancel Code | JS que cancela |
| Dialog, Width / Height / Maximum Width / CSS Classes | padrões, sobrescrevíveis na página |
| Dialog, Allow Embed in Frame | controle de iframe (ver acima) |

A sintaxe das chamadas está na ajuda de cada campo. O *Dialog Page* default do tema (Dialog Defaults) também é usado para erros exibidos em página separada.

Fonte: [Required Dialog Page Template Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/page-templates.html)

### Region Templates: #BODY#, posições, sub regions e imagem

Region templates envolvem o conteúdo da região. **`#BODY#` é a única substitution string obrigatória.** Strings reservadas: `#TITLE#`, `#PAGE_TITLE#`, `#SUB_REGION_HEADERS#`, `#FORM_OPEN#`, `#FORM_CLOSE#`, `#REGION_ID#`, `#DOM_ID#`, `#REGION_CSS_CLASSES#`, `#REGION_ATTRIBUTES#`, `#REGION_HEADER#`, `#REGION_FOOTER#`, `#REGION_IMAGE#`, `#REGION_IMAGE_URL#`, `#REGION_IMAGE_ALT_TEXT#`, `#REGION_IMAGE_ATTRIBUTES#`. As posições do template (como `#BODY#`, `#SUB_REGIONS#` e posições de botão) ficam na seção Positions.

Outras seções:
- **Layout**: atributos da tabela HTML dos itens, só quando o page template usa layout HTML Table.
- **Sub Regions**: *Header Template* (exige `#ENTRIES#`; renderizado em `#SUB_REGION_HEADERS#`), *Header Entry Template* (`#SUB_REGION_ID#`, `#SUB_REGION_TITLE#`), *Template* (envolve cada subregião; exige `#SUB_REGION#`; vai em `#SUB_REGIONS#`).
- **Image**: exige `#REGION_IMAGE_URL#` dentro de `<img>`; saída em `#REGION_IMAGE#`.
- **JavaScript** (File URLs, Execute when Page Loads) e **CSS** (File URLs).

No UT, o **Standard** atende a maioria dos casos: corpo em grid de 12 colunas, nove slots de botão e opções de cabeçalho, borda e espaçamento. **Blank with Attributes** mostra só o conteúdo, sem botões nem bordas. **Buttons Container** cria uma barra de botões em qualquer lugar da página.

Fonte: [Region Templates](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/region-templates.html), [Region Template Styles a Section](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/region-template-styles-section.html)

### Button Templates: Normal, Hot e substitution strings

Button templates são opcionais. Têm *Normal Template* e *Hot Template* (usado quando o botão é *Hot*), com substituições de aplicação (`&ITEM.`) e:

| String | Uso |
|---|---|
| `#BUTTON_ATTRIBUTES#` | atributos do botão |
| `#BUTTON_CSS_CLASSES#` | **obrigatória em templates com template options**: é onde as classes das opções são injetadas |
| `#DOM_ID#` | ID do botão (Static ID ou `'B'` + ID interno) |
| `#BUTTON_NAME#`, `#LABEL#`, `#ICON_CSS_CLASSES#` | nome, rótulo, ícone |
| `#LINK#` | para `href` |
| `#JAVASCRIPT#` | para `onclick` |
| `#ONCLICK#` | indica `onclick` com JS, emitido num `<script>` no fim da página |

No 26.1 os button templates aceitam template directives, e botões ganharam *Show as Disabled* (renderiza desabilitado em vez de esconder quando a condição é falsa) e *Type* = *Menu* (cria uma entrada de menu sob o botão na árvore Rendering).

Fonte: [Button Templates](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/button-templates.html), [New Features: Declarative Menu Buttons](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### Label (item) templates: Before/After Label, erro, help e field container

Label templates centralizam o HTML do rótulo dos itens.

| Seção | Atributos |
|---|---|
| Definition | *Before Label* (deve conter `#ITEM_CSS_CLASSES#` se o template tem template options), *After Label*, *Before Item*, *After Item*, *Item Pre Text* (`#ITEM_PRE_TEXT#`), *Item Post Text* (`#ITEM_POST_TEXT#`), *Help Template* (só renderiza para itens com help), *Inline Help Template* |
| Error Display | *On Error Before Label*, *On Error After Label*, *Error Template* (`#ERROR_MESSAGE#`; incluído via `#ERROR_TEMPLATE#`) |
| Field Container | *Before Label and Item* / *After Label and Item* (só quando a página não usa tabela no layout) |

`#CURRENT_ITEM_HELP_TEXT#` coloca o help do item direto no HTML (tooltip), sem Ajax. Use só com textos curtos, porque a página passa a carregar o help de todos os itens.

```html
<label for="#CURRENT_ITEM_NAME#" id="#LABEL_ID#">
<span class="helpText">#CURRENT_ITEM_HELP_TEXT#</span>
```

Item templates do UT: **Hidden** (sem rótulo); **Optional** / **Required** (rótulo antes do item, com *Label Column Span*); **Optional - Above** / **Required - Above** (rótulo acima, sem column span); **Optional - Floating** / **Required - Floating** (rótulo dentro do campo que sobe ao preencher; o item estica até o column span). Os Required mostram um marcador visual e há template option para exibir o texto "Required".

Fonte: [Label Templates](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/label-templates.html), [Item Template Controls the Label](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/item-template-controls-label.html)

### List Templates: current/noncurrent, primeira entrada e sublistas

| Seção | Atributos |
|---|---|
| Before List Entry | HTML antes da lista; deve conter `#COMPONENT_CSS_CLASSES#` se o template tem template options |
| Template Definition | *List Template Current*, *Current with Sub List Items*, *Noncurrent*, *Noncurrent with Sub List Items*, *Between List Elements*. Strings: `#LINK#`, `#TEXT#`, `#TEXT_ESC_SC#`, `#ICON_CSS_CLASSES#`, `#APEX_FILES#`, `#IMAGE#`, `#IMAGE_ATTR#`, `#A01#`..`#A10#` |
| Template Definitions for First Entry | versões *(First)* dos quatro acima |
| Before Sublist Entry / Sublist Entry / After Sub List Entry | equivalentes para sublistas, com `#LIST_ITEM_ID#` e `#PARENT_LIST_ITEM_ID#` |
| After List Entry | HTML de fechamento |

Templates "with Sublist" suportam hierarquia. No 26.1 list templates aceitam template directives, e as entradas podem ter Link Attributes.

Fonte: [List Templates](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/list-templates.html)

### Breadcrumb Templates

| Atributo | Função |
|---|---|
| Before First | antes da primeira entrada; deve conter `#COMPONENT_CSS_CLASSES#` se houver template options |
| Current Page Breadcrumb Entry / Non Current Page Breadcrumb Entry | aparência da entrada atual e das demais |
| After Last / Between Level | fechamento e separador |
| Maximum Levels | quantos níveis mostrar |

Strings das entradas: `#LINK#`, `#NAME#`, `#NAME_ESC_SC#` (escapado), `#LONG_NAME#`. O template é escolhido na região de breadcrumb.

Fonte: [Breadcrumb Templates](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/breadcrumb-templates.html)

### Report Templates (Classic Report): Generic Column × Named Column

- **Generic Column Template**: define a célula uma vez (`#COLUMN_VALUE#`) e repete para cada coluna. Funciona com qualquer consulta de estrutura linha/coluna. Use alias em expressões do SELECT para evitar erros (`(sal+comm)*12 yearly_comp`).
- **Named Column Template**: referencia colunas pelo nome (`#ENAME#`) ou posição (`#1#`). Dá controle total do HTML da linha, mas só serve para consultas com aquelas colunas.

| Seção | Conteúdo |
|---|---|
| Before Rows | abertura (`<table>`); aceita `#TOP_PAGINATION#`, `#CSV_LINK#`, `#REPORT_ATTRIBUTES#` |
| Column Headings | *Before Column Heading*, *Column Heading Template* (`OMIT` = sem cabeçalho), *After Column Heading* |
| Before Each Row | `#ROWNUM#`, `#COLCOUNT#`, `#HIGHLIGHT_ROW#` |
| Column Templates / Row Templates | até **4**, cada um com condição: *Use Based on PL/SQL Expression* (ex.: `:SAL > 2000`, ou `#SAL# > 2000` em named), *Use for Even/Odd Numbered Rows*. Strings: `#ALIGNMENT#`, `#COLCOUNT#`, `#COLNUM#`, `#COLUMN_HEADER#`, `#COLUMN_VALUE#`, `#ROWNUM#` |
| After Each Row / After Rows | fechamentos; After Rows aceita `#PAGINATION#`, `#COLCOUNT#`, `#CSV_LINK#`, `#EXTERNAL_LINK#` |
| Row Highlighting | cores de linha marcada e de hover |
| Pagination Subtemplate | *Pagination Template* (`#TEXT#`), *Next/Previous Page* e *Next/Previous Set* (`#LINK#`); strings `#PAGINATION_NEXT#`, `#PAGINATION_NEXT_SET#`, `#PAGINATION_PREVIOUS#`, `#PAGINATION_PREVIOUS_SET#` |

Qualquer item da app pode ser usado no template com `&ITEM.`. A documentação ainda traz um exemplo de column template com `<script>` e `document.writeln` para exibir HTML condicionalmente. Esse padrão é script inline, que as boas práticas de CSP do 26.1 mandam evitar; a região Classic Report aceita template directives (`{if COLUNA/}`) nos atributos que indicam suporte (ver a ajuda do Page Designer), o que resolve o mesmo caso sem script.

Fonte: [Report Templates](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/report-templates.html)

### Popup LOV Templates (itens legados do tipo POPUP)

Controlam a janela das popup LOVs antigas. Só **um** por tema. Seções: *Search Field* (Before/After Field Text, Filter Width, Filter Max Width, Filter Text Attribute), *Buttons* (Find, Close, Next, Previous), *Window* (`scrollbars=`, `resizable=`, `width=`, `height=`), *Pagination*, *Result Set* e *Page Attributes*. Raramente é preciso mexer nele em apps novas.

Fonte: [Popup LOV Templates](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/popup-lov-templates.html)

### Criar template customizado, marcar como traduzível e publicar

- **Criar**: Templates > Create, tipo, *From Scratch* ou *As a Copy of an Existing Template*. É mais fácil copiar um existente e alterar. Associe ao tema certo. Num tema assinado, a cópia local fica editável e fora do refresh.
- **Editar com feedback rápido**: marque *Return to Page* na página do template para continuar nela após Apply Changes e rodar a app em outra janela.
- **Translatable**: por padrão templates não entram no arquivo de tradução. Se o template tiver texto (o que deve ser evitado), marque *Translatable*. Alternativa: texto em static substitution strings da app, que são traduzidas.
- **Publish**: aba *Publish* mostra templates assinados por outros; *Publish Checked* empurra o conteúdo do master.

Fonte: [Creating a New Template](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-new-template.html), [Managing Templates](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-templates.html), [Identifying a Template as Translatable](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-application-translation-and-globalization-support.html)

### Template Directives: if, case, loop, with/apply e comentários

**Template directives** são tokens que controlam o processamento do texto ao redor. Funcionam em Template Components, atributos específicos de email templates, regiões Cards, Interactive Grid, Classic Report, Application Search e Interactive Report e, no 26.1, nos theme templates de button, label/item, list, region e page. A ajuda do Page Designer indica "Supports Server-side Template Directives" ou "Supports Client-side Template Directives". Directives podem ser aninhadas.

**if**:

```
{if [!][?|=]NAME/} texto {elseif NAME2/} texto2 {else/} texto3 {endif/}
```

Falso = vazio (após trim) ou um dos valores `F`, `f`, `N`, `n`, `0` e, desde o 26.1, `FALSE`. Todo o resto é verdadeiro.

| Diretiva | Verdadeira quando |
|---|---|
| `{if X/}` | X tem valor e não é F/N/0 |
| `{if ?X/}` | X tem valor (qualquer) |
| `{if !X/}` | X vazio ou F/N/0 |
| `{if !?X/}` | X vazio |
| `{if =X/}` | X vazio ou diferente de F/N/0 |
| `{if !=X/}` | X é F/N/0 |
| `{if X%assigned/}` | X foi atribuído (útil quando `&COL.` fica vazio em algumas linhas) |

**case**: `{case JOB/}{when SALESMAN/}...{when PRESIDENT/}...{otherwise/}...{endcase/}` (comparação com trim, sensível a maiúsculas).

**loop** sobre valores delimitados (separador padrão `:`; mais de um caractere = regex), com `&APEX$ITEM.` e `&APEX$I.` (índice a partir de 1):

```html
<ul class="tags">{loop "," TAGS/}<li>&APEX$ITEM.</li>{endloop/}</ul>
```

**with/apply** aplica um Template Component passando argumentos (ver seção 11):

```
{with/}
TYPE:=IMAGE
IMAGE:=&IMAGE_URL.
ALT:={if DESCRIPTION/}&DESCRIPTION.{else/}Sem descrição{endif/}
{apply THEME$AVATAR/}
```

**Comentário**: `{!texto/}` (sem quebra de linha). **Escapar `{`**: `{{/}` quando uma chave solta seguida de diretiva na mesma linha seria confundida. `APEX$DOM_ID` gera um ID único por execução do trecho.

No 26.1 o Code Editor destaca a sintaxe; digitar `{` lista as directives e `#`/`&` lista placeholders.

Fonte: [Using Template Directives](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-template-directives.html), [Template Directives](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/template-directives.html), [Changed Behavior: Template Directive False Values](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html), [New Features: Template Directive Enhancements](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

---

## 9. Template Options

### Template Options: modificadores CSS declarativos

**Template options** aplicam *CSS modifiers* (classes CSS) aos templates de pages, regions, classic reports, breadcrumbs, lists, items/labels e buttons, sem copiar templates. Exemplos: cores e acentos, espaçamento, estilo de botão com ou sem ícone, alinhamento de campos. Sem elas, cada variação exigiria um template quase idêntico.

Conceitos:
- **Default template options**: opções fora de grupo marcadas como padrão no template. Não são gravadas no componente: o componente guarda `#DEFAULT#` e o engine aplica os padrões atuais do template. Assim, mudar o padrão no template afeta todos os componentes que usam `#DEFAULT#`. Ao desligar *Use Template Defaults*, as opções escolhidas são gravadas no componente como string de classes.
- **Template option groups**: agrupam opções mutuamente exclusivas (Button Size, Button Style, List Style, Form Label Position). Uma opção de grupo é opcional, a menos que o template defina um **preset** para o grupo (ex.: Small como preset de tamanho faz todo botão novo nascer Small).
- **Global template options**: definidas no tema, valem para todos os componentes de um tipo.

Em runtime, as classes das opções selecionadas e das default são somadas às CSS Classes do componente e injetadas no placeholder do template: `#REGION_CSS_CLASSES#`, `#BUTTON_CSS_CLASSES#`, `#COMPONENT_CSS_CLASSES#` (list/breadcrumb), `#ITEM_CSS_CLASSES#` (label) ou `#PAGE_CSS_CLASSES#`.

Fonte: [Understanding Template Options](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-template-options.html), [Templates and Options Set Look and Feel](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/templates-and-options-set-look-and-feel.html)

### Criar e editar template options, groups e global options

Só o **dono do tema** cria ou edita template options. Num tema assinado, é preciso desassinar ou usar uma cópia local do template.

- **Template option** (Templates > template > *Add Template Option*): *Group*, *Name*, *Identifier* (alfanumérico em maiúsculas; mapeia a opção ao trocar de tema; **não pode ser alterado** depois), *Sequence*, *Classes* (uma ou mais classes CSS), *Help Text*, *Static ID*.
- **Template option group** (*Template Options Groups*): *Template Type*, *Name*, *Identifier*, *Sequence*, *Null Text* (valor quando nenhuma opção do grupo é escolhida), *Help Text*, *Advanced* (categoria Basic ou Advanced no Property Editor), *Static ID*.
- **Global**: mesma coisa, na página do tema (Themes > tema > Template Options), com *Template Type*.
- Excluir: menu *Row Actions > Delete Row* no grid.

Pegadinha: renomear a classe CSS de uma opção **não** atualiza os componentes que já gravaram aquela classe; é preciso ajustar à mão.

Fonte: [Managing Template Options](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-template-options.html), [Managing Global Template Options](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-global-template-options.html)

### Live Template Options pela Developer Toolbar (Quick Edit)

Rode a página, clique **Quick Edit** na Developer Toolbar, passe o mouse sobre o componente e clique na **chave inglesa** no canto superior direito. O diálogo *Live Template Options* altera as opções sem recarregar a página. Para regiões como listas e classic reports há também a aba *Attributes*. *Save* grava no componente. Não pode ser usado junto com Theme Roller ou Logo Editor.

Fonte: [Using Quick Edit to Modify Live Template Options](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-template-options.html)

### Template option selecionada não muda nada na tela

**Sintoma:** você escolhe uma template option no Page Designer, salva e o componente continua igual.
**Causa:** o template (geralmente uma cópia customizada) não tem o placeholder onde as classes são injetadas: `#BUTTON_CSS_CLASSES#` (button), `#COMPONENT_CSS_CLASSES#` (list em *Before List Entry*, breadcrumb em *Before First*), `#ITEM_CSS_CLASSES#` (label em *Before Label*), `#REGION_CSS_CLASSES#` (region). Outra causa: um CSS customizado com especificidade maior anula a classe.
**Correção:** inclua o placeholder no HTML do template; inspecione o elemento no DevTools para ver se a classe chegou.

Fonte: [Button Templates](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/button-templates.html), [List Templates](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/list-templates.html), [Label Templates](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/label-templates.html), [Breadcrumb Templates](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/breadcrumb-templates.html)

---

## 10. CSS e JavaScript customizados

### Onde colocar CSS e JavaScript: níveis e placeholder de cada um

| Nível | Onde configurar | Placeholder no page template | Quando usar |
|---|---|---|---|
| Aplicação | *User Interface Attributes > JavaScript/CSS > File URLs* | `#APPLICATION_JAVASCRIPT#` / `#APPLICATION_CSS#` | arquivos usados em todas as páginas |
| Tema | *Create/Edit Theme > JavaScript and Cascading Style Sheets* | `#THEME_JAVASCRIPT#` / `#THEME_CSS#` | arquivos do próprio tema |
| Theme style | *Theme Style > File URLs* | `#THEME_STYLE_CSS#` | CSS de cores/estilo |
| Page template | *JavaScript* / *Cascading Style Sheet* do template | `#TEMPLATE_JAVASCRIPT#` / `#TEMPLATE_CSS#` | CSS/JS do layout do template |
| Region template | *JavaScript / CSS File URLs* do template | `#TEMPLATE_JAVASCRIPT#` | quando a região usa o template |
| Página | Page Designer > página > *JavaScript* (File URLs, Function and Global Variable Declaration em `#PAGE_JAVASCRIPT#`, Execute when Page Loads) e *CSS* (File URLs, Inline) | `#PAGE_JAVASCRIPT#` / `#PAGE_CSS#` | código específico da página e testes |
| Plug-in / Template Component | *File URLs to Load* | CSS em `#APEX_CSS#`, JS em `#GENERATED_JAVASCRIPT#` | só quando o componente está na página |

Regras gerais da documentação:
- **File URLs**: um URL por linha, **sem** tags `<script>`/`<link>`.
- Código inline: **sem** `<script>`/`<style>`. Para código usado em várias páginas, prefira arquivo externo: evita duplicação e aproveita o cache do navegador. Um `.js` referenciado no page template é a forma mais eficiente para JS da app inteira, porque carrega na primeira página e fica em cache.
- *Execute when Page Loads* roda depois do JavaScript gerado pelo APEX.
- Regras CSS que valem para a app toda vão num arquivo de Static Application Files ligado em *User Interface Attributes > CSS > File URLs*; regras de um item ou de uma página vão em *Page > CSS > Inline*.

Fonte: [Editing User Interface Attributes: JavaScript / CSS](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-user-interface-attributes.html), [Incorporating JavaScript Using Page Designer](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-page-attributes-in-page-designer.html), [Configuring Application-Wide Style Rules](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configuring-application-wide-style-rules.html), [About Calling the JavaScript File from the Page Template](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/calling-javascript-file-from-page-template.html), [Page Templates](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/page-templates.html)

### Sintaxe dos File URLs: #MIN#, #MIN_DIRECTORY#, #APP_VERSION#, media query e RequireJS

| Sintaxe | Efeito |
|---|---|
| `/mycss/main.css` | referência simples |
| `#APP_FILES#app#MIN#.css` | `#MIN#` vira `.min` em página normal e vazio em **debug** |
| `/myjs/#MIN_DIRECTORY#main#MIN#.js` | `#MIN_DIRECTORY#` vira `minified/` em página normal e vazio em debug: carrega `/myjs/minified/main.min.js` normalmente e `/myjs/main.js` em debug |
| `/mycss/main.css?version=#APP_VERSION#` | versão da app no URL: ao subir a versão, o navegador baixa o arquivo novo (cache busting) |
| `[media="only screen and (max-device-width: 480px)"]/mycss/smartphone.css` | CSS condicional por media query |
| `[define hammerjs=Hammer]/myjs/hammer.js` | (JS, RequireJS) declara a biblioteca para o RequireJS não carregá-la de novo |
| `[require requirejs]/myjs/main.js` | carrega o RequireJS antes do arquivo |
| `[require jet]/myjs/main.js` | carrega RequireJS + configuração do Oracle JET antes |

`#APP_VERSION#` está disponível nos File URLs de CSS (app, tema, style, templates, página). `#PLUGIN_FILES#` é o file prefix do plug-in nos File URLs de plug-ins.

Fonte: [Editing User Interface Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-user-interface-attributes.html), [Editing Themes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-themes.html), [APP_VERSION](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-available-built-in-substitution-strings.html)

### Minificação automática de arquivos JavaScript e CSS

O que a documentação 26.1 afirma:
- **Static Application Files**: ao salvar um arquivo JavaScript como `app.js`, o App Builder cria automaticamente a versão minificada `app.min.js` (sem espaços, nomes encurtados, mesma lógica). Em runtime o APEX usa a minificada, exceto com **Debug** ligado, quando usa o fonte. Por isso a coluna *Reference* de arquivos JS já vem com `#MIN#`.
- **Arquivos de Template Components (plug-ins)**: o APEX cria versões minificadas de arquivos **CSS e JavaScript** ao salvar ou alterar, e a coluna *Reference* traz o nome a usar em *File URLs to Load*.

Para arquivos **CSS** em Static Application Files a documentação não diz explicitamente que a versão `.min` é gerada (confirmar no 26.1.5). Se ela não existir, o URL com `#MIN#` aponta para um arquivo inexistente fora do debug.

Fonte: [Including Helper Functions in All Pages](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/including-helper-functions-all-pages.html), [Defining Files and File URLs to Load](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/defining-files-and-file-urls-load.html)

### CSS diferente com e sem debug (#MIN# e .min desatualizado)

**Sintoma:** a página fica de um jeito com `?p_debug=YES` (ou debug ligado pelo Builder) e de outro para o usuário normal.
**Causa:** com `#MIN#`/`#MIN_DIRECTORY#`, o modo debug carrega o arquivo fonte e o modo normal carrega o `.min`. Se o `.min` não foi regenerado ou não foi enviado, as versões divergem; se o `.min` não existe, o modo normal fica sem o arquivo.
**Correção:** regenere e envie o `.min` junto com o fonte (ou confira se o Builder gerou); compare os dois arquivos.
**Prevenção:** ao editar `X.css`/`X.js`, sempre atualize o par; teste a página com e sem debug.

Fonte: [Editing User Interface Attributes: CSS](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-user-interface-attributes.html), [Including Helper Functions in All Pages](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/including-helper-functions-all-pages.html)

### Navegador continua com o CSS ou JS antigo depois do deploy

**Sintoma:** depois de subir um arquivo novo, usuários continuam vendo o comportamento antigo.
**Causa:** cache do navegador (ou CDN) para um URL que não mudou.
**Correção:** recarregue sem cache; para todos os usuários, inclua a versão no URL (`/mycss/main.css?version=#APP_VERSION#`) e incremente a *Version* da aplicação a cada release.
**Prevenção:** no web server, use cabeçalhos de expiração junto com URLs versionados.

Fonte: [Editing User Interface Attributes: CSS](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-user-interface-attributes.html), [About Uploading Static Files to Your Web Server](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-uploading-static-files-to-your-web-server.html)

### Substitution strings de arquivos: APP_FILES, WORKSPACE_FILES, APEX_FILES, THEME_FILES

| String | Aponta para | Nome legado |
|---|---|---|
| `#APP_FILES#` / `&APP_FILES.` / `:APP_FILES` / `v('APP_FILES')` | Static Application Files da app (ou o *#APP_FILES# Path*) | `APP_IMAGES` |
| `#WORKSPACE_FILES#` / `&WORKSPACE_FILES.` / `:WORKSPACE_FILES` | Static Workspace Files | `WORKSPACE_IMAGE` |
| `#APEX_FILES#` / `&APEX_FILES.` / `:APEX_FILES` / `v('APEX_FILES')`; em PL/SQL direto `APEX_APPLICATION.G_IMAGE_PREFIX` | diretório de imagens distribuído com o APEX (configurado como `/i/` na instalação, ou o *#APEX_FILES# Path*) | `IMAGE_PREFIX` |
| `#THEME_FILES#` | arquivos do tema (respeita o *File Prefix* do tema) | `THEME_IMAGES` |
| `#THEME_DB_FILES#` | sempre os arquivos do tema guardados no banco, mesmo com File Prefix | `THEME_DB_IMAGES` |
| `#DEFAULT_THEME_FILES#` | caminho do parâmetro de instância `DEFAULT_THEME_FILES`, para o File Prefix do tema | |
| `#APP_VERSION#` | versão da app | |
| `#JET_BASE_DIRECTORY#`, `#JET_CSS_DIRECTORY#`, `#JET_JS_DIRECTORY#` | diretórios do Oracle JET | |

Se o *#APEX_FILES# Path* da app for igual ao prefixo da instância, o atributo de app fica nulo, o que facilita mover a app entre instâncias.

Pegadinha: `#APP_FILES#` gravado num valor (coluna ou item) só é substituído quando aquele texto passa por substituição de template/HTML; em PL/SQL o valor continua literal. Em PL/SQL, use `v('APP_FILES')`.

Fonte: [Using Built-in Substitution Strings](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-available-built-in-substitution-strings.html), [Editing User Interface Attributes: Advanced](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-user-interface-attributes.html)

### Variáveis CSS do Universal Theme (--ut-*, --a-*) e regras em :root

O UT expõe **variáveis CSS** para ajustar componentes sem sobrescrever seletores. A lista completa está em *Reference > CSS Variables* do UT Reference app. Regras em `:root` valem para todas as páginas, então são boas candidatas a um arquivo estático da app. Exemplos citados na documentação:

```css
:root {
    --ut-body-content-padding-y: 1rem;   /* padding vertical do corpo no UT */
    --a-cv-item-width: 16rem;             /* largura de cada card da região Cards */
    --a-cv-body-padding-y: 0.2rem;        /* padding vertical do corpo do card */
}

/* escopo por item: tamanho do ícone de preview do Image Upload */
#P6_IMAGE { --a-filedrop-icon-size: 25rem; }
```

Prefira `rem` (acompanha o zoom do usuário) e `calc()` quando precisar de alturas relativas à viewport (ex.: `.a-MapRegion-container { height: calc(100vh - 5rem) !important; }` como CSS inline da página). O 26.1 ampliou o uso de variáveis em componentes core (ex.: `--a-treeview-toggle-selected-text-color` em Tree).

Por que preferir variáveis: elas são lidas pelos componentes nativos, sobrevivem melhor a refresh do tema e não brigam com especificidade de seletor.

Fonte: [Configuring Application-Wide Style Rules](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configuring-application-wide-style-rules.html), [Enlarging Image Upload Icon Preview](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/enlarging-image-upload-icon-preview.html), [Calculating Height in Inline CSS](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/calculating-height-inline-css.html), [The Role HTML and CSS Play to Format Data](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/role-html-and-css-play-format-data.html)

### Concatenated Files: um arquivo no lugar de vários

*User Interface Attributes > Concatenated Files* define um arquivo concatenado que substitui vários arquivos menores. O navegador faz uma requisição em vez de várias, e no desenvolvimento você continua com arquivos modulares. No APEXlang (`concatenatedFile`): `concatenatedFileUrl`, `singleFileUrls` (lista dos arquivos substituídos), `onlyForPage` (restringe a uma página) e `buildOption`.

Fonte: [Editing User Interface Attributes: Concatenated Files](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-user-interface-attributes.html), [APEXlang API Reference: concatenatedFile](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Content Security Policy (CSP) e código inline no 26.1

O APEX 26.1 não precisa mais de `unsafe-hashes` (estilos inline internos viraram classes) nem de `unsafe-inline` nos arquivos JS core (scripts inline viraram externos ou com nonce). Para ativar: *Security Attributes > Browser Security > HTTP Response Headers*:

```
Content-Security-Policy: default-src 'self' #APEX_CSP_NONCE#; object-src 'none'; img-src 'self' data:;
```

Teste antes com `Content-Security-Policy-Report-Only` e acompanhe as violações no console. Substitution strings: `#APEX_CSP_NONCE#` (no header), `#APEX_CSP_NONCE_ATTRIBUTE#` (atributo `nonce="..."`), `#APEX_CSP_NONCE_VALUE#` (só o valor) e `#APEX_CSP_DISPLAY_NONE#` (renderiza `style=display:none;` de forma segura em templates).

Boas práticas: evitar scripts e estilos inline (`style="..."`, `onclick=`, `onerror=`), usar arquivos externos e, quando inevitável, nonce. Bibliotecas de terceiros (MapLibre e CKEditor são citadas) e plug-ins podem não ser compatíveis com CSP estrito.

Fonte: [Using Content Security Policy (CSP) in APEX](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-csp-in-apex.html), [Best Practices for CSP Compliant Development](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/best-practices-for-csp-compliant-development.html), [APEX_CSP_DISPLAY_NONE](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-available-built-in-substitution-strings.html), [New Features: Content Security Policy Support](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### jQuery, jQuery Migrate, funções deprecated e Oracle JET

- O APEX traz jQuery 3.x (a documentação cita a atualização para 3.6.4). jQuery 3 quebra compatibilidade com 2.x. Para código antigo, ligue **Include jQuery Migrate** (*User Interface Attributes > JavaScript*), que restaura APIs removidas e avisa no console onde o código usa API obsoleta. APIs de jQuery 1.x não funcionam desde o APEX 18.1.
- **Include Deprecated or Desupported Javascript Functions**: inclui funções JS do APEX descontinuadas. Desligue se a app não usa, para carregar menos JS.
- **Oracle JET**: o APEX integra partes do JET, principalmente nos Charts. Usa RequireJS e bundles otimizados (`jetCommonBundle.min.js`, `chartBundle.min.js` em `/images/libraries/apex/minified/`), carregados fora do modo debug. Plug-ins podem aproveitar o bundle comum com o prefixo `[require jet]`.
- Para atualizar uma região por JavaScript: `apex.region("staticIdDaRegiao").refresh();`.

Fonte: [Understanding jQuery Support](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-jquery-and-jquery-ui-support.html), [Editing User Interface Attributes: JavaScript](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-user-interface-attributes.html), [Understanding Oracle JET Integration with Oracle APEX](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/Understanding-Oracle-JET-Integration-with-Oracle-Application-Express.html), [Manually Refreshing Oracle APEX Components](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/manually-refreshing-oracle-apex-components.html)

### CSS de tema em /i/themes e ícones da aplicação

- Os CSS dos temas built-in ficam em `/i/themes/theme_xx/` e `/i/themes/theme_xx/css` (imagens em `.../images`). Os arquivos carregam a versão do APEX no caminho, para manter compatibilidade de apps importadas com versões antigas do tema.
- Para referenciar um CSS enviado direto no *Header* de um page template: `<link rel="stylesheet" href="#APP_FILES#sample2.css" type="text/css">` (ou `#WORKSPACE_FILES#`).
- **Ícone da app** (*User Interface Attributes > Icon*): propagado para favicon, ícone PWA, Apple touch icon e ícone no App Builder. Fica em Static Application Files em cinco tamanhos: `icons/app-icon-32.png`, `app-icon-144-rounded.png`, `app-icon-192.png`, `app-icon-256-rounded.png`, `app-icon-512.png`. Para controlar cada tamanho, suba esses arquivos com esses nomes.
- **Logo** (*Logo*): None, Image, Text, Image and Text ou Custom; exige `#LOGO#` no page template.

Fonte: [About Cascading Style Sheets](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-cascading-style-sheets.html), [Using Custom Cascading Style Sheets](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-custom-cascading-style-sheets.html), [Editing User Interface Attributes: Icon / Logo](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-user-interface-attributes.html)

---

## 11. Template Components

### Template Component: o que é e quando usar

Um **Template Component** é um tipo de plug-in feito só com HTML, placeholders `#NOME#` e template directives, **sem PL/SQL**. Quem conhece HTML cria componentes visuais reutilizáveis, e o resto do time usa no Page Designer como um componente nativo, configurando no Property Editor. Template Components de um tema aparecem em *Shared Components > Templates*; os avulsos aparecem em *Shared Components > Plug-ins*.

Formas de uso:
- **Região** que pode conter outros componentes (slots).
- **Single (Partial)**: formata uma linha; também serve como coluna de Interactive Report.
- **Multiple (Report)**: renderiza várias linhas, com paginação, agrupamento, seleção de linhas, faceted search/smart filters, *external Order By* e navegação por teclado.
- Em qualquer HTML Expression que aceite directives, via `{with/}…{apply NOME/}`.

Quando usar: um card, badge, linha de lista ou bloco visual que se repete em várias páginas. Quando não usar: componentes com lógica de servidor própria, Ajax ou acesso a dados fora de uma fonte de região (use plug-in de região/item com PL/SQL).

O UT traz Template Components prontos: **Comments**, **Content Row**, **Media List** (com avatars e badges), **Timeline**, **Metric Card** (26.1), **Blank Page** (26.1), além do Avatar, usado nos exemplos como `{apply THEME$AVATAR/}`. Para ver os do tema: *Shared Components > Templates*, ordenando por tipo *Template Component*.

No 26.1, colunas de Interactive Report baseadas em Template Component podem ser **ordenadas e filtradas pelo valor** (agregações, control break, highlight, computations, charts, group by e pivot continuam desabilitados).

Fonte: [Template Components](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/template-components.html), [About Template Component Type Plug-ins](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-plug-ins.html), [Template Component Overview](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/template-component-overview.html), [Changed Behavior: Template Component-based Columns in Interactive Reports](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html)

### Disponibilidade (Available as) e templates que compõem o componente

Criar: *Plug-ins > Create > From Scratch*, **Type = Template Component**, HTML em *Templates*. O atributo **Available as** decide o uso no Page Designer:

| Opção | Comportamento |
|---|---|
| *Multiple (Report)* | região com várias linhas, paginação e agrupamento; mostra a seção Source |
| *Single (Partial)* | uma linha (coluna de IR ou região de linha única). A fonte deve devolver **no máximo uma linha**, ou dá erro em runtime |
| *Region Only* | região com valores estáticos; o HTML vai sem wrapper e com poucos atributos (sem Region Template, Header, Footer). Inclua `#APEX$DOM_ID#` como `id` de um elemento para o APEX funcionar |
| nenhuma marcada | só via `{with/}…{apply/}` |

Templates:
- **Partial** (sempre existe): o HTML principal.
- Se *Multiple (Report)*: **Report Row** (envolve cada linha e inclui a partial com `#APEX$PARTIAL#`), **Report Group** (cada grupo; inclui as linhas com `#APEX$ROWS#`), **Report Body** (página atual de linhas, `#APEX$ROWS#`), **Report Container** (envolve o body com `#APEX$REPORT_BODY#`).

APEXlang (`plugin`, grupo `templateComponent`): `availableAs` (`partial`, `report`, `regionOnly`), `partial`, `reportBody`, `reportGroup`, `reportRow`, `reportContainer`, `translateTemplates`, `defaultEscapeMode` (`html` padrão, `htmlAttribute`, `stripHtml`, `raw`), `numberOfLazyLoadingSkeletons`; grupo `defaultSlots` (`regions`, `items`, `buttons`).

Fonte: [Controlling Component Availability](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/controlling-component-availability.html), [Templates Comprising the Component](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/templates-comprising-component.html), [APEXlang API Reference: plugin](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Custom attributes de Template Component: escopos e uso no template

Os **custom attributes** são os placeholders que o desenvolvedor preenche no Property Editor. Use **Static ID em maiúsculas** (`MY_PLACEHOLDER`) e referencie no template como `#MY_PLACEHOLDER#`. O botão **Synchronize from Templates** cria de uma vez os atributos para todos os placeholders encontrados.

O escopo define em que template o valor existe:

| Scope | Disponível em |
|---|---|
| Component | Partial |
| Report | Partial, Report Row, Report Body, Report Group, Report Container |
| Report Group | Report Group |

O tipo do atributo muda o editor: *Session State Value* oferece as colunas da fonte; *Yes/No* vira switch; *Select List* lista opções fixas; há também ícone (icon picker), cor, HTML (code editor), link (link builder) etc. Atributos relacionados podem ir para um **attribute group** (seção própria no Property Editor); sem grupo, ficam em *Settings*. Help text e examples aparecem na aba Help.

Fonte: [Custom Attributes for Data and Settings](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/custom-attributes-data-and-settings.html), [Attribute Scopes and Availability to Templates](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/attribute-scopes-and-availability-templates.html), [About Template Component Type Plug-ins](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-plug-ins.html)

### Slots: compor regiões, itens e botões dentro do componente

**Slots** (antes chamados Display Points e depois Positions) são áreas do template onde o desenvolvedor coloca outros componentes. Defina o slot e inclua `#NOME_DO_SLOT#` no template:

```html
{if ACTION_BUTTONS/}
  <div class="action-buttons">#ACTION_BUTTONS#</div>
{endif/}
{if HEIGHT/}
  <div style="height:#HEIGHT#">#MAIN_CONTENT#</div>
{else/}
  #MAIN_CONTENT#
{endif/}
```

Configurações do slot: que tipos aceita (só botões, só regiões, só certos tipos de item ou região), se usa o **grid de 12 colunas**, e **default slots** (onde caem por padrão subregiões, itens e botões). Efeito no Page Designer: itens/regiões criados no slot assumem o primeiro tipo permitido; no Rendering e no Layout não dá para soltar tipos não suportados; no Property Editor eles ficam ocultos em *Unsupported* (*Show Unsupported* mostra). É uma restrição "suave": pelo Property Editor ainda dá para mover um tipo não suportado para o slot.

Fonte: [Slots Enable Component Composition](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/slots-enable-component-composition.html), [About Template Component Type Plug-ins: Slots](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-plug-ins.html)

### Action Positions e Action Templates: botões e menus por linha

Em componentes de uma ou várias linhas, **action positions** são slots por linha onde o desenvolvedor define botões ou menus. Inclua `#NOME_DA_POSICAO#` no Partial ou no Report Row. Cada posição usa um **action template** (HTML do botão simples ou do botão de menu). No Page Designer, o desenvolvedor define a ação de cada botão/menu e pode usar condições por linha (ex.: o menu "Ações" do Content Row com subentradas).

Fonte: [Action Positions and Action Templates](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/action-positions-and-action-templates.html)

### Agrupamento, paginação e seleção de linhas em Template Components

- **Agrupamento**: em *Multiple (Report)*, ligue *Group* em uma ou mais colunas da fonte (que precisam estar no `ORDER BY`). Aparecem atributos de *Report Group* e o template **Report Group** formata cada combinação distinta.
- **Paginação**: rolagem ou páginas com N linhas, com ou sem agrupamento.
- **Seleção**: marque **Has Row Selection Support** (*Standard Attributes*). No Page Designer aparece a seção *Row Selection*: seleção única, múltipla ou só foco, e o item que guarda as chaves selecionadas (*Current Selection Page Item*, separadas por `:`). *Entity Title* (singular/plural) deixa a mensagem "2 funcionários selecionados" legível. No template, `#APEX$SELECTOR#` vira radio ou checkbox por linha.

Processando a seleção num processo de página:

```plsql
for r in ( select column_value id
             from apex_string.split_numbers(:P26_SELECIONADOS, ':') )
loop
    null; -- processar r.id
end loop;
```

Fonte: [Presenting Grouped Data](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/presenting-grouped-data.html), [Configuring Pagination Support](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configuring-pagination-support.html), [Enabling Row Selection](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/enabling-row-selection.html)

### Arquivos do Template Component, aplicação por directive e partials no cliente

- **Arquivos**: CSS e JS do componente ficam na aba *Files* do componente (o APEX gera `.min` ao salvar). Liste-os em **File URLs to Load** pela coluna *Reference*, um por linha. Eles só carregam nas páginas que usam o componente.
- **Aplicar por nome** em qualquer atributo que aceite directives:

```
{with/}
NAME:=&ENAME.
VALUE:=&SAL.
{apply MEU_COMPONENTE/}
```

O Static ID de um Template Component de tema sempre tem o prefixo `THEME$` (ex.: `THEME$COM.MYCOMPANY.BADGE`), e é esse ID que se usa no `{apply/}`. Componentes podem ser aninhados (um template aplica outro). `{with/}…{apply/}` usa renderização no servidor.

- **Partials no cliente (26.1)**: o mesmo `{with/}…{apply/}` funciona em componentes renderizados no navegador: itens Combobox, Select Many e Select One, e regiões Maps, colunas de Interactive Grid e Cards. Se o componente tem CSS/JS, o APEX carrega os arquivos dinamicamente.

```
{with/}
TYPE:=INITIALS
INITIALS:=MH
{apply THEME$AVATAR/}
```

Fonte: [Defining Files and File URLs to Load](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/defining-files-and-file-urls-load.html), [Applying Template Using Directives](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/applying-template-using-directives.html), [Creating a Plug-in from Scratch](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-plug-ins.html), [New Features: Client-side Template Component Partials](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### Copiar um Template Component do tema para customizar

Para customizar um Template Component do UT sem alterar o original: *Plug-ins > Create > As a Copy of an Existing Plug-in*, escolha a app de origem e o **Theme** (com tema escolhido, só Template Components aparecem), dê um nome e marque *Copy = Yes*. Depois edite atributos, action positions, action templates e arquivos.

Fonte: [Template Component Type Plug-ins](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/template-component-type-plug-ins.html)

---

## 12. Plug-ins

### O que é um plug-in e quais são os tipos

Um **plug-in** adiciona um tipo novo ao APEX: aparece como mais um tipo de região, item, dynamic action, processo etc. no Page Designer e é usado de forma declarativa pelo time. Antes de criar, procure em `https://apex.world` e nos exemplos do repositório oficial no GitHub (`github.com/oracle/apex`, pasta Plug-ins de cada release).

Tipos (Create Plug-in > *Type*; enum APEXlang):

| Tipo | APEXlang | Para quê |
|---|---|---|
| Authentication Scheme Type | `authenticationScheme` | identificar o usuário |
| Authorization Scheme Type | `authorizationScheme` | decidir acesso a página/componente |
| Dynamic Action | `dynamicAction` | nova ação no cliente (com *Category*) |
| Generative AI Tool | `genAITool` | ferramenta para agentes de IA |
| Item | `item` | novo tipo de item (page items, colunas de IG, facets, filters) |
| Process | `process` | novo processo (páginas, automations, task definitions, workflows) |
| REST Data Source | `restDataSource` | adaptador de REST Data Source |
| Region | `region` | novo tipo de região |
| Template Component | `templateComponent` | componente só com HTML (seção 11) |
| (APEXlang) | `interactiveReportColumn` | tipo listado no enum do APEXlang |

Etapas: criar ou importar o plug-in, usá-lo num componente do tipo e testar. Plug-ins podem ser exportados e importados e aceitam subscription.

Fonte: [About Plug-ins](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-plug-ins.html), [Creating Plug-ins](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-plug-ins.html), [Adding Functionality with Plug-ins](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/adding-functionality-plug-ins.html), [APEXlang API Reference: plugin](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Criar plug-in: Name, APEXlang Name, Static ID, Source e Callbacks

Shared Components > Other Components > **Plug-ins** > Create > *From Scratch*:

| Campo | Regras |
|---|---|
| Name | nome exibido no Page Designer |
| **APEXlang Name** (26.1) | nome camelCase (sem espaços) usado no APEXlang; gerado automaticamente. Mudar afeta import/export APEXlang. No `.apx`: até 40 caracteres, começa com minúscula ou dígito |
| **Static ID** (antes "internal name") | único na app; a Oracle recomenda prefixar com o domínio da empresa: `COM.MYCOMPANY.SLIDER`. Template Components de tema recebem `THEME$`. APEXlang: até 45 caracteres |
| Type | ver tabela anterior; *Category* para Dynamic Action |
| Source, PL/SQL Code | bloco anônimo com as procedures/funções de callback. **Por desempenho, coloque o código num package do banco** |
| Do not validate PL/SQL code | parse só em runtime |
| Callbacks | nomes das procedures/funções; podem estar no bloco, num package ou ser standalone |
| Standard Attributes | atributos padrão que o tipo oferece (variam por tipo) |
| Information | Version, About URL, Help Text, Comments |

Callbacks por tipo (APEXlang `callbacks`):

| Tipo | Callbacks |
|---|---|
| Region | `renderProcedureName`, `ajaxProcedureName` |
| Item | `renderProcedureName`, `metaDataProcedureName`, `ajaxProcedureName`, `validationProcedureName` |
| Dynamic Action | `renderProcedureName`, `ajaxProcedureName` |
| Process | `executionFunctionProcedureName` (com *Wait for Completion*: `completionFunctionProcedureName`, `terminationFunctionProcedureName`) |
| Authorization | `executionFunctionProcedureName` |
| Authentication | `sessionSentryProcedureName`, `invalidSessionProcedureName`, `authenticationProcedureName`, `postLogoutProcedureName`, `ajaxProcedureName` |
| REST Data Source | `restSourceCapabilitiesProcedure`, `restSourceFetchProcedure`, `restSourceDmlProcedure`, `restSourceExecuteProcedure`, `restSourceDiscoverProcedure` |

`apiInterface` (padrão `3` no APEXlang) define se as callbacks usam a interface antiga (funções que retornam um record) ou a de **procedures** com parâmetro `in out` de resultado.

Fonte: [Creating a Plug-in from Scratch](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-plug-ins.html), [New Features: APEXlang Name for Plug-ins](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html), [APEXlang API Reference: plugin](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Assinaturas das callbacks PL/SQL (interface Procedure) e tipos do APEX_PLUGIN

Interface de **procedures** (unlimited attributes). No 26.1 ela chega a Authorization, Authentication, REST Source, Dynamic Action e Process; para plug-ins existentes, troque *API Interface* para `Procedure` e ajuste o código.

```plsql
-- Dynamic Action: render
procedure render (
    p_dynamic_action in            apex_plugin.t_dynamic_action,
    p_plugin         in            apex_plugin.t_plugin,
    p_param          in            apex_plugin.t_dynamic_action_render_param,
    p_render_result  in out nocopy apex_plugin.t_dynamic_action_render_result );

-- Process: execução
procedure executar (
    p_process in            apex_plugin.t_process,
    p_plugin  in            apex_plugin.t_plugin,
    p_result  in out nocopy apex_plugin.t_process_exec_result );

-- Authorization: execução
procedure autorizar (
    p_authorization in            apex_plugin.t_authorization,
    p_plugin        in            apex_plugin.t_plugin,
    p_result        in out nocopy apex_plugin.t_authorization_exec_result );

-- Item: render
procedure render_item (
    p_item   in            apex_plugin.t_item,
    p_plugin in            apex_plugin.t_plugin,
    p_param  in            apex_plugin.t_item_render_param,   -- value, clob_value, is_readonly, is_printer_friendly
    p_result in out nocopy apex_plugin.t_item_render_result ); -- is_navigable, navigable_dom_id, item_rendered
```

Authentication (procedures novas): session sentry (`p_authentication`, `p_plugin`, `p_is_public_page`, `p_result t_authentication_sentry_result`), invalid session (`t_authentication_inval_result`), authentication (`p_password`, `t_authentication_auth_result`), post logout (`t_authentication_logout_result`) e Ajax (`t_authentication_ajax_result`).

Exemplo de render de Dynamic Action na interface nova: o PL/SQL só informa a função JS e os parâmetros, e o JS recebe `(settings, daConfig)`:

```plsql
procedure render ( p_dynamic_action in apex_plugin.t_dynamic_action,
                   p_plugin         in apex_plugin.t_plugin,
                   p_param          in apex_plugin.t_dynamic_action_render_param,
                   p_render_result  in out nocopy apex_plugin.t_dynamic_action_render_result )
as
begin
    p_render_result.function_name := 'minhaFuncao';
    p_render_result.function_param.open_object;
    p_render_result.function_param.put( 'total',  p_dynamic_action.attributes.get_number('total-value') );
    p_render_result.function_param.put( 'ativo',  p_dynamic_action.attributes.get_boolean('is-true') );
    p_render_result.function_param.close_object;
end;
```

```javascript
window.minhaFuncao = ( settings, daConfig ) => {
    const { total, ativo } = settings;
    apex.da.resume( daConfig.resumeCallback, false );
};
```

Tipos em `APEX_PLUGIN`: `t_plugin` (`static_id`, `file_prefix`, `attributes`; os `attribute_01..15` estão deprecated), `t_plugin_attributes` (`get_varchar2`, `get_number`, `get_boolean`, `put`), `t_dynamic_action` (`id`, `name`, `static_id`, `action`, `attributes`, `init_javascript_code`, `affected_elements`…), `t_item_validation_result` (`message`, `display_location`, `page_item_name`), `t_region_render_param` (`is_printer_friendly`), `t_region_render_result` (`navigable_dom_id`), constantes de escape `c_escape_mode_raw|html|html_attribute|javascript|striphtml|json`.

Fonte: [New Features: Unlimited Attributes for Plug-in Types](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html), [APEX_PLUGIN Data Types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_PLUGIN-Data-Types.html), [PRINT_READ_ONLY Procedure Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PRINT_READ_ONLY-Procedure-Signature-2.html)

### Custom Attributes de plug-in: escopo, Static ID, tipo, dependência e Template Support

Edite o plug-in > *Custom Attributes* > **Add Attribute**:

| Grupo | Atributo | Notas |
|---|---|---|
| Name | **Scope** | *Application* (definido uma vez por app, lido via `t_plugin.attributes`), *Component* (por uso), *Report* / *Report Group* (template components em modo report) |
| | Attribute | sequência que corresponde às colunas `ATTRIBUTE_XX` (interface antiga) |
| | Display Sequence, Label, **APEXlang Name** | |
| | **Static ID** | plug-ins comuns: minúsculas (`my-static-id`), lidas por `p_x.attributes.get_varchar2('my-static-id')`; template components: maiúsculas (`MY_PLACEHOLDER`, usadas como `#MY_PLACEHOLDER#`) |
| Settings | **Type** | ver tabela seguinte |
| | Common, Show in Wizard, Required, **Translatable** (entra no XLIFF), Display Width, Maximum Length, Set Text Case, Unit | |
| Default Value | Default Value | use `Y`/`N` em Yes/No |
| Condition | **Depending On** | só mostra se outro atributo tiver certo valor |
| Help Text and Examples | **Template Support** (26.1) | *None*, *Substitutions*, *Template Directives - Client* (destaque de sintaxe e ajuda no Page Designer; o código do plug-in continua responsável por substituir e processar as directives) |
| | Help Text, Examples | aparecem na aba Help |

Substituições nos valores: na interface Procedure, o switch *Substitute Attribute Values* some (deprecated) e as substituições são pedidas na leitura:

```plsql
l_valor := p_dynamic_action.attributes.get_varchar2 (
               p_static_id                 => 'my_static_id',
               p_do_substitutions          => true,
               p_substitutions_escape_mode => apex_session_state.c_escape_mode_html );
```

`p_do_substitutions` e `p_do_serveronly_substitutions` não podem ser usados na mesma chamada. Na migração para o 26.1, os atributos existentes recebem Static IDs `attribute_01`, `attribute_02`… Para atributos novos, a Oracle sugere IDs curtos, minúsculos e descritivos (`css_classes`, `page_item_name`).

Dicionário: os atributos de plug-ins de authorization, authentication, REST source e dynamic action passam a ser lidos da coluna JSON `attributes` (ex.: `select da.attributes.my_static_id from apex_application_page_da_acts da`); as colunas `attribute_01..15` dessas views ficam obsoletas e retornam null.

Fonte: [Adding Custom Attributes to a Plug-in](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-plug-ins.html), [New Features: Unlimited Attributes for Plug-in Types](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html), [APEX_PLUGIN Data Types: t_plugin_attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_PLUGIN-Data-Types.html)

### Tipos de atributo de plug-in

| Tipo | Uso |
|---|---|
| Checkboxes | lista de checkboxes; valores marcados separados por `:` |
| Color | cor HEX com color picker |
| HTML | HTML com code editor; traduzível |
| Icon | classes de ícone com icon picker |
| Integer / Number | inteiro / decimal |
| JavaScript | código JS com code editor |
| Link to Target Page/URL | link builder |
| PL/SQL Code | bloco anônimo |
| PL/SQL Expression Returning VARCHAR2 | expressão |
| PL/SQL Function Body Returning BOOLEAN / VARCHAR2 | function body |
| Page Item / Page Items | um item / lista de itens separada por vírgula |
| Page Number / Page Numbers | página(s) |
| Region SQL Statement Column | coluna da SQL da região (só plug-ins de região) |
| SQL Query | SQL com número de colunas definido |
| Select List | opções fixas |
| Text / Textarea | texto (traduzível) |
| XML | XML com code editor |
| Yes/No | switch |

Fonte: [Plug-in Attribute Types](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-plug-ins.html)

### Standard Attributes de plug-ins de item

| Atributo | Significado |
|---|---|
| Is Visible Widget | o item é visível (pré-requisito da maioria dos demais) |
| Standard Form Element | renderiza `input`/`select`/`textarea`. Desmarcado, `GET_ELEMENT_ATTRIBUTES` adiciona `aria-labelledby` (exige `#LABEL_ID#` no label template) |
| Session State Changeable | valor pode mudar em session state |
| Has Read Only Attribute / Has Escape Special Characters Attribute / Has Quick Pick Attributes | expõem esses atributos no Page Designer |
| Has Source Attributes (+ Format Mask Date Only / Number Only) | Source Used, Source Type, Format Mask |
| Has Element / Width / Height / Element Option / Placeholder / Icon Attribute | atributos visuais |
| Has Encrypt Session State Attribute | "Store value encrypted in session state" |
| Has List of Values (+ List of Values Required, Has LOV Display Null Attributes, Has Cascading LOV Attributes, Join LOV for Column Display) | suporte a LOV |
| Optional Multiple Values / Always Multiple Values | multivalor opcional ou sempre (shuttle, checkboxes) |
| Has Filter / Has Link | mostra filtro e link em colunas de IG |
| Has "Initialization JavaScript Code" Attribute | configuração por função JS |
| Session State Supports CLOB | mostra o grupo Session State |

APEXlang: `component.supports` (`pageItems`, `interactiveGridColumns`, `facets`, `facetGroupItems`, `filters`, `filterGroupItems`) e `supportsSessionStateDataTypes` (`varchar2`, `clob`, `boolean`).

Fonte: [Standard Attributes for Item Type Plug-ins](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-plug-ins.html), [APEXlang API Reference: plugin](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Arquivos do plug-in, File URLs to Load, Attribute Groups e Events

- **Files**: *File Prefix* (vazio = arquivos guardados com o plug-in no banco; ou `#APEX_FILES#`/URL do web server, por desempenho). *Create File* com Directory, File Name e Content.
- **File URLs to Load**: *Cascading Style Sheet* (emitidos em `#APEX_CSS#`) e *JavaScript* (emitidos em `#GENERATED_JAVASCRIPT#`), um por linha, com `#MIN#`, `#MIN_DIRECTORY#` e **`#PLUGIN_FILES#`** (o file prefix do plug-in). O APEX carrega esses arquivos **só nas páginas que usam o plug-in**, na ordem listada.
- **Attribute Groups** (Item, Region, Process, Dynamic Action): *Title* + *Sequence*; nomes únicos por plug-in. Atributos sem grupo ficam em *Settings*.
- **Events** (Item, Region, Dynamic Action): *Name* (exibido como evento em Dynamic Actions, ex.: "Start Slide") + *Internal Name* (evento JS disparado, ex.: `slidestart`). Assim o time cria DAs que reagem ao plug-in.

Fonte: [Creating a File to Associate with a Plug-in](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-plug-ins.html), [Automatically Loading CSS and JavaScript Files](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-plug-ins.html), [Creating Attribute Groups](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-plug-ins.html), [Adding Events to a Plug-in](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-plug-ins.html)

### APEX_PLUGIN_UTIL: utilitários mais usados em plug-ins

| API | Para quê |
|---|---|
| `GET_ELEMENT_ATTRIBUTES (p_item, p_name, p_default_class, p_add_id, p_add_required, p_add_labelledby, p_aria_describedby_id, p_add_multi_value)` | atributos padrão do elemento HTML (id, name, required, placeholder, classes, aria) |
| `GET_DATA2` / `GET_DATA` / `GET_DISPLAY_DATA` | executa SQL (LOV, região) e devolve colunas tipadas, com busca e paginação (`p_search_type` = `c_search_contains_case`, `c_search_contains_ignore`, `c_search_exact_case`, `c_search_exact_ignore`) |
| `PRINT_LOV_AS_JSON (p_sql_statement, p_component_name, p_escape, p_replace_substitutions)` | resposta Ajax `[{"d":..,"r":..}]` com header JSON |
| `PRINT_HIDDEN`, `PRINT_READ_ONLY`, `PRINT_ESCAPED_VALUE`, `PRINT_OPTION`, `PRINT_JSON_HTTP_HEADER` | saída HTML padronizada |
| `GET_PLSQL_EXPRESSION_RESULT`, `GET_PLSQL_FUNCTION_RESULT` (+ variantes BOOLEAN/CLOB) | avaliam código informado em atributos |
| `REPLACE_SUBSTITUTIONS`, `ESCAPE`, `IS_EQUAL`, `GET_SEARCH_STRING` | utilidades |
| `DEBUG_REGION`, `DEBUG_PROCESS`, `DEBUG_DYNAMIC_ACTION` | escreve os atributos no debug |
| `APEX_PLUGIN.GET_AJAX_IDENTIFIER`, `GET_INPUT_NAME_FOR_ITEM` | identificador para `apex.server.plugin` e nome do input |

`PAGE_ITEM_NAMES_TO_JQUERY`, `EXECUTE_PLSQL_CODE`, `GET_POSITION_IN_LIST`, `PRINT_DISPLAY_ONLY` e `DEBUG_PAGE_ITEM` estão marcados como deprecated.

```plsql
sys.htp.prn( '<input type="text" '
          || apex_plugin_util.get_element_attributes( p_item, l_name, 'text_field' )
          || 'value="' || l_valor_escapado || '" />' );
```

Fonte: [APEX_PLUGIN_UTIL](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_PLUGIN_UTIL.html), [GET_ELEMENT_ATTRIBUTES](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_ELEMENT_ATTRIBUTES-Function.html), [GET_DATA2 Function Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_DATA2-Function-Signature-1.html), [PRINT_LOV_AS_JSON](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PRINT_LOV_AS_JSON-Procedure.html), [APEX_PLUGIN](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_PLUGIN.html)

### Distribuir plug-ins: importar do apex.world, copiar, assinar, exportar e excluir

- **Importar** (ex.: da apex.world): baixe o `.sql` (ex.: `region_type_plugin_material_kanban.sql`) e use *Plug-ins > Import* com File Type *Plug-in*. O plug-in passa a aparecer como tipo de região/item no Page Designer; configure conforme a documentação dele (no exemplo Kanban, um JSON de colunas e uma SQL com aliases como `TITLE`, `COLUMN_ID`, `GROUP_TITLE`).
- **Copiar/assinar** de outra app: *Copy from another app* (Yes, No, Copy and Subscribe). Para Template Components, escolha o Theme; deixe vazio para plug-ins fora de tema.
- **Exportar**: *Workspace Utilities > Export > Plug-ins* (ou *Tasks > Export Plug-in*), gera `.sql`.
- **Excluir**: só se não estiver em uso; com uso, o botão Delete nem aparece.
- *Utilization* mostra onde cada plug-in é usado; *History* mostra quem mudou o quê; *View Plug-in Repository* abre o repositório de plug-ins; *Reset* limpa os filtros do relatório.

Fonte: [Downloading and Importing a Plug-in](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/downloading-and-importing-plug.html), [Configuring the Kanban Plug-in](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configuring-kanban-plug.html), [Copying or Subscribing to a Plug-in](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/copying-or-subscribing-to-a-plug-in.html), [Exporting Plug-ins](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/exporting-plug-ins.html), [Deleting a Plug-in](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/deleting-a-plug-in.html)

### Botão Delete não aparece na página do plug-in

**Sintoma:** não há como excluir um plug-in.
**Causa:** o plug-in está em uso; o Delete só aparece para plug-ins sem uso.
**Correção:** veja a aba *Utilization*, troque o tipo dos componentes que o usam e volte à página do plug-in.

Fonte: [Deleting a Plug-in](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/deleting-a-plug-in.html)

### Limite de 25 custom attributes em plug-ins de autenticação, autorização e REST Source

**Sintoma:** não dá para criar mais custom attributes num plug-in de Authentication, Authorization ou REST Data Source.
**Causa:** o App Builder User's Guide 26.1 ainda diz que o máximo nesses tipos é 25, enquanto as Release Notes 26.1 dizem que esses tipos ganharam atributos ilimitados com a interface **Procedure** (e que REST Source mantém a interface antiga sem mudanças). As duas fontes oficiais divergem.
**Correção:** mude *API Interface* para `Procedure`, migre o código para `p_x.attributes.get_varchar2('static_id')` e teste se o limite some (confirmar no 26.1.5).

Fonte: [Adding Custom Attributes to a Plug-in](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-plug-ins.html), [New Features: Authorization, Authentication, and REST Source Plug-ins](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

---

## 13. Globalização

### Como o APEX decide o idioma: Application Primary Language e Application Language Derived From

Uma única instância do banco e do APEX atende sessões em idiomas diferentes. Na *Globalization* (Shared Components > Globalization Attributes, ou Edit Application Definition > aba Globalization):

- **Application Primary Language**: idioma em que a app é desenvolvida e base de todas as traduções. Toda alteração é feita na app primária (as traduzidas são geradas).
- **Application Language Derived From** (com Translate Application ligado aparece como *Translation Language Derived From*):

| Opção | Idioma usado |
|---|---|
| *No NLS (Application not translated)* | app não traduzida |
| *Application Primary Language* | sempre o primário |
| *Browser (use browser language preference)* | preferência de idioma do navegador |
| *Application Preference (use FSP_LANGUAGE_PREFERENCE)* | preferência gravada com `APEX_UTIL.SET_PREFERENCE`; persiste entre logins |
| *Item Preference (use item containing preference)* | application item chamado `FSP_LANGUAGE_PREFERENCE`; precisa ser definido a cada login |
| *Session* | idioma da sessão, definido por `APEX_UTIL.SET_SESSION_LANG` ou pelo parâmetro `P_LANG` da URL |

Ao determinar o idioma, o APEX altera o idioma da sessão de banco para aquela requisição. O idioma afeta a tradução usada e também o NLS (formatos de número, data e moeda; ver códigos). O idioma do navegador também fica em `BROWSER_LANGUAGE` (`:BROWSER_LANGUAGE`, `APEX_APPLICATION.G_BROWSER_LANGUAGE`).

Fonte: [Before You Begin: Configure Globalization Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/before-you-begin-configure-globalization-attributes.html), [About Language Identification](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-application-translation-and-globalization-support.html), [Determining User's Preferred Language](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/determining-users-preferred-language.html), [BROWSER_LANGUAGE](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-available-built-in-substitution-strings.html)

### Regras para escolher a versão traduzida (match exato, truncado e primário)

1. Procura a tradução com código **exatamente igual** à preferência do usuário.
2. Senão, procura um **match truncado** (idioma sem a região): preferência `en-us` sem tradução `en-us` cai em `en`.
3. Senão, usa o **idioma primário**.

Exemplo da documentação: app primária `de` com tradução `en-us`. Usuário com navegador `en-gb` vê a app em **alemão**. O correto seria publicar a tradução como `en`, que cobre todas as variações de inglês.

Fonte: [About the Rules for Translating Applications](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-application-translation-and-globalization-support.html)

### Usuário com navegador em variante regional vê a app no idioma primário

**Sintoma:** quem usa `en-gb` (ou `pt-pt`, `es-mx`) vê a app no idioma primário, apesar de existir tradução para outra variante do mesmo idioma.
**Causa:** o APEX procura o código exato e depois o idioma sem região; não procura uma variante "irmã" (`en-gb` não cai em `en-us`).
**Correção:** publique a tradução com o código genérico do idioma (`en`, `es`) ou crie uma tradução por variante.

Fonte: [About the Rules for Translating Applications](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-application-translation-and-globalization-support.html)

### Atributos de globalização: formatos de data e timestamp, ordenação, time zone e CSV

| Atributo | Efeito |
|---|---|
| Document Direction | *Language Default*, *Left-To-Right*, *Right-To-Left* |
| **Application Date Format** | altera `NLS_DATE_FORMAT` da sessão antes de mostrar ou enviar páginas. Máscara literal (`Month DD, YYYY`) ou item (`&MY_DATE_FORMAT.`). Vazio = herda da sessão de banco |
| **Application Date Time Format** | só exposto como `&APP_DATE_TIME_FORMAT.` / `v('APP_DATE_TIME_FORMAT')`; **não altera NLS**. Vazio = NLS date + time format da sessão |
| **Application Timestamp Format** | altera `NLS_TIMESTAMP_FORMAT` (ex.: `DD-MON-RR HH.MI.SSXFF AM`) |
| **Application Timestamp Time Zone Format** | altera `NLS_TIMESTAMP_TZ_FORMAT` (ex.: `... AM TZR`) |
| Character Value Comparison | altera `NLS_SORT` (ex.: `BINARY`, `GERMAN`) nas queries de classic e interactive reports |
| Character Value Comparison Behavior | `NLS_COMP`: padrão da sessão, *Binary* ou *Linguistic* (usa o NLS_SORT); vale em classic report, interactive report, List view e na API de plug-ins |
| **Automatic Time Zone** | On = deriva o fuso do navegador e ajusta o time zone da sessão de banco a cada page view. `APEX_UTIL.SET_SESSION_TIME_ZONE` sobrescreve e `RESET_SESSION_TIME_ZONE` volta ao padrão. **No 26.1 usa nomes de fuso**: `SESSIONTIMEZONE` pode retornar `Europe/Paris` em vez de `+01:00` |
| **Automatic CSV Encoding** | padrão On: converte o CSV dos relatórios para o charset do desktop do idioma do usuário (ex.: `de` → Windows 1252; `zh-cn` → GBK), evitando caracteres corrompidos no Excel |

Valores disponíveis em substituições: `APP_NLS_DATE_FORMAT`, `APP_NLS_TIMESTAMP_FORMAT`, `APP_NLS_TIMESTAMP_TZ_FORMAT`, `APP_DATE_TIME_FORMAT`.

Fonte: [Configuring Globalization Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-globalization-attributes.html), [Changed Behavior: Automatic Time Zone Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html)

### Format masks em itens e colunas

O engine aplica as configurações de globalização a cada página renderizada. Se o idioma vem do navegador e ele está em francês, datas e números saem no padrão francês. Para controlar explicitamente, defina *Appearance, Format Mask* no item (ou na coluna). A máscara de item/coluna tem precedência sobre o padrão da sessão.

Fonte: [Applying Format Masks to Items](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/applying-format-masks-to-items.html)

### Códigos de globalização: NLS_LANGUAGE e NLS_TERRITORY por idioma

`NLS_LANGUAGE` e `NLS_TERRITORY` determinam a apresentação padrão de números, datas e moedas e são definidos automaticamente pelo idioma da app. Alguns códigos:

| Idioma | Código | NLS_LANGUAGE | NLS_TERRITORY |
|---|---|---|---|
| English | `en` | AMERICAN | AMERICA |
| English (United States) | `en-us` | AMERICAN | AMERICA |
| English (United Kingdom) | `en-gb` | ENGLISH | UNITED KINGDOM |
| **Portuguese (Brazil)** | **`pt-br`** | **BRAZILIAN PORTUGUESE** | **BRAZIL** |
| Portuguese (Portugal) | `pt` | PORTUGUESE | PORTUGAL |
| Spanish (Traditional Sort) | `es` | LATIN AMERICAN SPANISH | SPAIN |
| Spanish (Mexico) | `es-mx` | MEXICAN SPANISH | MEXICO |
| French (France) | `fr` | FRENCH | FRANCE |
| German (Germany) | `de` | GERMAN | GERMANY |
| Italian (Italy) | `it` | ITALIAN | ITALY |
| Japanese | `ja` | JAPANESE | JAPAN |
| Chinese (China) | `zh-cn` | SIMPLIFIED CHINESE | CHINA |

A tabela completa (mais de 100 códigos) está na fonte. O APEXlang (`textMessage.language`) aceita os mesmos códigos, incluindo `pt-br`.

Para apps que rodam em vários idiomas ao mesmo tempo (chinês e japonês, por exemplo), o banco precisa de um character set que cubra todos: `UTF8` ou `AL32UTF8`.

Fonte: [Understanding Supported Globalization Codes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-supported-globalization-codes.html), [About Translating Applications for Multibyte Languages](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-translating-for-multibyte-languages.html)

---

## 14. Tradução

### Duas estratégias: Application-Based × Text Message-Based

Para traduzir, ligue **Translate Application** em Globalization e escolha o **Translate Method**:

| | **Application-Based** | **Text Message-Based** |
|---|---|---|
| Como funciona | cada idioma vira uma **app traduzida separada** (cópia oculta da primária com os textos trocados) | **uma única app**; todo texto traduzível vira **Text Message** referenciada por `&{NOME}.` |
| Fluxo | mapear idioma → seed → XLIFF → traduzir → aplicar → **publicar** | converter textos em mensagens → adicionar idioma → exportar XLIFF/CSV → importar |
| Mudança na app primária | repetir seed, XLIFF, aplicar e publicar (senão a tradução fica dessincronizada) | rodar *Convert to Text Messages* / *Sync* de novo para capturar textos novos |
| Renderização | o APEX procura a app traduzida do idioma; se não houver, usa a primária | mesma app; mensagem sem tradução cai na do idioma primário |

O Developer's Companion recomenda **Text Message-Based** como a abordagem mais simples e com melhor suporte no App Builder e no Page Designer.

Fonte: [Understanding the Translation Process](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-the-translation-process.html), [Overview of the Translation Process / How Translated Applications Are Rendered](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-application-translation-and-globalization-support.html), [Enabling the First Translation Language](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/enabling-first-translation-language.html), [New Features: Text Message-Based Application Translations](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### Tradução Application-Based passo a passo (mapping, seed, XLIFF, apply, publish)

1. **Habilitar**: Globalization > Translate Application = On, Translate Method = *Application-Based*.
2. **Define application languages** (Application Translations > *Define application languages* > Create): *Translation Application* (ID inteiro único na instância; a API exige que **não termine em 0**), *Language*, *Document Direction*, *Image Directory* (normalmente vazio).
3. **Seed translatable text**: copia todo texto traduzível para o *Translation Text repository*. Rode **sempre que a app primária mudar**.
4. **Download XLIFF**: arquivo da app inteira ou de uma página, com opção *Include XLIFF Target Elements* e *Export* de todos os elementos ou só dos novos/alterados. O APEX só trabalha com XLIFF em **UTF-8**.
5. **Traduzir** o XLIFF (padrão aberto, aceito por fornecedores de tradução). Tradução parcial é suportada: o que não tem tradução usa o texto primário.
6. **Apply XLIFF translation files**: *Upload Files*, selecione, escolha o mapeamento em *Apply to Translation* e *Apply Checked*. O APEX processa o arquivo e atualiza o repositório.
7. **Publish translated applications**: cria/atualiza a app traduzida.

Edição manual: *Translation Utilities > Translation Repository* (editar um texto, com *Update all occurrences of this string*) ou *Grid Edit*.

APIs equivalentes em `APEX_LANG`: `CREATE_LANGUAGE_MAPPING (p_application_id, p_language, p_translation_application_id, p_direction_right_to_left, p_image_directory)`, `SEED_TRANSLATIONS (p_application_id, p_language)`, `GET_XLIFF_DOCUMENT (p_application_id, p_page_id, p_language, p_only_modified_elements) return clob`, `APPLY_XLIFF_DOCUMENT (p_application_id, p_language, p_document)`, `UPDATE_TRANSLATED_STRING (p_id, p_language, p_string)`, `PUBLISH_APPLICATION (p_application_id, p_language, p_new_trans_application_id)`.

```plsql
begin
    apex_util.set_workspace( 'MEU_WORKSPACE' ); -- só fora de sessão APEX
    apex_lang.seed_translations  ( p_application_id => 100, p_language => 'en' );
    apex_lang.publish_application( p_application_id => 100, p_language => 'en' );
    commit;
end;
/
```

Views: `apex_application_trans_map` (mapeamentos), `apex_application_trans_repos` (repositório).

Fonte: [Creating an Application-Based Translation](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-an-application-based-translation.html), [Manually Editing a Translation](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/manually-editing-a-translation.html), [SEED_TRANSLATIONS](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SEED_TRANSLATIONS-Procedure.html), [PUBLISH_APPLICATION](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PUBLISH_APPLICATION-Procedure.html), [CREATE_LANGUAGE_MAPPING](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CREATE_LANGUAGE_MAPPING-Procedure.html)

### Tradução publicada não aparece ou não reflete as últimas mudanças

**Sintoma:** a app traduzida mostra textos antigos, não mostra campos novos ou nem aparece.
**Causa:** (1) a app primária mudou (theme refresh, título, item novo) e não houve novo seed + apply + **publish**; (2) o XLIFF foi aplicado, mas não publicado; (3) a globalização não leva àquele idioma (ex.: *Derived From* = Browser com o navegador em outro idioma). Apps traduzidas não aparecem na lista de apps do App Builder.
**Correção:** seed, exporte só os elementos novos/alterados, traduza, aplique e **publique**; teste com o idioma configurado (navegador, `P_LANG` ou preferência).
**Prevenção:** inclua seed + publish no roteiro de deploy de cada release.

Fonte: [Creating an Application-Based Translation](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-an-application-based-translation.html)

### Tradução Text Message-Based passo a passo (convert, add language, export/import)

1. **Habilitar**: Translate Method = *Text Message-Based*.
2. **Convert to Text Messages** (Application Translations > *Convert Text Messages*, ou Text Messages > *Tasks > Convert Application Text*): cria uma Text Message para cada texto traduzível único e troca o texto original por `&{NOME}.`. Textos iguais em várias páginas passam a usar **a mesma mensagem** (ex.: o rótulo "Date of Hire" do relatório e do formulário viram `DATE_OF_HIRE`). Não converte template directives, texto numérico, texto marcado como não traduzível nem objetos assinados.
3. **Add Language**: adicionar um idioma sincroniza as mensagens do idioma primário para ele (cópia inicial com o texto primário). Isso acontece automaticamente ao adicionar o primeiro idioma.
4. **Export Text Messages**: um idioma ou *All - Zipped file*, em **XLIFF** ou **CSV**. O XLIFF de um idioma se chama, por exemplo, `f154_en_it.xlf` (app, origem, destino); cada `trans-unit id` é o nome da mensagem e o `<target>` começa igual ao `<source>`.
5. **Import Text Messages**: suba o XLIFF, CSV ou ZIP traduzido. Não há publish: a app já usa as mensagens.

Conforme a app evolui: crie a mensagem antes (nome significativo) e use o **Text Messages Picker**, ou digite texto literal e depois rode **Sync Text Messages** no idioma. O sync converte os textos novos, cria as mensagens no primário e copia para o idioma de destino. *Convert to Text Messages* converte sem sincronizar com os idiomas de destino; o sync sempre faz o convert antes. Para traduções pequenas, use **Grid Edit** em Text Messages, filtrando por idioma.

APIs: `APEX_LANG.EXPORT_TEXT_MESSAGES (p_application_id, p_lang_code, p_format)` (`c_export_format_xliff` ou `c_export_format_csv`, retorna CLOB) e `APEX_LANG.IMPORT_TEXT_MESSAGES (p_application_id, p_file, p_format)`.

Fonte: [Creating a Text Message-Based Translation](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-a-text-message-based-translation.html), [Understanding Initial Text Message Sync](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-initial-text-message-sync.html), [Exporting and Importing Translations](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/exporting-and-importing-translations.html), [Synchronizing Text Messages Anytime](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/synchronizing-text-messages-anytime.html), [Centralizing Reusable UI Text](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/centralizing-reusable-ui-text.html), [EXPORT_TEXT_MESSAGES](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_LANG.EXPORT_TEXT_MESSAGES-Function-Signature-1.html), [IMPORT_TEXT_MESSAGES](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_LANG.IMPORT_TEXT_MESSAGES-Procedure-Signature-1.html)

### Exceções do Convert to Text Messages somem depois de sair e entrar de novo

**Sintoma:** o wizard *Convert to Text Messages* mostrou exceções, mas depois do logout elas não aparecem mais.
**Causa:** as exceções ficam guardadas só na sessão do Builder.
**Correção:** depois de entrar de novo, rode *Convert to Text Messages* outra vez para ver as exceções.

Fonte: [Step 2: Convert to Text Messages](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-a-text-message-based-translation.html)

### Text Messages: criar, parâmetros nomeados ou posicionais e uso em JavaScript

Text Messages (Shared Components > Globalization > Text Messages) são textos nomeados por idioma.

Atributos: **Static ID** (nome da mensagem, ex.: `NO_WEEKEND_DATES_ALLOWED`; único por idioma na app), **Language**, **Used in JavaScript** (liga para usar com `apex.lang.*` no navegador), **Text**, *Comment*. Parâmetros **nomeados** (`%name`, sem espaço nem `=`, únicos na mensagem) ou **posicionais** (`%0`, `%1`…); toda tradução precisa ter os mesmos parâmetros.

```
GREETING_MSG (en):  Good morning %name, you are %age
GREETING_MSG (de):  Guten Morgen %name, du bist %age
```

Fluxo para traduzir manualmente: crie a mensagem no idioma primário, copie (*Copy*) para outro idioma com o **mesmo Static ID** e edite o texto. A cópia de outra app aceita *Subscribe*.

Comportamento 26.1: se não existe a mensagem no idioma pedido, ela **cai no idioma primário**. A documentação de `APEX_LANG.MESSAGE` descreve a ordem de busca: idioma atual, depois o primário e, por fim, `en`.

Fonte: [Creating Text Messages](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-text-messages.html), [Workflow for Translating Messages into Multiple Languages](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/workflow-for-translating-messages-into-multiple-languages.html), [Copying or Subscribing to Text Messages](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/copying-or-subscribing-to-text-messages.html), [Changed Behavior: Text Message Translation Changes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html)

### Referenciar text messages: &{NOME}. com parâmetros, APP_TEXT$ legado e shortcuts

**Sintaxe curta** (apps com *Compatibility Mode* 24.2 ou superior):

```
&{EMPLOYEE_DIRECTORY}.
&{INCREASE_SALARY pct="5" date="&P3_SOME_ITEM."}.
&{INCREASE_SALARY pct="5" date="&P3_SOME_ITEM."}!RAW.
```

- O nome pode ter caracteres especiais, mas não espaço nem `}`.
- Parâmetros `nome=valor` separados por espaço antes do `}`. Valores: substituição sem aspas (`&P1_NAME.`, escapada em HTML por padrão), substituição com aspas (`&"X-1".`), literal sem aspas (sem espaço nem `}`) ou literal entre aspas (`"Olá ""APEX"""`, aspas dobradas para escapar).
- O parâmetro especial `$lang` força o idioma (`$lang=FR`).
- O filtro de escape vai entre `}` e o ponto final (`}!RAW.`).

**Sintaxe legada**: `&APP_TEXT$NOME.` e `&APP_TEXT$NOME$LANG.` (ex.: `&APP_TEXT$MY_MESSAGE$FR!HTML.`); também como `:APP_TEXT$NOME` e `V('APP_TEXT$NOME')`. A documentação recomenda a sintaxe com chaves.

**Shortcuts** do tipo *Message* e *Message with JavaScript Escaped Single Quotes* expandem para a mensagem no idioma atual (o nome do shortcut é o nome da mensagem).

No Page Designer, o **Text Messages Picker** (ícone de globo ao lado dos campos traduzíveis; ligue em *Utilities > Show > Text Message Picker*) busca e insere a mensagem com a sintaxe certa e mostra a prévia abaixo do campo. No Code Editor, digite `&{` (exige compatibility mode 24.2+) ou `&APP_TEXT$` para sugestões.

Fonte: [Substitutions in Text Messages (24.2 or later)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-using-substitution-strings.html), [APP_TEXT$Message_Name](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-available-built-in-substitution-strings.html), [Using the Text Messages Picker](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-text-messages-picker.html), [Selecting Translation Messages in Page Designer](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-the-text-messages-picker.html), [About Shortcuts that Support Translatable Messages](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-application-translation-and-globalization-support.html)

### APEX_LANG.GET_MESSAGE: mensagens traduzíveis em PL/SQL

Texto gerado em PL/SQL (regiões PL/SQL, processos, packages, triggers) não entra na tradução automática. Defina-o como Text Message e leia com `GET_MESSAGE`:

```sql
APEX_LANG.GET_MESSAGE (
    p_name           IN VARCHAR2,
    p_params         IN apex_t_varchar2 DEFAULT apex_t_varchar2(),
    p_lang           IN VARCHAR2        DEFAULT NULL,   -- padrão: idioma atual (Application Language Derived From)
    p_application_id IN NUMBER          DEFAULT NULL )  -- útil fora de sessão APEX (jobs)
RETURN VARCHAR2;
```

```plsql
l_msg := apex_lang.get_message( 'GREETING_MSG',
                                apex_t_varchar2( 'name', :P1_NAME, 'age', :P1_AGE ) );
```

`p_params` é uma lista de pares nome/valor substituídos da esquerda para a direita. `APEX_LANG.MESSAGE (p_name, p0..p9, p_lang, p_application_id)` está **deprecated**. Para erros traduzíveis, `apex_error.add_error( p_error_code => 'NOME_DA_MENSAGEM', ...)` usa a mensagem pelo nome.

Outras APIs: `CREATE_MESSAGE (p_application_id, p_name, p_language, p_message_text, p_used_in_javascript, p_comment, p_metadata)`, `UPDATE_MESSAGE`, `DELETE_MESSAGE`, `EMIT_LANGUAGE_SELECTOR_LIST` (imprime um seletor de idiomas numa região PL/SQL) e `GET_LANGUAGE_SELECTOR_LIST` (o mesmo seletor como HTML para Dynamic Content).

Fonte: [GET_MESSAGE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_LANG.GET_MESSAGE-Function.html), [MESSAGE Function (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/MESSAGE-Function.html), [CREATE_MESSAGE](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_LANG.CREATE_MESSAGE-Procedure.html), [About Translating Messages Used in PL/SQL Procedures](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-translating-messages-used-in-pl-sql-procedures.html), [Enabling Row Selection](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/enabling-row-selection.html)

### Mensagens internas do APEX (APEX.*) e idiomas do runtime

O runtime do APEX (paginação, Interactive Grid, Interactive Report, faceted search, PWA, validações de item) já vem traduzido para: árabe, **português do Brasil**, croata, tcheco, dinamarquês, holandês, finlandês, francês, francês canadense, alemão, grego, hebraico, húngaro, italiano, japonês, coreano, norueguês, polonês, português (Portugal), romeno, russo, sérvio (cirílico e latino), chinês simplificado e tradicional, eslovaco, esloveno, espanhol, sueco, tailandês, turco, ucraniano e vietnamita (as traduções da instância são instaladas conforme o Installation Guide). Para outros idiomas, crie Text Messages com os **mesmos nomes** das mensagens internas, no idioma desejado. Exemplos de nomes:

| Mensagem | Texto em inglês |
|---|---|
| `APEX.DIALOG.CANCEL` / `APEX.DIALOG.SAVE` | Cancel / Save |
| `APEX.CORRECT_ERRORS` | Correct errors before saving. |
| `APEX.ITEM_TYPE.YES_NO.YES_LABEL` / `NO_LABEL` | Yes / No |
| `APEX.NUMBER_FIELD.VALUE_INVALID` | #LABEL# must be Numeric. |
| `APEX.DATEPICKER.VALUE_INVALID` | #LABEL# must be a valid date, for example %0. |
| `APEX.FS.SEARCH_PLACEHOLDER` / `APEX.FS.COUNT_RESULTS` | Search... / %0 results |

As listas completas (internas, Interactive Grid, Interactive Report, PWA, Search and Smart Filters) estão nas páginas de referência.

Fonte: [Translating Messages Used Internally by APEX](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/translating-messages-used-internally-by-apex.html), [Internal Messages Requiring Translation](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/internal-messages-requiring-translation.html), [Search and Smart Filters Messages Requiring Translation](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/search-and-smart-filters-messages-requiring-translation.html)

### Traduzir relatórios padrão de IR e IG, títulos de região e templates

- **Default reports** de Interactive Report e Interactive Grid (Primary e Alternative, salvos pelo desenvolvedor) entram no XLIFF (Application-Based): nome e descrição, filtro, highlight, rótulos de eixo de gráfico; no IR também labels e máscaras de computation, pivot e group by; no IG o tooltip de agregação. Relatórios salvos por usuários (públicos ou privados) **não** são traduzíveis.
- **Título de região**: entra na tradução por padrão. Para excluir: *Advanced, Exclude Title from Translation* = On.
- **Templates**: não entram por padrão (não deveriam ter texto). Marque *Translatable* se precisar ou use static substitution strings da app, que são traduzidas.
- **Atributos de plug-in** marcados *Translatable* entram no XLIFF.
- **Dados do banco** (LOVs por SQL): use Dynamic Translations + `APEX_LANG.LANG` (seção 3).

Fonte: [Translating Default Reports for Interactive Reports and Interactive Grids](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/translating-default-reports-for-interactive-reports-and-interactive-grids.html), [Making Application Attributes Translatable](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-application-translation-and-globalization-support.html)

---

## 15. Application Components (help, JET) e componentes legados

### Managing Application Components: calendars, charts, maps e help

O capítulo *Managing Application Components* cobre Calendars (visões mensal, semanal, diária e lista, com drag and drop), Charts (Oracle JET; criados pelo wizard ou no Page Designer), Maps (dados de localização, com fundos nativos ou custom map backgrounds) e Help da aplicação. O detalhe de charts, mapas e calendários fica fora deste documento. O calendário legado (*Legacy Calendar*) e seus templates estão **deprecated** no 26.1: não existem mais no UT 26.1, o export APEXlang falha se houver região Legacy Calendar e templates não usados são removidos no upgrade.

Fonte: [Managing Application Components](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-application-components.html), [Deprecated Features: Legacy Calendar Templates](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/deprecated-features.html)

### Help da aplicação: página de help, page help e item help

1. Crie uma página em branco e adicione uma região **Help Text** (Gallery).
2. *Page Help*: na página, atributo *Help, Help Text*.
3. *Item Help*: em cada item, *Help*. Em massa: *Utilities > Item Utilities > Edit Item Help Text*; *Seed Item Help Text* cria um texto padrão para itens sem help.
4. Crie uma entrada de navigation bar para a página de help com *Request* = `&APP_PAGE_ID.`, para mostrar o help da página atual.

Fonte: [Creating Help for Your Application](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-help-for-your-application.html)

### Componentes legados: tabular forms, data loading, web services, mobile

A Oracle ainda suporta, mas **não recomenda**, os componentes legados. No Page Designer eles aparecem na Gallery via *Gallery Menu > Show Legacy Components*.

- **Legacy Tabular Forms**: edição de várias linhas com processos *Multi Row Update* (MRU) e *Multi Row Delete* (MRD) e checksum por linha (optimistic locking). **Criar tabular forms novos está desupported**; use Interactive Grid. Não altere o SELECT de um tabular form existente de forma que mude os valores das colunas atualizáveis; não adicione JS customizado em display types com JS próprio (radio, checkbox simples, popup key LOV). A PK precisa estar na query, oculta ou display only (save state); linhas novas têm PK nula.
- **Legacy Data Loading**: wizard antigo de carga por Data Load Table. Use as *Data Load Definitions* atuais.
- **Legacy Web Services**: referências SOAP/REST antigas (WSDL, manual, repositório), forms e reports sobre web service e processo *Web Service*. Prefira REST Data Sources.
- **Legacy Forms Optimized for Mobile**: Column Toggle, List View e Reflow reports da era jQuery Mobile.

Fonte: [Managing Application Legacy Components](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-app-legacy-components.html), [Viewing Legacy Components in the Gallery](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/viewing-legacy-components-gallery.html), [Managing Legacy Tabular Forms](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-tabular-forms.html), [Managing Legacy Web Services](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/implementing-web-services.html), [Managing Applications with Legacy Data Loading Capability](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-legacy-data-loading-capability.html)

---

## 16. Aplicação no Corlix Hub

> Projeto: app 100 `CORLIXHUB`, APEX 26.1.5, fonte APEXlang em `corlixhub/`. O estado do projeto está em `docs/ai-context/03-componentes-compartilhados.md` (shared components) e `docs/ai-context/04-tema-e-estilos.md` (tema). Aqui está como os recursos acima se aplicam, com as divergências apontadas. Caminhos do Builder não conferidos no 26.1.5 estão marcados "(confirmar no 26.1.5)".

### Corlix Hub: onde ficam os shared components no APEXlang

| Shared component | Arquivo `.apx` | Estado (ver `ai-context/03`) |
|---|---|---|
| Application Items | `shared-components/app-items.apx` | `APP_USER_CARGO`, `APP_USER_FOTO`, `APP_USER_INICIAIS`, `APP_USER_NOME` (órfão), `G_ID_EMPRESA`, `G_NOME_EMPRESA`, `G_NOME_USUARIO`. Todos declarados vazios, ou seja, com o padrão APEXlang `scope: app` + `sessionStateProtection: restricted` (o que o `03` registra como proteção `I`) |
| Application Processes | `shared-components/app-processes.apx` | 4 processos `executeCode` em *Before Header*, sem condição |
| Build Options | `shared-components/build-options.apx` | só `commented-out` (padrão; não apagar, senão o Page Designer perde o "comentar componente") |
| Component Settings | `shared-components/component-settings.apx` | Checkbox `uncheckedValue: N`, Switch `onValue: Y`, Date Picker com month/year picker e Today |
| LOVs | `shared-components/lovs.apx` | ver tópico de LOVs |
| Lists | `shared-components/lists.apx` | `navigation-menu` e `emitir-comunicado` (não usada) |
| Static files | `shared-components/static-files.apx` + `static-files/` | tema, custom, CSS dos módulos, ícones, fotos |
| Tema | `shared-components/themes/universal-theme/` | UT 42 `ut-26.1`, style Redwood Light, templates locais `corlix-standard-page`, `cards-container-image-first`, `chat-contatos`, `chat-mensagens`, `html-button-legacy-apex-5-migration` |
| Globalização / CSS da app | `application.apx` | `appFormatMasks` = `DS`; `css.fileUrls` = `corlix-tema#MIN#` → `custom#MIN#` |

Não existem no app: Application Settings, Application Computations, Shortcuts, Component Groups, Email Templates, Text Messages, plug-ins nem Template Components customizados.

Fonte: [Shared Components Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/shared-components-page.html), [APEXlang API Reference: appItem](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Corlix Hub: application processes e itens de contexto (G_ID_EMPRESA)

- Os 4 app processes rodam em **todas** as páginas, inclusive no login (`:APP_USER = 'nobody'`). A documentação indica *On New Instance* para valores que não dependem do usuário e **After Authentication** para valores do usuário logado (perfil, empresa, foto), uma vez por sessão. Isso confirma a sugestão do `ai-context/03` §3.2. Ao mudar, lembre que um dado que muda durante a sessão (ex.: foto atualizada) só será recarregado no próximo login.
- O `ai-context/08` diz que `G_ID_EMPRESA` só é preenchido depois de um novo login, o que é coerente com um processo em ponto de autenticação. Mantenha `G_ID_EMPRESA` com SSP **Restricted**: é o "current company" de uma app multi-tenant, o caso de uso citado na doc para variáveis globais. Nunca deixe esse item ser setado pela URL.
- Se algum dia o Corlix Hub for dividido em várias apps na mesma sessão, `G_ID_EMPRESA` é candidato a item **Global** (mesmo nome, Scope Global, Restricted em todas).
- Itens que precisem ser enviados por Ajax (cascading LOV, Set Value) precisam de SSP *Unrestricted*. Isso vale para **page items** da cascata, **nunca** para `G_ID_EMPRESA`.

Fonte: [About Application Processes that Execute On New Instance](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-application-processes.html), [About Creating an Application Item that Functions as a Global Variable](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-application-items.html)

### Corlix Hub: LOVs e o filtro multiempresa por :G_ID_EMPRESA

- Regra do projeto: toda query de negócio filtra por `id_empresa`. As LOVs mais novas já seguem o padrão recomendado pela doc (bind variable de session state na LOV):

````
lov lov-colaborador-ativo (
    name: LOV_COLABORADOR_ATIVO
    source {
        type: sqlQuery
        sqlQuery:
            ```sql
            select nome_completo d, id_colaborador r
              from colaborador
             where id_empresa = :G_ID_EMPRESA
               and status = true
             order by nome_completo
            ```
    }
    columnMapping {
        return: R
        display: D
    }
)
````

- As LOVs de tabela `colaborador-nome-completo`, `departamento-nome` e `empresa-nome` (usadas em p26/p27) **não filtram** por empresa (`ai-context/03` §6). Para uma LOV de tabela, a forma mínima é `source.whereClause` (`id_empresa = :G_ID_EMPRESA`) ou trocar por `sqlQuery` como acima. Prefira o application item `:G_ID_EMPRESA` a um page item, para a LOV continuar reutilizável em qualquer página.
- A LOV `boolean` mostra "Yes"/"No" em inglês. Como a UI é pt-BR, troque os `display` para "Sim"/"Não" (o `return` `TRUE`/`FALSE` continua igual).
- Para ícone por entrada (Select One/Many, Combobox) ou colunas extras em Popup LOV, use `columnMapping.icon` e filhos `column` na LOV compartilhada; LOV local não oferece isso.

Fonte: [About Referencing Session State Within a List of Values](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-referencing-session-state-within-list-of-values.html), [APEXlang API Reference: lov](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html), [Additional Shared LOV Features](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/additional-shared-lov-features.html)

### Corlix Hub: Navigation Menu, authorization e dynamic lists com checksum

- O menu lateral é a lista `navigation-menu`, renderizada no `#SIDE_GLOBAL_NAVIGATION_LIST#` do page template, com template `@/side-navigation-menu` e template options `js-defaultCollapsed`, `js-navCollapsed--default` e `t-TreeNav--styleA` (menu começa recolhido).
- A doc confirma que *Authorization Scheme* numa entrada de lista **só controla a renderização da entrada**. Proteger a página exige `authorizationScheme` na própria página (regra 3 do projeto; `ai-context/08` §3 lista as páginas expostas).
- Se o menu virar **dynamic list** (ex.: entradas por perfil), monte a coluna 3 com `apex_page.get_url(...)`, como no exemplo da doc. Isso também atende à regra de links com checksum (`argumentsMustHaveChecksum`).
- **Apagar a lista `emitir-comunicado` apaga as regiões que a usam.** Hoje nenhuma página a usa, então apagar é seguro.
- O `custom.css` transforma o último item do menu em botão de rodapé (`ai-context/04` §10). Ao incluir entradas, respeite o `sequence` (Sair = 10000).

Fonte: [Managing Navigation Menus](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-navigation-menus.html), [Understanding Dynamic List Syntax](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-dynamic-lists.html), [Editing List Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-list-attributes.html)

### Corlix Hub: static files, #APP_FILES#, #MIN# e o par .css/.min.css

- CSS global em `application.apx > css.fileUrls`: `#APP_FILES#corlix-tema#MIN#.css` e depois `#APP_FILES#custom#MIN#.css`. Equivale a *User Interface Attributes > CSS > File URLs*, emitidos em `#APPLICATION_CSS#` do page template. CSS dos módulos é carregado **por página** (`page > css > fileUrls`: `#APP_FILES#organograma#MIN#.css` na p3, `#APP_FILES#historico-carreira#MIN#.css` nas p13, p19, p20), o nível que a doc indica para CSS que só algumas páginas usam.
- **Minificação, possível divergência:** o `ai-context/04` §2.4/§9.6 diz que não há minificação automática e que os pares `.css`/`.min.css` são mantidos à mão. A doc 26.1 diz que o App Builder gera `.min.js` automaticamente para **JavaScript** em Static Application Files (e `.min` de CSS e JS em arquivos de Template Components), mas não afirma o mesmo para **CSS** em Static Application Files (confirmar no 26.1.5). Como o repositório registra os `.min.css` como arquivos separados em `static-files.apx` e eles vão no export APEXlang, **mantenha a regra do projeto**: editou `X.css`, regenere e suba `X.min.css`.
- Para forçar o navegador a baixar o CSS novo depois de um deploy, a doc sugere versionar o URL: `#APP_FILES#custom#MIN#.css?version=#APP_VERSION#` e incrementar a *Version* da app (hoje `Release 1.0`, segundo o `ai-context/03`). É opcional; o guia do tema hoje usa Ctrl/Cmd+Shift+R.
- Fotos: `#APP_FILES#Fotos Colaboradores/<arquivo>` funciona porque a substituição é feita no HTML renderizado. Em PL/SQL puro, `#APP_FILES#` é literal (use `v('APP_FILES')`), o que bate com a pegadinha do `ai-context/03` §3.
- Arquivo comum a várias apps do workspace iria para **Static Workspace Files** (`#WORKSPACE_FILES#`). O Corlix Hub é uma app só, então use sempre Application Files (que vão no export).

Fonte: [Editing User Interface Attributes: CSS](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-user-interface-attributes.html), [Including Helper Functions in All Pages](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/including-helper-functions-all-pages.html), [Defining Files and File URLs to Load](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/defining-files-and-file-urls-load.html), [Managing Static Workspace Files](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-static-workspace-files.html)

### Corlix Hub: tema assinado, templates locais e refresh do Universal Theme

- O tema `universal-theme` (42, `ut-26.1`) é assinado do UT. Pela doc, templates assinados ficam somente leitura e o **Refresh Theme atualiza só o que é assinado**. Os templates customizados (`corlix-standard-page`, `cards-container-image-first`, `chat-*`) são **cópias locais**: editáveis e **fora do refresh**. Depois de cada refresh do UT, compare o `corlix-standard-page` com o *Standard* novo (classes, placeholders, JS `apex.theme42.initializePage`) e incorpore as mudanças à mão.
- O `corlix-standard-page` declara o slot `topNavigation` (`REGION_POSITION_06`) sem `#REGION_POSITION_06#` no HTML (`ai-context/03` §8.2). Pela doc, a posição só renderiza se o placeholder estiver no Body; regiões nesse slot não aparecem.
- Faça backup (export) antes de *Refresh Theme* ou *Switch Theme*, como a doc recomenda.
- Novidade do 26.1: **Iris** é o style padrão de apps novas. O Corlix Hub usa **Redwood Light** de propósito (`theme.apx`: `currentThemeStyle: @/redwood-light`); não troque.

Fonte: [About Theme Subscriptions / About Modifying a Theme Subscription](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-theme-subscriptions.html), [Page Templates: Positions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/page-templates.html), [Refreshing the Universal Theme](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-the-universal-theme.html)

### Corlix Hub: tokens --cx-*, variáveis do UT e por que não usar o Theme Roller

- O "Tema Corlix" é uma camada CSS que redefine variáveis do UT (`--ut-*`, `--a-*`) em `:root` a partir de tokens `--cx-*` (`corlix-tema.css`). É o padrão da doc: regras em `:root` num static file da app, ligado em *User Interface Attributes > CSS > File URLs*. Novas variáveis do UT: consulte *Reference > CSS Variables* no UT Reference app antes de criar seletores.
- O `ai-context/04` §9 proíbe salvar style no Theme Roller. A doc explica o risco: o Theme Roller grava um *Output CSS* e um JSON no style, carregados em `#THEME_STYLE_CSS#`, ou seja, uma segunda fonte de cores competindo com o `corlix-tema.css` (que vem depois, em `#APPLICATION_CSS#`). Use o Theme Roller só para **experimentar** (*Reset* no fim) ou para descobrir o nome de uma variável. E lembre: exports do Theme Roller entre Vita/Iris e Redwood Light não são compatíveis.
- Template Options primeiro, CSS depois: escolha `Hot`, *Remove UI Decoration*, *Danger* etc. pelas template options (que injetam classes via `#BUTTON_CSS_CLASSES#`/`#REGION_CSS_CLASSES#`) antes de escrever CSS. Para testar combinações sem salvar, use **Quick Edit > chave inglesa** (Live Template Options).
- CSP: o projeto usa `onerror="..."` e `style="display:none"` no padrão de avatar de iniciais (`ai-context/04` §5.2). Isso só importa se um dia o app ativar `Content-Security-Policy`. Nesse caso, troque por classe + JS externo ou pelo `#APEX_CSP_DISPLAY_NONE#` em templates, e teste antes com `Content-Security-Policy-Report-Only`.

Fonte: [Configuring Application-Wide Style Rules](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configuring-application-wide-style-rules.html), [Using Theme Styles](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/theme-styles.html), [Using Theme Roller](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-theme-roller.html), [Using Quick Edit to Modify Live Template Options](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-template-options.html), [Using Content Security Policy (CSP) in APEX](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-csp-in-apex.html)

### Corlix Hub: módulos com Dynamic Content × Template Components e plug-ins

- O padrão de módulo do projeto (`ai-context/06`, `08` regra 4) é `pkg_<nome>_ui` devolvendo HTML para uma região *Dynamic Content* + CSS/JS próprios. Continua válido e é o padrão a seguir.
- Para peças **visuais repetidas sem lógica de servidor** (card de pessoa `cx-pessoa`, badge `cx-badge`, avatar de iniciais), a doc oferece **Template Components**: HTML + `#PLACEHOLDERS#` + directives, usados no Page Designer ou por `{with/}…{apply/}` em HTML Expressions de Cards, Classic Report e IR. O avatar do UT (`THEME$AVATAR`, com `TYPE:=INITIALS`) já resolve foto ou iniciais sem o truque de `onerror`. Adotar isso seria uma decisão de design: **pergunte ao time** antes.
- Se um módulo virar plug-in (região com PL/SQL), siga a doc: Static ID com prefixo de domínio (ex.: `BR.COM.CORLIX.ORGANOGRAMA`), código num **package** (não no bloco do plug-in), interface **Procedure** com `p_region.attributes.get_varchar2('static_id')`, CSS/JS em *File URLs to Load* com `#PLUGIN_FILES#` e `#MIN#`, e queries do plug-in filtrando por `:G_ID_EMPRESA`.
- Não há plug-ins de terceiros. Se importar algum (apex.world), registre em `static-files`/`modulos` conforme o padrão e confira a compatibilidade com o UT 26.1 e com CSP.

Fonte: [Template Component Overview](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/template-component-overview.html), [With and Apply Directives](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-template-directives.html), [Creating a Plug-in from Scratch](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-plug-ins.html), [New Features: Client-side Template Component Partials](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### Corlix Hub: idioma primário en, máscaras DS e pt-BR

- Estado: idioma primário `en`, *Application Language Derived From* = *Application Primary Language* (`p_flow_language_derived_from=>'FLOW_PRIMARY_LANGUAGE'` no `f100.sql`), máscaras `DS`, *Automatic CSV Encoding* ligado, UI escrita em pt-BR, sem tradução (`ai-context/03` §1, `08` §3 Configuração). Pela doc, o idioma da app define `NLS_LANGUAGE`/`NLS_TERRITORY` da sessão: `en` = AMERICAN/AMERICA (datas e números no padrão americano), `pt-br` = BRAZILIAN PORTUGUESE/BRAZIL. Isso explica por que o projeto formata datas com `to_char(..., 'dd/mm/yyyy')`.
- As mensagens internas do APEX (paginação, IG, IR, validações como "#LABEL# must be Numeric.") seguem o idioma da sessão. O runtime tem tradução para **português do Brasil**, mas com idioma primário `en` elas aparecem em inglês. Mudar o *Application Primary Language* para `pt-br` (ou definir *Application Date Format* = `DD/MM/YYYY`) mudaria o padrão de toda a app e pode alterar como datas são lidas e gravadas. É mudança de configuração global: **pergunte ao time antes** e teste formulários com data.
- Se a app precisar de outro idioma no futuro: a doc recomenda **Text Message-Based** (uma app só, `&{NOME}.`). Para o RH, mensagens de PL/SQL (`pkg_historico_carreira`) poderiam virar Text Messages lidas por `apex_lang.get_message`, o que também centraliza os textos em pt-BR mesmo sem tradução (*Centralizing Reusable UI Text*).
- *Automatic Time Zone* não aparece ligado no export (não há `p_auto_time_zone` no `f100.sql`). Se for ligado, lembre da mudança do 26.1 (`SESSIONTIMEZONE` com nome de fuso, ex.: `America/Sao_Paulo`).

Fonte: [Understanding Supported Globalization Codes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-supported-globalization-codes.html), [Configuring Globalization Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-globalization-attributes.html), [Translating Messages Used Internally by APEX](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/translating-messages-used-internally-by-apex.html), [Centralizing Reusable UI Text](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/centralizing-reusable-ui-text.html)

### Corlix Hub: Static IDs com acento e a regra de Static ID permanente do 26.1

- O `ai-context/08` aponta Static IDs com acento (`publicador-de-conteúdo`, `histórico-de-carreira`, `comunicação`, `notificações`). No 26.1, o Static ID é o identificador primário para casar componentes entre apps e o que aparece no APEXlang (`@publicador-de-conteúdo`). A doc pede para tratá-lo como **permanente**: renomear exige corrigir toda referência (`.apx`, chamadas de API) e quebra a comparação de versões.
- Se o time decidir normalizar (sem acento), faça num único commit: troque o Static ID no Builder (cadeado de edição) **e** todas as referências `@...` no `.apx`, e depois reimporte e teste. Não misture com outras mudanças.

Fonte: [New Features: Static ID Added](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html), [Changed Behavior: Static ID Changes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html)

### Corlix Hub: checklist ao mexer em shared components, tema ou plug-ins

1. Editou o `.apx` em `corlixhub/shared-components/` (nunca `database/f100.sql`)?
2. LOV, lista ou processo novo filtra por `:G_ID_EMPRESA`?
3. App item novo está *Restricted* (padrão APEXlang), salvo se precisar de Ajax?
4. Processo de app novo tem condição ou está em *After Authentication* / *On New Instance*, em vez de rodar em toda página?
5. Arquivo estático novo está em `static-files/` **e** em `static-files.apx`, com o par `.min` e referência `#APP_FILES#nome#MIN#.ext`?
6. Cores novas viraram token `--cx-*` ou variável do UT em `corlix-tema.css`, e não Theme Roller nem hex solto?
7. Mudou template local (`corlix-standard-page`)? Conferiu placeholders (`#REGION_CSS_CLASSES#`, `#BUTTON_CSS_CLASSES#`, posições) e documentou em `ai-context/03` §8 e `04`?
8. Dynamic list ou link gerado em SQL usa `apex_page.get_url`?
9. Textos em pt-BR (inclusive `display` de LOVs estáticas)?
10. Atualizou `docs/ai-context/03` ou `04` conforme a mudança (regra 7 do projeto)?

Fonte: [Managing Shared Components](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-shared-components.html), [Using Themes and Theme Styles](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-themes-and-theme-styles.html)
