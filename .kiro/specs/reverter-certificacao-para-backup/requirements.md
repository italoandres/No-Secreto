# Requirements Document

## Introduction

O sistema de certificação espiritual não está funcionando após correções anteriores. A análise revelou que o backup funcional usava a collection `spiritual_certifications` com campos específicos (`createdAt`, `processedAt`), mas as correções mudaram para `certification_requests` com campos diferentes (`requestedAt`, `reviewedAt`). Este documento especifica os requisitos para reverter o sistema para a configuração do backup que funcionava.

## Glossary

- **CertificationSystem**: Sistema completo de certificação espiritual incluindo app Flutter, Cloud Functions e Firestore
- **BackupConfiguration**: Configuração do código de backup que estava funcionando corretamente
- **FirestoreCollection**: Collection no banco de dados Firestore onde documentos são armazenados
- **CloudFunction**: Função serverless que executa no Firebase Cloud Functions
- **SecurityRules**: Regras de segurança do Firestore que controlam acesso aos dados

## Requirements

### Requirement 1

**User Story:** Como desenvolvedor, eu quero reverter todas as collections para `spiritual_certifications`, para que o sistema use a mesma estrutura do backup funcional

#### Acceptance Criteria

1. WHEN o CertificationSystem salva um documento, THE FirestoreCollection SHALL usar o nome `spiritual_certifications`
2. WHEN o CertificationSystem consulta documentos, THE FirestoreCollection SHALL buscar em `spiritual_certifications`
3. WHEN CloudFunction escuta mudanças, THE CloudFunction SHALL monitorar a collection `spiritual_certifications`
4. THE SecurityRules SHALL definir permissões para a collection `spiritual_certifications`

### Requirement 2

**User Story:** Como desenvolvedor, eu quero usar os campos de data do backup (`createdAt`, `processedAt`), para que as queries e ordenações funcionem corretamente

#### Acceptance Criteria

1. WHEN o CertificationSystem cria um documento, THE CertificationSystem SHALL usar o campo `createdAt` para timestamp de criação
2. WHEN o CertificationSystem processa uma certificação, THE CertificationSystem SHALL usar o campo `processedAt` para timestamp de processamento
3. WHEN o CertificationSystem ordena resultados, THE CertificationSystem SHALL ordenar por `createdAt` ou `processedAt`
4. THE FirestoreCollection SHALL ter índices configurados para `createdAt` e `processedAt`

### Requirement 3

**User Story:** Como desenvolvedor, eu quero que o campo de prova use `proofFileUrl`, para que as regras de segurança validem corretamente

#### Acceptance Criteria

1. WHEN o CertificationSystem salva uma certificação, THE CertificationSystem SHALL usar o campo `proofFileUrl` para a URL da prova
2. WHEN SecurityRules validam um documento, THE SecurityRules SHALL verificar a presença de `proofFileUrl`
3. THE CertificationSystem SHALL rejeitar documentos sem o campo `proofFileUrl`

### Requirement 4

**User Story:** Como desenvolvedor, eu quero que Cloud Functions usem os mesmos campos do backup, para que emails e notificações sejam enviados corretamente

#### Acceptance Criteria

1. WHEN CloudFunction detecta nova certificação, THE CloudFunction SHALL ler campos `createdAt`, `userId`, `status` e `proofFileUrl`
2. WHEN CloudFunction envia email, THE CloudFunction SHALL usar dados da collection `spiritual_certifications`
3. WHEN CloudFunction atualiza status, THE CloudFunction SHALL usar campo `processedAt` para timestamp

### Requirement 5

**User Story:** Como desenvolvedor, eu quero que o painel admin use a mesma configuração do backup, para que certificações apareçam corretamente

#### Acceptance Criteria

1. WHEN o painel admin carrega certificações pendentes, THE CertificationSystem SHALL buscar em `spiritual_certifications` com status `pending`
2. WHEN o painel admin ordena certificações, THE CertificationSystem SHALL ordenar por `createdAt`
3. WHEN o painel admin aprova/reprova, THE CertificationSystem SHALL atualizar campo `processedAt`
4. THE CertificationSystem SHALL exibir todas as certificações da collection `spiritual_certifications`
