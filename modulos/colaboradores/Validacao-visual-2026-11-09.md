# Colaboradores — validação visual de 09/11/2026

Comparação da captura enviada pelo usuário (arquivo screencapture terminado em 2026-11-09-10_45_58.png) com pen_dev/Colaboradores · visão de administração.png. Inspeção de imagens e CSS do módulo; não houve interação com a app nem leitura do DOM computado.

**Resultado: parcialmente conforme; fidelidade visual ainda não aprovada.** Capturas têm larguras diferentes (1280 e 2048 pixels), portanto não se conclui divergência de tamanho de fonte por comparação direta em pixels. Os 309 registros reais não precisam reproduzir as oito pessoas fictícias.

## O que a captura confirma

- Filtros à esquerda e relatório à direita: problema anterior de empilhamento resolvido nessa largura.
- Cabeçalho com título, descrição e botão escuro à direita; sinal de mais e texto presentes. Isso confirma aparência/posição, não autorização ou navegação.
- Nome/e-mail, avatares de iniciais e badges de situação aparecem.
- Facetas exibem contagens: total 309; situação 305 + 4; perfil 295 + 14. Somas consistentes na captura, mas classificação e filtros combinados não foram testados.

## Diferenças e ordem de correção

| Prioridade | Evidência na captura | Alvo / encaminhamento |
|---|---|---|
| Alta | Perfil de administradores mostra literalmente a tag span e a classe cx-etiqueta | Renderizar etiqueta neutra. Conferir HTML Expression de PERFIL = #PERFIL_HTML!RAW# conforme guia; somente o fragmento fixo da view pode ser tratado como HTML. Confirmar configuração atual e ausência de dupla codificação se persistir |
| Alta | Tabela sem card branco arredondado e com grade vertical marcada | Protótipo usa superfície branca, borda externa suave e divisórias horizontais. Conferir template efetivo e DOM antes de ajustar CSS; o CSS atual do módulo não define toda essa estrutura |
| Alta | Vínculo muito estreito: departamento/cargo quebram em várias linhas, aumentando bastante cada registro | Distribuir larguras para Pessoa/Login/Vínculo/Perfil/Situação após corrigir o HTML literal. Não fixar altura cortando texto nem aplicar nowrap global. Testar nomes longos e largura disponível; não copiar a largura do protótipo de 2048 pixels diretamente |
| Média | Contagem está na lateral como Total Row Count 309 | Protótipo coloca “309 colaboradores” sobre o relatório; localizar mensagem/atributo ou implementar barra integrada sem duplicar estado das facetas |
| Média | Não há controle “Ordenar por — Nome” sobre a tabela | Implementar barra equivalente com ordenação real ligada à consulta/relatório. A seta no cabeçalho Pessoa não reproduz esse controle |
| Média | Facetas mostram contagens entre parênteses junto ao rótulo e menus de três pontos | Protótipo usa contagens alinhadas à direita e apresentação simples. Conferir recursos do Faceted Search e adaptar estilo sem quebrar foco, seleção ou contagens |
| Média | Rodapé em inglês e texto aparentemente cortado na borda direita | Traduzir mensagens e conferir overflow e paginação efetivos no navegador. A captura não comprova que não existem controles fora da área visível |
| Baixa | Rótulo da faceta “Perfil” | Protótipo usa “Perfil de acesso” |

## Investigação necessária antes de alterar CSS

O CSS do módulo usa seletores table.t-Report-report. A captura sozinha não comprova que esse seletor corresponde à tabela renderizada, nem que o CSS minificado carregou. Verificar arquivo solicitado, resposta sem 404, classes do elemento e regras computadas. Não atribuir a grade ou o espaçamento a “CSS não carregado” sem essa evidência.

O HTML literal em Perfil também pode influenciar a largura das colunas; corrigir primeiro e medir novamente. Não desativar escape de todos os dados como solução.

## Padrão de implementação

Preservar o cabeçalho em pkg_colaboradores_ui e o padrão dos packages de Histórico, Holerite e Ponto para qualquer novo HTML personalizado. Manter a integração SQL do relatório com as facetas. Caso a barra de contagem/ordenação precise de código próprio, documentar como reage a busca, seleção de facetas, refresh e paginação antes de implementar; não criar contagem estática divergente do relatório.

Não há motivo nesta captura para refazer a posição do botão ou trocar novamente a arquitetura do cabeçalho.

## Critérios para nova validação

1. Etiqueta Administrador renderizada, sem tags visíveis.
2. Card branco com divisórias e proporções próximas ao protótipo.
3. Vínculo legível e linhas sem crescimento causado por distribuição inadequada de largura.
4. Contagem e ordenação na barra acima da tabela, sincronizadas com filtros.
5. Mensagens em pt-BR e rodapé legível, sem corte.
6. Repetir testes em desktop e tela estreita, com teclado, filtros combinados e mais de uma página.

Estado: auditoria concluída e documentada; correções visuais não aplicadas nem validadas nesta tarefa. Não confundir conformidade visual parcial com homologação funcional.

## Revalidação da DEV b1ff0d6 — backup 05730bc, 09/11 às 12:06

Esta seção atualiza a auditoria da captura das 10:45. A captura anterior não prova o resultado visual das mudanças das 12:06. Revisão atual de export APEXlang, DDL, CSS e mensagens; sem execução autenticada no navegador ou banco.

### Confirmado como aplicado no backup

| Item | Evidência |
|---|---|
| Cabeçalho no padrão de packages | p00012-colaboradores.apx chama pkg_colaboradores_ui.render_cabecalho; spec/body constam nos DDL 08/09 |
| Ordem do layout | Filtros sequence 10/coluna 1/span 3; relatório sequence 20/coluna 4/span 9, startNewRow false |
| Paginação com links | pagination.type = rowRangesXToYOfZWithPagination; export SQL confirma p_query_num_rows = 15, ROW_RANGES_WITH_LINKS e BOTTOM_RIGHT |
| Pessoa com escape | FOTO_URL!ATTR, INICIAIS!HTML, NOME_COMPLETO!HTML e EMAIL!HTML no Link Text |
| Etiqueta de perfil | htmlExpression de PERFIL = #PERFIL_HTML!RAW#; não repetir instrução como se ainda estivesse ausente |
| Rótulo Perfil de acesso | P12_PERFIL.label atualizado |
| Traduções | messages.apx contém APEX.FS.*, PAGINATION.* e WWV_RENDER_REPORT3.* em en com texto em português |
| Card e proporções | CSS Inline na página contém superfície/borda/raio, table-layout fixed e larguras 30/15/25/18/12 |
| ACL | Função e view corrigida continuam presentes |

### Pendências que impedem declarar a página pronta

1. **Barra do protótipo não implementada:** não há região/controle acima do relatório com total filtrado e “Ordenar por — Nome”. O total continua configurado nas facetas; não há item/select correspondente à ordenação. A seta no cabeçalho Pessoa não substitui o controle do protótipo.
2. **Edição na p14 não homologada:** p12 passa P14_ID_COLABORADOR, mas p14 mantém CREATE_USER sem condição de inclusão. Revisar criação/edição, admissão, validações e autorização antes de afirmar que “Editar colaborador” funciona.
3. **Isolamento incompleto:** VW_COLABORADORES_LISTA mantém v('G_ID_EMPRESA') is null OR id_empresa = contexto. Uma sessão RH sem empresa pode obter todos os registros; a intenção de acesso global não está explicitamente verificada nesse predicado.
4. **Acesso da lista precisa de decisão:** export da p12 contém authorizationScheme @admin-rh, diferente da orientação posterior que separou consulta da lista e ação de cadastro. Confirmar o público da página; não remover nem adicionar autorização automaticamente durante esta auditoria.
5. **Escape de Vínculo não atualizado:** HTML Expression usa VINCULO_LINHA1/VINCULO_LINHA2 sem filtros explícitos e escapeSpecialChars false; a view compõe nomes de empresa/departamento/cargo sem escape. Aplicar o tratamento contextual documentado e testar caracteres especiais.
6. **CSS ainda em etapa de teste:** ajustes de card/colunas estão Inline, fora dos arquivos normal/minificado do módulo. Confirmar o DOM e o resultado visual/responsivo antes de consolidar, para não duplicar estilos.
7. **Tradução e navegação precisam de teste:** mensagens estão cadastradas, mas isso não comprova o texto final no cliente nem ausência de corte no rodapé. Conferir recarga completa, filtros e navegação. O export não explicita Used in JavaScript nas mensagens das facetas; verificar se são carregadas pelo componente antes de atribuir falha a esse atributo.
8. **Facetas ainda diferem do alvo até prova visual:** alinhamento de contagens, menus de três pontos e posição do total precisam de captura atual. Nenhum CSS novo específico para esses elementos foi identificado.

### Parecer

**Não pronta para homologação final e ainda não integralmente fiel ao protótipo.** As correções de configuração acima estão no backup e não devem ser solicitadas novamente como se faltassem. Para concluir: implementar barra sincronizada; resolver/validar edição e política de acesso; tratar Vínculo; testar o fluxo e produzir captura atual em desktop e tela estreita. Não exigir oito registros ou dimensões fixas do mockup.

Validações executadas nesta revisão: comparação dos exports, inspeção dos packages/DDL, consulta pontual do export SQL para paginação, inspeção das mensagens e comparação dos arquivos CSS. Não houve alteração de código da app, execução de testes Oracle nem validação visual posterior às 12:06.
