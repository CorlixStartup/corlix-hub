# Busca na intranet (página 29) · passo a passo no APEX

Este guia faz a barra **"Buscar na intranet..."** do header funcionar e cria a página de resultados, no App Builder do **APEX 26.1.5**, seguindo o protótipo [`pen_dev/Busca (resultados).png`](../../pen_dev/Busca%20(resultados).png) (descrição em `docs/ai-context/07-design-pen-dev.md` §4.17).

Como nos outros módulos, a mudança é feita no Builder e o backup diário traz o resultado para `corlixhub/` na `DEV`. Editar só o `.apx` do repositório não muda o app.

Passos marcados com **(confirmar no 26.1.5)** ainda não foram conferidos na tela desta versão. Se o caminho não existir, tire um print e registre o caminho certo neste guia.

### Como funciona

1. A região "Barra de Busca" da Global Page passa a ser gerada pelo `pkg_busca_ui.render_campo`. O campo já sai com a URL da página 29 (`apex_page.get_url`).
2. Ao apertar **Enter**, o campo leva a `.../busca?clear=29&session=...&p29_termo=<termo>`. O termo vai com `encodeURIComponent`, então espaços, acentos e símbolos chegam certos. Com o campo **vazio**, o Enter leva à página 29 sem termo e ela lista tudo. O `clear=29` limpa o termo anterior da sessão; sem ele, a busca vazia repetiria a última busca.
3. A página 29 mostra "Resultados para “termo”", a contagem e os cards **Pessoas** e **Comunicados**, mais o card "O que a busca encontra".

O que a busca procura:
- **Pessoas:** colaboradores **ativos** da empresa do usuário (`G_ID_EMPRESA`), por nome, cargo ou departamento. O nome leva ao Organograma já focado na pessoa; **Conversar** abre o Chat (página 4), como o botão do card Meu gestor. Não aparece "Conversar" na linha do próprio usuário.
- **Comunicados:** da empresa do usuário, por título ou texto (os primeiros 2.000 caracteres). O título leva a Comunicados (página 11).
- Maiúsculas e acentos não fazem diferença ("JOAO" acha "João"). Com termo, ele precisa de pelo menos 2 letras. **Busca vazia** lista todas as pessoas ativas e todos os comunicados da empresa. Cada grupo mostra até 20 linhas; acima disso, o rodapé do card avisa.

Fica para depois: o protótipo cita "Páginas do menu às quais você tem acesso". Isso exige ler a view do dicionário do APEX com as entradas do menu e checar a authorization de cada uma; o card de ajuda não promete esse grupo até ele existir.

### Arquivos do módulo

| Arquivo | O que é |
|---|---|
| `pkg_busca_ui.pks` / `.pkb` | Package que devolve o HTML do campo do header, do cabeçalho, dos resultados e da ajuda |
| `instalar.sql` | Instala o package pelo SQLcl |
| `busca-pagina.js` | JS da página 29 (carrega as fotos das pessoas, mesmo padrão da Início) |
| CSS | `custom.css` §13 (`cx-busca-*`), já em `corlixhub/shared-components/static-files/` |

---

## 1. Package

**SQLcl:** `cd modulos/busca` e `sql <usuario>@<servico> @instalar.sql`.

**Ou no Builder:** *SQL Workshop › SQL Scripts* (confirmar no 26.1.5) › suba e execute `pkg_busca_ui.pks` e depois `pkg_busca_ui.pkb`.

Conferência em *SQL Workshop › SQL Commands*:

```sql
select object_type, status from user_objects where object_name = 'PKG_BUSCA_UI';
```

Os dois (`PACKAGE` e `PACKAGE BODY`) devem estar `VALID`. Teste rápido:

```sql
select pkg_busca_ui.render_resultados(p_termo => 'ana', p_id_empresa => 1, p_login => 'X') from dual;
```

Deve voltar HTML com `cx-busca-card` (ou o estado vazio "Nenhum resultado para “ana”").

## 2. CSS

Suba o `custom.css` e o `custom.min.css` desta branch em *Shared Components › Static Application Files*, substituindo os atuais. Eles também trazem o CSS do header e do menu (`modulos/tema/Etapas-header-e-menu.md`). Recarregue com Ctrl+Shift+R.

## 3. Página 29 "Busca"

*Create Page* › **Blank Page** (confirmar no 26.1.5):

| Atributo | Valor |
|---|---|
| Page Number | `29` |
| Name | `Busca` |
| Page Mode | Normal |
| Navigation › Use Breadcrumb / Use Navigation | Não (a busca não é item de menu) |

Depois de criada, no nó da página:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Alias | `BUSCA` |
| Identification | Title | `Busca` |
| Security | Authentication | Page Requires Authentication |
| Security | Page Access Protection | **Unrestricted**: o termo chega pela URL, sem checksum. É seguro porque o termo só é usado como texto de busca e sai escapado no HTML |
| Navigation | Cursor Focus | Do not focus cursor |
| JavaScript › Function and Global Variable Declaration | | BLOCO 1 de `busca-pagina.js` |
| JavaScript › Execute when Page Loads | | BLOCO 2 de `busca-pagina.js` |

### 3.1 Regiões

Todas do tipo **Dynamic Content** (*PL/SQL Function Body returning a CLOB*), template **Blank with Attributes**:

| Name | Slot (Layout) | Source | Layout |
|---|---|---|---|
| Cabeçalho | **Breadcrumb Bar** | `return pkg_busca_ui.render_cabecalho(:P29_TERMO);` | Sequence 10 |
| Resultados | Body | `return pkg_busca_ui.render_resultados(:P29_TERMO);` | Sequence 10 · Column Span **8** |
| Ajuda | Body | `return pkg_busca_ui.render_ajuda;` | Sequence 20 · Start New Row **No** · Column Span **4** |

A região no slot Breadcrumb Bar fica dentro da faixa branca do topo (`.t-Body-title`), como no protótipo.

### 3.2 Item P29_TERMO

Na região **Cabeçalho**, crie o item:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `P29_TERMO` |
| Identification | Type | **Hidden** |
| Settings | Value Protected | **Off** |
| Security | Session State Protection | **Unrestricted** (confirmar no 26.1.5) |

Sem *Value Protected* desligado e *Unrestricted*, o APEX recusa o valor que vem pela URL.

### 3.3 Como deve ficar a árvore

```
Page 29: Busca
├── Breadcrumb Bar
│   └── Cabeçalho              (Dynamic Content)
│       └── P29_TERMO          (Hidden)
└── Body
    ├── Resultados             (Dynamic Content, span 8)
    └── Ajuda                  (Dynamic Content, span 4)
```

## 4. Campo de busca do header (página 0)

Abra a **página 0** e selecione a região **Barra de Busca** (slot *After Logo*):

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Type | **Dynamic Content** (era Static Content) |
| Source | PL/SQL Function Body returning a CLOB | `return pkg_busca_ui.render_campo;` |

Não mexa no template nem nas Template Options. O HTML antigo (com o `<input id="P0_SEARCH_GLOBAL">`, que não era item do APEX e não fazia nada) sai junto com a troca de tipo.

O link depende das **friendly URLs** (`/r/corlixhub/corlixhub/...`), que o app já usa: o termo vai como `&p29_termo=...` (confirmar no 26.1.5).

---

## 5. Teste

Saia e entre de novo, recarregue com Ctrl+Shift+R e confira:

1. Em qualquer página, digite um nome no campo do header e aperte **Enter**: abre a página 29 com "Resultados para “nome”" e a contagem.
2. O campo continua preenchido com o termo na página 29.
3. **Pessoas:** avatar (foto ou iniciais), nome em azul, "Cargo · Departamento" e **Conversar**. Clique no nome: abre o Organograma focado na pessoa. Na sua própria linha não aparece Conversar.
4. **Comunicados:** etiqueta "Para: …", data, título em azul e resumo. Clique no título: abre Comunicados.
5. Busque sem acento um nome com acento (ex.: `joao` para "João"): acha.
6. Busque um termo que não existe: card "Nenhum resultado para “…”".
7. Digite uma letra só e Enter: "Digite pelo menos 2 letras."
8. Apague o campo e aperte Enter: "Buscar na intranet", a contagem total e os cards com todas as pessoas ativas e todos os comunicados (até 20 de cada, com o aviso no rodapé). O campo fica vazio, sem repetir a busca anterior.
9. Busque um departamento (ex.: `vendas`): aparecem as pessoas do departamento e os comunicados para ele.
10. Com um usuário sem empresa: "Nenhum resultado" e a explicação sobre o vínculo.

### Se não funcionar

| Sintoma | Causa provável | Correção |
|---|---|---|
| `ORA-06550` / `PLS-00201: identifier 'PKG_BUSCA_UI' must be declared` | Package não instalado | Passo 1 |
| `ORA-06502: character string buffer too small` em `PKG_BUSCA_UI`, line 10, em **todas** as páginas (região do header) | Versão antiga do body: as constantes com letras acentuadas eram `varchar2(30)` em bytes, e em UTF-8 cada acento ocupa 2 bytes; o erro acontece ao carregar o package | Recompile o `pkg_busca_ui.pkb` atual (tamanhos em `char`) |
| Enter não faz nada | A região "Barra de Busca" ainda é Static Content | Passo 4 |
| Busca vazia mostra os resultados da busca anterior | Body antigo do package (URL sem `clear=29`) | Recompile o `pkg_busca_ui.pkb` atual |
| Enter recarrega a página atual em vez de ir para a busca | O HTML do campo é o antigo (sem o `onkeydown`), ou há cache | Passo 4 e Ctrl+Shift+R |
| A página 29 abre com "Buscar na intranet" mesmo com termo na URL | `P29_TERMO` com Value Protected ligado ou Session State Protection restrita | Passo 3.2 |
| Erro de checksum ao abrir a página 29 | Page Access Protection diferente de Unrestricted | Passo 3 |
| Cabeçalho aparece no corpo, e não na faixa branca do topo | Região Cabeçalho fora do slot Breadcrumb Bar | Passo 3.1 |
| Lupa colada na borda esquerda e campo deslocado para a direita | `custom.css` antigo: a regra `.apex-icons-fontapex .fa { position: relative }` do Core do UT vencia a da lupa | Passo 2 (a regra nova usa `.corlix-header__search .corlix-header__search-icon`) |
| Cards sem borda e textos sem estilo | `custom.css` antigo no app ou em cache | Passo 2 |
| Só iniciais, sem fotos | JS da página 29 ausente | Passo 3, blocos de `busca-pagina.js` |
| Pessoas e comunicados vazios para todo mundo | `G_ID_EMPRESA` vazio na sessão (só é preenchido no login) | Saia e entre de novo |
