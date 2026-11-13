# Fluxo · Dividir o trabalho entre agentes

**Quando:** a tarefa exige ler muitos arquivos independentes (ex.: fichas de 42 páginas, revisão de vários módulos). Ferramentas com subagentes (Claude Code, Codex) podem rodar partes em paralelo; sem esse recurso, faça as partes em sequência com o mesmo roteiro.

## Como dividir

- **Um dono por arquivo.** Cada agente escreve só os arquivos dele; ninguém edita o arquivo de outro ao mesmo tempo. Índices e arquivos compartilhados (README, 02, 08) ficam com o agente principal, no fim.
- **Mesma branch, sem commit dos subagentes.** O principal cria a branch antes, os subagentes só escrevem, e o principal revisa e faz o commit. Nenhum subagente troca de branch (isso muda os arquivos de todos).
- **Prompt completo.** O subagente só sabe o que está no prompt. Inclua: objetivo, regras obrigatórias (pastas só leitura, não inventar, pt-BR), fonte da verdade, arquivos que pode escrever, estrutura exata do resultado e o que devolver no relatório.
- **Peça o relatório em formato útil:** lista de arquivos, linhas prontas para o índice e divergências encontradas.

## Depois

- **Não aceite o relatório no escuro.** Confira as afirmações mais graves no código antes de repassar, principalmente as de segurança e isolamento por empresa, que podem ser falsos positivos.
- Junte as divergências que os agentes acharam e corrija os documentos compartilhados.
- Relate ao time o que foi verificado por você e o que veio só do relatório dos agentes.
