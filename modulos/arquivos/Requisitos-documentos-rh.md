# Documentos de RH · requisitos antes de construir

Ainda não há módulo de documentos. Este texto registra o que documentos confidenciais e assinados exigem, para eles não nascerem usando o caminho das fotos. O holerite em PDF (CD-70) é o primeiro caso provável. A CD-72 mantém segurança, LGPD e holerite, mas não libera um módulo geral: o escopo mínimo é o necessário para a CD-70, salvo nova decisão.

## Fotos × documentos

| Item | Fotos (`Etapas-fotos-object-storage.md`) | Documentos |
|---|---|---|
| Quem vê | Colegas da mesma empresa | A pessoa e quem tem papel autorizado para aquele documento |
| Bucket e credencial | `corlix-fotos`, só leitura | Bucket e credencial próprios |
| Chave de criptografia | Gerenciada pela Oracle | Chave gerenciada no OCI Vault (proposta) |
| Endereço do arquivo | `x01`, sem checksum | Sem `x01`: item protegido por checksum e validação no servidor |
| Link temporário (PAR) | Possível, se ficar lento | Não usar |
| Cache no navegador | Privado, 1 hora | `no-store` |
| Registro de acesso | Não | Todo acesso (CD-60) |

## Requisitos propostos

- **Armazenamento:** bucket privado separado, com chave no OCI Vault, policy para o Object Storage usar a chave e plano de rotação. Perder a chave significa perder os documentos.
- **Acesso:** tabela de documentos com empresa, dono, tipo, classificação, nome do objeto, SHA-256, versão e situação. Regra de acesso em package, testada por perfil.
- **Registro:** quem enviou, viu, baixou, assinou e apagou (CD-60), sem o conteúdo do documento.
- **Integridade:** SHA-256 gravado no envio e conferido na entrega, versionamento do bucket e bloqueio de alteração em documento assinado.
- **Retenção:** prazo por tipo e descarte (CD-57 e CD-59). Retenção legal pode impedir a exclusão a pedido.
- **Envio:** validar o tipo real e o tamanho do arquivo, e avaliar antivírus.
- **Criptografia:** definir se a criptografia no servidor basta ou se algum tipo exige criptografia antes do envio.

## Assinatura: decisões antes de construir

- Com apoio jurídico, definir por tipo de documento qual nível de assinatura é necessário e se isso muda para documentos trabalhistas.
- Decidir entre integrar um provedor de assinatura e construir um aceite interno. A proposta é integrar: um aceite interno registra ciência, mas pode não bastar para todo documento.
- Definir o que guardar como prova: documento, hash, assinante, data e hora, IP e relatório do provedor.

A Lei 14.063/2020 define assinatura simples, avançada e qualificada, mas trata de interações com o poder público. Usá-la em relações privadas é uma referência, não uma regra direta. **Este texto não é parecer jurídico.**

## Pronto quando

- Decisões de assinatura registradas.
- Arquitetura aprovada.
- Primeiro tipo de documento entregue e testado com colaborador, gestor, RH e outra empresa.
