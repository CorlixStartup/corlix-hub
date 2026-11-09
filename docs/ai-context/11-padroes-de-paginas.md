# 11 · Padrões de páginas

> **Obrigatório para criar, redesenhar ou corrigir qualquer página.** Levantado em 09/11/2026 nos exports da `DEV` (`7f902ab`). Detalha a regra 14 do [08](./08-convencoes-e-pegadinhas.md).

## 1. Princípio

**O padrão existente é a decisão padrão.** Mudar pode piorar as coisas: a página nova passa a se comportar diferente das outras, e o próximo agente passa a copiar a diferença. Quem quer seguir o padrão não precisa justificar nada. Quem quer sair dele segue o §5.

Se uma situação não estiver coberta aqui, não invente: procure a página mais parecida na ordem do §2 e siga o que ela faz. Se nenhuma servir, pergunte ao time.

## 2. Qual página copiar

Quando as páginas divergirem entre si, vale esta ordem:

| Tipo de tela | Referência | Arquivos |
|---|---|---|
| Página personalizada | Holerite (p. 9) | `modulos/holerite/`, `p00009-holerite-digital.apx` |
| Página com colunas, abas e diálogos | Ponto (p. 30) | `modulos/ponto-eletronico/`, `p00030-ponto-eletronico.apx` |
| Resultados com busca | Busca (p. 29) | `modulos/busca/`, `p00029-busca.apx` |
| Modal com formulário | Solicitar ajuste (p. 31) | `p00031-solicitar-ajuste.apx` |
| Relatório operacional | Ajustes de ponto (p. 32) | `p00032-ajustes-de-ponto.apx` |
| Lista com facetas | Colaboradores (p. 12), **ainda não validada** | Só para a composição Faceted Search + Classic Report; veja o §6 |

Antes de copiar, confira a referência na `DEV` atualizada: o export é a fonte de verdade, não a memória nem um guia antigo.

## 3. Regras

### Estrutura

| # | Regra | Valor |
|---|---|---|
| E1 | Template da página normal | `Corlix - Standard Page` (`@corlix-standard-page`) |
| E2 | Modal | Page Mode `Modal Dialog`, template `Modal Dialog`; botões numa região `Buttons Container` em `Dialog Footer` |
| E3 | Cabeçalho | Região Dynamic Content em `Breadcrumb Bar`, template `Blank with Attributes (No Grid)`, chamando `pkg_<modulo>_ui.render_cabecalho` |
| E4 | Classes do cabeçalho | `cx-cabecalho-pagina`, com `__titulo`, `__descricao`, `__trilha`; botões em `--acoes` e `__acoes` |
| E5 | Corpo personalizado | Dynamic Content em `Body`, template `Blank with Attributes` (ou No Grid), chamando `render_*` |
| E6 | Diálogo na própria página | Slot `Dialogs, Drawers and Popups`, template `Inline Dialog` |
| E7 | Colunas de layout | Regiões `Blank with Attributes` com sub-regiões, como no Ponto |

### Componente

| Necessidade | Use | Exemplo |
|---|---|---|
| Layout do protótipo que não cabe no Universal Theme | Dynamic Content + package | Holerite, Ponto |
| Lista com filtros laterais | Faceted Search + Classic Report nativos | Colaboradores |
| Relatório de trabalho para RH ou gestão | Interactive Report | Ajustes de ponto, Dashboard RH |
| Cartões simples vindos de SQL | Cards nativo | Comunicados da Home |
| Entrada de dados | Form nativo, itens `Required/Optional Floating` | p. 31 |

Não troque um componente nativo filtrável por HTML gerado: as facetas dependem da fonte SQL da região.

### Package de UI

| # | Regra |
|---|---|
| P1 | HTML personalizado fica em `pkg_<modulo>_ui`. A região só faz a chamada: `return pkg_x_ui.render_y(:Pn_ITEM);` |
| P2 | Funções `render_*` retornam CLOB. Ações Ajax são procedures `ajax_*` no mesmo package |
| P3 | Base do corpo: `g_html`, `inicia`, `p(texto)`, `e()` = `apex_escape.html`, `a()` = `apex_escape.html_attribute` |
| P4 | Regra de negócio e acesso a dados ficam em `pkg_<modulo>`, separados da apresentação |
| P5 | Links sempre por `apex_page.get_url`, passados por `a()` |
| P6 | Nomes de mês e formatos numéricos explícitos: o idioma técnico da app é `en` |

### Ícones

| Onde | Como |
|---|---|
| HTML gerado por package | SVG Lucide em linha, `currentColor`, `aria-hidden="true"`, por uma função `icone()` |
| Componente nativo ou botão com classe do tema | Classe `fa-*`, mapeada para Lucide pelo tema |

### CSS e JavaScript

| # | Regra |
|---|---|
| C1 | **Sem CSS Inline** de página ou região e sem atributo `style`, mesmo em teste |
| C2 | Use os tokens `--cx-*`; não fixe cor nova |
| C3 | Página nova: `#APP_FILES#<modulo>#MIN#.css`, com `.css` e `.min.css` juntos. Não mova arquivos que já existem |
| C4 | Regras do módulo com prefixo próprio, por exemplo `.cx-hol-` |
| C5 | JS em `modulos/<nome>/<nome>-pagina.js`, colado em **Execute when Page Loads**, com eventos delegados por `data-*` |
| C6 | Ajax por `apex.server.process` com `x01`, respondido por Ajax Callback que chama `ajax_*` |

### Segurança

| # | Regra |
|---|---|
| S1 | Toda página tem `Authorization Scheme` na própria página, e o menu usa o mesmo esquema |
| S2 | `Page Access Protection` = `Arguments Must Have Checksum`, exceto com justificativa no guia, como a Busca recebendo o termo pela URL |
| S3 | Reutilize esquemas existentes (`COLABORADOR`, `ADMIN_RH`, `GESTOR`, `SOMENTE_DIRETORIA`, `EQUIPE_CORLIX_HUB`). Novo esquema, só compondo os existentes com `apex_authorization.is_authorized` |
| S4 | Separe três permissões: ver a página, executar a ação e abrir o destino. Não mostre link para destino que a pessoa não pode abrir |
| S5 | Todo dado de negócio filtra por `id_empresa`. **Empresa nula nunca libera tudo**: sem empresa, nenhuma linha |
| S6 | Em relatório com `Escape Special Characters = No`, use filtros explícitos: `!HTML` em texto, `!ATTR` em atributo e `!RAW` só em fragmento fixo gerado pela view |

### Banco e fotos

| # | Regra |
|---|---|
| B1 | Módulo em `modulos/<nome>/`: SQL numerado, `instalar.sql`, CSS, JS e `Etapas-<nome>.md` |
| B2 | Foto de colaborador: `apex_page.get_url(p_page => 44, p_x01 => <arquivo>)`, tratando valor vazio e o legado `#APP_FILES#Fotos Colaboradores/`; sem foto, iniciais |

### Guia e entrega

| # | Regra |
|---|---|
| G1 | O guia tem a seção **Referências reutilizadas**, indicando o que veio de qual página |
| G2 | Caminho do Builder não conferido vai marcado "(confirmar no 26.1.5)"; se não existir, peça print |
| G3 | Confira no template se a posição existe antes de indicá-la. Exemplo: `Standard` não tem `#ORDER_BY_ITEM#` |
| G4 | Diferencie proposto, versionado, aplicado e validado. Leitura de export não é teste |

## 4. Antes de entregar

- [ ] Li o protótipo em `pen_dev/` e a página de referência do §2 na `DEV` atualizada.
- [ ] Todas as regras do §3 foram seguidas, ou há exceção aprovada (§5).
- [ ] Nada de CSS Inline, HTML longo na região ou link sem checksum.
- [ ] A página e o menu têm autorização; a consulta filtra por empresa.
- [ ] O guia traz Referências reutilizadas, testes e "Se não funcionar".
- [ ] O registro do módulo foi atualizado (regra 15).

## 5. Quando sair do padrão

Só é aceitável se **todos** os itens valerem:

1. **Versão:** a prática melhor vale para o APEX **26.1.5** e está na [documentação oficial do 26.1](../apex-26.1/README.md) ou foi comprovada em teste nesta app.
2. **Benefício concreto** em segurança, manutenção, desempenho, acessibilidade ou compatibilidade. Preferência, novidade ou conveniência não contam.
3. **Impacto conhecido:** o que muda nas outras páginas e o que deixa de ficar consistente.
4. **Aprovação do time antes de implementar.** O agente propõe e espera; não adota por conta própria.

Corrigir uma falha de segurança comprovada conta como benefício. Ainda assim, use a correção mais próxima do padrão.

Registre no guia do módulo:

```markdown
### Exceção ao padrão: <regra, por exemplo C3>
- Padrão atual e onde é usado:
- Alternativa proposta:
- Evidência (link da doc 26.1 ou teste):
- Benefício concreto:
- Impacto em outras páginas:
- Validação prevista:
- Aprovado por / data:
```

Se a exceção se mostrar melhor para todo o projeto, atualize este documento no mesmo PR ou em outro, com a mesma aprovação.

## 6. Divergências conhecidas: não copie

| Onde | Divergência | Regra |
|---|---|---|
| p. 12, 13, 14, 20 e outras | `@/standard` em vez de `Corlix - Standard Page` | E1 |
| p. 13 e 20 | Cabeçalho em `Body`, sem package | E3 |
| p. 14 | Cabeçalho com HTML na própria região | P1 |
| p. 30 | CSS sem `#MIN#` e em pasta própria | C3 |
| p. 12 | Arquivo em `modulos/colaboradores/` e CSS Inline ainda no export | C1, C3 |

Não corrija essas páginas de passagem. Trocar o template de uma página pronta muda o layout e exige teste: faça em tarefa própria, com aprovação.
