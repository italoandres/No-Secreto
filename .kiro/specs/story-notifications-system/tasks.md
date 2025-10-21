# Plano de Implementação - Sistema de Notificações de Stories

- [x] 1. Criar modelo de dados e repositório base


  - Implementar NotificationModel com serialização/deserialização para Firestore
  - Criar NotificationRepository com operações CRUD básicas
  - Adicionar índices necessários no firestore.indexes.json
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7_



- [ ] 2. Implementar serviço de notificações
  - Criar NotificationService com métodos utilitários
  - Implementar função para criar notificações de comentários


  - Adicionar formatação de tempo relativo e truncamento de texto
  - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [x] 3. Criar componente de ícone de notificação


  - Implementar NotificationIconComponent com ícone de sino
  - Adicionar badge com contador de notificações não lidas
  - Integrar stream para atualização em tempo real do contador
  - _Requirements: 1.1, 1.2, 1.3, 1.4_



- [ ] 4. Implementar página de notificações
  - Criar NotificationsView com AppBar e lista de notificações
  - Implementar estado vazio quando não há notificações



  - Adicionar funcionalidade de marcar todas como lidas ao abrir
  - _Requirements: 2.1, 2.2, 2.3, 5.1, 5.7_

- [ ] 5. Criar componente de item de notificação
  - Implementar NotificationItemComponent com layout de notificação
  - Adicionar avatar, nome do usuário, prévia do comentário e tempo
  - Implementar indicador visual para notificações não lidas
  - _Requirements: 5.2, 5.3, 5.4, 5.5, 5.6_

- [ ] 6. Integrar ícone na capa do chat principal
  - Localizar e modificar a capa do chat principal (provavelmente chat_view.dart)
  - Adicionar NotificationIconComponent ao lado do ícone de comunidade
  - Testar navegação para página de notificações
  - _Requirements: 1.1, 1.3_

- [ ] 7. Implementar navegação de notificações
  - Adicionar funcionalidade de tap em notificações para navegar ao story
  - Implementar verificação se story ainda existe antes de navegar
  - Adicionar tratamento de erro para stories não encontrados
  - _Requirements: 2.4, 3.5_

- [ ] 8. Integrar com sistema de comentários existente
  - Localizar onde comentários são salvos no sistema atual
  - Adicionar chamada para criar notificação após salvar comentário
  - Implementar verificação para não notificar o próprio autor
  - _Requirements: 6.1, 6.2, 6.3, 6.4_

- [ ] 9. Implementar funcionalidades avançadas da página
  - Adicionar pull-to-refresh na lista de notificações
  - Implementar paginação para carregar notificações em lotes
  - Adicionar opção de deletar notificações individuais
  - _Requirements: 2.1, 2.2_

- [ ] 10. Adicionar regras de segurança no Firestore
  - Implementar regras de segurança para coleção notifications
  - Testar permissões de leitura, escrita e atualização
  - Validar que usuários só acessam suas próprias notificações
  - _Requirements: 4.1, 4.2_

- [ ] 11. Implementar tratamento de erros e estados
  - Adicionar tratamento de erro na criação de notificações
  - Implementar estados de loading, erro e vazio na página
  - Adicionar retry automático em caso de falhas de rede
  - _Requirements: 2.1, 2.3_

- [ ] 12. Testes e refinamentos finais
  - Testar fluxo completo: comentário → notificação → visualização
  - Verificar performance com múltiplas notificações
  - Ajustar layout e animações conforme necessário
  - _Requirements: 1.1, 2.1, 3.1_