# Página 9999 · Login Page

> **Estado em 13/11/2026** (backup `84f8625`): implementada com o login padrão gerado pelo APEX, textos em inglês. O redesign de [`modulos/login/Etapas-login.md`](../../../modulos/login/Etapas-login.md) está só **proposto** ("Estado: proposto", packages não compilados) e não foi aplicado; [`Registro-implantacao.md`](../../../modulos/login/Registro-implantacao.md) lista como pendência "aplicar o guia e executar os testes do §4".

## Resumo

| Atributo | Valor |
|---|---|
| Alias | `LOGIN` (é o `loginUrl` em `application.apx`) |
| Modo | Normal |
| Page template | `@/login` |
| Autorização | pública (`authentication: public`); `argumentsMustHaveChecksum` |
| CSS/JS de arquivo | nenhum. A região usa a imagem `#APP_FILES#icons/app-icon-512.png` |
| Módulo/guia | `modulos/login/` · [`Etapas-login.md`](../../../modulos/login/Etapas-login.md) (proposto) |
| Protótipo | `pen_dev/Login.png` citado no guia, no registro e no [07](../07-design-pen-dev.md) §4.28, mas **o arquivo não está em `pen_dev/`** neste checkout (nem no histórico do Git) |

Tela de entrada da app. Autentica com `APEX_AUTHENTICATION.LOGIN` (contas APEX) e leva para a página 1.

## Estrutura

```
Page 9999: Login Page
└── Content Body
    └── CorlixHub (10, Static Content, template Login, imagem app-icon-512.png)
        ├── P9999_USERNAME (10, Text Field, template Hidden, ícone fa-user, placeholder "Username",
        │                   max 100, autocomplete="username", storage request)
        ├── P9999_PASSWORD (20, Password, template Hidden, ícone fa-key, placeholder "Password",
        │                   max 100, autocomplete="current-password", storage request)
        ├── P9999_REMEMBER (30, Checkbox "Remember username", template Hidden)
        │                   cond.: apex_authentication.persistent_cookies_enabled
        └── LOGIN          (40, next, Text, hot) "Sign In"
```

## Lógica

- **Computations / Validations / Dynamic Actions / JavaScript:** —
- **Processes:**
  - Before Header 10 `Get Username Cookie`: `:P9999_USERNAME := apex_authentication.get_login_username_cookie;` e marca `P9999_REMEMBER` = `Y` se houver usuário.
  - Processing 10 `Set Username Cookie`: `APEX_AUTHENTICATION.SEND_LOGIN_USERNAME_COOKIE(p_username => lower(:P9999_USERNAME), p_consent => :P9999_REMEMBER)`.
  - Processing 20 `Login`: `APEX_AUTHENTICATION.LOGIN(p_username => :P9999_USERNAME, p_password => :P9999_PASSWORD, p_set_persistent_auth => API Default)`.
  - Processing 30 `Clear Page(s) Cache` (Clear Session State).

## Dados

- Nenhuma tabela da app. Autenticação por contas APEX do workspace.
- Depois do login, os 4 app processes `BEFORE_HEADER` ligam o usuário ao colaborador por `COLABORADOR.login_apex = :APP_USER` (08 §3, 02 §3). Eles também rodam nesta página.
- Packages do redesign (não instalados): `pkg_login.resolver_login` e `pkg_login_ui` (`modulos/login/01_*`, `02_*`).

## Navegação

- Chega: `loginUrl` da app (sessão inexistente ou expirada) e "Sair" do menu.
- Vai: `homeUrl` → página 1 (Início).

## Pegadinhas e pendências

- Textos em inglês ("Username", "Password", "Remember username", "Sign In"); a mensagem de credencial inválida é interna do APEX (idioma técnico `en`) e continua em inglês mesmo depois do redesign (`Registro-implantacao.md`).
- "Remember username" só lembra o usuário: `p_set_persistent_auth` está em API Default. O redesign troca para login persistente ("Manter conectado"). A persistent authentication está ligada na instância (a caixa apareceu em 09/11/2026).
- Esta página controla a entrada de todos: ao aplicar o redesign, teste em janela anônima com o Builder aberto em outra (guia, "Cuidado" e "Voltar atrás").
- Não há "Esqueci minha senha" nem redefinição pelo usuário: com contas APEX, redefinir exige administrador do workspace (guia, "Decisões").
- Protótipo `pen_dev/Login.png` ausente do repositório: pedir ao time antes de conferir o layout (08 §1, regra 12).

## Referências

- [`modulos/login/Etapas-login.md`](../../../modulos/login/Etapas-login.md)
- [`modulos/login/Registro-implantacao.md`](../../../modulos/login/Registro-implantacao.md)
- [02 · Páginas](../02-paginas.md) (seção da 9999)
- [07 · Design pen.dev §4.28](../07-design-pen-dev.md)
- [10 · Cookies e sessão](../10-erro-400-cookies.md)
