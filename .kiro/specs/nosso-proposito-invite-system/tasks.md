# Implementation Plan

- [x] 1. Criar componente de botão de convite fixo


  - Implementar PurposeInviteButton component
  - Adicionar design com gradiente azul/rosa consistente
  - Integrar com estado de parceria do usuário
  - _Requirements: 1.1, 5.1, 5.4_



- [ ] 2. Implementar banner de restrição de chat
  - Criar ChatRestrictionBanner component
  - Exibir mensagem "Você precisa ter uma pessoa adicionada para iniciar esse chat"
  - Posicionar no topo do chat quando usuário não tem parceiro

  - Integrar botão "Adicionar Parceiro" no banner
  - _Requirements: 4.1, 4.2, 4.3, 5.1_

- [ ] 3. Restaurar e melhorar modal de convite
  - Verificar se _showAddPartnerDialog existe e está funcional
  - Corrigir chamada do modal a partir do botão de convite

  - Melhorar design das abas "Buscar Usuário" e "Mensagem do Convite"
  - Aplicar gradiente azul/rosa consistente no modal
  - _Requirements: 1.2, 1.3, 1.4, 5.4_

- [ ] 4. Implementar lógica de restrição de mensagens
  - Desabilitar campo de mensagem quando usuário não tem parceiro


  - Mostrar banner de restrição em vez do campo de mensagem
  - Habilitar campo automaticamente quando parceria é criada
  - Adicionar validação antes de envio de mensagem
  - _Requirements: 4.1, 4.2, 4.4, 4.5_


- [ ] 5. Corrigir sistema de @menções
  - Verificar funcionamento do MentionAutocompleteComponent
  - Corrigir bug de menções não sendo processadas
  - Melhorar integração com PurposePartnershipRepository.sendMentionInvite
  - Adicionar feedback visual quando menção é enviada
  - _Requirements: 3.1, 3.2, 3.3, 3.5_


- [ ] 6. Melhorar componente de convites recebidos
  - Verificar se PurposeInvitesComponent está sendo exibido corretamente
  - Posicionar componente abaixo do banner de restrição
  - Garantir que convites aparecem em tempo real
  - Melhorar feedback visual das ações (aceitar/recusar/bloquear)

  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 5.2_

- [ ] 7. Implementar validações de segurança
  - Adicionar validação de usuário existente antes de enviar convite
  - Verificar se usuário não está bloqueado
  - Validar se não há convite pendente duplicado

  - Verificar compatibilidade de sexo para parcerias
  - _Requirements: 6.1, 6.2, 6.3, 6.4_

- [ ] 8. Adicionar tratamento de erros robusto
  - Implementar try-catch em todas as operações de convite
  - Mostrar mensagens de erro específicas para cada tipo de problema



  - Adicionar loading states durante operações
  - Implementar retry automático para falhas de rede
  - _Requirements: 6.5, 1.5, 2.5_

- [ ] 9. Integrar todos os componentes no chat
  - Adicionar PurposeInviteButton condicionalmente no topo do chat
  - Posicionar ChatRestrictionBanner quando necessário
  - Manter PurposeInvitesComponent para convites recebidos
  - Garantir que componentes aparecem/desaparecem baseado no estado
  - _Requirements: 5.1, 5.2, 5.3, 4.4_

- [ ] 10. Testar fluxo completo de convites
  - Testar envio de convite de parceria com mensagem personalizada
  - Testar recebimento e resposta a convites
  - Testar sistema de @menções com convites automáticos
  - Testar restrições de chat sem parceiro
  - Verificar que todos os estados visuais funcionam corretamente
  - _Requirements: 1.5, 2.5, 3.4, 4.5, 5.5_