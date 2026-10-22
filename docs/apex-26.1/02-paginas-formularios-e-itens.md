# 02 · Páginas, Page Designer, layout, formulários, itens e Dynamic Actions

> Base: documentação oficial Oracle APEX 26.1 (App Builder User's Guide/htmdb: *Creating Applications*, *Quick Start*, *Managing Pages in an Application*, *Editing Pages in Page Designer*, *Controlling Page Layout*, *Developing Forms*, *About Item Types*, *Managing Application Controls*; Developer's Companion/apxdc: *Simplifying User Experience Design*, *Working with Master/Detail Data* e, como apoio, *Understanding Page Flow & Session State* e *Referencing Data Values in Pages*; JavaScript API/aexjs: `apex.navigation.dialog`, `item`). Gerado em 21/10/2026.

**Sumário**
1. Criação de aplicações (resumo) · 2. Quick Start (resumo) · 3. Gerenciar páginas e tipos de página · 4. Páginas de diálogo: modal, non-modal e drawer · 5. Page Designer · 6. Atributos de página · 7. Layout: templates, slots, grid e regiões · 8. Formulários (Form region, Form - Initialization, Automatic Row Processing, Lost Update) · 9. Master-detail · 10. Itens de página: conceitos e atributos · 11. Catálogo de tipos de item · 12. Listas de valores e cascading LOV · 13. Botões · 14. Dynamic Actions · 15. Trees · 16. Submit, AJAX e redirect · 17. Aplicação no Corlix Hub

Convenção: os nomes de interface, propriedades e APIs ficam em inglês, como aparecem na doc. Caminhos "Grupo, Atributo" (ex.: *Behavior, Action*) seguem a notação da Oracle para o Property Editor.

---

## 1. Criação de aplicações (resumo)

### Métodos de criação de aplicação no App Builder (Create Application, Create App Wizard, IA, arquivo, Fusion)
Uma aplicação é um conjunto de páginas ligadas por menus, abas, botões ou links, que compartilham session state e autenticação. Em *App Builder › Create* há estas opções:

| Opção | O que gera | Quando usar |
|---|---|---|
| **Create Application** | Só *Global Page*, *Home* e *Login*. As outras páginas vêm depois, pelo Create Page Wizard | Começar enxuto e montar página a página |
| **Use Create App Wizard** | App completa a partir de tabelas ou de SQL, com páginas, *Features* e *Settings* | Protótipo rápido sobre um modelo de dados pronto |
| **Create App Using Generative AI** | App a partir de um prompt em linguagem natural | Só aparece se houver um Generative AI Service com *Used by App Builder* ligado |
| **Create App From a File** | Carrega CSV, XLSX, XML ou JSON (ou dados colados) e gera páginas | Dados em planilha ainda sem tabela |
| **Create Fusion Integration** | App inicial integrada a uma instância Oracle Fusion Applications | Extensões de Fusion |

Na primeira visita ao App Builder aparece a região *Get Started Now*, que leva ao wizard ou à Gallery (apps de exemplo). Cada página tem número e *alias*, e o alias aparece na URL.

Fonte: [Creating Applications](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-applications.html), [Choosing an Application Creation Method](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/choosing-an-application-creation-method.html), [Starting a New Application](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/starting-new-application.html)

### Create Application Wizard completo: Appearance, Add Page, Features e Settings
- **Set Icon**: o ícone escolhido vira favicon, ícone de PWA, Apple touch icon e ícone no App Builder.
- **Appearance**: *Theme Style* e *Navigation*. A navegação pode ser *Side Menu* (árvore lateral recolhível), *Top Menu* (barra no cabeçalho) ou *Mega Menu* (painel flutuante com todos os itens).
- **Add Page**: adiciona páginas por tipo (Form, relatórios, Master Detail etc.). A Home é sempre a primeira e não pode ser reordenada. As demais podem ser arrastadas, e a ordem das páginas administrativas define a ordem delas na página de Administração.
- **Features**: funcionalidades de nível de aplicação (About, Access Control, Activity Reporting, Feedback, Theme Style Selection...). Cada uma só pode ser adicionada uma vez.
- **Settings**: *Application ID* (os IDs de 3000 a 9000 são reservados ao APEX), *Schema* de parsing, *Authentication*, *Languages*, *Advanced Settings* e *UI Defaults*.

O wizard de aplicação aplica boas práticas gerais, mas não expõe as opções avançadas do Create Page Wizard. Por exemplo, Master Detail no wizard de aplicação só oferece Stacked e Side by Side; Drill Down existe apenas no Create Page Wizard.

Fonte: [Running the Full Create Application Wizard](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/running-the-create-app-wizard.html), [About the Full Create Application Wizard](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-the-full-create-application-wizard.html)

### JSON Application Blueprints (View Blueprint, Load Blueprint, Apply Blueprint)
Cada execução do Create Application Wizard salva um *blueprint* JSON da aplicação em montagem. No topo do wizard:
- **View Blueprint**: mostra a definição atual em JSON num Script Editor. Você edita e clica em **Apply Blueprint**. Para criar muitas páginas parecidas, copie o JSON de uma página, cole várias vezes e ajuste.
- **Load Blueprint / Load Previous Blueprint**: recarrega o blueprint de uma app gerada antes, para iterar (mais páginas, outras features) e gerar de novo.

Fonte: [Using JSON Application Blueprints](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/using-json-blueprints.html)

### APEXlang: formato de arquivo e validação com `apex validate`
APEXlang é a linguagem aberta de especificação de apps APEX, voltada a desenvolvimento por agentes de IA. Um pacote APEXlang é um ZIP com arquivos `.apx` de definição, scripts SQL de Supporting Objects, CSS/JS e arquivos estáticos, num formato legível e adequado ao Git (em vez do export SQL grande). Para diagnosticar erros de import:
1. Exporte a app em APEXlang.
2. No SQLcl com `/nolog`, rode `apex validate -input <diretório ou zip>` (use `spool` para guardar a saída).
3. Para cada erro, veja o `.apx`, a linha, o componente e a mensagem. Corrija no App Builder e reexporte, ou edite o `.apx` direto, e valide de novo.

Só **erros** exigem correção. **Warnings** são informativos e não impedem o import. O APEX corrige sozinho, no import e no upgrade, as inconsistências de metadados cuja correção é inequívoca. Em Page Designer, *Utilities › Show APEXlang View* mostra um snapshot somente leitura da última versão salva da página.

Fonte: [Creating an Application with APEXlang](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-an-application-with-APEXlang.html), [Page Designer Toolbar](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/page-designer-toolbar.html)

---

## 2. Quick Start (resumo)

### Workspace home, App Builder, Application home page e APEX Menu Bar
- O **APEX Menu Bar** (barra lateral) dá acesso a App Builder, SQL Workshop, Data Reporter, Gallery, Search, menu Extensions (links configurados pelo admin do workspace), Help e Account (aparência, dark mode do Builder, perfil, preferências, sign out).
- **Global Search** (*Spotlight*, atalho `Ctrl + '` em teclado US) busca apps, páginas, shared components e menus do workspace, e põe o foco no componente dentro do Page Designer.
- **Application home page**: *Run Application*, *Supporting Objects* (scripts de instalação e desinstalação de objetos), *Shared Components*, *Utilities* (Advisor, dashboards, relatórios) e *Export/Import* (inclui *Remote Deployment* via REST Enabled SQL). O botão *Edit Application Definition* edita o nome e o *Application Alias*.
- **App Gallery**: Sample Apps (ex.: *Sample Dynamic Actions* e *Sample Trees*, citados como referência neste documento), Starter Apps, Custom Apps e Utility Apps.

Fonte: [Quick Start](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/quick-start.html), [APEX Menu Bar](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/apex-menu-bar.html), [Understanding the Application Home Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-application-home-page.html)

---

## 3. Gerenciar páginas e tipos de página

### Create Page Wizard: abas Generative AI, Component, Feature e Legacy
Abra pelo botão *Create Page* da Application home page ou, no Page Designer, por *Create › Page*. As abas são:
- **Using Generative AI**: cria a página a partir de um prompt. Fica oculta se não houver Generative AI Service no workspace.
- **Component**: páginas com funcionalidade de página (relatórios, Form, Master Detail...).
- **Feature**: funcionalidades de nível de aplicação.
- **Legacy Page**: tipos ainda suportados, mas não recomendados.

O botão **Create Page as Copy** abre o Copy Page Wizard. O Universal Theme 42 serve tanto para desktop quanto para mobile. O antigo UI mobile baseado em jQuery Mobile foi desuportado, e apps móveis antigas precisam migrar para o Universal Theme.

Fonte: [Adding a New Page to an Application](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/adding-new-page-app.html), [Understanding Page Types in the Create Page Wizard](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/page-types-create-page-wizard.html)

### Tipos de página Component do Create Page Wizard (Blank, Form, Interactive Report, Master Detail...)

| Tipo | O que cria | Observações |
|---|---|---|
| Blank Page | Página vazia | Você monta as regiões no Page Designer |
| Calendar | Calendário mensal, semanal e diário | |
| Cards | Blocos de informação em layout Grid, Float ou Horizontal (Row) | Ações (Button, Full Card, Title, Subtitle, Media) e template directives |
| Chart | Página com gráfico (área, barra, pizza, gantt, radar...) | |
| Classic Report | Relatório SQL baseado em template | *Include Form* cria o par relatório + formulário. Pode ser modal |
| Comments, Content Row, Media List, Timeline | Regiões de template do UT | Exigem a versão mais recente do Universal Theme |
| Dashboard | Layouts com 4 ou 6 gráficos | |
| Data Loading | Página com o processo nativo de Data Loading | Exige uma Data Load Definition |
| Faceted Search / Smart Filters | Busca por facetas (painel à esquerda) ou campo único com chips | |
| **Form** | Atualiza uma ou várias linhas de uma tabela | Colunas com FK numa tabela local viram **Select List** |
| Interactive Grid | Relatório customizável e opcionalmente editável | Edição ligada em *Edit, Enabled* |
| Interactive Report | Relatório customizável pelo usuário | *Include Form* |
| Map | Mapa com camadas de pontos, linhas, polígonos ou heat map | |
| **Master Detail** | Stacked, Side by Side ou Drill Down | Ver §9 |
| Search Page | Busca baseada em Search Configuration | |
| Tree | Hierarquia com navegação | Ver §15 |
| Unified Task List, Workflow Console | Tarefas de aprovação e workflows | |
| Wizard | Conjunto de páginas em passos | Entrada de dados em várias etapas |
| Plug-in Page | Página baseada num region plug-in | |

**Global Page** também é criada por *Component* e só aparece como opção se a app ainda não tiver uma (ver "Global Page" adiante).

Fonte: [Understanding Page Types in the Create Page Wizard](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/page-types-create-page-wizard.html)

### Feature pages e como removê-las com Build Options
Feature pages trazem funcionalidade de aplicação: Push Notifications, About Page, Access Control (cria os papéis reader, contributor e administrator e as authorization schemes correspondentes), Activity Reporting, Configuration Options, Email Reporting, Feedback, Login Page e Theme Style Selection. Elas podem ser adicionadas no Create Application Wizard, no Create Page Wizard (aba Feature) ou em *Tasks › Add Feature Page* da Application home page.

Cada feature criada por wizard fica associada a uma **build option**:
- *Include*: os componentes fazem parte da app em runtime.
- *Exclude*: o engine trata os componentes como inexistentes.
- Para remover de vez, apague os componentes associados à build option e depois a build option.

Fonte: [Managing Feature Pages](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-feature-pages.html)

### Legacy page types (Form on Local Procedure, Summary Page, Legacy Data Loading)
Ainda são suportados, mas a Oracle não recomenda usá-los. Para formulários legados, a doc indica rodar *Utilities › Upgrade Application*, que converte os forms antigos para a Form region atual.

Fonte: [Legacy Page Types](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/page-types-create-page-wizard.html), [Developing Forms](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/developing-forms.html)

### Copiar página (Copy Page Wizard) na mesma app ou de outra app
Acesso por *Create Page › Create Page as Copy* ou pelo Page Designer (*Create › Copy Page*).
- **Na mesma app**: escolha a página de origem e o novo número, *Copy Public Reports* (On/Off; os relatórios padrão são sempre copiados), *Breadcrumb*, *Navigation Preference* e *New Names* (revisão de nomes antigos e novos).
- **De outra app**: além do acima, há o passo *Templates*. Todo template usado pela página de origem precisa ser mapeado para um template da app de destino.

Fonte: [Creating a New Page by Copying](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-a-new-page-by-copying.html)

### Page Groups: organizar páginas (sem efeito em runtime)
Page groups servem só para organizar o trabalho do desenvolvedor e não mudam o runtime. Ficam em *Utilities › Page Specific Utilities › Page Groups*. A página é atribuída a um grupo no Page Designer, em *Identification, Page Group*. Para excluir um grupo, primeiro tire todas as páginas dele. O grupo tem *Static ID* próprio para APIs e exports: se você mudar o Static ID, as referências de componentes continuam valendo, mas as chamadas de API que usam o ID antigo precisam ser atualizadas à mão.

Fonte: [Managing Page Groups](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-page-groups.html)

### Travar e destravar páginas (Page Lock) para evitar conflito entre desenvolvedores
Uma página travada não pode ser editada por outros desenvolvedores. Você pode travar pela Application home page (Report View, coluna Actions), pelo botão de cadeado na toolbar do Page Designer ou em *Utilities › Cross Page Utilities › Page Locks* (*Lock Checked*). O ícone indica o estado:
- cadeado aberto: página destravada;
- cadeado fechado: travada por você;
- cadeado com silhueta de pessoa: travada por outro desenvolvedor.

Só quem travou pode destravar, exceto um administrador do workspace (*Page Locks › Lock Administration*). Uma página travada só pode ser excluída por quem a travou.

Fonte: [Locking and Unlocking a Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/locking-and-unlocking-a-page.html), [Managing Pages in an Application](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-pages-in-an-application.html)

### Global Page (antiga Page 0): componentes que aparecem em todas as páginas
A Global Page funciona como página mestra: tudo o que é colocado nela é renderizado em todas as páginas da app (pode haver uma por user interface). Use **condições** para controlar quando cada componente aparece ou quando cada computation, validation ou process roda. A Global Page é criada em *Create Page › Component › Global Page*, opção que só aparece se ela ainda não existir. Apps antigas a mostram como *Page Zero*.

**Quando não usar:** para conteúdo que só algumas páginas precisam, porque sem condição ele aparece em todas, inclusive no login.

Fonte: [Creating a Global Page to Display Components on Every Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-a-global-page-to-display-components-on-every-page.html), [Starting a New Application](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/starting-new-application.html)

### Excluir página: o que é removido junto
Ao excluir uma página, as abas, breadcrumbs e entradas de lista correspondentes também são excluídos. Você só pode excluir páginas destravadas ou travadas por você. Para excluir no Page Designer, use *Utilities › Delete Page*.

Fonte: [Managing Pages in an Application](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-pages-in-an-application.html)

---

## 4. Páginas de diálogo: modal, non-modal e drawer

### Page Mode: Normal, Modal Dialog e Non-Modal Dialog
O atributo **Appearance, Page Mode** define se a página é normal ou de diálogo:
- **Modal Dialog**: janela sobreposta dentro do viewport. A página de baixo fica acinzentada e não aceita interação até o diálogo fechar.
- **Non-Modal Dialog**: janela sobreposta em que o usuário pode interagir tanto com o diálogo quanto com a página que o abriu. Serve quando a informação pedida não é essencial para continuar.

As opções de diálogo **só aparecem** se o tema atual tiver ao menos um page template do tipo *Dialog Page* definido como padrão. O Universal Theme 42 já traz esses templates, e ao escolher Modal ou Non-Modal o APEX usa o template de diálogo padrão.

Fonte: [Creating Dialog Pages](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-dialog-pages.html)

### Dialog Template: Modal Dialog, Wizard Modal Dialog e Drawer
**Appearance, Dialog Template** sobrescreve o template de diálogo padrão (*Theme Default*):
- **Modal Dialog**: serve à maioria dos casos. Fica centralizado sobre a página que o abriu, ajusta-se ao conteúdo por padrão e pode ter largura e altura fixas ou ocupar todo o espaço.
- **Wizard Modal Dialog**: interface mais enxuta, boa para wizards modais, alertas, notificações e formulários pequenos.
- **Drawer**: alternativa de apresentação de página modal. Ocupa a altura toda da janela e desliza a partir da borda inicial ou final. O Create Page Wizard usa Drawer como *Form Page Mode* padrão do formulário que acompanha um relatório (*Include Form Page*).

Os três fecham e cancelam do mesmo jeito (Close Dialog / Cancel Dialog).

Fonte: [Creating Dialog Pages](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-dialog-pages.html), [Modal Dialogs and Drawers](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/modal-dialogs-and-drawers.html), [Creating List and Edit Pages](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/creating-list-and-edit-pages.html)

### Atributos do grupo Dialog: Width, Height, Maximum Width, Attributes, CSS Classes, Chained, Resizable

| Atributo | Efeito | Substituição no template |
|---|---|---|
| Width | Largura em pixels ou porcentagem | `#DIALOG_WIDTH#` |
| Height | Altura em pixels (ex.: `500`) | `#DIALOG_HEIGHT#` |
| Maximum Width | Largura máxima em pixels | `#DIALOG_MAX_WIDTH#` |
| Attributes | Outros atributos do diálogo, como pares nome/valor separados por vírgula | `#DIALOG_ATTRIBUTES#` |
| CSS Classes | Classes extras, separadas por espaço | |
| Chained | **On**: um diálogo aberto por outro diálogo reaproveita a mesma janela (wizard em várias páginas). **Off**: abre numa nova janela sobre a atual (modal dentro de modal) | |
| Resizable | Permite ao usuário redimensionar o modal | |

Altura, largura e largura máxima são as únicas propriedades com suporte declarativo. O resto vai em *Attributes*.

Fonte: [Creating Dialog Pages](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-dialog-pages.html), [Configuring Dialog Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-page-attributes-in-page-designer.html)

### Criar um dialog page template quando o tema não tem um
O dialog page template contém as chamadas JavaScript de inicialização, fechamento e cancelamento do diálogo. Se uma app antiga não tiver esse template, o caminho mais simples é copiar um: *Shared Components › Templates › Create*, Template Type *Page*, *As a Copy of an Existing Template*. Escolha a app e o tema de origem e marque *Yes* nos templates Drawer, Modal Dialog e Wizard Modal Dialog. Depois confirme que o template ficou ativo no tema atual.

Fonte: [Creating a Dialog Page Template](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-dialog-pages.html)

### Fechar o diálogo: processo Close Dialog × Dynamic Action Close Dialog × branch
Há três formas de fechar um diálogo:
1. **Page process Close Dialog** (antigo *Close Popup Window*): use quando a página **precisa ser submetida**, por exemplo depois do DML de um form. Pode devolver itens do diálogo para a página-mãe.
2. **Dynamic action Close Dialog**: use quando **não** há submit. Também devolve itens.
3. **Branch**: fecha o diálogo e redireciona para a página do branch.

Os dois primeiros chamam `apex.navigation.dialog.close` do template.

**Quando escolher cada um:**
- Para editar dados num modal e atualizar só o relatório da página-mãe (refresh parcial), feche com Close Dialog e trate o evento *Dialog Closed* na mãe.
- Para wizards modais de vários passos, ou quando há vários destinos possíveis ao fechar, use branching.

Padrão gerado pelo wizard: o processo Close Dialog vem **depois** do processo de DML, com a Server-side Condition *Request is contained in Value* = `CREATE,SAVE,DELETE`.

Fonte: [Generating a Close Dialog Page Process on the Dialog Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-dialog-pages.html), [Refreshing List On Dialog Close](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/refreshing-list-dialog-close.html)

### Cancelar o diálogo: Dynamic Action Cancel Dialog
Num diálogo com botão Cancel, crie uma dynamic action (ou uma triggered action no botão) com a ação **Cancel Dialog**. Ela usa `apex.navigation.dialog.cancel` do template. No form modal gerado pelo wizard, o botão CANCEL tem *Behavior, Action* = Defined by Dynamic Action e dispara Cancel Dialog. Se o form for uma página **normal**, o wizard faz o CANCEL submeter a página, com um branch *When Button Pressed = CANCEL* que volta para a lista.

Fonte: [Generating a Cancel Dialog Dynamic Action on the Dialog Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-dialog-pages.html), [Conditional Database Action Buttons](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/conditional-database-action-buttons.html)

### Branching com páginas de diálogo (dialog → dialog, dialog → normal)
- **Diálogo para diálogo**: só funciona se as duas páginas tiverem o mesmo *Page Mode*, por exemplo uma página Modal Dialog para outra com *Chained* = On. É o que permite diálogos encadeados, como os wizards internos do APEX.
- **Diálogo para página normal**: o diálogo fecha e o navegador vai para a nova página, seja ela a que abriu o diálogo ou outra.

Fonte: [About Branching with Dialog Pages](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-dialog-pages.html), [Modal Dialogs and Drawers](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/modal-dialogs-and-drawers.html)

### Atualizar a página-mãe ao fechar o diálogo: eventos Dialog Closed e Dialog Return Item
Na página que abriu o diálogo, crie uma dynamic action com um destes eventos:
- **Dialog Closed** (`apexafterclosedialog`): dispara só quando o diálogo fecha via processo ou DA *Close Dialog*.
- **Dialog Closed or Canceled** (`apexafterclosecanceldialog`): dispara também no cancelamento (tecla ESC ou DA *Cancel Dialog*).

Como o wizard configura:
- *When, Selection Type* = Region e *Region* = a região de relatório. Assim a DA escuta só os diálogos abertos a partir daquela região.
- A ação é **Refresh** com a mesma região como *Affected Element*.

Para usar valores devolvidos pelo diálogo, crie um **Set Value** com *Set Type* = **Dialog Return Item**. Ele grava num item da página-mãe um valor devolvido pelo Close Dialog (os itens a devolver ficam listados no processo ou DA de fechamento).

Fonte: [Handling Refresh Actions on Parent Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-dialog-pages.html), [About Dynamic Action Events](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-dynamic-actions.html), [Refreshing List On Dialog Close](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/refreshing-list-dialog-close.html)

### API JavaScript `apex.navigation.dialog.close` e `apex.navigation.dialog.cancel`
Essas funções devem rodar **no contexto da página de diálogo**.
- `apex.navigation.dialog.cancel(pIsModal)`: fecha a janela (`true` = modal).
- `apex.navigation.dialog.close(pIsModal, pAction)`: executa a ação e fecha. `pAction` pode ser:
  - uma URL, que redireciona a página-mãe;
  - uma função, que abre outro diálogo reaproveitando a janela;
  - `false`, que cancela;
  - um objeto de pares item/valor;
  - um array de nomes de item, cujos valores são coletados.

  Os valores passados por objeto ou array ficam disponíveis nos eventos `apexafterclosedialog` e `apexafterclosecanceldialog`.

```javascript
// devolve P3_EMPNO e P3_ENAME para a DA "Dialog Closed" da página-mãe
apex.navigation.dialog.close( true, ["P3_EMPNO","P3_ENAME"] );
// devolve um valor arbitrário para identificar qual diálogo fechou
apex.navigation.dialog.close( true, { dialogPageId: 3 } );
```

Fonte: [apex.navigation.dialog](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/apex.navigation.dialog.html)

### Page Mode não oferece Modal Dialog / Non-Modal Dialog
**Sintoma:** no Property Editor, *Appearance, Page Mode* só tem Normal.
**Causa:** o tema atual não tem um page template padrão do tipo Dialog Page.
**Correção:** copie os templates Modal Dialog, Wizard Modal Dialog e Drawer de outro tema ou app (*Shared Components › Templates › Create › Page › As a Copy*) e defina o template de diálogo padrão do tema.
**Prevenção:** use o Universal Theme 42 atualizado, que já traz esses templates.

Fonte: [Creating Dialog Pages](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-dialog-pages.html)

### Relatório da página-mãe não atualiza depois de salvar no modal
**Sintoma:** o usuário salva no diálogo, o diálogo fecha, mas o relatório continua com os dados antigos.
**Causa:** a página-mãe não tem DA no evento *Dialog Closed*, ou o diálogo foi fechado por um branch (que não dispara o evento), ou não existe processo/DA *Close Dialog* depois do DML.
**Correção:** no diálogo, um processo Close Dialog sequenciado depois do *Form - Automatic Row Processing (DML)*, condicionado aos requests dos botões. Na mãe, uma DA *Dialog Closed* (Selection Type = Region da lista) com a ação *Refresh* na região.
**Prevenção:** prefira o par lista + form modal gerado pelo Create Page Wizard, que já cria as duas partes.

Fonte: [Handling Refresh Actions on Parent Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-dialog-pages.html), [Refreshing List On Dialog Close](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/refreshing-list-dialog-close.html)

---

## 5. Page Designer

### Visão geral do Page Designer: três painéis, Two Pane Mode e Reset Layout
O Page Designer é o IDE de páginas. As mudanças salvas valem na hora na página em execução: não há geração de código nem deploy, basta recarregar o navegador. O padrão é **Three Pane Mode**:
- **esquerda**: Rendering, Dynamic Actions, Processing e Page Shared Components;
- **centro**: Layout, Page Search e Help, com a Gallery embaixo;
- **direita**: Property Editor.

Em *Utilities › Layout* você troca para **Two Pane Mode** (só centro e direita, útil para ver a árvore Rendering ao lado do Property Editor) e restaura com **Reset Layout**. As abas podem ser arrastadas entre painéis, e os divisores redimensionam ou recolhem os painéis.

Fonte: [Working with Page Designer](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/working-with-page-designer.html), [Rendering, Layout, and Property Editor](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/rendering-layout-and-property-editor.html), [Simplifying User Experience Design](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/simplifying-user-experience-design.html)

### Toolbar do Page Designer: Page Selector, Show Messages, Lock, Undo/Redo, Create, Utilities, Save
- **Page Selector / Page Finder**: busca páginas por número, nome, UI ou grupo (aceita regex), com abas *All Pages* e *Recently Edited*. Tem setas para a página anterior e a próxima.
- **Show Messages**: lista os erros e avisos da página. Clicar num item leva ao atributo com problema no Property Editor.
- **Page Lock**: estado do cadeado (§3).
- **Undo / Redo**.
- **Create (+)**: Page, Copy Page, Breadcrumb Region, Shared Component, Page Group, Developer Comment, Issue.
- **Utilities**:
  - Delete Page e **Show APEXlang View**;
  - Advisor, Caching, History (mudanças da página), Checksum e Export;
  - *Show*: Tooltips, Text Messages Picker e Layout View;
  - *Layout*: modo de painéis.
- **Shared Components**.
- **Save / Save and Run Page**.

Fonte: [Page Designer Toolbar](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/page-designer-toolbar.html)

### Painel esquerdo: abas Rendering, Dynamic Actions, Processing e Page Shared Components
- **Rendering**: regiões, itens e botões nas posições (slots) da página e das regiões, mais a lógica de *Pre-Rendering* (processes, computations e branches em Before Header, After Header e Before Regions) e de *Post-Rendering*. A ordem da árvore segue a ordem de processamento em runtime. DAs e validations aparecem sob o componente a que se ligam.
- **Dynamic Actions**: as DAs agrupadas por evento.
- **Processing**: a lógica de submit em ordem de execução (*After Submit*, *Validating*, *Processing*, *After Processing*).
- **Page Shared Components**: shared components usados pela página. O botão *Edit Component* abre o editor do componente.

Em todas as abas: menu de contexto (botão direito), seleção múltipla que vai para o Property Editor, arrastar para mudar posição ou sequência, e tooltips.

Fonte: [Left Pane of Page Designer](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/left-pane-page-designer.html)

### Painel central: Layout, Page Search, Help e Gallery
- **Layout**: representação visual da posição dos componentes. Permite arrastar para mover ou reordenar, arrastar da Gallery para criar, e usar o menu de contexto para excluir, mover ou copiar. **Itens Hidden não aparecem no Layout**, só na árvore. O menu Layout tem *Display from Here* (a região escolhida ocupa o painel), *Display from Page* (volta ao normal) e *Hide Empty Slots*.
- **Page Search**: busca em todos os metadados da página (regiões, itens, botões, DAs, colunas), com *Match Case* e *Regular Expression*. Clicar no resultado abre o componente no Property Editor.
- **Help**: ajuda do atributo selecionado, com opções e exemplos. É a fonte mais detalhada para valores de atributos que este documento não lista.
- **Gallery**: abas Regions, Items e Buttons. Arraste para o Layout ou use *Add To* no menu de contexto (botão direito). Por padrão mostra só componentes suportados (os legados ficam em *Show Legacy*).

Para colocar um item na mesma linha de outro, arraste-o até o fim do primeiro e **espere** a grade mudar e mostrar a área amarela de drop.

Fonte: [Central Pane of Page Designer](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/central-pane-page-designer.html), [Searching Your Page](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/searching-your-page.html)

### Property Editor: grupos, Filter Properties, Pin Filter, Go to Group e seleção múltipla
- Os atributos vêm em grupos funcionais (Identification, Layout, Appearance, Source, Default, Session State, Security, Server-side Condition...). **Go to Group** salta para um grupo, e *Expand All* volta.
- **Filter Properties** filtra por nome de grupo ou atributo. ESC limpa o filtro.
- **Pin Filter** mantém o filtro enquanto você navega entre componentes, para comparar o mesmo atributo em vários deles.
- **Seleção múltipla** (Shift para intervalo, Ctrl/Cmd para avulsos): mostra só os atributos comuns. Valores diferentes aparecem com um símbolo de delta, e alterar um atributo altera todos os selecionados.
- Atributos alterados e ainda não salvos ganham um **marcador** à esquerda do nome (a doc fala em marcador verde e em barra vertical), que some ao salvar.
- `ALT+6` leva direto ao Property Editor.
- Alguns componentes têm atributos espalhados em mais de uma aba do Property Editor. A doc cita, por exemplo, a aba *Attributes* da região. Veja a divergência no §17.

Fonte: [Right Pane of Page Designer (Property Editor)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/right-pane-page-designer.html), [Configuring Settings with Property Editor](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configuring-settings-property-editor.html), [Editing Page Items](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-page-items.html)

### Code Editor do Page Designer (atalhos, Validate, Query Builder, multi-cursor)
Atributos com muito código (Source de região, PL/SQL, JS, CSS, HTML) abrem num editor modal. Atalhos:

| Ação | Atalho |
|---|---|
| Undo | `Ctrl+Z` |
| Redo | `Ctrl+Shift+Z` |
| Find | `Ctrl+F` |
| Replace | `Ctrl+H` |
| Auto Complete | `Ctrl+Space` |
| **Validate** | `Ctrl+Alt+V` |
| Change All Occurrences | `Ctrl+F2` |
| Command Palette (mais de 80 comandos) | `F1` |

Também tem *Query Builder* e multi-cursor: `Shift+Alt+clique`, `Ctrl+Alt+↑/↓` (no macOS, `Shift+Option+clique` e `Option+Command+↑/↓`). O botão *Save and Run Page* funciona sem fechar o editor. Em *Settings* ficam indentação, tema (Automatic, Light, Dark, High Contrast Dark) e régua. Com Generative AI configurado, todos os editores ganham o chat *APEX Assistant*.

Fonte: [Page Designer Code Editor](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/code-editor-in-page-designer.html)

### Adicionar e copiar regiões, itens e botões (Gallery, Rendering, Ctrl+arrastar, Copy to other Page)
- **Criar**: arraste da Gallery para o Layout, ou use o menu de contexto da árvore Rendering (*Create Region*, *Create Sub Region*, *Create Page Item*, *Create Page Item Below*, *Create Button*). Para tipos legados, escolha *Show Legacy...* na lista *Type*.
- **Copiar**: *Copy To* no menu de contexto do Layout, `Ctrl`+arrastar na árvore Rendering, ou *Copy to other Page* (abre um wizard).
- Depois de criar, confira o ícone **Show Messages**: a Gallery cria o componente, mas ele pode ficar com atributos obrigatórios em aberto.
- **Atenção:** uma Form region criada pela Gallery ou pela árvore **não** traz os itens e processos (Form - Initialization, DML) que o Create Page Wizard cria. Ver §8.

Fonte: [Managing Regions, Items, and Buttons](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-regions-items-and-buttons.html), [Creating a Form Using the Create Page Wizard](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-a-form.html)

### Onde criar processos, computations, validations e branches (pre-rendering × submit)
- **Antes de renderizar**: na aba Rendering, nó *Pre-Rendering*, botão direito em *Before Header*, *After Header* ou *Before Regions* › *Create Branch / Computation / Process*. (Se a árvore estiver agrupada por tipo de componente, esses itens ficam na aba Processing.)
- **No submit**: na aba Processing, em *After Submit*, *Validating*, *Processing* ou *After Processing* › *Create Branch / Validation / Computation / Process*.
- O menu de contexto também tem *Duplicate*, *Delete* e *Copy to other Page*.

Fonte: [Creating Branches, Validations, Computations, and Processes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-branches-validations-computations-and-processes.html)

### Comment Out / Uncomment: excluir um componente do runtime sem apagá-lo
Botão direito no componente (Rendering, Dynamic Actions ou Processing) › **Comment Out**. O componente aparece riscado e é ignorado em runtime. **Uncomment** o traz de volta. Isso é implementado pela build option **Commented Out**, e vem por padrão nas apps criadas a partir do APEX 23.2. Vale também para colunas de relatório e itens de Form region: uma coluna comentada **continua comentada** depois de *Synchronize Columns*, enquanto uma coluna excluída volta na sincronização.

Fonte: [Commenting Out Page Components in Page Designer](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/commenting-out-page-components-in-page-designer.html), [Deleting or Commenting Out Columns](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/deleting-or-commenting-columns.html)

### Developer Toolbar em runtime: Page, Session, Debug, Quick Edit, Customize, Info
Aparece no rodapé das páginas executadas pelo App Builder, se o *Availability, Status* da app for *Available with Developer Toolbar*.
- **Page N**: abre a página no Page Designer.
- **Session**: *View Session State* e *Session Overrides*.
- **Debug**: os níveis são No Debug, *Info* (nível 4, URL `YES`), *App Trace* (nível 6, `LEVEL6`) e *Full Trace* (nível 9, `LEVEL9`, mais lento). *View Debug* mostra o log.
- **Quick Edit**: clique num componente da página para abri-lo no Page Designer (ESC sai). *Edit Live Template Options* usa o ícone de chave inglesa.
- **Customize**: Theme Roller, Edit Logo, Edit App Icon.
- **Info**: Show Layout Columns, Show Page Timing, Show Landmarks, Show Headings.
- **Opções**: Auto Hide, Show Icons Only e Display Position (Top, Left, Bottom ou Right).
- Um **botão vermelho** à esquerda indica erro de JavaScript na página: abra o console do navegador.

Fonte: [Developer Toolbar](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/runtime-developer-toolbar.html), [Running and Iteratively Editing Pages](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/running-and-iteratively-editing-pages.html)

---

## 6. Atributos de página

### Editar atributos da página (selecionar o nome da página no Rendering)
Selecione o nó da página (o nome dela) na aba Rendering ou no Layout. Os atributos controlam nome e título, cabeçalho e rodapé, navegação, JavaScript e CSS da página, tratamento de erro e o **authorization scheme** da página (grupo Security).

Fonte: [Managing Page Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-page-attributes-in-page-designer.html)

### JavaScript da página: File URLs, Function and Global Variable Declaration, Execute When Page Loads
- **File URLs**: um arquivo por linha. Suporta `#MIN#` (vira `.min` fora do debug), `#MIN_DIRECTORY#` (vira `minified/` fora do debug) e `#APP_VERSION#`.
- **Function and Global Variable Declaration**: funções e variáveis globais da página. Substitui `#PAGE_JAVASCRIPT#` no page template. Não coloque as tags `<script>`. Para atalho (shortcut) use `"SHORTCUTNAME"`.
- **Execute When Page Loads**: código que roda depois do JavaScript gerado pelo APEX.

**Quando usar:** para JS específico de uma página ou para testar uma função antes de levá-la a um `.js`. Se o mesmo código for usado em várias páginas, coloque num arquivo estático, que é cacheado pelo navegador.

```javascript
// Function and Global Variable Declaration
function test(){ alert('This is a test.'); }
```

Fonte: [Incorporating JavaScript Using Page Designer](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-page-attributes-in-page-designer.html)

### Rejoin Sessions da página (Security, Rejoin Sessions)
Define se uma URL sem session ID pode reaproveitar a sessão existente (pelo cookie).
- **Application Default**: herda o valor da aplicação.
- **Disabled**: cria uma sessão nova.
- **Enabled for Public Sessions**: só reaproveita sessões ainda não autenticadas. Exige *Embed In Frames* = *Allow from same origin* ou *Deny*.
- **Enabled for All Sessions**: exige Session State Protection ativa e checksum válido na URL, URL sem payload (request, clear cache ou pares item/valor) e a mesma restrição de *Embed In Frames*.

A configuração da instância prevalece se for mais restritiva. **Risco:** facilita o sequestro de sessão. Use com cautela.

Fonte: [Configuring Rejoin Sessions for a Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-page-attributes-in-page-designer.html)

### Warn on Unsaved Changes: página, item e botão
- **Página** (*Navigation, Warn on Unsaved Changes* = On): avisa ao sair de uma página com mudanças não salvas.
- **Item** (*Advanced, Warn on Unsaved Changes*): *Page Default* entra na checagem; *Ignore* fica de fora. Use *Ignore* em itens que não são coluna de banco, como campos de busca.
- **Botão** (*Behavior, Warn on Unsaved Changes*): *Page Default* checa; *Do Not Check* não checa. Use *Do Not Check* em Cancel, Delete e Apply Changes.

A implementação usa `apex.page.warnOnUnsavedChanges`. Um redirect não envia o que o usuário mudou, por isso o aviso existe.

Fonte: [Configuring Pages to Warn Users of Unsaved Changes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-page-attributes-in-page-designer.html), [Configuring Button Attributes to Warn Users of Unsaved Changes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-buttons.html), [Understanding AJAX and Redirect](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-ajax-and-redirect.html)

---

## 7. Layout: templates, slots, grid e regiões

### Como o APEX renderiza uma página: page template, region template e slots/positions
O engine combina **templates** com os componentes que você define e os dados do banco.
- O **page template** define a estrutura: navegação, barra lateral e posições (*slots*) de regiões. É HTML com substitution strings.
- Cada **região** é um container de conteúdo (relatório, form, gráfico, lista, PL/SQL, árvore, URL, calendário...). Ela é posicionada pela sequência e coluna, ou explicitamente num slot do page template (*Layout, Position*).
- O **region template** define o visual da região (título, borda, fundo) e as posições dos botões dentro dela.

O Layout do Page Designer mostra os slots com nome, e *Hide Empty Slots* esconde os vazios.

Fonte: [About Page Layout in Oracle APEX](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-page-layout-in-oracle-apex.html), [About Regions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-regions.html), [Page Layout Based on Template with Slots](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/page-layout-based-template-slots.html)

### Grid de 12 colunas: Start New Row, Column e Column Span
O layout responsivo segue três regras:
1. A largura de cada container (página ou região) se divide em **12 colunas lógicas**. Doze tem seis divisores exatos.
2. A coluna inicial (**Column**) e a extensão (**Column Span**) de cada elemento podem ser *Automatic* ou definidas à mão.
3. Um elemento fica na **mesma linha** do anterior, a menos que tenha **Start New Row** = true.

Detalhes:
- Com *Automatic*, os elementos de uma linha dividem o espaço por igual. Por exemplo, dois itens com span 4 deixam 4 colunas para os dois automáticos seguintes (2 para cada).
- Só combinações válidas são aceitas: se Column = 10, o span máximo é 3.
- A ordem no layout é a **sequência** na árvore. Arrastar ou mudar o *Sequence* reordena.
- Alguns slots de botões (ex.: **NEXT** de uma região) **não usam o grid**: os botões ocupam só a largura necessária, e não existe *Start New Row* para eles.
- Em telas estreitas o APEX mantém o layout lógico enquanto der e depois empilha um elemento por linha. Não é preciso desenhar versões por dispositivo.
- As mesmas regras valem para regiões no corpo da página. Duas regiões com Start New Row = false ficam lado a lado, cada uma com metade da largura. Com Column Span 4, uma delas fica com um terço.

Fonte: [Flexible Grid of Columns and Rows](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/flexible-grid-columns-and-rows.html), [Simple Layout for Any Screen Size](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/simple-layout-any-screen-size.html)

### Regiões aninhadas (Parent Region) para montar layouts complexos
Uma região pode conter outras. As sub-regiões têm a propriedade **Parent Region**, e as regras do grid valem dentro de cada nível. O uso mais comum é uma região *Static Content* vazia com o template **Blank with Attributes** (sem cabeçalho nem borda) como container invisível. Exemplo da doc: três regiões no mesmo row com spans 2, 6 e 4. A do meio contém Tabs e Departments, e a última contém Help e um Chart empilhados.

Fonte: [Nest Regions to Create Any Layout](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/nest-regions-create-any-layout.html)

### Item template e posição do label (Hidden, Optional, Required, Above, Floating)

| Template | Label | Observações |
|---|---|---|
| Hidden | Sem label | |
| Optional / Required | Antes do item | O **Label Column Span** define quantas colunas o label ocupa. O campo não estica por padrão (há opção para esticar) |
| Optional - Above / Required - Above | Acima do item | Não tem Label Column Span. O campo não estica |
| Optional - Floating / Required - Floating | Dentro do campo; encolhe e sobe quando há valor | Estica o item até o span |

Os templates *Required* mostram um marcador visual, e uma template option pode mostrar o texto "Required". A obrigatoriedade de fato vem de *Validation, Value Required* (§10).

Fonte: [Item Template Controls the Label](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/item-template-controls-label.html)

### Tipos de região suportados no Page Designer

| Tipo | Uso |
|---|---|
| Breadcrumb | Trilha de navegação da página |
| Calendar | Eventos por data, com duração e drag-and-drop opcional |
| Cards | Relatório SQL em blocos (Grid, Float, Row) |
| Chart | Gráficos nativos |
| Classic Report | Relatório SQL simples, guiado por template |
| **Dynamic Content** | HTML devolvido por uma função |
| Faceted Search / Smart Filters | Filtros de pesquisa |
| **Form** | Fonte de dados (local, remota, REST) com page items ligados a ela. Cada item tem uma *Form Region* (fonte) e uma região de exibição |
| Help Text | Região da página de ajuda |
| Interactive Grid / Interactive Report | Relatórios customizáveis pelo usuário |
| List | Listas estáticas ou dinâmicas, normalmente de navegação |
| Map | Mapa com coordenadas |
| Reflow Report | Relatório responsivo (legado) |
| Region Display Selector | Abas que mostram uma região por vez |
| Search | Resultado de Search Configurations |
| **Static Content** | Texto ou container de itens. Para HTML sem escape, *Output As* = HTML |
| Tree | Hierarquia |
| URL | Conteúdo remoto |
| Workflow Diagram | Diagrama do workflow (somente leitura) |

Region plug-ins aparecem como *Nome [Plug-in]* (ex.: Avatar, Badge, Comments, Content Row, Media List, Timeline).

Fonte: [Supported Region Types](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/supported-region-types.html)

### Atributos de região: Name/Title, Position, Header/Footer, Server Cache, Customizable, Advanced
- **Identification, Name** (obrigatório; é o nome usado no Page Designer) e **Title**: o título só aparece se o region template o prevê. Sem Title, o runtime usa o Name.
- **Layout, Position**: o slot do page template ou do region template pai.
- **Header / Footer Text**: HTML antes e depois de `#BODY#`. No footer vale `#TIMING#` (segundos de renderização). Em Classic Report valem também `#ROWS_FETCHED#`, `#TOTAL_ROWS#`, `#FIRST_ROW_FETCHED#` e `#LAST_ROW_FETCHED#`.
- **Server Cache, Caching**: *Disabled*, *Enabled* (para todos), *Cached by User* ou *Cache by Session*. Serve para regiões estáticas, como listas sem condição ou HTML fixo. O cache guarda `&SESSION.` como substituição, não a sessão real, e só é usado se a condição da região for atendida.
- **Customization, Customizable**: *Not Customizable By End Users*, *Customizable and Not Shown By Default* ou *Customizable and Shown By Default*. Exige `#CUSTOMIZE#` no page template.
- **Advanced**:
  - **HTML DOM ID**: antigo *Static ID* da região. Referenciado como `#DOM_ID#`; `#REGION_STATIC_ID#` está depreciado. O region template precisa conter `#DOM_ID#`.
  - **Custom Attributes**: preenche `#REGION_ATTRIBUTES#`.
  - **Static ID**: novo ID usado em APIs e no export APEXlang. Vem travado; clique no cadeado para editar. Se mudar, as chamadas de API com o ID antigo precisam ser corrigidas à mão.
  - **Region Display Selector**: inclui a região no seletor.
  - **Exclude Title from Translation**.
- **Region Image / Image Tag Attributes**: imagem no canto superior esquerdo. Sem `alt`, a imagem é tratada como decorativa.

Fonte: [Editing Regions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-regions.html)

### Region Display Selector: mostrar uma região por vez em abas
1. Em cada região que vai entrar no seletor, ligue *Advanced, Region Display Selector* = On.
2. Arraste uma região do tipo **Region Display Selector** da Gallery.
3. Nos atributos do seletor (a doc indica a aba *Attributes*):
   - **Mode**: *View Single Region* (abas que escondem as outras regiões) ou *Scroll Window* (todas visíveis; a aba rola até a região);
   - *Display Region Icons*;
   - *Include 'Show All'*;
   - **Remember Last Selection**: *By User*, *By Session* ou *No*.

Fonte: [Creating a Region Display Selector](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-regions.html)

### Região URL: incorporar conteúdo de outro site (Inclusion Mode)
Uma região do tipo URL aceita substituições na URL (ex.: `...&s=&STOCK_SYMBOL.`). Os modos de **Inclusion Mode** são:
- **IFrame**: o navegador carrega o conteúdo. O banco não busca nada.
- **Inline (escape special characters)**: o banco busca o conteúdo na renderização (`utl_http.request_pieces`) e o exibe com escape, contra XSS.
- **Inline (no escaping)**: igual ao anterior, mas sem escape. Use só com conteúdo confiável.

Para recortar o HTML recebido há os atributos *discard until but not including this text* e *discard after and including this text*. Os modos inline podem exigir *Proxy Server* na app, e URLs HTTPS exigem uma **wallet** configurada.

Fonte: [About Incorporating Content from Other Websites](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-incorporating-content-from-other-websites.html)

### Gerar HTML com PL/SQL numa região (htp.p)
Para HTML que forms, relatórios e gráficos não resolvem, use uma região PL/SQL (Dynamic Content) com o PL/SQL Web Toolkit. O session state é acessível por bind. Você perde a consistência dos templates.

```plsql
declare
   l_max_sal number;
begin
   select max(sal) into l_max_sal from emp;
   htp.p('The maximum salary is: '||to_char(l_max_sal,'999,999.00'));
end;
```

Fonte: [Rendering HTML Using Custom PL/SQL](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/rendering-html-using-custom-plsql.html)

### Página otimizada para impressão (Printer Friendly template e 9º argumento do f?p)
Defina um page template *Printer Friendly* em *Shared Components › Themes › (tema) › Component Defaults › Printer Friendly Page*. Ele costuma esconder navegação e mostrar itens como texto. O nono argumento do `f?p` (`PrinterFriendly`) renderiza a página nesse modo.

Fonte: [Optimizing a Page for Printing](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/optimizing-a-page-for-printing.html)

---

## 8. Formulários (Form region, Form - Initialization, Automatic Row Processing, Lost Update)

### Tipos de formulário no APEX: Interactive Grid editável, Form, Report with Form e Master Detail
- **Editable Interactive Grid**: várias linhas editadas direto no relatório. Ligue *Editing Enabled* no wizard ou *Edit, Enabled* numa grid existente.
- **Form**: uma linha de uma tabela (ou de outra fonte). O Create Page Wizard oferece mais opções de fonte que o Create Application Wizard.
- **Report with Form**: Interactive Report ou Classic Report com *Include Form* (no Create App Wizard) ou *Include Form Page* (no Create Page Wizard). A lista tem link para o form de cada linha.
- **Master Detail**: uma linha mestre e várias de detalhe (§9).

Fonte: [Understanding Form Types](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-forms-types.html)

### Criar Form pelo Create Page Wizard (Data Source, Primary Key Column, Branch Pages)
Passos: *Create Page › Component › Form*.
1. **Page Definition**: número, nome (também vira o título) e **Page Mode** (normal, modal etc.).
2. **Data Source**:
   - **Local Database**, com *Source Type* = Table (owner e tabela ou view) ou SQL Query;
   - **REST Enabled SQL**;
   - **REST Source** (REST Data Source);
   - **Duality View**;
   - **JSON Source** (tabelas com colunas JSON ou JSON Collection Tables);
   - **Sample Data**.
3. **Navigation**: *Use Breadcrumb* e *Use Navigation* (entrada de menu).
4. **Primary Key Column**: confirme ou escolha a chave.
5. **Branch Pages**: *Branch Here on Submit* (destino depois do processamento) e *Cancel and Go To Page*.

**Por que usar o wizard:** ele cria a Form region **com** os page items, o processo **Form - Initialization**, o processo **Form - Automatic Row Processing (DML)**, os botões com *Database Action* e, em modais, o Close Dialog. Uma Form region criada pela Gallery ou pela árvore Rendering **não** traz esses componentes.

Fonte: [Creating a Form Using the Create Page Wizard](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-a-form.html)

### Form region e seus page items: Form Region, Column, Primary Key, Synchronize Page Items
- Cada page item ligado ao form tem, no grupo **Source**, a propriedade **Form Region** (a região de origem) e a **Column**. Os itens da chave têm **Primary Key** marcado. O exemplo da doc é `P4_EMPNO` com coluna `EMPNO` e Primary Key.
- O Page Designer mostra um item por coluna no slot *Region Body*. Se a fonte é **SQL Query**, colunas novas no `SELECT` viram itens automaticamente. Se é tabela ou outra fonte, use **Synchronize Page Items** no menu de contexto.
- **Layout flexível**: o item pertence à Form Region pela Source, mas pode ser exibido em **outra região** (*Layout, Region*), como uma Static Content "Identity" no topo ou abas de um Tabs Container. O fetch e o salvamento continuam funcionando, porque usam a Source, não a região de exibição.
- Itens da Form region aceitam Comment Out, Uncomment e Delete.
- Uma tabela local com FK gera itens **Select List** para as colunas de FK.

Fonte: [Page Items in a Form Region](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/page-items-form-region.html), [Flexible Form Page Item Layout](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/flexible-form-page-item-layout.html), [Retrieving Existing Row by Primary Key](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/retrieving-existing-row-primary-key.html)

### Processo Form - Initialization: buscar a linha pela chave primária (Before Header)
- **Tipo:** processo nativo *Form - Initialization*, em *Pre-Rendering › Before Header*. A propriedade **Form Region** liga o processo à região, que fornece a fonte de dados e as colunas da PK.
- **Comportamento:** na renderização, se **todos** os itens marcados como PK tiverem valor, o processo consulta a fonte pela PK e preenche os itens. É o equivalente a:

```sql
SELECT ENAME, MGR, HIREDATE, SAL, COMM, DEPTNO
INTO :P4_ENAME, :P4_MGR, :P4_HIREDATE, :P4_SAL, :P4_COMM, :P4_DEPTNO
FROM EMP
WHERE EMPNO = :P4_EMPNO
```

- Se algum item de PK estiver nulo, o processo **não faz nada** e o form abre em modo de inclusão.
- **Como a PK chega:** o link da lista passa `P4_EMPNO` na URL, e o engine atribui esse valor ao item **antes** do Pre-Rendering. Por isso o processo já encontra a chave.
- A doc também descreve a "inicialização simples" dos itens, sem fetch, como função desse processo.

Fonte: [Retrieving Existing Row by Primary Key](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/retrieving-existing-row-primary-key.html), [About Page Processes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-page-processes.html)

### Navegação entre registros no form (Next/Previous Primary Key Item, Current Row/Total Item)
O *Form - Initialization* pode calcular a navegação entre registros. Configure no processo:
- **Next Primary Key Item(s)** (ex.: `P9_DEPTNO_NEXT`);
- **Previous Primary Key Item(s)** (ex.: `P9_DEPTNO_PREV`);
- **Current Row/Total Item** (ex.: `P9_DEPTNO_COUNT`, com valor como "3 of 4").

Na Form region, defina um **Order By Clause**. Os itens de chave anterior e próxima costumam ser Hidden, e o contador é Display Only. Os botões `GET_NEXT_...` e `GET_PREVIOUS_...` aparecem por Server-side Condition (item not null). Os branches com *When Button Pressed* passam o próximo ou o anterior como PK ao recarregar a página. Os dois valores podem ser nulos no primeiro e no último registro. No Drill Down, a opção do wizard é *Form Navigation Order*.

Fonte: [Drilling Down to Edit Master and Details](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/drilling-edit-master-and-details.html), [Creating a Drill Down Master Detail Using the Create Page Wizard](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-master-detail-forms.html)

### Itens de Form com Storage Per Request (Memory Only): por que o form abre vazio
O wizard cria os itens da Form region com **Session State, Storage** = *Per Request (Memory Only)*. Os valores não ficam no session state depois do request, o que não é problema porque o form grava antes de fechar. Consequência: esses itens **sempre começam nulos** na renderização, antes das computations e processos de Pre-Rendering. O botão *Create* da lista não passa parâmetros, então a PK fica nula, o Form - Initialization não busca nada e o form abre vazio para inclusão. Nos itens de banco ligados a uma Form region, Memory Only é o padrão e *Per User* não está disponível.

Fonte: [Memory Only Storage for Form Page Items](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/memory-only-storage-form-page-items.html), [Controlling How Page Items Write Session State](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-page-items.html)

### Processo Form - Automatic Row Processing (DML) e a Database Action do botão
O processo nativo **Form - Automatic Row Processing (DML)** (Processing) faz INSERT, UPDATE ou DELETE da linha da Form region. O que decide a operação é a propriedade **Database Action** do botão que submeteu a página (*SQL INSERT action*, *SQL UPDATE action*, *SQL DELETE action*). **Se o botão não tiver Database Action, o processo não faz nada.**

Com os valores padrão (só *Form Region* preenchida), o processo:
- faz o DML na fonte da região;
- **previne lost updates**, checando se outro usuário alterou a linha antes;
- **trava a linha** que vai ser alterada ou excluída;
- **devolve as PKs** para os itens correspondentes depois do insert (útil para processos seguintes, como gravar detalhes).

**Target Type** tem mais dois modos: fazer o DML numa tabela ou view diferente da fonte da região, ou tratar o DML você mesmo em **PL/SQL**.

**Ordem:** em diálogos, o DML vem **antes** do Close Dialog. Ao adicionar uma Form region a uma página que já existe, crie você mesmo o processo DML (com *Form Region*) e configure a *Database Action* dos botões.

Fonte: [Saving Changes with a Page Process](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/saving-changes-page-process.html), [Ensuring the Automatic DML Process](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/ensuring-automatic-dml-process.html), [About Page Processes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-page-processes.html)

### Botões CREATE, SAVE, DELETE e CANCEL gerados pelo wizard (Database Action, condição, validações)

| Botão | Behavior | Execute Validations | Database Action | Server-side Condition |
|---|---|---|---|---|
| `CREATE` | Submit Page | Yes | INSERT | item PK **is null** |
| `SAVE` | Submit Page | Yes | UPDATE | item PK **is not null** |
| `DELETE` | Submit Page | **No** | DELETE | item PK is not null |
| `CANCEL` | Dynamic Action (Cancel Dialog) | No | | |

O DELETE tem *Requires Confirmation*, com estilo **Danger** e mensagem `&APP_TEXT$DELETE_MSG!RAW.`: é o text message traduzível `DELETE_MSG`, e o `!RAW` deixa passar HTML. Para personalizar, crie um text message com a chave `DELETE_MSG` e *Used in JavaScript* ligado.

Fonte: [Conditional Database Action Buttons](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/conditional-database-action-buttons.html)

### Lost Update Detection: Lost Update Type (Row Values, Row Version Column) e Prevent Lost Updates
Lost update é quando dois usuários editam a mesma linha e o último sobrescreve o primeiro. A detecção compara os valores atuais no banco com os lidos ao abrir o registro. Para configurar:
1. Na Form region, defina **Lost Update Type**. A doc diz *Property Editor › aba Attributes › grupo Edit*.
   - **Row Values**: na leitura, calcula um checksum concatenando as colunas atualizáveis e compara no commit.
   - **Row Version Column**: usa uma coluna incrementada a cada update, de preferência por trigger. **Não recomendado** se o form atualiza várias tabelas.
2. No processo *Form - Automatic Row Processing (DML)*, em *Settings*, ligue **Prevent Lost Updates** = On. Ele já vem ligado nos valores padrão gerados pelo wizard.

Ver no §17 a divergência sobre a aba Attributes e a seção Edit no 26.1.5.

Fonte: [Configuring Lost Update Detection](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-lost-update-detection.html), [Saving Changes with a Page Process](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/saving-changes-page-process.html)

### Validações de formulário: Error Message, Display Location e Associated Item
1. Crie a validação (Processing › Validating).
2. Em *Error*, preencha **Error Message**, **Display Location** e **Associated Item**.
   - **Display Location**: na página (inline, abaixo do label do item ou na área de notificação do page template) ou numa página de erro separada.
   - **Associated Item**: o item onde a mensagem aparece.

Para um **erro "duro"**, que interrompe processos e as validações restantes, a mensagem precisa ir para a página de erro. Os masters-details gerados por wizard já trazem validações para colunas `NOT NULL` e para colunas `NUMBER`, `DATE` e `TIMESTAMP`, exceto colunas read-only. Lembre ainda que *Value Required* do item já gera uma validação NOT NULL implícita (§10).

Fonte: [Validating User Input in Forms](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/validating-user-input-in-forms.html), [About Master Detail Forms](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-master-detail-forms.html)

### BLOB em formulários: File Browse/File Upload, colunas auxiliares e remoção da imagem
- Uma coluna `BLOB` vira um item de upload (File Browse). No INSERT o arquivo vai para o BLOB. No UPDATE aparece um link de download ao lado do botão.
- **Storage Type**:
  - *BLOB column specified in Item Source attribute*: declarativo; usa a tabela do processo DML;
  - *Table APEX_APPLICATION_TEMP_FILES*: arquivo temporário, apagado ao fim da sessão ou do request conforme *Purge File At*;
  - *WWV_FLOW_FILES*: só por compatibilidade, não use.
- Recomenda-se ter colunas de MIME type, nome do arquivo, última atualização e charset, ligadas aos atributos *MIME Type Column*, *Filename Column*, *BLOB Last Updated Column* e *Character Set Column*. O charset **não** é preenchido no upload: crie um item para o usuário informar.
- Num form manual sobre tabela própria, use Storage Type = BLOB column numa página com processo DML de linha (a doc cita `DML_PROCESS_ROW`).
- Não há como anular o BLOB pelo item. Para remover a imagem, crie um botão específico:

```sql
UPDATE demo_product_info
   SET product_image = NULL, MIMETYPE = NULL, FILENAME = NULL,
       IMAGE_LAST_UPDATE = NULL, CHARSET = NULL
 WHERE product_id = :P6_PRODUCT_ID;
```

- Para mostrar a imagem, use o item **Display Image** (§11).

Fonte: [Understanding BLOB Support in Forms](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-blob-support-in-forms.html)

### Lista e edição (Report with Form): Link Column, Set Items e valor `\#EMPNO#\`
O par gerado pelo wizard funciona assim:
1. Na lista (Interactive Report), *Link Column* = **Link to Custom Target** aponta para a página do form. Em *Set Items* vai o item de PK do form com o valor `\#EMPNO#\`. As **barras invertidas** fazem o valor passar literalmente, mesmo que contenha delimitadores como `:`.
2. O ícone do link é `<span role="img" aria-label="Edit" class="fa fa-edit" title="Edit"></span>`.
3. O form (por padrão um **Drawer** modal) busca a linha com Form - Initialization, salva com Automatic Row Processing e fecha com Close Dialog.
4. A lista trata *Dialog Closed* com Refresh da região.

Fonte: [Linking to the Edit Page](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/linking-edit-page.html), [Studying a List and Edit Flow](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/studying-list-and-edit-flow.html)

### Form submete sem erro mas não grava nada no banco
**Sintoma:** o botão salva, aparece mensagem de sucesso ou o diálogo fecha, mas a tabela não muda.
**Causa:** o botão que submeteu não tem **Database Action** (INSERT, UPDATE ou DELETE), então o *Form - Automatic Row Processing (DML)* não faz nada. Outra causa possível: a Form region foi criada à mão e não existe processo DML com *Form Region* configurada.
**Correção:** no botão, *Behavior, Database Action*. Na aba Processing, um processo *Form - Automatic Row Processing (DML)* com *Form Region* = a região, sequenciado antes do Close Dialog.
**Prevenção:** crie forms pelo Create Page Wizard. Ao adicionar uma Form region a uma página existente, siga o checklist "processo DML + Database Action".

Fonte: [Conditional Database Action Buttons](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/conditional-database-action-buttons.html), [Ensuring the Automatic DML Process](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/ensuring-automatic-dml-process.html)

### Form abre vazio ao clicar em editar um registro
**Sintoma:** o link da lista abre o form, mas os campos vêm vazios.
**Causa:** a PK não foi passada no link (*Set Items*), ou o item de PK não está marcado como *Primary Key* na Source, ou falta o processo *Form - Initialization* (ou ele não aponta para a Form region).
**Correção:** confira o link (item de PK = `\#COLUNA_PK#\`), o *Source, Primary Key* do item e o processo Form - Initialization em Before Header com *Form Region* certa.

Fonte: [Retrieving Existing Row by Primary Key](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/retrieving-existing-row-primary-key.html)

### Interactive Grid editável como formulário de várias linhas (resumo)
O usuário inclui, altera e exclui linhas no próprio grid (Row Actions: Single Row View, Add Row, Duplicate Row, Delete Row, Refresh Row, Revert Changes) e salva com o botão *Save* do grid. O processamento é feito pelo processo **Interactive Grid - Automatic Row Processing (DML)**. Num processo PL/SQL com *Editable Region* = o grid, o código roda **uma vez por linha** alterada, com `:APEX$ROW_STATUS` = `C` (criada), `U` (atualizada) ou `D` (excluída), e as colunas são acessadas como `:COLUNA`. Os detalhes do grid estão no documento de relatórios.

Fonte: [About Making an Interactive Grid Editable](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-making-grids-editable.html), [Drilling Down to Edit Master and Details](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/drilling-edit-master-and-details.html)

---

## 9. Master-detail

### Três padrões de master-detail: Stacked, Side by Side e Drill Down

| Padrão | Páginas | Mestre | Detalhe | Wizards |
|---|---|---|---|---|
| **Stacked** | 1 | Interactive Grid editável | Interactive Grid(s) editável(is) coordenado(s) | Create App e Create Page |
| **Side by Side** | 1 + modais | Lista compacta à esquerda (Classic Report Media List) | Dados do mestre (Value Attribute Pairs) + relatório(s) de detalhe, com edição em drawer | Create App e Create Page |
| **Drill Down** | 2 | Interactive Report | Form do mestre + Interactive Grid do detalhe na 2ª página | Só Create Page |

São relações um-para-muitos (header/lines, parent/child).

Fonte: [Reviewing Master/Detail Wizard Patterns](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/reviewing-master-detail-wizard-patterns.html), [About Master Detail Forms](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-master-detail-forms.html)

### Stacked master-detail: Master Region e Master Column no grid de detalhe
- Clicar numa linha do grid mestre atualiza o grid de detalhe com as linhas daquela PK.
- Os grids **não têm botão Save próprio**. O botão *Save* da página submete tudo numa única transação, e se uma validação falhar nada é salvo. O usuário pode criar um mestre novo e vários detalhes dele antes de salvar.
- **Configuração** no grid de detalhe:
  1. **Master Region** = o grid mestre;
  2. em cada coluna de FK, **Master Column** = a coluna do mestre (ex.: `DEPTNO` → `DEPTNO`).

  **Não** escreva o filtro mestre/detalhe no Where Clause: o runtime faz isso sozinho. Filtros extras podem ser adicionados normalmente.
- Para um "neto", repita a configuração no terceiro grid.

Fonte: [Configuring Master/Detail Grids](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configuring-master-detail-grids.html)

### Side by Side master-detail: busca, lista Media List, item oculto da seleção e drawers
Página com template *Left Side Column*.
- **Busca:** o item `P4_SEARCH` tem uma DA no evento *Key Press* com a Client-side Condition `this.browserEvent.which === apex.jQuery.ui.keyCode.ENTER` e as ações *Refresh* (lista) e *Cancel Event*. O Cancel Event impede o navegador de submeter a página com Enter num formulário de campo único. A região lista `P4_SEARCH` em **Page Items to Submit**.
- **Lista mestre:** Classic Report com o template **Media List** (Named Column). A query precisa ter colunas com os nomes que o template espera: `LINK`, `LIST_CLASS`, `LIST_TITLE`, `LIST_TEXT`...
  - `LINK` vem de `apex_page.get_url(p_items => 'P4_DEPTNO', p_values => "DEPTNO")`. Sem `p_page`, o link aponta para a própria página.
  - `LIST_CLASS` devolve `'is-active'` na linha selecionada.
- **Seleção:** o Hidden `P4_DEPTNO` tem Storage *Per Session (Persistent)*. A região do mestre (template *Value Attribute Pairs - Column*, sem paginação) filtra `DEPTNO = :P4_DEPTNO` e fica oculta quando o item é nulo. O detalhe (template Standard) filtra a FK pelo mesmo item.
- **Criar e editar:** *Create* abre o form do mestre em drawer sem parâmetros. *Edit* passa a PK. O botão `+` do detalhe passa `P4_DEPTNO` para a FK do form do detalhe (`P7_DEPTNO`).
- **Editar detalhe:** não vem pronto. Transforme a coluna (ex.: `ENAME`) em *Link* para o form do detalhe passando a PK do detalhe.

```sql
select "DEPTNO",
       apex_page.get_url(p_items => 'P4_DEPTNO', p_values => "DEPTNO") LINK,
       case when coalesce(:P4_DEPTNO,'0') = "DEPTNO" then 'is-active' else ' ' end LIST_CLASS,
       substr("DNAME",1,50) LIST_TITLE,
       substr("LOC",1,50)   LIST_TEXT
  from "DEPT" x
 where (:P4_SEARCH is null
        or upper(x."DNAME") like '%'||upper(:P4_SEARCH)||'%'
        or upper(x."LOC")   like '%'||upper(:P4_SEARCH)||'%')
 order by "DNAME"
```
(Consulta resumida da doc.)

Fonte: [Showing Master/Detail Data Side by Side](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/showing-master-detail-data-side-side.html)

### Drill Down master-detail: Form do mestre + Interactive Grid do detalhe numa transação
- A 1ª página é um Interactive Report com ícone de edição. A 2ª tem a Form region do mestre e um IG editável do detalhe. O *Save* do grid fica **desligado**, e o *Apply Changes* da página salva mestre e detalhes juntos.
- **Configuração mínima do grid de detalhe:**
  1. Where Clause `DEPTNO = :P9_DEPTNO` e o item da PK do mestre em *Page Items to Submit*;
  2. a coluna FK `DEPTNO` com **Default** = item `P9_DEPTNO`, para os detalhes novos já nascerem ligados ao mestre.
- Tem navegação anterior/próximo (ver "Navegação entre registros no form").
- Dica de layout: breadcrumb com *Use Compact Style*; Form region com *Header = Hidden* e *Style = Remove UI Decoration*.

Fonte: [Drilling Down to Edit Master and Details](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/drilling-edit-master-and-details.html)

### Criar mestre e detalhes novos no mesmo submit (APEX$ROW_STATUS e ordem dos processos)
Por padrão o grid de detalhe fica oculto quando a PK do mestre é nula, e o usuário precisa salvar o mestre antes de incluir detalhes. Para aceitar os dois de uma vez:
1. Tire a Server-side Condition do grid.
2. Crie um processo *Execute Code* com **Editable Region** = o grid, sequenciado **depois** do processo DML do form (que devolve a nova PK em `P9_DEPTNO`) e **antes** do processo de DML do grid:

```plsql
-- roda uma vez por linha do grid; só atribui a FK nas linhas criadas
if :APEX$ROW_STATUS = 'C' then
    :DEPTNO := :P9_DEPTNO;
end if;
```

Fonte: [Drilling Down to Edit Master and Details](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/drilling-edit-master-and-details.html)

### Criar master-detail pelos wizards (passos e chaves)
- **Create Page › Component › Master Detail** › estilo *Stacked*, *Side by Side* ou *Drill Down*.
- **Stacked:** Page Definition; fonte do mestre (Local, REST Enabled SQL, REST Source, Duality View, JSON Source); **Primary Key Column 1/2** do mestre; *Detail Region Title*; fonte do detalhe com *Show Only Related Tables*; PK do detalhe; **Master Detail Foreign Key**.
- **Side by Side:** *Starting Page Number* (o wizard cria várias páginas a partir desse número); *Master Table* (o nome é case sensitive se digitado); *Primary Display Column* e *Secondary Display Column*; uma ou mais *Detail Table*. Para fontes externas, use *Advanced*.
- **Drill Down:** página mestre e página de detalhe com números próprios; PK 1/2; **Form Navigation Order**; fonte do detalhe; PK do detalhe; Master Detail Foreign Key.
- No **Create Application Wizard**: *Add Page › Master Detail › Page Type* = Side by Side (Table, Primary e Secondary Display Column, Detail Table) ou Stacked (Table, Detail Table).
- Também é possível criar um master-detail a partir de um Interactive Grid existente.

Fonte: [Creating Master Detail Forms](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-master-detail-forms.html)

### Nota sobre um erro de digitação na doc do Drill Down (Page Items to Submit)
O texto oficial diz que o grid de detalhe "lista `P9_EMPNO` em Page Items to Submit", mas o Where Clause usa `:P9_DEPTNO`. Pela regra geral da doc (todo item usado como bind na fonte da região vai em *Page Items to Submit*), o item correto é **`P9_DEPTNO`**.

Fonte: [Drilling Down to Edit Master and Details](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/drilling-edit-master-and-details.html), [Configure Items to Submit and Return](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configure-items-submit-and-return.html)

---

## 10. Itens de página: conceitos e atributos

### Page items × application items
**Page items** ficam numa página e têm propriedades de interface: tipo, label, label template etc. **Application items** não pertencem a nenhuma página e não têm UI: funcionam como variáveis globais da sessão.

Fonte: [About the Differences Between Page Items and Application Items](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-page-items.html)

### Regras de nome de item (P<página>_NOME, 30 caracteres, ASCII)
O nome de um item:
- é único na aplicação;
- não tem aspas;
- começa com letra ou número e continua com letras, números ou `_`;
- não diferencia maiúsculas de minúsculas;
- deve ter **até 30 caracteres**, porque nomes maiores não podem ser usados como bind (`:ITEM`);
- só usa ASCII básico.

Boa prática e padrão dos wizards: o prefixo `P<nº da página>_` (ex.: `P1_NAME`). O nome precisa ser um identificador Oracle válido.

Fonte: [About Item Naming Conventions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-page-items.html)

### Referenciar o valor de um item: `:ITEM`, `V('ITEM')`, `NV('ITEM')`, `&ITEM.`

| Contexto | Sintaxe | Uso |
|---|---|---|
| SQL e PL/SQL da app | `:MY_ITEM` | Bind padrão (nomes até 30 bytes) |
| PL/SQL em packages, procedures e functions | `V('MY_ITEM')` / `NV('MY_ITEM')` (numérico) | **Evite em SQL**, porque pode prejudicar a performance |
| Texto estático e HTML | `&MY_ITEM.` | Substituição exata. **Nunca use em SQL ou PL/SQL**, porque abre caminho para SQL injection |

Formas de definir o valor:
- **Source** do item;
- atribuição em PL/SQL (`:MY_ITEM := 'x';`);
- URL `f?p=100:101:<sessão>::NO::MY_ITEM:ABC`;
- **computation**;
- `APEX_UTIL.SET_SESSION_STATE('MY_ITEM', valor)`.

Em código reutilizável, a doc recomenda receber os valores como **parâmetros** de procedure ou function e passar `:P1_X` na chamada.

Fonte: [Referencing Item Values](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-page-items.html), [Using Data Values in SQL and PL/SQL](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/using-data-values-sql-and-pl-sql.html)

### Bind variables são sempre VARCHAR2 (exceções CLOB e BOOLEAN)
Mesmo um Date Picker ou um Number Field é ligado como `VARCHAR2`. Números costumam funcionar pela conversão implícita do banco. Datas podem dar erro se o format mask do item for diferente do padrão da app: converta explicitamente. As exceções são:
- **Session State, Data Type** = `CLOB`, disponível em Hidden, Textarea e Rich Text Editor (e em outros tipos que oferecem VARCHAR2/CLOB, como Display Only e Markdown Editor);
- `BOOLEAN` em **Switch** e **Checkbox**, só com **banco 26ai**.

Fonte: [Values Bind as Strings](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/values-bind-strings.html)

### Ler e definir itens em JavaScript: `$v`, `$s` e `apex.item().setValue`
O `id` HTML do item é o nome dele (ex.: `P1_FIRST_NAME`), não o label.

```javascript
$v('P1_FIRST_NAME');            // valor
$s('P1_FIRST_NAME', 'Joe');     // define o valor
apex.item('P1_ITEM').setValue('10', 'SALES', true); // valor, display value, suprime o change
```

`setValue` **não altera o session state** até o submit, um AJAX que envie o item ou uma DA. Ele dispara `change` por padrão (o que alimenta cascading LOV e DAs de Change). Passe `true` em `pSuppressChangeEvent` quando o valor for definido dentro do handler de change do **mesmo** item, para evitar loop. Em Popup LOV, use `pDisplayValue` quando o display for diferente do return. O objeto item também tem `getValue`, `disable`, `enable`, `hide`, `show`, `isChanged` e `refresh`.

Fonte: [About Referencing Items Using JavaScript](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-page-items.html), [item (setValue)](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/item.html)

### Posicionar o item: Layout, Region e Layout, Position
- **No nível da página:** deixe *Layout, Region* vazio e escolha *Layout, Position* (slot da página).
- **Numa região:** *Layout, Region* = a região e *Position* = o slot dentro dela (ex.: Region Body).

Depois disso valem as regras do grid (§7).

Fonte: [Positioning Page Items](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-page-items.html)

### Default do item (Default, Type): Static, Item, SQL Query, PL/SQL Expression, Function Body, Sequence
O default é usado quando o valor **não vem do session state** e a **Source é nula**.

| Default Type | Valor |
|---|---|
| Static | O texto de *Static Value* |
| Item | O session state de outro item |
| SQL Query | O valor devolvido pela query |
| SQL Query returning Colon Delimited List | A lista `a:b:c`, necessária para checkbox, radio group e shuttle |
| PL/SQL Expression | O resultado da expressão (sem `;` no final) |
| PL/SQL Function Body | O `return` do bloco |
| Sequence | O próximo valor da sequence |

**Source × Default:** a Source (coluna do form, SQL, PL/SQL, ou várias linhas com "SQL Query (return multiple values)", que gera lista separada por `:`) dá o valor "real". O Default só entra quando não há valor.

Fonte: [Defining Default Values for Page Items](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-page-items.html), [Creating a Shuttle Item on the Form Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-shuttle-item-on-form-page.html)

### Session State, Storage (Maintain Session State): Per Request, Per Session, Per User
- **Per Request (Memory Only)**: o valor não vai para o banco e só existe durante o request. Se uma chamada AJAX precisar do item, inclua-o em *Page Items to Submit* ou *Items to Submit*. É o **padrão para itens de banco de Form region**, onde *Per User* não aparece. A doc recomenda esse modo para *Manual Entries Items* de Combobox e para senhas.
- **Per Session (Persistent / Disk)**: guardado no banco durante a sessão inteira.
- **Per User (Persistent / Disk)**: guardado no repositório de atributos do usuário e disponível em sessões futuras.

Quando a página é submetida, o engine grava no session state os valores digitados (de acordo com o Storage). Um item de filtro em Memory Only não aciona o aviso de mudanças não salvas num redirect.

Fonte: [Controlling How Page Items Write Session State](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-page-items.html), [Managing Session State Values](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-session-state-values.html), [Understanding AJAX and Redirect](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-ajax-and-redirect.html)

### Read Only do item (Read Only, Type) e prioridade sobre região e página
*Read Only, Type* recebe uma condição. Quando ela é verdadeira, o item é renderizado como **Display Only**. Sem condição, o item renderiza normalmente. **Never** força o item a ser editável e **sobrepõe** condições de read only da região ou da página. Não confunda com a DA *Disable*: item desabilitado **não é enviado** no submit (§14).

Fonte: [Displaying Read Only Page Items](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-page-items.html)

### Server-side Condition: renderizar ou processar o item condicionalmente
*Server-side Condition, Type* define quando o componente é renderizado ou processado (expressões PL/SQL, item nulo ou não nulo, request contido em valor, *Never*...). Componentes com condição falsa **não existem no DOM**, o que importa para DAs e refresh (ver §17). Vale para itens, botões, regiões e processos.

Fonte: [Displaying Conditional Page Items](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-page-items.html), [Displaying a Button Conditionally](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-buttons.html)

### Value Required e a mensagem APEX.PAGE_ITEM_IS_REQUIRED
Com *Validation, Value Required* = On, **e o item visível**, o APEX faz uma validação NOT NULL implícita no submit. Para trocar o texto padrão, crie em *Shared Components › Text Messages* a mensagem `APEX.PAGE_ITEM_IS_REQUIRED`. O local de exibição segue o atributo de aplicação *Default Error Display Location*. Alguns tipos também têm *Validation, Maximum Length*.

Fonte: [About Item Types (Number Field, Select Many, Select One)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-item-types.html)

### Segurança do item: Authorization Scheme, Session State Protection, criptografia e Restricted Characters
- **Authorization Scheme**: precisa ser TRUE para o item ser renderizado ou processado.
- **Session State Protection**:
  - *Unrestricted*: aceita valor por URL ou form sem checksum;
  - *Checksum Required* com escopo **Application Level** (workspace e app), **User Level** (workspace, app e usuário) ou **Session Level** (sessão);
  - *Restricted - May not be set from browser*: o valor não muda por URL nem por POST, só por processos e computations. Vale para itens que não são de entrada (ex.: Display Only sem gravar estado) e é respeitado **mesmo com SSP desativado**.
- **Store value encrypted in session state**: para dados sensíveis, que de outra forma poderiam ser lidos nas tabelas de metadados.
- **Restricted Characters** (contra XSS):
  - *All characters can be saved*;
  - *Allowlist for a-Z, 0-9 and space*;
  - *Blocklist HTML command characters (<>")*;
  - *Blocklist &<>"/;,*|=% and --*;
  - o mesmo bloqueio acrescido de quebra de linha.

Fonte: [Configuring Page Item Security](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-page-items.html)

### Value Protected em itens Hidden (e em QR Code)
*Settings, Value Protected* = On impede que o valor de um item Hidden seja alterado no POST. **Desligue** quando o próprio JavaScript ou uma DA da página define o valor do Hidden.

Fonte: [Hidden](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-item-types.html), [Unprotecting Client-Set Hidden Items](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/unprotecting-client-set-hidden-items.html)

### Session state protection violation: This may be caused by manual alteration of protected page item
**Sintoma:** ao submeter aparece `Session state protection violation: This may be caused by manual alteration of protected page item P60_LATITUDE.`
**Causa:** um item Hidden com **Value Protected** = On teve o valor alterado no cliente (por DA, `$s` ou plug-in).
**Correção:** em *Settings*, desligue **Value Protected** nos Hidden preenchidos no cliente.
**Prevenção:** ao criar um Hidden que vai receber valor de DA, desligue o Value Protected na hora. Mantenha ligado nos Hidden que só o servidor define, como PKs.

Fonte: [Unprotecting Client-Set Hidden Items](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/unprotecting-client-set-hidden-items.html)

### Format Mask do item
*Appearance, Format Mask* controla a exibição de números e datas. Aplique máscara de número só a números e de data só a datas, ou dá erro de conversão. No Number Field, o locale define o separador decimal da digitação. No Date Picker em *Native HTML*, a máscara é fixada pelo APEX e não pode ser mudada.

Fonte: [Applying a Format Mask to an Item](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-page-items.html)

### Quick Picks: valores de um clique abaixo do item
*Quick Picks, Type*:
- **Static**: até 10 pares label/valor.
- **Shared List of Values**: só as entradas com *Quick Pick Rank*. Numa LOV dinâmica, a coluna é a *Quick Pick Rank Column*. Tem *Maximum Displayed Entries* (1 a 10).
- **SQL Query** (`select display, return ...`): coloque alias nas expressões. Os valores precisam ser coerentes com a LOV do item.

*Link Attributes* adiciona atributos HTML a cada link.

Fonte: [Changing an Existing Item to Use Quick Picks](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-page-items.html)

### Multiple Values (Type e Separator) e como processar listas de valores
Disponível em Checkbox Group, Combobox, List Manager, Popup LOV, Select List, Select Many e Shuttle. É **obrigatório** em Checkbox Group, List Manager, Select Many e Shuttle.
- **Type**:
  - *No*;
  - *Delimited List* (ex.: `APEX,SQL,PL/SQL`);
  - *JSON Array* (ex.: `["APEX","SQL"]`; JSON inválido gera erro).
- **Separator**: `"`, `\` e caracteres no formato `\xxxx` **não** são aceitos.

```sql
select column_value from apex_string.split(:ITEM_NAME, ',');
select element from json_table(:ITEM_NAME, '$[*]' columns element varchar2 path '$');
```

Fonte: [Configuring Multiple Value Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-page-items.html)

### Tratar o valor de um select múltiplo ou shuttle (colon-delimited)
O valor enviado é uma string separada por `:`. Duas formas de usar:

```sql
-- filtrar um relatório pelos departamentos selecionados
select ename, job, sal from emp e
 where instr(':'||:P1_DEPTNO||':', ':'||e.deptno||':') > 0
```
```plsql
declare
  l_selected apex_t_varchar2;
begin
  l_selected := apex_string.split(p_str => :P1_DEPTNO, p_sep => ':');
  for i in 1 .. l_selected.count loop
    insert into report_audit_table (report_date, selected_department)
    values (sysdate, l_selected(i));
  end loop;
end;
```

Fonte: [Working with Multiple Select List Item](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-page-items.html)

### Item Utilities: relatórios de Password Items e Conditional Items
*Utilities › Page Specific Utilities › Item Utilities* tem dois relatórios: **Password Items** (a recomendação é que senhas não gravem session state) e **Conditional Items**.

Fonte: [Viewing Item Utilities](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-page-items.html)

### Criar page item no Page Designer (Rendering ou Gallery)
Botão direito na região › *Create Page Item* (ou *Create Page Item Below* num item existente), ou arraste da aba Items da Gallery. Preencha *Identification, Name* e *Type*. Os atributos dependem do tipo e as mudanças ficam marcadas até salvar.

Fonte: [Creating a Page Item from the Rendering Tab](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-page-item-from-rendering-tab.html), [Adding a Page Item from the Gallery](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/adding-page-item-from-gallery.html)

---

## 11. Catálogo de tipos de item

### Tabela-resumo dos tipos de item nativos (APEX 26.1)

| Tipo | Valor / uso | Em coluna de IG? |
|---|---|---|
| Checkbox | Um checkbox, valor marcado ou desmarcado | sim |
| Checkbox Group | Vários checkboxes de uma LOV, valores separados por `:` | sim |
| Color Picker | Cor (Popup, Inline, Color-only Popup, Native) | sim |
| Combobox | Texto livre + sugestões de LOV, chips em modo múltiplo | sim |
| Date Picker | Data (e hora) | sim |
| Date Picker (jQuery) | **Desuportado** | |
| Display Image | Imagem de BLOB ou de URL | **não** |
| Display Map | Mapa a partir de um GeoJSON Point | |
| Display Only | Texto não editável (Plain Text, HTML, Markdown) | |
| File Upload | Upload de arquivo | **não** |
| Geocoded Address | Endereço convertido em coordenada | |
| Hidden | Valor no session state, não renderizado | |
| Image Upload | Upload de imagem com recorte e redimensionamento | |
| List Manager | Popup LOV + botões Add e Remove, valores separados por `:` | **não** |
| Markdown Editor | Editor Markdown | **não** |
| Number Field | Número formatado e validado | |
| Password | Senha | |
| Percent Graph | Valor de 0 a 100 como gráfico | |
| Popup LOV | Busca em popup, para listas grandes | |
| QR Code | Codifica o valor num QR | |
| Radio Group | Escolha única | |
| Rich Text Editor | HTML ou Markdown formatado | |
| Select List | Lista inline, para listas pequenas | |
| Select Many | Múltipla escolha com busca | |
| Select One | Escolha única com busca | |
| Shuttle | Duas listas (disponíveis e selecionados), valores separados por `:` | |
| Star Rating | De 1 a 10 estrelas | |
| Switch | Liga/desliga (flip, pill button ou select list) | |
| Text Field | Texto | |
| Text Field with Autocomplete | Texto livre com autocomplete | |
| Textarea | Texto em várias linhas | |

Os plug-ins aparecem como *Nome [Plug-in]*. A coluna "Em coluna de IG?" só registra o que a doc diz explicitamente.

Fonte: [About Item Types](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-item-types.html)

### Checkbox e Switch: Checked/Unchecked Value, On/Off Value e Use Defaults
- **Checkbox**: *Use Defaults* = On usa *Shared Components › Component Settings › Checkbox*. Com Off, defina **Checked Value** e **Unchecked Value** (até 255 caracteres; o Unchecked pode ficar em branco para gravar NULL). Se o item receber um valor que não é nenhum dos dois, vale o Unchecked. Numa faceta de Faceted Search baseada em LOV, o Checked Value precisa coincidir com o display **e** com o return da LOV; se não coincidir, use uma faceta Checkbox Group.
- **Switch**: aparece como flip toggle (padrão), Pill Button ou Select List. Com *Use Defaults* = Off, defina **On Value / On Label** e **Off Value / Off Label**. O Off Value em branco grava NULL, e é usado se o valor não bater com nenhum dos dois. *Value Required* está disponível.
- Para sim/não, a doc recomenda Checkbox ou Switch em vez de Checkbox Group.
- Com banco 26ai, Switch e Checkbox podem ter Data Type `BOOLEAN`.

Fonte: [Checkbox, Switch](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-item-types.html), [Values Bind as Strings](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/values-bind-strings.html)

### Checkbox Group e Radio Group: Number of Columns e Page Action on Selection
- **Checkbox Group**: exige LOV. Grava os valores marcados separados por `:`. *Settings, Number Columns* define as colunas de exibição. Multiple Values é obrigatório.
- **Radio Group**: escolha única. *Number of Columns*. **Page Action on Selection** define o que acontece ao escolher, como *Submit Page*. Se for submit, aparece *Execute Validations* (Off pula as validações). Combine com o atributo *Always Execute* das validações.

Exemplo de LOV: `select ename, empno from emp` (display, return).

Fonte: [Checkbox Group, Radio Group](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-item-types.html)

### Select List: lista inline para listas pequenas (Page Action on Selection, Allow Multi Selection)
Boa para listas pequenas e discretas, porque a escolha é rápida e não tira o foco da página. Para listas grandes, use Popup LOV. Atributos:
- **Page Action on Selection** e *Execute Validations*, como no Radio Group;
- **Allow Multi Selection**: permite escolher vários valores (a doc diz que eles voltam separados por vírgula; veja também *Multiple Values*);
- *Multiple Values*;
- *Value Required*.

Na LOV, use `select display, return from ... order by ...`.

Fonte: [Select List](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-item-types.html)

### Select One e Select Many: Infinite Scroll, Fetch on Search, Value HTML Expression
São itens de LOV com busca, grupos e template directives. São mais amigáveis que Select List e Popup LOV.

| Atributo | Efeito |
|---|---|
| Infinite Scroll | Busca mais linhas ao rolar. Desligado, mostra até *Maximum Values in List* (padrão 250) |
| Fetch on Search | Consulta o banco a cada tecla. Desligado, carrega tudo no load da página. **Recomendado para listas grandes** |
| Use Cache (Select One) | Cacheia as buscas no navegador. Só aparece com Fetch on Search |
| Value HTML Expression | HTML e template directives por opção. As colunas extras precisam estar em *Additional Display Columns* de uma **LOV compartilhada**. `&APEX$ITEM%d.` é o display e `&APEX$ITEM%r.` o return |
| Search: Match Type | *Contains* (impede o uso de índice) ou *Starts With* |
| Search: Case-Sensitive, Minimum Characters | Comportamento da busca |
| Display Values As (Select Many, sem Use Defaults) | *Chips* ou *Comma-separated list* (com contador) |
| Multiple Values (Select Many) | Delimited List ou JSON Array |
| Session State, Storage | Per Request, Per Session ou **Per User** |

```html
<div class="your-container">
  <span class="your-item">Name: &NAME.</span>
  {if ?CAPITAL/}<span class="your-item">Capital: &CAPITAL.</span>{endif/}
</div>
```

Fonte: [Select One, Select Many](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-item-types.html)

### Combobox: texto livre + LOV, Manual Entries Item
Para listas **pequenas** em que o usuário pode digitar valores próprios. Com *Multiple Values*, as escolhas viram chips. Atributos:
- *Multi Selection*: o dropdown fica aberto, com um checkbox por opção;
- *Infinite Scroll*, *Maximum Values in List* e *Fetch on Search*. Sem Fetch on Search, o APEX consolida duplicatas (afetado por *Case Sensitive*). **Com Fetch on Search, a LOV não pode ter coluna de display configurada**;
- **Manual Entries Item**: um item, de preferência Hidden com *Value Protected* = Off e Storage *Per Request*, que recebe as entradas digitadas que não estão na LOV. É **obrigatório** quando a LOV tem display e return. Com ele, o valor do Combobox (no session state e em `apex.item(...).getValue()`) contém **só** os valores que existem na LOV, e os digitados ficam no Manual Entries Item. A sincronia é só do Combobox para esse item;
- *Value HTML Expression*, *Match Type*, *Case-Sensitive* e *Minimum Characters*;
- *Session State*: Data Type VARCHAR2 ou CLOB, e Storage.

Para seleção sem texto livre, use Select List, Select One ou Select Many. Para listas grandes, Popup LOV.

Fonte: [Combobox](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-item-types.html)

### Popup LOV: listas grandes, Manual Entry, Initial Fetch, colunas extras
É o item indicado para **listas grandes**, porque a busca reduz o que é carregado. Atributos:
- **Display As**;
- **Initial Fetch** (como os dados são buscados na primeira abertura ou depois de um refresh por cascade);
- **Manual Entry** (Yes deixa digitar valores; nesse caso digita-se o *return value* da LOV);
- **Fetch on Search** (Yes filtra enquanto digita; No só ao pressionar Enter ou clicar em buscar);
- *Title*;
- Search: Match Type, Case-Sensitive e **Minimum Characters** (os displays mais curtos que o mínimo não são encontrados);
- Multiple Values: No, Delimited List ou JSON Array.

Com uma LOV compartilhada dinâmica, a Popup LOV mostra **colunas adicionais**, busca nelas e, em seleção única, pode **devolver valores das colunas extras para outros itens** ou colunas de grid. Nas expressões do SELECT, use alias.

```sql
select ename||' '||job display_value, empno from emp
```

Fonte: [Popup LOV](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-item-types.html), [List-Driven Items Available](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/list-driven-items-available.html), [Additional Shared LOV Features](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/additional-shared-lov-features.html)

### Shuttle e List Manager: seleção múltipla com valores separados por `:`
- **Shuttle**: duas caixas (disponíveis e selecionados). *Show Controls*: None, Moving Only, Ordering Only ou All. Exige LOV e Multiple Values. Para pré-carregar a seleção, use **Source, Type** = *SQL Query (return multiple values)*: cada linha devolvida vira um valor da lista `a:b:c`.

```sql
-- LOV
select ename, empno from emp order by 1
-- Source (return multiple values)
select empno from emp where deptno = :P2_DEPTNO order by ename
```

- **List Manager**: Popup LOV + Add/Remove. Atributo *Fetch*. Não funciona em IG. Como o Text Field with Autocomplete, usa só o return da LOV.

Fonte: [Shuttle, List Manager](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-item-types.html), [Creating a Shuttle Item on the Form Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-shuttle-item-on-form-page.html)

### Text Field, Text Field with Autocomplete e Textarea
- **Text Field**:
  - *Subtype* (HTML5) troca o teclado virtual e, quando o item é read only, gera o link adequado;
  - **Trim Spaces**: Leading, Trailing, Leading and Trailing ou None;
  - **Text Case**: No Change, Lower ou Upper.
- **Text Field with Autocomplete**: texto livre com sugestões de uma query de uma coluna. Atributos:
  - *Infinite Scroll* e *Fetch On Type*;
  - *Use Cache*;
  - *Maximum Values in List*;
  - *Match Type*: Contains & Case Sensitive, Exact & Case Sensitive, Contains & Ignore Case ou Exact & Ignore Case. As variantes Contains impedem o uso de índice;
  - *Minimum Characters*.
- **Textarea**:
  - *Resizable* e **Auto-Height**;
  - **Character Counter**;
  - Trim Spaces;
  - Data Type VARCHAR2 ou **CLOB**.

Fonte: [Text Field, Text Field with Autocomplete, Textarea](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-item-types.html)

### Number Field: formatação, Minimum/Maximum Value e limite de precisão
O número é validado no cliente e no servidor, sem precisar de validação extra, e formatado no cliente depois da digitação. Atributos:
- *Format Mask*;
- **Minimum Value / Maximum Value**, estáticos ou por substituição;
- *Number Alignment*, ignorado em read only ou com HTML Form Element Attributes;
- **Virtual Keyboard**: Decimal, Numeric ou Text.

**Limite:** a precisão é de 15 a 17 dígitos (IEEE 754 do JavaScript). Para números muito grandes, como PKs enormes, a doc recomenda **Text Field**.

Fonte: [Number Field](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-item-types.html)

### Date Picker: Show Time, Display As (Popup, Inline, Native HTML), Minimum/Maximum Date
- A hora só aparece no popup se o **Format Mask** tiver componentes de hora, e *Show Time* liga a parte de hora.
- **Display As**:
  - *Popup*;
  - *Inline* (calendário fixo, sem campo de texto);
  - *Native HTML* (`date` ou `datetime-local`): a máscara é fixada pelo APEX e o usuário vê o formato do locale dele. É bom para mobile.
- **Minimum / Maximum Date**: None, **Item** (vem de outro item) ou Static (absoluta ou relativa a hoje).
- *Multiple Months*.
- Com *Use Defaults* = Off:
  - Show Week, Month Picker e Year Picker;
  - Paginate by Multiple Months;
  - Show Today Button e Show Clear Button (só Inline);
  - **Days Outside Month**: Hidden, Selectable ou Visible;
  - **Time Increment** (minutos);
  - **Show On**: Item Focus ou Icon Click.
- O antigo **Date Picker (jQuery)** está desuportado. *Utilities › Upgrade Application* converte todos de uma vez.

Fonte: [Date Picker, Date Picker (jQuery)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-item-types.html)

### Password: Storage, criptografia e Submit when Enter pressed
- *Submit when Enter pressed*.
- A template option **Hide Password Visibility** desativa o botão de mostrar a senha.
- **Storage Per Request (Memory Only)** é o recomendado para valores sensíveis. Se for Per Session, ligue *Store value encrypted in session state*.
- Também tem Authorization Scheme e Session State Protection, cujos níveis estão no §10.

Fonte: [Password](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-item-types.html)

### Hidden e Display Only: Value Protected, Send On Page Submit, Based On
- **Hidden**: o valor fica no session state e não é exibido. *Value Protected* (§10), Data Type VARCHAR2 ou CLOB, Storage Per Request ou Per Session. **Hidden não aparece no Layout do Page Designer**, só na árvore.
- **Display Only**:
  - *Format*: Plain Text, HTML ou Markdown;
  - *Based On*: Page Item Value ou *Display Value of List of Values* (mostra o display de uma LOV);
  - *Show Line Breaks*;
  - **Send On Page Submit**: se o valor vai junto no submit;
  - Data Type e Storage.

Fonte: [Hidden, Display Only](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-item-types.html)

### File Upload: Display As, Storage Type, APEX_APPLICATION_TEMP_FILES e Allow Multiple Files
- **Display As**: Inline File Browse, Inline Dropzone, Block Dropzone ou Native File Browse.
- *Dropzone Title* e *Description*: os padrões são os text messages `APEX.ITEM.FILE.DROP_FILE(S)`, `APEX.ITEM.FILE.DROP_OR_CHOOSE_FILE(S)` e `APEX.ITEM.FILE.DROP_OR_SELECT_FILE(S)`.
- **Capture Using**: abre a câmera no mobile, mas aí o usuário não consegue escolher arquivos.
- **Allow Copy & Paste**: ligue em **só um** item de upload por página, ou vários itens vão tentar processar a mesma colagem.
- **Storage, Type**:
  - *BLOB column specified in Item Source attribute*: grava na tabela do processo DML. O download usa a tabela do *Automatic Row Fetch*.
  - *Table APEX_APPLICATION_TEMP_FILES*: com **Purge File At** (End of Session ou End of Request) e **Allow Multiple Files** (nomes separados por `:`).
- **File Types**: lista separada por vírgula.
- **Maximum File Size** em KB.
- Não funciona em IG.

```plsql
declare
    l_file_names apex_t_varchar2;
    l_file       apex_application_temp_files%rowtype;
begin
    l_file_names := apex_string.split(p_str => :P1_ARQUIVOS, p_sep => ':');
    for i in 1 .. l_file_names.count loop
        select * into l_file from apex_application_temp_files where name = l_file_names(i);
        -- gravar l_file.blob_content na sua tabela
    end loop;
end;
```

Fonte: [File Upload](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-item-types.html)

### Image Upload: preview, recorte (Allow Cropping, Aspect Ratio) e redimensionamento
- Os mesmos modos de Display As e Storage do File Upload, mais o *Icon Dropzone*.
- **Preview Size**: Auto, Extra Small até Extra Large. Tamanhos extras podem ser criados com a classe `apex-item-image--{size}`.
- **Allow Cropping**: não funciona com *Allow Multiple Files*. **Aspect Ratio**: Original, 1:1, 16:9, 4:3, 2:1 ou Custom (ex.: `3:2`).
- **Resize To**: *Maximum File Size* (KB), *Maximum File Width* e *Maximum Height* (px). O redimensionamento é feito no cliente, em segundo plano.

Fonte: [Image Upload](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-item-types.html)

### Display Image: exibir imagem de BLOB ou URL
- *Based On*: de onde vem a imagem.
- **Alternative Text Column**: item com o texto alternativo, para leitores de tela.
- *Filename Column*, *MIME Type Column* e **BLOB Last Updated Column**: esta última serve ao cache do navegador, que só busca de novo se a imagem mudou.
- Os nomes dos itens vão em maiúsculas.
- Não funciona em IG.

Fonte: [Display Image](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-item-types.html)

### Rich Text Editor e Markdown Editor
- **Rich Text Editor**:
  - *Library* ORTL;
  - **Format**: *HTML* (mais flexível, mas o conteúdo precisa ser confiável ou sanitizado ao exibir) ou *Markdown* (mais seguro, passa por parser);
  - em HTML: *Toolbar* Basic, Intermediate ou Full, e *Toolbar Style* Overflow Menu ou Multiline;
  - *Minimum / Maximum Height* (vazio cresce sem limite);
  - Data Type VARCHAR2 ou CLOB.
- **Markdown Editor**:
  - *Toolbar*: Simple, Full ou None;
  - *Syntax Highlighting*, só para conteúdo com menos de 4000 caracteres;
  - não funciona em IG.

Fonte: [Rich Text Editor, Markdown Editor](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-item-types.html)

### Color Picker, Star Rating, QR Code e Percent Graph
- **Color Picker** (com *Use Defaults* = Off):
  - Display As: Popup, Inline, Color-only Popup ou Native Color Picker;
  - Mode: Simple ou Full;
  - Color Preset: None, Theme Style Colors ou Custom Colors;
  - **Contrast With**: mostra a razão de contraste com outro item ou cor, útil para acessibilidade;
  - **Return Value As**: Hex, rgb, rgb/rgba, hsl, hsl/hsla ou Any CSS Value.
- **Star Rating**: *Number of Stars* de 1 a 10 (padrão 5). Icon, cores, *Tooltip* com `#VALUE#`, *Show Clear Button*, *Show Value*, *Read Only Display*.
- **QR Code**: *Value Protected*. **Data Type** Plain Text, Phone, Email, SMS ou Geo location (`latitude,longitude`). *Size* Default, Small, Medium ou Large.
- **Percent Graph**: o valor precisa estar entre 0 e 100.

Fonte: [Color Picker, Star Rating, QR Code, Percent Graph](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-item-types.html)

### Geocoded Address e Display Map (Oracle Elocation, GeoJSON Point)
- **Geocoded Address**:
  - transforma o endereço de outros itens numa coordenada GeoJSON (só `Point`);
  - o **navegador** chama o Oracle Elocation, então precisa de internet. A doc avisa das possíveis implicações de proteção de dados;
  - **Structured Address** On mapeia Street, House Number, Postal Code, City e City Sub Area (até 8 itens) e permite *Sanitize Address* (devolve a correção aos itens). Off usa um item só, separado por vírgula;
  - *Country Type* Static ou Item;
  - *Match Vector Item* (17 dígitos);
  - **Trigger Geocoding**: Automatic, Dynamic Action (ação *Trigger Geocoding*) ou jQuery Selector.
- **Display Map**:
  - Background: Default, OpenStreetMap Bright, Dark ou Positron, Oracle World Map, ou Shared Component;
  - *Zoom Level* de 1 a 18;
  - Show Marker e Marker Color;
  - Tooltip com template directives;
  - Show Map Controls e Interactive Map;
  - *Height*: o padrão é a proporção 3:2 da largura.
- Itens Hidden que recebem a coordenada por DA precisam de *Value Protected* = Off.

```json
{ "type": "Point", "coordinates": [13.74081, 51.05363] }
```

Fonte: [Geocoded Address, Display Map](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-item-types.html)

---

## 12. Listas de valores e cascading LOV

### Os dez itens dirigidos por lista e o tipo de seleção de cada um

| Seleção | Itens |
|---|---|
| Só única | Select List, Select One (com busca, ícones e HTML), Radio Group |
| Única ou múltipla | Checkbox Group, Combobox (aceita entrada manual), Popup LOV (colunas extras, devolve para outros itens) |
| Só múltipla | Select Many, List Manager, Shuttle (ordenação) |
| Texto livre com sugestão | Text Field with Autocomplete (usa só o return) |

**Null Display Value** (ex.: "All" num filtro opcional) está disponível em Select List, Radio Group e Popup LOV.

Fonte: [List-Driven Items Available](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/list-driven-items-available.html)

### LOV local: Static Values e SQL Query (display, return)
- **Static Values**: no diálogo *Display1, Display2*, preencha Display Value e Return Value. Sem return, ele é igual ao display. Os botões reordenam, e **Sort at Runtime** (ligado por padrão) ordena alfabeticamente pelo display. Desligue para manter a ordem digitada, como em "Sim" antes de "Não".
- **SQL Query**: duas colunas, display primeiro e return depois. É comum usar os alias `d` e `r`. Pode usar binds de itens.

Exemplo: em seleção única o valor do item é o return (`30`). Em seleção múltipla, os returns separados por `:` (`10:20`).

```sql
select dname as d, deptno as r from dept order by dname
```

Uma LOV local não é reutilizável. A Oracle recomenda LOV **compartilhada** sempre que possível.

Fonte: [Creating a Static List of Values](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-static-List-of-values.html), [Defining the List of Values](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/defining-list-values.html), [Defining a Local List of Values](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/defining-local-list-values.html)

### LOV compartilhada (Shared Components) e conversão de LOV local
A LOV compartilhada tem recursos que a local não tem:
- uma **condição** por entrada estática;
- **Dynamic List** a partir de SELECT ou de fonte remota, com colunas **adicionais**: um ícone por linha, colunas para o Value HTML Expression de Select One, Select Many e Combobox, colunas exibidas, pesquisáveis e devolvidas pela Popup LOV;
- *Quick Pick Rank Column*.

Para converter, vá em *Shared Components › List of Values › aba Locally Defined › Convert*. O App Builder já ajusta a página para usar a nova LOV.

Fonte: [Additional Shared LOV Features](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/additional-shared-lov-features.html), [Converting Local LOVs to Shared](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/converting-local-lovs-shared.html)

### Cascading LOV: Parent Item(s), Items to Submit e vários níveis
Uma lista que depende de outra precisa de dois passos:
1. A query da LOV filha usa o pai como bind: `where deptno = :P2_DEPARTMENT`.
2. Na filha, grupo **Cascading List of Values**, preencha **Parent Item(s)** = `P2_DEPARTMENT`.

O que acontece em runtime:
- ao mudar o pai, o valor da filha é **limpo** e a lista é **recarregada**;
- itens extras usados como bind na query vão em **Items to Submit** do mesmo grupo. Eles são enviados no refresh, mas **mudar o valor deles não dispara o cascade**: só o pai faz isso;
- funciona em vários níveis (marca → modelo → motor), e limpar um nível limpa os de baixo.

Tipos com suporte, conforme a htmdb: Select List, Shuttle, Checkbox, Radio Group, Popup LOV e List Manager. A apxdc mostra também Select Many. Para ícones ou colunas extras na filha, referencie uma **LOV compartilhada**.

No **Interactive Grid**: a LOV da coluna usa a coluna pai como bind (`:COLUNA`) e a propriedade é **Parent Column(s)**.

```sql
select ename as d, empno as r
  from emp
 where deptno = :P2_DEPARTMENT
 order by ename
```

Fonte: [Configuring Cascading Lists](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configuring-cascading-lists.html), [Creating a Cascading List of Values](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-cascading-list-of-values.html)

### Cascading LOV fica vazia ou não recarrega
**Sintoma:** a lista filha vem vazia ou não muda ao alterar o item de que depende.
**Causa:** o item usado como bind não está em *Parent Item(s)* (não há cascade), ou está só em *Items to Submit* (é enviado, mas sua mudança não dispara refresh). Outra causa: um bind usado na query não está em nenhum dos dois, e chega `null` no servidor.
**Correção:** coloque em **Parent Item(s)** o item cuja mudança deve recarregar a lista, e em **Items to Submit** os demais binds.
**Prevenção:** a cada `:ITEM` numa query de LOV ou região, confira se ele está em Parent Items, Items to Submit ou Page Items to Submit.

Fonte: [Configuring Cascading Lists](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configuring-cascading-lists.html), [Configure Items to Submit and Return](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configure-items-submit-and-return.html)

---

## 13. Botões

### Behavior, Action: o que um botão pode fazer

| Action | Comportamento |
|---|---|
| **Submit Page** | Submete a página com `REQUEST` = nome do botão (*Button Name*) |
| **Trigger Action** | Executa uma ou mais *Trigger Actions* definidas sob o botão. Não submete nem redireciona |
| Redirect to Page in this Application | Redireciona, com opções de resetar paginação, definir request, limpar cache e definir itens no destino |
| Redirect to Page in a different Application | O mesmo, para outra app. Exige **Deep Linking** ligado na app de destino |
| Redirect to URL | Vai para a URL |
| Defined by Dynamic Action | Não submete nem redireciona. Quem age é uma DA de Click |

**Submit × Redirect:** o submit envia os valores para o session state e roda validações e processos. O redirect **não envia** o que o usuário mudou na página atual.

Fonte: [About Actions Buttons Can Perform](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-buttons.html), [Understanding AJAX and Redirect](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-ajax-and-redirect.html)

### Nome do botão e REQUEST (`:REQUEST`, maiúsculas e minúsculas)
O *Button Name* de um botão Submit Page vira o valor de `REQUEST`. Ele pode ser usado em PL/SQL e em condições:

```plsql
if :REQUEST in ('EDIT','DELETE') then ... end if;
if :REQUEST != 'DELETE' then ... end if;
```

**Pegadinha:** a comparação **diferencia maiúsculas de minúsculas**. Um botão `LOGIN` não casa com `'Login'`. Em JS, `apex.submit('Finish')` envia `REQUEST` = `Finish`. Condições do tipo *Request is contained in Value* (`CREATE,SAVE,DELETE`) e *When Button Pressed* dependem desse nome.

Fonte: [About the Relationship Between Button Names and REQUEST](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-buttons.html), [Refreshing List On Dialog Close](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/refreshing-list-dialog-close.html)

### Database Action do botão (SQL INSERT, UPDATE, DELETE action)
Num botão *Submit Page*, **Database Action** informa ao *Form - Automatic Row Processing (DML)* qual operação fazer. Sem ela não há DML (§8). O wizard combina a Database Action com a Server-side Condition sobre a PK: CREATE quando a PK é nula; SAVE e DELETE quando não é.

Fonte: [Conditional Database Action Buttons](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/conditional-database-action-buttons.html)

### Branching ligado a botões (When Button Pressed)
Uma página pode ter vários branches, para páginas ou URLs, avaliados em momentos diferentes do processamento: antes do processamento, antes da computation, antes da validação e depois do processamento. Associe o branch a um botão (*When Button Pressed*) e ele só será considerado quando aquele botão submeter a página.

Fonte: [About Branching with Buttons](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-buttons.html)

### Execute Validations, Show Processing e Requires Confirmation
- **Execute Validations**: Off pula as validações. O DELETE do wizard vem com Off.
- **Show Processing** (só com Submit Page): acinzenta a página e mostra uma animação durante o submit. Evita duplo clique em processos lentos.
- **Requires Confirmation**: mostra um diálogo antes da ação (submit, redirect ou DA). Se o usuário cancelar, nada acontece. Grupo *Confirmation*:
  - *Message*, com substituições;
  - *Style*: Default, Information, Warning, Danger ou Success.

  O botão de confirmar do diálogo usa o label do próprio botão.

Fonte: [Avoiding Multiple Page Submits by Enabling Show Processing](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-buttons.html), [Displaying a Button Confirmation Dialog](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-buttons.html)

### Trigger Action no botão: DA definida embaixo do próprio botão
Em *Behavior*, troque para **Trigger Action**. O APEX cria uma ação *Execute Server-side Code* sob o botão na árvore Rendering, e você muda para a ação que quiser (Refresh, Set Value, Submit Page, Cancel Dialog...). Menus de botão também aceitam triggered actions. É o jeito recomendado para reagir a cliques em botões e menus. Para os demais eventos, use dynamic actions na aba Dynamic Actions.

Fonte: [Adding a Trigger Action to a Button](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-buttons.html), [Configuring Dynamic Behavior](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configuring-dynamic-behavior.html)

### Botão como menu (Behavior, Type = Menu)
Com *Type* = **Menu**, aparece o nó *Menus* com uma entrada *New*. Para cada entrada: *Label*, *Link, Type* (ex.: Redirect to Page in this Application) e *Link, Target*. Entradas do tipo **Separator** e o atributo *Appearance, Icon* também estão disponíveis. Esconda uma entrada com *Comment Out*. O *Button Template* **Icon** deixa o botão só com ícone. **Exige o Universal Theme 25.1** ou mais recente, e botões com template alterado à mão podem não ter esses recursos.

Fonte: [Displaying a Button as a Menu](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-buttons.html)

### Esconder, desabilitar ou exibir um botão sob condição
- **Esconder**: *Server-side Condition, Type* = Never, ou *Comment Out*.
- **Mostrar desabilitado**: Server-side Condition = Never **e** *Appearance, Show as Disabled* ligado. Também exige o UT 25.1.
- **Condicional**: qualquer *Server-side Condition* (ex.: Item is NULL ou NOT NULL).

Fonte: [Hiding a Button or Displaying It as Disabled](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-buttons.html), [Displaying a Button Conditionally](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-buttons.html)

---

## 14. Dynamic Actions

### O que é uma Dynamic Action: evento (When), condição e ações True/False
Uma dynamic action define, sem JavaScript, como a página reage a uma interação.
- O **gatilho** é o evento mais o elemento (*When*), com uma *Client-side Condition* opcional.
- As **ações** podem mostrar, esconder, definir valor, executar PL/SQL etc.
- **Custo:** cada DA adiciona código que o navegador baixa e executa. Muitas DAs aumentam a página.

A DA aparece na aba Dynamic Actions agrupada por evento. A app de exemplo *Sample Dynamic Actions* (Gallery) traz casos prontos.

Fonte: [About Dynamic Actions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-dynamic-actions.html)

### Criar uma Dynamic Action no Page Designer (passo a passo e atributos)
1. Na aba *Dynamic Actions*, botão direito em *Events* (ou em Page Load, Change, Click, Dialog Close) › **Create Dynamic Action**. Outra opção: botão direito no item, botão ou região › *Create Dynamic Action*.
2. Na DA, preencha:
   - *Identification, Name*;
   - *Execution*: *Sequence*, **Event Scope**, *Static Container* e **Type**;
   - *When*: **Event** e **Selection Type** (Items, Button, Region, jQuery Selector, JavaScript Expression...). Selection Type não aparece em Page Load, Page Unload, Resize, Before Page Submit e Orientation Change;
   - **Client-side Condition**.
3. Em cada ação:
   - *Identification, Action*;
   - **Affected Elements**;
   - *Execution*: *Sequence*, **Fire When Event Result Is** (True ou False) e **Fire on Initialization**.
4. Para incluir mais ações: botão direito na DA › *Create TRUE Action* ou *Create FALSE Action*.

Depois de criada, a DA ainda aceita atributos como *Authorization Scheme*.

Fonte: [Creating a Dynamic Action](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-and-editing-dynamic-actions.html), [Editing Dynamic Actions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-and-editing-dynamic-actions.html)

### Eventos de Dynamic Action: Browser, Framework, Component e Custom
**Browser events** (nome JS entre parênteses):
- Change (`change`): ao perder o foco com o valor alterado;
- **Input** (`input`): a cada mudança, inclusive colagem;
- Click, Double Click, Get Focus (`focusin`), Lose Focus (`focusout`);
- Key Down, Key Press, Key Release;
- Mouse Button Press/Release, Mouse Enter/Leave/Move;
- **Page Load** (jQuery ready), Page Unload, Resize, Resource Load (`load`), Scroll, Select;
- toque: Tap, Double Tap, Press (mais de 250 ms), Pan, Swipe (`apex*`).

**Framework events:**
- **After Refresh** (`apexafterrefresh`) e **Before Refresh** (`apexbeforerefresh`): só em elementos com refresh parcial, como IR, Classic Report, gráficos, list view e todo item com cascading LOV. Também são disparados por `apex.server.process` e `apex.server.plugin` com a opção `refreshObject`;
- **Before Page Submit** (`apexbeforepagesubmit`);
- **Dialog Closed** (`apexafterclosedialog`): só via Close Dialog, seja processo ou DA;
- **Dialog Closed or Canceled** (`apexafterclosecanceldialog`): inclui ESC e Cancel Dialog.

**Component events:** no formato `Evento [Componente]`. Ex.: `Change Order [Shuttle]`, `Page Change [Cards]` e eventos de `interactiveGrid` e `treeView`. Plug-ins também geram eventos.

**Custom:** um nome de evento livre.

Fonte: [About Dynamic Action Events](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-dynamic-actions.html), [Adding Interactivity to Pages](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/adding-interactivity-pages.html)

### Client-side Condition e ações True/False
- **Sem** condição: só as ações True disparam.
- **Com** condição: as True disparam quando ela é verdadeira e as False quando é falsa.

O tipo da condição revela os campos necessários (ex.: *Item = Value* mostra Item e Value). **JavaScript Expression** permite qualquer teste, por exemplo filtrar a tecla Enter:

```javascript
this.browserEvent.which === apex.jQuery.ui.keyCode.ENTER
```

**Detalhe:** a condição é avaliada quando a DA e suas ações **executam**, não quando o evento dispara. Isso importa com Debounce e Throttle.

Fonte: [Creating a Dynamic Action](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-and-editing-dynamic-actions.html), [Defining Dynamic Action Event Scope](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-and-editing-dynamic-actions.html), [Showing Master/Detail Data Side by Side](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/showing-master-detail-data-side-side.html)

### Event Scope (Static, Dynamic, Once) e Static Container
- **Static**: o handler fica ligado ao elemento durante a vida da página, mas **se perde** se o elemento for recriado por refresh parcial (PPR).
- **Dynamic**: continua valendo mesmo que o elemento seja recriado por PPR. **Static Container (jQuery Selector)** melhora a performance: é um elemento que não é recriado e contém os elementos que disparam.
- **Once**: dispara uma vez só, até a página ser recarregada inteira.

**Quando usar Dynamic:** em eventos de elementos dentro de relatórios que dão refresh, como botões ou links em linhas de Classic Report.

Fonte: [Defining Dynamic Action Event Scope](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-and-editing-dynamic-actions.html)

### Execution Type: Immediate, Debounce e Throttle
- **Immediate**: executa na hora.
- **Debounce**: executa **uma vez**, depois de um intervalo sem novos eventos. Exemplos: atualizar quando o usuário parou de digitar por 2 s; um refresh depois de um clique, ignorando os cliques dos 5 s seguintes.
- **Throttle**: executa em intervalos enquanto o evento se repete. Exemplo: atualizar a posição a cada 2 s durante o scroll.

Combine com o evento **Input** para buscas enquanto o usuário digita.

Fonte: [Creating a Dynamic Action](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-and-editing-dynamic-actions.html)

### Fire on Initialization: executar a ação também no carregamento
Em *Execution, Fire on Initialization*, a ação também roda no **page load**. Use para que o estado inicial, como um item escondido ou mostrado por um valor, combine com a regra da DA. Em DAs de **colunas de Interactive Grid**, "inicialização" é quando a linha é ativada para edição. Ações com efeito colateral (Execute Server-side Code, Submit, Refresh) normalmente ficam com Off.

Fonte: [Creating a Dynamic Action](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-and-editing-dynamic-actions.html)

### Ações nativas de Dynamic Action (Component, Execute, Navigation, Notification, Style, AI)

| Categoria | Ações |
|---|---|
| AI | Generate Text With AI, Show AI Assistant |
| Component | Clear, **Close Region / Open Region** (inline dialog, inline popup, collapsible), Collapse/Expand Tree, **Disable / Enable**, **Hide / Show**, **Refresh**, **Set Focus** (o primeiro dos afetados), **Set Value**, Trigger Geocoding |
| Execute | Download, **Execute JavaScript Code**, **Execute Server-side Code** (com *Show Processing* para mostrar um spinner), Invoke Interactive Report Dialog, Print Report |
| Miscellaneous | Cancel Event, Get Current Position, Share |
| Navigation | Cancel Event, **Cancel Dialog**, **Submit Page** (a ação *Close Dialog* é citada em outros tópicos da doc) |
| Notification | **Alert**, Clear Errors, **Confirm** (se o usuário cancelar, as ações seguintes não rodam e o evento é cancelado), Show Success Message, Show Error Message |
| Style | Add Class, Remove Class, Set Style |

**Pegadinha de Disable:** um elemento desabilitado **não envia o valor** no submit da página.

Fonte: [About Supported Actions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-dynamic-actions.html), [Generating a Close Dialog Page Process on the Dialog Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-dialog-pages.html)

### Execute Server-side Code: Items to Submit e Items to Return
A ação executa PL/SQL (ou JavaScript no servidor) por **AJAX**, sem submeter a página.
- **Items to Submit**: lista separada por vírgula dos itens (ou colunas de relatório) cujos valores atuais vão para o servidor **antes** do código rodar. Sem isso, o bind recebe o valor que está no session state, que pode ser nulo ou antigo.
- **Items to Return**: itens que o código altera e que o APEX deve atualizar na página depois.
- Em relatórios, a PK está sempre disponível. Outras colunas precisam de **Available on Client**.

```plsql
-- Items to Submit: P5_ID_CARGO     Items to Return: P5_SALARIO_BASE
select salario_base into :P5_SALARIO_BASE
  from cargo
 where id_cargo = :P5_ID_CARGO;
```
(Exemplo ilustrativo; a regra de Submit/Return é da doc.)

Fonte: [Understanding AJAX and Redirect](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-ajax-and-redirect.html), [Adding Interactivity to Pages](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/adding-interactivity-pages.html), [Configure Items to Submit and Return](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configure-items-submit-and-return.html)

### Refresh de região e Page Items to Submit
A ação **Refresh** recarrega o conteúdo de uma região (IR, Classic Report, IG, cards, mapa...) ou de um item com cascading LOV, por AJAX. Nem toda região ou item aceita refresh. Os valores enviados são os da propriedade **Page Items to Submit** **da região**, e não da ação. A resposta traz o HTML e os dados, que o APEX aplica só naquela área. Ao terminar, a região dispara `apexafterrefresh`, e com isso é possível encadear: o refresh dos Cards gera `Page Change [Cards]`, que dispara o Refresh do mapa.

Fonte: [Understanding AJAX and Redirect](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-ajax-and-redirect.html), [Adding Interactivity to Pages](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/adding-interactivity-pages.html)

### Set Value: definir valor de itens (incluindo Dialog Return Item)
*Set Value* define o valor dos *Affected Elements*. O *Set Type* determina a origem do valor. A doc cita **Dialog Return Item**, para usar um valor devolvido por Close Dialog numa DA *Dialog Closed*. Os demais tipos e atributos (consultas SQL ou PL/SQL com envio de itens, supressão do change...) estão no Help do Page Designer. Lembre que definir um item no cliente **não grava** o session state até o submit ou AJAX, e que um Hidden definido assim precisa de *Value Protected* = Off. Ao definir um valor durante o *change* do mesmo item, suprima o evento de change para evitar loop (ver `setValue` no §10).

Fonte: [Handling Refresh Actions on Parent Page](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-dialog-pages.html), [item (setValue)](https://docs.oracle.com/en/database/oracle/apex/26.1/aexjs/item.html), [Unprotecting Client-Set Hidden Items](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/unprotecting-client-set-hidden-items.html)

### Execute JavaScript Code e funções da página
Use **Execute JavaScript Code** para chamar código da página. As funções podem ficar em *Function and Global Variable Declaration* da página, para código de uma página só, ou num arquivo estático, se forem compartilhadas. Também é possível usar JavaScript em condições (*JavaScript Expression*) e em ações de Set Value. Não use JS para validações que dependem de muitos dados (ex.: verificar se um nome existe numa tabela grande): faça no servidor.

Fonte: [About Calling JavaScript Using a Dynamic Action](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-and-editing-dynamic-actions.html), [About Incorporating JavaScript into an Application](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/about-incorporating-javascript-into-an-application.html)

### Depurar Dynamic Actions (console do navegador + Debug)
Boa parte do processamento de DAs ocorre no cliente. Em modo Debug, o APEX escreve no console:

```
Dynamic Action Fired: [nome da DA] ([nome da ação]) {objeto com when, affected elements, evento, dados}
```

Passos:
1. A app precisa permitir debugging.
2. Rode a página e abra o console.
3. No Developer Toolbar, *Debug › Enable Debug* (Info, App Trace ou Full Trace).
4. Provoque o evento e veja no console se a DA disparou.

*View Debug* recarrega a página, então as DAs de page load aparecem no log.

Fonte: [Debugging Dynamic Actions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/debugging-dynamic-actions.html)

### Execute Server-side Code dá No Data Found ou não atualiza a página
**Sintoma:** `ORA-01403 no data found` na DA, ou o código roda mas os itens na tela não mudam.
**Causa:** os itens usados como bind não estão em **Items to Submit**, então chegam com o valor antigo ou nulo do session state. Ou os itens alterados não estão em **Items to Return**.
**Correção:** liste em Items to Submit todo `:ITEM` lido pelo código e em Items to Return todo item que ele altera.
**Prevenção:** revise as duas listas sempre que mexer no PL/SQL da DA.

Fonte: [Configure Items to Submit and Return](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configure-items-submit-and-return.html)

### Refresh de região devolve nenhuma linha ou ignora o filtro
**Sintoma:** depois de mudar um filtro e dar Refresh, o relatório fica vazio ou não filtra.
**Causa:** o item do filtro, usado como `:ITEM` na query, não está em **Page Items to Submit** da região, e o bind chega como `null`.
**Correção:** acrescente o item (sem os dois-pontos) em *Page Items to Submit*. Vários itens vão separados por vírgula.

Fonte: [Configure Items to Submit and Return](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/configure-items-submit-and-return.html)

### Pressionar Enter num campo submete a página inteira
**Sintoma:** numa página com um único campo de texto (ex.: busca), Enter recarrega ou submete a página em vez de só filtrar.
**Causa:** é o comportamento padrão de formulários HTML de campo único.
**Correção:** uma DA *Key Press* no campo com a condição JavaScript `this.browserEvent.which === apex.jQuery.ui.keyCode.ENTER` e as ações *Refresh* (da região) e **Cancel Event**.

Fonte: [Showing Master/Detail Data Side by Side](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/showing-master-detail-data-side-side.html)

### Valor de item desabilitado por DA some no submit
**Sintoma:** um campo preenchido por código e desabilitado com a DA *Disable* chega nulo nos processos.
**Causa:** elementos desabilitados não mantêm o valor no submit.
**Correção:** em vez de desabilitar, use *Read Only* (condição de servidor) ou deixe o campo habilitado com estilo de leitura. Se o valor precisar ir ao servidor, envie por um Hidden (com *Value Protected* = Off, se for definido no cliente).

Fonte: [About Supported Actions (Disable)](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-dynamic-actions.html)

### DA deixa de funcionar depois do refresh da região
**Sintoma:** um clique em botões ou links dentro de um relatório funciona até o primeiro refresh e depois para.
**Causa:** a DA usa *Event Scope* = Static, e o PPR recriou os elementos.
**Correção:** use *Event Scope* = **Dynamic**, com um *Static Container* (jQuery selector de um elemento que não é recriado, como a região).

Fonte: [Defining Dynamic Action Event Scope](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-and-editing-dynamic-actions.html)

---

## 15. Trees (região de árvore)

### Região Tree: query hierárquica START WITH ... CONNECT BY
A Tree usa a **APEX Tree**, um componente JS com navegação por teclado e gravação de estado opcionais. O antigo jsTree não existe mais e é convertido automaticamente. A query precisa ser hierárquica (`START WITH .. CONNECT BY`), com coluna de ID e de ID pai.
- **No Create Page Wizard**: *Node Text*, *Start With* (a raiz) e *Start Tree*, que pode vir de um item, de um valor estático ou de uma SQL de valor único.
- **No Page Designer**:
  - *Node Value Column*: o ID do nó, acessível por JS;
  - *Hierarchy*: o APEX calcula a hierarquia ou os dados já a trazem.

Só é suportada em páginas com UI Desktop. Há exemplos na app *Sample Trees*.

Fonte: [Managing Trees](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-trees.html)

---

## 16. Submit, AJAX e redirect

### Três formas de falar com o servidor: render/submit/branch, AJAX e redirect
- **Render, submit e branch**: o submit grava os valores no session state, roda validações, computations e processos e depois um branch decide a próxima página.
- **AJAX**: a página conversa com o servidor sem recarregar. Os dois usos típicos são *Execute Server-side Code* (Items to Submit e Return) e *Refresh* de região (Page Items to Submit). O APEX cuida da comunicação.
- **Redirect**: vai para outra página passando parâmetros, como um branch, mas **sem enviar** o que o usuário mudou na página atual (o session state não é atualizado). Por isso o aviso de mudanças não salvas existe. Itens de filtro em Memory Only não disparam o aviso.

Fonte: [Understanding AJAX and Redirect](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/understanding-ajax-and-redirect.html)

---

## 17. Aplicação no Corlix Hub

Contexto do projeto (ver `docs/ai-context/README.md`, `02-paginas.md` e `08-convencoes-e-pegadinhas.md`): app 100 `CORLIXHUB`, APEX **26.1.5**, Oracle DB **23ai**, fonte em APEXlang (`corlixhub/pages/*.apx`). O padrão de cadastro do projeto é **lista (Interactive Report) + formulário em modal criado pelo assistente**.

### Como os recursos deste documento aparecem nos `.apx` do Corlix Hub
Correspondência entre a interface e o APEXlang, conferida nos arquivos de página:

| Recurso (doc) | APEXlang no projeto | Exemplo |
|---|---|---|
| Page Mode = Modal Dialog + Dialog Template | `appearance { pageMode: modalDialog dialogTemplate: @/modal-dialog }`, `dialog { chained: false }` | p16, p18 |
| Form region | `region ... ( type: form source { location: localDatabase tableName: EMPRESA } )` | p16 (`EMPRESA`), p18 (`VW_HISTORICO_CARREIRA`) |
| Item de PK do form | `source { formRegion: @... column: ID_EMPRESA dataType: number queryOnly: true primaryKey: true }` | `P16_ID_EMPRESA` (Hidden, `sessionStateProtection: checksumRequiredSessionLevel`) |
| Form - Initialization | `process ... ( type: formInitialization formRegion: @... execution { point: beforeHeader } )` | p16, p18 |
| Form - Automatic Row Processing (DML) | `process ... ( type: formAutoRowProcessing formRegion: @... )` | p16 |
| Database Action do botão | `behavior { databaseAction: insert / update / delete }` + `serverSideCondition { type: itemIsNull / itemIsNotNull item: P16_ID_EMPRESA }` | botões CREATE, SAVE, DELETE da p16 |
| Requires Confirmation | `requiresConfirmation: true` + `confirmation { message: &APP_TEXT$DELETE_MSG!RAW. style: danger }` | DELETE da p16 |
| Cancel Dialog como Trigger Action | `behavior { action: triggerAction }` + `triggerAction native-dialog-cancel ( action: cancelDialog )` | CANCEL da p16 |
| Close Dialog depois do DML | `process close-dialog ( type: closeDialog execution { sequence: 50 } serverSideCondition { type: requestIsContainedInValue value: CREATE,SAVE,DELETE } )` | p16; na p18, `SALVAR_RASCUNHO,EFETIVAR,ESTORNAR,EXCLUIR` |
| Dialog Closed + Refresh na página-mãe | `dynamicAction ... when { event: apexafterclosedialog selectionType: region region: @empresas-cadastradas }` + `action native-refresh ( action: refresh ... )` | p15, p13 |
| Cascading LOV | `cascadingLov { parentItems: P18_ID_DEPARTAMENTO_NOVO itemsToSubmit: P18_ID_DEPARTAMENTO_ATUAL parentRequired: false }` | `P18_ID_CARGO_NOVO` (Popup LOV) |
| Set Value com SQL e Items to Submit | `action: setValue settings { type: sqlQuery sqlQuery: ... itemsToSubmit: P18_ID_TIPO_MOVIMENTACAO suppressChangeEvent: true }` | p18 (código do tipo) |
| Value Protected desligado em Hidden definido no cliente | `settings { valueProtected: false }` | `P18_CD_TIPO` |
| Fire on Initialization | `execution { sequence: 10 fireOnInit: false }` | todas as DAs |

Fonte: [Creating Dialog Pages](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/creating-dialog-pages.html), [Studying a List and Edit Flow](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/studying-list-and-edit-flow.html)

### Regras do projeto aplicadas a páginas, forms, LOVs e DAs
- **Multiempresa**: toda query de LOV, região, Set Value ou Execute Server-side Code filtra por `id_empresa`, em geral `:G_ID_EMPRESA` (app item). A LOV de cargo da p18 e o Set Value do tipo de movimentação já fazem isso. Lembre que `G_ID_EMPRESA` só é preenchido depois de um novo login (08 §3).
- **Página administrativa**: *Security, Authorization Scheme* na **página** (atributo de página, §6), não só no menu. Ex.: a p14 e a p20 exigem `ADMIN_RH`.
- **Links**: as páginas usam `pageAccessProtection: argumentsMustHaveChecksum`. Gere URLs com `apex_page.get_url` (como no padrão Side by Side do §9) ou pelo Link Builder (Link Column, Set Items). Não monte `f?p=` à mão com parâmetros.
- **UI em pt-BR**: labels, mensagens de sucesso, *Null Display Value* e confirmações. O texto `DELETE_MSG` vem do APEX. Para traduzir, crie o text message `DELETE_MSG` com *Used in JavaScript* (§8).
- **Datas**: o idioma primário técnico é `en`. Como os binds são VARCHAR2 (§10), converta explicitamente (`to_date`/`to_char` com máscara) quando um item de data entrar em SQL.
- **BOOLEAN em Switch/Checkbox**: exige banco **26ai**. O Corlix Hub usa **23ai**, então mantenha flags `S/N` (prefixo `fl_`) com *On Value*/*Off Value* (§11).

Fonte: [Values Bind as Strings](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/values-bind-strings.html), [Showing Master/Detail Data Side by Side](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/showing-master-detail-data-side-side.html)

### Divergência: aba Attributes e grupo Edit (Lost Update Type, Region Display Selector) no 26.1.5
A doc oficial 26.1 manda configurar o **Lost Update Type** em *Form region › Property Editor › aba **Attributes** › grupo **Edit***, e cita a aba *Attributes* para o Region Display Selector e outras regiões. O `docs/ai-context/08` (regra 11) e o `09` §4.8 registram que, **na tela do 26.1.5 usado pelo time, o Property Editor não tem a aba "Attributes" e a Form region não mostra a seção "Edit"**. Nos exports, o bloco `edit { enabled: true allowedOperations: [...] }` só aparece em regiões criadas pelo assistente (p16, p27). Regiões montadas depois (p18, p19) ficam só leitura e não há onde ligar a edição.

O que fazer até conferir na tela:
- Para forms editáveis, crie a página pelo **Create Page Wizard** (Form, ou relatório com *Include Form Page*) e confira `edit {` no export APEXlang.
- O **Prevent Lost Updates** fica no processo *Form - Automatic Row Processing (DML)*, que vem **ligado por padrão** (§8). Caminhos de Lost Update Type fora disso devem ir nos guias marcados como **(confirmar no 26.1.5)**, com pedido de print se o caminho não existir.

Fonte: [Configuring Lost Update Detection](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/configuring-lost-update-detection.html), [Creating a Region Display Selector](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-regions.html)

### Pegadinhas do projeto explicadas pela doc oficial
- **p4 Chat: o refresh não funciona.** A região de mensagens tem a Server-side Condition `P4_CANAL_ID is not null`. Uma região com condição falsa **não é renderizada**, então não existe no DOM para o Refresh (§10). Corrija renderizando sempre a região e filtrando na query (com o item em *Page Items to Submit*), ou recarregando a página.
- **p16 Empresa: endereço do ViaCEP chega nulo.** Os campos preenchidos pelo ViaCEP ficam desabilitados, e **item desabilitado não é enviado** (§14). Prefira *Read Only*, ou leve o valor por Hidden com *Value Protected* = Off.
- **p17 Comunicado.** Não tem processo *Close Dialog*, então o modal não fecha nem dispara *Dialog Closed* na página-mãe (§4). O default `plsqlExpression: SYSDATE;` tem um `;` a mais: o tipo *PL/SQL Expression* espera só a expressão (§10). Todos os itens com `sequence: 10` deixam a ordem do layout indefinida (§7).
- **Hidden preenchido por DA ou JS.** Desligue *Value Protected* (ex.: `P18_CD_TIPO`), ou o submit dá *Session state protection violation* (§10).
- **Botões só de UI.** Botões que não devem submeter usam *Defined by Dynamic Action* ou *Trigger Action* (§13). Os triggered actions são o padrão do projeto (p16 CANCEL).
- **Mudar um Form por SQL.** Ao trocar a fonte de uma Form region baseada em tabela ou view, rode **Synchronize Page Items** para criar os itens das colunas novas (§8).

Fonte: [Supported Region Types](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/supported-region-types.html), [About Supported Actions](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/understanding-dynamic-actions.html), [Page Items in a Form Region](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/page-items-form-region.html)

### Checklist ao criar ou alterar uma página de cadastro no Corlix Hub
1. Criar pelo **Create Page Wizard** (relatório + *Include Form Page*, ou Form). O form sai como modal ou drawer.
2. Conferir no `.apx`:
   - `type: form` com o bloco `edit { enabled: true ... }`;
   - item de PK com `primaryKey: true`;
   - `formInitialization` em `beforeHeader`;
   - `formAutoRowProcessing` **antes** do `closeDialog`;
   - botões com `databaseAction` e condições `itemIsNull`/`itemIsNotNull`.
3. Na lista: uma DA `apexafterclosedialog` com Selection Type = Region e Refresh da região. O link da coluna é gerado pelo Link Builder e leva a PK escapada (`\#ID#\`).
4. Toda LOV e query com `id_empresa = :G_ID_EMPRESA`. Os binds estão em *Page Items to Submit*, *Items to Submit* ou *Parent Item(s)*.
5. Na página administrativa: `security { authorizationScheme: @... }`.
6. Textos em pt-BR. Item PK Hidden com *Session State Protection* por checksum, como na p16.
7. Atualizar `docs/ai-context/02-paginas.md` com a página nova ou alterada.

Fonte: [Studying a List and Edit Flow](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/studying-list-and-edit-flow.html), [Conditional Database Action Buttons](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/conditional-database-action-buttons.html)
