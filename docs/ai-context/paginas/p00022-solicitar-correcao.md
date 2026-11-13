# Página 22 · Solicitar correção

> **Estado em 13/11/2026** (backup `84f8625`): implementada e validada. O guia `modulos/historico-carreira/Etapas-historico-carreira.md` marca §6 e §9.5 como ✅ ("Situação na revalidação de 19/10/2026"), e o export atual confere.

## Resumo

| Atributo | Valor |
|---|---|
| Alias | `SOLICITAR-CORRECAO` |
| Modo | Modal Dialog (`@/modal-dialog`); largura não definida no export |
| Page template | — (modal) |
| Autorização | `@colaborador` (`COLABORADOR`) · `argumentsMustHaveChecksum` |
| CSS/JS de arquivo | nenhum |
| Módulo/guia | `modulos/historico-carreira/` · `Etapas-historico-carreira.md` §6 |
| Protótipo | não há em `pen_dev/` |

Modal em que o próprio colaborador pede ao RH a revisão de um registro do seu histórico de carreira. O pedido aparece em "Solicitações de correção abertas" na página 20.

## Estrutura

```
Page 22: Solicitar correção (Modal Dialog)
├── Content Body (itens sem região)
│   ├── P22_ID_COLABORADOR        (10 · Hidden · checksum de sessão · preenchido pelo processo "Colaborador logado")
│   ├── P22_ID_HISTORICO_CARREIRA (20 · Select List "Qual registro?" · opcional · nulo = "Não sei / vários")
│   │     LOV SQL: historico_carreira EFETIVADO e não estornado do colaborador, da G_ID_EMPRESA
│   └── P22_DS_MENSAGEM           (30 · Textarea "O que está incorreto?" · obrigatório · max 2000 · ajuda inline)
└── Dialog Footer
    └── contêiner-de-botões "Botões" (10 · @/buttons-container)
        ├── CANCELAR "Cancelar" (close · Defined by DA)
        └── ENVIAR   "Enviar"   (next · hot · submit)
```

## Lógica

- **Computations:** —
- **Validations:** — (só `valueRequired` em `P22_DS_MENSAGEM`).
- **Processes:**
  - `Colaborador logado` (Before Header, 10): busca o `id_colaborador` por `upper(trim(login_apex)) = upper(trim(:APP_USER))` e `G_ID_EMPRESA`; sem vínculo (ou com mais de um) dá `-20012` "Sua conta não está vinculada a um colaborador desta empresa. Fale com o RH.". Sobrescreve qualquer id vindo da URL.
  - `Enviar` (Processing, 10, botão ENVIAR) · `pkg_historico_carreira.solicitar_correcao(p_id_colaborador, p_ds_mensagem, p_id_historico_carreira)`.
  - `Fechar` (20, botão ENVIAR) · Close Dialog · "Pedido enviado ao RH.".
- **Dynamic Actions:** `Cancelar` (click em `CANCELAR`) → Cancel Dialog.
- **JavaScript da página:** —

## Dados

- Tabelas `colaborador`, `historico_carreira`, `tipo_movimentacao`; grava em `solicitacao_correcao` pelo package.
- `pkg_historico_carreira.solicitar_correcao` (`modulos/historico-carreira/04_pkg_historico_carreira.pkb`), que confere que quem pede é o próprio colaborador.
- Multiempresa: o processo e a LOV filtram `:G_ID_EMPRESA`.

## Navegação

- Chega por: link "Solicitar correção" da página 13, só no histórico do próprio usuário (`pkg_historico_carreira_ui`, `c_pagina_solicitacao = 22`, item `P22_ID_COLABORADOR`).
- Sai por: Close Dialog; a página 13 passa a mostrar a solicitação em análise.
- Não há entrada de menu para a página 22 em `lists.apx`.

## Pegadinhas e pendências

- Contas sem colaborador (SARAHSILVA, EDUARDOMARINS, ALAIRTONROCHA) recebem o erro `-20012`; é esperado (guia §6).
- Se `c_pagina_solicitacao` estiver `null` no banco, o link da página 13 some (guia §6, aviso inicial; `09-erros-e-solucoes.md` §4.5, `ERR-1002`).
- Sem *Defined by Dynamic Action* no Cancelar, a modal recarrega em vez de fechar (guia §6, "Se não funcionar").

## Referências

- [Guia do módulo, §6, §8.5 e §9.5](../../../modulos/historico-carreira/Etapas-historico-carreira.md)
- [02 · Páginas, tabela-resumo](../02-paginas.md) (sem seção própria da 22)
- [09 · Erros e soluções, §4.5](../09-erros-e-solucoes.md)
- [Página 23 · Responder solicitação](./p00023-responder-solicitacao.md)
