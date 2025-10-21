import 'package:cloud_firestore/cloud_firestore.dart';

class Interest {
  final String id;
  final String from; // userId que demonstrou interesse
  final String to;   // userId que recebeu interesse
  final DateTime timestamp;
  final String? message;
  final Map<String, dynamic>? metadata;

  Interest({
    required this.id,
    required this.from,
    required this.to,
    required this.timestamp,
    this.message,
    this.metadata,
  });

  factory Interest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Interest(
      id: doc.id,
      from: data['from'] ?? '',
      to: data['to'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      message: data['message'],
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'from': from,
      'to': to,
      'timestamp': Timestamp.fromDate(timestamp),
      if (message != null) 'message': message,
      if (metadata != null) 'metadata': metadata,
    };
  }

  bool isValid() {
    return from.isNotEmpty && to.isNotEmpty && from != to;
  }

  @override
  String toString() {
    return 'Interest(id: $id, from: $from, to: $to, timestamp: $timestamp)';
  }
}