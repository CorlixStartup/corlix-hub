# Página 14 · Cadastro de Usuários

> **Estado em 13/11/2026** (backup `84f8625`): implementada, com criação e edição. A edição foi validada na app em 09/11/2026 (`modulos/colaboradores/Registro-implantacao.md`, "Validação na tela da página 12 e da edição na p14"). **Criar colaborador com a conta de RH falha** (`APEX_UTIL.CREATE_USER` exige admin do workspace): pendência 1 de `modulos/colaboradores/Pendencias.md`, bloqueada até decisão do time.

## Resumo

| Atributo | Valor |
|---|---|
| Alias | `CADASTROS-DE-USUARIOS` |
| Modo | Normal |
| Page template | `@/standard` (divergência E1 do `11` §6) |
| Autorização | `@admin-rh` (`ADMIN_RH`) · `argumentsMustHaveChecksum` |
| CSS/JS de arquivo | nenhum na página; classes `cx-form-secao`, `cx-form-rodape` do tema global |
| Módulo/guia | `modulos/colaboradores/Etapas-colaboradores.md` §12.8 e §13 (edição); `modulos/tema/Etapas-cadastro-colaborador.md` (layout); `modulos/perfis-acesso/` (papéis); `modulos/historico-carreira/Etapas-historico-carreira.md` §7 (admissão) |
| Protótipo | `pen_dev/Novo colaborador.png` e `pen_dev/Editar colaborador.png` (`07` §4.5 e §4.6) |

Formulário do colaborador (tabela `COLABORADOR`). Na criação, também cria o usuário APEX, atribui os papéis do cargo e registra a admissão no histórico. Na edição, só atualiza o registro e volta para a lista.

## Estrutura

```
Page 14: Cadastro de Usuários
├── Breadcrumb Bar
│   └── cabeçalho "Cabeçalho" (20 · Dynamic Content · @/blank-with-attributes-no-grid)
│         return pkg_colaboradores_ui.render_cabecalho_cadastro(to_number(:P14_ID_COLABORADOR));
└── Body
    ├── novo "Cadastrar Colaborador" (20 · Form em COLABORADOR · @/standard noUI, sem header)
    │   ├── P14_ID_COLABORADOR (Hidden · PK)
    │   ├── dados-do-colaborador "Dados pessoais" (10 · Static Content · cx-form-secao)
    │   │     P14_NOME_COMPLETO, P14_PRIMEIRO_NOME, P14_ULTIMO_NOME, P14_DATA_NASCIMENTO (todos obrigatórios)
    │   ├── vínculo-profissional "Vínculo profissional" (20 · Static Content · cx-form-secao)
    │   │     P14_EMPRESA (Select One; LOV só a G_ID_EMPRESA; default :G_ID_EMPRESA)
    │   │     P14_DEPARTAMENTO (Select List em cascata da empresa)
    │   │     P14_CARGO (Select List em cascata de empresa + departamento)
    │   │     P14_GESTOR (Popup LOV em cascata: quem tem cargo com papel 'gestor' em CARGO_PAPEL + o atual)
    │   │     P14_DATA_ADMISSAO (obrigatório)
    │   │     (empresa, departamento, cargo e gestor ficam Read Only quando P14_ID_COLABORADOR não é nulo)
    │   ├── status-do-registro "Acesso ao sistema" (30 · Static Content · cx-form-secao)
    │   │     P14_EMAIL (obrigatório) · P14_LOGIN (obrigatório; Read Only na edição)
    │   │     P14_SENHA / P14_CONFIRMAR_SENHA (Password; só aparecem na criação)
    │   │     P14_STATUS "Situação da conta" (Switch; default TRUE; Read Only na edição)
    │   └── botão HISTORICO "Histórico de carreira" (60 · slot edit · se P14_ID_COLABORADOR não nulo · @admin-rh)
    │         → página 13 (P13_ID_COLABORADOR)
    └── rodapé "Rodapé" (30 · @/buttons-container · cx-form-rodape · "Campos com * são obrigatórios.")
        ├── CANCELAR "Cancelar" → página 14
        ├── SALVAR_USUARIO "Salvar colaborador" (hot · insert · confirmação · se ID nulo)
        └── SALVAR_ALTERACOES "Salvar alterações" (hot · update · se ID não nulo)
```

## Lógica

- **Computations:** —
- **Validations:** `Empresa do usuário` (5, `:P14_EMPRESA = :G_ID_EMPRESA`); `Validar Confirmação de Senha` (10, só no `SALVAR_USUARIO`); `Validar idade mínima` (20, 16 anos); `Validar data de admissão` (30, não futura); `Validar idade na admissão` (40, 16 anos na admissão). Datas em `America/Sao_Paulo`.
- **Processes:**
  - `Inicializar o form Cadastros` (Before Header, Form Initialization).
  - `Salvar Dados Colaborador` (Processing 10, Form Automatic Row Processing; "Dados salvos.").
  - `Registrar admissão` (15, `SALVAR_USUARIO` e ID não nulo) → `pkg_historico_carreira.registrar_admissao_automatica`.
  - `Criar usuário APEX` (20, `SALVAR_USUARIO`) → `APEX_UTIL.CREATE_USER(...)`; erro vira `-20000` com backtrace; "Colaborador cadastrado com sucesso!".
  - `Atribuir papéis do cargo` (30, `SALVAR_USUARIO` e login não nulo) → `PKG_PERFIS_ACESSO.ATRIBUIR_PAPEIS(login, cargo, APP_ID)`.
- **Branches:** `Voltar à lista após editar` (5, `SALVAR_ALTERACOES`) → página 12; `Limpar formulário após carregamento` (10) → página 14, clear 14.
- **Dynamic Actions:** `Desabilitar campos caso a empresa não tenha sido selecionada` (change `P14_EMPRESA`): com empresa, habilita Departamento/Cargo/Gestor; sem, desabilita.
- **JavaScript da página:** —

## Dados

- Tabelas `colaborador` (insert/update), `empresa`, `departamento`, `cargo`, `cargo_papel`.
- `pkg_colaboradores_ui.render_cabecalho_cadastro` (`modulos/colaboradores/02_pkg_colaboradores_ui.*`); `pkg_perfis_acesso` (`modulos/perfis-acesso/03_pkg_perfis_acesso.sql`); `pkg_historico_carreira` (`modulos/historico-carreira/04_*`); APIs `APEX_UTIL.CREATE_USER` e ACL do APEX.
- Multiempresa: LOV de empresa e validação `Empresa do usuário` prendem à `G_ID_EMPRESA`; LOVs em cascata filtram `:P14_EMPRESA`.

## Navegação

- Chega por: menu Administração › Cadastro de usuários (`@admin-rh`); página 12 (nome da pessoa, com `P14_ID_COLABORADOR`; "Novo colaborador", clear 14).
- Vai para: página 12 (depois de editar; trilha do cabeçalho); página 13 (botão `HISTORICO`); a própria 14 (Cancelar e depois de criar).

## Pegadinhas e pendências

- **Criação pelo RH bloqueada** (`Pendencias.md` §1): `User TESTE.RH requires ADMIN privilege to perform this operation.`; os processos 10 e 15 rodam antes do 20 e a transação é desfeita. Opções levantadas, sem decisão.
- Inativar (`P14_STATUS`) não bloqueia a conta APEX (`Pendencias.md` §2).
- Os papéis vêm do cargo só na criação; trocar o cargo depois não ajusta os papéis (`02-paginas.md`, página 14; `Pendencias.md` §3).
- As validações de data usam `TO_DATE(..., 'YYYY-MM-DD')`, que depende do formato do Date Picker; registros antigos sem data de nascimento não salvam na edição (`Etapas-colaboradores.md` §12.0).
- As LOVs de Cargo e de Empresa terminam com `;` dentro do SQL (o APEX costuma tolerar).
- O `02-paginas.md` (página 14) descreve a versão antiga (só insert, regiões "INFORMAÇÕES DE LOGIN"/"STATUS DO REGISTRO", botão Histórico que nunca aparece). Vale este `.apx`.

## Referências

- [Guia de colaboradores, §12.8 e §13](../../../modulos/colaboradores/Etapas-colaboradores.md) · [Pendências](../../../modulos/colaboradores/Pendencias.md)
- [Guia do cadastro de colaborador (layout)](../../../modulos/tema/Etapas-cadastro-colaborador.md)
- [Perfis de acesso](../../../modulos/perfis-acesso/Etapas-perfis-acesso.md)
- [Guia do histórico de carreira, §7](../../../modulos/historico-carreira/Etapas-historico-carreira.md)
- [02 · Páginas, página 14](../02-paginas.md)
