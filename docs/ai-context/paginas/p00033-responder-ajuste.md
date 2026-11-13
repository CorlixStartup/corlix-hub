# Página 33 · Responder ajuste

> **Estado em 13/11/2026** (backup `84f8625`): implementada e validada na app em 03/11/2026 no DEV (`modulos/ponto-eletronico/Etapas-ajustes-validacao.md`, "Resultado na app": dados do pedido, só Aprovar e Recusar, recusar sem mensagem barrado, aprovar abono zera o saldo).

## Resumo

| Atributo | Valor |
|---|---|
| Alias | `RESPONDER-AJUSTE` |
| Modo | Modal Dialog (`@/modal-dialog`); largura não definida no export |
| Page template | — (modal) |
| Autorização | `@aprovador-ponto` (`APROVADOR_PONTO`) · `argumentsMustHaveChecksum` |
| CSS/JS de arquivo | nenhum |
| Módulo/guia | `modulos/ponto-eletronico/` · `Etapas-ponto-eletronico.md` §6 |
| Protótipo | não há em `pen_dev/` |

Modal em que o gestor direto ou o RH aprova ou recusa um pedido de ajuste de ponto.

## Estrutura

```
Page 33: Responder ajuste (Modal Dialog)
├── Content Body (itens sem região)
│   ├── P33_ID_AJUSTE      (10 · Hidden)
│   ├── P33_NM_COLABORADOR (20 · Display Only "Colaborador")
│   ├── P33_DS_PEDIDO      (30 · Display Only "Pedido": dia · tipo · horário)
│   ├── P33_DS_MOTIVO      (40 · Display Only "Motivo")
│   ├── P33_ST_AJUSTE      (50 · Radio "Resposta" · Aprovar;APROVADO / Recusar;RECUSADO · obrigatório)
│   └── P33_DS_RESPOSTA    (60 · Textarea "Mensagem ao colaborador" · max 2000 · "Obrigatória se recusar.")
└── Dialog Footer
    └── botões (70 · @/buttons-container)
        ├── CANCELAR  "Cancelar"  (close · Defined by DA)
        └── RESPONDER "Responder" (next · hot · submit)
```

## Lógica

- **Computations / Validations:** — (só `valueRequired` no radio; o resto no package).
- **Processes:**
  - `Carregar` (Before Header, 10): `-20067` se `pkg_ponto.fn_pode_aprovar(:P33_ID_AJUSTE) <> 'S'`; lê colaborador, pedido e motivo de `ponto_ajuste` PENDENTE da `G_ID_EMPRESA`; sem linha dá `-20066` "Pedido não encontrado ou já respondido.".
  - `Responder` (Processing, 10, botão RESPONDER) · `pkg_ponto.responder_ajuste(p_id_ajuste, p_st_ajuste, p_ds_resposta)`.
  - `Fechar` (20, botão RESPONDER) · Close Dialog · "Resposta registrada.".
- **Dynamic Actions:** `Cancelar` (click em `CANCELAR`) → Cancel Dialog.
- **JavaScript da página:** —

## Dados

- Tabelas `ponto_ajuste`, `colaborador`; ao aprovar marcação, o package insere em `ponto_marcacao` com origem `AJUSTE`.
- `pkg_ponto.responder_ajuste` (`modulos/ponto-eletronico/03_pkg_ponto.pkb`): confere `fn_pode_aprovar`, status PENDENTE, valor APROVADO/RECUSADO, mensagem obrigatória ao recusar, mês aberto e ordem das marcações.
- Multiempresa: o carregamento filtra `:G_ID_EMPRESA`; `fn_pode_aprovar` limita a gestor direto ou RH.

## Navegação

- Chega por: coluna `RESPONDER` da página 32 (`P33_ID_AJUSTE`, clear 33).
- Sai por: Close Dialog; a página 32 atualiza o IR pela DA `Pedido respondido`.

## Pegadinhas e pendências

- `P33_ID_AJUSTE` não tem Session State Protection própria; a proteção vem do checksum da página e das conferências do processo e do package.
- Os códigos `-20066` a `-20068` estão na faixa que o `log_pkg.apex_error_handler` repassa ao `fn_tratar_erro` (mensagem sem "ORA-"; guia do histórico §9.1).
- Aprovar um ajuste não apaga a marcação original: a nova linha passa a valer e a original continua nos comprovantes (guia, "Regras de cálculo").

## Referências

- [Guia do ponto, §6](../../../modulos/ponto-eletronico/Etapas-ponto-eletronico.md)
- [Ajustes da validação, §4 e "Resultado na app"](../../../modulos/ponto-eletronico/Etapas-ajustes-validacao.md)
- [02 · Páginas, seção "Páginas 30 a 33"](../02-paginas.md)
- [Página 32 · Ajustes de ponto](./p00032-ajustes-de-ponto.md)
