# Busca de casos (Elasticsearch)

Busca dos **casos já ocorridos** (erros, sintomas, causas e correções) para os agentes de IA que trabalham neste repo. Em vez de `grep` por palavra exata, os agentes consultam um índice Elasticsearch com relevância (BM25), português (sem acento e com radical: "atualiza" acha "atualizar"), sinônimos ("acesso negado" acha "Access denied") e tolerância a erros de digitação. Códigos de erro (`ORA-01403`, `PLS-00201`, `-20012`) e identificadores (`P13_ID_COLABORADOR`, `PKG_PERFIS_ACESSO`) têm peso extra.

## Documentação oficial do APEX 26.1 (`apex_docs.py`)

Segundo índice, `apex-docs`, com a **documentação oficial inteira** (13 livros, 3.340 páginas: App Builder, API Reference, JavaScript API, APEXlang, Developer's Companion, Administration, SQL Workshop, Installation, Release Notes etc.), dividida por seção, com o link oficial de cada trecho. Na API Reference, cada página leva o package no título (`APEX_COLLECTION.ADD_MEMBER Procedure`).

```sh
python3 scripts/busca-casos/apex_docs.py baixar    # zip oficial (~325 MB) em .cache/apex-docs/
python3 scripts/busca-casos/apex_docs.py extrair   # HTML -> Markdown em .cache/apex-docs/md/ (+ sumario.json)
python3 scripts/busca-casos/apex_docs.py indexar   # índice apex-docs (~7.300 trechos)

python3 scripts/busca-casos/casos.py buscar "APEX_WEB_SERVICE.MAKE_REST_REQUEST" --fonte apex
python3 scripts/busca-casos/casos.py buscar "interactive grid editable" --fonte todas
```

`--fonte casos` (padrão) busca os documentos do projeto, inclusive a base em pt-BR `docs/apex-26.1/` (filtre com `--modulo apex-26.1`). `--fonte apex` busca a doc oficial (em inglês: busque em inglês) e `--fonte todas` busca as duas. O texto da Oracle fica só em `.cache/` (no `.gitignore`) e no índice; não vai para o Git.

## O que é indexado

Fonte: `docs/ai-context/*.md`, `docs/apex-26.1/*.md` e `modulos/**/*.md`, divididos em trechos pequenos:

| Tipo | De onde vem | Campos |
|---|---|---|
| `caso` | Entradas com **Sintoma:** / **Causa:** / **Correção:** / **Prevenção:** (doc 09) | separados por campo |
| `caso` | Cada linha das tabelas `\| Sintoma \| Causa \| Correção \|` dos guias `Etapas-*.md` ("Se não funcionar", "Problemas comuns") | sintoma, causa, correção |
| `caso` | Seções do doc 10 (cookies/sessão) | corpo |
| `doc` | Demais seções da documentação | corpo |

Casos pesam mais que trechos de doc. Cada resultado traz `arquivo:linha` para o agente abrir a fonte.

## Uso

Na raiz do repo:

```sh
# 1. Subir o Elasticsearch (uma vez; fica em 127.0.0.1:9200)
docker compose -f scripts/busca-casos/docker-compose.yml up -d

# 2. Indexar (de novo sempre que um .md de docs/ai-context ou modulos mudar)
python3 scripts/busca-casos/casos.py indexar

# 3. Buscar
python3 scripts/busca-casos/casos.py buscar "ORA-01403 no select into da página 13"
python3 scripts/busca-casos/casos.py buscar "menu não aparece depois de dar o papel" --tipo caso -n 3
python3 scripts/busca-casos/casos.py buscar "gráfico não atualiza" --modulo historico-carreira
python3 scripts/busca-casos/casos.py buscar "acesso negado" --json   # saída para agentes
```

Opções de `buscar`: `-n` (padrão 5), `--tipo caso|doc`, `--modulo` (`ai-context`, `historico-carreira`, `perfis-acesso`, `organograma`, `tema`), `--json`.

Sem Elasticsearch no ar, `buscar` cai num **modo offline** (pontuação simples em memória, sem sinônimos nem tolerância a erros de digitação), avisa no stderr e informa `"motor": "offline"` no JSON. Outro endereço: `ES_URL=http://host:9200`.

## Para registrar um caso novo

A busca só acha o que está documentado. Ao resolver um erro, registre-o:
- no `docs/ai-context/09-erros-e-solucoes.md`, como `### N.M <mensagem>` com **Sintoma:**, **Causa:**, **Correção:** e **Prevenção:**; ou
- na tabela "Se não funcionar" (`| Sintoma | Causa provável | Correção |`) da etapa do guia do módulo.

Depois rode `casos.py indexar`.

## Detalhes

- Só usa a stdlib do Python 3. Índice `corlix-casos`, recriado a cada `indexar`. Imagem `elasticsearch:8.15.3`, nó único, sem segurança, 512 MB de heap.
- Analisadores: `pt_br` (minúsculas, sem acento, stopwords sem o "não", `light_portuguese`), `pt_br_busca` (o mesmo + sinônimos da lista `SINONIMOS` em `casos.py`) e o subcampo `.exato` (sem radical, usado na busca com tolerância a erros de digitação).
- Para parar: `docker compose -f scripts/busca-casos/docker-compose.yml down` (o volume `es_dados` fica; `down -v` apaga).
