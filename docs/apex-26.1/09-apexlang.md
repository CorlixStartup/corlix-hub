# 09 · APEXlang: sintaxe e referência dos componentes (.apx)

> Base: documentação oficial Oracle APEX 26.1 (APEXlang API Reference/apxln, com a gramática `apexlang.ebnf`; Developer's Companion/apxdc: *Working with APEXlang* e *Understanding Application Lifecycle*; App Builder User's Guide/htmdb: *Creating an Application with APEXlang*, *Deploying an Application* e Apêndice C *Directory Structure When Splitting Export Files into Separate Scripts*; Administration Guide/aeadm: *Exporting and Importing Using SQLcl*; Release Notes/htmrn: *New Features*, *Changed Behavior*, *Deprecated Features*, *Open Bugs and Known Issues*; pontualmente aexjs `apex.server` e aeapi `APEX_ESCAPE`). Gerado em 21/10/2026.

**Sumário**
1. O que é APEXlang e onde ele aparece · 2. Gramática e sintaxe · 3. Estrutura de diretórios do export · 4. Exportar, importar e validar (e casos de erro) · 5. Blocos reutilizados (condições, layout, aparência, segurança) · 6. Referência: `app`, `page`, `pageGroup`, `metaTag` · 7. Referência: `region` e cada tipo de região · 8. Referência: itens, botões, processos, validações, computações, branches e Dynamic Actions · 9. Referência: shared components, tema e templates · 10. Pegadinhas · 11. Aplicação no Corlix Hub

**Como ler as tabelas de referência.** A APEXlang API Reference descreve cada componente com *propriedades diretas*, *grupos de propriedades* e *filhos*. Nas tabelas abaixo: **Obrig.** = obrigatório quando a propriedade se aplica; **Padrão** = valor assumido quando a propriedade é omitida; "aplica-se quando" resume a condição *Applies when* da referência (o compilador só aceita a propriedade nesse contexto). Listas de enum longas foram cortadas só quando indicado. Nada aqui substitui o `apex validate`: na dúvida, valide.

**Convenção.** Nomes de componentes, grupos, propriedades e valores ficam exatamente como no APEXlang (camelCase, em inglês). Quando um fato vem só da observação dos arquivos deste repositório (e não da doc), o texto diz "observado no export".

---

## 1. O que é APEXlang e onde ele aparece

### APEXlang: o que é, para que serve e quando usar
APEXlang é a representação textual, legível e **editável** de uma aplicação APEX, introduzida no 26.1. A app continua morando como metadados no banco; o APEXlang é um formato de export/import em arquivos `.apx` (um por página e por grupo de shared components) que pode ser revisado, editado à mão, validado, versionado no Git e importado de volta.

Por que existe: antes, o export SQL servia para source control, mas descrevia a app como chamadas de API internas com IDs numéricos; o YAML legível ajudava a revisar diffs, mas não podia ser importado. O APEXlang junta as duas coisas: é legível e importável. SQLcl, ORDS e SQL Developer for VS Code usam o **mesmo compilador APEXlang**, com as mesmas regras que o Page Designer aplica, por isso a edição externa tem validação estrita, code completion e import/export integrados.

Quando usar:
- Edição em massa, revisão de código, diffs de Git e trabalho com agentes de IA.
- Resolver conflitos entre o App Builder e mudanças externas.
- Gerar páginas e componentes a partir de especificação (blueprints).

Quando não usar (ou com cuidado):
- Para importar uma **página isolada**: o import APEXlang é sempre da aplicação inteira (página isolada só no formato SQL).
- Para levar dados de runtime (relatórios salvos públicos/privados, assinaturas, instâncias de workflow/task): o export APEXlang do 26.1 não os inclui.

Fonte: [Working with APEXlang](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/working-apexlang.html), [Why APEXlang Matters](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/why-apexlang-matters.html), [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### APEXlang dentro do App Builder: APEXlang View e diffs de working copy
Mesmo quem só usa o navegador ganha com o APEXlang:
- No Page Designer, o menu **APEXlang View** abre um snapshot somente leitura da página atual em APEXlang, útil para revisar e pesquisar.
- Ao comparar uma working copy com a app principal (ou duas working copies), os diffs passam a ser exibidos em APEXlang, no lugar do YAML legível. Exemplo da doc: dá para ver que um `pageItem` mudou de `selectList` para `textField` e perdeu o grupo `lov`.

Dica para agentes: quando o usuário mandar print ou trecho do Page Designer, peça o **APEXlang View** da página; ele mostra exatamente o que o arquivo `.apx` deveria conter.

Fonte: [APEXlang Inside App Builder](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/apexlang-app-builder.html)

### APEXlang com agentes de IA: skills, validação e blueprints
A Oracle distribui *skills* de APEXlang para agentes (Claude, Codex e outros) no GitHub (`github.com/oracle/skills`), instaláveis/atualizáveis com o comando `skills sync` do SQLcl. O fluxo recomendado trata a validação como parte do ciclo de edição: alterar os `.apx` → rodar `apex validate` → revisar → importar só quando validar limpo.

O que um agente pode alterar via APEXlang (lista da doc, resumida): atributos da aplicação; páginas, diálogos, regiões, itens, botões e Dynamic Actions; Supporting Objects; shared components (temas, templates, listas, navegação, authorization e authentication schemes); regras, computações, condições e validações; processos, workflows e automações; integrações (REST Data Sources, OData, AI Providers, Identity Providers); comentários e versões. Em resumo: tudo o que o App Builder expõe.

*Blueprints*: a partir de uma especificação funcional e de um modelo de dados, um agente usa o prompt de geração de blueprint da Oracle para produzir um plano em Markdown (páginas, navegação, relatórios, formulários, gráficos, filtros, ações). O App Builder importa esse blueprint e gera, de forma determinística, um app esqueleto com blocos APEXlang testados, que depois evolui no App Builder e com o agente.

Fonte: [Using APEXlang with AI Coding Agents](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-apexlang-coding-agents.html), [Creating an Application with APEXlang](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-an-application-with-APEXlang.html)

---

## 2. Gramática e sintaxe

### Estrutura de um arquivo .apx: componentes `tipo id ( … )` e grupos `grupo { … }`
Um arquivo `.apx` é uma sequência de declarações de componente. Cada componente tem a forma:

```
<tipo> [<identificador>] (
    <propriedade direta>: <valor>
    <grupo> {
        <propriedade>: <valor>
    }
    <componente filho> <id> (
        ...
    )
)
```

Regras da gramática oficial (`apexlang.ebnf`):
- **Componentes** abrem com `(` e fecham com `)`; **grupos de propriedades** abrem com `{` e fecham com `}`.
- A gramática é **orientada a linha**: cada declaração de componente, cada abertura de grupo, cada propriedade e cada delimitador de fechamento ocupa a própria linha. Não há `;` nem `,` entre propriedades.
- Propriedades são pares `nome: valor` (dois-pontos seguido de espaço).
- Dentro do corpo de um componente podem aparecer, em qualquer ordem, propriedades diretas, grupos e componentes filhos (no export real, grupos às vezes aparecem depois dos filhos; ex.: o grupo `page { … }` de impressão de um Interactive Report vem depois das colunas na p15).
- O identificador é opcional na gramática (`branch (`, `componentSetting (`, `supportingObject (` aparecem sem ele no export).
- Indentação não tem significado sintático (é só `<indent>` livre), mas o export usa 4 espaços por nível; mantenha.

Exemplo real (p16, simplificado):
```
page 16 (
    name: Cadastro de Empresas
    alias: CADASTRO-DE-EMPRESAS
    appearance {
        pageMode: modalDialog
        dialogTemplate: @/modal-dialog
        templateOptions: #DEFAULT#
    }

    region buttons (
        name: Buttons
        type: staticContent
        layout {
            sequence: 20
            slot: dialogFooter
        }
    )
)
```

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (gramática EBNF), [Reading APEXlang Syntax](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/reading-apexlang-syntax.html)

### Gramática EBNF oficial: tokens de valor (string, identifier, number, boolean, reference, multiline, array)
Produções principais do `apexlang.ebnf` (transcritas, são fatos da gramática):

| Produção | Definição | Observação |
|---|---|---|
| `<value>` | `<string> \| <identifier> \| <boolean> \| <number> \| <reference> \| <multiline-string> \| <array>` | Valor genérico |
| `<component-id>` | `<string> \| <identifier> \| <number>` | Identificador após o tipo |
| `<identifier>` | começa com `A-Z a-z 0-9 _`; continua com esses ou `.` `-` | Por isso `contato-e-endereco`, `P16_CEP`, `corlix-tema.css` não precisam de aspas |
| `<string>` | `"` … `"` com escapes `\"` `\\` `\/` `\b` `\f` `\n` `\r` `\t` `\uXXXX` | Use quando houver espaço ou caractere fora do identificador |
| `<multiline-string>` | ```` ``` ```` … ```` ``` ```` | Texto livre, várias linhas |
| `<reference>` | `@` seguido de caracteres de referência | Aponta para outro componente |
| `<boolean>` | `true \| false` | |
| `<number>` | `[-]` dígitos `[.` dígitos`]` | |
| `<array>` | `[` valores separados por espaço **ou** um por linha `]` | Ver seção de arrays |
| `<comment>` | `//` até o fim da linha, ou `/* … */` | |

Na prática, a maior parte dos valores escalares é escrita **sem aspas**, e o compilador interpreta pelo tipo da propriedade (texto, enum, número, booleano). Exemplos do export: `label: Salvar`, `errorMessage: Você só pode cadastrar colaboradores na sua empresa.`, `headerText: <h2 class="cx-titulo-secao">Configurações</h2>`. Aspas aparecem quando o identificador do componente tem espaço: `file "Fotos Colaboradores/aline_alves.jpg" (`.

Observado no export: identificadores com acentos (`region configurações`, `entry comunicação`, `validation empresa-do-usuário`) são aceitos pelo compilador, embora a produção `<identifier>` da EBNF só liste ASCII. Para componentes **novos**, prefira ASCII.

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (Download EBNF)

### Propriedades diretas e o grupo padrão (identification, label, entry, file…)
Cada componente tem um **grupo padrão** cujas propriedades podem ser escritas **sem o bloco de grupo**, direto no corpo do componente. Para 175 tipos o grupo padrão é `identification` (por isso `name:`, `alias:`, `title:`, `type:` aparecem soltos). Alguns tipos usam outro grupo padrão; a EBNF registra, entre outros: `label` (entry de list, classicNavigationBarEntry, facetGroup, filterGroup), `entry` (entry de LOV), `file` (static files), `heading`, `aggregate`, `condition`, `translation`, `layout`, `dbObject`, `component`, `config`, `comments`.

Consequência prática: na referência em HTML/MD, uma `entry` de lista mostra `label { label: … }`, mas no export ela aparece como `label: Cadastro de Usuários` direto. As duas formas descrevem a mesma propriedade; **siga a forma do export**.

Fonte: [Reading APEXlang Syntax](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/reading-apexlang-syntax.html), [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Defaults omitidos: propriedade ausente = valor padrão
Propriedades obrigatórias precisam de valor, mas **qualquer propriedade com valor padrão pode (e costuma) ser omitida**. O export não grava defaults. Consequências:
- Se uma propriedade não aparece no arquivo, ela está no default da referência (ex.: `page.navigation.warnOnUnsavedChanges` ausente = `true`; `region.edit.enabled` ausente = `false`).
- Para "desligar" algo cujo default é `true`, você precisa escrever o valor explicitamente (`fireOnInit: false`, `addBuiltWithApexToFooter: false`).
- Remover uma linha do `.apx` volta a propriedade ao default; não existe "valor vazio" diferente de ausência.
- Componentes inteiramente em default aparecem vazios: `appItem G_ID_EMPRESA (` + `)`.

Fonte: [Reading APEXlang Syntax](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/reading-apexlang-syntax.html)

### Arrays em APEXlang: um elemento por linha, colchetes opcionais com um elemento
Um array pode ser escrito em uma linha, separado por espaços, ou com um elemento por linha:

```
templateOptions: [
    #DEFAULT#
    t-Region--noUI
    t-Region--scrollBody
]
pages: [1, 2]
```

Regras e observações:
- A EBNF aceita separação por espaço/tab ou quebra de linha; o export sempre usa um elemento por linha.
- Com **um único elemento**, os colchetes podem ser omitidos (`templateOptions: #DEFAULT#`, `pages: 14`, `css { fileUrls: #THEME_FILES#css/Core#MIN#.css?v=#APEX_VERSION# }`). A própria doc mostra a remoção dos colchetes de um array de um elemento antes de importar.
- Cada **linha** é um elemento: uma template option composta como `t-Region--removeHeader js-removeLandmark` ocupa uma linha só e é um único valor (observado no export).
- Números em array de strings que poderiam ser lidos como número vão entre aspas no exemplo oficial (`includeLegacyJavascript: [ pre18 "18" ]`).

Fonte: [Reading APEXlang Syntax](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/reading-apexlang-syntax.html), [Editing APEXlang in Visual Studio Code](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/editing-apexlang-visual-studio-code.html), [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Strings multilinha e blocos de código cercados (sql, plsql, javascript-browser, javascript-mle, html, css, json)
Código e texto longo usam *fenced code blocks* com indicador de linguagem. A forma do export é: nome da propriedade com `:` no fim da linha, e o bloco cercado na linha seguinte, indentado um nível a mais:

````
source {
    sqlQuery:
        ```sql
        select empno, ename
          from emp
         where deptno = :P1_DEPTNO
        ```
}
````

Indicadores de linguagem documentados e usados:

| Indicador | Uso |
|---|---|
| `sql` | Queries, expressões SQL, where/order by |
| `plsql` | Blocos, expressões e function bodies PL/SQL |
| `javascript-browser` | JavaScript que roda no navegador (DAs, page load, init functions) |
| `javascript-mle` | JavaScript no servidor (MLE), propriedades `javaScriptExpression`/`javaScriptFunctionBody`/`javaScriptCode` |
| `html` | HTML (help text, HTML expressions, templates, headerText) |
| `css` | CSS inline |
| `json` | JSON (ex.: `jsonSchema`, `jsonConfig` de theme style) |

Regras práticas:
- A referência anota a linguagem esperada de cada propriedade (`language=plsql` etc.). Use **exatamente** esse indicador; `javascript` puro não é o indicador documentado.
- O conteúdo do bloco é texto livre: comentários `--` de SQL, `//` de JS, aspas e `#` são parte do código.
- A forma compacta também é válida e aparece nos exemplos gerados da referência: ```` aiConsentMessage: ``` ```` na mesma linha, texto nas linhas seguintes e ```` ``` ```` fechando. Prefira a forma do export.
- Propriedades `multiline string` curtas podem ir em uma linha só, sem cerca: `plsqlExpression: :P14_EMPRESA = :G_ID_EMPRESA`, `whenNoDataFound: Nenhum registro.` (observado no export).
- Linhas em branco dentro do bloco são preservadas (o export às vezes deixa uma linha vazia antes da cerca de fechamento; é inofensivo).

Fonte: [Reading APEXlang Syntax](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/reading-apexlang-syntax.html), [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Comentários em APEXlang: `//` e `/* … */`
A gramática aceita comentários de linha (`//` até o fim da linha) e de bloco (`/* … */`). Fora de blocos de código eles são ignorados pelo compilador. Cuidado: dentro de um bloco cercado, `//` e `--` são parte do código (JS/SQL), não comentários APEXlang. O export não gera comentários APEXlang; comentários do desenvolvedor sobre um componente ficam na propriedade `comments { comments: … }` (presente em quase todos os componentes) ou no componente `developerComment`.

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (EBNF, produção `<comment>`)

### Identificadores de componente e Static ID: unicidade por escopo
Cada tipo de componente elege uma **propriedade identificadora**, normalmente `staticId`, às vezes `name` ou `alias`. O valor dela é o que vem logo depois do tipo, antes do `(`. Todo componente tem um Static ID legível obrigatório, de modo que os arquivos nunca precisam de IDs numéricos internos; no import ou upgrade, o APEX gera Static IDs para componentes que não tenham.

O compilador garante unicidade conforme o tipo, no escopo da app, da página ou só do componente pai. Exemplos da doc:
- uma app só pode ter uma `page 3`;
- as páginas 2 e 3 podem ter, cada uma, uma `region employees`;
- na página 3, as regiões `employees` e `departments` podem ter, cada uma, uma `column DEPTNO`;
- a mesma região não pode ter duas colunas `DEPTNO`.

Propriedade identificadora observada no export deste projeto:

| Componente | O que vai depois do tipo | Exemplo |
|---|---|---|
| `app` | alias | `app CORLIXHUB (` |
| `page` | número da página | `page 16 (` |
| `pageItem` | nome do item | `pageItem P16_CEP (` |
| `region`, `button`, `process`, `dynamicAction`, `action`, `validation`, `computation` | `staticId` | `region cadastro-de-empresas (`, `button cancel (` |
| `column` (relatórios) | nome da coluna | `column ID_EMPRESA (` |
| `savedReport` | staticId (antigo "alias") | `savedReport primary (` |
| `displayColumn` | coluna | `displayColumn BAIRRO (` |
| `appItem`, `substitution` | nome | `appItem G_ID_EMPRESA (` |
| `file` | caminho do arquivo | `file "Fotos Colaboradores/x.jpg" (` |
| `slot` (page template) | `apexlangName` | `slot afterLogo (` |
| `parameter` de invokeApi | nome do parâmetro | `parameter p_username (` |
| `branch`, `componentSetting`, `supportingObject` | sem identificador | `branch (` |

Atenção ao botão: o identificador (`staticId`, ex.: `cancel`) é diferente de `buttonName` (`CANCEL`, o REQUEST enviado). Os dois precisam ser únicos: o `apex validate` acusa `DUPLICATED_COMPONENT … identification.buttonName` quando dois botões da mesma página têm o mesmo `buttonName`.

Fonte: [Reading APEXlang Syntax](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/reading-apexlang-syntax.html), [Using SQLcl with APEXlang](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-sqlcl-apexlang.html)

### Static ID x HTML DOM ID (renomeação no APEX 26.1)
No 26.1, o antigo atributo **Static ID** de regiões, botões e colunas de Interactive Grid/Interactive Report foi renomeado para **HTML DOM ID** (em APEXlang: `advanced { htmlDomId: … }`). O nome **Static ID** passou a designar o identificador externo único usado no export APEXlang (`advanced.staticId`, que é o id após o tipo). O *Alias* de relatórios salvos de IR/IG também virou *Static ID*. A substituição `#REGION_STATIC_ID#` foi depreciada em favor de `#DOM_ID#`.

Implicações:
- O id `region home_hero (` **não** vira o `id` do elemento HTML. Se o JavaScript/CSS precisar de um id fixo no DOM, defina `advanced { htmlDomId: meu_id }` (formato: sem `: / , + ? ^ ' "` nem espaço). Sem `htmlDomId`, o APEX gera um ID interno. O template precisa conter `#DOM_ID#` para usar o valor.
- Referências entre componentes no APEXlang (`@x`) sempre usam o Static ID, nunca o DOM ID.
- Trate Static IDs como permanentes: mudar um Static ID quebra chamadas de API que usavam o antigo e faz ferramentas de diff perderem a correlação entre versões. No Builder ele fica bloqueado por padrão (ícone de cadeado para editar); componentes dependentes mantêm a referência, mas código seu com o id antigo precisa ser ajustado à mão.
- Apps vindas de versões anteriores ganham Static IDs legíveis gerados a partir do nome; Static IDs duplicados de séries/eixos de JET Chart foram tornados únicos no upgrade (há um *JavaScript Static ID* depreciado para compatibilidade).

Fonte: [Changed Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html), [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html), [Editing Regions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-regions.html), [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Referências entre componentes: `@id`, `@/id` e propriedades COMPONENT x ITEM
Um valor iniciado por `@` é uma **referência** ao valor da propriedade identificadora de outro componente:
- `@id`: componente da mesma página (região, botão, item) ou shared component da app (LOV, lista, breadcrumb, authorization, template local do tema). Ex.: `region: @employee`, `formRegion: @employee`, `lov: @dept-dname`, `authorizationScheme: @admin-rh`, `pageTemplate: @corlix-standard-page`.
- `@/id`: duas exceções usam barra: (1) componentes da **Global Page** referenciados de outra página (`@/my-global-page-header`) e (2) componentes do **Universal Theme padrão** (templates `@/drawer`, `@/blank-with-attributes`, `@/optional-floating`, e o theme style `@/redwood-light`). Um template definido localmente no app usa `@` sem barra (`@my-slideshow`).

Quando usar `@` e quando não: a EBNF tipa cada propriedade. As do tipo **COMPONENT** recebem `<reference>` (com `@`); as do tipo **ITEM** (e COLUMN) recebem o nome simples. Exemplos:

| Com `@` (COMPONENT) | Sem `@` (ITEM/COLUMN/texto) |
|---|---|
| `layout.region`, `layout.parentRegion`, `source.formRegion` | `when.items`, `affectedElements.items` (array de nomes) |
| `when.button`, `when.region`, `affectedElements.region` | `serverSideCondition.item`, `clientSideCondition.item` |
| `error.associatedItem` (validação) | `cascadingLov.parentItems`, `itemsToSubmit`, `pageItemsToSubmit` |
| `lov.lov`, `source.breadcrumb`, `source.list` | `source.column` (coluna do form), `columnMapping.return/display` |
| `security.authorizationScheme`, `config.buildOption` | `computation.itemName` |
| `appearance.template`, `pageTemplate`, `dialogTemplate`, `buttonTemplate` | `settings.names` de authorization *is in role* (nome da role, texto) |
| `page.pageGroup`, `app.userInterface.currentTheme`, `navigationMenu.list` | `validation.item`, `branch.item` |

Na referência em Markdown essas propriedades aparecem como `string`, com o exemplo `@component`; a EBNF é que deixa claro o tipo COMPONENT. Referência quebrada gera `REFERENCE_NOT_FOUND` no `apex validate`.

Fonte: [Reading APEXlang Syntax](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/reading-apexlang-syntax.html), [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Valores complexos: link target `{ page: … items: { … } }`
Propriedades do tipo `complex`/LINK (ex.: `link.target`, `behavior.target`, `navigation.homeUrl`) recebem um objeto entre chaves, inline. A referência só mostra `target: value` e não detalha as chaves internas; o formato abaixo foi **observado no export** deste projeto:

```
link {
    target: {
        page: 16
        items: {
            P16_ID_EMPRESA: \#ID_EMPRESA#\
        }
        clearCache: 18
        action: resetPagination
    }
}

target: {
    type: url
    url: &LOGOUT_URL.
}

homeUrl: {
    page: 1
}
loginUrl: {
    page: LOGIN
}
```

Chaves observadas: `page` (número ou alias), `items` (mapa ITEM: valor), `clearCache` (páginas), `action` (`resetPagination`, `clearRegions`), `type: url` + `url`. Sobre o escape `\#COL#\`: no link de coluna de Interactive Report da p15 o valor aparece como `\#ID_EMPRESA#\`, enquanto num Classic Report da p13 aparece `#ID_HISTORICO_CARREIRA#` sem barras. A doc não explica o escape; **preserve exatamente como o export gerou** e, ao criar um target novo, copie o padrão de um componente do mesmo tipo e rode `apex validate`.

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (tipo `complex`/LINK; formato interno observado no export)

### Propriedades condicionais ("Applies when") e validação por metadados (MMD)
Cada propriedade da referência pode ter uma condição *Applies when* (ex.: `region.edit.enabled` só se aplica a Form e Interactive Grid; `page.dialogTemplate` só quando `pageMode` é modal/non-modal; `chart.zoomAndScroll` só para regiões `chart`). O compilador conhece, por tipo, quais propriedades e filhos existem e valida valores, aninhamento e essas condições. Exemplos da doc: uma região `interactiveReport` tem `column` filhas, uma `form` não; uma `chart` tem `zoomAndScroll`, uma `classicReport` não.

Esse conhecimento é o **meta-metadata (MMD)**, o mesmo que o Page Designer usa para mostrar/esconder propriedades. Ele evolui com novas versões; por isso cada app grava a versão de MMD usada no export em `.apex/apexlang.json`. Não edite esse arquivo à mão: ele só deve mudar quando uma versão futura do APEX reexportar a app.

```
{
  "mmdVersion" : "26.1.0+3102"
}
```

Fonte: [Using SQLcl with APEXlang](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-sqlcl-apexlang.html)

### Substituições e marcadores dentro de valores (#DEFAULT#, #APP_FILES#, #MIN#, &ITEM., #COL#)
Valores APEXlang carregam as mesmas strings de substituição do App Builder, sem escape especial:
- `#DEFAULT#` em `templateOptions`: "as opções padrão que o template define".
- `#APP_FILES#`, `#THEME_FILES#`, `#APEX_FILES#`, `#MIN#`, `#MIN_DIRECTORY#`, `#APEX_VERSION#` em URLs de arquivo (`#APP_FILES#corlix-tema#MIN#.css`).
- `&ITEM.` (session state) em textos, HTML e links (`&G_NOME_USUARIO.`, `&APP_TEXT$DELETE_MSG!RAW.`).
- `#COLUNA#` em templates de relatório, link de coluna e HTML expression; `&COLUNA.` em HTML expression de Cards.
- `#COMPONENT_PAGE_ID#`/`#PAGE_ID#` aparecem nas condições da própria referência (ex.: default do nome de item `P#PAGE_ID#_NEW`).

Fonte: [Reading APEXlang Syntax](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/reading-apexlang-syntax.html), [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Tipos de propriedade da referência e como escrever cada um
| Tipo na referência | Como escrever | Exemplo |
|---|---|---|
| `string` | texto sem aspas (aspas se precisar) | `label: Salvar` |
| `enum` | um dos valores listados, camelCase | `pageMode: modalDialog` |
| `boolean` | `true`/`false` | `hot: true` |
| `number`/`integer` | número | `sequence: 10` |
| `multiline string` | uma linha ou bloco cercado com linguagem | `plsqlCode:` + ```` ```plsql ```` |
| `array of strings`/`array of enums`/`array of integers` | `[ … ]` ou valor único | `allowedOperations: [ add update ]` |
| `complex` | objeto `{ … }` | `target: { page: 1 }` |
| `datetime` | string-like | `allowUrlsCreatedAfter: …` |
| `blob` | conteúdo binário vem do arquivo físico (static files) | `file … ( mimeType: image/png )` |
| referência (`string` com `@component` no exemplo) | `@id` ou `@/id` | `lov: @boolean` |

Observação sobre enums que viram booleanos: vários atributos Yes/No antigos aparecem na referência como `boolean` com default exibido em letras (`def=on`, `def=YES`, `def=0`). Escreva `true`/`false`.

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

---

## 3. Estrutura de diretórios do export

### Estrutura de diretórios de um export APEXlang (application.apx, pages/, shared-components/, deployments/, .apex/)
Um export APEXlang é um ZIP (ou pasta) com um arquivo por página e por grupo de componentes. Estrutura documentada para um app de exemplo:

```
employees.zip
├── application.apx              # atributos da aplicação (componente app)
├── page-groups.apx              # pageGroup
├── deployments/
│   └── default.json             # id da app e settings por ambiente
├── pages/
│   ├── p00000-global-page.apx
│   ├── p00001-home.apx
│   ├── p00002-employees.apx
│   ├── p00003-employee.apx
│   └── p09999-login.apx
├── shared-components/
│   ├── static-files/            # arquivos estáticos como estão (binários)
│   │   └── icons/app-icon-*.png
│   ├── themes/universal-theme/theme.apx
│   ├── authentications.apx
│   ├── authorizations.apx
│   ├── breadcrumbs.apx
│   ├── build-options.apx
│   ├── component-settings.apx
│   ├── lists.apx
│   ├── lovs.apx
│   └── static-files.apx         # nomes e metadados dos static files
└── .apex/
    └── apexlang.json            # mmdVersion (não editar)
```

Arquivos adicionais aparecem conforme o que a app tem. Neste repositório (`corlixhub/`) também existem `shared-components/acl-roles.apx`, `app-items.apx`, `app-processes.apx`, `themes/universal-theme/{page-templates,region-templates,button-templates,classic-report-templates}/*.apx` e `themes/universal-theme/static-files.apx` (arquivos do tema), além de `supporting-objects/supporting-objects.apx` e `supporting-objects/substitutions.apx` (observado no export).

Um pacote APEXlang, segundo o htmdb, contém arquivos `.apx`, scripts SQL de Supporting Objects, assets CSS/JS e recursos estáticos (inclusive imagens). Desde o 26.1, o export APEXlang inclui os static files binários (consumidores de `APEX_EXPORT` devem ler `APEX_T_EXPORT_FILE.contents_blob` para binários).

Fonte: [Exporting APEXlang from App Builder](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/exporting-apexlang-app-builder.html), [Creating an Application with APEXlang](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-an-application-with-APEXlang.html), [Changed Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html)

### Nome de arquivo de página `pNNNNN-alias.apx` e a regra alias x arquivo
O nome do arquivo de página combina o número com 5 dígitos e o alias em minúsculas: `p00003-employee.apx` para `page 3` com `alias: EMPLOYEE`. O compilador **exige** que o número e o alias declarados dentro do arquivo correspondam ao nome do arquivo. Logo:
- Renomear o alias de uma página exige renomear o arquivo (e vice-versa).
- Criar uma página nova à mão = criar `pages/pNNNNN-<alias>.apx` com `page NNNNN (` e `alias:` coerentes.
- A Global Page é `p00000-global-page.apx`, sem `alias`/`title` (essas propriedades não se aplicam à página global).

Observado no export: aliases com acento geram nome de arquivo com acento (`p00008-notificações.apx`, `p00001-início.apx`).

Fonte: [Exporting APEXlang from App Builder](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/exporting-apexlang-app-builder.html), [Reading APEXlang Syntax](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/reading-apexlang-syntax.html)

### deployments/default.json: ID da aplicação, runtime e mapeamento de assinaturas
O ID numérico da app **não** fica no `application.apx`; ele fica em `deployments/default.json`. Isso permite que o ZIP tenha nome descritivo (alias) e que cada ambiente tenha seu conjunto de settings.

```
{
  "app" : {
    "id" : 104,
    "runtime" : {
      "debugging" : true
    }
  }
}
```

Para apps que assinam componentes de uma app mestre (*subscription*), o mesmo arquivo aceita `subscription.masterApps`, que mapeia o id da mestre na origem para o id no destino. Exemplo da Release Notes: a mestre 101 foi instalada como 901 no destino; antes de importar a app 102, ajuste:

```
{
  "app" : { "id" : 102 },
  "subscription" : { "masterApps" : { "101" : 901 } }
}
```

Observação: a doc chama o arquivo ora de `default.json`, ora de `defaults.json`; o export real (e o deste projeto) usa `deployments/default.json`.

Fonte: [Exporting APEXlang from App Builder](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/exporting-apexlang-app-builder.html), [Open Bugs and Known Issues](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/open-bugs-known-issues.html)

### Static Application Files no export APEXlang (static-files.apx + arquivos físicos)
Os arquivos estáticos da aplicação vão "como estão" para `shared-components/static-files/` (mantendo subpastas), e a lista com metadados vai em `static-files.apx`, um componente `file` por arquivo:

```
file "Fotos Colaboradores/aline_alves.jpg" (
    mimeType: image/jpeg
    charSet: utf-8
)

file corlix-tema.css (
    mimeType: text/css
    charSet: utf-8
)
```

O conteúdo (`content: blob`) não é escrito no `.apx`: vem do arquivo físico. Para adicionar um static file por APEXlang: coloque o arquivo na pasta e declare o `file` correspondente. Arquivos do tema seguem o mesmo esquema em `themes/<tema>/static-files.apx` (observado no export, com nomes numéricos como `10245258954911381.css`).

Fonte: [Exporting APEXlang from App Builder](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/exporting-apexlang-app-builder.html), [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (componente `file`)

### Estrutura de diretórios do export SQL dividido (Split into Multiple Files) — comparação
O export **SQL** com *Split into Multiple Files* (App Builder) ou `-split` (SQLcl) cria `f<id>/install.sql` e uma árvore `application/…` organizada por tipo. A mesma estrutura vale para exports de página/componente com *Export as Zip*. Mapeamento oficial (Apêndice C), resumido:

| Componente | Diretório (export SQL split) |
|---|---|
| Supporting Objects | `application/deployment` |
| Page / Page Group | `application/pages` / `application/pages/page_groups` |
| Plug-in Settings | `application/plugin_settings` |
| Application Static File | `application/shared_components/files` |
| Text Message | `application/shared_components/globalization/messages` |
| Application Computation / Item / Process / Setting | `application/shared_components/logic/application_{computations,items,processes,settings}` |
| Build Option (+ status) | `application/shared_components/logic/build_options` (`/status`) |
| Breadcrumb / Entry | `application/shared_components/navigation/breadcrumbs` / `…/breadcrumbentry` |
| List / Navigation Bar Entry / Tabs / Tree | `application/shared_components/navigation/{lists,navigation_bar,tabs,trees}` |
| Plug-in | `application/shared_components/plugins` |
| Report Layout / Report Query | `application/shared_components/reports/{report_layouts,report_queries}` |
| ACL Role / Authentication / Authorization | `application/shared_components/security/{app_access_control,authentications,authorizations}` |
| List of Values / Shortcut | `application/shared_components/user_interface/{lovs,shortcuts}` |
| Templates (page, region, button, label, list, report, breadcrumb, calendar, popuplov) | `application/shared_components/user_interface/templates/<tipo>` |
| REST Data Source | `application/shared_components/web_sources` |
| Data Profile / Data Loading / Email Template | `application/shared_components/{data_profiles,data_loading/tables,email/templates}` |
| Concatenated File | `application/user_interfaces/combined_files` |
| Credential / Workspace Static File / Remote Server | `workspace/{credentials,files,remote_servers}` |

Não confunda: essa árvore é do formato **SQL**. O export APEXlang tem a estrutura da seção anterior (`pages/`, `shared-components/`, `deployments/`).

Fonte: [Directory Structure When Splitting Export Files into Separate Scripts](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/directory-structure-when-splitting-export-files.html), [Exporting One or More Applications](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/exporting-one-or-more-applications.html)

---

## 4. Exportar, importar e validar

### Exportar em APEXlang pelo App Builder (Format: APEXlang; tipos Standard, Runtime, Full, Custom)
Caminho: *App Builder › (app) › Export/Import › Export* (ou *Workspace Utilities › Export*). Na página Export:
- **Format**: `SQL` (script `.sql`, ou ZIP com *Split into Multiple Files*) ou **`APEXlang`** (ZIP `alias-da-app.zip`, legível e editável).
- **Type**: *Standard Export* (padrão; recomendado para source control; inclui comentários de desenvolvedor e auditoria; exclui dados de runtime), *Runtime Export* (para TEST/PROD; omite metadados de desenvolvedor e põe build status *Run Application Only*), *Full Export* (inclui dados de runtime, workflow/task instances e relatórios salvos; não recomendado para Git) e *Custom Export* (abre *Advanced Options*).
- *Advanced Options* com Format = APEXlang: *Build Status Override*, *Comments*, *Debugging*, *Owner Override*, *As of* (flashback em minutos, via `DBMS_FLASHBACK`, limitado por `UNDO_RETENTION`). Opções como Split, Supporting Objects, Public/Private Reports, Subscriptions, Translations, Original IDs e Workflow/Task Instances só existem para o formato SQL.

Limitação do 26.1: exportar dados de runtime (Public Reports, Private Reports, Report Subscriptions, Workflow Instances, Task Instances) **não é suportado** no formato APEXlang. Para levar relatórios salvos de usuários, use o export SQL.

Exportar uma **página** em APEXlang também é possível (*Export Page*), mas importar uma página APEXlang pelo App Builder não está disponível no 26.1.

Fonte: [Exporting an Application](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/exporting-an-application.html), [Exporting an Application Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/exporting-an-application-page.html), [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### Exportar com SQLcl: `apex export -exptype APEXLANG`
Conecte no **schema de parsing do workspace** e rode:

```
SQL> apex export -applicationid 104 -exptype apexlang
SQL> apex export -applicationid 104 -dir '/caminho/pai' -exptype APEXLANG
```

- Sem `-dir`, o SQLcl cria, no diretório atual, uma pasta com o nome do **alias** da app e exporta nela. Com `-dir`, cria a pasta do alias dentro do diretório pai informado.
- Dá para combinar formatos numa execução: `-expType APPLICATION_SOURCE,APEXLANG` gera a pasta do alias (APEXlang) e a pasta `f<id>/` (SQL).
- O painel *Export…* do SQL Developer for VS Code mostra, na aba SQL, o comando SQLcl equivalente.

Exemplo do Developer's Companion para source control (uma linha só na prática):
```
apex export -applicationid 12345 -split -skipExportDate -expOriginalIds -expSupportingObjects Y -expType APPLICATION_SOURCE,APEXLANG
```

Fonte: [Using SQLcl with APEXlang](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-sqlcl-apexlang.html), [Editing APEXlang in Visual Studio Code](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/editing-apexlang-visual-studio-code.html), [Exporting and Importing Applications](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/exporting-and-importing-applications.html)

### Opções do comando `apex export` (SQLcl)
| Opção | Efeito |
|---|---|
| `-applicationid <id>` | App a exportar |
| `-workspaceid <id>` | Exporta todas as apps do workspace |
| `-expType` | Lista separada por vírgula: `APPLICATION_SOURCE` (padrão, SQL), `APEXLANG`, `EMBEDDED_CODE` (extrai SQL/PL/SQL/JS), `READABLE_YAML`, `CHECKSUM-SH1`, `CHECKSUM-SH256` |
| `-split` | SQL dividido em arquivos (`f<id>/install.sql` + `application/…`) |
| `-dir <pasta>` | Pasta de saída |
| `-skipExportDate` | Omite a data do export (evita diffs falsos) |
| `-expOriginalIds` | Emite IDs como estavam no último import (diffs estáveis entre ambientes) |
| `-expSupportingObjects Y\|N\|I` | Inclui supporting objects; `I` = incluir e instalar automaticamente no import |
| `-expComponents "TIPO:ID …"` | Export parcial (gera `install_component.sql` quando com `-split`) |
| `-expPubReports`, `-expSavedReports`, `-expIRNotif` | Relatórios públicos, salvos e notificações de IR |
| `-expTranslations`, `-expComments`, `-expNoSubscriptions` | Traduções, comentários, sem referências de assinatura |
| `-expFiles` | Arquivos estáticos do workspace |
| `-nochecksum` | Sobrescreve arquivos mesmo sem mudança |
| `-debug` | Saída de depuração |

`apex list -applicationid <id> -changesSince AAAA-MM-DD` lista componentes alterados (útil para export parcial SQL). As opções de dados de runtime não se aplicam ao formato APEXlang.

Fonte: [Exporting One or More Applications](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/exporting-one-or-more-applications.html), [Exporting and Importing Applications](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/exporting-and-importing-applications.html)

### Importar APEXlang pelo App Builder (Import wizard, ORDS 26.1.1 e schema REST-enabled)
Em *App Builder › Import*, arraste ou selecione o ZIP APEXlang. O wizard confirma o tipo APEXlang, deixa escolher o **Application ID** e, em *Import Application*, valida e compila o APEXlang; sem erros, a app é importada. Requisitos:
- ORDS **26.1.1 ou posterior** na instância.
- Pelo menos um schema do workspace **REST-enabled**: o App Builder compila o APEXlang por um endpoint ORDS dedicado com autenticação do Builder. Na primeira vez, o wizard pode oferecer o botão **REST Enable Schema** para o schema de parsing.

Se houver erros, uma página de erros/avisos aparece e é possível baixar um CSV com a validação. Importar **sobrescreve** a versão atual da app no App Builder: garanta que mudanças feitas no Builder já estão nos arquivos.

Fonte: [Importing APEXlang in App Builder](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/importing-apexlang-app-builder.html), [Importing Export Files](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/importing-export-files.html), [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### Importar com SQLcl: `apex import -input`
Conectado no schema de parsing do workspace:

```
SQL> apex import -input /caminho/employees        -- pasta
SQL> apex import -input myapp.zip                 -- ZIP
SQL> help apex import                             -- todas as opções
```

O `apex import` **sempre valida antes**: erros e avisos saem como no `apex validate`; sem erros, importa e mostra `Importing application ID: 104 into workspace: …` / `Import successful.`. É preciso uma versão do SQLcl que tenha o comando `apex import` (atualize o SQLcl antes).

Para o formato **SQL**, o import é rodar o script (`@f1234.sql`, `@f1234/install.sql` ou `@f1234/install_component.sql`), e o contexto de destino diferente se ajusta antes com `APEX_APPLICATION_INSTALL` (`set_workspace`, `set_application_id` + `generate_offset`, `generate_application_id`, `set_schema`, `set_application_alias`, `set_auto_install_sup_obj(true)`). Na mesma instância, o ID da app precisa ser diferente entre workspaces.

Fonte: [Using SQLcl with APEXlang](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-sqlcl-apexlang.html), [Installing an Application](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/installing-an-application.html), [Exporting and Importing Applications](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/exporting-and-importing-applications.html)

### Validar sem importar: `apex validate` (inclusive sem conexão, com `/nolog`)
```
SQL> apex validate -input /caminho/employees
Validation successful

$ sql /nolog
SQL> apex validate -input .
```

- `apex validate` compila e reporta erros/avisos **sem importar**.
- Funciona **sem conexão** (SQLcl com `/nolog`): útil para validar uma app baixada de instância sem SQL*Net e para agentes de IA corrigirem os próprios erros.
- `-input` aceita pasta ou ZIP; `.` = diretório atual (raiz da app, onde está `application.apx`).
- Para guardar a saída: `spool erros.log` → `apex validate …` → `spool off`.
- Só **erros** impedem o import; **avisos** são informativos.

Fonte: [Using SQLcl with APEXlang](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-sqlcl-apexlang.html), [Creating an Application with APEXlang](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-an-application-with-APEXlang.html)

### Ler a saída do `apex validate`: File, Line, Column, Type, Error
Cada erro traz o arquivo relativo, linha, coluna, um **Type** e a mensagem:

```
APEXLang Compile Errors:

File: pages/p00003-employee.apx
Line: 117
Column: 12
Type: REFERENCE_NOT_FOUND
Error: Reference not found: @employe
```

Tipos de erro mostrados na doc: `REFERENCE_NOT_FOUND`, `INVALID_PROPERTY`, `LOV_NOT_FOUND` (valor de enum inválido, com a lista de valores válidos), `DUPLICATED_COMPONENT`. No VS Code os mesmos erros aparecem no painel *Problems* com sublinhado, enquanto você digita. Fluxo de correção recomendado: abrir o `.apx` na linha indicada, conferir o componente no App Builder se precisar de contexto, corrigir (no Builder e reexportar, ou direto no arquivo) e validar de novo.

Fonte: [Using SQLcl with APEXlang](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-sqlcl-apexlang.html), [Creating an Application with APEXlang](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-an-application-with-APEXlang.html)

### Reference not found: @nome (REFERENCE_NOT_FOUND)
**Sintoma:** `apex validate`/`apex import` falha com `Type: REFERENCE_NOT_FOUND` e `Error: Reference not found: @employe`.
**Causa:** o valor `@…` não corresponde ao identificador de nenhum componente no escopo: erro de digitação, componente renomeado/removido, falta da barra (`@/`) para template do Universal Theme ou componente da Global Page, ou barra indevida para template local.
**Correção:** corrija o identificador (procure `region <id> (`, `lov <id> (` etc. no projeto); use `@/` para templates padrão (`@/standard`, `@/modal-dialog`) e para componentes da página 0; use `@` para templates customizados (`@corlix-standard-page`).
**Prevenção:** ao renomear um Static ID, faça busca global pelo `@antigo` em todos os `.apx`.

Fonte: [Using SQLcl with APEXlang](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-sqlcl-apexlang.html), [Reading APEXlang Syntax](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/reading-apexlang-syntax.html)

### Invalid property: <nome> (INVALID_PROPERTY)
**Sintoma:** `Type: INVALID_PROPERTY`, `Error: Invalid property: primaryKe`.
**Causa:** nome de propriedade inexistente no grupo/componente (erro de digitação, propriedade de outro grupo, ou propriedade que não se aplica àquele tipo de componente, ex.: `zoomAndScroll` numa `classicReport`).
**Correção:** confira o nome e o grupo na API Reference do componente/tipo; no VS Code use Ctrl+Espaço para ver as propriedades válidas.
**Prevenção:** copie a estrutura de um componente do mesmo tipo já exportado.

Fonte: [Using SQLcl with APEXlang](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-sqlcl-apexlang.html)

### Invalid LOV required parameter … Valid parameters are (LOV_NOT_FOUND / valor de enum inválido)
**Sintoma:** `Type: LOV_NOT_FOUND`, `Error: Invalid LOV required parameter: source - dataType (string)` seguido de `Valid parameters are: -bfile -blob -boolean -clob -date …`.
**Causa:** valor fora da lista permitida para uma propriedade enum (no exemplo, `dataType: numbe`). Apesar do nome, não tem a ver com shared LOV: "LOV" aqui é a lista de valores da propriedade.
**Correção:** use um dos valores listados na própria mensagem (camelCase exato: `number`, `varchar2`, `timestampWithTimeZone`…).

Fonte: [Using SQLcl with APEXlang](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-sqlcl-apexlang.html)

### Duplicated component within parent scope (DUPLICATED_COMPONENT)
**Sintoma:** `Type: DUPLICATED_COMPONENT`, `Error: Duplicated component within parent scope. For properties: identification.buttonName: VIEW_ACTIVITY_BY_USER`.
**Causa:** dois componentes do mesmo tipo no mesmo escopo com o mesmo valor numa propriedade que precisa ser única (identificador ou, como no exemplo, `buttonName`). Comum ao duplicar blocos copiando e colando.
**Correção:** dê `staticId`/nome único ao componente copiado e, para botões, um `buttonName` diferente.

Fonte: [Using SQLcl with APEXlang](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-sqlcl-apexlang.html)

### Invalid template option value… (template options incompatíveis após trocar o template)
**Sintoma:** depois de trocar `appearance.dialogTemplate` (ex.: de `@/drawer` para `@/modal-dialog`), `templateOptions` fica sublinhado e o painel Problems do VS Code mostra "Invalid template option value…".
**Causa:** template options são definidas por template; uma opção do template antigo (ex.: `js-dialog-class-t-Drawer--pullOutEnd`) não existe no novo.
**Correção:** remova as opções que não pertencem ao novo template (deixar só `#DEFAULT#` é sempre válido).
**Prevenção:** ao trocar template de página, região, botão ou item, revise `templateOptions` junto.

Fonte: [Editing APEXlang in Visual Studio Code](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/editing-apexlang-visual-studio-code.html)

### Erros de validação em apps antigas (metadados legados) ao exportar/importar em APEXlang
**Sintoma:** uma app madura, copiada ou atualizada por várias versões, exporta em APEXlang mas o `apex validate` (ou o reimport) reporta erros que não afetam o runtime.
**Causa:** inconsistências de metadados legados. O APEX corrige automaticamente, no import e no upgrade, as que têm correção inequívoca; as demais aparecem pela validação mais estrita do APEXlang.
**Correção:** exporte em APEXlang e rode `apex validate -input` com `/nolog` (com `spool`), ou exporte/reimporte no App Builder e baixe o CSV de erros. Para cada erro, abra o arquivo/linha, veja o componente no Builder e decida: corrigir referência obsoleta, remover metadado órfão, recriar componente faltante ou trocar valor inválido por um permitido. Só erros exigem correção.

Fonte: [Creating an Application with APEXlang](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-an-application-with-APEXlang.html)

### Import APEXlang pede "REST Enable Schema" ou falha por ORDS/schema
**Sintoma:** o wizard de import para e pede para habilitar o schema para ORDS REST, ou o import APEXlang mostra erro de requisito.
**Causa:** o App Builder compila APEXlang por um endpoint ORDS; exige ORDS 26.1.1+ e ao menos um schema REST-enabled no workspace.
**Correção:** clique em **REST Enable Schema** (ou habilite o schema de parsing para ORDS) e continue; confirme a versão do ORDS com o administrador. Alternativa: importe pelo SQLcl (`apex import`).

Fonte: [Importing APEXlang in App Builder](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/importing-apexlang-app-builder.html), [Importing Export Files](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/importing-export-files.html)

### Export APEXlang falha com região Legacy Calendar
**Sintoma:** erro ao exportar em APEXlang uma app com região de calendário legado.
**Causa:** o template Legacy Calendar foi depreciado e não existe no Universal Theme 26.1; o export APEXlang levanta erro se houver regiões Legacy Calendar.
**Correção:** migre a região para o tipo `calendar` atual antes de exportar. No upgrade, templates Legacy Calendar não referenciados são removidos automaticamente.

Fonte: [Deprecated Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/deprecated-features.html)

### Import APEXlang: erro de validação com workflow que tem Parallel Branch
**Sintoma:** o import APEXlang falha na validação numa app com workflow que contém atividade *Parallel Branch*.
**Causa:** problema conhecido do 26.1.
**Correção:** não há correção documentada; use o export/import SQL para essa app até a correção da Oracle.

Fonte: [Open Bugs and Known Issues](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/open-bugs-known-issues.html)

### Importar APEXlang numa working copy desassocia a working copy da app principal
**Sintoma:** após importar um export APEXlang para dentro de uma working copy, ela deixa de estar ligada à app base.
**Causa:** problema conhecido do 26.1 (listado em *Known Issues for Importing APEXlang* e *Working Copy*).
**Correção/Prevenção:** evite importar APEXlang sobre working copy quando precisar manter o vínculo para *Merge into Main*; trabalhe a mudança e importe na app principal, ou refaça a working copy. Observação: o Developer's Companion descreve o fluxo "exportar a working copy, editar e reimportar" como suportado; a Release Notes registra a desassociação como problema conhecido. Confie na Release Notes.

Fonte: [Open Bugs and Known Issues](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/open-bugs-known-issues.html), [Using App Builder and External Tools Together](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-app-builder-and-external-tools-together.html)

### Após import APEXlang não aparece a tela de credenciais "Prompt on Install"
**Sintoma:** web credentials ou remote servers marcados *Prompt on Install* não pedem valores após o import APEXlang.
**Causa:** problema conhecido do 26.1: não há página de conveniência pós-import.
**Correção:** ajuste-os em *Workspace Utilities* nas páginas de edição de Web Credentials e Remote Servers.

Fonte: [Open Bugs and Known Issues](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/open-bugs-known-issues.html)

### A aplicação é a unidade de export/import APEXlang
O export APEXlang é sempre da **aplicação inteira** e o import substitui a app inteira no destino:
- Mudou fora do Builder → importar o APEXlang substitui a versão atual do Builder.
- Mudou no Builder → as ferramentas externas só veem a mudança no próximo export.
- Não é possível importar uma página isolada em APEXlang (só em SQL).

Para equipes, a combinação recomendada é SQLcl + Git: exportar regularmente, commitar com mensagem, importar os arquivos em TEST/PROD. Com working copies, normalmente só a app principal vai para o Git.

Fonte: [Using App Builder and External Tools Together](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-app-builder-and-external-tools-together.html), [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html), [Summarizing Lifecycle Recommendations](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/summarizing-lifecycle-recommendations.html)

### APEXlang e App Builder fora de sincronia: como resolver o conflito
**Sintoma:** houve mudança no App Builder e mudança nos `.apx` ao mesmo tempo; importar um lado apagaria o outro.
**Correção (fluxo da doc):** (1) exporte a versão atual do App Builder em APEXlang; (2) descompacte numa pasta temporária; (3) unifique as versões com sua ferramenta de diff/merge; (4) valide e importe o resultado unificado. A app só importa se validar limpo; se falhar, corrija e tente de novo.
Para conflitos de merge de working copy: exporte a principal e a working copy em APEXlang, resolva o conflito externamente, valide a principal com `apex validate`, importe sobrescrevendo a principal e apague a working copy conflitada.

Fonte: [Using App Builder and External Tools Together](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-app-builder-and-external-tools-together.html), [Isolating Changes with Working Copies](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/isolating-changes-working-copies.html)

### Editar, validar e importar APEXlang no SQL Developer for VS Code
A extensão SQL Developer for VS Code (procure "Oracle APEX" no Marketplace) lista as apps na pasta APEX da conexão. Funções:
- **Export…** no menu de contexto da app: escolha a pasta pai e *Apply*; a aba SQL mostra o comando SQLcl equivalente.
- Edição com assistência: Ctrl+Espaço sugere valores válidos no contexto (ex.: em `appearance.dialogTemplate` de página modal, lista os templates de diálogo válidos).
- Painel **Problems**: erros de validação aparecem enquanto você edita.
- Botão **play** (canto superior direito do editor): importa a app na conexão (pede o schema de parsing se necessário); sucesso mostra confirmação.

O SQLcl embutido também roda em terminal não interativo (headless/automação).

Fonte: [Editing APEXlang in Visual Studio Code](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/editing-apexlang-visual-studio-code.html), [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### Ciclo de vida da aplicação com APEXlang: artefatos, ambientes, Git e working copies
Pontos do capítulo *Understanding Application Lifecycle* relevantes para APEXlang:
- A app é metadado no banco e o dicionário só guarda o estado atual: **não há histórico**. O histórico vem de exportar artefatos (SQL ou APEXlang) e versioná-los.
- Para source control, o export dividido (um arquivo por componente) gera diffs úteis; o APEXlang é ainda mais legível, editável e validável sem conexão.
- Ambientes DEV/TEST/PROD: instâncias separadas (mesmo ID e alias) ou workspaces separados numa instância (IDs/aliases diferentes, remapeados no import). Use *Environment Banner* para distinguir. Incremente a *Version* da app a cada release.
- Working copies: clones isolados dentro do workspace para features/fixes, com compare, refresh e merge por página/componente; trave a página (*page lock*) na principal enquanto trabalha nela na working copy. Se a lógica depender do ID da app principal, use `MAIN_APP_ID` em vez de `APP_ID`.
- Export/import cobre só a definição da app: tabelas, views e packages migram à parte (SQL scripts, SQLcl Projects).

Fonte: [Identifying Application Artifacts](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/identifying-application-artifacts.html), [Working with Multiple Environments](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/working-multiple-environments.html), [Isolating Changes with Working Copies](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/isolating-changes-working-copies.html), [Tracking Changes with Source Control](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/tracking-changes-source-control.html), [Exporting and Importing Applications](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/exporting-and-importing-applications.html)

---

## 5. Blocos reutilizados por muitos componentes

### serverSideCondition: tipos de condição de servidor e propriedades
Quase todo componente (página, região, item, botão, processo, validação, computação, branch, DA, ação, coluna, entrada de lista/breadcrumb/LOV) tem o grupo `serverSideCondition { … }` e, vários, `readOnly { … }` com a mesma estrutura. Valores válidos de `type`:

`always`, `never`, `rowsReturned`, `noRowsReturned`, `expression`, `functionBody`, `request=Value`, `request!=Value`, `requestIsContainedInValue`, `requestIsNotContainedInValue`, `item=value`, `item!=value`, `itemIsNull`, `itemIsNotNull`, `itemIsZero`, `itemIsNotZero`, `itemIsNullOrZero`, `itemIsNotNullAndNotZero`, `itemContainsNoSpaces`, `itemIsNumeric`, `itemIsNotNumeric`, `itemIsAlphanumeric`, `itemIsInColonDelimitedList`, `itemIsNotInColonDelimitedList`, `textIsContainedInItem`, `text=value`, `text!=value`, `textIsContainedInValue`, `textIsNotContainedInValue`, `userPreference=value`, `userPreference!=value`, `currentPage=page`, `currentPage!=page`, `currentPageInList`, `currentPageNotInList`, `currentPage=pageSubmitted`, `currentPage!=pageSubmitted`, `currentPageIsInPrinterFriendlyMode`, `currentPageIsNotInPrinterFriendlyMode`, `pageRegionIsReadOnly`, `pageRegionIsNotReadOnly`, `userIsAuthenticated`, `userIsPublicUser`, `inlineValidationErrorsDisplayed`, `inlineValidationErrorsNotDisplayed`, `sqlReportsOkToShowForwardButton`, `sqlReportsOkToShowBackButton`, `currentLanguage=value`, `currentLanguage!=value`, `currentLanguageIsContainedInValue`, `currentLanguageIsNotContainedInValue`, `clientBrowserIsMozilla`, `clientBrowserIsIE7higher`, `clientBrowserIsXhtmlCssCapable`, `clientBrowserIsOther`, `cgiEnvDadName=value`, `cgiEnvDadName!=value`, `cgiEnvServerName=value`, `cgiEnvServerName!=value`, `cgiEnvHttpHost=value`, `cgiEnvHttpHost!=value`.

Propriedades complementares (aparecem conforme o tipo):

| Propriedade | Quando |
|---|---|
| `sqlQuery` (sql) | `rowsReturned`/`noRowsReturned` |
| `language` (`sql`, `plsql`, `javaScript-mle`; padrão `plsql`) + `sqlExpression`/`plsqlExpression`/`javaScriptExpression` | `expression` |
| `language` (`plsql`, `javaScript-mle`) + `plsqlFunctionBody`/`javaScriptFunctionBody` | `functionBody` |
| `value` | condições de request, idioma, CGI e `item=value` etc. |
| `item` | condições de item |
| `list` (array) | item in/not in colon delimited list |
| `page` / `pages` | current page = / in list |
| `text` | condições de texto |
| `preference` + `value` | preferência de usuário |

Em processos, validações e branches o grupo também tem `whenButtonPressed: @BOTAO` (referência ao botão) e, com região editável, `executionScope` e `executeCondition`.

Exemplos reais:
```
serverSideCondition {
    type: requestIsContainedInValue
    value: CREATE,SAVE,DELETE
}
serverSideCondition {
    type: itemIsNull
    item: P16_ID_EMPRESA
}
serverSideCondition {
    type: request=Value
    value: TROCAR_COLABORADOR
}
```

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (grupos `serverSideCondition`/`readOnly` de `page`, `region`, `pageItem`, `button`, `process`)

### clientSideCondition: condição de cliente em Dynamic Actions e ações
Em `dynamicAction`, `action` (de DA) e `triggerAction`, o grupo `clientSideCondition` aceita:
- `type`: `item=value`, `item!=value`, `item>value`, `item>=value`, `item<value`, `item<=value`, `itemIsNull`, `itemIsNotNull`, `itemIsInList`, `itemIsNotInList`, `jsExpression`.
- `item` (nome do item, sem `@`), `value`, `list` (array) e `javaScriptExpression` (```` ```javascript-browser ````).
- Quando o disparador é um Interactive Grid (seleção por colunas ou região IG): `type` usa `itemColumn=value` … `itemColumnIsNotInList`, `jsExpression`; e `componentType` (`item` ou `column`, padrão `column`) escolhe entre `item` e `column`.

```
clientSideCondition {
    type: itemIsNotNull
    item: P16_CEP
}
```

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`dynamicAction`, `action`)

### layout: sequência, slot, região pai e grid (regiões, itens e botões)
Grupo `layout` de `region`, `pageItem` e `button`:

| Propriedade | Tipo | Obrig. | Padrão | Notas |
|---|---|---|---|---|
| `sequence` | number | sim | | Ordem dentro do slot |
| `slot` | string | sim | | Posição do template (nome APEXlang do slot) |
| `parentRegion` (região) / `region` (item, botão) | ref | não | | `@id` da região pai |
| `startNewLayout` | boolean | sim | `false` | |
| `startNewRow` | boolean | sim | `true` | |
| `newColumn` | boolean | sim | `true` | Aplica-se quando `startNewRow` é `false` |
| `column`, `columnSpan`, `rowSpan` (item/botão), `labelColumnSpan` (item) | string/number | não | | Grid de 12 colunas |
| `rowCssClasses`, `columnCssClasses`, `columnAttributes` | array | não | | |
| `alignment` (item: padrão `leftCenter`; botão no slot BODY) | enum | | | |
| `horizontalAlignment` (botão) | `left`/`right` | | `right` | Slots TOP/BOTTOM |

Slots de página vistos no export: `body`, `contentBody`, `breadcrumbBar`, `dialogsDrawersAndPopups`, `dialogFooter`, `wizardBody`, `wizardButtons`, `afterLogo`, `afterNavigationBar`. Slots de região: `regionBody`, `subRegions`, `tabs`, e de botões `next`, `close`, `delete`, `create`, `edit`, `rightOfInteractiveReportSearchBar`. O nome do slot é o `apexlangName` definido no componente `slot` do page/region template (ver `pageTemplate`).

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`region.layout`, `pageItem.layout`, `button.layout`, `slot`)

### appearance: template, templateOptions (#DEFAULT#), cssClasses e icon
- Região: `appearance { template: @/standard templateOptions: [ #DEFAULT# … ] cssClasses: [ … ] icon: fa-x renderComponents: aboveContent|belowContent }` (`template` aplica-se a tipos com region template; `templateOptions`, `cssClasses` e `icon` só com template definido).
- Item: `appearance { template: @/optional-floating templateOptions … cssClasses … icon formatMask width height valuePlaceholder }`.
- Botão: `appearance { buttonTemplate: @/text (obrig.) hot: false showAsDisabled: false templateOptions cssClasses icon }`.
- Página: `appearance { pageMode pageTemplate|dialogTemplate templateOptions cssClasses mediaType }`.
- `componentAppearance` (região) é o template do **componente interno**: report template de Classic Report, list template, breadcrumb template, layout de Cards, `selectFirstRow`/`fixedRowHeight` de IG, `showNullValuesAs`.

`#DEFAULT#` representa as opções padrão do template; as demais entradas são classes que o template define como opções. Uma opção inválida para o template gera erro de validação.

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html), [Reading APEXlang Syntax](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/reading-apexlang-syntax.html)

### security, config, comments, subscription e advanced (grupos comuns)
- `security { authorizationScheme: @x }`: presente em página, região, item, botão, processo, validação, computação, branch, DA, ação, coluna, entradas de lista/breadcrumb. Itens ainda têm `sessionStateProtection` (`unrestricted` padrão, `checksumRequiredAppLevel`, `checksumRequiredUserLevel`, `checksumRequiredSessionLevel`, `restricted`), `encryptSessionState` (padrão `true`), `escapeSpecialChars` (padrão `true`) e `restrictedChars`. Regiões têm `escapeSpecialChars`. Página tem `authentication` (`required`/`public`), `pageAccessProtection`, `formAutoComplete`, `deepLinking`, `browserCache`.
- `config { buildOption: @x }`: liga o componente a uma build option.
- `comments { comments: … }`: comentário de desenvolvedor.
- `subscription { master: … }`: assinatura de shared component de outra app.
- `advanced { staticId: … }`: o Static ID (o valor que vai após o tipo); `htmlDomId` (regiões, botões, colunas) é o id do DOM.

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Linguagem do código: `language` (sql, plsql, javaScript-mle)
Propriedades de código que aceitam mais de uma linguagem vêm acompanhadas de `language`:
- Expressões: `language: sql|plsql|javaScript-mle` (padrão `plsql`) + `sqlExpression`/`plsqlExpression`/`javaScriptExpression`.
- Function bodies: `language: plsql|javaScript-mle` (padrão `plsql`) + `plsqlFunctionBody`/`javaScriptFunctionBody`.
- Processos `executeCode`: `source { language: plsql|javaScript-mle plsqlCode|javaScriptCode }`, com `location: localDatabase|restEnabledSql` (+ `remoteServer`).

Como o padrão é `plsql`, o export omite `language` para PL/SQL. JavaScript de servidor usa o indicador ```` ```javascript-mle ````; JavaScript de navegador (DAs, page load) usa ```` ```javascript-browser ````.

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html), [Reading APEXlang Syntax](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/reading-apexlang-syntax.html)

---

## 6. Referência: aplicação e página

### app (application.apx): propriedades diretas e filhos
Componente raiz, em `application.apx`. O identificador após `app` é o alias (`app CORLIXHUB (`).

Propriedades diretas (grupo `identification`):

| Propriedade | Tipo | Obrig. | Padrão | Valores |
|---|---|---|---|---|
| `name` | string (≤255) | sim | | |
| `alias` | string (≤80) | sim | | também é o id após `app` |
| `version` | string | sim | `Release 1.0` | |
| `type` | enum | sim | `standard` | `standard`, `library`, `boilerplate`, `theme` |
| `group` | string | não | | grupo de apps |

Filhos possíveis de `app` (shared components declarados nos arquivos de `shared-components/`): `aiAgent`, `appComputation`, `appItem`, `appProcess`, `appSetting`, `authentication`, `authorization`, `automation`, `breadcrumb`, `buildOption`, `classicNavigationBarEntry`, `componentGroup`, `componentSetting`, `concatenatedFile`, `dataLoadDefinition`, `developerComment`, `dynamicTranslation`, `emailTemplate`, `file`, `jsonDualityView`, `jsonSource`, `languageMapping`, `legacyDataLoadDefinition`, `list`, `lov`, `mapBackground`, `page`, `pageGroup`, `plugin`, `pwaScreenshot`, `pwaShortcut`, `reportLayout`, `reportQuery`, `restDataSource`, `role`, `searchConfig`, `shortcut`, `substitution`, `supportingObject`, `taskDefinition`, `textMessage`, `theme`, `workflow`. No export, cada grupo vai para o seu arquivo; o `application.apx` do projeto contém também um filho `substitution APP_NAME (…)`.

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`app`)

### app: grupos de navegação, interface, CSS/JS e formatos (navigation, navigationMenu, navigationBar, userInterface, logo, appFormatMasks, javaScript, css)
| Grupo.propriedade | Tipo | Padrão | Valores / notas |
|---|---|---|---|
| `logo.type` | enum | | `image`, `text`, `imageAndText`, `custom` |
| `logo.imageUrl` / `logo.text` / `logo.customHtml` | string/multiline | | conforme `type` |
| `navigation.homeUrl` (obrig.) / `navigation.loginUrl` | complex | | `{ page: 1 }`, `{ page: LOGIN }` |
| `navigationMenu.listTemplate` | ref | | `@/side-navigation-menu`, `@/top-navigation-menu` |
| `navigationMenu.templateOptions` | array | | quando há list template |
| `navigationMenu.listPosition` | enum | `side` | `top`, `side` |
| `navigationMenu.list` | ref | | `@navigation-menu` |
| `navigationBar.implementation` | enum | `list` | `classic`, `list` (com `list` + `listTemplate` obrigatórios) |
| `userInterface.currentTheme` (obrig.) | ref | | `@universal-theme` |
| `userInterface.globalPage` | integer | | normalmente `0` |
| `userInterface.usersCanChooseThemeStyle` | boolean | `false` | |
| `userInterface.addBuiltWithApexToFooter` | boolean | `true` | |
| `userInterface.autoDismissSuccessMessages` | boolean | `false` | |
| `appFormatMasks.date` / `dateTime` / `timestamp` / `timestampTimeZone` | string | | ex.: `DS` |
| `javaScript.fileUrls` | array | | |
| `javaScript.includeLegacyJavascript` | array enum | | `pre18`, `"18"` |
| `javaScript.includeJqueryMigrate` | boolean | `false` | |
| `css.fileUrls` | array | | `#APP_FILES#custom#MIN#.css` |
| `genAI.service` (ref), `aiConsentMessage`, `requestHandlerProcedure`, `responseHandlerProcedure` | | | serviço de IA da app |

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`app`)

### app: grupos de segurança e sessão (authentication, authorization, security, sessionStateProtection, sessionManagement, databaseSession)
| Grupo.propriedade | Tipo | Padrão | Valores / notas |
|---|---|---|---|
| `authentication.scheme` (obrig.) | select | | esquema atual (`@oracle-apex-accounts` no export) |
| `authentication.configProcedureName`, `publicUser` | string | | |
| `authorization.scheme` | ref | | authorization da app inteira |
| `authorization.runOnPublicPages` | boolean | `false` | |
| `authorization.runOnBackgroundJob` | boolean | `true` | |
| `authorization.sourceForRoleOrGroupSchemes` | enum | `accessControlUserRoleAssignments` | `authenticationScheme`, `customCode` |
| `security.deepLinking` | enum | `false` | `true`, `false` |
| `security.enableDictation` | boolean | `false` | |
| `security.browserCache` | enum | `false` | |
| `security.embedInFrames` | enum | `deny` | `allowSameOrigin`, `allow` |
| `security.referrerPolicy` | enum | `strictOrigin` | `noReferrer`, `sameOrigin`, `strictOriginWhenCrossOrigin`, … |
| `security.htmlEscapingMode` | enum | `extended` | `basic` |
| `security.httpResponseHeaders` | multiline | | |
| `security.runtimeApiUsage` | array enum | | `modifyThisApp`, `modifyOtherApps`, `modifyWorkspaceRepository` |
| `sessionStateProtection.enabled` | boolean | `true` | |
| `sessionStateProtection.bookmarkHashFunction` | enum | `sha2-512bit` | `sha1`, `sha2-256bit`, `sha2-384bit`, `md5` |
| `sessionStateProtection.checksumSalt`, `allowUrlsCreatedAfter` | string/datetime | | |
| `sessionStateProtection.acceptPre202UrlChecksums` | boolean | `false` | |
| `sessionManagement.rejoinSessions` | enum | `false` | `publicSessions`, `allSessions` |
| `sessionManagement.sessionStateCommits` | enum | `endOfRequest` | `immediate` |
| `sessionManagement.maxSessionLength`, `maxSessionIdleTime`, `sessionTimeoutWarning` | integer (s) | | + URLs de timeout |
| `databaseSession.parsingSchema`, `mleEnvironment` | string | | |
| `databaseSession.initPlsqlCode`, `cleanupPlsqlCode` | multiline plsql | | |

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`app`)

### app: globalização, PWA, erros, runtime, disponibilidade e avançado (globalization, progressiveWebApp, errorHandling, runtime, availability, advanced…)
| Grupo.propriedade | Padrão | Valores / notas |
|---|---|---|
| `globalization.primaryLanguage` | `en` | códigos (`pt-br`, `en`, …) |
| `globalization.documentDirection` | | `leftToRight`, `rightToLeft` |
| `globalization.translationMethod` | | `translationApps`, `textMessages` |
| `globalization.languageDerivedFrom` | `appPrimaryLanguage` | `notTranslated`, `browserPreference`, `appPreference`, `itemPreference`, `session` |
| `globalization.autoTimeZone` / `autoCsvEncoding` | `false` / `true` | |
| `progressiveWebApp.enable` / `installable` | `true` / `false` | + `display`, `screenOrientation`, `themeColor`, push notifications |
| `customServiceWorker.mode` | `default` | `custom`, `url` (hooks em `javascript-browser`) |
| `errorHandling.defaultDisplayLocation` | `inlineWithFieldAndInNotification` | `inlineWithField`, `inlineInNotification` |
| `errorHandling.errorHandlingFunctionName` | | ex.: `log_pkg.apex_error_handler` |
| `runtime.friendlyUrls` | `true` | |
| `runtime.allowFeedback` | `false` | |
| `runtime.compatibilityMode` | `26.1` | `24.2`, `21.2`, … `4.0` |
| `runtime.accessibleReadOnlyItems` | `true` | |
| `staticFiles.appFilesPath` / `apexFilesPath` | | |
| `availability.status` | `availableWithDevToolbar` | `available`, `availableDevsOnly`, `restricted`, `unavailable`, `unavailableStatusShownWithPlsql`, `unavailableRedirectToUrl` |
| `availability.buildStatus` | `runAndBuild` | `runOnly` |
| `availability.globalNotificationMessage` | | |
| `rowSearch.tokenize` / `textQueryFunction` | `true` | `searchEngine`, `expertSearch`, `custom` |
| `reportPrinting.type` | `native` | `remote`, `useInstanceSettings` |
| `fileStorage.type` | `database` | `objectStorage` (+ `fileServer`) |
| `advanced.exactSubstitutions` / `passEcid` | `true` | |
| `advanced.emailFromAddress`, `faviconHtml`, `copyrightBanner`, `maxBackgroundPageProcessJobs`, … | | |

Exemplo mínimo válido de `application.apx`:
```
app MINHAAPP (
    name: Minha App
    navigation {
        homeUrl: {
            page: 1
        }
    }
    userInterface {
        currentTheme: @universal-theme
        globalPage: 0
    }
    authentication {
        scheme: @oracle-apex-accounts
    }
)
```

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`app`)

### page: propriedades diretas, filhos e modo da página (appearance, dialog)
Arquivo `pages/pNNNNN-<alias>.apx`. Filhos: `region`, `pageItem`, `button`, `process`, `validation`, `computation`, `branch`, `dynamicAction`, `metaTag`.

| Propriedade | Tipo | Obrig. | Padrão | Notas |
|---|---|---|---|---|
| `page` | number | sim | | é o número após `page` |
| `name` | string | sim | | |
| `alias` | string | não | | não se aplica à Global Page |
| `title` | string | não | | não se aplica à Global Page |
| `pageGroup` | ref | não | | `@administration` |
| `appearance.pageMode` | enum | sim | `normal` | `normal`, `modalDialog`, `nonModalDialog` |
| `appearance.pageTemplate` | ref | sim (normal) | | `@/standard`, `@/login`, `@corlix-standard-page` |
| `appearance.dialogTemplate` | ref | sim (diálogo) | | `@/modal-dialog`, `@/drawer`, `@/wizard-modal-dialog` |
| `appearance.templateOptions`, `cssClasses`, `mediaType` | | | | |
| `dialog.width`, `height`, `maxWidth`, `attributes`, `cssClasses` | | | | só diálogos |
| `dialog.chained` | boolean | sim | `true` | só diálogos |
| `dialog.resizable` | boolean | sim | `true` | só diálogos |
| `navigationMenu.overrideUserInterfaceLevel` | boolean | | `false` | + `list`, `listPosition`, `listTemplate` |
| `navigation.cursorFocus` | enum | | `firstItemOnPage` | `doNotFocusCursor` |
| `navigation.warnOnUnsavedChanges` | boolean | | `true` | |

Desde o 26.1 não existe mais "Default Template" para página: `pageTemplate` é obrigatório (páginas que usavam o default passaram a apontar para o template padrão do tema).

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`page`), [Changed Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html)

### page: JavaScript, CSS, HTML header, help, segurança, cache e erro
| Grupo.propriedade | Tipo | Padrão | Valores / notas |
|---|---|---|---|
| `javaScript.fileUrls` | array | | URLs de arquivos JS (só URLs!) |
| `javaScript.functionAndGlobalVariableDeclaration` | multiline `javascript-browser` | | |
| `javaScript.executeWhenPageLoads` | multiline `javascript-browser` | | |
| `javaScript.includeStandardJavaScriptAndCss` | boolean | `true` | |
| `css.fileUrls` / `css.inline` (css) | | | |
| `htmlHeader.htmlHeader` (html), `pageHtmlBodyAttribute` | | | |
| `headerAndFooter.headerText`, `bodyHeader`, `footerText` | html | | |
| `readOnly.*` | condição | | página inteira somente leitura |
| `security.authorizationScheme` | ref | | **use em páginas administrativas** |
| `security.authentication` | enum | `required` | `public` |
| `security.deepLinking`, `browserCache` | enum | | `true`, `false` |
| `security.pageAccessProtection` | enum | `unrestricted` | `argumentsMustHaveChecksum`, `noArgumentsSupported`, `noUrlAccess` |
| `security.formAutoComplete` | enum | `true` | `false` |
| `sessionManagement.rejoinSessions` | enum | | |
| `advanced.enableMetaTags` | boolean | `false` | |
| `advanced.enableDuplicatePageSubmissions` | enum | `true` | `false` (+ `duplicateSubmissionUrl`) |
| `advanced.reloadOnSubmit` | enum | `onlyForSuccess` | `always` |
| `serverCache.caching` | enum | `false` | `true`, `cacheByUser`, `cacheBySession` (+ `cacheTimeout`, padrão `6Hours`) |
| `errorHandling.inLineErrorNotificationText`, `errorHandlingFunctionName` | | | |
| `help.helpText` | html | | |
| `config.buildOption` | ref | | |

Quase todas essas propriedades "não se aplicam" à Global Page (página 0), que só aceita regiões/itens/botões/DAs e `templateOptions`.

Exemplo mínimo de página normal e de modal:
```
page 30 (
    name: Relatório X
    alias: RELATORIO-X
    title: Relatório X
    appearance {
        pageTemplate: @/standard
        templateOptions: #DEFAULT#
    }
    security {
        authorizationScheme: @admin-rh
        pageAccessProtection: argumentsMustHaveChecksum
    }
)

page 31 (
    name: Editar X
    alias: EDITAR-X
    title: Editar X
    appearance {
        pageMode: modalDialog
        dialogTemplate: @/modal-dialog
        templateOptions: #DEFAULT#
    }
    dialog {
        chained: false
    }
)
```

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`page`)

### pageGroup (page-groups.apx)
Agrupa páginas para organização no Builder. Propriedades: `name` (obrig.), `staticId` (obrig., o id após o tipo), `sequence` (integer), `description.description`. A página referencia com `pageGroup: @<id>`. Só se aplica a apps `standard`.

```
pageGroup administration (
    name: Administration
)
```

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`pageGroup`)

### metaTag (filho de page)
Meta tags HTML da página (exige `page.advanced.enableMetaTags`, que se aplica a páginas com autenticação). Propriedades: `name` (padrão `description`), `value` (multiline, obrig.), `advanced.staticId`, `serverSideCondition`, `config.buildOption`, `comments`.

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`metaTag`)

---

## 7. Referência: regiões

### region: propriedades comuns a todos os tipos
`region <staticId> ( … )`, filho de `page`.

| Propriedade | Tipo | Obrig. | Padrão | Notas |
|---|---|---|---|---|
| `name` | string | sim | | nome no Page Designer; vira título se `title` vazio |
| `title` | string | não | | só aparece se o template mostra título |
| `type` | enum | sim | | ver tabela de tipos |
| `layout.*` | | | | `sequence`, `slot` obrigatórios; `parentRegion: @x` para sub-região |
| `appearance.template` | ref | | | region template (`@/standard`, `@/blank-with-attributes`, `@/title-bar`, `@/interactive-report`, `@/buttons-container`, `@/inline-dialog`, `@/tabs-container`, `@/cards-container`) |
| `appearance.templateOptions`, `cssClasses`, `icon` | | | | |
| `appearance.renderComponents` | enum | | `aboveContent` | `belowContent` |
| `headerAndFooter.headerText` / `footerText` | html | | | |
| `advanced.htmlDomId` | string | | | id no DOM |
| `advanced.staticId` | string | sim | | o id após `region` |
| `advanced.customAttributes`, `regionImage`, `imageTagAttributes` | | | | |
| `advanced.regionDisplaySelector` | boolean | | `false` | aparece em Region Display Selector |
| `advanced.excludeTitleFromTranslation` | boolean | | `false` | |
| `advanced.savedReportMappingIdentifier` | string | | | IR/IG; gerado pelo APEX |
| `accessibility.useLandmark` | boolean | | `true` | + `landmarkType` (`banner`, `complementary`, `contentInfo`, `form`, `main`, `navigation`, `region`, `search`), `landmarkLabel` |
| `image.fileUrl`, `accessibleDescription`, `customAttributes` | | | | templates com imagem |
| `serverSideCondition`, `readOnly` | | | | |
| `security.authorizationScheme`, `escapeSpecialChars` (`true`) | | | | |
| `serverCache.caching` | enum | | `false` | `true`, `cacheByUser`, `cacheBySession` (+ `cacheTimeout`, `dependsOnItems`) |
| `customization.customizable` | enum | | `false` | `shownByDefault`, `notShownByDefault` (+ `name`) |
| `config.buildOption`, `comments.comments` | | | | |

Filhos (conforme tipo): `column` (IR, Classic Report, Tabular Form, IG e template components), `columnGroup` (IR, IG), `savedReport` (IR, IG), `action` (Cards e template components), `series` e `axis` (chart), `facet`/`facetGroup` (faceted search), `filter`/`filterGroup` (smart filters), `layer` (map), `searchSource` (search), `parameter`.

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`region`)

### region type: valores válidos de `type`
| `type` | Região |
|---|---|
| `staticContent` | Static Content (HTML/texto) |
| `dynamicContent` | Dynamic Content (função PL/SQL ou MLE que retorna HTML) |
| `plSqlDynamicContent` | PL/SQL Dynamic Content legado |
| `form` | Form |
| `interactiveReport` | Interactive Report |
| `interactiveGrid` | Interactive Grid |
| `classicReport` | Classic Report |
| `tabform` | Tabular Form legado |
| `cards` | Cards |
| `chart` | Chart (JET) |
| `simpleChart`, `svgChart` | gráficos legados |
| `breadcrumb` | Breadcrumb |
| `list` | List |
| `listView`, `columnToggleReport`, `reflowReport` | legados mobile |
| `calendar` / `legacyCalendar` | Calendar / calendário legado (depreciado) |
| `tree` / `classicTree` | Tree |
| `map` | Map |
| `facetedSearch` / `smartFilters` | Faceted Search / Smart Filters |
| `search` | Search |
| `regionDisplaySelector` | Region Display Selector |
| `helpText` | Help Text |
| `url` | URL |
| `dataUploadColMapping` | mapeamento de upload de dados |
| `workflowDiagram` | Workflow Diagram |
| `themeTemplateComponent/<nome>` | template components do tema: `actions`, `avatar`, `badge`, `comments`, `contentRow`, `mediaList`, `metricCard`, `timeline`, `contextualInfoTemplateComponent`, `emptyStateTemplateComponent`, `listItemTemplateComponent`, `avatarTemplateComponent`, `badgeTemplateComponent` |
| `appTemplateComponent/<nome>` | template component plug-in da app |
| `plugin/<pluginName>` | plug-in de região (`pluginName` = APEXlang Name do plug-in) |

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`region.type`), [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html) (APEXlang Name para plug-ins)

### region source: fonte de dados (location, type, tableName, sqlQuery, htmlCode…)
Grupo `source` (aplica-se conforme o tipo suporta fonte):

| Propriedade | Quando | Notas |
|---|---|---|
| `location` | tipos com fonte de dados | `localDatabase` (padrão), `restEnabledSql`, `restSource`, `jsonDualityView`, `jsonSource`, `sampleData` |
| `type` | location local/remota | padrão `TABLE` (omitido); no export aparece `sqlQuery` para query SQL; há também função que retorna SQL e property graph |
| `tableOwner`, `tableName` | type = tabela | |
| `includeRowidColumn` | tabela | padrão `false` |
| `whereClause` | tabela/graph | sql |
| `orderByClause` | IG, IR, map, form | |
| `sqlQuery` | type SQL | ```` ```sql ```` |
| `language` + `plsqlFunctionBody`/`javaScriptFunctionBody` | function body returning SQL | |
| `graphOwner`, `graphName`, `matchClause`, `columnsClause` | property graph | |
| `remoteServer` | REST-enabled SQL | |
| `restSource`, `jsonDualityView`, `jsonSource` | outras locations | ref |
| `sampleData` | sampleData | `employees`, `tasks`, `products`, `projects` |
| `htmlCode` | Static Content | html |
| `text` | tipos de texto puro | |
| `plsqlCode` / `plsqlFunctionBody` | PL/SQL Dynamic Content / Dynamic Content | |
| `list` / `breadcrumb` | List / Breadcrumb | ref |
| `filteredRegion` | Faceted Search / Smart Filters | ref |
| `pageItemsToSubmit` | tipos com AJAX | array de nomes de item |
| `optimizerHint` | | |
| `useGenericColumnNames`, `genericColumnCount` | Classic Report com SQL dinâmico | |

Grupos relacionados: `orderBy` (`type: staticValue|item`, `orderByClause`, `item`), `localPostProcessing` (para REST/duality/JSON: `whereOrderByClause`, `sqlQuery`, `plsqlFunctionBody`), `externalFilterAndOrderBy`, `restSynchronization.useLocalTable`, `remoteCache` (`allUsers`, `user`, `session` + `timeout`), `dataProfile.nestedRows`.

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`region.source`)

### Static Content (`type: staticContent`)
Região de HTML fixo ou contêiner de outras regiões/itens/botões. Fonte em `source.htmlCode` (html). Sem `source`, serve como contêiner (ex.: região "Buttons" num diálogo, com `slot: dialogFooter` e template `@/buttons-container`, ou seção de formulário com `headerText`).

````
region boas-vindas (
    name: Boas-vindas
    type: staticContent
    source {
        htmlCode:
            ```html
            <p class="cx-descricao">Olá, &G_NOME_USUARIO.</p>
            ```
    }
    layout {
        sequence: 10
        slot: body
    }
    appearance {
        template: @/standard
        templateOptions: [
            #DEFAULT#
            t-Region--noUI
        ]
    }
)
````

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`region`)

### Dynamic Content (`type: dynamicContent`)
Região cujo HTML é retornado por uma função: `source { language: plsql|javaScript-mle (padrão plsql) plsqlFunctionBody|javaScriptFunctionBody pageItemsToSubmit }`. Use para HTML gerado no servidor (ex.: organograma da p3 via `pkg_organograma.render`). Lembre de escapar dados (`apex_escape.html`) dentro da função, porque o HTML retornado é emitido como está.

````
region organograma (
    name: Organograma
    type: dynamicContent
    source {
        plsqlFunctionBody:
            ```plsql
            return pkg_organograma.render(:P3_ID_FOCO);
            ```
        pageItemsToSubmit: P3_ID_FOCO
    }
    layout {
        sequence: 10
        slot: body
    }
)
````

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`region.source`), [APEX_ESCAPE](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_ESCAPE.html)

### Form (`type: form`) e o grupo `edit` (enabled, allowedOperations, lost update)
Região Form ligada a tabela/view/SQL. Itens do form apontam para ela com `source { formRegion: @<form> column: COL dataType: … }`. Processos típicos: `formInitialization` (antes do header) e `formAutoRowProcessing` (após submit), ambos com `formRegion: @<form>`.

Grupo `edit` (aplica-se a Form e Interactive Grid):

| Propriedade | Tipo | Padrão | Notas |
|---|---|---|---|
| `enabled` | boolean | **`false`** | sem ele, a região é só leitura |
| `allowedOperations` | array enum | | `add`, `update`, `delete` (quando `enabled`) |
| `allowedRowOperationsColumn` | string | | coluna que diz se a linha pode ser alterada/excluída |
| `lostUpdateType` | enum | `rowValues` | `rowVersionColumn` (+ `rowVersionColumn` obrig.) |
| `addRowIfEmpty` | boolean | `true` | só IG com `add` |

Grupo `editAuthorization`: `add`, `update`, `delete` (refs a authorization schemes, por operação permitida).

Exemplo real (p16):
```
region cadastro-de-empresas (
    name: Cadastro de Empresas
    type: form
    source {
        location: localDatabase
        tableName: EMPRESA
    }
    layout {
        sequence: 10
        slot: contentBody
    }
    appearance {
        template: @/blank-with-attributes
        templateOptions: #DEFAULT#
    }
    edit {
        enabled: true
        allowedOperations: [
            add
            update
            delete
        ]
    }
)
```

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`region.edit`, `region.editAuthorization`), [Reading APEXlang Syntax](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/reading-apexlang-syntax.html)

### Interactive Report (`type: interactiveReport`): grupos da região
Grupos específicos de IR:

| Grupo.propriedade | Padrão | Valores / notas |
|---|---|---|
| `link.linkColumn` | `exclude` | `singleRowView`, `customTarget` |
| `link.uniquelyIdentifyRowsBy` | `rowid` | `uniqueColumn` (+ `uniqueColumn`) — para single row view |
| `link.target` | | obrig. com `customTarget` |
| `link.linkIcon`, `linkAttributes`, `authorizationScheme`, `conditionType`… | | ícone e condição do link |
| `pagination.type` | | `rowRangesXToYOfZ`, `rowRangesXToY` |
| `pagination.displayPosition` | `bottomRight` | `bottomLeft`, `topLeft`, `topRight`, `topAndBottomLeft`, `topAndBottomRight` |
| `pagination.maxRowsToDisplay` | | |
| `searchBar.includeSearchBar` / `searchField` / `finderDropDown` | `true` | |
| `searchBar.reportsSelectList` | | |
| `searchBar.rowsPerPageSelector` | `false` | |
| `actionsMenu.includeActionsMenu` e cada item (`filter`, `selectColumns`, `rowsPerPage`, `sort`, `controlBreak`, `highlight`, `compute`, `aggregate`, `chart`, `groupBy`, `pivot`, `flashback`, `saveReport`, `reset`, `help`, `download`, `subscription`) | `true` | desligue com `false` |
| `actionsMenu.savePublicReport` | `false` | + `savePublicReportAuthorization` |
| `download.formats` | `csv html excel pdf` | + `authorization`, `sendAsEmail`, `csvSeparator`, `filename`… |
| `heading.fixedTo` | `page` | `none`, `region` (+ `maxReportHeight`) |
| `iconView.show` / `detailView.show` | `false` | views alternativas |
| `singleRowView.excludeNullValues` / `onlyDisplayedColumns` | `false` | |
| `messages.whenNoDataFound`, `whenMoreDataFound` | | |
| `componentAdvanced.regionAlias`, `reportIdItem`, `oracleTextIndexColumn`, `emailFromAddress`, `maxRowsPerPageInSelector` | | |
| `componentAppearance.showNullValuesAs` | | |
| `genAI.naturalLanguageSupport` | `false` | NL2IR; `defaultSearchMode` (`searchModeAI` padrão, `searchModeRow`), `reportContext` |
| `page.*`, `pageHeader.*`, `columnHeadings.*`, `columns.*`, `pageFooter.*`, `output.*` | | formatação de PDF/XLSX do download |
| `description.description` | | |

Filhos: `column` (uma por coluna da query), `columnGroup`, `savedReport` (pelo menos o primário).

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`region` com `region.type = interactiveReport`), [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### Interactive Report column: propriedades de `column` em IR
`column <NOME_COLUNA> ( … )` dentro da região IR.

| Grupo.propriedade | Padrão | Valores / notas |
|---|---|---|
| `type` (obrig.) | | `plainText`, `plainTextBasedOnLov`, `hidden`, `link`, `richText`, `displayImage`, `downloadBlob`, `percentGraph`, `removeHtml`, `rowSelector`, `themeTemplateComponent/…`, `appTemplateComponent/…`, `plugin/…` |
| `heading.heading` | | obrig. (exceto rowSelector) |
| `heading.alternativeLabel`, `alignment` (`start`) | | |
| `singleRowView.useColumnHeading` (`true`) / `label` | | |
| `lov.lov` | | ref; obrig. com `plainTextBasedOnLov` |
| `layout.sequence` (obrig.), `columnAlignment` (`start`), `group` (ref columnGroup) | | |
| `appearance.cssClasses`, `formatMask` | | |
| `columnFormatting.htmlExpression` | | html, com `#COL#` |
| `link.target`, `linkText`, `linkAttributes` | | coluna `link` |
| `source.primaryKey` (`false`), `dataType` (obrig.), `availableOnClient` (`false`), `valueProtected` (`true`) | | `dataType` no export: `STRING`, `NUMBER`, `DATE`, `BOOLEAN` |
| `columnFilter.type` | `defaultBasedOnColumnType` | `none`, `definedLovExactMatch`, `definedLovWordContains`, `namedLovExactMatch`, `namedLovWordContains` |
| `enableUsersTo.hide/sort/filter/highlight/controlBreak/aggregate/compute/chart/groupBy/pivot` | `true` | |
| `advanced.htmlDomId`, `endUserAlias` | | `endUserAlias` gerado (A, B, C…) |
| `rowSelection.*` | | coluna `rowSelector` (`enableMultiSelect`, `showSelectAll`, `currentSelectionPageItem`) |
| `security.authorizationScheme`, `escapeSpecialChars` (`true`) | | |
| `genAI.columnContext`, `referenceDataType` | | NL2IR |

Exemplo real (p15):
```
column STATUS (
    type: plainTextBasedOnLov
    heading {
        heading: Status
    }
    lov {
        lov: @boolean
    }
    layout {
        sequence: 15
    }
    source {
        dataType: BOOLEAN
    }
    advanced {
        endUserAlias: O
    }
)
```

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`column`, filho de `region` IR)

### Interactive Report savedReport, displayColumn, sort, filter (relatório salvo)
`savedReport <staticId> ( … )` define relatórios salvos do IR. O export sempre traz o relatório primário (`visibility: primaryDefault`, observado no export), com as colunas exibidas em `displayColumn`.

| Propriedade | Padrão | Valores |
|---|---|---|
| `visibility` (obrig.) | | `primaryDefault`, `alternativeDefault`, `public`, `private` |
| `name` | | obrig. exceto no primário |
| `view.default` | `REPORT` | |
| `view.rowsPerPage` | | ex.: `50` |
| `view.chart` / `groupBy` / `pivot` | `false` | |
| `chart.*`, `axisTitle.*`, `sort.by` | | gráfico salvo |
| `flashback.minutesAgo` | | |
| `settings.appUser` | | relatórios públicos |

Filhos: `displayColumn <COL> ( sequence: N )` (colunas visíveis e ordem), `sort <COL> ( sort { direction: asc|desc nulls: first|last sequence: N } )`, `filter` (`condition { type: column|rowSearch|rowExpression column operator value … }`), `controlBreak`, `aggregate`, `computation`, `highlight`, `groupByColumn`, `groupByAggregate`, `groupBySort`, `pivotColumn`, `pivotRowColumn`, `pivotAggregate`, `pivotSort`. Operadores de filtro: `=`, `!=`, `>`, `>=`, `<`, `<=`, `between`, `isNull`, `isNotNull`, `like`, `notLike`, `in`, `notIn`, `contains`, `doesNotContain`, `regexp`, `isInTheLast`, `isNotInTheLast`, `isInTheNext`, `isNotInTheNext`.

```
savedReport primary (
    visibility: primaryDefault
    view {
        rowsPerPage: 50
    }
    displayColumn NOME (
        sequence: 2
    )
)
```

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`savedReport`, `displayColumn`, `sort`, `filter`)

### Interactive Grid (`type: interactiveGrid`): grupos da região
| Grupo.propriedade | Padrão | Valores / notas |
|---|---|---|
| `edit.enabled` | `false` | ligar edição; ver grupo `edit` no Form |
| `edit.allowedOperations` | | `add`, `update`, `delete` |
| `edit.addRowIfEmpty` | `true` | com `add` |
| `edit.lostUpdateType` | `rowValues` | `rowVersionColumn` |
| `toolbar.show` | `true` | |
| `toolbar.controls` | | `searchCol`, `searchField`, `actionsMenu`, `resetButton`, `saveButton` |
| `toolbar.addButtonLabel` | | |
| `enableUsersTo.savePublicReport` | `false` | + `savePublicReportAuthorization` |
| `enableUsersTo.flashback` / `defineChartView` / `download` | `true` | |
| `download.formats` | | `csv`, `html`, `pdf`, `excel` |
| `componentAppearance.selectFirstRow` / `fixedRowHeight` | `true` | |
| `heading.fixedTo` | `page` | `none`, `region` (+ `fixedReportHeight`) |
| `pagination.type`, `showTotalCount` (`false`) | | |
| `iconView.*`, `detailView.*` | | views alternativas |
| `masterDetail.masterRegion` | | ref à região mestre |
| `help.helpText` | | |
| `componentAdvanced.initJavaScriptFunction` | | `javascript-browser` |
| `componentAdvanced.oracleTextIndexColumn`, `emailFromAddress` | | |

Processo de gravação: `process … ( type: interactiveGridAutoRowProcessing editableRegion: @<ig> … )` (o processo tem `editableRegion`, e `serverSideCondition.executionScope` `forCreatedAndModifiedRows`/`allSubmittedRows`). No Page Designer, ligar *Edit › Enabled* cria esse processo automaticamente; ao escrever o APEXlang à mão, declare o processo você mesmo (inferência a partir da doc do Builder; valide).

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`region` IG, `process`), [Making an Existing Interactive Grid Editable](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/making-an-existing-interactive-grid-editable.html)

### Interactive Grid column: propriedades de `column` em IG
| Grupo.propriedade | Padrão | Valores / notas |
|---|---|---|
| `columnName`, `type` (obrig.) | | `type` é "SUPPORTED UI" (string): tipos de item/coluna (a referência lista, entre outros, `actionsMenu`, `checkbox`, `checkboxGroup`, `htmlExpression`, `link`, `radioGroup`, `rowSelector`, `selectList`, `plugin/…`; o exemplo gerado usa `staticContent`) |
| `heading.heading`, `alignment`, `alternativeLabel` | | |
| `lov.type` | | `sharedComponent`, `sqlQuery`, `staticValues`, `functionBody` |
| `cascadingLov.parentColumns`, `itemsToSubmit`, `parentRequired` (`true`) | | |
| `layout.sequence` (obrig.), `columnAlignment`, `group`, `useGroupFor` (`both`), `stretch` (`never`/`always`) | | |
| `appearance.cssClasses`, `icon`, `formatMask`, `width`, `height`, `valuePlaceholder` | | |
| `validation.valueRequired` (`false`), `maxLength` | | |
| `source.type` | `databaseColumn` | `sqlExpression`, `none` |
| `source.databaseColumn` / `sqlExpression` | | |
| `source.dataType` | | `varchar2`, `number`, `date`, `timestamp…`, `clob`, `blob`, `boolean`, `rowid`, … |
| `source.queryOnly` / `primaryKey` | `false` | |
| `masterDetail.masterColumn` | | |
| `default.type` | | `static`, `item`, `sqlQuerySingleValue`, `sqlQueryMultipleValues`, `expression`, `functionBody`, `sequence` |
| `default.duplicateCopiesExistingValue` | `true` | |
| `sessionState.dataType` | `varchar2` | `clob`, `boolean` |
| `columnFilter.enabled` (`true`), `lovType` (`distinctColumn`), `textCase` (`mixed`), `exactMatch` (`true`) | | |
| `exportPrinting.includeInExportPrint` | `true` | |
| `enableUsersTo.sort` / `controlBreakAggregate` / `hide` | `true` | |
| `advanced.htmlDomId`, `cssClasses`, `customAttributes`, `columnInitJavaScriptFunction`, `initJavaScriptFunction` | | |
| `readOnly.*` + `readOnly.execute` (`once`/`forEachRow`) | | |

Saved reports de IG: `savedReport` com `visibility: primary|alternative|public|private`, `view { default rowsPerPage stretchColumns(true) }`, filhos `displayColumn`, `sort`, `filter`, `highlight`, `controlBreak`, `aggregate`.

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`column` e `savedReport` filhos de `region` IG; EBNF `column-g`)

### Classic Report (`type: classicReport`) e suas colunas
Região:

| Grupo.propriedade | Padrão | Notas |
|---|---|---|
| `componentAppearance.templateType` | `theme` | `predefined` |
| `componentAppearance.template` | | ref ao report template (`@/standard`, `@chat-mensagens`) ou, se predefined, `html`, `verticalReport`, `csv`, `xml` |
| `componentAppearance.templateOptions`, `cssClasses`, `customAttributes`, `showNullValuesAs` | | `t-Report--stretch` etc. |
| `pagination.type` | | `rowRangesXToYNoPagination`, `rowRangesXToYOfZNoPagination`, `rowRangesXToYOfZWithPagination`, `setPaginationLinks`, `setPaginationSelectList`, `setPaginationSearchEngine`, `externalPaginationButtons`, `nextAndPreviousLinks` |
| `pagination.partialPageRefresh` | `true` | |
| `reportLayout.numberOfRowsType` / `numberOfRows` | `staticValue` / `15` | ou `itemValue` + `item` |
| `heading.type` | `customHeadings` | `columnNames`, `columnNamesInitcap`, `plsqlFunctionBody`, `none` |
| `breakFormatting.breakColumns` | | `col1`, `cols1-2`, `cols1-3` |
| `download.csvExportEnabled` | `false` | + `linkText`, `filename`, `csvSeparator` |
| `printing.enabled` | `false` | |
| `externalProcessing.enabled` | `false` | |
| `componentAdvanced.stripHtml` (`false`), `sortNulls` (`last`) | | |
| `performance.maxRowsToProcess`, `lazyLoading` | | |
| `messages.whenNoDataFound`, `whenMoreDataFound` | | |

Coluna (`column <NOME>`): `reportColumnQueryId`, `derivedColumn` (gerados; preserve), `type` (padrão `plainText`; `plainTextBasedOnLov`, `richText`, `link`, `displayImage`, `downloadBlob`, `percentGraph`, `hidden`, …), `heading.heading`/`alignment`, `lov { type: sharedComponent lov: @x }`, `layout.sequence`/`columnAlignment`, `appearance.formatMask`, `link { target linkText linkAttributes }`, `columnFormatting { htmlExpression cssClasses cssStyle highlightWords }`, `sorting { defaultSequence (1–8) direction sortable(false) }`, `exportPrinting`, `security`.

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`region` classicReport, `column` de Classic Report)

### Cards (`type: cards`) e ações de card (`action`)
| Grupo.propriedade | Padrão | Notas |
|---|---|---|
| `componentAppearance.layout` | `grid` | `float`, `horizontal` |
| `componentAppearance.gridColumns` | | `2`–`5` (layout grid) |
| `componentAppearance.cssClasses` | | |
| `card.primaryKeyColumn1` / `primaryKeyColumn2` | | obrig. com mídia/ícone BLOB |
| `card.cssClasses` | | |
| `title`, `subtitle`, `body`, `secondaryBody` | | cada um: `advancedFormatting` (`false`) + `column` + `cssClasses`, ou `advancedFormatting: true` + `htmlExpression` (html, `&COL.`) |
| `iconAndBadge.iconSource` | | `initials`, `iconClass`, `iconClassColumn`, `imageUrl`, `imageBlobColumn` (+ colunas, `iconPosition` `start`, `badgeColumn`, `badgeLabel`) |
| `media.source` | | `imageUrl`, `urlColumn`, `blobColumn` (+ `position` `body`/`first`/`background`, `appearance` `square`/`widescreen`, `sizing` `fit`/`cover`) |
| `blobAttributes.mimeTypeColumn`, `lastUpdatedColumn` | | mídia BLOB |
| `pagination.type`, `cardsPerPage` (`15`), `showTotalCount` | | |
| `messages.whenNoDataFound`, `noDataFoundIcon` | | |

Filho `action` (botões/links do card): `type` (`button` padrão, `fullCard`, `title`, `subtitle`, `media`), `label`, `layout { position: primary|secondary sequence }`, `behavior { type: redirectThisApp|redirectOtherApp|redirectUrl|triggerAction target targetUrl linkAttributes }`, `appearance { displayType: text|icon|textWithIcon icon hot cssClasses }`, `serverSideCondition` (+ `executeCondition`), `security`.

Exemplo real (Home, resumido):
````
region comunicados (
    name: Comunicados
    type: cards
    source {
        type: sqlQuery
        sqlQuery:
            ```sql
            select id_comunicado, titulo, resumo, imagem, mime_type
              from comunicado
             where id_empresa = :G_ID_EMPRESA
            ```
    }
    layout {
        sequence: 20
        slot: body
    }
    componentAppearance {
        layout: horizontal
    }
    card {
        primaryKeyColumn1: ID_COMUNICADO
    }
    title {
        column: TITULO
    }
    body {
        column: RESUMO
    }
    media {
        source: blobColumn
        blobColumn: IMAGEM
        position: first
        sizing: cover
    }
    blobAttributes {
        mimeTypeColumn: MIME_TYPE
    }
)
````

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`region` cards, `action` filho de `region`)

### Chart (`type: chart`), `series` e `axis`
Região:

| Grupo.propriedade | Padrão | Valores / notas |
|---|---|---|
| `chart.type` | `bar` | `area`, `bar`, `boxPlot`, `bubble`, `combination`, `statusMeterGauge`, `donut`, `funnel`, `gantt`, `line`, `lineWithArea`, `pie`, `polar`, `pyramid`, `radar`, `range`, `scatter`, `stock` |
| `chartAppearance.orientation` | `vertical` | `horizontal` |
| `chartAppearance.stack`, `stackLabel` | off | |
| `chartLayout.height`, `maxWidth` | | |
| `title.title` | | |
| `legend.show` | on | + `position` (`auto`, `start`, `end`, `top`, `bottom`), `hideAndShowBehavior` |
| `tooltip.show` / `showSeriesName` / `showGroupName` / `showValue` | `true` | |
| `animation.onDisplay` | `auto` | `alphaFade`, `zoom`, `none` |
| `animation.onDataChange` | `auto` | `slideToLeft`, `slideToRight`, `none` |
| `dataCursor.cursor` / `behavior` | `auto` | |
| `settings.zoomAndScroll` | `false` | `delayed`, `delayedScrollOnly`, `live`, `liveScrollOnly` |
| `settings.timeAxisType`, `initialZooming`, `pieSelectionEffect`, `renderAs` (stock) | | |
| `multiSeriesChartData.fillGapsInChartData` | `true` | + `sortOrder` (`labelAsc`) |
| `value.*` (pie/donut/dial/funnel) | | `format`, `decimalPlaces`, `formatScaling` |
| `gauge.*` | | status meter |
| `autoRefresh.interval` | | |
| `componentAdvanced.initJavaScriptFunction` | | |

`series <id>`: `name`, `type` (depende do tipo do gráfico), `execution.sequence`, `source` (mesmas opções da região, inclusive `location: regionSource` para reaproveitar a query da região, `pageItemsToSubmit`), `columnMapping` (`label`, `value`, `seriesName`, `low`/`high`/`open`/`close`/`volume`, `x`/`y`/`z`, Gantt: `taskId`, `taskName`, `taskStartDate`, `taskEndDate`, …; `valueAggregation`), além de grupos de aparência e rótulo (no export: `appearance { color }`, `label { show position }`).

`axis <x|y|…>`: `name`, `showAxis` (on), `title`, `value { min max format decimalPlaces formatScaling baselineScaling scale step }`, `appearance.position`, `majorTicks { show minStep }`, `minorTicks { show step }`, `timeScale`, `zoomScale`, fontes do título.

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`region` chart, `series`, `axis`)

### Breadcrumb e List como regiões (`type: breadcrumb`, `type: list`)
- **Breadcrumb**: `source { breadcrumb: @breadcrumb }` e `componentAppearance { breadcrumbTemplate: @/breadcrumb templateOptions }`; normalmente no slot `breadcrumbBar` com template de região `@/title-bar`.
- **List**: `source { list: @minha-lista }` e `componentAppearance { listTemplate: @/links-list templateOptions }`.

```
region breadcrumb (
    name: Breadcrumb
    type: breadcrumb
    source {
        breadcrumb: @breadcrumb
    }
    layout {
        sequence: 10
        slot: breadcrumbBar
    }
    appearance {
        template: @/title-bar
        templateOptions: [
            #DEFAULT#
            t-BreadcrumbRegion--useBreadcrumbTitle
        ]
    }
    componentAppearance {
        breadcrumbTemplate: @/breadcrumb
        templateOptions: #DEFAULT#
    }
)
```

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`region.source`, `region.componentAppearance`)

### Faceted Search e Smart Filters (`facet`, `facetGroup`, `filter`, `filterGroup`)
Regiões `facetedSearch` e `smartFilters` filtram outra região indicada em `source { filteredRegion: @relatorio }`. Filhos:
- `facet`: `type` (`checkboxGroup`, `inputField`, `radioGroup`, `range`, `search`, `selectList`, `plugin/…`), grupos `label`, `lov`, `cascadingLov`, `layout`, `appearance`, `listEntries`, `actionsMenu`, `source`, `multipleValues`, `default`, `dependingOn`, `serverSideCondition`, `security`. `name` padrão `P#PAGE_ID#_NEW` (facetas são itens de página).
- `facetGroup`/`filterGroup`: agrupam `checkbox` filhos; `filter`: equivalente da faceta para Smart Filters.

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`facet`, `facetGroup`, `filter`, `filterGroup`)

### Map (`type: map`) e `layer` (resumo)
Região `map`: `map { background: default|builtIn|sharedComponent standard darkMode height (640) }`, `controls { navigationBar (zoomAndCompass) navigationBarPosition options [mousewheelZoom rectangleZoom scaleBar overviewMap infiniteMap getBrowserLocation circleTool distanceTool] }`, `initialPositionAndZoom`, `boundingBox`, `legend`, `attributes { unitSystem messagesPosition copyrightNotice }`. Cada camada é um filho `layer` com fonte, geometria e estilo próprios.

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`region` map, `layer`)

### Template Component regions (`themeTemplateComponent/…`, `appTemplateComponent/…`)
Regiões de template component (ex.: `themeTemplateComponent/contentRow`, `…/metricCard`, `…/badge`) exibem dados de uma fonte com um template parcial/relatório. Propriedades relevantes: `componentAppearance.display` (obrig.; modo de exibição), `pagination.type` (`SET` padrão) + `entitiesPerPage` (15) ou `initialEntitiesCount` (scroll), `rowSelection.type` (`focusOnly`, `singleSelection`, `multipleSelection`) + itens de seleção, `entityTitle { singular plural }`, `messages.whenNoDataFound`. Colunas (`column` com `columnName`, `show`, `source.dataType`, `heading`, `layout`) e `action` filhos (com `menu` e `triggerAction`) seguem os slots do template component. Os atributos específicos de cada template component não constam da referência genérica.

Exemplo da doc:
````
region employees (
    name: Employees
    type: themeTemplateComponent/contentRow
    source {
        location: localDatabase
        type: sqlQuery
        sqlQuery:
            ```sql
            select EMPNO, ENAME, DNAME from EMP_DEPT_V
            ```
    }
)
````

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`region`, `column`, `action`), [Reading APEXlang Syntax](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/reading-apexlang-syntax.html)

### Outros tipos de região (calendar, tree, search, regionDisplaySelector, helpText, url, workflowDiagram, legados)
- `calendar`: calendário atual (o `legacyCalendar` é depreciado e impede o export APEXlang).
- `tree` / `classicTree`: árvore hierárquica.
- `search` + filhos `searchSource`: pesquisa sobre search configurations.
- `regionDisplaySelector`: mostra abas/links para regiões com `advanced.regionDisplaySelector: true`.
- `helpText`, `url`, `workflowDiagram`, `dataUploadColMapping`.
- Legados: `plSqlDynamicContent`, `tabform` (Tabular Form, com colunas próprias), `listView`, `columnToggleReport`, `reflowReport`, `simpleChart`, `svgChart`.
- `genAI { enabled agent service systemPrompt welcomeMessage }`: tipos com suporte a IA (assistente).

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`region.type`), [Deprecated Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/deprecated-features.html)

---

## 8. Referência: itens, botões, processamento e Dynamic Actions

### pageItem: propriedades comuns (name, type, label, layout, appearance, validation)
`pageItem <NOME> ( … )`, filho de `page`. O identificador é o nome do item (`P16_CEP`); o default da propriedade `name` é `P#PAGE_ID#_NEW`.

| Grupo.propriedade | Tipo | Padrão | Notas |
|---|---|---|---|
| `type` (obrig.) | string "SUPPORTED UI" | | ver seção de tipos |
| `label.label` | string | | itens visíveis |
| `label.alignment` | enum | `rightCenter` | `above`, `below`, `left`, `leftCenter`, `right`, … (o export usa `left`) |
| `label.tableCellAttributes` | array | | |
| `layout.sequence`, `slot` (obrig.), `region` (`@x`) | | | `slot: regionBody` dentro de região |
| `layout.alignment` | enum | `leftCenter` | |
| `layout.startNewRow` / `newColumn` | boolean | `true` | `startNewRow: false` = mesma linha |
| `layout.column`, `columnSpan`, `rowSpan`, `labelColumnSpan`, CSS da coluna/linha | | | |
| `appearance.template` | ref | | `@/optional-floating`, `@/required-floating`, `@/hidden`, … |
| `appearance.templateOptions`, `cssClasses`, `icon`, `formatMask`, `width`, `height`, `valuePlaceholder` | | | conforme o tipo |
| `validation.valueRequired` | boolean | `false` | |
| `validation.maxLength` | number | | |
| `advanced.cssClasses`, `customAttributes`, `optionHtmlAttributes`, `preText`, `postText` (html) | | | |
| `advanced.warnOnUnsavedChanges` | enum | | `ignore` |
| `advanced.initJavaScriptFunction` | `javascript-browser` | | tipos com init JS |
| `quickPicks.*` | | | `label1..10`/`value1..10` ou `sqlQuery` |
| `help.inlineHelpText`, `helpText` | html | | |
| `serverSideCondition`, `readOnly` (+ `readOnlyHtmlAttributes`) | | | |
| `security.sessionStateProtection` | enum | `unrestricted` | `checksumRequiredSessionLevel` em PKs |
| `security.encryptSessionState` / `escapeSpecialChars` | boolean | `true` | |
| `security.restrictedChars` | enum | | `alphanumWithSpace`, `webSafe`, `noSpecialChar`, `noSpecialCharNoNewline`, `workspaceSchema`, … |
| `security.authorizationScheme`, `config.buildOption`, `comments` | | | |
| `genAI.*` | | | itens com assistente de IA |

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`pageItem`)

### pageItem type: tipos de item e o bloco `settings` específico do tipo
A propriedade `type` do item é do tipo "SUPPORTED UI" (string) na EBNF; a lista em tabela da referência não é completa (mostra `checkbox`, `checkboxGroup`, `combobox`, `displayImage`, `displayMap`, `fileUpload`, `geocodedAddress`, `imageUpload`, `listManager`, `qrCode`, `radioGroup`, `selectList`, `selectMany`, `selectOne`, `stopAndStartGridLayout`, `plugin/<pluginName>`). Tipos usados no export deste projeto (todos válidos, pois o export valida): `textField`, `textarea`, `numberField`, `password`, `hidden`, `displayOnly`, `datePicker`, `selectList`, `selectOne`, `popupLov`, `radioGroup`, `checkbox`, `switch`, `fileUpload`, `imageUpload`.

**Atributos específicos do tipo** (o que no Page Designer aparece em *Settings*) ficam num grupo `settings { … }` e, em alguns tipos, em outros grupos como `storage { … }`. Esses grupos **não são documentados** na referência genérica do `pageItem` (vêm do metadado do tipo/plug-in nativo). Exemplos observados no export:

```
settings {
    subtype: email
    textCase: lower
}
settings {
    displayAs: nativeHtml
}
storage {
    type: appTempFiles
}
```

Para criar um item com settings, copie o bloco de um item do mesmo tipo já exportado e valide; ou crie o item no Builder e exporte.

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`pageItem`; EBNF: `type` "SUPPORTED UI")

### pageItem source, default e sessionState (de onde vem o valor do item)
`source` tem duas formas:

1. **Item de Form** (`formRegion` definido):
| Propriedade | Obrig. | Padrão | Notas |
|---|---|---|---|
| `formRegion` | | | `@<região form>` |
| `column` | sim | | coluna da tabela/query |
| `dataType` | sim | | `varchar2`, `number`, `date`, `timestamp`, `timestampWithTimeZone`, `timestampWithLocalTimeZone`, `intervalYearToMonth`, `intervalDayToSecond`, `clob`, `blob`, `boolean`, `rowid`, `bfile`, `sdoGeometry` |
| `queryOnly` | sim | `false` | coluna não gravada (ex.: PK por trigger/identity) |
| `primaryKey` | sim | `false` | |

2. **Item comum** (sem `formRegion`): `type` (padrão `null`): `staticValue`, `databaseColumn`, `item`, `sqlQuerySingleValue`, `sqlQueryMultipleValues`, `expression`, `functionBody`, `preference`, `null`; com `staticValue`, `sqlQuery`, `item`, `language` + expressão/function body, `databaseColumn`, `preference`; e `used` (`onlyWhenSessionStateIsNull` padrão, `always`) e `postCalculationComputation` (plsql).

`default { type … }`: `static` (+ `staticValue`), `item`, `sqlQuerySingleValue`, `sqlQueryMultipleValues`, `expression`, `functionBody`, `sequence` (+ `sequence`).

`sessionState { dataType storage }`: `dataType` `varchar2` (padrão), `clob`, `boolean`, `number`; `storage` `session` (padrão em item comum; também `request`, `user`) ou `request` (padrão em item de form; também `session`).

````
pageItem P16_ID_EMPRESA (
    type: hidden
    layout {
        sequence: 10
        region: @new
        slot: regionBody
    }
    source {
        formRegion: @cadastro-de-empresas
        column: ID_EMPRESA
        dataType: number
        queryOnly: true
        primaryKey: true
    }
    security {
        sessionStateProtection: checksumRequiredSessionLevel
    }
)

pageItem P20_DT_INICIO (
    type: datePicker
    label {
        label: Início
    }
    layout {
        sequence: 10
        region: @filtros
        slot: regionBody
    }
    default {
        type: expression
        plsqlExpression:
            ```plsql
            to_char(trunc(sysdate, 'MM'), 'DD/MM/YYYY')
            ```
    }
)
````

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`pageItem.source`, `default`, `sessionState`)

### pageItem lov, cascadingLov e multipleValues (listas de valores no item)
| Grupo.propriedade | Padrão | Notas |
|---|---|---|
| `lov.type` | | `sharedComponent` (+ `lov: @x`), `sqlQuery` (+ `sqlQuery`, 2 colunas: display, return), `staticValues` (+ `staticValues`, padrão `STATIC:Display1;Return1,Display2;Return2`), `functionBody` (+ `language`, function body) |
| `lov.displayExtraValues` | `true` | não se aplica a combobox/selectOne/selectMany |
| `lov.displayNullValue` | `true` | + `nullDisplayValue`, `nullReturnValue` |
| `cascadingLov.parentItems` | | array de itens pai |
| `cascadingLov.itemsToSubmit` | | |
| `cascadingLov.parentRequired` | `true` | |
| `multipleValues.type` | `delimitedList` | `jsonArray` (+ `separator`, padrão `:`) |

````
pageItem P17_DEPARTAMENTO (
    type: selectList
    label {
        label: Departamento
    }
    lov {
        type: sqlQuery
        sqlQuery:
            ```sql
            select nome d, id_departamento r
              from departamento
             where id_empresa = :G_ID_EMPRESA
             order by nome
            ```
        nullDisplayValue: - Todos -
    }
    layout {
        sequence: 30
        region: @dados
        slot: regionBody
    }
)
````

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`pageItem.lov`, `cascadingLov`, `multipleValues`)

### button: propriedades (layout, appearance, behavior, confirmation, advanced)
`button <staticId> ( … )`, filho de `page`; filhos `triggerAction` e `menu`.

| Grupo.propriedade | Obrig. | Padrão | Valores / notas |
|---|---|---|---|
| `buttonName` | sim | | REQUEST enviado no submit (`SAVE`, `CREATE`); único na página |
| `label` | sim | | |
| `layout.sequence`, `slot` | sim | | `region: @x`; slots observados: `next`, `close`, `delete`, `create`, `edit`, `rightOfInteractiveReportSearchBar` |
| `layout.horizontalAlignment` | | `right` | slots TOP/BOTTOM |
| `appearance.buttonTemplate` | sim | | `@/text`, `@/text-with-icon`, `@/icon` |
| `appearance.hot` | | `false` | |
| `appearance.showAsDisabled` | | `false` | |
| `appearance.templateOptions`, `cssClasses`, `icon` | | | `t-Button--danger`, `fa-plus` |
| `behavior.type` | | `STANDARD` | |
| `behavior.action` | | `submitPage` | `triggerAction`, `redirectThisApp` (+ `target`), `redirectOtherApp` (+ `target`), `redirectUrl` (+ `targetUrl`), `definedByDynamicAction`, `resetPage`, `nextPage`, `previousPage` |
| `behavior.executeValidations` | | `true` | |
| `behavior.showProcessing` | | `false` | submit |
| `behavior.warnOnUnsavedChanges` | | | `doNotCheck` |
| `behavior.databaseAction` | | | `insert`, `update`, `delete` |
| `behavior.requiresConfirmation` | | `false` | + `confirmation { message style }` (`information`, `warning`, `danger`, `success`) |
| `advanced.htmlDomId`, `staticId`, `customAttributes`, `preText`, `postText` | | | |
| `advanced.requestSourceType` / `requestSource` | | | REQUEST dinâmico |
| `serverSideCondition`, `security.authorizationScheme`, `config.buildOption` | | | |

````
button save (
    buttonName: SAVE
    label: Salvar
    layout {
        sequence: 30
        region: @buttons
        slot: next
    }
    appearance {
        buttonTemplate: @/text
        hot: true
        templateOptions: #DEFAULT#
    }
    behavior {
        warnOnUnsavedChanges: doNotCheck
        databaseAction: update
    }
    serverSideCondition {
        type: itemIsNotNull
        item: P16_ID_EMPRESA
    }
)
````

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`button`)

### triggerAction e menu de botão (ações declarativas no próprio botão)
Com `behavior.action: triggerAction`, o botão tem filhos `triggerAction <id> ( … )` que executam ações sem criar uma Dynamic Action separada:

| Propriedade | Notas |
|---|---|
| `name` | opcional |
| `action` (obrig.) | mesma família das ações de DA: `cancelDialog`, `executeServerSideCode`, `executeJsCode`, `refresh`, `submitPage`, … |
| `affectedElements { selectionType region button items jquerySelector javaScriptExpression }` | conforme a ação |
| `execution { sequence stopExecutionOnError(true) waitForResult(true) }` | |
| `clientSideCondition`, `serverSideCondition`, `security`, `config` | |
| `advanced { staticId initJavaScriptFunction }` | |
| `settings { … }` | atributos da ação (não documentados na referência genérica; ex.: `plsqlCode`, `itemsToSubmit`, `itemsToReturn`) |
| `genAI.*` | ações com IA |

`menu` (botão de menu): `type` (`menuEntry` padrão, `subMenu`, `separator`), `label`, `parentMenu`, `layout.sequence`, `behavior { type: redirectThisApp|redirectOtherApp|redirectUrl|triggerAction target targetUrl }`, `appearance.icon`; um `menu` pode ter `triggerAction` filhos.

````
button cancel (
    buttonName: CANCEL
    label: Cancelar
    layout {
        sequence: 10
        region: @buttons
        slot: close
    }
    appearance {
        buttonTemplate: @/text
    }
    behavior {
        action: triggerAction
    }

    triggerAction native-dialog-cancel (
        action: cancelDialog
        execution {
            sequence: 10
        }
    )
)
````

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`triggerAction` filho de `button`, `menu`), [Reading APEXlang Syntax](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/reading-apexlang-syntax.html)

### process: tipos, ponto de execução e propriedades
`process <staticId> ( … )`, filho de `page`.

| Propriedade | Obrig. | Padrão | Notas |
|---|---|---|---|
| `name` | sim | | |
| `type` | sim | | ver lista |
| `formRegion` | sim p/ tipos de form | | `@<form>` |
| `editableRegion` | sim p/ tipos de região editável | | `@<ig>` |
| `executionChain` | | | processo dentro de execution chain |
| `source { location language plsqlCode javaScriptCode remoteServer }` | | `localDatabase`, `plsql` | `executeCode` |
| `execution.sequence` | sim | | |
| `execution.point` | sim | `AFTER_SUBMIT` | no export: `beforeHeader`, `afterSubmit` (padrão, omitido), `processing`, `ajaxCallback`… |
| `execution.runProcess` | | `oncePerPageVisitDefault` | `oncePerSessionOrWhenReset` |
| `successMessage.successMessage` | | | |
| `error.errorMessage` / `displayLocation` | | `inlineInNotification` | `onErrorPage` |
| `advanced.staticId`, `executionMappingIdentifier` | | | o segundo é gerado pelo APEX |
| `serverSideCondition` + `whenButtonPressed: @botao` | | | `executionScope`, `executeCondition` em região editável |
| `security`, `config`, `comments`, `genAI` | | | |

Valores de `type`: `autoRowFetch`, `autoRowProcessing`, `clearSessionState`, `closeDialog`, `dataLoading`, `download`, `executeCode`, `executionChain`, `formAutoRowProcessing`, `formInitialization`, `formPagination`, `generateTextWithAi`, `humanTaskCreate`, `humanTaskManage`, `interactiveGridAutoRowProcessing`, `invokeApi`, `invokeWorkflow`, `legacyAutoRowProcessing`, `legacyWebService`, `loadUploadedData`, `parallelFlow`, `parseUploadedData`, `plugin/<pluginName>`, `prepareUploadedData`, `printReport`, `resetPagination`, `sendEMail`, `sendPushNotification`, `serverSideGeocoding`, `switch`, `tabformAddRows`, `tabformDelete`, `tabformUpdate`, `userPreferences`, `wait`, `webService`, `workflow`, `workflowEnd`, `workflowStart`.

Como em itens, atributos específicos de alguns tipos ficam em grupos próprios não listados na referência genérica (ex.: `invoke { package procedureOrFunction }` do `invokeApi`, observado no export).

````
process gravar-log (
    name: Gravar log
    type: executeCode
    source {
        plsqlCode:
            ```plsql
            meu_pkg.registrar(p_acao => :REQUEST, p_empresa => :G_ID_EMPRESA);  -- exemplo
            ```
    }
    execution {
        sequence: 20
    }
    serverSideCondition {
        whenButtonPressed: @save
    }
)
````

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`process`)

### process de formulário modal: formInitialization, formAutoRowProcessing e closeDialog
Padrão gerado pelo assistente (p16), que um agente deve reproduzir em formulários novos:

```
process initialize-form-x (
    name: Initialize form X
    type: formInitialization
    formRegion: @x
    execution {
        sequence: 10
        point: beforeHeader
    }
)

process process-form-x (
    name: Process form X
    type: formAutoRowProcessing
    formRegion: @x
    execution {
        sequence: 10
    }
)

process close-dialog (
    name: Close Dialog
    type: closeDialog
    execution {
        sequence: 50
    }
    serverSideCondition {
        type: requestIsContainedInValue
        value: CREATE,SAVE,DELETE
    }
)
```

- O `formAutoRowProcessing` usa o `databaseAction` dos botões (`insert`/`update`/`delete`) para decidir a operação.
- O form só grava se a região tiver `edit { enabled: true allowedOperations: [...] }`.
- `executionMappingIdentifier` aparece nos processos exportados; preserve-o ao editar e omita-o em processos novos (a doc não descreve como é gerado).

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`process`, `region.edit`)

### process invokeApi e parameter (chamada declarativa de package/procedure)
`type: invokeApi` chama um procedimento/função PL/SQL, um REST Data Source ou outros alvos. No export:

```
process login (
    name: Login
    type: invokeApi
    invoke {
        package: APEX_AUTHENTICATION
        procedureOrFunction: LOGIN
    }
    execution {
        sequence: 20
    }

    parameter p_username (
        value {
            type: item
            item: P9999_USERNAME
        }
        advanced {
            displaySequence: 1
        }
    )

    parameter p_set_persistent_auth (
        parameter {
            dataType: boolean
            hasDefault: true
        }
        value {
            type: apiDefault
        }
    )
)
```

`parameter` (PL/SQL): direto `type` (`parameter` ou `functionResult`) e `name`; grupo `parameter { direction: in|out|inOut dataType (varchar2, clob, number, plsqlInteger, boolean, date, timestamp…, blob, char, rowid, custom) dataTypeName hasDefault ignoreOutput }`; grupo `value { type staticValue sqlQuery item language + expressão … }`; `advanced { displaySequence }`. Outros filhos de processo: `inParameter`, `outParameter`, `basicAuthenticationParameter` (web services) e `parameter` de `createTask`/`workflow`.

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`process`, `parameter`; EBNF `parameter-j`)

### validation: tipos e propriedades
`validation <staticId> ( … )`, filho de `page`.

| Grupo.propriedade | Padrão | Notas |
|---|---|---|
| `name` (obrig.) | | |
| `execution.sequence` (obrig.) | | |
| `validation.type` | `expression` | ver lista |
| `validation.editableRegion` | | `@<ig>` para validar colunas (troca `item*` por `column*`) |
| `validation.sqlQuery`, `language`, `sqlExpression`/`plsqlExpression`/`javaScriptExpression`, `plsqlFunctionBody`, `plsqlCodeRaisingError` | | conforme o tipo |
| `validation.item` / `column`, `regexp`, `value` | | tipos de item/coluna |
| `validation.alwaysExecute` | `false` | executa mesmo se o botão não valida |
| `error.errorMessage` | | obrig. exceto em *function body returning error text* |
| `error.displayLocation` | `inlineWithFieldAndInNotification` | `inlineWithField`, `inlineInNotification`, `onErrorPage` |
| `error.associatedItem` | | `@ITEM` (referência) |
| `error.associatedColumn` | | em região editável |
| `serverSideCondition` (+ `whenButtonPressed`, `executionScope`, `executeCondition`) | | |
| `security`, `config`, `comments` | | |

Tipos (item): `rowsReturned`, `noRowsReturned`, `expression`, `plsqlError`, `functionBodyReturningBoolean`, `functionBody` (retorna texto de erro), `itemIsNotNull`, `itemIsNotNullOrZero`, `itemIsNotZero`, `itemContainsNoSpaces`, `itemIsAlphanumeric`, `itemIsNumeric`, `itemIsAValidDate`, `itemIsAValidTimestamp`, `item=Value`, `item!=Value`, `itemIsContainedInValue`, `itemIsNotContainedInValue`, `itemContainsOnlyCharsInValue`, `itemContainsAtLeastOneOfCharsInValue`, `itemContainsNoneOfCharsInValue`, `itemMatchesRegexp`. Com `editableRegion`, os mesmos com prefixo `column` (`columnIsNotNull`, `column=Value`, …).

````
validation validar-confirmacao-senha (
    name: Validar Confirmação de Senha
    execution {
        sequence: 10
    }
    validation {
        type: functionBodyReturningBoolean
        plsqlFunctionBody:
            ```plsql
            return :P14_SENHA = :P14_CONFIRMAR_SENHA;
            ```
        alwaysExecute: true
    }
    error {
        errorMessage: A confirmação de senha não corresponde à senha informada.
        associatedItem: @P14_CONFIRMAR_SENHA
    }
)

validation empresa-do-usuario (
    name: Empresa do usuário
    execution {
        sequence: 5
    }
    validation {
        plsqlExpression: :P14_EMPRESA = :G_ID_EMPRESA
    }
    error {
        errorMessage: Você só pode cadastrar colaboradores na sua empresa.
        associatedItem: @P14_EMPRESA
    }
)
````

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`validation`)

### computation (computação de página)
`computation <staticId> ( … )`: atribui valor a um item.

| Grupo.propriedade | Padrão | Notas |
|---|---|---|
| `itemName` (obrig.) | | nome do item (sem `@`) |
| `execution.sequence` (obrig.) | | |
| `execution.point` | `beforeRegions` | `newSession`, `beforeHeader`, `afterHeader`, `beforeRegions`, `afterRegions`, `beforeFooter`, `afterFooter`, `afterSubmit` |
| `computation.type` | `sqlQuerySingleValue` | `staticValue`, `item`, `sqlQuerySingleValue`, `sqlQueryMultipleValues`, `expression`, `functionBody`, `preference` |
| `computation.staticValue`, `sqlQuery`, `language` + expressão/function body, `itemName`, `preference` | | conforme tipo |
| `computation.computationProcessed` | | `newSession`, `replaceExisting`, `addToExisting`, `raiseErrorOnReplace`, `replaceNullValues` |
| `error.errorMessage` | | |
| `serverSideCondition`, `security`, `config`, `comments` | | |

````
computation p1-mes-atual (
    itemName: P1_MES_ATUAL
    execution {
        sequence: 10
        point: beforeHeader
    }
    computation {
        type: expression
        plsqlExpression:
            ```plsql
            pkg_home_ui.mes_atual
            ```
    }
)
````

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`computation`)

### branch (desvio após processamento)
`branch ( … )` (sem identificador no export).

| Grupo.propriedade | Padrão | Notas |
|---|---|---|
| `name` | | opcional |
| `execution.sequence` (obrig.) | | |
| `execution.point` | `afterProcessing` | `beforeHeader`, `afterSubmit`, `validating`, `processing`, `afterProcessing` |
| `behavior.type` | `pageOrUrl` | `urlIdentifiedByItem`, `functionReturningUrl`, `page`, `pageIdentifiedByItem`, `functionReturningPage`, `plsqlProcedure`, `pageProcessing` |
| `behavior.target` | | obrig. com `pageOrUrl` (`{ page: 13 clearCache: 13 action: clearRegions }`) |
| `behavior.saveStateBeforeBranching` | `false` | |
| `behavior.pageNumber`, `request`, `item`, `language` + function body, `plsqlCode` | | conforme tipo |
| `serverSideCondition` (+ `whenButtonPressed`) | | |

```
branch (
    name: Recarregar
    execution {
        sequence: 10
    }
    behavior {
        target: {
            page: 13
        }
    }
    serverSideCondition {
        type: request=Value
        value: TROCAR_COLABORADOR
    }
)
```

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`branch`)

### dynamicAction: evento, seleção e escopo
`dynamicAction <staticId> ( … )`, filho de `page`, com filhos `action`.

| Grupo.propriedade | Padrão | Notas |
|---|---|---|
| `name` (obrig.) | | |
| `execution.sequence` (obrig.) | | |
| `execution.eventScope` | `static` | `dynamic`, `once` (+ `staticContainer` para dinâmico) |
| `execution.type` | `immediate` | `debounce`, `throttle` (+ `time`, `immediate`) |
| `when.event` | `change` | `click`, `ready`, `keyup`, `keydown`, `apexafterclosedialog`, `apexafterrefresh`, `custom` (+ `customEvent`), … |
| `when.selectionType` | | `items`, `button`, `region`, `columns`, `domObject`, `jQuerySelector`, `jsExpression` (não se aplica a `ready`, `unload`, `resize`, `orientationchange`, `apexbeforepagesubmit`) |
| `when.items` | | array de nomes de item |
| `when.button` / `region` / `interactiveGrid` | | referências `@x` |
| `when.columns`, `domObject`, `jquerySelector`, `javaScriptExpression` | | |
| `clientSideCondition` | | ver bloco comum |
| `advanced.staticId` | | |
| `serverSideCondition`, `security`, `config`, `comments` | | |

Sem `event` no arquivo = `change` (o default é omitido). DA de clique de botão exige `behavior.action: definedByDynamicAction` no botão.

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`dynamicAction`)

### action de Dynamic Action (ações True/False)
`action <staticId> ( … )`, filho de `dynamicAction`.

| Grupo.propriedade | Padrão | Notas |
|---|---|---|
| `name` | | opcional |
| `action` (obrig.) | | string "SUPPORTED UI"; valores observados no export: `executeJsCode`, `executeServerSideCode`, `refresh`, `setValue`, `show`, `enable`, `disable`, `submitPage`, `redirectThisApp`, `openRegion`, `cancelDialog` |
| `affectedElements.selectionType` | | conforme a ação: region, button, items, jquerySelector, javaScriptExpression, triggering element, event source |
| `affectedElements.region` / `button` | | `@x` |
| `affectedElements.items` | | array de nomes |
| `affectedElements.columns`, `domObject`, `jquerySelector`, `javaScriptExpression` | | |
| `execution.sequence` (obrig.) | | |
| `execution.fireWhenEventResultIs` | `TRUE` | `false` = ramo "False" |
| `execution.fireOnInit` | `true` | não se aplica a `ready`; **desligue** em ações que não devem rodar no load |
| `execution.stopExecutionOnError` / `waitForResult` | `true` | |
| `clientSideCondition`, `serverSideCondition`, `security`, `config` | | |
| `advanced.staticId`, `initJavaScriptFunction` | | |
| `settings { … }` | | atributos da ação (`jsCode`, `plsqlCode`, `itemsToSubmit`, `itemsToReturn`, …) — não documentados na referência genérica |

````
dynamicAction ao-carregar (
    name: Ao carregar
    execution {
        sequence: 20
    }
    when {
        event: ready
    }

    action boas-vindas (
        action: executeJsCode
        settings {
            jsCode:
                ```javascript-browser
                apex.message.showPageSuccess( "Bem-vindo!" );
                ```
        }
        execution {
            sequence: 10
        }
    )
)

dynamicAction atualizar-relatorio (
    name: Atualizar relatório
    execution {
        sequence: 30
    }
    when {
        event: apexafterclosedialog
        selectionType: button
        button: @novo
    }

    action refresh-lista (
        action: refresh
        affectedElements {
            selectionType: region
            region: @lista
        }
        execution {
            sequence: 10
        }
    )
)
````

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`action` filho de `dynamicAction`), [Reading APEXlang Syntax](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/reading-apexlang-syntax.html)

---

## 9. Referência: shared components, tema e templates

### authentication (authentications.apx)
| Grupo.propriedade | Padrão | Valores / notas |
|---|---|---|
| `name` (obrig.) | | |
| `type` (obrig.) | | `oracleApexAccounts`, `databaseAccounts`, `custom`, `httpHeaderVariable`, `ldapDirectory`, `noAuth`, `openDoorCredentials`, `oracleAppServerSSO`, `samlSignIn`, `socialSignIn`, `internalAppExtension`, `plugin/<pluginName>` |
| `source.plsqlCode` | | PL/SQL de apoio |
| `sessionNotValid.verifyFunctionName` | | |
| `sessionNotValid.redirectTo` | `loginPage` | `builtInLoginPage`, `url` (+ `invalidSessionUrl`) |
| `loginProcessing.preAuthenticationProcedureName` / `postAuthenticationProcedureName` | | |
| `loginProcessing.switchInSession` | `false` | |
| `postLogout.redirectTo` | `homePage` | `url` (+ `url`) |
| `sessionSharing.type` | `app` | `workspaceSharing`, `custom` (+ cookie name/path/domain, `secure`) |
| `realAppSecurity.rasMode` | `disabled` | `externalUsers`, `internalUsers` |
| `advanced.staticId`, `help.helpText`, `subscription.master`, `comments` | | |

Atributos do tipo (ex.: configuração de Social Sign-In ou de esquema custom) vão em `settings { … }`, não detalhado na referência genérica. A app aponta o esquema atual em `application.apx › authentication.scheme`.

```
authentication oracle-apex-accounts (
    name: Oracle APEX Accounts
    type: oracleApexAccounts
)
```

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`authentication`)

### authorization (authorizations.apx)
| Grupo.propriedade | Padrão | Valores / notas |
|---|---|---|
| `name` (obrig.) | | nome usado em `apex_authorization.is_authorized('NOME')` |
| `type` (obrig.) | | `existsSqlQuery`, `notExistsSqlQuery`, `isInRoleOrGroup`, `isNotInRoleOrGroup`, `itemEqualsValue`, `itemNotEqualsValue`, `itemIsNull`, `itemIsNotNull`, `plSqlFunctionBody`, `preferenceEqualsValue`, `preferenceNotEqualsValue`, `plugin/<pluginName>` |
| `error.errorMessage` | | mensagem ao negar |
| `advanced.evaluationType` | `perPageView` | `perSession`, `perComponent`, `always` |
| `advanced.staticId` | | id usado em `authorizationScheme: @id` |
| `subscription.master`, `comments` | | |

O conteúdo do tipo vai em `settings { … }` (observado no export; não detalhado na referência genérica): `names: <nome da role>` para `isInRoleOrGroup`, `plsqlFunctionBody:` para `plSqlFunctionBody`.

````
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

authorization colaborador (
    name: COLABORADOR
    type: plSqlFunctionBody
    settings {
        plsqlFunctionBody:
            ```plsql
            declare
              l_qt pls_integer;
            begin
              select count(*) into l_qt
                from colaborador
               where upper(login_apex) = upper(:APP_USER)
                 and id_empresa = :G_ID_EMPRESA;
              return l_qt > 0;
            end;
            ```
    }
    advanced {
        evaluationType: perSession
    }
)
````

Note a diferença: o **Static ID** (`admin-rh`) é o que se usa nas referências `@admin-rh`; o **name** (`ADMIN_RH`) é o que se usa nas APIs PL/SQL.

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`authorization`)

### role: papéis de Access Control (acl-roles.apx)
`role <staticId> ( name: … description { description: … } )`. Propriedades: `name` (obrig.), `description.description`, `advanced.staticId`, `subscription.master`. Atribuições de usuários a roles são dados de runtime (não ficam no `.apx`; no export SQL vão com `-expaclassignments`, observado no script de backup do projeto).

```
role admin-rh (
    name: Admin RH
    description {
        description: Equipe de RH. Usado pela autorização ADMIN_RH.
    }
)
```

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`role`)

### appItem: itens de aplicação (app-items.apx)
| Grupo.propriedade | Padrão | Valores |
|---|---|---|
| `name` (obrig.) | | é o id após `appItem` |
| `scope` | `app` | `global` |
| `security.sessionStateDataType` | `varchar` | `number` |
| `security.sessionStateProtection` | `restricted` | `unrestricted`, `checksumRequiredAppLevel`, `checksumRequiredUserLevel`, `checksumRequiredSessionLevel` |
| `security.escapeSpecialChars` | `true` | |
| `subscription.master`, `config.buildOption`, `comments` | | |

Note que o default de proteção do app item é `restricted` (não pode ser definido pelo navegador), diferente do item de página (`unrestricted`). Um app item todo em default aparece vazio: `appItem G_ID_EMPRESA (` / `)`.

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`appItem`)

### appProcess: processos de aplicação (app-processes.apx)
| Grupo.propriedade | Padrão | Notas |
|---|---|---|
| `name` (obrig.), `type` (obrig.) | | mesmos tipos de `process` (normalmente `executeCode`) |
| `source { location language plsqlCode javaScriptCode remoteServer }` | `localDatabase`, `plsql` | |
| `execution.sequence` (obrig.) | | |
| `execution.point` | `beforeHeader` | `afterAuthentication`, `newSession`, `beforeHeader`, `afterHeader`, `beforeRegions`, `afterRegions`, `beforeFooter`, `afterFooter`, `afterSubmit`, `processing`, `ajaxCallback` |
| `error.errorMessage`, `displayLocation` | | |
| `serverSideCondition`, `security.authorizationScheme`, `config.buildOption`, `subscription`, `comments` | | |

`ajaxCallback` = processo chamado por `apex.server.process('NOME')`. Como o default é `beforeHeader`, um processo que roda em toda página antes do header não declara `point`.

````
appProcess carregar-empresa (
    name: CARREGAR_EMPRESA
    type: executeCode
    source {
        plsqlCode:
            ```plsql
            select id_empresa into :G_ID_EMPRESA
              from colaborador
             where upper(trim(login_apex)) = upper(trim(:APP_USER));
            ```
    }
    execution {
        sequence: 1
        point: afterAuthentication
    }
)
````

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`appProcess`), [apex.server](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.server.html)

### appComputation: computações de aplicação
`appComputation ( itemName: … )`: `execution { sequence point }` com `point` padrão `newSession` (`afterAuthentication`, `beforeHeader`, `afterHeader`, `beforeRegions`, `afterRegions`, `beforeFooter`, `afterFooter`, `afterSubmit`); `computation { type (padrão staticValue) … }` com os mesmos tipos e propriedades de `computation` de página; `error`, `serverSideCondition`, `security`, `config`, `subscription`, `comments`.

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`appComputation`)

### appSetting: Application Settings
`appSetting <staticId> ( value { staticValue onUpgradeKeepValue(false) } validation { required(false) validValues } config subscription comments )`. Lidos em PL/SQL com `APEX_APP_SETTING`.

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`appSetting`)

### buildOption (build-options.apx)
| Grupo.propriedade | Padrão | Valores |
|---|---|---|
| `name` (obrig.) | | |
| `status.status` | `exclude` | `include` |
| `status.defaultOnExport` | | `exclude`, `include` |
| `status.onUpgradeKeepStatus` | `false` | |
| `advanced.staticId`, `featureIdentifier` | | |

Componentes usam `config { buildOption: @id }`. Uso típico: "comentar" componentes sem apagá-los (build option `Commented Out` com status `exclude`), ou entregar features por ambiente.

```
buildOption commented-out (
    name: Commented Out
)
```

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`buildOption`), [Exporting an Application](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/exporting-an-application.html)

### lov: Shared List of Values (lovs.apx) — source, columnMapping, entry, column
| Grupo.propriedade | Padrão | Notas |
|---|---|---|
| `name` (obrig.) | | |
| `source.location` | `localDatabase` | `staticValues`, `restEnabledSql`, `restSource`, `jsonDualityView`, `jsonSource`, `sampleData` |
| `source.type` | `TABLE` (omitido) | `sqlQuery`, função que retorna SQL, legado |
| `source.tableOwner`, `tableName`, `whereClause` | | tabela |
| `source.sqlQuery` | | sql |
| `source.plsqlFunctionBody` (+ `language`) | | |
| `columnMapping.return` (obrig.) / `display` / `defaultSort` | | nomes de coluna |
| `columnMapping.sortDirection` / `groupSortDirection` | `ascNullsLast` | `ascNullsFirst`, `descNullsLast`, `descNullsFirst` |
| `columnMapping.group`, `icon`, `quickPickRank`, `oracleTextIndex` | | |
| `advanced.staticId`, `subscription`, `comments` | | |

Filhos: `entry` (LOV estática: `sequence`, `display`, `return`, `quickPickRank`, `globalization.template`, `serverSideCondition`, `config`); `column` (colunas extras para popup LOV: `columnName`, `show` (`true`), `heading`, `layout.sequence`, `source.dataType`, `appearance.formatMask`, `advanced.searchable` (`true`)); `parameter` (REST).

````
lov lov-departamento-empresa (
    name: LOV_DEPARTAMENTO_EMPRESA
    source {
        type: sqlQuery
        sqlQuery:
            ```sql
            select nome d, id_departamento r
              from departamento
             where id_empresa = :G_ID_EMPRESA
             order by nome
            ```
    }
    columnMapping {
        return: R
        display: D
    }
)

lov boolean (
    name: BOOLEAN
    source {
        location: staticValues
    }

    entry true (
        sequence: 1
        display: Yes
        return: TRUE
    )

    entry false (
        sequence: 2
        display: No
        return: FALSE
    )
)
````

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`lov`, `entry`, `column` filhos de `lov`)

### list e entry de lista (lists.apx) — menu de navegação, wizard, links
`list <staticId> ( name source { type … } )`:
- `source.type`: `staticValues` (padrão, com `entry` filhos), `sqlQuery` (+ `sqlQuery`), `functionBody` (função que retorna SQL).

`entry <staticId> ( … )` (lista estática):

| Grupo.propriedade | Padrão | Notas |
|---|---|---|
| `label` (obrig.; grupo padrão, escrito direto) | | html |
| `icon.imageIconCssClasses`, `attributes`, `altAttribute` | | `fa-users` |
| `layout.sequence` (obrig.), `parentEntry` (`@pai`), `subentriesList` | | hierarquia |
| `isCurrent.type` | `targetPage` | `pages` (+ `pages`), `existsSqlQuery`, `notExistsSqlQuery`, `expression`, `always`, `never` |
| `link.target`, `linkAttributes` | | |
| `clickCounting.countClicks` | `false` | + `category` |
| `userDefinedAttributes.1` … `10`, `translatable` | | |
| `serverSideCondition`, `security.authorizationScheme`, `config.buildOption` | | |

```
entry cadastros (
    label: Cadastro de Usuários
    icon {
        imageIconCssClasses: fa-user-plus
    }
    layout {
        sequence: 70
    }
    isCurrent {
        type: pages
        pages: 14
    }
    link {
        target: {
            page: 14
        }
    }
    security {
        authorizationScheme: @admin-rh
    }
)
```

Atenção: `security.authorizationScheme` na entrada só **esconde o link**; a página continua acessível por URL se ela mesma não tiver `security.authorizationScheme`.

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`list`, `entry` filho de `list`)

### breadcrumb e entry de breadcrumb (breadcrumbs.apx)
`breadcrumb <staticId> ( name … entry … )`. Cada `entry`:

| Propriedade | Obrig. | Notas |
|---|---|---|
| `name` | sim | texto exibido |
| `pageNumber` | sim | página em que a entrada é a "atual" |
| `execution.sequence` | sim | |
| `appearance.parentEntry` | | `@entrada-pai` (hierarquia) |
| `appearance.longName` | | |
| `link.target` | | `{ page: N }` |
| `serverSideCondition`, `security.authorizationScheme`, `config.buildOption`, `comments` | | |

```
breadcrumb breadcrumb (
    name: Breadcrumb

    entry empresas-cadastradas (
        name: Empresas Cadastradas
        pageNumber: 15
        execution {
            sequence: 10
        }
        link {
            target: {
                page: 15
            }
        }
    )
)
```

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`breadcrumb`, `entry` filho de `breadcrumb`)

### file: Static Application File (static-files.apx)
`file <caminho> ( … )` com grupo padrão `file`: `fileName` (obrig.; é o id após `file`, com aspas se tiver espaço), `content` (blob, vem do arquivo físico em `shared-components/static-files/<caminho>`), `mimeType` (obrig.), `charSet` (ex.: `utf-8`, `iso-8859-1`, `windows-1252`…). Referencie no app com `#APP_FILES#<caminho>`; com `#MIN#`, o APEX escolhe `.min` fora do modo debug, então mantenha os dois arquivos (`x.css` e `x.min.css`) registrados.

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`file`), [Exporting APEXlang from App Builder](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/exporting-apexlang-app-builder.html), [Editing User Interface Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-user-interface-attributes.html) (`#MIN#`)

### componentSetting (component-settings.apx)
Configurações de nível de aplicação para tipos de componente nativos e plug-ins. `componentSetting ( type name settings { … } )`: `type` ∈ `item`, `region`, `dynamicAction`, `genAITool`, `process`, `authenticationScheme`, `authorizationScheme`, `restDataSource`; `name` é o tipo (ex.: `datePicker`, `checkbox`, `switch`, `interactiveReport`); `settings` contém os atributos do componente (não detalhados na referência). Sem identificador.

```
componentSetting (
    type: item
    name: switch
    settings {
        onValue: Y
    }
)
```

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`componentSetting`)

### substitution (substituições de aplicação) e textMessage (mensagens de texto)
- `substitution <NOME> ( value { staticValue: … } )` em `application.apx`: define `&NOME.`. Existe também `substitution` filho de `supportingObject` (prompts de instalação: `installation { promptSubstitution(false) installationPrompt }`).
- `textMessage <staticId> ( message { text (obrig.) language (obrig.) usedInJavaScript(false) } advanced { metadata } )`: mensagens traduzíveis (`APEX_LANG.GET_MESSAGE`, `&APP_TEXT$NOME.`, `apex.lang.getMessage` quando `usedInJavaScript`). No 26.1 a mensagem cai para o idioma primário se não houver texto no idioma pedido.
- `dynamicTranslation ( translation { language fromText toText } )`.

```
substitution APP_NAME (
    value {
        staticValue: CorlixHub
    }
)
```

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`substitution`, `textMessage`, `dynamicTranslation`), [Changed Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html)

### theme (themes/<tema>/theme.apx): defaults de componentes, ícones e arquivos
| Grupo.propriedade | Notas |
|---|---|
| `name` (obrig.), `themeNumber` (42 = Universal Theme), `baseTheme` (`ut-24.2`, `ut-26.1`), `version` | |
| `style.currentThemeStyle` | `@/redwood-light`, `@/vita`… |
| `javaScript.fileUrls`, `css.fileUrls` | arquivos do tema (`#THEME_FILES#…`) |
| `navigation.type` (`list`/`tabs`), `navigationBarType` (`list`/`classic`) | |
| `componentDefaults.page`, `loginPage`, `errorPage`, `printerFriendlyPage`, `breadcrumb`, `button`, `defaultLabel`, `optionalLabel`, `requiredLabel`, `list`, `region`, `classicReport`, `navigationBarList`, `navigationMenuListTop`, `navigationMenuListSide`, `navigationMenuListPosition` (`top` padrão/`side`), `headerToolbar`, `footerToolbar` | templates padrão (refs) |
| `regionDefaults.breadcrumbs`, `charts`, `forms`, `lists`, `reports`, `wizards`, `interactiveReports` | |
| `dialogDefaults.dialogContentRegion`, `dialogButtonRegion`, `dialogPage` | |
| `icons.library` (`fontApex`, `fontApexLatest`), `customLibraryFileUrls`, `customClasses`, `customPrefixClass`, `datePickerIconName` | |
| `advanced.staticId`, `filePrefix`, `identifier` (obrig.; `UNIVERSAL_THEME`) | |

Filhos: `pageTemplate`, `regionTemplate`, `buttonTemplate`, `classicReportTemplate`, `listTemplate`, `fieldTemplate`, `breadcrumbTemplate`, `popupLovTemplate`, `globalTemplateOption`, `templateOptionGroup`, `style`, `file`. No export, só templates **customizados/copiados** aparecem em subpastas; os padrões do UT são referenciados com `@/`.

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`theme`)

### pageTemplate e slot (page-templates/*.apx): de onde vêm os nomes de slot
`pageTemplate <staticId> ( … )`: `name`, `templateClass`, `templateOptions { preset default }`, `page { type: normal|dialog header body footer }` (html), `javaScript`, `css { fileUrls inline }`, `subtemplate { successMessage navigationBar navigationBarEntry notification }`, `layout { type (fixedNumberOfColumns padrão, htmlTable, variableNumberOfColumns) maxColumns … containerTemplate rowTemplate columnTemplate }`, `positions { breadcrumbPosition sidebarPosition }`, `dialog { width height maxWidth cssClasses allowEmbedInFrame initCode closureCode cancelCode }`, `errorPage.template`, `advanced { staticId identifier translatable }`. Filhos `slot` e `templateOption`.

`slot <apexlangName> ( name apexlangName staticId supports { regions(true) items(false) buttons(false) } gridLayout { gridSupport(true) maxFixedColumns newRow(true) } )`. O **identificador do slot é o `apexlangName`** (ex.: `afterLogo`, `body`, `breadcrumbBar`), e é ele que vai em `layout.slot` das regiões/itens/botões; o `staticId` é a posição do template (`AFTER_LOGO`, `BODY`, `REGION_POSITION_01`). Region templates também têm `slot` filhos (ex.: `regionBody`, `subRegions`, `next`, `close`).

```
slot afterLogo (
    name: After Logo
    staticId: AFTER_LOGO
    supports {
        items: true
        buttons: true
    }
)
```

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`pageTemplate`, `slot`)

### regionTemplate, buttonTemplate, classicReportTemplate, listTemplate, fieldTemplate, breadcrumbTemplate, popupLovTemplate
Templates customizados do tema (cada um em sua subpasta). Estrutura comum: `name`, `templateClass`, `templateOptions { preset default }`, grupos de HTML do template, `javaScript`/`css`, `advanced { staticId identifier translatable }`, filhos `templateOption` (e `slot` em region template).
- `regionTemplate`: `region { template image htmlTableAttributes }`, `subRegions { template header headerEntry }`, `accessibility { landmarkType regionTitleHtmlId }`.
- `buttonTemplate`: `button { normal (obrig.) hot }`.
- `classicReportTemplate`: `type` (`genericColumns`, `namedColumn`), `reportTemplate { top bottom }`, `columnTemplates { beforeHeading heading afterHeading beforeEachRow template conditionType plsqlExpression … }` (até 4 templates de coluna condicionais), paginação.
- `listTemplate`, `fieldTemplate` (label/item, com grupos de help e erro), `breadcrumbTemplate`, `popupLovTemplate`: HTML específico de cada tipo.

Templates do UT não precisam ser declarados: referencie com `@/nome`. Ao **copiar** um template do UT para customizar, ele passa a existir no tema da app e é referenciado com `@nome`.

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`regionTemplate`, `buttonTemplate`, `classicReportTemplate`, `listTemplate`, `fieldTemplate`, `breadcrumbTemplate`, `popupLovTemplate`)

### templateOption, globalTemplateOption, templateOptionGroup e style
- `templateOption` (filho de um template): `name`, `group` (ref a `templateOptionGroup`), `sequence` (obrig.), `appearance.cssClasses` (obrig.; as classes que entram em `templateOptions`), `help.helpText`, `advanced { isAdvancedOption(false) staticId identifier }`.
- `globalTemplateOption` (filho do tema): igual, com `templateType` (`button`, `item`, `region`, `report`, `list`, `page`, `breadcrumb`); vale para todos os templates do tipo.
- `templateOptionGroup`: `templateType`, `name`, `sequence`, `settings.nullText`, `help`, `advanced`.
- `style` (theme style): `name`, `css { fileUrls cssClasses }`, `themeRollerAttributes { readOnly(false) inputParameterFileUrls outputCssFileUrl jsonConfig }` (json), `advanced { staticId endUserCanPick(false) accessibilityTested(false) }`.

Os valores aceitos em `appearance.templateOptions` de um componente são as `cssClasses` das template options do template escolhido, mais `#DEFAULT#`.

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`templateOption`, `globalTemplateOption`, `templateOptionGroup`, `style`)

### supportingObject e filhos (installScript, upgradeScript, validation, substitution, buildOption, databaseObject)
`supportingObject ( … )` (sem id; `supporting-objects/supporting-objects.apx`):

| Grupo.propriedade | Notas |
|---|---|
| `prerequisites.freeSpace`, `systemPrivileges` | `createTable`, `createView`, `createProcedure`, `createSequence`, `createTrigger`, `createType`, `createSynonym`, `createMaterializedView`, `createDatabaseLink` |
| `installation.objectNames` | objetos que não podem existir |
| `installationMessages.welcome`, `confirmation`, `installSuccess`, `installFailure` | |
| `upgrade.upgradeWhenSqlQuery` | sql que detecta upgrade |
| `upgradeMessages.*`, `deinstall.script`, `deinstallationMessages.*`, `messages.*` | |
| `advanced.includeInAppExport` | `true`, `false`, `autoInstall` |

Filhos: `installScript` e `upgradeScript` (`name`, `execution.sequence`, `script { type: packageSpec|packageBody|table content }`, `serverSideCondition`), `databaseObject` (filho de installScript: `dbObject { owner type name }` com `type` ∈ `databaseLink`, `function`, `index`, `materializedView`, `mleEnvironment`, `mleModule`, `package`, `procedure`, `sequence`, `synonym`, `table`, `trigger`, `type`, `view`), `validation` (pré-requisito com condição e `error.errorMessage`), `substitution` (prompt de instalação), `buildOption` (prompt de build option).

Lembrete: supporting objects não substituem migração de schema; o export/import da app cobre só a definição da app.

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`supportingObject` e filhos), [Exporting and Importing Applications](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/exporting-and-importing-applications.html)

### plugin e APEXlang Name (como plug-ins viram tipos de componente)
`plugin <staticId> ( name apexlangName (obrig.) staticId type … )`. `type` (padrão `templateComponent`): `templateComponent`, `item`, `region`, `dynamicAction`, `genAITool`, `process`, `authenticationScheme`, `authorizationScheme`, `restDataSource`, …; template components têm `availableAs` (`partial`, `report`, `regionOnly`) e HTML `partial`, `reportBody`, `reportGroup`, `reportRow`, `reportContainer`. Filhos: `customAttribute`, `attributeGroup`, `slot`, `actionPosition`, `actionTemplate`, `event`, `file`, `standardAttributeConfig`.

No 26.1, plug-ins e seus subcomponentes ganharam o atributo **APEXlang Name** (camelCase, alfanumérico, único), gerado automaticamente no upgrade. É por ele que o plug-in aparece como tipo: `type: plugin/<apexlangName>` (item/região/processo/DA) ou `appTemplateComponent/<apexlangName>`.

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`plugin`), [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### Outros shared components de app (REST, automações, e-mail, PWA, busca, IA, workflow…)
Resumo dos demais filhos de `app` (propriedades-chave):
- `restDataSource`: `name`, `type` (`http`, `oci`, `odataRestService`, `oracleCloudAppsBoss`, `oracleCloudAppsSaas`, `ords`, `restEnabledSqlQuery`, `plugin/…`), `remoteServer`, formato (`json`, `csv`, `xml`), `rowSelector`; filhos `operation`, `parameter`, `dataProfileColumn`, `synchronizationStep`.
- `automation`: `type` (`scheduled` padrão, `onDemand`), `scheduleExpression`, `scheduleStatus` (`disabled` padrão, `active`, `error`), `actionsInitiatedOn` (`rowsReturned` padrão…), fonte; filhos `action` e `parameter`.
- `emailTemplate`: `name`, `emailSubject`, `header`/`body` (obrig.)/`footer` (html), `htmlTemplate`, `versionNumber`.
- `shortcut`: `type` (`htmlText` padrão, `functionBody`, `htmlEscapeSpecialChars`, `image`, `jsEscapeSingleQuotes`, `message`, `jsMessageEscapeSingleQuotes`) + conteúdo.
- `classicNavigationBarEntry`: `label`, `sequence`, `target` (obrig.), `imageIconCssClasses`, `feedbackEntry`.
- `concatenatedFile`: `concatenatedFileUrl`, `singleFileUrls`, `onlyForPage`.
- `searchConfig` (Search Configurations): `type` (`simple` padrão, `vector`, `text`, `ubiquitous`, `apexList`), fonte e mapeamento.
- `aiAgent` (+ `tool`): `service`, `systemPrompt`, `welcomeMessage`, `type` (`text`, `jsonObject` + `jsonSchema`), `temperature`.
- `taskDefinition` (+ `action`, `parameter`, `participant`), `workflow` (+ `version`, `parameter`; versões com `activity`, `connection`, `variable`, `participant`).
- `componentGroup` (+ `component`), `developerComment` (`pages`, `comments`), `languageMapping`, `dynamicTranslation`, `pwaShortcut`, `pwaScreenshot`, `reportQuery` (+ `sourceQuery`), `reportLayout`, `jsonSource`, `jsonDualityView`, `dataLoadDefinition`, `legacyDataLoadDefinition`, `mapBackground`.

Componentes **de workspace** (sem pai `app`) também têm forma APEXlang: `appGroup`, `authenticationServer`, `fileServer`, `genAIService`, `printServer`, `restDataSourceServer`, `restEnabledSqlDatabase`, `vectorProvider`, `webCredential` (tipos `basicAuthentication`, `oauth2ClientCredentialsFlow`, `oci`, `httpHeader`, `urlQueryString`, `keyPair`, …) e `file` de workspace.

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

---

## 10. Pegadinhas

### Form ou Interactive Grid sem edição: o bloco `edit { enabled: true }` (default `false`)
**Sintoma:** Form não grava/alterar campos ou Interactive Grid não permite editar; no export a região não tem bloco `edit`.
**Causa:** na referência APEXlang, `region.edit.enabled` tem **default `false`** e se aplica a Form e Interactive Grid; como defaults são omitidos, uma região sem `edit { … }` é somente leitura. `allowedOperations` (`add`, `update`, `delete`) só se aplica com `enabled: true`.
**Correção em APEXlang:** acrescente na região:
```
edit {
    enabled: true
    allowedOperations: [
        add
        update
        delete
    ]
}
```
Para IG, garanta também o processo `interactiveGridAutoRowProcessing` com `editableRegion: @<ig>`; para Form, `formInitialization` + `formAutoRowProcessing` com `formRegion`. Valide com `apex validate` e importe.
**No App Builder (doc 26.1):** o htmdb descreve o caminho *Property Editor › aba Attributes › grupo Edit › Enabled = On* (para IG, ligar isso cria o processo de gravação automaticamente), e o assistente de criação tem *Editing Enabled*.
**Divergência com `docs/ai-context`:** o `docs/ai-context/09-erros-e-solucoes.md` §4.8 e o `08` registram que, no 26.1.5 usado pelo time, o painel não mostra a aba Attributes nem a seção Edit, e que o bloco só vem em regiões criadas pelo assistente. A doc oficial 26.1 descreve a aba Attributes; a referência APEXlang confirma que o bloco é uma propriedade comum (com default `false`) e pode ser escrita à mão no `.apx`. Ou seja: pelo Builder, siga o `ai-context` (crie pelo assistente ou peça print); por APEXlang, adicionar o bloco é suportado pela referência.
**Prevenção:** depois de criar uma região editável, procure `edit {` no `.apx`.

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`region.edit`), [Making an Existing Interactive Grid Editable](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/making-an-existing-interactive-grid-editable.html), [Understanding Form Types](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-forms-types.html)

### Atributos específicos de tipo (`settings`, `storage`, `invoke`) não constam da referência genérica
**Sintoma:** você procura na API Reference como escrever o `subtype: email` de um text field, o `jsCode` de uma ação *Execute JavaScript Code*, o `names` de uma authorization *is in role*, o `storage` de um image upload ou o `invoke` de um processo *Invoke API* e não encontra.
**Causa:** a referência descreve as propriedades comuns de `pageItem`, `action`, `authorization`, `process` etc.; os atributos de cada tipo nativo vêm do metadado do tipo (equivalente ao grupo *Settings* do Page Designer) e não estão listados. O tipo (`type`/`action`) é "SUPPORTED UI" na EBNF.
**Correção:** copie o bloco de um componente do mesmo tipo já exportado (o projeto tem exemplos de quase todos), ou crie o componente no Builder e exporte; depois valide. O VS Code (SQL Developer) oferece code completion com o mesmo metadado.

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html), [Editing APEXlang in Visual Studio Code](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/editing-apexlang-visual-studio-code.html)

### Identificadores gerados pelo APEX: executionMappingIdentifier, savedReportMappingIdentifier, endUserAlias, reportColumnQueryId
**Sintoma:** diffs inesperados ou relatórios salvos/processos que perdem vínculo após editar o `.apx`.
**Causa:** o export inclui identificadores gerados (`advanced.executionMappingIdentifier` em processos, `advanced.savedReportMappingIdentifier` em IR/IG, `advanced.endUserAlias` em colunas de IR, `reportColumnQueryId`/`derivedColumn` em colunas de Classic Report). A referência só os lista como strings opcionais, sem explicar a geração.
**Correção/Prevenção:** ao editar, **preserve** os valores existentes; ao criar componentes novos à mão, omita-os e deixe o APEX gerar no import (comportamento não documentado: confira o reexport).

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`process.advanced`, `region.advanced`, `column`)

### `javascript` x `javascript-browser` x `javascript-mle` nos blocos de código
**Sintoma:** código JS não reconhecido/validação reclama do bloco, ou JS de servidor tratado como de navegador.
**Causa:** os indicadores documentados são `javascript-browser` (navegador) e `javascript-mle` (servidor). Cada propriedade de código declara a linguagem esperada.
**Correção:** use ```` ```javascript-browser ```` em `jsCode`, `executeWhenPageLoads`, `initJavaScriptFunction` e afins; ```` ```javascript-mle ```` em `javaScriptExpression`/`javaScriptFunctionBody`/`javaScriptCode`.

Fonte: [Reading APEXlang Syntax](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/reading-apexlang-syntax.html)

### `javaScript.fileUrls` recebe URLs, não código
**Sintoma:** página quebra ou o import aceita mas o navegador tenta baixar "arquivos" estranhos.
**Causa:** `page.javaScript.fileUrls` (e `css.fileUrls`) são arrays de URLs; código colado ali vira uma lista de URLs inválidas. (Foi o bug histórico da Home registrado no `docs/ai-context/02` §5.)
**Correção:** código vai em `functionAndGlobalVariableDeclaration` ou `executeWhenPageLoads` (bloco ```` ```javascript-browser ````); arquivos em `fileUrls` com `#APP_FILES#…#MIN#.js`.

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`page.javaScript`)

### Autorização no menu não protege a página
**Sintoma:** usuário sem permissão abre a página digitando a URL.
**Causa:** `security.authorizationScheme` em `entry` de lista só controla a exibição do link; a página só é protegida pelo seu próprio `security.authorizationScheme`.
**Correção:** declare `security { authorizationScheme: @x }` no componente `page`.

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`page.security`, `entry.security`)

### Static ID não é o id do DOM (`apex.region`, seletores CSS/jQuery)
**Sintoma:** `document.getElementById('minha-regiao')` ou `#minha-regiao` no CSS não encontram a região cujo `.apx` é `region minha-regiao (`.
**Causa:** desde o 26.1, o identificador APEXlang é o Static ID; o id do HTML é o `advanced.htmlDomId` (antes chamado Static ID). Sem `htmlDomId`, o APEX gera um ID interno.
**Correção:** defina `advanced { htmlDomId: minha_regiao }` quando JS/CSS precisar de id fixo, e use `#DOM_ID#` em templates.

Fonte: [Changed Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/changed-behavior.html), [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html) (`htmlDomId`)

### Outras pegadinhas rápidas de edição manual de .apx
- Uma propriedade por linha; não junte `execution { sequence: 10 fireOnInit: false }` numa linha (o `docs/ai-context/02` condensa só para leitura).
- Arrays: cada linha é um elemento; template option composta (`t-Region--removeHeader js-removeLandmark`) fica numa linha só.
- Renomear alias de página exige renomear o arquivo `pNNNNN-alias.apx`.
- Trocar template exige revisar `templateOptions`.
- Não edite `.apex/apexlang.json`; não ponha o ID da app em `application.apx` (ele fica em `deployments/default.json`).
- Componentes com espaço no id precisam de aspas (`file "Fotos Colaboradores/x.jpg"`).
- Para referências: `@` em propriedades COMPONENT, nome simples em propriedades ITEM (`when.items`, `serverSideCondition.item`).
- `fireOnInit` é `true` por padrão em ações de DA: ações em eventos que não são `ready` rodam também no carregamento se você não puser `fireOnInit: false`.
- O import substitui a app inteira: exporte antes de importar se houve mudança no Builder.

Fonte: [Reading APEXlang Syntax](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/reading-apexlang-syntax.html), [Using SQLcl with APEXlang](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-sqlcl-apexlang.html), [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

---

## 11. Aplicação no Corlix Hub

### Onde fica o APEXlang do Corlix Hub e como ele chega ao Git
- Fonte da app 100 (`CORLIXHUB`, workspace `WKSP_CORLIXHUB`): `corlixhub/` em APEXlang, `mmdVersion` `26.1.0+3102`, ID em `corlixhub/deployments/default.json` (`"id" : 100`). Estrutura: `application.apx`, `page-groups.apx`, `pages/p*.apx` (25 páginas), `shared-components/` (`acl-roles`, `app-items`, `app-processes`, `authentications`, `authorizations`, `breadcrumbs`, `build-options`, `component-settings`, `lists`, `lovs`, `static-files` + pasta `static-files/`), `shared-components/themes/universal-theme/` (theme.apx, page/region/button/classic-report templates customizados, static-files do tema) e `supporting-objects/` (vazio na prática).
- `database/f100.sql` é o **mesmo app no formato SQL** (export single file): só consulta com `grep`, nunca edição.
- O pipeline de backup (`scripts/backup/backup.sql`) gera os dois formatos com SQLcl: `apex export -applicationid &APP_ID -exptype APEXLANG -dir … -skipexportdate -overwrite-files` e `apex export … -exptype SQL,CHECKSUM-SH256 -expaclassignments -exppubreports -expsavedreports …`. O job publica `corlixhub/` e `database/f100.sql` na `DEV` com commits `chore(backup): …` (ver `docs/ai-context/01` §8.1). Como o export APEXlang não leva relatórios salvos de usuários nem atribuições ACL, eles só existem no SQL.
- Restaurar/aplicar: `apex import -input <pasta>/apexlang/…` (ou `@…/sql/f100.sql`), conectado como dono do schema.

Fonte: [Using SQLcl with APEXlang](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-sqlcl-apexlang.html), [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### Fluxo recomendado para um agente editar `corlixhub/**/*.apx`
1. **Antes:** confirme com o time se houve mudança no App Builder depois do último export/backup. O import APEXlang substitui a app inteira; se houver mudança no Builder, reexporte (`apex export -applicationid 100 -exptype APEXLANG`) e faça o merge antes (fluxo da seção 4).
2. **Editar** só os `.apx` (e static files), seguindo a forma do export: uma propriedade por linha, 4 espaços, blocos de código com `sql`/`plsql`/`javascript-browser`/`html`/`css`.
3. **Validar** sem conexão, na raiz da app: `sql /nolog` → `apex validate -input corlixhub` (ou `cd corlixhub` e `-input .`). Corrija até `Validation successful`.
4. **Importar** (quando o time pedir): `apex import -input corlixhub` conectado como `WKSP_CORLIXHUB`, ou ZIP pelo Import wizard (exige ORDS 26.1.1+ e schema REST-enabled).
5. **Conferir** no Builder (APEXlang View da página) e atualizar o documento correspondente em `docs/ai-context/`.

Regras do projeto que se traduzem em APEXlang:
- Página administrativa: `security { authorizationScheme: @admin-rh }` (ou `@administration-rights`, `@gestor`, `@colaborador`…) **no componente `page`**, não só na `entry` do menu.
- Multiempresa: toda `sqlQuery`/`plsqlCode` de negócio filtra `id_empresa = :G_ID_EMPRESA` (exemplos corretos: `lov-departamento-empresa`, `lov-colaborador-ativo`, Cards de comunicados da Home, série do Dashboard RH).
- Links: as páginas usam `security.pageAccessProtection: argumentsMustHaveChecksum`; prefira `link.target { page items }` declarativo (o APEX gera checksum) e, em PL/SQL/HTML gerado, `apex_page.get_url`. Não monte `f?p=` à mão.
- UI em pt-BR: `label`, `name`, `errorMessage`, `whenNoDataFound`, `confirmation.message` em português.
- Novos static files: arquivo em `shared-components/static-files/` **e** `file … ( mimeType charSet )` em `static-files.apx`; CSS sempre com o par `.min.css` (o app usa `#APP_FILES#corlix-tema#MIN#.css` e `#APP_FILES#custom#MIN#.css` em `application.apx › css.fileUrls`).

Fonte: [Using SQLcl with APEXlang](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-sqlcl-apexlang.html), [Using App Builder and External Tools Together](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-app-builder-and-external-tools-together.html)

### Convenções do export do Corlix Hub (identificadores, templates, slots)
- Identificadores de região/botão/DA são slugs gerados do nome, às vezes com acento (`region configurações`, `dynamicAction endereço-por-cep`) ou genéricos (`region new`, `region novo`). Em componentes novos, use slugs ASCII descritivos (`region filtros-dashboard`) e nunca reaproveite o id de outro componente da mesma página.
- Templates do UT com `@/` (`@/standard`, `@/modal-dialog`, `@/wizard-modal-dialog`, `@/blank-with-attributes`, `@/buttons-container`, `@/interactive-report`, `@/title-bar`, `@/text`, `@/text-with-icon`, `@/optional-floating`, `@/required-floating`); templates customizados sem barra: `@corlix-standard-page` (page template com os slots `afterLogo`/`afterNavigationBar` usados pela Global Page), `@cards-container-image-first`, `@chat-contatos`, `@chat-mensagens`, `@html-button-legacy-apex-5-migration`. O tema padrão de páginas é `componentDefaults.page: @corlix-standard-page`, mas várias páginas declaram `@/standard` (ver `docs/ai-context/02` §8).
- Formulários modais seguem o padrão do assistente (p16, p27): região `form` com `edit { enabled: true allowedOperations }`, itens com `source.formRegion`, PK `hidden` com `queryOnly`/`primaryKey`/`checksumRequiredSessionLevel`, botões `CANCEL` (`triggerAction cancelDialog`), `CREATE`/`SAVE`/`DELETE` com `databaseAction` e condição na PK, processos `formInitialization` (`beforeHeader`), `formAutoRowProcessing` e `closeDialog` com `requestIsContainedInValue CREATE,SAVE,DELETE`.

Fonte: [Reading APEXlang Syntax](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/reading-apexlang-syntax.html), [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Divergências e pontos a confirmar entre a doc oficial e o `docs/ai-context`
| Tema | Doc oficial 26.1 | `docs/ai-context` | Como agir |
|---|---|---|---|
| Ligar edição de Form/IG | htmdb: *Attributes › Edit › Enabled*; APEXlang: `region.edit.enabled` (default `false`) editável no `.apx` | 08 §1 regra 11 e 09 §4.8: no 26.1.5 o painel não tem aba Attributes nem seção Edit; bloco só vem pelo assistente | No Builder, siga o ai-context (assistente ou print). Em APEXlang, adicionar `edit { enabled: true allowedOperations [...] }` é válido pela referência; valide e confira no Builder (confirmar no 26.1.5) |
| `executionMappingIdentifier` | Listado como string opcional, sem regra de geração | 02 §1.6: preservar; omitir em processo novo (não verificado) | Mesmo procedimento; confirme no reexport |
| Escape `\#COL#\` em `target.items` | Não documentado | 02 §1.1/§8: manter o escape | Preserve como exportado; copie o padrão do mesmo tipo de componente |
| Comentários `//` | EBNF aceita `//` e `/* */` como comentários APEXlang | 02 §1.1: "aparecem só por acidente" | Não use comentários APEXlang; documente em `comments { comments: … }` |
| Import de página isolada | Não suportado em APEXlang (só SQL) | — | Para mudar uma página, importe a app inteira |

Fonte: [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html), [Making an Existing Interactive Grid Editable](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/making-an-existing-interactive-grid-editable.html), [New Features](https://docs.oracle.com/en/database/oracle/apex/26.1/htmrn/new-features.html)

### Checklist antes de entregar uma mudança em .apx
- [ ] O arquivo certo foi editado (`corlixhub/…`, nunca `database/f100.sql`)? Nome do arquivo de página bate com número e alias?
- [ ] Ids novos são únicos no escopo e ASCII; `buttonName` único; nenhuma referência `@x` aponta para id inexistente?
- [ ] `@` só em propriedades COMPONENT; nomes simples em `items`, `item`, `itemName`, `pageItemsToSubmit`?
- [ ] Blocos de código com o indicador certo (`javascript-browser`, não `javascript`)?
- [ ] Defaults não foram escritos à toa e defaults que precisavam mudar foram escritos (`fireOnInit: false`, `edit.enabled: true`)?
- [ ] Identificadores gerados (`executionMappingIdentifier`, `savedReportMappingIdentifier`, `endUserAlias`, `reportColumnQueryId`) preservados?
- [ ] Página administrativa com `security.authorizationScheme`; SQL filtrando `id_empresa`; textos em pt-BR?
- [ ] Static files novos registrados em `static-files.apx` (com `.min`)?
- [ ] `apex validate -input corlixhub` sem erros?
- [ ] Documento correspondente em `docs/ai-context/` atualizado?

Fonte: [Using SQLcl with APEXlang](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-sqlcl-apexlang.html), [APEXlang API Reference](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)
