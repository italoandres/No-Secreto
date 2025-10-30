# Design Document: Melhorar Tela de Matches Aceitos

## Overview

Redesenhar a tela de matches aceitos para incluir fotos reais, status de presença, e sincronização em tempo real de mensagens.

## Architecture

### Componentes Principais

```
SimpleAcceptedMatchesView (UI)
    ↓
AcceptedMatchesController (Lógica)
    ↓
├── SimpleAcceptedMatchesRepository (Dados de Matches)
├── UserPresenceService (Status Online)
└── ChatRepository (Mensagens)
```

## Components and Interfaces

### 1. Enhanced Match Card Component

**Arquivo**: `lib/components/enhanced_match_card.dart`

```dart
class EnhancedMatchCard extends StatefulWidget {
  final AcceptedMatchModel match;
  final VoidCallback onTap;
  
  // Streams em tempo real
  Stream<int> unreadCountStream;
  Stream<UserPresence> presenceStream;
}
```

**Responsabilidades**:
- Exibir foto do perfil com fallback
- Mostrar status de presença em tempo real
- Atualizar contador de não lidas
- Preview da última mensagem

### 2. User Presence Service

**Arquivo**: `lib/services/user_presence_service.dart`

```dart
class UserPresenceService {
  // Atualizar presença do usuário atual
  Future<void> updatePresence(String userId, bool isOnline);
  
  // Stream de presença de um usuário
  Stream<UserPresence> getPresenceStream(String userId);
  
  // Obter última vez online
  Future<DateTime?> getLastSeen(String userId);
  
  // Formatar tempo desde última vez online
  String formatLastSeen(DateTime? lastSeen);
}
```

**Estrutura no Firestore**:
```
user_presence/{userId}
  - isOnline: boolean
  - lastSeen: timestamp
  - updatedAt: timestamp
```

### 3. Enhanced Accepted Matches Repository

**Melhorias em**: `lib/repositories/simple_accepted_matches_repository.dart`

```dart
class SimpleAcceptedMatchesRepository {
  // Buscar matches com fotos
  Future<List<AcceptedMatchModel>> getAcceptedMatchesWithPhotos(String userId);
  
  // Stream de matches em tempo real
  Stream<List<AcceptedMatchModel>> getMatchesStream(String userId);
  
  // Buscar foto do perfil
  Future<String?> getUserProfilePhoto(String userId);
}
```

### 4. Chat Unread Counter

**Arquivo**: `lib/services/chat_unread_counter.dart`

```dart
class ChatUnreadCounter {
  // Stream de contador de não lidas
  Stream<int> getUnreadCountStream(String chatId, String userId);
  
  // Marcar mensagens como lidas
  Future<void> markAsRead(String chatId, String userId);
  
  // Obter última mensagem
  Future<ChatMessage?> getLastMessage(String chatId);
}
```

## Data Models

### UserPresence Model

```dart
class UserPresence {
  final String userId;
  final bool isOnline;
  final DateTime? lastSeen;
  final DateTime updatedAt;
  
  bool get isRecentlyOnline => 
    lastSeen != null && 
    DateTime.now().difference(lastSeen!) < Duration(minutes: 5);
    
  String get statusText {
    if (isOnline) return 'Online agora';
    if (isRecentlyOnline) return 'Online recentemente';
    if (lastSeen == null) return 'Nunca visto';
    return 'Visto ${_formatLastSeen(lastSeen!)}';
  }
}
```

### Enhanced AcceptedMatchModel

```dart
class AcceptedMatchModel {
  // Campos existentes
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final DateTime matchDate;
  
  // Novos campos
  final String? otherUserPhoto;  // URL da foto
  final int? otherUserAge;       // Idade
  final String? otherUserCity;   // Cidade
  final String? lastMessageText; // Preview da última mensagem
  final DateTime? lastMessageTime; // Timestamp da última mensagem
  
  // Streams
  Stream<int>? unreadCountStream;
  Stream<UserPresence>? presenceStream;
}
```

## Error Handling

### Foto Não Carrega
```dart
// Fallback para inicial do nome
if (photoUrl == null || photoUrl.isEmpty) {
  return CircleAvatar(
    child: Text(name[0].toUpperCase()),
  );
}

// Erro ao carregar imagem
errorBuilder: (context, error, stackTrace) {
  return CircleAvatar(
    child: Icon(Icons.person),
  );
}
```

### Presença Indisponível
```dart
// Se não há dados de presença
if (presence == null) {
  return Text('Status desconhecido');
}
```

### Permissões Firestore
```dart
// Tratar erro de permissão
try {
  final matches = await repository.getMatches();
} on FirebaseException catch (e) {
  if (e.code == 'permission-denied') {
    showError('Sem permissão para acessar matches');
  }
}
```

## Testing Strategy

### Unit Tests
- `UserPresenceService`: Testar formatação de tempo
- `ChatUnreadCounter`: Testar contagem de não lidas
- `AcceptedMatchModel`: Testar getters e formatação

### Integration Tests
- Carregar matches com fotos
- Atualizar presença em tempo real
- Sincronizar contador de não lidas

### Widget Tests
- `EnhancedMatchCard`: Testar renderização
- Testar estados (loading, error, empty, success)
- Testar interações (tap, refresh)

## Visual Design

### Card Layout

```
┌─────────────────────────────────────────┐
│  ┌────┐                                 │
│  │ 📷 │  Nome, 25                    🔴 │ ← Badge não lidas
│  │    │  São Paulo, SP                  │
│  └────┘  ● Online agora                 │ ← Status presença
│          "Oi, tudo bem?"                 │ ← Preview mensagem
│          há 5 minutos                    │ ← Tempo mensagem
└─────────────────────────────────────────┘
```

### Indicador de Presença

```dart
// Ponto verde sobreposto à foto
Positioned(
  right: 0,
  bottom: 0,
  child: Container(
    width: 16,
    height: 16,
    decoration: BoxDecoration(
      color: isOnline ? Colors.green : Colors.grey,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 2),
    ),
  ),
)
```

### Badge de Não Lidas

```dart
// Badge rosa no canto superior direito
if (unreadCount > 0)
  Container(
    padding: EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: Colors.pink,
      shape: BoxShape.circle,
    ),
    child: Text(
      unreadCount > 99 ? '99+' : '$unreadCount',
      style: TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    ),
  )
```

## Performance Considerations

### Lazy Loading de Fotos
```dart
// Usar CachedNetworkImage
CachedNetworkImage(
  imageUrl: photoUrl,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.person),
  memCacheWidth: 120, // Otimizar memória
)
```

### Debounce de Presença
```dart
// Atualizar presença a cada 30 segundos, não em tempo real
Timer.periodic(Duration(seconds: 30), (timer) {
  updatePresence();
});
```

### Pagination de Matches
```dart
// Carregar 20 matches por vez
final matches = await repository.getMatches(
  limit: 20,
  startAfter: lastDocument,
);
```

## Migration Plan

### Fase 1: Adicionar Fotos
1. Atualizar `AcceptedMatchModel` com campo `otherUserPhoto`
2. Modificar repository para buscar fotos
3. Atualizar UI para exibir fotos

### Fase 2: Adicionar Presença
1. Criar `UserPresenceService`
2. Criar collection `user_presence` no Firestore
3. Integrar na UI

### Fase 3: Sincronizar Mensagens
1. Criar `ChatUnreadCounter`
2. Adicionar streams de não lidas
3. Atualizar UI em tempo real

### Fase 4: Melhorias Visuais
1. Criar `EnhancedMatchCard`
2. Adicionar preview de mensagem
3. Melhorar layout e animações
