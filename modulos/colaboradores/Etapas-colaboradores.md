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

### 4.2 Instalar o package de UI

Para a página já montada, execute somente os dois arquivos novos, nesta ordem:

1. [02_pkg_colaboradores_ui.pks](./02_pkg_colaboradores_ui.pks) — especificação.
2. [02_pkg_colaboradores_ui.pkb](./02_pkg_colaboradores_ui.pkb) — corpo.

Use SQL Workshop › SQL Scripts ou SQLcl. No SQL Commands, execute um CREATE OR REPLACE por vez, omitindo somente a linha isolada `/` e preservando os pontos e vírgulas internos. O instalador completo inclui esses arquivos depois da função e da view; não é necessário reinstalar tudo no ambiente atual.

Confira a compilação:

```sql
select type, line, position, text
  from user_errors
 where name = 'PKG_COLABORADORES_UI'
 order by type, sequence
```

O resultado deve estar vazio. Confira também PACKAGE e PACKAGE BODY com STATUS = VALID:

```sql
select object_type, status
  from user_objects
 where object_name = 'PKG_COLABORADORES_UI'
   and object_type in ('PACKAGE', 'PACKAGE BODY')
```

Não altere a região antes de resolver eventuais erros de compilação. Não foi possível compilar no banco a partir desta tarefa: esses testes devem ser feitos no ambiente do projeto.

### 4.3 Chamar o package no Builder

1. Na página 12, selecione a região **Cabeçalho** existente.
2. Mantenha **Type = Dynamic Content**, posição **Breadcrumb Bar** e template **Blank with Attributes (No Grid)**, como no cabeçalho do Holerite.
3. Substitua todo o corpo PL/SQL da região por:

   ```plsql
   return pkg_colaboradores_ui.render_cabecalho;
   ```

4. Se a tentativa anterior criou o botão nativo NOVO_COLABORADOR, confira sua identificação e remova somente essa duplicata. O package renderiza a ação; não existe uma segunda configuração de botão no Builder.
5. Salve e execute com uma conta autorizada.

A autorização da ação está no package e usa o nome ADMIN_RH, em alinhamento com a página 14. Mantenha a proteção no destino; não restrinja a página 12 inteira para esconder o botão. O package usa URL com checksum e escape de atributo. O tema já converte fa-plus no Lucide Plus; não instalar biblioteca adicional.

**Arquitetura adotada:** o HTML personalizado do cabeçalho fica no package. Classic Report e Faceted Search continuam nativos, pois as facetas dependem da fonte SQL filtrável. Essa composição preserva busca, contagens e paginação existentes; não há substituição da listagem por HTML manual. O CLOB é local à chamada, seguindo o mesmo padrão de montagem incremental dos módulos de referência e evitando estado compartilhado desnecessário para uma única função.

**Conferência:** use uma conta autorizada; deve existir uma única ação à direita do título, com fundo escuro, ícone Lucide Plus e texto branco. Teste a navegação ao cadastro limpo. Com usuário comum, a lista continua disponível e a ação não aparece. Teste tela estreita e foco pelo teclado. Se o resultado divergir, registre print e export atual antes de sugerir outra posição ou CSS; não declare o alinhamento concluído apenas pelo código.

---

## 5. Região de Resultados (Classic Report)

1. Na árvore *Rendering*, clique com o botão direito em **Body** › **Create Region**.
2. Defina as propriedades da região:
   - *Identification › Title*: `Colaboradores`
   - *Identification › Type*: **Classic Report**
   - *Advanced › Static ID*: `colaboradores`
   - *Layout › Sequence*: `20` **na região Colaboradores**, não na coluna do relatório.
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
| `NOME_COMPLETO` | **Link** | `Pessoa` | **Sortable**: Yes<br>**Default Sequence**: 1<br>**Default Direction**: Ascending<br>**Escape Special Characters**: No<br>**Link › Target**: Page `14`<br>**Link › Set Items**: `P14_ID_COLABORADOR` = `#ID_COLABORADOR#`<br>**Link › Clear Cache**: `14`<br>**Link › Link Text** (uso confirmado pelo usuário em 09/11/2026):<br>`<span class="cx-colab-pessoa"><span class="cx-avatar"><img src="#APP_FILES#Fotos Colaboradores/#FOTO_URL!ATTR#" alt="" onerror="this.remove();" loading="lazy">#INICIAIS!HTML#</span><span class="cx-colab-pessoa__info"><span class="cx-colab-pessoa__nome">#NOME_COMPLETO!HTML#</span><span class="cx-colab-pessoa__email">#EMAIL!HTML#</span></span></span>` |
| `LOGIN_APEX` | **Plain Text** | `Login` | **Sortable**: Yes |
| `VINCULO_LINHA1` | **Plain Text** | `Vínculo` | **Sortable**: Yes<br>**Escape Special Characters**: No<br>**Column Formatting › HTML Expression**:<br>`<div class="cx-colab-vinculo #CLASSE_VINCULO!ATTR#"><span class="cx-colab-vinculo__emp-dept">#ICONE_VINCULO!RAW##VINCULO_LINHA1!HTML#</span><span class="cx-colab-vinculo__cargo">#VINCULO_LINHA2!HTML#</span></div>` |
| `PERFIL` | **Plain Text** | `Perfil` | **Sortable**: Yes<br>**Escape Special Characters**: No<br>**Column Formatting › HTML Expression**:<br>`#PERFIL_HTML!RAW#` |
| `SITUACAO` | **Plain Text** | `Situação` | **Sortable**: Yes<br>**Escape Special Characters**: No<br>**Column Formatting › HTML Expression**:<br>`<span class="cx-badge cx-badge--#SITUACAO_CLASSE!ATTR#">#SITUACAO!HTML#</span>` |
| *Demais colunas* | **Hidden** | — | Deixe como **Hidden**: `ID_COLABORADOR`, `EMAIL`, `PRIMEIRO_NOME`, `ULTIMO_NOME`, `FOTO_URL`, `TEM_IMAGEM`, `INICIAIS`, `ID_EMPRESA`, `EMPRESA`, `ID_DEPARTAMENTO`, `DEPARTAMENTO`, `ID_CARGO`, `CARGO`, `VINCULO_LINHA2`, `FL_SEM_VINCULO`, `CLASSE_VINCULO`, `ICONE_VINCULO`, `PERFIL_HTML`, `SITUACAO_CLASSE`. |


**Coluna Pessoa — já aplicado:** o usuário confirmou em 09/11/2026 que `NOME_COMPLETO` já usa **Type = Link** e o HTML em **Link Text**. Não mudar o tipo, mover o HTML ou reconfigurar o Target para este ajuste. O APEX gera a tag `<a>` com o destino e o checksum; não coloque outra tag `<a>` dentro do conteúdo nem use `&LINK.`. As demais colunas **Plain Text** continuam usando **HTML Expression**.

**Ajuste pontual na configuração existente:** em NOME_COMPLETO → Link → Link Text, substitua somente as quatro referências abaixo, ou cole o conteúdo completo a seguir. Preserve classes, estrutura, Type e Target atuais.

| Referência atual | Referência com escape |
|---|---|
| `#FOTO_URL#` | `#FOTO_URL!ATTR#` |
| `#INICIAIS#` | `#INICIAIS!HTML#` |
| `#NOME_COMPLETO#` | `#NOME_COMPLETO!HTML#` |
| `#EMAIL#` | `#EMAIL!HTML#` |

```html
<span class="cx-colab-pessoa">
  <span class="cx-avatar">
    <img src="#APP_FILES#Fotos Colaboradores/#FOTO_URL!ATTR#"
         alt="" onerror="this.remove();" loading="lazy">
    #INICIAIS!HTML#
  </span>
  <span class="cx-colab-pessoa__info">
    <span class="cx-colab-pessoa__nome">#NOME_COMPLETO!HTML#</span>
    <span class="cx-colab-pessoa__email">#EMAIL!HTML#</span>
  </span>
</span>
```

O escape ainda não foi confirmado como aplicado. Após salvar, confira a apresentação e caracteres especiais em nome/e-mail. A confirmação de Link Text não valida os processos de edição da página 14.

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
   - *Layout › Sequence*: `10` **na região Filtros**, não nas facetas.
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

Resultado da captura de 09/11: **parcialmente conforme**. Consulte [validação visual](./Validacao-visual-2026-11-09.md) antes de novos ajustes. Filtros e botão estão posicionados; tabela, etiqueta de perfil e barra superior ainda divergem.

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

Estado atualizado pela captura de 09/11: cabeçalho e posição dos filtros confirmados visualmente. A chamada ao package e o escape de NOME_COMPLETO constam no export enviado. Demais ajustes e testes funcionais continuam pendentes. A instalação de ACL está confirmada pelo backup; a validação final das facetas permanece pendente.


## 10. Verificações complementares da revisão integrada

- Teste texto com caracteres especiais em nome, e-mail, departamento e cargo; não deve virar marcação HTML.
- Confira o carregamento dos arquivos CSS normal/minificado sem erro 404, foto válida, foto ausente e iniciais.
- Com mais de 15 resultados, avance e volte páginas; depois filtre e confira total e navegação.
- Combine Situação, Empresa, Departamento e Perfil; limpe os filtros e teste a busca textual. Confira um usuário com papel manual conhecido e outro com papel via cargo.
- Teste isolamento entre empresas e sessão sem empresa. A autorização do botão não substitui a política de acesso aos dados.

| Sintoma | Verificação | Ação |
|---|---|---|
| HTML Expression não aparece em NOME_COMPLETO | Coluna do tipo Link | Usar Link Text conforme §5.1; se ausente, obter print do painel |
| Filtros aparecem abaixo do relatório | Export de 09/11 mostra Colaboradores sequence 10 e Filtros sequence 20, apesar das colunas 4 e 1 | Inverter a sequência das regiões: Filtros 10 com Start New Row Yes; Colaboradores 20 com Start New Row No. Manter colunas/spans 1/3 e 4/9. Salvar e executar a página inteira; captura posterior de 09/11 confirma o alinhamento resolvido |
| Total aparece sem navegação | Tipo NoPagination | Usar WithPagination e testar mais de 15 resultados |
| Botão aparece para conta sem empresa | Condição antiga tratava G_ID_EMPRESA nulo como permissão | Usar o package do §4 com ADMIN_RH na ação e manter proteção no destino; não restringir a lista inteira por causa do botão |
| Nome abre cadastro em vez de edição | Página 14 ainda não validada para editar | Revisar processos e condições da página 14 antes de liberar essa navegação |


## 11. Ajustes após a captura de 09/11/2026

Siga esta seção na página já montada. **Não recrie o cabeçalho, o botão, as facetas ou a view:** a captura confirma o alinhamento geral. A [auditoria visual](./Validacao-visual-2026-11-09.md) registra o que ainda diverge do protótipo. Não alterar os 309 registros para reproduzir os oito exemplos fictícios.

### 11.1 Corrigir a etiqueta de Perfil primeiro

1. Na página 12, selecione **Colaboradores → Columns → PERFIL** (não PERFIL_HTML).
2. Em **Column Formatting → HTML Expression**, use:

   ```html
   #PERFIL_HTML!RAW#
   ```

3. Preserve PERFIL_HTML como coluna Hidden. O fragmento RAW é permitido aqui porque a view gera a etiqueta com marcação fixa; não aplique RAW a nome, e-mail ou vínculo.
4. Salve e execute. Administrador deve aparecer como etiqueta cinza, sem tags visíveis.
5. Se continuar aparecendo HTML literal, confira o valor retornado pela view: se contém `&lt;span`, há escape anterior. Obtenha o valor/expressão atual antes de alterar outras colunas. Não desligue o escape de todos os campos.

Só avalie a largura das colunas depois disso: o HTML literal em Perfil aumenta a largura necessária da célula.

### 11.2 Confirmar o CSS e o template efetivamente usados

1. Preserve **CSS File URLs** com `#APP_FILES#modulos/colaboradores/colaboradores#MIN#.css`.
2. No navegador, abra DevTools → Network e recarregue a página. Confirme qual variante foi solicitada, retorno sem 404 e conteúdo atualizado.
3. Inspecione a tabela em Elements. Confira se possui a classe `t-Report-report` e se está dentro da região com classe `cx-relatorio`.
4. Em Styles/Computed, confira se as regras de colaboradores.css aparecem. Se o DOM não corresponder, registre as classes e o template antes de adaptar seletores.
5. No Builder, preserve `cx-relatorio` em CSS Classes da região. As opções do **template do relatório** são diferentes das opções da região; confira o componente que desenha as células.

Não conclua que o CSS está ausente só pela imagem. Os próximos seletores pressupõem a estrutura acima e devem ser validados no navegador.

### 11.3 Card e distribuição das colunas

Referência reutilizada: [ponto.css](../ponto-eletronico/ponto.css), `.cx-ponto-card`: superfície, borda, raio e ausência de sombras. A adaptação abaixo é restrita à tabela de Colaboradores, preservando o componente nativo.

**Proposta para teste visual, ainda não homologada:** com o DOM confirmado no §11.2, teste o bloco abaixo ao final de **Page → CSS → Inline** (confirmar caminho no 26.1.5). Não edite arquivos de corlixhub/ diretamente.

```css
.cx-colaboradores-pagina .cx-relatorio table.t-Report-report {
    width: 100%;
    table-layout: fixed;
    border-collapse: separate;
    border-spacing: 0;
    border: 1px solid var(--cx-borda);
    border-radius: var(--cx-raio-card);
    background: var(--cx-superficie);
    box-shadow: none;
}

.cx-colaboradores-pagina .cx-relatorio table.t-Report-report th,
.cx-colaboradores-pagina .cx-relatorio table.t-Report-report td {
    border: 0;
    border-bottom: 1px solid var(--cx-borda);
    padding: 12px;
    vertical-align: middle;
    white-space: normal;
    overflow-wrap: anywhere;
}

.cx-colaboradores-pagina .cx-relatorio table.t-Report-report tr:last-child td {
    border-bottom: 0;
}

.cx-colaboradores-pagina .cx-relatorio table.t-Report-report th:first-child {
    border-top-left-radius: var(--cx-raio-card);
}

.cx-colaboradores-pagina .cx-relatorio table.t-Report-report th:last-child {
    border-top-right-radius: var(--cx-raio-card);
}

/* Ordem das cinco colunas visíveis: Pessoa, Login, Vínculo, Perfil, Situação. */
.cx-colaboradores-pagina .cx-relatorio table.t-Report-report th:nth-child(1) { width: 30%; }
.cx-colaboradores-pagina .cx-relatorio table.t-Report-report th:nth-child(2) { width: 15%; }
.cx-colaboradores-pagina .cx-relatorio table.t-Report-report th:nth-child(3) { width: 25%; }
.cx-colaboradores-pagina .cx-relatorio table.t-Report-report th:nth-child(4) { width: 18%; }
.cx-colaboradores-pagina .cx-relatorio table.t-Report-report th:nth-child(5) { width: 12%; }

.cx-colaboradores-pagina .cx-colab-pessoa {
    display: flex;
    min-width: 0;
    max-width: 100%;
}

.cx-colaboradores-pagina .cx-colab-pessoa__info {
    min-width: 0;
}

.cx-colaboradores-pagina .cx-colab-pessoa__email {
    overflow-wrap: anywhere;
}
```

As proporções são ponto de partida, não medidas extraídas do protótipo. Não fixe altura de linha nem corte departamento/cargo. Confirme a ordem das cinco colunas antes de usar nth-child. Em tela estreita, confira legibilidade e acesso a todas as colunas: se necessário, planeje rolagem horizontal no contêiner real do relatório; não esconda overflow apenas para eliminar o corte.

Se regras do tema vencerem na cascata, confira o seletor computado antes de acrescentar especificidade; não use !important indiscriminadamente. Após aprovar o teste, incorporar o ajuste aos arquivos do módulo normal/minificado, publicar ambos pelo Builder e retirar a cópia Inline. A sincronização definitiva dos arquivos ainda não foi realizada nesta revisão documental.

### 11.4 Facetas, contagem e ordenação

1. Na faceta P12_PERFIL, altere Label para **Perfil de acesso**.
2. Preserve a busca com placeholder **Nome, login ou e-mail**.
3. Confira as opções disponíveis de contagem e menus no componente Faceted Search. Não esconder menus pelo CSS sem verificar suas ações e acessibilidade.
4. As contagens junto aos rótulos devem, no alvo visual, ficar alinhadas à direita. Esse ajuste depende do DOM efetivo das facetas; obtenha-o antes de adicionar seletores novos.

**Barra acima da tabela — implementação pendente:** o protótipo tem “309 colaboradores” à esquerda e “Ordenar por — Nome” à direita. Isso não se resolve apenas renomeando “Total Row Count”. Não desative a contagem atual antes de existir a substituta funcional.

A nova barra deve seguir pkg_colaboradores_ui para HTML personalizado e a integração nativa do relatório/facetas para estado. Antes de implementar, definir e verificar pela documentação APEX 26.1:
- fonte do total filtrado, inclusive zero resultados;
- atualização após busca, combinação/limpeza de facetas e refresh;
- opções de ordenação realmente disponíveis e aplicação ao relatório;
- preservação dos filtros e retorno à primeira página quando necessário;
- acesso por teclado e rótulos em pt-BR.

Não usar um count(*) independente sem os filtros, não fixar “309” e não criar um select decorativo. A fidelidade ao protótipo permanece pendente até essa barra funcionar.

### 11.5 Paginação e mensagens em português

1. Confira no relatório o tipo com navegação do §5 e o número de linhas = 15.
2. Teste avançar, voltar e filtrar estando fora da primeira página.
3. Inspecione o rodapé para distinguir texto cortado por overflow de texto incompleto gerado pelo template.
4. Para “Total Row Count” e “row(s)”, identifique primeiro a origem pelo Help/documentação de Faceted Search e pelo template de paginação. Não altere o idioma global da aplicação nem invente chaves de Text Messages para corrigir apenas esta página.
5. Se a mensagem vier de template compartilhado, avaliar impacto nas outras páginas antes da alteração. Registrar chave/template identificado e tradução no guia.
6. O resultado deve exibir total e intervalo em pt-BR, por exemplo “1–15 de 309”, sem corte e com navegação acessível. A chave exata de tradução ainda precisa ser confirmada no Builder.

### 11.6 Conferência final e registro

Compare novamente com o protótipo, considerando a largura da janela:
- card branco, divisórias horizontais e borda discreta;
- etiqueta Administrador renderizada;
- Vínculo com espaço suficiente sem truncar dados;
- barra de contagem/ordenação funcional;
- facetas e rodapé em pt-BR;
- botão e filtros nas posições já confirmadas;
- navegação e filtros funcionando após cada ajuste.

Registre no Registro-implantacao.md quais passos foram aplicados, prints/export e testes executados. Esta seção oferece ajustes de Builder e uma proposta de CSS para validação; não declara a página pronta nem implementa a barra pendente.

### 11.7 Mensagens confirmadas na documentação APEX 26.1

Em Shared Components → Globalization → Text Messages, criar/editar as mensagens abaixo (confirmar agrupamento no Builder 26.1.5). Usar o idioma efetivo da sessão: a configuração técnica atual do projeto é en, portanto os overrides em português devem ser cadastrados em English (en) enquanto esse for o idioma efetivo. Se a sessão usar pt-br, cadastrar nesse idioma. Não alterar idioma global apenas para corrigir esta tela.

| Name | Text |
|---|---|
| APEX.FS.TOTAL_ROW_COUNT_LABEL | Total de colaboradores |
| APEX.FS.CLEAR | Limpar |
| APEX.FS.CLEAR_ALL | Limpar filtros |
| APEX.FS.SHOW_MORE | Mostrar mais |
| APEX.FS.SHOW_LESS | Mostrar menos |
| PAGINATION.NEXT | Próxima |
| PAGINATION.PREVIOUS | Anterior |
| PAGINATION.NEXT_SET | Próximo conjunto |
| PAGINATION.PREVIOUS_SET | Conjunto anterior |
| WWV_RENDER_REPORT3.X_Y_OF_Z | %0–%1 de %2 |
| WWV_RENDER_REPORT3.X_Y_OF_Z_2 | %0–%1 de %2 |
| WWV_RENDER_REPORT3.X_Y_OF_MORE_THAN_Z | %0–%1 de mais de %2 |

Para mensagens APEX.FS usadas no cliente, marcar Used in JavaScript = Yes (confirmar rótulo no Builder). Preservar os placeholders. As mensagens são da aplicação: TOTAL_ROW_COUNT_LABEL pode aparecer em outras páginas com facetas; se houver listagens de outros assuntos, preferir “Total de registros”. Isso traduz o rótulo no local atual, não cria a barra do protótipo.

No Classic Report, localizar Pagination no painel e usar Row Ranges X to Y of Z com paginação (confirmar rótulo); export rowRangesXToYOfZWithPagination. Number of Rows = 15; Display Position = Bottom Right e Partial Page Refresh = Yes se disponíveis (confirmar no 26.1.5). Salvar, recarregar a página inteira e testar navegação/filtros. Não há necessidade de ORDER BY fixo na SQL.

Fontes: [mensagens das facetas](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/search-and-smart-filters-messages-requiring-translation.html), [mensagens internas](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/internal-messages-requiring-translation.html). As chaves antes pendentes de identificação no §11.5 foram confirmadas; cadastro e teste no Builder continuam pendentes.
