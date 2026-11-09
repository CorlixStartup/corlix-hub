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

## Guia dos ajustes visuais — 09/11/2026

A auditoria foi convertida no §11 do guia: correção pontual de PERFIL, inspeção de CSS/DOM, proposta de card e distribuição de colunas baseada nos tokens do Ponto, rótulo das facetas, paginação e investigação de mensagens. Separadas as dependências ainda não implementadas (barra sincronizada de contagem/ordenação e identificação das chaves de tradução).

Verificação documental: diff, links locais e reindexação. Nenhum CSS foi publicado ou executado no navegador. O bloco CSS é proposta para teste, não resultado homologado. Próximo passo: corrigir a etiqueta, confirmar DOM/CSS e testar a apresentação antes de consolidar estilos no módulo. Package/cabeçalho e posição dos filtros não precisam ser refeitos.

## Tradução e paginação — 09/11/2026

Consultadas listas oficiais de mensagens APEX 26.1 e identificadas APEX.FS.TOTAL_ROW_COUNT_LABEL, PAGINATION.* e WWV_RENDER_REPORT3.X_Y_OF_Z/_2/X_Y_OF_MORE_THAN_Z. Guia §11.7 atualizado com overrides, idioma efetivo en, uso em JavaScript, abrangência por aplicação e configuração de paginação com navegação. Verificação: documentação oficial, diff e reindexação; cadastro de mensagens e execução no Builder não realizados. Próximo passo: aplicar e testar total, intervalo e navegação com filtros.

## Revalidação após atualização de DEV — 09/11/2026

Pedido: voltar à DEV, atualizar e avaliar prontidão/fidelidade. Checkout principal estava limpo e foi atualizado por fast-forward para b1ff0d6; workspace de trabalho também selecionou DEV nessa revisão. Criada branch fix/validacao-colaboradores-dev somente para registrar auditoria, sem commit direto na DEV.

Inspeção do backup 05730bc das 12:06 confirma package instalado, paginação de 15 linhas com links, layout corrigido, escape de Pessoa, RAW em Perfil, rótulo e traduções. O CSS de ajuste foi aplicado Inline. Não foi usada a captura antiga como prova do resultado novo.

Parecer e pendências em Validacao-visual-2026-11-09.md, seção Revalidação: barra de total/ordenação ausente, p14 ainda sem fluxo de edição comprovado, isolamento com empresa nula, decisão do acesso RH da lista, escape de Vínculo, consolidação CSS após teste e verificação visual/funcional atual. Não foram feitas alterações na app. Verificação documental: diff e reindexação; retorno à DEV ao encerrar. Próximo passo: priorizar pendências confirmadas e obter captura após as alterações das 12:06.

## CSS exclusivamente em arquivo — 09/11/2026

Por instrução do usuário, retirado o uso de CSS Inline do fluxo recomendado, inclusive para testes. Regras Inline do export da p12 foram transferidas para colaboradores.css, conciliadas com os estilos de tabela anteriores; colaboradores.min.css regenerado. O guia §11.3 agora orienta publicação dos dois arquivos, manutenção de File URLs e remoção do Inline pelo Builder. Regra persistida em AGENTS.md/convenções.

Validação local: diff, balanço de blocos CSS e equivalência da versão minificada com a transformação conservadora. Não houve publicação ou remoção de Inline na aplicação; corlixhub/ foi apenas lido. Próximo passo: publicar arquivos, remover Inline pelo Builder e comparar aparência, paginação e responsividade. Pendências de barra e edição permanecem.

## Acesso da liderança e guia das correções — 09/11/2026

Decisão do usuário: a lista é vista por RH, gestores, CEO e diretores; criar e editar seguem com ADMIN_RH. Interpretação registrada: papéis admin-rh, diretoria e gestor, além da autorização GESTOR; a equipe do Corlix Hub não foi incluída, e o gestor vê a empresa toda.

Versionado: §12 do guia, view com isolamento estrito por G_ID_EMPRESA, render_cabecalho_cadastro no package e CSS da barra e do avatar inativo. Decisões: departamento e cargo só leitura na edição, para passar pela Movimentação; sincronização da conta APEX fora do guia, pois SET_EMAIL e LOCK_ACCOUNT exigem administrador do workspace; Order By Item em região própria, porque o template Standard não tem #ORDER_BY_ITEM#.

Verificação: export e documentação oficial do APEX 26.1 conferidos, git diff --check. Não houve compilação Oracle, aplicação no Builder nem teste em execução; os itens marcados no guia dependem de confirmação no 26.1.5. Próximo passo: executar §12 na ordem e os testes do §12.9.

## Validação do §12 no backup das 13:11 — 09/11/2026

Pedido: identificar o que já foi aplicado e o que falta. Comparados §12 do guia, export e DDL do backup a6d16f1 (corlixhub-prd-20261109-160916), cujo commit registra ausência de mudanças em relação ao de 12:06. Resultado: nenhum item do §12 consta como aplicado no banco PRD, único ambiente exportado pelo job. O usuário relatou ter feito boa parte; hipóteses a confirmar: alterações anteriores às 12:06, não salvas ou em outro ambiente.

Registrada a situação no §12.0, com a ordem do que falta, e incluída a remoção do CSS Inline no §12.1. Verificação: comparação de export/DDL e git diff --check. Revisão estática, sem execução da app. Próximo passo: aplicar os itens do §12.0 e rodar novo backup.

## Passo a passo detalhado do §12 — 09/11/2026

§12.1 a §12.8 reescritos por item, com caminho de cada propriedade, valores e conferência. Corrigido: "When Button Pressed" é propriedade própria de Server-side Condition, não opção de Type. Confirmado na documentação do 26.1 que o item de Order By pode ser posicionado em qualquer lugar da página. Referência: export a6d16f1 e documentação oficial. Alteração só documental, sem execução no Builder; caminhos não conferidos seguem marcados.

## Validação das páginas 12 e 14 no backup das 14:10 — 09/11/2026

Comparados guia, export e DDL do backup 571499e. Aplicados na app: view, package, CSS, autorização, menu, consulta, colunas, barra, ordenação e separação de criação e edição. Revisão estática; não houve execução autenticada.

Pendências encontradas: branch "Limpar formulário" em BEFORE_PROCESSING sem condição, antes de todos os processos (AFTER_SUBMIT), o que impede o branch de retorno e pode impedir o salvamento; Barra da lista sem Static ID, com CSS por #cx-colab-barra; relatório em Region Body e barra em Sub Regions; item automático P12_ORDER_BY sobrando.

Correção: a justificativa anterior de que o template Standard não tinha posição de ordenação estava errada. O export mostra a posição sortOrder no relatório; o template do tema não aparece no f100.sql. A região própria segue porque o protótipo põe total e seletor na mesma linha. O caminho de criação de P12_ORDEM no guia foi corrigido conforme o export. Próximo passo: aplicar os ajustes do §12.0 e executar §12.9.

## Revalidação do export colado da página 12 — 09/11/2026

Base: export da p12 enviado pelo usuário, mais novo que o backup 571499e. Confirmados os ajustes 2, 3 e 4 do §12.0: Barra da lista com identificador cx-colab-barra, relatório em Sub Regions e P12_ORDER_BY removido. O ajuste 1 (branch da p14) não pôde ser confirmado: a p14 não veio no export colado e o último backup ainda o mostra em processing.

O usuário informou que a página segue diferente do protótipo. Sem captura ou DOM: a tentativa de abrir a página parou no login, sem digitar credenciais. Diferenças identificáveis no export: linhas alternadas (t-Report--altRowsDefault), página em @/standard fora do padrão E1, "Ordenar por" com rótulo flutuante, rótulo visível na busca e colunas sem ordenação pelo cabeçalho (sem a seta de Pessoa). Contagens à direita e menus das facetas seguem sem CSS validado; o seletor .a-FS-facetList nunca foi conferido no DOM. Não foi escrito CSS novo sem o DOM (§11.4). Próximo passo: obter captura atual e DOM das facetas.

## Validação na tela da página 12 e da edição na p14 — 09/11/2026

Usuário autenticou no Chrome (conta Teste Rh); nenhuma credencial digitada e nada salvo. Confirmados na execução: filtro por situação com total sincronizado, Ordenar por, avatar cinza, paginação e, na p14 em modo edição, cabeçalho, ausência de senha, campos só leitura e botão correto; sem erros de console.

Causas das diferenças: região Barra da lista sem Static ID no DOM (id gerado), logo o CSS por #cx-colab-barra não aplicava; seletor flutuante em largura total; contagens com parênteses por pseudo-elemento; menu de faceta com a única ação Filter. Corrigido: apontamentos anteriores de linhas alternadas e rótulo visível da busca eram falsos na tela.

CSS novo testado por estilo temporário na própria aba, sem persistência, e incorporado aos arquivos do módulo. Falta publicar, aplicar a classe e o ajuste de Clear; salvar na p14 não foi testado, e o branch segue em processing no último backup. Testes de contas de outros perfis pendentes.

## Validação visual final da página 12 — 09/11/2026

Usuário autenticou no Chrome (conta Teste Rh); nenhuma credencial digitada e nenhum dado gravado. Backup 4633d7a confirma classe da barra, APEX.FS.CLEAR em JavaScript e branch da p14 em After Processing; o CSS foi publicado depois desse backup e conferido na execução.

Resultado em desktop (1488 px): barra em linha única com total à esquerda e Ordenar por à direita; contagens à direita, sem parênteses; menu de três pontos oculto; filtro Inativa levou o total de 309 a 4 e exibiu "Limpar"; sem erros de console. Layout considerado fiel ao protótipo, com as diferenças aceitas listadas no §12.0.

Pendências: testes de salvar na p14 (grava dados), contas de diretor, gestor e colaborador comum, caracteres especiais e tela estreita. Próximo passo: executar esses testes e decidir os itens em aberto do §12.0.

## Teste de salvar edição na p14 — 09/11/2026

Autorizado pelo usuário no registro [DEMO] Diego Alves (id 315), conta Teste Rh, login feito pelo usuário. Alterado apenas o primeiro nome para DiegoTeste e acionado Salvar alterações. Resultado: recusado pela validação "Data de nascimento must have some value.", porque o registro não tem data de nascimento e o campo é obrigatório. Ao reabrir, o primeiro nome continua Diego: nada foi gravado e não houve o que restaurar.

Conclusão: a validação obrigatória funciona na edição, mas o caminho de sucesso (gravar, voltar à lista com "Alterações salvas.", não criar conta nem admissão) segue não testado. Achados: colaboradores sem data de nascimento não podem ser editados até o campo ser preenchido; mensagem de obrigatório em inglês. Próximo passo: repetir o teste num registro de teste com data de nascimento.

Continuação em 09/11/2026: autorizado repetir o teste em outro [DEMO] com data de nascimento. Leitura sem gravação dos 16 registros [DEMO] encontrados pela busca: nenhum tem data de nascimento (leitura conferida com a data de admissão, presente no HTML). Teste de sucesso não executado; nenhum registro alterado. Próximo passo: preencher por SQL a data de um [DEMO], testar e restaurar o valor nulo por SQL, se o usuário autorizar.

## Teste de salvar edição com sucesso na p14 — 09/11/2026

Autorizado pelo usuário, que preencheu por SQL a data de nascimento do [DEMO] Diego Alves (id 315) para o teste. Conta Teste Rh. Primeiro nome alterado para DiegoTeste e salvo: novo carregamento do registro retornou DiegoTeste. Restaurado para Diego pelo mesmo botão e confirmado em novo carregamento; nome, admissão e e-mail inalterados.

Resposta do servidor (POST wwv_flow.accept, status 200): redirectURL para a página colaboradores com success_msg "Row updated. Alterações salvas.", o que comprova a execução do branch de retorno. Na aba automatizada o navegador não seguiu o redirecionamento e permaneceu na p14, com apex.page.isChanged verdadeiro; causa não identificada, possivelmente própria da automação. Falta um salvamento manual para confirmar o retorno na tela.

Não comprovado: ausência de conta e admissão novas, pois a contagem anterior ao teste não foi obtida. Achado: a mensagem de sucesso inclui o texto padrão em inglês "Row updated.". O ambiente informou versão 26.1.6 em wwv_flow.js_messages, enquanto os guias citam 26.1.5. Pendência: restaurar por SQL a data de nascimento nula do registro 315.

Conclusão do teste de edição em 09/11/2026: usuário salvou manualmente o registro 315 e restaurou por SQL a data de nascimento nula, confirmada em novo carregamento, com nome e demais campos originais. Consulta informada pelo usuário após os salvamentos: contas = 0 e historico = 3. Sem conta APEX para DEMO.CARREIRA.1.4, o CREATE_USER não rodou na edição (a carga demo insere em COLABORADOR sem criar conta; a expectativa anterior de contas = 1 estava errada). Os 3 lançamentos são compatíveis com a carga 09_dados_demo_dashboard.sql (admissão, promoção e desligamento), sem indício de admissão nova. O usuário não informou se a tela voltou à lista no salvamento manual.

## Decisões de acesso e confirmação do retorno — 09/11/2026

Usuário confirmou a mensagem de sucesso no salvamento manual da edição; o não redirecionamento visto antes era da aba automatizada.

Decisões: equipe do Corlix Hub vê todas as empresas e os perfis; RH edita; gestores e diretoria só leem; data de nascimento segue obrigatória. Versionado: view com liberação explícita pelo papel equipe-do-corlix-hub, reutilizando fn_colab_tem_papel, e código da autorização no §12.2. Interpretação registrada: a equipe é somente leitura na lista, sem link de edição, pois apenas o RH foi citado como editor.

Não compilado nem aplicado; sem teste com conta da equipe. Risco a observar: nova chamada de função no predicado, a validar nas contagens das facetas. Próximo passo: aplicar o bloco do §12.0 e testar 4A.

Validação com a conta Teste Rh após o usuário aplicar a view e a autorização, 09/11/2026: lista com 309 registros, faceta Empresa só com Corlix, contagens das facetas carregadas sem ORA-, link no nome, botão Novo colaborador e coluna Pessoa única. Mostra que o RH segue restrito à própria empresa. O acesso global da equipe do Corlix Hub não foi testado, por falta de sessão com essa conta, e o último backup (14:51) é anterior à aplicação.

Observado sem relação comprovada com a alteração: exceção de console em onerror de imagem (nextElementSibling nulo) e avatar do cabeçalho ausente nessa carga, embora a imagem e o span de iniciais existam no DOM. O Global Page não muda desde 05/11. Causa não investigada.

Teste com a conta AMANDANUNES, informada como da equipe, 09/11/2026: lista abriu pelo menu, 309 registros, sem link no nome, sem botão Novo colaborador, coluna Pessoa única e sem erro. Somente leitura confirmada. Faceta Empresa só com Corlix, igual à conta de RH: inconclusivo para o acesso global, pois pode haver colaboradores de uma única empresa ou a conta pode não ter o papel equipe-do-corlix-hub. Próximo passo: conferir por SQL as empresas com colaboradores e os papéis da conta.

Resultado das consultas, informado pelo usuário em 09/11/2026: colaboradores só na empresa Corlix (309) e AMANDANUNES apenas com o papel diretoria. Logo, o teste anterior vale como teste 2 (diretoria, somente leitura, aprovado), e não como teste da equipe. O acesso global (teste 4A) segue sem teste: exige conta com equipe-do-corlix-hub e colaborador em outra empresa para distinguir o resultado.

Teste com a conta SARAHSILVA2, da equipe do Corlix Hub, 09/11/2026: a p12 não abre. ORA-20012 em APROVADOR_PONTO (PKG_PONTO.FN_E_APROVADOR via FN_EMPRESA_CONTEXTO), porque a conta não tem empresa em G_ID_EMPRESA; a autorização está em item de menu, logo afeta todas as páginas. Correção proposta no §12.0: tratar -20012 como falso no esquema, seguindo o tratamento já usado em pkg_suporte_ui, sem recompilar o package. Não aplicada nem testada. Caso novo registrado no guia do Ponto; rodar casos.py indexar após o merge. Teste 4A segue pendente.

Reteste com SARAHSILVA2 após a correção de APROVADOR_PONTO, 09/11/2026: a p12 abre sem erro (correção confirmada), porém com 0 colaboradores e com o botão Novo colaborador, indicando papel Admin RH nessa conta. Teste 4A reprovado até o diagnóstico: conferir se a conta tem equipe-do-corlix-hub e se a view instalada contém a liberação.

Novo reteste com SARAHSILVA2, 09/11/2026: após acrescentar à view a condição com fn_colab_tem_papel (bloco com dbms_metadata), a lista seguiu com 0 registros, embora a conta tenha equipe-do-corlix-hub. Hipótese, não confirmada: APEX_ACL.HAS_USER_ROLE não reconhece o papel nesse contexto. Tentativas com colagem longa no SQL Commands falharam (ORA-00900 e ORA-00923). Versionada a troca por fn_colab_e_equipe, baseada em apex_authorization.is_authorized('EQUIPE_CORLIX_HUB'). Atenção: a classificação de Perfil usa o mesmo fn_colab_tem_papel; se a hipótese se confirmar, papéis manuais podem estar sendo classificados como Colaborador. Não aplicado nem testado.

Com fn_colab_e_equipe aplicada, o usuário confirmou que a lista apareceu para a conta da equipe, o que aponta APEX_ACL.HAS_USER_ROLE como a causa provável dos zeros. Teste 4A: lista aprovada; relato do usuário, sem nova leitura da tela.

Fotos ausentes para a equipe: entregar_foto responde 404 sem G_ID_EMPRESA, e a página 44 exige COLABORADOR, que uma conta só da equipe não atende. Versionado em pkg_arquivos: a equipe resolve a empresa pelo dono da foto; a página 44 passa a VER_FOTO_COLABORADOR. Se dois colaboradores de empresas diferentes tiverem o mesmo nome de arquivo, vale o maior id_empresa. Não aplicado nem testado.

Validação na tela com SARAHSILVA2, sem empresa e com equipe-do-corlix-hub, 09/11/2026: 309 registros, facetas carregadas, 15 de 15 fotos da página carregadas e sem erro de tela ou console. Correções de APROVADOR_PONTO, fn_colab_e_equipe, pkg_arquivos e página 44 aplicadas pelo usuário. Limites: só existe uma empresa com colaboradores, e a conta também tem admin-rh, logo o modo somente leitura e o acesso de conta só da equipe à página 44 não foram exercitados. Pendente: revisar a coluna Perfil, que ainda usa APEX_ACL.HAS_USER_ROLE.

Coluna Perfil, 09/11/2026: consulta informada pelo usuário mostrou AnaSouza (publicador-de-conteúdo), FernandaLima (admin-rh) e EDUARDOMARINS (diretoria, admin-rh, equipe-do-corlix-hub, publicador-de-conteúdo) com papéis atribuídos fora do cargo. Com a faceta Publicador sem contagem, confirma-se que papel manual não é reconhecido por fn_colab_tem_papel. Versionada a função com consulta a APEX_APPL_ACL_USER_ROLES, mantendo a assinatura e isolando o SQL da agregação de facetas. Risco a validar: retorno de ORA-00904 e tempo de carga. Não aplicado nem testado.

Validação da coluna Perfil na tela, 09/11/2026, conta SARAHSILVA2: facetas Colaborador 292, Administrador 16 e Publicador 1, conforme o previsto; filtro Publicador retornou AnaSouza com a etiqueta correta, sem ORA-00904 ou erro de console; documento da página em cerca de 0,7 s. Correção de fn_colab_tem_papel confirmada. Limitação conhecida vista na tela: "1 colaboradores" no singular.
