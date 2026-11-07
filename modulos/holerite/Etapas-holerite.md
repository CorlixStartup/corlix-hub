# Holerite digital (página 9) · redesign · passo a passo no APEX

Este guia deixa a página 9 igual ao protótipo [`pen_dev/Holerite digital.png`](../../pen_dev/Holerite%20digital.png), no App Builder do **APEX 26.1.5**. A página continua sendo a 9, com o mesmo alias. O que muda são as regiões, a autorização e a forma de gerar a folha.

Como nos outros guias, a mudança é feita no Builder. O backup diário traz o resultado para `corlixhub/pages/p00009-holerite-digital.apx` na `DEV`; editar o `.apx` do repositório não muda o app e é desfeito no próximo backup.

> **Estado do código:** o package foi compilado e testado em um Oracle 23ai local, com 69 verificações, e a tela foi renderizada em navegador com o CSS real do tema. Esse banco **não tem APEX**: as APIs do APEX foram simuladas. A página real, os links com checksum e o modal só são testados ao seguir este guia (§4).

### Como ler os caminhos deste guia (APEX 26.1.5)

- **Rendering** é a árvore da esquerda do Page Designer; o **painel de propriedades** é o da direita. `Seção › Atributo` indica a seção e o campo no painel do componente selecionado.
- No 26.1.5 a região **não tem a aba nem o nó "Attributes"**. Para achar um atributo, use a busca no topo do painel de propriedades.
- Passos marcados com **(confirmar no 26.1.5)** ainda não foram conferidos na tela desta versão. Se o caminho não existir, não procure por tentativa: tire um print da árvore e do painel e registre o caminho certo neste guia.

## O que muda

| Parte | Hoje | Depois |
|---|---|---|
| Topo | Barra com breadcrumb | Faixa branca com título, descrição, **Mostrar valores** e **Baixar PDF** |
| Escolha do mês | Selects de mês e ano, que recarregam a página | Lista **Holerites** à direita, com seletor de ano. Só mostra meses que existem |
| Resumo | Totais numa linha, no fim | Líquido em destaque, bruto, descontos, selo de situação e barra de proporção |
| Itens | Tabela com colunas de proventos e descontos | Grupos **Proventos** e **Descontos**, com explicação e referência em cada item |
| Bases | Não existiam | Base INSS, Base IRRF, Base FGTS e FGTS do mês |
| Correção | Não existia | Card **Algo errado neste holerite?**, que abre a página 22 |
| Números | `2,875.44` (formato do idioma técnico da app) | `2.875,44` |
| Acesso | Sem autorização própria | **COLABORADOR** na página e no menu, como nas páginas 13 e 30 |
| Geração da folha | Ao abrir a página, com gravação e `COMMIT`, para qualquer mês escolhido | Fora da página: carga única e job mensal (§1.2 e §1.3) |
| Quando o holerite aparece | Em qualquer data | **A partir do dia 25 do mês** (veja abaixo) |
| Desde quando há holerites | Só para admitidos a partir de 01/06/2026 | **Para todos, desde o mês da admissão** (veja abaixo) |
| Valores ao abrir a página | Visíveis | **Ocultos** (`••••••`), até a pessoa clicar em **Mostrar valores** (veja abaixo) |

### Por que a geração saiu da página

O `pkg_holerite.render` chama `gerar_folha_mensal` quando o mês escolhido não tem nenhum holerite. Na prática, qualquer pessoa logada que escolhesse um mês vazio gerava a folha de **todos** os colaboradores, inclusive de meses futuros, como dezembro de 2027. O `pkg_holerite_ui` só lê. `pkg_holerite.render` fica no banco para o caso de voltar atrás.

### A regra do dia 25

O holerite do mês aparece a partir do dia 25. Em 24/11, o mais recente é o de outubro; em 25/11, entra o de novembro.

A regra vale em dois lugares, com o mesmo valor: `c_dia_liberacao` em `pkg_holerite_ui` e em `prc_gerar_holerites_pendentes`. Se o dia mudar, altere os dois e o horário do job. A data de "hoje" da tela usa o fuso da empresa (`pkg_historico_carreira.fn_hoje`). O job roda às 06:00 no fuso do banco, então o holerite pode levar algumas horas para aparecer no dia 25.

### A regra da admissão

Cada pessoa tem holerites desde o mês em que foi admitida, seja qual for a data da admissão. Nada aparece antes da data de admissão chegar.

| Admissão | Primeiro holerite | Aparece em |
|---|---|---|
| 10/03/2024 | Março de 2024 | Depois da carga única (§1.2) |
| 15/11/2026 | Novembro de 2026 | 25/11/2026 |
| 28/11/2026 | Novembro de 2026 | 28/11/2026, depois do job das 06:00 |
| 01/12/2026 | Dezembro de 2026 | 25/12/2026 |

O primeiro mês sai com o salário cheio ("30 dias"): a geração não calcula valor proporcional.

### Valores ocultos ao abrir

Toda vez que a pessoa entra na página, os valores chegam ocultos: o líquido, os totais, os itens, as bases, os percentuais e os valores da lista de meses aparecem como `••••••`, e a barra de proporção fica cinza. O botão do topo começa como **Mostrar valores**.

- **Mostrar valores** revela tudo até a pessoa sair da página. Ao trocar de mês ou de ano pela própria página, os valores continuam visíveis.
- **Recarregar a página, voltar a ela pelo menu ou abrir em outra aba** começa oculto de novo.
- **Baixar PDF** sai sempre com os valores, mesmo com a tela oculta.

A máscara já vem pronta no HTML do `pkg_holerite_ui`, então o valor não aparece nem por um instante antes do JavaScript rodar. O valor real fica no atributo `data-cx-hol-original` do elemento, como antes ficava no texto, porque o JavaScript precisa dele para mostrar sem recarregar a página.

### Arquivos do módulo

| Arquivo | O que é |
|---|---|
| `00_pkg_holerite.pks` / `.pkb` | Cálculo da folha: mesmas contas, sem o corte de 01/06/2026 e com `gerar_holerite` por pessoa. Substitui o package do banco |
| `01_prc_gerar_holerites_pendentes.sql` | Procedure que gera, por pessoa, os holerites que faltam desde a admissão, sem tocar nos que já existem |
| `02_pkg_holerite_ui.pks` / `.pkb` | Package que devolve o HTML (`render_cabecalho`, `render_pagina`) |
| `03_job_folha_mensal.sql` | Job que chama a procedure todo dia |
| `instalar.sql` | Instala os packages e a procedure pelo SQLcl |
| `holerite.css` / `holerite.min.css` | Estilos da página (classes `cx-hol-*`); sobem como Static Application Files |
| `holerite-pagina.js` | "Mostrar/Ocultar valores" (a página abre oculta), "Baixar PDF", seletor de ano e mensagem do modal |

Não há tabela nova.

---

## 1. Banco

> **Se você já aplicou este guia antes dos valores ocultos ao abrir:** rode só `02_pkg_holerite_ui.pkb` (no SQL Scripts, ou `@02_pkg_holerite_ui.pkb` no SQLcl), cole de novo o JavaScript do §3.1 e faça os testes 5 a 7 e 19 do §4. O resto não muda.
>
> **Se você já rodou este §1 antes da regra do dia 25 e da regra da admissão:** instale tudo de novo (§1.1), rode a carga única (§1.2) e recrie o job (§1.3). Se a carga antiga já rodou, ela pode ter criado o mês atual: confira com a consulta do §1.2 e apague esse mês antes do dia 25, como explicado lá, para que o job o gere com os valores do dia.

### 1.1 Instalar

**Pelo SQLcl:** `cd modulos/holerite` e `sql <usuario>@<servico> @instalar.sql`.

**Pelo SQL Workshop:** em *SQL Workshop › SQL Scripts › Upload*, envie e rode um arquivo por vez, nesta ordem:

1. `00_pkg_holerite.pks`
2. `00_pkg_holerite.pkb`
3. `01_prc_gerar_holerites_pendentes.sql`
4. `02_pkg_holerite_ui.pks`
5. `02_pkg_holerite_ui.pkb`

Depois, no SQL Commands, sem `;` no final:

```sql
select object_name, object_type, status from user_objects
 where object_name in ('PKG_HOLERITE', 'PKG_HOLERITE_UI', 'PRC_GERAR_HOLERITES_PENDENTES') order by 1, 2
```

Os cinco devem estar `VALID`. Se algum estiver `INVALID`:

```sql
select name, line, position, text from user_errors
 where name in ('PKG_HOLERITE', 'PKG_HOLERITE_UI', 'PRC_GERAR_HOLERITES_PENDENTES') order by name, sequence
```

### 1.2 Gerar os holerites que faltam (uma vez só)

Antes, um mês só existia se alguém o tivesse aberto, e só para admitidos a partir de 01/06/2026. Agora a lista mostra apenas o que já foi gerado, então é preciso preencher o que falta, de cada pessoa, desde a admissão.

**Veja primeiro o que já existe:**

```sql
select ano_referencia, mes_referencia, count(*) holerites
  from colaborador_holerite
 group by ano_referencia, mes_referencia
 order by 1, 2
```

**Atenção aos dados:** os meses preenchidos agora usam o salário de hoje do cargo e as faixas fixas de INSS e IRRF, mesmo em anos antigos. Quem tem muitos anos de casa ganha um holerite por mês, então confira o volume antes:

```sql
select count(*) colaboradores, min(data_admissao) mais_antiga,
       sum(months_between(trunc(sysdate, 'MM'), trunc(data_admissao, 'MM')) + 1) holerites_no_maximo
  from colaborador
 where data_admissao <= sysdate
```

Depois, em SQL Commands:

```sql
begin prc_gerar_holerites_pendentes; end;
```

A carga vai até o último mês liberado: antes do dia 25, para no mês anterior. Rodar de novo só gera o que ainda falta. A consulta acima pode mostrar o mês atual ou meses futuros criados pela geração antiga. A página **não mostra** esses meses antes do dia 25 de cada um, então nada precisa ser apagado agora. Eles passam a aparecer nessa data, com os valores gravados na época. Como o job não refaz um mês que já tem folha, é melhor apagá-los para que sejam recalculados no dia 25. Confira antes o que será apagado e rode em um dia anterior ao 25: `delete from colaborador_holerite where ano_referencia * 100 + mes_referencia >= to_number(to_char(sysdate, 'YYYYMM'))`. Os itens saem junto, em cascata.

### 1.3 Criar o job

Sem o job, nenhum mês novo aparece. Em *SQL Scripts › Upload*, envie e rode `03_job_folha_mensal.sql`. Ele roda todo dia, às 06:00, no fuso do banco, e só gera o que falta. O holerite do mês entra no dia 25, e quem for admitido depois disso entra na primeira execução a partir da data de admissão. Confira:

```sql
select job_name, enabled, to_char(next_run_date, 'DD/MM/YYYY HH24:MI') proxima
  from user_scheduler_jobs where job_name = 'JOB_FOLHA_MENSAL'
```

Deve mostrar `TRUE` e as próximas 06:00.

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
| 5 | Qualquer uma | Abra **Holerite** no menu | Todos os valores aparecem como `••••••`, sem mostrar o número nem por um instante, a barra fica cinza e o botão é **Mostrar valores** |
| 6 | A mesma | Clique em **Mostrar valores**, depois troque de mês e de ano | Os valores aparecem, o botão vira **Ocultar valores** e os valores continuam visíveis nos outros meses |
| 7 | A mesma, com os valores ocultos | Clique em **Baixar PDF** | O diálogo de impressão abre com os valores, o nome da pessoa e sem menu nem lista. Escolha *Salvar como PDF*. O documento deve caber em uma página, e a tela volta oculta ao fechar |
| 8 | Qualquer uma | Clique em **Solicitar correção** | O modal abre com `Holerite-10/2026` (o mês aberto) já no campo, sem erro de checksum |
| 9 | A mesma | Complete o texto e envie | O modal fecha e aparece "Pedido enviado ao RH." |
| 10 | RH | Abra o Dashboard RH | O pedido aparece em **Solicitações de correção**, com o mês |
| 11 | Colega | Compare com a conta do teste 1 | Cada pessoa só vê os próprios valores |
| 12 | Admitido antes de 01/06/2026 | Abra **Holerite** e escolha o ano da admissão | Holerites desde o mês da admissão, e nenhum antes dele |
| 13 | Conta sem colaborador | Abra a página pela URL | Acesso negado, com "Sua conta não está vinculada a um colaborador desta empresa." |
| 14 | Colaborador com holerites | Abra a página e confira, antes e depois, o `count(*)` de `colaborador_holerite` | O total não muda |
| 15 | Qualquer uma | Reduza a janela até a largura de um celular | Sem rolagem horizontal; a lista desce para baixo do detalhamento, e a coluna Referência some |
| 16 | Colaborador com holerites, antes do dia 25 | Abra **Holerite**, mesmo que o mês atual já tenha folha gravada | O mais recente é o do mês anterior; o mês atual não está na lista |
| 17 | A mesma, a partir do dia 25 | Abra **Holerite** depois da execução do job | O mês atual aparece primeiro, com o selo **Pagamento agendado** |
| 18 | Colaborador com admissão futura | Abra **Holerite** | "Nenhum holerite disponível ainda.", sem os botões |
| 19 | A do teste 6, com os valores visíveis | Recarregue a página (`F5`), e depois saia e volte pelo menu | Nas duas vezes, os valores voltam ocultos |

O selo **Pagamento agendado** só aparece do dia 25 até a véspera da data de pagamento. Depois disso, a tela mostra **Pago**.

## Se não funcionar

| Sintoma | Causa provável | Correção |
|---|---|---|
| `PLS-00201` citando `PKG_HOLERITE` ou `PKG_HISTORICO_CARREIRA` | Package ausente neste schema | Instale o que falta e rode o §1.1 de novo |
| `ORA-27486` ao criar o job | O schema não tem o privilégio `CREATE JOB` | Peça ao administrador do banco o `grant create job`, ou crie uma *Automation* no APEX que chame `prc_gerar_holerites_pendentes` |
| O holerite do mês não apareceu no dia 25 | O job ainda não rodou, ou falhou | Confira `user_scheduler_job_run_details` e, se preciso, rode `begin prc_gerar_holerites_pendentes; end;` |
| Lista com poucos meses | O §1.2 não foi feito, ou `DATA_ADMISSAO` está errada ou vazia | Rode o §1.2 e confira a data. Meses anteriores à admissão não aparecem de propósito, e quem não tem data de admissão não gera holerite |
| A carga do §1.2 roda sem erro e gera 0 holerites | O cargo da pessoa está sem `SALARIO_BASE`. Sem salário, `gerar_holerite` não grava nada | Preencha o salário do cargo. O job do dia seguinte gera os meses que faltam, ou rode `begin prc_gerar_holerites_pendentes; end;`. Para ver quem está nessa situação: `select c.login_apex, car.nome from colaborador c join cargo car on car.id_cargo = c.id_cargo where nvl(car.salario_base, 0) <= 0` |
| `PLS-00302` citando `GERAR_HOLERITE` em `prc_gerar_holerites_pendentes` | O `pkg_holerite` antigo continua no banco | Instale os arquivos `00_` e rode o §1.1 na ordem |
| Página sem estilo | CSS não enviado, ou nome diferente | Confira o §2 e `Cmd+Shift+R` |
| Faixa branca sem título | Região do §3.3 ausente ou fora de **Breadcrumb Bar** | Confira o §3.3 |
| Clicar num mês sempre volta ao mais recente | Item `P9_COMPETENCIA` com outro nome, ou a região não recebeu o item | Confira o §3.2 e o código do §3.4 |
| Erro de checksum ao trocar de mês | Link gerado fora do package | Confira se o `.pkb` novo está instalado |
| Erro de checksum em **Solicitar correção** | `get_url` tratou o valor de um jeito inesperado | Mande um print. O texto inicial vem de `correcao` no `.pkb` e pode sair sem afetar o resto |
| Botões **Mostrar valores** e **PDF** não respondem | JavaScript não colado | Confira o §3.1 |
| Valores visíveis ao abrir a página | `.pkb` antigo no banco | Rode `02_pkg_holerite_ui.pkb` de novo (§1.1) |
| Valores ocultos e **Mostrar valores** não revela nada | `.pkb` novo com o JavaScript antigo | Cole de novo o `holerite-pagina.js` no §3.1 |
| Menu ou cabeçalho do app saem no PDF | O tema usa uma classe que o CSS de impressão não conhece | Mande um print. O ajuste é no §8 do `holerite.css` |
| Conta legítima recebe "acesso negado" | Conta sem o papel COLABORADOR ou sem vínculo em `LOGIN_APEX` | Veja `modulos/perfis-acesso/Registro-implantacao.md` |

## Voltar atrás

Recrie a página a partir de `corlixhub/pages/p00009-holerite-digital.apx` no commit `21f03a5`. Para o cálculo antigo, recrie `pkg_holerite` a partir de `database/ddl/08-plsql-especificacoes.sql` e `09-plsql-corpos.sql`, no commit `21f03a5`; `render` não foi alterado. Se não quiser a geração automática, desligue o job com `begin dbms_scheduler.drop_job('JOB_FOLHA_MENSAL'); end;`. O package e a procedure podem ficar no banco, ou saem com `drop package pkg_holerite_ui` e `drop procedure prc_gerar_holerites_pendentes`.

## Situação na app

Conferido em 07/11/2026 com a conta `TESTE.RH`, admitida em 07/10/2026, pela página e pelo console do navegador, sem comparar imagens:

- **Aplicado:** o backup de 07/11/2026 às 16:09 tem a página 9, o menu e os dois CSS como no §2 e no §3, e `pkg_holerite`, `prc_gerar_holerites_pendentes` e `pkg_holerite_ui` iguais aos arquivos do módulo.
- **OK, testes 1 e 3:** outubro de 2026 abre como mês mais recente, no formato `2.875,44`. Bruto 3.500,00 − descontos 624,56 = líquido 2.875,44; Base IRRF 3.181,18 (bruto − INSS) e FGTS 280,00 (8%).
- **OK, testes 5, 6 e 19:** os 19 valores abrem como `••••••`, com a barra cinza e **Mostrar valores**. Mostrar e ocultar funcionam; os valores continuam visíveis ao clicar no mês da lista, sem erro de checksum, e voltam ocultos ao recarregar e ao sair e voltar pela Início.
- **OK, teste 7, em parte:** com a tela oculta, os eventos de impressão trocam a máscara pelos valores e depois voltam a ocultar. O diálogo de impressão e o PDF gerado não foram abertos.
- **OK, teste 8:** **Solicitar correção** abre o modal com `Holerite-10/2026`. O pedido não foi enviado, então os testes 9 e 10 ficam para depois.
- **OK, regra da admissão nesta conta:** a lista mostra só outubro de 2026, o mês da admissão, e o seletor de ano só tem 2026.
- **OK:** nenhum erro no console e sem rolagem horizontal na largura da janela.
- **OK, teste 2 e regra da admissão, com `Rafael Nunes`, admitido em 01/06/2026:** a lista vai de junho a outubro de 2026, sem nenhum mês anterior à admissão. Os 23 valores abrem ocultos. Com os valores visíveis, clicar em **Junho** abre o mês marcado na lista, sem erro de checksum e com os valores ainda visíveis. Bruto 4.200,00 − descontos 1.273,08 = líquido 2.926,92. Nenhum erro no console.
- **OK, testes 4 e 12, com `DEMO.CARREIRA.1.1`, admitida em 07/09/2023 (conta criada para o teste, cargo `[DEMO] Analista II`):** o seletor de ano tem 2026, 2025, 2024 e 2023, e a página abre em outubro de 2026, com os 28 valores ocultos. Com os valores visíveis, trocar para 2023 abre dezembro de 2023, sem erro de checksum e com os valores ainda visíveis. A lista de 2023 vai de setembro a dezembro, sem nenhum mês antes da admissão. Bruto 6.000,00 − descontos 1.772,92 = líquido 4.227,08. Nenhum erro no console.
- **OK, testes 9 e 10:** com `DEMO.CARREIRA.1.1` (`[DEMO] Ana Lima`), o pedido `Holerite-10/2026 – teste do guia do holerite, pode ignorar` foi enviado; o modal fechou com "Pedido enviado ao RH.". Com `TESTE.RH`, ele aparece no Dashboard RH, em **Solicitações de correção abertas**, aberto em 07/11/2026 às 16:41. O pedido ficou sem resposta; responda ou feche como teste.
- **OK, teste 11:** o endereço da página com `p9_competencia` e sem checksum, ou com checksum falso, é recusado com "Session state protection violation" (HTTP 400). A página não recebe identificador de pessoa, e as contas `TESTE.RH`, `Rafael Nunes` e `DEMO.CARREIRA.1.1` mostraram só os próprios valores (3.500,00, 4.200,00 e 6.000,00 de bruto).
- **OK, teste 15:** com `TESTE.RH`, numa janela de 378 px úteis, a página mede 363 px, sem rolagem horizontal e sem elemento fora da tela. **Mostrar valores** e **Baixar PDF** ficam lado a lado sob a descrição, a lista **Holerites** desce para baixo do detalhamento e das bases, e a coluna Referência some.
- **OK, teste 14:** antes e depois de abrir, com `DEMO.CARREIRA.1.1`, os 38 meses e as 4 páginas de ano, `colaborador_holerite` ficou com 2.859 linhas (maior id 9471) e `holerite_itens` com 11.436 (maior id 47762). Para não derrubar a sessão, as contagens no SQL Commands e a app foram abertas em momentos separados.
- **Faltam:**
  - **13:** precisa de uma conta da app sem colaborador vinculado.
  - **16, em parte:** antes do dia 25, outubro é o mês mais recente em todas as contas. Novembro foi apagado (veja abaixo), então o caso "mês atual gravado e escondido" não foi visto na tela.
  - **17:** a partir de 25/11, depois do job.
  - **18:** não há colaborador com admissão futura.

### Banco, conferido no SQL Commands em 07/11/2026

- **Job:** estava na versão mensal antiga (dia 25) e nunca tinha rodado. Foi recriado pelo §1.3: diário, às 06:00, próxima execução em 08/11/2026.
- **Carga única (§1.2):** na primeira vez, gerou 0 holerites: as 17 pessoas admitidas antes de 01/06/2026 (a conta `EDUARDOMARINS`, de 2010, e as `DEMO.CARREIRA.*`) estavam em cargos **sem salário**, que a geração ignora. Eram 37 cargos sem `SALARIO_BASE`, 9 deles com gente.
- **Salários preenchidos (dados de demonstração):** os 37 cargos receberam um salário inventado, de acordo com o cargo e o mercado, seguindo a escala dos cargos que já tinham salário. Os principais: assistentes de 3.200 a 5.000; analistas de 4.500 a 6.500 (`[DEMO] Analista I` 4.500, `[DEMO] Analista II` 6.000); Desenvolvedor(a) 9.000; coordenadores de 9.000 a 9.500; gerentes e Tech Lead de 16.000 a 18.000; Chefe de Gabinete 15.000; diretores de 30.000 a 35.000; Presidente (CEO) 45.000. Antes de usar dados reais, substitua pelos salários de verdade.
- **Carga única, depois dos salários:** gerou 513 holerites, o número esperado. As 309 pessoas com admissão têm todos os meses até outubro de 2026, desde o mês da admissão; a mais antiga começa em janeiro de 2010. Os outubros que já existiam ficaram como estavam (3.500,00), porque a carga não refaz um holerite gravado.
- **Meses gravados pela geração antiga:** novembro de 2026 foi apagado antes da carga, então o job o gera em 25/11 com os salários atuais. Continuam no banco 873 holerites de meses anteriores à admissão, em pessoas admitidas a partir de junho; a página não os mostra, e eles podem sair a qualquer momento com o `delete` do §1.2.

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
- **Quem entra na folha:** todos os admitidos, sem filtro por empresa ou por situação do colaborador. Quem foi desligado continua recebendo holerite.
- **Primeiro mês:** sai cheio, mesmo com admissão no meio do mês.
- **Anos antigos:** usam o salário de hoje e as mesmas faixas de INSS e IRRF.
- **Cargo:** o holerite não guarda o cargo da época. Meses antigos mostram o cargo de hoje.
- **FGTS e bases:** são calculados na tela, a 8% do bruto, e não vêm de valores gravados.
- **RH:** o texto diz que o RH tem acesso, mas ainda não há tela para o RH consultar o holerite de outra pessoa.
- **"Ver holerite" no Histórico de carreira:** o link segue oculto (`c_pagina_holerite` nulo em `pkg_historico_carreira_ui`). Agora dá para apontar para a página 9.
