# Fichas das páginas

> **Estado em 13/11/2026** (backup de DEV `84f8625`). Uma ficha por página da app 100, com o mesmo nome do `.apx`. Cada ficha traz o estado real, o template, a autorização, a árvore de regiões, a lógica, os dados, a navegação e as pendências. **Antes de mexer numa página, leia a ficha dela.** Como criar ou atualizar uma ficha: [`docs/agentes/fluxos/ficha-de-pagina.md`](../../agentes/fluxos/ficha-de-pagina.md).

O `.apx` é a fonte da verdade. Se a ficha divergir dele, corrija a ficha.

## Índice

| Nº | Página | Estado em 13/11/2026 | Guia |
|---|---|---|---|
| 0 | [Global Page](./p00000-global-page.md) | Implementada: busca do header (`pkg_busca_ui`) e menu do usuário em popover. Sem registro de teste | `busca`, `tema/Etapas-header-e-menu.md` |
| 1 | [Início](./p00001-início.md) | **§8 concluído** (55/55, testes 1 a 8). Pendentes: Parabenizar, "Disponível agora" e conta sem colaborador | `home/Etapas-home.md` |
| 2 | [Meu Perfil](./p00002-meu-perfil.md) | Implementada e testada (privacidade e protótipo). "Salvar foto" sem ação | `perfil/` |
| 3 | [Organograma](./p00003-organograma.md) | Implementada com `pkg_organograma` e drawer; sem registro de isolamento por empresa | `organograma/Etapas-organograma.md` |
| 4 | [Chat](./p00004-chat.md) | Implementada com envio e polling de 1 s; sem guia no repositório; CSS inline | — |
| 5 | [Notificações](./p00005-notificacoes.md) | Placeholder (destino do sino) | — |
| 6 | [Configurações](./p00006-configuracoes.md) | Placeholder, sem autorização | — |
| 7 | [Monitor de Logs](./p00007-monitor-logs.md) | Implementada com `@admin-rh`; a troca para `EQUIPE_CORLIX_HUB` não foi aplicada | `isolamento-empresas/` §5 |
| 8 | [Notificações (vazia)](./p00008-notificações.md) | Vazia, duplicada da 5, sem referências | — |
| 9 | [Holerite Digital](./p00009-holerite-digital.md) | Redesign aplicado e testado (falta o teste 17); PDF "Aviso de crédito" não aplicado | `holerite/Etapas-holerite.md` |
| 11 | [Comunicados Oficiais](./p00011-comunicados-oficiais.md) | Placeholder; destino de "Ler comunicado" e "Ver todos" | — |
| 12 | [Colaboradores](./p00012-colaboradores.md) | Implementada e validada (09/11/2026) | `colaboradores/Etapas-colaboradores.md` |
| 13 | [Histórico de carreira](./p00013-historico-de-carreira.md) | Implementada e validada (19/10/2026) | `historico-carreira/` §2 |
| 14 | [Cadastro de Usuários](./p00014-cadastros-de-usuarios.md) | Criação e edição; edição validada; criar pelo RH falha (`CREATE_USER`) | `colaboradores/` |
| 15 | [Empresas Cadastradas](./p00015-empresas-cadastradas.md) | Implementada no visual do protótipo | `tema/Etapas-empresas.md` |
| 16 | [Cadastro de Empresas](./p00016-cadastro-de-empresas.md) | Modal com BrasilAPI e ViaCEP | `tema/Etapas-cadastro-empresa.md` |
| 17 | [Novo comunicado](./p00017-comunicado.md) | **Concluída** (48/48, testes da §5). Sem autorização própria na página | `comunicados/Etapas-comunicados.md` |
| 18 | [Movimentação](./p00018-movimentacao.md) | Implementada e validada; falta o filtro por empresa do isolamento | `historico-carreira/` §3 |
| 19 | [Formações e certificações](./p00019-formacoes-e-certificacoes.md) | Implementada e validada | `historico-carreira/` §4 |
| 20 | [Dashboard RH](./p00020-dashboard-rh.md) | Versão antiga validada; redesign não aplicado | `dashboard-rh/Etapas-dashboard-rh.md` |
| 21 | [Formação](./p00021-formacao.md) | Implementada e validada; falta o filtro por empresa do isolamento | `historico-carreira/` §4.5 |
| 22 | [Solicitar correção](./p00022-solicitar-correcao.md) | Implementada e validada | `historico-carreira/` §6 |
| 23 | [Responder solicitação](./p00023-responder-solicitacao.md) | Implementada e validada | `historico-carreira/` §5.5 |
| 26 | [Central de Equipes](./p00026-central-de-equipes.md) | Versão do assistente, **sem autorização e sem filtro por empresa** | `isolamento-empresas/` §3 e §4.1 |
| 27 | [Nova Equipe](./p00027-nova-equipe.md) | Modal do assistente, **sem autorização e sem filtro por empresa** | `isolamento-empresas/` §3 e §4.2 |
| 29 | [Busca](./p00029-busca.md) | Montada conforme o guia; sem registro de teste | `busca/Etapas-busca.md` |
| 30 | [Ponto eletrônico](./p00030-ponto-eletronico.md) | Implementada e validada (03/11/2026); carrega `ponto.css` sem `#MIN#` | `ponto-eletronico/` |
| 31 | [Solicitar ajuste](./p00031-solicitar-ajuste.md) | Implementada e validada | `ponto-eletronico/` §5 |
| 32 | [Ajustes de ponto](./p00032-ajustes-de-ponto.md) | Implementada e validada | `ponto-eletronico/` §7 |
| 33 | [Responder ajuste](./p00033-responder-ajuste.md) | Implementada e validada | `ponto-eletronico/` §6 |
| 34 | [Suporte TI](./p00034-suporte-ti.md) | Criada; fora do menu; sem registro de testes | `suporte-ti/Etapas-suporte-ti.md` §4 |
| 35 | [Abrir chamado](./p00035-abrir-chamado.md) | Criada conforme o guia; sem registro de testes | `suporte-ti/` §5 |
| 36 | [Chamado](./p00036-chamado.md) | Criada; botões fora do guia; sem registro de testes | `suporte-ti/` §6 |
| 37 | [Base de conhecimento](./p00037-base-conhecimento.md) | Criada; cabeçalho no slot `body`; sem registro de testes | `suporte-ti/` §7 |
| 38 | [Atendimento TI](./p00038-atendimento-ti.md) | Criada; fora do menu; sem registro de testes | `suporte-ti/` §9 |
| 39 | [Atender chamado](./p00039-atender-chamado.md) | Criada sem as condições do guia; sem registro de testes | `suporte-ti/` §8 |
| 40 | [Status dos sistemas](./p00040-status-dos-sistemas.md) | Criada pelo assistente com os ajustes do §10.2; textos em inglês | `suporte-ti/` §10 |
| 41 | [Sistema](./p00041-sistema.md) | Criada pelo assistente com os ajustes do §10.3 | `suporte-ti/` §10.3 |
| 42 | [Artigos](./p00042-artigos.md) | §11.2 concluído no export em 13/11/2026 (16/16, filtra por empresa); sem teste na app | `suporte-ti/` §11 |
| 43 | [Artigo](./p00043-artigo.md) | Só o assistente; **empresa escolhível** e campos de controle obrigatórios | `suporte-ti/` §11.3 |
| 44 | [Foto](./p00044-foto.md) | Em uso (entrega as fotos do bucket), validada em 09/11/2026 | `arquivos/Etapas-fotos-object-storage.md` |
| 9999 | [Login](./p09999-login.md) | Login padrão do APEX, em inglês; redesign proposto, não aplicado | `login/Etapas-login.md` |

Os guias ficam em `modulos/<pasta>/`.

## Pontos de atenção (achados na criação das fichas)

Conferidos no código em 13/11/2026; nada foi alterado na app.

- **Isolamento por empresa:** a 43 deixa escolher a empresa (a 42 passou a filtrar em 13/11/2026). A 26 e a 27 continuam sem filtro e sem autorização, e os forms da 18 e da 21 não filtram por empresa. A correção da 26, 27, 18 e 21 está em `modulos/isolamento-empresas/Etapas-isolamento-empresas.md`, ainda não aplicado; a da 42 e da 43 está no §11 do guia do Suporte TI.
- **Autorização da página:** a 17 (Novo comunicado), a 26 e a 27 não têm `authorizationScheme` próprio. A 17 só fica protegida pelo botão da Home.
- **Menu:** nenhuma página do Suporte TI (34 a 43) está no menu (§12 do guia não aplicado).
- **CSS:** a p30 carrega `ponto.css` sem `#MIN#`; a p4 tem CSS inline.
- **Protótipo citado e ausente:** `pen_dev/Login.png` não existe.
