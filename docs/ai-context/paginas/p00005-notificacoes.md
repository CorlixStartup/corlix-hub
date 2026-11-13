# Página 5 · Notificações

> **Estado em 13/11/2026** (backup `84f8625`): placeholder, só com o breadcrumb. Não há guia nem protótipo.

## Resumo

| Atributo | Valor |
|---|---|
| Alias | `NOTIFICACOES` |
| Modo | Normal |
| Page template | `@corlix-standard-page` |
| Autorização | nenhuma — qualquer usuário autenticado · `argumentsMustHaveChecksum` |
| CSS/JS de arquivo | nenhum |
| Módulo/guia | não há |
| Protótipo | não há em `pen_dev/` (`07` §1) |

Destino do sino do header. Ainda sem conteúdo.

## Estrutura

```
Page 5: Notificações
└── Breadcrumb Bar
    └── navegação-estrutural (10 · Breadcrumb @breadcrumb · @/title-bar, useBreadcrumbTitle)
```

## Lógica

- **Computations / Validations / Processes / Dynamic Actions / JavaScript:** —

## Dados

—

## Navegação

- Chega por: sino do header (página 0, `f?p=&APP_ID.:NOTIFICACOES:&SESSION.`). Não está no menu lateral. Tem entrada no breadcrumb compartilhado.
- Vai para: —

## Pegadinhas e pendências

- A página 8 tem o mesmo nome ("Notificações"), alias `NOTIFICAÇÕES` e está vazia; não há referência a ela. Ao implementar notificações, use esta (5) e trate a 8 como duplicata (`02-paginas.md`, página 8).
- O link rápido "Holerite Digital" que levava a esta página era da Home antiga; a Início atual leva à página 9.
- O protótipo de Configurações (`07` §4.14) cita o recurso "Notificações" (Inativo), "Sino do cabeçalho com novos comunicados e aniversários": regra de negócio ainda não definida.

## Referências

- [02 · Páginas, página 5](../02-paginas.md)
- [Página 0 · Global Page](./p00000-global-page.md) · [Página 8 · Notificações (vazia)](./p00008-notificações.md)
