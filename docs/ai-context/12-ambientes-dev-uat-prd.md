# 12 · Ambientes DEV, UAT e PRD (proposta)

> **Estado em 17/11/2026: decisões tomadas, passo a passo pronto, nada aplicado.** As decisões da seção 8 estão no início de [`modulos/ambientes/Etapas-ambientes.md`](../../modulos/ambientes/Etapas-ambientes.md), que é o guia de execução. Ele usa o [`instalar-app.sql`](../../modulos/ambientes/instalar-app.sql) e o workflow [`.github/workflows/instalar-app.yml`](../../.github/workflows/instalar-app.yml). Nada foi criado no Oracle Cloud nem no APEX. Tarefa: CD-77.

## 1. Situação hoje

- Existe **uma única instância**: um Autonomous Database da OCI com o workspace `WKSP_CORLIXHUB` e a app 100. O time desenvolve no Builder dessa instância, e é ela que está no ar (`…/ords/r/corlixhub/corlixhub/início`). Na prática, DEV e PROD são o mesmo banco.
- O Git já tem as branches `DEV`, `UAT` e `PROD`, mas elas não correspondem a bancos diferentes. O backup diário do Jenkins chama essa instância de `PRD` (`scripts/backup/Jenkinsfile`, mapa `AMBIENTES`) e já deixa comentada uma entrada `DEV` (`corlixhubdev_low`) para "quando o ambiente existir".
- **Consequência:** toda mudança feita no Builder vale na hora para quem usa a app. Não existe um lugar para testar antes de publicar.

## 2. Limites do plano gratuito (Always Free)

| Limite | Valor | Fonte |
|---|---|---|
| Autonomous Databases gratuitos por conta (tenancy) | **2**, criados na região principal (*home region*) da conta | [Always Free Resources](https://docs.oracle.com/en-us/iaas/Content/GSG/Concepts/alwaysfree.htm) |
| O banco do APEX Service conta nesse limite | Sim: são 2 no total, somando todos os tipos | [APEX Always Free](https://docs.oracle.com/en/cloud/paas/apex/gsadd/always-free-oracle-apex-application-development.html) |
| Armazenamento por banco | cerca de 20 GB | [Always Free Autonomous Database](https://docs.cloud.oracle.com/iaas/Content/Database/Concepts/adbfreeoverview.htm) |
| Sessões simultâneas por banco | 30 na maior parte da documentação; uma página diz 20 | idem |
| Banco parado por falta de uso | Parado depois de alguns dias sem uso; pode ser apagado se ficar parado por muito tempo | **confirmar na documentação antes de aplicar** |

Ter três bancos gratuitos não é possível. Abrir uma segunda conta gratuita para conseguir o terceiro também não serve: os termos da Oracle preveem uma conta gratuita por pessoa.

## 3. Proposta

| Banco gratuito | Workspace | App | Endereço | Uso |
|---|---|---|---|---|
| **Banco 1** (o atual, `CORLIXHUB`) | `WKSP_CORLIXHUB` | 100 | `…/ords/r/corlixhub/corlixhub/início` (não muda) | **PRD**: só a app no ar. Ninguém edita no Builder |
| **Banco 2** (novo) | `WKSP_CORLIXHUB` | 100 | `…/ords/r/corlixhub/corlixhub/início` em outro domínio | **DEV**: o time inteiro edita no Builder, como hoje |
| **Banco 2** | `WKSP_CORLIXHUB_UAT` | 200 (ver 4.1) | `…/ords/r/corlixhub_uat/corlixhub/início` (confirmar o prefixo) | **UAT**: recebe versões vindas do DEV para teste. Ninguém edita no Builder |

**Por que o DEV fica compartilhado na nuvem, e não no Docker de cada pessoa.** No APEX, a app fica guardada no banco de dados, e o Builder grava direto no banco. Com um DEV local para cada pessoa, uma não veria o que a outra mudou. Sincronizar essas cópias pelo Git exigiria exportar e importar o tempo todo, e o export de uma página editada por duas pessoas não se junta bem no Git. Com o DEV num banco só, o time continua trabalhando como hoje.

**Por que o PRD fica no banco atual.** O endereço que as pessoas já usam continua o mesmo, os dados ficam onde estão, e o Jenkins já trata esse banco como `PRD`.

**Por que o UAT fica junto com o DEV.** São os ambientes que não atendem quem usa a app. Como o DEV é usado todo dia, o banco 2 não fica parado, e o UAT não corre o risco de ser desligado por falta de uso, o que poderia acontecer se ele tivesse um banco só para ele. O PRD fica com o banco 1 inteiro: sessões, espaço e CPU.

**Docker local** (o `docker-compose.yml` antigo, ver 01 §5.1): continua opcional, só para experimentar algo arriscado sem afetar o DEV.

## 4. Pontos técnicos

### 4.1 ID da app no UAT

O ID da aplicação é único na instância do APEX inteira, não só no workspace. Por isso o UAT, que fica no mesmo banco do DEV, não pode usar o ID 100. Na importação para o UAT, a app ganha outro ID (proposto: 200), com *offset* nos IDs dos componentes.

- **Antes de aplicar:** procurar ID fixo na app e nos packages (`f?p=100:`, `p_application => 100`, `:APP_ID` escrito como número). Na conferência de 17/11/2026, só dois guias citam `f?p=100`, e nenhum package tem o ID fixo. Os links da app são gerados com `apex_page.get_url`, que usa a app atual.
- No DEV e no PRD a app continua com o ID 100.

### 4.2 Schema, dados e LGPD

- Cada workspace tem o próprio schema: `WKSP_CORLIXHUB` no DEV e `WKSP_CORLIXHUB_UAT` no UAT. As tabelas e os packages são instalados pelos `instalar.sql` dos módulos e pelo DDL de `database/ddl/`.
- **Dados de DEV e UAT:** hoje os dados do PRD são todos de teste (confirmado pelo time em 17/11/2026), então DEV e UAT recebem uma cópia pelo backup (`Etapas-ambientes.md` 3.2). O backup continua fora do Git (01 §8.1). **Quando o PRD tiver dados reais, a cópia só pode ser feita com anonimização**, e o passo tem de ser revisto.
- **Configurações por ambiente:** `ARQUIVO_CONFIG` (bucket e credencial das fotos) e `SUPORTE_CONFIG` precisam de valores próprios em cada schema. Proposta: um prefixo ou bucket separado para DEV e UAT, para que um teste nunca apague a foto real de alguém.

### 4.3 Usuários e papéis

As contas do APEX e os papéis da app são de cada workspace e de cada app. O UAT precisa das próprias contas de teste (`teste.rh`, contas `[DEMO]`) e dos papéis (`ADMIN_RH`, `SUPORTE_TI` e os outros). A senha de cada conta é criada pelo time.

### 4.4 PRD protegido contra edição

No PRD, em *Shared Components › Application Definition › Availability*, marcar **Build Status** = `Run Application Only` (confirmar o caminho no 26.1.5). Assim a app roda, mas ninguém consegue editá-la pelo Builder. A importação de uma versão nova continua funcionando.

### 4.5 Backup (Jenkins)

- Descomentar a entrada `DEV` do mapa `AMBIENTES` no `scripts/backup/Jenkinsfile` e criar as credenciais `corlixhub-db-dev` e `corlixhub-wallet-dev` (`scripts/backup/README.md` §1).
- **Mudar `AMBIENTE_GIT` de `PRD` para `DEV`.** Hoje o backup que vira commit na branch `DEV` sai do PRD, porque é lá que o time edita. Depois da mudança, quem edita é o DEV, e o commit diário tem de sair dele. O backup do PRD continua sendo feito, só como cópia de segurança.
- O UAT pode ficar fora do backup diário: dá para recriá-lo a partir do Git.

## 5. Como uma versão vai do DEV ao PRD

```
Builder (DEV) ──backup diário──▶ branch DEV ──PR──▶ branch UAT ──instala──▶ UAT (app 200)
                                                         │
                                                  time testa no UAT
                                                         │
                                         PR ──▶ branch PROD ──aprovação──▶ PRD (app 100)
```

1. O time trabalha no Builder do DEV. O backup diário (4.5) leva a app e o DDL para a branch `DEV`, como já acontece hoje.
2. Um PR `DEV` → `UAT` marca a versão a testar. O merge instala essa versão no UAT: importa a app com o ID 200 e roda o DDL e os packages que mudaram.
3. O time testa no UAT (seção de testes de cada guia).
4. Um PR `UAT` → `PROD`. O merge instala no PRD depois da aprovação de uma pessoa do time.

**Ferramenta de instalação.** Duas fases:

- **Fase 1, manual:** uma pessoa do time roda o SQLcl conectado ao destino. Importa a app (`apex import` do APEXlang ou `@f100.sql`, ver `scripts/backup/README.md` §4) e roda os `instalar.sql` dos módulos que mudaram. Cada instalação fica registrada no PR.
- **Fase 2, automática:** usar **SQLcl Projects**, que gera um pacote de versão a partir do Git e o instala no destino ([Pretius](https://pretius.com/?p=15514), [fórum da Oracle](https://forums.oracle.com/ords/apexds/post/ci-cd-sqlcl-across-environments-7567), [ciclo de vida no APEX 26.1](https://docs.oracle.com/en/database/oracle/apex/26.1/apxdc/summarizing-lifecycle-recommendations.html)). Exige SQLcl 24.4 ou mais novo. Quem roda o pipeline pode ser:
  - **GitHub Actions**, com um *Environment* por destino (`uat` automático e `prd` com *required reviewers*). O wallet e as senhas ficam guardados como *secrets* desses Environments. É o mais parecido com o console do Liferay Cloud: cada versão, quem aprovou e o resultado ficam na aba Actions do repositório.
  - **Jenkins**, que já tem SQLcl, wallet e credenciais por ambiente para o backup.

**Painel no Oracle Cloud:** um compartimento por ambiente (`corlix-prd` para o banco 1 e `corlix-dev-uat` para o banco 2), com tags. Lá se liga e desliga cada banco, se acompanha o uso e se controla quem acessa o quê.

## 6. Plano de migração

Cada passo é feito pelo time, no Oracle Cloud ou no Builder. Os agentes só escrevem guias e documentação (`AGENTS.md`).

| # | Passo | Como voltar atrás |
|---|---|---|
| 1 | Conferir em *Limits, Quotas and Usage* que a conta ainda tem 1 Autonomous Database gratuito disponível | — |
| 2 | Criar o banco 2 (`corlixhubdev`, **Always Free**, na região principal, no compartimento `corlix-dev-uat`) | Apagar o banco 2 |
| 3 | No banco 2, criar o workspace `WKSP_CORLIXHUB` e instalar o schema (DDL de `database/ddl/` e os `instalar.sql` dos módulos, na ordem do 06) | Apagar o workspace |
| 4 | Importar a app 100 do último backup e carregar os dados de demonstração. Criar as contas de teste e os papéis | Reimportar |
| 5 | Conferir o DEV novo pela seção de testes dos guias principais (Home, Comunicados, Holerite, Ponto) | — |
| 6 | **Dia da troca:** congelar o Builder do banco 1, gerar um último backup, importar no DEV novo e marcar o banco 1 como `Run Application Only` (4.4). Avisar o time do novo endereço do Builder | Voltar o Build Status do banco 1 para `Run and Build Application` |
| 7 | Ajustar o Jenkins (4.5) e conferir um backup do DEV chegando na branch `DEV` | Voltar `AMBIENTE_GIT` para `PRD` |
| 8 | Criar o workspace `WKSP_CORLIXHUB_UAT` no banco 2, importar a app como 200 e criar as contas | Apagar o workspace |
| 9 | Fazer uma primeira promoção completa DEV → UAT → PRD, ainda manual (fase 1) | — |
| 10 | Automatizar com SQLcl Projects (fase 2) | Continuar manual |

Atualizar a documentação no mesmo PR de cada etapa: 01 §5 e §8, `docs/agentes/fluxos/testar-na-app.md` (endereço do DEV), `README.md` da raiz e `scripts/backup/README.md`.

## 7. Riscos e limites

- **DEV e UAT dividem o banco 2:** um teste pesado no UAT pode deixar o Builder do DEV mais lento, e o limite de sessões é dividido entre os dois.
- **Duas pessoas na mesma página:** o DEV compartilhado não resolve isso sozinho. Use *Page Locks* no Builder (confirmar no 26.1.5).
- **ID 200 no UAT:** se algum código tiver o ID 100 escrito fixo, ele vai funcionar no DEV e no PRD e falhar só no UAT (4.1).
- **Atualizações da Oracle:** os dois bancos recebem as atualizações do APEX e do banco em datas que a Oracle decide, então DEV e PRD podem ficar em versões diferentes por alguns dias.
- **Plano gratuito:** se a conta deixar de ser gratuita (*upgrade*), confira se os bancos continuam marcados como **Always Free**, para não haver cobrança.

## 8. Decisões do time (tomadas em 17/11/2026, menos a 5)

Respostas: 1, aceita; 2, só demonstração, e depois o time confirmou que **todos os dados do PRD são de teste**, então DEV e UAT recebem uma cópia deles (revisar quando houver dados reais); 3, prefixo `dev/` e `uat/` no mesmo bucket (coluna `ARQUIVO_CONFIG.DS_PREFIXO`); 4, GitHub Actions; 5, troca em 18/11/2026. O workspace se chama `WKSP_CORLIXHUB`; `CORLIXHUB` é o nome do Autonomous AI Database.

1. Aceitar a distribuição da seção 3 (PRD no banco atual; DEV e UAT no banco novo).
2. Dados de DEV e UAT: só demonstração ou uma cópia anonimizada do PRD (4.2).
3. Bucket ou prefixo das fotos para DEV e UAT (4.2).
4. Instalação automática pelo GitHub Actions ou pelo Jenkins (seção 5, fase 2).
5. Data do congelamento do Builder no banco 1 (passo 6).
