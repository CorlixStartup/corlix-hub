# Home (página 28) · redesign · passo a passo no APEX

Este guia monta a nova Home numa **página nova, a 28 ("Início")**, no App Builder do **APEX 26.1.5**, seguindo o protótipo [`pen_dev/Início.png`](../../pen_dev/Início.png) (descrição em `docs/ai-context/07-design-pen-dev.md` §4.1).

> **Situação em 28/10/2026:** o time montou o redesign direto na **página 1** (renomeada para "Início", alias `INÍCIO`; export `corlixhub/pages/p00001-início.apx`), e a página 28 não existe. As seções 1 a 5 ficam como histórico dessa montagem. O protótipo foi atualizado em 28/10/2026 (commit `25c7e8a`): a **[seção 6](#6-atualização-para-o-protótipo-de-28102026-página-1)** leva a página 1 até ele, só com os blocos que têm dados no banco.

> **Situação em 10/11/2026:** o export de 05/11/2026 ainda não tem a seção 6 aplicada (sem carrossel, celebrações nem `home.css`). Com o ponto eletrônico implantado (páginas 30 a 33), a **[seção 7](#7-blocos-do-ponto-eletrônico-página-1)** acrescenta os blocos do protótipo que agora têm dados: o painel "Ponto de hoje" no hero, o banco de horas e "Suas pendências". Aplique a 6 e a 7 na mesma rodada; o registro está em [Situação na app](#situação-na-app).

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
| `pkg_home_ui.pks` / `.pkb` | Package que devolve o HTML do hero (com o "Ponto de hoje"), dos indicadores, das pendências, do Meu gestor e das celebrações |
| `instalar.sql` | Instala o package pelo SQLcl |
| `home-pagina.js` | JavaScript da página (2 blocos; carrossel desde a seção 6, ponto desde a seção 7) |
| `home.css` / `home.min.css` | Estilos do protótipo de 28/10/2026: hero, carrossel, Meu gestor e celebrações (seção 6); ponto, indicadores e pendências (seção 7) |
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
| Advanced | HTML DOM ID | `aniversariantes_todos` (o JS usa esse ID). No 26.1 o **Static ID** só identifica a região no export; o `id` do HTML vem do **HTML DOM ID**. Sem ele, o APEX gera `R<número>` e o "Ver todos →" dá `Region does not support being opened and closed` |

### 3.8 JavaScript da página

Clique no nó **Page 28** e cole os blocos de `modulos/home/home-pagina.js`:

- **JavaScript › Function and Global Variable Declaration:** BLOCO 1 (`cxHomeCarregarFotos`).
- **JavaScript › Execute when Page Loads:** BLOCO 2.

O arquivo já traz o código do ponto (seção 7): relógio do painel, botão de registrar e atualização das pendências. Sem as regiões da seção 7, esse trecho não faz nada.

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

1. **Hero:** "Olá, <primeiro nome>", a data de hoje por extenso ("Segunda-feira, 19 de outubro de 2026"), os 3 atalhos com ícone em quadrado azul-claro e a arte à direita. Clique em **Holerite digital**: abre a página 9. Clique em **Ponto eletrônico** ou **Suporte TI**: aparece "Este atalho ainda não tem destino configurado." (essas páginas ainda não existem; o destino de cada link é o `p_pagina` do `atalho` no `render_hero`). Estreite a janela: a arte some e os atalhos quebram linha.
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
e `region home_hero ( type: dynamicContent ... template: @/blank-with-attributes )`, `region aniversariantes_todos ( ... slot: dialogsDrawersAndPopups ... template: @/inline-dialog ... advanced { htmlDomId: aniversariantes_todos } )`. O identificador depois de `region` é o Static ID, que **não** vira o `id` do HTML; para o JS achar o diálogo, o export precisa ter o `htmlDomId`. O arquivo esperado é `corlixhub/pages/p00028-inicio.apx` (nome a conferir no próximo backup), e `p00001-home.apx` não deve mudar.

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
| "Ver todos →" não abre o diálogo; no console: `Error: Region does not support being opened and closed` | A região do diálogo está sem **HTML DOM ID**, e o `id` no HTML é `R<número>` (confira com `document.querySelector('.js-regionDialog').id`) | Passo 3.7: Advanced › HTML DOM ID = `aniversariantes_todos` |
| "Aniversariantes de " sem o mês | Computação ausente ou com Point diferente de Before Header | Passo 3.2 |
| Comunicados e aniversariantes vazios para todo mundo | `G_ID_EMPRESA` vazio na sessão (só é preenchido no login) | Saia e entre de novo (`docs/ai-context/08` §3, Módulos) |
| Fotos não aparecem, só iniciais | BLOCO 1/2 do JS não está na página 28, ou o arquivo não existe em `Fotos Colaboradores/` | Passo 3.8; confira o arquivo em Static Application Files |
| Comunicado em destaque com área cinza no lugar da imagem | O comunicado não tem imagem | Esperado: a área fica no tom de etiqueta. Se preferir esconder, avise para ajustar o CSS |
| Comunicados com sombra, cantos de 14px ou imagem de 260px | Falta a classe `cx-home-comunicados` na região | Passo 3.4, *CSS Classes* |
| "Novo comunicado" não abre nada | *Behavior › Action* do botão ficou **Defined by Dynamic Action** (`triggerAction`), o que acontece quando a DA é criada pelo botão direito no botão | Passo 3.4: volte a Action para **Redirect to Page in this Application** · página 17 · Clear Cache `17` |
| Menu ou logo ainda abrem a Home antiga | Seção 5 não aplicada (ou só em parte) | Confira os três ajustes da seção 5 |

---

## 6. Atualização para o protótipo de 28/10/2026 (página 1)

O `pen_dev/Início.png` ganhou blocos novos. A página 1 recebe só os que têm dados no banco; os outros ficam pendentes de backend (`docs/ai-context/07` §5).

| Bloco do protótipo | O que esta seção faz |
|---|---|
| Hero "Boa tarde, Sarah" + atalhos Holerite, Organograma, Suporte TI, Chat | Saudação pelo horário de Brasília; 4 atalhos (Holerite → p9, Organograma → p3, Chat → p4, Suporte TI sem destino até aplicar o `modulos/suporte-ti/Etapas-suporte-ti.md` §13); a arte decorativa sai e o hero ocupa a largura toda |
| Comunicados em carrossel (imagem de fundo, selo "Novo", "Ler comunicado →", setas e pontos) | A Cards atual vira carrossel com os 5 mais recentes; "Novo" = publicado há até 7 dias; "Ler comunicado" abre a p11 |
| Meu gestor com "Mensagem" e "Dar feedback" | "Chat" vira **Mensagem** (p4); o segundo botão continua **E-mail** |
| Celebrações de outubro (aniversário e tempo de empresa) | Substitui "Aniversariantes": aniversários + anos de empresa pela `DATA_ADMISSAO`; "hoje" em destaque |

**Ficam de fora (sem tabela no banco):** card "Ponto de hoje" e botão "Registrar saída", faixa de indicadores (banco de horas, próximo pagamento, férias, PDI), "Suas pendências", "Feedbacks recebidos", "Pesquisa de clima", "Próximos eventos", "Próxima conversa 1:1" e "Disponível agora" no Meu gestor, botões "Dar feedback" e "Parabenizar", e o selo "Não lido"/contagem "3 não lidos" nos comunicados (a tabela `COMUNICADO_LEITURA` existe, mas nenhuma página registra a leitura ainda, então todos sairiam como não lidos).

### 6.1 Banco: reinstalar o `pkg_home_ui`

Igual à seção 1 (SQLcl com `instalar.sql`, ou *SQL Workshop › SQL Scripts*, `.pks` e depois `.pkb`).

O que muda no package:
- `render_hero`: "Bom dia" (até 11h59), "Boa tarde" (até 17h59) ou "Boa noite"; os 4 atalhos novos; sem a `<div class="cx-home-hero__arte">`.
- `render_meu_gestor`: botão "Mensagem" no lugar de "Chat" e classe `cx-home-gestor__acoes`.
- `render_celebracoes` (nova): aniversários e anos de empresa do mês, da empresa do usuário, só colaboradores ativos.
- `render_aniversariantes` continua lá e com o mesmo resultado, para a página não quebrar entre a instalação e o passo 6.5.
- Já vem com o que a seção 7 usa (`render_indicadores`, `render_pendencias` e o painel do ponto dentro do `render_hero`). Por isso o package agora **depende do `pkg_ponto`** (`modulos/ponto-eletronico`, já instalado no ambiente): sem ele, a compilação falha com `PLS-00201: identifier 'PKG_PONTO' must be declared`.

**O painel "Ponto de hoje" aparece no hero assim que o package é instalado**, para quem tem colaborador vinculado. O botão de registrar do painel só funciona depois do Ajax Callback do passo 7.3; faça as seções 6 e 7 em seguida.

Assim que o package é instalado, a página 1 já mostra a saudação e os atalhos novos (o hero vem do package). Até o passo 6.2, sobra um espaço vazio onde ficava a arte: suba o CSS logo em seguida.

**Teste** (SQL Commands, um comando por vez):

```sql
select pkg_home_ui.render_celebracoes(p_id_empresa => 1) from dual
```
Deve voltar um `<ul class="cx-home-lista">` com até 4 itens ("Aniversário · 28 de outubro", "2 anos de empresa · 27 de outubro"), ou o estado vazio "Nenhuma celebração em outubro".

### 6.2 Arquivos estáticos

Em *Shared Components › Static Application Files › Create File*, envie **na raiz** (sem pasta) os dois arquivos de `modulos/home/`:

| Arquivo | Nome no APEX |
|---|---|
| `home.css` | `home.css` |
| `home.min.css` | `home.min.css` |

A página carrega `home#MIN#.css`, então os dois precisam existir e estar iguais. Quando mudar o `.css`, gere o `.min.css` de novo e suba os dois. O `custom.css` não muda: o `home.css` só complementa a §12.

Depois, no Page Designer da **página 1**, clique no nó **Page 1** no topo da árvore:

| Seção | Atributo | Valor |
|---|---|---|
| CSS | File URLs | `#APP_FILES#home#MIN#.css` |

### 6.3 Região "Comunicados" (Cards) → carrossel

Selecione a região **Comunicados** (`home_comunicados`).

**Source › SQL Query:** troque pela query abaixo (5 comunicados e a coluna `SELO`):

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
            end as data_publicacao_txt,
       -- selo "Novo": publicado nos últimos 7 dias
       case when c.data_publicacao >= trunc(sysdate) - 7 then 'Novo' end as selo
  from comunicado c
  left join departamento d
    on d.id_departamento = c.id_departamento
 where c.id_empresa = :G_ID_EMPRESA
 order by c.data_publicacao desc, c.id_comunicado desc
 fetch first 5 rows only
```

**Atributos** (no mesmo painel):

| Seção | Atributo | Valor |
|---|---|---|
| Appearance | CSS Classes | `cx-home-card cx-home-comunicados cx-home-carrossel` (acrescente `cx-home-carrossel`) |
| Title | HTML Expression | trecho abaixo |
| Media | Position | **First** (sem mudança: o CSS põe a imagem no fundo) |
| Media | Sizing | **Cover** (sem mudança) |

**Title › HTML Expression:**

```html
<span class="cx-home-comunicado__meta">
  {if SELO/}<span class="cx-badge cx-badge--info">&SELO.</span>{endif/}
  <span class="cx-etiqueta">&PUBLICO.</span>
  <span>&DATA_PUBLICACAO_TXT.</span>
</span>
<span class="cx-home-comunicado__titulo">&TITULO.</span>
```

**Ação "Ler comunicado".** Na árvore, abra a região **Comunicados**, botão direito em **Actions** › **Create Action**:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Type | **Button** |
| Identification | Label | `Ler comunicado` |
| Layout | Position | **Primary** (confirmar no 26.1.5) |
| Appearance | Display Type | **Text with Icon** (confirmar no 26.1.5) |
| Appearance | Icon | `fa-arrow-right` |
| Link | Type | **Redirect to Page in this Application** |
| Link | Target | Page **11** |

A página 11 (Comunicados) ainda é placeholder e não abre um comunicado específico. Quando ganhar a leitura de um comunicado, o *Target* passa a levar o `&ID_COMUNICADO.` num item dela.

Os botões "Ver todos" e "Novo comunicado" e a DA "Atualizar comunicados" ficam como estão. Depois do refresh da DA, o JS (passo 6.6) monta as setas de novo.

### 6.4 Região "Meu gestor"

Nada a mudar no Builder: o HTML novo vem do package (passo 6.1) e o estilo, do `home.css` (passo 6.2).

### 6.5 Região "Aniversariantes" → "Celebrações"

Selecione a região **Aniversariantes** (`home_aniversariantes`, dentro de "Coluna lateral"):

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `Celebrações` |
| Identification | Title | `<span class="fa fa-birthday-cake" aria-hidden="true"></span>Celebrações de &P1_MES_ATUAL.` |
| Source | PL/SQL Function Body returning a CLOB | `return pkg_home_ui.render_celebracoes;` |

Depois selecione o diálogo **Aniversariantes** (`aniversariantes_todos`, em *Dialogs, Drawers and Popups*):

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `Celebrações` |
| Identification | Title | `Celebrações de &P1_MES_ATUAL.` |
| Source | PL/SQL Function Body returning a CLOB | `return pkg_home_ui.render_celebracoes(p_limite => null, p_ver_todos => 'N');` |
| Advanced | HTML DOM ID | `aniversariantes_todos` (**não mude**: o "Ver todos" abre o diálogo por esse ID) |

### 6.6 JavaScript da página

Clique no nó **Page 1** e substitua os dois campos pelos blocos de `modulos/home/home-pagina.js`:

- **JavaScript › Function and Global Variable Declaration:** BLOCO 1 (`cxHomeCarregarFotos` e `cxHomeCarrossel`).
- **JavaScript › Execute when Page Loads:** BLOCO 2.

### 6.7 Testar

Abra a página 1 e recarregue com **Ctrl+Shift+R** (Cmd+Shift+R no Mac).

1. **Hero:** "Boa tarde, <primeiro nome>" (ou Bom dia / Boa noite, pelo horário de Brasília), a data por extenso e os 4 atalhos; o card ocupa a largura toda, sem a arte. Holerite abre a p9, Organograma a p3, Chat a p4; Suporte TI mostra "Este atalho ainda não tem destino configurado." até aplicar o `modulos/suporte-ti/Etapas-suporte-ti.md` §13, e depois abre a p34.
2. **Comunicados:** um comunicado por vez, com a imagem de fundo escurecida e o texto branco à esquerda; o selo **Novo** só nos publicados há até 7 dias; botão branco **Ler comunicado →** (abre a p11). Setas nas laterais e pontos embaixo; o ponto do slide atual fica mais largo. Com a janela estreita, as setas somem e o carrossel rola com o dedo ou o trackpad.
3. Com só 1 comunicado na empresa: sem setas nem pontos. Sem comunicado: a mensagem "Nenhum comunicado publicado...".
4. **Novo comunicado** (usuário publicador): ao fechar a p17, a lista atualiza e as setas continuam funcionando.
5. **Meu gestor:** botões **Mensagem** e **E-mail** lado a lado, com a mesma largura.
6. **Celebrações de <mês>:** aniversários ("Aniversário · 28 de outubro") e tempo de empresa ("2 anos de empresa · 27 de outubro"); quem celebra hoje aparece com "· hoje" em azul. **Ver todos →** abre o diálogo com o mês inteiro.

**No export** (`corlixhub/pages/p00001-início.apx`, depois do próximo backup), procure: `fileUrls: #APP_FILES#home#MIN#.css` no bloco `css` da página; `cx-home-carrossel` nas `cssClasses` da `home_comunicados`; um `action` com `label: Ler comunicado` dentro dela; e `pkg_home_ui.render_celebracoes` nas regiões `home_aniversariantes` e `aniversariantes_todos`.

### 6.8 Se não funcionar

| Sintoma | Causa provável | Correção |
|---|---|---|
| Hero com um espaço vazio à direita | `home.css` não carregou (arquivo não enviado ou *File URLs* vazio) | Passo 6.2; recarregue com Ctrl+Shift+R |
| Comunicados um embaixo do outro, sem imagem de fundo | Falta `cx-home-carrossel` nas *CSS Classes* da região, ou o `home.css` não carregou | Passos 6.3 e 6.2 |
| Carrossel aparece, mas sem setas nem pontos | BLOCO 1/2 do JS não foi atualizado, ou só existe 1 comunicado | Passo 6.6; com 1 comunicado é o esperado |
| Setas somem depois de criar um comunicado | Falta o trecho `apexafterrefresh` do BLOCO 2 | Passo 6.6 |
| Aparece `{if SELO/}` como texto | A expressão foi colada em *Body*, ou *Title › Advanced Formatting* está desligado | Passo 6.3 |
| `ORA-00904: "SELO": invalid identifier` | A query nova não foi salva | Passo 6.3, *Source › SQL Query* |
| Botão "Ler comunicado" não aparece | Ação criada com outro *Type* (Full Card, Title...) | Passo 6.3: *Type* **Button** |
| Celebrações sem os anos de empresa | Colaboradores sem `DATA_ADMISSAO`, ou admitidos neste ano (só conta a partir de 1 ano) | Esperado; confira com `select nome_completo, data_admissao from colaborador where to_char(data_admissao, 'mm') = to_char(sysdate, 'mm')` |
| `PLS-00302: component 'RENDER_CELEBRACOES' must be declared` | Package antigo no banco | Passo 6.1 |
| Título do comunicado escuro sobre a foto, difícil de ler | `home.css` anterior a 10/11/2026: com a *HTML Expression*, o título fica no `.a-CardView-header`, fora do `.a-CardView-title` | Suba de novo o `home.css` e o `home.min.css` (passo 6.2) |
| Painel "Ponto de hoje" aparece sem estilo (tudo empilhado) | `home.css` antigo no Static Application Files | Passo 6.2 com os arquivos desta versão (têm as seções 5 a 7) |

---

## 7. Blocos do ponto eletrônico (página 1)

O ponto eletrônico (páginas 30 a 33, `modulos/ponto-eletronico`) já tem dados. Esta seção põe na Home os blocos do protótipo que vêm dele. **Faça a seção 6 antes**: esta usa o package, o CSS e o JS de lá.

| Bloco do protótipo | O que entra | Fonte |
|---|---|---|
| Card **Ponto de hoje** à direita do hero | Hora atual, "4h33 trabalhadas · faltam 3h27", selo (Não iniciada, Em jornada, Em intervalo, Jornada concluída ou o nome do feriado), botão da próxima marcação (Registrar entrada, Iniciar intervalo, Voltar do intervalo, Registrar saída) e a linha Entrada → Intervalo → Retorno → Saída prev. O título abre a página 30 | `pkg_ponto` (as mesmas funções do relógio da página 30) |
| Faixa de indicadores: **Banco de horas** | Saldo ("+6h15", verde se positivo, vermelho se negativo), "Saldo até ontem · ver espelho" ou, se houver horas para vencer em até 60 dias, "3h10 vencem em 31/12/2026 · ver espelho" | `pkg_ponto.calcular_banco` |
| **Suas pendências** | Do ponto: marcação incompleta ou dia sem marcação nos últimos 30 dias (até 5, botão **Justificar** abre a página 31 já preenchida), espelho do mês a assinar (**Assinar** abre a página 30, onde fica o diálogo de assinatura) e, para gestor ou RH, "N pedidos de ajuste de ponto" (**Responder** abre a página 32). Sem nada: "Nenhuma pendência" | `pkg_ponto` |

**Ficam de fora:** os outros 3 indicadores (Próximo pagamento, Férias, Meu PDI), as pendências de outros módulos (avaliação, documento, feedback, chamado), o número no título "Suas pendências" e o "Ver todas". Seguem em `docs/ai-context/07` §5.

**Quem vê o quê:**
- Conta sem colaborador na empresa (equipe do Corlix Hub, RH sem cadastro): hero sem o painel, sem indicadores. Em "Suas pendências", o RH vê os pedidos de ajuste, se houver; os outros veem "Nenhuma pendência".
- Empresa sem jornada cadastrada (`-20061`): a página abre normalmente, sem os blocos do ponto.
- Registrar a marcação: o `pkg_ponto.registrar_marcacao` só grava para o colaborador da conta logada. O Ajax Callback ainda pede a autorização `COLABORADOR`, a mesma da página 30.
- Links: página 30 e 31 (`COLABORADOR`) só aparecem para quem tem colaborador; página 32 (`APROVADOR_PONTO`) só no item de pedidos, que só aparece para quem passa no `pkg_ponto.fn_e_aprovador`, a mesma função do esquema.

### 7.1 Banco e arquivos

Nada além da seção 6: o package do passo 6.1 e os arquivos do passo 6.2 já têm tudo. Se instalou antes desta versão, reinstale o package (6.1) e suba de novo o `home.css` e o `home.min.css` (6.2).

**Teste** (SQL Commands, um comando por vez; troque `123` por um colaborador com ponto, como na seção "Conta de teste" do `modulos/ponto-eletronico/Etapas-ponto-eletronico.md`):

```sql
select pkg_home_ui.render_hero(p_id_colaborador => 123) from dual
```
Deve voltar a `<section class="cx-home-hero cx-home-hero--ponto">` com um `<aside class="cx-home-ponto"` no fim.

```sql
select pkg_home_ui.render_indicadores(p_id_colaborador => 123) from dual
```
Deve voltar um `<ul class="cx-home-indicadores">` com o banco de horas.

```sql
select pkg_home_ui.render_pendencias(p_id_colaborador => 123) from dual
```
Deve voltar um `<ul class="cx-home-pendencias">` ou o estado vazio "Nenhuma pendência". No SQL Commands os links saem sem sessão; isso é esperado.

### 7.2 Regiões

O hero não muda no Builder: o painel vem do `render_hero`. Ele só precisa de um id para o JS atualizar depois de registrar a marcação.

Selecione a região **Início** (`home_hero`):

| Seção | Atributo | Valor |
|---|---|---|
| Advanced | HTML DOM ID | `home_hero` |

**Indicadores.** Botão direito em **Body** › **Create Region**:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `Indicadores` |
| Identification | Type | **Dynamic Content** |
| Source | PL/SQL Function Body returning a CLOB | `return pkg_home_ui.render_indicadores;` |
| Layout | Sequence | `15` |
| Layout | Start New Row | Yes |
| Appearance | Template | **Blank with Attributes** |
| Advanced | HTML DOM ID | `home_indicadores` |

**Coluna principal.** Hoje a Comunicados ocupa a coluna da esquerda sozinha (span 8). Para "Suas pendências" ficar embaixo dela, as duas vão para uma região de coluna, como a Coluna lateral (e como as colunas da página 30). Botão direito em **Body** › **Create Region**:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `Coluna principal` |
| Identification | Type | **Static Content** (Source vazio) |
| Layout | Sequence | `20` |
| Layout | Start New Row | Yes |
| Layout | Column Span | **8** |
| Appearance | Template | **Blank with Attributes** |

Selecione a região **Comunicados** (`home_comunicados`):

| Seção | Atributo | Valor |
|---|---|---|
| Layout | Parent Region | `Coluna principal` |
| Layout | Slot | **Sub Regions** (o Builder pode sugerir *Region Body*; troque) |
| Layout | Sequence | `10` |
| Layout | Column Span | **Automatic** (era 8; agora a coluna é que tem o 8) |

Os botões "Ver todos" e "Novo comunicado", a ação "Ler comunicado" e a DA "Atualizar comunicados" vão junto com a região; não mexa neles.

**Suas pendências.** Botão direito em **Coluna principal** › **Create Sub Region**:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `Suas pendências` |
| Identification | Title | `Suas pendências<span class="cx-home-card__subtitulo">Itens que aguardam uma ação sua</span>` |
| Identification | Type | **Dynamic Content** |
| Source | PL/SQL Function Body returning a CLOB | `return pkg_home_ui.render_pendencias;` |
| Layout | Sequence | `20` |
| Appearance | Template | **Standard** |
| Appearance | Template Options | As mesmas do Meu gestor: **Remove Body Padding** e o corpo com rolagem (no export, `t-Region--noPadding` e `t-Region--scrollBody`) |
| Appearance | CSS Classes | `cx-home-card` |
| Advanced | HTML DOM ID | `home_pendencias` |

A **Coluna lateral** fica como está (Sequence 30, span 4, *Start New Row* No): ela continua na mesma linha da Coluna principal.

**O HTML DOM ID é obrigatório** no hero e nas pendências: o JS atualiza as regiões por ele. Sem ele, o APEX gera `R<número>` e o refresh não acontece (`docs/ai-context/08` §3, "Static ID ≠ id do HTML").

### 7.3 Ajax Callback

Na aba **Processing** do Page Designer, botão direito em **Ajax Callback** › **Create Process**:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `REGISTRAR_MARCACAO` (exatamente assim: o JS chama por esse nome) |
| Identification | Type | **Execute Code** |
| Source | PL/SQL Code | `pkg_ponto_ui.ajax_registrar(apex_application.g_x01);` |
| Security | Authorization Scheme | **COLABORADOR** (confirmar no 26.1.5) |

É o mesmo processo da página 30: o `pkg_ponto_ui.ajax_registrar` responde `{"ok":..., "mensagem":...}` e o JS mostra a mensagem.

### 7.4 Como deve ficar a árvore

```
Page 1: Início                          (home#MIN#.css)
├── Body
│   ├── Início                          (10, home_hero)
│   ├── Indicadores                     (15, home_indicadores)
│   ├── Coluna principal                (20, span 8)
│   │   ├── Comunicados                 (10, Cards, cx-home-carrossel)
│   │   └── Suas pendências             (20, home_pendencias)
│   └── Coluna lateral                  (30, span 4, não começa linha)
│       ├── P1_MES_ATUAL
│       ├── Meu gestor                  (10)
│       └── Celebrações                 (20)
├── Dialogs, Drawers and Popups
│   └── Celebrações                     (aniversariantes_todos)
└── Ajax Callback
    └── REGISTRAR_MARCACAO
```

### 7.5 Testar

Use uma conta com colaborador vinculado e ponto (as contas SARAHSILVA, EDUARDOMARINS e ALAIRTONROCHA não têm colaborador). Recarregue a página 1 com **Ctrl+Shift+R**.

1. **Painel:** à direita do hero, "Ponto de hoje" com a hora correndo, o selo e a linha do dia batendo com a página 30. Com a janela estreita, o painel desce para baixo da saudação.
2. **Registrar:** clique no botão do painel. Aparece "Marcação registrada: ... Comprovante nº ..." e o painel atualiza (o passo fica marcado, o botão muda para a próxima marcação). Confira a mesma marcação na página 30.
3. Clique de novo rápido, ou registre em outra aba antes: aparece o erro de marcação fora da sequência, sem gravar duas vezes.
4. **Horas:** com a jornada em andamento, "trabalhadas" sobe a cada minuto sem recarregar; no intervalo, fica parado.
5. **Banco de horas:** o mesmo saldo do card "Banco de horas" da página 30; "ver espelho" abre a página 30.
6. **Pendências:** os mesmos dias do card "Pendências" da página 30. **Justificar** abre o modal da página 31 já com o dia e a marcação; ao enviar, o item some da lista (em análise não conta mais).
7. Com o espelho do mês a assinar: item "Assinar o espelho de <mês>" com o prazo; **Assinar** abre a página 30.
8. **Gestor** com pedido de ajuste pendente de alguém da equipe: item "1 pedido de ajuste de ponto"; **Responder** abre a página 32.
9. **Conta sem colaborador:** hero sem painel e na largura toda, sem a faixa de indicadores, e "Nenhuma pendência" (ou, no RH, os pedidos de ajuste).
10. A seção 6 continua funcionando: carrossel, Meu gestor e Celebrações.

**No export** (`corlixhub/pages/p00001-início.apx`, depois do próximo backup): `htmlDomId: home_hero` na região `home_hero`; regiões com `pkg_home_ui.render_indicadores` e `pkg_home_ui.render_pendencias`, esta com `parentRegion` da Coluna principal e `htmlDomId: home_pendencias`; `home_comunicados` com `parentRegion` da Coluna principal e sem `columnSpan: 8`; e um `process` com `name: REGISTRAR_MARCACAO` e `point: ajaxCallback`.

### 7.6 Se não funcionar

| Sintoma | Causa provável | Correção |
|---|---|---|
| `PLS-00201: identifier 'PKG_PONTO' must be declared` ao instalar | Módulo do ponto não instalado no schema | Instale `modulos/ponto-eletronico` antes |
| Painel não aparece para um colaborador | Conta sem vínculo na empresa da sessão, ou empresa sem jornada | Esperado; confira com o aviso da página 30, que usa a mesma regra |
| Botão do painel não faz nada, ou erro de processo não encontrado | Ajax Callback ausente ou com outro nome | Passo 7.3, *Name* `REGISTRAR_MARCACAO` |
| Marcação gravada, mas o painel não muda | Falta o HTML DOM ID `home_hero` | Passo 7.2 |
| "Justificar" envia, mas a lista não atualiza | Falta o HTML DOM ID `home_pendencias`, ou o BLOCO 2 é o antigo | Passos 7.2 e 6.6 |
| Comunicados sem espaço até Suas pendências, ou fora da grade da coluna | Comunicados no *Slot* **Region Body** da Coluna principal | Passo 7.2: *Slot* **Sub Regions**, como Suas pendências |
| Pendências embaixo da coluna lateral, e não da Comunicados | Comunicados ou Suas pendências fora da Coluna principal | Passo 7.2 (*Parent Region*) |
| Comunicados estreita dentro da coluna | *Column Span* 8 ficou na Comunicados | Passo 7.2: *Automatic* |
| Hora do painel diferente da página 30 | Não deve acontecer: as duas usam o fuso da empresa | Registre o caso no `09` com print das duas |

### Referências reutilizadas (seção 7)

| De onde | O que veio | Adaptação |
|---|---|---|
| `modulos/ponto-eletronico/04_pkg_ponto_ui.pkb` (`render_relogio`, `render_banco`, `render_pendencias`) | Regras de exibição: próxima marcação, saída prevista, horas trabalhadas, janela de 30 dias, links para a página 31 já preenchida, aviso de 60 dias do banco | Painel compacto no hero; `saida_prevista` copiado (é privado no `pkg_ponto_ui`); pendências no formato do protótipo da Home |
| `pkg_ponto_ui.icone` | Ícones SVG Lucide em linha (regra de ícones do `11` §3) | Classe `cx-home-icone`; ícones `clock`, `calendar-x` e `users` novos |
| `ponto.css` (`.cx-ponto-selo`, `.cx-ponto-passo`, `.cx-ponto-registrar`) | Selos, linha do dia e botão escuro | Classes `cx-home-*` no `home.css`; as 4 cores de selo copiadas para variáveis `--cx-home-*` |
| `ponto-pagina.js` | Relógio a partir da hora do servidor e chamada `apex.server.process` com `{ok, mensagem}` | Funções `cxHomePontoRelogio` e o clique em `data-cx-home-registrar` |
| Página 30 (`p00030-ponto-eletronico.apx`) | Ajax Callback `REGISTRAR_MARCACAO`, colunas em Blank with Attributes, HTML DOM ID nas regiões atualizadas | O mesmo na página 1 |
| Seção 6 deste guia | Cards `cx-home-card`, estado vazio `estado_vazio`, título com subtítulo | Suas pendências segue o Meu gestor |

---

## 8. Fidelidade ao protótipo: categoria, leitura e os blocos que faltavam (página 1)

Depois das seções 6 e 7, a Home foi comparada na app com o protótipo de 28/10/2026, em 10/11/2026, com a conta `teste.rh`. Esta seção leva a página 1 até ele:

| Bloco | O que muda | Dados |
|---|---|---|
| Carrossel | Etiqueta da **categoria** ("Institucional"); "Para: Todos · 9 de novembro" em texto; seta do "Ler comunicado" à direita, logo abaixo do resumo; "**Não lido**" ao lado do botão; "· 3 não lidos" no subtítulo | `CATEGORIA_COMUNICADO` (nova, `modulos/comunicados`) e `COMUNICADO_LEITURA` (já existia) |
| Indicadores | Além do banco de horas: **Próximo/Último pagamento** (valor oculto até clicar no olho, como na p9), **Férias disponíveis** e **Meu PDI** com barra | `COLABORADOR_HOLERITE` (já existia); `FERIAS_PERIODO`, `PDI`, `PDI_OBJETIVO` (novas, `modulos/home-blocos`) |
| Suas pendências | Número no título | Do §7 |
| Feedbacks recebidos | Região nova: os 2 últimos, com autor, relação ("Gestão direta", "Colega de equipe"), tipo e texto | `FEEDBACK` (nova) |
| Meu gestor | "Disponível agora" (mesma regra do chat), "Próxima conversa 1:1", botões **Mensagem** e **Dar feedback** (o "E-mail" sai, como no protótipo) | `PRESENCA_COLABORADOR` (já existia); `CONVERSA_1A1` (nova) |
| Pesquisa de clima | Região nova: pesquisa aberta, "Aberta até", "Responder pesquisa" (abre o formulário em outra aba e registra a participação; o card some) | `PESQUISA`, `PESQUISA_RESPOSTA` (novas) |
| Próximos eventos | Região nova: 4 próximos, com data em bloco e selo "Hoje"/"Amanhã"/"Feriado" | `EVENTO` (nova) + `PONTO_FERIADO` (já existia) |
| Celebrações | "**Parabenizar**" para quem celebra hoje (abre o diálogo de feedback já preenchido) | `FEEDBACK` |
| Avatar | "[DEMO] Karen Dias" mostrava "[D"; agora "KD" | — |

**Ficam de fora**, por não haver tela de destino: os "Ver todos/Ver todas" de pendências, feedbacks e eventos ("Ver agenda"), e a página do comunicado ("Ler comunicado" continua indo para a p11, que é placeholder). "Responder pesquisa" usa um link externo (`PESQUISA.DS_LINK`), porque o app não tem formulário de pesquisa.

### 8.1 Banco (nesta ordem)

1. `modulos/comunicados/01_ddl_categoria.sql`: tabela de categorias, coluna `COMUNICADO.ID_CATEGORIA` e 7 categorias para cada empresa.
2. `modulos/comunicados/02_categoria_demo.sql`: categoria dos 5 comunicados de exemplo (se você criou os exemplos).
3. `modulos/home-blocos/01_ddl_blocos.sql`: as 8 tabelas novas.
4. `modulos/home-blocos/02_dados_demo.sql`: troque `TROQUE_PELO_LOGIN` pelo login ou ID de quem vai ver os exemplos (ex.: o ID de `teste.rh`). Cria 2 feedbacks, a pesquisa, 3 eventos, a próxima 1:1, férias e um PDI. **Troque o `ds_link` da pesquisa** pelo formulário real quando houver.
5. Reinstale o `pkg_home_ui` (`modulos/home/instalar.sql`, ou o `.pks` e o `.pkb` em *SQL Scripts*). Ele passa a depender das tabelas dos passos 1 e 3: sem elas, a compilação falha com `PL/SQL: ORA-00942: table or view does not exist`.

**Teste** (SQL Commands, troque `123` pelo ID usado no passo 4):

```sql
select pkg_home_ui.render_indicadores(p_id_colaborador => 123) from dual
```
Deve voltar até 4 `<li class="cx-home-indicador">` (banco de horas, pagamento, férias e PDI).

### 8.2 Arquivos estáticos e JavaScript

- Suba de novo o `home.css` e o `home.min.css` em `modulos/home/` (seções 6 a 14 do arquivo).
- A arte da pesquisa usa o `home-hero.jpg` que já está na **raiz** do *Static Application Files* (o CSS aponta para `../../home-hero.jpg`, a partir de `modulos/home/`). Se ela não existir lá, envie `modulos/home/home-hero.jpg` para a raiz.
- No nó **Page 1**, substitua os dois campos de JavaScript pelos BLOCOS 1 e 2 do `home-pagina.js`.

### 8.3 Itens e computações dos títulos

Botão direito em **Coluna lateral** › **Create Page Item**, duas vezes, como o `P1_MES_ATUAL`:

| Seção | Atributo | Item 1 | Item 2 |
|---|---|---|---|
| Identification | Name | `P1_NAO_LIDOS` | `P1_QT_PENDENCIAS` |
| Identification | Type | **Hidden** | **Hidden** |

Em *Pre-Rendering › Before Header*, crie duas **Computations**, como a do `P1_MES_ATUAL`:

| Item | Type | PL/SQL Expression |
|---|---|---|
| `P1_NAO_LIDOS` | PL/SQL Expression | `pkg_home_ui.nao_lidos_texto` |
| `P1_QT_PENDENCIAS` | PL/SQL Expression | `pkg_home_ui.qt_pendencias` |

### 8.4 Região "Comunicados"

**Identification › Title:**
```html
Comunicados<span class="cx-home-card__subtitulo">Publicações oficiais da empresa&P1_NAO_LIDOS.</span>
```

**Source › SQL Query** (acrescenta `CATEGORIA` e `NAO_LIDO`):
```sql
select c.id_comunicado,
       c.titulo,
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
            end as data_publicacao_txt,
       case when c.data_publicacao >= trunc(sysdate) - 7 then 'Novo' end as selo,
       k.nm_categoria as categoria,
       -- "Não lido": só para quem tem colaborador e ainda não abriu
       case when eu.id_colaborador is not null
             and not exists (select 1 from comunicado_leitura l
                              where l.id_comunicado = c.id_comunicado
                                and l.id_colaborador = eu.id_colaborador)
            then 'S' end as nao_lido
  from comunicado c
  left join departamento d
    on d.id_departamento = c.id_departamento
  left join categoria_comunicado k
    on k.id_categoria = c.id_categoria
  left join colaborador eu
    on upper(trim(eu.login_apex)) = upper(trim(:APP_USER))
   and eu.id_empresa = c.id_empresa
 where c.id_empresa = :G_ID_EMPRESA
 order by c.data_publicacao desc, c.id_comunicado desc
 fetch first 5 rows only
```

**Title › HTML Expression** (categoria como etiqueta; público e data em texto):
```html
<span class="cx-home-comunicado__meta">
  {if SELO/}<span class="cx-badge cx-badge--info">&SELO.</span>{endif/}
  {if CATEGORIA/}<span class="cx-etiqueta">&CATEGORIA.</span>{endif/}
  <span class="cx-home-comunicado__para">&PUBLICO. · &DATA_PUBLICACAO_TXT.</span>
</span>
<span class="cx-home-comunicado__titulo">&TITULO.</span>
```

**Body:** ligue *Advanced Formatting* e use esta *HTML Expression* (confirmar no 26.1.5: o mesmo par de atributos do *Title*). No export deve aparecer `body { advancedFormatting: true  htmlExpression: ... }` no lugar de `column: RESUMO`.
```html
&RESUMO.{if NAO_LIDO/}<span class="cx-home-nao-lido" data-cx-nao-lido>Não lido</span>{endif/}
```
O JS move o "Não lido" para o lado do botão.

### 8.5 Região "Suas pendências"

**Identification › Title:**
```html
Suas pendências<span class="cx-home-contador">&P1_QT_PENDENCIAS.</span><span class="cx-home-card__subtitulo">Itens que aguardam uma ação sua</span>
```
Sem pendência, o item fica vazio e o CSS esconde o número.

### 8.6 Regiões novas

**Feedbacks recebidos.** Botão direito em **Coluna principal** › **Create Sub Region**:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `Feedbacks recebidos` |
| Identification | Title | `Feedbacks recebidos<span class="cx-home-card__subtitulo">Reconhecimentos e sugestões que você recebeu</span>` |
| Identification | Type | **Dynamic Content** |
| Source | PL/SQL Function Body returning a CLOB | `return pkg_home_ui.render_feedbacks;` |
| Layout | Slot | **Sub Regions** |
| Layout | Sequence | `30` |
| Appearance | Template | **Standard**, com as mesmas *Template Options* e a classe `cx-home-card` do Meu gestor |

**Na Coluna lateral**, a ordem passa a ser: Meu gestor (10), Pesquisa de clima (20), Próximos eventos (30), Celebrações (40). Selecione **Celebrações** (`home_aniversariantes`) e mude *Layout › Sequence* para `40`. Depois, botão direito em **Coluna lateral** › **Create Sub Region**, duas vezes:

| Seção | Atributo | Pesquisa de clima | Próximos eventos |
|---|---|---|---|
| Identification | Name | `Pesquisa de clima` | `Próximos eventos` |
| Identification | Title | (vazio) | `<span class="fa fa-calendar-o" aria-hidden="true"></span>Próximos eventos` |
| Identification | Type | **Dynamic Content** | **Dynamic Content** |
| Source | PL/SQL Function Body returning a CLOB | `return pkg_home_ui.render_pesquisa;` | `return pkg_home_ui.render_eventos;` |
| Layout | Slot | **Sub Regions** | **Sub Regions** |
| Layout | Sequence | `20` | `30` |
| Appearance | Template | **Blank with Attributes** (o card vem pronto do package) | **Standard**, *Template Options* e classe `cx-home-card` como o Meu gestor |
| Advanced | HTML DOM ID | `home_pesquisa` | (vazio) |

### 8.7 Diálogo "Dar feedback"

Botão direito em **Dialogs, Drawers and Popups** › **Create Region**:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `Dar feedback` |
| Identification | Title | `Dar feedback` |
| Identification | Type | **Static Content** |
| Source | HTML Code | `<p class="cx-home-fb-para">Para <strong data-cx-home-fb-nome></strong></p>` |
| Appearance | Template | **Inline Dialog** |
| Advanced | HTML DOM ID | `home_dlg_feedback` (**obrigatório**: o JS abre o diálogo por ele) |

Itens, com botão direito em **Dar feedback** › **Create Page Item**:

| Name | Type | Configuração |
|---|---|---|
| `P1_FB_DESTINATARIO` | **Hidden** | *Settings › Value Protected* **No** (o JS preenche; o package confere a empresa) |
| `P1_FB_TIPO` | **Radio Group** | *Label* `Tipo`; *List of Values* **Static Values**: `Reconhecimento` → `RECONHECIMENTO`, `Sugestão` → `SUGESTAO`; *Default* `RECONHECIMENTO`; *Template Options* exibir como botões, se houver (confirmar no 26.1.5) |
| `P1_FB_TEXTO` | **Textarea** | *Label* `Feedback`; *Validation › Maximum Length* `1000`; *Appearance › Template* **Required - Floating** |

Botões, com botão direito em **Dar feedback** › **Create Button**:

| Name | Label | Slot | Hot | Behavior › Action | Advanced › CSS Classes |
|---|---|---|---|---|---|
| `FB_CANCELAR` | `Cancelar` | **Close** | No | **Defined by Dynamic Action** | `cx-home-fb-cancelar` |
| `FB_ENVIAR` | `Enviar feedback` | **Create** | Yes | **Defined by Dynamic Action** | `cx-home-fb-enviar` |

Não crie Dynamic Actions: o JS da página trata os dois botões pelas classes.

### 8.8 Ajax Callbacks

Na aba **Processing**, botão direito em **Ajax Callback** › **Create Process**, três vezes. *Type* **Execute Code**. *Security › Authorization Scheme* **COLABORADOR** nos três.

| Name | PL/SQL Code |
|---|---|
| `MARCAR_LIDO` | `pkg_home_ui.ajax_marcar_lido(apex_application.g_x01);` |
| `RESPONDER_PESQUISA` | `pkg_home_ui.ajax_responder_pesquisa(apex_application.g_x01);` |
| `SALVAR_FEEDBACK` | `pkg_home_ui.ajax_salvar_feedback(apex_application.g_x01, apex_application.g_x02, apex_application.g_x03);` |

### 8.9 Página 17: campo Categoria

Siga `modulos/comunicados/Etapas-comunicados.md` §2: LOV `LOV_CATEGORIA_COMUNICADO` e o item `P17_ID_CATEGORIA`.

### 8.10 Como deve ficar a árvore

```
Page 1: Início
├── Body
│   ├── Início                          (10, home_hero)
│   ├── Indicadores                     (15, home_indicadores)
│   ├── Coluna principal                (20, span 8)
│   │   ├── Comunicados                 (10)
│   │   ├── Suas pendências             (20, home_pendencias)
│   │   └── Feedbacks recebidos         (30)
│   └── Coluna lateral                  (30, span 4)
│       ├── P1_MES_ATUAL, P1_NAO_LIDOS, P1_QT_PENDENCIAS
│       ├── Meu gestor                  (10)
│       ├── Pesquisa de clima           (20, home_pesquisa)
│       ├── Próximos eventos            (30)
│       └── Celebrações                 (40)
├── Dialogs, Drawers and Popups
│   ├── Celebrações                     (aniversariantes_todos)
│   └── Dar feedback                    (home_dlg_feedback)
└── Ajax Callback
    ├── REGISTRAR_MARCACAO
    ├── MARCAR_LIDO
    ├── RESPONDER_PESQUISA
    └── SALVAR_FEEDBACK
```

### 8.11 Testar

Com a conta usada no passo 8.1.4 e a página recarregada com **Cmd+Shift+R**:

1. **Carrossel:** etiqueta da categoria, "Para: Todos · <data>" em texto, título branco, resumo em 2 linhas com "…", botão "Ler comunicado →" logo abaixo e "• Não lido" ao lado. Subtítulo "Publicações oficiais da empresa · N não lidos".
2. Clique em **Ler comunicado**: abre a p11. Volte: aquele comunicado não tem mais "Não lido" e o número do subtítulo diminuiu.
3. **Indicadores:** 4 blocos numa faixa. O pagamento chega como `R$ ••••••`; o olho mostra e esconde. Recarregue: volta oculto.
4. **Suas pendências:** número no título igual ao total da lista.
5. **Feedbacks recebidos:** os 2 exemplos, com "Gestão direta"/"Colega" e os selos Reconhecimento/Sugestão.
6. **Meu gestor:** com o gestor com o chat aberto (online), ponto verde e "Disponível agora"; "Próxima conversa 1:1" com dia e hora. **Dar feedback** abre o diálogo "Para <gestor>"; enviar mostra "Feedback enviado." Enviar vazio mostra "Escreva o feedback antes de enviar."
7. **Pesquisa de clima:** card com a arte. "Responder pesquisa" abre o link em outra aba e o card some da Home.
8. **Próximos eventos:** os 3 exemplos e os feriados do ponto, em ordem de data.
9. **Celebrações:** quem celebra hoje tem "Parabenizar"; o diálogo abre com "Feliz aniversário! " ou "Parabéns pelos N anos de empresa! ". "[DEMO] Karen Dias" com "KD".
10. **Conta sem colaborador:** sem indicadores, sem pesquisa, "Nenhum feedback ainda", sem botões de feedback.

### 8.12 Se não funcionar

| Sintoma | Causa provável | Correção |
|---|---|---|
| `ORA-00942` ao compilar o `pkg_home_ui` | Tabelas dos módulos `comunicados` ou `home-blocos` não instaladas | Passos 8.1.1 e 8.1.3 antes do 8.1.5 |
| `ORA-00904: "K"."NM_CATEGORIA"` na Comunicados | Faltou o `01_ddl_categoria.sql` | Passo 8.1.1 |
| Aparece `&P1_NAO_LIDOS.` ou `&P1_QT_PENDENCIAS.` como texto | Item não criado ou nome diferente | Passo 8.3 |
| "Não lido" no meio do resumo | BLOCO 1 antigo (sem mover o "Não lido") | Passo 8.2 |
| Diálogo de feedback não abre | Falta o HTML DOM ID `home_dlg_feedback` | Passo 8.7 |
| "Enviar feedback" não faz nada | Falta a classe `cx-home-fb-enviar` no botão, ou o Ajax Callback `SALVAR_FEEDBACK` | Passos 8.7 e 8.8 |
| Pesquisa sem a arte (bloco cinza) | `home-hero.jpg` não está na raiz do Static Application Files | Passo 8.2 |
| Indicador de pagamento não aparece | Sem holerite liberado (antes do dia 25 do primeiro mês, ou sem geração) | Esperado; confira na p9 |

### Referências reutilizadas (seção 8)

| De onde | O que veio | Adaptação |
|---|---|---|
| `modulos/holerite` (`holerites_de`, `holerite-pagina.js`) | Regra do dia 25 e da admissão; valor oculto com `data-*-original` | Só o último holerite; olho por indicador, sempre oculto ao abrir |
| Página 4 (chat) | Regra de presença: ping há menos de 5 min e `ONLINE` | "Disponível agora" no Meu gestor |
| `PKG_COMUNICADO` | `MARCAR_COMO_LIDO` e `QTD_NAO_LIDOS` | Chamados pelo Ajax `MARCAR_LIDO` e pela computação `P1_NAO_LIDOS` |
| `pkg_ponto_ui` | Ajax com `{ok, mensagem}` e `responder_erro` com o código | `responder`/`responder_erro` no `pkg_home_ui` |
| `docs/ai-context/07` §5 | Modelo sugerido de `FEEDBACK`, `PESQUISA`, `EVENTO`, `CONVERSA_1A1`, `PDI_OBJETIVO`, `CATEGORIA_COMUNICADO` | Nomes no padrão do ponto (`id_`, `ds_`, `dt_`, `dh_`, `st_`, `tp_`, `fl_`) e `id_empresa` em todas |

---

## Situação na app

| Data | O quê | Estado |
|---|---|---|
| 28/10/2026 | Seção 6 (protótipo de 28/10/2026) | Versionada; **não aplicada**: o export de 05/11/2026 (`2964a9d`) não tem carrossel, celebrações nem `home.css` |
| 10/11/2026 | Seção 6 aplicada pelo time (export da página 1 colado na conversa, ainda não no backup) | **Aplicada com 1 erro**: *CSS Classes* da Comunicados com `x-home-carrossel` (falta o `c`), então o carrossel não liga. Resto conferido no export: query com `SELO` e 5 linhas, *Title* com `{if SELO/}`, ação "Ler comunicado" para a p11, Celebrações na região e no diálogo, JS novo (BLOCO 1 e 2, já com o ponto). Diferenças em relação ao guia: *File URLs* `#APP_FILES#modulos/home/home#MIN#.css` (pasta `modulos/home/` em vez da raiz; funciona se os dois arquivos estiverem nela) e o *Type* da ação não aparece no export (confirmar na tela que é **Button**). Falta confirmar qual versão do `pkg_home_ui` e do `home.css` foi instalada. Testes 6.7 não rodados |
| 10/11/2026 | Classe `cx-home-carrossel` corrigida pelo time | Corrigida (export colado) |
| 10/11/2026 | Seção 7 aplicada pelo time (export colado na conversa) | **Aplicada, com 1 ajuste**: `home_comunicados` ficou com `slot: regionBody` na Coluna principal; deve ser `subRegions`, como `suas-pendências` e as regiões da Coluna lateral (o passo 7.2 agora diz o *Slot*). Conferido no export: `htmlDomId` `home_hero`, `home_indicadores` e `home_pendencias`; Coluna principal span 8; Comunicados sem `columnSpan`; Suas pendências com título, `cx-home-card` e as template options do Meu gestor; Ajax Callback `REGISTRAR_MARCACAO` com `@colaborador`. Testes 7.5 não rodados |
| 10/11/2026 | Carrossel com o título escuro e o resumo cortado, visto na app com a conta `teste.rh` | Corrigido no `home.css`/`home.min.css` (título branco no `.a-CardView-header`, degradê mais forte, resumo em 2 linhas). Testado na app só com o CSS injetado no navegador; **falta subir os dois arquivos** |
| 10/11/2026 | Comparação com o protótipo na app (conta `teste.rh`) e seção 8: categoria, "Não lido", 3 indicadores, Feedbacks, Pesquisa, Eventos, 1:1, presença, Dar feedback, Parabenizar | Versionada na branch `feature/home-prototipo-completo`; **não compilada nem aplicada**. Testados na app, com CSS injetado, só o carrossel (título, degradê, resumo, botão e "Não lido"); o visual dos blocos novos não foi testado (a aba foi fechada) |
| 10/11/2026 | Seção 7 (blocos do ponto) e nova versão do `pkg_home_ui`, `home.css`, `home.min.css` e `home-pagina.js` | Versionada na branch `feature/home-ponto-de-hoje`; **não compilada nem aplicada**. Conferido só por leitura: os nomes usados do `pkg_ponto` batem com a especificação, o `home.min.css` foi gerado do `.css` (a parte antiga ficou idêntica à anterior) e o `home-pagina.js` passou no `node --check` |

**Protótipo conferido em 10/11/2026:** o frame "Início" do `corlixhub.pen` (pen.dev) está igual ao `pen_dev/Início.png` de 28/10/2026; não há versão mais nova no repositório.

**Próximo passo:** aplicar a seção 6 e a 7 no Builder, rodar os testes 6.7 e 7.5 com uma conta com colaborador e registrar aqui o resultado.
