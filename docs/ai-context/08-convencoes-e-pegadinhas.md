# 08 · Convenções, regras de trabalho e pegadinhas conhecidas

> Consolida as regras de trabalho e os problemas encontrados nos demais documentos (02–07). Detalhes e números de linha estão nos documentos de origem.
> Estado: §1 atualizado continuamente; §3 revisado em 13/11/2026 contra o backup de DEV `84f8625` e as [fichas das páginas](./paginas/README.md). Regras de conduta e fluxos de trabalho para qualquer agente: [`docs/agentes/`](../agentes/README.md).

## 1. Regras para uma IA trabalhando neste repositório

1. **Proibido modificar** `corlixhub/`, `backups/`, `pen_dev/` e `scripts/` (regra obrigatória do projeto). São só para leitura: nada de criar, editar, apagar ou reverter arquivos nelas. A app muda pelo Builder, feita pelo time, e o `.apx` chega ao repositório pelo export/backup; o agente valida, escreve o guia em `modulos/<nome>/Etapas-*.md` e atualiza `docs/`. Se a tarefa parecer exigir mudança nessas pastas, pare e pergunte. `database/f100.sql` também não se edita: é um export gerado (12 MB), só para consulta via `grep`.
2. **Sempre em pt-BR**: textos da UI, comentários, nomes de objetos (`colaborador`, `departamento`, `id_empresa`…), mensagens de commit.
3. **Nomes de objetos de banco** em `snake_case` minúsculo nos scripts. Prefixos: `pkg_` (packages), `vw_` (views), `trg_<tabela>_aud|log` (triggers), `fn_` (funções), `prc_` (procedures), `id_<entidade>` (PKs/FKs), `dt_` (datas), `fl_` (flags `S/N`), `ds_`/`nm_` quando aparecem.
4. **Módulos novos** seguem o padrão de `modulos/<nome>/`: scripts SQL numerados + `instalar.sql`, package `pkg_<nome>` com a lógica, `pkg_<nome>_ui` (ou procedure `render_*`) que devolve HTML para uma região *Dynamic Content*, `<nome>.css` e `<nome>.js`, e um `Etapas-<nome>.md` com o passo a passo no Builder. Veja o template em [`06-modulos.md`](./06-modulos.md).
5. **CSS**: não usar CSS Inline de página/região nem atributo style para novos ajustes, inclusive testes provisórios. Manter estilos em arquivos do módulo/tema e carregá-los por File URLs. Ao migrar Inline já instalado, publicar os arquivos completos antes de remover o bloco no Builder.
    tokens `--cx-*` em `corlix-tema.css`; ajustes e componentes em `custom.css`. **Atualize sempre o `.min.css` junto**, porque não existe script de minificação e os pares são mantidos à mão. Novos arquivos precisam ser registrados em `shared-components/static-files.apx` e, se forem globais, em `application.apx > css.fileUrls`. Prefixo de classes novas: `cx-` (tema), `org-`/`hc-`/`ch-`/`log-` (por módulo). Não há dark mode. A política visual é **sem sombras**. Veja [`04-tema-e-estilos.md`](./04-tema-e-estilos.md).
6. **Links entre páginas**: as páginas usam `argumentsMustHaveChecksum`, então gere URLs com `apex_page.get_url(...)` ou com o link builder. URLs `f?p=` montadas manualmente com parâmetros quebram.
7. **Multiempresa**: toda consulta nova a dados de negócio deve filtrar por `id_empresa` da empresa do usuário. Hoje quase nenhuma filtra (ver §3).
8. **Segurança**: quando criar ou alterar páginas administrativas, defina `authorizationScheme` **na página**, e não apenas na entrada do menu.
9. **Commits**: Conventional Commits (`feat(escopo): …`). Branches e PRs seguem a regra 13. Nunca versione `apex/`, `oracle_oradata/`, `ords_config/`, `.env`.
10. **Não invente**: o README e o código divergem em vários pontos (ver [`01`](./01-arquitetura-e-ambiente.md) §6). Confie no código e pergunte ao time sobre o que não estiver confirmado (ambiente atual, DDL das tabelas base, `log_pkg`).
11. **Passo a passo do Builder é para o APEX 26.1.5.** Os guias (`Etapas-*.md`) descrevem caminhos do Page Designer desta versão, com passos detalhados (onde clicar, seção › atributo, valor, como testar).
    - Não copie caminhos de versões antigas: no 26.1.5 o painel de propriedades **não tem a aba "Attributes"** e a região de Form **não mostra a seção "Edit"**.
    - Caminho que não foi conferido na tela do 26.1.5 vai marcado **(confirmar no 26.1.5)** e acompanhado de um jeito de verificar o resultado (o processo que o APEX cria, ou o trecho esperado no export APEXlang).
    - Se o usuário disser que um caminho não existe, **não chute outro**: peça um print da árvore e do painel de propriedades, e depois corrija o guia com o caminho real.
12. **Protótipos ficam em `pen_dev/`.** Toda tela-alvo, mockup ou protótipo do projeto está nessa pasta (PNGs exportados do pen.dev, um arquivo por tela, nomeado pelo título da tela). Quando a tarefa falar em "protótipo", "tela do pen.dev", "design" ou "tela-alvo", procure primeiro em `pen_dev/` e não em outro lugar; a descrição de cada tela está em [`07-design-pen-dev.md`](./07-design-pen-dev.md). Se o protótipo pedido não estiver lá, pergunte ao time em vez de inventar o layout. A pasta continua somente leitura (regra 1).

13. **Toda alteração vai numa branch própria, com PR.** Vale para qualquer alteração no repositório, por menor que seja:
    - Use `feature/<assunto>` para funcionalidade nova (módulo, tela, recurso) e `fix/<assunto>` para as demais (correção, documentação, ajuste).
    - Crie a branch a partir da `DEV` atualizada. Nunca faça commit direto na `DEV` ou na `PROD`.
    - Faça commit e push e abra o PR para `DEV`. Mudanças de assuntos diferentes ficam em branches e PRs diferentes.
    - Quando a `DEV` tiver commits que ainda não estão na `PROD`, abra o PR `DEV` → `PROD`, se não houver um aberto. Antes do merge do PR para `DEV`, o `DEV` → `PROD` ainda não tem o que mostrar: o GitHub recusa um PR sem commits.
    - O merge é do time: o agente só abre os PRs.
    - A regra não libera as pastas somente leitura (regra 1).


14. **Páginas devem partir dos módulos já implementados.** As regras concretas, a ordem das referências e o formulário de exceção estão em [11 · Padrões de páginas](./11-padroes-de-paginas.md); a exceção precisa de aprovação do time antes de ser implementada. Antes de criar, redesenhar ou corrigir uma página:
    - Atualize as referências remotas e confira a DEV atualizada, o último export e os relatos do time. Distinga código instalado, proposta em PR e teste executado; não peça para reinstalar algo já confirmado no backup.
    - Leia o protótipo em pen_dev/ e escolha o módulo existente mais próximo. Referências iniciais: Histórico de carreira (modulos/historico-carreira/), Holerite (modulos/holerite/) e Ponto eletrônico (modulos/ponto-eletronico/). Consulte o guia, o SQL/PLSQL, o CSS/JS necessário e o export da página de referência.
    - Registre no guia uma seção **Referências reutilizadas**: arquivos, componente reaproveitado e adaptações necessárias. Reutilize primeiro cabeçalho, ações, templates, tokens, espaçamento, estados vazios, ícones e padrões de navegação já adotados.
    - **Reutilize a arquitetura de packages de UI**, não apenas as classes CSS. HTML personalizado deve ser centralizado em `pkg_<modulo>_ui`, com funções `render_*` retornando CLOB; as regiões Dynamic Content fazem chamadas curtas ao package. Separe regras de negócio e acesso a dados da apresentação, seguindo o módulo equivalente. Registre a estratégia de CLOB, escape de texto/atributos, URLs com checksum e ícones. Não distribua grandes blocos de HTML/PLSQL pelas regiões como substituto desse padrão. Componentes nativos podem coexistir quando necessários (por exemplo, fonte filtrável do Faceted Search); justificar a composição no guia.
    - Preserve a integração entre HTML, CSS, JS e APEX. Antes de trocar uma ação renderizada por botão nativo (ou o contrário), confira posição disponível no template, DOM, autorização, checksum, ação e resultado visual. Não suponha que um botão nativo ficará dentro de um contêiner HTML retornado por PL/SQL.
    - **Padrão existente é a escolha obrigatória por padrão.** Só adote outra abordagem quando uma boa prática for demonstravelmente melhor para o caso. Antes da mudança, registre o padrão comparado, evidência técnica (documentação oficial e/ou teste), benefício concreto em segurança, manutenção, desempenho, acessibilidade ou compatibilidade, impactos de integração e validação prevista. Preferência pessoal, novidade ou conveniência isolada não bastam. Sem evidência suficiente, preserve o padrão. A alternativa deve ser compatível com o APEX 26.1.5. Reuso não autoriza copiar falhas de segurança; corrigir uma falha comprovada é justificativa técnica válida.
    - Diferencie permissão de consultar a página, executar uma ação e acessar o destino. Não restrinja toda uma listagem ao RH só porque contém uma ação administrativa. Não use empresa nula como substituto de autorização explícita.
    - Confirme como os ícones são renderizados: fonte Lucide mapeada por classes fa-* e SVG Lucide inline coexistem no projeto. Siga o padrão do componente escolhido.
    - Se o usuário informar que a orientação não funciona, interrompa as tentativas por suposição: confira o exemplo existente e obtenha o export/print necessário. Marque propostas não verificadas e não declare a página validada só por ler o código.
    - Registre resultados, falhas e pendências no módulo, com evidência e próximo passo. Mantenha as pastas protegidas somente para leitura.


15. **Documentar o encerramento de toda tarefa ou módulo.** Antes da entrega final:
    - Atualize o registro existente do módulo (preferencialmente Registro-implantacao.md ou seção Situação na app do guia). Para tarefa sem módulo, use o documento temático em docs/. Não crie registros duplicados quando já existe um apropriado.
    - Registre objetivo/escopo, data e referência do código consultado, alterações e arquivos/componentes, decisões e referências reutilizadas, comandos ou testes relevantes, resultado e evidências (export, print, relato do usuário, commit/PR).
    - Diferencie proposto, versionado, aplicado no Builder/banco e validado em execução. Registre também tentativas malsucedidas e hipóteses descartadas. Não trate revisão estática ou backup como prova de funcionamento.
    - Liste o que falta, bloqueios e próximo passo concreto; se nada falta, indique conclusão e sua evidência. Se a tarefa terminar parcialmente, documente esse estado sem afirmar que o módulo foi concluído.
    - Atualize o guia e docs/ai-context/ correspondentes quando a mudança afetar instruções ou estado do projeto. Registre casos novos no 09 ou em Se não funcionar e rode casos.py indexar quando aplicável.
    - Para mudanças apenas documentais, registre o que foi revisado e a verificação feita; não invente testes de app. Escale o tamanho do registro à tarefa, sem transcrever toda a conversa ou incluir credenciais/dados pessoais desnecessários.
    - Inclua o registro no mesmo fluxo de branch/commit/PR da tarefa e aponte o resultado na resposta final. Não peça confirmação só para documentar trabalho já autorizado.

## 2. Lacunas estruturais (objetos que faltam no repositório)

| Lacuna | Impacto |
|---|---|
| Dados do banco (empresas, cargos, colaboradores) | Só `DEPARTAMENTO` tem export (`database/dados/departamento.xlsx`). `database/corlix-hub.sql` é só o DDL (snapshot com blocos duplicados, não roda de ponta a ponta) e `f100.sql` é só a app. Para contagens e listas, consulte o banco (ver `05` §3.2). |
| Schema real com furos | `CARGO.ID_DEPARTAMENTO` sem FK; 8 FKs para `COLABORADOR` desabilitadas; códigos -20010..-20012 repetidos entre `PKG_EQUIPE_CANAL` e `PKG_HISTORICO_CARREIRA`; `07_testes.sql` falha no INSERT de `EMPRESA` (ver `05` §3–4A). |
| Função `ch_get_canal_direto` (Chat) | Usada na p4, sem fonte. |
| `docker-compose.yml` e `.env.example` | Deletados no working tree. `scripts/setup.*` dependem deles. O CI ignora a validação do compose quando o arquivo não existe. |
| Supporting objects | Estão vazios: o export da app não instala nada do schema. |
| Itens exigidos pelo organograma (`ID_COLABORADOR`, processo `DOWNLOAD_FOTO`) | Não aparecem em `shared-components/`. O histórico de carreira já está integrado: `G_ID_EMPRESA`, `GESTOR`, `COLABORADOR` e as páginas 18–23 estão no app. |

## 3. Pegadinhas por área

### Segurança / multi-tenant
- **Autorização na página (estado em 13/11/2026, backup `84f8625`):** várias páginas já têm `authorizationScheme` próprio (2, 7, 9, 12–16, 18–23, 30–44; ver as fichas em [`paginas/`](./paginas/README.md)). **Continuam sem:** 1, 3, 4, 5, 6, 8, 11, **17** (Novo comunicado: só o botão da Home exige `publicador-de-conteudo`), **26 e 27** (Equipes, que ficam no grupo Administração do menu). A lista completa de autorizações e de quem usa cada uma está no [`03`](./03-componentes-compartilhados.md) §2.
- Menus sem a autorização da página: "Dashboard RH" (p20 exige `ADMIN_RH`) e "Solicitar correção" (p22 exige `COLABORADOR`). Quem não tem o papel vê o item e recebe "acesso negado".
- **Filtro por `id_empresa`:** comunicados e as LOVs `LOV_*` já filtram por `:G_ID_EMPRESA`. Ainda não filtram: equipes (p26/p27), os forms da p18 e da p21, os artigos do suporte (p42; a p43 deixa escolher a empresa) e a `vw_org_colaborador` do organograma. Correções em `modulos/isolamento-empresas/Etapas-isolamento-empresas.md` e no §11 do guia do suporte, não aplicadas.
- Os app processes (4, `BEFORE_HEADER`, sem condição) rodam em todas as páginas, inclusive no login. Eles ligam o usuário ao colaborador por `COLABORADOR.login_apex = :APP_USER`; algumas comparações usam `UPPER` e outras não.

### Páginas
- **Edição de regiões no 26.1.5**: Form e Interactive Grid só são editáveis com o bloco `edit { enabled: true ... }`, que nos exports só aparece em regiões criadas pelo assistente de criação de página; o painel de propriedades não oferece onde ligar. Para cadastros, prefira lista (Interactive Report) + formulário em modal criado pelo assistente (padrão p15/p16). Ver `09` §4.8.
- **Placeholders** (só breadcrumb, em 13/11/2026): p5 Notificações, p6 Configurações e p11 Comunicados Oficiais. A p8 `NOTIFICAÇÕES` está vazia e duplica a p5. As páginas 2, 3, 12 e 13 deixaram de ser placeholders (ver as fichas).
- **p4 Chat:** tem envio e atualização automática (polling de 1 s, `CH_VERIFICAR_MSGS`), mas ainda carrega CSS inline grande e não tem guia no repositório.
- **p17 Novo comunicado:** os problemas do wizard antigo (`SYSDATE;`, sem *Close Dialog*, itens em `sequence: 10`) foram corrigidos em 12/11/2026. Ficam: a página sem autorização própria e a hora gravada como `00:00` (formato `DS` no item *Hidden*), registrada no guia §4.10.
- **p16 Cadastro de empresa**: faltam no Builder as validações de CNPJ repetido e de remoção com vínculos (`modulos/tema/Etapas-cadastro-empresa.md` §6.1).
- **p1 Início:** o redesign foi aplicado na própria página 1 (não existe página 28). As pegadinhas da Home antiga (links para 5/6/7, `href="#"`, `.` em `columnCssClasses`) não valem mais. O botão Suporte TI do hero depende do `modulos/suporte-ti/Etapas-suporte-ti.md` §13.
- **p0 Global:** a busca do cabeçalho já é Dynamic Content do `pkg_busca_ui` e os links do menu do usuário usam `f?p=` num popover. Ainda há `style="display:none"` no avatar de iniciais (contra a regra sem CSS inline).
- **Suporte TI (p34–43):** criadas, mas fora do menu (§12 do guia não aplicado) e sem registro de testes do §14.
- **Gráficos (JET) com mais de uma série**: o APEX junta os rótulos de todas as séries e os ordena **como texto**, ignorando o `order by` da query. Rótulo de mês em `mm/yyyy` sai fora de ordem ("01/2026" antes de "11/2025"). Use um rótulo que ordene certo como texto, como `to_char(mes, 'yyyy/mm')` (ex.: turnover da p20, `Etapas-historico-carreira.md` §5.2).

- **p9 Holerite**: até aplicar `modulos/holerite/Etapas-holerite.md`, abrir um mês vazio gera a folha de todos os colaboradores, com `COMMIT`, inclusive de meses futuros (`pkg_holerite.render`), e a página não tem autorização própria. Depois do guia, a folha vem do job `JOB_FOLHA_MENSAL`; se o job parar, nenhum holerite novo aparece. Cada pessoa tem holerites desde o mês da admissão, e o do mês atual só a partir do dia 25.

### Arquivos e tema
- As fotos vêm do bucket privado pela **página 44** (`pkg_arquivos.entregar_foto`, autorização `VER_FOTO_COLABORADOR`); os packages mandam `data-cx-foto` e o JS da página monta a URL (`modulos/arquivos/Etapas-fotos-object-storage.md`). A p12 e a p29 ainda tratam o caminho antigo `Fotos Colaboradores/`. Sem foto, o avatar mostra as iniciais (`.cx-avatar-iniciais`, ver 04); a SQL precisa devolver a foto **nula** nesse caso.
- `custom.css` tem regras globais (`.a-CardView-*` com sombra e raio 14px, `.ui-dialog-titlebar`) que contrariam a política "sem sombra" do tema.
- A p30 carrega `ponto.css` sem `#MIN#`, então o `ponto.min.css` publicado nunca é usado (ver 04 §10).
- Static IDs e aliases com acento (`publicador-de-conteúdo`, `histórico-de-carreira`, `NOTIFICAÇÕES`) são frágeis em URLs e scripts.
- **Static ID ≠ id do HTML (26.1):** o nome depois de `region` no `.apx` (Static ID) só identifica o componente no export. O `id` do elemento vem de **Advanced › HTML DOM ID** (`advanced { htmlDomId: … }`); sem ele, o APEX gera `R<número>`. Todo JS que busca uma região pelo id (`apex.theme.openRegion`, `apex.region(...)`, `$("#...")`) precisa do HTML DOM ID preenchido. A p1 e a p30 já usam `htmlDomId` em várias regiões; o diálogo de aniversariantes da Início caiu nisso (`Region does not support being opened and closed`, `modulos/home/Etapas-home.md` §3.7), e o organograma (p3, `organograma`) e o histórico (p13, `historico_carreira`) dependem do mesmo id.

### Módulos
- O guia do organograma usa a página 10 (`P10_ID_FOCO`), mas a página real é a **3**.
- `c_pagina_perfil = 20` do organograma conflita com o Dashboard RH (página 20) planejado pelo histórico de carreira.
- `vw_org_colaborador` não filtra por empresa, e o drawer de detalhes não verifica permissão.
- `G_ID_EMPRESA` só é preenchido depois de um novo login. Sem esse item, toda chamada a `pkg_historico_carreira` dentro de uma sessão APEX falha com `-20012`.
- A p14 chama `registrar_admissao_automatica` (processo "Registrar admissão", seq 15) desde 18/10/2026.
- Os erros do módulo de carreira (-20001 a -20099) só aparecem sem "ORA-" porque o `log_pkg.apex_error_handler` delega para `pkg_historico_carreira.fn_tratar_erro` (aplicado em 19/10/2026). Se recriar o `log_pkg`, mantenha essas três linhas (guia do módulo, §9.1).
- `corlixhub/shared-components/static-files/` traz a versão do CSS que está **no ambiente**. Ao mudar `modulos/historico-carreira/historico-carreira.css`, reenvie `.css` e `.min.css` pelo Builder (guia §2.3 e §9.3).
- O botão "Histórico de carreira" da p14 nunca aparece: a página só cadastra, e o branch pós-salvar limpa `P14_ID_COLABORADOR`.
- `COMUNICADO.TITULO` aceita até 200 caracteres no formulário (p17), mas o package corta em 100.
- O README do módulo de carreira fala em "nove códigos padrão" de movimentação, mas o seed cria 11.
- Perfis de acesso: os papéis vêm de `CARGO_PAPEL`, mas os colaboradores da empresa 1 estão em cargos antigos (101–604) vinculados à mão. Os cargos 605–633 do seed estão vazios. Antes de mexer em cargos, leia `modulos/perfis-acesso/Registro-implantacao.md`.
- `apex_acl` (atribuir papéis) não funciona no SQL Commands do APEX: sem sessão da app dá `ORA-01403`, e `apex_session.create_session` é bloqueado (`ORA-20987`). Use o Builder, a P14 ou o SQLcl/SQL Developer.
- SQL Commands: um comando por vez (sem `;` final, sem `commit;` junto), mostra só 10 linhas por padrão (campo **Rows**) e não mistura `unistr()` (NVARCHAR2) com VARCHAR2 em `union` sem `to_char`.
- As contas SARAHSILVA, EDUARDOMARINS e ALAIRTONROCHA são da equipe e não têm colaborador: "SEM VINCULO" na Home é esperado para elas.

### SQL e PL/SQL
Os erros já vistos (ORA-12704, PLS-00201/00304, PLS-00231, ORA-02000, ORA-01403, Access Denied etc.), com causa, correção e prevenção, estão em [09 · Erros e soluções](./09-erros-e-solucoes.md). Para achar um caso pela mensagem ou pelo sintoma (inclusive nas tabelas "Se não funcionar" dos módulos), use `python3 scripts/busca-casos/casos.py buscar "<texto>"` (01 §8.2). Consulte o checklist da §5 desse documento antes de entregar SQL ou PL/SQL.

Regras gerais para scripts PL/SQL:
- Todo bloco `create or replace package|package body|procedure|function|trigger|type` e todo bloco anônimo `begin … end;` termina com `/` sozinho na linha seguinte. Sem a `/`, o SQLcl não executa o bloco e o próximo comando é anexado a ele.
- Comandos SQL simples (`create view`, `comment`, `insert`) terminam com `;`, sem `/`. Um `;` seguido de `/` executa o comando duas vezes.
- Spec e body ficam em arquivos separados (`.pks` e `.pkb`), cada um com sua `/`, e são instalados nessa ordem.
- Depois de compilar, confira com `show errors package body <nome>` (SQLcl) ou com `select * from user_errors where name = '<NOME>'`. O APEX mostra só a primeira linha do erro.
- `set define off` no início do script: sem ele, `&` em strings (HTML, URLs) vira variável de substituição.
- Ao ler `Error at line N`, conte as linhas **a partir do início do comando** (`create or replace …`), não do arquivo.

### Configuração
- O idioma primário da app é `en`, com máscaras de data `DS`. Para pt-BR, formate explicitamente com `to_char(..., 'dd/mm/yyyy')`. A LOV `BOOLEAN` mostra "Yes/No".
- `400 Request Header Or Cookie Too Large` no host do Autonomous: são cookies acumulados, e o limite do proxy da OCI não pode ser alterado. Limpe **só o host** (DevTools → Application → Clear site data). Veja [`10-erro-400-cookies.md`](./10-erro-400-cookies.md).
- A sessão do Builder cai e pede o workspace de novo: ou os cookies foram perdidos, ou houve timeout (padrão de 1 h de inatividade e 8 h de duração; a app não define timeout próprio). Diagnóstico com `scripts/apex-sessao-timeouts.sql`; ver `10` §8.
- O último commit (`feature: …`) não segue o padrão do hook `commit-msg`.

## 4. Checklist rápido antes de entregar uma mudança
- [ ] Editei o `.apx` correto (e o `.min.css` junto com o `.css`, quando aplicável)?
- [ ] Os novos estáticos estão registrados em `static-files.apx`?
- [ ] As queries filtram por empresa? A página tem authorization?
- [ ] Os links foram gerados com checksum (`apex_page.get_url`)?
- [ ] Os textos estão em pt-BR e as datas formatadas explicitamente?
- [ ] O SQL novo está num script numerado e idempotente (`create table if not exists`, `create or replace`) e foi adicionado ao `instalar.sql` do módulo?
- [ ] O SQL/PL/SQL novo passa no checklist da §5 do [09 · Erros e soluções](./09-erros-e-solucoes.md)?
- [ ] A documentação em `docs/ai-context/` foi atualizada se a mudança altera páginas, schema, tema ou módulos?
