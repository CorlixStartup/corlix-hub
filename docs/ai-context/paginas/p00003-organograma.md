# Página 3 · Organograma

> **Estado em 13/11/2026** (backup `84f8625`): implementada com o `modulos/organograma` (Dynamic Content do `pkg_organograma` e drawer de detalhes). O guia `Etapas-organograma.md` não tem seção "Situação"; o uso na app aparece no teste 7 de `modulos/perfil/Etapas-perfil-privacidade.md` (04/11/2026, "Ver perfil completo" abre a pessoa certa). O isolamento por empresa (`modulos/isolamento-empresas` §2) não tem registro de aplicação.

## Resumo

| Atributo | Valor |
|---|---|
| Alias | `ORGANOGRAMA` |
| Modo | Normal |
| Page template | `@/standard` |
| Autorização | nenhuma — qualquer usuário autenticado · `argumentsMustHaveChecksum` |
| CSS/JS de arquivo | `#APP_FILES#organograma#MIN#.css`; JS na própria página (o módulo versiona `organograma.js`) |
| Módulo/guia | `modulos/organograma/` (`Etapas-organograma.md`, `organograma.sql`) e `modulos/isolamento-empresas/Etapas-isolamento-empresas.md` §2 |
| Protótipo | `pen_dev/Organograma.png`; variantes em `modulos/organograma/Organograma — redesign (navegação por níveis).png` e `Organograma · detalhes da pessoa (Drawer) — redesign.png` (`07` §4.8 e §4.9) |

Navegação por níveis da hierarquia: pessoa em foco, caminho até o topo e subordinados diretos. Clicar num card abre um drawer com contato, gestor, equipe direta e "Ver perfil completo".

## Estrutura

```
Page 3: Organograma
├── Breadcrumb Bar
│   └── breadcrumb (10 · Breadcrumb @breadcrumb · @/title-bar)
└── Body
    ├── organograma "Organograma Principal" (10 · Dynamic Content · @/blank-with-attributes · DOM id organograma)
    │     PL/SQL: foco = P3_ID_FOCO; se nulo, o colaborador do APP_USER em vw_org_colaborador;
    │     return pkg_organograma.render(v_id_foco);  Page Items to Submit: P3_ID_FOCO
    ├── P3_ID_FOCO (20 · Hidden) default: select id_colaborador from vw_org_colaborador
    │     where lower(email) = lower(:APP_USER)
    └── P3_BUSCA (30 · Popup LOV · label "Novo" · placeholder "Buscar pessoa no organograma")
          LOV: nome_completo || ' — ' || cargo de vw_org_colaborador
```

## Lógica

- **Computations / Validations:** —
- **Processes:** `ORG_DETALHES` (Ajax Callback, 10) → `apex_util.prn(pkg_organograma.render_detalhes(x01))`. Tem `buildOption: !@commented-out` (ver Pegadinhas).
- **Dynamic Actions:** `Buscar Organograma` (Change em `P3_BUSCA`) → JS: `orgIrPara(id)` e limpa o campo.
- **JavaScript da página:**
  - `orgIrPara`: grava `P3_ID_FOCO` e dá refresh na região `organograma`.
  - `orgAbrirDetalhes`/`orgObterDrawer`/`orgCliqueNoDrawer`: `<dialog class="org-drawer">` com o HTML do `ORG_DETALHES`; ações `fechar`, `detalhe`, `equipe`, `copiar`.
  - `orgCarregarFotos`: troca `img[data-org-foto]` pela URL da página 44.
  - `orgCopiar`: copia o e-mail para a área de transferência.
  - Page Load: clique delegado em `.org [data-acao]` (`foco`/`detalhe`) e, no `apexafterrefresh` de `#organograma`, recarrega fotos e foca `#org-foco-nome`.

## Dados

- View `vw_org_colaborador` e package `pkg_organograma` (`modulos/organograma/organograma.sql`). Versão com `id_empresa` e filtro da sessão: `modulos/isolamento-empresas/01_vw_org_colaborador_empresa.sql`.
- Multiempresa: depende só da view. Sem o script do isolamento, a busca e o drawer veem todas as empresas (`Etapas-isolamento-empresas.md`, prioridade Alta).

## Navegação

- Chega por: menu Pessoas › Organograma; atalho "Organograma" do hero da Início; busca (página 29, nome da pessoa com `P3_ID_FOCO`); perfil (página 2, "Organograma" e "e mais N", com `P3_ID_FOCO`).
- Vai para: página 2 ("Ver perfil completo") e chat ("Conversar") pelos links do package; página 44 (fotos).

## Pegadinhas e pendências

- `ORG_DETALHES` tem `buildOption: !@commented-out` desde o backup de 09/10/2026. Pela notação `!` (como `!@admin-rh` na p12), deve ser "{Not Commented Out}", que mantém o processo ativo; não conferido no Builder.
- No `organograma.sql` do repositório, `c_pagina_perfil = 20` (`P20_ID_COLABORADOR`) e `c_pagina_chat = 30` (`P30_ID_COLABORADOR`), que hoje são Dashboard RH e Ponto. Como "Ver perfil completo" abriu a página 2 no teste de 04/11/2026, a versão instalada no banco deve ser outra: não confirmado.
- `P3_ID_FOCO` tem default por `email = APP_USER`, mas a região usa `login_apex`; como a região resolve o nulo, o default quase nunca vale.
- `P3_BUSCA` tem o label "Novo" (sobra do assistente).
- Sem `authorizationScheme` na página. O isolamento por empresa (`Etapas-isolamento-empresas.md` §2) e os testes 1 a 4 do §7 desse guia não têm registro de aplicação.
- O `02-paginas.md` e o `README.md` ainda dizem "placeholder"; este `.apx` já tem o módulo integrado.

## Referências

- [Guia do organograma](../../../modulos/organograma/Etapas-organograma.md)
- [Isolamento entre empresas, §2 e §7](../../../modulos/isolamento-empresas/Etapas-isolamento-empresas.md)
- [06 · Módulos (organograma)](../06-modulos.md) · [05 · Banco (pkg_organograma)](../05-banco-de-dados.md)
- [02 · Páginas, página 3](../02-paginas.md)
