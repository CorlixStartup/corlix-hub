# 06 · API PL/SQL (núcleo da aplicação)

> Base: documentação oficial Oracle APEX 26.1 (Oracle APEX API Reference, livro `aeapi`: capítulos APEX_APPLICATION, APEX_APP_SETTING, APEX_SESSION, APEX_SESSION_STATE, APEX_UTIL, APEX_PAGE, APEX_ERROR, APEX_DEBUG, APEX_ESCAPE, APEX_STRING, APEX_STRING_UTIL, APEX_JSON, APEX_COLLECTION, APEX_LANG, APEX_CSS, APEX_JAVASCRIPT, APEX_T_JAVASCRIPT_OBJECT, APEX_PLUGIN, APEX_PLUGIN_UTIL, APEX_REGION, APEX_IR, APEX_IG, APEX_THEME, APEX_ACL, APEX_AUTHENTICATION, APEX_AUTHORIZATION, APEX_CUSTOM_AUTH, APEX_LDAP, APEX_MARKDOWN, APEX_SHARED_COMPONENT, APEX_ITEM (Legacy), APEX_APP_OBJECT_DEPENDENCY, APEX_DB_DICTIONARY, APEX_UI_DEFAULT_UPDATE, JavaScript APIs; e trechos do App Builder User's Guide `htmdb` sobre Error Handling, Evaluation Point e APEX Views). Gerado em 21/10/2026.

Referência das APIs PL/SQL que uma app APEX usa no dia a dia: contexto e sessão, session state, URLs, erros, debug, escape, strings, JSON, coleções, segurança (ACL, autenticação, autorização), regiões/IR/IG, tradução, plug-ins e utilitários. Cada package tem a tabela completa de membros e, para os mais usados, assinatura, comportamento, exceções e exemplo. APIs **Deprecated**/**Legacy** estão marcadas.

**Sumário**
1. Contexto da aplicação e sessão: `APEX_APPLICATION`, `APEX_APP_SETTING`, `APEX_SESSION`, `APEX_SESSION_STATE`, `APEX_PAGE`
2. Erros e debug: `APEX_ERROR`, `APEX_DEBUG`
3. Escape e segurança de saída: `APEX_ESCAPE`
4. Utilitários gerais: `APEX_UTIL`
5. Strings e listas: `APEX_STRING`, `APEX_STRING_UTIL`
6. JSON: `APEX_JSON`
7. Coleções: `APEX_COLLECTION`
8. Segurança: `APEX_ACL`, `APEX_AUTHORIZATION`, `APEX_AUTHENTICATION`, `APEX_CUSTOM_AUTH`, `APEX_LDAP`
9. Regiões e relatórios: `APEX_REGION`, `APEX_IR`, `APEX_IG`
10. Tradução, front-end e tema: `APEX_LANG`, `APEX_CSS`, `APEX_JAVASCRIPT`, `APEX_T_JAVASCRIPT_OBJECT`, `APEX_THEME`, `APEX_MARKDOWN`
11. Componentes, dependências, plug-ins e legados: `APEX_SHARED_COMPONENT`, `APEX_APP_OBJECT_DEPENDENCY`, `APEX_PLUGIN`, `APEX_PLUGIN_UTIL`, `APEX_ITEM` (Legacy), `APEX_DB_DICTIONARY`, `APEX_UI_DEFAULT_UPDATE`, views do dicionário
12. Aplicação no Corlix Hub

Convenções deste documento: assinaturas copiadas da doc (às vezes resumidas com `p0 .. p9` ou `|` para variantes); exemplos adaptados ao Corlix Hub (`:G_ID_EMPRESA`, tabelas `COLABORADOR`, `EQUIPE`…) são ilustrativos e devem ser conferidos com o schema real (`docs/ai-context/05`).

## APEX_APPLICATION: motor de renderização, variáveis globais e STOP_APEX_ENGINE

`APEX_APPLICATION` é o package PL/SQL que implementa o motor de renderização do APEX. No dia a dia ele interessa por três motivos: as **variáveis globais** (`G_USER`, `G_FLOW_ID`, `G_REQUEST`, `G_X01..G_X10`…), o procedimento `STOP_APEX_ENGINE` (encerrar o request depois de um redirect ou download) e os arrays legados `G_F01..G_F50`.

| Membro | Tipo | O que faz |
|---|---|---|
| `G_USER`, `G_FLOW_ID`, `G_FLOW_STEP_ID`… | Variáveis globais | Contexto do request atual (ver tabela abaixo) |
| `G_F01` … `G_F50` | Arrays (Legacy) | Valores postados por itens gerados com `APEX_ITEM` |
| `HELP` | Procedure | Gera em HTML a ajuda da página e dos itens |
| `STOP_APEX_ENGINE` | Procedure | Para o processamento e sai imediatamente (levanta `E_STOP_APEX_ENGINE`) |
| `E_STOP_APEX_ENGINE` | Exceção | Levantada internamente por `STOP_APEX_ENGINE` |

Fonte: [APEX_APPLICATION](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION.html)

### APEX_APPLICATION: tabela das variáveis globais (G_USER, G_FLOW_ID, G_REQUEST, G_X01…)

| Variável | Significado |
|---|---|
| `G_USER` | Usuário logado (equivale a `:APP_USER`) |
| `G_FLOW_ID` | ID da aplicação em execução (`:APP_ID`) |
| `G_FLOW_STEP_ID` | ID da página em execução (`:APP_PAGE_ID`) |
| `G_FLOW_OWNER` | Parsing schema da aplicação; em SQL/PL/SQL use `#OWNER#`. Alterar em runtime **não** muda o parsing schema |
| `G_REQUEST` | Valor do REQUEST mais recente (`:REQUEST`) |
| `G_BROWSER_LANGUAGE` | Idioma preferido do navegador |
| `G_DEBUG` | Debug ligado ou não (`Yes`/`No`) |
| `G_HOME_LINK` | Página inicial da app (destino padrão quando nenhuma página é informada) |
| `G_LOGIN_URL` | URL de login para usuários não logados |
| `G_IMAGE_PREFIX` | Caminho virtual das imagens do APEX (`#APEX_FILES#`) |
| `G_FLOW_SCHEMA_OWNER` | Dono do schema do APEX |
| `G_PRINTER_FRIENDLY` | Se o request está em modo de impressão (útil em condições) |
| `G_PROXY_SERVER` | Atributo *Proxy Server* da app |
| `G_SYSDATE` | Data atual do servidor (tipo `DATE`) |
| `G_PUBLIC_USER` | Schema usado na conexão do gateway (DAD) |
| `G_GLOBAL_NOTIFICATION` | Atributo *Global Notification* da app |
| `G_X01` … `G_X10` | Parâmetros `x01..x10` do request; típicos em processos Ajax *On-Demand* (`apex.server.process`) |

Pegadinhas:
- Em código de página prefira as *bind variables* (`:APP_USER`, `:APP_ID`) ou `V('APP_USER')`; as `G_*` são úteis em packages que rodam dentro do request.
- `G_X01..G_X10` só têm valor no request Ajax que os enviou.
- `G_INSTANCE` (usado como default de vários parâmetros `p_session`, por exemplo em `APEX_SESSION.DELETE_SESSION`) é o ID da sessão atual.

Fonte: [Global Variables](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION-Global-Variables.html)

### APEX_APPLICATION.STOP_APEX_ENGINE: encerrar o request após redirect ou download

Sinaliza ao motor que pare tudo e saia na hora, para não acrescentar mais HTML ao buffer HTTP. Uso típico: depois de `owa_util.redirect_url`, de um download de arquivo (`wpg_docload`/`htp`) ou de gerar uma resposta JSON num processo Ajax.

```sql
APEX_APPLICATION.STOP_APEX_ENGINE;
```

Comportamento: levanta internamente `APEX_APPLICATION.E_STOP_APEX_ENGINE`. **Se o seu bloco tiver `WHEN OTHERS`, re-levante essa exceção**, senão o motor continua e a página pode sair corrompida ou o erro é engolido.

```sql
begin
    owa_util.redirect_url('https://exemplo.com');
    apex_application.stop_apex_engine;
exception
    when apex_application.e_stop_apex_engine then
        raise;          -- obrigatório: deixe o APEX parar
    when others then
        apex_debug.error('Falhou: %s', sqlerrm);
        raise;
end;
```

Fonte: [STOP_APEX_ENGINE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/STOP_APEX_ENGINE-Procedure.html)

### APEX_APPLICATION.HELP: página de ajuda gerada a partir do help text

Gera HTML com o help da página e dos itens. Assinatura:

```sql
APEX_APPLICATION.HELP (
    p_request             IN VARCHAR2 DEFAULT NULL,   -- não usado
    p_flow_id             IN VARCHAR2 DEFAULT NULL,
    p_flow_step_id        IN VARCHAR2 DEFAULT NULL,
    p_show_item_help      IN VARCHAR2 DEFAULT 'YES',
    p_show_regions        IN VARCHAR2 DEFAULT 'YES',
    p_before_page_html    IN VARCHAR2 DEFAULT '<p>',
    p_after_page_html     IN VARCHAR2 DEFAULT NULL,
    p_before_region_html  IN VARCHAR2 DEFAULT NULL,
    p_after_region_html   IN VARCHAR2 DEFAULT '</td></tr></table></p>',
    p_before_prompt_html  IN VARCHAR2 DEFAULT '<p><b>',
    p_after_prompt_html   IN VARCHAR2 DEFAULT '</b></p>:&nbsp;',
    p_before_item_html    IN VARCHAR2 DEFAULT NULL,
    p_after_item_html     IN VARCHAR2 DEFAULT NULL );
```

Padrão de uso: criar uma página de ajuda com uma região *PL/SQL Dynamic Content* chamando `APEX_APPLICATION.HELP(p_flow_id => :APP_ID, p_flow_step_id => :REQUEST)`, e um link na *Navigation Bar* que passa `&APP_PAGE_ID.` como REQUEST. Os parâmetros `p_before/after_*` mudam a marcação; os de região são ignorados com `p_show_regions = 'NO'` e os de item com `p_show_item_help = 'NO'`.

Fonte: [HELP Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/HELP-Procedure.html)

### APEX_APPLICATION.G_F01..G_F50: arrays de formulário manual (Legacy)

**Legacy**: será removido numa versão futura; a Oracle recomenda Interactive Grid. Os arrays `G_F01`…`G_F50` recebem, no submit, os valores dos campos gerados por `APEX_ITEM.TEXT`, `APEX_ITEM.SELECT_LIST` etc. O número do array é o `p_idx` passado ao `APEX_ITEM`.

```sql
-- Classic Report (colunas com Escape Special Characters desligado)
select apex_item.hidden(1, empno) || apex_item.text(2, ename) ename,
       apex_item.text(5, sal) sal
  from emp;

-- Processo After Submit
for i in 1 .. apex_application.g_f01.count loop
    update emp set ename = apex_application.g_f02(i),
                   sal   = apex_application.g_f05(i)
     where empno = apex_application.g_f01(i);
end loop;
```

Pegadinhas:
- `APEX_ITEM.CHECKBOX` só manda valor das linhas **marcadas**: o array do checkbox tem menos elementos que os outros, então não indexe por `i` em paralelo.
- Fora do contexto `APEX_ITEM`, use `APEX_T_VARCHAR2` e `APEX_STRING`. `APEX_UTIL.TABLE_TO_STRING`/`STRING_TO_TABLE` estão deprecated: use `APEX_STRING.TABLE_TO_STRING`/`STRING_TO_TABLE`.
- Desligar o escape da coluna para renderizar o HTML do `APEX_ITEM` abre espaço para XSS se outros dados da linha não forem escapados.

Fonte: [Working with G_Fnn Arrays (Legacy)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/working-with-g_fnn-arrays.html)

## APEX_APP_SETTING: ler e gravar Application Settings

Utilitário para os *Application Settings* (componente compartilhado chave/valor configurável sem redeploy).

| Membro | O que faz |
|---|---|
| `GET_VALUE` (function) | Lê o valor de um setting da app atual |
| `SET_VALUE` (procedure) | Altera o valor de um setting da app atual |

Fonte: [APEX_APP_SETTING](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APP_SETTING.html)

### APEX_APP_SETTING.GET_VALUE e SET_VALUE: assinatura e erros

```sql
APEX_APP_SETTING.GET_VALUE (
    p_name          IN VARCHAR2,
    p_raise_error   IN BOOLEAN DEFAULT FALSE )
RETURN VARCHAR2;

APEX_APP_SETTING.SET_VALUE (
    p_name          IN VARCHAR2,
    p_value         IN VARCHAR2,
    p_raise_error   IN BOOLEAN DEFAULT FALSE );
```

- `p_name` não diferencia maiúsculas. Há erro se o setting não existir ou se a *Build Option* associada estiver desligada.
- `SET_VALUE` falha se o setting for *required* e o valor vier nulo, ou se houver *valid values* e o valor não estiver na lista.
- `p_raise_error => FALSE` (padrão) **suprime** as mensagens: o valor simplesmente não é gravado, sem aviso. Use `TRUE` quando precisar saber que falhou.
- Se o setting é **subscrito** de outra app, `SET_VALUE` não altera nada (e com `p_raise_error => TRUE` levanta erro).

```sql
declare
    l_ativo varchar2(4000);
begin
    l_ativo := apex_app_setting.get_value(p_name => 'ACCESS_CONTROL_ENABLED');
    if l_ativo is null then
        apex_app_setting.set_value(p_name => 'ACCESS_CONTROL_ENABLED',
                                   p_value => 'Y',
                                   p_raise_error => true);
    end if;
end;
```

Fonte: [GET_VALUE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APP_SETTING.GET_VALUE-Function.html), [SET_VALUE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APP_SETTING.SET_VALUE-Procedure.html)

## APEX_SESSION: criar, anexar, apagar sessões e ligar debug/trace

`APEX_SESSION` configura sessões APEX. É a forma suportada de ter um contexto APEX (`V('APP_USER')`, itens, coleções) **fora** do navegador: jobs `DBMS_SCHEDULER`, testes utPLSQL, scripts SQL*Plus/SQLcl.

| Membro | O que faz |
|---|---|
| `CREATE_SESSION` | Cria sessão nova para app/página/usuário e roda o *Initialization PL/SQL Code* |
| `ATTACH` | Anexa a uma sessão existente e roda o *Initialization PL/SQL Code* |
| `DETACH` | Desanexa, reseta o ambiente e roda o *Cleanup PL/SQL Code* |
| `DELETE_SESSION` | Apaga a sessão (se anexada, roda o Cleanup e reseta) |
| `SET_DEBUG` | Define nível de debug para os próximos requests da sessão |
| `SET_TRACE` | Liga/desliga SQL trace nos próximos requests da sessão |
| `SET_TENANT_ID` | Associa um tenant ID à sessão (lido via `APP_TENANT_ID`) |

Fonte: [APEX_SESSION](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_SESSION.html)

### APEX_SESSION.CREATE_SESSION: sessão APEX em job, teste ou script

```sql
APEX_SESSION.CREATE_SESSION (
   p_app_id                   IN NUMBER,
   p_page_id                  IN NUMBER,
   p_username                 IN VARCHAR2,
   p_call_post_authentication IN BOOLEAN DEFAULT FALSE );
```

- Cria a sessão, monta o ambiente e roda o *Initialization PL/SQL Code* da app.
- `p_call_post_authentication => TRUE` também chama o procedimento *Post-Authentication* do esquema de autenticação (útil para popular app items como empresa do usuário).
- Exceção: `WWV_FLOW.APP_NOT_FOUND_ERR` (app inexistente ou chamador sem acesso ao workspace).
- **Não é suportado** em *SQL Commands* e *SQL Scripts* do SQL Workshop.

```sql
begin
    apex_session.create_session(p_app_id => 100, p_page_id => 1,
                                p_username => 'EXAMPLE_USER');
    dbms_output.put_line('App '||v('APP_ID')||' sessão '||v('APP_SESSION'));
    -- ... código que depende de contexto APEX ...
    apex_session.delete_session;   -- limpa ao terminar
end;
```

Fonte: [CREATE_SESSION Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CREATE_SESSION-Procedure.html)

### APEX_SESSION.ATTACH, DETACH e DELETE_SESSION: reutilizar e encerrar sessões

```sql
APEX_SESSION.ATTACH (
    p_app_id        IN  NUMBER,
    p_page_id       IN  NUMBER,
    p_session_id    IN  NUMBER );

APEX_SESSION.DETACH;

APEX_SESSION.DELETE_SESSION (
    p_session_id    IN  NUMBER  DEFAULT apex_application.g_instance );
```

- `ATTACH` monta o ambiente de uma sessão existente e roda o *Initialization PL/SQL Code*. Exceções: `WWV_FLOW.APP_NOT_FOUND_ERR`, `APEX.SESSION.EXPIRED` (sessão terminou), `SECURITY_GROUP_ID_INVALID` (workspace inválido).
- `DETACH` reseta o ambiente e roda o *Cleanup PL/SQL Code*; não faz nada se não houver sessão anexada.
- `DELETE_SESSION` apaga a sessão informada (padrão: a atual). Se ela estiver anexada, roda o Cleanup e reseta o ambiente. Exceções: `APEX.SESSION.EXPIRED`, `SECURITY_GROUP_ID_INVALID`.

```sql
begin
    apex_session.attach(p_app_id => 100, p_page_id => 1, p_session_id => 12345678);
    dbms_output.put_line(v('APP_USER'));
    apex_session.detach;
end;
```

Fonte: [ATTACH Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ATTACH-Procedure.html), [DETACH Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/DETACH-Procedure.html), [DELETE_SESSION Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/DELETE_SESSION-Procedure.html)

### APEX_SESSION.SET_DEBUG e SET_TRACE: depurar a sessão de outro usuário

```sql
APEX_SESSION.SET_DEBUG (
    p_session_id    IN NUMBER DEFAULT apex_application.g_instance,
    p_level         IN apex_debug.t_log_level );   -- NULL desliga; 1..9 liga

APEX_SESSION.SET_TRACE (
    p_session_id    IN NUMBER  DEFAULT apex_application.g_instance,
    p_mode          IN VARCHAR2 );                 -- NULL desliga; 'SQL' liga SQL trace
```

Valem para **todos os requests futuros** da sessão. A sessão precisa ser do workspace atual (ou o chamador precisa poder definir o workspace dela). Os exemplos da doc fazem `commit` depois da chamada, para a mudança valer nos requests seguintes.

```sql
begin
    apex_session.set_debug(p_session_id => 1234, p_level => apex_debug.c_log_level_info);
    commit;
end;
```

Fonte: [SET_DEBUG Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_DEBUG-Procedure.html), [SET_TRACE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_TRACE-Procedure.html)

### APEX_SESSION.SET_TENANT_ID: apps multitenant com APP_TENANT_ID

```sql
APEX_SESSION.SET_TENANT_ID ( p_tenant_id IN VARCHAR2 );
```

Associa a sessão a um tenant; depois o valor fica disponível no built-in `APP_TENANT_ID`. Só pode ser definido **uma vez** por sessão. Exceções: `PE.DISPLAY_GROUP.SESSION_NOT_VALID` (sessão não existe) e `WWV_FLOW_SESSION_API.TENANT_ID_EXISTS` (tenant já definido). Uso típico: no *Post-Authentication*, depois de descobrir a empresa do usuário.

Fonte: [SET_TENANT_ID Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_TENANT_ID.html)

## APEX_SESSION_STATE: ler e gravar session state com tipo (VARCHAR2, CLOB, BOOLEAN, NUMBER, TIMESTAMP)

Package moderno para session state tipado. Alternativa a `V()`/`NV()` e `APEX_UTIL.SET_SESSION_STATE`, com suporte a CLOB e BOOLEAN.

| Membro | Tipo | O que faz |
|---|---|---|
| `t_data_type` | Subtipo | `pls_integer range 1..16` |
| `c_data_type_varchar2`, `c_data_type_clob`, `c_data_type_boolean` | Constantes | Tipos do `t_value` (iguais aos de `APEX_EXEC`) |
| `t_value` | Record | `data_type`, `varchar2_value varchar2(32767)`, `clob_value clob`, `boolean_value boolean`; só um preenchido por vez |
| `GET_VARCHAR2` | Function | Valor como VARCHAR2 (equivale a `V`); **erro se o valor for CLOB** |
| `GET_CLOB` | Function | Valor de item CLOB |
| `GET_BOOLEAN` | Function | Valor de item BOOLEAN |
| `GET_NUMBER` | Function | Converte para NUMBER usando a *format mask* do item |
| `GET_TIMESTAMP` | Function | Converte para TIMESTAMP usando a *format mask* do item |
| `GET_VALUE` | Function | Valor genérico `t_value` |
| `SET_VALUE` (4 assinaturas) | Procedure | Grava VARCHAR2, CLOB, BOOLEAN ou `t_value` |

Fonte: [APEX_SESSION_STATE](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_SESSION_STATE.html), [Data Types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_SESSION_STATE-Data-Types.html), [Global Constants](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_SESSION_STATE-Global-Constants.html)

### APEX_SESSION_STATE.SET_VALUE e GET_*: assinaturas, commit e format mask

```sql
APEX_SESSION_STATE.SET_VALUE (
    p_item   IN VARCHAR2,
    p_value  IN VARCHAR2,          -- ou CLOB, BOOLEAN, t_value
    p_commit IN BOOLEAN DEFAULT TRUE );

APEX_SESSION_STATE.GET_VARCHAR2  ( p_item IN VARCHAR2 ) RETURN VARCHAR2;
APEX_SESSION_STATE.GET_NUMBER    ( p_item IN VARCHAR2 ) RETURN NUMBER;
APEX_SESSION_STATE.GET_TIMESTAMP ( p_item IN VARCHAR2 ) RETURN TIMESTAMP;
APEX_SESSION_STATE.GET_CLOB      ( p_item IN VARCHAR2 ) RETURN CLOB;
APEX_SESSION_STATE.GET_BOOLEAN   ( p_item IN VARCHAR2 ) RETURN BOOLEAN;
APEX_SESSION_STATE.GET_VALUE     ( p_item IN VARCHAR2 ) RETURN T_VALUE;
```

- `p_commit => TRUE` (padrão) faz commit depois de alterar. Não há commit se `FALSE` ou se o valor não mudou. O parâmetro é **ignorado** quando o atributo da app *Session State Changes* está em *End Of Request*.
- `GET_NUMBER`/`GET_TIMESTAMP` usam a *format mask* do item: evita o clássico `to_number(:P1_VALOR)` falhando com máscara `999G999D99`.

```sql
declare
    l_salario number    := apex_session_state.get_number('P10_SALARIO');
    l_inicio  timestamp := apex_session_state.get_timestamp('P10_DT_INICIO');
begin
    apex_session_state.set_value(p_item => 'P10_ATIVO', p_value => true, p_commit => false);
end;
```

Fonte: [SET_VALUE Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_SESSION_STATE.SET_VALUE-Procedure-Signature-1.html), [GET_NUMBER Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_SESSION_STATE.GET_NUMBER-Function.html), [GET_VARCHAR2 Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_SESSION_STATE.GET_VARCHAR2-Function.html)

## APEX_PAGE: URLs com checksum (GET_URL), cache de página e modo da página

| Membro | O que faz |
|---|---|
| `c_ui_type_desktop` | Constante `'DESKTOP'` (**Deprecated**) |
| `GET_URL` | Monta URL `f?p=` com checksum e suporte a modal |
| `GET_CACHE_DATE` | Data/hora em que a página foi cacheada |
| `GET_PAGE_MODE` | *Page Mode* de uma página |
| `IS_READ_ONLY` | `TRUE` se a página atual está renderizada como somente leitura |
| `PURGE_CACHE` | Limpa o cache da página/região |
| `GET_UI_TYPE` | **Deprecated**: tipo de UI da página |
| `IS_DESKTOP_UI` | **Deprecated**: se a página é para desktop |

Fonte: [APEX_PAGE](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_PAGE.html), [Global Constants](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_PAGE-Global-Constants.html)

### APEX_PAGE.GET_URL: assinatura completa, checksum e links para modal dialog

```sql
APEX_PAGE.GET_URL (
    p_application        IN VARCHAR2 DEFAULT NULL,      -- ID ou alias; padrão = app atual
    p_page               IN VARCHAR2 DEFAULT NULL,      -- ID ou alias; padrão = página atual
    p_session            IN NUMBER   DEFAULT apex_application.g_instance,
    p_request            IN VARCHAR2 DEFAULT NULL,
    p_debug              IN VARCHAR2 DEFAULT NULL,      -- padrão = modo de debug atual
    p_clear_cache        IN VARCHAR2 DEFAULT NULL,      -- ex.: 'RP', '10', 'RP,10'
    p_items              IN VARCHAR2 DEFAULT NULL,      -- 'P10_ID,P10_MODO'
    p_values             IN VARCHAR2 DEFAULT NULL,      -- '123,EDIT'
    p_printer_friendly   IN VARCHAR2 DEFAULT NULL,
    p_trace              IN VARCHAR2 DEFAULT NULL,
    p_x01                IN VARCHAR2 DEFAULT NULL,      -- acrescenta &x01=valor
    p_hash               IN VARCHAR2 DEFAULT NULL,      -- acrescenta #valor
    p_triggering_element IN VARCHAR2 DEFAULT 'this',    -- seletor jQuery do elemento que abre o modal
    p_plain_url          IN BOOLEAN  DEFAULT FALSE,
    p_absolute_url       IN BOOLEAN  DEFAULT FALSE )
RETURN VARCHAR2;
```

Comportamento:
- Gera a URL `f?p=` **já com o checksum** (proteção de *Session State Protection*). Exceção: se a app de destino está em **outro workspace**, a URL sai sem checksum.
- Se o destino é um **Modal Dialog**, a função devolve um `javascript:` que abre o diálogo; `p_triggering_element` (ex.: `'#BTN_NOVO'`) indica o elemento ao qual o evento de fechamento é amarrado.
- Chamado **de dentro** de um modal, por padrão o link inclui JS para fechar o modal atual. `p_plain_url => TRUE` gera só a URL, sem esse JS (use quando for um `href` comum ou redirect).
- `p_absolute_url => TRUE` sempre gera URL absoluta (e-mails, notificações); `FALSE` decide sozinho.
- `p_items`/`p_values` são listas separadas por vírgula: um valor contendo vírgula quebra a lista.

```sql
-- Coluna link em Classic Report (coluna com escape desligado ou tipo Link)
select c.nome_completo,
       apex_page.get_url(p_page        => 18,
                         p_clear_cache => '18',
                         p_items       => 'P18_ID_COLABORADOR',
                         p_values      => c.id_colaborador) as link_movimentacao
  from colaborador c
 where c.id_empresa = :G_ID_EMPRESA;

-- Redirect em processo PL/SQL
apex_util.redirect_url(apex_page.get_url(p_page => 1, p_plain_url => true));
```

`APEX_UTIL.PREPARE_URL('f?p=&APP_ID.:1:&APP_SESSION.::::P1_X,P1_Y:a,b')` gera o mesmo resultado; `GET_URL` é mais legível e é a forma recomendada.

Fonte: [GET_URL Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_URL-Function.html)

### APEX_PAGE.PURGE_CACHE e GET_CACHE_DATE: cache de página e de região

```sql
APEX_PAGE.PURGE_CACHE (
    p_application_id       IN NUMBER   DEFAULT apex.g_flow_id,
    p_page_id              IN NUMBER   DEFAULT apex.g_flow_step_id,  -- NULL = todas as páginas
    p_user_name            IN VARCHAR2 DEFAULT NULL,                 -- só entradas desse usuário
    p_current_session_only IN BOOLEAN  DEFAULT FALSE );

APEX_PAGE.GET_CACHE_DATE (
    p_application_id IN NUMBER,
    p_page_id        IN NUMBER ) RETURN DATE;
```

`PURGE_CACHE` sem usuário apaga todas as versões cacheadas da página; com `p_page_id => NULL` limpa a app inteira. `GET_CACHE_DATE` devolve quando a página foi cacheada para o usuário atual (ou para todos, se o cache não é por usuário), ou NULL se não está em cache.

```sql
begin
    apex_page.purge_cache(p_current_session_only => true);
end;
```

Fonte: [PURGE_CACHE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PURGE_CACHE-Procedure.html), [GET_CACHE_DATE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_PAGE.GET_CACHE_DATA-Function.html)

### APEX_PAGE.IS_READ_ONLY e GET_PAGE_MODE: condicionar comportamento ao modo da página

```sql
APEX_PAGE.IS_READ_ONLY RETURN BOOLEAN;
APEX_PAGE.GET_PAGE_MODE ( p_application_id IN NUMBER, p_page_id IN NUMBER ) RETURN VARCHAR2;
```

`IS_READ_ONLY` é útil em processos e condições para não tentar gravar quando a página foi renderizada *Read Only* (atributo *Read Only* da página). `GET_PAGE_MODE` devolve o *Page Mode* de qualquer página (a doc não lista os valores retornados; confira com um teste antes de comparar strings), útil para decidir entre redirect e fechar diálogo. `GET_UI_TYPE` e `IS_DESKTOP_UI` são **deprecated** e serão removidos.

Fonte: [IS_READ_ONLY Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_PAGE-IS_READ_ONLY-Function.html), [GET_PAGE_MODE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_PAGE_MODE-Function.html), [GET_UI_TYPE Function (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_UI_TYPE-Function.html), [IS_DESKTOP_UI Function (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/IS_DESKTOP_UI-Function.html)
## APEX_ERROR: função de tratamento de erros e erros customizados (ADD_ERROR)

`APEX_ERROR` tem duas funções: (1) define a interface (`t_error`, `t_error_result`) e utilitários para a **Error Handling Function** da aplicação ou da página; (2) permite **levantar erros** em validações e processos (`ADD_ERROR`) escolhendo onde eles aparecem.

| Membro | Tipo | O que faz |
|---|---|---|
| `c_inline_with_field` | Constante | `'INLINE_WITH_FIELD'`: erro junto ao campo |
| `c_inline_with_field_and_notif` | Constante | `'INLINE_WITH_FIELD_AND_NOTIFICATION'`: no campo e na notificação |
| `c_inline_in_notification` | Constante | `'INLINE_IN_NOTIFICATION'`: só na notificação da página |
| `c_on_error_page` | Constante | `'ON_ERROR_PAGE'`: página de erro |
| `c_ass_type_page_item`, `c_ass_type_region`, `c_ass_type_region_column` | Constantes | Tipos de associação (`'PAGE_ITEM'`, `'REGION'`, `'REGION_COLUMN'`) |
| `t_error` | Record | Tudo sobre o erro, recebido pela função de tratamento |
| `t_error_result` | Record | O que a função de tratamento devolve (mensagem final, local, item) |
| `ADD_ERROR` (5 assinaturas) | Procedure | Empilha um erro: genérico, de item, por text message, de tabular form |
| `AUTO_SET_ASSOCIATED_ITEM` | Procedure | Descobre o item/coluna afetado pela constraint violada |
| `EXTRACT_CONSTRAINT_NAME` | Function | Extrai o nome da constraint de `ora_sqlerrm` |
| `GET_FIRST_ORA_ERROR_TEXT` | Function | Primeiro texto ORA- da pilha, sem o resto |
| `HAVE_ERRORS_OCCURRED` | Function | `TRUE` se já há erros (inline) no request |
| `INIT_ERROR_RESULT` | Function | Inicializa `t_error_result` a partir de `t_error` (obrigatório usar) |

Fonte: [APEX_ERROR](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_ERROR.html), [Constants and Attributes Used for Result Types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/Constants-and-Attributes-used-for-Result-Types.html)

### APEX_ERROR: display locations (onde o erro aparece)

| Constante | Valor | Efeito |
|---|---|---|
| `apex_error.c_inline_with_field` | `INLINE_WITH_FIELD` | Mensagem junto ao rótulo/campo associado |
| `apex_error.c_inline_with_field_and_notif` | `INLINE_WITH_FIELD_AND_NOTIFICATION` | No campo **e** na área de notificação (`#NOTIFICATION_MESSAGE#`) |
| `apex_error.c_inline_in_notification` | `INLINE_IN_NOTIFICATION` | Só na área de notificação |
| `apex_error.c_on_error_page` | `ON_ERROR_PAGE` | Página de erro separada; usa também `additional_info` |

As duas primeiras exigem um item (`p_page_item_name`) ou uma coluna de tabular form (`p_region_id` + `p_column_alias` + `p_row_num`). O padrão da app para validações declarativas fica em *Application Definition > Error Handling > Default Error Display Location*. Erros **internos** (`is_internal_error`) sempre vão para a página de erro.

Fonte: [Constants and Attributes Used for Result Types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/Constants-and-Attributes-used-for-Result-Types.html), [Editing Application Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-application-attributes.html)

### APEX_ERROR.t_error e t_error_result: campos do record de erro

`t_error` (entrada da função de tratamento):

| Campo | Tipo | Conteúdo |
|---|---|---|
| `message` | varchar2(32767) | Mensagem que será exibida |
| `additional_info` | varchar2(32767) | Detalhe extra, só usado em `ON_ERROR_PAGE` |
| `display_location` | varchar2(40) | Uma das constantes de display location |
| `association_type` | varchar2(40) | `PAGE_ITEM`, `REGION` ou `REGION_COLUMN` |
| `page_item_name` | varchar2(255) | Item associado |
| `region_id` | number | Região de tabular form associada |
| `column_alias` | varchar2(255) | Coluna de tabular form associada |
| `row_num` | pls_integer | Linha do tabular form |
| `apex_error_code` | varchar2(255) | Código da mensagem de sistema, se o erro veio do APEX |
| `is_internal_error` | boolean | `TRUE` para erro crítico do motor (SQL/PLSQL inválido etc.); sempre vai para a página de erro |
| `is_common_runtime_error` | boolean | `TRUE` para erros de autorização, sessão e session state, que normalmente **não** devem ser mascarados |
| `ora_sqlcode` | number | SQLCODE que disparou o erro (NULL se não foi ORA) |
| `ora_sqlerrm` | varchar2(32767) | SQLERRM correspondente |
| `error_backtrace` | varchar2(32767) | `dbms_utility.format_error_backtrace` ou `format_call_stack` |
| `error_statement` | varchar2(32767) | Comando que estava sendo parseado (quando o parse causou o erro) |
| `component` | `apex_application.t_component` | Componente em processamento quando o erro ocorreu |

`t_error_result` (saída): `message`, `additional_info`, `display_location`, `page_item_name`, `column_alias`.

Fonte: [Constants and Attributes Used for Result Types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/Constants-and-Attributes-used-for-Result-Types.html)

### APEX_ERROR: escrever e registrar a Error Handling Function da aplicação

Onde registrar: *Application Definition > Error Handling > Error Handling Function* (nível app) ou o atributo equivalente na página, que **sobrescreve** o da app. Referencie com `#OWNER#.nome_funcao` ou `#OWNER#.pkg.funcao`. Assinatura obrigatória:

```sql
function <nome> ( p_error in apex_error.t_error ) return apex_error.t_error_result
```

Roteiro recomendado pela doc (adaptado):

```sql
create or replace function trata_erro_apex (
    p_error in apex_error.t_error )
    return apex_error.t_error_result
is
    l_result     apex_error.t_error_result;
    l_ref        number;
    l_constraint varchar2(255);
begin
    -- 1. SEMPRE inicializar via INIT_ERROR_RESULT (compatível com mudanças futuras)
    l_result := apex_error.init_error_result(p_error => p_error);

    if p_error.is_internal_error then
        -- 2. Erro interno pode expor SQL/estrutura: mascarar, exceto erros "comuns"
        --    (acesso negado, sessão expirada, session state)
        if not p_error.is_common_runtime_error then
            l_ref := log_erro_autonomo(p_error);           -- sua rotina (autonomous transaction)
            l_result.message := 'Ocorreu um erro inesperado. Informe ao suporte o código '
                                || to_char(l_ref, '999G999G990') || '.';
            l_result.additional_info := null;
        end if;
    else
        -- 3. Violação de constraint: traduzir via tabela de lookup
        if p_error.ora_sqlcode in (-1, -2091, -2290, -2291, -2292) then
            l_constraint := apex_error.extract_constraint_name(p_error => p_error);
            begin
                select mensagem into l_result.message
                  from mensagem_constraint
                 where nome_constraint = l_constraint;
            exception when no_data_found then null;
            end;
        end if;

        -- 4. raise_application_error(-20xxx, ...) de trigger/package:
        --    mostrar só o primeiro texto, sem a pilha ORA-06512 etc.
        if p_error.ora_sqlcode is not null and l_result.message = p_error.message then
            l_result.message := apex_error.get_first_ora_error_text(p_error => p_error);
        end if;

        -- 5. Sem item associado? Tentar adivinhar pela constraint/coluna
        if l_result.page_item_name is null and l_result.column_alias is null then
            apex_error.auto_set_associated_item(p_error_result => l_result,
                                                p_error        => p_error);
        end if;
    end if;
    return l_result;
end trata_erro_apex;
```

Dica da doc: para só deixar uma mensagem ORA mais amigável, nem precisa de código: crie um *Text Message* com o nome `APEX.ERROR.ORA-<número>` (ex.: `APEX.ERROR.ORA-00001`).

Fonte: [Example of an Error Handling Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/Example-of-an-Error-Handling-Function.html), [Editing Application Attributes](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-application-attributes.html)

### APEX_ERROR.INIT_ERROR_RESULT, GET_FIRST_ORA_ERROR_TEXT, EXTRACT_CONSTRAINT_NAME e AUTO_SET_ASSOCIATED_ITEM

```sql
APEX_ERROR.INIT_ERROR_RESULT ( p_error IN t_error ) RETURN t_error_result;

APEX_ERROR.GET_FIRST_ORA_ERROR_TEXT (
    p_error            IN t_error,
    p_include_error_no IN BOOLEAN DEFAULT FALSE )   -- TRUE inclui "ORA-xxxxx:"
RETURN VARCHAR2;                                   -- NULL se ora_sqlerrm vazio

APEX_ERROR.EXTRACT_CONSTRAINT_NAME (
    p_error          IN t_error,
    p_include_schema IN BOOLEAN DEFAULT FALSE )     -- TRUE: 'HR.DEMO_PRODUCT_INFO_PK'
RETURN VARCHAR2;

APEX_ERROR.AUTO_SET_ASSOCIATED_ITEM (
    p_error_result IN OUT NOCOPY t_error_result,
    p_error        IN            t_error );
```

- `INIT_ERROR_RESULT` **deve** ser usada (em vez de montar o record à mão) para continuar compatível com campos novos.
- `EXTRACT_CONSTRAINT_NAME` procura o padrão `schema.constraint` em `ora_sqlerrm`.
- `AUTO_SET_ASSOCIATED_ITEM`: acha a constraint (`schema.constraint`), aceita só tipos **P, U, R e C**; para C analisa a expressão e pega as colunas usadas; associa o **primeiro item visível** (ou coluna de tabular form) baseado nessas colunas e, se achar, muda `display_location` para `c_inline_with_field_and_notif`.

Fonte: [INIT_ERROR_RESULT Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/INIT_ERROR_RESULT-Function.html), [GET_FIRST_ORA_ERROR_TEXT Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_FIRST_ORA_ERROR_TEXT-Function.html), [EXTRACT_CONSTRAINT_NAME Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/EXTRACT_CONSTRAINT_NAME-Function.html), [AUTO_SET_ASSOCIATED_ITEM Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/AUTO_SET_ASSOCIATED_ITEM-Procedure.html)

### APEX_ERROR.ADD_ERROR: as 5 assinaturas (notificação, item, text message, tabular form)

Empilha um erro durante validações ou processos; vários erros podem ser adicionados no mesmo request.

```sql
-- 1) Notificação ou página de erro
APEX_ERROR.ADD_ERROR (
    p_message          IN VARCHAR2,
    p_additional_info  IN VARCHAR2 DEFAULT NULL,
    p_display_location IN VARCHAR2,              -- c_inline_in_notification | c_on_error_page
    p_ignore_ora_error IN BOOLEAN  DEFAULT FALSE );

-- 2) Associado a um item da página
APEX_ERROR.ADD_ERROR (
    p_message          IN VARCHAR2,
    p_additional_info  IN VARCHAR2 DEFAULT NULL,
    p_display_location IN VARCHAR2,              -- c_inline_with_field | c_inline_with_field_and_notif
    p_page_item_name   IN VARCHAR2,
    p_ignore_ora_error IN BOOLEAN  DEFAULT FALSE );

-- 3) Texto vindo de Shared Components > Text Messages (%0..%9)
APEX_ERROR.ADD_ERROR (
    p_error_code          IN VARCHAR2,           -- nome do text message
    p0 .. p9              IN VARCHAR2 DEFAULT NULL,
    p_escape_placeholders IN BOOLEAN  DEFAULT TRUE,   -- escapa p0..p9 com htf.escape_sc
    p_additional_info     IN VARCHAR2 DEFAULT NULL,
    p_display_location    IN VARCHAR2,
    p_page_item_name      IN VARCHAR2,
    p_ignore_ora_error    IN BOOLEAN  DEFAULT FALSE );

-- 4) Tabular form (mensagem literal)  e  5) tabular form com text message
APEX_ERROR.ADD_ERROR (
    p_message          IN VARCHAR2,              -- ou p_error_code + p0..p9 + p_escape_placeholders
    p_additional_info  IN VARCHAR2 DEFAULT NULL,
    p_display_location IN VARCHAR2,
    p_region_id        IN NUMBER,                -- ID da região (APEX_APPLICATION_PAGE_REGIONS)
    p_column_alias     IN VARCHAR2 DEFAULT NULL,
    p_row_num          IN NUMBER,
    p_ignore_ora_error IN BOOLEAN  DEFAULT FALSE );
```

- `p_ignore_ora_error => TRUE`, chamado dentro de um handler de exceção, **remove** o erro ORA original da pilha (senão aparecem os dois).
- `p_escape_placeholders => TRUE` (padrão) protege contra XSS nos valores `p0..p9`.

```sql
-- Validação "PL/SQL Function Body (returning Boolean)" seria o caminho declarativo;
-- em processo, use ADD_ERROR:
if :P14_EMAIL is not null and not regexp_like(:P14_EMAIL, '^[^@]+@[^@]+$') then
    apex_error.add_error(
        p_message          => 'Informe um e-mail válido.',
        p_display_location => apex_error.c_inline_with_field_and_notif,
        p_page_item_name   => 'P14_EMAIL');
end if;

-- Com text message traduzível
apex_error.add_error(
    p_error_code       => 'COLABORADOR_JA_EXISTE',
    p0                 => :P14_EMAIL,
    p_display_location => apex_error.c_inline_with_field_and_notif,
    p_page_item_name   => 'P14_EMAIL');
```

Fonte: [ADD_ERROR Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_ERROR-Procedure-Signature-1.html), [Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_ERROR-Procedure-Signature-2.html), [Signature 3](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_ERROR-Procedure-Signature-3.html), [Signature 4](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_ERROR-Procedure-Signature-4.html), [Signature 5](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_ERROR-Procedure-Signature-5.html)

### APEX_ERROR.ADD_ERROR não mostra nada (erro ignorado depois da última validação/processo)

**Sintoma:** o processo chama `apex_error.add_error(... c_inline_in_notification ...)`, mas a página segue normalmente e nenhuma mensagem aparece.
**Causa:** `ADD_ERROR` precisa ser chamado **antes** de o APEX executar a última validação ou processo. Depois disso, erros com display location diferente de `c_on_error_page` são ignorados.
**Correção:** chame em uma validação ou num processo que não seja o último do ponto de processamento; ou use `c_on_error_page`; ou, num processo, levante a exceção (`raise_application_error`) para interromper.
**Prevenção:** depois de empilhar erros, teste `apex_error.have_errors_occurred` antes de executar DML dependente.

Fonte: [ADD_ERROR Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_ERROR-Procedure-Signature-1.html)

### APEX_ERROR.HAVE_ERRORS_OCCURRED: não gravar se alguma validação falhou

```sql
APEX_ERROR.HAVE_ERRORS_OCCURRED RETURN BOOLEAN;

if not apex_error.have_errors_occurred then
    insert into ... ;
end if;
```

Retorna `TRUE` quando já houve erros (inline) no request. Útil em processos que chamam `ADD_ERROR` em laço e só devem gravar se tudo passou.

Fonte: [HAVE_ERRORS_OCCURRED Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_ERROR.HAVE_ERRORS_OCCURRED-Function.html)

## APEX_DEBUG: instrumentar PL/SQL e gerenciar o log de debug

`APEX_DEBUG` grava mensagens no log de debug do APEX (visível em *View Debug* no Builder ou na view `APEX_DEBUG_MESSAGES`), serve para código de páginas e para packages do banco. O antigo nome `APEX_DEBUG_MESSAGE` (até 4.2) ainda funciona por compatibilidade, mas use `APEX_DEBUG`.

| Membro | O que faz |
|---|---|
| `t_log_level` + constantes `c_log_level_*` | Níveis 1 a 9 |
| `ENABLE` | Liga o debug no request (nível padrão 4/info) |
| `DISABLE` | Desliga o debug |
| `ERROR` | Loga nível 1; **sempre loga**, mesmo com debug desligado |
| `WARN` | Loga nível 2 |
| `INFO` | Loga nível 4 |
| `ENTER` | Loga nível 5 com nome da rotina e até 10 pares parâmetro/valor |
| `TRACE` | Loga nível 6 |
| `MESSAGE` | Versão geral: nível configurável, até 20 placeholders, `p_force` |
| `LOG_LONG_MESSAGE` | Mensagens até 32.767 bytes, quebradas em blocos de 4.000 |
| `LOG_MESSAGE` | **Deprecated**: use ERROR/WARN/INFO/MESSAGE/ENTER/TRACE |
| `LOG_PAGE_SESSION_STATE` | Loga os valores dos itens da sessão (de uma página) |
| `LOG_DBMS_OUTPUT` | Copia o buffer `dbms_output` para o log |
| `ENABLE_DBMS_OUTPUT` / `DISABLE_DBMS_OUTPUT` | Espelha (ou para de espelhar) o debug em `dbms_output` |
| `GET_LAST_MESSAGE_ID` | ID da última mensagem gerada na sessão |
| `GET_PAGE_VIEW_ID` | ID do page view atual (único por request) |
| `TOCHAR` | Converte BOOLEAN em VARCHAR2 para logar |
| `REMOVE_DEBUG_BY_AGE` | Apaga mensagens da app mais antigas que N dias |
| `REMOVE_DEBUG_BY_APP` | Apaga todas as mensagens da app |
| `REMOVE_DEBUG_BY_VIEW` | Apaga as mensagens de um page view |
| `REMOVE_SESSION_MESSAGES` | Apaga as mensagens de uma sessão (padrão: atual) |

Fonte: [APEX_DEBUG](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DEBUG.html)

### APEX_DEBUG: níveis de log (c_log_level_error .. c_log_level_engine_trace)

| Constante | Valor | Uso |
|---|---|---|
| `c_log_level_error` | 1 | Erro crítico |
| `c_log_level_warn` | 2 | Erro menos crítico |
| `c_log_level_info` | 4 | Padrão quando o debug está ligado |
| `c_log_level_app_enter` | 5 | App: entrada de procedures/functions |
| `c_log_level_app_trace` | 6 | App: demais mensagens internas |
| `c_log_level_engine_enter` | 8 | Motor APEX: entradas |
| `c_log_level_engine_trace` | 9 | Motor APEX: demais mensagens |

Ligar num nível registra esse nível **e todos os menores**. Ex.: nível 2 registra 1 e 2.

Fonte: [Constants](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DEBUG-Constants.html), [ENABLE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DEBUG-ENABLE-Procedure.html)

### APEX_DEBUG.ERROR, WARN, INFO, TRACE e MESSAGE: assinatura e placeholders %s

```sql
APEX_DEBUG.INFO (                       -- ERROR, WARN e TRACE têm a mesma forma
    p_message       IN VARCHAR2,
    p0 .. p9        IN VARCHAR2     DEFAULT NULL,
    p_max_length    IN PLS_INTEGER  DEFAULT 1000 );

APEX_DEBUG.MESSAGE (
    p_message       IN VARCHAR2,
    p0 .. p19       IN VARCHAR2     DEFAULT NULL,
    p_max_length    IN PLS_INTEGER  DEFAULT 1000,
    p_level         IN t_log_level  DEFAULT c_log_level_info,
    p_force         IN BOOLEAN      DEFAULT FALSE );
```

- Placeholders estilo `utl_lms.format_message`/`sprintf`: cada `%s` recebe o próximo `pN`; `%<n>` usa `p<n>` explicitamente; `%%` é um `%` literal.
- Cada valor é truncado em `p_max_length` e ganha `~` no fim quando foi cortado.
- `ERROR` grava **sempre**, mesmo sem debug ligado: ideal em handlers de exceção.
- `MESSAGE ... p_force => TRUE` grava mesmo sem debug ou com nível acima do configurado.
- Para BOOLEAN use `apex_debug.tochar(l_flag)`.

```sql
apex_debug.info('Colaborador %s movido para o cargo %s', :P18_ID_COLABORADOR, :P18_ID_CARGO);
apex_debug.warn('Restrição suave %s violada: %s', 4711, sqlerrm);
apex_debug.error('Falha ao gravar movimentação: %s', sqlerrm);
apex_debug.message('soma %s + %s = %s', 3, 5, 'oito');
apex_debug.info('Ativo? %s', apex_debug.tochar(l_ativo));
```

Fonte: [INFO Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/INFO-Procedure.html), [ERROR Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ERROR-Procedure.html), [WARN Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/WARN-Procedure.html), [TRACE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/TRACE-Procedure.html), [MESSAGE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/MESSAGE-Procedure.html), [TOCHAR Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/TOCHAR-Function.html)

### APEX_DEBUG.ENTER: logar entrada de procedure com parâmetros

```sql
APEX_DEBUG.ENTER (
    p_routine_name      IN VARCHAR2,
    p_name01 / p_value01 .. p_name10 / p_value10  IN VARCHAR2 DEFAULT NULL,
    p_value_max_length  IN PLS_INTEGER  DEFAULT 1000 );
```

Loga em `c_log_level_app_enter` (5). Valores maiores que `p_value_max_length` são cortados e marcados com `~`.

```sql
procedure registra_movimentacao(p_id_colaborador in number, p_id_cargo in number) is
begin
    apex_debug.enter('registra_movimentacao',
                     'p_id_colaborador', p_id_colaborador,
                     'p_id_cargo',       p_id_cargo);
    ...
end;
```

Fonte: [ENTER Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ENTER-Procedure.html)

### APEX_DEBUG.ENABLE, DISABLE e ENABLE_DBMS_OUTPUT: debug fora do navegador (SQLcl, jobs)

```sql
APEX_DEBUG.ENABLE ( p_level IN t_log_level DEFAULT c_log_level_info );
APEX_DEBUG.DISABLE;
APEX_DEBUG.ENABLE_DBMS_OUTPUT ( p_prefix IN VARCHAR2 DEFAULT '# APEX|' );
APEX_DEBUG.DISABLE_DBMS_OUTPUT;
```

- `ENABLE` só precisa ser chamado uma vez por page view/submit.
- `ENABLE_DBMS_OUTPUT` passa a escrever o debug também em `dbms_output` (formato `<prefixo><nível>|<mensagem>`, ex. `# APEX|INF|texto`). Se o debug estiver desligado, ele o liga em `c_log_level_warn`: para ver INFO, chame também `ENABLE(c_log_level_info)`.
- Para debug persistente na sessão de um usuário use `APEX_SESSION.SET_DEBUG`.

```sql
set serveroutput on size unlimited
begin
    apex_debug.enable_dbms_output;
    apex_debug.enable(p_level => apex_debug.c_log_level_info);
    apex_debug.info('aparece no dbms_output');
end;
/
```

Fonte: [ENABLE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DEBUG-ENABLE-Procedure.html), [DISABLE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/DISABLE-Procedure.html), [ENABLE_DBMS_OUTPUT Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ENABLE_DBMS_OUTPUT-Procedure.html), [DISABLE_DBMS_OUTPUT Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/DISABLE_DBMS_OUTPUT-Procedure.html)

### APEX_DEBUG.LOG_LONG_MESSAGE, LOG_PAGE_SESSION_STATE e LOG_DBMS_OUTPUT

```sql
APEX_DEBUG.LOG_LONG_MESSAGE (
    p_message   IN VARCHAR2     DEFAULT NULL,      -- até 32.767 bytes
    p_enabled   IN BOOLEAN      DEFAULT FALSE,     -- TRUE = loga mesmo sem debug
    p_level     IN t_log_level  DEFAULT c_log_level_app_trace );

APEX_DEBUG.LOG_PAGE_SESSION_STATE (
    p_page_id   IN NUMBER       DEFAULT NULL,      -- NULL = página atual
    p_enabled   IN BOOLEAN      DEFAULT FALSE,
    p_level     IN t_log_level  DEFAULT c_log_level_app_trace );

APEX_DEBUG.LOG_DBMS_OUTPUT;
```

- Cada mensagem de debug tem limite de 4.000 caracteres; `LOG_LONG_MESSAGE` divide em blocos. Prefira as APIs curtas quando possível.
- `LOG_PAGE_SESSION_STATE` despeja os valores dos itens: ótimo para investigar "o item estava nulo no processo?". Cuidado com dados sensíveis no log.
- `LOG_DBMS_OUTPUT` copia `dbms_output.get_lines` para o log; exige `dbms_output.enable` antes.

Fonte: [LOG_LONG_MESSAGE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/LOG_LONG_MESSAGE-Procedure.html), [LOG_PAGE_SESSION_STATE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/LOG_PAGE_SESSION_STATE-Procedure.html), [LOG_DBMS_OUTPUT Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/LOG_DBMS_OUTPUT-Procedure.html), [LOG_MESSAGE Procedure (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/LOG_MESSAGE-Procedure-Deprecated.html)

### APEX_DEBUG: consultar e limpar o log (APEX_DEBUG_MESSAGES, REMOVE_DEBUG_*)

```sql
APEX_DEBUG.GET_PAGE_VIEW_ID    RETURN NUMBER;   -- NULL até a 1ª mensagem
APEX_DEBUG.GET_LAST_MESSAGE_ID RETURN NUMBER;   -- NULL até a 1ª mensagem
APEX_DEBUG.REMOVE_DEBUG_BY_AGE  ( p_application_id IN NUMBER, p_older_than_days IN NUMBER );
APEX_DEBUG.REMOVE_DEBUG_BY_APP  ( p_application_id IN NUMBER );
APEX_DEBUG.REMOVE_DEBUG_BY_VIEW ( p_application_id IN NUMBER, p_view_id IN NUMBER );
APEX_DEBUG.REMOVE_SESSION_MESSAGES ( p_session IN NUMBER DEFAULT NULL );  -- NULL = sessão atual
```

O page view ID identifica cada request do navegador (ou sessão de banco avulsa) e é o filtro natural para ler o log em `APEX_DEBUG_MESSAGES`. Padrão útil: guardar `apex_debug.get_page_view_id` na tabela de log de erros da Error Handling Function, para ligar o erro ao trecho de debug.

Fonte: [GET_PAGE_VIEW_ID Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_PAGE_VIEW_ID-Function.html), [GET_LAST_MESSAGE_ID Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_LAST_MESSAGE_ID-Function.html), [REMOVE_DEBUG_BY_AGE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/REMOVE_DEBUG_BY_AGE-Procedure.html), [REMOVE_DEBUG_BY_APP Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/REMOVE_DEBUG_BY_APP-Procedure.html), [REMOVE_DEBUG_BY_VIEW Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/REMOVE_DEBUG_BY_VIEW-Procedure.html), [REMOVE_SESSION_MESSAGES Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/REMOVE_SESSION_MESSAGES-Procedure.html)

## APEX_ESCAPE: escapar strings para HTML, atributo, JavaScript, JSON, CSV, LDAP e regex

Regra geral: **escape no ponto de saída, conforme o contexto**. Texto em corpo HTML → `HTML`; dentro de string JS → `JS_LITERAL`; dentro de JSON montado à mão → `JSON`; em regex → `REGEXP`; em CSV → `CSV`.

| Membro | O que faz |
|---|---|
| `c_ldap_dn_reserved_chars` | `'"+,;<=>\'` |
| `c_ldap_search_reserved_chars` | `'*()\/'` |
| `c_html_allowlist_tags` | Tags permitidas por padrão em `HTML_ALLOWLIST`: h1–h4, p, b, strong, i, ul, ol, li, br, hr |
| `HTML` / `HTML_CLOB` | Escapa `& " < > ' /` (modo Extended) para corpo HTML |
| `HTML_TRUNC` (VARCHAR2 e CLOB) | Escapa e limita aos primeiros `p_length` bytes (padrão 4000) |
| `HTML_ATTRIBUTE` / `HTML_ATTRIBUTE_CLOB` | Hex-escapa tudo exceto alfanuméricos e `, . - _` (atributos HTML) |
| `HTML_ALLOWLIST` / `HTML_ALLOWLIST_CLOB` | Escapa tudo menos as tags permitidas |
| `JS_LITERAL` / `JS_LITERAL_CLOB` | Escapa (e põe aspas) uma string JavaScript |
| `JSON` / `JSON_CLOB` | Escapa caracteres especiais para valor JSON |
| `CSS_SELECTOR` | Escapa metacaracteres de seletor CSS/jQuery |
| `CSV` (VARCHAR2 e CLOB) | Escapa um valor CSV |
| `SET_CSV_PARAMETERS` | Define delimitador, separador e escape de fórmulas |
| `GET_CSV_ENCLOSED_BY` / `GET_CSV_SEPARATED_BY` | Lê os parâmetros CSV atuais |
| `LDAP_DN` | Escapa DN LDAP (RFC 4514) |
| `LDAP_SEARCH_FILTER` | Escapa filtro de busca LDAP (RFC 4515) |
| `REGEXP` | Escapa metacaracteres de expressão regular |
| `STRIPHTML` (VARCHAR2 e CLOB) | Remove as tags e devolve texto puro |
| `NOOP` (VARCHAR2 e CLOB) | Devolve inalterado; documenta a intenção de não escapar |
| `SET_HTML_ESCAPING_MODE` | `'B'` (Basic, como `htf.escape_sc`) ou `'E'` (Extended) |

Fonte: [APEX_ESCAPE](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_ESCAPE.html), [Constants](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_ESCAPE-Constants.html)

### APEX_ESCAPE.HTML e HTML_CLOB: escapar texto em corpo HTML (modo Basic x Extended)

```sql
APEX_ESCAPE.HTML      ( p_string IN VARCHAR2 ) RETURN VARCHAR2 deterministic;
APEX_ESCAPE.HTML_CLOB ( p_string IN CLOB )     RETURN CLOB deterministic;
APEX_ESCAPE.SET_HTML_ESCAPING_MODE ( p_mode IN VARCHAR2 );   -- 'B' ou 'E'
```

| Caractere | Extended (padrão) | Basic |
|---|---|---|
| `&` | `&amp;` | `&amp;` |
| `"` | `&quot;` | `&quot;` |
| `<` | `&lt;` | `&lt;` |
| `>` | `&gt;` | `&gt;` |
| `'` | `&#x27;` | não escapa |
| `/` | `&#x2F;` | não escapa |

O modo vem do atributo de segurança da app *HTML Escaping Mode* (padrão Extended) ou de `SET_HTML_ESCAPING_MODE`. `HTML_CLOB` ainda pode escapar caracteres Unicode como `&#xHHHH;` quando o charset do banco não é UTF-8 ou o header `REQUEST_IANA_CHARSET` não é UTF-8.

```sql
-- Região PL/SQL Dynamic Content
for r in (select nome, cargo from vw_colaborador where id_empresa = :G_ID_EMPRESA) loop
    sys.htp.p('<li>' || apex_escape.html(r.nome) || ' · ' || apex_escape.html(r.cargo) || '</li>');
end loop;
```

Fonte: [HTML Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/HTML-Function.html), [HTML_CLOB Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/HTML_CLOB-Function.html), [SET_HTML_ESCAPING_MODE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_HTML_ESCAPING_MODE-Procedure.html)

### APEX_ESCAPE.HTML_ATTRIBUTE: atributos HTML (e por que preferir GET_HTML_ATTR)

```sql
APEX_ESCAPE.HTML_ATTRIBUTE      ( p_string IN VARCHAR2 ) RETURN VARCHAR2 deterministic;
APEX_ESCAPE.HTML_ATTRIBUTE_CLOB ( p_string IN CLOB )     RETURN CLOB deterministic;
```

Hex-escapa tudo que não for alfanumérico ou `,` `.` `-` `_`. Avisos da doc:
- Para atributos de **texto legível** (`title`, `placeholder`, `aria-label`, `alt`, `summary`), essa função pode expor código HTML ao usuário ou a leitores de tela. **Não** use nesses atributos.
- A Oracle recomenda `GET_HTML_ATTR` (escolhe o algoritmo correto por atributo) em vez de `HTML_ATTRIBUTE`.

```sql
sys.htp.p('<span class="' || apex_escape.html_attribute(l_css) || '">'
          || apex_escape.html(l_titulo) || '</span>');
```

Fonte: [HTML_ATTRIBUTE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/HTML_ATTRIBUTE-Function.html), [HTML_ATTRIBUTE_CLOB Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/HTML_ATTRIBUTE_CLOB-Function.html)

### APEX_ESCAPE.HTML_ALLOWLIST, HTML_TRUNC e STRIPHTML: HTML do usuário com segurança

```sql
APEX_ESCAPE.HTML_ALLOWLIST (
    p_html           IN VARCHAR2,
    p_allowlist_tags IN VARCHAR2 DEFAULT c_html_allowlist_tags )   -- lista separada por vírgula
RETURN VARCHAR2 deterministic;                                      -- HTML_ALLOWLIST_CLOB: CLOB

APEX_ESCAPE.HTML_TRUNC ( p_string IN VARCHAR2 | CLOB, p_length IN NUMBER DEFAULT 4000 ) RETURN VARCHAR2;

APEX_ESCAPE.STRIPHTML ( p_string IN VARCHAR2 | CLOB ) RETURN VARCHAR2 | CLOB deterministic;
```

- `HTML_ALLOWLIST` mantém só as tags da lista (padrão: h1–h4, p, b, strong, i, ul, ol, li, br, hr) e escapa o resto: `'<h1>Olá<script>…</script></h1>'` mantém o `<h1>` e neutraliza o `<script>`. Bom para comunicados com marcação simples.
- `HTML_TRUNC` corta em **bytes** (Unicode pode usar até 4 bytes por caractere) e escapa: ideal para exibir o começo de um CLOB grande.
- `STRIPHTML` remove as tags e devolve o texto, mas **preserva o conteúdo** de blocos como script/CSS (só tira as tags). Não serve como sanitização para exibição em HTML; para isso escape.

Fonte: [HTML_ALLOWLIST Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/HTML_ALLOWLIST-Function.html), [HTML_ALLOWLIST_CLOB Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/HTML_ALLOWLIST_CLOB-Function.html), [HTML_TRUNC Function Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/HTML_TRUNC-Function.html), [HTML_TRUNC Function Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/HTML_TRUNC-Function-Signature-2.html), [STRIPHTML Function Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/STRIPHTML-Function-Signature-1.html), [STRIPHTML Function Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/STRIPHTML-Function-Signature-2.html)

### APEX_ESCAPE.JS_LITERAL, JSON e CSS_SELECTOR: dados em JavaScript, JSON e seletores

```sql
APEX_ESCAPE.JS_LITERAL (
    p_string IN VARCHAR2,
    p_quote  IN VARCHAR2 DEFAULT '''' )   -- NULL = sem aspas; senão ' ou "
RETURN VARCHAR2;
APEX_ESCAPE.JS_LITERAL_CLOB ( p_string IN CLOB ) RETURN CLOB;

APEX_ESCAPE.JSON      ( p_string IN VARCHAR2 ) RETURN VARCHAR2;
APEX_ESCAPE.JSON_CLOB ( p_string IN CLOB )     RETURN CLOB;

APEX_ESCAPE.CSS_SELECTOR ( p_string IN VARCHAR2 ) RETURN VARCHAR2 deterministic;
```

- `JS_LITERAL` troca caracteres não imunes por `\xHH`/`\uHHHH`. Imunes: letras, dígitos, `,` `.` `_`. Com `p_quote` preenchido, ASCII imprimível não é escapado, exceto `& < > " ' \` / \ %`. O resultado é seguro dentro de `<script>` e em `javascript:`.
- `JSON` escapa para valor JSON (`O'Brien` vira `O'Brien`). Para gerar JSON inteiro prefira `APEX_JSON`.
- `CSS_SELECTOR` escapa metacaracteres jQuery (ex.: `@` em IDs). Combine com `JS_LITERAL` quando for para dentro de código JS.

```sql
apex_javascript.add_onload_code(
    '$("#' || apex_escape.js_literal(apex_escape.css_selector(l_id), null) || '").hide();');

sys.htp.p('<script>apex.message.showPageSuccess('
          || apex_escape.js_literal(l_msg) || ');</script>');
```

Fonte: [JS_LITERAL Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/JS_LITERAL-Function.html), [JS_LITERAL_CLOB Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/JS_LITERAL_CLOB-Function.html), [JSON Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/JSON-Function.html), [JSON_CLOB Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/JSON_CLOB-Function.html), [CSS_SELECTOR Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CSS_SELECTOR-Function.html)

### APEX_ESCAPE.CSV e SET_CSV_PARAMETERS: exportar CSV sem quebrar e sem injeção de fórmula

```sql
APEX_ESCAPE.CSV (
    p_string        IN VARCHAR2 | CLOB,
    p_quote         IN BOOLEAN  DEFAULT TRUE,     -- envolve com p_enclosed_by se houver especiais
    p_strip_html    IN BOOLEAN  DEFAULT FALSE )   -- TRUE remove tags HTML
RETURN VARCHAR2 | CLOB;

APEX_ESCAPE.SET_CSV_PARAMETERS (
    p_enclosed_by     IN VARCHAR2 DEFAULT NULL,   -- NULL = aspas duplas
    p_separated_by    IN VARCHAR2 DEFAULT NULL,   -- NULL = ';' se o separador decimal NLS for ',', senão ','
    p_escape_formulas IN BOOLEAN  DEFAULT NULL ); -- padrão efetivo TRUE (parâmetro de instância CSV_DOWNLOAD_ESCAPE_FORMULAS)
APEX_ESCAPE.GET_CSV_ENCLOSED_BY  RETURN VARCHAR2;
APEX_ESCAPE.GET_CSV_SEPARATED_BY RETURN VARCHAR2;
```

Com `p_escape_formulas` ligado, células que começam com `=`, `@`, `+` ou `-` ganham um espaço na frente (sinais só quando não fazem parte de número), evitando *CSV/formula injection* no Excel. Em pt-BR (decimal `,`), o separador automático é `;`.

```sql
apex_escape.set_csv_parameters(p_enclosed_by => '"', p_separated_by => ';');
for r in (select id_colaborador, nome_completo as nome from colaborador where id_empresa = :G_ID_EMPRESA) loop
    sys.htp.p(r.id_colaborador || ';' || apex_escape.csv(r.nome));
end loop;
```

Fonte: [CSV Function Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CSV-Function-Signature-1.html), [CSV Function Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CSV-Function-Signature-2.html), [SET_CSV_PARAMETERS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_CSV_PARAMETERS-Procedure.html), [GET_CSV_ENCLOSED_BY Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_CSV_ENCLOSED_BY-Function.html), [GET_CSV_SEPARATED_BY Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_CSV_SEPARATED_BY-Function.html)

### APEX_ESCAPE.REGEXP, LDAP_DN, LDAP_SEARCH_FILTER e NOOP

```sql
APEX_ESCAPE.REGEXP ( p_string IN VARCHAR2 );       -- escapa \.^$*+-?()[]{| com barra
APEX_ESCAPE.LDAP_DN (
    p_string            IN VARCHAR2,
    p_reserved_chars    IN VARCHAR2 DEFAULT c_ldap_dn_reserved_chars,
    p_escaped_non_ascii IN BOOLEAN  DEFAULT TRUE ) RETURN VARCHAR2;
APEX_ESCAPE.LDAP_SEARCH_FILTER (
    p_string            IN VARCHAR2,
    p_reserved_chars    IN VARCHAR2 DEFAULT c_ldap_search_reserved_chars,
    p_escape_non_ascii  IN BOOLEAN  DEFAULT TRUE ) RETURN VARCHAR2;
APEX_ESCAPE.NOOP ( p_string IN VARCHAR2 | CLOB ) RETURN VARCHAR2 | CLOB deterministic;
```

- `REGEXP`: use sempre que entrada do usuário entra num padrão (`regexp_like(lista, '(^|,)' || apex_escape.regexp(:P1_NOME) || '($|,)')`).
- `LDAP_DN` (RFC 4514) escapa reservados com `\`, não imprimíveis e >127 como `\xx`, e espaço no início/fim e `#` inicial. `LDAP_SEARCH_FILTER` (RFC 4515) escapa como `\xx`. O escape de não-ASCII pode dar erro em servidores LDAP antigos e no Microsoft AD: desligue se for o caso.
- `NOOP` não muda nada; serve para silenciar detectores de injeção e documentar que não escapar foi intencional.

Fonte: [REGEXP Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/REGEXP-Function.html), [LDAP_DN Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/LDAP_DN-Function.html), [LDAP_SEARCH_FILTER Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/LDAP_SEARCH_FILTER-Function.html), [NOOP Function Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/NOOP-Function-Signature-1.html), [NOOP Function Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/NOOP-Function-Signature-2.html)
## APEX_UTIL: utilitários gerais (session state, usuários APEX, arquivos, cache, preferências, URLs)

`APEX_UTIL` é o "canivete suíço" do APEX: session state, contas do repositório nativo (*Oracle APEX Accounts*), download de arquivos, cache de páginas/regiões, preferências de usuário, impressão, acessibilidade e conversão de LOBs. Muitas funções antigas foram substituídas por packages específicos (`APEX_SESSION_STATE`, `APEX_PAGE`, `APEX_IR`, `APEX_STRING`, `APEX_APPLICATION_ADMIN`, `APEX_AUTHORIZATION`): estão marcadas como **Deprecated** abaixo.

Regra importante: **todas** as rotinas de usuários/grupos/senhas operam no repositório nativo de contas APEX e só fazem sentido em apps com autenticação *Oracle APEX Accounts*. As que alteram contas exigem que o usuário corrente seja **administrador do workspace** (e, dentro de uma app, que a app permita modificar o repositório do workspace).

Fonte: [APEX_UTIL](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_UTIL.html)

### APEX_UTIL: tabela de todos os membros por tema

**Session state e itens**

| Membro | O que faz |
|---|---|
| `GET_SESSION_STATE` (atalho `V`) | Valor de um item (VARCHAR2) |
| `GET_NUMERIC_SESSION_STATE` (atalho `NV`) | Valor numérico de um item |
| `SET_SESSION_STATE` | Grava valor de item (com `p_commit`) |
| `FETCH_APP_ITEM` | Valor de um *application item* de outra app/sessão |
| `CLEAR_APP_CACHE` | Limpa session state de uma app na sessão atual |
| `CLEAR_PAGE_CACHE` | Limpa session state de uma página |
| `CLEAR_USER_CACHE` | Limpa session state e preferências de sistema da sessão do usuário |
| `SAVEKEY_NUM` / `KEYVAL_NUM` | Guarda/lê um número em variável de package |
| `SAVEKEY_VC2` / `KEYVAL_VC2` | Guarda/lê um VARCHAR2 em variável de package |

**Sessão: idioma, território, fuso, duração**

| Membro | O que faz |
|---|---|
| `GET_SESSION_LANG` / `SET_SESSION_LANG` | Idioma da sessão (código IANA: `en`, `pt-br`…) |
| `GET_SESSION_TERRITORY` / `SET_SESSION_TERRITORY` | Território Oracle (`AMERICA`, `BRAZIL`…) |
| `GET_SESSION_TIME_ZONE` / `SET_SESSION_TIME_ZONE` | Fuso da sessão (`-03:00`) |
| `SET_SESSION_LIFETIME_SECONDS` | Sobrescreve *Maximum Session Length in Seconds* |
| `SET_SESSION_MAX_IDLE_SECONDS` | Sobrescreve *Maximum Session Idle Time in Seconds* |
| `SET_EDITION` / `GET_EDITION` | Edition (EBR) usada no SQL do page view |
| `SET_PARSING_SCHEMA_FOR_REQUEST` | Troca o parsing schema do request (só no *Initialization PL/SQL Code*) |
| `SET_WORKSPACE` | Define o workspace atual (código fora de app, jobs) |
| `SET_SECURITY_GROUP_ID` | Define o workspace pelo ID (com `FIND_SECURITY_GROUP_ID`) |
| `FIND_SECURITY_GROUP_ID` | ID numérico de um workspace pelo nome |
| `FIND_WORKSPACE` | Nome do workspace pelo ID |
| `GET_APEX_OWNER` | Schema que contém o motor APEX |
| `GET_DEFAULT_SCHEMA` | Schema padrão do usuário atual |

**URLs, redirect e saída HTML**

| Membro | O que faz |
|---|---|
| `PREPARE_URL` | Acrescenta checksum (`&cs=`) a uma URL `f?p` (prefira `APEX_PAGE.GET_URL`) |
| `REDIRECT_URL` | Redirect + `stop_apex_engine` |
| `HOST_URL` | URL base da instância (`NULL`, `SCRIPT`, `APEX_PATH`, `IMGPRE`) |
| `PRN` | Imprime um CLOB no buffer HTP (escapando por padrão) |
| `COUNT_CLICK` (atalho `Z`) | Conta cliques em links externos (`APEX_WORKSPACE_CLICKS`) |
| `GET_SINCE` (DATE e TIMESTAMP) | Data relativa ("há 2 dias", curto "2d") |
| `HTML_PCT_GRAPH_MASK` | Barra de porcentagem em HTML (máscara `PCT_GRAPH`) |
| `GET_HASH` | Hash dos valores (detecção de *lost update*) |
| `URL_ENCODE` | **Deprecated**: use `UTL_URL.ESCAPE` |

**Arquivos e LOBs**

| Membro | O que faz |
|---|---|
| `GET_FILE` | Baixa arquivo de `APEX_APPLICATION_FILES` |
| `GET_FILE_ID` | ID de um arquivo em `APEX_APPLICATION_FILES` pelo NAME |
| `GET_BLOB_FILE_SRC` | URL de download/exibição de BLOB via item File Browse |
| `BLOB_TO_CLOB` / `CLOB_TO_BLOB` | Conversão de LOB temporário com charset |
| `GET_SUPPORTING_OBJECT_SCRIPT` (function/procedure) | Scripts de install/upgrade/deinstall dos *Supporting Objects* |

**Cache de páginas e regiões**

| Membro | O que faz |
|---|---|
| `CACHE_GET_DATE_OF_PAGE_CACHE` | Quando a página foi cacheada |
| `CACHE_GET_DATE_OF_REGION_CACHE` | Quando a região foi cacheada |
| `CACHE_PURGE_BY_APPLICATION` | Apaga todo cache de páginas/regiões da app |
| `CACHE_PURGE_BY_PAGE` | Apaga cache de uma página (e de suas regiões cacheadas) |
| `CACHE_PURGE_STALE` | Apaga o cache vencido (*Cache Timeout*) |
| `PURGE_REGIONS_BY_APP` / `_BY_PAGE` / `_BY_NAME` | Apaga cache de regiões |

**Usuários, grupos e senhas (repositório APEX Accounts)**

| Membro | O que faz |
|---|---|
| `CREATE_USER` | Cria conta |
| `EDIT_USER` | Altera conta (todos os campos) |
| `FETCH_USER` (3 assinaturas) | Lê a conta |
| `REMOVE_USER` (por ID ou nome) | Remove conta |
| `GET_USER_ID` / `GET_USERNAME` / `GET_CURRENT_USER_ID` | Converte nome ↔ ID |
| `GET_EMAIL` / `SET_EMAIL`, `GET_FIRST_NAME` / `SET_FIRST_NAME`, `GET_LAST_NAME` / `SET_LAST_NAME`, `SET_USERNAME` | Campos da conta |
| `GET_ATTRIBUTE` / `SET_ATTRIBUTE` | Atributos livres 1..10 da conta |
| `GET_USER_ROLES` | Campo `DEVELOPER_ROLE` |
| `IS_USERNAME_UNIQUE` | Se o nome já existe no workspace |
| `IS_LOGIN_PASSWORD_VALID` | Confere usuário/senha (TRUE/FALSE/NULL) |
| `CHANGE_CURRENT_USER_PW` | Troca senha do usuário logado |
| `RESET_PASSWORD` | Troca senha de um usuário (com senha antiga) |
| `RESET_PW` | Gera nova senha e envia por e-mail |
| `CHANGE_PASSWORD_ON_FIRST_USE` / `PASSWORD_FIRST_USE_OCCURRED` | Política de troca no primeiro uso |
| `STRONG_PASSWORD_CHECK` / `STRONG_PASSWORD_VALIDATION` | Testa a senha contra a política do site |
| `LOCK_ACCOUNT` / `UNLOCK_ACCOUNT` / `GET_ACCOUNT_LOCKED_STATUS` | Bloqueio de conta |
| `EXPIRE_END_USER_ACCOUNT` / `UNEXPIRE_END_USER_ACCOUNT` / `END_USER_ACCOUNT_DAYS_LEFT` | Expiração (usuário final) |
| `EXPIRE_WORKSPACE_ACCOUNT` / `UNEXPIRE_WORKSPACE_ACCOUNT` / `WORKSPACE_ACCOUNT_DAYS_LEFT` | Expiração (dev/admin) |
| `CREATE_USER_GROUP` / `DELETE_USER_GROUP` (por ID ou nome) | Grupos do workspace |
| `GET_GROUP_ID` / `GET_GROUP_NAME` / `GET_GROUPS_USER_BELONGS_TO` / `CURRENT_USER_IN_GROUP` | Consulta de grupos |
| `SET_GROUP_GROUP_GRANTS` / `SET_GROUP_USER_GRANTS` | Concede grupos a grupo/usuário |
| `EXPORT_USERS` | Exporta workspace, usuários e grupos |

**Autenticação e autorização**

| Membro | O que faz |
|---|---|
| `SET_AUTHENTICATION_RESULT` / `GET_AUTHENTICATION_RESULT` | Código numérico do resultado do login (log de acesso) |
| `SET_CUSTOM_AUTH_STATUS` | Texto do resultado do login (log de acesso) |
| `PUBLIC_CHECK_AUTHORIZATION` | **Deprecated**: use `APEX_AUTHORIZATION.IS_AUTHORIZED` |
| `RESET_AUTHORIZATIONS` | **Deprecated**: use `APEX_AUTHORIZATION.RESET_CACHE` |

**Preferências de usuário**

| Membro | O que faz |
|---|---|
| `SET_PREFERENCE` / `GET_PREFERENCE` / `REMOVE_PREFERENCE` | Preferência persistente entre sessões |
| `REMOVE_SORT_PREFERENCES` | Remove preferências de ordenação de colunas |

**Acessibilidade**

| Membro | O que faz |
|---|---|
| `IS_HIGH_CONTRAST_SESSION` / `_YN` | Sessão em alto contraste? |
| `SET_SESSION_HIGH_CONTRAST_ON` / `_OFF` | Liga/desliga alto contraste |
| `GET_HIGH_CONTRAST_MODE_TOGGLE` / `SHOW_HIGH_CONTRAST_MODE_TOGGLE` | Link de alternância (retorna ou imprime) |
| `IS_SCREEN_READER_SESSION` / `_YN` | Sessão em modo leitor de tela? |
| `SET_SESSION_SCREEN_READER_ON` / `_OFF` | Liga/desliga modo leitor de tela |
| `GET_SCREEN_READER_MODE_TOGGLE` / `SHOW_SCREEN_READER_MODE_TOGGLE` | Link de alternância |

**Impressão (Report Queries/Layouts)**

| Membro | O que faz |
|---|---|
| `DOWNLOAD_PRINT_DOCUMENT` (4 assinaturas) | Gera e baixa documento (pdf, rtf, xls, htm, xml) |
| `GET_PRINT_DOCUMENT` (4 assinaturas) | Gera e devolve o documento como BLOB |

**Feedback**

| Membro | O que faz |
|---|---|
| `FEEDBACK_ENABLED` | Se *Allow Feedback* está ligado |
| `SUBMIT_FEEDBACK` / `SUBMIT_FEEDBACK_FOLLOWUP` | Registra feedback/follow-up |
| `REPLY_TO_FEEDBACK` | Responde feedback (tipo, status, resposta pública) |
| `GET_FEEDBACK_FOLLOW_UP` | Lê follow-ups de um feedback |
| `DELETE_FEEDBACK` / `DELETE_FEEDBACK_ATTACHMENT` | Apaga feedback/anexo |

**Diversos e deprecated**

| Membro | O que faz |
|---|---|
| `CLOSE_OPEN_DB_LINKS` | Fecha DB links abertos (uso pelo ORDS em pre/postProcess) |
| `STRING_TO_TABLE` / `TABLE_TO_STRING` | **Deprecated**: use `APEX_STRING.STRING_TO_TABLE` / `JOIN` |
| `GET_APPLICATION_STATUS` / `SET_APPLICATION_STATUS` / `SET_APP_BUILD_STATUS` | **Deprecated**: use `APEX_APPLICATION_ADMIN` |
| `GET_BUILD_OPTION_STATUS` (2) / `SET_BUILD_OPTION_STATUS` | **Deprecated**: use `APEX_APPLICATION_ADMIN` |
| `GET_GLOBAL_NOTIFICATION` / `SET_GLOBAL_NOTIFICATION` | **Deprecated**: use `APEX_APPLICATION_ADMIN` |
| `SET_CURRENT_THEME_STYLE` | **Deprecated** (ver `APEX_THEME.SET_CURRENT_STYLE`) |
| `IR_CLEAR`, `IR_DELETE_REPORT`, `IR_DELETE_SUBSCRIPTION`, `IR_FILTER`, `IR_RESET` | **Deprecated**: use `APEX_IR` |
| `CUSTOM_CALENDAR`, `INCREMENT_CALENDAR` | **Deprecated** (calendário legado) |

Fonte: [APEX_UTIL](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_UTIL.html)

### APEX_UTIL.GET_SESSION_STATE, GET_NUMERIC_SESSION_STATE (V e NV) e SET_SESSION_STATE

```sql
APEX_UTIL.GET_SESSION_STATE         ( p_item IN VARCHAR2 ) RETURN VARCHAR2;  -- atalho V()
APEX_UTIL.GET_NUMERIC_SESSION_STATE ( p_item IN VARCHAR2 ) RETURN NUMBER;    -- atalho NV()

APEX_UTIL.SET_SESSION_STATE (
    p_name     IN VARCHAR2 DEFAULT NULL,   -- item de página ou de aplicação
    p_value    IN VARCHAR2 DEFAULT NULL,
    p_commit   IN BOOLEAN  DEFAULT TRUE );
```

- Nome do item não diferencia maiúsculas.
- **Dica de desempenho (doc):** dentro de SQL, embrulhe em *scalar subquery* para usar FAST DUAL e não chamar a função por linha: `where id_empresa = (select apex_util.get_numeric_session_state('G_ID_EMPRESA') from dual)`. Em SQL de região, a bind `:G_ID_EMPRESA` é ainda melhor.
- `p_commit` tem a mesma regra de `APEX_SESSION_STATE.SET_VALUE`: sem commit se `FALSE` ou valor igual; ignorado se *Session State Changes* = *End Of Request*.
- Para CLOB, BOOLEAN ou conversão por format mask, use `APEX_SESSION_STATE`.

```sql
-- Post-Authentication: carregar a empresa do usuário
begin
    for r in (select id_empresa from colaborador where upper(login_apex) = upper(:APP_USER)) loop
        apex_util.set_session_state('G_ID_EMPRESA', r.id_empresa);
    end loop;
end;
```

Fonte: [GET_SESSION_STATE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_SESSION_STATE-Function.html), [GET_NUMERIC_SESSION_STATE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_NUMERIC_SESSION_STATE-Function.html), [SET_SESSION_STATE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_SESSION_STATE-Procedure.html)

### APEX_UTIL.CLEAR_PAGE_CACHE, CLEAR_APP_CACHE, CLEAR_USER_CACHE e FETCH_APP_ITEM

```sql
APEX_UTIL.CLEAR_PAGE_CACHE ( p_page_id IN NUMBER   DEFAULT NULL );  -- NULL = página atual
APEX_UTIL.CLEAR_APP_CACHE  ( p_app_id  IN VARCHAR2 DEFAULT NULL );
APEX_UTIL.CLEAR_USER_CACHE;                                         -- session state + preferências de sistema
APEX_UTIL.FETCH_APP_ITEM (
    p_item    IN VARCHAR2,             -- application item (não item de página)
    p_app     IN NUMBER DEFAULT NULL,  -- NULL = app atual
    p_session IN NUMBER DEFAULT NULL ) -- NULL = sessão atual
RETURN VARCHAR2;
```

- Limpar o cache de uma página antes de abri-la para "novo registro" equivale ao `p_clear_cache` de `APEX_PAGE.GET_URL`.
- `CLEAR_USER_CACHE` é indicado quando se reutiliza um session ID e se quer rodar sem o estado anterior.

Fonte: [CLEAR_PAGE_CACHE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CLEAR_PAGE_CACHE-Procedure.html), [CLEAR_APP_CACHE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CLEAR_APP_CACHE-Procedure.html), [CLEAR_USER_CACHE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CLEAR_USER_CACHE-Procedure.html), [FETCH_APP_ITEM Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/FETCH_APP_ITEM-Function.html)

### APEX_UTIL.REDIRECT_URL: redirecionar dentro de um processo PL/SQL

```sql
APEX_UTIL.REDIRECT_URL (
    p_url               IN VARCHAR2,
    p_reset_htp_buffer  IN BOOLEAN  DEFAULT TRUE );
```

Chama `owa_util.redirect_url` e em seguida `apex_application.stop_apex_engine` automaticamente. `p_reset_htp_buffer => TRUE` limpa o que já foi escrito no buffer HTP para o navegador entender o redirect; use `FALSE` se a app grava um cookie próprio na resposta. Como para o motor, o mesmo cuidado de `STOP_APEX_ENGINE` vale para `WHEN OTHERS` (re-levante `apex_application.e_stop_apex_engine`).

```sql
apex_util.redirect_url(p_url => apex_page.get_url(p_page => 20, p_plain_url => true));
```

Fonte: [REDIRECT_URL Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/REDIRECT_URL-Procedure.html)

### APEX_UTIL.PREPARE_URL: checksum em URLs f?p montadas à mão (prefira APEX_PAGE.GET_URL)

```sql
APEX_UTIL.PREPARE_URL (
    p_url                IN VARCHAR2,               -- f?p com substituições já resolvidas
    p_url_charset        IN VARCHAR2 DEFAULT NULL,  -- ex.: 'UTF-8'
    p_checksum_type      IN VARCHAR2 DEFAULT NULL,
    p_triggering_element IN VARCHAR2 DEFAULT 'this',
    p_plain_url          IN BOOLEAN  DEFAULT FALSE )
RETURN VARCHAR2;
```

`p_checksum_type`:

| Valor | Uso |
|---|---|
| `PUBLIC_BOOKMARK` ou `1` | Link usável por qualquer usuário (ex.: link em e-mail) |
| `PRIVATE_BOOKMARK` ou `2` | Link fora da sessão atual, mas só para o mesmo usuário autenticado |
| `SESSION` ou `3` | Só dentro da sessão atual |

Também troca o session ID por `0` quando o recurso *Zero Session ID* se aplica (usuário público, página pública). O retorno contém `&cs=...`: em JavaScript/HTML pode ser preciso escapar o `&`. Não gera checksum para apps de outro workspace. `p_plain_url`/`p_triggering_element` funcionam como em `GET_URL`.

Fonte: [PREPARE_URL Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PREPARE_URL-Function.html)

### APEX_UTIL.HOST_URL: montar links absolutos (e-mails, notificações)

```sql
APEX_UTIL.HOST_URL ( p_option IN VARCHAR2 DEFAULT NULL ) RETURN VARCHAR2;
```

| `p_option` | Retorno (exemplo) |
|---|---|
| `NULL` | Até a porta: `http://example.com:7778` |
| `SCRIPT` | Com o script; com *Friendly URL*: `https://example.com:7778/pls/apex/r/{workspace}/{application}`, sem: `https://example.com:7778/pls/apex/` |
| `APEX_PATH` | Até o caminho do APEX: `https://example.com:7778/pls/apex/` |
| `IMGPRE` | Prefixo de imagens: `https://example.com:7778/i/` |

Para link de página com checksum em e-mail, `APEX_PAGE.GET_URL(..., p_absolute_url => TRUE)` é mais direto.

Fonte: [HOST_URL Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/HOST_URL-Function.html)

### APEX_UTIL.PRN: imprimir CLOB no buffer HTP (com escape)

```sql
APEX_UTIL.PRN ( p_clob IN CLOB, p_escape IN BOOLEAN DEFAULT TRUE );
```

Escreve o CLOB inteiro no buffer HTP (sem o limite de 32K do `htp.p`). Com `p_escape => TRUE` (padrão) aplica `apex_escape.html`. Use `FALSE` só para conteúdo já seguro (ex.: JSON gerado pelo próprio código num processo Ajax).

```sql
-- Processo Ajax Callback (On-Demand) devolvendo JSON
apex_util.prn(p_clob => l_json, p_escape => false);
```

Fonte: [PRN Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PRN-Procedure.html)

### APEX_UTIL.GET_FILE, GET_FILE_ID e GET_BLOB_FILE_SRC: download e exibição de arquivos

```sql
APEX_UTIL.GET_FILE    ( p_file_id IN VARCHAR2, p_inline IN VARCHAR2 DEFAULT 'NO' );  -- 'YES' exibe no navegador
APEX_UTIL.GET_FILE_ID ( p_name IN VARCHAR2 ) RETURN NUMBER;     -- NAME em APEX_APPLICATION_FILES

APEX_UTIL.GET_BLOB_FILE_SRC (
    p_item_name           IN VARCHAR2 DEFAULT NULL,   -- item File Browse com Storage = coluna BLOB
    p_v1                  IN VARCHAR2 DEFAULT NULL,   -- PK 1
    p_v2                  IN VARCHAR2 DEFAULT NULL,   -- PK 2
    p_content_disposition IN VARCHAR2 DEFAULT NULL )  -- 'INLINE' ou 'ATTACHMENT'
RETURN VARCHAR2;
```

- `GET_FILE` baixa da view `APEX_APPLICATION_FILES` (arquivos do workspace). **Pegadinha:** se chamado durante o processamento da página, nenhum branch pode disparar na mesma condição (nem branch do mesmo botão, nem condicional verdadeiro, nem incondicional), senão o download é corrompido.
- `GET_BLOB_FILE_SRC` exige sessão APEX válida e um item de página tipo File que descreva a coluna BLOB; a URL gerada respeita a segurança do item. Se for passar a URL para `PREPARE_URL` e o item estiver numa página modal, use `p_plain_url => TRUE`.

```sql
select id,
       case when dbms_lob.getlength(documento) > 0 then
           '<a href="' || apex_util.get_blob_file_src('P4_DOCUMENTO', id) || '">Baixar</a>'
       end as link
  from anexo
 where id_empresa = :G_ID_EMPRESA;
```

Fonte: [GET_FILE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_FILE-Procedure.html), [GET_FILE_ID Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_FILE_ID-Function.html), [GET_BLOB_FILE_SRC Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_BLOB_FILE_SRC-Function.html)

### APEX_UTIL.BLOB_TO_CLOB e CLOB_TO_BLOB: converter LOBs com charset

```sql
APEX_UTIL.BLOB_TO_CLOB (
    p_blob              IN BLOB,
    p_charset           IN VARCHAR2 DEFAULT NULL,   -- NULL = charset do banco, sem conversão
    p_in_memory         IN VARCHAR2 DEFAULT 'Y',
    p_free_immediately  IN VARCHAR2 DEFAULT 'Y' )   -- libera o LOB temporário após a chamada top-level
RETURN CLOB;

APEX_UTIL.CLOB_TO_BLOB (
    p_clob              IN CLOB,
    p_charset           IN VARCHAR2 DEFAULT NULL,   -- ex.: 'AL32UTF8', 'WE8ISO8859P1'
    p_include_bom       IN VARCHAR2 DEFAULT 'N',
    p_in_memory         IN VARCHAR2 DEFAULT 'Y',
    p_free_immediately  IN VARCHAR2 DEFAULT 'Y' )
RETURN BLOB;
```

Uso típico: resposta de `APEX_WEB_SERVICE.MAKE_REST_REQUEST_B` para CLOB; gerar arquivo CSV/JSON para download ou anexo de `APEX_MAIL`. `p_include_bom => 'Y'` ajuda o Excel a reconhecer CSV UTF-8.

Fonte: [BLOB_TO_CLOB Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/BLOB_TO_CLOB-Function.html), [CLOB_TO_BLOB Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CLOB_TO_BLOB-Function.html)

### APEX_UTIL.CREATE_USER: criar contas APEX (APEX Accounts) por PL/SQL

```sql
APEX_UTIL.CREATE_USER (
    p_user_id                       IN NUMBER   DEFAULT NULL,
    p_user_name                     IN VARCHAR2,
    p_first_name                    IN VARCHAR2 DEFAULT NULL,
    p_last_name                     IN VARCHAR2 DEFAULT NULL,
    p_description                   IN VARCHAR2 DEFAULT NULL,
    p_email_address                 IN VARCHAR2 DEFAULT NULL,
    p_web_password                  IN VARCHAR2,
    p_web_password_format           IN VARCHAR2 DEFAULT 'CLEAR_TEXT',  -- ou 'HEX_ENCODED_DIGEST_V2'
    p_group_ids                     IN VARCHAR2 DEFAULT NULL,          -- IDs separados por ':'
    p_developer_privs               IN VARCHAR2 DEFAULT NULL,          -- NULL = usuário final
    p_default_schema                IN VARCHAR2 DEFAULT NULL,
    p_default_date_format           IN VARCHAR2 DEFAULT NULL,
    p_allow_access_to_schemas       IN VARCHAR2 DEFAULT NULL,
    p_account_expiry                IN DATE     DEFAULT TRUNC(SYSDATE),
    p_account_locked                IN VARCHAR2 DEFAULT 'N',
    p_failed_access_attempts        IN NUMBER   DEFAULT 0,
    p_change_password_on_first_use  IN VARCHAR2 DEFAULT 'Y',
    p_first_password_use_occurred   IN VARCHAR2 DEFAULT 'N',
    p_attribute_01 .. p_attribute_10 IN VARCHAR2 DEFAULT NULL,
    p_allow_app_building_yn         IN VARCHAR2 DEFAULT NULL,
    p_allow_sql_workshop_yn         IN VARCHAR2 DEFAULT NULL,
    p_allow_websheet_dev_yn         IN VARCHAR2 DEFAULT NULL,
    p_allow_team_development_yn     IN VARCHAR2 DEFAULT NULL );
```

Valores de `p_developer_privs`: `NULL` (usuário final, só entra nas apps), `CREATE:DATA_LOADER:EDIT:HELP:MONITOR:SQL` (desenvolvedor), `ADMIN:CREATE:DATA_LOADER:EDIT:HELP:MONITOR:SQL` (admin do workspace). A doc avisa: o mesmo campo `DEVELOPER_ROLE` se chama `p_developer_privs` em `CREATE_USER`, `p_developer_roles` em `EDIT_USER` e `p_developer_role` em `FETCH_USER`.

Requisitos e comportamento:
- Dentro de uma app, o usuário corrente precisa ser **admin do workspace** e a app precisa permitir modificar o repositório do workspace.
- `p_change_password_on_first_use` vem `'Y'`: o usuário é forçado a trocar a senha no primeiro login.
- `p_attribute_01..10` guardam texto livre, lido com `GET_ATTRIBUTE`.
- Só cria o usuário no repositório APEX; para devs com autenticação por conta de banco, é preciso também `CREATE USER` no banco.

```sql
begin
    if apex_util.is_username_unique(p_username => upper(:P14_LOGIN)) then
        apex_util.create_user(
            p_user_name     => upper(:P14_LOGIN),
            p_first_name    => :P14_PRIMEIRO_NOME,
            p_last_name     => :P14_ULTIMO_NOME,
            p_email_address => :P14_EMAIL,
            p_web_password  => :P14_SENHA,
            p_change_password_on_first_use => 'Y');
    else
        apex_error.add_error(p_message => 'Login já existe no workspace.',
                             p_display_location => apex_error.c_inline_with_field_and_notif,
                             p_page_item_name => 'P14_LOGIN');
    end if;
end;
```

Fonte: [CREATE_USER Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CREATE_USER-Procedure.html), [IS_USERNAME_UNIQUE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/IS_USERNAME_UNIQUE-Function.html)

### APEX_UTIL.EDIT_USER e FETCH_USER: alterar contas sem perder campos

`EDIT_USER` tem os mesmos campos (incluindo `p_web_password` e `p_new_password`, `p_developer_roles`, `p_account_locked`, `p_failed_access_attempts`, `p_change_password_on_first_use`) e **sobrescreve todos**: os defaults (`'N'`, `0`, `'Y'`…) são aplicados se você não passar o valor. Padrão da doc: chamar `FETCH_USER` (assinatura 3, com todos os OUT) para ler a conta, mudar só o campo desejado e passar o resto de volta para `EDIT_USER`. Para trocar a senha via `EDIT_USER`, `p_web_password` e `p_new_password` devem ser **iguais e não nulos**.

Para mudanças pontuais prefira os setters: `SET_EMAIL`, `SET_FIRST_NAME`, `SET_LAST_NAME`, `SET_USERNAME`, `SET_ATTRIBUTE`, `LOCK_ACCOUNT`, `UNLOCK_ACCOUNT`.

```sql
APEX_UTIL.FETCH_USER (            -- assinatura 2 (enxuta)
    p_user_id        IN  NUMBER,
    p_user_name      OUT VARCHAR2,
    p_first_name     OUT VARCHAR2,
    p_last_name      OUT VARCHAR2,
    p_email_address  OUT VARCHAR2,
    p_groups         OUT VARCHAR2,
    p_developer_role OUT VARCHAR2,
    p_description    OUT VARCHAR2 );
```

Fonte: [EDIT_USER Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/EDIT_USER-Procedure.html), [FETCH_USER Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/FETCH_USER-Procedure-Signature-1.html), [FETCH_USER Procedure Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/FETCH_USER-Procedure-Signature-2.html), [FETCH_USER Procedure Signature 3](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/FETCH_USER-Procedure-Signature-3.html)

### APEX_UTIL: senhas (RESET_PASSWORD, CHANGE_CURRENT_USER_PW, IS_LOGIN_PASSWORD_VALID, STRONG_PASSWORD_*)

```sql
APEX_UTIL.RESET_PASSWORD (
    p_user_name                     IN VARCHAR2 DEFAULT apex_application.g_user,
    p_old_password                  IN VARCHAR2 DEFAULT NULL,
    p_new_password                  IN VARCHAR2,
    p_change_password_on_first_use  IN BOOLEAN  DEFAULT TRUE );

APEX_UTIL.CHANGE_CURRENT_USER_PW ( p_new_password IN VARCHAR2 );
APEX_UTIL.RESET_PW ( p_user IN VARCHAR2, p_msg IN VARCHAR2 );      -- gera senha e envia e-mail
APEX_UTIL.IS_LOGIN_PASSWORD_VALID ( p_username IN VARCHAR2 DEFAULT NULL,
                                    p_password IN VARCHAR2 DEFAULT NULL ) RETURN BOOLEAN;
APEX_UTIL.STRONG_PASSWORD_VALIDATION ( p_username IN VARCHAR2, p_password IN VARCHAR2,
                                       p_old_password IN VARCHAR2 DEFAULT NULL,
                                       p_workspace_name IN VARCHAR2 ) RETURN VARCHAR2;   -- HTML
```

`RESET_PASSWORD` erros:

| Erro | Quando |
|---|---|
| `INVALID_CREDENTIALS` | `p_old_password` não confere |
| `APEX.AUTHENTICATION.LOGIN_THROTTLE.COUNTER` | Bloqueado pelo *login throttle* |
| internal error | `p_old_password` NULL e o dono do código não tem `APEX_ADMINISTRATOR_ROLE` |
| internal error | Chamador não é um schema válido do workspace |

`IS_LOGIN_PASSWORD_VALID` retorna `TRUE` (válido), `FALSE` (inválido) ou **`NULL`** (verificação adiada por excesso de tentativas erradas): trate o NULL. `STRONG_PASSWORD_CHECK` devolve um BOOLEAN OUT por regra (tamanho mínimo, diferir da antiga, alfa, numérico, pontuação, maiúscula, minúscula, não conter usuário/workspace/palavras simples, não reutilizável); passe `p_use_strong_rules => FALSE`. `STRONG_PASSWORD_VALIDATION` devolve o mesmo resultado já em HTML.

```sql
-- Validação "PL/SQL Function Body returning Error Text" na troca de senha
return apex_util.strong_password_validation(
           p_username       => :APP_USER,
           p_password       => :P6_NOVA_SENHA,
           p_old_password   => :P6_SENHA_ATUAL,
           p_workspace_name => 'WKSP_CORLIXHUB');
```

Fonte: [RESET_PASSWORD Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/RESET_PASSWORD-Procedure.html), [CHANGE_CURRENT_USER_PW Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CHANGE_CURRENT_USER_PW-Procedure.html), [RESET_PW Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/RESET_PW-Procedure.html), [IS_LOGIN_PASSWORD_VALID Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/IS_LOGIN_PASSWORD_VALID-Function.html), [STRONG_PASSWORD_CHECK Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/STRONG_PASSWORD_CHECK-Procedure.html), [STRONG_PASSWORD_VALIDATION Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/STRONG_PASSWORD_VALIDATION-Function.html)

### APEX_UTIL: bloqueio, expiração e consulta de contas (LOCK_ACCOUNT, EXPIRE_*, *_DAYS_LEFT)

| Rotina | Assinatura | Observação |
|---|---|---|
| `LOCK_ACCOUNT` / `UNLOCK_ACCOUNT` | `(p_user_name IN VARCHAR2)` | Admin do workspace, em contexto de request de página |
| `GET_ACCOUNT_LOCKED_STATUS` | `(p_user_name) RETURN BOOLEAN` | Admin, em request de página |
| `EXPIRE_END_USER_ACCOUNT` / `UNEXPIRE_END_USER_ACCOUNT` | `(p_user_name)` | Expira/renova o uso como usuário final (pode afetar também o login de dev) |
| `EXPIRE_WORKSPACE_ACCOUNT` / `UNEXPIRE_WORKSPACE_ACCOUNT` | `(p_user_name)` | Expira/renova o login de dev/admin |
| `END_USER_ACCOUNT_DAYS_LEFT` / `WORKSPACE_ACCOUNT_DAYS_LEFT` | `(p_user_name) RETURN NUMBER` | Dias até a senha expirar; qualquer usuário autenticado |
| `CHANGE_PASSWORD_ON_FIRST_USE` | `(p_user_name) RETURN BOOLEAN` | Se a conta exige troca no primeiro uso |
| `PASSWORD_FIRST_USE_OCCURRED` | `(p_user_name) RETURN BOOLEAN` | Se a senha já foi trocada desde a criação/reset |
| `GET_USER_ID` / `GET_USERNAME` / `GET_CURRENT_USER_ID` | nome ↔ ID | |
| `GET_EMAIL`, `GET_FIRST_NAME`, `GET_LAST_NAME`, `GET_USER_ROLES` | `(p_username) RETURN VARCHAR2` | |
| `GET_ATTRIBUTE` / `SET_ATTRIBUTE` | `(p_username, p_attribute_number 1..10)` / `(p_userid, p_attribute_number, p_attribute_value)` | Atributos só acessíveis por API |
| `REMOVE_USER` | `(p_user_id)` ou `(p_user_name)` | Admin do workspace |

As views `APEX_USERS` / `APEX_WORKSPACE_APEX_USERS` listam as contas (usadas nos exemplos da doc).

Fonte: [LOCK_ACCOUNT Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/LOCK_ACCOUNT-Procedure.html), [UNLOCK_ACCOUNT Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/UNLOCK_ACCOUNT-Procedure.html), [EXPIRE_END_USER_ACCOUNT Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/EXPIRE_END_USER_ACCOUNT-Procedure.html), [END_USER_ACCOUNT_DAYS_LEFT Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/END_USER_ACCOUNT_DAYS_LEFT-Function.html), [REMOVE_USER Procedure Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/REMOVE_USER-Signature-2-Procedure.html), [GET_ATTRIBUTE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_ATTRIBUTE-Function.html), [SET_ATTRIBUTE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_ATTRIBUTE-Procedure.html)

### APEX_UTIL: grupos de usuários do workspace (CREATE_USER_GROUP, CURRENT_USER_IN_GROUP, SET_GROUP_USER_GRANTS)

```sql
APEX_UTIL.CREATE_USER_GROUP ( p_id IN NUMBER DEFAULT NULL, p_group_name IN VARCHAR2,
                              p_security_group_id IN NUMBER DEFAULT NULL,  -- NULL = workspace atual
                              p_group_desc IN VARCHAR2 DEFAULT NULL );
APEX_UTIL.DELETE_USER_GROUP ( p_group_id IN NUMBER ) | ( p_group_name IN VARCHAR2 );
APEX_UTIL.CURRENT_USER_IN_GROUP ( p_group_name IN VARCHAR2 ) | ( p_group_id IN NUMBER ) RETURN BOOLEAN;
APEX_UTIL.GET_GROUPS_USER_BELONGS_TO ( p_username IN VARCHAR2 ) RETURN VARCHAR2;  -- 'A, B, C'
APEX_UTIL.GET_GROUP_ID ( p_group_name IN VARCHAR2 ) RETURN VARCHAR2;
APEX_UTIL.GET_GROUP_NAME ( p_group_id IN NUMBER ) RETURN VARCHAR2;
APEX_UTIL.SET_GROUP_GROUP_GRANTS ( p_group_name IN VARCHAR2, p_granted_group_names IN apex_t_varchar2 );
APEX_UTIL.SET_GROUP_USER_GRANTS  ( p_user_name  IN VARCHAR2, p_granted_group_names IN apex_t_varchar2 );
```

Grupos de workspace são diferentes dos *roles* do Access Control da aplicação (`APEX_ACL`). Para autorizações por papel dentro de uma app, prefira `APEX_ACL` + authorization scheme do tipo *Is In Role or Group*.

Fonte: [CREATE_USER_GROUP Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CREATE_USER_GROUP-Procedure.html), [CURRENT_USER_IN_GROUP Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CURRENT_USER_IN_GROUP-Function.html), [GET_GROUPS_USER_BELONGS_TO Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_GROUPS_USER_BELONGS_TO-Function.html), [SET_GROUP_GROUP_GRANTS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_GROUP_GROUP_GRANTS-Procedure.html), [SET_GROUP_USER_GRANTS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_GROUP_USER_GRANTS-Procedure.html)

### APEX_UTIL.SET_AUTHENTICATION_RESULT e SET_CUSTOM_AUTH_STATUS: registrar o resultado do login

```sql
APEX_UTIL.SET_AUTHENTICATION_RESULT ( p_code IN NUMBER );
APEX_UTIL.GET_AUTHENTICATION_RESULT RETURN NUMBER;
APEX_UTIL.SET_CUSTOM_AUTH_STATUS ( p_status IN VARCHAR2 );   -- até 4000 caracteres
```

Chamados dentro da função de verificação de credenciais de um esquema *Custom*. Código e texto aparecem no *Login Access Log* (view `APEX_USER_ACCESS_LOG`). `GET_AUTHENTICATION_RESULT` lê o código no *Post-Authentication*.

```sql
create or replace function autentica(p_username in varchar2, p_password in varchar2)
return boolean is
begin
    if credenciais_ok(p_username, p_password) then
        apex_util.set_authentication_result(0);
        return true;
    end if;
    apex_util.set_custom_auth_status(p_status => 'Senha inválida para ' || p_username);
    apex_util.set_authentication_result(-1);
    return false;
end;
```

Fonte: [SET_AUTHENTICATION_RESULT Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_AUTHENTICATION_RESULT-Procedure.html), [GET_AUTHENTICATION_RESULT Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_AUTHENTICATION_RESULT-Function.html), [SET_CUSTOM_AUTH_STATUS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_CUSTOM_AUTH_STATUS-Procedure.html)

### APEX_UTIL.SET_PREFERENCE, GET_PREFERENCE e REMOVE_PREFERENCE: preferências persistentes do usuário

```sql
APEX_UTIL.SET_PREFERENCE    ( p_preference IN VARCHAR2 DEFAULT NULL,  -- nome sensível a maiúsculas
                              p_value      IN VARCHAR2 DEFAULT NULL,
                              p_user       IN VARCHAR2 DEFAULT NULL );
APEX_UTIL.GET_PREFERENCE    ( p_preference IN VARCHAR2 DEFAULT NULL,
                              p_user       IN VARCHAR2 DEFAULT V('USER') ) RETURN VARCHAR2;
APEX_UTIL.REMOVE_PREFERENCE ( p_preference IN VARCHAR2 DEFAULT NULL,
                              p_user       IN VARCHAR2 DEFAULT V('USER') );
APEX_UTIL.REMOVE_SORT_PREFERENCES ( p_user IN VARCHAR2 DEFAULT V('USER') );
```

Persistem **além da sessão** (ex.: visão padrão de um calendário, filtro preferido). O nome da preferência é *case-sensitive* em `SET_PREFERENCE`. Passe `p_user => :APP_USER` explicitamente.

Fonte: [SET_PREFERENCE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_PREFERENCE-Procedure.html), [GET_PREFERENCE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_PREFERENCE-Function.html), [REMOVE_PREFERENCE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/REMOVE_PREFERENCE-Procedure.html), [REMOVE_SORT_PREFERENCES Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/REMOVE_SORT_PREFERENCES-Procedure.html)

### APEX_UTIL: idioma, território, fuso e duração da sessão (SET_SESSION_LANG, SET_SESSION_TIME_ZONE, SET_SESSION_LIFETIME_SECONDS)

```sql
APEX_UTIL.SET_SESSION_LANG      ( p_lang IN VARCHAR2 );       -- IANA: 'en', 'de', 'pt-br'
APEX_UTIL.SET_SESSION_TERRITORY ( p_territory IN VARCHAR2 );  -- 'AMERICA', 'UNITED KINGDOM'...
APEX_UTIL.SET_SESSION_TIME_ZONE ( p_time_zone IN VARCHAR2 );  -- '+09:00', '-05:00'
APEX_UTIL.GET_SESSION_LANG / GET_SESSION_TERRITORY / GET_SESSION_TIME_ZONE RETURN VARCHAR2;
APEX_UTIL.SET_SESSION_LIFETIME_SECONDS ( p_seconds IN NUMBER, p_scope IN VARCHAR2 DEFAULT 'SESSION' );
APEX_UTIL.SET_SESSION_MAX_IDLE_SECONDS ( p_seconds IN NUMBER, p_scope IN VARCHAR2 DEFAULT 'SESSION' );
```

- `GET_SESSION_TIME_ZONE` volta NULL se o fuso não foi definido por `SET_SESSION_TIME_ZONE` ou se o atributo de fuso automático da app está ligado.
- `p_scope` é **obsoleto**: as duas rotinas de duração sempre valem para a sessão inteira (todas as apps que a compartilham).
- Uso típico: encurtar a sessão de perfis administrativos no *Post-Authentication*.

Fonte: [SET_SESSION_LANG Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_SESSION_LANG-Procedure.html), [SET_SESSION_TERRITORY Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_SESSION_TERRITORY-Procedure.html), [SET_SESSION_TIME_ZONE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_SESSION_TIME_ZONE-Procedure.html), [GET_SESSION_TIME_ZONE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_SESSION_TIME_ZONE-Function.html), [SET_SESSION_LIFETIME_SECONDS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_SESSION_LIFETIME_SECONDS-Procedure.html), [SET_SESSION_MAX_IDLE_SECONDS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_SESSION_MAX_IDLE_SECONDS-Procedure.html)

### APEX_UTIL.SET_WORKSPACE e SET_SECURITY_GROUP_ID: usar APIs APEX em jobs e scripts

```sql
APEX_UTIL.SET_WORKSPACE         ( p_workspace IN VARCHAR2 );            -- nome curto do workspace
APEX_UTIL.SET_SECURITY_GROUP_ID ( p_security_group_id IN NUMBER );
APEX_UTIL.FIND_SECURITY_GROUP_ID ( p_workspace IN VARCHAR2 ) RETURN NUMBER;
APEX_UTIL.FIND_WORKSPACE ( p_security_group_id IN VARCHAR2 ) RETURN VARCHAR2;
```

Necessário para chamar APIs que dependem de workspace (`APEX_MAIL`, `GET_SUPPORTING_OBJECT_SCRIPT`…) fora de uma app: jobs `DBMS_SCHEDULER`, PL/SQL avulso, schema ligado a vários workspaces.

**Pegadinha:** `SET_WORKSPACE` só muda o contexto se o usuário de banco estiver mapeado ao workspace ou tiver `APEX_ADMINISTRATOR_ROLE`; caso contrário **não levanta erro** e simplesmente não muda nada. Se a chamada seguinte falhar por workspace, desconfie disso.

```sql
begin
    apex_util.set_workspace(p_workspace => 'WKSP_CORLIXHUB');
    apex_mail.send(p_to => 'rh@exemplo.com', p_from => 'noreply@exemplo.com',
                   p_subj => 'Resumo diário', p_body => '...');
end;
```

Fonte: [SET_WORKSPACE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_UTIL.SET_WORKSPACE_Procedure-2.html), [SET_SECURITY_GROUP_ID Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_SECURITY_GROUP_ID-Procedure.html), [FIND_SECURITY_GROUP_ID Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/FIND_SECURITY_GROUP_ID-Function.html), [FIND_WORKSPACE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/FIND_WORKSPACE-Function.html)

### APEX_UTIL.SET_PARSING_SCHEMA_FOR_REQUEST e SET_EDITION

```sql
APEX_UTIL.SET_PARSING_SCHEMA_FOR_REQUEST ( p_schema IN VARCHAR2 );
APEX_UTIL.SET_EDITION ( p_edition IN VARCHAR2 );
APEX_UTIL.GET_EDITION RETURN VARCHAR2;
```

`SET_PARSING_SCHEMA_FOR_REQUEST` troca o parsing schema do page view para outro schema do workspace e **só pode** ser chamado no *Initialization PL/SQL Code* da app. Exceções: `PROGRAM_ERROR` (fora do Initialization Code) e `WWV_FLOW.NO_PRIV_ON_SCHEMA` (schema inválido). `SET_EDITION` define a edition (Edition-Based Redefinition) para todo SQL do page view/submit.

Fonte: [SET_PARSING_SCHEMA_FOR_REQUEST Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_PARSING_SCHEMA_FOR_REQUEST-Procedure.html), [SET_EDITION Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_EDITION-Procedure.html), [GET_EDITION Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_EDITION-Function.html)

### APEX_UTIL.GET_HASH: detectar atualização concorrente (lost update)

```sql
APEX_UTIL.GET_HASH (
    p_values IN apex_t_varchar2,
    p_salted IN BOOLEAN DEFAULT TRUE )   -- salga com informação interna da sessão
RETURN VARCHAR2;
```

Calcula hash com o algoritmo padrão da instância. Indicado para hashes de vida curta: guarde o hash dos valores lidos num item oculto, recalcule antes do UPDATE e compare. Como é salgado com dados da sessão, não serve para persistir. Para controle total do algoritmo use `STANDARD_HASH` ou `DBMS_CRYPTO`.

```sql
select apex_util.get_hash(apex_t_varchar2(id_colaborador, id_cargo, id_departamento))
  into l_hash
  from colaborador
 where id_colaborador = :P13_ID and id_empresa = :G_ID_EMPRESA;
if :P13_HASH <> l_hash then
    raise_application_error(-20001, 'Outro usuário alterou este registro. Recarregue a página.');
end if;
```

Fonte: [GET_HASH Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_HASH-Function.html)

### APEX_UTIL.GET_SINCE e HTML_PCT_GRAPH_MASK: formatação em relatórios

```sql
APEX_UTIL.GET_SINCE ( p_date  IN DATE,
                      p_short IN BOOLEAN DEFAULT FALSE | VARCHAR2 DEFAULT 'N' ) RETURN VARCHAR2;
APEX_UTIL.GET_SINCE ( p_value IN TIMESTAMP | TIMESTAMP WITH TIME ZONE | TIMESTAMP WITH LOCAL TIME ZONE,
                      p_short IN BOOLEAN DEFAULT FALSE | VARCHAR2 DEFAULT 'N' ) RETURN VARCHAR2;

APEX_UTIL.HTML_PCT_GRAPH_MASK (
    p_number          IN NUMBER   DEFAULT NULL,   -- 0..100
    p_size            IN NUMBER   DEFAULT 100,    -- largura em px
    p_background      IN VARCHAR2 DEFAULT NULL,   -- hex 6 caracteres
    p_bar_background  IN VARCHAR2 DEFAULT NULL,
    p_format          IN VARCHAR2 DEFAULT NULL,   -- 'PCT_GRAPH:<fundo>:<barra>:<largura>' (ignora os 3 anteriores)
    p_aria_labelledby IN VARCHAR2 DEFAULT NULL,
    p_aria_label      IN VARCHAR2 DEFAULT NULL ) RETURN VARCHAR2;
```

`GET_SINCE` equivale às máscaras `SINCE` / `SINCE_SHORT` ("há 30 minutos" / "30m"). `HTML_PCT_GRAPH_MASK` gera um `<div>` com estilos inline; em coluna numérica de relatório dá para usar a máscara `PCT_GRAPH:777777:111111:200` diretamente. Informe `p_aria_label` para acessibilidade.

Fonte: [GET_SINCE Function Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_SINCE-Function-Signature-1.html), [GET_SINCE Function Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_SINCE-Function-Signature-2.html), [HTML_PCT_GRAPH_MASK Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/HTML_PCT_GRAPH_MASK-Function.html)

### APEX_UTIL: cache de páginas e regiões (CACHE_PURGE_*, PURGE_REGIONS_*)

```sql
APEX_UTIL.CACHE_PURGE_BY_APPLICATION ( p_application IN NUMBER );
APEX_UTIL.CACHE_PURGE_BY_PAGE ( p_application IN NUMBER, p_page IN NUMBER, p_user_name IN VARCHAR2 DEFAULT NULL );
APEX_UTIL.CACHE_PURGE_STALE ( p_application IN NUMBER );
APEX_UTIL.CACHE_GET_DATE_OF_PAGE_CACHE   ( p_application IN NUMBER, p_page IN NUMBER ) RETURN DATE;
APEX_UTIL.CACHE_GET_DATE_OF_REGION_CACHE ( p_application IN NUMBER, p_page IN NUMBER, p_region_name IN VARCHAR2 ) RETURN DATE;
APEX_UTIL.PURGE_REGIONS_BY_APP  ( p_application IN NUMBER );
APEX_UTIL.PURGE_REGIONS_BY_PAGE ( p_application IN NUMBER, p_page IN NUMBER );
APEX_UTIL.PURGE_REGIONS_BY_NAME ( p_application IN NUMBER, p_page IN NUMBER, p_region_name IN VARCHAR2 );
```

`CACHE_PURGE_BY_PAGE` também limpa as regiões cacheadas da página, mesmo que a página em si não seja cacheada; `p_user_name` restringe ao cache daquele usuário (quando o cache é por usuário). `CACHE_PURGE_STALE` remove só o que passou do *Cache Timeout*. Para a página atual, `APEX_PAGE.PURGE_CACHE` é o equivalente moderno. Padrão: após gravar dados que alimentam uma região cacheada do dashboard, purgue o cache dela.

Fonte: [CACHE_PURGE_BY_PAGE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CACHE_PURGE_BY_PAGE-Procedure.html), [CACHE_PURGE_BY_APPLICATION Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CACHE_PURGE_BY_APPLICATION-Procedure.html), [CACHE_PURGE_STALE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CACHE_PURGE_STALE-Procedure.html), [CACHE_GET_DATE_OF_REGION_CACHE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CACHE_GET_DATE_OF_REGION_CACHE-Function.html), [PURGE_REGIONS_BY_NAME Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PURGE_REGIONS_BY_NAME-Procedure.html)

### APEX_UTIL.DOWNLOAD_PRINT_DOCUMENT e GET_PRINT_DOCUMENT: PDF a partir de Report Query

As duas famílias têm 4 assinaturas que combinam origem dos dados e layout:

| Assinatura | Dados | Layout |
|---|---|---|
| 1 | `p_report_data IN BLOB` (XML) | `p_report_layout IN CLOB` (XSL-FO ou RTF) |
| 2 | `p_application_id` + `p_report_query_name` (Report Query) | `p_report_layout IN CLOB` (DOWNLOAD) / `p_report_layout_name` (GET) |
| 3 | Report Query | `p_report_layout_name` (DOWNLOAD) / `p_report_layout IN CLOB` (GET) |
| 4 | `p_report_data IN CLOB` (XML em UTF-8) | `p_report_layout IN CLOB` |

Parâmetros comuns: `p_report_layout_type` (`'xsl-fo'` padrão ou `'rtf'`), `p_document_format` (`'pdf'` padrão, `'rtf'`, `'xls'`, `'htm'`, `'xml'`), `p_print_server` (NULL = o configurado na instância). `DOWNLOAD_PRINT_DOCUMENT` acrescenta `p_file_name` e `p_content_disposition` (`'attachment'` ou `'inline'`). `GET_PRINT_DOCUMENT` devolve BLOB, útil para anexar em `APEX_MAIL.ADD_ATTACHMENT`.

```sql
declare
    l_pdf blob;
    l_id  number;
begin
    l_pdf := apex_util.get_print_document(
                 p_application_id     => :APP_ID,
                 p_report_query_name  => 'FICHA_COLABORADOR',
                 p_report_layout_name => 'FICHA_COLABORADOR');
    l_id := apex_mail.send(p_to => :P13_EMAIL, p_from => 'rh@exemplo.com',
                           p_subj => 'Sua ficha', p_body => 'Segue anexo.');
    apex_mail.add_attachment(p_mail_id => l_id, p_attachment => l_pdf,
                             p_filename => 'ficha.pdf', p_mime_type => 'application/pdf');
end;
```

Fonte: [DOWNLOAD_PRINT_DOCUMENT Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/DOWNLOAD_PRINT_DOCUMENT-Procedure-Signature-1.html), [Signature 3](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/DOWNLOAD_PRINT_DOCUMENT-Procedure-Signature-3.html), [GET_PRINT_DOCUMENT Function Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_PRINT_DOCUMENT-Function-Signature-2.html), [GET_PRINT_DOCUMENT Function Signature 4](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_PRINT_DOCUMENT-Function-Signature-4.html)

### APEX_UTIL: modo alto contraste e leitor de tela

`IS_HIGH_CONTRAST_SESSION` / `IS_SCREEN_READER_SESSION` (BOOLEAN) e as versões `_YN` (`'Y'`/`'N'`, úteis em SQL e condições) informam o modo da sessão. `SET_SESSION_*_ON/OFF` liga/desliga. `GET_*_MODE_TOGGLE` devolve, e `SHOW_*_MODE_TOGGLE` imprime, um link que recarrega a página alternando o modo; os textos padrão podem ser trocados por `p_on_message`/`p_off_message` ou pelas mensagens de sistema traduzíveis `APEX.SET_HIGH_CONTRAST_MODE_ON` / `APEX.SET_HIGH_CONTRAST_MODE_OFF`.

```sql
if apex_util.is_high_contrast_session then
    apex_css.add_file(p_name => 'corlix-alto-contraste');
end if;
```

Fonte: [IS_HIGH_CONTRAST_SESSION Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/IS_HIGH_CONTRAST_SESSION-Function.html), [GET_HIGH_CONTRAST_MODE_TOGGLE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_HIGH_CONTRAST_MODE_TOGGLE-Function.html), [IS_SCREEN_READER_SESSION Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/IS_SCREEN_READER_SESSION-Function.html), [SHOW_SCREEN_READER_MODE_TOGGLE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SHOW_SCREEN_READER_MODE_TOGGLE-Procedure.html)

### APEX_UTIL: feedback da aplicação (SUBMIT_FEEDBACK, REPLY_TO_FEEDBACK)

```sql
APEX_UTIL.SUBMIT_FEEDBACK (
    p_comment, p_type DEFAULT 1,          -- 1 comentário, 2 melhoria, 3 bug
    p_application_id, p_page_id, p_email, p_screen_width, p_screen_height,
    p_attribute_01..08, p_label_01..08,
    p_rating,                             -- 3 bom, 2 neutro, 1 ruim
    p_attachment_name );                  -- referência ao item File Browse
APEX_UTIL.REPLY_TO_FEEDBACK (
    p_feedback_id, p_type, p_status,      -- status: 0 sem ação, 1 reconhecido, 3 aberto, 4 fechado
    p_tags, p_developer_comment, p_public_response, p_followup );
APEX_UTIL.SUBMIT_FEEDBACK_FOLLOWUP ( p_feedback_id, p_follow_up, p_email );
APEX_UTIL.GET_FEEDBACK_FOLLOW_UP ( p_feedback_id, p_row DEFAULT 1,
    p_template DEFAULT '<br />#CREATED_ON# (#CREATED_BY#) #FOLLOW_UP#' ) RETURN VARCHAR2;
APEX_UTIL.FEEDBACK_ENABLED RETURN BOOLEAN;
APEX_UTIL.DELETE_FEEDBACK ( p_feedback_id ); APEX_UTIL.DELETE_FEEDBACK_ATTACHMENT ( p_feedback_id );
```

A página de feedback gerada pelo assistente usa só `p_public_response` (não passa dados para `p_followup`); `p_tags` e `p_developer_comment` não são exibidos na implementação atual.

Fonte: [SUBMIT_FEEDBACK Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SUBMIT_FEEDBACK-Procedure.html), [REPLY_TO_FEEDBACK Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_UTIL.REPLY_TO_FEEDBACK-Procedure.html), [GET_FEEDBACK_FOLLOW_UP Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_FEEDBACK_FOLLOW_UP-Function.html), [FEEDBACK_ENABLED Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/FEEDBACK_ENABLED-Function.html)

### APEX_UTIL: demais rotinas (COUNT_CLICK, CLOSE_OPEN_DB_LINKS, SAVEKEY/KEYVAL, GET_SUPPORTING_OBJECT_SCRIPT, EXPORT_USERS)

- `COUNT_CLICK(p_url, p_cat, p_id, p_user, p_workspace, p_referrer_policy)` (atalho `Z`): redireciona para `p_url` e registra o clique na view `APEX_WORKSPACE_CLICKS`.
- `CLOSE_OPEN_DB_LINKS`: fecha os DB links da sessão; feito para o ORDS chamar em `procedure.preProcess`/`procedure.postProcess`. Raramente chamado pela app.
- `SAVEKEY_NUM`/`KEYVAL_NUM` e `SAVEKEY_VC2`/`KEYVAL_VC2`: guardam um valor em variável de package (`apex_utilities.g_val_num`/`g_val_vc2`) para ler depois no mesmo request.
- `GET_SUPPORTING_OBJECT_SCRIPT(p_application_id, p_script_type)` (function, CLOB) e procedure com `p_output_type` (`c_output_as_dbms_output` padrão ou `c_output_as_file`). Tipos: `c_install_script`, `c_upgrade_script`, `c_deinstall_script`. Exige workspace definido antes.
- `EXPORT_USERS(p_export_format DEFAULT 'UNIX')` (`'UNIX'` = LF, `'DOS'` = CRLF): exporta workspace, usuários e grupos; admin do workspace.
- `GET_APEX_OWNER`, `GET_DEFAULT_SCHEMA`: nomes de schema.

Fonte: [COUNT_CLICK Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/COUNT_CLICK-Procedure.html), [CLOSE_OPEN_DB_LINKS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CLOSE_OPEN_DB_LINKS-Procedure.html), [SAVEKEY_NUM Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SAVEKEY_NUM-Function.html), [GET_SUPPORTING_OBJECT_SCRIPT Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_SUPPORTING_OBJECT_SCRIPT-Function.html), [GET_SUPPORTING_OBJECT_SCRIPT Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_SUPPORTING_OBJECT_SCRIPT-Procedure.html), [EXPORT_USERS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/EXPORT_USERS-Procedure.html), [GET_APEX_OWNER Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_UTIL.GET_APEX_OWNER-Function.html)

### APEX_UTIL: APIs deprecated e o substituto de cada uma

| Deprecated | Use no lugar |
|---|---|
| `STRING_TO_TABLE` (retorna `APEX_APPLICATION_GLOBAL.VC_ARR2`) | `APEX_STRING.STRING_TO_TABLE` / `SPLIT` |
| `TABLE_TO_STRING` | `APEX_STRING.JOIN` / `JOIN_CLOB` |
| `PUBLIC_CHECK_AUTHORIZATION` | `APEX_AUTHORIZATION.IS_AUTHORIZED` |
| `RESET_AUTHORIZATIONS` | `APEX_AUTHORIZATION.RESET_CACHE` |
| `IR_CLEAR`, `IR_DELETE_REPORT`, `IR_DELETE_SUBSCRIPTION`, `IR_FILTER`, `IR_RESET` | `APEX_IR` |
| `GET_APPLICATION_STATUS`, `SET_APPLICATION_STATUS` | `APEX_APPLICATION_ADMIN` |
| `SET_APP_BUILD_STATUS` | `APEX_APPLICATION_ADMIN.SET_BUILD_STATUS` |
| `GET_BUILD_OPTION_STATUS` (2), `SET_BUILD_OPTION_STATUS` | `APEX_APPLICATION_ADMIN` |
| `GET_GLOBAL_NOTIFICATION`, `SET_GLOBAL_NOTIFICATION` | `APEX_APPLICATION_ADMIN` |
| `SET_CURRENT_THEME_STYLE` | `APEX_THEME.SET_CURRENT_STYLE` |
| `URL_ENCODE` | `UTL_URL.ESCAPE` |
| `CUSTOM_CALENDAR`, `INCREMENT_CALENDAR` | (sem substituto indicado; calendário legado) |
| `PREPARE_URL` (não deprecated, mas desaconselhado) | `APEX_PAGE.GET_URL` |

Status de app válidos em `SET_APPLICATION_STATUS` (para referência ao migrar): `AVAILABLE`, `AVAILABLE_W_EDIT_LINK`, `DEVELOPERS_ONLY`, `RESTRICTED_ACCESS`, `UNAVAILABLE`, `UNAVAILABLE_PLSQL`, `UNAVAILABLE_URL`. Ao mudar status de *Build Option* por API, marque *On Upgrade Keep Status* = Yes, senão um upgrade sobrescreve.

Fonte: [STRING_TO_TABLE Function (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/STRING_TO_TABLE-Function.html), [TABLE_TO_STRING Function (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/TABLE_TO_STRING-Function.html), [PUBLIC_CHECK_AUTHORIZATION Function (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PUBLIC_CHECK_AUTHORIZATION-Function-DEPRECATED.html), [RESET_AUTHORIZATIONS Procedure (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/RESET_AUTHORIZATIONS-Procedure-DEPRECATED.html), [IR_FILTER Procedure (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/IR_FILTER-Procedure-DEPRECATED.html), [SET_APPLICATION_STATUS Procedure (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_APPLICATION_STATUS-Procedure.html), [SET_BUILD_OPTION_STATUS Procedure (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_BUILD_OPTION_STATUS-Procedure.html), [URL_ENCODE Function (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/URL_ENCODE-Function.html), [SET_CURRENT_THEME_STYLE Procedure (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_CURRENT_THEME_STYLE-Procedure.html)
## APEX_STRING: split, join, push, format e property lists (apex_t_varchar2, apex_t_number, apex_t_clob)

`APEX_STRING` trabalha com os tipos coleção `apex_t_varchar2`, `apex_t_number`, `apex_t_clob` e com `varchar2`/`clob`. É o substituto oficial de `APEX_UTIL.STRING_TO_TABLE`/`TABLE_TO_STRING` e a forma recomendada de processar listas (ex.: valores de *Checkbox Group*/*Shuttle*/*Select Many*, separados por `:`). Salvo indicação contrária, as APIs esperam arrays **contínuos** (sem buracos criados por `coll.delete(n)`).

| Membro | O que faz |
|---|---|
| `SPLIT` (VARCHAR2 → `apex_t_varchar2`, com `p_limit`) | Quebra string por separador, caractere a caractere ou regex |
| `SPLIT` (CLOB → `apex_t_varchar2`) | Idem para CLOB |
| `SPLIT_NUMBERS` | Quebra em `apex_t_number` (todos os valores precisam ser números) |
| `SPLIT_CLOBS` | Quebra CLOB em `apex_t_clob` |
| `JOIN` (`apex_t_varchar2` e `apex_t_number`) | Concatena com separador (padrão LF) |
| `JOIN_CLOB` | Concatena `apex_t_varchar2` em CLOB |
| `JOIN_CLOBS` | Concatena `apex_t_clob` em CLOB |
| `PUSH` (7 assinaturas) | Acrescenta valor(es) a `apex_t_varchar2`/`apex_t_number`/`apex_t_clob` |
| `INDEX_OF` (`apex_t_varchar2` e `vc_arr2`) | Posição do primeiro valor igual (NULL se não achar) |
| `GREP` (tabela, VARCHAR2, CLOB) | Valores/trechos que casam com regex |
| `FORMAT` | Formata mensagem com `%s`, `%0..%19`, `%n` |
| `GET_INITIALS` | Iniciais das palavras ("John Doe" → "JD") |
| `GET_SEARCHABLE_PHRASES` | Frases de 1–3 palavras sem stopwords (busca simples) |
| `NEXT_CHUNK` | Lê CLOB em pedaços (wrapper seguro de `DBMS_LOB.READ`) |
| `SHUFFLE` (function e procedure) | Embaralha a tabela |
| `PLIST_GET`, `PLIST_GET_KEY`, `PLIST_EXISTS`, `PLIST_PUT`, `PLIST_PUSH`, `PLIST_DELETE` | Property list (chave, valor, chave, valor… numa `apex_t_varchar2`) |
| `PLIST_TO_JSON_CLOB` | Converte property list em objeto JSON |
| `STRING_TO_TABLE` | Split em `apex_application_global.vc_arr2` (para código legado) |
| `TABLE_TO_STRING` / `TABLE_TO_CLOB` | Join de `vc_arr2` em VARCHAR2/CLOB |

Fonte: [APEX_STRING](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_STRING.html)

### APEX_STRING.SPLIT e SPLIT_NUMBERS: transformar lista "1:2:3" em tabela (e usar em SQL)

```sql
APEX_STRING.SPLIT (
    p_str   IN VARCHAR2,
    p_sep   IN VARCHAR2     DEFAULT apex_application.LF,
    p_limit IN PLS_INTEGER  DEFAULT NULL )
RETURN apex_t_varchar2;

APEX_STRING.SPLIT ( p_str IN CLOB, p_sep IN VARCHAR2 DEFAULT apex_application.LF ) RETURN apex_t_varchar2;
APEX_STRING.SPLIT_NUMBERS ( p_str IN VARCHAR2, p_sep IN VARCHAR2 DEFAULT apex_application.LF ) RETURN apex_t_number;
APEX_STRING.SPLIT_CLOBS ( p_str IN CLOB, p_sep IN VARCHAR2 DEFAULT apex_application.LF,
                          p_limit IN PLS_INTEGER DEFAULT NULL ) RETURN apex_t_clob;
```

Regras de `p_sep`:
- padrão: quebra de linha (LF);
- `NULL`: quebra **após cada caractere** (`split('123', null)` → `'1','2','3'`);
- 1 caractere: quebra nesse caractere;
- mais de 1 caractere: é tratado como **expressão regular** (até 512 caracteres). Ex.: `split('key1=val1, key2=val2', '\s*[=,]\s*')` → `key1, val1, key2, val2`.

`p_limit`: número máximo de quebras; o último elemento recebe o resto (`split('1:2:3:4', ':', 2)` → `'1'`, `'2:3:4'`).

Pegadinha: separador de 2+ caracteres vira regex, então `'||'` ou `'.'`-like precisam ser escapados (`apex_escape.regexp`).

```sql
-- Item Checkbox Group P26_MEMBROS = '10:25:31'
insert into equipe_membro (id_equipe, id_colaborador)
select :P26_ID_EQUIPE, column_value
  from table(apex_string.split_numbers(:P26_MEMBROS, ':'));

-- Filtro em relatório com Select Many
select * from colaborador
 where id_empresa = :G_ID_EMPRESA
   and (:P12_DEPTOS is null
        or id_departamento in (select column_value
                                 from table(apex_string.split_numbers(:P12_DEPTOS, ':'))));
```

Fonte: [SPLIT Function Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SPLIT-Function-Signature-1.html), [SPLIT Function Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SPLIT-Function-Signature-2.html), [SPLIT_NUMBERS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SPLIT_NUMBERS-Function.html), [SPLIT_CLOBS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SPLIT_CLOBS-Function.html)

### APEX_STRING.JOIN, JOIN_CLOB, JOIN_CLOBS e PUSH: montar listas e textos

```sql
APEX_STRING.JOIN ( p_table IN apex_t_varchar2 | apex_t_number,
                   p_sep   IN VARCHAR2 DEFAULT apex_application.LF ) RETURN VARCHAR2;
APEX_STRING.JOIN_CLOB  ( p_table IN apex_t_varchar2, p_sep IN VARCHAR2 DEFAULT apex_application.LF,
                         p_dur IN PLS_INTEGER DEFAULT sys.dbms_lob.call ) RETURN CLOB;
APEX_STRING.JOIN_CLOBS ( p_table IN apex_t_clob, p_sep IN VARCHAR2 DEFAULT apex_application.LF,
                         p_dur IN PLS_INTEGER DEFAULT sys.dbms_lob.call ) RETURN CLOB;
```

`PUSH` (todas com `p_table IN OUT NOCOPY`):

| Assinatura | Tabela destino | Valor |
|---|---|---|
| 1 | `apex_t_varchar2` | `p_value VARCHAR2` |
| 2 | `apex_t_clob` | `p_value` (a doc mostra o tipo `apex_t_clob`; o exemplo passa um literal) |
| 3 | `apex_t_number` | `p_value NUMBER` |
| 4 | `apex_t_varchar2` | `p_values apex_t_varchar2` (concatena coleção) |
| 5 | `apex_t_clob` | `p_values apex_t_clob` |
| 6 | `apex_t_varchar2` | `p_values apex_application_global.vc_arr2` |
| 7 | `apex_t_varchar2` | `p_values apex_t_number` + `p_format_mask` |

`PUSH` funciona com a variável ainda não inicializada (`l_tab apex_t_varchar2;` sem construtor).

```sql
declare
    l_ids apex_t_varchar2;
begin
    for r in (select id_colaborador from colaborador where id_empresa = :G_ID_EMPRESA and id_gestor = :P3_ID) loop
        apex_string.push(l_ids, r.id_colaborador);
    end loop;
    :P3_SUBORDINADOS := apex_string.join(l_ids, ':');   -- formato de item multi-valor
end;
```

Fonte: [JOIN Function Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/JOIN-Function-Signature-1.html), [JOIN Function Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/JOIN-Function-Signature-2.html), [JOIN_CLOB Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/JOIN_CLOB-Function.html), [JOIN_CLOBS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/JOIN_CLOBS-Function.html), [PUSH Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PUSH-Procedure-Signature-1.html), [PUSH Procedure Signature 4](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PUSH-Procedure-Signature-4.html), [PUSH Procedure Signature 7](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PUSH-Procedure-Signature-7.html)

### APEX_STRING.FORMAT: mensagens com placeholders %s, %0..%19 e %n

```sql
APEX_STRING.FORMAT (
     p_message    IN VARCHAR2,
     p0 .. p19    IN VARCHAR2     DEFAULT NULL,
     p_max_length IN PLS_INTEGER  DEFAULT 1000,   -- corta cada pN e acrescenta '~'
     p_prefix     IN VARCHAR2     DEFAULT NULL )  -- remove espaços + prefixo do início de cada linha
RETURN VARCHAR2;
```

- O n-ésimo `%s` recebe `p<n>`; `%<n>` usa `p<n>` diretamente; `%%` = `%`; `%n` = nova linha.
- `p_prefix` facilita escrever texto multilinha indentado dentro do código (`q'!...!'` com `!` no começo de cada linha).

```sql
apex_string.format('%s+%s=%s', 1, 2, 'três')         -- 1+2=três
apex_string.format('%1+%2=%0', 'três', 1, 2)         -- 1+2=três
l_msg := apex_string.format('Olá %s,%nvocê tem %s solicitações pendentes.', l_nome, l_qtd);
```

Fonte: [FORMAT Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/FORMAT-Function.html)

### APEX_STRING.GREP, INDEX_OF, GET_INITIALS, NEXT_CHUNK e SHUFFLE

```sql
APEX_STRING.GREP (
   p_table | p_str IN apex_t_varchar2 | VARCHAR2 | CLOB,
   p_pattern       IN VARCHAR2,
   p_modifier      IN VARCHAR2    DEFAULT NULL,    -- ex.: 'i'
   p_subexpression IN VARCHAR2    DEFAULT '0',     -- NULL = valor inteiro; '0' = trecho casado; '1,2' = grupos
   p_limit         IN PLS_INTEGER DEFAULT NULL )
RETURN apex_t_varchar2;

APEX_STRING.INDEX_OF ( p_table IN apex_t_varchar2 | apex_application_global.vc_arr2,
                       p_value IN VARCHAR2 ) RETURN NUMBER;    -- NULL se não encontrado

APEX_STRING.GET_INITIALS ( p_str IN VARCHAR2, p_cnt IN PLS_INTEGER DEFAULT 2 ) RETURN VARCHAR2;  -- p_cnt 1..255

APEX_STRING.NEXT_CHUNK (
    p_str    IN            CLOB,
    p_chunk  OUT    NOCOPY VARCHAR2,
    p_offset IN OUT NOCOPY INTEGER,
    p_amount IN            INTEGER DEFAULT 8191 ) RETURN BOOLEAN;   -- FALSE ao passar do fim

APEX_STRING.SHUFFLE ( p_table IN apex_t_varchar2 ) RETURN apex_t_varchar2;   -- e procedure IN OUT
```

- `GREP` com `p_subexpression => '1,2'` devolve os grupos em sequência (ótimo para montar property lists).
- `GET_INITIALS` separa palavras por espaço, vírgula, hífen, aspas; com uma palavra só, devolve as primeiras letras. Útil para avatar de iniciais no organograma/cards ("Ana Souza" → "AS").
- `NEXT_CHUNK` evita erros de offset ao percorrer CLOB grande (ex.: `htp.prn` em pedaços). Inicie `p_offset` como NULL, igual ao exemplo da doc.

```sql
select nome_completo, apex_string.get_initials(nome_completo) as iniciais
  from colaborador where id_empresa = :G_ID_EMPRESA;
```

Fonte: [GREP Function Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GREP-Function-Signature-1.html), [GREP Function Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GREP-Function-Signature-2.html), [GREP Function Signature 3](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GREP-Function-Signature-3.html), [INDEX_OF Function Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/INDEX_OF-Function-Signature-1.html), [GET_INITIALS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_INITIALS-Function.html), [NEXT_CHUNK Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/NEXT_CHUNK-Function.html), [SHUFFLE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SHUFFLE-Function.html)

### APEX_STRING: property lists (PLIST_GET, PLIST_PUT, PLIST_PUSH, PLIST_DELETE, PLIST_TO_JSON_CLOB)

Uma *property list* é uma `apex_t_varchar2` com pares alternados: posições ímpares são chaves, pares são valores (`apex_t_varchar2('key1','foo','key2','bar')`).

```sql
APEX_STRING.PLIST_GET     ( p_table IN apex_t_varchar2, p_key IN VARCHAR2 ) RETURN VARCHAR2;     -- NO_DATA_FOUND se a chave não existe
APEX_STRING.PLIST_GET_KEY ( p_table IN apex_t_varchar2, p_value IN VARCHAR2 ) RETURN VARCHAR2;   -- 1ª chave com esse valor, ou NULL
APEX_STRING.PLIST_EXISTS  ( p_table IN apex_t_varchar2, p_key IN VARCHAR2 ) RETURN BOOLEAN;
APEX_STRING.PLIST_PUT     ( p_table IN OUT NOCOPY apex_t_varchar2, p_key IN VARCHAR2, p_value IN VARCHAR2 ); -- insere ou atualiza
APEX_STRING.PLIST_PUSH    ( p_table IN OUT NOCOPY apex_t_varchar2, p_key IN VARCHAR2, p_value IN VARCHAR2 ); -- acrescenta sem checar duplicata
APEX_STRING.PLIST_DELETE  ( p_table IN OUT NOCOPY apex_t_varchar2, p_key IN VARCHAR2 );        -- NO_DATA_FOUND se a chave não existe
APEX_STRING.PLIST_TO_JSON_CLOB ( p_plist IN apex_t_varchar2 ) RETURN CLOB;                     -- {"key1":"foo",...}
```

Notas: a doc lista `PLIST_PUT` como "Function", mas a assinatura é de procedure (IN OUT, sem RETURN); chame como procedure. A página de `PLIST_EXISTS` também cita `NO_DATA_FOUND` em *Raises*, embora o exemplo retorne FALSE para chave inexistente; trate os dois casos se depender disso.

```sql
declare
    l_p apex_t_varchar2;
begin
    apex_string.plist_put(l_p, 'status', 'ATIVO');
    apex_string.plist_put(l_p, 'empresa', :G_ID_EMPRESA);
    sys.htp.p(apex_string.plist_to_json_clob(l_p));   -- {"status":"ATIVO","empresa":"1"}
end;
```

Fonte: [PLIST_GET Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PLIST_GET-Function.html), [PLIST_GET_KEY Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_STRING.PLIST_GET_KEY-Function.html), [PLIST_EXISTS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_STRING.PLIST_EXISTS-Function.html), [PLIST_PUT Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PLIST_PUT-Function.html), [PLIST_PUSH Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PLIST_PUSH-Procedure.html), [PLIST_DELETE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PLIST_DELETE-Procedure.html), [PLIST_TO_JSON_CLOB Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PLIST_TO_JSON_CLOB-Function.html)

### APEX_STRING.GET_SEARCHABLE_PHRASES: palavras-chave para busca simples

```sql
APEX_STRING.GET_SEARCHABLE_PHRASES (
    p_strings   IN apex_t_varchar2,
    p_max_words IN PLS_INTEGER     DEFAULT 3,
    p_language  IN apex_t_varchar2 DEFAULT 'en' )   -- 'cn','de','en','es','fr','it','ja','ko','pt-br'
RETURN apex_t_varchar2;
```

Retorna frases distintas de 1 a `p_max_words` palavras em minúsculas, ignorando stopwords do idioma (que também quebram frases). É uma implementação PL/SQL mínima: para busca de verdade, a doc recomenda Oracle Text. Em pt-BR passe `p_language => apex_t_varchar2('pt-br')`.

Fonte: [GET_SEARCHABLE_PHRASES Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_SEARCHABLE_PHRASES-Function.html)

### APEX_STRING.STRING_TO_TABLE, TABLE_TO_STRING e TABLE_TO_CLOB: ponte com vc_arr2 legado

```sql
APEX_STRING.STRING_TO_TABLE ( p_str IN VARCHAR2, p_sep IN VARCHAR2 DEFAULT ':' )
    RETURN apex_application_global.vc_arr2;          -- separador literal, sem regex
APEX_STRING.TABLE_TO_STRING ( p_table IN apex_application_global.vc_arr2, p_sep IN VARCHAR2 DEFAULT ':' )
    RETURN VARCHAR2;                                  -- assume índice a partir de 1 e sem buracos
APEX_STRING.TABLE_TO_CLOB ( p_table IN apex_application_global.vc_arr2,
    p_sep IN VARCHAR2 DEFAULT apex_application.LF, p_dur IN PLS_INTEGER DEFAULT sys.dbms_lob.call ) RETURN CLOB;
```

Use quando o código lida com `vc_arr2` (ex.: arrays `G_Fnn`). Atenção às diferenças de default: aqui o separador padrão é `':'`, enquanto `SPLIT`/`JOIN` usam LF.

Fonte: [STRING_TO_TABLE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/STRING_TO_TABLE-1-Function.html), [TABLE_TO_STRING Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/TABLE_TO_STRING-1-Function.html), [TABLE_TO_CLOB Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/TABLE_TO_CLOB-Function.html)

## APEX_STRING_UTIL: utilitários extras de texto (diff, e-mails, links, tags, slug, tamanho de arquivo)

| Membro | O que faz |
|---|---|
| `DIFF` | Diferença entre duas `apex_t_varchar2` em formato tipo *unified diff* |
| `FIND_EMAIL_ADDRESSES` | Todos os e-mails de um texto, sem duplicatas |
| `FIND_EMAIL_FROM` | E-mail após o primeiro `From:` |
| `FIND_EMAIL_SUBJECT` | Texto do `Subject:` |
| `FIND_IDENTIFIERS` | Identificadores com prefixo + números (`ORA-02291`, `BUG 123`) |
| `FIND_LINKS` | Links http/https (opção só https) |
| `FIND_PHRASES` | Quais frases da lista aparecem no texto |
| `FIND_TAGS` | Tags com prefixo (`#`, `@`), em maiúsculas |
| `GET_DOMAIN` | Domínio de URL ou e-mail |
| `GET_FILE_EXTENSION` | Extensão do arquivo em minúsculas |
| `GET_SLUG` | Texto em formato slug (`hey-now-brown-cow-1`), opcional hash |
| `PHRASE_EXISTS` | Se a frase está no texto (ignora caixa, espaços e especiais) |
| `REPLACE_WHITESPACE` | Tokeniza: minúsculas e especiais trocados por separador |
| `TO_DISPLAY_FILESIZE` | Bytes em texto amigável (`1.2GB`) |

Fonte: [APEX_STRING_UTIL](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_STRING_UTIL.html)

### APEX_STRING_UTIL: assinaturas e exemplos (DIFF, FIND_*, GET_SLUG, TO_DISPLAY_FILESIZE)

```sql
APEX_STRING_UTIL.DIFF ( p_left IN apex_t_varchar2, p_right IN apex_t_varchar2,
                        p_context IN PLS_INTEGER DEFAULT 3 ) RETURN apex_t_varchar2;
APEX_STRING_UTIL.FIND_EMAIL_ADDRESSES ( p_string IN VARCHAR2 ) RETURN apex_t_varchar2;
APEX_STRING_UTIL.FIND_EMAIL_FROM      ( p_string IN VARCHAR2 ) RETURN VARCHAR2;
APEX_STRING_UTIL.FIND_EMAIL_SUBJECT   ( p_string IN VARCHAR2 ) RETURN VARCHAR2;
APEX_STRING_UTIL.FIND_IDENTIFIERS     ( p_string IN VARCHAR2, p_prefix IN VARCHAR2 ) RETURN apex_t_varchar2;
APEX_STRING_UTIL.FIND_LINKS ( p_string IN VARCHAR2, p_https_only IN BOOLEAN DEFAULT FALSE ) RETURN apex_t_varchar2;
APEX_STRING_UTIL.FIND_PHRASES ( p_phrases IN apex_t_varchar2, p_string IN VARCHAR2 ) RETURN apex_t_varchar2;
APEX_STRING_UTIL.FIND_TAGS ( p_string IN VARCHAR2, p_prefix IN VARCHAR2 DEFAULT '#',
                             p_exclude_numeric IN BOOLEAN DEFAULT TRUE ) RETURN apex_t_varchar2;
APEX_STRING_UTIL.GET_DOMAIN ( p_string IN VARCHAR2 ) RETURN VARCHAR2;
APEX_STRING_UTIL.GET_FILE_EXTENSION ( p_filename IN VARCHAR2 ) RETURN VARCHAR2;
APEX_STRING_UTIL.GET_SLUG ( p_string IN VARCHAR2, p_hash_length IN PLS_INTEGER DEFAULT 0 ) RETURN VARCHAR2;
APEX_STRING_UTIL.PHRASE_EXISTS ( p_phrase IN VARCHAR2, p_string IN VARCHAR2 ) RETURN BOOLEAN;
APEX_STRING_UTIL.REPLACE_WHITESPACE ( p_string IN VARCHAR, p_original_find IN VARCHAR2 DEFAULT NULL,
                                      p_whitespace_character IN VARCHAR2 DEFAULT '|' ) RETURN VARCHAR2;
APEX_STRING_UTIL.TO_DISPLAY_FILESIZE ( p_size_in_bytes IN NUMBER ) RETURN VARCHAR2;
```

Detalhes úteis:
- `DIFF`: cada linha de saída começa com `@` (números de linha), espaço (contexto igual), `-` (só à esquerda) ou `+` (só à direita). Algoritmo LCS sem otimização: **não use para entradas muito grandes**.
- `FIND_TAGS` devolve em maiúsculas; com `p_exclude_numeric => TRUE` ignora `#123`. Bom para hashtags em comunicados/chat.
- `GET_SLUG`: no máximo 255 caracteres; `p_hash_length > 0` acrescenta dígitos aleatórios (até 38) para unicidade.
- `FIND_PHRASES`/`PHRASE_EXISTS`/`FIND_IDENTIFIERS` ignoram caixa, espaços e caracteres especiais (`sqldeveloper` casa com `sql developer`).

```sql
select apex_string_util.get_slug('Comunicado: Férias coletivas 2026', 4) slug,
       apex_string_util.to_display_filesize(dbms_lob.getlength(arquivo)) tamanho,
       apex_string_util.get_file_extension(nome_arquivo) ext
  from anexo_comunicado
 where id_empresa = :G_ID_EMPRESA;
```

Fonte: [DIFF Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_STRING_UTIL-DIFF-Function.html), [FIND_EMAIL_ADDRESSES Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/FIND_EMAIL_ADDRESSES-Function.html), [FIND_TAGS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/FIND_TAGS-Function.html), [FIND_LINKS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/FIND_LINKS-Function.html), [GET_SLUG Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_SLUG-Function.html), [PHRASE_EXISTS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PHRASE_EXISTS-Function.html), [REPLACE_WHITESPACE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/REPLACE_WHITESPACE-Function.html), [TO_DISPLAY_FILESIZE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/TO_DISPLAY_FILESIZE-Function.html), [GET_FILE_EXTENSION Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_FILE_EXTENSION-Function.html), [GET_DOMAIN Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_DOMAIN-Function.html), [FIND_IDENTIFIERS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/FIND_IDENTIFIERS-Function.html), [FIND_PHRASES Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/FIND_PHRASES-Function.html), [FIND_EMAIL_FROM Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/FIND_EMAIL_FROM-Function.html), [FIND_EMAIL_SUBJECT Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/FIND_EMAIL_SUBJECT-Function.html)
## APEX_JSON: ler (parse/get_*) e gerar (open/write/close) JSON em PL/SQL

`APEX_JSON` faz duas coisas:
1. **Leitura**: `PARSE` converte VARCHAR2/CLOB num formato interno (`t_values`); depois `GET_VARCHAR2`, `GET_NUMBER`, `GET_DATE`, `GET_BOOLEAN`, `GET_CLOB`, `GET_COUNT`, `GET_MEMBERS`… acessam os valores por *path*, e `FIND_PATHS_LIKE` busca. `TO_XMLTYPE` converte para XML (para usar `XMLTABLE`).
2. **Escrita**: `OPEN_OBJECT`/`OPEN_ARRAY`, `WRITE` (21 assinaturas) e `CLOSE_*` geram JSON no buffer `SYS.HTP` (padrão, ideal para processos Ajax) ou num CLOB temporário (`INITIALIZE_CLOB_OUTPUT` / `GET_CLOB_OUTPUT` / `FREE_OUTPUT`).

Fonte: [APEX_JSON](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_JSON.html), [APEX_JSON Overview and Examples](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/Package-Overview-and-Examples.html)

### APEX_JSON: tabela de todos os membros

| Membro | Tipo | O que faz |
|---|---|---|
| `t_kind`, `c_null`(1), `c_true`(2), `c_false`(3), `c_number`(4), `c_varchar2`(5), `c_object`(6), `c_array`(7), `c_clob`(8) | Subtipo/constantes | Tipo de cada valor parseado |
| `t_value` | Record | `kind`, `number_value`, `varchar2_value`, `clob_value`, `object_members apex_t_varchar2` |
| `t_values` | Tabela | `table of t_value index by varchar2(32767)` (chave = path) |
| `g_values` | Variável | Tabela global padrão usada quando `p_values` é omitido |
| `c_date_iso8601` | Constante | `'yyyy-mm-dd"T"hh24:mi:ss"Z"'` |
| `e_parse_error` | Exceção | `-20987`, levantada pelo `PARSE` |
| `PARSE` (2 assinaturas × VARCHAR2/CLOB) | Procedure | Parseia para `p_values` ou para `g_values` |
| `GET_VARCHAR2`, `GET_NUMBER`, `GET_DATE`, `GET_BOOLEAN`, `GET_CLOB` | Function | Valor escalar no path |
| `GET_VALUE` | Function | `t_value` no path (atributos nulos se não existe) |
| `GET_VALUE_KIND` | Function | `t_kind` no path (NULL se não existe) |
| `GET_COUNT` | Function | Nº de elementos do array / membros do objeto |
| `GET_MEMBERS` | Function | Nomes dos membros de um objeto |
| `GET_T_VARCHAR2`, `GET_T_NUMBER` | Function | Array como `apex_t_varchar2`/`apex_t_number` |
| `GET_SDO_GEOMETRY` | Function | GeoJSON → `SDO_GEOMETRY` (requer Oracle Locator) |
| `DOES_EXIST` | Function | Se o path existe |
| `FIND_PATHS_LIKE` | Function | Paths que casam com um padrão (e opcionalmente subpath/valor) |
| `TO_MEMBER_NAME` | Function | Escapa nome de membro para usar em path |
| `TO_XMLTYPE`, `TO_XMLTYPE_SQL` | Function | JSON → `XMLTYPE` (a versão SQL aceita `p_strict` 'Y'/'N') |
| `STRINGIFY` (VARCHAR2, NUMBER, DATE, BOOLEAN, SDO_GEOMETRY) | Function | Valor → literal JSON escapado |
| `INITIALIZE_OUTPUT` | Procedure | Configura saída HTP (headers, cache, indentação) |
| `INITIALIZE_CLOB_OUTPUT` | Procedure | Redireciona a saída para um CLOB temporário |
| `GET_CLOB_OUTPUT` | Function | Devolve o CLOB gerado (`p_free` opcional) |
| `FREE_OUTPUT` | Procedure | Libera o CLOB e restaura a saída anterior |
| `FLUSH` | Procedure | Descarrega o que está pendente |
| `OPEN_OBJECT`, `OPEN_ARRAY` | Procedure | Abre `{` / `[` (com nome opcional) |
| `CLOSE_OBJECT`, `CLOSE_ARRAY`, `CLOSE_ALL` | Procedure | Fecha `}` / `]` / tudo |
| `WRITE` (21 assinaturas) | Procedure | Escreve valores, atributos, cursores, XML, `t_values`, arrays, BLOB (Base64) |
| `WRITE_CONTEXT` | Procedure | Escreve as linhas de um contexto `APEX_EXEC` como array |

Fonte: [Constants and Data Types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_JSON-Constants-and-Data-Types.html), [APEX_JSON](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_JSON.html)

### APEX_JSON.PARSE: assinaturas, modo strict e a exceção e_parse_error (-20987)

```sql
-- Assinatura 1: resultado numa variável local
APEX_JSON.PARSE (
    p_values   IN OUT NOCOPY t_values,
    p_source   IN VARCHAR2 | CLOB,
    p_strict   IN BOOLEAN DEFAULT TRUE );

-- Assinatura 2: resultado no global g_values (dispensa p_values nos GET_*)
APEX_JSON.PARSE (
    p_source   IN VARCHAR2 | CLOB,
    p_strict   IN BOOLEAN DEFAULT TRUE );
```

- `p_strict => TRUE` (padrão) aplica as regras estritas de JSON; `FALSE` aceita, por exemplo, nomes de membro sem aspas.
- JSON inválido levanta `apex_json.e_parse_error` (`ORA-20987`).
- Prefira a assinatura 1 (variável local) em código de package reutilizável: `g_values` é global da sessão e pode ser sobrescrito por outro `PARSE`.

```sql
declare
    l_json apex_json.t_values;
begin
    apex_json.parse(p_values => l_json, p_source => :P16_RESPOSTA_VIACEP);
    :P16_LOGRADOURO := apex_json.get_varchar2(p_values => l_json, p_path => 'logradouro');
    :P16_CIDADE     := apex_json.get_varchar2(p_values => l_json, p_path => 'localidade');
exception
    when apex_json.e_parse_error then
        apex_error.add_error(p_message => 'Resposta inválida do serviço de CEP.',
                             p_display_location => apex_error.c_inline_in_notification);
end;
```

Fonte: [PARSE Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PARSE-Procedure-Signature-1.html), [PARSE Procedure Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PARSE-Procedure-Signature-2.html), [Constants and Data Types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_JSON-Constants-and-Data-Types.html)

### APEX_JSON.GET_VARCHAR2, GET_NUMBER, GET_DATE, GET_BOOLEAN, GET_CLOB: sintaxe de path e placeholders

Todas compartilham a forma:

```sql
APEX_JSON.GET_VARCHAR2 (            -- idem GET_NUMBER, GET_BOOLEAN, GET_CLOB, GET_DATE
    p_path    IN VARCHAR2,
    p0 .. p4  IN VARCHAR2 DEFAULT NULL,
    p_default IN <tipo>   DEFAULT NULL,   -- valor se o membro não existe
    p_values  IN t_values DEFAULT g_values )
RETURN <tipo>;

APEX_JSON.GET_DATE ( ..., p_default IN DATE DEFAULT NULL,
                     p_format IN VARCHAR2 DEFAULT NULL, p_values ... ) RETURN DATE;
```

Path:
- objeto: `'a.b.c'`; raiz: `'.'`;
- array: **base 1**, `'items[1]'`, `'coord[2]'`;
- placeholders: cada `%N` vira `pN`, e o i-ésimo `%s` ou `%d` vira `p[i-1]`: `p_path => 'items[%d].foo', p0 => 3`;
- membro com caracteres especiais: use `TO_MEMBER_NAME` (nomes que não são identificadores simples `A-Z, 0-9, _` precisam de aspas).

Conversões e erros:

| Função | Conversão | `VALUE_ERROR` quando |
|---|---|---|
| `GET_VARCHAR2` | converte boolean e number | o valor é array/objeto |
| `GET_CLOB` | converte varchar2, boolean, number | o valor é array/objeto |
| `GET_NUMBER` | — | o valor não é número |
| `GET_BOOLEAN` | — (retorna TRUE/FALSE/NULL) | o valor não é boolean |
| `GET_DATE` | usa `p_format` (ISO 8601 no exemplo) | o valor não é data |

Pegadinha: na doc, `GET_NUMBER` e `GET_VARCHAR2` declaram `p_default IN BOOLEAN`; para não depender disso, teste com `DOES_EXIST` ou trate o NULL retornado.

```sql
apex_json.parse(l_json, '{ "items": [ 1, 2, { "foo": 42, "quando": "2026-10-21T10:08:00Z" } ] }');
l_num  := apex_json.get_number  (p_values => l_json, p_path => 'items[%d].foo', p0 => 3);    -- 42
l_data := apex_json.get_date    (p_values => l_json, p_path => 'items[3].quando');
l_txt  := apex_json.get_varchar2(p_values => l_json, p_path => 'items[1]');                  -- '1'
```

Fonte: [GET_VARCHAR2 Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_JSON.GET_VARCHAR2-Function.html), [GET_NUMBER Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_JSON.GET_NUMBER-Function.html), [GET_DATE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_DATE-Function.html), [GET_BOOLEAN Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_BOOLEAN-Function.html), [GET_CLOB Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_JSON.GET_CLOB-Function.html), [TO_MEMBER_NAME Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/To_MEMBER_NAME-Function.html)

### APEX_JSON.GET_COUNT, GET_MEMBERS, GET_VALUE, GET_VALUE_KIND e DOES_EXIST: percorrer estruturas

```sql
APEX_JSON.GET_COUNT      ( p_path, p0..p4, p_values ) RETURN NUMBER;          -- NULL se não achar
APEX_JSON.GET_MEMBERS    ( p_path, p0..p4, p_values ) RETURN apex_t_varchar2;  -- nomes dos membros
APEX_JSON.GET_VALUE      ( p_path, p0..p4, p_values ) RETURN t_value;          -- campos nulos se não achar
APEX_JSON.GET_VALUE_KIND ( p_path, p0..p4, p_values ) RETURN t_kind;           -- NULL se não achar
APEX_JSON.DOES_EXIST     ( p_path, p0..p4, p_values ) RETURN BOOLEAN;
APEX_JSON.GET_T_VARCHAR2 ( p_path, p0..p4, p_values ) RETURN apex_t_varchar2;
APEX_JSON.GET_T_NUMBER   ( p_path, p0..p4, p_values ) RETURN apex_t_number;
```

- `GET_COUNT('.')` conta os membros da raiz; num array, o número de elementos (o `t_value` de um array guarda o tamanho em `number_value`).
- `GET_T_VARCHAR2`/`GET_T_NUMBER`: se o path for array, devolvem os elementos; se for escalar conversível, devolvem uma tabela com um elemento só. `VALUE_ERROR` em erro de conversão.

```sql
-- Iterar um array de objetos
apex_json.parse(l_json, l_resposta);
for i in 1 .. nvl(apex_json.get_count(p_values => l_json, p_path => 'colaboradores'), 0) loop
    insert into stg_colaborador(nome, email)
    values (apex_json.get_varchar2(p_values => l_json, p_path => 'colaboradores[%d].nome',  p0 => i),
            apex_json.get_varchar2(p_values => l_json, p_path => 'colaboradores[%d].email', p0 => i));
end loop;
```

Fonte: [GET_COUNT Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_COUNT-Function.html), [GET_MEMBERS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_MEMBERS-Function.html), [GET_VALUE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_JSON.GET_VALUE-Function.html), [GET_VALUE_KIND Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_VALUE_KIND-Function.html), [DOES_EXIST Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/DOES_EXIST-Function.html), [GET_T_VARCHAR2 Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_T_VARCHAR2-Function.html), [GET_T_NUMBER Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_T_NUMBER-Function.html)

### APEX_JSON.FIND_PATHS_LIKE: buscar elementos por padrão de path e valor

```sql
APEX_JSON.FIND_PATHS_LIKE (
    p_return_path IN VARCHAR2,                 -- padrão do path retornado, ex.: 'items[%]'
    p_subpath     IN VARCHAR2 DEFAULT NULL,    -- padrão abaixo dele, ex.: '.magical'
    p_value       IN VARCHAR2 DEFAULT NULL,    -- padrão do valor, ex.: 'true'
    p_values      IN t_values DEFAULT g_values )
RETURN apex_t_varchar2;
```

Devolve os paths (ex.: `items[1]`) que casam; depois use-os em `GET_*` (`l_paths(i) || '.name'`).

Fonte: [FIND_PATHS_LIKE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/FIND_PATHS_LIKE-Function.html)

### APEX_JSON.TO_XMLTYPE e TO_XMLTYPE_SQL: consultar JSON com XMLTABLE

```sql
APEX_JSON.TO_XMLTYPE     ( p_source IN VARCHAR2 | CLOB, p_strict IN BOOLEAN  DEFAULT TRUE ) RETURN sys.xmltype;
APEX_JSON.TO_XMLTYPE_SQL ( p_source IN VARCHAR2 | CLOB, p_strict IN VARCHAR2 DEFAULT 'Y'  ) RETURN sys.xmltype;
```

O JSON vira `<json>` com arrays em `<row>`. `TO_XMLTYPE_SQL` existe porque SQL não aceita BOOLEAN: passe `p_strict => 'N'` para modo LAX.

```sql
select col1, col2
  from xmltable('/json/row'
        passing apex_json.to_xmltype('[{"col1": 1, "col2": "hello"},{"col1": 2, "col2": "world"}]')
        columns col1 number      path '/row/col1',
                col2 varchar2(5) path '/row/col2');
```

Fonte: [TO_XMLTYPE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/TO_XMLTYPE-Function.html), [TO_XMLTYPE_SQL Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/TO_XMLTYPE_SQL-Function.html), [APEX_JSON Overview and Examples](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/Package-Overview-and-Examples.html)

### APEX_JSON: gerar JSON para um processo Ajax Callback (OPEN_OBJECT, WRITE, CLOSE_ALL)

Por padrão a saída vai para `SYS.HTP` já com header `application/json` e `Cache-Control: no-cache`: basta escrever.

```sql
APEX_JSON.OPEN_OBJECT ( p_name IN VARCHAR2 DEFAULT NULL );   -- "nome": {   (ou só { )
APEX_JSON.OPEN_ARRAY  ( p_name IN VARCHAR2 DEFAULT NULL );   -- "nome": [   (ou só [ )
APEX_JSON.CLOSE_OBJECT;  APEX_JSON.CLOSE_ARRAY;  APEX_JSON.CLOSE_ALL;
APEX_JSON.FLUSH;          -- os CLOSE_* já fazem flush
```

```sql
-- Processo Ajax Callback "GET_EQUIPE"; JS: apex.server.process('GET_EQUIPE', {x01: id})
declare
    l_id number := to_number(apex_application.g_x01 default null on conversion error);
begin
    apex_json.open_object;
    apex_json.write('ok', true);
    apex_json.open_array('membros');
    for r in (select c.id_colaborador, c.nome_completo
                from equipe_membro m join colaborador c on c.id_colaborador = m.id_colaborador
               where m.id_equipe = l_id and c.id_empresa = :G_ID_EMPRESA) loop
        apex_json.open_object;
        apex_json.write('id',   r.id_colaborador);
        apex_json.write('nome', r.nome_completo);
        apex_json.close_object;
    end loop;
    apex_json.close_all;
end;
```

Vírgulas entre elementos são inseridas automaticamente. Saída do `WRITE` com cursor gera nomes de coluna em **maiúsculas** (`"DEPTNO"`), como no exemplo da doc; um alias entre aspas no SELECT controla o nome.

Fonte: [OPEN_OBJECT Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/OPEN_OBJECT-Procedure.html), [OPEN_ARRAY Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/OPEN_ARRAY-Procedure.html), [CLOSE_ALL Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CLOSE_ALL-Procedure.html), [CLOSE_OBJECT Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CLOSE_OBJECT-Procedure.html), [CLOSE_ARRAY Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CLOSE_ARRAY-Procedure.html), [FLUSH Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/FLUSH-Procedure.html), [INITIALIZE_OUTPUT Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/INITIALIZE_OUTPUT-Procedure.html)

### APEX_JSON.WRITE: as 21 assinaturas (valores, atributos, cursor, XML, arrays, BLOB)

| # | Forma | Escreve |
|---|---|---|
| 1–5 | `WRITE(p_value)` VARCHAR2, CLOB, NUMBER, DATE (+`p_format`), BOOLEAN | Elemento de array |
| 6 | `WRITE(p_value sys.xmltype)` | Elemento de array a partir de XML |
| 7 | `WRITE(p_cursor IN OUT sys_refcursor)` | Array com um objeto por linha |
| 8 | `WRITE(p_value mdsys.sdo_geometry)` | Elemento GeoJSON (requer Locator) |
| 9–13 | `WRITE(p_name, p_value, p_write_null DEFAULT FALSE)` VARCHAR2, CLOB, NUMBER, DATE (+`p_format`), BOOLEAN | Atributo de objeto |
| 14 | `WRITE(p_name, p_cursor)` | Atributo cujo valor é o array das linhas do cursor |
| 15 | `WRITE(p_name, p_value sys.xmltype, p_write_null)` | Atributo a partir de XML |
| 16 | `WRITE(p_values t_values, p_path DEFAULT '.', p0..p4)` | Parte de um JSON parseado |
| 17 | `WRITE(p_name, p_values, p_path, p0..p4, p_write_null)` | Parte de um JSON parseado como atributo |
| 18 | `WRITE(p_name, p_values apex_t_varchar2, p_write_null)` | Atributo array de strings |
| 19 | `WRITE(p_name, p_values apex_t_number, p_write_null)` | Atributo array de números |
| 20 | `WRITE(p_name, p_value BLOB, p_write_null)` | Atributo BLOB em **Base64** |
| 21 | `WRITE(p_name, p_value mdsys.sdo_geometry, p_write_null)` | Atributo GeoJSON |

Regras de comportamento:
- `p_write_null => FALSE` (padrão) **omite** o atributo quando o valor é NULL (nas assinaturas 18/19/20, omite o array vazio). Se o front-end espera a chave sempre presente, passe `TRUE`.
- Datas saem no formato `c_date_iso8601` (`2014-05-05T05:36:08Z`); `LOCALTIMESTAMP`/`CURRENT_TIMESTAMP` saem com fração e fuso.
- Cursor (7 e 14): colunas VARCHAR2 com valor `'TRUE'`/`'FALSE'` (qualquer caixa) viram boolean; colunas de objeto, coleção ou `CURSOR()` aninhado são convertidas via XML.
- XML (6 e 15): vazio → null; `TRUE`/`FALSE` → boolean; se a função XPath `number` aceita → número; senão string.

```sql
declare
    c sys_refcursor;
begin
    open c for select id_departamento "id", nome "nome"
                 from departamento where id_empresa = :G_ID_EMPRESA;
    apex_json.open_object;
    apex_json.write('departamentos', c);      -- "departamentos":[{"id":1,"nome":"RH"},...]
    apex_json.close_object;
end;
```

Fonte: [WRITE Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/WRITE-Procedure-Signature-1.html), [WRITE Procedure Signature 7](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/WRITE-Procedure-Signature-7.html), [WRITE Procedure Signature 9](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/WRITE-Procedure-Signature-9.html), [WRITE Procedure Signature 14](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/WRITE-Procedure-Signature-14.html), [WRITE Procedure Signature 15](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/WRITE-Procedure-Signature-15.html), [WRITE Procedure Signature 16](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/WRITE-Procedure-Signature-16.html), [WRITE Procedure Signature 17](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/WRITE-Procedure-Signature-17.html), [WRITE Procedure Signature 18](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/WRITE-Procedure-Signature-18.html), [WRITE Procedure Signature 19](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/WRITE-Procedure-Signature-19.html), [WRITE Procedure Signature 20](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/WRITE-Procedure-Signature-20.html)

### APEX_JSON.INITIALIZE_CLOB_OUTPUT, GET_CLOB_OUTPUT e FREE_OUTPUT: gerar JSON num CLOB

```sql
APEX_JSON.INITIALIZE_CLOB_OUTPUT (
    p_dur      IN PLS_INTEGER DEFAULT sys.dbms_lob.call,   -- ou dbms_lob.session
    p_cache    IN BOOLEAN     DEFAULT TRUE,
    p_indent   IN PLS_INTEGER DEFAULT NULL,                -- 2 com debug ligado, 0 sem
    p_preserve IN BOOLEAN     DEFAULT FALSE );
APEX_JSON.GET_CLOB_OUTPUT ( p_free IN BOOLEAN DEFAULT FALSE ) RETURN CLOB;
APEX_JSON.FREE_OUTPUT;
```

- Use quando o JSON vai para uma tabela, uma chamada REST (`APEX_WEB_SERVICE`), um item, ou quando o código roda **fora de uma sessão APEX** (a doc avisa que, sem contexto APEX, é preciso inicializar a saída antes de escrever).
- Sempre chame `FREE_OUTPUT` (ou `GET_CLOB_OUTPUT(p_free => TRUE)`).
- `p_preserve => TRUE`: se a saída HTP já estava ativa e você precisa de um CLOB no meio (ex.: dentro de um Ajax que também responde JSON), preserve e, depois do `FREE_OUTPUT`, a escrita volta para o HTP. Com `p_preserve => TRUE` o `FREE_OUTPUT` é **obrigatório**.

```sql
declare
    l_payload clob;
begin
    apex_json.initialize_clob_output(p_preserve => true);
    apex_json.open_object;
    apex_json.write('evento', 'MOVIMENTACAO');
    apex_json.write('id_colaborador', :P18_ID_COLABORADOR);
    apex_json.close_object;
    l_payload := apex_json.get_clob_output(p_free => true);
    insert into log_evento(id_empresa, payload) values (:G_ID_EMPRESA, l_payload);
end;
```

Fonte: [INITIALIZE_CLOB_OUTPUT Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/INITIALIZE_CLOB_OUTPUT-Procedure.html), [GET_CLOB_OUTPUT Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_CLOB_OUTPUT-Function.html), [FREE_OUTPUT Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/FREE_OUTPUT-Procedure.html)

### APEX_JSON.INITIALIZE_OUTPUT: headers HTTP, cache e status customizado

```sql
APEX_JSON.INITIALIZE_OUTPUT (
    p_http_header     IN BOOLEAN     DEFAULT TRUE,    -- escreve mime application/json
    p_http_cache      IN BOOLEAN     DEFAULT FALSE,   -- TRUE: max-age=315360000; FALSE: no-cache
    p_http_cache_etag IN VARCHAR2    DEFAULT NULL,    -- etag, só com p_http_cache TRUE
    p_indent          IN PLS_INTEGER DEFAULT NULL );
```

Só é necessário para mudar os defaults. Para devolver um status HTTP diferente (ex.: 429), desligue o header e escreva-o você mesmo:

```sql
apex_json.initialize_output(p_http_header => false);
sys.owa_util.mime_header('application/json', false);
sys.owa_util.status_line(429, 'Too Many Requests');
sys.owa_util.http_header_close;
apex_json.open_object;
apex_json.write('maxRequestsPerSecond', 10);
apex_json.close_object;
```

Fonte: [INITIALIZE_OUTPUT Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/INITIALIZE_OUTPUT-Procedure.html)

### APEX_JSON.STRINGIFY e WRITE_CONTEXT: literais JSON e saída de APEX_EXEC

```sql
APEX_JSON.STRINGIFY ( p_value IN VARCHAR2 ) RETURN VARCHAR2;     -- string escapada com aspas
APEX_JSON.STRINGIFY ( p_value IN NUMBER ) RETURN VARCHAR2;
APEX_JSON.STRINGIFY ( p_value IN DATE, p_format IN VARCHAR2 DEFAULT c_date_iso8601 ) RETURN VARCHAR2;
APEX_JSON.STRINGIFY ( p_value IN BOOLEAN ) RETURN VARCHAR2;      -- true / false
APEX_JSON.STRINGIFY ( p_value IN mdsys.sdo_geometry ) RETURN CLOB;  -- GeoJSON (Locator)

APEX_JSON.WRITE_CONTEXT (
    p_name       IN VARCHAR2,
    p_context    IN apex_exec.t_context,    -- de APEX_EXEC.OPEN_QUERY_CONTEXT
    p_write_null IN BOOLEAN DEFAULT FALSE );
```

`STRINGIFY` serve para montar JSON em SQL (`select apex_json.stringify(nome) from ...`). `WRITE_CONTEXT` escreve um array de objetos a partir de uma consulta do `APEX_EXEC` (local, REST Data Source…); diferente do cursor, **levanta erro** se houver colunas de objeto, coleção ou cursor.

Fonte: [STRINGIFY Function Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/STRINGIFY-Function-Signature-1.html), [STRINGIFY Function Signature 3](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/STRINGIFY-Function-Signature-3.html), [STRINGIFY Function Signature 4](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/STRINGIFY-Function-Signature-4.html), [WRITE_CONTEXT Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/WRITE_CONTEXT-Procedure.html), [GET_SDO_GEOMETRY Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_SDO_GEOMETRY-Function.html)
## APEX_COLLECTION: coleções de sessão (tabela temporária por usuário/sessão/app)

Uma *collection* é um "balde" nomeado de linhas temporárias ligado ao **usuário + sessão + aplicação**. Cada membro tem até 50 atributos texto (`C001..C050`, `VARCHAR2(4000)`), 5 números (`N001..N005`), 5 datas (`D001..D005`), 1 `CLOB001`, 1 `BLOB001`, 1 `XMLTYPE001` e um `SEQ_ID`. Com `MAX_STRING_SIZE=EXTENDED` (e APEX instalado assim), os `Cnnn` aceitam até 32.767 bytes.

Quando usar (segundo a doc): wizards de várias etapas que juntam linhas antes de gravar numa única transação; telas de edição de vários detalhes que só são aplicados no final; carrinho de compras. Quando **não** usar: como armazenamento permanente, ou para dados compartilhados entre usuários/sessões (cada sessão vê só as suas coleções).

Fonte: [APEX_COLLECTION](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_COLLECTION.html), [About the APEX_COLLECTION API](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/About-the-APEX_COLLECTION-API.html)

### APEX_COLLECTION: tabela de todos os membros

| Membro | O que faz |
|---|---|
| `CREATE_COLLECTION` | Cria coleção vazia (`p_truncate_if_exists`) |
| `CREATE_OR_TRUNCATE_COLLECTION` | Cria, ou esvazia se já existir |
| `CREATE_COLLECTION_FROM_QUERY` | Cria a partir de query (até 50 colunas → `C001..C050`), com MD5 opcional |
| `CREATE_COLLECTION_FROM_QUERY2` | Idem, mas as 5 primeiras colunas vão para `N001..N005`, as 5 seguintes para `D001..D005` |
| `CREATE_COLLECTION_FROM_QUERY_B` (com e sem binds) | Versão *bulk* (muito mais rápida), sem MD5 |
| `CREATE_COLLECTION_FROM_QUERYB2` (com e sem binds) | Bulk com 5 números + 5 datas + texto |
| `ADD_MEMBER` (procedure e function) | Acrescenta um membro (a function devolve o `SEQ_ID`) |
| `ADD_MEMBERS` | Acrescenta vários membros a partir de arrays |
| `UPDATE_MEMBER` | Atualiza um membro (**anula** atributos não informados) |
| `UPDATE_MEMBERS` | Atualiza vários membros por arrays (`p_seq`) |
| `UPDATE_MEMBER_ATTRIBUTE` (6 assinaturas) | Atualiza um único atributo (texto, CLOB, BLOB, XMLTYPE, NUMBER, DATE) |
| `MERGE_MEMBERS` | Sincroniza a coleção com arrays (insere/atualiza/apaga) |
| `DELETE_MEMBER` | Apaga um membro por `SEQ_ID` |
| `DELETE_MEMBERS` | Apaga membros onde `Cnnn` = valor |
| `TRUNCATE_COLLECTION` | Esvazia a coleção |
| `DELETE_COLLECTION` | Apaga a coleção |
| `DELETE_ALL_COLLECTIONS` | Apaga todas as coleções do usuário/sessão na app atual |
| `DELETE_ALL_COLLECTIONS_SESSION` | Apaga todas as coleções da sessão, de qualquer app |
| `COLLECTION_EXISTS` | Se a coleção existe |
| `COLLECTION_MEMBER_COUNT` | Nº de membros (não dá erro se a coleção não existe) |
| `COLLECTION_HAS_CHANGED` | Se mudou desde a criação/reset do flag |
| `RESET_COLLECTION_CHANGED` / `RESET_COLLECTION_CHANGED_ALL` | Zera o flag de alteração (uma / todas) |
| `GET_MEMBER_MD5` | MD5 atual de um membro (comparar com `MD5_ORIGINAL`) |
| `MOVE_MEMBER_UP` / `MOVE_MEMBER_DOWN` | Troca o `SEQ_ID` com o vizinho (+1 / −1) |
| `RESEQUENCE_COLLECTION` | Remove buracos nos `SEQ_ID` (1,2,3,5,8 → 1..5) |
| `SORT_MEMBERS` | Reordena por uma coluna (1..50) e renumera sem buracos |

Fonte: [APEX_COLLECTION](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_COLLECTION.html)

### APEX_COLLECTION: consultar a view APEX_COLLECTIONS (nome sempre em maiúsculas)

Os membros são lidos pela view `APEX_COLLECTIONS`, com colunas `COLLECTION_NAME`, `SEQ_ID`, `C001..C050`, `N001..N005`, `D001..D005`, `CLOB001`, `BLOB001`, `XMLTYPE001`, `MD5_ORIGINAL`. A view já filtra pela sessão/app correntes.

**Pegadinha:** os nomes das coleções são convertidos para **maiúsculas**. A API aceita qualquer caixa, mas no `WHERE` da view use maiúsculas.

```sql
select seq_id, c001 as nome, n001 as id_colaborador, d001 as data_inicio
  from apex_collections
 where collection_name = 'MEMBROS_EQUIPE'    -- maiúsculas!
 order by seq_id;
```

Fonte: [Accessing a Collection](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/Accessing-a-Collection.html)

### APEX_COLLECTION.CREATE_COLLECTION e CREATE_OR_TRUNCATE_COLLECTION

```sql
APEX_COLLECTION.CREATE_COLLECTION (
    p_collection_name    IN VARCHAR2,                -- até 255 caracteres
    p_truncate_if_exists IN VARCHAR2 DEFAULT 'NO' ); -- 'YES' esvazia em vez de dar erro
APEX_COLLECTION.CREATE_OR_TRUNCATE_COLLECTION ( p_collection_name IN VARCHAR2 );
APEX_COLLECTION.COLLECTION_EXISTS ( p_collection_name IN VARCHAR2 ) RETURN BOOLEAN;
```

`CREATE_COLLECTION` sem `p_truncate_if_exists => 'YES'` levanta erro de aplicação se a coleção já existe para o usuário/sessão/app. Padrão seguro no *Before Header* de um wizard:

```sql
apex_collection.create_or_truncate_collection(p_collection_name => 'MEMBROS_EQUIPE');
```

Fonte: [CREATE_COLLECTION Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CREATE_COLLECTION-Procedure.html), [CREATE_OR_TRUNCATE_COLLECTION Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CREATE_OR_TRUNCATE_COLLECTION-Procedure.html), [COLLECTION_EXISTS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/COLLECTION_EXISTS-Function.html)

### APEX_COLLECTION.CREATE_COLLECTION_FROM_QUERY e variantes _B, 2, B2 (bulk e binds)

```sql
APEX_COLLECTION.CREATE_COLLECTION_FROM_QUERY (
    p_collection_name    IN VARCHAR2,
    p_query              IN VARCHAR2,
    p_generate_md5       IN VARCHAR2 DEFAULT 'NO',
    p_truncate_if_exists IN VARCHAR2 DEFAULT 'NO' );

APEX_COLLECTION.CREATE_COLLECTION_FROM_QUERY_B (
    p_collection_name    IN VARCHAR2,
    p_query              IN VARCHAR2,
    p_names              IN apex_application_global.vc_arr2,   -- nomes dos binds (sem ':')
    p_values             IN apex_application_global.vc_arr2,   -- valores dos binds
    p_max_row_count      IN NUMBER   DEFAULT NULL,
    p_truncate_if_exists IN VARCHAR2 DEFAULT 'NO' );
-- _B sem binds: (p_collection_name, p_query, p_max_row_count)
-- QUERY2 e QUERYB2: mesmas formas; colunas 1-5 → N001..N005, 6-10 → D001..D005, depois até 50 de texto
```

| Variante | Mapeamento das colunas | MD5 | Desempenho / limites |
|---|---|---|---|
| `FROM_QUERY` | até 50 → `C001..C050` | opcional | normal |
| `FROM_QUERY2` | 5 números, 5 datas, até 50 texto | opcional | normal |
| `FROM_QUERY_B` | até 50 → `C001..C050` | **não** calcula | bulk, bem mais rápido; nenhum valor de coluna pode passar de 4.000 bytes (2.000 em bancos antigos) |
| `FROM_QUERYB2` | 5 números, 5 datas, até 50 texto | **não** | bulk; mesmo limite |

Todas parseiam a query como o **dono da aplicação** (parsing schema) e dão erro se a coleção já existe (salvo `p_truncate_if_exists => 'YES'` onde houver). Use as versões com `p_names`/`p_values` para binds em vez de concatenar valores no SQL (evita SQL injection).

```sql
apex_collection.create_collection_from_query_b(
    p_collection_name    => 'COLAB_DEPTO',
    p_query              => 'select id_colaborador, nome_completo from colaborador
                              where id_empresa = :emp and id_departamento = :dep',
    p_names              => apex_string.string_to_table('emp:dep'),
    p_values             => apex_string.string_to_table(:G_ID_EMPRESA || ':' || :P26_ID_DEPTO),
    p_truncate_if_exists => 'YES');
```

Fonte: [CREATE_COLLECTION_FROM_QUERY Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CREATE_COLLECTION_FROM_QUERY-Procedure.html), [CREATE_COLLECTION_FROM_QUERY2 Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CREATE_COLLECTION_FROM_QUERY2-Procedure.html), [CREATE_COLLECTION_FROM_QUERY_B Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CREATE_COLLECTION_FROM_QUERY_B-Procedure.html), [CREATE_COLLECTION_FROM_QUERY_B Procedure (No bind version)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CREATE_COLLECTION_FROM_QUERY_B-Procedure-NBV.html), [CREATE_COLLECTION_FROM_QUERYB2 Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CREATE_COLLECTION_FROM_QUERYB2-Procedure.html), [CREATE_COLLECTION_FROM_QUERYB2 Procedure (No bind version)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CREATE_COLLECTION_FROM_QUERYB2-Procedure-NBV.html)

### APEX_COLLECTION.ADD_MEMBER e ADD_MEMBERS: inserir membros

```sql
APEX_COLLECTION.ADD_MEMBER (                -- existe como procedure e como function (RETURN NUMBER = seq_id)
    p_collection_name IN VARCHAR2,
    p_c001 .. p_c050  IN VARCHAR2 DEFAULT NULL,
    p_n001 .. p_n005  IN NUMBER   DEFAULT NULL,
    p_d001 .. p_d005  IN DATE     DEFAULT NULL,
    p_clob001         IN CLOB     DEFAULT empty_clob(),
    p_blob001         IN BLOB     DEFAULT empty_blob(),
    p_xmltype001      IN XMLTYPE  DEFAULT NULL,
    p_generate_md5    IN VARCHAR2 DEFAULT 'NO' );

APEX_COLLECTION.ADD_MEMBERS (
    p_collection_name IN VARCHAR2,
    p_c001            IN apex_application_global.vc_arr2,                 -- obrigatório
    p_c002 .. p_c050  IN apex_application_global.vc_arr2 DEFAULT empty_vc_arr,
    p_n001 .. p_n005  IN apex_application_global.n_arr   DEFAULT empty_n_arr,
    p_d001 .. p_d005  IN apex_application_global.d_arr   DEFAULT empty_d_arr,
    p_generate_md5    IN VARCHAR2 DEFAULT 'NO' );
```

Regras:
- A coleção precisa existir (erro caso contrário).
- O novo `SEQ_ID` é sempre **maior que o maior existente**: buracos não são reaproveitados (1,2,5,8 → próximo é 9).
- Texto acima de 4.000 caracteres é **truncado** silenciosamente: use `p_clob001`.
- Em `ADD_MEMBERS` a quantidade de membros é a de `p_c001` (se `p_c001` tem 2 e `p_c002` tem 10, entram 2); `p_c001` NULL dá erro.

```sql
declare
    l_seq number;
begin
    l_seq := apex_collection.add_member(
                 p_collection_name => 'MEMBROS_EQUIPE',
                 p_c001            => :P27_NOME,
                 p_n001            => :P27_ID_COLABORADOR,
                 p_d001            => sysdate);
end;
```

Fonte: [ADD_MEMBER Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_MEMBER-Function.html), [ADD_MEMBER Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_MEMBER-Procedure.html), [ADD_MEMBERS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_MEMBERS-Procedure.html)

### APEX_COLLECTION.UPDATE_MEMBER x UPDATE_MEMBER_ATTRIBUTE: não apagar atributos sem querer

```sql
APEX_COLLECTION.UPDATE_MEMBER (
    p_collection_name IN VARCHAR2,
    p_seq             IN VARCHAR2 DEFAULT NULL,
    p_c001 .. p_c050, p_n001 .. p_n005, p_d001 .. p_d005,
    p_clob001 DEFAULT empty_clob(), p_blob001 DEFAULT empty_blob(), p_xmltype001 DEFAULT NULL );

APEX_COLLECTION.UPDATE_MEMBER_ATTRIBUTE ( p_collection_name, p_seq IN NUMBER,
    p_attr_number IN NUMBER, p_attr_value   IN VARCHAR2 );       -- 1: Cnnn (1..50)
APEX_COLLECTION.UPDATE_MEMBER_ATTRIBUTE ( p_collection_name, p_seq,
    p_clob_number IN NUMBER, p_clob_value   IN CLOB );           -- 2: CLOB001 (só 1)
APEX_COLLECTION.UPDATE_MEMBER_ATTRIBUTE ( p_collection_name, p_seq,
    p_blob_number IN NUMBER, p_blob_value   IN BLOB );           -- 3: BLOB001 (só 1)
APEX_COLLECTION.UPDATE_MEMBER_ATTRIBUTE ( p_collection_name, p_seq,
    p_xmltype_number IN NUMBER, p_xmltype_value IN SYS.XMLTYPE ); -- 4: XMLTYPE001 (só 1)
APEX_COLLECTION.UPDATE_MEMBER_ATTRIBUTE ( p_collection_name, p_seq,
    p_attr_number IN NUMBER, p_number_value IN NUMBER );         -- 5: N001..N005
APEX_COLLECTION.UPDATE_MEMBER_ATTRIBUTE ( p_collection_name, p_seq,
    p_attr_number IN NUMBER, p_date_value   IN DATE );           -- 6: D001..D005
```

**Pegadinha principal:** `UPDATE_MEMBER` grava os atributos informados e **anula todos os outros**. Para mudar uma coluna só, use `UPDATE_MEMBER_ATTRIBUTE`. Erros: coleção ou `p_seq` inexistente. Na assinatura 1, números fora de 1..50 são ignorados (a página também menciona erro para atributo inválido).

```sql
apex_collection.update_member_attribute(
    p_collection_name => 'MEMBROS_EQUIPE', p_seq => :P27_SEQ_ID,
    p_attr_number     => 2,                p_attr_value => :P27_PAPEL);
```

`UPDATE_MEMBERS` atualiza em lote por arrays; a contagem de `p_seq` manda (se `p_seq` tem 2 elementos, só 2 membros são atualizados); `p_seq` NULL ou `SEQ_ID` inexistente dão erro.

Fonte: [UPDATE_MEMBER Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/UPDATE_MEMBER-Procedure.html), [UPDATE_MEMBERS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/UPDATE_MEMBERS-Procedure.html), [UPDATE_MEMBER_ATTRIBUTE Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/UPDATE_MEMBER_ATTRIBUTE-Procedure-Signature-1.html), [Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/UPDATE_MEMBER_ATTRIBUTE-Procedure-Signature-2.html), [Signature 3](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/UPDATE_MEMBER_ATTRIBUTE-Procedure-Signature-3.html), [Signature 4](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/UPDATE_MEMBER_ATTRIBUTE-Procedure-Signature-4.html), [Signature 5](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/UPDATE_MEMBER_ATTRIBUTE-Procedure-Signature-5.html), [Signature 6](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/UPDATE_MEMBER_ATTRIBUTE-Procedure-Signature-6.html)

### APEX_COLLECTION.MERGE_MEMBERS: sincronizar a coleção com arrays

```sql
APEX_COLLECTION.MERGE_MEMBERS (
    p_collection_name IN VARCHAR2,
    p_seq             IN apex_application_global.vc_arr2 DEFAULT empty_vc_arr,
    p_c001 .. p_c050  IN apex_application_global.vc_arr2 DEFAULT empty_vc_arr,
    p_null_index      IN NUMBER   DEFAULT 1,
    p_null_value      IN VARCHAR2 DEFAULT NULL,
    p_init_query      IN VARCHAR2 DEFAULT NULL );
```

Se a coleção não existe, é criada (a partir de `p_init_query`, se informado). Se existe: linhas da coleção que não estão nos arrays são **apagadas**, as que estão são **atualizadas**, e as novas dos arrays são **inseridas**. A contagem de `p_c001` vale para todos os arrays. `p_null_index`/`p_null_value` marcam linhas a ignorar (ex.: `p_null_index => 3, p_null_value => '0'` trata como nula a linha em que `p_c003 = '0'`, removendo-a). Só aceita atributos texto.

Fonte: [MERGE_MEMBERS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/MERGE_MEMBERS-Procedure.html)

### APEX_COLLECTION: apagar membros e coleções (DELETE_MEMBER, DELETE_MEMBERS, TRUNCATE, DELETE_COLLECTION, f?p)

```sql
APEX_COLLECTION.DELETE_MEMBER  ( p_collection_name IN VARCHAR2, p_seq IN VARCHAR2 );
APEX_COLLECTION.DELETE_MEMBERS ( p_collection_name IN VARCHAR2,
                                 p_attr_number IN NUMBER,     -- 1..50 (Cnnn)
                                 p_attr_value  IN VARCHAR2 ); -- NULL apaga onde Cnnn IS NULL
APEX_COLLECTION.TRUNCATE_COLLECTION ( p_collection_name IN VARCHAR2 );
APEX_COLLECTION.DELETE_COLLECTION   ( p_collection_name IN VARCHAR2 );
APEX_COLLECTION.DELETE_ALL_COLLECTIONS;            -- app atual
APEX_COLLECTION.DELETE_ALL_COLLECTIONS_SESSION;    -- qualquer app da sessão
```

- Todas (exceto as `DELETE_ALL_*`) dão erro se a coleção não existe.
- `DELETE_MEMBERS` com `p_attr_value` NULL apaga os membros cujo atributo é NULL (cuidado!).
- Também dá para limpar uma coleção pela URL: o 6º argumento do `f?p` (*clear cache*) aceita o nome da coleção: `f?p=App:Page:Session::NO:NOME_COLECAO`.

Fonte: [DELETE_MEMBER Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/DELETE_MEMBER-Procedure.html), [DELETE_MEMBERS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/DELETE_MEMBERS-Procedure.html), [TRUNCATE_COLLECTION Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/TRUNCATE_COLLECTION-Procedure.html), [DELETE_COLLECTION Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/DELETE_COLLECTION-Procedure.html), [DELETE_ALL_COLLECTIONS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/DELETE_ALL_COLLECTIONS-Procedure.html), [DELETE_ALL_COLLECTIONS_SESSION Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/DELETE_ALL_COLLECTIONS_SESSION-Procedure.html), [Clearing Collection Session State](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/Clearing-Collection-Session-State.html)

### APEX_COLLECTION: detectar alterações (MD5, COLLECTION_HAS_CHANGED, GET_MEMBER_MD5)

- `p_generate_md5 => 'YES'` (em `ADD_MEMBER`, `ADD_MEMBERS`, `CREATE_COLLECTION_FROM_QUERY`/`QUERY2`) calcula o MD5 dos 50 atributos + CLOB e guarda em `MD5_ORIGINAL`. As versões `_B`/`B2` não calculam.
- `GET_MEMBER_MD5(p_collection_name, p_seq IN NUMBER) RETURN VARCHAR2` recalcula o MD5 atual do membro: compare com `MD5_ORIGINAL` para saber se a linha mudou.
- Flag de alteração da coleção: começa `FALSE` na criação e vira `TRUE` em qualquer operação (add, update, truncate…). `COLLECTION_HAS_CHANGED(p_collection_name) RETURN BOOLEAN` lê; `RESET_COLLECTION_CHANGED(p_collection_name)` e `RESET_COLLECTION_CHANGED_ALL` zeram.
- `COLLECTION_MEMBER_COUNT(p_collection_name) RETURN NUMBER`: total de membros; não é o maior `SEQ_ID` quando há buracos; não dá erro se a coleção não existe.

```sql
-- Gravar só as linhas alteradas pelo usuário
for r in (select seq_id, n001, c002, md5_original
            from apex_collections where collection_name = 'MEMBROS_EQUIPE') loop
    if r.md5_original <> apex_collection.get_member_md5('MEMBROS_EQUIPE', r.seq_id) then
        update equipe_membro set papel = r.c002 where id_colaborador = r.n001 and id_equipe = :P27_ID;
    end if;
end loop;
```

Fonte: [Determining Collection Status](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/Determining-Collection-Status.html), [GET_MEMBER_MD5 Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_MEMBER_MD5-Function.html), [COLLECTION_HAS_CHANGED Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/COLLECTION_HAS_CHANGED-Function.html), [RESET_COLLECTION_CHANGED Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/RESET_COLLECTION_CHANGED-Procedure.html), [RESET_COLLECTION_CHANGED_ALL Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/RESET_COLLECTION_CHANGED_ALL-Procedure.html), [COLLECTION_MEMBER_COUNT Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/COLLECTION_MEMBER_COUNT-Function.html)

### APEX_COLLECTION: ordenar e renumerar (SORT_MEMBERS, RESEQUENCE_COLLECTION, MOVE_MEMBER_UP/DOWN)

```sql
APEX_COLLECTION.SORT_MEMBERS ( p_collection_name IN VARCHAR2, p_sort_on_column_number IN NUMBER );  -- 1..50
APEX_COLLECTION.RESEQUENCE_COLLECTION ( p_collection_name IN VARCHAR2 );
APEX_COLLECTION.MOVE_MEMBER_UP   ( p_collection_name IN VARCHAR2, p_seq IN NUMBER );   -- troca com seq+1
APEX_COLLECTION.MOVE_MEMBER_DOWN ( p_collection_name IN VARCHAR2, p_seq IN NUMBER );   -- troca com seq-1
```

`SORT_MEMBERS` reordena por um atributo texto e renumera os `SEQ_ID` sem buracos. `MOVE_MEMBER_*` não dá erro no topo/fundo, mas dá se o `p_seq` não existe. Útil para listas ordenáveis pelo usuário (ex.: ordem de etapas de um onboarding).

Fonte: [SORT_MEMBERS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SORT_MEMBERS-Procedure.html), [RESEQUENCE_COLLECTION Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/RESEQUENCE_COLLECTION-Procedure.html), [MOVE_MEMBER_UP Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/MOVE_MEMBER_UP-Procedure.html), [MOVE_MEMBER_DOWN Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/MOVE_MEMBER_DOWN-Procedure.html)

### Erro "collection does not exist" ou "collection already exists" em APEX_COLLECTION

**Sintoma:** `ADD_MEMBER`, `UPDATE_MEMBER`, `TRUNCATE_COLLECTION` ou `DELETE_COLLECTION` levantam erro de aplicação dizendo que a coleção não existe; ou `CREATE_COLLECTION` diz que já existe.
**Causa:** coleções pertencem ao **usuário + sessão + application ID**. Uma coleção criada em outra sessão (outro login, job, SQL Workshop) ou em outra app não é visível. E `CREATE_COLLECTION` sem `p_truncate_if_exists => 'YES'` falha se ela já existe (ex.: usuário voltou ao passo 1 do wizard).
**Correção:** crie com `CREATE_OR_TRUNCATE_COLLECTION` (ou teste `COLLECTION_EXISTS` antes) no início do fluxo; consulte `APEX_COLLECTIONS` com o nome em maiúsculas.
**Prevenção:** centralize o nome da coleção numa constante de package; não conte com coleções fora da sessão APEX (em jobs, use `APEX_SESSION.CREATE_SESSION` antes).

Fonte: [CREATE_COLLECTION Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CREATE_COLLECTION-Procedure.html), [ADD_MEMBER Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_MEMBER-Procedure.html), [Accessing a Collection](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/Accessing-a-Collection.html)
## APEX_ACL: papéis do Application Access Control (ADD_USER_ROLE, HAS_USER_ROLE, REPLACE_USER_ROLES)

`APEX_ACL` manipula as atribuições de usuários a papéis (*roles*) do componente compartilhado **Application Access Control**. Os papéis são consumidos por authorization schemes do tipo *Is In Role or Group*. Também é possível editar atribuições por DML na view `APEX_APPL_ACL_USERS` (tem trigger `INSTEAD OF` para INSERT/UPDATE/DELETE). Views relacionadas: `APEX_APPL_ACL_ROLES` (papéis), `APEX_APPL_ACL_USERS` (usuários), `APEX_APPL_ACL_USER_ROLES` (atribuições).

**Fora de um ambiente APEX** (job, SQLcl), defina o workspace antes com `APEX_UTIL.SET_WORKSPACE` ou `APEX_UTIL.SET_SECURITY_GROUP_ID`.

| Membro | O que faz |
|---|---|
| `ADD_USER_ROLE` (por `p_role_id` ou `p_role_static_id`) | Atribui um papel a um usuário |
| `REMOVE_USER_ROLE` (por ID ou static ID) | Remove um papel do usuário |
| `REPLACE_USER_ROLES` (`apex_t_number` de IDs ou `apex_t_varchar2` de static IDs) | Substitui todos os papéis do usuário pela lista |
| `REMOVE_ALL_USER_ROLES` | Remove todos os papéis do usuário |
| `HAS_USER_ROLE` | `TRUE` se o usuário tem o papel (static ID) |
| `HAS_USER_ANY_ROLES` | `TRUE` se o usuário tem qualquer papel (teste de acesso à app) |
| `IS_ROLE_REMOVED_FROM_USER` | `TRUE` se a nova lista de IDs tiraria do usuário um papel que ele tem hoje |

Fonte: [APEX_ACL](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_ACL.html)

### APEX_ACL.ADD_USER_ROLE, REMOVE_USER_ROLE, REPLACE_USER_ROLES e REMOVE_ALL_USER_ROLES: assinaturas

```sql
APEX_ACL.ADD_USER_ROLE (
    p_application_id IN NUMBER   DEFAULT apex_application.g_flow_id,
    p_user_name      IN VARCHAR2,                 -- não diferencia maiúsculas
    p_role_id        IN NUMBER );                 -- assinatura 1
APEX_ACL.ADD_USER_ROLE (
    p_application_id IN NUMBER   DEFAULT apex_application.g_flow_id,
    p_user_name      IN VARCHAR2,
    p_role_static_id IN VARCHAR2 );               -- assinatura 2 (não diferencia maiúsculas)

APEX_ACL.REMOVE_USER_ROLE   ( p_application_id, p_user_name, p_role_id IN NUMBER );
APEX_ACL.REMOVE_USER_ROLE   ( p_application_id, p_user_name, p_role_static_id IN VARCHAR2 );
APEX_ACL.REPLACE_USER_ROLES ( p_application_id, p_user_name, p_role_ids IN apex_t_number );
APEX_ACL.REPLACE_USER_ROLES ( p_application_id, p_user_name, p_role_static_ids IN apex_t_varchar2 );
APEX_ACL.REMOVE_ALL_USER_ROLES ( p_application_id IN NUMBER DEFAULT apex_application.g_flow_id,
                                 p_user_name IN VARCHAR2 );
```

Prefira as assinaturas com **static ID** (estáveis entre ambientes; IDs numéricos mudam ao importar a app em outro workspace).

```sql
begin
    if not apex_acl.has_user_role(p_user_name => :P14_LOGIN, p_role_static_id => 'ADMIN_RH') then
        apex_acl.add_user_role(p_user_name => :P14_LOGIN, p_role_static_id => 'ADMIN_RH');
    end if;
    -- ou, para definir a lista inteira:
    apex_acl.replace_user_roles(p_user_name       => :P14_LOGIN,
                                p_role_static_ids => apex_t_varchar2('COLABORADOR', 'GESTOR'));
end;
```

Fonte: [ADD_USER_ROLE Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_USER_ROLE-Procedure-Signature1.html), [ADD_USER_ROLE Procedure Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_USER_ROLE-Procedure-Signature2.html), [REMOVE_USER_ROLE Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/REMOVE_USER_ROLE-Procedure-Signature1.html), [REMOVE_USER_ROLE Procedure Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/REMOVE_USER_ROLE-Procedure-Signature2.html), [REPLACE_USER_ROLES Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/REPLACE_USER_ROLES-Procedure-Signature1.html), [REPLACE_USER_ROLES Procedure Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/REPLACE_USER_ROLES-Procedure-Signature2.html), [REMOVE_ALL_USER_ROLES Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/REMOVE_ALL_USER_ROLES-Procedure.html)

### APEX_ACL.HAS_USER_ROLE, HAS_USER_ANY_ROLES e IS_ROLE_REMOVED_FROM_USER: checagens

```sql
APEX_ACL.HAS_USER_ROLE (
    p_application_id IN NUMBER   DEFAULT apex_application.g_flow_id,
    p_user_name      IN VARCHAR2 DEFAULT apex_application.g_user,
    p_role_static_id IN VARCHAR2 ) RETURN BOOLEAN;

APEX_ACL.HAS_USER_ANY_ROLES (
    p_application_id IN NUMBER   DEFAULT apex_application.g_flow_id,
    p_user_name      IN VARCHAR2 DEFAULT apex_application.g_user ) RETURN BOOLEAN;

APEX_ACL.IS_ROLE_REMOVED_FROM_USER (
    p_application_id IN NUMBER   DEFAULT apex_application.g_flow_id,
    p_user_name      IN VARCHAR2,
    p_role_static_id IN VARCHAR2,
    p_role_ids       IN apex_t_number ) RETURN BOOLEAN;
```

`IS_ROLE_REMOVED_FROM_USER` devolve `TRUE` só quando o usuário **tem hoje** o papel e a nova lista `p_role_ids` **não** o inclui. Uso típico: impedir que um administrador tire o próprio papel de admin numa tela de gestão de acesso.

```sql
if :P6_USUARIO = :APP_USER
   and apex_acl.is_role_removed_from_user(
           p_user_name      => :APP_USER,
           p_role_static_id => 'ADMIN_RH',
           p_role_ids       => apex_string.split_numbers(
                                   case when :REQUEST = 'DELETE' then null else :P6_PAPEIS end, ':')) then
    raise_application_error(-20001, 'Você não pode remover o próprio papel de administrador.');
end if;
```

Fonte: [HAS_USER_ROLE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/HAS_USER_ROLE-Function.html), [HAS_USER_ANY_ROLES Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/HAS_USER_ANY_ROLES-Function.html), [IS_ROLE_REMOVED_FROM_USER Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/IS_ROLE_REMOVED_FROM_USER-Function.html)

### ORA-01403 em WWV_FLOW_ACL_API ao chamar APEX_ACL.ADD_USER_ROLE fora da aplicação

**Sintoma:** `apex_acl.add_user_role` (ou `has_user_role`) executado no SQL Commands, num script ou num job falha com `ORA-01403: no data found` vindo de `WWV_FLOW_ACL_API`.
**Causa:** sem contexto APEX não há workspace/aplicação definidos. A doc exige, fora de um ambiente APEX, definir o `security_group_id` antes (`APEX_UTIL.SET_WORKSPACE` ou `SET_SECURITY_GROUP_ID`), e o default `p_application_id => apex_application.g_flow_id` fica nulo.
**Correção:** em SQLcl/SQL Developer/job: `apex_util.set_workspace('<WORKSPACE>')` e passe `p_application_id` explicitamente; ou crie uma sessão com `apex_session.create_session(p_app_id => 100, p_page_id => 1, p_username => ...)`. Lembre que `CREATE_SESSION` **não é suportado** em SQL Commands/SQL Scripts do SQL Workshop (no Corlix Hub isso aparece como `ORA-20987: Access to session state is disabled`, ver `modulos/perfis-acesso/Registro-implantacao.md`).
**Prevenção:** dentro da app, chame `APEX_ACL` em processos de página; scripts de carga, rode-os no SQLcl com sessão criada.

Fonte: [APEX_ACL](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_ACL.html), [CREATE_SESSION Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CREATE_SESSION-Procedure.html)

## APEX_AUTHORIZATION: testar authorization schemes em PL/SQL e controlar o cache

| Membro | O que faz |
|---|---|
| `IS_AUTHORIZED` | `TRUE` se o usuário passa no authorization scheme (pelo **nome**) |
| `HAS_ACCESS` | `TRUE` se o usuário passa no authorization scheme (pelo **Static ID**) |
| `RESET_CACHE` | Limpa o cache de autorizações da sessão (força reavaliação) |
| `ENABLE_DYNAMIC_GROUPS` | Habilita grupos na sessão (vindos de LDAP, header HTTP etc.) |

Fonte: [APEX_AUTHORIZATION](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AUTHORIZATION.html)

### APEX_AUTHORIZATION.IS_AUTHORIZED e HAS_ACCESS: checar permissão em PL/SQL, SQL e views

```sql
APEX_AUTHORIZATION.IS_AUTHORIZED ( p_authorization_name IN VARCHAR2 ) RETURN BOOLEAN;  -- nome do scheme
APEX_AUTHORIZATION.HAS_ACCESS    ( p_static_id          IN VARCHAR2 ) RETURN BOOLEAN;  -- Static ID do scheme
```

- Os resultados são **cacheados** por desempenho: a função pode devolver o valor do cache sem reavaliar. A frequência é controlada pelo atributo *Evaluation Point > Validate authorization scheme* do scheme: *Once per session* (padrão, mais eficiente), *Once per page view*, *Once per component* ou *Always (No Caching)*.
- `HAS_ACCESS` usa o Static ID, mais estável que o nome se alguém renomear o scheme.
- `IS_AUTHORIZED` substitui o deprecated `APEX_UTIL.PUBLIC_CHECK_AUTHORIZATION`.

```sql
-- Condição PL/SQL de região ou dentro de package chamado por processo
if apex_authorization.is_authorized('ADMIN_RH') then
    ...
end if;

-- Para usar em SQL/views, encapsule numa função que devolve 'S'/'N'
create or replace function fn_eh_admin_rh return varchar2 is
begin
    return case when apex_authorization.is_authorized('ADMIN_RH') then 'S' else 'N' end;
end;
```

Fonte: [IS_AUTHORIZED Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/IS_AUTHORIZED-Function.html), [Editing an Authorization Scheme](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-authorization-scheme.html), [HAS_ACCESS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AUTHORIZATION.HAS_ACCESS-Function.html)

### APEX_AUTHORIZATION.RESET_CACHE: papel mudou mas a tela continua negando (ou liberando)

**Sintoma:** depois de atribuir/remover um papel (`APEX_ACL`) ou mudar um dado que a autorização consulta, o usuário continua vendo (ou não vendo) a página/botão até fazer logout.
**Causa:** os resultados de authorization schemes são cacheados na sessão conforme o *Evaluation Point* (ex.: *Once per session*).
**Correção:** chame `apex_authorization.reset_cache;` logo após a mudança (para a sessão corrente); para outros usuários, a mudança vale na próxima sessão ou reavaliação.
**Prevenção:** a doc recomenda trocar o padrão *Once per session* por outra opção (*Once per page view*, *Once per component*, *Always (No Caching)*) quando a checagem depende de session state ou de dados que mudam durante a sessão.

```sql
APEX_AUTHORIZATION.RESET_CACHE;
```

Substitui o deprecated `APEX_UTIL.RESET_AUTHORIZATIONS`.

Fonte: [RESET_CACHE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/RESET_CACHE-Procedure.html), [Editing an Authorization Scheme](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-authorization-scheme.html), [IS_AUTHORIZED Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/IS_AUTHORIZED-Function.html), [RESET_AUTHORIZATIONS Procedure (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/RESET_AUTHORIZATIONS-Procedure-DEPRECATED.html)

### APEX_AUTHORIZATION.ENABLE_DYNAMIC_GROUPS: grupos vindos de LDAP ou header

```sql
APEX_AUTHORIZATION.ENABLE_DYNAMIC_GROUPS ( p_group_names IN apex_t_varchar2 );
```

Habilita grupos na sessão sem que existam no repositório do workspace (podem vir de LDAP ou de header HTTP confiável). Habilitar um grupo que existe no workspace também habilita os grupos concedidos a ele. Com Real Application Security ligada no esquema de autenticação, viram grupos RAS dinâmicos ou externos. **Deve ser chamado durante ou logo após a autenticação** (ex.: no *Post-Authentication*). Views: `APEX_WORKSPACE_SESSION_GROUPS`, `APEX_WORKSPACE_GROUP_GROUPS`.

```sql
apex_authorization.enable_dynamic_groups(p_group_names => apex_t_varchar2('SALES', 'HR'));
```

Fonte: [ENABLE_DYNAMIC_GROUPS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ENABLE_DYNAMIC_GROUPS-Procedure.html)

## APEX_AUTHENTICATION: login, logout, estado de autenticação e callbacks de plug-ins

API pública usada por plug-ins de autenticação e por páginas de login.

| Membro | O que faz |
|---|---|
| `c_default_username_cookie` | Constante `'LOGIN_USERNAME_COOKIE'` |
| `LOGIN` | Autentica com o esquema atual (pre-auth, credenciais, post-auth, log, redirect) |
| `POST_LOGIN` | Só a parte final do login (credenciais já verificadas fora do APEX) |
| `LOGOUT` | Encerra a sessão e redireciona para a home (chamado do navegador) |
| `IS_AUTHENTICATED` | `TRUE` se o usuário está logado |
| `IS_PUBLIC_USER` | `TRUE` se **não** está logado |
| `GET_LOGIN_USERNAME_COOKIE` / `SEND_LOGIN_USERNAME_COOKIE` | Cookie "lembrar usuário" da página de login |
| `PERSISTENT_AUTH_ENABLED` | Se a autenticação persistente ("lembrar-me") está habilitada na instância |
| `PERSISTENT_COOKIES_ENABLED` | Se cookies persistentes estão habilitados (parâmetro `WORKSPACE_NAME_USER_COOKIE`) |
| `REMOVE_CURRENT_PERSISTENT_AUTH` | Remove a autenticação persistente do navegador atual |
| `REMOVE_PERSISTENT_AUTH` | Remove a autenticação persistente de um usuário (ou de todos) e encerra as sessões dele |
| `CALLBACK` / `CALLBACK2` | Ponto de retorno de páginas de login externas e Social Sign-In (OAuth2) |
| `GET_CALLBACK_URL` | Monta a URL de callback para um login externo |
| `SAML_CALLBACK` | Ponto de retorno do provedor SAML |
| `SAML_METADATA` | Emite os metadados SAML da app ou da instância |

Fonte: [APEX_AUTHENTICATION](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AUTHENTICATION.html), [Constants](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AUTHENTICATION-Constants.html)

### APEX_AUTHENTICATION.LOGIN e POST_LOGIN: os passos do login

```sql
APEX_AUTHENTICATION.LOGIN (
    p_username            IN VARCHAR2,
    p_password            IN VARCHAR2,
    p_uppercase_username  IN BOOLEAN DEFAULT TRUE,
    p_set_persistent_auth IN BOOLEAN DEFAULT FALSE );  -- exige autenticação persistente habilitada na instância

APEX_AUTHENTICATION.POST_LOGIN (
    p_username            IN VARCHAR2,
    p_password            IN VARCHAR2,
    p_uppercase_username  IN BOOLEAN DEFAULT TRUE );
```

Sequência do `LOGIN`:
1. roda o *Pre-Authentication* do esquema;
2. roda a função de autenticação com `p_username`/`p_password`;
   - sucesso: roda o *Post-Authentication*, grava o usuário na tabela de sessões e define o redirect para o *deep link*;
   - falha: redirect para a página atual com mensagem em `notification_msg`;
3. registra o resultado no log de acesso;
4. redireciona.

`POST_LOGIN` executa só os passos 3–4 e o trecho de sucesso, pulando 1 e 2: use quando a verificação de credenciais foi feita fora do APEX. `p_uppercase_username => TRUE` (padrão) converte o usuário para maiúsculas: é por isso que `:APP_USER` costuma vir em maiúsculas.

```sql
-- Exemplo de processo de login numa página de login (ex.: 9999)
apex_authentication.send_login_username_cookie(
    p_username => lower(:P9999_USERNAME),
    p_consent  => :P9999_REMEMBER = 'Y');
apex_authentication.login(
    p_username => :P9999_USERNAME,
    p_password => :P9999_PASSWORD);
```

Fonte: [LOGIN Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/LOGIN-Procedure.html), [POST_LOGIN Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/POST_LOGIN-Procedure.html)

### APEX_AUTHENTICATION.LOGOUT, IS_AUTHENTICATED e IS_PUBLIC_USER

```sql
APEX_AUTHENTICATION.LOGOUT ( p_session_id IN NUMBER, p_app_id IN NUMBER );
APEX_AUTHENTICATION.IS_AUTHENTICATED RETURN BOOLEAN;
APEX_AUTHENTICATION.IS_PUBLIC_USER   RETURN BOOLEAN;   -- o inverso
```

`LOGOUT` fecha a sessão e redireciona para a home da app; é feito para ser chamado **diretamente do navegador**. `IS_AUTHENTICATED`/`IS_PUBLIC_USER` são úteis em páginas públicas que mostram conteúdo diferente para logados.

```sql
if apex_authentication.is_authenticated then
    sys.htp.p(apex_escape.html(:APP_USER) || ', bem-vindo de volta');
else
    sys.htp.p('Entre para continuar');
end if;
```

Fonte: [LOGOUT Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/LOGOUT-Procedure.html), [IS_AUTHENTICATED Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/IS_AUTHENTICATED-Function.html), [IS_PUBLIC_USER Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/IS_PUBLIC_USER-Function.html)

### APEX_AUTHENTICATION: cookie "lembrar usuário" e autenticação persistente

```sql
APEX_AUTHENTICATION.GET_LOGIN_USERNAME_COOKIE (
    p_cookie_name IN VARCHAR2 DEFAULT c_default_username_cookie ) RETURN VARCHAR2;
APEX_AUTHENTICATION.SEND_LOGIN_USERNAME_COOKIE (
    p_username    IN VARCHAR2,
    p_cookie_name IN VARCHAR2 DEFAULT c_default_username_cookie,
    p_consent     IN BOOLEAN  DEFAULT FALSE );
APEX_AUTHENTICATION.PERSISTENT_COOKIES_ENABLED RETURN BOOLEAN;
APEX_AUTHENTICATION.PERSISTENT_AUTH_ENABLED    RETURN BOOLEAN;
APEX_AUTHENTICATION.REMOVE_CURRENT_PERSISTENT_AUTH;
APEX_AUTHENTICATION.REMOVE_PERSISTENT_AUTH ( p_username IN VARCHAR2 );   -- NULL = todos do workspace
```

- `SEND_LOGIN_USERNAME_COOKIE` só envia o cookie com `p_consent => TRUE`. Sem consentimento e com cookie existente, o valor é **sobrescrito com NULL**. Nada é enviado se `PERSISTENT_COOKIES_ENABLED` for `FALSE` (parâmetro de instância `WORKSPACE_NAME_USER_COOKIE = 'N'`).
- `GET_LOGIN_USERNAME_COOKIE` no *Before Header* da página de login preenche o usuário e o switch "lembrar".
- `REMOVE_PERSISTENT_AUTH(:APP_USER)` invalida os cookies persistentes do usuário e **encerra todas as sessões dele** no workspace (útil após troca de senha).

Fonte: [GET_LOGIN_USERNAME_COOKIE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_LOGIN_USERNAME_COOKIE-Function.html), [SEND_LOGIN_USERNAME_COOKIE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SEND_LOGIN_USERNAME_COOKIE-Procedure.html), [PERSISTENT_COOKIES_ENABLED Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PERSISTENT_COOKIES_ENABLED-Function.html), [PERSISTENT_AUTH_ENABLED Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PERSISTENT_AUTH_ENABLED-Function.html), [REMOVE_CURRENT_PERSISTENT_AUTH Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/REMOVE_CURRENT_PERSISTENT_AUTH-Procedure.html), [REMOVE_PERSISTENT_AUTH Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/REMOVE_PERSISTENT_AUTH-Procedure.html)

### APEX_AUTHENTICATION.CALLBACK, CALLBACK2, GET_CALLBACK_URL, SAML_CALLBACK e SAML_METADATA: login externo

```sql
APEX_AUTHENTICATION.GET_CALLBACK_URL (
    p_x01 .. p_x10  IN VARCHAR2 DEFAULT NULL,
    p_callback_name IN VARCHAR2 DEFAULT NULL )   -- padrão apex_authentication.callback
RETURN VARCHAR2;

APEX_AUTHENTICATION.CALLBACK (                    -- CALLBACK2 tem a mesma assinatura
    p_session_id, p_app_id, p_ajax_identifier, p_page_id, p_x01 .. p_x10,   -- callback customizado
    state, code, error, error_description, error_uri, error_reason, error_code,
    error_message, authuser, session_state, prompt, hd, scope, realmID );   -- OAuth2 (não use em callback customizado)

APEX_AUTHENTICATION.SAML_CALLBACK ( SAMLResponse, SAMLRequest, RelayState, SigAlg, Signature );
APEX_AUTHENTICATION.SAML_METADATA ( p_app_id IN NUMBER DEFAULT NULL );
```

Fluxo de login externo em plug-in: o plug-in obtém `GET_CALLBACK_URL`, redireciona para o SSO passando essa URL (escapada com `utl_url.escape`), e para o motor com `stop_apex_engine`. O SSO, após autenticar, chama a URL de callback (pode anexar `&p_x01=<handle>`), o que dispara o Ajax do plug-in de autenticação, que lê `x01` e loga o usuário. `CALLBACK`/`CALLBACK2`/`SAML_CALLBACK` são chamados **pelo navegador**, nunca pelo seu código. `SAML_METADATA` gera os metadados de *service provider* (da app ou da instância), ex.: `https://host/apex/apex_authentication.saml_metadata?p_app_id=101`.

Fonte: [CALLBACK Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CALLBACK-Procedure.html), [CALLBACK2 Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CALLBACK2-Procedure.html), [GET_CALLBACK_URL Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_CALLBACK_URL-Function.html), [SAML_CALLBACK Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SAML_CALLBACK-Procedure.html), [SAML_METADATA Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SAML_METADATA-Procedure.html)

## APEX_CUSTOM_AUTH: sessão e autenticação em baixo nível

API mais antiga para esquemas customizados e gestão de sessão. Para login/logout em código novo, prefira `APEX_AUTHENTICATION`.

| Membro | O que faz |
|---|---|
| `LOGIN` | Autentica e registra a sessão (*Login API*) |
| `POST_LOGIN` | Registra a sessão após autenticação já feita (só em contexto de página) |
| `LOGOUT` | **Deprecated**: use `APEX_AUTHENTICATION.LOGOUT` |
| `IS_SESSION_VALID` | Resultado do *page sentry* do esquema de autenticação |
| `SESSION_ID_EXISTS` | Se a variável global de sessão tem um ID positivo |
| `GET_SESSION_ID` | Devolve `APEX_APPLICATION.G_INSTANCE` |
| `GET_SESSION_ID_FROM_COOKIE` | Session ID lido do cookie de sessão |
| `GET_NEXT_SESSION_ID` | Próximo ID da sequence de sessões |
| `SET_SESSION_ID` / `SET_SESSION_ID_TO_NEXT_VALUE` | Define `G_INSTANCE` |
| `GET_USER` | Devolve `APEX_APPLICATION.G_USER` |
| `GET_USERNAME` | Usuário registrado na tabela interna de sessões |
| `SET_USER` | Define `G_USER` |
| `DEFINE_USER_SESSION` | `SET_USER` + `SET_SESSION_ID` numa chamada |
| `GET_SECURITY_GROUP_ID` | ID do workspace do usuário atual |
| `CURRENT_PAGE_IS_PUBLIC` | Se a página atual é *Page Is Public* |
| `APPLICATION_PAGE_ITEM_EXISTS` | Se um item existe na página atual |
| `GET_COOKIE_PROPS` | Nome, path, domínio e *secure* do cookie de sessão do esquema |
| `GET_LDAP_PROPS` | Host, porta, SSL, DN, filtro e edit function LDAP do esquema |
| `LDAP_DNPREP` | Troca `.` por `_` no usuário |

Fonte: [APEX_CUSTOM_AUTH](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_CUSTOM_AUTH.html)

### APEX_CUSTOM_AUTH.LOGIN, POST_LOGIN e funções de sessão: assinaturas e cuidados

```sql
APEX_CUSTOM_AUTH.LOGIN (
    p_uname         IN VARCHAR2 DEFAULT NULL,
    p_password      IN VARCHAR2 DEFAULT NULL,
    p_session_id    IN VARCHAR2 DEFAULT NULL,   -- NÃO use bind (:APP_SESSION); use V('APP_SESSION')
    p_app_page      IN VARCHAR2 DEFAULT NULL,   -- 'app_id:pagina_pos_login'
    p_entry_point   IN VARCHAR2 DEFAULT NULL,   -- uso interno
    p_preserve_case IN BOOLEAN  DEFAULT FALSE );-- TRUE não converte o usuário para maiúsculas

APEX_CUSTOM_AUTH.POST_LOGIN (
    p_uname, p_session_id, p_app_page, p_preserve_case DEFAULT FALSE );  -- só em contexto de página

APEX_CUSTOM_AUTH.IS_SESSION_VALID RETURN BOOLEAN;
APEX_CUSTOM_AUTH.GET_SESSION_ID   RETURN NUMBER;
APEX_CUSTOM_AUTH.GET_USER         RETURN VARCHAR2;
APEX_CUSTOM_AUTH.GET_USERNAME     RETURN VARCHAR2;
APEX_CUSTOM_AUTH.SET_USER ( p_user IN VARCHAR2 );
APEX_CUSTOM_AUTH.DEFINE_USER_SESSION ( p_user IN VARCHAR2, p_session_id IN NUMBER );
APEX_CUSTOM_AUTH.GET_COOKIE_PROPS ( p_app_id IN NUMBER, p_cookie_name OUT VARCHAR2,
    p_cookie_path OUT VARCHAR2, p_cookie_domain OUT VARCHAR2, p_secure OUT BOOLEAN );
APEX_CUSTOM_AUTH.LDAP_DNPREP ( p_username IN VARCHAR2 ) RETURN VARCHAR2;   -- replace(p_username,'.','_')
```

`GET_COOKIE_PROPS` é útil para diagnosticar problemas de cookie de sessão (nome, path, domínio, secure) do esquema da app. `APEX_CUSTOM_AUTH.LOGOUT` é **deprecated**.

```sql
apex_custom_auth.login(p_uname      => 'FRANK',
                       p_password   => 'secret99',
                       p_session_id => v('APP_SESSION'),
                       p_app_page   => :APP_ID || ':1');
```

Fonte: [LOGIN Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/LOGIN-Procedure-2.html), [POST_LOGIN Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/POST_LOGIN-Procedure-2.html), [LOGOUT Procedure (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/LOGOUT-Procedure-DEPRECATED.html), [IS_SESSION_VALID Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/IS_SESSION_VALID-Function.html), [GET_COOKIE_PROPS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_COOKIE_PROPS-Procedure.html), [DEFINE_USER_SESSION Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/DEFINE_USER_SESSION-Procedure.html), [LDAP_DNPREP Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/LDAP_DNPREP-Function.html), [GET_LDAP_PROPS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_LDAP_PROPS-Procedure.html), [CURRENT_PAGE_IS_PUBLIC Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CURRENT_PAGE_IS_PUBLIC-Function.html), [SESSION_ID_EXISTS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SESSION_ID_EXISTS-Function.html)

## APEX_LDAP: autenticar e consultar diretórios LDAP/AD

| Membro | O que faz |
|---|---|
| `AUTHENTICATE` | `TRUE` se usuário/senha fazem `SIMPLE_BIND_S` no servidor |
| `SEARCH` | Busca no diretório e devolve tabela `(dn, name, val)` (pipelined) para usar em SQL |
| `GET_USER_ATTRIBUTES` | Valores de atributos específicos do usuário |
| `GET_ALL_USER_ATTRIBUTES` | Todos os atributos (nomes + valores) do usuário |
| `IS_MEMBER` | Se o usuário é membro de um grupo |
| `MEMBER_OF` | Grupos do usuário (`vc_arr2`) |
| `MEMBER_OF2` | Grupos do usuário em VARCHAR2 separado por `:` |

Fonte: [APEX_LDAP](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_LDAP.html)

### APEX_LDAP.AUTHENTICATE, SEARCH, IS_MEMBER e MEMBER_OF: parâmetros comuns e exemplos

Parâmetros comuns: `p_username`, `p_pass`/`p_password`, `p_auth_base`/`p_search_base` (ex.: `dc=users,dc=my,dc=org`), `p_host`, `p_port` (padrão `389`; em `GET_ALL_USER_ATTRIBUTES` o padrão é `636`), `p_use_ssl` (`'N'` padrão, `'Y'` SSL no bind, `'A'` SSL com autenticação de um lado, exige o certificado do servidor numa Oracle wallet), e `p_credential_static_id` (usar uma *Web Credential*; se informada e não encontrada, `NO_DATA_FOUND`).

```sql
APEX_LDAP.AUTHENTICATE ( p_username, p_password, p_search_base, p_host,
                         p_port DEFAULT 389, p_use_ssl DEFAULT 'N' ) RETURN BOOLEAN;
APEX_LDAP.SEARCH ( p_username, p_pass, p_auth_base, p_host, p_port DEFAULT 389, p_use_ssl DEFAULT 'N',
                   p_search_base, p_search_filter,
                   p_scope DEFAULT sys.dbms_ldap.scope_subtree, p_timeout_sec DEFAULT 3,
                   p_attribute_names,               -- lista separada por vírgula
                   p_credential_static_id DEFAULT NULL ) RETURN apex_t_ldap_attributes pipelined;
APEX_LDAP.IS_MEMBER ( p_username, p_pass, p_auth_base, p_host, p_port, p_use_ssl,
                      p_group, p_group_base, p_credential_static_id ) RETURN BOOLEAN;
APEX_LDAP.MEMBER_OF  ( ... ) RETURN apex_application_global.vc_arr2;
APEX_LDAP.MEMBER_OF2 ( ... ) RETURN VARCHAR2;      -- 'grupo1:grupo2'
```

**Segurança:** sempre escape a entrada do usuário no filtro com `APEX_ESCAPE.LDAP_SEARCH_FILTER` (e DNs com `APEX_ESCAPE.LDAP_DN`).

```sql
select dn, mail, nome, fone
  from (select dn, name, val
          from table(apex_ldap.search(
                   p_host            => 'ldap.example.com',
                   p_port            => 636,
                   p_use_ssl         => 'A',
                   p_search_base     => 'dc=example,dc=com',
                   p_search_filter   => 'uid=' || apex_escape.ldap_search_filter(:APP_USER),
                   p_attribute_names => 'mail,displayname,telephonenumber')))
 pivot (min(val) for name in ('mail' mail, 'displayname' nome, 'telephonenumber' fone));
```

Fonte: [AUTHENTICATE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/AUTHENTICATE-Function.html), [SEARCH Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_LDAP.SEARCH-Function.html), [IS_MEMBER Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/IS_MEMBER-Function.html), [MEMBER_OF Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/MEMBER_OF-Function.html), [MEMBER_OF2 Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/MEMBER_OF2-Function.html), [GET_USER_ATTRIBUTES Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_USER_ATTRIBUTES-Procedure.html), [GET_ALL_USER_ATTRIBUTES Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_ALL_USER_ATTRIBUTES-Procedure.html)
## APEX_REGION: dados, exportação, cache e reset de regiões

API pública para regiões. Permite ler os dados **exatamente como a região os mostra** (com filtros do usuário, relatório salvo, view), exportar para PDF/XLSX/CSV, limpar/resetar configurações e cache.

| Membro | O que faz |
|---|---|
| `OPEN_QUERY_CONTEXT` (por `p_region_id` ou `p_static_id`) | Abre um contexto `APEX_EXEC` com os dados atuais da região |
| `EXPORT_DATA` | Exporta os dados da região (`apex_data_export.t_export`) |
| `GET_ID` (por static ID ou por nome) | ID numérico da região |
| `IS_READ_ONLY` | Se a região atual está sendo renderizada somente leitura (NULL fora de região) |
| `CLEAR` (por ID ou static ID) | Limpa paginação e configurações de relatório (filtros, breaks, agregações…) |
| `RESET` (por ID ou static ID) | Reseta paginação, ordenação, configurações de IR/IG e aba do *Region Display Selector* |
| `PURGE_CACHE` (por ID ou static ID) | Limpa cache de região |
| `GET_CACHE_DATE` | Quando a região foi cacheada |

Restrição comum: `OPEN_QUERY_CONTEXT` e `EXPORT_DATA` só suportam **regiões nativas** (não plug-ins).

Fonte: [APEX_REGION](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_REGION.html)

### APEX_REGION.OPEN_QUERY_CONTEXT: ler em PL/SQL os dados que a região está exibindo

```sql
APEX_REGION.OPEN_QUERY_CONTEXT (
    p_page_id                IN NUMBER,
    p_region_id              IN NUMBER,                -- assinatura 2: p_static_id IN VARCHAR2
    p_component_id           IN NUMBER    DEFAULT NULL,-- IR/IG: ID do relatório salvo; JET chart: ID da série
    p_view_mode              IN VARCHAR2  DEFAULT NULL,-- apex_ir.c_view_report | c_view_groupby | c_view_pivot
    p_additional_filters     IN apex_exec.t_filters    DEFAULT apex_exec.c_empty_filters,
    p_outer_sql              IN VARCHAR2  DEFAULT NULL,-- envolve a query; use #APEX$SOURCE_DATA#
    p_first_row              IN NUMBER    DEFAULT NULL,-- padrão 1
    p_max_rows               IN NUMBER    DEFAULT NULL,-- padrão sem limite
    p_total_row_count        IN BOOLEAN   DEFAULT FALSE,
    p_total_row_count_limit  IN NUMBER    DEFAULT NULL,
    p_parent_column_values   IN apex_exec.t_parameters DEFAULT apex_exec.c_empty_parameters )  -- detalhe de IG master-detail
RETURN apex_exec.t_context;
```

Comportamento:
- Roda numa **transação autônoma**.
- Com `p_view_mode` NULL usa a view que o relatório está usando; passar uma view que não existe levanta erro.
- `p_outer_sql` sobrepõe as views CHART/GROUP BY/PIVOT de IR. Se usar `p_total_row_count => TRUE` junto com `p_outer_sql`, inclua a coluna `APEX$TOTAL_ROW_COUNT` no select externo.
- Substitui o deprecated `APEX_IR.GET_REPORT`.

```sql
declare
    l_ctx apex_exec.t_context;
begin
    l_ctx := apex_region.open_query_context(
                 p_page_id   => 12,
                 p_static_id => 'colaboradores');
    apex_json.open_object;
    apex_json.write_context('data', l_ctx);   -- respeita os filtros que o usuário aplicou
    apex_json.close_object;
    apex_exec.close(l_ctx);
end;
```

Fonte: [OPEN_QUERY_CONTEXT Function Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_REGION-OPEN_QUERY_CONTEXT-Function-Signature-1.html), [OPEN_QUERY_CONTEXT Function Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_REGION-OPEN_QUERY_CONTEXT-Function-Signature-2.html)

### APEX_REGION.EXPORT_DATA: exportar a região para PDF, XLSX, CSV, HTML

```sql
APEX_REGION.EXPORT_DATA (
    p_format                  IN apex_data_export.t_format,          -- apex_data_export.c_format_*
    p_page_id                 IN NUMBER,
    p_region_id               IN NUMBER,
    p_component_id            IN NUMBER   DEFAULT NULL,
    p_view_mode               IN VARCHAR2 DEFAULT NULL,
    p_additional_filters      IN apex_exec.t_filters    DEFAULT apex_exec.c_empty_filters,
    p_max_rows                IN NUMBER   DEFAULT NULL,
    p_parent_column_values    IN apex_exec.t_parameters DEFAULT apex_exec.c_empty_parameters,
    p_as_clob                 IN BOOLEAN  DEFAULT FALSE,             -- não funciona com PDF/XLSX
    p_file_name               IN VARCHAR2 DEFAULT NULL,
    p_page_size               IN apex_data_export.t_size        DEFAULT apex_data_export.c_size_letter,
    p_orientation             IN apex_data_export.t_orientation DEFAULT apex_data_export.c_orientation_portrait,
    p_data_only               IN BOOLEAN  DEFAULT FALSE,             -- TRUE ignora grupos, breaks, agregados, highlights
    p_pdf_accessible          IN BOOLEAN  DEFAULT FALSE,
    p_xml_include_declaration IN BOOLEAN  DEFAULT TRUE )
RETURN apex_data_export.t_export;
```

Só regiões nativas. O retorno traz o conteúdo, o mime type e, opcionalmente, o layout; baixe com `apex_data_export.download(l_export)`.

```sql
declare
    l_export apex_data_export.t_export;
begin
    l_export := apex_region.export_data(
                    p_format    => apex_data_export.c_format_xlsx,
                    p_page_id   => 12,
                    p_region_id => apex_region.get_id(p_page_id => 12, p_dom_static_id => 'colaboradores'),
                    p_file_name => 'colaboradores');
    apex_data_export.download(l_export);
end;
```

Fonte: [EXPORT_DATA Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_REGION-EXPORT_DATA-Function.html)

### APEX_REGION.GET_ID, IS_READ_ONLY e GET_CACHE_DATE

```sql
APEX_REGION.GET_ID ( p_application_id IN NUMBER DEFAULT apex.g_flow_id,
                     p_page_id IN NUMBER, p_dom_static_id IN VARCHAR2 ) RETURN NUMBER;
APEX_REGION.GET_ID ( p_application_id IN NUMBER DEFAULT apex.g_flow_id,
                     p_page_id IN NUMBER, p_name IN VARCHAR2 ) RETURN NUMBER;
APEX_REGION.IS_READ_ONLY RETURN BOOLEAN;
APEX_REGION.GET_CACHE_DATE ( p_application_id IN NUMBER, p_page_id IN NUMBER,
                             p_static_id IN VARCHAR2 ) RETURN DATE;
```

- `GET_ID` evita fixar IDs numéricos no código (eles mudam entre ambientes). Static ID e nome **não são únicos**: se houver duas regiões iguais, levanta `TOO_MANY_ROWS`.
- `IS_READ_ONLY` serve em condições da região e dos seus itens/botões; devolve `NULL` se chamada fora do processamento de uma região.
- Alternativa por SQL: `select region_id from apex_application_page_regions where application_id = :APP_ID and page_id = 3 and static_id = '...'`.

Fonte: [GET_ID Function Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_REGION.GET_ID-Function-Signature-1.html), [GET_ID Function Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_REGION.GET_ID-Function-Signature-2.html), [IS_READ_ONLY Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_REGION-IS_READ_ONLY-Function.html), [GET_CACHE_DATE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_REGION.GET_CACHE_DATE-Function.html)

### APEX_REGION.CLEAR x RESET: o que cada um limpa

```sql
APEX_REGION.CLEAR ( p_application_id IN NUMBER DEFAULT apex_application.g_flow_id,
                    p_page_id IN NUMBER, p_region_id IN NUMBER | p_static_id IN VARCHAR2,
                    p_component_id IN NUMBER DEFAULT NULL );
APEX_REGION.RESET ( p_application_id IN NUMBER DEFAULT apex_application.g_flow_id,
                    p_page_id IN NUMBER, p_region_id IN NUMBER | p_static_id IN VARCHAR2,
                    p_component_id IN NUMBER DEFAULT NULL );
APEX_REGION.PURGE_CACHE ( p_application_id DEFAULT apex.g_flow_id, p_page_id DEFAULT NULL,
                          p_region_id | p_static_id DEFAULT NULL, p_current_session_only IN BOOLEAN DEFAULT FALSE );
```

| | `CLEAR` | `RESET` |
|---|---|---|
| Paginação de Classic Report e IR | limpa | reseta |
| IR: control break, aggregate, flashback, chart, nº de linhas, filtros, highlight, computation, group by | limpa | reseta para o padrão do desenvolvedor |
| IR: lista de colunas exibidas, ordenação, preferências (view mode etc.) | **mantém** | reseta |
| Ordenação de Classic Report | — | reseta |
| Configurações de Interactive Grid | — | reseta |
| Aba selecionada do Region Display Selector | — | reseta (só assinatura por ID cita o RDS) |

`PURGE_CACHE` sem página limpa o cache de todas as regiões da app; sem região, todas da página; `p_current_session_only => TRUE` limita à sessão.

Fonte: [CLEAR Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_REGION.CLEAR-Procedure-Signature-1.html), [CLEAR Procedure Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_REGION.CLEAR-Procedure-Signature-2.html), [RESET Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_REGION.RESET-Procedure-Signature-1.html), [RESET Procedure Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_REGION.RESET-Procedure-Signature-2.html), [PURGE_CACHE Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_REGION.PURGE_CACHE-Procedure-Signature-1.html), [PURGE_CACHE Procedure Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_REGION.PURGE_CACHE-Procedure-Signature-2.html)

## APEX_IR: Interactive Reports em PL/SQL (filtros, reset, relatórios salvos, assinaturas)

| Membro | O que faz |
|---|---|
| `c_view_report`, `c_view_groupby`, `c_view_pivot` | Constantes de view (`'REPORT'`, `'GROUP_BY'`, `'PIVOT'`) |
| `t_report` | Record `sql_query varchar2(32767)`, `binds apex_plugin_util.t_bind_list` |
| `ADD_FILTER` (por report ID, alias ou Static ID) | Cria filtro num IR |
| `CLEAR_REPORT` (3 assinaturas) | Limpa as configurações do relatório |
| `RESET_REPORT` (3 assinaturas) | Volta às configurações padrão do desenvolvedor |
| `GET_LAST_VIEWED_REPORT_ID` | ID do último relatório-base visto na região |
| `CLONE_REPORT` | Clona um relatório salvo de usuário (devolve novo ID) |
| `DELETE_REPORT` | Apaga um relatório salvo |
| `CHANGE_REPORT_OWNER` | Muda o dono de um relatório salvo |
| `EXPORT_SAVED_REPORTS` / `IMPORT_SAVED_REPORTS` | Exporta/importa relatórios salvos (assinados com credencial Key Pair) |
| `CHANGE_SUBSCRIPTION_EMAIL` / `CHANGE_SUBSCRIPTION_LANG` / `DELETE_SUBSCRIPTION` | Gestão de assinaturas (envio por e-mail) |
| `GET_REPORT` | **Deprecated**: use `APEX_REGION.OPEN_QUERY_CONTEXT` |

Fonte: [APEX_IR](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_IR.html), [Constants and Data Types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_IR.Constants-Data-Types.html)

### APEX_IR.ADD_FILTER: filtrar um Interactive Report a partir de um processo

```sql
APEX_IR.ADD_FILTER (                       -- assinatura 3 (Static IDs), recomendada
    p_page_id            IN NUMBER,
    p_region_static_id   IN VARCHAR2,
    p_report_column      IN VARCHAR2,      -- coluna ou alias do SQL
    p_filter_value       IN VARCHAR2,      -- ignorado para N/NN
    p_operator_abbr      IN VARCHAR2 DEFAULT NULL,
    p_report_static_id   IN VARCHAR2 DEFAULT NULL );   -- NULL = último relatório visto
-- assinatura 1: p_region_id + p_report_id;  assinatura 2: p_region_id + p_report_alias
```

Operadores: `EQ`, `NEQ`, `LT`, `LTE`, `GT`, `GTE`, `LIKE`, `NLIKE`, `N` (nulo), `NN` (não nulo), `C` (contém), `NC` (não contém), `IN`, `NIN`. Para vários valores com `IN`/`NIN`, separe por vírgula e envolva com barras invertidas: `p_filter_value => '\CLOSED,OPEN\'`.

```sql
-- Processo After Submit do botão "Filtrar departamento"
apex_ir.reset_report(p_page_id => 12, p_region_static_id => 'colaboradores');
apex_ir.add_filter(p_page_id          => 12,
                   p_region_static_id => 'colaboradores',
                   p_report_column    => 'ID_DEPARTAMENTO',
                   p_filter_value     => :P12_DEPTO,
                   p_operator_abbr    => 'EQ');
```

Fonte: [ADD_FILTER Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_FILTER-Procedure-Signature-1.html), [ADD_FILTER Procedure Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_FILTER-Procedure-Signature-2.html), [ADD_FILTER Procedure Signature 3](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_FILTER-Procedure-Signature-3.html)

### Download do Interactive Report/Grid não bate com o que o usuário vê (APEX_IR/APEX_IG em processo de renderização)

**Sintoma:** o usuário baixa CSV/HTML/e-mail do relatório e o arquivo vem com filtros diferentes dos da tela, ou o filtro "volta" ao baixar.
**Causa:** `ADD_FILTER`, `CLEAR_REPORT` e `RESET_REPORT` foram chamados num processo de **renderização** (Before Header etc.). No download, o IR/IG recarrega a página com o formato no REQUEST, e as mudanças de configuração feitas pelo usuário ocorreram por Ajax/partial refresh; o processo de render reaplica as alterações e o resultado diverge.
**Correção:** chame essas APIs apenas em processos de **submit** (After Submit / Processing), por exemplo atrás de um botão.
**Prevenção:** se precisar de um filtro "inicial", prefira condicionar o SQL da região a um item de página ou usar relatórios salvos padrão.

Fonte: [ADD_FILTER Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_FILTER-Procedure-Signature-1.html), [CLEAR_REPORT Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CLEAR_REPORT-Procedure-Signature-1.html), [APEX_IG ADD_FILTER Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_IG-ADD_FILTER-Procedure-Signature-1.html)

### APEX_IR.CLEAR_REPORT, RESET_REPORT e GET_LAST_VIEWED_REPORT_ID

```sql
APEX_IR.CLEAR_REPORT ( p_page_id, p_region_id, p_report_id    IN NUMBER   DEFAULT NULL );
APEX_IR.CLEAR_REPORT ( p_page_id, p_region_id, p_report_alias IN VARCHAR2 DEFAULT NULL );
APEX_IR.CLEAR_REPORT ( p_page_id, p_region_static_id, p_report_static_id IN VARCHAR2 DEFAULT NULL );
APEX_IR.RESET_REPORT ( ... mesmas 3 formas ... );   -- volta ao padrão definido pelo desenvolvedor
APEX_IR.GET_LAST_VIEWED_REPORT_ID ( p_page_id IN NUMBER, p_region_id IN VARCHAR2 ) RETURN NUMBER;  -- ID ou Static ID
```

Com o ID/alias/Static ID do relatório NULL, agem sobre o **último relatório visto**. `CLEAR_REPORT` limpa as configurações; `RESET_REPORT` remove todas as personalizações e volta ao padrão. Mesmo aviso: use em processos de submit.

Fonte: [CLEAR_REPORT Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CLEAR_REPORT-Procedure-Signature-1.html), [CLEAR_REPORT Procedure Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CLEAR_REPORT-Procedure-Signature-2.html), [CLEAR_REPORT Procedure Signature 3](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CLEAR_REPORT-Procedure-Signature-3.html), [RESET_REPORT Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/RESET_REPORT-Procedure-Signature-1.html), [RESET_REPORT Procedure Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/RESET_REPORT-Procedure-Signature-2.html), [RESET_REPORT Procedure Signature 3](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/RESET_REPORT-Procedure-Signature-3.html), [GET_LAST_VIEWED_REPORT_ID Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_LAST_VIEWED_REPORT_ID-Function-Signature-1.html)

### APEX_IR: relatórios salvos (CLONE_REPORT, DELETE_REPORT, CHANGE_REPORT_OWNER, EXPORT/IMPORT_SAVED_REPORTS)

```sql
APEX_IR.CLONE_REPORT (
    p_report_id       IN NUMBER,
    p_new_name        IN VARCHAR2,
    p_new_description IN VARCHAR2 DEFAULT NULL,
    p_new_owner       IN VARCHAR2 DEFAULT apex_application.g_user,   -- sensível a maiúsculas
    p_new_is_public   IN BOOLEAN  DEFAULT FALSE,
    p_replace_report  IN BOOLEAN  DEFAULT TRUE )                     -- FALSE: erro se já existe mesmo nome/dono
RETURN NUMBER;
APEX_IR.DELETE_REPORT ( p_report_id IN NUMBER );
APEX_IR.CHANGE_REPORT_OWNER ( p_report_id IN NUMBER, p_old_owner IN VARCHAR2, p_new_owner IN VARCHAR2 );
APEX_IR.EXPORT_SAVED_REPORTS ( p_report_ids IN apex_t_number, p_credential_static_id IN VARCHAR2 ) RETURN CLOB;
APEX_IR.IMPORT_SAVED_REPORTS ( p_export_content IN CLOB, p_credential_static_id IN VARCHAR2,
    p_replace_report IN BOOLEAN DEFAULT TRUE, p_new_owner IN VARCHAR2 DEFAULT apex_application.g_user,
    p_new_application_id IN NUMBER DEFAULT NULL );
```

- Não é possível clonar **para** um relatório padrão, nem mudar dono de relatório padrão. Relatório privado só pode ser clonado se o novo dono for o mesmo.
- Nomes de dono são **sensíveis a maiúsculas** e precisam ser usuários válidos.
- Export/Import usam uma *Web Credential* do tipo **Key Pair** (chaves geradas com OpenSSH) para assinar e verificar; o conteúdo é JSON assinado em base64. Fora do APEX, defina o workspace com `apex_util.set_workspace`.

Fonte: [CLONE_REPORT Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CLONE_REPORT-Function.html), [DELETE_REPORT Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/DELETE_REPORT-Procedure.html), [CHANGE_REPORT_OWNER Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CHANGE_REPORT_OWNER-Procedure.html), [EXPORT_SAVED_REPORTS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/EXPORT_SAVED_REPORTS-Function.html), [IMPORT_SAVED_REPORTS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/IMPORT_SAVED_REPORTS-Procedure.html)

### APEX_IR: assinaturas de e-mail (CHANGE_SUBSCRIPTION_EMAIL, CHANGE_SUBSCRIPTION_LANG, DELETE_SUBSCRIPTION) e GET_REPORT deprecated

```sql
APEX_IR.CHANGE_SUBSCRIPTION_EMAIL ( p_subscription_id IN NUMBER, p_email_address IN VARCHAR2 );  -- e-mail válido, não nulo
APEX_IR.CHANGE_SUBSCRIPTION_LANG  ( p_subscription_id IN NUMBER, p_language IN VARCHAR2 );       -- IANA: 'pt-br'
APEX_IR.DELETE_SUBSCRIPTION       ( p_subscription_id IN NUMBER );
APEX_IR.GET_REPORT ( p_page_id, p_region_id, p_report_id DEFAULT NULL,
                     p_view DEFAULT c_view_report ) RETURN t_report;    -- DEPRECATED
```

`GET_REPORT` (deprecated) devolvia a query de runtime + binds; para executar a query de um IR em PL/SQL hoje, use `APEX_REGION.OPEN_QUERY_CONTEXT`.

Fonte: [CHANGE_SUBSCRIPTION_EMAIL Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CHANGE_SUBSCRIPTION_EMAIL-Procedure.html), [CHANGE_SUBSCRIPTION_LANG Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CHANGE_SUBSCRIPTION_LANG-Procedure.html), [DELETE_SUBSCRIPTION Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/DELETE_SUBSCRIPTION-Procedure.html), [GET_REPORT Function (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_REPORT-Function.html)

## APEX_IG: Interactive Grids em PL/SQL (filtros, reset, relatórios salvos)

| Membro | O que faz |
|---|---|
| `ADD_FILTER` assinatura 1 (report ID) | Filtro de coluna ou de linha (busca) |
| `ADD_FILTER` assinatura 2 (report name) | **Deprecated**: use a assinatura 3 |
| `ADD_FILTER` assinatura 3 (Static IDs) | Filtro com Static ID da região e do relatório, separador multi-valor |
| `CLEAR_REPORT` (ID, nome, Static ID) | Limpa os filtros para o padrão do desenvolvedor |
| `RESET_REPORT` (ID, nome, Static ID) | Reseta todas as configurações para o padrão |
| `GET_LAST_VIEWED_REPORT_ID` | Último relatório-base visto |
| `DELETE_REPORT` | Apaga relatório salvo |
| `CHANGE_REPORT_OWNER` | Muda o dono de relatório salvo (não o padrão) |

Para gravar dados de IG use o processo declarativo *Interactive Grid - Automatic Row Processing (DML)*; `APEX_IG` trata das **configurações** do relatório.

Fonte: [APEX_IG](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_IG.html)

### APEX_IG.ADD_FILTER: filtro de coluna x filtro de linha (busca)

```sql
APEX_IG.ADD_FILTER (                          -- assinatura 3, recomendada
    p_page_id               IN NUMBER,
    p_region_static_id      IN VARCHAR2,
    p_filter_value          IN VARCHAR2,      -- ignorado para N/NN
    p_column_name           IN VARCHAR2 DEFAULT NULL,   -- NULL = filtro de LINHA (busca em todas as colunas)
    p_operator_abbr         IN VARCHAR2 DEFAULT NULL,
    p_is_case_sensitive     IN BOOLEAN  DEFAULT FALSE,  -- só vale para filtro de linha
    p_report_static_id      IN VARCHAR2 DEFAULT NULL,   -- NULL = último relatório visto
    p_multi_value_separator IN VARCHAR2 DEFAULT NULL ); -- separador para IN/NIN
-- assinatura 1: p_region_id + p_report_id
```

Operadores de IG: `EQ`, `NEQ`, `LT`, `LTE`, `GT`, `GTE`, `N`, `NN`, `C`, `NC`, `IN`, `NIN` (sem `LIKE`/`NLIKE`, que existem só no IR). Mesmo aviso do IR: use em processos de submit, não de renderização.

```sql
-- Filtro de coluna
apex_ig.add_filter(p_page_id => 26, p_region_static_id => 'equipes',
                   p_column_name => 'ID_DEPARTAMENTO', p_operator_abbr => 'EQ',
                   p_filter_value => :P26_DEPTO);
-- Filtro de linha (busca), sensível a maiúsculas
apex_ig.add_filter(p_page_id => 26, p_region_static_id => 'equipes',
                   p_filter_value => 'Marketing', p_is_case_sensitive => true);
-- IN com separador próprio
apex_ig.add_filter(p_page_id => 26, p_region_static_id => 'equipes',
                   p_column_name => 'STATUS', p_operator_abbr => 'IN',
                   p_filter_value => 'ATIVA;PAUSADA', p_multi_value_separator => ';');
```

Fonte: [ADD_FILTER Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_IG-ADD_FILTER-Procedure-Signature-1.html), [ADD_FILTER Procedure Signature 2 (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_IG-ADD_FILTER-Procedure-Signature-2.html), [ADD_FILTER Procedure Signature 3](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_IG-ADD_FILTER-Procedure-Signature-3.html)

### APEX_IG.CLEAR_REPORT, RESET_REPORT, DELETE_REPORT, CHANGE_REPORT_OWNER e GET_LAST_VIEWED_REPORT_ID

```sql
APEX_IG.CLEAR_REPORT ( p_page_id, p_region_id, p_report_id   IN NUMBER   DEFAULT NULL );
APEX_IG.CLEAR_REPORT ( p_page_id, p_region_id, p_report_name IN VARCHAR2 DEFAULT NULL );
APEX_IG.CLEAR_REPORT ( p_page_id, p_region_static_id, p_report_static_id IN VARCHAR2 DEFAULT NULL );
APEX_IG.RESET_REPORT ( ... mesmas 3 formas ... );
APEX_IG.DELETE_REPORT ( p_application_id IN NUMBER DEFAULT apex_application.g_flow_id, p_report_id IN NUMBER );
APEX_IG.CHANGE_REPORT_OWNER ( p_application_id IN NUMBER DEFAULT apex_application.g_flow_id,
    p_report_id IN NUMBER, p_old_owner IN VARCHAR2, p_new_owner IN VARCHAR2 );   -- donos sensíveis a maiúsculas
APEX_IG.GET_LAST_VIEWED_REPORT_ID ( p_page_id IN NUMBER, p_region_id IN VARCHAR2 ) RETURN NUMBER;
```

`CLEAR_REPORT` volta os **filtros** ao padrão; `RESET_REPORT` volta **todas** as configurações ao padrão do desenvolvedor. Diferente do IR, `DELETE_REPORT` e `CHANGE_REPORT_OWNER` do IG aceitam `p_application_id`.

Fonte: [CLEAR_REPORT Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_IG-CLEAR_REPORT-Procedure-Signature-1.html), [CLEAR_REPORT Procedure Signature 3](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_IG-CLEAR_REPORT-Procedure-Signature-3.html), [RESET_REPORT Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_IG-RESET_REPORT-Procedure-Signature-1.html), [RESET_REPORT Procedure Signature 3](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_IG-RESET_REPORT-Procedure-Signature-3.html), [DELETE_REPORT Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_IG-DELETE_REPORT-Procedure.html), [CHANGE_REPORT_OWNER Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_IG-CHANGE_REPORT_OWNER-Procedure.html), [GET_LAST_VIEWED_REPORT_ID Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_IG-GET_LAST_VIEWED_REPORT_ID-Function-Signature-1.html)
## APEX_LANG: text messages traduzíveis e tradução de aplicações

`APEX_LANG` cobre dois usos: (1) **mensagens de texto** (*Shared Components > Text Messages*) usadas em PL/SQL e JS; (2) o fluxo de **tradução da aplicação** (mapeamento de idioma, seed, XLIFF, publish).

| Membro | O que faz |
|---|---|
| `GET_MESSAGE` | Texto traduzido de um text message, com placeholders nomeados (`%nome`) |
| `MESSAGE` | **Deprecated**: use `GET_MESSAGE` (placeholders `%0..%9`) |
| `LANG` | Tradução via *Dynamic Translations* (texto do idioma primário → traduzido) |
| `CREATE_MESSAGE` / `UPDATE_MESSAGE` (2 assinaturas) / `DELETE_MESSAGE` | CRUD de text messages |
| `EXPORT_TEXT_MESSAGES` (1 idioma → CLOB; todos → ZIP BLOB) | Exporta mensagens em XLIFF ou CSV |
| `IMPORT_TEXT_MESSAGES` (CLOB ou ZIP) | Importa mensagens |
| `CREATE_LANGUAGE_MAPPING` / `UPDATE_LANGUAGE_MAPPING` / `DELETE_LANGUAGE_MAPPING` | Mapeamento idioma → app traduzida |
| `SEED_TRANSLATIONS` | Popula o repositório de tradução com strings novas/alteradas/removidas |
| `GET_XLIFF_DOCUMENT` / `APPLY_XLIFF_DOCUMENT` | Gera/aplica o XLIFF de um idioma |
| `UPDATE_TRANSLATED_STRING` | Altera uma string traduzida no repositório |
| `PUBLISH_APPLICATION` | Publica a versão traduzida (réplica oculta da app) |
| `EMIT_LANGUAGE_SELECTOR_LIST` / `GET_LANGUAGE_SELECTOR_LIST` | Seletor de idioma (imprime / devolve HTML) |

Fonte: [APEX_LANG](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_LANG.html)

### APEX_LANG.GET_MESSAGE: mensagens traduzíveis com placeholders nomeados

```sql
APEX_LANG.GET_MESSAGE (
    p_name           IN VARCHAR2,                              -- nome do Text Message
    p_params         IN apex_t_varchar2 DEFAULT apex_t_varchar2(),  -- pares nome, valor
    p_lang           IN VARCHAR2        DEFAULT NULL,          -- NULL = idioma atual (Application Language Derived From)
    p_application_id IN NUMBER          DEFAULT NULL )         -- útil fora do APEX (jobs)
RETURN VARCHAR2;
```

Os placeholders do texto são nomeados (`%name`, `%age`) e `p_params` traz pares `'name', valor, 'age', valor`, substituídos da esquerda para a direita. O antigo `APEX_LANG.MESSAGE` (posicional `%0..%9`) está **deprecated**.

```sql
-- Text Message BOAS_VINDAS (pt-br): 'Olá %nome, você tem %qtd comunicados novos'
l_txt := apex_lang.get_message('BOAS_VINDAS',
                               apex_t_varchar2('nome', :G_PRIMEIRO_NOME, 'qtd', l_qtd));
```

Mesmo que a app tenha um idioma só, centralizar textos em Text Messages permite reaproveitá-los em `APEX_ERROR.ADD_ERROR(p_error_code => ...)` e em JS (`apex.lang`, marcando *Used in JavaScript*).

Fonte: [GET_MESSAGE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_LANG.GET_MESSAGE-Function.html), [MESSAGE Function (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/MESSAGE-Function.html)

### APEX_LANG.LANG: traduzir dados com Dynamic Translations

```sql
APEX_LANG.LANG (
    p_primary_text_string IN VARCHAR2 DEFAULT NULL,   -- valor "Translate From Text"
    p0 .. p9              IN VARCHAR2 DEFAULT NULL,   -- %0..%9
    p_primary_language    IN VARCHAR2 DEFAULT NULL )
RETURN VARCHAR2;
```

Traduz valores vindos de dados (ex.: `select apex_lang.lang(cor) from cores` devolve `ROT` numa sessão em alemão se a tradução dinâmica de `RED` existir).

Fonte: [LANG Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/LANG_Function.html)

### APEX_LANG.CREATE_MESSAGE, UPDATE_MESSAGE, DELETE_MESSAGE e EXPORT/IMPORT_TEXT_MESSAGES

```sql
APEX_LANG.CREATE_MESSAGE (
    p_application_id     IN NUMBER,        -- app de idioma primário
    p_name               IN VARCHAR2,
    p_language           IN VARCHAR2,      -- IANA: 'pt-br', 'en-us'
    p_message_text       IN VARCHAR2,
    p_used_in_javascript IN BOOLEAN  DEFAULT FALSE,
    p_comment            IN VARCHAR2 DEFAULT NULL,
    p_metadata           IN CLOB     DEFAULT NULL );   -- não usado pelo APEX
APEX_LANG.UPDATE_MESSAGE ( p_id IN NUMBER, p_message_text IN VARCHAR2 );
APEX_LANG.UPDATE_MESSAGE ( p_id, p_name, p_language, p_message_text, p_used_in_javascript, p_comment, p_metadata );
APEX_LANG.DELETE_MESSAGE ( p_id IN NUMBER );
APEX_LANG.EXPORT_TEXT_MESSAGES ( p_application_id, p_lang_code,
                                 p_format IN t_export_format DEFAULT c_export_format_xliff ) RETURN CLOB;
APEX_LANG.EXPORT_TEXT_MESSAGES ( p_application_id, p_format DEFAULT c_export_format_xliff ) RETURN BLOB;  -- ZIP
APEX_LANG.IMPORT_TEXT_MESSAGES ( p_application_id, p_file IN CLOB, p_format DEFAULT c_export_format_xliff );
APEX_LANG.IMPORT_TEXT_MESSAGES ( p_application_id, p_zip_file IN BLOB );
```

Formatos: `apex_lang.c_export_format_xliff` (padrão) ou `apex_lang.c_export_format_csv`. **Pegadinha:** `UPDATE_MESSAGE` levanta erro se a mensagem for **subscrita** (fica somente leitura; mude a mestre e publique, ou desinscreva no App Builder, já que não há API para desinscrever).

Fonte: [CREATE_MESSAGE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_LANG.CREATE_MESSAGE-Procedure.html), [UPDATE_MESSAGE Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_LANG.UPDATE_MESSAGE-Procedure-Signature-1.html), [UPDATE_MESSAGE Procedure Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_LANG.UPDATE_MESSAGE-Procedure-Signature-2.html), [DELETE_MESSAGE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/DELETE_MESSAGE-Procedure.html), [EXPORT_TEXT_MESSAGES Function Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_LANG.EXPORT_TEXT_MESSAGES-Function-Signature-1.html), [EXPORT_TEXT_MESSAGES Function Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_LANG.EXPORT_TEXT_MESSAGES-Function-Signature-2.html), [IMPORT_TEXT_MESSAGES Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_LANG.IMPORT_TEXT_MESSAGES-Procedure-Signature-1.html), [IMPORT_TEXT_MESSAGES Procedure Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_LANG.IMPORT_TEXT_MESSAGES-Procedure-Signature-2.html)

### APEX_LANG: fluxo de tradução por API (mapping, seed, XLIFF, publish)

```sql
APEX_LANG.CREATE_LANGUAGE_MAPPING ( p_application_id, p_language,
    p_translation_application_id IN NUMBER,           -- não pode terminar em 0
    p_direction_right_to_left IN BOOLEAN DEFAULT FALSE, p_image_directory IN VARCHAR2 DEFAULT NULL );
APEX_LANG.UPDATE_LANGUAGE_MAPPING ( p_application_id, p_language, p_new_trans_application_id );
APEX_LANG.DELETE_LANGUAGE_MAPPING ( p_application_id, p_language );   -- apaga também as strings traduzidas
APEX_LANG.SEED_TRANSLATIONS ( p_application_id, p_language );
APEX_LANG.GET_XLIFF_DOCUMENT ( p_application_id, p_page_id DEFAULT NULL, p_language,
                               p_only_modified_elements IN BOOLEAN DEFAULT FALSE ) RETURN CLOB;
APEX_LANG.APPLY_XLIFF_DOCUMENT ( p_application_id, p_language, p_document IN CLOB );
APEX_LANG.UPDATE_TRANSLATED_STRING ( p_id, p_language, p_string );
APEX_LANG.PUBLISH_APPLICATION ( p_application_id, p_language, p_new_trans_application_id DEFAULT NULL );
APEX_LANG.EMIT_LANGUAGE_SELECTOR_LIST;               -- em região PL/SQL
APEX_LANG.GET_LANGUAGE_SELECTOR_LIST RETURN VARCHAR2; -- HTML para Dynamic Content
```

Ordem: mapear o idioma → `SEED_TRANSLATIONS` → traduzir (XLIFF ou `UPDATE_TRANSLATED_STRING`) → `PUBLISH_APPLICATION`. Repita seed + publish sempre que a app primária mudar. A app traduzida é uma réplica **oculta**: pode ser publicada e exportada, mas não editada no App Builder.

Fonte: [CREATE_LANGUAGE_MAPPING Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CREATE_LANGUAGE_MAPPING-Procedure.html), [SEED_TRANSLATIONS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SEED_TRANSLATIONS-Procedure.html), [GET_XLIFF_DOCUMENT Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_XLIFF_DOCUMENT-Function.html), [APPLY_XLIFF_DOCUMENT Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APPLY_XLIFF_DOCUMENT-Procedure.html), [PUBLISH_APPLICATION Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PUBLISH_APPLICATION-Procedure.html), [UPDATE_LANGUAGE_MAPPING Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/UPDATE_LANGUAGE_MAPPING-Procedure.html), [DELETE_LANGUAGE_MAPPING Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/DELETE_LANGUAGE_MAPPING-Procedure.html), [UPDATE_TRANSLATED_STRING Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/UPDATE_TRANSLATED_STRING-Procedure.html), [EMIT_LANGUAGE_SELECTOR_LIST Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/EMIT_LANGUAGE_SELECTOR_LIST-Procedure.html), [GET_LANGUAGE_SELECTOR_LIST Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_LANGUAGE_SELECTOR_LIST-Function.html)

## APEX_CSS: incluir CSS na página a partir de PL/SQL

Usado principalmente em plug-ins.

| Membro | O que faz |
|---|---|
| `ADD` | Adiciona CSS inline (com `p_key` para não duplicar) |
| `ADD_FILE` | Adiciona `<link>` para um arquivo CSS (não duplica) |
| `ADD_3RD_PARTY_LIBRARY_FILE` | **Deprecated**: CSS de biblioteca de terceiros considerando CDN |

```sql
APEX_CSS.ADD ( p_css IN VARCHAR2, p_key IN VARCHAR2 DEFAULT NULL );   -- mesma key = ignorado
APEX_CSS.ADD_FILE (
    p_name           IN VARCHAR2,
    p_directory      IN VARCHAR2 DEFAULT apex_application.g_image_prefix || 'css/',  -- em plug-in: p_plugin.file_prefix
    p_version        IN VARCHAR2 DEFAULT NULL,
    p_skip_extension IN BOOLEAN  DEFAULT FALSE,   -- por padrão acrescenta .css
    p_media_query    IN VARCHAR2 DEFAULT NULL,
    p_ie_condition   IN VARCHAR2 DEFAULT NULL,    -- desuportado, sem efeito
    p_attributes     IN VARCHAR2 DEFAULT NULL );  -- quem chama deve escapar
```

```sql
apex_css.add(p_css => '.cx-card-destaque{border-left:4px solid var(--cx-primaria)}', p_key => 'cx-card-destaque');
```

Fonte: [APEX_CSS](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_CSS.html), [ADD Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD-Procedure.html), [ADD_FILE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_FILE-Procedure.html), [ADD_3RD_PARTY_LIBRARY_FILE Procedure (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_3RD_PARTY_LIBRARY_FILE-Procedure.html)

## APEX_JAVASCRIPT: injetar JavaScript e montar valores JS a partir de PL/SQL

| Membro | O que faz |
|---|---|
| `t_function_type`: `c_type_function`(1), `c_type_function_body`(2), `c_type_expression`(3) | Tipos de código para `APEX_T_JAVASCRIPT_OBJECT.PUT_FUNCTION` |
| `ADD_ONLOAD_CODE` | Código executado no onload da página |
| `ADD_INLINE_CODE` | Código inline (funções, variáveis globais) |
| `ADD_LIBRARY` | `<script>` para um arquivo JS (módulo, async, defer, RequireJS) |
| `ADD_REQUIREJS` / `ADD_REQUIREJS_DEFINE` | Carrega RequireJS / registra um módulo |
| `ADD_JET` | Carrega Oracle JET |
| `ADD_3RD_PARTY_LIBRARY_FILE` | **Deprecated** |
| `ADD_ATTRIBUTE` (VARCHAR2, NUMBER, BOOLEAN, DATE) | Gera `nome:valor,` para objeto JS |
| `ADD_VALUE` (VARCHAR2, NUMBER, BOOLEAN, DATE) | Gera valor JS (`"texto",`) |
| `ESCAPE` | Escapa texto para JS (usa `APEX_ESCAPE.JS_LITERAL`) |

Fonte: [APEX_JAVASCRIPT](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_JAVASCRIPT.html), [Data Types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_JAVASCRIPT.Data-Types.html)

### APEX_JAVASCRIPT.ADD_ONLOAD_CODE, ADD_INLINE_CODE e ADD_LIBRARY: assinaturas e cuidados

```sql
APEX_JAVASCRIPT.ADD_ONLOAD_CODE ( p_code IN VARCHAR2, p_key IN VARCHAR2 DEFAULT NULL );
APEX_JAVASCRIPT.ADD_INLINE_CODE ( p_code IN VARCHAR2, p_key IN VARCHAR2 DEFAULT NULL );
APEX_JAVASCRIPT.ADD_LIBRARY (
    p_name                    IN VARCHAR2,                 -- sem .js
    p_directory               IN VARCHAR2,                 -- com barra final
    p_version                 IN VARCHAR2 DEFAULT NULL,
    p_check_to_add_minified   IN BOOLEAN  DEFAULT FALSE,   -- usa .min fora do modo debug
    p_skip_extension          IN BOOLEAN  DEFAULT FALSE,
    p_ie_condition            IN VARCHAR2 DEFAULT NULL,
    p_requirejs_module        IN VARCHAR2 DEFAULT NULL,
    p_requirejs_js_expression IN VARCHAR2 DEFAULT NULL,
    p_requirejs_required      IN BOOLEAN  DEFAULT FALSE,
    p_is_module               IN BOOLEAN  DEFAULT FALSE,   -- type="module"
    p_is_async                IN BOOLEAN  DEFAULT FALSE,
    p_is_defer                IN BOOLEAN  DEFAULT FALSE,   -- não combine com async nem com module
    p_attributes              IN VARCHAR2 DEFAULT NULL,    -- quem chama deve escapar
    p_key                     IN VARCHAR2 DEFAULT NULL );  -- padrão: p_directory||p_name||p_version
```

- `ADD_INLINE_CODE` é para **declarações** (funções, variáveis); para **executar** código use `ADD_ONLOAD_CODE`.
- `p_key` evita duplicar o snippet quando o mesmo componente aparece várias vezes; com `p_key` NULL o código é sempre adicionado.
- Todo valor vindo do banco que entra no código deve passar por `APEX_ESCAPE.JS_LITERAL`.

```sql
apex_javascript.add_onload_code(
    p_code => 'apex.message.showPageSuccess(' || apex_escape.js_literal(l_msg) || ');',
    p_key  => 'msg-boas-vindas');
```

Fonte: [ADD_ONLOAD_CODE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_ONLOAD_CODE-Procedure.html), [ADD_INLINE_CODE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_INLINE_CODE-Procedure.html), [ADD_LIBRARY Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_LIBRARY-Procedure.html), [ADD_REQUIREJS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_REQUIREJS-Procedure.html), [ADD_REQUIREJS_DEFINE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_REQUIREJS_DEFINE-Procedure.html), [ADD_JET Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_JET-Procedure.html)

### APEX_JAVASCRIPT.ADD_ATTRIBUTE, ADD_VALUE e ESCAPE: montar objetos JS (e o limite de escape)

```sql
APEX_JAVASCRIPT.ADD_ATTRIBUTE ( p_name IN VARCHAR2, p_value IN VARCHAR2 | NUMBER | BOOLEAN | DATE,
                                p_omit_null IN BOOLEAN := TRUE, p_add_comma IN BOOLEAN := TRUE ) RETURN VARCHAR2;
APEX_JAVASCRIPT.ADD_VALUE ( p_value IN VARCHAR2 | NUMBER | BOOLEAN | DATE,
                            p_add_comma IN BOOLEAN := TRUE ) RETURN VARCHAR2;
APEX_JAVASCRIPT.ESCAPE ( p_text IN VARCHAR2 ) RETURN VARCHAR2;
```

- `ADD_ATTRIBUTE` devolve `nome:"valor",`; com `p_omit_null => TRUE` e valor NULL não devolve nada; com `FALSE` devolve `nome:null`. DATE vira objeto Date JS.
- **Segurança:** `ADD_ATTRIBUTE`/`ADD_VALUE` só impedem que o texto quebre a atribuição JS; **não** escapam HTML. `ESCAPE` também escapa `<` e `>`, mas não outras tags. Se o valor for injetado em HTML, aplique também `sys.htf.escape_sc` (ou `APEX_ESCAPE.HTML`).
- Para objetos maiores, prefira `APEX_T_JAVASCRIPT_OBJECT`.

```sql
apex_javascript.add_onload_code(
    'cxOrganograma.init({' ||
        apex_javascript.add_attribute('regiao',  'organograma') ||
        apex_javascript.add_attribute('empresa', to_number(:G_ID_EMPRESA)) ||
        apex_javascript.add_attribute('editavel', apex_authorization.is_authorized('ADMIN_RH'), p_add_comma => false) ||
    '});');
```

Fonte: [ADD_ATTRIBUTE Function Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_ATTRIBUTE-Function-Signature-1.html), [ADD_ATTRIBUTE Function Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_ATTRIBUTE-Function-Signature-2.html), [ADD_ATTRIBUTE Function Signature 3](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_ATTRIBUTE-Function-Signature-3.html), [ADD_ATTRIBUTE Function Signature 4](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_ATTRIBUTE-Function-Signature-4.html), [ADD_VALUE Function Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_VALUE-Function-Signature-1.html), [Escape Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/Escape-Function.html)

## APEX_T_JAVASCRIPT_OBJECT: construir objetos JavaScript (com funções) em PL/SQL

Object type para montar **objetos JavaScript** a enviar ao navegador. Não gera JSON: aceita propriedades não escapadas, como funções. Para JSON, a doc indica usar recursos nativos do banco (`sys.json_object_t`).

| Membro | O que faz |
|---|---|
| Constructor `apex_t_javascript_object()` | Cria objeto vazio |
| `OPEN_OBJECT(p_key DEFAULT NULL)` / `CLOSE_OBJECT` | Abre/fecha objeto (sem key na raiz ou dentro de array) |
| `OPEN_ARRAY(p_key DEFAULT NULL)` / `CLOSE_ARRAY` | Abre/fecha array |
| `PUT(p_key, p_value, p_omit_null DEFAULT TRUE)` | Par chave/valor: VARCHAR2, NUMBER, BOOLEAN, CLOB, `apex_t_javascript_object`, `apex_t_varchar2`/`apex_t_number` (`p_omit_empty`) |
| `PUT_FUNCTION(p_key, p_code, p_type, p_omit_null)` | Função JS (sem escape) |
| `PUT_RAW(p_key, p_value)` | Valor bruto (`undefined`, `NaN`, `apex.jQuery`) |
| `APPEND(...)` (7 assinaturas) | Elemento de array: VARCHAR2, NUMBER, BOOLEAN, CLOB, objeto, `apex_t_varchar2`/`apex_t_number` (com `p_spread`) |
| `APPEND_FUNCTION`, `APPEND_RAW` | Função / valor bruto em array |
| `IS_NULL` | `TRUE` se nada foi escrito desde a criação |
| `RESET` | Zera o objeto |
| `TO_CLOB` | Serializa; erro se houver estrutura não fechada; `'null'` se nada foi escrito |

Regras: sempre comece com `OPEN_OBJECT` ou `OPEN_ARRAY` **sem** key (raiz); todo open precisa do close correspondente. `PUT_FUNCTION`/`PUT_RAW`/`APPEND_RAW` **não escapam**: nunca passe dados do usuário. `p_type` de função: `c_type_function` (como está), `c_type_function_body` (envolve em `function(){...}`), `c_type_expression` (envolve e faz `return`). `APPEND(..., p_spread => TRUE)` espalha os valores no array aberto em vez de criar um array aninhado.

```sql
declare
    l_cfg apex_t_javascript_object := apex_t_javascript_object();
begin
    l_cfg.open_object;
    l_cfg.put('regiao', 'organograma');
    l_cfg.put('niveis', 3);
    l_cfg.put('ids', apex_t_number(10, 20, 30));
    l_cfg.put_function(p_key => 'onClick', p_code => 'cxOrganograma.abrir(this.data.id);',
                       p_type => apex_javascript.c_type_function_body);
    l_cfg.close_object;
    apex_javascript.add_onload_code('cxOrganograma.init(' || l_cfg.to_clob || ');');
end;
```

Fonte: [APEX_T_JAVASCRIPT_OBJECT](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/apex_t_javascript_object.html), [Constructor](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/constructor-apex_t_javascript_object.html), [PUT Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/put-procedure-signature-1-apex_t_javascript_object.html), [PUT_FUNCTION Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/put_function-procedure-apex_t_javascript_object.html), [PUT_RAW Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/put_raw-procedure-apex_t_javascript_object.html), [APPEND Procedure Signature 6](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/append-procedure-signature-6-apex_t_javascript_object.html), [OPEN_OBJECT Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/open_object-procedure-apex_t_javascript_object.html), [TO_CLOB Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/to_clob-function-apex_t_javascript_object.html), [IS_NULL Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/is_null-function-apex_t_javascript_object.html), [RESET Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/reset-procedure-apex_t_javascript_object.html)

## APEX_THEME: theme styles por sessão, por usuário e da aplicação

| Membro | O que faz |
|---|---|
| `SET_SESSION_STYLE` | Define o theme style da **sessão** (por Static ID; cai para nome por compatibilidade) |
| `SET_SESSION_STYLE_CSS` | Define URLs de CSS de estilo para a sessão (sem estilo persistente) |
| `SET_USER_STYLE` / `GET_USER_STYLE` / `CLEAR_USER_STYLE` | Preferência de estilo do usuário (precede o da sessão) |
| `CLEAR_ALL_USERS_STYLE` | Limpa as preferências de todos os usuários |
| `ENABLE_USER_STYLE` / `DISABLE_USER_STYLE` | Liga/desliga o link *Customize* para o usuário escolher estilo |
| `SET_CURRENT_STYLE` | Muda o estilo **padrão da aplicação** (persistente) |

```sql
APEX_THEME.SET_SESSION_STYLE ( p_application_id IN apex_application.g_flow_id,
                               p_theme_number IN apex_themes.theme_id, p_name IN VARCHAR2 );  -- Static ID do estilo
APEX_THEME.SET_SESSION_STYLE_CSS ( p_application_id DEFAULT {app atual}, p_theme_number DEFAULT {tema atual},
                                   p_css_file_urls IN VARCHAR2, p_page_css_classes IN VARCHAR2 DEFAULT NULL );
APEX_THEME.SET_USER_STYLE ( p_application_id, p_user DEFAULT {usuário atual}, p_theme_number, p_id IN NUMBER );
APEX_THEME.GET_USER_STYLE ( p_application_id, p_user, p_theme_number ) RETURN NUMBER;   -- NULL sem preferência
APEX_THEME.SET_CURRENT_STYLE ( p_application_id DEFAULT {app atual}, p_theme_number IN NUMBER, p_id IN VARCHAR2 );
```

- `SET_SESSION_STYLE`/`SET_SESSION_STYLE_CSS` costumam ser chamados logo após a autenticação. `p_page_css_classes` vai para o placeholder `PAGE_CSS_CLASSES`.
- Preferência de usuário (`SET_USER_STYLE`) **tem precedência** sobre o estilo de sessão.
- `ENABLE_USER_STYLE` mostra o link *Customize* se houver ao menos um estilo marcado *Public*; afeta só o link, não as chamadas de API.
- `SET_CURRENT_STYLE` é persistente e exige *Shared Components > Security > Runtime API Usage > Modify this Application* ativado. Substitui o deprecated `APEX_UTIL.SET_CURRENT_THEME_STYLE`.

Fonte: [APEX_THEME](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_THEME.html), [SET_SESSION_STYLE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_SESSION_STYLE-Procedure.html), [SET_SESSION_STYLE_CSS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_SESSION_STYLE_CSS-Procedure.html), [SET_USER_STYLE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_USER_STYLE-Procedure.html), [GET_USER_STYLE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_USER_STYLE-Function.html), [CLEAR_USER_STYLE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CLEAR_USER_STYLE-Procedure.html), [CLEAR_ALL_USERS_STYLE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CLEAR_ALL_USERS_STYLE-Procedure.html), [ENABLE_USER_STYLE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ENABLE_USER_STYLE-Procedure.html), [DISABLE_USER_STYLE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/DISABLE_USER_STYLE-Procedure.html), [SET_CURRENT_STYLE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_CURRENT_STYLE-Procedure.html)

## APEX_MARKDOWN: converter Markdown em HTML no banco (TO_HTML)

Parser compatível com **CommonMark 0.29**.

```sql
APEX_MARKDOWN.TO_HTML (
    p_markdown              IN CLOB,
    p_embedded_html_mode    IN t_embedded_html_mode DEFAULT c_embedded_html_escape,   -- ou c_embedded_html_preserve
    p_softbreak             IN VARCHAR2             DEFAULT '<br />',                 -- ex.: apex_application.LF
    p_extra_link_attributes IN apex_t_varchar2      DEFAULT apex_t_varchar2() )       -- plist de atributos para <a>
RETURN CLOB;
```

Constantes: `c_embedded_html_escape` (`'ESCAPE'`, padrão: escapa HTML embutido) e `c_embedded_html_preserve` (`'PRESERVE'`: mantém o HTML). **Use `PRESERVE` só com conteúdo confiável** (risco de XSS). Para abrir links em nova aba: `p_extra_link_attributes => apex_t_varchar2('target', '_blank')`.

```sql
select apex_markdown.to_html(c.corpo_md, p_extra_link_attributes => apex_t_varchar2('target','_blank')) corpo_html
  from comunicado c
 where c.id_empresa = :G_ID_EMPRESA;
```

Fonte: [APEX_MARKDOWN](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_MARKDOWN.html), [Constants](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_MARKDOWN-Constants.html), [TO_HTML Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/TO_HTML-Function.html)

## APEX_SHARED_COMPONENT: publicar e atualizar componentes subscritos

Só disponível em instalações completas do APEX (não *runtime-only*).

```sql
APEX_SHARED_COMPONENT.PUBLISH ( p_component_type IN t_component_type, p_component_id IN NUMBER );  -- mestre → assinantes
APEX_SHARED_COMPONENT.REFRESH ( p_component_type IN t_component_type, p_component_id IN NUMBER );  -- assinante ← mestre
```

Tipos (`t_component_type`): `c_app_computation`, `c_app_item`, `c_app_process`, `c_app_setting`, `c_authentication`, `c_authorization`, `c_build_option`, `c_component_group`, `c_component_setting` (`PLUGIN_SETTINGS`), `c_custom_map_bkg`, `c_data_load`, `c_email_template`, `c_list`, `c_lov`, `c_message`, `c_plugin`, `c_report_layout`, `c_search_config`, `c_shortcut`, `c_user_group` (`APP_ACL`), `c_rest_data_source` (`WEB_SOURCE`), `c_duality_view`, `c_json_source`, `c_ai_config`. Status de subscrição (`t_subscription_status`): `c_status_up_to_date`, `c_status_needs_refresh`, `c_status_unknown`.

Fonte: [APEX_SHARED_COMPONENT](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_SHARED_COMPONENT.html), [Global Constants](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_SHARED_COMPONENT.Global-Constants.html), [PUBLISH Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_SHARED_COMPONENT.PUBLISH-Procedure.html), [REFRESH Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_SHARED_COMPONENT.REFRESH-Procedure.html)

## APEX_APP_OBJECT_DEPENDENCY: relatório de dependências de objetos do banco (e SQL inválido)

Varre a aplicação (ou uma página) e lista os objetos de banco de que ela depende (tabelas, views, procedures, functions, packages, sinônimos) em forms, relatórios, regiões PL/SQL, condições, plug-ins etc. Também serve para **achar SQL/PL/SQL inválido** na app.

```sql
APEX_APP_OBJECT_DEPENDENCY.SCAN (
    p_application_id IN NUMBER,
    p_page_id        IN NUMBER   DEFAULT NULL,          -- uma página só
    p_options        IN VARCHAR2 DEFAULT c_option_all );
APEX_APP_OBJECT_DEPENDENCY.CLEAR_CACHE ( p_application_id IN NUMBER );
```

| `p_options` | Efeito |
|---|---|
| `c_option_all` (`'ALL'`, padrão) | Varre tudo |
| `c_option_dependencies` | Só dependências de topo via `dba_dependencies` |
| `c_option_identifiers` | Dependências detalhadas via PL/Scope (colunas de tabelas/views, membros de packages compilados com `identifiers:all`) |
| `c_option_errors` | Só erros de compilação |

Resultados nas views `APEX_USED_DB_OBJECT_COMP_PROPS` (todo SQL/PLSQL encontrado, inclusive mensagens de erro de compilação), `APEX_USED_DB_OBJECTS` (objetos referenciados) e `APEX_USED_DB_OBJ_DEPENDENCIES` (dependências). Ficam salvos até novo scan, `CLEAR_CACHE` ou upgrade da instância. Requer `CREATE PROCEDURE` no schema dono da app.

Limitações: não detecta SQL dinâmico (`execute immediate`, `dbms_sql`), nem o SQL gerado por *Function Returning SQL*, nem dependências recursivas (use `USER_DEPENDENCIES`), nem scripts de *Supporting Objects*. Para métodos de package, compile antes com PL/Scope:

```sql
alter session set plscope_settings='identifiers:all';
exec sys.dbms_utility.compile_schema(user, true);
alter session set plscope_settings='identifiers:none';

begin
    apex_app_object_dependency.scan(p_application_id => 100);
end;
/
select * from apex_used_db_objects;   -- filtre pela app conforme as colunas da view
```

Fonte: [APEX_APP_OBJECT_DEPENDENCY](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APP_OBJECT_DEPENDENCY.html), [SCAN Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APP_OBJECT_DEPENDENCY.SCAN-Procedure.html), [CLEAR_CACHE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APP_OBJECT_DEPENDENCY.CLEAR_CACHE-Procedure.html), [Constants](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APP_OBJECT_DEPENDENCY.Constants.html)
## APEX_PLUGIN: tipos e interface para desenvolver plug-ins

`APEX_PLUGIN` declara os **tipos** que o APEX passa às funções de callback de cada tipo de plug-in (região, item, dynamic action, processo, autenticação, autorização, REST Data Source, AI tool) e algumas funções utilitárias.

| Membro | O que faz |
|---|---|
| `GET_AJAX_IDENTIFIER` | ID do callback Ajax do plug-in (só na função de render, e só se o plug-in define Ajax) |
| `GET_INPUT_NAME_FOR_ITEM` | Valor do atributo `name` do `<input>` para o valor ir ao session state no submit |
| `GET_INPUT_NAME_FOR_PAGE_ITEM` | **Deprecated**: use `GET_INPUT_NAME_FOR_ITEM` |
| `GET_KEEP_BACKGROUND_EXECS` | Se execuções em background são preservadas no upgrade da app (a doc mostra a sintaxe em `APEX_APPLICATION_INSTALL`) |
| `t_escape_mode` + `c_escape_mode_raw/html/html_attribute/javascript/striphtml/json` | Modos de escape de substituições |
| `t_plugin` | `static_id`, `file_prefix`, `attributes` (os `attribute_01..15` e `name` são **deprecated**) |
| `t_plugin_attributes` | Objeto com `get_varchar2`, `get_number`, `get_boolean` (Y→TRUE, N→FALSE), `put` |
| Constantes de REST Data Source | `c_format_xml/json/csv`, `c_db_operation_*`, `c_web_src_param_*`, `c_direction_*`, `c_row_*` |
| Constantes de AI Tool | `c_ai_tool_augment_sys_prompt`, `c_ai_tool_on_demand` |
| Tipos de autenticação | `t_authentication`, `t_authentication_auth_result` (`is_authenticated`, `redirect_url`, `log_code`, `log_text`, `display_text`), `_sentry_result` (`is_valid`), `_inval_result`, `_logout_result`, `_ajax_result` |
| Tipos de autorização | `t_authorization` (`id`, `name`, `username`, `caching`, `component`, `attributes`), `t_authorization_exec_result` (`is_authorized`) |
| Tipos de dynamic action | `t_dynamic_action`, `t_dynamic_action_render_result` (`ajax_identifier`, `function_name`, `function_param`), `_render_param`, `_ajax_param`, `_ajax_result` |
| Tipos de item | `t_item` (nome, LOV, formato, required, escape…), `t_item_render_param` (`value`, `clob_value`, `is_readonly`, `is_printer_friendly`), `t_item_render_result`, `t_item_validation_result` (`message`, `display_location`, `page_item_name`), `t_item_meta_data_result`, `t_item_ajax_result`; constantes `c_inline_in_notification`, `c_inline_with_field`, `c_inline_with_field_and_notif`, `c_on_error_page` |
| Tipos de processo | `t_process`, `t_process_exec_result` (`success_message`, `execution_skipped`) |
| Tipos de região | `t_region` (`dom_id`, `source`, `lazy_loading`, `ajax_items_to_submit`, `fetched_rows`, `escape_output`, `region_columns`…), `t_region_column(s)`, `t_region_render_param` (`is_printer_friendly`), `t_region_render_result` (`navigable_dom_id`), `t_region_ajax_result` |
| Tipos de REST Data Source | `t_web_source`, `t_web_source_capabilities`, `_column`, `_operation`, `_parameter`, `_fetch_params/_result`, `_dml_params/_result`, `_execute_result`, `_discover_params/_result`, `t_remote_server_info`, `t_remote_server_config` |
| Tipos de AI Tool | `t_ai_tool`, `t_ai_tool_exec_param` (`args`, `args_json`), `t_ai_tool_exec_result`, `t_ai_tool_render_param/_result` |

`t_plugin_attributes.get_varchar2(p_static_id, p_default_value, p_do_substitutions, p_do_serveronly_substitutions, p_substitutions_escape_mode)`: `p_do_substitutions` e `p_do_serveronly_substitutions` **não podem ser usados juntos**.

Fonte: [APEX_PLUGIN](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_PLUGIN.html), [Constants](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_PLUGIN-Constants.html), [Data Types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_PLUGIN-Data-Types.html), [GET_AJAX_IDENTIFIER Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_AJAX_IDENTIFIER-Function.html), [GET_INPUT_NAME_FOR_ITEM Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_PLUGIN_UTIL.GET_INPUT_NAME_FOR_ITEM-Function.html), [GET_INPUT_NAME_FOR_PAGE_ITEM Function (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_INPUT_NAME_FOR_PAGE_ITEM-Function.html), [GET_KEEP_BACKGROUND_EXECS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_PLUGIN.GET_KEEP_BACKGROUND_EXECS-Function.html)

### APEX_PLUGIN: Flexible Remote Servers (t_remote_server_info / t_remote_server_config)

Um *Remote Server* "flexível" chama uma procedure de configuração (package no banco ou atributo *PL/SQL Code* do Remote Server) para trocar a URL em runtime. Assinatura obrigatória:

```sql
procedure my_server_config (
    p_info   in  apex_plugin.t_remote_server_info,
    p_config out apex_plugin.t_remote_server_config )
is
begin
    if p_info.application_id = 100 then
        p_config.base_url      := 'https://#cust#.example.com';
        p_config.substitutions := apex_t_varchar2();
        apex_string.plist_put(p_config.substitutions, 'cust', v('P3_CUSTOMER'));
    else
        p_config.base_url := 'https://test.example.com';
    end if;
end;
```

Fonte: [About Configuring Flexible Remote Servers in APEX](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/About-Configuring-Flexible-Remote-Servers.html)

## APEX_PLUGIN_UTIL: utilitários para escrever plug-ins

| Grupo | Membros |
|---|---|
| Executar código de atributos | `GET_PLSQL_EXPRESSION_RESULT`, `GET_PLSQL_EXPR_RESULT_BOOLEAN`, `GET_PLSQL_EXPR_RESULT_CLOB`, `GET_PLSQL_FUNCTION_RESULT`, `GET_PLSQL_FUNC_RESULT_BOOLEAN`, `GET_PLSQL_FUNC_RESULT_CLOB`; `EXECUTE_PLSQL_CODE` (**Deprecated**: use `APEX_EXEC.EXECUTE_PLSQL`) |
| Ler dados de SQL/LOV | `GET_DATA` (2, tudo como string), `GET_DATA2` (2, com tipos originais), `GET_DISPLAY_DATA` (2, lookup de display), `GET_SEARCH_STRING`, `GET_VALUE_AS_VARCHAR2`, `PRINT_LOV_AS_JSON` |
| Session state por linha | `SET_COMPONENT_VALUES`, `CLEAR_COMPONENT_VALUES` |
| Gerar HTML de item | `GET_ELEMENT_ATTRIBUTES`, `GET_HTML_ATTR`, `PRINT_HIDDEN`, `PRINT_HIDDEN_IF_READONLY`, `PRINT_READ_ONLY` (2), `PRINT_OPTION`, `PRINT_ESCAPED_VALUE` (2), `PRINT_JSON_HTTP_HEADER`; `PRINT_DISPLAY_ONLY` (2, **Deprecated**: use `PRINT_READ_ONLY`) |
| Escape e substituições | `ESCAPE`, `REPLACE_SUBSTITUTIONS` |
| Diversos | `GET_ATTRIBUTE_AS_NUMBER`, `IS_EQUAL`, `IS_COMPONENT_USED`, `SPLIT_MUTLIPLE_VALUE_TO_TABLE` (grafia da doc), `GET_CURRENT_DATABASE_TYPE`, `GET_ORDERBY_NULLS_SUPPORT`; `GET_POSITION_IN_LIST` e `PAGE_ITEM_NAMES_TO_JQUERY` (**Deprecated**) |
| Debug | `DEBUG_REGION` (2), `DEBUG_DYNAMIC_ACTION`, `DEBUG_PROCESS`; `DEBUG_PAGE_ITEM` (2, **Deprecated**) |
| REST Data Source plug-ins | `GET_WEB_SOURCE_OPERATION`, `MAKE_REST_REQUEST` (2), `BUILD_REQUEST_BODY`, `PROCESS_DML_RESPONSE`, `PARSE_REFETCH_RESPONSE`, `CURRENT_ROW_CHANGED`, `DB_OPERATION_ALLOWED` |

Fonte: [APEX_PLUGIN_UTIL](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_PLUGIN_UTIL.html)

### APEX_PLUGIN_UTIL.GET_HTML_ATTR, ESCAPE, REPLACE_SUBSTITUTIONS e GET_ELEMENT_ATTRIBUTES: HTML seguro em plug-ins

```sql
APEX_PLUGIN_UTIL.GET_HTML_ATTR ( p_name IN VARCHAR2, p_value IN VARCHAR2 ) RETURN VARCHAR2;  -- '' se p_value NULL
APEX_PLUGIN_UTIL.ESCAPE ( p_value IN VARCHAR2, p_escape IN BOOLEAN ) RETURN VARCHAR2;
APEX_PLUGIN_UTIL.REPLACE_SUBSTITUTIONS ( p_value IN VARCHAR2, p_escape IN BOOLEAN DEFAULT TRUE ) RETURN VARCHAR2;
APEX_PLUGIN_UTIL.GET_ELEMENT_ATTRIBUTES (
    p_item                IN apex_plugin.t_item,
    p_name                IN VARCHAR2 DEFAULT NULL,      -- valor de apex_plugin.get_input_name_for_item
    p_default_class       IN VARCHAR2 DEFAULT NULL,
    p_add_id              IN BOOLEAN  DEFAULT TRUE,
    p_add_required        IN BOOLEAN  DEFAULT TRUE,
    p_add_labelledby      IN BOOLEAN  DEFAULT TRUE,
    p_aria_describedby_id IN VARCHAR2 DEFAULT NULL,
    p_add_multi_value     IN BOOLEAN  DEFAULT FALSE ) RETURN VARCHAR2;
```

- `GET_HTML_ATTR` (nome do atributo em minúsculas) é o recomendado pela doc para escapar **qualquer** atributo HTML, no lugar de `APEX_ESCAPE.HTML_ATTRIBUTE`: escolhe o algoritmo adequado e omite o atributo quando o valor é NULL.
- `REPLACE_SUBSTITUTIONS` troca `&ITEM.` pelos valores; `p_escape => TRUE` (padrão) escapa os valores contra XSS.
- `ESCAPE` respeita o atributo padrão *Has Escape Output Attribute* do item plug-in.
- `GET_ELEMENT_ATTRIBUTES` gera id, name, required, placeholder, aria-* e class consistentes para `<input>`, `<select>`, `<textarea>`.

```sql
sys.htp.p('<input type="text" ' ||
          apex_plugin_util.get_element_attributes(p_item, apex_plugin.get_input_name_for_item, 'text_field') ||
          apex_plugin_util.get_html_attr('value', p_param.value) ||
          apex_plugin_util.get_html_attr('title', p_item.plain_label) || '>');
```

Fonte: [GET_HTML_ATTR Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_HTML_ATTR-Function.html), [ESCAPE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ESCAPE-Function.html), [REPLACE_SUBSTITUTIONS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/REPLACE_SUBSTITUTIONS-Function.html), [GET_ELEMENT_ATTRIBUTES Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_ELEMENT_ATTRIBUTES-Function.html)

### APEX_PLUGIN_UTIL.GET_PLSQL_*_RESULT: executar atributos do tipo PL/SQL Expression/Function Body

```sql
APEX_PLUGIN_UTIL.GET_PLSQL_EXPRESSION_RESULT (
    p_plsql_expression IN VARCHAR2,
    p_auto_bind_items  IN BOOLEAN     DEFAULT TRUE,      -- faz bind de itens de página/app
    p_bind_list        IN t_bind_list DEFAULT c_empty_bind_list )
RETURN VARCHAR2;
APEX_PLUGIN_UTIL.GET_PLSQL_FUNCTION_RESULT ( p_plsql_function IN VARCHAR2, p_auto_bind_items, p_bind_list ) RETURN VARCHAR2;
-- variantes _BOOLEAN e _CLOB para expressão (GET_PLSQL_EXPR_RESULT_*) e function body (GET_PLSQL_FUNC_RESULT_*)
APEX_PLUGIN_UTIL.GET_ATTRIBUTE_AS_NUMBER ( p_value IN VARCHAR2, p_attribute_label IN VARCHAR2 ) RETURN NUMBER;
```

Fazem o bind das variáveis automaticamente. `GET_ATTRIBUTE_AS_NUMBER` respeita o separador decimal NLS da sessão: use no lugar de `to_number` para atributos customizados do tipo NUMBER (o label aparece na mensagem de erro).

Fonte: [GET_PLSQL_EXPRESSION_RESULT Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_PLSQL_EXPRESSION_RESULT-Function.html), [GET_PLSQL_FUNCTION_RESULT Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_PLSQL_FUNCTION_RESULT-Function.html), [GET_PLSQL_EXPR_RESULT_BOOLEAN Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_PLSQL_EXPR_RESULT_BOOLEAN-Function.html), [GET_PLSQL_FUNC_RESULT_CLOB Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_PLSQL_FUNC_RESULT_CLOB-Function.html), [GET_ATTRIBUTE_AS_NUMBER Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_ATTRIBUTE_AS_NUMBER-Function.html), [EXECUTE_PLSQL_CODE Procedure (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/EXECUTE_PLSQL_CODE-Procedure.html)

### APEX_PLUGIN_UTIL.GET_DATA2, GET_DISPLAY_DATA, SET_COMPONENT_VALUES e PRINT_LOV_AS_JSON: dados e LOVs em plug-ins

```sql
APEX_PLUGIN_UTIL.GET_DATA2 (
    p_sql_statement    IN VARCHAR2,
    p_min_columns      IN NUMBER,
    p_max_columns      IN NUMBER,
    p_data_type_list   IN apex_application_global.vc_arr2 DEFAULT c_empty_data_type_list,  -- c_data_type_*
    p_component_name   IN VARCHAR2,              -- nome do item/coluna para mensagens de erro
    p_search_type      IN VARCHAR2,              -- c_search_contains_case | _contains_ignore | _exact_case | _exact_ignore
    p_search_column_no IN VARCHAR2,
    p_search_string    IN VARCHAR2,
    p_first_row        IN NUMBER   DEFAULT NULL,
    p_max_rows         IN NUMBER   DEFAULT NULL,
    p_auto_bind_items  IN BOOLEAN  DEFAULT TRUE,
    p_bind_list        IN t_bind_list DEFAULT c_empty_bind_list )
RETURN t_column_list;                            -- t_column_values indexado pelo nº da coluna

APEX_PLUGIN_UTIL.GET_SEARCH_STRING ( p_search_type IN VARCHAR2, p_search_string IN VARCHAR2 ) RETURN VARCHAR2;
APEX_PLUGIN_UTIL.SET_COMPONENT_VALUES   ( p_column_value_list IN t_column_list, p_row_num IN PLS_INTEGER );
APEX_PLUGIN_UTIL.CLEAR_COMPONENT_VALUES;
APEX_PLUGIN_UTIL.PRINT_LOV_AS_JSON ( p_sql_statement IN VARCHAR2, p_component_name IN VARCHAR2,
    p_escape IN BOOLEAN, p_replace_substitutions IN BOOLEAN DEFAULT FALSE );   -- [{"d":"display","r":"return"},...]
```

- `GET_DATA` devolve tudo como string; `GET_DATA2` preserva os tipos (converta com `GET_VALUE_AS_VARCHAR2`). Ambos respeitam os atributos de globalização de comparação de caracteres da app.
- `GET_SEARCH_STRING` devolve a string em maiúsculas para os tipos `_ignore`.
- `SET_COMPONENT_VALUES` expõe as colunas de uma linha como session state (referenciáveis por `&COL.` e `V()`); **sempre** chame `CLEAR_COMPONENT_VALUES` ao terminar a linha.
- `PRINT_LOV_AS_JSON` já inicializa o header HTTP com `application/json`.

Fonte: [GET_DATA2 Function Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_DATA2-Function-Signature-1.html), [GET_DATA Function Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_DATA-Function-Signature-1.html), [GET_DISPLAY_DATA Function Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_DISPLAY_DATA-Function-Signature-1.html), [GET_SEARCH_STRING Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_SEARCH_STRING-Function.html), [SET_COMPONENT_VALUES Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_COMPONENT_VALUES-Procedure.html), [CLEAR_COMPONENT_VALUES Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CLEAR_COMPONENT_VALUES-Procedure.html), [PRINT_LOV_AS_JSON Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PRINT_LOV_AS_JSON-Procedure.html)

### APEX_PLUGIN_UTIL: PRINT_HIDDEN, PRINT_READ_ONLY, PRINT_OPTION, IS_EQUAL, IS_COMPONENT_USED, SPLIT_MUTLIPLE_VALUE_TO_TABLE

```sql
APEX_PLUGIN_UTIL.PRINT_HIDDEN ( p_item IN apex_plugin.t_item, p_param IN apex_plugin.t_item_render_param,
                                p_id_postfix IN VARCHAR2 DEFAULT NULL, p_classes IN VARCHAR2 DEFAULT NULL );
APEX_PLUGIN_UTIL.PRINT_READ_ONLY ( p_item, p_param,
    p_value IN apex_session_state_api.t_value DEFAULT apex_session_state_api.t_value(),
    p_display_value IN VARCHAR2 DEFAULT c_ignore_display_value,
    p_width, p_height, p_css_classes,
    p_protected IN BOOLEAN DEFAULT TRUE, p_escape IN BOOLEAN DEFAULT TRUE, p_show_icon IN BOOLEAN DEFAULT TRUE );
APEX_PLUGIN_UTIL.PRINT_OPTION ( p_display_value, p_return_value, p_is_selected IN BOOLEAN,
                                p_attributes, p_escape IN BOOLEAN DEFAULT TRUE );
APEX_PLUGIN_UTIL.PRINT_ESCAPED_VALUE ( p_value IN VARCHAR2 );   -- escapa e quebra strings grandes em pedaços
APEX_PLUGIN_UTIL.IS_EQUAL ( p_value1 IN VARCHAR2, p_value2 IN VARCHAR2 ) RETURN BOOLEAN;   -- NULL = NULL → TRUE
APEX_PLUGIN_UTIL.IS_COMPONENT_USED ( p_build_option_id DEFAULT NULL, p_authorization_scheme_id,
    p_condition_type, p_condition_expression1, p_condition_expression2, p_component DEFAULT NULL ) RETURN BOOLEAN;
APEX_PLUGIN_UTIL.SPLIT_MUTLIPLE_VALUE_TO_TABLE ( p_value IN CLOB, p_item IN apex_plugin_api.t_item ) RETURN apex_t_varchar2;
```

`IS_EQUAL` é útil para comparar valores de session state, já que em PL/SQL `NULL = NULL` não é TRUE. `IS_COMPONENT_USED` avalia build option + autorização + condição de subcomponentes do plug-in. `SPLIT_MUTLIPLE_VALUE_TO_TABLE` usa a configuração multi-valor do item (o nome com "MUTLIPLE" é assim na doc).

Fonte: [PRINT_HIDDEN Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PRINT_HIDDEN-Procedure.html), [PRINT_READ_ONLY Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PRINT_READ_ONLY-Procedure-Signature-1.html), [PRINT_OPTION Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PRINT_OPTION-Procedure.html), [PRINT_ESCAPED_VALUE Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PRINT_ESCAPED_VALUE-Procedure.html), [IS_EQUAL Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/IS_EQUAL-Function.html), [IS_COMPONENT_USED Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/IS_COMPONENT_USED-Function.html), [SPLIT_MUTLIPLE_VALUE_TO_TABLE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SPLIT_MUTLIPLE_VALUE_TO_TABLE-Function.html), [PRINT_DISPLAY_ONLY Procedure Signature 1 (Deprecated)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PRINT_DISPLAY_ONLY-Procedure-Signature-1.html)

### APEX_PLUGIN_UTIL: utilitários de REST Data Source plug-ins (MAKE_REST_REQUEST e afins)

`MAKE_REST_REQUEST` (2 assinaturas) faz a chamada HTTP respeitando todos os parâmetros do REST Data Source (diferente de chamar `APEX_WEB_SERVICE.MAKE_REST_REQUEST` direto); recebe `p_web_source_operation` (de `GET_WEB_SOURCE_OPERATION`), `p_request_body`, `p_bypass_cache`, `p_time_budget IN OUT`, e devolve `p_response` e `p_response_parameters`. `BUILD_REQUEST_BODY` monta o corpo de DML substituindo `#COLUMN#` do template; `PROCESS_DML_RESPONSE` carrega valores de retorno; `PARSE_REFETCH_RESPONSE` trata o *row refetch* usado na detecção de lost update; `CURRENT_ROW_CHANGED` compara a linha atual entre dois contextos; `DB_OPERATION_ALLOWED` verifica se a operação é permitida; `GET_CURRENT_DATABASE_TYPE` e `GET_ORDERBY_NULLS_SUPPORT` ajudam a gerar SQL compatível com a fonte.

Fonte: [MAKE_REST_REQUEST Procedure Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/MAKE_REST_REQUEST-Procedure-Signature-1.html), [GET_WEB_SOURCE_OPERATION Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_WEB_SOURCE_OPERATION-Function.html), [BUILD_REQUEST_BODY Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/BUILD_REQUEST_BODY-Procedure.html), [PROCESS_DML_RESPONSE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PROCESS_DML_RESPONSE-Procedure.html), [PARSE_REFETCH_RESPONSE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PARSE_REFETCH_RESPONSE-Function.html), [GET_CURRENT_DATABASE_TYPE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_CURRENT_DATABASE_TYPE-Function.html)

## APEX_ITEM (Legacy): campos HTML gerados por SQL (arrays G_F01..G_F50)

**Legacy.** Gera elementos de formulário dentro de uma query (Classic Report), cujos valores voltam no submit nos arrays `APEX_APPLICATION.G_F01..G_F50` (o `p_idx` 1..50 escolhe o array). A Oracle recomenda **Interactive Grid** para edição tabular; use `APEX_ITEM` só para manter código antigo.

| Função | Gera |
|---|---|
| `TEXT` | `<input type="text">` |
| `TEXTAREA` | `<textarea>` |
| `HIDDEN` | `<input type="hidden">` |
| `CHECKBOX2` | Checkbox (valores marcados via `p_checked_values`) |
| `DATE_POPUP`, `DATE_POPUP2` | Campo de data com calendário |
| `SELECT_LIST`, `SELECT_LIST_FROM_LOV`, `SELECT_LIST_FROM_QUERY` (+ `_XL` com CLOB > 32K) | Select list |
| `POPUP_FROM_LOV`, `POPUP_FROM_QUERY`, `POPUPKEY_FROM_LOV`, `POPUPKEY_FROM_QUERY` | Popup LOV |
| `RADIOGROUP` | Radio group a partir de query |
| `SWITCH` | Toggle (Yes/No por padrão) |
| `DISPLAY_AND_SAVE` | Mostra como texto e salva o valor |
| `TEXT_FROM_LOV`, `TEXT_FROM_LOV_QUERY` | Texto com display de uma LOV |
| `MD5_CHECKSUM`, `MD5_HIDDEN` | Checksum para detecção de lost update |

```sql
APEX_ITEM.TEXT ( p_idx IN NUMBER, p_value IN VARCHAR2 DEFAULT NULL, p_size IN NUMBER DEFAULT NULL,
                 p_maxlength IN NUMBER DEFAULT NULL, p_attributes IN VARCHAR2 DEFAULT NULL,
                 p_item_id IN VARCHAR2 DEFAULT NULL, p_item_label IN VARCHAR2 DEFAULT NULL ) RETURN VARCHAR2;
APEX_ITEM.CHECKBOX2 ( p_idx, p_value, p_attributes, p_checked_values,
                      p_checked_values_delimiter DEFAULT ':', p_item_id, p_item_label ) RETURN VARCHAR2;
APEX_ITEM.SELECT_LIST ( p_idx, p_value, p_list_values, p_attributes, p_show_null DEFAULT 'NO',
                        p_null_value DEFAULT '%NULL%', p_null_text DEFAULT '%', p_item_id, p_item_label,
                        p_show_extra DEFAULT 'YES' ) RETURN VARCHAR2;
APEX_ITEM.MD5_CHECKSUM ( p_value01 .. p_value50, p_col_sep DEFAULT '|', p_item_id ) RETURN VARCHAR2;
```

Pegadinhas: o parâmetro `p_row` de algumas funções está deprecated (ignorado); `p_item_label` serve para acessibilidade; a coluna do relatório precisa ter o escape desligado para renderizar o HTML; checkboxes só enviam as linhas marcadas (ver `G_Fnn`).

Fonte: [APEX_ITEM (Legacy)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_ITEM.html), [TEXT Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/TEXT-Function.html), [CHECKBOX2 Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CHECKBOX2-Function.html), [SELECT_LIST Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SELECT_LIST-Function.html), [MD5_CHECKSUM Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/MD5_CHECKSUM-Function.html), [Working with G_Fnn Arrays (Legacy)](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/working-with-g_fnn-arrays.html)

## APEX_DB_DICTIONARY: metadados do banco formatados para humanos e LLMs

Descrições de tabelas/views "amigáveis a LLM" (Markdown ou texto), úteis para alimentar prompts de IA ou documentação.

| Membro | O que faz |
|---|---|
| `GET_TABLE_INFO` (lista CSV ou array) / `GET_TABLE_INFO_REGEX` | Metadados formatados de uma ou mais tabelas/views |
| `GET_TABLES_SUMMARY` | Lista resumida de tabelas/views (Markdown ou texto) |
| `GET_TABLES_ARRAY` / `GET_TABLES_JSON` | Nomes `OWNER.OBJETO` que casam com uma regex |
| `GET_PRIMARY_KEY_COLUMNS` | Colunas da PK separadas por vírgula (NULL se não houver PK) |
| `GET_METADATA` | Wrapper de `DBMS_DEVELOPER.GET_METADATA` (JSON no 21c+, CLOB antes) |
| `FORMAT_METADATA` (2) | Converte o JSON de `GET_METADATA` em texto legível |
| `IS_SUPPORTED` | Se `DBMS_DEVELOPER` é suportado na instância |

```sql
APEX_DB_DICTIONARY.GET_TABLE_INFO (
    p_table_names             IN VARCHAR2,                 -- 'COLABORADOR, CARGO' (ou 'OWNER.TAB')
    p_include_constraints     IN BOOLEAN DEFAULT TRUE,
    p_include_indexes         IN BOOLEAN DEFAULT FALSE,
    p_include_comments        IN BOOLEAN DEFAULT TRUE,
    p_include_annotations     IN BOOLEAN DEFAULT TRUE,
    p_include_domains         IN BOOLEAN DEFAULT TRUE,
    p_include_virtual_columns IN BOOLEAN DEFAULT FALSE,
    p_format                  IN t_format_type DEFAULT c_markdown )   -- ou c_plain
RETURN CLOB;
APEX_DB_DICTIONARY.GET_TABLES_SUMMARY ( p_regex DEFAULT NULL, p_owner DEFAULT NULL, p_object_type DEFAULT NULL,
    p_include_comments DEFAULT TRUE, p_include_annotations DEFAULT TRUE, p_format DEFAULT c_markdown ) RETURN CLOB;
APEX_DB_DICTIONARY.GET_TABLES_ARRAY ( p_regex, p_owner, p_object_type ) RETURN WWV_FLOW_T_VARCHAR2;  -- regex vazia → array vazio
APEX_DB_DICTIONARY.GET_PRIMARY_KEY_COLUMNS ( p_table IN VARCHAR2, p_owner DEFAULT NULL, p_delimiter DEFAULT ',' ) RETURN VARCHAR2;
APEX_DB_DICTIONARY.GET_METADATA ( p_name, p_schema DEFAULT NULL, p_object_type DEFAULT NULL,   -- TABLE, INDEX, VIEW
                                  p_level DEFAULT 'typical', p_etag DEFAULT NULL ) RETURN JSON;      -- BASIC | TYPICAL | ALL
```

`p_name`/`p_schema` de `GET_METADATA` são sensíveis a maiúsculas (como no dicionário). Comentários e *annotations* das tabelas melhoram muito a saída.

Fonte: [APEX_DB_DICTIONARY](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DB_DICTIONARY.html), [GET_TABLE_INFO Function Signature 1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DB_DICTIONARY.GET_TABLE_INFO-Function-Signature-1.html), [GET_TABLES_SUMMARY Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DB_DICTIONARY.GET_TABLES_SUMMARY-Function.html), [GET_TABLES_ARRAY Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DB_DICTIONARY.GET_TABLES_ARRAY-Function.html), [GET_PRIMARY_KEY_COLUMNS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DB_DICTIONARY.GET_PRIMARY_KEY_COLUMNS-Function.html), [GET_METADATA Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DB_DICTIONARY.GET_METADATA-Function.html)

## APEX_UI_DEFAULT_UPDATE: User Interface Defaults por SQL Developer/SQLcl

Ajusta os *User Interface Defaults* (rótulos, máscaras, help, larguras, alinhamentos) que os **assistentes** usam ao gerar forms e relatórios. Precisa ser chamado **no schema dono da tabela**.

| Grupo | Membros |
|---|---|
| Table-based UI Defaults | `SYNCH_TABLE` (cria ou sincroniza com as colunas atuais), `UPD_TABLE`, `DEL_TABLE`, `UPD_COLUMN`, `DEL_COLUMN`, `UPD_GROUP`, `DEL_GROUP` |
| Atalhos por atributo | `UPD_LABEL`, `UPD_ITEM_HELP`, `UPD_DISPLAY_IN_FORM`, `UPD_DISPLAY_IN_REPORT`, `UPD_FORM_REGION_TITLE`, `UPD_REPORT_REGION_TITLE`, `UPD_ITEM_DISPLAY_WIDTH`, `UPD_ITEM_DISPLAY_HEIGHT`, `UPD_ITEM_FORMAT_MASK`, `UPD_REPORT_FORMAT_MASK`, `UPD_REPORT_ALIGNMENT` |
| Attribute Dictionary | `ADD_AD_COLUMN` (até 3 sinônimos), `UPD_AD_COLUMN`, `DEL_AD_COLUMN`, `ADD_AD_SYNONYM`, `UPD_AD_SYNONYM`, `DEL_AD_SYNONYM` |

Nas rotinas `UPD_*`, passar `'null%'` define o atributo como NULL (passar NULL mantém o valor).

```sql
begin
    apex_ui_default_update.synch_table('COLABORADOR');
    apex_ui_default_update.upd_label('COLABORADOR', 'NOME_COMPLETO', 'Nome completo');
    apex_ui_default_update.upd_item_help('COLABORADOR', 'LOGIN_APEX', 'Login usado para entrar no Corlix Hub.');
end;
```

Fonte: [APEX_UI_DEFAULT_UPDATE](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_UI_DEFAULT_UPDATE.html), [SYNCH_TABLE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SYNCH_TABLE-Procedure.html), [UPD_COLUMN Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/UPD_COLUMN-Procedure.html), [UPD_LABEL Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/UPD_LABEL-Procedure.html), [ADD_AD_COLUMN Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_AD_COLUMN-Procedure.html)

## Views do dicionário do APEX citadas pelas APIs (APEX_APPLICATION_*, APEX_WORKSPACE_*, APEX_DICTIONARY)

A *API Reference* não traz um catálogo das views; o App Builder tem *Utilities > Oracle APEX Views* e a lista completa sai da view **`APEX_DICTIONARY`**. As views abaixo são as citadas nas páginas dos packages deste documento:

| View | Uso nas APIs |
|---|---|
| `APEX_DICTIONARY` | Lista de todas as views do APEX e suas colunas |
| `APEX_APPLICATIONS` | Apps (ex.: `theme_number`, `last_updated_on` em exemplos de `GET_SINCE`/`APEX_THEME`) |
| `APEX_APPLICATION_PAGE_REGIONS` | `region_id`, `static_id` (para `APEX_REGION`, `APEX_ERROR.ADD_ERROR` de tabular form) |
| `APEX_APPLICATION_FILES` | Arquivos do workspace (`APEX_UTIL.GET_FILE`, `GET_FILE_ID`) |
| `APEX_APPLICATION_TEMP_FILES` | Arquivos enviados por File Browse temporário (exemplo de `APEX_IR.IMPORT_SAVED_REPORTS`) |
| `APEX_APPLICATION_THEMES`, `APEX_APPLICATION_THEME_STYLES`, `APEX_THEMES` | Temas e estilos (`APEX_THEME`, `SET_CURRENT_THEME_STYLE`) |
| `APEX_COLLECTIONS` | Membros das coleções da sessão |
| `APEX_DEBUG_MESSAGES` | Log de debug (`APEX_DEBUG`) |
| `APEX_APPL_ACL_ROLES`, `APEX_APPL_ACL_USERS`, `APEX_APPL_ACL_USER_ROLES` | Papéis e atribuições do Access Control (`APEX_ACL`); `APEX_APPL_ACL_USERS` aceita DML via `INSTEAD OF` |
| `APEX_USERS`, `APEX_WORKSPACE_APEX_USERS` | Contas do repositório APEX (`APEX_UTIL`) |
| `APEX_USER_ACCESS_LOG` | Log de login (`SET_AUTHENTICATION_RESULT`, `SET_CUSTOM_AUTH_STATUS`) |
| `APEX_WORKSPACE_CLICKS` | Cliques contados por `COUNT_CLICK` |
| `APEX_WORKSPACE_SESSION_GROUPS`, `APEX_WORKSPACE_GROUP_GROUPS` | Grupos dinâmicos da sessão (`ENABLE_DYNAMIC_GROUPS`) |
| `APEX_TEAM_FEEDBACK_FOLLOWUP` | Follow-ups de feedback |
| `APEX_USED_DB_OBJECT_COMP_PROPS`, `APEX_USED_DB_OBJECTS`, `APEX_USED_DB_OBJ_DEPENDENCIES` | Resultado do `APEX_APP_OBJECT_DEPENDENCY.SCAN` |

Para descobrir colunas e views, consulte `APEX_DICTIONARY` (ou a tela *Oracle APEX Views*, que mostra a query gerada).

Fonte: [Accessing APEX Views](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/accessing-apex-views.html), [APEX_ACL](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_ACL.html), [Accessing a Collection](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/Accessing-a-Collection.html), [APEX_DEBUG](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DEBUG.html), [APEX_APP_OBJECT_DEPENDENCY](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APP_OBJECT_DEPENDENCY.html)

## JavaScript APIs e mudanças da release 26.1 na API Reference

- O capítulo "JavaScript APIs" da *API Reference* apenas informa que o conteúdo foi movido para a **Oracle APEX JavaScript API Reference** (livro `aexjs`). As contrapartes JS das APIs daqui são, por exemplo, `apex.server.process` (que envia `x01..x10` lidos por `APEX_APPLICATION.G_X01..G_X10`) e `apex.lang` (lê Text Messages marcadas *Used in JavaScript*).
- "Changes in Release 26.1": a doc remete ao app **APEX Diff** (apex.oracle.com/apexdiff) para comparar as especificações dos packages entre versões.

Fonte: [JavaScript APIs](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/JavaScript-APIs.html), [Changes in Release 26.1](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/changes-in-this-release.html)
## Aplicação no Corlix Hub

Como as APIs deste documento se aplicam ao app 100 (`CORLIXHUB`, workspace `WKSP_CORLIXHUB`, APEX 26.1.5). Regras do projeto: toda query filtra por `id_empresa`; páginas administrativas têm `authorizationScheme`; links via `apex_page.get_url`; UI em pt-BR. Referências: `docs/ai-context/03`, `05`, `08`, `09` e os `.apx` em `corlixhub/`.

Fonte: [APEX_PAGE](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_PAGE.html), [APEX_ERROR](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_ERROR.html), [APEX_UTIL](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_UTIL.html)

### Corlix Hub: links entre páginas com APEX_PAGE.GET_URL (Session State Protection ligado)

A app usa *Session State Protection* com `pageAccessProtection: argumentsMustHaveChecksum` em todas as páginas normais (`docs/ai-context/03`). Por isso:
- todo link com parâmetros deve sair de `apex_page.get_url` (ou do link builder declarativo), que já gera o checksum; URLs `f?p=` concatenadas quebram (`08` regra 6);
- para modais (18, 21, 22, 23, 27), `GET_URL` devolve o `javascript:` de abertura do diálogo; para redirect em processo use `p_plain_url => TRUE`;
- links em e-mail/notificação: `p_absolute_url => TRUE` (ou `APEX_UTIL.PREPARE_URL` com `p_checksum_type => 'PUBLIC_BOOKMARK'`).

Pegadinha já registrada no projeto (`09`, `ERR-1002 ... P22_ID_COLABORADOR`): `GET_URL` com `p_items` de um item que não existe na página de destino falha. Confira o nome do item na página alvo.

Fonte: [GET_URL Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_URL-Function.html), [PREPARE_URL Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PREPARE_URL-Function.html)

### Corlix Hub: G_ID_EMPRESA, session state e filtro multiempresa

- `G_ID_EMPRESA` é preenchido pelo *application process* `SET_G_ID_EMPRESA` (ponto `afterAuthentication`, `corlixhub/shared-components/app-processes.apx`), ligando `COLABORADOR.LOGIN_APEX` a `:APP_USER`. Não existe *Post-Authentication procedure* no esquema (`03`).
- Em SQL de regiões, LOVs e authorizations use a bind `:G_ID_EMPRESA`. Em packages, `pkg_historico_carreira.fn_empresa_contexto` lê com `apex_util.get_session_state('G_ID_EMPRESA')` (`05`). Alternativa tipada: `apex_session_state.get_number('G_ID_EMPRESA')`.
- Se um dia a app usar `APEX_SESSION.SET_TENANT_ID` + `APP_TENANT_ID`, lembre que o tenant só pode ser definido **uma vez** por sessão. Hoje o projeto não usa (o isolamento é por `id_empresa` nas queries, sem VPD, `05`).

Fonte: [GET_SESSION_STATE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_SESSION_STATE-Function.html), [GET_NUMBER Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_SESSION_STATE.GET_NUMBER-Function.html), [SET_TENANT_ID Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_TENANT_ID.html)

### Corlix Hub: a Error Handling Function log_pkg.apex_error_handler comparada à recomendação da Oracle

A app registra `log_pkg.apex_error_handler` em `application.apx` (`errorHandling.errorHandlingFunctionName`). O código atual (em `database/ddl/09-plsql-corpos.sql`; o `docs/ai-context` cita `database/corlix-hub.sql`, arquivo que não existe mais no repositório) faz:
1. `apex_error.init_error_result(p_error)` (como a doc exige);
2. grava em `APP_LOG` (autonomous transaction) o tipo do componente (`p_error.component.type`), `ora_sqlerrm`, `error_backtrace` e `error_statement`;
3. para `ora_sqlcode` entre -20099 e -20001 delega a `pkg_historico_carreira.fn_tratar_erro`, que usa `apex_error.get_first_ora_error_text` e `c_inline_in_notification`.

Diferenças em relação ao exemplo oficial (oportunidades, não bugs confirmados):
- não mascara erros internos (`is_internal_error and not is_common_runtime_error`), que podem expor SQL ao usuário; a doc recomenda trocar a mensagem por uma genérica com número de referência;
- não traduz violações de constraint (`ORA-00001/02291/02292...`) nem usa `auto_set_associated_item`; dá para criar Text Messages `APEX.ERROR.ORA-<n>` sem código;
- erros `-20000` (ex.: o processo "Criar usuário APEX" da P14 usa `raise_application_error(-20000, SQLERRM || backtrace)`) ficam fora da faixa -20001..-20099 e aparecem com pilha.

Fonte: [Example of an Error Handling Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/Example-of-an-Error-Handling-Function.html), [Constants and Attributes Used for Result Types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/Constants-and-Attributes-used-for-Result-Types.html)

### Corlix Hub: APEX_UTIL.CREATE_USER na P14 e APEX_ACL nos perfis de acesso

- A autenticação é *Oracle APEX Accounts* e a app tem `runtimeApiUsage: modifyWorkspaceRepository` (`03`): requisitos que a doc impõe para `APEX_UTIL.CREATE_USER` dentro de uma app (usuário corrente admin do workspace e app autorizada a modificar o repositório).
- Melhorias alinhadas à doc: validar antes com `apex_util.is_username_unique` e mostrar o erro no campo com `apex_error.add_error(... c_inline_with_field_and_notif, p_page_item_name => 'P14_LOGIN')`; considerar `apex_util.strong_password_validation` para a senha.
- Papéis (`ADMIN_RH`, `GESTOR`, `COLABORADOR`…) usam `apex_acl.has_user_role` / `add_user_role` por **static ID** em `pkg_perfis_acesso.atribuir_papeis` (bom: IDs numéricos mudam entre ambientes). Depois de alterar papéis da sessão corrente, chame `apex_authorization.reset_cache`.
- `APEX_ACL` e `APEX_SESSION.CREATE_SESSION` não funcionam no SQL Commands (`08`, `modulos/perfis-acesso/Registro-implantacao.md`, itens 5–6). A doc confirma: `CREATE_SESSION` não é suportado em SQL Commands/SQL Scripts, e fora do APEX é preciso definir o workspace.

Fonte: [CREATE_USER Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CREATE_USER-Procedure.html), [IS_USERNAME_UNIQUE Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/IS_USERNAME_UNIQUE-Function.html), [ADD_USER_ROLE Procedure Signature 2](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ADD_USER_ROLE-Procedure-Signature2.html), [RESET_CACHE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/RESET_CACHE-Procedure.html), [CREATE_SESSION Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/CREATE_SESSION-Procedure.html)

### Corlix Hub: authorizations em packages e views (APEX_AUTHORIZATION.IS_AUTHORIZED)

O projeto chama `apex_authorization.is_authorized('ADMIN_RH')` em `authorizations.apx`, `pkg_historico_carreira` e na função `FN_CARREIRA_VE_SALARIO` (view `03_views_carreira.sql`, que devolve `'S'/'N'`). Pontos da doc a lembrar:
- o resultado é cacheado conforme o *Evaluation Point* do scheme (padrão *Once per session*): se a checagem depende de dados que mudam na sessão, troque o Evaluation Point ou use `reset_cache`;
- `IS_AUTHORIZED` recebe o **nome** do scheme; `HAS_ACCESS` recebe o **Static ID**, que é mais estável se alguém renomear o scheme;
- página administrativa continua precisando do `authorizationScheme` na própria página (regra do projeto); a checagem em PL/SQL é defesa adicional, não substituta.

Fonte: [IS_AUTHORIZED Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/IS_AUTHORIZED-Function.html), [HAS_ACCESS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AUTHORIZATION.HAS_ACCESS-Function.html), [Editing an Authorization Scheme](https://docs.oracle.com/en/database/oracle/apex/26.1/htmdb/editing-authorization-scheme.html)

### Corlix Hub: processos Ajax (organograma P3) com G_X01, APEX_UTIL.PRN e APEX_JSON

O processo `ORG_DETALHES` da página 3 (ponto `ajaxCallback`) lê `apex_application.g_x01` com `to_number(... default null on conversion error)` e devolve HTML via `apex_util.prn(p_clob => pkg_organograma.render_detalhes(...), p_escape => false)`. Com `p_escape => false`, **todo** dado de usuário dentro do HTML gerado por `render_detalhes` precisa já sair escapado (`apex_escape.html` / `apex_plugin_util.get_html_attr`) e a consulta precisa filtrar por `:G_ID_EMPRESA` (o `x01` vem do navegador e pode ser trocado). Para respostas estruturadas, prefira `APEX_JSON` (header `application/json` automático) e, para configuração de JS, `APEX_T_JAVASCRIPT_OBJECT` + `APEX_JAVASCRIPT.ADD_ONLOAD_CODE`.

Fonte: [Global Variables](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_APPLICATION-Global-Variables.html), [PRN Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PRN-Procedure.html), [APEX_JSON Overview and Examples](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/Package-Overview-and-Examples.html)

### Corlix Hub: debug e Monitor de Logs (APEX_DEBUG_MESSAGES)

A página 7 (Monitor de Logs) lê `APEX_DEBUG_MESSAGES` além de `APP_LOG` (`05`), com os níveis 1 = erro, 2 = aviso, 4 = info, iguais às constantes `c_log_level_*` de `APEX_DEBUG`. Para instrumentar packages do projeto: `apex_debug.enter` no início das rotinas públicas, `apex_debug.info` nos passos e `apex_debug.error` nos handlers (grava mesmo sem debug ligado). Para ligar debug na sessão de um usuário que relata problema: `apex_session.set_debug(p_session_id => ..., p_level => apex_debug.c_log_level_info); commit;`. Para limpeza periódica: `apex_debug.remove_debug_by_age(p_application_id => 100, p_older_than_days => 7)`.

Fonte: [APEX_DEBUG](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DEBUG.html), [Constants](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DEBUG-Constants.html), [SET_DEBUG Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_DEBUG-Procedure.html), [REMOVE_DEBUG_BY_AGE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/REMOVE_DEBUG_BY_AGE-Procedure.html)

### Corlix Hub: onde cada API se encaixa nas telas planejadas

| Necessidade | API recomendada |
|---|---|
| Comunicados com texto rico (P11/P17) | `APEX_MARKDOWN.TO_HTML` (modo `ESCAPE`) ou `APEX_ESCAPE.HTML_ALLOWLIST`; hashtags com `APEX_STRING_UTIL.FIND_TAGS` |
| Membros de equipe em wizard (P27) | `APEX_COLLECTION` (`CREATE_OR_TRUNCATE_COLLECTION`, `ADD_MEMBER`, `UPDATE_MEMBER_ATTRIBUTE`), gravação final em uma transação |
| Listas multi-valor (Checkbox Group, Select Many) | `APEX_STRING.SPLIT_NUMBERS(:ITEM, ':')` em `table(...)` |
| Iniciais no avatar (organograma, chat) | `APEX_STRING.GET_INITIALS` |
| Exportar lista de colaboradores (P12) | `APEX_REGION.EXPORT_DATA` / `OPEN_QUERY_CONTEXT` (respeita filtros do usuário) |
| Filtro rápido de IR/IG por botão | `APEX_IR.ADD_FILTER` / `APEX_IG.ADD_FILTER` em processo de **submit** |
| Detecção de edição concorrente no histórico (P13/P18) | `APEX_UTIL.GET_HASH` em item oculto |
| CEP via ViaCEP (P16) | `APEX_JSON.PARSE` + `GET_VARCHAR2` (ou `APEX_WEB_SERVICE` + `APEX_JSON`) |
| Mensagens em pt-BR reutilizáveis | Text Messages + `APEX_LANG.GET_MESSAGE` / `APEX_ERROR.ADD_ERROR(p_error_code => ...)` |
| Tema por empresa (futuro) | `APEX_THEME.SET_SESSION_STYLE` após o login |

Lembretes: a UI é pt-BR, então separadores CSV automáticos (`APEX_ESCAPE.SET_CSV_PARAMETERS`) viram `;`; `GET_NUMBER`/`GET_TIMESTAMP` de `APEX_SESSION_STATE` respeitam a máscara do item, evitando erros de `to_number` com vírgula decimal. Passo a passo de Builder citado aqui deve ser conferido no 26.1.5 (regra 8 do `docs/ai-context/README.md`).

Fonte: [TO_HTML Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/TO_HTML-Function.html), [APEX_COLLECTION](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_COLLECTION.html), [SPLIT_NUMBERS Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SPLIT_NUMBERS-Function.html), [EXPORT_DATA Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_REGION-EXPORT_DATA-Function.html), [GET_HASH Function](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_HASH-Function.html), [SET_CSV_PARAMETERS Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_CSV_PARAMETERS-Procedure.html), [SET_SESSION_STYLE Procedure](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/SET_SESSION_STYLE-Procedure.html)
