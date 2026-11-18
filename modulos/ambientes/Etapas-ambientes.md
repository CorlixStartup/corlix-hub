# Ambientes DEV, UAT e PRD · passo a passo

> **Para quem executa:** o time, no Oracle Cloud, no APEX, no Jenkins e no GitHub. O agente escreveu este guia, o `instalar-app.sql` e o workflow `instalar-app.yml`, mas não cria nem altera nada nesses lugares. Motivo e comparação de alternativas: [`docs/ai-context/12-ambientes-dev-uat-prd.md`](../../docs/ai-context/12-ambientes-dev-uat-prd.md). Tarefa: [CD-77](https://corlix.youtrack.cloud/issue/CD-77).

## Decisões (17/11/2026)

| Tema | Decisão |
|---|---|
| Distribuição | **Banco 1 (atual) = PRD.** **Banco 2 (novo) = DEV + UAT**, em workspaces separados |
| Dados de DEV e UAT | **Cópia dos dados do PRD**, que são todos de teste (confirmado pelo time em 17/11/2026). Ver o aviso no 3.2 |
| Fotos | Mesmo bucket `corlix-fotos`, com prefixo **`dev/`** e **`uat/`** |
| Instalação nos ambientes | **GitHub Actions**, com aprovação obrigatória no PRD. Antes da automação, a primeira vez é manual |
| Data da troca (passo 4) | **18/11/2026** |
| Ordem | **Congelar primeiro** (§0, decidido em 18/11/2026): o Builder do banco 1 para antes de montar o DEV, e o DEV nasce do backup do congelamento. Assim não há mudança feita no banco 1 depois da cópia, e os passos 2 e 3 do §4 não são necessários |

## Como fica

| | DEV | UAT | PRD |
|---|---|---|---|
| Banco | 2 (`corlixhubdev`) | 2 (`corlixhubdev`) | 1 (o atual) |
| Workspace | `CORLIXHUB` | `CORLIXHUB_UAT` | `CORLIXHUB` |
| Schema | `WKSP_CORLIXHUB` | `WKSP_CORLIXHUB_UAT` | `WKSP_CORLIXHUB` |
| App | 100 | 200 | 100 |
| Builder | Edição liberada (`RUN_AND_BUILD`) | Só leitura (`RUN_ONLY`) | Só leitura (`RUN_ONLY`) |
| Branch | `DEV` | `UAT` | `PROD` |
| Prefixo das fotos | `dev/` | `uat/` | (nenhum) |

> **Nomes:** `CORLIXHUB` é o nome do Autonomous AI Database atual (banco 1; serviço `corlixhub_low`). O **workspace** do APEX é `CORLIXHUB` e o **schema** é `WKSP_CORLIXHUB` (conferido em 18/11/2026 em `apex_workspace_schemas` no banco 1, workspace ID `10008945716225088`; a informação de 17/11 de que o workspace era `WKSP_CORLIXHUB` estava trocada). O banco 2 se chama `corlixhubdev` (serviço `corlixhubdev_low`).

> **ID 200 no UAT:** o ID da app é único na instância do APEX, e DEV e UAT estão no mesmo banco. Por isso não use `f?p=100:` nem `100` escrito fixo no código: use `apex_page.get_url` e `:APP_ID`.

---

## 0. Congelamento

Do congelamento até o DEV ficar pronto (§3.7), **ninguém edita a app**: nem no Builder nem no SQL Workshop (packages, tabelas, dados de configuração). A app no ar continua funcionando para quem usa.

### 0.1 Antes de congelar

1. Pergunte no canal do time se alguém tem uma mudança em andamento no Builder ou no SQL Workshop. Quem tiver termina e salva, ou desiste da mudança.
2. Confira que não há objeto inválido no banco 1. No SQL Commands, sem `;`:

   ```sql
   select object_type, object_name from user_objects where status = 'INVALID' order by 1, 2
   ```

   Tem de voltar vazio. Em 17/11/2026 o `PKG_CHAT_UI` (body) estava inválido (resolvido pelo time em 18/11/2026) e quebrava o `CX_PRESENCA_PING` em todas as páginas (`SyntaxError: Unexpected token 's', "sqlerrm:OR"...`). O corpo exportado no backup de 18/11 compila sem erro num Oracle local, então o mais provável é que só precise ser recompilado:

   ```sql
   alter package pkg_chat_ui compile body
   ```

   Se continuar inválido, rode a consulta abaixo e resolva antes de congelar. Senão, o DEV herda o erro.

   ```sql
   select line, position, text from user_errors where name = 'PKG_CHAT_UI' and type = 'PACKAGE BODY' order by sequence
   ```

### 0.2 Congelar

1. Avise no canal do time: "Builder do Corlix Hub congelado a partir de agora até o DEV novo ficar pronto. Ninguém edita no Builder nem no SQL Workshop."
2. Confira como está hoje. No banco 1, em *SQL Workshop › SQL Commands*, cole o bloco inteiro e clique em **Run**:

   ```sql
   begin
     dbms_output.put_line('Build Status da app 100: ' || apex_application_admin.get_build_status(p_application_id => 100));
   end;
   ```

   Deve mostrar `RUN_AND_BUILD`.
3. Bloqueie o Builder do banco 1. No mesmo SQL Commands:

   ```sql
   begin
     apex_application_admin.set_build_status(p_application_id => 100, p_build_status => 'RUN_ONLY');
     commit;
     dbms_output.put_line('Build Status da app 100: ' || apex_application_admin.get_build_status(p_application_id => 100));
   end;
   ```

   Deve mostrar `RUN_ONLY`. Pelo Builder, o caminho é *Shared Components › Application Definition › Availability › Build Status* = **Run Application Only** (confirmar no 26.1.5).
4. Confira: no App Builder, a app 100 não abre mais para edição; em outra aba, a app no ar (Início) continua funcionando.
5. Rode o backup do Jenkins (`AMBIENTE = PRD`) e espere o commit na branch `DEV`. O backup só lê a app e o banco, então funciona com o Builder bloqueado (confirmar no primeiro backup). **Esse backup é a base do DEV:** guarde o `.tar.gz` (§1, item 3) e use a `DEV` desse commit no §3.

### 0.3 Correção urgente durante o congelamento

Se a app no ar quebrar antes de o DEV ficar pronto: volte o Build Status para `RUN_AND_BUILD` (mesmo bloco do §0.2, item 3, trocando o valor; ou, sem SQL, *Administration › Manage Service › Application Build Status*, como administrador do workspace), corrija, bloqueie de novo e rode outro backup. Se o §3 já tiver começado, repita no DEV o §3.4 com o `f100.sql` novo e qualquer DDL alterado.

---

## 1. Antes de começar

1. No Oracle Cloud: *Governance & Administration › Limits, Quotas and Usage*. Filtre por **Autonomous Database** e procure o limite de Always Free (confirmar o nome do limite no console). Tem de sobrar **1**. Se não sobrar, pare: há outro banco gratuito na conta, e o time precisa decidir o que fazer com ele.
2. No APEX do banco 1: *Help › About* e anote a versão (hoje `26.1.6`). O banco 2 tem de estar na mesma versão ou numa mais nova; senão o `f100.sql` não importa.
3. Rode o backup do Jenkins (*Build with Parameters*, `AMBIENTE = PRD`) e guarde o `.tar.gz` do dia.

## 2. Criar o banco 2

*Oracle Database › Autonomous Database › Create Autonomous Database* (confirmar os nomes no console):

| Campo | Valor |
|---|---|
| Compartment | crie antes `corlix-dev-uat` (*Identity › Compartments*) e escolha ele |
| Display name / Database name | `corlixhubdev` |
| Workload type | **APEX** ou **Transaction Processing** (os dois servem para o APEX; prefira o mesmo tipo do banco 1) |
| **Always Free** | **Ligado.** Confira antes de criar: sem isso o banco é cobrado |
| Database version | a oferecida pelo console (em 18/11/2026, só **26ai**, sucessor do 23ai). Se o banco 1 ainda estiver em 23ai, não use no DEV recurso que só exista no 26ai: a app vai para o PRD |
| ADMIN password | gerada com o comando abaixo e guardada no cofre de senhas do time |
| Network access | **Secure access from everywhere**, com mTLS obrigatório (o GitHub Actions entra pela internet, com o wallet) |

Senha do ADMIN (e, depois, a do wallet): 24 letras e números, com maiúscula, minúscula e número, copiada para a área de transferência sem aparecer na tela. Sem símbolos, que costumam dar problema no SQLcl e nos secrets do GitHub.

```bash
while :; do s=$(openssl rand -base64 48 | tr -dc 'A-Za-z0-9' | head -c 24); [[ $s =~ [A-Z] && $s =~ [a-z] && $s =~ [0-9] ]] && break; done; printf %s "$s" | pbcopy; unset s; echo "Senha copiada"
```

O compartimento `corlix-dev-uat` pede descrição: `Ambientes DEV e UAT do Corlix Hub (banco 2, Always Free)`. No §1, o limite certo é **Always Free Autonomous Database Instance Count** (`adb-free-count`), no serviço **Database**; não confunda com *Developer Autonomous Database*, que é pago.

Depois de criado: *Database connection › Download wallet*. O alias do serviço (`corlixhubdev_low`) está no `tnsnames.ora` dentro do zip.

Mova o banco 1 para um compartimento `corlix-prd` se quiser separar no console (*More actions › Move resource*).

## 3. Montar o DEV no banco 2

### 3.1 Workspace

No banco 2: *Tool configuration › Oracle APEX* (entre como `ADMIN`) *› Create Workspace*. No Autonomous Database, a tela é simplificada e **não tem campo para o schema**: o APEX cria o schema `WKSP_<nome do workspace>`.

| Campo | Valor |
|---|---|
| Workspace Name | `CORLIXHUB` (o mesmo do banco 1; o schema sai `WKSP_CORLIXHUB`) |
| Workspace Username / Password | o administrador do workspace (uma pessoa do time) |
| Advanced › Database Password | senha do schema, gerada com o `openssl` do §2 e guardada no cofre como "corlixhubdev · WKSP_CORLIXHUB" |
| Advanced › Workspace ID | em branco |

Confira em *Database actions › SQL* do banco 2: `select * from apex_workspace_schemas;` tem de mostrar `CORLIXHUB` com o schema `WKSP_CORLIXHUB`, como no banco 1. O Path Prefix padrão é o nome do workspace, então os endereços ficam `…/ords/r/corlixhub/corlixhub/…` (confirmar em *Manage Workspaces*).

Se a tela disser **Workspace name already exists**, o workspace provavelmente já foi criado numa tentativa anterior: confira em *Manage Workspaces* ou na consulta acima antes de mudar o nome. Em *Manage Workspaces*, deixe **Auto Purge** = No no DEV, para o workspace não ser apagado por inatividade (confirmar o campo no 26.1.6).

Entre no workspace com o administrador e crie as contas do time em *Administration › Manage Users and Groups*.

Libere o dono do schema para o SQLcl (como `ADMIN`, em *Database Actions › SQL*):

```sql
alter user WKSP_CORLIXHUB identified by "<senha-forte>" account unlock;
grant create session to WKSP_CORLIXHUB;
grant create job to WKSP_CORLIXHUB;   -- jobs do holerite e do suporte
```

### 3.2 Schema

> **Dados:** o time confirmou em 17/11/2026 que **todos os dados do PRD são de teste** (as 309 pessoas da empresa 1 inclusive). Por isso o DEV e o UAT recebem uma cópia deles. **Quando o PRD tiver dados reais (piloto ou cliente), esta cópia para de valer:** os dados só podem ir para DEV e UAT anonimizados, e este passo tem de ser revisto.

Ordem: tabelas → dados → o resto do DDL. Carregar antes das chaves estrangeiras e dos triggers evita erro de ordem entre as tabelas e não dispara a auditoria na carga.

No SQLcl, conectado como `WKSP_CORLIXHUB` no banco 2 (`set cloudconfig <wallet do banco 2>`), a partir da raiz do repositório na branch `DEV` atualizada.

**a) Tabelas**

> **Não rode o `database/ddl/03-tabelas.sql` direto.** O DDL exportado traz, depois de cada tabela, um `INSERT … FROM "<tabela>"@ KU$` e, depois da `HTMLDB_PLAN_TABLE`, um bloco `DECLARE … END;` sem a `/` no fim. O SQLcl junta o resto do arquivo nesse bloco e não executa mais nada: num teste local de 18/11/2026, só 27 das 51 tabelas foram criadas, sem nenhuma mensagem de erro. Gere uma cópia limpa fora do repositório:

```bash
mkdir -p ~/corlix-carga
awk '
  /^  INSERT \/\*\+  APPEND/ { pula = 1 }
  /^  DECLARE CURSOR/        { pula = 2 }
  pula == 1 { if ($0 ~ /KU\$;$/) pula = 0; next }
  pula == 2 { if ($0 ~ /^  END;$/) pula = 0; next }
  { print }
' database/ddl/03-tabelas.sql > ~/corlix-carga/03-tabelas-limpo.sql
grep -c 'CREATE TABLE' ~/corlix-carga/03-tabelas-limpo.sql   # 51 no backup de 18/11/2026
```

```sql
whenever sqlerror exit failure
@database/ddl/01-tipos.sql
@database/ddl/02-sequencias.sql
@~/corlix-carga/03-tabelas-limpo.sql
@modulos/arquivos/05_ddl_prefixo_ambiente.sql
whenever sqlerror continue
select count(*) from user_tables;
```

O `count` tem de dar o mesmo número do `grep`. A correção definitiva é no `scripts/backup/backup.sql`, que o time ajusta (veja "Pendências do time").

**b) Dados do backup do PRD** (o `.tar.gz` do passo 1.3, extraído numa pasta **fora do repositório**, por exemplo `~/corlix-carga/`; ele nunca vai para o Git). Gere a lista de cargas no terminal, pulando os arquivos de controle (`_*.csv`) e os logs:

```bash
cd ~/corlix-carga/corlixhub-prd-<data>
for f in dados/*.csv; do
  t=$(basename "$f" .csv)
  case "$t" in _*|APP_LOG|HTMLDB_PLAN_TABLE) continue ;; esac
  echo "load table $t $PWD/$f"
done > ~/corlix-carga/carregar.sql
```

De volta ao SQLcl, na mesma sessão:

```sql
alter session set nls_date_format = 'YYYY-MM-DD HH24:MI:SS';
alter session set nls_timestamp_format = 'YYYY-MM-DD HH24:MI:SS.FF6';
alter session set nls_timestamp_tz_format = 'YYYY-MM-DD HH24:MI:SS.FF6 TZH:TZM';
alter session set nls_numeric_characters = '.,';
@modulos/ambientes/identidades.sql ANTES
@~/corlix-carga/carregar.sql
@modulos/ambientes/identidades.sql DEPOIS
```

Confira as linhas de cada tabela contra `dados/_contagens.csv`. As colunas BLOB (imagem do comunicado, anexos, logotipo) vêm em base64 e estão listadas em `dados/_colunas-especiais.csv`: carregue-as como no `scripts/backup/README.md` §4 ou deixe-as vazias no DEV.

O `identidades.sql` deixa as colunas `GENERATED ALWAYS` aceitarem os IDs do CSV durante a carga e, no fim, faz cada sequência recomeçar depois do maior ID carregado.

**c) O resto do DDL**

```sql
@database/ddl/04-chaves-estrangeiras.sql
@database/ddl/05-indices.sql
@database/ddl/06-views.sql
@database/ddl/07-materialized-views.sql
@database/ddl/08-plsql-especificacoes.sql
@database/ddl/09-plsql-corpos.sql
@database/ddl/10-triggers.sql
@database/ddl/11-sinonimos.sql
exec dbms_utility.compile_schema(schema => user, compile_all => false);
select object_type, object_name from user_objects where status = 'INVALID';
```

A última consulta deve voltar vazia. Se sobrar algo inválido, veja em "Se não funcionar".

Recompile o package das fotos, que agora usa o prefixo:

```sql
@modulos/arquivos/02_pkg_arquivos.pkb
```

O `04_pkg_foto_perfil.pkb` (envio da foto, CD-75) ainda não está instalado no PRD. Quando for aplicado, siga o `Etapas-upload-foto-perfil.md`: ele já usa o prefixo.

### 3.3 Jobs

Os jobs não vêm no DDL. Rode como `WKSP_CORLIXHUB` no banco 2:

```sql
@modulos/holerite/03_job_folha_mensal.sql
@modulos/suporte-ti/05_job_suporte.sql
```

### 3.4 App

```bash
grep -c create_acl_assignment database/f100.sql   # tem de dar 0
```

No SQLcl, ainda como `WKSP_CORLIXHUB` no banco 2:

```sql
@modulos/ambientes/instalar-app.sql CORLIXHUB WKSP_CORLIXHUB 100 RUN_AND_BUILD
```

Confira no fim: `build_status` de edição liberada e nenhum objeto inválido. O `f100.sql` exportado depois do §0 traz `p_build_status=>'RUN_ONLY'`; o 4º parâmetro (`RUN_AND_BUILD`) troca isso na importação, por `apex_application_install.set_build_status`.

### 3.5 Configurações e credenciais

As senhas e chaves não vêm no export. Refaça no banco 2:

| O quê | Onde | Valor no DEV |
|---|---|---|
| Web Credential das fotos (leitura) | *Workspace Utilities › Web Credentials* | mesma chave de leitura do PRD (`modulos/arquivos/Etapas-fotos-object-storage.md` §3) |
| Web Credential de gravação da foto de perfil | idem | `Etapas-upload-foto-perfil.md` §2, se o módulo estiver aplicado |
| `ARQUIVO_CONFIG` | SQL | a linha veio na carga (3.2); só `update arquivo_config set ds_prefixo = 'dev/' where id_config = 1;` e `commit;` |
| `SUPORTE_CONFIG` | SQL | veio na carga; troque por contatos de teste se quiser diferenciar |
| Contas e papéis | *Administration › Manage Users and Groups* e *App 100 › Shared Components › Application Access Control* | contas e senhas não vêm no backup. Crie as que o time usa nos testes (`teste.rh`, `DEMO.CARREIRA.1.1` e outras) com o mesmo nome de usuário do `login_apex`, e atribua os papéis |

### 3.6 Fotos de teste

As fotos não estão no backup: ficam no bucket `corlix-fotos`, em `empresa/<id>/fotos/`. Para o DEV mostrar as mesmas fotos, copie-as para o prefixo `dev/` com o OCI CLI (perfil com acesso ao bucket):

```bash
oci os object bulk-download --bucket-name corlix-fotos --prefix "empresa/" --download-dir ~/corlix-carga/fotos
oci os object bulk-upload   --bucket-name corlix-fotos --src-dir ~/corlix-carga/fotos --object-prefix "dev/"
oci os object list --bucket-name corlix-fotos --prefix "dev/empresa/" --all --query 'length(data)'
```

A última linha deve dar o mesmo número de arquivos que `--prefix "empresa/"`. Depois, apague `~/corlix-carga/` do computador.

### 3.7 Conferir o DEV

Entre com uma conta de teste no DEV (`…corlixhubdev….oraclecloudapps.com/ords/r/corlixhub/corlixhub/início`) e rode, sem gravar:

- Home abre com saudação, atalhos e comunicados;
- Holerite abre o mês mais recente com valores ocultos;
- as fotos dos colaboradores aparecem (vêm de `dev/empresa/<id>/fotos/`);
- o número de pessoas em Colaboradores é o mesmo do PRD.

## 4. Dia da troca

> **Com o congelamento do §0**, os itens 1 e 4 já foram feitos e os itens 2 e 3 não são necessários: o DEV já nasceu do último estado do banco 1. Falta só avisar o time do endereço do Builder do DEV (item 1) e seguir para o §5.

Sem o §0, combine a data com o time. No dia:

1. Avise: "a partir de agora, o Builder é o do DEV, no endereço …". Ninguém edita mais no banco 1.
2. Rode o backup do PRD (Jenkins) e espere o commit na branch `DEV`. Ele traz as últimas mudanças feitas no banco 1.
3. Reinstale a app no DEV com esse `database/f100.sql` (3.4) e aplique no DEV qualquer DDL novo desde o passo 3.2.
4. Bloqueie o Builder do PRD. No SQLcl, como `WKSP_CORLIXHUB` no banco 1:
   ```sql
   begin
     apex_util.set_workspace(p_workspace => 'CORLIXHUB');
     apex_application_admin.set_build_status(p_application_id => 100, p_build_status => 'RUN_ONLY');
     commit;
   end;
   /
   ```
   Ou no Builder: *Shared Components › Application Definition › Availability › Build Status* = **Run Application Only** (confirmar o caminho no 26.1.5).
5. Confira: no Builder do banco 1, a app 100 não abre para edição; a app no ar continua funcionando.

## 5. Jenkins (backup)

O time altera `scripts/backup/` (o agente não edita essa pasta):

1. Credenciais `corlixhub-db-dev` (`WKSP_CORLIXHUB` + senha do banco 2) e `corlixhub-wallet-dev` (wallet do banco 2), como no `scripts/backup/README.md` §3.
2. No `Jenkinsfile`: descomente a linha `DEV` do mapa `AMBIENTES` com `servico: 'corlixhubdev_low'`.
3. No `Jenkinsfile`: **`AMBIENTE_GIT = 'DEV'`**. O commit diário na branch `DEV` passa a vir do DEV, onde o time edita.
4. Se `grep -c create_acl_assignment database/f100.sql` der mais que 0 depois do primeiro backup do DEV, tire `-expaclassignments` da linha do export SQL em `scripts/backup/backup.sql`. Com ele, o arquivo levaria as atribuições de papel do DEV para o UAT e o PRD, e o workflow recusa a instalação.
5. O UAT não precisa de backup: ele é recriado a partir do Git.

## 6. UAT

### 6.1 Montar

No **banco 2**, repita o 3.1 a 3.6 com estes valores (dados: use o mesmo backup; fotos: prefixo `uat/`):

| Onde | Valor |
|---|---|
| Workspace Name (o schema sai `WKSP_CORLIXHUB_UAT`) | `CORLIXHUB_UAT` |
| Instalação da app | `@modulos/ambientes/instalar-app.sql CORLIXHUB_UAT WKSP_CORLIXHUB_UAT 200 RUN_ONLY` |
| `ARQUIVO_CONFIG.DS_PREFIXO` | `uat/` |
| Path Prefix do workspace | `CORLIXHUB_UAT` |
| Endereço | `…corlixhubdev….oraclecloudapps.com/ords/r/corlixhub_uat/corlixhub/início` |
| Contas | só contas de teste (`teste.rh`, `[DEMO] ...`) |

### 6.2 Uma versão nova, do DEV ao PRD

1. **DEV:** o time trabalha; o backup diário leva a app e o DDL para a branch `DEV`.
2. **PR `DEV` → `UAT`.** No PR, liste os `instalar.sql` (ou arquivos `.sql`/`.pkb`) que mudaram desde a última versão. Antes do merge, rode esses scripts no UAT (SQLcl, `WKSP_CORLIXHUB_UAT`). Depois do merge, a app é instalada no UAT (6.4).
3. **Teste no UAT** pelas seções de teste dos guias. Registre na Situação de cada guia.
4. **PR `UAT` → `PROD`.** Antes do merge, rode os mesmos scripts de banco no PRD. Depois do merge, o workflow espera a aprovação no Environment `prd` e instala.

Ordem que não pode inverter: **banco primeiro, app depois.** A app nova chamando um package que ainda não existe dá erro na tela.

### 6.3 Configurar o GitHub

*Settings › Environments › New environment*, um para cada destino:

| | `uat` | `prd` |
|---|---|---|
| Deployment branches | só `UAT` | só `PROD` |
| Required reviewers | — | pelo menos 1 pessoa do time |
| Variable `DB_SERVICE` | `corlixhubdev_low` | `corlixhub_low` |
| Variable `DB_USER` | `WKSP_CORLIXHUB_UAT` | `WKSP_CORLIXHUB` |
| Variable `APEX_WORKSPACE` | `CORLIXHUB_UAT` | `CORLIXHUB` |
| Variable `APP_ID` | `200` | `100` |
| Variable `BUILD_STATUS` | `RUN_ONLY` | `RUN_ONLY` |
| Secret `DB_PASSWORD` | senha do `WKSP_CORLIXHUB_UAT` | senha do `WKSP_CORLIXHUB` no banco 1 |
| Secret `DB_WALLET_BASE64` | wallet do banco 2 em base64 | wallet do banco 1 em base64 |

Para gerar o base64 do wallet no macOS: `base64 -i Wallet_corlixhubdev.zip | pbcopy` e cole no secret.

O banco 1 também precisa aceitar conexão de fora (*Network access*: acesso de qualquer lugar com mTLS). Se ele tiver lista de IPs liberados, o GitHub Actions não entra; veja "Se não funcionar".

### 6.4 Rodar

1. **Primeira vez, manual:** *Actions › Instalar app (UAT/PRD) › Run workflow*, branch `UAT`, destino `uat`. Acompanhe o log: papéis antes e depois, objetos inválidos e `build_status`.
2. Repita com a branch `PROD` e o destino `prd` só depois de testar o UAT. O job espera a aprovação de quem estiver em *Required reviewers*.
3. Quando as duas tiverem funcionado, crie a variável do repositório `INSTALACAO_AUTOMATICA` = `true` (*Settings › Secrets and variables › Actions › Variables*). A partir daí, todo merge que mudar o `database/f100.sql` na `UAT` ou na `PROD` instala sozinho (o PRD continua esperando aprovação).

Sem o GitHub Actions, dá para fazer a mesma coisa no SQLcl com o `instalar-app.sql` (linha de exemplo no cabeçalho do arquivo).

## 7. Testes

| # | Teste | Esperado |
|---|---|---|
| 1 | Builder do DEV: duas pessoas abrem a mesma app | As duas veem as mesmas mudanças |
| 2 | Builder do banco 1 (PRD) depois do passo 4 | A app 100 não abre para edição; a app no ar funciona |
| 3 | Builder do UAT | A app 200 não abre para edição |
| 4 | Workflow `uat` | Sucesso; papéis antes = papéis depois; nenhum objeto inválido |
| 5 | Workflow `prd` sem aprovação | Fica parado em "Waiting" até alguém aprovar |
| 6 | Workflow `prd` rodado a partir da branch `UAT` | Recusa: "PRD só a partir da PROD" |
| 7 | Contas do PRD depois de uma instalação | Cada pessoa continua com os mesmos papéis (comparar `apex_appl_acl_user_roles` antes e depois) |
| 8 | Foto no UAT | Lê e grava só em `uat/...`; nenhum objeto novo fora do prefixo no bucket |
| 9 | Backup do Jenkins | O commit na `DEV` vem do DEV (o `manifesto.txt` diz `DEV`) |
| 10 | Links da app no UAT | Navegação e botões funcionam com o ID 200 (nenhum link volta para a app 100) |

## Se não funcionar

| Sintoma | Causa provável | Correção |
|---|---|---|
| Não há Always Free disponível no passo 1 | Já existem 2 bancos gratuitos na conta | Decisão do time: apagar um deles ou rever a distribuição |
| `f100.sql` falha logo no começo citando versão | Banco 2 com APEX mais antigo que o banco 1 | Espere a atualização da Oracle no banco 2 ou exporte do banco 1 na versão do banco 2 |
| `ORA-01031` ao criar a tabela temporária em `instalar-app.sql` | Usuário sem `CREATE TABLE` | `grant create table to <usuário>` como `ADMIN` |
| Objeto inválido depois do 3.2 | Package que depende de outro módulo ou de privilégio (ex.: `CREATE JOB`) | `select * from user_errors where name = '<objeto>'` e mande o resultado |
| Fotos não aparecem no DEV | `DS_PREFIXO` vazio ou arquivo fora de `dev/...` | Confira o `update` do 3.5 e o caminho no bucket |
| `ORA-32795: cannot insert into a generated always identity column` na carga | `identidades.sql ANTES` não rodou nessa sessão | Rode o `ANTES` e repita só as tabelas que falharam |
| Carga com `ORA-01843`/`ORA-01858` em datas | Formatos de data da sessão diferentes dos do backup | Os `alter session` do 3.2 b, na mesma sessão da carga |
| Workflow: "atribuições de papel (ACL)" | `f100.sql` exportado com `-expaclassignments` | Passo 5, item 4 |
| Workflow: `ORA-12506` ou tempo esgotado ao conectar | Banco com lista de IPs liberados | *Network access* do banco: acesso de qualquer lugar com mTLS |
| Workflow: "X não configurado no Environment" | Variável ou secret ausente | Tabela do 6.3 |
| Página do UAT abre a app 100 | ID `100` escrito fixo em link ou package | Troque por `apex_page.get_url`/`:APP_ID` no DEV e promova de novo |
| Só parte das tabelas existe no DEV depois do 3.2 a, sem erro na tela | `03-tabelas.sql` rodado direto: o bloco `DECLARE` sem `/` engoliu o resto do arquivo | Gere o `03-tabelas-limpo.sql` do 3.2 a e rode de novo |
| `ORA-02019: connection description for remote database not found` | `INSERT … @ KU$` do DDL exportado | Mesma correção da linha acima |
| `VW_CARREIRA_TIMELINE` (ou outra view) na lista de inválidos do §0.1 | Uma tabela usada pela view foi alterada; a view só se recompila no próximo uso | `alter view <nome> compile` e consulte de novo. Se falhar, `user_errors` da view |
| `SyntaxError: Unexpected token 's', "sqlerrm:OR"...` em qualquer página | `PKG_CHAT_UI` inválido: o `CX_PRESENCA_PING` responde texto em vez de JSON | §0.1, item 2 |
| Builder do PRD continua editável | Passo 4 não aplicado, ou instalação feita sem `RUN_ONLY` | Passo 4; no workflow, `BUILD_STATUS` = `RUN_ONLY` |

## Pendências do time

- **`scripts/backup/backup.sql`** (o agente não edita): o DDL das tabelas sai com `INSERT … @ KU$` e com o bloco `DECLARE` da `HTMLDB_PLAN_TABLE` sem `/`. Está assim pelo menos desde o backup de 10/11/2026. Até corrigir, use o filtro do 3.2 a.
- **`PKG_CHAT_UI` e `CX_PRESENCA_PING`** não estão em nenhum módulo do repositório (só no backup). Quem fez o chat precisa versionar o código em `modulos/` com guia.

## Voltar atrás

- **Durante o congelamento (§0), antes do §3:** volte o Build Status do banco 1 para `RUN_AND_BUILD` e avise o time. Nada mais mudou.
- **Antes do passo 4:** nada mudou para quem usa a app. Apague o banco 2 se quiser desistir.
- **Depois do passo 4:** volte o Build Status do banco 1 para `RUN_AND_BUILD` (mesmo bloco do passo 4), avise o time para editar de novo no banco 1 e volte `AMBIENTE_GIT` para `PRD` no Jenkins.
- **Uma instalação ruim no PRD:** rode o workflow `prd` a partir de um commit anterior da `PROD` (revert do PR) ou importe o `f100.sql` do último backup do PRD com o `instalar-app.sql`.

## Situação

| Data | Evento | Resultado |
|---|---|---|
| 17/11/2026 | Proposta ([`12`](../../docs/ai-context/12-ambientes-dev-uat-prd.md)) e decisões do time | Distribuição aceita; prefixo `dev/`/`uat/` nas fotos; GitHub Actions. Dados: "só demonstração" (revisto na linha seguinte) |
| 17/11/2026 | Guia, `instalar-app.sql`, workflow `.github/workflows/instalar-app.yml` e prefixo das fotos (`05_ddl_prefixo_ambiente.sql`, `pkg_arquivos`, `pkg_foto_perfil`) versionados | **Testado:** `05_ddl_prefixo_ambiente.sql` num Oracle 23ai local descartável (sem APEX). Ele roda duas vezes sem erro, aceita `dev/`, recusa `dev` e `../`, e com a coluna vazia o caminho continua `/o/empresa/1/fotos/x.jpg`. O YAML e o shell do workflow passaram na checagem de sintaxe. **Não testados:** `instalar-app.sql`, o workflow e os packages de fotos, que dependem do APEX e de um banco 2 que ainda não existe. |
| 17/11/2026 | Respostas do time às pendências | Troca marcada para **18/11/2026**. Todos os dados do PRD são de teste, então DEV e UAT recebem uma cópia pelo backup (3.2 b) em vez de um script de demonstração. O workspace se chama `WKSP_CORLIXHUB` (`CORLIXHUB` é o nome do Autonomous AI Database); guia, `instalar-app.sql` e `testar-na-app.md` corrigidos |
| 17/11/2026 | `identidades.sql` versionado | **Testado** num Oracle 23ai local descartável: `GENERATED ALWAYS`, `BY DEFAULT` e `BY DEFAULT ON NULL` aceitam o ID do CSV depois do `ANTES` e voltam ao tipo original no `DEPOIS`, recomeçando depois do maior ID (50→51, 70→71, 90→91), e a tabela de controle é apagada. O primeiro teste achou um erro (o `ON NULL` voltava como `BY DEFAULT`), já corrigido |
| 18/11/2026 | Ordem trocada: **congelar primeiro** (§0), a pedido do time | Validado o backup de 18/11 num Oracle 23ai local: o `03-tabelas.sql` criava só 27 das 51 tabelas (bloco `DECLARE` sem `/` e `INSERT … @ KU$`). O filtro do 3.2 a cria as 51, sem erro, com `whenever sqlerror exit`. O `PKG_CHAT_UI` do backup compila sem erro com as tabelas completas; no banco 1 ele está inválido (visto na app em 17/11/2026, `ORA-04063`). **Nada foi executado no Oracle Cloud.** Próximo passo: §0.1 e §0.2 pelo time |
| 18/11/2026 | Validação da DEV depois do backup das 09:15 (`ec1176e`) e dos PRs #192 a #194 | O backup diz "Sem mudanças na app nem no DDL" em relação ao das 02:52, então o filtro do 3.2 a continua valendo (51 tabelas, testado). O `PKG_CHAT_UI` versionado em `modulos/chat/` (PR #193) é igual ao do backup, só com comentários a mais, e compila. **Não conferido na app** (a sessão expirou e o login é do time): se o Build Status do banco 1 já está `RUN_ONLY` e se o `PKG_CHAT_UI` voltou a `VALID`. O export não mostra o Build Status. Próximo passo: o time confirma o §0.1 e o §0.2, item 3, e segue para o §1 |
| 18/11/2026 | Time: `PKG_CHAT_UI` resolvido; congelamento ainda não feito | §0.2 reescrito para o SQL Commands: conferir o Build Status antes e depois com `apex_application_admin.get_build_status` e bloquear com `set_build_status` (API conferida na documentação do 26.1). Desbloqueio sem SQL por *Administration › Manage Service › Application Build Status* (Administration Guide 2.14.2) |
| 18/11/2026 | §0.1 no banco 1: sobrou `VW_CARREIRA_TIMELINE` inválida | A view do backup compila sem erro com as tabelas do backup (Oracle 23ai local). Orientado `alter view vw_carreira_timeline compile`; aguardando o resultado do time |
| 18/11/2026 | **§0 feito pelo time** (itens 0.1 e 0.2, 1 a 5): `VW_CARREIRA_TIMELINE` recompilada, nenhum objeto inválido, Build Status `RUN_ONLY`, app no ar funcionando | Backup do congelamento: commit `6978491` (`corlixhub-prd-20261118-123528.tar.gz`, build 74 do Jenkins). O backup rodou com o Builder bloqueado. O export mostra `p_build_status=>'RUN_ONLY'` e `buildStatus: runOnly`; o DDL não mudou desde as 02:52 (filtro do 3.2 a vale). **Base do DEV: `DEV` em `6978491`.** Próximo passo: §1 e §2 |
| 18/11/2026 | §1 conferido pelo time | `adb-free-count`: limite 2, uso 1, **1 disponível**. Console só oferece 26ai para o banco novo; senha do ADMIN por `openssl` (comando no §2, testado: 24 caracteres, regras do ADB) |
| 18/11/2026 | **§2 feito pelo time:** banco 2 `corlixhubdev` criado | Print conferido: **Always Free**, Instance type **Free**, compartimento `corlix-dev-uat`, Transaction Processing, 26ai. APEX do banco 2: **26.1.6**, igual ao banco 1. Próximo passo: wallet e §3.1 |
| 18/11/2026 | Nome do workspace corrigido | `apex_workspace_schemas` no banco 1: workspace **`CORLIXHUB`** (ID `10008945716225088`, o mesmo do `f100.sql`), schema `WKSP_CORLIXHUB`. Guia, `instalar-app.sql`, doc 12 e `testar-na-app.md` corrigidos: o 1º parâmetro do `instalar-app.sql` e a variável `APEX_WORKSPACE` passam a ser `CORLIXHUB`/`CORLIXHUB_UAT`. O §3.1 agora segue a tela simplificada do Autonomous Database, sem campo de schema |
| 18/11/2026 | **§3.1: workspace criado no banco 2** | `apex_workspace_schemas` no `corlixhubdev`: `CORLIXHUB` (ID `9532154002622806`), schema `WKSP_CORLIXHUB`, como no banco 1. A segunda tentativa deu "Workspace name already exists" porque a primeira já tinha criado. Workspace com Auto Purge = Yes; orientado mudar para No. Falta: `alter user`/`grant` do §3.1 |
