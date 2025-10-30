# Implementation Plan - Sistema de Certificação Espiritual com Verificação

- [x] 1. Criar modelos de dados e enums


  - Criar `CertificationRequestModel` com todos os campos necessários
  - Criar enum `CertificationStatus` (pending, approved, rejected)
  - Implementar métodos `fromFirestore()` e `toFirestore()`
  - _Requirements: 1.5, 6.3_



- [ ] 2. Implementar Repository para Firestore
  - Criar `SpiritualCertificationRepository`
  - Implementar método `createRequest()` para salvar solicitação
  - Implementar método `getByUserId()` para buscar solicitações do usuário
  - Implementar `getPendingRequests()` com Stream para admin
  - Implementar `updateStatus()` para aprovar/rejeitar


  - Implementar `updateUserCertificationStatus()` para atualizar campo do usuário
  - _Requirements: 1.5, 3.1, 3.3, 5.1_

- [ ] 3. Implementar serviço de upload de arquivos
  - Criar `CertificationFileUploadService`
  - Implementar validação de tipo de arquivo (PDF, JPG, JPEG, PNG)
  - Implementar validação de tamanho (máx 5MB)



  - Implementar upload para Firebase Storage em `/certifications/{userId}/{timestamp}`
  - Implementar callback de progresso do upload
  - Implementar tratamento de erros de upload
  - _Requirements: 1.3, 6.1, 6.2, 6.3, 6.4_




- [ ] 4. Criar componente de upload de arquivo
  - Criar `FileUploadComponent`
  - Implementar seleção de arquivo com `file_picker`
  - Mostrar preview do arquivo selecionado
  - Exibir barra de progresso durante upload
  - Mostrar mensagens de erro de validação
  - _Requirements: 1.2, 1.3, 6.1, 6.4_

- [ ] 5. Implementar serviço principal de certificação
  - Criar `SpiritualCertificationService`
  - Implementar `createCertificationRequest()` que:
    - Faz upload do arquivo
    - Salva solicitação no Firestore



    - Dispara envio de email para admin
  - Implementar `getUserRequests()` para histórico
  - Implementar `approveCertification()` que:
    - Atualiza status para approved
    - Atualiza `isSpiritualCertified` do usuário
    - Cria notificação in-app
  - Implementar `rejectCertification()` que:


    - Atualiza status para rejected
    - Cria notificação in-app
  - _Requirements: 1.5, 1.6, 3.3, 3.4, 4.1, 4.2, 7.1_

- [ ] 6. Implementar serviço de email
  - Criar `CertificationEmailService`
  - Implementar `sendNewRequestEmailToAdmin()` com:


    - Template HTML com dados do usuário
    - Links para aprovar/rejeitar
    - Link para download do comprovante
  - Configurar envio para sinais.app@gmail.com
  - Implementar tratamento de erros de envio
  - _Requirements: 2.1, 2.2, 2.3, 2.4_




- [ ] 7. Criar formulário de solicitação
  - Criar `CertificationRequestFormComponent`
  - Implementar campo de email da compra com validação
  - Implementar campo de email do app (pré-preenchido)
  - Integrar `FileUploadComponent`
  - Implementar validação de campos obrigatórios
  - Habilitar botão "Enviar" apenas quando válido
  - _Requirements: 1.1, 1.2, 1.4_

- [ ] 8. Criar tela de solicitação de certificação
  - Criar `SpiritualCertificationRequestView`
  - Implementar design com fundo âmbar/dourado


  - Integrar `CertificationRequestFormComponent`
  - Implementar envio da solicitação
  - Mostrar mensagem de sucesso após envio
  - Implementar navegação de volta
  - _Requirements: 1.1, 1.5, 1.6_



- [ ] 9. Criar componente de histórico de solicitações
  - Criar `CertificationHistoryComponent`
  - Listar solicitações do usuário ordenadas por data
  - Mostrar status com ícones (⏱️ pending, ✅ approved, ❌ rejected)
  - Mostrar data de cada solicitação
  - Permitir reenvio se rejeitada

  - _Requirements: 7.1, 7.2, 7.3, 7.4_

- [ ] 10. Integrar histórico na tela de solicitação
  - Adicionar `CertificationHistoryComponent` na `SpiritualCertificationRequestView`
  - Mostrar histórico abaixo do formulário
  - Ocultar formulário se há solicitação pendente
  - Mostrar apenas status se já aprovado
  - _Requirements: 7.1, 7.2, 7.3_

- [x] 11. Criar card de solicitação para admin

  - Criar `CertificationRequestCardComponent`
  - Exibir foto, nome e emails do usuário
  - Mostrar data da solicitação
  - Adicionar botão para visualizar comprovante
  - Adicionar botões "Aprovar" e "Rejeitar"
  - _Requirements: 3.2, 3.3_



- [ ] 12. Criar visualizador de comprovante
  - Criar `CertificationProofViewerComponent`
  - Implementar visualização de PDF
  - Implementar visualização de imagens
  - Adicionar botão de download
  - Implementar zoom para imagens



  - _Requirements: 3.2, 6.5_

- [ ] 13. Criar painel admin de certificações
  - Criar `SpiritualCertificationAdminView`
  - Listar solicitações pendentes usando Stream
  - Integrar `CertificationRequestCardComponent`


  - Implementar ação de aprovar com confirmação
  - Implementar ação de rejeitar com campo de motivo opcional
  - Atualizar lista em tempo real
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_



- [ ] 14. Implementar sistema de notificações in-app
  - Criar notificação quando certificação é aprovada
  - Criar notificação quando certificação é rejeitada
  - Implementar navegação ao clicar na notificação
  - Integrar com sistema de notificações existente
  - _Requirements: 4.1, 4.2, 4.3, 4.4_



- [ ] 15. Atualizar exibição do selo no perfil
  - Verificar campo `isSpiritualCertified` no perfil
  - Exibir selo dourado quando true


  - Mostrar "Certificado ✓" no próprio perfil
  - Exibir selo para outros usuários
  - Mostrar botão "Solicitar Certificação" quando false
  - _Requirements: 5.1, 5.2, 5.3, 5.4_



- [ ] 16. Adicionar navegação para certificação
  - Adicionar opção "Certificação Espiritual" em "Vitrine de Propósito"
  - Implementar navegação para `SpiritualCertificationRequestView`
  - Adicionar navegação do botão no perfil



  - _Requirements: 1.1, 5.4_

- [ ] 17. Configurar regras de segurança do Firebase
  - Atualizar Storage rules para `/certifications/{userId}/{fileName}`
  - Atualizar Firestore rules para `spiritual_certifications`
  - Testar permissões de leitura/escrita
  - _Requirements: 6.2, 6.3_

- [ ] 18. Criar documentação de uso
  - Criar guia para usuários solicitarem certificação
  - Criar guia para admin aprovar/rejeitar
  - Documentar estrutura de dados no Firebase
  - Criar FAQ sobre certificação
  - _Requirements: Todos_

- [ ] 19. Testar fluxo completo
  - Testar solicitação de certificação
  - Verificar recebimento de email
  - Testar aprovação via painel admin
  - Verificar notificação in-app
  - Confirmar selo aparece no perfil
  - Testar rejeição e reenvio
  - _Requirements: Todos_
