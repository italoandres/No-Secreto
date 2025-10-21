# Design Document - Sistema Unificado de Notificações

## Overview

Este documento descreve a arquitetura e design técnico do Sistema Unificado de Notificações, que organiza todas as notificações do app em 3 categorias horizontais: Stories, Interesse/Match e Sistema. O design reutiliza os serviços e repositórios existentes, mantendo compatibilidade com as versões atuais do Firebase.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   UnifiedNotificationsView                   │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │   Stories   │  │ Interesse/  │  │   Sistema   │         │
│  │     📖      │  │   Match 💕  │  │     ⚙️      │         │
│  │   Badge: 5  │  │   Badge: 3  │  │   Badge: 1  │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
│                                                               │
│  ┌───────────────────────────────────────────────────────┐  │
│  │         NotificationCategoryContent                    │  │
│  │  - Lista de notificações da categoria ativa           │  │
│  │  - Pull to refresh                                    │  │
│  │  - Empty state                                        │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              UnifiedNotificationController                   │
│  - Gerencia estado das 3 categorias                         │
│  - Agrega notificações de múltiplas fontes                  │
│  - Calcula contadores de badges                             │
│  - Coordena navegação entre categorias                      │
└─────────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        ▼                   ▼                   ▼
┌──────────────┐  ┌──────────────────┐  ┌──────────────┐
│   Stories    │  │  Interesse/Match │  │   Sistema    │
│   Service    │  │    Repository    │  │   Service    │
└──────────────┘  └──────────────────┘  └──────────────┘
        │                   │                   │
        └───────────────────┼───────────────────┘
                            ▼
                ┌───────────────────────┐
                │  Firebase Firestore   │
                │  (Versão Atual 4.13.6)│
                └───────────────────────┘
```

## Components and Interfaces

### 1. UnifiedNotificationsView (Widget Principal)

**Responsabilidades:**
- Exibir as 3 categorias horizontais com badges
- Gerenciar navegação entre categorias
- Coordenar pull-to-refresh
- Exibir estados vazios apropriados

**Interface:**
```dart
class UnifiedNotificationsView extends StatefulWidget {
  const UnifiedNotificationsView({Key? key}) : super(key: key);
}

class _UnifiedNotificationsViewState extends State<UnifiedNotificationsView> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late UnifiedNotificationController _controller;
  
  // Índices das categorias
  static const int STORIES_TAB = 0;
  static const int INTEREST_TAB = 1;
  static const int SYSTEM_TAB = 2;
}
```

### 2. UnifiedNotificationController (GetX Controller)

**Responsabilidades:**
- Agregar notificações de múltiplas fontes
- Calcular contadores de badges em tempo real
- Gerenciar estado de loading e erros
- Coordenar marcação de lidas

**Interface:**
```dart
class UnifiedNotificationController extends GetxController {
  // Observables para cada categoria
  final RxList<NotificationModel> storiesNotifications = <NotificationModel>[].obs;
  final RxList<InterestNotificationModel> interestNotifications = <InterestNotificationModel>[].obs;
  final RxList<Map<String, dynamic>> systemNotifications = <Map<String, dynamic>>[].obs;
  
  // Contadores de badges
  final RxInt storiesBadgeCount = 0.obs;
  final RxInt interestBadgeCount = 0.obs;
  final RxInt systemBadgeCount = 0.obs;
  
  // Estado
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxInt activeCategory = 0.obs;
  
  // Métodos principais
  Future<void> loadAllNotifications();
  Future<void> refreshCategory(NotificationCategory category);
  Future<void> markCategoryAsRead(NotificationCategory category);
  void switchCategory(int index);
  int getTotalBadgeCount();
}
```

### 3. NotificationCategoryTab (Widget de Categoria)

**Responsabilidades:**
- Exibir ícone da categoria
- Mostrar badge com contador
- Indicar categoria ativa

**Interface:**
```dart
class NotificationCategoryTab extends StatelessWidget {
  final NotificationCategory category;
  final int badgeCount;
  final bool isActive;
  final VoidCallback onTap;
  
  const NotificationCategoryTab({
    required this.category,
    required this.badgeCount,
    required this.isActive,
    required this.onTap,
  });
}
```

### 4. NotificationCategoryContent (Widget de Conteúdo)

**Responsabilidades:**
- Exibir lista de notificações da categoria
- Implementar pull-to-refresh
- Mostrar estado vazio
- Renderizar item apropriado por tipo

**Interface:**
```dart
class NotificationCategoryContent extends StatelessWidget {
  final NotificationCategory category;
  final List<dynamic> notifications;
  final bool isLoading;
  final VoidCallback onRefresh;
  final Function(dynamic) onNotificationTap;
  
  const NotificationCategoryContent({
    required this.category,
    required this.notifications,
    required this.isLoading,
    required this.onRefresh,
    required this.onNotificationTap,
  });
}
```

### 5. NotificationItemFactory (Factory Pattern)

**Responsabilidades:**
- Criar widget apropriado para cada tipo de notificação
- Aplicar estilos específicos por categoria
- Gerenciar ações específicas por tipo

**Interface:**
```dart
class NotificationItemFactory {
  static Widget createNotificationItem({
    required NotificationCategory category,
    required dynamic notification,
    required Function(dynamic) onTap,
    required Function(dynamic)? onDelete,
  }) {
    switch (category) {
      case NotificationCategory.stories:
        return StoryNotificationItem(notification: notification, onTap: onTap);
      case NotificationCategory.interest:
        return InterestNotificationItem(notification: notification, onTap: onTap);
      case NotificationCategory.system:
        return SystemNotificationItem(notification: notification, onTap: onTap);
    }
  }
}
```

## Data Models

### NotificationCategory (Enum)

```dart
enum NotificationCategory {
  stories,
  interest,
  system;
  
  String get displayName {
    switch (this) {
      case NotificationCategory.stories:
        return 'Stories';
      case NotificationCategory.interest:
        return 'Interesse';
      case NotificationCategory.system:
        return 'Sistema';
    }
  }
  
  IconData get icon {
    switch (this) {
      case NotificationCategory.stories:
        return Icons.auto_stories;
      case NotificationCategory.interest:
        return Icons.favorite;
      case NotificationCategory.system:
        return Icons.settings;
    }
  }
  
  Color get color {
    switch (this) {
      case NotificationCategory.stories:
        return Colors.amber.shade700;
      case NotificationCategory.interest:
        return Colors.pink.shade400;
      case NotificationCategory.system:
        return Colors.blue.shade600;
    }
  }
}
```

### UnifiedNotificationModel (Wrapper)

```dart
class UnifiedNotificationModel {
  final String id;
  final NotificationCategory category;
  final dynamic data; // NotificationModel, InterestNotificationModel ou Map
  final DateTime timestamp;
  final bool isRead;
  
  UnifiedNotificationModel({
    required this.id,
    required this.category,
    required this.data,
    required this.timestamp,
    required this.isRead,
  });
  
  // Factory para criar a partir de diferentes tipos
  factory UnifiedNotificationModel.fromStory(NotificationModel notification) {
    return UnifiedNotificationModel(
      id: notification.id,
      category: NotificationCategory.stories,
      data: notification,
      timestamp: notification.createdAt.toDate(),
      isRead: notification.isRead,
    );
  }
  
  factory UnifiedNotificationModel.fromInterest(InterestNotificationModel notification) {
    return UnifiedNotificationModel(
      id: notification.id!,
      category: NotificationCategory.interest,
      data: notification,
      timestamp: notification.dataCriacao!.toDate(),
      isRead: !notification.isPending,
    );
  }
  
  factory UnifiedNotificationModel.fromSystem(Map<String, dynamic> notification) {
    return UnifiedNotificationModel(
      id: notification['id'],
      category: NotificationCategory.system,
      data: notification,
      timestamp: (notification['createdAt'] as Timestamp).toDate(),
      isRead: notification['read'] ?? false,
    );
  }
}
```

## Integration with Existing Services

### Stories Notifications

**Serviço Existente:** `NotificationService` e `NotificationRepository`

**Tipos de Notificações de Stories:**
1. **Curtidas** - Alguém curtiu seu story
2. **Comentários** - Alguém comentou no seu story
3. **Menções (@)** - Alguém te mencionou em um comentário
4. **Respostas** - Alguém respondeu seu comentário
5. **Comentários Curtidos** - Alguém curtiu seu comentário

**Integração:**
```dart
// No UnifiedNotificationController
Future<void> _loadStoriesNotifications() async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;
  
  // Usar stream existente que já inclui todos os tipos
  NotificationRepository.getUserNotifications(userId).listen((notifications) {
    // Filtrar apenas notificações de stories (todos os tipos)
    final storyNotifications = notifications.where((n) {
      final type = n.type;
      return type == 'like' || 
             type == 'comment' || 
             type == 'mention' || 
             type == 'reply' || 
             type == 'comment_like';
    }).toList();
    
    storiesNotifications.value = storyNotifications;
    _updateStoriesBadgeCount();
  });
}

void _updateStoriesBadgeCount() {
  storiesBadgeCount.value = storiesNotifications
      .where((n) => !n.isRead)
      .length;
}
```

### Interest/Match Notifications

**Serviço Existente:** `InterestNotificationRepository`

**Integração:**
```dart
// No UnifiedNotificationController
Future<void> _loadInterestNotifications() async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;
  
  // Usar stream existente
  InterestNotificationRepository.getUserInterestNotifications(userId).listen((notifications) {
    interestNotifications.value = notifications;
    _updateInterestBadgeCount();
  });
}

void _updateInterestBadgeCount() {
  interestBadgeCount.value = interestNotifications
      .where((n) => n.isPending)
      .length;
}
```

### System Notifications (including Certification)

**Serviço Existente:** `CertificationNotificationService`

**Integração:**
```dart
// No UnifiedNotificationController
Future<void> _loadSystemNotifications() async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;
  
  // Usar stream existente que já inclui certificação
  CertificationNotificationService().getAllNotifications(userId).listen((notifications) {
    systemNotifications.value = notifications;
    _updateSystemBadgeCount();
  });
}

void _updateSystemBadgeCount() {
  systemBadgeCount.value = systemNotifications
      .where((n) => !(n['read'] ?? false))
      .length;
}
```

## UI/UX Design

### Layout Structure

```
┌─────────────────────────────────────────────────────────┐
│  AppBar: "Notificações"                    [Total: 9]   │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐              │
│  │  📖      │  │  💕      │  │  ⚙️      │              │
│  │ Stories  │  │ Interesse│  │ Sistema  │              │
│  │  [5]     │  │  [3]     │  │  [1]     │              │
│  └──────────┘  └──────────┘  └──────────┘              │
│      ▲                                                   │
│  (Ativa)                                                 │
│                                                           │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌─────────────────────────────────────────────────┐   │
│  │ 👤 João Silva                          2h atrás │   │
│  │ Curtiu seu story "Sinais de Rebeca"            │   │
│  └─────────────────────────────────────────────────┘   │
│                                                           │
│  ┌─────────────────────────────────────────────────┐   │
│  │ 👤 Maria Santos                        5h atrás │   │
│  │ Comentou no seu story "Nosso Propósito"        │   │
│  └─────────────────────────────────────────────────┘   │
│                                                           │
│  ┌─────────────────────────────────────────────────┐   │
│  │ 👤 Pedro Costa                         1d atrás │   │
│  │ Salvou seu story "Sinais de Isaque"            │   │
│  └─────────────────────────────────────────────────┘   │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

### Color Scheme

**Stories (📖):**
- Primary: `Colors.amber.shade700`
- Badge: `Colors.red` (contador)
- Background: `Colors.amber.shade50` (quando ativa)

**Interesse/Match (💕):**
- Primary: `Colors.pink.shade400`
- Badge: `Colors.red` (contador)
- Background: `Colors.pink.shade50` (quando ativa)

**Sistema (⚙️):**
- Primary: `Colors.blue.shade600`
- Badge: `Colors.red` (contador)
- Background: `Colors.blue.shade50` (quando ativa)

### Badge Design

```dart
Widget _buildBadge(int count) {
  if (count == 0) return const SizedBox.shrink();
  
  return Positioned(
    right: 0,
    top: 0,
    child: Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
      ),
      constraints: const BoxConstraints(
        minWidth: 20,
        minHeight: 20,
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    ),
  );
}
```

## Error Handling

### Error Recovery Strategy

1. **Network Errors:**
   - Usar cache local (NotificationFallbackSystem)
   - Exibir snackbar informando modo offline
   - Tentar reconexão automática

2. **Permission Errors:**
   - Verificar autenticação do usuário
   - Redirecionar para login se necessário
   - Exibir mensagem apropriada

3. **Data Errors:**
   - Validar dados antes de exibir
   - Usar fallback para dados inválidos
   - Registrar erro para debug

### Error UI States

```dart
Widget _buildErrorState(String error) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
        const SizedBox(height: 16),
        Text('Erro ao carregar notificações', style: TextStyle(fontSize: 18)),
        const SizedBox(height: 8),
        Text(error, style: TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => _controller.refreshCategory(_currentCategory),
          child: const Text('Tentar Novamente'),
        ),
      ],
    ),
  );
}
```

## Testing Strategy

### Unit Tests

1. **UnifiedNotificationController:**
   - Teste de agregação de notificações
   - Teste de cálculo de badges
   - Teste de mudança de categoria
   - Teste de marcação como lida

2. **NotificationItemFactory:**
   - Teste de criação de widgets por tipo
   - Teste de aplicação de estilos
   - Teste de ações específicas

3. **Data Models:**
   - Teste de conversão entre tipos
   - Teste de validação de dados
   - Teste de serialização/deserialização

### Integration Tests

1. **Fluxo Completo:**
   - Abrir tela de notificações
   - Navegar entre categorias
   - Tocar em notificação
   - Marcar como lida
   - Pull to refresh

2. **Integração com Serviços:**
   - Teste de carregamento de stories
   - Teste de carregamento de interesse
   - Teste de carregamento de sistema
   - Teste de sincronização em tempo real

### Widget Tests

1. **UnifiedNotificationsView:**
   - Teste de renderização das 3 categorias
   - Teste de exibição de badges
   - Teste de navegação entre tabs
   - Teste de estados vazios

2. **NotificationCategoryTab:**
   - Teste de exibição de ícone
   - Teste de exibição de badge
   - Teste de estado ativo/inativo

## Performance Considerations

### Optimization Strategies

1. **Lazy Loading:**
   - Carregar apenas categoria ativa inicialmente
   - Carregar outras categorias em background
   - Implementar paginação para listas grandes

2. **Caching:**
   - Usar NotificationFallbackSystem existente
   - Cache em memória para navegação rápida
   - Invalidar cache ao receber novas notificações

3. **Stream Management:**
   - Cancelar streams ao trocar de categoria
   - Usar debounce para evitar updates excessivos
   - Implementar throttle para scroll

4. **Widget Optimization:**
   - Usar const constructors onde possível
   - Implementar shouldRebuild em widgets customizados
   - Usar ListView.builder para listas longas

### Memory Management

```dart
@override
void dispose() {
  _tabController.dispose();
  _storiesSubscription?.cancel();
  _interestSubscription?.cancel();
  _systemSubscription?.cancel();
  Get.delete<UnifiedNotificationController>();
  super.dispose();
}
```

## Migration Strategy

### Phase 1: Criar Novos Componentes (Sem Quebrar Existente)

1. Criar `UnifiedNotificationsView` como nova tela
2. Criar `UnifiedNotificationController`
3. Implementar integração com serviços existentes
4. Testar em paralelo com tela antiga

### Phase 2: Substituir Navegação

1. Atualizar rotas para apontar para nova tela
2. Manter tela antiga como fallback
3. Monitorar erros e performance
4. Coletar feedback de usuários

### Phase 3: Remover Código Antigo

1. Remover `NotificationsView` antiga
2. Limpar imports não utilizados
3. Atualizar documentação
4. Fazer release final

## Security Considerations

1. **Autenticação:**
   - Verificar usuário autenticado antes de carregar
   - Validar permissões para cada categoria
   - Proteger dados sensíveis

2. **Validação de Dados:**
   - Validar dados do Firebase antes de exibir
   - Sanitizar inputs do usuário
   - Prevenir XSS em mensagens

3. **Privacy:**
   - Não expor dados de outros usuários
   - Respeitar configurações de privacidade
   - Implementar opt-out se necessário

## Accessibility

1. **Screen Readers:**
   - Adicionar Semantics em todos os widgets
   - Fornecer descrições claras para badges
   - Anunciar mudanças de categoria

2. **Visual:**
   - Suportar tamanhos de fonte maiores
   - Manter contraste adequado (WCAG AA)
   - Não depender apenas de cores

3. **Motor:**
   - Áreas de toque mínimas de 48x48
   - Suportar navegação por teclado
   - Permitir gestos alternativos

## Future Enhancements

1. **Filtros e Busca:**
   - Filtrar por data
   - Buscar por usuário ou conteúdo
   - Ordenação customizada

2. **Notificações Push:**
   - Integrar com Firebase Messaging
   - Categorizar push notifications
   - Deep linking para categorias

3. **Personalização:**
   - Permitir reordenar categorias
   - Configurar quais categorias exibir
   - Customizar cores e ícones

4. **Analytics:**
   - Rastrear engajamento por categoria
   - Medir tempo de resposta
   - Identificar padrões de uso
