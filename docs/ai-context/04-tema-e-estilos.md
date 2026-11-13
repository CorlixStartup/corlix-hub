# 04 · Tema e estilos (sistema visual do Corlix Hub)

> **Estado em 13/11/2026 (backup 84f8625, "Backup - Corlix Hub - 13/11/2026 as 09:52").**
> Contexto para IAs. Fonte do estado **publicado**: `corlixhub/shared-components/static-files/` (CSS, `.min.css`, fontes, imagens), o manifesto `corlixhub/shared-components/static-files.apx`, `corlixhub/shared-components/themes/universal-theme/` (`theme.apx`, `page-templates/corlix-standard-page.apx`), `corlixhub/application.apx` e os `fileUrls` de `corlixhub/pages/*.apx`. Fonte das **versões dos módulos**: `modulos/*/*.css` e `modulos/tema/` (README e guias). Telas-alvo: `pen_dev/Design System · Redwood Light (CorlixHub).png` e [`07-design-pen-dev.md`](./07-design-pen-dev.md).
> Os nomes dos glifos Lucide foram conferidos no `lucide.css` do pacote `lucide-static@0.460.0` (a mesma versão citada no `corlix-tema.css`).
> Regras que valem para tudo abaixo: **sem CSS Inline** e sem atributo `style` (AGENTS.md; [08](./08-convencoes-e-pegadinhas.md) §1 regra 5; [11](./11-padroes-de-paginas.md) C1). O agente **não edita** `corlixhub/`: toda mudança de CSS é feita pelo time no Builder, a partir do arquivo do módulo.

---

## 1. Visão geral

- **Universal Theme 42** (`baseTheme: ut-26.1`), estilo **Redwood Light** como *Current* (`theme.apx` → `currentThemeStyle: @/redwood-light`). Não há tema próprio nem estilo de Theme Roller salvo.
- O "Tema Corlix" é **uma camada CSS** sobre o Redwood Light: tokens `--cx-*` + redefinição de variáveis do UT (`--ut-*`, `--a-*`, `--u-color-*`) + poucos ajustes de componente, tudo em `corlix-tema.css`. Regra da prancha: *componentes nativos, Template Options e variáveis do tema; CSS próprio só onde o nativo não chega*.
- Cada módulo tem o seu CSS, carregado só nas páginas dele (*Page › CSS › File URLs*), com prefixo próprio de classe (`cx-home-`, `cx-hol-`, `cx-ponto-`, `cx-sup-`, `cx-comunicado`, `cx-colab-`, `perfil-`, `org-`, `hc-`).
- **Fonte:** Figtree (variável, 300 a 900). **Ícones:** Lucide por dois caminhos, que coexistem (§5): (a) fonte reduzida "Corlix Lucide" (`lucide.woff2`), que troca o glifo das classes Font APEX `fa-*`; (b) SVG Lucide em linha, gerado pela função `icone()` dos packages `pkg_*_ui`.
- **Dark mode: não existe.** Nenhum CSS publicado tem `prefers-color-scheme` nem variante escura de token; a prancha só tem versão clara.

---

## 2. Como o CSS é carregado

### 2.1 Onde está configurado

| O quê | Onde (APEXlang) | Valor atual |
|---|---|---|
| CSS global (todas as páginas) | `corlixhub/application.apx` → `css.fileUrls` (UI Attributes › CSS › File URLs) | `#APP_FILES#corlix-tema#MIN#.css` e depois `#APP_FILES#custom#MIN#.css` |
| CSS do tema | `theme.apx` → `css.fileUrls` | `#THEME_FILES#css/Core#MIN#.css?v=#APEX_VERSION#` (nativo) |
| CSS por página | `page { css { fileUrls: ... } }` em `corlixhub/pages/pXXXXX-*.apx` | ver §3 |
| CSS Inline de página | `page { css { inline: ... } }` | **só a p4 (Chat)**, legado (tokens `--ch-*` → `--cx-*`). Não criar novos |
| Atributo `style` em página | HTML de região | só a p0: `style="display:none"` no `<span>` de iniciais do avatar do header (legado, §9) |
| Arquivos estáticos | `static-files/` + manifesto `shared-components/static-files.apx` | lista em §3 |
| Theme static files | `themes/universal-theme/static-files/1024*.css` | dois arquivos de 65 bytes, só cabeçalho; irrelevantes |

### 2.2 Ordem no `<head>` (page template `corlix-standard-page`, default do tema)

```
#APEX_CSS# → #THEME_CSS# (Core) → #TEMPLATE_CSS# → #THEME_STYLE_CSS# (Redwood Light)
→ #APPLICATION_CSS# (corlix-tema → custom) → #PAGE_CSS# (File URLs da página) → #GENERATED_CSS#
```

1. `corlix-tema` vem depois do Redwood → suas variáveis em `:root` vencem as do estilo.
2. `custom` vem depois de `corlix-tema` → lê os tokens e, com a mesma especificidade, vence o tema.
3. O CSS da página (módulo) vem por último → vence o `custom.css` com a mesma especificidade. É assim que o `home.css` complementa a §12 do `custom.css` (comentário no topo do `home.css`).
4. Body: `<body class="t-PageBody t-PageBody--hideLeft t-PageBody--hideActions no-anim t-PageTemplate--standard #PAGE_CSS_CLASSES#">`, onde `#PAGE_CSS_CLASSES#` recebe *Page › Appearance › CSS Classes*. JS on load: `apex.theme42.initializePage.noSideCol();`.

Atenção: várias páginas ainda usam `@/standard` e não `Corlix - Standard Page` ([11](./11-padroes-de-paginas.md) §6); a ordem de CSS é a mesma do UT.

### 2.3 `#MIN#`

O APEX troca `#MIN#` por `.min` fora do modo debug e por vazio em debug. Usuário normal recebe o `.min.css`; com debug, o `.css`. **Se o par estiver fora de sincronia, a tela muda entre debug e não-debug.** Arquivo referenciado **sem** `#MIN#` (hoje a p30) sempre recebe o `.css`, e o `.min.css` publicado fica sem uso.

---

## 3. Mapa de arquivos CSS (publicado em 13/11/2026)

Sincronia conferida comparando o conteúdo **normalizado** (sem comentários e sem espaços). "Módulo × publicado" compara o `.css` em `modulos/` com o publicado.

| Arquivo publicado (`static-files/`) | Linhas | O que estiliza | Prefixo de classe | Carregado por | `.min` × `.css` publicado | Fonte no módulo × publicado |
|---|---|---|---|---|---|---|
| `corlix-tema.css` | 783 | Tokens `--cx-*`, variáveis do UT, ajustes de componente nativo, `cx-badge`/`cx-etiqueta`, `@font-face` Figtree e Corlix Lucide, mapa `fa-*` → Lucide | `cx-badge`, `cx-etiqueta` | **todas** (`application.apx`) | em sincronia | não há cópia em `modulos/` (fonte = publicado; guias em `modulos/tema/`) |
| `custom.css` | 1984 | Ajustes globais, header (p0), menu do usuário, legado da Home antiga (§3–§10), classes de layout `cx-*` (§11), Home (§12), Busca (§13), formulário e cabeçalho de página (§14), lista com IR (§15), form em modal (§16) | `corlix-header__`, `cx-menu-usuario`, `cx-*` de layout, legado `card-*`/`figma-*`/`cmt-*`/`log-*` | **todas** (`application.apx`) | em sincronia | idem |
| `modulos/home/home.css` | 994 | Home: hero com "Ponto de hoje", carrossel de comunicados, indicadores, pendências, gestor, feedbacks, pesquisa, eventos, celebrações, diálogo "Dar feedback" | `cx-home-*`, `cx-carrossel__*` (setas e pontos do carrossel) | p1 (`#APP_FILES#modulos/home/home#MIN#.css`) | em sincronia | igual |
| `modulos/comunicados/comunicado.css` | 226 | Diálogo "Novo comunicado": rádio segmentado, select com chevron Lucide, `*` nos obrigatórios, dropzone, "Fixar no topo" | `cx-comunicado`, `cx-comunicado__*` | p17 | em sincronia | igual |
| `modulos/colaboradores/colaboradores.css` | 247 | Lista de colaboradores (Faceted Search + Classic Report), pessoa com avatar, barra de contagem | `cx-colab-*`, `cx-colaboradores-pagina`, ajustes de `.cx-relatorio` | p12 | em sincronia | `.css` igual; o `modulos/colaboradores/colaboradores.min.css` tem as **mesmas regras em outra ordem** (o publicado segue a ordem do `.css`) |
| `modulos/suporte-ti/suporte.css` | 756 | Suporte TI (HTML do `pkg_suporte_ui`) | `cx-sup-*` | p34, p36, p37, p39 | em sincronia | igual |
| `ponto-eletronico/ponto.css` | 614 | Ponto eletrônico (HTML do `pkg_ponto_ui`) | `cx-ponto-*` | p30 (`#APP_FILES#ponto-eletronico/ponto.css`, **sem `#MIN#`**) | em sincronia, mas o `.min` não é usado | igual |
| `holerite.css` | 707 | Holerite (HTML do `pkg_holerite_ui`), inclusive impressão | `cx-hol-*` (+ ajustes de `.cx-cabecalho-pagina` no `@media print`) | p9 | em sincronia | **diferente**: o módulo tem o PDF "Aviso de crédito" (`.cx-hol-aviso*`, proposto em 10/11/2026, não aplicado); o publicado tem a impressão anterior (`.cx-hol-impressao-nome` etc.) |
| `Meu Perfil.css` (nome com espaço) | 633 | Meu perfil e drawer da foto (`dialog.org-drawer`) | `perfil-*` | p2 (`#APP_FILES#Meu Perfil#MIN#.css`) | em sincronia | **diferente**: o módulo tem 3 regras a mais (`.perfil-btn:disabled`, `.perfil-modal-status`, `.is-erro`), do envio da foto ao bucket (planejado) |
| `organograma.css` | 925 | Organograma em níveis + drawer | `org-*` (tokens `--org-*` em `.org-drawer`) | p3 | em sincronia | **diferente**: o publicado tem `#P3_BUSCA_CONTAINER { max-width: 300px; margin-left: auto }`, que não está em `modulos/organograma/organograma.css` |
| `historico-carreira.css` | 981 | Histórico de carreira, formações e a barra do RH | `hc-*` (tokens `--hc-*` em `.hc-barra-rh`/`.hc`) | p13, p19, p20 | em sincronia | igual (o módulo não tem `.min.css`) |

**CSS de módulo ainda não publicado** (existe só em `modulos/`): `modulos/dashboard-rh/dashboard-rh.css`/`.min.css` (redesign da p20, que hoje carrega `historico-carreira#MIN#.css`) e `modulos/login/login.css`/`.min.css` (redesign da p9999). Os pares `.css`/`.min.css` de ambos estão em sincronia.

**Páginas sem CSS próprio**: as demais (p0, p4, p5–p8, p11, p14–p16, p18, p21–p23, p26, p27, p29, p31–p33, p35, p38, p40–p44, p9999) usam só o global. p14, p15, p16, p29, p32, p37 e p38 dependem de classes do `custom.css` (`cx-form-secao`, `cx-cabecalho-pagina`, `cx-relatorio`, `cx-form-modal`, `cx-busca-*`).

**Outros arquivos publicados**: `figtree-latin.woff2`, `figtree-latin-ext.woff2`, `lucide.woff2` (lidos pelo `corlix-tema.css`), `home-hero.jpg` (lido pela §12 do `custom.css` e pelo `home.css` em `url("../../home-hero.jpg")`), `default-user.jpeg`, `icons/app-icon-*.png`, e cinco imagens `Comunicado · *.png` (dados de demonstração dos comunicados; três delas aparecem como *untracked* no git local em 13/11/2026).

---

## 4. Design tokens `--cx-*`

### 4.1 Tokens do tema (fonte da verdade: `:root` de `corlix-tema.css`)

Os tokens apontam para a paleta do Redwood (`--rw-palette-*`) com fallback hex; o valor efetivo é o fallback se a variável `--rw-*` não existir. **Não há valor escuro** para nenhum token. "Arquivos" = CSS publicados (sem `.min`) que usam o token.

| Token | Definição | Valor claro | Para que serve | Arquivos que usam |
|---|---|---|---|---|
| `--cx-primaria` | `var(--rw-palette-sky-120, #00688C)` | `#00688C` azul-petróleo | links, foco, abas, item atual do menu, botão terciário, ícones | todos |
| `--cx-primaria-hover` | `var(--rw-palette-sky-130, #025E7E)` | `#025E7E` | hover de link/terciário | tema, custom, ponto, suporte |
| `--cx-primaria-suave` | `var(--rw-palette-sky-30, #E4F1F7)` | `#E4F1F7` | avatar de iniciais, badge info, fundo de ícone | quase todos |
| `--cx-primaria-texto` | `#1D5F84` | `#1D5F84` | texto sobre fundo suave (avisos, pílulas, badge info) | tema, perfil, hc, holerite, home, ponto, suporte |
| `--cx-fundo` | `var(--rw-palette-neutral-30, #F1EFED)` | `#F1EFED` | fundo das páginas | tema, hc |
| `--cx-superficie` | `var(--rw-palette-neutral-0, #FFFFFF)` | `#FFFFFF` | regiões, cards, header, menu lateral | todos |
| `--cx-superficie-2` | `var(--rw-palette-neutral-10, #FBF9F8)` | `#FBF9F8` | rodapés de diálogo, cabeçalho de tabela | vários |
| `--cx-tag` | `var(--rw-palette-neutral-20, #F5F4F2)` | `#F5F4F2` | etiquetas, busca do header, dropzone | todos |
| `--cx-borda` | `var(--rw-palette-neutral-40, #E4E1DD)` | `#E4E1DD` | bordas e divisórias | quase todos |
| `--cx-borda-campo` | `#8A857F` | `#8A857F` | borda forte de campo | comunicado, hc, holerite, ponto, suporte |
| `--cx-selecionado` | `#EDEBE8` | `#EDEBE8` | item atual do menu, hover do segmentado | tema, comunicado, holerite |
| `--cx-texto` | `var(--rw-palette-neutral-190, #161513)` | `#161513` | texto principal | todos |
| `--cx-texto-2` | `#57534F` | `#57534F` | texto secundário, rótulos | todos |
| `--cx-texto-3` | `#6B6661` | `#6B6661` | metadados, placeholders | perfil, custom, hc, org, suporte |
| `--cx-btn` | `#EAE7E3` | `#EAE7E3` | botão secundário | tema, perfil, custom, hc, org, ponto |
| `--cx-btn-hover` | `#DEDAD5` | `#DEDAD5` | hover do secundário | tema, perfil, hc, org |
| `--cx-escuro` | `var(--rw-palette-neutral-170, #312D2A)` | `#312D2A` | botão primário escuro (o Hot do Redwood), opção marcada do segmentado | perfil, comunicado, holerite, home, org, ponto, suporte |
| `--cx-sucesso` | `#2F7D4F` | `#2F7D4F` | sucesso | holerite, home, org, ponto, suporte |
| `--cx-alerta` | `#B3261E` | `#B3261E` | erro, `*` de obrigatório | comunicado, custom, hc, home, ponto, suporte |
| `--cx-raio` | `.375rem` | 6px | campos, menus, chips, botões | vários |
| `--cx-raio-card` | `.5rem` | 8px | regiões e cards | vários |
| `--cx-fonte` | `var(--a-base-font-family)` | Figtree | referência | **nenhum** (definido e sem uso; o CSS usa `font-family: inherit`) |

Não há tokens `--cx-*` de espaçamento nem de sombra: espaçamentos ficam nas variáveis do UT (§6) e a política é **sem sombra**.

### 4.2 Tokens locais dos módulos (não existem no tema)

Nenhum CSS usa um `--cx-*` que não esteja definido em algum lugar. Mas os tokens abaixo são **locais**: só existem quando o CSS do módulo carrega.

| Token(s) | Definidos em | Escopo | Valores |
|---|---|---|---|
| `--cx-home-atencao`, `-atencao-fundo`, `-erro-fundo`, `-sucesso-fundo` | `home.css` | `.t-Body` | `#8A4B00`, `#FDF0DC`, `#FCE8E6`, `#E6F2EA` |
| `--cx-ponto-atencao`, `-atencao-fundo`, `-erro-fundo`, `-sucesso-fundo` | `ponto.css` | `:root` | os mesmos quatro |
| `--cx-sup-atencao`, `-atencao-fundo`, `-erro-fundo`, `-sucesso-fundo` | `suporte.css` | `:root` | os mesmos quatro |
| `--cx-hol-barra-descontos`, `--cx-hol-sucesso-fundo` | `holerite.css` | `:root` | `#7FB2C7`, `#E6F2EA` |
| `--cx-dash-serie-1/-2`, `--cx-dash-urgente(-fundo)`, `--cx-dash-atencao(-fundo)` | `modulos/dashboard-rh/dashboard-rh.css` (não publicado) | `:root` | `#2B78D4`, `#E8683A`, `var(--cx-alerta)`, `#FCE8E6`, `#8A4B00`, `#FDF0DC` |
| `--org-*` (17) | `organograma.css` | `.org-drawer` (e `.org`) | `var(--cx-*, fallback)` + `--org-borda-forte #C9C4BE`, `--org-linha #D2CDC7`, `--org-escuro-hover #1F1C1A`, `--org-gap 32px` |
| `--hc-*` (20) | `historico-carreira.css` | `.hc-barra-rh` / `.hc` | `var(--cx-*, fallback)` + `--hc-atencao #8A5A00`, `--hc-atencao-suave #FFF4DB`, `--hc-alerta-suave #FCEDEC`, `--hc-aviso-fundo #E6F1F7` |
| `--ch-*` (17) | CSS Inline da p4 (Chat) | `:root` da página | mapeiam para `--cx-*`; `--ch-online/ausente/offline` e medidas próprias |

Observações: as cores de status atenção/erro/sucesso se repetem em 4 arquivos com prefixos diferentes (candidatas a token do tema; decisão do time). `--hc-atencao` (`#8A5A00`) difere dos demais (`#8A4B00`). Os fallbacks de `--cx-primaria-suave` em `organograma.css` e `historico-carreira.css` são `#E6F2F6`, e não o `#E4F1F7` do tema (só importa se o tema não carregar).

---

## 5. Tipografia e ícones

### 5.1 Figtree

Dois `@font-face` "Figtree" no fim do `corlix-tema.css` (`figtree-latin.woff2` e `figtree-latin-ext.woff2`, peso `300 900`, `font-display: swap`, separados por `unicode-range`; origem `@fontsource-variable/figtree@5.1.1`, SIL OFL 1.1, conforme `modulos/tema/Etapas-fonte-e-icones.md`). A fonte entra trocando `--a-base-font-family` num segundo `:root`:

```css
--a-base-font-family: "Figtree", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", sans-serif;
```

Os `url()` não têm pasta: as fontes ficam na raiz dos Static Application Files, ao lado do `corlix-tema.css`. Nos módulos, use `font-family: inherit` e não fixe fonte.

Tipografia efetiva (prancha + CSS): título de página 26px/32px bold (`--ut-breadcrumb-title-*`); cabeçalhos de página em região (`.cx-cabecalho-pagina__titulo`) 32px/700; título de região 15px/20px bold, sem caixa alta; nome do app 18px bold; menu 14px/20px (itens de 40px); botões peso 600; badge/etiqueta 12px/600.

### 5.2 Fonte de ícones "Corlix Lucide" (`lucide.woff2`)

Declaração (fim do `corlix-tema.css`):

```css
@font-face {
    font-family: "Corlix Lucide";
    font-style: normal; font-weight: normal; font-display: block;
    src: url("lucide.woff2") format("woff2");
}
```

`lucide.woff2` é a fonte do `lucide-static@0.460.0` (ISC) **reduzida** com `pyftsubset` aos 69 glifos que o tema usa (passo a passo em `modulos/tema/Etapas-fonte-e-icones.md`). Glifo fora desses 69 não existe na fonte publicada.

**Como se usa:**

1. **Classes Font APEX (`fa-*`)**: o app continua usando `fa-home`, `fa-users` etc. no Builder (ícone de botão, de lista, de região, HTML). O `corlix-tema.css` aplica `font-family: "Corlix Lucide" !important` no `::before` das 84 classes mapeadas e troca o `content`. O seletor tem o prefixo `.apex-icons-fontapex` porque o Font APEX aplica a fonte com `!important` (`.fa.fa-lg::before`) e é preciso vencer em especificidade. Classe fora do mapa continua sendo desenhada pelo Font APEX.
2. **`content` direto num pseudo-elemento**, para ícones que não são classe `fa-*`:
   ```css
   .x::after { content: "\e071"; font-family: "Corlix Lucide"; }   /* chevron-down */
   ```
   Uso atual: só `comunicado.css` (`\e071` chevron-down na seta do select; `\e070` check na opção marcada do rádio segmentado).

**Mapa `fa-*` → glifo** (do `corlix-tema.css`; nome conferido no `lucide.css` 0.460.0):

| Código | Lucide | Classes `fa-*` |
|---|---|---|
| `\e0f8` | house | `fa-home` |
| `\e235` | megaphone | `fa-bullhorn` |
| `\e412` | messages-square | `fa-comments-o`, `fa-comments` |
| `\e11a` | message-circle | `fa-comment-o`, `fa-comment` |
| `\e57a` | message-square-text | `fa-commenting-o` |
| `\e1a4` | users | `fa-users` |
| `\e46d` | user-round | `fa-user`, `fa-user-o` |
| `\e472` | user-round-x | `fa-user-times` |
| `\e1a2` | user-plus | `fa-user-plus` |
| `\e066` | briefcase | `fa-briefcase` |
| `\e1ff` | shield-check | `fa-shield` |
| `\e155` | search | `fa-search` |
| `\e05d` | bell | `fa-bell-o`, `fa-bell` |
| `\e112` | log-out | `fa-sign-out` |
| `\e111` | log-in | `fa-sign-in` |
| `\e141` | plus | `fa-plus` |
| `\e1f9` | pencil | `fa-edit`, `fa-pencil` |
| `\e0fe` | info | `fa-info-circle` |
| `\e073` / `\e071` / `\e072` / `\e074` | chevron-right / -down / -left / -up | `fa-chevron-right` / `-down` / `-left` / `-up` |
| `\e04d` | arrow-right | `fa-arrow-right` |
| `\e07f` | circle-arrow-up | `fa-arrow-circle-up` |
| `\e348` | cake | `fa-birthday-cake` |
| `\e0d0` | file-text | `fa-file-text-o`, `fa-file-text` |
| `\e113` | mail | `fa-envelope-o`, `fa-envelope` |
| `\e250` | clock-3 | `fa-clock-o` |
| `\e2a3` | chart-column | `fa-bar-chart` |
| `\e2a1` | undo-2 | `fa-undo` |
| `\e149` | refresh-cw | `fa-repeat`, `fa-refresh` |
| `\e129` | network | `fa-sitemap` |
| `\e156` | send | `fa-paper-plane` |
| `\e056` | banknote | `fa-money` |
| `\e5db` | briefcase-medical | `fa-medkit` |
| `\e103` | languages | `fa-language` |
| `\e4a8` | key-round | `fa-key` |
| `\e1f5` | history | `fa-history` |
| `\e5c2` | headset | `fa-headphones` |
| `\e234` | graduation-cap | `fa-graduation-cap` |
| `\e24a` | arrow-left-right | `fa-exchange` |
| `\e053` | award | `fa-certificate` |
| `\e290` | building-2 | `fa-building-o`, `fa-building` |
| `\e063` | book-open | `fa-book` |
| `\e158` | settings | `fa-gear`, `fa-cog` |
| `\e067` | calendar | `fa-calendar`, `fa-calendar-o` |
| `\e10f` | lock | `fa-lock` |
| `\e070` | check | `fa-check` |
| `\e226` | circle-check | `fa-check-circle` |
| `\e1b2` | x | `fa-times`, `fa-close` |
| `\e119` | menu | `fa-bars` |
| `\e18e` | trash-2 | `fa-trash-o`, `fa-trash` |
| `\e0b6` / `\e19e` | download / upload | `fa-download` / `fa-upload` |
| `\e0d5` | filter | `fa-filter` |
| `\e0be` | eye | `fa-eye` |
| `\e068` | camera | `fa-camera` |
| `\e193` | triangle-alert | `fa-exclamation-triangle`, `fa-warning` |
| `\e07b` | circle-alert | `fa-exclamation-circle` |
| `\e137` | phone | `fa-phone` |
| `\e115` | map-pin | `fa-map-marker` |
| `\e0eb` | globe | `fa-globe` |
| `\e61c` | id-card | `fa-id-card-o` |
| `\e145` | printer | `fa-print` |
| `\e1c2` | lightbulb | `fa-lightbulb-o` |
| `\e184` | target | `fa-bullseye` |
| `\e0f5` | heart | `fa-heart` |
| `\e108` | link | `fa-link` |
| `\e131` | paperclip | `fa-paperclip` |

**Font APEX onde ainda aparece:** todas as classes `fa-*` encontradas em `corlixhub/pages/*.apx`, `corlixhub/shared-components/*.apx` e nos packages/JS de `modulos/` estão no mapa (conferido em 13/11/2026), então hoje **nenhum ícone visível depende do desenho Font APEX**. Exemplos de uso: menu lateral (`lists.apx`: Início `fa-home`, Comunicados `fa-bullhorn`, Chat `fa-comments-o`, Pessoas `fa-users`, Minha carreira `fa-briefcase`, Ponto eletrônico `fa-clock-o`, Administração `fa-shield`); header (`fa-bell-o`, `fa-chevron-down`, `fa-user-o`, `fa-sign-out`); `pkg_home_ui` (`fa-arrow-right`, `fa-birthday-cake`, `fa-calendar-o`, `fa-check-circle`, `fa-chevron-right`, `fa-comments-o`, `fa-file-text-o`, `fa-headphones`, `fa-sitemap`, `fa-user-times`); `pkg_busca_ui` (`fa-bullhorn`, `fa-comment-o`, `fa-search`, `fa-users`); `pkg_colaboradores_ui` (`fa-chevron-right`, `fa-plus`). Para incluir um ícone novo: classe na lista do `font-family`, regra `content` e nova fonte com `pyftsubset` (guia `Etapas-fonte-e-icones.md`).

### 5.3 SVG Lucide em linha (packages `pkg_*_ui`)

HTML gerado por package usa SVG em linha (padrão do [11](./11-padroes-de-paginas.md), "Ícones"): função `icone(p_nome)` que devolve `<svg class="cx-<mod>-icone" width=".." viewBox="0 0 24 24" aria-hidden="true" focusable="false">` com os paths do Lucide e `stroke="currentColor"` (a cor vem do CSS). Não depende da fonte.

| Package | Classe do `<svg>` | Nomes aceitos por `icone()` |
|---|---|---|
| `modulos/home/pkg_home_ui.pkb` | `cx-home-icone` | clock, log-in, log-out, coffee, check, hourglass, calendar-x, assinar, wallet, palm, target, eye, calendar, calendar-clock, message, feedback, party, users |
| `modulos/ponto-eletronico/04_pkg_ponto_ui.pkb` | `cx-ponto-icone` | log-in, log-out, coffee, check, map-pin, timer, arrow, download, history, hourglass, alerta, assinar, cadeado |
| `modulos/holerite/02_pkg_holerite_ui.pkb` | `cx-hol-icone` | olho-fechado, olho, download, banco, mais, menos, info, mensagem, cadeado |
| `modulos/suporte-ti/04_pkg_suporte_ui.pkb` | `cx-sup-icone` | key, mail, laptop, wifi, janela, printer, busca, chevron, seta, voltar, mais, alerta, fechar, artigo, responder, check, pessoa, calendario, chat, telefone, relogio, anexo |
| `modulos/dashboard-rh/pkg_dashboard_rh_ui.pkb` (não aplicado) | `cx-dash-icone` | trending-up, user-plus, user-minus, chevron-right, arrow-right, info |
| `modulos/login/02_pkg_login_ui.pkb` (não aplicado) | `cx-login-icone` | info |

Escolha: componente nativo ou botão com classe do tema → `fa-*` (§5.2); HTML de package → `icone()`. Não misture os dois no mesmo componente sem necessidade.

---

## 6. Mapeamento para variáveis do Universal Theme (`corlix-tema.css`)

Todas em `:root`. Nomes do UT 26.1.5; se uma atualização renomear, perde-se só aquele ajuste.

| Grupo | Variável UT | Valor Corlix |
|---|---|---|
| Tipografia | `--ut-breadcrumb-title-font-size` / `-line-height` | `1.625rem` / `2rem` |
| Primária | `--ut-palette-primary` / `-contrast` / `-shade` | `--cx-primaria` / `#FFFFFF` / `var(--rw-palette-sky-10, #F6FAFC)` |
| | `--ut-link-text-color` | `--cx-primaria` |
| | `--ut-component-icon-background-color` / `--ut-component-icon-color` | `--cx-primaria-suave` / `--cx-primaria` |
| | `--u-color-5` / `--u-color-5-contrast` | `--cx-primaria` / `#FFFFFF` |
| Foco | `--ut-focus-outline` / `-color` / `-offset` | `2px solid var(--cx-primaria)` / `--cx-primaria` / `2px` |
| Página | `--ut-body-background-color` / `--ut-body-text-color` | `--cx-fundo` / `--cx-texto` |
| | `--ut-body-content-padding-x` / `-y` | `2rem` / `2rem` |
| Header | `--ut-header-background-color` / `-text-color` / `-border-color` | `--cx-superficie` / `--cx-texto` / `--cx-borda` |
| | `--ut-header-height` / `--ut-header-padding-x` | `3.5rem` / `.5rem` |
| Menu lateral | `--ut-nav-width` | `15rem` |
| | `--ut-body-nav-background-color` / `-border-color` / `-text-color` | `--cx-superficie` / `--cx-borda` / `--cx-texto` |
| | `--a-treeview-node-font-size` / `-line-height` / `-padding-y` | `.875rem` / `1.25rem` / `.625rem` |
| | `--ut-treeview-toplevel-node-font-size` / `--a-treeview-node-font-weight` | `.875rem` / `400` (o Redwood põe `1rem` e `600`) |
| | `--a-treeview-node-text-color` / `-hover-background-color` | `--cx-texto` / `rgba(22,21,19,.04)` |
| | `--a-treeview-node-selected-background-color` / `-selected-text-color` / `--ut-treeview-node-current-text-color` | `--cx-selecionado` / `--cx-texto` / `--cx-texto` |
| Título da página | `--ut-body-title-background-color` / `-border-color` / `-border-width` / `-box-shadow` | `--cx-superficie` / `--cx-borda` / `1px` / `none` |
| Componentes | `--ut-component-background-color` / `-border-color` / `-border-radius` | `--cx-superficie` / `--cx-borda` / `--cx-raio` |
| | `--ut-component-text-title-color` / `-text-muted-color` | `--cx-texto` / `--cx-texto-2` |
| Regiões | `--ut-region-border-color` / `-border-radius` / `-box-shadow` | `--cx-borda` / `--cx-raio-card` / `none` |
| | `--ut-region-header-border-color` / `-font-size` / `-line-height` | `--cx-borda` / `.9375rem` / `1.25rem` |
| | `--ut-region-header-padding-x/-y`, `--ut-region-body-padding-x/-y` | `1.25rem` / `1rem` |
| Cards | `--a-cv-shadow` / `--a-cv-border-radius` / `--ut-cardlist-box-shadow` | `none` / `--cx-raio-card` / `none` |
| Botões | `--a-button-background-color` / `-hover-` / `-active-` | `--cx-btn` / `--cx-btn-hover` / `#D2CDC7` |
| | `--a-button-text-color` / `--a-button-font-weight` | `--cx-texto` / `600` |
| Campos | `--a-field-input-focus-border-color` | `--cx-primaria` |
| | `--ut-field-label-text-color` / `--ut-field-fl-label-text-color` | `--cx-texto-2` |
| Abas | `--ut-tabs-item-active-highlight-color` / `--ut-navtabs-item-active-highlight-color` | `--cx-primaria` |
| Badge UT | `--ut-badge-border-radius` / `-font-size` / `-font-weight` / `-padding-x` | `999px` / `.75rem` / `600` / `.5rem` |
| Menus/chips | `--a-menu-border-radius` / `--a-chip-border-radius` | `--cx-raio` |

O botão **Hot** não é redefinido: o escuro `#312D2A` já é o do Redwood.

### 6.1 Ajustes de componente em `corlix-tema.css` (o que variável não alcança)

| Seletor | Efeito |
|---|---|
| `.t-Header-logo-link, .t-Header-logo-label` | nome do app 18px, 700, `--cx-texto` |
| `.t-TreeNav .a-TreeView-node.is-current > .a-TreeView-row`, `.is-current--top > …`, `.a-TreeView-row.is-selected` | fundo `--cx-selecionado` + `box-shadow: inset 3px 0 0 var(--cx-primaria)` (barra azul) |
| `.t-TreeNav .is-current, .is-current--top` | `--a-treeview-node-font-weight: 700` |
| `.t-TreeNav .a-TreeView-node .a-Icon/.fa` | ícones do menu em `--cx-texto-2` |
| `.t-Body-title` / `::after` | fundo e borda redefinidos aqui porque o Redwood os redefine em `body:not([class*="rw-pillar--"])`, que vence o `:root`; `::after` com `content: none` tira a faixa de textura |
| `.t-Body-title .t-BreadcrumbRegion` | `--ut-breadcrumb-padding-x: 2rem; -y: 1.5rem` |
| `.t-BreadcrumbRegion-titleText`, `.t-Region-title` | negrito; região sem caixa alta |
| `.t-Button--link`, `.t-Button--noUI` (exceto `--noLabel`, `--header`, `--closeAlert`) | texto na primária: botão terciário azul; botões só de ícone e do header ficam neutros |
| `.a-CardView-initials, .t-Avatar--initials` | fundo `--cx-primaria-suave`, texto `--cx-primaria` |

---

## 7. Catálogo de componentes e classes reutilizáveis

### 7.1 Design system global (`corlix-tema.css`)

**`.cx-badge` + variante**: pílula de status, sempre com texto; ponto colorido no `::before` em `currentColor`. 999px, 12px/16px, 600, padding `.125rem .5rem`.

| Variante | Fundo | Texto |
|---|---|---|
| (base) | `--cx-tag` | `--cx-texto-2` |
| `--sucesso` | `--rw-palette-green-30 #E4F5D3` | `--rw-palette-green-140 #355617` |
| `--neutro` | `--rw-palette-neutral-30 #F1EFED` | `--cx-texto-2` |
| `--erro` | `--rw-palette-red-30 #FFEBE8` | `--rw-palette-red-140 #8F2719` |
| `--aviso` | `--rw-palette-orange-30 #FCEDDC` | `--rw-palette-orange-140 #724108` |
| `--info` | `--cx-primaria-suave` | `--cx-primaria-texto` |

**`.cx-etiqueta`**: etiqueta neutra (departamento, categoria); raio 4px, fundo `--cx-tag`, borda interna 1px `--cx-borda`, 12px/600. Cor não pode sugerir status.

Uso atual: `cx-badge` em p1 (`pkg_home_ui`), p12 (`pkg_colaboradores_ui`) e p15 (situação da empresa); `cx-etiqueta` em p1 e na busca (`pkg_busca_ui`).

### 7.2 Componentes do `custom.css` (globais, servem a qualquer página)

| Classe | Seção | O que é | Onde é usado hoje |
|---|---|---|---|
| `.corlix-header__search` (`__search-icon`, `__search-input`), `__actions`, `__icon-btn`, `__divisor`, `__user` (`__avatar`, `__user-name`, `__user-seta`) | §2 | Header (slots *After Logo* e *After Navigation Bar*) | p0; campo de busca vem do `pkg_busca_ui.render_campo` |
| `.cx-menu-usuario` (`__cabecalho`, `__nome`, `__info`, `__login`, `__separador`, `__item`) | §2 | Menu do usuário com atributo HTML `popover` (sem JS) e "Sair" | p0 |
| `.cx-avatar-iniciais` | §11 | Iniciais quando não há foto (vai com a classe de tamanho, ex. `corlix-header__avatar`) | p0 |
| `.cx-pessoa` (`__foto`, `__nome`, `__detalhe`), `.cx-acoes-card` | §11 | Foto + nome + detalhe; botões lado a lado | `pkg_home_ui`, `pkg_busca_ui` |
| `.cx-titulo`, `.cx-titulo-secao` | §11 | Título de página antigo; título de seção de formulário | p16 |
| `.cx-avatar` (`--vazio`) | §12 | Avatar 40px com iniciais e `<img>` por cima | `pkg_home_ui`, `pkg_busca_ui`, p12 (com `cx-avatar--situacao-*` do `colaboradores.css`), `pkg_dashboard_rh_ui` |
| `.cx-home-card` (`__subtitulo`, `__rodape`), `.cx-home-hero`, `.cx-home-atalho(s)`, `.cx-home-gestor`, `.cx-home-lista`, `.cx-home-vazio`, `.cx-home-comunicados` | §12 | Home (base); o `home.css` da p1 complementa | p1; `.cx-home-vazio` também na busca |
| `.cx-busca-cabecalho`, `.cx-busca-card`, `.cx-busca-lista`, `.cx-busca__link`, `.cx-busca-comunicado`, `.cx-busca-ajuda` | §13 | Resultados da busca | p29 (`pkg_busca_ui`) |
| `.cx-cabecalho-pagina` (`__trilha`, `__texto`, `__titulo`, `__descricao`, `__acoes`) e `--acoes` | §14/§15 | **Cabeçalho de página padrão** na Breadcrumb Bar | p15, p32, p37, p38 e packages de colaboradores, ponto, suporte e holerite |
| `.cx-form-secao` (`__info`, `__titulo`, `__descricao`), `.cx-form-rodape` (`__nota`) | §14 | Formulário em seções 1/3 + 2/3 e rodapé fixo | p14 |
| `.cx-relatorio` (`__nota`) | §15 | Card para Interactive Report (`.t-IRR-region`); o `colaboradores.css` estende para Classic Report | p12, p15, p32, p38 |
| `.cx-form-modal`, `.cx-form-modal-rodape` (`__nota`) | §16 | Formulário em modal e rodapé do diálogo (via `.t-Dialog-footer:has(...)`) | p16 |

### 7.3 Componentes por módulo (prefixo próprio; reutilizar copiando o padrão, não a classe)

| Componente | Classes | Arquivo |
|---|---|---|
| Selo de status | `.cx-ponto-selo`, `.cx-sup-selo`, `.cx-hol-selo`, `.cx-home-selo` (`--sucesso`, `--neutro`, `--info`, `--erro`, `--atencao`) | `ponto.css`, `suporte.css`, `holerite.css`, `home.css` |
| Botão | `.cx-hol-botao` (`--escuro`, `--largo`), `.cx-ponto-botao`, `.cx-sup-botao` (`--primario`, `--largo`), `.perfil-btn` (`--primario`), `.org-btn` (`--primario`, `--auto`), `.hc-btn` (`--bloco`) | holerite, ponto, suporte, Meu Perfil, organograma, histórico |
| Ícone SVG | `.cx-home-icone`, `.cx-ponto-icone`, `.cx-hol-icone`, `.cx-sup-icone` | idem (§5.3) |
| Estado vazio | `.cx-home-vazio` (custom §12), `.cx-ponto-vazio`, `.cx-sup-vazio`, `.cx-hol-vazio`, `.hc-vazio`, `.org-vazio` | idem |
| Carrossel | `.cx-home-carrossel` (classe da região Cards; ligada pelo JS da p1) | `home.css` |
| Segmentado (rádio) | `.cx-comunicado__publico` | `comunicado.css` |
| Drawer | `dialog.org-drawer` (`__painel`, `__estado`) | `organograma.css` e `Meu Perfil.css` |

Para página nova: reaproveite `cx-badge`, `cx-etiqueta`, `cx-cabecalho-pagina`, `cx-relatorio`, `cx-avatar`/`cx-pessoa` e, para o resto, crie classes com o prefixo do módulo no CSS do módulo ([11](./11-padroes-de-paginas.md) C4).

### 7.4 Legado no `custom.css` (sem uso nas páginas e packages em 13/11/2026)

Conferido por busca em `corlixhub/pages/*.apx` e nos `.pkb`/`.js` de `modulos/`: **nenhum uso** de `card-default`, `card-boas-vindas`, `link-empresa`, `card-comunicados-oficiais`, `lista-de-comunicados`, `titulo-lista-de-comunicados`, `botao-emitir-comunicado`, `imagem-capa-comunicado`, `cmt-*`, `card-meu-gestor`, `links-rapidos-card`, `link-item`, `card-aniversariantes`, `figma-*`, `popup-todos-aniversariantes`, `cx-cabecalho-card`, `cx-descricao` (§3–§11, Home antiga). Remoção é decisão do time. **Continuam ativas e globais** no §3: `.t-Cards { gap: 24px }` e `.a-CardView-item`/`-media img`/`-body`/`-title`/`-subTitle`/`-desc` (raio 14px, sombra, hover que sobe 3px, imagem 260px), além de `.ui-dialog .ui-dialog-titlebar` (§10, todos os diálogos). `log-detalhe`, `log-descricao`, `log-tag` seguem em uso na p7.

---

## 8. Regras de uso do design system no APEX (prancha + README do tema)

| Na prancha | No APEX |
|---|---|
| Botão primário (escuro) | **Hot = Yes**; uma ação primária por tela/contexto |
| Secundário (cinza) | template *Text* (`componentDefaults.button: @/text`) |
| Terciário ("Ver todos →") | *Text with Icon*, `fa-arrow-right`, *Icon Position: Right*, *Style: Remove UI Decoration* |
| Somente ícone | template *Icon* (fica neutro) |
| Excluir | *Template Options › Type: Danger*, sem Hot |
| Campos | **Optional - Floating** / **Required - Floating**; ajuda em *Inline Help Text*; erro *Inline with Field* |
| Badge de status | `cx-badge cx-badge--*` (ou selo do módulo); sempre com texto |
| Etiqueta de departamento | `cx-etiqueta` |
| Feedback | *Success Message* do processo; avisos persistentes em região **Alert** |
| Regiões | template **Standard**, título em frase normal |
| Navegação | Navigation Menu nativo; Administração com Authorization Scheme |

Prancha (`pen_dev/Design System · Redwood Light (CorlixHub).png`, resumo em [07](./07-design-pen-dev.md) §3): botões (primária, secundária, terciária, só ícone, hover, foco com anel azul, desabilitado, carregando), campos (vazio, preenchido, foco, erro, desabilitado, switch, checkbox), status e etiquetas, alertas, navegação lateral (padrão, hover, ativo com barra azul), estados de região e estrutura (header com busca, sino e menu do usuário com Meu perfil e Sair).

---

## 9. Padrões e pegadinhas de CSS aprendidos no projeto

**Onde pôr cada coisa**
1. **Sem CSS Inline e sem `style`**, nem para teste. Estilo vai no CSS do módulo (ou no tema, se for global), publicado pelo Builder com o par `.css`/`.min.css`. Legados que ainda existem: Inline da p4 (Chat) e `style="display:none"` no `<span>` de iniciais da p0; também há `style` em packages (`width:` nas barras do `pkg_holerite_ui`, `--h`/`--y`/`--w` no `pkg_dashboard_rh_ui`, `display:none` no input de arquivo do `pkg_perfil`, `text-align` no `00_pkg_holerite`). Não copie esses casos.
2. **Cor nova ou ajuste global** → token `--cx-*` ou variável UT no `corlix-tema.css`. Nunca no Theme Roller. Em módulo, use `var(--cx-*)` e não fixe hex novo ([11](./11-padroes-de-paginas.md) C2).
3. **CSS de página nova**: `modulos/<modulo>/<arquivo>.css` + `.min.css`, publicados em *Static Application Files* (pasta `modulos/<modulo>/`) e referenciados em *Page › CSS › File URLs* como `#APP_FILES#modulos/<modulo>/<arquivo>#MIN#.css`. Arquivo novo entra também no manifesto `static-files.apx` (o export faz isso). Não mova arquivos que já existem ([11](./11-padroes-de-paginas.md) C3).
4. `url()` dentro do CSS é **relativo ao arquivo CSS**: o `corlix-tema.css` (raiz) usa `url("lucide.woff2")`; o `home.css` (em `modulos/home/`) usa `url("../../home-hero.jpg")`.

**Onde pôr a classe no Builder**
5. **Modal: use *Page › Appearance › CSS Classes* (ou CSS Classes da região), não *Dialog › CSS Classes*.** A classe de *Dialog* fica na moldura do diálogo, na página de trás; o conteúdo roda no iframe do modal e o CSS não alcança os campos (`Etapas-comunicados.md` §4.2). A de *Appearance* vai no `<body>` do iframe (`#PAGE_CSS_CLASSES#`).
6. **Item: *Layout › Column CSS Classes*, não *Advanced › CSS Classes*.** A de *Advanced* vai só no `<input>`; a de *Column* vai na coluna que envolve rótulo, campo e ajuda, que é o que o CSS precisa (`cx-comunicado__publico`, `cx-comunicado__fixar`).
7. Botão: as CSS Classes do botão (no export, `appearance.cssClasses`) ficam no próprio `<button>` (ex.: `cx-home-fb-cancelar` na p1, que é só gancho de JS, sem estilo).
8. Região com *Template Options › Body Padding: No Padding* gera `t-Region--noPadding`; o `cx-home-card` conta com isso.
9. Erro de digitação em CSS Classes não dá erro, só tira o estilo (caso real: `x-home-carrossel` sem o `c`, `Etapas-home.md`). Confira no export.

**Técnicas usadas**
10. **Esconder a coluna de um campo oculto por Dynamic Action**: a DA põe `style="display: none"` no `.t-Form-fieldContainer`; o CSS esconde a coluna e puxa a vizinha:
    ```css
    .cx-comunicado .col:has(> .t-Form-fieldContainer[style*="display: none"]) { display: none; }
    .cx-comunicado .col:has(> .t-Form-fieldContainer[style*="display: none"]) + .col { padding-inline-start: 0; }
    ```
11. **Rádio como botões segmentados só com CSS** (p17; o 26.1.5 não tem *Display as Pill Button* no Radio Group): sobre a marcação `.apex-item-option > input[type=radio] + label`, o input fica visualmente oculto (1px, `opacity: 0`, continua no DOM para teclado e leitor de tela), o `label::before/::after` do UT some, `input:checked + label` ganha `--cx-escuro` e o ✓ via `content: "\e070"` com `font-family: "Corlix Lucide"`, e `input:focus-visible + label` tem contorno 2px na primária.
12. **Select com seta Lucide**: `background-image: none` no `<select>` e `::after` no `.t-Form-itemWrapper` com `content: "\e071"` e `pointer-events: none`.
13. **`*` vermelho no rótulo** dos obrigatórios: esconder `.t-Form-itemRequired` (e `-marker` quando o protótipo pede) e `.is-required … .t-Form-label::after { content: " *"; color: var(--cx-alerta) }` (`custom.css` §14/§16, `comunicado.css`).
14. Switch com "Ativa/Inativa" por `.a-Switch:has(input:checked)::after` (`cx-form-secao`, `cx-form-modal`).
15. Rodapé de diálogo pintado pelo filho: `.t-Dialog-footer:has(.cx-form-modal-rodape)`.
16. **Especificidade contra o legado**: o `home.css` vence a §12 do `custom.css` por vir depois; nos itens da Cards usa `:nth-child(n)` para passar das regras com `:first-child`. Escope regras de Cards numa classe de região (`cx-home-comunicados`) para não brigar com o `.a-CardView-*` global.
17. O Font APEX usa `!important` no `::before`; para trocar o glifo, o prefixo `.apex-icons-fontapex` dá a especificidade necessária. O `.corlix-header__search-icon` precisa do pai na frente pelo mesmo motivo (`.apex-icons-fontapex .fa { position: relative }` do Core).
18. O Redwood redefine fundo/borda do `.t-Body-title` em `body:not([class*="rw-pillar--"])`; por isso o tema repete as variáveis no próprio `.t-Body-title`.
19. Avatar com iniciais: o `cx-avatar` põe a `<img>` por cima das iniciais e a `<img>` some no `onerror` (sem `style`); o padrão antigo (`cx-avatar-iniciais` com `style="display:none"`) só sobrevive no header.

**Minificação e publicação**
20. Todo `.css` tem um `.min.css` irmão, publicado junto. **Não há script de minificação** no repositório; qualquer minificador serve. Os `.min.css` publicados **não têm comentários** (conferido) e a formatação varia (o `corlix-tema.min.css` mantém espaços do `:root`). Compare sempre pelo conteúdo normalizado, não por `diff` de texto.
21. Depois de subir CSS, recarregue com Ctrl/Cmd+Shift+R: o navegador guarda a versão antiga (sintoma frequente nas tabelas "Se não funcionar" dos guias).
22. Ordem das regras também importa no `.min`: o `modulos/colaboradores/colaboradores.min.css` tem as mesmas regras do `.css` em outra ordem; aqui não muda o resultado (especificidades diferentes), mas não é garantido em geral.

**Outras armadilhas**
- **`.a-CardView-*` (§3) e `.ui-dialog-titlebar` (§10) do `custom.css` são globais**: toda região Cards ganha raio 14px, sombra e hover, contra a política "sem sombra".
- **`.t-Footer` está escondido** globalmente (`custom.css` §1): regiões no slot Footer não aparecem.
- O seletor do item atual do menu (`.t-TreeNav .a-TreeView-node.is-current > .a-TreeView-row`) é o mais frágil numa atualização do APEX.
- Não criar `prefers-color-scheme` sem antes definir a paleta escura no tema.

---

## 10. Inconsistências encontradas em 13/11/2026

| # | Onde | O quê |
|---|---|---|
| 1 | p30 | `fileUrls: #APP_FILES#ponto-eletronico/ponto.css` sem `#MIN#`: o `ponto.min.css` publicado nunca é servido. O guia (`Etapas-ponto-eletronico.md`) previa `#APP_FILES#ponto#MIN#.css`. Já listado no [11](./11-padroes-de-paginas.md) §6 |
| 2 | `holerite.css` | Módulo ≠ publicado (PDF "Aviso de crédito" proposto e não aplicado) |
| 3 | `Meu Perfil.css` | Módulo tem 3 regras a mais que o publicado (foto no bucket, planejado) |
| 4 | `organograma.css` | Publicado tem `#P3_BUSCA_CONTAINER {…}` que não está no módulo: a fonte do módulo está atrás da app |
| 5 | `modulos/colaboradores/colaboradores.min.css` | Mesmas regras do `.css`, em outra ordem (o publicado está na ordem certa) |
| 6 | `--cx-fonte` | Definido no tema e sem uso |
| 7 | Tokens locais | `--cx-home-*`, `--cx-ponto-*`, `--cx-sup-*` repetem os mesmos 4 hex; `--hc-atencao` usa `#8A5A00` em vez de `#8A4B00` |
| 8 | Comentários desatualizados nos CSS publicados | `corlix-tema.css`: cita a pasta `figma/` e `#APP_FILES#corlix-tema.css` sem `#MIN#`. `custom.css`: índice sem as §15 e §16; §2 diz "Cole em corlix-header.css"; §12 fala em "página 28" (a Home nova está na p1; não há p28 no backup). `home.css`: cita `#APP_FILES#home#MIN#.css`, mas a p1 usa `modulos/home/home#MIN#.css` |
| 9 | Legado | Classes da Home antiga no `custom.css` sem uso (§7.4) |
| 10 | Não publicados | `dashboard-rh.css` e `login.css` só em `modulos/` (redesigns pendentes) |
| 11 | Doc 11 §6 | Diz que a p12 tem "CSS Inline ainda no export"; no backup 84f8625 a p12 não tem `css.inline` (só `fileUrls`). Corrigir no 11 |
| 12 | Guia de suporte | `Etapas-suporte-ti.md` cita `#APP_FILES#suporte#MIN#.css`; as páginas usam `#APP_FILES#modulos/suporte-ti/suporte#MIN#.css` (o que está no app funciona) |

---

## 11. Histórico

- A versão anterior deste documento descrevia o working tree de 06/10/2026: `organograma.css` e `historico-carreira.css` fora do app, último item do menu como botão "Sair" (o "Sair" foi para o menu do usuário e a regra saiu do `custom.css`), CSS Inline de página como opção aceitável (hoje proibido), Home nova na p28 e status de aplicação do tema por página. Tudo isso foi substituído pelo estado de 13/11/2026 acima; o status por página fica nos guias `modulos/*/Etapas-*.md` e no [README](./README.md).
