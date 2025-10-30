# Correção: Botões da Vitrine por Contexto

## Problema

Quando o usuário clica em "Ver Perfil" no Interest Dashboard, o `EnhancedVitrineDisplayView` sempre mostrava o botão "Tenho Interesse", independente do contexto:

- ❌ **Notificação Pendente:** Mostrava "Tenho Interesse" (deveria ser "Também Tenho")
- ❌ **Notificação Aceita:** Mostrava "Tenho Interesse" (deveria ser "Conversar")

## Solução Implementada

Adicionamos um parâmetro `interestStatus` que é passado ao navegar para o perfil, permitindo que o botão seja contextual.

### Fluxo

```
EnhancedInterestNotificationCard
    ↓ (passa interestStatus)
EnhancedVitrineDisplayView
    ↓ (decide qual botão mostrar)
Botão Contextual
```

## Mudanças Implementadas

### 1. EnhancedVitrineDisplayView

**Arquivo:** `lib/views/enhanced_vitrine_display_view.dart`

#### Adicionado campo de estado:
```dart
String? interestStatus; // 'pending', 'accepted', 'rejected', null
```

#### Recebe argumento:
```dart
void _initializeData() {
  final arguments = Get.arguments as Map<String, dynamic>? ?? {};
  userId = arguments['userId'] as String? ?? controller.currentUserId.value;
  isOwnProfile = arguments['isOwnProfile'] as bool? ?? true;
  interestStatus = arguments['interestStatus'] as String?; // ✅ NOVO
}
```

#### Botão contextual:
```dart
Widget _buildActionButton() {
  // Match aceito → Botão "Conversar"
  if (interestStatus == 'accepted' || interestStatus == 'mutual_match') {
    return ElevatedButton.icon(
      onPressed: _navigateToChat,
      icon: Icon(Icons.chat),
      label: Text('Conversar'),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
    );
  }
  
  // Notificação pendente → Botão "Também Tenho"
  if (interestStatus == 'pending' || interestStatus == 'viewed') {
    return ElevatedButton.icon(
      onPressed: _respondWithInterest,
      icon: Icon(Icons.favorite),
      label: Text('Também Tenho'),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
    );
  }
  
  // Caso padrão → Botão "Tenho Interesse"
  return InterestButtonComponent(...);
}
```

#### Método para responder interesse:
```dart
void _respondWithInterest() async {
  // Busca notificação pendente
  // Responde com 'accepted'
  // Mostra snackbar de sucesso
  // Volta para dashboard
}
```

#### Método para navegar ao chat:
```dart
void _navigateToChat() {
  // Gera chatId
  // Navega para /chat
}
```

### 2. EnhancedInterestNotificationCard

**Arquivo:** `lib/components/enhanced_interest_notification_card.dart`

#### Passa status ao navegar:
```dart
void _navigateToProfile() {
  Get.toNamed('/vitrine-display', arguments: {
    'userId': fromUserId,
    'isOwnProfile': false,
    'interestStatus': widget.notification.status, // ✅ NOVO
  });
}
```

## Comportamento por Status

### Status: `pending` ou `viewed`
- **Botão:** "Também Tenho" (rosa, ícone coração)
- **Ação:** Aceita o interesse e cria match
- **Resultado:** Snackbar de sucesso + volta para dashboard

### Status: `accepted` ou `mutual_match`
- **Botão:** "Conversar" (verde, ícone chat)
- **Ação:** Navega para o chat
- **Resultado:** Abre tela de chat

### Status: `null` (navegação normal)
- **Botão:** "Tenho Interesse" (componente padrão)
- **Ação:** Demonstra interesse pela primeira vez
- **Resultado:** Cria notificação de interesse

## Teste

### Teste 1: Notificação Pendente
1. Abra Interest Dashboard
2. Veja notificação com status "pending"
3. Clique em "Ver Perfil"
4. **Esperado:** Botão "Também Tenho" (rosa)
5. Clique no botão
6. **Esperado:** Snackbar "Interesse Aceito!" + volta para dashboard

### Teste 2: Notificação Aceita
1. Abra Interest Dashboard
2. Veja notificação com status "accepted" e badge "MATCH!"
3. Clique em "Ver Perfil"
4. **Esperado:** Botão "Conversar" (verde)
5. Clique no botão
6. **Esperado:** Abre tela de chat

### Teste 3: Navegação Normal
1. Vá para "Explorar Perfis" ou outra tela
2. Abra um perfil qualquer
3. **Esperado:** Botão "Tenho Interesse" (padrão)

## Logs Esperados

```
🔍 [CARD] Navegando para perfil: k8Z5VD3B3YgdIcy9DsS5MiEjpUS2
🔍 [CARD] Status da notificação: pending

[VITRINE_DISPLAY] Argumentos recebidos
  - userId: k8Z5VD3B3YgdIcy9DsS5MiEjpUS2
  - isOwnProfile: false
  - interestStatus: pending

[VITRINE_DISPLAY] Respondendo com interesse
  - targetUserId: k8Z5VD3B3YgdIcy9DsS5MiEjpUS2
```

## Resultado Final

✅ **Notificação Pendente** → Botão "Também Tenho"
✅ **Notificação Aceita** → Botão "Conversar"
✅ **Navegação Normal** → Botão "Tenho Interesse"
✅ **Contexto preservado** → Botão correto em cada situação
✅ **UX melhorada** → Usuário sabe exatamente o que fazer

## Arquivos Modificados

1. `lib/views/enhanced_vitrine_display_view.dart`
   - Adicionado campo `interestStatus`
   - Adicionado método `_buildActionButton()`
   - Adicionado método `_respondWithInterest()`
   - Adicionado método `_navigateToChat()`
   - Adicionado import `InterestNotificationRepository`

2. `lib/components/enhanced_interest_notification_card.dart`
   - Modificado `_navigateToProfile()` para passar `interestStatus`
