# Página 6 · Configurações

> **Estado em 13/11/2026** (backup `84f8625`): placeholder, só com o breadcrumb. Há protótipo, sem guia.

## Resumo

| Atributo | Valor |
|---|---|
| Alias | `CONFIGURACOES` |
| Modo | Normal |
| Page template | `@corlix-standard-page` |
| Autorização | nenhuma — qualquer usuário autenticado (nem a página nem a entrada do menu têm `authorizationScheme`) · `argumentsMustHaveChecksum` |
| CSS/JS de arquivo | nenhum |
| Módulo/guia | não há |
| Protótipo | `pen_dev/Configurações (equipe de produto).png` (`07` §4.14) |

Página prevista para cadastros de apoio, acesso e parâmetros, restrita à equipe de produto segundo o protótipo. Hoje sem conteúdo.

## Estrutura

```
Page 6: Configurações
└── Breadcrumb Bar
    └── navegação-estrutural (10 · Breadcrumb @breadcrumb · @/title-bar, useBreadcrumbTitle)
```

## Lógica

- **Computations / Validations / Processes / Dynamic Actions / JavaScript:** —

## Dados

—

## Navegação

- Chega por: menu Administração › Configurações (`lists.apx`, entrada `configurações`, sem autorização). A engrenagem do header que levava aqui não existe mais na página 0.
- Vai para: —

## Pegadinhas e pendências

- O protótipo diz "Acesso restrito à equipe de produto", mas a página e a entrada do menu estão abertas: qualquer usuário vê "Configurações" no grupo Administração (confirmado no teste de colaborador comum de 09/11/2026, `modulos/colaboradores/Registro-implantacao.md`). Ao implementar, ponha `authorizationScheme` na página e na entrada do menu (provavelmente `@administration-rights`, `EQUIPE_CORLIX_HUB`: decisão do time, não confirmada).
- O protótipo usa recursos sem backend no app (Application Settings, Configuration Options, competências, ciclos de avaliação): veja `07` §4.14 antes de propor.

## Referências

- [07 · Design, §4.14](../07-design-pen-dev.md)
- [02 · Páginas, página 6](../02-paginas.md)
- [11 · Padrões de páginas](../11-padroes-de-paginas.md)
