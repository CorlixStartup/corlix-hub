# Login (página 9999) · redesign · passo a passo no APEX

Este guia deixa a página 9999 igual ao protótipo [`pen_dev/Login.png`](../../pen_dev/Login.png), no App Builder do **APEX 26.1.5**. A página continua sendo a 9999, com o alias `LOGIN`, o template de página **Login** e o mesmo processo de autenticação (`APEX_AUTHENTICATION.LOGIN`).

Como nos outros guias, a mudança é feita no Builder. O backup diário traz o resultado para `corlixhub/pages/p09999-login.apx` na `DEV`.

> **Estado:** proposto. Os packages não foram compilados nem testados. O CSS foi conferido numa prévia local sobre a página de login real (09/11/2026): coluna do formulário, arte, card, "Primeiro acesso" e rodapé apareceram como no protótipo. Nada foi publicado na app.

> **Cuidado: esta página controla a entrada de todo mundo.** Mantenha o Builder aberto numa janela e teste numa **janela anônima** (ou outro navegador). Se o login quebrar, desfaça pelo Builder (veja "Voltar atrás"); a sessão do Builder não depende da página 9999.

### Como ler os caminhos deste guia (APEX 26.1.5)

- **Rendering** é a árvore da esquerda do Page Designer; o **painel de propriedades** é o da direita. `Seção › Atributo` indica a seção e o campo no painel do componente selecionado.
- Passos marcados com **(confirmar no 26.1.5)** ainda não foram conferidos na tela desta versão. Se o caminho não existir, não procure por tentativa: tire um print e registre o caminho certo aqui.

## O que muda

| Parte | Hoje | Depois |
|---|---|---|
| Layout | Card cinza centralizado, ícone de foguete | Formulário à esquerda e arte à direita; em tela estreita, só o formulário |
| Título | "CorlixHub" (título da região) | Marca **CorlixHub**, **Acesse sua conta** e subtítulo |
| Campos | Ícone, sem rótulo, "Username"/"Password" | Rótulo flutuante: **Login ou e-mail corporativo** e **Senha** (olho para mostrar a senha, nativo) |
| Usuário | Só o login APEX | **Login ou e-mail corporativo** (o e-mail é convertido no login antes de autenticar) |
| Caixa | "Remember username": só lembra o usuário | **Manter conectado**: login persistente (recurso nativo) e continua lembrando o usuário |
| Esqueci a senha | Não existia | **Esqueci minha senha** abre um diálogo com a orientação |
| Botão | "Sign In" | **Entrar**, largura total |
| Primeiro acesso | Não existia | Bloco **Primeiro acesso?** com o que o sistema faz hoje |
| Rodapé | Não existia | "Problemas para entrar? Procure o Suporte TI ou o RH." e "© <ano> Corlix" |
| Arte | Fundo com formas cinza | Arte do protótipo e card **Intranet Corlix** |

### Decisões (09/11/2026, usuária)

| Item do protótipo | Decisão | Por quê |
|---|---|---|
| Esqueci minha senha | Mostra orientação: pedir ao RH ou ao Suporte TI | Com contas APEX não há redefinição pelo próprio usuário; redefinir exige administrador do workspace |
| Primeiro acesso | Texto ajustado: "Entre com a senha que o RH enviou. Em caso de dúvida, procure o RH." | Hoje a conta é criada com a troca de senha desligada (`p_change_password_on_first_use => 'N'`), e a criação pelo RH está pendente (`modulos/colaboradores/Pendencias.md` §1) |
| Fale com o Suporte TI | Só texto, sem link | A página do Suporte TI (34) exige login |
| Manter conectado | Login persistente | É o que o protótipo promete. A caixa começa desmarcada |

### Manter conectado: como funciona

`APEX_AUTHENTICATION.LOGIN` tem o parâmetro `p_set_persistent_auth`: com `TRUE`, o APEX grava um cookie persistente e a pessoa volta sem digitar a senha até o prazo **Persistent Authentication Lifetime Days**, definido na instância. A documentação diz que o recurso precisa estar ligado na instância ([LOGIN](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/LOGIN-Procedure.html), [Controlling Persistent Authentication](https://docs.oracle.com/en/database/oracle/apex/26.1/aeadm/configuring-service-level-security-settings.html)).

Nesta app, ele está ligado: a caixa `P9999_REMEMBER` só aparece quando `apex_authentication.persistent_cookies_enabled` é verdadeiro, e ela apareceu na tela de login em 09/11/2026. Se a caixa sumir, a instância desligou o recurso.

Risco: em computador compartilhado, quem marcar a caixa continua logado. Por isso ela começa desmarcada e o texto é explícito. **Sair** (menu do usuário) encerra a sessão.

### Login por e-mail: como funciona

Um processo antes do **Login** chama `pkg_login.resolver_login(:P9999_USERNAME)`. Se o texto tiver `@`, a função procura **um único** colaborador com esse e-mail e login preenchido e troca o valor pelo login APEX. Sem correspondência única, o texto fica como foi digitado, e o `APEX_AUTHENTICATION.LOGIN` recusa com a mesma mensagem de credencial inválida. Assim a tela não revela se um e-mail existe.

### Arquivos do módulo

| Arquivo | O que é |
|---|---|
| `01_pkg_login.pks` / `.pkb` | `resolver_login`: e-mail para login APEX |
| `02_pkg_login_ui.pks` / `.pkb` | HTML das regiões: cabeçalho, primeiro acesso, diálogo, rodapé e card |
| `instalar.sql` | Instala os dois packages pelo SQLcl |
| `login.css` / `login.min.css` | Estilos da página, todos sob `.t-PageBody--login` |
| `login-arte.jpg` | Arte do painel direito (recorte do protótipo, 1400×1053, cerca de 310 KB) |
| `login-pagina.js` | Abre o diálogo "Esqueci minha senha" |
| `Registro-implantacao.md` | Histórico, testes e pendências |

### Referências reutilizadas

| O quê | De onde |
|---|---|
| Package de UI com `inicia`, `p`, `e` e `icone()` com SVG Lucide | Holerite (`pkg_holerite_ui`) |
| Diálogo inline em **Dialogs, Drawers and Popups**, aberto por `apex.theme.openRegion` com evento delegado por `data-*` | Ponto (p. 30, `ponto-pagina.js`) |
| Arquivo `<modulo>#MIN#.css`, `.css` e `.min.css` juntos | Holerite (§2 do guia) |
| Botão no corpo da região (`slot: regionBody`) | Histórico de carreira (p. 13, `hc_barra_rh`) |
| Arte com a mesma linguagem visual do hero | Home (`home-hero.jpg`) |
| Tokens `--cx-*` | `corlix-tema.css` |

Fora do padrão do `11`, sem exceção a aprovar: o template de página continua **Login** (E1 vale para páginas com menu), e a página não tem Authorization Scheme (S1), porque o login precisa ser público.

---

## 1. Banco

### 1.1 Instalar

Pelo SQLcl, na pasta do módulo:

```
cd modulos/login
sql <usuario>@<servico> @instalar.sql
```

No **SQL Workshop › SQL Scripts**, envie e rode um arquivo por vez, nesta ordem: `01_pkg_login.pks`, `01_pkg_login.pkb`, `02_pkg_login_ui.pks`, `02_pkg_login_ui.pkb`.

### 1.2 Conferir no SQL Commands

Um comando por vez:

```sql
select object_name, object_type, status from user_objects where object_name in ('PKG_LOGIN', 'PKG_LOGIN_UI') order by 1, 2
```

Os quatro objetos devem estar `VALID`.

```sql
select pkg_login.resolver_login('nao.existe@exemplo.invalid') r from dual
```

Deve voltar o próprio texto. Para um e-mail de colaborador com login, deve voltar o login.

---

## 2. Arquivos estáticos

Em *Shared Components › Static Application Files › Create File*, envie **na raiz** (sem pasta):

| File Name | Arquivo |
|---|---|
| `login.css` | `modulos/login/login.css` |
| `login.min.css` | `modulos/login/login.min.css` |
| `login-arte.jpg` | `modulos/login/login-arte.jpg` |

O CSS procura a arte na mesma pasta (`url("login-arte.jpg")`). Quando mudar o `.css`, gere o `.min.css` de novo e suba os dois.

---

## 3. Página 9999 no Page Designer

Faça os passos na ordem e salve no fim de cada seção.

### 3.1 Atributos da página

Clique no nó **Page 9999: Login Page**:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Title | `Entrar · CorlixHub` |
| CSS | File URLs | `#APP_FILES#login#MIN#.css` |
| JavaScript | Execute when Page Loads | conteúdo de `modulos/login/login-pagina.js` |

Não mude **Page Template** (continua **Login**) nem **Authentication** (continua **Page Is Public**).

### 3.2 Região do formulário

Selecione a região **CorlixHub**:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Title | `Acesse sua conta` |
| Image (ou Icon) | File URL | **vazio** (tire `#APP_FILES#icons/app-icon-512.png`) (confirmar no 26.1.5) |

O template **Login** continua. O título fica para leitores de tela; o CSS esconde o cabeçalho do template, porque o título visível vem da região do §3.4.

### 3.3 Itens e botão

**`P9999_USERNAME`**

| Seção | Atributo | Valor |
|---|---|---|
| Label | Label | `Login ou e-mail corporativo` |
| Appearance | Template | **Optional - Floating** |
| Appearance | Icon | **vazio** |
| Appearance | Value Placeholder | **vazio** |
| Validation | Maximum Length | `255` |

**`P9999_PASSWORD`**

| Seção | Atributo | Valor |
|---|---|---|
| Label | Label | `Senha` |
| Appearance | Template | **Optional - Floating** |
| Appearance | Icon | **vazio** |
| Appearance | Value Placeholder | **vazio** |

Não marque **Hide Password Visibility** nas Template Options: o olho que mostra a senha é nativo.

**`P9999_REMEMBER`**

| Seção | Atributo | Valor |
|---|---|---|
| Label | Label | `Manter conectado` |

Deixe a condição `apex_authentication.persistent_cookies_enabled` como está.

**Botão `LOGIN`**

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Label | `Entrar` |

**Novo botão "Esqueci minha senha"**: botão direito na região **Acesse sua conta** › **Create Button** (confirmar no 26.1.5):

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Button Name | `ESQUECI_SENHA` |
| Identification | Label | `Esqueci minha senha` |
| Layout | Sequence | `35` (depois de `P9999_REMEMBER`) |
| Layout | Slot (ou Position) | **Region Body** (confirmar no 26.1.5) |
| Layout | Start New Row | **Off** |
| Appearance | Button Template | **Text** |
| Appearance | Hot | **Off** |
| Appearance | CSS Classes | `cx-login-esqueci` |
| Behavior | Action | **Defined by Dynamic Action** |
| Advanced | Custom Attributes | `data-cx-login-dialogo="login_dlg_esqueci"` |

Sem dynamic action: o `login-pagina.js` trata o clique. Se **Start New Row** não aparecer para botão, deixe como está: o link fica na linha de baixo, alinhado à direita.

### 3.4 Regiões novas

Todas: botão direito em **Body** › **Create Region**, tipo **Dynamic Content**, **Source › Language** PL/SQL.

| Name | Sequence | PL/SQL Function Body returning a CLOB | Template |
|---|---|---|---|
| `Cabeçalho` | `5` | `return pkg_login_ui.render_cabecalho;` | **Blank with Attributes (No Grid)** |
| `Primeiro acesso` | `20` | `return pkg_login_ui.render_primeiro_acesso;` | **Blank with Attributes (No Grid)** |
| `Rodapé` | `30` | `return pkg_login_ui.render_rodape;` | **Blank with Attributes (No Grid)** |
| `Destaque` | `40` | `return pkg_login_ui.render_destaque;` | **Blank with Attributes (No Grid)** |

A região **Acesse sua conta** fica com a sequência `10`. A ordem na árvore deve ser Cabeçalho, Acesse sua conta, Primeiro acesso, Rodapé, Destaque. O CSS leva o rodapé ao fim da coluna e o card para cima da arte.

### 3.5 Diálogo "Esqueci minha senha"

Botão direito em **Dialogs, Drawers and Popups** › **Create Region** (confirmar no 26.1.5):

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name / Title | `Esqueci minha senha` |
| Identification | Type | **Dynamic Content** |
| Source | PL/SQL Function Body returning a CLOB | `return pkg_login_ui.render_esqueci;` |
| Appearance | Template | **Inline Dialog** |
| Appearance | Template Options | **Auto Height** e tamanho **480x320** (confirmar no 26.1.5) |
| Advanced | Static ID | `login_dlg_esqueci` |

Se o template **Login** não tiver a posição **Dialogs, Drawers and Popups**, pare e envie um print da árvore: não ponha o diálogo em **Body**.

### 3.6 Processos

Aba **Processing**.

**Novo processo**, botão direito em **Processes** › **Create Process**:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `Resolver login por e-mail` |
| Identification | Type | **Execute Code** |
| Source | PL/SQL Code | `:P9999_USERNAME := pkg_login.resolver_login(:P9999_USERNAME);` |
| Execution | Sequence | `15` |

Ele roda depois de **Set Username Cookie** (10), que guarda o que a pessoa digitou, e antes de **Login** (20).

**Processo Login**, parâmetro **p_set_persistent_auth**:

| Seção | Atributo | Valor |
|---|---|---|
| Value | Type | **Expression** (confirmar no 26.1.5) |
| Value | Language | **PL/SQL** |
| Value | PL/SQL Expression | `:P9999_REMEMBER = 'Y'` |

Hoje ele está em **API Default**, que é `FALSE`. Se **Expression** não existir para parâmetro booleano, envie um print das opções de **Value › Type**.

Salve a página.

---

## 4. Testar

Numa **janela anônima**, com o Builder aberto em outra janela.

| # | Teste | Esperado |
|---|---|---|
| 1 | Abrir o login em tela larga (1280 px ou mais) | Formulário à esquerda, arte à direita, card "Intranet Corlix" embaixo da arte, rodapé no fim da coluna |
| 2 | Tela estreita (menos de 1024 px, ou celular) | Só o formulário, sem arte e sem card, sem rolagem lateral |
| 3 | Entrar com login e senha certos | Vai para o Início |
| 4 | Entrar com o **e-mail** corporativo e a senha | Vai para o Início, com o mesmo usuário do teste 3 |
| 5 | Senha errada, com login e com e-mail | Mesma mensagem de credencial inválida nos dois casos |
| 6 | E-mail que não existe | Mesma mensagem do teste 5 |
| 7 | Olho do campo Senha | Mostra e esconde a senha |
| 8 | **Esqueci minha senha** | Abre o diálogo com a orientação; fecha pelo X e pelo Esc; o formulário não é enviado |
| 9 | **Manter conectado** marcado, fechar o navegador todo e abrir a app de novo | Entra sem pedir senha |
| 10 | **Manter conectado** desmarcado, fechar o navegador e abrir de novo | Pede login |
| 11 | Depois do teste 9, **Sair** e abrir a app | Pede login |
| 12 | Tab pelo formulário | Ordem: login, senha, olho, Manter conectado, Esqueci minha senha, Entrar |
| 13 | Console do navegador | Sem erro e sem 404 de `login.min.css` ou `login-arte.jpg` |

---

## Se não funcionar

| Sintoma | Causa / verificação | Ação |
|---|---|---|
| Página sem estilo novo, card cinza no meio | `login#MIN#.css` não carregou | Confira o §2 e o File URL do §3.1; recarregue com Ctrl+Shift+R |
| Painel direito cinza, sem arte | `login-arte.jpg` fora da raiz ou com outro nome | Suba de novo com o nome exato |
| Título "Acesse sua conta" duplicado | Cabeçalho do template visível | Confira se o `.min.css` é o desta pasta |
| Erro `ORA-06550`/`PLS-00201` ao abrir ou ao entrar | Package não instalado ou inválido | §1.2 |
| Login por e-mail recusa a senha certa | E-mail duplicado em dois colaboradores ou sem `login_apex` | `select login_apex from colaborador where lower(email) = lower('<e-mail>')` deve voltar uma linha |
| "Esqueci minha senha" envia o formulário | **Action** não está em **Defined by Dynamic Action** | §3.3 |
| Clique em "Esqueci minha senha" não faz nada | JS não colado ou Static ID diferente | Confira **Execute when Page Loads** e `login_dlg_esqueci` |
| Caixa "Manter conectado" sumiu | Persistent authentication desligada na instância | Peça ao administrador da instância; até lá, a caixa não aparece |
| Teste 9 pede senha | Parâmetro `p_set_persistent_auth` ainda em API Default | §3.6 |
| Mensagem de erro em inglês | Texto interno do APEX (idioma técnico `en`) | Registrar no `Registro-implantacao.md`; a tradução é outra tarefa |
| Ninguém consegue entrar | Erro no processo novo ou no Login | Pelo Builder, desative o processo **Resolver login por e-mail** (Server-side Condition **Never**) e teste de novo |

## Voltar atrás

O estado anterior está em `corlixhub/pages/p09999-login.apx` na `DEV` (backup antes desta mudança). Para desfazer pelo Builder:

1. Apague as regiões Cabeçalho, Primeiro acesso, Rodapé, Destaque e Esqueci minha senha, o botão `ESQUECI_SENHA` e o processo **Resolver login por e-mail**.
2. Volte **p_set_persistent_auth** para **API Default**.
3. Volte os rótulos (`Username`, `Password`, `Remember username`, `Sign In`), o template **Hidden** e os ícones `fa-user`/`fa-key` dos itens, e o File URL da imagem da região.
4. Tire o File URL do CSS e o JS da página.

Os packages podem ficar no banco: sem a página, não são chamados.
