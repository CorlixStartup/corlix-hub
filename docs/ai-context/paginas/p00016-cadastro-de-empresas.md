# Página 16 · Cadastro de Empresas

> **Estado em 13/11/2026** (backup `84f8625`): implementada pelo `modulos/tema/Etapas-cadastro-empresa.md`, inclusive as validações do §6.1 (CNPJ repetido, remoção com vínculos), que o `02-paginas.md` registra como conferidas no Builder e na app em 27/10/2026. O guia não tem seção "Situação".

## Resumo

| Atributo | Valor |
|---|---|
| Alias | `CADASTRO-DE-EMPRESAS` |
| Modo | Modal Dialog, largura 1000, `chained: false` · título `&P16_TITULO.` |
| Page template | `@/modal-dialog` |
| Autorização | `@administration-rights` (`EQUIPE_CORLIX_HUB`) · `argumentsMustHaveChecksum` |
| CSS/JS de arquivo | nenhum; classes `cx-form-modal`, `cx-form-modal-rodape` do tema global |
| Módulo/guia | `modulos/tema/Etapas-cadastro-empresa.md`; banco em `modulos/empresas/` (`01_data_criacao_opcional.sql`, `02_complemento_100.sql`) |
| Protótipo | `pen_dev/Nova empresa (modal).png` (`07` §4.7.1) |

Modal de CRUD da tabela `EMPRESA`. O CNPJ preenche os dados pela BrasilAPI (só em empresa nova) e o CEP preenche o endereço pelo ViaCEP.

## Estrutura

```
Page 16: Cadastro de Empresas (modal)
├── Content Body
│   └── cadastro-de-empresas (10 · Form em EMPRESA · @/blank-with-attributes · cx-form-modal)
│       ├── new "Identificação" (10 · @/standard)
│       │     P16_ID_EMPRESA (PK) · P16_TITULO (Hidden) · P16_CNPJ · P16_NOME · P16_NOME_FANTASIA
│       │     · P16_DATA_CRIACAO
│       ├── contato-e-endereço "Contato e endereço" (40 · @/standard)
│       │     P16_EMAIL_CORPORATIVO · P16_TELEFONE · P16_CEP · P16_LOGRADOURO · P16_NUMERO
│       │     · P16_COMPLEMENTO · P16_BAIRRO · P16_CIDADE · P16_UF (lista estática das 27 UFs)
│       └── configurações "Logotipo e situação" (50 · @/standard)
│             P16_LOGOTIPO_EMPRESA (Image Upload, dropzone, até 2 MB, coluna BLOB LOGOTIPO_EMPRESA)
│             · P16_STATUS "Situação" (Switch)
└── Dialog Footer
    └── buttons "Ações do formulário" (20 · @/buttons-container · "Campos marcados com * são obrigatórios.")
        ├── CANCEL "Cancelar" (Cancel Dialog)
        ├── CREATE "Criar empresa" (insert · se ID nulo)
        ├── SAVE "Salvar alterações" (update · se ID não nulo)
        └── DELETE "Remover" (delete · confirmação "Remover esta empresa? ..." · se ID não nulo)
```

## Lógica

- **Computations:** `P16_TITULO` (Before Header) = "Nova empresa"/"Editar empresa"; `P16_CEP` e `P16_TELEFONE` (After Submit) só com dígitos.
- **Validations:** `CNPJ com 14 dígitos` (10); `CNPJ não cadastrado` (15, compara só dígitos, ignora a própria empresa); `CEP com 8 dígitos` (20); `Telefone com DDD` (30, 10 ou 11 dígitos); `Empresa sem vínculos` (40, só no `DELETE`: percorre as FKs para `EMPRESA` em `user_constraints` com SQL dinâmico e bloqueia se houver linha).
- **Processes:** `Initialize form` (Before Header); `Process form` (Processing 10); `Close Dialog` (50, request em `CREATE,SAVE,DELETE`).
- **Dynamic Actions:** `Endereço por CEP` (keyup em `P16_CEP`) → `fetch` no ViaCEP e preenche o endereço; `Dados por CNPJ` (em `P16_CNPJ`, evento padrão) → `fetch` na BrasilAPI, só se 14 dígitos e sem `P16_ID_EMPRESA`.
- **JavaScript da página:** Page Load põe `P16_TITULO` no título do diálogo (`apex.util.getTopApex()...dialog("option","title",...)`).

## Dados

- Tabela `EMPRESA`; dicionário `user_constraints`/`user_cons_columns` na validação de remoção.
- APIs externas chamadas pelo navegador: `brasilapi.com.br/api/cnpj/v1/<cnpj>` e `viacep.com.br/ws/<cep>/json/`.
- Multiempresa: tela da plataforma, sem filtro; protegida por `EQUIPE_CORLIX_HUB`.

## Navegação

- Chega por: página 15 ("+ Nova empresa", clear 16; lápis ou nome fantasia, com `P16_ID_EMPRESA`).
- Vai para: fecha o diálogo; a página 15 atualiza o IR no `apexafterclosedialog`.

## Pegadinhas e pendências

- O título vem do JS do Page Load, não só do *Title* `&P16_TITULO.`: sem ele o cabeçalho do modal fica vazio ou com o título da abertura anterior (`Etapas-cadastro-empresa.md`, "Se não funcionar", 27/10/2026).
- `EMPRESA.COMPLEMENTO` precisa de 100 caracteres (`modulos/empresas/02_complemento_100.sql`); com 30, "Criar empresa" falha depois do preenchimento pela BrasilAPI (guia §0.1).
- O CNPJ é gravado com a máscara digitada; por isso a validação compara só os dígitos.
- O `08` §3 ainda diz que a página não tem autorização; este `.apx` tem `@administration-rights`.

## Referências

- [Guia do cadastro de empresa](../../../modulos/tema/Etapas-cadastro-empresa.md)
- [02 · Páginas, página 16](../02-paginas.md)
- [Página 15 · Empresas Cadastradas](./p00015-empresas-cadastradas.md)
