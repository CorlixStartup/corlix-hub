# Página 11 · Comunicados Oficiais

> **Estado em 13/11/2026** (backup `84f8625`): placeholder, só com o breadcrumb. Há protótipo, sem guia. É o destino de "Ler comunicado" e "Ver todos" da Início, que por isso ficam sem conteúdo (`modulos/home/Etapas-home.md` §8, "Ficam de fora").

## Resumo

| Atributo | Valor |
|---|---|
| Alias | `COMUNICADOS-OFICIAIS` |
| Modo | Normal |
| Page template | `@/standard` |
| Autorização | nenhuma — qualquer usuário autenticado · `argumentsMustHaveChecksum` |
| CSS/JS de arquivo | nenhum |
| Módulo/guia | não há guia da página; dados e categorias em `modulos/comunicados/` |
| Protótipo | `pen_dev/Comunicados.png` (`07` §4.3) |

Lista de comunicados da empresa. Hoje sem conteúdo; a única listagem é o carrossel da Início (5 mais recentes).

## Estrutura

```
Page 11: Comunicados Oficiais
└── Breadcrumb Bar
    └── breadcrumb (10 · Breadcrumb @breadcrumb · @/title-bar, useBreadcrumbTitle)
```

## Lógica

- **Computations / Validations / Processes / Dynamic Actions / JavaScript:** —

## Dados

— (quando implementada: `comunicado`, `categoria_comunicado`, `comunicado_leitura`, `departamento`, filtrando `id_empresa = :G_ID_EMPRESA`, como a Cards da página 1).

## Navegação

- Chega por: menu "Comunicados"; página 1 (ação "Ler comunicado" do card, botão "Ver todos"); página 29 (título do comunicado na busca).
- Vai para: —

## Pegadinhas e pendências

- "Ler comunicado" na página 1 chama `MARCAR_LIDO` antes de abrir esta página, sem passar o ID; a página não sabe qual comunicado foi clicado.
- O protótipo pede Faceted Search (Categoria, Leitura, Público) + Cards, "Marcar todos como lidos" e "+ Novo comunicado" (`07` §4.3). Siga o `11-padroes-de-paginas.md`: a composição Faceted Search + relatório da página 12 ainda tem divergências listadas no §6 dele.
- Template `@/standard`, diferente do `@corlix-standard-page` da Início (divergência E1 do `11` §6).

## Referências

- [07 · Design, §4.3](../07-design-pen-dev.md)
- [Guia da Home, §8](../../../modulos/home/Etapas-home.md) · [Guia de comunicados](../../../modulos/comunicados/Etapas-comunicados.md)
- [02 · Páginas, página 11](../02-paginas.md)
