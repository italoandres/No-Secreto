import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/match_chat_creator.dart';
import '../views/match_chat_view.dart';

/// Botão "Conversar" robusto que garante a criação do chat antes de abrir
class RobustConversarButton extends StatefulWidget {
  final String otherUserId;
  final String? otherUserName;
  final VoidCallback? onChatCreated;

  const RobustConversarButton({
    Key? key,
    required this.otherUserId,
    this.otherUserName,
    this.onChatCreated,
  }) : super(key: key);

  @override
  _RobustConversarButtonState createState() => _RobustConversarButtonState();
}

class _RobustConversarButtonState extends State<RobustConversarButton> {
  bool _isCreatingChat = false;
  String? _statusMessage;

  Future<void> _onConversarPressed() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showError('Usuário não autenticado');
      return;
    }

    setState(() {
      _isCreatingChat = true;
      _statusMessage = 'Verificando chat...';
    });

    try {
      // Verificar se o chat já existe
      final chatExists = await MatchChatCreator.chatExists(
        currentUser.uid,
        widget.otherUserId,
      );

      if (chatExists) {
        setState(() {
          _statusMessage = 'Abrindo chat...';
        });
        
        // Chat já existe, abrir diretamente
        final chatId = MatchChatCreator.getChatId(currentUser.uid, widget.otherUserId);
        await _openChat(chatId);
      } else {
        setState(() {
          _statusMessage = 'Criando chat...';
        });
        
        // Chat não existe, criar primeiro
        final chatId = await MatchChatCreator.createOrGetChatId(
          currentUser.uid,
          widget.otherUserId,
        );
        
        setState(() {
          _statusMessage = 'Chat criado! Abrindo...';
        });
        
        // Aguardar um momento para garantir que foi criado
        await Future.delayed(Duration(milliseconds: 500));
        
        // Chamar callback se fornecido
        if (widget.onChatCreated != null) {
          widget.onChatCreated!();
        }
        
        // Abrir o chat
        await _openChat(chatId);
      }

    } catch (e) {
      print('❌ Erro ao processar botão Conversar: $e');
      _showError('Estamos criando seu chat... tente novamente em alguns segundos');
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingChat = false;
          _statusMessage = null;
        });
      }
    }
  }

  Future<void> _openChat(String chatId) async {
    try {
      if (!mounted) return;
      
      // Navegar para a tela de chat
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MatchChatView(
            chatId: chatId,
            otherUserId: widget.otherUserId,
            otherUserName: widget.otherUserName ?? 'Usuário',
          ),
        ),
      );
    } catch (e) {
      print('❌ Erro ao abrir chat: $e');
      _showError('Erro ao abrir chat. Tente novamente.');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Tentar Novamente',
          textColor: Colors.white,
          onPressed: _onConversarPressed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton.icon(
          onPressed: _isCreatingChat ? null : _onConversarPressed,
          icon: _isCreatingChat
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(Icons.chat_bubble_outline),
          label: Text(_isCreatingChat ? 'Preparando...' : 'Conversar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isCreatingChat ? Colors.grey : Colors.blue,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        if (_statusMessage != null) ...[
          SizedBox(height: 8),
          Text(
            _statusMessage!,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}

/// Versão simples do botão para uso rápido
class SimpleConversarButton extends StatelessWidget {
  final String otherUserId;
  final String? otherUserName;

  const SimpleConversarButton({
    Key? key,
    required this.otherUserId,
    this.otherUserName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RobustConversarButton(
      otherUserId: otherUserId,
      otherUserName: otherUserName,
    );
  }
}