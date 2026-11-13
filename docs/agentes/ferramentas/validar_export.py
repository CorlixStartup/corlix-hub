#!/usr/bin/env python3
"""Compara um export APEXlang de página com o checklist do guia do módulo.

Uso:
    python3 docs/agentes/ferramentas/validar_export.py <guia Etapas-*.md> <export.apx | -> [--pagina N]

O guia traz um ou mais blocos cercados por ```export-check (um por página).
Cada linha do bloco é uma regra:

    pagina: 17                                  # a que página o bloco se refere
    <componente> | <texto esperado>             # o bloco do componente tem uma linha que contém o texto
    <componente> | !<texto proibido>            # nenhuma linha do bloco contém o texto
    <componente> | ?                            # o componente existe
    !<componente>                               # o componente não existe
    # comentário

<componente> é o cabeçalho como aparece no export, sem o "(":
`page 17`, `pageItem P17_TITULO`, `validation imagem-png-ou-jpg`, `process fechar`,
`region aviso`, `button next`, `dynamicAction público`, `computation p17-id-departamento`.

Saída: uma linha por regra (OK/FALHA) e um resumo. Código de saída 0 se tudo
passar, 1 se alguma regra falhar, 2 em erro de uso.
"""
import re
import sys
import unicodedata


def norm(s):
    return unicodedata.normalize("NFC", s).strip()


def blocos_checklist(guia_txt):
    """Devolve {pagina: [regras]} a partir dos blocos ```export-check."""
    out = {}
    for m in re.finditer(r"```export-check\s*\n(.*?)```", guia_txt, re.S):
        pagina, regras = None, []
        for n, linha in enumerate(m.group(1).splitlines(), 1):
            l = linha.strip()
            if not l or l.startswith("#"):
                continue
            if l.lower().startswith("pagina:") or l.lower().startswith("página:"):
                pagina = l.split(":", 1)[1].strip()
                continue
            regras.append(l)
        out.setdefault(pagina, []).extend(regras)
    return out


def componentes(export_txt):
    """Mapeia 'tipo nome' -> texto do bloco, pelo cabeçalho `tipo nome (` e o `)` na mesma indentação."""
    linhas = export_txt.splitlines()
    comp = {}
    cab = re.compile(r"^(\s*)([A-Za-z]+)\s+(\S+)\s*\($")
    for i, linha in enumerate(linhas):
        m = cab.match(linha)
        if not m:
            continue
        ind = m.group(1)
        chave = norm(f"{m.group(2)} {m.group(3)}")
        corpo = []
        for j in range(i + 1, len(linhas)):
            if linhas[j].rstrip() == f"{ind})":
                break
            corpo.append(linhas[j])
        comp.setdefault(chave, "\n".join(corpo))
    return comp


def avaliar(regra, comp):
    if "|" not in regra:
        if regra.startswith("!"):
            nome = norm(regra[1:])
            return nome not in comp, f"{nome} não existe" if nome not in comp else f"{nome} ainda existe"
        return False, "regra sem '|'"
    nome, esperado = (norm(x) for x in regra.split("|", 1))
    if nome not in comp:
        return False, f"{nome} não encontrado no export"
    if esperado == "?":
        return True, "existe"
    linhas = [norm(l) for l in comp[nome].splitlines()]
    if esperado.startswith("!"):
        txt = esperado[1:].strip()
        achou = [l for l in linhas if txt in l]
        return (not achou), ("ausente" if not achou else f"encontrado: {achou[0]}")
    achou = [l for l in linhas if esperado in l]
    if achou:
        return True, achou[0]
    chave = esperado.split(":", 1)[0] + ":" if ":" in esperado else None
    atual = [l for l in linhas if chave and l.startswith(chave)]
    return False, ("no export: " + atual[0]) if atual else "ausente no export"


def main(argv):
    args = [a for a in argv if not a.startswith("--")]
    pagina = None
    if "--pagina" in argv:
        pagina = argv[argv.index("--pagina") + 1]
        args.remove(pagina)
    if len(args) != 2:
        print(__doc__)
        return 2
    guia = open(args[0], encoding="utf-8").read()
    export = sys.stdin.read() if args[1] == "-" else open(args[1], encoding="utf-8").read()

    if pagina is None:
        m = re.search(r"^\s*page\s+(\d+)\s*\($", export, re.M)
        pagina = m.group(1) if m else None
    checks = blocos_checklist(guia)
    regras = checks.get(pagina) or (checks.get(None) if len(checks) == 1 else None)
    if not regras:
        print(f"Nenhum bloco ```export-check para a página {pagina} em {args[0]}.")
        print(f"Páginas com checklist: {', '.join(str(k) for k in checks) or 'nenhuma'}")
        return 2

    comp = componentes(export)
    falhas = 0
    print(f"Página {pagina} · {len(regras)} regras · {args[0]}\n")
    for r in regras:
        ok, det = avaliar(r, comp)
        falhas += not ok
        print(f"{'OK   ' if ok else 'FALHA'} {r}\n      {det}")
    print(f"\n{len(regras) - falhas}/{len(regras)} ok" + ("" if not falhas else f" · {falhas} falha(s)"))
    return 1 if falhas else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
