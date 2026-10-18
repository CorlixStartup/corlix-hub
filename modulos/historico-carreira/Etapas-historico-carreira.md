# Histórico de Carreira · passo a passo no APEX

Este guia monta as páginas do módulo no App Builder do **APEX 26.1.5**, a versão do ambiente (o app já é versionado em APEXlang, `mmdVersion 26.1.0`). O banco precisa estar instalado antes: rode o `instalar.sql` (veja o `README-historico-carreira.md`).

Depois de montar as páginas no Builder, exporte o app em APEXlang como já é feito hoje, para que as páginas novas entrem no Git em `corlixhub/pages/`.

### Como ler os caminhos deste guia (APEX 26.1.5)

- **Rendering** é a árvore da esquerda do Page Designer; o **painel de propriedades** é o da direita. `Seção › Atributo` indica a seção e o campo no painel de propriedades do componente selecionado.
- No 26.1.5 a região **não tem a aba nem o nó "Attributes"** que versões antigas tinham (Region | Attributes).
- Para achar qualquer atributo, use a **busca no topo do painel de propriedades** (digite parte do nome, ex.: `Edit`, `Clear Cache`).
- Passos marcados com **(confirmar no 26.1.5)** ainda não foram conferidos na tela desta versão. Se o caminho não existir, não procure por tentativa: tire um print da árvore e do painel e registre o caminho certo neste guia.
- Para confirmar que um ajuste pegou, confira o **export APEXlang** da página: cada passo crítico traz o trecho esperado (ex.: `edit { enabled: true }`).


| Página | Nome | Tipo | Quem acessa |
|---|---|---|---|
| 13 | Histórico de carreira (já existe, vazia) | Normal | ADMIN_RH, gestor da equipe, o próprio colaborador |
| 18 | Movimentação | Modal Dialog | ADMIN_RH |
| 19 | Formações e certificações | Normal | ADMIN_RH |
| 20 | Dashboard RH | Normal | ADMIN_RH |
| 21 | Formação (formulário da formação, com anexo) | Modal Dialog | ADMIN_RH |
| 22 | Solicitar correção | Modal Dialog | O próprio colaborador |
| 23 | Responder solicitação | Modal Dialog | ADMIN_RH |

Se algum desses números já estiver em uso, troque o prefixo `P18_`, `P19_` etc. nos itens, no `historico-carreira.js` e nas constantes do `08_pkg_historico_carreira_ui.sql`.

---

## 1. Shared Components

### 1.1 Isolamento por empresa: `G_ID_EMPRESA`

1. **Application Items > Create**
   - Name: `G_ID_EMPRESA`
   - Scope: Application
   - Session State Protection: **Restricted - May not be set from browser**
2. **Application Processes > Create**
   - Name: `SET_G_ID_EMPRESA`
   - Process Point: **After Authentication**
   - Source:
     ```sql
     begin
       select id_empresa
         into :G_ID_EMPRESA
         from colaborador
        where upper(trim(login_apex)) = upper(trim(:APP_USER));
     exception
       when no_data_found or too_many_rows then
         :G_ID_EMPRESA := null;
     end;
     ```
3. Sessões já abertas não passam pelo After Authentication. Depois de publicar, saia e entre de novo.

O package recusa qualquer operação em sessão APEX sem `G_ID_EMPRESA`. Toda query das páginas abaixo também filtra por `:G_ID_EMPRESA`.

### 1.2 Papel e esquemas de autorização

1. O papel `Admin RH` (Static ID `admin-rh`) e o esquema `ADMIN_RH` já existem na app (módulo `modulos/perfis-acesso/`). Os usuários do RH recebem o papel automaticamente ao serem cadastrados na P14. Crie aqui só `GESTOR` e `COLABORADOR`.
2. **Authorization Schemes > Create** (os nomes precisam ser exatamente estes, porque o package e a view consultam `ADMIN_RH` pelo nome):

| Nome | Tipo | Configuração |
|---|---|---|
| `ADMIN_RH` | Is In Role or Group | Type: Application Role · Names: `Admin RH` · Evaluation Point: Once per session |
| `GESTOR` | PL/SQL Function Returning Boolean | Código abaixo · Once per session |
| `COLABORADOR` | PL/SQL Function Returning Boolean | Código abaixo · Once per session |

`GESTOR`: tem pelo menos um subordinado direto na mesma empresa.
```sql
declare
  l_qt pls_integer;
begin
  select count(*)
    into l_qt
    from colaborador s
    join colaborador g on g.id_colaborador = s.id_gestor
   where upper(g.login_apex) = upper(:APP_USER)
     and g.id_empresa = :G_ID_EMPRESA;
  return l_qt > 0;
end;
```

`COLABORADOR`: tem cadastro na empresa ou é do RH. Esse é o esquema de leitura da página 13.
```sql
declare
  l_qt pls_integer;
begin
  if apex_authorization.is_authorized('ADMIN_RH') then
    return true;
  end if;
  select count(*)
    into l_qt
    from colaborador
   where upper(login_apex) = upper(:APP_USER)
     and id_empresa = :G_ID_EMPRESA;
  return l_qt > 0;
end;
```

O detalhe "gestor só vê a própria equipe" fica na função `pkg_historico_carreira.fn_pode_ver_colaborador`, chamada pela página 13 (item 2.2). Ela libera o colaborador para o gestor de qualquer nível acima dele.

### 1.3 Mensagens de erro amigáveis

A aplicação já usa `log_pkg.apex_error_handler` como Error Handling Function. Para os erros do módulo (-20001 a -20099) aparecerem sem "ORA-" e sem pilha, escolha uma das opções:

- **Opção A (recomendada):** dentro do `log_pkg.apex_error_handler`, depois de registrar o log, delegue esses códigos:
  ```sql
  if p_error.ora_sqlcode between -20099 and -20001 then
    return pkg_historico_carreira.fn_tratar_erro(p_error);
  end if;
  ```
- **Opção B:** nas páginas 18, 19 e 21, em *Page > Error Handling > Error Handling Function*, informe `pkg_historico_carreira.fn_tratar_erro`. Essas páginas deixam de passar pelo `log_pkg` nesse caso.

### 1.4 Listas de valores (Shared Components > List of Values)

Todas do tipo *SQL Query*:

`LOV_TIPO_MOVIMENTACAO`
```sql
select ds_tipo d, id_tipo_movimentacao r
  from tipo_movimentacao
 where id_empresa = :G_ID_EMPRESA
   and fl_ativo = true
 order by nr_ordem, ds_tipo
```

`LOV_DEPARTAMENTO_EMPRESA`
```sql
select nome d, id_departamento r
  from departamento
 where id_empresa = :G_ID_EMPRESA
 order by nome
```

`LOV_COLABORADOR_ATIVO`
```sql
select nome_completo d, id_colaborador r
  from colaborador
 where id_empresa = :G_ID_EMPRESA
   and status = true
 order by nome_completo
```

`LOV_TIPO_FORMACAO` (Static): Graduação `GRADUACAO`, Pós-graduação `POS`, MBA `MBA`, Curso `CURSO`, Certificação `CERTIFICACAO`, Idioma `IDIOMA`.

---

## 2. Página 13 · Histórico de carreira

A página segue o protótipo *"Histórico de carreira — nova página"*. Como no organograma, o conteúdo é uma região **Dynamic Content** que chama `pkg_historico_carreira_ui.render`. O package monta o resumo, a faixa "Cargos ao longo do tempo", a linha do tempo com abas e filtro de ano, a posição atual e o quadro "Sobre este histórico".

O que cada perfil vê:
- **Colaborador:** o próprio histórico, inclusive reajustes por mérito, e o botão "Solicitar correção".
- **Gestor:** a equipe, sem os reajustes por mérito e sem o motivo de afastamentos.
- **RH:** tudo, mais a contagem de solicitações abertas daquela pessoa.

Salário nunca aparece nessa região: o valor fica só na lista "Lançamentos (RH)".

### 2.1 Atributos da página

- Authorization Scheme: `COLABORADOR`
- Item `P13_ID_COLABORADOR`: Hidden · Value Protected: Yes · Session State Protection: **Checksum Required - Session Level**
- Remova a região de breadcrumb (`title-bar`) que a página tem hoje: o título e o botão "Exportar PDF" já vêm na região.

### 2.2 Processos Before Header (nesta ordem)

1. **Colaborador padrão** (PL/SQL, seq. 10): sem parâmetro, abre o histórico do próprio usuário.
   ```sql
   if :P13_ID_COLABORADOR is null then
     select id_colaborador
       into :P13_ID_COLABORADOR
       from colaborador
      where upper(login_apex) = upper(:APP_USER)
        and id_empresa = :G_ID_EMPRESA;
   end if;
   ```
2. **Validar acesso** (PL/SQL, seq. 20):
   ```sql
   if :P13_ID_COLABORADOR is null
      or pkg_historico_carreira.fn_pode_ver_colaborador(:P13_ID_COLABORADOR) = 'N' then
     raise_application_error(-20012, 'Você não tem acesso ao histórico deste colaborador.');
   end if;
   ```
3. **Registrar acesso salarial** (PL/SQL, seq. 30) · Authorization Scheme `ADMIN_RH`. Só é necessário por causa da região "Lançamentos (RH)", que mostra salário.
   ```sql
   pkg_historico_carreira.registrar_acesso_salarial(
     p_id_colaborador => :P13_ID_COLABORADOR,
     p_contexto       => 'P13 · lançamentos do histórico');
   ```

### 2.3 CSS e JavaScript

1. Suba `historico-carreira.css` em *Shared Components > Static Application Files* e informe `#APP_FILES#historico-carreira#MIN#.css` em *Page > CSS > File URLs*. Também dá para colar o conteúdo em *CSS > Inline*. Se usar `#MIN#`, suba também uma versão minificada, como o app já faz com o `custom.css`.
2. `historico-carreira-pagina.js` tem dois blocos. Cole o primeiro em *JavaScript > Function and Global Variable Declaration* e o segundo em *Execute when Page Loads*.
3. Largura e altura toda: use o page template **Standard** com as regiões em *Body*, sem nenhum ajuste extra. O próprio `historico-carreira.css` faz o resto: só na página que tem a região do histórico (`body:has([data-hc])`), ele zera o padding de 2rem que o Universal Theme coloca em volta do corpo e pinta o fundo `#F1EFED` até o rodapé. O título fica encostado nas bordas da área de conteúdo, como no protótipo. A região "Lançamentos (RH)" mantém uma margem de 32px.
   - Se continuar com a moldura branca em volta, o CSS antigo está em cache. Suba o `.css` e o `.min.css` de novo e recarregue com Ctrl+F5.
   - `:has()` funciona no Chrome, Edge e Safari atuais e no Firefox 121 ou mais novo. Em navegadores antigos, a página só fica com a moldura, sem quebrar.

### 2.4 Região "Histórico de carreira"

- Type: **Dynamic Content** · Static ID: `historico_carreira` (o JS usa esse ID)
- Appearance > Template: *Blank with Attributes*
- Source > PL/SQL Function Body returning a CLOB:
  ```sql
  return pkg_historico_carreira_ui.render(:P13_ID_COLABORADOR);
  ```
- Page Items to Submit: `P13_ID_COLABORADOR`

Ajuste as constantes no topo de `08_pkg_historico_carreira_ui.sql` para o seu app, e rode o arquivo de novo:

| Constante | Padrão | Uso |
|---|---|---|
| `c_pagina_organograma` / `c_item_organograma` | 3 / `P3_ID_FOCO` | "Ver no organograma". Use o item de foco que você criou no organograma (no guia daquele módulo ele aparece como `P10_ID_FOCO`). |
| `c_pagina_comunicado` / `c_item_comunicado` | 11 / nulo | "Ver comunicado". Com item nulo, abre a lista de comunicados. |
| `c_pagina_holerite` | nulo | "Ver holerite" no mérito. Nulo esconde o link até o holerite existir. |
| `c_pagina_solicitacao` / `c_item_solicitacao` | `22` / `P22_ID_COLABORADOR` | Botão "Solicitar correção". Se a página 22 (§6) ainda não existir, mude para `null` e rode o arquivo: sem o item, a página 13 dá `ERR-1002` |
| `c_pagina_painel_rh` | 20 | Link para o RH ver as solicitações abertas |

### 2.5 Região "Lançamentos (RH)"

Lista de todos os lançamentos, incluindo rascunhos. É por aqui que o RH edita um rascunho ou estorna. Fica abaixo da região principal.

- Type: Interactive Report · Authorization Scheme: `ADMIN_RH` · Template Options: Collapsible (fechada)
- Source:
  ```sql
  select id_historico_carreira, dt_efetiva, ds_tipo, st_registro, fl_estorno,
         nm_cargo_anterior, nm_cargo_novo, nm_departamento_anterior, nm_departamento_novo,
         nm_gestor_novo, vl_salario_anterior, vl_salario_novo, ds_motivo,
         usr_efetivacao, dt_efetivacao
    from vw_historico_carreira
   where id_colaborador = :P13_ID_COLABORADOR
     and id_empresa     = :G_ID_EMPRESA
   order by dt_efetiva desc, id_historico_carreira desc
  ```
- Colunas `VL_SALARIO_ANTERIOR` e `VL_SALARIO_NOVO`: Server-side Condition **Authorization Scheme `ADMIN_RH`**. A view já mascara o salário para outros perfis; a condição tira até o cabeçalho da coluna.
- Coluna `ID_HISTORICO_CARREIRA`: Type Link · Target página 18 · Items `P18_ID_HISTORICO_CARREIRA` = `#ID_HISTORICO_CARREIRA#`, `P18_ID_COLABORADOR` = `&P13_ID_COLABORADOR.` · Clear Cache 18 · Link Text `<span class="fa fa-edit"></span>`

### 2.6 Barra do RH (botões e seletor)

O protótipo mostra a visão do colaborador e não tem nada do RH. Para não mexer no layout dele, tudo o que é só do RH fica numa **barra fina, numa linha só, logo acima do título**. Ela tem o selo "Visão do RH", o seletor de colaborador à esquerda e os botões à direita. Quem não é `ADMIN_RH` não vê a barra, e a página fica igual ao protótipo.

```
┌───────────────────────────────────────────────────────────────────────────────┐
│ [Visão do RH]  Ver histórico de [Amanda Nunes ▾]      [Formações] [Nova movimentação] │
├───────────────────────────────────────────────────────────────────────────────┤
│ Histórico de carreira                                          [⬇ Exportar PDF] │
```

> **Por que não colocar os botões ao lado do "Exportar PDF":** o título é gerado pelo package dentro da região "Histórico de carreira", e essa região é recriada a cada refresh (ex.: ao fechar a modal). Botões ou itens movidos para dentro dela sumiriam a cada atualização.

**Antes de começar, confira:**

- [ ] O `historico-carreira.css` atualizado (com o bloco "Barra do RH") foi enviado de novo em *Shared Components › Static Application Files*, junto com o `.min.css`, porque a página usa `#MIN#` (§2.3).

#### Passo 1 · Região

Clique na região que hoje se chama **Buttons Container** (ou crie uma: botão direito em **Body** › Create Region) e preencha:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `Barra do RH` |
| Identification | Type | **Static Content** |
| Layout | Sequence | 10 (antes de "Histórico de carreira") |
| Appearance | Template | **Blank with Attributes (No Grid)** |
| Appearance | CSS Classes | `hc-barra-rh` |
| Advanced | Static ID | `hc_barra_rh` |
| Security | Authorization Scheme | **ADMIN_RH** |

O template *Buttons Container* é o que deixa a região com cara de cartão, com sombra, e empilha os botões, porque cada componente ganha uma linha do grid. Com *No Grid*, os componentes ficam lado a lado e o CSS arruma a linha.

#### Passo 2 · Seletor e botões dentro da região

A ordem na tela segue a **Sequence**: o seletor primeiro, depois os botões.

| Componente | Layout › Sequence | Layout › Slot | Appearance |
|---|---|---|---|
| `P13_COLABORADOR_SELECIONADO` | 10 | Region Body | Template **Optional - Floating** (já está) · Label `Ver histórico de` |
| `FORMACOES` ("Formações") | 20 | Region Body | Text · Hot **Off** |
| `NOVA_MOVIMENTACAO` ("Nova movimentação") | 30 | Region Body | Text · Hot **On** |

Os dois botões:

| Botão | Behavior › Action | Target |
|---|---|---|
| `FORMACOES` | Redirect to Page in this Application | Page **19** · Set Items `P19_ID_COLABORADOR` = `&P13_ID_COLABORADOR.` |
| `NOVA_MOVIMENTACAO` | Redirect to Page in this Application | Page **18** · Set Items `P18_ID_COLABORADOR` = `&P13_ID_COLABORADOR.` · Clear Cache `18` |

Em ambos, **Security › Authorization Scheme:** `ADMIN_RH`.

O botão principal (Hot) fica por último, na ponta direita, como o "Exportar PDF" no título.

#### Passo 3 · Testar

1. Salve e rode a página 13 com um usuário RH. A barra aparece numa linha só, sem sombra, colada no título e com a mesma largura dele.
2. Diminua a janela até a largura de um celular. O seletor ocupa a linha inteira e os botões descem para a linha de baixo.
3. Clique em **Exportar PDF**. A barra não aparece na impressão.
4. Entre com um usuário que não é RH. A barra não aparece, e a página fica igual ao protótipo.

#### Como conferir no export da página 13

```
region barra-do-rh (
    name: Barra do RH
    type: staticContent
    ...
    appearance {
        template: @/blank-with-attributes-no-grid
        cssClasses: hc-barra-rh
    }
    security {
        authorizationScheme: @admin-rh
    }
)
```
(Os nomes `blank-with-attributes-no-grid` e `cssClasses` são o formato esperado do export; confirmar no 26.1.5.) Os botões e o item devem ter `region: @barra-do-rh` e as sequências 10, 20 e 30.

#### Se não funcionar

| Sintoma | Causa provável | Correção |
|---|---|---|
| Continua com sombra e botões empilhados | Template ainda é *Buttons Container* ou *Blank with Attributes* (com grid) | Passo 1: **Blank with Attributes (No Grid)** |
| Barra sem fundo, sem o selo "Visão do RH" ou sem a linha embaixo | CSS sem a classe ou arquivo antigo em cache | Confira *CSS Classes* `hc-barra-rh`, suba o `.css` e o `.min.css` de novo e recarregue com Ctrl+F5 |
| Os botões ficam colados no seletor, à esquerda | O APEX colocou os componentes dentro de outro `div`, e o CSS não alcança | Inspecione (F12) e mande o HTML da região para ajustar o seletor do CSS |
| Botões na ordem errada | Sequências iguais ou trocadas | Passo 2: 10, 20, 30 |

### 2.7 Dynamic Action "Atualizar depois da modal"

- Event: **Dialog Closed** · Selection Type: JavaScript Expression · `document`
- True actions: Refresh `Histórico de carreira` e Refresh `Lançamentos (RH)`

Esse refresh vale também para a modal "Solicitar correção" (página 22): a contagem de solicitações em análise aparece logo depois.

### 2.8 Seletor de colaborador (RH)

Sem parâmetro, a página abre no próprio usuário. Para o RH abrir o histórico de qualquer pessoa sem depender da página 12 (Colaboradores), coloque um seletor no topo, visível só para `ADMIN_RH`.

**Região**
- Na região **Barra do RH** do §2.6 (Sequence 10, antes dos botões).

**Item `P13_COLABORADOR_SELECIONADO`**
- Type: **Popup LOV** · Label "Ver histórico de" · Authorization Scheme `ADMIN_RH`
- Source: nenhum · Default › Type **Item** › `P13_ID_COLABORADOR` (abre mostrando quem está na tela)
- List of Values › Type **SQL Query** (inclui inativos, porque o RH também consulta quem saiu):
  ```sql
  select nome_completo
         || case when status then null else ' (inativo)' end as d,
         id_colaborador as r
    from colaborador
   where id_empresa = :G_ID_EMPRESA
   order by nome_completo
  ```
- Display Null Value: Off

**Dynamic Action "Trocar colaborador"**
- Event: **Change** · Item: `P13_COLABORADOR_SELECIONADO`
- Client-side Condition: Item **is not null** › `P13_COLABORADOR_SELECIONADO`
- True action: **Submit Page** · Request/Button Name: `TROCAR_COLABORADOR` · Show Processing: On

**Processo "Trocar colaborador"** (Processing, Sequence 5)
- Type: Execute Code · Server-side Condition: **Request = Value** › `TROCAR_COLABORADOR` · Authorization `ADMIN_RH`
  ```sql
  :P13_ID_COLABORADOR := :P13_COLABORADOR_SELECIONADO;
  ```

**Branch "Recarregar"** (After Processing)
- Target: página **13**, sem itens nem Clear Cache. O valor novo já está na sessão.
- Server-side Condition: Request = Value › `TROCAR_COLABORADOR`

Por que assim: a página recarrega inteira, então os processos Before Header do §2.2 rodam de novo para o colaborador escolhido (validação de acesso e log de acesso salarial). Trocar o item só no navegador e dar Refresh pularia esses dois. `P13_ID_COLABORADOR` continua protegido por checksum, porque quem muda o valor é o processo no servidor.

O valor escolhido fica na sessão. Para o menu "Histórico de carreira" voltar sempre ao próprio usuário, coloque **Clear Cache: `13`** nessa entrada do Navigation Menu.

O caminho definitivo continua sendo o link "Histórico" na lista da página 12 (§7). O seletor resolve o RH enquanto ela não existe e pode ficar depois.

### 2.9 O que o protótipo mostra e ainda não tem dado

- **PDI e Resultados 360:** os módulos de Avaliações, Resultados 360 e Plano de desenvolvimento não existem no app. A aba "Desenvolvimento" mostra, por enquanto, as formações e certificações. Quando esses módulos existirem, basta acrescentar um `union all` no cursor `c_eventos`, com `ds_grupo = 'DEV'`.
- **"Aprovado por":** não há fluxo de aprovação no app. O RH informa quem aprovou (`P18_ID_APROVADOR` → `HISTORICO_CARREIRA.ID_APROVADOR`) ao lançar a movimentação, e o rodapé mostra "Aprovado por ..." ao lado de "Registrado por ... (RH) em ...". Sem aprovador informado, só a linha do registro aparece.
- **"CLT · efetivado":** o cadastro não guarda o regime de contratação. A linha "Contrato" aparece como "Efetivado em dd/mm/aaaa" quando existe uma movimentação `EFETIVACAO_CONTRATO`.

---

## 3. Página 18 · Modal Nova/Editar Movimentação

### 3.1 Atributos

- Page Mode: **Modal Dialog** · Authorization Scheme: `ADMIN_RH`
- JavaScript: cole os blocos 1 e 2 do `historico-carreira.js` em *Function and Global Variable Declaration* e *Execute when Page Loads*

### 3.2 Região "Movimentação"

- Type: **Form** · Source: Table/View `VW_HISTORICO_CARREIRA` · Primary Key: `ID_HISTORICO_CARREIRA`
- **Não** crie o processo "Automatic Row Processing (DML)". A view serve só para carregar; toda gravação passa pelo package.
- Processo Before Header **Initialize form** (Form - Initialization): mantenha o que o assistente cria.

Itens (crie os que não vierem do assistente):

| Item | Tipo | Detalhes |
|---|---|---|
| `P18_ID_HISTORICO_CARREIRA` | Hidden | PK · Value Protected |
| `P18_ID_COLABORADOR` | Hidden | Value Protected · Session State Protection: Checksum Required - Session Level |
| `P18_ST_REGISTRO` | Display Only | Label "Situação" · Default `RASCUNHO` |
| `P18_FL_ESTORNO` | Hidden | |
| `P18_CD_TIPO` | Hidden | Value Protected: **No** (o JS lê o valor) |
| `P18_ID_DEPARTAMENTO_ATUAL` | Hidden | Source: nenhum · Default (SQL): `select id_departamento from colaborador where id_colaborador = :P18_ID_COLABORADOR and id_empresa = :G_ID_EMPRESA` |
| `P18_ID_TIPO_MOVIMENTACAO` | Select List | LOV `LOV_TIPO_MOVIMENTACAO` · obrigatório |
| `P18_DT_EFETIVA` | Date Picker | Format Mask `DD/MM/YYYY` · obrigatório |
| `P18_NM_CARGO_ANTERIOR` | Display Only | Label "Cargo atual" · Source: Database Column `NM_CARGO_ANTERIOR` · Settings › Based On: **Page Item Value** · **Default** › Type: **SQL Query** (não use List of Values): `select cg.nome from colaborador c join cargo cg on cg.id_cargo = c.id_cargo where c.id_colaborador = :P18_ID_COLABORADOR and c.id_empresa = :G_ID_EMPRESA` |
| `P18_NM_DEPARTAMENTO_ANTERIOR` | Display Only | Label "Departamento atual" · mesma configuração do item acima, com Source `NM_DEPARTAMENTO_ANTERIOR` e Default (SQL Query): `select d.nome from colaborador c join departamento d on d.id_departamento = c.id_departamento where c.id_colaborador = :P18_ID_COLABORADOR and c.id_empresa = :G_ID_EMPRESA` |
| `P18_ID_DEPARTAMENTO_NOVO` | Popup LOV | LOV `LOV_DEPARTAMENTO_EMPRESA` · Label "Novo departamento" |
| `P18_ID_CARGO_NOVO` | Popup LOV | Label "Novo cargo" · LOV em cascata (abaixo) |
| `P18_ID_GESTOR_NOVO` | Popup LOV | LOV `LOV_COLABORADOR_ATIVO` · Label "Novo gestor" |
| `P18_VL_SALARIO_ANTERIOR` | Number Field | Server-side Condition: Authorization `ADMIN_RH` · sem Format Mask |
| `P18_VL_SALARIO_NOVO` | Number Field | Server-side Condition: Authorization `ADMIN_RH` · sem Format Mask |
| `P18_DS_MOTIVO` | Textarea | Max 1000 |
| `P18_ID_APROVADOR` | Popup LOV | LOV `LOV_COLABORADOR_ATIVO` · Label "Aprovado por" · opcional (em geral a gestão que aprovou; não pode ser o próprio colaborador) · aparece em todos os tipos |
| `P18_DS_OBSERVACAO` | Textarea | |
| `P18_DS_MOTIVO_ESTORNO` | Textarea | Source: nenhum · Label "Motivo do estorno" · **fica fora da região do formulário**, numa região própria "Estorno" (abaixo) |

**Região "Estorno"** (só para o motivo do estorno):
- Type: **Static Content** · Slot: Body · Sequence 20 (depois de "Movimentação") · Template: Standard
- Server-side Condition (Expression): `:P18_ST_REGISTRO = 'EFETIVADO' and :P18_FL_ESTORNO = 'N'`
- Mova `P18_DS_MOTIVO_ESTORNO` para ela (*Layout › Region*: `Estorno`) e tire a condição do item, que passa a ser da região.

Dentro da região de formulário, ao abrir um lançamento existente, o campo não aceita digitação: o motivo do estorno não é coluna da view, então fica numa região à parte.

Os campos de cargo e departamento anteriores aparecem preenchidos com a situação atual do colaborador. Na efetivação o package grava o snapshot definitivo.

**Cascading LOV do cargo** (`P18_ID_CARGO_NOVO` > List of Values > SQL Query):
```sql
select cg.nome d, cg.id_cargo r
  from cargo cg
 where cg.id_empresa = :G_ID_EMPRESA
   and cg.id_departamento = coalesce(to_number(:P18_ID_DEPARTAMENTO_NOVO),
                                     to_number(:P18_ID_DEPARTAMENTO_ATUAL))
 order by cg.nome
```
- Cascading List of Values > Parent Item(s): `P18_ID_DEPARTAMENTO_NOVO` · Items to Submit: `P18_ID_DEPARTAMENTO_ATUAL` · Parent Required: **No**

Para edição só de rascunho: em todos os itens editáveis, *Read Only* com condição `:P18_ST_REGISTRO <> 'RASCUNHO'`.

### 3.3 Dynamic Action "Tipo mudou"

Quando o RH troca o tipo da movimentação, a página descobre o código do tipo (`PROMOCAO`, `MERITO`…) e mostra só os campos que fazem sentido para ele. São duas ações em sequência: a primeira busca o código no banco e guarda em `P18_CD_TIPO`; a segunda roda o JS que mostra e esconde os campos lendo esse item.

**Antes de começar, confira:**

- [ ] Os blocos 1 e 2 do `historico-carreira.js` já estão na página (§3.1). Sem o bloco 1, a ação 2 dá `carreira is not defined` no console.
- [ ] `P18_CD_TIPO` existe, é **Hidden**, tem **Value Protected: No** e Source **Database Column** `CD_TIPO` (a view tem essa coluna; é assim que o tipo vem preenchido ao editar um rascunho).
- [ ] `P18_ID_TIPO_MOVIMENTACAO` tem opção vazia: *List of Values > Display Null Value* **On**, com *Null Display Value* `- Selecione -`. Sem ela o select abre já com "Admissão", nenhum Change dispara e `P18_CD_TIPO` fica vazio, então os campos de Admissão não aparecem.
- [ ] `P18_ID_CARGO_NOVO`, `P18_ID_DEPARTAMENTO_NOVO`, `P18_ID_GESTOR_NOVO` e os dois salários estão com **Validation > Value Required: Off**. Eles ficam escondidos em vários tipos, e um item obrigatório escondido trava o envio. A obrigatoriedade é feita pelo JS (marca visual) e validada de novo pelo package.

#### Passo 1 · Criar a Dynamic Action

1. Abra a página 18 no Page Designer.
2. Na aba **Rendering** (painel da esquerda), localize o item `P18_ID_TIPO_MOVIMENTACAO` dentro da região "Movimentação".
3. Clique com o botão direito no item e escolha **Create Dynamic Action**. O APEX cria a DA já ligada ao item, com uma ação *Show* de exemplo.
4. Com a DA selecionada (o nó com o raio), preencha no painel da direita:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `Tipo mudou` |
| When | Event | **Change** |
| When | Selection Type | Item(s) |
| When | Item(s) | `P18_ID_TIPO_MOVIMENTACAO` |
| Client-side Condition | Type | (nenhuma) |

#### Passo 2 · Ação 1: Set Value (busca o código do tipo)

1. Embaixo da DA, abra **True** e clique na ação *Show* que o APEX criou.
2. Preencha:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Action | **Set Value** |
| Settings | Set Type | **SQL Statement** |
| Settings | SQL Statement | (SQL abaixo) |
| Settings | Items to Submit | `P18_ID_TIPO_MOVIMENTACAO` |
| Settings | Escape Special Characters | On (padrão) |
| Settings | Suppress Change Event | On |
| Affected Elements | Selection Type | Item(s) |
| Affected Elements | Item(s) | `P18_CD_TIPO` |
| Execution | Sequence | 10 |
| Execution | Fire on Initialization | **Off** |
| Execution | Wait For Result | **On** |

```sql
select cd_tipo
  from tipo_movimentacao
 where id_tipo_movimentacao = :P18_ID_TIPO_MOVIMENTACAO
   and id_empresa = :G_ID_EMPRESA
```

Por que cada um importa:
- **Items to Submit:** o SQL roda no servidor e só enxerga o valor novo do select list se ele for enviado. Sem isso, `:P18_ID_TIPO_MOVIMENTACAO` chega vazio (ou com o valor antigo) e `P18_CD_TIPO` fica em branco. `G_ID_EMPRESA` é app item e já está na sessão, então não precisa entrar aqui.
- **Wait For Result:** faz a ação 2 esperar a resposta do servidor. Desligado, o JS roda antes de `P18_CD_TIPO` mudar e mostra os campos do tipo *anterior*.
- **Fire on Initialization Off:** no carregamento quem ajusta os campos é o bloco 2 do JS, com o `CD_TIPO` que já veio da view.

#### Passo 3 · Ação 2: Execute JavaScript Code (mostra/esconde os campos)

1. Clique com o botão direito em **True** e escolha **Create TRUE Action**.
2. Preencha:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Action | **Execute JavaScript Code** |
| Settings | Code | `carreira.ajustarCampos(true);` (bloco 3 do `.js`) |
| Affected Elements | Selection Type | (nenhum) |
| Execution | Sequence | 20 (precisa ser **maior** que a da ação 1) |
| Execution | Fire on Initialization | **Off** |

O `true` manda limpar os campos que ficaram escondidos, para não gravar, por exemplo, um cargo "fantasma" num mérito. No carregamento o bloco 2 chama `ajustarCampos(false)`, que preserva os valores do rascunho.

3. Salve a página (**Save**, Ctrl+S).

A árvore deve ficar assim:

```
Dynamic Actions
└── Change
    └── Tipo mudou            (Change · P18_ID_TIPO_MOVIMENTACAO)
        └── True
            ├── Set Value                  seq 10 → P18_CD_TIPO
            └── Execute JavaScript Code    seq 20
```

#### O que aparece em cada tipo

| Tipo | Novo cargo | Novo departamento | Novo gestor | Salários |
|---|---|---|---|---|
| Admissão | sim | sim | sim | sim |
| Promoção | **obrigatório** | – | sim | sim |
| Mudança de cargo | **obrigatório** | – | sim | sim |
| Transferência de área | sim | **obrigatório** | sim | – |
| Mudança de gestão | – | – | **obrigatório** | – |
| Mérito | – | – | – | sim |
| Efetivação, Jornada, Afastamento, Retorno, Desligamento | – | – | – | – |

Tipo, data, motivo, aprovador e observação aparecem sempre. Os salários só existem para quem tem `ADMIN_RH` (o JS ignora itens que não foram renderizados). Para mudar essas regras, edite `carreira.visivelEm` e `carreira.obrigatorioEm` no bloco 1 do JS; o package também descarta cargo, departamento e gestor nos tipos que não mexem na estrutura.

#### Passo 4 · Testar

1. Rode a página 13 de um colaborador e clique em **Nova movimentação**.
2. Abra o console do navegador (F12) e escolha **Promoção**: devem aparecer Novo cargo (com marca de obrigatório), Novo gestor e os salários. Digite `$v('P18_CD_TIPO')` no console: deve responder `"PROMOCAO"`.
3. Escolha um cargo, troque para **Mérito**: o cargo some e, ao voltar para Promoção, aparece vazio.
4. Salve um rascunho de Transferência, feche e reabra pelo ícone de edição na lista "Lançamentos (RH)": o departamento novo continua visível e preenchido.

#### Se não funcionar

| Sintoma | Causa provável | Correção |
|---|---|---|
| Nenhum campo some ao trocar o tipo | `P18_CD_TIPO` vazio | Confira *Items to Submit* da ação 1 e se o tipo tem `id_empresa` igual ao `G_ID_EMPRESA` da sessão |
| Os campos mostrados são os do tipo anterior | Ação 2 rodou antes da 1 terminar | *Wait For Result* On na ação 1 e sequência da ação 2 maior |
| `carreira is not defined` no console | Bloco 1 do JS não está na página | Cole-o em *Page > JavaScript > Function and Global Variable Declaration* |
| Ao salvar: "Session state protection violation" / item protegido alterado | `P18_CD_TIPO` com Value Protected On | Mude para **No** |
| Ao salvar: "... must have some value" num campo escondido | Item com Value Required On | Desligue *Value Required* nos itens da lista acima |
| Na movimentação nova o select já vem com um tipo e nenhum campo extra aparece | Select list sem opção vazia | *Display Null Value* On em `P18_ID_TIPO_MOVIMENTACAO` |
| Ao abrir um rascunho os campos certos não aparecem | `P18_CD_TIPO` sem Source | Source: Database Column `CD_TIPO` |

### 3.4 Botões

A modal tem cinco botões, e cada situação do lançamento mostra só os que fazem sentido:

| Situação | Botões visíveis |
|---|---|
| Nova movimentação | Cancelar · Salvar rascunho · Efetivar |
| Rascunho já salvo | Cancelar · Excluir rascunho · Salvar rascunho · Efetivar |
| Efetivado (não estornado) | Cancelar · Estornar |
| Estornado | Cancelar |

O nome do botão vira o *request* da submissão (`:REQUEST`), e é por ele que os processos da §3.5 decidem o que rodar. Por isso use **exatamente** os nomes da tabela, em maiúsculas.

**Antes de começar, confira:**

- [ ] O item `P18_ST_REGISTRO` tem Default `RASCUNHO` e `P18_FL_ESTORNO` tem Source `FL_ESTORNO` (§3.2). As condições dos botões leem esses dois itens.

#### Passo 1 · Criar a região dos botões

1. Na aba **Rendering**, clique com o botão direito em **Dialog Footer** e escolha **Create Region**.
2. Preencha:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `Botões` |
| Identification | Type | **Static Content** |
| Layout | Slot (Position) | **Dialog Footer** |
| Appearance | Template | **Buttons Container** |

Com isso os botões ficam fixos no rodapé da modal, como na página 27 (Nova Equipe).

#### Passo 2 · Criar os botões

Para cada linha da tabela abaixo: clique com o botão direito na região **Botões** › **Create Button**, e preencha os atributos.

| Button Name | Label | Slot (Button Position) | Sequence | Appearance |
|---|---|---|---|---|
| `CANCELAR` | Cancelar | **Close** | 10 | padrão |
| `EXCLUIR` | Excluir rascunho | **Delete** | 20 | padrão |
| `ESTORNAR` | Estornar | **Delete** | 30 | Template Options › Type: **Danger** |
| `SALVAR_RASCUNHO` | Salvar rascunho | **Next** | 40 | padrão |
| `EFETIVAR` | Efetivar | **Next** | 50 | **Hot: On** |

Em todos os botões, preencha também **Security › Authorization Scheme:** `ADMIN_RH`. A página já exige esse papel, e a autorização no botão é uma segunda proteção.

#### Passo 3 · Comportamento e condição de cada botão

**`CANCELAR`**
- Behavior › Action: **Defined by Dynamic Action**
- Clique com o botão direito no botão › **Create Dynamic Action** › Name `Cancelar` (Event *Click* já vem preenchido) › True action: **Cancel Dialog**
- Server-side Condition: nenhuma (aparece sempre)

**`EXCLUIR`**
- Behavior › Action: **Submit Page** · Execute Validations: **Off** · Warn on Unsaved Changes: *Do Not Check*
- Behavior › Requires Confirmation: **On** › Message `Excluir este rascunho?` › Style **Danger**
- Server-side Condition › Type **Expression** (PL/SQL):
  ```sql
  :P18_ST_REGISTRO = 'RASCUNHO' and :P18_ID_HISTORICO_CARREIRA is not null
  ```

**`ESTORNAR`**
- Behavior › Action: **Submit Page** · Execute Validations: **Off**
- Behavior › Requires Confirmation: **On** › Message `Estornar este lançamento?` › Style **Danger**
- Server-side Condition › Type **Expression**:
  ```sql
  :P18_ST_REGISTRO = 'EFETIVADO' and :P18_FL_ESTORNO = 'N'
  ```

**`SALVAR_RASCUNHO`**
- Behavior › Action: **Submit Page** · Execute Validations: **On** (padrão)
- Server-side Condition › Type **Expression**:
  ```sql
  nvl(:P18_ST_REGISTRO, 'RASCUNHO') = 'RASCUNHO'
  ```

**`EFETIVAR`**
- Behavior › Action: **Submit Page** · Execute Validations: **On**
- Behavior › Requires Confirmation: **On** › Message `Depois de efetivado, o lançamento não pode ser alterado. Continuar?` › Style **Warning**
- Server-side Condition › Type **Expression**:
  ```sql
  nvl(:P18_ST_REGISTRO, 'RASCUNHO') = 'RASCUNHO'
  ```

Por que esses detalhes importam:
- **`nvl(..., 'RASCUNHO')`:** a condição do botão pode ser avaliada antes de o Default do item ser aplicado. Numa movimentação nova `P18_ST_REGISTRO` ainda está nulo, e sem o `nvl` os botões Salvar e Efetivar sumiriam.
- **Execute Validations Off em Excluir e Estornar:** essas ações não dependem do formulário. Sem isso, um campo obrigatório vazio (ou somente leitura num lançamento efetivado) impediria a exclusão ou o estorno. O motivo do estorno é validado pelo package.
- **Requires Confirmation:** é o diálogo nativo do APEX, o mesmo que a página 16 usa. Não precisa de DA nem de JavaScript para confirmar.

Salve a página (**Save**, Ctrl+S). A árvore deve ficar assim:

```
Dialog Footer
└── Botões                 (Static Content · Buttons Container)
    ├── Close    CANCELAR          seq 10
    ├── Delete   EXCLUIR           seq 20
    ├── Delete   ESTORNAR          seq 30  (Danger)
    ├── Next     SALVAR_RASCUNHO   seq 40
    └── Next     EFETIVAR          seq 50  (Hot)
```

No export APEXlang, cada botão fica parecido com este:

```
button efetivar (
    buttonName: EFETIVAR
    label: Efetivar
    layout {
        sequence: 50
        region: @botões
        slot: next
    }
    appearance {
        buttonTemplate: @/text
        hot: true
        templateOptions: #DEFAULT#
    }
    behavior {
        requiresConfirmation: true
    }
    confirmation {
        message: Depois de efetivado, o lançamento não pode ser alterado. Continuar?
        style: warning
    }
    serverSideCondition {
        type: expression
        plsqlExpression: nvl(:P18_ST_REGISTRO, 'RASCUNHO') = 'RASCUNHO'
    }
    security {
        authorizationScheme: @admin-rh
    }
)
```

#### Passo 4 · Testar

Os botões que enviam a página só gravam alguma coisa depois que os processos da §3.5 existirem. Por enquanto, teste se eles aparecem nas situações certas:

1. Na página 13, clique em **Nova movimentação**: devem aparecer só *Cancelar*, *Salvar rascunho* e *Efetivar*.
2. Clique em **Cancelar**: a modal fecha sem erro.
3. Clique em **Efetivar**: deve abrir a confirmação. Clique em *Cancelar* no diálogo, porque o processo ainda não existe.
4. Depois de montar a §3.5, repita com um rascunho salvo (deve aparecer *Excluir rascunho*) e com um lançamento efetivado (só *Cancelar* e *Estornar*).

#### Se não funcionar

| Sintoma | Causa provável | Correção |
|---|---|---|
| Salvar e Efetivar não aparecem numa movimentação nova | Condição sem `nvl` | Use `nvl(:P18_ST_REGISTRO, 'RASCUNHO') = 'RASCUNHO'` |
| Efetivar aparece antes de Salvar rascunho (ou a ordem muda sozinha) | Botões do mesmo slot com a mesma sequência | Use as sequências da tabela do Passo 2 (40 e 50) |
| Os botões aparecem no meio do formulário | Região criada no Body | Mova a região `Botões` para o slot **Dialog Footer** |
| Cancelar não fecha a modal | Action ficou *Submit Page* ou a DA não tem *Cancel Dialog* | Action **Defined by Dynamic Action** e DA Click com *Cancel Dialog* |
| Clicar no botão recarrega a modal e nada acontece | Processos da §3.5 ainda não existem, ou o nome do botão difere do request do processo | Confira a grafia exata (`SALVAR_RASCUNHO`, `EFETIVAR`…) |
| Excluir ou Estornar mostra "... must have some value" | Execute Validations On | Desligue *Execute Validations* nesses dois botões |
| Botão não aparece para o RH | Authorization Scheme errado no botão | Use `ADMIN_RH` e confira se o usuário tem o papel |

### 3.5 Processos (Processing, nesta ordem)

Nenhum faz DML direto: todos chamam o package.

1. **Salvar movimentação** · PL/SQL · roda com `SALVAR_RASCUNHO` **ou** `EFETIVAR`. *When Button Pressed* aceita um botão só, então deixe-o **vazio** e use *Server-side Condition* › Type **Request is contained in Value** › Value `SALVAR_RASCUNHO,EFETIVAR` (nomes dos botões, separados por vírgula, sem espaço). Sem isso, Efetivar numa movimentação nova chama `efetivar_movimentacao` com ID nulo.
   ```sql
   begin
     if :P18_ID_HISTORICO_CARREIRA is null then
       :P18_ID_HISTORICO_CARREIRA := pkg_historico_carreira.registrar_movimentacao(
         p_id_colaborador       => :P18_ID_COLABORADOR,
         p_id_tipo_movimentacao => :P18_ID_TIPO_MOVIMENTACAO,
         p_dt_efetiva           => to_date(:P18_DT_EFETIVA, 'DD/MM/YYYY'),
         p_id_cargo_novo        => :P18_ID_CARGO_NOVO,
         p_id_departamento_novo => :P18_ID_DEPARTAMENTO_NOVO,
         p_id_gestor_novo       => :P18_ID_GESTOR_NOVO,
         p_vl_salario_anterior  => to_number(:P18_VL_SALARIO_ANTERIOR),
         p_vl_salario_novo      => to_number(:P18_VL_SALARIO_NOVO),
         p_ds_motivo            => :P18_DS_MOTIVO,
         p_ds_observacao        => :P18_DS_OBSERVACAO,
         p_id_aprovador         => :P18_ID_APROVADOR);
     else
       pkg_historico_carreira.atualizar_rascunho(
         p_id_historico_carreira => :P18_ID_HISTORICO_CARREIRA,
         p_id_tipo_movimentacao  => :P18_ID_TIPO_MOVIMENTACAO,
         p_dt_efetiva            => to_date(:P18_DT_EFETIVA, 'DD/MM/YYYY'),
         p_id_cargo_novo         => :P18_ID_CARGO_NOVO,
         p_id_departamento_novo  => :P18_ID_DEPARTAMENTO_NOVO,
         p_id_gestor_novo        => :P18_ID_GESTOR_NOVO,
         p_vl_salario_anterior   => to_number(:P18_VL_SALARIO_ANTERIOR),
         p_vl_salario_novo       => to_number(:P18_VL_SALARIO_NOVO),
         p_ds_motivo             => :P18_DS_MOTIVO,
         p_ds_observacao         => :P18_DS_OBSERVACAO,
         p_id_aprovador          => :P18_ID_APROVADOR);
     end if;
   end;
   ```
2. **Efetivar** · When Button Pressed `EFETIVAR` · Success Message "Movimentação efetivada."
   ```sql
   pkg_historico_carreira.efetivar_movimentacao(:P18_ID_HISTORICO_CARREIRA);
   ```
3. **Estornar** · When Button Pressed `ESTORNAR` · Success Message "Lançamento estornado."
   ```sql
   pkg_historico_carreira.estornar_movimentacao(:P18_ID_HISTORICO_CARREIRA, :P18_DS_MOTIVO_ESTORNO);
   ```
4. **Excluir rascunho** · When Button Pressed `EXCLUIR`
   ```sql
   pkg_historico_carreira.excluir_rascunho(:P18_ID_HISTORICO_CARREIRA);
   ```
5. **Fechar** · Type: Close Dialog · Server-side Condition: Request is contained in Value `SALVAR_RASCUNHO,EFETIVAR,ESTORNAR,EXCLUIR`

Os processos 1 e 2 rodam na mesma submissão. Se a efetivação falhar, o APEX desfaz também o rascunho salvo no passo 1 (tudo é uma transação só) e a mensagem do package aparece na modal.

### 3.6 Log de acesso salarial

Processo Before Header (depois do *Initialize form*) · Authorization `ADMIN_RH` · Server-side Condition: `P18_ID_HISTORICO_CARREIRA` is not null
```sql
pkg_historico_carreira.registrar_acesso_salarial(
  p_id_colaborador => :P18_ID_COLABORADOR,
  p_contexto       => 'P18 · lançamento #' || :P18_ID_HISTORICO_CARREIRA);
```

---

## 4. Páginas 19 e 21 · Formações e certificações

O RH cadastra as formações de um colaborador numa **lista** (página 19) e edita cada uma num **formulário em modal** (página 21). É o mesmo padrão das páginas 15/16 (Empresas) e 13/18 (Movimentações).

> **Por que não Interactive Grid:** no 26.1.5 o painel de propriedades não oferece onde ligar a edição de uma região; nos exports do app, a edição (`edit { enabled: true ... }`) só aparece em regiões criadas pelo assistente de criação de página. Por isso as duas páginas são criadas juntas pelo assistente. Ver `docs/ai-context/09-erros-e-solucoes.md` §4.8.

| Página | Tipo | O que faz |
|---|---|---|
| 19 · Formações e certificações | Normal · Interactive Report | Lista as formações do colaborador, com destaque para formações com validade vencida ou a vencer |
| 21 · Formação | Modal Dialog · Form | Cria, edita e exclui uma formação, inclusive o anexo (PDF ou imagem) |

Os dados vão direto para a tabela `FORMACAO_COLABORADOR` (DML nativo do APEX). Isso é aceitável aqui porque a regra de imutabilidade vale só para as movimentações. Os triggers preenchem criação/alteração e o log.

### 4.1 Antes de começar

1. **Apague as versões antigas das páginas 19 e 21**, se já existirem (a grid e o anexo do desenho anterior). Com a página aberta no Page Designer: menu da página (ícone de engrenagem/lixeira no topo) › **Delete Page** (confirmar no 26.1.5). O assistente não cria páginas em números já ocupados.
2. Confira que a LOV `LOV_TIPO_FORMACAO` existe (§1.4).
3. Confira que o botão **Formações** da página 13 (§2.6) leva para a página 19 com `P19_ID_COLABORADOR` = `&P13_ID_COLABORADOR.`.

### 4.2 Criar as duas páginas pelo assistente

1. **Create › Page** (no App Builder, dentro do app 100).
2. Escolha **Interactive Report**.
3. Preencha (os nomes dos campos são do assistente; confirmar no 26.1.5):

| Campo | Valor |
|---|---|
| Page Number | `19` |
| Name | `Formações e certificações` |
| Page Mode | Normal |
| Data Source › Table/View | `FORMACAO_COLABORADOR` |
| **Include Form Page** | **On** |
| Form Page Number | `21` |
| Form Page Name | `Formação` |
| Form Page Mode | **Modal Dialog** |
| Primary Key Column | `ID_FORMACAO` |
| Navigation › Create Navigation Menu Entry | **Off** (a página 19 é aberta pela página 13; a 21 é modal) |
| Breadcrumb | Don't use breadcrumbs |

4. **Create Page**.

Como conferir: no export da página 21, a região do formulário tem o bloco abaixo. Sem ele, o formulário fica só leitura.
```
edit {
    enabled: true
    allowedOperations: [
        add
        update
        delete
    ]
}
```

Se o assistente criar entradas no menu mesmo assim, apague-as em **Shared Components › Navigation Menu**.

### 4.3 Página 19 · atributos e acesso

A página 19 recebe o colaborador pela URL (`P19_ID_COLABORADOR`, vindo do botão **Formações** da página 13), confere se o usuário pode vê-lo e busca o nome dele para o cabeçalho. Tudo isso acontece **antes** de a página ser montada, num processo Before Header.

**Antes de começar, confira:**

- [ ] As páginas 19 e 21 foram criadas juntas pelo assistente (§4.2).
- [ ] O package `pkg_historico_carreira` está compilado (tem `fn_pode_ver_colaborador` e `fn_hoje`).
- [ ] O app item `G_ID_EMPRESA` é preenchido no login (§1.1). Sem ele, o processo do Passo 4 dá `ORA-01403`.

#### Passo 1 · Autorização da página

1. Abra a página 19 no Page Designer e clique no nó da página (o primeiro da árvore **Rendering**).
2. No painel da direita:

| Seção | Atributo | Valor |
|---|---|---|
| Security | Authorization Scheme | **ADMIN_RH** |
| Security | Page Access Protection | **Arguments Must Have Checksum** (o assistente já coloca) |

#### Passo 2 · Item `P19_ID_COLABORADOR`

1. Na árvore **Rendering**, clique com o botão direito em **Body** › **Create Page Item**.
2. Preencha:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `P19_ID_COLABORADOR` |
| Identification | Type | **Hidden** |
| Settings | Value Protected | **On** (padrão) |
| Layout | Sequence | 20 |
| Source | Type | **Null** (nenhum) |
| Default | Type | (nenhum) |
| Security | Session State Protection | **Checksum Required - Session Level** |

Por que a proteção importa: sem ela, quem tem acesso à página pode trocar o número na URL e abrir as formações de outro colaborador. O processo do Passo 4 também barra isso, mas o checksum barra antes, sem nem chegar ao banco.

#### Passo 3 · Item `P19_NM_COLABORADOR`

1. Botão direito em **Body** › **Create Page Item**.
2. Preencha:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `P19_NM_COLABORADOR` |
| Identification | Type | **Hidden** |
| Settings | Value Protected | **On** |
| Layout | Sequence | 30 |
| Source | Type | **Null** (nenhum) |
| Default | Type | **(nenhum)**: apague o SQL se já tiver colocado um |

Quem preenche esse item é o processo do Passo 4.

> **Por que não usar Source/Default:** Source e Default só são calculados quando o item é renderizado. Os itens ficam abaixo da região da lista, então o texto com o nome seria montado antes do valor existir e sairia sem o nome. No Before Header, o valor já está na sessão antes de qualquer região.

#### Passo 4 · Processo "Validar acesso" (Before Header)

1. Na árvore **Rendering**, abra **Pre-Rendering**, clique com o botão direito em **Before Header** › **Create Process**.
2. Preencha:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `Validar acesso` |
| Identification | Type | **Execute Code** |
| Source | Location | Local Database |
| Source | Language | PL/SQL |
| Source | PL/SQL Code | (código abaixo) |
| Execution | Sequence | 10 |
| Execution | Point | **Before Header** |
| Server-side Condition | Type | (nenhuma: roda sempre) |

```sql
if :P19_ID_COLABORADOR is null
   or pkg_historico_carreira.fn_pode_ver_colaborador(:P19_ID_COLABORADOR) = 'N' then
  raise_application_error(-20012, 'Você não tem acesso a este colaborador.');
end if;

select nome_completo
  into :P19_NM_COLABORADOR
  from colaborador
 where id_colaborador = :P19_ID_COLABORADOR
   and id_empresa     = :G_ID_EMPRESA;
```

O `-20012` aparece como mensagem amigável se o tratamento da §1.3 estiver feito. Sem ele, a mensagem vem com `ORA-20012` na frente, mas o bloqueio funciona igual.

#### Passo 5 · Cabeçalho da página (igual ao da página 13)

A página 19 não está no protótipo. Para parecer parte do mesmo módulo, ela usa o **mesmo cabeçalho da página 13**: uma faixa branca de ponta a ponta, título de 26px em negrito e subtítulo cinza. O `historico-carreira.css` já tem esse estilo (`.hc-titulo`). Basta uma região Static Content com o HTML abaixo.

1. Na árvore **Rendering**, clique com o botão direito em **Body** › **Create Region** e preencha:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `Cabeçalho` |
| Identification | Type | **Static Content** |
| Source | HTML Code | (HTML abaixo) |
| Layout | Sequence | **5** (antes do Interactive Report, que é 10) |
| Appearance | Template | **Blank with Attributes (No Grid)** |

```html
<div class="hc" data-hc>
  <header class="hc-titulo">
    <div>
      <h1>Formações e certificações</h1>
      <p>Cursos, idiomas e certificações de &P19_NM_COLABORADOR!HTML.
         Formações vencidas ou que vencem nos próximos 60 dias aparecem destacadas.</p>
    </div>
  </header>
</div>
```

2. Clique na página (primeiro nó da árvore) › **CSS › File URLs**: `#APP_FILES#historico-carreira#MIN#.css`, o mesmo arquivo da página 13.
3. Clique na região **Formações e certificações** (o Interactive Report) e **apague** o *Header and Footer › Header Text*. O nome do colaborador agora fica no subtítulo do cabeçalho.
4. Salve a página (**Save**, Ctrl+S).

Por que cada parte importa:
- **`class="hc"`:** é onde ficam as cores (tokens `--hc-*`). Sem esse `div`, o título sai sem fundo e sem cor.
- **`data-hc`:** liga as regras de "página inteira" do CSS (`body:has([data-hc])`). Elas tiram a moldura de 2rem em volta do conteúdo e pintam o fundo cinza até o rodapé, como na página 13. O Interactive Report ganha margem de 32px nas laterais.
- **`!HTML`:** escapa o nome do colaborador antes de colocá-lo no HTML. É a forma segura de usar um item dentro de HTML.
- **Sequence 5:** o processo "Validar acesso" (Before Header) já preencheu `P19_NM_COLABORADOR` antes de qualquer região ser montada, então o nome aparece mesmo com o cabeçalho sendo a primeira região.

A árvore deve ficar assim:

```
Pre-Rendering
└── Before Header
    └── Validar acesso            (Execute Code · seq 10)
Components
└── Body
    ├── Cabeçalho                 (Static Content · seq 5)
    ├── Formações e certificações (Interactive Report · seq 10)
    ├── P19_ID_COLABORADOR        (Hidden · seq 20)
    └── P19_NM_COLABORADOR        (Hidden · seq 30)
```

#### Como conferir no export da página 19

- `security { authorizationScheme: @admin-rh ... }` no nó da página;
- `sessionStateProtection: checksumRequiredSessionLevel` em `P19_ID_COLABORADOR`. O export não mostra `valueProtected` quando a opção está On, porque só escreve o valor `false`;
- um `process validar-acesso` com `point: beforeHeader`;
- **nenhum** bloco `default` nem `source` em `P19_NM_COLABORADOR`. Se aparecer `default { type: sqlQuerySingleValue ... }`, o Passo 3 não foi feito;
- uma `region` "Cabeçalho" `staticContent` com sequence 5 e template `@/blank-with-attributes-no-grid`, e **nenhum** `headerText` no Interactive Report;
- `fileUrls: #APP_FILES#historico-carreira#MIN#.css` no bloco `css` da página.

### 4.4 Página 19 · região da lista (Interactive Report)

O assistente cria a região com uma query de **todas** as colunas e **sem filtro**: a lista mostra as formações de todos os colaboradores de todas as empresas. Esta etapa troca a query, ajusta as colunas, os botões e o destaque das certificações.

Faça **nesta ordem**: as colunas mudam quando a query muda, então ajustar colunas antes do Passo 1 é trabalho perdido.

**Antes de começar, confira:**

- [ ] A §4.3 está feita: `P19_ID_COLABORADOR` existe e o processo "Validar acesso" preenche `P19_NM_COLABORADOR`.
- [ ] A LOV `LOV_TIPO_FORMACAO` existe em Shared Components (§1.4).

#### Passo 1 · Trocar a query da região

1. Clique na região **Formações e certificações**.
2. No painel da direita, em **Source**, o Type já é **SQL Query** (o assistente gera a query a partir da tabela). Apague todo o texto de **SQL Query** e cole:
   ```sql
   select f.id_formacao,
          f.tp_formacao,
          f.ds_titulo,
          f.ds_instituicao,
          f.dt_inicio,
          f.dt_conclusao,
          f.dt_validade,
          f.nr_carga_horaria,
          f.ds_link,
          f.ds_nome_arquivo,
          case
            when f.dt_validade <  pkg_historico_carreira.fn_hoje(:G_ID_EMPRESA)      then 'VENCIDA'
            when f.dt_validade <= pkg_historico_carreira.fn_hoje(:G_ID_EMPRESA) + 60 then 'A VENCER'
          end as ds_alerta_validade
     from formacao_colaborador f
    where f.id_colaborador = :P19_ID_COLABORADOR
      and f.id_empresa     = :G_ID_EMPRESA
    order by coalesce(f.dt_conclusao, f.dt_inicio) desc
   ```
3. Confira os outros atributos:

| Seção | Atributo | Valor |
|---|---|---|
| Source | Location | Local Database |
| Source | Type | SQL Query |
| Source | Page Items to Submit | `P19_ID_COLABORADOR` |
| Messages | When No Data Found | `Nenhuma formação cadastrada.` |

4. Salve (Ctrl+S). Ao salvar, o APEX recria a lista de colunas a partir da query nova: somem `ID_EMPRESA`, `ID_COLABORADOR`, `BL_ANEXO`, `DS_MIME_TYPE`, `DT_CRIACAO`, `USR_CRIACAO`, `DT_ALTERACAO` e `USR_ALTERACAO`, e aparece `DS_ALERTA_VALIDADE`. Se ele pedir confirmação para remover colunas, confirme.

   > **Não apague colunas pela árvore no lugar deste passo.** No Interactive Report as colunas vêm só da query: apagar `ID_EMPRESA` etc. em *Columns* não tira o dado da query nem cria `DS_ALERTA_VALIDADE`, e não existe "Create Column" para criá-la à mão. O único jeito é trocar o texto da query.

Por que cada parte importa:
- **`where ... id_empresa = :G_ID_EMPRESA`:** é o isolamento entre empresas (regra de ouro 3). Sem ele, o RH de uma empresa vê as formações das outras.
- **`where ... id_colaborador = :P19_ID_COLABORADOR`:** a página é de um colaborador só.
- **Page Items to Submit:** o Interactive Report busca as linhas por Ajax quando o usuário pagina, filtra ou ordena. Sem esse item, a busca vai sem o colaborador e a lista volta vazia.
- **`ds_alerta_validade`:** a coluna existe só para o destaque do Passo 6. Ela usa `fn_hoje`, a data de hoje no fuso da empresa, e marca **qualquer formação com validade** (não só certificações) que já venceu ou vence em até 60 dias. Treinamentos obrigatórios, como NR-10 e NR-35, costumam ser do tipo "Curso" e também vencem. A regra é a mesma da linha do tempo da página 13 (`08_pkg_historico_carreira_ui.sql`), então as duas telas sempre concordam. Sem validade, a coluna fica vazia.

#### Passo 2 · Colunas

Na árvore **Rendering**, abra a região › **Columns** e clique em cada coluna. Preencha:

| Coluna | Type | Heading | Outros atributos |
|---|---|---|---|
| `ID_FORMACAO` | **Hidden** | (vazio) | Source › Primary Key: On (já vem) |
| `TP_FORMACAO` | **Plain Text (based on List of Values)** | Tipo | List of Values › **`LOV_TIPO_FORMACAO`** (confirmar no 26.1.5) |
| `DS_TITULO` | Plain Text | Título | |
| `DS_INSTITUICAO` | Plain Text | Instituição | |
| `DT_INICIO` | Plain Text | Início | Appearance › Format Mask `DD/MM/YYYY` |
| `DT_CONCLUSAO` | Plain Text | Conclusão | Appearance › Format Mask `DD/MM/YYYY` |
| `DT_VALIDADE` | Plain Text | Validade | Appearance › Format Mask `DD/MM/YYYY` |
| `NR_CARGA_HORARIA` | Plain Text | Carga horária (h) | Alinhamento à direita (já vem) |
| `DS_LINK` | **Link** | Link | Link › Target: Type **URL** · URL `#DS_LINK#` · Link Text `Abrir` |
| `DS_NOME_ARQUIVO` | Plain Text | Anexo | O download fica no formulário (página 21) |
| `DS_ALERTA_VALIDADE` | Plain Text | Situação | Mostra "VENCIDA" ou "A VENCER"; vazio nas demais linhas |

Por que cada um importa:
- **LOV em `TP_FORMACAO`:** a tabela guarda o código (`CERTIFICACAO`, `POS`…). A LOV mostra o texto ("Certificação", "Pós-graduação").
- **Heading "Situação" em `DS_ALERTA_VALIDADE`:** "Validade" já é o heading de `DT_VALIDADE`, e dois títulos iguais confundem o RH.
- **Format Mask:** sem ela, a data sai no formato da sessão, que pode vir em inglês.

#### Passo 3 · Link de edição (lápis de cada linha)

O assistente já cria o link apontando para a 21. Para achar a configuração, selecione a região e digite `Link` na busca do painel (confirmar no 26.1.5).

| Seção | Atributo | Valor |
|---|---|---|
| Link | Link Column | **Link to Custom Target** |
| Link | Target | Page **21** · Set Items: `P21_ID_FORMACAO` = `#ID_FORMACAO#` · Clear Cache **`21`** |

Clicar em **Target** abre a janela do link (Link Builder): Type *Page in this application*, Page, a tabela *Set Items* (Name / Value) e Clear Cache (confirmar os nomes no 26.1.5).

Por que o Clear Cache `21`: sem ele, a modal pode abrir com valores de uma formação vista antes (anexo, datas) nos itens que não vêm da tabela.

#### Passo 4 · Botão "Nova formação"

O assistente cria um botão `CREATE` na barra do relatório. Clique nele e ajuste:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Button Name | `NOVA_FORMACAO` (ou mantenha `CREATE`; nenhum processo da 19 depende do nome) |
| Identification | Label | `Nova formação` |
| Layout | Slot | Right of Interactive Report Search Bar (já vem) |
| Appearance | Hot | **On** |
| Behavior | Action | **Redirect to Page in this Application** |
| Behavior | Target | Page **21** · Set Items: Name `P21_ID_COLABORADOR`, Value **`&P19_ID_COLABORADOR.`** · Clear Cache **`21`** |
| Security | Authorization Scheme | `ADMIN_RH` |

**Atenção ao Value do Set Items:** é fácil preencher só o Name e deixar o Value vazio. Escreva `&P19_ID_COLABORADOR.` com o `&` no começo e o ponto no final. Sem o valor, a formação é criada sem colaborador e a validação da 21 responde "Formação não encontrada.".

#### Passo 5 · Botão "Voltar ao histórico"

1. Clique com o botão direito na região **Formações e certificações** › **Create Button**.
2. Preencha:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Button Name | `VOLTAR_AO_HISTORICO` |
| Identification | Label | `Voltar ao histórico` |
| Layout | Slot | Right of Interactive Report Search Bar |
| Layout | Sequence | 20 (depois de "Nova formação") |
| Appearance | Hot | Off |
| Behavior | Action | **Redirect to Page in this Application** |
| Behavior | Target | Page **13** · **sem** Set Items · **sem** Clear Cache |

Sem itens e sem Clear Cache, a página 13 volta no colaborador que estava aberto, porque `P13_ID_COLABORADOR` continua na sessão.

#### Passo 6 · Dynamic Action "Atualizar depois da modal"

O assistente costuma criar a DA **Edit Report - Dialog Closed**. Confira na árvore em **Dynamic Actions**:

| Seção | Atributo | Valor |
|---|---|---|
| When | Event | **Dialog Closed** |
| When | Selection Type | Region |
| When | Region | Formações e certificações |
| True action | Action | **Refresh** › Region `Formações e certificações` |

Se não existir, crie igual à da página 15. Salve a página (Ctrl+S).

#### Passo 7 · Destaque das certificações e relatório padrão

Esta parte é feita **com a página rodando**, não no Page Designer. O destaque fica gravado no relatório salvo, não nas propriedades da região.

**Dados de teste.** Para ver o destaque funcionando, o colaborador precisa ter formações, e a página 21 (que cadastra) só fica pronta na §4.5. Por isso, insira três linhas de teste direto no banco, em **SQL Workshop › SQL Commands**:

a. Descubra o ID do colaborador que você vai abrir na página 13:
   ```sql
   select id_colaborador, nome_completo, id_empresa
     from colaborador
    order by nome_completo;
   ```
b. Troque o `123` pelo ID escolhido e rode o bloco abaixo. Ele cria uma certificação **a vencer** (amarela), uma **vencida** (vermelha) e um curso sem validade (sem destaque):
   ```sql
   declare
     l_id_colaborador number := 123;  -- troque pelo ID do passo a
     l_id_empresa     number;
   begin
     select id_empresa
       into l_id_empresa
       from colaborador
      where id_colaborador = l_id_colaborador;

     insert into formacao_colaborador
       (id_empresa, id_colaborador, tp_formacao, ds_titulo, ds_instituicao,
        dt_conclusao, dt_validade, nr_carga_horaria)
     values
       (l_id_empresa, l_id_colaborador, 'CERTIFICACAO', '[TESTE] Certificação a vencer', 'Instituição de teste',
        trunc(sysdate) - 30, trunc(sysdate) + 30, 40);

     insert into formacao_colaborador
       (id_empresa, id_colaborador, tp_formacao, ds_titulo, ds_instituicao,
        dt_conclusao, dt_validade, nr_carga_horaria)
     values
       (l_id_empresa, l_id_colaborador, 'CERTIFICACAO', '[TESTE] Certificação vencida', 'Instituição de teste',
        trunc(sysdate) - 400, trunc(sysdate) - 10, 40);

     insert into formacao_colaborador
       (id_empresa, id_colaborador, tp_formacao, ds_titulo, ds_instituicao,
        dt_inicio, dt_conclusao, nr_carga_horaria, ds_link)
     values
       (l_id_empresa, l_id_colaborador, 'CURSO', '[TESTE] Curso sem validade', 'Instituição de teste',
        trunc(sysdate) - 240, trunc(sysdate) - 200, 20, 'https://example.com');

     commit;
   end;
   ```
   `ID_FORMACAO`, criação e usuário são preenchidos pela identity e pelo trigger. As datas respeitam as constraints da tabela (validade depois da conclusão, conclusão depois do início).
c. Depois de salvar o relatório (item 4 abaixo), apague as linhas de teste:
   ```sql
   delete from formacao_colaborador
    where ds_titulo like '[TESTE]%';
   commit;
   ```
   O destaque fica gravado no relatório Primary, não nos dados, então continua valendo sem essas linhas.

1. Entre no Builder com seu usuário de desenvolvedor e rode a página 19 pelo botão **Formações** da página 13, com o colaborador usado nos dados de teste.
2. Se a coluna **Situação** não aparecer: **Actions › Columns**, mova `Situação` para *Display in Report* › **Apply**.
3. **Actions › Format › Highlight** e crie as duas regras:

| Name | Sequence | Highlight Type | Background Color | Text Color | Column | Operator | Expression |
|---|---|---|---|---|---|---|---|
| `Vencida` | 10 | **Row** | `#FCEDEC` | `#B3261E` | `Situação` | `=` | `VENCIDA` |
| `A vencer` | 20 | **Row** | `#FFF4DB` | `#8A5A00` | `Situação` | `=` | `A VENCER` |

As cores são as mesmas das etiquetas "Vencida" e "Vence em breve" da linha do tempo da página 13 (`--hc-alerta-suave`/`--hc-alerta` e `--hc-atencao-suave`/`--hc-atencao` no `historico-carreira.css`). Assim, o RH vê a mesma cor nas duas telas. O texto escuro sobre o fundo claro tem contraste acima de 4,5:1 (WCAG AA). Digite os códigos no campo de cor do diálogo, porque as cores prontas da paleta do APEX não batem com essas. A regra "Vencida" fica com a sequência menor por ser a mais grave.

4. **Actions › Report › Save Report** › Save: *As Default Report Settings* › Default Report Type: **Primary** › **Apply**. Essa opção só aparece para o desenvolvedor logado no Builder.

Sem o passo 4, o destaque fica só na sua sessão e o RH não vê.

A árvore deve ficar assim:

```
Components
└── Body
    ├── Formações e certificações          (Interactive Report)
    │   ├── Columns
    │   │   ├── ID_FORMACAO                (Hidden)
    │   │   ├── TP_FORMACAO                (Plain Text based on LOV)
    │   │   ├── DS_TITULO … DS_NOME_ARQUIVO
    │   │   └── DS_ALERTA_VALIDADE
    │   ├── NOVA_FORMACAO                  (seq 10 · Hot)
    │   └── VOLTAR_AO_HISTORICO            (seq 20)
    ├── P19_ID_COLABORADOR
    └── P19_NM_COLABORADOR
Dynamic Actions
└── Dialog Closed
    └── Edit Report - Dialog Closed  → Refresh Formações e certificações
```

#### Como conferir no export da página 19

- A `sqlQuery` da região tem o `where f.id_colaborador = :P19_ID_COLABORADOR and f.id_empresa = :G_ID_EMPRESA`, e não aparece mais `from "FORMACAO_COLABORADOR"` entre aspas;
- **não existem** as colunas `ID_EMPRESA`, `ID_COLABORADOR`, `BL_ANEXO`, `DS_MIME_TYPE`, `DT_CRIACAO`, `USR_CRIACAO`, `DT_ALTERACAO`, `USR_ALTERACAO`; existe `column DS_ALERTA_VALIDADE`;
- `column TP_FORMACAO` tem `type: plainTextBasedOnLov` e um bloco `lov { lov: @... }` apontando para a LOV de tipo de formação;
- nenhum heading em inglês ou com prefixo de coluna (`Dt Inicio`, `Ds Link`, `Nr Carga Horaria`…);
- o botão "Nova formação" tem o item **com valor**:
  ```
  target: {
      page: 21
      items: {
          P21_ID_COLABORADOR: &P19_ID_COLABORADOR.
      }
      clearCache: 21
  }
  ```
  Se aparecer `P21_ID_COLABORADOR:` sem nada depois, o Value ficou vazio (Passo 4);
- `button voltar-ao-historico` com `target: { page: 13 }`;
- o `link` da região com `page: 21`, `P21_ID_FORMACAO: \#ID_FORMACAO#\` e, de preferência, `clearCache: 21`;
- `savedReport primary` só com as colunas da query nova (incluindo `displayColumn DS_ALERTA_VALIDADE`) e com as duas regras de destaque. O Highlight Type *Row* e o operador `=` são o padrão, por isso o export não os mostra:
  ```
  highlight ir-condition-2 (
      name: Vencida
      condition {
          column: DS_ALERTA_VALIDADE
          value: VENCIDA
      }
      colors {
          background: #fcedec
          text: #b3261e
      }
      execution {
          sequence: 10
      }
  )
  ```

#### Testar

1. Na página 13, escolha um colaborador e clique em **Formações**: o subtítulo do cabeçalho mostra "... certificações de *Nome*" e a lista mostra só as formações dele (ou "Nenhuma formação cadastrada.").
2. Copie a URL, troque o número de `P19_ID_COLABORADOR` e abra: deve dar erro de checksum.
3. Clique em **Nova formação**: a modal abre. Feche-a e clique em **Voltar ao histórico**: a página 13 volta no mesmo colaborador.
4. O teste completo, com cadastro, destaque e exclusão, está na §4.6, depois de montar a página 21.

#### Se não funcionar

| Sintoma | Causa provável | Correção |
|---|---|---|
| A lista mostra formações de outros colaboradores ou de outras empresas | Query do assistente, sem `where` | Passo 1 |
| A lista ficou vazia depois de trocar a query (antes mostrava tudo) | A página foi aberta direto pelo **Run** do Page Designer, então `P19_ID_COLABORADOR` está vazio; ou as formações são de outro colaborador ou de outra empresa (`G_ID_EMPRESA`) | Abra a 19 sempre pelo botão **Formações** da 13 (§2.6). Confira os valores em *Session* na barra de desenvolvedor (confirmar no 26.1.5) e compare com `select id_formacao, id_empresa, id_colaborador, ds_titulo from formacao_colaborador` |
| A lista sempre vazia, mesmo com formações cadastradas | `P19_ID_COLABORADOR` vazio ou fora de *Page Items to Submit* | §4.3 Passo 2 e §4.4 Passo 1 |
| Subtítulo do cabeçalho sem o nome | Nome no Source/Default de `P19_NM_COLABORADOR`, ou processo Validar acesso faltando | §4.3 Passos 3 e 4 |
| `ORA-01403: no data found` ao abrir a 19 | `G_ID_EMPRESA` vazio, ou colaborador de outra empresa | Confira o login (§1.1) e o colaborador escolhido na 13 |
| Coluna Tipo mostra `CERTIFICACAO` em vez de "Certificação" | Coluna sem LOV | Passo 2: Plain Text (based on List of Values) com `LOV_TIPO_FORMACAO` |
| Colunas que deviam ter sumido ainda aparecem | A query foi editada mas a página não foi salva, ou o export é anterior | Salve (Ctrl+S) e exporte de novo |
| `DS_ALERTA_VALIDADE` não existe em *Columns* e não há como criá-la | A query da região ainda é a do assistente. No Interactive Report as colunas vêm só da query: não existe "Create Column", e apagar colunas na árvore não muda a query | Passo 1: troque o texto de **Source › SQL Query** e salve. No export, a `sqlQuery` não pode mais ter `from "FORMACAO_COLABORADOR"` |
| Ao salvar a query nova, erro com `PKG_HISTORICO_CARREIRA` ou `FN_HOJE` (`ORA-00904`, `ORA-06553`, `PLS-00201`) | Package não compilado ou inválido, então o Builder recusa a query e mantém a antiga | Recompile `04_pkg_historico_carreira.pks`/`.pkb` e salve de novo (ver `docs/ai-context/09-erros-e-solucoes.md`) |
| A coluna Situação não aparece | O relatório salvo é anterior à coluna nova | Passo 7, item 2, e salve o Primary de novo |
| "Formação não encontrada." ao criar | Set Items do botão sem Value | Passo 4: Value `&P19_ID_COLABORADOR.` |
| Destaque some ao sair e entrar | Relatório não foi salvo como Primary | Passo 7, item 4, logado no Builder |
| "Voltar ao histórico" abre a 13 no próprio usuário | Clear Cache `13` no botão | Tire o Clear Cache (Passo 5) |

### 4.5 Página 21 · formulário da formação (Modal)

1. Página 21 › **Security › Authorization Scheme:** `ADMIN_RH` · Title `Formação`.
2. **Itens criados pelo assistente** (ajuste ou apague):

| Item | O que fazer |
|---|---|
| `P21_ID_FORMACAO` | Hidden · PK · Session State Protection: **Checksum Required - Session Level** |
| `P21_ID_EMPRESA` | Hidden · Value Protected (o valor vem do processo do passo 4) |
| `P21_ID_COLABORADOR` | Hidden · Value Protected · Session State Protection: **Checksum Required - Session Level** (vem na URL do botão "Nova formação") |
| `P21_TP_FORMACAO` | **Select List** · LOV `LOV_TIPO_FORMACAO` · Display Null Value On (`- Selecione -`) · Value Required On · Label "Tipo" |
| `P21_DS_TITULO` | Text Field · Value Required On · Label "Título" |
| `P21_DS_INSTITUICAO` | Text Field · Value Required On · Label "Instituição" |
| `P21_DT_INICIO`, `P21_DT_CONCLUSAO`, `P21_DT_VALIDADE` | Date Picker · Format Mask `DD/MM/YYYY` · Labels "Início", "Conclusão", "Validade" (vale para qualquer tipo: certificações, cursos obrigatórios etc.) |
| `P21_NR_CARGA_HORARIA` | Number Field · Label "Carga horária (h)" |
| `P21_DS_LINK` | Text Field · Label "Link (https://...)" |
| `P21_BL_ANEXO` | **File Upload** (ver passo 3) |
| `P21_DS_MIME_TYPE`, `P21_DS_NOME_ARQUIVO` | **Apague.** O item de upload já grava essas colunas |
| `P21_DT_CRIACAO`, `P21_USR_CRIACAO`, `P21_DT_ALTERACAO`, `P21_USR_ALTERACAO` | **Apague.** O trigger preenche e sobrescreve qualquer valor do formulário |

3. **Anexo (`P21_BL_ANEXO`)** (confirmar os nomes no 26.1.5):
   - Type: **File Upload** (não use *Image Upload*: o anexo pode ser PDF)
   - Label `Anexo (PDF ou imagem)`
   - Storage › Type: **BLOB column specified in Item Source attribute**
   - MIME Type Column `DS_MIME_TYPE` · Filename Column `DS_NOME_ARQUIVO`
   - Download Link Text `Baixar anexo`
   - File Types `.pdf,image/*` · Maximum File Size `5000` (em KB, cerca de 5 MB). No export: `fileTypes` e `maxFileSize` no bloco `storage`
   - Source: Form Region · Column `BL_ANEXO`
4. **Processo "Empresa da sessão"** · Processing · Sequence **antes** do processo de gravação do assistente (ex.: 5) · Execute Code:
   ```sql
   :P21_ID_EMPRESA := :G_ID_EMPRESA;
   ```
   Garante a empresa certa sem depender de valor vindo do navegador.
5. **Validações** (Processing › Validations). As constraints da tabela já barram dados errados, mas com mensagem técnica; estas mostram a mensagem no campo:

| Nome | Tipo | Código / valor | Mensagem | Item |
|---|---|---|---|---|
| Formação da empresa | PL/SQL Function Body Returning Boolean | (abaixo) | `Formação não encontrada.` | |
| Data obrigatória | Expression | `:P21_DT_INICIO is not null or :P21_DT_CONCLUSAO is not null` | `Informe a data de início ou de conclusão.` | `P21_DT_INICIO` |
| Conclusão depois do início | Expression | `:P21_DT_CONCLUSAO is null or :P21_DT_INICIO is null or to_date(:P21_DT_CONCLUSAO, 'DD/MM/YYYY') >= to_date(:P21_DT_INICIO, 'DD/MM/YYYY')` | `A conclusão não pode ser antes do início.` | `P21_DT_CONCLUSAO` |
| Validade | Expression | `:P21_DT_VALIDADE is null or to_date(:P21_DT_VALIDADE, 'DD/MM/YYYY') >= to_date(coalesce(:P21_DT_CONCLUSAO, :P21_DT_INICIO), 'DD/MM/YYYY')` | `A validade não pode ser antes da conclusão.` | `P21_DT_VALIDADE` |
| Carga horária | Expression | `:P21_NR_CARGA_HORARIA is null or to_number(:P21_NR_CARGA_HORARIA) > 0` | `A carga horária deve ser maior que zero.` | `P21_NR_CARGA_HORARIA` |
| Link | Expression | `:P21_DS_LINK is null or regexp_like(:P21_DS_LINK, '^https?://', 'i')` | `O link deve começar com http:// ou https://.` | `P21_DS_LINK` |

   "Formação da empresa" impede editar formação de outra empresa ou cadastrar para colaborador de outra empresa:
   ```sql
   declare
     l_qt pls_integer;
   begin
     if :P21_ID_FORMACAO is not null then
       select count(*) into l_qt
         from formacao_colaborador
        where id_formacao = :P21_ID_FORMACAO
          and id_empresa  = :G_ID_EMPRESA;
     else
       select count(*) into l_qt
         from colaborador
        where id_colaborador = :P21_ID_COLABORADOR
          and id_empresa     = :G_ID_EMPRESA;
     end if;
     return l_qt = 1;
   end;
   ```
   Na validação "Formação da empresa":
   - deixe **Server-side Condition › When Button Pressed** vazio, para valer para criar, salvar e excluir;
   - ligue **Always Execute: On**. O botão `DELETE` do assistente vem com *Execute Validations: Off*, que pula **todas** as validações. Sem o *Always Execute*, a exclusão não confere a empresa. No export, a validação passa a ter `alwaysExecute: true` dentro do bloco `validation`.
6. **Botões e processos do assistente:** mantenha `CANCEL`, `DELETE` (com confirmação), `SAVE` e `CREATE`, e os processos *Initialize form*, *Process form* (Automatic Row Processing) e *Close Dialog*. Traduza os labels: Cancelar, Excluir, Salvar, Criar. Em todos os botões, Authorization `ADMIN_RH`.

### 4.6 Testar

1. Na página 13, escolha um colaborador no seletor e clique em **Formações**. A página 19 abre com o cabeçalho igual ao da página 13, a lista vazia e o nome dele no subtítulo.
2. **Nova formação** › Certificação · título · instituição · conclusão = hoje · validade = daqui a 30 dias · anexe um PDF › **Criar**. A modal fecha e a linha aparece **em amarelo** ("A VENCER").
3. Abra a formação pelo lápis. O link **Baixar anexo** baixa o PDF.
4. Mude a validade para uma data passada › **Salvar**. A linha fica **vermelha** ("VENCIDA").
5. Coloque a conclusão antes do início › **Salvar**. A mensagem aparece no campo, sem `ORA-`.
6. **Excluir** › confirme. A linha some.
7. **Voltar ao histórico**: a página 13 volta no mesmo colaborador, e a aba *Desenvolvimento* mostra as formações cadastradas.
8. Abra a página 19 com um usuário que não é RH, ou mude o `P19_ID_COLABORADOR` na URL: deve dar acesso negado ou erro de checksum.

### 4.7 Se não funcionar

| Sintoma | Causa provável | Correção |
|---|---|---|
| A lista sempre vazia | `P19_ID_COLABORADOR` não existe ou não está em *Page Items to Submit* | Passos 4.3 e 4.4 |
| Subtítulo sem o nome do colaborador | O nome está no Source/Default de `P19_NM_COLABORADOR`, que só é calculado depois que a região já foi montada | Busque o nome no processo Validar acesso (§4.3, passo 4) |
| Cabeçalho sem fundo branco, sem negrito ou com moldura em volta | Faltou o CSS na página, ou o `div class="hc" data-hc` no HTML | §4.3 Passo 5, itens 1 e 2; suba o `.css`/`.min.css` e recarregue com Ctrl+F5 |
| `ORA-01403: no data found` ao abrir a 19 | `G_ID_EMPRESA` vazio na sessão, e aí o `select ... into` do Validar acesso não acha linha | Confira o processo que preenche `G_ID_EMPRESA` no login (§1.1) |
| Os campos da modal não aceitam digitação ao editar | Formulário sem o bloco `edit` | Recrie as páginas pelo assistente (§4.2) e confira o export |
| "Formação não encontrada." ao criar | `P21_ID_COLABORADOR` vazio | O botão "Nova formação" precisa passar `P21_ID_COLABORADOR` = `&P19_ID_COLABORADOR.` |
| `ORA-02290 ... FORMACAO_COLABORADOR_..._CK` | Validação faltando para essa regra | Crie a validação correspondente do passo 4.5 |
| Anexo não grava ou não baixa | Storage do File Upload errado | Storage: BLOB column specified in Item Source · MIME `DS_MIME_TYPE` · Filename `DS_NOME_ARQUIVO` |
| Destaque some depois | Relatório não foi salvo como Primary | Actions › Report › Save Report › Primary, logado no Builder |

---


## 5. Página 20 · Dashboard RH

Painel do RH com indicadores de carreira da empresa num período: promoções por departamento (§5.1), turnover (§5.2), tempo médio no cargo (§5.3), formações a vencer (§5.4) e solicitações de correção abertas (§5.5). A página **não está no protótipo** e, por isso, usa o mesmo cabeçalho das páginas 13 e 19.

Todas as consultas usam só movimentações válidas: efetivadas, não estornadas e que não são lançamentos de estorno (`VW_MOVIMENTACAO_VALIDA`). Toda consulta filtra por `:G_ID_EMPRESA`.

### 5.0 Criar a página e o filtro de período

**Antes de começar, confira:**

- [ ] A página 20 não existe (*App Builder › app 100*: não há página 20 na lista). Se existir uma versão antiga, apague-a como no §4.1.
- [ ] A view `VW_MOVIMENTACAO_VALIDA` existe (`03_views_carreira.sql`) e o package compila (tem `fn_hoje`).
- [ ] O esquema de autorização `ADMIN_RH` existe (§1.2).

#### Passo 1 · Criar a página em branco

1. **Create › Page › Blank Page** (confirmar no 26.1.5). Com uma página em branco, cada região é criada à mão, com o tipo certo. O assistente de *Chart* criaria uma página com um gráfico só.
2. Preencha:

| Campo | Valor |
|---|---|
| Page Number | `20` |
| Name | `Dashboard RH` |
| Page Mode | Normal |
| Navigation › Create Navigation Menu Entry | **Off**. A entrada de menu é criada no §7, com autorização |
| Breadcrumb | Don't use breadcrumbs |

3. **Create Page**. No Page Designer, clique no nó da página e preencha:

| Seção | Atributo | Valor |
|---|---|---|
| Appearance | Page Template | **Standard** (o mesmo da página 13) |
| CSS | File URLs | `#APP_FILES#historico-carreira#MIN#.css` |
| Security | Authorization Scheme | **ADMIN_RH** |
| Security | Page Access Protection | **Arguments Must Have Checksum** |

Por que a autorização vai na página: é a regra de ouro 3. Só esconder a entrada de menu não impede abrir a página pela URL.

#### Passo 2 · Cabeçalho

Igual ao da página 19 (§4.3, Passo 5). Botão direito em **Body** › **Create Region**:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `Cabeçalho` |
| Identification | Type | **Static Content** |
| Layout | Sequence | 5 |
| Appearance | Template | **Blank with Attributes (No Grid)** |
| Source | HTML Code | (abaixo) |

```html
<div class="hc" data-hc>
  <header class="hc-titulo">
    <div>
      <h1>Dashboard RH</h1>
      <p>Promoções, turnover, tempo no cargo e formações a vencer no período escolhido.</p>
    </div>
  </header>
</div>
```

O `data-hc` liga o layout de página inteira do `historico-carreira.css`: sem moldura e com o fundo cinza até o rodapé. As regiões com template *Standard* ganham margem de 24px em cima e embaixo e 32px nas laterais.

#### Passo 3 · Região e itens do período

Os filtros ficam numa linha só, acima dos gráficos, e valem para todos eles.

1. Botão direito em **Body** › **Create Region**:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `Período` |
| Identification | Type | **Static Content** |
| Layout | Sequence | 10 |
| Appearance | Template | **Standard** |
| Appearance | Template Options › Header | **Hidden but accessible** (no export: `t-Region--hideHeader js-addHiddenHeadingRoleDesc`) |

2. Botão direito na região **Período** › **Create Page Item**, duas vezes:

| Atributo | `P20_DT_INICIO` | `P20_DT_FIM` |
|---|---|---|
| Identification › Type | **Date Picker** | **Date Picker** |
| Label › Label | `De` | `Até` |
| Layout › Sequence | 10 | 20 |
| Layout › Start New Row | On | **Off** (fica ao lado do início) |
| Appearance › Format Mask | `DD/MM/YYYY` | `DD/MM/YYYY` |
| Settings › Minimum Date | (nenhuma) | **Item** › `P20_DT_INICIO` (no export: `minDate: item`, `minItem: P20_DT_INICIO`) |
| Appearance › Template | **Required - Floating** | **Required - Floating** |
| Validation › Value Required | On | On |
| Default › Type | **Expression** · Language PL/SQL | **Expression** · Language PL/SQL |
| Default › PL/SQL Expression | (abaixo) | (abaixo) |
| Source › Type | Null | Null |

Default de `P20_DT_INICIO`, o primeiro dia de 11 meses atrás, para mostrar os últimos 12 meses fechados mais o mês atual:
```sql
to_char(add_months(trunc(pkg_historico_carreira.fn_hoje(:G_ID_EMPRESA), 'mm'), -11), 'DD/MM/YYYY')
```
Default de `P20_DT_FIM`, hoje no fuso da empresa:
```sql
to_char(pkg_historico_carreira.fn_hoje(:G_ID_EMPRESA), 'DD/MM/YYYY')
```

Por que cada um importa:
- **Default com `to_char(..., 'DD/MM/YYYY')`:** o Date Picker guarda o valor como texto, no formato da Format Mask. Se o default vier em outro formato, o item mostra a data errada ou dá erro de conversão nas queries.
- **`fn_hoje`:** usa a data de hoje no fuso da empresa, não a do servidor de banco, que fica em UTC.
- **Minimum Date no fim:** o calendário não deixa escolher um fim antes do início.

#### Passo 4 · Dynamic Action "Período mudou"

Ao trocar uma das datas, os gráficos atualizam sem recarregar a página.

1. Na aba **Dynamic Actions**, botão direito em **Events › Change** › **Create Dynamic Action** (ou botão direito no item `P20_DT_INICIO` › Create Dynamic Action).
2. Preencha:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `Período mudou` |
| When | Event | **Change** |
| When | Selection Type | Item(s) |
| When | Item(s) | `P20_DT_INICIO,P20_DT_FIM` |
| Client-side Condition | Type | **JavaScript expression** |
| Client-side Condition | JavaScript Expression | `$v('P20_DT_INICIO') !== '' && $v('P20_DT_FIM') !== ''` |

3. Ação **True** › Action **Refresh** › Affected Elements › Region **Promoções por departamento**. Crie esta ação depois do §5.1, quando a região existir. No §5.2, acrescente uma ação Refresh para o gráfico de turnover. Os §5.3 a 5.5 não usam o período (calculam a partir de hoje) e não precisam de Refresh.

A expressão devolve `true` ou `false`, nunca um texto. Com a versão anterior, `$v(...) && $v(...)`, o resultado era a própria data (um texto), e em 13/10/2026 a DA não disparava no ambiente: o gráfico só mudava com `refresh()` manual. A condição é a principal suspeita (confirmar). A condição evita atualizar os gráficos enquanto uma das datas está vazia, por exemplo no meio da digitação. Quem envia as datas ao servidor é a própria região, pelo *Page Items to Submit* de cada série. A DA não precisa enviar nada.

### 5.1 Promoções por departamento (Chart · Bar)

Quantas promoções cada departamento teve no período. É uma comparação de quantidade entre categorias, então o formato é **barra horizontal, ordenada da maior para a menor**. Barras horizontais deixam o nome do departamento legível sem girar o texto, e a ordenação mostra o ranking sem o usuário precisar comparar alturas. Como há **uma série só**, o gráfico usa uma cor só, sem legenda: o título da região já diz o que é.

**Antes de começar, confira:**

- [ ] O §5.0 está feito: `P20_DT_INICIO` e `P20_DT_FIM` existem e têm default.
- [ ] Há dados para ver o gráfico. Rode em **SQL Workshop › SQL Commands**:
  ```sql
  select count(*)
    from vw_movimentacao_valida
   where cd_tipo = 'PROMOCAO';
  ```
  Se der 0, use a massa de demonstração (próximo item) ou efetive uma promoção pela página 13 (Nova movimentação › Promoção › Efetivar).

**Massa de demonstração (opcional).** O `09_dados_demo_dashboard.sql` cria dados marcados como `[DEMO]` que alimentam todos os gráficos da página 20:
1. Descubra a empresa do seu usuário RH: `select id_empresa, nome from empresa order by id_empresa;`
2. Abra o `09_dados_demo_dashboard.sql` e troque `c_empresa constant number := 1;` pela sua empresa.
3. **SQL Workshop › SQL Scripts › Upload** (ou *Create* e cole o conteúdo) › **Run**. SQL Commands não serve, porque roda um comando por vez.
4. A saída deve terminar com algo como `colaboradores: 16 | admissões: 16 | promoções: 10 | desligamentos: 4`. A consulta de conferência no fim do script lista as promoções por departamento: 4, 3, 2 e 1.

O que cada gráfico mostra com essa massa, no período padrão (últimos 12 meses). Se a empresa já tiver dados reais, eles se somam a estes:

| Gráfico | Resultado esperado |
|---|---|
| 5.1 Promoções por departamento | 4 barras: 4, 3, 2 e 1 promoções, nos 4 primeiros departamentos da empresa. **Todas as promoções caem nos últimos 4 meses**, então qualquer período que comece antes disso mostra o mesmo gráfico. Use a tabela "Intervalos para testar o filtro" no Testar do §5.1 |
| 5.2 Turnover | 7 admissões entre 7 e 11 meses atrás; 4 desligamentos nos últimos 4 meses |
| 5.3 Tempo médio no cargo | Uma barra por departamento, com médias diferentes |
| 5.4 Formações a vencer | 5 linhas: 4 certificações e 1 curso (NR-10), vencendo entre 10 e 45 dias |
| 5.5 Solicitações abertas | 2 linhas |

Os dados aparecem também nas outras telas: lista de colaboradores, seletor da página 13, organograma. Os nomes começam com `[DEMO]`, para ninguém confundir com gente real. Não há data de nascimento, então eles não entram nos aniversariantes da Home. Também não geram comunicados.

Para apagar tudo, rode o `10_remover_dados_demo.sql` da mesma forma, com a mesma `c_empresa`. Ele desliga a trigger que protege a trilha só durante a exclusão e a religa no fim. A última consulta do script confirma `ENABLED`.

> **Por que o script grava direto nas tabelas, e não pelo package:** no SQL Workshop, o código roda dentro da sessão do App Builder, que não tem `G_ID_EMPRESA`. Pelo código do package (`em_sessao_apex` e `fn_empresa_contexto`), ele trataria isso como sessão sem empresa e recusaria com `-20012` ("Sua sessão não está vinculada a uma empresa"). Isso não foi testado no ambiente. O script monta cada lançamento como o package grava (efetivado, com a situação anterior e a nova completas) e não publica comunicado na intranet.

#### Passo 1 · Criar a região do gráfico

1. Botão direito em **Body** › **Create Region**.
2. Preencha:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `Promoções por departamento` |
| Identification | Type | **Chart** |
| Layout | Sequence | 20 |
| Appearance | Template | **Standard** |
| Advanced | Static ID | `grafico_promocoes` |

Ao trocar o Type para *Chart*, o APEX cria embaixo da região um nó **Series** com uma série de exemplo e um nó **Axes** com os eixos `x` e `y`.

#### Passo 2 · Atributos do gráfico

Os atributos do gráfico (tipo, orientação, legenda, tooltip, mensagens) ficam no componente do gráfico, não no da região. Em versões anteriores isso era o nó/aba **Attributes** da região. No 26.1.5, procure pelo nome do atributo na busca do painel (ex.: `Orientation`) (confirmar no 26.1.5).

| Seção | Atributo | Valor | Por quê |
|---|---|---|---|
| Chart | Type | **Bar** | Comparar quantidades entre categorias |
| Chart | Orientation | **Horizontal** | Nome do departamento legível, sem girar |
| Chart | Stack | Off | Série única |
| Appearance | Height | `360` | Altura fixa; com muitos departamentos, aumente |
| Animation | On Display | **None** | Respeita quem desativa animações; o valor aparece na hora |
| Legend | Show | **Off** | Série única: o título da região já identifica |
| Tooltip | Show | On | |
| Tooltip | Show Series Name | **Off** | "Promoções" já está no título |
| Tooltip | Show Group Name | On | Mostra o departamento |
| Tooltip | Show Value | On | |
| Messages | When No Data Found | `Nenhuma promoção no período.` | Mensagem em pt-BR em vez do padrão em inglês |

#### Passo 3 · Série "Promoções"

1. Abra **Series** e clique na série que o APEX criou.
2. Preencha:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `Promoções` |
| Source | Location | Local Database |
| Source | Type | **SQL Query** |
| Source | SQL Query | (abaixo) |
| Source | Page Items to Submit | `P20_DT_INICIO,P20_DT_FIM` |
| Column Mapping | Label | `DEPARTAMENTO` |
| Column Mapping | Value | `PROMOCOES` |
| Appearance | Color | `#00688C` |
| Label | Show | **On** |
| Label | Position | **Outside Bar Edge** |

```sql
select coalesce(d.nome, '(sem departamento)') as departamento,
       count(*)                               as promocoes
  from vw_movimentacao_valida v
  left join departamento d
         on d.id_departamento = v.id_departamento_novo
 where v.id_empresa = :G_ID_EMPRESA
   and v.cd_tipo    = 'PROMOCAO'
   and v.dt_efetiva between to_date(:P20_DT_INICIO, 'DD/MM/YYYY')
                        and to_date(:P20_DT_FIM,    'DD/MM/YYYY')
 group by d.id_departamento, d.nome
 order by promocoes desc, departamento
```

Por que cada parte importa:
- **`v.id_empresa = :G_ID_EMPRESA`:** é o isolamento entre empresas (regra de ouro 3).
- **`id_departamento_novo`:** o package grava no lançamento efetivado a situação completa, mesmo quando o departamento não muda. Por isso a promoção conta para o departamento em que a pessoa estava quando foi promovida.
- **`group by d.id_departamento, d.nome`:** dois departamentos com o mesmo nome continuam separados.
- **`order by promocoes desc, departamento`:** o gráfico segue a ordem da query. O desempate pelo nome deixa a ordem estável entre atualizações.
- **`to_date(..., 'DD/MM/YYYY')`:** o mesmo formato da Format Mask dos itens. Sem a máscara explícita, a conversão depende do idioma da sessão.
- **Page Items to Submit na série:** no Refresh, o APEX envia as datas da tela antes de rodar a query. Sem isso, a query usa as datas antigas da sessão.
- **Uma cor só, `#00688C`:** é a primária do tema (`--cx-primaria`). O contraste com o fundo branco do cartão é de pelo menos 3:1, que é o mínimo para elementos gráficos. Use o código, não `var(--cx-primaria)`: o gráfico é desenhado em SVG, e a cor vai como atributo, onde variáveis CSS não funcionam em todos os navegadores.
- **Rótulo com o valor na ponta da barra:** com poucas barras, o número na ponta dispensa ler o eixo e funciona para quem não distingue cores.

#### Passo 4 · Eixos

Abra **Axes**. Na barra horizontal, `x` é o eixo das categorias (departamentos) e `y` é o dos valores.

| Eixo | Seção | Atributo | Valor |
|---|---|---|---|
| `x` | Title | Title | (vazio: os nomes dos departamentos já dizem o que é) |
| `y` | Title | Title | `Promoções` |
| `y` | Value | Format | **Decimal** · Decimal Places `0` |
| `y` | Value | Minimum | `0` |
| `y` | Value | Format Scaling | **None** (mostra "12", não "12K") |
| `y` | Major Ticks | Minimum Step | `1` (só números inteiros) |
| `y` | Minor Ticks | Rendered | Off |

Por que: promoção é contagem. Sem casas decimais e com passo 1, o eixo não mostra valores como "0,5 promoção". Começar em zero mantém o comprimento da barra proporcional ao valor.

#### Passo 5 · Ligar o gráfico à DA do período

Volte à DA **Período mudou** (§5.0, Passo 4) e crie a ação True **Refresh** › Region **Promoções por departamento**. Salve a página (Ctrl+S).

A árvore deve ficar assim:

```
Body
├── Cabeçalho                    (Static Content · No Grid · seq 5)
├── Período                      (Static Content · Standard · seq 10)
│   ├── P20_DT_INICIO            (Date Picker · seq 10)
│   └── P20_DT_FIM               (Date Picker · seq 20)
└── Promoções por departamento   (Chart · Bar horizontal · seq 20)
    ├── Series
    │   └── Promoções            (SQL Query · #00688C)
    └── Axes
        ├── x
        └── y                    (Promoções · 0 casas · passo 1)
Dynamic Actions
└── Change
    └── Período mudou            (P20_DT_INICIO, P20_DT_FIM)
        └── True › Refresh       Promoções por departamento
```

#### Como conferir no export da página 20

- `security { authorizationScheme: @admin-rh ... }` e `css { fileUrls: #APP_FILES#historico-carreira#MIN#.css }` na página;
- os dois Date Picker com `formatMask: DD/MM/YYYY`, `default { type: expression ... }`, `valueRequired: true`, labels **De** e **Até**, e `P20_DT_FIM` com `minDate: item` / `minItem: P20_DT_INICIO`;
- `dynamicAction período-mudou` com `items: [P20_DT_INICIO P20_DT_FIM]`, a `clientSideCondition` em JavaScript e uma ação `refresh` para `@grafico_promocoes`. O evento *Change* é o padrão e não aparece no export;
- a região do gráfico. O tipo *Bar* é o padrão e também não aparece. Trecho real do export (12/10/2026):

```
region grafico_promocoes (
    name: Promoções por departamento
    type: chart
    chartAppearance { orientation: horizontal }
    chartLayout     { height: 360 }
    animation       { onDisplay: none }
    tooltip         { showSeriesName: false }
    legend          { show: false }
    messages        { whenNoDataFound: Nenhuma promoção no período. }

    series promoções (
        source {
            type: sqlQuery
            sqlQuery: ...
            pageItemsToSubmit: [ P20_DT_INICIO P20_DT_FIM ]
        }
        columnMapping { label: DEPARTAMENTO  value: PROMOCOES }
        appearance    { color: #00688c }
        label         { show: true  position: outsideBarEdge }
    )

    axis x ( name: x )
    axis y (
        name: y
        title: Promoções
        value      { min: 0  format: decimal  decimalPlaces: 0  formatScaling: none }
        majorTicks { minStep: 1 }
        minorTicks { show: false }
    )
)
```
(Blocos condensados em uma linha para caber aqui; no export, cada atributo fica numa linha.)

#### Testar

1. Rode a página 20 com um usuário RH. O cabeçalho "Dashboard RH" aparece igual ao das páginas 13 e 19, e o período vem preenchido com os últimos 12 meses.
2. As barras aparecem em ordem decrescente, com o número na ponta. Passe o mouse numa barra: o tooltip mostra o departamento e a quantidade, sem o nome da série.
3. **Filtro de período.** Com a massa de demonstração, as promoções ficam assim (M-1 = mês passado, M-4 = quatro meses atrás):

   | Departamento | Datas das promoções |
   |---|---|
   | 1º | dia 7 de M-1, M-2, M-3 e M-4 |
   | 2º | dia 11 de M-2, M-3 e M-4 |
   | 3º | dia 15 de M-3 e M-4 |
   | 4º | dia 19 de M-4 |

   **Intervalos para testar o filtro** (com **Até** = hoje, mudando só o **De**):

   | De | Barras esperadas (1º, 2º, 3º, 4º departamento) |
   |---|---|
   | dia 1 do mês atual | nenhuma: "Nenhuma promoção no período." |
   | dia 1 de M-1 | 1 (só o 1º departamento) |
   | dia 1 de M-2 | 2 e 1 |
   | dia 1 de M-3 | 3, 2 e 1 |
   | dia 1 de M-4 ou antes | 4, 3, 2 e 1 (o gráfico completo) |

   Teste também o **Até**: com De = dia 1 de M-4 e Até = último dia de M-4, aparecem 4 barras com **1 promoção cada**.

   O gráfico deve mudar **sem recarregar a página**, assim que você sai do campo de data. Para ver as datas reais, inclusive as que não são de demonstração:
   ```sql
   select d.nome as departamento, v.dt_efetiva
     from vw_movimentacao_valida v
     left join departamento d on d.id_departamento = v.id_departamento_novo
    where v.id_empresa = 1   -- a sua empresa
      and v.cd_tipo    = 'PROMOCAO'
    order by v.dt_efetiva desc;
   ```
4. Abra o calendário de **Até**: os dias antes da data **De** ficam bloqueados.
5. Entre com um usuário que não é RH e abra a página 20: o acesso é negado.
6. Confira o número com SQL:
   ```sql
   select count(*)
     from vw_movimentacao_valida
    where id_empresa = 1   -- a sua empresa
      and cd_tipo    = 'PROMOCAO'
      and dt_efetiva between date '2025-11-01' and date '2026-10-12';
   ```
   O total deve ser igual à soma das barras.

#### Se não funcionar

| Sintoma | Causa provável | Correção |
|---|---|---|
| "Nenhuma promoção no período." mesmo com promoções | Promoções fora do período, ainda em rascunho ou estornadas | Amplie o período. Só entram promoções efetivadas e não estornadas (`VW_MOVIMENTACAO_VALIDA`) |
| Ao mudar a data, o gráfico continua igual | As datas escolhidas ainda incluem todas as promoções (com a massa demo, todas estão nos últimos 4 meses) | Use os intervalos do Testar, item 3. Se "dia 1 do mês atual" mostrar "Nenhuma promoção no período.", o filtro funciona |
| O gráfico só muda depois de rodar `apex.region('<id>').refresh()` no console | A DA "Período mudou" não dispara. Suspeita principal: condição client-side que devolvia texto em vez de `true`/`false` | §5.0, Passo 4: condição `$v('P20_DT_INICIO') !== '' && $v('P20_DT_FIM') !== ''`. Para ver se a DA dispara, rode `apex.debug.setLevel(4)` no console, mude uma data e procure "Período mudou" no log |
| Nem "dia 1 do mês atual" muda o gráfico | A DA não dispara, ou a série não envia as datas | No console do navegador (F12), rode `apex.region("grafico_promocoes").refresh()`. Se o gráfico mudar, o problema é a DA (Passo 5 e §5.0 Passo 4). Se não mudar, falta *Page Items to Submit* na **série** (Passo 3) |
| `ORA-01843: not a valid month` ou `ORA-01858` | Default do item ou Format Mask fora de `DD/MM/YYYY` | §5.0, Passo 3: o mesmo formato no default, na máscara e no `to_date` |
| Barra "(sem departamento)" | O colaborador não tinha departamento no cadastro quando a promoção foi efetivada. Nesse caso o package grava `id_departamento_novo` nulo | Corrija o departamento no cadastro do colaborador. Para lançamentos já efetivados, use uma movimentação de Transferência de área |
| Eixo com "0,5" ou "1,5" | Faltou formato inteiro no eixo `y` | Passo 4: Decimal Places 0 e Step 1 |
| Barras verticais com nomes girados | Orientation ficou Vertical | Passo 2: **Horizontal** |
| Página com moldura branca em volta | Faltou o CSS na página ou o `data-hc` no cabeçalho | §5.0, Passos 1 e 2 |

### 5.2 Turnover: admissões x desligamentos por mês (Chart · Bar, 2 séries)

Quantas pessoas entraram e saíram em cada mês do período. É uma comparação de duas quantidades ao longo do tempo, então o formato é **barra vertical agrupada**: os meses ficam no eixo horizontal, da esquerda para a direita, e cada mês tem uma barra de admissões ao lado de uma de desligamentos. Como há **duas séries**, o gráfico tem legenda e uma cor para cada série.

O gráfico mostra contagens, não uma taxa de turnover (que dividiria os desligamentos pelo número médio de pessoas).

**Antes de começar, confira:**

- [ ] O §5.1 está feito e a DA **Período mudou** já atualiza o gráfico de promoções.
- [ ] Há admissões ou desligamentos para ver o gráfico. Rode em **SQL Workshop › SQL Commands**:
  ```sql
  select cd_tipo, count(*)
    from vw_movimentacao_valida
   where cd_tipo in ('ADMISSAO', 'DESLIGAMENTO')
   group by cd_tipo;
  ```
  A carga inicial (`06_carga_inicial.sql`) cria uma admissão para cada colaborador, com a data de `DATA_ADMISSAO`, então as admissões já começam preenchidas. Desligamentos só existem a partir do uso do módulo: os inativos de antes da instalação recebem só a admissão. Para ver as duas séries, use a massa de demonstração do §5.1.

#### Passo 1 · Criar a região do gráfico

1. Botão direito em **Body** › **Create Region**.
2. Preencha:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `Turnover: admissões x desligamentos por mês` |
| Identification | Type | **Chart** |
| Layout | Sequence | 25 (fica entre promoções, 20, e tempo no cargo, 30) |
| Appearance | Template | **Standard** |
| Advanced | Static ID | `grafico_turnover` |

Ao trocar o Type para *Chart*, o APEX cria uma série de exemplo chamada `New` e os eixos `x` e `y`. Renomeie a série no Passo 3. Se o nome da região começar com "New", corrija também.

#### Passo 2 · Atributos do gráfico

Como no §5.1, os atributos ficam no componente do gráfico. Procure pelo nome na busca do painel (confirmar no 26.1.5).

| Seção | Atributo | Valor | Por quê |
|---|---|---|---|
| Chart | Type | **Bar** | Comparar quantidades |
| Chart | Orientation | **Vertical** (padrão) | O tempo corre da esquerda para a direita |
| Chart | Stack | **Off** | Admissões e desligamentos lado a lado. Empilhados, a altura da barra seria a soma, que não significa nada |
| Appearance | Height | `360` | A mesma altura do gráfico de promoções |
| Animation | On Display | **None** | Igual ao §5.1 |
| Legend | Show | **On** (padrão) | Duas séries: a legenda diz qual cor é qual |
| Tooltip | Show | On | |
| Tooltip | Show Series Name | **On** (padrão) | O tooltip diz se o número é de admissões ou de desligamentos |
| Tooltip | Show Group Name | On | Mostra o mês |
| Tooltip | Show Value | On | |

A mensagem *When No Data Found* pode ficar como está: a query sempre devolve uma linha por mês do período, com zero nos meses sem movimentação, então essa mensagem nunca aparece.

#### Passo 3 · Séries "Admissões" e "Desligamentos"

As duas séries usam a mesma query e mudam só a coluna de valor.

1. Abra **Series** e clique na série que o APEX criou. Preencha a coluna **Admissões** da tabela abaixo.
2. Botão direito em **Series** › **Create Series** e preencha a coluna **Desligamentos**.

| Seção | Atributo | Série 1 | Série 2 |
|---|---|---|---|
| Identification | Name | `Admissões` | `Desligamentos` |
| Execution | Sequence | 10 | 20 |
| Source | Location | Local Database | Local Database |
| Source | Type | **SQL Query** | **SQL Query** |
| Source | SQL Query | (abaixo) | (a mesma) |
| Source | Page Items to Submit | `P20_DT_INICIO,P20_DT_FIM` | `P20_DT_INICIO,P20_DT_FIM` |
| Column Mapping | Label | `MES` | `MES` |
| Column Mapping | Value | `ADMISSOES` | `DESLIGAMENTOS` |
| Appearance | Color | `#00688C` | `#B3261E` |
| Label | Show | Off | Off |

```sql
with periodo as (
  select to_date(:P20_DT_INICIO, 'DD/MM/YYYY') as dt_inicio,
         to_date(:P20_DT_FIM,    'DD/MM/YYYY') as dt_fim
    from dual
),
meses as (
  select add_months(trunc(p.dt_inicio, 'mm'), level - 1) as mes
    from periodo p
 connect by level <= months_between(trunc(p.dt_fim, 'mm'), trunc(p.dt_inicio, 'mm')) + 1
)
select to_char(m.mes, 'yyyy/mm')                              as mes,
       count(case when v.cd_tipo = 'ADMISSAO'     then 1 end) as admissoes,
       count(case when v.cd_tipo = 'DESLIGAMENTO' then 1 end) as desligamentos
  from meses m
 cross join periodo p
  left join vw_movimentacao_valida v
         on v.id_empresa  = :G_ID_EMPRESA
        and v.cd_tipo    in ('ADMISSAO', 'DESLIGAMENTO')
        and v.dt_efetiva >= m.mes
        and v.dt_efetiva <  add_months(m.mes, 1)
        and v.dt_efetiva between p.dt_inicio and p.dt_fim
 group by m.mes
 order by m.mes
```

Por que cada parte importa:
- **`meses`:** gera uma linha para cada mês, do mês de **De** até o mês de **Até**. Assim, um mês sem nenhuma movimentação aparece com zero, em vez de sumir do eixo e dar a impressão de que os meses vizinhos são seguidos.
- **`between p.dt_inicio and p.dt_fim`:** só conta o que caiu dentro das datas escolhidas, como no §5.1. Sem essa linha, o primeiro e o último mês entrariam inteiros: com **De** = 15/03, as admissões de 01 a 14/03 seriam contadas. Com ela, o primeiro e o último mês podem ser **parciais**, e a barra deles só tem os dias do período.
- **`dt_efetiva >= m.mes and dt_efetiva < add_months(m.mes, 1)`:** põe cada lançamento no seu mês. Comparar a coluna direto, sem `trunc(v.dt_efetiva, 'mm')`, deixa o banco usar o índice `historico_carreira_emp_dt_ix` (`id_empresa, dt_efetiva`).
- **`left join` com os filtros no `on`:** se os filtros de `v` ficassem no `where`, os meses sem movimentação sumiriam, como num `join` comum.
- **`count(case ... then 1 end)`:** conta só os lançamentos do tipo da coluna. Num mês sem nada, as duas contagens dão 0.
- **`v.id_empresa = :G_ID_EMPRESA`:** isolamento entre empresas (regra de ouro 3).
- **`to_char(m.mes, 'yyyy/mm')`:** o rótulo é texto, e num gráfico com mais de uma série o APEX junta os rótulos das séries e os ordena **como texto**, ignorando o `order by m.mes`. Com `mm/yyyy`, `01/2026` apareceria antes de `11/2025` (visto no teste de 18/10/2026). Com `yyyy/mm`, a ordem do texto é a ordem do calendário.
- **Page Items to Submit nas duas séries:** cada série roda a sua própria query no Refresh. Se uma delas não enviar as datas, ela usa as datas antigas da sessão e as duas séries ficam fora de sincronia.
- **Cores `#00688C` (primária, `--cx-primaria`) e `#B3261E` (`--cx-alerta`):** azul e vermelho continuam distintos para quem tem daltonismo vermelho-verde, o que não acontece com verde (`--cx-sucesso`) e vermelho. As duas têm contraste de pelo menos 3:1 com o fundo branco. Como no §5.1, use o código, não a variável CSS. A legenda e o nome da série no tooltip dispensam depender só da cor.
- **Sem rótulo na barra:** com 12 meses e 2 barras por mês, são 24 números. O tooltip mostra o valor exato.

#### Passo 4 · Eixos

Na barra vertical, `x` é o eixo das categorias (meses) e `y` é o dos valores.

| Eixo | Seção | Atributo | Valor |
|---|---|---|---|
| `x` | Title | Title | (vazio: os rótulos `yyyy/mm` já dizem o que é) |
| `y` | Title | Title | `Pessoas` |
| `y` | Value | Format | **Decimal** · Decimal Places `0` |
| `y` | Value | Minimum | `0` |
| `y` | Value | Format Scaling | **None** |
| `y` | Major Ticks | Minimum Step | `1` |
| `y` | Minor Ticks | Rendered | Off |

Por que: como no §5.1, é contagem de pessoas. Sem casas decimais e com passo 1, o eixo não mostra "0,5 pessoa".

#### Passo 5 · Ligar o gráfico à DA do período

Na DA **Período mudou**, crie uma segunda ação True: **Refresh** › Affected Elements › Region **Turnover: admissões x desligamentos por mês**, Sequence 20. Salve a página (Ctrl+S).

A árvore deve ficar assim (o tempo no cargo, do §5.3, aparece se já tiver sido criado):

```
Body
├── Cabeçalho                    (Static Content · No Grid · seq 5)
├── Período                      (Static Content · Standard · seq 10)
│   ├── P20_DT_INICIO            (Date Picker · seq 10)
│   └── P20_DT_FIM               (Date Picker · seq 20)
├── Promoções por departamento   (Chart · Bar horizontal · seq 20)
├── Turnover: admissões x desligamentos por mês   (Chart · Bar vertical · seq 25)
│   ├── Series
│   │   ├── Admissões            (SQL Query · #00688C · seq 10)
│   │   └── Desligamentos        (SQL Query · #B3261E · seq 20)
│   └── Axes
│       ├── x
│       └── y                    (Pessoas · 0 casas · passo 1)
└── Tempo médio no cargo por departamento   (Chart · seq 30 · §5.3)
Dynamic Actions
└── Change
    └── Período mudou            (P20_DT_INICIO, P20_DT_FIM)
        ├── True › Refresh       Promoções por departamento   (seq 10)
        └── True › Refresh       Turnover: admissões x ...    (seq 20)
```

#### Como conferir no export da página 20

O que se espera no export, montado a partir das chaves que o §5.1 já mostrou (ainda não conferido com um export real deste gráfico):

```
region grafico_turnover (
    name: Turnover: admissões x desligamentos por mês
    type: chart
    layout     { sequence: 25  slot: body }
    chartLayout { height: 360 }
    animation  { onDisplay: none }

    series admissões (
        name: Admissões
        execution { sequence: 10 }
        source {
            type: sqlQuery
            sqlQuery: ...
            pageItemsToSubmit: [ P20_DT_INICIO P20_DT_FIM ]
        }
        columnMapping { label: MES  value: ADMISSOES }
        appearance    { color: #00688c }
    )

    series desligamentos (
        name: Desligamentos
        execution { sequence: 20 }
        source { ... a mesma query e os mesmos pageItemsToSubmit ... }
        columnMapping { label: MES  value: DESLIGAMENTOS }
        appearance    { color: #b3261e }
    )

    axis x ( name: x )
    axis y (
        name: y
        title: Pessoas
        value      { min: 0  format: decimal  decimalPlaces: 0  formatScaling: none }
        majorTicks { minStep: 1 }
        minorTicks { show: false }
    )
)
```

Confira também:
- **não** há `chartAppearance { orientation: horizontal }`, `legend { show: false }` nem `tooltip { showSeriesName: false }` nesta região. São os valores do §5.1 que não servem aqui;
- nenhuma série com `name: New`. O identificador depois de `series` pode continuar `new`: no export de 13/10/2026, a série renomeada para *Admissões* manteve `series new (`. O que vale é o `name:`;
- as **duas** séries com `pageItemsToSubmit: [ P20_DT_INICIO P20_DT_FIM ]`;
- na `dynamicAction período-mudou`, uma segunda ação `refresh` com `region: @grafico_turnover`.

#### Testar

1. Rode a página 20 com um usuário RH. O gráfico aparece abaixo do de promoções, com uma barra por mês do período, legenda "Admissões" e "Desligamentos", e os meses em ordem, do mais antigo ao mais recente.
2. Passe o mouse numa barra: o tooltip mostra o mês, o nome da série e a quantidade.
3. **Valores com a massa de demonstração** no período padrão (M-11 = 11 meses atrás, M0 = mês atual). Admissões nos dias 17 e 22 do mês; desligamentos no dia 20:

   | Mês | Admissões | Desligamentos |
   |---|---|---|
   | M-11 | 1 | 0 |
   | M-10 | 2 | 0 |
   | M-9 | 2 (dias 17 e 22) | 0 |
   | M-8 | 1 | 0 |
   | M-7 | 1 | 0 |
   | M-6, M-5 | 0 | 0 |
   | M-4, M-3, M-2, M-1 | 0 | 1 cada (dia 20) |
   | M0 | 0 | 0 |

   O total é 7 admissões e 4 desligamentos. Se a empresa tiver dados reais, eles se somam a estes.

4. **Filtro de período.** O gráfico deve mudar sem recarregar a página, assim que você sai do campo de data:

   | De | Até | Esperado |
   |---|---|---|
   | dia 1 de M-4 | hoje | 5 meses (M-4 a M0): nenhuma admissão e 1 desligamento em cada mês de M-4 a M-1 |
   | dia 21 de M-4 | hoje | M-4 com **0** desligamentos: o desligamento do dia 20 ficou fora. Prova que o mês parcial conta só os dias do período |
   | dia 18 de M-9 | hoje | M-9 com **1** admissão (só a do dia 22) |
   | dia 1 de M-1 | dia 19 de M-1 | 1 mês só, com 0 e 0: o desligamento do dia 20 ficou fora |

5. Confira o total com SQL:
   ```sql
   select cd_tipo, count(*)
     from vw_movimentacao_valida
    where id_empresa  = 1   -- a sua empresa
      and cd_tipo    in ('ADMISSAO', 'DESLIGAMENTO')
      and dt_efetiva between date '2025-11-01' and date '2026-10-13'   -- o período da tela
    group by cd_tipo;
   ```
   Cada total deve ser igual à soma das barras da série.

#### Se não funcionar

| Sintoma | Causa provável | Correção |
|---|---|---|
| Ao mudar a data, promoções muda e turnover não | Falta a ação Refresh do turnover na DA | Passo 5 |
| Só uma das séries muda ao trocar a data | Falta *Page Items to Submit* numa das séries | Passo 3: as duas séries enviam `P20_DT_INICIO,P20_DT_FIM` |
| Barras empilhadas | Stack ficou On | Passo 2: **Off** |
| Barras deitadas, meses no eixo vertical | Orientation ficou Horizontal (copiado do §5.1) | Passo 2: **Vertical** |
| Sem legenda ou tooltip sem o nome da série | `legend { show: false }` ou `showSeriesName: false` copiados do §5.1 | Passo 2 |
| As duas séries com a mesma cor | Faltou a cor numa das séries | Passo 3 |
| Uma série chamada "New" na legenda | A série de exemplo não foi renomeada, ou sobrou uma terceira série | Passo 3: renomeie ou apague a série a mais |
| Meses fora de ordem (`01/2026` antes de `11/2025`) | Rótulo em `mm/yyyy`. Com mais de uma série, o APEX ordena os rótulos como texto e ignora o `order by` | Passo 3: `to_char(m.mes, 'yyyy/mm')` nas duas séries |
| Meses sem movimentação somem do eixo | Filtros de `v` no `where` em vez do `on` do `left join` | Use a query do Passo 3 |
| O primeiro mês conta movimentações de antes do **De** | Falta `and v.dt_efetiva between p.dt_inicio and p.dt_fim` | Use a query do Passo 3 |
| Desligamentos sempre 0, sem a massa demo | Os inativos de antes da instalação têm só a admissão na carga inicial | Esperado. Desligamentos aparecem conforme o RH lança pelo módulo |
| `ORA-01843: not a valid month` ou `ORA-01858` | Formato da data diferente de `DD/MM/YYYY` | §5.0, Passo 3 |

### 5.3 Tempo médio no cargo por departamento (Chart · Bar horizontal)

```sql
select nvl(s.nm_departamento, '(sem departamento)') as departamento,
       round(avg(months_between(pkg_historico_carreira.fn_hoje(:G_ID_EMPRESA),
                                s.dt_inicio_funcao)) / 12, 1) as anos_no_cargo
  from vw_situacao_atual_colaborador s
 where s.id_empresa       = :G_ID_EMPRESA
   and s.fl_vinculo_ativo = 'S'
 group by s.id_departamento, s.nm_departamento
 order by anos_no_cargo desc, departamento
```
Value Axis title: "anos"

Agrupe por `s.id_departamento, s.nm_departamento`, como no §5.1. Agrupar só pelo nome juntaria numa barra só dois departamentos com o mesmo nome, e a média deles se misturaria. O desempate pelo nome no `order by` deixa a ordem estável quando duas médias empatam.

### 5.4 Formações a vencer (Classic Report)

Lista as formações que vencem de hoje até daqui a 60 dias, da mais próxima para a mais distante. Assim como na página 19, entra qualquer formação com validade, não só certificação. A janela começa sempre hoje: a região **não** depende de De/Até e não entra na DA "Período mudou".

#### Passo 1 · Região

Crie uma região **Classic Report** no Body, Sequence `45` (depois dos gráficos), Title `Formações a vencer`, Source **SQL Query**:

```sql
select f.id_colaborador       as id_colaborador,
       c.nome_completo        as colaborador,
       f.ds_titulo            as formacao,
       f.tp_formacao          as tipo,
       f.ds_instituicao       as emissor,
       f.dt_validade          as validade,
       f.dt_validade - pkg_historico_carreira.fn_hoje(:G_ID_EMPRESA) as dias_restantes
  from formacao_colaborador f
  join colaborador c on c.id_colaborador = f.id_colaborador
 where f.id_empresa  = :G_ID_EMPRESA
   and f.dt_validade between pkg_historico_carreira.fn_hoje(:G_ID_EMPRESA)
                         and pkg_historico_carreira.fn_hoje(:G_ID_EMPRESA) + 60
 order by f.dt_validade
```

Por que cada parte importa:
- **`f.id_colaborador`:** é o valor que o link do Passo 2 manda para a página 19. Sem essa coluna, o link não tem como dizer qual colaborador abrir.
- **`fn_hoje`:** devolve a data de hoje no fuso da empresa, já sem hora (`trunc`). Por isso `dias_restantes` sai inteiro e o `between` inclui hoje e o 60º dia.
- **`f.id_empresa = :G_ID_EMPRESA`:** isolamento entre empresas (regra de ouro 3).

Em **No Data Found**, na própria região (confirmar no 26.1.5): `Nenhuma formação vence nos próximos 60 dias.`

#### Passo 2 · Colunas

| Coluna | Type | Heading | Outros atributos |
|---|---|---|---|
| `ID_COLABORADOR` | **Hidden Column** | (vazio) | Só existe para o link |
| `COLABORADOR` | **Link** | `Colaborador` | Target: Page `19` · Set Items `P19_ID_COLABORADOR` = `#ID_COLABORADOR#` · Link Text `#COLABORADOR#` |
| `FORMACAO` | Plain Text | `Formação` | |
| `TIPO` | **Plain Text (based on List of Values)** | `Tipo` | LOV `LOV_TIPO_FORMACAO` (mostra "Certificação" em vez de `CERTIFICACAO`) |
| `EMISSOR` | Plain Text | `Emissor` | |
| `VALIDADE` | Plain Text | `Validade` | Format Mask `DD/MM/YYYY` |
| `DIAS_RESTANTES` | Plain Text | `Dias restantes` | Alinhamento do cabeçalho e da coluna: End (direita) |

- **Set Items do link é obrigatório.** O processo "Validar acesso" da página 19 (§4.3) barra a entrada quando `P19_ID_COLABORADOR` chega vazio. Monte o link pelo editor de link do Builder, não com um `f?p=` à mão: a página 19 exige checksum.
- **Format Mask da validade:** o idioma técnico da app é `en`, então sem máscara a data pode sair no formato americano.
- Os cabeçalhos gerados pelo Builder vêm sem acento e em Title Case (`Formacao`, `Dias Restantes`). Corrija-os como na tabela.

#### Como conferir no export da página 20

```
region formações-a-vencer (
    name: Formações a vencer
    type: classicReport
    layout { sequence: 45  slot: body }

    column COLABORADOR (
        type: link
        link {
            target: {
                page: 19
                items: { P19_ID_COLABORADOR: #ID_COLABORADOR# }
            }
            linkText: #COLABORADOR#
        }
    )
    column ID_COLABORADOR ( type: hidden )
    column TIPO     ( type: plainTextBasedOnLov  lov { lov: @lov-tipo-formacao } )
    column VALIDADE ( appearance { formatMask: DD/MM/YYYY } )
    ...
)
```

Confira também que a região **não** aparece em nenhuma ação da `dynamicAction período-mudou`.

#### Testar

1. Rode a página 20 com um usuário RH. A lista começa pela validade mais próxima, com datas como `05/11/2026`.
2. Clique num nome. A página 19 abre com as formações **daquele** colaborador, com o nome dele no cabeçalho.
3. Mude o período De/Até. Esta lista não muda.
4. Se a lista vier vazia, confira se existe alguma formação vencendo na janela:
   ```sql
   select count(*) from formacao_colaborador
    where id_empresa = 1 and dt_validade between trunc(sysdate) and trunc(sysdate) + 60;
   ```

#### Se não funcionar

| Sintoma | Causa provável | Correção |
|---|---|---|
| Clicar no nome dá erro de acesso ou abre a página 19 vazia | Link sem Set Items `P19_ID_COLABORADOR` | Passo 2 |
| Não aparece `#ID_COLABORADOR#` como opção no link | A query não traz `id_colaborador` | Passo 1 |
| Coluna de números (o id) aparecendo na lista | `ID_COLABORADOR` ficou como Plain Text | Passo 2: **Hidden Column** |
| Tipo aparece como `CERTIFICACAO` | Coluna `TIPO` sem LOV | Passo 2 |
| Data no formato `11/05/2026` (mês primeiro) ou com hora | `VALIDADE` sem Format Mask | Passo 2: `DD/MM/YYYY` |
| Região vazia, sem mensagem | No Data Found em branco | Passo 1 |

---

### 5.5 Solicitações de correção abertas (Interactive Report + modal na página 23)

#### Como funciona

O colaborador abre um pedido de correção pela página 22 (§6), por exemplo "minha promoção está com a data errada". O pedido entra com situação `ABERTA` e aparece nesta lista para o RH. Para cada pedido, o RH:

1. **Clica no nome do colaborador.** Abre a página 13 daquela pessoa. Se o pedido tiver razão, o RH corrige ali: estorna o lançamento errado e lança o certo (§3). O histórico nunca é editado direto, por isso a correção é sempre "estorno + novo lançamento".
2. **Clica em "Responder".** Abre a página 23, uma modal pequena onde o RH marca o pedido como **Resolvida** (corrigiu) ou **Recusada** (estava certo) e escreve uma resposta para o colaborador. Ao salvar, o pedido sai da lista.

A §5.5 tem duas partes: a **página 23** (Passos 1 a 4), que precisa existir antes porque o link "Responder" aponta para ela, e a **lista na página 20** (Passos 5 a 7).

> **Antes de começar:** confira que o número 23 está livre no app (Builder › Application 100). Se não estiver, use outro e troque `P23_` por `P<número>_` em tudo abaixo.

#### Passo 1 · Criar a página 23 (modal)

1. **Create Page** › **Blank Page**.
2. Preencha:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Page Number | `23` |
| Identification | Name | `Responder solicitação` |
| Appearance | Page Mode | **Modal Dialog** |
| Navigation | Use Breadcrumb / Navigation Menu | Off (é modal) |

3. Depois de criada, nos atributos da página:
   - **Security › Authorization Scheme:** `ADMIN_RH`
   - **Security › Page Access Protection:** **Arguments Must Have Checksum**
   - Se você usou a Opção B do §1.3, informe também a Error Handling Function aqui.

#### Passo 2 · Itens

Crie uma região **Static Content** chamada `Solicitação` no **Content Body** e, dentro dela, os itens:

| Item | Type | Label | Detalhes |
|---|---|---|---|
| `P23_ID_SOLICITACAO` | **Hidden** | | Value Protected: **Yes**. Vem do link da página 20 |
| `P23_NM_COLABORADOR` | **Display Only** | `Colaborador` | Source: nenhum (o Passo 3 preenche) |
| `P23_DS_LANCAMENTO` | **Display Only** | `Registro questionado` | Source: nenhum |
| `P23_DS_MENSAGEM` | **Display Only** | `Pedido` | Source: nenhum |
| `P23_ST_SOLICITACAO` | **Radio Group** | `Resposta` | Value Required: **On** · List of Values › Type **Static Values**: `Resolvida` = `RESOLVIDA`, `Recusada` = `RECUSADA` · Display Null Value: Off |
| `P23_DS_RESPOSTA` | **Textarea** | `Mensagem ao colaborador` | Maximum Length `2000` · Help/Inline Help: "Obrigatória se recusar." |

Para que serve cada um:
- Os três **Display Only** mostram ao RH o que está respondendo. Sem eles, a modal teria só o radio e a caixa de texto, sem dizer de qual pedido se trata.
- `P23_ST_SOLICITACAO` só aceita `RESOLVIDA` ou `RECUSADA`, os mesmos valores que o package valida. Escreva os valores exatamente assim, em maiúsculas.
- `P23_DS_RESPOSTA` não é obrigatório na tela porque só é exigido na recusa. Quem confere isso é o package: se o RH recusar sem escrever nada, aparece "Explique ao colaborador por que a solicitação foi recusada." (com o §1.3 configurado, sem "ORA-").

#### Passo 3 · Processo "Carregar solicitação" (Before Header)

Na aba **Pre-Rendering › Before Header**, crie um processo **PL/SQL Code** chamado `Carregar solicitação`:

```sql
begin
  select c.nome_completo,
         s.ds_mensagem,
         case when h.id_historico_carreira is not null
              then to_char(h.dt_efetiva, 'dd/mm/yyyy') || ' · ' || t.ds_tipo
              else 'Não informado'
         end
    into :P23_NM_COLABORADOR, :P23_DS_MENSAGEM, :P23_DS_LANCAMENTO
    from solicitacao_correcao s
    join colaborador c             on c.id_colaborador        = s.id_colaborador
    left join historico_carreira h on h.id_historico_carreira = s.id_historico_carreira
    left join tipo_movimentacao  t on t.id_tipo_movimentacao  = h.id_tipo_movimentacao
   where s.id_solicitacao = :P23_ID_SOLICITACAO
     and s.id_empresa     = :G_ID_EMPRESA
     and s.st_solicitacao = 'ABERTA';
exception
  when no_data_found then
    raise_application_error(-20019, 'Solicitação não encontrada ou já respondida.');
end;
```

- **`s.id_empresa = :G_ID_EMPRESA`:** impede abrir pedido de outra empresa trocando o id na URL (o checksum já bloqueia isso, e esta é a segunda proteção).
- **`st_solicitacao = 'ABERTA'`:** se dois do RH abrirem o mesmo pedido, quem chegar depois vê a mensagem em vez de responder de novo. O package também confere isso ao salvar.
- **`left join` com o histórico:** o colaborador pode pedir correção sem escolher um registro ("Não sei / vários" na página 22). Nesse caso aparece "Não informado".

#### Passo 4 · Botões e processos

Crie uma região **Buttons Container** no **Dialog Footer** (como no §3.4, Passo 1) com dois botões:

| Button Name | Label | Slot | Behavior |
|---|---|---|---|
| `CANCELAR` | Cancelar | **Close** | Action **Defined by Dynamic Action** · DA *Click* › True action **Cancel Dialog** |
| `RESPONDER` | Responder | **Next** | Action **Submit Page** · **Hot: On** |

Na aba **Processing**, nesta ordem:

1. **Responder** · PL/SQL Code · Server-side Condition › When Button Pressed `RESPONDER`:
   ```sql
   pkg_historico_carreira.responder_solicitacao(
     p_id_solicitacao => :P23_ID_SOLICITACAO,
     p_st_solicitacao => :P23_ST_SOLICITACAO,
     p_ds_resposta    => :P23_DS_RESPOSTA);
   ```
2. **Fechar** · Type **Close Dialog** · When Button Pressed `RESPONDER` · Success Message `Resposta registrada.`

O package confere de novo que o usuário é do RH, que o pedido é da empresa dele e que ainda está aberto. Também grava quem respondeu e quando (`usr_resolucao`, `dt_resolucao`).

#### Passo 5 · Região na página 20

Volte à página 20 e crie uma região **Interactive Report** no Body, Sequence `55` (depois de Formações a vencer), Title `Solicitações de correção abertas`, Source **SQL Query**:

```sql
select s.id_solicitacao,
       s.id_colaborador,
       c.nome_completo                         as colaborador,
       s.ds_mensagem                           as solicitacao,
       h.dt_efetiva                            as data_lancamento,
       t.ds_tipo                               as lancamento,
       pkg_historico_carreira.fn_data_local(s.id_empresa, s.dt_criacao) as aberta_em,
       'Responder'                             as responder
  from solicitacao_correcao s
  join colaborador c             on c.id_colaborador        = s.id_colaborador
  left join historico_carreira h on h.id_historico_carreira = s.id_historico_carreira
  left join tipo_movimentacao  t on t.id_tipo_movimentacao  = h.id_tipo_movimentacao
 where s.id_empresa     = :G_ID_EMPRESA
   and s.st_solicitacao = 'ABERTA'
 order by s.dt_criacao
```

Por que cada parte importa:
- **`id_solicitacao` e `id_colaborador`:** não aparecem na tela. São os valores que os links mandam para as páginas 23 e 13.
- **`'Responder' as responder`:** uma coluna só com o texto do link. Assim o link fica numa coluna própria, com cabeçalho, em vez de esconder o link atrás de um número.
- **`left join` com o histórico:** pedidos sem registro escolhido também aparecem, com Data e Lançamento vazios.
- **`fn_data_local`:** `dt_criacao` é gravada com fuso horário. A função converte para a hora local da empresa, para "Aberta em" não mostrar 3 horas a mais.
- **`order by s.dt_criacao`:** o pedido mais antigo aparece primeiro, para ser atendido antes.

> **Não apague colunas pela árvore.** Como no §4.4, no Interactive Report as colunas vêm da query: para tirar ou incluir uma coluna, mude a query.

#### Passo 6 · Colunas

| Coluna | Type | Heading | Outros atributos |
|---|---|---|---|
| `ID_SOLICITACAO` | **Hidden Column** | | |
| `ID_COLABORADOR` | **Hidden Column** | | |
| `COLABORADOR` | **Link** | `Colaborador` | Target: Page `13` · Set Items `P13_ID_COLABORADOR` = `#ID_COLABORADOR#` · Link Text `#COLABORADOR#` |
| `SOLICITACAO` | Plain Text | `Pedido` | |
| `DATA_LANCAMENTO` | Plain Text | `Data do registro` | Format Mask `DD/MM/YYYY` |
| `LANCAMENTO` | Plain Text | `Registro` | |
| `ABERTA_EM` | Plain Text | `Aberta em` | Format Mask `DD/MM/YYYY HH24:MI` |
| `RESPONDER` | **Link** | `Ação` | Target: Page `23` · Set Items `P23_ID_SOLICITACAO` = `#ID_SOLICITACAO#` · Link Text `#RESPONDER#` |

- Monte os dois links pelo editor de link do Builder. As páginas 13 e 23 exigem checksum, e um `f?p=` montado à mão é recusado.
- Em **No Data Found** da região (confirmar no 26.1.5): `Nenhuma solicitação aberta.`

#### Passo 7 · Atualizar a lista quando a modal fechar

Sem este passo, o pedido respondido continua na lista até a página ser recarregada.

1. Clique com o botão direito na região **Solicitações de correção abertas** › **Create Dynamic Action**.
2. Name `Atualizar solicitações` · Event **Dialog Closed** · Selection Type **Region** · Region `Solicitações de correção abertas`.
3. True action: **Refresh** › Affected Elements › Region `Solicitações de correção abertas`.

Esta DA é separada da "Período mudou": a lista não depende de De/Até.

#### Testar

A página 22 (§6), onde o colaborador abre o pedido, vem depois desta etapa. Para testar agora, crie um pedido de teste no **SQL Commands** (um comando por vez, sem `;` no final):

```sql
insert into solicitacao_correcao (id_empresa, id_colaborador, ds_mensagem)
select 1, min(id_colaborador), 'TESTE: a data da minha última promoção está errada.'
  from colaborador
 where id_empresa = 1 and status
```

1. Rode a página 20. A lista mostra o pedido de teste, com "Aberta em" na hora local e Data/Registro vazios.
2. Clique no nome. A página 13 abre no histórico daquela pessoa.
3. Volte e clique em **Responder**. A modal mostra colaborador, "Não informado" e o texto do pedido.
4. Marque **Recusada** sem escrever nada e clique em Responder. Aparece "Explique ao colaborador por que a solicitação foi recusada."
5. Escreva uma resposta e clique em Responder. A modal fecha, aparece "Resposta registrada." e o pedido sai da lista.
6. Confira no banco:
   ```sql
   select st_solicitacao, ds_resposta, usr_resolucao, dt_resolucao
     from solicitacao_correcao
    where ds_mensagem like 'TESTE:%'
   ```
7. Apague o pedido de teste: `delete from solicitacao_correcao where ds_mensagem like 'TESTE:%'`

#### Se não funcionar

| Sintoma | Causa provável | Correção |
|---|---|---|
| Não aparece a página 23 como Target do link | A página 23 ainda não foi criada | Passos 1 a 4 antes do Passo 6 |
| A modal abre com tudo vazio, ou com "Solicitação não encontrada" | Link "Responder" sem Set Items `P23_ID_SOLICITACAO` | Passo 6 |
| Clicar no nome abre o histórico do próprio usuário | Link `COLABORADOR` sem Set Items `P13_ID_COLABORADOR` | Passo 6 |
| Números (os ids) aparecendo na lista | `ID_SOLICITACAO` ou `ID_COLABORADOR` ficaram como Plain Text | Passo 6: **Hidden Column** |
| Pedido respondido continua na lista | Falta a DA Dialog Closed | Passo 7 |
| `Responda com RESOLVIDA ou RECUSADA` | Valores do Radio Group diferentes (ex.: `Resolvida`) | Passo 2: valores em maiúsculas |
| `Esta solicitação já foi respondida` | Outra pessoa do RH respondeu antes | Esperado. Feche a modal |
| Erro com "ORA-20019" ou "ORA-20012" na tela | Tratamento de erro do §1.3 não configurado para a página 23 | §1.3 |

---

## 6. Página 22 · Solicitar correção (Modal)

> Ao terminar esta página, confira que `c_pagina_solicitacao` está `22` em `08_pkg_historico_carreira_ui.sql` (o arquivo já vem assim) e rode o arquivo de novo no banco. Se você tinha mudado para `null` para fugir do `ERR-1002`, o botão "Solicitar correção" só aparece na página 13 depois disso. Para conferir o que está no banco: `select text from user_source where name = 'PKG_HISTORICO_CARREIRA_UI' and text like '%c_pagina_solicitacao%constant%'`.

- Page Mode: **Modal Dialog** · Authorization Scheme: `COLABORADOR` · Title "Solicitar correção"
- Processo **Colaborador logado** · PL/SQL · Point: **Before Header** · Sequence 10. Preenche o colaborador com o usuário logado antes de a página ser montada:
  ```sql
  begin
    select id_colaborador
      into :P22_ID_COLABORADOR
      from colaborador
     where upper(login_apex) = upper(:APP_USER)
       and id_empresa = :G_ID_EMPRESA;
  exception
    when no_data_found then
      raise_application_error(-20012, 'Seu usuário não está vinculado a um colaborador.');
  end;
  ```
  Sem esse processo, `P22_ID_COLABORADOR` só tem valor quando a modal é aberta pelo botão da página 13. Aberta de outro jeito (pelo Run do Page Designer, por exemplo), o item fica vazio e o select list "Qual registro?" mostra só "Não sei / vários". Como só o próprio colaborador pode pedir correção, a página sempre usa o usuário logado, mesmo que a URL traga outro id. As contas da equipe sem colaborador veem a mensagem de erro, o que é esperado.
- Itens:
  - `P22_ID_COLABORADOR`: Hidden · Checksum Required - Session Level · preenchido pelo processo acima
  - `P22_ID_HISTORICO_CARREIRA`: Select List opcional, Label "Qual registro?", Null display "Não sei / vários". Query:
    ```sql
    select to_char(h.dt_efetiva, 'dd/mm/yyyy') || ' · ' || t.ds_tipo d, h.id_historico_carreira r
      from historico_carreira h
      join tipo_movimentacao t on t.id_tipo_movimentacao = h.id_tipo_movimentacao
     where h.id_colaborador = :P22_ID_COLABORADOR
       and h.id_empresa     = :G_ID_EMPRESA
       and h.st_registro    = 'EFETIVADO'
       and h.id_registro_estornado is null
     order by h.dt_efetiva desc
    ```
  - `P22_DS_MENSAGEM`: Textarea obrigatório, Label "O que está incorreto?", Max 2000
- Texto de apoio: "O RH revisa o pedido. Se houver correção, ela também fica registrada no histórico."
- Botões: `CANCELAR` (Cancel Dialog) e `ENVIAR` (Hot)
- Processo **Enviar** · When Button Pressed `ENVIAR`:
  ```sql
  declare
    l_id number;
  begin
    l_id := pkg_historico_carreira.solicitar_correcao(
              p_id_colaborador        => :P22_ID_COLABORADOR,
              p_ds_mensagem           => :P22_DS_MENSAGEM,
              p_id_historico_carreira => :P22_ID_HISTORICO_CARREIRA);
  end;
  ```
- Processo **Fechar** · Close Dialog · Server-side Condition: When Button Pressed `ENVIAR` · Success Message "Pedido enviado ao RH."

O package confere que quem pede é o próprio colaborador. Mesmo com o checksum, ninguém consegue abrir pedidos em nome de outra pessoa.

---

## 7. Ligações com páginas existentes

1. **Página 14 · Cadastro de usuários:** gera a admissão automática.
   - Novo processo **Registrar admissão** · PL/SQL · Point: Processing · Sequence **15** (logo depois de "Salvar Dados Colaborador", antes de "Criar usuário APEX"):
     ```sql
     pkg_historico_carreira.registrar_admissao_automatica(:P14_ID_COLABORADOR);
     ```
     Além da admissão, isso publica o comunicado de boas-vindas para a equipe (se `CONFIG_CARREIRA.FL_COMUNICADO_AUTOMATICO` estiver ligado, o padrão).
   - Server-side Condition: Item `P14_ID_COLABORADOR` is not null. O processamento automático do form devolve a PK nesse item depois do insert.
   - Botão **Histórico de carreira** (condição: `P14_ID_COLABORADOR` is not null · Authorization `ADMIN_RH`) · Redirect página 13 com `P13_ID_COLABORADOR` = `&P14_ID_COLABORADOR.`
2. **Página 12 · Colaboradores:** quando a lista for criada, adicione uma coluna link "Histórico" para a página 13 com `P13_ID_COLABORADOR` = `#ID_COLABORADOR#`.
3. **Página 2 · Meu perfil:** botão **Meu histórico** para a página 13 sem parâmetro. A página abre no próprio usuário.
4. **Navegação:** entradas "Histórico de carreira" (página 13, sem parâmetro) e "Dashboard RH" (página 20, Authorization `ADMIN_RH`) no menu.

---

## 8. Checklist de teste no APEX

- [ ] Usuário sem o papel Admin RH não vê o botão "Nova movimentação", nem a região de lançamentos, nem as colunas de salário.
- [ ] Trocar o `P13_ID_COLABORADOR` na URL dá erro de checksum.
- [ ] Gestor abre o histórico de alguém da equipe (inclusive indireto), mas não o de um colega de outra equipe.
- [ ] Na modal, trocar o tipo para Mérito esconde e limpa cargo, departamento e gestor.
- [ ] Efetivar uma promoção muda o cargo no organograma (página 3).
- [ ] Estornar a promoção devolve o cargo anterior, e a timeline mostra o estorno.
- [ ] Cada abertura de lançamento com salário gera uma linha em `LOG_ACESSO_SALARIAL`.
- [ ] Erros do package aparecem como mensagem simples, sem "ORA-20005".
- [ ] A página 13 fica igual ao protótipo: resumo com 3 indicadores, faixa de cargos, abas com contagem, filtro de ano, posição atual e "Sobre este histórico".
- [ ] Trocar de aba ou de ano esconde os eventos e atualiza a contagem de cada ano.
- [ ] Um gestor não vê o "Reajuste por mérito" de quem é da equipe; o próprio colaborador vê.
- [ ] Efetivar uma promoção cria um comunicado na página de comunicados, e o evento mostra "Equipe de ... avisada automaticamente".
- [ ] "Exportar PDF" abre a impressão só com o conteúdo do histórico, sem menu e sem cabeçalho.
- [ ] "Solicitar correção" grava o pedido, e a página passa a mostrar "1 solicitação em análise pelo RH".
