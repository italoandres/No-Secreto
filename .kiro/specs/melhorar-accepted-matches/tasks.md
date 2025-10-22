# Implementation Plan: Melhorar Tela de Matches Aceitos

## Fase 1: Adicionar Fotos dos Perfis

- [ ] 1.1 Atualizar AcceptedMatchModel com campo de foto
  - Adicionar campo `otherUserPhoto` opcional
  - Adicionar campo `otherUserAge` opcional
  - Adicionar campo `otherUserCity` opcional
  - _Requirements: 1.1, 1.2_

- [ ] 1.2 Modificar SimpleAcceptedMatchesRepository para buscar fotos
  - Criar método `getUserProfilePhoto(userId)`
  - Buscar foto principal do perfil no Firestore
  - Buscar idade e cidade do perfil
  - Retornar URL da foto ou null
  - _Requirements: 1.1, 1.2_

- [ ] 1.3 Atualizar método getAcceptedMatches para incluir fotos
  - Para cada match, buscar foto do outro usuário
  - Preencher campo `otherUserPhoto` no modelo
  - Preencher idade e cidade
  - Tratar erros de busca graciosamente
  - _Requirements: 1.1, 1.2, 1.3_

- [ ] 1.4 Atualizar UI para exibir fotos reais
  - Usar NetworkImage quando foto existe
  - Manter fallback com inicial do nome
  - Adicionar errorBuilder para falhas de carregamento
  - Aumentar tamanho do avatar para 60x60
  - _Requirements: 1.2, 1.3, 1.4_

## Fase 2: Implementar Sistema de Presença

- [ ] 2.1 Criar UserPresence model
  - Campos: userId, isOnline, lastSeen, updatedAt
  - Getter `isRecentlyOnline` (< 5 minutos)
  - Getter `statusText` formatado
  - Método `formatLastSeen` para exibição
  - _Requirements: 2.1, 2.2, 2.3_

- [ ] 2.2 Criar UserPresenceService
  - Método `updatePresence(userId, isOnline)`
  - Método `getPresenceStream(userId)` retorna Stream
  - Método `getLastSeen(userId)`
  - Método `formatLastSeen(DateTime)` para UI
  - _Requirements: 2.1, 2.4_

- [ ] 2.3 Integrar presença no AppLifecycle
  - Atualizar presença quando app vai para foreground
  - Marcar offline quando app vai para background
  - Usar Timer para atualizar a cada 30 segundos
  - _Requirements: 2.4_

- [ ] 2.4 Adicionar indicador de presença no card
  - Ponto verde/cinza sobreposto à foto
  - Texto "Online agora" ou "Visto há X"
  - Atualizar em tempo real com Stream
  - _Requirements: 2.1, 2.2, 2.3, 2.5_

## Fase 3: Sincronizar Notificações de Mensagens

- [ ] 3.1 Criar ChatUnreadCounter service
  - Método `getUnreadCountStream(chatId, userId)`
  - Método `markAsRead(chatId, userId)`
  - Método `getLastMessage(chatId)`
  - _Requirements: 3.1, 3.3_

- [ ] 3.2 Adicionar stream de não lidas no AcceptedMatchModel
  - Campo `unreadCountStream` opcional
  - Inicializar stream ao carregar matches
  - _Requirements: 3.1, 3.2_

- [ ] 3.3 Atualizar UI para exibir contador em tempo real
  - Usar StreamBuilder para contador
  - Badge rosa quando > 0
  - Ocultar badge quando = 0
  - Animação ao atualizar contador
  - _Requirements: 3.2, 3.4, 3.5_

- [ ] 3.4 Zerar contador ao abrir chat
  - Chamar `markAsRead` ao navegar para chat
  - Atualizar Firestore com timestamp de leitura
  - _Requirements: 3.2_

## Fase 4: Melhorias Visuais e UX

- [ ] 4.1 Criar EnhancedMatchCard component
  - Foto 60x60 com indicador de presença
  - Nome, idade e cidade
  - Status de presença
  - Preview da última mensagem
  - Badge de não lidas
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

- [ ] 4.2 Adicionar preview da última mensagem
  - Buscar última mensagem do chat
  - Exibir texto truncado (max 50 chars)
  - Mostrar tempo relativo ("há 5 min")
  - _Requirements: 5.5_

- [ ] 4.3 Melhorar estados de loading e erro
  - Skeleton loader para cards
  - Mensagens de erro mais claras
  - Botão de retry em erros
  - _Requirements: 4.3_

- [ ] 4.4 Adicionar animações
  - Fade in ao carregar cards
  - Pulse animation no badge de não lidas
  - Ripple effect ao tocar no card
  - _Requirements: 5.1_

## Fase 5: Correções para Produção (APK)

- [ ] 5.1 Adicionar tratamento de permissões
  - Try-catch em todas as queries Firestore
  - Mensagens específicas para erros de permissão
  - Fallback para dados ausentes
  - _Requirements: 4.2, 4.3, 4.5_

- [ ] 5.2 Adicionar logs de debug
  - Logs ao carregar matches
  - Logs ao buscar fotos
  - Logs de erros com stack trace
  - Remover logs sensíveis em release
  - _Requirements: 4.4_

- [ ] 5.3 Testar em release build
  - Build APK de release
  - Testar carregamento de matches
  - Testar fotos e presença
  - Testar notificações de mensagens
  - _Requirements: 4.1_

- [ ] 5.4 Atualizar regras do Firestore
  - Permitir leitura de fotos de perfil
  - Permitir leitura/escrita de presença
  - Permitir leitura de contadores de mensagens
  - _Requirements: 4.2_

## Fase 6: Testes e Validação

- [ ]* 6.1 Escrever unit tests
  - Testar UserPresence model
  - Testar formatação de tempo
  - Testar ChatUnreadCounter
  - _Requirements: Todos_

- [ ]* 6.2 Escrever widget tests
  - Testar EnhancedMatchCard
  - Testar estados (loading, error, success)
  - Testar interações
  - _Requirements: Todos_

- [ ]* 6.3 Testar integração completa
  - Carregar matches com fotos
  - Atualizar presença em tempo real
  - Receber notificações de mensagens
  - Navegar para chat
  - _Requirements: Todos_
