# 08 · API JavaScript do APEX

> Base: documentação oficial Oracle APEX 26.1 (JavaScript API Reference `aexjs`, todas as 47 páginas; App Builder User's Guide `htmdb`: *Managing Page Attributes*, *Understanding Application Processes*, *Understanding Dynamic Actions*; Developer's Companion `apxdc`: *Understanding and Customizing Grid Behavior*, *Displaying Messages with JavaScript*, *Understanding AJAX and Redirect*, *Providing App-Wide Helper Functions* e páginas vizinhas). Gerado em 21/10/2026.

**Sumário**

1. Onde colocar JavaScript numa app APEX (atributos de página, arquivos, Dynamic Actions, ordem de carga, legado)
2. Namespace `apex` (raiz): `apex.env`, `apex.items`, `apex.regions`, `apex.jQuery`, `apex.gPageContext$`
3. Eventos do APEX (`apexafterclosedialog`, `apexbeforepagesubmit`, `apexafterrefresh`…) e `apex.event`
4. `apex.item`, interface `item` e `numberFieldItem`
5. `apex.region`, interface `region` e as interfaces de região (IR, Cards, Template Component, Faceted Search/Smart Filters, Map)
6. `apex.server` (Ajax Callback, `x01`–`x20`, `f01`–`f20`, `pageItems`, filas, `loadScript`)
7. `apex.message`
8. `apex.page` (submit, confirm, validate, Warn on Unsaved Changes)
9. `apex.navigation` (redirect, dialog, popup)
10. `apex.da`
11. `apex.lang`, `apex.locale`, `apex.date`
12. `apex.util`, `apex.util.delayLinger`, `htmlBuilder`, templates no cliente
13. `apex.debug`, `apex.storage`, `apex.theme`, `apex.widget`, `apex.pwa`
14. `apex.actions` e interface `actions`
15. `apex.model` e interface `model`
16. Interactive Grid: widget `interactiveGrid` e `interactiveGridView`
17. Widget `grid`
18. Widgets `tableModelViewBase`, `tableModelView` e `recordView`
19. Widgets `menu`, `menuButton` e `iconList`
20. Widget `treeView` e interface `treeNodeAdapter`
21. Funções globais (`$v`, `$s`, `$x`… *Non-namespace APIs*)
22. Problemas conhecidos e pegadinhas (formato de caso)
23. Aplicação no Corlix Hub

Convenções deste documento: "Since" indica a versão em que a API apareceu (quando a doc informa); **(deprecated)** marca o que a doc declara obsoleto. Assinaturas seguem a doc: parâmetro com sufixo `opt` na doc aparece aqui entre colchetes, por exemplo `setValue(pValue, [pDisplayValue], [pSuppressChangeEvent])`.

---

## 1. Onde colocar JavaScript numa app APEX

### Lugares certos para JavaScript numa página APEX (Function and Global Variable Declaration, Execute when Page Loads, File URLs)

O APEX monta a página por você, então o código JS entra em pontos específicos e não em `<script>` soltos. A página tem um grupo **JavaScript** no Property Editor com três atributos:

| Atributo da página | Quando roda | Use para |
|---|---|---|
| **File URLs** | Arquivos carregados depois das bibliotecas do APEX, um URL por linha | Bibliotecas de terceiros e seus próprios `.js`. Aceita `#MIN#`, `#MIN_DIRECTORY#` e `#APP_VERSION#` |
| **Function and Global Variable Declaration** | Depois das bibliotecas do APEX e dos *File URLs*, **antes** do *document ready* (DOMContentLoaded / jQuery ready) | Declarar funções e variáveis globais usadas pela página. O código substitui o token `#PAGE_JAVASCRIPT#` do page template |
| **Execute when Page Loads** | Depois do *document ready* e depois de todo o JS gerado pelo APEX | Código de inicialização: ligar handlers, ajustar a UI depois que os componentes existem |

Regras da doc:
- Não escreva `<script>` nem `</script>` nesses atributos: só o código.
- Evite `<script>` em atributos que aceitam HTML, handlers inline (`onclick="..."`) e o pseudo-protocolo `javascript:` em atributos de URL.
- O código de página é bom para funções específicas de uma página e para testar antes de mover para um arquivo `.js`. Se o mesmo código serve a várias páginas, coloque num arquivo (cache do navegador e sem duplicação).
- Handlers de eventos que precisam existir **antes** de um widget ser inicializado (ex.: `interactivegridviewchange`) vão em *Function and Global Variable Declaration*, não em *Execute when Page Loads* (exemplo da própria doc do `interactiveGrid`).
- `apex.actions.add(...)` na global só funciona depois do DOM pronto. Em *Function and Global Variable Declaration* ou num arquivo, embrulhe em `$( function() { ... } )`.

Fonte: [Introduction (JavaScript API)](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/index.html), [Managing Page Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-page-attributes-in-page-designer.html)

### Ordem de carga do JavaScript no page template (#APEX_JAVASCRIPT# … #GENERATED_JAVASCRIPT#)

O page template define **a ordem em que os scripts são incluídos** (a ordem de execução depende também de eventos como o *document ready*). Os tokens ficam no fim do `<body>`, nesta ordem:

1. `#APEX_JAVASCRIPT#`: bibliotecas do APEX
2. `#THEME_JAVASCRIPT#`: arquivos do tema
3. `#TEMPLATE_JAVASCRIPT#`: JS de templates (região, lista…) usados na página
4. `#APPLICATION_JAVASCRIPT#`: *File URLs* de Shared Components > User Interface Attributes
5. `#PAGE_JAVASCRIPT#`: JS da página
6. `#GENERATED_JAVASCRIPT#`: código gerado pelo APEX para os componentes

Se você criar um page template próprio, não mude essa ordem. Na dúvida sobre onde o código caiu, veja o código-fonte da página e use `console.log` ou `apex.debug`.

O APEX inclui sozinho os arquivos de que a página precisa (ex.: página com Interactive Grid recebe `model.js`, `widget.interactiveGrid.js` etc.). Fora do modo debug são carregados minificados e muitas vezes concatenados; os mais usados vão em `desktop.min.js` (`desktop_all.min.js` inclui o jQuery). Esse empacotamento muda entre versões, então não dependa dele. Todas as APIs ficam em `#APEX_FILES#libraries/apex/`. Só inclua um arquivo do APEX à mão se usar uma API ou widget sem o componente correspondente na página, o que é raro. Você pode criar arquivos concatenados próprios em Shared Components > User Interface Attributes: *Create Concatenated File*.

Fonte: [Introduction (JavaScript API)](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/index.html)

### Arquivos JavaScript estáticos, minificação e #MIN# / #MIN_DIRECTORY#

Boa prática: o grosso do código fica em arquivos. Opções:
- **Static Application Files** (Shared Components): servidos pelo APEX, referenciados por `#APP_FILES#`. Ao salvar um `.js` o App Builder **gera o minificado automaticamente** (`app.js` → `app.min.js`).
- **Static Workspace Files**: compartilhados entre apps (`#WORKSPACE_FILES#`).
- Um servidor web seu.

Minificado: fica numa subpasta `minified/` relativa ao original ou tem `.min` no nome. Na URL use `#MIN#` (vira `.min`) e/ou `#MIN_DIRECTORY#` (vira `minified/`). Em execução normal o APEX carrega o minificado; **em modo debug carrega o original**, o que facilita depurar. Exemplo:

```
#APP_FILES#appUtils#MIN#.js
```

Para carregar um arquivo em **todas as páginas**, informe a URL uma vez em Shared Components > User Interface > User Interface Attributes (aba JavaScript, *File URLs*, um por linha), em vez de repetir em cada página. Templates (região, lista etc.) também têm atributos de JS que são incluídos onde o template é usado.

Fonte: [Introduction (JavaScript API)](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/index.html), [Including Helper Functions in All Pages](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/including-helper-functions-all-pages.html), [Adding Static Application JavaScript File](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/adding-static-application-javascript-file.html)

### Biblioteca de funções da aplicação com namespace (padrão IIFE `app.js`)

A doc recomenda juntar as funções reutilizáveis num único símbolo global, como um package PL/SQL: funções públicas no objeto retornado e privadas dentro do bloco. O padrão é uma IIFE (*immediately invoked function expression*) que recebe `apex.jQuery` como `$`:

```javascript
// app.js em Static Application Files
const app = (function($) {
    // privadas
    function normalizar(v) { return (v || ''); }

    // públicas
    function areDifferent(x, y) {
        return normalizar(x) !== normalizar(y);
    }
    function setDialogTitle(title) {
        apex.util.getTopApex()
                 .jQuery(".ui-dialog-content")
                 .dialog("option", "title", title);
    }
    return { areDifferent, setDialogTitle };
})(apex.jQuery);
```

Pegadinhas citadas: JavaScript não tem sobrecarga como PL/SQL. Se duas funções tiverem o mesmo nome, vale a última definida. Para parâmetros opcionais, teste `typeof p === "undefined"` ou use parâmetros desestruturados com valor padrão.

Nota: `apex.util.getTopApex()` aparece nos exemplos do Developer's Companion, mas **não está listado** na página de referência de `apex.util` do 26.1.

Fonte: [Using JavaScript Namespace Template](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-javascript-namespace-template.html), [Comparing Namespace to PL/SQL Package](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/comparing-namespace-pl-sql-package.html)

### JavaScript em Dynamic Actions (Execute JavaScript Code, condição JavaScript Expression e `this`)

- A ação **Execute JavaScript Code** roda seu código quando o evento da DA acontece. DAs da Global Page (página 0) valem para todas as páginas, sujeitas à Server-Side Condition.
- Também há JS em ações como *Set Value* (tipo JavaScript Expression) e na **Client-side Condition** do tipo *JavaScript Expression*.
- Dentro do código da DA, `this` traz o contexto da ação. A doc cita:
  - `this.data`: dados do evento. No *Dialog Closed* traz os itens devolvidos pelo diálogo (`this.data.P2_EMPNO_EDITED`); em *After Refresh*/*Before Refresh* traz o `refreshObjectData` passado ao `apex.server.process`/`plugin`.
  - `this.browserEvent`: o evento do navegador (ex.: `this.browserEvent.key === "Enter"`).
  - `this.resumeCallback`: callback para `apex.da.resume` em ações assíncronas (ver §10).
- Ações que chamam o servidor (Execute Server-side Code, Refresh) usam Ajax: *Items to Submit* define o que vai do navegador para a sessão e *Items to Return* o que volta.

Fonte: [Understanding Dynamic Actions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-dynamic-actions.html), [About Calling JavaScript Using a Dynamic Action](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-and-editing-dynamic-actions.html), [Understanding AJAX and Redirect](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-ajax-and-redirect.html), [Understanding and Customizing Grid Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-and-customizing-grid-behavior.html)

### Código de inicialização de regiões e itens (Initialization JavaScript Function / JavaScript Initialization Code)

Algumas regiões e itens (Interactive Grid, suas colunas, charts, mapas…) têm um atributo **Advanced: JavaScript Initialization Code** (a doc também o chama de *Initialization JavaScript Function* e *Advanced JavaScript Code*). Ele recebe uma função que **recebe o objeto `options` e devolve o mesmo objeto alterado** antes do widget ser criado:

```javascript
function( options ) {
    apex.util.getNestedObject( options, "defaultGridViewOptions" ).footer = false;
    return options;
}
```

- O servidor só manda as opções que diferem do padrão, então objetos aninhados podem não existir. Use `apex.util.getNestedObject` para criá-los sem apagar o que já existe.
- Use para o que precisa estar pronto **antes** da criação (features, toolbar, `initActions`, paginação, opções de view e de model). Depois de criado, use as APIs de região, widget, actions e model.
- O caminho exato do atributo no Property Editor do 26.1.5 deve ser conferido na tela (confirmar no 26.1.5).

Fonte: [Introduction (JavaScript API)](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/index.html), [interactiveGrid](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/interactiveGrid.html), [Understanding and Customizing Grid Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-and-customizing-grid-behavior.html)

### APIs JavaScript legadas e jQuery Migrate (Include Deprecated or Desupported Javascript Functions)

Funções deprecated e desupported foram movidas para arquivos `/i/libraries/apex/legacy*.js`. Em Shared Components > User Interface > User Interface Attributes há caixas **Include Deprecated or Desupported Javascript Functions** e uma opção para incluir o **jQuery Migrate** (registra no console o uso de APIs jQuery obsoletas).

- Apps novas: nenhum arquivo legado é incluído por padrão.
- Apps migradas: vêm com a opção do legado mais recente marcada, por compatibilidade. Para desligar, procure no app e nos `.js` referências às funções do arquivo legado e só então desmarque.
- A biblioteca **jQuery UI está deprecated** no APEX, mas ainda é usada por componentes internos (os widgets do APEX usam a *widget factory* do jQuery UI).

Fonte: [Introduction (JavaScript API)](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/index.html)

### Plug-ins e APEX_JAVASCRIPT para modularizar JavaScript

O jeito mais modular de reaproveitar código é criar plug-ins (Template Component, Region, Item, Dynamic Action). O plug-in controla o que o servidor renderiza, inclusive JS e arquivos enviados com o plug-in. No servidor, veja `APEX_JAVASCRIPT` (`ADD_3RD_PARTY_LIBRARY_FILE`, `ADD_ONLOAD_CODE`). No cliente, plug-ins usam `apex.item.create`, `apex.region.create`, `apex.server.plugin` e `apex.da.resume` (seções 4, 5, 6 e 10).

Fonte: [Introduction (JavaScript API)](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/index.html)

---

## 2. Namespace `apex` (raiz)

### Namespace apex: sub-namespaces, propriedades e funções

O APEX organiza as APIs em namespaces (objetos globais singleton). Há um namespace raiz `apex` e sub-namespaces. Símbolos globais que começam com `apex` ou `$` são **reservados pelo APEX**. Funções que devolvem uma *interface* (ex.: `apex.item("P1_X")`) dão acesso a uma instância específica, com métodos e propriedades.

| Membro | Tipo | Descrição |
|---|---|---|
| `apex.actions`, `apex.da`, `apex.date`, `apex.debug`, `apex.event`, `apex.item`, `apex.lang`, `apex.locale`, `apex.message`, `apex.model`, `apex.navigation`, `apex.page`, `apex.pwa`, `apex.region`, `apex.server`, `apex.storage`, `apex.theme`, `apex.util`, `apex.widget` | namespaces | Ver seções seguintes |
| `apex.env` | object | Valores de ambiente (Since 21.2) |
| `apex.gPageContext$` | jQuery | Contexto da página atual (= `apex.jQuery(document)`) |
| `apex.items` | object | Todas as interfaces de item criadas com `apex.item.create` (Since 21.2) |
| `apex.regions` | object | Todas as interfaces de região criadas com `apex.region.create` (Since 21.2) |
| `apex.jQuery` | function | A cópia de jQuery que o APEX usa |
| `apex.item(pItemId)` → `item` | function | Interface do item |
| `apex.region(pRegionId)` → `region\|null` | function | Interface da região |
| `apex.submit()` | function | Alias de `apex.page.submit` |
| `apex.confirm()` | function | Alias de `apex.page.confirm` |
| `apex.userHasTouched()` → boolean | function | `true` se o usuário usou toque nesta sessão do navegador |

Fonte: [Namespace: apex](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.html)

### apex.env: APP_ID, APP_PAGE_ID, APP_SESSION, APP_USER e caminhos de arquivos no cliente

`apex.env` (Since 21.2) expõe no navegador os valores que no servidor seriam substitution strings:

| Propriedade | Conteúdo |
|---|---|
| `APP_USER` | usuário atual |
| `APP_ID` | ID da aplicação |
| `APP_PAGE_ID` | ID da página |
| `APP_SESSION` | ID da sessão |
| `APP_FILES` | caminho relativo dos Static Application Files |
| `WORKSPACE_FILES` | caminho relativo dos Static Workspace Files |
| `APEX_FILES` | caminho relativo dos arquivos distribuídos com o APEX |
| `APEX_VERSION` | versão completa da instância |
| `APEX_BASE_VERSION` | versão base da instância |

Use em arquivos `.js`, onde substitutions como `&APP_ID.` **não** são trocadas pelo servidor:

```javascript
apex.navigation.redirect( "f?p=" + apex.env.APP_ID + ":2:" + apex.env.APP_SESSION );
```

Cuidado: URL montada no cliente não tem checksum. Se a página de destino exige checksum nos argumentos, gere a URL no servidor (`APEX_PAGE.GET_URL`). Ver §9.

Fonte: [Namespace: apex](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.html)

### apex.jQuery, apex.gPageContext$, apex.items e apex.regions

- **`apex.jQuery`**: pode haver mais de uma cópia de jQuery na página (plugins antigos). Use `apex.jQuery` em vez de `$`/`jQuery` globais para garantir a mesma cópia que o APEX usa. Padrão: `var $ = apex.jQuery;` dentro da função, ou passar `apex.jQuery` para uma IIFE.
- **`apex.gPageContext$`**: contexto da página (o `document`). Eventos de página como `apexbeforepagesubmit` são disparados nele: `apex.jQuery( ".minha-classe", apex.gPageContext$ )`.
- **`apex.items`** e **`apex.regions`**: coleções das interfaces criadas por `apex.item.create`/`apex.region.create`. `apex.items.P1_NAME` equivale a `apex.item("P1_NAME")` e `apex.regions.minhaRegiao` a `apex.region("minhaRegiao")`. Itens ou regiões que não chamam `create` não aparecem nessas coleções, mas `apex.item()`/`apex.region()` ainda devolvem uma interface padrão.

Fonte: [Namespace: apex](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.html)

---

## 3. Eventos do APEX e `apex.event`

### Tabela de eventos do APEX (apexafterclosedialog, apexbeforepagesubmit, apexafterrefresh…)

Eventos jQuery disparados pelo APEX. Muitos têm um evento de Dynamic Action equivalente.

| Evento | Disparado em | Quando | DA equivalente | Dados do handler |
|---|---|---|---|---|
| `apexafterclosedialog` | elemento que abriu o diálogo (ou `apex.gPageContext$`) | diálogo modal **fechado** pela ação DA *Close Dialog* ou pelo processo *Close Dialog* | Dialog Closed | `{ dialogPageId, closeAction: "close", <ITEM>: valor... }` |
| `apexafterclosecanceldialog` | idem | diálogo fechado **ou cancelado** (Close/Cancel Dialog, X do diálogo, Esc) | Dialog Closed | `{ dialogPageId, closeAction: "close"\|"cancel", <ITEM>... }` |
| `apexbeforepagesubmit` | `apex.gPageContext$` | `apex.page.submit`/`confirm` antes de validar; pode ser cancelado | Before Page Submit | `request` (string) |
| `apexpagesubmit` | `apex.gPageContext$` | depois da validação, logo antes de enviar; não pode ser cancelado | n/d | `request` |
| `apexbeforerefresh` | item/elemento do `refreshObject` | antes de um item (cascading LOV) ou `refreshObject` atualizar | Before Refresh | `refreshObjectData` |
| `apexafterrefresh` | idem | depois do refresh | After Refresh | `refreshObjectData` |
| `apexselectionchange` | região | seleção mudou (com debounce de algumas centenas de ms) | n/d | `{ selectedValues: [] }` |
| `apexcurrentrowchange` | região | item/linha atual (foco) mudou | n/d | `{ currentValue }` |
| `apexbeginrecordedit` | região/model view | um registro vai começar a ser editado | n/d | `{ model, record, recordId }` |
| `apexendrecordedit` | idem | edição do registro terminou | n/d | `{ model, record, recordId }` |
| `apexreadyend` | `apex.gPageContext$` | fim de todo o carregamento da página, incluindo itens com `delayLoading` | n/d | n/d |
| `apexwindowresized` | `window` | algumas centenas de ms depois que o redimensionamento para | n/d | n/d |

Para botões, o elemento que abriu o diálogo é o próprio botão; para links de lista, a região da lista; na navegação global ou quando não dá para saber, o `document`.

Fonte: [Namespace: apex (Events)](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.html)

### Atualizar região quando um diálogo modal fecha (apexafterclosedialog / Dialog Closed)

O evento é disparado na **página que abriu o diálogo**, não no diálogo. Para reagir a qualquer diálogo:

```javascript
apex.gPageContext$.on( "apexafterclosedialog", function( event, data ) {
    // data.dialogPageId, data.closeAction e os itens de "Items to Return"
    apex.region( "emp" ).refresh();
} );
```

- Use `apexafterclosecanceldialog` se precisar reagir também ao cancelamento (X, Esc, Cancel Dialog).
- Declarativo: DA no evento **Dialog Closed** com *Selection Type* jQuery Selector `body` reage a diálogos abertos por qualquer elemento.
- Os valores devolvidos vêm dos itens listados em *Items to Return* do processo ou da ação *Close Dialog*. Na DA ficam em `this.data.<ITEM>`.
- Receita oficial para atualizar **só a linha editada** de um IG depois do diálogo: §16 (fetchRecords).

Fonte: [Namespace: apex](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.html), [Refreshing Region on Dialog Close](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/refreshing-region-dialog-close.html)

### Validação extra antes do submit (apexbeforepagesubmit e apexpagesubmit)

- `apexbeforepagesubmit` dispara antes da validação e pode ser cancelado por uma DA *Confirm* ou *Cancel Event*, então não garante que o submit vai acontecer.
- `apexpagesubmit` dispara depois da validação: é a última chance de mexer em itens antes do envio.
- Nos dois, **não faça processamento longo nem assíncrono, e nem Ajax** (síncrono ou assíncrono).

```javascript
// validação customizada (funciona se o botão tiver Execute Validations = Yes e
// compatibility mode >= 5.1, ou se apex.page.submit for chamado com validate: true)
apex.jQuery( apex.gPageContext$ ).on( "apexbeforepagesubmit", function() {
    var item = apex.item( "P1_CHECK_ME" );
    item.node.setCustomValidity( item.getValue() !== "valid" ? "Valor inválido" : "" );
} );

// última alteração antes do envio
apex.jQuery( apex.gPageContext$ ).on( "apexpagesubmit", function() {
    var item = apex.item( "P1_VALUE" );
    item.setValue( item.getValue().toUpperCase() );
} );
```

Fonte: [Namespace: apex](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.html)

### Bloquear UI durante refresh (apexbeforerefresh / apexafterrefresh)

Disparados por itens que suportam *Cascading LOV Parent Item(s)* e por `apex.server.process`/`plugin` quando a opção `refreshObject` é usada. O handler recebe `refreshObjectData`.

```javascript
apex.jQuery( "body" ).on( "apexbeforerefresh", function() {
    apex.jQuery( "#B1" ).prop( "disabled", true );
} ).on( "apexafterrefresh", function() {
    apex.jQuery( "#B1" ).prop( "disabled", false );
} );
```

Fonte: [Namespace: apex](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.html)

### Seleção e linha atual em relatórios (apexselectionchange, apexcurrentrowchange)

Regiões que suportam seleção ou navegação por teclado (Cards, Template Component, Interactive Report com seleção) disparam esses eventos genéricos. Alguns widgets também têm eventos próprios mais específicos (`interactivegridselectionchange`, `gridcurrentcellchange`).

```javascript
apex.region( "myReport" ).element.on( "apexselectionchange", function( event, data ) {
    console.log( data.selectedValues );   // normalmente as PKs
} );
apex.region( "myReport" ).element.on( "apexcurrentrowchange", function( event, data ) {
    console.log( data.currentValue );
} );
```

Fonte: [Namespace: apex](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.html)

### apexreadyend e apexwindowresized

- `apexreadyend`: disparado no fim de todo o carregamento do APEX. Ao contrário do *ready* padrão, espera também os itens com `delayLoading` (ver `apex.item.create`). Use quando precisar que itens lentos (JET, RequireJS) estejam prontos.
- `apexwindowresized`: disparado uma vez no `window`, depois que o redimensionamento para. É melhor que o `resize` nativo, que dispara muitas vezes.

```javascript
apex.jQuery( window ).on( "apexwindowresized", function() {
    if ( apex.theme.mq( "(min-width: 640px)" ) ) { /* layout largo */ }
} );
```

Fonte: [Namespace: apex](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.html), [Namespace: theme](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.theme.html)

### apex.event.trigger(pSelector, pEvent, [pData]) → boolean

Única função do namespace `apex.event`. Dispara um evento e informa se ele foi cancelado.

| Parâmetro | Tipo | Descrição |
|---|---|---|
| `pSelector` | jQuery/seletor | elemento em que o evento é disparado |
| `pEvent` | string | nome do evento |
| `pData` | string\|Array\|Object (opcional) | dados extras para o handler |

Retorna `true` se o evento foi **cancelado**.

```javascript
var cancelado = apex.event.trigger( "#myLink", "click", ["apples","pears"] );
```

Fonte: [Namespace: event](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.event.html)

---

## 4. `apex.item`, interface `item` e `numberFieldItem`

### apex.item: funções do namespace (create, addAttachHandler, isItem)

| Função | Descrição |
|---|---|
| `apex.item(pItemId)` → `item` | Interface do item (page item ou column item). Se o item não existe, `node` é `false`. Passar um Element em vez do nome é **deprecated** |
| `apex.item.create(pItemId, pItemImpl)` → object | Só para plug-ins de item: registra a implementação do tipo. Retorna um Deferred quando `delayLoading: true` (Since 5.1) |
| `apex.item.addAttachHandler(pHandler)` | Só para plug-ins: `pHandler(pContext$)` inicializa todas as instâncias do tipo quando a página inicializa, sem precisar renderizar chamada JS (Since 20.2) |
| `apex.item.isItem(pItemId)` → boolean | `true` só se o elemento tiver uma interface criada com `apex.item.create`. Itens simples sem `create` ainda funcionam com `apex.item()` mesmo dando `false` aqui |

```javascript
if ( apex.item.isItem( someId ) ) {
    apex.item( someId ).hide();
}
```

Fonte: [Namespace: item](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.item.html)

### Interface item: todas as propriedades e métodos

A interface vale para **page items** (com session state) e **column items** (de regiões editáveis como o Interactive Grid; o valor muda conforme o registro ativo e vem do model).

| Membro | Descrição | Since |
|---|---|---|
| `element` : jQuery | jQuery do elemento do item (`$()` se não existe). Uso principal: plug-ins | |
| `id` : string\|false | id do elemento; `false` se não existe | |
| `item_type` : string | tipo do item (ex.: `"NUMBER"`) | |
| `node` : Element\|false | elemento que melhor representa o valor; `false` se não existe | |
| `value` : string\|Array | atalho de leitura e escrita para `getValue`/`setValue`. Não serve para column items num contexto de trigger de DA | 21.2 |
| `addValue(pValue, [pDisplayValue])` | adiciona valor em item multivalor (nem todos suportam) | |
| `disable()` / `enable()` | desabilita / habilita a edição | |
| `displayValueFor(pValue, [pState])` → string | valor de exibição de um valor (select list, Popup LOV…) | 5.1 |
| `getMultiValueStorage()` → `{type, separator}\|null` | como o item multivalor guarda os valores (`"separated"` ou `"json-array"`) | 24.1 |
| `getSeparator()` → string\|null | separador do item multivalor (padrão `:`) | 24.1 |
| `getValidationMessage([pLabel])` → string | mensagem de validação (ou `""`) | 5.1 |
| `getValidity()` → ValidityState | estado de validação HTML5 (no mínimo `valid`) | 5.1 |
| `getValue()` → string\|Array | valor atual | |
| `hasDisplayValue()` → boolean | se há algo exibido no item (inclui placeholder) | 22.1 |
| `hide([pHideRow])` / `show([pShowRow])` | esconde/mostra o item e o label ou o container. `pHideRow`/`pShowRow` **deprecated** | |
| `isChanged()` → boolean | valor mudou desde a inicialização (usado pelo Warn on Unsaved Changes) | 5.1 |
| `isDisabled()` → boolean | se está desabilitado | 5.1 |
| `isEmpty()` → boolean | vazio, considerando espaços e o *Null Return Value* da LOV | |
| `isReady()` → boolean | se itens com carga lenta já estão prontos | 21.2 |
| `refresh()` | atualiza o item (ex.: busca as opções de uma select list) | |
| `removeValue([pValue])` | remove valor de item multivalor | |
| `setFocus()` | põe o foco no item | |
| `setStyle(pPropertyName, pPropertyValue)` | define estilo CSS (não é boa prática: prefira classes) | |
| `setValue(pValue, [pDisplayValue], [pSuppressChangeEvent])` | define o valor | |
| `whenReady()` → Promise | resolve quando o item com carga lenta fica pronto (só existe nesses itens) | 21.2 |

Fonte: [Interface: item](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/item.html)

### Ler e gravar valor de item no navegador (apex.item(...).getValue / setValue / .value)

**`getValue()`** devolve o valor **atual** no navegador: o inicial vem do session state (page item) ou do registro ativo do model (column item), mas reflete o que o usuário digitou ou o que foi definido por `setValue`. Itens multivalor (Shuttle, Select List com *Multiple Values*, Checkbox Group) devolvem **array**.

**`setValue(pValue, [pDisplayValue], [pSuppressChangeEvent])`**:

| Parâmetro | Tipo | Descrição |
|---|---|---|
| `pValue` | string \| Array.<string> | valor; array para multivalor |
| `pDisplayValue` | string (opcional) | valor de exibição quando difere do valor e o item não consegue descobrir sozinho (ex.: Popup LOV: `pValue` = retorno escondido, `pDisplayValue` = texto) |
| `pSuppressChangeEvent` | boolean (opcional, padrão `false`) | `true` não dispara o `change` |

Comportamento:
- **Não altera o session state**: o servidor só vê o novo valor depois do submit, de uma requisição Ajax que envie o item (`pageItems`, *Items to Submit*) ou de uma DA que salve.
- Por padrão dispara `change`, o que faz funcionarem as cascading LOVs e as DAs de Change.
- **Suprima o `change` quando estiver definindo o valor dentro de um handler de `change` do mesmo item**, ou você cria um loop infinito.
- O widget `grid` depende do `change` para atualizar o model. Se suprimir o evento num column item, chame `grid#setActiveRecordValue` (§17).

```javascript
apex.item( "P1_ITEM" ).setValue( "10" );                  // dispara change
apex.item( "P1_ITEM" ).setValue( "10", "SALES", true );   // Popup LOV, sem change
apex.item( "P1_ITEM" ).setValue( "10", null, true );      // sem display value, sem change

// atalhos equivalentes (Since 21.2)
var empno = apex.items.P1_EMPNO.value;
apex.items.P1_EMPNO.value = "100";
```

Item que pode não existir na página:

```javascript
var item = apex.item( "P1_OPTIONAL_ITEM" );
if ( item.node ) { item.setValue( novoValor ); }
```

Fonte: [Interface: item](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/item.html)

### $v, $v2 e $s: atalhos globais para valor de item

| Função | Equivale a | Retorno |
|---|---|---|
| `$v(pNd)` | `getValue` | **string**. Multivalor vira lista separada por `:` (ignora separador e storage type configurados) |
| `$v2(pNd)` | `getValue` | string ou array |
| `$s(pNd, pValue, [pDisplayValue], [pSuppressChangeEvent])` | `setValue` | n/d |

Pegadinha: para item multivalor com separador customizado (24.1+), `$v` usa sempre `:`. Use `getValue()` (array) ou `apex.util.toArray(valor, item.getMultiValueStorage())`.

Fonte: [Non-namespace APIs](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/global.html), [Interface: item](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/item.html)

### Mostrar, esconder, habilitar e desabilitar itens (show, hide, enable, disable)

- `hide()`/`show()`: com layout em grid (o normal no Universal Theme), se o label template tem um *Field Container* com `id="#CURRENT_ITEM_CONTAINER_ID#"` (id `<ITEM>_CONTAINER`), **o container inteiro** é escondido/mostrado. Sem isso, só o item e o label (`for` = id do item). Em column item, só o conteúdo da célula (no IG não esconde a coluna).
- `pHideRow`/`pShowRow` (layout em tabela HTML) estão **deprecated**.
- `disable()`/`enable()`: só para itens editáveis. A ação de DA *Disable*/*Enable* usa esses métodos.
- `isDisabled()` informa o estado. Use antes de ler um valor que não deve ser considerado.

```javascript
apex.item( "P1_ITEM" ).hide();
if ( !apex.item( "P1_ITEM" ).isDisabled() ) { valor = apex.item( "P1_ITEM" ).getValue(); }
```

Fonte: [Interface: item](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/item.html)

### Validação no cliente com a interface item (getValidity, getValidationMessage, data-valid-message)

- `getValidity()` devolve o ValidityState HTML5. **Não valida nada**: o navegador valida pelos atributos (`required`, `pattern`…) e você pode usar `setCustomValidity`.
- `getValidationMessage([pLabel])` usa `validationMessage` do elemento, ou o atributo customizado **`data-valid-message`** se existir (o texto deve dizer o que se espera, não o que deu errado). `#LABEL#` é substituído pelo label.
- `apex.page.validate()` e `apex.page.submit({validate:true})` usam isso e mostram os erros com `apex.message.showErrors`.

```javascript
var item = apex.item( "P1_ITEM" );
if ( !item.getValidity().valid ) {
    apex.message.alert( "Erro: " + item.getValidationMessage() );
}
```

Fonte: [Interface: item](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/item.html), [Namespace: page](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.page.html)

### isEmpty × hasDisplayValue, refresh, isChanged e itens com carga lenta (isReady / whenReady)

- `isEmpty()`: considera vazio só espaços/tab/form-feed e respeita o *Null Return Value* da LOV. Para saber se **há algo exibido** (inclusive o placeholder), use `hasDisplayValue()` (Since 22.1).
- `refresh()`: o significado depende do item; numa select list busca as opções no servidor. Raramente é preciso, porque *Cascading LOV Parent Items* já faz isso.
- `isChanged()`: base do *Warn on Unsaved Changes*.
- `isReady()`/`whenReady()`: só para itens que demoram a carregar (JET, RequireJS). Código de DA não precisa, porque o carregamento das DAs já espera esses itens.

```javascript
var theItem = apex.item( "P1_ITEM" );
theItem.whenReady().then( function() { theItem.setValue( "Algum valor" ); } );
```

Fonte: [Interface: item](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/item.html)

### Plug-in de item: apex.item.create(pItemId, pItemImpl) e as propriedades de pItemImpl

Chame `apex.item.create` mesmo com `pItemImpl` vazio, para o item integrar com DAs, `$v`/`$s`, validação e IG. `pItemImpl` pode ser um objeto (as propriedades são copiadas para a interface) ou uma função que recebe a interface base e a altera (útil para adicionar métodos próprios).

| Propriedade | Assinatura / tipo | Para que serve |
|---|---|---|
| `item_type` | string | tipo do item |
| `getValue` / `setValue` | `():string` / `(value, displayValue, suppressChangeEvent)` | valor; mesmo sobrescrito, o APEX sempre chama `afterModify` e dispara o `change` conforme o parâmetro |
| `displayValueFor` | `(value, [state]):string` | valor de exibição |
| `disable` / `enable` / `isDisabled` | funções | compostos ou widgets com API própria |
| `show` / `hide` | funções | não são chamadas se existir `<ITEM>_CONTAINER` (o container é escondido) |
| `isChanged` | `():boolean` | sem isso o Warn on Unsaved Changes não percebe a mudança |
| `getValidity` / `getValidationMessage` | funções | validação própria (dispensável se usa `setCustomValidity`) |
| `getPopupSelector` | `():string` | seletor do popup flutuante (necessário para funcionar no IG); o popup deve ter `tabindex=-1` |
| `setFocusTo` / `setStyleTo` | elemento, seletor ou função | alvo de `setFocus`/`setStyle` |
| `loadingIndicator` | `(loadingIndicator$):jQuery` | onde pôr o spinner em refresh (cascading LOV, Set Value) |
| `nullValue` | string | *Null Return Value* da LOV, para `isEmpty` e condições de DA |
| `refresh` | função | padrão dispara `apexrefresh` (legado) |
| `reinit` | `(value, display):function` | column items: reinicia valor a cada registro editado. Itens com cascading LOV devolvem a função que faz a cascata |
| `addValue` / `removeValue` | funções | itens multivalor |
| `storageType` / `separator` | `"separated"`\|`"json-array"` / string | armazenamento multivalor (separator é obrigatório com `"separated"`) |
| `delayLoading` | boolean | faz a página esperar o item inicializar. `create` devolve um Deferred **que precisa ser resolvido** |
| `afterModify` | função | **deprecated** |

```javascript
var lDeferred = apex.item.create( "P100_COMPANY_NAME", { delayLoading: true } );
// ... quando terminar de inicializar:
lDeferred.resolve();

apex.item.create( itemName, function( baseItem ) {
    baseItem.setToolbarMode = function( pMode ) { /* ... */ };
} );
apex.item( itemName ).setToolbarMode( "EXPANDED" );
```

Fonte: [Namespace: item](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.item.html)

### Number Field: interface numberFieldItem e getNativeValue (Since 21.2)

`apex.item("P1_NUM")` num item Number Field devolve a interface `numberFieldItem` (estende `item`, `item_type = "NUMBER"`). Ao perder o foco ou ao pressionar Enter, o número é formatado pela máscara do item. Na validação do cliente (padrão antes do submit), reporta obrigatório, número inválido e fora do mínimo/máximo.

Método extra: **`getNativeValue()` → number**, o valor como número JS (`NaN` se inválido). `getValue()` continua devolvendo string.

```javascript
var total = apex.item( "P1_QTD" ).getNativeValue() * apex.item( "P1_PRECO" ).getNativeValue();
```

Fonte: [Interface: numberFieldItem](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/numberFieldItem.html)

---

## 5. `apex.region`, interface `region` e interfaces de região

### apex.region: funções do namespace (create, destroy, findClosest, isRegion) — Since 5.1

| Função | Descrição |
|---|---|
| `apex.region(pRegionId)` → `region\|null` | interface da região pelo id/Static ID; `null` se não há elemento |
| `apex.region.create(pRegionId, pRegionImpl)` | plug-ins: define a implementação. `pRegionImpl` objeto ou função; deve ter `type`. Se usa widget jQuery UI, implemente `widget()` e `widgetName` para `call` funcionar |
| `apex.region.destroy(pRegionId)` | plug-ins: remove a interface (não remove o elemento do DOM) |
| `apex.region.findClosest(pTarget)` → `region\|null` | região que contém o elemento |
| `apex.region.isRegion(pRegionId)` → boolean | `true` só se a região chamou `create` |

Boa prática: **dê um Static ID (HTML DOM id) a toda região usada por JS**. Sem ele o APEX gera um id interno. O id vai para o template pelo `#DOM_ID#`.

```javascript
apex.jQuery( ".refresh-button" ).on( "click", function( event ) {
    var region = apex.region.findClosest( event.target );
    if ( region ) { region.refresh(); }
} );
```

Fonte: [Namespace: region](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.region.html)

### Interface region: propriedades e métodos

| Membro | Descrição |
|---|---|
| `element` : jQuery | elemento da região |
| `type` : string | tipo (`"generic"` quando a região não implementa interface; `"InteractiveGrid"`, `"InteractiveReport"`, `"Cards"`, `"TemplateComponent"`, `"Facets"`, `"SpatialMap"`…) |
| `widgetName` : string | nome do widget jQuery UI (se houver) |
| `parentRegionId` : string | região mestre num master-detail |
| `filterRegionId` : string | id da região Faceted Search/Smart Filters ligada (plug-ins); o APEX atualiza a região quando os filtros mudam e faz lock/unlock se `refresh` devolver Promise |
| `alternateLoadingIndicator(pElement, pLoadingIndicator$)` → jQuery | spinner alternativo para column items (nem toda região tem) |
| `call(pMethod, ...args)` → * | chama método do widget da região |
| `focus()` | foco na região (padrão: primeiro elemento tabulável) |
| `on(events, ...args)` / `off(events, ...args)` | liga/desliga handlers no widget; aceita nome curto do evento (`"selectionChange"`); **não é encadeável** |
| `refresh([pKeepPagination])` → Promise | busca dados novos ou se reconstrói |
| `widget()` → jQuery\|null | jQuery do widget (IG, Calendar, Tree…) |

Fonte: [Interface: region](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/region.html)

### Atualizar uma região por JavaScript (apex.region(...).refresh)

```javascript
apex.region( "myRegion" ).refresh();       // padrão
apex.region( "myRegion" ).refresh( true ); // Interactive Report mantém a página e o scroll
```

- Substitui o jeito legado de disparar `apexrefresh` no elemento (que ainda é o comportamento padrão para regiões sem interface).
- Nem toda região suporta refresh. O que acontece depende do tipo.
- `pKeepPagination`: segundo o Developer's Companion, **no 26.1 só tem efeito no Interactive Report**.
- O refresh **deveria** devolver uma Promise; se devolve depende da região/plug-in.
- Itens usados na query da região precisam estar em **Page Items to Submit** da região, ou o servidor usa o session state antigo.
- Uma região com Server-side Condition falsa **não existe no DOM**: `refresh()` não tem o que atualizar.

Fonte: [Interface: region](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/region.html), [Understanding and Customizing Grid Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-and-customizing-grid-behavior.html), [Referencing Page Item Values](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/referencing-page-item-values.html)

### Chamar métodos do widget da região (region.call, region.widget, region.on)

```javascript
// duas formas equivalentes
var r1 = apex.region( "emp" ).call( "getSelectedRecords" );
var r2 = apex.region( "emp" ).widget().interactiveGrid( "getSelectedRecords" );

// invocar uma action do IG
apex.region( "myGridRegion" ).widget().interactiveGrid( "getActions" ).invoke( "selection-add-row" );

// eventos com nome curto
apex.region( igId ).on( "selectionChange", function( event, data ) {
    console.log( data.selectedRecords.length );
} );
apex.region( igId ).off( "selectionChange" );
```

`call`, `on`, `off` e `widgetName` existem por compatibilidade com widgets jQuery UI (que está deprecated).

Fonte: [Interface: region](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/region.html)

### Interactive Report via JavaScript: interface interactiveReportRegion (Since 26.1)

`apex.region(id)` num Interactive Report devolve `interactiveReportRegion` (`type = "InteractiveReport"`, estende `region`).

| Método | Descrição |
|---|---|
| `focus()` | foca a linha atual (se há seleção) ou o primeiro elemento focável |
| `getCurrentRow()` → jQuery / `getCurrentRowValue()` → string | linha atual (a que tem ou teve o foco); valor = PK no `data-id` |
| `setCurrentRow(pRow$, [pFocus])` / `setCurrentRowValue(pRowValue, [pFocus])` | muda a linha atual (precisa estar renderizada) |
| `getSelection()` → jQuery / `getSelectedValues()` → string[] | linhas selecionadas / PKs |
| `setSelection(pElements$, [pFocus], [pNoNotify])` / `setSelectedValues(pValues, [pFocus], [pNoNotify])` → number | seleciona; dispara `apexselectionchange` (exceto com `pNoNotify`) |
| `selectAll([pFocus], [pNoNotify])` | seleciona todas as linhas visíveis |
| `getViewName()` → string | view atual: `REPORT`, `CHART`, `DETAIL`, `GROUP_BY`, `ICON`, `PIVOT` |
| `refresh([pKeepPagination])` | busca dados novos |

Fonte: [Interface: interactiveReportRegion](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/interactiveReportRegion.html)

### Cards via JavaScript: interface cardsRegion (Since 24.1)

Cards é renderizada no cliente: `model` como camada de dados e `tableModelView` como view. A interface (`type = "Cards"`) embrulha quase todos os métodos do `tableModelView`. Os cards são "items" (não confundir com page items).

| Grupo | Métodos |
|---|---|
| Paginação | `firstPage()`, `previousPage()`, `nextPage()`, `lastPage()`, `gotoPage(n)`, `loadMore()`, `getPageInfo()` |
| Dados | `getModel()`, `getRecords(pElements$)`, `refresh()` → Promise (busca no servidor), `refreshView()` (re-renderiza sem buscar) |
| Foco | `focus()`, `getCurrentItem()`, `getCurrentItemValue()`, `setCurrentItem(pItem$, [pFocus])`, `setCurrentItemValue(v, [pFocus])` |
| Seleção | `getSelection()`, `getSelectedRecords()`, `getSelectedValues()`, `setSelection(...)`, `setSelectedRecords(...)`, `setSelectedValues(...)`, `selectAll(...)` (disparam `tableModelView` `selectionchange` e `apexselectionchange`) |
| Herdados | `call`, `on`, `off`, `widget`, `element`, `filterRegionId`, `widgetName` |

Filtro instantâneo no cliente: veja `model.updateVisibility` (§15).

Fonte: [Interface: cardsRegion](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/cardsRegion.html)

### Template Component Report via JavaScript: interface templateReportRegion (Since 24.1)

Relatórios de Template Component são renderizados **no servidor** e têm poucos métodos no cliente (`type = "TemplateComponent"`): `firstPage`, `previousPage`, `nextPage`, `lastPage`, `refresh()` → Promise, `focus`, `getCurrentRow`, `getCurrentRowValue`, `setCurrentRow`, `setCurrentRowValue`, `getSelection`, `getSelectedValues`, `setSelection`, `setSelectedValues`, `selectAll`. O valor da linha é a PK no atributo `data-id`, normalmente gerado pelo placeholder `#APEX$ROW_IDENTIFICATION#`. A seleção dispara `apexselectionchange`.

Fonte: [Interface: templateReportRegion](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/templateReportRegion.html)

### Faceted Search e Smart Filters via JavaScript: interface facetsRegion

`apex.region(id)` de uma região Faceted Search ou Smart Filters devolve `facetsRegion` (`type = "Facets"`). `uiMode` é `"F"` (faceted search) ou `"S"` (smart filters) e não muda depois de criado.

**Facet = page item escondido.** O valor de cada faceta fica num page item com o nome da faceta. Mudar o item atualiza as facetas e o relatório:

```javascript
apex.item( "P1_PROJECT_STATUS" ).setValue( "OPEN:REOPENED" ); // vários valores: ":"
// faixa: "min|max"
// operador (Input Field com "User can Choose Operator", Since 21.2):
apex.item( "P1_POPULATION" ).setValue( "EQ:1000" );
```

Operadores: gerais `EQ`, `NEQ`; NUMBER `LT`, `LTE`, `GT`, `GTE`; VARCHAR2 `STARTS`, `NSTARTS`, `C` (contém), `NC`.

| Métodos | Descrição |
|---|---|
| `apply()` | aplica mudanças pendentes (com `batch` e `externalApply`) |
| `clear()` / `clearFacets()` / `reset()` | limpa facetas e busca / só facetas / limpa e restaura configurações persistidas |
| `fetchCounts()` / `refresh()` | recalcula contagens (útil quando o relatório também filtra por itens externos) |
| `getFacetCount(pIncludeSearchTerms)` → number | quantas facetas têm valor (ex.: badge "3 filtros") |
| `getFacetValueCounts()` → object / `getTotalResourceCount()` → number | contagens |
| `showFacet(name)` / `hideFacet(name)` | esconder não limpa o valor |
| `addChart(name, [pAppendTo$], [pConfig])` / `removeChart(name)` | gráficos de faceta |
| `lock()` / `unlock()` | plug-ins de relatório: travar durante o Ajax (um unlock para cada lock) |
| `focus()`, `refreshView()`, `on`, `off` | |

Eventos: `change` (= DA *Facets Change*/*Filters Change*), `beforeAddChart`, `afterRemoveChart`. O relatório ligado já atualiza sozinho. Outras regiões precisam ouvir o evento:

```javascript
apex.region( "myFacets" ).on( "facetschange", function() {
    apex.region( "extraReport" ).refresh();
} );
```

Principais propriedades: `batch` (padrão true), `controls`, `currentFacets`, `externalApply`, `feedback`, `maxChips` (5), `moreFiltersChip`, `multipleSearches`, `numberFormat`, `persistState`, `searchField`, `searchItem`, `showCharts`, `showTotalCount`, `chartTopNValues` (10), `clearOnHide`, `collapsibleSearchBar`, `text`, `uiMode`.

Fonte: [Interface: facetsRegion](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/facetsRegion.html)

### Map region via JavaScript: interface mapRegion (Since 21.2)

A região Map usa a biblioteca MapLibre GL JS (`type = "SpatialMap"`). `getMapObject()` expõe o objeto MapLibre, mas código que usa a API do MapLibre pode quebrar em versões futuras.

| Grupo | Métodos |
|---|---|
| Estado do mapa | `getMapBboxAndZoomLevel()`, `getMapCenterAndZoomLevel()`, `getMapPitchAndBearing()`, `getMapStatus()`, `setCenter(pCenter)`, `setZoomLevel(n)`, `reset()`, `focus()`, `refresh()` |
| Camadas | `getLayers()`, `getLayerIdByName(name)`, `showLayer(nameOrId)`, `hideLayer(nameOrId)`, `moveLayer(id, [beforeId])` (as três Since 26.1) |
| Features | `addFeature(layerId, feature)`, `getFeature(layerId, featureId)`, `updateFeature(...)`, `removeFeature(...)` |
| Popups | `displayPopup(pType, pLayerId, pFeatureId, pFocusAfterOpen, [pLngLat])`, `closeInfoWindow(...)`, `closeAllInfoWindows([layerId])`, `closeTooltip()` |
| Círculo | `getCircle()`, `clearCircle()` |
| Outros | `getMapObject()`, `on`, `off` |

Eventos: `changed` (área ou zoom), `click` (no mapa), `objectclick` (numa feature), `initialized`. Propriedades: `layers`, `tileLayer`, `useVectorTileLayers`, `mapStatusItem` (item recebe o bbox atual), `itemsToSubmit`, `lazyLoading`, `resetMapPosition`, `mapUnitSystem` (`"metric"`/`"imperial"`), `bboxCustom` (Since 26.1), `legend`, `navigationBar`, `customStyles` etc.

Fonte: [Interface: mapRegion](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/mapRegion.html)

---

## 6. `apex.server` (Ajax)

### apex.server: todas as funções

| Função | Descrição |
|---|---|
| `process(pName, [pData], [pOptions])` → Promise | chama um processo PL/SQL **On Demand (Ajax Callback)** da página ou da aplicação |
| `plugin([pAjaxIdentifier], [pData], [pOptions])` → Promise | chama a função Ajax PL/SQL de um plug-in (id de `apex_plugin.get_ajax_identifier`) |
| `pluginUrl(pAjaxIdentifier, [pData])` → string | URL GET para a função Ajax do plug-in |
| `url([pData], [pPage])` → string | URL GET para a página atual (ou `pPage`) |
| `loadScript(pOptions, [callback])` → * | carrega JS assíncrono via RequireJS ou `jQuery.getScript` |
| `chunk(Text)` → string\|string[] | quebra texto em pedaços de até 8.000 caracteres |

`process` e `plugin` embrulham `jQuery.ajax` e aceitam um subconjunto das opções dele, mais as opções próprias do APEX.

Fonte: [Namespace: server](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.server.html)

### Chamar PL/SQL por Ajax: apex.server.process(pName, pData, pOptions)

**`pName`**: nome do processo *On Demand* (ponto **Ajax Callback**) da página, ou do processo de aplicação com ponto On Demand.

**`pData`** é serializado como JSON e enviado no parâmetro `p_json`. Propriedades especiais:

| Propriedade | Tipo | Efeito |
|---|---|---|
| `pageItems` | seletor jQuery, jQuery, Element ou array de nomes | itens enviados para o **session state** antes do processo rodar (ex.: `"#P1_DEPTNO,#P1_EMPNO"` ou `["P1_DEPTNO","P1_EMPNO"]`). Se incluir column items, passe também `pOptions.target` |
| `x01` … `x20` | string | saem do `p_json` e vão como parâmetros escalares `x01`–`x20` (no PL/SQL: `apex_application.g_x01`…) |
| `f01` … `f20` | string \| Array | saem do `p_json` e vão como arrays `f01`–`f20` (no PL/SQL: `apex_application.g_f01`…) |
| `regions` | array | dados por região: `[{ id: <região>, ... }]` |

**`pOptions`**: opções do `jQuery.ajax` aceitas: `accepts`, `dataType` (**padrão `"json"`**), `beforeSend`, `contents`, `converters`, `dataFilter`, `headers`, `complete`, `statusCode`, `error`, `success`. A opção `async` está **deprecated** e vai sair. Opções do APEX:

| Opção | Descrição |
|---|---|
| `refreshObject` | elemento em que `apexbeforerefresh`/`apexafterrefresh` são disparados (sem isso, não há esses eventos) |
| `refreshObjectData` | dados extras para esses eventos (`this.data` na DA) |
| `clear` | função chamada depois do `apexbeforerefresh` e antes do Ajax, para limpar o DOM |
| `loadingIndicator` | elemento(s) que recebem spinner, ou função que recebe o spinner e devolve o jQuery dele (ou uma função de remoção) |
| `loadingIndicatorPosition` | `"before"`, `"after"`, `"prepend"`, `"append"`, `"centered"`, `"page"` |
| `queue` | `{ name, action }`, com `action` = `"wait"` (padrão), `"replace"` ou `"lazyWrite"` |
| `target` | elemento a que a requisição se refere (contexto de session state da região); **obrigatório** se `pageItems` tem column items |

**Retorno**: uma Promise (não é um `jqXHR`, mas tem `abort`, que não funciona com filas). `done` = `success`, `fail` = `error`, `always` depois dos dois. Valores de `textStatus` no `fail`: `"superseded"`/`"abort"` (filas), `"cancel"` (o `apexbeforerefresh` cancelou) e **`"APEX"`** para erro devolvido pelo servidor APEX (detalhes em `errorThrown`).

```javascript
// callbacks
apex.server.process( "MY_PROCESS", {
    x01: "test",
    pageItems: "#P1_DEPTNO,#P1_EMPNO"
}, {
    success: function( data ) { /* data = resposta (JSON por padrão) */ },
    error: function( jqXHR, textStatus, errorThrown ) { /* tratar */ }
} );

// promise
apex.server.process( "MY_PROCESS", { x01: "test", pageItems: ["P1_DEPTNO","P1_EMPNO"] } )
    .done( function( data ) { /* ... */ } )
    .fail( function( jqXHR, textStatus, errorThrown ) { /* ... */ } )
    .always( function() { /* sempre */ } );

// resposta em HTML/texto, não JSON
apex.server.process( "ORG_DETALHES", { x01: id }, { dataType: "text" } )
    .done( function( html ) { painel.innerHTML = html; } );
```

Pegadinhas:
- Com o `dataType` padrão `"json"`, uma resposta que não é JSON válido cai no `fail`. Se o processo devolve HTML ou texto, passe `dataType: "text"`.
- `x01`–`x20` e `f01`–`f20` são o que a doc de `process`/`plugin` lista. Para `pluginUrl`/`url` a doc fala em `x01`–`x10` e `f01`–`f20`.
- O valor do item só chega ao servidor se estiver em `pageItems`. `setValue` no cliente não muda o session state.

Fonte: [Namespace: server](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.server.html)

### Lado servidor do Ajax Callback: processo On Demand, g_x01 e autorização

- O processo chamado por `apex.server.process` é um processo PL/SQL com ponto **Ajax Callback** na página, ou um **Application Process** com ponto **On Demand**. Esse ponto só roda quando requisitado.
- Prefira criar o processo **na página**. Processos On Demand de aplicação são criados com a authorization inicial **Must Not Be Public User**, para que sessões não autenticadas não os chamem.
- No PL/SQL, os escalares chegam em `apex_application.g_x01`… e os arrays em `apex_application.g_f01`…. Itens de `pageItems` já estão no session state (`:P1_ITEM`, `v('P1_ITEM')`). A resposta é o que o processo escreve no buffer HTTP (por exemplo com `apex_json`, `htp.p` ou `apex_util.prn`) e deve combinar com o `dataType` do cliente.
- Um On Demand de aplicação também pode ser chamado por URL: `f?p=app:page:session:APPLICATION_PROCESS=nome`. Falhas de autenticação, autorização ou condição não mostram erro (normalmente a página sai em branco), exceto para quem está logado no Builder.

Fonte: [Understanding Application Processes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-application-processes.html), [Namespace: server](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.server.html)

### Filas de requisições Ajax (queue: wait, replace, lazyWrite)

| `action` | Comportamento |
|---|---|
| `"wait"` (padrão) | põe na fila nomeada; executa quando as anteriores terminarem |
| `"replace"` | aborta a que está em andamento e descarta as que esperam (rejeitadas com `"superseded"`), depois executa esta. Ideal para "busca enquanto digita" |
| `"lazyWrite"` | limita (throttle) gravações não críticas (posição de splitter, estado de árvore). Só o último valor importa. Use **um nome por unidade de dado** e não misture com `wait`/`replace` na mesma fila. `refreshObject`, `clear` e `loadingIndicator` não fazem sentido aqui |

`wait` e `replace` podem ser misturados na mesma fila. O `abort` da promise não funciona com filas.

```javascript
apex.server.process( "BUSCAR", { x01: termo }, { queue: { name: "busca", action: "replace" } } );
```

Fonte: [Namespace: server](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.server.html)

### apex.server.plugin, pluginUrl e url para plug-ins e GET

- **`plugin`**: igual ao `process`, mas chama a função Ajax de um plug-in. O identificador vem de `apex_plugin.get_ajax_identifier` no render do plug-in. Ele pode ser o 1º argumento ou ir em `pData.regions[i].ajaxIdentifier`.
- **`pluginUrl(pAjaxIdentifier, [pData])`**: URL GET para o plug-in, com `pageItems`, `x01`–`x10` e `f01`–`f20`.
- **`url([pData], [pPage])`**: URL GET para a página atual ou outra (ex.: `p_request`).

```javascript
apex.server.plugin( lAjaxIdentifier, {
    x01: "test",
    pageItems: "#P1_DEPTNO,#P1_EMPNO"
}, {
    refreshObject: "#P1_MY_LIST",
    loadingIndicator: "#P1_MY_LIST",
    success: function( data ) { /* ... */ }
} );

var lUrl = apex.server.url( { p_request: "DELETE", x01: "test", pageItems: "#P1_DEPTNO" } );
```

Fonte: [Namespace: server](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.server.html)

### Carregar JavaScript sob demanda: apex.server.loadScript

Use no lugar de `jQuery.getScript`. O motivo é que a página pode ou não ter o RequireJS: bibliotecas que conhecem o RequireJS dão erro se não forem carregadas por `require`, e sem RequireJS não dá para usar `require`.

| Opção | Descrição |
|---|---|
| `path` | URL do arquivo |
| `requirejs` | `true` para carregar via RequireJS (padrão false) |
| `global` | nome global introduzido pelo arquivo (sobrescreve o existente). Deixe vazio se o arquivo foi gerado pelo RequireJS optimizer |
| `callback` | função chamada depois de carregar |

Retorna um promise estilo jqXHR quando usa `getScript`; caso contrário não retorna nada.

```javascript
apex.server.loadScript( { path: "./library_1.js" }, function() { console.log( "pronta" ); } );
apex.server.loadScript( { path: "./library_2.js", requirejs: true, global: "myModule" },
    function() { console.log( myModule ); } );
```

Fonte: [Namespace: server](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.server.html)

### Enviar texto maior que 32k: apex.server.chunk e arrays f01

`apex.server.chunk(texto)` devolve o texto se tiver menos de 8.000 caracteres, ou um array de pedaços. A doc mostra como contornar o limite de 32k de um item: no `apexpagesubmit`, crie inputs `f01` escondidos no form `#wwvFlowForm` com os pedaços e limpe o item. No servidor, percorra `apex_application.g_f01`.

```javascript
apex.gPageContext$.on( "apexpagesubmit", function() {
    var $ = apex.jQuery, form$ = $( "#wwvFlowForm" ),
        f1 = apex.server.chunk( $v( "P1_TEXT" ) );
    if ( !Array.isArray( f1 ) ) { f1 = [f1]; }
    f1.forEach( function( v ) {
        form$.append( "<input type='hidden' name='f01' value='" + v + "'>" );
    } );
    $s( "P1_TEXT", " " );
} );
```

Fonte: [Namespace: server](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.server.html)

---

## 7. `apex.message`

### apex.message: todas as funções e constantes

| Membro | Descrição |
|---|---|
| `TYPE` | `{ SUCCESS: "success", ERROR: "error" }` |
| `alert(pMessage, pCallback, [pOptions])` | diálogo com OK (não bloqueia) |
| `confirm(pMessage, pCallback, [pOptions])` | diálogo OK/Cancel; callback recebe `okPressed` (não bloqueia e não retorna valor) |
| `showErrors(pErrors)` | mostra erros de página e/ou inline |
| `clearErrors()` | limpa os erros mostrados |
| `showPageSuccess(pMessage)` | mensagem de sucesso de página (limpa sucessos e erros anteriores) |
| `hidePageSuccess()` | esconde a mensagem de sucesso |
| `setDismissPreferences(pOptions)` | auto-dismiss das mensagens de sucesso |
| `setThemeHooks(pOptions)` | ganchos para temas (beforeShow/beforeHide, seletores) |
| `addVisibilityCheck(pFunction)` | plug-ins de região: garantir que um elemento com erro esteja visível antes do foco |
| `ariaMessage(pMessage)` / `ariaAlertMessage(pMessage)` | mensagem ARIA live *polite* / *assertive*, sem nada visual |

Fonte: [Namespace: message](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.message.html)

### Mostrar e limpar erros no cliente (apex.message.showErrors / clearErrors)

`showErrors(pErrors)` mostra **todos os erros da pilha** de mensagens. Para não acumular, chame `clearErrors()` antes. Cada objeto:

| Propriedade | Descrição |
|---|---|
| `type` | sempre `"error"` (outros tipos reservados) |
| `location` | `"inline"`, `"page"` ou `["inline","page"]` |
| `pageItem` | item do erro inline (obrigatório com `"inline"`) |
| `message` | texto |
| `unsafe` | padrão `true` (o texto **é escapado**). Passe `false` se a mensagem já estiver escapada ou tiver HTML confiável |

```javascript
apex.message.clearErrors();
apex.message.showErrors( [
    { type: "error", location: [ "page", "inline" ], pageItem: "P1_ENAME",
      message: "Nome é obrigatório", unsafe: false },
    { type: "error", location: "page", message: "Erro na página", unsafe: false }
] );
```

Comportamento:
- Erros de página usam o *Subtemplate > Notification* do page template; inline usam o *Error Template* do label template (o label template precisa ter `#ERROR_TEMPLATE#`).
- Com erros de página, o APEX foca o container de erros; só com inline, foca o primeiro erro inline.
- Receita do Developer's Companion para **validação antecipada**: DA Change → `apex.message.clearErrors('P5_EMPNO')` → Execute Server-side Code que grava a mensagem num item escondido (Items to Submit/Return) → Execute JavaScript Code com condição "item não nulo" que chama `showErrors` inline.
- Divergência: a referência do 26.1 documenta `clearErrors()` **sem parâmetros**, mas o Developer's Companion usa `clearErrors('P5_EMPNO')` para limpar o erro de um item só.

Fonte: [Namespace: message](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.message.html), [Displaying Messages with JavaScript](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/displaying-messages-javascript.html)

### Mensagem de sucesso no cliente (showPageSuccess, hidePageSuccess, setDismissPreferences)

```javascript
apex.message.showPageSuccess( "Alterações salvas!" );
apex.message.hidePageSuccess();
apex.message.setDismissPreferences( {
    dismissPageSuccess: true,          // false = não some sozinha
    dismissPageSuccessDuration: 10000  // padrão 5000 ms
} );
```

- `showPageSuccess` usa o *Subtemplate > Success Message* do page template e **também limpa erros** exibidos.
- `setDismissPreferences` deve ser chamada em *Function and Global Variable Declaration* ou num `.js` da aplicação. Sem ela, vale a configuração de auto-dismiss da aplicação.
- Acessibilidade: o auto-dismiss pode esconder a mensagem antes de usuários de tecnologia assistiva lerem. A doc sugere dar ao usuário uma preferência para desligá-lo ou ajustar o tempo.

Fonte: [Namespace: message](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.message.html)

### Diálogos de confirmação e alerta (apex.message.confirm / alert) não bloqueiam

Diferente do `window.confirm`, o código **depois** da chamada roda antes de o usuário responder. A ação vai **dentro do callback**.

```javascript
apex.message.confirm( "Excluir este registro?", function( okPressed ) {
    if ( okPressed ) { excluir(); }
}, {
    title: "Atenção",
    style: "danger",                    // "information" | "warning" | "danger" | "success"
    iconClasses: "fa fa-trash fa-2x",
    cancelLabel: "Não",
    confirmLabel: "Sim, excluir"
} );

apex.message.alert( "Carga concluída.", function() { depois(); }, { title: "Pronto", style: "success" } );
```

Opções: `title`, `style`, `dialogClasses`, `iconClasses`, e os rótulos `okLabel`/`okLabelKey` (alert), `cancelLabel`/`cancelLabelKey`/`confirmLabel`/`confirmLabelKey` (confirm). Os rótulos padrão vêm das mensagens `APEX.DIALOG.OK` e `APEX.DIALOG.CANCEL`. O diálogo usa jQuery UI Dialog, segue o estilo da app e pode ser movido.

Fonte: [Namespace: message](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.message.html)

### Mensagens ARIA, ganchos de tema e visibilidade (ariaMessage, setThemeHooks, addVisibilityCheck)

- `ariaMessage` (polite) avisa sem interromper. `ariaAlertMessage` (assertive) interrompe e pode limpar a fila de fala. Use mensagens curtas para mudanças dinâmicas que o leitor de tela não perceberia.
- `setThemeHooks({ beforeShow, beforeHide, closeNotificationSelector, pageErrorsContainerSelector, successMessageContainerSelector })`: para temas. Os callbacks recebem `(pMsgType, pElement$)`; retornar `false` substitui o comportamento padrão. Os seletores padrão do Universal Theme são `button.t-Button-closeAlert`, `#t_Alert_Notification` e `#t_Alert_Success`.
- `addVisibilityCheck(fn(id))`: plug-ins de região que escondem conteúdo (abas, expansores) registram uma função que torna visível o elemento com erro, para o "Go to Error" funcionar.

Fonte: [Namespace: message](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.message.html)

---

## 8. `apex.page`

### apex.page: todas as funções

| Função | Descrição |
|---|---|
| `submit([pOptions])` → boolean\|undefined | submete a página (alias `apex.submit`) |
| `confirm([pMessage], [pOptions])` | confirma e depois submete (alias `apex.confirm`) |
| `validate([pLocation])` → boolean | verifica se itens e models submetíveis são válidos e mostra os erros |
| `isChanged()` → boolean | algum item ou model mudou desde o último envio |
| `warnOnUnsavedChanges([pMessage], [pExtraIsChanged])` | liga ou customiza o aviso de alterações não salvas |
| `cancelWarnOnUnsavedChanges()` | remove o aviso (antes de um "cancelar" intencional) |

Fonte: [Namespace: page](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.page.html)

### Submeter a página por JavaScript (apex.page.submit)

`pOptions` pode ser uma string (vira o `REQUEST`), `null` (sem REQUEST) ou um objeto:

| Opção | Padrão | Descrição |
|---|---|---|
| `request` | null | valor de `REQUEST` (usado em condições "When Button Pressed"/request) |
| `set` | n/d | `{ ITEM: valor }` definidos antes do envio |
| `showWait` | false | mostra spinner (`apex.widget.waitPopup`). Com *Reload on Submit = Only for Success* (Ajax) pode haver spinner mesmo com false |
| `submitIfEnter` | n/d | passe o evento de `keydown`/`keypress` para submeter só com Enter |
| `reloadOnSubmit` | atributo da página | `"A"` (sempre) ou `"S"` (só sucesso) |
| `ignoreChange` | true | se false e o Warn on Unsaved Changes está ligado, avisa sobre mudanças. Use false quando o submit não salva nada |
| `validate` | false | valida itens e models antes; se algo for inválido, mostra alerta e não submete |

Fluxo: dispara `apexbeforepagesubmit` (pode ser cancelado) → validação (se pedida) → `apexpagesubmit` → envio. Conforme o *Reload on Submit* da página, o envio é por Ajax ou por POST normal.

```javascript
apex.page.submit( "DELETE" );
apex.page.submit( {
    request: "SAVE",
    set: { "P1_DEPTNO": 10, "P1_EMPNO": 5433 },
    showWait: true,
    validate: true
} );
apex.jQuery( "#P1_TEXT" ).on( "keydown", function( event ) {
    apex.page.submit( { submitIfEnter: event } );
} );
```

Retorno: com `submitIfEnter`, `false` se Enter foi pressionado e `true` caso contrário. Sem essa opção, `undefined`.

Fonte: [Namespace: page](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.page.html)

### Confirmar antes de submeter (apex.page.confirm)

Mesmas opções do `submit`, mas o `request` padrão é `"Delete"` e `submitIfEnter` não faz sentido. **Sempre passe a mensagem**: a mensagem padrão ("Would you like to perform this delete action?") não é traduzida, está deprecated e o argumento vai virar obrigatório.

```javascript
apex.page.confirm( "Excluir o departamento?", "DELETE" );
apex.page.confirm( "Salvar o departamento?", {
    request: "SAVE",
    set: { "P1_DEPTNO": 10 }
} );
```

Fonte: [Namespace: page](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.page.html)

### Validar no cliente sem submeter (apex.page.validate)

Verifica se itens e models submetíveis estão inválidos e mostra os erros com `apex.message.showErrors` em `pLocation` (padrão `["inline","page"]`). **Não executa validação**: confia nos atributos e API HTML5 dos itens (veja `item.getValidity`). As validações de servidor continuam necessárias.

```javascript
if ( !apex.page.validate() ) { return; }
```

Fonte: [Namespace: page](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.page.html)

### Warn on Unsaved Changes por JavaScript (isChanged, warnOnUnsavedChanges, js-ignoreChange)

- `apex.page.isChanged()` verifica itens e models (ignora itens desabilitados ou configurados para ignorar mudanças). Por último, chama `pExtraIsChanged`. Em modo debug, o console mostra qual model ou item mudou.
- `warnOnUnsavedChanges(pMessage, pExtraIsChanged)` é chamado sozinho quando o atributo da página está em Yes. Chame à mão para customizar, por exemplo para considerar inputs que não são itens APEX. A maioria dos navegadores **não mostra** a mensagem.
- `cancelWarnOnUnsavedChanges()` antes de sair intencionalmente. A classe **`js-ignoreChange`** num link ou botão faz isso automaticamente.

```javascript
apex.jQuery( "#custom-cancel-button" ).on( "click", function() {
    apex.page.cancelWarnOnUnsavedChanges();
    apex.navigation.redirect( someUrl );
} );
```

Fonte: [Namespace: page](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.page.html)

---

## 9. `apex.navigation`

### apex.navigation: todas as funções (redirect, dialog, popup, openInNewWindow)

| Função | Descrição |
|---|---|
| `redirect(pWhere, [pIgnoreUnsavedChanges])` | abre a URL na janela atual |
| `dialog(pUrl, pOptions, pCssClasses, pTriggeringElement)` | abre página como diálogo (modal em iframe ou não modal em popup) |
| `dialog.close(pIsModal, [pAction])` | no diálogo: executa a ação e fecha |
| `dialog.cancel(pIsModal)` | no diálogo: fecha (cancelar) |
| `dialog.registerCloseHandler(pOptions)` | **deprecated desde 18.2** |
| `popup(pOptions)` → Window\|null | janela popup nomeada |
| `popup.close(pItem, pValue)` | no popup: define item na janela pai e fecha |
| `openInNewWindow(pURL, [pWindowName], [pOptions])` → Window\|null | nova janela ou aba "de verdade" |

Fonte: [Namespace: navigation](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.navigation.html)

### Redirecionar por JavaScript (apex.navigation.redirect)

```javascript
apex.navigation.redirect( "f?p=&APP_ID.:3:&APP_SESSION.::NO:RP::" ); // substituições trocadas no servidor
apex.navigation.redirect( "f?p=" + apex.env.APP_ID + ":3:" + apex.env.APP_SESSION ); // em arquivo .js
apex.navigation.redirect( apex.item( "P1_URL" ).getValue() );        // URL gerada no servidor
```

- `pIgnoreUnsavedChanges` (padrão false): `true` pula o aviso de alterações não salvas.
- Redirect não submete: mudanças do usuário não vão para o session state (diferente de submit + branch).
- Substitution strings como `&APP_SESSION.` só são trocadas quando o código é renderizado pelo servidor (atributos da página, DA). Num `.js` estático, use `apex.env`.
- Se o destino exige checksum (*Page Access Protection* / argumentos com checksum), gere a URL no servidor com `APEX_PAGE.GET_URL` e leia de um item escondido.

Fonte: [Namespace: navigation](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.navigation.html), [Understanding AJAX and Redirect](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-ajax-and-redirect.html)

### Abrir página modal por JavaScript (apex.navigation.dialog) e checksum

Normalmente essa API é chamada pelo próprio APEX, por uma URL especial gerada no servidor quando o destino é uma página de diálogo. **No mínimo a URL precisa ser gerada no servidor** para levar o checksum do diálogo. Pode ser o retorno de `APEX_PAGE.GET_URL` (com `p_plain_url => true` você controla as opções no JS; com `false` a URL já traz opções, classes e elemento disparador).

| Parâmetro | Descrição |
|---|---|
| `pUrl` | URL da página de diálogo |
| `pOptions` | `title` (só modal; padrão = nome da página), `height`/`width` (padrão 500; a doc diz que só se aplicam ao não modal, mas os exemplos as usam no modal), `maxWidth` (padrão 1500), `modal` (padrão true), outras opções do jQuery UI Dialog (`resizable`…) |
| `pCssClasses` | classes adicionadas ao `dialogClass` (veja o page template: `t-Dialog-page--standard`, `t-Drawer-page--standard t-Drawer--pullOutEnd`) |
| `pTriggeringElement` | seletor do elemento que abriu; recebe `apexafterclosedialog`/`apexafterclosecanceldialog` |

```javascript
apex.navigation.dialog(
    apex.items.P1_DIALOG_URL.value,           // gerada com APEX_PAGE.GET_URL(p_plain_url => true)
    { title: "Pedidos", height: "480", width: "800", modal: true, resizable: true },
    "t-Dialog-page--standard",
    "#mybutton" );
```

Receita do Developer's Companion: funções `app.openDialogURL({url, title, width = 400, maxWidth = 1000, triggeringElement = $('body')[0]})` e `app.openDrawerURL(...)` (classes `t-Drawer-page--standard t-Drawer--pullOutEnd`) num `app.js`, com parâmetros desestruturados e padrões.

Fonte: [Namespace: navigation](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.navigation.html), [Opening Dialog URL Passing Client Data](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/opening-dialog-url-passing-client-data.html)

### Fechar diálogo e devolver valores (apex.navigation.dialog.close / cancel)

Rodam **dentro** da página de diálogo.

`close(pIsModal, [pAction])`, onde `pAction` pode ser:
- uma URL: redireciona a página pai;
- uma função: redireciona para outro diálogo, reaproveitando o atual (recebe `pDialog`; passe `dialog: pDialog` nas opções);
- `false`: cancela;
- um objeto `{ ITEM: valor }`: exposto no `apexafterclosedialog`;
- um array de nomes de itens: os valores são lidos dos itens.

```javascript
apex.navigation.dialog.close( true, ["P3_EMPNO","P3_ENAME"] );  // pai recebe data.P3_EMPNO
apex.navigation.dialog.close( true, { dialogPageId: 3 } );
apex.navigation.dialog.cancel( true );

// encadear para outro diálogo
apex.navigation.dialog.close( true, function( pDialog ) {
    apex.navigation.dialog( url, { title: "Sobre", modal: true, dialog: pDialog },
        "t-Dialog-page--standard", $( "#mybutton" ) );
} );
```

`registerCloseHandler` está **deprecated desde 18.2**.

Fonte: [Namespace: dialog](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.navigation.dialog.html)

### Título dinâmico de diálogo com dados da página (Including Context Info in Dialog Title)

`&P60_ENAME.` no título da página de diálogo aparece vazio, por causa do momento em que o título é definido. A doc manda definir o título no Page Load:

```javascript
apex.util.getTopApex()
         .jQuery( ".ui-dialog-content" )
         .dialog( "option", "title", "Endereço de " + $v( "P60_ENAME" ) );
```

Dica da doc: ponha no título da página uma substituição inexistente (`&INITIALLY_BLANK.`) para não piscar um título estático antes. Para traduzir, use uma Text Message com *Used in JavaScript* ligado e `apex.lang.formatMessage`.

Fonte: [Including Context Info in Dialog Title](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/including-context-info-dialog-title.html), [Using Translatable Text in JavaScript](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-translatable-text-javascript.html)

### Popups e novas janelas (popup, popup.close, openInNewWindow)

- `popup({ url, name, height, width, scroll, resizeable, toolbar, location, statusbar, menubar })`. Padrões: `about:blank`, `_blank`, 600×600, scroll `"no"`, resizeable `"yes"`, o resto `"no"`. O nome é tornado único por app. Não use `_self`, `_parent` nem `_top`. Retorna a janela ou `null`.
- `popup.close(pItem, pValue)`: no popup aberto por `apex.navigation.popup`, define o item na janela pai e fecha.
- `openInNewWindow(pURL, [pWindowName], { altSuffix, favorTabbedBrowsing, noopener })`: janela ou aba funcional, como um `<a target>`. `noopener` é padrão true para `_blank`; com ele a função retorna sempre `null`.
- Chame os dois a partir de um **handler de click** para não cair no bloqueador de popups.

Fonte: [Namespace: navigation](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.navigation.html), [Namespace: popup](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.navigation.popup.html)

---

## 10. `apex.da`

### apex.da: cancel, resume e handleAjaxErrors (ações assíncronas em Dynamic Actions)

| Função | Descrição |
|---|---|
| `apex.da.cancel()` | para as ações restantes da DA **sem** indicar erro, independente de *Stop Execution On Error*; funciona também em ações assíncronas |
| `apex.da.resume(pCallback, pErrorOccurred)` | retoma as próximas ações depois de uma ação que pausou (*Wait for Result*). `pCallback` = `this.resumeCallback`. Com `pErrorOccurred = true` e *Stop Execution on Error* ligado, a DA para |
| `apex.da.handleAjaxErrors(pjqXHR, pTextStatus, pErrorThrown, pResumeCallback)` | em erro de Ajax: mostra a mensagem e retoma a DA. Passe como `error` do `apex.server.*` |

Regras:
- Retornar `false` da função JS indica erro, mas só para a DA se *Stop Execution On Error* estiver ligado.
- Plug-in que expõe *Wait for Result* **tem** de chamar `resume` no sucesso (ou `handleAjaxErrors` no erro), senão as ações seguintes nunca rodam.

```javascript
var lResume = this.resumeCallback;
apex.server.plugin( lAction.ajaxIdentifier, { /* pData */ }, {
    success: function() { apex.da.resume( lResume, false ); },
    error: function( jqXHR, textStatus, errorThrown ) {
        apex.da.handleAjaxErrors( jqXHR, textStatus, errorThrown, lResume );
    }
} );

// cancelar o resto da DA de forma assíncrona
var self = this;
setTimeout( function() {
    if ( algumaCondicao() ) { apex.da.cancel(); } else { fazerAlgo(); }
    apex.da.resume( self.resumeCallback, false );
}, 800 );
```

Fonte: [Namespace: da](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.da.html)

---

## 11. `apex.lang`, `apex.locale` e `apex.date`

### apex.lang: mensagens traduzíveis no JavaScript (getMessage, formatMessage, loadMessages)

| Função | Descrição |
|---|---|
| `getMessage(pKey)` → string | texto localizado; devolve a própria chave se não existir |
| `hasMessage(pKey)` → boolean | a chave existe? |
| `formatMessage(pKey, ...pValues)` → string | mensagem com `%0`–`%9` ou `%nome`; argumentos **escapados** |
| `formatMessageNoEscape(pKey, ...pValues)` | idem, sem escape (só em contexto seguro) |
| `format(pPattern, ...pValues)` | formata um padrão literal (não é chave); argumentos escapados |
| `formatNoEscape(pPattern, ...pValues)` | idem, sem escape |
| `addMessages(pMessages)` | adiciona `{ CHAVE: "texto" }` (mescla) |
| `clearMessages()` | remove todas (componentes do APEX dependem delas) |
| `loadMessages(pMessageKeys)` → Promise | busca no servidor; chave com `%` no fim carrega por prefixo |
| `loadMessagesIfNeeded(pMessageKeys, pCallback)` | busca só as que faltam e chama o callback |

As Text Messages com **Used in JavaScript = On** já vêm carregadas na página. As outras precisam de `loadMessages`.

```javascript
apex.lang.formatMessage( "PROCESS_STATUS", progresso );            // "Processo %0% concluído"
apex.lang.formatMessage( "PROCESS_STATUS", { processComplete: 60 } );
apex.lang.format( "Total: R$ %0", total );
apex.lang.loadMessages( ["MEU_COMP_%"] ).done( function() { /* ... */ } );
```

Erros nos exemplos da doc: o exemplo de `loadMessagesIfNeeded` chama `apex.lang.loadMessage` (sem "s") e o de `loadMessages` tem parênteses desbalanceados. Use os nomes da tabela.

Fonte: [Namespace: lang](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.lang.html), [Using Translatable Text in JavaScript](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-translatable-text-javascript.html)

### apex.locale: formatar e converter números conforme o idioma (Since 20.1)

| Função | Descrição |
|---|---|
| `formatNumber(pValue, [pFormat], [pOptions])` → string | como `TO_CHAR(number)` com format model (sem `RN`, `TM`, `EEEE`). Opções `NLS_NUMERIC_CHARACTERS`, `NLS_CURRENCY`, `NLS_DUAL_CURRENCY`, `NLS_ISO_CURRENCY` (ISO, ex. `"BRL"`) |
| `formatCompactNumber(pValue, [pOptions])` → string | compacto ("123.4K", "1.23M"). Opções `maximumFractionDigits` (2), `minimumFractionDigits` (0), `minimumIntegerDigits` (1), `roundingMode` (`DEFAULT`, `HALF_UP`, `HALF_DOWN`, `HALF_EVEN`, `UP`, `DOWN`, `CEILING`, `FLOOR`), `separators: {decimal, group}`, `useGrouping` (true) |
| `toNumber(pValue, [pFormat])` → number | converte texto digitado em número (remove símbolos de formato; considera separadores do locale). `NaN` se não der. `0o`/`0b` nunca, `0x` só com máscara hex |
| `resourcesLoaded([pCallback])` → Promise | recursos do locale carregados (necessário para `formatCompactNumber`) |
| `getLanguage()` | idioma atual (ex.: `"en"`, `"de"`, `"en-US"`) |
| `getDecimalSeparator()` / `getGroupSeparator()` | separadores |
| `getCurrency()` / `getDualCurrency()` / `getISOCurrency()` | moeda |
| `getDateFormat()` / `getDSDateFormat()` / `getDLDateFormat()` | máscaras de data do banco |
| `getDayNames()` / `getAbbrevDayNames()` / `getMonthNames()` / `getAbbrevMonthNames()` | nomes (o array começa no 1º dia da semana / 1º mês do locale) |

```javascript
apex.locale.formatNumber( 1234.569, "FML999G999G999G999G990D00" );
apex.locale.resourcesLoaded( function() {
    console.log( apex.locale.formatCompactNumber( 123456789.12 ) );
} );
var n = apex.locale.toNumber( "1.234,56" ); // locale com vírgula decimal → 1234.56
```

Antes de os recursos carregarem, `formatCompactNumber` devolve o número sem formatação.

Fonte: [Namespace: locale](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.locale.html)

### apex.date: operações e formatação de datas no cliente (Since 21.2)

Constantes `apex.date.UNIT`: `MILLISECOND`, `SECOND`, `MINUTE`, `HOUR`, `DAY`, `WEEK`, `MONTH`, `YEAR`.

| Função | Descrição |
|---|---|
| `add([pDate], pAmount, [pUnit])` / `subtract(...)` → Date | soma/subtrai **alterando o objeto original** (use `clone` antes); unidade padrão ms |
| `clone(pDate)` → Date | cópia |
| `format([pDate], [pFormat], [pLocale])` → string | máscara Oracle (padrão = máscara e idioma da app). Não suporta `SYEAR`, `SYYYY`, `IYYY`, `YEAR`, `IYY`, `SCC`, `TZD`, `TZH`, `TZM`, `TZR`, `AD`, `BC`, `CC`, `EE`, `FF`, `FX`, `IY`, `RM`, `TS`, `E`, `I`, `J`, `Q`, `X` |
| `parse(pDateString, [pFormat])` → Date | texto + máscara Oracle → Date (lista própria de máscaras não suportadas, inclui `SSSSS`, `IW`, `WW`, `W`) |
| `toISOString([pDate])` → string | ISO 8601 **sem fuso** (`"2021-06-15T14:30:00"`) |
| `isValid(pDate)` / `isValidString(pDateString)` | validade (a de string depende do `Date.parse` do navegador; use ISO) |
| `isBefore`, `isAfter`, `isSame`, `isSameOrBefore`, `isSameOrAfter` `(d1, d2, [pUnit])` | comparações com precisão por unidade |
| `isBetween(d1, d2, d3, [pUnit])` | d1 entre d2 e d3 |
| `min(...dates)` / `max(...dates)` | menor/maior |
| `monthsBetween(d1, d2)` | meses entre |
| `startOfDay`, `endOfDay`, `firstOfMonth`, `lastOfMonth` | limites |
| `dayOfWeek`, `daysInMonth`, `getDayOfYear`, `setDayOfYear(pDate, pDay)`, `ISOWeek`, `weekOfMonth`, `isLeapYear`, `secondsPastMidnight` | utilidades |
| `since([pDate], [pShort])` → string | "há 2 dias" / "30m"; contraparte de `APEX_UTIL.GET_SINCE` |

```javascript
var fim = apex.date.add( apex.date.clone( inicio ), 30, apex.date.UNIT.DAY );
apex.date.format( new Date(), "DD/MM/YYYY HH24:MI" );
apex.date.parse( "29/06/2021", "DD/MM/YYYY" );
```

Fonte: [Namespace: date](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.date.html)

---

## 12. `apex.util`, `delayLinger`, `htmlBuilder` e templates

### apex.util: todas as funções

| Função | Descrição | Obs. |
|---|---|---|
| `applyTemplate(pTemplate, [pOptions])` → string | processa template estilo APEX no cliente | |
| `applyNamedTemplate(pTemplateName, [pOptions])` → string | aplica template nomeado (`args`) | Since 26.1 |
| `defineTemplates(pTemplates)` | define templates nomeados (com args, CSS e JS) | Since 26.1 |
| `getTemplateDef(name)` → object\|null / `listTemplates()` → string[] | consulta templates | Since 26.1 |
| `escapeHTML(pValue)` | escapa para conteúdo HTML (= `APEX_ESCAPE.HTML` estendido) | |
| `escapeHTMLAttr(pValue)` | escapa para valor de atributo (= `APEX_ESCAPE.HTML_ATTRIBUTE`) | |
| `escapeCSS(pValue)` | escapa para seletor CSS | |
| `stripHTML(pText)` | remove tags | |
| `debounce(fn, delay, [immediate])` | chama `delay` ms depois da última chamada | |
| `throttle(fn, wait, [immediate=true])` | no máximo uma vez a cada `wait` ms | |
| `getNestedObject(root, "a.b.c")` | devolve o objeto aninhado, criando o que faltar | |
| `toArray(pValue, [pSeparator])` | string → array (`":"` padrão, ou `{type, separator}`, ou RegExp) | |
| `arrayEqual(a1, a2)` | comparação rasa | |
| `getDateFromISO8601String(s)` | ISO 8601 → Date (fuso só "Z"); útil com datas de `APEX_JSON` | |
| `getScrollbarSize()` | `{width, height}` da barra de rolagem | |
| `showSpinner([pContainer], [pOptions])` → jQuery | spinner ARIA; remova com `.remove()` | |
| `htmlBuilder()` → htmlBuilder | construtor de HTML seguro | |
| `invokeAfterPaint(fn)` / `cancelInvokeAfterPaint(id)` | | **deprecated**: use `requestAnimationFrame`/`cancelAnimationFrame` |
| `delayLinger` | namespace anti-pisca de spinners | |

Fonte: [Namespace: util](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.util.html)

### Evitar XSS ao montar HTML no JavaScript (escapeHTML, escapeHTMLAttr, htmlBuilder)

Dado vindo do usuário ou do banco **sempre** passa por escape antes de entrar no DOM:

```javascript
apex.jQuery( "#show_user" ).append( apex.util.escapeHTML( $v( "P1_UNTRUSTED_NAME" ) ) );
apex.jQuery( "#show_user" ).attr( "title", apex.util.escapeHTMLAttr( $v( "P1_UNTRUSTED_NAME" ) ) );
apex.jQuery( "#" + apex.util.escapeCSS( "my.id" ) );
```

O `htmlBuilder` gera markup bem formado e escapado, mais simples e seguro que concatenar strings:

| Método | Descrição |
|---|---|
| `markup(s)` | markup cru (sem escape) |
| `attr([name], value)` | atributo com valor escapado e entre aspas |
| `optionalAttr(name, value)` | só se o valor não for vazio, 0 ou false |
| `optionalBoolAttr(name, bool)` | atributo booleano se true |
| `content(s)` | conteúdo escapado |
| `css(name, value)` | guarda CSS como `data-css-*` (evita violar CSP com `style` inline) |
| `append(otherBuilder)` | concatena outro builder |
| `clear()` | limpa para reutilizar |
| `toString()` | HTML gerado |
| `toJquery()` | jQuery com os CSS de `css()` aplicados |

```javascript
var out = apex.util.htmlBuilder();
out.markup( "<label" ).attr( "for", opt.id ).markup( ">" ).content( opt.label )
   .markup( "</label><input type='text'" ).attr( "id", opt.id )
   .optionalAttr( "title", opt.title ).attr( "value", "" ).markup( " />" );
$( "#container" ).html( out.toString() );
```

Para ser compatível com Content-Security-Policy sem `unsafe-inline`, não gere `<style>`, `<script>`, `style=` nem handlers inline.

Fonte: [Namespace: util](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.util.html), [Interface: htmlBuilder](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/htmlBuilder.html)

### Templates no cliente: apex.util.applyTemplate (placeholders, substituições e diretivas)

`applyTemplate` processa templates com a mesma sintaxe do servidor, mas usando os **valores atuais no navegador** (não o session state). Não suporta substituição sem ponto final (`&ITEM`), `#COLUMN#` antigo nem `PREPARE_URL`. Scripts no resultado são removidos. Ordem de processamento: diretivas → placeholders → substituições.

**Placeholders** `#NOME#` (opção `placeholders`). Embutidos: `#APEX$DOM_ID#`, `#APEX$IS_LAZY_LOADING#`, `#APEX$COMPONENT_CSS_CLASSES#`.

**Substituições**: `&ITEM.`, `&ITEM!FILTRO.`, `&"nome com espaço".`, `&APP_TEXT$CHAVE.`, `&{CHAVE p1=v1 p2="v 2"}.` (mensagem com parâmetros; exige compatibility mode ≥ 24.2). Propriedades: `&P1_NAME%LABEL.`, `%DISPLAY`, `%CHANGED`, `%DISABLED`; em colunas `%HEADING`, `%LABEL`, `%DISPLAY`, `%HEADING_CLASS`, `%COLUMN_CLASS`, `%REQUIRED`. Embutidas: `&APP_USER.`, `&APP_ID.`, `&APP_PAGE_ID.`, `&APP_SESSION.`, `&APP_FILES.`, `&WORKSPACE_FILES.`, `&REQUEST.`, `&DEBUG.`, `&APEX_FILES.`, `&IMAGE_PREFIX.` (legado), `&APEX_VERSION.`, `&APEX_BASE_VERSION.`. Ordem de resolução: mensagem → coluna → coluna de models ancestrais → page item → embutidas → extras.

**Filtros de escape**: `HTML` (padrão), `ATTR`, `RAW`, `STRIPHTML`.

**Diretivas**:

```
{if [!][?|=]NOME/} ... {elseif NOME2/} ... {else/} ... {endif/}
{case NOME/}{when A/} ... {when B/} ... {otherwise/} ... {endcase/}
{loop ["SEP"] ITEM/} &APEX$ITEM. &APEX$I. {endloop/}
{loop MODEL_ID/} &APEX$ID. &APEX$I. &APEX$META%valid. {endloop/}
{with/} ARG:=&COL. {apply NOME_TEMPLATE/}
{!comentário/}
{{/}   (abre-chaves literal)
```

- No `if`, é falso: string vazia, item com `isEmpty()`, ou valor em `falseValues` (padrão `["FALSE","F","f","N","n","0"]`). `?` testa só se é vazio e `=` testa só verdadeiro/falso.
- `APEX$META` no loop de model: `valid`, `state` (`O`/`D`/`I`/`U`), `allowedOperations`, `selected`, `agg`, `highlight`, `endControlBreak`, `grandTotal`, `errorMessage`, `warningMessage`. Loops de model só veem registros já buscados.

Opções: `placeholders`, `directives` (true), `defaultEscapeFilter` (`"HTML"` ou `false` para não escapar e evitar escape duplo), `includePageItems` (true), `model`, `record`, `extraSubstitutions`, `includeBuiltinSubstitutions` (true), `falseValues`, `iterationCallback`, `id`, `idPostfix`, `isLazyLoading`, `componentCSSClasses`.

```javascript
apex.jQuery( "#notification" ).html(
    apex.util.applyTemplate( "<div>#MESSAGE#</div>", { placeholders: { MESSAGE: "Tudo certo." } } ) );

const html = apex.util.applyNamedTemplate( "THEME$AVATAR", {      // 26.1
    args: { "TYPE": "INITIALS", "INITIALS": "{if P1_INI/}&P1_INI.{else/}N/A{endif/}" }
} );
```

`defineTemplates([{ name, template, defaultEscape, args: [{name, required, default, escape}], cssFileUrls: [{url, media, attr}], javaScriptFileUrls: [{url, requireJsModule, requireJsExp, requirejs, jet, attrs}] }])` (Since 26.1) define templates usados por `{with/}{apply/}` e `applyNamedTemplate`. Os arquivos são carregados na primeira aplicação.

Fonte: [Namespace: util](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.util.html)

### debounce, throttle e getNestedObject

```javascript
// formatar só quando o usuário para de digitar
apex.jQuery( "#P1_PHONE" ).on( "keypress", apex.util.debounce( formatValue, 100 ) );
// no máximo 1 chamada por segundo durante o scroll
$( document ).on( "scroll", apex.util.throttle( updatePosition, 1000, true ) );
// criar options.views.grid.features se não existirem
apex.util.getNestedObject( options, "views.grid.features" ).cellRangeActions = false;
```

`debounce` chama uma vez depois da sequência de eventos. `throttle` chama em intervalos regulares, guardando a última chamada.

Fonte: [Namespace: util](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.util.html)

### Spinner sem piscar: apex.util.showSpinner + apex.util.delayLinger

Processos rápidos não devem mostrar spinner, e processos que terminam logo depois de o spinner aparecer não devem fazê-lo piscar. `delayLinger.start(scope, showFn)` só mostra depois de um atraso, e `delayLinger.finish(scope, hideFn)` mantém visível por um tempo mínimo. Para cada `start` deve haver um `finish` com o mesmo `pScopeName`. O `apex.server` já faz isso internamente; use para seus processos longos.

```javascript
var spinner$, p = processoLongo();
apex.util.delayLinger.start( "main", function() {
    spinner$ = apex.util.showSpinner( $( "#container_id" ) );
} );
p.always( function() {
    apex.util.delayLinger.finish( "main", function() { spinner$.remove(); } );
} );
```

Opções de `showSpinner`: `alert` ("Processing"), `ariaProcessingStarted`, `ariaStillProcessing`, `ariaProcessed`, `spinnerClass`, `fixed` (fixo e anexado ao body, ignora o container), `suppressAria`.

Fonte: [Namespace: delayLinger](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.util.delayLinger.html), [Namespace: util](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.util.html)

---

## 13. `apex.debug`, `apex.storage`, `apex.theme`, `apex.widget` e `apex.pwa`

### apex.debug: log no console conforme o nível de debug

`LOG_LEVEL`: `OFF` 0, `ERROR` 1, `WARN` 2, `INFO` 4, `APP_TRACE` 6, `ENGINE_TRACE` 9.

| Função | Nível |
|---|---|
| `error(...args)` | sempre escreve (usa `console.trace` se houver) |
| `warn(...args)` | WARN |
| `info(...args)` | INFO |
| `trace(...args)` | APP_TRACE |
| `log(...args)` | maior nível (sempre que o log está ligado) |
| `message(pLevel, ...args)` | escreve se o nível atual ≥ `pLevel` |
| `getLevel()` / `setLevel(n)` | nível atual; sincronizado com o input escondido `#pdebug` do servidor. Numa sessão de desenvolvedor o padrão é WARN |

```javascript
apex.debug.info( "Carregou", dados );
apex.debug.error( "Falha: ", ex );
```

Fonte: [Namespace: debug](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.debug.html)

### apex.storage: cookies e web storage com escopo por app

| Função | Descrição |
|---|---|
| `getCookie(pName)` / `setCookie(pName, pValue)` | cookies |
| `hasLocalStorageSupport()` / `hasSessionStorageSupport()` | suporte do navegador |
| `getScopedLocalStorage({ prefix, useAppId=true, usePageId=false, regionId })` | wrapper do `localStorage` com prefixo nas chaves |
| `getScopedSessionStorage({...})` | idem para `sessionStorage` |

O wrapper tem `prefix`, `length`, `key(n)`, `getItem`, `setItem`, `removeItem`, `clear` e `sync()` (recalcula `length`). Se o navegador não suportar, o wrapper funciona sem efeito.

Todas as apps de uma instância (mesma origem) compartilham o web storage. O escopo por app/página evita colisão, mas **não é partição segura**: não guarde dado sensível. O web storage também não é compartilhado entre navegadores ou máquinas.

```javascript
var s = apex.storage.getScopedLocalStorage( { prefix: "Corlix", usePageId: true } );
s.setItem( "aba", "historico" );
```

Fonte: [Namespace: storage](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.storage.html)

### apex.theme: abrir e fechar regiões, media query e ajuda de campo

| Função | Descrição | Since |
|---|---|---|
| `openRegion(pRegion)` / `closeRegion(pRegion)` → jQuery | abre/fecha Inline Dialog, Inline Popup, Collapsible (widget com open/close ou expand/collapse) | 18.2 |
| `mq(pMediaQuery)` → boolean | testa media query (`window.matchMedia`) | 20.1 |
| `popupFieldHelp(pItemId\|{helpText,title}, [pSessionId], [pUrl])` | diálogo de ajuda do item | |

```javascript
apex.theme.openRegion( "meuDialogo" );   // Static ID da Inline Dialog
apex.theme.closeRegion( "meuDialogo" );
apex.theme.popupFieldHelp( { title: "Ajuda", helpText: "Texto de ajuda" } );
```

Para temas próprios, a ajuda acessível usa a classe `js-itemHelp` com `data-itemhelp="#CURRENT_ITEM_ID#"`. Alt+F1 exige `id="#CURRENT_ITEM_CONTAINER_ID#"` no label template.

Fonte: [Namespace: theme](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.theme.html)

### apex.widget: waitPopup e initPageItem (deprecated)

- `apex.widget.waitPopup([pContent])` → `{ remove() }`: overlay que bloqueia cliques (não o teclado) e mostra spinner. Feito para antes de um submit. O `apex.page.submit({showWait:true})` já usa. Para Ajax, prefira `apex.util.showSpinner` + `delayLinger`.
- `apex.widget.initPageItem()`: **deprecated**, embrulha `apex.item.create`.

```javascript
var popup = apex.widget.waitPopup();
apex.server.process( "LENTO" ).always( function() { popup.remove(); } );
```

Fonte: [Namespace: widget](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.widget.html)

### apex.pwa: instalação e push notifications (Since 21.2)

Só faz sentido com a app configurada como Progressive Web App.

| Função | Descrição |
|---|---|
| `getDisplayMode()` → string | `fullscreen`, `standalone`, `minimal-ui` ou `browser` |
| `isInstallable()` → Promise\<boolean\> | dá para instalar (prompt disponível, iOS/Safari etc.)? |
| `openInstallDialog()` | instala ou mostra instruções. Também via classe `.a-pwaInstall` ou `href="#action$a-pwa-install"` |
| `getInstallText()` | **deprecated** |
| `subscribePushNotifications()` / `unsubscribePushNotifications()` | inscrição em push |
| `hasPushSubscription()` → Promise\<boolean\> / `getPushSubscription()` → Promise\<PushSubscription\> | estado da inscrição |

```javascript
if ( await apex.pwa.isInstallable() ) { apex.pwa.openInstallDialog(); }
```

Fonte: [Namespace: pwa](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.pwa.html)

---

## 14. `apex.actions` e interface `actions`

### Conceito de actions: um comando, vários controles (botão, menu, atalho)

Uma *action* encapsula nome, rótulo, ícone, estado (habilitado/oculto) e comportamento de um comando. Ligue botões, menus, links e atalhos à action e tudo fica sincronizado. Tipos:
- **action**: tem `action` (função) ou `href`;
- **toggle**: `get`/`set` booleanos, sem `choices`;
- **radio group**: `get`/`set` + `choices`.

O singleton `apex.actions` é o contexto **global** (página). Componentes com várias instâncias (IG, recordView) criam contextos próprios com `apex.actions.createContext`. **Since 5.0** (interface), 5.1 (namespace).

**Binding**: atributo `data-action` (botões, selects, checkbox `js-actionCheckbox`, radio `js-actionRadioGroup`) ou `href="#action$nome"` em links. Sintaxe completa: `[context-id]nome-da-action?arg1=v1&arg2=v2` (`[global]` explícito para o global). Para uma action usada em várias linhas de um relatório, use `idArg` e `instanceSelector`.

```html
<button type="button" class="t-Button" data-action="send-email">Enviar</button>
<a href="#action$send-email">Enviar</a>
<button type="button" data-action="[emp]save">Salvar grid</button>
<button type="button" data-action="complete-task?taskId=&TASK_ID!ATTR.">Concluir</button>
```

Em botões, use `t-Button-label` (texto), `t-Button--icon` e `t-Button--noLabel` para o APEX atualizar rótulo, ícone e aria-label. Use `data-no-update="true"` para não atualizar.

Fonte: [Interface: actions](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/actions.html)

### apex.actions: funções do namespace (createContext, findContextById, atalhos)

| Função | Descrição |
|---|---|
| `createContext(pTypeName, pContext)` → actions | contexto ligado a um elemento (o foco precisa estar dentro dele para os atalhos funcionarem). Plug-ins: chame depois de `apex.region.create` |
| `findContext([pTypeName], pContext)` → actions | contexto de um elemento |
| `findContextById(pContextId)` → actions | pelo id do elemento ou da região (`"global"` = global). Ex.: `apex.actions.findContextById("contactsIG")` = `getActions` do IG |
| `getContextTypes()` → string[] / `getContextsForType(type)` → actions[] | listar |
| `removeContext(pTypeName, pContext)` | remove |
| `shortcutSupport([type])` | `"off"`, `"single"` ou `"sequence"` (padrão) |
| `setKeyCaps(map\|null)` / `getKeyCaps()` | nomes exibidos das teclas por layout |

Fonte: [Namespace: actions](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.actions.html)

### Interface actions: métodos (add, invoke, lookup, update, enable, hide, toggle, set)

| Método | Descrição |
|---|---|
| `add(pActions)` → boolean | adiciona uma ou várias. No global, **só depois do DOM pronto** |
| `addFromMarkup(pList$)` | cria a partir de `<ul><li data-id>` |
| `remove(pActions)` / `clear()` | remove (`clear` no global remove também as actions do APEX) |
| `lookup(name)` → action | obtém para alterar. Depois chame `update` |
| `update(name, [pArgs])` → boolean | propaga mudanças aos controles |
| `updateChoices(name)` | depois de mudar `choices` |
| `invoke(name, [pEvent], [pFocusElement], [pArgs])` | executa. Sem efeito se oculta ou desabilitada. Passe o evento e o elemento de foco |
| `toggle(name, [pArgs])` / `get(name, [pArgs])` / `set(name, value, [pArgs])` | toggle e radio |
| `enable/disable/show/hide(name, [pArgs])` | atalhos de estado (`pArgs` com `idArg` afeta uma instância) |
| `addShortcut(shortcut, name, [choice])` / `removeShortcut(shortcut)` | atalhos extras |
| `listShortcuts([markup])`, `shortcutDisplay(name, [markup])`, `ariaKeyshortcut(name)` | exibição de atalhos |
| `disableShortcuts()` / `enableShortcuts()` | aninháveis (usados por diálogos e menus) |
| `list()` | `[{name, label, choice}]` |
| `observe(cb)` / `unobserve(cb)` | `cb(action, operation, args)` com `add`, `remove`, `update` ou `updateChoices` |
| propriedades `context`, `typeName` | elemento e tipo (`"global"`) |

```javascript
$( function() {
    apex.actions.add( {
        name: "send-email",
        label: "Enviar e-mail",
        shortcut: "Ctrl+Alt+E",
        action: function( event, focusElement, args ) { /* ... */ }
    } );
} );
var a = apex.actions.lookup( "send-email" );
a.label = "Enviar agora"; apex.actions.update( "send-email" );
apex.actions.disable( "send-email" );
```

Fonte: [Interface: actions](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/actions.html)

### Propriedades do objeto action e sintaxe de atalhos (shortcutName)

`name` (sem espaço, `>`, `:` ou aspas; convenção `palavra-palavra`), `label`/`labelKey`, `onLabel`/`offLabel` (toggle antônimo), `contextLabel`, `title`/`titleKey`, `icon`, `onIcon`, `offIcon`, `iconType` (padrão `a-Icon`), `disabled`, `hide` (**não podem ser funções**), `shortcut`, `href`, `target`, `action(event, focusElement, args)` (retorne true se definiu o foco), `convertBindingArguments` (converte args string em número/booleano/JSON), `get`, `set`, `choices` (`label`, `value`, `icon`, `iconType`, `shortcut`, `disabled`, `group`), `labelClasses`, `labelStartClasses`, `labelEndClasses`, `itemWrapClasses`, `idArg`, `instanceSelector`, `purpose` (`"action"`/`"dialog"`, para `aria-roledescription` de links).

**Atalhos**: `[Ctrl+][Alt+][Meta+][Shift+]tecla`, nomes de tecla do layout US (`"A"`–`"Z"`, `"0"`–`"9"`, `"F1"`–`"F15"`, `"Enter"`, `"Escape"`, `"Page Down"`, `"Comma"`…). `CtrlOrMeta+` vira Command no macOS e Ctrl nos outros sistemas. Sequências separadas por vírgula (`"Ctrl+F2,G,H"`, `"C,S"`). Com o foco num campo de texto, atalhos que gerariam caracteres são ignorados. Ctrl+Alt pode colidir com AltGr.

Fonte: [Interface: actions](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/actions.html)

---

## 15. `apex.model` e interface `model`

### O que é o model do APEX (MVVM, formatos table/tree/record, master-detail) — Since 5.1

O *model* guarda dados em memória para a UI (é o *view-model* do padrão MVVM): as views leem e escrevem nele, ele notifica os inscritos e conversa com o servidor (fetch e save). O Interactive Grid, o Cards e outras regiões usam models. Formatos (`shape`):
- **table**: coleção ordenada de registros (linhas);
- **tree**: um nó raiz com filhos;
- **record**: um registro só.

Um registro é um **array** (`recordIsArray: true`, os campos são mapeados pelo `index` do `FieldMeta`) ou um **objeto**. Campos especiais: identidade (obrigatória em model editável), meta (metadados), children e parent identity (árvore). Valor com display separado: `{ d: "exibição", v: valor }`, onde só `v` é comparado e salvo.

**Master-detail**: models detalhe têm `parentModel` e `parentRecordId`. Cada registro mestre tem uma *instância* do detalhe, identificada por `["nomeDetalhe", "idMestre"]`. Instâncias sem referência e sem mudanças ficam em cache LRU (`get/setMaxCachedModels`). Models com mudanças só são destruídos com `apex.model.destroy`.

**Contagem de referências**: para cada `apex.model.get`/`create` deve haver um `apex.model.release`. Normalmente a região gerencia isso. Sem `regionId`, o model é **local** (não busca nem salva no servidor).

Fonte: [Namespace: model](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.model.html), [Interface: model](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/model.html)

### apex.model: funções do namespace (create, get, release, save, anyChanges, multipleFetch)

| Função | Descrição |
|---|---|
| `create(pModelId, pOptions, [pData], [pTotal], [pMoreData], [pDataOverflow])` → model | cria (sobrescreve se o id já existe) |
| `get(pModelId)` → model | obtém (incrementa a referência) |
| `release(pModelId)` | libera (com zero referências é destruído, salvo se mudou ou tem pai) |
| `destroy(pModelId)` | destrói ignorando referências e cache (nome sem instância destrói todas) |
| `list([pIncludeLocal], [pModelId], [pIncludeRelated])` → ModelId[] | lista |
| `save([pRequestData], [pOptions], [pModelId], [pIncludeRelated], [pCallServer])` → promise\|null | salva **numa única requisição** todos os models com mudanças (ou só os indicados) |
| `anyChanges([pIncludeLocal], [pModelId], [pIncludeRelated])` → boolean | algum model mudou? |
| `anyErrors(...)` → boolean | algum tem erro? |
| `multipleFetch([pRequestData], [pOptions], pModelIds, [pCallServer])` → promise\|null | busca dados de vários models numa requisição |
| `addChangesToSaveRequest(pRequestData, [pModelId], [pIncludeRelated])` → function | baixo nível; prefira `save` |
| `getMaxCachedModels()` / `setMaxCachedModels(n)` | cache de instâncias detalhe |

**Opções de `create`**: `shape` (`"table"`), `recordIsArray` (false), `fields` (**obrigatório**: `{CAMPO: FieldMeta}`), `identityField` (string ou array; obrigatório se editável e não record), `editable` (false), `trackChanges` (true), `onlyMarkForDelete` (true; false se `trackChanges` false), `regionId`, `ajaxIdentifier`, `pageItemsToSubmit`, `regionData`, `fetchData`, `saveData`, `requestOptions`, `callServer(requestData, requestOptions) → promise` (troca o `apex.server.plugin`, por exemplo para usar REST direto do navegador), `parentModel`, `parentRecordId`, `hasTotalRecords`, `paginationType` (`"none"`, `"one"`, `"progressive"`), `pageSize` (100), `genIdPrefix` (`"t"`), `childrenField`, `parentIdentityField`, `metaField`, `check`, `delayClearData`, `makeLoadingIndicator`, `visibilityFilter`, `visibilityFilterContext`, `version` (reservada).

```javascript
// model local simples
apex.model.create( "people", {
    shape: "table", recordIsArray: true,
    fields: { ID: { index: 0 }, NAME: { index: 1 }, AGE: { index: 2 } },
    identityField: "ID", editable: true, paginationType: "none"
}, [ ["00010","Mark","32"], ["00091","Mary","27"] ], 2 );

// salvar tudo que mudou na página
apex.model.save();

// atualizar dois IGs numa requisição só
let views = [ apex.region("r1").call("getCurrentView"), apex.region("r2").call("getCurrentView") ];
views.forEach( v => v.model.clearData( false ) );
apex.model.multipleFetch( null, { loadingIndicatorPosition: "page" },
        views.map( v => v.model.modelId() ) )
    .done( () => views.forEach( v => v.view$.grid( "refresh" ) ) );
```

Fonte: [Namespace: model](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.model.html)

### Interface model: métodos de leitura (getValue, getRecord, forEach, getSelectedRecords…)

| Método | Descrição |
|---|---|
| `getValue([pRecord], pFieldName)` → * | valor do campo (omita `pRecord` no shape record) |
| `getRecordValue(pRecordId, pFieldName)` | valor pelo id |
| `getRecord([pRecordId])` → Record\|null | registro pelo id **já buscado**. Identidade múltipla: array ou string de `getRecordId`. Sem `identityField` (table): índice. Record: sem argumento |
| `getRecordId(pRecord)` → string | id do registro |
| `recordAt(index)` / `indexOf(pRecord)` | por índice (table) |
| `getRecordMetadata([pRecordId])` → RecordMetadata | metadados (`fields` só existe se houver metadado de campo) |
| `getFieldKey(pFieldName)` | índice ou chave para ler `record[key]` direto |
| `getFieldMetadata(pFieldName)` → FieldMeta | metadados do campo |
| `isIdentityField(name)` | |
| `forEach(cb, [thisArg])` | percorre o que está no model (inclui agregados; **nunca busca**) |
| `forEachInPage(pOffset, pCount, cb, [thisArg])` | percorre uma página e **busca no servidor** se faltar. `cb(record, index, id, error)`; `record` null no fim ou em erro |
| `walkTree(pNode, visitor, [pParentNode])` | árvore em profundidade: `node`, `beginChildren`, `endChildren`, `postNode` |
| `root()`, `child(node, i)`, `childCount(node)`, `hasChildren(node)`, `parent(node)` | árvore |
| `getTotalRecords([pCurrentTotal])` / `getServerTotalRecords()` | totais (-1 se desconhecido) |
| `getDataOverflow()` | servidor tem mais que o máximo permitido |
| `getSelectedRecords()` / `getSelectedCount()` / `getSelectionState()` | seleção **guardada no model** (`persistSelection`). Em geral, prefira obter a seleção pela view |
| `isChanged()` / `getChanges()` | mudanças (auto-inseridos não contam em `isChanged`, mas aparecem em `getChanges`) |
| `hasErrors()` / `getErrors()` | erros |
| `isDisabled(rec, [meta])` | estado desabilitado |
| `getControlBreakId(rec)`, `hasControlBreaks()` | quebras |
| `getOption(name)` | opção |
| `modelId()` | id do model |
| `transform(pOptions, [pContext])` | converte os dados em outra estrutura (ex.: séries de gráfico JET) |

Fonte: [Interface: model](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/model.html)

### Interface model: métodos de escrita e servidor (setValue, insertNewRecord, deleteRecords, fetchRecords, save)

| Método | Descrição |
|---|---|
| `setValue([pRecord], pFieldName, pValue)` → `"SET"\|"DUP"\|"NC"\|null` | grava o campo; **erro** se o registro ou campo não permite edição |
| `setRecordValue(pRecordId, pFieldName, pValue)` | idem pelo id |
| `insertNewRecord([pParent], [pAfter], [pNewRecord])` → id temporário | insere (precisa de `allowAdd`) |
| `copyRecords(recs, [parent], [after])` / `moveRecords(...)` | copiar/mover |
| `deleteRecords(recs)` → number | apaga (ou marca, com `onlyMarkForDelete`) |
| `revertRecords(recs)` → number / `canRevertRecord(rec)` | desfazer |
| `allowAdd`, `allowEdit(rec)`, `allowDelete(rec)`, `allowDrag(rec)`, `check(op, ...)`, `dragOperations(recs)` | permissões |
| `setValidity("error"\|"warning"\|"valid", recordId, [field], [message])` | erro/aviso de registro ou campo |
| `metadataChanged(recordId, [field], [prop])` | avisa as views após mudar metadados à mão |
| `setDisabledState(id, bool)` / `setHiddenState(id, bool)` | estados |
| `setSelectionState(id, sel, [action])` / `clearSelection()` | **só para views** |
| `fetch([pOffset], [cb], [pNoProgress])` → promise | busca no servidor (raramente direto) |
| `fetchAll(cb, [pNoProgress=true])` | busca tudo (cuidado com volume) |
| `fetchRecords(recs, [cb])` → promise\|null | **recarrega registros específicos** do servidor (precisa de `identityField`) |
| `fetchChildNodes([node], [cb])` | árvore lazy |
| `save([cb])` → promise\|null | salva as mudanças deste model (null se nada a salvar ou se já há save em andamento) |
| `clearChanges()` | descarta o **rastreamento** de mudanças (não desfaz). Implícito depois do save |
| `clearData([pNotify=true])` | esvazia e manda `refresh` às views |
| `setData(data, [offset], [total], [moreData])` | carrega dados à mão |
| `setOption(name, value)` | só `genIdPrefix`, `pageItemsToSubmit`, `fetchData`, `saveData`, `regionData`, `parentRecordId`, `editable`, `trackChanges`, `onlyMarkForDelete`, `pageSize`, `requestOptions`, `callServer`, `visibilityFilter`, `visibilityFilterContext`, `delayClearData` |
| `updateVisibility([ctx])` | filtro no cliente pela `visibilityFilter` (marca `hidden`) |
| `subscribe(observer)` → viewId / `unSubscribe(viewId)` | notificações |
| `addChangesToSaveRequest(req)` | baixo nível |

**Valores devem ser strings**: o model aceita qualquer tipo, mas o servidor APEX espera string: `model.setValue( rec, "SALARY", "" + sal )`. `"DUP"` indica identidade duplicada no cliente (o servidor ainda pode rejeitar). `"NC"` indica que o valor não mudou.

```javascript
var result = model.setValue( rec, "PART_NO", novo );
if ( result === "DUP" ) { apex.message.alert( "Código já usado." ); }
```

Fonte: [Interface: model](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/model.html)

### Notificações do model (subscribe: set, insert, delete, refresh, refreshRecords, metaChange…)

`model.subscribe({ viewId, onChange(changeType, change), progressView, progressOptions })`:

| `changeType` | Quando | `change` traz |
|---|---|---|
| `addData` | dados chegaram do servidor | `parentNode`, `offset`, `count`, `replacedIds`, `firstIndex` |
| `set` | campo alterado | `oldValue`, `oldIdentity`, `recordId`, `record`, `field` |
| `insert` | registro inserido | `record`, `recordId`, `insertAfterId` |
| `delete` | registros apagados | `records`, `recordIds` |
| `copy` / `move` | copiados/movidos | `records`, `recordIds`, `insertAfterId` (+ `firstIndex`/`lastIndex` em move) |
| `revert` | revertidos | `records`, `recordIds`, `newIds` |
| `refresh` | dados novos ou o model deve buscar de novo | `clearDataPending` |
| `refreshRecords` | registros atualizados (save ou `fetchRecords`) | `records`, `recordIds`, `newIds` (inseridos: id antigo → novo) |
| `metaChange` | metadados mudaram (ex.: erro de validação) | `record`, `field`, `property` |
| `clearChanges` | depois do save ou de `clearChanges` | `deletedIds`, `changedIds` |
| `instanceRename` | id do mestre mudou (detalhe) | `oldInstance`, `newInstance` |
| `destroy` | model destruído | `{}` |

No IG, o evento `interactivegridviewmodelcreate` (`viewmodelcreate`) é o lugar de se inscrever no model de cada view (§16).

Fonte: [Interface: model](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/model.html)

### Tipos do model: FieldMeta, RecordMetadata e RecordFieldMetadata

**FieldMeta** (por campo em `fields`): `index`, `controlBreakIndex`, `defaultValue` (valor ou função), `dataType`, `calcValue(argsArray, model, record)` + `dependsOn` (campos calculados), `aggregates` (`COUNT`, `COUNT_DISTINCT`, `SUM`, `AVG`, `MIN`, `MAX`, `MEDIAN`), `parentField`, `noCopy`, `readonly`, `volatile` (gerado no servidor, não editável, não enviado), `virtual` (sem dado).

**RecordMetadata** (`getRecordMetadata`): `index`, `recSequence`, `deleted`, `inserted`, `autoInserted`, `updated`, `original`, `record`, `parent`, `error`, `warning`, `message`, `sel`, `highlight`, `disabled`, `hidden`, `allowedOperations { delete, update }`, `canEdit`, `canDelete`, `endControlBreak`, `agg`, `grandTotal`, `fields { CAMPO: RecordFieldMetadata }`.

**RecordFieldMetadata**: `changed`, `stale`, `error`, `warning`, `message`, `disabled` (enviado como string vazia), `highlight`, `ck` (checksum: campo somente leitura), `url` (célula de link).

**ModelId**: `"Nome"` ou `["NomeDetalhe", "idMestre"]`.

```javascript
// destacar salário alto (classe CSS própria)
var meta = model.getRecordMetadata( id ),
    salMeta = apex.util.getNestedObject( meta, "fields.SAL" );
salMeta.highlight = Number( model.getValue( rec, "SAL" ) ) > 5000 ? "warn-sal" : null;
model.metadataChanged( id );
```

Fonte: [Interface: model](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/model.html)

### Mensagens Ajax do model (formato JSON de fetch e save para plug-ins)

Todas as requisições usam `{ regions: [ { id, ajaxIdentifier, ...regionData, <específico> } ] }`.

- **fetch** (table), request `fetchData: { firstRow (1-based), maxRows, version, ...fetchData }`; response `fetchedData: { values: [record...], firstRow, moreData, dataOverflow, totalRows }`. Tree: `{ root: node }`. Record: `{ value: record }`.
- **fetchRecords**, request `fetchData: { primaryKeys: [ { recordId, pk: [...] } ], version }`; response `fetchedData: { values: [...] }`.
- **save**, request `saveData: { models: [ { version, instance, values: [record...] } ] }` (o meta de cada registro tem `op`: `i`, `u` ou `d`; inseridos vão com identidade `""`); response `fetchedData: { models: [ { values: [...] } ] }`.
- **fetchChildNodes**, request `fetchData: { parentId: [...]|null }`; response `{ root }` ou `{ <childrenField>: [...] }`.

No `save`, campos `volatile` são omitidos e o meta recebe `op` (array: último elemento; objeto: `_meta`).

Fonte: [Interface: model](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/model.html)

---

## 16. Interactive Grid: widget `interactiveGrid` e `interactiveGridView`

### Como o Interactive Grid funciona no cliente (model + views + actions) e como salva

O IG é um componente model-view: um model no cliente guarda os registros, os metadados e as mudanças; várias views (grid, ícone, detalhe, chart) mostram e editam; actions e eventos ligam a UI. O widget orquestra `grid`, `recordView` (single row view), `tableModelView`, `toolbar`, `menu`, `iconList`, `apex.actions`, `apex.model` e `apex.item`. A intenção é **customizar o IG da região nativa**, não criar instâncias do widget à mão.

- Editável: o model rastreia inserts, updates e deletes. A action **save** grava as mudanças do próprio grid **sem recarregar a página**.
- **Submit da página**: as mudanças pendentes do grid são processadas com os itens do form, as validações e os processos, pelo processo **Interactive Grid - Automatic Row Processing (DML)** de cada grid. Assim, mestre (form) e detalhes (grids) são validados e salvos numa transação. Nesse caso você pode esconder o botão Save do grid.

Fonte: [Widget: interactiveGrid](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/interactiveGrid.html), [Understanding and Customizing Grid Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-and-customizing-grid-behavior.html)

### Actions pré-definidas do Interactive Grid (save, edit, refresh, selection-add-row…)

Acesse com `apex.region(id).call("getActions")`. Actions ocultas ou desabilitadas não fazem nada ao ser invocadas.

| Grupo | Actions (tipo) |
|---|---|
| Busca/filtro | `search`, `search-case-sensitive` (toggle), `filter-column` (radio) |
| Relatórios salvos | `change-report` (radio), `save-report`, `show-save-report-as-dialog`, `show-edit-report-dialog`, `delete-report`, `reset-report` |
| Views | `change-view`, `chart-view`, `single-row-view`, `close-single-row-view`, `stretch-columns` (toggle), `change-rows-per-page` (radio) |
| Diálogos | `show-columns-dialog`, `show-filter-dialog`, `show-sort-dialog`, `show-aggregate-dialog`, `show-flashback-dialog`, `show-highlight-dialog`, `show-control-break-dialog`, `show-download-dialog`, `show-help-dialog` |
| Linha atual | `row-add-row`, `row-duplicate`, `row-delete`, `row-refresh`, `row-revert` |
| Seleção | `selection-mode` (toggle: linha × célula), `selection-duplicate`, `selection-delete`, `selection-refresh`, `selection-revert`, `selection-copy`, `selection-add-row`, `selection-copy-down`, `selection-clear`, `selection-fill` (as três últimas só na view Grid; várias exigem IG editável) |
| Dados | `refresh`, `edit` (toggle), `save` |

```javascript
apex.region( "emp" ).call( "getActions" ).invoke( "save" );
apex.region( "emp" ).call( "getActions" ).set( "edit", true );
apex.region( "emp" ).call( "getActions" ).set( "change-view", "detail" );
var a = apex.region( "emp" ).call( "getActions" ).lookup( "save" ); // inspecionar
```

Pegadinha: desligar o botão Save declarativamente **esconde a action `save`**. Se você precisa invocá-la sem botão, mantenha a opção declarativa ligada e remova o botão da toolbar via `toolbarData`.

Fonte: [Widget: interactiveGrid](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/interactiveGrid.html)

### Opções do IG no JavaScript Initialization Code (features, toolbar, defaultGridViewOptions, initActions…)

Só valem **na inicialização** (salvo indicação). Use `apex.util.getNestedObject`, porque o servidor não envia os valores padrão.

| Opção | Tipo / padrão | Descrição |
|---|---|---|
| `editable` | boolean / false | IG editável |
| `features` | `{ filter: true, flashback: true }` | recursos gerais |
| `toolbar` | `{ actionMenu, columnSelection, editing, reset, save, savedReports, searchField }` todos true; false/null = sem toolbar | partes da toolbar padrão (`editing` só esconde o botão; para impedir edição use `editable`) |
| `toolbarData` | Array / `copyDefaultToolbar()` | toolbar customizada |
| `initActions` | `function(actions)` / null | adicionar ou alterar actions antes da toolbar e dos menus serem ligados (`actions.context` = elemento do IG) |
| `initialSelection` | boolean / true | seleção inicial |
| `reportSettingsArea` | boolean / true | área de filtros, quebras e destaques |
| `trackParentSelection` | boolean / true | detalhe segue a seleção do mestre (false = use `setMasterRecord`) |
| `saveLoadingIndicator` / `saveLoadingIndicatorPosition` | n/d | spinner do save (útil em mestre com detalhes ocultos) |
| `text` | `{ addRowButton, noDataFound, noParentSelected, help }` | textos (padrões em `APEX.IG.ADD_ROW`, `APEX.IG.NO_DATA_FOUND`, `APEX.IG.SELECT_1_ROW_IN_MASTER`) |
| `defaultGridViewOptions` | Object | opções do widget `grid` (§17) |
| `defaultSingleRowOptions` | Object | opções do `recordView` |
| `defaultIconViewOptions` / `defaultDetailViewOptions` | Object | opções do `tableModelView` |
| `defaultModelOptions` | Object | opções do model (`apex.model.create`), ex.: `pageSize` |

```javascript
function( options ) {
    apex.util.getNestedObject( options, "features" ).flashback = false;
    var tb = apex.util.getNestedObject( options, "toolbar" );
    tb.actionMenu = false;
    var g = apex.util.getNestedObject( options, "defaultGridViewOptions" );
    g.multiple = true;
    g.persistSelection = true;
    g.selectionStateItem = "P2_SELECTED_EMPNOS";   // PKs ":"-separadas
    g.footer = false;
    apex.util.getNestedObject( options, "defaultModelOptions" ).pageSize = 200;
    options.initActions = function( actions ) {
        actions.hide( "show-help-dialog" );
        actions.lookup( "show-filter-dialog" ).shortcut = "Ctrl+Alt+F";
        actions.update( "show-filter-dialog" );
        actions.add( { name: "my-action", label: "Olá", action: function() { /* ... */ } } );
    };
    return options;
}
```

**Por coluna**: no *JavaScript Initialization Code* da coluna, `options.defaultGridColumnOptions = { headingCssClasses, columnCssClasses, ... }` define propriedades do `grid#columns` para aquela coluna.

Algumas opções do `grid` podem interferir no funcionamento do IG (a doc avisa que o IG pode sobrescrevê-las).

Fonte: [Widget: interactiveGrid](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/interactiveGrid.html), [Widget: grid](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/grid.html), [Understanding and Customizing Grid Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-and-customizing-grid-behavior.html)

### Customizar a toolbar do IG (copyDefaultToolbar, toolbarFind, toolbarInsertAfter, toolbarRemove)

`$.apex.interactiveGrid.copyDefaultToolbar()` devolve uma cópia da estrutura padrão com métodos auxiliares (que funcionam antes de o widget existir):
- `toolbarFind(id)`: grupo, controle, item de menu ou nome de action;
- `toolbarInsertAfter(id, item)`;
- `toolbarRemove(id)` → item removido. **Remover não desliga a funcionalidade**: a action continua invocável.

Grupos padrão: `search`, `reports`, `views`, `actions1` (menu Actions), `actions2` (Edit/Save), `actions3` (Add Row), `actions4` (Reset).

```javascript
function( options ) {
    var toolbarData = $.apex.interactiveGrid.copyDefaultToolbar();
    // botão de download após o menu Actions
    toolbarData.toolbarFind( "actions1" ).controls.push( {
        type: "BUTTON", action: "show-download-dialog", iconBeforeLabel: true
    } );
    // ou mover o item de menu para um botão
    var download = toolbarData.toolbarRemove( "show-download-dialog" );
    download.type = "BUTTON"; download.iconBeforeLabel = true;
    toolbarData.toolbarInsertAfter( "actions_button", download );
    options.toolbarData = toolbarData;
    return options;
}
```

Os botões da toolbar são dirigidos por action: basta informar `action: "<nome>"`.

Fonte: [Widget: interactiveGrid](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/interactiveGrid.html)

### Eventos do Interactive Grid (selectionchange, save, viewchange, modechange, viewmodelcreate)

Nome completo = `interactivegrid` + evento em minúsculas. Com `region.on`, use o nome curto.

| Evento | Dados | Observação |
|---|---|---|
| `selectionchange` | `{ selectedRecords, model }` | todas as views com seleção; DA *Selection Change [Interactive Grid]* |
| `viewchange` | `{ view, created }` | DA *View Change*. **Registre em *Function and Global Variable Declaration*** para pegar a criação |
| `viewmodelcreate` | `{ viewId, model }` | lugar de fazer `model.subscribe` |
| `modechange` | `{ editMode }` | grid e single row view |
| `save` | `{ status: "success" }` | depois de salvar |
| `reportchange` / `reportsettingschange` | n/d | relatório ou configurações mudaram |

```javascript
apex.region( "emp" ).on( "selectionChange", function( event, data ) {
    var model = data.model;
    data.selectedRecords.forEach( function( rec ) {
        console.log( model.getValue( rec, "ENAME" ) );
    } );
} );
$( "#emp" ).on( "interactivegridsave", function( event, data ) {
    if ( data.status === "success" ) { apex.message.showPageSuccess( "Salvo" ); }
} );
```

Fonte: [Widget: interactiveGrid](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/interactiveGrid.html)

### Métodos do widget interactiveGrid (getSelectedRecords, getCurrentView, getViews, gotoCell, refresh)

| Método | Descrição |
|---|---|
| `getActions()` → actions | contexto de actions do IG |
| `getCurrentView()` → interactiveGridView / `getCurrentViewId()` → string | view atual |
| `getViews([pViewId])` | uma view (`"grid"`, `"chart"`, `"icon"`, `"detail"`) ou mapa de todas |
| `getSelectedRecords()` → Array\|null | registros selecionados na view atual; `[]` sem seleção; `null` se a view não suporta seleção. Com `persistSelection` pode abranger várias páginas |
| `setSelectedRecords(pRecords, [pFocus], [pNoNotify])` | seleciona (registros ou ids; `[]` limpa). Com `pNoNotify` os detalhes não atualizam |
| `getToolbar()` → jQuery\|null | widget da toolbar |
| `gotoCell([pModelInstanceId], pRecordId, [pColumn])` | foca a célula (muda para a view editável) |
| `refresh()` | busca dados no servidor (avisa se há mudanças pendentes) |
| `resize()` | quando o container muda de tamanho (normalmente automático) |
| `setMasterRecord(pMasterModel, pMasterRecord)` | define o mestre à mão (`trackParentSelection: false`) |
| `focus()` | busca ou view atual |
| `$.apex.interactiveGrid.copyDefaultToolbar()` (estático) | ver acima |

Fonte: [Widget: interactiveGrid](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/interactiveGrid.html)

### Interface interactiveGridView (view$, model, getContextRecord)

Cada view (`grid` = widget grid + single row view; `chart` = JET ojChart; `detail` e `icon` = tableModelView) é uma `interactiveGridView`:

| Membro | Descrição |
|---|---|
| `model` : model / `modelName` : ModelId | model da view |
| `view$` : jQuery | widget da view (ex.: `view$.grid("getSelectedRecords")`) |
| `singleRowMode` : boolean / `singleRowView$` : jQuery | single row view |
| `internalIdentifier`, `title`, `icon`, `cssClass` | identificação |
| `getContextRecord(pContext)` → Array | registro que contém um elemento (ex.: botão na célula), array de no máximo 1 |
| `getSelectedRecords()` / `setSelectedRecords(recs, [focus], [noNotify])` | seleção da view |

Verifique `view.supports.edit` antes de mexer em edição (usado no exemplo de `clearChanges`).

Fonte: [Interface: interactiveGridView](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/interactiveGridView.html), [Interface: model](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/model.html)

### Receita: ler, alterar e salvar dados do IG por JavaScript (getSelectedRecords, getValue, setValue, save)

```javascript
var ig$   = apex.region( "emp" ).widget(),
    view  = ig$.interactiveGrid( "getCurrentView" ),
    model = view.model;

// 1) ler os selecionados
ig$.interactiveGrid( "getSelectedRecords" ).forEach( function( rec ) {
    var id = model.getRecordId( rec ),
        sal = model.getValue( rec, "SAL" );
} );

// 2) alterar (string!) e salvar
var rec = model.getRecord( "7839" );
if ( rec && model.allowEdit( rec ) ) {
    model.setValue( rec, "SAL", String( 5000 ) );
}
ig$.interactiveGrid( "getActions" ).invoke( "save" );   // preferido

// 3) somar uma coluna do que está no model (ignora deletados e agregados)
var total = 0;
model.forEach( function( r, i, id ) {
    var meta = model.getRecordMetadata( id ), v = parseFloat( model.getValue( r, "SAL" ) );
    if ( !isNaN( v ) && !meta.deleted && !meta.agg ) { total += v; }
} );
```

Se for salvar fora da action, primeiro sincronize a view com o model:

```javascript
var grid = apex.region( "igRegion" ).call( "getViews" ).grid;
grid.view$.grid( "finishEditing" ).done( function() {
    apex.model.save( null, null, grid.modelName, true ).done( function() { /* ... */ } );
} );
```

A doc diz que é **muito melhor** usar a action `save` do que esse caminho.

Fonte: [Widget: interactiveGrid](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/interactiveGrid.html), [Widget: grid](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/grid.html), [Interface: model](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/model.html)

### Receita: atualizar só a linha editada após fechar o diálogo (fetchRecords)

Helper do Developer's Companion (em *Function and Global Variable Declaration*):

```javascript
function refreshGridRowOrRegion( regionHtmlDomId, primaryKey ) {
    const region = apex.region( regionHtmlDomId );
    if ( !region || region.type !== "InteractiveGrid" ) {
        throw new Error( "A região precisa ser um Interactive Grid" );
    }
    if ( primaryKey ) {
        const model = region.call( "getViews", "grid" ).model;
        const record = model.getRecord( primaryKey );
        if ( record ) { model.fetchRecords( [ record ] ); return; }
    }
    region.refresh();   // insert/delete exigem refresh completo
}
```

Na página que chama: DA **Dialog Closed** com seletor `body` → Execute JavaScript Code:

```javascript
const editado = this.data && this.data.P2_EMPNO_EDITED;
refreshGridRowOrRegion( "employees", editado || null );
```

No diálogo: uma computation Pre-Rendering copia a PK para o item escondido `P2_EMPNO_EDITED` no caso de edição. O processo *Close Dialog* devolve esse item em *Items to Return*. Um processo *Clear Session State* limpa o item quando o botão DELETE é pressionado, o que força o refresh completo.

Fonte: [Understanding and Customizing Grid Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-and-customizing-grid-behavior.html)

### Receita: cancelar edição do IG sem perguntar (clearChanges + refresh)

```javascript
var ig$ = apex.region( "emp" ).widget(),
    view = ig$.interactiveGrid( "getCurrentView" );
if ( view.supports.edit ) {
    ig$.interactiveGrid( "getActions" ).set( "edit", false ); // sai do modo de edição
    view.model.clearChanges();
}
apex.region( "emp" ).refresh();
```

Sem o `clearChanges`, o refresh perguntaria se o usuário quer descartar as mudanças.

Fonte: [Interface: model](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/model.html)

---

## 17. Widget `grid`

### Widget grid: edição, seleção, clipboard e menus de contexto (Since 5.1)

O `grid` (derivado de `tableModelViewBase`) é a view tabular do IG. Segue o padrão WAI-ARIA de data grid.

- **Edição**: tem modo de navegação e modo de edição (só uma célula por vez). Para uma célula ser editável: o grid precisa ser `editable`, o registro editável pelo model, a coluna ter `elementId`, não ser `readonly`, e o metadado do campo não ter `ck`. Quem edita é o **column item** (como um page item, mas ligado à coluna), movido para dentro da célula. Os column items ficam num `<div class="u-vh" aria-hidden="true">` com cada item em `<div class="a-GV-columnItem">`.
- **Seleção**: por linha (`multiple`, `rowHeaderCheckbox`, `selectionStateItem`, `persistSelection`) ou por intervalo de células (`selectCells`, `multipleCells`, `multipleRanges` 26.1, `selectCellsColumn` 26.1, `selectCellsRow` 26.1).
- **Clipboard**: copiar, recortar e colar (Ctrl/Cmd+C/X/V; Ctrl+Shift+V cola inserindo). Formatos text/html, text/plain e um JSON próprio. Colar age como digitação: roda DAs e validações. Em LOVs, cole os valores de retorno. Se houver mais linhas do que cabe, insere linhas novas. Também aceita arrastar e soltar dados tabulares. Recortar e colar exigem grid editável e fora do modo de edição. `allowCut`/`allowPaste` são Since 26.1.
- **Menu de contexto**: `contextMenu` (opções do widget `menu`), `contextMenuId` ou `contextMenuAction`. O `beforeOpen` recebe `menuElement`, `grid`, `selection`, `selectedRecords`/`selectedRanges`.

Classes CSS: `a-GV`, `a-GV-row`, `a-GV-cell`, `a-GV-header`, estados `is-selected`, `is-focused`, `is-active`, `is-deleted`, `is-changed`, `is-updated`, `is-inserted`, `is-error`, `is-warning`, `is-readonly`.

Teclado (principais): F2/Enter entra em edição, Esc sai; Enter/Shift+Enter próxima/anterior linha em edição; Tab/Shift+Tab células (com `autoAddRecord`, Tab no fim insere linha); Insert insere; Delete apaga linhas selecionadas; Alt+F1 ajuda da coluna; Alt+Up/Down ordena; Ctrl+Left/Right largura; Shift+Left/Right move coluna; Ctrl/Cmd+A seleciona tudo.

Fonte: [Widget: grid](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/grid.html)

### Opções do widget grid (defaultGridViewOptions)

| Opção | Padrão | Descrição |
|---|---|---|
| `columns` | obrigatório | `[ { COLUNA: definição } ]` (ver próxima seção) |
| `columnGroups` | n/d | `{ GRUPO: { heading, label, headingAlignment, parentGroupName } }` |
| `modelName` | obrigatório | model |
| `editable` | false | permite edição (o model também precisa permitir) |
| `allowEditMode` / `allowInsert` / `allowDelete` | true | teclado (o model decide o que pode) |
| `allowCopy` / `allowCut` (26.1) / `allowPaste` (26.1) | true | clipboard (só na inicialização) |
| `autoAddRecord` | false | insere registro se o model está vazio ou ao passar do último |
| `multiple` | false | várias linhas |
| `selectCells` / `multipleCells` / `multipleRanges` | false / true / false | seleção por células |
| `selectAll` | true | Ctrl+A / checkbox "todos" |
| `selectCellsColumn` / `selectCellsRow` | false (26.1) | selecionar coluna ou linha inteira de células |
| `allowSelectHidden` | false | permitir selecionar linhas ocultas (quebras recolhidas) |
| `persistSelection` | false | seleção guardada no model (sobrevive à paginação virtual) |
| `selectionStateItem` | null | page item que recebe as PKs selecionadas, separadas por `:` |
| `loadIncompleteSelection` | `"on-demand"` | `"always"`, `"never"`, `"on-demand"` |
| `rowHeader` | `"none"` | `"plain"`, `"sequence"`, `"label"`. Grid editável precisa de um para mostrar erros de linha |
| `rowHeaderCheckbox` / `rowHeaderLabelColumn` / `rowHeaderWidth` | false / null / CSS vars | cabeçalho de linha |
| `pagination` | n/d | `{ scroll, virtual, loadMore, showPageLinks, maxLinks (5), showPageSelector, showRange (true), firstAndLastButtons, hideSinglePage }` |
| `rowsPerPage` | null (pela altura) | registros por página |
| `footer` / `hideEmptyFooter` / `stickyFooter` / `stickyTop` / `hasSize` | true/false/false/false/false | layout |
| `fixedRowHeight` | true | altura igual |
| `hideDeletedRows` | false | esconde em vez de riscar |
| `columnSort` / `columnSortMultiple` / `reorderColumns` / `resizeColumns` | true | interação nos cabeçalhos (o grid não ordena; dispara `sortchange`) |
| `collapsibleControlBreaks` | true | quebras recolhíveis |
| `highlights` | n/d | `{ id: { seq, row, color, background, cssClass } }` |
| `aggregateLabels` / `aggregateTooltips` | {} | agregados |
| `noDataMessage` / `noDataIcon` | "" / `icon-irr-no-results` | sem dados |
| `showNullAs` | `"-"` | nulos |
| `skipReadonlyCells` | false | Tab pula células somente leitura |
| `tabbableCellContent` | `"a,button,input,span[role='checkbox']"` | conteúdo focável na navegação |
| `constrainNavigation` | true | setas não vazam do grid |
| `tooltip` | n/d | jQuery UI tooltip (`content` recebe model, recordMeta, colMeta, columnDef) |
| `contextMenu` / `contextMenuId` / `contextMenuAction` | null | menu |
| `entityTitleSingular` / `entityTitlePlural` / `selectionStatusMessageKey` | null / `"APEX.GV.SELECTION_COUNT"` | textos de contagem |
| `updateStatus` | null | callback `{ deletedCount, selectedCount, total, incomplete, altMessage }` para mostrar status fora do rodapé |
| `progressOptions` | `{fixed: !hasSize}` | spinner |
| `applyTemplateOptions` | {} | para `cellTemplate` |

Fonte: [Widget: grid](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/grid.html)

### Definição de coluna do grid (grid#columns e defaultGridColumnOptions)

Propriedades: `elementId` (column item que edita), `heading` (aceita markup), `label` (sem markup), `headingAlignment`, `alignment` (`start`, `end`, `center`, `left`, `right`), `headingCssClasses`, `columnCssClasses`, `cellCssClassesColumn`, `cellTemplate` (template `applyTemplate`), `copyValueToClipboard` (true = display do model, false = valor de retorno da LOV, ou função), `escape`, `seq`, `width` (mínima), `noStretch`, `groupName`, `useGroupFor`, `canHide`, `hidden`, `readonly`, `linkTargetColumn`, `linkText`, `linkAttributes`, `isRequired` (classe `is-required` no cabeçalho), `helpid`, `virtual`, `noCopy`, `usedAsRowHeader`, `noHeaderActivate`, `sortDirection`/`sortIndex`/`canSort`, `controlBreakDirection`/`controlBreakIndex`, `frozen` (só as primeiras; no máximo 20), `property` (automático).

No IG, defina por coluna em *JavaScript Initialization Code* da coluna:

```javascript
function( options ) {
    options.defaultGridColumnOptions = {
        headingCssClasses: "special-heading",
        columnCssClasses: "special-cell"
    };
    return options;
}
```

Fonte: [Widget: grid](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/grid.html)

### Eventos do widget grid (gridselectionchange, gridcurrentcellchange, gridsortchange…)

Prefixo `grid` + nome: `activatecell` (Enter ou duplo clique em grid **não editável**, Since 18.2: `{cell$, row$}`), `activatecolumnheader` (`{header$, column}`), `cancelcolumnheader`, `columnreorder` (`{header$, column, newPosition, oldPosition}`), `columnresize` (`{header$, column, width}`), `currentcellchange`, `modechange` (`{editMode}`), `pagechange` (`{offset, count}`), `selectionchange` (sem dados; use `getSelectedRecords`), `sortchange` (`{header$, column, direction, action}`; o handler atualiza `sortIndex`/`sortDirection`, chama `refreshColumns` e busca dados ordenados).

```javascript
$( "#gridDomId" ).on( "gridcurrentcellchange", function() {
    var g$ = $( this ), cell$ = g$.grid( "getCurrentCell" ),
        col = g$.grid( "getColumnForCell", cell$ );
    console.log( col ? col.heading : "nenhuma", cell$.text() );
} );
```

Fonte: [Widget: grid](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/grid.html)

### Métodos do widget grid (getSelectedRecords, setActiveRecordValue, lockActive, gotoCell…)

| Método | Descrição |
|---|---|
| `getSelectedRecords()` / `setSelectedRecords(recs, [focus], [noNotify])` → number | seleção por registros (vazio com `selectCells`) |
| `getSelection()` / `setSelection(rows, ...)` / `getRecords(rows)` | seleção como jQuery (só o que está no DOM) |
| `getSelectedRanges()` / `setSelectedRanges(ranges, ...)` | intervalos (26.1). `grid.Range`: `startRowIndex`, `startColIndex`, `startRowKey`, `startColKey`, `endRowIndex`, `endColIndex`, `endRowKey`, `endColKey`, `incomplete` (fim -1 = ilimitado) |
| `getSelectedRange()` | **deprecated** (use `getSelectedRanges`) |
| `selectAll([focus], [noNotify])` | seleciona tudo |
| `getActiveRecord()` / `getActiveRecordId()` | registro em edição |
| `setActiveRecordValue(pColumn)` | atualiza o model depois de `setValue` com change suprimido |
| `lockActive()` / `unlockActive()` | trava a linha ativa durante operação assíncrona (um unlock por lock). DAs em colunas do IG já fazem isso sozinhas |
| `finishEditing()` → Promise | sincroniza view → model |
| `getActiveCellFromColumnItem(item)` | célula do column item |
| `getCurrentCell()` / `setCurrentCell(cell$, [focus])` / `getColumnForCell(cell$)` | célula atual |
| `getColumns()` / `refreshColumns()` | colunas; depois de alterar a definição, `refreshColumns` + `refresh` |
| `showColumn`, `hideColumn`, `freezeColumn`, `unfreezeColumn`, `moveColumn(col, pos)`, `moveColumnGroup(level, de, para)`, `setColumnWidth(col, px)` | colunas |
| `inEditMode()` / `setEditMode(bool, [select])` | modo |
| `gotoCell(recordId, [column])` | foca (troca a página se precisar) |
| `copyDownSelection([cols], [cb])` / `fillSelection(valor, [cols], [cb])` | copiar para baixo / preencher (`{v, d}` para LOV) |
| `firstPage`, `previousPage`, `nextPage`, `lastPage`, `gotoPage(n)`, `loadMore`, `getPageInfo` | paginação |
| `fetchAllData([showProgress])` | busca tudo e mantém a seleção |
| `getModel()` | model atual (não guarde a referência; use `apex.model.get`/`release`) |
| `refresh([focus])`, `resize()`, `focus()` | |
| `debugCellEdit(bool)` | **só para depurar** plug-ins de coluna: deixa o item na célula para inspecionar o CSS |

Exemplo da doc: column item com valor atualizado de forma assíncrona:

```javascript
let salary = apex.item( "C_SALARY" );
$( salary.node ).on( "change", function() {
    const grid$ = apex.region( "MyGrid" ).call( "getCurrentView" ).view$;
    grid$.grid( "lockActive" );
    setTimeout( function() {
        salary.setValue( parseFloat( salary.getValue() ) + 10, null, true ); // sem change
        grid$.grid( "setActiveRecordValue", "SALARY" ).grid( "unlockActive" );
    }, 10 );
} );
```

Fonte: [Widget: grid](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/grid.html)

---

## 18. Widgets `tableModelViewBase`, `tableModelView` e `recordView`

### tableModelViewBase: base de paginação e edição sobre model (Since 5.1)

Widget base (não use direto) de `grid` e `tableModelView`. Opções herdadas: `modelName`, `editable`, `autoAddRecord`, `pagination`, `rowsPerPage`, `footer`, `hideEmptyFooter`, `stickyFooter`, `stickyTop`, `hasSize`, `fixedRowHeight`, `hideDeletedRows`, `highlights`, `persistSelection`, `loadIncompleteSelection`, `noDataMessage`, `noDataIcon`, `showNullAs`, `entityTitleSingular`, `entityTitlePlural`, `selectionStatusMessageKey` (`"APEX.TMV.SELECTION_COUNT"`), `updateStatus`, `progressOptions`, `applyTemplateOptions`. Métodos: `getModel`, `getPageInfo`, `firstPage`/`previousPage`/`nextPage`/`lastPage`/`gotoPage`/`loadMore`, `fetchAllData`, `finishEditing`, `getActiveRecord`/`getActiveRecordId`, `setActiveRecordValue`, `lockActive`/`unlockActive`.

`pageInfo`: `rowHeight`, `recordsPerRow`, `firstOffset`, `lastOffset` (1-based), `pageSize`, `pageOffset` (0-based), `total`, `scrollOffset`.

Quem implementa edição por column items deve inicializar os itens, sincronizar model ↔ item, renderizar somente leitura e disparar `apexbeginrecordedit`/`apexendrecordedit`.

Fonte: [Widget: tableModelViewBase](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/tableModelViewBase.html)

### tableModelView: relatório por template (Cards, views ícone e detalhe do IG)

View de lista ou cards dirigida por template sobre um model table, com paginação, seleção e quebras. Não edita, mas reage às mudanças do model. Markup: um elemento vazio. Duas formas: templates (`beforeTemplate` padrão `<ul>`, `recordTemplate`, `afterTemplate` `</ul>`, `headerTemplate`, `aggregateTemplate`, `controlBreakTemplate`, `controlBreakBeforeTemplate`, `controlBreakAfterTemplate`) ou opções de lista padrão (`labelColumn`, `iconClassColumn`, `imageURLColumn`, `imageAttributes`, `linkTarget`, `linkTargetColumn`, `linkAttributes`).

Substituições do `recordTemplate`: `&APEX$ROW_ID.`, `&APEX$ROW_INDEX.`, `&APEX$ROW_URL.`, `&APEX$ROW_STATE_CLASSES.`, `&APEX$VALIDATION_MESSAGE.`. Placeholders: `#APEX$SELECTOR#` (checkbox ou radio de seleção) e `#APEX$ROW_IDENTIFICATION#` (atributos `data-id` e `data-rownum`, **obrigatórios** no elemento do item).

Padrões de markup suportados: **layout grid** (role grid > row > gridcell com `aria-label`; o mais acessível), **lista simples** (`ul > li`) e **tabela simples** (`tbody > tr`). Quebras planas usam `controlBreakSelector`; aninhadas (lista de listas) não funcionam com paginação virtual nem com agregados.

Opções de seleção e foco: `itemNavigationMode` (`"none"`, `"focus"`, `"select"`; com focus/select exige `itemSelector`), `multiple`, `selectAll`, `selectAllId`, `selectionStateItem`, `accLabelColumn`, `collectionClasses`, `clipboardValue`, `allowCopy`, `syncHeaderHScroll`, `constrainNavigation`. `useIconList`, `iconListOptions` e `getIconList` são **deprecated**.

Eventos: `currentitemchange`, `pagechange`, `selectionchange`. Métodos: `focus`, `getCurrentItem`, `getCurrentItemValue`, `setCurrentItem`, `setCurrentItemValue`, `getSelection`, `getSelectedRecords`, `getSelectedValues`, `setSelection`, `setSelectedRecords`, `setSelectedValues`, `selectAll`, `getRecords`, `refresh`, `resize`, mais os herdados.

Fonte: [Widget: tableModelView](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/tableModelView.html)

### recordView: formulário de um registro do model (single row view do IG)

Formulário gerado dinamicamente para ver ou editar um registro do model, usando os mesmos column items do grid (os dois não podem estar visíveis e em edição ao mesmo tempo). As regras de edição são as do grid (`elementId`, `readonly`, `ck`).

Actions: `delete-record`, `duplicate-record`, `insert-record`, `refresh-record`, `revert-record`, `next-record`, `previous-record`, `exclude-null-values` (toggle), `exclude-hidden` (toggle).

Opções: `modelName`, `fields` (`[ { CAMPO: def } ]`), `fieldGroups`, `editable`, `alwaysEdit` (começa em edição; duplo clique, Enter e Esc não trocam o modo), `recordOffset`, `actionsContext`, `toolbar`, `formCssClasses`, `labelAlignment` (`"end"`), `idPrefix`, `skipDeletedRecords`, `showExcludeHiddenFields`, `showExcludeNullValues`, `showNullAs`, `noDataMessage`, `noDataIcon`, `hasSize`, `autoAddRecord`, `progressOptions`, `applyTemplateOptions`. No IG: `defaultSingleRowOptions` (ex.: `alwaysEdit: true`).

Eventos: `modechange`, `recordchange`. Métodos: `getActions`, `getRecord`, `getActiveRecord(Id)`, `getFields`, `refreshFields`, `fieldElement(name)`, `gotoField(recordId, [field])`, `inEditMode`, `setEditMode`, `finishEditing`, `setActiveRecordValue`, `lockActive`/`unlockActive`, `getToolbar`, `getModel`, `refresh`, `resize`, `focus`.

Fonte: [Widget: recordView](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/recordView.html)

---

## 19. Widgets `menu`, `menuButton` e `iconList`

### Widget menu: menus popup e barras de menu (Since 5.0)

Implementa menu popup ou menu bar (padrões WAI-ARIA). Markup: um `<div>` vazio; o conteúdo vem de `items` (array de `menu.Item`), de markup `<ul><li>` ou de conteúdo customizado. Menus popup vão para o fim do `body` e são **re-renderizados a cada abertura**, então você pode alterar `items` antes de abrir.

**menu.Item** (`type`): `"action"` (`label`, `action` ou `href`, `target`, `icon`, `accelerator`), `"toggle"` (`get`, `set`, `onLabel`/`offLabel`), `"radioGroup"` (`get`, `set`, `choices`), `"subMenu"` (`menu: { items }`), `"separator"`. Comuns: `id`, `labelKey` (e `onLabelKey`/`offLabelKey`), `hide` e `disabled` (boolean ou função), `iconType`, `iconStyle`, `onIcon`/`offIcon`, `args`, `actionContextId`, `ariaKeyshortcut`, `current` (menubar com `behaveLikeTabs`). Na menubar, um subMenu com `action`/`href` vira *split item*.

**Integração com actions**: se `action` é string, é o nome de uma action (contexto global ou `actionsContext`). Rótulo, ícone, disabled e atalho vêm da action. Quando `disabled`/`hide` vêm de uma action, não podem ser funções.

Opções: `items`, `menubar` (false; só na inicialização), `menubarOverflow`, `menubarShowSubMenuIcon`, `behaveLikeTabs`, `actionsContext`, `asyncFetchMenu(menu, callback)`, `customContent`, `firstItemIsDefault`, `iconType` (`"a-Icon"`), `idPrefix`, `callout`, `slide`, `tabBehavior` (`"EXIT"`), `useLinks` (true), `popupMenuLabelId` (Since 26.1).

Eventos: `beforeOpen`, `afterClose` (`actionTaken`, `actionTookFocus`), `create`. Métodos: `open(x, [y], [args])`, `toggle(x, [y], [args])`, `find(id)`, `refresh()` (menubar), `resize()`, `setCurrentMenuItem(item)`.

```javascript
$( "#myMenu" ).menu( { items: [
    { type: "action", label: "Editar", action: function() { editar(); } },
    { type: "separator" },
    { type: "action", action: "send-email" },              // usa a action
    { type: "toggle", label: "Detalhes", get: () => mostrar, set: v => { mostrar = v; } }
] } );
```

Fonte: [Widget: menu](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/menu.html)

### menuButton: botão que abre menu (data-menu, data-hover-menu)

Não é um widget: é markup. `data-menu="idDoMenu"` num `<button>` faz o clique alternar o menu. O botão recebe `is-active` enquanto o menu está aberto e o APEX cuida dos atributos ARIA. Botões criados depois do carregamento precisam de `aria-haspopup="menu"` e `aria-expanded="false"`. `data-menu-position="inline"` abre ao lado. **Hover menu** (`data-hover-menu`): o botão ou link faz sua ação e, ao pairar o mouse, abre o menu; precisa de `aria-expanded="false"` e não pode ter `aria-haspopup`.

```html
<button type="button" data-menu="myMenu" class="t-Button">Menu</button>
```

Teclado: Space/Enter/Down abrem. Hover menu abre com as setas.

Fonte: [Widget: menuButton](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/menuButton.html)

### Widget iconList: lista de ícones selecionável em grade (Since 5.0)

ListBox com itens em grade (todos do mesmo tamanho, definido por CSS). Setas em 2 dimensões, digitar para selecionar, copiar, menu de contexto e ativação (duplo clique ou Enter; clique simples no modo `navigation`). Markup: `<ul>` com `<li>`; `class="is-selected"` marca a seleção inicial e `data-value` dá o valor.

Opções: `multiple`, `navigation` (só na criação), `itemSelector` + `addItemSelector` (checkbox `<span class="u-selector">`), `label` (seletor para digitar e buscar), `tabbableContent`, `noNavKeyContent`, `allowCopy`, `contextMenu`/`contextMenuId`/`contextMenuAction`. Eventos: `activate`, `selectionchange`. Métodos: `getSelection`, `getSelectionValues`, `setSelection(items$, [focus], [noNotify])`, `getColumns`, `getRows`, `refresh`, `resize`, `focus`.

Fonte: [Widget: iconList](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/iconList.html)

---

## 20. Widget `treeView` e interface `treeNodeAdapter`

### Widget treeView: árvore com seleção, menus e arrastar e soltar (Since 5.0)

Mostra dados hierárquicos de qualquer fonte por meio de um `treeNodeAdapter` (opção `getNodeAdapter`) ou a partir de markup. A árvore deve ter uma raiz única; para várias raízes use `showRoot: false`.

Opções principais: `getNodeAdapter`, `adapterTypesMap`, `showRoot` (true), `expandRoot` (true), `collapsibleRoot` (true), `autoCollapse`, `multiple`, `nodeSelector` (checkbox ou radio), `navigation` (clique ativa e navega para `getLink`), `useLinks` (true), `doubleClick` (false ou ação), `actionsContext`, `iconType` (`"a-Icon"`), `labelClass`, `idPrefix`, `tooltip`, `allowCopy`, `contextMenu`/`contextMenuId`/`contextMenuAction`, edição (`keyboardAdd`, `keyboardDelete`, `keyboardRename`, `clickToRename`) e drag & drop (`dragAndDrop`, `dragMultiple`, `dragReorder`, `dragExpandDelay` 1200, `dragAppendTo`, `dragContainment`, `dragCursor`, `dragCursorAt`, `dragHelper`, `dragOpacity`, `dragScroll`, `dragScrollSensitivity`, `dragScrollSpeed`, `dragZIndex`, `scope`).

Eventos: `activateNode` (o handler pode chamar `preventDefault` para não navegar), `selectionChange`, `expansionStateChange`, `beginEdit`, `endEdit`, e os de drag (`start`, `drag`, `stop`, `beforeStop`, `activate`, `deactivate`, `over`, `out`).

Métodos: `expand`, `expandAll`, `collapse`, `collapseAll`, `find(pOptions)` (com função `match`), `getSelection`, `getSelectedNodes`, `setSelection`, `setSelectedNodes`, `getNodes(nodeContent$)`, `getTreeNode(node)`, `getExpandedNodeIds`, `getExpandedState`, `getNodeAdapter`, `addNode`, `addNodeInPlace`, `renameNodeInPlace`, `deleteNodes`, `deleteTreeNodes`, `moveNodes`, `copyNodes`, `update(node$, [render])`, `refresh([node$])`, `focus`. Estático: `$.apex.treeView.makeDefaultNodeAdapter(pData, [pTypes], [pHasIdentity], [pInitialExpandedNodeIds])`.

A região **Tree** do APEX é implementada com este widget: acesse com `apex.region(id).widget()` e chame `treeView(...)`.

```javascript
var adapter = $.apex.treeView.makeDefaultNodeAdapter( {
    label: "Raiz", children: [ { label: "Filho 1", children: [ { label: "Neto" } ] } ]
}, null, false );
$( "#myTree" ).treeView( { getNodeAdapter: function() { return adapter; } } );

apex.region( "arvore" ).widget().treeView( "expandAll" );
```

Fonte: [Widget: treeView](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/treeView.html)

### Interface treeNodeAdapter e nó padrão (defaultNode, typeInfo)

O adapter é **todo** o acesso da árvore aos dados. Áreas: estrutura (`root`, `child`, `childCount`, `hasChildren`, `fetchChildNodes` para carga lazy; a raiz e o 1º nível não devem ser lazy), apresentação (`getLabel`, `getIcon`, `getClasses`, `getLink`, `getLinkTarget` (Since 20.1), `getAccDescription`, `isDisabled`, `isHidden`, `renderNodeContent` **deprecated**), modificação (`addNode`, `renameNode`, `deleteNode`, `moveNodes`, `copyNodes`), permissões (`allowAdd`, `allowRename`, `allowDelete`, `allowDrag`, `dragOperations`) e estado de visualização (`setExpanded`, `isExpanded`, `getExpandedNodeIds`, `getExpandedState`, `setViewId`, `getViewId`, `clearViewId`).

**defaultNode** (adapter padrão): `label`, `id`, `type`, `link`, `linkTarget`, `children` (array vazio = pode ter filhos; omita em folhas), `icon`, `accDescription`, `classes`, `isDisabled`, `operations`, `_parent` (automático). A região Tree adiciona `tooltip`. **typeInfo**: configuração por `type` (com o tipo reservado `"default"`), com padrões e operações permitidas. O adapter padrão não persiste edições (edição pelo adapter padrão é experimental).

Fonte: [Interface: treeNodeAdapter](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/treeNodeAdapter.html), [Widget: treeView](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/treeView.html)

---

## 21. Funções globais (*Non-namespace APIs*)

### Funções globais $v, $s, $x e utilitários DOM legados

Funções antigas fora de namespace, quase todas começando com `$`. Em código novo prefira `apex.item`, `apex.util` e jQuery. Ficam aqui para leitura de código existente.

| Função | Descrição |
|---|---|
| `$v(pNd)` / `$v2(pNd)` / `$s(pNd, v, [d], [suppress])` | valor de item (§4) |
| `$v_Array(pNd)` / `$f_ReturnChecked(pNd)` | valor como array |
| `$v_CheckValueAgainst(pThis, pValue)` | valor bate com algum de uma lista |
| `$v_Upper(pNd)` | maiúsculas direto no elemento (não passa por `setValue` nem dispara change) |
| `$nvl(pTest, pDefault)` | default se vazio ou false |
| `$x(pNd)` → Element\|false | elemento por id |
| `$x_ByClass`, `$x_FormItems`, `$x_UpTill(pNd, tag, [class])` | busca no DOM |
| `$x_Hide`, `$x_Show`, `$x_Toggle`, `$x_Remove`, `$x_HideAllExcept`, `$x_HideChildren`, `$x_ShowChildren`, `$x_HideSiblings`, `$x_ShowSiblings`, `$x_ShowAllByClass` | visibilidade |
| `$x_HideItemRow`, `$x_ShowItemRow`, `$x_ToggleItemRow`, `$x_ItemRow(pNd, 'TOGGLE'\|'SHOW'\|'HIDE')` | só layout em **tabela** (procuram `tr`) |
| `$x_Class`, `$x_ClassByClass`, `$x_SetSiblingsClass`, `$x_Style`, `$x_RowHighlight`, `$x_RowHighlightOff` | classes e estilos |
| `$x_Value(pNd, v)`, `$x_disableItem(pNd, bool)`, `$f_DisableOnValue`, `$f_Hide_On_Value_Item(_Row)`, `$f_Show_On_Value_Item(_Row)` | valor e estado |
| `$x_CheckImageSrc`, `$x_SwitchImageSrc`, `$x_ToggleWithImage` | imagens |
| `$f_CheckAll`, `$f_CheckFirstColumn`, `$f_SelectValue`, `$f_SelectedOptions`, `$f_SetValueSequence`, `$f_Swap`, `$f_ValuesToArray`, `$f_get_emptys` | formulários |
| `$d_ClearAndHide`, `$dom_AddInput`, `$dom_AddTag`, `$dom_MakeParent`, `$tr_AddTD`, `$tr_AddTH`, `html_RemoveAllChildren`, `html_SetSelectValue` | DOM |
| `$u_Carray(pNd)` / `$u_Narray(pNd)` | normalizar para array ou valor |

Fonte: [Non-namespace APIs](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/global.html)

---

## 22. Problemas conhecidos e pegadinhas (formato de caso)

### Loop infinito ou página travando ao usar setValue dentro de um handler de change

**Sintoma:** o navegador trava ou a DA de *Change* roda sem parar depois de um `apex.item(...).setValue(...)`.
**Causa:** `setValue` dispara `change` por padrão. Gravar no mesmo item dentro do handler do `change` dele dispara o handler de novo.
**Correção:** passe `pSuppressChangeEvent = true`: `apex.item("P1_X").setValue(v, null, true)`. Em column item do IG, chame depois `grid$.grid("setActiveRecordValue", "COLUNA")`, porque o model só é atualizado pelo `change`.
**Prevenção:** sempre que o handler escreve no item que o disparou, suprima o evento.

Fonte: [Interface: item](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/item.html), [Widget: grid](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/grid.html)

### apex.server.process cai sempre no fail (parsererror) mesmo com o PL/SQL funcionando

**Sintoma:** o processo Ajax roda, mas o `.done` nunca é chamado e o `.fail` recebe erro de parse.
**Causa:** o `dataType` padrão de `apex.server.process`/`plugin` é **`"json"`**. Se o processo escreve HTML ou texto (`htp.p`, `apex_util.prn`), a resposta não é JSON válido.
**Correção:** passe `{ dataType: "text" }` (ou `"html"`) nas opções, ou faça o PL/SQL devolver JSON válido (`apex_json`).
**Prevenção:** defina o formato da resposta junto com o processo. Trate `textStatus === "APEX"` no `fail` para erros devolvidos pelo APEX (detalhe em `errorThrown`).

Fonte: [Namespace: server](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.server.html)

### O PL/SQL do Ajax Callback ou da região lê o valor antigo do item

**Sintoma:** `:P1_ITEM` no processo On Demand, no Execute Server-side Code ou na query da região vem vazio ou com o valor anterior, embora a tela mostre outro.
**Causa:** `setValue` e a digitação só mudam o valor no navegador. O session state só é atualizado quando o item vai na requisição.
**Correção:** `apex.server.process(..., { pageItems: ["P1_ITEM"] })`; *Items to Submit* na DA; *Page Items to Submit* na região que faz refresh.
**Prevenção:** liste em "submit" todo item lido pelo servidor numa requisição Ajax.

Fonte: [Namespace: server](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.server.html), [Referencing Page Item Values](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/referencing-page-item-values.html), [Understanding AJAX and Redirect](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-ajax-and-redirect.html)

### apex.region(...).refresh() não faz nada ou dá erro "Cannot read properties of null"

**Sintoma:** a região não atualiza, ou `apex.region("x")` devolve `null`.
**Causa:** (1) não existe elemento com aquele id: falta Static ID, o id está errado, ou a região tem **Server-side Condition** falsa e não foi renderizada; (2) o tipo de região não suporta refresh.
**Correção:** dê um Static ID à região e use exatamente esse valor. Para regiões condicionais, renderize sempre e controle a visibilidade no cliente (ou recarregue a página).
**Prevenção:** teste `apex.region.isRegion(id)` antes de chamar métodos.

Fonte: [Namespace: region](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.region.html), [Interface: region](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/region.html)

### refresh(true) não mantém a página no Interactive Grid ou no Cards

**Sintoma:** depois de `apex.region(id).refresh(true)`, o grid ou os cards voltam para a primeira página.
**Causa:** `pKeepPagination` depende da região. Segundo o Developer's Companion, **no 26.1 só o Interactive Report o respeita**.
**Correção:** no IG, para atualizar um registro use `model.fetchRecords([rec])` (mantém a posição). Para o resto, aceite o refresh completo.

Fonte: [Interface: region](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/region.html), [Understanding and Customizing Grid Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-and-customizing-grid-behavior.html)

### Código depois de apex.message.confirm roda antes de o usuário responder

**Sintoma:** o registro é apagado (ou a próxima linha roda) antes de o usuário clicar em OK.
**Causa:** `apex.message.confirm` e `alert` **não bloqueiam** e não retornam true/false, ao contrário de `window.confirm`.
**Correção:** coloque a ação dentro do callback: `apex.message.confirm(msg, function(ok){ if (ok) { ... } })`.

Fonte: [Namespace: message](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.message.html)

### Mensagem de erro aparece com as tags HTML escritas na tela

**Sintoma:** o texto de `apex.message.showErrors` mostra `<b>` literalmente.
**Causa:** `unsafe` é `true` por padrão, então o APEX escapa a mensagem.
**Correção:** com HTML confiável (ou já escapado), passe `unsafe: false`. Se o texto vem do usuário, mantenha o escape.

Fonte: [Namespace: message](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.message.html), [Displaying Messages with JavaScript](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/displaying-messages-javascript.html)

### TypeError no JavaScript Initialization Code do Interactive Grid (options.toolbar is undefined)

**Sintoma:** o IG não carrega e o console mostra `Cannot set properties of undefined` em `options.toolbar.x = ...` ou `options.defaultGridViewOptions.x = ...`.
**Causa:** o servidor só envia as opções que diferem do padrão, então objetos aninhados podem não existir.
**Correção:** `apex.util.getNestedObject(options, "toolbar").searchField = false;` e **sempre `return options;`**.
**Prevenção:** nunca suponha que um objeto pai exista nas opções do IG.

Fonte: [Widget: interactiveGrid](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/interactiveGrid.html), [Understanding and Customizing Grid Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-and-customizing-grid-behavior.html)

### invoke("save") do Interactive Grid não salva nada

**Sintoma:** `apex.region("ig").call("getActions").invoke("save")` não faz nada.
**Causa:** o botão Save foi desligado declarativamente, o que **esconde a action `save`**, e actions ocultas ou desabilitadas são ignoradas. Outra causa possível: o IG não é editável ou não há mudanças.
**Correção:** deixe o Save ligado no Property Editor e remova só o botão pela `toolbarData` (`toolbarRemove("save")`). Ou salve pelo submit da página, com o processo *Interactive Grid - Automatic Row Processing (DML)*.

Fonte: [Widget: interactiveGrid](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/interactiveGrid.html), [Understanding and Customizing Grid Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-and-customizing-grid-behavior.html)

### Handler de interactivegridviewchange não dispara na primeira exibição

**Sintoma:** o evento só dispara quando o usuário troca de view, não na carga.
**Causa:** o handler foi registrado em *Execute when Page Loads*, depois de o IG já ter sido inicializado.
**Correção:** registre em *Function and Global Variable Declaration* (antes da inicialização), como o exemplo oficial. Para se inscrever no model, use `viewmodelcreate`.

Fonte: [Widget: interactiveGrid](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/interactiveGrid.html)

### apex.actions.add falha ou some quando chamado em Function and Global Variable Declaration

**Sintoma:** a action não existe ou os botões com `data-action` não respondem.
**Causa:** o contexto global `apex.actions` só existe depois do DOM pronto.
**Correção:** `$( function() { apex.actions.add({...}); } );` ou coloque em *Execute when Page Loads*. Para o IG, use `initActions`.

Fonte: [Interface: actions](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/actions.html)

### model.setValue lança erro ou não grava no Interactive Grid

**Sintoma:** exceção em `model.setValue`, ou o valor não aparece no grid.
**Causa:** o registro não permite edição (model não editável, `allowedOperations`, registro deletado ou agregado, `clearDataPending`) ou o campo é `readonly`/`volatile`/tem `ck`. Também acontece ao usar o model de outra view, e não o da view atual.
**Correção:** teste `model.allowEdit(rec)` antes; use `apex.region(id).call("getCurrentView").model` ou `getViews("grid").model`; grave string (`"" + valor`).

Fonte: [Interface: model](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/model.html), [Widget: interactiveGrid](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/interactiveGrid.html)

### getSelectedRecords do IG devolve null

**Sintoma:** `apex.region("ig").call("getSelectedRecords")` devolve `null`.
**Causa:** a view atual não suporta seleção (ex.: chart ou detail).
**Correção:** trate `null`; mude para a view grid (`getActions().set("change-view","grid")`) ou use `getViews("grid")`. Se nada estiver selecionado, o retorno é `[]`.

Fonte: [Widget: interactiveGrid](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/interactiveGrid.html)

### Ações seguintes da Dynamic Action nunca executam depois de uma ação assíncrona

**Sintoma:** a DA para numa ação de plug-in ou numa ação com *Wait for Result*.
**Causa:** a ação pausou a DA e ninguém chamou `apex.da.resume`.
**Correção:** chame `apex.da.resume(this.resumeCallback, false)` no sucesso e `apex.da.handleAjaxErrors(jqXHR, textStatus, errorThrown, this.resumeCallback)` no erro. Guarde `this.resumeCallback` numa variável antes do callback assíncrono, porque `this` muda.

Fonte: [Namespace: da](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.da.html)

### Ajax dentro de apexbeforepagesubmit ou apexpagesubmit não completa

**Sintoma:** a requisição é cortada ou a página submete antes da resposta.
**Causa:** os handlers desses eventos **não podem** fazer processamento longo ou assíncrono, nem Ajax síncrono ou assíncrono.
**Correção:** faça a chamada antes (num botão que roda o Ajax e, no `done`, chama `apex.page.submit`) ou valide no servidor.

Fonte: [Namespace: apex](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.html)

### Substitution string (&APP_ID., &APP_SESSION.) não é trocada no arquivo .js

**Sintoma:** a URL sai com `&APP_SESSION.` literal e a navegação falha.
**Causa:** substitution strings só são processadas no que o servidor renderiza (atributos de página, DAs, templates), não em arquivos estáticos.
**Correção:** use `apex.env.APP_ID`, `apex.env.APP_SESSION`, `apex.env.APP_FILES` etc. (Since 21.2). Para páginas com checksum, leve a URL pronta (`APEX_PAGE.GET_URL`) num item.

Fonte: [Namespace: apex](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.html), [Namespace: navigation](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.navigation.html)

### Diálogo aberto por JavaScript dá erro de checksum ou acesso negado

**Sintoma:** `apex.navigation.dialog("f?p=...")` montado no cliente abre um erro em vez da página.
**Causa:** a URL de diálogo precisa do checksum gerado no servidor.
**Correção:** gere a URL com `APEX_PAGE.GET_URL` (por exemplo numa computation ou num Execute Server-side Code que preenche um item escondido) e passe o valor para `apex.navigation.dialog`. Prefira links e botões declarativos com destino do tipo página, que o APEX já gera com checksum.

Fonte: [Namespace: navigation](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.navigation.html)

### Título do diálogo modal sai vazio com &P60_ITEM.

**Sintoma:** o título configurado como `Endereço de &P60_ENAME.` aparece sem o nome.
**Causa:** o título é definido antes de o item ter valor no ciclo de render.
**Correção:** defina o título no Page Load com `apex.util.getTopApex().jQuery(".ui-dialog-content").dialog("option","title", ...)`. Para não piscar, ponha `&INITIALLY_BLANK.` no título.

Fonte: [Including Context Info in Dialog Title](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/including-context-info-dialog-title.html)

### apex.lang.getMessage devolve a própria chave

**Sintoma:** aparece `MINHA_CHAVE` na tela em vez do texto.
**Causa:** a Text Message não está com **Used in JavaScript** ligado (não foi carregada na página) ou a chave não existe no idioma.
**Correção:** ligue *Used in JavaScript* ou carregue sob demanda com `apex.lang.loadMessages(["MINHA_CHAVE"]).done(...)`. Teste com `hasMessage`.

Fonte: [Namespace: lang](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.lang.html)

### formatCompactNumber devolve o número sem formatação

**Sintoma:** `apex.locale.formatCompactNumber(123456)` devolve `"123456"`.
**Causa:** os recursos do locale ainda não terminaram de carregar.
**Correção:** chame dentro de `apex.locale.resourcesLoaded(function(){ ... })`.

Fonte: [Namespace: locale](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.locale.html)

### apex.date.add altera a data original

**Sintoma:** a data de início também muda depois de calcular a data de fim.
**Causa:** `add`, `subtract` e `setDayOfYear` alteram o objeto passado e o devolvem.
**Correção:** `apex.date.add( apex.date.clone( inicio ), 30, apex.date.UNIT.DAY )`.

Fonte: [Namespace: date](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.date.html)

### $v devolve valores separados por ":" mesmo com separador customizado

**Sintoma:** item multivalor configurado com `~` ou JSON array, mas `$v` devolve `A:B`.
**Causa:** `$v` sempre junta com `:` e ignora o separador e o storage type do item (24.1+).
**Correção:** use `apex.item(x).getValue()` (array) e, para converter strings, `apex.util.toArray(s, apex.item(x).getMultiValueStorage())`.

Fonte: [Non-namespace APIs](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/global.html), [Interface: item](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/item.html)

### Popup ou nova janela não abre (bloqueador de popups)

**Sintoma:** `apex.navigation.popup` ou `openInNewWindow` devolve `null` e nada abre.
**Causa:** o navegador bloqueia janelas abertas fora de uma interação direta do usuário (por exemplo, depois de um Ajax).
**Correção:** chame a partir do handler de `click` do link ou botão. Com `noopener` (padrão em `_blank`), o retorno de `openInNewWindow` é sempre `null`, o que não indica falha.

Fonte: [Namespace: navigation](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.navigation.html)

### Aviso de alterações não salvas ao sair por um botão Cancelar customizado

**Sintoma:** o navegador pergunta se o usuário quer sair ao clicar num "Cancelar" próprio.
**Causa:** o *Warn on Unsaved Changes* detecta itens ou models alterados.
**Correção:** chame `apex.page.cancelWarnOnUnsavedChanges()` antes, ou adicione a classe `js-ignoreChange` ao link ou botão. No `redirect`, passe `pIgnoreUnsavedChanges = true`.

Fonte: [Namespace: page](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.page.html), [Namespace: navigation](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.navigation.html)

### Funções antigas param de existir ao desligar o legado (legacy*.js)

**Sintoma:** depois de desmarcar *Include Deprecated or Desupported Javascript Functions*, o console mostra `xxx is not defined`.
**Causa:** a função estava em `legacy*.js`.
**Correção:** substitua pelas APIs atuais (`apex.item`, `apex.server`, `apex.util`…) ou religue o legado temporariamente. Use o jQuery Migrate para achar uso de jQuery obsoleto.
**Prevenção:** antes de desligar, procure no app e nos `.js` as funções listadas no arquivo legado.

Fonte: [Introduction (JavaScript API)](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/index.html)

### Model ocupando memória ou detalhe com dados velhos (get sem release)

**Sintoma:** em master-detail com muitas trocas de mestre, a memória cresce ou o detalhe mostra cache antigo.
**Causa:** `apex.model.get`/`create` sem o `release` correspondente; models com mudanças não são liberados.
**Correção:** um `release` para cada `get`/`create`; `getModel()` dos widgets não deve ser guardado (o model pode mudar); ajuste `apex.model.setMaxCachedModels(n)`; `destroy` só se tiver certeza de que ninguém usa.

Fonte: [Namespace: model](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.model.html), [Widget: grid](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/grid.html)

---

## Aplicação no Corlix Hub

### Onde o JavaScript fica nos .apx do Corlix Hub (bloco javaScript em APEXlang)

Nos exports APEXlang (`corlixhub/pages/*.apx`), os atributos da §1 aparecem no bloco `javaScript { ... }` da página:

| Atributo da doc | Chave no `.apx` | Exemplo no projeto |
|---|---|---|
| File URLs | `fileUrls` | p3, p13, p19, p20: `#APP_FILES#organograma#MIN#.css` / `#APP_FILES#historico-carreira#MIN#.css` |
| Function and Global Variable Declaration | `functionAndGlobalVariableDeclaration` | p3 (funções `org*`), p13 (namespace `hc`), p18 (namespace `carreira`) |
| Execute when Page Loads | `executeWhenPageLoads` | p3, p13, p18 (`carreira.ajustarCampos(false)`) |
| Execute JavaScript Code (DA) | `action: executeJsCode` + `settings.jsCode` | p4 (`preparar-envio`), p16 (ViaCEP) |

Código JS em bloco cercado ` ```javascript-browser ` (`ai-context/02` §1). O padrão de módulo (`ai-context/06` §4) separa o `.js` em três blocos: 1 → *Function and Global Variable Declaration*, 2 → *Execute when Page Loads*, 3 → DAs. Isso bate com a ordem de execução da doc (declarações antes do *ready*, inicialização depois).

Um detalhe sobre arquivos: o App Builder **gera sozinho o `.min.js`** ao salvar um `.js` em Static Application Files. O `ai-context/08` §1 regra 5 (manter `.min` à mão) foi escrito para **CSS**. Arquivos `.js` novos continuam precisando entrar em `shared-components/static-files.apx` e ser referenciados com `#APP_FILES#nome#MIN#.js`. Hoje os `.js` dos módulos são colados nos atributos da página, não servidos como arquivo.

Fonte: [Managing Page Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-page-attributes-in-page-designer.html), [Including Helper Functions in All Pages](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/including-helper-functions-all-pages.html)

### Padrões de API já usados no projeto e o que a doc 26.1 diz sobre eles

- **p3 Organograma** (`modulos/organograma/organograma.js`): `apex.item(ORG_ITEM_FOCO).setValue(String(id))` + `apex.region(ORG_REGIAO).refresh()` para trocar o foco sem recarregar, e `apex.server.process("ORG_DETALHES", { x01: id }, { dataType: "text" })` para o drawer. Está de acordo com a doc: `dataType: "text"` é necessário porque o callback devolve HTML. O item de foco só chega à query da região se estiver em **Page Items to Submit** da região.
- **p13 Histórico de carreira**: DA no evento `apexafterclosedialog` com `javaScriptExpression: document` → Refresh da região `historico_carreira`. É o padrão oficial (§3). O `hc.preparar` ligado em `apexafterrefresh` re-inicializa a região depois de cada refresh, o uso previsto do evento.
- **p15/p16 Empresas**: DA `apexafterclosedialog` → refresh; na p16, `apex.message.showErrors([{ type: "error", location: "page", message: "CEP não encontrado.", unsafe: false }])`. Como o texto é fixo, `unsafe: false` é seguro. Se um dia vier de API externa, mantenha `unsafe` true ou escape com `apex.util.escapeHTML`.
- **p18 Movimentação**: `apex.item(nome).show()/hide()/setValue('')` e `$x(nome)` para pular itens não renderizados. `hide()` esconde o `<ITEM>_CONTAINER` com o Universal Theme. A doc recomenda `apex.jQuery` em vez do `$` global (o código usa `$('#' + nome + '_CONTAINER')`).
- **p20 Dashboard RH**: condição client-side `$v('P20_DT_INICIO') !== '' && $v('P20_DT_FIM') !== ''`, uso válido de `$v` (item de valor único).
- **p4 Chat**: a ação `preparar-envio` usa **`apex.da.cancelEvent.call(this)`**. Essa função **não aparece** na referência JavaScript do 26.1: `apex.da` documenta só `cancel()`, `resume()` e `handleAjaxErrors()`. A função documentada para parar as ações restantes sem erro é `apex.da.cancel()`. Como `cancelEvent` não é API documentada, pode mudar sem aviso. Teste no 26.1.5 antes de manter e prefira `apex.da.cancel()`, ou a ação declarativa *Cancel Event*. Também vale o registro do `ai-context/08`: a região de mensagens da p4 tem Server-side Condition e não existe no DOM ao carregar, então o refresh por JS não tem alvo (caso "refresh não faz nada" acima).

Fonte: [Namespace: da](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.da.html), [Namespace: server](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.server.html), [Namespace: apex](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.html)

### Regras do projeto aplicadas a JavaScript (multiempresa, autorização, checksum, pt-BR)

1. **Ajax não substitui segurança de servidor.** Todo processo *Ajax Callback* que recebe `x01` (ex.: `ORG_DETALHES` com o id do colaborador) deve validar no PL/SQL se o usuário pode ver aquele registro e **filtrar por `id_empresa`** (`:G_ID_EMPRESA`). O cliente pode mandar qualquer id. O `ai-context/08` já registra que o drawer do organograma não verifica permissão. Crie os callbacks **na página** (a página tem `authorizationScheme`). Callback de aplicação nasce com *Must Not Be Public User*, mas isso não basta para regras de papel (`ADMIN_RH` etc.).
2. **Links e diálogos com checksum** (`ai-context/08` §1 regra 6): não monte `f?p=` com argumentos no JS. Gere no servidor com `apex_page.get_url` e leia de um item, ou use links e botões declarativos. A doc exige URL de diálogo gerada no servidor. `apex.env` serve para URLs sem argumentos protegidos.
3. **HTML injetado** (`innerHTML` com o retorno de `apex.server.process`, como no drawer da p3): o PL/SQL deve escapar dados (`apex_escape`). No cliente, dado não confiável passa por `apex.util.escapeHTML`/`escapeHTMLAttr` ou `htmlBuilder`.
4. **pt-BR**: textos de `apex.message.confirm/alert`, `showErrors` e `showPageSuccess` em português. Para strings reutilizadas, use Text Messages com *Used in JavaScript* + `apex.lang.formatMessage`. O idioma primário técnico da app é `en` (`ai-context/08`, Configuração): `apex.date.format` sem máscara e `apex.locale` seguem a globalização da app. Passe a máscara explícita (`apex.date.format(d, "DD/MM/YYYY")`).
5. **Sem handlers inline**: a doc desaconselha `onclick=` e `javascript:`. Em HTML gerado por região (p4 usa `href="javascript:void(0)"` no template de contatos, conforme `ai-context/03`), prefira `data-*` + handler delegado ou `data-action` com `apex.actions`. O `ai-context/02` cita um `onclick="apex.navigation.redirect(...)"` nos links rápidos da Home, mas não o encontrei no `p00001-início.apx` atual: confira antes de corrigir.
6. **Interactive Grid**: o `ai-context/08` (§3 Páginas) registra que no 26.1.5 a edição de IG só aparece com o bloco `edit { enabled: true }` criado pelo assistente. As opções JS (`editable`, `defaultGridViewOptions`) **não substituem** essa configuração do servidor (o DML continua sendo o processo *Automatic Row Processing*). O padrão do projeto (IR + modal) combina com a receita oficial de `apexafterclosedialog` + refresh (ou `fetchRecords` se a lista for IG).
7. **Passo a passo no Builder**: caminhos como "Advanced > JavaScript Initialization Code" e "User Interface Attributes > JavaScript > File URLs" vêm da doc. Em guias `Etapas-*.md`, marque "(confirmar no 26.1.5)" até conferir na tela (`ai-context/08` §1 regra 11).

Fonte: [Understanding Application Processes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-application-processes.html), [Namespace: navigation](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.navigation.html), [Namespace: util](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.util.html), [Introduction (JavaScript API)](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/index.html)

### Divergências entre a doc oficial e o projeto ou entre livros da doc

| Ponto | Doc 26.1 | Projeto / outra fonte |
|---|---|---|
| `apex.da.cancelEvent` | não documentado (só `cancel`, `resume`, `handleAjaxErrors`) | usado na p4 |
| `apex.message.clearErrors(item)` | referência: `clearErrors()` sem parâmetro | Developer's Companion usa `clearErrors('P5_EMPNO')` |
| `apex.util.getTopApex()` | ausente da página de `apex.util` | usado nos exemplos do Developer's Companion |
| `x01`–`x20`/`f01`–`f20` | `process`/`plugin`: x01–x20 e f01–f20; `url`/`pluginUrl`: x01–x10 | pedidos de "f01..f50" não têm base na referência JS 26.1 |
| `.min` de arquivos | App Builder gera `.min.js` sozinho | `ai-context/08` regra 5 manda manter `.min.css` à mão (vale para CSS) |
| `refresh(pKeepPagination)` | 26.1 só no IR (Developer's Companion) | o parâmetro existe na interface genérica `region` |

Fonte: [Namespace: da](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.da.html), [Namespace: message](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.message.html), [Displaying Messages with JavaScript](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/displaying-messages-javascript.html), [Namespace: server](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.server.html)
