# Isolamento entre empresas · correções da auditoria

Este guia corrige o que a auditoria de 07/11/2026 achou na CD-61: telas que mostram ou alteram dados de outra empresa. Os caminhos são do **APEX 26.1.5**.

| Prioridade | Onde | O que acontece hoje | Seção |
|---|---|---|---|
| **Alta** | Organograma (página 3) e perfil (página 2) | O painel de detalhe aceita o ID de qualquer pessoa e devolve nome, cargo, área, e-mail, admissão e aniversário. A busca lista pessoas de todas as empresas. Sem foco válido, o organograma abre pela raiz do banco inteiro | 2 |
| **Alta** | Central de Equipes e Nova Equipe (páginas 26 e 27) | Lista equipes, pessoas, departamentos e empresas de todas as empresas, e deixa criar ou editar equipe em qualquer uma | 3 e 4 |
| Média | Monitor de Logs (página 7) | O RH de uma empresa vê os logs da app inteira | 5 |
| Média | Movimentação e Formação (páginas 18 e 21) | O formulário carrega o registro só pelo ID; hoje quem protege é o checksum da URL | 6 |

O que já estava isolado e não muda: Início, Busca, Holerite, Ponto, Histórico de carreira, Dashboard RH, Chat, Cadastro de usuários e Meu perfil (dados pessoais).

## 1. Conferir os dados antes

No SQL Commands, um comando por vez, sem `;` no final. Os dois devem responder **nenhuma linha**:

```sql
select c.id_colaborador, c.id_empresa, g.id_empresa as empresa_do_gestor
  from colaborador c
  join colaborador g on g.id_colaborador = c.id_gestor
 where g.id_empresa <> c.id_empresa
```

```sql
select upper(trim(login_apex)) as login, count(*)
  from colaborador
 where login_apex is not null
 group by upper(trim(login_apex))
having count(*) > 1
```

| Se aparecer | Efeito | O que fazer |
|---|---|---|
| Gestor de outra empresa | O organograma corta a pessoa da árvore da empresa dela | Corrija o gestor pelo Histórico de carreira, com uma mudança de gestão |
| Login repetido | A pessoa entra sem empresa na sessão, e quase nenhuma tela mostra dados | Deixe cada login em uma só empresa. Avise antes, porque pode ser conta de teste |

## 2. Banco: organograma e perfil

Em *SQL Workshop › SQL Scripts › Upload*, envie e rode:

1. `modulos/isolamento-empresas/01_vw_org_colaborador_empresa.sql`

A view `VW_ORG_COLABORADOR` passa a devolver só a empresa da sessão e ganha a coluna `ID_EMPRESA`. Isso corrige de uma vez o painel de detalhe, a navegação, a busca da página 3 e o gestor e os colegas do perfil, porque todos leem dessa view. Sem empresa na sessão, ela não devolve ninguém.

Confira, sem `;` no final:

```sql
select object_name, object_type, status from user_objects
 where object_name in ('VW_ORG_COLABORADOR', 'PKG_ORGANOGRAMA', 'PKG_PERFIL') order by 1, 2
```

Todos devem estar `VALID`. No SQL Commands, a consulta `select count(*) from vw_org_colaborador` dá `0`: lá não há sessão da app, e isso é o esperado.

## 3. Builder: listas usadas pelas Equipes

Em *Shared Components › List of Values*, as três listas abaixo leem a tabela inteira e só são usadas nas páginas 26 e 27. Em cada uma, mude **Source › Type** para **SQL Query** e cole a consulta:

| List of Values | SQL Query |
|---|---|
| `COLABORADOR.NOME_COMPLETO` | `select nome_completo d, id_colaborador r from colaborador where id_empresa = :G_ID_EMPRESA order by nome_completo` |
| `DEPARTAMENTO.NOME` | `select nome d, id_departamento r from departamento where id_empresa = :G_ID_EMPRESA order by nome` |
| `EMPRESA.NOME` | `select nome d, id_empresa r from empresa where id_empresa = :G_ID_EMPRESA` |

Em **Column Mapping**, use **Return** = `R` e **Display** = `D`.

## 4. Builder: Central de Equipes e Nova Equipe

### 4.1 Página 26

Na região **Central de Equipes**, em **Source › Where Clause**:

```sql
ID_EMPRESA = :G_ID_EMPRESA
```

### 4.2 Página 27

1. Na região **Nova Equipe**, em **Source › Where Clause**, use a mesma linha do §4.1.
2. No item `P27_ID_EMPRESA`, em **Default**, escolha **Type** = **Item** e **Item** = `G_ID_EMPRESA`.
3. Crie três validações em *Processing › Validations*, cada uma do tipo **Rows returned**:

| Name | SQL Query | Error Message | Associated Item |
|---|---|---|---|
| `Equipe da empresa` | `select 1 from dual where :P27_ID_EQUIPE is null or exists (select 1 from equipe where id_equipe = :P27_ID_EQUIPE and id_empresa = :G_ID_EMPRESA)` | Equipe não encontrada. | — |
| `Empresa da sessão` | `select 1 from dual where :P27_ID_EMPRESA = :G_ID_EMPRESA` | Empresa inválida. | `P27_ID_EMPRESA` |
| `Departamento e criador da empresa` | `select 1 from dual where (:P27_ID_DEPARTAMENTO is null or exists (select 1 from departamento where id_departamento = :P27_ID_DEPARTAMENTO and id_empresa = :G_ID_EMPRESA)) and (:P27_ID_CRIADOR is null or exists (select 1 from colaborador where id_colaborador = :P27_ID_CRIADOR and id_empresa = :G_ID_EMPRESA))` | Departamento ou criador de outra empresa. | — |

Salve as duas páginas.

## 5. Builder: Monitor de Logs

Na página 7, clique no nome da página e mude **Security › Authorization Scheme** para **EQUIPE_CORLIX_HUB**.

Os logs são da app inteira, de todas as empresas, e mostram usuários e IDs de sessão. Por isso, ficam com a equipe do Corlix Hub. O RH perde o acesso a essa página.

## 6. Builder: formulários das páginas 18 e 21

Na região do formulário, em **Source › Where Clause**:

| Página | Região | Where Clause |
|---|---|---|
| 18 | **Movimentação** | `id_empresa = :G_ID_EMPRESA` |
| 21 | Formulário de formação | `id_empresa = :G_ID_EMPRESA` |

Isso não muda nada para quem usa a tela pelos links. Só impede que um ID de outra empresa seja carregado.

## 7. Testar com duas empresas

Precisa de uma segunda empresa com pelo menos dois colaboradores e uma conta para um deles. Se ela ainda não existir, crie pela página 16, com a equipe do Corlix Hub, e cadastre as pessoas pela página 14, com um RH dessa empresa.

| # | Conta | Faça | Esperado |
|---|---|---|---|
| 1 | Empresa 1 | Abra o Organograma e use a busca de pessoa | Só pessoas da empresa 1 |
| 2 | Empresa 2 | Abra o Organograma | Começa pela raiz da empresa 2, sem ninguém da empresa 1 |
| 3 | Empresa 2 | Peça ao Claude o teste do painel de detalhe com um ID da empresa 1 | "Esta pessoa não está mais disponível no organograma." |
| 4 | Empresa 1 | Abra o perfil de um colega e veja o card de gestor e colegas | Só pessoas da empresa 1 |
| 5 | Empresa 2 | Abra a Central de Equipes | Só equipes da empresa 2 |
| 6 | Empresa 2 | Abra **Nova Equipe** | As listas mostram só pessoas, departamentos e a empresa 2 |
| 7 | RH da empresa 1 | Abra o Monitor de Logs | Acesso negado |
| 8 | Equipe do Corlix Hub | Abra o Monitor de Logs | Abre normalmente |
| 9 | RH da empresa 1 | Abra uma movimentação e uma formação pelos links | Abrem normalmente |

## Se não funcionar

| Sintoma | Causa provável | Correção |
|---|---|---|
| Organograma e perfil vazios para todo mundo | `G_ID_EMPRESA` vazio na sessão | Veja o §1, sobre login repetido. Saia e entre de novo |
| `INVALID` em `PKG_ORGANOGRAMA` ou `PKG_PERFIL` | O pacote não recompilou | Rode `alter package pkg_organograma compile body` e o mesmo para `pkg_perfil`. Se continuar, mande o `user_errors` |
| Pessoa some do organograma | Gestor de outra empresa | Veja o §1 |
| Lista da Nova Equipe vazia | A consulta da lista foi colada com erro | Confira o §3 |
| Página 18 ou 21 dá "No data found" ao abrir pelo link | Registro de outra empresa, ou erro no Where Clause | Confira o texto do §6 |

## Voltar atrás

Rode o `create or replace view` de `database/ddl/06-views.sql` para `VW_ORG_COLABORADOR` e recompile os dois pacotes. Nas páginas, desfaça os §3 a §6.

## Fica para depois (CD-61)

Pontos que não vazam com o uso atual da app, mas ficam frágeis se o código mudar:

- **Parâmetros públicos sem conferência:** `PKG_PONTO_UI.render_comprovantes`, `PKG_HOLERITE_UI` e `PKG_BUSCA_UI` aceitam ID ou empresa como parâmetro sem comparar com a sessão.
- **`PKG_HOLERITE.gerar_folha_mensal` e `render` antigos:** geram e leem holerites de todas as empresas. Nenhuma página chama, mas continuam no banco.
- **Hierarquia sem restrição de empresa:** `fn_pode_ver_colaborador` filtra a empresa só depois do `CONNECT BY`, e nenhuma constraint impede gestor de outra empresa.
- **Log salarial:** `registrar_acesso_salarial` não confere a empresa.
- **Login repetido:** nenhuma constraint impede o mesmo login em duas empresas.
- **Pacotes fora do APEX:** sem sessão e sem `definir_empresa_contexto`, as checagens deixam passar. Não é alcançável pela app hoje.
