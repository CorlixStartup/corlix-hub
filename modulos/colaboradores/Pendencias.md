# Colaboradores · Pendências para o final do projeto

> Registradas em 09/11/2026, ao encerrar a validação das páginas 12 e 14. Por decisão da usuária, ficam para o final do projeto. As evidências estão no [Registro de implantação](./Registro-implantacao.md), e os casos de erro no §13.6 do [guia](./Etapas-colaboradores.md).

O que já está validado na app: lista, filtros, acesso por perfil, edição na página 14, ajustes visuais e bloqueio de colaborador comum. Os itens abaixo não impedem o uso da lista nem da edição.

| # | Pendência | Tipo | Quem decide ou faz | Situação |
|---|---|---|---|---|
| 1 | Criação de colaborador pelo RH | Arquitetura | Time | Bloqueada |
| 2 | Bloqueio de conta inativa | Segurança | Time | Aberta |
| 3 | Papel `gestor` no cargo 403 (Supervisor de Vendas) | Acesso | Time | Aberta |
| 4 | Cargo de Eduardo Vieira (id 272) | Dados | RH | Aberta |
| 5 | Testes de gestor, caracteres especiais e tela estreita | Teste | Agente, com login da usuária | Aberta |

## 1. Criação de colaborador pelo RH

**Problema:** ao criar um colaborador com a TESTE.RH, a página 14 mostra `User TESTE.RH requires ADMIN privilege to perform this operation.` O processo "Criar usuário APEX" usa `APEX_UTIL.CREATE_USER`, que dentro de uma app exige que o usuário logado seja administrador do workspace. Nada fica gravado.

**Opções (nenhuma validada):**
1. RH como administrador do workspace. **Não recomendado:** dá acesso ao Builder.
2. RH cadastra o colaborador, e um administrador cria a conta e os papéis no APEX. A página 14 precisa deixar de chamar `CREATE_USER` quando quem salva não é administrador. **Sugestão do agente.**
3. Criar a conta fora da sessão do RH, por fila e processo de banco. Precisa de pesquisa e pode exigir `CREATE JOB`, que já faltou no Suporte TI.
4. Trocar a autenticação, com tabela própria ou login externo. Mudança grande.

**Para fechar:** o time escolhe a opção, o agente escreve o passo a passo, e o teste de criação é refeito com a TESTE.RH, conferindo conta, papéis, admissão e a mensagem "Dados salvos. Colaborador cadastrado com sucesso!".

## 2. Bloqueio de conta inativa

**Problema:** o [DEMO] Diego Alves (id 315) está Inativo, mas a conta `DEMO.CARREIRA.1.4` entrou no sistema em 09/11/2026. Inativar o colaborador não bloqueia a conta APEX (§12.11 do guia): `APEX_UTIL.LOCK_ACCOUNT` também exige administrador do workspace. Não se sabe como essa conta foi criada, porque ela não existia no teste anterior.

**Para fechar:** definir como bloquear o acesso. Pode ser uma checagem da situação na autenticação ou na autorização, ou o bloqueio manual da conta por um administrador. Depois, testar com uma conta inativa.

## 3. Papel `gestor` no cargo 403

**Situação:** o Supervisor de Vendas tem 2 ocupantes (João Oliveira e Ricardo Freitas), que lideram 60 pessoas, mas o cargo não tem o papel `gestor`. A exibição do nome na edição já foi corrigida pela LOV (§13.5). Incluir o papel daria aos dois acesso à lista e os colocaria como opção de Gestor em novos cadastros. Há precedente: `Supervisor(a) de Atendimento` tem o papel.

**Para fechar:** o time decide. Se aprovar, rodar `insert into cargo_papel (id_cargo, cd_papel) values (403, 'gestor')` e confirmar como o papel chega às contas, porque o processo "Atribuir papéis do cargo" pode rodar só na criação.

## 4. Cargo de Eduardo Vieira (id 272)

**Situação:** Eduardo está no cargo 506 (Técnico de Logística, 147 ocupantes) e é gestor de 7 pessoas. Pode ser cargo desatualizado ou gestor gravado errado. **Não** incluir o papel `gestor` no cargo 506.

**Para fechar:** o RH confere e corrige o cargo dele ou o gestor dos 7 liderados.

## 5. Testes de acompanhamento

| Teste | O que conferir |
|---|---|
| Gestor | Conta com o papel `gestor` vê a lista sem editar (regra do §12) |
| Caracteres especiais | Nome com acento, apóstrofo e `<` aparece escapado na lista e na edição |
| Tela estreita | Barra, filtros e tabela sem corte nem rolagem horizontal da página |

**Para fechar:** a usuária faz login com cada conta, e o agente valida na tela sem gravar dados, salvo autorização em registro `[DEMO]`.
