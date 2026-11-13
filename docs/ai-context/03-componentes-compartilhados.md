# 03 — Componentes compartilhados (Shared Components) da app 100 CORLIXHUB

> **Estado em 13/11/2026 (backup `84f8625`).** Fonte da verdade: `corlixhub/application.apx`, `corlixhub/page-groups.apx`, `corlixhub/shared-components/*.apx`, `corlixhub/shared-components/themes/universal-theme/**`, as 42 páginas em `corlixhub/pages/` e trechos de `database/f100.sql` (só grep).
> APEXlang `mmdVersion` `26.1.0+3102` (`corlixhub/.apex/apexlang.json`). O cabeçalho do `f100.sql` desse backup diz `Version: 26.1.6`; os guias do projeto continuam escritos para o Builder **26.1.5** (ver 08 §1, regra 11) — a diferença não foi confirmada com o time.
> Todas as contagens de "páginas que usam" saíram de `grep` nos `.apx` desse backup. Para recontar: `grep -h "pageTemplate:\|dialogTemplate:\|template: @\|buttonTemplate:" corlixhub/pages/*.apx | sort | uniq -c`.

---

## 1. Configuração da aplicação (`corlixhub/application.apx`)

| Item | Valor | Observação |
|---|---|---|
| Alias / nome | `CORLIXHUB` / `Corlix Hub` | Owner/schema `WKSP_CORLIXHUB` (f100.sql). |
| Logo | tipo `text`, texto `CorlixHub` | Renderizado em `#LOGO#` do page template. |
| Home | página `1` | |
| Login | página `LOGIN` (= 9999) | |
| Autenticação | `@oracle-apex-accounts` (tipo `oracleApexAccounts`) | Usuários são **contas do workspace APEX**. Pós-login: app process `SET_G_ID_EMPRESA` (§3.2). |
| Navigation menu | lista `@navigation-menu`, template `@/side-navigation-menu`, posição `side` | Template options: `js-navCollapsed--default`, `t-TreeNav--styleA`. Saiu o `js-defaultCollapsed` (estava no estado de 06/10): o menu **não começa mais recolhido**; `js-navCollapsed--default` define o modo de recolher (só ícones) quando o usuário fecha o menu (comportamento do UT, não testado aqui). |
| Navigation bar | `implementation: classic` | Sem lista. O cabeçalho real (busca, sino, menu do usuário) vem da **Global Page 0** (§1.2). |
| Tema | `@universal-theme` (UT 42, `ut-26.1`, estilo `Redwood Light`) | `globalPage: 0`; `addBuiltWithApexToFooter: false`. |
| Máscaras de formato | `date`, `timestamp`, `timestampTimeZone` = `DS` | Idioma primário técnico `en` (`p_flow_language=>'en'`). Formate datas explicitamente (`to_char(..., 'dd/mm/yyyy')`). |
| CSS globais | `#APP_FILES#corlix-tema#MIN#.css`, depois `#APP_FILES#custom#MIN#.css` | Ordem tema → ajustes. O `f100.sql` agora tem a mesma ordem (a inversão de 06/10 foi corrigida). |
| Segurança | `runtimeApiUsage: modifyWorkspaceRepository` (`p_runtime_api_usage=>'W'`) | Permite `apex_util.create_user` (P14). |
| Session State Protection | habilitado (`p_page_protection_enabled_y_n=>'Y'`), `checksumSalt` fixo, `SH512` | A maioria das páginas usa `pageAccessProtection: argumentsMustHaveChecksum` (exceções: p0, p29 e p44, ver §2.3) → **links com parâmetros via `apex_page.get_url`**. App items têm `p_protection_level=>'I'` (Restricted). |
| Error handler | `log_pkg.apex_error_handler` | Fonte em `database/ddl/09-plsql-corpos.sql` (§12). |
| Runtime | `allowFeedback: true` | |
| Substituição | `APP_NAME` = `CorlixHub` | `supporting-objects/substitutions.apx` traz `substitution APP_NAME ( )` vazio (artefato do export). |
| Outros (f100.sql) | `p_flow_version=>'Release 1.0'`, `p_rejoin_existing_sessions=>'N'`, `p_is_pwa=>'Y'`, `p_page_view_logging=>'YES'` | |

### 1.1 Deployment / grupos de páginas / supporting objects
- `corlixhub/deployments/default.json`: só `{"app":{"id":100}}`. O `debugging: true` que existia em 06/10 **saiu**.
- `corlixhub/page-groups.apx`: um único grupo `administration` ("Administration"), **não usado** por nenhuma página.
- `corlixhub/supporting-objects/supporting-objects.apx`: só `includeInAppExport: true`. Importar a app **não cria tabelas, packages nem dados**; o DDL está em `database/ddl/` e nos `modulos/<m>/`.

### 1.2 Cabeçalho global (Global Page 0)
`pages/p00000-global-page.apx` tem duas regiões, ambas com template `@/standard` e opções `t-Region--removeHeader js-removeLandmark`, `t-Region--noUI`, `t-Region--scrollBody`:
- **Barra de Busca** (Dynamic Content, slot `afterLogo`): `return pkg_busca_ui.render_campo;` (módulo `modulos/busca`; resultados na p29).
- **Perfil** (Static Content, slot `afterNavigationBar`): sino → `f?p=&APP_ID.:NOTIFICACOES:&SESSION.`; botão do usuário com `&APP_USER_FOTO!ATTR.` e fallback `&APP_USER_INICIAIS.` (`.cx-avatar-iniciais`), `&G_NOME_USUARIO.`; menu `popover` (`#cx-menu-usuario`) com `&APP_USER.` · `&G_NOME_EMPRESA.`, "Meu perfil" (`MEU-PERFIL`) e "Sair" (`&LOGOUT_URL.`).
- Os links fixos `r/corlixhub/...` e a engrenagem de Configurações **saíram** (substituídos pelos aliases acima). O fallback de iniciais ainda usa `style="display:none"` no HTML da região (contraria a regra C1 do 11).

---

## 2. Roles ACL e Authorization Schemes

### 2.1 Roles (`acl-roles.apx`)
| Static ID | Nome | Descrição no export |
|---|---|---|
| `admin-rh` | Admin RH | "Equipe de RH. Usado pela autorização ADMIN_RH." |
| `colaborador` | Colaborador | "Acesso básico. Dado a todo usuário cadastrado." |
| `diretoria` | Diretoria | — |
| `equipe-do-corlix-hub` | Equipe do Corlix Hub | — |
| `gestor` | Gestor | "Lidera equipe. Aparece na lista de gestores da P14." |
| `publicador-de-conteúdo` | Publicador de Conteúdo | — (static id com acento) |
| `suporte-ti` | Suporte TI | "Equipe de TI. Atende chamados e mantém o status dos sistemas e os artigos." **(nova)** |

Atribuição: na P14, `pkg_perfis_acesso.atribuir_papeis` dá `colaborador` a todos e os papéis do cargo (`CARGO_PAPEL`, `modulos/perfis-acesso/`). `equipe-do-corlix-hub` e ajustes pontuais continuam manuais em *Shared Components > Application Access Control*.

### 2.2 Authorizations (`authorizations.apx`) — todas `evaluationType: perSession`
`perSession` = resultado em cache na sessão: depois de mudar o papel de alguém, a pessoa precisa de **novo login**. O nome (coluna 2) é o que se usa em `apex_authorization.is_authorized('<NOME>')`; o static id (coluna 1) é o que aparece no `.apx` (`authorizationScheme: @<static id>`).

| Static ID (`@...`) | Nome | Tipo | Regra | Mensagem |
|---|---|---|---|---|
| `admin-rh` | `ADMIN_RH` | isInRoleOrGroup | role `Admin RH` | "Acesso restrito ao RH." |
| `administration-rights` | `EQUIPE_CORLIX_HUB` (antes "Equipe Corlix Hub") | isInRoleOrGroup | role `Equipe do Corlix Hub` | "Acesso restrito à equipe do Corlix Hub." |
| `aprovador-ponto` | `APROVADOR_PONTO` **(nova)** | plSqlFunctionBody | `pkg_ponto.fn_e_aprovador = 'S'`; erro `-20012` (sem empresa) → `false` | "Acesso restrito à gestão direta e ao RH." |
| `colaborador` | `COLABORADOR` | plSqlFunctionBody | `ADMIN_RH` **ou** existe `COLABORADOR` com `upper(login_apex) = upper(:APP_USER)` e `id_empresa = :G_ID_EMPRESA` | "Sua conta não está vinculada a um colaborador desta empresa." |
| `gestor` | `GESTOR` | plSqlFunctionBody | o usuário é `id_gestor` de alguém na mesma `:G_ID_EMPRESA` | "Acesso restrito a gestores." |
| `publicador-de-conteudo` | `PUBLICADOR_DE_CONTEUDO` | isInRoleOrGroup | role `Publicador de Conteúdo` | "Acesso restrito a publicadores de conteúdo." |
| `somente-diretoria` | `SOMENTE_DIRETORIA` | isInRoleOrGroup | role `Diretoria` | "Acesso restrito à Diretoria." |
| `suporte-ti` | `SUPORTE_TI` **(nova)** | isInRoleOrGroup | role `Suporte TI` | "Acesso restrito à equipe de TI." |
| `ver-foto-colaborador` | `VER_FOTO_COLABORADOR` **(nova)** | plSqlFunctionBody | `COLABORADOR` ou `EQUIPE_CORLIX_HUB` | "Acesso restrito." |
| `ver-lista-colaboradores` | `VER_LISTA_COLABORADORES` **(nova)** | plSqlFunctionBody | `ADMIN_RH` ou `EQUIPE_CORLIX_HUB` ou `SOMENTE_DIRETORIA` ou `GESTOR` ou role ACL `gestor` (`apex_acl.has_user_role`) | "Acesso restrito ao RH e à liderança." |

Compor esquemas novos só com `apex_authorization.is_authorized` sobre os existentes (regra S3 do 11), como fazem `VER_FOTO_COLABORADOR` e `VER_LISTA_COLABORADORES`.

### 2.3 Quem usa cada authorization (uso real no backup)
A pegadinha de 06/10 ("nenhuma página tem `authorizationScheme`") **não vale mais**: 31 páginas têm esquema próprio.

| Authorization | Nível de página | Componentes (região/botão/item/processo) | Entrada do menu |
|---|---|---|---|
| `ADMIN_RH` | 7, 14, 18, 19, 20, 21, 23 | 12, 13, 14, 18, 19, 21 | Cadastro de usuários, Dashboard RH, Monitor de logs |
| `EQUIPE_CORLIX_HUB` | 15, 16 | — | Empresas |
| `APROVADOR_PONTO` | 32, 33 | — | Ajustes de ponto |
| `COLABORADOR` | 2, 9, 13, 22, 30, 31, 34, 35, 36, 37 | 1 | Ponto eletrônico, Histórico de carreira, Holerite |
| `SUPORTE_TI` | 38, 39, 40, 41, 42, 43 | — | — (Suporte TI não está no menu) |
| `VER_FOTO_COLABORADOR` | 44 | — | — |
| `VER_LISTA_COLABORADORES` | 12 | — | Colaboradores |
| `PUBLICADOR_DE_CONTEUDO` | — | 1 (botão que abre a p17) | — |
| `GESTOR` | — | — | — (só dentro de `VER_LISTA_COLABORADORES` e de packages) |
| `SOMENTE_DIRETORIA` | — | — | — (só dentro de `VER_LISTA_COLABORADORES`) |

**Páginas sem authorization própria:** 1, 3, 4, 5, 6, 8, 11, 17, 26, 27, 29 (e 0/9999, que não precisam). Atenção à **p17** (Novo comunicado, modal): só o botão da p1 é protegido por `PUBLICADOR_DE_CONTEUDO`; pela URL qualquer usuário logado abre o diálogo. A **Central de equipes** (p26/p27) fica no grupo Administração sem esquema nenhum.

**Page Access Protection:** todas as páginas com `argumentsMustHaveChecksum`, exceto p0 (global), **p29 Busca** (recebe o termo pela URL, exceção prevista na regra S2 do 11) e **p44 Foto** (sem atributo = `unrestricted`; a URL é montada com `apex_page.get_url` — justificativa não registrada no export).

---

## 3. Application Items e Application Processes

### 3.1 Items (`app-items.apx`) — todos `p_protection_level=>'I'` (Restricted)
| Item | Populado por | Usado em |
|---|---|---|
| `APP_USER_CARGO` | processo `APP_USER_CARGO` | **nenhuma página** desde a troca do cabeçalho (o processo continua rodando em toda página) |
| `APP_USER_FOTO` | processo `APP_USER_FOTO` | p0 (`<img src="&APP_USER_FOTO!ATTR.">`). Agora é URL da **p44** (`apex_page.get_url(p_page => 44, p_x01 => <arquivo>)`), não mais caminho de `#APP_FILES#` |
| `APP_USER_INICIAIS` | processo `APP_USER_FOTO` | p0 (avatar sem foto) |
| `APP_USER_NOME` | **ninguém** | **ninguém** (órfão) |
| `G_ID_EMPRESA` **(novo)** | processo `SET_G_ID_EMPRESA` (pós-login) | autorizações `COLABORADOR`/`GESTOR`, LOVs `LOV_*`, páginas 1, 13, 14, 17–23, 31–33, 35, 38–41 e packages (`v('G_ID_EMPRESA')`) |
| `G_NOME_EMPRESA` | processo `G_NOME_EMPRESA` | p0 (menu do usuário) |
| `G_NOME_USUARIO` | processo `G_NOME_USUARIO` | p0; `pkg_home_ui` (`v('G_NOME_USUARIO')`) |

### 3.2 Processes (`app-processes.apx`)
Todos `executeCode`, `sequence: 1`, **sem condição**. Pontos conferidos no `f100.sql`:

| Processo | Ponto | O que faz |
|---|---|---|
| `APP_USER_CARGO` | `BEFORE_HEADER` (toda página, inclusive login) | `CARGO.nome` do colaborador; `NO_DATA_FOUND` → `'SEM VÍNCULO'`, `TOO_MANY_ROWS` → `'MÚLTIPLOS VÍNCULOS'`, `OTHERS` → `'ERRO AO CARREGAR CARGO'` |
| `APP_USER_FOTO` | `BEFORE_HEADER` | Foto: nula se `foto_url` vazio ou igual ao legado `'#APP_FILES#Fotos Colaboradores/'`; senão `apex_page.get_url(p_page => 44, p_x01 => regexp_substr(trim(foto_url), '[^/]+$'))`. Iniciais: 1ª letra de `primeiro_nome` (ou `nome_completo`) + 1ª de `ultimo_nome` (ou último nome de `nome_completo`). Erro → foto nula e iniciais = 1ª letra de `:APP_USER` |
| `G_NOME_EMPRESA` | `BEFORE_HEADER` | `EMPRESA.nome`; `'sem empresa vinculada'` / `'mais de uma empresa vinculada'` / `'empresa indisponível'` + `log_pkg.erro(SQLERRM, 'G_NOME_EMPRESA')`. Não expõe mais `SQLERRM` na tela |
| `G_NOME_USUARIO` | `BEFORE_HEADER` | `initcap(first_name || ' ' || last_name)` de `apex_workspace_apex_users`; `no_data_found` → `:APP_USER` |
| `SET_G_ID_EMPRESA` **(novo)** | `AFTER_LOGIN` (`point: afterAuthentication`) | `COLABORADOR.id_empresa` do usuário; `no_data_found`/`too_many_rows` → nulo |

Vínculo usuário APEX ↔ colaborador: `UPPER(TRIM(COLABORADOR.login_apex)) = UPPER(TRIM(:APP_USER))` (as autorizações usam `upper` sem `trim`).

Pegadinhas:
- `G_ID_EMPRESA` só é preenchido **no login**: sessão aberta antes de vincular o colaborador fica sem empresa até sair e entrar.
- `G_NOME_USUARIO` vem do cadastro de usuários do workspace, não de `COLABORADOR.nome_completo`.
- Os quatro processos `BEFORE_HEADER` rodam em toda página (inclusive no login, com `:APP_USER = 'nobody'`). `APP_USER_CARGO` hoje não alimenta nada.

---

## 4. Lists (`lists.apx`)

### 4.1 `navigation-menu` — menu lateral (estado do backup)
Reorganizado pelo `modulos/tema/Etapas-header-e-menu.md`: grupos **Pessoas**, **Minha carreira** e **Administração**; as entradas "Sair", "Emitir Comunicado" e "Solicitar correção" saíram (Sair está no menu do usuário da p0; o novo comunicado abre por botão na p1). Ícones `fa-*` (Font APEX, remapeados para Lucide pelo `corlix-tema.css`, ver 04).

| Seq | Static ID | Label | Ícone | Destino | Current também em | Authorization |
|---|---|---|---|---|---|---|
| 10 | `início` | Início | `fa-home` | p1 | 1 | — |
| 20 | `comunicação` | Comunicados | `fa-bullhorn` | p11 | 11 | — |
| 30 | `chat` | Chat | `fa-comments-o` | p4 | 4 | — |
| 35 | `ponto-eletrônico` | Ponto eletrônico | `fa-clock-o` | p30 | (padrão) | `@colaborador` |
| 40 | `pessoas` | **Pessoas** (grupo, sem link) | `fa-users` | — | | — |
| 41 | ↳ `colaboradores` | Colaboradores | — | p12 | (padrão) | `@ver-lista-colaboradores` |
| 42 | ↳ `organograma` | Organograma | — | p3 | (padrão) | — |
| 50 | `minha-carreira` | **Minha carreira** (grupo) | `fa-briefcase` | — | | — |
| 51 | ↳ `meu-perfil` | Meu perfil | — | p2 | (padrão) | — (a página exige `COLABORADOR`) |
| 52 | ↳ `histórico-de-carreira` | Histórico de carreira | — | p13 | (padrão) | `@colaborador` |
| 53 | ↳ `holerite` | Holerite | — | p9 | (padrão) | `@colaborador` |
| 60 | `administração` | **Administração** (grupo) | `fa-shield` | — | | — |
| 61 | ↳ `empresas-cadastradas` | Empresas | — | p15 | 15, 16 | `@administration-rights` |
| 62 | ↳ `cadastros` | Cadastro de usuários | — | p14 | 14 | `@admin-rh` |
| 63 | ↳ `dashboard-rh` | Dashboard RH | — | p20 | 20 | `@admin-rh` |
| 64 | ↳ `central-de-equipes` | Central de equipes | — | p26 | 26, 27 | — |
| 65 | ↳ `terminal` | Monitor de logs | — | p7 | 7 | `@admin-rh` |
| 66 | ↳ `configurações` | Configurações | — | p6 | (padrão) | — |
| 67 | ↳ `ajustes-de-ponto` | Ajustes de ponto | — | p32 | (padrão) | `@aprovador-ponto` |

"(padrão)" = sem `isCurrent` no export; o APEX marca como atual quando a página é o destino.
Fora do menu: p5/p8 (notificações; o sino aponta para a 5), p17 (modal), p18–23 (modais e páginas do histórico), p29 (Busca, pelo header), p31/p33 (modais do ponto), **p34–43 (Suporte TI: nenhuma entrada no menu)**, p44 (Foto), p9999.
Os grupos (Pessoas, Minha carreira, Administração) não têm authorization; se o usuário não puder ver nenhum filho, não foi conferido se o UT esconde o grupo vazio.

### 4.2 `emitir-comunicado` — lista de wizard (sem uso)
Entradas `Step 1` → p17, `Step 2` → p18, `Step 3` → p19. **Nenhuma página referencia** (a p17 usa `@/modal-dialog`, não wizard). As páginas 18 e 19 são do histórico de carreira. Pode ser apagada pelo time.

---

## 5. Breadcrumbs (`breadcrumbs.apx`)
Um único breadcrumb `breadcrumb`, **plano** (todas as entradas com `sequence: 10`, nenhuma `parentEntry`).

| Entry | Nome | Página |
|---|---|---|
| `meu-perfil` | Meu Perfil | 2 |
| `organograma` | Organograma | 3 |
| `notificações` | Notificações | 5 |
| `configurações` | Configurações | 6 |
| `terminal` | Monitor de Logs | 7 |
| `holerite-digital` | Holerite Digital | 9 **(nova)** |
| `comunicação` | Comunicação | 11 (no menu: "Comunicados") |
| `colaboradores` | Colaboradores | 12 |
| `histórico-de-carreira` | Histórico de carreira | 13 |
| `cadastros` | Cadastro de Usuários | 14 |
| `empresas-cadastradas` | Empresas Cadastradas | 15 |
| `dashboard-rh` | Dashboard RH | 20 **(nova)** |
| `central-de-equipes` | Central de Equipes | 26 |
| `status-dos-sistemas` | Status dos sistemas | 40 **(nova)** |
| `artigos` | Artigos | 42 **(nova)** |

A entry `home` (p1) **saiu**.
Páginas com região Breadcrumb (`breadcrumb: @breadcrumb`, template `@/title-bar`, opção `t-BreadcrumbRegion--useBreadcrumbTitle`, slot `breadcrumbBar`): **3, 5, 6, 7, 11, 26, 40, 42**.
Entries sem região Breadcrumb: 2, 9, 12, 13, 14, 15, 20 — essas páginas usam o cabeçalho próprio `cx-cabecalho-pagina` (Dynamic Content com `render_cabecalho`, regra E3 do 11) ou HTML na região.

---

## 6. LOVs (`lovs.apx`)
| Static ID | Nome | Tipo | Retorno / Exibição | Filtra empresa? | Usada em |
|---|---|---|---|---|---|
| `boolean` | `BOOLEAN` | estática | `TRUE`→"Yes", `FALSE`→"No" (rótulos em inglês) | — | 26 |
| `colaborador-nome-completo` | `COLABORADOR.NOME_COMPLETO` | tabela | `ID_COLABORADOR` / `NOME_COMPLETO` | **não** | 26, 27 |
| `departamento-nome` | `DEPARTAMENTO.NOME` | tabela | `ID_DEPARTAMENTO` / `NOME` | **não** | 26, 27 |
| `empresa-nome` | `EMPRESA.NOME` | tabela | `ID_EMPRESA` / `NOME` | **não** | 26, 27, 42, 43 |
| `lov-categoria-comunicado` | `LOV_CATEGORIA_COMUNICADO` **(nova)** | SQL | `id_categoria` / `nm_categoria`, só `fl_ativo = true`, ordem `nr_ordem` | sim (`:G_ID_EMPRESA`) | 17 |
| `lov-colaborador-ativo` | `LOV_COLABORADOR_ATIVO` **(nova)** | SQL | `id_colaborador` / `nome_completo`, `status = true` | sim | 18 |
| `lov-departamento-empresa` | `LOV_DEPARTAMENTO_EMPRESA` **(nova)** | SQL | `id_departamento` / `nome` | sim | 17, 18 |
| `lov-tipo-formacao` | `LOV_TIPO_FORMACAO` **(nova)** | estática | `GRADUACAO`, `POS`, `MBA`, `CURSO`, `CERTIFICACAO`, `IDIOMA` (rótulos pt-BR) | — | 19, 20, 21 |
| `lov-tipo-movimentacao` | `LOV_TIPO_MOVIMENTACAO` **(nova)** | SQL | `id_tipo_movimentacao` / `ds_tipo`, `fl_ativo = true`, ordem `nr_ordem` | sim | 18 |
| `suporte-assunto-nm-assunto` | `SUPORTE_ASSUNTO.NM_ASSUNTO` **(nova)** | tabela | `ID_ASSUNTO` / `NM_ASSUNTO` | **não** | 42, 43 |

Para LOV nova, siga o padrão `LOV_*` (SQL com `where id_empresa = :G_ID_EMPRESA`, colunas `d`/`r`). As LOVs de tabela (geradas pelo assistente) mostram dados de todas as empresas.

---

## 7. Text messages (`messages.apx`) **(nova seção)**
Traduções pt-BR de mensagens internas do APEX. Ficam com `language: en` porque o idioma primário técnico da app é `en`: é assim que sobrescrevem o texto padrão.

| Mensagem | Texto | Onde aparece |
|---|---|---|
| `APEX.FS.CLEAR` (usada em JS) | Limpar | Faceted Search (p12) |
| `APEX.FS.CLEAR_ALL` | Limpar filtros | Faceted Search |
| `APEX.FS.SHOW_LESS` / `APEX.FS.SHOW_MORE` | Mostrar menos / Mostrar mais | Faceted Search |
| `APEX.FS.TOTAL_ROW_COUNT_LABEL` | Total de colaboradores | Faceted Search — **vale para todo Faceted Search da app**, não só a p12 |
| `PAGINATION.NEXT` / `PREVIOUS` / `NEXT_SET` / `PREVIOUS_SET` | Próxima / Anterior / Próximo conjunto / Conjunto anterior | Paginação de relatórios |
| `WWV_RENDER_REPORT3.X_Y_OF_Z`, `X_Y_OF_Z_2` | `%0–%1 de %2` | Contador de linhas do Classic Report |
| `WWV_RENDER_REPORT3.X_Y_OF_MORE_THAN_Z` | `%0–%1 de mais de %2` | idem |

---

## 8. Component Settings e Build Options
- `component-settings.apx` (sem mudança desde 06/10): **Checkbox** `uncheckedValue: N`; **Switch** `onValue: Y`; **Date Picker** com `monthPicker`, `yearPicker`, `showTodayButton`; **Star Rating** tooltip `#VALUE#`; **Geocoded Address** `mapPreview: [resultsPopup, item]`. Demais (`showAiAssistant`, `colorPicker`, `selectMany`, `serverSideGeocoding`, `regionDisplaySelector`, `interactiveReport`, `map`, REST Oracle Cloud Apps) nos defaults. Colunas `BOOLEAN` do banco × switch/checkbox que gravam `Y`/`N`: converta no processo.
- `build-options.apx`: só `commented-out` ("Commented Out"). Uso: o processo Ajax `ORG_DETALHES` da p3 tem `buildOption: !@commented-out` ("{Not Commented Out}", ou seja, sempre incluído).
- `page-groups.apx`: grupo `administration` sem uso (§1.1).

---

## 9. Templates

O tema é o **Universal Theme 42** (`ut-26.1`, estilo Redwood Light). Os templates com `@/` (barra) são os **embutidos do UT 26.1**: não aparecem em `corlixhub/shared-components/themes/` nem no `f100.sql` (só o template customizado de página está lá). Por isso, os slots listados para eles abaixo são os **observados nas páginas** do backup, não a lista completa do template. Os templates sem barra (`@corlix-standard-page`, `@chat-contatos`…) são customizados e estão versionados em `themes/universal-theme/`.

> A pasta `themes/` só tem `universal-theme/`. `icons/`, `modulos/` e `ponto-eletronico/` são **subpastas de static files** (`shared-components/static-files/`), não temas (§10).

### 9.1 Defaults do tema (`themes/universal-theme/theme.apx`)
| Componente | Default |
|---|---|
| Página | **`@corlix-standard-page`** (página nova nasce com o template custom) |
| Login / erro | `@/login` |
| Modal | `@/modal-dialog`; região de conteúdo `@/blank-with-attributes`; região de botões `@/buttons-container` |
| Região / Classic Report / Form / Chart / List / Wizard | `@/standard` |
| Interactive Report | `@/interactive-report` |
| Breadcrumb (região) | `@/title-bar`; breadcrumb `@/breadcrumb` |
| Label | `@/optional-floating` (opcional/default), `@/required-floating` (obrigatório) |
| Botão | `@/text` |
| Lista | `@/links-list`; menu lateral `@/side-navigation-menu`; navbar `@/navigation-bar` |

JS do tema: `widget.stickyWidget` + `theme42#MIN#.js`; CSS: `Core#MIN#.css`; ícones `fontApex`; `filePrefix: #APEX_FILES#themes/theme_42/26.1/`.
`themes/universal-theme/static-files/10245258954911381.css` e `10246955817960493.css`: 65 bytes cada, só o comentário de copyright da Oracle (sobras de Theme Roller). Inócuos.

### 9.2 Page templates

| Template | Builder | Páginas | Observação |
|---|---|---|---|
| `@corlix-standard-page` | Corlix - Standard Page | **17**: 1, 4, 5, 6, 7, 9, 19, 26, 29, 30, 32, 34, 37, 38, 40, 42, 44 | **Padrão (regra E1).** Customizado, ver 9.2.1 |
| `@/standard` | Standard | **9**: 2, 3, 8, 11, 12, 13, 14, 15, 20 | Divergência conhecida (11 §6): não copie, não troque de passagem |
| `@/modal-dialog` (`dialogTemplate`) | Modal Dialog | **14**: 16, 17, 18, 21, 22, 23, 27, 31, 33, 35, 36, 39, 41, 43 | `pageMode: modalDialog`. Larguras explícitas: p16 `width: 1000`, p17 `width: 680`; demais no padrão. `chained: false` em 16, 21, 27 |
| `@/login` | Login | 9999 | |
| `wizard-modal-dialog` | Wizard Modal Dialog | **nenhuma** | A p17 deixou de usar (estado de 06/10) |

Todas com `templateOptions: #DEFAULT#`.

Slots de página observados:
- Página normal: `breadcrumbBar` (cabeçalho), `body`, `dialogsDrawersAndPopups` (p1, p30); p0 usa `afterLogo` e `afterNavigationBar`.
- Modal: `contentBody` (formulário/conteúdo) e `dialogFooter` (botões).
- Login: `contentBody`.

#### 9.2.1 `corlix-standard-page` ("Corlix - Standard Page", `templateClass: oneLevelTabs`)
Arquivo `themes/universal-theme/page-templates/corlix-standard-page.apx` (também no `f100.sql`, `p_name=>'Corlix - Standard Page'`). É um template de página **sem colunas laterais** no molde do Standard do UT. Não dá para comparar linha a linha com o Standard 26.1 embutido (ele não está no repositório): diferenças em relação ao UT, além das listadas, **não confirmadas**.
- `<html class="... page-&APP_PAGE_ID!ATTR. app-&APP_ALIAS!ATTR.">` → CSS por página com `.page-30 ...`.
- `<body class="t-PageBody t-PageBody--hideLeft t-PageBody--hideActions no-anim t-PageTemplate--standard #PAGE_CSS_CLASSES#">`; JS on load `apex.theme42.initializePage.noSideCol();`.
- Header `t-Header`: `#REGION_POSITION_07#`, botão do menu `#t_Button_navControl`, `#LOGO#` + `#AFTER_LOGO#`, navbar `#BEFORE_NAVIGATION_BAR#` / `#NAVIGATION_BAR#` / `#AFTER_NAVIGATION_BAR#`.
- Body: `#SIDE_GLOBAL_NAVIGATION_LIST#`, `t-Body-title` = `#REGION_POSITION_01#`, mensagens, `t-Body-fullContent` = `#REGION_POSITION_08#`, `t-Body-contentInner` = `#BODY#`, footer `#REGION_POSITION_05#`, inline dialogs `#REGION_POSITION_04#`.

| Slot (APEXlang) | Nome no Builder | Posição | Aceita | Grid |
|---|---|---|---|---|
| `afterLogo` | After Logo | `AFTER_LOGO` | itens, botões | sem grid, máx. 4 |
| `beforeNavigationBar` | Before Navigation Bar | `BEFORE_NAVIGATION_BAR` | itens, botões | sem grid, máx. 4 |
| `afterNavigationBar` | After Navigation Bar | `AFTER_NAVIGATION_BAR` | itens, botões | sem grid, máx. 4 |
| `banner` | Banner | `REGION_POSITION_07` | | sem grid |
| `breadcrumbBar` | Breadcrumb Bar | `REGION_POSITION_01` | | sem grid (posição do breadcrumb) |
| `body` | Body | `BODY` | itens, botões | 12 colunas |
| `fullWidthContent` | Full Width Content | `REGION_POSITION_08` | | 12 colunas |
| `footer` | Footer | `REGION_POSITION_05` | itens, botões | 12 colunas |
| `dialogsDrawersAndPopups` | Dialogs, Drawers and Popups | `REGION_POSITION_04` | | 12 colunas |
| `topNavigation` | Top Navigation | `REGION_POSITION_06` | | **não renderiza**: não há `#REGION_POSITION_06#` no HTML |

- **Não há** Left/Right Column (`REGION_POSITION_02/03`): use colunas de layout com regiões `Blank with Attributes` (regra E7).
- Template option própria: `js-pageStickyMobileHeader` (Sticky Header on Mobile), não usada.
- Grid: 12 colunas, `alwaysUseMaxColumns: true`, classes `container`/`row`/`col col-N`. Subtemplate de navbar com `&APP_USER.` fixo; error page com `#MESSAGE#`, `#ADDITIONAL_INFO#`, `#TECHNICAL_INFO#`, `#OK#`.

### 9.3 Region templates

| Template | Builder | Uso típico no projeto | Páginas | Template options usadas |
|---|---|---|---|---|
| `@/blank-with-attributes` | Blank with Attributes | Dynamic Content do `render_*` (corpo, E5), contêiner de colunas (E7), conteúdo de modal | 1, 2, 3, 4, 9, 12, 13, 16, 17, 21, 27, 30, 34, 36, 37, 39, 41, 43 | só `#DEFAULT#` |
| `@/blank-with-attributes-no-grid` | Blank with Attributes (No Grid) | **Cabeçalho `cx-cabecalho-pagina` no `breadcrumbBar` (E3)** e corpos sem grid | 9, 12, 13, 14, 15, 19, 20, 29, 30, 32, 34, 37, 38 | só `#DEFAULT#` |
| `@/standard` | Standard | Formulários nativos, Classic Report, Chart, Cards, Faceted Search, regiões da p0 | 0, 1, 12, 14, 16, 18, 20, 23, 26, 34, 39 | ver abaixo |
| `@/buttons-container` | Buttons Container | Botões do modal no `dialogFooter` (E2) | 14, 16, 17, 18, 21, 22, 23, 27, 31, 33, 35, 36, 41, 43 | só `#DEFAULT#` |
| `@/inline-dialog` | Inline Dialog | Diálogo na própria página, slot `dialogsDrawersAndPopups` (E6) | 1 (Celebrações, Dar feedback), 30 (4 diálogos do ponto) | `js-dialog-autoheight` + tamanho: `js-dialog-size480x320` (p1 Celebrações), `js-dialog-size600x400` (p1 Dar feedback), `js-dialog-size720x480` (p30) |
| `@/interactive-report` | Interactive Report | Relatórios de trabalho | 7, 15, 19, 32, 38, 40, 42 | `t-IRR-region--hideHeader js-addHiddenHeadingRoleDesc` (cabeçalho oculto, acessível) em todas |
| `@/title-bar` | Title Bar | Região Breadcrumb no `breadcrumbBar` | 3, 5, 6, 7, 11, 26, 40, 42 | `t-BreadcrumbRegion--useBreadcrumbTitle` em todas |
| `@/tabs-container` | Tabs Container | Abas | 7 | `t-TabsRegion-mod--simple`, `js-useLocalStorage` (lembra a aba) |
| `@/collapsible` | Collapsible | IR recolhível | 13 | `is-collapsed`, `t-Region--scrollBody` |
| `@/login` | Login | Região do login | 9999 | `#DEFAULT#` |
| `@chat-contatos`, `@chat-mensagens` | (Classic Report templates custom, §9.6) | Chat | 4 | `#DEFAULT#` |
| `@cards-container-image-first` | Cards Container - Image First (custom) | **nenhuma** (a Home usa Cards com `@/standard`) | — | — |

Template options de `@/standard` observadas:
| Opção | Significado (UT) | Páginas |
|---|---|---|
| `t-Region--removeHeader js-removeLandmark` | Header: Hidden (sem cabeçalho nem landmark) | 0, 12, 14, 16 |
| `t-Region--hideHeader js-addHiddenHeadingRoleDesc` | Header: Hidden but accessible | 20 |
| `t-Region--noUI` | Style: Remove UI Decoration | 0, 12, 14, 16 |
| `t-Region--scrollBody` | Body Overflow: Scroll (default do UT) | 0, 1, 12, 14, 18, 20, 23, 34, 39 |
| `t-Region--hiddenOverflow` | Body Overflow: Hide | 16 |
| `t-Region--noPadding` | Body Padding: No Body Padding | 1, 12, 26 |
| `t-Report--altRowsDefault`, `t-Report--rowHighlight`, `t-Report--stretch`, `t-Report--inline`, `t-Report--staticRowColors`, `t-Report--hideNoPagination` | Opções do report template Standard de Classic Report (linhas alternadas, destaque, largura total…) | 12, 20, 26 |

Slots de região observados (filhos dentro da região):
- `@/blank-with-attributes`: `regionBody` (itens, sub-regiões), `subRegions` (colunas de layout em 1, 4, 12, 30, 34).
- `@/blank-with-attributes-no-grid`: `regionBody` (itens e botões).
- `@/standard`: `regionBody`, `subRegions`, botões em `edit` (1, 14, 26), `copy` (1) e `regionBody` (39).
- `@/buttons-container`: botões em `close` (Cancelar/Fechar), `delete` (Excluir), `next` (ação principal, `hot: true`) e `regionBody` (36).
- `@/inline-dialog`: itens em `regionBody`; botões em `close` e `create`.
- `@/interactive-report`: botões em `rightOfInteractiveReportSearchBar` (19, 40, 42).
- `@/tabs-container`: sub-regiões em `tabs` (7).
- `@/login`: itens em `regionBody`, botão em `next`.

Combinação por tipo de região no backup: Dynamic Content usa `@/blank-with-attributes` (19), `@/standard` (9), `@/blank-with-attributes-no-grid` (9) ou `@/inline-dialog` (5); Static Content usa `@/buttons-container` (14), `@/standard` (11), `@/blank-with-attributes` (11), No Grid (7); Form usa `@/blank-with-attributes` (6, modais) ou `@/standard` (2); IR usa `@/interactive-report` (9), `@/standard` (1) e `@/collapsible` (1); Chart, Cards e Faceted Search usam `@/standard`.

### 9.4 Item templates
| Template | Builder | Uso | Páginas |
|---|---|---|---|
| `@/required-floating` | Required - Floating | Campo obrigatório (rótulo dentro do campo, sobe ao preencher). **Padrão de formulário** | 1, 14, 16, 17, 18, 20, 21, 22, 23, 27, 31, 35, 41, 43 (61 itens) |
| `@/optional-floating` | Optional - Floating | Campo opcional e itens auxiliares de páginas personalizadas | 1, 3, 12, 13, 14, 16, 17, 18, 21, 22, 23, 27, 31, 33, 35, 36, 39, 41, 43 (55 itens) |
| `@/optional-above` | Optional - Above | Rótulo acima (casos pontuais de cadastro) | 14, 16 (3 itens) |
| `@/hidden` | Hidden | Label template sem rótulo visível | 9999 (usuário, senha e "Remember username", 3 itens) |

Itens do tipo `hidden` (há vários, por exemplo em 1, 4, 7, 15 e 17) não declaram template. Todos com `templateOptions: #DEFAULT#`. Referência de formulário: p31 (`required-floating` nos obrigatórios, `optional-floating` nos opcionais, `inlineHelpText` para orientar).

### 9.5 Button templates
| Template | Builder | Páginas | Template options usadas |
|---|---|---|---|
| `@/text` | Text | 1, 13, 14, 16, 17, 18, 19, 21, 22, 23, 26, 27, 31, 33, 35, 36, 39, 40, 41, 42, 43, 9999 (56 botões) | `#DEFAULT#`; `t-Button--danger` (Excluir em 16 e 18); ação principal com `hot: true` |
| `@/text-with-icon` | Text with Icon | 1 (2 botões) | `t-Button--iconLeft`, `t-Button--iconRight`, `t-Button--noUI` |
| `@html-button-legacy-apex-5-migration` | HTML button (legacy - APEX 5 migration), `custom8` | **nenhuma** | `<input type="button" ...>` legado |

Botões em HTML gerado por `pkg_<m>_ui` não usam button template: usam classes do tema e SVG Lucide (regras de ícones do 11).

### 9.6 Classic report templates custom (`custom1`, named column) — só no Chat (p4)
A query deve devolver exatamente as colunas citadas; colunas com HTML precisam de `escapeSpecialChars: false`. O CSS `.ch-*` está inline na p4 (divergência da regra C1).

**`chat-contatos`** — wrapper `<div class="ch-contacts">`; linha:
```html
#CAB_DEPT#
<a href="javascript:void(0)" class="ch-contact" data-id="#ID_COLABORADOR#">
  <span class="ch-avatar-wrap">
    <span class="ch-avatar" aria-hidden="true">#INICIAIS#<img src="#FOTO_URL#" alt="" loading="lazy" onerror="this.remove()"></span>
    <i class="ch-dot ch-dot--#PRESENCA#"></i>
  </span>
  <span class="ch-contact-txt"><b>#NOME_COMPLETO#</b><small>#CARGO#</small></span>
</a>
```
Colunas: `CAB_DEPT` (HTML do cabeçalho de departamento na 1ª linha do grupo), `ID_COLABORADOR`, `FOTO_URL` (**URL completa da p44** via `apex_page.get_url`; o template não prefixa mais `#APP_FILES#`), `INICIAIS`, `PRESENCA` ∈ `online|ausente|offline`, `NOME_COMPLETO`, `CARGO`.

**`chat-mensagens`** — wrapper `<div class="ch-msgs">`; linha `#SEP_DIA#` + `<div class="ch-msg ch-msg--#LADO#" data-id="#ID_MSG#">` com `#CORPO#` e `#HORA#`. Coluna nova: `ID_MSG`. `LADO` ∈ `out|in`.

### 9.7 Region template custom `cards-container-image-first` (`custom1`) — sem uso
Cópia do Cards Container do UT (`t-CardsRegion`), slots `regionBody`, `sortOrder`, `subRegions`; opções `u-colors`, cabeçalho oculto, `t-CardsRegion--styleA|B|C`. Em 06/10 era usado na Home; no backup **nenhuma página** o referencia.

### 9.8 Qual template usar para quê (coerente com o 11)
| Necessidade | Página | Região | Itens / botões | Referência |
|---|---|---|---|---|
| Página normal | `@corlix-standard-page` | — | — | E1; p9, p30 |
| Cabeçalho da página (`render_cabecalho`) | — | Dynamic Content, `@/blank-with-attributes-no-grid`, slot `breadcrumbBar` | ações dentro do HTML do package | E3/E4; p9, p30, p32 |
| Corpo personalizado (`render_*`) | — | Dynamic Content, `@/blank-with-attributes` (ou No Grid), slot `body` | — | E5; p9, p30 |
| Colunas de layout | — | Static Content `@/blank-with-attributes` com sub-regiões (`subRegions`) | — | E7; p30, p34 |
| Diálogo na própria página | — | `@/inline-dialog`, slot `dialogsDrawersAndPopups`, `js-dialog-autoheight` + `js-dialog-sizeWxH`; **preencha `htmlDomId`** para abrir por JS | botões `close`/`create` | E6; p30 |
| Modal com formulário | `pageMode: modalDialog`, `@/modal-dialog` | conteúdo em `contentBody` (Form em `@/blank-with-attributes` ou itens direto); botões em Static Content `@/buttons-container`, slot `dialogFooter` | `@/required-floating` / `@/optional-floating`; botões `@/text` em `close` (Cancelar → DA `cancelDialog`) e `next` (`hot`), Excluir em `delete` com `t-Button--danger` | E2; p31 |
| Relatório operacional | `@corlix-standard-page` | IR `@/interactive-report` + `t-IRR-region--hideHeader js-addHiddenHeadingRoleDesc` | botão de ação em `rightOfInteractiveReportSearchBar` | p32, p19 |
| Lista com facetas | — | Faceted Search + Classic Report `@/standard` (com `t-Region--noUI`/`removeHeader`) | — | p12 (ainda não validada como referência, 11 §2) |
| Cartões simples de SQL | — | Cards nativo em `@/standard` | — | Comunicados da p1 |
| Breadcrumb nativo (páginas antigas) | — | `@/title-bar` + `t-BreadcrumbRegion--useBreadcrumbTitle` | — | Prefira o cabeçalho E3 em página nova |
| Abas | — | `@/tabs-container` + `t-TabsRegion-mod--simple` | — | p7 |

Antes de indicar um slot, confira que ele aparece no template (§9.2.1) ou num export que já o usa (regra G3 do 11).

---

## 10. Static Application Files (`static-files.apx` + `static-files/`)
37 arquivos registrados, todos `charSet: utf-8`. A pasta `Fotos Colaboradores/` (~291 fotos fictícias) **saiu** no backup de 05/11/2026 (`2964a9d`): as fotos agora são entregues pela **p44** (`pkg_arquivos.entregar_foto(apex_application.g_x01)`, autorização `VER_FOTO_COLABORADOR`; guia `modulos/arquivos/Etapas-fotos-object-storage.md`). Sem foto, use o avatar de iniciais (regra B2 do 11).

| Grupo | Arquivo(s) | Quem carrega |
|---|---|---|
| Tema | `corlix-tema.css` / `.min.css` | **Todas** (`application.apx > css.fileUrls`, 1º). Tokens `--cx-*`, `@font-face` Figtree e "Corlix Lucide" (ver 04) |
| Ajustes globais | `custom.css` / `.min.css` | **Todas** (`css.fileUrls`, 2º). Usa `url("home-hero.jpg")` |
| Fontes | `figtree-latin.woff2`, `figtree-latin-ext.woff2`, `lucide.woff2` | Por `url()` relativo em `corlix-tema.css` |
| Home | `modulos/home/home.css` / `.min.css` | p1. Usa `url("../../home-hero.jpg")` |
| Comunicados | `modulos/comunicados/comunicado.css` / `.min.css` | p17 |
| Colaboradores | `modulos/colaboradores/colaboradores.css` / `.min.css` | p12 |
| Suporte TI | `modulos/suporte-ti/suporte.css` / `.min.css` | p34, p36, p37, p39 |
| Holerite | `holerite.css` / `.min.css` (raiz) | p9 |
| Histórico de carreira | `historico-carreira.css` / `.min.css` (raiz) | p13, p19, p20 |
| Organograma | `organograma.css` / `.min.css` (raiz) | p3 |
| Ponto | `ponto-eletronico/ponto.css` / `.min.css` | p30, **sem `#MIN#`** (`#APP_FILES#ponto-eletronico/ponto.css`): o `.min` nunca é usado (divergência C3) |
| Perfil | `Meu Perfil.css` / `Meu Perfil.min.css` (nome com espaço) | p2 (`#APP_FILES#Meu Perfil#MIN#.css`) |
| Imagens | `home-hero.jpg` | `custom.css`, `home.css` |
| Imagens | `Comunicado · Confraternização.png`, `· Novembro Azul.png`, `· Resultados 3º tri.png`, `· Segurança da informação.png`, `· Trabalho híbrido.png` | Capas de comunicados de demonstração (`modulos/home/dados-demo/01_comunicados_demo.sql`); referenciadas por dado, não por página |
| Imagens | `icons/app-icon-32.png`, `-144-rounded`, `-192`, `-256-rounded`, `-512` | Ícones do app/PWA; p9999 usa `#APP_FILES#icons/app-icon-512.png` |
| Legado | `default-user.jpeg` | Nenhuma página; ainda citado em `modulos/tema/Etapas-tema-paginas.md` |

Regras:
- **Padrão para módulo novo (C3):** `modulos/<m>/<arquivo>.css` + `.min.css` registrados em `static-files.apx` e carregados na página por `#APP_FILES#modulos/<m>/<arquivo>#MIN#.css`. Os arquivos antigos na raiz (`holerite`, `historico-carreira`, `organograma`, `Meu Perfil`) e em `ponto-eletronico/` **não são movidos**.
- `#MIN#` vira `.min` fora do modo debug. **Não há minificação automática**: ao mudar o `.css`, o time atualiza o `.min.css` junto e reenvia os dois pelo Builder. A fonte editável fica em `modulos/<m>/`; a cópia em `corlixhub/shared-components/static-files/` é a que está no ambiente (chega pelo backup).
- CSS global só em `corlix-tema`/`custom`; CSS de página nunca inline (C1).

---

## 11. Objetos de banco que os shared components pressupõem
Nenhum DDL acompanha a app. O DDL atual está em `database/ddl/` (`03-tabelas.sql`, `08/09-plsql-*.sql`…); o antigo `database/corlix-hub.sql` não existe mais no repositório. Detalhes em `05`.

| Objeto | Usado por |
|---|---|
| `COLABORADOR` (`login_apex`, `id_empresa`, `id_cargo`, `id_gestor`, `foto_url`, `primeiro_nome`, `ultimo_nome`, `nome_completo`, `status`) | app processes, autorizações `COLABORADOR`/`GESTOR`, LOVs |
| `CARGO`, `EMPRESA`, `DEPARTAMENTO` | processos `APP_USER_CARGO`, `G_NOME_EMPRESA`; LOVs |
| `CATEGORIA_COMUNICADO`, `TIPO_MOVIMENTACAO`, `SUPORTE_ASSUNTO` | LOVs (§6) |
| `PRESENCA_COLABORADOR`, `CANAL_MENSAGEM` | templates do Chat (p4) |
| `APP_LOG`, `LOG_PKG` | error handler, `G_NOME_EMPRESA`, p7 |
| `PKG_PONTO.FN_E_APROVADOR` | autorização `APROVADOR_PONTO` |
| `PKG_ARQUIVOS.ENTREGAR_FOTO` | p44 (fotos) |
| `PKG_BUSCA_UI.RENDER_CAMPO` | p0 (busca do header) |
| `APEX_WORKSPACE_APEX_USERS` | `G_NOME_USUARIO` |

---

## 12. `log_pkg.apex_error_handler`
Fonte em `database/ddl/08-plsql-especificacoes.sql` / `09-plsql-corpos.sql`. `gravar` usa `pragma autonomous_transaction` e grava em `APP_LOG`; `erro`/`aviso`/`info` são atalhos. `apex_error_handler` registra origem, `ORA-`, backtrace e comando, e delega os erros -20001..-20099 a `pkg_historico_carreira.fn_tratar_erro`, que tira o "ORA-200xx" da mensagem (guia do histórico de carreira, §9.1). Detalhes em `05`.

---

## 13. Pegadinhas e inconsistências (resumo, backup 13/11/2026)
1. **Páginas sem authorization própria:** 1, 3, 4, 5, 6, 8, 11, 17, 26, 27 (29 é pública por desenho). A p17 (novo comunicado) só é protegida pelo botão da p1; Central de equipes (26/27) está em Administração sem esquema.
2. **Menu × página:** "Meu perfil" sem esquema no menu, página exige `COLABORADOR`. Suporte TI (34–43) existe e tem autorização, mas **não tem entrada no menu**.
3. **Autorizações sem uso direto:** `GESTOR` e `SOMENTE_DIRETORIA` só aparecem dentro de `VER_LISTA_COLABORADORES` (e em packages); `PUBLICADOR_DE_CONTEUDO` só num botão da p1.
4. **App items:** `APP_USER_NOME` órfão; `APP_USER_CARGO` sem uso, mas o processo roda em toda página. `G_ID_EMPRESA` só no login.
5. **p44 Foto** sem `pageAccessProtection` (= `unrestricted`); justificativa não registrada no export.
6. Lista `emitir-comunicado`, region template `cards-container-image-first`, button template legado e grupo de páginas `administration` não são usados.
7. Breadcrumb plano; entries 2, 9, 12, 13, 14, 15, 20 sem região Breadcrumb; nome "Comunicação" ≠ menu "Comunicados".
8. `corlix-standard-page`: slot `topNavigation` sem placeholder; sem colunas laterais. Nove páginas ainda usam `@/standard` (11 §6).
9. Static ids com acento (`publicador-de-conteúdo`, `comunicação`, `histórico-de-carreira`, `configurações`, `notificações`, `início`, `ponto-eletrônico`, `administração`); p5 e p8 duplicadas.
10. `ponto.css` carregado sem `#MIN#`; `Meu Perfil.css` com espaço no nome.
11. LOVs de tabela (`colaborador-nome-completo`, `departamento-nome`, `empresa-nome`, `suporte-assunto-nm-assunto`) não filtram por empresa. LOV `BOOLEAN` com "Yes/No".
12. `APEX.FS.TOTAL_ROW_COUNT_LABEL` = "Total de colaboradores" vale para qualquer Faceted Search futuro.
13. Comentários desatualizados: a SQL do Chat (p4) diz que o prefixo `#APP_FILES#` "fica no template", mas o template já usa a URL completa; a p29 e a p12 ainda tratam o caminho legado `Fotos Colaboradores/`.
14. Header da p0 com `style="display:none"` no fallback de iniciais (C1).

---

## 14. Histórico desta página
- **06/10/2026:** primeira versão (DEV `bac2d69` + mudanças não commitadas). Afirmações daquela data que **não valem mais**: "nenhuma página tem `authorizationScheme`"; menu sem grupos e com "Sair"/"Emitir Comunicado"; `js-defaultCollapsed`; links `r/corlixhub/` no header; `deployments/default.json` com `debugging: true`; ordem dos CSS invertida no `f100.sql`; Home usando `@/standard` e `cards-container-image-first`; p17 com `wizard-modal-dialog`; pasta `Fotos Colaboradores/` em static files; DDL em `database/corlix-hub.sql`; a antiga §13 "Mudanças não commitadas" (já incorporadas).
- **13/11/2026:** revisão completa pelo backup `84f8625` (esta versão). Revisão só documental: nada foi testado na app.
