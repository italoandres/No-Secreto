import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Serviço para enviar emails de confirmação para administradores
/// 
/// Este serviço envia emails aos administradores após:
/// - Aprovação de certificação
/// - Reprovação de certificação
/// 
/// Os emails incluem:
/// - Resumo da ação tomada
/// - Informações do usuário afetado
/// - Link para o painel administrativo
/// - Timestamp da ação
class AdminConfirmationEmailService {
  static final AdminConfirmationEmailService _instance = 
      AdminConfirmationEmailService._internal();
  factory AdminConfirmationEmailService() => _instance;
  AdminConfirmationEmailService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Collection reference para emails
  CollectionReference get _emailsRef => _firestore.collection('mail');

  /// Envia email de confirmação de aprovação para o admin
  /// 
  /// [certificationId] - ID da certificação aprovada
  /// [userId] - ID do usuário que teve a certificação aprovada
  /// [userEmail] - Email do usuário
  /// [userName] - Nome do usuário
  /// [adminEmail] - Email do admin que aprovou (opcional, usa o atual se não fornecido)
  /// [adminName] - Nome do admin que aprovou
  /// [notes] - Notas adicionais do admin (opcional)
  Future<void> sendApprovalConfirmation({
    required String certificationId,
    required String userId,
    required String userEmail,
    required String userName,
    String? adminEmail,
    String? adminName,
    String? notes,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      final finalAdminEmail = adminEmail ?? currentUser?.email ?? 'admin@app.com';
      final finalAdminName = adminName ?? currentUser?.displayName ?? 'Administrador';
      
      final timestamp = DateTime.now();
      
      // Criar documento de email na coleção 'mail'
      await _emailsRef.add({
        'to': [finalAdminEmail],
        'template': {
          'name': 'admin-certification-approval-confirmation',
          'data': {
            'adminName': finalAdminName,
            'userName': userName,
            'userEmail': userEmail,
            'userId': userId,
            'certificationId': certificationId,
            'approvalDate': timestamp.toIso8601String(),
            'approvalDateFormatted': _formatDate(timestamp),
            'notes': notes ?? 'Nenhuma nota adicional',
            'panelLink': _getPanelLink(),
            'subject': '✅ Certificação Aprovada - $userName',
          },
        },
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('📧 Email de confirmação de aprovação enviado para $finalAdminEmail');
      
    } catch (e) {
      print('❌ Erro ao enviar email de confirmação de aprovação: $e');
      // Não falhar a operação principal por causa do email
    }
  }

  /// Envia email de confirmação de reprovação para o admin
  /// 
  /// [certificationId] - ID da certificação reprovada
  /// [userId] - ID do usuário que teve a certificação reprovada
  /// [userEmail] - Email do usuário
  /// [userName] - Nome do usuário
  /// [rejectionReason] - Motivo da reprovação
  /// [adminEmail] - Email do admin que reprovou (opcional, usa o atual se não fornecido)
  /// [adminName] - Nome do admin que reprovou
  /// [notes] - Notas adicionais do admin (opcional)
  Future<void> sendRejectionConfirmation({
    required String certificationId,
    required String userId,
    required String userEmail,
    required String userName,
    required String rejectionReason,
    String? adminEmail,
    String? adminName,
    String? notes,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      final finalAdminEmail = adminEmail ?? currentUser?.email ?? 'admin@app.com';
      final finalAdminName = adminName ?? currentUser?.displayName ?? 'Administrador';
      
      final timestamp = DateTime.now();
      
      // Criar documento de email na coleção 'mail'
      await _emailsRef.add({
        'to': [finalAdminEmail],
        'template': {
          'name': 'admin-certification-rejection-confirmation',
          'data': {
            'adminName': finalAdminName,
            'userName': userName,
            'userEmail': userEmail,
            'userId': userId,
            'certificationId': certificationId,
            'rejectionDate': timestamp.toIso8601String(),
            'rejectionDateFormatted': _formatDate(timestamp),
            'rejectionReason': rejectionReason,
            'notes': notes ?? 'Nenhuma nota adicional',
            'panelLink': _getPanelLink(),
            'subject': '❌ Certificação Reprovada - $userName',
          },
        },
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('📧 Email de confirmação de reprovação enviado para $finalAdminEmail');
      
    } catch (e) {
      print('❌ Erro ao enviar email de confirmação de reprovação: $e');
      // Não falhar a operação principal por causa do email
    }
  }

  /// Envia email de resumo diário para administradores
  /// 
  /// [adminEmail] - Email do administrador
  /// [adminName] - Nome do administrador
  /// [approvedCount] - Número de certificações aprovadas no dia
  /// [rejectedCount] - Número de certificações reprovadas no dia
  /// [pendingCount] - Número de certificações pendentes
  Future<void> sendDailySummary({
    required String adminEmail,
    required String adminName,
    required int approvedCount,
    required int rejectedCount,
    required int pendingCount,
  }) async {
    try {
      final timestamp = DateTime.now();
      
      await _emailsRef.add({
        'to': [adminEmail],
        'template': {
          'name': 'admin-daily-certification-summary',
          'data': {
            'adminName': adminName,
            'date': _formatDate(timestamp),
            'approvedCount': approvedCount,
            'rejectedCount': rejectedCount,
            'pendingCount': pendingCount,
            'totalProcessed': approvedCount + rejectedCount,
            'panelLink': _getPanelLink(),
            'subject': '📊 Resumo Diário de Certificações - ${_formatDate(timestamp)}',
          },
        },
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('📧 Email de resumo diário enviado para $adminEmail');
      
    } catch (e) {
      print('❌ Erro ao enviar email de resumo diário: $e');
    }
  }

  /// Envia email de alerta para administradores
  /// 
  /// [adminEmail] - Email do administrador
  /// [adminName] - Nome do administrador
  /// [alertType] - Tipo de alerta (ex: 'pending_overflow', 'suspicious_activity')
  /// [alertMessage] - Mensagem do alerta
  /// [details] - Detalhes adicionais do alerta
  Future<void> sendAlert({
    required String adminEmail,
    required String adminName,
    required String alertType,
    required String alertMessage,
    Map<String, dynamic>? details,
  }) async {
    try {
      final timestamp = DateTime.now();
      
      await _emailsRef.add({
        'to': [adminEmail],
        'template': {
          'name': 'admin-certification-alert',
          'data': {
            'adminName': adminName,
            'alertType': alertType,
            'alertMessage': alertMessage,
            'details': details ?? {},
            'timestamp': _formatDate(timestamp),
            'panelLink': _getPanelLink(),
            'subject': '🚨 Alerta - Sistema de Certificações',
          },
        },
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('📧 Email de alerta enviado para $adminEmail');
      
    } catch (e) {
      print('❌ Erro ao enviar email de alerta: $e');
    }
  }

  /// Envia email para múltiplos administradores
  /// 
  /// [adminEmails] - Lista de emails dos administradores
  /// [subject] - Assunto do email
  /// [templateName] - Nome do template a ser usado
  /// [templateData] - Dados para o template
  Future<void> sendToMultipleAdmins({
    required List<String> adminEmails,
    required String subject,
    required String templateName,
    required Map<String, dynamic> templateData,
  }) async {
    try {
      await _emailsRef.add({
        'to': adminEmails,
        'template': {
          'name': templateName,
          'data': {
            ...templateData,
            'subject': subject,
            'panelLink': _getPanelLink(),
          },
        },
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('📧 Email enviado para ${adminEmails.length} administradores');
      
    } catch (e) {
      print('❌ Erro ao enviar email para múltiplos admins: $e');
    }
  }

  /// Obtém lista de emails de administradores
  Future<List<String>> getAdminEmails() async {
    try {
      // Buscar usuários com role 'admin'
      final adminsSnapshot = await _firestore
          .collection('usuarios')
          .where('role', isEqualTo: 'admin')
          .get();
      
      final adminEmails = adminsSnapshot.docs
          .map((doc) => doc.data()['email'] as String?)
          .where((email) => email != null && email.isNotEmpty)
          .cast<String>()
          .toList();
      
      return adminEmails;
      
    } catch (e) {
      print('❌ Erro ao buscar emails de administradores: $e');
      return [];
    }
  }

  /// Envia notificação para todos os administradores
  /// 
  /// [subject] - Assunto do email
  /// [templateName] - Nome do template
  /// [templateData] - Dados para o template
  Future<void> notifyAllAdmins({
    required String subject,
    required String templateName,
    required Map<String, dynamic> templateData,
  }) async {
    try {
      final adminEmails = await getAdminEmails();
      
      if (adminEmails.isEmpty) {
        print('⚠️ Nenhum administrador encontrado para notificar');
        return;
      }
      
      await sendToMultipleAdmins(
        adminEmails: adminEmails,
        subject: subject,
        templateName: templateName,
        templateData: templateData,
      );
      
    } catch (e) {
      print('❌ Erro ao notificar todos os administradores: $e');
    }
  }

  /// Formata data para exibição
  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    
    return '$day/$month/$year às $hour:$minute';
  }

  /// Obtém link para o painel administrativo
  String _getPanelLink() {
    // Em produção, usar o domínio real do app
    // Por enquanto, retornar um placeholder
    return 'https://app.exemplo.com/admin/certifications';
  }

  /// Testa envio de email
  Future<void> testEmail(String adminEmail) async {
    try {
      await _emailsRef.add({
        'to': [adminEmail],
        'template': {
          'name': 'admin-test-email',
          'data': {
            'adminEmail': adminEmail,
            'timestamp': _formatDate(DateTime.now()),
            'subject': '🧪 Email de Teste - Sistema de Certificações',
          },
        },
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('📧 Email de teste enviado para $adminEmail');
      
    } catch (e) {
      print('❌ Erro ao enviar email de teste: $e');
      rethrow;
    }
  }

  /// Dispose do serviço
  void dispose() {
    print('🧹 AdminConfirmationEmailService disposed');
  }
}
