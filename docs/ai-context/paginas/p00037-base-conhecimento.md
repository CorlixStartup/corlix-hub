# Página 37 · Base de conhecimento

> **Estado em 13/11/2026** (backup `84f8625`): criada na app (backup de 10/11/2026, `acd59be`) conforme o §7 de [`Etapas-suporte-ti.md`](../../../modulos/suporte-ti/Etapas-suporte-ti.md), com o cabeçalho no slot `body`. Sem seção "Situação" no guia e sem registro dos testes 3 a 5 e 22 do §14.

## Resumo

| Atributo | Valor |
|---|---|
| Alias | `BASE-CONHECIMENTO` |
| Modo | Normal |
| Page template | `@corlix-standard-page` |
| Autorização | `@colaborador`; `argumentsMustHaveChecksum` |
| CSS/JS de arquivo | CSS `#APP_FILES#modulos/suporte-ti/suporte#MIN#.css`; JS nenhum |
| Módulo/guia | `modulos/suporte-ti/` · [`Etapas-suporte-ti.md`](../../../modulos/suporte-ti/Etapas-suporte-ti.md) §7 |
| Protótipo | — (destino de "Ver base de conhecimento" e dos assuntos da p34) |

Lista os artigos publicados (todos, agrupados por assunto, ou de um assunto) e mostra um artigo. Cada abertura de artigo soma 1 em `nr_acessos`.

## Estrutura

```
Page 37: Base de conhecimento
└── Body
    ├── Cabeçalho      (10, Static Content, Blank with Attributes (No Grid), css cx-cabecalho-pagina)
    │                  HTML fixo: trilha "Suporte TI" (f?p=&APP_ID.:34:&SESSION.), h1 e descrição
    ├── Artigos        (20, Dynamic Content, Blank with Attributes) render_base(:P37_ID_ASSUNTO, :P37_ID_ARTIGO)
    ├── P37_ID_ASSUNTO (30, Hidden, slot body)
    └── P37_ID_ARTIGO  (40, Hidden, slot body)
```

## Lógica

- **Computations / Validations:** —
- **Processes:** Before Header 10 `Registrar leitura`: `pkg_suporte.registrar_acesso_artigo(:P37_ID_ARTIGO)`, quando `P37_ID_ARTIGO` não é nulo.
- **Dynamic Actions:** —
- **JavaScript da página:** —

## Dados

- `suporte_artigo`, `suporte_assunto` (`modulos/suporte-ti/01_ddl_suporte.sql`).
- `pkg_suporte_ui.render_base` (`04_pkg_suporte_ui.pkb`): com `p_id_artigo` mostra o artigo; sem ele, os artigos do assunto ou todos.
- `pkg_suporte.registrar_acesso_artigo` (`03_pkg_suporte.pkb`): `update ... nr_acessos + 1` só se `id_empresa` = empresa da sessão e `fl_publicado = 'S'`.
- Multiempresa: pela empresa da sessão (`pkg_historico_carreira.fn_empresa_contexto`).

## Navegação

- Chega pela p34: assuntos (`url_assunto`, `P37_ID_ASSUNTO`), artigos e busca (`url_artigo`, `P37_ID_ARTIGO`), "Ver base de conhecimento" (sem item). Todas com clear cache 37.
- Volta para a p34 pela trilha do cabeçalho. Links internos entre assunto e artigo vêm do `render_base`.

## Pegadinhas e pendências

- `Cabeçalho` está no slot `body`; o guia §7.2 e a regra E3 do [11](../11-padroes-de-paginas.md) pedem **Breadcrumb Bar**. É Static Content com HTML na região, e não `render_cabecalho` do package (o guia escolheu assim).
- A trilha usa `f?p=` montado à mão. Funciona porque não passa argumento (guia §7.2); não copie para links com itens (08 §1, regra 6).
- Os hidden precisam de Value Protected (guia §7.3). O export não mostra o atributo; não confirmado.
- Recarregar a página com um artigo aberto conta outra leitura.

## Referências

- [`Etapas-suporte-ti.md`](../../../modulos/suporte-ti/Etapas-suporte-ti.md) §7, §14
- [Página 34](./p00034-suporte-ti.md) · [Página 42](./p00042-artigos.md) (cadastro dos artigos)
