import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Serviço compartilhado para gerenciar status online em chats
/// Usado por ChatView e RomanticMatchChatView
class ChatStatusService {
  /// Retorna o texto de "última vez online" baseado no timestamp
  static String getLastSeenText(Timestamp? lastSeen) {
    if (lastSeen == null) return 'Offline';

    final now = DateTime.now();
    final lastSeenDate = lastSeen.toDate();
    final difference = now.difference(lastSeenDate);

    // Online se visto nos últimos 2 minutos
    if (difference.inMinutes < 2) {
      return 'Online';
    }

    // Minutos atrás
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}min atrás';
    }

    // Horas atrás
    if (difference.inHours < 24) {
      return '${difference.inHours}h atrás';
    }

    // Dias atrás
    if (difference.inDays < 7) {
      return '${difference.inDays}d atrás';
    }

    // Mais de 7 dias
    return 'Offline';
  }

  /// Retorna a cor do status baseado no timestamp
  static Color getStatusColor(Timestamp? lastSeen) {
    if (lastSeen == null) return Colors.grey;

    final now = DateTime.now();
    final lastSeenDate = lastSeen.toDate();
    final difference = now.difference(lastSeenDate);

    // Verde se online (menos de 2 minutos)
    if (difference.inMinutes < 2) {
      return Colors.green;
    }

    // Amarelo se visto recentemente (menos de 1 hora)
    if (difference.inHours < 1) {
      return Colors.orange;
    }

    // Cinza se offline
    return Colors.grey;
  }

  /// Verifica se o usuário está online
  static bool isOnline(Timestamp? lastSeen) {
    if (lastSeen == null) return false;

    final now = DateTime.now();
    final lastSeenDate = lastSeen.toDate();
    final difference = now.difference(lastSeenDate);

    return difference.inMinutes < 2;
  }

  /// Constrói o widget de status completo (bolinha + texto)
  static Widget buildStatusWidget(Timestamp? lastSeen, {double fontSize = 12}) {
    final statusText = getLastSeenText(lastSeen);
    final statusColor = getStatusColor(lastSeen);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bolinha de status
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        // Texto de status
        Text(
          statusText,
          style: TextStyle(
            fontSize: fontSize,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  /// Constrói apenas a bolinha de status (para usar em AppBar)
  static Widget buildStatusDot(Timestamp? lastSeen, {double size = 10}) {
    final statusColor = getStatusColor(lastSeen);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: statusColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
      ),
    );
  }

  /// Constrói o texto de status sem a bolinha
  static Widget buildStatusText(
    Timestamp? lastSeen, {
    double fontSize = 12,
    Color? textColor,
  }) {
    final statusText = getLastSeenText(lastSeen);

    return Text(
      statusText,
      style: TextStyle(
        fontSize: fontSize,
        color: textColor ?? Colors.grey.shade600,
      ),
    );
  }
}
