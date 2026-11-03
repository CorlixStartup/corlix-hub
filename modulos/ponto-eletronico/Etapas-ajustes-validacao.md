# Ponto eletrônico · ajustes da validação de 03/11/2026

Este guia traz **só o que a validação encontrou** nas páginas 30 a 33, já montadas pelo [`Etapas-ponto-eletronico.md`](./Etapas-ponto-eletronico.md). Os caminhos são do **APEX 26.1.5**. Passos marcados com **(confirmar no 26.1.5)** não foram conferidos na tela; se o caminho não existir, tire um print da árvore e do painel e registre o caminho certo aqui.

> **Estado (03/11/2026):** as seções 1 a 4 já foram aplicadas. O resultado está em [Resultado na app](#resultado-na-app). As seções ficam como registro do que foi feito.

A seção 1 muda o banco; as seções 2 a 4 mudam a app no Builder.

| Prioridade | Onde | O que acontecia | Seção |
|---|---|---|---|
| **Alta** | Página 30 | Regiões sem HTML DOM ID: registrar grava, mas a tela não atualiza; seletor de mês e diálogos não funcionam | 2.1 |
| Média | `pkg_ponto` | Saída de hoje aprovada sem entrada trava o registro; pendência de assinatura some antes do prazo | 1 |
| Média | Página 32 | Duas colunas "Pedido em" e data sem o formato certo | 3 |
| Média | Página 33 | Provável opção em branco em **Resposta** | 4.1 |
| Baixa | Páginas 30 e 33 | Faixa do cabeçalho, posição dos botões e nome do processo | 2.2, 4.2 |

---

## 1. Banco: reinstalar os packages

Nenhuma tabela muda. Em *SQL Workshop › SQL Scripts › Upload*, envie e rode um arquivo por vez, **nesta ordem**:

1. `modulos/ponto-eletronico/03_pkg_ponto.pks`
2. `modulos/ponto-eletronico/03_pkg_ponto.pkb`
3. `modulos/ponto-eletronico/04_pkg_ponto_ui.pkb`

Depois, no SQL Commands, um comando por vez, sem `;` no final:

```sql
select object_name, object_type, status from user_objects
 where object_name in ('PKG_PONTO', 'PKG_PONTO_UI') order by 1, 2
```

Todos devem estar `VALID`. Se algum estiver `INVALID`:

```sql
select name, type, line, position, text from user_errors
 where name in ('PKG_PONTO', 'PKG_PONTO_UI') order by name, type, sequence
```

### O que muda

| Regra | Antes | Agora |
|---|---|---|
| Pedido de marcação para **hoje** | Podia pular marcações. Uma saída aprovada sem entrada mostrava "Jornada concluída" e travava o botão até o fim do dia | Só aceita se as marcações anteriores do dia existirem, no pedido e de novo na aprovação. Dias passados continuam podendo vir em qualquer ordem, um pedido por vez |
| Pendência de assinatura | Só o mês anterior: em 01/12, o espelho de outubro sumia, embora o prazo fosse 05/12 | O mês retrasado continua pendente até o dia 5; depois dele, vale o mês anterior |
| Assinar mês anterior ao início do controle | Aceitava, por chamada forjada, e gravava um espelho vazio | Recusa com "Não há espelho deste mês para assinar" |
| Assinar mês com pedido em análise | Aceitava, e depois quem aprova só podia recusar o pedido (`-20070`) | Recusa com "Este mês tem pedido de ajuste em análise" (`-20074`). Decisão de 03/11/2026 |
| `render_*(p_id_colaborador)` fora do APEX | O id era ignorado: voltava o aviso de conta sem vínculo | Usa o id informado (só no SQLcl: no SQL Commands continua dando `ORA-20012`, veja `docs/ai-context/09`) |

---

## 2. Página 30 · Ponto eletrônico

### 2.1 HTML DOM ID das regiões (obrigatório)

O JavaScript procura as regiões pelo `id` do HTML. No 26.1, o Static ID não vira esse `id`: sem o HTML DOM ID, o APEX gera `R<número>` (`docs/ai-context/08` §3, "Static ID ≠ id do HTML").

Na árvore **Rendering**, clique em cada região e preencha **Advanced › HTML DOM ID**:

| Região | HTML DOM ID |
|---|---|
| Relógio | `ponto_relogio` |
| Espelho | `ponto_espelho` |
| Banco de horas | `ponto_banco` |
| Pendências | `ponto_pendencias` |
| Sua jornada | `ponto_jornada` |
| Comprovantes de marcação | `ponto_dlg_comprovantes` |
| Espelho do mês | `ponto_dlg_mes` |
| Extrato do banco de horas | `ponto_dlg_extrato` |
| Assinar espelho | `ponto_dlg_assinatura` |

**Como conferir:** rode a página, abra o console do navegador (F12) e cole:

```javascript
["ponto_relogio","ponto_espelho","ponto_banco","ponto_pendencias","ponto_jornada","ponto_dlg_comprovantes","ponto_dlg_mes","ponto_dlg_extrato","ponto_dlg_assinatura"].filter(function (id) { return !document.getElementById(id); })
```

Deve voltar `[]`. Qualquer nome na lista é uma região que ficou sem o id.

### 2.2 Faixa do cabeçalho

Na tela, o título da página 30 fica solto no fundo cinza. O protótipo mostra uma faixa branca, que a página 32 já tem: ela usa o template `Corlix Standard Page` e o cabeçalho em Breadcrumb Bar. Faça a página 30 igual:

1. No nó **Page 30**, mude **Appearance › Page Template** para o mesmo da página 32 (`Corlix Standard Page`; confirmar o nome no 26.1.5).
2. Mova a região `Cabeçalho` de Body para **Breadcrumb Bar**: clique nela e mude **Layout › Slot** (confirmar no 26.1.5).

Compare o resultado com `pen_dev/Ponto eletrônico.png`. A troca de template ainda não foi testada na página 30: se o layout quebrar, volte os dois passos e mande um print antes de mudar mais alguma coisa.

### 2.3 Tabela cortada nos diálogos

O **Espelho do mês** já está em Large (720 px), mas a tabela ocupa 782 px e a coluna Situação fica cortada. A correção é de CSS: não mude o tamanho do diálogo.

Em *Shared Components › Static Application Files*, na pasta `ponto-eletronico/`, reenvie **os dois** arquivos, substituindo os atuais:

- `modulos/ponto-eletronico/ponto.css`
- `modulos/ponto-eletronico/ponto.min.css`

Recarregue a página 30 com Cmd+Shift+R e abra **Ver comprovantes** ou **Ver mês completo**: a tabela cabe no diálogo, sem barra de rolagem embaixo dele. Com um nome de feriado muito longo, a rolagem fica dentro da tabela.

---

## 3. Página 32 · Ajustes de ponto

Na região `Pedidos pendentes`, abra **Columns** e ajuste:

| Coluna | Seção › Atributo | Valor |
|---|---|---|
| `PEDIDO` | Heading › Heading | `Pedido` |
| `PEDIDO` | Appearance › Format Mask | (vazio) |
| `HORARIO` | Heading › Heading | `Horário` |
| `PEDIDO_EM` | Heading › Heading | `Pedido em` |
| `PEDIDO_EM` | Appearance › Format Mask | `DD/MM/YYYY HH24:MI` |

---

## 4. Página 33 · Responder ajuste

### 4.1 Opção em branco

Clique em `P33_ST_AJUSTE` e mude **List of Values › Display Null Value** para **No**. A página 23 é o modelo.

### 4.2 Botões e nome do processo

1. Mova a região `Botões` para **Dialog Footer**: clique nela e mude **Layout › Slot** (confirmar no 26.1.5).
2. Clique no botão `RESPONDER` e mude **Layout › Slot** para **Next** (confirmar no 26.1.5).
3. Na aba **Pre-Rendering**, renomeie o processo `New` para `Carregar` em **Identification › Name**.

---

## 5. Atalho da Início (outro assunto)

Na Início publicada, o atalho **Ponto eletrônico** mostra "Este atalho ainda não tem destino configurado", embora a página 30 já exista. Isso vem da versão de `pkg_home_ui` instalada no banco. No repositório, `modulos/home/pkg_home_ui.pkb` já não tem esse atalho (protótipo de 28/10/2026), então o aviso some quando a versão atual da Home for instalada. Se o time quiser um atalho para o ponto na Início, é um ajuste do módulo da Home.

---

## 6. Testar

Use uma conta **de teste**, com colaborador e gestor. **Marcações reais não podem ser apagadas**, então não registre ponto em nome de outra pessoa nem em conta de uso real.

**Página 30, sem gravar nada**

1. Recarregue com Cmd+Shift+R. O título fica na faixa branca, e o teste do console do passo 2.1 volta `[]`.
2. Troque o mês no seletor: espelho e rodapé mudam sem recarregar.
3. Abra **Ver comprovantes**, **Ver mês completo** e **Ver extrato**: cada um abre o seu diálogo, sem `Region does not support being opened and closed`.
4. Abra **Solicitar ajuste** e clique em **Cancelar**. Mude entre as duas opções antes: os campos **Marcação** e **Horário** somem no abono.

**Com gravação (só em conta de teste)**

5. Registre uma marcação: aparece o comprovante, e o relógio e o espelho atualizam sem recarregar.
6. Em **Solicitar ajuste**, peça a **Saída** de hoje antes de existir entrada: mensagem "as marcações anteriores precisam estar registradas".
7. Envie um pedido válido para um dia passado: o modal fecha e o dia passa a **Ajuste em análise**.
7a. Se esse dia for do mês com espelho pendente, clique em **Revisar e assinar** e em **Assinar espelho**: mensagem "Este mês tem pedido de ajuste em análise", e nada é assinado.

**Páginas 32 e 33 (com o gestor)**

8. Em **Ajustes de ponto**, as colunas mostram `Pedido`, `Horário` e `Pedido em`, com data e hora.
9. Em **Responder**, só existem as opções **Aprovar** e **Recusar**, e os botões ficam no rodapé.
10. Recuse sem mensagem: erro pedindo a explicação. Depois responda de verdade: o pedido some da fila.

### Como conferir no export

No próximo backup:

- `corlixhub/pages/p00030-*.apx`: as 9 regiões com `advanced { htmlDomId: ponto_... }`, `pageTemplate: @corlix-standard-page` e `Cabeçalho` com `slot: breadcrumbBar`.
- `corlixhub/pages/p00032-*.apx`: `PEDIDO` sem `formatMask`, `PEDIDO_EM` com `formatMask`.
- `corlixhub/pages/p00033-*.apx`: `displayNullValue: false` em `P33_ST_AJUSTE`, região `Botões` com `slot: dialogFooter`.
- `database/ddl/09-plsql-corpos.sql`: `PKG_PONTO` com a procedure `exigir`.

### Se não funcionar

| Sintoma | Causa provável | Correção |
|---|---|---|
| Registrar grava, mas a tela não atualiza | Região sem HTML DOM ID | Passo 2.1 |
| `Region does not support being opened and closed` | Diálogo sem HTML DOM ID | Passo 2.1 |
| Pedido da saída de hoje aceito sem entrada | `pkg_ponto` antigo no banco | Seção 1 |
| Saída aprovada travou o botão com "Jornada concluída" e sem entrada | Pedido aprovado antes da correção | O gestor não consegue desfazer: o dia precisa de um ajuste de entrada, que o colaborador pede em **Solicitar ajuste** |
| Colaborador não consegue assinar: "Este mês tem pedido de ajuste em análise" | Regra nova: há pedido pendente naquele mês | O gestor ou o RH responde na página 32, e depois o colaborador assina |
| `ORA-20012` ao testar `render_*` no SQL Commands | O SQL Workshop é uma sessão APEX sem `G_ID_EMPRESA` | Teste no SQLcl (`docs/ai-context/09`) |
| Layout da página 30 quebrou depois de trocar o template | Troca do passo 2.2 ainda não testada | Volte o template e o slot, e mande um print da página e da árvore |

## Resultado na app

Conferido em 03/11/2026 na app publicada, com a conta `TESTE.RH` e os backups do dia, até o das 09:52.

| Item | Resultado |
|---|---|
| Packages no banco iguais aos do módulo | Certo |
| Os 9 HTML DOM IDs e o título na faixa branca | Certo |
| Os 4 diálogos sem corte nem erro de JavaScript | Certo, com poucas linhas de dados |
| Registrar marcação e atualizar a tela sem recarregar | Certo (comprovante nº 3) |
| Outra marcação em menos de 1 minuto | Recusada, como previsto |
| Pedido da saída de hoje sem as marcações anteriores | Recusado, como previsto |
| Pedido de abono e pedido igual repetido | Enviado; o repetido foi recusado |
| Modal fecha e a página 30 recebe o evento | Certo |
| Baixar espelho (CSV com BOM e colunas certas) | Certo |
| Página 32 não mostra o pedido da própria conta | Certo |
| Página 32 mostra o pedido ao gestor direto, com as colunas certas | Certo; `Pedido em` saía em UTC e, depois da correção, mostra a hora local (pedido das 10:10 aparece como 10:10) |
| Página 33: dados do pedido, só Aprovar e Recusar, botões no rodapé | Certo |
| Recusar sem mensagem | Recusado, como previsto |
| Recusar com mensagem | Certo: "Resposta registrada", e o pedido saiu da fila |
| Aprovar abono em dia com saldo negativo | Certo: dia **Abonado**, saldo do dia e banco de horas em 0h00, extrato sem lançamentos |
| Cartão **Meus pedidos** (`Etapas-meus-pedidos.md`) | Certo: Em análise, Aprovado e Recusado, com a resposta; atualiza quando o modal fecha |
| Rodapé do relógio depois da saída | Certo: "jornada encerrada" |

**Ainda não testado na app:**

- selo "Abaixo da jornada" e mensagem "Marcação registrada: ...", cobertos só pelos testes locais;
- assinatura do espelho, inclusive o bloqueio com pedido em análise;
- seletor de mês e "Ver mês completo", que precisam de uma conta com mais dados.

**Dados de teste que ficaram no banco**, na conta `TESTE.RH`, em 03/11/2026:

- comprovantes nº 3 (retorno às 09:02) e nº 4 (saída às 09:25), que não podem ser apagados. O dia fechou com 0h24 trabalhadas e -7h36, zerados pelo abono abaixo;
- um pedido de abono com o motivo "Teste de validação", recusado pelo gestor com a mesma mensagem;
- um segundo pedido de abono, com o mesmo motivo, aprovado pelo gestor com a mesma mensagem;
- um terceiro pedido de abono, enviado às 10:10 para conferir `Pedido em`, recusado pelo gestor com a mensagem "Teste de validação".

**Pontos achados no teste e já corrigidos** (`Etapas-meus-pedidos.md`):

- a hora de `Pedido em` saía em UTC na página 32;
- o colaborador não via o status nem a resposta do pedido;
- um dia completo com saldo negativo aparecia como "Regular";
- o rodapé do relógio dizia "faltam 7h36" depois da saída;
- a mensagem do registro errava o gênero ("Retorno do intervalo registrada").

**Detalhe de texto, ainda sem correção:**

- Mensagens e rótulos do APEX em inglês: "1 error has occurred", "Required", "Search", "Go" e "Actions".
