# Implementation Plan - Melhorias no Sistema de Chat de Matches

- [x] 1. Reorganizar navegação de matches





  - Remover ícone de matches da home view
  - Adicionar navegação para vitrine menu em community_info_view



  - Criar vitrine_menu_view com opções de matches, explorar e configurar
  - Adicionar rota '/vitrine-menu' no main.dart
  - _Requirements: 1.1, 1.2, 1.3, 1.4_






- [ ] 2. Corrigir alinhamento de mensagens no chat
  - Modificar _buildMessagesList() para comparar senderId com currentUserId
  - Garantir que isMe seja calculado corretamente (senderId == _auth.currentUser?.uid)


  - Testar com dois usuários diferentes para verificar alinhamento
  - _Requirements: 2.1, 2.2, 2.3, 2.4_



- [ ] 3. Implementar indicadores de leitura
- [ ] 3.1 Adicionar método _markMessagesAsRead() no initState
  - Buscar mensagens não lidas do outro usuário
  - Marcar como isRead: true usando batch update
  - Zerar contador unreadCount do usuário atual
  - _Requirements: 3.1, 3.2, 3.5, 3.6_

- [ ] 3.2 Atualizar visual dos indicadores de leitura
  - Modificar _buildMessageBubble() para mostrar ícones corretos
  - Usar Icons.done para não lida (cinza)



  - Usar Icons.done_all para lida (azul)
  - Mostrar indicadores apenas para mensagens do usuário atual (isMe)
  - _Requirements: 3.3, 3.4_

- [ ] 4. Corrigir erro de Hero tags duplicados
  - Atualizar Hero tag no romantic_match_chat_view para 'chat_profile_${chatId}_${otherUserId}'
  - Atualizar Hero tag no accepted_matches_view para 'match_profile_${chatId}_${otherUserId}'
  - Verificar se não há mais erros de Hero tags no console
  - _Requirements: 5.1, 5.2, 5.3_

- [x] 5. Validar visual do estado vazio
  - Confirmar que o estado vazio mostra todos os elementos corretos
  - Verificar animações (coração pulsante, corações flutuantes)
  - Testar transição de estado vazio para lista de mensagens
  - _Requirements: 4.1, 4.2, 4.3_

- [ ] 6. Testes e validação final
  - Testar fluxo completo: Home → Comunidade → Vitrine Menu → Matches → Chat
  - Testar envio de mensagens com dois usuários diferentes
  - Verificar alinhamento correto (direita/esquerda)
  - Verificar indicadores de leitura (✓ e ✓✓)
  - Verificar ausência de erros no console
  - _Requirements: Todos_
