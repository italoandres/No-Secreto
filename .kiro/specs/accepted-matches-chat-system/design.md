# Design Document

## Overview

O sistema de matches aceitos com chat temporário é composto por uma tela de lista de matches, telas de chat individual, e serviços de backend para gerenciar mensagens e expiração. O sistema integra com as notificações de interesse existentes e utiliza Firebase Firestore para persistência em tempo real.

## Architecture

### Frontend Components
- **AcceptedMatchesView**: Lista principal de matches aceitos
- **MatchChatView**: Tela de chat individual com um match
- **MatchChatCard**: Card individual na lista de matches
- **ChatMessageBubble**: Componente para exibir mensagens
- **ChatExpirationBanner**: Banner mostrando tempo restante

### Backend Services
- **MatchChatService**: Gerencia criação e operações de chat
- **MatchChatRepository**: Acesso aos dados de chat no Firebase
- **ChatExpirationService**: Gerencia expiração automática de chats
- **MatchesRepository**: Busca matches aceitos das notificações

### Data Models
- **MatchChatModel**: Representa um chat entre dois usuários
- **ChatMessageModel**: Representa uma mensagem individual
- **AcceptedMatchModel**: Representa um match aceito

## Components and Interfaces

### AcceptedMatchesView
```dart
class AcceptedMatchesView extends StatefulWidget {
  // Lista scrollável de matches aceitos
  // Botão de refresh
  // Estado de loading e empty state
  // Navegação para chat individual
}
```

### MatchChatView
```dart
class MatchChatView extends StatefulWidget {
  final String matchId;
  final String otherUserId;
  
  // Cabeçalho com foto e nome do match
  // Lista de mensagens em tempo real
  // Campo de input para nova mensagem
  // Banner de expiração
  // Botão voltar
}
```

### MatchChatService
```dart
class MatchChatService {
  static Future<String> createOrGetChatId(String userId1, String userId2);
  static Future<void> sendMessage(String chatId, ChatMessageModel message);
  static Stream<List<ChatMessageModel>> getMessagesStream(String chatId);
  static Future<bool> isChatExpired(String chatId);
  static Future<int> getDaysRemaining(String chatId);
}
```

## Data Models

### MatchChatModel
```dart
class MatchChatModel {
  final String id;
  final String user1Id;
  final String user2Id;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? lastMessageAt;
  final String? lastMessage;
  final bool isExpired;
  final Map<String, int> unreadCount; // userId -> count
}
```

### ChatMessageModel
```dart
class ChatMessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isRead;
}
```

### AcceptedMatchModel
```dart
class AcceptedMatchModel {
  final String notificationId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhoto;
  final DateTime matchDate;
  final String chatId;
  final int unreadMessages;
  final bool chatExpired;
  final int daysRemaining;
}
```

## Error Handling

### Chat Creation Errors
- **Usuário não encontrado**: Mostrar erro e voltar para lista
- **Falha na criação**: Tentar novamente automaticamente
- **Permissões insuficientes**: Mostrar mensagem de erro

### Message Sending Errors
- **Chat expirado**: Bloquear envio e mostrar aviso
- **Falha de rede**: Mostrar retry automático
- **Mensagem muito longa**: Validar antes do envio

### Data Loading Errors
- **Falha ao carregar matches**: Mostrar botão de retry
- **Falha ao carregar mensagens**: Mostrar estado de erro
- **Timeout de conexão**: Implementar retry automático

## Testing Strategy

### Unit Tests
- **MatchChatService**: Testar criação de chat, envio de mensagens, verificação de expiração
- **ChatExpirationService**: Testar cálculo de dias restantes, verificação de expiração
- **Data Models**: Testar serialização/deserialização JSON

### Integration Tests
- **Chat Flow**: Testar fluxo completo de criar chat e enviar mensagem
- **Expiration Flow**: Testar comportamento quando chat expira
- **Real-time Updates**: Testar recebimento de mensagens em tempo real

### Widget Tests
- **AcceptedMatchesView**: Testar exibição de lista, estados vazios, navegação
- **MatchChatView**: Testar envio de mensagens, exibição de tempo restante
- **ChatMessageBubble**: Testar diferentes tipos de mensagens

## Firebase Collections Structure

### match_chats
```json
{
  "id": "chat_user1_user2",
  "user1Id": "userId1",
  "user2Id": "userId2", 
  "createdAt": "2025-01-15T10:00:00Z",
  "expiresAt": "2025-02-14T10:00:00Z",
  "lastMessageAt": "2025-01-16T15:30:00Z",
  "lastMessage": "Olá! Como você está?",
  "isExpired": false,
  "unreadCount": {
    "userId1": 0,
    "userId2": 2
  }
}
```

### chat_messages
```json
{
  "id": "messageId",
  "chatId": "chat_user1_user2",
  "senderId": "userId1",
  "senderName": "João",
  "message": "Olá! Como você está?",
  "timestamp": "2025-01-16T15:30:00Z",
  "isRead": false
}
```

## Navigation Flow

```
AcceptedMatchesView
    ↓ (tap match)
MatchChatView
    ↓ (back button)
AcceptedMatchesView
```

## Real-time Updates

### Message Streaming
- Usar `Stream<QuerySnapshot>` para mensagens em tempo real
- Implementar debounce para evitar muitas atualizações
- Marcar mensagens como lidas automaticamente

### Unread Count Updates
- Atualizar contador quando usuário abre chat
- Sincronizar entre dispositivos em tempo real
- Mostrar badge na lista de matches

## Performance Considerations

### Message Pagination
- Carregar últimas 50 mensagens inicialmente
- Implementar scroll infinito para mensagens antigas
- Cache local para mensagens recentes

### Image Optimization
- Usar thumbnails para fotos de perfil na lista
- Lazy loading para imagens nas mensagens
- Compressão automática de imagens enviadas