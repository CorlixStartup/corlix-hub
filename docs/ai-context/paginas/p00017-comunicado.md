# Página 17 · Novo comunicado

> **Estado em 13/11/2026** (backup `84f8625`): implementada, aplicada e testada. `modulos/comunicados/Etapas-comunicados.md`, "Situação": §4 aplicado, export validado (48/48), testes da §5 feitos (com publicação de teste apagada depois) e o `.apx` de DEV idêntico ao 8º export. Fica só o `;` opcional no fim da expressão da validação de imagem.

## Resumo

| Atributo | Valor |
|---|---|
| Alias | `COMUNICADO` |
| Modo | Modal Dialog, largura 680 (sem altura fixa) |
| Page template | `@/modal-dialog` (era *Wizard Modal Dialog*) |
| Autorização | **nenhuma** — qualquer usuário autenticado (só o botão da página 1 exige `@publicador-de-conteudo`) · `argumentsMustHaveChecksum` |
| CSS/JS de arquivo | `#APP_FILES#modulos/comunicados/comunicado#MIN#.css` |
| Módulo/guia | `modulos/comunicados/` (`Etapas-comunicados.md` §1, §2 e §4) |
| Protótipo | `pen_dev/Novo comunicado (diálogo).png` (`07` §4.2) |

Diálogo para publicar um comunicado da empresa da sessão: público (Todos ou um departamento), categoria, título, texto, imagem 16:9 opcional e "Fixar no topo".

## Estrutura

```
Page 17: Novo comunicado (modal)
├── Content Body
│   ├── aviso "Aviso" (5 · Static Content · @/blank-with-attributes · cx-comunicado)
│   │     <p class="cx-comunicado__aviso">Campos marcados com * são obrigatórios.</p>
│   └── step-1 "Emitir comunicado" (10 · Form em COMUNICADO · @/blank-with-attributes · cx-comunicado)
│       ├── P17_PUBLICO "Público" (8 · Radio Group TODOS/DEPARTAMENTO · default TODOS · sem coluna
│       │     · coluna cx-comunicado__publico, vira controle segmentado pelo CSS)
│       ├── P17_ID_COMUNICADO (10 · Hidden · PK · checksum de sessão)
│       ├── P17_ID_AUTOR (10 · Hidden · default: colaborador do APP_USER na G_ID_EMPRESA)
│       ├── P17_ID_EMPRESA (10 · Hidden · default item G_ID_EMPRESA · checksum de sessão)
│       ├── P17_ID_DEPARTAMENTO "Departamento destinatário" (10 · Select List · LOV lov-departamento-empresa)
│       ├── P17_ID_CATEGORIA "Categoria" (20 · Select List · LOV lov-categoria-comunicado · obrigatório)
│       ├── P17_TITULO "Título" (30 · Text · máx. 200 · obrigatório)
│       ├── P17_CONTEUDO "Comunicado" (40 · Textarea CLOB · obrigatório)
│       ├── P17_DATA_PUBLICACAO (50 · Hidden · default cast(systimestamp at time zone 'America/Sao_Paulo' as date))
│       ├── P17_IMAGEM "Imagem (opcional)" (60 · Image Upload · dropzone · recorte widescreen · 5 MB
│       │     · coluna BLOB IMAGEM, MIME_TYPE e NOME_ARQUIVO)
│       ├── P17_MIME_TYPE (70 · Hidden) · P17_NOME_ARQUIVO (80 · Hidden)
│       └── P17_FL_FIXADO "Fixar no topo" (70 · Checkbox S/N · default N)
└── Dialog Footer
    └── buttons "Buttons" (10 · @/buttons-container)
        ├── cancelar "Cancelar" (slot close · Cancel Dialog)
        └── PUBLICAR_COMUNICADO "Publicar comunicado" (slot next · hot · insert · sem aviso de alterações)
```

## Lógica

- **Computations:** `p17-id-departamento` (After Submit, se `P17_PUBLICO = TODOS`) → limpa `P17_ID_DEPARTAMENTO` (Static Value vazio).
- **Validations:** `Departamento obrigatório` (10, só com `DEPARTAMENTO`: "Escolha o departamento destinatário."); `Imagem PNG ou JPG` (20, se houver imagem: `regexp_like(:P17_IMAGEM, '\.(png|jpe?g)$', 'i')`).
- **Processes:** `Initialize form Emitir Comunicado` (Before Header); `processo-emissao-comunicado` (Processing 10, Form Automatic Row Processing em `COMUNICADO`, "Comunicado publicado."); `Fechar` (20, Close Dialog, só no `PUBLICAR_COMUNICADO`).
- **Dynamic Actions:** `Público` (change em `P17_PUBLICO`): `DEPARTAMENTO` → Show `P17_ID_DEPARTAMENTO`; senão Hide.
- **JavaScript da página:** —

## Dados

- Tabela `COMUNICADO` (colunas `ID_CATEGORIA` e `FL_FIXADO` dos scripts `01_ddl_categoria.sql` e `03_ddl_fixado.sql`); `CATEGORIA_COMUNICADO`, `DEPARTAMENTO`, `COLABORADOR` (autor).
- LOVs compartilhadas `lov-categoria-comunicado` e `lov-departamento-empresa`, as duas com `where id_empresa = :G_ID_EMPRESA`.
- Multiempresa: `P17_ID_EMPRESA` vem de `G_ID_EMPRESA` com checksum de sessão.

## Navegação

- Chega por: botão `NOVO_COMUNICADO` "Novo comunicado" da página 1 (clear 17, `@publicador-de-conteudo`). Não há entrada no menu lateral.
- Vai para: fecha o diálogo; a DA `Atualizar comunicados` da página 1 dá refresh no carrossel.

## Pegadinhas e pendências

- **Sem `authorizationScheme` na página:** quem não é publicador abre a URL e publica. O guia diz que "quem não tem empresa não abre a página", mas o `.apx` não tem regra para isso (não confirmado). Proteger a página exige tarefa própria (08 §1, regra 8).
- A hora é gravada como `00:00`: o formato de data da app (`DS`) se aplica ao item Hidden `P17_DATA_PUBLICACAO` (guia §4.10, passo 3; melhoria opcional).
- *File Types* não existe no Image Upload do 26.1.5; a checagem é a validação pela extensão. Uma versão anterior consultava `APEX_APPLICATION_TEMP_FILES` e deixava passar GIF, porque o item grava direto na coluna BLOB (guia, "Se não funcionar").
- A *Success Message* fica só no `processo-emissao-comunicado`; com ela no `Fechar`, aparecia "Row created. Comunicado publicado." (guia §4.10, passo 2).
- "Uma empresa" do protótipo ficou de fora (decisão do time, guia §4).
- As mensagens padrão do APEX ("... must have some value", "Crop Image") saem em inglês.
- A lista compartilhada `emitir-comunicado` (Steps 1 a 3 → páginas 17, 18, 19) é do wizard antigo e não é usada; 18 e 19 hoje são do histórico de carreira.
- O `02-paginas.md` (tabela) e o `08` §3 ainda descrevem o wizard antigo (`@/wizard-modal-dialog`, altura 600, sem Close Dialog, default `SYSDATE;`). Vale este `.apx`.

## Referências

- [Guia de comunicados, §4, §5 e Situação](../../../modulos/comunicados/Etapas-comunicados.md)
- [Guia da Home, §8.9](../../../modulos/home/Etapas-home.md)
- [07 · Design, §4.2](../07-design-pen-dev.md)
- [02 · Páginas, tabela-resumo](../02-paginas.md)
- [Página 1 · Início](./p00001-início.md)
