import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:whatsapp_chat/models/notification_category.dart';
import 'package:whatsapp_chat/models/notification_model.dart';
import 'package:whatsapp_chat/models/interest_notification_model.dart';

/// Modelo wrapper que unifica diferentes tipos de notificações
/// em uma estrutura comum para o sistema unificado
class UnifiedNotificationModel {
  /// ID único da notificação
  final String id;
  
  /// Categoria da notificação (stories, interest, system)
  final NotificationCategory category;
  
  /// Dados originais da notificação (pode ser NotificationModel, InterestNotificationModel ou Map)
  final dynamic data;
  
  /// Timestamp da notificação
  final DateTime timestamp;
  
  /// Se a notificação foi lida
  final bool isRead;
  
  /// Tipo específico da notificação (like, comment, mention, interest, certification_approved, etc)
  final String? type;

  UnifiedNotificationModel({
    required this.id,
    required this.category,
    required this.data,
    required this.timestamp,
    required this.isRead,
    this.type,
  });

  /// Factory para criar a partir de NotificationModel (Stories)
  factory UnifiedNotificationModel.fromStory(NotificationModel notification) {
    return UnifiedNotificationModel(
      id: notification.id,
      category: NotificationCategory.stories,
      data: notification,
      timestamp: notification.createdAt.toDate(),
      isRead: notification.isRead,
      type: notification.type,
    );
  }

  /// Factory para criar a partir de InterestNotificationModel
  factory UnifiedNotificationModel.fromInterest(InterestNotificationModel notification) {
    return UnifiedNotificationModel(
      id: notification.id!,
      category: NotificationCategory.interest,
      data: notification,
      timestamp: notification.dataCriacao!.toDate(),
      isRead: !notification.isPending, // Se não está pendente, foi lida
      type: notification.type,
    );
  }

  /// Factory para criar a partir de Map (System notifications)
  factory UnifiedNotificationModel.fromSystem(Map<String, dynamic> notification) {
    final createdAt = notification['createdAt'];
    DateTime timestamp;
    
    if (createdAt is Timestamp) {
      timestamp = createdAt.toDate();
    } else if (createdAt is String) {
      timestamp = DateTime.parse(createdAt);
    } else {
      timestamp = DateTime.now();
    }

    return UnifiedNotificationModel(
      id: notification['id'] ?? '',
      category: NotificationCategory.system,
      data: notification,
      timestamp: timestamp,
      isRead: notification['read'] ?? false,
      type: notification['type'],
    );
  }

  /// Converte para NotificationModel se for do tipo stories
  NotificationModel? asStoryNotification() {
    if (category == NotificationCategory.stories && data is NotificationModel) {
      return data as NotificationModel;
    }
    return null;
  }

  /// Converte para InterestNotificationModel se for do tipo interest
  InterestNotificationModel? asInterestNotification() {
    if (category == NotificationCategory.interest && data is InterestNotificationModel) {
      return data as InterestNotificationModel;
    }
    return null;
  }

  /// Converte para Map se for do tipo system
  Map<String, dynamic>? asSystemNotification() {
    if (category == NotificationCategory.system && data is Map<String, dynamic>) {
      return data as Map<String, dynamic>;
    }
    return null;
  }

  /// Verifica se é uma notificação de story
  bool get isStoryNotification => category == NotificationCategory.stories;

  /// Verifica se é uma notificação de interesse
  bool get isInterestNotification => category == NotificationCategory.interest;

  /// Verifica se é uma notificação de sistema
  bool get isSystemNotification => category == NotificationCategory.system;

  /// Verifica se é uma menção (@) em story
  bool get isMention => type == 'mention';

  /// Verifica se é uma curtida
  bool get isLike => type == 'like';

  /// Verifica se é um comentário
  bool get isComment => type == 'comment';

  /// Verifica se é uma resposta a comentário
  bool get isReply => type == 'reply';

  /// Verifica se é uma curtida em comentário
  bool get isCommentLike => type == 'comment_like';

  /// Verifica se é uma notificação de certificação
  bool get isCertification => 
      type == 'certification_approved' || type == 'certification_rejected';

  /// Verifica se é um match mútuo
  bool get isMutualMatch => type == 'mutual_match';

  /// Obtém o nome do usuário que gerou a notificação
  String? get fromUserName {
    if (data is NotificationModel) {
      return (data as NotificationModel).userName;
    } else if (data is InterestNotificationModel) {
      return (data as InterestNotificationModel).fromUserName;
    } else if (data is Map<String, dynamic>) {
      return (data as Map<String, dynamic>)['fromUserName'] ?? 
             (data as Map<String, dynamic>)['title'];
    }
    return null;
  }

  /// Obtém a mensagem da notificação
  String? get message {
    if (data is NotificationModel) {
      return (data as NotificationModel).message;
    } else if (data is InterestNotificationModel) {
      return (data as InterestNotificationModel).message;
    } else if (data is Map<String, dynamic>) {
      return (data as Map<String, dynamic>)['message'] ?? 
             (data as Map<String, dynamic>)['body'];
    }
    return null;
  }

  /// Obtém a foto do usuário que gerou a notificação
  String? get fromUserPhoto {
    if (data is NotificationModel) {
      return (data as NotificationModel).userPhoto;
    } else if (data is InterestNotificationModel) {
      // InterestNotificationModel não tem foto, precisaria buscar
      return null;
    } else if (data is Map<String, dynamic>) {
      return (data as Map<String, dynamic>)['fromUserPhoto'];
    }
    return null;
  }

  /// Compara notificações por timestamp (mais recente primeiro)
  int compareTo(UnifiedNotificationModel other) {
    return other.timestamp.compareTo(timestamp);
  }

  @override
  String toString() {
    return 'UnifiedNotificationModel(id: $id, category: $category, type: $type, isRead: $isRead, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UnifiedNotificationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
