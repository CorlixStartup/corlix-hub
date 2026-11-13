# Página 15 · Empresas Cadastradas

> **Estado em 13/11/2026** (backup `84f8625`): implementada no visual do protótipo pelo `modulos/tema/Etapas-empresas.md` (aplicado em 26/10/2026, com os ajustes do §7 do guia). O guia não tem seção "Situação"; registro de teste formal: não confirmado.

## Resumo

| Atributo | Valor |
|---|---|
| Alias | `EMPRESAS-CADASTRADAS` (título da página: "Empresas") |
| Modo | Normal |
| Page template | `@/standard` |
| Autorização | `@administration-rights` (`EQUIPE_CORLIX_HUB`) · `argumentsMustHaveChecksum` |
| CSS/JS de arquivo | nenhum; classes `cx-cabecalho-pagina`, `cx-relatorio`, `cx-badge` do tema global |
| Módulo/guia | `modulos/tema/Etapas-empresas.md`; banco em `modulos/empresas/` |
| Protótipo | `pen_dev/Empresas.png` (`07` §4.7) |

Lista das empresas (tenants) da plataforma, para a equipe do Corlix Hub. Abre a modal 16 para criar ou editar.

## Estrutura

```
Page 15: Empresas Cadastradas
├── Breadcrumb Bar
│   └── cabeçalho "Cabeçalho" (20 · Dynamic Content · @/blank-with-attributes-no-grid)
│         HTML no próprio PL/SQL: título "Empresas", descrição e link hot "+ Nova empresa"
│         (apex_page.get_url(p_page => 16, p_clear_cache => '16'))
└── Body
    └── empresas-cadastradas "Empresas" (10 · IR · @/interactive-report, header oculto · cx-relatorio)
          SQL: empresa (nome_fantasia, nome, cnpj, cidade – uf, e-mail, telefone mascarado,
          situacao Ativa/Inativa + classe sucesso/neutro, endereço, data_criacao)
          Link Column: lápis → página 16 (P16_ID_EMPRESA = #ID_EMPRESA#); NOME_FANTASIA também é link
          rodapé: "Endereço completo, CEP e data de abertura: Ações › Colunas"; paginação X a Y de Z
```

## Lógica

- **Computations / Validations / Processes:** —
- **Dynamic Actions:** `edit-report-dialog-closed` (`apexafterclosedialog` em `document`, porque o link "Nova empresa" fica fora do IR) → refresh do IR.
- **JavaScript da página:** —

## Dados

- Tabela `EMPRESA` (`STATUS` BOOLEAN, convertido por `case when e.status`).
- Multiempresa: **não filtra** por empresa, de propósito (tela do administrador da plataforma). Por isso exige `EQUIPE_CORLIX_HUB`.

## Navegação

- Chega por: menu Administração › Empresas (`@administration-rights`).
- Vai para: página 16 (modal; nova ou edição).

## Pegadinhas e pendências

- O cabeçalho monta HTML direto no PL/SQL da região, sem package `pkg_*_ui`; é exceção ao padrão do `11` (não copie para páginas novas).
- A barra do IR sai em inglês (idioma primário da app `en`); a nota do rodapé está em pt-BR (`02-paginas.md`, página 15).
- O `pageHeader` "Empresas" do IR é o cabeçalho do download em PDF, não o título da tela (`02-paginas.md`, página 15).
- Não há região de breadcrumb nesta página, embora exista a entrada `empresas-cadastradas` no breadcrumb compartilhado.

## Referências

- [Guia das empresas](../../../modulos/tema/Etapas-empresas.md)
- [02 · Páginas, página 15](../02-paginas.md)
- [Página 16 · Cadastro de Empresas](./p00016-cadastro-de-empresas.md)
