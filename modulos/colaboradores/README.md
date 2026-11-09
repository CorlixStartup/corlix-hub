# Módulo Colaboradores (Página 12)

> **Situação atual e histórico:** consulte [Registro de implantação](./Registro-implantacao.md). Páginas 12 e 14 validadas na app em 09/11/2026 (lista, acesso por perfil, edição). A criação de colaborador pelo RH e as demais pendências ficaram para o final do projeto: [Pendências](./Pendencias.md).

Módulo responsável pela página de listagem, busca e administração de colaboradores do Corlix Hub (**Página 12: `COLABORADORES`**).

Protótipo correspondente no `pen_dev/`:
- `pen_dev/Colaboradores · visão de administração.png` (descrito em [`docs/ai-context/07-design-pen-dev.md`](../../docs/ai-context/07-design-pen-dev.md) §4.4)

---

## 1. Visão geral e arquitetura

A página foi desenhada segundo o padrão **Faceted Search** + **Classic Report** do Oracle APEX 26.1:

```
Banco de dados (COLABORADOR, CARGO, DEPARTAMENTO, EMPRESA, CARGO_PAPEL)
   └─ View VW_COLABORADORES_LISTA (01_vw_colaboradores_lista.sql)
        └─ Página 12 no App Builder:
             ├─ Breadcrumb Bar: Região Dynamic Content "Cabeçalho" com título, subtítulo e botão "+ Novo colaborador" (para administradores/RH)
             ├─ Body (esquerda): Região Faceted Search "Filtros" com 5 facetas (Busca, Situação, Empresa, Departamento, Perfil de acesso)
             └─ Body (direita): Região Classic Report "Colaboradores" em card (.cx-relatorio) com avatares, links, vínculos, etiquetas e badges
```

## 2. Componentes da tela

1. **Cabeçalho (faixa branca)**:
   - Título: **Colaboradores**
   - Subtítulo: *Encontre pessoas e gerencie contas, vínculos e perfis de acesso.*
   - Ação: botão escuro (Hot) **+ Novo colaborador** (redireciona para a Página 14 com cache limpo). Visível para quem possui permissão de administração ou RH (`ADMIN_RH` ou `administration-rights`).

2. **Facetas (Faceted Search)**:
   - `Busca`: campo de busca textual sobre `NOME_COMPLETO, LOGIN_APEX, EMAIL` com placeholder *"Nome, login ou e-mail"*.
   - `Situação`: checkboxes com contagem para *Ativa* e *Inativa*.
   - `Empresa`: checkboxes com contagem por empresa (ou *Sem vínculo* para usuários não associados).
   - `Departamento`: checkboxes com contagem por departamento (*Operações*, *Vendas*, *Diretoria*, etc.).
   - `Perfil de acesso`: checkboxes com contagem por perfil principal (*Administrador*, *Publicador de conteúdo*, *Colaborador*).

3. **Tabela de resultados (Classic Report)**:
   - **Pessoa**: Avatar circular (foto ou iniciais com fundo azul-claro) + Nome em link azul + E-mail corporativo abaixo em cinza. Clique no nome abre o formulário de edição na Página 14.
   - **Login**: Login corporativo (`login_apex`).
   - **Vínculo**: Linha 1 com *Empresa · Departamento* e Linha 2 com *Cargo* em cinza. Caso o cadastro esteja incompleto, exibe o aviso em âmbar `⚠ Sem vínculo` com subtítulo *Cadastro incompleto*.
   - **Perfil**: Etiqueta cinza (`.cx-etiqueta`) para *Administrador* e *Publicador de conteúdo*, ou texto simples para *Colaborador*.
   - **Situação**: Badge com ponto colorido (`.cx-badge cx-badge--sucesso` para *Ativa*, `.cx-badge cx-badge--neutro` para *Inativa*).
   - **Paginação**: *Row Ranges X to Y of Z* ("1 – 8 de 8").

---

## 3. Arquivos do módulo

| Arquivo | Descrição |
|---|---|
| `00_fn_colab_tem_papel.sql` | Função de consulta de papéis via APEX_ACL; executar antes da view |
| `01_vw_colaboradores_lista.sql` | View `VW_COLABORADORES_LISTA` que alimenta o relatório e as facetas |
| `02_pkg_colaboradores_ui.pks` / `.pkb` | Cabeçalho em package de UI, com ação autorizada; instalar spec antes do body |
| `instalar.sql` | Script instalador para SQLcl ou SQL Workshop |
| `colaboradores.css` / `.min.css` | Estilos específicos para avatares, pessoa, vínculo e tabela |
| `Etapas-colaboradores.md` | Passo a passo detalhado para montagem no App Builder do APEX 26.1.5 |
| `Registro-implantacao.md` | Histórico de validações, decisões e evidências |
| `Pendencias.md` | Pendências deixadas para o final do projeto |

---

## 4. Como instalar e montar

1. Execute o script `instalar.sql` no banco de dados (ou execute `00_fn_colab_tem_papel.sql` e depois `01_vw_colaboradores_lista.sql` no *SQL Workshop* do APEX).
2. Siga as instruções do guia [`Etapas-colaboradores.md`](./Etapas-colaboradores.md) no App Builder.
