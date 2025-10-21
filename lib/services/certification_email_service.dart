/// Serviço para envio de emails relacionados à certificação espiritual
/// NOTA: Cloud Functions não está disponível - emails serão enviados via backend alternativo
class CertificationEmailService {
  static const String _adminEmail = 'sinais.aplicativo@gmail.com';

  /// Enviar email para admin quando há nova solicitação
  Future<void> sendNewRequestEmailToAdmin({
    required String requestId,
    required String userName,
    required String userEmail,
    required String purchaseEmail,
    required String proofFileUrl,
  }) async {
    try {
      // TODO: Implementar envio de email via backend alternativo
      // Por enquanto, apenas log
      print('📧 Email para admin: Nova solicitação de $userName');
      print('   Request ID: $requestId');
      print('   Email: $userEmail');
      print('   Email compra: $purchaseEmail');
      print('   Comprovante: $proofFileUrl');
    } catch (e) {
      print('Erro ao enviar email para admin: $e');
      // Não propagar erro - email é opcional
    }
  }

  /// Enviar email de aprovação para o usuário
  Future<void> sendApprovalEmailToUser({
    required String userEmail,
    required String userName,
  }) async {
    try {
      // TODO: Implementar envio de email via backend alternativo
      print('📧 Email de aprovação para: $userName ($userEmail)');
    } catch (e) {
      print('Erro ao enviar email de aprovação: $e');
      // Não propagar erro - email é opcional
    }
  }

  /// Enviar email de rejeição para o usuário
  Future<void> sendRejectionEmailToUser({
    required String userEmail,
    required String userName,
    String? reason,
  }) async {
    try {
      // TODO: Implementar envio de email via backend alternativo
      print('📧 Email de rejeição para: $userName ($userEmail)');
      print('   Motivo: ${reason ?? "Não especificado"}');
    } catch (e) {
      print('Erro ao enviar email de rejeição: $e');
      // Não propagar erro - email é opcional
    }
  }
}
