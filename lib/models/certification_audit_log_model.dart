import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para logs de auditoria de certificações
/// 
/// Registra todas as ações relacionadas a certificações espirituais
class CertificationAuditLogModel {
  final String id;
  final String action; // 'approval', 'rejection', 'invalid_token_attempt', 'unauthorized_access', 'proof_view'
  final String? certificationId;
  final String? userId;
  final String? userName;
  final String? performedBy;
  final String? performedByEmail;
  final String? method; // 'email_link' ou 'admin_panel'
  final String? rejectionReason;
  final String? adminNotes;
  final String? token;
  final String? reason; // Para invalid_token_attempt
  final String? attemptedAction; // Para unauthorized_access
  final String? attemptedBy;
  final String? attemptedByEmail;
  final String? viewedBy;
  final String? viewedByEmail;
  final String? ipAddress;
  final String? userAgent;
  final DateTime? timestamp;

  CertificationAuditLogModel({
    required this.id,
    required this.action,
    this.certificationId,
    this.userId,
    this.userName,
    this.performedBy,
    this.performedByEmail,
    this.method,
    this.rejectionReason,
    this.adminNotes,
    this.token,
    this.reason,
    this.attemptedAction,
    this.attemptedBy,
    this.attemptedByEmail,
    this.viewedBy,
    this.viewedByEmail,
    this.ipAddress,
    this.userAgent,
    this.timestamp,
  });

  /// Cria instância a partir do Firestore
  factory CertificationAuditLogModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return CertificationAuditLogModel(
      id: id,
      action: data['action'] as String,
      certificationId: data['certificationId'] as String?,
      userId: data['userId'] as String?,
      userName: data['userName'] as String?,
      performedBy: data['performedBy'] as String?,
      performedByEmail: data['performedByEmail'] as String?,
      method: data['method'] as String?,
      rejectionReason: data['rejectionReason'] as String?,
      adminNotes: data['adminNotes'] as String?,
      token: data['token'] as String?,
      reason: data['reason'] as String?,
      attemptedAction: data['attemptedAction'] as String?,
      attemptedBy: data['attemptedBy'] as String?,
      attemptedByEmail: data['attemptedByEmail'] as String?,
      viewedBy: data['viewedBy'] as String?,
      viewedByEmail: data['viewedByEmail'] as String?,
      ipAddress: data['ipAddress'] as String?,
      userAgent: data['userAgent'] as String?,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  /// Converte para Map para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'action': action,
      if (certificationId != null) 'certificationId': certificationId,
      if (userId != null) 'userId': userId,
      if (userName != null) 'userName': userName,
      if (performedBy != null) 'performedBy': performedBy,
      if (performedByEmail != null) 'performedByEmail': performedByEmail,
      if (method != null) 'method': method,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      if (adminNotes != null) 'adminNotes': adminNotes,
      if (token != null) 'token': token,
      if (reason != null) 'reason': reason,
      if (attemptedAction != null) 'attemptedAction': attemptedAction,
      if (attemptedBy != null) 'attemptedBy': attemptedBy,
      if (attemptedByEmail != null) 'attemptedByEmail': attemptedByEmail,
      if (viewedBy != null) 'viewedBy': viewedBy,
      if (viewedByEmail != null) 'viewedByEmail': viewedByEmail,
      if (ipAddress != null) 'ipAddress': ipAddress,
      if (userAgent != null) 'userAgent': userAgent,
      'timestamp': timestamp != null 
          ? Timestamp.fromDate(timestamp!) 
          : FieldValue.serverTimestamp(),
    };
  }

  /// Retorna descrição legível da ação
  String getActionDescription() {
    switch (action) {
      case 'approval':
        return 'Certificação aprovada';
      case 'rejection':
        return 'Certificação reprovada';
      case 'invalid_token_attempt':
        return 'Tentativa de uso de token inválido';
      case 'unauthorized_access':
        return 'Tentativa de acesso não autorizado';
      case 'proof_view':
        return 'Comprovante visualizado';
      default:
        return 'Ação desconhecida';
    }
  }

  /// Retorna ícone apropriado para a ação
  String getActionIcon() {
    switch (action) {
      case 'approval':
        return '✅';
      case 'rejection':
        return '❌';
      case 'invalid_token_attempt':
        return '⚠️';
      case 'unauthorized_access':
        return '🚨';
      case 'proof_view':
        return '👁️';
      default:
        return '📝';
    }
  }

  @override
  String toString() {
    return 'CertificationAuditLogModel(id: $id, action: $action, certificationId: $certificationId, timestamp: $timestamp)';
  }
}
