#!/usr/bin/env python3
"""Documentação oficial do Oracle APEX 26.1 no Elasticsearch, para os agentes de IA.

Baixa o zip oficial da biblioteca (docs.oracle.com), converte cada página HTML em
Markdown e indexa por seção no índice "apex-docs", com o link oficial de cada trecho.
O texto é da Oracle: fica só no cache local (.cache/apex-docs/, fora do Git) e no índice.

Uso (na raiz do repo, com o Elasticsearch de scripts/busca-casos no ar):
  python3 scripts/busca-casos/apex_docs.py baixar     # ~325 MB, uma vez
  python3 scripts/busca-casos/apex_docs.py extrair    # HTML -> .cache/apex-docs/md/<livro>/<pagina>.md
  python3 scripts/busca-casos/apex_docs.py indexar    # (re)cria o índice apex-docs
  python3 scripts/busca-casos/casos.py buscar "apex_collection add_member" --fonte apex

Só usa a stdlib.
"""
import argparse
import html
import json
import pathlib
import re
import shutil
import sys
import urllib.request
import zipfile
from html.parser import HTMLParser

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import casos  # noqa: E402

VERSAO = "26.1"
BASE_URL = f"https://docs.oracle.com/en/database/oracle/apex/{VERSAO}"
ZIP_URL = f"{BASE_URL}/zip/apex_{VERSAO}.zip"
CACHE = casos.RAIZ / ".cache" / "apex-docs"
INDICE = "apex-docs"
LIVROS = {
    "htmdb": "App Builder User's Guide",
    "aeapi": "API Reference",
    "aexjs": "JavaScript API Reference",
    "apxln": "APEXlang API Reference",
    "apxdc": "Developer's Companion",
    "aeadm": "Administration Guide",
    "aeutl": "SQL Workshop Guide",
    "htmig": "Installation Guide",
    "htmrn": "Release Notes",
    "aeeug": "End User's Guide",
    "aeacc": "Accessibility Guide",
    "apxdr": "Data Reporter Guide",
    "aelim": "Licensing Information",
}
BLOCO = {"p", "div", "section", "article", "li", "dt", "dd", "table", "tr", "br", "figure", "figcaption",
         "dl", "ul", "ol", "header", "blockquote"}
IGNORAR = {"script", "style", "nav", "footer", "noscript", "button"}


class Conversor(HTMLParser):
    """HTML da Oracle (DITA) ou JSDoc -> Markdown simples."""

    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.out, self.em_pre, self.listas = [], 0, []
        self.ign_tag, self.ign_n = None, 0
        self.titulo, self.meta = "", {}
        self.na_tabela, self.celulas, self.linha_tab = 0, [], None
        self.dentro = False  # dentro de <article> (DITA) ou <div id="main"> (JSDoc)

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if tag == "meta" and a.get("name") in ("DC.Title", "description", "keywords"):
            self.meta[a["name"]] = a.get("content", "")
        if tag == "article" or (tag == "div" and a.get("id") == "main"):
            self.dentro = True
        if self.ign_tag:
            self.ign_n += tag == self.ign_tag
            return
        classe = a.get("class") or ""
        if tag in IGNORAR or "familylinks" in classe or "noscript" in classe or a.get("id") == "quick-nav":
            self.ign_tag, self.ign_n = tag, 1
            return
        if not self.dentro:
            return
        if re.fullmatch(r"h[1-6]", tag):
            self.out.append("\n\n" + "#" * int(tag[1]) + " ")
        elif tag == "pre":
            self.em_pre += 1
            self.out.append("\n\n```\n")
        elif tag == "code" and not self.em_pre:
            self.out.append("`")
        elif tag in ("ul", "ol"):
            self.listas.append(tag)
        elif tag == "li":
            self.out.append("\n" + "  " * (len(self.listas) - 1) + ("1. " if self.listas[-1:] == ["ol"] else "- "))
        elif tag == "table":
            self.na_tabela += 1
            self.out.append("\n\n")
        elif tag == "tr":
            self.linha_tab = []
        elif tag in ("td", "th"):
            self.celulas = []
            self.out_cel = len(self.out)
        elif tag in ("strong", "b"):
            self.out.append("**")
        elif tag in BLOCO:
            self.out.append("\n\n")

    def handle_endtag(self, tag):
        if self.ign_tag:
            if tag == self.ign_tag:
                self.ign_n -= 1
                if not self.ign_n:
                    self.ign_tag = None
            return
        if not self.dentro:
            return
        if tag == "article":
            self.dentro = False
        if re.fullmatch(r"h[1-6]", tag):
            self.out.append("\n\n")
        elif tag == "pre":
            self.em_pre -= 1
            self.out.append("\n```\n\n")
        elif tag == "code" and not self.em_pre:
            self.out.append("`")
        elif tag in ("ul", "ol") and self.listas:
            self.listas.pop()
            self.out.append("\n")
        elif tag in ("td", "th") and self.linha_tab is not None:
            cel = re.sub(r"\s+", " ", "".join(self.out[self.out_cel:])).strip().replace("|", "\\|")
            del self.out[self.out_cel:]
            self.linha_tab.append(cel)
        elif tag == "tr" and self.linha_tab is not None:
            if any(self.linha_tab):
                self.out.append("| " + " | ".join(self.linha_tab) + " |\n")
            self.linha_tab = None
        elif tag == "table":
            self.na_tabela -= 1
            self.out.append("\n")
        elif tag in ("strong", "b"):
            self.out.append("**")
        elif tag in BLOCO:
            self.out.append("\n\n")

    def handle_data(self, data):
        if self.lasttag == "title" and not self.titulo:
            self.titulo = data.strip()
        if self.ign_tag or not self.dentro:
            return
        self.out.append(data if self.em_pre else re.sub(r"\s+", " ", data))

    def markdown(self):
        txt = "".join(self.out).replace("****", "")
        txt = re.sub(r"[ \t]+\n", "\n", txt)
        linhas, anterior_tab = [], False
        for l in txt.split("\n"):
            tab = l.lstrip().startswith("| ")
            if tab:
                l = l.lstrip()
                if not anterior_tab:  # 1ª linha da tabela vira cabeçalho
                    linhas += ["", l, "|" + "---|" * l.count(" | ") + "---|"]
                    anterior_tab = True
                    continue
            elif anterior_tab and l.strip() == "":
                continue
            elif anterior_tab:
                linhas.append("")
            anterior_tab = tab
            linhas.append(l)
        txt = re.sub(r"\n{3,}", "\n\n", "\n".join(linhas))
        return txt.strip()


def converter(caminho):
    p = Conversor()
    p.feed(caminho.read_text(encoding="utf-8", errors="replace"))
    if not "".join(p.out).strip():  # páginas sem <article>: usa o <body> inteiro
        p2 = Conversor()
        p2.dentro = True
        p2.feed(re.sub(r"(?s)^.*?<body[^>]*>", "", caminho.read_text(encoding="utf-8", errors="replace")))
        p2.meta, p2.titulo = p.meta, p.titulo
        p = p2
    titulo = p.meta.get("DC.Title") or re.sub(r",? Release [\d.]+$", "", p.titulo) or caminho.stem
    return html.unescape(titulo), p.meta.get("description", ""), p.meta.get("keywords", ""), p.markdown()


# ---------------------------------------------------------------- comandos

def raiz_zip():
    achados = sorted((CACHE / "src").glob("apex_*/content"))
    if not achados:
        raise SystemExit("Rode antes: python3 scripts/busca-casos/apex_docs.py baixar")
    return achados[-1]


def cmd_baixar(_a):
    CACHE.mkdir(parents=True, exist_ok=True)
    destino = CACHE / f"apex_{VERSAO}.zip"
    if not destino.exists():
        print(f"Baixando {ZIP_URL} …")
        req = urllib.request.Request(ZIP_URL, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=600) as r, open(destino, "wb") as f:
            shutil.copyfileobj(r, f)
    shutil.rmtree(CACHE / "src", ignore_errors=True)
    with zipfile.ZipFile(destino) as z:
        for m in z.namelist():  # proteção contra caminhos fora da pasta
            if m.startswith("/") or ".." in pathlib.PurePosixPath(m).parts:
                raise SystemExit(f"Entrada suspeita no zip: {m}")
        z.extractall(CACHE / "src")
    print(f"Extraído em {raiz_zip()}")


def cmd_extrair(_a):
    raiz, md = raiz_zip(), CACHE / "md"
    shutil.rmtree(md, ignore_errors=True)
    total, sumario = 0, {}
    for livro in LIVROS:
        paginas = sorted((raiz / livro).glob("*.html"))
        (md / livro).mkdir(parents=True, exist_ok=True)
        itens, convertidas, capitulos = [], [], {}
        for p in paginas:
            titulo, desc, chaves, corpo = converter(p)
            num = re.match(r"#+ ((\d+|[A-Z])(?:\.\d+)*) (.+)", corpo)
            if num and num.group(1) == num.group(2):  # "## 15 APEX_COLLECTION" abre o capítulo 15
                capitulos[num.group(1)] = num.group(3).strip()
            convertidas.append((p, titulo, desc, corpo, num.group(2) if num else None))
        for p, titulo, desc, corpo, cap in convertidas:
            if len(corpo) < 80:
                continue
            url = f"{BASE_URL}/{livro}/{p.name}"
            capitulo = capitulos.get(cap, "")
            (md / livro / f"{p.stem}.md").write_text(
                f"<!-- fonte: {url} | capitulo: {capitulo} -->\n# {titulo}\n\n"
                f"{('> ' + desc + chr(10) + chr(10)) if desc else ''}{corpo}\n", encoding="utf-8")
            itens.append({"pagina": p.stem, "titulo": titulo, "capitulo": capitulo, "descricao": desc,
                          "chars": len(corpo)})
            total += 1
        sumario[livro] = itens
        print(f"{livro:6} {LIVROS[livro]:32} {len(itens):5} páginas")
    (md / "sumario.json").write_text(json.dumps(sumario, ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"Total: {total} páginas em {md}")


def trechos_da_pagina(livro, arq):
    """Divide a página em seções (h1-h4); cada seção vira um documento."""
    texto = arq.read_text(encoding="utf-8")
    m = re.match(r"<!-- fonte: (\S+) \| capitulo: (.*?) -->", texto)
    url, capitulo = m.group(1), m.group(2).strip()
    linhas = texto.splitlines()[1:]
    pagina_titulo = linhas[0].lstrip("# ").strip() if linhas else arq.stem
    pacote = capitulo if re.fullmatch(r"APEX_\w+", capitulo) else ""
    if pacote and not pagina_titulo.upper().startswith(pacote):
        pagina_titulo = f"{pacote}.{pagina_titulo}"  # "APEX_COLLECTION.ADD_MEMBER Procedure"
    trilha = " › ".join(x for x in (LIVROS[livro], capitulo, pagina_titulo) if x)
    secoes, atual, ancora, em_cod = [], {"titulo": pagina_titulo, "corpo": []}, "", False
    for l in linhas[1:]:
        if l.startswith("```"):
            em_cod = not em_cod
        m = None if em_cod else re.match(r"^(#{1,4})\s+(.*)", l)
        if m and sum(len(x) for x in atual["corpo"]) > 400:
            secoes.append(atual)
            atual = {"titulo": m.group(2).strip(), "corpo": []}
        elif m:
            atual["corpo"].append(l)
        else:
            atual["corpo"].append(l)
    secoes.append(atual)
    for i, s in enumerate(secoes):
        corpo = "\n".join(s["corpo"]).strip()
        if len(corpo) < 60:
            continue
        for parte, pedaco in enumerate(_fatiar(corpo, 6000)):
            yield {
                "tipo": "apex", "livro": livro, "livro_nome": LIVROS[livro], "pagina": arq.stem,
                "titulo": (pagina_titulo if i == 0 else s["titulo"])[:300], "secao": trilha,
                "url": url, "arquivo": f".cache/apex-docs/md/{livro}/{arq.name}", "linha": 0,
                "codigos": casos.codigos(pedaco),
                "identificadores": _idents_api(f"{pedaco} {s['titulo']} {pagina_titulo.split(' ')[0]}"),
                "corpo": pedaco, "_id": f"{livro}:{arq.stem}:{i}:{parte}",
            }


def _fatiar(txt, tam):
    if len(txt) <= tam:
        return [txt]
    partes, atual = [], ""
    for par in txt.split("\n\n"):
        if len(atual) + len(par) > tam and atual:
            partes.append(atual)
            atual = ""
        atual += par + "\n\n"
    return partes + [atual] if atual else partes


def _idents_api(txt):
    """APEX_COLLECTION.ADD_MEMBER, apex.item, P1_X, apex_web_service etc."""
    achados = set(re.findall(r"\b(?:apex|wwv|htmldb|owa|htp|dbms|utl)[_.][\w.$#]+", txt, re.I))
    achados |= set(casos.identificadores(txt))
    return sorted({a.strip(".").lower() for a in achados if len(a) < 80})[:200]


def mapeamento():
    texto = {"type": "text", "analyzer": "en_apex",
             "fields": {"exato": {"type": "text", "analyzer": "exato"}}}
    return {
        "settings": {
            "number_of_shards": 1, "number_of_replicas": 0,
            "analysis": {
                "filter": {
                    "en_stem": {"type": "stemmer", "language": "light_english"},
                    "en_stop": {"type": "stop", "stopwords": "_english_"},
                    "en_poss": {"type": "stemmer", "language": "possessive_english"},
                },
                "normalizer": {"minusculo": {"type": "custom", "filter": ["lowercase", "asciifolding"]}},
                "analyzer": {
                    "en_apex": {"tokenizer": "standard",
                                "filter": ["en_poss", "lowercase", "asciifolding", "en_stop", "en_stem"]},
                    "exato": {"tokenizer": "standard", "filter": ["lowercase", "asciifolding"]},
                },
            },
        },
        "mappings": {"properties": {
            "titulo": texto, "secao": texto, "corpo": texto,
            **{k: {"type": "keyword"} for k in ("tipo", "livro", "livro_nome", "pagina", "url", "arquivo")},
            "linha": {"type": "integer"},
            "codigos": {"type": "keyword", "normalizer": "minusculo"},
            "identificadores": {"type": "keyword", "normalizer": "minusculo"},
        }},
    }


def cmd_indexar(_a):
    if not casos.es_no_ar():
        raise SystemExit(f"Elasticsearch fora do ar em {casos.ES_URL}.")
    md = CACHE / "md"
    if not md.exists():
        raise SystemExit("Rode antes: apex_docs.py baixar && apex_docs.py extrair")
    casos.es("DELETE", f"/{INDICE}")
    casos.es("PUT", f"/{INDICE}", mapeamento())
    lote, total = [], 0

    def enviar():
        nonlocal lote
        if lote:
            r = casos.es("POST", "/_bulk", "\n".join(lote) + "\n", ndjson=True)
            if r.get("errors"):
                erro = next(i["index"]["error"] for i in r["items"] if "error" in i["index"])
                raise SystemExit(f"Falha ao indexar: {erro}")
            lote = []

    for livro in LIVROS:
        for arq in sorted((md / livro).glob("*.md")):
            for d in trechos_da_pagina(livro, arq):
                lote.append(json.dumps({"index": {"_index": INDICE, "_id": d.pop("_id")}}))
                lote.append(json.dumps(d, ensure_ascii=False))
                total += 1
                if len(lote) >= 1000:
                    enviar()
    enviar()
    casos.es("POST", f"/{INDICE}/_refresh")
    print(f"Índice {INDICE}: {total} trechos.")


def main():
    ap = argparse.ArgumentParser(description="Documentação oficial do APEX 26.1 no Elasticsearch.")
    sub = ap.add_subparsers(dest="cmd", required=True)
    for nome, f, ajuda in (("baixar", cmd_baixar, "baixa e extrai o zip oficial"),
                           ("extrair", cmd_extrair, "converte HTML em Markdown"),
                           ("indexar", cmd_indexar, "(re)cria o índice apex-docs")):
        sub.add_parser(nome, help=ajuda).set_defaults(f=f)
    a = ap.parse_args()
    a.f(a)


if __name__ == "__main__":
    main()
