# Fluxo · Ficha de contexto de uma página

**Quando:** uma página nova entra no backup, uma página muda bastante, ou a ficha diverge do `.apx`. As fichas ficam em [`docs/ai-context/paginas/`](../../ai-context/paginas/), uma por página, com o mesmo nome do `.apx` (`p00017-comunicado.md`, `p00001-início.md`, com acentos).

**Fonte da verdade:** `corlixhub/pages/pNNNNN-*.apx` do backup de DEV. Os guias dizem o que foi aplicado e testado (seção "Situação"). O `02-paginas.md` pode estar atrás: o `.apx` manda. Não invente: o que não der para confirmar fica "não confirmado".

## Estrutura (títulos fixos)

```markdown
# Página N · <nome>
> **Estado em DD/MM/AAAA** (backup `<commit>`): status real em uma frase, com o guia e a linha da Situação.

## Resumo
| Alias | Modo | Page template | Autorização | CSS/JS de arquivo | Módulo/guia | Protótipo |
Propósito em 1–3 frases.

## Estrutura
Árvore como no Page Designer: regiões (sequência, slot, template, static id), itens, botões; fonte de Cards/Reports.

## Lógica
Computations, Validations, Processes (inclusive Ajax Callbacks com o PL/SQL e a autorização), Dynamic Actions, JavaScript.

## Dados
Tabelas, views, packages (com o arquivo em `modulos/`), filtro por `G_ID_EMPRESA`.

## Navegação
De onde se chega e para onde vai.

## Pegadinhas e pendências
Pontos reais, com a fonte.

## Referências
Guia, seção do 02, docs.
```

## Ao terminar

- Atualize a linha da página no índice [`paginas/README.md`](../../ai-context/paginas/README.md) e na tabela do [`docs/ai-context/README.md`](../../ai-context/README.md).
- Divergência entre o `.apx` e outro documento: corrija o documento ou registre no índice, em "Divergências".
- Links relativos a partir de `docs/ai-context/paginas/`; confira se nenhum ficou quebrado.
