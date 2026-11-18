# Ambientes DEV, UAT e PRD · passo a passo

> **Para quem executa:** o time, no Oracle Cloud, no APEX, no Jenkins e no GitHub. O agente escreveu este guia, o `instalar-app.sql` e o workflow `instalar-app.yml`, mas não cria nem altera nada nesses lugares. Motivo e comparação de alternativas: [`docs/ai-context/12-ambientes-dev-uat-prd.md`](../../docs/ai-context/12-ambientes-dev-uat-prd.md). Tarefa: [CD-77](https://corlix.youtrack.cloud/issue/CD-77).

## Decisões (17/11/2026)

| Tema | Decisão |
|---|---|
| Distribuição | **Banco 1 (atual) = PRD.** **Banco 2 (novo) = DEV + UAT**, em workspaces separados |
| Dados de DEV e UAT | **Só demonstração**: nenhum dado pessoal do PRD |
| Fotos | Mesmo bucket `corlix-fotos`, com prefixo **`dev/`** e **`uat/`** |
| Instalação nos ambientes | **GitHub Actions**, com aprovação obrigatória no PRD. Antes da automação, a primeira vez é manual |
| Data da troca (passo 4) | **A definir pelo time** |

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

> **Nome do workspace:** confirme em *Administration Services › Manage Workspaces* do banco 1 como o workspace se chama (os documentos citam `CORLIXHUB` e `WKSP_CORLIXHUB`). Use o mesmo nome no DEV e troque `CORLIXHUB` por ele em todo este guia e no Environment `prd` (6.3). O `instalar-app.sql` recusa um nome que não corresponda ao schema conectado.

> **ID 200 no UAT:** o ID da app é único na instância do APEX, e DEV e UAT estão no mesmo banco. Por isso não use `f?p=100:` nem `100` escrito fixo no código: use `apex_page.get_url` e `:APP_ID`.

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
| Database version | a mesma do banco 1 (23ai) |
| ADMIN password | criada pelo time e guardada no cofre de senhas do time |
| Network access | **Secure access from everywhere**, com mTLS obrigatório (o GitHub Actions entra pela internet, com o wallet) |

Depois de criado: *Database connection › Download wallet*. O alias do serviço (`corlixhubdev_low`) está no `tnsnames.ora` dentro do zip.

Mova o banco 1 para um compartimento `corlix-prd` se quiser separar no console (*More actions › Move resource*).

## 3. Montar o DEV no banco 2

### 3.1 Workspace

No banco 2: *Database Actions › APEX › Administration Services* (entre como `ADMIN`) *› Manage Workspaces › Create Workspace*:

| Campo | Valor |
|---|---|
| Database User | `WKSP_CORLIXHUB` (novo) |
| Workspace Name | `CORLIXHUB` |

Entre no workspace com o usuário administrador que o assistente criar e crie as contas do time em *Administration › Manage Users and Groups*.

Libere o dono do schema para o SQLcl (como `ADMIN`, em *Database Actions › SQL*):

```sql
alter user WKSP_CORLIXHUB identified by "<senha-forte>" account unlock;
grant create session to WKSP_CORLIXHUB;
grant create job to WKSP_CORLIXHUB;   -- jobs do holerite e do suporte
```

### 3.2 Schema

No SQLcl, conectado como `WKSP_CORLIXHUB` no banco 2 (`set cloudconfig <wallet do banco 2>`), a partir da raiz do repositório na branch `DEV` atualizada:

```sql
@database/ddl/01-tipos.sql
@database/ddl/02-sequencias.sql
@database/ddl/03-tabelas.sql
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

Depois, aplique a coluna de prefixo das fotos e recompile os dois packages de arquivos, que agora a usam:

```sql
@modulos/arquivos/05_ddl_prefixo_ambiente.sql
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

Confira no fim: `build_status` de edição liberada e nenhum objeto inválido.

### 3.5 Configurações e credenciais

As senhas e chaves não vêm no export. Refaça no banco 2:

| O quê | Onde | Valor no DEV |
|---|---|---|
| Web Credential das fotos (leitura) | *Workspace Utilities › Web Credentials* | mesma chave de leitura do PRD (`modulos/arquivos/Etapas-fotos-object-storage.md` §3) |
| Web Credential de gravação da foto de perfil | idem | `Etapas-upload-foto-perfil.md` §2, se o módulo estiver aplicado |
| `ARQUIVO_CONFIG` | SQL | o mesmo `insert` do `Etapas-fotos-object-storage.md` §4 e depois `update arquivo_config set ds_prefixo = 'dev/' where id_config = 1;` |
| `SUPORTE_CONFIG` | SQL | contatos de teste (`Etapas-suporte-ti.md` §1.3) |
| Papéis da app | *App 100 › Shared Components › Application Access Control* | os papéis vieram no export; atribua às contas do time |

### 3.6 Dados de demonstração

**Nenhum CSV do backup do PRD entra no DEV.** O backup tem dados pessoais.

Carga mínima para a app abrir e os guias serem testáveis: empresa, departamentos, cargos (com `SALARIO_BASE`), categorias de comunicado, tipos de movimentação e algumas pessoas fictícias (`[DEMO] ...`), cada uma com conta APEX e `login_apex`. Holerites: `prc_gerar_holerites_pendentes` gera a partir da admissão (`Etapas-holerite.md` §1.2).

> **Pendente:** o script `modulos/ambientes/dados-demo.sql` ainda não existe. Para escrevê-lo sem copiar dado real, o time precisa dizer quais registros do PRD já são fictícios (por exemplo, se as 309 pessoas da empresa 1 foram geradas para teste ou são pessoas reais). Até lá, cadastre pelo próprio app no DEV.

### 3.7 Conferir o DEV

Entre com uma conta de teste no DEV (`…corlixhubdev….oraclecloudapps.com/ords/r/corlixhub/corlixhub/início`) e rode, sem gravar:

- Home abre com saudação, atalhos e comunicados;
- Holerite abre o mês mais recente com valores ocultos;
- uma foto enviada para `dev/empresa/<id>/fotos/` aparece; a mesma foto sem o prefixo **não** aparece.

## 4. Dia da troca

Combine a data com o time. No dia:

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

No **banco 2**, repita o 3.1 a 3.5 com estes valores:

| Onde | Valor |
|---|---|
| Workspace / Database User | `CORLIXHUB_UAT` / `WKSP_CORLIXHUB_UAT` |
| Instalação da app | `@modulos/ambientes/instalar-app.sql CORLIXHUB_UAT WKSP_CORLIXHUB_UAT 200 RUN_ONLY` |
| `ARQUIVO_CONFIG.DS_PREFIXO` | `uat/` |
| Endereço | `…corlixhubdev….oraclecloudapps.com/ords/r/corlixhub_uat/corlixhub/início` (confirmar o prefixo do workspace em *Manage Workspaces*) |
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
| Workflow: "atribuições de papel (ACL)" | `f100.sql` exportado com `-expaclassignments` | Passo 5, item 4 |
| Workflow: `ORA-12506` ou tempo esgotado ao conectar | Banco com lista de IPs liberados | *Network access* do banco: acesso de qualquer lugar com mTLS |
| Workflow: "X não configurado no Environment" | Variável ou secret ausente | Tabela do 6.3 |
| Página do UAT abre a app 100 | ID `100` escrito fixo em link ou package | Troque por `apex_page.get_url`/`:APP_ID` no DEV e promova de novo |
| Builder do PRD continua editável | Passo 4 não aplicado, ou instalação feita sem `RUN_ONLY` | Passo 4; no workflow, `BUILD_STATUS` = `RUN_ONLY` |

## Voltar atrás

- **Antes do passo 4:** nada mudou para quem usa a app. Apague o banco 2 se quiser desistir.
- **Depois do passo 4:** volte o Build Status do banco 1 para `RUN_AND_BUILD` (mesmo bloco do passo 4), avise o time para editar de novo no banco 1 e volte `AMBIENTE_GIT` para `PRD` no Jenkins.
- **Uma instalação ruim no PRD:** rode o workflow `prd` a partir de um commit anterior da `PROD` (revert do PR) ou importe o `f100.sql` do último backup do PRD com o `instalar-app.sql`.

## Situação

| Data | Evento | Resultado |
|---|---|---|
| 17/11/2026 | Proposta ([`12`](../../docs/ai-context/12-ambientes-dev-uat-prd.md)) e decisões do time | Distribuição aceita; só dados de demonstração; prefixo `dev/`/`uat/` nas fotos; GitHub Actions |
| 17/11/2026 | Guia, `instalar-app.sql`, workflow `.github/workflows/instalar-app.yml` e prefixo das fotos (`05_ddl_prefixo_ambiente.sql`, `pkg_arquivos`, `pkg_foto_perfil`) versionados | **Testado:** `05_ddl_prefixo_ambiente.sql` num Oracle 23ai local descartável (sem APEX). Ele roda duas vezes sem erro, aceita `dev/`, recusa `dev` e `../`, e com a coluna vazia o caminho continua `/o/empresa/1/fotos/x.jpg`. O YAML e o shell do workflow passaram na checagem de sintaxe. **Não testados:** `instalar-app.sql`, o workflow e os packages de fotos, que dependem do APEX e de um banco 2 que ainda não existe. Falta a data da troca e o script de dados de demonstração (3.6) |
