# Ponto eletrônico (páginas 30 a 33) · passo a passo no APEX

Este guia cria a tela do protótipo [`pen_dev/Ponto eletrônico.png`](../../pen_dev/Ponto%20eletr%C3%B4nico.png) no App Builder do **APEX 26.1.5**. Branch deste trabalho: `feature/ponto-eletronico`.

Como nos outros guias, a mudança é feita no Builder. O backup diário traz o resultado para `corlixhub/pages/` na `DEV`; editar o `.apx` do repositório não muda o app e é desfeito no próximo backup.

> **Estado do código:** os scripts e packages deste módulo **ainda não foram compilados**, porque não há banco acessível no ambiente em que foram escritos. A seção 1 tem os testes para fazer antes de montar as páginas. Se aparecer erro de compilação, mande a saída de `user_errors` para corrigir o arquivo aqui no módulo.

### Como ler os caminhos deste guia (APEX 26.1.5)

- **Rendering** é a árvore da esquerda do Page Designer; o **painel de propriedades** é o da direita. `Seção › Atributo` indica a seção e o campo no painel do componente selecionado.
- No 26.1.5 a região **não tem a aba nem o nó "Attributes"**. Para achar qualquer atributo, use a busca no topo do painel de propriedades.
- Passos marcados com **(confirmar no 26.1.5)** ainda não foram conferidos na tela desta versão. Se o caminho não existir, não procure por tentativa: tire um print da árvore e do painel e registre o caminho certo neste guia.

### O que será criado

| Página | Tipo | Para quê | Quem acessa |
|---|---|---|---|
| **30 · Ponto eletrônico** | Normal | Relógio, registro, marcações do dia, espelho, banco de horas, pendências e jornada | `COLABORADOR` |
| **31 · Solicitar ajuste** | Modal | Pedido de inclusão ou correção de marcação, ou abono do dia | `COLABORADOR` |
| **32 · Ajustes de ponto** | Normal | Fila dos pedidos pendentes | `APROVADOR_PONTO` (novo: gestor ou RH) |
| **33 · Responder ajuste** | Modal | Aprovar ou recusar um pedido | `APROVADOR_PONTO` |

As páginas 31 a 33 não estão no protótipo, mas sem elas os botões **Solicitar ajuste** e **Justificar** não teriam efeito.

### Do protótipo para o app

| Elemento | Como funciona |
|---|---|
| Relógio e **Registrar saída** | A hora gravada é a do servidor, no fuso da empresa. O botão muda conforme a próxima marcação: entrada, intervalo, retorno, saída |
| Linha do tempo | As 4 marcações de hoje. A saída mostra a previsão, calculada com o intervalo real (08:57, 12:02 e 13:04 dão 17:59 para 8h, como no print) |
| Espelho de ponto | Os 7 dias mais recentes do mês escolhido. **Ver mês completo** abre um diálogo com todos |
| Banco de horas | Saldo calculado a partir dos dias, com aviso dos créditos que vencem em até 60 dias e o extrato em diálogo |
| Pendências | Marcações ausentes e faltas dos últimos 30 dias (**Justificar** abre a p31 preenchida) e espelho do mês anterior sem assinatura |
| Sua jornada | Tabelas `ponto_jornada` e `ponto_colaborador`; quem aprova é o gestor direto (`colaborador.id_gestor`), ou "RH" se não houver gestor |
| Baixar espelho | Arquivo CSV do mês selecionado, que abre no Excel |

### Regras de cálculo (conferem com os números do print)

- **Trabalhadas** = (intervalo − entrada) + (saída − retorno).
- **Saldo do dia** = trabalhadas − jornada. Diferença até a tolerância (10 min) vira `0h00`: 8h05 dá `0h00`; 8h17 dá `+0h17`; 9h40 dá `+1h40`.
- **Dia incompleto** não entra no saldo até ser ajustado. **Falta** (dia útil passado sem marcação) desconta a jornada inteira. **Abono aprovado** zera o saldo negativo do dia.
- Sábado, domingo e feriado trabalhados: todas as horas são crédito.
- **Banco de horas:** o crédito vence no fim do mês, 6 meses depois do dia em que entrou. O débito consome primeiro o crédito mais antigo. Crédito vencido sai do saldo; o pagamento fica fora do sistema.
- **Marcação não muda:** um trigger bloqueia `update` e `delete`. Ajuste aprovado cria outra linha, que passa a valer no cálculo, e a original continua na lista de comprovantes.
- **Mês assinado** não aceita ajustes novos.

### Decisões que diferem do print

- **"Saldo de outubro até ontem"** virou **"até hoje"**, porque um dia de hoje já fechado também conta. O valor é o mesmo do print enquanto o dia está em andamento.
- **Baixar espelho** gera CSV, não PDF: não há servidor de impressão configurado no app.
- **Local** ("Sede São Paulo"): é o `ponto_colaborador.ds_local`, preenchido com "Sede " + cidade da empresa. Não há GPS, cerca virtual nem validação de local.
- O print mostra 8h03 em 16/10, mas 08:58–12:01 + 13:00–18:02 dá **8h05**. O app mostra 8h05.

### Fica de fora

- **Conformidade legal:** este módulo **não é um REP-P homologado** e não gera AFD nem AEJ da Portaria MTP 671/2021. Serve para o projeto e como controle interno. Para uso real como registro oficial, o RH e o jurídico precisam avaliar o que falta. A validade do banco de horas (6 meses) e a tolerância são parâmetros de `ponto_jornada`, a conferir com o acordo de cada empresa.
- **Férias e afastamentos:** não há tabela. Esses dias aparecem como falta até o RH abonar.
- **Turno que cruza a meia-noite** e **escala diferente de seg a sex**: a jornada é diurna, de segunda a sexta.
- **Telas de cadastro** de jornadas e feriados: por enquanto, por SQL (§1.3).
- **Saldo inicial** de banco de horas de quem já tinha saldo em outro sistema.
- **Notificações** de pedido novo ou respondido, e a página **Minhas aprovações**: o gestor acompanha pela p32.
- **Card "Ponto de hoje" e indicador de banco de horas na Início:** ficam para um passo seguinte, porque dependem de `pkg_ponto` estar no ar.

### Arquivos do módulo

| Arquivo | O que é |
|---|---|
| `01_ddl_ponto.sql` | Tabelas, trigger de imutabilidade e `vw_ponto_marcacao_vigente` |
| `02_seed_ponto.sql` | Jornada padrão por empresa, vínculo dos colaboradores e feriados nacionais de 2026–2027 |
| `03_pkg_ponto.pks` / `.pkb` | Regras: cálculo dos dias, banco de horas, registro, ajustes e assinatura |
| `04_pkg_ponto_ui.pks` / `.pkb` | HTML das regiões e Ajax Callbacks |
| `05_dados_demo.sql` / `06_remover_dados_demo.sql` | Dados de teste para um colaborador e a remoção deles (opcionais) |
| `instalar.sql` | Instala tudo pelo SQLcl, menos a demonstração |
| `ponto.css` / `ponto.min.css` | Estilos (classes `cx-ponto-*`); sobem como Static Application Files |
| `ponto-pagina.js` | JavaScript da página 30 |

**Pré-requisito:** módulo de histórico de carreira instalado (`pkg_historico_carreira.fn_hoje`, `fn_data_local` e `fn_empresa_contexto`).

**Conta de teste:** use uma conta com colaborador vinculado. As contas SARAHSILVA, EDUARDOMARINS e ALAIRTONROCHA não têm colaborador, então nelas a página 30 só mostra o aviso de conta sem vínculo (`docs/ai-context/08` §3). Para achar uma conta:

```sql
select id_colaborador, nome_completo, login_apex, id_gestor from colaborador where login_apex is not null
```

---

## 1. Banco

### 1.1 Instalar

**Pelo SQLcl:** `cd modulos/ponto-eletronico` e `sql <usuario>@<servico> @instalar.sql`.

**Pelo SQL Workshop:** *SQL Workshop › SQL Scripts › Upload*. Envie e rode um arquivo por vez, **nesta ordem**:

1. `01_ddl_ponto.sql`
2. `03_pkg_ponto.pks`
3. `03_pkg_ponto.pkb`
4. `04_pkg_ponto_ui.pks`
5. `04_pkg_ponto_ui.pkb`
6. `02_seed_ponto.sql` (por último, mesmo com o número 02: ele usa o `pkg_historico_carreira` e precisa das tabelas do passo 1)

O `instalar.sql` não roda no SQL Workshop, porque o `@@` é comando do SQLcl.

### 1.2 Conferir (SQL Commands, um comando por vez, sem `;` no final)

```sql
select object_name, object_type, status from user_objects
 where object_name in ('PKG_PONTO', 'PKG_PONTO_UI', 'VW_PONTO_MARCACAO_VIGENTE', 'TRG_PONTO_MARCACAO_IMUTAVEL')
 order by 1, 2
```
Todos com `VALID`. Se algum estiver `INVALID`:

```sql
select name, type, line, position, text from user_errors
 where name in ('PKG_PONTO', 'PKG_PONTO_UI') order by name, type, sequence
```

```sql
select (select count(*) from ponto_jornada) jornadas,
       (select count(*) from ponto_colaborador) vinculos,
       (select count(*) from ponto_feriado) feriados
  from dual
```
Deve voltar 1 jornada por empresa, 1 vínculo por colaborador e 20 feriados por empresa (10 em cada ano: 9 de data fixa e a Sexta-feira Santa).

Teste as telas fora do APEX, trocando `123` pelo `id_colaborador` da sua conta de teste:

```sql
select pkg_ponto_ui.render_relogio(123) from dual
```
Deve voltar `<section class="cx-ponto-card cx-ponto-relogio" ...>`.

```sql
select pkg_ponto_ui.render_espelho(null, 7, 'S', 123) from dual
```
Deve voltar o card do espelho com o `<select>` do mês.

### 1.3 Ajustar para a realidade da empresa (opcional)

A jornada padrão é seg a sex, 09:00 às 18:00, com 1h de intervalo, 40h semanais, 10 min de tolerância e 6 meses de validade do banco. Os horários são guardados em minutos desde a meia-noite (09:00 = 540). Exemplos:

```sql
update ponto_jornada set nr_min_tolerancia = 5 where id_empresa = 1
```

```sql
insert into ponto_feriado (id_empresa, dt_feriado, nm_feriado)
values (1, date '2027-01-25', 'Aniversário de São Paulo')
```
Os feriados estaduais e municipais entram assim. O seed traz só os nacionais de 2026 e 2027, então os anos seguintes também precisam ser incluídos.

### 1.4 Dados de demonstração (opcional, para ver a tela cheia)

Sem isto, o espelho começa vazio no dia da instalação. Abra `05_dados_demo.sql`, troque o `0` em `c_id_colaborador` pelo id da conta de teste e rode em *SQL Scripts*. Ele cria uns 5 meses de ponto, com um dia sem saída, um dia abonado e o crédito perto de vencer. Para tirar: rode `06_remover_dados_demo.sql`.

---

## 2. Arquivos estáticos

Em *Shared Components › Static Application Files › Create File*, envie os dois arquivos **na raiz** (sem pasta):

| File Name | Arquivo |
|---|---|
| `ponto.css` | `modulos/ponto-eletronico/ponto.css` |
| `ponto.min.css` | `modulos/ponto-eletronico/ponto.min.css` |

A página carrega `ponto#MIN#.css`, então os dois precisam existir e estar iguais. Quando mudar o `.css`, gere o `.min.css` de novo e suba os dois.

---

## 3. Autorização `APROVADOR_PONTO`

*Shared Components › Authorization Schemes › Create › From Scratch* (confirmar no 26.1.5):

| Atributo | Valor |
|---|---|
| Name | `APROVADOR_PONTO` |
| Scheme Type | **PL/SQL Function Returning Boolean** |
| PL/SQL Function Body | `return pkg_ponto.fn_e_aprovador = 'S';` |
| Error Message | `Acesso restrito à gestão direta e ao RH.` |
| Validate authorization scheme | **Once per session** |

---

## 4. Página 30 · Ponto eletrônico

### 4.1 Criar a página

*App Builder › Create Page › Blank Page* (confirmar no 26.1.5):

| Campo | Valor |
|---|---|
| Page Number | `30` |
| Name | `Ponto eletrônico` |
| Page Mode | **Normal** |
| Breadcrumb | não usar |
| Navigation | não criar entrada no menu (a seção 8 cria) |

Depois clique no nó **Page 30** no topo da árvore:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Alias | `PONTO-ELETRONICO` |
| Identification | Title | `Ponto eletrônico` |
| Appearance | Page Template | **Standard** (o mesmo da página 20) |
| CSS | File URLs | `#APP_FILES#ponto#MIN#.css` |
| JavaScript | Execute when Page Loads | conteúdo de `modulos/ponto-eletronico/ponto-pagina.js` |
| Security | Authorization Scheme | **COLABORADOR** |
| Security | Page Access Protection | **Arguments Must Have Checksum** |

Se a página tiver sido criada com alguma região de breadcrumb, apague-a: o título vem da região do passo 4.2.

### 4.2 Cabeçalho

Botão direito em **Breadcrumb Bar** › **Create Region** (confirmar no 26.1.5):

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `Cabeçalho` |
| Identification | Type | **Dynamic Content** |
| Source | PL/SQL Function Body returning a CLOB | `return pkg_ponto_ui.render_cabecalho;` |
| Appearance | Template | **Blank with Attributes (No Grid)** |

### 4.3 Coluna principal

Botão direito em **Body** › **Create Region**:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `Coluna principal` |
| Identification | Type | **Static Content** (Source vazio) |
| Layout | Sequence | 10 |
| Layout | Start New Row | Yes |
| Layout | Column Span | **8** |
| Appearance | Template | **Blank with Attributes** |

Botão direito em **Coluna principal** › **Create Sub Region**, duas vezes:

| Seção | Atributo | Relógio | Espelho |
|---|---|---|---|
| Identification | Name | `Relógio` | `Espelho` |
| Identification | Type | **Dynamic Content** | **Dynamic Content** |
| Source | PL/SQL Function Body returning a CLOB | `return pkg_ponto_ui.render_relogio;` | `return pkg_ponto_ui.render_espelho(:P30_COMPETENCIA);` |
| Source | Page Items to Submit | (vazio) | `P30_COMPETENCIA` |
| Layout | Sequence | 10 | 20 |
| Appearance | Template | **Blank with Attributes** | **Blank with Attributes** |
| Advanced | HTML DOM ID | `ponto_relogio` | `ponto_espelho` |

**O HTML DOM ID é obrigatório em todas as regiões desta página.** O JavaScript procura as regiões por ele. No 26.1 o Static ID só identifica a região no export; sem o HTML DOM ID o APEX gera `R<número>` e a região não atualiza (`docs/ai-context/08` §3, "Static ID ≠ id do HTML").

Item do mês: botão direito em **Coluna principal** › **Create Page Item**:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `P30_COMPETENCIA` |
| Identification | Type | **Hidden** |
| Settings | Value Protected | **No** (o JavaScript muda o valor) |
| Security | Session State Protection | **Unrestricted** |

O valor vem do usuário, mas não é confiável nem precisa ser: o package só usa o mês para ler os dados da própria conta logada, e um valor inválido cai no mês atual.

### 4.4 Coluna lateral

Botão direito em **Body** › **Create Region**:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `Coluna lateral` |
| Identification | Type | **Static Content** (Source vazio) |
| Layout | Sequence | 20 |
| Layout | Start New Row | **No** |
| Layout | Column Span | **4** |
| Appearance | Template | **Blank with Attributes** |

Botão direito em **Coluna lateral** › **Create Sub Region**, três vezes:

| Seção | Atributo | Banco | Pendências | Jornada |
|---|---|---|---|---|
| Identification | Name | `Banco de horas` | `Pendências` | `Sua jornada` |
| Identification | Type | **Dynamic Content** | **Dynamic Content** | **Dynamic Content** |
| Source | PL/SQL Function Body returning a CLOB | `return pkg_ponto_ui.render_banco;` | `return pkg_ponto_ui.render_pendencias;` | `return pkg_ponto_ui.render_jornada;` |
| Layout | Sequence | 10 | 20 | 30 |
| Appearance | Template | **Blank with Attributes** | **Blank with Attributes** | **Blank with Attributes** |
| Advanced | HTML DOM ID | `ponto_banco` | `ponto_pendencias` | `ponto_jornada` |

### 4.5 Diálogos

Botão direito em **Dialogs, Drawers and Popups** › **Create Region** (confirmar no 26.1.5), quatro vezes. Em todos: *Type* **Dynamic Content**, *Template* **Inline Dialog**, *Template Options* Size **Large** e Auto Height (confirmar no 26.1.5).

| Name / Title | PL/SQL Function Body returning a CLOB | Page Items to Submit | HTML DOM ID |
|---|---|---|---|
| `Comprovantes de marcação` | `return pkg_ponto_ui.render_comprovantes;` | | `ponto_dlg_comprovantes` |
| `Espelho do mês` | `return pkg_ponto_ui.render_espelho(:P30_COMPETENCIA, null, 'N');` | `P30_COMPETENCIA` | `ponto_dlg_mes` |
| `Extrato do banco de horas` | `return pkg_ponto_ui.render_extrato;` | | `ponto_dlg_extrato` |
| `Assinar espelho` | `return pkg_ponto_ui.render_assinatura;` | | `ponto_dlg_assinatura` |

### 4.6 Ajax Callbacks

Na aba **Processing** do Page Designer, botão direito em **Ajax Callback** › **Create Process**, três vezes. *Type* **Execute Code** em todos. O **Name** precisa ser exatamente este, pois o JavaScript chama por ele:

| Name | PL/SQL Code |
|---|---|
| `REGISTRAR_MARCACAO` | `pkg_ponto_ui.ajax_registrar(apex_application.g_x01);` |
| `ASSINAR_ESPELHO` | `pkg_ponto_ui.ajax_assinar(apex_application.g_x01);` |
| `BAIXAR_ESPELHO` | `pkg_ponto_ui.ajax_baixar_espelho(apex_application.g_x01);` |

### 4.7 Como deve ficar a árvore

```
Page 30: Ponto eletrônico                  (ponto#MIN#.css, COLABORADOR)
├── Breadcrumb Bar
│   └── Cabeçalho                          (render_cabecalho)
├── Body
│   ├── Coluna principal                   (10, span 8)
│   │   ├── P30_COMPETENCIA                (Hidden, Value Protected No)
│   │   ├── Relógio                        (ponto_relogio)
│   │   └── Espelho                        (ponto_espelho, submit P30_COMPETENCIA)
│   └── Coluna lateral                     (20, span 4, não começa linha)
│       ├── Banco de horas                 (ponto_banco)
│       ├── Pendências                     (ponto_pendencias)
│       └── Sua jornada                    (ponto_jornada)
├── Dialogs, Drawers and Popups
│   ├── Comprovantes de marcação           (ponto_dlg_comprovantes)
│   ├── Espelho do mês                     (ponto_dlg_mes, submit P30_COMPETENCIA)
│   ├── Extrato do banco de horas          (ponto_dlg_extrato)
│   └── Assinar espelho                    (ponto_dlg_assinatura)
└── Ajax Callback
    ├── REGISTRAR_MARCACAO
    ├── ASSINAR_ESPELHO
    └── BAIXAR_ESPELHO
```

**Ainda não rode a página.** O cabeçalho e as pendências montam links para a página 31, que só existe depois da seção 5.

---

## 5. Página 31 · Solicitar ajuste (modal)

### 5.1 Criar a página

*Create Page › Blank Page*: Page Number `31`, Name `Solicitar ajuste`, Page Mode **Modal Dialog**, sem breadcrumb e sem menu. Depois, no nó **Page 31**:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Alias | `SOLICITAR-AJUSTE` |
| Security | Authorization Scheme | **COLABORADOR** |
| Security | Page Access Protection | **Arguments Must Have Checksum** |

### 5.2 Itens

Crie em **Content Body** (a página 22 é o modelo):

| Name | Type | Label | Valores | Sequence |
|---|---|---|---|---|
| `P31_DT_REFERENCIA` | **Date Picker** | `Dia` | *Format Mask* `DD/MM/YYYY`; *Default* › **PL/SQL Expression**: `to_char(pkg_historico_carreira.fn_hoje(:G_ID_EMPRESA), 'DD/MM/YYYY')`; Value Required Yes | 10 |
| `P31_TP_AJUSTE` | **Radio Group** | `O que você precisa?` | *LOV* Static Values: `STATIC:Incluir ou corrigir marcação;MARCACAO,Abonar o dia;ABONO`; *Display Null Value* No; *Default* Static `MARCACAO`; Value Required Yes | 20 |
| `P31_TP_MARCACAO` | **Select List** | `Marcação` | *LOV* Static Values: `STATIC2:Entrada;ENTRADA,Saída para intervalo;INTERVALO,Retorno do intervalo;RETORNO,Saída;SAIDA`; *Display Null Value* Yes, texto `Escolha` | 30 |
| `P31_HR_MARCACAO` | **Text Field** | `Horário` | *Maximum Length* 5; *Inline Help Text* `No formato HH:MM, por exemplo 18:05.` | 40 |
| `P31_DS_MOTIVO` | **Textarea** | `Motivo` | *Maximum Length* 2000; Value Required Yes; *Inline Help Text* `Quem aprova vê este texto.` | 50 |

Nos itens de valor obrigatório, *Appearance › Template* **Required - Floating**; nos outros, **Optional - Floating**.

### 5.3 Botões

Botão direito em **Dialog Footer** › **Create Region** (confirmar no 26.1.5): Name `Botões`, Type **Static Content**, Template **Buttons Container**. Nessa região:

| Button Name | Label | Slot (Layout › Position) | Template / Hot | Behavior › Action |
|---|---|---|---|---|
| `CANCELAR` | `Cancelar` | **Close** | Text | **Defined by Dynamic Action** |
| `ENVIAR` | `Enviar pedido` | **Next** | Text, Hot **Yes** | Submit Page (padrão); Warn on Unsaved Changes **Do Not Check** |

### 5.4 Dynamic actions

**Cancelar:** botão direito em `CANCELAR` › **Create Dynamic Action**. Name `Cancelar`, Event Click. Ação True: **Cancel Dialog**, Fire on Initialization **Off**.

**Mostrar campos de marcação:**

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `Tipo de ajuste` |
| When | Event | **Change** |
| When | Selection Type | **Item(s)** · `P31_TP_AJUSTE` |
| Client-side Condition | Type | **Item = Value** |
| Client-side Condition | Item / Value | `P31_TP_AJUSTE` / `MARCACAO` |

- Ação **True**: **Show**, Affected Elements Item(s) `P31_TP_MARCACAO,P31_HR_MARCACAO`, Fire on Initialization **On**.
- Ação **False**: **Hide**, os mesmos itens, Fire on Initialization **On**.

### 5.5 Processos

Na aba **Processing**, em **Processes**:

| Sequence | Name | Type | Código | Server-side Condition | Success Message |
|---|---|---|---|---|---|
| 10 | `Enviar` | Execute Code | bloco abaixo | When Button Pressed **ENVIAR** | |
| 20 | `Fechar` | **Close Dialog** | | When Button Pressed **ENVIAR** | `Pedido enviado para aprovação.` |

```plsql
declare
  l_id number;
begin
  l_id := pkg_ponto.solicitar_ajuste(
            p_dt_referencia => :P31_DT_REFERENCIA,
            p_tp_ajuste     => :P31_TP_AJUSTE,
            p_tp_marcacao   => :P31_TP_MARCACAO,
            p_hr_marcacao   => :P31_HR_MARCACAO,
            p_ds_motivo     => :P31_DS_MOTIVO);
end;
```

---

## 6. Página 33 · Responder ajuste (modal)

Crie a 33 antes da 32, porque o relatório da 32 tem um link para ela.

### 6.1 Criar a página

*Create Page › Blank Page*: Page Number `33`, Name `Responder ajuste`, Page Mode **Modal Dialog**. No nó **Page 33**: Alias `RESPONDER-AJUSTE`, Authorization Scheme **APROVADOR_PONTO**, Page Access Protection **Arguments Must Have Checksum**.

### 6.2 Itens

Crie em **Content Body** (a página 23 é o modelo):

| Name | Type | Label | Detalhes | Sequence |
|---|---|---|---|---|
| `P33_ID_AJUSTE` | **Hidden** | | Value Protected **Yes** | 10 |
| `P33_NM_COLABORADOR` | **Display Only** | `Colaborador` | | 20 |
| `P33_DS_PEDIDO` | **Display Only** | `Pedido` | | 30 |
| `P33_DS_MOTIVO` | **Display Only** | `Motivo` | | 40 |
| `P33_ST_AJUSTE` | **Radio Group** | `Resposta` | *LOV* Static Values: `STATIC:Aprovar;APROVADO,Recusar;RECUSADO`; Display Null Value No; Value Required Yes | 50 |
| `P33_DS_RESPOSTA` | **Textarea** | `Mensagem ao colaborador` | Maximum Length 2000; Inline Help Text `Obrigatória se recusar.` | 60 |

### 6.3 Botões

Mesma região `Botões` do passo 5.3: `CANCELAR` (Dynamic Action **Cancel Dialog**) e `RESPONDER` (Label `Responder`, Hot Yes, Submit Page, Warn on Unsaved Changes **Do Not Check**).

### 6.4 Processos

**Carregar**, na aba **Pre-Rendering** › **Before Header** › **Create Process**. Type **Execute Code**:

```plsql
begin
  if pkg_ponto.fn_pode_aprovar(:P33_ID_AJUSTE) <> 'S' then
    raise_application_error(-20067, 'Você não pode responder a este pedido: ele cabe ao gestor direto ou ao RH.');
  end if;

  select c.nome_completo,
         to_char(a.dt_referencia, 'DD/MM/YYYY') || ' · '
         || case a.tp_ajuste
              when 'ABONO' then 'Abonar o dia'
              else case a.tp_marcacao
                     when 'ENTRADA'   then 'Entrada'
                     when 'INTERVALO' then 'Saída para intervalo'
                     when 'RETORNO'   then 'Retorno do intervalo'
                     else 'Saída'
                   end || ' às ' || to_char(a.dh_solicitada, 'HH24:MI')
            end,
         a.ds_motivo
    into :P33_NM_COLABORADOR, :P33_DS_PEDIDO, :P33_DS_MOTIVO
    from ponto_ajuste a
    join colaborador c on c.id_colaborador = a.id_colaborador
   where a.id_ajuste  = :P33_ID_AJUSTE
     and a.id_empresa = :G_ID_EMPRESA
     and a.st_ajuste  = 'PENDENTE';
exception
  when no_data_found then
    raise_application_error(-20066, 'Pedido não encontrado ou já respondido.');
end;
```

Na aba **Processing**:

| Sequence | Name | Type | Código | Server-side Condition | Success Message |
|---|---|---|---|---|---|
| 10 | `Responder` | Execute Code | bloco abaixo | When Button Pressed **RESPONDER** | |
| 20 | `Fechar` | **Close Dialog** | | When Button Pressed **RESPONDER** | `Resposta registrada.` |

```plsql
pkg_ponto.responder_ajuste(
  p_id_ajuste   => :P33_ID_AJUSTE,
  p_st_ajuste   => :P33_ST_AJUSTE,
  p_ds_resposta => :P33_DS_RESPOSTA);
```

---

## 7. Página 32 · Ajustes de ponto

### 7.1 Criar a página

*Create Page › Blank Page*: Page Number `32`, Name `Ajustes de ponto`, Page Mode **Normal**. No nó **Page 32**: Alias `AJUSTES-PONTO`, Page Template igual ao da 30, Authorization Scheme **APROVADOR_PONTO**, Page Access Protection **Arguments Must Have Checksum**.

### 7.2 Cabeçalho

Em **Breadcrumb Bar**, região Name `Cabeçalho`, Type **Static Content**, Template **Blank with Attributes (No Grid)**, CSS Classes `cx-cabecalho-pagina`. *Source › HTML Code*:

```html
<div class="cx-cabecalho-pagina__texto">
  <h1 class="cx-cabecalho-pagina__titulo">Ajustes de ponto</h1>
  <p class="cx-cabecalho-pagina__descricao">Pedidos de ajuste e abono que aguardam a sua resposta.</p>
</div>
```

### 7.3 Relatório

Em **Body**, região:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `Pedidos pendentes` |
| Identification | Type | **Interactive Report** |
| Source | Type | **SQL Query** |
| Appearance | Template | **Interactive Report** |
| Appearance | CSS Classes | `cx-relatorio` |

```sql
select a.id_ajuste,
       c.nome_completo as colaborador,
       a.dt_referencia as dia,
       case a.tp_ajuste
         when 'ABONO' then 'Abonar o dia'
         else case a.tp_marcacao
                when 'ENTRADA'   then 'Entrada'
                when 'INTERVALO' then 'Saída para intervalo'
                when 'RETORNO'   then 'Retorno do intervalo'
                else 'Saída'
              end
       end as pedido,
       to_char(a.dh_solicitada, 'HH24:MI') as horario,
       a.ds_motivo as motivo,
       cast(a.dh_pedido as date) as pedido_em,
       'Responder' as responder
  from ponto_ajuste a
  join colaborador c on c.id_colaborador = a.id_colaborador
 where a.id_empresa = :G_ID_EMPRESA
   and a.st_ajuste  = 'PENDENTE'
   and pkg_ponto.fn_pode_aprovar(a.id_ajuste) = 'S'
```

Colunas:

| Coluna | Ajuste |
|---|---|
| `ID_AJUSTE` | Type **Hidden Column** |
| `DIA` | Format Mask `DD/MM/YYYY` |
| `PEDIDO_EM` | Heading `Pedido em`, Format Mask `DD/MM/YYYY HH24:MI` |
| `RESPONDER` | Type **Link**; Target: Page `33`, Set Items `P33_ID_AJUSTE` = `#ID_AJUSTE#`, Clear Cache `33`; Link Text `Responder` |

### 7.4 Atualizar ao fechar o modal

Botão direito na região `Pedidos pendentes` › **Create Dynamic Action**: Name `Pedido respondido`, Event **Dialog Closed**. Ação True: **Refresh**, Affected Elements Region `Pedidos pendentes`, Fire on Initialization **Off**.

---

## 8. Menu lateral

*Shared Components › Navigation Menu › Navigation Menu* (confirmar no 26.1.5). Crie duas entradas:

| Seq | Label | Pai | Ícone | Target | Current (Colon Delimited Page List) | Authorization |
|---|---|---|---|---|---|---|
| 35 | `Ponto eletrônico` | (nenhum) | `fa-clock-o` | página 30 | `30:31` | `COLABORADOR` |
| 67 | `Ajustes de ponto` | Administração | (vazio) | página 32 | `32:33` | `APROVADOR_PONTO` |

O `fa-clock-o` já tem glifo Lucide no `corlix-tema.css`. A sequência 35 coloca o item entre Chat e Pessoas, como no protótipo.

Saia e entre de novo para o menu e a autorização nova valerem (`docs/ai-context/09` §4.1).

---

## 9. Testar

Use uma conta com colaborador e que tenha gestor. Recarregue com **Ctrl+Shift+R** (Cmd+Shift+R no Mac) para não ver CSS antigo. Para os testes de marcação, comece sem dados de demonstração ou num dia sem marcação.

**Registro**

1. Abra **Ponto eletrônico** no menu. O item fica destacado e o relógio mostra a hora local, mudando sozinho.
2. Clique em **Registrar entrada**. Aparece "Entrada registrada. Comprovante nº N", o primeiro círculo fica azul com a hora e o botão vira **Iniciar intervalo**.
3. Clique de novo em menos de 1 minuto: mensagem "Sua última marcação foi há menos de um minuto".
4. Depois de 1 minuto, registre intervalo e retorno. A previsão de saída acompanha os horários reais. As horas trabalhadas param durante o intervalo e voltam a contar depois do retorno.
5. Registre a saída: o botão fica cinza, "Jornada concluída". A linha de hoje no espelho sai de **Em andamento**.
6. Abra a página em duas abas, registre numa e clique na outra: mensagem de que a marcação não é a próxima, sem gravar duas vezes.
7. **Ver comprovantes** lista as marcações, com número, data e hora, marcação e origem.

**Imutabilidade**

8. No SQL Commands, tente alterar uma marcação real:
   ```sql
   update ponto_marcacao set dh_marcacao = sysdate where ds_origem = 'NAVEGADOR' and rownum = 1
   ```
   Deve dar `ORA-20061: Marcações de ponto não podem ser alteradas nem apagadas`.

**Com os dados de demonstração** (§1.4)

9. **Espelho:** 7 linhas, a mais recente em cima. O último dia útil aparece com **Marcação ausente** e "Incompleto"; o anterior, **Abonado**, 6h00 e saldo `0h00`. Fins de semana não aparecem.
10. Troque o mês no seletor: espelho e rodapé mudam sem recarregar. **Ver mês completo** abre o diálogo com todos os dias do mês escolhido, e feriados aparecem com o nome.
11. **Banco de horas:** saldo, acumulado do mês e aviso âmbar de vencimento. **Ver extrato** mostra os lançamentos e o saldo depois de cada um.
12. **Pendências:** selo "N para resolver", a marcação ausente e o espelho do mês anterior.
13. **Baixar espelho** salva `espelho-ponto-AAAA-MM.csv`. Abra no Excel e confira os acentos e as colunas.

**Ajuste**

14. Em **Marcação ausente**, clique em **Justificar**. O modal abre com dia, tipo e marcação preenchidos. Escolha o horário `18:00`, escreva o motivo e envie. O modal fecha, e o dia passa a **Ajuste em análise** e sai das pendências.
15. Em **Solicitar ajuste**, peça para o mesmo dia e a mesma marcação: "Já existe um pedido igual em análise".
16. Tente um horário fora de ordem (retorno antes do intervalo): mensagem de horários fora de ordem. Mude o tipo para **Abonar o dia**: os campos de marcação somem.
17. Entre com o **gestor** (ou RH). Em **Administração › Ajustes de ponto**, o pedido aparece. Clique em **Responder**, escolha **Recusar** sem mensagem: erro pedindo a explicação. Escolha **Aprovar**. O pedido some da fila.
18. Volte à conta do colaborador. O dia fica **Regular** com a saída `18:00`, e o saldo entra no banco. Em **Ver comprovantes** há uma linha nova com origem **Ajuste aprovado**.
19. Entre com uma conta que não é gestor nem RH e abra a página 32 pelo menu ou URL: acesso negado.

**Assinatura**

20. Em **Espelho de ...**, clique em **Revisar e assinar**, confira o diálogo, clique em **Assinar espelho** e confirme. A pendência some. Peça depois um ajuste para um dia daquele mês: "O espelho deste mês já foi assinado".

**Conta sem vínculo e layout**

21. Entre com uma conta sem colaborador e com o papel Admin RH: só o aviso, sem botões e sem erro. Sem esse papel, a autorização `COLABORADOR` nega o acesso à página, e isso também é esperado.
22. Estreite a janela: as colunas empilham, o botão ocupa a largura toda, a linha do tempo fica vertical e a tabela rola de lado.
23. Tab pela página: botão, seletor e links mostram o contorno azul de foco.

### Como conferir no export

No próximo backup, `corlixhub/pages/p00030-*.apx` deve ter `authorizationScheme: @colaborador`, `fileUrls: #APP_FILES#ponto#MIN#.css`, 10 regiões `type: dynamicContent` com `plsqlFunctionBody: return pkg_ponto_ui.render_...`, cada uma (menos o Cabeçalho) com `advanced { htmlDomId: ponto_... }`, os 4 diálogos com `template: @/inline-dialog` e os 3 processos de Ajax Callback. O `static-files.apx` ganha `ponto.css` e `ponto.min.css`; o `lists.apx`, as duas entradas de menu; o `authorizations.apx`, o `APROVADOR_PONTO`.

### Se não funcionar

| Sintoma | Causa provável | Correção |
|---|---|---|
| `PLS-00201: identifier 'PKG_PONTO_UI' must be declared` | Package não instalado | Seção 1 |
| `PLS-00201` citando `PKG_HISTORICO_CARREIRA` na compilação | Módulo de histórico de carreira não instalado neste schema | Instale-o antes |
| `INVALID` em `PKG_PONTO` ou `PKG_PONTO_UI` | Erro de compilação | Veja `user_errors` (§1.2) e mande o resultado |
| Tudo sem estilo | `ponto.css`/`.min.css` não subiram ou File URLs errado | Seção 2 e passo 4.1; Ctrl+Shift+R |
| Botões do relógio não fazem nada; nada no console | JavaScript não foi colado | Passo 4.1 |
| Registra, mas a tela não atualiza | Região sem **HTML DOM ID** | Passos 4.3 a 4.5 |
| "Ver comprovantes" dá `Region does not support being opened and closed` | Diálogo sem **HTML DOM ID** | Passo 4.5 |
| "Não foi possível concluir agora" ao registrar | Erro inesperado no servidor; a mensagem real vai para o debug | Rode a página em Debug, veja `pkg_ponto_ui:` no log |
| "Não foi possível falar com o servidor" | Ajax Callback com outro nome ou ausente | Passo 4.6: os nomes têm de ser exatos |
| "Sua empresa ainda não tem jornada de trabalho cadastrada" | Empresa criada depois do seed | Rode `02_seed_ponto.sql` de novo (só insere o que falta) |
| Aviso de conta sem vínculo em conta com colaborador | `login_apex` diferente do usuário, ou colaborador de outra empresa | Confira `colaborador.login_apex` e `G_ID_EMPRESA` |
| "Sua sessão não está vinculada a uma empresa" | `G_ID_EMPRESA` vazio | Saia e entre de novo |
| Erro aparece com "ORA-200xx" na tela | Handler de erro do app sem a faixa do módulo | Confira as três linhas do `log_pkg` (`docs/ai-context/08` §3, Módulos) |
| Trocar o mês não muda o espelho, ou dá erro de checksum | Item com proteção ligada, ou sem *Page Items to Submit* | Passo 4.3: Value Protected **No**, Unrestricted e Page Items to Submit |
| Dia de hoje com a data errada | `config_carreira.ds_fuso_horario` da empresa | Confira o fuso da empresa |
| Todos os dias anteriores aparecem como falta | `dt_inicio_controle` no passado sem marcações | Ajuste `ponto_colaborador.dt_inicio_controle` para a data real de início |
| Feriado local virou falta | Feriado não cadastrado | §1.3; os dias passam a valer como feriado no próximo cálculo |
| Modal da p31 abre, mas os campos de marcação não somem | DA `Tipo de ajuste` sem a condição | Passo 5.4 |
| Modal fecha e o espelho não atualiza | Evento não chegou ao `document` | Recarregue a página e mande o console do navegador; o JS escuta `apexafterclosedialog` |
| Erro ao abrir a página 30 citando `P31_...` | Página 31 ainda não criada | Seção 5 |
| Link da página 32 não abre o modal | Coluna `RESPONDER` sem o Target completo | Passo 7.3 |
