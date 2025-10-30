# Design Document - Correção Exibição de Notificações de Interesse

## Overview

Este design corrige o problema de filtragem de notificações onde notificações de interesse simples (curtidas) estão sendo criadas e salvas no Firebase, mas não aparecem na interface do usuário devido a um filtro muito restritivo.

## Architecture

### Componentes Afetados

1. **ReceivedInterestsView** - Tela que exibe notificações recebidas
2. **InterestNotificationRepository** - Repositório que busca notificações
3. **RealInterestNotificationService** - Serviço que processa notificações
4. **Filtros de Notificação** - Lógica que determina quais notificações exibir

### Fluxo Atual (Com Problema)

```
Firebase (4 notificações)
    ↓
Repository busca notificações
    ↓
Filtro aplica regras restritivas ❌
    ↓
0 notificações exibidas
```

### Fluxo Corrigido

```
Firebase (4 notificações)
    ↓
Repository busca notificações
    ↓
Filtro inclusivo (interest, acceptance, mutual_match) ✅
    ↓
Todas notificações válidas exibidas
```

## Components and Interfaces

### 1. Correção do Filtro de Notificações

**Arquivo:** `lib/views/received_interests_view.dart` ou componente de notificações

**Problema Atual:**
```dart
// Filtro muito restritivo - exclui notificações de interesse
.where('status', whereIn: ['pending', 'viewed'])
// Falta filtro por tipo
```

**Solução:**
```dart
// Filtro inclusivo que aceita todos os tipos de notificação
.where('toUserId', isEqualTo: currentUserId)
.where('status', whereIn: ['pending', 'viewed', 'new'])
// Não filtrar por tipo no Firebase - filtrar na aplicação se necessário
```

### 2. Processamento de Notificações

**Arquivo:** `lib/services/real_interest_notification_service.dart`

**Método:** `processNotifications()`

```dart
List<NotificationModel> processNotifications(List<Map<String, dynamic>> rawData) {
  print('🔍 [FILTER] Processando ${rawData.length} notificações brutas');
  
  final validNotifications = rawData.where((notification) {
    final type = notification['type'] as String?;
    final status = notification['status'] as String?;
    
    // Aceitar todos os tipos de notificação de interesse
    final validTypes = ['interest', 'acceptance', 'mutual_match'];
    final validStatuses = ['pending', 'viewed', 'new'];
    
    final isValidType = validTypes.contains(type);
    final isValidStatus = validStatuses.contains(status);
    
    if (!isValidType) {
      print('⚠️ [FILTER] Notificação excluída - tipo inválido: $type');
    }
    if (!isValidStatus) {
      print('⚠️ [FILTER] Notificação excluída - status inválido: $status');
    }
    
    return isValidType && isValidStatus;
  }).toList();
  
  print('✅ [FILTER] ${validNotifications.length} notificações válidas após filtro');
  
  return validNotifications.map((data) => NotificationModel.fromMap(data)).toList();
}
```

### 3. Query do Firebase

**Arquivo:** `lib/repositories/interest_notification_repository.dart`

**Método:** `getReceivedNotifications()`

```dart
Stream<List<NotificationModel>> getReceivedNotifications(String userId) {
  print('🔍 [REPO] Buscando notificações para usuário: $userId');
  
  return FirebaseFirestore.instance
      .collection('interest_notifications')
      .where('toUserId', isEqualTo: userId)
      // Remover filtro whereIn de status - buscar todas e filtrar na app
      .orderBy('dataCriacao', descending: true)
      .snapshots()
      .map((snapshot) {
        print('📊 [REPO] Total de documentos encontrados: ${snapshot.docs.length}');
        
        final notifications = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
        
        // Aplicar filtro na aplicação
        final filtered = notifications.where((n) {
          final status = n['status'] as String?;
          final type = n['type'] as String?;
          
          final validStatuses = ['pending', 'viewed', 'new'];
          final validTypes = ['interest', 'acceptance', 'mutual_match'];
          
          return validStatuses.contains(status) && validTypes.contains(type);
        }).toList();
        
        print('✅ [REPO] Notificações após filtro: ${filtered.length}');
        
        return filtered.map((data) => NotificationModel.fromMap(data)).toList();
      });
}
```

## Data Models

### NotificationModel

Garantir que o modelo suporta todos os tipos:

```dart
class NotificationModel {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String type; // 'interest', 'acceptance', 'mutual_match'
  final String status; // 'pending', 'viewed', 'new'
  final String message;
  final Timestamp dataCriacao;
  
  // Campos opcionais
  final String? fromUserName;
  final String? fromUserEmail;
  final Timestamp? dataResposta;
}
```

## Error Handling

### Cenários de Erro

1. **Notificações não aparecem:**
   - Verificar logs de filtro
   - Confirmar que tipo e status estão corretos
   - Verificar se query do Firebase está retornando dados

2. **Notificações duplicadas:**
   - Usar ID único do documento
   - Implementar deduplicação na UI

3. **Performance:**
   - Limitar query a últimas 50 notificações
   - Implementar paginação se necessário

## Testing Strategy

### Testes Manuais

1. **Teste de Criação:**
   - Usuário A curte perfil de Usuário B
   - Verificar log: "✅ Notificação de interesse salva com ID: xxx"

2. **Teste de Recebimento:**
   - Usuário B abre tela de notificações
   - Verificar logs:
     - "📊 [REPO] Total de documentos encontrados: X"
     - "✅ [REPO] Notificações após filtro: X"
   - Confirmar que X > 0

3. **Teste de Exibição:**
   - Notificação deve aparecer na lista
   - Deve mostrar nome do usuário que curtiu
   - Deve ter botões de ação (aceitar/rejeitar)

### Logs de Debug

Adicionar logs em cada etapa:

```dart
print('🔍 [QUERY] Iniciando query para userId: $userId');
print('📊 [QUERY] Documentos retornados: ${snapshot.docs.length}');
print('🔍 [FILTER] Aplicando filtros...');
print('   - Tipos válidos: [interest, acceptance, mutual_match]');
print('   - Status válidos: [pending, viewed, new]');
print('✅ [FILTER] Notificações válidas: $count');
print('📱 [UI] Renderizando $count notificações');
```

## Implementation Notes

### Prioridade de Correção

1. **Alta:** Corrigir filtro de status e tipo
2. **Alta:** Adicionar logs de debug
3. **Média:** Melhorar mensagens de erro
4. **Baixa:** Otimizar performance

### Arquivos a Modificar

1. `lib/views/received_interests_view.dart` - Corrigir query e filtro
2. `lib/repositories/interest_notification_repository.dart` - Ajustar lógica de busca
3. `lib/services/real_interest_notification_service.dart` - Melhorar processamento
4. `lib/components/real_interest_notifications_component.dart` - Garantir renderização

### Compatibilidade

- Manter compatibilidade com notificações existentes
- Suportar migração de status antigos
- Não quebrar funcionalidade de matches aceitos
