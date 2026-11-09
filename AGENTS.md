# AGENTS.md — Corlix Hub

Instruções para agentes de IA (Claude Code, Copilot, Cursor, Codex etc.).

**Antes de qualquer tarefa, leia [`docs/ai-context/README.md`](docs/ai-context/README.md)** (o projeto) e, quando a tarefa envolver recursos do APEX, [`docs/apex-26.1/README.md`](docs/apex-26.1/README.md) (base de conhecimento do Oracle APEX 26.1 tirada da documentação oficial) e, a partir dele, os documentos relevantes. Antes de editar qualquer coisa, leia [`docs/ai-context/08-convencoes-e-pegadinhas.md`](docs/ai-context/08-convencoes-e-pegadinhas.md).

> **Regra obrigatória:** nunca crie, edite, apague ou reverta nada em `corlixhub/` (código-fonte da app), `backups/`, `pen_dev/` e `scripts/`. Essas pastas são só para leitura. As mudanças na app são feitas pelo time no Builder e chegam ao repositório pelo export/backup; o trabalho do agente é validar, guiar (`modulos/<nome>/Etapas-*.md`) e documentar (`docs/`). Se uma tarefa parecer exigir mudança nessas pastas, pare e pergunte.

Resumo:
- App Oracle APEX 26.1 (ID 100, `CORLIXHUB`, workspace `WKSP_CORLIXHUB`) sobre Oracle DB 23ai. Toda a lógica está em SQL/PL/SQL e no APEX.
- Fonte da app: `corlixhub/` (APEXlang `.apx`), **somente leitura** (regra acima). `database/f100.sql` é um export gerado: só leia com grep, nunca edite.
- **Protótipos:** todo protótipo/tela-alvo do projeto está em `pen_dev/` (PNGs do pen.dev, um por tela; descrições em `docs/ai-context/07-design-pen-dev.md`). Procure lá antes de qualquer outro lugar; se a tela pedida não existir, pergunte.
- **Páginas baseadas nos módulos existentes (obrigatório):** antes de criar ou alterar uma página, compare o protótipo com a implementação atual de Histórico de carreira, Holerite, Ponto eletrônico ou outro módulo equivalente. Siga sempre os padrões já adotados, especialmente packages `pkg_<modulo>_ui` com `render_*` retornando CLOB e chamadas curtas no Builder, além de cabeçalho, ações, layout, ícones, autorização e integração. Só substitua um padrão se houver uma boa prática comprovadamente melhor para o caso: documente a comparação, os benefícios concretos, os impactos e a validação. Preferência pessoal ou conveniência isolada não justificam a troca; sem evidência suficiente, mantenha o padrão existente. Não proponha componentes ou posições do Builder sem conferir o template usado. Veja a regra 14 em [08-convenções](docs/ai-context/08-convencoes-e-pegadinhas.md).
- Módulos de feature em `modulos/<nome>/`: SQL numerado + `instalar.sql`, packages, CSS/JS e o guia `Etapas-*.md`.
- Tema: tokens `--cx-*` em `corlixhub/shared-components/static-files/corlix-tema.css`; ajustes em `custom.css`. Mantenha os `.min.css` em sincronia.
- Escreva em pt-BR. Use Conventional Commits (`scripts/git-hooks/commit-msg`).
- **Branches e PRs (regra obrigatória):** qualquer alteração vai numa branch criada a partir da `DEV` atualizada, `feature/<assunto>` para funcionalidade nova e `fix/<assunto>` para as demais, nunca em commit direto na `DEV` ou na `PROD`. Faça commit e push, abra PR para `DEV` e, quando a `DEV` tiver commits que ainda não estão na `PROD`, abra também o PR `DEV` → `PROD`, se não houver um aberto. O merge é do time. Detalhes em `docs/ai-context/08-convencoes-e-pegadinhas.md` §1, regra 13.
- Ao alterar páginas, schema, tema ou módulos, atualize o documento correspondente em `docs/ai-context/`.
- **Dúvida sobre o APEX (componente, atributo, API PL/SQL ou JS, APEXlang)?** Consulte `docs/apex-26.1/` e, para o detalhe exato, a documentação oficial indexada: `python3 scripts/busca-casos/casos.py buscar "<termos em inglês>" --fonte apex`. Não responda de memória quando a doc puder confirmar.
- **Apareceu um erro ou comportamento estranho?** Antes de investigar, procure casos já ocorridos com `python3 scripts/busca-casos/casos.py buscar "<mensagem ou sintoma>"` (Elasticsearch; ver [`scripts/busca-casos/README.md`](scripts/busca-casos/README.md)). Ao resolver um caso novo, registre-o no `09` ou na tabela "Se não funcionar" do guia do módulo e rode `casos.py indexar`.

- **Documentação de encerramento (obrigatória):** ao finalizar qualquer tarefa ou módulo, atualize o registro correspondente com o que foi feito, decisões, evidências, testes (inclusive falhas), estado instalado versus proposto, pendências e próximo passo. A resposta final não substitui o registro versionado. Veja 08 §1, regra 15.
