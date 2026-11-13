# Suporte TI (páginas 34 a 43) · passo a passo no APEX

Este guia cria a tela do protótipo [`pen_dev/Suporte TI.png`](../../pen_dev/Suporte%20TI.png) e o que ela precisa para funcionar, no App Builder do **APEX 26.1.5**.

Como nos outros guias, a mudança é feita no Builder. O backup diário traz o resultado para `corlixhub/pages/` na `DEV`; editar o `.apx` do repositório não muda o app e é desfeito no próximo backup.

> **Estado do código:** os packages foram compilados e testados em um Oracle 23ai local, com 89 verificações do fluxo do chamado, de permissões, de outra empresa, de XSS e de anexos. Esse banco **não tem APEX**: as APIs do APEX foram simuladas. As páginas, o upload e o download reais só são testados ao seguir este guia (§14).

### Como ler os caminhos deste guia (APEX 26.1.5)

- **Rendering** é a árvore da esquerda do Page Designer; o **painel de propriedades** é o da direita. `Seção › Atributo` indica a seção e o campo no painel do componente selecionado.
- No 26.1.5 a região **não tem a aba nem o nó "Attributes"**. Para achar qualquer atributo, use a busca no topo do painel de propriedades.
- Passos marcados com **(confirmar no 26.1.5)** ainda não foram conferidos na tela desta versão. Se o caminho não existir, não procure por tentativa: tire um print da árvore e do painel e registre o caminho certo neste guia.

### O que será criado

| Página | Tipo | Para quê | Quem acessa |
|---|---|---|---|
| **34 · Suporte TI** | Normal | A tela do protótipo | `COLABORADOR` |
| **35 · Abrir chamado** | Modal | Novo incidente ou solicitação, com anexo | `COLABORADOR` |
| **36 · Chamado** | Modal | Conversa, resposta e reabertura; também faz o download dos anexos | `COLABORADOR` |
| **37 · Base de conhecimento** | Normal | Artigos por assunto e leitura do artigo | `COLABORADOR` |
| **38 · Atendimento TI** | Normal | Fila de chamados | `SUPORTE_TI` (nova) |
| **39 · Atender chamado** | Modal | Assumir, responder, pedir informação e resolver | `SUPORTE_TI` |
| **40 e 41 · Status dos sistemas** | Lista + modal | Status e aviso de instabilidade | `SUPORTE_TI` |
| **42 e 43 · Artigos** | Lista + modal | Escrever e publicar artigos | `SUPORTE_TI` |

Só a 34 está no protótipo. As outras existem porque, sem elas, os botões **Abrir chamado**, **Responder** e **Ver base de conhecimento** não teriam efeito, e a TI não teria como atender nem como publicar o aviso.

### Do protótipo para o app

| Elemento | Como funciona |
|---|---|
| Aviso "Instabilidade na VPN" | Aparece enquanto um sistema não está **Operando** e tem título de aviso (p41). O **x** esconde o aviso até o fim da sessão do navegador ou até a TI alterar o sistema |
| Busca "Descreva o problema" | Procura enquanto a pessoa digita, a partir de 3 letras, sem diferenciar acento nem maiúscula. Título vale mais que o restante do artigo |
| 6 assuntos | Abrem a p37 filtrada pelo assunto |
| Meus chamados | **Em aberto** traz tudo que não foi encerrado, inclusive o resolvido que espera confirmação, como no print. **Resolvidos** traz os encerrados (os 20 mais recentes, com o total na aba) |
| Selos | Na fila, Em atendimento, Aguardando você, Resolvido, Encerrado |
| INC-4821 / REQ-4807 | Prefixo do tipo (incidente ou solicitação) + `id_chamado` |
| "A solução funcionou?" | **Sim, encerrar** encerra na hora. **Não, reabrir** abre a p36 e pede o motivo |
| "Sem resposta, o chamado é encerrado em 27/10" | Prazo de `suporte_config.nr_dias_confirmacao` (3 dias) depois de resolvido. O job `SUPORTE_ENCERRAR_VENCIDOS` encerra às 23:30 |
| Status dos sistemas | Tabela `suporte_sistema`, mantida pela TI na p40 |
| Artigos mais acessados | Os 5 com mais leituras. Cada abertura do artigo soma 1 |
| Prefere falar com alguém? | Ramal, telefone e horário vêm de `suporte_config` |

### Decisões que diferem do print ou que o print não define

- **Conversar com a TI** abre o Chat (p4), sem contato escolhido. Não há canal fixo da TI, e a p4 não aceita abrir uma conversa pela URL.
- **Foto do colaborador:** a mensagem mostra as iniciais, como no print.
- **Prioridade** (baixa, média, alta) não aparece no print. Só a TI vê e define, para ordenar a fila.
- **Quem atende precisa ter colaborador vinculado.** As contas SARAHSILVA, EDUARDOMARINS e ALAIRTONROCHA não têm, então não abrem nem atendem chamados.
- **Encerrado é definitivo.** Se o problema voltar, abre-se outro chamado.
- **Anexos:** um por envio, de até 5 MB, em PNG, JPG, PDF, TXT ou LOG. O download nunca abre o arquivo dentro da página.

### Fica de fora

- **Notificações** e e-mail de chamado novo ou respondido: a TI acompanha pela p38 e o colaborador pela p34.
- **Pendência "chamado de TI" na Início** (`docs/ai-context/07` §5).
- **Prazo de atendimento (SLA)** e relatórios: a previsão é informada à mão.
- **Cancelar chamado:** quem abriu por engano avisa na conversa e a TI resolve.
- **Nota interna da TI:** toda mensagem é vista pelo colaborador. Não escreva senhas nem dados sensíveis nela.
- **Telas de cadastro** de assuntos e dos contatos: por enquanto, por SQL (§1.3).
- **Chamados na busca do cabeçalho** (p29).

### Arquivos do módulo

| Arquivo | O que é |
|---|---|
| `01_ddl_suporte.sql` | Tabelas, triggers de auditoria e `vw_suporte_fila` |
| `02_seed_suporte.sql` | Assuntos, sistemas, artigos e contatos de cada empresa |
| `03_pkg_suporte.pks` / `.pkb` | Regras: abrir, responder, atender, resolver, reabrir, encerrar, anexos |
| `04_pkg_suporte_ui.pks` / `.pkb` | HTML das regiões e Ajax Callbacks |
| `05_job_suporte.sql` | Job diário de encerramento |
| `instalar.sql` | Instala tudo pelo SQLcl |
| `suporte.css` / `suporte.min.css` | Estilos (classes `cx-sup-*`); sobem como Static Application Files |
| `suporte-pagina.js` | JavaScript da página 34 |

**Pré-requisito:** módulo de histórico de carreira instalado (`pkg_historico_carreira.fn_hoje`, `fn_data_local` e `fn_empresa_contexto`).

**Contas de teste:** use duas contas com colaborador vinculado, uma para abrir e outra para atender.

```sql
select id_colaborador, nome_completo, login_apex from colaborador where login_apex is not null
```

---

## 1. Banco

### 1.1 Instalar

**Pelo SQLcl:** `cd modulos/suporte-ti` e `sql <usuario>@<servico> @instalar.sql`.

**Pelo SQL Workshop:** *SQL Workshop › SQL Scripts › Upload*. Envie e rode um arquivo por vez, **nesta ordem**:

1. `01_ddl_suporte.sql`
2. `03_pkg_suporte.pks`
3. `03_pkg_suporte.pkb`
4. `04_pkg_suporte_ui.pks`
5. `04_pkg_suporte_ui.pkb`
6. `02_seed_suporte.sql`
7. `05_job_suporte.sql`

O `instalar.sql` não roda no SQL Workshop, porque o `@@` é comando do SQLcl.

### 1.2 Conferir (SQL Commands, um comando por vez, sem `;` no final)

```sql
select object_name, object_type, status from user_objects
 where object_name in ('PKG_SUPORTE', 'PKG_SUPORTE_UI', 'VW_SUPORTE_FILA', 'TRG_SUPORTE_SISTEMA_AUD', 'TRG_SUPORTE_ARTIGO_AUD')
 order by 1, 2
```
Todos com `VALID`. Se algum estiver `INVALID`:

```sql
select name, type, line, position, text from user_errors
 where name in ('PKG_SUPORTE', 'PKG_SUPORTE_UI') order by name, type, sequence
```

```sql
select (select count(*) from suporte_assunto) assuntos,
       (select count(*) from suporte_sistema) sistemas,
       (select count(*) from suporte_artigo) artigos,
       (select count(*) from suporte_config) configuracoes
  from dual
```
Por empresa, deve voltar 6 assuntos, 5 sistemas, 7 artigos e 1 configuração.

```sql
select job_name, enabled, state, next_run_date from user_scheduler_jobs where job_name = 'SUPORTE_ENCERRAR_VENCIDOS'
```
Deve voltar `TRUE`, `SCHEDULED` e a próxima execução às 23:30. Empresa nova: rode `02_seed_suporte.sql` de novo; ele só insere o que falta.

### 1.3 Revisar o conteúdo de exemplo (obrigatório antes de liberar)

**O ramal, o telefone e o horário são os do protótipo, e os artigos são genéricos.** Sem esta revisão, a página mostra um telefone que não é da empresa. A TI deve conferir os artigos na p42 (§11) e os contatos assim:

```sql
update suporte_config
   set ds_ramal = '<ramal>', ds_telefone = '<telefone>', ds_horario = '<horário>'
 where id_empresa = 1
```

Campo vazio some da tela. Para mudar o prazo de confirmação, use `nr_dias_confirmacao` (1 a 30). Para os assuntos:

```sql
update suporte_assunto set nm_assunto = 'Novo nome', fl_ativo = 'S' where id_assunto = 1
```
Os ícones aceitos em `cd_icone` são `key`, `mail`, `laptop`, `wifi`, `janela` e `printer`.

---

## 2. Arquivos estáticos

Em *Shared Components › Static Application Files › Create File*, envie os dois arquivos na pasta `modulos/suporte-ti/` (como os outros módulos):

| File Name | Arquivo |
|---|---|
| `modulos/suporte-ti/suporte.css` | `modulos/suporte-ti/suporte.css` |
| `modulos/suporte-ti/suporte.min.css` | `modulos/suporte-ti/suporte.min.css` |

As páginas 34, 36, 37 e 39 carregam `#APP_FILES#modulos/suporte-ti/suporte#MIN#.css` (é o que está no backup de 13/11/2026; versões antigas deste guia mandavam subir na raiz), então os dois precisam existir e estar iguais. Quando mudar o `.css`, gere o `.min.css` de novo e suba os dois.

---

## 3. Papel e autorização `SUPORTE_TI`

### 3.1 Criar o papel

*Shared Components › Application Access Control › Add Role*:

| Atributo | Valor |
|---|---|
| Name | `Suporte TI` |
| Static ID | `suporte-ti` |
| Description | `Equipe de TI. Atende chamados e mantém o status dos sistemas e os artigos.` |

### 3.2 Criar a autorização

*Shared Components › Authorization Schemes › Create › From Scratch* (confirmar no 26.1.5). É igual à `ADMIN_RH`:

| Atributo | Valor |
|---|---|
| Name | `SUPORTE_TI` |
| Scheme Type | **Is In Role or Group** |
| Type | **Application Role** (confirmar no 26.1.5) |
| Name(s) | `Suporte TI` |
| Error Message | `Acesso restrito à equipe de TI.` |
| Validate authorization scheme | **Once per session** |

### 3.3 Dar o papel à equipe

**O atendimento fica com pessoas escolhidas, e não com um cargo inteiro.** Quem tem o papel lê os chamados e os anexos de toda a empresa, então ele vai só para os desenvolvedores designados para o suporte. **Não inclua `suporte-ti` em `cargo_papel`:** todo mundo cadastrado depois com aquele cargo receberia o papel, e os desenvolvedores que não atendem também.

Para cada pessoa designada:

1. Confira se a conta dela tem colaborador vinculado. Sem isso, ela não consegue atender:
   ```sql
   select id_colaborador, nome_completo, login_apex
     from colaborador
    where upper(login_apex) = upper('<login>')
   ```
2. Em *Application Access Control › User Role Assignments › Add User Role Assignment*, escolha o usuário e o papel `Suporte TI` (`modulos/perfis-acesso/Etapas-perfis-acesso.md` §6.1). O `apex_acl` não funciona no SQL Commands.
3. Peça para a pessoa sair e entrar de novo.

Quando alguém deixar o suporte, remova o papel na mesma tela e peça o mesmo novo login. Os chamados que essa pessoa atendia continuam com ela até outra pessoa da equipe escolher **Assumir o chamado**, então passe os que estiverem em aberto antes de remover o papel.

Tenha ao menos duas pessoas com o papel, para a fila não parar em férias ou ausências. O papel só libera as páginas de suporte: não dá acesso a outras áreas de administração.

---

## 4. Página 34 · Suporte TI

### 4.1 Criar a página

*App Builder › Create Page › Blank Page* (confirmar no 26.1.5):

| Campo | Valor |
|---|---|
| Page Number | `34` |
| Name | `Suporte TI` |
| Page Mode | **Normal** |
| Breadcrumb | não usar |
| Navigation | não criar entrada no menu (a seção 12 cria) |

Depois clique no nó **Page 34** no topo da árvore:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Alias | `SUPORTE-TI` |
| Identification | Title | `Suporte TI` |
| Appearance | Page Template | **Standard** (o mesmo da página 30) |
| CSS | File URLs | `#APP_FILES#suporte#MIN#.css` |
| JavaScript | Execute when Page Loads | conteúdo de `modulos/suporte-ti/suporte-pagina.js` |
| Security | Authorization Scheme | **COLABORADOR** |
| Security | Page Access Protection | **Arguments Must Have Checksum** |

### 4.2 Cabeçalho

Botão direito em **Breadcrumb Bar** › **Create Region** (confirmar no 26.1.5):

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `Cabeçalho` |
| Identification | Type | **Dynamic Content** |
| Source | PL/SQL Function Body returning a CLOB | `return pkg_suporte_ui.render_cabecalho;` |
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

Botão direito em **Coluna principal** › **Create Sub Region**, três vezes. Em todas: *Type* **Dynamic Content** e *Template* **Blank with Attributes**.

| Name | Sequence | PL/SQL Function Body returning a CLOB | Advanced › HTML DOM ID |
|---|---|---|---|
| `Aviso` | 10 | `return pkg_suporte_ui.render_aviso;` | `suporte_aviso` |
| `Como podemos ajudar` | 20 | `return pkg_suporte_ui.render_ajuda;` | `suporte_ajuda` |
| `Meus chamados` | 30 | `return pkg_suporte_ui.render_chamados;` | `suporte_chamados` |

**O HTML DOM ID de `Meus chamados` é obrigatório.** O JavaScript atualiza a região por ele. No 26.1 o Static ID só identifica a região no export; sem o HTML DOM ID o APEX gera `R<número>` e a lista não atualiza (`docs/ai-context/08` §3, "Static ID ≠ id do HTML").

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

Botão direito em **Coluna lateral** › **Create Sub Region**, três vezes, com o mesmo *Type* e *Template*:

| Name | Sequence | PL/SQL Function Body returning a CLOB |
|---|---|---|
| `Status dos sistemas` | 10 | `return pkg_suporte_ui.render_status;` |
| `Artigos mais acessados` | 20 | `return pkg_suporte_ui.render_artigos;` |
| `Prefere falar com alguém` | 30 | `return pkg_suporte_ui.render_contato;` |

### 4.5 Ajax Callbacks

Na aba **Processing**, botão direito em **Ajax Callback** › **Create Process**, duas vezes. *Type* **Execute Code**. O **Name** precisa ser exatamente este, pois o JavaScript chama por ele:

| Name | PL/SQL Code |
|---|---|
| `BUSCAR_ARTIGOS` | `pkg_suporte_ui.ajax_buscar(apex_application.g_x01);` |
| `CONFIRMAR_SOLUCAO` | `pkg_suporte_ui.ajax_confirmar(to_number(apex_application.g_x01));` |

### 4.6 Como deve ficar a árvore

```
Page 34: Suporte TI                        (suporte#MIN#.css, COLABORADOR)
├── Breadcrumb Bar
│   └── Cabeçalho                          (render_cabecalho)
├── Body
│   ├── Coluna principal                   (10, span 8)
│   │   ├── Aviso                          (suporte_aviso)
│   │   ├── Como podemos ajudar            (suporte_ajuda)
│   │   └── Meus chamados                  (suporte_chamados)
│   └── Coluna lateral                     (20, span 4, não começa linha)
│       ├── Status dos sistemas
│       ├── Artigos mais acessados
│       └── Prefere falar com alguém
└── Ajax Callback
    ├── BUSCAR_ARTIGOS
    └── CONFIRMAR_SOLUCAO
```

**Ainda não rode a página.** Ela monta links para as páginas 35, 36 e 37, que só existem depois das próximas seções.

---

## 5. Página 35 · Abrir chamado (modal)

### 5.1 Criar a página

*Create Page › Blank Page*: Page Number `35`, Name `Abrir chamado`, Page Mode **Modal Dialog**, sem breadcrumb e sem menu. Depois, no nó **Page 35**:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Alias | `ABRIR-CHAMADO` |
| Security | Authorization Scheme | **COLABORADOR** |
| Security | Page Access Protection | **Arguments Must Have Checksum** |

### 5.2 Itens

Crie em **Content Body** (a página 31 é o modelo):

| Name | Type | Label | Valores | Sequence |
|---|---|---|---|---|
| `P35_TP_CHAMADO` | **Radio Group** | `O que você precisa?` | *LOV* Static Values: `STATIC2:Algo não está funcionando;INC,Quero pedir algo;REQ`; *Display Null Value* No; *Default* Static `INC`; Value Required Yes | 10 |
| `P35_ID_ASSUNTO` | **Select List** | `Assunto` | *LOV* SQL (abaixo); *Display Null Value* Yes, texto `Escolha`; Value Required Yes | 20 |
| `P35_DS_TITULO` | **Text Field** | `Título` | *Maximum Length* 140; Value Required Yes; *Inline Help Text* `Resuma em poucas palavras.` | 30 |
| `P35_DS_TEXTO` | **Textarea** | `Descrição` | *Maximum Length* 3500; Value Required Yes; *Inline Help Text* `Conte o que aconteceu, desde quando e a mensagem de erro, se houver.` | 40 |
| `P35_ANEXO` | **File Upload** | `Anexo` | Ver a tabela abaixo; *Inline Help Text* `Opcional. PNG, JPG, PDF, TXT ou LOG, até 5 MB.` | 50 |

LOV de `P35_ID_ASSUNTO`:

```sql
select nm_assunto as d, id_assunto as r
  from suporte_assunto
 where id_empresa = :G_ID_EMPRESA
   and fl_ativo = 'S'
 order by nr_ordem
```

Atributos do `P35_ANEXO` (confirmar no 26.1.5):

| Atributo | Valor |
|---|---|
| Storage Type | **Table APEX_APPLICATION_TEMP_FILES** |
| Purge File at | **End of Request** |
| File Types | `.png,.jpg,.jpeg,.pdf,.txt,.log` |
| Allow Multiple Files | **Off** |

O package confere o tipo e o tamanho de novo, porque o navegador pode ser contornado. Nos itens de valor obrigatório, *Appearance › Template* **Required - Floating**; nos outros, **Optional - Floating**.

### 5.3 Botões

Botão direito em **Dialog Footer** › **Create Region** (confirmar no 26.1.5): Name `Botões`, Type **Static Content**, Template **Buttons Container**. Nessa região:

| Button Name | Label | Slot (Layout › Position) | Template / Hot | Behavior › Action |
|---|---|---|---|---|
| `CANCELAR` | `Cancelar` | **Close** | Text | **Defined by Dynamic Action** |
| `ABRIR` | `Abrir chamado` | **Next** | Text, Hot **Yes** | Submit Page; Warn on Unsaved Changes **Do Not Check** |

Botão direito em `CANCELAR` › **Create Dynamic Action**: Name `Cancelar`, Event **Click**. Ação True: **Cancel Dialog**, Fire on Initialization **Off**.

### 5.4 Processos

Na aba **Processing**, em **Processes**:

| Sequence | Name | Type | Código | Server-side Condition | Success Message |
|---|---|---|---|---|---|
| 10 | `Abrir` | Execute Code | bloco abaixo | When Button Pressed **ABRIR** | |
| 20 | `Fechar` | **Close Dialog** | | When Button Pressed **ABRIR** | `Chamado aberto. A equipe de TI vai responder por aqui.` |

```plsql
declare
  l_id number;
begin
  l_id := pkg_suporte.abrir_chamado(
            p_tp_chamado => :P35_TP_CHAMADO,
            p_id_assunto => :P35_ID_ASSUNTO,
            p_ds_titulo  => :P35_DS_TITULO,
            p_ds_texto   => :P35_DS_TEXTO,
            p_anexo      => :P35_ANEXO);
end;
```

---

## 6. Página 36 · Chamado (modal)

### 6.1 Criar a página

*Create Page › Blank Page*: Page Number `36`, Name `Chamado`, Page Mode **Modal Dialog**. No nó **Page 36**:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Alias | `CHAMADO` |
| Appearance | Dialog › Width | `760` (confirmar no 26.1.5) |
| CSS | File URLs | `#APP_FILES#suporte#MIN#.css` |
| Security | Authorization Scheme | **COLABORADOR** |
| Security | Page Access Protection | **Arguments Must Have Checksum** |

### 6.2 Conversa

Em **Content Body**, região Name `Conversa`, Type **Dynamic Content**, Template **Blank with Attributes**, Sequence 10:

```plsql
return pkg_suporte_ui.render_conversa(:P36_ID_CHAMADO);
```

### 6.3 Itens

Crie em **Content Body**. Os dois campos visíveis usam a *Server-side Condition* **PL/SQL Expression** abaixo; no chamado encerrado, eles somem.

```plsql
:P36_ST_CHAMADO in ('ABERTO', 'EM_ATENDIMENTO', 'AGUARDANDO_USUARIO', 'RESOLVIDO')
```

| Name | Type | Label | Detalhes | Sequence |
|---|---|---|---|---|
| `P36_ID_CHAMADO` | **Hidden** | | Value Protected **Yes** | 20 |
| `P36_ID_ANEXO` | **Hidden** | | Value Protected **Yes** | 30 |
| `P36_ST_CHAMADO` | **Hidden** | | Value Protected **Yes** | 40 |
| `P36_DS_TEXTO` | **Textarea** | `Sua mensagem` | Maximum Length 3500; Template **Optional - Floating**; condição acima | 50 |
| `P36_ANEXO` | **File Upload** | `Anexo` | Atributos do passo 5.2; condição acima | 60 |

O texto não é marcado como obrigatório no item: o package devolve a mensagem certa para cada botão.

### 6.4 Botões

Mesma região `Botões` do passo 5.3, com a Dynamic Action **Cancel Dialog** em `CANCELAR` (Label `Fechar`). Os outros dois são *Submit Page*, Hot **Yes**, Warn on Unsaved Changes **Do Not Check**, na posição **Next**, e cada um tem uma *Server-side Condition* **PL/SQL Expression**:

| Button Name | Label | Condição |
|---|---|---|
| `RESPONDER` | `Enviar resposta` | `:P36_ST_CHAMADO in ('ABERTO', 'EM_ATENDIMENTO', 'AGUARDANDO_USUARIO')` |
| `REABRIR` | `Reabrir chamado` | `:P36_ST_CHAMADO = 'RESOLVIDO'` |

### 6.5 Processos

Na aba **Pre-Rendering** › **Before Header**, nesta ordem. Type **Execute Code**:

| Sequence | Name | Código | Server-side Condition |
|---|---|---|---|
| 10 | `Baixar anexo` | `pkg_suporte.baixar_anexo(:P36_ID_ANEXO);` | **Request = Value**, Value `BAIXAR_ANEXO` |
| 20 | `Carregar` | `:P36_ST_CHAMADO := pkg_suporte.fn_situacao(:P36_ID_CHAMADO);` | |

O download é o único caso em que a página não abre. Os links de anexo pedem a página 36 com o request `BAIXAR_ANEXO`, e o `apex_http.download` encerra a resposta ali mesmo.

Na aba **Processing**:

| Sequence | Name | Type | Código | Server-side Condition | Success Message |
|---|---|---|---|---|---|
| 10 | `Responder` | Execute Code | `pkg_suporte.responder(:P36_ID_CHAMADO, :P36_DS_TEXTO, :P36_ANEXO);` | When Button Pressed **RESPONDER** | |
| 20 | `Reabrir` | Execute Code | `pkg_suporte.reabrir(:P36_ID_CHAMADO, :P36_DS_TEXTO, :P36_ANEXO);` | When Button Pressed **REABRIR** | |
| 30 | `Fechar` | **Close Dialog** | | **Request is contained in Value**, Value `RESPONDER,REABRIR` (confirmar no 26.1.5) | `Mensagem enviada à equipe de TI.` |

---

## 7. Página 37 · Base de conhecimento

### 7.1 Criar a página

*Create Page › Blank Page*: Page Number `37`, Name `Base de conhecimento`, Page Mode **Normal**. No nó **Page 37**: Alias `BASE-CONHECIMENTO`, Page Template igual ao da 34, File URLs `#APP_FILES#suporte#MIN#.css`, Authorization Scheme **COLABORADOR**, Page Access Protection **Arguments Must Have Checksum**.

### 7.2 Cabeçalho

Em **Breadcrumb Bar**, região Name `Cabeçalho`, Type **Static Content**, Template **Blank with Attributes (No Grid)**, CSS Classes `cx-cabecalho-pagina`. *Source › HTML Code*:

```html
<div class="cx-cabecalho-pagina__trilha">
  <a href="f?p=&APP_ID.:34:&SESSION.">Suporte TI</a>
</div>
<div class="cx-cabecalho-pagina__texto">
  <h1 class="cx-cabecalho-pagina__titulo">Base de conhecimento</h1>
  <p class="cx-cabecalho-pagina__descricao">Respostas rápidas para as dúvidas mais comuns.</p>
</div>
```

O link é fixo porque não passa parâmetros, e o checksum só é exigido em URLs com argumentos.

### 7.3 Conteúdo e itens

Em **Body**, região Name `Artigos`, Type **Dynamic Content**, Template **Blank with Attributes**:

```plsql
return pkg_suporte_ui.render_base(:P37_ID_ASSUNTO, :P37_ID_ARTIGO);
```

Dentro dela, dois itens **Hidden**, com Value Protected **Yes**: `P37_ID_ASSUNTO` e `P37_ID_ARTIGO`.

### 7.4 Contar a leitura

Em **Pre-Rendering** › **Before Header**, processo Name `Registrar leitura`, Type **Execute Code**, Server-side Condition **Item is NOT NULL** `P37_ID_ARTIGO`:

```plsql
pkg_suporte.registrar_acesso_artigo(:P37_ID_ARTIGO);
```

---

## 8. Página 39 · Atender chamado (modal)

Crie a 39 antes da 38, porque o relatório da 38 tem um link para ela.

### 8.1 Criar a página

*Create Page › Blank Page*: Page Number `39`, Name `Atender chamado`, Page Mode **Modal Dialog**. No nó **Page 39**: Alias `ATENDER-CHAMADO`, Dialog Width `760` (confirmar no 26.1.5), File URLs `#APP_FILES#suporte#MIN#.css`, Authorization Scheme **SUPORTE_TI**, Page Access Protection **Arguments Must Have Checksum**.

### 8.2 Conversa e itens

Em **Content Body**, região Name `Conversa`, Type **Dynamic Content**, Template **Blank with Attributes**, Sequence 10:

```plsql
return pkg_suporte_ui.render_conversa(:P39_ID_CHAMADO);
```

Depois os itens. Todos os visíveis usam a *Server-side Condition* **PL/SQL Expression** `:P39_ST_CHAMADO in ('ABERTO', 'EM_ATENDIMENTO', 'AGUARDANDO_USUARIO')`:

| Name | Type | Label | Detalhes | Sequence |
|---|---|---|---|---|
| `P39_ID_CHAMADO` | **Hidden** | | Value Protected **Yes** | 20 |
| `P39_ST_CHAMADO` | **Hidden** | | Value Protected **Yes** | 30 |
| `P39_ACAO` | **Radio Group** | `O que fazer` | *LOV* Static Values: `STATIC2:Assumir o chamado;ASSUMIR,Responder ao colaborador;RESPONDER,Pedir informação ao colaborador;PEDIR,Resolver;RESOLVER`; Display Null Value No; *Default* Static `RESPONDER`; Value Required Yes | 40 |
| `P39_TP_PRIORIDADE` | **Select List** | `Prioridade` | *LOV* Static Values: `STATIC2:Alta;ALTA,Média;MEDIA,Baixa;BAIXA`; Display Null Value No; Value Required Yes | 50 |
| `P39_DT_PREVISAO` | **Date Picker** | `Previsão` | Format Mask `DD/MM/YYYY`; Inline Help Text `Opcional. O colaborador vê esta data.` | 60 |
| `P39_DS_TEXTO` | **Textarea** | `Mensagem ao colaborador` | Maximum Length 3500; Inline Help Text `O colaborador lê tudo o que for escrito aqui. Em "Resolver", este texto é a solução.` | 70 |
| `P39_ANEXO` | **File Upload** | `Anexo` | Atributos do passo 5.2 | 80 |

### 8.3 Botões

Região `Botões` do passo 5.3: `CANCELAR` (Label `Fechar`, Dynamic Action **Cancel Dialog**) e `SALVAR` (Label `Salvar`, Hot Yes, Submit Page, Warn on Unsaved Changes **Do Not Check**, com a mesma condição dos itens).

### 8.4 Processos

**Carregar**, na aba **Pre-Rendering** › **Before Header** › **Create Process**. Type **Execute Code**:

```plsql
begin
  select st_chamado, tp_prioridade, to_char(dt_previsao, 'DD/MM/YYYY')
    into :P39_ST_CHAMADO, :P39_TP_PRIORIDADE, :P39_DT_PREVISAO
    from suporte_chamado
   where id_chamado = :P39_ID_CHAMADO
     and id_empresa = :G_ID_EMPRESA;
exception
  when no_data_found then
    raise_application_error(-20077, 'Chamado não encontrado.');
end;
```

Na aba **Processing**:

| Sequence | Name | Type | Código | Server-side Condition | Success Message |
|---|---|---|---|---|---|
| 10 | `Atender` | Execute Code | bloco abaixo | When Button Pressed **SALVAR** | |
| 20 | `Fechar` | **Close Dialog** | | When Button Pressed **SALVAR** | `Chamado atualizado.` |

```plsql
pkg_suporte.atender(
  p_id_chamado    => :P39_ID_CHAMADO,
  p_acao          => :P39_ACAO,
  p_ds_texto      => :P39_DS_TEXTO,
  p_tp_prioridade => :P39_TP_PRIORIDADE,
  p_dt_previsao   => :P39_DT_PREVISAO,
  p_anexo         => :P39_ANEXO);
```

---

## 9. Página 38 · Atendimento TI

### 9.1 Criar a página

*Create Page › Blank Page*: Page Number `38`, Name `Atendimento TI`, Page Mode **Normal**. No nó **Page 38**: Alias `ATENDIMENTO-TI`, Page Template igual ao da 34, Authorization Scheme **SUPORTE_TI**, Page Access Protection **Arguments Must Have Checksum**.

### 9.2 Cabeçalho

Em **Breadcrumb Bar**, região Name `Cabeçalho`, Type **Static Content**, Template **Blank with Attributes (No Grid)**, CSS Classes `cx-cabecalho-pagina`:

```html
<div class="cx-cabecalho-pagina__texto">
  <h1 class="cx-cabecalho-pagina__titulo">Atendimento TI</h1>
  <p class="cx-cabecalho-pagina__descricao">Chamados dos colaboradores desta empresa.</p>
</div>
```

### 9.3 Relatório

Em **Body**, região:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `Chamados` |
| Identification | Type | **Interactive Report** |
| Source | Type | **SQL Query** |
| Appearance | Template | **Interactive Report** |
| Appearance | CSS Classes | `cx-relatorio` |

```sql
select id_chamado,
       cd_chamado,
       ds_titulo,
       ds_tipo,
       nm_assunto,
       nm_solicitante,
       nm_atendente,
       ds_status,
       ds_prioridade,
       nr_prioridade,
       dt_previsao,
       pkg_historico_carreira.fn_data_local(id_empresa, dh_abertura) as aberto_em,
       pkg_historico_carreira.fn_data_local(id_empresa, dh_atualizacao) as atualizado_em,
       'Atender' as atender
  from vw_suporte_fila
 where id_empresa = :G_ID_EMPRESA
```

Colunas:

| Coluna | Ajuste |
|---|---|
| `ID_CHAMADO`, `NR_PRIORIDADE` | Type **Hidden Column** |
| `CD_CHAMADO` | Heading `Chamado` |
| `DS_TITULO` | Heading `Título` |
| `DS_TIPO` | Heading `Tipo` |
| `NM_ASSUNTO` | Heading `Assunto` |
| `NM_SOLICITANTE` | Heading `Colaborador` |
| `NM_ATENDENTE` | Heading `Atendente` |
| `DS_STATUS` | Heading `Situação` |
| `DS_PRIORIDADE` | Heading `Prioridade` |
| `DT_PREVISAO` | Heading `Previsão`, Format Mask `DD/MM/YYYY` |
| `ABERTO_EM` | Heading `Aberto em`, Format Mask `DD/MM/YYYY HH24:MI` |
| `ATUALIZADO_EM` | Heading `Atualizado em`, Format Mask `DD/MM/YYYY HH24:MI` |
| `ATENDER` | Heading `Ação`; Type **Link**; Target: Page `39`, Set Items `P39_ID_CHAMADO` = `#ID_CHAMADO#`, Clear Cache `39`; Link Text `Atender` |

### 9.4 Atualizar ao fechar o modal

Botão direito na região `Chamados` › **Create Dynamic Action**: Name `Chamado atendido`, Event **Dialog Closed**. Ação True: **Refresh**, Affected Elements Region `Chamados`, Fire on Initialization **Off**.

### 9.5 Relatório padrão

Rode a página com uma conta que tenha o papel `Suporte TI`. Em **Actions**:

1. **Filter:** `Situação` `!=` `Encerrado`.
2. **Data › Sort:** `Prioridade` não serve, porque ordenaria como texto. Ordene por **Aberto em**, crescente, para o chamado mais antigo ficar em cima.
3. **Report › Save Report**, Save **As Default Report Settings**, Default Report Type **Primary** (confirmar no 26.1.5).

A coluna **Prioridade** continua disponível para filtrar a fila por "Alta".

---

## 10. Páginas 40 e 41 · Status dos sistemas

### 10.1 Criar as páginas

*Create Page › Interactive Report*, com a opção de incluir o formulário (confirmar no 26.1.5). No 26.1.5, só o assistente deixa o formulário editável (`docs/ai-context/08` §3); as páginas 15 e 16 são o modelo.

| Campo | Valor |
|---|---|
| Page Number / Name (lista) | `40` / `Status dos sistemas` |
| Form Page Number / Name | `41` / `Sistema` |
| Form Page Mode | **Modal Dialog** |
| Table | `SUPORTE_SISTEMA` |
| Primary Key | `ID_SISTEMA` |
| Navigation | não criar entrada no menu |

Nas duas páginas: Authorization Scheme **SUPORTE_TI** e Page Access Protection **Arguments Must Have Checksum**.

### 10.2 Lista (p40)

Na região do relatório, *Source › Where Clause*: `id_empresa = :G_ID_EMPRESA`. *Order By Clause*: `nr_ordem`. Deixe visíveis `NM_SISTEMA`, `ST_SISTEMA`, `DS_DETALHE` e `DS_AVISO_TITULO`, e esconda as outras com **Hidden Column**. Headings: `Sistema`, `Situação`, `Detalhe` e `Aviso`.

### 10.3 Formulário (p41)

**Apague** `P41_DH_ATUALIZACAO` e `P41_USR_ATUALIZACAO`: o trigger preenche os dois. Ajuste os outros:

| Item | Ajuste |
|---|---|
| `P41_ID_SISTEMA` | Hidden (o assistente já cria assim) |
| `P41_ID_EMPRESA` | **Hidden**, Value Protected Yes; *Default* Type **Item**, `G_ID_EMPRESA` |
| `P41_NM_SISTEMA` | Label `Sistema` |
| `P41_NR_ORDEM` | Label `Ordem na lista`, **Number Field** |
| `P41_ST_SISTEMA` | Label `Situação`, **Select List**; LOV `STATIC2:Operando;OPERANDO,Instável;INSTAVEL,Em manutenção;MANUTENCAO,Fora do ar;FORA`; Display Null Value No |
| `P41_DS_DETALHE` | Label `Detalhe`, **Text Field**, Maximum Length 140; Inline Help Text `Ex.: Desde 13:40 · equipe atuando. Só aparece quando o sistema não está operando.` |
| `P41_DS_AVISO_TITULO` | Label `Título do aviso`, **Text Field**, Maximum Length 140; Inline Help Text `Preencha para mostrar o aviso no topo da página. Ex.: Instabilidade na VPN desde 13:40.` |
| `P41_DS_AVISO_TEXTO` | Label `Texto do aviso`, **Textarea**, Maximum Length 450; Inline Help Text `Ex.: A equipe já está atuando, não é preciso abrir chamado. Próxima atualização às 15:00.` |

Quando o sistema volta a **Operando**, o aviso some mesmo com os campos preenchidos. Limpe-os para não reaparecerem na próxima instabilidade.

---

## 11. Páginas 42 e 43 · Artigos

### 11.1 Criar as páginas

Mesmo assistente da seção 10:

| Campo | Valor |
|---|---|
| Page Number / Name (lista) | `42` / `Artigos` |
| Form Page Number / Name | `43` / `Artigo` |
| Form Page Mode | **Modal Dialog** |
| Table | `SUPORTE_ARTIGO` |
| Primary Key | `ID_ARTIGO` |

Nas duas páginas: Authorization Scheme **SUPORTE_TI** e Page Access Protection **Arguments Must Have Checksum**.

### 11.2 Lista (p42)

*Source › Where Clause*: `id_empresa = :G_ID_EMPRESA`. Deixe visíveis `DS_TITULO`, `NR_MIN_LEITURA`, `NR_ACESSOS` e `FL_PUBLICADO`, com os Headings `Título`, `Leitura (min)`, `Acessos` e `Publicado`. Esconda as outras com **Hidden Column**, incluindo a `DS_CORPO`.

**Acabamento** (o assistente deixa textos em inglês e códigos na tela):

| Onde | Atributo | Valor |
|---|---|---|
| Coluna `FL_PUBLICADO` | Type | **Plain Text (based on List of Values)**; *List of Values › Type* **Static Values**: `Sim` → `S`, `Não` → `N` (sem isso a coluna mostra `S`/`N`) |
| Coluna `NR_MIN_LEITURA` | Appearance › Format Mask | `990` (com a máscara do assistente, 5 minutos aparece como `5,0`) |
| Região `Artigos` | Attributes › Link › Link Icon | `<span role="img" aria-label="Editar" class="fa fa-edit" title="Editar"></span>` |
| Região `Artigos` | Messages › When No Data Found | `Nenhum artigo cadastrado.` |
| Região `Artigos` | Messages › When More Data Found | `Há mais artigos do que o limite do relatório. Use a busca ou um filtro.` |
| Botão `CREATE` | Label | `Novo artigo` |

```export-check
pagina: 42
# 11.1 Página
page 42 | authorizationScheme: @suporte-ti
page 42 | pageAccessProtection: argumentsMustHaveChecksum
# 11.2 Lista
region artigos | tableName: SUPORTE_ARTIGO
region artigos | whereClause: id_empresa = :G_ID_EMPRESA
page 42 | heading: Título
page 42 | heading: Leitura (min)
page 42 | heading: Acessos
page 42 | heading: Publicado
page 42 | page: 43
# Acabamento
page 42 | Sim;S,Não;N
page 42 | formatMask: 990
region artigos | aria-label="Editar"
region artigos | whenNoDataFound: Nenhum artigo cadastrado.
region artigos | !No data found.
region artigos | !The maximum row count
button create | label: Novo artigo
```

As colunas escondidas não entram no checklist pelo nome (o validador lê blocos de página, região, item, botão e processo); confira no export que só `DS_TITULO`, `NR_MIN_LEITURA`, `NR_ACESSOS` e `FL_PUBLICADO` têm `type: plainText` (ou `plainTextBasedOnLov`).

### 11.3 Formulário (p43)

**Apague** `P43_DH_ATUALIZACAO`, `P43_USR_ATUALIZACAO` e `P43_NR_ACESSOS`. Ajuste os outros:

| Item | Ajuste |
|---|---|
| `P43_ID_ARTIGO` | Hidden |
| `P43_ID_EMPRESA` | **Hidden**, Value Protected Yes; *Default* Type **Item**, `G_ID_EMPRESA` |
| `P43_ID_ASSUNTO` | Label `Assunto`, **Select List**, com a LOV do passo 5.2; Value Required Yes |
| `P43_DS_TITULO` | Label `Título`, Maximum Length 140 |
| `P43_DS_RESUMO` | Label `Resumo`, **Text Field**, Maximum Length 280 |
| `P43_DS_CORPO` | Label `Texto`, **Textarea**, Maximum Length 3500; Inline Help Text `Texto simples. As quebras de linha são mantidas.` |
| `P43_DS_PALAVRAS` | Label `Palavras para a busca`, **Text Field**, Maximum Length 450; Inline Help Text `Palavras que as pessoas usam ao descrever o problema, separadas por espaço.` |
| `P43_NR_MIN_LEITURA` | Label `Leitura (min)`, **Number Field**; Default Static `2` |
| `P43_FL_PUBLICADO` | Label `Publicado`, **Select List**; LOV `STATIC2:Sim;S,Não;N`; Display Null Value No |

---

## 12. Menu lateral

*Shared Components › Navigation Menu › Navigation Menu* (confirmar no 26.1.5). Crie as entradas:

| Seq | Label | Pai | Ícone | Target | Current (Colon Delimited Page List) | Authorization |
|---|---|---|---|---|---|---|
| 36 | `Suporte TI` | (nenhum) | `fa-headphones` | página 34 | `34:35:36:37` | `COLABORADOR` |
| 68 | `Atendimento TI` | Administração | (vazio) | página 38 | `38:39` | `SUPORTE_TI` |
| 69 | `Status dos sistemas` | Administração | (vazio) | página 40 | `40:41` | `SUPORTE_TI` |
| 70 | `Artigos de suporte` | Administração | (vazio) | página 42 | `42:43` | `SUPORTE_TI` |

O `fa-headphones` já tem glifo Lucide no `corlix-tema.css`. A sequência 36 coloca o item logo depois de Ponto eletrônico, como no protótipo.

Saia e entre de novo para o menu e a autorização nova valerem (`docs/ai-context/09` §4.1).

---

## 13. Atalho da Início

Recompile o `modulos/home/pkg_home_ui.pkb` (*SQL Workshop › SQL Scripts › Upload*). O atalho **Suporte TI** passa a abrir a página 34. Faça isto **depois** da seção 4: antes, o atalho levaria a uma página que não existe.

---

## 14. Testar

Use duas contas com colaborador: **A** abre os chamados, **B** tem o papel `Suporte TI`. Recarregue com **Ctrl+Shift+R** (Cmd+Shift+R no Mac) para não ver CSS antigo.

**Tela (conta A)**

1. Abra **Suporte TI** no menu. O item fica destacado, e a tela mostra "Como podemos ajudar, <nome>?", 6 assuntos, 5 sistemas, 5 artigos e os contatos. "Meus chamados" diz que não há chamados.
2. Digite `a vpn nao conecta` na busca: em menos de 1 segundo aparece **Configurar a VPN no notebook** e "Não resolveu? Abrir chamado". Digite `xyzqwe`: "Nenhum artigo encontrado". Pressione Enter: a página não recarrega.
3. Clique em **Rede e VPN**: a p37 abre só com esse assunto. Abra o artigo, confira as quebras de linha e volte pelo link do assunto. Clique em **Suporte TI** na trilha.
4. **Ver base de conhecimento** lista os artigos de todos os assuntos.
5. Abra um artigo e confira que `nr_acessos` subiu 1 na p42 (§11). A ordem de "Artigos mais acessados" segue esse número.
6. **Conversar com a TI** abre o Chat.

**Abertura**

7. Em **Abrir chamado**, envie sem preencher: os campos obrigatórios acusam. Tente anexar um `.exe`: é recusado.
8. Preencha tudo, anexe uma imagem e envie. O modal fecha, aparece a mensagem de sucesso e o chamado surge em **Em aberto · 1** com o selo **Na fila** e o código `INC-<n>`, sem recarregar a página.
9. Clique no título: a p36 mostra a conversa e o anexo. Clique no anexo: o arquivo é baixado, sem trocar de tela.

**Atendimento (conta B)**

10. Em **Administração › Atendimento TI**, o chamado aparece na fila. Clique em **Atender**.
11. Escolha **Assumir o chamado**, prioridade **Alta**, uma previsão futura, sem mensagem, e salve. A fila mostra o atendente e a situação **Em atendimento**. Na conta A, o card mostra o atendente e "Previsão: até dd/mm".
12. Tente uma previsão passada: erro sem "ORA-". Escolha **Resolver** sem mensagem: erro pedindo a solução.
13. Escolha **Pedir informação ao colaborador**, escreva a pergunta e salve.

**Resposta e solução (conta A)**

14. O card fica no topo com **Aguardando você**, a mensagem e "há N min". **Responder** abre a p36. Responda com um anexo: o selo volta para **Em atendimento**.
15. Na conta B, escolha **Resolver** e escreva a solução. Na conta A, o card mostra a solução e "encerrado em dd/mm" (3 dias depois).
16. **Não, reabrir** abre a p36. Clique em **Reabrir chamado** sem mensagem: erro pedindo o que não funcionou. Escreva e envie: o chamado volta para **Em atendimento**.
17. Resolva de novo na conta B e, na conta A, clique em **Sim, encerrar**. O card passa para **Resolvidos · 1**, e a lista continua na aba em que estava. A p36 mostra a conversa sem campos de resposta.

**Encerramento automático**

18. Resolva outro chamado e rode no SQL Commands:
    ```sql
    update suporte_chamado set dt_limite_confirmacao = trunc(sysdate) where st_chamado = 'RESOLVIDO'
    ```
    ```sql
    begin dbms_scheduler.run_job('SUPORTE_ENCERRAR_VENCIDOS'); end;
    ```
    O chamado passa para **Resolvidos**, com "Encerrado automaticamente" na conversa.

**Status e aviso (conta B)**

19. Em **Status dos sistemas**, marque a VPN como **Instável**, com detalhe, título e texto de aviso. Na p34 surgem o aviso âmbar e o selo com o detalhe, e "Atualizado às" muda.
20. Feche o aviso no **x** e recarregue: ele continua fechado. Altere o sistema de novo: o aviso volta.
21. Marque como **Operando**: o aviso e o detalhe somem.

**Artigos (conta B)**

22. Crie um artigo em **Artigos de suporte**: ele aparece na p37 e na busca. Marque **Publicado** como **Não**: ele some das duas.

**Segurança**

23. Na conta A, abra a p38 e a p40 pela URL: acesso negado, e os itens de menu não aparecem.
24. Com uma terceira conta sem o papel, tente abrir o chamado da conta A trocando o id na URL: erro de checksum.
25. Entre com uma conta sem colaborador e com o papel Admin RH: só o aviso, sem botões e sem erro. Sem esse papel, a autorização `COLABORADOR` nega o acesso, e isso também é esperado.
26. Abra um chamado com o título `<script>alert(1)</script>`: o texto aparece escrito, e nada é executado.

**Layout**

27. Estreite a janela: as colunas empilham, os assuntos passam a 2 e depois a 1 por linha, e nada estoura.
28. Tab pela página: busca, assuntos, abas, botões e links mostram o contorno azul de foco. Nas abas, as setas do teclado trocam de aba.
29. Compare com `pen_dev/Suporte TI.png`.

### Como conferir no export

No próximo backup, `corlixhub/pages/p00034-*.apx` deve ter `authorizationScheme: @colaborador`, `fileUrls: #APP_FILES#suporte#MIN#.css`, 7 regiões `type: dynamicContent` com `return pkg_suporte_ui.render_...`, `advanced { htmlDomId: suporte_chamados }` na região `Meus chamados` e os 2 processos de Ajax Callback. O `static-files.apx` ganha `suporte.css` e `suporte.min.css`; o `lists.apx`, as 4 entradas de menu; o `authorizations.apx`, a `SUPORTE_TI`; e o `acl-roles.apx`, o papel `suporte-ti`.

### Se não funcionar

| Sintoma | Causa provável | Correção |
|---|---|---|
| `PLS-00201: identifier 'PKG_SUPORTE_UI' must be declared` | Package não instalado | Seção 1 |
| `PLS-00201` citando `PKG_HISTORICO_CARREIRA` na compilação | Módulo de histórico de carreira não instalado neste schema | Instale-o antes |
| `INVALID` em `PKG_SUPORTE` ou `PKG_SUPORTE_UI` | Erro de compilação | Veja `user_errors` (§1.2) e mande o resultado |
| `ORA-27486: insufficient privileges` no `05_job_suporte.sql` | Schema sem o privilégio `CREATE JOB` | Peça o privilégio ao administrador. Sem o job, os chamados resolvidos só encerram por confirmação |
| Tudo sem estilo | `suporte.css`/`.min.css` não subiram ou File URLs errado | Seção 2 e passo 4.1; Ctrl+Shift+R |
| Abas, busca e "Sim, encerrar" não fazem nada; nada no console | JavaScript não foi colado | Passo 4.1 |
| Modal fecha e a lista não atualiza | Região sem **HTML DOM ID** `suporte_chamados` | Passo 4.3 |
| "Não foi possível falar com o servidor" na busca ou ao encerrar | Ajax Callback com outro nome ou ausente | Passo 4.5: os nomes têm de ser exatos |
| "Não foi possível concluir agora" | Erro inesperado no servidor; a mensagem real vai para o debug | Rode a página em Debug e procure `pkg_suporte_ui:` no log |
| Aviso de conta sem vínculo em conta com colaborador | `login_apex` diferente do usuário, ou colaborador de outra empresa | Confira `colaborador.login_apex` e `G_ID_EMPRESA` |
| "Sua sessão não está vinculada a uma empresa" | `G_ID_EMPRESA` vazio | Saia e entre de novo |
| Erro aparece com "ORA-200xx" na tela | Handler de erro do app sem a faixa do módulo | Confira as três linhas do `log_pkg` (`docs/ai-context/08` §3, Módulos) |
| Erro ao abrir a página 34 citando `P35_`, `P36_` ou `P37_` | Página de destino ainda não criada | Seções 5 a 7 |
| "O arquivo enviado não foi encontrado" | Item File Upload com outro Storage Type, ou arquivo já apagado | Passo 5.2: **APEX_APPLICATION_TEMP_FILES** e **End of Request** |
| Clicar no anexo abre uma página de erro ou um HTML | Processo `Baixar anexo` sem a condição de request ou fora de ordem | Passo 6.5: sequence 10, **Request = Value** `BAIXAR_ANEXO` |
| Conta da TI recebe "Só a equipe de TI pode atender chamados" | Papel atribuído depois do login, ou autorização com outro nome | Saia e entre de novo; o nome tem de ser exatamente `SUPORTE_TI` |
| Conta da TI recebe "Sua conta não está vinculada a um colaborador" ao salvar | Quem atende precisa de colaborador | Use uma conta com `login_apex` em `colaborador` |
| P14 dá `-20102` ao cadastrar | `cargo_papel` aponta para o papel e ele não existe na aplicação | §3.1 |
| Salvar a p41 ou a p43 dá erro de conversão de data | Sobrou um item de data da tabela no formulário | Passos 10.3 e 11.3: apague os itens `DH_` e `USR_` |
| Sistema sem empresa: `ORA-01400` em `ID_EMPRESA` | Item sem o valor padrão e `G_ID_EMPRESA` vazio | Passos 10.3 e 11.3; saia e entre de novo |
| Aviso não aparece | Sistema **Operando** ou sem **Título do aviso** | Passo 10.3 |
| Aviso não volta depois de fechado | Sistema não foi alterado desde que o aviso foi fechado | Esperado. Altere o sistema ou abra uma nova sessão do navegador |
| Chamados resolvidos não encerram sozinhos | Job desligado | `select enabled, state, failure_count from user_scheduler_jobs where job_name = 'SUPORTE_ENCERRAR_VENCIDOS'` |
| Atalho da Início diz "ainda não tem destino" | `pkg_home_ui` antigo no banco | Seção 13 |

---

## Situação

| Data | O quê | Estado |
|---|---|---|
| 09/11/2026 | Banco (§1) | **Instalado:** tabelas `SUPORTE_*`, `VW_SUPORTE_FILA`, `PKG_SUPORTE` e `PKG_SUPORTE_UI` válidos (compilados em 09/11 22:41), job `SUPORTE_ENCERRAR_VENCIDOS` ativo (última execução 12/11 23:30). Conteúdo de exemplo: 6 assuntos, 7 artigos e 5 sistemas da empresa 1. Conferido no SQL Commands em 13/11/2026, só leitura |
| 10/11/2026 | Páginas 34 a 43 (§4 a §11) | Criadas no Builder (backup `acd59be`); detalhe por página nas [fichas](../../docs/ai-context/paginas/README.md) |
| 13/11/2026 | Levantamento do que falta (backup `84f8625` + banco) | Ver "O que falta" abaixo. Nenhum teste do §14 registrado; `SUPORTE_CHAMADO` está vazia, então nenhum chamado foi aberto |
| 13/11/2026 | Export da p42 colado na conversa | Validador: **§11.1 e §11.2 ok (9/9)**: autorização `@suporte-ti`, checksum, **Where Clause `id_empresa = :G_ID_EMPRESA`** (furo de isolamento da lista fechado), cabeçalhos em português e só `DS_TITULO`, `NR_MIN_LEITURA`, `NR_ACESSOS` e `FL_PUBLICADO` visíveis. **Acabamento novo do §11.2 pendente (7 regras):** `Publicado` mostra `S`/`N`, leitura como `5,0`, botão `Create`, ícone "Edit" e mensagens em inglês. Não testado na app: a única conta com o papel não tem colaborador e só a empresa 1 tem artigos, então o filtro não tem como mostrar diferença |

### O que falta (13/11/2026)

**Banco e acesso**
1. **Contatos (§1.3):** `SUPORTE_CONFIG` da empresa 1 está com o texto literal do guia (`<ramal> | <telefone> | <horário>`); a p34 mostra isso na tela. Rodar o `update` com os dados reais.
2. **Papel `Suporte TI` (§3.3):** só a conta `SARAHSILVA2` tem o papel, e ela **não tem colaborador vinculado**: vê as páginas da TI, mas não consegue atender (`-20076`). Dar o papel a quem vai atender (com colaborador). Para o §14, a conta B precisa do papel e de colaborador.
3. **Artigos de exemplo (§1.3):** revisar os 7 artigos na p42 antes de liberar.

**Páginas (Builder)**
4. **p43 (§11.3), urgente por segurança** (a p42 já filtra por empresa desde 13/11/2026; falta o acabamento do §11.2): o formulário deixa escolher a empresa e lista assuntos de todas. O formulário também tem itens `DH_`/`USR_`/`NR_ACESSOS` na tela (o `P43_DH_ATUALIZACAO` obrigatório deve impedir salvar) e `FL_PUBLICADO` em texto livre.
5. **p36 (§6.3 e §6.4):** condição no `P36_ANEXO`, *Purge File At* **End of Request**, região de botões em **Buttons Container** no *Dialog Footer*, `RESPONDER`/`REABRIR` como Hot e o rótulo "Fechar".
6. **p39 (§8.2 e §8.3):** condição de status nos itens visíveis e no `SALVAR`, região de botões em **Buttons Container** no *Dialog Footer*, *Purge File At* do anexo.
7. **p34 e p37 (§4.2 e §7.2):** mover o `Cabeçalho` do slot `body` para **Breadcrumb Bar**.
8. **p40, p41, p42 e p43:** textos do assistente em inglês (botões, cabeçalhos de coluna, "No data found") e `ST_SISTEMA` sem LOV de exibição.

**Navegação**
9. **Menu (§12):** criar as 4 entradas (Suporte TI, Atendimento TI, Status dos sistemas, Artigos de suporte). Hoje as páginas só abrem pela URL.
10. **Atalho da Início (§13):** o `pkg_home_ui` reinstalado em 13/11/2026 já aponta para a p34; conferir na Home depois do menu.

**Testes**
11. **§14 (1 a 29)**, com duas contas com colaborador: A abre chamados, B tem o papel `Suporte TI`. Os testes gravam chamados, mensagens e anexos: registrar aqui e apagar os dados de teste depois.

