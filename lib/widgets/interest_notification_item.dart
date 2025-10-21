import 'package:flutter/material.dart';
import 'package:whatsapp_chat/models/interest_notification_model.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Widget para exibir notificação de interesse/match
/// Suporta: demonstrações de interesse, aceitações, matches mútuos
/// Exibe notificação misteriosa que leva para Vitrine de Propósito
class InterestNotificationItem extends StatelessWidget {
  final InterestNotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final Function(bool)? onRespond; // true = aceitar, false = rejeitar

  const InterestNotificationItem({
    Key? key,
    required this.notification,
    required this.onTap,
    this.onDelete,
    this.onRespond,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMutualMatch = notification.type == 'mutual_match';
    final isPending = notification.isPending;

    return Card(
      elevation: isPending ? 4 : (isMutualMatch ? 3 : 1),
      color: isPending
          ? Colors.purple.shade50 // Cor misteriosa para pendente
          : (isMutualMatch ? Colors.pink.shade50 : Colors.grey.shade50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isPending
            ? BorderSide(color: Colors.purple.shade300, width: 2)
            : (isMutualMatch 
                ? BorderSide(color: Colors.pink.shade300, width: 2)
                : BorderSide.none),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar misterioso (interrogação)
                  _buildMysteriousAvatar(),
                  const SizedBox(width: 12),
                  
                  // Conteúdo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título misterioso
                        _buildMysteriousHeader(),
                        const SizedBox(height: 8),
                        
                        // Mensagem misteriosa
                        _buildMysteriousMessage(),
                        
                        const SizedBox(height: 4),
                        
                        // Timestamp
                        _buildTimestamp(),
                      ],
                    ),
                  ),
                  
                  // Ícone misterioso
                  _buildMysteriousIcon(),
                  
                  // Botão de deletar (se fornecido)
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: onDelete,
                      color: Colors.grey.shade400,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              
              // Botão misterioso para ir para Vitrine
              const SizedBox(height: 16),
              _buildMysteriousButton(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói avatar misterioso (interrogação)
  Widget _buildMysteriousAvatar() {
    return Stack(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.purple.shade300,
                Colors.pink.shade300,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.shade200,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              '?',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        
        // Efeito de brilho
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.star,
              size: 12,
              color: Colors.amber.shade400,
            ),
          ),
        ),
      ],
    );
  }

  /// Constrói header misterioso
  Widget _buildMysteriousHeader() {
    return Row(
      children: [
        Icon(
          Icons.auto_awesome,
          size: 20,
          color: Colors.purple.shade600,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Alguém Especial',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade700,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.purple.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.visibility_off,
                size: 12,
                color: Colors.purple.shade700,
              ),
              const SizedBox(width: 4),
              Text(
                'MISTÉRIO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Constrói mensagem misteriosa
  Widget _buildMysteriousMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.favorite,
            size: 16,
            color: Colors.purple.shade400,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Tem interesse em conhecer você melhor...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.purple.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói timestamp
  Widget _buildTimestamp() {
    if (notification.dataCriacao == null) return const SizedBox.shrink();
    
    final timestamp = notification.dataCriacao!.toDate();
    final timeAgo = timeago.format(timestamp, locale: 'pt_BR');
    
    return Text(
      timeAgo,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey.shade500,
      ),
    );
  }

  /// Constrói ícone misterioso
  Widget _buildMysteriousIcon() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade200, Colors.pink.shade200],
        ),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.help_outline,
        size: 20,
        color: Colors.white,
      ),
    );
  }

  /// Constrói botão misterioso para ir para Vitrine de Propósito
  Widget _buildMysteriousButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade400, Colors.pink.shade400],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.shade200,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.storefront, size: 20),
        label: const Text(
          'Entre em Vitrine de Propósito para Saber',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
