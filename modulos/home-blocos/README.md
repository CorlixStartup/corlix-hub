# Blocos da Home · tabelas e dados de demonstração

Tabelas dos blocos da página 1 que não tinham onde guardar os dados: Feedbacks recebidos, Pesquisa de clima, Próximos eventos, conversa 1:1 do Meu gestor, Férias disponíveis e Meu PDI. O passo a passo no Builder está em `modulos/home/Etapas-home.md` §8.

| Arquivo | O que faz |
|---|---|
| `01_ddl_blocos.sql` | Cria `FEEDBACK`, `PESQUISA`, `PESQUISA_RESPOSTA`, `EVENTO`, `CONVERSA_1A1`, `FERIAS_PERIODO`, `PDI` e `PDI_OBJETIVO` (todas com `ID_EMPRESA`). Reexecutável |
| `02_dados_demo.sql` | Exemplos para uma pessoa (login ou ID em `c_colaborador`), com datas relativas a hoje |
| `03_remover_dados_demo.sql` | Remove os exemplos do 02 (menos o período de férias, que não dá para separar de um real) |
| `instalar.sql` | Só as tabelas, pelo SQLcl |

As telas próprias desses assuntos (Feedbacks, PDI, Minhas aprovações...) estão nos protótipos de `pen_dev/` e ainda não existem; quando forem feitas, partem destas tabelas. Por isso a Home ainda não tem "Ver todos" nesses blocos.

## Situação

| Data | Estado |
|---|---|
| 10/11/2026 | Versionado na branch `feature/home-prototipo-completo`; **não executado** no banco |
