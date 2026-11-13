# Página 34 · Suporte TI

> **Estado em 13/11/2026** (backup `84f8625`): criada na app (chegou no backup de 10/11/2026, `acd59be`) conforme o §4 de [`Etapas-suporte-ti.md`](../../../modulos/suporte-ti/Etapas-suporte-ti.md). O guia não tem seção "Situação na app" e não há registro dos testes do §14. O menu lateral do §12 não foi aplicado: a página não está em `lists.apx`.

## Resumo

| Atributo | Valor |
|---|---|
| Alias | `SUPORTE-TI` |
| Modo | Normal |
| Page template | `@corlix-standard-page` |
| Autorização | `@colaborador` (`COLABORADOR`); `pageAccessProtection: argumentsMustHaveChecksum` |
| CSS/JS de arquivo | CSS `#APP_FILES#modulos/suporte-ti/suporte#MIN#.css`. JS só em `executeWhenPageLoads` (conteúdo de `modulos/suporte-ti/suporte-pagina.js`) |
| Módulo/guia | `modulos/suporte-ti/` · [`Etapas-suporte-ti.md`](../../../modulos/suporte-ti/Etapas-suporte-ti.md) §4 |
| Protótipo | [`pen_dev/Suporte TI.png`](../../../pen_dev/Suporte%20TI.png) (07, linha 33) |

Tela do colaborador para pedir ajuda à TI: aviso de instabilidade, busca na base de conhecimento, assuntos, "Meus chamados", status dos sistemas, artigos mais acessados e contatos. Todo o HTML vem do `pkg_suporte_ui`.

## Estrutura

```
Page 34: Suporte TI
├── Body
│   ├── Cabeçalho              (10, body, Blank with Attributes (No Grid)) render_cabecalho
│   ├── Coluna principal       (10, body, Blank with Attributes, span 8)   Static Content
│   │   ├── Aviso              (10, Blank with Attributes, htmlDomId suporte_aviso)    render_aviso   [static id: new]
│   │   ├── Como podemos ajudar(20, Blank with Attributes, htmlDomId suporte_ajuda)    render_ajuda
│   │   └── Meus chamados      (30, Blank with Attributes, htmlDomId suporte_chamados) render_chamados
│   └── Coluna lateral         (20, body, Blank with Attributes, span 4, startNewRow: false)
│       ├── Status dos sistemas      (10, Standard, t-Region--scrollBody) render_status
│       ├── Artigos mais acessados   (20, Standard, t-Region--scrollBody) render_artigos
│       └── Prefere falar com alguém (30, Standard, t-Region--scrollBody) render_contato
└── Ajax Callback
    ├── BUSCAR_ARTIGOS     (10)
    └── CONFIRMAR_SOLUCAO  (20)
```

Sem itens de página e sem botões nativos: links e botões estão no HTML do package.

## Lógica

- **Computations / Validations:** —
- **Processes (Ajax Callback, autorização da página):**
  - `BUSCAR_ARTIGOS`: `pkg_suporte_ui.ajax_buscar(apex_application.g_x01)`. Responde `{ok, mensagem, html}`.
  - `CONFIRMAR_SOLUCAO`: `pkg_suporte_ui.ajax_confirmar(to_number(apex_application.g_x01))`. "Sim, encerrar" do chamado resolvido; responde `{ok, mensagem}`.
- **Dynamic Actions:** — (tudo no JS da página).
- **JavaScript (Execute when Page Loads):**
  - Abas "Em aberto"/"Resolvidos" (`[data-cx-sup-aba]`, setas do teclado); após `apexafterrefresh` em `#suporte_chamados`, volta à aba aberta.
  - Busca (`[data-cx-sup-busca]`): a partir de 3 letras, espera 300 ms, chama `BUSCAR_ARTIGOS` e descarta respostas fora de ordem; Enter não envia a página.
  - `[data-cx-sup-confirmar]` → `CONFIRMAR_SOLUCAO`, depois `refresh` de `suporte_chamados`.
  - Aviso: o "x" grava o id em `sessionStorage` (`cxSupAvisosFechados`).
  - `apexafterclosedialog` (p35/p36): mostra a mensagem de sucesso e atualiza `suporte_chamados`.

## Dados

- Tabelas: `suporte_config`, `suporte_sistema`, `suporte_assunto`, `suporte_artigo`, `suporte_chamado`, `suporte_mensagem` (`modulos/suporte-ti/01_ddl_suporte.sql`).
- Packages: `pkg_suporte_ui` (`04_pkg_suporte_ui.pks/.pkb`: `render_cabecalho`, `render_aviso`, `render_ajuda`, `render_chamados`, `render_status`, `render_artigos`, `render_contato`, `ajax_buscar`, `ajax_confirmar`) e `pkg_suporte` (`03_pkg_suporte.pks/.pkb`: `confirmar_solucao`, `fn_colaborador_logado`). Depende de `pkg_historico_carreira.fn_empresa_contexto`/`fn_data_local`.
- Job `SUPORTE_ENCERRAR_VENCIDOS` (`05_job_suporte.sql`) encerra os resolvidos sem confirmação.
- Multiempresa: o package filtra pela empresa da sessão (`pkg_historico_carreira.fn_empresa_contexto`, que usa `G_ID_EMPRESA`). Instalação no banco do app: não confirmado (o 06 ainda diz "falta instalar").

## Navegação

- Chega por: atalho **Suporte TI** da Início (`pkg_home_ui.pkb`, `atalho(... p_pagina => 34)`, guia §13; se o package instalado é essa versão, não confirmado) ou pela URL. Sem entrada de menu (§12 não aplicado).
- Vai para: p35 (Abrir chamado, modal), p36 (Chamado, modal), p37 (Base de conhecimento, por assunto ou artigo) e p4 (Chat, "Conversar com a TI"). URLs com `apex_page.get_url` no `pkg_suporte_ui`.

## Pegadinhas e pendências

- O **HTML DOM ID** `suporte_chamados` é obrigatório: o JS atualiza a região por ele (guia §4.3; 08 §3 "Static ID ≠ id do HTML").
- Os nomes dos Ajax Callbacks têm de ser exatos (`BUSCAR_ARTIGOS`, `CONFIRMAR_SOLUCAO`); o JS chama pelo nome (guia §4.5).
- O `Cabeçalho` está no slot `body` (seq 10, mesmo número da `Coluna principal`). O guia §4.2 e a regra E3 do [11](../11-padroes-de-paginas.md) mandam pôr em **Breadcrumb Bar**.
- A região `Aviso` tem static id `new` (sobra da criação); não afeta o DOM, que usa `suporte_aviso`.
- File URL real é `#APP_FILES#modulos/suporte-ti/suporte#MIN#.css` (arquivo na pasta `modulos/suporte-ti/` dos Static Files). O guia §2/§4.1 manda subir na raiz e usar `#APP_FILES#suporte#MIN#.css`: o guia está desatualizado.
- Menu (§12) e atalho da Início (§13): menu ausente em `lists.apx`; atalho depende do `pkg_home_ui` recompilado. A p1 ainda tem o handler de "atalho sem destino" (`aria-disabled`).
- Contas sem colaborador vinculado (ex.: SARAHSILVA, EDUARDOMARINS, ALAIRTONROCHA) não abrem chamados (guia, "Decisões"). Com `ADMIN_RH` e sem vínculo, a página mostra só o aviso (teste 25).
- Toda mensagem é vista pelo colaborador; não há nota interna (guia, "Fica de fora").
- Testes do §14 (1 a 29): sem registro de execução.

## Referências

- [`modulos/suporte-ti/Etapas-suporte-ti.md`](../../../modulos/suporte-ti/Etapas-suporte-ti.md) §1–§4, §12–§14
- [06 · Módulos §2E](../06-modulos.md)
- [11 · Padrões de páginas](../11-padroes-de-paginas.md)
- [08 · Convenções e pegadinhas](../08-convencoes-e-pegadinhas.md)
