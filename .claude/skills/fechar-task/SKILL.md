---
name: fechar-task
description: Valida um export APEXlang de página (texto que começa com `page N (`) ou o backup de DEV contra o guia do módulo e diz se a tarefa pode ser fechada. Use quando a pessoa colar um export, pedir "confere o export", "valide a página N", "posso fechar a tarefa?" ou invocar /fechar-task.
---

Siga o fluxo universal em `docs/agentes/fluxos/validar-export.md` (vale para qualquer agente; esta skill só o aciona). Leia também `docs/agentes/conduta.md`.

Validador: `python3 docs/agentes/ferramentas/validar_export.py <guia> <export.apx>`. Grave o export colado num `.apx` no scratchpad da sessão.

Para os testes na app, use `docs/agentes/fluxos/testar-na-app.md` (skill `testar-na-app`).
