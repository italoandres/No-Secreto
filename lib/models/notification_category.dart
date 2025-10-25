import 'package:flutter/material.dart';

/// Enum que define as 3 categorias de notificações do sistema unificado
enum NotificationCategory {
  /// Notificações de stories (curtidas, comentários, menções, respostas)
  stories,

  /// Notificações de interesse e matches mútuos
  interest,

  /// Notificações do sistema (certificação, atualizações, avisos)
  system;

  /// Nome de exibição da categoria
  String get displayName {
    switch (this) {
      case NotificationCategory.stories:
        return 'Stories';
      case NotificationCategory.interest:
        return 'Interesse';
      case NotificationCategory.system:
        return 'Outros';
    }
  }

  /// Ícone representativo da categoria
  IconData get icon {
    switch (this) {
      case NotificationCategory.stories:
        return Icons.auto_stories;
      case NotificationCategory.interest:
        return Icons.favorite;
      case NotificationCategory.system:
        return Icons.notifications_active;
    }
  }

  /// Cor primária da categoria
  Color get color {
    switch (this) {
      case NotificationCategory.stories:
        return Colors.amber.shade700;
      case NotificationCategory.interest:
        return Colors.pink.shade400;
      case NotificationCategory.system:
        return Colors.blue.shade600;
    }
  }

  /// Cor de fundo quando a categoria está ativa
  Color get backgroundColor {
    switch (this) {
      case NotificationCategory.stories:
        return Colors.amber.shade50;
      case NotificationCategory.interest:
        return Colors.pink.shade50;
      case NotificationCategory.system:
        return Colors.blue.shade50;
    }
  }

  /// Emoji representativo da categoria
  String get emoji {
    switch (this) {
      case NotificationCategory.stories:
        return '📖';
      case NotificationCategory.interest:
        return '💕';
      case NotificationCategory.system:
        return '🔔';
    }
  }

  /// Descrição da categoria para acessibilidade
  String get semanticLabel {
    switch (this) {
      case NotificationCategory.stories:
        return 'Notificações de Stories - Curtidas, comentários e menções';
      case NotificationCategory.interest:
        return 'Notificações de Interesse - Demonstrações de interesse e matches';
      case NotificationCategory.system:
        return 'Outras Notificações - Certificação, avisos e atualizações';
    }
  }

  /// Mensagem de estado vazio para a categoria
  String get emptyStateMessage {
    switch (this) {
      case NotificationCategory.stories:
        return 'Você receberá notificações quando\nalguém interagir com seus stories';
      case NotificationCategory.interest:
        return 'Você receberá notificações quando\nalguém demonstrar interesse em você';
      case NotificationCategory.system:
        return 'Você receberá avisos importantes,\ncertificação e atualizações do app';
    }
  }

  /// Título do estado vazio para a categoria
  String get emptyStateTitle {
    switch (this) {
      case NotificationCategory.stories:
        return 'Nenhuma notificação de stories';
      case NotificationCategory.interest:
        return 'Nenhuma notificação de interesse';
      case NotificationCategory.system:
        return 'Nenhuma outra notificação';
    }
  }
}
