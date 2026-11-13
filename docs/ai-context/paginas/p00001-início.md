# Página 1 · Início

> **Estado em 13/11/2026** (backup `84f8625`): implementada, aplicada e testada. O `modulos/home/Etapas-home.md`, "Situação na app", registra o §8 concluído em 13/11/2026 (export 55/55, testes 1 a 8 do 8.11 na app) e o `.apx` de DEV idêntico ao export validado. Faltam três testes aceitos como pendência (9, 6 e 10 do 8.11).

## Resumo

| Atributo | Valor |
|---|---|
| Alias | `INÍCIO` (com acento) |
| Modo | Normal |
| Page template | `@corlix-standard-page` |
| Autorização | nenhuma — qualquer usuário autenticado (os Ajax Callbacks exigem `@colaborador`; o botão "Novo comunicado" exige `@publicador-de-conteudo`) · `argumentsMustHaveChecksum` |
| CSS/JS de arquivo | `#APP_FILES#modulos/home/home#MIN#.css`; o JS está na própria página (o módulo versiona o código em `modulos/home/home-pagina.js`; igualdade com o export não conferida) |
| Módulo/guia | `modulos/home/` (`Etapas-home.md` §6, §7 e §8), com `modulos/home-blocos/`, `modulos/comunicados/` e `modulos/ponto-eletronico/` |
| Protótipo | `pen_dev/Início.png` (`07-design-pen-dev.md` §4.1) |

Home da intranet. Hero com saudação, atalhos e "Ponto de hoje"; faixa de indicadores; carrossel de comunicados; pendências; feedbacks; coluna lateral com gestor, pesquisa de clima, eventos e celebrações do mês.

## Estrutura

```
Page 1: Início
├── Body
│   ├── home_hero "Início" (10 · Dynamic Content · @/blank-with-attributes · DOM id home_hero)
│   │     return pkg_home_ui.render_hero;
│   ├── indicadores "Indicadores" (15 · Dynamic Content · @/blank-with-attributes · DOM id home_indicadores)
│   │     return pkg_home_ui.render_indicadores;
│   ├── coluna-principal (20 · Static Content · @/blank-with-attributes · span 8)
│   │   ├── home_comunicados "Comunicados" (10 · Cards horizontal · @/standard noPadding
│   │   │   │   · classes cx-home-card cx-home-comunicados cx-home-carrossel)
│   │   │   │   título com &P1_NAO_LIDOS.; SQL em comunicado + departamento + categoria_comunicado
│   │   │   │   + colaborador (não lido via comunicado_leitura); where id_empresa = :G_ID_EMPRESA;
│   │   │   │   fixados primeiro (fl_fixado), 5 linhas; mídia BLOB IMAGEM/MIME_TYPE
│   │   │   ├── ação "Ler comunicado" (botão do card) → página 11
│   │   │   ├── botão VER_TODOS "Ver todos" (slot copy · noUI) → página 11
│   │   │   └── botão NOVO_COMUNICADO "Novo comunicado" (slot edit · hot · @publicador-de-conteudo)
│   │   │         → página 17 (clear 17)
│   │   ├── suas-pendências (20 · Dynamic Content · @/standard · DOM id home_pendencias)
│   │   │     título com &P1_QT_PENDENCIAS.; return pkg_home_ui.render_pendencias;
│   │   └── feedbacks-recebidos (30 · Dynamic Content · @/standard)
│   │         return pkg_home_ui.render_feedbacks;
│   └── coluna-lateral (30 · Static Content · @/blank-with-attributes · span 4, mesma linha)
│       ├── home_meu_gestor "Meu gestor" (10 · Dynamic Content) → pkg_home_ui.render_meu_gestor
│       ├── pesquisa-de-clima (20 · Dynamic Content · DOM id home_pesquisa) → pkg_home_ui.render_pesquisa
│       ├── próximos-eventos (30 · Dynamic Content) → pkg_home_ui.render_eventos
│       ├── home_aniversariantes "Celebrações de &P1_MES_ATUAL." (40 · Dynamic Content)
│       │     → pkg_home_ui.render_celebracoes
│       ├── P1_MES_ATUAL (100 · Hidden)
│       ├── P1_NAO_LIDOS (110 · Hidden)
│       └── P1_QT_PENDENCIAS (120 · Hidden)
└── Dialogs, Drawers and Popups
    ├── aniversariantes_todos "Celebrações" (40 · Dynamic Content · @/inline-dialog 480x320
    │     · DOM id aniversariantes_todos) → pkg_home_ui.render_celebracoes(p_limite => null, p_ver_todos => 'N')
    └── dar-feedback "Dar feedback" (50 · Static Content · @/inline-dialog 600x400 · DOM id home_dlg_feedback)
        ├── HTML "Para <strong data-cx-home-fb-nome>"
        ├── P1_FB_DESTINATARIO (10 · Hidden, valor não protegido)
        ├── P1_FB_TIPO (20 · Radio Group Reconhecimento/Sugestão · default RECONHECIMENTO)
        ├── P1_FB_TEXTO (30 · Textarea · máx. 1000)
        ├── botão FB_CANCELAR (slot close · classe cx-home-fb-cancelar · ação por JS)
        └── botão FB_ENVIAR "Enviar feedback" (slot create · hot · classe cx-home-fb-enviar · ação por JS)
```

## Lógica

- **Computations (Before Header):** `p9-mes-atual` (10) → `P1_MES_ATUAL := pkg_home_ui.mes_atual`; `p1-nao-lidos` (20) → `pkg_home_ui.nao_lidos_texto`; `p1-qt-pendencias` (30) → `pkg_home_ui.qt_pendencias`.
- **Validations:** —
- **Processes (todos Ajax Callback, `@colaborador`, respondem JSON `{ok, mensagem}`):**
  - `REGISTRAR_MARCACAO` (10) → `pkg_ponto_ui.ajax_registrar(x01)` (o mesmo da página 30).
  - `MARCAR_LIDO` (20) → `pkg_home_ui.ajax_marcar_lido(x01)`.
  - `RESPONDER_PESQUISA` (30) → `pkg_home_ui.ajax_responder_pesquisa(x01)`.
  - `SALVAR_FEEDBACK` (40) → `pkg_home_ui.ajax_salvar_feedback(x01, x02, x03)`.
- **Dynamic Actions:** `Atualizar comunicados` (`apexafterclosedialog` do botão `NOVO_COMUNICADO`) → Refresh de `home_comunicados`.
- **JavaScript da página** (*Function and Global Variable Declaration* + *Execute when Page Loads*):
  - `cxHomeCarregarFotos`: troca `data-cx-foto` pela URL da página 44 (`foto?session=...&x01=<arquivo>`).
  - `cxHomeCarrossel`: setas e pontos do carrossel, move o "Não lido" para junto do botão; refeito em `apexafterrefresh`.
  - `cxHomePontoRelogio` (a cada 1 s): relógio e horas trabalhadas do "Ponto de hoje" a partir de `data-segundos`.
  - `cxHomeChamar`: wrapper de `apex.server.process` para os Ajax Callbacks.
  - Clique em `[data-cx-home-registrar]` → `REGISTRAR_MARCACAO` e refresh do `home_hero`.
  - "Ler comunicado" → `MARCAR_LIDO` e depois redireciona para o `href` do botão.
  - Olho do pagamento (`[data-cx-home-mostrar]`) mostra/oculta o valor (abre oculto, como na p9).
  - "Responder pesquisa" → `RESPONDER_PESQUISA` e refresh de `home_pesquisa`.
  - "Dar feedback"/"Parabenizar" preenchem `P1_FB_*`, sobem o "Para <nome>" e abrem `home_dlg_feedback`; Enviar → `SALVAR_FEEDBACK`.
  - "Ver todos" das celebrações → `apex.theme.openRegion("aniversariantes_todos")`.
  - Atalho sem destino (`aria-disabled`) → `apex.message.alert`.
  - `apexafterclosedialog` em `document` → refresh de `home_pendencias` (pedido de ajuste da página 31).

## Dados

- Package `pkg_home_ui` (`modulos/home/pkg_home_ui.pks`/`.pkb`); depende de `pkg_ponto`/`pkg_ponto_ui` (`modulos/ponto-eletronico/`) e de `pkg_comunicado` (`qtd_nao_lidos`, `marcar_como_lido`; fonte em `database/ddl/08-plsql-especificacoes.sql` e `09-plsql-corpos.sql`).
- Tabelas (pela spec do package e pela query da Cards): `comunicado`, `comunicado_leitura`, `categoria_comunicado`, `departamento`, `colaborador`, `colaborador_holerite`, `presenca_colaborador`, `ponto_feriado` e as de `modulos/home-blocos/` (`feedback`, `pesquisa`, `pesquisa_resposta`, `evento`, `conversa_1a1`, `ferias_periodo`, `pdi`, `pdi_objetivo`).
- Multiempresa: a Cards filtra `c.id_empresa = :G_ID_EMPRESA`; as funções do package usam `G_ID_EMPRESA`/`APP_USER` da sessão quando não recebem parâmetro.

## Navegação

- Chega por: menu "Início" (página inicial da app).
- Vai para: página 11 ("Ler comunicado" e "Ver todos"); página 17 (modal "Novo comunicado"); páginas 9, 3, 34 e 4 (atalhos do hero); 30, 31 e 32 (ponto, pendências); 4 ("Mensagem" do gestor); página 44 (fotos).

## Pegadinhas e pendências

- **Pendências do §8 (Situação na app, 13/11/2026):** teste 9 "Parabenizar" (próximo aniversário em 15/11/2026, apagar o feedback depois); teste 6 "Disponível agora" com o gestor on-line; teste 10 com conta sem colaborador. Fora do escopo: o `ds_link` da pesquisa ainda é `example.com`.
- "Ler comunicado" e "Ver todos" levam à página 11, que é **placeholder** (`Etapas-home.md` §8, "Ficam de fora").
- `warnOnUnsavedChanges: false` na página é proposital: sem isso, "Ler comunicado" era barrado por "Sair do site?" depois de enviar um feedback (achado (c) do 8.11).
- A computação de `P1_MES_ATUAL` tem o nome `p9-mes-atual` (herança de cópia); não é da página 9.
- Os `htmlDomId` (`home_hero`, `home_indicadores`, `home_pendencias`, `home_pesquisa`, `home_dlg_feedback`, `aniversariantes_todos`) são obrigatórios: o JS usa esses ids (`Etapas-home.md` §7.2; 08 §3, "Static ID ≠ id do HTML").
- As regiões da coluna principal e lateral precisam de *Slot* `subRegions` (achado da Situação de 10/11/2026).
- A seção da página 1 no `08-convencoes-e-pegadinhas.md` §3 (links rápidos para 5/6/7, `href="#"`, `columnCssClasses` com ponto) descreve a Home antiga e não vale mais para este `.apx`.

## Referências

- [Guia da Home, §6 a §8 e Situação na app](../../../modulos/home/Etapas-home.md)
- [Guia de comunicados (categoria, fixado)](../../../modulos/comunicados/Etapas-comunicados.md)
- [02 · Páginas, página 1](../02-paginas.md)
- [07 · Design, §4.1](../07-design-pen-dev.md)
- [Página 17 · Novo comunicado](./p00017-comunicado.md) · [Página 11 · Comunicados Oficiais](./p00011-comunicados-oficiais.md)
