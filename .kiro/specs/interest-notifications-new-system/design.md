# Design Document - Sistema de Notificações de Interesse

## Overview

O sistema de notificações de interesse será implementado seguindo exatamente a mesma arquitetura do sistema funcional de convites do "Nosso Propósito". Utilizaremos os mesmos padrões, estruturas de dados e componentes visuais que já funcionam perfeitamente.

## Architecture

### Modelo Baseado no Sistema Funcional

```
Botão "Tenho Interesse" → InterestNotificationRepository → Firebase Firestore
                                    ↓
Firebase Stream → InterestNotificationsComponent → Interface do Usuário
```

### Componentes Principais

1. **InterestNotificationModel** - Modelo de dados (baseado em PurposeInviteModel)
2. **InterestNotificationRepository** - Repository para operações Firebase (baseado em PurposePartnershipRepository)
3. **InterestNotificationsComponent** - Componente visual (baseado em PurposeInvitesComponent)
4. **InterestButtonComponent** - Botão de interesse integrado aos perfis

## Data Models

### InterestNotificationModel

Baseado exatamente no PurposeInviteModel funcional:

```dart
class InterestNotificationModel {
  final String? id;
  final String fromUserId;
  final String fromUserName;
  final String fromUserEmail;
  final String toUserId;
  final String toUserEmail;
  final String type; // 'interest'
  final String status; // 'pending', 'accepted', 'rejected'
  final String? message;
  final Timestamp dataCriacao;
  final Timestamp? dataResposta;

  // Getters de conveniência
  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isInterest => type == 'interest';
}
```

### Estrutura Firebase

Coleção: `interest_notifications`

```json
{
  "id": "auto_generated_id",
  "fromUserId": "2MBqslnxAGeZFe18d9h52HYTZIy1",
  "fromUserName": "Italo Lior",
  "fromUserEmail": "italolior@gmail.com",
  "toUserId": "St2kw3cgX2MMPxlLRmBDjYm2nO22",
  "toUserEmail": "itala@gmail.com",
  "type": "interest",
  "status": "pending",
  "message": "Tem interesse em conhecer seu perfil melhor",
  "dataCriacao": "2025-01-15T22:21:55.851Z",
  "dataResposta": null
}
```

## Components and Interfaces

### 1. InterestNotificationRepository

Baseado no PurposePartnershipRepository funcional:

```dart
class InterestNotificationRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'interest_notifications';

  // Criar notificação de interesse (equivale a sendPartnershipInvite)
  static Future<void> createInterestNotification({
    required String fromUserId,
    required String fromUserName,
    required String fromUserEmail,
    required String toUserId,
    required String toUserEmail,
    String? message,
  }) async {
    // Verificar se já existe interesse pendente
    final existing = await _firestore
        .collection(_collection)
        .where('fromUserId', isEqualTo: fromUserId)
        .where('toUserId', isEqualTo: toUserId)
        .where('status', isEqualTo: 'pending')
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('Você já demonstrou interesse neste perfil');
    }

    // Criar nova notificação
    final notification = InterestNotificationModel(
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      fromUserEmail: fromUserEmail,
      toUserId: toUserId,
      toUserEmail: toUserEmail,
      type: 'interest',
      status: 'pending',
      message: message ?? 'Tem interesse em conhecer seu perfil melhor',
      dataCriacao: Timestamp.now(),
    );

    await _firestore.collection(_collection).add(notification.toMap());
  }

  // Stream de notificações (equivale a getUserInvites)
  static Stream<List<InterestNotificationModel>> getUserInterestNotifications(String userId) {
    return _firestore
        .collection(_collection)
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('dataCriacao', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InterestNotificationModel.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Responder a notificação (equivale a respondToInviteWithAction)
  static Future<void> respondToInterestNotification(String notificationId, String action) async {
    await _firestore.collection(_collection).doc(notificationId).update({
      'status': action, // 'accepted', 'rejected'
      'dataResposta': Timestamp.now(),
    });

    // Se aceito, criar match mútuo (implementar lógica de match se necessário)
    if (action == 'accepted') {
      // Lógica adicional para matches
    }
  }
}
```

### 2. InterestNotificationsComponent

Baseado exatamente no PurposeInvitesComponent funcional:

```dart
class InterestNotificationsComponent extends StatelessWidget {
  const InterestNotificationsComponent({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<InterestNotificationModel>>(
      stream: InterestNotificationRepository.getUserInterestNotifications(
        FirebaseAuth.instance.currentUser!.uid
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final notifications = snapshot.data!;
        if (notifications.isEmpty) {
          return const SizedBox();
        }

        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header (mesmo design dos convites)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF39b9ff),
                      const Color(0xFFfc6aeb),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.favorite, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Notificações de Interesse',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${notifications.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Lista de notificações
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: notifications.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: Colors.grey.shade200,
                ),
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return _buildNotificationItem(notification);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem(InterestNotificationModel notification) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho com nome e tempo
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFfc6aeb).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Interesse',
                  style: TextStyle(
                    color: const Color(0xFFfc6aeb),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${notification.fromUserName}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                _formatDate(notification.dataCriacao),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Mensagem
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              notification.message ?? 'Tem interesse em conhecer seu perfil melhor',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Botões de ação (mesmo layout dos convites)
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => _respondToNotification(notification, 'rejected'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                  ),
                  child: const Text('Não Tenho'),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: TextButton(
                  onPressed: () => _viewProfile(notification),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF39b9ff),
                  ),
                  child: const Text('Ver Perfil'),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _respondToNotification(notification, 'accepted'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFfc6aeb),
                  ),
                  child: const Text(
                    'Também Tenho',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _respondToNotification(InterestNotificationModel notification, String action) async {
    // Implementação idêntica ao _respondToInvite dos convites
    try {
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFfc6aeb)),
          ),
        ),
        barrierDismissible: false,
      );

      await InterestNotificationRepository.respondToInterestNotification(
        notification.id!,
        action,
      );

      Get.back();

      if (action == 'accepted') {
        Get.snackbar(
          'Interesse Mútuo! 💕',
          'Vocês demonstraram interesse mútuo!',
          backgroundColor: const Color(0xFFfc6aeb),
          colorText: Colors.white,
          icon: const Icon(Icons.favorite, color: Colors.white),
          duration: const Duration(seconds: 3),
        );
      } else {
        Get.snackbar(
          'Interesse Recusado',
          'O interesse foi recusado.',
          backgroundColor: Colors.grey.shade600,
          colorText: Colors.white,
          icon: const Icon(Icons.info, color: Colors.white),
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      if (Get.isDialogOpen == true) {
        Get.back();
      }
      
      Get.snackbar(
        'Erro',
        e.toString().replaceAll('Exception: ', ''),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
        duration: const Duration(seconds: 4),
      );
    }
  }

  void _viewProfile(InterestNotificationModel notification) {
    // Navegar para o perfil do usuário interessado
    // Implementar navegação baseada na estrutura existente
  }

  String _formatDate(Timestamp? timestamp) {
    // Mesma implementação do PurposeInvitesComponent
    if (timestamp == null) return '';
    
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 1) {
      return 'Agora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return DateFormat('dd/MM').format(date);
    }
  }
}
```

### 3. InterestButtonComponent

Integração com botões "Tenho Interesse" existentes:

```dart
class InterestButtonComponent extends StatelessWidget {
  final String targetUserId;
  final String targetUserName;
  final String targetUserEmail;
  final UsuarioModel currentUser;

  const InterestButtonComponent({
    super.key,
    required this.targetUserId,
    required this.targetUserName,
    required this.targetUserEmail,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _showInterest(),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFfc6aeb),
        foregroundColor: Colors.white,
      ),
      child: const Text('Tenho Interesse'),
    );
  }

  void _showInterest() async {
    try {
      await InterestNotificationRepository.createInterestNotification(
        fromUserId: currentUser.id!,
        fromUserName: currentUser.displayName ?? 'Usuário',
        fromUserEmail: currentUser.email!,
        toUserId: targetUserId,
        toUserEmail: targetUserEmail,
      );

      Get.snackbar(
        'Interesse Enviado! 💕',
        'Sua notificação de interesse foi enviada!',
        backgroundColor: const Color(0xFFfc6aeb),
        colorText: Colors.white,
        icon: const Icon(Icons.favorite, color: Colors.white),
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        e.toString().replaceAll('Exception: ', ''),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
        duration: const Duration(seconds: 4),
      );
    }
  }
}
```

## Integration Points

### 1. Integração com Perfis Existentes

- Substituir botões "Tenho Interesse" existentes pelo InterestButtonComponent
- Manter mesma funcionalidade visual
- Adicionar validações antes de enviar interesse

### 2. Integração com Interface Principal

- Adicionar InterestNotificationsComponent na mesma área dos convites do Nosso Propósito
- Usar mesma lógica de exibição condicional
- Manter consistência visual

### 3. Integração com Sistema de Navegação

- Usar mesmas rotas e navegação existente
- Integrar com sistema de perfis atual
- Manter padrões de navegação

## Error Handling

Usar exatamente o mesmo padrão dos convites:

1. **Try-catch** em todas as operações
2. **Loading dialogs** durante operações
3. **Snackbars** para feedback
4. **Validações** antes de operações
5. **Rollback** em caso de erro

## Testing Strategy

Seguir mesma estratégia dos convites:

1. **Testes de Repository** - CRUD operations
2. **Testes de Component** - Renderização e interações
3. **Testes de Integração** - Fluxo completo
4. **Testes de Stream** - Tempo real

## Performance Considerations

Usar mesmas otimizações dos convites:

1. **Streams otimizados** com where clauses
2. **Índices Firebase** apropriados
3. **Lazy loading** de componentes
4. **Cache local** quando possível

## Security Rules

Baseado nas regras dos convites:

```javascript
// firestore.rules
match /interest_notifications/{notificationId} {
  allow read, write: if request.auth != null && 
    (resource.data.toUserId == request.auth.uid || 
     resource.data.fromUserId == request.auth.uid);
}
```