# Imagens · página "Otimizar imagens" (p. 45)

As imagens dos comunicados estão gravadas do jeito que foram enviadas. As 5 da Home têm de 4,1 a 4,7 MB cada (comunicados 61 a 65), e a Home baixa 18,7 MB só de imagem (Lighthouse de 17/11/2026, `modulos/monitoramento/Etapas-monitoramento.md`). Este guia cria uma página de administração que troca essas imagens por versões em JPEG de até 1280 × 720 px, sem recriar os comunicados. Os caminhos do Builder são do **APEX 26.1.5**. Tarefa: CD-44.

## Como funciona

1. A página lista as imagens de comunicado **da empresa da sessão** com mais de 400 KB.
2. Em **Otimizar**, o navegador baixa a imagem (`OBTER_IMAGEM`), redesenha num canvas de até 1280 × 720 px, sem cortar e sem aumentar, e gera um JPEG com qualidade 0,82. O JPEG novo não leva metadados, como a localização.
3. O JPEG volta ao servidor (`SALVAR_IMAGEM`), que confere o papel `ADMIN_RH`, a empresa, o conteúdo (começo e fim de JPEG), o tamanho (até 1 MB) e se ficou menor que a original.
4. A original vai para a tabela `IMAGEM_ORIGINAL` e o comunicado passa a ter o JPEG, com `MIME_TYPE = image/jpeg` e o nome do arquivo terminando em `.jpg`.

**Otimizar todas** faz uma imagem por vez, para não pesar no servidor. A compressão é feita no navegador porque o banco não tem como redimensionar imagem (o Oracle Multimedia, com o `ORDImage`, saiu do banco no 19c).

Decisão: a original **é guardada** em `IMAGEM_ORIGINAL`, para voltar atrás se a versão nova ficar ruim. Depois de conferir, o time pode apagar as linhas (§6) e liberar o espaço.

## 1. Banco

Em *SQL Workshop › SQL Scripts › Upload*, envie e rode um arquivo por vez, **nesta ordem**:

1. `modulos/imagens/01_ddl_imagens.sql`
2. `modulos/imagens/02_pkg_imagens.pks`
3. `modulos/imagens/02_pkg_imagens.pkb`
4. `modulos/imagens/03_pkg_imagens_ui.pks`
5. `modulos/imagens/03_pkg_imagens_ui.pkb`

Ou, no Database Actions › SQL, abra `instalar.sql` e rode tudo com **Run Script** (F5).

Confira no SQL Commands, sem `;` no final:

```sql
select object_name, object_type, status from user_objects
 where object_name in ('IMAGEM_ORIGINAL', 'PKG_IMAGENS', 'PKG_IMAGENS_UI') order by 1, 2
```

Os cinco objetos devem estar `VALID`.

## 2. Static files

Em *Shared Components › Static Application Files › Create File*, envie os dois juntos:

- `modulos/imagens/imagens.css`
- `modulos/imagens/imagens.min.css`

## 3. Builder: criar a página 45

Em *App Builder › Create Page › Blank Page*:

| Campo | Valor |
|---|---|
| Page Number | `45` |
| Name | `Otimizar imagens` |
| Page Mode | Normal |
| Navigation › Use Breadcrumb / Use Navigation | Não |

### 3.1 Atributos da página

| Atributo | Valor |
|---|---|
| Appearance › Page Template | `Corlix - Standard Page` |
| CSS › File URLs | `#APP_FILES#imagens#MIN#.css` |
| Security › Authorization Scheme | `ADMIN_RH` |
| Security › Page Access Protection | `Arguments Must Have Checksum` |
| Navigation › Cursor Focus | `Do not focus cursor` |

### 3.2 Regiões

| Name | Type | Slot (Layout › Position) | Template | Source › PL/SQL Function Body returning a CLOB |
|---|---|---|---|---|
| `Cabeçalho` | Dynamic Content | `Breadcrumb Bar` | `Blank with Attributes (No Grid)` | `return pkg_imagens_ui.render_cabecalho;` |
| `Imagens` | Dynamic Content | `Body` | `Blank with Attributes` | `return pkg_imagens_ui.render_lista;` |

### 3.3 Processos

Em *Processing*, clique com o botão direito em **Ajax Callback › Create Process**, duas vezes:

| Name | Type | PL/SQL Code |
|---|---|---|
| `OBTER_IMAGEM` | Execute Code | `pkg_imagens_ui.ajax_obter;` |
| `SALVAR_IMAGEM` | Execute Code | `pkg_imagens_ui.ajax_salvar;` |

Os nomes precisam ser exatamente esses.

### 3.4 JavaScript

Em *Page › JavaScript › Execute when Page Loads*, cole o conteúdo de `modulos/imagens/imagens-pagina.js`. Salve.

A página fica fora do menu: abra pela URL (`.../r/corlixhub/otimizar-imagens`) ou pelo Builder. Ela é de uso pontual.

No export da página 45, procure:

```export-check
pagina: 45
page 45 | pageTemplate: @corlix-standard-page
page 45 | fileUrls: #APP_FILES#imagens#MIN#.css
page 45 | authorizationScheme: @admin-rh
page 45 | pageAccessProtection: argumentsMustHaveChecksum
page 45 | !inlineCss
region cabeçalho | pkg_imagens_ui.render_cabecalho
region cabeçalho | slot: breadcrumbBar
region cabeçalho | template: @/blank-with-attributes-no-grid
region imagens | pkg_imagens_ui.render_lista
region imagens | slot: body
process obter-imagem | name: OBTER_IMAGEM
process obter-imagem | pkg_imagens_ui.ajax_obter
process obter-imagem | point: ajaxCallback
process salvar-imagem | name: SALVAR_IMAGEM
process salvar-imagem | pkg_imagens_ui.ajax_salvar
process salvar-imagem | point: ajaxCallback
page 45 | data-cx-img-otimizar
```

## 4. Testar

Limpe o cache do navegador antes (`Cmd+Shift+R`). Os testes 4 a 6 **gravam no banco**: o time decide quando rodar.

| # | Conta | Faça | Esperado |
|---|---|---|---|
| 1 | Sem `ADMIN_RH` | Abra a página 45 pela URL | Acesso negado |
| 2 | RH | Abra a página 45 | Lista com os comunicados 61 a 65, do maior para o menor, e o total no rodapé |
| 3 | RH | Confira as linhas | Só comunicados da sua empresa |
| 4 | RH | Clique em **Otimizar** numa linha | "Baixando...", "Comprimindo...", "Salvando…" e depois "Otimizada: 4,5 MB → 2xx KB" (valores aproximados) |
| 5 | RH | Abra a Home | A imagem do comunicado aparece, nítida e sem fundo preto |
| 6 | RH | Clique em **Otimizar todas** | Uma linha por vez, até a última |
| 7 | RH | Recarregue a página 45 | "Nenhuma imagem de comunicado acima de 400 KB." |
| 8 | — | Rode o Lighthouse da Home de novo | Peso total bem abaixo dos 19,9 MB de antes |

Para conferir o teste 6 no SQL Commands:

```sql
select id_registro, round(nr_bytes / 1024) kb_antes, round(nr_bytes_novo / 1024) kb_depois, dh_troca
  from imagem_original order by id_registro
```

## 5. Voltar atrás

Se uma imagem nova ficar ruim, devolva a original. Troque `<id>` pelo `ID_COMUNICADO` e rode um comando por vez, sem `;`:

```sql
update comunicado c
   set (imagem, mime_type, nome_arquivo) = (
         select o.imagem, o.mime_type, o.nome_arquivo from imagem_original o
          where o.nm_tabela = 'COMUNICADO' and o.id_registro = c.id_comunicado
            and o.id_original = (select min(x.id_original) from imagem_original x
                                  where x.nm_tabela = 'COMUNICADO' and x.id_registro = c.id_comunicado))
 where c.id_comunicado = <id>
```

```sql
commit
```

## 6. Liberar o espaço das originais

Só depois de conferir as imagens novas na Home:

```sql
delete from imagem_original where nm_tabela = 'COMUNICADO' and dh_troca < sysdate - 7
```

```sql
commit
```

## Fica para depois

- **Logotipos (`EMPRESA.LOGOTIPO_EMPRESA`) e anexos de formação (`FORMACAO_COLABORADOR.BL_ANEXO`):** a tabela e o package já aceitam outros tipos (`NM_TABELA`); falta liberar no `check` e criar um `trocar_*` para cada um. Os logotipos podem ter transparência, que o JPEG perde: avaliar antes.
- **Comprimir já no envio da página 17:** o item Image Upload do APEX já tem *Resize To* (§4.7 de `modulos/comunicados/Etapas-comunicados.md`). Ligar este JavaScript ao item seria mais frágil que o recurso nativo, então não está previsto.

## Se não funcionar

| Sintoma | Causa provável | Correção |
|---|---|---|
| "Não foi possível falar com o servidor." | Falta um dos processos do §3.3, ou o nome está diferente | Confira os nomes `OBTER_IMAGEM` e `SALVAR_IMAGEM` |
| "Só o RH pode otimizar imagens." | A conta não tem o papel `ADMIN_RH` | Use uma conta do RH |
| "Sua sessão não está vinculada a uma empresa." | `G_ID_EMPRESA` vazio na sessão | Saia e entre de novo |
| "Não foi possível ler a imagem agora." ou "...salvar a imagem agora." | Erro no banco. O motivo fica no debug da app | Com a página em debug, procure `pkg_imagens_ui` |
| "Já está leve" | A versão comprimida ficou maior que a atual | Nada a fazer: a imagem continua como está |
| Imagem nova com fundo branco onde era transparente | PNG com transparência | Esperado no JPEG. Se não servir, volte a original (§5) |
| Página sem estilo | `imagens.min.css` não enviado | Confira o §2 |

## Situação

| Data | O quê |
|---|---|
| 17/11/2026 | Módulo criado na branch `feature/modulo-imagens`. Testado num Oracle 23ai local com as APIs do APEX simuladas: os dois packages compilam; a lista só mostra a empresa da sessão e escapa o título; `OBTER_IMAGEM` devolve a imagem em base64; `SALVAR_IMAGEM` recusa sem papel, sem empresa, conteúdo que não é JPEG, comunicado de outra empresa e JPEG maior que a atual; com um JPEG real (144 KB sobre 600 KB) grava, troca `MIME_TYPE` e a extensão e guarda a original. **Não aplicado na app** e sem teste no navegador (a compressão em canvas só roda lá). Próximo passo: §1 a §4 pelo time |
