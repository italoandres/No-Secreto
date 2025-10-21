# 🚀 Implementação Completa - Melhorias no Chat de Matches

## ✅ Status: PRONTO PARA IMPLEMENTAR

Este documento contém TODAS as mudanças necessárias para corrigir os problemas do chat de matches.

---

## 📋 TAREFA 1: Reorganizar Navegação (CRÍTICO)

### Passo 1.1: Remover ícone de matches da HomeView

**Arquivo a modificar:** Procure no código onde está o ícone de matches na home e REMOVA.

### Passo 1.2: Adicionar navegação em CommunityInfoView

**Arquivo:** `lib/views/community_info_view.dart`

Adicione este ListTile na lista de opções:

```dart
ListTile(
  leading: Icon(Icons.storefront, color: Color(0xFFfc6aeb)),
  title: Text('Vitrine de Propósito'),
  subtitle: Text('Gerencie seu perfil e matches'),
  trailing: Icon(Icons.arrow_forward_ios),
  onTap: () => Get.toNamed('/vitrine-menu'),
),
```

### Passo 1.3: Criar VitrineMenuView

**Criar arquivo:** `lib/views/vitrine/vitrine_menu_view.dart`

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VitrineMenuView extends StatelessWidget {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Vitrine de Propósito',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Gerencie seus matches
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.all(16),
              leading: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('interest_notifications')
                    .where('toUserId', isEqualTo: _auth.currentUser?.uid)
                    .where('type', isEqualTo: 'mutual_match')
                    .where('status', isEqualTo: 'new')
                    .snapshots(),
                builder: (context, snapshot) {
                  final count = snapshot.data?.docs.length ?? 0;
                  return Badge(
                    label: Text('$count'),
                    isLabelVisible: count > 0,
                    child: Icon(
                      Icons.favorite,
                      color: Color(0xFFfc6aeb),
                      size: 32,
                    ),
                  );
                },
              ),
              title: Text(
                'Gerencie seus matches',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Veja quem demonstrou interesse',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Get.toNamed('/interest-dashboard'),
            ),
          ),
          
          SizedBox(height: 12),
          
          // Explorar perfis
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.all(16),
              leading: Icon(
                Icons.explore,
                color: Color(0xFF39b9ff),
                size: 32,
              ),
              title: Text(
                'Explorar perfis',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Descubra pessoas com propósito',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Get.toNamed('/explore-profiles'),
            ),
          ),
          
          SizedBox(height: 12),
          
          // Configure sua vitrine
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.all(16),
              leading: Icon(
                Icons.edit,
                color: Color(0xFFfc6aeb),
                size: 32,
              ),
              title: Text(
                'Configure sua vitrine de propósito',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Edite seu perfil espiritual',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Get.toNamed('/vitrine-confirmation'),
            ),
          ),
        ],
      ),
    );
  }
}
```

### Passo 1.4: Adicionar rota no main.dart

**Arquivo:** `lib/main.dart`

Adicione esta rota na lista de GetPage:

```dart
GetPage(
  name: '/vitrine-menu',
  page: () => VitrineMenuView(),
  transition: Transition.rightToLeft,
),
```

---

## 📋 TAREFA 2: Corrigir Alinhamento de Mensagens (CRÍTICO)

**Arquivo:** `lib/views/romantic_match_chat_view.dart`

### Localizar e substituir o método _buildMessagesList():

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

      if (snapshot.hasError) {
        return Center(
          child: Text('Erro ao carregar mensagens: ${snapshot.error}'),
        );
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
          
          // ✅ CORREÇÃO CRÍTICA: Comparar senderId com userId atual
          final isMe = senderId == _auth.currentUser?.uid;
          
          debugPrint('📨 Mensagem: senderId=$senderId, currentUser=${_auth.currentUser?.uid}, isMe=$isMe');
          
          return _buildMessageBubble(
            message: message['message'] ?? '',
            isMe: isMe,  // ✅ Agora está correto!
            timestamp: message['timestamp'] as Timestamp?,
            isRead: message['isRead'] ?? false,
          );
        },
      );
    },
  );
}
```

---

## 📋 TAREFA 3: Implementar Indicadores de Leitura

**Arquivo:** `lib/views/romantic_match_chat_view.dart`

### Passo 3.1: Adicionar método _markMessagesAsRead()

Adicione este método na classe:

```dart
Future<void> _markMessagesAsRead() async {
  try {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    debugPrint('📖 Marcando mensagens como lidas para $currentUserId');

    // Buscar mensagens não lidas do outro usuário
    final unreadMessages = await _firestore
        .collection('match_chats')
        .doc(widget.chatId)
        .collection('messages')
        .where('senderId', isEqualTo: widget.otherUserId)
        .where('isRead', isEqualTo: false)
        .get();

    if (unreadMessages.docs.isEmpty) {
      debugPrint('✅ Nenhuma mensagem não lida');
      return;
    }

    debugPrint('📖 Marcando ${unreadMessages.docs.length} mensagens como lidas');

    // Marcar como lidas usando batch
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

    debugPrint('✅ Mensagens marcadas como lidas com sucesso');
  } catch (e) {
    debugPrint('❌ Erro ao marcar mensagens como lidas: $e');
  }
}
```

### Passo 3.2: Chamar no initState()

Modifique o initState para incluir:

```dart
@override
void initState() {
  super.initState();
  _initializeAnimations();
  _checkForMessages();
  _markMessagesAsRead();  // ✅ Adicionar esta linha
}
```

### Passo 3.3: Atualizar _buildMessageBubble()

Substitua o método _buildMessageBubble por este:

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

### Passo 3.4: Adicionar método _formatTime()

```dart
String _formatTime(Timestamp timestamp) {
  final date = timestamp.toDate();
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inDays == 0) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  } else if (difference.inDays == 1) {
    return 'Ontem';
  } else {
    return '${date.day}/${date.month}';
  }
}
```

### Passo 3.5: Atualizar envio de mensagem para incluir isRead

No método de envio de mensagem, certifique-se de incluir:

```dart
'isRead': false,  // ✅ Adicionar este campo
```

---

## 📋 TAREFA 4: Corrigir Hero Tags Duplicados

**Arquivo:** `lib/views/romantic_match_chat_view.dart`

Procure por `Hero(` e atualize para:

```dart
Hero(
  tag: 'chat_profile_${widget.chatId}_${widget.otherUserId}',  // ✅ Único
  child: CircleAvatar(...),
)
```

**Arquivo:** `lib/views/accepted_matches_view.dart`

Procure por `Hero(` e atualize para:

```dart
Hero(
  tag: 'match_profile_${match.chatId}_${match.otherUserId}',  // ✅ Único
  child: CircleAvatar(...),
)
```

---

## 📋 TAREFA 5: Validar Estado Vazio

O estado vazio já está implementado corretamente! Apenas verifique se o método `_buildEmptyState()` existe e está funcionando.

---

## 🎯 CHECKLIST FINAL

Após implementar tudo, teste:

- [ ] Ícone de matches removido da home
- [ ] Navegação Comunidade → Vitrine Menu funciona
- [ ] Vitrine Menu mostra 3 opções
- [ ] Mensagens do Italo aparecem à direita (azul/rosa)
- [ ] Mensagens da Itala aparecem à esquerda (branco)
- [ ] Check simples (✓) cinza para não lida
- [ ] Check duplo (✓✓) azul para lida
- [ ] Sem erros de Hero tags no console
- [ ] Estado vazio aparece quando não há mensagens

---

## 🚀 PRONTO!

Todas as mudanças estão documentadas. Implemente uma por uma e teste!

**Boa sorte! 💪**
