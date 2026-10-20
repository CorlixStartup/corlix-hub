# Home (página 28) · redesign · passo a passo no APEX

Este guia monta a nova Home numa **página nova, a 28 ("Início")**, no App Builder do **APEX 26.1.5**, seguindo o protótipo [`pen_dev/Início.png`](../../pen_dev/Início.png) (descrição em `docs/ai-context/07-design-pen-dev.md` §4.1).

**A Home atual (página 1) não é apagada nem alterada.** Ela continua sendo a página inicial do app até a seção 5, quando a 28 passa a ser a Home. Para voltar atrás, basta desfazer os três ajustes da seção 5.

Depois de montar a página no Builder, não é preciso exportar à mão: o backup diário (Jenkins) exporta o app de PRD em APEXlang para `corlixhub/` na `DEV`. Mudança feita só no `.apx` do repositório, sem levar ao APEX, é **desfeita** no próximo backup. Por isso este módulo traz o package, o CSS, a imagem e este guia, e não um `.apx` editado.

### Como ler os caminhos deste guia (APEX 26.1.5)

- **Rendering** é a árvore da esquerda do Page Designer; o **painel de propriedades** é o da direita. `Seção › Atributo` indica a seção e o campo no painel de propriedades do componente selecionado.
- No 26.1.5 a região **não tem a aba nem o nó "Attributes"**. Os atributos da Cards (Title, Body, Media...) aparecem direto no painel da região.
- Para achar qualquer atributo, use a **busca no topo do painel de propriedades**.
- Passos marcados com **(confirmar no 26.1.5)** ainda não foram conferidos na tela desta versão. Se o caminho não existir, não procure por tentativa: tire um print da árvore e do painel e registre o caminho certo neste guia.

### O que muda

| Antes (página 1, continua existindo) | Depois (página 28, protótipo) |
|---|---|
| Card "Bem-vindo, Fulano! 👋" + card "Links rápidos" separado | **Hero** de largura total: "Olá, Sarah", data por extenso, 3 atalhos e a arte decorativa à direita |
| "Comunicados Oficiais" com cards grandes e sombra; botão "Emitir Comunicado" | Card **Comunicados** + "Publicações oficiais da empresa"; 1º item em destaque com imagem 16:9, os outros em lista; "Ver todos →" e **"+ Novo comunicado"** (Hot, só publicador) |
| "Meu gestor" com `href="#"` e estilos colados no HTML; sem estado vazio | **Meu gestor** com Chat (página 4) e E-mail (`mailto:`); estado vazio "Nenhum gestor vinculado" |
| "Aniversariantes" em caixa alta + badge do mês preenchido por JS, só dias ≥ hoje, sem filtro de empresa | **Aniversariantes de outubro** (ícone de bolo), mês inteiro da empresa, próximos primeiro, selo "Hoje"; "Ver todos →" abre o diálogo |
| Comunicados e aniversariantes de **todas** as empresas | Tudo filtrado por `:G_ID_EMPRESA` |

O cabeçalho e o menu lateral do protótipo são da Global Page e dos Shared Components: ficam fora deste guia.

### Arquivos do módulo

| Arquivo | O que é |
|---|---|
| `pkg_home_ui.pks` / `.pkb` | Package que devolve o HTML do hero, do Meu gestor e dos aniversariantes |
| `instalar.sql` | Instala o package pelo SQLcl |
| `home-pagina.js` | JavaScript da página 28 (2 blocos) |
| `home-hero.jpg` | Arte decorativa do hero (recorte do protótipo; troque pela arte original quando houver) |
| `corlixhub/shared-components/static-files/custom.css` §12 (+ `.min.css`) | Estilos da nova Home (classes `cx-home-*` e `cx-avatar`) |

---

## 1. Banco: instalar o `pkg_home_ui`

**Pelo SQLcl:** `cd modulos/home` e `sql <usuario>@<servico> @instalar.sql`.

**Pelo SQL Workshop:** *SQL Workshop › SQL Scripts › Upload*, envie `pkg_home_ui.pks` e rode; depois `pkg_home_ui.pkb` e rode. Os dois terminam em `/`, então funcionam como script. No *SQL Commands* cole um arquivo por vez **sem** a `/` final.

**Teste** (SQL Commands, um comando por vez):

```sql
select pkg_home_ui.mes_atual from dual
```
Deve voltar o mês em minúsculas (ex.: `outubro`).

```sql
select pkg_home_ui.render_aniversariantes(p_id_empresa => 1) from dual
```
Deve voltar um `<ul class="cx-home-lista">` com até 3 pessoas, ou o estado vazio "Nenhum aniversariante em ...".

Se der erro de compilação: `select line, position, text from user_errors where name = 'PKG_HOME_UI' order by sequence` (ver `docs/ai-context/09-erros-e-solucoes.md`).

---

## 2. Arquivos estáticos

Em *Shared Components › Static Application Files*:

1. **Create File** › envie `modulos/home/home-hero.jpg` com o nome `home-hero.jpg`, na raiz (sem pasta). O CSS procura a imagem na mesma pasta do `custom.css`.
2. Envie de novo `custom.css` **e** `custom.min.css` (de `corlixhub/shared-components/static-files/`), substituindo os atuais. O app carrega `custom#MIN#.css`, então os dois precisam estar iguais.

O CSS novo só acrescenta a §12 (classes `cx-home-*`, que a página 1 não usa), então pode subir antes da seção 3 sem mudar nada na Home atual.

---

## 3. Página 28 no Page Designer

### 3.1 Criar a página 28

Nada é apagado da página 1. Crie uma página em branco: no App Builder, app 100 › **Create Page** › **Blank Page** (confirmar no 26.1.5):

| Campo | Valor |
|---|---|
| Page Number | `28` |
| Name | `Início` |
| Page Mode | **Normal** |
| Breadcrumb | **Don't use breadcrumbs on page** (confirmar no 26.1.5) |
| Navigation › Use Navigation | **Off** (o menu continua apontando para a 1 até a seção 5; confirmar no 26.1.5) |

Depois, no Page Designer da 28, clique no nó **Page 28** no topo da árvore:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Alias | `INICIO` (o `HOME` continua sendo da página 1) |
| Identification | Title | `CorlixHub` (o mesmo da página 1) |
| Appearance | Page Template | **Standard** |
| Navigation | Cursor Focus | **Do not focus cursor** |
| Security | Authentication | **Page Requires Authentication** (padrão) |

### 3.2 Item e computação do mês

O título "Aniversariantes de outubro" usa `&P28_MES_ATUAL.`. O valor precisa estar na sessão **antes** de as regiões serem montadas, por isso vem de uma computação Before Header (Source/Default só rodam quando o item é renderizado, depois do título).

Depois de criar a região "Coluna lateral" (passo 3.5), clique com o botão direito nela › **Create Page Item**:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `P28_MES_ATUAL` |
| Identification | Type | **Hidden** |
| Layout | Sequence | 100 |

Na árvore, abra **Pre-Rendering**, botão direito em **Before Header** › **Create Computation**:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Item Name | `P28_MES_ATUAL` |
| Execution | Point | **Before Header** |
| Computation | Type | **Expression** |
| Computation | Language | PL/SQL |
| Computation | PL/SQL Expression | `pkg_home_ui.mes_atual` |

### 3.3 Região "Início" (hero)

Botão direito em **Body** › **Create Region**:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Title | `Início` |
| Identification | Type | **Dynamic Content** |
| Source | PL/SQL Function Body returning a CLOB | `return pkg_home_ui.render_hero;` |
| Layout | Sequence | 10 |
| Layout | Slot | Body |
| Appearance | Template | **Blank with Attributes** |
| Advanced | Static ID | `home_hero` |

O título não aparece (o template não tem cabeçalho); o `<h1>` "Olá, ..." vem do package.

### 3.4 Região "Comunicados" (Cards)

Botão direito em **Body** › **Create Region**:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Title | `Comunicados<span class="cx-home-card__subtitulo">Publicações oficiais da empresa</span>` |
| Identification | Type | **Cards** |
| Source | Type | SQL Query (query abaixo) |
| Layout | Sequence | 20 |
| Layout | Start New Row | Yes |
| Layout | Column Span | **8** |
| Appearance | Template | **Standard** |
| Appearance | Template Options | **Body Padding: No Padding** (confirmar no 26.1.5; no export: `t-Region--noPadding`) |
| Appearance | CSS Classes | `cx-home-card cx-home-comunicados` |
| Advanced | Static ID | `home_comunicados` |

O subtítulo vai dentro do título (com classe, sem `style`) para ficar no cabeçalho, à esquerda dos botões, como no protótipo.

**Source › SQL Query:**

```sql
select c.id_comunicado,
       c.titulo,
       -- resumo em texto puro: tira as tags do editor e corta em 220 caracteres
       substr(trim(regexp_replace(regexp_replace(dbms_lob.substr(c.conteudo, 1000, 1),
                                                 '<[^>]+>', ' '),
                                  '\s+', ' ')), 1, 220) as resumo,
       c.imagem,
       c.mime_type,
       'Para: ' || nvl(d.nome, 'Todos') as publico,
       to_char(c.data_publicacao, 'fmdd') || ' de '
         || to_char(c.data_publicacao, 'fmmonth', 'NLS_DATE_LANGUAGE=''BRAZILIAN PORTUGUESE''')
         || case when extract(year from c.data_publicacao) <> extract(year from sysdate)
                 then ' de ' || to_char(c.data_publicacao, 'yyyy')
            end as data_publicacao_txt
  from comunicado c
  left join departamento d
    on d.id_departamento = c.id_departamento
 where c.id_empresa = :G_ID_EMPRESA
 order by c.data_publicacao desc, c.id_comunicado desc
 fetch first 3 rows only
```

**Atributos da Cards** (no mesmo painel, abaixo de Source):

| Seção | Atributo | Valor |
|---|---|---|
| Appearance | Layout | **Horizontal (Row)** (confirmar no 26.1.5; no export: `componentAppearance { layout: horizontal }`) |
| Card | Primary Key Column 1 | `ID_COMUNICADO` |
| Title | Advanced Formatting | **On** |
| Title | HTML Expression | trecho abaixo |
| Body | Advanced Formatting | Off |
| Body | Column | `RESUMO` |
| Media | Source | **BLOB Column** |
| Media | BLOB Column | `IMAGEM` |
| Media | Position | **First** |
| Media | Appearance › Sizing | **Cover** (confirmar no 26.1.5) |
| Media | Image Description | (vazio: a imagem é decorativa) |
| BLOB Attributes | Mime Type Column | `MIME_TYPE` |
| Pagination | Type | **No Pagination (Show All Rows)** (confirmar no 26.1.5) |
| Messages | When No Data Found | `Nenhum comunicado publicado. Os comunicados oficiais aparecerão aqui.` |

**Title › HTML Expression:**

```html
<span class="cx-home-comunicado__meta">
  <span class="cx-etiqueta">&PUBLICO.</span>
  <span>&DATA_PUBLICACAO_TXT.</span>
</span>
<span class="cx-home-comunicado__titulo">&TITULO.</span>
```

O CSS (§12.4) mostra a imagem só no 1º comunicado (o destaque) e põe os demais em lista com divisórias.

**Botões no cabeçalho da região.** Botão direito na região **Comunicados** › **Create Button**, duas vezes:

| Atributo | `VER_TODOS` | `NOVO_COMUNICADO` |
|---|---|---|
| Identification › Label | `Ver todos` | `Novo comunicado` |
| Layout › Sequence | 10 | 20 |
| Layout › Slot | **Copy** (confirmar no 26.1.5) | **Edit** (confirmar no 26.1.5) |
| Appearance › Button Template | **Text with Icon** | **Text with Icon** |
| Appearance › Hot | Off | **On** |
| Appearance › Icon | `fa-arrow-right` | `fa-plus` |
| Appearance › Template Options | Icon Position: **Right** · Style: **Remove UI Decoration** | Icon Position: Left |
| Behavior › Action | Redirect to Page in this Application | Redirect to Page in this Application |
| Behavior › Target | Page **11** | Page **17** · Clear Cache `17` |
| Security › Authorization Scheme | (nenhum) | **PUBLICADOR_DE_CONTEUDO** |

No template *Standard*, os slots **Copy** e **Edit** ficam no cabeçalho, à direita do título. Se os botões aparecerem dentro do corpo do card, o slot está errado: tire um print do campo *Slot* aberto e registre o nome certo aqui.

**Dynamic Action "Atualizar comunicados".** Crie a DA pela região, **não** pelo botão: botão direito na região **Comunicados** › **Create Dynamic Action**, e depois aponte para o botão em *When*. Criada pelo botão direito no botão, o Builder troca o *Behavior › Action* do botão para **Defined by Dynamic Action** e ele para de abrir a página 17.

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `Atualizar comunicados` |
| When | Event | **Dialog Closed** |
| When | Selection Type | Button · `NOVO_COMUNICADO` |
| True Action | Action | **Refresh** · Selection Type Region · `Comunicados` |

Depois de criar a DA, confira no botão `NOVO_COMUNICADO`: *Behavior › Action* tem que continuar **Redirect to Page in this Application** · página 17. No export: `action: redirectThisApp`, e não `triggerAction`.

A página 17 ainda não tem o processo *Close Dialog* (`docs/ai-context/08` §3), então hoje ela não fecha sozinha ao salvar. Quando ganhar o processo, a lista atualiza sem recarregar a Home.

### 3.5 Região "Coluna lateral"

Botão direito em **Body** › **Create Region**:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Title | `Coluna lateral` |
| Identification | Type | **Static Content** (Source vazio) |
| Layout | Sequence | 30 |
| Layout | Start New Row | **No** |
| Layout | Column Span | **4** |
| Appearance | Template | **Blank with Attributes** |

### 3.6 Regiões "Meu gestor" e "Aniversariantes"

Botão direito em **Coluna lateral** › **Create Sub Region**, duas vezes:

| Seção | Atributo | Meu gestor | Aniversariantes |
|---|---|---|---|
| Identification | Title | `Meu gestor` | `<span class="fa fa-birthday-cake" aria-hidden="true"></span>Aniversariantes de &P28_MES_ATUAL.` |
| Identification | Type | **Dynamic Content** | **Dynamic Content** |
| Source | PL/SQL Function Body returning a CLOB | `return pkg_home_ui.render_meu_gestor;` | `return pkg_home_ui.render_aniversariantes;` |
| Layout | Sequence | 10 | 20 |
| Appearance | Template | **Standard** | **Standard** |
| Appearance | Template Options | Body Padding: **No Padding** (confirmar no 26.1.5) | Body Padding: **No Padding** (confirmar no 26.1.5) |
| Appearance | CSS Classes | `cx-home-card` | `cx-home-card` |
| Advanced | Static ID | `home_meu_gestor` | `home_aniversariantes` |

O package já trata os estados: no Meu gestor, "Nenhum gestor vinculado" com texto diferente para quem não tem vínculo com a empresa e para quem tem vínculo mas não tem gestor; nos aniversariantes, "Nenhum aniversariante em ...". O "Ver todos →" só aparece quando há aniversariantes.

### 3.7 Diálogo "Todos os aniversariantes"

Botão direito em **Dialogs, Drawers and Popups** › **Create Region** (confirmar no 26.1.5):

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Title | `Aniversariantes de &P28_MES_ATUAL.` |
| Identification | Type | **Dynamic Content** |
| Source | PL/SQL Function Body returning a CLOB | `return pkg_home_ui.render_aniversariantes(p_limite => null, p_ver_todos => 'N');` |
| Appearance | Template | **Inline Dialog** |
| Appearance | Template Options | Auto Height · Size: **480x320** (confirmar no 26.1.5) |
| Advanced | Static ID | `aniversariantes_todos` (o JS usa esse ID) |

### 3.8 JavaScript da página

Clique no nó **Page 28** e cole os blocos de `modulos/home/home-pagina.js`:

- **JavaScript › Function and Global Variable Declaration:** BLOCO 1 (`cxHomeCarregarFotos`).
- **JavaScript › Execute when Page Loads:** BLOCO 2.

### 3.9 Como deve ficar a árvore

```
Page 28: Início
├── Pre-Rendering
│   └── Before Header
│       └── Computation P28_MES_ATUAL
├── Dialogs, Drawers and Popups
│   └── Aniversariantes de &P28_MES_ATUAL.   (aniversariantes_todos)
└── Body
    ├── Início                               (home_hero, 10)
    ├── Comunicados ...                      (home_comunicados, 20, span 8)
    │   ├── VER_TODOS        (Copy)
    │   └── NOVO_COMUNICADO  (Edit) ── DA Atualizar comunicados
    └── Coluna lateral                       (30, span 4, não começa linha)
        ├── Meu gestor                       (home_meu_gestor)
        ├── Aniversariantes de ...           (home_aniversariantes)
        └── P28_MES_ATUAL
```

---

## 4. Testar

Abra a página 28 pelo botão **Run** do Page Designer (ou `f?p=100:28`). A página 1 continua sendo a Home, então o menu e o logo ainda levam para ela. Recarregue com **Ctrl+Shift+R** (Cmd+Shift+R no Mac) para não ver CSS antigo em cache.

1. **Hero:** "Olá, <primeiro nome>", a data de hoje por extenso ("Segunda-feira, 19 de outubro de 2026"), os 3 atalhos com ícone em quadrado azul-claro e a arte à direita. Clique num atalho: aparece "Este atalho ainda não tem destino configurado.". Estreite a janela: a arte some e os atalhos quebram linha.
2. **Comunicados:** título + subtítulo; "Ver todos →" e "+ Novo comunicado" à direita. O 1º comunicado tem imagem à esquerda e título maior; os outros dois vêm em lista, cada um com "Para: <departamento>" e a data ("28 de julho").
3. Entre com um usuário **sem** o papel *Publicador de Conteúdo*: o botão "Novo comunicado" some.
4. **Meu gestor:** com um colaborador que tem gestor, aparecem foto (ou iniciais), nome, "Cargo · Departamento", **Chat** (abre a página 4) e **E-mail** (abre o cliente de e-mail). Com as contas da equipe (SARAHSILVA, EDUARDOMARINS, ALAIRTONROCHA, sem colaborador) aparece o estado vazio "Nenhum gestor vinculado".
5. **Aniversariantes:** título "Aniversariantes de <mês>", até 3 pessoas da empresa do usuário, próximos aniversários primeiro; quem faz aniversário hoje tem o selo "Hoje". **Ver todos →** abre o diálogo com o mês inteiro.
6. Tab pela página: os atalhos, os botões e o "Ver todos" mostram o contorno azul de foco.

### Como conferir no export da página 28

```
region home_comunicados (
    name: Comunicados<span class="cx-home-card__subtitulo">Publicações oficiais da empresa</span>
    type: cards
    ...
    appearance {
        template: @/standard
        templateOptions: [
            #DEFAULT#
            t-Region--noPadding
        ]
        cssClasses: [
            cx-home-card
            cx-home-comunicados
        ]
    }
    componentAppearance {
        layout: horizontal
    }
```
e `region home_hero ( type: dynamicContent ... template: @/blank-with-attributes )`, `region aniversariantes_todos ( ... slot: dialogsDrawersAndPopups ... template: @/inline-dialog )`. O identificador depois de `region` é o Static ID. O arquivo esperado é `corlixhub/pages/p00028-inicio.apx` (nome a conferir no próximo backup), e `p00001-home.apx` não deve mudar.

---

## 5. Trocar a Home para a página 28

Só depois que a seção 4 passar. São três ajustes; nenhum mexe na página 1.

| # | Onde | O que mudar |
|---|---|---|
| 1 | *Shared Components › User Interface Attributes* › **Home URL** (confirmar no 26.1.5; no export: `application.apx › navigation › homeUrl`) | Página `1` → `28` |
| 2 | *Shared Components › Navigation Menu* › lista `Navigation Menu` › entrada **Home** | Target: página `1` → `28`. Edite a entrada existente (não crie outra): o "Emitir Comunicado" é filho dela |
| 3 | *Shared Components › Breadcrumbs* › entrada **Home** | Page `1` → `28` e Target página `1` → `28` |

Teste: saia e entre de novo; o login deve cair na 28, e o logo e o item "Home" do menu também. A página 1 continua acessível por `f?p=100:1` (ou `f?p=100:HOME`) para comparar.

**Para voltar atrás:** devolva os três campos para a página `1`.

**A página 1 depois da troca:** fica como está. Se o time decidir removê-la no futuro, isso é uma tarefa à parte; não faz parte deste guia.

### Se não funcionar

| Sintoma | Causa provável | Correção |
|---|---|---|
| `ORA-06550` / `PLS-00201: identifier 'PKG_HOME_UI' must be declared` | Package não instalado | Seção 1 |
| Hero sem a arte (fundo cinza à direita) | `home-hero.jpg` não foi enviado, ou foi para uma pasta | Seção 2: na raiz dos Static Application Files, com esse nome exato |
| Tudo sem estilo (cards sem borda, atalhos como links azuis) | `custom.min.css` antigo no app ou em cache | Suba `.css` e `.min.css` de novo e recarregue com Ctrl+Shift+R |
| "Aniversariantes de " sem o mês | Computação ausente ou com Point diferente de Before Header | Passo 3.2 |
| Comunicados e aniversariantes vazios para todo mundo | `G_ID_EMPRESA` vazio na sessão (só é preenchido no login) | Saia e entre de novo (`docs/ai-context/08` §3, Módulos) |
| Fotos não aparecem, só iniciais | BLOCO 1/2 do JS não está na página 28, ou o arquivo não existe em `Fotos Colaboradores/` | Passo 3.8; confira o arquivo em Static Application Files |
| Comunicado em destaque com área cinza no lugar da imagem | O comunicado não tem imagem | Esperado: a área fica no tom de etiqueta. Se preferir esconder, avise para ajustar o CSS |
| Comunicados com sombra, cantos de 14px ou imagem de 260px | Falta a classe `cx-home-comunicados` na região | Passo 3.4, *CSS Classes* |
| "Novo comunicado" não abre nada | *Behavior › Action* do botão ficou **Defined by Dynamic Action** (`triggerAction`), o que acontece quando a DA é criada pelo botão direito no botão | Passo 3.4: volte a Action para **Redirect to Page in this Application** · página 17 · Clear Cache `17` |
| Menu ou logo ainda abrem a Home antiga | Seção 5 não aplicada (ou só em parte) | Confira os três ajustes da seção 5 |
