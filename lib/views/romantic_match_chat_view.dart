import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// View de chat romântico para matches mútuos
/// Design moderno inspirado nos melhores apps de mensagem
class RomanticMatchChatView extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhotoUrl;

  const RomanticMatchChatView({
    Key? key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhotoUrl,
  }) : super(key: key);

  @override
  State<RomanticMatchChatView> createState() => _RomanticMatchChatViewState();
}

class _RomanticMatchChatViewState extends State<RomanticMatchChatView>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late AnimationController _heartAnimationController;
  late Animation<double> _heartAnimation;
  bool _hasMessages = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkForMessages();
    _markMessagesAsRead();
  }

  void _initializeAnimations() {
    _heartAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _heartAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _heartAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _checkForMessages() async {
    try {
      final messages = await _firestore
          .collection('match_chats')
          .doc(widget.chatId)
          .collection('messages')
          .limit(1)
          .get();

      setState(() {
        _hasMessages = messages.docs.isNotEmpty;
        _isLoading = false;
      });
    } catch (e) {
      print('Erro ao verificar mensagens: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Marca mensagens do outro usuário como lidas
  Future<void> _markMessagesAsRead() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Buscar mensagens não lidas do outro usuário
      final unreadMessages = await _firestore
          .collection('match_chats')
          .doc(widget.chatId)
          .collection('messages')
          .where('senderId', isEqualTo: widget.otherUserId)
          .where('isRead', isEqualTo: false)
          .get();

      if (unreadMessages.docs.isEmpty) return;

      // Marcar todas como lidas usando batch
      final batch = _firestore.batch();
      
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();

      // Zerar contador de mensagens não lidas do usuário atual
      await _firestore.collection('match_chats').doc(widget.chatId).update({
        'unreadCount.${currentUser.uid}': 0,
      });

      print('✅ ${unreadMessages.docs.length} mensagens marcadas como lidas');
    } catch (e) {
      print('⚠️ Erro ao marcar mensagens como lidas: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _heartAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _hasMessages
                    ? _buildMessagesList()
                    : _buildEmptyState(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: () => Get.back(),
      ),
      title: Row(
        children: [
          // Foto de perfil
          Hero(
            tag: 'chat_profile_${widget.chatId}_${widget.otherUserId}',
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: widget.otherUserPhotoUrl == null
                    ? const LinearGradient(
                        colors: [Color(0xFF39b9ff), Color(0xFFfc6aeb)],
                      )
                    : null,
                image: widget.otherUserPhotoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(widget.otherUserPhotoUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: widget.otherUserPhotoUrl == null
                  ? Center(
                      child: Text(
                        widget.otherUserName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Match Mútuo 💕',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFFfc6aeb),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.black87),
          onPressed: () {
            // Menu de opções
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            
            // Animação de corações
            ScaleTransition(
              scale: _heartAnimation,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF39b9ff).withOpacity(0.2),
                      const Color(0xFFfc6aeb).withOpacity(0.2),
                    ],
                  ),
                ),
                child: const Center(
                  child: Text(
                    '💕',
                    style: TextStyle(fontSize: 60),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Título
            Text(
              'Vocês têm um Match! 🎉',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFfc6aeb),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // Mensagem espiritual
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    '✨',
                    style: TextStyle(fontSize: 32),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '"O amor é paciente, o amor é bondoso. Não inveja, não se vangloria, não se orgulha."',
                    style: GoogleFonts.crimsonText(
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1 Coríntios 13:4',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF39b9ff),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Elementos decorativos
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFloatingHeart(delay: 0),
                const SizedBox(width: 20),
                _buildFloatingHeart(delay: 500),
                const SizedBox(width: 20),
                _buildFloatingHeart(delay: 1000),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Mensagem de incentivo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF39b9ff).withOpacity(0.1),
                    const Color(0xFFfc6aeb).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Comece uma conversa! 💬',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Envie a primeira mensagem e inicie esta jornada de propósito juntos.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingHeart({required int delay}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 1500 + delay),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, -20 * value),
          child: Opacity(
            opacity: 1 - value,
            child: const Text(
              '💕',
              style: TextStyle(fontSize: 24),
            ),
          ),
        );
      },
      onEnd: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

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
            final senderId = message['senderId'] as String?;
            final currentUserId = _auth.currentUser?.uid;
            
            // Garantir comparação correta de strings
            final isMe = senderId != null && 
                         currentUserId != null && 
                         senderId == currentUserId;
            
            return _buildMessageBubble(
              message: message['message'] ?? '',
              isMe: isMe,
              timestamp: message['timestamp'] as Timestamp?,
              isRead: message['isRead'] ?? false,
            );
          },
        );
      },
    );
  }

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
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        isRead ? Icons.done_all : Icons.done,
                        size: 14,
                        color: isRead ? const Color(0xFF39b9ff) : Colors.grey,
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

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Botão de emoji
            IconButton(
              icon: const Icon(Icons.emoji_emotions_outlined),
              color: const Color(0xFFfc6aeb),
              onPressed: () {
                // Abrir seletor de emoji
              },
            ),
            
            // Campo de texto
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Digite sua mensagem...',
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Botão de enviar
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF39b9ff), Color(0xFFfc6aeb)],
                ),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded),
                color: Colors.white,
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Limpar campo
      _messageController.clear();

      // Enviar mensagem
      await _firestore
          .collection('match_chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        'senderId': currentUser.uid,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // Atualizar última mensagem do chat
      await _firestore.collection('match_chats').doc(widget.chatId).update({
        'lastMessage': message,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadCount.${widget.otherUserId}': FieldValue.increment(1),
      });

      // Atualizar estado se era a primeira mensagem
      if (!_hasMessages) {
        setState(() {
          _hasMessages = true;
        });
      }

      // Scroll para o final
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      print('Erro ao enviar mensagem: $e');
      Get.snackbar(
        'Erro',
        'Não foi possível enviar a mensagem. Tente novamente.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  String _formatTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(date);
    } else if (difference.inDays == 1) {
      return 'Ontem ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays < 7) {
      return DateFormat('EEE HH:mm', 'pt_BR').format(date);
    } else {
      return DateFormat('dd/MM/yy').format(date);
    }
  }
}
