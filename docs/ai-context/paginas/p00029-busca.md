# Página 29 · Busca

> **Estado em 13/11/2026** (backup `84f8625`): montada conforme `modulos/busca/Etapas-busca.md` §3 e §4 (as três regiões do `pkg_busca_ui` e o campo do header na página 0 com `render_campo` estão no export). O guia não tem seção "Situação" e não há registro de teste na app; o `README.md` ainda lista a página como "Em montagem".

## Resumo

| Atributo | Valor |
|---|---|
| Alias | `BUSCA` |
| Modo | Normal |
| Page template | `@corlix-standard-page` |
| Autorização | nenhuma — qualquer usuário autenticado · Page Access Protection no padrão (Unrestricted: o termo chega pela URL) |
| CSS/JS de arquivo | nenhum `fileUrls`; CSS `cx-busca-*` no `custom.css` global; JS inline (blocos de `modulos/busca/busca-pagina.js`) |
| Módulo/guia | `modulos/busca/` · `Etapas-busca.md` |
| Protótipo | `pen_dev/Busca (resultados).png` (`07-design-pen-dev.md` §4.17) |

Resultados da busca do header: pessoas ativas e comunicados da empresa do usuário, mais um card de ajuda.

## Estrutura

```
Page 29: Busca
├── Breadcrumb Bar
│   └── cabeçalho (10 · Dynamic Content · return pkg_busca_ui.render_cabecalho(:P29_TERMO) · @/blank-with-attributes-no-grid)
│       └── P29_TERMO (Hidden · valueProtected: false)
└── Body
    ├── resultados (10 · Dynamic Content · return pkg_busca_ui.render_resultados(:P29_TERMO) · span 8)
    └── ajuda      (20 · Dynamic Content · return pkg_busca_ui.render_ajuda · span 4 · mesma linha)
```

## Lógica

- **Computations / Validations / Processes:** —
- **Dynamic Actions:** —
- **JavaScript da página:**
  - Function and Global Variable Declaration: `cxBuscaCarregarFotos(raiz)` troca cada `img[data-cx-foto]` por `.../foto?session=...&x01=<arquivo>` (alias `foto` = página 44, que entrega a foto do bucket privado).
  - Execute when Page Loads: `cxBuscaCarregarFotos();`.

## Dados

- Package `pkg_busca_ui` (`modulos/busca/pkg_busca_ui.pks`/`.pkb`): `render_campo` (header, página 0), `render_cabecalho`, `render_resultados`, `render_ajuda`. Constante `c_pagina = 29`.
- Tabelas lidas: `colaborador`, `cargo`, `departamento`, `comunicado`.
- Multiempresa: as funções usam `G_ID_EMPRESA` por padrão (`p_id_empresa default v('G_ID_EMPRESA')`); sem empresa, mostra "Nenhum resultado" com a explicação do vínculo.
- Regras (guia, "Como funciona"): termo com pelo menos 2 letras, sem diferença de maiúsculas e acentos; busca vazia lista tudo; até 20 linhas por grupo.

## Navegação

- Chega por: Enter no campo "Buscar na intranet..." do header (região "Barra de Busca" da página 0, `pkg_busca_ui.render_campo`), que leva a `.../busca?clear=29&session=...&p29_termo=<termo>`. Não há entrada de menu nem breadcrumb.
- Vai para: página 3 (nome da pessoa, `P3_ID_FOCO`), página 4 ("Conversar") e página 11 (título do comunicado), todos por `apex_page.get_url`.

## Pegadinhas e pendências

- `P29_TERMO` precisa de Value Protected Off e Session State Protection Unrestricted; a página precisa de Page Access Protection Unrestricted, senão dá erro de checksum (guia §3 e §3.2).
- As fotos dependem da página 44 (`FOTO`, autorização `VER_FOTO_COLABORADOR`). O comentário do JS no `.apx` ainda fala em `#APP_FILES#`, mas o código já usa a página 44 (igual ao `busca-pagina.js`).
- Sem o JS da página, só aparecem as iniciais (guia, "Se não funcionar").
- Fica para depois: grupo "Páginas do menu" do protótipo (guia, "Como funciona").
- `pkg_busca_ui` aceita empresa por parâmetro sem comparar com a sessão (`Etapas-isolamento-empresas.md`, "Fica para depois"); a página não passa esse parâmetro.
- Teste do guia (§5) sem registro de execução: tratar como não validada na app.

## Referências

- [Guia da busca](../../../modulos/busca/Etapas-busca.md)
- [Protótipo](../../../pen_dev/Busca%20%28resultados%29.png)
- [07 · Design, §4.17](../07-design-pen-dev.md)
- [02 · Páginas](../02-paginas.md) (sem seção própria da 29)
- [Página 44 · Foto](./p00044-foto.md) (entrega das fotos)
