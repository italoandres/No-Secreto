# Implementation Plan - Sistema de Verificação de Certificação Espiritual

- [x] 1. Configurar estrutura do Firebase


  - Criar collections e configurar Security Rules para armazenamento seguro de solicitações
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 9.1, 9.2, 9.3, 9.4_



- [ ] 1.1 Criar Security Rules do Firestore
  - Implementar regras de acesso para `certification_requests` collection
  - Garantir que usuários só possam criar/ler suas próprias solicitações
  - Garantir que apenas admins possam aprovar/rejeitar


  - _Requirements: 8.1, 8.2, 9.1, 9.4_

- [x] 1.2 Criar Security Rules do Storage



  - Implementar regras para `certification_proofs` bucket
  - Limitar tamanho de arquivo a 5MB
  - Garantir que usuários só possam fazer upload de seus próprios comprovantes


  - _Requirements: 2.6, 8.4, 9.4_

- [ ] 2. Implementar modelo de dados aprimorado
  - Criar `CertificationRequestModel` com todos os campos necessários




  - _Requirements: 8.1, 8.2_

- [x] 2.1 Criar CertificationRequestModel


  - Implementar classe com campos: id, userId, userName, userEmail, purchaseEmail, proofUrl, status, timestamps
  - Adicionar métodos `fromFirestore()` e `toFirestore()`
  - Implementar enum `CertificationStatus` (pending, approved, rejected)
  - _Requirements: 8.1, 8.2_


- [ ] 2.2 Criar FileUploadResult model
  - Implementar classe para resultado de upload com downloadUrl, storagePath, fileSize, fileType
  - _Requirements: 2.1, 2.2, 2.3_


- [ ] 3. Implementar FileUploadService
  - Criar serviço para gerenciar upload de comprovantes para Firebase Storage
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_

- [ ] 3.1 Implementar método uploadCertificationProof
  - Fazer upload de arquivo para Storage em `certification_proofs/{userId}/{timestamp}_{filename}`
  - Implementar callback de progresso
  - Retornar URL de download
  - _Requirements: 2.1, 2.2, 2.3, 8.4_




- [ ] 3.2 Implementar validação de arquivo
  - Validar tamanho máximo de 5MB
  - Validar tipos permitidos (imagem: jpg, png, pdf)

  - Retornar erros claros se validação falhar
  - _Requirements: 2.6_

- [ ] 3.3 Implementar método deleteProof
  - Deletar arquivo do Storage quando necessário

  - Tratar erros de permissão
  - _Requirements: 2.5_

- [ ]* 3.4 Escrever testes unitários para FileUploadService
  - Testar upload com arquivo válido

  - Testar validação de tamanho
  - Testar validação de tipo
  - Testar tratamento de erros
  - _Requirements: 2.1, 2.2, 2.6_


- [ ] 4. Aprimorar CertificationRepository
  - Adicionar métodos para gerenciar solicitações de certificação
  - _Requirements: 8.1, 8.2, 8.3_

- [ ] 4.1 Implementar método createRequest
  - Salvar nova solicitação no Firestore com status "pending"
  - Incluir todos os campos necessários
  - Retornar ID da solicitação criada
  - _Requirements: 1.4, 8.1, 8.2_


- [ ] 4.2 Implementar método getUserRequest
  - Buscar solicitação do usuário por userId
  - Retornar null se não existir
  - Implementar stream para atualizações em tempo real

  - _Requirements: 7.1, 7.2, 7.3, 8.3_

- [ ] 4.3 Implementar método updateRequestStatus
  - Atualizar status da solicitação (approved/rejected)
  - Adicionar timestamp de revisão e ID do admin

  - Adicionar motivo de rejeição se aplicável

  - _Requirements: 5.3, 5.4, 5.5, 8.3_

- [x] 4.4 Implementar método getPendingRequests

  - Buscar todas as solicitações com status "pending"
  - Ordenar por data de solicitação
  - Implementar stream para painel admin
  - _Requirements: 5.1, 5.2_


- [ ]* 4.5 Escrever testes unitários para CertificationRepository
  - Testar criação de solicitação
  - Testar busca por userId
  - Testar atualização de status
  - Testar busca de pendentes

  - _Requirements: 8.1, 8.2, 8.3_

- [ ] 5. Implementar EmailNotificationService aprimorado
  - Criar serviço para enviar emails de notificação com templates HTML
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 6.1, 6.2, 6.3_

- [ ] 5.1 Implementar método notifyAdminNewRequest
  - Enviar email para sinais.app@gmail.com quando nova solicitação é criada
  - Incluir dados do usuário e link para comprovante
  - Usar template HTML profissional



  - _Requirements: 4.1, 4.2, 4.4_

- [x] 5.2 Implementar método notifyUserApproval

  - Enviar email ao usuário quando solicitação é aprovada
  - Incluir mensagem de parabéns e benefícios do selo
  - Usar template HTML profissional
  - _Requirements: 6.1, 6.3_

- [ ] 5.3 Implementar método notifyUserRejection
  - Enviar email ao usuário quando solicitação é rejeitada

  - Incluir motivo da rejeição e instruções para reenvio
  - Usar template HTML profissional
  - _Requirements: 6.2, 6.3_


- [ ] 5.4 Criar templates HTML de email
  - Template para notificação ao admin
  - Template para aprovação ao usuário
  - Template para rejeição ao usuário
  - _Requirements: 4.4, 6.1, 6.2_


- [ ] 5.5 Implementar tratamento de erros de email
  - Registrar falhas de envio sem bloquear operação
  - Implementar retry para emails críticos
  - _Requirements: 4.3, 6.4_

- [x]* 5.6 Escrever testes unitários para EmailNotificationService

  - Testar envio de email ao admin
  - Testar envio de email ao usuário
  - Testar templates corretos
  - Testar tratamento de falhas
  - _Requirements: 4.1, 4.2, 4.3, 6.1, 6.2, 6.3_


- [ ] 6. Implementar CertificationRequestService
  - Criar serviço para orquestrar lógica de negócio das solicitações
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 5.3, 5.4, 7.4_

- [ ] 6.1 Implementar método createRequest
  - Validar dados de entrada (emails, arquivo)
  - Fazer upload do comprovante via FileUploadService
  - Salvar solicitação via CertificationRepository
  - Enviar email ao admin via EmailNotificationService


  - Retornar ID da solicitação
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 4.1_


- [ ] 6.2 Implementar método getUserRequest
  - Buscar solicitação atual do usuário
  - Retornar null se não existir
  - _Requirements: 7.1, 7.2, 7.3_


- [ ] 6.3 Implementar método approveRequest
  - Atualizar status para "approved"
  - Adicionar selo ao perfil do usuário
  - Enviar email de aprovação ao usuário
  - Registrar admin e timestamp
  - _Requirements: 5.3, 5.5, 6.1_


- [ ] 6.4 Implementar método rejectRequest
  - Atualizar status para "rejected"
  - Salvar motivo da rejeição
  - Enviar email de rejeição ao usuário
  - Registrar admin e timestamp
  - _Requirements: 5.4, 5.5, 6.2_

- [ ] 6.5 Implementar método resubmitRequest
  - Permitir reenvio após rejeição



  - Criar nova solicitação com status "pending"
  - Manter histórico da solicitação anterior
  - _Requirements: 7.4_


- [ ] 6.6 Implementar validações de negócio
  - Validar formato de emails
  - Verificar se usuário já tem solicitação pendente
  - Verificar se usuário já tem selo aprovado
  - _Requirements: 3.1, 3.2, 3.3, 9.2, 9.3_


- [ ]* 6.7 Escrever testes unitários para CertificationRequestService
  - Testar criação de solicitação com dados válidos
  - Testar validação de emails
  - Testar aprovação/rejeição
  - Testar reenvio após rejeição

  - _Requirements: 1.1, 1.2, 1.3, 1.4, 5.3, 5.4_

- [ ] 7. Criar CertificationStatusComponent
  - Implementar componente para exibir status visual da solicitação
  - _Requirements: 7.1, 7.2, 7.3, 7.4_


- [ ] 7.1 Implementar view de status pendente
  - Exibir badge "Aguardando Aprovação"
  - Mostrar mensagem "Em análise. Você receberá resposta em até 3 dias úteis"
  - Exibir data da solicitação
  - _Requirements: 1.5, 7.1_


- [ ] 7.2 Implementar view de status aprovado
  - Exibir badge "Aprovado" com ícone de verificação
  - Mostrar mensagem de confirmação do selo ativo
  - Exibir data de aprovação
  - Listar benefícios do selo
  - _Requirements: 7.2_


- [ ] 7.3 Implementar view de status rejeitado
  - Exibir badge "Rejeitado"
  - Mostrar motivo da rejeição
  - Exibir botão "Solicitar Novamente"
  - _Requirements: 7.3, 7.4_

- [ ]* 7.4 Escrever testes de widget para CertificationStatusComponent
  - Testar renderização de status pendente
  - Testar renderização de status aprovado
  - Testar renderização de status rejeitado
  - _Requirements: 7.1, 7.2, 7.3_




- [ ] 8. Modificar ProfileCertificationTaskView
  - Transformar página existente em formulário completo de solicitação

  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 2.1, 2.2, 2.3, 2.4, 2.5, 3.1, 3.2, 3.3, 3.4, 3.5_

- [ ] 8.1 Implementar formulário de solicitação
  - Adicionar campo "Email da Compra" com validação

  - Adicionar campo "Email do App" (pré-preenchido)
  - Adicionar botão de upload de comprovante
  - Adicionar preview do arquivo selecionado
  - _Requirements: 1.2, 2.1, 3.1, 3.2_

- [x] 8.2 Implementar lógica de upload

  - Integrar com FileUploadService
  - Exibir progress indicator durante upload
  - Permitir cancelar e selecionar outro arquivo
  - Validar arquivo antes de enviar
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_

- [x] 8.3 Implementar validação de formulário

  - Validar formato de emails
  - Validar presença de comprovante
  - Exibir mensagens de erro claras
  - Desabilitar botão de envio se inválido
  - _Requirements: 1.3, 3.1, 3.2, 3.3_


- [ ] 8.4 Implementar envio de solicitação
  - Chamar CertificationRequestService.createRequest
  - Exibir loading durante envio
  - Mostrar mensagem de sucesso com prazo de 3 dias úteis
  - Tratar erros e exibir feedback
  - _Requirements: 1.4, 1.5, 10.1, 10.2, 10.3, 10.4_

- [ ] 8.5 Implementar gerenciamento de estados
  - Estado inicial: formulário vazio
  - Estado pendente: exibir CertificationStatusComponent
  - Estado aprovado: exibir selo ativo
  - Estado rejeitado: permitir reenvio
  - _Requirements: 7.1, 7.2, 7.3, 7.4_

- [ ] 8.6 Implementar UI/UX aprimorada
  - Design limpo e intuitivo
  - Instruções claras em cada etapa
  - Feedback visual para todas as ações
  - Mensagens de erro acionáveis
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

- [ ]* 8.7 Escrever testes de widget para ProfileCertificationTaskView
  - Testar renderização do formulário
  - Testar validação de campos
  - Testar upload de arquivo
  - Testar envio de solicitação
  - Testar diferentes estados
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 7.1, 7.2, 7.3_

- [ ] 9. Aprimorar AdminCertificationPanelView
  - Adicionar funcionalidades de aprovação/rejeição ao painel existente
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

- [ ] 9.1 Implementar visualização de comprovante
  - Adicionar botão para visualizar comprovante anexado
  - Abrir imagem/PDF em modal ou nova aba
  - _Requirements: 5.2_

- [ ] 9.2 Implementar botão de aprovação
  - Adicionar botão "Aprovar" em cada solicitação
  - Exibir confirmação antes de aprovar
  - Chamar CertificationRequestService.approveRequest
  - Atualizar lista em tempo real
  - _Requirements: 5.3, 5.5_

- [ ] 9.3 Implementar botão de rejeição
  - Adicionar botão "Rejeitar" em cada solicitação
  - Exibir modal para inserir motivo da rejeição
  - Validar que motivo não está vazio
  - Chamar CertificationRequestService.rejectRequest
  - Atualizar lista em tempo real
  - _Requirements: 5.4, 5.5_

- [ ] 9.4 Implementar filtros e ordenação
  - Filtrar por status (pending, approved, rejected)
  - Ordenar por data de solicitação
  - Adicionar busca por nome/email
  - _Requirements: 5.1_

- [ ] 9.5 Implementar feedback visual
  - Loading durante aprovação/rejeição
  - Mensagens de sucesso/erro
  - Atualização em tempo real da lista
  - _Requirements: 5.3, 5.4, 5.5_

- [ ]* 9.6 Escrever testes de widget para AdminCertificationPanelView
  - Testar listagem de solicitações
  - Testar aprovação
  - Testar rejeição
  - Testar filtros
  - _Requirements: 5.1, 5.2, 5.3, 5.4_

- [ ] 10. Implementar testes de integração
  - Testar fluxos completos end-to-end
  - _Requirements: All_

- [ ]* 10.1 Testar fluxo completo de solicitação
  - Usuário preenche formulário
  - Upload de comprovante
  - Salvamento no Firebase
  - Email enviado ao admin
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 2.1, 4.1_

- [ ]* 10.2 Testar fluxo de aprovação
  - Admin aprova solicitação
  - Status atualizado no Firebase
  - Selo adicionado ao perfil
  - Email enviado ao usuário
  - _Requirements: 5.3, 5.5, 6.1_

- [ ]* 10.3 Testar fluxo de rejeição
  - Admin rejeita com motivo
  - Status atualizado no Firebase
  - Email enviado ao usuário
  - Usuário pode reenviar
  - _Requirements: 5.4, 5.5, 6.2, 7.4_

- [ ] 11. Documentação e deploy
  - Criar documentação e preparar para produção
  - _Requirements: All_

- [ ] 11.1 Criar documentação de usuário
  - Guia de como solicitar certificação
  - FAQ sobre o processo
  - Requisitos para aprovação
  - _Requirements: 10.1_

- [ ] 11.2 Criar documentação técnica
  - Arquitetura do sistema
  - Fluxos de dados
  - Configuração do Firebase
  - _Requirements: All_

- [ ] 11.3 Configurar monitoramento
  - Logs de erros
  - Métricas de uso
  - Alertas para falhas críticas
  - _Requirements: All_

- [ ] 11.4 Deploy gradual
  - Deploy em ambiente de teste
  - Testes com usuários beta
  - Deploy em produção
  - Monitoramento pós-deploy
  - _Requirements: All_
