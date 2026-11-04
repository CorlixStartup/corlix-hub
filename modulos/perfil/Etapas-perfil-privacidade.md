# Perfil · restringir dados pessoais (página 2)

Este guia corrige a falha achada na auditoria de LGPD de 04/11/2026 ([CD-73](https://corlix.youtrack.cloud/issue/CD-73)): pelo organograma, "Ver perfil completo" mostra a qualquer colega a data de nascimento completa, o login, a admissão e a trajetória de outra pessoa. Os caminhos são do **APEX 26.1.5**.

São dois passos: reinstalar um package e pôr uma autorização na página 2. Nenhuma tabela muda, e o JavaScript da página fica como está.

## Quem vê o quê

| Quem abre o perfil | Nome, cargo, área, e-mail, admissão no cabeçalho, gestor e colegas | Trajetória e dados pessoais | Alterar foto |
|---|---|---|---|
| A própria pessoa | Sim | Sim | Sim |
| Gestor, em qualquer nível acima | Sim | Sim | Não |
| RH (`ADMIN_RH`) | Sim | Sim | Não |
| Colega, inclusive subordinado ou par | Sim | **Não** | **Não** |
| Outra empresa | "Colaborador não encontrado." | Não | Não |

A regra de quem vê é a mesma do histórico de carreira: `pkg_historico_carreira.fn_pode_ver_colaborador`. O que continua aberto a colegas é o que o painel do organograma já mostra a eles.

## 1. Banco: reinstalar o corpo do package

Em *SQL Workshop › SQL Scripts › Upload*, envie e rode:

1. `modulos/perfil/01_pkg_perfil.pkb`

A especificação não muda. Depois, no SQL Commands, sem `;` no final:

```sql
select object_name, object_type, status from user_objects
 where object_name = 'PKG_PERFIL' order by 2
```

Os dois devem estar `VALID`. Se o corpo estiver `INVALID`:

```sql
select line, position, text from user_errors
 where name = 'PKG_PERFIL' order by sequence
```

## 2. Builder: autorização da página 2

Em *App Builder › aplicação 100 › página 2 › Page Designer*, clique no nome da página, à esquerda, e ajuste:

| Grupo | Atributo | Valor |
|---|---|---|
| Security | Authorization Scheme | **COLABORADOR** |

Salve. Quem é `ADMIN_RH` também passa nesse esquema.

## 3. Testar

Use três contas: a pessoa consultada, um colega sem relação de gestão com ela e o RH (`TESTE.RH`). Se puder, use também o gestor dela. Abra o perfil sempre pelo organograma: clique na pessoa e depois em **Ver perfil completo**.

| # | Conta | Faça | Esperado |
|---|---|---|---|
| 1 | Colega | Abra o perfil de outra pessoa | Cabeçalho, gestor e colegas. Sem abas **Trajetória** e **Dados pessoais**, sem nascimento e sem login. Aparece o aviso "A trajetória e os dados pessoais ficam visíveis só para a própria pessoa, a gestão e o RH." |
| 2 | Colega | Procure **Alterar foto** nesse perfil | Nem o botão nem a câmera aparecem |
| 3 | Colega | Abra **Minha carreira › Meu perfil** | As duas abas e **Alterar foto** |
| 4 | Colega | Clique em **Alterar foto** no próprio perfil | O painel abre com **Escolher foto**. Antes ele podia ficar carregando sem parar |
| 5 | Gestor | Abra o perfil de alguém da equipe | As duas abas, sem **Alterar foto** |
| 6 | RH | Abra o perfil de outra pessoa | As duas abas, sem **Alterar foto** |

Não clique em **Salvar foto**: esse botão ainda não tem ação no código.

## Se não funcionar

| Sintoma | Causa provável | Correção |
|---|---|---|
| `PLS-00201` citando `PKG_HISTORICO_CARREIRA` ou `PKG_ORGANOGRAMA` | Package ausente neste schema | Instale o módulo correspondente e rode o §1 de novo |
| Todo perfil diz "Colaborador não encontrado." | `G_ID_EMPRESA` vazio na sessão, ou o login não bate com `COLABORADOR.LOGIN_APEX` nessa empresa | Saia e entre de novo. Depois confira o login da conta |
| Página 2 diz "Sua conta não está vinculada a um colaborador desta empresa." | A conta não tem colaborador na empresa da sessão, e o esquema do §2 a barrou | Corrija o `LOGIN_APEX` do colaborador |
| Colega ainda vê a aba **Dados pessoais** | O corpo novo não foi instalado, ou a conta tem `ADMIN_RH` ou é gestora da pessoa | Rode o §1 de novo e confira os papéis da conta |
| Erro ao abrir o perfil, citando `-20012` ou "não está vinculada a uma empresa" | Sessão sem empresa | Saia e entre de novo |

## Voltar atrás

O corpo anterior está em `database/ddl/09-plsql-corpos.sql`, entre `CREATE OR REPLACE EDITIONABLE PACKAGE BODY "PKG_PERFIL"` e `end pkg_perfil;`. Rode esse trecho e limpe a autorização do §2.

## Fora deste guia

Continuam na CD-73:

- **Fotos:** os arquivos em `Fotos Colaboradores` abrem sem login.
- **Salvar foto:** o botão não tem ação. Ao ligá-lo, valide no servidor que a foto é da própria pessoa.
- **Empresa fixa:** o perfil mostra "Corlix" escrito no código, em "Empresa" e em "Entrada na Corlix".
- **Organograma:** `VW_ORG_COLABORADOR` não tem `ID_EMPRESA`, e a página 3 não filtra por empresa (CD-61).
