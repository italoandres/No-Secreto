import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/certification_audit_log_model.dart';

/// Serviço para registrar logs de auditoria de certificações
/// 
/// Registra todas as ações de aprovação/reprovação incluindo:
/// - Quem executou a ação
/// - Quando foi executada
/// - Via qual método (email ou painel)
/// - Tentativas de uso de tokens inválidos
class CertificationAuditService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Registra aprovação de certificação
  Future<void> logApproval({
    required String certificationId,
    required String userId,
    required String approvedBy,
    required String method, // 'email' ou 'panel'
    String? tokenId,
  }) async {
    try {
      final log = CertificationAuditLogModel(
        id: _firestore.collection('certification_audit_log').doc().id,
        certificationId: certificationId,
        userId: userId,
        action: 'approved',
        performedBy: approvedBy,
        method: method,
        timestamp: DateTime.now(),
      );
      
      await _firestore
          .collection('certification_audit_log')
          .doc(log.id)
          .set(log.toFirestore());
          
      print('✅ Auditoria: Aprovação registrada - Cert: $certificationId por $approvedBy via $method');
    } catch (e) {
      print('❌ Erro ao registrar log de aprovação: $e');
      // Não lança exceção para não bloquear o fluxo principal
    }
  }
  
  /// Registra reprovação de certificação
  Future<void> logRejection({
    required String certificationId,
    required String userId,
    required String rejectedBy,
    required String method,
    required String reason,
    String? tokenId,
  }) async {
    try {
      final log = CertificationAuditLogModel(
        id: _firestore.collection('certification_audit_log').doc().id,
        certificationId: certificationId,
        userId: userId,
        action: 'rejected',
        performedBy: rejectedBy,
        method: method,
        timestamp: DateTime.now(),
        reason: reason,
      );
      
      await _firestore
          .collection('certification_audit_log')
          .doc(log.id)
          .set(log.toFirestore());
          
      print('✅ Auditoria: Reprovação registrada - Cert: $certificationId por $rejectedBy via $method');
    } catch (e) {
      print('❌ Erro ao registrar log de reprovação: $e');
    }
  }
  
  /// Registra tentativa de uso de token inválido
  Future<void> logInvalidToken({
    required String token,
    required String reason,
    String? ipAddress,
  }) async {
    try {
      final log = CertificationAuditLogModel(
        id: _firestore.collection('certification_audit_log').doc().id,
        certificationId: 'unknown',
        userId: 'unknown',
        action: 'invalid_token_attempt',
        performedBy: 'system',
        method: 'email',
        timestamp: DateTime.now(),
        reason: reason,
        ipAddress: ipAddress,
      );
      
      await _firestore
          .collection('certification_audit_log')
          .doc(log.id)
          .set(log.toFirestore());
          
      print('⚠️ Auditoria: Tentativa de token inválido registrada - Motivo: $reason');
    } catch (e) {
      print('❌ Erro ao registrar tentativa de token inválido: $e');
    }
  }
  
  /// Registra tentativa de uso de token expirado
  Future<void> logExpiredToken({
    required String token,
    required String certificationId,
    DateTime? expirationDate,
  }) async {
    try {
      final log = CertificationAuditLogModel(
        id: _firestore.collection('certification_audit_log').doc().id,
        certificationId: certificationId,
        userId: 'unknown',
        action: 'expired_token_attempt',
        performedBy: 'system',
        method: 'email',
        timestamp: DateTime.now(),
        reason: 'Token expirado',
      );
      
      await _firestore
          .collection('certification_audit_log')
          .doc(log.id)
          .set(log.toFirestore());
          
      print('⚠️ Auditoria: Token expirado - Cert: $certificationId');
    } catch (e) {
      print('❌ Erro ao registrar token expirado: $e');
    }
  }
  
  /// Registra tentativa de uso de token já usado
  Future<void> logUsedToken({
    required String token,
    required String certificationId,
    DateTime? usedAt,
    String? usedBy,
  }) async {
    try {
      final log = CertificationAuditLogModel(
        id: _firestore.collection('certification_audit_log').doc().id,
        certificationId: certificationId,
        userId: 'unknown',
        action: 'used_token_attempt',
        performedBy: 'system',
        method: 'email',
        timestamp: DateTime.now(),
        reason: 'Token já foi usado anteriormente',
      );
      
      await _firestore
          .collection('certification_audit_log')
          .doc(log.id)
          .set(log.toFirestore());
          
      print('⚠️ Auditoria: Tentativa de reusar token - Cert: $certificationId');
    } catch (e) {
      print('❌ Erro ao registrar token já usado: $e');
    }
  }
  
  /// Obtém logs de auditoria de uma certificação específica
  Stream<List<CertificationAuditLogModel>> getCertificationLogs(String certificationId) {
    return _firestore
        .collection('certification_audit_log')
        .where('certificationId', isEqualTo: certificationId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CertificationAuditLogModel.fromFirestore(doc.id, doc.data()))
            .toList());
  }
  
  /// Obtém logs de auditoria de um usuário específico
  Stream<List<CertificationAuditLogModel>> getUserLogs(String userId) {
    return _firestore
        .collection('certification_audit_log')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CertificationAuditLogModel.fromFirestore(doc.id, doc.data()))
            .toList());
  }
  
  /// Obtém logs de tentativas suspeitas (tokens inválidos, expirados, etc)
  Stream<List<CertificationAuditLogModel>> getSuspiciousActivityLogs() {
    return _firestore
        .collection('certification_audit_log')
        .where('action', whereIn: [
          'invalid_token_attempt',
          'expired_token_attempt',
          'used_token_attempt',
        ])
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CertificationAuditLogModel.fromFirestore(doc.id, doc.data()))
            .toList());
  }
  
  /// Obtém estatísticas de auditoria
  Future<Map<String, int>> getAuditStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection('certification_audit_log');
      
      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }
      
      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endDate);
      }
      
      final snapshot = await query.get();
      
      final stats = <String, int>{
        'total': snapshot.docs.length,
        'approved': 0,
        'rejected': 0,
        'invalid_attempts': 0,
        'expired_attempts': 0,
        'used_attempts': 0,
      };
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final action = data['action'] as String?;
        
        switch (action) {
          case 'approved':
            stats['approved'] = (stats['approved'] ?? 0) + 1;
            break;
          case 'rejected':
            stats['rejected'] = (stats['rejected'] ?? 0) + 1;
            break;
          case 'invalid_token_attempt':
            stats['invalid_attempts'] = (stats['invalid_attempts'] ?? 0) + 1;
            break;
          case 'expired_token_attempt':
            stats['expired_attempts'] = (stats['expired_attempts'] ?? 0) + 1;
            break;
          case 'used_token_attempt':
            stats['used_attempts'] = (stats['used_attempts'] ?? 0) + 1;
            break;
        }
      }
      
      return stats;
    } catch (e) {
      print('❌ Erro ao obter estatísticas de auditoria: $e');
      return {};
    }
  }
}
