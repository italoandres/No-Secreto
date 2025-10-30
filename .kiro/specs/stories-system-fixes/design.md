# Design Document - Stories System Fixes

## Overview

Este documento descreve o design técnico para corrigir os problemas restantes no sistema de stories: índices do Firebase, histórico automático, carregamento de imagens e auto-close dos stories.

## Architecture

### Firebase Indexes
- Criar índices compostos necessários para consultas de likes e comentários
- Configurar índices no arquivo `firestore.indexes.json`
- Aplicar índices via Firebase Console

### Stories History System
- Implementar job automático para mover stories antigos
- Usar Cloud Functions ou lógica local para migração
- Manter integridade dos dados durante a migração

### Image Loading Enhancement
- Implementar cache de imagens robusto
- Adicionar retry logic para falhas de carregamento
- Otimizar URLs de imagem do Firebase Storage

### Auto-Close Mechanism
- Implementar timer automático baseado no tipo de mídia
- Gerenciar estado de reprodução de vídeos
- Controlar navegação automática entre stories

## Components and Interfaces

### 1. Firebase Index Configuration

```json
{
  "indexes": [
    {
      "collectionGroup": "story_likes",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "storyId", "order": "ASCENDING"},
        {"fieldPath": "dataCadastro", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "story_comments", 
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "isBlocked", "order": "ASCENDING"},
        {"fieldPath": "parentCommentId", "order": "ASCENDING"},
        {"fieldPath": "storyId", "order": "ASCENDING"},
        {"fieldPath": "dataCadastro", "order": "ASCENDING"}
      ]
    }
  ]
}
```

### 2. Stories History Service

```dart
class StoriesHistoryService {
  static Future<void> moveExpiredStoriesToHistory() async;
  static Future<void> moveStoryToHistory(StorieFileModel story) async;
  static Stream<List<StorieFileModel>> getHistoryStories() async;
}
```

### 3. Enhanced Image Loading

```dart
class EnhancedImageLoader {
  static Widget buildCachedImage(String url, {Widget? placeholder, Widget? errorWidget});
  static Future<void> preloadImage(String url) async;
  static void clearImageCache() async;
}
```

### 4. Auto-Close Controller

```dart
class StoryAutoCloseController {
  Timer? _autoCloseTimer;
  
  void startAutoClose(StorieFileModel story);
  void pauseAutoClose();
  void resumeAutoClose();
  void cancelAutoClose();
}
```

## Data Models

### Enhanced StorieFileModel
- Adicionar campo `isExpired` para controle de expiração
- Adicionar campo `historyMovedAt` para rastreamento
- Manter compatibilidade com modelo atual

### Story Interaction Models
- Otimizar consultas de likes e comentários
- Implementar paginação para grandes volumes
- Adicionar cache local para melhor performance

## Error Handling

### Firebase Index Errors
- Detectar erros de índice faltando
- Mostrar mensagens informativas para admins
- Implementar fallback queries quando possível

### Image Loading Errors
- Retry automático com backoff exponencial
- Fallback para placeholder quando falha
- Log de erros para monitoramento

### History Migration Errors
- Transações atômicas para evitar perda de dados
- Rollback automático em caso de falha
- Notificação de erros críticos

## Testing Strategy

### Unit Tests
- Testar lógica de migração de histórico
- Testar auto-close timers
- Testar retry logic de imagens

### Integration Tests
- Testar consultas com índices
- Testar fluxo completo de expiração
- Testar carregamento de imagens em diferentes cenários

### Performance Tests
- Medir tempo de carregamento de imagens
- Testar performance com grandes volumes de stories
- Monitorar uso de memória durante reprodução

## Implementation Notes

### Firebase Indexes
- Aplicar via Firebase Console primeiro
- Depois atualizar arquivo local
- Testar todas as consultas após aplicação

### Stories History
- Implementar como job diário
- Executar durante horários de baixo uso
- Manter logs detalhados da migração

### Image Loading
- Usar CachedNetworkImage com configurações otimizadas
- Implementar preload para próximos stories
- Limpar cache periodicamente

### Auto-Close
- Integrar com sistema de gestos existente
- Pausar durante interações do usuário
- Sincronizar com reprodução de vídeo