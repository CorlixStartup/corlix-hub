# Holerite digital (página 9) · redesign · passo a passo no APEX

Este guia deixa a página 9 igual ao protótipo [`pen_dev/Holerite digital.png`](../../pen_dev/Holerite%20digital.png), no App Builder do **APEX 26.1.5**. A página continua sendo a 9, com o mesmo alias. O que muda são as regiões, a autorização e a forma de gerar a folha.

Como nos outros guias, a mudança é feita no Builder. O backup diário traz o resultado para `corlixhub/pages/p00009-holerite-digital.apx` na `DEV`; editar o `.apx` do repositório não muda o app e é desfeito no próximo backup.

> **Estado do código:** o package foi compilado e testado em um Oracle 23ai local, com 41 verificações, e a tela foi renderizada em navegador com o CSS real do tema. Esse banco **não tem APEX**: as APIs do APEX foram simuladas. A página real, os links com checksum e o modal só são testados ao seguir este guia (§4).

### Como ler os caminhos deste guia (APEX 26.1.5)

- **Rendering** é a árvore da esquerda do Page Designer; o **painel de propriedades** é o da direita. `Seção › Atributo` indica a seção e o campo no painel do componente selecionado.
- No 26.1.5 a região **não tem a aba nem o nó "Attributes"**. Para achar um atributo, use a busca no topo do painel de propriedades.
- Passos marcados com **(confirmar no 26.1.5)** ainda não foram conferidos na tela desta versão. Se o caminho não existir, não procure por tentativa: tire um print da árvore e do painel e registre o caminho certo neste guia.

## O que muda

| Parte | Hoje | Depois |
|---|---|---|
| Topo | Barra com breadcrumb | Faixa branca com título, descrição, **Ocultar valores** e **Baixar PDF** |
| Escolha do mês | Selects de mês e ano, que recarregam a página | Lista **Holerites** à direita, com seletor de ano. Só mostra meses que existem |
| Resumo | Totais numa linha, no fim | Líquido em destaque, bruto, descontos, selo de situação e barra de proporção |
| Itens | Tabela com colunas de proventos e descontos | Grupos **Proventos** e **Descontos**, com explicação e referência em cada item |
| Bases | Não existiam | Base INSS, Base IRRF, Base FGTS e FGTS do mês |
| Correção | Não existia | Card **Algo errado neste holerite?**, que abre a página 22 |
| Números | `2,875.44` (formato do idioma técnico da app) | `2.875,44` |
| Acesso | Sem autorização própria | **COLABORADOR** na página e no menu, como nas páginas 13 e 30 |
| Geração da folha | Ao abrir a página, com gravação e `COMMIT`, para qualquer mês escolhido | Fora da página: carga única e job mensal (§1.2 e §1.3) |
| Quando o holerite aparece | Em qualquer data | **A partir do dia 25 do mês** (veja abaixo) |

### Por que a geração saiu da página

O `pkg_holerite.render` chama `gerar_folha_mensal` quando o mês escolhido não tem nenhum holerite. Na prática, qualquer pessoa logada que escolhesse um mês vazio gerava a folha de **todos** os colaboradores, inclusive de meses futuros, como dezembro de 2027. O `pkg_holerite_ui` só lê. `pkg_holerite.gerar_folha_mensal` continua igual, e `pkg_holerite.render` fica no banco para o caso de voltar atrás.

### A regra do dia 25

O holerite do mês aparece a partir do dia 25. Em 24/11, o mais recente é o de outubro; em 25/11, entra o de novembro.

A regra vale em dois lugares, com o mesmo valor: `c_dia_liberacao` em `pkg_holerite_ui` e em `prc_gerar_holerites_pendentes`. Se o dia mudar, altere os dois e o horário do job. A data de "hoje" da tela usa o fuso da empresa (`pkg_historico_carreira.fn_hoje`). O job roda às 06:00 no fuso do banco, então o holerite pode levar algumas horas para aparecer no dia 25.

### Arquivos do módulo

| Arquivo | O que é |
|---|---|
| `01_prc_gerar_holerites_pendentes.sql` | Procedure que gera os meses sem nenhum holerite, sem tocar nos que já existem |
| `02_pkg_holerite_ui.pks` / `.pkb` | Package que devolve o HTML (`render_cabecalho`, `render_pagina`) |
| `03_job_folha_mensal.sql` | Job que chama a procedure todo dia 25 |
| `instalar.sql` | Instala a procedure e o package pelo SQLcl |
| `holerite.css` / `holerite.min.css` | Estilos da página (classes `cx-hol-*`); sobem como Static Application Files |
| `holerite-pagina.js` | "Ocultar valores", "Baixar PDF", seletor de ano e mensagem do modal |

Não há tabela nova.

---

## 1. Banco

> **Se você já rodou este §1 antes da regra do dia 25:** instale de novo a procedure e o package (§1.1). Se a carga única já rodou, ela pode ter criado o mês atual: confira com a consulta do §1.2 e apague esse mês antes do dia 25, como explicado lá, para que o job o gere com os valores do dia.

### 1.1 Instalar

**Pelo SQLcl:** `cd modulos/holerite` e `sql <usuario>@<servico> @instalar.sql`.

**Pelo SQL Workshop:** em *SQL Workshop › SQL Scripts › Upload*, envie e rode um arquivo por vez, nesta ordem:

1. `01_prc_gerar_holerites_pendentes.sql`
2. `02_pkg_holerite_ui.pks`
3. `02_pkg_holerite_ui.pkb`

Depois, no SQL Commands, sem `;` no final:

```sql
select object_name, object_type, status from user_objects
 where object_name in ('PKG_HOLERITE_UI', 'PRC_GERAR_HOLERITES_PENDENTES') order by 1, 2
```

Os três devem estar `VALID`. Se algum estiver `INVALID`:

```sql
select name, line, position, text from user_errors
 where name in ('PKG_HOLERITE_UI', 'PRC_GERAR_HOLERITES_PENDENTES') order by name, sequence
```

### 1.2 Gerar os meses que faltam (uma vez só)

Antes, um mês só existia se alguém o tivesse aberto. Agora a lista mostra apenas o que já foi gerado, então é preciso preencher os meses que faltam.

**Veja primeiro o que já existe:**

```sql
select ano_referencia, mes_referencia, count(*) holerites
  from colaborador_holerite
 group by ano_referencia, mes_referencia
 order by 1, 2
```

**Atenção aos dados:** os meses preenchidos agora usam o salário de hoje do cargo, e a geração só inclui quem foi admitido a partir de 01/06/2026 (regra atual de `gerar_folha_mensal`). Se isso não servir para os seus dados, combine com o time antes de rodar.

Depois, em SQL Commands:

```sql
begin prc_gerar_holerites_pendentes; end;
```

O padrão começa em junho de 2026. Para começar em outro mês, use `p_inicio => date '2026-01-01'`.

A carga vai até o último mês liberado: antes do dia 25, para no mês anterior. A consulta acima pode mostrar o mês atual ou meses futuros criados pela geração antiga. A página **não mostra** esses meses antes do dia 25 de cada um, então nada precisa ser apagado agora. Eles passam a aparecer nessa data, com os valores gravados na época. Como o job não refaz um mês que já tem folha, é melhor apagá-los para que sejam recalculados no dia 25. Confira antes o que será apagado e rode em um dia anterior ao 25: `delete from colaborador_holerite where ano_referencia * 100 + mes_referencia >= to_number(to_char(sysdate, 'YYYYMM'))`. Os itens saem junto, em cascata.

### 1.3 Criar o job mensal

Sem o job, nenhum mês novo aparece. Em *SQL Scripts › Upload*, envie e rode `03_job_folha_mensal.sql`. Ele roda todo dia 25, às 06:00, no fuso do banco. Confira:

```sql
select job_name, enabled, to_char(next_run_date, 'DD/MM/YYYY HH24:MI') proxima
  from user_scheduler_jobs where job_name = 'JOB_FOLHA_MENSAL'
```

Deve mostrar `TRUE` e o próximo dia 25.

### 1.4 Testar no SQL Commands

Troque `482` por um colaborador que tenha holerite.

```sql
select pkg_holerite_ui.render_pagina(null, 482) from dual
```

Deve voltar um `<div class="cx-hol" data-cx-hol>` com o holerite mais recente. Para quem não tem holerite, volta "Nenhum holerite disponível ainda."

---

## 2. Arquivos estáticos

Em *Shared Components › Static Application Files › Create File*, envie os dois arquivos **na raiz** (sem pasta), com estes nomes:

| File Name | Arquivo |
|---|---|
| `holerite.css` | `modulos/holerite/holerite.css` |
| `holerite.min.css` | `modulos/holerite/holerite.min.css` |

A página carrega `holerite#MIN#.css`, então os dois precisam existir e estar iguais. Quando mudar o `.css`, gere o `.min.css` de novo e suba os dois.

---

## 3. Página 9 no Page Designer

Faça os passos na ordem: entre o 3.3 e o 3.5 a página fica sem o título novo ou com partes das duas versões.

### 3.1 Atributos da página

Clique no nó **Page 9: Holerite Digital** no topo da árvore:

| Seção | Atributo | Valor |
|---|---|---|
| CSS | File URLs | `#APP_FILES#holerite#MIN#.css` |
| CSS | Inline | **Apague todo o conteúdo** (as classes `holerite-*` não são mais usadas) |
| JavaScript | Execute when Page Loads | conteúdo de `modulos/holerite/holerite-pagina.js` |
| Security | Authorization Scheme | **COLABORADOR** |

### 3.2 Criar o item da competência

Botão direito em **Body** › **Create Page Item** (confirmar no 26.1.5):

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `P9_COMPETENCIA` |
| Identification | Type | **Hidden** |
| Settings | Value Protected | **On** |
| Session State | Storage | **Per Request (Memory Only)** |

Com *Per Request*, abrir **Holerite** pelo menu sempre mostra o mês mais recente, e não o último escolhido.

### 3.3 Criar o cabeçalho

Botão direito em **Breadcrumb Bar** › **Create Region** (confirmar no 26.1.5):

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `Cabeçalho` |
| Identification | Type | **Dynamic Content** |
| Source | Language | **PL/SQL** |
| Source | PL/SQL Function Body returning a CLOB | `return pkg_holerite_ui.render_cabecalho;` |
| Appearance | Template | **Blank with Attributes (No Grid)** |

### 3.4 Trocar a região do holerite

Selecione **Visualização do Holerite**, em **Body**:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `Holerite` |
| Source | PL/SQL Function Body returning a CLOB | `return pkg_holerite_ui.render_pagina(:P9_COMPETENCIA);` |
| Source | Page Items to Submit | **vazio** (tire `P9_MES` e `P9_ANO`) |
| Appearance | Template | **Blank with Attributes** |
| Appearance | Template Options | Volte ao padrão: tire *Remove Header* e *Scroll Body*, se continuarem disponíveis |

### 3.5 Apagar o que sobrou

Apague, nesta ordem:

1. A dynamic action **Recarregar Holerite** (aba **Dynamic Actions**).
2. Os itens **P9_MES** e **P9_ANO**.
3. A região **Filtro de Período**.
4. A região **Navegação Estrutural**, em **Breadcrumb Bar**.

Salve a página.

### 3.6 Menu

Em *Shared Components › Navigation Menu › Navigation Menu*, abra a entrada **Holerite**:

| Seção | Atributo | Valor |
|---|---|---|
| Authorization | Authorization Scheme | **COLABORADOR** |

Sem isso, quem não tem o papel vê o item no menu e recebe "acesso negado".

A página 22 não muda.

---

## 4. Testar

Limpe o cache do navegador antes (`Cmd+Shift+R`). Compare com o protótipo.

| # | Conta | Faça | Esperado |
|---|---|---|---|
| 1 | Colaborador com holerites | Abra **Holerite** no menu | Mês mais recente, com os números no formato `2.875,44`, sem a barra antiga |
| 2 | A mesma | Clique em outro mês na lista | O mês abre, marcado na lista, sem erro de checksum |
| 3 | A mesma | Confira as contas | Líquido = bruto − descontos; Base IRRF = bruto − INSS; FGTS = 8% do bruto |
| 4 | Quem tem holerites em dois anos | Troque o ano no seletor | Abre o mês mais recente daquele ano |
| 5 | Qualquer uma | Clique em **Ocultar valores** | Todos os valores viram `••••••`, a barra fica cinza e o botão vira **Mostrar valores** |
| 6 | A mesma | Troque de mês e recarregue a página | Os valores continuam ocultos |
| 7 | A mesma, com os valores ocultos | Clique em **Baixar PDF** | O diálogo de impressão abre com os valores, o nome da pessoa e sem menu nem lista. Escolha *Salvar como PDF*. O documento deve caber em uma página, e a tela volta oculta ao fechar |
| 8 | Qualquer uma | Clique em **Solicitar correção** | O modal abre com `Holerite-10/2026` (o mês aberto) já no campo, sem erro de checksum |
| 9 | A mesma | Complete o texto e envie | O modal fecha e aparece "Pedido enviado ao RH." |
| 10 | RH | Abra o Dashboard RH | O pedido aparece em **Solicitações de correção**, com o mês |
| 11 | Colega | Compare com a conta do teste 1 | Cada pessoa só vê os próprios valores |
| 12 | Admitido antes de 01/06/2026 | Abra **Holerite** | "Nenhum holerite disponível ainda.", sem os botões |
| 13 | Conta sem colaborador | Abra a página pela URL | Acesso negado, com "Sua conta não está vinculada a um colaborador desta empresa." |
| 14 | Colaborador com holerites | Abra a página e confira, antes e depois, o `count(*)` de `colaborador_holerite` | O total não muda |
| 15 | Qualquer uma | Reduza a janela até a largura de um celular | Sem rolagem horizontal; a lista desce para baixo do detalhamento, e a coluna Referência some |
| 16 | Colaborador com holerites, antes do dia 25 | Abra **Holerite**, mesmo que o mês atual já tenha folha gravada | O mais recente é o do mês anterior; o mês atual não está na lista |
| 17 | A mesma, a partir do dia 25 | Abra **Holerite** depois da execução do job | O mês atual aparece primeiro, com o selo **Pagamento agendado** |

O selo **Pagamento agendado** só aparece do dia 25 até a véspera da data de pagamento. Depois disso, a tela mostra **Pago**.

## Se não funcionar

| Sintoma | Causa provável | Correção |
|---|---|---|
| `PLS-00201` citando `PKG_HOLERITE` ou `PKG_HISTORICO_CARREIRA` | Package ausente neste schema | Instale o que falta e rode o §1.1 de novo |
| `ORA-27486` ao criar o job | O schema não tem o privilégio `CREATE JOB` | Peça ao administrador do banco o `grant create job`, ou crie uma *Automation* no APEX que chame `prc_gerar_holerites_pendentes` |
| O holerite do mês não apareceu no dia 25 | O job ainda não rodou, ou falhou | Confira `user_scheduler_job_run_details` e, se preciso, rode `begin prc_gerar_holerites_pendentes; end;` |
| Lista com poucos meses | O §1.2 não foi feito, ou a pessoa foi admitida no meio do período | Rode o §1.2. Meses anteriores à admissão não aparecem de propósito |
| Página sem estilo | CSS não enviado, ou nome diferente | Confira o §2 e `Cmd+Shift+R` |
| Faixa branca sem título | Região do §3.3 ausente ou fora de **Breadcrumb Bar** | Confira o §3.3 |
| Clicar num mês sempre volta ao mais recente | Item `P9_COMPETENCIA` com outro nome, ou a região não recebeu o item | Confira o §3.2 e o código do §3.4 |
| Erro de checksum ao trocar de mês | Link gerado fora do package | Confira se o `.pkb` novo está instalado |
| Erro de checksum em **Solicitar correção** | `get_url` tratou o valor de um jeito inesperado | Mande um print. O texto inicial vem de `correcao` no `.pkb` e pode sair sem afetar o resto |
| Botões **Ocultar** e **PDF** não respondem | JavaScript não colado | Confira o §3.1 |
| Menu ou cabeçalho do app saem no PDF | O tema usa uma classe que o CSS de impressão não conhece | Mande um print. O ajuste é no §8 do `holerite.css` |
| Conta legítima recebe "acesso negado" | Conta sem o papel COLABORADOR ou sem vínculo em `LOGIN_APEX` | Veja `modulos/perfis-acesso/Registro-implantacao.md` |

## Voltar atrás

Recrie a página a partir de `corlixhub/pages/p00009-holerite-digital.apx` no commit `21f03a5`. `pkg_holerite.render` não foi alterado. Se não quiser a geração automática, desligue o job com `begin dbms_scheduler.drop_job('JOB_FOLHA_MENSAL'); end;`. O package e a procedure podem ficar no banco, ou saem com `drop package pkg_holerite_ui` e `drop procedure prc_gerar_holerites_pendentes`.

## O que fica diferente do protótipo

- **Banco e conta ("Itaú, conta ••••5678"):** o sistema não guarda dados bancários. A linha mostra só "Crédito em 31/10/2026".
- **Matrícula:** o sistema não tem esse campo, então ela saiu. O ID interno do colaborador não foi usado no lugar dela.
- **Data de pagamento:** o protótipo mostra o último dia útil (30/10). `gerar_folha_mensal` grava o último dia do mês (31/10, um sábado).
- **Baixar PDF:** abre o diálogo de impressão do navegador, onde a pessoa escolhe *Salvar como PDF*. O PDF nativo do APEX é para relatórios, não para este layout. O documento leva o nome da pessoa, que não aparece na tela.
- **Solicitar correção:** reaproveita a página 22 e a fila do RH, sem tabela nova. O mês vai no texto, como `Holerite-10/2026`, porque não há coluna para ele. O campo "Qual registro?" do modal continua listando movimentações de carreira; deixe em "Não sei / vários".
- **Referência:** a geração grava "Tabela Oficial" no INSS e no IRRF. A tela mostra a alíquota efetiva e a base de cálculo, calculadas na hora. A explicação de cada item vem do nome dele; um item de outro tipo aparece sem explicação.

## Limites que continuam

Nenhum destes itens foi alterado por este guia:

- **Valores simulados:** `gerar_folha_mensal` é um cálculo simplificado. As faixas de INSS e IRRF estão fixas no código e parecem ser de 2024 (salário mínimo de R$ 1.412,00). A base de IRRF não considera dependentes.
- **Quem entra na folha:** só admitidos a partir de 01/06/2026, sem filtro por empresa ou por situação do colaborador. Quem foi desligado continua recebendo holerite.
- **Admissão depois do dia 25:** o mês já gerado não é refeito. A pessoa só aparece a partir da folha seguinte.
- **Cargo:** o holerite não guarda o cargo da época. Meses antigos mostram o cargo de hoje.
- **FGTS e bases:** são calculados na tela, a 8% do bruto, e não vêm de valores gravados.
- **RH:** o texto diz que o RH tem acesso, mas ainda não há tela para o RH consultar o holerite de outra pessoa.
- **"Ver holerite" no Histórico de carreira:** o link segue oculto (`c_pagina_holerite` nulo em `pkg_historico_carreira_ui`). Agora dá para apontar para a página 9.
