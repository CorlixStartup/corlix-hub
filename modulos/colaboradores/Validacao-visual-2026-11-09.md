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
