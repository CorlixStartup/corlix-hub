# Chat (página 4) · passo a passo no APEX

Este guia completa o chat interno 1:1 da página 4 no App Builder do **APEX 26.1.5**. A lista de contatos, a abertura da conversa e o envio já funcionam (estado em `docs/ai-context/02-paginas.md`, "Página 4"). Este guia acrescenta:

- **§1 Polling de mensagens (1 s):** as mensagens recebidas aparecem sozinhas, sem reabrir o contato.
- **§2 Presença:** quem está usando a app aparece como online, em qualquer página, e os pontos da lista de contatos se atualizam sozinhos.
- **§3 Barra de rolagem extra:** a página não rola, só a conversa e a lista.
- **§4 Anexos:** Excel, Word, PowerPoint e imagens até 10 MB, pelo clipe, arrastando e soltando sobre a conversa ou com Ctrl+V.

Como nos outros módulos, a mudança é feita no Builder e o backup traz o resultado para `corlixhub/` na `DEV`. Editar só o `.apx` do repositório não muda o app.

Passos marcados com **(confirmar no 26.1.5)** ainda não foram conferidos na tela desta versão. Se o caminho não existir, tire um print e registre o caminho certo neste guia.

---

## 1. Polling de mensagens (1 s)

### Como funciona

1. A cada **1 segundo**, o navegador chama o processo Ajax `CH_VERIFICAR_MSGS` com o canal aberto (`P4_CANAL_ID`). O processo devolve uma **assinatura** da conversa: `"<id da última mensagem>:<quantidade>"`. São dois números, sem HTML, então a chamada é leve.
2. O JS calcula a mesma assinatura a partir do que está **na tela** (cada mensagem passa a levar `data-id`). **Só quando as duas diferem** a região Mensagens é recarregada. Se ninguém escreveu nada, nada é renderizado de novo, e não há piscada nem spinner.
3. A rolagem fica onde o usuário espera:
   - Se ele está no fim da conversa (a menos de 40 px), a lista desce até a mensagem nova.
   - Se ele subiu para ler mensagens antigas, a posição é mantida.
   - Ao abrir um contato ou enviar uma mensagem, a lista sempre vai para o fim.
4. O polling **para** quando não há conversa aberta ou a aba está em segundo plano (`document.hidden`). Ao voltar para a aba, ele verifica na hora. Depois de um erro de rede, a próxima tentativa espera 5 s.
5. Só começa uma verificação depois que a anterior terminou, e nenhuma roda enquanto a região está sendo recarregada. Assim as requisições não se acumulam numa rede lenta.

Por que não um *Refresh* da região a cada 1 s: re-renderizar o relatório toda hora gera HTML, spinner e salto de rolagem a cada segundo, mesmo sem mensagem nova. A assinatura evita isso.

**Correção incluída:** hoje a região Mensagens está com o *Number of Rows* padrão, **15** (no export: `p_query_num_rows=>15`). Como a consulta ordena da mais antiga para a mais nova, uma conversa com mais de 15 mensagens mostra só as 15 primeiras, e as novas **nunca** aparecem. Com o polling isso também faria a região recarregar todo segundo. O passo 1.1 passa a buscar as **200 mais recentes** e sobe o limite para 200.

**Custo:** cada aba com o chat aberto e visível faz 1 requisição por segundo ao ORDS. A consulta usa o índice `IDX_CANALMSG_CANAL_DATA (ID_CANAL, DATA_ENVIO)`. Efeito colateral: enquanto o chat está aberto e visível, a sessão do APEX não expira por inatividade.

### 1.1 Região "Mensagens": SQL e limite de linhas

*Page Designer* da página 4 › aba **Rendering** › *Body* › Chat Shell › Conversa › **Mensagens**.

1. **Source › SQL Query**: substitua a consulta inteira por esta:

   ```sql
   with ultimas as (
     -- as 200 mensagens mais recentes (o Number of Rows da região também é 200)
     select m.id_canal_mensagem,
            m.id_colaborador,
            m.corpo,
            m.data_envio
     from   canal_mensagem m
     where  m.id_canal = :P4_CANAL_ID
     and    nvl(m.excluida, false) = false
     -- só exibe canais dos quais o usuário logado participa
     and    exists (
              select 1
              from   canal_participante cp
              join   colaborador eu on eu.id_colaborador = cp.id_colaborador
              where  cp.id_canal = m.id_canal
              and    upper(eu.login_apex) = upper(:APP_USER)
            )
     order  by m.data_envio desc, m.id_canal_mensagem desc
     fetch  first 200 rows only
   )
   select u.corpo,
          to_char(u.data_envio, 'hh24:mi') as hora,
          case when upper(col.login_apex) = upper(:APP_USER) then 'out' else 'in' end as lado,
          case when row_number() over (
                      partition by trunc(u.data_envio)
                      order by u.data_envio, u.id_canal_mensagem
                    ) = 1
               then '<div class="ch-sep"><span>' ||
                    case when trunc(u.data_envio) = trunc(sysdate) then 'HOJE'
                         when trunc(u.data_envio) = trunc(sysdate)-1 then 'ONTEM'
                         else to_char(u.data_envio, 'dd/mm/yyyy') end ||
                    '</span></div>'
          end as sep_dia,
          -- usado pelo polling (data-id no template Chat Mensagens)
          u.id_canal_mensagem as id_msg
   from   ultimas u
   join   colaborador col on col.id_colaborador = u.id_colaborador
   order  by u.data_envio, u.id_canal_mensagem
   ```

   `ID_MSG` fica **por último** de propósito: as colunas que já existem mantêm a posição (CORPO 1 … SEP_DIA 4).

2. Salve. Em *Mensagens › Columns* aparece a coluna nova **ID_MSG**. Deixe-a como está. Quem decide o HTML é o template, não o tipo da coluna. Confira se **SEP_DIA** continua com *Security › Escape special characters* = **Off**.
3. **Number of Rows = 200**. É a mesma propriedade em que a região **Lista** (contatos) está com 1000: selecione a região Mensagens e procure *Layout › Number of Rows* no painel de propriedades **(confirmar no 26.1.5)**. Se não achar, use o campo de busca do painel de propriedades e digite "Number of Rows".
4. **Advanced › Static ID = `msgs`** (minúsculo, sem `#`). O JS do 1.4 procura a região primeiro por esse id; se não achar, usa o id interno (`R<número>`) a partir do relatório `report_<número>_catch`. Em 05/11/2026, mesmo com `msgs` preenchido no Builder, a região saía no HTML como `<div id="R9290772597503215" class="lto9290772597503215_0 js-apex-region">`. Faltavam o Static ID e também o *Custom Attributes* `class="ch-msgs-wrap"`. Ou seja, o wrapper era gerado pelo próprio APEX, e o template da região não aplicava nem o id nem os atributos. Com isso `apex.region("msgs")` voltava `null` e a primeira versão do JS não conseguia recarregar nem rolar a lista. O JS atual contorna o problema. Causa em aberto: conferir *Appearance › Template* da região (ver "Se não funcionar"). Para conferir, rode no Console do navegador `document.getElementById("msgs")`. Se voltar `null`, o JS usa o plano B.

### 1.2 Template "Chat Mensagens": `data-id` em cada mensagem

*Shared Components* › *User Interface* › **Templates** › filtre por tipo **Report** › **Chat Mensagens** **(confirmar no 26.1.5)**.

Em **Row Templates › Row Template 1**, troque a linha

```html
<div class="ch-msg ch-msg--#LADO#">
```

por

```html
<div class="ch-msg ch-msg--#LADO#" data-id="#ID_MSG#">
```

O resto do template fica igual. Aplique as alterações.

### 1.3 Processo Ajax "CH_VERIFICAR_MSGS"

*Page Designer* da página 4 › aba **Processing** › clique com o botão direito em **Ajax Callback** › **Create Process**.

| Propriedade | Valor |
|---|---|
| Identification › Name | `CH_VERIFICAR_MSGS` (exatamente assim: é o nome que o JS chama) |
| Identification › Type | Execute Code |
| Source › Location | Local Database |
| Source › Language | PL/SQL |
| Execution › Point | Ajax Callback (já vem preenchido) |

**Source › PL/SQL Code:**

```plsql
declare
  l_canal  number := to_number(apex_application.g_x01 default null on conversion error);
  l_ultima canal_mensagem.id_canal_mensagem%type;
  l_qtd    number;
begin
  -- mesma regra da região Mensagens: só canais de que o usuário logado participa.
  -- "última" = a mais recente pela mesma ordem da região (data_envio, id).
  select max(m.id_canal_mensagem) keep (dense_rank last order by m.data_envio, m.id_canal_mensagem),
         count(*)
  into   l_ultima, l_qtd
  from   canal_mensagem m
  where  m.id_canal = l_canal
  and    nvl(m.excluida, false) = false
  and    exists (
           select 1
           from   canal_participante cp
           join   colaborador eu on eu.id_colaborador = cp.id_colaborador
           where  cp.id_canal = m.id_canal
           and    upper(eu.login_apex) = upper(:APP_USER)
         );

  -- mesmo formato que o JS monta a partir da tela: "<última>:<quantidade>".
  -- A quantidade é limitada a 200, o Number of Rows da região.
  apex_json.open_object;
  apex_json.write('assinatura', nvl(l_ultima, 0) || ':' || least(l_qtd, 200));
  apex_json.close_object;
end;
```

Conversa vazia ou canal de que o usuário não participa → `"0:0"`, o que bate com a tela "Nenhuma mensagem nesta conversa ainda.".

### 1.4 JavaScript da página

*Page Designer* da página 4 › clique no nó **Page 4: Chat** (raiz da árvore) › seção **JavaScript**.

**Function and Global Variable Declaration** (o campo hoje está vazio; cole tudo):

```javascript
// Polling do chat: a cada 1 s pergunta ao servidor (CH_VERIFICAR_MSGS) qual é a
// assinatura da conversa aberta e só recarrega a região Mensagens quando ela é
// diferente da que está na tela. Ver modulos/chat/Etapas-chat.md §1.
const chChat = (function () {
    const REGIAO_ID         = "msgs"; // Static ID da região Mensagens (passo 1.1, item 4)
    const INTERVALO_MS      = 1000;  // 1 s
    const INTERVALO_ERRO_MS = 5000;  // depois de um erro de rede, espera mais
    const FOLGA_FIM_PX      = 40;    // "está no fim" = a menos de 40 px do fim
    const LIMITE_REFRESH_MS = 10000; // destrava se um refresh nunca terminar

    let timer          = null;
    let consultando    = false; // há uma chamada ao CH_VERIFICAR_MSGS em andamento
    let atualizandoDes = 0;     // quando começou o refresh da região (0 = nenhum)
    let forcarFim      = false; // próximo refresh rola até o fim (envio de mensagem)
    let irAoFim        = true;
    let topoSalvo      = 0;
    let canalNaTela    = null;  // canal cujas mensagens estão renderizadas

    function canalAtual() {
        return apex.item("P4_CANAL_ID").getValue();
    }

    // Elemento da região Mensagens. Usa o Static ID "msgs" se ele vier no HTML;
    // senão, sobe a partir do relatório (report_<id>_catch) até o id interno R<id>.
    // Assim o polling funciona mesmo que o Static ID não chegue à página.
    function regiaoEl() {
        const porId = document.getElementById(REGIAO_ID);
        if (porId) {
            return porId;
        }
        const relatorio = document.querySelector(".ch-chat [id^='report_'][id$='_catch']");
        return relatorio ? relatorio.closest("[id^='R']") : null;
    }

    function lista() {
        const el = regiaoEl();
        return el ? el.querySelector(".ch-msgs") : null;
    }

    function atualizando() {
        return atualizandoDes > 0 && Date.now() - atualizandoDes < LIMITE_REFRESH_MS;
    }

    // mesma regra do CH_VERIFICAR_MSGS: "<id da última mensagem>:<quantidade>"
    function assinaturaNaTela() {
        const el     = regiaoEl();
        const msgs   = el ? el.querySelectorAll(".ch-msg[data-id]") : [];
        const ultima = msgs.length ? msgs[msgs.length - 1].dataset.id : "0";
        return ultima + ":" + msgs.length;
    }

    function recarregar() {
        const el = regiaoEl();
        if (!el) {
            console.warn("chChat: região Mensagens não encontrada na página");
            return;
        }
        apex.region(el.id).refresh();
    }

    function agendar(ms) {
        clearTimeout(timer);
        timer = setTimeout(verificar, ms === undefined ? INTERVALO_MS : ms);
    }

    function verificar() {
        const canal = canalAtual();

        // sem conversa aberta, aba escondida ou algo já em andamento: só reagenda
        if (!canal || document.hidden || consultando || atualizando()) {
            agendar();
            return;
        }

        consultando = true;
        let espera = INTERVALO_MS;

        apex.server.process("CH_VERIFICAR_MSGS", { x01: canal }, { dataType: "json" })
            .done(function (resp) {
                // trocou de conversa enquanto a resposta vinha, ou já há refresh: ignora
                if (canal !== canalAtual() || atualizando()) {
                    return;
                }
                if (resp && resp.assinatura !== assinaturaNaTela()) {
                    // try/catch: um erro aqui não pode impedir o .always de liberar o ciclo
                    try {
                        recarregar();
                    } catch (e) {
                        console.error("chChat: falha ao atualizar a conversa", e);
                    }
                }
            })
            .fail(function () {
                espera = INTERVALO_ERRO_MS;
            })
            .always(function () {
                consultando = false;
                agendar(espera);
            });
    }

    // vale para qualquer refresh da região: polling, abrir contato e enviar
    function antesDoRefresh() {
        atualizandoDes = Date.now();
        const l = lista();
        const outraConversa = canalNaTela !== canalAtual();
        irAoFim = forcarFim || outraConversa || !l ||
                  l.scrollHeight - l.scrollTop - l.clientHeight < FOLGA_FIM_PX;
        topoSalvo = l ? l.scrollTop : 0;
    }

    function depoisDoRefresh() {
        const l = lista();
        if (l) {
            l.scrollTop = irAoFim ? l.scrollHeight : topoSalvo;
        }
        canalNaTela    = canalAtual();
        forcarFim      = false;
        atualizandoDes = 0;
        agendar(); // a próxima verificação conta a partir de agora
    }

    // só reage aos eventos da região Mensagens (a lista de contatos também é relatório).
    // "contains" e não "===": o relatório dispara o evento num elemento DENTRO da
    // região (report_<id>_catch), e ele sobe até o document.
    function daRegiao(evento) {
        const el = regiaoEl();
        return !!el && el.contains(evento.target);
    }

    function iniciar() {
        // ligado no document: funciona com qualquer id que a região tenha
        apex.jQuery(document)
            .on("apexbeforerefresh", function (e) { if (daRegiao(e)) { antesDoRefresh(); } })
            .on("apexafterrefresh",  function (e) { if (daRegiao(e)) { depoisDoRefresh(); } });

        // voltou para a aba: verifica na hora em vez de esperar o próximo ciclo
        document.addEventListener("visibilitychange", function () {
            if (!document.hidden) {
                agendar(0);
            }
        });

        agendar();
    }

    return {
        iniciar: iniciar,
        // chamado pela DA "Enviar Mensagem": quem envia quer ver a própria mensagem
        irParaFim: function () { forcarFim = true; }
    };
})();
```

**Execute when Page Loads:**

```javascript
chChat.iniciar();
```

### 1.5 Remover a DA "Rolar para a última mensagem"

Agora a rolagem fica com o JS do 1.4, que decide entre ir até o fim e manter a posição. A DA antiga sempre rola até o fim e anularia isso.

*Page Designer* da página 4 › aba **Dynamic Actions** › *Events* › **After Refresh** › **Rolar para a última mensagem** › botão direito › **Delete**.

### 1.6 DA "Enviar Mensagem": sempre rolar até o fim ao enviar

*Dynamic Actions* › *Click* › **Enviar Mensagem** › *True* › **Preparar envio** (Execute JavaScript Code, sequência 10) › *Settings › Code*. Logo depois de

```javascript
apex.item("P4_MENSAGEM").setValue(texto);
```

acrescente

```javascript
chChat.irParaFim();
```

Não mexa no resto. A ação "Atualizar conversa" continua **Refresh** da região Mensagens.

### 1.7 Como deve ficar no export

Depois do próximo backup, `corlixhub/pages/p00004-chat.apx` deve ter:

- `javaScript { functionAndGlobalVariableDeclaration: ... executeWhenPageLoads: chChat.iniciar(); }` no topo da página.
- Na região `msgs`: o SQL com `with ultimas as (`, a coluna `ID_MSG` e `reportLayout { numberOfRows: 200 }`.
- Um `process` com `name: CH_VERIFICAR_MSGS` e `execution { point: ajaxCallback }`.
- **Nenhuma** `dynamicAction` com `event: apexafterrefresh`.
- `chChat.irParaFim();` na ação `preparar-envio`.

E `classic-report-templates/chat-mensagens.apx` deve ter `data-id="#ID_MSG#"`.

### 1.8 Teste

Use dois usuários com colaborador vinculado, da mesma empresa: A num navegador normal e B numa janela anônima, ou noutro navegador.

1. A abre a conversa com B, e B abre a conversa com A.
2. B envia "teste 1". Em até ~1 s a mensagem aparece para A, sem recarregar nada, e a lista de A desce até ela.
3. A sobe a rolagem até o começo, e B envia outra mensagem. A lista de A **não** pula. Ao descer, A vê a mensagem nova.
4. A envia uma mensagem estando rolado para cima. A lista vai até o fim e mostra a mensagem dele.
5. Abra o DevTools (F12) › **Network** na conversa parada. Aparece **1 requisição por segundo** (`wwv_flow.ajax` / `CH_VERIFICAR_MSGS`) com resposta `{"assinatura":"123:8"}`, e **nenhuma** de refresh da região.
6. Troque para outra aba por alguns segundos. As requisições param e voltam na hora quando você retorna.
7. Numa conversa com mais de 15 mensagens, as mais recentes aparecem. Era o bug do limite de 15.

### Se não funcionar

| Sintoma | Causa provável | Correção |
|---|---|---|
| Nada atualiza e o Network fica vazio com a conversa parada; `document.getElementById("msgs")` dá `null`; a região aparece no HTML como `R<número>` | Região Mensagens **sem Static ID**. Na versão antiga do JS, o `apex.region("msgs").refresh()` sobre `null` também travava o ciclo de polling (caso de 05/11/2026) | *Mensagens › Advanced › Static ID* = `msgs`, use o JS atual do 1.4 e recarregue com Ctrl+Shift+R |
| Nada atualiza e o console mostra `chChat is not defined` | O JS do 1.4 não foi salvo no nó da página ou foi colado no *Execute when Page Loads* | Confira os dois campos de 1.4 |
| A região recarrega **todo segundo**, mesmo sem mensagem nova | A tela e o servidor não montam a mesma assinatura: falta `data-id="#ID_MSG#"` no template (1.2), a coluna ID_MSG não existe (1.1) ou *Number of Rows* ainda é 15 | Refaça 1.1 e 1.2. Inspecione uma bolha e confira o `data-id` com um número |
| A resposta do Network é `{"error":...}` ou HTTP 4xx | Nome do processo diferente de `CH_VERIFICAR_MSGS` ou erro no PL/SQL | Confira o nome exato e o código do 1.3 |
| Ao chegar mensagem, a lista **sobe para o topo** em vez de descer | O refresh troca o HTML da lista, que volta para `scrollTop = 0`, e os handlers de rolagem não rodam: o evento vem de um elemento **dentro** da região e a versão anterior do `daRegiao` comparava com `===` (caso de 05/11/2026) | Use o JS atual do 1.4 (`el.contains(evento.target)`) |
| A lista sempre volta para o fim ao chegar mensagem | A DA "Rolar para a última mensagem" ainda existe | Faça o 1.5 |
| A lista não desce ao abrir um contato | `#msgs` não encontrado: o Static ID da região Mensagens foi alterado | *Mensagens › Advanced › Static ID* = `msgs` |
| Mensagens novas só aparecem depois de ~5 s | As chamadas estão falhando, e a cada falha a próxima espera 5 s | Veja o erro no Network. Sessão expirada pede novo login |

---

## 2. Presença

### Como funciona

Hoje a página 4 **lê** a tabela `presenca_colaborador`, mas nada grava nela, a não ser o envio de mensagem em canal de equipe (`pkg_equipe_canal.enviar_mensagem_canal`). Por isso quase todo mundo aparece offline. A procedure que grava o ping já existe, `pkg_equipe_canal.atualizar_presenca`, só que nenhuma página chama essa procedure.

1. **Ping em todas as páginas.** Uma DA de *Page Load* na **Global Page (página 0)** roda o JS `presenca-global.js`. Ele chama o Application Process `CX_PRESENCA_PING`, que grava `ONLINE` com o horário atual para a conta logada. O ping é global, e não só da página 4, porque a Home também mostra a presença do gestor (`pkg_home_ui.render_meu_gestor`, "Disponível agora").
2. **Quando o ping sai:**
   - no máximo **1 por minuto** por aba, mesmo navegando entre páginas (o horário do último ping fica no `sessionStorage` da aba);
   - só com a aba **visível** e com **atividade** (mouse, teclado, toque, rolagem) nos últimos **3 minutos**;
   - dentro de um modal (iframe), quem pinga é a página de baixo.
3. **Como a situação é calculada** (a mesma regra que a região Contatos e o `pkg_home_ui` já usam, sem mudança):

   | Situação | Regra |
   |---|---|
   | online | `status_presenca = 'ONLINE'` e último ping há **menos de 5 min** |
   | ausente | último ping há menos de **30 min** |
   | offline | sem ping há 30 min ou mais, ou sem linha na tabela |

   Resultado: quem para de mexer na app (ou troca de aba) fica online por mais 5 a 8 min, depois ausente até completar 30 min sem ping, e então offline.
4. **Lista de contatos ao vivo.** Na página 4, a cada **30 s** com a aba visível, o JS `chat-presenca.js` chama o Ajax Callback `CH_PRESENCAS` e só troca a classe dos pontos (`ch-dot--online`, `--ausente`, `--offline`) na lista e no cabeçalho da conversa aberta. A região Contatos **não** é recarregada, então os grupos de departamento abertos continuam abertos.
5. **O colaborador vem sempre da sessão** (`APP_USER` + `G_ID_EMPRESA`), nunca do navegador. Conta sem colaborador ativo ou sem empresa na sessão não grava nada e recebe a lista vazia.

**Por que não há job de offline:** a ideia original (comentário da tabela e spec do `pkg_equipe_canal`) era um job `DBMS_SCHEDULER` chamando `atualizar_offline` a cada 1 ou 2 min. Ele não é necessário, porque todas as leituras (região Contatos, `pkg_home_ui` e o `CH_PRESENCAS`) já decidem pela **idade do último ping**: um `ONLINE` antigo aparece como ausente ou offline. Um job só acrescentaria uma peça para manter. Se no futuro alguém ler só `status_presenca`, sem olhar o horário, aí sim o job passa a fazer falta.

**Custo:** 1 requisição por minuto por aba ativa (um `MERGE` numa linha pela chave primária) e, na página 4, mais 1 a cada 30 s (uma consulta dos colegas da empresa). Como o ping para quando a pessoa fica parada, ele **não** mantém a sessão viva para sempre: o timeout por inatividade continua valendo (o polling de mensagens da §1, na página 4, é outra história e já está registrado lá).

**Referências reutilizadas:** a regra de situação vem da região Contatos da página 4 e de `pkg_home_ui.render_meu_gestor`; o formato `pkg_<modulo>_ui` com `ajax_*` e `instalar.sql` vem da Home (`modulos/home`); o uso de `apex.server.process` sem spinner e a pausa com `document.hidden` vêm do polling da §1.

### 2.1 Banco: instalar o `pkg_chat_ui`

Arquivos em `modulos/chat/`: `pkg_chat_ui.pks`, `pkg_chat_ui.pkb` e `instalar.sql`. Não cria tabela, só o package.

**Pelo SQLcl:**

```
cd modulos/chat
sql <usuario>@<servico> @instalar.sql
```

**Pelo SQL Workshop › SQL Scripts:** suba e rode primeiro o `pkg_chat_ui.pks` e depois o `pkg_chat_ui.pkb` (os dois terminam em `/`).

A conferência no fim do `instalar.sql` deve listar `PKG_CHAT_UI` como `PACKAGE` e `PACKAGE BODY`, os dois `VALID`.

Especificação (`pkg_chat_ui.pks`):

```sql
create or replace package pkg_chat_ui authid definer as

  function situacao_presenca (
    p_status      in varchar2,
    p_ultimo_ping in timestamp
  ) return varchar2;

  -- {"ok":true} quando gravou; {"ok":false} para conta sem colaborador ativo
  procedure ajax_ping;

  -- {"presencas":{"12":"online","15":"ausente",...}}
  procedure ajax_presencas;

end pkg_chat_ui;
/
```

Corpo (`pkg_chat_ui.pkb`):

```sql
create or replace package body pkg_chat_ui as

  -- Mesmos limites da região "Contatos" da página 4 e do pkg_home_ui
  c_online_min  constant pls_integer := 5;   -- ping ONLINE há menos de 5 min: online
  c_ausente_min constant pls_integer := 30;  -- qualquer ping há menos de 30 min: ausente

  -- Colaborador ativo da conta logada, na empresa da sessão.
  -- Sem empresa na sessão, nenhum (empresa nula nunca libera nada).
  function colaborador_logado return number is
    l_empresa constant number := to_number(v('G_ID_EMPRESA') default null on conversion error);
    l_id      colaborador.id_colaborador%type;
  begin
    if l_empresa is null then
      return null;
    end if;

    select c.id_colaborador
      into l_id
      from colaborador c
     where upper(trim(c.login_apex)) = upper(trim(v('APP_USER')))
       and c.id_empresa = l_empresa
       and c.status     = true
     fetch first 1 row only;

    return l_id;
  exception
    when no_data_found then
      return null;
  end colaborador_logado;

  function situacao_presenca (
    p_status      in varchar2,
    p_ultimo_ping in timestamp
  ) return varchar2 is
  begin
    if p_ultimo_ping > systimestamp - numtodsinterval(c_online_min, 'MINUTE')
       and upper(p_status) = 'ONLINE' then
      return 'online';
    elsif p_ultimo_ping > systimestamp - numtodsinterval(c_ausente_min, 'MINUTE') then
      return 'ausente';
    end if;
    return 'offline';
  end situacao_presenca;

  procedure ajax_ping is
    l_id constant number := colaborador_logado;
  begin
    if l_id is not null then
      pkg_equipe_canal.atualizar_presenca(l_id, 'ONLINE');  -- faz o commit
    end if;

    apex_json.open_object;
    apex_json.write('ok', l_id is not null);
    apex_json.close_object;
  exception
    when others then
      -- o ping não pode mostrar erro para quem está usando a app: só registra no debug
      apex_debug.error('pkg_chat_ui.ajax_ping: %s', sqlerrm);
      apex_json.open_object;
      apex_json.write('ok', false);
      apex_json.close_object;
  end ajax_ping;

  procedure ajax_presencas is
    l_id constant number := colaborador_logado;
  begin
    apex_json.open_object;
    apex_json.open_object('presencas');

    if l_id is not null then
      -- mesmos colegas da região "Contatos": ativos, da minha empresa, menos eu
      for r in (
        select c.id_colaborador,
               p.status_presenca,
               p.data_ultimo_ping
          from colaborador c
          join colaborador eu
            on eu.id_colaborador = l_id
           and eu.id_empresa     = c.id_empresa
          left join presenca_colaborador p
            on p.id_colaborador = c.id_colaborador
         where c.status         = true
           and c.id_colaborador <> l_id
      ) loop
        apex_json.write(to_char(r.id_colaborador),
                        situacao_presenca(r.status_presenca, r.data_ultimo_ping));
      end loop;
    end if;

    apex_json.close_object;
    apex_json.close_object;
  end ajax_presencas;

end pkg_chat_ui;
/
```

### 2.2 Application Process `CX_PRESENCA_PING`

Tem que ser de **aplicação**, e não de página, porque o ping sai de qualquer página.

**Shared Components › Application Logic › Application Processes › Create**:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `CX_PRESENCA_PING` |
| Identification | Sequence | `10` |
| Identification | Point | **Ajax Callback: Run this application process when requested by a page process** (confirmar no 26.1.5) |
| Source | Language | `PL/SQL` |
| Source | PL/SQL Code | `pkg_chat_ui.ajax_ping;` |
| Security | Authorization Scheme | **Must Not Be Public User** (é o valor que já vem; não troque) |
| Server-side Condition | Type | nenhuma |

O nome tem que ser exatamente `CX_PRESENCA_PING`: é o nome que o JS chama.

### 2.3 Global Page (página 0): DA "Presença"

1. Abra a **página 0 (Global Page)** no Page Designer.
2. Aba **Dynamic Actions** › botão direito em **Page Load** › **Create Dynamic Action**:

   | Seção | Atributo | Valor |
   |---|---|---|
   | Identification | Name | `Presença` |
   | When | Event | `Page Load` |
   | Server-side Condition | Type | **User is Authenticated (not public)** |

   A condição evita que o JS vá para a página de login (9999), onde ninguém está logado.
3. Clique na ação *True* que foi criada (vem como *Show*) e troque:

   | Seção | Atributo | Valor |
   |---|---|---|
   | Identification | Action | `Execute JavaScript Code` |
   | Settings | Code | o conteúdo de `modulos/chat/presenca-global.js` (abaixo) |

4. Salve.

Conteúdo de `presenca-global.js`:

```javascript
// Presença (modulos/chat/Etapas-chat.md §2): avisa o servidor que a pessoa está usando a app.
// Roda em todas as páginas pela DA "Presença" da Global Page (página 0), só para quem está logado.
// Regras:
//   - no máximo 1 ping por minuto por aba, mesmo navegando entre páginas;
//   - só com a aba visível e com atividade (mouse, teclado, toque) nos últimos 3 min.
//     Parado ou em outra aba, a pessoa deixa de pingar e vira "ausente" depois de 5 min;
//   - dentro de um modal (iframe), quem pinga é a página de baixo.
if (window.cxPresenca || window.self !== window.top) {
    return;
}

const PROCESSO     = "CX_PRESENCA_PING";
const INTERVALO_MS = 60000;   // 1 ping por minuto, no máximo
const ATIVIDADE_MS = 180000;  // sem atividade há 3 min: para de pingar
const CICLO_MS     = 15000;   // de quanto em quanto tempo confere se é hora de pingar
const CHAVE        = "cxPresencaUltimoPing"; // sessionStorage da aba

let ultimaAtividade = Date.now();
let enviando        = false;

function lerUltimoPing() {
    try {
        return Number(sessionStorage.getItem(CHAVE)) || 0;
    } catch (e) {
        return 0;
    }
}

function gravarUltimoPing(momento) {
    try {
        sessionStorage.setItem(CHAVE, String(momento));
    } catch (e) {
        // sem storage: só pinga a cada carregamento de página
    }
}

function ping() {
    const agora = Date.now();
    if (enviando ||
        document.hidden ||
        agora - ultimaAtividade > ATIVIDADE_MS ||
        agora - lerUltimoPing() < INTERVALO_MS) {
        return;
    }

    enviando = true;
    apex.server.process(PROCESSO, {}, { dataType: "json", loadingIndicator: null })
        .done(function () {
            // conta sem colaborador responde {"ok":false}: grava assim mesmo, para não insistir
            gravarUltimoPing(Date.now());
        })
        .always(function () {
            enviando = false;
        });
}

function marcarAtividade() {
    const estavaParado = Date.now() - ultimaAtividade > ATIVIDADE_MS;
    ultimaAtividade = Date.now();
    if (estavaParado) {
        ping(); // voltou depois de um tempo parado: fica online na hora
    }
}

["pointerdown", "pointermove", "keydown", "wheel", "touchstart"].forEach(function (evento) {
    document.addEventListener(evento, marcarAtividade, { passive: true, capture: true });
});

document.addEventListener("visibilitychange", function () {
    if (!document.hidden) {
        marcarAtividade();
        ping();
    }
});

setInterval(ping, CICLO_MS);
ping();

window.cxPresenca = { ping: ping };
```

### 2.4 Página 4: Ajax Callback `CH_PRESENCAS`

Página 4 › aba **Processing** › botão direito em **Ajax Callback** › **Create Process**:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `CH_PRESENCAS` |
| Identification | Type | `Execute Code` |
| Source | Language | `PL/SQL` |
| Source | PL/SQL Code | `pkg_chat_ui.ajax_presencas;` |
| Execution | Point | `Ajax Callback` |

Fica ao lado do `CH_VERIFICAR_MSGS` da §1. Não mexa nele.

### 2.5 Página 4: JavaScript da lista de contatos

Clique no nó da **página 4** › **JavaScript › Execute when Page Loads**. Hoje o campo tem só `chChat.iniciar();`. **Mantenha essa linha** e cole, logo abaixo dela, o conteúdo de `modulos/chat/chat-presenca.js`. O campo fica assim:

```javascript
chChat.iniciar();

// Presença na lista de contatos e no cabeçalho da conversa (modulos/chat/Etapas-chat.md §2).
// A cada 30 s, com a aba visível, pergunta ao CH_PRESENCAS a situação de cada colega e só troca a
// classe do ponto (ch-dot--online / --ausente / --offline). Não recarrega a região "Contatos",
// então os grupos de departamento abertos continuam abertos.
(function () {
    const INTERVALO_MS = 30000;
    let enviando = false;

    function aplicar(presencas) {
        document.querySelectorAll(".ch-contact[data-id]").forEach(function (contato) {
            const ponto = contato.querySelector(".ch-dot");
            if (!ponto) {
                return;
            }
            ponto.className = "ch-dot ch-dot--" + (presencas[contato.dataset.id] || "offline");

            // o cabeçalho da conversa copia o ponto do contato aberto
            if (contato.classList.contains("is-active")) {
                const cabecalho = document.querySelector(".ch-head .ch-dot");
                if (cabecalho) {
                    cabecalho.className = ponto.className;
                }
            }
        });
    }

    function atualizar() {
        if (enviando || document.hidden) {
            return;
        }
        enviando = true;
        apex.server.process("CH_PRESENCAS", {}, { dataType: "json", loadingIndicator: null })
            .done(function (resp) {
                if (resp && resp.presencas) {
                    aplicar(resp.presencas);
                }
            })
            .always(function () {
                enviando = false;
            });
    }

    setInterval(atualizar, INTERVALO_MS);
    document.addEventListener("visibilitychange", function () {
        if (!document.hidden) {
            atualizar();
        }
    });
})();
```

Não cole no *Function and Global Variable Declaration*: ali fica só o `chChat` da §1.

Nada muda na região Contatos, no template `Chat Contatos` nem no CSS: as classes `ch-dot--online`, `--ausente` e `--offline` já existem.

### 2.6 Como deve ficar no export

Depois do próximo backup:

- `corlixhub/shared-components/app-processes.apx`: um `appProcess` com `name: CX_PRESENCA_PING`, `point: ajaxCallback` e `pkg_chat_ui.ajax_ping`.
- `corlixhub/pages/p00000-global-page.apx`: uma `dynamicAction` com `event: ready`, condição `userIsAuthenticated` e ação `executeJsCode` com `CX_PRESENCA_PING`.
- `corlixhub/pages/p00004-chat.apx`: `executeWhenPageLoads` com `chChat.iniciar();` e `"CH_PRESENCAS"`, e um `process` com `name: CH_PRESENCAS`, `point: ajaxCallback` e `pkg_chat_ui.ajax_presencas`.

Checklist lido pelo validador de exports ([`docs/agentes/fluxos/validar-export.md`](../../docs/agentes/fluxos/validar-export.md)):

```export-check
pagina: 4
# §3 Altura do chat
page 4 | --ch-topbar-h: var(--ut-header-height, 3.5rem);
# 2.4 Ajax Callback
process ch-presencas | name: CH_PRESENCAS
process ch-presencas | pkg_chat_ui.ajax_presencas
process ch-presencas | point: ajaxCallback
# 2.5 JavaScript
page 4 | chChat.iniciar();
page 4 | "CH_PRESENCAS"
page 4 | presencas[contato.dataset.id]
# §1 continua no lugar
process ch-verificar-msgs | name: CH_VERIFICAR_MSGS
```

```export-check
pagina: 0
# 2.3 DA "Presença"
dynamicAction presença | event: ready
dynamicAction presença | userIsAuthenticated
dynamicAction presença | action: executeJsCode
dynamicAction presença | CX_PRESENCA_PING
dynamicAction presença | window.self !== window.top
```

O Application Process não está em página e não entra no validador: confira à mão no `app-processes.apx` (nome, `point: ajaxCallback`, `pkg_chat_ui.ajax_ping` e sem condição).

### 2.7 Teste

Use dois usuários com colaborador vinculado, da mesma empresa: A num navegador normal e B numa janela anônima ou noutro navegador.

1. **Package:** no SQL Commands, `select pkg_chat_ui.situacao_presenca('ONLINE', systimestamp) from dual;` devolve `online`. Com `systimestamp - interval '10' minute` devolve `ausente`, e com `systimestamp - interval '1' hour`, `offline`.
2. **Ping:** A entra na app e fica na Home. No DevTools (F12) › **Network**, aparece uma chamada `CX_PRESENCA_PING` com resposta `{"ok":true}`. No SQL Commands, a linha de A em `presenca_colaborador` tem `STATUS_PRESENCA = 'ONLINE'` e `DATA_ULTIMO_PING` de agora.
3. **Sem excesso:** A navega por 4 ou 5 páginas em menos de 1 min. Sai **no máximo 1** `CX_PRESENCA_PING` nesse minuto.
4. **Modal:** A abre um modal (por exemplo, Solicitar correção). O modal **não** faz ping próprio (o Network do iframe não mostra `CX_PRESENCA_PING`).
5. **Lista ao vivo:** B abre o Chat. A aparece **online** (ponto verde). Abra um grupo de departamento e deixe aberto.
6. **Ausente:** A para de mexer no mouse e no teclado (ou troca de aba) por uns 9 min. Em até 30 s depois disso, o ponto de A na tela de B fica **ausente**, sem B recarregar nada, e o grupo aberto continua aberto. Se B estiver com a conversa de A aberta, o ponto do cabeçalho também muda.
7. **Volta:** A mexe no mouse na app. Em até ~30 s o ponto de A na tela de B volta a **online**.
8. **Offline:** A fecha o navegador. Depois de 30 min sem ping, A aparece **offline** para B.
9. **Login:** na página de login (deslogado), o Network **não** mostra `CX_PRESENCA_PING`.
10. **Home:** B tem A como gestor, e A está online. O card "Meu gestor" da Home de B mostra A como disponível.

### Se não funcionar

| Sintoma | Causa provável | Correção |
|---|---|---|
| `CX_PRESENCA_PING` responde `{"ok":false}` | Conta sem colaborador ativo, `G_ID_EMPRESA` vazio na sessão ou `login_apex` diferente do usuário APEX | Confira `colaborador.login_apex` e `status`. `G_ID_EMPRESA` é preenchido no login (`SET_G_ID_EMPRESA`): saia e entre de novo |
| Network mostra erro ou `{"error":...}` no `CX_PRESENCA_PING` | Process com outro nome, ponto diferente de *Ajax Callback* ou package não instalado | Refaça o 2.2 (nome exato) e o 2.1. Veja o `apex_debug` com *Debug* ligado |
| Nenhuma chamada `CX_PRESENCA_PING` no Network | A DA não foi criada na página **0**, a condição está errada ou a aba estava sem atividade | Confira o 2.3. No console, `window.cxPresenca` deve existir; `cxPresenca.ping()` força a verificação |
| `CX_PRESENCA_PING` em toda navegação, mais de 1 por minuto | `sessionStorage` bloqueado no navegador | Não é erro: o ping só não consegue lembrar o horário entre páginas. Custo pequeno |
| Na lista, os pontos não mudam sozinhos | `CH_PRESENCAS` não criado ou o JS do 2.5 foi colado no campo errado | Confira o 2.4 e o 2.5. O Network deve mostrar `CH_PRESENCAS` a cada 30 s |
| Todos os pontos viram cinza depois de 30 s | `CH_PRESENCAS` respondendo `{"presencas":{}}`: conta sem colaborador ou sem empresa na sessão | Mesma correção da primeira linha |
| Depois do 2.3, nenhuma DA funciona em página nenhuma (no chat, os departamentos não abrem). Console: `Uncaught SyntaxError: Unexpected token ')'` e `apex.da.initDaEventList is not a function` | O código da DA "Presença" chegou com parêntese sobrando ou faltando (ex.: a primeira linha `(function () {` não foi copiada). O APEX junta o JS de **todas** as DAs da página num só script; um erro de sintaxe em uma derruba todas, e como a DA está na página 0, derruba as DAs da app inteira (caso de 17/11/2026) | Abra a DA "Presença" da página 0, apague o código e cole o do 2.3, que agora começa direto em `if (window.cxPresenca` e não usa `(function () { ... })();`. Para destravar a app na hora, antes de corrigir: *Server-side Condition › Type* = `Never` na DA |
| `chChat is not defined` depois de colar o JS | A linha `chChat.iniciar();` foi apagada ou o JS da §1 sumiu do *Function and Global Variable Declaration* | Mantenha `chChat.iniciar();` na primeira linha e confira a §1.4 |

---

## 3. Barra de rolagem extra da página

**Sintoma:** além da rolagem da conversa, a página inteira ganha uma barra de rolagem na direita e desce alguns pixels.

**Causa:** o CSS Inline da página calcula a altura do chat como `calc(100vh - var(--ch-topbar-h))`, com `--ch-topbar-h: 40px`. Só que o header da app tem `3.5rem` (56 px, `--ut-header-height` no `corlix-tema.css`). O chat fica 16 px mais alto que a tela, e a página rola.

**Correção:** trocar só o valor da variável, sem acrescentar regra nova ao CSS Inline (a migração dele para arquivo continua pendente).

Página 4 › clique no nó da página › **CSS › Inline** › logo no começo, dentro de `:root { ... }`, troque a linha

```css
--ch-topbar-h: 40px;
```

por

```css
--ch-topbar-h: var(--ut-header-height, 3.5rem);
```

Salve e recarregue com Ctrl+Shift+R.

**Teste:** a barra da direita da página some; a lista de contatos e a conversa continuam rolando cada uma na sua coluna; o campo "Escreva uma mensagem" fica encostado no rodapé da tela. No console, `document.documentElement.scrollHeight - window.innerHeight` deve dar `0`.

**No export:** `page 4 | --ch-topbar-h: var(--ut-header-height, 3.5rem);`

---

## 4. Anexos (clipe, arrastar e soltar, Ctrl+V)

### Como funciona

1. **Três jeitos de anexar**, todos com a conversa aberta:
   - o botão de **clipe** ao lado do campo de mensagem;
   - **arrastar** o arquivo do computador e **soltar** sobre a conversa (aparece uma moldura "Solte o arquivo para anexar");
   - **Ctrl+V** de uma imagem copiada (um print, por exemplo) dentro do campo de mensagem.
2. O arquivo fica **pendente** numa prévia acima do campo (miniatura, ou o selo da extensão, com nome, tamanho e um "×" para remover). A pessoa pode escrever um texto junto.
3. **Enviar** (ou Enter) manda o arquivo e o texto juntos ao Ajax Callback `CH_ENVIAR_ANEXO`. Com anexo pendente, o JS deste passo assume o envio no lugar da DA "Enviar Mensagem". Sem anexo, o envio de texto continua igual.
4. O servidor confere tudo antes de gravar: a pessoa participa da conversa, a extensão está na lista, o arquivo tem até **10 MB** e os **primeiros bytes** batem com a extensão (um `.exe` renomeado para `.docx` é recusado). A mensagem vai para `canal_mensagem` e o arquivo para `canal_mensagem_anexo`, que já existia no banco. É **1 anexo por mensagem**.
5. Na conversa:
   - **imagem** aparece como miniatura; clicar abre a imagem inteira numa aba nova;
   - **Excel, Word e PowerPoint** aparecem como um cartão com o selo da extensão (verde, azul ou vermelho), nome e tamanho; clicar baixa o arquivo, e o navegador oferece abrir no programa;
   - arquivo que **pode ter macro** (`.xlsm`, `.xlsb`, `.docm`, `.pptm` e os antigos `.xls`, `.doc`, `.ppt`, `.pps`) ganha o aviso "⚠ Pode conter macros: só abra se confiar em quem enviou".
6. O download passa pela própria página 4, com o request `BAIXAR_ANEXO` (ou `VER_ANEXO` para a miniatura) e o link com checksum. O package só entrega o arquivo para quem participa da conversa: um link copiado não abre para outra pessoa.

**Extensões aceitas:**

| Família | Extensões |
|---|---|
| Excel | `xlsx`, `xls`, `xlsm`, `xlsb`, `xltx`, `csv` |
| Word | `docx`, `doc`, `docm`, `dotx`, `rtf` |
| PowerPoint | `pptx`, `ppt`, `pptm`, `ppsx`, `pps`, `potx` |
| Imagens | `jpg`, `jpeg`, `png`, `gif`, `webp`, `bmp` |

Ficam de fora, de propósito: `svg` (pode conter script), `heic` e `tiff` (o navegador não mostra), executáveis e compactados.

**Referências reutilizadas:** a lista de tipos por extensão e o download com `apex_http.download` por request vêm do Suporte TI (`pkg_suporte.mime_permitido` e `baixar_anexo`, página 36); o envio do arquivo em base64 por `apex.server.process` vem da foto de perfil (`modulos/arquivos/foto-perfil.js`); a região Mensagens e a assinatura do polling são as da §1, sem mudança.

### 4.1 Banco: atualizar o `pkg_chat_ui`

O package é o mesmo da §2, agora com as funções de anexo. Reinstalar não atrapalha a presença.

1. **SQL Workshop › SQL Scripts › Create**, *Script Name* `chat_anexos`.
2. Cole, na ordem e num script só: o `01_ddl_anexo.sql`, o `pkg_chat_ui.pks` e o `pkg_chat_ui.pkb` de `modulos/chat/`.
3. **Run › Run Now**. O resultado deve ter **3 comandos com sucesso e 0 erros**.

(Pelo SQLcl: `cd modulos/chat` e `sql <usuario>@<servico> @instalar.sql`.)

O `01_ddl_anexo.sql` só cria um índice único pela mensagem (a tabela já existe):

```sql
create unique index if not exists idx_canalanexo_msg
    on canal_mensagem_anexo (id_canal_mensagem);
```

O código completo do package está nos arquivos `pkg_chat_ui.pks` e `pkg_chat_ui.pkb`.

### 4.2 Arquivo CSS do módulo

1. **Shared Components › Static Application Files › Create File**.
2. *Directory* `modulos/chat`, envie o `chat.css` e depois o `chat.min.css` (os dois de `modulos/chat/`).
3. Página 4 › nó da página › **CSS › File URLs**:

   ```
   #APP_FILES#modulos/chat/chat#MIN#.css
   ```

Não mexa no **CSS › Inline** da página: os estilos novos estão todos no arquivo.

### 4.3 Página 4: item e processos

**a) Item `P4_ID_ANEXO`.** Página 4 › aba **Rendering** › botão direito em **Body** (ou onde estão os outros itens `P4_*`) › **Create Page Item**:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `P4_ID_ANEXO` |
| Identification | Type | `Hidden` |
| Settings | Value Protected | `On` (o padrão) |

**b) Processo de download.** Aba **Processing** › **Pre-Rendering** › botão direito em **Before Header** › **Create Process**:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `Baixar anexo` |
| Identification | Type | `Execute Code` |
| Source | PL/SQL Code | `pkg_chat_ui.baixar_anexo(:P4_ID_ANEXO, :REQUEST = 'VER_ANEXO');` |
| Execution | Sequence | `5` |
| Server-side Condition | Type | `Request is contained in Value` |
| Server-side Condition | Value | `BAIXAR_ANEXO,VER_ANEXO` |

Esse processo só roda quando o link de um anexo é aberto. Ele entrega o arquivo e encerra ali, sem montar a página.

**c) Ajax Callback do envio.** Aba **Processing** › botão direito em **Ajax Callback** › **Create Process**:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `CH_ENVIAR_ANEXO` |
| Identification | Type | `Execute Code` |
| Source | PL/SQL Code | `pkg_chat_ui.ajax_enviar_anexo;` |
| Execution | Point | `Ajax Callback` |

### 4.4 Página 4: HTML do campo de mensagem

Região **Composer** › **Source › HTML Code**: troque todo o conteúdo por:

```html
<div class="ch-composer">
  <div class="ch-anexo-previa" hidden></div>
  <button type="button" class="ch-clip" aria-label="Anexar arquivo"
          title="Anexar arquivo (ou arraste para a conversa)">
    <span class="fa fa-paperclip" aria-hidden="true"></span>
  </button>
  <input type="file" id="ch-arquivo" hidden
         accept=".xlsx,.xls,.xlsm,.xlsb,.xltx,.csv,.docx,.doc,.docm,.dotx,.rtf,.pptx,.ppt,.pptm,.ppsx,.pps,.potx,.jpg,.jpeg,.png,.gif,.webp,.bmp">
  <textarea id="ch-texto" rows="1" maxlength="4000"
            placeholder="Escreva uma mensagem… (Enter envia, Shift+Enter quebra linha)"
            aria-label="Mensagem"></textarea>
  <button type="button" class="ch-enviar">
    <span class="fa fa-paper-plane" aria-hidden="true"></span> Enviar
  </button>
</div>
```

O textarea e o botão Enviar continuam com o mesmo `id` e a mesma classe: as DAs "Enviar Mensagem" e "Enter envia mensagem" seguem funcionando.

### 4.5 Página 4: SQL da região Mensagens e coluna nova

1. Região **Mensagens** › **Source › SQL Query**: troque pelo SQL abaixo. Muda só o `select` final: o `left join` com o anexo, a coluna `ANEXO_HTML` e o `CORPO`, que fica vazio quando a mensagem é só o arquivo.

```sql
with ultimas as (
  -- as 200 mensagens mais recentes (o Number of Rows da região também é 200)
  select m.id_canal_mensagem,
         m.id_colaborador,
         m.corpo,
         m.data_envio
  from   canal_mensagem m
  where  m.id_canal = :P4_CANAL_ID
  and    nvl(m.excluida, false) = false
  -- só exibe canais dos quais o usuário logado participa
  and    exists (
           select 1
           from   canal_participante cp
           join   colaborador eu on eu.id_colaborador = cp.id_colaborador
           where  cp.id_canal = m.id_canal
           and    upper(eu.login_apex) = upper(:APP_USER)
         )
  order  by m.data_envio desc, m.id_canal_mensagem desc
  fetch  first 200 rows only
)
select -- mensagem só com arquivo: o corpo guarda o nome do arquivo, que não precisa aparecer
       case when a.id_anexo is not null and u.corpo = a.nome_arquivo then null
            else u.corpo end                              as corpo,
       to_char(u.data_envio, 'hh24:mi') as hora,
       case when upper(col.login_apex) = upper(:APP_USER) then 'out' else 'in' end as lado,
       case when row_number() over (
                   partition by trunc(u.data_envio)
                   order by u.data_envio, u.id_canal_mensagem
                 ) = 1
            then '<div class="ch-sep"><span>' ||
                 case when trunc(u.data_envio) = trunc(sysdate) then 'HOJE'
                      when trunc(u.data_envio) = trunc(sysdate)-1 then 'ONTEM'
                      else to_char(u.data_envio, 'dd/mm/yyyy') end ||
                 '</span></div>'
       end as sep_dia,
       -- usado pelo polling (data-id no template Chat Mensagens)
       u.id_canal_mensagem as id_msg,
       -- miniatura ou cartão do anexo (HTML gerado e escapado pelo package)
       case when a.id_anexo is not null
            then pkg_chat_ui.html_anexo(a.id_anexo, a.nome_arquivo, a.tamanho)
       end                                                as anexo_html
from   ultimas u
join   colaborador col on col.id_colaborador = u.id_colaborador
left   join canal_mensagem_anexo a on a.id_canal_mensagem = u.id_canal_mensagem
order  by u.data_envio, u.id_canal_mensagem
```

2. Salve. O Builder cria a coluna **ANEXO_HTML** sozinho, embaixo de Mensagens › Columns. Clique nela e ajuste:

| Seção | Atributo | Valor |
|---|---|---|
| Security | Escape special characters | `Off` |

Só essa coluna fica sem escape, porque o package já escapa o nome do arquivo. A coluna **CORPO** continua com escape `On`.

### 4.6 Template "Chat Mensagens"

**Shared Components › Templates** › filtre por *Report* › **Chat Mensagens** › **Row Templates › Row Template 1**: troque por:

```html
#SEP_DIA#
<div class="ch-msg ch-msg--#LADO#" data-id="#ID_MSG#">
  <div class="ch-bubble">
    #ANEXO_HTML#
    <span class="ch-txt">#CORPO#</span>
    <span class="ch-time">#HORA#</span>
  </div>
</div>
```

Só entrou a linha `#ANEXO_HTML#`. O `data-id` continua, porque o polling da §1 depende dele.

### 4.7 Página 4: JavaScript dos anexos

Nó da página 4 › **JavaScript › Execute when Page Loads**: o campo já tem o `chChat.iniciar();` e o bloco da presença (§2.5). **Não apague nada**: vá até o fim e cole, depois de tudo, o conteúdo de `modulos/chat/chat-anexo.js`.

O arquivo começa em `// Anexos do chat` e termina em `})();`. Confira que as duas pontas vieram na cópia.

### 4.8 Como deve ficar no export

- `corlixhub/pages/p00004-chat.apx`: `fileUrls` com `modulos/chat/chat#MIN#.css`; item `P4_ID_ANEXO`; processo `Baixar anexo` (Before Header, `requestIsContainedInValue`, `BAIXAR_ANEXO,VER_ANEXO`); processo `CH_ENVIAR_ANEXO` (`ajaxCallback`); `ch-clip` e `ch-arquivo` no Composer; `anexo_html` no SQL de Mensagens e a coluna `ANEXO_HTML` com `escapeSpecialChars: false`; `"CH_ENVIAR_ANEXO"` no JavaScript.
- `classic-report-templates/chat-mensagens.apx`: `#ANEXO_HTML#`.
- `static-files.apx`: `modulos/chat/chat.css` e `modulos/chat/chat.min.css`.

```export-check
pagina: 4
page 4 | fileUrls: #APP_FILES#modulos/chat/chat#MIN#.css
page 4 | "CH_ENVIAR_ANEXO"
page 4 | is-arrastando
pageItem P4_ID_ANEXO | type: hidden
process baixar-anexo | pkg_chat_ui.baixar_anexo(:P4_ID_ANEXO, :REQUEST = 'VER_ANEXO');
process baixar-anexo | requestIsContainedInValue
process baixar-anexo | BAIXAR_ANEXO,VER_ANEXO
process ch-enviar-anexo | pkg_chat_ui.ajax_enviar_anexo
process ch-enviar-anexo | point: ajaxCallback
region composer | ch-clip
region composer | id="ch-arquivo"
region composer | id="ch-texto"
region msgs | pkg_chat_ui.html_anexo
region msgs | left   join canal_mensagem_anexo
```

Confira à mão a coluna `ANEXO_HTML` (`escapeSpecialChars: false`), o template `chat-mensagens.apx` (`#ANEXO_HTML#` e `data-id="#ID_MSG#"`) e os dois arquivos no `static-files.apx`.

### 4.9 Teste

Use dois usuários da mesma empresa, A e B, com a conversa entre os dois aberta nas duas telas. Separe um arquivo de cada família, um com macro (`.xlsm`) e um maior que 10 MB.

1. **Clipe:** A clica no clipe, escolhe um `.xlsx` e vê a prévia com selo `XLSX`, nome e tamanho. Clica em Enviar. Em até ~1 s o cartão aparece para A e para B, sem recarregar a página.
2. **Arrastar:** A arrasta um `.png` do computador sobre a conversa. Aparece a moldura "Solte o arquivo para anexar"; ao soltar, a prévia mostra a miniatura. Envia com Enter. A miniatura aparece na conversa; clicar abre a imagem numa aba nova.
3. **Ctrl+V:** A tira um print (Win+Shift+S), clica no campo de mensagem e aperta Ctrl+V. A prévia aparece. Escreve "olha isso" e envia. A bolha mostra a imagem e o texto.
4. **Download:** B clica no cartão do `.xlsx`. O arquivo baixa com o nome original e abre no Excel.
5. **Macro:** A envia um `.xlsm`. O cartão mostra o aviso "Pode conter macros".
6. **Remover:** A anexa um arquivo e clica no "×". A prévia some e Enviar volta a mandar só texto.
7. **Recusas:** um `.svg` ou `.pdf` mostra "Tipo de arquivo não aceito"; o arquivo de mais de 10 MB mostra "O arquivo pode ter até 10 MB". Um `.txt` renomeado para `.docx` é recusado pelo servidor ("O conteúdo do arquivo não corresponde à extensão .docx").
8. **Permissão:** B copia o link de um anexo (botão direito › copiar endereço do link) e abre numa janela de um usuário C, que não participa da conversa. Abre uma página de erro, e não o arquivo.
9. **Tamanho no limite:** um arquivo de 9 a 10 MB chega inteiro (veja a observação sobre o ORDS em "Se não funcionar").
10. **Texto continua igual:** sem anexo, Enter e o botão Enviar mandam mensagem de texto como antes.

### Se não funcionar

| Sintoma | Causa provável | Correção |
|---|---|---|
| O clipe não aparece | HTML do 4.4 não salvo, ou o CSS do 4.2 não carregou | Confira o HTML do Composer e o *File URL*. No Network, `chat.min.css` deve responder 200 |
| Console: `chAnexo: falta o HTML do passo 4.4` | O Composer ainda está com o HTML antigo | Refaça o 4.4 |
| Arrastar abre o arquivo no navegador e sai do chat | O JS do 4.7 não rodou (erro antes dele, ou não foi colado) | Veja o console. Confira que o `chat-anexo.js` está no fim do *Execute when Page Loads*, inteiro |
| Enviar com anexo grava só o texto | O JS do 4.7 não está ativo, e a DA "Enviar Mensagem" fez o envio normal | Mesmo que acima |
| "Não foi possível enviar o arquivo" em todo envio | Package não reinstalado (falta `ajax_enviar_anexo`) ou o processo não se chama `CH_ENVIAR_ANEXO` | Refaça o 4.1 e confira o nome do 4.3 c. Com *Debug* ligado, o erro real aparece em `apex_debug` |
| Arquivos pequenos vão, os grandes (vários MB) falham com erro de rede ou HTTP 413/400 | Limite de tamanho da requisição no ORDS/servidor: o arquivo viaja em base64, cerca de 1,35 vez o tamanho original | Teste até onde passa. Se o limite do ambiente for menor que 10 MB, baixe `MAX_BYTES` no JS e `c_max_anexo` no package para o mesmo valor, e registre aqui |
| A bolha mostra o HTML do cartão como texto (`<a class="ch-anexo...`) | Coluna `ANEXO_HTML` com escape ligado | 4.5, passo 2: *Escape special characters* = `Off` |
| A bolha não mostra nada do anexo | Template sem `#ANEXO_HTML#` ou SQL sem a coluna | Refaça o 4.5 e o 4.6 |
| Miniatura quebrada ou clicar no cartão abre a página do chat | Processo `Baixar anexo` sem a condição, com outro request ou com sequence depois de outro Before Header | 4.3 b: *Request is contained in Value* `BAIXAR_ANEXO,VER_ANEXO`, sequence `5` |
| Clicar no anexo dá erro de checksum | Link montado sem o `apex_page.get_url` ou item `P4_ID_ANEXO` criado com outro nome | O link vem do package; confira o nome do item (4.3 a) |
| Ping, bolinhas e anexo param juntos; `user_errors` mostra `PLS-00231: function 'MIME_ANEXO' may not be used in SQL` | Versão anterior do `pkg_chat_ui.pkb` chamava a função privada `mime_anexo` dentro do `insert` (caso de 17/11/2026). Package inválido derruba tudo que depende dele | Use o `.pkb` atual (`l_mime := mime_anexo(l_ext)` antes do `insert`) e recompile |
| Erro ao compilar: `ORA-00955` ou índice já existe | O índice já foi criado antes | Sem problema: o `if not exists` deixa o script reexecutável. Se o banco recusar a sintaxe, rode o `create unique index` sem o `if not exists` uma única vez |

---

## Situação

| Data | Evento | Evidência | Pendências |
|---|---|---|---|
| 17/11/2026 | §1 encontrada aplicada no backup de DEV (`CH_VERIFICAR_MSGS`, `data-id`, JS do polling) | `corlixhub/pages/p00004-chat.apx` no commit `7016ea7` | Validar contra o checklist e rodar os testes da §1.8 |
| 17/11/2026 | §2 Presença **proposta e versionada** (`pkg_chat_ui`, `presenca-global.js`, `chat-presenca.js`, passos 2.1 a 2.5) | Este guia e os arquivos de `modulos/chat/` | Instalar o package, aplicar no Builder, validar o export e rodar os testes da §2.7 |
| 17/11/2026 | Erro ao aplicar o 2.3: `SyntaxError: Unexpected token ')'` derrubou todas as DAs da app. Código da DA trocado por uma versão sem `(function () { ... })();` | Console do time na página 4 | Recolar o código do 2.3 e refazer os testes da §2.7 |
| 17/11/2026 | §3 aplicada pelo time (`--ch-topbar-h`) | Confirmação do time: a barra extra sumiu | Conferir no próximo backup |
| 17/11/2026 | §4 Anexos **proposta e versionada** (`01_ddl_anexo.sql`, `pkg_chat_ui` com anexos, `chat.css`/`.min.css`, `chat-anexo.js`) | Este guia e os arquivos de `modulos/chat/` | Instalar, aplicar 4.1 a 4.7, validar o export e rodar os testes da §4.9, inclusive o limite de tamanho do ORDS (teste 9) |
| 17/11/2026 | §2, §3 e §4 **aplicadas e funcionando** segundo o time (presença, altura e anexos), depois da correção do `PLS-00231` no `pkg_chat_ui` | Relato do time na sessão; sem export validado ainda | Validar o próximo backup contra os `export-check` e registrar os testes da §2.7 e da §4.9 um a um (inclusive o limite de 10 MB no ORDS) |

Fora do escopo deste guia, ainda em aberto: abrir a conversa com uma pessoa pela URL (atalho "Mensagem" do perfil e da Home), marcar offline no logout e migrar o CSS inline da página 4 para arquivo.
