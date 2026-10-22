# 03 · Relatórios, Interactive Grid, Cards, gráficos e visualização

> Base: documentação oficial Oracle APEX 26.1 (App Builder User's Guide: *Developing Reports*, *Managing Application Components* — Charts, Maps, Calendars —, *Managing Application Controls* — Trees —, *Managing Application Legacy Components* — Tabular Forms —; Developer's Companion: *Visualizing and Analyzing Data*, *Editing Data in a Grid*, *Enhancing Search for End-Users*; End User's Guide: *Using Interactive Reports*, *Using Interactive Grids*; trechos do APEXlang API Reference e da JavaScript API Reference para nomes de propriedades e opções do widget). Gerado em 21/10/2026.

Este documento cobre as regiões que **mostram dados em quantidade**: Classic Report, Interactive Report (IR), Interactive Grid (IG, inclusive editável), Cards, Content Row e Template Components usados como relatório, Faceted Search, Smart Filters, Search region, Charts (Oracle JET), Map, Calendar, Tree e Dynamic Content. Fecha com desempenho, uso pelo usuário final, recursos legados, casos de troubleshooting e a aplicação no Corlix Hub.

**Sumário**

1. Escolha do tipo de relatório e fontes de dados
2. Formatação de colunas, escaping e BLOB (comum a todos)
3. Classic Report
4. Interactive Report
5. Interactive Grid (leitura e recursos gerais)
6. Interactive Grid editável (DML, `:APEX$ROW_STATUS`, validações por linha)
7. Customização do Interactive Grid com JavaScript
8. Cards
9. Content Row, Template Components e Order By Item
10. Faceted Search
11. Smart Filters
12. Search region, filtros em outras regiões e Query by Example
13. Charts (Oracle JET)
14. Map, Calendar, Tree e Dynamic Content
15. Impressão e exportação
16. Desempenho de relatórios
17. O que o usuário final consegue fazer (IR e IG)
18. Relatórios legados
19. Problemas conhecidos e troubleshooting
20. Aplicação no Corlix Hub

Documentos relacionados desta pasta: [01 · Conceitos e sessão](./01-conceitos-sessao-e-fluxo.md) (bind variables, substitution strings), [02 · Páginas e formulários](./02-paginas-formularios-e-itens.md) (Form region, Dynamic Actions, master-detail), [04 · Shared Components e tema](./04-componentes-compartilhados-tema-e-plugins.md) (LOVs, templates de relatório, Template Components), [08 · API JavaScript](./08-api-javascript.md) (widget `interactiveGrid`, `apex.model`), [09 · APEXlang](./09-apexlang.md) (sintaxe dos `.apx`), [11 · Dados, REST e PDF](./11-dados-rest-arquivos-e-relatorios-pdf.md) (REST Data Sources, report queries).

---

## 1. Escolha do tipo de relatório e fontes de dados

### Tipos de relatório do APEX 26.1 e quando usar cada um

No APEX, um relatório é o resultado formatado de uma consulta SQL, que você escolhe por tabela/view no assistente ou escreve à mão. Os assistentes (*Create Application Wizard* e *Create Page Wizard*) oferecem seis tipos de página de relatório. Alguns são relatórios "puros" (Classic, IR, IG); outros combinam uma região de busca com uma região de resultado (Faceted Search, Smart Filters).

| Tipo | Use quando | Evite quando |
|---|---|---|
| **Cards** | Quer mostrar dados "de relance" em blocos (com imagem, ícone, badge) e levar o usuário a uma página de detalhe com um clique. Layouts *Grid*, *Float* ou *Horizontal (Row)*. | O usuário precisa ordenar/filtrar livremente por qualquer coluna (Cards não tem ordenação própria: use Order By Item). |
| **Classic Report** | Lista simples, totalmente controlada por template (Standard, Media List, Timeline, Badge List, Value Attribute Pairs…), com ordenação por coluna e paginação. É o mais versátil visualmente. | Precisa de scroll pagination, colunas congeladas, grupos de colunas ou personalização pelo usuário. |
| **Faceted Search** | Filtro estilo e-commerce: região de facets à esquerda e resultados (Classic Report ou Cards) ao lado, com contagem de ocorrências por valor. | Tela estreita ou resultados que precisam da largura toda (prefira Smart Filters). |
| **Interactive Grid** | Grade com edição em linha, seleção de linhas/células, clipboard, colunas congeladas, scroll pagination e personalização salva. | Precisa de altura de linha variável, Pivot, Group By, colunas computadas pelo usuário ou filtros complexos (recursos só do IR); o IG também não lembra a página corrente. |
| **Interactive Report** | Relatório que o usuário personaliza: filtros, highlight, control break, agregações, colunas computadas, gráfico, Group By, Pivot, flashback, download e assinatura por e-mail. | Precisa de scroll pagination, congelar colunas ou grupos de colunas. |
| **Smart Filters** | Mesmo poder de filtro do Faceted Search num único campo de busca no topo, com *suggestion chips*. Resultados como Classic Report, Cards, Map ou Calendar. | O usuário precisa ver todos os facets abertos ao mesmo tempo. |

Para exemplos funcionando, a Oracle recomenda instalar os apps de exemplo **Sample Reporting**, **Sample Cards**, **Sample Interactive Grids**, **Sample Charts**, **Sample Maps** e **Sample Calendar** pela Gallery.

Fonte: [Understanding Report Page Types](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-report-page-types.html), [Developing Reports](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/developing-reports.html)

### Comparação de recursos e limitações entre Classic Report, Interactive Report e Interactive Grid

| Recurso | Classic Report | Interactive Report | Interactive Grid |
|---|---|---|---|
| Fonte | Tabela, SQL, Function Body returning SQL | Tabela, SQL | Tabela, SQL |
| Personalização pelo usuário | Só ordenação e busca simples | Ampla (Actions menu, Column Heading menu) | Ampla + arrastar/redimensionar/congelar colunas |
| Relatórios salvos | Não | Primary, Alternative, Public, Private | Primary, Alternative, Public, Private |
| Edição de dados | Não (só tabular form legado) | Não (use formulário em modal) | Sim, em linha |
| Paginação | Vários estilos, sem scroll | Row ranges, sem scroll | Page ou Scroll (com virtual scrolling se houver total) |
| Group By / Pivot / Compute | Não | Sim | Não |
| Colunas congeladas e grupos de colunas | Não | Não | Sim |
| Download | CSV (link), XML/CSV por template, impressão | CSV, HTML, Excel, PDF, e-mail, assinatura | CSV, HTML, Excel, PDF, e-mail |
| Altura de linha | Livre (template) | Livre | Fixa |
| Lembra a página corrente | Sim | Sim | Não |

Fonte: [Understanding Report Page Types](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-report-page-types.html)

### Criar relatórios: Create Application Wizard, Create Page Wizard e Gallery do Page Designer

Há três caminhos:

1. **Create Application Wizard** → *Add Page* → escolha Cards, Faceted Search, Smart Filters, Interactive Grid, Interactive Report ou Classic Report (os tipos menos comuns ficam em *Additional Pages*).
2. **Create Page Wizard** (*Create Page* na home da aplicação, ou menu *Create › Page* no Page Designer) → aba *Component* → tipo de relatório. Pede *Page Number*, *Name* (vira o título da página), *Page Mode* (normal ou modal), *Include Form Page* (gera um formulário modal junto; o formulário é **sempre** modal), *Data Source*, *Source Type* (Table ou SQL Query) e *Navigation* (*Use Breadcrumb*, *Use Navigation*).
3. **Gallery** do Page Designer: arraste o tipo de região para o Layout, ou clique com o botão direito › *Add To*. Nesse caminho você precisa informar a fonte (SQL ou tabela) depois; o Page Designer marca os erros pendentes no ícone *Show Messages*.

Comportamentos automáticos importantes dos assistentes:
- **Colunas BLOB**: em IR e Classic Report sobre tabela local com PK, viram *Download BLOB* já configuradas. Em IG são **excluídas** da fonte, porque o IG não suporta BLOB.
- **Chaves estrangeiras** (tabela local): em IR e Classic Report a coluna vira *Plain Text (based on List of Values)*; em IG vira *Select List*. Se já existir LOV compatível, ela é reaproveitada; senão, uma Shared LOV é criada.
- **IG**: a opção *Editing Enabled* liga a edição na própria grade.

Fonte: [Creating a Report Using the Create Page Wizard](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-report-create-page-wizard.html), [Creating a Report by Dragging and Dropping from the Gallery](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-a-report-by-dragging-and-dropping-from-gallery.html), [Creating an Interactive Grid Using the Create Page Wizard](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-an-interactive-grid-using-the-create-page-wizard.html)

### Fontes de dados de relatórios: Local Database, REST Enabled SQL, REST Source, Duality View, JSON Source e Sample Data

O atributo *Source > Location* da região (APEXlang `source.location`) define de onde vêm os dados:

| Location (UI) | APEXlang | Uso |
|---|---|---|
| Local Database | `localDatabase` (padrão) | Tabelas/views do schema da aplicação. |
| REST Enabled SQL | `restEnabledSql` | Banco remoto via REST Enabled SQL (Shared Components › REST Enabled SQL Databases). |
| REST Source | `restSource` | REST Data Source (Shared Components › REST Data Sources). |
| Duality View | `jsonDualityView` | Duality View Source. |
| JSON Source | `jsonSource` | Tabelas com colunas JSON ou JSON Collection Tables. |
| Sample Data | `sampleData` (`employees`, `tasks`, `products`, `projects`) | Conjunto de exemplo embutido, para protótipo. |

Para Local Database/REST Enabled SQL, *Source > Type* pode ser **Table/View** (com `tableName`, `whereClause` opcional e, em IG/IR/Map/Form, `orderByClause`), **SQL Query** ou **Function Body returning SQL Query** (PL/SQL ou JavaScript MLE). O Classic Report é o único relatório tabular que aceita Function Body returning SQL; com ele você pode usar *Generic Column Names* (`useGenericColumnNames`, `genericColumnCount` até 999). Outras propriedades da fonte: `pageItemsToSubmit` e `optimizerHint`.

Para REST Enabled SQL existe cache remoto (`remoteCache.caching`: `allUsers`, `user` ou `session`, com `timeout`).

Fonte: [Creating an Interactive Report Using the Create Page Wizard](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-an-interactive-report-using-the-create-page-wizard.html), [APEXlang API Reference — region](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Page Items to Submit: bind variables em fontes de relatório que são atualizadas por AJAX

Quando o `WHERE` ou a query de uma região referencia itens de página como bind variables (`:P1_DEPTNO`), **liste esses itens em *Page Items to Submit*** da região (sem os dois-pontos, separados por vírgula; no APEXlang, `source.pageItemsToSubmit: [ P1_DEPTNO ]`). Num refresh por AJAX (dynamic action *Refresh*, paginação, filtro), o APEX envia ao servidor o valor atual desses itens no navegador antes de executar a query. Sem isso, o servidor usa o valor que está em session state, normalmente `null`, e a consulta volta vazia.

Isso vale para **qualquer** tipo de região (Classic Report, Cards, Chart — onde fica na *série* —, Calendar, Dynamic Content, Map etc.).

```sql
-- Região filtrada por um select list de departamento, opcional
select empno, ename, sal
  from emp
 where (:P5_SELECTED_DEPARTMENT is null
        or deptno = :P5_SELECTED_DEPARTMENT)
-- Page Items to Submit: P5_SELECTED_DEPARTMENT
```

Fonte: [Visualizing and Analyzing Data](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/visualizing-and-analyzing-data.html), [Filtering on a Page Item's Value](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/filtering-page-items-value.html)

### Atualizar relatórios com a dynamic action Refresh

Qualquer região de dados pode ser recarregada pela ação **Refresh** de uma dynamic action (ex.: evento *Change* de um select list → *Refresh* da região). Combine sempre com *Page Items to Submit* (seção anterior). Para manter duas regiões sincronizadas, dispare o refresh da região-alvo a partir do evento de "fim de atualização" da região-fonte: **After Refresh** para Classic Report e **Page Change (Cards)** para Cards.

Fonte: [Visualizing and Analyzing Data](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/visualizing-and-analyzing-data.html), [Refreshing the Target Region](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/refreshing-target-region.html)

---

## 2. Formatação de colunas, escaping e BLOB

### HTML Expression em colunas de relatório: sintaxe #COLUNA# e &COLUNA.

A *HTML Expression* (grupo *Column Formatting*) permite montar o HTML de uma célula misturando tags, valores de colunas (inclusive colunas **Hidden**) e template directives.

- Em **Classic Report** e **Interactive Report** as colunas são referenciadas como `#NOME_COLUNA#`.
- Em **Interactive Grid**, **Cards**, **Content Row**, Calendar, Map e Template Components a sintaxe é `&NOME_COLUNA.`.
- Coluna com identificador entre aspas (case-sensitive): `#"Mixed Case Name"#`.

Exemplos (IR/Classic):

```html
<span style="background-color: yellow; color: red;">#EMPLOYEE_STATUS#</span>
<span class="#COLUMN_CLASS#">#EMPLOYEE_STATUS#</span>            <!-- classe vinda do SQL -->
<img src="#IMAGE_NAME#" alt="#EMPLOYEE_NAME#" title="#EMPLOYEE_NAME#">
<ul>{loop "," TAGS/}<li>&APEX$ITEM.</li>{endloop/}</ul>        <!-- lista separada por vírgula -->
{if Mixed Case Name/}<strong>#"Mixed Case Name"#</strong>{endif/}
```

Quando usar: formatação condicional e composição de várias colunas numa célula. Quando não usar: para montar links clicáveis que o usuário vai filtrar no IR (ver o caso "Filtro no cabeçalho de coluna falha quando o link é montado no SQL", §19).

Fonte: [Managing Interactive Report Column Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-interactive-report-column-attributes.html), [Listing Data with Classic Reports](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/listing-data-classic-reports.html)

### Escape Special Characters e filtros de escape (!HTML, !ATTR, !JS, !RAW, !STRIPHTML)

Toda coluna de relatório tem *Security > Escape Special Characters* (APEXlang `security.escapeSpecialChars`, padrão `true`). Com ele ligado, o APEX escapa `<`, `>`, `&`, aspas etc. ao exibir o valor, o que impede Cross Site Scripting (XSS). **Mantenha ligado.** Desligue só para colunas cujo HTML vem de fonte confiável e já sanitizada; para HTML formatado prefira o tipo de coluna **Rich Text** (renderiza HTML ou Markdown) ou **Remove HTML** (tira as tags e escapa).

Para controle fino numa substituição, acrescente `!FILTRO` ao nome:

| Filtro | Efeito | IG / Cards (`&COL.`) | IR / Classic (`#COL#`) |
|---|---|---|---|
| `HTML` | Escapa caracteres reservados de HTML | `&ENAME!HTML.` | `#ENAME!HTML#` |
| `ATTR` | Escapa para contexto de atributo HTML | `&ENAME!ATTR.` | `#ENAME!ATTR#` |
| `JS` | Escapa para contexto JavaScript (não funciona em substituições feitas no cliente) | `&ENAME!JS.` | `#ENAME!JS#` |
| `RAW` | Não escapa nada | `&ENAME!RAW.` | `#ENAME!RAW#` |
| `STRIPHTML` | Remove tags e escapa o resto | `&ENAME!STRIPHTML.` | `#ENAME!STRIPHTML#` |

Exemplo da documentação: na técnica de "Dica de IR com link condicional" a Oracle manda **manter** *Escape Special Characters* ligado na coluna HTML Expression. E no Calendar, a Oracle explica que você não pode simplesmente colocar tags no título do evento porque o APEX as escapa por segurança; a solução é marcar o texto e convertê-lo em HTML no `eventContent` do JavaScript Initialization Code (§14).

Fonte: [Controlling Output Escaping in Substitution Strings](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/controlling-output-escaping-in-substitution-strings.html), [Supported Columns in Interactive Reports](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/supported-columns-in-interactive-reports.html), [Enhancing Event Display](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/enhancing-event-display.html)

### Template directives em relatórios: {if}, {loop}, {with/}{apply} e Template Components em colunas

Template directives são tokens que controlam o texto ao redor: `{if COLUNA/}…{else/}…{endif/}`, `{loop "sep" COLUNA/}…&APEX$ITEM.…{endloop/}` e `{with/} ATTR := valor {apply NOME_COMPONENTE/}`. Funcionam em HTML Expressions de colunas (IR, Classic, IG), em Cards, Content Row e Template Components, e são avaliadas **no cliente** para formatação condicional.

Exemplo de formatação condicional (Cards/Content Row):

```text
Compensation: &SAL. {if COMM/} + &COMM. commission = &TOTAL_COMP.{endif/}
```

Exemplo de Template Component dentro de uma coluna HTML Expression do IG (aplica o componente `PERCENT_DOT_ON_BAR` passando dois atributos):

```text
{with/}
    LABEL   := &SAL.
    PERCENT := &PERCENT.
{apply PERCENT_DOT_ON_BAR/}
```

Fonte: [Getting to Know the Interactive Grid](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/getting-know-interactive-grid.html), [Info Tiles Using Cards](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/info-tiles-using-cards.html)

### BLOB em relatórios: Download BLOB e Display Image

Classic Report e IR mostram colunas BLOB como `[unsupported data type]`. Para oferecer download ou imagem:

1. Se a fonte é *Table/View*, mude para *SQL Query* (o APEX gera a query equivalente).
2. Acrescente uma coluna **numérica**, normalmente o tamanho do arquivo: `sys.dbms_lob.getlength(blob_col) as download`. Se o tamanho for 0 (BLOB nulo), não aparece link/imagem.
3. Mude o tipo dessa coluna para **Download BLOB** (link) ou **Display Image** (imagem).
4. Em *BLOB Attributes*: *Table Name*, *BLOB Column*, *Primary Key Column(s)* (se a PK tiver mais de duas colunas, use `ROWID`), e opcionais *Mime Type Column*, *Filename Column*, *Last Updated Column* (deve refletir a alteração do arquivo, não de outras colunas) e *Character Set Column*.
5. Download BLOB: *Appearance > Download Text* e *Content Disposition* (`Attachment` força download; `Inline` tenta abrir no navegador).
6. Display Image: preencha *Accessibility > Image Description* (vira o `alt`). A imagem sai no tamanho original; para limitar, dê um *HTML DOM ID* à coluna e use CSS, por exemplo `td[headers="my_report_image_column"] img { height: 25px; }`.

Alternativa procedural: `APEX_UTIL.GET_BLOB_FILE_SRC`, que permite formatar a imagem com mais controle, mas só funciona dentro de uma sessão APEX válida e exige que os parâmetros do BLOB estejam definidos num item da aplicação. Para baixar arquivos há também processos nativos e plug-ins de dynamic action.

Os assistentes **não** incluem a coluna BLOB na definição do relatório (exceto o caso de IR/Classic sobre tabela com PK, que já vem como Download BLOB). O IG não suporta BLOB.

Fonte: [Understanding BLOB Support in Forms and Reports](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-blob-support-in-forms-and-reports.html)

---

## 3. Classic Report

### Classic Report: o que é, quando usar e atributos principais

O Classic Report exibe o resultado de uma consulta formatado por um **report template** do tema. O usuário final só ordena colunas e faz busca simples; todo o resto é decisão do desenvolvedor. Aceita Table/View, SQL Query e Function Body returning SQL Query. Pode incluir um formulário de edição (*Include Form Page*).

Use quando: a aparência importa mais que a personalização (timelines, listas de mídia, comentários, pares chave-valor), ou o relatório é pequeno e fixo. Não use quando: o usuário precisa salvar filtros, exportar em vários formatos ou rolar milhares de linhas.

Três grupos de atributos: **Region** (fonte, layout, condição), **Attributes** (template, paginação, download, break formatting) e **Column** (tipo, cabeçalho, ordenação, link).

Fonte: [Managing Classic Reports](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-classic-reports.html), [Example Classic Report](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/example-classic-report.html)

### Classic Report: tipos de coluna suportados

| Tipo | Descrição |
|---|---|
| Plain Text | Mostra o valor (aceita HTML Expression). |
| Plain Text (based on List of Values) | Mostra o *display value* de uma LOV para o valor da coluna (dispensa JOIN). |
| Rich Text | Renderiza HTML ou Markdown. |
| Link | Coluna como link (Link Builder). |
| Display Image | Imagem a partir de BLOB. |
| Download BLOB | Link de download de BLOB. |
| Percent Graph | Barra de porcentagem; o valor precisa estar entre 0 e 100. |
| Hidden | Não aparece, mas pode ser referenciada (`#COL#`). |

Fonte: [Supported Columns in Classic Reports](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/supported-columns-in-classic-reports.html)

### Classic Report: report templates do Universal Theme e Template Options

Em *Attributes > Appearance*:

- **Template Type**: `Theme` (template do tema) ou `Predefined` (`html`, `verticalReport`, `csv`, `xml`).
- **Template**: templates do Universal Theme — *Alerts*, *Badge List*, *Cards*, *Comments*, *Content Row* (linhas com coluna de seleção, ícones e ações), *Contextual Info* (pares chave-valor em sequência, usando cabeçalhos como rótulos), *Media List*, *Search Results*, *Standard* (tabela, padrão), *Timeline*, *Value Attribute Pairs - Column* e *Value Attribute Pairs - Row* (primeira coluna é o rótulo, segunda o valor).
- **Template Options**: variações visuais; também ajustáveis em tempo real pelas *Live Template Options*.
- **CSS Classes**: só têm efeito se o template contém `#COMPONENT_CSS_CLASSES#`.
- **Show Null Values as**: texto para nulos.
- **Custom Attributes** (`customAttributes`): substitui `#REPORT_ATTRIBUTES#`, que só é trocado no *Before Rows* do template.

**Pegadinha:** templates "row based" (Cards, Search Results, Media List etc.) esperam **aliases de coluna específicos** na sua query, que são substituídos no template. Você precisa renomear as colunas do SELECT para os nomes que o template usa. Para algo que nenhum template atende, crie um template de relatório próprio (inclusive *named column templates*).

Fonte: [Managing Classic Report Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-classic-report-attributes.html)

### Classic Report: paginação e Partial Page Refresh

*Attributes > Pagination*:

- **Type** (APEXlang `pagination.type`): `rowRangesXToYNoPagination`, `rowRangesXToYOfZNoPagination`, `rowRangesXToYOfZWithPagination`, `setPaginationLinks`, `setPaginationSelectList`, `setPaginationSearchEngine`, `externalPaginationButtons`, `nextAndPreviousLinks`. Os estilos "of Z" precisam contar o total de linhas.
- **Display Position**: `bottomLeft`, `bottomRight` (padrão), `topLeft`, `topRight`, `topAndBottomLeft`, `topAndBottomRight`.
- **Partial Page Refresh** (padrão ligado): ao paginar ou ordenar, recarrega só a região; desligado, recarrega a página inteira. Lazy Loading do Classic Report exige PPR ligado.

O Classic Report **não** tem scroll pagination nem virtual scrolling. Se o número de linhas é pequeno e estável, pode mostrar tudo de uma vez.

Fonte: [Managing Classic Report Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-classic-report-attributes.html), [Listing Data with Classic Reports](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/listing-data-classic-reports.html)

### Classic Report: ordenação de colunas (Sortable e Default Sequence)

Em cada coluna, grupo *Sorting*: **Sortable** (On permite ao usuário ordenar por ela) e **Default Sequence** (ordem padrão). Dê a cada coluna uma sequência **única**; ao menos uma coluna precisa ter sequência definida. A ordenação também precisa estar ligada para que nulos possam ir para o início ou o fim (atributo *Sort Nulls*).

Edições comuns de coluna: esconder (*Type = Hidden*), mudar cabeçalho e alinhamento (*Heading*), mudar ordem (*Layout > Sequence*), somar a coluna (*Advanced > Compute Sum*).

Fonte: [Managing Classic Report Column Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-classic-report-column-attributes.html)

### Classic Report: break formatting e soma de colunas

*Attributes > Break Formatting* controla se uma coluna se repete e como as quebras aparecem: **Break Columns** (quantas colunas, contíguas a partir da primeira, entram na quebra) e **Report Sum Label** (texto ao lado das somas). Exemplo: num relatório de empregados por departamento, o número do departamento aparece uma vez por grupo. O APEXlang tem ainda `breakFormatting.style` (`default` ou `repeatHeadings`) e `repeatHeadingFormat`. Soma por coluna: *Advanced > Compute Sum*.

Fonte: [Managing Classic Report Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-classic-report-attributes.html)

### Classic Report: download CSV e exportação por template XML/CSV

Duas formas:

1. **Link de CSV**: *Attributes > Download > CSV Export Enabled* = On, com um template que contenha `#CSV_LINK#`. Configure *CSV Separator* (vazio = vírgula ou ponto e vírgula conforme NLS), *CSV Enclosed By* (padrão aspas duplas), *Link Text* e *Filename* (sem extensão; vazio = nome da região). É preciso ativar **Automatic CSV Encoding** nos atributos de Globalização da aplicação.
2. **Template predefinido**: *Template Type = Predefined*, *Template = XML* ou *CSV*. Com XML, o APEX não renderiza a página e devolve o conteúdo como arquivo XML.

**Não use *Supplemental Text* com CSV**: o texto extra no topo invalida o formato CSV.

Fonte: [Managing Classic Report Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-classic-report-attributes.html), [Managing Classic Report Column Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-classic-report-column-attributes.html)

### Links de coluna em relatórios: Link Builder, Set Items e Clear/Reset

Em Classic Report, IR e IG: coluna com *Type = Link* → *Link > Target* → **Link Builder - Target**:

- **Type**: *Page in this Application*, *Page in a different Application* (exige Deep Linking no app de destino) ou *URL*.
- **Page**, **Set Items** (nome = valor; o valor pode ser `#COL#`/`&COL.`, item `&P2_ID.` ou literal).
- **Clear/Reset > Clear Cache**: páginas (lista separada por vírgula) cujo cache será limpo; aceita também `RP`, `CR`, `RR` para relatórios.
- **Clear/Reset > Action**: *None*, *Clear Regions* (limpa as configurações das regiões da página), *Reset Regions* (volta ao estado padrão, inclusive ordenação e colunas ocultas), *Reset Pagination* (compatibilidade).
- **Advanced > Request**.

No IG existem ainda `linkText` e `linkAttributes`. Prefira sempre o Link Builder a montar a URL `f?p=` à mão dentro do SQL.

Fonte: [Managing Classic Report Column Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-classic-report-column-attributes.html), [Managing Interactive Grid Column Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-interactive-grid-column-attributes.html)

### Classic Report: coluna exibida por LOV, colunas condicionais e colunas atualizáveis

- **Plain Text (based on List of Values)**: em *List of Values > Type* escolha *Shared Component*, *SQL Query*, *Static Values* ou *PL/SQL Function Body returning SQL Query*. Mostra o texto amigável de uma FK sem JOIN.
- **Colunas condicionais**: *Security > Authorization Scheme* e *Server-side Condition*. A coluna aparece só se a autorização passar **e** a condição for verdadeira.
- **Colunas atualizáveis** (legado): só funcionam se houver processo de multirow update, um processo PL/SQL que trate os dados e, com elementos de tabular form nativos, se a fonte for do tipo SQL Query (updatable report). Para novas telas, use IG.

Fonte: [Managing Classic Report Column Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-classic-report-column-attributes.html)

### Classic Report em APEXlang: exemplo comentado

~~~text
region equipes (
    name: Equipes
    type: classicReport
    source {
        location: localDatabase
        type: sqlQuery
        sqlQuery:
            ```sql
            select id_equipe, nome, ds_equipe
              from equipe
             where id_empresa = :G_ID_EMPRESA
            ```
        pageItemsToSubmit: [ P26_BUSCA ]          // itens usados como bind
    }
    componentAppearance {
        templateType: theme
        template: @/standard                     // ou Content Row, Media List...
        showNullValuesAs: -
    }
    pagination {
        type: rowRangesXToYOfZWithPagination
        partialPageRefresh: true
        displayPosition: bottomRight
    }
    performance {
        maxRowsToProcess: 500
        lazyLoading: false
    }
    messages {
        whenNoDataFound: Nenhuma equipe cadastrada.
    }
)
~~~

Os nomes dos grupos e propriedades vêm do APEXlang API Reference (`componentAppearance`, `pagination`, `performance`, `messages`, `download`, `breakFormatting`). Confira a sintaxe exata no [09 · APEXlang](./09-apexlang.md) antes de editar.

Fonte: [APEXlang API Reference — region](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

---

## 4. Interactive Report

### Interactive Report: o que é, quando usar e limitações

O IR é o resultado formatado de uma consulta que o **usuário final** personaliza: esconde e reordena colunas, filtra, destaca, ordena, cria quebras, agregações, colunas computadas, gráfico, Group By e Pivot, consulta flashback, baixa e assina por e-mail, e salva tudo como relatório privado ou público. Por padrão tem barra de busca, Actions menu, menus de cabeçalho de coluna e um ícone de edição/visualização na primeira coluna. Pode haver vários IRs na mesma página. O IR é suportado só em aplicações Desktop.

Use quando: listas operacionais que cada usuário quer ver do seu jeito, relatórios com exportação, a "lista" do padrão lista + formulário modal. Limitações: sem scroll pagination, sem congelar colunas, sem grupos de colunas e gráfico menos poderoso que o do IG.

O desenvolvedor pode restringir recursos (por exemplo, desligar download ou a possibilidade de esconder colunas); o comportamento, para o usuário, é o mesmo em todos os IRs da aplicação.

Fonte: [Example Interactive Report](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/example-interactive-report.html), [Personalizable Interactive Reports](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/personalizable-interactive-reports.html)

### Interactive Report: tipos de coluna (Built-in e Theme Components)

| Tipo | Descrição | Categoria |
|---|---|---|
| Display Image | Imagem (BLOB) | Built-in |
| Download BLOB | Link de download | Built-in |
| Hidden | Não exibe, mas pode ser referenciada | Built-in |
| Link | Link | Built-in |
| Percent Graph | Barra 0–100 | Built-in |
| Plain Text | Valor | Built-in |
| Plain Text (based on List of Values) | Display value de uma LOV | Built-in |
| Remove HTML | Remove tags e escapa | Built-in |
| Rich Text | HTML ou Markdown | — |
| Row Selector | Seleção de linha única ou múltipla; não tem coluna-fonte; só uma por relatório, sempre no início da linha | Built-in |
| Avatar, Badge, Comments, Content Row, Media List, Timeline | Template Components do Universal Theme (instalados nos Shared Components) usados como *partial* da coluna | Theme Components |

Fonte: [Supported Columns in Interactive Reports](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/supported-columns-in-interactive-reports.html)

### Interactive Report: atributos de coluna (Heading, Layout, Accessibility, Enable Users To)

Atributos de coluna mais usados:

- **Heading**: *Heading*, *Alternative Label* (usado em diálogos e quando o cabeçalho tem HTML), *Alignment* (`start`, `center`, `end`, desde que o template suporte).
- **Single Row View > Use Column Heading**: usa o cabeçalho como rótulo na visão de linha única.
- **List of Values**: LOV para exibição.
- **Layout**: *Sequence*, *Column Alignment*, *Group* (agrupa colunas na Single Row View).
- **Accessibility > Value Identifies Row**: colunas que identificam a linha para leitores de tela (ex.: nome e sobrenome).
- **Appearance > CSS Classes**: classes aplicadas a cada célula (ex.: `u-bold u-color-13`); *Format Mask*.
- **Enable Users To**: On/Off por recurso (ordenar, esconder, filtrar, control break, agregar, computar, gráfico, group by, pivot).
- **Column Filter > Type**: *None*; *Default Based on Column Type* (STRING/NUMBER usam valores distintos, DATE usa faixas pré-definidas); *Use Defined List of Values to Filter Exact Match* / *Word Contains*; *Use Named List of Values to Filter Exact Match* / *Word Contains*. Definir uma LOV acelera os filtros do cabeçalho.
- **Advanced > endUserAlias** (APEXlang, uma ou duas letras maiúsculas): o alias da coluna. As expressões que o usuário escreve em *Compute* e em filtros de linha usam esses aliases (ex.: `I - H`).

Fonte: [Managing Interactive Report Column Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-interactive-report-column-attributes.html)

### Interactive Report: seleção de linhas com Row Selector e Current Selection Page Item

Para operações em lote (aprovar várias linhas, por exemplo), mude o tipo de uma coluna para **Row Selector** e configure *Row Selection*:

- **Enable Multi Select**: permite várias linhas.
- **Show Select All**: caixa "selecionar tudo" no cabeçalho e atalho Ctrl+A.
- **Hide Control**: esconde o checkbox/radio de cada linha.
- **Current Selection Page Item**: item de página que guarda as **chaves primárias** das linhas selecionadas, separadas por dois-pontos.

Dynamic actions ou processos podem agir sobre a seleção; ela também é acessível pela API JavaScript `interactiveReportRegion` e pode ser copiada com Ctrl+C / Command+C.

```sql
-- Processo que aprova as linhas selecionadas (P5_SELECIONADOS = Current Selection Page Item)
update solicitacao
   set status = 'APROVADA'
 where id in (select to_number(column_value)
                from apex_string.split(:P5_SELECIONADOS, ':'));
```

Fonte: [Managing Interactive Report Column Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-interactive-report-column-attributes.html), [Filtering on a Multi-Selection Page Item](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/filtering-multi-selection-page-item.html)

### Interactive Report: Link Column (Single Row View, Custom Target, Exclude)

A *Link Column* é a coluna de ícone à esquerda de cada linha (*Attributes > Link*). O usuário não pode ordenar, esconder nem mover essa coluna, e ela é independente dos links de coluna comuns.

- **Link to Single Row View**: abre a visão de linha única. *Uniquely Identify Rows by*: `ROWID` ou *Unique Column*. *Link Icon*, *Link Attributes* (atributos extras no `<a>`), *Authorization Scheme* e *Condition Type* para a coluna aparecer. Em *Single Row View*: *Exclude Null Values* e *Only Displayed Columns* (Off pode mostrar colunas ocultas).
- **Link to Custom Target**: Link Builder para página ou URL; *Link Icon* aceita HTML (ex.: `<span class="fa fa-edit"></span>`).
- **Exclude Link Column**: sem a coluna.

Acessibilidade: se o ícone da Single Row View não tiver `alt`, o APEX coloca `alt="Single Row View"`; melhor ainda é um `alt` específico da linha, como `alt="View Row: #ENAME#"`.

Fonte: [Managing Link Columns](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-link-columns.html)

### Interactive Report: barra de busca (Search Bar) e Actions menu

**Search Bar** (*Attributes > Search Bar*): *Include Search Bar*, *Search Field*, *Finder Drop Down* ("Select columns to search", restringe a busca a uma coluna), *Reports Select List* (só aparece se houver relatório além do primário acessível ao usuário), *Rows Per Page Selector* (não ligue junto com *Actions Menu > Rows Per Page*) e *Search Button Label*. Se houver várias views configuradas, aparece um grupo de botões para alternar.

**Actions Menu** (*Attributes > Actions Menu*), todos On/Off (padrões do APEXlang entre parênteses):

| Opção | Efeito |
|---|---|
| Include Actions Menu (on) | Mostra o menu |
| Filter, Select Columns, Rows Per Page, Sort, Control Break, Highlight, Compute, Aggregate, Chart, Group By, Pivot, Flashback (todos on) | Libera cada recurso |
| Save Report (on) | Salvar relatório **privado** (só usuários autenticados) |
| Save Public Report (off) | Salvar relatório **público** (só autenticados) |
| Save Public Report Authorization | Authorization que restringe quem salva público; vazio = qualquer um |
| Reset (on) | Desfaz personalizações e volta ao Primary |
| Help (on) | Diálogo de ajuda com as opções disponíveis ao usuário |
| Subscription (on) | Assinatura por e-mail |
| Download (on) | Menu Download |

A estrutura do Actions menu mudou na 5.1 para ficar igual à do IG; para voltar à estrutura antiga use *Shared Components > Component Settings > Interactive Report*.

Fonte: [Customizing an Interactive Report Search Bar](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/customizing-an-interactive-report-search-bar.html), [Customizing the Interactive Report Actions Menu](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/customizing-the-interactive-report-actions-menu.html)

### Interactive Report: download (CSV, HTML, Excel, PDF) e envio por e-mail

Pré-requisitos: *Search Bar > Include Search Bar* = On e *Actions Menu > Download* = On. Depois, em *Download*:

- **Authorization**: quem pode baixar (vazio = todos).
- **Download Formats**: CSV, HTML, Excel, PDF (padrão: os quatro). Desligar *Download* esconde o menu, mas **para impedir download de verdade desmarque todos os formatos**. Alguns formatos dependem do servidor de impressão configurado na instância.
- **Send as Email**: anexa o download a um e-mail. Só para usuários autenticados (em página pública a opção não aparece) e exige SMTP configurado pelo administrador da instância. Suporta todos os formatos exceto Word (RTF). O e-mail leva uma assinatura gerada pelo sistema que não pode ser removida.
- **CSV Separator** e **CSV Enclosed By**; CSV exige *Automatic CSV Encoding* ligado na Globalização.
- **Filename** (sem extensão) e **Supplemental Text** (texto no topo; **não use com CSV**).

O Pivot não baixa em PDF. Downloads de conjuntos grandes podem demorar bastante.

**E-mail From**: defina em *Advanced > Email From Address* (no relatório) ou em *Application Email From Address* (aplicação). Aceita literal, substituição estática de aplicação ou `&APP_EMAIL.`. Substituição de item de página/aplicação **não** é recomendada: funciona no download por e-mail, mas não nas assinaturas.

Fonte: [Configuring Interactive Report Download Options](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-interactive-report-download-options.html), [Configuring Advanced Attributes for Interactive Reports](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-advanced-attributes-for-interactive-reports.html)

### Interactive Report: paginação, Maximum Rows to Display e Maximum Rows to Process

*Attributes > Pagination*:

- **Type**: `rowRangesXToYOfZ` ou `rowRangesXToY` (sem total; mais barato).
- **Display Position**: acima/abaixo, à esquerda/direita.
- **Maximum Rows to Display**: máximo de linhas exibidas **depois** de aplicadas as configurações do relatório.

Em *Performance*, **Maximum Rows to Process** (`maxRowsToProcess`) limita as linhas lidas da query; no IR só vale quando *Maximum Rows to Display* está vazio. *Messages > When More Data Found* é exibida quando a query passa de *Maximum Rows to Process* ou quando as linhas restantes passam de *Maximum Rows to Display* (neste caso, só se o tamanho da página for "All").

*Heading > Fixed To* (`none`, `region`, `page` — padrão `page`) fixa o cabeçalho; com `region`, defina *Maximum Report Height*.

Fonte: [Controlling Interactive Report Pagination](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/controlling-interactive-report-pagination.html), [APEXlang API Reference — region](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Interactive Report: Icon View e Detail View

- **Icon View** (*Attributes > Icon View*): *Show* = On adiciona o botão "View Icons" na barra. Modo simples: *Columns Per Row*, *Link Column* (destino), *Image Source Column*, *Label Column*, *Image Attributes*, *HTML Alt/Title Text*. Modo *Custom* = On: *Custom Link* com HTML livre usando substituições, por exemplo `<a href="#EMP_LINK#"><img src="#EMP_IMG#" title="#ENAME#" alt=""><br>#ENAME#</a>`. Boa prática: deixe as colunas de ícone/rótulo/link como Hidden.
- **Detail View** (*Attributes > Detail View*): *Show* = On adiciona "View Details". *Before Rows*, *For Each Row* (com `#COLUNA#` e `#COLUNA_LABEL#`) e *After Rows*.

```html
<!-- For Each Row do Detail View -->
<tr><td class="u-textRight">#ENAME_LABEL#:</td><td>#ENAME#</td></tr>
<tr><td class="u-textRight">#JOB_LABEL#:</td><td>#JOB#</td></tr>
```

Fonte: [Enabling Icon View](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/enabling-icon-view.html), [Enabling Detail View](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/enabling-detail-view.html)

### Interactive Report: atributos Advanced (Region Alias, Report ID Item, Oracle Text Index Column)

*Attributes > Advanced*:

- **Region Alias**: alias alfanumérico único na aplicação. Use-o em APIs no lugar do `INTERACTIVE_REPORT_ID`, que muda entre instâncias no export/import. Ex.: buscar o ID consultando a coluna `ALIAS` da view `APEX_APPLICATION_PAGE_IR`.
- **Report ID Item**: item de página/aplicação cujo valor guarda o ID do relatório salvo a abrir. Os IDs ficam em `APEX_APPLICATION_PAGE_IR_RPT`. Útil para uma lista de links para relatórios salvos.
- **Email From Address**: ver download.
- **Oracle Text Index Column**: coluna com índice Oracle Text; a busca de linha passa a aceitar operadores do Oracle Text. Ligue só se o índice existir e os usuários souberem usar os operadores; para simplificar, configure *Oracle Text PL/SQL Function Name* nos Component Settings.

Fonte: [Configuring Advanced Attributes for Interactive Reports](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-advanced-attributes-for-interactive-reports.html)

### Interactive Report: relatórios salvos Primary, Alternative, Public e Private

| Tipo | Quem cria | Quem vê | Renomear/excluir |
|---|---|---|---|
| **Primary Default** | Desenvolvedor | Todos; é o que abre por padrão | Não pode ser renomeado nem excluído |
| **Alternative Default** | Desenvolvedor | Todos, na lista de relatórios | Só desenvolvedor |
| **Public** | Usuário ou desenvolvedor (se *Save Public Report* ligado) | Todos | Só o criador; outros podem salvar uma cópia com outro nome |
| **Private** | Qualquer usuário autenticado | Só o criador | Só o criador |

Para os usuários conseguirem salvar: a aplicação precisa de **authentication scheme**; ligue *Search Bar > Reports Select List*, *Actions Menu > Save Report* e, para públicos, *Save Public Report* (+ authorization opcional).

Como desenvolvedor: rode a página, personalize e use *Actions > Report > Save Report* → *As Default Report Settings* → *Primary* ou *Alternative* (com nome). Para um relatório nomeado: *As Named Report*, com *Public* se quiser. Os relatórios aparecem no Page Designer sob *Saved Reports* (no APEXlang, `savedReport primary ( displayColumn … sort … )`).

**Export**: o export da aplicação leva Primary, Alternative e públicos por padrão; os atributos *Export Public Reports* e *Export Private Reports* controlam o que entra. Gestão em massa dos relatórios salvos fica na Administração do workspace.

Fonte: [Customizing Interactive Reports in a Running Application](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/customizing-interactive-reports-as-an-end-user.html)

### Interactive Report: links com filtros na URL (Request, itemNames e ClearCache)

As configurações passadas pela URL alteram só o relatório **de trabalho** do usuário, nunca os relatórios salvos.

**Abrir um relatório salvo** (parte *Request* da URL): `IR[<HTML DOM ID da região>]_<alias>`, por exemplo `IR[EMP]_dept20`. Vários relatórios: separe por vírgula. Primary: `IR_PRIMARY`.

**Criar filtro** (parte *itemNames/itemValues*): `IR[<DOM ID>]<operador>_<alias da coluna>` = valor, por exemplo `IR[EMP]C_ENAME:KING`. Sem operador = igualdade. Com um único IR na página, o `[DOM ID]` é dispensável. `ROWFILTER` como alias cria um filtro "Row Text Contains" em todas as colunas STRING/NUMBER exibidas: `IR[EMP]_ROWFILTER:SALES`.

Operadores: `C` (contains), `EQ` (padrão), `GTE`, `GT`, `LIKE`, `LT`, `LTE`, `N` (null), `NC` (not contains), `NEQ`, `NLIKE`, `NN` (not null), `IN` e `NIN` (lista separada por vírgula, envolta em `\`…`\`), `ROWFILTER`.

**ClearCache**: `RR` reseta relatório e paginação (= *Reset* do Actions menu); `CR` limpa todas as configurações de sessão (control break, agregação, flashback, gráfico, linhas por página, filtro, highlight, computação, group by, pivot) e reseta paginação; `RP` reseta só a paginação. Sem relatório no *Request*, o ClearCache age no Primary; com vários IRs, qualifique pelo DOM ID.

```text
f?p=&APP_ID.:2:&SESSION.::::IR[EMP]_ENAME:KING          (filtro no Primary da região EMP)
f?p=100:1:&APP_SESSION.:IR_PRIMARY::RR,CR:IR_ENAME:KING  (abre, reseta, limpa e filtra o Primary)
f?p=100:1:&SESSION.:IR_REPORT1                           (abre o relatório salvo REPORT1)
f?p=&APP_ID.:1:&SESSION.:::RR                            (reseta todos os IRs da página 1)
https://host/ords/r/mycompany/hr-app/simple-ir?session=...&IR_JOB=CLERK   (friendly URL)
```

Dê um **Static ID** legível ao relatório salvo (*Saved Reports* › relatório › *Identification > Static ID*, destravando o cadeado); *Link > Link Example* mostra a URL pronta. Para abrir de fora da aplicação (e-mail), pode ser preciso habilitar *Session Management > Deep Linking*.

**Regras**: sem *Request*, as mudanças vão para o Primary. Sem *Request* e com mais de um IR na página, o filtro **precisa** ser qualificado com o DOM ID, senão dá erro. A sintaxe antiga `IR_REPORT_<alias>` e `IR_<coluna>` só funciona com um único IR na página.

Num link declarativo (Link Builder, ações de Cards), use *Set Items* com o nome `IR_EMPNO` (ou `IR[DOM]C_ENAME`) e *Clear Cache* com `RR`/`CR`.

Fonte: [Linking to Interactive Reports](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/linking-to-interactive-reports.html), [Using Actions to Link from a Cards Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-actions-to-link-from-cards-page.html)

### Interactive Report: Natural Language Support com Generative AI

O IR pode aceitar instruções em linguagem natural ("Show me…", "Break by…", "Highlight…", "Group by…"), que um LLM converte em configurações declarativas: filtros, colunas, highlights, quebras, ordenação, Group By, gráfico, Pivot, reset, salvar e linhas por página. Passos:

1. Criar um **Generative AI Service** no workspace (sem ele, os atributos ficam ocultos).
2. Associá-lo à aplicação (AI Attributes).
3. Na região IR, *Attributes > Generative AI*: **Natural Language Support** = On; **Default Search Mode** = *Search with AI* (padrão com o recurso ligado; com duas ou mais palavras dispara também uma busca de linha) ou *Row Search*; **Report Context** (descrição curta do que o relatório contém, melhora a precisão).
4. Em cada coluna relevante: **Column Context** (significado, usos comuns, dicas para a IA) e **Reference Data Type** (*Shared Component* com uma LOV, ou *SQL Query* com valores distintos) para a IA conhecer os valores válidos.

Na tela aparecem o campo "Search or ask a question" e um painel **AI Assistant** (pode ser destacado em janela). Boas práticas: perguntas focadas em como mostrar os dados; uma agregação/agrupamento por vez; não pedir análises livres ("Why are sales down?") nem consultas aninhadas complexas.

Fonte: [Adding Natural Language Support to Interactive Reports](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/adding-natural-language-support-to-interactive-reports.html), [Natural Language Support in Interactive Reports](https://docs.oracle.com/en/database/oracle/apex/26.1/aeeug/natural_language_support_in_interactive_reports.html)

### Interactive Report em APEXlang: estrutura de região, colunas e savedReport

Estrutura típica (extraída do próprio projeto, p20, e do APEXlang API Reference):

~~~text
region rel_solicitacoes (
    name: Solicitações de correção abertas
    type: interactiveReport
    source {
        location: localDatabase
        type: sqlQuery
        sqlQuery: ```sql
            select s.id_solicitacao, c.nome_completo as colaborador, ...
              from solicitacao_correcao s join colaborador c on ...
             where s.id_empresa = :G_ID_EMPRESA
            ```
    }
    pagination { type: rowRangesXToY }
    messages { whenNoDataFound: Nenhuma solicitação aberta. }
    advanced { savedReportMappingIdentifier: 38217116175837915 }

    column COLABORADOR (
        type: link
        heading { heading: Colaborador }
        link {
            target: { page: 13  items: { P13_ID_COLABORADOR: #ID_COLABORADOR# } }
            linkText: #COLABORADOR#
        }
    )
    savedReport primary ( ... displayColumn COLABORADOR ( ... ) ... )
)
~~~

Grupos de região específicos do IR no APEXlang: `searchBar` (`includeSearchBar`, `searchField`, `finderDropDown`, `reportsSelectList`, `rowsPerPageSelector`, `searchButtonLabel`), `actionsMenu` (as chaves da tabela do Actions menu), `download` (`authorization`, `formats`, `sendAsEmail`, `csvSeparator`, `csvEnclosedBy`, `filename`, `supplementalText`), `link`, `singleRowView`, `iconView`, `detailView`, `heading` (`fixedTo`, `maxReportHeight`), `performance`, `messages` e `genAI`. O `savedReportMappingIdentifier` liga a região aos relatórios salvos: não o altere à mão.

Fonte: [APEXlang API Reference — region](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

---

## 5. Interactive Grid: leitura e recursos gerais

### Interactive Grid: o que é, modelo cliente e quando usar

O Interactive Grid apresenta a consulta como uma grade rica. Tem quase tudo o que o IR oferece ao usuário (busca, ordenação, filtros, quebras, agregações, highlight, gráfico, download, relatórios salvos) e acrescenta: redimensionar, congelar e esticar colunas, arrastar colunas, scroll pagination, navegação e seleção por teclado (linhas ou intervalos de células), clipboard e, opcionalmente, **edição em linha** com inserção, alteração, duplicação, exclusão, refresh e revert de linhas sem sair da página.

Internamente é um componente **model-view**: um *model* no navegador guarda registros, metadados e estado de alteração; várias *views* (grid, icon, detail, chart, single row) mostram e editam esse model; *actions*, eventos e métodos do widget permitem comandar e reagir. Botões da toolbar e itens de menu são ligados a **actions** nomeadas.

Use quando: edição de várias linhas (detalhes de um mestre, planilhas de lançamento, carrinho em coleção), grandes volumes com scroll, ou quando o usuário precisa colar dados de planilha. Não use quando: precisa de Pivot, Group By, colunas computadas pelo usuário, filtros complexos ou altura de linha variável (use IR), ou quando quer lembrar a página corrente. O IG não suporta colunas BLOB.

Fonte: [Getting to Know the Interactive Grid](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/getting-know-interactive-grid.html), [Understanding and Customizing Grid Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-and-customizing-grid-behavior.html), [Understanding Report Page Types](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-report-page-types.html)

### Interactive Grid: tipos de coluna suportados

| Tipo | Observação |
|---|---|
| Actions Menu | Menu de ações da linha (*Row Actions*). Em IG editável, a coluna `APEX$ROW_ACTION` é criada automaticamente com este tipo; em IG não editável, adicione-a à mão (o menu terá só Single Row View e Refresh Row). |
| Row Selector | Checkbox de seleção de linha. `APEX$ROW_SELECTOR` é criada automaticamente ao tornar o IG editável. |
| Checkbox, Checkbox Group, Radio Group, Switch, Shuttle | Checkbox Group e Shuttle gravam valores em string separada por `:`. |
| Select List, Popup LOV, Text Field with autocomplete | Select List para listas pequenas; Popup LOV para listas grandes (com busca). |
| Text Field, Textarea, Number Field (valida número), Password, Date Picker, Color Picker, Star Rating, Rich Text Editor, Markdown Editor | Controles de edição, como itens de página. |
| Display Only, HTML Expression, Link, Percent Graph (0–100) | Não editáveis. Use *Display Only* para tornar uma coluna não editável num IG editável. |
| Hidden | Para PKs e colunas usadas só em templates (icon/detail view, links, HTML Expression). |
| Plug-ins | Aparecem como `<Nome> [Plug-in]`. |

Fonte: [Supported Columns in Interactive Grids](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/supported-columns-in-interactive.grids.html), [Managing Interactive Grid Column Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-interactive-grid-column-attributes.html)

### Interactive Grid: atributos de coluna (Source, Heading, Layout, Stretch, Enable Users To, Column Filter)

Principais grupos da coluna de IG (nomes do Property Editor e, entre parênteses, do APEXlang):

- **Source** (`source`): *Type* `Database Column` (padrão), `SQL Expression` (coluna calculada só leitura, preserva a editabilidade da fonte) ou `None` (coluna sem fonte, útil para HTML Expression); *Data Type*; **Query Only** (`queryOnly`: lida mas não gravada); **Primary Key** (`primaryKey`).
- **Heading**: *Heading* (numa coluna Hidden só vale para export/impressão), *Alignment*, *Alternative Label* (diálogos e Single Row View).
- **Layout**: *Sequence*, *Column Alignment*, *Group* (+ `useGroupFor`: `both`, `singleRowView`, `heading`) e **Stretch** (`Use Report Setting` padrão, `never`, `always`).
- **Appearance**: *CSS Classes* (aplicadas às células; para o item em edição use *Advanced > CSS Classes*), *Icon*, *Format Mask*, *Width/Height*, *Value Placeholder*.
- **Validation**: *Value Required*, *Maximum Length*.
- **Default** (`default.type`): `static`, `item`, `sqlQuerySingleValue`, `sqlQueryMultipleValues`, `expression`, `functionBody`, `sequence`; e **Duplicate Copies Existing Value** (padrão ligado).
- **List of Values / Cascading LOV** (`parentColumns`, `itemsToSubmit`, `parentRequired`) e **Multiple Values** (`delimitedList` ou `jsonArray`, separador `:`).
- **Master Detail > Master Column**: liga a coluna à coluna correspondente do IG mestre.
- **Column Filter**: *Enabled*; **LOV Type** — `None` (para colunas longas, em geral acima de 50 caracteres), `Distinct Column` (VARCHAR2/NUMBER; datas usam faixas pré-definidas), `SQL Query`, `Shared Component`, `Static Values`, `PL/SQL Function Body returning SQL Query`, `Use List of Values`; *Exact Match*, *Text Case*, *Date Ranges* (`all`, `past`, `future`).
- **Enable Users To**: *Sort*, *Control Break/Aggregate* (só se Sort ligado) e *Hide*.
- **Export/Printing > Include in Export/Print**.
- **Read Only** (`readOnly`): condição para a coluna ficar somente leitura, com **Execute** `once` ou `forEachRow` (avalia por linha).
- **Security**: *Authorization Scheme* e *Escape Special Characters*.
- **Advanced**: *HTML DOM ID*, *Custom Attributes*, **Column Initialization JavaScript Function** (`columnInitJavaScriptFunction`).

Algumas preferências (ordem das colunas, largura, ordenação) são salvas no relatório Primary/Alternate pelo desenvolvedor em tempo de execução, não no Property Editor.

**Desempenho:** liberar Sort e Control Break/Aggregate pode pesar em conjuntos grandes ou sem índices adequados.

Fonte: [Managing Interactive Grid Column Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-interactive-grid-column-attributes.html), [APEXlang API Reference — column](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Interactive Grid: toolbar, paginação e cabeçalho fixo

**Toolbar** (*Attributes > Toolbar*): *Show* (sem toolbar, todo o Actions menu some, inclusive Save/Save As de relatórios) e *Controls*: `searchCol` (Search Column Selection, só colunas não numéricas), `searchField`, `actionsMenu`, `resetButton`, `saveButton` (só aparece se o IG for editável e o usuário puder inserir/alterar/excluir). *Add Button Label* troca o texto padrão "Add Row".

**Pagination**:
- *Type* **Page**: linhas por página escolhidas pelo usuário (*Actions > Format > Rows Per Page*), com controles no rodapé.
- *Type* **Scroll**: preenche a altura do IG e busca mais linhas conforme a rolagem.
- **Show Total Row Count**: mostra o total no rodapé, exige uma query adicional. Com total, o scroll vira **virtual scrolling** (a barra reflete o tamanho do conjunto); sem total, a barra só indica se há mais linhas.

**Heading > Fixed To**: `Page` (cabeçalho preso ao topo da página), `Region` (cabeçalho acima de uma grade rolável de altura *Fixed Report Height*) ou `None`.

Outros: *Appearance > Select First Row* (`selectFirstRow`, padrão ligado), *Fixed Row Height* (padrão ligado), *Show Null Values as*; *Messages > When No Data Found*; *Help > Help Text* (aparece na ajuda do Actions menu).

Fonte: [Customizing the Interactive Grid Toolbar](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/customizing-the-interactive-grid-toolbar.html), [Controlling Interactive Grid Pagination](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/controlling-interactive-grid-pagination.html), [Getting to Know the Interactive Grid](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/getting-know-interactive-grid.html)

### Interactive Grid: Enable Users To (flashback, chart view, download, relatórios públicos)

Grupo *Attributes > Enable Users To* (padrões do APEXlang):

| Atributo | Padrão | Efeito |
|---|---|---|
| Save Public Report | off | Usuários autenticados podem salvar relatórios públicos. |
| Save Public Report Authorization | — | Quem pode salvar públicos (vazio = qualquer um). |
| Flashback | on | Consulta flashback: ver os dados como estavam há N minutos (só leitura; o alcance depende da retenção de undo/redo do banco). |
| Define Chart View | on | Usuário pode criar um gráfico do IG. |
| Download | on | Menu Download. |

Fonte: [Enabling Flashback and Charts](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/enabling-flashback-and-charts.html), [Enabling Users to Save Interactive Grid Public Reports](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/enabling-users-to-save-interactive-grid-public-reports.html)

### Interactive Grid: formatos de download e e-mail

Com *Enable Users To > Download* = On, configure em *Download*: *Authorization*; *Formats* (CSV, HTML, PDF, Excel — para bloquear de verdade, desmarque todos); *Send as Email* (anexo HTML, só autenticados, exige SMTP); *CSV Separator* e *CSV Enclosed By*; *Filename* (sem extensão) e *Supplemental Text* (não use com CSV). O usuário pode escolher *Data Only* (ignora grupos de colunas, agregações, highlights e quebras) e *Strip Rich Text* (CSV/Excel com coluna Rich Text). Para PDF nativo, aparecem *Page Size*, *Page Orientation* e *Include Accessibility Tags*. O grupo `columns` do APEXlang define fonte, peso, tamanho e cores usados no PDF/Excel.

Fonte: [Configuring Interactive Grid Download Formats](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-interactive-grid-download-formats.html), [Downloading or Emailing an Interactive Grid](https://docs.oracle.com/en/database/oracle/apex/26.1/aeeug/downloading-emailing-interactive-grid.html)

### Interactive Grid: Icon View e Detail View

O IG tem por padrão a view **Grid**; *Icon View* e *Detail View* acrescentam botões ao seletor de views.

- **Icon View**: *Show* = On. Modo não custom: *Icon Type* `iconCssClasses` (coluna com classes Font APEX) ou `imageInUrl` (coluna com URL + *Icon Attributes*), *Icon*, *Label Column*, *Link Target* (Link Builder) e *Link Attributes*. Modo *Custom* = On: HTML completo em *Custom Icon*. **Requisito:** todos os itens precisam ter a mesma largura e altura e o conteúdo não pode transbordar; o tamanho é definido por CSS na classe `a-IconList-item`.
- **Detail View**: *Before Rows*, *For Each Row* e *After Rows*. Substituições: `&COLUNA.` e `&COLUNA_LABEL.`, `&APEX$ROW_ID.` (identificador do registro) e `&APEX$ROW_INDEX.` (sequência de exibição).

```html
<tr><td align="right">&ENAME_LABEL.:</td><td>&ENAME.</td></tr>
<tr><td align="right">&JOB_LABEL.:</td><td>&JOB.</td></tr>
```

Fonte: [Enabling Icon View in an Interactive Grid](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/enabling-icon-view-in-an-interactive-grid.html), [Enabling Detail View in an Interactive Grid](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/enabling-detail-view-in-an-interactive-grid.html)

### Interactive Grid: relatórios salvos (Private, Public, Primary, Alternative)

- **Private**: qualquer usuário; só o criador vê e mexe. *Actions > Report > Save As* → *Type = Private*.
- **Public**: qualquer usuário, se *Save Public Report* estiver ligado (e a authorization deixar). Todos veem; quem tem privilégio de salvar públicos pode modificá-los ou copiar com *Save As*.
- **Primary**: o que todos veem por padrão. Só desenvolvedor salva (*Report > Save*) e renomeia (*Report > Edit*); **não pode ser excluído**.
- **Alternative**: layouts extras do desenvolvedor, com *Authorization* opcional para restringir quem vê. Aparecem sob "Default" na lista.

Salvar exige authentication scheme na aplicação e a toolbar ligada. Para relatórios públicos a Oracle sugere: configurar o *Stretch* de cada coluna, rodar a página, ajustar as colunas para a menor largura máxima razoável e então salvar. *Reset* volta ao último estado salvo; num Primary, desfaz tudo o que o usuário fez (salve um Private para preservar).

Fonte: [Saving Interactive Grid Reports](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/saving-interactive-grids-reports.html), [Resetting Interactive Grids](https://docs.oracle.com/en/database/oracle/apex/26.1/aeeug/resetting-interactive-grid.html)

### Interactive Grid: links com filtros na URL (IG[...], DATE canônico, RR e CR)

Mesma ideia do IR, com prefixo `IG`:

- Relatório salvo (*Request*): `IG[<DOM ID>]_<static id do relatório>`; Primary = `IG_PRIMARY`.
- Filtro (*itemNames*): `IG[<DOM ID>]<operador>_<coluna>`, ex.: `IG[EMP]C_ENAME:KING`; `ROWFILTER` para texto em todas as colunas STRING/NUMBER.
- Operadores: `C`, `EQ` (padrão), `GTE`, `GT`, `LT`, `LTE`, `N`, `NC`, `NEQ`, `NN`, `IN`, `NIN` (**sem** `LIKE`/`NLIKE`, que existem só no IR).
- **DATE/TIMESTAMP**: valor em formato canônico sem separadores `YYYYMMDDHH24MISS`, ex.: `IG[EMP]EQ_HIREDATE:19811117000000`.
- ClearCache: `RR` (reset, como o botão Reset) e `CR` (limpa todos os filtros). Não há `RP` para IG.

```text
f?p=&APP_ID.:2:&SESSION.::::IG[EMP]_ENAME:KING
f?p=100:1:&APP_SESSION.:IG_PRIMARY::RR,CR:IG_ENAME:KING
f?p=100:1:&SESSION.:IG_12345::RR,CR:
```

As mesmas restrições do IR valem para páginas com vários IGs (qualificar pelo DOM ID).

Fonte: [Linking to Interactive Grid Reports](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/linking-to-interactive-grid-reports.html)

### Interactive Grid: seleção múltipla e Selection State Item

- **IG editável**: a coluna `APEX$ROW_SELECTOR` (criada automaticamente) tem *Settings > Enable Multi Select* = Yes por padrão. O usuário navega com setas, seleciona com Espaço e alterna com Ctrl+Espaço.
- **IG não editável**: precisa de configuração JavaScript (ver §7, `defaultGridViewOptions.multiple = true`).
- Para gravar as PKs selecionadas num item oculto (para SQL, PL/SQL, branches ou outra região), use `selectionStateItem` no JavaScript Initialization Code; `persistSelection = true` mantém a seleção entre páginas.

Fonte: [Managing Interactive Grid Column Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-interactive-grid-column-attributes.html), [Understanding and Customizing Grid Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-and-customizing-grid-behavior.html)

---

## 6. Interactive Grid editável

### Tornar um Interactive Grid editável: Edit Enabled, Allowed Operations, Allowed Row Operations Column, Lost Update Type

Grupo *Attributes > Edit* da região IG (APEXlang `edit { … }`):

| Atributo | APEXlang | Valores / padrão | Efeito |
|---|---|---|---|
| Enabled | `enabled` | padrão `false` | Liga a edição. **Ao ligar, o APEX cria automaticamente o processo** *Interactive Grid - Automatic Row Processing (DML)* e as colunas `APEX$ROW_ACTION`/`APEX$ROW_SELECTOR`. |
| Allowed Operations | `allowedOperations` | `add`, `update`, `delete` | Operações liberadas. |
| Allowed Row Operations Column | `allowedRowOperationsColumn` | coluna | Coluna cujo valor indica, por linha, se ela pode ser alterada e/ou excluída (ex.: só editar enquanto status for rascunho). |
| Lost Update Type | `lostUpdateType` | `rowValues` (padrão) ou `rowVersionColumn` | Proteção contra *lost update*. |
| Row Version Column | `rowVersionColumn` | coluna | Coluna incrementada a cada alteração (de preferência por trigger). |
| Add Row If Empty | `addRowIfEmpty` | padrão `true` (com `add`) | Adiciona uma linha vazia quando a consulta não retorna nada; a mensagem No Data Found nunca aparece; a linha só é inserida se for alterada. |

Também há *Edit Authorization* por operação (`editAuthorization.add`, `update`, `delete`).

**Lost update**: com *Row Values*, o APEX calcula um checksum de cada linha (concatenando as colunas atualizáveis) na consulta e o compara no commit; com *Row Version Column*, compara a versão. A Oracle **não recomenda** *Row Version Column* quando o IG grava em várias tabelas.

Por padrão, o IG editável tem botão **Save** na toolbar, que salva só aquele IG via AJAX, sem recarregar a página.

Fonte: [Making an Existing Interactive Grid Editable](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/making-an-existing-interactive-grid-editable.html), [APEXlang API Reference — region](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Interactive Grid editável: coluna Primary Key e por que a chave não pode mudar

O model do IG identifica cada linha pelo valor da(s) coluna(s) marcada(s) como **Primary Key** (*Source > Primary Key* = On) e assume que esse valor **nunca muda**. Para linhas novas, o model gera uma chave temporária no navegador; quando o processo grava a linha, a chave real do banco substitui a temporária. Essa é a única troca de chave permitida.

Consequências práticas:
- Marque a PK (ou um conjunto de colunas) e deixe-a *Hidden* ou *Display Only*.
- Não use como PK algo que muda (por exemplo, o `SEQ_ID` de uma coleção, que é renumerado quando membros são removidos ou movidos): gere um identificador estável (`SYS_GUID()`) e guarde-o numa coluna da coleção.

Fonte: [Editing Collection Data with a Grid](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/editing-collection-data-grid.html), [Creating Master Detail from an Existing Interactive Grid](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-master-metail-from-existing-interactive-grid.html)

### Processo Interactive Grid - Automatic Row Processing (DML): Editable Region, Target Type e transação única

O processo nativo **Interactive Grid - Automatic Row Processing (DML)** (APEXlang `type: interactiveGridAutoRowProcessing`) insere, altera e exclui as linhas do IG. Pontos-chave:

- **Editable Region** (`editableRegion`): o IG cujas alterações ele grava. Cada IG editável tem o seu processo.
- **Quando roda**: (a) no **Save** da toolbar, que salva só as alterações pendentes daquele IG via AJAX; (b) no **submit da página**, junto com itens de Form, validações e outros processos — assim um Form mestre e um ou mais IGs de detalhe são validados e gravados **numa única transação**. Se o salvamento for por submit, você pode esconder o botão Save do IG (*Toolbar > Controls*).
- **Target Type**: padrão grava na fonte da região (tabela/view). Com *Target Type = PL/SQL Code*, você escreve o código de *Insert/Update/Delete*, que roda **uma vez por linha** criada, alterada ou excluída. Dá para desligar *lock row* e *lost update protection* quando não fazem sentido (ex.: coleção, que é privada da sessão).
- **Execution Scope** (`executionScope`, em processos com Editable Region): `forCreatedAndModifiedRows` (padrão) ou `allSubmittedRows`.
- **Success Message**: para processos multi-linha, as substituições `#MRI_COUNT#` (inseridas), `#MRU_COUNT#` (alteradas) e `#MRD_COUNT#` (excluídas).

Outros processos de página também podem ter *Editable Region* apontando para o IG; a documentação recomenda isso, por exemplo, para recalcular na gravação valores que foram calculados no cliente. Nesse caso o processo roda por linha e enxerga as colunas como bind variables.

Fonte: [Understanding and Customizing Grid Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-and-customizing-grid-behavior.html), [Editing Collection Data with a Grid](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/editing-collection-data-grid.html), [About Page Processes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-page-processes.html), [APEXlang API Reference — process](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Bind variables de linha no Interactive Grid: :APEX$ROW_STATUS, :COLUNA, APEX$ROW_NUM e APEX$ROW_SELECTOR

Em validações, processos e condições associados a um IG (*Editable Region* definido), o APEX executa o código **para cada linha** e expõe:

| Referência | Conteúdo |
|---|---|
| `:NOME_COLUNA` | Valor da coluna na linha corrente. Pode ser **atribuído** em processos PL/SQL (ex.: `:ID := ...` para devolver a PK gerada). |
| `:APEX$ROW_STATUS` (`V('APEX$ROW_STATUS')`, `&APEX$ROW_STATUS.`) | `C` = criada, `U` = alterada, `D` = excluída. Também vale para Form region. |
| `:APEX$ROW_NUM` | Número da linha processada (documentado para tabular forms). |
| `:APEX$ROW_SELECTOR` | `X` se o checkbox de seleção da linha estiver marcado, `NULL` se não (tabular forms). |

**Tipos**: os valores das colunas chegam como texto. Para colunas DATE/TIMESTAMP use `to_date`/`to_timestamp` com a máscara adequada, e `to_number` para NUMBER.

```plsql
-- Target Type = PL/SQL Code do processo DML do IG
case :APEX$ROW_STATUS
when 'C' then
    :ID := shopping_cart_api.add_item(
               p_item_code    => :ITEM_CODE,
               p_quantity     => to_number(:QUANTITY),
               p_need_by_date => to_date(:NEED_BY_DATE, 'DD-MON-YYYY'));
when 'U' then
    shopping_cart_api.update_item(
               p_item_id      => :ID,
               p_item_code    => :ITEM_CODE,
               p_quantity     => to_number(:QUANTITY),
               p_need_by_date => to_date(:NEED_BY_DATE, 'DD-MON-YYYY'));
when 'D' then
    shopping_cart_api.remove_item(p_item_id => :ID);
end case;
```

Atenção: no exemplo publicado na documentação aparece `to_number('QUANTITY')` (literal entre aspas), que geraria erro de conversão; o correto é a bind variable `to_number(:QUANTITY)`, como acima.

Fonte: [Using Built-in Substitution Strings](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-available-built-in-substitution-strings.html), [Editing Collection Data with a Grid](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/editing-collection-data-grid.html)

### Validações por linha em Interactive Grid (Editable Region e #COLUMN_HEADER#)

Crie a validação em *Processing › Validations › Create Validation* e, em *Validation > Editable Region*, escolha o IG. A validação passa a ser avaliada **para cada linha alterada**, com acesso a `:COLUNA` e `:APEX$ROW_STATUS`. Na mensagem de erro, use `#COLUMN_HEADER#` para o cabeçalho da coluna associada (equivalente ao `#LABEL#` de itens); esses placeholders não funcionam se o local de exibição for *On Error Page*. *Always Execute* = On faz a validação rodar mesmo que o botão de submit tenha *Execute Validations* desligado.

```plsql
-- Validação "Expressão PL/SQL" com Editable Region = IG de itens
:APEX$ROW_STATUS = 'D' or to_number(:QUANTIDADE) > 0
-- Mensagem: #COLUMN_HEADER# deve ser maior que zero.
```

Além das validações de servidor, cada coluna tem *Validation > Value Required* e *Maximum Length*, aplicadas no cliente.

Fonte: [Understanding Validations](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-validations.html)

### Interactive Grid editável: modos de navegação e edição, ações de linha e de seleção, clipboard

- **Navigation mode** × **Edit mode**: em navegação o usuário move entre células, seleciona, abre menus. Entra em edição com duplo clique, Enter, F2 ou o botão *Edit*; sai com Esc. Só **um** editor de célula fica ativo por vez (melhor desempenho, teclado e acessibilidade).
- **Row actions** (linha corrente): Single Row View, Add Row, Duplicate Row, Delete Row, Refresh Row, Revert Changes.
- **Selection actions** (linhas ou intervalo): Copy, Cut, Paste, Paste Insert, Duplicate, Delete, Refresh, Revert, Copy Down, Fill, Clear.
- **Seleção**: *Row Selection* (padrão) ou *Cell Selection* (F8 ou *Actions > Selection*).
- **Clipboard**: copiar põe texto e tabela HTML no clipboard (e um JSON próprio entre IGs, preservando os valores do model). Paste sobrescreve a partir da célula corrente; Paste Insert (com Shift) insere linhas. Valores colados são aplicados como se digitados, então DAs e validações de cliente rodam; linhas/colunas só leitura são puladas. Em colunas de LOV, cole o **valor de retorno**, não o texto exibido. O navegador pode exigir HTTPS, atalho de teclado ou permissão para colar.
- **Exclusão**: *Delete Row* só marca a linha (riscada); ela sai de fato ao salvar.

Fonte: [Getting to Know the Interactive Grid](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/getting-know-interactive-grid.html), [About Editable Interactive Grids](https://docs.oracle.com/en/database/oracle/apex/26.1/aeeug/about-editable-interactive-grids.html)

### Interactive Grid editável: colunas como formulário (cascading LOV, DAs, read-only condicional)

Uma linha editável funciona como um formulário horizontal: cada coluna tem um tipo de controle (Date Picker, Select List, Popup LOV, Switch…) e se comporta como um item, mas o valor é da célula da linha corrente. Recursos de formulário disponíveis:

- **Cascading LOV** entre colunas da mesma linha (*Cascading LOV > Parent Column(s)*).
- **Dynamic actions** reagindo à mudança de uma coluna (calcular outra, habilitar/desabilitar, validar).
- **Somente leitura condicional** (*Read Only*), inclusive por authorization, avaliada uma vez ou por linha.

**Cuidado de desempenho**: cascading LOVs e DAs que chamam o servidor deixam lentas as operações em massa (paste, copy down, fill, clear), porque podem gerar uma chamada por linha. Quando possível, calcule e valide no cliente em JavaScript e recalcule na gravação com um processo cujo *Editable Region* seja o IG.

Fonte: [Getting to Know the Interactive Grid](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/getting-know-interactive-grid.html)

### Master-detail com dois Interactive Grids na mesma página

Passos:

1. Crie o IG mestre (ex.: departamentos) pelo Create Page Wizard com *Editing Enabled* e confirme a PK.
2. Crie a região filha (botão direito na região › *Create Region Below*), *Type = Interactive Grid*, fonte SQL dos detalhes.
3. Na filha, *Master Detail > Master Region* = região mestre.
4. Na coluna FK da filha (ex.: `DEPARTMENT_ID`), *Master Detail > Master Column* = coluna correspondente do mestre.
5. Para editar a filha: *Edit > Enabled* = On, operações, e marque a PK da filha (*Source > Primary Key*).

Ao selecionar uma linha no mestre, a filha mostra só os detalhes correspondentes. Pode haver qualquer número de relações mestre-detalhe na página. Via JavaScript, `trackParentSelection = false` desliga a sincronização automática e você controla com `setMasterRecord`.

Fonte: [Creating Master Detail from an Existing Interactive Grid](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-master-metail-from-existing-interactive-grid.html), [JSDoc: Widget interactiveGrid](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/interactiveGrid.html)

### Exemplo completo: editar uma APEX collection num Interactive Grid com chave estável

Cenário: carrinho de compras em coleção (`SHOPPING_CART`), com `C001` = código do item, `N001` = quantidade, `D001` = data, `C002` = ID estável (GUID).

1. **View** com nomes legíveis, usada como fonte do IG:

```sql
create or replace view shopping_cart_v as
select c001 as item_code, c002 as id, n001 as quantity, d001 as need_by_date
  from apex_collections
 where collection_name = 'SHOPPING_CART';
```

2. **Package** que encapsula `APEX_COLLECTION` (cria a coleção se não existir; `add_item` devolve `sys_guid()`; `update_item`/`remove_item` localizam o `SEQ_ID` pelo GUID em `C002` e chamam `apex_collection.update_member`/`delete_member`).
3. IG sobre a view, coluna `ID` como **Primary Key**, *Edit > Enabled* = On.
4. No processo DML criado, *Target Type = PL/SQL Code* com o `case :APEX$ROW_STATUS` mostrado acima; desligue lock de linha e proteção de lost update (dados privados da sessão).
5. *Messages > When No Data Found* = "No items in your cart".
6. Para usar um botão comum como "Add Item" ligado à ação do IG (com toolbar escondida): dê ao IG o *HTML DOM ID* `shoppingcart`, botão com *Action = Defined by Dynamic Action* e *Custom Attributes* `data-action="[shoppingcart]selection-add-row" data-no-update="true"` (`data-no-update` impede que a ação troque rótulo e ícone do botão).
7. Na finalização, percorra `shopping_cart_v` num loop PL/SQL.

Fonte: [Editing Collection Data with a Grid](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/editing-collection-data-grid.html)

### Interactive Grid em APEXlang: região editável e coluna

~~~text
region itens (
    name: Itens
    type: interactiveGrid
    source { location: localDatabase  type: sqlQuery  sqlQuery: ```sql ... ``` }
    edit {
        enabled: true
        allowedOperations: [ add  update  delete ]
        lostUpdateType: rowValues
        addRowIfEmpty: false
    }
    toolbar { show: true  controls: [ searchCol  searchField  actionsMenu  resetButton  saveButton ] }
    pagination { type: SCROLL  showTotalCount: false }
    enableUsersTo { savePublicReport: false  flashback: false  defineChartView: true  download: true }
    advanced { htmlDomId: itens }
    componentAdvanced { initJavaScriptFunction: ```js function(options){ return options; } ``` }

    column ID ( type: hidden  source { type: databaseColumn  databaseColumn: ID  dataType: number  primaryKey: true } )
    column QUANTIDADE (
        type: numberField          // nome do tipo: confira num export real
        validation { valueRequired: true }
        readOnly { type: itemIsNotNull  item: P10_FECHADO  execute: once }
        security { escapeSpecialChars: true }
    )
)
~~~

Os nomes de grupos (`edit`, `toolbar`, `pagination`, `enableUsersTo`, `download`, `iconView`, `detailView`, `heading`, `help`) e de propriedades vêm do APEXlang API Reference; o grupo do JavaScript de inicialização (`initJavaScriptFunction`) está listado em `componentAdvanced`. Alguns campos não têm enum documentado (o `pagination.type` do IG, por exemplo, é uma string com padrão `SET`; aqui foi usado `SCROLL` como ilustração); **confira num export real antes de editar** e veja o caso "IG sem edição no 26.1.5" (§19).

Fonte: [APEXlang API Reference — region e column](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

---

## 7. Customização do Interactive Grid com JavaScript

### JavaScript Initialization Code do Interactive Grid: estrutura e regras

Em *Attributes > Advanced > JavaScript Initialization Code* (APEXlang `initJavaScriptFunction`) você escreve uma função que recebe o objeto `options`, altera-o e o **devolve**. Regras:

- As opções do widget só podem ser definidas **na inicialização**; mudá-las depois não tem efeito (salvo indicação na própria opção).
- O APEX só envia ao cliente o que é necessário, então objetos aninhados (`options.toolbar`, `options.defaultGridViewOptions`…) **podem não existir**. Programe de forma defensiva: use `apex.util.getNestedObject(options, "caminho")`, que cria os objetos que faltam sem apagar o que já existe.
- Use a inicialização para o que precisa estar pronto antes de o IG existir (features, toolbar, seleção, editabilidade, paginação, view padrão, model, `initActions`). Depois de criado, use as APIs de região, view, model, actions e eventos.

```js
function( options ) {
    const gridOptions = apex.util.getNestedObject( options, "defaultGridViewOptions" );
    gridOptions.multiple           = true;                  // seleção múltipla de linhas
    gridOptions.selectionStateItem = "P2_SELECTED_EMPNOS";  // PKs selecionadas num item oculto
    gridOptions.persistSelection   = true;                  // mantém seleção entre páginas
    // gridOptions.footer = false;                          // esconde o rodapé
    return options;
}
```

Fonte: [Understanding and Customizing Grid Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-and-customizing-grid-behavior.html), [JSDoc: Widget interactiveGrid](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/interactiveGrid.html)

### Opções do widget interactiveGrid mais usadas

| Opção | Tipo | Uso |
|---|---|---|
| `defaultGridViewOptions` | Object | Opções do widget `grid` da view Grid (ex.: `multiple`, `allowInsert`, `footer`, `selectionStateItem`, `persistSelection`). |
| `defaultIconViewOptions` / `defaultDetailViewOptions` | Object | Opções do `tableModelView` das views Icon/Detail (ex.: `footer: false`). |
| `defaultSingleRowOptions` | Object | Opções do `recordView` da Single Row View (ex.: `alwaysEdit: true`). |
| `defaultModelOptions` | Object | Opções do model não definidas pelo IG (ex.: `pageSize: 200`). |
| `editable` | boolean (false) | Liga/desliga a edição. |
| `features` | Object | `filter`, `flashback` (ambos `true` por padrão). |
| `toolbar` | Object | `actionMenu`, `columnSelection`, `editing` (só esconde o botão Edit), `reset`, `save`, `savedReports`, `searchField`. `false`/`null` remove a toolbar. |
| `toolbarData` | Array | Estrutura completa da toolbar; parta de `$.apex.interactiveGrid.copyDefaultToolbar()`. |
| `initActions` | function(actions) | Adicionar, esconder, desabilitar ou mudar atalhos de actions. |
| `initialSelection`, `reportSettingsArea`, `saveLoadingIndicator`, `text`, `trackParentSelection` | — | Seleção inicial, área de configurações, indicador de salvamento, textos, sincronização com o mestre. |

```js
function( options ) {
    apex.util.getNestedObject( options, "toolbar" ).searchField = false;   // sem busca
    const features = apex.util.getNestedObject( options, "features" );
    features.flashback = false;
    return options;
}
```

Fonte: [JSDoc: Widget interactiveGrid](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/interactiveGrid.html)

### initActions e actions pré-definidas do Interactive Grid

Toolbar e menus do IG são guiados por **actions**. Em `initActions` você recebe a interface de actions (`actions.context` é o elemento do widget):

```js
function( options ) {
    options.initActions = function( actions ) {
        actions.hide( "show-help-dialog" );                               // esconde a ajuda
        actions.lookup( "show-filter-dialog" ).shortcut = "Ctrl+Alt+F";   // novo atalho
        actions.update( "show-filter-dialog" );
        actions.add( {
            name: "aprovar-selecionados",
            label: "Aprovar",
            action: function( event, focusElement ) { /* ... */ }
        } );
    };
    return options;
}
```

Actions pré-definidas (seleção): `search`, `filter-column`, `change-report`, `change-view`, `chart-view`, `show-columns-dialog`, `show-filter-dialog`, `show-sort-dialog`, `show-aggregate-dialog`, `show-flashback-dialog`, `show-highlight-dialog`, `show-control-break-dialog`, `show-download-dialog`, `show-help-dialog`, `stretch-columns`, `change-rows-per-page`, `save-report`, `show-save-report-as-dialog`, `show-edit-report-dialog`, `delete-report`, `reset-report`, `row-add-row`, `row-duplicate`, `row-delete`, `row-refresh`, `row-revert`, `selection-mode`, `selection-duplicate`, `selection-delete`, `selection-refresh`, `selection-revert`, `selection-copy`, `selection-add-row`, `selection-copy-down`, `selection-clear`, `selection-fill`, `refresh`, `edit`, `save`, `single-row-view`, `close-single-row-view`.

Actions ocultas ou desabilitadas não fazem nada quando invocadas. A opção declarativa de **não** ter o botão Save simplesmente esconde a action `save`: se você precisa invocar `save` por código mas não quer o botão, deixe a opção declarativa ligada e remova o botão da toolbar via `toolbarData`.

Em tempo de execução: `apex.region("dom_id").call("getActions").invoke("save")` ou `.lookup("nome")`.

Fonte: [JSDoc: Widget interactiveGrid](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/interactiveGrid.html)

### Personalizar a toolbar do Interactive Grid com toolbarData e copyDefaultToolbar

```js
function( options ) {
    const $ = apex.jQuery,
          toolbarData = $.apex.interactiveGrid.copyDefaultToolbar();  // cópia da toolbar padrão
    // move "Download" do Actions menu para um botão próprio, após o botão Actions
    const download = toolbarData.toolbarRemove( "show-download-dialog" );
    download.type = "BUTTON";
    download.iconBeforeLabel = true;
    toolbarData.toolbarInsertAfter( "actions_button", download );
    options.toolbarData = toolbarData;
    return options;
}
```

O array retornado tem métodos auxiliares (`toolbarFind`, `toolbarRemove`, `toolbarInsertAfter`) e grupos como `"reports"` e `"actions1"`. Botões são definidos pela action (`{ type: "BUTTON", action: "save-report", iconOnly: true }`).

Fonte: [JSDoc: Widget interactiveGrid](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/interactiveGrid.html)

### APIs de tempo de execução e eventos do Interactive Grid

Métodos do widget (via `apex.region("dom_id").call(...)` ou `.widget().interactiveGrid(...)`): `getActions()`, `getCurrentView()`, `getCurrentViewId()`, `getViews(id)` (ex.: `"grid"`), `getSelectedRecords()`, `setSelectedRecords(records)`, `gotoCell(...)`, `refresh()`, `resize()`, `setMasterRecord(model, record)`, `getToolbar()`, `focus()`.

Eventos (jQuery, prefixo `interactivegrid`): `modechange` (`data.editMode`), `reportchange`, `reportsettingschange`, `save` (`data.status === "success"`), `selectionchange` (`data.selectedRecords`, `data.model`; também disponível como evento de DA *Selection Change [Interactive Grid]*), `viewchange`, `viewmodelcreate`.

```js
// "Execute when Page Loads"
$( "#itens" ).on( "interactivegridselectionchange", function( event, data ) {
    const qtd = data.selectedRecords.length;
    apex.item( "P10_QTD_SELECIONADA" ).setValue( qtd );
} );
```

Fonte: [JSDoc: Widget interactiveGrid](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/interactiveGrid.html), [Understanding and Customizing Grid Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-and-customizing-grid-behavior.html)

### Atualizar só a linha editada do Interactive Grid ao fechar um modal

Padrão para IG não editável que abre um formulário modal:

1. **Função** em *Function and Global Variable Declaration* da página:

```js
function refreshGridRowOrRegion( regionHtmlDomId, primaryKey ) {
    const region = apex.region( regionHtmlDomId );
    if ( !region || region.type !== "InteractiveGrid" ) {
        throw new Error( "The region must be an Interactive Grid" );
    }
    if ( primaryKey ) {
        const model  = region.call( "getViews", "grid" ).model;
        const record = model.getRecord( primaryKey );      // acha pela PK no model
        if ( record ) {
            model.fetchRecords( [ record ] );               // busca só esse registro no servidor
            return;
        }
    }
    region.refresh();   // inserção/exclusão: recarrega tudo
}
```

2. **DA** *Dialog Closed* com seletor jQuery `body`, ação *Execute JavaScript Code*:

```js
const editedEmpno = this.data && this.data.P2_EMPNO_EDITED;
refreshGridRowOrRegion( "employees", editedEmpno || null );
```

3. **No modal**: computação *Pre-Rendering* copia a PK editada para o item oculto `P2_EMPNO_EDITED`; o processo *Close Dialog* devolve esse item em *Items to Return*; um processo *Clear Session State* com *When Button Pressed = DELETE* limpa o item antes de fechar (força refresh completo na exclusão).
4. Opcional: esconder o botão Delete com condição *No Rows Returned* quando houver registros dependentes (evita erro de integridade referencial).

O flag de "manter paginação" de `refresh()` só vale para IR no 26.1.

Fonte: [Understanding and Customizing Grid Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-and-customizing-grid-behavior.html)

### Coluna do Interactive Grid com Template Component (gráfico SVG por linha)

Técnica para visualização dentro da célula:

1. Crie uma coluna **sem fonte de tabela** (*Create Column*), *Type = Hidden*, *Source > Type = SQL Expression*, *Data Type = NUMBER*, com uma expressão analítica, por exemplo a posição do salário na faixa de 7 a 93:

```sql
round( 7 + ( (sal - min(sal) over ())
             / nullif(max(sal) over () - min(sal) over (), 0) ) * 86 )
```

(`over ()` aplica a função sobre todas as linhas sem colapsar com `GROUP BY`; `nullif` evita divisão por zero.)

2. Crie outra coluna com *Source > Type = None*, *Type = HTML Expression*, aplicando o Template Component com `{with/} … {apply PERCENT_DOT_ON_BAR/}`.
3. O Template Component contém o SVG (`viewBox` lógico 0 0 100 16) que usa os atributos `#LABEL#` e `#PERCENT#`.

Para uso em produção, a Oracle lembra de tratar acessibilidade e o conteúdo copiado para o clipboard (as APIs da grade controlam o que cada célula copia).

Fonte: [Getting to Know the Interactive Grid](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/getting-know-interactive-grid.html)

---

## 8. Cards

### Cards: o que é, quando usar e layouts Grid, Float e Horizontal

A região **Cards** mostra cada linha como um bloco de informação, com slots para título, subtítulo, corpo, corpo secundário, ícone, badge, mídia e ações. Aceita mídia de coluna BLOB, URL ou vídeo em iframe. Layouts (*Appearance > Layout*, APEXlang `componentAppearance.layout`): `grid` (com `gridColumns` 2 a 5), `float` e `horizontal` (linha). Pelo assistente você escolhe a fonte, o layout e as colunas de *Title*, *Body*, *Icon Initials* e *Badge*.

Use quando: painéis de resumo com um clique para o detalhe, galerias, listas visuais. Cards também pode ser o resultado de um Faceted Search ou Smart Filters. Não use quando: o usuário precisa ordenar por colunas arbitrárias sem você prever (use Order By Item) ou editar dados.

Fonte: [Managing Cards](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-cards.html), [Example Cards Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/example-cards-page.html), [Creating a Cards Page Using the Create Page Wizard](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-cards-page-using-create-page-wizard.html)

### Cards: atributos Title, Subtitle, Body, Secondary Body, Icon and Badge e Media

Em *Attributes* da região Cards:

| Grupo | Atributos (APEXlang) | Observações |
|---|---|---|
| Card | `primaryKeyColumn1`, `primaryKeyColumn2`, `cssClasses` | PK obrigatória quando ícone ou mídia vêm de BLOB. |
| Title / Subtitle / Body / Secondary Body | `advancedFormatting` (false), `column` ou `htmlExpression`, `cssClasses` | Com *Advanced Formatting* ligado, você escreve HTML com `&COL.` e template directives. |
| Icon and Badge | `iconSource`: `initials`, `iconClass`, `iconClassColumn`, `imageUrl`, `imageBlobColumn`; `iconColumn`/`imageColumn`/`imageUrl`; `iconCssClasses`; `iconPosition` (`top`, `start` padrão, `end`); `iconDescription`; `badgeColumn`, `badgeLabel`, `badgeCssClasses` | `initials` gera as iniciais a partir da coluna. |
| Media | `source`: `imageUrl`, `urlColumn`, `blobColumn`; `position`: `first`, `body` (padrão), `background`; `appearance`: `square`, `widescreen`; `sizing`: `fit` (padrão), `cover`; `imageDescription`; ou `advancedFormatting` + `htmlExpression` | Com BLOB, informe também `blobAttributes` (mime type etc.). |
| Pagination | `cardsPerPage` (15) | |
| Messages | `whenNoDataFound`, `noDataFoundIcon` | |

Todos os atributos de texto livre (CSS Classes, Icon/Image Description, Badge Label) aceitam substituição de coluna `&ENAME.`. Formatos de número e data devem vir prontos do SQL ou das máscaras das colunas.

```text
&JOB. in &DNAME. (&LOC.)<br>
since &HIREDATE.
```

Fonte: [Editing Card Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-card-attributes.html), [Info Tiles Using Cards](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/info-tiles-using-cards.html), [APEXlang API Reference — region](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Cards: ações (Button, Full Card, Title, Subtitle, Media) e links para detalhe

Na árvore, botão direito em *Actions* da região Cards › *Create Action*:

- **Identification > Type**: *Button* (botão no card; *Label* vira texto ou ALT do ícone), *Full Card* (o card inteiro é link), *Title*, *Subtitle*, *Media*.
- **Link > Type**: *Redirect to Page in this Application*, *Redirect to Page in a different Application* (exige Deep Linking no app de destino), *Redirect to URL*. No Link Builder: *Page* (número ou alias), *Set Items* (itens de página, de aplicação ou **filtros de IR** como `IR_EMPNO`, com valores `&ID.`, `&P2_EMPNO.` ou literais), *Clear Cache* (páginas, itens, `RP`, `CR`, `RR`), *Action* (None, Clear Regions, Reset Regions, Reset Pagination) e *Request*.
- **Server-side Condition**: se a condição referencia colunas, defina *Execute* = **For Each Row**; senão, *Once*.

Regra de múltiplas ações: você pode criar várias do mesmo tipo, mas **só botões são renderizados várias vezes**. Para os demais tipos, vale a primeira ação cuja condição for verdadeira; as outras são ignoradas. Para alternar destinos por linha, crie várias ações com condições por linha.

Fonte: [Using Actions to Link from a Cards Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-actions-to-link-from-cards-page.html)

---

## 9. Content Row, Template Components e Order By Item

### Template Components como relatório: regiões de uma ou várias linhas

**Template Components** são plug-ins de UI reutilizáveis feitos com HTML e template directives. Podem ser usados como **região** (uma linha ou várias linhas de dados) ou como **partial** dentro de uma coluna de relatório. Regiões baseadas em Template Component:

- renderizam instantaneamente uma ou várias linhas;
- lembram a paginação;
- funcionam com Faceted Search e Smart Filters;
- suportam Order By externo;
- suportam seleção de uma ou várias linhas e navegação por teclado;
- suportam agrupamento dos dados;
- têm **Actions** e **Menus** com condições por linha (*Action Positions* e *Action Templates*).

O Universal Theme traz, entre outros, Avatar, Badge, Comments, **Content Row**, Media List, Timeline, Metric Card, Contextual Info, Empty State e List Item (no APEXlang, tipos `themeTemplateComponent/<nome>`; os da aplicação são `appTemplateComponent/<nome>`). Componentes do tema ficam em *Shared Components > Templates*; os avulsos em *Shared Components > Plug-ins*. Para criar o seu, copie um existente (*Plug-ins > Create > As a Copy of an Existing Plug-in*) e edite atributos, action positions, templates e arquivos.

Seleção em regiões de Template Component (APEXlang `rowSelection`): `type` `focusOnly`, `singleSelection` ou `multipleSelection`, com `currentSelectionPageItem` (PKs selecionadas) e `selectAllPageItem`.

Fonte: [Template Components](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/template-components.html), [Template Component Type Plug-ins](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/template-component-type-plug-ins.html), [APEXlang API Reference — region](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Content Row: lista com slots, ações por linha e seleção

A região **Content Row** formata cada linha em slots (*Title*, *Description*, *Overline*, *Avatar*, *Badge*…), aceitando HTML, template directives e colunas, inclusive ocultas, com `&COL.`. Exemplo de slots:

- Title: `&ENAME.`; Avatar Icon: `&ICON.`
- Description: `&JOB. in &DNAME. (&LOC.) since &HIREDATE.`
- Overline: `Compensation: &SAL. {if COMM/} + &COMM. commission = &TOTAL_COMP.{endif/}`

Você define ações (ex.: *Edit*, *Promote*) disponíveis em cada linha, paginação, seleção simples ou múltipla com um item oculto que recebe as PKs selecionadas, e um Order By Item para o usuário escolher a ordenação. Pode ser filtrada por Faceted Search e Smart Filters.

Fonte: [Flexibly Styling and Acting on Data](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/flexibly-styling-and-acting-data.html)

### Order By Item: deixar o usuário escolher a ordenação (Cards, Classic Report, Content Row)

*Region > Order By > Type = Item* cria uma LOV estática inline com cláusulas de ordenação pré-definidas e um item de página (por padrão Select List; também Radio Group, plug-in ou Hidden) que o usuário usa em tempo de execução. É ideal para regiões sem ordenação própria, como Cards. **Não** é suportado em Map, Tree, Interactive Report e Interactive Grid.

No diálogo *Order By Item*, cada linha tem *Clause*, *Key* e *Display*:

| Clause | Key | Display |
|---|---|---|
| `SAL DESC` | `SAL1` | Salary descending |
| `SAL ASC` | `SAL2` | Salary ascending |
| `DEPTNO ASC, SAL DESC` | `DEPT1` | Department and Salary |
| `ENAME ASC` | `ENAME` | Employee Name |

O item é gerado a partir de *Key*/*Display* e pode ser posicionado em qualquer lugar da página. As cláusulas aceitam diretivas (veja a ajuda do atributo). Alternativa sem escolha do usuário: *Order By > Type = Static Value* com `orderByClause`.

Fonte: [Managing Sorting with Order By Item](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-sorting-with-order-by-item.html)

---

## 10. Faceted Search

### Faceted Search: o que é, quando usar e componentes da página

A página de Faceted Search tem uma região **Search** do tipo *Faceted Search* (normalmente no slot *Left Column* do template *Left Side Column*) e uma região de resultados (Classic Report, Cards, Map, Content Row, Template Components ou plug-ins que suportem facets). O atributo **Source > Filtered Region** da região de busca aponta para a região filtrada. O usuário marca valores nos facets, vê quantas linhas cada valor tem e os resultados se atualizam.

**Facets são parecidos com itens, mas não são itens**: usam a mesma convenção de nome (`P<página>_<NOME>`), cada um é associado a uma coluna da região filtrada, e o facet *Search* pode filtrar várias colunas. Embora tenham tipos com nomes de itens (Checkbox Group, Select List), **a maioria das dynamic actions não se aplica a facets**.

Use quando: catálogos e listas com várias dimensões categóricas e espaço lateral disponível. Para economizar espaço, veja Smart Filters.

Fonte: [Example Faceted Search](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/example-faceted-search.html), [Editing a Faceted Search Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-faceted-search-page.html), [Narrowing a Search Using Facet Filters](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/narrowing-search-using-facet-filters.html)

### Faceted Search: tipos de facet (Checkbox Group, Input Field, Radio Group, Range, Search, Select List)

| Tipo | Comportamento |
|---|---|
| **Checkbox Group** | Vários valores; exige LOV; seleção gravada como string separada por `:`. |
| **Input Field** | Texto livre com operador definido pelo desenvolvedor ou escolhido pelo usuário. Filtra DATE/TIMESTAMP (com local time zone) usando o formato canônico `YYYYMMDDHH24MISS`. |
| **Radio Group** | Um valor. |
| **Range** | Lista de faixas (início inclusivo, fim **exclusivo**); seleção simples ou múltipla e entrada manual. |
| **Search** | Campo de texto que busca em várias colunas. Só **um** por região, sempre no topo, independentemente da sequência (salvo se for externo, referenciando um item em outro lugar da página). |
| **Select List** | Lista inline; bom para listas pequenas. |

Para Checkbox Group, Radio Group e Select List, a LOV é definida como num item, com a opção extra **Distinct Values** (valores distintos da coluna nas linhas que atendem aos filtros já aplicados).

Fonte: [About Creating Faceted Search Pages](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-creating-faceted-search-reports.html), [Defining Your Facets](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/defining-your-facets.html)

### Faceted Search pelo assistente: facets descobertos pelo Data Dictionary Cache

Ao criar a página pelo Create Application ou Create Page Wizard sobre uma **tabela local**, os facets são descobertos automaticamente pelo **Data Dictionary Cache**: o assistente pega as cinco primeiras colunas com *facet search score* ≥ 20 (veja o relatório *Table Column Cache*). Sobre **view ou SQL**, não há descoberta: o assistente cria um facet que só busca colunas `VARCHAR2`. O cache é atualizado pelo job noturno `ORACLE_APEX_DICTIONARY_CACHE` ou manualmente (*Gather Statistics and Refresh Cache* / *Refresh Cache Only*). Facets criados pelo assistente que calculam contagens já vêm com gráfico.

Para sincronizar facets com uma região existente: botão direito em *Facets* › *Synchronize Facets*.

Fonte: [About Creating Faceted Search Pages](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-creating-faceted-search-reports.html), [Editing a Faceted Search Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-faceted-search-page.html)

### Faceted Search: atributos da região (Batch Facet Changes, Show Total Row Count, Show Current Facets, Show Charts)

Em *Attributes > Settings* da região Faceted Search:

- **Batch Facet Changes**: ligado, aparece um botão *Apply* sob o facet e o filtro só roda ao clicar; desligado, filtra a cada mudança.
- **Show Total Row Count**: `No`, `Yes` (no topo dos facets correntes, ou no topo da região se *Show Current Facets* = No) ou `Selector` (em qualquer elemento, por seletor CSS, ex.: `#total_count_area`).
- **Show Current Facets**: `Yes` mostra *filter chips* (rótulo do facet + valor, com "x" para remover e "Clear All") no topo da região; `Selector` + *Current Facets Selector* (ex.: `#active_facets`, uma região Static Content no Body) põe os chips onde você quiser. Os assistentes criam por padrão o elemento `active_facets` acima do relatório.
- **Show Charts**: `Dialog` (ação *Show Chart* no menu de contexto do facet abre um diálogo não modal), `No` (desliga a ação; os atributos *Chart* e *Show Chart Initially* dos facets deixam de valer) ou `Selector` (desenha os gráficos num elemento seu, ex.: `<div id="facetDashboardArea"></div>` e seletor `#facetDashboardArea`).
- **Display Chart for Top N Values**: máximo de valores por gráfico (com *Sort By Top Counts*, são os maiores).

O usuário alterna barra/pizza no gráfico e pode clicar numa fatia "Others" para detalhar.

Fonte: [Editing a Faceted Search Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-faceted-search-page.html), [Showing Filter Chips and Total Row Count](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/showing-filter-chips-and-total-row-count.html)

### Faceted Search: atributos do facet (contagens, dependência, filtro de lista, Add Filter Dialog)

- **List Entries > Compute Counts**: calcula quantas linhas têm cada valor (necessário para o gráfico do facet). **Show Counts** mostra/esconde as contagens; é possível esconder opções com contagem zero e, em Checkbox/Radio Group, ordenar por maior contagem (*Sort By Top Counts*).
- **List Entries > Display Filter Initially**: campo de filtro acima da lista (só aparece se houver mais entradas que *Maximum Displayed Entries*).
- **Depending On > Facet**: o facet só aparece depois que o usuário escolhe um valor no facet do qual depende, e mostra só valores coerentes com ele (ex.: Responsável depende de Projeto).
- **Appearance > Display**: inline ou **Add Filter Dialog** (o facet fica num diálogo aberto pelo botão *Add Filter*, com campo "Select One" para achar o facet; o usuário aplica e fecha).
- **Settings** (Input Field): *Comparison Operator*, *Current Label* (texto do chip, com `%0` para o valor, ex.: `Less than %0`), *Suffix Text*.
- **Source**: *Database Column* (nome **case-sensitive**) e *Data Type*.
- **Layout > Sequence**: ordem na tela.

Comportamento de seleção múltipla: em Checkbox Group e Range, várias opções selecionadas retornam linhas que atendem **qualquer** uma (OR). Entre facets diferentes, os filtros se somam (AND).

Fonte: [Editing a Faceted Search Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-faceted-search-page.html), [Counts, Dependency, and Charts](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/counts-dependency-and-charts.html), [Behavior of Multiple Selections](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/behavior-multiple-selections.html), [Displaying Facets in Add Filter Dialog](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/displaying-facets-add-filter-dialog.html)

### Facet do tipo Range: sintaxe das faixas, datas canônicas e separadores #G# e #D#

O tipo Range exige coluna `NUMBER`, `DATE` ou `TIMESTAMP`. Cada opção da LOV estática tem *Return Value* no formato `Baixo|Alto` (baixo inclusivo, alto exclusivo); omita um lado para faixa aberta:

| Display Value | Return Value |
|---|---|
| `< 1#G#000` | `\|1000` |
| `1#G#000 - 3#G#000` | `1000\|3000` |
| `> 4#G#500` | `4500\|` |

No *Display Value*, `#G#` vira o separador de milhar e `#D#` o separador decimal do NLS em tempo de execução (`1#G#000` aparece como `1,000` ou `1.000`). Para datas use `YYYYMMDDHH24MISS`: "Antes de 2020" = `|20191231235959`; "2020 a 2024" = `20200101000000|20241231235959`.

Fonte: [Configuring Range Facets](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configuring-range-facets.html), [Editing a Faceted Search Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-faceted-search-page.html)

### Facet sobre coluna com vários valores (Delimited List ou JSON Array)

Para colunas que guardam vários valores numa string (ex.: `PLSQL:Spatial`), configure no facet **Multiple Values**:

- **Type**: `No`, `Delimited List` ou `JSON Array` (array JSON de escalares; JSON inválido gera erro).
- **Separator**: ex.: `:`. Aspas duplas e barra invertida não são aceitas.
- **Trim Whitespace**: remove espaços/tabs/quebras nas pontas de cada valor; aumenta o custo de parsing, a Oracle recomenda **desligar** e limpar os dados.
- **Filter Combination**: `OR (Union)` (linha casa se qualquer valor bate) ou `AND (Intersect)` (linha precisa conter todos os valores escolhidos).

Combine com *LOV Type = Distinct Values*, *Include Null Option* e *Null Display Value* (ex.: "No Skills"). Requer Oracle Database 12.2 ou posterior.

Fonte: [Editing a Faceted Search Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-faceted-search-page.html), [Working with Multi-Value Columns](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/working-multi-value-columns.html)

### Facet Groups para várias colunas de flag

Modelos com várias colunas de flag (Sim/Não: "Em estoque", "Disponível para pedido"…) poluem a busca. Um **Facet Group** (botão direito em *Facets* › *Create Facet Group*) mostra um único facet com vários checkboxes, cada um ligado a uma coluna: em cada checkbox, desligue *Settings > Use Defaults*, defina *Checked Value* (até 255 caracteres), *Database Column* e *Data Type*. Para adicionar mais, botão direito em *Checkboxes* › *Create Checkbox*.

Fonte: [Editing a Faceted Search Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-faceted-search-page.html)

### Facet Search: buscar texto em várias colunas

Toda região Faceted Search tem um facet **Search**. Em *Source > Database Column(s)* informe a lista de colunas separadas por vírgula (ex.: `ENAME,JOB,MGR,DEPTNO`). O usuário digita uma ou mais palavras e tecla Enter; o APEX retorna linhas que contêm **qualquer** das palavras em **qualquer** das colunas, combinadas (AND) com os demais facets aplicados. O Search pode ficar inline ou referenciar um item colocado em outro ponto da página.

Fonte: [Finding Text Across Columns](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/finding-text-columns.html)

### Criar uma página de Faceted Search manualmente no Page Designer

1. Tenha uma região de resultados (ex.: Classic Report sobre `EMP`).
2. Crie uma região **Search** com *Type = Faceted Search* e *Source > Filtered Region* = região de resultados; Template Options *Remove Body Padding* e cabeçalho *Hidden but accessible*.
3. Ajuste o facet `Px_SEARCH` (*Database Column(s)*).
4. Adicione facets (botão direito em *Facets* › *Create Facet*): por exemplo `Px_DEPTNO` (Checkbox Group, LOV SQL `select dname, deptno from dept`), `Px_MGR` (LOV Shared Component), `Px_JOB` (Distinct Values), `Px_SAL` (Range, *Select Multiple*, LOV estática de faixas).
5. Layout: Search com *Column* 1 e *Column Span* 3; relatório com *Start New Row* desligado.
6. Botão **Reset**: região Static Content com template *Buttons Container*, botão `RESET` com ícone `fa-undo`, *Action = Redirect to Page in this Application* para a própria página, *Clear Cache* = a página e *Action = Reset Regions*.

O caminho pelo assistente é mais simples e já cria chips, contagem e gráficos.

Fonte: [Creating a Faceted Search Manually](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-a-faceted-search-manually.html)

---

## 11. Smart Filters

### Smart Filters: o que é, quando usar e diferenças para Faceted Search

A região **Smart Filters** dá o poder do Faceted Search num **único campo de busca** no topo, deixando a largura toda para os resultados. Filtra Classic Report, Cards, Map, Calendar, Content Row, Template Components e plug-ins com suporte a facets. Os filtros aparecem como **suggestion chips** (com contagem quando o filtro suporta, como os baseados em LOV); clicar no nome abre a lista de valores; clicar à direita do nome aplica a sugestão e o chip vai para a área de filtros aplicados; o "x" remove. Ao digitar, aparecem sugestões de valores de filtros que casam com o texto (ex.: `cl` → Job: CLERK, Manager: CLARK) e Enter busca o texto nas colunas do filtro Search.

Diferenças: há sempre **um** filtro do tipo Search (obrigatório); tipos de filtro são Checkbox Group, Input Field, Radio Group, Range e Search (sem Select List); os assistentes só criam o resultado como Classic Report ou Cards — Map e Calendar precisam ser montados à mão. Contagens, Range, dependência e colunas multivaloradas funcionam como no Faceted Search.

Com breadcrumbs ligados no Create Page Wizard, a região Smart Filters vai para o container do Breadcrumb (fica sempre no topo); sem breadcrumbs, vai para o Body.

Fonte: [Managing Smart Filters](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-smart-filters.html), [About Creating Smart Filters Pages](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-creating-smart-filters-pages.html), [Smart Filters User Experience](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/smart-filters-user-experience.html), [More Space for Results with Smart Filters](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/more-space-results-smart-filters.html)

### Smart Filters: sugestões (Suggestions Type e Maximum Suggestion Chips)

Quando nenhum filtro está aplicado, a região mostra chips de sugestão. Para cada filtro além do Search, *Suggestions > Type*:

- **Dynamic**: primeiro valor visível da LOV (com contagem, é o mais frequente; sem contagem, o primeiro na ordem).
- **Static Values**: valor fixo (ex.: `2000|2500` num Range mostra "Salary 2,000 - 2,500 (1)").
- **SQL Query**: sugestão calculada, por exemplo usando `:APP_USER`.
- **None**: sem sugestão.

O valor sugerido precisa ser um dos *return values* da LOV do filtro. *Maximum Suggestion Chips* na região limita os chips (vazio = até cinco, um por filtro com sugestão); `0` desliga.

Fonte: [Configuring Suggestions](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configuring-suggestions.html), [Editing a Smart Filters Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-a-smart-filters-page.html)

### Smart Filters: atributos de filtro (Client-Side Filtering, Depending On) e posição na barra de navegação

- **List Entries > Client-Side Filtering**: campo de busca acima da lista de valores do filtro.
- **Depending On > Filter**: o filtro só aparece depois que o filtro do qual depende recebe valor.
- **Mais espaço**: coloque a região na barra de navegação: *Parent Region* = No Parent, slot *Before Navigation Bar*, *CSS Classes* = `w100p`, de preferência com *Maximum Suggestion Chips* = 0.

Fonte: [Editing a Smart Filters Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-a-smart-filters-page.html), [Even More Space for Search Results](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/even-more-space-search-results.html)

### Criar uma página de Smart Filters manualmente

1. Região de resultados (Classic Report, Cards, Map ou Calendar).
2. Região com *Type = Smart Filters* (no Body ou na Breadcrumb Bar, que a mantém no topo), *Source > Filtered Region* = resultados; Template Options *Remove Body Padding* e cabeçalho *Hidden but accessible*; por exemplo *Column Span* 8.
3. Ajuste `Px_SEARCH` (*Database Column(s)*).
4. Botão direito em *Filters* › *Create Filter* para cada coluna (Checkbox Group com LOV Shared Component, Distinct Values, Range com faixas estáticas e *Select Multiple*…).

Fonte: [Creating a Smart Filters Page Manually](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-smart-filters-page-manually.html)

---

## 12. Search region, filtros em outras regiões e Query by Example

### Search region e Search Configurations: busca unificada em várias fontes

Para uma busca "estilo web" em várias fontes, crie uma **Search Configuration** (Shared Component) por tipo de dado: fonte local ou remota (tabela, SQL, entradas de lista APEX, REST Data Source), colunas pesquisáveis, mapeamento de papéis (*Primary Key*, *Title*, *Subtitle*, *Description*, *Badge*, *Icon*, até três *Custom Columns*) e *Link* para a página de detalhe. Conforme o tipo, o APEX faz filtro `LIKE`, busca de texto com Oracle Text ou Ubiquitous Search (Oracle AI Database 26ai), ou busca semântica com Vector Search.

Depois adicione uma região **Search** e referencie as configurações como *Search Sources*. O campo de busca pode ser o integrado ou um item seu (*Search Page Item*). Há ordenação, paginação, *Lazy Loading*, mensagens (*No Query Entered*, *No Results Found*) e *Use as Initial Result*.

Formatação: (1) CSS para mudanças simples; (2) **Result Row Template** na região (*Custom Layout*), com `&TITLE.`, `&SUBTITLE.`, `&DESCRIPTION.`, `&ICON.`, `&LINK.` etc. e template directives, que formata todas as fontes do mesmo jeito; (3) **Default Result Row Template** em cada Search Configuration (*Icon and Display*), usado a menos que a região defina o seu.

Para uma experiência totalmente própria, use `APEX_SEARCH.SEARCH` em qualquer região (detalhes no [10 · Workflows, automações, notificações e IA](./10-workflows-automacoes-notificacoes-e-ia.md) e no [06 · API PL/SQL](./06-api-plsql-nucleo.md)):

```sql
select *
  from table( apex_search.search(
                p_search_expression => :P31_SEARCH,
                p_search_static_ids => apex_t_varchar2('employees','departments'),
                p_apply_order_bys   => 'N' ) )   -- 'N' se você tiver ORDER BY próprio
 order by title
```

Fonte: [Unified Search Results Across Sources](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/unified-search-results-sources.html), [Defining a Search Configuration](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/defining-search-configuration.html), [Using Search Configurations](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-search-configurations.html), [Search Results Formatting Options](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/search-results-formatting-options.html), [Custom Unified Search Experience](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/custom-unified-search-experience.html), [Editing a Search Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-a-search-page.html)

### Mostrar em outra região os dados filtrados por Faceted Search, Smart Filters, IR ou IG

Para mostrar num gráfico ou mapa as mesmas linhas que o usuário filtrou num Cards (com Smart Filters, por exemplo), use as PKs dos resultados filtrados da região-fonte:

```sql
create or replace function region_pks(
    p_region_static_id in varchar2,
    p_pk_column_name   in varchar2 default 'ID')
return apex_t_number pipelined
is
    c_page_id constant number := v('APP_PAGE_ID');
    l_context apex_exec.t_context;
begin
    l_context := apex_region.open_query_context(
                    p_page_id   => c_page_id,
                    p_region_id => apex_region.get_id(
                                       p_page_id       => c_page_id,
                                       p_dom_static_id => p_region_static_id));
    while apex_exec.next_row(l_context) loop
        pipe row (apex_exec.get_number(l_context, p_pk_column_name));
    end loop;
    apex_exec.close(l_context);
    return;
exception
    when no_data_needed then
        apex_exec.close(l_context);
        return;
end region_pks;
```

Uso na região-alvo:

```sql
with result_pks as (
    select column_value as empno from table(region_pks('employees','EMPNO')) )
select ename, sal
  from result_pks
  join emp e using (empno)
```

Mantenha sincronizado com uma DA na região-fonte: evento **After Refresh** (Classic Report) ou **Page Change (Cards)**, ação *Refresh* na região-alvo.

Fonte: [Showing Filtered Data in Another Region](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/showing-filtered-data-another-region.html), [Getting Filtered Data Primary Keys](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/getting-filtered-data-primary-keys.html), [Using Filtered Data Primary Keys](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-filtered-data-primary-keys.html), [Refreshing the Target Region](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/refreshing-target-region.html)

### Query by Example com itens de página: filtros opcionais, multisseleção e Null Display Value

Itens de página também servem de critério de busca para outra região:

- **Item simples opcional**:
  ```sql
  (:P5_SELECTED_DEPARTMENT is null or deptno = :P5_SELECTED_DEPARTMENT)
  ```
- **Item multisseleção** (valores separados por `:`):
  ```sql
  (:P5_SELECTED_DEPARTMENTS is null
   or deptno in (select column_value
                   from apex_string.split(:P5_SELECTED_DEPARTMENTS, ':')))
  ```
- **Null Display Value** em Select List, Radio Group e Popup LOV (ex.: "<Todos>") deixa claro o que significa não escolher.
- Desligue **Warn on Unsaved Changes** (na página ou no item): critérios de busca mudam por definição e o aviso de alterações não salvas confunde o usuário.
- Liste os itens em **Page Items to Submit** da região filtrada.

Fonte: [Using Page Items for Query by Example](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-page-items-query-example.html), [Filtering on a Multi-Selection Page Item](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/filtering-multi-selection-page-item.html), [Using Null Display Value](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-null-display-value.html), [Disabling Warn on Unsaved Changes](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/disabling-warn-unsaved-changes.html)

### Query by Example com melhor desempenho: Function Body returning SQL Query

O padrão `(:ITEM is null or col = :ITEM)` é simples, mas o banco reaproveita o plano de execução calculado com os primeiros valores das binds; com vários filtros assim, o índice ideal pode não ser usado. Para melhor desempenho, **inclua o predicado só quando o item tiver valor**, montando a SQL numa *Function Body returning SQL Query*:

```plsql
return q'~
select empno, ename, sal, deptno, hiredate
  from emp
 where 1=1
~'
|| case when :P5_SELECTED_DEPARTMENT is not null then q'~
   and deptno = :P5_SELECTED_DEPARTMENT
~' end
|| case when :P5_ENAME_CONTAINS is not null then q'~
   and instr(upper(ename), upper(:P5_ENAME_CONTAINS)) > 0
~' end
|| case when :P5_MAX_SALARY is not null then q'~
   and sal <= :P5_MAX_SALARY
~' end;
```

Detalhes: o `where 1=1` permite que todo predicado comece com `and`; `q'~ … ~'` evita escapar aspas; `case` sem `else` devolve `null`, e concatenar `null` não altera a string. A SQL gerada **continua usando bind variables** (não concatene valores). Para manutenção, mova a montagem para uma função de package e chame-a da região. Liste os itens em *Page Items to Submit*. O APEX envolve seu código numa função `function x return varchar2 is begin … end;`.

**Pegadinha:** ao validar a sintaxe no Page Designer, todas as binds valem `null`, então o código precisa sempre devolver um `SELECT` válido nesse caso.

Fonte: [Optimal Approach to Query by Example](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/optimal-approach-query-example.html)

---

## 13. Charts (Oracle JET)

### Charts no APEX: integração com Oracle JET, bundles e modo debug

A região **Chart** usa as Data Visualizations do **Oracle JET** (JavaScript Extension Toolkit), com animação, acessibilidade, layout responsivo, internacionalização e interatividade. O APEX integra principalmente a parte de gráficos do JET; o *two-way data binding* (knockout.js) do JET **não** é usado nativamente.

O JET usa RequireJS para carregar só os módulos necessários; para evitar dezenas de requisições, o APEX entrega bundles otimizados em `/images/libraries/apex/minified/`:

- `chartBundle.min.js`: carregado quando há um gráfico JET na página (região Chart ou Interactive Grid) **fora** do modo debug.
- `jetCommonBundle.min.js`: carregado quando um arquivo JavaScript declara que precisa do JET com o prefixo `[require jet]` (útil em plug-ins: módulos já presentes no bundle não são buscados de novo).

Em **modo debug** os bundles não são usados e o RequireJS carrega cada recurso separadamente (a página fica mais lenta; é esperado).

Fonte: [Understanding Oracle JET Integration with Oracle APEX](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/Understanding-Oracle-JET-Integration-with-Oracle-Application-Express.html), [About Supported Charts](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-supported-charts.html)

### Tipos de gráfico e formas de criar (Create Application Wizard, Create Page Wizard, Dashboard, Page Designer)

Tipos nativos (18): Area, Bar, Box Plot, Bubble, Combination, Status Meter Gauge, Donut, Funnel, Gantt, Line, Line with Area, Pie, Polar, Pyramid, Radar, Range, Scatter e Stock.

| Método | Tipos disponíveis |
|---|---|
| Create Application Wizard › Chart | Area, Bar, Line, Pie |
| Create Application Wizard › Dashboard | Até 4 gráficos (Area, Bar, Line, Pie), cada um com tabela, *Label Column*, *Value Aggregation* (Column Value, Sum, Count) e *Value Column* |
| Create Page Wizard › Chart | Todos, exceto Range (Area, Bar, Box Plot, Bubble, Combination, Status Meter Gauge, Donut, Funnel, Gantt, Line, Line with Area, Pie, Polar, Pyramid, Radar, Scatter, Stock) |
| Create Page Wizard › Dashboard | Layout inicial com dados de exemplo: *Primary and 2 secondary charts*, *Grid of 4 charts*, *Primary and 3 secondary charts*, *Grid of 6 charts* |
| Page Designer (Gallery › Chart) | Qualquer tipo; você configura séries e eixos à mão |

Gantt, Status Meter Gauge e Stock têm **uma** série; os demais aceitam várias séries no mesmo gráfico. Para um dashboard, basta pôr vários gráficos na página e organizar no grid.

Fonte: [About Supported Charts](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-supported-charts.html), [Choosing a Chart Type](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/choosing-chart-type.html), [Creating a Dashboard Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-a-dashboard-page.html)

### Atributos de gráfico: Region, chart Attributes, Series, Column Mapping e Axes

Um gráfico tem três níveis:

1. **Region** (aba Region): título, layout, template, condição.
2. **Chart Attributes** (aba Attributes): *Chart > Type*, orientação, empilhamento (*stack*), legenda, tooltip, animação, zoom/scroll, *Automatic Refresh*, *Advanced > JavaScript Initialization Code*. No APEXlang: `chart`, `chartAppearance`, `chartLayout` (`maxWidth`, `height`), `settings` (`timeAxisType`, `zoomAndScroll`: `false`/`delayed`/`delayedScrollOnly`/`live`/`liveScrollOnly`, `zoomDirection`, `initialZooming`, `pieSelectionEffect`, `renderAs` do Stock…), `overview`, `legend`, `tooltip`, `dataCursor`, `animation`, `gauge`, `autoRefresh`.
3. **Series** (nós sob *Series*): cada série tem sua fonte (*Location*: Local Database, REST Enabled SQL, REST Source, Duality View, JSON Source, Sample Data; Table ou SQL), **Column Mapping** (*Label* = rótulos do eixo X — em Stock deve ser DATE/TIMESTAMP —, *Value*, e colunas extras conforme o tipo, como mínimo/quartis/mediana/máximo do Box Plot), agregação, ordenação, cor, rótulos e *Page Items to Submit*.

**Axes** (nó *Axes*, só em tipos com eixos: area, bar, bubble, combination, line, line with area, polar, radar, range, scatter, stock): título, mínimo/máximo, formato do valor, ticks.

Para mostrar nomes em vez de códigos, use SQL com JOIN e agregue na própria série:

```sql
select e.deptno, d.dname, sum(nvl(e.comm,0)) as total_commissions
  from emp e join dept d on d.deptno = e.deptno
 group by e.deptno, d.dname
-- Column Mapping: Label = DNAME, Value = TOTAL_COMMISSIONS; ordenar por DEPTNO
```

Fonte: [Editing Charts](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-charts.html), [Adding a Chart in Page Designer](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/adding-chart-in-page-designer.html), [Defining Chart Series](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/defining-chart-series.html), [Including Related Data on a Chart](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/including-related-data-chart.html)

### Trocar o tipo de um gráfico e combinar tipos de série

Mude *Attributes > Chart > Type* (ex.: para Combination) e revise **cada série**: os *Column Mapping* exigidos variam conforme o tipo, então confira se todas as colunas obrigatórias estão mapeadas. O atributo *Series > Type* (ex.: Bar Range) só aparece nos tipos que aceitam misturar séries no mesmo plot: **Combination, Polar, Radar e Range**.

Fonte: [Editing Charts](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-charts.html)

### Atualização automática de gráficos (Automatic Refresh) e dynamic action Refresh

- **Automatic Refresh > Interval** (segundos, APEXlang `autoRefresh.interval`): o gráfico se atualiza sozinho. Intervalos muito curtos (2 s) podem causar problemas sérios de desempenho no banco.
- **Dynamic action** com ação *Refresh*, *Affected Elements* = região do gráfico; com *Fire on Initialization* ligado, roda também ao carregar a página. Combine com *Page Items to Submit* na série.

Fonte: [Editing Charts](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-charts.html)

### JavaScript Initialization Code de gráficos (dataFilter e opções do ojChart)

Em *Attributes > Advanced > JavaScript Initialization Code*, uma função recebe as opções do gráfico JET, altera e devolve. `options.dataFilter` é chamado quando os dados chegam e permite mexer nas séries:

```js
function( options ) {
    options.dataFilter = function( data ) {
        data.series[ 0 ].color = "red";   // primeira série em vermelho
        return data;
    };
    options.type = "line";                // altera o tipo na inicialização
    return options;
}
```

As opções válidas são as do componente **ojChart** do Oracle JET (consulte o JSDoc do JET).

Fonte: [Editing Charts](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-charts.html)

### Gráfico em APEXlang: região, série e eixos

Exemplo real do projeto (p20, Dashboard RH), resumido:

~~~text
region grafico_promocoes (
    name: Promoções por departamento
    type: chart
    chartAppearance { orientation: horizontal }
    chartLayout { height: 360 }
    legend { show: false }
    messages { whenNoDataFound: Nenhuma promoção no período. }

    series promoções (
        name: Promoções
        source {
            type: sqlQuery
            sqlQuery: ```sql
                select coalesce(d.nome, '(sem departamento)') as departamento,
                       count(*) as promocoes
                  from vw_movimentacao_valida v
                  left join departamento d on d.id_departamento = v.id_departamento_novo
                 where v.id_empresa = :G_ID_EMPRESA
                   and v.dt_efetiva between to_date(:P20_DT_INICIO,'DD/MM/YYYY')
                                        and to_date(:P20_DT_FIM,'DD/MM/YYYY')
                 group by d.id_departamento, d.nome
                ```
            pageItemsToSubmit: [ P20_DT_INICIO  P20_DT_FIM ]
        }
        columnMapping { label: DEPARTAMENTO  value: PROMOCOES }
        label { show: true  position: outsideBarEdge }
    )
    axis y ( name: y  title: Promoções  value { min: 0  decimalPlaces: 0 } )
)
~~~

Note que *Page Items to Submit* fica na **série**, não na região.

Fonte: [APEXlang API Reference — region, series e axis](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

---

## 14. Map, Calendar, Tree e Dynamic Content

### Map region: camadas, geometrias, fundo e controles

A região **Map** desenha objetos espaciais sobre um mapa de fundo. Pode ter várias **layers**, cada uma com fonte própria (tabela, SQL, REST Enabled SQL, REST Data Source) ou herdada da região. Tipos de layer: **Points** (marcadores), **Lines**, **Polygons**, **Heat Map** (densidade de pontos) e **Extruded Polygons** (3D, altura por coluna). Geometria: coluna `SDO_GEOMETRY`, `VARCHAR2`/`CLOB` com GeoJSON, ou duas colunas numéricas de longitude e latitude (só Points e Heat Map). No Oracle AI Database 26ai, um ponto é `SDO_GEOMETRY(longitude, latitude)`; `SDO_UTIL.TO_GEOJSON` converte para GeoJSON.

Fundo: Oracle Elocation (sem API key, mas o navegador precisa acessar `https://maps.oracle.com`), inclusive camadas vetoriais (OpenStreetMap Positron, Bright, DarkMatter; ligadas por padrão em apps novos, e em apps anteriores ao 22.2 via *Component Settings*). Fundos próprios (Raster, Vector, OGC WMS) em *Shared Components > Map Backgrounds*.

Controles (`controls.options`): `mousewheelZoom`, `rectangleZoom`, `scaleBar`, `overviewMap`, `infiniteMap`, `getBrowserLocation`, `circleTool` (dispara evento para DA/JS), `distanceTool`; barra de navegação (`zoomOnly`, `zoomAndCompass`), legenda, tooltip (ex.: `&ENAME. - &ADDRESS.`), clustering de pontos e unidades (`metric`, `imperial`, por item). Para sincronizar um relatório com a área visível do mapa, guarde o *bounding box* num item oculto e filtre o relatório por ele (não funciona nos zooms 1 e 2, por limitação do Oracle Spatial quando o mapa mostra mais de meia Terra).

Fonte: [About Supported Maps](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-supported-maps.html), [Choosing a Map Layer Type](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/choosing-map-layer-type.html), [Simplifying Points and Distance](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/simplifying-points-and-distance.html), [Editing Maps](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-maps.html)

### Calendar region: eventos, links de criação/edição, drag and drop e JavaScript

Baseado na biblioteca **FullCalendar**. Fonte: tabela ou SQL com coluna de data inicial, final (opcional) e título. Views Month, Week, Day e List; eventos com ou sem duração (sem data final, aparece no dia; com *Show Time*, como evento de uma hora); tooltips; CSS por tipo de evento; download em PDF e compartilhamento iCal/CSV/XML; eventos de fontes externas.

- **Create Link**: abre uma página ao clicar numa data vazia ou arrastar um intervalo; passe `&APEX$NEW_START_DATE.` e `&APEX$NEW_END_DATE.` para os itens de data do formulário.
- **View/Edit Link**: ao clicar num evento; exige *Primary Key Column* e passa a PK (ex.: `PX_ID` = `&ID.`). A Oracle recomenda duas páginas separadas para criar e editar.
- **Drag and Drop** (só fontes locais): com *Primary Key Column* definida, ligue *Drag and Drop* e escreva o *Drag and Drop PL/SQL Code* usando `:APEX$PK_VALUE`, `:APEX$NEW_START_DATE` e `:APEX$NEW_END_DATE` (formato canônico):

```plsql
update emp_meetings
   set starts_at = to_date(:APEX$NEW_START_DATE, 'YYYYMMDDHH24MISS'),
       ends_at   = to_date(:APEX$NEW_END_DATE,   'YYYYMMDDHH24MISS')
 where id = :APEX$PK_VALUE;
```

- **Initialization JavaScript Code** (FullCalendar v5): `function(pOptions){ pOptions.slotMinTime = "07:00:00"; pOptions.weekNumbers = true; pOptions.locale = "en-gb"; pOptions.eventContent = function(arg){ return { html: ... }; }; return pOptions; }`. Calendários baseados em FullCalendar v3 estão **deprecated** e serão desuportados.
- **Eventos de DA**: *Date Selected [Calendar]* (dados `newStartDate`/`newEndDate`; não dispara se houver Create Link), *Event Selected [Calendar]* (JSON do evento; não dispara se houver Edit Link), *View Changed [Calendar]* (`viewType`, `startDate`, `endDate`).

Lembre de *Page Items to Submit* quando o `WHERE` usa itens (ex.: o calendário de um colaborador escolhido num select list, com DA de Refresh no *Change*).

Fonte: [About Calendars](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-calendars.html), [Managing Calendar Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-calendar-attributes.html), [About Dynamic Action Support for Calendar](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-dynamic-action-support-for-calendar.html), [Configuring a Basic Calendar](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configuring-basic-calendar.html), [Enhancing Event Display](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/enhancing-event-display.html)

### Tree region (APEX Tree): hierarquia, ícones e seleção lembrada

A região **Tree** usa o componente **APEX Tree** (JavaScript, navegação por teclado e estado opcional), só em UI Desktop. Os antigos jsTree foram desuportados e são convertidos automaticamente.

*Attributes > Settings*: **Node Label Column** (sem markup), **Node Value Column** (id acessível por JS), **Hierarchy**:
- **Computed with SQL**: o APEX gera a consulta hierárquica; informe **Node ID Column**, **Parent Key Column**, **Start Tree With** (ex.: *Value is NULL* = raízes com pai nulo; também item, SQL ou valor estático) e **Order Siblings By**.
- **Not Computed**: os dados já trazem a hierarquia; informe **Node Status Column** (0 = folha, 1 = tem filhos) e **Hierarchy Level Column**.

Também: *Tooltip*, *Link*/*Link Column*, **Icon CSS Class Column** (ex.: `'fa '||case job when 'MANAGER' then 'fa-users' … end`) e **Selected Node Page Item**.

**Lembrar a seleção**: item oculto (ex.: `P17_SELECTED_EMPNO`) com *Value Protected* = No e *Storage* = Per Session; *Selected Node Page Item* = esse item; DA no evento *Selection Changed [Tree]* com *Set Value* (JavaScript Expression `apex.region("emptree").call("getSelectedNodes")[0]?.id`, *Fire on Initialization* desligado) e, para gravar já na sessão, um passo *Execute Server-side Code* `null;` com o item em *Items to Submit*.

**Pai/filho de tabelas diferentes** num único tree: `UNION ALL` garantindo que os IDs não colidam (ex.: departamentos com `-1 * deptno`):

```sql
select -1 * deptno as node_id, dname as node_label, null as parent_key, 'fa fa-building-o' as icon from dept
union all
select empno, ename, -1 * deptno, icon from emp_with_icons_v
```

Fonte: [Managing Trees](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-trees.html), [Configuring a Basic Tree Display](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configuring-basic-tree-display.html), [Tracking and Remembering Selection](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/tracking-and-remembering-selection.html), [Adding Icons to the Tree](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/adding-icons-tree.html), [Parent/Child Data in a Tree](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/parent-child-data-tree.html)

### Dynamic Content region: HTML gerado por PL/SQL

Quando nenhuma região atende, a **Dynamic Content** executa um *PL/SQL Function Body* (ou JavaScript MLE) que devolve um `CLOB` com o HTML. Estilize com classes CSS (*Appearance > CSS Classes* + CSS inline da página) e atualize com DA *Refresh*, listando os itens usados em *Page Items to Submit*.

```plsql
declare
    l_content clob;
    procedure p(p_text varchar2) is begin l_content := l_content || p_text; end;
begin
    for j in (select ename, sal from emp where deptno = :P22_DEPARTMENT order by sal desc) loop
        p('<pre>' || apex_escape.html(j.ename) || ' | ' || j.sal || '</pre>');
    end loop;
    return l_content;
end;
```

**Escape:** o HTML devolvido entra na página como você o montou. Por segurança, escape todo dado vindo do banco ou do usuário (por exemplo com `apex_escape.html`, ver [05 · Segurança](./05-seguranca.md)) antes de concatenar.

Fonte: [Dynamically Formatting Data](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/dynamically-formatting-data.html), [Generating HTML Tags to Present Data](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/generating-html-tags-present-data.html), [Referencing Page Item Values](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/referencing-page-item-values.html)

---

## 15. Impressão e exportação

### Impressão de relatórios: Native, Document Generator, BI Publisher, APEX Office Print e Apache FOP

Classic Report, IR e IG exportam nativamente para PDF, Excel (XLSX), HTML e CSV. Formatos e layouts avançados exigem um servidor de impressão:

| Opção | Descrição |
|---|---|
| None (Native) | Sem servidor externo: CSV, HTML, PDF, XLSX básicos. Sem layouts personalizados. |
| Oracle Document Generator Pre-built Function | JSON → PDF/Office com templates Office próprios. Só configurável na instância; na aplicação, use *Use Instance Settings*. |
| Oracle BI Publisher / Analytics Publisher | Licenciado; XML → RTF/PDF/XLS/XML com templates RTF ou XSL-FO. |
| APEX Office Print | JSON → PDF/Office com templates Office. |
| External (Apache FOP) | XSL-FO num servidor J2EE externo. |

Na aplicação: *Application Definition > Report Printing > Print Server Type* (`Native Printing`, `Remote Print Server`, `Use Instance Settings`), que sobrepõe a configuração da instância. Servidor externo exige *network services* liberados no banco.

**Limites do PDF/Excel nativo**: no PDF, uma linha do relatório pode ocupar várias linhas de texto e ter no máximo uma quebra de página; o que passar disso é truncado. No Excel, cada célula aceita até 32k de texto; o excedente é truncado.

Fonte: [Printing Report Regions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/printing-report-regions.html)

### Classic Report: Printing Attributes, Report Queries e Report Layouts

Duas formas de imprimir um Classic Report: (1) *Attributes > Printing > Enabled* = On e configurar a aba *Printing* (vale só para aquela região); (2) **Report Query** em Shared Components (tabela, SQL — não função que retorna SQL — ou REST Data Source), reutilizável. Formatos: PDF, RTF, Excel (com BI Publisher e layout customizado não é um `.xls` real, é HTML), HTML, XML. O formato pode vir de um item com valores `PDF`, `RTF`, `XLS` ou `HTML`. Sem **Report Layout** associado, usa-se um layout XSL-FO padrão.

Limite com servidor externo: cabeçalho do template limitado a 32k, o que suporta cerca de 26 colunas ou menos, dependendo do tamanho dos aliases. Detalhes de report queries e PDF em [11 · Dados, REST, arquivos e PDF](./11-dados-rest-arquivos-e-relatorios-pdf.md).

Fonte: [Printing Report Regions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/printing-report-regions.html), [Oracle APEX Limits](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/oracle-apex-limits.html)

---

## 16. Desempenho de relatórios

### Lazy Loading de regiões de relatório

*Performance > Lazy Loading* (APEXlang `performance.lazyLoading`, padrão `false`) faz a página renderizar imediatamente e carregar os dados da região depois, por AJAX. Sem lazy loading, a página só aparece quando todas as regiões terminaram (uma região de 5 s atrasa a página inteira 5 s). Disponível em IR, Classic Report (com Partial Page Refresh ligado), IG, Cards, Map, Search e regiões que declaram suporte. Use em regiões lentas ou abaixo da dobra; evite quando o conteúdo precisa estar no HTML inicial.

Fonte: [Editing a Search Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-a-search-page.html), [APEXlang API Reference — region](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Maximum Rows to Process, Maximum Rows to Display e contagem total

- **Maximum Rows to Process** (`performance.maxRowsToProcess`): limita as linhas lidas da consulta em Classic Report e IR (no IR, só quando *Maximum Rows to Display* está vazio).
- **Maximum Rows to Display** (IR, *Pagination*): máximo exibido depois de aplicadas as configurações do usuário.
- **When More Data Found** (*Messages*): mensagem quando o limite é atingido.
- **Contagem total**: estilos "X to Y of Z" (Classic/IR) e *Show Total Row Count* (IG, Faceted Search) exigem uma query extra. Em conjuntos muito grandes, prefira "X to Y" e scroll sem total.

Fonte: [Controlling Interactive Report Pagination](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/controlling-interactive-report-pagination.html), [Controlling Interactive Grid Pagination](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/controlling-interactive-grid-pagination.html), [APEXlang API Reference — region](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Boas práticas de desempenho em IR, IG, Faceted Search e gráficos

- **Filtros de coluna**: definir uma LOV no *Column Filter* acelera os filtros embutidos; em colunas longas use *LOV Type = None*. O IR mostra no máximo 999 valores por filtro de cabeçalho quando não há LOV própria.
- **Sort / Control Break / Aggregate**: liberar para todas as colunas pode custar caro em tabelas grandes sem índice; libere só onde faz sentido.
- **IG em massa**: cascading LOVs e DAs de servidor tornam lento paste/copy down/fill/clear; calcule no cliente e recalcule no servidor ao salvar.
- **Query by Example**: Function Body returning SQL com predicados condicionais em vez de `(:X is null or col = :X)` repetido.
- **Facets**: *Trim Whitespace* em colunas multivaloradas custa caro; LOVs de facet acima de 5.000 valores são cortadas.
- **Gráficos**: *Automatic Refresh* com intervalo muito curto sobrecarrega o banco; gráfico de IR renderiza até 10.000 pontos.
- **Downloads** grandes demoram; restrinja com *Download Authorization* quando preciso.
- **Consultas lentas**: a maioria dos problemas vem do SQL/PL/SQL do desenvolvedor. Rode a página em debug para achar a região lenta e teste a query fora do APEX (SQLcl, SQL Developer, SQL Commands). Para consultas caras que o usuário pagina e filtra muito, a Oracle sugere guardar o resultado numa **collection**, executando a consulta cara uma vez por usuário; e considere desligar *Enable duplicate page submissions* para evitar reenvios que abrem novas sessões e podem gerar locks (situação comum com IR).
- **Optimizer Hint** (`source.optimizerHint`) está disponível na fonte da região.

Fonte: [Managing Interactive Grid Column Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-interactive-grid-column-attributes.html), [Getting to Know the Interactive Grid](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/getting-know-interactive-grid.html), [Identifying Performance Issues](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/identifying-performance-issues.html), [Oracle APEX Limits](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/oracle-apex-limits.html)

---

## 17. O que o usuário final consegue fazer (IR e IG)

### Interactive Report pelo usuário final: busca, menu de cabeçalho e Actions menu

- **Barra de busca**: lupa *Columns to search* (restringe a uma coluna; *Row Search* volta a todas), campo de busca (sem distinção de maiúsculas, curingas implícitos), lista de relatórios, ícones de view (Report, Icon, Detail, Chart, Group By, Pivot) e Actions menu.
- **Menu de cabeçalho da coluna**: ordenar asc/desc, esconder coluna (volta com *Reset*), control break, informação da coluna (help text) e filtro rápido (escolhe um valor da lista, criando filtro `=` ou *contains* conforme o *Column Filter Type*).
- **Filtros** aparecem entre a barra e o relatório: checkbox liga/desliga, clicar no nome edita, "x" remove, seta recolhe detalhes. Dois tipos: **Column** (coluna + operador + expressão) e **Row** (expressão livre com aliases de coluna e funções Oracle, com `AND`/`OR`, ex.: `I >= 2500`).
- **Actions menu**: *Columns*; *Filter*; *Data* (Sort com tratamento de nulos, Aggregate — Sum, Average, Count, Count Distinct, Minimum, Maximum, Median —, Compute — coluna nova com expressão sobre aliases, ex.: `I - H`, e máscara —, Flashback); *Format* (Control Break, Highlight de linha ou célula com cores e condição, Rows Per Page); *Chart* (um por relatório: Bar, Line with Area, Pie, Line; rótulo, valor, função, orientação, ordenação); *Group By* (colunas + funções; tem *Group By Sort*); *Pivot* (colunas pivô, linhas e funções); *Report* (Save Report, Reset); *Download*; *Subscription*; *Help*.
- **Flashback**: padrão de 3 horas (180 minutos), mas o alcance real depende do banco.
- **Assinatura**: formato, e-mails (separados por vírgula), assunto, frequência, *Skip if No Data Found*, início e fim. Requer e-mail configurado na instância e *Subscription* e *Download* ligados pelo desenvolvedor. A assinatura gerada pelo sistema no e-mail não pode ser removida.

Fonte: [Using Interactive Reports](https://docs.oracle.com/en/database/oracle/apex/26.1/aeeug/using-interactive-reports.html), [About the Actions Menu](https://docs.oracle.com/en/database/oracle/apex/26.1/aeeug/about-the-actions-menu.html), [Adding a Filter](https://docs.oracle.com/en/database/oracle/apex/26.1/aeeug/adding-a-filter.html), [Computing Columns](https://docs.oracle.com/en/database/oracle/apex/26.1/aeeug/computing-columns.html), [Executing a Flashback Query](https://docs.oracle.com/en/database/oracle/apex/26.1/aeeug/executing-flashback-query.html), [Subscribing to Report Updates by Email](https://docs.oracle.com/en/database/oracle/apex/26.1/aeeug/subscribing-to-report-updates-email.html)

### Interactive Report pelo usuário final: salvar, resetar e baixar

- **Salvar**: *Actions > Report > Save Report* → nome, descrição e *Public* (se o desenvolvedor permitir). Desenvolvedores veem também *As Named Report* / *As Default Report Settings*.
- **Lista de relatórios**: "Default - Primary Report" (não renomeia nem exclui), "Private - …" (só o criador), "Public - …" (todos veem; só o criador altera; outros salvam cópia).
- **Renomear**: clicar no filtro do relatório salvo; **Excluir**: "x" ao lado do nome.
- **Reset**: *Actions > Report > Reset* remove as personalizações.
- **Download**: CSV, HTML, Excel ou PDF (PDF nativo com tamanho, orientação e *Include Accessibility Tags*), *Data Only* (ignora quebras, highlights etc.) e *Send as Email* (To, Cc, Bcc, Subject, Body).

Fonte: [Saving an Interactive Report](https://docs.oracle.com/en/database/oracle/apex/26.1/aeeug/saving-an-interactive-report.html), [Resetting a Report](https://docs.oracle.com/en/database/oracle/apex/26.1/aeeug/resetting-a-report.html), [Downloading a Report](https://docs.oracle.com/en/database/oracle/apex/26.1/aeeug/downloading-a-report.html)

### Interactive Grid pelo usuário final: busca, colunas, filtros, agregações, gráfico e relatórios

- **Interface**: barra de busca, Actions menu, botão Reset e menus de cabeçalho de coluna.
- **Busca**: lupa para escolher a coluna e *Case Sensitive*; a busca só funciona em colunas de texto (não em número/data); "All Text Columns" volta ao padrão.
- **Colunas**: arrastar pela alça do cabeçalho, redimensionar pela borda, *Columns* (exibir/ocultar, ordem, largura mínima), *Stretch Column Widths* (a grade ocupa a largura da tela).
- **Menu de cabeçalho**: ordenar, Control Break, Aggregate, **Freeze** (coluna fora da área rolável; desfaz pelo ícone de floco de neve), Hide e filtro de texto com lista de valores.
- **Actions**: *Filter* (Row: texto em qualquer coluna filtrável, com *Case Sensitive*; Column: coluna, operador, valor), *Data* (Sort com nulos First/Last, Aggregate com *Tooltip* e *Show Overall Value*, Refresh, Flashback em minutos), *Format* (Control Break com direção e nulos, Highlight de linha ou coluna com condição, Stretch), *Selection*, *Chart* (um por vez; Bar com orientação, rótulo, valor e agregação: Count, Count Distinct, Approx. Count Distinct, Min, Max, Sum, Average), *Report*, *Download*.
- **Relatórios**: *Report > Save As* (Private), *Save*, *Edit* (renomear), *Delete*. Depois do primeiro relatório salvo aparece a lista na toolbar.
- **Reset** volta ao último estado salvo (no Primary, desfaz tudo; num Private, só o que mudou desde o último save). **Refresh** busca os dados atuais sem recarregar a página. **Flashback** mostra os dados de N minutos atrás.

Fonte: [About Interactive Grids](https://docs.oracle.com/en/database/oracle/apex/26.1/aeeug/what-is-interactive-grid.html), [Customizing an Interactive Grid with the Column Heading Menu](https://docs.oracle.com/en/database/oracle/apex/26.1/aeeug/using-column-heading-menu.html), [Filtering an Interactive Grid](https://docs.oracle.com/en/database/oracle/apex/26.1/aeeug/filtering-interactive-grid.html), [Saving an Interactive Grid](https://docs.oracle.com/en/database/oracle/apex/26.1/aeeug/saving-an-interactive-grid.html), [Resetting Interactive Grids](https://docs.oracle.com/en/database/oracle/apex/26.1/aeeug/resetting-interactive-grid.html), [Using Charts in an Interactive Grid](https://docs.oracle.com/en/database/oracle/apex/26.1/aeeug/using-charts-interactive-grid.html)

### Interactive Grid editável pelo usuário final: edição, seleção e atalhos

- **Edit mode**: botão *Edit*, duplo clique, Enter ou F2. Tab/Shift+Tab move na linha; Enter/Shift+Enter move na coluna; Esc sai. Com *Edit* ligado, um clique edita; desligado, é preciso duplo clique (facilita navegar em grades grandes).
- **Linhas**: *Add Row* (botão ou *Row Actions*; a linha nova entra no topo ou abaixo da selecionada), Duplicate, Delete (riscada até salvar), Refresh, Revert, *Single Row View* (com Previous/Next e opções *Exclude Null Values* e *Display Values*).
- **Seleção**: *Row Selection* (padrão, checkboxes; Shift+setas para intervalos) ou *Cell Selection* (F8). O *Selection Actions* do cabeçalho tem Copy, Cut, Paste, Paste Insert, Duplicate, Delete, Refresh, Revert, Copy Down, Fill e Clear. Copy, Cut, Copy Down, Fill e Clear funcionam também em seleção de células; Paste e Paste Insert agem na célula corrente.
- **Copy Down**: copia a primeira linha/célula selecionada para as demais (por coluna). **Fill**: aplica um valor a um bloco contíguo de células. **Clear**: esvazia células contíguas. **Revert Changes** desfaz por linha inteira.
- **Clipboard**: só fora do edit mode; colar de planilha (HTML funciona bem; arrastar com Shift insere); colar além do fim da página só insere linhas na última página; LOV precisa do valor de retorno; o navegador pode pedir permissão.
- **Save** grava as alterações.

Fonte: [About Editable Interactive Grids](https://docs.oracle.com/en/database/oracle/apex/26.1/aeeug/about-editable-interactive-grids.html), [Editing Rows in an Interactive Grid](https://docs.oracle.com/en/database/oracle/apex/26.1/aeeug/editing-rows-interactive-grid.html), [Modifying Multiple Rows and Cells in an Editable Interactive Grid](https://docs.oracle.com/en/database/oracle/apex/26.1/aeeug/modifying-cells-rows-interactive-grid.html)

---

## 18. Relatórios legados

### Legacy Tabular Forms: como funcionam e por que migrar para Interactive Grid

Tabular forms são componentes **legados**: os existentes continuam suportados, mas **criar novos foi desuportado**. A Oracle recomenda Interactive Grid. Como funcionam:

- Consulta SQL com colunas ligadas às colunas da tabela; os dados **não** vão para session state.
- Dois processos: **Multi Row Update (MRU)** (insere e altera) e **Multi Row Delete (MRD)** (exclui as linhas marcadas no *row selector*, identificadas pelo número da linha). A PK precisa estar na query, como coluna Hidden ou Display Only (save state); linhas novas têm PK nula.
- **Checksum por linha** (lock otimista) numa coluna oculta: se o dado mudou no banco desde a renderização, a gravação é rejeitada.
- Limites: um tabular form gerado por assistente por página; até 50 colunas editáveis (`apex_application.g_f01` a `g_f50`). Em validações e processos, `:APEX$ROW_NUM` e `:APEX$ROW_SELECTOR`.
- Boas práticas: não altere a lista do SELECT de um tabular form existente (os valores atualizáveis não podem mudar depois de consultados); não adicione JavaScript próprio a tipos de exibição que já têm lógica JS (radio, checkbox simples, popup key LOV).

Componentes legados aparecem na Gallery do Page Designer via *Gallery Menu › Show Legacy Components*. O APEXlang ainda lista tipos de região como `tabform`, `legacyCalendar`, `simpleChart` e `svgChart`, mas para telas novas use os componentes atuais.

Fonte: [Managing Legacy Tabular Forms](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-tabular-forms.html), [Managing Application Legacy Components](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-app-legacy-components.html), [Viewing Legacy Components in the Gallery](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/viewing-legacy-components-gallery.html), [Oracle APEX Limits](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/oracle-apex-limits.html)

---

## 19. Problemas conhecidos e troubleshooting

### Relatório volta sem dados (ou com dados velhos) depois de um Refresh por AJAX

**Sintoma:** ao mudar um select list e disparar *Refresh*, o relatório/gráfico/calendário mostra "No data found" ou continua com o filtro anterior; ao recarregar a página inteira, funciona.
**Causa:** a query referencia itens de página como bind variables, mas eles não estão em *Page Items to Submit*. No refresh, o servidor usa o valor de session state (geralmente nulo).
**Correção:** liste os itens em *Source > Page Items to Submit* da região (no gráfico, na **série**), sem dois-pontos, separados por vírgula.
**Prevenção:** sempre que escrever `:P<n>_ITEM` numa fonte de região, adicione o item em *Page Items to Submit* na mesma hora.

Fonte: [Visualizing and Analyzing Data](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/visualizing-and-analyzing-data.html), [Filtering on a Page Item's Value](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/filtering-page-items-value.html)

### Interactive Report com condição de exibição por :REQUEST funciona de forma errada

**Sintoma:** o IR aparece, mas paginação, filtros e ordenação falham ou o relatório some depois da primeira ação.
**Causa:** o IR usa AJAX o tempo todo; nas chamadas AJAX o `REQUEST` não é o da submissão original, então uma *Server-side Condition* baseada em `:REQUEST` é avaliada de outro jeito.
**Correção:** baseie a condição num **item de página** cujo valor esteja em session state.

Fonte: [Managing Interactive Report Region Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-interactive-report-region-attributes.html)

### Filtro do menu de cabeçalho falha numa coluna de IR cujo link é montado no SQL

**Sintoma:** ao filtrar pelo menu de cabeçalho numa coluna com `<a href…>` gerado na query, o filtro não funciona e a lista de valores mostra links.
**Causa:** os valores da coluna já são links, e o menu de cabeçalho não consegue renderizá-los como valores clicáveis para criar o filtro.
**Correção:** (1) acrescente na query uma coluna só com o texto do link (alias `my_link_display`), torne a coluna do link *Hidden*, e na coluna de texto use HTML Expression `#MY_LINK#` com o mesmo cabeçalho e *Escape Special Characters* ligado; reordene e salve como relatório padrão. Ou (2) defina um *Column Filter* personalizado que consulte o texto do link.
**Prevenção:** prefira links declarativos (*Type = Link*) a HTML montado no SQL.

Fonte: [Managing Interactive Report Column Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-interactive-report-column-attributes.html)

### Coluna BLOB aparece como [unsupported data type] no relatório

**Sintoma:** Classic Report ou IR mostra `[unsupported data type]`.
**Causa:** colunas BLOB não são exibidas diretamente.
**Correção:** fonte em SQL Query, coluna numérica `dbms_lob.getlength(blob)`, tipo *Download BLOB* ou *Display Image* e *BLOB Attributes* (tabela, coluna BLOB, PK, mime type, nome do arquivo, última alteração). No IG não há suporte a BLOB: use IR/Cards ou um formulário.

Fonte: [Understanding BLOB Support in Forms and Reports](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-blob-support-in-forms-and-reports.html)

### Link para Interactive Report ou Interactive Grid dá erro numa página com mais de um relatório

**Sintoma:** um link `f?p=…:::::ENAME:KING` ou `IR_REPORT_x` que funcionava passa a dar erro depois que outra região IR/IG foi adicionada à página de destino.
**Causa:** sem *Request* e sem o filtro qualificado pelo HTML DOM ID, o APEX não sabe em qual região criar o filtro. A sintaxe antiga só vale com um único IR/IG na página; dois *Requests* separados por vírgula com filtro não qualificado também falham.
**Correção:** dê *Static ID* às regiões e qualifique: `IR[EMP]_ENAME:KING`, `IG[EMP]C_ENAME:KING`, `IR[EMP]_dept20`.
**Prevenção:** use sempre a sintaxe qualificada, mesmo com um único relatório.

Fonte: [Linking to Interactive Reports](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/linking-to-interactive-reports.html), [Linking to Interactive Grid Reports](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/linking-to-interactive-grid-reports.html)

### Opção Download, Email ou Subscription não aparece no Actions menu

**Sintoma:** o menu não mostra Download, ou o diálogo não oferece *Send as Email*, ou a assinatura não existe.
**Causa:** (a) nenhum formato marcado em *Download Formats* — o item Download só aparece com pelo menos um formato; (b) formato depende de servidor de impressão não configurado; (c) e-mail só para usuários autenticados (em página pública some) e exige SMTP configurado pelo administrador da instância; (d) *Subscription* exige *Download* ligado e e-mail na instância; (e) *Download Authorization* falhou para o usuário.
**Correção:** revise *Actions Menu > Download*, *Download > Formats*, *Send as Email*, a authorization e a configuração de e-mail da instância.

Fonte: [Configuring Interactive Report Download Options](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-interactive-report-download-options.html), [Subscribing to Report Updates by Email](https://docs.oracle.com/en/database/oracle/apex/26.1/aeeug/subscribing-to-report-updates-email.html)

### CSV baixado do relatório fica inválido ou com caracteres errados

**Sintoma:** o CSV abre com uma linha estranha no topo ou com acentuação errada.
**Causa:** *Supplemental Text* preenchido (o texto entra no topo e invalida o CSV); *Automatic CSV Encoding* desligado na Globalização; separador dependente do NLS.
**Correção:** deixe *Supplemental Text* vazio quando CSV estiver habilitado, ligue *Automatic CSV Encoding* e defina *CSV Separator* explicitamente se necessário.

Fonte: [Configuring Interactive Report Download Options](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-interactive-report-download-options.html), [Managing Classic Report Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-classic-report-attributes.html)

### Usuários não conseguem salvar relatórios no IR ou IG

**Sintoma:** não há *Save Report*/*Save As*, ou só aparece a opção privada.
**Causa:** a aplicação não tem authentication scheme (salvar exige usuário autenticado); IR com *Save Report* desligado ou sem *Reports Select List*; IG com toolbar desligada (some o Actions menu inteiro); salvar públicos exige *Save Public Report* ligado e a authorization correspondente.
**Correção:** ligue os atributos correspondentes e confira a authorization.

Fonte: [Customizing Interactive Reports in a Running Application](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/customizing-interactive-reports-as-an-end-user.html), [Saving Interactive Grid Reports](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/saving-interactive-grids-reports.html)

### Faceted Search ou Smart Filters: LOV cortada em 5.000 valores ou erro com muitos itens

**Sintoma:** o facet não mostra todos os valores; como desenvolvedor aparece erro de execução.
**Causa:** LOVs e *Distinct Values* de facets/filtros são cortadas silenciosamente em **5.000** itens. Logado como desenvolvedor, o APEX levanta erro acima de **4.000** itens no Faceted Search e acima de **2.000** no Smart Filters, sinalizando que a lista é grande demais para ser útil.
**Correção:** use um facet *Search* ou *Input Field* para essa coluna, agrupe os valores (Range) ou reduza a LOV.

Fonte: [Editing a Faceted Search Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-faceted-search-page.html), [Editing a Smart Filters Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-a-smart-filters-page.html)

### Faceted Search: dynamic action num facet não dispara

**Sintoma:** uma DA de *Change* configurada para um facet Checkbox Group ou Select List não funciona.
**Causa:** facets e filtros não são itens de página, ainda que tenham o mesmo padrão de nome e tipos com nomes iguais; a maioria das DAs não se aplica a eles.
**Correção:** reaja aos eventos da região de resultados (por exemplo *After Refresh* do Classic Report ou *Page Change* do Cards) ou use a API JavaScript `facetsRegion` (ver [08 · API JavaScript](./08-api-javascript.md)).

Fonte: [Editing a Faceted Search Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-faceted-search-page.html)

### Faceted Search: mudança em Display Chart for Top N Values não aparece

**Sintoma:** você alterou *Display Chart for Top N Values*, mas o gráfico do facet continua igual.
**Causa:** o conjunto de gráficos visíveis fica guardado no *session storage* do navegador.
**Correção:** resete a região (botão Reset da página) para ver a mudança.

Fonte: [Editing a Faceted Search Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-faceted-search-page.html)

### Facet sobre coluna com vários valores dá erro

**Sintoma:** facet com *Multiple Values* levanta erro.
**Causa:** o recurso exige Oracle Database 12.2 ou superior; com *JSON Array*, dados com JSON inválido também geram erro; aspas duplas e barra invertida não são aceitas como separador.
**Correção:** confira a versão do banco, o formato dos dados e o separador.

Fonte: [Editing a Faceted Search Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-faceted-search-page.html)

### Interactive Grid: linhas somem ou se confundem ao salvar porque a chave muda

**Sintoma:** depois de salvar, o IG mostra linhas erradas, perde a linha editada ou atualiza o registro errado (típico em IG sobre `APEX_COLLECTIONS` usando `SEQ_ID`).
**Causa:** o model do IG exige uma PK que **nunca muda**; só a troca da chave temporária de linhas novas pela chave do banco é permitida. `SEQ_ID` de coleções é renumerado.
**Correção:** gere um identificador estável (`SYS_GUID()`) numa coluna da coleção (ex.: `C002`), marque-o como Primary Key e grave por API PL/SQL (*Target Type = PL/SQL Code*), devolvendo a chave nova em `:ID` no `case :APEX$ROW_STATUS when 'C'`.

Fonte: [Editing Collection Data with a Grid](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/editing-collection-data-grid.html)

### Interactive Grid: paste, fill e copy down muito lentos

**Sintoma:** colar várias linhas ou usar *Fill*/*Copy Down* demora muito.
**Causa:** cascading LOVs e dynamic actions que executam código no servidor são disparadas para cada linha alterada.
**Correção:** mova cálculos e validações para o cliente (JavaScript) e recalcule/valide no servidor ao salvar com um processo cujo *Editable Region* é o IG.

Fonte: [Getting to Know the Interactive Grid](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/getting-know-interactive-grid.html)

### Interactive Grid: valores colados em coluna LOV não são aceitos ou ficam errados

**Sintoma:** ao colar de uma planilha numa coluna Select List/Popup LOV, o valor fica inválido.
**Causa:** o IG grava o **valor de retorno** da LOV; colar o texto exibido não corresponde ao valor armazenado. O navegador também pode bloquear o acesso ao clipboard (HTTPS, permissão).
**Correção:** cole valores de retorno (ou copie de outro IG, que usa o formato JSON próprio preservando os valores) e conceda a permissão de clipboard.

Fonte: [Getting to Know the Interactive Grid](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/getting-know-interactive-grid.html), [About Editable Interactive Grids](https://docs.oracle.com/en/database/oracle/apex/26.1/aeeug/about-editable-interactive-grids.html)

### Interactive Grid: Icon View com itens desalinhados ou cortados

**Sintoma:** os ícones da Icon View ficam de tamanhos diferentes ou com conteúdo transbordando.
**Causa:** a Icon View exige que todos os itens tenham a mesma largura e altura e que o conteúdo não transborde.
**Correção:** defina largura e altura por CSS na classe `a-IconList-item`.

Fonte: [Enabling Icon View in an Interactive Grid](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/enabling-icon-view-in-an-interactive-grid.html)

### Interactive Grid: action save não funciona depois de esconder o botão Save

**Sintoma:** você desligou o *Save Button* da toolbar e agora `apex.region("x").call("getActions").invoke("save")` não grava nada.
**Causa:** desligar a opção declarativa só **esconde** a action `save`; actions ocultas ou desabilitadas não fazem nada.
**Correção:** deixe a opção declarativa ligada e remova o botão da toolbar via `toolbarData` no JavaScript Initialization Code; ou grave por submit da página.

Fonte: [JSDoc: Widget interactiveGrid](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/interactiveGrid.html)

### Opções do Interactive Grid definidas em JavaScript não têm efeito ou causam erro

**Sintoma:** `options.toolbar.searchField = false` gera "Cannot set properties of undefined", ou mudar `options` depois que a página carregou não muda nada.
**Causa:** o APEX não envia objetos aninhados com valores padrão, então `options.toolbar` pode não existir; e as opções do widget só valem na inicialização.
**Correção:** use `apex.util.getNestedObject(options, "toolbar").searchField = false;` dentro do *JavaScript Initialization Code* e devolva `options`. Depois da criação, use métodos, actions e eventos.

Fonte: [JSDoc: Widget interactiveGrid](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/interactiveGrid.html)

### Function Body returning SQL dá erro ao salvar a região no Page Designer

**Sintoma:** o Page Designer reclama da SQL de uma região *Function Body returning SQL Query*, embora em execução ela funcione.
**Causa:** na validação de sintaxe, todas as bind variables valem `null`; se nesse caso a função devolve SQL inválida (ex.: `where` sem predicado), a validação falha.
**Correção:** garanta que o código sempre retorne um `SELECT` válido, por exemplo com `where 1=1` e predicados `and …` opcionais.

Fonte: [Optimal Approach to Query by Example](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/optimal-approach-query-example.html)

### Pivot do Interactive Report não exporta em PDF

**Sintoma:** com a view Pivot ativa, o PDF não está disponível.
**Causa:** a view Pivot não suporta download em PDF, mesmo com o formato habilitado e servidor de impressão configurado.
**Correção:** exporte em outro formato ou volte à view Report para baixar o PDF.

Fonte: [Configuring Interactive Report Download Options](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-interactive-report-download-options.html)

### Mapa: relatório ligado ao bounding box não atualiza nos zooms mais afastados

**Sintoma:** o relatório sincronizado com a área visível do mapa não se atualiza nos níveis de zoom 1 e 2.
**Causa:** restrição do Oracle Spatial: o filtro por bounding box só funciona quando o mapa mostra menos de metade da Terra.
**Correção:** comportamento esperado; trate o caso (por exemplo, sem filtro espacial nesses níveis).

Fonte: [Editing Maps](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-maps.html)

### Calendar: Date Selected ou Event Selected não disparam

**Sintoma:** DA nos eventos *Date Selected [Calendar]* ou *Event Selected [Calendar]* nunca roda.
**Causa:** se o calendário tem *Create Link*, o *Date Selected* não é disparado; se tem *Edit Link*, o *Event Selected* não é disparado.
**Correção:** use links **ou** DAs para cada interação, não os dois.

Fonte: [About Dynamic Action Support for Calendar](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-dynamic-action-support-for-calendar.html)

### Página com gráfico fica lenta só em modo debug

**Sintoma:** com debug ligado, páginas com Chart ou IG carregam muito mais devagar e fazem dezenas de requisições de JS.
**Causa:** em debug, os bundles `chartBundle.min.js`/`jetCommonBundle.min.js` não são usados e o RequireJS carrega cada módulo do JET separadamente.
**Correção:** comportamento esperado; meça desempenho com debug desligado.

Fonte: [Understanding Oracle JET Integration with Oracle APEX](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/Understanding-Oracle-JET-Integration-with-Oracle-Application-Express.html)

### Interactive Grid sem seção Edit no Property Editor do 26.1.5 (divergência com a documentação)

**Sintoma:** no projeto, o `ai-context` registra que no Page Designer do 26.1.5 o painel de propriedades **não tem a aba "Attributes"** nem a seção *Edit*, e que IG/Form só ficam editáveis quando criados pelo assistente (bloco `edit { enabled: true … }` no export).
**Divergência:** a documentação oficial 26.1 descreve *Property Editor › aba Attributes › grupo Edit › Enabled = On* para tornar um IG existente editável, e o APEXlang documenta o grupo `edit` (`enabled`, `allowedOperations`…). Os dois não batem com o que o time observou na tela.
**Correção no projeto:** siga o `ai-context` (09 §4.8): crie a região editável pelo Create Page Wizard com *Editing Enabled* e confira no export que o bloco `edit {` veio; ou use lista (IR) + formulário modal. Caminhos do Builder não conferidos ficam marcados "(confirmar no 26.1.5)", e se o caminho não existir, peça um print.

Fonte: [Making an Existing Interactive Grid Editable](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/making-an-existing-interactive-grid-editable.html), [APEXlang API Reference — region](https://docs.oracle.com/en/database/oracle/apex/26.1/apxln/index.html)

### Gráfico JET com várias séries mostra rótulos fora de ordem (observado no projeto)

**Sintoma:** num gráfico com mais de uma série, os meses aparecem fora de ordem ("01/2026" antes de "11/2025"), ignorando o `order by` da query.
**Causa (registrada no `ai-context/08`):** o APEX junta os rótulos de todas as séries e os ordena como texto.
**Correção:** use rótulos que ordenem corretamente como texto, por exemplo `to_char(mes, 'yyyy/mm')` (padrão adotado no turnover da p20). A documentação oficial só diz que você pode configurar a ordenação de cada série; o comportamento acima é observação do time.

Fonte: [Including Related Data on a Chart](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/including-related-data-chart.html)

---

## 20. Aplicação no Corlix Hub

### Onde cada tipo de relatório aparece no Corlix Hub

Levantamento dos `.apx` em `corlixhub/pages/` (21/10/2026):

| Página | Regiões de dados | Observações |
|---|---|---|
| p1 Início | `cards` (`home_comunicados`, layout `horizontal`, mídia BLOB `IMAGEM` em `first`/`cover`, título com Advanced Formatting e `&PUBLICO.`/`&DATA_PUBLICACAO_TXT.`), 3 `dynamicContent` | Cards já filtra `c.id_empresa = :G_ID_EMPRESA`. |
| p3 Organograma | `dynamicContent` (módulo `modulos/organograma`) | HTML gerado por package (`pkg_<nome>_ui`). |
| p4 Chat | 2 `classicReport` com templates próprios (`@chat-contatos`, `@chat-mensagens`) | Colunas com `escapeSpecialChars: false`; região `msgs` condicionada a `P4_CANAL_ID is not null`. |
| p7 Monitor de Logs | 3 `interactiveReport` em abas | O `.apx` atual já tem `authorizationScheme: @admin-rh` na página; o README e o `ai-context/02` ainda dizem "sem authorization" (atualizar o `ai-context`). |
| p13 Histórico de carreira | `interactiveReport` + `dynamicContent` | IR filtra `id_empresa = :G_ID_EMPRESA`. |
| p15 Empresas | `interactiveReport` sobre a tabela `EMPRESA` com link para o modal p16 | Padrão lista + formulário modal; sem authorization na página. |
| p19 Formações | `interactiveReport` | Filtra por `:G_ID_EMPRESA`; página `@admin-rh`. |
| p20 Dashboard RH | 3 `chart`, 1 `classicReport`, 1 `interactiveReport` | Todos filtram `:G_ID_EMPRESA`; séries com `pageItemsToSubmit` de datas. |
| p26 Central de Equipes | `classicReport` sobre a tabela `EQUIPE` (Table/View, sem `whereClause`) | **Não filtra por `id_empresa`**. |

Não há Interactive Grid, Faceted Search, Smart Filters, Map, Calendar nem Tree no app hoje. Telas-alvo do `pen_dev/` (ver `ai-context/07`) podem pedir Cards, Content Row e Smart Filters.

Fonte: [Understanding Report Page Types](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-report-page-types.html)

### Regras do projeto aplicadas a relatórios (id_empresa, authorization, links, pt-BR)

1. **Multiempresa**: toda fonte de relatório (região, série de gráfico, LOV de coluna, facet, Search Configuration, Dynamic Content) filtra `id_empresa = :G_ID_EMPRESA`. Em fonte *Table/View*, use `whereClause` (APEXlang `source.whereClause`) ou troque para SQL Query. Como `G_ID_EMPRESA` é item de aplicação preenchido no login, não precisa ir em *Page Items to Submit* (já está em session state); itens de página usados no filtro precisam. Lembre que `G_ID_EMPRESA` só é preenchido depois de um novo login (`ai-context/08`). Caso concreto a corrigir: p26 (`EQUIPE` sem filtro).
2. **Authorization na página**: relatórios administrativos (logs, empresas, dashboards de RH) precisam de `authorizationScheme` em `page > security`, não só no menu. Dentro de relatórios, use *Download > Authorization*, *Save Public Report Authorization*, authorization em colunas sensíveis (como `CAB_DEPT` do chat) e na Link Column.
3. **Links com checksum**: as páginas usam `pageAccessProtection: argumentsMustHaveChecksum`. Use colunas *Link* com Link Builder (como `COLABORADOR` → p13 na p20), ações de Cards ou `apex_page.get_url` no SQL; não monte `f?p=` à mão. Os links com filtros de IR/IG (`IR[...]`) também devem sair do Link Builder (*Set Items*).
4. **Escaping**: mantenha *Escape Special Characters* ligado. As colunas `escapeSpecialChars: false` da p4 só são aceitáveis se o conteúdo for gerado pelo próprio app; mensagens digitadas por usuários devem ser escapadas (`!HTML` ou `apex_escape.html` no SQL/package).
5. **pt-BR**: preencha *When No Data Found* (`messages.whenNoDataFound`), cabeçalhos, rótulos de botões (*Add Button Label* do IG) e textos de download em português. Como a app tem idioma primário `en` e máscaras `DS`, defina *Format Mask* nas colunas de data (ex.: `DD/MM/YYYY HH24:MI`, como em `ABERTA_EM` da p20) ou formate no SQL.
6. **Tema**: Cards e Content Row recebem classes `cx-*` (`cx-home-card`, `cx-home-comunicados`) em *CSS Classes*; ajustes visuais vão em `custom.css` + `.min.css`. O `custom.css` tem regras globais em `.a-CardView-*` com sombra, contrariando a política "sem sombra" (`ai-context/08`).

Fonte: [Managing Classic Report Column Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-classic-report-column-attributes.html), [Controlling Output Escaping in Substitution Strings](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/controlling-output-escaping-in-substitution-strings.html), [Configuring Interactive Report Download Options](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-interactive-report-download-options.html)

### Escolha de componente para novas telas do Corlix Hub

- **Cadastros (colaboradores, cargos, departamentos, empresas)**: IR + formulário modal criado pelo assistente (padrão p15/p16 e p13/p18), conforme `ai-context/08` e `09 §4.8`. Interactive Grid editável só se a edição em massa for realmente necessária e a região for criada pelo assistente com *Editing Enabled* (conferir o bloco `edit {` no export).
- **Lista de colaboradores (p12) e diretório**: Cards ou Content Row com avatar (foto em `#APP_FILES#Fotos Colaboradores/…` ou iniciais) + **Smart Filters** (departamento, cargo, equipe) — economiza espaço e funciona com Cards. Facets com LOVs filtradas por `id_empresa`.
- **Comunicados (p11)**: Cards (layout horizontal ou grid) com Order By Item (mais recentes, por departamento).
- **Dashboards (p1, p20)**: Charts JET com uma série por métrica, *Page Items to Submit* nas séries, rótulos ordenáveis como texto (`yyyy/mm`) e *Lazy Loading* nas regiões mais lentas.
- **Logs (p7)**: IR com *Download* restrito por authorization e *Maximum Rows to Process* para não varrer as views do APEX inteiras.
- **Organograma (p3)**: o módulo usa Dynamic Content; a região Tree nativa é alternativa simples (Computed with SQL sobre `COLABORADOR.ID_GESTOR`), mas não substitui o layout gráfico do módulo.

Fonte: [Understanding Report Page Types](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-report-page-types.html), [More Space for Results with Smart Filters](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/more-space-results-smart-filters.html), [Managing Trees](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-trees.html)

### Divergências entre a documentação oficial 26.1 e o ai-context do projeto

| Tema | Documentação oficial 26.1 | `docs/ai-context` / código | O que fazer |
|---|---|---|---|
| Aba *Attributes* do Property Editor | Quase todos os procedimentos de IR, IG, Classic, Cards, Chart e Calendar mandam selecionar a região e abrir a aba **Attributes** | `08 §1 regra 11`: no 26.1.5 o painel **não tem** a aba "Attributes" | Ao escrever guias, marque o caminho como "(confirmar no 26.1.5)" e peça print; confirme pelo export APEXlang (os grupos existem no `.apx`). |
| Tornar IG/Form editável | *Attributes > Edit > Enabled* = On em região existente | `08 §3` e `09 §4.8`: só regiões criadas pelo assistente trazem `edit { enabled: true }`; o Builder não oferece onde ligar | Siga o `ai-context`: crie pelo assistente ou use IR + modal. |
| Autorização da p7 | — | README/`02` dizem "sem authorization"; o `.apx` atual tem `authorizationScheme: @admin-rh` | Vale o código; atualizar `ai-context/02` e o README. |
| Ordem de rótulos em gráfico multi-série | Documenta ordenação por série | `08`: rótulos de várias séries ordenados como texto | Use rótulos ordenáveis como texto. |

Fonte: [Making an Existing Interactive Grid Editable](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/making-an-existing-interactive-grid-editable.html), [Editing Charts](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-charts.html)
