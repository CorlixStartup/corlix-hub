# Página 45 · Otimizar imagens

> **Estado em 17/11/2026:** proposta, **não criada** no app. Guia [`modulos/imagens/Etapas-imagens.md`](../../../modulos/imagens/Etapas-imagens.md) (CD-44). Packages testados em Oracle 23ai local com as APIs do APEX simuladas; sem teste no navegador.

## Resumo

| Atributo | Valor (proposto) |
|---|---|
| Alias | `OTIMIZAR-IMAGENS` |
| Modo | Normal, fora do menu (uso pontual) |
| Page template | `@corlix-standard-page` |
| Autorização | `@admin-rh`, com `pageAccessProtection: argumentsMustHaveChecksum`; os Ajax conferem `ADMIN_RH` de novo |
| CSS/JS de arquivo | `#APP_FILES#imagens#MIN#.css`; `imagens-pagina.js` em Execute when Page Loads |
| Módulo/guia | `modulos/imagens/` · `Etapas-imagens.md` §3 |
| Protótipo | — (página técnica de administração) |

## Estrutura

```
Page 45: Otimizar imagens
├── Breadcrumb Bar
│   └── Cabeçalho (Dynamic Content) pkg_imagens_ui.render_cabecalho
├── Body
│   └── Imagens (Dynamic Content) pkg_imagens_ui.render_lista
└── Processing › Ajax Callback
    ├── OBTER_IMAGEM   pkg_imagens_ui.ajax_obter
    └── SALVAR_IMAGEM  pkg_imagens_ui.ajax_salvar
```

## Lógica

- Lista os comunicados de `G_ID_EMPRESA` com imagem acima de 400 KB, do maior para o menor.
- **Otimizar**: `OBTER_IMAGEM` (x01 = `ID_COMUNICADO`) devolve a imagem em base64; o navegador gera o JPEG e envia em `f01` para `SALVAR_IMAGEM`.
- O servidor confere papel, empresa, cabeçalho e fim de JPEG, até 1 MB e menor que a atual; guarda a original em `IMAGEM_ORIGINAL` e faz commit.

## Dados

- `COMUNICADO.IMAGEM`, `MIME_TYPE`, `NOME_ARQUIVO`, `ID_EMPRESA`.
- `IMAGEM_ORIGINAL` (`modulos/imagens/01_ddl_imagens.sql`).

## Pendências

- Criar a página (guia §1 a §3) e rodar os testes do §4.
- Logotipos e anexos de formação ficam para depois (guia, "Fica para depois").
