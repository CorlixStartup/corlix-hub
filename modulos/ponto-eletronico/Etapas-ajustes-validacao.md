# Ponto eletrônico · ajustes da validação de 03/11/2026

Este guia traz **só o que a validação encontrou** nas páginas 30 a 33, já montadas pelo [`Etapas-ponto-eletronico.md`](./Etapas-ponto-eletronico.md). Os caminhos são do **APEX 26.1.5**. Passos marcados com **(confirmar no 26.1.5)** não foram conferidos na tela; se o caminho não existir, tire um print da árvore e do painel e registre o caminho certo aqui.

Faça as seções na ordem. A seção 1 muda o banco; as seções 2 a 4 mudam a app no Builder.

| Prioridade | Onde | O que acontece hoje | Seção |
|---|---|---|---|
| **Alta** | Página 30 | Regiões sem HTML DOM ID: registrar grava, mas a tela não atualiza; seletor de mês e diálogos não funcionam | 2.1 |
| Média | `pkg_ponto` | Saída de hoje aprovada sem entrada trava o registro; pendência de assinatura some antes do prazo | 1 |
| Média | Página 32 | Duas colunas "Pedido em" e data sem o formato certo | 3 |
| Média | Página 33 | Provável opção em branco em **Resposta** | 4.1 |
| Baixa | Páginas 30, 32 e 33 | Ordem do cabeçalho, template, posição dos botões e nome do processo | 2.2, 3, 4.2 |

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

### 2.2 Ordem do cabeçalho

O `Cabeçalho` e a `Coluna principal` estão ambos em Body com **Sequence 10**. Clique na região `Cabeçalho` e mude **Layout › Sequence** para `5`, para ele ficar sempre em cima.

Compare o resultado com `pen_dev/Ponto eletrônico.png`. Se o título não ficar na faixa do protótipo, mande um print antes de mudar mais alguma coisa.

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

No nó **Page 32**, mude **Appearance › Page Template** para **Standard**, o mesmo da página 30.

---

## 4. Página 33 · Responder ajuste

### 4.1 Opção em branco

Clique em `P33_ST_AJUSTE` e mude **List of Values › Display Null Value** para **No**. A página 23 é o modelo.

### 4.2 Botões e nome do processo

1. Mova a região `Botões` para **Dialog Footer**: clique nela e mude **Layout › Slot** (confirmar no 26.1.5).
2. Clique no botão `RESPONDER` e mude **Layout › Slot** para **Next** (confirmar no 26.1.5).
3. Na aba **Pre-Rendering**, renomeie o processo `New` para `Carregar` em **Identification › Name**.

---

## 5. Testar

Use uma conta **de teste**, com colaborador e gestor. **Marcações reais não podem ser apagadas**, então não registre ponto em nome de outra pessoa nem em conta de uso real.

**Página 30, sem gravar nada**

1. Recarregue com Cmd+Shift+R. O cabeçalho aparece em cima, e o teste do console do passo 2.1 volta `[]`.
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

- `corlixhub/pages/p00030-*.apx`: as 9 regiões com `advanced { htmlDomId: ponto_... }`, e `Cabeçalho` com `sequence: 5`.
- `corlixhub/pages/p00032-*.apx`: `pageTemplate: @/standard`, `PEDIDO` sem `formatMask`, `PEDIDO_EM` com `formatMask`.
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
| `Page Template` **Standard** deixou a página 32 sem o cabeçalho | O Cabeçalho está em Breadcrumb Bar | Mande um print da página e da árvore antes de mudar mais |
