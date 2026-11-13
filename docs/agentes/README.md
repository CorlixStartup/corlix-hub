# Regras e fluxos para agentes de IA

Esta pasta é a **fonte única** das regras e dos fluxos de trabalho de qualquer agente neste repositório: Claude Code, Codex, Cursor, GitHub Copilot, Gemini ou outro. Nenhuma regra fica presa a uma ferramenta. Os arquivos de cada ferramenta só apontam para cá.

## Ordem de leitura

1. [`AGENTS.md`](../../AGENTS.md): regras obrigatórias do projeto (pastas só leitura, branches e PRs, pt-BR, padrões de página).
2. [`docs/ai-context/README.md`](../ai-context/README.md): o projeto, as páginas e onde está cada coisa.
3. [`docs/ai-context/08-convencoes-e-pegadinhas.md`](../ai-context/08-convencoes-e-pegadinhas.md): antes de editar qualquer coisa.
4. [`conduta.md`](./conduta.md): como agir com segurança, honestidade e autorização (vale para toda tarefa).
5. O fluxo da tarefa, em [`fluxos/`](./fluxos/).

## Fluxos

| Quando | Fluxo |
|---|---|
| O time cola o export de uma página, pede "confere o export" ou "posso fechar?" | [`fluxos/validar-export.md`](./fluxos/validar-export.md) |
| Testar ou conferir algo na app (navegador) ou no banco | [`fluxos/testar-na-app.md`](./fluxos/testar-na-app.md) |
| Escrever ou corrigir um guia de Builder (`modulos/<m>/Etapas-*.md`) | [`fluxos/escrever-guia.md`](./fluxos/escrever-guia.md) |
| Criar ou atualizar a ficha de contexto de uma página | [`fluxos/ficha-de-pagina.md`](./fluxos/ficha-de-pagina.md) |
| Dividir um trabalho grande entre vários agentes | [`fluxos/delegar.md`](./fluxos/delegar.md) |

## Ferramentas

| Arquivo | O que faz |
|---|---|
| [`ferramentas/validar_export.py`](./ferramentas/validar_export.py) | Confere um export APEXlang contra o bloco `export-check` do guia. Só biblioteca padrão do Python |

## Como cada ferramenta chega aqui

| Ferramenta | Arquivo de entrada | Observação |
|---|---|---|
| Codex, Cursor, Copilot (coding agent), Jules e outros que leem `AGENTS.md` | [`AGENTS.md`](../../AGENTS.md) | Entrada principal |
| Claude Code | [`CLAUDE.md`](../../CLAUDE.md) (importa o `AGENTS.md`) e as skills em `.claude/skills/` | As skills só apontam para os fluxos daqui |
| GitHub Copilot (chat e review) | [`.github/copilot-instructions.md`](../../.github/copilot-instructions.md) | Aponta para o `AGENTS.md` |
| Cursor (regras) | [`.cursor/rules/corlix-hub.mdc`](../../.cursor/rules/corlix-hub.mdc) | `alwaysApply: true`, aponta para o `AGENTS.md` |
| Gemini CLI | [`GEMINI.md`](../../GEMINI.md) | Aponta para o `AGENTS.md` |

## Como manter

- Regra nova ou fluxo novo: escreva **aqui** (ou no `AGENTS.md`/`08`, se for regra do projeto). Não escreva regra só no arquivo de uma ferramenta.
- Arquivo de ferramenta (skill, `.mdc`, `copilot-instructions`, `GEMINI.md`): só gatilho e link. Se ele começar a ter conteúdo próprio, mova o conteúdo para cá.
- Uma ferramenta tem um recurso que as outras não têm (ex.: subagentes, navegador)? Descreva o **resultado** esperado no fluxo e diga como fazer sem o recurso. Exemplo: sem navegador, o agente pede ao time o print ou o resultado do teste.
