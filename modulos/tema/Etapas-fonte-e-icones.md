# Fonte e ícones do protótipo · passo a passo no APEX

O protótipo (`pen_dev/`, arquivo `corlixhub.pen`) usa a fonte **Figtree** e os ícones **Lucide**. Este guia leva os dois para o app inteiro no **APEX 26.1.5**, sem mexer em páginas.

### Como funciona

- As fontes ficam nos *Static Application Files*, na raiz (ao lado do `corlix-tema.css`). Não há dependência de CDN.
- A última seção do `corlix-tema.css` declara as `@font-face` e troca `--a-base-font-family` (a variável do Redwood) pela Figtree. Todo componente do Universal Theme segue essa variável.
- O app continua usando classes Font APEX (`fa-home`, `fa-users`…) no menu, nos botões e nos packages. O mesmo CSS troca o glifo de cada classe mapeada pelo equivalente Lucide. Classe fora da lista continua Font APEX.
- O `lucide.woff2` é a fonte do `lucide-static@0.460.0` reduzida aos ícones mapeados (12 KB em vez de 220 KB).

| Arquivo (em `corlixhub/shared-components/static-files/`) | Origem |
|---|---|
| `figtree-latin.woff2` / `figtree-latin-ext.woff2` | `@fontsource-variable/figtree@5.1.1` (SIL OFL 1.1), pesos 300 a 900 |
| `lucide.woff2` | `lucide-static@0.460.0/font/lucide.woff2` (ISC), reduzida com `pyftsubset` |
| `corlix-tema.css` / `.min.css` | Seção "Fonte e ícones do protótipo" no fim do arquivo |

## 1. Subir os arquivos

*Shared Components › Static Application Files › Create File* (confirmar no 26.1.5). Para cada fonte:

| File Name | Arquivo |
|---|---|
| `figtree-latin.woff2` | `static-files/figtree-latin.woff2` |
| `figtree-latin-ext.woff2` | `static-files/figtree-latin-ext.woff2` |
| `lucide.woff2` | `static-files/lucide.woff2` |

Deixe o campo de diretório vazio: o CSS procura `url("lucide.woff2")` relativo a ele mesmo, então as fontes precisam ficar na mesma pasta do `corlix-tema.css` (a raiz).

Depois substitua `corlix-tema.css` e `corlix-tema.min.css`. Suba as fontes **antes** ou junto com o CSS: com o CSS novo e sem as fontes, os ícones mapeados aparecem como quadrados.

## 2. Teste

Recarregue com Ctrl+Shift+R e confira:

1. Textos em Figtree em todas as páginas (o "g" de "Segunda-feira" tem a perna aberta, diferente da Oracle Sans).
2. Menu: casa (Início), megafone (Comunicados), dois balões (Chat), pessoas (Pessoas), maleta (Minha carreira), escudo com check (Administração).
3. Header: lupa, sino e seta do usuário em traço fino.
4. Início: atalhos com documento, relógio e headset; botões Chat e E-mail; bolo em Aniversariantes.
5. DevTools › Network, filtro `woff2`: `figtree-latin.woff2` e `lucide.woff2` com status 200.

### Se não funcionar

| Sintoma | Causa provável | Correção |
|---|---|---|
| Ícones viram quadrados (□) e a fonte continua a Oracle Sans | `corlix-tema.css` novo no app, mas as fontes não estão nos Static Application Files, ou estão em outra pasta (404 em `.../files/static/v.../*.woff2`) | Passo 1, com as fontes na raiz, ao lado do `corlix-tema.css` |
| Ícones quadrados mesmo com as fontes no app | O CSS no app é uma versão que procurava `fontes/*.woff2` | Suba o `corlix-tema.css` e o `.min.css` atuais (`url("lucide.woff2")`, sem pasta) |
| Um ícone específico continua no estilo Font APEX | A classe dele não está no mapa | Seção "Incluir um ícone" abaixo |
| Um ícone aparece errado (glifo de outro ícone) | Código do glifo errado na regra `content`, ou `lucide.woff2` gerado sem esse código | Confira o código no `lucide.css` da 0.460.0 e gere a fonte de novo |
| Texto em Figtree só em parte da página | Região com `style="font-family:..."` ou CSS de módulo com fonte fixa | Troque por `font-family: inherit` |

## 3. Incluir um ícone

1. Escolha o nome Lucide em <https://lucide.dev/icons> e pegue o código em `lucide-static@0.460.0/font/lucide.css` (ex.: `.icon-house:before { content: "\e0f8"; }`).
2. No `corlix-tema.css`, inclua `.fa-<classe>` na lista do `:is(...)` e a regra `.apex-icons-fontapex .fa.fa-<classe>::before { content: "\<código>"; }`. Repita no `.min.css`.
3. Gere a fonte com todos os códigos das regras `content`:

```sh
U=$(grep -o 'content: *"\\[0-9a-f]*"' corlix-tema.css | grep -o '[0-9a-f]\{4\}' | sort -u | sed 's/^/U+/' | paste -sd, -)
pyftsubset lucide.woff2 --unicodes="$U" --flavor=woff2 --no-hinting --layout-features='' --output-file=lucide-reduzida.woff2
```

(o `lucide.woff2` de entrada é o completo, baixado do `lucide-static@0.460.0`, numa pasta à parte; renomeie a saída para `lucide.woff2` antes de subir. O `pyftsubset` vem do pacote `fonttools`.)

4. Suba o `lucide.woff2` novo e os dois CSS de novo.
