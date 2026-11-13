# Página 23 · Responder solicitação

> **Estado em 13/11/2026** (backup `84f8625`): implementada e validada. O guia `modulos/historico-carreira/Etapas-historico-carreira.md` marca §5 (com a §5.5), §9.6 e a etapa 4.1 da §9.10 como ✅ ("Situação na revalidação de 19/10/2026").

## Resumo

| Atributo | Valor |
|---|---|
| Alias | `RESPONDER-SOLICITACAO` |
| Modo | Modal Dialog (`@/modal-dialog`); largura não definida no export |
| Page template | — (modal) |
| Autorização | `@admin-rh` (`ADMIN_RH`) · `argumentsMustHaveChecksum` |
| CSS/JS de arquivo | nenhum |
| Módulo/guia | `modulos/historico-carreira/` · `Etapas-historico-carreira.md` §5.5 |
| Protótipo | não há em `pen_dev/` |

Modal em que o RH responde a uma solicitação de correção aberta: marca Resolvida ou Recusada e escreve a mensagem ao colaborador.

## Estrutura

```
Page 23: Responder solicitação (Modal Dialog)
├── Content Body
│   └── solicitação (10 · Static Content · @/standard, t-Region--scrollBody)
│       ├── P23_ID_SOLICITACAO  (10 · Hidden)
│       ├── P23_NM_COLABORADOR  (20 · Display Only "Colaborador")
│       ├── P23_DS_LANCAMENTO   (30 · Display Only "Registro questionado")
│       ├── P23_DS_MENSAGEM     (40 · Display Only "Pedido")
│       ├── P23_ST_SOLICITACAO  (50 · Radio "Resposta" · Resolvida;RESOLVIDA / Recusada;RECUSADA · obrigatório)
│       └── P23_DS_RESPOSTA     (60 · Textarea "Mensagem ao colaborador" · max 2000 · "Obrigatória se recusar.")
└── Dialog Footer
    └── botões (10 · @/buttons-container)
        ├── CANCELAR "Cancelar" (close · Defined by DA)
        └── RESPONDER "Responder" (next · hot · submit)
```

## Lógica

- **Computations:** —
- **Validations:** — (só `valueRequired` no radio; a obrigatoriedade da mensagem ao recusar está no package).
- **Processes:**
  - `Carregar solicitação` (Before Header, 10): lê colaborador, pedido e registro questionado de `solicitacao_correcao` com `id_empresa = G_ID_EMPRESA` e `st_solicitacao = 'ABERTA'`; sem linha dá `-20019` "Solicitação não encontrada ou já respondida.".
  - `Responder` (Processing, 10, botão RESPONDER) · `pkg_historico_carreira.responder_solicitacao(p_id_solicitacao, p_st_solicitacao, p_ds_resposta)`.
  - `Fechar` (20, botão RESPONDER) · Close Dialog · "Resposta registrada.".
- **Dynamic Actions:** `Cancelar` (click em `CANCELAR`) → Cancel Dialog.
- **JavaScript da página:** —

## Dados

- Tabelas `solicitacao_correcao`, `colaborador`, `historico_carreira`, `tipo_movimentacao`.
- `pkg_historico_carreira.responder_solicitacao` (`modulos/historico-carreira/04_pkg_historico_carreira.pkb`): exige `ADMIN_RH`, confere a empresa, recusa se já respondida e exige mensagem ao recusar ("Explique ao colaborador por que a solicitação foi recusada.").
- Multiempresa: o carregamento filtra `:G_ID_EMPRESA` e o package confere de novo.

## Navegação

- Chega por: coluna `RESPONDER` do IR "Solicitações de correção abertas" da página 20 (`P23_ID_SOLICITACAO`, clear 23).
- Sai por: Close Dialog; a página 20 atualiza a lista pela DA `Atualizar solicitações`.

## Pegadinhas e pendências

- O link da página 20 precisa de Clear Cache 23; sem ele, a segunda solicitação abria com a resposta da anterior (guia §9.10, etapa 4.1, já aplicado).
- `P23_ID_SOLICITACAO` não tem Session State Protection própria; a proteção vem do checksum da página e das conferências de empresa e status no processo e no package.
- O redesign da página 20 (`modulos/dashboard-rh/Etapas-dashboard-rh.md`) continua abrindo esta modal; só muda quem escuta o fechamento (DA em `document`).

## Referências

- [Guia do módulo, §5.5, §8.6 e §9.6](../../../modulos/historico-carreira/Etapas-historico-carreira.md)
- [02 · Páginas, tabela-resumo](../02-paginas.md) (sem seção própria da 23)
- [Página 20 · Dashboard RH](./p00020-dashboard-rh.md)
