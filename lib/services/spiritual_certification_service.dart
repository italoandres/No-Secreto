import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../models/certification_request_model.dart';
import '../repositories/spiritual_certification_repository.dart';
import 'certification_file_upload_service.dart';
import 'certification_email_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Resultado de operação
class OperationResult {
  final bool success;
  final String? message;
  final String? data;

  OperationResult.success({this.message, this.data}) : success = true;

  OperationResult.error(this.message)
      : success = false,
        data = null;
}

/// Serviço principal para gerenciar certificações espirituais
class SpiritualCertificationService {
  final SpiritualCertificationRepository _repository;
  final CertificationFileUploadService _uploadService;
  final CertificationEmailService _emailService;

  SpiritualCertificationService({
    SpiritualCertificationRepository? repository,
    CertificationFileUploadService? uploadService,
    CertificationEmailService? emailService,
  })  : _repository = repository ?? SpiritualCertificationRepository(),
        _uploadService = uploadService ?? CertificationFileUploadService(),
        _emailService = emailService ?? CertificationEmailService();

  /// Criar nova solicitação de certificação
  Future<OperationResult> createCertificationRequest({
    required String userId,
    required String userName,
    required String userEmail,
    required String purchaseEmail,
    required PlatformFile proofFile,
    required Function(double) onUploadProgress,
  }) async {
    try {
      // 1. Verificar se já tem solicitação pendente
      final hasPending = await _repository.hasPendingRequest(userId);
      if (hasPending) {
        return OperationResult.error(
          'Você já tem uma solicitação pendente. Aguarde a aprovação.',
        );
      }

      // 2. Fazer upload do arquivo
      final uploadResult = await _uploadService.uploadProofFile(
        userId: userId,
        file: proofFile,
        onProgress: onUploadProgress,
      );

      if (!uploadResult.success) {
        return OperationResult.error(
            uploadResult.error ?? 'Erro ao enviar arquivo');
      }

      // 3. Criar solicitação no Firestore
      print('🔍 [CERT_SERVICE] Criando solicitação no Firestore...');

      final request = CertificationRequestModel(
        id: '', // Será gerado pelo Firestore
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        purchaseEmail: purchaseEmail,
        proofFileUrl: uploadResult.downloadUrl!,
        proofFileName: proofFile.name,
        status: CertificationStatus.pending,
        createdAt: DateTime.now(),
      );

      print(
          '📊 [CERT_SERVICE] Request criado: userId=$userId, email=$userEmail');

      final requestId = await _repository.createRequest(request);

      print('✅ [CERT_SERVICE] Solicitação salva com ID: $requestId');

      // 4. Enviar email para admin
      try {
        await _emailService.sendNewRequestEmailToAdmin(
          requestId: requestId,
          userName: userName,
          userEmail: userEmail,
          purchaseEmail: purchaseEmail,
          proofFileUrl: uploadResult.downloadUrl!,
        );
      } catch (e) {
        // Email falhou mas solicitação foi criada
        print('Erro ao enviar email: $e');
      }

      return OperationResult.success(
        message:
            'Solicitação enviada com sucesso! Você receberá resposta em até 3 dias úteis.',
        data: requestId,
      );
    } catch (e) {
      return OperationResult.error('Erro ao criar solicitação: $e');
    }
  }

  /// Buscar solicitações do usuário
  Future<List<CertificationRequestModel>> getUserRequests(String userId) async {
    try {
      return await _repository.getByUserId(userId);
    } catch (e) {
      throw Exception('Erro ao buscar solicitações: $e');
    }
  }

  /// Buscar última solicitação do usuário
  Future<CertificationRequestModel?> getLatestRequest(String userId) async {
    try {
      return await _repository.getLatestRequest(userId);
    } catch (e) {
      throw Exception('Erro ao buscar última solicitação: $e');
    }
  }

  /// Stream de solicitações pendentes (admin)
  Stream<List<CertificationRequestModel>> getPendingRequests() {
    return _repository.getPendingRequests();
  }

  /// Aprovar certificação (admin)
  Future<OperationResult> approveCertification(
    String requestId,
    String adminEmail,
  ) async {
    try {
      // 1. Buscar solicitação
      final request = await _repository.getById(requestId);
      if (request == null) {
        return OperationResult.error('Solicitação não encontrada');
      }

      // 2. Atualizar status da solicitação
      await _repository.updateStatus(
        requestId,
        CertificationStatus.approved,
        reviewedBy: adminEmail,
      );

      // 3. Atualizar campo isSpiritualCertified do usuário
      await _repository.updateUserCertificationStatus(
        request.userId,
        true,
      );

      // 4. Criar notificação in-app para o usuário
      await _createApprovalNotification(request.userId, request.userName);

      // 5. Enviar email de aprovação (opcional)
      try {
        await _emailService.sendApprovalEmailToUser(
          userEmail: request.userEmail,
          userName: request.userName,
        );
      } catch (e) {
        print('Erro ao enviar email de aprovação: $e');
      }

      return OperationResult.success(
        message: 'Certificação aprovada com sucesso!',
      );
    } catch (e) {
      return OperationResult.error('Erro ao aprovar certificação: $e');
    }
  }

  /// Rejeitar certificação (admin)
  Future<OperationResult> rejectCertification(
    String requestId,
    String adminEmail, {
    String? reason,
  }) async {
    try {
      // 1. Buscar solicitação
      final request = await _repository.getById(requestId);
      if (request == null) {
        return OperationResult.error('Solicitação não encontrada');
      }

      // 2. Atualizar status da solicitação
      await _repository.updateStatus(
        requestId,
        CertificationStatus.rejected,
        reviewedBy: adminEmail,
        rejectionReason: reason,
      );

      // 3. Criar notificação in-app para o usuário
      await _createRejectionNotification(
        request.userId,
        request.userName,
        reason,
      );

      // 4. Enviar email de rejeição (opcional)
      try {
        await _emailService.sendRejectionEmailToUser(
          userEmail: request.userEmail,
          userName: request.userName,
          reason: reason,
        );
      } catch (e) {
        print('Erro ao enviar email de rejeição: $e');
      }

      return OperationResult.success(
        message: 'Certificação rejeitada.',
      );
    } catch (e) {
      return OperationResult.error('Erro ao rejeitar certificação: $e');
    }
  }

  /// Criar notificação de aprovação
  Future<void> _createApprovalNotification(
    String userId,
    String userName,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'type': 'certification_approved',
        'title': 'Certificação Aprovada! 🏆',
        'message': 'Parabéns! Sua certificação espiritual foi aprovada ✅',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
        'data': {
          'action': 'open_certification',
        },
      });
    } catch (e) {
      print('Erro ao criar notificação de aprovação: $e');
    }
  }

  /// Criar notificação de rejeição
  Future<void> _createRejectionNotification(
    String userId,
    String userName,
    String? reason,
  ) async {
    try {
      final message = reason != null
          ? 'Sua solicitação precisa de revisão: $reason'
          : 'Sua solicitação de certificação precisa de revisão. Entre em contato conosco.';

      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'type': 'certification_rejected',
        'title': 'Certificação - Revisão Necessária',
        'message': message,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
        'data': {
          'action': 'open_certification',
        },
      });
    } catch (e) {
      print('Erro ao criar notificação de rejeição: $e');
    }
  }

  /// Verificar se usuário pode solicitar certificação
  Future<bool> canRequestCertification(String userId) async {
    try {
      return !(await _repository.hasPendingRequest(userId));
    } catch (e) {
      return false;
    }
  }

  /// Contar solicitações pendentes (admin)
  Future<int> countPendingRequests() async {
    try {
      return await _repository.countPendingRequests();
    } catch (e) {
      return 0;
    }
  }
}
