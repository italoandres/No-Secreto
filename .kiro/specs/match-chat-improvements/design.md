# Design Document - Melhorias no Sistema de Chat de Matches

## Overview

Este documento descreve o design técnico para implementar melhorias no sistema de chat de matches mútuos, incluindo reorganização da navegação, correção do alinhamento de mensagens, implementação de indicadores de leitura e correção de bugs.

## Architecture

### Componentes Afetados

```
lib/views/
├── home_view.dart                    # Remover ícone de matches
├── community_info_view.dart          # Adicionar navegação para vitrine
└── romantic_match_chat_view.dart     # Corrigir alinhamento e read receipts

lib/views/vitrine/
└── vitrine_menu_view.dart           # Nova view com menu da vitrine

lib/services/
└── message_read_status_service.dart  # Já existe, melhorar

lib/repositories/
└── match_chat_repository.dart        # Adicionar métodos de read status
```

## Components and Interfaces

### 1. Reorganização da Navegação

#### 1.1 Remover Ícone de Matches da Home

**Arquivo:** `lib/views/home_view.dart`

```dart
// REMOVER este código da AppBar:
IconButton(
  icon: Badge(
    label: Text('$matchCount'),
    child: Icon(Icons.favorite),
  ),
  onPressed: () => Get.toNamed('/accepted-matches'),
)
```

#### 1.2 Adicionar Menu na Vitrine de Propósito

**Arquivo:** `lib/views/community_info_view.dart`

Adicionar botão para navegar para o menu da vitrine:

```dart
ListTile(
  leading: Icon(Icons.storefront, color: Color(0xFFfc6aeb)),
  title: Text('Vitrine de Propósito'),
  subtitle: Text('Gerencie seu perfil e matches'),
  trailing: Icon(Icons.arrow_forward_ios),
  onTap: () => Get.toNamed('/vitrine-menu'),
)
```

#### 1.3 Criar Menu da Vitrine

**Novo Arquivo:** `lib/views/vitrine/vitrine_menu_view.dart`

```dart
class VitrineMenuView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vitrine de Propósito'),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // Header com foto e nome
          _buildHeader(),
          
          Divider(),
          
          // Gerencie seus matches
          ListTile(
            leading: Badge(
              label: StreamBuilder<int>(
                stream: _getMatchCountStream(),
                builder: (context, snapshot) {
                  return Text('${snapshot.data ?? 0}');
                },
              ),
              child: Icon(Icons.favorite, color: Color(0xFFfc6aeb)),
            ),
            title: Text('Gerencie seus matches'),
            subtitle: Text('Veja quem demonstrou interesse'),
            onTap: () => Get.toNamed('/interest-dashboard'),
          ),
          
          // Explorar perfis
          ListTile(
            leading: Icon(Icons.explore, color: Color(0xFF39b9ff)),
            title: Text('Explorar perfis'),
            subtitle: Text('Descubra pessoas com propósito'),
            onTap: () => Get.toNamed('/explore-profiles'),
          ),
          
          // Configure sua vitrine
          ListTile(
            leading: Icon(Icons.edit, color: Color(0xFFfc6aeb)),
            title: Text('Configure sua vitrine de propósito'),
            subtitle: Text('Edite seu perfil espiritual'),
            onTap: () => Get.toNamed('/vitrine-confirmation'),
          ),
        ],
      ),
    );
  }
}
```

### 2. Correção do Alinhamento de Mensagens

#### 2.1 Corrigir Lógica de Alinhamento

**Arquivo:** `lib/views/romantic_match_chat_view.dart`

**Problema Atual:**
```dart
Widget _buildMessageBubble({
  required String message,
  required bool isMe,  // ❌ Sempre true?
  ...
}) {
  // Alinhamento baseado em isMe
}
```

**Solução:**
```dart
Widget _buildMessagesList() {
  return StreamBuilder<QuerySnapshot>(
    stream: _firestore
        .collection('match_chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }

      final messages = snapshot.data!.docs;

      if (messages.isEmpty) {
        return _buildEmptyState();
      }

      return ListView.builder(
        controller: _scrollController,
        reverse: true,
        padding: const EdgeInsets.all(16),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index].data() as Map<String, dynamic>;
          final senderId = message['senderId'] as String;
          
          // ✅ CORREÇÃO: Comparar senderId com userId atual
          final isMe = senderId == _auth.currentUser?.uid;
          
          return _buildMessageBubble(
            message: message['message'] ?? '',
            isMe: isMe,  // ✅ Agora está correto
            timestamp: message['timestamp'] as Timestamp?,
            isRead: message['isRead'] ?? false,
          );
        },
      );
    },
  );
}
```

### 3. Implementação de Indicadores de Leitura

#### 3.1 Marcar Mensagens como Lidas

**Arquivo:** `lib/views/romantic_match_chat_view.dart`

```dart
@override
void initState() {
  super.initState();
  _initializeAnimations();
  _checkForMessages();
  _markMessagesAsRead();  // ✅ Adicionar
}

Future<void> _markMessagesAsRead() async {
  try {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    // Buscar mensagens não lidas do outro usuário
    final unreadMessages = await _firestore
        .collection('match_chats')
        .doc(widget.chatId)
        .collection('messages')
        .where('senderId', isEqualTo: widget.otherUserId)
        .where('isRead', isEqualTo: false)
        .get();

    // Marcar como lidas
    final batch = _firestore.batch();
    for (var doc in unreadMessages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();

    // Zerar contador de não lidas
    await _firestore
        .collection('match_chats')
        .doc(widget.chatId)
        .update({
      'unreadCount.$currentUserId': 0,
    });

    debugPrint('✅ Mensagens marcadas como lidas');
  } catch (e) {
    debugPrint('❌ Erro ao marcar mensagens como lidas: $e');
  }
}
```

#### 3.2 Atualizar Visual dos Indicadores

**Arquivo:** `lib/views/romantic_match_chat_view.dart`

```dart
Widget _buildMessageBubble({
  required String message,
  required bool isMe,
  Timestamp? timestamp,
  required bool isRead,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Avatar do outro usuário (esquerda)
        if (!isMe) ...[
          CircleAvatar(
            radius: 16,
            backgroundImage: widget.otherUserPhotoUrl != null
                ? NetworkImage(widget.otherUserPhotoUrl!)
                : null,
            child: widget.otherUserPhotoUrl == null
                ? Text(
                    widget.otherUserName[0].toUpperCase(),
                    style: const TextStyle(fontSize: 12),
                  )
                : null,
          ),
          const SizedBox(width: 8),
        ],
        
        Flexible(
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Bolha da mensagem
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: isMe
                      ? const LinearGradient(
                          colors: [Color(0xFF39b9ff), Color(0xFFfc6aeb)],
                        )
                      : null,
                  color: isMe ? null : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isMe ? 20 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  message,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: isMe ? Colors.white : Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
              
              const SizedBox(height: 4),
              
              // Timestamp e indicadores de leitura
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (timestamp != null)
                    Text(
                      _formatTime(timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  
                  // ✅ Indicadores de leitura (só para mensagens do usuário atual)
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      isRead ? Icons.done_all : Icons.done,  // ✓✓ ou ✓
                      size: 14,
                      color: isRead 
                          ? const Color(0xFF39b9ff)  // Azul se lida
                          : Colors.grey,              // Cinza se não lida
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
```

### 4. Correção do Erro de Hero Tags

#### 4.1 Tornar Hero Tags Únicos

**Arquivo:** `lib/views/romantic_match_chat_view.dart`

```dart
// ANTES (❌ Duplicado):
Hero(
  tag: 'profile_${widget.otherUserId}',
  child: Container(...),
)

// DEPOIS (✅ Único):
Hero(
  tag: 'chat_profile_${widget.chatId}_${widget.otherUserId}',
  child: Container(...),
)
```

**Arquivo:** `lib/views/accepted_matches_view.dart`

```dart
// Atualizar para usar tags únicas também:
Hero(
  tag: 'match_profile_${match.chatId}_${match.otherUserId}',
  child: CircleAvatar(...),
)
```

## Data Models

### Message Model (Atualizado)

```dart
{
  'messageId': 'msg_123456',
  'senderId': '2MBqslnxAGeZFe18d9h52HYTZIy1',
  'message': 'oi',
  'timestamp': Timestamp.now(),
  'isRead': false,  // ✅ Novo campo
}
```

### Chat Model (Atualizado)

```dart
{
  'chatId': 'match_user1_user2',
  'participants': ['user1', 'user2'],
  'lastMessage': 'oi',
  'lastMessageAt': Timestamp.now(),
  'unreadCount': {
    'user1': 0,  // ✅ Zerado quando abre o chat
    'user2': 1,  // ✅ Incrementado quando recebe mensagem
  },
  'createdAt': Timestamp.now(),
}
```

## Error Handling

### 1. Erro ao Marcar como Lida

```dart
try {
  await _markMessagesAsRead();
} catch (e) {
  debugPrint('❌ Erro ao marcar mensagens como lidas: $e');
  // Não bloquear a UI, apenas logar
}
```

### 2. Erro ao Carregar Mensagens

```dart
if (!snapshot.hasData) {
  return const Center(child: CircularProgressIndicator());
}

if (snapshot.hasError) {
  return Center(
    child: Text('Erro ao carregar mensagens: ${snapshot.error}'),
  );
}
```

## Testing Strategy

### Unit Tests

1. Testar lógica de `isMe` (senderId == currentUserId)
2. Testar marcação de mensagens como lidas
3. Testar atualização de contador de não lidas

### Integration Tests

1. Testar fluxo completo: enviar mensagem → marcar como lida → atualizar contador
2. Testar navegação: Home → Comunidade → Vitrine Menu → Matches
3. Testar alinhamento de mensagens com múltiplos usuários

### UI Tests

1. Verificar alinhamento visual (direita/esquerda)
2. Verificar indicadores de leitura (✓ e ✓✓, cinza e azul)
3. Verificar estado vazio
4. Verificar ausência de erros de Hero tags

## Performance Considerations

1. **Batch Updates**: Usar batch para marcar múltiplas mensagens como lidas
2. **Stream Optimization**: Usar `limit()` para carregar mensagens paginadas
3. **Cache**: Cachear contador de matches para evitar queries desnecessárias

## Security Considerations

1. **Validação de Permissões**: Verificar se usuário tem permissão para acessar o chat
2. **Sanitização**: Validar senderId antes de comparar com currentUserId
3. **Rate Limiting**: Limitar frequência de marcação de mensagens como lidas

## Migration Plan

1. Adicionar campo `isRead` em mensagens existentes (default: true para não afetar histórico)
2. Atualizar regras do Firestore para permitir atualização de `isRead`
3. Testar em ambiente de desenvolvimento
4. Deploy gradual em produção
