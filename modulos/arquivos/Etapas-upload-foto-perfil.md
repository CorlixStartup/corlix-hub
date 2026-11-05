# Foto de perfil · ligar o botão "Salvar foto"

Hoje o botão "Salvar foto" não tem ação, e nenhum código grava `COLABORADOR.FOTO_URL`. Este guia faz a própria pessoa conseguir trocar a foto, com o arquivo indo para o bucket privado `corlix-fotos`. Os caminhos do Builder são do **APEX 26.1.5**. Os do Console do OCI podem mudar: se a tela estiver diferente, mande um print. Tarefa: CD-75.

> **Pré-requisito:** `Etapas-fotos-object-storage.md` e `modulos/perfil/Etapas-perfil-prototipo.md` já aplicados, com as fotos abrindo pela página 44.

## Como funciona

1. A pessoa escolhe a imagem em **Alterar foto**.
2. O navegador recorta o centro em quadrado, reduz para 512 x 512 px e gera um JPEG novo, sem metadados como a localização. A prévia aparece na hora.
3. **Salvar foto** manda o JPEG ao servidor, que confere a sessão, a empresa e o conteúdo do arquivo.
4. O servidor grava no bucket com um nome novo, como `<id_colaborador>_<data e hora>.jpg`, e atualiza `FOTO_URL`.
5. A foto anterior é apagada do bucket, se foi gerada por este envio para a mesma pessoa.

O navegador nunca fala direto com o bucket. Só a própria pessoa troca a própria foto: o servidor usa o usuário logado e não aceita um ID vindo da tela.

## 1. OCI: criar o acesso de gravação

Faça no **mesmo domínio** do `corlix-hub-fotos`. Nos exemplos, é o `Corlix`.

1. Em *Identity & Security › Domains › Corlix › User management*, crie:
   - o grupo `corlix-hub-fotos-escrita`;
   - o usuário `corlix-hub-fotos-escrita`, com **Use the email address as the username** desligado, um e-mail do time e esse grupo marcado. Depois de criar, em **Edit user capabilities**, deixe ligado só **API keys**.
2. Em *Identity & Security › Policies › Create Policy*, no compartimento raiz, clique em **Show manual editor** e cole:

   ```text
   Allow group 'Corlix'/'corlix-hub-fotos-escrita' to manage objects in tenancy where target.bucket.name = 'corlix-fotos'
   ```

3. No usuário, em **API keys › Add API key**, escolha **Generate API key pair**, baixe a chave privada e clique em **Add**. **Não abra o `.pem` com dois cliques**, porque o Mac tenta importá-lo no Acesso às Chaves.

> **Nunca coloque a chave privada, os OCIDs ou a impressão digital em chat, ticket ou repositório.**

## 2. APEX: criar a segunda Web Credential

Em *App Builder › Workspace Utilities › Web Credentials › Create*:

| Campo | Valor |
|---|---|
| Name | `Corlix OCI Fotos Escrita` |
| Static ID | `CORLIX_OCI_FOTOS_ESCRITA` |
| Authentication Type | **OCI Native Authentication** |
| OCI User ID | O valor de `user=` do novo usuário, sem `user=` |
| OCI Private Key | Conteúdo do `.pem`, de `BEGIN` até `END`, sem a linha `OCI_API_KEY` |
| OCI Tenancy ID | O valor de `tenancy=` |
| OCI Public Key Fingerprint | O valor de `fingerprint=` |
| Valid for URLs | `https://objectstorage.sa-saopaulo-1.oraclecloud.com/n/<namespace>/b/corlix-fotos/` |

Para copiar a chave no Terminal sem abrir o arquivo:

```bash
sed '/OCI_API_KEY/d' ~/Downloads/"<arquivo>.pem" | pbcopy
```

Confira se o **Static ID** ficou exatamente como na tabela. O APEX pode preenchê-lo sozinho a partir do nome.

## 3. Banco

Em *SQL Workshop › SQL Scripts › Upload*, envie e rode um arquivo por vez, **nesta ordem**:

1. `modulos/arquivos/03_ddl_foto_escrita.sql`
2. `modulos/arquivos/04_pkg_foto_perfil.pks`
3. `modulos/arquivos/04_pkg_foto_perfil.pkb`
4. `modulos/perfil/02_pkg_perfil_prototipo.pkb`

No SQL Commands, um comando por vez, sem `;` no final:

```sql
update arquivo_config set cd_credencial_escrita = 'CORLIX_OCI_FOTOS_ESCRITA' where id_config = 1
```

```sql
commit
```

```sql
select object_name, object_type, status from user_objects
 where object_name in ('PKG_FOTO_PERFIL', 'PKG_PERFIL') order by 1, 2
```

Todos devem estar `VALID`.

## 4. Static files

Em *Shared Components › Static Application Files*, envie estes dois arquivos, substituindo os atuais com o mesmo nome:

- `modulos/perfil/Meu Perfil.css`
- `modulos/perfil/Meu Perfil.min.css`

## 5. Builder: página 2

### 5.1 Criar o processo

Em *Processing › Ajax Callback*, crie um processo:

| Atributo | Valor |
|---|---|
| Name | `SALVAR_FOTO` |
| Type | **Execute Code** |
| PL/SQL Code | `pkg_foto_perfil.ajax_salvar;` |

O nome precisa ser exatamente `SALVAR_FOTO`.

### 5.2 Colar o JavaScript

Em *Page › JavaScript › Execute when Page Loads*, cole o conteúdo de `modulos/arquivos/foto-perfil.js` **no fim**, sem apagar o que já existe. Salve a página.

## 6. Testar

Limpe o cache do navegador antes (`Cmd+Shift+R`).

| # | Conta | Faça | Esperado |
|---|---|---|---|
| 1 | Colaborador | Abra **Alterar foto** | **Salvar foto** fica desativado até escolher uma imagem |
| 2 | Colaborador | Escolha um PDF | "Escolha uma imagem em JPG ou PNG.", com o botão desativado |
| 3 | Colaborador | Escolha um arquivo acima de 5 MB | "A imagem precisa ter até 5 MB." |
| 4 | Colaborador | Escolha uma foto retangular | Prévia quadrada, com o centro da imagem |
| 5 | Colaborador | Clique em **Salvar foto** | A página recarrega com a foto nova, no perfil e no cabeçalho |
| 6 | Colega | Abra a Início, o Organograma ou a Busca | A foto nova aparece. Pode levar até 1 hora em quem já tinha a antiga aberta |
| 7 | Colaborador | Envie outra foto. No Cloud Shell, liste os objetos com o ID da pessoa | Só o arquivo mais novo fica no bucket |
| 8 | Colaborador | Abra o perfil de outra pessoa | Sem **Alterar foto** |

Para o teste 7, troque `<id>` pelo `ID_COLABORADOR`:

```bash
oci os object list --bucket-name corlix-fotos --prefix "empresa/1/fotos/<id>_" --all --query 'data[].name'
```

## Se não funcionar

| Sintoma | Causa provável | Correção |
|---|---|---|
| "O envio de fotos ainda não foi configurado." | `CD_CREDENCIAL_ESCRITA` vazio | Rode o `update` e o `commit` do §3 |
| "Não foi possível salvar a foto agora." | Falha na credencial ou no bucket. O motivo fica no debug da app, não na tela | Confira o Static ID, a policy e o domínio. Com a página em debug, procure "Falha ao salvar a foto" |
| "Não foi possível falar com o servidor." | Falta o processo `SALVAR_FOTO`, ou o nome está diferente | Confira o §5.1 |
| **Salvar foto** não ativa | Faltou o JavaScript do §5.2, ou o `.pkb` do perfil não foi reinstalado | Confira os §3 e §5.2 |
| Salvou, mas a foto não aparece | A foto não abre pela página 44 | Veja a tabela "Se não funcionar" de `Etapas-fotos-object-storage.md` |
| Foto antiga continua no bucket | A foto anterior não foi gerada por este envio, ou a exclusão falhou | Fotos com nome antigo não são apagadas. O motivo da falha fica no debug |

## Voltar atrás

Apague o processo `SALVAR_FOTO` e o trecho colado no JavaScript. Os arquivos já enviados continuam no bucket, e `FOTO_URL` continua apontando para eles.

## O que fica diferente do protótipo

- **Recorte:** o protótipo promete ajustar o recorte. Aqui ele é sempre o centro da imagem, e a prévia mostra o resultado antes de salvar.
- **Quem envia:** só a própria pessoa. Envio pelo RH ou em lote fica para outra tarefa, que um piloto pode exigir.
