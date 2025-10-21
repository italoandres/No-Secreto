import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message_model.dart';
import '../models/match_chat_model.dart';
import '../repositories/match_chat_repository.dart';
import '../services/message_sender_service.dart';
import '../components/chat_message_bubble.dart';
import '../components/chat_expiration_banner.dart';

/// Tela de chat individual entre dois usuários que deram match
class MatchChatView extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhoto;
  final int daysRemaining;

  const MatchChatView({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhoto,
    required this.daysRemaining,
  });

  @override
  State<MatchChatView> createState() => _MatchChatViewState();
}

class _MatchChatViewState extends State<MatchChatView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  
  List<ChatMessageModel> _messages = [];
  MatchChatModel? _chatModel;
  StreamSubscription<List<ChatMessageModel>>? _messagesSubscription;

  
  bool _isLoading = true;
  bool _isSendingMessage = false;
  bool _hasError = false;
  String _errorMessage = '';
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _getCurrentUserId();
    _initializeChat();
    _setupMessageListener();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    _messagesSubscription?.cancel();
    super.dispose();
  }

  /// Obtém o ID do usuário atual
  void _getCurrentUserId() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _currentUserId = user.uid;
        print('✅ Current user ID: $_currentUserId');
      } else {
        print('❌ Nenhum usuário autenticado');
      }
    } catch (e) {
      print('❌ Erro ao obter usuário atual: $e');
    }
  }

  /// Inicializa o chat
  Future<void> _initializeChat() async {
    try {
      print('🔄 Inicializando chat ${widget.chatId}...');
      
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Buscar o chat existente
      var chat = await MatchChatRepository.getChatById(widget.chatId);
      
      // Se o chat não existe, criar um novo
      if (chat == null) {
        print('📝 Chat não encontrado. Criando novo chat...');
        
        // Criar novo chat (o chatId é gerado automaticamente)
        final newChat = MatchChatModel.create(
          user1Id: widget.otherUserId,
          user2Id: _currentUserId ?? '',
        );
        
        await MatchChatRepository.createChat(newChat);
        
        // Buscar o chat recém-criado
        chat = await MatchChatRepository.getChatById(newChat.id);
        
        if (chat == null) {
          throw Exception('Erro ao criar chat');
        }
        
        print('✅ Chat criado com sucesso: ${chat.id}');
      }

      if (mounted) {
        setState(() {
          _chatModel = chat;
          _isLoading = false;
        });
      }

      print('✅ Chat inicializado: ${chat!.id}');

    } catch (e) {
      print('❌ Erro ao inicializar chat: $e');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Erro ao carregar chat. Tente novamente.';
        });
      }
    }
  }

  /// Configura listener para mensagens em tempo real
  void _setupMessageListener() {
    _messagesSubscription = MatchChatRepository
        .getMessagesStream(widget.chatId)
        .listen(
      (messages) {
        if (mounted) {
          setState(() {
            _messages = messages;
          });
          
          // Marcar mensagens como lidas
          _markMessagesAsRead();
          
          // Scroll para o final
          _scrollToBottom();
        }
      },
      onError: (error) {
        print('❌ Erro no stream de mensagens: $error');
      },
    );

    // TODO: Implementar stream do chat se necessário
    // Por enquanto, vamos atualizar o chat periodicamente ou quando necessário
  }

  /// Marca mensagens não lidas como lidas
  Future<void> _markMessagesAsRead() async {
    try {
      final unreadMessages = _messages
          .where((msg) => !msg.isRead && msg.senderId != _currentUserId)
          .toList();

      if (unreadMessages.isNotEmpty) {
        await MatchChatRepository.markMessagesAsRead(
          widget.chatId,
          _currentUserId!,
        );
      }
    } catch (e) {
      print('❌ Erro ao marcar mensagens como lidas: $e');
    }
  }

  /// Scroll para o final da lista
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  /// Envia uma nova mensagem usando o MessageSenderService
  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    
    if (messageText.isEmpty || _isSendingMessage) return;

    try {
      setState(() {
        _isSendingMessage = true;
      });

      print('📤 Enviando mensagem: $messageText');

      // Limpar campo de texto imediatamente para melhor UX
      _messageController.clear();

      // Enviar mensagem usando o serviço robusto
      final result = await MessageSenderService.sendMessage(
        chatId: widget.chatId,
        senderId: _currentUserId!,
        senderName: 'Você', // TODO: Obter nome real do usuário
        messageText: messageText,
        matchDate: DateTime.now(), // Data do match
      );

      if (mounted) {
        if (result.isSuccess) {
          print('✅ Mensagem enviada com sucesso');
          
          // Mostrar feedback de sucesso discreto
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Mensagem enviada'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
            ),
          );
        } else {
          // Restaurar texto se houve erro
          _messageController.text = messageText;
          
          // Mostrar erro específico baseado no tipo
          _showSendError(result);
        }
      }

    } catch (e) {
      print('❌ Erro inesperado ao enviar mensagem: $e');
      
      if (mounted) {
        // Restaurar texto
        _messageController.text = messageText;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro inesperado. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingMessage = false;
        });
      }
    }
  }

  /// Mostra erro específico baseado no resultado do envio
  void _showSendError(MessageSendResponse result) {
    // Mostrar erro genérico por enquanto
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Erro ao enviar mensagem. Tente novamente.'),
        backgroundColor: Colors.red,
      ),
    );

  }

  /// Mostra diálogo de chat expirado
  void _showExpiredChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chat Expirado'),
        content: Text(
          'O chat com ${widget.otherUserName} expirou. '
          'Não é mais possível enviar mensagens.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  /// Callback quando o chat expira
  void _onChatExpired() {
    if (mounted) {
      setState(() {
        _chatModel = _chatModel?.copyWith(isExpired: true);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este chat expirou. Não é mais possível enviar mensagens.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  /// Constrói a AppBar personalizada
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        onPressed: () => Get.back(),
        icon: const Icon(Icons.arrow_back),
      ),
      title: Row(
        children: [
          // Foto do usuário
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            backgroundImage: widget.otherUserPhoto != null
                ? NetworkImage(widget.otherUserPhoto!)
                : null,
            child: widget.otherUserPhoto == null
                ? Text(
                    widget.otherUserName.isNotEmpty 
                        ? widget.otherUserName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          
          const SizedBox(width: 12),
          
          // Nome e status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                if (_chatModel != null)
                  Text(
                    _chatModel!.hasExpired 
                        ? 'Chat expirado'
                        : '${_chatModel!.daysRemaining} dias restantes',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Menu de opções
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'info':
                _showChatInfo();
                break;
              case 'clear':
                _showClearChatDialog();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'info',
              child: Row(
                children: [
                  Icon(Icons.info_outline),
                  SizedBox(width: 12),
                  Text('Informações do Chat'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  Icon(Icons.clear_all),
                  SizedBox(width: 12),
                  Text('Limpar Histórico'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Constrói o corpo da tela
  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }
    
    if (_hasError) {
      return _buildErrorState();
    }
    
    return Column(
      children: [
        // Banner de expiração
        if (_chatModel != null && _chatModel!.hasExpired)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.red.shade100,
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Este chat expirou. Não é mais possível enviar mensagens.',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              ],
            ),
          ),
        
        // Lista de mensagens
        Expanded(
          child: _buildMessagesList(),
        ),
        
        // Campo de input
        _buildMessageInput(),
      ],
    );
  }

  /// Estado de carregamento
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Carregando chat...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// Estado de erro
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Erro ao Carregar Chat',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.red.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            
            const SizedBox(height: 24),
            
            ElevatedButton.icon(
              onPressed: _initializeChat,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Lista de mensagens
  Widget _buildMessagesList() {
    if (_messages.isEmpty) {
      return _buildEmptyMessagesState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isCurrentUser = message.senderId == _currentUserId;
        
        // Mostrar separador de data se necessário
        bool showDateSeparator = false;
        if (index == 0) {
          showDateSeparator = true;
        } else {
          final previousMessage = _messages[index - 1];
          final currentDate = DateTime(
            message.timestamp.year,
            message.timestamp.month,
            message.timestamp.day,
          );
          final previousDate = DateTime(
            previousMessage.timestamp.year,
            previousMessage.timestamp.month,
            previousMessage.timestamp.day,
          );
          showDateSeparator = !currentDate.isAtSameMomentAs(previousDate);
        }

        return Column(
          children: [
            if (showDateSeparator)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '${message.timestamp.day}/${message.timestamp.month}/${message.timestamp.year}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ),
            
            ChatMessageBubble(
              message: message,
              isCurrentUser: isCurrentUser,
              onLongPress: () => _showMessageOptions(message),
            ),
          ],
        );
      },
    );
  }

  /// Estado vazio (sem mensagens)
  Widget _buildEmptyMessagesState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Início da Conversa',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Vocês deram match! Que tal começar uma conversa com ${widget.otherUserName}?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Campo de input para mensagens
  Widget _buildMessageInput() {
    final isExpired = _chatModel?.hasExpired == true;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: isExpired
          ? _buildExpiredChatMessage()
          : _buildActiveMessageInput(),
    );
  }

  /// Mensagem para chat expirado
  Widget _buildExpiredChatMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.block,
            color: Colors.red.shade600,
            size: 20,
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: Text(
              'Este chat expirou. Não é mais possível enviar mensagens.',
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Input ativo para mensagens
  Widget _buildActiveMessageInput() {
    return Row(
      children: [
        // Campo de texto
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextField(
              controller: _messageController,
              focusNode: _messageFocusNode,
              maxLines: null,
              maxLength: 1000,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Digite sua mensagem...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                counterText: '',
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Botão de enviar
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: _isSendingMessage ? null : _sendMessage,
            icon: _isSendingMessage
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(
                    Icons.send,
                    color: Colors.white,
                  ),
          ),
        ),
      ],
    );
  }

  /// Mostra opções para uma mensagem
  void _showMessageOptions(ChatMessageModel message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copiar Mensagem'),
              onTap: () {
                // TODO: Implementar cópia
                Navigator.pop(context);
              },
            ),
            
            if (message.senderId == _currentUserId)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Excluir Mensagem'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteMessageDialog(message);
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Mostra diálogo para excluir mensagem
  void _showDeleteMessageDialog(ChatMessageModel message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Mensagem'),
        content: const Text('Tem certeza que deseja excluir esta mensagem?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implementar exclusão de mensagem
            },
            child: const Text(
              'Excluir',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  /// Mostra informações do chat
  void _showChatInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chat com ${widget.otherUserName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_chatModel != null) ...[
              Text('Criado em: ${_chatModel!.formattedDate}'),
              const SizedBox(height: 8),
              Text('Expira em: ${_chatModel!.formattedExpirationDate}'),
              const SizedBox(height: 8),
              Text('Status: ${_chatModel!.hasExpired ? 'Expirado' : 'Ativo'}'),
              const SizedBox(height: 8),
              Text('Mensagens: ${_messages.length}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  /// Mostra diálogo para limpar chat
  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar Histórico'),
        content: const Text(
          'Tem certeza que deseja limpar todo o histórico de mensagens? '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implementar limpeza do chat
            },
            child: const Text(
              'Limpar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}