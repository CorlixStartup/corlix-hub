# Página 12 · Colaboradores

> **Estado em 13/11/2026** (backup `84f8625`): implementada e validada na tela em 09/11/2026 com a conta de RH (`modulos/colaboradores/Etapas-colaboradores.md` §12.0 e `Registro-implantacao.md`, "Teste de colaborador comum"). Pendências deixadas para o final do projeto em `modulos/colaboradores/Pendencias.md`.

## Resumo

| Atributo | Valor |
|---|---|
| Alias | `COLABORADORES` |
| Modo | Normal (CSS Classes da página: `cx-colaboradores-pagina`) |
| Page template | `@/standard` (divergência E1 do `11` §6) |
| Autorização | `@ver-lista-colaboradores` (`VER_LISTA_COLABORADORES`: ADMIN_RH, EQUIPE_CORLIX_HUB, SOMENTE_DIRETORIA, GESTOR ou papel ACL `gestor`) · `argumentsMustHaveChecksum` |
| CSS/JS de arquivo | `#APP_FILES#modulos/colaboradores/colaboradores#MIN#.css`; JS na própria página (o módulo versiona `colaboradores-pagina.js`) |
| Módulo/guia | `modulos/colaboradores/` (`Etapas-colaboradores.md` §1 a §13) |
| Protótipo | `pen_dev/Colaboradores · visão de administração.png` (`07` §4.4) |

Diretório de pessoas da empresa, com filtros por facetas. RH e liderança consultam; só o RH edita (link para a página 14).

## Estrutura

```
Page 12: Colaboradores
├── Breadcrumb Bar
│   └── cabeçalho "Cabeçalho" (30 · Dynamic Content · @/blank-with-attributes-no-grid)
│         return pkg_colaboradores_ui.render_cabecalho;   (botão "Novo colaborador" só para ADMIN_RH)
└── Body
    ├── filtros "Filtros" (10 · Faceted Search · coluna 1, span 3 · filtra @colaboradores
    │   │   · total em #cx-colab-total)
    │   ├── P12_SEARCH (10 · Search: NOME_COMPLETO, LOGIN_APEX, EMAIL · "Nome, login ou e-mail")
    │   ├── P12_SITUACAO (20 · Checkbox: Ativa/Inativa)
    │   ├── P12_EMPRESA (30 · Checkbox: valores distintos)
    │   ├── P12_DEPARTAMENTO (40 · Checkbox: valores distintos)
    │   └── P12_PERFIL (50 · Checkbox: Administrador / Publicador de conteúdo / Colaborador)
    └── resultados "Resultados" (20 · Static Content · coluna 4, span 9, mesma linha)
        ├── cx-colab-barra "Barra da lista" (10 · Static Content · div#cx-colab-total)
        │   └── P12_ORDEM "Ordenar por" (10 · Select List NOME/LOGIN/DEPARTAMENTO · default NOME)
        └── colaboradores "Colaboradores" (20 · Classic Report · classe cx-relatorio)
              fonte: select ... from vw_colaboradores_lista; Order By pelo item P12_ORDEM
              colunas visíveis: NOME_COMPLETO "Pessoa" (link → p14, só @admin-rh) ou
              NOME_SEM_LINK "Pessoa" (!@admin-rh), LOGIN_APEX, VINCULO_LINHA1 "Vínculo",
              PERFIL (#PERFIL_HTML!RAW#), SITUACAO; as demais ocultas
```

## Lógica

- **Computations / Validations / Processes / Dynamic Actions:** —
- **JavaScript da página:** `MutationObserver` em `#cx-colab-total` põe o sufixo "colaborador"/"colaboradores" (`data-sufixo`).

## Dados

- View `vw_colaboradores_lista` (`modulos/colaboradores/01_vw_colaboradores_lista.sql`): avatar, vínculo, perfil principal e situação.
- `pkg_colaboradores_ui.render_cabecalho` (`modulos/colaboradores/02_pkg_colaboradores_ui.pks`/`.pkb`).
- Funções usadas pela view: `fn_colab_tem_papel` (papel do login na app, para o Perfil) e `fn_colab_e_equipe` (a conta é da equipe do Corlix Hub), em `00_fn_colab_tem_papel.sql` e `00_fn_colab_e_equipe.sql`.
- Multiempresa: a view devolve só a empresa de `G_ID_EMPRESA`; a equipe do Corlix Hub (papel explícito) vê todas e quem está sem empresa.
- Fotos pela página 44 (`apex_page.get_url(p_page => 44, p_x01 => ...)` na query).

## Navegação

- Chega por: menu Pessoas › Colaboradores (`@ver-lista-colaboradores`); branch "Voltar à lista após editar" da página 14; trilha do cabeçalho da página 14.
- Vai para: página 14 (nome da pessoa, com `P14_ID_COLABORADOR`, clear 14; "Novo colaborador", clear 14).

## Pegadinhas e pendências

- `Pendencias.md`: (1) criar colaborador pelo RH falha (`APEX_UTIL.CREATE_USER` exige admin do workspace); (2) inativar não bloqueia a conta; (3) papel `gestor` no cargo 403; (4) cargo do id 272; (5) testes de gestor, caracteres especiais e tela estreita.
- §12.0 do guia: testes 2, 3, 4 (diretor, gestor, colaborador comum), 6, 11, 12 e 14 constavam como pendentes em 09/11/2026; o de colaborador comum foi feito depois (`Registro-implantacao.md`).
- O `Registro-implantacao.md` ainda diz, em "Situação atual", que a página "não está integralmente validada"; as seções seguintes (09/11/2026) registram o encerramento. Leia o registro inteiro.
- A coluna "Pessoa" existe duas vezes (`NOME_COMPLETO` com link e `NOME_SEM_LINK`), alternadas por `@admin-rh` / `!@admin-rh`. Ao mexer numa, mexa na outra.
- O `11` §6 lista esta página como divergente (template `@/standard`, arquivo em `modulos/colaboradores/`). Não corrija de passagem.
- Diferenças aceitas com o protótipo: §12.0 do guia (seta de ordenação, "Sem vínculo" ausente para RH, filtro interno das facetas).

## Referências

- [Guia de colaboradores](../../../modulos/colaboradores/Etapas-colaboradores.md) · [Pendências](../../../modulos/colaboradores/Pendencias.md) · [Registro de implantação](../../../modulos/colaboradores/Registro-implantacao.md)
- [02 · Páginas, página 12](../02-paginas.md)
- [11 · Padrões de páginas, §6](../11-padroes-de-paginas.md)
- [Página 14 · Cadastro de Usuários](./p00014-cadastros-de-usuarios.md)
