# Cadastro de empresa · passo a passo no APEX

Este guia deixa a página 16 (Cadastro de Empresas, modal aberto pela página 15) igual ao protótipo `pen_dev/Nova empresa (modal).png`, no App Builder do **APEX 26.1.5**. A descrição da tela está em `docs/ai-context/07-design-pen-dev.md` §4.7.1.

Como nos outros guias do tema, a mudança é feita no Builder. O backup diário traz o resultado para `corlixhub/pages/p00016-cadastro-de-empresas.apx` na `DEV`; editar só o `.apx` do repositório não muda o app e é desfeito no próximo backup.

Passos marcados com **(confirmar no 26.1.5)** ainda não foram conferidos na tela desta versão. Se o caminho não existir, tire um print da árvore e do painel de propriedades e registre o caminho certo neste guia.

### O que muda

| Antes | Depois (protótipo) |
|---|---|
| Título "Cadastro de Empresas" | "Nova empresa" (ou "Editar empresa", ao abrir pelo lápis) |
| Seções "Informações principais", "Contato e endereço", "Configurações", com rolagem própria | **Identificação**, **Contato e endereço**, **Logotipo e situação**, sem rolagem interna |
| Razão social primeiro | **CNPJ** primeiro: ao digitar, os dados vêm da Receita Federal (BrasilAPI) |
| Campos de 32 caracteres, em linhas soltas | Campos em grade, ocupando a coluna |
| "Required" embaixo do campo e triângulo no canto | `*` vermelho nos obrigatórios e "(opcional)" no rótulo dos opcionais |
| Data de abertura obrigatória, no seletor nativo do navegador | Opcional, no Date Picker do APEX (ícone de calendário) |
| UF digitada | UF numa lista |
| Logotipo num campo de arquivo simples | Dropzone "Arraste o logotipo ou clique para selecionar", ao lado da Situação |
| Switch "Status da Empresa" desligado ao abrir | "Situação" já **Ativa**, com a ajuda "Novas empresas nascem ativas." |
| Cancelar à esquerda, junto do Remover; rodapé branco | Rodapé cinza-claro: "Campos marcados com * são obrigatórios." à esquerda; **Cancelar** + **Criar empresa** à direita |
| Página sem autorização | Mesma autorização da página 15 |

Também ficam corrigidos os defeitos do `docs/ai-context/08` §3 (p16): os campos de endereço desabilitados (que não são enviados no submit), o CEP e o telefone com máscara que não cabem na coluna e o logotipo que não é gravado na tabela.

### Fica de fora

- **Edição:** o protótipo só mostra "Nova empresa". Ao editar, o guia usa o mesmo layout, com o título "Editar empresa", **Salvar alterações** e **Remover** (vermelho, à esquerda). A consulta do CNPJ só roda em empresa nova, para não sobrescrever dados já cadastrados.
- A BrasilAPI devolve razão social e cidade em maiúsculas, como estão na Receita. Os campos ficam editáveis para quem quiser ajustar.

### Ordem dos passos

1. Banco (passo 0) e CSS (passo 1) podem ir antes de tudo: não mudam nada na tela atual.
2. Depois faça os passos 2 a 7 em sequência e salve (*Save*) no fim de cada um.

---

## 0. Banco: data de abertura opcional

`EMPRESA.DATA_CRIACAO` é `NOT NULL`. Com o campo vazio, o form grava `NULL` e o insert falha com `ORA-01400`. Rode `modulos/empresas/01_data_criacao_opcional.sql`:

- **SQLcl:** `cd modulos/empresas` e `@instalar.sql`.
- **SQL Commands do APEX:** cole só o bloco `declare … end;` do arquivo, sem a `/` final, e clique em *Run*.

O script só altera a coluna se ela ainda for `NOT NULL`. O `DEFAULT SYSDATE` continua valendo para inserts que omitem a coluna.

**Confira:** `select nullable from user_tab_columns where table_name = 'EMPRESA' and column_name = 'DATA_CRIACAO'` devolve `Y`.

### 0.1 Complemento com 100 caracteres

`EMPRESA.COMPLEMENTO` tem 30 caracteres, mas a consulta do CNPJ (§5.1) traz complementos maiores: o do Banco do Brasil tem 67 (visto em 27/10/2026). Com 30, o **Criar empresa** falha no tamanho máximo logo depois do preenchimento automático. Rode `modulos/empresas/02_complemento_100.sql` do mesmo jeito que o 01: no SQLcl, o `@instalar.sql` já roda os dois; no SQL Commands, cole só o bloco `declare … end;` do 02.

Depois, no Page Designer, `P16_COMPLEMENTO` › *Validation › Maximum Length*: `100`.

**Confira:** `select char_length from user_tab_columns where table_name = 'EMPRESA' and column_name = 'COMPLEMENTO'` devolve `100`.

## 1. CSS

Suba em *Shared Components › Static Application Files* os dois arquivos, substituindo os atuais:

- `corlixhub/shared-components/static-files/custom.css`
- `corlixhub/shared-components/static-files/custom.min.css`

O que entrou (seção 16 do `custom.css`):
- `.cx-form-modal`: na região do form. Troca o "Required" do Redwood pelo `*` vermelho no rótulo e põe "Ativa"/"Inativa" ao lado do switch, como a `.cx-form-secao` da página 14.
- `.cx-form-modal-rodape` (com `__nota`): na região dos botões. Rodapé cinza-claro com borda, aviso à esquerda e botões à direita.

Se você já subiu os arquivos da página 15 (`Etapas-empresas.md`), suba de novo: a seção 16 veio depois.

## 2. Página

Abra a página 16 no Page Designer e selecione o nó da página (**Page 16: Cadastro de Empresas**):

- *Identification › Title*: `&P16_TITULO.`
- *Dialog › Width*: `1000` (confirmar no 26.1.5)
- *Security › Authorization Scheme*: **EQUIPE_CORLIX_HUB** (a mesma da página 15 e do menu)

### 2.1 Título conforme o caso

1. Clique com o botão direito na região **Informações Principais** › **Create Page Item**:
   - *Identification › Name*: `P16_TITULO`
   - *Identification › Type*: **Hidden**
2. Na aba *Pre-Rendering*, clique com o botão direito em **Before Header** › **Create Computation** (confirmar no 26.1.5):
   - *Identification › Item Name*: `P16_TITULO`
   - *Execution › Sequence*: `20` (depois do *Initialize form*, que é o 10)
   - *Computation › Type*: **Expression**; *Language*: PL/SQL; *PL/SQL Expression*:
     ```plsql
     case when :P16_ID_EMPRESA is null then 'Nova empresa' else 'Editar empresa' end
     ```
3. Selecione o nó da página e, em *JavaScript › Execute when Page Loads*, cole:
   ```javascript
   // O título do diálogo é definido antes de o item ter valor; &P16_TITULO. sozinho deixa o cabeçalho vazio
   apex.util.getTopApex()
       .jQuery(".ui-dialog-content")
       .dialog("option", "title", apex.item("P16_TITULO").getValue());
   ```
   O *Title* `&P16_TITULO.` continua: ele dá o título da aba (`document.title`), mas não o do cabeçalho do modal. É o caso "Including Context Info in Dialog Title" da documentação do 26.1 (`docs/apex-26.1/08-api-javascript.md`).

**Confira:** "+ Nova empresa" abre o modal com o título "Nova empresa"; o lápis abre com "Editar empresa".

## 3. Seções

Em cada uma das três regiões filhas do form:
- *Appearance › Template Options*: tire **Scroll - Default Height** (`t-Region--scrollBody`). Mantenha **Header: Hidden** e **Style: Remove UI Decoration**.

| Região (*Name* atual) | *Name* novo | *Header and Footer › Header Text* |
|---|---|---|
| Informações Principais | `Identificação` | `<h2 class="cx-titulo-secao">Identificação</h2>` |
| Contato e Endereço | `Contato e endereço` | `<h2 class="cx-titulo-secao">Contato e endereço</h2>` (já está) |
| Configurações | `Logotipo e situação` | `<h2 class="cx-titulo-secao">Logotipo e situação</h2>` |

Depois selecione a região do form, **Cadastro de Empresas**:
- *Appearance › CSS Classes*: `cx-form-modal`

## 4. Campos

### 4.1 Posição, rótulo, largura e ajuda

Para cada item, ajuste *Layout › Sequence*, *Layout › Start New Row*, *Layout › Column Span*, *Label › Label*, *Appearance › Template* e *Help › Inline Help Text*. Em todos os itens visíveis:
- *Appearance › Width*: apague o `32` (no logotipo, o `30`). Sem o *Width*, os campos ocupam a coluna toda (conferido na página 14).

| Região | Seq | Item | Label | Start New Row | Column Span | Template | Inline Help Text |
|---|---|---|---|---|---|---|---|
| Identificação | 20 | `P16_CNPJ` | CNPJ | Sim | 5 | Required - Floating | `Preenche os dados pela Receita Federal.` |
| | 30 | `P16_DATA_CRIACAO` | Data de abertura (opcional) | Não | 7 | **Optional - Floating** | — |
| | 40 | `P16_NOME` | Razão social | Sim | 12 | Required - Floating | — |
| | 50 | `P16_NOME_FANTASIA` | Nome fantasia | Sim | 12 | Required - Floating | — |
| Contato e endereço | 10 | `P16_EMAIL_CORPORATIVO` | E-mail corporativo | Sim | 8 | Required - Floating | — |
| | 20 | `P16_TELEFONE` | Telefone | Não | 4 | Required - Floating | — |
| | 30 | `P16_CEP` | CEP | Sim | 3 | Required - Floating | `Preenche o endereço.` |
| | 40 | `P16_LOGRADOURO` | Logradouro | Não | 7 | Required - Floating | — |
| | 50 | `P16_NUMERO` | Número | Não | 2 | Required - Floating | — |
| | 60 | `P16_COMPLEMENTO` | Complemento (opcional) | Sim | 6 | Optional - Floating | — |
| | 70 | `P16_BAIRRO` | Bairro | Não | 6 | Required - Floating | — |
| | 80 | `P16_CIDADE` | Cidade | Sim | 10 | Required - Floating | — |
| | 90 | `P16_UF` | UF | Não | 2 | Required - Floating | — |
| Logotipo e situação | 10 | `P16_LOGOTIPO_EMPRESA` | Logotipo (opcional) | Sim | 8 | **Optional - Above** | — |
| | 20 | `P16_STATUS` | Situação | Não | 4 | **Optional - Above** (o switch sempre tem valor) | `Novas empresas nascem ativas.` |

`P16_ID_EMPRESA` e `P16_TITULO` são ocultos e não entram na grade.

O "Start New Row" importa: com *Não* depois de uma linha já cheia (12 colunas), o APEX acusa a coluna 13 (`WWV_FLOW_GRID_LAYOUT.MORE_THAN_SUPPORTED_COLUMNS`, ver o guia da página 14).

Em "Contato e endereço", confira três pontos que costumam sair errados:
- **A sequência muda a linha, e não pode repetir.** O E-mail é o 10 e o CEP é o 30. Se os dois ficarem trocados, a 2ª linha vira E-mail (8) + Logradouro + Número e passa de 12 colunas.
- **Use *Column Span*, não *Column*.** As duas propriedades ficam lado a lado em *Layout*. *Column* = 6 no Bairro diz que ele *começa* na coluna 6, o que bate de frente com o Complemento (colunas 1–6). O valor certo é *Column Span* = 6, com *Column* em **Automatic**.
- **Nenhum item visível fica com *Column Span* vazio.** Sem o span, a UF ocupa o resto da linha. Preencha os 2 da tabela.

Para conferir: em cada linha, a soma dos *Column Span* tem que dar 12 (8+4, 3+7+2, 6+6, 10+2).

Confira também, item por item, o que costuma ficar para trás:
- ***Width* vazio em todos.** O `32` sobra no Nome fantasia e o `30` no Logotipo. Com o *Width*, o campo fica estreito mesmo com o span certo.
- **Logotipo e Situação na mesma linha:** Logotipo com span 8; Situação com *Start New Row* = **Não** e span 4. Sem isso, a Situação cai numa linha própria.
- **Situação, não "Status da Empresa":** o label do `P16_STATUS` muda, e o template vai para **Optional - Above** (não Required - Floating).
- ***Inline Help Text* em três itens:** CNPJ, CEP e Situação. Ele fica em *Help*, mais abaixo no painel, e não em *Label*.

### 4.2 CNPJ

No `P16_CNPJ`: *Appearance › Value Placeholder*: `00.000.000/0000-00`.

### 4.3 Data de abertura com calendário

No `P16_DATA_CRIACAO`:
- *Settings › Display As*: **Popup** (era Native HTML; o Popup traz o ícone de calendário do protótipo) (confirmar no 26.1.5)
- *Appearance › Format Mask*: `DD/MM/YYYY`
- *Validation › Value Required*: **Off**
- *Validation › Maximum Length*: apague o `255`

### 4.4 UF em lista

No `P16_UF`:
- *Identification › Type*: **Select List**
- *List of Values › Type*: **Static Values**; nos valores, uma linha por UF, com *Display Value* e *Return Value* iguais:
  `AC, AL, AP, AM, BA, CE, DF, ES, GO, MA, MT, MS, MG, PA, PB, PR, PE, PI, RJ, RN, RS, RO, RR, SC, SP, SE, TO`
- *List of Values › Display Extra Values*: **Off**; *Display Null Value*: **On**, com *Null Display Value* vazio
- Confira a lista: são **27** siglas, cada uma uma vez só. **MG** vem depois de **MS**. É fácil digitar `MS` duas vezes e ficar sem `MG`; aí uma empresa de Minas fica sem UF, porque a sigla devolvida pelo ViaCEP e pela BrasilAPI não está na lista.
- *List of Values › Sort*: deixe na ordem digitada (alfabética pelo nome do estado, como acima) (confirmar no 26.1.5)

O ViaCEP e a BrasilAPI devolvem a sigla (`SP`), que é o *Return Value*, então o preenchimento automático escolhe a opção certa.

### 4.5 Logotipo em dropzone, gravado na tabela

O `P16_LOGOTIPO_EMPRESA` guarda o arquivo em `APEX_APPLICATION_TEMP_FILES` e o processo do form não grava a coluna. Para gravar, o armazenamento precisa ser a própria coluna BLOB (documentação do 26.1, *Configuring Upload Image Item Source*). No item:

- *Storage › Type*: **BLOB column specified in Item Source attribute**
- *Display › Display As*: **Inline Dropzone**
- *Display › Dropzone Title*: `Arraste o logotipo ou clique para selecionar`
- *Display › Dropzone Description*: `PNG, JPG ou SVG, até 2 MB. Prefira fundo transparente.`
- *Resize To › Maximum File Size*: `2048` (KB). Não é um limite que recusa o arquivo: a imagem maior é reduzida no navegador até caber.

O Image Upload **não tem *File Types***: o atributo só existe no File Upload (documentação do 26.1, *About Item Types*, A.10 e A.12). O item já aceita só imagens, e o "PNG, JPG ou SVG" da descrição é uma orientação, não uma trava.

A tabela `EMPRESA` não tem colunas de MIME type, nome de arquivo nem data do BLOB, então deixe *MIME Type Column*, *Filename Column* e *BLOB Last Updated Column* em branco. Esses campos recebem o **nome de um item ou coluna** (ex.: `MIME_TYPE` na página 17), nunca uma lista de tipos: `image/png,image/jpeg,…` no *MIME Type Column* faz o APEX procurar um item com esse nome e quebra a gravação do logotipo. Se a pré-visualização não aparecer ao editar, o próximo passo é criar essas colunas (mudança de schema; registre no `05`).

### 4.6 Situação nasce ativa

A coluna `STATUS` é obrigatória e não tem `DEFAULT`, e hoje o switch abre desligado. No `P16_STATUS`:
- *Default › Type*: **Static**
- *Default › Static Value*: `TRUE`

- *Validation › Value Required*: **Off**. O switch sempre manda `TRUE` ou `FALSE`, então a validação nunca falha; ligada, ela só faz o APEX tratar o item como obrigatório.

`TRUE` é o valor do switch ligado, como no `P14_STATUS` (guia da página 14, 5.6).

## 5. Preenchimento automático

### 5.1 CNPJ → dados da Receita Federal (novo)

Clique com o botão direito em **Dynamic Actions** › **Create Dynamic Action**:
- *Identification › Name*: `Dados por CNPJ`
- *When › Event*: **Change**; *Selection Type*: **Item(s)**; *Item(s)*: `P16_CNPJ`

Na ação *True* que o Builder cria (ela nasce como **Show**; troque a *Action* antes de colar o código):
- *Identification › Action*: **Execute JavaScript Code**
- *Settings › Code*:
  ```javascript
  var cnpj = this.triggeringElement.value.replace(/\D/g, '');
  // Só em empresa nova: na edição, não sobrescreve o que já está cadastrado
  if (cnpj.length !== 14 || apex.item("P16_ID_EMPRESA").getValue()) {
    return;
  }

  var preencher = function (item, valor) {
    if (valor) {
      apex.item(item).setValue(valor);
    }
  };

  fetch(`https://brasilapi.com.br/api/cnpj/v1/${cnpj}`)
    .then(response => {
      if (!response.ok) {
        throw new Error(response.status);
      }
      return response.json();
    })
    .then(d => {
      apex.message.clearErrors();
      preencher("P16_NOME", d.razao_social);
      preencher("P16_NOME_FANTASIA", d.nome_fantasia);
      if (d.data_inicio_atividade) {
        var [ano, mes, dia] = d.data_inicio_atividade.split("-");
        preencher("P16_DATA_CRIACAO", `${dia}/${mes}/${ano}`);
      }
      preencher("P16_EMAIL_CORPORATIVO", (d.email || "").toLowerCase());
      preencher("P16_TELEFONE", d.ddd_telefone_1);
      preencher("P16_CEP", d.cep);
      preencher("P16_LOGRADOURO", [d.descricao_tipo_de_logradouro, d.logradouro].filter(Boolean).join(" "));
      preencher("P16_NUMERO", d.numero);
      preencher("P16_COMPLEMENTO", d.complemento);
      preencher("P16_BAIRRO", d.bairro);
      preencher("P16_CIDADE", d.municipio);
      preencher("P16_UF", d.uf);
    })
    .catch(() => {
      apex.message.showErrors([{
        type: "error",
        location: "inline",
        pageItem: "P16_CNPJ",
        message: "Não encontramos este CNPJ na Receita Federal. Confira o número ou preencha os dados à mão.",
        unsafe: false
      }]);
    });
  ```
- *Affected Elements*: deixe vazio (o código não age sobre um elemento)
- *Execution › Fire on Initialization*: **Off**

Se o código estiver em *Affected Elements › JavaScript Expression*, a *Action* ainda está como **Show**: a DA não chama a BrasilAPI e nada é preenchido. No export, a ação certa aparece como `action: executeJsCode` com o código em `settings { jsCode }`.

A consulta é feita no navegador, como a do ViaCEP. A BrasilAPI é pública e gratuita. Campo que a Receita não traz (o e-mail costuma vir vazio) fica como estava.

### 5.2 CEP → endereço (corrigido)

Hoje a DA **Desabilitar campos de endereço** desabilita Logradouro, Bairro, Cidade e UF enquanto o CEP está vazio. Depois que o CEP é digitado, só Número e Complemento voltam a ficar habilitados. Item desabilitado não é enviado no submit, então a gravação falha com "Logradouro must have some value". E quando o ViaCEP não traz o logradouro (CEP geral de cidade), não dá para digitá-lo.

1. Apague a DA **Desabilitar campos de endereço** (botão direito › **Delete**).
2. Na DA **Endereço por CEP**, ação **Quando CEP for verdade**, troque o *Settings › Code* por:
   ```javascript
   var cep = this.triggeringElement.value.replace(/\D/g, '');
   if (cep.length !== 8) {
     return;
   }

   fetch(`https://viacep.com.br/ws/${cep}/json/`)
     .then(response => response.json())
     .then(data => {
       apex.message.clearErrors();
       if (data.erro) {
         apex.message.showErrors([{
           type: "error",
           location: "inline",
           pageItem: "P16_CEP",
           message: "CEP não encontrado. Confira o número ou preencha o endereço à mão.",
           unsafe: false
         }]);
         return;
       }
       apex.item("P16_LOGRADOURO").setValue(data.logradouro);
       apex.item("P16_BAIRRO").setValue(data.bairro);
       apex.item("P16_CIDADE").setValue(data.localidade);
       apex.item("P16_UF").setValue(data.uf);
       apex.item(data.logradouro ? "P16_NUMERO" : "P16_LOGRADOURO").setFocus();
     })
     .catch(() => {
       apex.message.showErrors([{
         type: "error",
         location: "inline",
         pageItem: "P16_CEP",
         message: "Não foi possível consultar o CEP agora. Preencha o endereço à mão.",
         unsafe: false
       }]);
     });
   ```

Os campos ficam sempre editáveis. O CEP preenchido pela consulta do CNPJ não dispara o ViaCEP (o `setValue` não gera `keyup`), e o endereço já vem completo da Receita.

## 6. CEP e telefone com máscara

As colunas `CEP` (8) e `TELEFONE` (12) só comportam os dígitos, e os itens limitam a 8 e 12 caracteres. Por isso "01310-100" e "(11) 98765-1234" não cabem. A Corlix tem hoje o CEP `0101010`, com 7 dígitos.

A correção aceita a máscara na digitação e grava só os dígitos. A lista (página 15) já formata o telefone na exibição.

1. Nos itens, *Validation › Maximum Length*: `P16_CEP` = `9`; `P16_TELEFONE` = `15`.
2. Na aba *Processing*, clique com o botão direito em **After Submit** › **Create Computation** (confirmar no 26.1.5), uma para cada item. Em ambas, *Computation › Type*: **Expression** e *Language*: PL/SQL:

   | *Item Name* | Seq | *PL/SQL Expression* |
   |---|---|---|
   | `P16_CEP` | 10 | `regexp_replace(:P16_CEP, '[^0-9]')` |
   | `P16_TELEFONE` | 20 | `regexp_replace(:P16_TELEFONE, '[^0-9]')` |

   As computações *After Submit* rodam antes das validações, que já recebem só os dígitos.
3. Na aba *Processing*, em **Validating**, crie três validações (botão direito › **Create Validation**). Em todas, *Error › Display Location*: **Inline with Field**:

   | *Name* | *Type* | *PL/SQL Expression* | *Error Message* | *Associated Item* |
   |---|---|---|---|---|
   | `CNPJ com 14 dígitos` | Expression | `length(regexp_replace(:P16_CNPJ, '[^0-9]')) = 14` | `Informe os 14 dígitos do CNPJ.` | `P16_CNPJ` |
   | `CEP com 8 dígitos` | Expression | `regexp_like(:P16_CEP, '^[0-9]{8}$')` | `Informe o CEP com 8 dígitos.` | `P16_CEP` |
   | `Telefone com DDD` | Expression | `regexp_like(:P16_TELEFONE, '^[0-9]{10,11}$')` | `Informe o telefone com DDD (10 ou 11 dígitos).` | `P16_TELEFONE` |

   O botão `DELETE` já tem *Execute Validations* = Não, então Remover não passa por elas.

O CNPJ continua gravado como foi digitado (a coluna tem 20 caracteres e aceita a máscara); a validação só confere os dígitos.

**Atenção:** ao editar a Corlix, a validação do CEP vai pedir os 8 dígitos. Corrija o CEP antes de salvar.

## 6.1 CNPJ repetido e remoção com vínculos

Sem estas duas validações, o form aceita o mesmo CNPJ duas vezes (a tabela não tem `UNIQUE`), e o **Remover** de uma empresa com cadastros mostra um `ORA-02292: integrity constraint … violated - child record found` cru.

As duas validações ficam na aba *Processing* do Page Designer, junto das três que já existem (CNPJ com 14 dígitos, CEP com 8 dígitos, Telefone com DDD).

### 6.1.1 CNPJ não cadastrado

1. No Page Designer da página 16, abra a aba **Processing** (no painel da esquerda, ao lado de *Rendering*).
2. Clique com o botão direito em **Validating** › **Create Validation**. A validação nova aparece selecionada, com o nome "New".
3. No painel de propriedades, à direita:
   - *Identification › Name*: `CNPJ não cadastrado`
   - *Execution › Sequence*: `15` (fica logo depois da "CNPJ com 14 dígitos", que é a 10)
   - *Validation › Type*: **Function Body (returning Boolean)**
   - *Validation › Language*: **PL/SQL**
   - *Validation › PL/SQL Function Body*: clique no campo, apague o que houver e cole:
   ```plsql
   declare
       l_existe number;
   begin
       -- Compara só os dígitos: o CNPJ é gravado com a máscara que foi digitada
       select count(*)
         into l_existe
         from empresa
        where regexp_replace(cnpj, '[^0-9]') = regexp_replace(:P16_CNPJ, '[^0-9]')
          and (:P16_ID_EMPRESA is null or id_empresa <> to_number(:P16_ID_EMPRESA))
          and rownum = 1;
       return l_existe = 0;
   end;
   ```
   - *Validation › Always Execute*: deixe **Off**
   - *Error › Error Message*: `Já existe uma empresa cadastrada com este CNPJ.`
   - *Error › Display Location*: **Inline with Field**
   - *Error › Associated Item*: `P16_CNPJ`
   - *Server-side Condition › Type*: deixe **vazio** (a validação roda no Criar e no Salvar; o Remover não executa validações)
4. Clique em **Save** (canto superior direito).

Na edição, a própria empresa fica de fora da comparação (`id_empresa <> :P16_ID_EMPRESA`), então salvar a Corlix sem mudar o CNPJ não acusa nada.

**Confira:** em **+ Nova empresa**, com o CNPJ da Corlix (`00.000.000/0001-00`), **Criar empresa** mostra "Já existe uma empresa cadastrada com este CNPJ." embaixo do campo. Para não gravar nada, deixe o telefone incompleto (ex.: `(11) 98765`): as duas mensagens aparecem juntas e o insert não acontece.

### 6.1.2 Empresa sem vínculos

1. Ainda na aba **Processing**, clique com o botão direito em **Validating** › **Create Validation**.
2. No painel de propriedades:
   - *Identification › Name*: `Empresa sem vínculos`
   - *Execution › Sequence*: `40` (depois da "Telefone com DDD", que é a 30)
   - *Validation › Type*: **Function Body (returning Boolean)**
   - *Validation › Language*: **PL/SQL**
   - *Validation › PL/SQL Function Body*: cole:
   ```plsql
   declare
       l_existe number;
   begin
       -- Percorre as FKs para EMPRESA pelo dicionário: tabela nova com FK entra sozinha
       for fk in (
           select c.table_name, cc.column_name
             from user_constraints c
             join user_constraints p
               on p.constraint_name = c.r_constraint_name
             join user_cons_columns cc
               on cc.constraint_name = c.constraint_name
            where c.constraint_type = 'R'
              and c.delete_rule = 'NO ACTION'
              and p.table_name = 'EMPRESA'
       ) loop
           execute immediate
               'select count(*) from ' || dbms_assert.enquote_name(fk.table_name)
               || ' where ' || dbms_assert.enquote_name(fk.column_name) || ' = :id'
               || ' and rownum = 1'
               into l_existe
               using to_number(:P16_ID_EMPRESA);
           if l_existe > 0 then
               return false;
           end if;
       end loop;
       return true;
   end;
   ```
   - *Validation › Always Execute*: **On**. O botão `DELETE` tem *Execute Validations* = Não, e isso pula todas as validações que não têm *Always Execute*. Sem ele, esta validação nunca roda.
   - *Error › Error Message*: `Esta empresa tem colaboradores, departamentos ou outros cadastros vinculados e não pode ser removida. Para tirá-la de uso, desligue a Situação.`
   - *Error › Display Location*: **Inline in Notification**
   - *Error › Associated Item*: deixe **vazio** (o erro é da empresa, não de um campo)
   - *Server-side Condition › When Button Pressed*: **DELETE** (sem isso, ela rodaria também no Criar e no Salvar e impediria salvar a Corlix)
3. Clique em **Save**.

Hoje cerca de 12 tabelas apontam para `EMPRESA` (colaboradores, cargos, departamentos, comunicados, equipes, histórico de carreira, logs…). Em vez de listar cada uma, a validação lê as FKs no dicionário do schema, então uma tabela nova com FK para `EMPRESA` entra sozinha. As FKs com `ON DELETE CASCADE` ficam de fora, porque nelas o banco apaga os filhos e não há erro.

**Confira:** abra a Corlix pelo lápis › **Remover** › confirme. Aparece a mensagem no topo do modal e a Corlix continua na lista. **Só faça este teste depois de conferir no export que a validação existe** (abaixo): sem ela, o Remover tenta apagar a empresa de verdade.

### 6.1.3 Conferir no export

Depois de salvar, exporte a página (ou cole o APEXlang) e procure os dois blocos. Eles devem aparecer assim:

```
validation cnpj-não-cadastrado (
    name: CNPJ não cadastrado
    execution {
        sequence: 15
    }
    validation {
        type: functionBodyReturningBoolean
        plsqlFunctionBody: …
    }
    error {
        errorMessage: Já existe uma empresa cadastrada com este CNPJ.
        displayLocation: inlineWithField
        associatedItem: @P16_CNPJ
    }
)

validation empresa-sem-vínculos (
    name: Empresa sem vínculos
    execution {
        sequence: 40
    }
    validation {
        type: functionBodyReturningBoolean
        plsqlFunctionBody: …
        alwaysExecute: true
    }
    error {
        errorMessage: Esta empresa tem colaboradores…
        displayLocation: inlineInNotification
    }
    serverSideCondition {
        whenButtonPressed: @delete
    }
)
```

Se o bloco não aparecer, a validação não foi salva (faltou o **Save**). Se aparecer sem `alwaysExecute: true` ou sem `whenButtonPressed: @delete`, volte ao passo 2 da 6.1.2.

## 7. Rodapé

### 7.1 Aviso e fundo

Selecione a região **Buttons** (slot Dialog Footer):
- *Identification › Title*: `Ações do formulário` (fica só para leitores de tela)
- *Source › HTML Code*: `<p class="cx-form-modal-rodape__nota">Campos marcados com * são obrigatórios.</p>`
- *Appearance › CSS Classes*: `cx-form-modal-rodape`

No Buttons Container, o HTML da região fica na coluna do meio: à esquerda dele vem o Remover (só na edição) e à direita, os botões do slot Next.

### 7.2 Botões

| Botão | *Layout › Slot* | Seq | *Identification › Label* | *Appearance* |
|---|---|---|---|---|
| `DELETE` | Delete (mantém) | 20 | Remover | Template Text, sem Hot; *Template Options › Type*: **Danger** |
| `CANCEL` | **Next** (era Close) | 10 | Cancelar | Template Text, sem Hot |
| `SAVE` | Next | 30 | Salvar alterações | Template Text, **Hot** |
| `CREATE` | Next | 40 | Criar empresa | Template Text, **Hot** |

No `DELETE`, o *Type* **Danger** fica em *Appearance › Template Options*: no diálogo, escolha *Type* = **Danger** e mantenha **Use Template Defaults** marcado (confirmar no 26.1.5). Só o *Template* Text não basta: sem o Danger, o Remover sai cinza como o Cancelar. No export, a opção aparece como `t-Button--danger` em `templateOptions`, como no botão Estornar da página 18.

`SAVE` e `CREATE` nunca aparecem juntos (condição em `P16_ID_EMPRESA`), então o modal tem uma ação principal por vez. A ação dos botões não muda.

### 7.3 Confirmação do Remover em português

O `DELETE` usa a mensagem `&APP_TEXT$DELETE_MSG!RAW.`, que no app sai em inglês ("Would you like to perform this delete action?", visto em 27/10/2026). No botão `DELETE`:
- *Confirmation › Message*: `Remover esta empresa? Esta ação não pode ser desfeita.`
- *Confirmation › Style*: **Danger** (mantém)

**Confira:** **Remover** abre a pergunta em português, com o botão vermelho "Remover".

## 8. Teste

Recarregue com **Ctrl+Shift+R** (Cmd+Shift+R no Mac) e abra a página 15.

1. **+ Nova empresa** abre o modal "Nova empresa": seções Identificação, Contato e endereço, Logotipo e situação; `*` vermelho nos obrigatórios, "(opcional)" nos opcionais, nenhum "Required".
2. Grade como no protótipo: CNPJ e Data de abertura; Razão social; Nome fantasia; E-mail e Telefone; CEP, Logradouro e Número; Complemento e Bairro; Cidade e UF; Logotipo e Situação.
3. Situação nasce **Ativa**, com "Novas empresas nascem ativas." embaixo. Logotipo em dropzone. Data de abertura com ícone de calendário.
4. Rodapé cinza-claro com "Campos marcados com * são obrigatórios." à esquerda e **Cancelar** + **Criar empresa** à direita.
5. Digite um CNPJ real e saia do campo: razão social, nome fantasia, data de abertura, telefone e endereço são preenchidos.
6. Digite `00.000.000/0000-00`: aparece "Não encontramos este CNPJ…" embaixo do campo.
7. Apague o endereço e digite `01310-100` no CEP: Logradouro, Bairro, Cidade e UF (SP na lista) são preenchidos e o cursor vai para Número.
8. Clique em **Criar empresa** com o telefone `(11) 98765`: aparece "Informe o telefone com DDD…" embaixo do campo.
9. Feche com **Cancelar** e abra a Corlix pelo lápis: título "Editar empresa", **Remover** em vermelho à esquerda, **Salvar alterações** à direita; mudar o CNPJ não preenche nada.
10. Em **+ Nova empresa**, digite o CNPJ da Corlix e preencha o resto: **Criar empresa** mostra "Já existe uma empresa cadastrada com este CNPJ." embaixo do campo. Ao editar a própria Corlix, **Salvar alterações** não acusa nada.
11. Abra a Corlix, que tem colaboradores, e clique em **Remover** › confirme: aparece "Esta empresa tem colaboradores…" no topo do modal, e a empresa continua na lista.
12. Com um usuário fora da equipe do Corlix Hub, a página 16 não abre ("Acesso restrito à equipe do Corlix Hub.").

Se for gravar uma empresa de teste para conferir o fluxo completo, apague-a depois pelo Remover.

## Se não funcionar

| Sintoma | Causa | Correção |
|---|---|---|
| "Component P16_… cannot be rendered… Column 13" | *Start New Row* = Não depois de uma linha cheia | Passo 4.1: confira a coluna "Start New Row" |
| Mesmo erro de Column 13 em "Contato e endereço", com o Start New Row certo | E-mail e CEP com as sequências trocadas, Bairro com *Column* = 6 em vez de *Column Span*, ou UF sem span | Passo 4.1: os três pontos depois da tabela |
| "Component P16_BAIRRO cannot be rendered… Column 11 with a Column Span of 6" | O Bairro vem logo depois de CEP + Logradouro (3 + 7 = 10): ficou com uma sequência menor que a do Número, ou igual à dele (com sequências iguais, a ordem não é garantida) | Passo 4.1: sequências 50 a 90 diferentes entre si, na ordem Número, Complemento, Bairro, Cidade, UF. Não use o "Automatic" que a mensagem sugere: ele desfaz a grade |
| O CNPJ não preenche nada e o console (F12) não mostra nenhum erro nem requisição a `brasilapi.com.br` | A ação da DA "Dados por CNPJ" ficou como **Show**, com o código em *Affected Elements* | Passo 5.1: *Action* = **Execute JavaScript Code**, código em *Settings › Code* |
| UF fica vazia só para empresas de MG | `MG` não está na lista (`MS` digitado duas vezes) | Passo 4.4: confira as 27 siglas |
| Campos estreitos | *Width* ainda com `32` (no Logotipo, `30`) | Passo 4.1 |
| Situação numa linha própria, abaixo do Logotipo | Logotipo sem span 8, ou Situação com *Start New Row* = Sim ou sem span 4 | Passo 4.1 |
| Aparece "Status da Empresa" com rótulo flutuante e sem a dica "Novas empresas nascem ativas." | Label, template e *Inline Help* do `P16_STATUS` não foram trocados | Passos 4.1 e 4.6 |
| CNPJ e CEP sem a dica embaixo | *Inline Help Text* vazio | Passo 4.1, coluna "Inline Help Text" |
| Erro ao salvar com logotipo, ou o logotipo não grava, e o export mostra `mimeTypeColumn: image/png,…` | A lista de tipos foi digitada em *Storage › MIME Type Column* (o Image Upload não tem *File Types*) | Passo 4.5: apague o *MIME Type Column* |
| Remover cinza, igual ao Cancelar | Falta *Template Options › Type* = Danger | Passo 7.2 |
| Continua "Required" embaixo do campo, sem `*` | CSS antigo ou classe `cx-form-modal` fora da região do form | Passo 1 (Ctrl+Shift+R) e passo 3 |
| Título do modal aparece como `&P16_TITULO.` | Computação fora do Before Header, ou o item não existe | Passo 2.1, itens 1 e 2 |
| Ao editar, o cabeçalho diz "Nova empresa" (ou o contrário), embora `P16_TITULO` esteja certo (visto em 27/10/2026) | Sem o JS do Page Load, o cabeçalho usa o `P16_TITULO` que ficou na sessão da abertura anterior | Passo 2.1, item 3 |
| Cabeçalho do modal vazio, mas `document.title` do iframe é "Nova empresa" (visto em 27/10/2026) | O título do diálogo é definido antes de o item ter valor; a substituição no *Title* não chega ao cabeçalho | Passo 2.1, item 3: título pelo *Execute when Page Loads* |
| `ORA-01400: cannot insert NULL into ("…"."EMPRESA"."DATA_CRIACAO")` | O script do passo 0 não rodou | Passo 0 |
| "Logradouro must have some value" com o endereço preenchido | A DA de desabilitar ainda existe | Passo 5.2, item 1 |
| O CNPJ não preenche nada e o console (F12) mostra `Content Security Policy` ou `CORS` | O app bloqueia chamadas a `brasilapi.com.br` | Libere o domínio em *Shared Components › Security Attributes › Content Security Policy* (confirmar no 26.1.5) ou preencha à mão |
| "Não encontramos este CNPJ…" com um CNPJ válido | BrasilAPI fora do ar ou limite de consultas | Preencha à mão; tente de novo depois |
| UF fica vazia depois do CEP ou do CNPJ | Lista com *Return Value* diferente da sigla | Passo 4.4: *Return Value* = sigla |
| "Informe o CEP com 8 dígitos." ao editar a Corlix | Dado antigo com 7 dígitos | Corrija o CEP da empresa (passo 6) |
| "Complemento (opcional) must have at most 30 characters" depois de digitar o CNPJ | Coluna e item ainda com 30 | Passo 0.1: script 02 e *Maximum Length* 100 |
| `ORA-12899: value too large for column … COMPLEMENTO` | O item foi para 100, mas o script 02 não rodou | Passo 0.1 |
| `ORA-12899: value too large for column … CEP/TELEFONE` | A computação do passo 6 não rodou (*Point* diferente de After Submit) | Passo 6, item 2 |
| `ORA-02292: integrity constraint … violated - child record found` ao remover | A validação "Empresa sem vínculos" não existe, não está com *Always Execute* = On ou a condição não é o botão DELETE | Passo 6.1.2 |
| "Já existe uma empresa cadastrada com este CNPJ." ao salvar a própria empresa | `P16_ID_EMPRESA` vazio no submit | Confira que o item oculto tem a fonte `ID_EMPRESA` do form (passo 6.1.1) |
| O logotipo some depois de salvar | *Storage › Type* ainda em `APEX_APPLICATION_TEMP_FILES` | Passo 4.5 |
| Rodapé sem fundo cinza | O template do modal não usa `.t-Dialog-footer` no 26.1.5 | Inspecione o rodapé (F12), registre aqui a classe real e ajuste o seletor no `custom.css` §16 |
