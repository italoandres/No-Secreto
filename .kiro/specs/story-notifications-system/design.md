# Sistema de Notificações de Stories - Design

## Overview

O sistema de notificações de stories será implementado como uma extensão do sistema existente, adicionando funcionalidades de notificação para comentários em stories. O sistema incluirá um ícone de notificação na interface principal, uma página dedicada às notificações e integração automática com o sistema de comentários existente.

## Architecture

### Componentes Principais

1. **NotificationIconComponent** - Ícone de notificação com badge na capa principal
2. **NotificationsView** - Página principal de notificações
3. **NotificationItemComponent** - Item individual de notificação na lista
4. **NotificationService** - Serviço para gerenciar notificações
5. **NotificationRepository** - Repositório para operações no Firestore
6. **NotificationModel** - Modelo de dados das notificações

### Fluxo de Dados

```
Comentário Criado → NotificationService → Firestore → NotificationsView → UI Update
```

## Components and Interfaces

### 1. NotificationModel

```dart
class NotificationModel {
  final String id;
  final String userId;           // Destinatário da notificação
  final String type;             // 'story_comment'
  final String relatedId;        // ID do story
  final String fromUserId;       // Usuário que gerou a notificação
  final String fromUserName;     // Nome do usuário
  final String fromUserAvatar;   // Avatar do usuário
  final String content;          // Conteúdo da notificação
  final bool isRead;             // Status de lida
  final DateTime createdAt;      // Data de criação
  
  // Métodos de conversão para/do Firestore
  Map<String, dynamic> toMap();
  factory NotificationModel.fromMap(Map<String, dynamic> map);
}
```

### 2. NotificationRepository

```dart
class NotificationRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'notifications';
  
  // Criar nova notificação
  static Future<void> createNotification(NotificationModel notification);
  
  // Buscar notificações do usuário
  static Stream<List<NotificationModel>> getUserNotifications(String userId);
  
  // Marcar notificação como lida
  static Future<void> markAsRead(String notificationId);
  
  // Marcar todas como lidas
  static Future<void> markAllAsRead(String userId);
  
  // Contar notificações não lidas
  static Stream<int> getUnreadCount(String userId);
  
  // Deletar notificação
  static Future<void> deleteNotification(String notificationId);
}
```

### 3. NotificationService

```dart
class NotificationService {
  // Criar notificação de comentário
  static Future<void> createCommentNotification({
    required String storyId,
    required String storyAuthorId,
    required String commentAuthorId,
    required String commentAuthorName,
    required String commentAuthorAvatar,
    required String commentText,
  });
  
  // Formatar tempo relativo
  static String getRelativeTime(DateTime dateTime);
  
  // Truncar texto do comentário
  static String truncateComment(String comment, int maxLength = 100);
}
```

### 4. NotificationsView

```dart
class NotificationsView extends StatefulWidget {
  // Página principal de notificações
  // - AppBar com título "Notificações"
  // - Lista de notificações
  // - Estado vazio quando não há notificações
  // - Pull-to-refresh
  // - Marcar todas como lidas automaticamente
}
```

### 5. NotificationItemComponent

```dart
class NotificationItemComponent extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  
  // Item de notificação com:
  // - Avatar do usuário
  // - Nome do usuário
  // - Prévia do comentário
  // - Tempo relativo
  // - Indicador visual para não lidas
  // - Ação de tap para navegar
}
```

### 6. NotificationIconComponent

```dart
class NotificationIconComponent extends StatelessWidget {
  // Ícone de notificação com:
  // - Ícone de sino
  // - Badge com contador (quando > 0)
  // - Ação de tap para abrir NotificationsView
  // - Stream para atualizar contador em tempo real
}
```

## Data Models

### Estrutura no Firestore

**Coleção: `notifications`**

```json
{
  "id": "notification_id",
  "userId": "user_id_destinatario",
  "type": "story_comment",
  "relatedId": "story_id",
  "fromUserId": "user_id_autor_comentario",
  "fromUserName": "Nome do Usuário",
  "fromUserAvatar": "url_avatar",
  "content": "Texto do comentário truncado...",
  "isRead": false,
  "createdAt": "2024-01-15T10:30:00Z"
}
```

### Índices Necessários

```json
{
  "indexes": [
    {
      "collectionGroup": "notifications",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "userId", "order": "ASCENDING"},
        {"fieldPath": "createdAt", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "notifications", 
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "userId", "order": "ASCENDING"},
        {"fieldPath": "isRead", "order": "ASCENDING"}
      ]
    }
  ]
}
```

## Error Handling

### Cenários de Erro

1. **Falha na Criação de Notificação**
   - Log do erro
   - Não bloquear a criação do comentário
   - Retry automático em caso de falha de rede

2. **Falha no Carregamento de Notificações**
   - Exibir mensagem de erro
   - Botão para tentar novamente
   - Fallback para cache local se disponível

3. **Falha na Navegação**
   - Verificar se o story ainda existe
   - Exibir mensagem se conteúdo não encontrado
   - Opção para remover notificação inválida

### Tratamento de Estados

```dart
enum NotificationState {
  loading,
  loaded,
  empty,
  error,
}
```

## Testing Strategy

### Testes Unitários

1. **NotificationModel**
   - Serialização/deserialização
   - Validação de campos obrigatórios

2. **NotificationService**
   - Criação de notificações
   - Formatação de tempo
   - Truncamento de texto

3. **NotificationRepository**
   - Operações CRUD
   - Queries com filtros
   - Tratamento de erros

### Testes de Integração

1. **Fluxo Completo**
   - Criar comentário → Gerar notificação → Exibir na lista
   - Marcar como lida → Atualizar contador
   - Navegar para story → Verificar contexto

2. **Estados da UI**
   - Lista vazia
   - Lista com notificações
   - Estados de loading e erro

### Testes de Widget

1. **NotificationIconComponent**
   - Exibição do badge
   - Navegação ao tocar

2. **NotificationItemComponent**
   - Layout correto
   - Formatação de dados
   - Estados visuais

3. **NotificationsView**
   - Lista de notificações
   - Pull-to-refresh
   - Estado vazio

## Performance Considerations

### Otimizações

1. **Paginação**
   - Carregar 20 notificações por vez
   - Lazy loading conforme scroll

2. **Cache**
   - Cache local das notificações recentes
   - Sincronização em background

3. **Real-time Updates**
   - Stream para contador de não lidas
   - Debounce para evitar updates excessivos

4. **Limpeza Automática**
   - Remover notificações antigas (> 30 dias)
   - Batch operations para performance

## Security Considerations

### Regras do Firestore

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /notifications/{notificationId} {
      // Usuário só pode ler suas próprias notificações
      allow read: if request.auth != null && 
                     request.auth.uid == resource.data.userId;
      
      // Usuário só pode marcar suas notificações como lidas
      allow update: if request.auth != null && 
                       request.auth.uid == resource.data.userId &&
                       request.resource.data.diff(resource.data).affectedKeys()
                       .hasOnly(['isRead']);
      
      // Sistema pode criar notificações
      allow create: if request.auth != null;
      
      // Usuário pode deletar suas próprias notificações
      allow delete: if request.auth != null && 
                       request.auth.uid == resource.data.userId;
    }
  }
}
```

### Validações

1. **Autorização**
   - Verificar se usuário pode acessar notificações
   - Validar ownership antes de operações

2. **Sanitização**
   - Limpar conteúdo de comentários
   - Validar IDs de referência

3. **Rate Limiting**
   - Limitar criação de notificações por usuário
   - Prevenir spam de notificações