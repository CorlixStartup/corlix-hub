# Fluxo · Testar na app e no banco

**Quando:** conferir na app o que o guia mandou fazer (tela, JS, mensagens, navegação) ou consultar o banco. Vale para agentes com navegador (ex.: Claude in Chrome). Sem navegador, peça ao time o resultado de cada teste e registre como "relato do time".

Leia antes a [conduta](../conduta.md): login é do time, gravar exige autorização, apagar só o que o teste gravou.

## 1. Ambiente

- App (DEV): `https://gfe80286062641f-corlixhub.adb.sa-saopaulo-1.oraclecloudapps.com/ords/r/corlixhub/corlixhub/início`. O formato `f?p=100:N` funciona em `/ords/f?p=100:N`, não sob `/ords/r/...`.
- Conta de teste do RH: `teste.rh` (tem colaborador vinculado). A senha nunca passa pelo agente: se cair no login, peça ao time para entrar **na aba que o agente está usando** (uma aba que o agente não controla não serve).
- Builder e SQL Commands: `/ords/apex` → workspace `CORLIXHUB` → SQL Workshop › SQL Commands. A sessão do Builder é do time; o agente só escolhe o workspace.
- `render_*` dos packages no SQL Commands dá `ORA-20012` (sessão APEX sem `G_ID_EMPRESA`): isso é esperado. Teste esses no SQLcl ou direto na página.
- Data local: o banco está em UTC. Use `cast(systimestamp at time zone 'America/Sao_Paulo' as date)` para "agora" em Brasília.

## 2. Testes que não gravam

Faça sem perguntar: abrir páginas e diálogos, ler o DOM, conferir textos, classes e estilos, clicar em navegação que não grava, `select` no banco.

- **Validação de servidor sem gravar:** deixe pelo menos um campo obrigatório vazio e envie. O servidor devolve todos os erros e não grava nada. Para pular a validação do navegador: `apex.page.submit({request: '<botão>', validate: false})`.
- **Upload sem arquivo do disco:** gere a imagem no próprio navegador (canvas → `File` → `DataTransfer`) e dispare `change` no `input[type=file]`.
- **Modal (iframe):** o conteúdo fica em `[...document.querySelectorAll('iframe')].find(i => i.closest('.ui-dialog')).contentWindow`.
- **CSS em teste:** pode injetar CSS só na aba do agente para comparar com o protótipo. Nunca oriente o time a usar CSS inline (regra "Sem CSS Inline"): a correção vai no arquivo do módulo.
- Feche as abas que abriu ao terminar.

## 3. Testes que gravam

1. Peça autorização dizendo **o que** vai gravar e **como** vai desfazer. Exemplo de tabela: teste → o que grava → como desfaz.
2. Use texto que se identifica como teste: título "Teste de publicação · ignorar", feedback "Teste da Home · ignorar".
3. Rode e registre o que apareceu (mensagem, tela, linha no banco).
4. Desfaça no SQL Commands, filtrando pelo id **e** por um segundo campo:
   ```sql
   delete from comunicado where id_comunicado = 82 and titulo = 'Teste de publicação · ignorar'
   ```
   Antes de apagar, confira as FKs que apontam para a tabela (`user_constraints`, `delete_rule`): `CASCADE` apaga junto; `NO ACTION` bloqueia.
5. Confira que voltou a 0 linha e que a tela voltou ao estado anterior (ex.: "5 não lidos").

## 4. Armadilhas já vistas

| Sintoma | Causa | O que fazer |
|---|---|---|
| Navegação para no "Sair do site?" do navegador | Item alterado e *Warn on Unsaved Changes* ligado | Na Home ele fica desligado; em teste, `apex.page.cancelWarnOnUnsavedChanges()` antes de recarregar |
| A aba muda de página sozinha | O time está usando a mesma aba | Volte para a página do teste e avise |
| Sessão cai no meio do teste | Sessão expirada | Peça para o time entrar de novo na aba do agente |
| Ação bloqueada pela permissão do ambiente | O pedido do time não cobria aquela ação (ex.: enviar formulário) | Pare, explique e espere o time autorizar |
| Hora gravada como `00:00` | Item *Hidden* de data passa pelo formato `DS` da app | Limite conhecido (página 17, §4.10) |

## 5. Registrar

Na "Situação" do guia: data, conta usada, o que passou, o que falhou (com a causa), o que não deu para testar e por quê, e a limpeza feita (ids apagados e conferência).
