import 'package:flutter/material.dart';
import '../models/accepted_match_model.dart';
import 'unread_messages_counter.dart';

/// Card que representa um match aceito na lista de chats
/// 
/// Funcionalidades:
/// - Exibe foto, nome e data do match
/// - Mostra indicador de mensagens não lidas
/// - Indica status de expiração do chat
/// - Animações de tap e estados visuais
class MatchChatCard extends StatefulWidget {
  final AcceptedMatchModel match;
  final VoidCallback onTap;
  final bool showOnlineStatus;
  final EdgeInsets? margin;

  const MatchChatCard({
    super.key,
    required this.match,
    required this.onTap,
    this.showOnlineStatus = false,
    this.margin,
  });

  @override
  State<MatchChatCard> createState() => _MatchChatCardState();
}

class _MatchChatCardState extends State<MatchChatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _handleTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpired = widget.match.chatExpired;
    final hasUnreadMessages = widget.match.unreadMessages > 0;
    
    // Debug: Verificar dados do match
    debugPrint('🎨 [MATCH_CARD] Exibindo: ${widget.match.otherUserName}');
    debugPrint('   nameWithAge: ${widget.match.nameWithAge}');
    debugPrint('   formattedLocation: ${widget.match.formattedLocation}');
    debugPrint('   otherUserAge: ${widget.match.otherUserAge}');
    debugPrint('   otherUserCity: ${widget.match.otherUserCity}');
    
    return Container(
      margin: widget.margin ?? const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTapDown: _handleTapDown,
              onTapUp: _handleTapUp,
              onTapCancel: _handleTapCancel,
              onTap: widget.onTap,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: hasUnreadMessages
                      ? Border.all(
                          color: const Color(0xFFFF6B9D).withOpacity(0.3),
                          width: 2,
                        )
                      : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Foto do usuário com indicador online
                      _buildUserAvatar(),
                      const SizedBox(width: 16),
                      
                      // Informações do match
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildUserName(),
                            if (widget.match.formattedLocation.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              _buildLocation(),
                            ],
                            const SizedBox(height: 4),
                            _buildMatchInfo(),
                            if (isExpired) ...[
                              const SizedBox(height: 4),
                              _buildExpirationWarning(),
                            ],
                          ],
                        ),
                      ),
                      
                      // Indicadores laterais
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildTimeIndicator(),
                          const SizedBox(height: 8),
                          _buildUnreadBadge(),
                          if (!isExpired)
                            _buildChatIcon(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserAvatar() {
    final hasPhoto = widget.match.otherUserPhoto != null;
    
    return Stack(
      children: [
        Hero(
          tag: 'chat_profile_${widget.match.chatId}_${widget.match.otherUserId}',
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: hasPhoto
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFFFF6B9D), Color(0xFFFFA8A8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B9D).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: hasPhoto
                ? ClipOval(
                    child: Image.network(
                      widget.match.otherUserPhoto!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDefaultAvatar();
                      },
                    ),
                  )
                : _buildDefaultAvatar(),
          ),
        ),
        
        // Indicador online (se habilitado)
        if (widget.showOnlineStatus)
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFFFF6B9D), Color(0xFFFFA8A8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(
        Icons.favorite,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  Widget _buildUserName() {
    final theme = Theme.of(context);
    final isExpired = widget.match.chatExpired;
    
    return Text(
      widget.match.nameWithAge,  // MUDADO: Agora exibe nome com idade
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: isExpired
            ? theme.textTheme.bodyMedium?.color?.withOpacity(0.6)
            : null,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildLocation() {
    final theme = Theme.of(context);
    final isExpired = widget.match.chatExpired;
    
    return Row(
      children: [
        Icon(
          Icons.location_on,
          size: 12,
          color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: Text(
            widget.match.formattedLocation,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: isExpired
                  ? theme.textTheme.bodySmall?.color?.withOpacity(0.4)
                  : theme.textTheme.bodySmall?.color?.withOpacity(0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMatchInfo() {
    final theme = Theme.of(context);
    final isExpired = widget.match.chatExpired;
    
    return Text(
      'Match ${widget.match.formattedMatchDate}',
      style: theme.textTheme.bodySmall?.copyWith(
        color: isExpired
            ? theme.textTheme.bodySmall?.color?.withOpacity(0.5)
            : theme.textTheme.bodySmall?.color?.withOpacity(0.7),
      ),
    );
  }

  Widget _buildExpirationWarning() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule,
            size: 12,
            color: Colors.orange.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            'Chat Expirado',
            style: TextStyle(
              fontSize: 10,
              color: Colors.orange.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeIndicator() {
    final theme = Theme.of(context);
    final daysRemaining = widget.match.daysRemaining;
    final isExpired = widget.match.chatExpired;
    
    if (isExpired) {
      return Icon(
        Icons.block,
        size: 16,
        color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
      );
    }
    
    Color timeColor;
    if (daysRemaining <= 1) {
      timeColor = Colors.red;
    } else if (daysRemaining <= 7) {
      timeColor = Colors.orange;
    } else {
      timeColor = Colors.green;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: timeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${daysRemaining}d',
        style: TextStyle(
          fontSize: 10,
          color: timeColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildUnreadBadge() {
    return UnreadMessagesCounter(
      chatId: widget.match.chatId,
      userId: 'current_user_id', // TODO: Obter userId real
      backgroundColor: const Color(0xFFFF6B9D),
      textColor: Colors.white,
      fontSize: 10,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    );
  }

  Widget _buildChatIcon() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B9D).withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.chat_bubble_outline,
        size: 16,
        color: const Color(0xFFFF6B9D),
      ),
    );
  }
}

/// Variação do card para estado de loading
class MatchChatCardSkeleton extends StatelessWidget {
  final EdgeInsets? margin;

  const MatchChatCardSkeleton({
    super.key,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar skeleton
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              
              // Content skeleton
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Right side skeleton
              Column(
                children: [
                  Container(
                    height: 12,
                    width: 30,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}