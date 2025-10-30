import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para interesse demonstrado entre usuários
class Interest {
  /// ID do documento
  final String id;

  /// ID do usuário que demonstrou interesse
  final String fromUserId;

  /// ID do usuário que recebeu o interesse
  final String toUserId;

  /// Data/hora do interesse
  final DateTime timestamp;

  /// Status do interesse: 'pending', 'matched', 'expired'
  final String status;

  Interest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.timestamp,
    required this.status,
  });

  /// Se o interesse está pendente
  bool get isPending => status == 'pending';

  /// Se o interesse resultou em match
  bool get isMatched => status == 'matched';

  /// Se o interesse expirou
  bool get isExpired => status == 'expired';

  /// Cria Interest a partir de documento Firestore
  factory Interest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Interest(
      id: doc.id,
      fromUserId: data['fromUserId'] as String,
      toUserId: data['toUserId'] as String,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      status: data['status'] as String? ?? 'pending',
    );
  }

  /// Converte para Map para salvar no Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
    };
  }

  /// Cria uma cópia com valores modificados
  Interest copyWith({
    String? id,
    String? fromUserId,
    String? toUserId,
    DateTime? timestamp,
    String? status,
  }) {
    return Interest(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }

  @override
  String toString() {
    return 'Interest(id: $id, from: $fromUserId, to: $toUserId, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Interest && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
