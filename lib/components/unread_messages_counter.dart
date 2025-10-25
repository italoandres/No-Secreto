import 'package:flutter/material.dart';
import '../services/message_read_status_service.dart';
import '../utils/enhanced_logger.dart';

/// Widget para mostrar contador de mensagens não lidas em tempo real
class UnreadMessagesCounter extends StatelessWidget {
  final String chatId;
  final String userId;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;
  final EdgeInsets? padding;
  final bool showZero;

  const UnreadMessagesCounter({
    super.key,
    required this.chatId,
    required this.userId,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.padding,
    this.showZero = false,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: MessageReadStatusService.watchUnreadCount(chatId, userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          EnhancedLogger.error(
              'Erro no stream de mensagens não lidas: ${snapshot.error}',
              tag: 'UNREAD_COUNTER');
          return const SizedBox.shrink();
        }

        final unreadCount = snapshot.data ?? 0;

        if (unreadCount == 0 && !showZero) {
          return const SizedBox.shrink();
        }

        return Container(
          padding:
              padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          constraints: const BoxConstraints(
            minWidth: 20,
            minHeight: 20,
          ),
          child: Text(
            unreadCount > 99 ? '99+' : unreadCount.toString(),
            style: TextStyle(
              color: textColor ?? Colors.white,
              fontSize: fontSize ?? 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }
}

/// Widget compacto para usar em AppBars
class CompactUnreadCounter extends StatelessWidget {
  final String chatId;
  final String userId;

  const CompactUnreadCounter({
    super.key,
    required this.chatId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return UnreadMessagesCounter(
      chatId: chatId,
      userId: userId,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 10,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    );
  }
}

/// Widget para mostrar badge de mensagens não lidas sobre um ícone
class UnreadBadge extends StatelessWidget {
  final String chatId;
  final String userId;
  final Widget child;
  final Alignment alignment;

  const UnreadBadge({
    super.key,
    required this.chatId,
    required this.userId,
    required this.child,
    this.alignment = Alignment.topRight,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: alignment == Alignment.topRight || alignment == Alignment.topLeft
              ? -4
              : null,
          bottom: alignment == Alignment.bottomRight ||
                  alignment == Alignment.bottomLeft
              ? -4
              : null,
          right: alignment == Alignment.topRight ||
                  alignment == Alignment.bottomRight
              ? -4
              : null,
          left: alignment == Alignment.topLeft ||
                  alignment == Alignment.bottomLeft
              ? -4
              : null,
          child: StreamBuilder<int>(
            stream: MessageReadStatusService.watchUnreadCount(chatId, userId),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;

              if (unreadCount == 0) {
                return const SizedBox.shrink();
              }

              return Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  unreadCount > 9 ? '9+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Widget para mostrar estatísticas detalhadas de leitura
class ReadStatsWidget extends StatelessWidget {
  final String chatId;
  final bool showPercentage;

  const ReadStatsWidget({
    super.key,
    required this.chatId,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: MessageReadStatusService.getChatReadStats(chatId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(
            'Erro ao carregar estatísticas',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          );
        }

        if (!snapshot.hasData) {
          return const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        final stats = snapshot.data!;
        final totalMessages = stats['totalMessages'] as int;
        final readMessages = stats['readMessages'] as int;
        final readPercentage = stats['readPercentage'] as int;

        if (totalMessages == 0) {
          return Text(
            'Nenhuma mensagem',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$readMessages de $totalMessages mensagens lidas',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
              ),
            ),
            if (showPercentage) ...[
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: readPercentage / 100,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  readPercentage > 80
                      ? Colors.green
                      : readPercentage > 50
                          ? Colors.orange
                          : Colors.red,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$readPercentage% lidas',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 10,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
