# Ponto eletrônico · Meus pedidos, selo do dia e textos do relógio

Este guia traz os ajustes encontrados no teste da app em 03/11/2026. **Não há região nova nem CSS novo:** basta reinstalar um package e, se ainda não foi feito, trocar uma linha na página 32.

| Ajuste | Antes | Depois |
|---|---|---|
| **Meus pedidos** (página 30) | O colaborador não via o status nem a resposta do pedido | Novo cartão, abaixo de Pendências, com os 5 pedidos mais recentes: Em análise, Aprovado ou Recusado, e a resposta de quem aprovou |
| **Selo do dia** (espelho e CSV) | Dia completo com saldo negativo aparecia como "Regular" | Aparece "Abaixo da jornada" |
| **Mensagem do registro** | "Retorno do intervalo registrada. Comprovante nº 3." | "Marcação registrada: Retorno do intervalo. Comprovante nº 3." |
| **Rodapé do relógio** | Com a saída registrada antes de completar a jornada: "faltam 7h36 para completar a jornada" | "jornada encerrada" |
| **`Pedido em`** (página 32) | Hora em UTC: 09:01 aparecia como 12:01 | Hora local da empresa |

---

## 1. Banco: reinstalar o package de tela

Só o corpo do package muda. Em *SQL Workshop › SQL Scripts › Upload*, envie e rode:

- `modulos/ponto-eletronico/04_pkg_ponto_ui.pkb`

Depois, no SQL Commands, sem `;` no final:

```sql
select object_name, object_type, status from user_objects
 where object_name = 'PKG_PONTO_UI' order by 2
```

Os dois devem estar `VALID`. Se algum estiver `INVALID`:

```sql
select name, type, line, position, text from user_errors
 where name = 'PKG_PONTO_UI' order by type, sequence
```

---

## 2. Página 32: hora de `Pedido em`

Pule esta seção se a troca já foi feita pelo `Etapas-ajustes-validacao.md`.

No Page Designer da página 32, clique na região `Pedidos pendentes` e, em **Source › SQL Query**, troque a linha:

```sql
cast(a.dh_pedido as date) as pedido_em,
```

por:

```sql
pkg_historico_carreira.fn_data_local(a.id_empresa, a.dh_pedido) as pedido_em,
```

Salve. Não mude mais nada na região: a coluna continua com o mesmo nome e a mesma máscara.

---

## 3. Testar

Use uma conta **de teste**. Enviar e responder pedidos fica registrado.

**Com o colaborador**

1. Abra **Ponto eletrônico** e recarregue com Cmd+Shift+R. Quem já fez pedidos vê o cartão **Meus pedidos** abaixo de Pendências, com o mais recente em cima. Quem nunca fez não vê o cartão.
2. Em **Solicitar ajuste**, envie um pedido. O modal fecha, e o pedido aparece no cartão como **Em análise**, sem recarregar a página.
3. Procure no espelho um dia completo com saldo negativo: ele mostra **Abaixo da jornada**, e a mesma situação sai no CSV de **Baixar espelho**.
4. Registre uma marcação: a mensagem é "Marcação registrada: ... Comprovante nº N".
5. Num dia com a saída já registrada e menos horas que a jornada, o rodapé do relógio diz "jornada encerrada", sem "faltam". Com a jornada completa, continua "jornada completa".

**Com o gestor ou o RH**

6. Em **Ajustes de ponto**, `Pedido em` mostra a hora local em que o pedido foi enviado.
7. Responda ao pedido, com uma mensagem.

**De volta ao colaborador**

8. Recarregue a página 30: o pedido aparece como **Aprovado** ou **Recusado**, com "Resposta: ...".

### Como conferir no export

No próximo backup:

- `database/ddl/09-plsql-corpos.sql`: `PKG_PONTO_UI` com a procedure `meus_pedidos`.
- `corlixhub/pages/p00032-*.apx`: a consulta com `fn_data_local`.

### Se não funcionar

| Sintoma | Causa provável | Correção |
|---|---|---|
| O cartão **Meus pedidos** não aparece, mesmo com pedidos | `pkg_ponto_ui` antigo no banco | Seção 1 |
| `INVALID` em `PKG_PONTO_UI` | Erro de compilação | Veja `user_errors` (seção 1) e mande o resultado |
| Cartão **Meus pedidos** sem atualizar depois de enviar o pedido | Região `Pendências` sem o HTML DOM ID `ponto_pendencias` | `Etapas-ajustes-validacao.md`, passo 2.1 |
| Erro na página 32 depois de trocar a linha | Vírgula perdida na troca | Confira se a linha termina com vírgula, como a original |
