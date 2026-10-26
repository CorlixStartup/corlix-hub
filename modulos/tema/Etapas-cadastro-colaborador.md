# Cadastro de colaborador · passo a passo no APEX

Este guia deixa a página 14 (Cadastro de Usuários) igual ao protótipo `pen_dev/Novo colaborador.png`, no App Builder do **APEX 26.1.5**. A descrição da tela está em `docs/ai-context/07-design-pen-dev.md` §4.5.

Como nos outros guias do tema, a mudança é feita no Builder. O backup diário traz o resultado para `corlixhub/pages/p00014-cadastros-de-usuarios.apx` na `DEV`; editar só o `.apx` do repositório não muda o app e é desfeito no próximo backup.

Passos marcados com **(confirmar no 26.1.5)** ainda não foram conferidos na tela desta versão. Se o caminho não existir, tire um print da árvore e do painel de propriedades e registre o caminho certo neste guia.

### O que muda

| Antes | Depois (protótipo) |
|---|---|
| Título "Cadastro de usuários" num card no corpo da página | Faixa branca com trilha "Colaboradores › Novo colaborador", título e descrição |
| Um card com três blocos sem título visível ("INFORMAÇÕES DE LOGIN", "DADOS DO COLABORADOR", "STATUS DO REGISTRO") | Três cards: **Dados pessoais**, **Vínculo profissional** e **Acesso ao sistema**, cada um com título e descrição à esquerda e campos em duas colunas à direita |
| Acesso ao sistema em primeiro | Ordem do protótipo: pessoa → vínculo → acesso |
| Rótulos "Último Nome", "E-mail Coporativo", "Salvar Usuario" | "Sobrenome", "E-mail corporativo", "Salvar colaborador" |
| Campos de 30 caracteres de largura | Campos ocupando a coluna (meia linha ou linha inteira) |
| Departamento e Cargo em Popup LOV | Select List, como no protótipo (o Gestor continua Popup LOV, com a lupa) |
| Botões no rodapé do card | Rodapé preso no fim da tela: nota à esquerda, **Cancelar** e **Salvar colaborador** à direita |

Os processos, as validações e o fluxo de gravação não mudam. A única mudança de comportamento é o passo 5.3: os campos que o protótipo marca com `*` passam a ser obrigatórios.

### Fica de fora (precisa de backend ou de outra página)

- **Perfis de acesso** (checkboxes Publicador / Administrador): hoje os papéis vêm do cargo (`PKG_PERFIS_ACESSO.ATRIBUIR_PAPEIS`), não de escolha manual.
- **Topo da hierarquia** (checkbox que esconde o Gestor): hoje basta deixar o Gestor em branco; a ajuda do campo diz isso.
- **Sugestão de primeiro nome e sobrenome** a partir do nome completo.
- **Senha mínima de 12 caracteres e troca no primeiro acesso**: o `APEX_UTIL.CREATE_USER` usa `p_change_password_on_first_use => 'N'` e não há validação de tamanho.
- **Modo edição** (`Editar colaborador.png`): a página só cadastra.

Por isso alguns textos do guia diferem do protótipo: eles descrevem o que a página faz hoje.

### Ordem dos passos

O CSS (passo 1) pode subir antes de tudo: as classes são novas e não afetam outras páginas. Faça os passos 2 a 7 em sequência e salve (*Save*) no fim de cada um.

---

## 1. CSS

Suba em *Shared Components › Static Application Files* os dois arquivos, substituindo os atuais:

- `corlixhub/shared-components/static-files/custom.css`
- `corlixhub/shared-components/static-files/custom.min.css`

O que entrou (seção 14 do `custom.css`):
- `.cx-cabecalho-pagina` (com `__trilha`, `__titulo`, `__descricao`): cabeçalho de página com trilha. Serve para outras páginas com o mesmo cabeçalho.
- `.cx-form-secao` (com `__info`, `__titulo`, `__descricao`): card de seção com descrição à esquerda e campos à direita. Abaixo de 768px vira uma coluna só.
- `.cx-form-rodape` (com `__nota`): rodapé do formulário preso no fim da tela.

## 2. Cabeçalho da página

Abra a página 14 no Page Designer.

### 2.1 Apagar o cabeçalho antigo

Na árvore *Rendering*, clique com o botão direito em **Cadastrar Colaborador - Header** (corpo da página) › **Delete**.

### 2.2 Criar o cabeçalho na faixa do título

1. Clique com o botão direito em **Breadcrumb Bar** › **Create Region** (confirmar no 26.1.5).
2. Propriedades:
   - *Identification › Name*: `Cabeçalho`
   - *Identification › Type*: **Dynamic Content**
   - *Source › Language*: PL/SQL; *PL/SQL Function Body returning a CLOB*:
     ```plsql
     return '<div class="cx-cabecalho-pagina">'
         || '<nav class="cx-cabecalho-pagina__trilha" aria-label="Trilha de navegação">'
         || '<a href="' || apex_escape.html_attribute(apex_page.get_url(p_page => 12)) || '">Colaboradores</a>'
         || '<span class="fa fa-chevron-right" aria-hidden="true"></span>'
         || '<span aria-current="page">Novo colaborador</span>'
         || '</nav>'
         || '<h1 class="cx-cabecalho-pagina__titulo">Novo colaborador</h1>'
         || '<p class="cx-cabecalho-pagina__descricao">Preencha os dados pessoais, o vínculo profissional e o acesso ao CorlixHub.</p>'
         || '</div>';
     ```
   - *Appearance › Template*: **Blank with Attributes (No Grid)** (o mesmo do cabeçalho da página 29).

O link usa `apex_page.get_url` porque as páginas exigem checksum (regra 4 do `docs/ai-context/08`). O ícone `fa-chevron-right` já sai como Lucide pelo `corlix-tema.css`.

**Confira:** no export, a região fica com `slot: breadcrumbBar` e `template: @/blank-with-attributes-no-grid`, como `cabeçalho` em `p00029-busca.apx`.

## 3. Card que envolve as seções

Selecione a região **Cadastrar Colaborador** (o form, tabela `COLABORADOR`):

- *Appearance › Template Options*: mantenha **Header: Hidden** e troque *Style* para **Remove UI Decoration** (`t-Region--noUI`). Desmarque **Stack Regions** (`t-Region--stacked`) se estiver marcado (confirmar no 26.1.5).

Os cards passam a ser as três regiões filhas; o form só agrupa os itens.

## 4. As três seções

As regiões filhas do form recebem o mesmo tratamento. Em cada uma:

- *Appearance › Template*: **Standard**
- *Appearance › Template Options*: **Header: Hidden** (`t-Region--removeHeader`); *Style* volta para **Default** (tire o *Remove UI Decoration*)
- *Appearance › CSS Classes*: `cx-form-secao`
- *Layout › Parent Region*: **Cadastrar Colaborador**

O título visível vem do HTML da região (o header da região fica escondido para não aparecer duas vezes).

### 4.1 Dados pessoais

Selecione **DADOS DO COLABORADOR**:
- *Identification › Name*: `Dados pessoais`; *Title*: `Dados pessoais`
- *Layout › Sequence*: `10`
- *Source › HTML Code*:
  ```html
  <div class="cx-form-secao__info">
    <h2 class="cx-form-secao__titulo">Dados pessoais</h2>
    <p class="cx-form-secao__descricao">Identificação da pessoa em todo o CorlixHub.</p>
  </div>
  ```

### 4.2 Vínculo profissional (nova)

Clique com o botão direito em **Cadastrar Colaborador** › **Create Sub Region** (confirmar no 26.1.5):
- *Identification › Name*: `Vínculo profissional`; *Title*: `Vínculo profissional`; *Type*: **Static Content**
- *Layout › Sequence*: `20`
- *Source › HTML Code*:
  ```html
  <div class="cx-form-secao__info">
    <h2 class="cx-form-secao__titulo">Vínculo profissional</h2>
    <p class="cx-form-secao__descricao">Empresa, área e liderança da pessoa. Departamento, cargo e gestor são carregados depois que a empresa é selecionada.</p>
  </div>
  ```

### 4.3 Acesso ao sistema

Selecione **INFORMAÇÕES DE LOGIN**:
- *Identification › Name*: `Acesso ao sistema`; *Title*: `Acesso ao sistema`
- *Layout › Sequence*: `30`
- *Source › HTML Code*:
  ```html
  <div class="cx-form-secao__info">
    <h2 class="cx-form-secao__titulo">Acesso ao sistema</h2>
    <p class="cx-form-secao__descricao">Credenciais usadas para entrar no CorlixHub.</p>
  </div>
  ```

A região **STATUS DO REGISTRO** é apagada no passo 5.4, depois que o switch sair dela.

## 5. Itens

### 5.1 Posição, rótulo e largura

Para cada item, ajuste *Layout › Region*, *Layout › Sequence*, *Layout › Start New Row*, *Layout › Column Span* e *Label › Label*. Em todos os itens visíveis:
- *Appearance › Width*: apague o `30`.
- *Appearance › Template Options*: marque **Stretch Form Item** (confirmar no 26.1.5).

| Região | Seq | Item | Label | Start New Row | Column Span |
|---|---|---|---|---|---|
| Dados pessoais | 10 | `P14_NOME_COMPLETO` | Nome completo | Sim | 12 |
| Dados pessoais | 20 | `P14_PRIMEIRO_NOME` | Primeiro nome | Sim | 6 |
| Dados pessoais | 30 | `P14_ULTIMO_NOME` | Sobrenome | Não | 6 |
| Dados pessoais | 40 | `P14_DATA_NASCIMENTO` | Data de nascimento | Sim | 6 |
| Vínculo profissional | 10 | `P14_EMPRESA` | Empresa | Sim | 6 |
| Vínculo profissional | 20 | `P14_DATA_ADMISSAO` | Data de admissão | Não | 6 |
| Vínculo profissional | 30 | `P14_DEPARTAMENTO` | Departamento | Sim | 6 |
| Vínculo profissional | 40 | `P14_CARGO` | Cargo | Não | 6 |
| Vínculo profissional | 50 | `P14_GESTOR` | Gestor | Sim | 6 |
| Acesso ao sistema | 10 | `P14_EMAIL` | E-mail corporativo | Sim | 6 |
| Acesso ao sistema | 20 | `P14_LOGIN` | Login corporativo | Não | 6 |
| Acesso ao sistema | 30 | `P14_SENHA` | Senha | Sim | 6 |
| Acesso ao sistema | 40 | `P14_CONFIRMAR_SENHA` | Confirmar senha | Não | 6 |
| Acesso ao sistema | 50 | `P14_STATUS` | Situação da conta | Sim | 12 |

Os campos de senha já trazem o botão de mostrar/ocultar (o "olho" do protótipo): é padrão do item Password no 26.1. Não marque *Hide Password Visibility*.

### 5.2 Departamento e Cargo como Select List

Em `P14_DEPARTAMENTO` e `P14_CARGO`:
- *Identification › Type*: **Select List**. A query da LOV e o *Cascading List of Values* (Parent Items e Items to Submit) continuam os mesmos.
- *List of Values › Display Null Value*: On, com *Null Display Value* vazio (confirmar no 26.1.5).

O `P14_GESTOR` continua **Popup LOV** (no protótipo ele tem a lupa).

### 5.3 Obrigatórios e textos de ajuda

| Item | *Appearance › Template* | *Validation › Value Required* | *Help › Inline Help Text* |
|---|---|---|---|
| `P14_NOME_COMPLETO` | Required - Floating | On (já está) | |
| `P14_PRIMEIRO_NOME` | Required - Floating | **On** | |
| `P14_ULTIMO_NOME` | Required - Floating | **On** | |
| `P14_DATA_NASCIMENTO` | Required - Floating | **On** | Usada na lista de aniversariantes. |
| `P14_EMPRESA` | Required - Floating | On (já está) | |
| `P14_DATA_ADMISSAO` | Required - Floating | **On** | |
| `P14_DEPARTAMENTO` | Required - Floating | On (já está) | Disponível após selecionar a empresa. |
| `P14_CARGO` | Required - Floating | On (já está) | Disponível após selecionar a empresa. |
| `P14_GESTOR` | Optional - Floating | Off | Busque pelo nome. Deixe em branco para quem está no topo da hierarquia (ex.: CEO). |
| `P14_EMAIL` | Required - Floating | On (já está) | |
| `P14_LOGIN` | Required - Floating | On (já está) | |
| `P14_SENHA` | Required - Floating | **On** | |
| `P14_CONFIRMAR_SENHA` | Required - Floating | **On** | |
| `P14_STATUS` | Optional - Above (confirmar no 26.1.5) | Off | Contas inativas não conseguem entrar no sistema. |

O *Required - Floating* só desenha o `*`; quem barra o campo vazio é o *Value Required*.

### 5.4 Apagar a região de status

Com o `P14_STATUS` já em **Acesso ao sistema**, clique com o botão direito em **STATUS DO REGISTRO** › **Delete**. Ela ficou vazia.

## 6. Rodapé com os botões

### 6.1 Região do rodapé

Clique com o botão direito em **Body** › **Create Region** (confirmar no 26.1.5):
- *Identification › Name*: `Rodapé`; *Title*: `Ações do formulário`; *Type*: **Static Content**
- *Source › HTML Code*: `<p class="cx-form-rodape__nota">Campos com * são obrigatórios.</p>`
- *Layout › Sequence*: `30` (depois do form)
- *Appearance › Template*: **Buttons Container**
- *Appearance › CSS Classes*: `cx-form-rodape`

O título fica escondido pelo CSS, mas continua para leitores de tela.

### 6.2 Botões

| Botão | *Layout › Region* | *Layout › Slot* | Seq | *Identification › Label* | *Appearance* |
|---|---|---|---|---|---|
| `CANCELAR` | Rodapé | **Next** | 10 | Cancelar | Template Text, sem Hot |
| `SALVAR_USUARIO` | Rodapé | **Next** | 20 | Salvar colaborador | Template Text, **Hot** |

A ação dos botões não muda: o `SALVAR_USUARIO` continua com *Database Action* = SQL INSERT e a confirmação, e os processos do form continuam rodando com ele, porque dependem do *request* e não da região do botão.

O botão `HISTORICO` pode ficar onde está: ele nunca aparece nesta página (ver `docs/ai-context/08` §3).

## 7. Testar

Recarregue a página com **Ctrl+Shift+R** (Cmd+Shift+R no Mac) e confira:

- [ ] Faixa branca com "Colaboradores › Novo colaborador", título grande e descrição; "Colaboradores" abre a página 12.
- [ ] Três cards brancos com borda fina, título e descrição na coluna da esquerda e campos na da direita.
- [ ] Nome completo na linha inteira; os demais em pares, como no protótipo.
- [ ] Departamento e Cargo como lista de seleção, carregando pela empresa.
- [ ] Rodapé branco preso no fim da tela ao rolar, com a nota à esquerda e **Cancelar** (cinza) + **Salvar colaborador** (escuro) à direita.
- [ ] Salvar com campos vazios mostra o erro em cada campo obrigatório.
- [ ] Um cadastro completo cria o usuário APEX e a admissão no histórico, como antes.
- [ ] Na largura de celular (menos de 768px), descrição em cima e campos embaixo.

### Se não funcionar

| Sintoma | Causa provável | Correção |
|---|---|---|
| "Component P14_… cannot be rendered as the grid settings for this component are invalid. It is set to be displayed at Column 13…" (`WWV_FLOW_GRID_LAYOUT.MORE_THAN_SUPPORTED_COLUMNS`) | O item está com *Start New Row* = Não depois de uma linha já cheia (ex.: `P14_DATA_NASCIMENTO` depois de Primeiro nome 6 + Sobrenome 6) | Passo 5.1: *Layout › Start New Row* = Sim no item citado. Confira a coluna "Start New Row" da tabela em todos os itens |
| Descrição e campos um embaixo do outro em tela larga | `custom.css` antigo, ou a região sem a classe `cx-form-secao` | Passo 1 e Ctrl+Shift+R; passo 4, *CSS Classes* |
| Título da seção aparece duas vezes | A região ficou com o header visível | Passo 4: *Header: Hidden* |
| Descrição na coluna da direita, acima dos campos | O APEX embrulhou o HTML da região num elemento a mais, e o `.cx-form-secao__info` não é filho direto do `.t-Region-body` | Inspecione no DevTools e mande o HTML gerado; o seletor do CSS precisa seguir a estrutura real |
| Cards colados, sem fundo cinza entre eles, ou um card branco em volta dos três | O form **Cadastrar Colaborador** ainda tem a decoração do Standard | Passo 3: *Remove UI Decoration* |
| Campos estreitos | *Width* ainda com `30` ou *Stretch Form Item* desmarcado | Passo 5.1 |
| Rodapé não fica preso ao rolar | Algum contêiner acima tem `overflow` diferente de `visible` | Inspecione no DevTools e registre aqui o elemento |
| Botões continuam no card | Slot ou região do botão não mudou | Passo 6.2 |
| `ORA-` ao salvar sem senha | *Value Required* desligado na senha | Passo 5.3 |
