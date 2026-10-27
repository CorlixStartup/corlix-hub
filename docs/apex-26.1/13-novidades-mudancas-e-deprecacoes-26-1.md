# 13 · APEX 26.1: novidades, mudanças de comportamento, deprecações e bugs conhecidos

> Base: documentação oficial Oracle APEX 26.1 (Release Notes `htmrn` inteiro: About, New Features, Changed Behavior, Ideas App, Deprecated Features, Deprecated in Previous Releases, Desupported Features, Desupported in Previous Releases, Fixed Bugs, Open Bugs and Known Issues, Privacy Notice; páginas "Changes in Release 26.1" de `htmdb`, `aeapi`, `aeadm`, `aeutl`, `htmig`, `aeeug`, `aeacc`; páginas "(Deprecated)" do `aeapi` e do `aexjs`; `htmdb` "Upgrading Oracle APEX Applications", "Using Content Security Policy (CSP) in APEX", "Locking and Unlocking an Application", "Running Advisor"; `htmig` "Oracle APEX Installation Requirements" e "Upgrading from a Previous APEX Release"). Gerado em 21/10/2026.

**Sumário**
1. Requisitos do 26.1 (banco, ORDS, navegador, disco, Universal Theme) e upgrade
2. O que cada livro mudou ("Changes in Release 26.1")
3. Novidades (New Features), por área: APEXlang, IA, Data Reporter, Workflow/Task, REST, Map, Segurança/CSP, Interactive Report, tipos de aplicação, BOOLEAN, DAs, plug-ins, UI e tema, APIs PL/SQL e JS, bibliotecas
4. Mudanças de comportamento (Changed Behavior) com impacto prático
5. Deprecated no 26.1, com alternativa
6. Deprecated em releases anteriores (ainda presentes)
7. Desupported (26.1 e anteriores)
8. Open Bugs e Known Issues (formato de caso)
9. Fixed Bugs relevantes, por área
10. Ideas App: pedidos da comunidade entregues
11. Privacidade: cookies e storage do APEX
12. Checklist para agentes
13. Aplicação no Corlix Hub

---

## 1. Requisitos do APEX 26.1 e upgrade

### Requisitos de banco de dados do APEX 26.1 (Oracle Database 19c 19.18+ ou 26ai 23.26.0+)
- **Oracle Database 19c**: exige o Release Update **19.18** (janeiro de 2023) ou posterior.
- **Oracle AI Database 26ai**: exige no mínimo a versão **23.26.0** (outubro de 2025). Observe a numeração: o "26ai" é identificado pela versão de banco `23.26.x`.
- Funciona em todas as edições (EE, SE2 e 26ai Free), em instância única ou RAC.
- Memória mínima para instalar: **SGA ≥ 1200 MB** e **PGA ≥ 300 MB** (`SGA_TARGET`, `PGA_AGGREGATE_TARGET`; se `SGA_TARGET = 0`, a base usa gerência automática e o ajuste é via `MEMORY_TARGET`).
- Durante instalação ou upgrade, `WORKAREA_SIZE_POLICY` precisa estar `AUTO` na sessão (em CDB, no nível do sistema: `ALTER SYSTEM SET WORKAREA_SIZE_POLICY=AUTO SCOPE=BOTH`).
- **Oracle XML DB** precisa estar instalado para o ambiente de desenvolvimento completo; o instalador aborta se não estiver. Não remova o usuário `ANONYMOUS` (criado pelo XML DB): o provisionamento de workspaces depende dele.
- Banco com **Database Vault**: há passos extras de configuração (workspace provisioning e SQL Workshop).

Vários recursos novos do 26.1 dependem do 26ai: sessão com tipo **BOOLEAN** (§3.10), validação automática de JSON Schema na saída de IA via `DBMS_JSON_SCHEMA` (§3.2.6) e `APEX_DB_DICTIONARY`/Describe Tables (também em patches recentes do 19c).

Fonte: [About These Release Notes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/about-release-notes.html), [Oracle APEX Installation Requirements](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/apex-installation-requirements.html), [Changed Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html)

### Requisitos de servidor web: ORDS 26.1.1 ou posterior (e instalar ORDS antes do APEX)
- O APEX 26.1 exige **Oracle REST Data Services 26.1.1 ou posterior**. Isso aparece em About These Release Notes, em Changed Behavior (§3.1) e em Installation Requirements.
- **Nova recomendação do 26.1**: em instalações novas, instale o **ORDS antes do APEX**.
- Serviços REST baseados no próprio APEX foram desupported no 22.1; o ORDS 21.4.2+ traz scripts de migração para serviços ORDS.
- **Divergência interna da doc**: a página "Viewing the Oracle REST Data Services Release Number" do Installation Guide (§4.4) ainda fala em "ORDS 23.3 or later". Trate o requisito de **26.1.1** (citado três vezes) como o válido. Para conferir a versão em uso: *Help > About*, seção *CGI Environment*, variável `APEX_LISTENER_VERSION`.

Fonte: [About These Release Notes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/about-release-notes.html), [Upgrading from a Previous APEX Release](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/upgrading-from-previous-apex-release.html)

### Requisitos de navegador e disco do APEX 26.1
- Navegador com JavaScript, na versão atual ou na anterior de Chrome, Firefox, Safari ou Edge.
- Disco: 670 MB para os arquivos do pacote só em inglês (`apex_26.1_en.zip`) ou 1.178 MB para o completo (`apex_26.1.zip`). No banco: 260 MB livres no tablespace do APEX, 128 MB no `SYSTEM` e mais 60 MB por idioma adicional.

Fonte: [Oracle APEX Installation Requirements](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/apex-installation-requirements.html)

### Caminho de upgrade para o 26.1 (a partir de 18.1+; antes disso, passar pelo 24.2)
- Upgrade direto só a partir do **18.1**. Se a instância for mais antiga, suba primeiro para o **24.2** e depois para o 26.1, ou exporte workspaces e apps e importe numa instalação nova.
- O APEX não tem mais patch sets (como 5.1.1), só releases completos. Correções críticas saem como PSE (patch set exception), listadas na página de Known Issues do 26.1.
- O upgrade cria os objetos do 26.1 em um **schema novo** (`APEX_260100`) e migra os metadados das apps.
- Novo no 26.1: o relatório **Install / Upgrade Logs** em *Administration Services* mostra as fases, avisos e erros do upgrade, com drill-down por etapa.
- No upgrade, a configuração de Network Services (ACL) da versão anterior é reaplicada automaticamente ao novo schema.

Fonte: [About These Release Notes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/about-release-notes.html), [Upgrading from a Previous APEX Release](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/upgrading-from-previous-apex-release.html), [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### Versões de Universal Theme suportadas no 26.1 (26.1 e 24.2) e refresh do tema
- Cada release do APEX suporta a versão atual e a anterior do Universal Theme. No 26.1, isso significa **UT 26.1 e 24.2**.
- Recomenda-se dar *Refresh Theme* depois de cada upgrade. Não é obrigatório e a app continua funcionando, mas UT antigo não recebe correções nem suporta recursos novos (ex.: Declarative Menu Buttons e NL2IR exigem UT 26.1).
- O refresh: App Builder > a app > banner "There is a new version of Universal Theme available!" > **Refresh Theme**. Faça backup (export ou cópia) antes.
- Desde o 21.1 o UT usa variáveis CSS, o que facilita o refresh de quem customiza o tema por variáveis em vez de sobrescrever classes.

Fonte: [About These Release Notes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/about-release-notes.html), [Upgrading Oracle APEX Applications](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/upgrading-apex-applications.html)

### Roteiro pós-upgrade de uma aplicação (Release Notes, Refresh Theme, Compatibility Mode, Upgrade Application, JS legado)
O App Builder Guide recomenda, após subir a instância ou importar uma app de release anterior, nesta ordem e testando a cada passo:
1. **Ler as Release Notes**: Changed Behavior, Deprecated, Deprecated in Previous Releases, Desupported. Rodar o **APEX Advisor** (*Utilities > Advisor*), que também detecta atributos deprecated.
2. **Refresh do Universal Theme** (ver acima).
3. **Compatibility Mode**: em *Edit Application Definition > Definition > Properties > Compatibility Mode*, defina a versão atual depois de revisar as mudanças. O upgrade ajusta esse atributo sozinho quando é preciso preservar comportamento antigo.
4. **Upgrade Application**: assistente de atualização em lote. No 26.1 também é acessível pela região **New Features Available** do Application Home (botão *View Details*; *Dismiss* esconde o aviso). Exemplo de tipo de upgrade citado: "Update Button Dynamic Actions to Trigger Actions". Depois do primeiro upgrade aplicado, o aviso some, mas o caminho *Utilities > Upgrade Application* continua disponível.
5. **JavaScript legado**: em *User Interface > JavaScript*, desmarque **Include Deprecated or Desupported Javascript Functions** e **Include jQuery Migrate** se o código não depender deles. Isso reduz o JS carregado. As funções deprecated ficam em `/i/libraries/apex/legacy*`.

Fonte: [Upgrading Oracle APEX Applications](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/upgrading-apex-applications.html), [Running Advisor to Check Application Integrity](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/running-advisor-to-check-application-integrity.html), [Changed Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html)

---

## 2. "Changes in Release 26.1" em cada livro

### O que as páginas "Changes in Release 26.1" de cada livro informam
Nenhum dos livros tem uma lista própria de mudanças. Todos remetem às Release Notes para New Features, Changed Behavior, Deprecated e Desupported. O resumo:

| Livro | O que diz de próprio |
|---|---|
| App Builder User's Guide (`htmdb`) | Atualizado para a funcionalidade e a UI do 26.1 |
| API Reference (`aeapi`) | Atualizado. Para comparar especificações PL/SQL entre versões (19.2 a 26.1), use o **APEX Diff** em `apex.oracle.com/apexdiff`. Remete a "PL/SQL API Updates" nas Release Notes |
| Administration Guide (`aeadm`) | Atualizado para a funcionalidade e a UI do 26.1 |
| SQL Workshop Guide (`aeutl`) | **Única novidade explícita:** criar tabelas com colunas **BOOLEAN**, adicionar uma coluna BOOLEAN a uma tabela existente e editar valores BOOLEAN (Object Browser) |
| Installation Guide (`htmig`) | Atualizado para a funcionalidade do 26.1 |
| End User's Guide (`aeeug`) | Atualizado para a funcionalidade e a UI do 26.1 |
| Accessibility Guide (`aeacc`) | Atualizado. Remete a New Features e Changed Behavior |

Fonte: [htmdb: Changes in Release 26.1](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/changes-in-this-release.html), [aeapi: Changes in Release 26.1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/changes-in-this-release.html), [aeadm: Changes in Release 26.1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/changes-in-this-release.html), [aeutl: Changes in Release 26.1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/changes-release.html), [htmig: Changes in Release 26.1](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/changes-in-this-release.html), [aeeug: Changes in Release 26.1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeeug/changes-in-release.html), [aeacc: Changes in Release 26.1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeacc/changes-in-this-release.html)

---

## 3. Novidades do APEX 26.1 (New Features)

### APEXlang: o que é e onde aparece no 26.1
- **APEXlang** é uma linguagem aberta de especificação de aplicações. Representa uma app APEX como arquivos de texto legíveis (`.apx`), próprios para revisão, versionamento, diff, varredura e validação, e pensados para serem gerados ou editados por pessoas e por LLMs. No controle de versão, os `.apx` podem ser a fonte da verdade da app. O uso é **opcional**.
- **Ferramentas**: o Oracle SQL Developer for VS Code (extensão "Oracle APEX" no Marketplace) tem suporte nativo para pesquisar, editar e gerar APEXlang. O SQLcl tem suporte completo de linha de comando (importar, exportar, ver, modificar e gerar), inclusive em modo não interativo, para automação.
- **No Builder**: o Page Designer ganhou a opção **APEXlang View**, uma prévia somente leitura da página atual em APEXlang. A comparação de Working Copies (com o main ou entre duas cópias) passou a mostrar o diff em APEXlang.

Fonte: [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### Export e import em APEXlang (tipos de export, nome do arquivo, restrições)
- **Quatro tipos de export** (aplicação ou página):
  - *Standard Export*: o recomendado para controle de versão; inclui metadados de desenvolvimento.
  - *Runtime Export*: para ambientes de runtime; omite metadados de desenvolvimento e define o build status como *Run Application Only*.
  - *Full Export*: inclui metadados de desenvolvimento, atividade de workflows e tasks e relatórios salvos públicos e privados.
  - *Custom*: controle fino de cada opção. Para ver as opções avançadas de um dos três tipos, selecione o tipo e depois *Custom*.
- **Formato**: SQL (arquivo `f100.zip`) ou APEXlang (arquivo `<app-alias>.zip`).
- **Restrição do export APEXlang no 26.1**: não exporta dados de runtime (relatórios públicos e privados, subscriptions, instâncias de workflow e de task).
- **Import APEXlang**: pelo menos um schema do workspace precisa estar **REST-enabled**. Se houver erros, uma página nova lista erros e avisos. O import APEXlang é **sempre da aplicação inteira**: não dá para importar uma página isolada nesse formato. Para importar uma página, use o formato SQL.
- O export APEXlang inclui os static files binários (ver a mudança em `APEX_EXPORT`, §4).

Fonte: [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### APEXlang Name para plug-ins e seus subcomponentes
- Nos exports (inclusive APEXlang), plug-ins aparecem como tipos de componente. No APEXlang, um plug-in é referenciado pelo **APEXlang Name**, uma versão camelCase do nome.
- Atributo novo **APEXlang Name** em plug-ins, Attribute Groups, Custom Attributes, Attribute List of Values, Plug-in Slots, Plug-in Action Templates e Plug-in Action Positions.
- No upgrade, o APEX gera esses nomes automaticamente a partir do nome do componente. São únicos e só alfanuméricos.

Fonte: [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### Static ID em todos os componentes (identificador estável para export e diff)
- Para diminuir falsos positivos em diffs entre instâncias, o export passou a usar um **Static ID único** por componente. Vale para todos os shared components, componentes de página e templates.
- Componentes sem Static ID recebem um, legível e gerado a partir do nome, no upgrade do APEX ou no import de uma app de release anterior.
- No Builder, o Static ID é **somente leitura** por padrão; o ícone de cadeado (*Unlock/Lock*) libera a edição.
- **Cuidado**: trate o Static ID como permanente. Trocá-lo depois que o componente está em uso quebra as referências no código e faz as ferramentas de comparação perderem a correlação entre a versão antiga e a nova (diff enganoso).
- Isso muda a cópia de componentes entre apps e as subscriptions (ver §4, "Static ID" e "Matching Shared Components").

Fonte: [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### Natural Language Support for Interactive Report (NL2IR)
- O usuário final escreve em linguagem natural e o Interactive Report aplica filtros, quebras (*break*) e gráficos sem customização do desenvolvedor.
- Com o recurso ligado, o *Default Search Mode* passa a ser **Search with AI**.
- Pré-requisito: um **Generative AI Service** configurado e selecionado nos *AI Attributes* da aplicação. O UT 26.1 já suporta o recurso.

Fonte: [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### Create Page Using Natural Language (criar página por descrição)
- No Create Page, descreva em linguagem natural o que quer (ex.: "Create a report on EBA_PROJECTS"). A IA sugere nome, tipo de página e tabela ou dados de exemplo. Dá para refinar o prompt ou aceitar e seguir o assistente normalmente.

Fonte: [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### AI Agents e AI Tools (antigas AI Configurations; RAG Sources viram Augment System Prompt)
- **AI Configurations** passaram a se chamar **AI Agents** e ganharam **AI Tools**: capacidades que o serviço de IA pode chamar para obter dados ou executar tarefas. Cada tool tem nome e, opcionalmente, descrição e parâmetros. A implementação pode ser em SQL, PL/SQL ou JavaScript.
- **Execution Point** de uma tool:
  - **On Demand**: o APEX só executa quando o serviço de IA pede. O ciclo pedido → execução → resposta (*agent loop*) se repete até a IA dar a resposta final.
  - **Augment System Prompt**: roda **antes** do primeiro envio, pode ter condição, e o resultado entra como system prompt adicional antes da entrada do usuário. É o que antes se chamava **RAG Source**: as RAG Sources existentes viram tools Augment System Prompt automaticamente no upgrade.
  - Recomendação da Oracle: considere migrar RAG Sources para tools On Demand. Costuma dar resultado melhor, implementação mais simples e menos tokens.
- **Tipos nativos de tool**: *Retrieve Data* (SQL Query, Function Body que retorna CLOB ou texto estático), *Execute Server-side Code* (PL/SQL ou JavaScript MLE; para sobrescrever o resultado padrão "success", use `APEX_AI.SET_TOOL_RESULT`) e *Execute Client-side Code* (pede algo ao usuário ou chama APIs do navegador em contexto assíncrono, como um diálogo de confirmação).
- **Parâmetros de tool**: tipos `VARCHAR2`, `CLOB`, `NUMBER` e `BOOLEAN`, com descrição e obrigatoriedade. Em SQL/PL/SQL entram como bind (`:PERSON_ID`); em JavaScript, por `this.data.PERSON_ID`.
- **Uso declarativo**: as DAs *Show AI Assistant* e *Generate Text With AI* e o processo *Generate Text with AI* podem referenciar um AI Agent. Em PL/SQL, passe o Static ID do agente para as chamadas de `APEX_AI`. Tools client-side só funcionam quando a requisição sai do navegador (pelas DAs).
- **Dicionário**: `APEX_AI_AGENTS`, `APEX_AI_AGENT_TOOLS`, `APEX_AI_AGENTS_TOOL_PARAMS`.
- **Plug-in novo**: tipo **Generative AI Tool**, para criar tools reutilizáveis próprias.
- **Tools definidas em runtime** (avançado): passe uma coleção de registros de tool para `APEX_AI.CHAT`/`GENERATE`.
  - *Variante 1*: cada tool tem uma `callback_procedure`. O código lê os argumentos em `p_param.args_json` (`JSON_OBJECT_T`) e devolve o resultado em `p_result.result` (`CLOB`). Ver `APEX_AI.GENERATE` Signature 2, Exemplo 3.
  - *Variante 2*: um `p_response_handler_procedure` para a chamada inteira. As tools podem omitir o callback, mas o handler percorre a lista de chamadas e responde com `set_tool_result`. Também permite inspecionar todas as chamadas, ver o uso de tokens e registrar ou alterar a mensagem final. Ver Signature 2, Exemplo 4.

Fonte: [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html), [Changed Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html)

### AI Tool Guardrails (aprovação do usuário antes de executar uma tool)
- Uma tool On Demand sensível pode exigir que o usuário aprove a chamada. Configura-se o título do diálogo, a mensagem (aceita substituições) e os rótulos de OK e Cancel.
- Se o usuário nega, a tool não roda e o APEX define o resultado como "user denied".
- **Restrições atuais**: várias tools com aprovação chamadas de uma vez geram diálogos em sequência, e **uma negação nega o lote inteiro**, inclusive as já aprovadas. Um agente com tools que exigem aprovação **só pode ser usado por componentes de front-end** (Show AI Assistant, Generate Text With AI); chamá-lo via `APEX_AI` não é suportado.

Fonte: [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### Processo "Generate Text with AI", saída estruturada em JSON e limites de tokens
- **Processo de página Generate Text with AI**: equivalente declarativo de `apex_ai.generate()`, para tarefas como gerar tags, resumir ou traduzir.
- **Response Format** (no AI Agent e na API): *Text* (padrão) ou **JSON Object**. Com JSON Object, é obrigatório informar um **JSON Schema**. `APEX_AI.GENERATE` aceita o agente com esse formato ou o schema inline em `p_response_json_schema`.
  - Restrição: agentes com Response Format JSON Object **não** podem ser usados por Show AI Assistant nem por Generate Text Using AI; só por `APEX_AI.GENERATE`.
  - No 26ai, o APEX valida a saída em segundo plano com `DBMS_JSON_SCHEMA`. No 19c, valide no seu código.
  - A maioria dos provedores exige schema "estrito": cada objeto com `"additionalProperties": false` e todos os membros em `required`. Para membro opcional, mantenha-o em `required` com tipo `["string","null"]`.
- **Max AI Tokens**: limita os tokens de entrada e saída das requisições de IA, no nível de instância ou workspace, e também por Generative AI Service ou Vector Provider.
- **Novos provedores**: Anthropic Claude, Google Gemini, Mistral AI e Ollama.

```json
{ "type": "object",
  "properties": { "title": {"type": "string"}, "tags": {"type": "array", "items": {"type": "string"}} },
  "required": ["title", "tags"],
  "additionalProperties": false }
```

Fonte: [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### Anexos de arquivo em APEX_AI.GENERATE (imagens, PDFs)
- `APEX_AI.GENERATE` aceita `p_attachments` do tipo `apex_ai.t_attachments`, uma coleção de `apex_ai.t_attachment(mime_type, content_blob, file_name)`. O campo `detail_level` (`low`, `high`, padrão `auto`) troca fidelidade por velocidade.
- Os tipos aceitos variam por provedor (todos aceitam imagem, nem todos aceitam PDF). Arquivos menores processam bem mais rápido, então limite tamanho e resolução.

```plsql
declare
  l_nomes apex_t_varchar2 := apex_string.split(:P1_ANEXOS, ':');
  l_arq   apex_application_temp_files%rowtype;
  l_anex  apex_ai.t_attachments := apex_ai.t_attachments();
begin
  for i in 1 .. l_nomes.count loop
    select * into l_arq from apex_application_temp_files where name = l_nomes(i);
    l_anex.extend;
    l_anex(l_anex.count) := apex_ai.t_attachment(
        mime_type => l_arq.mime_type, content_blob => l_arq.blob_content, file_name => l_arq.name);
  end loop;
  :P1_RESULTADO := apex_ai.generate(p_prompt => 'Transcreva o texto das imagens.', p_attachments => l_anex);
end;
```

Fonte: [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### Data Reporter (novo construtor de relatórios ad hoc)
- Ferramenta no mesmo nível do App Builder e do SQL Workshop, acessível pela home do APEX. Administradores definem **datasets** a partir de objetos do workspace e montam relatórios simplificados sobre eles.
- As páginas do Data Reporter **não** são editáveis no Page Designer, mas podem ser exportadas e importadas. Há um guia próprio (`apxdr`).

Fonte: [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### Workflow: Parallel Flow, multi-tenant (Tenant ID), atividade de IA e retomada após upgrade da app
- **Parallel Flow**: executa atividades em dois ou mais ramos (*branches*) ao mesmo tempo; o fluxo só segue quando todos terminam.
- **Data Segregation**: workflows e tasks novos gravam o **Tenant ID** da sessão APEX em todas as tabelas de instância. O Workflow Console e a Unified Task List respeitam o tenant da sessão.
- **Export de instâncias**: dá para exportar instâncias de workflow e de task junto com a app e importá-las em outro ambiente (no export SQL; o APEXlang não exporta dados de runtime no 26.1).
- **Atividade Generate Text with AI** no workflow.
- **Retomada automática**: instâncias suspensas durante o upgrade de uma aplicação agora voltam a rodar sozinhas ao fim do processo. Antes era preciso retomá-las manualmente.
- **API nova**: `APEX_WORKFLOW.SET_ACTIVITY_DUE_DATE`, que ajusta o prazo de uma atividade e evita que workflows importados travem em atividades vencidas. Também `APEX_WORKFLOW.DELETE_TASKS`, para apagar instâncias que não são mais necessárias.

Fonte: [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### Task (Human Task): Authorization Scheme como participante, Excluded Owner/Admin, reatribuir pedido de informação
- Um **Authorization Scheme** pode ser participante de uma task, o que atribui a task a um grupo de usuários. As operações Delegate, Invite Participant e Remove Participant continuam valendo só para usuários; o business admin não adiciona nem remove authorization schemes em runtime.
- **Excluded Owners** e **Excluded Admins** (precisam ser usuários) e a operação **Exclude Participant** em runtime.
- **Request Information** pode ser redirecionado a outro usuário quando o iniciador não está disponível.
- Participantes do tipo SQL Query, Function Body ou Expression agora têm code editor, com validação.
- Para que a página de detalhe da task abra o registro certo, inclua `&Pxx_ID=&DETAIL_PK.` no Task Details URL.
- APIs novas: `APEX_HUMAN_TASK.REFRESH_BUSINESS_ADMINS` (recalcula os business admins de tasks pendentes quando quem estava no papel saiu) e `APEX_HUMAN_TASK.DELETE_TASKS`.

Fonte: [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### REST Data Sources: escopo OAuth por chamada, OAuth2 Password Flow, assertions, parâmetros dinâmicos e template directives
- **Escopo na invocação**: Web Credentials do tipo OAuth2 Client Credentials aceitam escopo definido na chamada. Se ainda não há token para aquele escopo, o APEX busca um novo. O escopo da credencial vira o **escopo padrão**. Atributos novos *Invocation Scope* e parâmetro `P_SCOPE` nas APIs PL/SQL.
- **OAuth2**: Client Credentials com **Refresh Token**; tipo novo **OAuth2 Password Flow** (usuário e senha, mais Client ID/Secret opcionais); atributo **Token Authentication Method** (como enviar Client ID e Secret ao servidor de token).
- **Client e User Assertions**: no OAuth Authentication Scheme, o APEX pode gerar assertions assinadas para pedir tokens. O cliente OAuth precisa estar configurado no Identity Provider como *Trusted*, não *Confidential*.
- **Parâmetros dinâmicos**: o valor de um parâmetro de REST source pode vir de static, page item, SQL query, expression (PL/SQL ou JS) ou function body (PL/SQL ou JS).
- **Template directives no Request Body Template**, para montar JSON com propriedades condicionais. Corpos existentes continuam funcionando.
- **OData** passa a aceitar DML (insert, update, delete) via IG, forms ou `APEX_EXEC` (ver §4).

Fonte: [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html), [Changed Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html)

### Map Region: substituições dinâmicas, Bounding Box, API de camadas, legendas e Vector Tiles
- **Dynamic Substitutions** (aplicação, page items, variáveis de sistema) em fill opacity, stroke width e stroke style. Também há suporte à propriedade MapLibre `line-dasharray`.
- **Bounding Box**: restringe a área exibida. Só fica ativo com *Infinite Map* desmarcado.
- **API JS de camadas**: `apex.region("id").hideLayer("nome")`, `showLayer("nome")`, `getLayerIdByName(...)` e `moveLayer(layerId, beforeLayerId)`, para mudar a ordem z. Também a opção `bboxCustom`.
- **Legend** customizada por camada, com template predefinido ou HTML próprio.
- **Vector Tile layers** (atributo *Use Vector Tiles*): usam a geração de vector tiles do banco para grandes volumes.

```js
const r = apex.region("mapa");
r.moveLayer(r.getLayerIdByName("Filiais"), r.getLayerIdByName("Rotas"));
r.hideLayer("Rotas");
```

Fonte: [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### Content Security Policy (CSP) sem unsafe-inline e sem unsafe-hashes no núcleo do APEX
- O 26.1 eliminou do **código do próprio APEX** a dependência de `unsafe-hashes` (estilos inline como `style="display:none;"` viraram classes) e de `unsafe-inline` nos JS do núcleo (comportamentos que usavam script inline agora usam scripts externos ou **nonce**).
- **Não há garantia de conformidade total**: algumas bibliotecas de terceiros embutidas no APEX não são compatíveis com CSP estrito. A doc cita **MapLibre** e **CKEditor**. Bibliotecas e código seus (atributos `onclick`, `onerror`, `style=""`, `href="javascript:..."`) também podem gerar violações.
- **Como configurar**: *Shared Components > Security Attributes > Browser Security > HTTP Response Headers*. Use `Content-Security-Policy-Report-Only` para testar sem bloquear e `Content-Security-Policy` para aplicar a política.
- **Substitutions**: `#APEX_CSP_NONCE#` (para o header, vira `'nonce-...'`), `#APEX_CSP_NONCE_ATTRIBUTE#` (`nonce="..."`), `#APEX_CSP_NONCE_VALUE#` (só o valor) e `#APEX_CSP_DISPLAY_NONE#` (vira `display: none`).

```
Content-Security-Policy-Report-Only: default-src 'self' #APEX_CSP_NONCE#; object-src 'none'; img-src 'self' data:;
```

Fonte: [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html), [Using Content Security Policy (CSP) in APEX](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-csp-in-apex.html)

### Segurança e integração: Fusion Apps, SMTP por workspace, BI Publisher com credencial, links externos
- **Fusion Applications**: a home da integração mostra dados de autenticação dinâmicos, grupos e papéis são puxados para a app automaticamente e há páginas novas de detalhe de usuário e permissões.
- **SMTP por workspace**: as credenciais SMTP podem ser definidas no workspace (*Workspace Preferences*), não só na instância.
- **BI Publisher**: o servidor de impressão aceita usuário e senha (*Instance Administration > Instance Settings > Report Printing*).
- **Disabling External Links**: o administrador pode desligar os links para documentação, fóruns e blogs no Builder e no SQL Workshop, útil em ambientes desconectados.

Fonte: [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### Interactive Report: CSS Classes por coluna, Maximum Rows to Display, seleção de linhas e DA Invoke Interactive Report Dialog
- **CSS Classes** na coluna (várias, separadas por espaço), sem precisar de HTML Expression. Aceita substituições de aplicação, page items, colunas da região e variáveis de sistema.
- **Maximum Rows to Display**: limite de linhas mostradas **depois** de aplicar filtros e ordenação. É diferente de *Maximum Rows to Process*, que limita o que é lido **antes**.
- **Row Selector**: seleção de linhas nas views Standard, Icon e Detail. Retorna os valores da Primary Key Column e permite copiar para a área de transferência. O estado se mantém em paginação e navegação, mas é zerado em qualquer outro refresh da região. A API JS nova é a interface `interactiveReportRegion` (seleção e linha corrente).
- **DA "Invoke Interactive Report Dialog"** (grupo Execute): abre diretamente um diálogo do IR, como *Select Columns* ou *Download*, a partir de um botão.
- Colunas baseadas em Template Component agora podem ser ordenadas e filtradas (ver §4).

Fonte: [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### Novos tipos de aplicação: Theme, Library, Boilerplate (e Standard)
- **Theme**: guarda uma definição de tema (estilos, templates, template components).
- **Library**: shared components reutilizáveis (ex.: authentication schemes, LOVs) para outras apps assinarem.
- **Boilerplate**: subscriptions pré-configuradas e páginas prontas, como ponto de partida de apps novas.
- As apps existentes passam a ser do tipo **Standard**.
- Relacionados: *Subscription Mode* na instalação (§3, PL/SQL) e `APEX_SHARED_COMPONENT.REFRESH`/`PUBLISH` agora também para temas.

Fonte: [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### Page Item Session State Data Type BOOLEAN (somente banco 26ai)
- **Só em banco 26ai ou superior.** O session state ganhou o tipo **BOOLEAN** (`TRUE`, `FALSE` ou `NULL`), alinhado ao BOOLEAN do SQL.
- Disponível nos itens **Checkbox**, **Switch** e **Hidden**: *Session State > Data Type* = `VARCHAR2` (padrão) ou `BOOLEAN`. Com BOOLEAN:
  - source, default e computations precisam resultar em BOOLEAN nativo;
  - o bind do item no PL/SQL é BOOLEAN;
  - onde não há bind, use `apex_session_state.get_boolean` e `apex_session_state.set_value`.
- **Wizards**: Forms e IG mapeiam colunas BOOLEAN para Switch BOOLEAN. Classic e Interactive Reports mapeiam para *Plain Text (based on List of Values)* com uma LOV gerada automaticamente chamada `BOOLEAN`.
- **JavaScript**: diferente de VARCHAR2 e CLOB (sempre string no cliente), um item BOOLEAN usa **Boolean nativo**: `getValue()` e `setValue()` recebem e devolvem `true`/`false`.
- **Plug-ins de item** podem marcar BOOLEAN em *Session State Data Types*. Use `t_item.session_state_data_type`, `t_item_render_param.session_state_value` e `t_item_validation_param.session_state_value`.
- **Restrições**:
  - em contextos estáticos (URL, valor Static), use o texto `TRUE`, `FALSE` ou vazio para null;
  - só vale para **page items**; application items continuam só VARCHAR2;
  - o processo **Invoke API** ainda não aceita itens BOOLEAN;
  - a DA **Set Value** do tipo PL/SQL Expression ou Function Body ainda não atribui BOOLEAN. Contorno: *Execute Server-side Code* com *Items to Return*;
  - em template directives, o item vira `TRUE`, `FALSE` ou vazio.
- **Object Browser**: cria colunas BOOLEAN e edita valores. No Edit Row, aceita qualquer texto que o SQL aceita como BOOLEAN (`Y`, `N`, `T`, `F`, `1`, `0`…).

Fonte: [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html), [aeutl: Changes in Release 26.1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeutl/changes-release.html)

### Dynamic Actions novas: Show Success Message, Show Error Message, Clear Errors, Show Processing e Items to Submit nas DAs de IA
- Grupo **Notification**: **Show Success Message**, **Show Error Message** e **Clear Errors**. Dispensam `apex.message.*` em JavaScript para mensagens simples.
- **Execute Server-side Code** ganhou **Show Processing**: com `on`, mostra spinner por item de *Items to Return* ou, se não houver itens, spinner de página.
- **Open AI Assistant** e **Generate Text with AI** ganharam **Items to Submit**: os valores ficam disponíveis no backend, por exemplo no System Prompt, via substituição (`&P1_ITEM.`).

Fonte: [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### Trigger Actions: DAs declarativas em ações, botões, cards e menus
- **Trigger Actions** permitem definir Dynamic Actions na árvore do Page Designer diretamente sob ações, botões, cards e menus.
- Em regiões multi-linha, os valores da linha ficam acessíveis se a coluna tiver **Available on Client** ligado: em JS com `$v('COLUNA')` e nas mensagens novas com `&COLUNA.`. Esses valores só existem durante a execução daquele conjunto de ações.
- Para enviar ou receber valores do servidor, use *Items to Submit* e *Items to Return*. Para segurança, ligue **Value Protected**.
- Ver em §4 a mudança no Page Designer (clique direito em botão agora cria Trigger Action).

Fonte: [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html), [Changed Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html)

### Declarative Menu Buttons (Type = Menu) e Show as Disabled em botões
- Propriedades novas em botões:
  - **Show as Disabled**: quando a server-side condition é falsa, o botão aparece desabilitado em vez de sumir (mesmo comportamento das Template Component Actions);
  - **Type** = *Standard* (comportamento atual) ou *Menu*, que esconde propriedades de ação e cria uma entrada de Menu sob o botão na Rendering Tree.
- Exigem **Universal Theme 26.1**.

Fonte: [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### Unlimited Attributes para plug-ins de Authorization, Authentication, REST Source, Dynamic Action e Process
- O fim do limite de atributos customizados, que chegou a alguns tipos de plug-in no 24.2, agora vale também para plug-ins de **Authorization**, **Authentication**, **REST Source**, **Dynamic Action** e **Process**. Plug-ins existentes precisam ser adaptados:
  1. Mude **API Interface** para `Procedure`.
  2. Troque as funções antigas por procedures que recebem `p_result in out nocopy ...` (ex.: sentry de autenticação: `procedure x(p_authentication, p_plugin, p_is_public_page, p_result in out nocopy apex_plugin.t_authentication_sentry_result)`; autorização: `p_result in out nocopy apex_plugin.t_authorization_exec_result`). Para REST Source a interface de procedure antiga continua valendo.
  3. Leia atributos por Static ID: `p_authorization.attributes.get_varchar2('meu_attr')`, `get_number`, `get_boolean`. Para substituições, use os parâmetros `p_do_substitutions`, `p_do_serveronly_substitutions` e `p_substitution_escape_mode` em vez do switch *Substitute Attribute Values* (deprecated).
- No upgrade, os atributos existentes recebem os Static IDs `attribute_01`, `attribute_02`… pela sequência. Para atributos novos, escolha IDs curtos, minúsculos e descritivos (`css_classes`, `plsql_code`).
- **DA plug-in, interface nova**: `procedure render(p_dynamic_action, p_plugin, p_param in apex_plugin.t_dynamic_action_render_param, p_render_result in out nocopy apex_plugin.t_dynamic_action_render_result)`. Defina `p_render_result.function_name` e monte `p_render_result.function_param` (`open_object`, `put`, `put_function` com `apex_javascript.c_type_expression`/`c_type_function_body`). No JS, a função recebe `(settings, daConfig)`.
- **Dicionário**: leia atributos pela coluna JSON `attributes` com alias e dot notation; as colunas `attribute_01..15` ficaram obsoletas e retornam null.

```sql
select a.attributes."minha_chave"
  from apex_application_authorization a
 where a.application_id = :APP_ID;
```

Fonte: [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### Template Directives: autoria no code editor, suporte em templates do tema e partials no cliente
- **Code editor**: realce de sintaxe de template directives; `{` lista as diretivas; `#` e `&` listam placeholders e substituições.
- Custom attributes de plug-in ganharam **Template Support**: *None*, *Substitutions* ou *Template Directives - Client*. Isso só afeta a ajuda e o editor: o código do plug-in ainda precisa processar substituições e diretivas.
- **Templates do tema** (button, list, item, region e page) agora aceitam template directives e reuso de partials.
- **Template Component Partials no cliente**: componentes renderizados no navegador (Combobox, Select Many, Select One, Map, colunas de IG, Cards) aceitam HTML Expression com `{with/} ... {apply THEME$AVATAR/}`. CSS e JS do template component são carregados sob demanda.
- APIs JS novas: `apex.util.applyNamedTemplate`, `defineTemplates`, `getTemplateDef` e `listTemplates`; `apex.util.applyTemplate` documenta `{with/}` e `{apply/}`.

```
{with/}
TYPE:=INITIALS
INITIALS:=MH
{apply THEME$AVATAR/}
```

Fonte: [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### Interactive Grid: copiar, recortar, colar e colar inserindo (Copy, Cut, Paste, Paste Insert)
- IG editável: **Copy**, **Cut**, **Paste** (sobrescreve), **Paste Insert** (cria linhas e cola) e arrastar faixas de células de uma planilha.
- Funciona dentro do mesmo IG ou entre IGs, **fora do modo de edição**. A origem precisa colocar dados tabulares na área de transferência, e cabe a você garantir que os dados combinam com as colunas. Selects e LOVs são delicados, porque o valor exibido difere do armazenado.
- **Exige HTTPS** e pode exigir permissão do navegador para acessar a área de transferência.
- Opções novas do widget `grid`: `allowCut`, `allowPaste`, `multipleRanges`, `selectCellsColumn`, `selectCellsRow`; métodos `getSelectedRanges` e `setSelectedRanges`.

Fonte: [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### Itens: infinite scroll em Select One/Many, Combobox e Autocomplete; Quick Pick dinâmico; colar arquivo em File/Image Upload
- **Infinite scroll** em Select One, Select Many, Combobox e Autocomplete: o usuário pode ver todos os resultados sem o limite de *Maximum Values in List*.
- **Quick Pick** com quatro modos: *None*, *Static*, *Dynamic* e *SQL Query*.
- **Allow Copy and Paste** em **File Upload** e **Image Upload**: colar arquivos com `Ctrl+V`/`Cmd+V`.

Fonte: [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### Faceted Search e Smart Filters: Exclude e Maximize
- Facetas e filtros dos tipos Checkbox Group, Radio Group e Range ganharam **Exclude**: filtra por tudo, exceto as opções marcadas. JS: `listControl.allowExclude`.
- Os gráficos de faceted search ganharam a template option **Maximize** (tela cheia, com *Restore*).
- A fatia "Others" dos gráficos (a partir da 11ª série) agora pode ser expandida com clique; *Reset* desfaz (ver §4).

Fonte: [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html), [Changed Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html)

### Builder e ciclo de vida: Application Lock, Run de Global Page e Modal, Sample Data, Blueprints
- **Application Lock**: bloqueia a app contra mudanças pelo App Builder. Só quem bloqueou edita ou desbloqueia; os demais vão para uma página de status, com links para eventuais Working Copies. Com a app bloqueada, **só dá para alterar via APEXlang**. Também serve para proteger o Main quando há Working Copies. Na home do App Builder em modo Report, um cadeado na coluna Actions mostra o estado. Para bloquear: *App Builder (Report) > Actions > ícone de cadeado* ou *Application home > Tasks > Lock Application* (com comentário).
- **Run a partir da Global Page ou de um Modal**: na Global Page, *Save and Run* recarrega a página ativa, com eventuais modais abertos; se nada estiver rodando, abre a home ou o login. Num modal, recarrega o modal; sem modal aberto, recarrega a página ativa.
- **Sample Data**: fonte de dados de exemplo para criar componentes sem definir a fonte real.
- **Blueprints**: formato em Markdown para *Spec-Driven Development* com assistentes de IA. Descreve páginas, navegação, regiões, relatórios, formulários, gráficos, filtros e ações; pode ser inspecionado antes de gerar a app e regenerado quando a especificação muda. É importável pela página Import do App Builder (referência: `github.com/oracle/apex`).

Fonte: [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html), [Locking and Unlocking an Application](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/locking-and-unlocking-an-application.html)

### Listas, Extension Menu, PWA, traduções por Text Messages e Document Generator
- **Listas**: *Link Attributes* nas entradas de listas estáticas e coluna `link_attributes` em listas dinâmicas, para atributos HTML no link.
- **Extension Menu**: *Backlink* da app de extensão para o Page Designer ou o shared component de origem via `apex_extension.get_builder_link`, e atributo **Tab Identifier**, que nomeia e reutiliza a aba do navegador.
- **PWA**: propriedades de manifest `short_name`, `handle_links`, `sizes` e `form_factor`. Screenshots sem elas continuam funcionando, mas não ficam otimizados.
- **Text Message-Based Translations**: exporte as text messages de um idioma (ou de todos) em XLIFF ou CSV, traduza e reimporte. A app roda em vários idiomas **sem** precisar de apps traduzidas separadas.
- **Document Generator**: PDF protegido por senha (fixa ou por substituição de item, como `&P1_SENHA.`), e novas sobrecargas de `GENERATE_DOCUMENT` com templates no OCI Object Storage.

Fonte: [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### SQL Workshop e dicionário: Describe Tables e APEX_DB_DICTIONARY
- **Describe Tables** (*SQL Workshop > Utilities*) e o pacote `APEX_DB_DICTIONARY` geram uma descrição de tabelas e views legível por humanos e LLMs, em Markdown ou texto: colunas, tipos, comentários, annotations e, opcionalmente, constraints e índices.
- Usa `DBMS_DEVELOPER`, então só está disponível no 26ai e em patches recentes do 19c.

Fonte: [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### Universal Theme 26.1: estilo Iris, Metric Card, Blank Page, drawers, Font APEX 2.5, badge em botão
- Novo estilo padrão **Iris**.
- Template components **Metric Card** e **Blank Page**.
- Suporte a grupos em Avatars, Timeline, Comments e Media List.
- Drawers de cima e de baixo, e slot Footer em Inline Drawers e Inline Dialogs.
- Theme Roller com propriedades condicionais e dinâmicas.
- **Font APEX 2.5**: mais de 66 ícones novos e modificadores novos.
- Badge em botão via atributo `data-count`.
- Utility classes de overflow, números tabulares (*tabular numbers*) e flex.
- Alinhamento vertical em page templates.
- Estilos *inbound*/*outbound* em Comments.
- Opção de remover os ícones padrão de arquivo quando o modo de colapso da navegação é *Hidden*.
- Mais variáveis CSS em componentes centrais (ex.: fundo do nó selecionado em Tree).
- Detalhes e migração: app **Universal Theme Reference**.

Fonte: [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### APIs PL/SQL novas e alteradas no 26.1 (APEX_AI, APEX_WORKFLOW, APEX_HUMAN_TASK, APEX_INSTANCE_DEBUG, APEX_DB_DICTIONARY, subscriptions)
| API | Novidade |
|---|---|
| `APEX_AI` | Reescrito em vários pontos: novas sobrecargas de `CHAT` e `GENERATE` com `p_agent_static_id`, tools, `p_response_json_schema`, `p_attachments`, `SET_TOOL_RESULT` |
| `APEX_WORKFLOW` | `SET_ACTIVITY_DUE_DATE`, `DELETE_TASKS` |
| `APEX_HUMAN_TASK` | `REFRESH_BUSINESS_ADMINS`, `DELETE_TASKS` |
| `APEX_INSTANCE_DEBUG` (novo) | Lista debug logs e activity logs no SQL*Plus/SQLcl para usuários com `APEX_ADMINISTRATOR_READ_ROLE` ou `APEX_ADMINISTRATOR_ROLE`. Antes era preciso `SYS`. Os scripts de `apex/utilities/debug` passaram a usá-lo |
| `APEX_DB_DICTIONARY` (novo) | Descrição de tabelas e views para humanos e LLMs (26ai e 19c recente) |
| `APEX_SHARED_COMPONENT` | `REFRESH` e `PUBLISH` agora também para temas |
| `APEX_APPLICATION_INSTALL` | `set_subscription_mode` e `set_subscription_mapping` (só para arquivos exportados do 26.1+) |
| `APEX_INSTANCE_ADMIN`, `APEX_EXEC`, `APEX_EXPORT` | Correções de valores de parâmetros e de tipos de dados |
| `APEX_SESSION_STATE` | `get_boolean`, para itens BOOLEAN |

Para comparar especificações entre versões: APEX Diff (`apex.oracle.com/apexdiff`).

Fonte: [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### APIs JavaScript novas e alteradas no 26.1
- **Novas**: interface `interactiveReportRegion`; `apex.util.applyNamedTemplate`, `defineTemplates`, `getTemplateDef` e `listTemplates`; `mapRegion.hideLayer`, `moveLayer`, `showLayer` e a opção `bboxCustom`; `htmlBuilder.append`, `css` e `toJquery` (melhor suporte a CSP).
- **Widget `grid`**: `getSelectedRanges`/`setSelectedRanges` (tipo `Range`); opções `allowCut`, `allowPaste`, `multipleRanges`, `selectCellsColumn` e `selectCellsRow`; `copyValueToClipboard` mudou o comportamento quando `false`; `updateStatus` ganhou `altMessage`; `copyDownSelection` e `fillSelection` passaram a retornar valor.
- **Outras**: `action.purpose` (acessibilidade de links); pseudo-modificador **`CtrlOrMeta`** em atalhos; parâmetros nomeados nas funções de formatação de `apex.lang`; `RecordMetadata` com `index` e `recSequence` e notificações `addData`/`move` com propriedades novas; `apex.util.showSpinner` com `ariaProcessingStarted`, `ariaStillProcessing`, `ariaProcessed` e `suppressAria`; `facets listControl.allowExclude`; `treeNodeAdapter.getAccDescription` e `accDescription`; menu `popupMenuLabelId` e `aria-keyshortcuts`; `menuButton` com `data-menu-position` e `data-hover-menu`.
- **Terminologia**: a doc JS agora diz "HTML DOM id" onde dizia "static id".

Fonte: [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### Bibliotecas JavaScript embutidas no APEX 26.1 (versões)
jQuery **3.7.1**, jQuery UI **1.14.1**, JET **20.0.2**, MapLibre **5.6.1**, FullCalendar **6.1.20**, DOMPurify **3.4.0**, monaco-editor **0.55.1**, Oracle Rich Text Library (ORTL) **2607.0.2**, marked **17.0.4**, Turndown **7.2.2**, prism.js **1.30.0**, Less.js **4.6.3**, Terser **5.46.0**, OpenTelemetry (core e sdk-trace 2.6.0, instrumentations 0.213.0 e 0.58.0) e especificações de cliente de IA (Anthropic API 0.86.0, Gemini REST b11274, Mistral 0.0.2, Ollama 0.19.0).

Observação: a seção "jQuery UI Deprecated" das Release Notes ainda fala em "custom bundle de jQuery UI 1.13.2", mas a lista de upgrades do 26.1 traz 1.14.1. Não dependa de versão exata do jQuery UI, que de todo modo está deprecated.

Fonte: [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html), [Deprecated in Previous Releases](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/deprecated-previous-releases.html)

---

## 4. Mudanças de comportamento (Changed Behavior) e impacto prático

### "Static ID" de regiões, botões e colunas virou "HTML DOM ID" (o que muda para quem desenvolve)
- O antigo **Static ID** de Regions, Buttons e colunas de IG e IR agora se chama **HTML DOM ID**. O nome "Static ID" ficou reservado para o identificador estável do export APEXlang (§3).
- O **Alias** de relatórios salvos de IG e IR agora se chama **Static ID**.
- No dicionário, a coluna `STATIC_ID` de `apex_application_page_regions`, `apex_application_page_rpt_cols`, `apex_application_page_buttons`, `apex_application_page_ir_col` e `apex_appl_page_ig_columns` está **deprecated**. Use **`HTML_DOM_ID`**.
- Substituições deprecated: `#REGION_STATIC_ID#` e `#BUTTON_ID#` → **`#DOM_ID#`**; `APP_REGION_STATIC_ID` → **`APP_REGION_DOM_ID`**.
- Em `APEX_PLUGIN.T_REGION`: `static_id` e `filter_region_static_id` → `dom_id` e `filter_region_dom_id`.
- **Impacto**: código que lê o dicionário ou monta seletor por "static id" continua funcionando por compatibilidade, mas deve migrar. Em JavaScript **não há compatibilidade** (ver o caso "regionStaticId" em §4 e §8).

Fonte: [Changed Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html), [Deprecated Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/deprecated-features.html)

### Código JS com regionStaticId ou staticId parou de funcionar após o upgrade para o 26.1
**Sintoma:** depois do upgrade, uma função de *JavaScript Initialization Code* compartilhada entre IGs para de aplicar configurações, ou `apex.message.showErrors` não liga o erro à região certa.
**Causa:** propriedades **não documentadas** foram renomeadas junto com o "Static ID → HTML DOM ID", **sem compatibilidade retroativa**: `config.regionStaticId` → `config.regionDomId`; `staticId` em opções de coluna → `domId`; `regionStaticId` em objetos de erro → `regionDomId`.
**Correção:** troque as referências.
```js
function commonIGConfig(config) {
  config.defaultGridViewOptions = { stickyFooter: false };
  if ($("#" + config.regionDomId).hasClass("seqNo")) {   // antes: regionStaticId
    config.defaultGridViewOptions.rowHeader = "sequence";
  }
  return config;
}
apex.message.showErrors([{ type: "error", location: ["page", "inline"],
  regionDomId: "test-region", message: "Mensagem" }]);   // antes: regionStaticId
```
**Prevenção:** busque `regionStaticId` e `staticId` em todo o JS (páginas, static files, plug-ins) antes de subir para o 26.1.

Fonte: [Changed Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html)

### Mudanças na UI do App Builder 26.1 (Import Application, aparência Auto, Page Template obrigatório, Comments…)
- *Install Application* agora se chama **Import Application**.
- A aparência do Builder passou a ser **Auto** (segue o claro/escuro do sistema) em vez de Dark.
- A home do App Builder abre em **Report** em vez de Icon. O IR da home mostra *App Alias* por padrão; *Theme* e *Version* ficam disponíveis pelo menu Actions.
- Com mais de cinco workspaces, a tela de escolha tem busca e ordenação.
- **Page Template não tem mais a opção "Default Template"**. As páginas que a usavam passam a usar o template definido no tema (*Default Page Template* ou *Default Modal Page Template*). Page Template agora é **obrigatório** no Page Designer.
- Shared Components > Templates mostra o *Report Template Type*.
- Mostrar ou esconder os componentes da Global Page (P0) nas views Rendering Tree e Grid Layout: *Utilities > Show > Global Page Components*.
- *Fire on Page Initialization* fica oculto para DAs de Page Load.
- O botão Save do Page Designer fica desabilitado sem mudanças pendentes.
- Os cabeçalhos de grupo do Property Editor ficam fixos ao rolar; as propriedades de LOV subiram na lista; badges e botões têm estilos distintos; contas **Locked** ficam mais visíveis em Manage Users and Groups.
- *View Differences* das Working Copies mostra nome, tipo e ID do componente.
- **Shortcuts**: o *Shortcut Name* virou **Shortcut Static ID**, sem distinção de maiúsculas.
- *Developer Comments* agora se chama **Comments**. O export leva todos os comentários (da aplicação e dos componentes) ou nenhum.
- **Team Development** saiu da barra de menu e fica na home do APEX.
- No SQL Commands, `Ctrl+Enter`/`Cmd+Enter` executa a seleção ou, sem seleção, o comando sob o cursor. *SQL Developer Web* aparece na lista de tarefas do SQL Workshop.

Fonte: [Changed Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html)

### Export e import no 26.1: Data Profiles, subscriptions, imports de página de versões antigas, APEX_EXPORT
- **Data Profile** não é mais exportado sozinho: vai junto do componente pai (REST Source, Data Load Definition, JSON Source). Scripts com `apex_export.get_application(p_components => apex_t_varchar2('DATA_PROFILE:...'))` ainda funcionam, mas podem ser desupported. Migre para exportar o pai.
- **Subscriptions**: o export leva o ID da app master, o Static ID do componente master e o ID interno. No import, o APEX confere se a master e os componentes existem no workspace de destino e permite remapear. **Se faltar um master obrigatório, a instalação falha.** Controle com `apex_application_install.set_subscription_mode` ou com o *Subscription Mode* na página de mapeamento do import.
- **Single page e component exports de versões anteriores ao 26.1 não podem mais ser importados.** Apps inteiras de 24.2 ou anteriores continuam importáveis.
- **`APEX_EXPORT`**: o export APEXlang inclui static files **binários**. Quem consome `APEX_T_EXPORT_FILE` precisa olhar `contents_blob`, não só `contents`.

```plsql
for i in 1 .. l_files.count loop
  if l_files(i).contents_blob is not null then
    null;  -- arquivo binário (imagem, fonte...)
  else
    null;  -- texto em l_files(i).contents
  end if;
end loop;
```

Fonte: [Changed Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html)

### Cópia de shared components entre apps passa a casar por Static ID (com fallback por nome)
- Antes, ao copiar uma página ou um shared component que referencia outros, o APEX às vezes casava por nome e às vezes por Static ID.
- No 26.1, o **Static ID é o identificador principal**. Sem Static ID correspondente no destino, o APEX tenta pelo nome quando o nome é suficientemente único. **Só por Static ID** para Application Computation, Email Template, Search Configuration e Plug-in. Sem correspondência, o componente é copiado para o destino.
- **Static ID na cópia**: copiado sem subscription → Static ID novo, a partir do nome novo. Copiado com subscription para outra app → reutiliza o Static ID do master. Refresh/Publish propagam a mudança de Static ID do master para os assinantes. Vale para REST Data Sources, Email Templates, Search Configurations, Data Load Definitions e JSON Sources. Report Layouts copiados para outra app recebem Static ID novo.

Fonte: [Changed Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html)

### Subscription Status "Could not determine, needs refresh" depois do upgrade
**Sintoma:** depois do upgrade ou do import de uma app antiga, shared components assinados mostram o status *Could not determine, needs refresh*.
**Causa:** a nova coluna Static ID invalidou o cálculo do status para Authentication e Authorization Schemes, Component Groups, Computations, LOVs, Map Background, Build Options, Application Processes, Lists, Plug-ins (com Action Templates ou Attribute Groups), REST Data Sources, JSON Sources e Data Load Definitions.
**Correção:** clique **Refresh** no assinante ou **Publish** no master.

Fonte: [Changed Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html)

### Static IDs duplicados de JET Chart Series e Axis foram renomeados no upgrade
**Sintoma:** customização JS de gráfico JET que localizava séries ou eixos pelo Static ID para de funcionar depois do upgrade.
**Causa:** o Static ID agora é único. Valores duplicados foram alterados para ficarem únicos.
**Correção:** para apps antigas, existe a propriedade **JavaScript Static ID** em Series e Axis, que preserva o identificador antigo. Ela é **deprecated** e só aparece no Page Designer se já tiver valor. Sem ela, o Static ID é usado como identificador JS. Em apps novas, use o Static ID único.

Fonte: [Changed Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html), [Deprecated Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/deprecated-features.html)

### Text Messages caem para o idioma primário quando falta tradução
- Se não existe a text message no idioma pedido, o APEX agora usa a do **idioma primário** da aplicação.
- Relacionado (Compatibility Mode 24.2/26.1): sintaxe estendida `&{TEXT.MESSAGE}` para referenciar text messages.

Fonte: [Changed Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html)

### Automatic Time Zone usa nome de fuso (Europe/Paris), não offset
- Com *Automatic Time Zone* ligado, o APEX agora trabalha com **nomes de fuso**. `SESSIONTIMEZONE` pode retornar `America/Sao_Paulo` em vez de `-03:00`.
- **Impacto**: código que fazia parse do offset textual de `SESSIONTIMEZONE` precisa aceitar nomes. Corrige o bug 34456483 (detecção só pegava o offset). O link "Set Time Zone" pode ser escondido (FR-4644).

Fonte: [Changed Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html), [Fixed Bugs](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/fixed-bugs.html)

### Timeouts de sessão em UTC no APEX_WORKSPACE_SESSIONS: comparação com SYSDATE errada
**Sintoma:** rotina que encerra ou alerta sessões expiradas comparando `APEX_WORKSPACE_SESSIONS` com `SYSDATE` passa a errar por algumas horas.
**Causa:** no 26.1, os timeouts novos ou recalculados são gravados em **UTC**. As colunas são `DATE`, então não há indicação de fuso no tipo.
**Correção:** compare com `SYSTIMESTAMP` convertido para UTC:
```sql
select apex_session_id, session_idle_timeout_on, session_life_timeout_on
  from apex_workspace_sessions
 where cast(systimestamp at time zone '00:00' as date) > session_idle_timeout_on
    or cast(systimestamp at time zone '00:00' as date) > session_life_timeout_on;
```

Fonte: [Changed Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html)

### IA: AI Configurations viram AI Agents, RAG Sources viram Augment System Prompt, Cohere v2
- A troca de nome vale para a UI, os parâmetros de API e as views. `APEX_AI.GENERATE` e `CHAT` com `p_config_static_id` estão **deprecated**; use as sobrecargas com **`p_agent_static_id`**.
- `apex_appl_ai_configs` e `apex_appl_ai_config_rag_srcs` continuam no 26.1, mas serão removidas; use `apex_appl_ai_agents` e `apex_appl_ai_agent_tools`. As colunas `ai_config_id`/`ai_config_name` (em `apex_application_page_items`, `_page_regions`, `_page_da_acts`) cedem lugar a `ai_agent_id`/`ai_agent_name`, que também existem em `apex_application_page_proc`, `apex_appl_workflow_activities` e `apex_appl_page_comp_da_acts`.
- **Cohere**: o APEX passou a usar o endpoint REST **v2**. Configurações v1 migram sozinhas no upgrade da instância ou no import da app.
- O AI Assistant do Query Builder agora considera **views** além de tabelas.

Fonte: [Changed Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html), [Deprecated Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/deprecated-features.html)

### Interactive Report: colunas Template Component ordenáveis e filtráveis, fim do limite de 32K por linha
- Colunas de IR baseadas em Template Component agora podem ser **ordenadas e filtradas por valor**. Agregações, control breaks, highlight, computations, chart, group by e pivot continuam desabilitados para elas.
- **Fim do limite de 32K de saída por linha** no IR (geração de saída refeita; FR-2307 e FR-4096). Corrige também o limite de 32K em export XLSX (bug 37466556).

Fonte: [Changed Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html)

### Template directives: "FALSE" agora conta como valor falso
- A lista de **False Values** das template directives (PL/SQL e JS) ganhou `"FALSE"`. Agora é `["F","f","N","n","0","FALSE"]`. Qualquer outro valor é verdadeiro.
- **Impacto**: `{if COLUNA/}` com valor `"FALSE"` (como as colunas BOOLEAN exibidas como texto) passa a ser falso. Antes era verdadeiro. Atenção: `"false"` minúsculo **não** está na lista.

Fonte: [Changed Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html)

### Interactive Grid: row header, data-rownum e mudanças em clipboard e seleção
- O *row header* de sequência (opção `rowHeader`) agora tem valor também para registros inseridos e se atualiza em inserts e deletes (baseado em `recSequence`). O atributo não documentado `data-rownum` pode mudar em inserts e deletes (baseado em `index`).
- **Clipboard**:
  - colunas virtuais vazias, inclusive o botão Actions, não são copiadas;
  - o row header de seleção só é copiado se tiver texto;
  - **Copy** copia links como links quando a coluna tem URL ou `linkTargetColumn`; **Paste** cola link como link se a coluna usa `linkTargetColumn`;
  - também são copiáveis células read-only, cabeçalhos e group headers, linhas de agregação e de control break.
- **Seleção**:
  - o botão *Selection Actions* é sempre tab stop;
  - spinner em operações em massa longas;
  - insert em *Cell Selection* entra **depois** da linha atual;
  - as teclas Insert e Delete passam pelas actions `selection-add-row` e `selection-delete` (personalizáveis);
  - atalhos: `Ctrl+Space` seleciona a coluna, `Shift+Space` a linha e `Ctrl/Cmd+A` tudo;
  - row headers de seleção não são selecionáveis;
  - a seleção pode incluir linhas de agregação;
  - com virtual scroll, selecionar células ainda não carregadas mostra *Load All*;
  - cabeçalhos de linha e coluna destacam a seleção.
- **Impacto**: CSS ou JS que dependia de `data-rownum` ou do conteúdo copiado precisa de revisão.

Fonte: [Changed Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html)

### Dynamic Actions: Trigger Action no clique direito de botão, &"COL%RETURN". em HTML Expression, Cards com modelo editável
- No Page Designer, o clique direito em botão oferece **Create Trigger Action** em vez de Create Dynamic Action. Para a DA "clássica", ponha o *Type* do botão em **Defined by Dynamic Action** e crie a DA.
- Em Template Components e IR, colunas de LOV podem expor o **valor de retorno** numa HTML Expression com `&"COLUMN_ALIAS%RETURN".`. **As aspas duplas são obrigatórias**; sem elas o resultado é NULL.
- **Cards** e **Template Components** (com colunas *Available on Client*) agora têm **modelo editável**, então Set Value e Execute Server-side Code podem devolver colunas. **Atenção**: manipulações de DOM feitas nos cards ou componentes depois da renderização **se perdem**, porque a UI é redesenhada quando o modelo muda.

Fonte: [Changed Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html)

### DA de Page Unload agora escuta "pagehide" (unload sendo removido dos navegadores)
**Sintoma:** DA de *Page Unload* que salvava rascunho ou registrava saída dispara em momentos diferentes ou não dispara, principalmente no celular.
**Causa:** os navegadores estão abandonando o evento `unload`. No 26.1 a DA passou a escutar **`pagehide`**, o evento de semântica mais próxima. Nem `pagehide` nem `unload` são confiáveis em todos os casos, e o evento Page Unload está deprecated desde o 24.1.
**Correção:** revise o que essas DAs fazem e prefira salvar estado em eventos explícitos (change, submit, visibilidade). Para encontrá-las:
```sql
select application_id, page_id, dynamic_action_name, when_event_name
  from apex_application_page_da
 where when_event_internal_name = 'unload'
 order by application_id, page_id;
```

Fonte: [Changed Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html), [Deprecated in Previous Releases](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/deprecated-previous-releases.html)

### Faceted Search mostra placeholder ao carregar; CSS customizado pode ser afetado
- Durante o carregamento, a região de faceted search mostra conteúdo **placeholder**. É automático, mas CSS próprio que mire o componente de facetas deve ser conferido contra o markup novo.

Fonte: [Changed Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html)

### Colunas attribute_01..25 retornam null em mais views do dicionário (use a coluna JSON attributes)
- No 26.1, as colunas `attribute_01...25` passaram a retornar **null** em: `apex_application_auth`, `apex_application_authorization`, `apex_application_page_da_acts`, `apex_application_page_proc`, `apex_application_processes`, `apex_appl_automation_actions`, `apex_appl_plugin_settings`, `apex_appl_taskdef_actions`, `apex_appl_web_src_modules`, `apex_appl_workflow_activities`.
- No 24.2 isso já valia para `apex_application_page_items`, `apex_appl_page_ig_columns`, `apex_appl_plugin_settings` e `apex_appl_page_filters`. No 23.2, para template components em `apex_application_page_regions` e `apex_application_page_ir_col`.
- **Correção**: use a coluna JSON **`attributes`**, com alias de tabela (obrigatório para a dot notation):
```sql
select p.process_name, p.attributes
  from apex_application_page_proc p
 where p.application_id = 100;
```
- **Impacto**: scripts de auditoria ou documentação automática que liam `attribute_NN` passam a ver null **sem erro**.

Fonte: [Changed Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html), [Desupported in Previous Releases](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/desupported-previous-releases.html)

### Outras mudanças de comportamento: OData com DML, Others expansível em gráficos de facetas, atalhos no Mac, Object Browser
- **OData** agora aceita insert, update e delete (IG, forms, `APEX_EXEC`).
- Gráficos de **Faceted Search**: a fatia "Others" (11ª série em diante) é expansível com clique; *Reset* desfaz.
- **Atalhos no Mac** (API `actions`): espaço entre modificador e tecla, e símbolos em vez de nomes.
- **Object Browser**: seleção de múltiplas faixas com `Ctrl/Cmd+clique` ou `Shift+F8`.

Fonte: [Changed Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html)

### Compatibility Mode: o que cada modo muda (4.1 a 26.1)
O atributo *Compatibility Mode* congela comportamentos do runtime. Os modos são cumulativos.

| Modo | Comportamento introduzido |
|---|---|
| 4.1 | Automatic DML acusa erro ao renderizar se a coluna-fonte do item é inválida; os atributos *Cache* e *Embed in Frames* passam a valer; o INSERT só inclui colunas DB Column presentes no POST que não sejam Display Only sem Save State |
| 4.2 | Condições de todas as regiões de um display point são avaliadas **antes** de renderizar o ponto, então região PL/SQL que seta estado para a condição de outra não funciona (use computation ou process); processos Before e After Regions rodam antes e depois de **todas** as regiões; Text Area respeita Maximum Width; colunas de relatório em links `javascript:` são escapadas para JS automaticamente |
| 5.0 | `#WORKSPACE_IMAGES#` não devolve mais arquivos da app (use `#APP_IMAGES#`); `apex_custom_auth.logout` e `wwv_flow_custom_auth_std.logout*` dão erro (use `apex_authentication.logout`); timeout sem URL gera erro; item de coluna com *Source Used = Only when null* gera erro (use *Always*) |
| 5.1/18.x | Botões com *Execute Validations = Yes* também validam no cliente (cuidado com Cancel e Previous); DA Ajax com *Wait for Result* passa a ser assíncrona |
| 19.1 | Rich Text Editor valida *Max Length* sobre o HTML |
| 19.2–21.1 | Classic Report renderiza vazio, sem `&nbsp;` |
| 21.2–24.1 | `APEX_ERROR.ADD_ERROR` num processo interrompe os processos seguintes e mostra os erros inline |
| 24.2/26.1 | Sintaxe estendida `&{TEXT.MESSAGE}` para text messages |

Fonte: [Changed Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html)

### Network Services (ACL) para e-mail, REST e impressão: concessão ao APEX_260100
- Para `APEX_MAIL`, REST, LDAP e impressão remota, o DBA precisa conceder `connect` ao usuário dono do APEX (**`APEX_260100`**) com `DBMS_NETWORK_ACL_ADMIN`. A concessão vale para a instância inteira. O schema do workspace só precisa de ACL própria se usar `UTL_HTTP` ou `UTL_SMTP` diretamente.
- No **Autonomous AI Database**, isso não se aplica.
- O upgrade reaplica a configuração da versão anterior. O parâmetro `compatible` do banco precisa ser ≥ `11.1.0.0.0`.
```plsql
begin
  dbms_network_acl_admin.append_host_ace(
    host => 'localhost',   -- ou '*' para qualquer host
    ace  => xs$ace_type(privilege_list => xs$name_list('connect'),
                        principal_name => apex_application.g_flow_schema_owner,
                        principal_type => xs_acl.ptype_db));
end;
/
```

Fonte: [Changed Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html)

### ORA-44416: Invalid ACL ao conceder Network Services
**Sintoma:** `APPEND_HOST_ACE` falha com `ORA-44416: Invalid ACL`.
**Causa:** a ACL atribuída a `'*'` referencia usuários que já foram apagados (principals órfãos).
**Correção:** identifique com `select acl, principal from dba_network_acls nacl, xds_ace ace where host = '*' and lower_port is null and upper_port is null and nacl.aclid = ace.aclid and not exists (select null from all_users where username = principal);`. Depois, remova só os principals órfãos de `XDB.XDB$ACL` (com `DELETEXML`) ou apague a ACL inteira se nenhum principal for válido, faça `COMMIT` e rode de novo a concessão ao `APEX_260100`. O script completo está na fonte.

Fonte: [Changed Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html)

---

## 5. Deprecated no 26.1 (com alternativa)

> Deprecated = ainda funciona, mas será removido. Rode o **APEX Advisor** para achar usos de atributos deprecated nas apps.

### APIs PL/SQL deprecated no 26.1 e substitutas
| Deprecated | Use em vez disso |
|---|---|
| `APEX_AI.GENERATE` Signature 3 e `APEX_AI.CHAT` Signature 3 (com `p_config_static_id`) | Sobrecargas com `p_agent_static_id` (a página da API indica a Signature 1) |
| `APEX_PLUGIN.T_REGION.static_id` / `filter_region_static_id` | `dom_id` / `filter_region_dom_id` |
| `APEX_PLUGIN.t_plugin.name` | `t_plugin.static_id` |
| `APEX_UTIL.CACHE_GET_DATE_OF_PAGE_CACHE` | `APEX_PAGE.GET_CACHE_DATE` |
| `APEX_UTIL.CACHE_GET_DATE_OF_REGION_CACHE` | `APEX_REGION.GET_CACHE_DATE` |
| `APEX_UTIL.PUBLIC_CHECK_AUTHORIZATION` | `APEX_AUTHORIZATION.HAS_ACCESS` (Release Notes) ou `APEX_AUTHORIZATION.IS_AUTHORIZED` (página da API) — ver nota |
| `APEX_UTIL.PURGE_REGIONS_BY_NAME`, `_BY_PAGE`, `_BY_APP` | Sem substituta indicada |

**Divergência na doc**: as Release Notes indicam `APEX_AUTHORIZATION.HAS_ACCESS` para substituir `PUBLIC_CHECK_AUTHORIZATION`; a página da API indica `IS_AUTHORIZED`. A diferença: `HAS_ACCESS(p_static_id)` recebe o **Static ID** do authorization scheme (ex.: `'admin-rh'`), enquanto `IS_AUTHORIZED` recebe o **nome** (ex.: `'ADMIN_RH'`). As duas devolvem BOOLEAN e usam o cache de autorização. `HAS_ACCESS` combina com a ênfase do 26.1 em Static IDs estáveis; `IS_AUTHORIZED` é a que este projeto já usa.

Fonte: [Deprecated Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/deprecated-features.html), [HAS_ACCESS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AUTHORIZATION.HAS_ACCESS-Function.html), [PUBLIC_CHECK_AUTHORIZATION Function (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PUBLIC_CHECK_AUTHORIZATION-Function-DEPRECATED.html), [CHAT Function Signature 3 (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AI.CHAT-Function-Signature-3.html), [GENERATE Function Signature 3 (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AI.GENERATE-Function-Signature-3.html)

### APIs JavaScript deprecated no 26.1 (invokeAfterPaint, getSelectedRange)
| Deprecated | Use em vez disso |
|---|---|
| `apex.util.invokeAfterPaint` | `window.requestAnimationFrame` |
| `apex.util.cancelInvokeAfterPaint` | `window.cancelAnimationFrame` |
| `grid.getSelectedRange` (e a propriedade `selectedRange` no contexto do menu) | `grid.getSelectedRanges` (`selectedRanges`) |

Fonte: [Deprecated Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/deprecated-features.html)

### Substitution strings deprecated no 26.1 (#REGION_STATIC_ID#, #BUTTON_ID#, APP_REGION_STATIC_ID)
- `#REGION_STATIC_ID#` e `#BUTTON_ID#` → **`#DOM_ID#`** (em templates de região e de botão).
- `APP_REGION_STATIC_ID` → **`APP_REGION_DOM_ID`**.
- Ainda funcionam, mas atualize templates customizados e plug-ins.

Fonte: [Deprecated Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/deprecated-features.html)

### Views e colunas do dicionário deprecated no 26.1
- Views `apex_appl_ai_configs` e `apex_appl_ai_config_rag_srcs` → `apex_appl_ai_agents` e `apex_appl_ai_agent_tools`.
- Colunas `ai_config_id`/`ai_config_name` (em `apex_application_page_items`, `apex_application_page_regions`, `apex_application_page_da_acts`) → `ai_agent_id`/`ai_agent_name`.
- Coluna `STATIC_ID` em `apex_application_page_regions`, `apex_application_page_rpt_cols`, `apex_application_page_buttons`, `apex_application_page_ir_col` e `apex_appl_page_ig_columns` → **`HTML_DOM_ID`**.

Fonte: [Deprecated Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/deprecated-features.html)

### Recursos deprecated no 26.1: Legacy Calendar, JavaScript Static ID, Export Repository, RESTful Services do SQL Workshop, modelos Cohere
- **Legacy Calendar Templates**: o template não existe mais no UT 26.1 e **o export APEXlang dá erro se houver região Legacy Calendar**. No upgrade, o APEX apaga os templates Legacy Calendar sem referência. Elimine as regiões Legacy Calendar antes de exportar em APEXlang.
- **JavaScript Static ID** de JET Chart Series e Axis: só aparece se já tiver valor; use o Static ID único.
- **Export Repository**: deprecated, será removido.
- **RESTful Services no SQL Workshop**: a definição de REST APIs por ali está deprecated. A especificação declarativa continua no **SQL Developer Web** (ORDS).
- **Modelos Cohere no OCI Generative AI**: `cohere.command-r-08-2024`, `cohere.command-r-plus-08-2024`, `cohere.command-latest` e `cohere.command-plus-latest` → **`cohere.command-a-03-2025`** (que também suporta tools, anexos e mais).

Fonte: [Deprecated Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/deprecated-features.html)

### Switch "Substitute Attribute Values" de plug-ins deprecated (Authorization, Authentication, DA, Process)
- Ao migrar o plug-in para a interface `Procedure`, o switch some. Para substituir valores, use os parâmetros de `attributes.get_varchar2(p_static_id, p_do_substitutions, p_do_serveronly_substitutions, p_substitution_escape_mode)`. Em region plug-ins, o mesmo switch está deprecated desde o 24.1; a alternativa é `apex_plugin_util.replace_substitutions`.

Fonte: [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html), [Deprecated in Previous Releases](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/deprecated-previous-releases.html)

---

## 6. Deprecated em releases anteriores (ainda presentes no 26.1)

### APIs deprecated em 23.1–24.2 ainda presentes no 26.1 e substitutas
| Desde | Deprecated | Use em vez disso |
|---|---|---|
| 24.2 | `APEX_LANG.MESSAGE` | `APEX_LANG.GET_MESSAGE` (aceita parâmetros nomeados) |
| 24.2 | `APEX_PLUGIN_UTIL.EXECUTE_PLSQL_CODE` | `APEX_EXEC.EXECUTE_PLSQL` (Signature 1 ou 2) |
| 24.2 | `APEX_UTIL.CUSTOM_CALENDAR`, `INCREMENT_CALENDAR` | Sem substituta indicada |
| 24.1 | Pacote `APEX_APPROVAL` inteiro | `APEX_HUMAN_TASK` |
| 24.1 | `APEX_UTIL.URL_ENCODE` | `UTL_URL.ESCAPE` (função do banco) |
| 24.1 | `APEX_PLUGIN_UTIL.PRINT_DISPLAY_ONLY` | `APEX_PLUGIN_UTIL.PRINT_READ_ONLY` |
| 24.1 | `APEX_AUTOMATION.ABORT` | `APEX_AUTOMATION.TERMINATE` |
| 23.1 | `APEX_UTIL.SET_BUILD_OPTION_STATUS`, `GET_BUILD_OPTION_STATUS` (2 sobrecargas), `SET_APPLICATION_STATUS`, `GET_APPLICATION_STATUS`, `SET_GLOBAL_NOTIFICATION`, `GET_GLOBAL_NOTIFICATION`, `SET_APP_BUILD_STATUS` | Os equivalentes em **`APEX_APPLICATION_ADMIN`** |
| 22.1 | `APEX_IR.GET_REPORT` | `APEX_REGION.OPEN_QUERY_CONTEXT` (Signature 1) |

Fonte: [Deprecated in Previous Releases](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/deprecated-previous-releases.html), [MESSAGE Function (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/MESSAGE-Function.html), [URL_ENCODE Function (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/URL_ENCODE-Function.html), [GET_REPORT Function (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_REPORT-Function.html), [APEX_AUTOMATION ABORT Procedure (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AUTOMATION_ABORT-Procedure.html)

### Outras APIs PL/SQL marcadas "(Deprecated)" na API Reference 26.1, com substituta
Lista das páginas do `aeapi` marcadas como deprecated que não aparecem acima, com a alternativa indicada na própria página:

| Deprecated | Use em vez disso |
|---|---|
| `APEX_UTIL.STRING_TO_TABLE` | `APEX_STRING.STRING_TO_TABLE` |
| `APEX_UTIL.TABLE_TO_STRING` | `APEX_STRING.JOIN` / `JOIN_CLOB` |
| `APEX_UTIL.PUBLIC_CHECK_AUTHORIZATION` | `APEX_AUTHORIZATION.IS_AUTHORIZED` (por nome) ou `HAS_ACCESS` (por Static ID) |
| `APEX_UTIL.RESET_AUTHORIZATIONS` | `APEX_AUTHORIZATION.RESET_CACHE` |
| `APEX_UTIL.IR_CLEAR`, `IR_DELETE_REPORT`, `IR_DELETE_SUBSCRIPTION`, `IR_FILTER`, `IR_RESET` | Os procedimentos equivalentes de `APEX_IR` (só em processo de submit) |
| `APEX_UTIL.SET_CURRENT_THEME_STYLE` | Sem substituta indicada na página |
| `APEX_CUSTOM_AUTH.LOGOUT` | `APEX_AUTHENTICATION.LOGOUT` |
| `APEX_DEBUG.LOG_MESSAGE` | `APEX_DEBUG.ERROR`, `WARN`, `MESSAGE`, `INFO`, `ENTER`, `TRACE` |
| `APEX_PAGE.GET_UI_TYPE`, `APEX_PAGE.IS_DESKTOP_UI` | Sem substituta indicada na página |
| `APEX_PLUGIN.GET_INPUT_NAME_FOR_PAGE_ITEM` | `APEX_PLUGIN.GET_INPUT_NAME_FOR_ITEM` |
| `APEX_PLUGIN_UTIL.DEBUG_PAGE_ITEM` (2 sobrecargas), `GET_POSITION_IN_LIST`, `PAGE_ITEM_NAMES_TO_JQUERY` | Sem substituta indicada |
| `APEX_PLUGIN_UTIL.PRINT_DISPLAY_ONLY` (2 sobrecargas) | `PRINT_READ_ONLY` |
| `APEX_EXEC.EXECUTE_WEB_SOURCE` | `APEX_EXEC.EXECUTE_REST_SOURCE` |
| `APEX_EXEC.OPEN_WEB_SOURCE_QUERY` | `APEX_EXEC.OPEN_REST_SOURCE_QUERY` |
| `APEX_EXEC.OPEN_WEB_SOURCE_DML_CONTEXT` | `APEX_EXEC.OPEN_REST_SOURCE_DML_CONTEXT` |
| `APEX_EXEC.PURGE_WEB_SOURCE_CACHE` | `APEX_EXEC.PURGE_REST_SOURCE_CACHE` |
| `APEX_IG.ADD_FILTER` Signature 2 (por nome de relatório) | `APEX_IG.ADD_FILTER` Signature 3. Em qualquer versão, chame só em processo de **submit**: em processo de renderização, o download (CSV, HTML, e-mail) pode trazer dados diferentes do que o usuário vê |
| `APEX_BACKGROUND_PROCESS.ABORT` (2 sobrecargas) | `APEX_BACKGROUND_PROCESS.TERMINATE` |
| `APEX_ZIP.GET_FILES` | `APEX_ZIP.GET_DIR_ENTRIES` |
| `APEX_ZIP.GET_FILE_CONTENT` Signature 1 | `GET_FILE_CONTENT` Signature 2 |
| `APEX_WEB_SERVICE.OAUTH_AUTHENTICATE` Signature 2 (sem default para wallet) | `APEX_WEB_SERVICE.OAUTH_AUTHENTICATE_CREDENTIAL` |
| `APEX_JAVASCRIPT.ADD_3RD_PARTY_LIBRARY_FILE`, `APEX_CSS.ADD_3RD_PARTY_LIBRARY_FILE` | Desupported desde o 24.2 (ver §7); a página da API ainda existe |

Fonte: [STRING_TO_TABLE Function (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/STRING_TO_TABLE-Function.html), [TABLE_TO_STRING Function (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/TABLE_TO_STRING-Function.html), [RESET_AUTHORIZATIONS Procedure (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/RESET_AUTHORIZATIONS-Procedure-DEPRECATED.html), [IR_FILTER Procedure (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/IR_FILTER-Procedure-DEPRECATED.html), [LOGOUT Procedure (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/LOGOUT-Procedure-DEPRECATED.html), [LOG_MESSAGE Procedure (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/LOG_MESSAGE-Procedure-Deprecated.html), [GET_UI_TYPE Function (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_UI_TYPE-Function.html), [GET_INPUT_NAME_FOR_PAGE_ITEM Function (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_INPUT_NAME_FOR_PAGE_ITEM-Function.html), [EXECUTE_WEB_SOURCE Procedure (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.EXECUTE_WEB_SOURCE-Procedure.html), [OPEN_WEB_SOURCE_QUERY Function (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_EXEC.OPEN_WEB_SOURCE_QUERY-Function.html), [ADD_FILTER Procedure Signature 2 (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_IG-ADD_FILTER-Procedure-Signature-2.html), [ABORT Procedure Signature 1 (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_BACKGROUND_PROCESS.ABORT-Procedure-Signature-1.html), [GET_FILES Function (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_ZIP.GET_FILES-Function.html), [OAUTH_AUTHENTICATE Procedure Signature 2 (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/OAUTH_AUTHENTICATE-Procedure-Signature-2.html)

### Pacote APEX_APPROVAL deprecated (desde 24.1): migrar para APEX_HUMAN_TASK
- Todo o `APEX_APPROVAL` está deprecated: `CREATE_TASK`, `APPROVE_TASK`, `REJECT_TASK`, `CLAIM_TASK`, `DELEGATE_TASK`, `GET_TASKS`, `IS_ALLOWED`, `SET_TASK_PRIORITY` e os demais. O substituto é **`APEX_HUMAN_TASK`**, que recebe as novidades do 26.1 (`REFRESH_BUSINESS_ADMINS`, `DELETE_TASKS`).

Fonte: [APEX_APPROVAL (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPROVAL.html), [Deprecated in Previous Releases](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/deprecated-previous-releases.html)

### APIs JavaScript deprecated em versões anteriores (apex.widget.initPageItem, apex.server async, etc.)
| Deprecated | Alternativa ou observação |
|---|---|
| `apex.widget.initPageItem` | `apex.item.create` |
| Passar um **elemento DOM** em vez do id/nome em `apex.item(...)`/`apex.item.create` | Passe o id/nome do item |
| Opção `async` em `apex.server.process`/`plugin` (`pOptions`) | Será removida; use o modelo assíncrono (Promise ou callbacks) |
| `apex.navigation.dialog.registerCloseHandler` | Deprecated desde 18.2 |
| `apex.pwa.getInstallText` | Deprecated |
| `item.hide(pHideRow)` / `item.show(pShowRow)`: parâmetros `pHideRow` e `pShowRow` | Deprecated (dependem de layout em tabela) |
| `apex.page.confirm` com mensagem padrão | A mensagem padrão (não localizada) está deprecated; passe sempre a sua |
| `tableModelView`: opções `useIconList` e `iconListOptions`, método `getIconList` | Deprecated |
| `treeNodeAdapter`: `accDescriptionId` | Deprecated |
| jQuery UI (desde 20.1) | Remova as dependências do seu código e dos plug-ins; os componentes nativos ainda o usam, mas o suporte será retirado. Não há mais widgets avulsos nem CSS do jQuery UI. `apex.region(...).call` e `widgetName` ficam por compatibilidade |

Funções JS deprecated ou desupported ficam em `/i/libraries/apex/legacy*` e só são carregadas se *Include Deprecated or Desupported Javascript Functions* estiver marcado em *User Interface Attributes*.

Fonte: [apex.widget](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.widget.html), [apex.item](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.item.html), [apex.server](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.server.html), [apex.navigation.dialog](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.navigation.dialog.html), [apex.pwa](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.pwa.html), [item](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/item.html), [apex.page](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.page.html), [tableModelView](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/tableModelView.html), [JavaScript API Reference (index)](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/index.html)

### Page Unload, Number Field com substituições em Min/Max e jQuery Date Picker deprecated
- **DA Page Unload** (desde 24.1): o evento `unload` do navegador está sendo descontinuado. No 26.1, a DA escuta `pagehide` (ver §4).
- **Number Field**: substituições dinâmicas em Min/Max Value (ex.: `&P1_MIN.`) estão deprecated desde 24.1. A Oracle promete um seletor declarativo de item no futuro.
- **jQuery Date Picker** (desde 22.2): não pode ser usado em páginas novas; as APIs JS antigas não têm suporte. Troque pelo Date Picker atual.

Fonte: [Deprecated in Previous Releases](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/deprecated-previous-releases.html)

### Markup de itens não documentado (desde 22.2): customize só via apex.item
- Desde o 22.2, o namespace `apex.item` e a interface de item são **as únicas APIs suportadas** para customizar itens. Classes CSS e estrutura HTML não documentadas (ex.: `.apex-item-textarea + .apex-item-textarea-counter`) podem mudar, inclusive para web components.
- Evite CSS que dependa da estrutura do markup e evite event handlers em *Custom Attributes*.

Fonte: [Deprecated in Previous Releases](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/deprecated-previous-releases.html)

### Display Only com Format "HTML (Unsafe)" deprecated e escape duplo em LOVs (desde 23.1)
- **Display Only, Format HTML**: desde 23.1, o HTML é **sanitizado no cliente** (scripts, `javascript:`, `onclick` e similares são removidos). Itens antigos foram migrados para **HTML (Unsafe)**, que está deprecated. Ainda é possível exibir HTML inseguro, mas não é recomendado.
- **Escape duplo em LOVs**: o APEX já escapa os valores exibidos de LOVs. Para não escapar duas vezes, ele detecta LOVs que já chamam `HTF.ESCAPE_SC`, `APEX_ESCAPE.HTML` ou `WWV_FLOW_ESCAPE.HTML`, mas esse mecanismo pode ser removido. **Tire o escape manual das queries de LOV.** Para encontrá-las:
```sql
select * from apex_application_lovs
 where lov_type = 'Dynamic'
   and (   upper(list_of_values_query) like '%HTF.ESCAPE_SC%'
        or upper(list_of_values_query) like '%APEX_ESCAPE.HTML%'
        or upper(list_of_values_query) like '%WWV_FLOW_ESCAPE.HTML%');
-- idem em apex_application_page_items (lov_definition), com lov_named_lov is null
```

Fonte: [Deprecated in Previous Releases](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/deprecated-previous-releases.html)

### Legacy Web Service References, Quick SQL e Object Browser (deprecações antigas)
- **Web Service References** SOAP e REST legados (desde 22.1): migre para **REST Data Sources**.
- **Quick SQL** (desde 23.2): as configurações `#language`, `#tags:true`, `#ondelete` (use a diretiva de coluna `/cascade`), `#longVC` e `#tenantID` e a diretiva `/select` estão deprecated.
- **Object Browser** (desde 23.1): a aba Model e o assistente de Materialized View foram removidos. Crie MVs com `CREATE MATERIALIZED VIEW` no SQL Commands.

Fonte: [Deprecated in Previous Releases](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/deprecated-previous-releases.html)

---

## 7. Desupported (não funciona mais)

### Desupported no 26.1: COMPONENT_SIGNATURE e iOS status bar style
- A coluna **`COMPONENT_SIGNATURE`** passou a ser null em todas as views públicas (comentário marcado como obsoleto). Os utilitários **Application Comparison** e **Component Summary Count** foram removidos. Para comparar versões de uma app, use o diff de Working Copies (agora em APEXlang) ou exports APEXlang no controle de versão.
- **iOS status bar style** (`apple_status_bar_style`) não é mais renderizado.

Fonte: [Desupported Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/desupported-features.html)

### Desupported em releases anteriores: 3rd-party library APIs, TinyMCE, CSSO, export JSON, CKEditor, APEXExport
| Desde | Item | Situação e alternativa |
|---|---|---|
| 24.2 | `apex_javascript.add_3rd_party_library_file`, `apex_css.add_3rd_party_library_file` | Desupported (só carregavam jQuery e jQuery UI considerando o CDN da app); não há substituta indicada |
| 24.2 | `attribute_01..25` null em `apex_application_page_items`, `apex_appl_page_ig_columns`, `apex_appl_plugin_settings`, `apex_appl_page_filters` | Use a coluna JSON `attributes` |
| 24.2 | Rich Text Editor com **TinyMCE** | Migrado automaticamente para **ORTL** (Oracle Rich Text Library); *Initialization JavaScript Function* customizada fica **comentada** |
| 24.2 | **CSSO** (minificação de CSS) | Trocado por uma minificação básica, o que pode afetar static files CSS |
| 24.1 | Export **JSON** da aplicação | Removido. *Export Readable Format* virou switch (off = SQL; on = YAML legível). No 26.1 há também o APEXlang |
| 23.2.9 | **CKEditor 4/5** | Desupported. Código com `CKEDITOR` ou APIs do CKEditor5 não funciona mais; regiões migraram para ORTL |
| 23.2 | Utilitário **APEXExport** (Java) | Removido; use o **SQLcl** |
| 23.2 | `ATTRIBUTE_01..25` de template components em `apex_application_page_regions` e `apex_application_page_ir_col` | Use `r.attributes.CHAVE` (com alias) |

Fonte: [Desupported in Previous Releases](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/desupported-previous-releases.html)

---

## 8. Open Bugs e Known Issues do 26.1 (formato de caso)

> A lista oficial mais atual fica na página "APEX 26.1 Known Issues" (oracle.com). Também existem os Accessibility Conformance Reports (ACR) por área.

### Import APEXlang de app que assina componentes de uma master com ID diferente no destino
**Sintoma:** ao importar via APEXlang uma app que assina shared components de uma master app, o import não acha a master (no destino, a master recebeu outro ID).
**Causa:** o mapeamento de subscription fica no `deployments/default.json` da app exportada, com o ID original da master.
**Correção:** antes de importar, edite `default.json` e ajuste `subscription.masterApps`. Exemplo: master `101` virou `901` no destino:
```json
{ "app": { "id": 102 }, "subscription": { "masterApps": { "101": 901 } } }
```
Depois: `SQL> apex import -input subscribing-app`.

Fonte: [Open Bugs and Known Issues](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/open-bugs-known-issues.html)

### Depois do import APEXlang não aparece a página para configurar Web Credentials e Remote Servers
**Sintoma:** com o import APEXlang concluído, o APEX não mostra a página de conveniência para preencher Web Credentials e Remote Servers marcados *Prompt on Install*.
**Causa:** limitação do 26.1.
**Correção:** ajuste em *Workspace Utilities*, nas páginas de edição de Web Credentials e Remote Servers.

Fonte: [Open Bugs and Known Issues](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/open-bugs-known-issues.html)

### Importar APEXlang numa Working Copy desassocia a cópia da app base
**Sintoma:** depois de importar um export APEXlang numa Working Copy, ela não está mais ligada à aplicação principal (merge e refresh deixam de existir).
**Causa:** known issue de Working Copy e APEXlang no 26.1.
**Correção / workaround:** não importe APEXlang numa Working Copy. Importe na app (ou numa app separada) e crie a Working Copy no Builder.

Fonte: [Open Bugs and Known Issues](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/open-bugs-known-issues.html)

### Import APEXlang dá erro de validação em workflow com Parallel Branch
**Sintoma:** o import APEXlang falha com erro de validação quando a app tem um workflow com atividade **Parallel Branch**.
**Causa:** bug conhecido do 26.1.
**Correção / workaround:** para apps com Parallel Flow, use export e import em **SQL** até sair a correção.

Fonte: [Open Bugs and Known Issues](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/open-bugs-known-issues.html)

### "Server Error" (ORA-00600 qjsnplsDecDomRefCnt) ao fazer merge, refresh ou compare de Working Copy no 19c
**Sintoma:** em *Merge into Main*, *Refresh from Main* ou *Compare Changes*, aparece "Server Error", causado por `ORA-00600: internal error code, arguments: [qjsnplsDecDomRefCnt:noValP]`.
**Causa:** defeito do banco 19c antigo.
**Correção:** atualize o banco para **19.16 ou superior** (o APEX 26.1 já exige 19.18).

Fonte: [Open Bugs and Known Issues](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/open-bugs-known-issues.html)

### ORA-00001 (unique constraint) ao fazer merge de Working Copy
**Sintoma:** o merge da Working Copy falha com `ORA-00001`.
**Causa:** componentes com nomes não únicos entre a Working Copy e o Main.
**Correção:** renomeie os componentes conflitantes.
**Prevenção:** combine a nomenclatura de shared components entre quem trabalha em Working Copies e no Main.

Fonte: [Open Bugs and Known Issues](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/open-bugs-known-issues.html)

### APEX_ACL não reconhece papel com Static ID em minúsculas (ACL Roles)
**Sintoma:** a checagem de papel de um usuário via `APEX_ACL` (a Release Notes cita `apex_acl.user_has_role`; na API Reference a função se chama `HAS_USER_ROLE`) não avalia corretamente um papel recém-criado.
**Causa:** ao criar um role, o APEX gera um Static ID em **minúsculas**.
**Correção:** depois de criar o role, troque o Static ID gerado para **MAIÚSCULAS**.
**Prevenção:** padronize Static IDs de roles em maiúsculas e use o mesmo valor em todo código PL/SQL e tabela de configuração. Ver a aplicação ao Corlix Hub em §13.

Fonte: [Open Bugs and Known Issues](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/open-bugs-known-issues.html), [HAS_USER_ROLE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/HAS_USER_ROLE-Function.html)

### Refresh do tema filho não copia templates locais do tema master (Theme Decoupling)
**Sintoma:** com um theme app master (assinante do UT central) e um theme app filho (assinante do master) no mesmo workspace, o refresh do filho não traz os templates criados localmente no master.
**Causa:** known issue do desacoplamento de temas.
**Correção / workaround:** copie esses templates manualmente para o filho.

Fonte: [Open Bugs and Known Issues](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/open-bugs-known-issues.html)

### HTTP 401 "Anonymous Access is not allowed for OpenApi Service" ao descobrir REST Source BOSS com OAuth no 19c
**Sintoma:** no 19c, ao criar um REST Data Source sobre um endpoint BOSS protegido por OAuth, a descoberta retorna 401 com essa mensagem.
**Causa:** a descoberta precisa da URL totalmente qualificada.
**Correção:** na descoberta, use a URL com o segmento de idioma e o deployment id explícito (ex.: `.../v1:99/$en/exampleobject` em vez de `.../v1/exampleobject`). Depois de criado, edite a URL e remova esses segmentos.
Também: o "total results" do BOSS só funciona em *search views*.

Fonte: [Open Bugs and Known Issues](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/open-bugs-known-issues.html)

### "Method Not Allowed" ao abrir SQL Developer Web pelo App Builder (ORDS 24.1.0)
**Sintoma:** numa instância atualizada com ORDS 24.1.0, o link do App Builder para o SQL Developer Web retorna "Method Not Allowed".
**Causa:** bug do ORDS 24.1.0.
**Correção:** use ORDS 24.1.2 ou posterior. Para o APEX 26.1, o requisito já é ORDS 26.1.1+.

Fonte: [Open Bugs and Known Issues](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/open-bugs-known-issues.html)

### Entradas de sublista não aparecem na busca de listas (List search)
**Sintoma:** uma search configuration definida sobre uma lista não retorna as entradas das sublistas.
**Causa:** limitação atual; a correção é prometida para um release futuro.
**Correção / workaround:** inclua as entradas no nível da lista pesquisada ou use outra fonte de busca.

Fonte: [Open Bugs and Known Issues](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/open-bugs-known-issues.html)

### Mensagens de DA Confirm ou Alert truncadas ao subir de 21.2 ou anterior
**Sintoma:** depois do upgrade a partir do 21.2 ou anterior, textos longos de DAs *Confirm* e *Alert* aparecem cortados (perda de dados).
**Causa:** o APEX passou a escapar essas mensagens em HTML, o que pode estourar o limite de 4000 bytes.
**Correção:** **antes** do upgrade, procure as mensagens afetadas e converta-as em Text Messages referenciadas por substituição:
```sql
select * from apex_application_page_da_acts
 where action_name in ('Alert', 'Confirm')
   and (lengthb(attribute_01) + 4 * nvl(regexp_count(attribute_01, '&|"|<|>'), 0)) > 4000;
```
Atenção: no 26.1, `attribute_01` desta view retorna null (§4). Rode a query **na versão antiga**, antes do upgrade.

Fonte: [Open Bugs and Known Issues](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/open-bugs-known-issues.html)

### Plug-in "Source Display" das Sample Apps antigas para de funcionar
**Sintoma:** o region plug-in *Source Display* de uma Sample App instalada numa versão anterior dá erro.
**Causa:** removeram as views de AnyChart e AnyMap (`apex_application_page_flash5_s`) que ele consultava.
**Correção:** em *Shared Components > Plug-ins > Source Display*, apague do PL/SQL o bloco `union all ... from apex_application_page_flash5_s ...` (linhas 35 a 48, filtro `'Flash Chart','Map'`) e clique *Apply Changes*.

Fonte: [Open Bugs and Known Issues](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/open-bugs-known-issues.html)

### Código jQuery antigo quebra (APIs do jQuery 1.x e 2.x removidas)
**Sintoma:** plug-in ou JS próprio dá erro de função inexistente do jQuery.
**Causa:** o jQuery 3.x quebra a compatibilidade com o 2.x; as APIs do 1.x não funcionam desde o 18.1. O 26.1 traz o jQuery 3.7.1.
**Correção:** para dependências do 2.x, ligue **Include jQuery Migrate** (*User Interface Details*). Ele também registra no console os usos deprecated. Para código 1.x, reescreva com APIs do jQuery 3.5+ (guias de migração em jquery.com).

Fonte: [Open Bugs and Known Issues](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/open-bugs-known-issues.html), [Upgrading Oracle APEX Applications](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/upgrading-apex-applications.html)

### "Internal ORDS OUT Bind limits exceeded" ao salvar Interactive Grid via REST Enabled SQL
**Sintoma:** o salvamento de um IG cuja fonte é REST Enabled SQL falha com "Internal ORDS OUT Bind limits exceeded".
**Causa:** o REST Enabled SQL do ORDS aceita no máximo 1000 bind variables por requisição, e o DML do IG mandou mais de 1000 valores de coluna.
**Correção:** reduza a quantidade de linhas por salvamento (salve em lotes menores).

Fonte: [Open Bugs and Known Issues](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/open-bugs-known-issues.html)

### Page Designer preso em "Group by Component Type"
**Sintoma:** o Page Designer fica no modo "Group by Component Type" sem opção para voltar a "Sort by Processing Order".
**Causa:** essas duas opções foram removidas da UI, e quem tinha a preferência gravada ficou preso.
**Correção:** com o Page Designer aberto, rode no console do navegador `pageDesigner.saveBoolPref("GROUP_BY_COMPONENT_TYPE", true);` (é o comando exato publicado na doc) e recarregue a página.

Fonte: [Open Bugs and Known Issues](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/open-bugs-known-issues.html)

### Data Generator: Percent Blank 100, min/max ignorados, preview e linha extra
**Sintoma:** na API do Data Generator: Percent Blank = 100 é rejeitado; alguns built-ins numéricos ignoram mínimo, máximo e precisão; o preview omite colunas com todos os valores nulos; com escala de linhas diferente de 1x, às vezes sai uma linha a mais.
**Causa:** bugs conhecidos, com correção prevista.
**Correção / workaround:** use Percent Blank ≤ 99, valide faixas numéricas depois de gerar e confira a contagem de linhas.

Fonte: [Open Bugs and Known Issues](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/open-bugs-known-issues.html)

---

## 9. Fixed Bugs do 26.1 (destaques por área)

### Bugs corrigidos no 26.1: Interactive Grid
- 34240318: linha de agregação no meio de resultados duplicados com mais de 300 linhas.
- 35154221: Copy Down falhava com paginação virtual.
- 35195398: registros duplicados ao inserir e rolar.
- 37288044: `aria-sort` no elemento errado.
- 37513080: download de colunas ocultas com cabeçalho.
- 37940390: `Cmd+A` no Mac não selecionava tudo.
- 38526099: **ORA-06502 ao salvar com PK maior que 255 bytes**.
- 38608644: PK com apóstrofo quebrava a paginação "page".
- 38612773: control break na primeira coluna faltava no download.
- 37708452: LOV baseada em REST com display igual ao return gerava ORA-904.

Fonte: [Fixed Bugs](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/fixed-bugs.html)

### Bugs corrigidos no 26.1: Interactive Report, Faceted Search e Smart Filters
- 36682228: menu Actions de IR na Global Page não funcionava.
- 37168162: erro JS ao editar filtros (regressão).
- 37757471: nomes vazios de colunas computadas no diálogo Group By.
- 37876867: aliases de coluna se esgotavam depois de "ZZ".
- 37929283: `JSON.parse` ao clicar no cabeçalho.
- 38228343: checkbox de relatório público não retido em outra sessão.
- 38337275: help text de coluna sem substituições.
- 38586509: botão Reset de Select Columns (regressão).
- 38190784: `APEX_IR.CLONE_REPORT` de outro dono.
- 37083384, 37257902, 37666796, 37802497, 38875427: problemas de exibição de sugestões, contagem com TIMESTAMP LTZ, Smart Filters na P0 que não atualizavam a região, Range múltiplo e Range com máscara de TIMESTAMP.

Fonte: [Fixed Bugs](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/fixed-bugs.html)

### Bugs corrigidos no 26.1: itens, formulários e Dynamic Actions
- 36918922: Clear não limpava File Upload.
- 37142461: Enter num text field limpava File Upload (desde 23.2).
- 37090926: Radio Group read-only sem a interface de item.
- 37527981: Number Field com format mask sempre acusava alteração.
- 37698174: FM não tirava os zeros à direita.
- 37581734: Set Focus em Password ignorado.
- 37655755: **Switch não aceitava valor Off nulo**.
- 37988882: Radio Group piscando e com problemas de null.
- 38140845: HTML Expression com `&FIRST_NAME` falhava.
- 38469361: Percent Graph sem `setValue` e refresh.
- 36999905: local do erro de Value Required.
- 38180681: *Initialization JavaScript Function* de DA não era copiada.
- 37216757: Geolocation DA com TypeError.
- 36733038: submit falhava com surrogate pairs (emoji).

Fonte: [Fixed Bugs](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/fixed-bugs.html)

### Bugs corrigidos no 26.1: Copy Page, Working Copy e Page Designer
- Copy Page:
  - 37299821 e FR-4107: não renomeava itens no JS da página;
  - 37923627 e FR-4396: não ajustava *Page Items to Submit*;
  - 38572261, 38583577, 38603247, 38630132: slots de Smart Filter, região mestre aninhada, referência de botão em sub-região e master-detail em IG;
  - 37564250: não copiava Data Load Definitions referenciadas;
  - 37715883: página com plug-in copiada para outra app quebrava o Page Designer;
  - 37238979: elementos comentados se perdiam.
- Working Copy:
  - 37272154: falso diff de ordem de itens;
  - 37324711: relatórios públicos de IR não copiados;
  - 38640055: auditoria;
  - 37716524: nome com mais de 250 caracteres.
- Page Designer:
  - 37038902: NO_DATA_FOUND ao copiar componente não salvo;
  - 37583433: copiar processos para página bloqueada.

Fonte: [Fixed Bugs](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/fixed-bugs.html)

### Bugs corrigidos no 26.1: tema, templates e Template Components
- 35136489: o Save do Theme Roller não ativava com CSS customizado.
- 34993208: File URLs de theme style geravam erro no console.
- 36460433: CSS inline em File URLs **deslogava do Builder** ao rodar a página.
- 37131653: alinhamento do Single Row View do IG no **Redwood Light**.
- 37593353: refresh do UT alterava colunas de auditoria.
- 37710307, 37716993: subscription do tema com templates customizados; Action Template de Template Component perdido no refresh.
- 37253653: default slots de Template Component em regiões.
- 36109782: botão de Content Row com alias `MENU_ID`.
- 36289704: dois underscores ou hífens no Static ID de Menu Popup quebravam o evento Dialog Closed.
- 37943994: erro JS com Content Row vazio.
- 38851637: barra de rolagem piscando ao carregar páginas.

Fonte: [Fixed Bugs](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/fixed-bugs.html)

### Bugs corrigidos no 26.1: sessão, segurança, autenticação e URLs
- 34456483: o fuso automático só detectava o offset (agora usa o nome; ver §4).
- 31950152 e 32788170: Social Sign-In com *Token Authentication Method* e refresh token.
- 35219456: Friendly URLs perdiam o context root.
- 37369199: endpoint REST Enabled SQL com barra final quebrava OAuth2.
- 37447990: log da URL ofensora em erros de "Valid for URL".
- 38343690: SSO no workspace pedia credenciais DBA.
- 38626188: `APEX_PUBLIC_USER` criado bloqueado pelo `apexins`.
- 38912513: a página não rolava depois de fechar o diálogo de sessão expirada.
- 39032410: redirect SAML com "!!".

Fonte: [Fixed Bugs](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/fixed-bugs.html)

### Bugs corrigidos no 26.1: APIs PL/SQL, dados, REST e export
- 37282977: `APEX_EXPORT` ignorava `p_csv_enclosed_by`.
- 37644004: CSV com LF em vez de CRLF.
- 37466556 e 38775084: limite de 32K e erro no XLSX.
- 37727402: `APEX_DATA_PARSER` incompleto com `p_skip_rows`.
- 38172429: `APEX_UTIL.GET_SINCE` com `NLS_COMP=LINGUISTIC`.
- 37784974: `APEX_COLLECTION` gravava debug demais.
- 37788910: text message com `%0` repetido.
- 37242841: `APEX_WEB_SERVICE` ignorava o proxy em redirect 302.
- 37606953: form sobre REST com coluna array dava ORA-904.
- 37895242: ORA-06592 em REST Sync com BLOB.
- 37991275 e 37991284: Data Load ignorava o parsing schema dinâmico.
- 38596562: erros de data loading não interceptáveis.
- 38484067: `APEX_AUTOMATION.LOG_*` sem efeito em Init, Before Rows e Cleanup.
- 37509075: logs de console do MLE fora do debug.
- 38672060: Document Generator convertia null em NBSP.
- 37650868: ORA-20409 BucketAlreadyExists.

Fonte: [Fixed Bugs](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/fixed-bugs.html)

### Bugs corrigidos no 26.1: Workflow, Human Task e Automations
- 35754407: o título do workflow agora pode usar colunas da source query.
- 37121256 e 38090832: import com replace quebrava a FK ou apagava instâncias.
- 37217671: NO_DATA_FOUND ao salvar IG cujo processo inicia workflow.
- 37222694: task vencida falhava o workflow mesmo com expiração None.
- 38235929 e 38237073: Case/Switch.
- 38739205: workflow chamado com parâmetro OUT ignorado.
- 39136581: diagrama não destacava os links concluídos.
- 37557733: o business admin não conseguia mudar o prazo de task criada por workflow.
- 38154463: `APEX$TASK_STATE` inesperado no handler de expiração.
- 38686098: view purgeable de `APEX_TASK_PARTICIPANTS`.
- 38085222: logs de automation não correlacionáveis depois do redeploy.

Fonte: [Fixed Bugs](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/fixed-bugs.html)

### Bugs corrigidos no 26.1: instalação, administração e acessibilidade
- 35993092: instalação em tablespace de bloco 4K.
- 37634913: upgrade direto 18.1 → 24.2 com FK da app 8842.
- 37859145: push notifications durante a fase 2 do upgrade.
- 37466233 e 38623845: `APEX_INSTANCE_ADMIN` com `LOGIN_MESSAGE` e wallet `system:`.
- 38888483: e-mail de notificação da instância.
- 38999603: ID de workspace de 17 dígitos estourava a precisão do JS.
- 38953322: comentário de app com 32768 caracteres dava ORA-06502.
- Acessibilidade: 32085649 (rótulo de obrigatório para leitor de tela), 36920726 (alvo da Star Rating), 37185033 (`aria-roledescription` depois de PPR), 37133718 (`aria-haspopup`), 37691881 (cálculo de contraste).

Fonte: [Fixed Bugs](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/fixed-bugs.html)

---

## 10. Ideas App: pedidos da comunidade entregues no 26.1

### Pedidos do APEX Ideas App (FR-xxxx) entregues no 26.1, por tema
O 26.1 lista cerca de 90 Feature Requests entregues ou corrigidos. Os mais úteis para desenvolvimento:

| Tema | FRs | Onde está |
|---|---|---|
| Quick Pick dinâmico | FR-1470, 2017, 2271, 3053 | Quick Pick Enhancements |
| CSS Class em coluna de IR; seleção de linhas no IR; IR com linha > 32K | FR-1590/1952; FR-2126; FR-2307/4096 | Interactive Report Enhancements; Output Limit Removed |
| DAs em ações de Cards; split/menu buttons; badge em botão | FR-1983; FR-2039; FR-2287/4160 | Trigger Actions; Declarative Menu Buttons; UT |
| Run de modal e Global Page | FR-2063, FR-2072 | Run Applications from Modal Dialog |
| OAuth2 Password Flow e Refresh Token | FR-2079, FR-3718 | OAuth2 Enhancements |
| Colar do Excel no IG; copiar coluna Display Only | FR-2479; FR-2251 | Copy and Paste for IG |
| DAs de mensagem de sucesso e erro; spinner no Execute Server-side Code | FR-2573; FR-2426 | New Dynamic Actions; Show Processing |
| Static ID em Authorization Schemes, List Entries e REST Sources | FR-2874/3736, FR-4154 | Static ID Added |
| Infinite scroll em LOVs | FR-3108 | Infinite Scroll |
| Workflow paralelo; retomar depois do deploy; reset de prazo | FR-3536/3952; FR-4182; FR-4292 | Workflow Enhancements |
| BOOLEAN em `apex_exec.add_parameter` e em template directives | FR-3741; FR-4506 | Session State BOOLEAN |
| AI Agents e tools; mais provedores; gerar página com IA | FR-3873, 4523/4796, 4664; FR-4688; FR-4213, 4556/4598 | AI Agent Tools; Providers; Create Page Using NL |
| SMTP por workspace | FR-4024 | SMTP Credentials at Workspace Level |
| PDF com senha | FR-4090 | Document Generator |
| Blank Page, drawer page, ícones em tabs | FR-4164, FR-4152, FR-4053 | UT Enhancements |
| Bloquear o merge de Working Copy sem aprovação | FR-4603 | Application Lock |
| `apex_mail` sem cabeçalho Date | FR-4179 | Corrigido |
| Esconder "Set Time Zone" com Automatic Time Zone | FR-4644 | Corrigido |

Fonte: [Ideas App Implementations](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/ideas-app.html)

---

## 11. Privacidade: logs, cookies e storage usados pelo APEX

### Logs de eventos, cookies e chaves de Session/Local Storage que o APEX usa
- **Logs**:
  - Activity Log: page views e Ajax; pode ser desligado pelo desenvolvedor ou pela instância;
  - Login Access Log;
  - Debug Log: desligado por padrão;
  - Click Count Log: cliques em links externos;
  - Web Service Activity Log;
  - Developer Activity Log;
  - SQL Workshop Log.
  - Guardam IP e usuário.
- **Cookies de sessão** (funcionais, sem rastreamento, sem terceiros):
  - `ORA_WWV_USER_<instance id>`: Builder e apps internas;
  - `ORA_WWV_APP_<app id>`: apps; o nome pode ser customizado no authentication scheme;
  - `ORA_WWV_RAC_INSTANCE`: só em RAC.
- **Cookies persistentes**:
  - `ORA_WWV_REMEMBER_LANG`;
  - `ORA_WWV_REMEMBER_UN`: opcional, no login do Builder;
  - `LOGIN_USERNAME_COOKIE`: opcional, nos logins das apps, controlado por "Remember username" com `APEX_AUTHENTICATION.GET_LOGIN_USERNAME_COOKIE` e `SEND_LOGIN_USERNAME_COOKIE`.
- **Session Storage** (prefixo `ORA_WWV_apex.`): estado do Object Browser, posição e zoom do mapa, facetas (visibilidade, gráficos, colapso), tamanho do Popup LOV, aba ativa de Region Display Selector e Tabs, última visão do Calendar, regiões colapsáveis, splitters do IG, preferências do Development Toolbar e do Page Designer, `core.userHasTouched`.

Fonte: [Privacy Notice](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/privacy-notice.html)

---

## 12. Checklist para agentes

### O que evitar no APEX 26.1 (APIs e recursos deprecated ou desupported)
- **PL/SQL**: `APEX_UTIL.STRING_TO_TABLE`, `TABLE_TO_STRING`, `URL_ENCODE`, `PUBLIC_CHECK_AUTHORIZATION`, `RESET_AUTHORIZATIONS`, `IR_*`, `CACHE_GET_DATE_OF_*`, `PURGE_REGIONS_BY_*`, `SET/GET_BUILD_OPTION_STATUS`, `SET/GET_APPLICATION_STATUS`, `SET/GET_GLOBAL_NOTIFICATION`, `SET_APP_BUILD_STATUS`, `CUSTOM_CALENDAR`, `INCREMENT_CALENDAR`, `SET_CURRENT_THEME_STYLE`; `APEX_LANG.MESSAGE`; `APEX_CUSTOM_AUTH.LOGOUT`; `APEX_DEBUG.LOG_MESSAGE`; `APEX_IR.GET_REPORT`; `APEX_APPROVAL.*`; `APEX_AUTOMATION.ABORT`; `APEX_BACKGROUND_PROCESS.ABORT`; `APEX_EXEC.*WEB_SOURCE*`; `APEX_IG.ADD_FILTER` Sig. 2; `APEX_ZIP.GET_FILES`; `APEX_PAGE.GET_UI_TYPE`/`IS_DESKTOP_UI`; `APEX_PLUGIN_UTIL.EXECUTE_PLSQL_CODE`, `PRINT_DISPLAY_ONLY`, `PAGE_ITEM_NAMES_TO_JQUERY`, `GET_POSITION_IN_LIST`, `DEBUG_PAGE_ITEM`; `APEX_PLUGIN.GET_INPUT_NAME_FOR_PAGE_ITEM`; `APEX_AI.CHAT/GENERATE` com `p_config_static_id`; `APEX_WEB_SERVICE.OAUTH_AUTHENTICATE` Sig. 2; `apex_javascript/apex_css.add_3rd_party_library_file` (desupported).
- **Dicionário**: `attribute_01..25` (retornam null); `STATIC_ID` de regiões, botões e colunas; `apex_appl_ai_configs`; `ai_config_*`; `COMPONENT_SIGNATURE`.
- **Substituições**: `#REGION_STATIC_ID#`, `#BUTTON_ID#`, `APP_REGION_STATIC_ID`; `#WORKSPACE_IMAGES#` para arquivos da app.
- **JavaScript**: `config.regionStaticId` e `staticId` (**já quebrados**); `apex.util.invokeAfterPaint`/`cancelInvokeAfterPaint`; `grid.getSelectedRange`; `apex.widget.initPageItem`; `async` em `apex.server.*`; passar elemento DOM a `apex.item`; `pHideRow`/`pShowRow`; jQuery UI; APIs do jQuery 1.x e 2.x; markup e classes internas de itens.
- **Componentes**: Legacy Calendar (quebra o export APEXlang); jQuery Date Picker; DA Page Unload; Display Only "HTML (Unsafe)"; escape manual em LOV; Web Service References legados; RESTful Services pelo SQL Workshop; Export Repository; switch *Substitute Attribute Values*; *JavaScript Static ID* de gráficos JET; modelos Cohere antigos.
- **Processo**: não importe single page ou component export de versão anterior ao 26.1 (não funciona); não importe APEXlang numa Working Copy; não troque o Static ID de componente em uso; não compare `APEX_WORKSPACE_SESSIONS` com `SYSDATE`; não espere que `{if X/}` trate "FALSE" como verdadeiro.

Fonte: [Deprecated Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/deprecated-features.html), [Deprecated in Previous Releases](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/deprecated-previous-releases.html), [Desupported Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/desupported-features.html), [Changed Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html)

### O que preferir no APEX 26.1
- **Strings e listas**: `APEX_STRING.STRING_TO_TABLE`/`JOIN`/`JOIN_CLOB`; URL encoding com `UTL_URL.ESCAPE`.
- **Autorização**: `APEX_AUTHORIZATION.IS_AUTHORIZED` (nome) ou `HAS_ACCESS` (Static ID), e `APEX_AUTHORIZATION.RESET_CACHE`.
- **Mensagens e debug**: `APEX_LANG.GET_MESSAGE` (parâmetros nomeados, fallback para o idioma primário); `APEX_DEBUG.INFO`/`WARN`/`ERROR`/`TRACE`/`ENTER`.
- **Logout**: `APEX_AUTHENTICATION.LOGOUT`.
- **Administração de app**: `APEX_APPLICATION_ADMIN` (build options, status, global notification).
- **Dados de relatório**: `APEX_REGION.OPEN_QUERY_CONTEXT`; `APEX_EXEC.*REST_SOURCE*`; `APEX_IR.*` e `APEX_IG.ADD_FILTER` Sig. 3 em processos de submit.
- **Tarefas**: `APEX_HUMAN_TASK`; `TERMINATE` em `APEX_AUTOMATION` e `APEX_BACKGROUND_PROCESS`.
- **IA**: AI Agents com `p_agent_static_id`; tools On Demand em vez de RAG; Response Format JSON com schema estrito; Max AI Tokens.
- **Dicionário**: coluna JSON `attributes` (com alias); `HTML_DOM_ID`; `apex_appl_ai_agents`.
- **Substituições e JS**: `#DOM_ID#` e `APP_REGION_DOM_ID`; `regionDomId`/`domId`; `requestAnimationFrame`; `grid.getSelectedRanges`; `apex.item(...)` para tudo de item.
- **Declarativo antes de JS**: DAs Show Success Message, Show Error Message e Clear Errors; Trigger Actions; Show Processing; Declarative Menu Buttons; CSS Classes em coluna de IR.
- **CSP**: sem inline (`style=""`, `onclick`, `onerror`, `javascript:`); use classes, `#APEX_CSP_NONCE_ATTRIBUTE#` e `#APEX_CSP_DISPLAY_NONE#`; teste com `Content-Security-Policy-Report-Only`.
- **Ciclo de vida**: export **Standard** em APEXlang para controle de versão, **Runtime** para produção; Static IDs estáveis; Application Lock quando o fonte de verdade for o APEXlang; depois de cada upgrade, Advisor, Refresh Theme, Compatibility Mode e Upgrade Application.
- **Time zone**: espere nomes de fuso em `SESSIONTIMEZONE`; compare timeouts de sessão em UTC.

Fonte: [Deprecated Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/deprecated-features.html), [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html), [Upgrading Oracle APEX Applications](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/upgrading-apex-applications.html), [Using Content Security Policy (CSP) in APEX](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-csp-in-apex.html)

### Consultas de auditoria pós-upgrade para o 26.1 (rodar no workspace)
```sql
-- DAs com evento unload (agora pagehide)
select application_id, page_id, dynamic_action_name
  from apex_application_page_da where when_event_internal_name = 'unload';

-- LOVs com escape manual (risco de escape duplo no futuro)
select application_id, list_of_values_name from apex_application_lovs
 where lov_type = 'Dynamic'
   and regexp_like(upper(list_of_values_query), 'HTF\.ESCAPE_SC|APEX_ESCAPE\.HTML|WWV_FLOW_ESCAPE\.HTML');

-- Regiões: html_dom_id em vez de static_id
select application_id, page_id, region_name, html_dom_id
  from apex_application_page_regions where application_id = :APP_ID;

-- Papéis ACL com Static ID em minúsculas (known issue)
select application_id, role_static_id, role_name
  from apex_appl_acl_roles where role_static_id <> upper(role_static_id);
```
Também: rode o **APEX Advisor** (*Utilities > Advisor*) e veja a região **New Features Available** no Application Home.

Fonte: [Changed Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html), [Deprecated in Previous Releases](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/deprecated-previous-releases.html), [Open Bugs and Known Issues](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/open-bugs-known-issues.html)

---

## 13. Aplicação no Corlix Hub

> Varredura feita em 21/10/2026 sobre `corlixhub/**/*.apx`, `corlixhub/shared-components/static-files/*` e `modulos/**` (SQL, packages e JS; arquivos `.min.*` e `.md` ignorados).
> Busca por: `APEX_ITEM`, `htmldb_`, `wwv_flow_` em código, APIs `APEX_UTIL` deprecated, `APEX_LANG.MESSAGE`, `APEX_CUSTOM_AUTH.LOGOUT`, `APEX_DEBUG.LOG_MESSAGE`, `APEX_IR.GET_REPORT`, `APEX_PLUGIN_UTIL` deprecated, `APEX_PAGE.GET_UI_TYPE`, `*WEB_SOURCE*`, `APEX_APPROVAL`, `add_3rd_party_library_file`, `p_config_static_id`, `#REGION_STATIC_ID#`, `#BUTTON_ID#`, `APP_REGION_STATIC_ID`, `regionStaticId`, `invokeAfterPaint`, `getSelectedRange`, `apex.widget.initPageItem`, `async:false`, jQuery UI (`.dialog(`, `.sortable(`…), eventos `unload`, Display Only HTML, Legacy Calendar.

### Resultado da varredura: nenhuma API PL/SQL ou JS deprecated em uso no Corlix Hub
- **Nenhuma ocorrência** de `APEX_ITEM`, `htmldb_`, APIs `APEX_UTIL` deprecated, `APEX_LANG.MESSAGE`, `APEX_DEBUG.LOG_MESSAGE`, `APEX_CUSTOM_AUTH.LOGOUT`, `APEX_IR.GET_REPORT`, `APEX_APPROVAL`, `*WEB_SOURCE*`, `regionStaticId`, `invokeAfterPaint`, jQuery UI, DA *Page Unload*, Display Only com HTML, Legacy Calendar, nem das substituições `#REGION_STATIC_ID#`, `#BUTTON_ID#` e `APP_REGION_STATIC_ID`.
- As únicas menções a `WWV_FLOW_` estão em **documentação de erro**, não em código: `modulos/perfis-acesso/Etapas-perfis-acesso.md:328`, `:402` e `modulos/perfis-acesso/Registro-implantacao.md:37` (texto do `ORA-01403` em `WWV_FLOW_ACL_API`).
- APIs `APEX_UTIL` em uso, **nenhuma deprecated** no 26.1:
  - `apex_util.prn` em `corlixhub/pages/p00003-organograma.apx:406`;
  - `apex_util.get_session_state` em `modulos/historico-carreira/04_pkg_historico_carreira.pkb:141`;
  - `apex_util.create_user`, usado 3 vezes (cadastro de usuários).
- O projeto já usa as alternativas recomendadas:
  - `apex_authorization.is_authorized` (substituta de `PUBLIC_CHECK_AUTHORIZATION`), em `corlixhub/shared-components/authorizations.apx`, authorization `colaborador`;
  - `apex_page.get_url` (regra 4 do `ai-context`);
  - `apex_string.push`;
  - `apex_escape.html`/`html_attribute` em **HTML gerado**, não em queries de LOV, então não há risco de escape duplo (`modulos/organograma/organograma.sql:114`, `:119`; `modulos/historico-carreira/08_pkg_historico_carreira_ui.sql:172`, `:177`; `corlixhub/pages/p00004-chat.apx:575`).
- **Trigger Actions** (novidade do 26.1) já aparecem 4 vezes nas páginas (`type: triggerAction`), e o tema está em `baseTheme: ut-26.1` com `filePrefix: #APEX_FILES#themes/theme_42/26.1/` (`corlixhub/shared-components/themes/universal-theme/theme.apx:4`, `:53`). O UT está atualizado; não é preciso Refresh Theme.
- Todas as páginas definem `pageTemplate` explícito (ex.: `pageTemplate: @corlix-standard-page` em `corlixhub/pages/p00001-início.apx:6`), compatível com o fim da opção "Default Template" no 26.1.

Fonte: [Deprecated Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/deprecated-features.html), [Deprecated in Previous Releases](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/deprecated-previous-releases.html), [Changed Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html)

### Corlix Hub: papéis ACL com Static ID em minúsculas × known issue do APEX_ACL
- `corlixhub/shared-components/acl-roles.apx` define os roles `admin-rh`, `colaborador`, `diretoria`, `equipe-do-corlix-hub`, `gestor` e `publicador-de-conteúdo`, todos com Static ID **em minúsculas** e com hífen. O `modulos/perfis-acesso/Etapas-perfis-acesso.md:50` manda digitá-los assim, e a tabela `CARGO_PAPEL.CD_PAPEL` guarda esses valores (`modulos/perfis-acesso/01_ddl_cargo_papel.sql:21`).
- `modulos/perfis-acesso/03_pkg_perfis_acesso.sql:77-84` chama `apex_acl.has_user_role(p_role_static_id => ...)` e `apex_acl.add_user_role(...)` com esses Static IDs.
- **Known issue 10.4 das Release Notes**: depois de criar um role, troque o Static ID gerado em minúsculas para **maiúsculas**, para que a checagem de papel via `APEX_ACL` avalie corretamente. O texto oficial cita `apex_acl.user_has_role`, nome que não existe na API Reference; a função equivalente é `HAS_USER_ROLE`.
- **Divergência a registrar, sem alterar nada agora**: o `ai-context/03` §2.1 e o guia de perfis de acesso padronizam minúsculas, e o `Registro-implantacao.md` registra a implantação funcionando. As authorizations do projeto são `isInRoleOrGroup` por **nome** do role (`Admin RH`, `Equipe do Corlix Hub`…), então não usam o Static ID. O risco está só no `pkg_perfis_acesso`.
- **Recomendação**: se `has_user_role` retornar `false` para quem tem o papel (o que geraria `add_user_role` repetido ou erro), padronize os Static IDs em MAIÚSCULAS no Builder **e** em `CARGO_PAPEL`/`02_seed_departamentos_cargos.sql` ao mesmo tempo. Antes, combine com o time e atualize o `ai-context/03` e o guia. Para diagnosticar: `select role_static_id from apex_appl_acl_roles where application_id = 100;`.

Fonte: [Open Bugs and Known Issues](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/open-bugs-known-issues.html), [HAS_USER_ROLE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/HAS_USER_ROLE-Function.html)

### Corlix Hub: código inline que impede CSP estrito (onclick, onerror, style, javascript:)
O núcleo do APEX 26.1 já funciona sem `unsafe-inline` e sem `unsafe-hashes`, mas o código do projeto ainda tem handlers e estilos inline. Se um dia a app ativar `Content-Security-Policy` estrito, estes pontos serão bloqueados:

| Arquivo:linha | Construção | Alternativa |
|---|---|---|
| `corlixhub/pages/p00000-global-page.apx:55` | `<img ... onerror="this.onerror=null; this.style.display...">` (avatar do header) | Tratar o erro de imagem num JS de static file (listener de `error`) |
| `corlixhub/pages/p00000-global-page.apx:56` | `<span ... style="display:none">` (iniciais) | Classe CSS, ou `#APEX_CSP_DISPLAY_NONE#` |
| `modulos/organograma/organograma.sql:229` | `<img ... onerror="this.remove()">` | Listener em `organograma.js` |
| `corlixhub/shared-components/themes/universal-theme/classic-report-templates/chat-contatos.apx:13` | `href="javascript:void(0)"` | `<button>` ou `href="#"` com handler em JS |
| `corlixhub/shared-components/themes/universal-theme/classic-report-templates/chat-contatos.apx:15` | `<img ... onerror="this.remove()">` sobre as iniciais | Idem ao avatar |
| `modulos/historico-carreira/08_pkg_historico_carreira_ui.sql:637`, `:641`, `:653`, `:658` | `style="flex-grow:..."` e `style="left:..%"` calculados (faixa do histórico) | Variáveis CSS com nonce, ou definir os valores via JS (`element.style`) |
| `corlixhub/shared-components/themes/universal-theme/button-templates/html-button-legacy-apex-5-migration.apx:5-6` | Template "HTML button (legacy - APEX 5 migration)" com `onclick="#JAVASCRIPT#"` | Não está referenciado por nenhuma página (grep sem ocorrências); candidato a remoção. Prefira o template `@/text` do UT |

Não é bug hoje, porque a app não define header CSP (nenhuma ocorrência em `application.apx`). Antes de ativar CSP, teste com `Content-Security-Policy-Report-Only`.

Fonte: [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html), [Using Content Security Policy (CSP) in APEX](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-csp-in-apex.html)

### Corlix Hub: versão do ORDS registrada (25.4) × requisito do APEX 26.1 (26.1.1+)
- `docs/ai-context/01-arquitetura-e-ambiente.md:19` registra **ORDS 25.4.0**. As Release Notes e o Installation Guide do 26.1 exigem **ORDS 26.1.1 ou posterior**.
- **Divergência explícita**: ou o ambiente foi atualizado e o `ai-context/01` está desatualizado, ou o APEX 26.1.5 está rodando num ORDS fora do requisito oficial. Confirme com *Help > About > CGI Environment > `APEX_LISTENER_VERSION`* e pergunte ao time antes de concluir (regra 6 do `ai-context`: o ambiente atual não está confirmado).
- Banco: `23.26.1.0` (Oracle AI Database 26ai Free), que atende o mínimo `23.26.0`. Como o banco é 26ai, ficam disponíveis o session state **BOOLEAN** em Checkbox, Switch e Hidden, a validação de JSON Schema da saída de IA e o Describe Tables / `APEX_DB_DICTIONARY`.

Fonte: [About These Release Notes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/about-release-notes.html), [Oracle APEX Installation Requirements](https://docs.oracle.com/en/database/oracle/apex/26.1/htmig/apex-installation-requirements.html)

### Corlix Hub: APEXlang, Static IDs com acento, deployments/default.json e mudanças a observar
- O fonte da app já está em **APEXlang** (`corlixhub/`, 47 `.apx`), com `corlixhub/deployments/default.json` contendo só `{"app": {"id": 100}}`. Não há subscriptions, então os known issues de mapeamento de master app não se aplicam hoje.
- **Import APEXlang é sempre da app inteira** e exige um schema REST-enabled no workspace. Para mexer numa única página no ambiente, é preciso importar a app toda; o import de página isolada só existe em SQL (e só de exports do 26.1).
- **Não troque Static IDs existentes** (ex.: `admin-rh`, `@corlix-standard-page`): no APEXlang eles são as referências `@...` entre arquivos e a base do diff. O `ai-context/08` §3 já aponta que Static IDs com acento (`publicador-de-conteúdo`, `histórico-de-carreira`) são frágeis; o 26.1 reforça que mudá-los quebra referências e diffs, então qualquer renomeação deve ser planejada.
- **Application Lock**: se o time decidir que o `.apx` é a fonte da verdade, travar a app no Builder impede edições "por fora" que divergem do Git (só APEXlang altera uma app travada).
- **LOV `BOOLEAN`** (`corlixhub/shared-components/lovs.apx:1`): é a LOV estática Yes/No que o 26.1 gera para colunas BOOLEAN em relatórios. O `ai-context/08` §3 (Configuração) registra que ela mostra "Yes/No"; para pt-BR, traduza as entradas ou use uma LOV própria.
- **Text messages**: se o projeto usar text messages em pt-BR com idioma primário `en`, lembre que no 26.1 a falta de tradução cai para o idioma primário.
- **Novidades com aplicação direta** nas páginas que usam JS para mensagens (ex.: `apex.message.showErrors` em `corlixhub/pages/p00016-cadastro-de-empresas.apx:772`): as DAs *Show Error Message*/*Show Success Message* resolvem casos simples sem JS. O código atual não usa `regionStaticId`, então não foi afetado pela renomeação.

Fonte: [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html), [Changed Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html), [Open Bugs and Known Issues](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/open-bugs-known-issues.html)
