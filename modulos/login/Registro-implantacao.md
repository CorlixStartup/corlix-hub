# Login (página 9999) · registro de implantação

## Proposta do redesign — 09/11/2026

Protótipo `pen_dev/Login.png`, adicionado pela usuária em 09/11/2026. O `07-design-pen-dev.md` listava a página 9999 como "sem tela no pen.dev"; foi atualizado.

Decisões da usuária: "Esqueci minha senha" mostra orientação (RH ou Suporte TI); "Primeiro acesso" com texto ajustado ao que o sistema faz hoje; Suporte TI só em texto, sem link; "Manter conectado" com login persistente.

Levantamento:
- Página atual (`p09999-login.apx`): template de página e de região **Login**; itens com template Hidden, ícones e textos em inglês; processos Get Username Cookie, Set Username Cookie, Login (`APEX_AUTHENTICATION.LOGIN`, `p_set_persistent_auth` em API Default) e Clear Page(s) Cache.
- Persistent authentication ligada na instância: a caixa `P9999_REMEMBER`, condicionada a `apex_authentication.persistent_cookies_enabled`, aparece na tela.
- Documentação do 26.1: `p_set_persistent_auth` exige o recurso ligado na instância; o item Password tem o botão Show Password nativo; `CREATE_USER` tem `p_change_password_on_first_use`, que a app usa com `'N'`.
- Estrutura do template Login lida na app: `.t-Login-bg`/`.t-Login-bgImg` (fundo fixo), `.t-Login-container` em grade, cabeçalho e rodapé ocultos quando vazios, região de 460 px.

Versionado em `modulos/login/`: `pkg_login.resolver_login` (e-mail para login), `pkg_login_ui` (cinco `render_*`), `login.css`/`.min.css`, `login-arte.jpg` (recorte do protótipo), `login-pagina.js` e o guia `Etapas-login.md`.

Evidência: prévia local, sem gravar nada, injetando o CSS e as regiões simuladas na página de login real em 1456 px. O resultado ficou fiel ao protótipo na coluna, no título, no "Primeiro acesso", no rodapé, no card e na arte (com `home-hero.jpg` no lugar da arte nova, ainda não publicada). Numa prévia em quadro isolado, os arquivos estáticos da app não carregaram, e os tokens ficaram vazios; isso é limitação do quadro, não do CSS.

Não testado: compilação dos packages, campos Floating, botão no corpo da região ao lado da caixa, diálogo, login por e-mail, login persistente e tela estreita.

Pendências: aplicar o guia e executar os testes do §4. A mensagem de credencial inválida deve continuar em inglês (texto interno do APEX); a tradução fica para outra tarefa.
