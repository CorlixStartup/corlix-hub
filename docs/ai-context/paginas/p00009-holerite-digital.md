# Página 9 · Holerite Digital

> **Estado em 13/11/2026** (backup `84f8625`): implementada, aplicada e testada na app em 07/11/2026 (testes 1 a 16 e 18; `modulos/holerite/Etapas-holerite.md`, "Situação na app"). Falta o teste 17 (a partir de 25/11/2026). O PDF no modelo "Aviso de crédito" (10/11/2026) está proposto e **não aplicado**.

## Resumo

| Atributo | Valor |
|---|---|
| Alias | `HOLERITE-DIGITAL` |
| Modo | Normal |
| Page template | `@corlix-standard-page` |
| Autorização | `@colaborador` (`COLABORADOR`) · `argumentsMustHaveChecksum` |
| CSS/JS de arquivo | `#APP_FILES#holerite#MIN#.css`; JS na própria página (o módulo versiona `holerite-pagina.js`) |
| Módulo/guia | `modulos/holerite/` (`Etapas-holerite.md` §1 a §3) |
| Protótipo | `pen_dev/Holerite digital.png` (`07` §1, item 31) |

Holerite da própria pessoa: líquido, proventos e descontos, bases, lista de holerites do ano, ocultar valores, Baixar PDF e "Solicitar correção". Só lê dados; a geração da folha é feita fora da página (job).

## Estrutura

```
Page 9: Holerite Digital
├── Breadcrumb Bar
│   └── cabeçalho "Cabeçalho" (20 · Dynamic Content · @/blank-with-attributes-no-grid)
│         return pkg_holerite_ui.render_cabecalho;
└── Body
    ├── visualização-do-holerite "Holerite" (30 · Dynamic Content · @/blank-with-attributes)
    │     return pkg_holerite_ui.render_pagina(:P9_COMPETENCIA);
    └── P9_COMPETENCIA (40 · Hidden · Storage Per Request) — mês em YYYYMM
```

## Lógica

- **Computations / Validations / Processes / Dynamic Actions:** —
- **JavaScript da página** (*Execute when Page Loads*, IIFE):
  - Valores abrem sempre como `••••••`; "Mostrar valores" troca o texto de `[data-cx-hol-valor]` e a barra `[data-cx-hol-barra]`.
  - A escolha "mostrar" vale só para a próxima carga (troca de mês/ano), guardada em `sessionStorage` (`cx-holerite-mostrar`); limpa a chave antiga `cx-holerite-ocultar` do `localStorage`.
  - `beforeprint`/`afterprint`: o PDF sai sempre com os valores; `[data-cx-hol-imprimir]` chama `window.print()`.
  - Select de ano `[data-cx-hol-ano]` → `apex.navigation.redirect` para a URL com checksum do mês mais recente do ano.
  - `apexafterclosedialog` → mostra a mensagem de sucesso do modal da página 22.

## Dados

- `pkg_holerite_ui` (`modulos/holerite/02_pkg_holerite_ui.pks`/`.pkb`), só leitura; usa o colaborador da conta logada (a página nunca passa `p_id_colaborador`).
- Tabelas `colaborador_holerite` e `holerite_itens`. A geração mensal: `prc_gerar_holerites_pendentes` e o job de `03_job_folha_mensal.sql`; `pkg_holerite` (`00_pkg_holerite.*`).
- Regras: holerite do mês só a partir do dia 25; nenhum mês antes da admissão (`Etapas-holerite.md`, "A regra do dia 25" e "A regra da admissão").
- Multiempresa: o package lê só a pessoa da sessão. Parâmetros públicos sem conferência com a sessão estão em "Fica para depois" do `Etapas-isolamento-empresas.md`.

## Navegação

- Chega por: menu Minha carreira › Holerite (`@colaborador`); atalho "Holerite" do hero e "ver holerite" dos indicadores da página 1.
- Vai para: a própria página 9 com `P9_COMPETENCIA` (links dos meses, com checksum); página 22 (modal "Solicitar correção", com a referência `Holerite-MM/AAAA`).

## Pegadinhas e pendências

- URL com `p9_competencia` sem checksum ou com checksum falso é recusada ("Session state protection violation", teste 11). Gere links com `apex_page.get_url`.
- Teste 17 pendente: a partir de 25/11/2026, novembro deve aparecer primeiro, com o selo "Pagamento agendado".
- PDF "Aviso de crédito": `02_pkg_holerite_ui.pkb` e `holerite.css`/`.min.css` mudados no módulo, não aplicados; faltam os testes 7, 20 e 21 do §4 (`Etapas-holerite.md`, "PDF no modelo de aviso de crédito").
- `PKG_HOLERITE.gerar_folha_mensal` e o `render` antigo continuam no banco e leem todas as empresas; nenhuma página chama (`Etapas-isolamento-empresas.md`, "Fica para depois").

## Referências

- [Guia do holerite e Situação na app](../../../modulos/holerite/Etapas-holerite.md)
- [02 · Páginas, página 9](../02-paginas.md)
- [Guia do histórico de carreira, §6 (página 22)](../../../modulos/historico-carreira/Etapas-historico-carreira.md)
