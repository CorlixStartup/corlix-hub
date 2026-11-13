# Página 0 · Global Page

> **Estado em 13/11/2026** (backup `84f8625`): implementada. A busca do header já é a Dynamic Content do `pkg_busca_ui` (`modulos/busca/Etapas-busca.md` §4) e o bloco do usuário já é o menu em `popover` do `modulos/tema/Etapas-header-e-menu.md` §4. Nenhum dos dois guias tem seção "Situação"; teste registrado na app: não confirmado.

## Resumo

| Atributo | Valor |
|---|---|
| Alias | — (a Global Page não tem alias) |
| Modo | — (regiões renderizadas em todas as páginas) |
| Page template | — |
| Autorização | nenhuma (vale a de cada página) |
| CSS/JS de arquivo | nenhum na página; usa o CSS global do tema (`corlix-tema.css`, `custom.css`) |
| Módulo/guia | `modulos/busca/` (`Etapas-busca.md` §4) e `modulos/tema/Etapas-header-e-menu.md` §4 e §5 |
| Protótipo | sem tela própria; o header aparece em todas as telas de `pen_dev/` (descrição em `07-design-pen-dev.md` §2.1) |

Header da app: campo "Buscar na intranet..." depois do logo, sino de notificações e menu do usuário (Meu perfil, Sair) depois da barra de navegação.

## Estrutura

```
Page 0: Global Page
├── After Logo
│   └── novo "Barra de Busca" (10 · Dynamic Content · @/standard, noUI, sem header)
│         return pkg_busca_ui.render_campo;
└── After Navigation Bar
    └── perfil "Perfil" (10 · Static Content · @/standard, noUI, sem header)
          HTML .corlix-header__actions:
          ├── sino  → f?p=&APP_ID.:NOTIFICACOES:&SESSION. (página 5)
          ├── botão .corlix-header__user (popovertarget="cx-menu-usuario")
          │     <img src="&APP_USER_FOTO!ATTR."> + iniciais (&APP_USER_INICIAIS.) + &G_NOME_USUARIO.
          └── div#cx-menu-usuario [popover]
                &G_NOME_USUARIO. · &APP_USER. · &G_NOME_EMPRESA.
                ├── Meu perfil → f?p=&APP_ID.:MEU-PERFIL:&SESSION. (página 2)
                └── Sair → &LOGOUT_URL.
```

## Lógica

- **Computations / Validations / Processes:** —
- **Dynamic Actions:** —
- **JavaScript:** — (o menu do usuário usa o atributo HTML `popover`, sem JS; a foto usa `onerror` inline para cair nas iniciais).
- O campo de busca leva à página 29 (`.../busca?clear=29&session=...&p29_termo=<termo>`), montado pelo `pkg_busca_ui.render_campo` (`Etapas-busca.md`, "Como funciona").

## Dados

- `pkg_busca_ui` (`modulos/busca/pkg_busca_ui.pks`/`.pkb`).
- Application items preenchidos pelos app processes (`shared-components/app-processes.apx`): `APP_USER_FOTO`, `APP_USER_INICIAIS`, `G_NOME_USUARIO`, `G_NOME_EMPRESA`. `G_ID_EMPRESA` vem de `SET_G_ID_EMPRESA` (After Authentication).

## Navegação

- Vai para: página 5 (sino), página 2 (Meu perfil), página 29 (Enter no campo de busca), logout.
- A engrenagem de Configurações (página 6) que o `02-paginas.md` cita **não existe mais** no HTML; a página 6 só é alcançada pelo menu lateral (Administração › Configurações).

## Pegadinhas e pendências

- Os links usam `f?p=` com alias e sem argumentos; não precisam de checksum. Se algum passar a levar item, use `apex_page.get_url` (08 §1, regra 6).
- A foto usa `src="&APP_USER_FOTO!ATTR."`. Sem foto, o `onerror` esconde a `<img>` e mostra o `<span>` irmão com `style="display:none"` (atributo `style` herdado; regra "Sem CSS Inline" vale para novos ajustes).
- O que é renderizado nos slots `afterLogo`/`afterNavigationBar` depende do page template: em páginas `@/standard` o header pode sair diferente do `@corlix-standard-page` (`02-paginas.md`, página 0).
- O sino leva à página 5, que ainda é placeholder.

## Referências

- [02 · Páginas, página 0](../02-paginas.md) (descrição antiga: input `P0_SEARCH_GLOBAL` e engrenagem já saíram)
- [Guia da busca, §4](../../../modulos/busca/Etapas-busca.md)
- [Guia do header e menu, §4 e §5](../../../modulos/tema/Etapas-header-e-menu.md)
- [03 · Componentes compartilhados](../03-componentes-compartilhados.md) (app items e processes)
