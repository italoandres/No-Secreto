import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:whatsapp_chat/utils/debug_utils.dart';

/// Serviço responsável por gerenciar a expiração automática dos chats de matches
///
/// Funcionalidades:
/// - Calcular dias restantes para expiração
/// - Verificar se chat está expirado
/// - Bloquear operações em chats expirados
/// - Manter histórico após expiração
class ChatExpirationService {
  static const int _chatDurationDays = 30;

  /// Calcula quantos dias restam até a expiração do chat
  ///
  /// [createdAt] Data de criação do chat
  /// Retorna número de dias restantes (0 se expirado)
  static int getDaysRemaining(DateTime createdAt) {
    final now = DateTime.now();
    final expirationDate =
        createdAt.add(const Duration(days: _chatDurationDays));
    final difference = expirationDate.difference(now);

    return difference.inDays.clamp(0, _chatDurationDays);
  }

  /// Verifica se o chat está expirado
  ///
  /// [createdAt] Data de criação do chat
  /// Retorna true se o chat expirou
  static bool isChatExpired(DateTime createdAt) {
    return getDaysRemaining(createdAt) == 0;
  }

  /// Calcula a data de expiração do chat
  ///
  /// [createdAt] Data de criação do chat
  /// Retorna a data exata de expiração
  static DateTime getExpirationDate(DateTime createdAt) {
    return createdAt.add(const Duration(days: _chatDurationDays));
  }

  /// Calcula o percentual de tempo restante (0-100)
  ///
  /// [createdAt] Data de criação do chat
  /// Retorna percentual de 0 a 100
  static double getTimeRemainingPercentage(DateTime createdAt) {
    final totalDuration = const Duration(days: _chatDurationDays);
    final elapsed = DateTime.now().difference(createdAt);

    if (elapsed >= totalDuration) return 0.0;

    final remaining = totalDuration - elapsed;
    return (remaining.inMilliseconds / totalDuration.inMilliseconds * 100)
        .clamp(0.0, 100.0);
  }

  /// Retorna o status de urgência baseado no tempo restante
  ///
  /// [createdAt] Data de criação do chat
  /// Retorna enum indicando o nível de urgência
  static ChatExpirationStatus getExpirationStatus(DateTime createdAt) {
    final daysRemaining = getDaysRemaining(createdAt);

    if (daysRemaining == 0) {
      return ChatExpirationStatus.expired;
    } else if (daysRemaining <= 3) {
      return ChatExpirationStatus.critical;
    } else if (daysRemaining <= 7) {
      return ChatExpirationStatus.warning;
    } else {
      return ChatExpirationStatus.normal;
    }
  }

  /// Verifica se é possível enviar mensagens no chat
  ///
  /// [createdAt] Data de criação do chat
  /// Retorna true se ainda é possível enviar mensagens
  static bool canSendMessages(DateTime createdAt) {
    return !isChatExpired(createdAt);
  }

  /// Formata o tempo restante em texto amigável
  ///
  /// [createdAt] Data de criação do chat
  /// Retorna string formatada com tempo restante
  static String formatTimeRemaining(DateTime createdAt) {
    final daysRemaining = getDaysRemaining(createdAt);

    if (daysRemaining == 0) {
      return 'Chat expirado';
    } else if (daysRemaining == 1) {
      return 'Expira em 1 dia';
    } else {
      return 'Expira em $daysRemaining dias';
    }
  }

  /// Retorna mensagem motivacional baseada no tempo restante
  ///
  /// [createdAt] Data de criação do chat
  /// Retorna mensagem apropriada para o status
  static String getMotivationalMessage(DateTime createdAt) {
    final status = getExpirationStatus(createdAt);

    switch (status) {
      case ChatExpirationStatus.expired:
        return 'O tempo para conversar acabou, mas há muitas outras pessoas esperando para conhecer você! 💕';

      case ChatExpirationStatus.critical:
        return 'Últimos dias para conversar! Que tal enviar uma mensagem especial? ⏰💕';

      case ChatExpirationStatus.warning:
        return 'O tempo está passando! Continue a conversa e conheça melhor essa pessoa 💬✨';

      case ChatExpirationStatus.normal:
        return 'Vocês têm bastante tempo para se conhecerem! Aproveitem cada momento 🌟';
    }
  }

  /// Busca e marca chats expirados no Firebase
  ///
  /// Este método deve ser chamado periodicamente para manter
  /// o banco de dados atualizado com o status de expiração
  static Future<List<String>> markExpiredChats() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final now = DateTime.now();
      final expiredDate = now.subtract(const Duration(days: _chatDurationDays));

      // Buscar chats que expiraram mas ainda não foram marcados
      final query = await firestore
          .collection('match_chats')
          .where('createdAt', isLessThan: Timestamp.fromDate(expiredDate))
          .where('isExpired', isEqualTo: false)
          .get();

      final expiredChatIds = <String>[];
      final batch = firestore.batch();

      for (final doc in query.docs) {
        batch.update(doc.reference, {
          'isExpired': true,
          'expiredAt': Timestamp.fromDate(now),
        });
        expiredChatIds.add(doc.id);
      }

      if (expiredChatIds.isNotEmpty) {
        await batch.commit();
      }

      return expiredChatIds;
    } catch (e) {
      // Log error for debugging - in production, use proper logging service
      safePrint('ChatExpirationService: Erro ao marcar chats expirados: $e');
      return [];
    }
  }

  /// Limpa mensagens antigas de chats expirados (opcional)
  ///
  /// [daysAfterExpiration] Quantos dias após expiração manter mensagens
  /// Retorna número de mensagens removidas
  static Future<int> cleanupExpiredChatMessages(
      {int daysAfterExpiration = 7}) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final cleanupDate = DateTime.now().subtract(
        Duration(days: _chatDurationDays + daysAfterExpiration),
      );

      // Buscar mensagens muito antigas
      final query = await firestore
          .collection('chat_messages')
          .where('createdAt', isLessThan: Timestamp.fromDate(cleanupDate))
          .limit(100) // Processar em lotes para evitar timeout
          .get();

      if (query.docs.isEmpty) return 0;

      final batch = firestore.batch();
      for (final doc in query.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      return query.docs.length;
    } catch (e) {
      // Log error for debugging - in production, use proper logging service
      safePrint('ChatExpirationService: Erro ao limpar mensagens antigas: $e');
      return 0;
    }
  }

  /// Cria um timer para verificação periódica de chats expirados
  ///
  /// [intervalHours] Intervalo em horas para verificação
  /// Retorna Timer que pode ser cancelado
  static Timer createExpirationCheckTimer({int intervalHours = 6}) {
    return Timer.periodic(Duration(hours: intervalHours), (timer) async {
      final expiredChats = await markExpiredChats();
      if (expiredChats.isNotEmpty) {
        safePrint(
            'ChatExpirationService: Marcados ${expiredChats.length} chats como expirados');
      }
    });
  }
}

/// Enum para representar o status de expiração do chat
enum ChatExpirationStatus {
  /// Chat funcionando normalmente (mais de 7 dias restantes)
  normal,

  /// Aviso de expiração próxima (3-7 dias restantes)
  warning,

  /// Crítico - expira em breve (1-3 dias restantes)
  critical,

  /// Chat expirado (0 dias restantes)
  expired,
}

/// Extensão para adicionar propriedades úteis ao enum
extension ChatExpirationStatusExtension on ChatExpirationStatus {
  /// Cor associada ao status
  String get colorHex {
    switch (this) {
      case ChatExpirationStatus.normal:
        return '#4CAF50'; // Verde
      case ChatExpirationStatus.warning:
        return '#FF9800'; // Laranja
      case ChatExpirationStatus.critical:
        return '#F44336'; // Vermelho
      case ChatExpirationStatus.expired:
        return '#9E9E9E'; // Cinza
    }
  }

  /// Ícone associado ao status
  String get iconName {
    switch (this) {
      case ChatExpirationStatus.normal:
        return 'check_circle';
      case ChatExpirationStatus.warning:
        return 'warning';
      case ChatExpirationStatus.critical:
        return 'error';
      case ChatExpirationStatus.expired:
        return 'block';
    }
  }

  /// Prioridade do status (maior número = mais urgente)
  int get priority {
    switch (this) {
      case ChatExpirationStatus.normal:
        return 1;
      case ChatExpirationStatus.warning:
        return 2;
      case ChatExpirationStatus.critical:
        return 3;
      case ChatExpirationStatus.expired:
        return 4;
    }
  }
}
