# Colaboradores · passo a passo no APEX

Este guia monta a página 12 (**Colaboradores**) exatamente igual ao protótipo `pen_dev/Colaboradores · visão de administração.png`, no App Builder do **Oracle APEX 26.1.5**. A descrição da tela está em [`docs/ai-context/07-design-pen-dev.md`](../../docs/ai-context/07-design-pen-dev.md) §4.4.

A alteração é feita no Builder. O backup diário trará o resultado para `corlixhub/pages/p00012-colaboradores.apx` na branch `DEV`.

> [!IMPORTANT]
> No APEX 26.1.5, o painel de propriedades **não tem a aba "Attributes" separada** (os atributos ficam dentro do próprio painel ao selecionar a região ou coluna na árvore *Rendering*). Passos marcados com **(confirmar no 26.1.5)** detalham o caminho exato nesta versão.

---

### O que muda

| Antes | Depois (protótipo) |
|---|---|
| Página placeholder com apenas a região Breadcrumb | Página completa com **Faceted Search** à esquerda e **Classic Report** à direita |
| Sem filtros nem busca | 5 facetas: campo de busca global, Situação, Empresa, Departamento e Perfil de acesso |
| Sem listagem de pessoas | Tabela estilizada com avatar circular (foto/iniciais), nome em link com e-mail, login, vínculo completo (com alerta para incompletos), etiquetas de perfil e badges de status |
| Sem botão de ação | Cabeçalho com faixa branca e botão primário escuro **+ Novo colaborador** (para administradores e RH) |

---

## 1. Banco de dados (View da listagem)

Antes de abrir o Builder, execute [00_fn_colab_tem_papel.sql](./00_fn_colab_tem_papel.sql) e depois a view abaixo. Se já criou a função durante o diagnóstico, basta recriar a view. No SQL Commands, execute um comando por vez e omita a linha isolada `/` da função, preservando `end;`.

1. No menu do APEX, acesse **SQL Workshop › SQL Scripts** (ou utilize o SQL Commands).
2. Execute o conteúdo do arquivo [`01_vw_colaboradores_lista.sql`](./01_vw_colaboradores_lista.sql):
   ```sql
   create or replace force editionable view vw_colaboradores_lista as
   select c.id_colaborador,
          c.nome_completo,
          c.email,
          c.login_apex,
          c.primeiro_nome,
          c.ultimo_nome,
          c.foto_url,
          case
            when c.imagem_perfil is not null then 'S'
            else 'N'
          end as tem_imagem,
          upper(
            substr(coalesce(trim(c.primeiro_nome), trim(c.nome_completo), 'C'), 1, 1) ||
            coalesce(
              substr(trim(c.ultimo_nome), 1, 1),
              substr(trim(substr(c.nome_completo, instr(c.nome_completo, ' ', -1) + 1)), 1, 1),
              ''
            )
          ) as iniciais,
          c.id_empresa,
          nvl(e.nome_fantasia, 'Sem vínculo') as empresa,
          c.id_departamento,
          nvl(d.nome, 'Sem departamento') as departamento,
          c.id_cargo,
          nvl(cg.nome, 'Sem cargo') as cargo,
          case
            when c.id_empresa is not null and c.id_departamento is not null then
              e.nome_fantasia || ' · ' || d.nome
            when c.id_empresa is not null then
              e.nome_fantasia
            else
              'Sem vínculo'
          end as vinculo_linha1,
          case
            when c.id_empresa is not null and c.id_cargo is not null then
              cg.nome
            else
              'Cadastro incompleto'
          end as vinculo_linha2,
          case
            when c.id_empresa is null or c.id_departamento is null or c.id_cargo is null then
              'S'
            else
              'N'
          end as fl_sem_vinculo,
          case
            when c.id_empresa is null or c.id_departamento is null or c.id_cargo is null then
              'cx-colab-vinculo--alerta'
            else
              ''
          end as classe_vinculo,
          case
            when c.id_empresa is null or c.id_departamento is null or c.id_cargo is null then
              '<span class="fa fa-warning" aria-hidden="true"></span> '
            else
              ''
          end as icone_vinculo,
          case
            when exists (
              select 1 from cargo_papel cp
               where cp.id_cargo = c.id_cargo
                 and cp.cd_papel in ('equipe-do-corlix-hub', 'admin-rh', 'diretoria')
            ) or (fn_colab_tem_papel(c.login_apex, 'equipe-do-corlix-hub', to_number(v('APP_ID') default 100 on conversion error)) = 1 or fn_colab_tem_papel(c.login_apex, 'admin-rh', to_number(v('APP_ID') default 100 on conversion error)) = 1) then 'Administrador'
            when exists (
              select 1 from cargo_papel cp
               where cp.id_cargo = c.id_cargo
                 and cp.cd_papel in ('publicador-de-conteudo', 'publicador-de-conteúdo')
             ) or (fn_colab_tem_papel(c.login_apex, 'publicador-de-conteudo', to_number(v('APP_ID') default 100 on conversion error)) = 1 or fn_colab_tem_papel(c.login_apex, 'publicador-de-conteúdo', to_number(v('APP_ID') default 100 on conversion error)) = 1) then 'Publicador de conteúdo'
            else 'Colaborador'
          end as perfil,
          case
            when exists (
              select 1 from cargo_papel cp
               where cp.id_cargo = c.id_cargo
                 and cp.cd_papel in ('equipe-do-corlix-hub', 'admin-rh', 'diretoria')
            ) or (fn_colab_tem_papel(c.login_apex, 'equipe-do-corlix-hub', to_number(v('APP_ID') default 100 on conversion error)) = 1 or fn_colab_tem_papel(c.login_apex, 'admin-rh', to_number(v('APP_ID') default 100 on conversion error)) = 1) then '<span class="cx-etiqueta">Administrador</span>'
            when exists (
              select 1 from cargo_papel cp
               where cp.id_cargo = c.id_cargo
                 and cp.cd_papel in ('publicador-de-conteudo', 'publicador-de-conteúdo')
            ) or (fn_colab_tem_papel(c.login_apex, 'publicador-de-conteudo', to_number(v('APP_ID') default 100 on conversion error)) = 1 or fn_colab_tem_papel(c.login_apex, 'publicador-de-conteúdo', to_number(v('APP_ID') default 100 on conversion error)) = 1) then '<span class="cx-etiqueta">Publicador de conteúdo</span>'
            else 'Colaborador'
          end as perfil_html,
          case when c.status = true then 'Ativa' else 'Inativa' end as situacao,
          case when c.status = true then 'sucesso' else 'neutro' end as situacao_classe
     from colaborador c
     left join empresa e      on e.id_empresa = c.id_empresa
     left join departamento d on d.id_departamento = c.id_departamento
     left join cargo cg       on cg.id_cargo = c.id_cargo
    where (
      v('G_ID_EMPRESA') is null
      or c.id_empresa = to_number(v('G_ID_EMPRESA') default null on conversion error)
    );
   ```

3. Confira se a view está válida no SQL Commands:
   ```sql
   select count(*) from vw_colaboradores_lista
   ```

---

## 2. CSS do Módulo

Em *Shared Components › Static Application Files*, suba os dois arquivos:
- `modulos/colaboradores/colaboradores.css`
- `modulos/colaboradores/colaboradores.min.css`

*(Caso prefira unificar no `custom.css`, basta colar o conteúdo de `colaboradores.css` no final do arquivo `corlixhub/shared-components/static-files/custom.css` e no `.min.css` correspondente).*

---

## 3. Configuração da Página 12

Abra a **Página 12** no Page Designer. Selecione o nó raiz da página (**Page 12: Colaboradores**):

- *Security › Authorization Scheme*: **ADMIN_RH** (confirmar no 26.1.5). Esta é a listagem administrativa e deve usar a mesma autorização da página 14; confira no export `security { authorizationScheme: @admin-rh }`. A proteção por checksum permanece habilitada.
- *Identification › Title*: `Colaboradores`
- *Appearance › Page CSS Classes*: `cx-colaboradores-pagina`
- *CSS › File URLs*:
  ```
  #APP_FILES#modulos/colaboradores/colaboradores#MIN#.css
  ```

---

## 4. Cabeçalho da Página

### 4.1 Apagar o breadcrumb antigo
Na árvore *Rendering*, clique com o botão direito na região **Breadcrumb** (slot Breadcrumb Bar) › **Delete**.

### 4.2 Criar o cabeçalho moderno com botão de ação
1. Clique com o botão direito em **Breadcrumb Bar** › **Create Region** *(confirmar no 26.1.5)*.
2. Defina as propriedades da nova região:
   - *Identification › Name*: `Cabeçalho`
   - *Identification › Type*: **Dynamic Content**
   - *Source › Language*: **PL/SQL**
   - *Source › PL/SQL Function Body returning a CLOB*:
     ```plsql
     return '<div class="cx-cabecalho-pagina cx-cabecalho-pagina--acoes">'
         || '<div class="cx-cabecalho-pagina__texto">'
         || '<h1 class="cx-cabecalho-pagina__titulo">Colaboradores</h1>'
         || '<p class="cx-cabecalho-pagina__descricao">Encontre pessoas e gerencie contas, vínculos e perfis de acesso.</p>'
         || '</div>'
         || '<div class="cx-cabecalho-pagina__acoes">'
         || case
              when apex_authorization.is_authorized('ADMIN_RH') then
                   '<a class="t-Button t-Button--hot t-Button--iconLeft" href="'
                || apex_escape.html_attribute(apex_page.get_url(p_page => 14, p_clear_cache => '14'))
                || '"><span class="t-Icon t-Icon--left fa fa-plus" aria-hidden="true"></span>'
                || '<span class="t-Button-label">Novo colaborador</span></a>'
            end
         || '</div>'
         || '</div>';
     ```
   - *Appearance › Template*: **Blank with Attributes (No Grid)**

---

## 5. Região de Resultados (Classic Report)

1. Na árvore *Rendering*, clique com o botão direito em **Body** › **Create Region**.
2. Defina as propriedades da região:
   - *Identification › Title*: `Colaboradores`
   - *Identification › Type*: **Classic Report**
   - *Advanced › Static ID*: `colaboradores`
   - *Layout › Sequence*: `20` (confirmar no 26.1.5; no export: `sequence: 20`)
   - *Layout › Column*: `4`
   - *Layout › Column Span*: `9`
   - *Layout › Start New Row*: `No` *(para ficar ao lado das facetas)*
   - *Appearance › Template*: **Standard**
   - *Appearance › Template Options*:
     - *Header*: **Hidden**
     - *Style*: **Remove UI Decoration**
     - Marque **Remove Body Padding**
   - *Appearance › CSS Classes*: `cx-relatorio`
   - *Source › Type*: **SQL Query**
   - *Source › SQL Query*:
     ```sql
     select id_colaborador,
            nome_completo,
            email,
            login_apex,
            primeiro_nome,
            ultimo_nome,
            foto_url,
            tem_imagem,
            iniciais,
            id_empresa,
            empresa,
            id_departamento,
            departamento,
            id_cargo,
            cargo,
            vinculo_linha1,
            vinculo_linha2,
            fl_sem_vinculo,
            classe_vinculo,
            icone_vinculo,
            perfil,
            perfil_html,
            situacao,
            situacao_classe
       from vw_colaboradores_lista
     ```
3. Nos atributos do relatório (*Attributes* na árvore sob a região):
   - *Pagination › Type*: **Row Ranges X to Y of Z (with pagination)** (confirmar o rótulo no 26.1.5; o export deve ter `rowRangesXToYOfZWithPagination`, não `rowRangesXToYOfZNoPagination`)
   - *Pagination › Number of Rows*: `15`
   - *Messages › When No Data Found*: `Nenhum colaborador encontrado.`

### 5.1 Configuração das Colunas do Relatório

Selecione cada coluna da região em *Columns* e configure:

| Coluna | Type | Heading | Propriedades e Formatação |
|---|---|---|---|
| `NOME_COMPLETO` | **Link** | `Pessoa` | **Sortable**: Yes<br>**Default Sequence**: 1<br>**Default Direction**: Ascending<br>**Escape Special Characters**: No<br>**Link › Target**: Page `14`<br>**Link › Set Items**: `P14_ID_COLABORADOR` = `#ID_COLABORADOR#`<br>**Link › Clear Cache**: `14`<br>**Link › Link Text** (confirmar no 26.1.5):<br>`<span class="cx-colab-pessoa"><span class="cx-avatar"><img src="#APP_FILES#Fotos Colaboradores/#FOTO_URL!ATTR#" alt="" onerror="this.remove();" loading="lazy">#INICIAIS!HTML#</span><span class="cx-colab-pessoa__info"><span class="cx-colab-pessoa__nome">#NOME_COMPLETO!HTML#</span><span class="cx-colab-pessoa__email">#EMAIL!HTML#</span></span></span>` |
| `LOGIN_APEX` | **Plain Text** | `Login` | **Sortable**: Yes |
| `VINCULO_LINHA1` | **Plain Text** | `Vínculo` | **Sortable**: Yes<br>**Escape Special Characters**: No<br>**Column Formatting › HTML Expression**:<br>`<div class="cx-colab-vinculo #CLASSE_VINCULO!ATTR#"><span class="cx-colab-vinculo__emp-dept">#ICONE_VINCULO!RAW##VINCULO_LINHA1!HTML#</span><span class="cx-colab-vinculo__cargo">#VINCULO_LINHA2!HTML#</span></div>` |
| `PERFIL` | **Plain Text** | `Perfil` | **Sortable**: Yes<br>**Escape Special Characters**: No<br>**Column Formatting › HTML Expression**:<br>`#PERFIL_HTML!RAW#` |
| `SITUACAO` | **Plain Text** | `Situação` | **Sortable**: Yes<br>**Escape Special Characters**: No<br>**Column Formatting › HTML Expression**:<br>`<span class="cx-badge cx-badge--#SITUACAO_CLASSE!ATTR#">#SITUACAO!HTML#</span>` |
| *Demais colunas* | **Hidden** | — | Deixe como **Hidden**: `ID_COLABORADOR`, `EMAIL`, `PRIMEIRO_NOME`, `ULTIMO_NOME`, `FOTO_URL`, `TEM_IMAGEM`, `INICIAIS`, `ID_EMPRESA`, `EMPRESA`, `ID_DEPARTAMENTO`, `DEPARTAMENTO`, `ID_CARGO`, `CARGO`, `VINCULO_LINHA2`, `FL_SEM_VINCULO`, `CLASSE_VINCULO`, `ICONE_VINCULO`, `PERFIL_HTML`, `SITUACAO_CLASSE`. |


**Coluna Pessoa:** como `NOME_COMPLETO` é do tipo **Link**, preencha o HTML em **Link › Link Text**, não em **HTML Expression**. O APEX gera a tag `<a>` com o destino e o checksum; não coloque outra tag `<a>` dentro do conteúdo nem use `&LINK.`. As demais colunas **Plain Text** continuam usando **HTML Expression**.

**Validação no Builder (pendente):** salve e execute a página; confira avatar, nome e e-mail e clique na Pessoa para verificar a navegação à página 14 com o colaborador correto. O link envolve todo o conteúdo da célula Pessoa. Se **Link Text** não aparecer, envie um print da árvore e das propriedades da coluna antes de tentar outro caminho.

Referência: [Oracle APEX 26.1 — Creating a Column Link in a Classic Report](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-classic-report-column-attributes.html).

---

## 6. Região de Facetas (Faceted Search)

A ordem final no Body deve ser **Filtros (10)** antes de **Colaboradores (20)**, independentemente da ordem em que as regiões foram criadas. Confirme ambos na mesma linha em desktop e o comportamento em tela estreita.

1. Na árvore *Rendering*, clique com o botão direito em **Body** › **Create Region**.
2. Defina as propriedades:
   - *Identification › Title*: `Filtros`
   - *Identification › Type*: **Faceted Search**
   - *Source › Filtered Region*: **Colaboradores** *(a região do Classic Report criada no passo 5)*
   - *Layout › Sequence*: `10` (confirmar no 26.1.5; no export: `sequence: 10`)
   - *Layout › Column*: `1`
   - *Layout › Column Span*: `3`
   - *Layout › Start New Row*: `Yes`
   - *Appearance › Template*: **Standard**
   - *Appearance › Template Options*:
     - *Header*: **Hidden**
     - *Style*: **Remove UI Decoration**
     - Marque **Remove Body Padding**
3. Nos atributos do Faceted Search (*Attributes* da região):
   - *Show Total Row Count*: **Yes**
   - *Show Current Facets*: **Yes**
   - *Show Charts*: **No**

### 6.1 Criar as 5 Facetas

Na árvore, clique com o botão direito no nó **Facets** da região Filtros › **Create Facet**:

#### Faceta 1: Busca Global
- *Identification › Name*: `P12_SEARCH`
- *Identification › Type*: **Search**
- *Settings › Value Placeholder*: `Nome, login ou e-mail`
- *Source › Database Column(s)*: `NOME_COMPLETO,LOGIN_APEX,EMAIL`

#### Faceta 2: Situação
- *Identification › Name*: `P12_SITUACAO`
- *Identification › Type*: **Checkbox Group**
- *Identification › Label*: `Situação`
- *Source › Database Column*: `SITUACAO`
- *Source › Data Type*: `VARCHAR2`
- *List Entries › Compute Counts*: **Yes**
- *List Entries › Show Counts*: **Yes**
- *List of Values › Type*: **Static Values**
- *List of Values › Static Values*:
  ```
  STATIC:Ativa;Ativa,Inativa;Inativa
  ```

#### Faceta 3: Empresa
- *Identification › Name*: `P12_EMPRESA`
- *Identification › Type*: **Checkbox Group**
- *Identification › Label*: `Empresa`
- *Source › Database Column*: `EMPRESA`
- *Source › Data Type*: `VARCHAR2`
- *List Entries › Compute Counts*: **Yes**
- *List Entries › Show Counts*: **Yes**
- *List of Values › Type*: **Distinct Values**

#### Faceta 4: Departamento
- *Identification › Name*: `P12_DEPARTAMENTO`
- *Identification › Type*: **Checkbox Group**
- *Identification › Label*: `Departamento`
- *Source › Database Column*: `DEPARTAMENTO`
- *Source › Data Type*: `VARCHAR2`
- *List Entries › Compute Counts*: **Yes**
- *List Entries › Show Counts*: **Yes**
- *List of Values › Type*: **Distinct Values**

#### Faceta 5: Perfil de acesso
- *Identification › Name*: `P12_PERFIL`
- *Identification › Type*: **Checkbox Group**
- *Identification › Label*: `Perfil de acesso`
- *Source › Database Column*: `PERFIL`
- *Source › Data Type*: `VARCHAR2`
- *List Entries › Compute Counts*: **Yes**
- *List Entries › Show Counts*: **Yes**
- *List of Values › Type*: **Static Values**
- *List of Values › Static Values*:
  ```
  STATIC:Administrador;Administrador,Publicador de conteúdo;Publicador de conteúdo,Colaborador;Colaborador
  ```

---

## 7. Salvar e Conferir

1. Clique em **Save** no canto superior direito.
2. Execute a página (**Run** / tecla `F8`).

---

## 8. Checklist de Validação Visual e Funcional

Compare com `pen_dev/Colaboradores · visão de administração.png`:

- [ ] **Faixa de Cabeçalho**: Título `Colaboradores`, descrição clara e botão escuro **+ Novo colaborador** à direita.
- [ ] **Ação do Botão**: Clicar em **+ Novo colaborador** abre o formulário da Página 14 limpo.
- [ ] **Painel de Facetas**:
  - [ ] Campo de busca com ícone de lupa e placeholder *"Nome, login ou e-mail"*.
  - [ ] Contagens dinâmicas exibidas ao lado de cada opção das facetas (ex.: `Ativa 7`, `Inativa 1`).
  - [ ] Selecionar uma faceta filtra os registros instantaneamente sem recarregar a página toda.
- [ ] **Tabela de Colaboradores**:
  - [ ] **Avatar**: Mostra a foto ou as iniciais em caixa alta com fundo azul-claro (`--cx-primaria-suave`).
  - [ ] **Pessoa**: Nome em link azul petróleo (`--cx-primaria`), com e-mail corporativo em cinza logo abaixo.
  - [ ] **Edição**: Clicar no nome do colaborador navega para a Página 14 carregando os dados daquele colaborador (`P14_ID_COLABORADOR`).
  - [ ] **Vínculo**: Linha 1 exibe *Empresa · Departamento* e Linha 2 exibe o *Cargo*.
  - [ ] **Sem vínculo**: Usuários com cadastro incompleto exibem o ícone `⚠ Sem vínculo` em âmbar e subtítulo *Cadastro incompleto*.
  - [ ] **Perfil**: Perfis especiais exibem a etiqueta neutra cinza (`Publicador de conteúdo`, `Administrador`) e os demais como texto simples `Colaborador`.
  - [ ] **Situação**: Badge com ponto verde para `Ativa` e ponto cinza para `Inativa`.
- [ ] **Paginação**: Formato `1 – 8 de 8` no rodapé à direita.

### Diagnóstico das contagens de perfil — 08/11/2026

Confirmado no ambiente: a leitura simples da view funciona; a agregação com GROUPING SETS falha ao incluir PERFIL e funciona sem ele. A tentativa com ROWNUM também falhou. O teste com FN_COLAB_TEM_PAPEL e GROUPING SETS executou sem erro, com 309 linhas retornando zero e total 309. Isso valida a execução da função, mas não comprova a classificação dos usuários.

A view agora chama a função baseada na API pública APEX_ACL.HAS_USER_ROLE em PERFIL e PERFIL_HTML. As condições de CARGO_PAPEL e os papéis consultados foram preservados. A causa interna exata do erro não foi confirmada.

Após recriar a view, execute:

```sql
select situacao, empresa, departamento, perfil, count(*) quantidade
  from vw_colaboradores_lista
 group by grouping sets (situacao, empresa, departamento, perfil, ())
```

Depois, na sessão da aplicação 100, teste as contagens e a seleção das facetas na página 12. Confira um colaborador com papel manual conhecido e outro com papel via CARGO_PAPEL. Compare a etiqueta do relatório com a faceta. A validação da view completa e da página permanece pendente.

A API depende do contexto de workspace. Não interprete os 309 zeros como prova de ausência de papéis: confira o APP_ID e um login com papel conhecido no mesmo contexto. Não altere o contexto de segurança dentro da função, não adicione cache e não suprima erros retornando zero.

Referência: [Oracle APEX 26.1 — APEX_ACL](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_ACL.html).

| Sintoma | Causa / diagnóstico | Correção proposta |
|---|---|---|
| ORA-00904: "APEX_260100"."WWV_FLOW_SECURITY": invalid identifier em Filtros | Reproduzido com GROUPING SETS incluindo PERFIL; sem PERFIL funciona. Causa interna ainda não confirmada | Criar 00_fn_colab_tem_papel.sql e recriar a view 01, isolando a consulta de ACL em PL/SQL. Teste isolado da função passou; validação da view completa e da página pendente |

## 8. Validação após a revisão do export de 08/11/2026

A revisão foi estática. Não marca como concluídos os testes de execução, segurança ou aparência.

### Autorização e isolamento

- A página 12 administrativa e o botão Novo colaborador usam **ADMIN_RH**, em alinhamento com a autorização da página 14 disponível no repositório.
- Na chamada PL/SQL use o **nome** do esquema, `ADMIN_RH`; `@admin-rh` é a referência do APEXlang. Não use ausência de empresa como permissão.
- Confira a autorização correspondente na entrada do menu. Teste acesso direto à página 12 com usuário autorizado e não autorizado.
- A view deste guia permite todas as empresas quando `G_ID_EMPRESA` é nulo. A autorização de página não corrige esse comportamento: não considere o isolamento validado até testar contas de duas empresas e uma sessão sem empresa. Para uma conta RH comum, empresa ausente não deve liberar dados de outras empresas; a política de acesso global precisa ser explícita.

### HTML e apresentação

- Em **Link Text**, o APEX gera a âncora: não inclua `<a>` nem `&LINK.`. O link envolve toda a célula Pessoa.
- Os exemplos da tabela usam `!HTML` para texto e `!ATTR` para valores dentro de atributos. `!RAW` fica restrito a `ICONE_VINCULO` e `PERFIL_HTML`, gerados com marcação fixa pela view; não acrescente dados livres a esses fragmentos sem escape.
- **Escape Special Characters = No** não torna dados seguros sozinho: mantenha os filtros explícitos dos exemplos. Teste nome, e-mail, departamento e cargo com caracteres como `&`, `<` e aspas: devem aparecer como texto, sem criar marcação.
- Confirme os arquivos estáticos no caminho `modulos/colaboradores/`, inclusive a variante minificada, e ausência de erro 404.
- Confira foto válida, foto ausente, iniciais, filtros à esquerda e relatório à direita.
- Com mais de 15 resultados, teste avançar e voltar páginas; após filtrar, confira total e navegação.

Referências: [escaping de substituições](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/controlling-output-escaping-in-substitution-strings.html) e [paginação de Classic Report](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-classic-report-attributes.html).

### Página 14 e filtros: testes pendentes

- O link para a página 14 está configurado, mas **edição ainda não foi comprovada**. O export disponível descreve cadastro e processos de criação de usuário/admissão.
- Primeiro confira os processos e condições da página 14. Em DEV, com registro de teste, verifique carregamento do ID, salvamento sem criar outro usuário nem outra admissão e comportamento de cancelamento. Se a página só suportar criação, não libere o link Pessoa como edição.
- Novo colaborador deve abrir a página 14 limpa e apenas para usuário autorizado.
- Combine Situação, Empresa, Departamento e **Perfil**, depois limpe os filtros e faça busca textual. Confirme ausência de ORA-00904 na requisição Ajax.
- A correção da ACL já está neste guia (§1): aplique a função `00_fn_colab_tem_papel.sql` e a view corrigida antes do teste. A consulta isolada da função passou com 309 zeros e total 309; isso não comprova a classificação de perfis. Valide um usuário com papel manual conhecido e outro com papel via cargo na sessão da app 100.

### Se não funcionar

| Sintoma | Causa / verificação | Ação |
|---|---|---|
| HTML Expression não aparece em NOME_COMPLETO | Coluna do tipo Link | Usar Link Text conforme §5.1; se não aparecer, obter print do painel antes de tentar outro caminho |
| Filtros aparecem abaixo do relatório | Sequência das regiões invertida | Filtros = 10, inicia linha, coluna 1; Colaboradores = 20, não inicia linha, coluna 4 |
| Total aparece sem navegação | Tipo NoPagination | Usar variante WithPagination e testar mais de 15 resultados |
| Botão aparece para conta sem empresa | Condição antiga usava G_ID_EMPRESA nulo como autorização | Usar somente ADMIN_RH e proteger a própria página |
| Nome abre cadastro em vez de edição | Página 14 ainda não validada para editar | Conferir processos da página 14 antes de liberar essa navegação |
