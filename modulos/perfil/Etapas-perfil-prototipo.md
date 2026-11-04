# Perfil · deixar a página 2 fiel ao protótipo

Este guia alinha a página 2 aos protótipos `pen_dev/Meu perfil (com trajetória).png`, `pen_dev/Meu perfil · aba Dados pessoais.png` e `pen_dev/Meu perfil · foto de perfil (Drawer).png`. Os caminhos são do **APEX 26.1.5**.

> **Pré-requisito:** a restrição de acesso de `Etapas-perfil-privacidade.md` já aplicada na app, inclusive `P2_ID_COLABORADOR` como **Per Request (Memory Only)**. O package deste guia mantém a mesma restrição.

Faça as três seções em sequência: entre a 1 e a 2, a página fica sem o cabeçalho.

## O que muda

| Parte | Hoje | Depois |
|---|---|---|
| Topo | Barra "Meu Perfil" e um card com o cabeçalho | Faixa branca de ponta a ponta, com avatar, nome, cargo, tempo de casa, e-mail e **Alterar foto** |
| Abas | Fora do card, com o texto ativo em azul | Dentro do card, com o texto ativo escuro e a linha azul |
| Trajetória | Vinda de `COLABORADOR_TRAJETORIA`, sem etiqueta de tipo e sem duração | Vinda do histórico de carreira, com etiquetas **Atual** e de tipo, período por extenso e duração |
| Dados pessoais | Rótulos em maiúsculas, sem aviso | Cadeado em nascimento e login, nota de visibilidade e alerta azul |
| Empresa | "Corlix" fixo no código | Nome da empresa da sessão |
| Gestor direto | Sem ações | Nome com link, **Conversar** e **Organograma** |
| Colegas | Lista inteira | Até 6 pessoas, "e mais N na equipe" e rodapé |
| Painel de foto | Janela central | Gaveta à direita, com alerta e botão **Salvar foto** escuro |

> **Se você já aplicou este guia antes da trajetória vir do histórico:** rode só o `.pkb` do §1 e faça os testes 10 a 13 do §4.

## 1. Banco: reinstalar o package

Em *SQL Workshop › SQL Scripts › Upload*, envie e rode um arquivo por vez, **nesta ordem**:

1. `modulos/perfil/02_pkg_perfil_prototipo.pks`
2. `modulos/perfil/02_pkg_perfil_prototipo.pkb`

Depois, no SQL Commands, sem `;` no final:

```sql
select object_name, object_type, status from user_objects
 where object_name = 'PKG_PERFIL' order by 2
```

Os dois devem estar `VALID`. Se algum estiver `INVALID`:

```sql
select line, position, text from user_errors
 where name = 'PKG_PERFIL' order by sequence
```

## 2. Static files: trocar o CSS

Em *Shared Components › Static Application Files*, envie estes dois arquivos, substituindo os atuais com o mesmo nome:

| Arquivo em `modulos/perfil/` | Substitui |
|---|---|
| `Meu Perfil.css` | `Meu Perfil.css` |
| `Meu Perfil.min.css` | `Meu Perfil.min.css` |

A página já referencia `#APP_FILES#Meu Perfil#MIN#.css`, então esse atributo não muda.

## 3. Builder: página 2

Em *App Builder › aplicação 100 › página 2 › Page Designer*:

### 3.1 Criar o cabeçalho

Clique com o botão direito em **Breadcrumb Bar** › **Create Region** (confirmar no 26.1.5) e ajuste:

| Grupo | Atributo | Valor |
|---|---|---|
| Identification | Name | `Cabeçalho do perfil` |
| Identification | Type | **Dynamic Content** |
| Source | Language | **PL/SQL** |
| Source | PL/SQL Function Body returning a CLOB | o código abaixo |
| Source | Page Items to Submit | `P2_ID_COLABORADOR` |
| Appearance | Template | **Blank with Attributes** |

```plsql
return pkg_perfil.render_cabecalho(to_number(:P2_ID_COLABORADOR default null on conversion error));
```

### 3.2 Apagar a barra antiga

Apague a região **Breadcrumb**, que também está em **Breadcrumb Bar**. Depois, salve a página.

A região **Perfil do Colaborador**, o item e o JavaScript da página ficam como estão.

## 4. Testar

Limpe o cache do navegador antes (`Cmd+Shift+R`). Compare com os protótipos e use uma conta comum, a do RH e, se puder, a de um gestor.

| # | Conta | Faça | Esperado |
|---|---|---|---|
| 1 | Colega | Abra **Meu perfil** | Faixa branca sem a barra "Meu Perfil", duas abas, etiqueta **Atual** e cards de gestor e colegas |
| 2 | Colega | Abra a aba **Dados pessoais** | Cadeado em nascimento e login, nota de visibilidade, alerta azul e o nome real da empresa |
| 3 | Colega | Clique em **Alterar foto** e na câmera | Gaveta à direita, com avatar, **Escolher foto** e alerta. **Cancelar** e o **×** fecham |
| 4 | Colega | Clique no nome do gestor e no de um colega | O perfil da pessoa, sem abas e sem **Alterar foto**, com o aviso de privacidade |
| 5 | Colega | Clique em **Conversar** e em **Organograma** | Abrem o Chat e o organograma focado no gestor |
| 6 | Gestor de equipe grande | Abra o perfil de alguém da equipe | Até 6 colegas e "e mais N na equipe" |
| 7 | RH | Abra o perfil de outra pessoa | As duas abas, sem **Alterar foto** |
| 8 | Qualquer uma | Confira a etiqueta de tipo e "Na … desde" | Texto legível, sem código como `PROMOCAO`, e o nome curto da empresa. Se vier estranho, mande um print |
| 9 | Qualquer uma | Reduza a janela até a largura de um celular | Sem rolagem horizontal; os cards ficam um embaixo do outro |
| 10 | Colega sem movimentações | Abra **Meu perfil** | Cargo atual com **Atual**, desde a admissão, e "Entrada na …" |
| 11 | Quem tem promoção | Abra **Meu perfil** | Um item por cargo, com a etiqueta **Promoção** e o período anterior terminando no mês certo |
| 12 | RH | Abra quem tem reajuste por mérito ou afastamento | Esses registros **não** aparecem na trajetória do perfil; continuam só no Histórico de carreira |
| 13 | RH | Compare com o Histórico de carreira da mesma pessoa | Os cargos e as datas batem |

Não clique em **Salvar foto**: esse botão ainda não tem ação no código.

## Se não funcionar

| Sintoma | Causa provável | Correção |
|---|---|---|
| `PLS-00201` citando `PKG_HISTORICO_CARREIRA` ou `PKG_ORGANOGRAMA` | Package ausente neste schema | Instale o módulo correspondente e rode o §1 de novo |
| `PLS-00323` no corpo do package | A especificação nova não foi instalada | Rode o `.pks` e depois o `.pkb` |
| Página sem cabeçalho | A região do §3.1 não foi criada ou está em outra posição | Confira o §3.1 |
| Layout antigo ou quebrado | Cache do navegador, ou CSS não substituído | `Cmd+Shift+R`. Confira os dois arquivos do §2 |
| Câmera e botão de foto não abrem | O JavaScript da página foi alterado | O guia não muda o JavaScript. Confira o evento `abrir-foto-drawer` na página |
| Clicar no nome do gestor dá erro de checksum | Link gerado fora do package | Confira se o `.pkb` novo está instalado |

## Voltar atrás

Rode `modulos/perfil/01_pkg_perfil.pkb` e a especificação anterior, em `database/ddl/08-plsql-especificacoes.sql`. Na página 2, apague a região do §3.1 e recrie a **Breadcrumb**. Restaure o CSS antigo a partir de `corlixhub/shared-components/static-files/`.

## Situação na app

Conferido com colaborador comum, depois da aplicação, lendo a estrutura e os estilos da página, sem comparar imagens:

- **OK, testes 1 a 5:** faixa do topo sem a barra antiga, abas no card, dados pessoais com cadeados, nota e alerta, nome real da empresa, gaveta de foto e links de gestor, colegas, Conversar e Organograma.
- **OK:** o perfil do gestor e o de um colega abrem sem abas, sem nascimento e sem botão de foto. Depois disso, **Meu perfil** volta para a própria pessoa.
- **OK:** lista de colegas limitada a 6, com "e mais 70 na equipe". Nenhum erro no console.
- **OK, trajetória vinda do histórico:** a conta mostra o cargo atual com **Atual**, área, período e duração, seguido de "Entrada na Corlix", e bate com o Histórico de carreira. O perfil de um colega continua sem trajetória.
- **Faltam:** os testes 6 e 7, o 9 (celular), a etiqueta de tipo do teste 8 e os testes 11 a 13.

## De onde vem a trajetória

- **Fonte:** `VW_MOVIMENTACAO_VALIDA` e `HISTORICO_CARREIRA`. Só entram registros efetivados, sem estorno e já vigentes.
- **O que vira item:** admissão, promoção, mudança de cargo e transferência de área, quando mudam o cargo ou a área. Desligamento encerra o período.
- **O que fica de fora:** mérito, afastamento, retorno, jornada, efetivação de contrato e mudança de gestão. Nenhum valor de salário é lido.
- **Quem vê:** a própria pessoa, a linha de gestão e o RH, a mesma regra do Histórico de carreira.
- **Sem histórico:** aparece o cargo atual, desde a admissão.

`COLABORADOR_TRAJETORIA` deixou de ser usada pela página e não foi apagada. Antes de apagá-la, confira se ela tem dados que não estão no histórico.

## O que fica diferente do protótipo

- **Recorte de foto:** o texto do protótipo promete ajustar o recorte quadrado. O recurso não existe, então a frase saiu.
- **Salvar foto:** o botão existe, mas continua sem ação. Depende da decisão sobre onde guardar as fotos (CD-73).
- **Colegas:** o protótipo só mostra uma pessoa. Com equipes grandes, a lista para em 6.
- **Conversar:** abre o Chat, como o atalho da Início, sem abrir a conversa com o gestor.
- **Descrição na trajetória:** o protótipo mostra uma descrição da função, que o sistema não guarda. No lugar dela aparece o motivo registrado pelo RH na movimentação, quando existe; muitas linhas ficam sem texto.
- **Itens do menu:** Avaliações, Resultados 360, Plano de desenvolvimento e Feedbacks não fazem parte deste guia.
