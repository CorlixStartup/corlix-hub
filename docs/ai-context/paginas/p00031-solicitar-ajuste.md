# Página 31 · Solicitar ajuste

> **Estado em 13/11/2026** (backup `84f8625`): implementada e validada na app em 03/11/2026 no DEV (`modulos/ponto-eletronico/Etapas-ajustes-validacao.md`, "Resultado na app": pedidos de abono, repetido recusado, "Justificar" preenchido, mês assinado recusado).

## Resumo

| Atributo | Valor |
|---|---|
| Alias | `SOLICITAR-AJUSTE` |
| Modo | Modal Dialog (`@/modal-dialog`); largura não definida no export |
| Page template | — (modal) |
| Autorização | `@colaborador` (`COLABORADOR`) · `argumentsMustHaveChecksum` |
| CSS/JS de arquivo | nenhum |
| Módulo/guia | `modulos/ponto-eletronico/` · `Etapas-ponto-eletronico.md` §5 |
| Protótipo | não há tela própria (o botão está em `pen_dev/Ponto eletrônico.png`) |

Modal em que o colaborador pede a inclusão ou correção de uma marcação, ou o abono de um dia. O pedido vai para a fila da página 32.

## Estrutura

```
Page 31: Solicitar ajuste (Modal Dialog)
├── Content Body (itens sem região)
│   ├── P31_DT_REFERENCIA (10 · Date Picker "Dia" · DD/MM/YYYY · obrigatório · default hoje por fn_hoje)
│   ├── P31_TP_AJUSTE     (20 · Radio "O que você precisa?" · MARCACAO / ABONO · default MARCACAO · obrigatório)
│   ├── P31_TP_MARCACAO   (30 · Select List "Marcação" · ENTRADA/INTERVALO/RETORNO/SAIDA · nulo "Escolha")
│   ├── P31_HR_MARCACAO   (40 · Text "Horário" · max 5 · ajuda "HH:MM")
│   └── P31_DS_MOTIVO     (50 · Textarea "Motivo" · obrigatório · max 2000)
└── Dialog Footer
    └── botões (60 · @/buttons-container)
        ├── CANCELAR "Cancelar"      (close · Defined by DA)
        └── ENVIAR   "Enviar pedido" (next · hot · submit)
```

## Lógica

- **Computations / Validations:** — (obrigatoriedade e coerência no package).
- **Processes:**
  - `Enviar` (Processing, 10, botão ENVIAR) · `pkg_ponto.solicitar_ajuste(p_dt_referencia, p_tp_ajuste, p_tp_marcacao, p_hr_marcacao, p_ds_motivo)`; data em `DD/MM/YYYY` e hora em `HH24:MI` como texto.
  - `Fechar` (20, botão ENVIAR) · Close Dialog · "Pedido enviado para aprovação.".
- **Dynamic Actions:**
  - `Cancelar` (click em `CANCELAR`) → Cancel Dialog.
  - `Tipo de ajuste` (change em `P31_TP_AJUSTE`, condição `= MARCACAO`) → True: Show `P31_TP_MARCACAO`, `P31_HR_MARCACAO`; False: Hide os dois. Fire on Initialization no padrão (On) nas duas ações.
- **JavaScript da página:** —

## Dados

- `pkg_ponto.solicitar_ajuste` (`modulos/ponto-eletronico/03_pkg_ponto.pks`/`.pkb`): grava em `ponto_ajuste` para o colaborador da conta logada; recusa pedido repetido e mês assinado (`-20070`).
- `pkg_historico_carreira.fn_hoje` no default do dia.
- Multiempresa: o package usa a conta logada e a empresa da sessão.

## Navegação

- Chega por: página 30 (botão "Solicitar ajuste" do cabeçalho, clear 31; "Justificar" das pendências com `P31_DT_REFERENCIA`, `P31_TP_AJUSTE` e, se marcação, `P31_TP_MARCACAO`) e Início (`pkg_home_ui.render_pendencias`).
- Sai por: Close Dialog; a página 30 atualiza espelho, pendências e diálogo do mês pelo `apexafterclosedialog` em `document`.

## Pegadinhas e pendências

- O Fire on Initialization das ações Show/Hide é necessário: "Justificar" num dia sem marcação abre a modal já em "Abonar o dia" (guia §5.4).
- Sem *Defined by Dynamic Action* no Cancelar, o botão faz Submit e a modal não fecha (mesmo padrão da página 22).
- O guia §5.2 escreve a LOV de `P31_TP_AJUSTE` com `STATIC:`; o export tem `STATIC2:`. No APEX, `STATIC2` mantém a ordem declarada e `STATIC` ordena pelo texto; o efeito na tela não foi conferido.

## Referências

- [Guia do ponto, §5](../../../modulos/ponto-eletronico/Etapas-ponto-eletronico.md)
- [Ajustes da validação e "Resultado na app"](../../../modulos/ponto-eletronico/Etapas-ajustes-validacao.md)
- [02 · Páginas, seção "Páginas 30 a 33"](../02-paginas.md)
- [Página 30 · Ponto eletrônico](./p00030-ponto-eletronico.md)
