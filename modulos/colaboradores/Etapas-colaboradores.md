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

**Estilos em arquivo, sem CSS Inline:** as regras de card e distribuição que constavam no export foram incorporadas a [colaboradores.css](./colaboradores.css) e [colaboradores.min.css](./colaboradores.min.css), preservando a aparência proposta. A validação visual continua pendente.

1. Publique os dois arquivos pelo Builder em Shared Components → Static Application Files, substituindo os arquivos com os mesmos nomes/prefixos existentes.
2. Mantenha CSS File URLs da página:

   ```
   #APP_FILES#modulos/colaboradores/colaboradores#MIN#.css
   ```

3. Após confirmar a publicação, remova o CSS Inline da página 12. Não copie os estilos para o corpo HTML ou atributo style.
4. Salve e recarregue sem cache. Confira em Network que o arquivo correto foi carregado e em Computed que as regras vêm do arquivo estático.
5. Teste as cinco colunas, nomes longos, filtros, paginação e janela estreita. Compare com a captura anterior para verificar que a transferência não alterou a apresentação.

A distribuição preservada é Pessoa 30%, Login 15%, Vínculo 25%, Perfil 18%, Situação 12%; depende dessa ordem de colunas e deve ser ajustada no arquivo se o teste visual exigir. Não fixar altura nem cortar dados para caber. Regras do tema devem ser investigadas pela cascata, sem !important indiscriminado. Pastas corlixhub/ continuam somente leitura; publicação é feita pelo time no Builder.

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

Registre no Registro-implantacao.md quais passos foram aplicados, prints/export e testes executados. Esta seção oferece ajustes de Builder e uma estilos em arquivo para validação; não declara a página pronta nem implementa a barra pendente.

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

---

## 12. Acesso da liderança e correções da validação de 09/11/2026

Decisão do time em 09/11/2026: **a lista é vista por RH, gestores, CEO, diretores e pela equipe do Corlix Hub**. Só o RH (`ADMIN_RH`) cria e edita; os demais apenas leem. A equipe do Corlix Hub, dona do produto, vê todas as empresas; os outros perfis, só a própria. A equipe é somente leitura: contas dela não devem ter o papel `admin-rh`, que libera a edição. A data de nascimento é obrigatória.

Passos conferidos no export e na documentação oficial; nada aqui foi executado na app. Faça na ordem. Caminho marcado "(confirmar no 26.1.5)" que não existir na sua tela: pare e envie um print.

Referências reutilizadas: autorização `COLABORADOR` (composição por `apex_authorization.is_authorized`), foto do Chat (p. 4, página 44), `pkg_holerite_ui`/`pkg_ponto_ui` (`render_*` com chamada curta) e `render_cabecalho` deste módulo.

### 12.0 Situação na app (validada na tela em 09/11/2026)

Validado no navegador com a conta de RH, sem gravar dados, e no backup `4633d7a`. **Layout da p12 fiel ao protótipo em desktop.** Os ajustes de CSS, classe da barra, tradução e branch da p14 estão aplicados.

**Falta testar (§12.9):**

| Teste | O que falta |
|---|---|
| 2, 3 e 4 | Contas de diretor, gestor e colaborador comum |
| 6 | Caracteres especiais em nome de departamento |
| 11 e 12 | Salvar edição e criar colaborador, com registro de teste |
| 14 | Tela estreita |

**Diferenças aceitas em relação ao protótipo:** seta "Pessoa ↑" (a ordenação é pelo seletor), linhas mais altas quando nomes reais quebram em duas linhas, opção "Sem vínculo" ausente (isolamento por empresa), menu lateral e, nas facetas, ausência do filtro interno de valores, removido junto com o menu de três pontos.

**Falta aplicar: acesso da equipe do Corlix Hub**

1. Em **SQL Commands**, execute [`01_vw_colaboradores_lista.sql`](./01_vw_colaboradores_lista.sql) atualizado e confira `VALID` na consulta do Item 1 do §12.1.
2. Abra **Shared Components › Security › Authorization Schemes › VER_LISTA_COLABORADORES** e troque o código pelo do §12.2.
3. Clique em **Apply Changes**. Quem estiver logado precisa sair e entrar de novo.

**Confira:** com conta da equipe, a faceta Empresa lista as empresas cadastradas, inclusive "Sem vínculo" se houver, e o nome aparece sem link, sem o botão Novo colaborador. Com conta de RH, continua só a própria empresa.

**Fotos para a equipe:** a página 44 e `pkg_arquivos` conferem a empresa da sessão, que a equipe não tem. A correção libera só o papel da equipe:

1. Em **Authorization Schemes**, crie `VER_FOTO_COLABORADOR`, do tipo PL/SQL Function Returning Boolean, com mensagem `Acesso restrito.`, avaliação uma vez por sessão e o código:
   ```plsql
   return apex_authorization.is_authorized('COLABORADOR')
       or apex_authorization.is_authorized('EQUIPE_CORLIX_HUB');
   ```
2. Página 44 › **Security › Authorization Scheme** = `VER_FOTO_COLABORADOR`.
3. Instale o [`02_pkg_arquivos.pkb`](../arquivos/02_pkg_arquivos.pkb) atualizado.


**Falta corrigir: autorização que derruba as contas sem empresa**

A equipe do Corlix Hub não tem empresa vinculada. Para essas contas, `APROVADOR_PONTO` termina em `ORA-20012` ("Sua sessão não está vinculada a uma empresa"), e como ela protege um item do menu, **nenhuma página abre**. Sair e entrar de novo não resolve.

1. Abra **Shared Components › Security › Authorization Schemes › APROVADOR_PONTO**.
2. Em **PL/SQL Function Body**, troque o código por:
   ```plsql
   begin
     return pkg_ponto.fn_e_aprovador = 'S';
   exception
     when others then
       if sqlcode = -20012 then
         return false;
       end if;
       raise;
   end;
   ```
3. Clique em **Apply Changes**, saia e entre de novo com a conta da equipe.

**Confira:** a página abre sem o erro, e o item **Ajustes de ponto** não aparece no menu dessa conta. Para quem tem empresa, nada muda.

**Falta aplicar: Gestor e Situação só leitura na edição.** Em `P14_GESTOR` e em `P14_STATUS`, na página 14: **Read Only › Type** = Item is NOT NULL e **Item** = `P14_ID_COLABORADOR`. Salve. Ao criar colaborador, os dois continuam editáveis.

A data de nascimento continua obrigatória: registros sem ela precisam ser completados para salvar uma edição. A página continua em `@/standard`, divergência registrada no [11 · Padrões de páginas](../../docs/ai-context/11-padroes-de-paginas.md), §6.

### 12.1 Banco e arquivos (itens 1, 2 e 3)

#### Item 1 · Instalar view e package

1. Abra **SQL Workshop › SQL Commands**.
2. Abra [`01_vw_colaboradores_lista.sql`](./01_vw_colaboradores_lista.sql), copie tudo, cole e clique em **Run**. Esperado: `View created`.
3. Limpe a tela e repita com [`02_pkg_colaboradores_ui.pks`](./02_pkg_colaboradores_ui.pks), **sem a última linha com a `/` isolada**.
4. Limpe a tela e repita com [`02_pkg_colaboradores_ui.pkb`](./02_pkg_colaboradores_ui.pkb), também sem a `/` final.
5. Rode a conferência:
   ```sql
   select object_name, object_type, status
     from user_objects
    where object_name in ('VW_COLABORADORES_LISTA', 'PKG_COLABORADORES_UI')
   ```
   **Esperado:** três linhas com `VALID`. Se houver `INVALID`, pare e rode:
   ```sql
   select name, type, line, position, text
     from user_errors
    where name = 'PKG_COLABORADORES_UI'
    order by type, sequence
   ```

> A view agora só devolve a empresa da sessão. Em SQL Commands `G_ID_EMPRESA` é nulo, então `select * from vw_colaboradores_lista` volta **vazio**: é o esperado. A lista só mostra dados dentro da app. Colaboradores sem empresa só aparecem para a equipe do Corlix Hub; para os demais, a opção "Sem vínculo" da faceta Empresa some. O alerta "Cadastro incompleto" continua para quem tem empresa, mas não tem departamento ou cargo.

#### Item 2 · Publicar os arquivos CSS

1. Abra **Shared Components › Static Application Files**.
2. Clique em **Create File** (confirmar no 26.1.5).
3. Em **Directory**, informe `modulos/colaboradores`.
4. Selecione [`colaboradores.css`](./colaboradores.css) e [`colaboradores.min.css`](./colaboradores.min.css) e confirme, substituindo os arquivos com o mesmo nome.
5. **Confira:** na lista, as datas dos dois arquivos devem ter mudado.

#### Item 3 · Apagar o CSS Inline da página 12

Faça só depois do item 2.

1. Abra a **página 12** no Page Designer e clique no nó **Page 12: Colaboradores**, no topo da árvore.
2. Em **CSS › File URLs**, confirme `#APP_FILES#modulos/colaboradores/colaboradores#MIN#.css`.
3. Em **CSS › Inline**, selecione tudo e apague.
4. Clique em **Save**.
5. **Confira:** abra a página, recarregue com Ctrl+F5 (Cmd+Shift+R no Mac). A tabela continua no card branco, com divisórias horizontais.

### 12.2 Item 4 · Criar a autorização

1. Abra **Shared Components › Security › Authorization Schemes**.
2. Clique em **Create**, escolha **From Scratch** e **Next**.
3. Preencha:

   | Campo | Valor |
   |---|---|
   | **Name** | `VER_LISTA_COLABORADORES` |
   | **Scheme Type** | PL/SQL Function Returning Boolean |
   | **Error Message** | `Acesso restrito ao RH e à liderança.` |

4. Em **PL/SQL Function Body**, cole:
   ```plsql
   return apex_authorization.is_authorized('ADMIN_RH')
       or apex_authorization.is_authorized('EQUIPE_CORLIX_HUB')
       or apex_authorization.is_authorized('SOMENTE_DIRETORIA')
       or apex_authorization.is_authorized('GESTOR')
       or apex_acl.has_user_role(
            p_application_id => :APP_ID,
            p_user_name      => :APP_USER,
            p_role_static_id => 'gestor');
   ```
5. Em **Validate authorization scheme**, escolha **Once per session** (confirmar no 26.1.5).
6. Clique em **Create Authorization Scheme**.
7. **Confira:** o esquema aparece na lista.

CEO e diretores têm o papel `diretoria` pelo cargo. A autorização `GESTOR` cobre quem tem subordinados, e o papel `gestor` cobre quem lidera pelo cargo.

### 12.3 Item 5 · Aplicar na página e no menu

**Na página:**

1. Página 12 › clique no nó **Page 12: Colaboradores**.
2. Em **Security › Authorization Scheme**, troque para `VER_LISTA_COLABORADORES`.
3. Clique em **Save**.

**No menu:**

4. Abra **Shared Components › Navigation › Navigation Menu** e a lista do menu.
5. Clique na entrada **Colaboradores**.
6. Em **Authorization › Authorization Scheme**, escolha `VER_LISTA_COLABORADORES` (confirmar no 26.1.5).
7. Clique em **Apply Changes**.

Não altere a página 14: ela continua com `ADMIN_RH`.

**Confira:** saia e entre de novo. Uma conta de RH vê o item no menu; uma conta comum, não.

### 12.4 Item 6 · Trocar a consulta do relatório

1. Página 12 › na árvore, clique na região **Colaboradores**.
2. Em **Source › SQL Query**, abra o editor, apague tudo e cole:
   ```sql
   select id_colaborador,
          nome_completo,
          nome_completo as nome_sem_link,
          email,
          login_apex,
          primeiro_nome,
          ultimo_nome,
          case
            when trim(foto_url) is null
                 or foto_url = '#APP_FILES#Fotos Colaboradores/' then null
            else apex_page.get_url(p_page => 44, p_x01 => regexp_substr(trim(foto_url), '[^/]+$'))
          end as foto_url,
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
3. Clique em **OK** e em **Save**.
4. **Confira:** a coluna `NOME_SEM_LINK` aparece em **Columns**, na árvore.

### 12.5 Item 7 · Ajustar as colunas

Selecione cada coluna em **Colaboradores › Columns**. Salve no final.

**`NOME_COMPLETO`** (só o RH vê o link):

1. Em **Security › Authorization Scheme**, escolha `ADMIN_RH`.
2. Em **Link › Link Text**, troque por:
   ```html
   <span class="cx-colab-pessoa"><span class="cx-avatar cx-avatar--situacao-#SITUACAO_CLASSE!ATTR#"><img src="#FOTO_URL!ATTR#" alt="" onerror="this.remove();" loading="lazy">#INICIAIS!HTML#</span><span class="cx-colab-pessoa__info"><span class="cx-colab-pessoa__nome">#NOME_COMPLETO!HTML#</span><span class="cx-colab-pessoa__email">#EMAIL!HTML#</span></span></span>
   ```

**`NOME_SEM_LINK`** (gestores, CEO e diretores):

3. Preencha:

   | Propriedade | Valor |
   |---|---|
   | **Identification › Type** | Plain Text |
   | **Heading › Heading** | `Pessoa` |
   | **Layout › Sequence** | `21` |
   | **Security › Escape Special Characters** | Off |
   | **Security › Authorization Scheme** | `{Not ADMIN_RH}` (confirmar no 26.1.5) |

4. Em **Column Formatting › HTML Expression**, cole:
   ```html
   <span class="cx-colab-pessoa"><span class="cx-avatar cx-avatar--situacao-#SITUACAO_CLASSE!ATTR#"><img src="#FOTO_URL!ATTR#" alt="" onerror="this.remove();" loading="lazy">#INICIAIS!HTML#</span><span class="cx-colab-pessoa__info"><span class="cx-colab-pessoa__nome">#NOME_SEM_LINK!HTML#</span><span class="cx-colab-pessoa__email">#EMAIL!HTML#</span></span></span>
   ```

O nome usa a própria coluna, porque o valor de `NOME_COMPLETO` não deve ser considerado disponível para quem não passa na autorização dela.

**`VINCULO_LINHA1`:**

5. Em **Column Formatting › HTML Expression**, troque por:
   ```html
   <div class="cx-colab-vinculo #CLASSE_VINCULO!ATTR#"><span class="cx-colab-vinculo__emp-dept">#ICONE_VINCULO!RAW##VINCULO_LINHA1!HTML#</span><span class="cx-colab-vinculo__cargo">#VINCULO_LINHA2!HTML#</span></div>
   ```

**`SITUACAO`:**

6. Em **Column Formatting › HTML Expression**, troque por:
   ```html
   <span class="cx-badge cx-badge--#SITUACAO_CLASSE!ATTR#">#SITUACAO!HTML#</span>
   ```

7. Clique em **Save**.

**Confira:** com conta de RH aparece uma única coluna Pessoa, com link. Pessoas inativas ficam com avatar cinza.

### 12.6 Item 8 · Barra de total e ordenação

O APEX cria o seletor por padrão na posição de ordenação do próprio relatório. Como o protótipo pede total e seletor na mesma linha, o seletor fica numa região própria. A [documentação](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-sorting-with-order-by-item.html) confirma que o item pode ser posicionado em qualquer lugar da página.

**Criar a região Resultados:**

1. Na árvore, clique com o botão direito em **Body** e escolha **Create Region**.
2. Preencha:

   | Propriedade | Valor |
   |---|---|
   | **Identification › Name** | `Resultados` |
   | **Identification › Type** | Static Content |
   | **Source › HTML Code** | vazio |
   | **Layout › Sequence** | `20` |
   | **Layout › Start New Row** | Off |
   | **Layout › Column** | `4` |
   | **Layout › Column Span** | `9` |
   | **Appearance › Template** | Blank with Attributes |

**Mover o relatório:**

3. Clique na região **Colaboradores** e preencha:

   | Propriedade | Valor |
   |---|---|
   | **Layout › Parent Region** | `Resultados` |
   | **Layout › Sequence** | `20` |
   | **Layout › Start New Row** | On |
   | **Layout › Column** | Automatic |
   | **Layout › Column Span** | Automatic |
| **Layout › Position** | Sub Regions (confirmar nome no 26.1.5) |

**Criar a barra:**

4. Clique com o botão direito em **Resultados** e escolha **Create Sub Region**.
5. Preencha:

   | Propriedade | Valor |
   |---|---|
   | **Identification › Name** | `Barra da lista` |
   | **Identification › Type** | Static Content |
   | **Layout › Sequence** | `10` |
   | **Appearance › Template** | Blank with Attributes (No Grid) |
   | **Appearance › CSS Classes** | `cx-colab-barra` |

6. Em **Source › HTML Code**, cole:
   ```html
   <div id="cx-colab-total" class="cx-colab-barra__total" aria-live="polite"></div>
   ```

**Levar o total para a barra:**

7. Clique na região **Filtros**.
8. Em **Settings › Show Total Row Count** (ou no grupo equivalente), escolha **Selector** e informe `#cx-colab-total` no campo que aparecer (confirmar nome no 26.1.5).

**Criar a ordenação:**

9. Clique com o botão direito em **Barra da lista** e escolha **Create Page Item**:

   | Propriedade | Valor |
   |---|---|
   | **Identification › Name** | `P12_ORDEM` |
   | **Identification › Type** | Select List |
   | **Label › Label** | `Ordenar por` |
   | **List of Values › Type** | Static Values (Nome/`NOME`, Login/`LOGIN`, Departamento/`DEPARTAMENTO`) |
   | **List of Values › Display Null Value** | Off |
   | **Default › Static Value** | `NOME` |

10. Clique na região **Colaboradores**. Em **Order By › Type**, escolha **Item**.
11. Em **Order By › Item**, clique em **No Order By Item**.
12. No diálogo, cadastre as cláusulas:

    | Clause | Key | Display |
    |---|---|---|
    | `nome_completo` | `NOME` | Nome |
    | `login_apex, nome_completo` | `LOGIN` | Login |
    | `departamento, nome_completo` | `DEPARTAMENTO` | Departamento |

13. No campo **Item**, selecione `P12_ORDEM` e clique em **OK**.
14. Se o APEX tiver criado o item automático `P12_ORDER_BY`, apague-o.
15. Clique em **Save** e execute a página.

**Se o item não puder ser movido, ou aparecer em outro lugar, pare e envie um print das propriedades dele.** Não crie `ORDER BY` na consulta.

**Confira:** acima da tabela aparecem "N colaboradores" à esquerda e "Ordenar por" à direita, e os filtros continuam ao lado. O sufixo vem do CSS, então um único resultado aparece como "1 colaboradores".

### 12.7 Item 9 · Rótulo da busca

1. Na região **Filtros**, clique na faceta `P12_SEARCH`.
2. Em **Label › Label**, troque `Search` por `Buscar`.
3. Clique em **Save**.

### 12.8 Item 10 · Página 14: separar criação e edição

Hoje `CREATE_USER` roda em todo envio, então salvar um colaborador existente tenta criar a conta de novo. Depois desta seção, o link da p12 passa a editar. Abra a **página 14** no Page Designer e salve a cada grupo.

**Passo A · Botões**

1. Clique em `SALVAR_USUARIO`. Em **Server-side Condition**: **Type** = Item is NULL e **Item** = `P14_ID_COLABORADOR`.
2. Clique com o botão direito em `SALVAR_USUARIO` e escolha **Duplicate**.
3. Na cópia, preencha:

   | Propriedade | Valor |
   |---|---|
   | **Identification › Button Name** | `SALVAR_ALTERACOES` |
   | **Identification › Label** | `Salvar alterações` |
   | **Behavior › Database Action** | SQL UPDATE action |
   | **Behavior › Requires Confirmation** | Off |
   | **Server-side Condition › Type** | Item is NOT NULL |
   | **Server-side Condition › Item** | `P14_ID_COLABORADOR` |

**Passo B · Campos**

4. Em `P14_SENHA` e em `P14_CONFIRMAR_SENHA`: **Server-side Condition › Type** = Item is NULL e **Item** = `P14_ID_COLABORADOR`.
5. Em cada um destes: `P14_LOGIN`, `P14_EMPRESA`, `P14_DEPARTAMENTO`, `P14_CARGO`, `P14_GESTOR` e `P14_STATUS`: **Read Only › Type** = Item is NOT NULL e **Item** = `P14_ID_COLABORADOR`.
6. Em `P14_LOGIN`, **Help › Inline Help Text** = `O login não pode ser alterado.`

**Passo C · Validação e processos**

7. Na aba **Processing**, em cada item abaixo, defina **Server-side Condition › When Button Pressed** = `SALVAR_USUARIO`. **Não altere o Type** que já existir:
   - validação **Validar Confirmação de Senha**;
   - processo **Registrar admissão**;
   - processo **Criar usuário APEX**;
   - processo **Atribuir papéis do cargo**.

**Passo D · Mensagem e retorno à lista**

8. Em **Processes**, clique com o botão direito e escolha **Create Process**:

   | Propriedade | Valor |
   |---|---|
   | **Identification › Name** | `Confirmar alteração` |
   | **Identification › Type** | Execute Code |
   | **Source › PL/SQL Code** | `null;` |
   | **Execution › Sequence** | `40` |
   | **Success Message › Success Message** | `Alterações salvas.` |
   | **Server-side Condition › When Button Pressed** | `SALVAR_ALTERACOES` |

9. Em **After Processing**, clique com o botão direito e escolha **Create Branch**. Depois, mude o branch antigo **Limpar formulário após carregamento** para **Execution › Point = After Processing**:

   | Propriedade | Valor |
   |---|---|
   | **Identification › Name** | `Voltar à lista após editar` |
   | **Execution › Sequence** | `5` |
   | **Behavior › Target** | Page `12` |
   | **Server-side Condition › When Button Pressed** | `SALVAR_ALTERACOES` |

**Passo E · Cabeçalho**

10. Na aba **Rendering**, clique na região **Cabeçalho** e troque todo o PL/SQL por:
    ```plsql
    return pkg_colaboradores_ui.render_cabecalho_cadastro(to_number(:P14_ID_COLABORADOR));
    ```
11. Clique em **Save**.

**Confira:** abra pelo botão Novo colaborador: título "Novo colaborador", campos de senha e botão "Salvar colaborador". Abra pelo nome de alguém: título com o nome e a situação, sem senha, login bloqueado e botão "Salvar alterações". Faça o teste de salvar só com registro de teste (§12.9, testes 11 e 12).

Departamento, cargo, gestor e situação ficam só leitura na edição porque a mudança precisa passar por **Histórico de carreira › Movimentação**, que registra o evento e atualiza o colaborador. É uma diferença consciente em relação ao protótipo.

### 12.9 Testes

| # | Conta / ação | Esperado |
|---|---|---|
| 1 | RH | Menu visível; lista só da própria empresa; nome com link; botão Novo colaborador |
| 2 | CEO ou diretor(a) sem papel de RH | Menu e lista visíveis; nome sem link; sem botão |
| 3 | Gestor pelo papel e gestor só com subordinados | Iguais ao teste 2 |
| 4 | Colaborador comum | Sem item no menu; URL direta da p12 mostra acesso restrito |
| 4A | Equipe do Corlix Hub | Lista de todas as empresas; nome sem link; sem botão Novo colaborador |
| 5 | Linha com cadastro incompleto | Ícone de alerta, sem tags visíveis |
| 6 | Departamento de teste com `<b>&` no nome | Texto literal, sem negrito |
| 7 | Colaborador com foto e sem foto | Foto real; sem foto, iniciais |
| 8 | Pessoa inativa | Avatar cinza |
| 9 | Filtros e busca | Total da barra acompanha; contagens consistentes |
| 10 | Trocar `Ordenar por`, depois paginar | Ordem muda e se mantém entre páginas |
| 11 | RH edita o nome de alguém em registro de teste | Volta à lista com "Alterações salvas."; nenhum usuário APEX ou admissão nova |
| 12 | RH cria colaborador | Conta, admissão e papéis criados como antes |
| 13 | Editar colaborador | Login, empresa, departamento e cargo bloqueados; sem campos de senha; título com nome e situação |
| 14 | Tela estreita | Barra e tabela sem corte |

### 12.10 Se não funcionar

| Sintoma | Causa / verificação | Ação |
|---|---|---|
| Lista vazia para todos os usuários | `G_ID_EMPRESA` nulo na sessão | Confira se a conta tem empresa e faça login de novo; `SET_G_ID_EMPRESA` roda na autenticação |
| Liderança recebe acesso negado | Conta sem papel e sem subordinados, ou avaliação antiga na sessão | Confira o cargo em `cargo_papel`; saia e entre de novo |
| Duas colunas Pessoa | Autorização ausente em uma delas | Revisar §12.5 |
| `{Not ADMIN_RH}` não aparece | Rótulo diferente no 26.1.5 | Enviar print da lista de autorizações da coluna |
| Total vazio | Seletor incorreto ou região sem o `div` | Conferir `#cx-colab-total` e o HTML da região |
| `ORA-` ao trocar a ordenação | Coluna da cláusula ausente da consulta | Usar só colunas do select do §12.4 |

### 12.11 Fora deste passo a passo

- **Conta APEX ao editar:** `APEX_UTIL.SET_EMAIL` e `LOCK_ACCOUNT` exigem administrador do workspace, conforme a documentação. Por isso, editar o e-mail ou inativar não altera a conta APEX; falta definir e testar como sincronizar.
- **Protótipo de edição:** Redefinir senha, Perfis de acesso e Topo da hierarquia não foram incluídos.
- **Gestor:** vê a empresa inteira, não só a própria equipe, conforme a decisão acima.

Fontes: [Order By Item](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/managing-sorting-with-order-by-item.html), [total em seletor](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/showing-filter-chips-and-total-row-count.html), [SET_EMAIL](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_EMAIL-Procedure.html) e [LOCK_ACCOUNT](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/LOCK_ACCOUNT-Procedure.html).

---

## 13. Ajustes visuais finais

Nada aqui altera regras de acesso. **Estado: aplicado e testado na app em 09/11/2026** (§13.1 a §13.5; detalhes em `Registro-implantacao.md`). Referência: padrão `*-pagina.js` do Holerite e do Ponto.

### 13.1 Publicar o CSS e o script (singular e nome sem link)

Corrige "1 colaboradores" e deixa o nome azul só para quem tem link.

1. Publique `colaboradores.css` e `colaboradores.min.css` desta pasta, como no Item 2 do §12.1.
2. Página 12 › nó **Page 12: Colaboradores** › **JavaScript › Execute when Page Loads**: cole o conteúdo de [`colaboradores-pagina.js`](./colaboradores-pagina.js).
3. Clique em **Save** e recarregue com Ctrl+F5.

Faça os dois passos juntos: sem o script, o sufixo "colaboradores" não aparece.

**Confira:** com filtro de um resultado, a barra mostra "1 colaborador". Com conta de RH, o nome é azul e sublinha ao passar o mouse. Com conta somente leitura, o nome fica na cor do texto.

### 13.2 Trocar "Row updated."

A documentação do 26.1 não lista uma chave de tradução para esse texto. Por isso, a mensagem vai no próprio processo (confirmar o efeito no teste).

1. Página 14 › aba **Processing** › processo **Salvar Dados Colaborador**.
2. Em **Success Message › Success Message**, informe `Dados salvos.`
3. Apague o processo **Confirmar alteração**, para não exibir duas mensagens.
4. Clique em **Save**.

**Confira:** ao salvar uma edição, aparece só "Dados salvos.". Ao criar, "Dados salvos. Colaborador cadastrado com sucesso!". Se "Row updated." continuar, envie um print e não crie outro processo.

### 13.3 Situação travada com "Off"

1. Página 14 › item `P14_STATUS`.
2. Em **Settings**, desligue **Use Defaults** e preencha:

   | Propriedade | Valor |
   |---|---|
   | **On Value** | `Y` |
   | **On Label** | `Ativa` |
   | **Off Value** | `N` |
   | **Off Label** | `Inativa` |

3. Clique em **Save**.

**Confira:** a edição mostra "Ativa" ou "Inativa", conforme o título. **Teste criar ou salvar com registro de teste:** a coluna é booleana, e os valores acima são os padrão da app; a situação não pode mudar.

### 13.4 Ajuda do Gestor

1. Página 14 › item `P14_GESTOR`.
2. Em **Help › Inline Help Text**, informe `Quem está no topo da hierarquia (ex.: CEO) não tem gestor.`
3. Clique em **Save**.

### 13.5 Gestor exibido como número

Na edição, o Gestor aparecia como ID (ex.: `48`) quando o gestor gravado não tinha cargo com o papel `gestor` em `CARGO_PAPEL`: a LOV não o encontrava e o APEX exibia o valor de retorno. Casos encontrados em 09/11/2026: cargo 403, Supervisor de Vendas (João Oliveira e Ricardo Freitas, 60 liderados), e cargo 506, Técnico de Logística (Eduardo Vieira, 7 liderados; 147 ocupantes no cargo).

Não incluir o papel no cargo só para corrigir a exibição: `CARGO_PAPEL` também concede o papel do APEX a todos os ocupantes. A correção mantém o gestor já gravado na LOV, sem mudar acesso:

1. Página 14 › item `P14_GESTOR` › **List of Values › SQL Query**:

   ```sql
   SELECT c.NOME_COMPLETO d,
          c.ID_COLABORADOR r
     FROM COLABORADOR c
    WHERE c.ID_EMPRESA = :P14_EMPRESA
      AND (c.ID_COLABORADOR = :P14_GESTOR
           OR EXISTS (SELECT 1
                        FROM CARGO_PAPEL cp
                       WHERE cp.ID_CARGO = c.ID_CARGO
                         AND cp.CD_PAPEL = 'gestor'))
    ORDER BY c.NOME_COMPLETO
   ```

2. Clique em **Save**.

**Confira:** Aline Alves e Aline Silva mostram Ricardo Freitas; Aline Barbosa e Aline Nunes, Joao Oliveira. Na criação, as opções continuam só com cargos que têm o papel `gestor`.

Pendências fora da página: o time decide se o cargo 403 recebe o papel `gestor` (só 2 ocupantes, ambos líderes); o RH confere o cargo de Eduardo Vieira (id 272), técnico que lidera 7 pessoas. Não inclua o papel no cargo 506.

Para achar outros casos:

```sql
select g.id_cargo, cg.nome cargo,
       count(distinct g.id_colaborador) gestores,
       count(*) liderados,
       (select count(*) from colaborador x where x.id_cargo = g.id_cargo) ocupantes
  from colaborador s
  join colaborador g on g.id_colaborador = s.id_gestor
  join cargo cg on cg.id_cargo = g.id_cargo
 where not exists (select 1 from cargo_papel cp
                    where cp.id_cargo = g.id_cargo and cp.cd_papel = 'gestor')
 group by g.id_cargo, cg.nome
 order by liderados desc
```

### 13.6 Se não funcionar

| Sintoma | Causa / verificação | Ação |
|---|---|---|
| Barra mostra só o número, sem "colaboradores" | Script do §13.1 não salvo na p12 | Conferir **Execute when Page Loads** da página 12 e recarregar com Ctrl+F5 |
| Gestor aparece como número | Gestor gravado fora da LOV (cargo sem papel `gestor`) | Aplicar o §13.5; não mudar `CARGO_PAPEL` só por isso |
| `ORA-00904: "DATA_NASCIMENTO"` ao preparar teste | A coluna se chama `DATA_DE_NASCIMENTO` | Usar `data_de_nascimento` |
| `ORA-03049` no SQL Commands | Update e `commit` colados juntos | Rodar só o update, com **Autocommit** marcado |
| Conta inativa ainda entra no sistema | Inativar não bloqueia a conta APEX (§12.11) | Pendente de definição; não é efeito do §13 |
