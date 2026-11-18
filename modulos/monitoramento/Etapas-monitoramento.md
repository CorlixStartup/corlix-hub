# Desempenho e monitoramento

> **Estado em 17/11/2026:** diagnóstico da Home pelo Lighthouse e consultas de monitoramento versionados. Nada foi alterado na app nem no banco. Os números de armazenamento, CPU e memória dependem de o time rodar as consultas (seções 2 e 3) ou abrir o painel do OCI.

## 1. Como cada pergunta é respondida

| Pergunta | Onde ver | Quem pode |
|---|---|---|
| Quanto armazenamento está ocupado | OCI › Autonomous Database › **Metrics › Storage Utilization**; consultas 1 a 3 do `02_consultas_admin.sql`; por tabela, consultas 1 a 4 do `01_consultas_schema.sql` | Admin (OCI/ADMIN); schema: qualquer dev |
| Quanta memória, em média | Consultas 8 a 10 do `02_consultas_admin.sql` (SGA e PGA). O OCI não mostra memória do Autonomous Database (confirmar no console) | ADMIN |
| A CPU está ok? Há picos? | OCI › **Metrics › CPU Utilization** (intervalo 1 h, estatística **Max**, 7 dias) e **Performance Hub** para o horário do pico; consultas 4 a 7 e 12 | Admin (OCI/ADMIN) |
| Como está a experiência de um usuário comum | Lighthouse (seção 5) e tempo das páginas no servidor: consultas 5 a 9 do `01_consultas_schema.sql` | Qualquer dev |

Limites do Always Free que importam aqui: **20 GB** de armazenamento por banco, CPU fixa (sem escalonamento automático) e cerca de **30 sessões** simultâneas.

## 2. Consultas do schema (`01_consultas_schema.sql`)

Rode no **SQL Commands** do workspace `WKSP_CORLIXHUB`, **uma consulta por vez**: cole só do `select` até a última linha, **sem o `;` final** e sem o comentário da consulta seguinte (o SQL Commands recusa qualquer texto depois do fim da consulta: `ORA-03405`). Outra forma: cole o arquivo inteiro, selecione só uma consulta com o mouse (sem o `;`) e clique em *Run*. Todas são só leitura.

| # | Mostra |
|---|---|
| 1–2 | Espaço por tabela (os LOBs somados à tabela dona) e total do schema |
| 3 | Tamanho de cada imagem de comunicado |
| 4 | Fotos ainda guardadas no banco (`COLABORADOR.IMAGEM_PERFIL`) |
| 5 | Tempo de geração de cada página no servidor: média, p95 e máximo (14 dias) |
| 6 | Chamadas Ajax mais lentas |
| 7 | As 20 aberturas de página mais lentas (picos) |
| 8 | Acessos por hora, para cruzar com os picos de CPU |
| 9 | Erros registrados |

As consultas 5 a 9 usam `APEX_WORKSPACE_ACTIVITY_LOG`, que só tem dados com o *Activity Logging* da app ligado (padrão do APEX; confirmar em *Shared Components › Application Definition › Properties*).

## 3. Consultas do banco inteiro (`02_consultas_admin.sql`)

Rode como **ADMIN** em *Database Actions › SQL*. A senha de ADMIN é do time. Lá dá para colar o arquivo inteiro e usar **Run Script** (F5), que roda todas em sequência; ou posicionar o cursor numa consulta e usar **Run Statement** (Ctrl+Enter).

| # | Mostra |
|---|---|
| 1–3 | Armazenamento total contra o limite de 20 GB, por schema e por tablespace |
| 4 | `cpu_count`, `sessions`, `processes` |
| 5 | CPU, sessões ativas e número de sessões na última hora, minuto a minuto |
| 6–7 | CPU por hora em 7 dias (média e pico) e as horas com pico acima de 80% |
| 8–10 | Memória: SGA, PGA agora e pico, PGA média e máxima por dia |
| 11 | Sessões abertas agora, por usuário |
| 12 | Os 15 SQL que mais consumiram CPU em 7 dias |

Testadas em 17/11/2026 num Oracle 23ai local: as 12 rodaram sem erro. No Autonomous, as views `DBA_HIST_*` dependem do AWR, que o ADB mantém (confirmar se retornam linhas no Always Free).

### Como ler

| Indicador | Ok | Investigar |
|---|---|---|
| Armazenamento | até 70% de 20 GB (14 GB) | acima de 70%: ver a consulta 1 do schema e os LOBs |
| CPU média por hora | até 50% | acima de 50% de média ou picos acima de 80% em horário de uso |
| Average Active Sessions | menor que `cpu_count` | maior que `cpu_count`: há fila de CPU |
| Sessões | bem abaixo de 30 | perto de 30: risco de recusar conexões |
| PGA máxima | estável dia a dia | crescendo todo dia: sessão ou SQL vazando memória |
| Página (p95 no servidor) | até 1 s | acima de 2 s |
| Ajax (p95) | até 0,5 s | acima de 1 s |

Para um pico: anote o horário pela consulta 7 (ou no gráfico do OCI), abra o **Performance Hub** nesse intervalo e veja o SQL e a sessão; cruze com a consulta 8 do schema (acessos naquela hora) e com a 12 do ADMIN.

## 4. Diagnóstico da Home (Lighthouse, 18/11/2026 01:38 UTC)

Medição colada pelo time: Lighthouse 13.5, **desktop**, conexão simulada (10 Mbps, 40 ms), conta `Rafael Nunes`, sessão com o Builder aberto (a barra de desenvolvedor carregou) e extensões do navegador ativas.

| Categoria | Nota |
|---|---|
| Desempenho | **68** |
| Acessibilidade | 94 |
| Boas práticas | 100 |
| SEO | 58 (sem importância: intranet, o `robots.txt` do ADB bloqueia indexação) |

| Métrica | Valor | Leitura |
|---|---|---|
| FCP (primeiro conteúdo) | 1,1 s | bom |
| **LCP (maior conteúdo)** | **9,9 s** (simulado) | ruim; na conexão real da medição foi 1,7 s |
| Speed Index | 2,3 s | regular |
| TBT (bloqueio da página) | 0 ms | ótimo |
| CLS (página pulando) | 0,0004 | ótimo |
| Resposta do servidor (TTFB) | 0,5 s | ok |
| **Peso total** | **19,9 MB** em 54 requisições | muito alto; 18,7 MB são imagens |

### O que pesa

1. **As imagens dos comunicados (causa principal).** O carrossel baixa 4 PNG de **4,2 a 4,8 MB** cada, com 2105×1350 px, para mostrar em 683×384 px. Só elas somam cerca de 18 MB, a cada sessão de cada pessoa. O Lighthouse estima 17,6 MB de economia. A primeira imagem é o LCP e ainda chega com `loading="lazy"`.
   - **Causa no código:** o `P17_IMAGEM` (página 17) tem *Resize To › Maximum File Size* = `5120` KB e nenhuma largura máxima. A imagem cortada em 16:9 é gravada quase do tamanho original.
2. **`home-hero.jpg`** (banner da pesquisa): 266 KB; em WebP ou JPEG mais comprimido cairia cerca de 170 KB.
3. **Fotos de avatar:** 354×356 px para 40 px na tela (cerca de 17 KB cada, 20 fotos). Pequeno; fica para depois.
4. **CSS do tema servido sem minificar** (`custom.css`, `corlix-tema.css`, `home.css`): as páginas usam `#MIN#`, que só deixa de valer com debug ligado. Como a medição foi feita com a sessão do Builder, provavelmente estava em debug. Confirmar na medição com usuário comum.
5. **Fora do nosso controle (plataforma do ADB):** HTML sem compressão (70 KB), HTTP/1.1 em vez de HTTP/2, `desktop_all.min.js` do APEX (724 KB) e o CSS do Universal Theme (a maior parte do "CSS não usado").

### Acessibilidade (94)

| Achado | Onde | Correção sugerida |
|---|---|---|
| Links "ver espelho" e "ver holerite" só se distinguem pela cor (contraste 1,21:1 com o texto ao lado) | `.cx-home-indicador__detalhe a` em `home.css` | Sublinhado no link |
| Pontos do carrossel com 8×8 px (mínimo recomendado 24×24) | `.cx-carrossel__ponto` em `home.css` | Área de clique de 24 px (padding ou `::before`), mantendo o ponto visível de 8 px |
| Botão do menu do usuário: `aria-label="Menu do usuário"` não contém o nome visível ("Rafael Nunes") | Header (Global Page, `tema/Etapas-header-e-menu.md`) | `aria-label` com o nome, por exemplo "Rafael Nunes, menu do usuário" |

## 5. Ações propostas

| # | Prioridade | Ação | Onde | Ganho esperado |
|---|---|---|---|---|
| 1 | **Alta** | `P17_IMAGEM`: *Resize To* › **Maximum File Width** `1280`, **Maximum Height** `720`, **Maximum File Size** `300` (KB). O APEX reduz a imagem no navegador antes de enviar | Builder, página 17 (`comunicados/Etapas-comunicados.md` §4.7) | Imagens novas com ~150–300 KB em vez de 4–5 MB |
| 2 | **Alta** | Trocar as imagens dos comunicados já publicados por versões 1280×720 em JPEG | Decisão do time: a página 17 só cria comunicados. Opções: recriar os comunicados de demonstração depois da ação 1, ou uma página de edição | A Home cai de ~20 MB para ~2 MB |
| 3 | Média | Primeira imagem do carrossel sem `loading="lazy"` | Atributo de *lazy loading* da região Cards `home_comunicados` (confirmar no 26.1.5 se existe; senão, `home-pagina.js` troca para `eager` no primeiro card) | LCP mais cedo |
| 4 | Média | Comprimir `home-hero.jpg` (WebP ou JPEG qualidade ~70) e republicar nos *Static Application Files* | `modulos/home/` + Builder | ~170 KB |
| 5 | Baixa | Correções de acessibilidade da tabela acima | `home.css`/`home.min.css` e header | Nota de acessibilidade ~100 |
| 6 | Baixa | Miniaturas das fotos (ex.: 96×96) para os avatares | `pkg_arquivos` / bucket | ~300 KB por Home |

### Medir de novo (depois das ações 1 e 2)

1. Janela **anônima**, sem extensões, **sem** o Builder aberto, com uma conta comum (ex.: `teste.rh` ou uma `[DEMO]`).
2. DevTools › Lighthouse › **Navigation**, categorias *Performance* e *Accessibility*; rodar em **Desktop** e em **Mobile**.
3. Rodar 3 vezes e anotar a mediana do LCP, do peso total e da nota.
4. Registrar na Situação abaixo.

Meta proposta: LCP abaixo de 2,5 s no simulado desktop, peso da Home abaixo de 3 MB, nota de desempenho acima de 90.

## 6. Monitoramento contínuo (proposta)

- **Alarmes no OCI** (*Observability › Monitoring › Alarm Definitions*), com aviso por e-mail ao time: CPU Utilization acima de 80% por 15 min, Storage Utilization acima de 70% e Sessions acima de 25. Criar alarme e tópico de notificação é ação do time no console; confirmar se fica dentro do gratuito.
- **Rotina semanal:** consultas 5 a 9 do schema e 1, 6, 7 e 11 do ADMIN, com o resultado na Situação.
- Depois da separação em DEV/UAT/PRD (`modulos/ambientes/`), o monitoramento vale para o **PRD**; DEV e UAT dividem o outro banco.

## Se não funcionar

| Sintoma | Causa provável | Correção |
|---|---|---|
| `ORA-03405: End of query reached; no additional text should follow` no SQL Commands | Colou mais de uma consulta, ou o `;` final e o comentário seguinte | Uma consulta por vez, do `select` ao fim, sem `;` (seção 2) |
| Consultas 5 a 9 do schema voltam vazias | *Activity Logging* desligado ou app nunca acessada no período | Ligar em *Application Definition* (confirmar o caminho no 26.1.5) e esperar uso |
| `ORA-00942` nas consultas `DBA_*`/`V$` | Rodou com o usuário do schema | Rodar como ADMIN |
| Consultas `DBA_HIST_*` sem linhas | AWR sem snapshots no período | Usar os gráficos de Metrics e o Performance Hub do OCI |
| `ORA-00904: PAGE_VIEW_TYPE` | Coluna com outro nome no 26.1.5 | Rodar `select * from apex_workspace_activity_log fetch first 1 rows only` e ajustar o filtro |

## Situação

| Data | Evento | Resultado |
|---|---|---|
| 17/11/2026 | Lighthouse da Home colado pelo time e analisado | Desempenho 68, LCP 9,9 s (simulado), 19,9 MB. Causa principal: imagens de comunicado de 4–5 MB, porque o `P17_IMAGEM` não limita a largura. Acessibilidade 94, com 3 achados |
| 17/11/2026 | `01_consultas_schema.sql` e `02_consultas_admin.sql` versionados | Testados num Oracle 23ai local: as 12 do ADMIN rodaram; as do schema rodaram, menos as de `APEX_WORKSPACE_ACTIVITY_LOG`, que só existe no ADB. **Números de armazenamento, CPU e memória ainda não coletados** |
| 18/11/2026 | Primeira execução pelo time no SQL Commands | `ORA-03405` na linha 13: a colagem levou o `;` e o comentário da consulta 2 junto. **Erro do guia**, que não avisava que o SQL Commands aceita um comando só; seção 2 e "Se não funcionar" corrigidas |
| 18/11/2026 | Consulta 1 do schema (espaço por tabela), rodada pelo time no SQL Commands | **`COMUNICADO.IMAGEM` ocupa 26,7 MB**, de longe o maior; depois `APP_LOG.DETALHE` 5,3 MB, `FORMACAO_COLABORADOR.BL_ANEXO` 1,4 MB, `HOLERITE_ITENS` 0,7 MB, `COLABORADOR.IMAGEM_PERFIL` 0,5 MB, `EMPRESA.LOGOTIPO_EMPRESA` 0,4 MB e `HISTORICO_CARREIRA` 0,4 MB. Aparecem objetos `BIN$…` (tabelas apagadas na lixeira do Oracle, 0,3 MB cada). Só vieram 10 linhas (limite padrão do SQL Commands); falta o total (consulta 2). O schema está na casa de dezenas de MB, longe do limite de 20 GB; o problema das imagens é de **transferência** (cada visita à Home), não de armazenamento |
