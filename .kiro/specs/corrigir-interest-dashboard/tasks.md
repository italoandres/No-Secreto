# Implementation Plan: Correção do Interest Dashboard

- [x] 1. Corrigir filtro de status no repositório


  - Adicionar "accepted" e "rejected" aos status válidos
  - Implementar filtro por tempo (7 dias) para notificações respondidas
  - Manter notificações pendentes/visualizadas sempre visíveis
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 5.1, 5.2, 5.3_


- [ ] 2. Implementar busca de nome do remetente
  - Adicionar state para armazenar nome carregado
  - Criar método _loadSenderName() no EnhancedInterestNotificationCard
  - Buscar nome do Firestore quando fromUserName está vazio
  - Adicionar fallback para "Usuário Anônimo"
  - Exibir nome correto no card

  - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [ ] 3. Corrigir navegação para perfil
  - Alterar navegação de '/profile-display' para '/vitrine-display'
  - Passar argumentos corretos (userId, isOwnProfile: false)
  - Adicionar logs de navegação

  - Tratar erro quando userId não existe
  - _Requirements: 2.1, 2.2, 2.3, 2.4_

- [ ] 4. Implementar botões corretos por status
  - Criar método _buildActionButtons() com lógica por status
  - Para "pending"/"viewed": botões "Não Tenho" e "Também Tenho"
  - Para "accepted": badge "MATCH!" + botão "Conversar"


  - Para "rejected": mensagem informativa
  - Para "mutual_match": apenas botão "Conversar"
  - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [ ] 5. Implementar navegação para chat
  - Criar método _navigateToChat()
  - Gerar chatId correto (match_userId1_userId2)
  - Navegar para '/chat' com argumentos corretos
  - Adicionar tratamento de erro
  - _Requirements: 6.3_

- [ ] 6. Executar script de correção de nomes
  - Executar fix_empty_fromUserName.dart
  - Verificar logs de correção
  - Confirmar que notificações foram atualizadas
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [ ] 7. Testar fluxo completo
  - Testar exibição de nome correto
  - Testar navegação para perfil
  - Testar botões por status
  - Testar navegação para chat
  - Testar filtro de 7 dias
  - Verificar que notificações aceitas aparecem
  - _Requirements: Todos_
