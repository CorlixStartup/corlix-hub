# Comunicados · categorias · passo a passo no APEX

Acrescenta a **categoria** aos comunicados, como nos protótipos `pen_dev/Início.png` (etiqueta "Institucional" no carrossel) e `pen_dev/Novo comunicado (diálogo).png` (campo **Categoria \***). Descrição das telas: `docs/ai-context/07-design-pen-dev.md` §4.1 e §4.2.

O carrossel da Home usa a categoria a partir do `modulos/home/Etapas-home.md` §8.

## Arquivos

| Arquivo | O que é |
|---|---|
| `01_ddl_categoria.sql` | Tabela `CATEGORIA_COMUNICADO`, coluna `COMUNICADO.ID_CATEGORIA` (FK) e 7 categorias para cada empresa: Institucional, Eventos, Benefícios, Saúde e bem-estar, Treinamentos, Resultados, Novos colaboradores |
| `02_categoria_demo.sql` | Dá categoria aos 5 comunicados de `modulos/home/dados-demo` |
| `03_ddl_fixado.sql` | Coluna `COMUNICADO.FL_FIXADO` (`S`/`N`) para o "Fixar no topo" |
| `comunicado.css` / `comunicado.min.css` | Visual do diálogo da página 17 (Público em botões, dropzone, Fixar no topo) |
| `instalar.sql` | Instala os três scripts pelo SQLcl |

## 1. Banco

*SQL Workshop › SQL Scripts*: rode `01_ddl_categoria.sql` e depois `02_categoria_demo.sql`. Os dois podem ser rodados de novo.

**Teste:**
```sql
select id_empresa, nm_categoria from categoria_comunicado order by id_empresa, nr_ordem
```

Empresa criada depois: rode o `01` de novo, e ela ganha as 7 categorias.

## 2. Página 17 (Emitir novo comunicado)

**LOV compartilhada.** *Shared Components › List of Values › Create*, **From Scratch**:

| Atributo | Valor |
|---|---|
| Name | `LOV_CATEGORIA_COMUNICADO` |
| Type | **Dynamic** |
| Source › SQL Query | `select nm_categoria d, id_categoria r from categoria_comunicado where id_empresa = :G_ID_EMPRESA and fl_ativo = true order by nr_ordem, nm_categoria` |

**Item.** No Page Designer da página 17, botão direito na região **emitir-comunicado** › **Create Page Item**:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `P17_ID_CATEGORIA` |
| Identification | Type | **Select List** |
| Label | Label | `Categoria` |
| Layout | Sequence | o mesmo do Departamento, logo depois dele |
| Appearance | Template | **Required - Floating** |
| Validation | Value Required | **On** |
| List of Values | Type | **Shared Component** › `LOV_CATEGORIA_COMUNICADO` |
| List of Values | Display Null Value | On, *Null Display Value* `- Selecione -` |
| Source | Form Region | `emitir-comunicado` |
| Source | Column | `ID_CATEGORIA` |
| Source | Data Type | **NUMBER** |

Se *Source › Column* não listar `ID_CATEGORIA`, a região foi carregada antes da coluna existir: em **emitir-comunicado**, clique em *Source › Table Name* e escolha `COMUNICADO` de novo, para o Builder reler as colunas (confirmar no 26.1.5).

**No export** (`p00017-comunicado.apx`): `pageItem P17_ID_CATEGORIA` com `lov { type: sharedComponent  lov: @lov-categoria-comunicado  nullDisplayValue: - Selecione - }`, `validation { valueRequired: true }` e `source { formRegion: @step-1  column: ID_CATEGORIA  dataType: number }`.

## 3. Testar

1. Abra "Novo comunicado": o campo **Categoria** lista as 7 categorias, começando por Institucional.
2. Tente publicar sem categoria: aparece o erro de campo obrigatório.
3. Publique com "Eventos": na Home, o comunicado aparece no carrossel com a etiqueta **Eventos**.

## 4. Página 17 no layout do protótipo

Leva o "Emitir novo comunicado" (assistente de uma etapa) ao diálogo **Novo comunicado** do `pen_dev/Novo comunicado (diálogo).png`. Referência de modal: a **página 31** (Solicitar ajuste), que já usa o template *Modal Dialog*, os botões no rodapé, o Radio Group que mostra e esconde campos e o processo *Close Dialog*.

| Protótipo | Hoje (export de 11/11/2026) | Passo |
|---|---|---|
| Diálogo simples "Novo comunicado", ~900 px | *Wizard Modal Dialog*, título "Emitir novo comunicado", altura fixa de 600 | 4.2 |
| "Campos marcados com * são obrigatórios." | Não existe | 4.3 |
| **Público \***: Todos \| Um departamento, em botões | Só o select de departamento, com "Todos (empresa inteira)" | 4.4 |
| Departamento destinatário \* e Categoria \* lado a lado, com ajuda | Um abaixo do outro, sem ajuda | 4.5 |
| Título \* e Comunicado \* com asterisco e ajuda | "Titulo" sem acento e sem asterisco; Comunicado opcional | 4.6 |
| Imagem (opcional) em área de arrastar, recorte 16:9 | Upload simples, sem recorte | 4.7 |
| Fixar no topo | Não existe (nem a coluna) | 1 e 4.8 |
| Rodapé: Cancelar + **Publicar comunicado** | "Enviar Comunicado" com seta e confirmação | 4.9 |
| O diálogo fecha e a Home atualiza | Não há processo *Close Dialog*: depois de gravar, o diálogo não fecha sozinho | 4.10 |

**"Uma empresa" fica de fora.** No protótipo, o Público tem uma terceira opção, "Uma empresa". Na app, todo comunicado já é da empresa da sessão (`ID_EMPRESA = G_ID_EMPRESA`), e quem não tem empresa (equipe do Corlix Hub) não abre a página. Publicar para outra empresa exige outra regra de acesso, decisão do time. Por isso o guia usa **Todos** (empresa inteira) e **Um departamento**.

### 4.1 Banco e arquivo

1. *SQL Workshop › SQL Scripts*: rode `03_ddl_fixado.sql` (coluna `COMUNICADO.FL_FIXADO`, `'S'`/`'N'`, padrão `'N'`). Pode ser rodado de novo.
2. *Shared Components › Static Application Files › Create File*: envie `comunicado.css` e `comunicado.min.css` com **Directory** `modulos/comunicados`.

**Teste:**
```sql
select fl_fixado, count(*) from comunicado group by fl_fixado
```
Todos os comunicados existentes voltam com `N`.

### 4.2 Página

No nó **Page 17**:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Title | `Novo comunicado` |
| Appearance | Dialog Template | **Modal Dialog** (no lugar de *Wizard Modal Dialog*) |
| Appearance | CSS Classes | `cx-comunicado`. Se preferir pôr nas regiões, ponha nas duas, **Aviso** e **Emitir comunicado**: o aviso fica fora do formulário (o da seção **Appearance**, que vai no `<body>` da página. **Não** use *Dialog › CSS Classes*: essa classe fica na moldura do diálogo, na página de trás, e o CSS não chega nos campos) |
| Dialog | Width | `680` (no protótipo o diálogo ocupa 45% da tela; com 900 ele fica largo demais na app, conferido ao vivo em 12/11/2026) |
| Dialog | Height | apague o `600` (o diálogo cresce com o conteúdo) |
| CSS | File URLs | `#APP_FILES#modulos/comunicados/comunicado#MIN#.css` |

Trocar o template muda os slots disponíveis (o *Modal Dialog* não tem `wizardBody` nem `wizardButtons`):

- Região **Emitir comunicado** (`step-1`): *Layout › Slot* **Content Body**. *Appearance › Template* continua **Blank with Attributes**.
- Região **Buttons**: *Layout › Slot* **Dialog Footer**, como a região **Botões** da página 31. Os botões continuam nos slots **Close** (Cancelar) e **Next** (Publicar).

Se o Page Designer mostrar regiões em "Unused Components" depois da troca, mova cada uma para o slot acima.

### 4.3 Aviso dos campos obrigatórios

Botão direito em **Content Body** › **Create Region** (uma região irmã, antes do formulário; como sub-região ela poderia sair depois dos campos):

| Atributo | Valor |
|---|---|
| Name | `Aviso` |
| Type | **Static Content** |
| Source › HTML Code | `<p class="cx-comunicado__aviso">Campos marcados com * são obrigatórios.</p>` |
| Layout › Slot / Sequence | **Content Body** / `5` (o formulário está no `10`) |
| Appearance › Template | **Blank with Attributes** |

### 4.4 Público

Botão direito em **Emitir comunicado** › **Create Page Item**:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `P17_PUBLICO` |
| Identification | Type | **Radio Group** |
| Label | Label | `Público` |
| Settings | Number of Columns | `2` |
| Layout | Sequence | `8` |
| Appearance | Template | **Required - Floating** |
| Layout | Column CSS Classes | `cx-comunicado__publico` (o `comunicado.css` transforma o rádio nos botões do protótipo; o 26.1.5 não tem *Display as Pill Button* para este item) |
| Validation | Value Required | **On** |
| List of Values | Type | **Static Values**: Display `Todos` / Return `TODOS` e Display `Um departamento` / Return `DEPARTAMENTO` (o retorno em maiúsculas: o padrão, a computação e a Dynamic Action comparam com `TODOS`). No export: `staticValues: STATIC2:Todos;TODOS,Um departamento;DEPARTAMENTO` |
| List of Values | Display Null Value | **Off** |
| Source | Type | **Null** (não é coluna da tabela) |
| Default | Type / Static Value | **Static** / `TODOS` |

**Dynamic Action** (igual à "Tipo de ajuste" da página 31): botão direito em **P17_PUBLICO** › **Create Dynamic Action**.

| Onde | Atributo | Valor |
|---|---|---|
| Ação dinâmica | Name | `Público` |
| When | Event / Item | **Change** / `P17_PUBLICO` |
| Client-side Condition | Type | **Item = Value**, item `P17_PUBLICO`, valor `DEPARTAMENTO` |
| True | Action | **Show**, item `P17_ID_DEPARTAMENTO` (*Fire on Initialization* **On**) |
| False | Action | **Hide**, item `P17_ID_DEPARTAMENTO` (*Fire on Initialization* **On**) |
| Ação dinâmica | Server-side Condition | **nenhuma** (com condição de servidor, a ação nem vai para a página quando o Público começa em "Todos") |

**Validação e limpeza** (em *Processing*):

1. **Validation** `Departamento obrigatório`: Type **Item is NOT NULL**, item `P17_ID_DEPARTAMENTO`; *Error Message* `Escolha o departamento destinatário.`; *Associated Item* `P17_ID_DEPARTAMENTO`; *Server-side Condition* **Item = Value**, `P17_PUBLICO` = `DEPARTAMENTO`.
2. **Computation** (After Submit) em `P17_ID_DEPARTAMENTO`: Type **Static Value** vazio; *Server-side Condition* **Item = Value**, `P17_PUBLICO` = `TODOS`. Assim, quem escolhe departamento e depois volta para "Todos" publica para a empresa inteira.

### 4.5 Departamento e Categoria lado a lado

| Item | Atributo | Valor |
|---|---|---|
| `P17_ID_DEPARTAMENTO` | Label | `Departamento destinatário` |
| | Appearance › Template | **Required - Floating** |
| | List of Values › Null Display Value | **vazio** (Display Null Value continua On). Sem texto, o rótulo "Departamento destinatário" fica dentro do campo até a escolha, como no protótipo |
| | Help › Inline Help Text | `Só esse departamento verá o comunicado.` |
| `P17_ID_CATEGORIA` | Layout › Start New Row | **No** |
| | List of Values › Null Display Value | **vazio**, pelo mesmo motivo |
| | Validation › Value Required | **On** (saiu no export de 11/11/2026) |
| | Help › Inline Help Text | `Tipo do comunicado (ex.: Eventos).` |

Quando o Público é "Todos", o Departamento some e a Categoria fica sozinha na metade esquerda da linha.

### 4.6 Título e Comunicado

| Item | Atributo | Valor |
|---|---|---|
| `P17_TITULO` | Label | `Título` |
| | Appearance › Template | **Required - Floating** |
| | Help › Inline Help Text | `Frase curta e objetiva. Evite escrever tudo em maiúsculas.` |
| `P17_CONTEUDO` | Appearance › Template | **Required - Floating** |
| | Validation › Value Required | **On** |
| | Appearance › Height | `6` |

### 4.7 Imagem

No `P17_IMAGEM`:

| Seção | Atributo | Valor |
|---|---|---|
| Label | Label | `Imagem (opcional)` |
| Display | Display As | **Inline Dropzone** |
| Display | Dropzone Title | `Arraste uma imagem ou clique para selecionar` |
| Display | Dropzone Description | `PNG ou JPG · você poderá recortar em 16:9 após selecionar` |
| Settings | Allow Cropping | **On**, Aspect Ratio **16:9** |
| Settings | Maximum File Size | `5120` (KB) |

O Image Upload **não tem *File Types*** no 26.1.5 (o atributo é só do File Upload, `docs/apex-26.1/02-paginas-formularios-e-itens.md`; na página o APEX gera `accept="image/*"` fixo). Para aceitar só PNG e JPG, crie uma validação em *Processing › Validations*:

| Atributo | Valor |
|---|---|
| Name | `Imagem PNG ou JPG` |
| Type | **Expression** (Language **PL/SQL**) |
| PL/SQL Expression | `regexp_like(:P17_IMAGEM, '\.(png\|jpe?g)$', 'i')` |
| Error Message | `Envie uma imagem PNG ou JPG.` |
| Associated Item | `P17_IMAGEM` |
| Server-side Condition | **Item is NOT NULL**, `P17_IMAGEM` |

(No Builder, digite a barra vertical sem a `\` da tabela: `'\.(png|jpe?g)$'`.)

> **Não use** a consulta em `APEX_APPLICATION_TEMP_FILES` da versão anterior deste guia. O `P17_IMAGEM` grava na coluna `IMAGEM` da tabela (*Storage Type* **BLOB column specified in Item Source attribute**), e com esse tipo o arquivo não passa por `APEX_APPLICATION_TEMP_FILES`: a consulta nunca acha linha e a validação deixa tudo passar. Isso foi comprovado na app em 12/11/2026, quando um GIF chegou ao servidor como `image/gif` e não foi barrado. A expressão acima confere a extensão do nome do arquivo, que é o valor do item, e funciona com qualquer *Storage Type*. Ela não lê o conteúdo: um GIF renomeado para `.png` passa.

Teste com um PNG (tem que passar) e com um GIF (tem que aparecer "Envie uma imagem PNG ou JPG."). Se o PNG também for barrado, o valor do item não termina no nome do arquivo: avise para trocarmos a regra.

Os nomes seguem a doc do 26.1 (`docs/apex-26.1/02-paginas-formularios-e-itens.md`, File Upload e Image Upload); a posição exata no Property Editor: confirmar no 26.1.5.

### 4.8 Fixar no topo

Botão direito em **Emitir comunicado** › **Create Page Item**:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `P17_FL_FIXADO` |
| Identification | Type | **Checkbox** |
| Label | Label | `Fixar no topo` |
| Settings | Use Defaults | **Off**; Checked Value `S` (letra S, não o número 5), Unchecked Value `N` |
| Validation | Value Required | **Off** (num checkbox, obrigatório quer dizer "tem que marcar") |
| Layout | Sequence | `70` |
| Appearance | Template | **Optional - Floating** |
| Layout | Column CSS Classes | `cx-comunicado__fixar` (não use *Advanced › CSS Classes*, que vai só no `<input>`) |
| Help | Inline Help Text | `Aparece primeiro na lista de comunicados.` |
| Source | Form Region / Column / Data Type | `Emitir comunicado` / `FL_FIXADO` / **VARCHAR2** |
| Default | Type / Static Value | **Static** / `N` |

Se *Column* não listar `FL_FIXADO`, escolha de novo `COMUNICADO` em *Source › Table Name* da região (igual ao `ID_CATEGORIA`, §2).

> O "Fixar no topo" fica disponível para todo publicador. Se o time quiser restringir ao RH, ponha *Security › Authorization Scheme* `ADMIN_RH` no item.

### 4.9 Botões

| Botão | Atributo | Valor |
|---|---|---|
| **cancel** | sem mudança | já fecha com *Cancel Dialog* |
| **next** | Label | `Publicar comunicado` |
| | Appearance › Button Template | **Text** (sem ícone); *Hot* **On** |
| | Appearance › Template Options | **Use Template Defaults** (tira o `t-Button--iconRight`) |
| | Appearance › Icon | apague o `fa-chevron-right` |
| | Behavior › Requires Confirmation | **Off** (o protótipo não pede confirmação) |

### 4.10 Fechar o diálogo e data local

1. Em *Processing*, botão direito › **Create Process** depois do `processo-emissao-comunicado`: Name `Fechar`, Type **Close Dialog**, Sequence `20`, *Server-side Condition › When Button Pressed* `next`, *Success Message* `Comunicado publicado.`. É o mesmo processo `fechar` da página 31. Ao fechar, a Home já atualiza o carrossel (Dynamic Action **Atualizar comunicados**, `apexafterclosedialog`).
2. Mensagem de sucesso: no processo `processo-emissao-comunicado`, *Success Message* `Comunicado publicado.`; no processo `Fechar`, apague a *Success Message*. Com a mensagem só no `Fechar` e o processo do formulário sem mensagem, o APEX completa com a padrão dele e a Home mostra "Row created. Comunicado publicado." (visto na app em 12/11/2026). Depois de trocar, publique um teste e confira se aparece só "Comunicado publicado." (confirmar no 26.1.5).
3. No `P17_DATA_PUBLICACAO`, *Default › PL/SQL Expression*: troque `SYSDATE` por `cast(systimestamp at time zone 'America/Sao_Paulo' as date)`. O banco está em UTC: um comunicado publicado às 22h aparecia com a data do dia seguinte. **Limite:** a hora não é gravada. O formato de data da app é `DS` (só a data), e o valor de um item *Hidden* passa por esse formato, então todo comunicado publicado pela página fica com `00:00` (o 22, o 2 e o teste de 12/11/2026). Hoje não aparece na tela, porque a Home mostra só o dia e desempata pelo `id_comunicado`. Se o time quiser a hora, a correção é no banco: um `default on null` na coluna com a mesma expressão e *Source › Query Only* **On** no `P17_DATA_PUBLICACAO`, ainda não escrita nem testada.

**No export** (`p00017-comunicado.apx`, depois do próximo backup), procure: `dialogTemplate: @/modal-dialog`; `fileUrls: #APP_FILES#modulos/comunicados/comunicado#MIN#.css`; a região `buttons` com `slot: dialogFooter`; `pageItem P17_PUBLICO` com `type: radioGroup`; `pageItem P17_FL_FIXADO` com `column: FL_FIXADO`; `valueRequired: true` em `P17_ID_CATEGORIA` e `P17_CONTEUDO`; e um `process` com `type: closeDialog`.

Checklist lido pelo validador de exports (skill `fechar-task`, `.claude/skills/fechar-task/`). Cada linha é `componente | texto que a linha do export deve conter`, `!` para "não pode conter":

```export-check
pagina: 17
# 4.2 Página
page 17 | title: Novo comunicado
page 17 | dialogTemplate: @/modal-dialog
page 17 | width: 680
page 17 | fileUrls: #APP_FILES#modulos/comunicados/comunicado#MIN#.css
region buttons | slot: dialogFooter
region step-1 | cssClasses: cx-comunicado
# 4.3 Aviso
region aviso | cx-comunicado__aviso
region aviso | sequence: 5
region aviso | slot: contentBody
region aviso | cssClasses: cx-comunicado
# 4.4 Público
pageItem P17_PUBLICO | type: radioGroup
pageItem P17_PUBLICO | staticValues: STATIC:Todos;TODOS,Um departamento;DEPARTAMENTO
pageItem P17_PUBLICO | columnCssClasses: cx-comunicado__publico
pageItem P17_PUBLICO | staticValue: TODOS
pageItem P17_PUBLICO | valueRequired: true
dynamicAction público | value: DEPARTAMENTO
dynamicAction público | action: hide
dynamicAction público | action: show
dynamicAction público | !serverSideCondition
validation departamento-obrigatório | item: P17_ID_DEPARTAMENTO
validation departamento-obrigatório | errorMessage: Escolha o departamento destinatário.
computation p17-id-departamento | value: TODOS
# 4.5 Departamento e Categoria
pageItem P17_ID_DEPARTAMENTO | !nullDisplayValue
pageItem P17_ID_CATEGORIA | !nullDisplayValue
pageItem P17_ID_CATEGORIA | startNewRow: false
pageItem P17_ID_CATEGORIA | valueRequired: true
pageItem P17_ID_CATEGORIA | column: ID_CATEGORIA
# 4.6 Título e Comunicado
pageItem P17_TITULO | valueRequired: true
pageItem P17_CONTEUDO | valueRequired: true
# 4.7 Imagem
pageItem P17_IMAGEM | displayAs: inlineDropzone
pageItem P17_IMAGEM | aspectRatio: widescreen
pageItem P17_IMAGEM | maxFileSize: 5120
validation imagem-png-ou-jpg | regexp_like(:P17_IMAGEM, '\.(png|jpe?g)$', 'i')
validation imagem-png-ou-jpg | !apex_application_temp_files
validation imagem-png-ou-jpg | errorMessage: Envie uma imagem PNG ou JPG.
# 4.8 Fixar no topo
pageItem P17_FL_FIXADO | checkedValue: S
pageItem P17_FL_FIXADO | uncheckedValue: N
pageItem P17_FL_FIXADO | !valueRequired: true
pageItem P17_FL_FIXADO | columnCssClasses: cx-comunicado__fixar
pageItem P17_FL_FIXADO | column: FL_FIXADO
# 4.9 Botões
button next | label: Publicar comunicado
button next | !fa-chevron-right
button next | !confirm
# 4.10 Fechar e data local
process fechar | type: closeDialog
process fechar | !successMessage
process fechar | whenButtonPressed: @next
process processo-emissao-comunicado | successMessage: Comunicado publicado.
pageItem P17_DATA_PUBLICACAO | America/Sao_Paulo
```

### 4.11 Home: fixados primeiro

No `modulos/home/Etapas-home.md` §8.4, a consulta da região **Comunicados** já ordena os fixados primeiro (`order by case c.fl_fixado when 'S' then 0 else 1 end, ...`). Por isso o §8.1 da Home pede o `03_ddl_fixado.sql` antes.

## 5. Testar o diálogo

1. Na Home, clique em **Novo comunicado**: abre o diálogo "Novo comunicado", sem as etapas do assistente, com "Todos" marcado em fundo escuro e com ✓.
2. Com "Todos", o campo Departamento não aparece. Marque "Um departamento": ele aparece ao lado da Categoria.
3. Clique em **Publicar comunicado** sem preencher nada: erros em Categoria, Título e Comunicado. Com "Um departamento" e sem departamento: "Escolha o departamento destinatário."
4. Escolha uma imagem: abre o recorte em 16:9.
5. Publique com "Todos", "Eventos" e **Fixar no topo**: o diálogo fecha, aparece "Comunicado publicado." e o comunicado entra primeiro no carrossel, com a etiqueta **Eventos** e "Para: Todos".
6. No banco: `select titulo, id_departamento, id_categoria, fl_fixado, data_publicacao from comunicado order by id_comunicado desc fetch first 1 rows only` volta `id_departamento` vazio, a categoria, `S` e a hora local.

## Se não funcionar

| Sintoma | Causa provável | Correção |
|---|---|---|
| Departamento sempre visível | Ação *False* da Dynamic Action com **Show** em vez de **Hide**, ou *Server-side Condition* na Dynamic Action | §4.4 |
| Nenhuma opção marcada no Público, e o departamento não é limpo | Retorno `Todos` em vez de `TODOS` na LOV estática | §4.4 |
| Não acha *File Types* no `P17_IMAGEM` | O Image Upload do 26.1.5 não tem esse atributo | Validação `Imagem PNG ou JPG` (§4.7) |
| GIF aceito, sem a mensagem "Envie uma imagem PNG ou JPG." | Validação com a consulta em `APEX_APPLICATION_TEMP_FILES`: com *Storage Type* BLOB column o arquivo não passa por essa tabela | Troque pela expressão de extensão (§4.7) |
| PNG ou JPG barrado com "Envie uma imagem PNG ou JPG." | O valor do item não termina no nome do arquivo | Avise o agente com o export; a regra do §4.7 precisa mudar |
| Mensagem "Row created. Comunicado publicado." depois de publicar | *Success Message* no `Fechar` e o processo do formulário sem mensagem: o APEX acrescenta a padrão | §4.10, passo 2 |
| Comunicado gravado com hora `00:00` | Formato de data da app `DS` aplicado ao item *Hidden* `P17_DATA_PUBLICACAO` | Limite conhecido, §4.10 passo 3 |
| `ORA-02290: check constraint (CK_COM_FIXADO) violated` ao fixar | *Checked Value* diferente de `S` (ex.: `5`) | §4.8 |
| Diálogo continua com as etapas do assistente | *Dialog Template* ainda é *Wizard Modal Dialog* | §4.2 |
| Público aparece como bolinhas de rádio | Falta `cx-comunicado__publico` em *Column CSS Classes* do `P17_PUBLICO`, ou o `comunicado.css` novo não foi enviado | §4.4 e §4.1 |
| Público em botões, mas sem o fundo escuro e o ✓ | `comunicado.css` não carregou, ou falta `cx-comunicado` em *Page › CSS Classes* | §4.1 e §4.2 |
| Diálogo não fecha depois de publicar | Falta o processo *Close Dialog* | §4.10 |
| `ORA-00904: "FL_FIXADO"` ao abrir ou publicar, ou na Home | `03_ddl_fixado.sql` não rodou | §4.1 |
| Lista de categorias vazia | `01_ddl_categoria.sql` não rodou, ou a empresa foi criada depois dele | Rode o `01` de novo |
| Comunicado publicado sem etiqueta na Home, e `ID_CATEGORIA` vazio na tabela | Item sem *Source* (no export, `P17_ID_CATEGORIA` sem o bloco `source`): o valor é validado, mas não é gravado | §2, *Source › Form Region* `emitir-comunicado`, *Column* `ID_CATEGORIA`, *Data Type* **NUMBER** |
| Publica sem categoria, mesmo com o asterisco no campo | *Value Required* desligado: o template **Required - Floating** só desenha o asterisco, não obriga | §2, *Validation › Value Required* **On** |
| `ORA-00904: "ID_CATEGORIA"` ao publicar | Item criado antes da coluna existir | §1, depois recarregue as colunas da região (§2) |

## Situação

| Data | Estado |
|---|---|
| 10/11/2026 | Versionado na branch `feature/home-prototipo-completo`; **não executado nem aplicado** |
| 11/11/2026 | LOV e item `P17_ID_CATEGORIA` aplicados (export colado no chat). **Falta o *Source* do item**: sem ele a categoria não é gravada. Também falta acertar a sequência (todos os itens estão em 10 e a Categoria em 20, então ela cai no fim do formulário) |
| 11/11/2026 (2º export) | *Source* `ID_CATEGORIA` e sequências (Departamento 10, Categoria 20, Título 30, Comunicado 40, Imagem 60) corrigidos. **O *Value Required* da Categoria saiu** (o export não tem mais `validation { valueRequired: true }`): precisa ser ligado de novo. Teste de publicação ainda não feito |
| 11/11/2026 | §4 (diálogo no layout do protótipo, "Fixar no topo", fechar o diálogo, data local) versionado na branch `feature/comunicado-modal-prototipo`; **não aplicado nem testado** |
| 11/11/2026 (export do §4) | Aplicados: Modal Dialog 900, CSS da página, aviso, rodapé, ajudas, Categoria obrigatória, dropzone com recorte 16:9, validação e computação do departamento, botão sem confirmação. **A corrigir:** classe `cx-comunicado` em *Dialog* (vai em *Appearance*); `P17_PUBLICO` com retorno `Todos` e sem *Pill Button*; Dynamic Action com Show nas duas ações e com condição de servidor; `P17_FL_FIXADO` com Checked Value `5` e obrigatório; falta o *Close Dialog* (4.10), a data local e os *File Types* da imagem; título da página e rótulo do botão. Não testado |
| 12/11/2026 (2º export do §4) | Corrigidos: Checked Value `S` e checkbox opcional, Column CSS Classes do Fixar, retorno `TODOS`, Dynamic Action (Hide e sem condição de servidor), rótulo do botão. `cx-comunicado` foi para a região do formulário (vale para os campos; o Aviso fica sem o estilo). **Ainda faltam:** *Display as Pill Button* no Público, processo *Close Dialog* (4.10), data local, *File Types* da imagem e o *Title* da página. Não testado |
| 12/11/2026 | O 26.1.5 não oferece *Display as Pill Button* no Radio Group (informado pelo time). O controle segmentado passou para o `comunicado.css` (classe `cx-comunicado__publico` no item). CSS escrito sobre a marcação padrão do APEX, ainda não conferido na app |
| 12/11/2026 (teste visual) | O CSS novo foi testado ao vivo no diálogo da app, injetado só na aba do agente (conta `teste.rh`, sem gravar nada): Público em botões com ✓ nos dois estados, Departamento some com a coluna e a Categoria sobe para a esquerda, `*` vermelho nos obrigatórios no lugar do texto "Required", ícone na área da imagem, ajuda do Fixar ao lado da caixa. Vale depois de enviar o `comunicado.css`/`.min.css` novos e pôr `cx-comunicado__publico` no `P17_PUBLICO`. O aviso no topo só ganha o estilo com `cx-comunicado` na região **Aviso** |
| 12/11/2026 (2º teste visual) | Comparado lado a lado com o protótipo, ao vivo e só na aba do agente: diálogo de 680 px, Null Display Value vazio nos dois selects (rótulo dentro do campo), seta fina, ajudas em cinza, sem a marca vermelha no canto, rótulos de Público e Imagem em semibold, borda do Público justa e ajuda do Fixar ao lado. Diferenças que ficam: "Uma empresa" (decisão do time) e o ícone da área da imagem (o do APEX, não o "image-plus") |
| 12/11/2026 (3º export do §4) | Aplicados: Width 680, Title "Novo comunicado", Null Display Value vazio nos dois selects, `cx-comunicado__publico`, classe no Aviso, processo *Close Dialog* `Fechar`. **Ainda faltam:** data local no `P17_DATA_PUBLICACAO` (segue `SYSDATE;`), *File Types* da imagem (`accept` segue `image/*`) e tirar a *Success Message* do `processo-emissao-comunicado`. Conferência visual pendente: a sessão do agente expirou e o login é feito pela pessoa |
| 12/11/2026 | Corrigido o §4.7: *File Types* não existe no Image Upload do 26.1.5 (apontado pelo time e confirmado na doc). Trocado por uma validação do MIME type em `APEX_APPLICATION_TEMP_FILES`, não testada |
| 12/11/2026 (4º export do §4) | Aplicados: data local no `P17_DATA_PUBLICACAO` e validação `Imagem PNG ou JPG`. **Falta só** apagar a *Success Message* do `processo-emissao-comunicado` (segue "Comunicado Publicado com Sucesso!"). Testes da §5 ainda não feitos |
| 12/11/2026 (conferência visual na app) | Com os arquivos e o export publicados, o diálogo abre igual ao protótipo (conta `teste.rh`, sem publicar): título "Novo comunicado", 680 px, CSS carregado, selects com o rótulo dentro do campo, Público em botões com ✓; com "Um departamento", Departamento e Categoria lado a lado. Pendentes: apagar a *Success Message* do processo do formulário e os testes de publicação da §5 |
| 12/11/2026 (5º export do §4) | **§4 aplicado por inteiro** pelo export: sem a *Success Message* no `processo-emissao-comunicado`; só o `Fechar` mostra "Comunicado publicado.". Falta rodar os testes de publicação da §5 (gravam dados; ficam com o time) |
| 12/11/2026 (testes da §5, sem gravar) | Feitos pelo agente na app (conta `teste.rh`), com envios que o servidor recusa e o diálogo fechado em Cancelar: **1** e **2** ok (Público e Departamento); **3** ok (erros em Categoria, Título e Comunicado; com "Um departamento" o servidor devolve "Escolha o departamento destinatário."); **4** ok (o recorte abre em 16:9). **Falha:** um GIF de 640×360 chegou ao servidor como `image/gif` e não foi barrado, porque a validação `Imagem PNG ou JPG` consultava `APEX_APPLICATION_TEMP_FILES` e o item grava direto na coluna BLOB. §4.7 corrigido (expressão sobre a extensão), **falta aplicar e testar de novo**. Detalhe visto: as mensagens padrão ("… must have some value", "Crop Image") estão em inglês. Os passos **5** e **6** (publicar e conferir no banco) não foram feitos: aguardam a confirmação do texto de teste |
| 12/11/2026 (6º export) | Validação `Imagem PNG ou JPG` trocada pela expressão de extensão do §4.7. A expressão ficou com `;` no fim (`…'i');`), que o APEX pode recusar ao executar. **Reteste com PNG e GIF não feito**: o envio pelo agente foi bloqueado pela permissão do ambiente e aguarda autorização do time |
| 12/11/2026 (reteste da imagem) | Autorizado pelo time e feito pelo agente sem gravar (Comunicado vazio, diálogo fechado em Cancelar): **PNG** recortado em 16:9 passa sem erro de imagem (e o `;` no fim da expressão não deu erro de execução); **GIF** é barrado com "Envie uma imagem PNG ou JPG.". Validação ok. Faltam os passos **5** e **6** da §5 (publicar e conferir no banco), que aguardam a confirmação do texto de teste |
| 12/11/2026 (7º export, validador) | Mesmo export do reteste, conferido pelo validador `fechar-task` contra o bloco `export-check` do §4.10: **48/48 regras ok**. Para conferir que o validador pega erros, rodamos uma cópia com Width 900, Checked Value `5` e a consulta em `APEX_APPLICATION_TEMP_FILES`, e ele acusou as 4 regras certas. **Fechamento:** export e testes sem gravar ok. A tarefa só fecha depois dos passos **5** e **6** da §5 (publicar e conferir no banco), que gravam dados e esperam o time. Opcional: tirar o `;` do fim da expressão da validação de imagem |
| 12/11/2026 (publicação de teste, passos 5 e 6) | Autorizado pelo time e feito pelo agente (conta `teste.rh`): "Teste de publicação · ignorar", Todos, Eventos e Fixar no topo. O diálogo fechou, o carrossel atualizou e o teste entrou primeiro, com Eventos, "Para: Todos · 12 de novembro" e "Não lido". No banco (id 81): `id_departamento` vazio, `id_categoria` 5, `fl_fixado` S, empresa 1, data 12/11/2026 (dia certo às 22:58 de Brasília). **Achados:** (1) a mensagem saiu "Row created. Comunicado publicado.", corrigido no §4.10 passo 2 e falta aplicar; (2) a hora foi gravada como `00:00`, limite que já existia e está registrado no §4.10 passo 3. A ordem dos fixados não pôde ser conferida, porque o teste também era o mais novo (fica para a §8.4 da Home). O comunicado 81 foi apagado em seguida, a pedido do time (`delete ... where id_comunicado = 81 and titulo = ...`, 1 linha; as leituras foram junto por cascade); a conferência deu 0 linhas em `comunicado` e em `comunicado_leitura`. **Para fechar:** aplicar a troca da mensagem, colar o export e publicar mais um teste |
| 12/11/2026 (8º export, validador) | Validador `fechar-task`: **48/48 regras ok**. A única mudança desde o 7º export é a troca do §4.10, passo 2 (*Success Message* `Comunicado publicado.` no `processo-emissao-comunicado` e nenhuma no `Fechar`). Nada mais mudou; o `;` no fim da expressão da validação de imagem segue lá (sem efeito). **Fechamento:** falta só publicar um teste para ver se a Home mostra apenas "Comunicado publicado." (sem o "Row created."), e apagá-lo depois |
| 12/11/2026 (fechamento) | Publicação de teste autorizada pelo time e feita pelo agente (conta `teste.rh`), com o export 48/48: a Home mostrou **só "Comunicado publicado."** (sem o "Row created."). No banco (id 82): departamento vazio, categoria 5, `S`, data 12/11/2026 `00:00` (o limite conhecido do §4.10, passo 3). O comunicado 82 foi apagado em seguida, a pedido do time; a conferência deu 0 linhas em `comunicado` e em `comunicado_leitura`. **Página 17 concluída:** §4 aplicado, export validado e todos os testes da §5 feitos. Ficam fora desta tarefa: a hora `00:00` (melhoria opcional, §4.10 passo 3), "Uma empresa" no Público (decisão do time) e a ordem dos fixados na Home (§8.4 do `Etapas-home.md`) |
| 13/11/2026 (validação em DEV) | `corlixhub/pages/p00017-comunicado.apx` no backup `84f8625` (13/11/2026 09:52) é idêntico ao 8º export: **48/48 regras**. `comunicado.css` igual ao do módulo; `comunicado.min.css` com o mesmo conteúdo (só muda a formatação do minificador). Página 17 concluída em DEV; segue o `;` opcional no fim da expressão da validação de imagem |
