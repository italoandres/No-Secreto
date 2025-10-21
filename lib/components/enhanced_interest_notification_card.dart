import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/interest_notification_model.dart';
import '../repositories/interest_notification_repository.dart';

/// Card de notificação de interesse com design moderno e correções
class EnhancedInterestNotificationCard extends StatefulWidget {
  final InterestNotificationModel notification;
  final VoidCallback? onResponse;

  const EnhancedInterestNotificationCard({
    Key? key,
    required this.notification,
    this.onResponse,
  }) : super(key: key);

  @override
  State<EnhancedInterestNotificationCard> createState() =>
      _EnhancedInterestNotificationCardState();
}

class _EnhancedInterestNotificationCardState
    extends State<EnhancedInterestNotificationCard> {
  String? _senderName;
  bool _isLoadingName = false;
  bool _isResponding = false;

  @override
  void initState() {
    super.initState();
    _loadSenderName();
  }

  /// Buscar nome do remetente do Firestore se estiver vazio
  Future<void> _loadSenderName() async {
    // Se já tem nome válido, usar
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
      print(
          '🔍 [CARD] Buscando nome do usuário: ${widget.notification.fromUserId}');

      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.notification.fromUserId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final name = userData['nome'] ?? userData['username'] ?? 'Usuário Anônimo';

        print('✅ [CARD] Nome encontrado: $name');

        setState(() {
          _senderName = name;
          _isLoadingName = false;
        });
      } else {
        print('⚠️ [CARD] Usuário não encontrado no Firestore');
        setState(() {
          _senderName = 'Usuário Anônimo';
          _isLoadingName = false;
        });
      }
    } catch (e) {
      print('❌ [CARD] Erro ao buscar nome: $e');
      setState(() {
        _senderName = 'Usuário Anônimo';
        _isLoadingName = false;
      });
    }
  }

  /// Nome para exibição
  String get displayName =>
      _senderName ?? widget.notification.fromUserName ?? 'Usuário';

  @override
  Widget build(BuildContext context) {
    final isMutualMatch = widget.notification.type == 'mutual_match';
    final isAccepted = widget.notification.status == 'accepted';
    final isRejected = widget.notification.status == 'rejected';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMutualMatch
              ? Colors.purple.withOpacity(0.3)
              : isAccepted
                  ? Colors.green.withOpacity(0.3)
                  : Colors.pink.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com avatar e nome
            Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.pink.withOpacity(0.1),
                      child: _isLoadingName
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _getInitials(),
                              style: const TextStyle(
                                color: Colors.pink,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                    // Ícone de coração
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.pink,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 12),

                // Nome
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$displayName, 25',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          // Badge de match
                          if (isMutualMatch || isAccepted || widget.notification.type == 'acceptance')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.purple.shade400,
                                    Colors.pink.shade400,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'MATCH!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Mensagem
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getMessageBackgroundColor(),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getMessage(),
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Tempo
            Text(
              _getTimeText(),
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 16),

            // Botões de ação
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  /// Obter iniciais do nome
  String _getInitials() {
    final name = displayName;

    if (name.trim().isEmpty || name == 'Usuário Anônimo') {
      return '?';
    }

    final parts = name.trim().split(' ');

    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }

    return '?';
  }

  /// Obter cor de fundo da mensagem
  Color _getMessageBackgroundColor() {
    if (widget.notification.type == 'mutual_match') {
      return Colors.purple.withOpacity(0.1);
    }
    if (widget.notification.type == 'acceptance') {
      return Colors.green.withOpacity(0.1);
    }
    if (widget.notification.status == 'accepted') {
      return Colors.green.withOpacity(0.1);
    }
    return Colors.pink.withOpacity(0.1);
  }

  /// Obter mensagem
  String _getMessage() {
    if (widget.notification.type == 'mutual_match') {
      return 'MATCH MÚTUO! Vocês dois demonstraram interesse! 🎉💕';
    }
    if (widget.notification.type == 'acceptance') {
      return '$displayName também tem interesse em você! 💕';
    }
    if (widget.notification.status == 'accepted') {
      return 'Você aceitou o interesse! Agora vocês podem conversar! 💕';
    }
    if (widget.notification.status == 'rejected') {
      return 'Você não demonstrou interesse neste perfil.';
    }
    return widget.notification.message ??
        'Tem interesse em conhecer seu perfil melhor';
  }

  /// Obter texto de tempo
  String _getTimeText() {
    if (widget.notification.dataCriacao == null) return '';

    final now = DateTime.now();
    final created = widget.notification.dataCriacao!.toDate();
    final difference = now.difference(created);

    if (difference.inDays > 0) {
      return 'há ${difference.inDays} ${difference.inDays == 1 ? "dia" : "dias"}';
    }
    if (difference.inHours > 0) {
      return 'há ${difference.inHours} ${difference.inHours == 1 ? "hora" : "horas"}';
    }
    if (difference.inMinutes > 0) {
      return 'há ${difference.inMinutes} ${difference.inMinutes == 1 ? "minuto" : "minutos"}';
    }
    return 'agora';
  }

  /// Construir botões de ação
  Widget _buildActionButtons() {
    final status = widget.notification.status;
    final type = widget.notification.type;

    // Match mútuo, aceitação ou aceito - botões de ver perfil e conversar
    if (type == 'mutual_match' || type == 'acceptance' || status == 'accepted') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _navigateToProfile,
              icon: const Icon(Icons.person),
              label: const Text('Ver Perfil'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                side: const BorderSide(color: Colors.blue),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _navigateToChat,
              icon: const Icon(Icons.chat),
              label: const Text('Conversar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    // Rejeitado - apenas ver perfil
    if (status == 'rejected') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _navigateToProfile,
              icon: const Icon(Icons.person),
              label: const Text('Ver Perfil'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey,
              ),
            ),
          ),
        ],
      );
    }

    // Pendente ou visualizado - botões de resposta
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _navigateToProfile,
            icon: const Icon(Icons.person),
            label: const Text('Ver Perfil'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
              side: const BorderSide(color: Colors.blue),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: _isResponding ? null : () => _respondToInterest(false),
            child: const Text('Não Tenho'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: _isResponding ? null : () => _respondToInterest(true),
            child: const Text('Também Tenho'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  /// Navegar para perfil
  void _navigateToProfile() {
    final fromUserId = widget.notification.fromUserId;

    if (fromUserId == null || fromUserId.isEmpty) {
      Get.snackbar('Erro', 'ID do usuário não encontrado');
      return;
    }

    print('🔍 [CARD] Navegando para perfil: $fromUserId');
    print('🔍 [CARD] Status da notificação: ${widget.notification.status}');

    // Navegar para EnhancedVitrineDisplayView com status de interesse
    Get.toNamed('/vitrine-display', arguments: {
      'userId': fromUserId,
      'isOwnProfile': false,
      'interestStatus': widget.notification.status, // Passar status para determinar botão
    });
  }

  /// Navegar para chat
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

      print('💬 [CARD] Navegando para match-chat: $chatId');

      // Navegar para o match-chat
      Get.toNamed('/match-chat', arguments: {
        'chatId': chatId,
        'otherUserId': otherUserId,
        'otherUserName': displayName,
        'matchDate': DateTime.now(), // Data do match
      });
    } catch (e) {
      print('❌ [CARD] Erro ao navegar para chat: $e');
      Get.snackbar('Erro', 'Não foi possível abrir o chat');
    }
  }

  /// Responder ao interesse
  Future<void> _respondToInterest(bool accept) async {
    if (_isResponding) return;

    setState(() {
      _isResponding = true;
    });

    try {
      final action = accept ? 'accepted' : 'rejected';

      print('💬 [CARD] Respondendo à notificação ${widget.notification.id} com ação: $action');

      await InterestNotificationRepository.respondToInterestNotification(
        widget.notification.id!,
        action,
      );

      Get.snackbar(
        accept ? 'Interesse Aceito!' : 'Interesse Rejeitado',
        accept
            ? 'Você aceitou o interesse de $displayName'
            : 'Você rejeitou o interesse',
        backgroundColor: accept ? Colors.green : Colors.grey.shade600,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );

      // Callback para recarregar
      widget.onResponse?.call();
    } catch (e) {
      print('❌ [CARD] Erro ao responder interesse: $e');
      Get.snackbar(
        'Erro',
        'Erro ao responder interesse. Tente novamente.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResponding = false;
        });
      }
    }
  }
}
