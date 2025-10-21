# Design: Correção do Interest Dashboard

## Overview

Corrigir 7 problemas críticos no InterestDashboardView para que funcione corretamente com o novo sistema de notificações, perfis e matches.

## Architecture

### Componentes Afetados

```
InterestDashboardView
├── EnhancedInterestNotificationCard (correção de nome e botões)
├── InterestNotificationRepository (correção de filtros)
├── EnhancedVitrineDisplayView (navegação correta)
└── fix_empty_fromUserName.dart (script de correção)
```

### Fluxo de Dados

```
Firestore (interest_notifications)
    ↓
InterestNotificationRepository (filtro corrigido)
    ↓
InterestDashboardView (stream)
    ↓
EnhancedInterestNotificationCard (exibição corrigida)
    ↓
EnhancedVitrineDisplayView (navegação corrigida)
```

## Components and Interfaces

### 1. Correção do Filtro de Status

**Arquivo:** `lib/repositories/interest_notification_repository.dart`

**Problema Atual:**
```dart
const validStatuses = ['pending', 'new', 'viewed'];
// ❌ Rejeita "accepted" e "rejected"
```

**Solução:**
```dart
const validStatuses = ['pending', 'new', 'viewed', 'accepted', 'rejected'];

// Filtrar por tempo para accepted/rejected
final notifications = snapshot.docs
    .map((doc) => InterestNotificationModel.fromMap({...doc.data(), 'id': doc.id}))
    .where((notification) {
      final isValidType = validTypes.contains(notification.type);
      final status = notification.status;
      
      // Aceitar pending, new, viewed sempre
      if (['pending', 'new', 'viewed'].contains(status)) {
        return isValidType;
      }
      
      // Para accepted/rejected, verificar se tem menos de 7 dias
      if (['accepted', 'rejected'].contains(status)) {
        if (notification.dataResposta == null) return false;
        
        final daysSinceResponse = DateTime.now().difference(
          notification.dataResposta!.toDate()
        ).inDays;
        
        return isValidType && daysSinceResponse < 7;
      }
      
      return false;
    })
    .toList();
```

### 2. Buscar Nome do Remetente

**Arquivo:** `lib/components/enhanced_interest_notification_card.dart`

**Solução:**
```dart
class EnhancedInterestNotificationCard extends StatefulWidget {
  final InterestNotificationModel notification;
  
  @override
  State<EnhancedInterestNotificationCard> createState() => _EnhancedInterestNotificationCardState();
}

class _EnhancedInterestNotificationCardState extends State<EnhancedInterestNotificationCard> {
  String? _senderName;
  bool _isLoadingName = false;
  
  @override
  void initState() {
    super.initState();
    _loadSenderName();
  }
  
  Future<void> _loadSenderName() async {
    // Se já tem nome, usar
    if (widget.notification.fromUserName != null && 
        widget.notification.fromUserName!.trim().isNotEmpty &&
        widget.notification.fromUserName != 'Usuário') {
      setState(() {
        _senderName = widget.notification.fromUserName;
      });
      return;
    }
    
    // Buscar do Firestore
    setState(() {
      _isLoadingName = true;
    });
    
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.notification.fromUserId)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final name = userData['nome'] ?? userData['username'] ?? 'Usuário Anônimo';
        
        setState(() {
          _senderName = name;
          _isLoadingName = false;
        });
      }
    } catch (e) {
      print('❌ Erro ao buscar nome: $e');
      setState(() {
        _senderName = 'Usuário Anônimo';
        _isLoadingName = false;
      });
    }
  }
  
  String get displayName => _senderName ?? widget.notification.fromUserName ?? 'Usuário';
}
```

### 3. Navegação para Perfil Correto

**Arquivo:** `lib/components/enhanced_interest_notification_card.dart`

**Problema Atual:**
```dart
// ❌ Navega para ProfileDisplayView (antigo)
Get.toNamed('/profile-display', arguments: {'userId': fromUserId});
```

**Solução:**
```dart
// ✅ Navega para EnhancedVitrineDisplayView (novo)
void _navigateToProfile() {
  final fromUserId = widget.notification.fromUserId;
  
  if (fromUserId == null || fromUserId.isEmpty) {
    Get.snackbar('Erro', 'ID do usuário não encontrado');
    return;
  }
  
  print('🔍 Navegando para perfil: $fromUserId');
  
  Get.toNamed('/vitrine-display', arguments: {
    'userId': fromUserId,
    'isOwnProfile': false,
  });
}
```

### 4. Botões Corretos por Status

**Arquivo:** `lib/components/enhanced_interest_notification_card.dart`

**Solução:**
```dart
Widget _buildActionButtons() {
  final status = widget.notification.status;
  
  // Match mútuo - apenas botão de conversar
  if (widget.notification.type == 'mutual_match') {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _navigateToChat,
            icon: Icon(Icons.chat),
            label: Text('Conversar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
        ),
      ],
    );
  }
  
  // Interesse aceito - badge + botão conversar
  if (status == 'accepted') {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.celebration, color: Colors.purple),
              SizedBox(width: 8),
              Text(
                'MATCH! Vocês dois demonstraram interesse!',
                style: TextStyle(
                  color: Colors.purple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _navigateToChat,
                icon: Icon(Icons.chat),
                label: Text('Conversar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  // Interesse rejeitado - apenas informação
  if (status == 'rejected') {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Você não demonstrou interesse',
        style: TextStyle(color: Colors.grey),
        textAlign: TextAlign.center,
      ),
    );
  }
  
  // Pendente ou visualizado - botões de resposta
  return Row(
    children: [
      Expanded(
        child: OutlinedButton(
          onPressed: () => _respondToInterest(false),
          child: Text('Não Tenho'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey,
          ),
        ),
      ),
      SizedBox(width: 12),
      Expanded(
        child: ElevatedButton(
          onPressed: () => _respondToInterest(true),
          child: Text('Também Tenho'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pink,
          ),
        ),
      ),
    ],
  );
}
```

### 5. Navegação para Chat

**Arquivo:** `lib/components/enhanced_interest_notification_card.dart`

**Solução:**
```dart
void _navigateToChat() async {
  try {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final otherUserId = widget.notification.fromUserId;
    
    if (currentUserId == null || otherUserId == null) {
      Get.snackbar('Erro', 'Não foi possível abrir o chat');
      return;
    }
    
    // Gerar ID do chat
    final sortedIds = [currentUserId, otherUserId]..sort();
    final chatId = 'match_${sortedIds[0]}_${sortedIds[1]}';
    
    print('💬 Navegando para chat: $chatId');
    
    // Navegar para o chat
    Get.toNamed('/chat', arguments: {
      'chatId': chatId,
      'otherUserId': otherUserId,
      'otherUserName': displayName,
    });
    
  } catch (e) {
    print('❌ Erro ao navegar para chat: $e');
    Get.snackbar('Erro', 'Não foi possível abrir o chat');
  }
}
```

## Data Models

### InterestNotificationModel (sem alterações)

Modelo já está correto, apenas precisa ser usado corretamente.

## Error Handling

### 1. Nome não encontrado
- Fallback para "Usuário Anônimo"
- Log de erro
- Não bloqueia a exibição

### 2. Navegação falha
- Snackbar de erro
- Log detalhado
- Não quebra o app

### 3. Chat não existe
- Criar chat automaticamente se não existir
- Fallback para mensagem de erro

## Testing Strategy

### Testes Manuais

1. **Teste de Nome:**
   - Criar notificação com nome vazio
   - Verificar se busca do Firestore
   - Verificar exibição correta

2. **Teste de Navegação:**
   - Clicar em "Ver Perfil"
   - Verificar se abre EnhancedVitrineDisplayView
   - Verificar dados corretos

3. **Teste de Botões:**
   - Verificar botões para status "pending"
   - Verificar botões para status "accepted"
   - Verificar botões para status "rejected"

4. **Teste de Filtro:**
   - Criar notificação aceita há 3 dias → deve aparecer
   - Criar notificação aceita há 8 dias → não deve aparecer
   - Criar notificação pendente → sempre deve aparecer

5. **Teste de Match:**
   - Aceitar interesse mútuo
   - Verificar criação de notificação mutual_match
   - Verificar criação de chat
   - Verificar badge "MATCH!"

## Implementation Notes

### Ordem de Implementação

1. Corrigir filtro de status no repositório
2. Adicionar busca de nome no card
3. Corrigir navegação para perfil
4. Corrigir botões por status
5. Adicionar navegação para chat
6. Executar script de correção
7. Testar fluxo completo

### Compatibilidade

- Manter compatibilidade com notificações antigas
- Fallbacks para dados ausentes
- Logs detalhados para debug

### Performance

- Buscar nome apenas uma vez (cache no state)
- Não bloquear UI durante busca
- Usar loading indicator se necessário
