# Fotos · sair dos Static Files para um bucket privado

Este guia tira as fotos de colaboradores dos Static Application Files, que abrem sem login, e as coloca num bucket privado do OCI Object Storage, na mesma região da app (`sa-saopaulo-1`). Os caminhos do Builder são do **APEX 26.1.5**. Os do Console do OCI podem mudar: se a tela estiver diferente, mande um print.

**Como fica:** o navegador pede a foto à página 44. A página confere a sessão e a empresa, busca o arquivo no bucket com a credencial, que só o servidor conhece, e devolve a imagem. Ninguém acessa o bucket direto.

| Antes | Depois |
|---|---|
| Quem tem o endereço abre a foto, sem login | Só quem está logado e é da mesma empresa |
| Fotos dentro de `corlixhub/`, no repositório público | Fotos só no bucket |
| Criptografia não garantida como requisito | Criptografia em repouso do Object Storage |

> **Criptografia não substitui controle de acesso.** O bucket criptografa o que guarda, mas quem controla quem vê a foto é a página 44.

Faça na ordem. As fotos antigas só saem no §7, depois dos testes, então até lá dá para voltar atrás.

> **Nunca coloque a chave privada, os OCIDs ou a impressão digital em chat, ticket ou repositório.** Eles só entram na Web Credential do §3.

## 1. OCI: criar o bucket

No Console do OCI, região **Brazil East (São Paulo)**, em *Storage › Object Storage & Archive Storage › Buckets › Create Bucket*:

| Campo | Valor |
|---|---|
| Name | `corlix-fotos` |
| Default Storage Tier | **Standard** |
| Encryption | **Encrypt using Oracle managed keys** |

Depois de criar, confira:

- **Visibility:** **Private**.
- **Namespace:** anote, porque ele entra no §4.

## 2. OCI: criar o acesso só de leitura

O acesso é de um usuário técnico que só lê esse bucket.

1. Em *Identity & Security › Domains › (seu domínio)*, crie:
   - o usuário `corlix-hub-fotos`, com **Use the email address as the username** desligado e um e-mail do time. Depois de criar, em **Edit user capabilities**, deixe ligado só **API keys**;
   - o grupo `corlix-hub-fotos`, com esse usuário dentro.
2. Em *Identity & Security › Policies › Create Policy*, preencha **Name** e **Description**, escolha em **Compartment** o mesmo compartimento do bucket e clique em **Show manual editor**. Cole uma destas linhas:

   | Onde está o bucket | Linha |
   |---|---|
   | No compartimento raiz (root) | `Allow group corlix-hub-fotos to read objects in tenancy where target.bucket.name = 'corlix-fotos'` |
   | Em outro compartimento | `Allow group corlix-hub-fotos to read objects in compartment <compartimento> where target.bucket.name = 'corlix-fotos'` |

   Se o grupo estiver num domínio que não seja o padrão, escreva `'<domínio>'/'corlix-hub-fotos'`.
3. No usuário, em *API Keys › Add API Key*, gere o par de chaves e baixe a chave privada. Anote o **User OCID**, o **Tenancy OCID** e o **Fingerprint** que aparecem no final.

## 3. APEX: criar a Web Credential

Em *App Builder › Workspace Utilities › Web Credentials › Create* (confirmar no 26.1.5):

| Campo | Valor |
|---|---|
| Name | `Corlix OCI Fotos` |
| Static ID | `CORLIX_OCI_FOTOS` |
| Authentication Type | **OCI Native Authentication** |
| OCI User ID | User OCID do §2 |
| OCI Private Key | Conteúdo do arquivo `.pem` do §2 |
| OCI Tenancy ID | Tenancy OCID do §2 |
| OCI Public Key Fingerprint | Fingerprint do §2 |
| Valid for URLs | `https://objectstorage.sa-saopaulo-1.oraclecloud.com/n/<namespace>/b/corlix-fotos/` |

Depois de salvar, apague a chave `.pem` da pasta de downloads, ou guarde-a num cofre de senhas.

## 4. Banco: instalar e configurar

Em *SQL Workshop › SQL Scripts › Upload*, envie e rode um arquivo por vez, **nesta ordem**:

1. `modulos/arquivos/01_ddl_arquivos.sql`
2. `modulos/arquivos/02_pkg_arquivos.pks`
3. `modulos/arquivos/02_pkg_arquivos.pkb`

No SQL Commands, troque `<namespace>` e rode:

```sql
insert into arquivo_config (ds_regiao, ds_namespace, nm_bucket_fotos, cd_credencial)
values ('sa-saopaulo-1', '<namespace>', 'corlix-fotos', 'CORLIX_OCI_FOTOS')
```

Salve com `commit` e confira, um comando por vez, sem `;` no final:

```sql
select object_name, object_type, status from user_objects
 where object_name = 'PKG_ARQUIVOS' order by 2
```

Os dois devem estar `VALID`. Para saber em que empresas há fotos:

```sql
select id_empresa, count(*) from colaborador
 where trim(foto_url) is not null group by id_empresa order by 1
```

## 5. OCI: enviar as fotos

Cada foto fica em `empresa/<id_empresa>/fotos/<arquivo>`. Se a consulta do §4 mostrou só a empresa 1, no **Cloud Shell** ou na **OCI CLI**, a partir de uma cópia do repositório:

```bash
oci os object bulk-upload \
  --bucket-name corlix-fotos \
  --src-dir "corlixhub/shared-components/static-files/Fotos Colaboradores" \
  --object-prefix "empresa/1/fotos/" \
  --content-type image/jpeg
```

Confira a quantidade. Hoje são 292 arquivos:

```bash
oci os object list --bucket-name corlix-fotos --prefix "empresa/1/fotos/" --all --query 'length(data)'
```

Se houver colaboradores de outra empresa com foto, envie os arquivos deles com o prefixo da empresa certa. Foto no prefixo errado não aparece.

## 6. Builder: entregar pela página 44

### 6.1 Criar a página 44

Em *Create Page › Blank Page*:

| Grupo | Atributo | Valor |
|---|---|---|
| Identification | Page Number | `44` |
| Identification | Name | `Foto` |
| Identification | Alias | `FOTO` |
| Navigation | Use Breadcrumb e Use Navigation | **Desligados** |
| Security | Authorization Scheme | **COLABORADOR** |
| Security | Page Access Protection | **Unrestricted** |

Em *Processing › Pre-Rendering › Before Header*, crie um processo:

| Atributo | Valor |
|---|---|
| Name | `Entregar foto` |
| Type | **Execute Code** |
| PL/SQL Code | `pkg_arquivos.entregar_foto(apex_application.g_x01);` |

O nome do arquivo vem em `x01`, que não tem checksum. Isso é seguro aqui porque quem pode ver o organograma já vê as fotos dos colegas, e o package recusa qualquer foto que não seja da empresa da sessão. **Não use esse padrão para documentos confidenciais.**

### 6.2 Testar antes de trocar as telas

Logado, abra numa aba `.../corlixhub/foto?session=<sessão>&x01=<arquivo>.jpg`, com o número da sessão da URL atual e o nome de uma foto. A imagem deve abrir. Se der erro, resolva pela tabela "Se não funcionar" antes de continuar.

### 6.3 Trocar as páginas 1, 3 e 29

Nas três, em *Page › JavaScript › Function and Global Variable Declaration*, há duas linhas iguais, salvo o nome do atributo. Elas ficam em `cxHomeCarregarFotos` (página 1), `orgCarregarFotos` (página 3) e `cxBuscaCarregarFotos` (página 29).

Troque as linhas:

```javascript
const caminho = img.dataset.cxFoto.split("/").map(encodeURIComponent).join("/");
```
```javascript
img.src = apex.env.APP_FILES + caminho;
```

Por estas, nesta ordem e sem mexer na linha `removeAttribute` que fica entre elas:

```javascript
const nome = img.dataset.cxFoto.split("/").pop();
```
```javascript
img.src = "foto?session=" + apex.env.APP_SESSION + "&x01=" + encodeURIComponent(nome);
```

Na **página 3**, use `img.dataset.orgFoto` no lugar de `img.dataset.cxFoto`.

### 6.4 Trocar a página 2

Em *Page › JavaScript › Execute when Page Loads*, na função `carregarFotosPerfil`, troque:

```javascript
img.src = base + "Fotos Colaboradores/" + encodeURIComponent(nome);
```

Por:

```javascript
img.src = "foto?session=" + apex.env.APP_SESSION + "&x01=" + encodeURIComponent(nome);
```

### 6.5 Trocar o avatar do cabeçalho

**Processo:** em *Shared Components › Application Processes › APP_USER_FOTO*, troque a linha `'Fotos Colaboradores/' || C.foto_url` por:

```sql
apex_page.get_url(p_page => 44, p_x01 => regexp_substr(trim(C.foto_url), '[^/]+$'))
```

**Página 0:** na região do cabeçalho, troque `src="#APP_FILES#&APP_USER_FOTO."` por:

```html
src="&APP_USER_FOTO!ATTR."
```

### 6.6 Trocar o Chat (página 4)

**Consulta:** na região de contatos, troque a linha `else 'Fotos Colaboradores/' || c.foto_url` por:

```sql
else apex_page.get_url(p_page => 44, p_x01 => regexp_substr(trim(c.foto_url), '[^/]+$'))
```

**Template:** em *Shared Components › Templates › chat-contatos* (confirmar no 26.1.5), troque `src="#APP_FILES##FOTO_URL#"` por:

```html
src="#FOTO_URL#"
```

## 7. Testar e só então apagar

| # | Conta | Faça | Esperado |
|---|---|---|---|
| 1 | Colaborador | Abra Início, Organograma, Busca, Chat e Meu perfil | As fotos aparecem, inclusive a do cabeçalho |
| 2 | Colaborador | Copie o endereço de uma foto e abra numa janela anônima | Não abre a imagem |
| 3 | Colaborador | Na URL do §6.2, use `x01=../../x.jpg` | Erro 404 |
| 4 | Conta de outra empresa, se houver | Use o nome de uma foto da empresa 1 | Erro 404 |
| 5 | Colaborador | Abra o Organograma numa equipe grande, com a rede lenta do navegador ligada | A página continua utilizável. Se ficar lenta, avise |
| 6 | Quem não tem foto | Abra **Meu perfil** | As iniciais aparecem |
| 7 | Qualquer um | Abra o endereço direto do bucket, `https://objectstorage.sa-saopaulo-1.oraclecloud.com/n/<namespace>/b/corlix-fotos/o/empresa/1/fotos/<arquivo>.jpg` | Erro, sem a imagem |

Com tudo certo, apague a pasta **Fotos Colaboradores** em *Shared Components › Static Application Files*. O próximo backup tira as fotos de `corlixhub/`. Elas continuam no histórico do Git, o que não é um problema porque são fictícias.

> **Antes de carregar fotos reais:** confira se elas não voltaram para os Static Files nem para o repositório.

## Se não funcionar

| Sintoma | Causa provável | Correção |
|---|---|---|
| A URL do §6.2 responde 404 para toda foto | Falta a linha em `ARQUIVO_CONFIG`, credencial errada ou arquivo fora do prefixo | Confira o §4, o Static ID e o caminho do objeto |
| Erro citando `ORA-24247` ou ACL | A saída HTTPS do banco está bloqueada | Mande a mensagem completa. Pode exigir um ajuste de rede no banco |
| Status 401 ou 404 do OCI, mesmo com o arquivo lá | Policy ou API Key incorretas | Confira o §2. O Object Storage responde 404 quando não há permissão |
| Algumas fotos não aparecem | `FOTO_URL` com nome diferente do arquivo no bucket | Compare o nome exato, com maiúsculas e minúsculas |
| Imagem quebrada no cabeçalho, mas não nas telas | §6.5 aplicado pela metade | Confira o processo e a página 0 |
| Fotos somem depois de abrir uma janela de diálogo | O endereço relativo `foto?...` saiu do caminho da app | Avise qual tela é |
| Telas lentas com muitas fotos | Cada foto passa pelo banco e pelo bucket na primeira vez | Avise. O caminho seguinte é usar links temporários (PAR) só para fotos |

## Voltar atrás

Até o §7, os arquivos antigos continuam nos Static Files. Basta desfazer os §6.3 a §6.6.

## Documentos de RH

Este guia cobre só as **fotos**. Documentos confidenciais têm requisitos mais fortes e **não devem usar** este bucket, esta credencial ou o padrão `x01`. Os requisitos estão em `Requisitos-documentos-rh.md`.
