# Sistema de Badge de Notificações 🔴

## Visão Geral

O sistema de badge vermelho no ícone de notificações mostra em tempo real o número total de notificações não lidas somando as 3 categorias:
- **Stories** (curtidas, comentários, menções, respostas)
- **Interesse/Match** (notificações de interesse mútuo)
- **Sistema** (certificação espiritual, atualizações)

## Como Funciona

### 1. Badge no Ícone de Notificações

O componente `NotificationIconComponent` exibe um badge vermelho com o contador total:

```dart
// Localização: lib/components/notification_icon_component.dart
// Usado em: lib/views/chat_view.dart (linha 127)

const NotificationIconComponent(contexto: 'principal')
```

**Características:**
- Badge vermelho circular no canto superior direito do sino
- Mostra número de 1 a 99, depois "99+"
- Atualiza em tempo real via GetX observables
- Desaparece quando não há notificações não lidas

### 2. Controller Unificado

O `UnifiedNotificationController` gerencia os contadores:

```dart
// Contadores reativos (GetX Observables)
final RxInt storiesUnreadCount = 0.obs;   // Stories não lidas
final RxInt interestUnreadCount = 0.obs;  // Interesse não lidas
final RxInt systemUnreadCount = 0.obs;    // Sistema não lidas

// Badge total = soma das 3 categorias
final unreadCount = controller.storiesUnreadCount.value + 
                   controller.interestUnreadCount.value + 
                   controller.systemUnreadCount.value;
```

### 3. Atualização em Tempo Real

Os contadores são atualizados automaticamente via streams do Firebase:

**Stories:**
```dart
NotificationRepository.getUserNotifications(userId)
  → Filtra por isRead = false
  → Atualiza storiesUnreadCount
```

**Interesse:**
```dart
InterestNotificationRepository.getUserInterestNotifications(userId)
  → Filtra por isPending = true
  → Atualiza interestUnreadCount
```

**Sistema:**
```dart
CertificationNotificationService.getAllNotifications(userId)
  → Filtra por read = false
  → Atualiza systemUnreadCount
```

### 4. Marcar Como Lida

Quando o usuário clica em uma notificação, ela é marcada como lida e o badge atualiza automaticamente:

**Stories:**
```dart
await NotificationRepository.markAsRead(notificationId);
// O stream detecta a mudança e atualiza o contador
```

**Sistema:**
```dart
await CertificationNotificationService.markAsRead(notificationId);
// O stream detecta a mudança e atualiza o contador
```

**Interesse:**
```dart
// Interesse usa isPending ao invés de isRead
// Quando o usuário responde ao interesse, isPending vira false
```

## Componentes Disponíveis

### 1. NotificationIconComponent (Padrão)
Badge simples sem animação:
```dart
const NotificationIconComponent(contexto: 'principal')
```

### 2. AnimatedNotificationIconComponent
Badge com animação de pulse quando há notificações:
```dart
const AnimatedNotificationIconComponent()
```

### 3. SimpleNotificationIcon
Versão simplificada com Badge nativo do Flutter:
```dart
SimpleNotificationIcon(
  iconColor: Colors.white,
  iconSize: 24,
  onTap: () => Get.to(() => const NotificationsView()),
)
```

## Fluxo de Dados

```
Firebase Firestore
    ↓
Streams (NotificationRepository, InterestNotificationRepository, CertificationNotificationService)
    ↓
UnifiedNotificationController (GetX)
    ↓
Observables (storiesUnreadCount, interestUnreadCount, systemUnreadCount)
    ↓
NotificationIconComponent (Obx widget)
    ↓
Badge Vermelho (UI atualiza automaticamente)
```

## Vantagens

✅ **Tempo Real:** Atualiza instantaneamente quando novas notificações chegam
✅ **Reativo:** Usa GetX observables para performance otimizada
✅ **Unificado:** Soma automaticamente as 3 categorias
✅ **Descontabiliza:** Remove do contador quando marcada como lida
✅ **Sem Polling:** Usa streams do Firebase (push, não pull)
✅ **Eficiente:** Apenas recalcula quando há mudanças reais

## Localização dos Arquivos

```
lib/
├── components/
│   └── notification_icon_component.dart    # Componente do badge
├── controllers/
│   └── unified_notification_controller.dart # Controller GetX
├── views/
│   ├── chat_view.dart                      # Usa o componente (linha 127)
│   └── notifications_view.dart             # Tela de notificações
└── models/
    ├── notification_category.dart          # Enum das categorias
    └── unified_notification_model.dart     # Modelo unificado
```

## Navegação das Notificações

### Notificações de Sistema

**Certificação Aprovada:**
- Ao clicar no botão "Ver Perfil" → Navega para `/vitrine-display`
- Mostra o perfil público do usuário certificado
- Badge verde com ícone de verificado

**Certificação Rejeitada:**
- Ao clicar no botão "Tentar Novamente" → Navega para formulário de certificação
- Badge laranja com ícone de informação

### Notificações de Interesse

**Interesse Mútuo:**
- Ao clicar na notificação → Navega para `/interest-dashboard`
- Mostra a vitrine de propósito com todos os interesses
- Badge roxo-rosa com design misterioso

### Notificações de Stories

**Curtidas, Comentários, Menções:**
- Ao clicar na notificação → Navega para o story específico
- Marca automaticamente como lida
- Badge amarelo com ícone de livro

## Testando

1. **Enviar notificação de teste:**
   - Use o botão 🧪 Teste na HomeView (modo debug)
   - Vá para TestNotificationsButtonView

2. **Verificar badge:**
   - Badge deve aparecer no ícone de sino
   - Número deve corresponder ao total de não lidas

3. **Marcar como lida:**
   - Abra NotificationsView
   - Clique em uma notificação
   - Badge deve diminuir automaticamente

4. **Verificar tempo real:**
   - Abra o app em 2 dispositivos
   - Envie notificação de um para outro
   - Badge deve aparecer instantaneamente

5. **Testar navegação:**
   - Clique em "Ver Perfil" na certificação aprovada
   - Deve navegar para vitrine-display
   - Clique em notificação de interesse
   - Deve navegar para interest-dashboard

## Correções Implementadas

### ✅ Badge Descontabiliza ao Clicar
- Quando clica em uma notificação de sistema, ela é marcada como lida ANTES de navegar
- O badge atualiza automaticamente após 300ms
- Funciona tanto na página de notificações quanto no ícone da HomeView

### ✅ Navegação com userId Correto
- Sempre passa o userId nos argumentos para vitrine-display
- Usa o userId da notificação ou fallback para o usuário atual do FirebaseAuth
- Passa também `isOwnProfile: true` para indicar que é o próprio perfil

### ✅ Código da Correção
```dart
// Marcar como lida ANTES de navegar
if (notificationId != null) {
  await _controller._certificationService.markAsRead(notificationId);
  
  // Forçar atualização dos badges
  await Future.delayed(const Duration(milliseconds: 300));
  _controller._updateSystemBadgeCount();
}

// Sempre passar o userId
final targetUserId = userId ?? FirebaseAuth.instance.currentUser?.uid;

Get.toNamed('/vitrine-display', arguments: {
  'userId': targetUserId,
  'isOwnProfile': true,
});
```

## Troubleshooting

**Badge não aparece:**
- Verificar se UnifiedNotificationController está inicializado
- Verificar se há notificações não lidas no Firebase
- Verificar console para erros de stream

**Badge não atualiza:**
- Verificar se os streams estão ativos
- Verificar se o método markAsRead está sendo chamado
- Verificar se o Firebase está retornando dados corretos

**Contador errado:**
- Verificar filtros de isRead/isPending
- Verificar se todas as 3 categorias estão sendo somadas
- Verificar logs do controller para debug

**Erro "User ID not found" na vitrine:**
- Verificar se a notificação tem o campo userId
- Verificar se FirebaseAuth.instance.currentUser está autenticado
- Verificar logs para ver qual userId está sendo passado
