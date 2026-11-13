# Fluxo · Escrever ou corrigir um guia de Builder

**Quando:** a mudança na app precisa ser feita pelo time no Builder (o agente não edita `corlixhub/`). O guia é `modulos/<modulo>/Etapas-<assunto>.md`.

## Antes de escrever

1. Leia o [`11 · Padrões de páginas`](../../ai-context/11-padroes-de-paginas.md) e a página de referência equivalente (ficha em [`docs/ai-context/paginas/`](../../ai-context/paginas/)).
2. Protótipo: `pen_dev/<tela>.png` e a descrição no [`07`](../../ai-context/07-design-pen-dev.md). Se não existir, pergunte.
3. Confira o template e os slots reais no export da página antes de propor região ou posição ([`03`](../../ai-context/03-componentes-compartilhados.md) §9).
4. Atributo do APEX que você não tem certeza que existe no 26.1.5: procure em `docs/apex-26.1/`; sem confirmação, marque "(confirmar no 26.1.5)" e peça print se o time não achar. Já aconteceu de o guia pedir atributo inexistente (*File Types* no Image Upload, *Display as Pill Button* no Radio Group).

## Formato

- Passos numerados, cada um com **onde clicar** e uma tabela `Seção | Atributo | Valor`.
- Valores exatos em `código`. Diga o que **não** usar quando houver armadilha conhecida (ex.: *Column CSS Classes*, não *Advanced › CSS Classes*; *Default* **Static**, não **Item**).
- SQL e PL/SQL completos, prontos para colar. Lógica nova vai em package `pkg_<modulo>_ui`, com chamada curta no Builder.
- CSS e JS em arquivos do módulo (`<m>.css` + `.min.css` em sincronia, publicados em `modulos/<m>/` nos *Static Application Files*). Nada de CSS inline.
- Depois dos passos: **No export, procure** (o que deve aparecer no `.apx`) e o bloco `export-check` (ver [`validar-export.md`](./validar-export.md)).
- Seção de testes numerada, com o resultado esperado de cada um, e uma tabela **Se não funcionar** (sintoma → causa provável → correção).
- Seção **Situação** no fim: uma linha por evento (versionado, export validado, teste na app), com data, evidência e pendências. Diferencie proposto, versionado, aplicado e testado.

## Ao corrigir um guia

- Se o erro era do guia, diga isso na Situação e acrescente a linha em "Se não funcionar".
- Atualize o `export-check` no mesmo commit.
- Atualize a ficha da página e o `docs/ai-context/README.md` se o estado mudou.
