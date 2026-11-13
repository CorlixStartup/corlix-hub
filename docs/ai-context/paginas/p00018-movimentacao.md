# Página 18 · Movimentação

> **Estado em 13/11/2026** (backup `84f8625`): implementada e validada. O guia `modulos/historico-carreira/Etapas-historico-carreira.md` marca a §3 como ✅ na "Situação na revalidação de 19/10/2026" (§9), e o export atual confere com ela. O isolamento por empresa do formulário (`Etapas-isolamento-empresas.md` §6) ainda não foi aplicado.

## Resumo

| Atributo | Valor |
|---|---|
| Alias | `MOVIMENTACAO` |
| Modo | Modal Dialog (`@/modal-dialog`); largura não definida no export (padrão do template) |
| Page template | — (modal usa `dialogTemplate: @/modal-dialog`) |
| Autorização | `@admin-rh` (`ADMIN_RH`) · `pageAccessProtection: argumentsMustHaveChecksum` |
| CSS/JS de arquivo | nenhum `fileUrls`. JS inline na página (blocos 1 e 2 de `modulos/historico-carreira/historico-carreira.js`) |
| Módulo/guia | `modulos/historico-carreira/` · `Etapas-historico-carreira.md` §3 |
| Protótipo | não há tela própria em `pen_dev/` (é a modal da página 13, cujo protótipo é `pen_dev/Histórico de carreira — nova página.png`) |

Modal do RH para criar, editar (só rascunho), efetivar, estornar e excluir um lançamento do histórico de carreira de um colaborador. Toda gravação passa por `pkg_historico_carreira`; a view só serve para carregar o formulário.

## Estrutura

```
Page 18: Movimentação (Modal Dialog)
├── Content Body
│   ├── movimentação (10 · Form sobre VW_HISTORICO_CARREIRA · @/standard, t-Region--scrollBody · sem bloco edit)
│   │   ├── P18_ID_TIPO_MOVIMENTACAO   (10 · Select List · LOV_TIPO_MOVIMENTACAO · "- Selecione -" · obrigatório)
│   │   ├── P18_DT_EFETIVA             (20 · Date Picker DD/MM/YYYY · obrigatório)
│   │   ├── P18_ST_REGISTRO            (30 · Display Only "Situação" · default RASCUNHO)
│   │   ├── P18_NM_CARGO_ANTERIOR      (40 · Display Only "Cargo atual" · default SQL do cargo atual)
│   │   ├── P18_NM_DEPARTAMENTO_ANTERIOR (50 · Display Only "Departamento atual")
│   │   ├── P18_ID_DEPARTAMENTO_NOVO   (60 · Popup LOV · LOV_DEPARTAMENTO_EMPRESA)
│   │   ├── P18_ID_CARGO_NOVO          (70 · Popup LOV em cascata · pai P18_ID_DEPARTAMENTO_NOVO)
│   │   ├── P18_ID_GESTOR_NOVO         (80 · Popup LOV · LOV_COLABORADOR_ATIVO)
│   │   ├── P18_VL_SALARIO_ANTERIOR    (90 · Number · authorization ADMIN_RH)
│   │   ├── P18_VL_SALARIO_NOVO        (100 · Number · authorization ADMIN_RH)
│   │   ├── P18_DS_MOTIVO              (110 · Textarea · max 1000)
│   │   ├── P18_ID_APROVADOR           (120 · Popup LOV · LOV_COLABORADOR_ATIVO)
│   │   ├── P18_DS_OBSERVACAO          (130 · Textarea · CLOB)
│   │   ├── P18_ID_HISTORICO_CARREIRA  (150 · Hidden · PK · checksum de sessão)
│   │   ├── P18_ID_COLABORADOR         (160 · Hidden · checksum de sessão)
│   │   ├── P18_CD_TIPO                (170 · Hidden · valueProtected: false, o JS lê)
│   │   ├── P18_FL_ESTORNO             (180 · Hidden)
│   │   └── P18_ID_DEPARTAMENTO_ATUAL  (190 · Hidden · Source SQL: departamento atual do colaborador)
│   └── estorno (20 · Static Content · @/standard · condição: EFETIVADO e FL_ESTORNO = 'N')
│       └── P18_DS_MOTIVO_ESTORNO      (140 · Textarea "Motivo do estorno")
└── Dialog Footer
    └── botões (10 · @/buttons-container)
        ├── CANCELAR        (close · Defined by DA)
        ├── EXCLUIR         (delete · "Excluir rascunho" · só rascunho já salvo · confirma)
        ├── ESTORNAR        (delete · t-Button--danger · só EFETIVADO não estornado · confirma)
        ├── SALVAR_RASCUNHO (next · só RASCUNHO)
        └── EFETIVAR        (next · hot · só RASCUNHO · confirma)
```

Todos os itens editáveis têm `readOnly` com `:P18_ST_REGISTRO <> 'RASCUNHO'`. Todos os botões têm `authorizationScheme: @admin-rh`.

## Lógica

- **Computations:** —
- **Validations:** nenhuma na página; as regras ficam no package (ex.: promoção sem cargo novo).
- **Processes (Before Header):**
  - `Initialize form Movimentação` (10, Form Initialization).
  - `Registrar acesso salarial` (20) · `pkg_historico_carreira.registrar_acesso_salarial(:P18_ID_COLABORADOR, 'P18 · lançamento #' || id)` · authorization `ADMIN_RH` · só com `P18_ID_HISTORICO_CARREIRA` preenchido.
- **Processes (Processing, nesta ordem):**
  - `Salvar movimentação` (10) · request em `SALVAR_RASCUNHO,EFETIVAR` · `registrar_movimentacao` (novo, devolve o id) ou `atualizar_rascunho` (existente).
  - `Mensagem do rascunho` (15) · `null;` · só `SALVAR_RASCUNHO` · mensagem "Rascunho salvo.".
  - `Efetivar` (20) · `efetivar_movimentacao(:P18_ID_HISTORICO_CARREIRA)` · "Movimentação efetivada.".
  - `Estornar` (30) · `estornar_movimentacao(id, :P18_DS_MOTIVO_ESTORNO)` · "Lançamento estornado.".
  - `Excluir rascunho` (40) · `excluir_rascunho(id)` · "Rascunho excluído.".
  - `Fechar` (50) · Close Dialog · request em `SALVAR_RASCUNHO,EFETIVAR,ESTORNAR,EXCLUIR`.
- **Dynamic Actions:**
  - `Tipo mudou` (change em `P18_ID_TIPO_MOVIMENTACAO`) → Set Value de `P18_CD_TIPO` por SQL em `tipo_movimentacao` (filtra `G_ID_EMPRESA`, Wait For Result no padrão On) → `carreira.ajustarCampos(true)`.
  - `Cancelar` (click em `CANCELAR`) → Cancel Dialog.
- **JavaScript da página:**
  - Function and Global Variable Declaration: objeto `carreira` com os mapas `visivelEm`, `obrigatorioEm` e `itens`, e `carreira.ajustarCampos(limpar)`, que mostra/esconde os grupos (cargo, departamento, gestor, salário) conforme `P18_CD_TIPO`, limpa os escondidos e marca `is-required`.
  - Execute when Page Loads: `carreira.ajustarCampos(false)` (preserva valores do rascunho).

## Dados

- View `VW_HISTORICO_CARREIRA` (só leitura do form), tabelas `tipo_movimentacao`, `colaborador`, `cargo`, `departamento`.
- Package `pkg_historico_carreira` (`modulos/historico-carreira/04_pkg_historico_carreira.pks`/`.pkb`): `registrar_movimentacao`, `atualizar_rascunho`, `efetivar_movimentacao` (atualiza `COLABORADOR` e pode publicar comunicado), `estornar_movimentacao`, `excluir_rascunho`, `registrar_acesso_salarial`.
- LOVs compartilhadas: `LOV_TIPO_MOVIMENTACAO`, `LOV_DEPARTAMENTO_EMPRESA`, `LOV_COLABORADOR_ATIVO` (todas filtram `G_ID_EMPRESA`).
- Multiempresa: LOVs, defaults e o SQL do tipo filtram `:G_ID_EMPRESA`; o package confere a empresa. A região de Form **não** tem Where Clause por empresa.

## Navegação

- Chega por: página 13, coluna `ID_HISTORICO_CARREIRA` (lápis, com `P18_ID_HISTORICO_CARREIRA` e `P18_ID_COLABORADOR`, clear 18) e botão `NOVA_MOVIMENTACAO` da barra do RH (`P18_ID_COLABORADOR`, clear 18).
- Sai por: Close Dialog nos quatro requests; a página 13 atualiza pela DA "Atualizar depois da modal".

## Pegadinhas e pendências

- A região `movimentação` não tem o bloco `edit { enabled: true }` (`09-erros-e-solucoes.md` §4.8). Por isso o motivo do estorno fica numa região à parte. Edição de um rascunho já salvo: comportamento não confirmado nos registros.
- `Salvar movimentação` roda também no `EFETIVAR`; sem ela, efetivar uma movimentação nova passaria id nulo (guia §3.5). Se a efetivação falha, o rascunho do mesmo submit é desfeito.
- `P18_CD_TIPO` precisa de `valueProtected: false`, senão o JS não o usa (guia §3.2).
- Os itens de salário somem para quem não é `ADMIN_RH`; o JS ignora item não renderizado.
- Pendente: Where Clause `id_empresa = :G_ID_EMPRESA` na região do form (`modulos/isolamento-empresas/Etapas-isolamento-empresas.md` §6). Hoje quem protege é o checksum da URL.
- Erros -20001 a -20099 aparecem sem "ORA-" porque o `log_pkg.apex_error_handler` delega para `pkg_historico_carreira.fn_tratar_erro` (guia §9.1).

## Referências

- [Guia do módulo, §3 e §8.2](../../../modulos/historico-carreira/Etapas-historico-carreira.md)
- [Isolamento entre empresas, §6](../../../modulos/isolamento-empresas/Etapas-isolamento-empresas.md)
- [02 · Páginas, tabela-resumo](../02-paginas.md) (sem seção própria da 18)
- [09 · Erros e soluções, §4.8](../09-erros-e-solucoes.md)
