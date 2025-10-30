import 'package:cloud_firestore/cloud_firestore.dart';

/// Serviço para sanitização robusta de dados Timestamp
class TimestampSanitizer {
  /// Sanitiza um valor para Timestamp, tratando nulls e tipos inválidos
  static Timestamp sanitizeTimestamp(dynamic value) {
    if (value == null) {
      print('⚠️ Timestamp null encontrado, usando timestamp atual');
      return Timestamp.now();
    }

    if (value is Timestamp) {
      return value;
    }

    if (value is DateTime) {
      return Timestamp.fromDate(value);
    }

    if (value is String) {
      try {
        final dateTime = DateTime.parse(value);
        return Timestamp.fromDate(dateTime);
      } catch (e) {
        print('⚠️ Erro ao converter string para Timestamp: $e');
        return Timestamp.now();
      }
    }

    if (value is int) {
      try {
        // Assumir que é timestamp em milliseconds
        final dateTime = DateTime.fromMillisecondsSinceEpoch(value);
        return Timestamp.fromDate(dateTime);
      } catch (e) {
        print('⚠️ Erro ao converter int para Timestamp: $e');
        return Timestamp.now();
      }
    }

    print('⚠️ Tipo de Timestamp não reconhecido: ${value.runtimeType}');
    return Timestamp.now();
  }

  /// Sanitiza dados de chat, garantindo que todos os campos estejam corretos
  static Map<String, dynamic> sanitizeChatData(Map<String, dynamic> data) {
    try {
      return {
        'id': data['id'] ?? '',
        'user1Id': data['user1Id'] ?? '',
        'user2Id': data['user2Id'] ?? '',
        'createdAt': sanitizeTimestamp(data['createdAt']),
        'expiresAt': sanitizeTimestamp(data['expiresAt']),
        'lastMessageAt': data['lastMessageAt'] != null
            ? sanitizeTimestamp(data['lastMessageAt'])
            : null,
        'lastMessage': data['lastMessage'] ?? '',
        'isExpired': data['isExpired'] ?? false,
        'unreadCount': _sanitizeUnreadCount(data['unreadCount']),
      };
    } catch (e) {
      print('❌ Erro ao sanitizar dados do chat: $e');
      // Retornar dados mínimos seguros
      return {
        'id': data['id'] ?? '',
        'user1Id': data['user1Id'] ?? '',
        'user2Id': data['user2Id'] ?? '',
        'createdAt': Timestamp.now(),
        'expiresAt': Timestamp.fromDate(DateTime.now().add(Duration(days: 30))),
        'lastMessageAt': null,
        'lastMessage': '',
        'isExpired': false,
        'unreadCount': {},
      };
    }
  }

  /// Sanitiza dados de mensagem
  static Map<String, dynamic> sanitizeMessageData(Map<String, dynamic> data) {
    try {
      return {
        'id': data['id'] ?? '',
        'chatId': data['chatId'] ?? '',
        'senderId': data['senderId'] ?? '',
        'senderName': data['senderName'] ?? 'Usuário',
        'message': data['message'] ?? '',
        'timestamp': data['timestamp'] != null
            ? sanitizeTimestamp(data['timestamp'])
            : Timestamp.now(),
        'isRead': data['isRead'] ?? false,
      };
    } catch (e) {
      print('❌ Erro ao sanitizar dados da mensagem: $e');
      // Retornar dados mínimos seguros
      return {
        'id': data['id'] ?? '',
        'chatId': data['chatId'] ?? '',
        'senderId': data['senderId'] ?? '',
        'senderName': 'Usuário',
        'message': data['message'] ?? '',
        'timestamp': Timestamp.now(),
        'isRead': false,
      };
    }
  }

  /// Sanitiza contador de mensagens não lidas
  static Map<String, int> _sanitizeUnreadCount(dynamic value) {
    if (value == null) return {};

    if (value is Map<String, dynamic>) {
      final result = <String, int>{};
      value.forEach((key, val) {
        if (key is String && val is int) {
          result[key] = val;
        } else if (key is String && val is num) {
          result[key] = val.toInt();
        }
      });
      return result;
    }

    return {};
  }

  /// Sanitiza string, garantindo que não seja null
  static String sanitizeString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    return value.toString();
  }

  /// Sanitiza boolean, garantindo que não seja null
  static bool sanitizeBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    if (value is num) {
      return value != 0;
    }
    return defaultValue;
  }

  /// Sanitiza número inteiro
  static int sanitizeInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return defaultValue;
      }
    }
    return defaultValue;
  }

  /// Verifica se um timestamp é válido (não muito antigo nem muito futuro)
  static bool isValidTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final now = DateTime.now();

    // Não pode ser mais de 10 anos no passado
    final tenYearsAgo = now.subtract(Duration(days: 365 * 10));

    // Não pode ser mais de 1 ano no futuro
    final oneYearFromNow = now.add(Duration(days: 365));

    return dateTime.isAfter(tenYearsAgo) && dateTime.isBefore(oneYearFromNow);
  }

  /// Corrige timestamp inválido
  static Timestamp correctInvalidTimestamp(Timestamp timestamp) {
    if (isValidTimestamp(timestamp)) {
      return timestamp;
    }

    print('⚠️ Timestamp inválido detectado, corrigindo...');
    return Timestamp.now();
  }
}
