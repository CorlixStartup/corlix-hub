---
name: testar-na-app
description: Testa ou confere algo na app Corlix Hub (navegador) ou no banco (SQL Commands) com segurança — login sempre do time, autorização antes de gravar, limpeza e registro. Use quando a pessoa pedir "faça os testes", "confere na app", "teste a página N" ou depois de validar um export.
---

Siga o fluxo universal em `docs/agentes/fluxos/testar-na-app.md` e a conduta em `docs/agentes/conduta.md` (valem para qualquer agente; esta skill só os aciona).

No Claude Code, o navegador é o Claude in Chrome (`mcp__claude-in-chrome__*`): carregue a skill do navegador antes, trabalhe em abas próprias e feche-as no fim.
