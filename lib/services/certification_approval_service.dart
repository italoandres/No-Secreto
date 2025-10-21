import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/certification_request_model.dart';
import 'certification_audit_service.dart';

/// Serviço para aprovação e reprovação de certificações
/// 
/// Fornece métodos para:
/// - Aprovar certificações
/// - Reprovar certificações com motivo
/// - Obter certificações pendentes em tempo real
/// - Obter histórico de certificações com filtros
class CertificationApprovalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CertificationAuditService _auditService = CertificationAuditService();
  
  /// Stream de certificações pendentes em tempo real
  Stream<List<CertificationRequestModel>> getPendingCertificationsStream() {
    return _firestore
        .collection('spiritual_certifications')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return CertificationRequestModel.fromMap(data);
      }).toList();
    });
  }
  
  /// Stream de histórico de certificações com filtros opcionais
  /// 
  /// [status] - Filtrar por status (approved, rejected, pending)
  /// [userId] - Filtrar por ID do usuário
  Stream<List<CertificationRequestModel>> getCertificationHistoryStream({
    CertificationStatus? status,
    String? userId,
  }) {
    Query query = _firestore.collection('spiritual_certifications');
    
    // Aplicar filtro de status se fornecido
    if (status != null) {
      String statusString;
      switch (status) {
        case CertificationStatus.pending:
          statusString = 'pending';
          break;
        case CertificationStatus.approved:
          statusString = 'approved';
          break;
        case CertificationStatus.rejected:
          statusString = 'rejected';
          break;
      }
      query = query.where('status', isEqualTo: statusString);
    }
    
    // Aplicar filtro de userId se fornecido
    if (userId != null && userId.isNotEmpty) {
      query = query.where('userId', isEqualTo: userId);
    }
    
    // Ordenar por data de processamento (mais recentes primeiro)
    query = query.orderBy('processedAt', descending: true);
    
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return CertificationRequestModel.fromMap(data);
      }).toList();
    });
  }
  
  /// Aprova uma certificação
  /// 
  /// [certificationId] - ID da certificação a ser aprovada
  /// [adminEmail] - Email do administrador que está aprovando
  /// 
  /// Retorna true se a aprovação foi bem-sucedida
  Future<bool> approveCertification(
    String certificationId,
    String adminEmail,
  ) async {
    try {
      // Obter dados da certificação para o log
      final certDoc = await _firestore
          .collection('spiritual_certifications')
          .doc(certificationId)
          .get();
          
      if (!certDoc.exists) {
        print('Erro: Certificação não encontrada');
        return false;
      }
      
      final userId = certDoc.data()?['userId'] as String?;
      
      final now = DateTime.now();
      
      await _firestore
          .collection('spiritual_certifications')
          .doc(certificationId)
          .update({
        'status': 'approved',
        'reviewedBy': adminEmail,
        'reviewedAt': Timestamp.fromDate(now),
        'processedAt': Timestamp.fromDate(now),
        'processedBy': adminEmail,
        'updatedAt': Timestamp.fromDate(now),
      });
      
      // Registrar no log de auditoria
      if (userId != null) {
        await _auditService.logApproval(
          certificationId: certificationId,
          userId: userId,
          approvedBy: adminEmail,
          method: 'panel',
        );
      }
      
      print('Certificação $certificationId aprovada por $adminEmail');
      return true;
    } catch (e) {
      print('Erro ao aprovar certificação: $e');
      return false;
    }
  }
  
  /// Reprova uma certificação com motivo
  /// 
  /// [certificationId] - ID da certificação a ser reprovada
  /// [adminEmail] - Email do administrador que está reprovando
  /// [rejectionReason] - Motivo da reprovação
  /// 
  /// Retorna true se a reprovação foi bem-sucedida
  Future<bool> rejectCertification(
    String certificationId,
    String adminEmail,
    String rejectionReason,
  ) async {
    try {
      // Validar que o motivo não está vazio
      if (rejectionReason.trim().isEmpty) {
        print('Erro: Motivo da reprovação não pode estar vazio');
        return false;
      }
      
      // Obter dados da certificação para o log
      final certDoc = await _firestore
          .collection('spiritual_certifications')
          .doc(certificationId)
          .get();
          
      if (!certDoc.exists) {
        print('Erro: Certificação não encontrada');
        return false;
      }
      
      final userId = certDoc.data()?['userId'] as String?;
      
      final now = DateTime.now();
      
      await _firestore
          .collection('spiritual_certifications')
          .doc(certificationId)
          .update({
        'status': 'rejected',
        'reviewedBy': adminEmail,
        'reviewedAt': Timestamp.fromDate(now),
        'processedAt': Timestamp.fromDate(now),
        'processedBy': adminEmail,
        'rejectionReason': rejectionReason,
        'updatedAt': Timestamp.fromDate(now),
      });
      
      // Registrar no log de auditoria
      if (userId != null) {
        await _auditService.logRejection(
          certificationId: certificationId,
          userId: userId,
          rejectedBy: adminEmail,
          method: 'panel',
          reason: rejectionReason,
        );
      }
      
      print('Certificação $certificationId reprovada por $adminEmail');
      return true;
    } catch (e) {
      print('Erro ao reprovar certificação: $e');
      return false;
    }
  }
  
  /// Obtém uma certificação específica por ID
  Future<CertificationRequestModel?> getCertificationById(
    String certificationId,
  ) async {
    try {
      final doc = await _firestore
          .collection('spiritual_certifications')
          .doc(certificationId)
          .get();
      
      if (!doc.exists) {
        return null;
      }
      
      final data = doc.data()!;
      data['id'] = doc.id;
      return CertificationRequestModel.fromMap(data);
    } catch (e) {
      print('Erro ao obter certificação: $e');
      return null;
    }
  }
  
  /// Obtém o total de certificações pendentes
  Future<int> getPendingCount() async {
    try {
      final snapshot = await _firestore
          .collection('spiritual_certifications')
          .where('status', isEqualTo: 'pending')
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      print('Erro ao obter contagem de pendentes: $e');
      return 0;
    }
  }
  
  /// Stream do total de certificações pendentes
  Stream<int> getPendingCountStream() {
    return _firestore
        .collection('spiritual_certifications')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
  
  /// Verifica se um usuário já tem uma certificação aprovada
  Future<bool> hasApprovedCertification(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('spiritual_certifications')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'approved')
          .limit(1)
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Erro ao verificar certificação aprovada: $e');
      return false;
    }
  }
  
  /// Obtém todas as certificações de um usuário
  Future<List<CertificationRequestModel>> getUserCertifications(
    String userId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('spiritual_certifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return CertificationRequestModel.fromMap(data);
      }).toList();
    } catch (e) {
      print('Erro ao obter certificações do usuário: $e');
      return [];
    }
  }
}
