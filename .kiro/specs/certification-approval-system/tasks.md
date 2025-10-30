# Implementation Plan - Sistema de Aprovação de Certificação Espiritual

- [x] 1. Atualizar Cloud Functions para incluir links de ação no email



  - Adicionar função para gerar tokens seguros de aprovação/reprovação
  - Atualizar template de email para incluir botões de Aprovar e Reprovar
  - Implementar validação de tokens com expiração de 7 dias




  - _Requirements: 1.1, 1.2, 1.3, 6.1, 6.2_

- [x] 2. Criar Cloud Functions para processar aprovação via link


  - Implementar função `processApproval` que valida token e atualiza Firestore



  - Verificar se solicitação já foi processada antes de atualizar
  - Marcar token como usado após processamento
  - Gerar página HTML de sucesso para exibir ao admin
  - Registrar ação no log de auditoria



  - _Requirements: 1.2, 1.4, 6.2, 6.3, 6.6_

- [x] 3. Criar Cloud Functions para processar reprovação via link



  - Implementar função `processRejection` que exibe formulário de motivo (GET)
  - Processar reprovação com motivo fornecido (POST)
  - Validar que motivo não está vazio antes de processar
  - Gerar página HTML de sucesso após reprovação



  - _Requirements: 1.3, 1.5, 6.2, 6.3_

- [x] 4. Implementar Cloud Function trigger para mudanças de status

  - Criar função `onCertificationStatusChange` que escuta updates em certifications
  - Detectar quando status muda de 'pending' para 'approved' ou 'rejected'
  - Chamar funções auxiliares para criar notificação, atualizar perfil, enviar emails
  - _Requirements: 3.1, 3.2, 4.1, 7.1, 7.2_

- [x] 5. Criar serviço de notificações de certificação



  - Implementar `CertificationNotificationService` no Flutter
  - Criar função para gerar notificação de aprovação com título e mensagem apropriados
  - Criar função para gerar notificação de reprovação incluindo motivo
  - Implementar handler para navegação ao tocar na notificação
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_




- [x] 6. Atualizar perfil do usuário com status de certificação


  - Adicionar campo `spirituallyCertified: true` no documento do usuário quando aprovado
  - Implementar função na Cloud Function para atualizar perfil automaticamente
  - Garantir que campo é atualizado de forma atômica
  - _Requirements: 4.1, 4.6_








- [x] 7. Criar componente de badge de certificação espiritual
  - Implementar `SpiritualCertificationBadge` widget com design dourado/laranja
  - Adicionar ícone de verificação e texto "Certificado Espiritualmente"
  - Implementar dialog informativo ao clicar no badge
  - Adicionar sombra e gradiente para destaque visual
  - _Requirements: 4.1, 4.2, 4.3_

- [x] 8. Integrar badge de certificação nas telas de perfil
  - Adicionar badge no cabeçalho da tela de perfil próprio
  - Adicionar badge no cabeçalho ao visualizar perfil de outros usuários
  - Adicionar badge nos cards de perfil na vitrine








  - Adicionar badge nos resultados de busca
  - Garantir que badge só aparece se `spirituallyCertified == true`
  - _Requirements: 4.1, 4.2, 4.4, 4.5, 4.6_

- [x] 9. Criar serviço de aprovação de certificações
  - Implementar `CertificationApprovalService` com métodos approve e reject
  - Implementar stream para obter certificações pendentes em tempo real
  - Implementar stream para obter histórico de certificações
  - Adicionar filtros por status e userId no histórico
  - _Requirements: 2.1, 2.6, 5.1, 5.2, 5.3, 5.4, 8.1, 8.2_

- [x] 10. Criar painel administrativo completo de certificações
  - Implementar `CertificationApprovalPanelView` com TabBar (Pendentes/Histórico)
  - Criar `CertificationRequestCard` para solicitações pendentes com botões de ação
  - Criar `CertificationHistoryCard` para histórico com informações de processamento
  - Implementar fluxos de aprovação e reprovação com dialogs e validações
  - Adicionar filtros por status e busca por usuário no histórico
  - Implementar estados de loading, erro e vazio com mensagens apropriadas
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 5.1, 5.2, 5.5, 5.6, 8.1, 8.2, 8.3, 8.5_

- [ ] 11. Implementar sistema de auditoria e logs
  - Criar coleção `certification_audit_log` no Firestore
  - Registrar todas as ações de aprovação/reprovação com timestamp
  - Incluir informações de quem executou a ação e via qual método
  - Registrar tentativas de uso de tokens inválidos
  - _Requirements: 5.2, 6.5, 6.6_

- [ ] 12. Criar emails de confirmação para administradores
  - Implementar função para enviar email ao admin após aprovação
  - Implementar função para enviar email ao admin após reprovação
  - Incluir resumo da ação tomada e link para o painel
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [x] 13. Adicionar botão de acesso ao painel no menu admin
  - Adicionar item "Certificações" no menu administrativo
  - Verificar permissão de admin antes de exibir
  - Navegar para `CertificationApprovalPanelView` ao clicar
  - Adicionar badge com contador de pendentes no ícone
  - _Requirements: 2.1_

- [ ] 14. Adicionar regras de segurança no Firestore
  - Permitir apenas admins lerem/escreverem em certifications
  - Permitir usuários lerem apenas suas próprias certificações
  - Validar estrutura de dados nas regras
  - _Requirements: 6.1, 6.2_
