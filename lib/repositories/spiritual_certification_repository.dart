import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/certification_request_model.dart';

/// Repository para gerenciar solicitações de certificação espiritual no Firestore
class SpiritualCertificationRepository {
  final FirebaseFirestore _firestore;
  
  static const String _collectionName = 'spiritual_certifications';
  static const String _usersCollection = 'users';

  SpiritualCertificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Criar nova solicitação de certificação
  Future<String> createRequest(CertificationRequestModel request) async {
    try {
      print('🔍 [CERT_REPO] Tentando salvar em: $_collectionName');
      print('📊 [CERT_REPO] Dados: ${request.toFirestore()}');
      
      final docRef = await _firestore
          .collection(_collectionName)
          .add(request.toFirestore());
      
      print('✅ [CERT_REPO] Documento criado com ID: ${docRef.id}');
      
      return docRef.id;
    } catch (e) {
      print('❌ [CERT_REPO] ERRO ao salvar: $e');
      throw Exception('Erro ao criar solicitação de certificação: $e');
    }
  }

  /// Buscar solicitações por ID do usuário
  Future<List<CertificationRequestModel>> getByUserId(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => CertificationRequestModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar solicitações do usuário: $e');
    }
  }

  /// Stream de solicitações pendentes (para admin)
  Stream<List<CertificationRequestModel>> getPendingRequests() {
    try {
      return _firestore
          .collection(_collectionName)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => CertificationRequestModel.fromFirestore(doc))
              .toList());
    } catch (e) {
      throw Exception('Erro ao buscar solicitações pendentes: $e');
    }
  }

  /// Buscar solicitação por ID
  Future<CertificationRequestModel?> getById(String requestId) async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(requestId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return CertificationRequestModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Erro ao buscar solicitação: $e');
    }
  }

  /// Atualizar status da solicitação
  Future<void> updateStatus(
    String requestId,
    CertificationStatus status, {
    String? reviewedBy,
    String? rejectionReason,
  }) async {
    try {
      final updateData = {
        'status': status.name,
        'processedAt': FieldValue.serverTimestamp(),
        'reviewedAt': FieldValue.serverTimestamp(),
      };

      if (reviewedBy != null) {
        updateData['reviewedBy'] = reviewedBy;
      }

      if (rejectionReason != null) {
        updateData['rejectionReason'] = rejectionReason;
      }

      await _firestore
          .collection(_collectionName)
          .doc(requestId)
          .update(updateData);
    } catch (e) {
      throw Exception('Erro ao atualizar status da solicitação: $e');
    }
  }

  /// Atualizar campo isSpiritualCertified do usuário
  Future<void> updateUserCertificationStatus(
    String userId,
    bool certified,
  ) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .update({
            'isSpiritualCertified': certified,
          });
    } catch (e) {
      throw Exception('Erro ao atualizar status de certificação do usuário: $e');
    }
  }

  /// Verificar se usuário tem solicitação pendente
  Future<bool> hasPendingRequest(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Erro ao verificar solicitação pendente: $e');
    }
  }

  /// Buscar última solicitação do usuário
  Future<CertificationRequestModel?> getLatestRequest(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return CertificationRequestModel.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      throw Exception('Erro ao buscar última solicitação: $e');
    }
  }

  /// Deletar solicitação (admin)
  Future<void> deleteRequest(String requestId) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(requestId)
          .delete();
    } catch (e) {
      throw Exception('Erro ao deletar solicitação: $e');
    }
  }

  /// Contar solicitações pendentes
  Future<int> countPendingRequests() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('status', isEqualTo: 'pending')
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      throw Exception('Erro ao contar solicitações pendentes: $e');
    }
  }
}
