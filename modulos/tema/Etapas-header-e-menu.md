# Header e menu lateral · passo a passo no APEX

Este guia deixa o cabeçalho (Global Page, página 0) e o menu lateral (Navigation Menu) iguais aos protótipos do `pen_dev/`, no App Builder do **APEX 26.1.5**. A descrição das telas está em `docs/ai-context/07-design-pen-dev.md` §2.1 e §2.2. Os protótipos de referência para o menu são os mais novos (`Holerite digital.png`, `Ponto eletrônico.png`, `Suporte TI.png`); o grupo **Administração** vem do `Início.png`.

Como nos outros módulos, a mudança é feita no Builder. O backup diário traz o resultado para `corlixhub/` na `DEV`; editar só o `.apx` do repositório não muda o app e é desfeito no próximo backup.

Passos marcados com **(confirmar no 26.1.5)** ainda não foram conferidos na tela desta versão. Se o caminho não existir, tire um print e registre o caminho certo neste guia.

### O que muda

| Antes | Depois (protótipo) |
|---|---|
| Menu lateral recolhido (só ícones) ao abrir o app | Menu expandido; o ☰ continua recolhendo |
| 15 itens soltos, sem grupos, com "Sair" fixo no rodapé | Itens de primeiro nível + grupos **Pessoas**, **Minha carreira** e **Administração**; subitens sem ícone |
| Header: sino, engrenagem, nome + cargo, avatar à direita | Header: sino, divisor, **avatar + nome + ▾**, que abre o **menu do usuário** |
| "Sair" no menu lateral; engrenagem leva a Configurações | Menu do usuário com nome, "login · empresa", **Meu perfil** e **Sair**; Configurações fica em Administração |

Ficam de fora, porque as páginas ainda não existem: Ponto eletrônico, Suporte TI, Avaliações, Resultados 360, Plano de desenvolvimento, Feedbacks, Minha equipe, Minhas aprovações e Preferências. Cada um entra no menu quando a página for criada.

### Ordem dos passos

O CSS (passo 1) pode subir antes de tudo: ele não quebra o header nem o menu atuais. Os passos 2 a 5 são independentes entre si.

---

## 1. CSS

Suba em *Shared Components › Static Application Files* os dois arquivos, substituindo os atuais:

- `corlixhub/shared-components/static-files/custom.css`
- `corlixhub/shared-components/static-files/custom.min.css`

O que mudou no CSS:
- §1: saiu a regra que transformava o **último** item do menu num botão de rodapé (era para o "Sair"). Sem ela, o último item volta a ser um item comum.
- §2: o bloco do usuário virou um botão (`.corlix-header__user`), com divisor (`.corlix-header__divisor`), seta (`.corlix-header__user-seta`) e o menu do usuário (`.cx-menu-usuario*`).

Recarregue com **Ctrl+Shift+R** (Cmd+Shift+R no Mac).

## 2. Menu lateral aberto por padrão

*Shared Components › User Interface Attributes › Navigation Menu › Template Options* (confirmar no 26.1.5).

**Collapsed by Default** (`js-defaultCollapsed`) é uma opção padrão do template: entra pelo `#DEFAULT#` e fica marcada e travada enquanto os padrões estiverem ligados. Por isso:

1. Desmarque **Use Template Defaults** (confirmar no 26.1.5: a caixa no topo do diálogo). Isso tira só o `#DEFAULT#`; o que ficar marcado passa a ser gravado no componente.
2. Desmarque **Collapsed by Default**.
3. Confira se continuam marcados o estilo **Style A** (`t-TreeNav--styleA`) e o modo de recolhimento atual (`js-navCollapsed--default`, que deixa só os ícones quando o menu é recolhido).
4. **OK** e *Apply Changes*.

No export, o `application.apx › navigationMenu › templateOptions` deve ficar só com `js-navCollapsed--default` e `t-TreeNav--styleA`.

O tema guarda no navegador a última escolha do ☰. Quem já recolheu o menu continua vendo-o recolhido até clicar no ☰ uma vez.

## 3. Itens do Navigation Menu

*Shared Components › Navigation Menu › Navigation Menu* (a lista usada pelo app, confirmar no 26.1.5). Edite as entradas que já existem (não apague e recrie: o Static ID de cada uma é usado nos backups) e crie só as três de grupo.

Em cada entrada: **Parent List Entry**, **Sequence**, **Image/Class** (ícone), **List Entry Label**, **Target** e **List Entry Current for Pages Type** › *Colon Delimited Page List* com as páginas da coluna "Current".

| Seq | Label | Pai | Ícone | Target | Current | Authorization |
|---|---|---|---|---|---|---|
| 10 | Início | | `fa-home` | página 1 | 1 | |
| 20 | Comunicados | | `fa-bullhorn` (era `fa-commenting-o`) | página 11 | 11 | |
| 30 | Chat | | `fa-comments-o` | página 4 | 4 | |
| 40 | **Pessoas** (nova) | | `fa-users` | sem target (confirmar no 26.1.5: *No Target*) | | |
| 41 | Colaboradores | Pessoas | (vazio) | página 12 | 12 | |
| 42 | Organograma | Pessoas | (vazio) | página 3 | 3 | |
| 50 | **Minha carreira** (nova) | | `fa-briefcase` | sem target | | |
| 51 | Meu perfil (era "Meu Perfil") | Minha carreira | (vazio) | página 2 | 2 | |
| 52 | Histórico de carreira | Minha carreira | (vazio) | página 13 | 13 | `COLABORADOR` (já tem) |
| 53 | Holerite (era "Holerite Digital") | Minha carreira | (vazio) | página 9 | 9 | |
| 60 | **Administração** (nova) | | `fa-shield` | sem target | | |
| 61 | Empresas (era "Empresas Cadastradas") | Administração | (vazio) | página 15 | 15:16 | `EQUIPE_CORLIX_HUB` (já tem) |
| 62 | Cadastro de usuários (era "Cadastro de Usuários") | Administração | (vazio) | página 14 | 14 | `ADMIN_RH` (já tem) |
| 63 | Dashboard RH | Administração | (vazio) | página 20 | 20 | `ADMIN_RH` (já tem) |
| 64 | Central de equipes (era "Central de Equipes") | Administração | (vazio) | página 26 | 26:27 | |
| 65 | Monitor de logs (era "Monitor de Logs") | Administração | (vazio) | página 7 | 7 | **`ADMIN_RH`** (nova: a página 7 já exige `ADMIN_RH`, e sem ela o item aparecia para todos e dava erro de acesso) |
| 66 | **Configurações** (nova) | Administração | (vazio) | página 6 | 6 | |

**Apague** duas entradas:
- **Solicitar correção** (página 22): é a modal aberta pelo Histórico de carreira, não uma tela de menu.
- **Sair**: vai para o menu do usuário (passo 4).

Os subitens ficam sem ícone, como no protótipo. Com o menu recolhido, o tema mostra só o ícone do grupo.

## 4. Header (Global Page)

Abra a **página 0** no Page Designer e selecione a região **Perfil** (slot *After Navigation Bar*). Em **Source › HTML Code**, troque todo o conteúdo por:

```html
<div class="corlix-header__actions">
  <a href="f?p=&APP_ID.:NOTIFICACOES:&SESSION." class="corlix-header__icon-btn"
     aria-label="Notificações" title="Notificações">
    <span class="fa fa-bell-o" aria-hidden="true"></span>
  </a>
  <span class="corlix-header__divisor" aria-hidden="true"></span>
  <button type="button" class="corlix-header__user" popovertarget="cx-menu-usuario"
          aria-haspopup="menu" aria-label="Menu do usuário">
    <img src="#APP_FILES#&APP_USER_FOTO." alt="" class="corlix-header__avatar"
         onerror="this.onerror=null; this.style.display='none'; this.nextElementSibling.style.display='';" />
    <span class="corlix-header__avatar cx-avatar-iniciais" aria-hidden="true" style="display:none">&APP_USER_INICIAIS.</span>
    <span class="corlix-header__user-name">&G_NOME_USUARIO.</span>
    <span class="fa fa-chevron-down corlix-header__user-seta" aria-hidden="true"></span>
  </button>
  <div id="cx-menu-usuario" class="cx-menu-usuario" popover>
    <div class="cx-menu-usuario__cabecalho">
      <span class="cx-menu-usuario__nome">&G_NOME_USUARIO.</span>
      <span class="cx-menu-usuario__info"><span class="cx-menu-usuario__login">&APP_USER.</span> · &G_NOME_EMPRESA.</span>
    </div>
    <hr class="cx-menu-usuario__separador">
    <a class="cx-menu-usuario__item" href="f?p=&APP_ID.:MEU-PERFIL:&SESSION.">
      <span class="fa fa-user-o" aria-hidden="true"></span>Meu perfil
    </a>
    <hr class="cx-menu-usuario__separador">
    <a class="cx-menu-usuario__item" href="&LOGOUT_URL.">
      <span class="fa fa-sign-out" aria-hidden="true"></span>Sair
    </a>
  </div>
</div>
```

O que muda em relação ao HTML atual:
- Sai a engrenagem (Configurações agora está no grupo Administração) e a linha do cargo abaixo do nome.
- O avatar vem antes do nome, e o conjunto vira um botão com ▾.
- O menu do usuário usa o atributo HTML `popover`: o navegador abre e fecha sozinho, fecha com Esc ou clique fora, e não precisa de JavaScript nem de Dynamic Action.
- Os links usam `f?p=&APP_ID.:<alias>:&SESSION.` em vez do caminho fixo `r/corlixhub/...`. Como não passam parâmetros, não precisam de checksum.

A região **Barra de Busca** (slot *After Logo*) não muda neste guia; ela passa a funcionar pelo `modulos/busca/Etapas-busca.md` §4.

## 5. Texto da empresa no menu do usuário

O menu do usuário mostra "login · empresa" com o item `G_NOME_EMPRESA`. Hoje, sem vínculo, ele vale "SEM VINCULO - usuario: TESTE"; o protótipo mostra "sem empresa vinculada". O item não é usado em mais nenhum lugar do app.

*Shared Components › Application Processes* › **G_NOME_EMPRESA** › **Source › PL/SQL Code**, troque por:

```plsql
BEGIN
  SELECT E.nome
    INTO :G_NOME_EMPRESA
    FROM COLABORADOR C
    JOIN EMPRESA E ON E.id_empresa = C.id_empresa
   WHERE UPPER(TRIM(C.login_apex)) = UPPER(TRIM(:APP_USER));
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    :G_NOME_EMPRESA := 'sem empresa vinculada';
  WHEN TOO_MANY_ROWS THEN
    :G_NOME_EMPRESA := 'mais de uma empresa vinculada';
  WHEN OTHERS THEN
    :G_NOME_EMPRESA := 'empresa indisponível';
    log_pkg.erro(SQLERRM, 'G_NOME_EMPRESA');
END;
```

---

## 6. Teste

Saia e entre de novo (os itens de aplicação são preenchidos no login), recarregue com Ctrl+Shift+R e confira:

1. **Menu:** abre expandido; ordem Início, Comunicados, Chat, Pessoas, Minha carreira, Administração. Os grupos abrem e fecham; os subitens não têm ícone. Na Início, o item Início tem fundo cinza, barra azul à esquerda e negrito.
2. **Menu recolhido:** o ☰ deixa só os ícones; clicar de novo expande.
3. **Permissões:** com um usuário sem `ADMIN_RH`, Cadastro de usuários, Dashboard RH e Monitor de logs não aparecem; sem `EQUIPE_CORLIX_HUB`, Empresas não aparece.
4. **Header:** sino, divisor, avatar (foto ou iniciais), nome e ▾. Sem engrenagem e sem cargo.
5. **Menu do usuário:** clique no nome: abre o menu com nome, "login · empresa" (login em minúsculas), Meu perfil e Sair. Esc ou clique fora fecham. Meu perfil abre a página 2; Sair faz logout.
6. **Usuário sem empresa:** a segunda linha mostra "login · sem empresa vinculada".

### Se não funcionar

| Sintoma | Causa provável | Correção |
|---|---|---|
| Menu continua abrindo recolhido | Preferência salva no navegador, ou `js-defaultCollapsed` ainda marcado | Clique no ☰ uma vez; confira o passo 2 |
| "Collapsed by Default" marcado e sem como desmarcar | É opção padrão do template e fica travada enquanto **Use Template Defaults** estiver ligado | Passo 2: desligue os padrões primeiro |
| Itens do menu em negrito e com 16px; faixa do título das páginas cinza com borda escura | `corlix-tema.css` antigo: o Redwood redefinia essas variáveis no `body` e no primeiro nível do menu | Suba `corlix-tema.css` e `corlix-tema.min.css` atuais |
| O último item do menu aparece como botão cinza no rodapé | `custom.css` antigo no app ou em cache | Passo 1 e Ctrl+Shift+R |
| Clicar no nome não abre nada | Faltou `popovertarget="cx-menu-usuario"` no botão, ou o `id` do menu está diferente | Copie o HTML do passo 4 de novo |
| Menu do usuário abre colado no topo, por cima do header, ou com fundo transparente | CSS do passo 1 não carregou | Passo 1 e Ctrl+Shift+R |
| Segunda linha "login · " sem a empresa | `G_NOME_EMPRESA` vazio na sessão | Saia e entre de novo |
| Item de grupo (Pessoas, Minha carreira, Administração) leva a uma página | A entrada de grupo ficou com Target | Passo 3: deixe sem target |
| Monitor de logs abre "Access denied" para quem vê o item | Falta `ADMIN_RH` na entrada do menu | Passo 3, linha 65 |
