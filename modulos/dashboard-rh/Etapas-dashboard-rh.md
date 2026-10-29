# Dashboard RH (página 20) · redesign · passo a passo no APEX

Este guia deixa a página 20 (Dashboard RH) igual ao protótipo [`pen_dev/Dashboard RH.png`](../../pen_dev/Dashboard%20RH.png), no App Builder do **APEX 26.1.5**. A página continua sendo a 20, com o mesmo alias, a mesma autorização (`ADMIN_RH`) e os mesmos itens de período; o que muda são as regiões.

A versão anterior foi montada pelo `modulos/historico-carreira/Etapas-historico-carreira.md` §5. Este guia **substitui** aquele §5 no Builder; as regras de negócio (o que conta como promoção, admissão, desligamento, tempo no cargo e formação a vencer) continuam as mesmas.

Como nos outros guias, a mudança é feita no Builder. O backup diário traz o resultado para `corlixhub/pages/p00020-dashboard-rh.apx` na `DEV`; editar o `.apx` do repositório não muda o app e é desfeito no próximo backup. **Para voltar atrás**, a versão atual da página está em `corlixhub/pages/p00020-dashboard-rh.apx` (commit `47a2d40`).

### Como ler os caminhos deste guia (APEX 26.1.5)

- **Rendering** é a árvore da esquerda do Page Designer; o **painel de propriedades** é o da direita. `Seção › Atributo` indica a seção e o campo no painel do componente selecionado.
- No 26.1.5 a região **não tem a aba nem o nó "Attributes"**. Para achar qualquer atributo, use a busca no topo do painel de propriedades.
- Passos marcados com **(confirmar no 26.1.5)** ainda não foram conferidos na tela desta versão. Se o caminho não existir, não procure por tentativa: tire um print da árvore e do painel e registre o caminho certo neste guia.

### O que muda

| Antes | Depois (protótipo) |
|---|---|
| Título "Dashboard RH" dentro do corpo e região "Período" separada, com De/Até | Faixa branca no topo: título e descrição à esquerda, **De** e **Até** à direita |
| Sem números de resumo | 3 indicadores: **Promoções** ("Em 4 de 6 departamentos"), **Admissões** ("290 delas em jun/2026") e **Desligamentos** ("Saldo no período: +292 pessoas"). Cada card leva ao quadro correspondente |
| Gráfico JET de turnover: a barra de jun/2026 (290) achata os outros meses | Barras em HTML/CSS com eixo nos meses "normais"; a barra fora de escala é **cortada** (corte diagonal + "290" em cima) e uma nota explica. **Ver em tabela** mostra os números mês a mês |
| Dois gráficos separados: promoções e tempo médio no cargo por departamento | Uma tabela **Promoções e tempo no cargo por departamento**, com barra + número nas duas colunas, todos os departamentos (inclusive com 0 promoções), ordenada por promoções |
| Formações a vencer em Classic Report (6 colunas) | Card lateral **Formações a vencer**: nome, formação, "Tipo · Instituição · vence em", selo de prazo colorido (≤ 7 dias vermelho, ≤ 30 âmbar, o resto cinza) |
| Solicitações abertas em Interactive Report | Card lateral **Solicitações de correção**: iniciais, nome, "há N dias", pedido, "Aberta em", **Responder** (abre a página 23 como antes) |

### Decisões que diferem do print

- **"Ver todas as solicitações" / "Ver todas as formações"** só aparecem quando há mais itens do que o card mostra (3 solicitações, 5 formações) e abrem um diálogo com a lista completa. Não existe página que liste todas as solicitações ou todas as formações da empresa (a página 19 é por colaborador). Para mostrar o link sempre, troque `l_total > l_limite` por `l_total > 0` nas duas funções do package.
- **Avatares** com iniciais, sem foto (o print também não mostra fotos).
- **Os chevrons (›) dos indicadores** rolam até o quadro da página: Promoções → tabela por departamento; Admissões e Desligamentos → turnover. Ainda não há página de detalhe para onde levar.
- O nome na formação é link para a página 19 (formações do colaborador), como na versão anterior.

### Fica de fora

- Header, busca e menu lateral do print: são da Global Page e dos Shared Components.
- O período (De/Até) continua valendo só para os indicadores, o turnover e as promoções. Solicitações, formações e tempo no cargo mostram a situação de hoje, como antes.

### Arquivos do módulo

| Arquivo | O que é |
|---|---|
| `pkg_dashboard_rh_ui.pks` / `.pkb` | Package que devolve o HTML dos 5 cards (`render_indicadores`, `render_turnover`, `render_departamentos`, `render_solicitacoes`, `render_formacoes`) |
| `instalar.sql` | Instala o package pelo SQLcl |
| `dashboard-rh.css` / `dashboard-rh.min.css` | Estilos da página (classes `cx-dash-*`); sobem como Static Application Files |
| `dashboard-rh-pagina.js` | JavaScript da página: "Ver em tabela" e abertura dos diálogos |

O package só lê o que o módulo de histórico de carreira já criou: `vw_movimentacao_valida`, `vw_situacao_atual_colaborador`, `formacao_colaborador`, `solicitacao_correcao` e `pkg_historico_carreira.fn_hoje` / `fn_data_local`. Não há tabela nova.

---

## 1. Banco: instalar o `pkg_dashboard_rh_ui`

**Pelo SQLcl:** `cd modulos/dashboard-rh` e `sql <usuario>@<servico> @instalar.sql`.

**Pelo SQL Workshop:** *SQL Workshop › SQL Scripts › Upload*, envie `pkg_dashboard_rh_ui.pks` e rode; depois `pkg_dashboard_rh_ui.pkb` e rode. Os dois terminam em `/`, então funcionam como script. No *SQL Commands*, cole um arquivo por vez **sem** a `/` final.

**Teste** (SQL Commands, um comando por vez; troque `1` pela empresa e as datas pelo período que quiser):

```sql
select pkg_dashboard_rh_ui.render_indicadores('01/11/2025', '26/10/2026', 1) from dual
```
Deve voltar um `<div class="cx-dash-kpis">` com os 3 cards.

```sql
select pkg_dashboard_rh_ui.render_turnover('01/11/2025', '26/10/2026', 1) from dual
```
Deve voltar um `<section class="cx-dash-card cx-dash-turnover" ...>` com o gráfico e a tabela.

```sql
select pkg_dashboard_rh_ui.render_solicitacoes(1) from dual
```
Deve voltar o card com as solicitações abertas, ou o estado vazio "Nenhuma solicitação aberta.".

Se der erro de compilação: `select line, position, text from user_errors where name = 'PKG_DASHBOARD_RH_UI' order by sequence` (ver `docs/ai-context/09-erros-e-solucoes.md`).

---

## 2. Arquivos estáticos

Em *Shared Components › Static Application Files › Create File*, envie os dois arquivos **na raiz** (sem pasta), com estes nomes:

| File Name | Arquivo |
|---|---|
| `dashboard-rh.css` | `modulos/dashboard-rh/dashboard-rh.css` |
| `dashboard-rh.min.css` | `modulos/dashboard-rh/dashboard-rh.min.css` |

A página carrega `dashboard-rh#MIN#.css`, então os dois precisam existir e estar iguais. Quando mudar o `.css`, gere o `.min.css` de novo e suba os dois.

---

## 3. Página 20 no Page Designer

Faça os passos na ordem: as regiões novas entram primeiro, as dynamic actions passam para elas e só no fim as regiões antigas são apagadas.

### 3.1 Atributos da página

Clique no nó **Page 20: Dashboard RH** no topo da árvore:

| Seção | Atributo | Valor |
|---|---|---|
| CSS | File URLs | `#APP_FILES#dashboard-rh#MIN#.css` (substitui o `#APP_FILES#historico-carreira#MIN#.css`; nenhuma região nova usa classes `hc-`) |
| JavaScript | Execute when Page Loads | conteúdo de `modulos/dashboard-rh/dashboard-rh-pagina.js` |
| Security | Authorization Scheme | **ADMIN_RH** (já está; confira) |

### 3.2 Cabeçalho com o período

1. Na árvore, botão direito em **Breadcrumb Bar** › **Create Region** (confirmar no 26.1.5):

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `Título e período` |
| Identification | Type | **Static Content** |
| Source | HTML Code | trecho abaixo |
| Appearance | Template | **Blank with Attributes (No Grid)** |
| Appearance | CSS Classes | `cx-cabecalho-pagina cx-dash-cabecalho` |

**Source › HTML Code:**

```html
<div class="cx-cabecalho-pagina__texto">
  <h1 class="cx-cabecalho-pagina__titulo">Dashboard RH</h1>
  <p class="cx-cabecalho-pagina__descricao">Indicadores de pessoas no período selecionado e pendências que aguardam o RH.</p>
</div>
```

2. Leve os dois itens de período para essa região. Selecione **P20_DT_INICIO** (hoje dentro da região "Período") e mude:

| Seção | Atributo | Valor |
|---|---|---|
| Layout | Region | `Título e período` |
| Layout | Sequence | 10 |

Faça o mesmo em **P20_DT_FIM** (Sequence 20). O resto dos itens não muda: Date Picker, rótulos "De" e "Até", template **Required - Floating**, máscara `DD/MM/YYYY`, defaults (11 meses atrás até hoje) e o *Minimum Date* do Até apontando para o De.

O CSS põe o texto à esquerda e os dois campos à direita, com 232px cada. Se os campos ficarem embaixo do título ou um embaixo do outro, veja a tabela "Se não funcionar".

### 3.3 Coluna principal: indicadores, turnover e departamentos

Botão direito em **Body** › **Create Region**:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `Coluna principal` |
| Identification | Type | **Static Content** (Source vazio) |
| Layout | Sequence | 20 |
| Layout | Start New Row | Yes |
| Layout | Column Span | **8** |
| Appearance | Template | **Blank with Attributes** |

Depois, botão direito em **Coluna principal** › **Create Sub Region**, três vezes:

| Seção | Atributo | Indicadores | Turnover | Departamentos |
|---|---|---|---|---|
| Identification | Name | `Indicadores` | `Turnover` | `Promoções e tempo no cargo` |
| Identification | Type | **Dynamic Content** | **Dynamic Content** | **Dynamic Content** |
| Source | PL/SQL Function Body returning a CLOB | `return pkg_dashboard_rh_ui.render_indicadores(:P20_DT_INICIO, :P20_DT_FIM);` | `return pkg_dashboard_rh_ui.render_turnover(:P20_DT_INICIO, :P20_DT_FIM);` | `return pkg_dashboard_rh_ui.render_departamentos(:P20_DT_INICIO, :P20_DT_FIM);` |
| Source | Page Items to Submit | `P20_DT_INICIO,P20_DT_FIM` | `P20_DT_INICIO,P20_DT_FIM` | `P20_DT_INICIO,P20_DT_FIM` |
| Layout | Sequence | 10 | 20 | 30 |
| Appearance | Template | **Blank with Attributes** | **Blank with Attributes** | **Blank with Attributes** |

O título de cada card vem do package; o *Name* da região só aparece no Builder.

### 3.4 Coluna lateral: solicitações e formações

Botão direito em **Body** › **Create Region**:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `Coluna lateral` |
| Identification | Type | **Static Content** (Source vazio) |
| Layout | Sequence | 30 |
| Layout | Start New Row | **No** |
| Layout | Column Span | **4** |
| Appearance | Template | **Blank with Attributes** |

Botão direito em **Coluna lateral** › **Create Sub Region**, duas vezes:

| Seção | Atributo | Solicitações | Formações |
|---|---|---|---|
| Identification | Name | `Solicitações de correção` | `Formações a vencer` |
| Identification | Type | **Dynamic Content** | **Dynamic Content** |
| Source | PL/SQL Function Body returning a CLOB | `return pkg_dashboard_rh_ui.render_solicitacoes;` | `return pkg_dashboard_rh_ui.render_formacoes;` |
| Layout | Sequence | 10 | 20 |
| Appearance | Template | **Blank with Attributes** | **Blank with Attributes** |

### 3.5 Diálogos "Todas as solicitações" e "Todas as formações"

Botão direito em **Dialogs, Drawers and Popups** › **Create Region** (confirmar no 26.1.5), duas vezes:

| Seção | Atributo | Solicitações | Formações |
|---|---|---|---|
| Identification | Name / Title | `Solicitações de correção abertas` | `Formações a vencer (60 dias)` |
| Identification | Type | **Dynamic Content** | **Dynamic Content** |
| Source | PL/SQL Function Body returning a CLOB | `return pkg_dashboard_rh_ui.render_solicitacoes(p_limite => null, p_ver_todas => 'N');` | `return pkg_dashboard_rh_ui.render_formacoes(p_limite => null, p_ver_todas => 'N');` |
| Appearance | Template | **Inline Dialog** | **Inline Dialog** |
| Appearance | Template Options | Size: **Large**, Auto Height (confirmar no 26.1.5) | Size: **Large**, Auto Height (confirmar no 26.1.5) |
| Appearance | CSS Classes | `cx-dash-card--lateral` | `cx-dash-card--lateral` |
| Advanced | HTML DOM ID | `dash_solicitacoes_todas` | `dash_formacoes_todas` |

O **HTML DOM ID** é obrigatório: o "Ver todas" chama `apex.theme.openRegion('<HTML DOM ID>')`. No 26.1 o Static ID só identifica a região no export; sem o HTML DOM ID o APEX gera `R<número>` e o clique dá `Region does not support being opened and closed` (`docs/ai-context/08` §3, "Static ID ≠ id do HTML").

### 3.6 Dynamic actions

**"Período mudou"** (já existe). Ela continua disparando na mudança de `P20_DT_INICIO` / `P20_DT_FIM`, com a condição de os dois estarem preenchidos. Troque as ações:

| Ação | Antes | Depois |
|---|---|---|
| `Atualizar promoções` | Refresh · `Promoções por departamento` | Name `Atualizar indicadores` · Refresh · Region **Indicadores** |
| `Atualizar turnover` | Refresh · `Turnover: admissões x desligamentos por mês` | Refresh · Region **Turnover** |
| (nova) | — | Botão direito em *True* › **Create TRUE Action**: Name `Atualizar departamentos` · Action **Refresh** · Region **Promoções e tempo no cargo** · Sequence 30 · Fire on Initialization **Off** |

**"Atualizar solicitações"** (já existe; hoje escuta o fechamento do diálogo só no Interactive Report). Os links "Responder" agora estão dentro de regiões Dynamic Content, então o evento é ouvido no documento inteiro, como na página 13:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `Solicitação respondida` |
| When | Event | **Dialog Closed** |
| When | Selection Type | **JavaScript Expression** |
| When | JavaScript Expression | `document` |

Ações (*True*): troque a região da ação existente para **Solicitações de correção** e crie mais uma, Refresh · Region **Solicitações de correção abertas** (o diálogo), Sequence 20, Fire on Initialization **Off**.

### 3.7 Apagar as regiões antigas

Só depois de 3.2 a 3.6. Botão direito › **Delete** em cada uma:

| Região antiga (Name) | Static ID no export |
|---|---|
| Cabeçalho (no Body, sequence 5) | `cabeçalho` |
| Período (já sem itens) | `período` |
| Promoções por departamento | `grafico_promocoes` |
| Turnover: admissões x desligamentos por mês | `grafico_turnover` |
| Tempo médio no cargo por departamento | `grafico_tempo_cargo` |
| Formações a vencer (Classic Report) | `rel_formacoes_vencer` |
| Solicitações de correção abertas (Interactive Report) | `rel_solicitacoes` |

Se o Builder avisar que uma dynamic action ainda aponta para a região, volte ao 3.6: alguma ação ficou com a região antiga.

### 3.8 Como deve ficar a árvore

```
Page 20: Dashboard RH                       (CSS dashboard-rh#MIN#.css, ADMIN_RH)
├── Breadcrumb Bar
│   └── Título e período                    (cx-cabecalho-pagina cx-dash-cabecalho)
│       ├── P20_DT_INICIO
│       └── P20_DT_FIM
├── Body
│   ├── Coluna principal                    (20, span 8)
│   │   ├── Indicadores                     (render_indicadores)
│   │   ├── Turnover                        (render_turnover)
│   │   └── Promoções e tempo no cargo      (render_departamentos)
│   └── Coluna lateral                      (30, span 4, não começa linha)
│       ├── Solicitações de correção        (render_solicitacoes)
│       └── Formações a vencer              (render_formacoes)
├── Dialogs, Drawers and Popups
│   ├── Solicitações de correção abertas    (dash_solicitacoes_todas)
│   └── Formações a vencer (60 dias)        (dash_formacoes_todas)
└── Dynamic Actions
    ├── Período mudou                       (3 refresh)
    └── Solicitação respondida              (Dialog Closed em document, 2 refresh)
```

---

## 4. Testar

Abra a página 20 com um usuário que tenha o papel Admin RH e recarregue com **Ctrl+Shift+R** (Cmd+Shift+R no Mac) para não ver CSS antigo em cache.

1. **Cabeçalho:** faixa branca com "Dashboard RH", a descrição e os campos **De** e **Até** à direita, na mesma linha. Estreite a janela: os campos descem para baixo do título.
2. **Indicadores:** Promoções, Admissões e Desligamentos com ícone, número grande e a linha de detalhe. Clique em **Admissões**: a página rola até o turnover. Clique em **Promoções**: rola até a tabela por departamento.
3. **Turnover:** barras azuis (admissões) e laranja (desligamentos) por mês, eixo com números inteiros, rótulos "nov/25 … out/26". Com os dados de demonstração, jun/26 aparece **cortado**, com "290" em cima, rótulo em negrito e a nota "Jun/2026 está fora de escala…" embaixo. Passe o mouse numa barra: aparece "jun/2026: 290 admissões".
4. **Ver em tabela:** o gráfico e a nota somem e aparece a tabela Mês / Admissões / Desligamentos / Saldo com a linha Total; o botão vira **Ver gráfico**. Clique de novo e o gráfico volta.
5. **Mude o período** (ex.: De `01/01/2026`): os indicadores, o turnover e a tabela por departamento atualizam sem recarregar a página. Solicitações e formações não mudam (esperado).
6. **Promoções e tempo no cargo:** todos os departamentos da empresa, os com mais promoções primeiro; departamento sem promoção mostra "0" em cinza, sem barra; tempo em "N meses" (menos de 1 ano) ou "x,y anos".
7. **Solicitações de correção:** selo "N abertas", as 3 mais antigas, com "há N dias" e "Aberta em dd/mm/aaaa, hh:mi". Clique em **Responder**: abre a página 23. Responda e feche: o card atualiza sozinho e a solicitação some.
8. **Formações a vencer:** selo "N a vencer", as 5 que vencem primeiro nos próximos 60 dias; prazo vermelho até 7 dias, âmbar até 30, cinza depois. Clique no nome: abre a página 19 daquele colaborador.
9. Com mais de 3 solicitações (ou 5 formações), aparece **Ver todas … →**, que abre o diálogo com a lista completa.
10. Tab pela página: indicadores, "Ver em tabela", "Responder", nomes e "Ver todas" mostram o contorno azul de foco.

### Como conferir no export da página 20

No próximo backup, `corlixhub/pages/p00020-dashboard-rh.apx` deve ter:

```
css {
    fileUrls: #APP_FILES#dashboard-rh#MIN#.css
}
...
region título-e-período (            -- nome do Static ID gerado pelo Builder: conferir
    type: staticContent
    layout { ... slot: breadcrumbBar }
    appearance {
        template: @/blank-with-attributes-no-grid
        cssClasses: [
            cx-cabecalho-pagina
            cx-dash-cabecalho
        ]
    }
```

regiões `type: dynamicContent` com `plsqlFunctionBody: return pkg_dashboard_rh_ui.render_...` e `pageItemsToSubmit` nas três da coluna principal, os dois diálogos com `template: @/inline-dialog` e `advanced { htmlDomId: dash_solicitacoes_todas }` / `dash_formacoes_todas`, a DA `Solicitação respondida` com `selectionType: jsExpression` · `javaScriptExpression: document`, e **nenhuma** região `type: chart`, `classicReport` ou `interactiveReport`.

### Se não funcionar

| Sintoma | Causa provável | Correção |
|---|---|---|
| `ORA-06550` / `PLS-00201: identifier 'PKG_DASHBOARD_RH_UI' must be declared` | Package não instalado | Seção 1 |
| Tudo sem estilo (textos soltos, sem cards) | `dashboard-rh.css`/`.min.css` não subiram, ou a página ainda carrega `historico-carreira#MIN#.css` | Seções 2 e 3.1; recarregue com Ctrl+Shift+R |
| Campos De/Até embaixo do título, ou um embaixo do outro | O APEX envolveu os itens num contêiner diferente do esperado (`.t-Form-fieldContainer` filho direto da região) | Confira o template da região (**Blank with Attributes (No Grid)**). Se estiver certo, inspecione um dos campos no DevTools e mande um print da árvore do HTML a partir de `.cx-dash-cabecalho` para ajustar o seletor no CSS |
| Cards mostram "Empresa não identificada na sessão" | `G_ID_EMPRESA` vazio (só é preenchido no login) | Saia e entre de novo (`docs/ai-context/08` §3, Módulos) |
| "Informe as datas De e Até…" | Um dos campos vazio ou fora do formato `DD/MM/AAAA` | Preencha os dois; a máscara dos itens deve ser `DD/MM/YYYY` |
| Mudar o período não atualiza os cards | Ações da DA "Período mudou" ainda apontam para regiões antigas, ou falta *Page Items to Submit* | Passos 3.3 (Page Items to Submit) e 3.6 |
| Atualiza, mas com o período antigo | *Page Items to Submit* vazio na região | Passo 3.3 |
| Responder e fechar a página 23 não atualiza o card | DA ainda escuta só a região antiga | Passo 3.6: Selection Type **JavaScript Expression** · `document` |
| "Ver todas" não abre; no console: `Region does not support being opened and closed` | Diálogo sem **HTML DOM ID** | Passo 3.5 |
| "Ver em tabela" não faz nada | JS da página ausente | Passo 3.1, *Execute when Page Loads* |
| Gráfico e tabela aparecem juntos | CSS antigo em cache (falta a regra `.cx-dash-card [hidden]`) | Ctrl+Shift+R; confira se o `.min.css` no app é o deste módulo |
| Nenhuma barra cortada mesmo com um mês muito acima | Esperado quando o maior valor não passa de 4× o segundo maior. O fator é `c_fator_corte` no package | Ajuste a constante se o time preferir outro corte |
