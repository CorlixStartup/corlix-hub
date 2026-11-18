# Mapas de testes (QA manual)

Roteiros para o QA manual da app 100 (CORLIXHUB), um por perfil de usuário.

| Mapa | Perfil | Casos | Estado |
|---|---|---|---|
| [`mapa-testes-colaborador.docx`](./mapa-testes-colaborador.docx) | Colaborador comum | 126 (49 de prioridade alta, 22 gravam dados) | Versão 1.0 de 17/11/2026; ainda não executado |

## Mapa da visão do colaborador

**O que cobre:** login, header e menu; Início; Meu perfil; Organograma; Chat; Busca; Comunicados; Holerite (com o pedido de correção); Histórico de carreira (com o pedido de correção); Ponto eletrônico (com o pedido de ajuste e a assinatura); Suporte TI na visão de quem abre chamado; controle de acesso pelas URLs das páginas de RH, gestão, TI e equipe do Corlix Hub; responsividade, teclado e outros navegadores.

**Fora do escopo:** as telas de RH, gestor, aprovador de ponto, Suporte TI e equipe do Corlix Hub. Essas contas só entram como apoio quando um caso do colaborador depende de uma resposta delas (ex.: aprovar um ajuste ou atender um chamado).

**Como foi montado:** a partir das fichas de `docs/ai-context/paginas/` (estado de 13/11/2026, backup de DEV `84f8625`), da matriz de autorizações do `docs/ai-context/03-componentes-compartilhados.md` §2 e das seções de teste dos guias (`home`, `perfil`, `holerite`, `historico-carreira`, `ponto-eletronico`, `suporte-ti`, `busca` e `isolamento-empresas`). Nenhum caso foi executado na app para montar o mapa.

**Estrutura do documento:** escopo, ambiente e contas (CA, CB, CS, CE e contas de apoio), preparação, como registrar (OK, Falha, Bloqueado, N/A), dados gravados e limpeza, resumo, casos por grupo (ID, cenário e pré-condição, passos, resultado esperado, prioridade, resultado e observações), comportamentos já conhecidos, matriz de acesso esperada, registro de defeitos e registro de execução.

**Decisões:**
- Os casos com comportamento já conhecido trazem uma observação "Atenção" e o resultado esperado pela regra do projeto. Exemplo: a p17, a p26, a p27 e a p6 deveriam negar o acesso ao colaborador, mas abrem (ACE-06 e ACE-07). Quem testa registra o resultado real.
- O Suporte TI é aberto pelo atalho da Início, porque ainda não tem item de menu.
- As marcações de ponto são imutáveis. Os casos que registram ponto pedem um dia e uma conta combinados com o time.
- A limpeza dos dados gravados é feita pelo time, seguindo [`docs/agentes/fluxos/testar-na-app.md`](../agentes/fluxos/testar-na-app.md) §3.

**Pendências:**
- Executar a primeira rodada e preencher o registro de execução (seção 10 do documento).
- Revisar o mapa quando entrarem o menu do Suporte TI, a p11 de comunicados, o redesign do login, o PDF do holerite e as correções de autorização da p17, p26, p27 e p6.
- Criar os mapas dos outros perfis (RH, gestor, Suporte TI e equipe do Corlix Hub).

## Como atualizar o .docx

O conteúdo dos casos fica em [`fonte/casos.js`](./fonte/casos.js), e o layout em [`fonte/gerar.js`](./fonte/gerar.js). Edite o `casos.js` e gere de novo o documento:

```bash
cd "$(mktemp -d)" && npm init -y >/dev/null && npm install docx@9 >/dev/null
cp <repo>/docs/testes/fonte/*.js . && node gerar.js <repo>/docs/testes/mapa-testes-colaborador.docx
```

Atualize a versão e a data na capa (`gerar.js`) e a tabela acima.
