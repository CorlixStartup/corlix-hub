# Página 42 · Artigos

> **Estado em 13/11/2026** (backup `84f8625`): criada na app (backup de 10/11/2026, `acd59be`) só pelo assistente de Interactive Report + formulário. Os ajustes do §11.2 de [`Etapas-suporte-ti.md`](../../../modulos/suporte-ti/Etapas-suporte-ti.md) **não foram aplicados**: falta o filtro por empresa, e as colunas e headings são os do assistente. Sem seção "Situação" no guia e sem registro dos testes 5 e 22 do §14.

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
