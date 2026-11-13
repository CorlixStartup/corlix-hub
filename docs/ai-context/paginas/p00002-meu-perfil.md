# Página 2 · Meu Perfil

> **Estado em 13/11/2026** (backup `84f8625`): implementada, aplicada e testada. `modulos/perfil/Etapas-perfil-privacidade.md` ("Situação na app (04/11/2026)") e `Etapas-perfil-prototipo.md` ("Situação na app") registram os testes; a autorização `@colaborador`, que estava "a confirmar no próximo backup", aparece neste export. "Salvar foto" ainda sem ação (`modulos/arquivos/Etapas-upload-foto-perfil.md`, CD-75).

## Resumo

| Atributo | Valor |
|---|---|
| Alias | `MEU-PERFIL` |
| Modo | Normal |
| Page template | `@/standard` |
| Autorização | `@colaborador` (`COLABORADOR`) · `argumentsMustHaveChecksum` |
| CSS/JS de arquivo | `#APP_FILES#Meu Perfil#MIN#.css` (raiz dos Static Files, nome com espaço); JS na própria página |
| Módulo/guia | `modulos/perfil/` (`Etapas-perfil-prototipo.md`, `Etapas-perfil-privacidade.md`) |
| Protótipo | `pen_dev/Meu perfil (com trajetória).png`, `pen_dev/Meu perfil · aba Dados pessoais.png`, `pen_dev/Meu perfil · foto de perfil (Drawer).png` (`07` §4.10 a §4.12) |

Perfil da pessoa: faixa do topo (avatar, nome, cargo, tempo de casa, e-mail, Alterar foto), abas Trajetória e Dados pessoais, gestor e colegas. Também mostra o perfil de outra pessoa (vindo do organograma), com dados pessoais só para a própria pessoa, a linha de gestão e o RH.

## Estrutura

```
Page 2: Meu Perfil
├── Breadcrumb Bar
│   └── cabeçalho-do-perfil "Cabeçalho do perfil" (20 · Dynamic Content · @/blank-with-attributes)
│         return pkg_perfil.render_cabecalho(to_number(:P2_ID_COLABORADOR default null on conversion error));
│         Page Items to Submit: P2_ID_COLABORADOR
└── Body
    ├── P2_ID_COLABORADOR (10 · Hidden · valor não protegido · Storage Per Request)
    └── perfil-do-colaborador "Perfil do Colaborador" (20 · Dynamic Content · @/blank-with-attributes)
          return pkg_perfil.render(to_number(:P2_ID_COLABORADOR default null on conversion error));
```

## Lógica

- **Computations / Validations:** —
- **Processes:** `PERFIL_DRAWER_FOTO` (Ajax Callback, 10, sem autorização própria) → `apex_util.prn(pkg_perfil.render_drawer_foto(x01))`. O package recusa o ID de outra pessoa (teste da Situação de 04/11/2026).
- **Dynamic Actions:** —
- **JavaScript da página:**
  - `obterFotoDrawer`/`abrirDrawerFoto`: cria um `<dialog class="org-drawer">` e carrega o conteúdo pelo `PERFIL_DRAWER_FOTO`.
  - `carregarFotosPerfil`: troca `img[data-perfil-foto]` pela URL da página 44 (`foto?session=...&x01=<arquivo>`).
  - Clique em `.perfil-tab-btn`: alterna as abas Trajetória/Dados pessoais.
  - `[data-acao='abrir-foto-drawer']` abre o painel; `[data-acao='fechar-foto']` fecha.

## Dados

- `pkg_perfil` (`modulos/perfil/02_pkg_perfil_prototipo.pks`/`.pkb`; o `01_pkg_perfil.pkb` é a versão anterior). Constantes de destino: perfil 2 (`P2_ID_COLABORADOR`), chat 4, organograma 3 (`P3_ID_FOCO`).
- Lê `vw_org_colaborador`, `colaborador`, `empresa`, e a trajetória de `vw_movimentacao_valida` + `historico_carreira` (com `cargo` e `departamento`). Quem vê o quê: `pkg_historico_carreira.fn_pode_ver_colaborador`.
- Multiempresa: `vw_org_colaborador` filtra a empresa da sessão depois do `modulos/isolamento-empresas` §2 (aplicação não confirmada no export; é objeto de banco). Outra empresa → "Colaborador não encontrado." (`Etapas-perfil-privacidade.md`, "Quem vê o quê").

## Navegação

- Chega por: menu Minha carreira › Meu perfil; menu do usuário no header (página 0); "Ver perfil completo" do organograma (página 3, `P2_ID_COLABORADOR` com checksum).
- Vai para: página 4 ("Conversar"), página 3 ("Organograma", com `P3_ID_FOCO`), página 44 (fotos).

## Pegadinhas e pendências

- `P2_ID_COLABORADOR` precisa ficar **Per Request (Memory Only)**: assim "Meu perfil" volta para a própria pessoa depois de ver um colega (`Etapas-perfil-privacidade.md` §2.2).
- "Salvar foto" não tem ação; depende do guia `modulos/arquivos/Etapas-upload-foto-perfil.md` (CD-75). Recorte de foto não existe (`Etapas-perfil-prototipo.md`, "O que fica diferente do protótipo").
- Testes pendentes (`Etapas-perfil-prototipo.md`, Situação): 6 e 9 (celular), 13 em pessoa com promoção, afastamento na app; conta de outra empresa sem teste (CD-61).
- O `02-paginas.md` §2 ainda lista a página como placeholder na tabela-resumo; o `08` §3 também. Vale este `.apx`.

## Referências

- [Guia do protótipo do perfil](../../../modulos/perfil/Etapas-perfil-prototipo.md)
- [Guia de privacidade do perfil](../../../modulos/perfil/Etapas-perfil-privacidade.md)
- [Fotos no bucket (página 44)](../../../modulos/arquivos/Etapas-fotos-object-storage.md) · [Upload de foto](../../../modulos/arquivos/Etapas-upload-foto-perfil.md)
- [02 · Páginas, página 2](../02-paginas.md)
