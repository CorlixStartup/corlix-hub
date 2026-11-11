# Comunicados · categorias · passo a passo no APEX

Acrescenta a **categoria** aos comunicados, como nos protótipos `pen_dev/Início.png` (etiqueta "Institucional" no carrossel) e `pen_dev/Novo comunicado (diálogo).png` (campo **Categoria \***). Descrição das telas: `docs/ai-context/07-design-pen-dev.md` §4.1 e §4.2.

O carrossel da Home usa a categoria a partir do `modulos/home/Etapas-home.md` §8.

## Arquivos

| Arquivo | O que é |
|---|---|
| `01_ddl_categoria.sql` | Tabela `CATEGORIA_COMUNICADO`, coluna `COMUNICADO.ID_CATEGORIA` (FK) e 7 categorias para cada empresa: Institucional, Eventos, Benefícios, Saúde e bem-estar, Treinamentos, Resultados, Novos colaboradores |
| `02_categoria_demo.sql` | Dá categoria aos 5 comunicados de `modulos/home/dados-demo` |
| `instalar.sql` | Instala os dois pelo SQLcl |

## 1. Banco

*SQL Workshop › SQL Scripts*: rode `01_ddl_categoria.sql` e depois `02_categoria_demo.sql`. Os dois podem ser rodados de novo.

**Teste:**
```sql
select id_empresa, nm_categoria from categoria_comunicado order by id_empresa, nr_ordem
```

Empresa criada depois: rode o `01` de novo, e ela ganha as 7 categorias.

## 2. Página 17 (Emitir novo comunicado)

**LOV compartilhada.** *Shared Components › List of Values › Create*, **From Scratch**:

| Atributo | Valor |
|---|---|
| Name | `LOV_CATEGORIA_COMUNICADO` |
| Type | **Dynamic** |
| Source › SQL Query | `select nm_categoria d, id_categoria r from categoria_comunicado where id_empresa = :G_ID_EMPRESA and fl_ativo = true order by nr_ordem, nm_categoria` |

**Item.** No Page Designer da página 17, botão direito na região **emitir-comunicado** › **Create Page Item**:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `P17_ID_CATEGORIA` |
| Identification | Type | **Select List** |
| Label | Label | `Categoria` |
| Layout | Sequence | o mesmo do Departamento, logo depois dele |
| Appearance | Template | **Required - Floating** |
| Validation | Value Required | **On** |
| List of Values | Type | **Shared Component** › `LOV_CATEGORIA_COMUNICADO` |
| List of Values | Display Null Value | On, *Null Display Value* `- Selecione -` |
| Source | Form Region | `emitir-comunicado` |
| Source | Column | `ID_CATEGORIA` |
| Source | Data Type | **NUMBER** |

Se *Source › Column* não listar `ID_CATEGORIA`, a região foi carregada antes da coluna existir: em **emitir-comunicado**, clique em *Source › Table Name* e escolha `COMUNICADO` de novo, para o Builder reler as colunas (confirmar no 26.1.5).

**No export** (`p00017-comunicado.apx`): `pageItem P17_ID_CATEGORIA` com `lov { type: sharedComponent  lov: @lov-categoria-comunicado  nullDisplayValue: - Selecione - }`, `validation { valueRequired: true }` e `source { formRegion: @step-1  column: ID_CATEGORIA  dataType: number }`.

## 3. Testar

1. Abra "Novo comunicado": o campo **Categoria** lista as 7 categorias, começando por Institucional.
2. Tente publicar sem categoria: aparece o erro de campo obrigatório.
3. Publique com "Eventos": na Home, o comunicado aparece no carrossel com a etiqueta **Eventos**.

## Se não funcionar

| Sintoma | Causa provável | Correção |
|---|---|---|
| Lista de categorias vazia | `01_ddl_categoria.sql` não rodou, ou a empresa foi criada depois dele | Rode o `01` de novo |
| Comunicado publicado sem etiqueta na Home, e `ID_CATEGORIA` vazio na tabela | Item sem *Source* (no export, `P17_ID_CATEGORIA` sem o bloco `source`): o valor é validado, mas não é gravado | §2, *Source › Form Region* `emitir-comunicado`, *Column* `ID_CATEGORIA`, *Data Type* **NUMBER** |
| `ORA-00904: "ID_CATEGORIA"` ao publicar | Item criado antes da coluna existir | §1, depois recarregue as colunas da região (§2) |

## Situação

| Data | Estado |
|---|---|
| 10/11/2026 | Versionado na branch `feature/home-prototipo-completo`; **não executado nem aplicado** |
| 11/11/2026 | LOV e item `P17_ID_CATEGORIA` aplicados (export colado no chat). **Falta o *Source* do item**: sem ele a categoria não é gravada. Também falta acertar a sequência (todos os itens estão em 10 e a Categoria em 20, então ela cai no fim do formulário) |
