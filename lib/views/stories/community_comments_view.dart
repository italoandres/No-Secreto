import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/storie_file_model.dart';
import '../../models/community_comment_model.dart';
import '../../repositories/story_interactions_repository.dart';
import '../../components/community_comment_card.dart';
import 'package:whatsapp_chat/utils/debug_utils.dart';

class CommunityCommentsView extends StatefulWidget {
  final StorieFileModel story;

  const CommunityCommentsView({
    super.key,
    required this.story,
  });

  @override
  State<CommunityCommentsView> createState() => _CommunityCommentsViewState();
}

class _CommunityCommentsViewState extends State<CommunityCommentsView> {
  final TextEditingController _commentController = TextEditingController();
  final StoryInteractionsRepository _repository =
      StoryInteractionsRepository();
  bool _isDescriptionExpanded = false;
  bool _isSending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    if (_commentController.text.trim().isEmpty) return;
    if (_isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }

      // Buscar dados do usuário
      final userData =
          await _repository.getUserDataForComment(currentUser.uid);

      if (userData == null) {
        throw Exception('Dados do usuário não encontrados');
      }

      // Criar comentário
      await _repository.addRootComment(
        storyId: widget.story.id ?? '',
        userId: currentUser.uid,
        userName: userData['displayName'] ?? 'Usuário',
        userAvatarUrl: userData['mainPhotoUrl'] ?? '',
        text: _commentController.text.trim(),
        contexto: widget.story.contexto ?? 'principal', // 🔧 Passar contexto do story
      );

      // Limpar campo
      _commentController.clear();

      // Feedback visual
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comentário enviado! 🙏'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      safePrint('❌ Erro ao enviar comentário: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar comentário: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // 1️⃣ CABEÇALHO FIXO
            _buildHeader(),

            // 2️⃣ SEÇÃO PRINCIPAL - COMUNIDADE VIVA
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔥 CHATS EM ALTA
                    _buildHotChatsSection(),

                    const SizedBox(height: 24),

                    // 🌱 CHATS RECENTES
                    _buildRecentChatsSection(),

                    const SizedBox(height: 80), // Espaço para o rodapé
                  ],
                ),
              ),
            ),

            // 3️⃣ RODAPÉ FIXO - Campo de envio
            _buildCommentInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Botão voltar
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const Expanded(
                child: Text(
                  'Comunidade',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Título do vídeo
          if (widget.story.titulo != null && widget.story.titulo!.isNotEmpty)
            Text(
              widget.story.titulo!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          // Descrição com "ver mais"
          if (widget.story.descricao != null &&
              widget.story.descricao!.isNotEmpty) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isDescriptionExpanded = !_isDescriptionExpanded;
                });
              },
              child: Text(
                widget.story.descricao!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                maxLines: _isDescriptionExpanded ? null : 2,
                overflow: _isDescriptionExpanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isDescriptionExpanded = !_isDescriptionExpanded;
                });
              },
              child: Text(
                _isDescriptionExpanded ? '⬆️ Ver menos' : '⬇️ Ver mais',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHotChatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text(
                '🔥',
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              const Text(
                'CHATS EM ALTA',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<CommunityCommentModel>>(
          stream: _repository.getHotChatsStream(widget.story.id ?? ''),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text('Erro: ${snapshot.error}'),
                ),
              );
            }

            final hotChats = snapshot.data ?? [];

            if (hotChats.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Text(
                    'Nenhuma conversa em alta ainda.\nSeja o primeiro a comentar! 🙏',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: hotChats.length,
              itemBuilder: (context, index) {
                return CommunityCommentCard(
                  comment: hotChats[index],
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentChatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text(
                '🌱',
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              const Text(
                'CHATS RECENTES',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<CommunityCommentModel>>(
          stream: _repository.getRecentChatsStream(widget.story.id ?? ''),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text('Erro: ${snapshot.error}'),
                ),
              );
            }

            final recentChats = snapshot.data ?? [];

            if (recentChats.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Text(
                    'Nenhum comentário recente.\nCompartilhe o que o Pai falou ao seu coração! 💬',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentChats.length,
              itemBuilder: (context, index) {
                return CommunityCommentCard(
                  comment: recentChats[index],
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Escreva aqui o que o Pai falou ao seu coração...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: Colors.blue[700],
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: _isSending ? null : _sendComment,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(12),
                child: _isSending
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 24,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
