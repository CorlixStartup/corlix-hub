# Colaboradores · passo a passo no APEX

> **Situação atual e histórico:** consulte [Registro de implantação](./Registro-implantacao.md). O botão Novo colaborador continua pendente; as recomendações revistas estão registradas ali.

Este guia monta a página 12 (**Colaboradores**) com base no protótipo `pen_dev/Colaboradores · visão de administração.png`, no App Builder do **Oracle APEX 26.1.5**. A descrição da tela está em [`docs/ai-context/07-design-pen-dev.md`](../../docs/ai-context/07-design-pen-dev.md) §4.4.

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
| Sem botão de ação | Cabeçalho com faixa branca e botão primário escuro **+ Novo colaborador** (para usuários autorizados a cadastrar na página 14) |

---

## 1. Banco de dados (View da listagem)

**Ambiente atual:** função e view corrigidas já constam no backup e33f972. Não reinstale para ajustar o botão.

Para instalação em outro ambiente, execute [00_fn_colab_tem_papel.sql](./00_fn_colab_tem_papel.sql) antes de [01_vw_colaboradores_lista.sql](./01_vw_colaboradores_lista.sql). O [instalador](./instalar.sql) mantém essa ordem no SQLcl. No SQL Commands, execute um comando por vez, sem a linha isolada `/` da função, preservando `end;`.

Os arquivos SQL são a fonte da instalação; não há cópia paralela da view neste guia. Confira compilação e contagens das facetas conforme o diagnóstico ao final.

**Isolamento pendente:** a view permite todas as empresas quando G_ID_EMPRESA é nulo. Não use esse comportamento como prova de autorização da equipe; valide a política de acesso global separadamente antes de considerar o isolamento concluído.

---

## 2. CSS do Módulo

Os dois arquivos já constam no backup. Somente em instalação nova ou atualização de CSS, publique em *Shared Components › Static Application Files*, mantendo os nomes com o prefixo `modulos/colaboradores/`:
- `modulos/colaboradores/colaboradores.css`
- `modulos/colaboradores/colaboradores.min.css`

Não duplique esses estilos no custom.css. Reutilize os tokens e classes existentes; publique CSS pelo Builder, mantendo o arquivo minificado em sincronia.

---

## 3. Configuração da Página 12

Abra a **Página 12** no Page Designer. Selecione o nó raiz da página (**Page 12: Colaboradores**):

- *Identification › Title*: `Colaboradores`
- *Appearance › Page CSS Classes*: `cx-colaboradores-pagina`
- *CSS › File URLs*:
  ```
  #APP_FILES#modulos/colaboradores/colaboradores#MIN#.css
  ```

---

## 4. Cabeçalho da Página

### Referências reutilizadas

- [Holerite — render_cabecalho](../holerite/02_pkg_holerite_ui.pkb): título e ações dentro do mesmo contêiner.
- [Ponto eletrônico — render_cabecalho](../ponto-eletronico/04_pkg_ponto_ui.pkb): cx-cabecalho-pagina__texto e cx-cabecalho-pagina__acoes, URL com checksum e escape.
- [Histórico de carreira — UI](../historico-carreira/08_pkg_historico_carreira_ui.sql): padrões de renderização e integração.
- [Tema](../../docs/ai-context/04-tema-e-estilos.md): fa-plus já mapeia para Lucide; não instalar outra biblioteca.

**Retomada da página existente:** não recrie regiões. O botão nativo tentado não teve encaixe validado no template. A orientação abaixo mantém a ação dentro do cabeçalho, seguindo Holerite e Ponto. É uma proposta de ajuste, ainda pendente de teste visual no Builder.

Não aplique ADMIN_RH à página 12 inteira apenas para controlar esse botão. A página 14 atualmente exige ADMIN_RH; a condição da ação acompanha esse destino. Acesso adicional da equipe exige decisão explícita e alinhamento com o destino.

### 4.1 Apagar o breadcrumb antigo
Somente se ainda houver o breadcrumb antigo duplicado: na árvore Rendering, remova essa região. Preserve o Cabeçalho existente.

### 4.2 Configurar o cabeçalho com a ação no mesmo contêiner

Na página existente, selecione Cabeçalho e substitua a função abaixo. Se criou o botão nativo NOVO_COLABORADOR na tentativa anterior, remova apenas esse botão depois de conferir sua identificação, para evitar duplicação. Não remova ações de outros módulos.

Para instalação nova:
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

**Conferência:** use uma conta autorizada; deve existir uma única ação à direita do título, com fundo escuro, ícone Lucide Plus e texto branco. Teste a navegação ao cadastro limpo. Com usuário comum, a lista continua disponível e a ação não aparece. Teste tela estreita e foco pelo teclado. Se o resultado divergir, registre print e export atual antes de sugerir outra posição ou CSS; não declare o alinhamento concluído apenas pelo código.

---

## 5. Região de Resultados (Classic Report)

1. Na árvore *Rendering*, clique com o botão direito em **Body** › **Create Region**.
2. Defina as propriedades da região:
   - *Identification › Title*: `Colaboradores`
   - *Identification › Type*: **Classic Report**
   - *Advanced › Static ID*: `colaboradores`
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
3. Nas propriedades do Classic Report, use a busca do painel para localizar os atributos abaixo (confirmar agrupamento no 26.1.5):
   - *Pagination › Type*: **Row Ranges X to Y of Z com paginação** (confirmar rótulo no 26.1.5; export esperado: `rowRangesXToYOfZWithPagination`)
   - *Pagination › Number of Rows*: `15`
   - *Messages › When No Data Found*: `Nenhum colaborador encontrado.`

### 5.1 Configuração das Colunas do Relatório

Selecione cada coluna da região em *Columns* e configure. O link Pessoa abaixo documenta o destino existente; sua utilização como edição depende da revisão da página 14 descrita após a tabela.

| Coluna | Type | Heading | Propriedades e Formatação |
|---|---|---|---|
| `NOME_COMPLETO` | **Link** | `Pessoa` | **Sortable**: Yes<br>**Default Sequence**: 1<br>**Default Direction**: Ascending<br>**Escape Special Characters**: No<br>**Link › Target**: Page `14`<br>**Link › Set Items**: `P14_ID_COLABORADOR` = `#ID_COLABORADOR#`<br>**Link › Clear Cache**: `14`<br>**Link › Link Text** (confirmar no 26.1.5):<br>`<span class="cx-colab-pessoa"><span class="cx-avatar"><img src="#APP_FILES#Fotos Colaboradores/#FOTO_URL!ATTR#" alt="" onerror="this.remove();" loading="lazy">#INICIAIS!HTML#</span><span class="cx-colab-pessoa__info"><span class="cx-colab-pessoa__nome">#NOME_COMPLETO!HTML#</span><span class="cx-colab-pessoa__email">#EMAIL!HTML#</span></span></span>` |
| `LOGIN_APEX` | **Plain Text** | `Login` | **Sortable**: Yes |
| `VINCULO_LINHA1` | **Plain Text** | `Vínculo` | **Sortable**: Yes<br>**Escape Special Characters**: No<br>**Column Formatting › HTML Expression**:<br>`<div class="cx-colab-vinculo #CLASSE_VINCULO!ATTR#"><span class="cx-colab-vinculo__emp-dept">#ICONE_VINCULO!RAW##VINCULO_LINHA1!HTML#</span><span class="cx-colab-vinculo__cargo">#VINCULO_LINHA2!HTML#</span></div>` |
| `PERFIL` | **Plain Text** | `Perfil` | **Sortable**: Yes<br>**Escape Special Characters**: No<br>**Column Formatting › HTML Expression**:<br>`#PERFIL_HTML!RAW#` |
| `SITUACAO` | **Plain Text** | `Situação` | **Sortable**: Yes<br>**Escape Special Characters**: No<br>**Column Formatting › HTML Expression**:<br>`<span class="cx-badge cx-badge--#SITUACAO_CLASSE!ATTR#">#SITUACAO!HTML#</span>` |
| *Demais colunas* | **Hidden** | — | Deixe como **Hidden**: `ID_COLABORADOR`, `EMAIL`, `PRIMEIRO_NOME`, `ULTIMO_NOME`, `FOTO_URL`, `TEM_IMAGEM`, `INICIAIS`, `ID_EMPRESA`, `EMPRESA`, `ID_DEPARTAMENTO`, `DEPARTAMENTO`, `ID_CARGO`, `CARGO`, `VINCULO_LINHA2`, `FL_SEM_VINCULO`, `CLASSE_VINCULO`, `ICONE_VINCULO`, `PERFIL_HTML`, `SITUACAO_CLASSE`. |


**Coluna Pessoa:** como `NOME_COMPLETO` é do tipo **Link**, preencha o HTML em **Link › Link Text**, não em **HTML Expression**. O APEX gera a tag `<a>` com o destino e o checksum; não coloque outra tag `<a>` dentro do conteúdo nem use `&LINK.`. As demais colunas **Plain Text** continuam usando **HTML Expression**.

**Escape:** !HTML protege os textos livres e !ATTR os atributos. !RAW fica restrito aos fragmentos fixos de ícone e etiqueta da view. Teste caracteres especiais em nomes e vínculos sem produzir marcação.

**Página 14 — pendente:** o processo CREATE_USER disponível não está condicionado à inclusão. Revise também admissão, validações de senha e processamento do formulário antes de testar salvamento de registro existente. Receber o ID não comprova edição segura. Até validar, pode apresentar Pessoa como Plain Text usando o mesmo HTML em HTML Expression, sem link. Não considere esta revisão da p12 uma implementação do modo edição.

**Validação no Builder (pendente):** salve e execute a página; confira avatar, nome e e-mail e clique na Pessoa para verificar a navegação à página 14 com o colaborador correto. O link envolve todo o conteúdo da célula Pessoa. Se **Link Text** não aparecer, envie um print da árvore e das propriedades da coluna antes de tentar outro caminho.

Referência: [Oracle APEX 26.1 — Creating a Column Link in a Classic Report](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-classic-report-column-attributes.html).

---

## 6. Região de Facetas (Faceted Search)

Na página já montada, preserve as facetas existentes. Confira primeiro o resultado visual. **Somente se filtros e relatório estiverem em linhas incorretas**, ajuste Layout (confirmar no 26.1.5): Filtros sequence 10, coluna 1, span 3, Start New Row Yes; Colaboradores sequence 20, coluna 4, span 9, Start New Row No. Compare desktop e tela estreita antes de registrar resultado.

1. Na árvore *Rendering*, clique com o botão direito em **Body** › **Create Region**.
2. Defina as propriedades:
   - *Identification › Title*: `Filtros`
   - *Identification › Type*: **Faceted Search**
   - *Source › Filtered Region*: **Colaboradores** *(a região do Classic Report criada no passo 5)*
   - *Layout › Column*: `1`
   - *Layout › Column Span*: `3`
   - *Layout › Start New Row*: `Yes`
   - *Appearance › Template*: **Standard**
   - *Appearance › Template Options*:
     - *Header*: **Hidden**
     - *Style*: **Remove UI Decoration**
     - Marque **Remove Body Padding**
3. Nas propriedades do Faceted Search (confirmar agrupamento no 26.1.5):
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

Para verificar a view já instalada (ou após instalação nova), execute:

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
| ORA-00904: "APEX_260100"."WWV_FLOW_SECURITY": invalid identifier em Filtros | Reproduzido com GROUPING SETS incluindo PERFIL; sem PERFIL funciona. Causa interna ainda não confirmada | A função e a view corrigida já estão no backup. Em ambiente novo, instalar 00 e 01; no atual, testar antes de reinstalar. Teste isolado da função passou; validação da view completa e da página pendente |


## 9. Encerramento da tarefa

Atualize [Registro-implantacao.md](./Registro-implantacao.md) ao final de cada intervenção, conforme a regra 15 do [08](../../docs/ai-context/08-convencoes-e-pegadinhas.md). Registre referência reutilizada, alterações, aplicação no Builder, testes/evidências, falhas, pendências e próximo passo. Reindexe os casos se alterados. Não marque módulo concluído com botão, edição ou testes de isolamento ainda pendentes.

Esta revisão ajustou somente a documentação. O cabeçalho proposto, escape e paginação ainda precisam de aplicação e validação pelo time. A instalação de ACL está confirmada pelo backup; a validação final das facetas permanece pendente.
