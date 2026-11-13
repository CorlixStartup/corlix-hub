# Página 42 · Artigos

> **Estado em 13/11/2026** (export colado nesta data, depois do backup `84f8625`): §11.2 aplicado. A lista filtra por `id_empresa = :G_ID_EMPRESA` e mostra só Título, Leitura (min), Acessos e Publicado. Acabamento do §11.2 aplicado no segundo export (16/16): `Publicado` pela LOV compartilhada `LOV_SIM_NAO`, máscara `990`, ícone "Editar", mensagens e botão "Novo artigo" em português. Sem teste na app. Ver `Etapas-suporte-ti.md`, "Situação". **As seções abaixo descrevem o backup `84f8625`, de antes do §11.2; o próximo backup traz as mudanças.**

## Resumo

| Atributo | Valor |
|---|---|
| Alias | `ARTIGOS` |
| Modo | Normal |
| Page template | `@corlix-standard-page` |
| Autorização | `@suporte-ti` (`SUPORTE_TI`); `argumentsMustHaveChecksum` |
| CSS/JS de arquivo | nenhum |
| Módulo/guia | `modulos/suporte-ti/` · [`Etapas-suporte-ti.md`](../../../modulos/suporte-ti/Etapas-suporte-ti.md) §11 |
| Protótipo | — (alimenta "Artigos mais acessados", a busca da p34 e a p37) |

Lista dos artigos da base de conhecimento para a TI escrever e publicar.

## Estrutura

```
Page 42: Artigos
├── Breadcrumb Bar
│   └── Breadcrumb (10, Breadcrumb, Title Bar, useBreadcrumbTitle) entrada "Artigos" (p42)
└── Body
    └── Artigos (10, Interactive Report, hideHeader, paginação X a Y)
        Fonte: tabela SUPORTE_ARTIGO, SEM where clause
        Link de linha: ícone fa-edit → p43 (P43_ID_ARTIGO = #ID_ARTIGO#)
        Colunas (todas visíveis, headings do assistente): ID_EMPRESA "Id Empresa" (LOV EMPRESA.NOME),
          ID_ASSUNTO "Id Assunto" (LOV SUPORTE_ASSUNTO.NM_ASSUNTO), DS_TITULO, DS_RESUMO, DS_CORPO,
          DS_PALAVRAS, NR_MIN_LEITURA, NR_ACESSOS, FL_PUBLICADO, DH_ATUALIZACAO, USR_ATUALIZACAO
          (só ID_ARTIGO oculta)
        Botão CREATE (rightOfInteractiveReportSearchBar, hot) "Create" → p43, clear cache 43
```

## Lógica

- **Computations / Validations / Processes:** —
- **Dynamic Actions:** `Edit Report - Dialog Closed`: `apexafterclosedialog` na região → Refresh.
- **JavaScript da página:** —

## Dados

- Tabela `suporte_artigo` (`modulos/suporte-ti/01_ddl_suporte.sql`), trigger `trg_suporte_artigo_aud`.
- LOVs compartilhadas `EMPRESA.NOME` (`empresa-nome`) e `SUPORTE_ASSUNTO.NM_ASSUNTO` (`suporte-assunto-nm-assunto`), ambas sem filtro por empresa (`shared-components/lovs.apx`).
- Multiempresa: **não filtra**. O guia §11.2 manda `id_empresa = :G_ID_EMPRESA` no Where Clause.

## Navegação

- Chega pela URL. O menu "Administração › Artigos de suporte" do §12 não existe em `lists.apx`.
- Vai para a p43 (modal); ao fechar, o IR é atualizado.

## Pegadinhas e pendências

- **Furo de multiempresa:** a TI de uma empresa vê e edita artigos de todas (regra 3 do README; 08 §1, regra 7). Aplicar o §11.2.
- `DS_CORPO` (até 4000 caracteres) aparece na lista; o guia manda esconder, junto com as outras colunas fora de `DS_TITULO`, `NR_MIN_LEITURA`, `NR_ACESSOS`, `FL_PUBLICADO`.
- Headings e textos do assistente ("Ds Titulo", "Fl Publicado", "Create", "No data found.").
- Sem entrada de menu (§12).

## Referências

- [`Etapas-suporte-ti.md`](../../../modulos/suporte-ti/Etapas-suporte-ti.md) §11, §12, §14
- [Página 43](./p00043-artigo.md) · [Página 37](./p00037-base-conhecimento.md)
