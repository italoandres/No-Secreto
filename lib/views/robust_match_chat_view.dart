import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/timestamp_sanitizer.dart';

/// Tela de chat robusta com tratamento de erros
class RobustMatchChatView extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;

  const RobustMatchChatView({
    Key? key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
  }) : super(key: key);

  @override
  _RobustMatchChatViewState createState() => _RobustMatchChatViewState();
}

class _RobustMatchChatViewState extends State<RobustMatchChatView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isSending = false;
  String? _errorMessage;
  Map<String, dynamic>? _chatData;

  @override
  void initState() {
    super.initState();
    _loadChatData();
    _markMessagesAsRead();
  }

  Future<void> _loadChatData() async {
    try {
      final chatDoc =
          await _firestore.collection('match_chats').doc(widget.chatId).get();

      if (chatDoc.exists) {
        setState(() {
          _chatData = TimestampSanitizer.sanitizeChatData(chatDoc.data()!);
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = 'Chat não encontrado';
        });
      }
    } catch (e) {
      print('❌ Erro ao carregar dados do chat: $e');
      setState(() {
        _errorMessage = 'Erro ao carregar chat';
      });
    }
  }

  Future<void> _markMessagesAsRead() async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      // Usar query simples para evitar problemas de índice
      final unreadMessages = await _firestore
          .collection('chat_messages')
          .where('chatId', isEqualTo: widget.chatId)
          .where('senderId', isNotEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .limit(500) // ✅ LIMITE ADICIONADO (mensagens não lidas)
          .get();

      // Marcar como lidas em batch
      final batch = _firestore.batch();
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      if (unreadMessages.docs.isNotEmpty) {
        await batch.commit();
        print('✅ ${unreadMessages.docs.length} mensagens marcadas como lidas');
      }
    } catch (e) {
      print('⚠️ Erro ao marcar mensagens como lidas: $e');
      // Não quebrar o fluxo por causa disso
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    setState(() {
      _isSending = true;
    });

    try {
      // Verificar se o chat ainda é válido
      if (_chatData != null) {
        final expiresAt = _chatData!['expiresAt'] as Timestamp?;
        if (expiresAt != null && expiresAt.toDate().isBefore(DateTime.now())) {
          _showError('Este chat expirou');
          return;
        }
      }

      // Criar mensagem
      final messageData = {
        'chatId': widget.chatId,
        'senderId': currentUser.uid,
        'senderName': currentUser.displayName ?? 'Usuário',
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      };

      // Enviar mensagem
      await _firestore.collection('chat_messages').add(messageData);

      // Atualizar último timestamp do chat
      await _firestore.collection('match_chats').doc(widget.chatId).update({
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessage': message,
      });

      // Limpar campo de texto
      _messageController.clear();

      // Scroll para baixo
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      print('❌ Erro ao enviar mensagem: $e');
      _showError('Erro ao enviar mensagem');
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_chatData != null)
            IconButton(
              icon: Icon(Icons.info_outline),
              onPressed: () => _showChatInfo(),
            ),
        ],
      ),
      body: Column(
        children: [
          // Banner de erro se houver
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              color: Colors.red[100],
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red[800]),
                textAlign: TextAlign.center,
              ),
            ),

          // Lista de mensagens
          Expanded(
            child: _buildMessagesList(),
          ),

          // Campo de input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('chat_messages')
          .where('chatId', isEqualTo: widget.chatId)
          .orderBy('timestamp', descending: false)
          .limit(500) // ✅ LIMITE ADICIONADO (últimas 500 mensagens)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Erro ao carregar mensagens'),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: Text('Tentar Novamente'),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data?.docs ?? [];

        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Nenhuma mensagem ainda.\nSeja o primeiro a enviar uma mensagem!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final messageDoc = messages[index];
            final messageData = messageDoc.data() as Map<String, dynamic>;

            // Sanitizar dados da mensagem
            final sanitizedData =
                TimestampSanitizer.sanitizeMessageData(messageData);

            return _buildMessageBubble(sanitizedData);
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> messageData) {
    final currentUserId = _auth.currentUser?.uid;
    final isMyMessage = messageData['senderId'] == currentUserId;
    final message = messageData['message'] ?? '';
    final timestamp = messageData['timestamp'] as Timestamp?;

    return Align(
      alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMyMessage ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(18),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(
                color: isMyMessage ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            if (timestamp != null) ...[
              SizedBox(height: 4),
              Text(
                _formatTimestamp(timestamp),
                style: TextStyle(
                  color: isMyMessage ? Colors.white70 : Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: Offset(0, -2),
            blurRadius: 4,
            color: Colors.black12,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Digite sua mensagem...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.blue,
            child: IconButton(
              icon: _isSending
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.send, color: Colors.white),
              onPressed: _isSending ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min atrás';
    } else {
      return 'Agora';
    }
  }

  void _showChatInfo() {
    if (_chatData == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Informações do Chat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chat ID: ${widget.chatId}'),
            SizedBox(height: 8),
            Text('Criado em: ${_formatTimestamp(_chatData!['createdAt'])}'),
            SizedBox(height: 8),
            Text('Expira em: ${_formatTimestamp(_chatData!['expiresAt'])}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}