# Implementation Plan

- [x] 1. Reverter SpiritualCertificationRepository para configuração do backup


  - Alterar `_collectionName` de `certification_requests` para `spiritual_certifications`
  - Alterar todas as referências de `requestedAt` para `createdAt` nas queries
  - Alterar referências de `reviewedAt` para `processedAt` onde aplicável
  - _Requirements: 1.1, 1.2, 2.1, 2.2, 2.3_



- [ ] 2. Reverter CertificationApprovalService para configuração do backup
  - Alterar todas as queries de `certification_requests` para `spiritual_certifications`
  - Alterar ordenação de `requestedAt` para `createdAt` em `getPendingCertificationsStream()`
  - Alterar ordenação de `reviewedAt` para `processedAt` em `getCertificationHistoryStream()`
  - Alterar campo de atualização de `reviewedAt` para `processedAt` em `approveCertification()`
  - Alterar campo de atualização de `reviewedAt` para `processedAt` em `rejectCertification()`


  - Garantir que `approveCertification()` e `rejectCertification()` usem `spiritual_certifications` consistentemente
  - _Requirements: 1.1, 1.2, 2.1, 2.2, 2.3, 5.1, 5.2, 5.3_

- [ ] 3. Reverter Cloud Functions para configuração do backup
  - Alterar trigger de `certification_requests/{requestId}` para `spiritual_certifications/{requestId}` em `sendCertificationRequestEmail`
  - Alterar trigger de `certification_requests/{requestId}` para `spiritual_certifications/{requestId}` em `sendCertificationApprovalEmail`
  - Alterar referências de `requestedAt` para `createdAt` no template de email


  - Alterar queries de `certification_requests` para `spiritual_certifications` em `processApproval`
  - Alterar queries de `certification_requests` para `spiritual_certifications` em `processRejection`
  - Alterar campo de atualização de `reviewedAt` para `processedAt` nas funções HTTP
  - _Requirements: 1.1, 1.3, 2.1, 2.2, 4.1, 4.2, 4.3_





- [ ] 4. Atualizar Firestore Security Rules
  - Consolidar regras para usar apenas `spiritual_certifications`
  - Remover seção duplicada de `certification_requests`


  - Garantir validação de campo `proofFileUrl` (não `proofUrl`)
  - Garantir validação de campos `createdAt` e `processedAt`
  - _Requirements: 1.4, 3.1, 3.2, 3.3_






- [ ] 5. Deploy das alterações no Firebase
- [ ] 5.1 Deploy das Firestore Rules
  - Executar `firebase deploy --only firestore:rules`

  - Verificar no console que regras foram atualizadas
  - _Requirements: 1.4_

- [ ] 5.2 Deploy das Cloud Functions
  - Executar `firebase deploy --only functions`

  - Verificar no console que functions foram atualizadas
  - Monitorar logs para erros de deploy
  - _Requirements: 1.3, 4.1, 4.2, 4.3_

- [x] 6. Verificar sistema funcionando

- [ ] 6.1 Testar criação de certificação no app
  - Criar nova solicitação de certificação
  - Verificar no Firebase Console que documento foi salvo em `spiritual_certifications`
  - Verificar que campos `createdAt`, `proofFileUrl`, `status` estão corretos
  - _Requirements: 1.1, 2.1, 3.1_

- [ ] 6.2 Testar painel admin
  - Abrir painel admin de certificações
  - Verificar que certificações pendentes aparecem
  - Verificar ordenação por `createdAt`
  - _Requirements: 5.1, 5.2_

- [ ] 6.3 Testar aprovação de certificação
  - Aprovar uma certificação pendente
  - Verificar que campo `processedAt` foi atualizado
  - Verificar que status mudou para `approved`
  - _Requirements: 5.3, 2.2_

- [ ] 6.4 Testar envio de emails
  - Verificar logs das Cloud Functions
  - Confirmar que email foi enviado ao criar certificação
  - Confirmar que email foi enviado ao aprovar certificação
  - _Requirements: 4.1, 4.2_
