# Implementation Plan

- [x] 1. Criar modelos de dados para chat e mensagens


  - Implementar `MatchChatModel` com serialização JSON
  - Implementar `ChatMessageModel` com validação
  - Implementar `AcceptedMatchModel` para lista de matches
  - Criar testes unitários para todos os modelos
  - _Requirements: 1.1, 2.1, 3.1_



- [x] 2. Implementar repositório de matches aceitos
  - Criar `AcceptedMatchesRepository` para buscar matches aceitos
  - Integrar com sistema de notificações existente
  - Filtrar notificações com status 'accepted'
  - Mapear dados para `AcceptedMatchModel`
  - Implementar cache local para performance
  - _Requirements: 1.1, 1.4_

- [x] 3. Criar serviço de gerenciamento de chat
  - Implementar `MatchChatService` para operações de chat
  - Criar método `createOrGetChatId` para gerar ID único do chat
  - Implementar lógica de expiração de 30 dias
  - Criar método `isChatExpired` para verificar validade
  - Adicionar testes unitários para todas as operações
  - _Requirements: 2.3, 5.1, 5.2_

- [x] 4. Implementar repositório de chat e mensagens



  - Criar `MatchChatRepository` para operações Firebase
  - Implementar CRUD para chats na coleção `match_chats`
  - Implementar CRUD para mensagens na coleção `chat_messages`
  - Criar streams para atualizações em tempo real
  - Implementar sistema de contadores de mensagens não lidas
  - _Requirements: 3.2, 3.3, 6.3_





- [x] 5. Criar componente de card de match
  - Implementar `MatchChatCard` para exibir match na lista
  - Mostrar foto, nome e data do match
  - Adicionar indicador de mensagens não lidas
  - Implementar estado de chat expirado
  - Adicionar animações de tap
  - _Requirements: 1.2, 6.2, 6.3_



- [x] 6. Implementar tela de lista de matches aceitos
  - Criar `AcceptedMatchesView` com lista scrollável
  - Integrar com `AcceptedMatchesRepository`
  - Implementar estados de loading, empty e error
  - Adicionar pull-to-refresh
  - Implementar navegação para chat individual
  - _Requirements: 1.1, 1.3, 6.1, 6.4_

- [x] 7. Criar componente de bolha de mensagem
  - Implementar `ChatMessageBubble` para exibir mensagens
  - Diferenciar mensagens enviadas e recebidas
  - Mostrar timestamp e status de leitura
  - Implementar diferentes tipos de conteúdo (texto, imagem)
  - Adicionar animações de entrada
  - _Requirements: 3.1, 3.3_

- [x] 8. Implementar banner de expiração do chat
  - Criar `ChatExpirationBanner` para mostrar tempo restante
  - Calcular e exibir dias restantes
  - Implementar cores diferentes baseadas no tempo (verde/amarelo/vermelho)
  - Mostrar "Chat Expirado" quando necessário
  - Atualizar automaticamente a cada minuto
  - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [x] 9. Criar tela de chat individual
  - Implementar `RomanticMatchChatView` com cabeçalho personalizado
  - Integrar lista de mensagens em tempo real
  - Adicionar campo de input para nova mensagem
  - Implementar envio de mensagens com validação
  - Adicionar botão voltar para lista de matches
  - _Requirements: 2.1, 2.2, 3.1, 6.1_

- [x] 10. Implementar lógica de envio de mensagens ✅
  - Validar mensagem antes do envio (tamanho, conteúdo)
  - Verificar se chat não expirou antes de enviar
  - Salvar mensagem no Firebase com timestamp
  - Atualizar contador de mensagens não lidas
  - Implementar retry automático em caso de falha
  - _Requirements: 3.1, 3.2, 4.1_

- [x] 11. Criar serviço de expiração automática
  - Implementar `ChatExpirationService` para gerenciar expiração
  - Criar método `getDaysRemaining` para cálculo de tempo
  - Implementar verificação automática de chats expirados
  - Bloquear envio de mensagens em chats expirados
  - Manter histórico de mensagens após expiração
  - _Requirements: 4.1, 4.4, 5.3, 5.4_

- [x] 12. Integrar com sistema de notificações existente ✅
  - Modificar sistema existente para criar chat automaticamente
  - Trigger criação de chat quando match é aceito
  - Integrar contadores de mensagens não lidas
  - Sincronizar dados entre sistemas
  - Testar integração completa
  - _Requirements: 5.1, 5.2, 6.2_

- [x] 13. Implementar navegação e roteamento ✅
  - Adicionar rotas para `AcceptedMatchesView` e `MatchChatView`
  - Integrar com sistema de navegação existente
  - Implementar passagem de parâmetros entre telas
  - Adicionar animações de transição
  - Testar navegação em diferentes cenários
  - _Requirements: 2.1, 6.1, 6.4_

- [x] 14. Adicionar sistema de marcação de mensagens como lidas ✅
  - Implementar marcação automática quando usuário abre chat
  - Atualizar contadores em tempo real
  - Sincronizar status de leitura entre dispositivos
  - Implementar debounce para evitar muitas atualizações
  - Testar sincronização em tempo real
  - _Requirements: 3.3, 6.2, 6.3_

- [x] 15. Implementar tratamento de erros e estados de loading ✅
  - Adicionar tratamento para falhas de rede
  - Implementar retry automático para operações críticas
  - Mostrar mensagens de erro amigáveis ao usuário
  - Implementar estados de loading em todas as operações
  - Testar comportamento em cenários de erro
  - _Requirements: 5.4, 1.3_

- [x] 16. Criar testes de integração ✅
  - Testar fluxo completo de criação de chat
  - Testar envio e recebimento de mensagens
  - Testar comportamento de expiração de chat
  - Testar navegação entre telas
  - Testar sincronização em tempo real
  - _Requirements: 2.1, 3.1, 4.4, 6.1_

- [ ] 17. Otimizar performance e implementar cache
  - Implementar paginação para mensagens antigas
  - Adicionar cache local para matches e mensagens recentes
  - Otimizar queries Firebase para melhor performance
  - Implementar lazy loading para imagens
  - Testar performance com grandes volumes de dados
  - _Requirements: 1.4, 3.3_

- [ ] 18. Finalizar integração com "Gerencie seus Matches"
  - Adicionar botão "Aceitos" na tela principal
  - Integrar contadores de mensagens não lidas no dashboard
  - Testar navegação completa do sistema
  - Verificar consistência visual com resto do app
  - Realizar testes finais de usabilidade
  - _Requirements: 1.1, 6.1, 6.2_