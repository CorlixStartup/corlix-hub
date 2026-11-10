# Comunicados de demonstração da Home

Cria 5 comunicados com capa, para o carrossel da página 1 ter o que mostrar. Os textos são fictícios, sem nomes de pessoas. As imagens foram geradas por IA no pen.dev em 10/11/2026.

| # | Arquivo | Título | Publicado há | Para |
|---|---|---|---|---|
| 1 | `demo-comunicado-1.jpg` | Novembro Azul: roda de conversa sobre saúde do homem | 1 dia (selo "Novo") | Todos |
| 2 | `demo-comunicado-2.jpg` | Trabalho híbrido: novas regras a partir de 1º de dezembro | 4 dias (selo "Novo") | Todos |
| 3 | `demo-comunicado-3.jpg` | Treinamento obrigatório de segurança da informação | 9 dias | Departamento com "Tecnologia" no nome (ou Todos) |
| 4 | `demo-comunicado-4.jpg` | Confraternização de fim de ano: reserve o dia 18 de dezembro | 13 dias | Todos |
| 5 | `demo-comunicado-5.jpg` | Resultados do 3º trimestre: crescemos 12% em relação ao ano passado | 20 dias | Todos |

As imagens têm 1600×900 (16:9) e o assunto principal fica à direita, porque o carrossel escurece o lado esquerdo para o texto. As datas são calculadas a partir do dia em que o script roda: o selo "Novo" vale para os dois primeiros só por 7 dias.

## Como criar

1. **Imagens:** vá em *Shared Components › Static Application Files › Create File*. Envie os 5 `demo-comunicado-N.jpg` com **Directory** `modulos/home/comunicados-demo` (a mesma convenção do `home.css`). Confirme que o *File Name* final ficou `modulos/home/comunicados-demo/demo-comunicado-1.jpg` e assim por diante.
2. **Autor:** abra `01_comunicados_demo.sql` e troque `TROQUE_PELO_LOGIN` pelo login de uma conta **com colaborador** na empresa que vai receber os comunicados, por exemplo alguém do RH. A empresa vem desse colaborador.
3. **Rodar:** vá em *SQL Workshop › SQL Scripts › Upload*, envie o arquivo e clique em **Run**. A saída deve listar "Criado: ..." 5 vezes e terminar em "5 comunicado(s) criado(s) na empresa N." Se aparecer "AVISO: imagem ... não encontrada", o caminho do passo 1 está diferente; o comunicado é criado sem capa (remova com o script 02, corrija e rode de novo).
4. **Conferir:** abra a página 1 com uma conta da mesma empresa. O carrossel mostra os 5, com o selo "Novo" nos dois primeiros.
5. **Opcional:** depois de rodar, os arquivos de *Static Application Files* podem ser apagados, porque as imagens já foram copiadas para a tabela `COMUNICADO`.

O script pode ser rodado de novo sem problema: ele pula os comunicados que já existem na empresa. Para criar em outra empresa, troque o login e rode outra vez.

## Como remover

Rode `02_remover_comunicados_demo.sql` em *SQL Workshop › SQL Scripts*. Ele apaga só os comunicados de demonstração, que são identificados pelo `NOME_ARQUIVO` `demo-comunicado-N.jpg`, em todas as empresas. As leituras saem junto.

## Observações

- A imagem 5 mostra "Q3 Growth" em inglês na tela da TV. Ela é pequena e fica sob o degradê, mas troque a imagem se incomodar.
- O comunicado 3 mostra "Para: <departamento de TI>". Ainda assim, a Home exibe a lista para toda a empresa, porque a query da página 1 não filtra por departamento.
- O script lê as imagens da view `APEX_APPLICATION_STATIC_FILES` (colunas `FILE_NAME`, `MIME_TYPE` e `FILE_CONTENT`). Os nomes dessas colunas não puderam ser confirmados na documentação indexada (`casos.py`). Se aparecer `ORA-00904` ou `ORA-00942`, rode o script pelo SQL Workshop do workspace da app e anote o erro aqui.

## Situação

| Data | Estado |
|---|---|
| 10/11/2026 | Versionado; **não executado** no banco. O SQL foi conferido só por leitura contra o DDL de `COMUNICADO` (`database/ddl/03-tabelas.sql`) |
