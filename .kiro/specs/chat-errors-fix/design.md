# Design Document

## Overview

O sistema de correção de erros de chat implementa uma camada robusta de tratamento de erros, sanitização de dados e criação automática de índices Firebase. O design foca em recuperação automática de erros e experiência do usuário sem interrupções, mesmo quando há problemas técnicos subjacentes.

## Architecture

### Error Recovery Layer
- **ChatErrorHandler**: Intercepta e trata erros de chat
- **DataSanitizer**: Limpa e valida dados antes do uso
- **FirebaseIndexManager**: Gerencia criação automática de índices
- **ChatRecoveryService**: Implementa estratégias de recuperação

### Data Validation Layer
- **TimestampValidator**: Valida e corrige campos Timestamp
- **ChatDataValidator**: Valida estrutura de dados de chat
- **MessageDataValidator**: Valida dados de mensagens
- **UserDataValidator**: Valida dados de usuário

### User Interface Layer
- **ErrorNotificationWidget**: Mostra erros de forma amigável
- **IndexCreationDialog**: Interface para criação de índices
- **ChatStatusIndicator**: Mostra status do sistema de chat
- **RecoveryActionButton**: Botões para ações de recuperação

## Components and Interfaces

### ChatErrorHandler
```dart
class ChatErrorHandler {
  static Future<T?> handleChatOperation<T>(
    Future<T> Function() operation,
    {String? fallbackMessage}
  );
  
  static void handleTimestampError(dynamic error, String context);
  static void handleFirebaseIndexError(dynamic error);
  static bool isIndexMissingError(dynamic error);
  static String? extractIndexCreationLink(dynamic error);
}
```

### DataSanitizer
```dart
class DataSanitizer {
  static Map<String, dynamic> sanitizeChatData(Map<String, dynamic> data);
  static Map<String, dynamic> sanitizeMessageData(Map<String, dynamic> data);
  static Timestamp sanitizeTimestamp(dynamic value);
  static String sanitizeString(dynamic value, {String defaultValue = ''});
  static bool sanitizeBool(dynamic value, {bool defaultValue = false});
}
```

### FirebaseIndexManager
```dart
class FirebaseIndexManager {
  static Future<void> checkAndCreateRequiredIndexes();
  static Future<bool> isIndexRequired(String collection, List<String> fields);
  static String generateIndexCreationLink(String collection, List<String> fields);
  static Future<void> showIndexCreationDialog(BuildContext context, String link);
}
```

### ChatRecoveryService
```dart
class ChatRecoveryService {
  static Future<void> recoverChatData(String chatId);
  static Future<void> rebuildChatIndex(String chatId);
  static Future<void> fixCorruptedMessages(String chatId);
  static Future<bool> validateChatIntegrity(String chatId);
}
```

## Data Models

### ChatErrorInfo
```dart
class ChatErrorInfo {
  final String errorType;
  final String message;
  final String? recoveryAction;
  final String? indexLink;
  final DateTime timestamp;
  final Map<String, dynamic>? context;
  
  bool get isIndexError => errorType == 'firebase_index_missing';
  bool get isTimestampError => errorType == 'timestamp_conversion';
  bool get hasRecoveryAction => recoveryAction != null;
}
```

### ChatValidationResult
```dart
class ChatValidationResult {
  final bool isValid;
  final List<String> errors;
  final Map<String, dynamic> sanitizedData;
  final List<String> warnings;
  
  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
  bool get needsSanitization => sanitizedData.isNotEmpty;
}
```

### IndexRequirement
```dart
class IndexRequirement {
  final String collection;
  final List<String> fields;
  final String creationLink;
  final bool isRequired;
  final String description;
  
  String get displayName => fields.join(', ');
}
```

## Error Handling

### Timestamp Conversion Errors
```dart
// Estratégia de recuperação para erros de Timestamp
Timestamp sanitizeTimestamp(dynamic value) {
  if (value == null) return Timestamp.now();
  if (value is Timestamp) return value;
  if (value is DateTime) return Timestamp.fromDate(value);
  if (value is String) {
    try {
      return Timestamp.fromDate(DateTime.parse(value));
    } catch (e) {
      return Timestamp.now();
    }
  }
  return Timestamp.now();
}
```

### Firebase Index Missing Errors
```dart
// Detecção e tratamento de índices faltando
bool isIndexMissingError(dynamic error) {
  return error.toString().contains('requires an index') ||
         error.toString().contains('create_composite');
}

String? extractIndexCreationLink(dynamic error) {
  final regex = RegExp(r'https://console\.firebase\.google\.com[^\s]+');
  final match = regex.firstMatch(error.toString());
  return match?.group(0);
}
```

### Data Corruption Recovery
```dart
// Recuperação de dados corrompidos
Map<String, dynamic> sanitizeChatData(Map<String, dynamic> data) {
  return {
    'id': data['id'] ?? '',
    'user1Id': data['user1Id'] ?? '',
    'user2Id': data['user2Id'] ?? '',
    'createdAt': sanitizeTimestamp(data['createdAt']),
    'expiresAt': sanitizeTimestamp(data['expiresAt']),
    'lastMessageAt': sanitizeTimestamp(data['lastMessageAt']),
    'lastMessage': data['lastMessage'] ?? '',
    'isExpired': data['isExpired'] ?? false,
    'unreadCount': Map<String, int>.from(data['unreadCount'] ?? {}),
  };
}
```

## Testing Strategy

### Unit Tests
- **ChatErrorHandler**: Testar diferentes tipos de erro e recuperação
- **DataSanitizer**: Testar sanitização com dados corrompidos
- **FirebaseIndexManager**: Testar detecção e criação de índices
- **Validators**: Testar validação com dados válidos e inválidos

### Integration Tests
- **Error Recovery Flow**: Testar recuperação completa de erros
- **Index Creation Flow**: Testar criação automática de índices
- **Data Sanitization Flow**: Testar limpeza de dados em cenários reais
- **Chat Initialization**: Testar inicialização com dados problemáticos

### Error Simulation Tests
- **Timestamp Errors**: Simular diferentes tipos de erro de timestamp
- **Index Missing**: Simular erros de índice faltando
- **Network Errors**: Testar comportamento com falhas de rede
- **Data Corruption**: Testar com dados deliberadamente corrompidos

## Firebase Index Requirements

### chat_messages Collection
```javascript
// Índice composto necessário para queries de mensagens
{
  "collectionGroup": "chat_messages",
  "queryScope": "COLLECTION",
  "fields": [
    {"fieldPath": "chatId", "order": "ASCENDING"},
    {"fieldPath": "isRead", "order": "ASCENDING"},
    {"fieldPath": "senderId", "order": "ASCENDING"},
    {"fieldPath": "__name__", "order": "ASCENDING"}
  ]
}

// Índice para ordenação por timestamp
{
  "collectionGroup": "chat_messages", 
  "queryScope": "COLLECTION",
  "fields": [
    {"fieldPath": "chatId", "order": "ASCENDING"},
    {"fieldPath": "timestamp", "order": "DESCENDING"},
    {"fieldPath": "__name__", "order": "DESCENDING"}
  ]
}
```

## User Experience Flow

### Error Detection and Recovery
```
1. User clicks on match → Chat initialization starts
2. Error detected → ChatErrorHandler intercepts
3. Error type identified → Appropriate recovery strategy
4. If index missing → Show creation dialog with link
5. If data corruption → Sanitize and continue
6. If critical error → Show friendly error message
7. Recovery successful → Continue normal operation
```

### Index Creation Flow
```
1. Index error detected → Extract creation link
2. Show user-friendly dialog → Explain what's needed
3. User clicks "Create Index" → Open Firebase console
4. User creates index → Returns to app
5. App detects index ready → Retry operation
6. Operation succeeds → Normal chat functionality
```

## Performance Considerations

### Error Handling Overhead
- Implementar cache de validação para evitar reprocessamento
- Usar debounce para evitar múltiplas tentativas de recuperação
- Implementar circuit breaker para falhas persistentes

### Data Sanitization Performance
- Cache de dados sanitizados para evitar reprocessamento
- Sanitização lazy apenas quando necessário
- Batch processing para múltiplos registros

### Index Creation Optimization
- Cache de status de índices para evitar verificações desnecessárias
- Verificação assíncrona de índices em background
- Fallback graceful quando índices não estão disponíveis

## Monitoring and Logging

### Error Tracking
```dart
class ChatErrorLogger {
  static void logTimestampError(String context, dynamic originalValue);
  static void logIndexMissingError(String collection, List<String> fields);
  static void logDataSanitization(String type, Map<String, dynamic> changes);
  static void logRecoverySuccess(String errorType, Duration recoveryTime);
}
```

### Health Monitoring
- Monitorar taxa de erros de chat
- Alertar quando índices estão faltando
- Rastrear eficácia das estratégias de recuperação
- Métricas de performance de sanitização de dados