import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para match confirmado entre dois usuários
class Match {
  /// ID do match (gerado a partir dos IDs dos usuários)
  final String id;

  /// IDs dos dois usuários que deram match
  final List<String> users;

  /// Data/hora da criação do match
  final DateTime createdAt;

  /// Status do match: 'active', 'unmatched', 'blocked'
  final String status;

  /// ID da última mensagem (se houver)
  final String? lastMessageId;

  /// Data/hora da última mensagem
  final DateTime? lastMessageAt;

  /// Se o match foi visualizado pelo usuário 1
  final bool viewedByUser1;

  /// Se o match foi visualizado pelo usuário 2
  final bool viewedByUser2;

  Match({
    required this.id,
    required this.users,
    required this.createdAt,
    required this.status,
    this.lastMessageId,
    this.lastMessageAt,
    this.viewedByUser1 = false,
    this.viewedByUser2 = false,
  });

  /// Se o match está ativo
  bool get isActive => status == 'active';

  /// Se o match foi desfeito
  bool get isUnmatched => status == 'unmatched';

  /// Se o match foi bloqueado
  bool get isBlocked => status == 'blocked';

  /// Obtém o ID do outro usuário no match
  String getOtherUserId(String currentUserId) {
    return users.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  /// Verifica se o match foi visualizado por um usuário específico
  bool hasBeenViewedBy(String userId) {
    if (users.isEmpty || users.length < 2) return false;
    if (users[0] == userId) return viewedByUser1;
    if (users[1] == userId) return viewedByUser2;
    return false;
  }

  /// Cria Match a partir de documento Firestore
  factory Match.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Match(
      id: doc.id,
      users: List<String>.from(data['users'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      status: data['status'] as String? ?? 'active',
      lastMessageId: data['lastMessageId'] as String?,
      lastMessageAt: data['lastMessageAt'] != null
          ? (data['lastMessageAt'] as Timestamp).toDate()
          : null,
      viewedByUser1: data['viewedByUser1'] as bool? ?? false,
      viewedByUser2: data['viewedByUser2'] as bool? ?? false,
    );
  }

  /// Converte para Map para salvar no Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'users': users,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      if (lastMessageId != null) 'lastMessageId': lastMessageId,
      if (lastMessageAt != null)
        'lastMessageAt': Timestamp.fromDate(lastMessageAt!),
      'viewedByUser1': viewedByUser1,
      'viewedByUser2': viewedByUser2,
    };
  }

  /// Cria uma cópia com valores modificados
  Match copyWith({
    String? id,
    List<String>? users,
    DateTime? createdAt,
    String? status,
    String? lastMessageId,
    DateTime? lastMessageAt,
    bool? viewedByUser1,
    bool? viewedByUser2,
  }) {
    return Match(
      id: id ?? this.id,
      users: users ?? this.users,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      viewedByUser1: viewedByUser1 ?? this.viewedByUser1,
      viewedByUser2: viewedByUser2 ?? this.viewedByUser2,
    );
  }

  /// Marca como visualizado por um usuário
  Match markAsViewedBy(String userId) {
    if (users.isEmpty || users.length < 2) return this;
    
    if (users[0] == userId && !viewedByUser1) {
      return copyWith(viewedByUser1: true);
    }
    if (users[1] == userId && !viewedByUser2) {
      return copyWith(viewedByUser2: true);
    }
    return this;
  }

  @override
  String toString() {
    return 'Match(id: $id, users: $users, status: $status, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Match && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
