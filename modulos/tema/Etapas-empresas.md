# Empresas · passo a passo no APEX

Este guia deixa a página 15 (Empresas Cadastradas) igual ao protótipo `pen_dev/Empresas.png`, no App Builder do **APEX 26.1.5**. A descrição da tela está em `docs/ai-context/07-design-pen-dev.md` §4.7.

Como nos outros guias do tema, a mudança é feita no Builder. O backup diário traz o resultado para `corlixhub/pages/p00015-empresas-cadastradas.apx` na `DEV`; editar só o `.apx` do repositório não muda o app e é desfeito no próximo backup.

Passos marcados com **(confirmar no 26.1.5)** ainda não foram conferidos na tela desta versão. Se o caminho não existir, tire um print da árvore e do painel de propriedades e registre o caminho certo neste guia.

### O que muda

| Antes | Depois (protótipo) |
|---|---|
| Título "Empresas Cadastradas" na Title Bar (breadcrumb) | Faixa branca com título "Empresas", descrição e botão **+ Nova empresa** à direita |
| Botão "Cadastrar" ao lado da barra de pesquisa | Botão **+ Nova empresa** no cabeçalho |
| Relatório sobre a tabela `EMPRESA`, com as 14 colunas visíveis | Sete colunas: **Nome fantasia** (link), **Razão social**, **CNPJ**, **Cidade/UF**, **E-mail corporativo**, **Telefone**, **Status**. Endereço, CEP e data de abertura ficam em *Ações › Colunas* |
| Status "Yes"/"No" (LOV `BOOLEAN`) | Badge "Ativa" (verde) / "Inativa" (cinza) |
| Ordem das colunas do assistente, sem ordenação | Ordenado por Nome fantasia |
| Paginação "1 - 1" e mensagens em inglês | "1 – 1 de 1" e mensagens em pt-BR |
| Página sem autorização (só o menu exige `EQUIPE_CORLIX_HUB`) | Página com a mesma autorização do menu |

O modal de cadastro (página 16) e a gravação não mudam.

### Fica de fora

- Os textos da barra do Interactive Report seguem o idioma do app. Hoje ele é `en`, então aparecem "Search", "Go", "Actions" e "1 - 1 of 1" em vez de "Pesquisar", "Ir", "Ações" e "1 – 1 de 1". Traduzir é configuração do app, não deste guia.
- Formatar o CNPJ: a coluna mostra o que está gravado. A máscara é do cadastro (página 16).

---

## 1. CSS

Suba em *Shared Components › Static Application Files* os dois arquivos, substituindo os atuais:

- `corlixhub/shared-components/static-files/custom.css`
- `corlixhub/shared-components/static-files/custom.min.css`

O que entrou (seção 15 do `custom.css`):
- `.cx-cabecalho-pagina--acoes` (com `__texto` e `__acoes`): o mesmo cabeçalho da página 14, com os botões à direita.
- `.cx-relatorio` (com `__nota`): Interactive Report em card, com a barra de pesquisa e o cabeçalho da tabela separados por borda, link da linha em negrito e a nota do rodapé.

## 2. Página

Abra a página 15 no Page Designer e selecione o nó da página (**Page 15: Empresas Cadastradas**):

- *Identification › Title*: `Empresas`
- *Security › Authorization Scheme*: **EQUIPE_CORLIX_HUB** (a mesma da entrada "Empresas" do menu; regra 8 do `docs/ai-context/08`)

Faça o mesmo *Authorization Scheme* na página 16: pela URL, qualquer usuário logado abre o modal hoje.

## 3. Cabeçalho

### 3.1 Apagar o breadcrumb

Na árvore *Rendering*, clique com o botão direito em **Breadcrumb** (slot Breadcrumb Bar) › **Delete**.

### 3.2 Criar o cabeçalho

1. Clique com o botão direito em **Breadcrumb Bar** › **Create Region** (confirmar no 26.1.5).
2. Propriedades:
   - *Identification › Name*: `Cabeçalho`
   - *Identification › Type*: **Dynamic Content**
   - *Source › Language*: PL/SQL; *PL/SQL Function Body returning a CLOB*:
     ```plsql
     return '<div class="cx-cabecalho-pagina cx-cabecalho-pagina--acoes">'
         || '<div class="cx-cabecalho-pagina__texto">'
         || '<h1 class="cx-cabecalho-pagina__titulo">Empresas</h1>'
         || '<p class="cx-cabecalho-pagina__descricao">Consulte e mantenha as empresas cadastradas no CorlixHub.</p>'
         || '</div>'
         || '<div class="cx-cabecalho-pagina__acoes">'
         || '<a class="t-Button t-Button--hot t-Button--iconLeft" href="'
         || apex_escape.html_attribute(apex_page.get_url(p_page => 16, p_clear_cache => '16'))
         || '"><span class="t-Icon t-Icon--left fa fa-plus" aria-hidden="true"></span>'
         || '<span class="t-Button-label">Nova empresa</span></a>'
         || '</div>'
         || '</div>';
     ```
   - *Appearance › Template*: **Blank with Attributes (No Grid)**

Como a página 16 é modal, o `apex_page.get_url` devolve um link `javascript:apex.navigation.dialog(...)` com checksum, e o modal abre como pelo botão antigo.

**Confira:** no export, a região fica com `slot: breadcrumbBar` e `template: @/blank-with-attributes-no-grid`, como `cabeçalho` em `p00029-busca.apx`.

### 3.3 Apagar o botão antigo

Clique com o botão direito no botão **CREATE** ("Cadastrar", na região Empresas Cadastradas) › **Delete**.

### 3.4 Atualizar o relatório depois do modal

O botão novo fica fora do relatório, então o evento de fechar o modal não chega mais à região. Selecione a dynamic action **Edit Report - Dialog Closed** (*Dynamic Actions › Dialog Closed*):

- *When › Selection Type*: **JavaScript Expression**
- *When › JavaScript Expression*: `document`

O evento `apexafterclosedialog` sobe até o `document` tanto pelo botão **Nova empresa** quanto pelo lápis e pelo link do relatório. A ação *Refresh* da região não muda.

## 4. Relatório

Selecione a região **Empresas Cadastradas**.

### 4.1 Fonte

- *Identification › Title*: `Empresas`
- *Source › Type*: **SQL Query**
- *Source › SQL Query*:
  ```sql
  select e.id_empresa,
         e.nome_fantasia,
         e.nome,
         e.cnpj,
         e.cidade || case when e.uf is not null then ' – ' || e.uf end as cidade_uf,
         e.email_corporativo,
         case
           when regexp_like(e.telefone, '^\d{11}$') then regexp_replace(e.telefone, '^(\d{2})(\d{5})(\d{4})$', '(\1) \2-\3')
           when regexp_like(e.telefone, '^\d{10}$') then regexp_replace(e.telefone, '^(\d{2})(\d{4})(\d{4})$', '(\1) \2-\3')
           else e.telefone
         end as telefone,
         case when e.status then 'Ativa' else 'Inativa' end as situacao,
         case when e.status then 'sucesso' else 'neutro' end as situacao_classe,
         e.cep,
         e.logradouro,
         e.numero,
         e.complemento,
         e.bairro,
         e.data_criacao
    from empresa e
  ```

A lista mostra todas as empresas, sem filtro por `id_empresa`: é a tela de administração da plataforma (`docs/ai-context/02` §Página 15). `STATUS` é `BOOLEAN` (Oracle 23ai), por isso o `case when e.status`. O telefone é gravado só com dígitos (`11987651234`); a query mostra `(11) 98765-1234` (celular, 11 dígitos) ou `(11) 3456-7890` (fixo, 10 dígitos) e deixa como está o que vier em outro formato.

Ao salvar, o Builder cria as colunas `CIDADE_UF`, `SITUACAO` e `SITUACAO_CLASSE` e remove `STATUS`, `CIDADE` e `UF`.

### 4.2 Colunas

Selecione cada coluna em *Columns* e ajuste:

| Coluna | Type | Heading | Outras propriedades |
|---|---|---|---|
| `ID_EMPRESA` | Hidden | — | — |
| `NOME_FANTASIA` | **Link** | `Nome fantasia` | *Link › Target*: Page `16`, *Set Items* `P16_ID_EMPRESA` = `#ID_EMPRESA#`, *Clear Cache* `16`; *Link Text*: `#NOME_FANTASIA#` |
| `NOME` | Plain Text | `Razão social` | — |
| `CNPJ` | Plain Text | `CNPJ` | — |
| `CIDADE_UF` | Plain Text | `Cidade/UF` | — |
| `EMAIL_CORPORATIVO` | Plain Text | `E-mail corporativo` | — |
| `TELEFONE` | Plain Text | `Telefone` | — |
| `SITUACAO` | Plain Text | `Status` | *Column Formatting › HTML Expression*: `<span class="cx-badge cx-badge--#SITUACAO_CLASSE#">#SITUACAO#</span>` |
| `SITUACAO_CLASSE` | Hidden | — | — |
| `CEP` | Plain Text | `CEP` | — |
| `LOGRADOURO` | Plain Text | `Logradouro` | — |
| `NUMERO` | Plain Text | `Número` | — |
| `COMPLEMENTO` | Plain Text | `Complemento` | — |
| `BAIRRO` | Plain Text | `Bairro` | — |
| `DATA_CRIACAO` | Plain Text | `Data de abertura` | *Appearance › Format Mask*: `DD/MM/YYYY` |

O texto do badge vem da query (`Ativa`/`Inativa`) e não precisa de escape. A cor sai do `.cx-badge--sucesso`/`--neutro` do `corlix-tema.css`.

### 4.3 Ícone de edição

Ainda na região, em *Attributes* do relatório (o nó **Attributes** abaixo da região na árvore; confirmar no 26.1.5):

- *Link › Link Icon*: `<span role="img" aria-label="Editar" class="fa fa-pencil" title="Editar"></span>`

O destino (página 16 com `P16_ID_EMPRESA`) não muda.

### 4.4 Aparência, paginação e mensagens

Na região:
- *Appearance › CSS Classes*: `cx-relatorio`
- *Header and Footer › Footer Text*: `<p class="cx-relatorio__nota">Endereço completo, CEP e data de abertura: Ações › Colunas</p>`

  A nota fica em pt-BR, como no protótipo, porque o produto é para o mercado nacional. Enquanto o idioma do app for `en`, a barra mostra "Actions" e "Columns"; a nota passa a bater com o menu quando o app for traduzido.

No nó **Attributes** do relatório:
- *Pagination › Type*: **Row Ranges X to Y of Z**
- *Messages › When No Data Found*: `Nenhuma empresa cadastrada.`
- *Messages › When More Data Found*: `A lista passou de #MAX_ROW_COUNT# linhas. Use a pesquisa para filtrar.`

Salve a página (*Save*).

## 5. Relatório padrão

As colunas visíveis e a ordem do relatório ficam no relatório salvo *Primary*, que se ajusta rodando a página como desenvolvedor:

1. Rode a página 15.
2. *Ações › Colunas*: deixe em **Exibir na tabela**, nesta ordem: Nome fantasia, Razão social, CNPJ, Cidade/UF, E-mail corporativo, Telefone, Status. Passe CEP, Logradouro, Número, Complemento, Bairro e Data de abertura para **Não exibir**. *Aplicar*.
3. Clique no cabeçalho **Nome fantasia** › ordenar crescente.
4. *Ações › Relatório › Salvar relatório*: *Salvar* **Como configurações padrão do relatório**, tipo **Primário** (em inglês: *Actions › Report › Save Report › As Default Report Settings › Primary*).

**Confira:** no export, o `savedReport primary` passa a ter só as sete colunas em `displayColumn` e a ordenação por `NOME_FANTASIA`.

## 6. Teste

Recarregue com **Ctrl+Shift+R** (Cmd+Shift+R no Mac) e confira:

1. Faixa branca com "Empresas", a descrição e o botão escuro **+ Nova empresa** à direita; sem breadcrumb.
2. Relatório num card com borda, a barra de pesquisa em cima e o cabeçalho da tabela em cinza-claro.
3. Nome fantasia em azul e negrito; Status com badge "Ativa" verde.
4. Telefone com máscara, como "(11) 98765-1234".
5. Embaixo, a nota "Endereço completo, CEP e data de abertura: Ações › Colunas" e a paginação ("1 - 1 of 1" enquanto o app estiver em `en`).
6. **+ Nova empresa** abre o modal vazio; ao salvar, o relatório atualiza sozinho. O mesmo vale para o lápis e para o Nome fantasia.
7. Com um usuário fora da equipe do Corlix Hub, abrir a página 15 pela URL dá "Acesso restrito à equipe do Corlix Hub."

## 7. Ajustes depois do teste na página (26/10/2026)

Se você já aplicou o guia antes deste ajuste, faça só isto na região **Empresas Cadastradas** e salve:

- *Source › SQL Query*: troque a linha `e.telefone,` pelo `case ... end as telefone,` do passo 4.1. A coluna continua se chamando `TELEFONE`, então o relatório salvo não muda.

**Confira:** a linha da Corlix mostra "(11) 98765-1234".

A nota do rodapé continua "Ações › Colunas" mesmo com a barra em inglês: o foco do produto é o mercado nacional, e o texto passa a bater com o menu quando o app for para pt-BR.

## Se não funcionar

| Sintoma | Causa | Correção |
|---|---|---|
| O relatório não atualiza depois de salvar no modal | A DA ainda escuta a região, e o botão novo está fora dela | Passo 3.4: *Selection Type* **JavaScript Expression**, `document` |
| O botão abre a página 16 inteira, fora do modal | `p_plain_url => true` no `get_url`, ou link montado à mão | Use o `apex_page.get_url` do passo 3.2 sem `p_plain_url` |
| `ORA-00920` ou `ORA-00936` ao salvar a query | Banco sem `BOOLEAN` em SQL (anterior ao 23ai) | Troque `case when e.status then` por `case when e.status = 1 then` (confirmar o tipo em `user_tab_columns`) |
| O badge aparece como texto `<span class=...>` | O HTML foi para a coluna errada ou *Escape special characters* bloqueou | Confira se a HTML Expression está em *Column Formatting* da coluna `SITUACAO` |
| As colunas de endereço continuam visíveis | O relatório *Primary* não foi salvo de novo | Passo 5.4 |
| Cidade/UF e Status não aparecem, e o export mostra os `displayColumn` antigos (com as sequências 1–15 do assistente) mas já com o `sort` por `NOME_FANTASIA` | O relatório foi salvo como padrão sem o passo 5.2 aplicado (ou com um relatório particular selecionado). Colunas criadas depois do relatório salvo nascem ocultas no *Primary* | Com **Primary** no seletor de relatórios, refaça 5.2 e 5.4; no export, os `displayColumn` passam a ser só as sete colunas (mais as ocultas) |
| O cabeçalho não fica em linha com o botão | CSS antigo em cache ou `custom.min.css` não reenviado | Passo 1 e Ctrl+Shift+R |
| O telefone continua sem máscara | O número gravado tem outro formato (com espaço, hífen ou DDI) e cai no `else` | Confira o valor na tabela; a máscara vale só para 10 ou 11 dígitos sem nada mais |
| A nota do rodapé não aparece | *Footer Text* em outro lugar no 26.1.5 | Tire print do painel e registre aqui o caminho real |
