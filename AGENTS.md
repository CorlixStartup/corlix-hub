# AGENTS.md — Corlix Hub

Instruções para agentes de IA (Claude Code, Copilot, Cursor, Codex etc.).

**Antes de qualquer tarefa, leia [`docs/ai-context/README.md`](docs/ai-context/README.md)** (o projeto) e, quando a tarefa envolver recursos do APEX, [`docs/apex-26.1/README.md`](docs/apex-26.1/README.md) (base de conhecimento do Oracle APEX 26.1 tirada da documentação oficial) e, a partir dele, os documentos relevantes. Antes de editar qualquer coisa, leia [`docs/ai-context/08-convencoes-e-pegadinhas.md`](docs/ai-context/08-convencoes-e-pegadinhas.md).

Resumo:
- App Oracle APEX 26.1 (ID 100, `CORLIXHUB`, workspace `WKSP_CORLIXHUB`) sobre Oracle DB 23ai. Toda a lógica está em SQL/PL/SQL e no APEX.
- Fonte da app: `corlixhub/` (APEXlang `.apx`). `database/f100.sql` é um export gerado: só leia com grep, nunca edite.
- Módulos de feature em `modulos/<nome>/`: SQL numerado + `instalar.sql`, packages, CSS/JS e o guia `Etapas-*.md`.
- Tema: tokens `--cx-*` em `corlixhub/shared-components/static-files/corlix-tema.css`; ajustes em `custom.css`. Mantenha os `.min.css` em sincronia.
- Escreva em pt-BR. Use Conventional Commits (`scripts/git-hooks/commit-msg`) e abra PRs para `DEV`.
- Ao alterar páginas, schema, tema ou módulos, atualize o documento correspondente em `docs/ai-context/`.
- **Dúvida sobre o APEX (componente, atributo, API PL/SQL ou JS, APEXlang)?** Consulte `docs/apex-26.1/` e, para o detalhe exato, a documentação oficial indexada: `python3 scripts/busca-casos/casos.py buscar "<termos em inglês>" --fonte apex`. Não responda de memória quando a doc puder confirmar.
- **Apareceu um erro ou comportamento estranho?** Antes de investigar, procure casos já ocorridos com `python3 scripts/busca-casos/casos.py buscar "<mensagem ou sintoma>"` (Elasticsearch; ver [`scripts/busca-casos/README.md`](scripts/busca-casos/README.md)). Ao resolver um caso novo, registre-o no `09` ou na tabela "Se não funcionar" do guia do módulo e rode `casos.py indexar`.
