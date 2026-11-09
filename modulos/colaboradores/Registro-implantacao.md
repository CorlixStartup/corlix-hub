# Colaboradores — registro de implantação e pendências

Registro da sessão de montagem e revisão da página 12, em 08/11/2026. Base consultada: DEV a2e3c4b, com backup e33f972 de 08/11/2026 às 23:17. Relatos posteriores do Builder podem ainda não aparecer nesse export.

## Situação atual

A página possui Classic Report, Faceted Search, cabeçalho e CSS. A função de ACL e a view corrigida aparecem no backup. **A página não está integralmente validada.** O usuário informa que o botão Novo colaborador não está funcionando visualmente como esperado; a configuração atual desse botão após as tentativas ainda precisa ser inspecionada. Não foi feita alteração direta na app pelo agente.

## O que foi feito e qual é a evidência

| Etapa | Trabalho e resultado | Estado |
|---|---|---|
| Branch inicial | Localizada e selecionada feature/pagina-colaboradores | Concluído |
| HTML de Pessoa | O guia misturava Type = Link e HTML Expression. Corrigido para Link Text, sem âncora interna nem &LINK. | PR #126 integrado; export confirma Link Text |
| Ordenação | Retirado ORDER BY da consulta do relatório; ordenação inicial configurada na coluna de nome | Export da página confirma consulta sem ORDER BY e defaultSequence = 1 |
| Erro Ajax em Filtros | ORA-00904 em APEX_260100.WWV_FLOW_SECURITY ao contar facetas | Reproduzido pelo usuário; diagnóstico abaixo |
| Função de ACL | Criada FN_COLAB_TEM_PAPEL baseada em APEX_ACL.HAS_USER_ROLE | Teste isolado passou; função presente no backup |
| View | Subconsultas diretas à ACL substituídas pela função em PERFIL e PERFIL_HTML, preservando regras de cargo | PR #127 integrado; database/ddl/06-views.sql confirma implantação |
| CSS | Página aponta para #APP_FILES#modulos/colaboradores/colaboradores#MIN#.css | Arquivos normal e minificado registrados no backup |
| Revisão da página | Conferidos SQL, facetas, links, autorização, paginação e HTML | Revisão estática; não equivale a teste visual |
| Guia de validação | PR #129 propôs ajustes de autorização, escape, layout e paginação | Aberto na consulta desta sessão; contém recomendações posteriormente revistas |
| Botão nativo | Sugerido botão com destino p14, ADMIN_RH, Hot e Text with Icon, retirando o link gerado no PL/SQL | Tentativa não validada; usuário relata que não está dando certo |
| Lucide | Conferido mapeamento fa-plus para Lucide Plus em corlix-tema.css | Confirmado no código; não foi necessário instalar biblioteca |

PRs: [#126](https://github.com/CorlixStartup/corlix-hub/pull/126), [#127](https://github.com/CorlixStartup/corlix-hub/pull/127), [#129](https://github.com/CorlixStartup/corlix-hub/pull/129).

## Diagnóstico do erro das facetas

1. Leitura de PERFIL na view funcionou e retornou Colaborador nas cinco linhas apresentadas.
2. Consulta de ROLE_STATIC_ID em APEX_APPL_ACL_USER_ROLES funcionou, retornando diretoria, publicador-de-conteúdo, equipe-do-corlix-hub, colaborador e gestor.
3. Debug mostrou SQL gerada pelo Faceted Search com GROUPING SETS de SITUACAO, EMPRESA, DEPARTAMENTO e PERFIL.
4. Consulta reduzida com esses campos reproduziu ORA-00904.
5. A mesma agregação sem PERFIL funcionou.
6. Tentativa de impedir transformação com ROWNUM e filtro externo também falhou: não reutilizar como correção comprovada.
7. Função PL/SQL consultando APEX_ACL.HAS_USER_ROLE foi criada; agregação sobre o retorno funcionou: TEM_PAPEL = 0 para 309 registros, mais a linha de total 309.
8. SQL da view, instalador e guia foram atualizados para usar a função antes da view.

A causa interna exata do Oracle não foi comprovada. O teste isolou a dependência do cálculo de PERFIL na agregação; não demonstrou ausência de papéis. Os 309 zeros não validam a classificação. O backup comprova instalação, mas ainda é necessário confirmar filtros combinados e usuários com papéis conhecidos dentro da app 100.

## Revisão das recomendações anteriores

- **Não aplicar automaticamente ADMIN_RH à página 12 inteira.** A lista está em Pessoas e consulta não é a mesma permissão que cadastro. A recomendação anterior alteraria o acesso existente sem confirmar o requisito.
- **Não reinstalar ACL nem CSS já presentes no backup.** Os PRs de documentação não determinam sozinhos o estado instalado.
- **Não tratar a ordem das regiões como defeito visual comprovado.** Export mostra relatório com sequência 10 e filtros com 20; só alterar se a apresentação estiver incorreta e depois de conferir o template.
- **Não declarar edição na página 14 pronta.** Ela recebe o ID, mas o processo CREATE_USER disponível não está condicionado apenas à inclusão. Carregar dados não comprova salvamento seguro.
- **Não inferir autorização pela ausência de empresa.** A equipe Corlix possui contas sem vínculo, mas a regra deve reconhecer a autorização explicitamente. A view também permite todas as empresas quando G_ID_EMPRESA é nulo: separar política de equipe e sessão incompleta.
- **Não trocar estratégia de cabeçalho sem conferir outro módulo.** A sugestão de botão nativo não confirmou como ocupar o espaço de ações do HTML retornado pelo cabeçalho.

## Botão Novo colaborador: estado e retomada

O protótipo mostra botão escuro, texto branco, sinal de mais à esquerda e alinhamento à direita do título. O cabeçalho original gera o link dentro de cx-cabecalho-pagina__acoes, com URL via apex_page.get_url.

A alternativa nativa foi sugerida para permitir Authorization Scheme no próprio botão. O problema atual não foi diagnosticado: faltam export ou print da configuração mais recente e do resultado. Não afirmar que Hot, fa-plus ou uma posição não conferida resolvem o alinhamento.

### Referências reutilizadas

| Referência | O que conferir/reutilizar |
|---|---|
| [Holerite — package UI](../holerite/02_pkg_holerite_ui.pkb), render_cabecalho | Cabeçalho e ações no mesmo HTML; classes cx-cabecalho-pagina, __texto e __acoes; botões e SVGs; condições de renderização |
| [Holerite — guia](../holerite/Etapas-holerite.md) | Integração entre região, package, CSS/JS e validações na app |
| [Ponto — package UI](../ponto-eletronico/04_pkg_ponto_ui.pkb), render_cabecalho | Ações Baixar espelho e Solicitar ajuste dentro do cabeçalho; links com checksum e escape de atributo |
| [Ponto — guia](../ponto-eletronico/Etapas-ponto-eletronico.md) e [validação](../ponto-eletronico/Etapas-ajustes-validacao.md) | Padrões de integração e registro de testes |
| [Histórico — UI](../historico-carreira/08_pkg_historico_carreira_ui.sql) e [guia](../historico-carreira/Etapas-historico-carreira.md) | Padrões existentes de renderização, navegação e separação de responsabilidades |
| [Tema](../../docs/ai-context/04-tema-e-estilos.md) | Tokens, Lucide e classes existentes; evitar CSS duplicado |
| [Protótipo](../../pen_dev/Colaboradores%20%C2%B7%20vis%C3%A3o%20de%20administra%C3%A7%C3%A3o.png) | Resultado visual esperado |

Próxima intervenção: inspecionar o botão atual, escolher a implementação equivalente já usada nesses módulos e documentar a adaptação antes de orientar o Builder. Se mantido botão nativo, comprovar slot e posição no template; se renderizado em PL/SQL, verificar autorização pelo nome correto e manter proteção no destino. Não manter os dois botões.

## Pendências de validação

- Botão: posição, cor, ícone, ausência de duplicação, responsividade, autorização e navegação para cadastro limpo.
- Permissões: distinguir consulta na p12, ação de criar e destino p14. IS_AUTHORIZED recebe nomes ADMIN_RH e EQUIPE_CORLIX_HUB; os identificadores APEXlang são diferentes.
- Paginação: export contém rowRangesXToYOfZNoPagination. Conferir necessidade de navegação e testar mais de 15 resultados antes de marcar concluído.
- Escape: verificar os textos livres de nome, e-mail e vínculo inseridos no HTML; manter marcação confiável separada de dados.
- Layout: conferir resultado visual, sem presumir defeito apenas pela sequência.
- Página 14: revisar inclusão versus edição, CREATE_USER, admissão, senhas e autorização antes de oferecer edição na lista.
- Facetas: combinar filtros, limpar, buscar e conferir contagens e perfis conhecidos; registrar ausência do erro Ajax.
- Isolamento: testar duas empresas, usuário comum e equipe Corlix; empresa nula não comprova autorização global.

## Como registrar os próximos resultados

Para cada ajuste: referência existente, mudança no Builder, evidência (export/print/relato), resultado e pendência. Marcar como concluído apenas o que foi confirmado; conservar os testes negativos para não repetir tentativas. A regra de reutilização está no AGENTS.md e em docs/ai-context/08-convencoes-e-pegadinhas.md, regra 14.

## Revisão do guia e regra de encerramento — continuação da tarefa

Pedido: alinhar o guia aos módulos existentes e exigir documentação no encerramento de tarefas e módulos. Trabalho documental na branch fix/documentacao-padroes-paginas, baseado na DEV a2e3c4b.

- Guia revisado: instalação já presente distinguida de instalação nova; removida cópia duplicada da view e sugestão de duplicar CSS; caminho estático corrigido.
- Cabeçalho proposto seguindo Holerite e Ponto, com ação no mesmo contêiner e autorização pelo nome ADMIN_RH, compatível com o destino atual. A consulta da p12 não foi restringida ao RH.
- Retirada instrução de procurar aba Attributes; retirado ORDER BY da consulta; documentados escape, paginação com navegação e ajuste de layout condicionado à inspeção visual.
- Link de Pessoa permanece documentado com ressalva sobre edição na p14; alternativa sem link registrada até validar os processos.
- Regra 15 adicionada ao AGENTS.md, convenções e índice de contexto: toda entrega deve registrar trabalho, evidências, falhas e pendências.
- Verificação documental: diff e links locais verificados; índice de casos atualizado. Nenhuma aplicação ou execução no Builder nesta tarefa.

Pendências: aplicar/conferir cabeçalho, validar visualmente o botão e testar autorização, escape, paginação, facetas, isolamento e edição. Próximo passo: conferir o cabeçalho atual no Builder e seguir §4 do guia, registrando o resultado antes de outra alteração. PR de documentação: #130, atualizado nesta continuação; a revisão corrente substitui as orientações conflitantes do #129, que ainda requer conciliação pelo time.

## Conferência do padrão de packages de UI

Após a observação do usuário, foram inspecionados os packages e as chamadas nas páginas 9, 13 e 30. Confirmação: Holerite usa pkg_holerite_ui.render_cabecalho e render_pagina; Ponto usa pkg_ponto_ui.render_cabecalho e funções por seção; Histórico usa pkg_historico_carreira_ui.render. As regiões retornam o CLOB do package. HTML, helpers de CLOB, escape e ícones ficam centralizados no código do módulo; CSS/JS e processos APEX integram a apresentação.

A revisão anterior apenas reutilizou o contêiner do cabeçalho e manteve HTML inline, sem seguir a arquitetura. O guia agora marca essa proposta como anterior e registra a necessidade do package de Colaboradores antes da chamada no Builder. A regra 14 foi explicitada para exigir arquitetura de packages, além de reaproveitamento visual.

Escopo concluído: inspeção do padrão e correção documental. Validação: comparação das funções e chamadas nos exports, diff documental. Não houve criação/compilação de package nem aplicação no Builder. Próximo passo: implementar a UI de Colaboradores com spec/body, instalação e estratégia de integração com a fonte SQL do Faceted Search; depois validar o botão e as demais pendências. Não existe ainda pkg_colaboradores_ui instalado por esta tarefa.

## Regra permanente de preferência pelos padrões existentes

Por orientação explícita do usuário, AGENTS.md e regra 14 foram reforçados: seguir sempre os padrões adotados, incluindo packages de UI, salvo boa prática demonstravelmente melhor para o caso. A exceção exige comparação documentada, evidência, benefício concreto, impactos e validação; preferência pessoal não basta.

Entrega documental: regra persistida no repositório e incluída no PR #130. Verificação: git diff --check e reindexação dos casos. Nenhuma mudança na aplicação; implementação do package de Colaboradores e validações anteriores seguem pendentes.

## Guia executável com package de UI — 09/11/2026

A etapa anteriormente pendente de preparar o package foi realizada no repositório: 02_pkg_colaboradores_ui.pks/.pkb fornecem render_cabecalho retornando CLOB, com ação no mesmo contêiner, ADMIN_RH, URL com checksum, escape e Lucide pelo mapeamento do tema. O instalador inclui spec/body. O guia substitui o bloco inline por instalação, consulta de USER_ERRORS/USER_OBJECTS e chamada curta no Builder.

Referências: render_cabecalho de Holerite/Ponto. A montagem usa CLOB local e append; relatório e facetas permanecem nativos para preservar a fonte filtrável. Não foi criado um render_pagina para substituir esses componentes.

Verificação local: diff e links do guia; reindexação documental. Compilação Oracle, aplicação no Builder e testes visuais/funcionais não executados. O package está versionado, não confirmado como instalado. Próximo passo: executar os dois arquivos 02, conferir validade, aplicar a chamada do §4.3 e testar botão, autorização e navegação; demais pendências anteriores continuam abertas. Esta seção atualiza o estado histórico que dizia que o package ainda precisava ser criado.

## Resolução do conflito do PR #130 — 09/11/2026

A DEV avançou para 6efa452 com a integração do PR #129, gerando conflito no guia de Colaboradores. Integrada origin/DEV à branch do #130, preservando a chamada ao package, a instalação já confirmada de ACL/CSS e a distinção entre acesso à lista e autorização da ação. Incorporadas as verificações úteis de HTML, paginação, facetas e troubleshooting do #129, sem reintroduzir restrição geral a ADMIN_RH ou HTML inline no cabeçalho. Corrigida também a descrição do módulo que havia sido combinada automaticamente com a orientação antiga.

Verificação: diff sem erros, ausência de marcadores de conflito, links locais do guia e reindexação dos casos. Nenhuma alteração em pastas protegidas nem teste no Builder. O merge do PR para DEV permanece a cargo do time; compilação e validações da aplicação continuam pendentes.

## Confirmação de Link Text — 09/11/2026

O usuário forneceu o HTML atualmente aplicado em NOME_COMPLETO: já está em Link Text, com spans de pessoa/avatar/nome/e-mail e sem âncora interna. O guia §5.1 foi ajustado para reconhecer esse estado e orientar somente as substituições !ATTR em FOTO_URL e !HTML em INICIAIS, NOME_COMPLETO e EMAIL, preservando Type e Target.

Verificação: conferência do trecho enviado, diff sem erros e reindexação. Alteração exclusivamente documental. Não houve aplicação no Builder; escape e comportamento da página 14 continuam pendentes de validação. Próximo passo: aplicar as quatro substituições e conferir apresentação/caracteres especiais.

## Filtros abaixo do relatório — 09/11/2026

Usuário relatou filtros abaixo e enviou export: região Colaboradores sequence 10, coluna 4/span 9 e startNewRow false; Filtros sequence 20, coluna 1/span 3. O guia destacava as colunas, mas não incluía Sequence nas listas principais de configuração. Incluída a sequência nas duas regiões: Filtros 10 primeiro, iniciando linha; Colaboradores 20 depois, sem iniciar linha. A alteração é nas regiões, não nas colunas/facetas; o cabeçalho em breadcrumbBar não precisa ser reordenado.

O export também confirma a chamada ao package de cabeçalho e o escape de NOME_COMPLETO, sem comprovar todos os testes funcionais. Verificação documental: diff e reindexação. Próximo passo: salvar as propriedades e executar a página inteira para confirmar alinhamento; se persistir, obter print do Layout e resultado em desktop. Nenhuma alteração direta na app.

## Auditoria da captura de 09/11/2026 às 10:45

Comparadas captura do usuário e imagem do protótipo. Filtros ao lado e botão no cabeçalho confirmados visualmente. Fidelidade ainda parcial: HTML literal em Perfil, ausência do card/estilo de tabela, Vínculo estreito, barra de contagem/ordenação ausente e mensagens em inglês. Detalhes, limites da evidência e critérios de aceite em [Validacao-visual-2026-11-09.md](./Validacao-visual-2026-11-09.md).

Escopo: validação, sem alteração da app ou CSS. Verificação documental: diff e reindexação. Próximo passo: corrigir renderização de PERFIL, inspecionar DOM/CSS efetivos e depois ajustar distribuição e apresentação, preservando packages e integração das facetas.
