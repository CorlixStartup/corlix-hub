#!/usr/bin/env python3
"""Busca de casos (erros já vistos e soluções) para agentes de IA, com Elasticsearch.

Indexa docs/ai-context/*.md, docs/apex-26.1/*.md (base APEX em pt-BR) e modulos/**/*.md
em unidades pequenas:
  - tipo "caso": cada entrada com **Sintoma:** / **Causa:** / **Correção:** (doc 09),
    cada linha das tabelas "| Sintoma | Causa | Correção |" dos guias Etapas-*.md
    e as seções do doc 10 (cookies/sessão);
  - tipo "doc": as demais seções da documentação.

Uso (na raiz do repo):
  python3 scripts/busca-casos/casos.py indexar
  python3 scripts/busca-casos/casos.py buscar "ORA-01403 no select into da página 13"
  python3 scripts/busca-casos/casos.py buscar "menu não aparece depois de dar o papel" --tipo caso -n 3
  python3 scripts/busca-casos/casos.py buscar "..." --json

Sem Elasticsearch no ar, "buscar" cai num modo offline (pontuação simples em
memória) e avisa. Só usa a stdlib. Endereço: variável ES_URL (padrão
http://localhost:9200). Rode "indexar" de novo sempre que um .md mudar.
"""
import argparse
import hashlib
import json
import math
import os
import pathlib
import re
import sys
import unicodedata
import urllib.error
import urllib.request

RAIZ = pathlib.Path(__file__).resolve().parents[2]
ES_URL = os.environ.get("ES_URL", "http://localhost:9200").rstrip("/")
INDICE = "corlix-casos"
INDICE_APEX = "apex-docs"  # documentação oficial do APEX 26.1 (apex_docs.py)
FONTES = ["docs/ai-context/*.md", "docs/apex-26.1/*.md", "modulos/**/*.md"]
ARQUIVOS_CASO = {"10-erro-400-cookies.md"}  # o arquivo inteiro descreve um caso

RE_CODIGO = re.compile(r"(?<![\w-])(ORA|PLS|PLW|SP2|TNS|APEX|ORDS)-?(\d{3,5})\b", re.I)
RE_CODIGO_APP = re.compile(r"(?<![\w-])-(20\d{3})\b")  # raise_application_error
RE_CRASE = re.compile(r"`([^`\n]{2,80})`")
RE_IDENT = re.compile(r"[A-Za-z_][\w$#.]*")
RE_ROTULO = re.compile(r"\*\*(Sintomas?|Causas?|Correç(?:ão|ões)|Soluç(?:ão|ões)|Prevenção)\b[^*\n]{0,60}:\*\*", re.I)
# Palavras vazias removidas na indexação e na busca. "não" fica de fora de propósito.
STOPWORDS = ["a", "o", "as", "os", "ao", "aos", "de", "da", "do", "das", "dos", "em", "na", "no", "nas",
             "nos", "e", "ou", "que", "com", "para", "pra", "por", "pelo", "pela", "um", "uma", "se",
             "the", "of", "by", "is", "to", "in"]

# Sinônimos aplicados só na busca (já sem acento e em minúsculas).
SINONIMOS = [
    "erro, falha, excecao, problema",
    "pagina, tela",
    "access denied, acesso negado, sem permissao",
    "permissao, autorizacao, authorization, papel, role",
    "colaborador, funcionario, empregado",
    "no data found, nao encontrado, nenhuma linha",
    "invalido, invalid",
    "login, autenticacao",
    "botao, button",
    "regiao, region",
    "processo, process",
    "dynamic action, da, acao dinamica",
    "interactive grid, ig, grade interativa",
    "sessao, session",
    "cadastro, registro",
]

CAMPOS_TEXTO = ["titulo", "secao", "sintoma", "causa", "correcao", "prevencao", "corpo"]
PESOS = {"titulo": 4, "sintoma": 3, "secao": 1.5, "causa": 2, "correcao": 1.2, "prevencao": 1, "corpo": 1}


# ---------------------------------------------------------------- extração

def limpar_md(txt):
    txt = re.sub(r"^\s*```\w*\s*$", "", txt, flags=re.M)
    txt = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", txt)
    txt = txt.replace("**", "").replace("`", "")
    return re.sub(r"[ \t]+", " ", txt).strip()


def codigos(txt):
    achados = {f"{p.upper()}-{n.zfill(5) if p.upper() in ('ORA', 'PLS', 'PLW') else n}"
               for p, n in RE_CODIGO.findall(txt)}
    achados |= {f"ORA-{n}" for n in RE_CODIGO_APP.findall(txt)}
    return sorted(achados)


def identificadores(txt, so_crase=True):
    trechos = RE_CRASE.findall(txt) if so_crase else [txt]
    out = set()
    for t in trechos:
        for tok in RE_IDENT.findall(t):
            if "_" in tok or "." in tok.strip(".") or (tok.isupper() and len(tok) >= 4):
                out.add(tok.strip(".").lower())
    return sorted(out)


def campos_rotulados(corpo):
    """Separa **Sintoma:** / **Causa:** / **Correção:** / **Prevenção:** do corpo."""
    partes = RE_ROTULO.split(corpo)
    if len(partes) < 3:
        return {}
    out = {}
    for rot, txt in zip(partes[1::2], partes[2::2]):
        chave = {"sin": "sintoma", "cau": "causa", "cor": "correcao", "sol": "correcao",
                 "pre": "prevencao"}[rot[:3].lower()]
        out[chave] = (out.get(chave, "") + " " + txt.replace("\n---", "")).strip()
    return out


def modulo_de(rel):
    p = pathlib.PurePosixPath(rel).parts
    return p[1] if p[0] in ("modulos", "docs") else "ai-context"


def ancora(titulo):
    t = re.sub(r"[^\w\s-]", "", titulo.lower()).strip()
    return re.sub(r"\s+", "-", t)


def extrair(caminho):
    rel = caminho.relative_to(RAIZ).as_posix()
    linhas = caminho.read_text(encoding="utf-8").splitlines()
    docs, pilha = [], []  # pilha de (nível, título)
    atual = {"titulo": rel, "linha": 1, "corpo": []}
    cerca = ""  # cerca do bloco de código aberto ("```" ou "````"); vazio = fora de bloco
    tabela = None  # {"cols": n} enquanto dentro de uma tabela Sintoma/Causa/Correção

    def fechar():
        corpo = "\n".join(atual["corpo"]).strip()
        if len(limpar_md(corpo)) < 40:
            return
        rot = campos_rotulados(corpo)
        caso = bool(rot.get("sintoma")) or caminho.name in ARQUIVOS_CASO
        docs.append(montar(rel, atual["titulo"], atual["linha"], [t for _, t in pilha[:-1]],
                           corpo, rot, "caso" if caso else "doc"))

    for i, linha in enumerate(linhas, 1):
        crases = re.match(r"^\s*(`{3,})", linha)
        if crases and not cerca:
            cerca = crases.group(1)
        elif cerca and re.fullmatch(r"\s*`{%d,}\s*" % len(cerca), linha):
            cerca = ""
        em_codigo = bool(cerca)
        m = None if em_codigo else re.match(r"^(#{1,6})\s+(.*)", linha)
        if m:
            fechar()
            nivel, titulo = len(m.group(1)), m.group(2).strip()
            while pilha and pilha[-1][0] >= nivel:
                pilha.pop()
            pilha.append((nivel, titulo))
            atual = {"titulo": titulo, "linha": i, "corpo": []}
            tabela = None
            continue
        if not em_codigo and re.match(r"^\|\s*(Sintoma|Erro|Problema)\s*\|", linha, re.I):
            tabela = {}
            continue
        if tabela is not None:
            if re.match(r"^\|[\s:|-]+\|?\s*$", linha):
                continue
            if linha.startswith("|"):
                cel = [c.strip() for c in linha.strip().strip("|").split("|")]
                cel += [""] * (3 - len(cel))
                rot = {"sintoma": cel[0], "causa": cel[1], "correcao": " | ".join(cel[2:]).strip(" |")}
                secao = [t for _, t in pilha]
                docs.append(montar(rel, limpar_md(cel[0]), i, secao, linha, rot, "caso"))
                continue
            tabela = None
        atual["corpo"].append(linha)
    fechar()
    return docs


def montar(rel, titulo, linha, secao, corpo_md, rot, tipo):
    bruto = " ".join([titulo, corpo_md])
    doc = {
        "tipo": tipo,
        "titulo": limpar_md(titulo)[:300],
        "secao": " › ".join(limpar_md(s) for s in secao),
        "arquivo": rel,
        "linha": linha,
        "ancora": ancora(titulo),
        "modulo": modulo_de(rel),
        "codigos": codigos(bruto),
        "identificadores": identificadores(bruto),
        "sintoma": limpar_md(rot.get("sintoma", "")),
        "causa": limpar_md(rot.get("causa", "")),
        "correcao": limpar_md(rot.get("correcao", "")),
        "prevencao": limpar_md(rot.get("prevencao", "")),
        "corpo": limpar_md(corpo_md),
    }
    doc["id"] = hashlib.sha1(f"{rel}:{linha}:{doc['titulo']}".encode()).hexdigest()[:16]
    return doc


def coletar():
    vistos, docs = set(), []
    for padrao in FONTES:
        for p in sorted(RAIZ.glob(padrao)):
            if p not in vistos:
                vistos.add(p)
                docs.extend(extrair(p))
    return docs


# ---------------------------------------------------------------- Elasticsearch

def es(metodo, caminho, corpo=None, ndjson=False):
    dados = None
    if corpo is not None:
        dados = corpo.encode() if ndjson else json.dumps(corpo).encode()
    req = urllib.request.Request(f"{ES_URL}{caminho}", data=dados, method=metodo, headers={
        "Content-Type": "application/x-ndjson" if ndjson else "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            return json.loads(r.read() or b"{}")
    except urllib.error.HTTPError as e:
        if metodo in ("HEAD", "DELETE") and e.code == 404:
            return None
        raise SystemExit(f"Elasticsearch respondeu {e.code} em {metodo} {caminho}: {e.read().decode()[:800]}")


def es_no_ar():
    try:
        urllib.request.urlopen(ES_URL, timeout=2)
        return True
    except (urllib.error.URLError, OSError):
        return False


def mapeamento():
    texto = {"type": "text", "analyzer": "pt_br", "search_analyzer": "pt_br_busca",
             "fields": {"exato": {"type": "text", "analyzer": "exato"}}}
    return {
        "settings": {
            "number_of_shards": 1, "number_of_replicas": 0,
            "analysis": {
                "filter": {
                    "pt_stem": {"type": "stemmer", "language": "light_portuguese"},
                    "pt_stop": {"type": "stop", "stopwords": STOPWORDS},
                    "pt_sinonimos": {"type": "synonym_graph", "synonyms": SINONIMOS, "lenient": True},
                },
                "normalizer": {"minusculo": {"type": "custom", "filter": ["lowercase", "asciifolding"]}},
                "analyzer": {
                    "pt_br": {"tokenizer": "standard", "filter": ["lowercase", "asciifolding", "pt_stop", "pt_stem"]},
                    "pt_br_busca": {"tokenizer": "standard",
                                    "filter": ["lowercase", "asciifolding", "pt_stop", "pt_sinonimos", "pt_stem"]},
                    "exato": {"tokenizer": "standard", "filter": ["lowercase", "asciifolding", "pt_stop"]},
                },
            },
        },
        "mappings": {"properties": {
            **{c: texto for c in CAMPOS_TEXTO},
            "tipo": {"type": "keyword"}, "modulo": {"type": "keyword"},
            "arquivo": {"type": "keyword"}, "linha": {"type": "integer"}, "ancora": {"type": "keyword"},
            "codigos": {"type": "keyword", "normalizer": "minusculo"},
            "identificadores": {"type": "keyword", "normalizer": "minusculo"},
        }},
    }


def cmd_indexar(_args):
    if not es_no_ar():
        raise SystemExit(f"Elasticsearch fora do ar em {ES_URL}. Suba com:\n"
                         "  docker compose -f scripts/busca-casos/docker-compose.yml up -d")
    docs = coletar()
    es("DELETE", f"/{INDICE}")
    es("PUT", f"/{INDICE}", mapeamento())
    linhas = []
    for d in docs:
        linhas.append(json.dumps({"index": {"_index": INDICE, "_id": d["id"]}}))
        linhas.append(json.dumps({k: v for k, v in d.items() if k != "id"}, ensure_ascii=False))
    r = es("POST", "/_bulk?refresh=true", "\n".join(linhas) + "\n", ndjson=True)
    if r.get("errors"):
        erro = next(i["index"]["error"] for i in r["items"] if "error" in i["index"])
        raise SystemExit(f"Falha ao indexar: {erro}")
    casos = sum(d["tipo"] == "caso" for d in docs)
    print(f"Índice {INDICE}: {len(docs)} trechos ({casos} casos, {len(docs) - casos} seções de doc).")


def consulta_es(texto, tipo, modulo, n, fonte="casos"):
    cods = [c.lower() for c in codigos(texto)]
    idents = identificadores(texto, so_crase=False)
    campos = [f"{c}^{PESOS[c]}" for c in CAMPOS_TEXTO]
    exatos = [f"{c}.exato^{PESOS[c]}" for c in CAMPOS_TEXTO]
    relevancia = [
        {"multi_match": {"query": texto, "fields": campos, "type": "best_fields",
                         "tie_breaker": 0.3, "minimum_should_match": "2<60%"}},
        {"multi_match": {"query": texto, "fields": campos, "type": "phrase", "slop": 3, "boost": 2}},
        {"multi_match": {"query": texto, "fields": exatos, "type": "best_fields",
                         "fuzziness": "AUTO", "prefix_length": 2, "boost": 0.6}},
    ]
    if cods:
        relevancia.append({"terms": {"codigos": cods, "boost": 15}})
    if idents:
        relevancia.append({"terms": {"identificadores": idents, "boost": 6}})
    if fonte != "casos":  # documentação oficial: título e código pesam mais
        relevancia.append({"multi_match": {"query": texto, "fields": ["titulo^6", "secao"],
                                           "type": "best_fields", "boost": 1.5}})
    filtros = [{"term": {"tipo": tipo}}] if tipo else []
    if modulo:
        filtros.append({"term": {"modulo": modulo}})
    return {
        "size": n,
        "query": {"bool": {
            "must": [{"bool": {"should": relevancia, "minimum_should_match": 1}}],
            "should": [{"term": {"tipo": {"value": "caso", "boost": 2}}},
                       # em empate, o que é do projeto vem antes da base genérica do APEX
                       {"constant_score": {"filter": {"bool": {"must_not": [
                           {"terms": {"modulo": ["apex-26.1"]}}, {"term": {"tipo": "apex"}}]}}, "boost": 12}}],
            "filter": filtros,
        }},
        "highlight": {"pre_tags": ["»"], "post_tags": ["«"], "fragment_size": 180,
                      "number_of_fragments": 1, "require_field_match": False,
                      "fields": {c: {} for c in ("sintoma", "causa", "correcao", "corpo")}},
        "_source": {"excludes": ["identificadores"]},
    }


# ---------------------------------------------------------------- modo offline

def _termos(txt):
    txt = unicodedata.normalize("NFKD", txt.lower())
    txt = "".join(ch for ch in txt if not unicodedata.combining(ch))
    return [re.sub(r"(oes|aes|ais|eis|s)$", "", t) or t for t in re.findall(r"\w+", txt)
            if len(t) > 1 and t not in STOPWORDS]


def busca_offline(texto, tipo, modulo, n):
    docs = [d for d in coletar() if (not tipo or d["tipo"] == tipo) and (not modulo or d["modulo"] == modulo)]
    q = set(_termos(texto))
    cods, idents = set(codigos(texto)), set(identificadores(texto, so_crase=False))
    df = {}
    tf = []
    for d in docs:
        campos = {c: _termos(d[c]) for c in CAMPOS_TEXTO}
        tf.append(campos)
        for t in q & {t for v in campos.values() for t in v}:
            df[t] = df.get(t, 0) + 1
    res = []
    for d, campos in zip(docs, tf):
        s = 0.0
        for c, toks in campos.items():
            for t in q:
                f = toks.count(t)
                if f:
                    s += PESOS[c] * math.log(1 + len(docs) / df[t]) * (1 + math.log(f))
        s += 15 * len(cods & set(d["codigos"])) + 6 * len(idents & set(d["identificadores"]))
        if s:
            res.append((s * (1.3 if d["tipo"] == "caso" else 1), d))
    res.sort(key=lambda x: -x[0])
    return [{"score": round(s, 2), **d, "destaque": ""} for s, d in res[:n]]


# ---------------------------------------------------------------- saída

def cmd_buscar(args):
    texto = " ".join(args.texto)
    indices = {"casos": INDICE, "apex": INDICE_APEX, "todas": f"{INDICE},{INDICE_APEX}"}[args.fonte]
    if es_no_ar():
        if args.fonte != "casos" and es("HEAD", f"/{INDICE_APEX}") is None:
            raise SystemExit("Índice apex-docs não existe. Rode: apex_docs.py baixar && apex_docs.py extrair "
                             "&& apex_docs.py indexar")
        r = es("POST", f"/{indices}/_search?ignore_unavailable=true",
               consulta_es(texto, args.tipo, args.modulo, args.n, args.fonte))
        res = []
        for h in r["hits"]["hits"]:
            hl = h.get("highlight", {})
            src = {c: "" for c in ("secao", "sintoma", "causa", "correcao", "prevencao")} | {"codigos": []}
            src |= h["_source"]
            res.append({"score": round(h["_score"], 2), **src,
                        "destaque": next((hl[c][0] for c in ("sintoma", "causa", "correcao", "corpo") if c in hl), "")})
        motor = "elasticsearch"
    elif args.fonte != "casos":
        raise SystemExit(f"A documentação oficial do APEX só é buscável com o Elasticsearch no ar ({ES_URL}).")
    else:
        print(f"[aviso] Elasticsearch fora do ar em {ES_URL}; usando modo offline (menos preciso).",
              file=sys.stderr)
        res, motor = busca_offline(texto, args.tipo, args.modulo, args.n), "offline"

    if args.json:
        print(json.dumps({"motor": motor, "consulta": texto, "resultados": res}, ensure_ascii=False, indent=2))
        return
    if not res:
        print("Nenhum caso encontrado. Tente outras palavras, o código do erro (ex.: ORA-01403) ou --tipo doc.")
        return
    def corte(s, k=280):
        s = re.sub(r"\s+", " ", s)
        return (s[:k] + "…") if len(s) > k else s
    for i, d in enumerate(res, 1):
        print(f"{i}. [{d['tipo']}] {d['titulo']}  (score {d['score']})")
        if d.get("url"):
            print(f"   {d['url']}  · {d['secao']}")
            print(f"   Texto local: {d['arquivo']}")
        else:
            print(f"   {d['arquivo']}:{d['linha']}" + (f"  · {d['secao']}" if d["secao"] else ""))
        if d["codigos"]:
            print(f"   Códigos: {', '.join(d['codigos'])}")
        for rot, c in (("Sintoma", "sintoma"), ("Causa", "causa"), ("Correção", "correcao"), ("Prevenção", "prevencao")):
            if d[c]:
                print(f"   {rot}: {corte(d[c])}")
        if not any(d[c] for c in ("sintoma", "causa", "correcao")):
            print(f"   {corte(d['destaque'] or d['corpo'])}")
        print()


def main():
    ap = argparse.ArgumentParser(description="Busca de casos para agentes de IA (Elasticsearch).")
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("indexar", help="(re)cria o índice a partir dos .md").set_defaults(f=cmd_indexar)
    b = sub.add_parser("buscar", help="busca casos e trechos de documentação")
    b.add_argument("texto", nargs="+", help="mensagem de erro, sintoma ou pergunta")
    b.add_argument("-n", type=int, default=5, help="quantidade de resultados (padrão 5)")
    b.add_argument("--tipo", choices=["caso", "doc", "apex"], help="restringe a casos, doc do projeto ou doc oficial")
    b.add_argument("--fonte", choices=["casos", "apex", "todas"], default="casos",
                   help="casos = docs do projeto (padrão); apex = documentação oficial do APEX 26.1; todas = ambos")
    b.add_argument("--modulo", help="ex.: historico-carreira, perfis-acesso, ai-context")
    b.add_argument("--json", action="store_true", help="saída JSON para agentes")
    b.set_defaults(f=cmd_buscar)
    args = ap.parse_args()
    args.f(args)


if __name__ == "__main__":
    main()
