import '../models/certification_request_model.dart';

/// Serviço aprimorado para envio de emails com templates HTML profissionais
class EmailService {
  /// Email do admin para receber notificações
  static const String adminEmail = 'sinais.aplicativo@gmail.com';

  /// Envia email de notificação para o admin sobre nova solicitação
  static Future<void> notifyAdminNewRequest({
    required String userName,
    required String userEmail,
    required String purchaseEmail,
    required String proofUrl,
    required String requestId,
  }) async {
    try {
      final subject = '🏆 Nova Solicitação de Certificação - $userName';
      final htmlBody = _getAdminNotificationTemplate(
        userName: userName,
        userEmail: userEmail,
        purchaseEmail: purchaseEmail,
        proofUrl: proofUrl,
        requestId: requestId,
      );

      await _sendEmail(
        to: adminEmail,
        subject: subject,
        htmlBody: htmlBody,
      );

      print('✅ Email enviado para admin: Nova solicitação de $userName');
    } catch (e) {
      print('❌ Erro ao enviar email para admin: $e');
      // Não relançar erro para não bloquear a solicitação
    }
  }

  /// Envia email de aprovação para o usuário
  static Future<void> notifyUserApproval({
    required String userEmail,
    required String userName,
  }) async {
    try {
      final subject = '✅ Certificação Aprovada - Parabéns $userName!';
      final htmlBody = _getApprovalTemplate(userName: userName);

      await _sendEmail(
        to: userEmail,
        subject: subject,
        htmlBody: htmlBody,
      );

      print('✅ Email de aprovação enviado para $userEmail');
    } catch (e) {
      print('❌ Erro ao enviar email de aprovação: $e');
      // Tentar reenviar após 5 segundos
      await Future.delayed(const Duration(seconds: 5));
      try {
        await _sendEmail(
          to: userEmail,
          subject: '✅ Certificação Aprovada - Parabéns $userName!',
          htmlBody: _getApprovalTemplate(userName: userName),
        );
        print('✅ Email de aprovação reenviado com sucesso');
      } catch (retryError) {
        print('❌ Falha no reenvio do email de aprovação: $retryError');
      }
    }
  }

  /// Envia email de rejeição para o usuário
  static Future<void> notifyUserRejection({
    required String userEmail,
    required String userName,
    required String reason,
  }) async {
    try {
      final subject = '❌ Solicitação de Certificação - Revisão Necessária';
      final htmlBody = _getRejectionTemplate(
        userName: userName,
        reason: reason,
      );

      await _sendEmail(
        to: userEmail,
        subject: subject,
        htmlBody: htmlBody,
      );

      print('✅ Email de rejeição enviado para $userEmail');
    } catch (e) {
      print('❌ Erro ao enviar email de rejeição: $e');
      // Tentar reenviar após 5 segundos
      await Future.delayed(const Duration(seconds: 5));
      try {
        await _sendEmail(
          to: userEmail,
          subject: '❌ Solicitação de Certificação - Revisão Necessária',
          htmlBody: _getRejectionTemplate(userName: userName, reason: reason),
        );
        print('✅ Email de rejeição reenviado com sucesso');
      } catch (retryError) {
        print('❌ Falha no reenvio do email de rejeição: $retryError');
      }
    }
  }

  /// Método privado para enviar email (implementação real)
  static Future<void> _sendEmail({
    required String to,
    required String subject,
    required String htmlBody,
  }) async {
    // TODO: Implementar envio real de email
    // Opções:
    // 1. Firebase Functions com SendGrid
    // 2. Firebase Functions com Nodemailer
    // 3. Cloud Functions com Gmail API
    // 4. Serviço externo como EmailJS

    // Por enquanto, apenas log para desenvolvimento
    print('📧 EMAIL ENVIADO:');
    print('Para: $to');
    print('Assunto: $subject');
    print('Corpo: ${htmlBody.substring(0, 100)}...');

    // Simular delay de envio
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Template HTML para notificação ao admin
  static String _getAdminNotificationTemplate({
    required String userName,
    required String userEmail,
    required String purchaseEmail,
    required String proofUrl,
    required String requestId,
  }) {
    final requestDate = DateTime.now().toLocal().toString().split(' ')[0];
    const adminPanelUrl = 'https://sinais.app/admin/certifications';

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Nova Solicitação de Certificação</title>
</head>
<body style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 0; background-color: #f5f5f5;">
  <div style="max-width: 600px; margin: 20px auto; background: white; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.1);">
    <div style="background: linear-gradient(135deg, #FFA726, #FF9800); color: white; padding: 30px 20px; text-align: center;">
      <h1 style="margin: 0; font-size: 24px; font-weight: 600;">🏆 Nova Solicitação de Certificação</h1>
      <p style="margin: 10px 0 0 0; opacity: 0.9;">Sistema Sinais - Preparado(a) para os Sinais</p>
    </div>
    
    <div style="padding: 30px 20px; line-height: 1.6;">
      <div style="background: #fff3cd; border: 1px solid #ffeaa7; border-radius: 6px; padding: 15px; margin: 20px 0;">
        <span style="color: #856404; font-size: 18px; margin-right: 8px;">⚡</span>
        <strong>Ação Necessária:</strong> Uma nova solicitação de certificação aguarda sua análise.
      </div>
      
      <h3 style="color: #333; margin-bottom: 20px;">📋 Detalhes da Solicitação</h3>
      
      <div style="background: #f8f9fa; border-left: 4px solid #FFA726; padding: 20px; margin: 20px 0; border-radius: 0 8px 8px 0;">
        <div style="display: flex; justify-content: space-between; margin: 10px 0; padding: 8px 0; border-bottom: 1px solid #eee;">
          <span style="font-weight: 600; color: #333;">👤 Nome do Usuário:</span>
          <span style="color: #666;">$userName</span>
        </div>
        <div style="display: flex; justify-content: space-between; margin: 10px 0; padding: 8px 0; border-bottom: 1px solid #eee;">
          <span style="font-weight: 600; color: #333;">📧 Email do App:</span>
          <span style="color: #666;">$userEmail</span>
        </div>
        <div style="display: flex; justify-content: space-between; margin: 10px 0; padding: 8px 0; border-bottom: 1px solid #eee;">
          <span style="font-weight: 600; color: #333;">🛒 Email da Compra:</span>
          <span style="color: #666;">$purchaseEmail</span>
        </div>
        <div style="display: flex; justify-content: space-between; margin: 10px 0; padding: 8px 0; border-bottom: 1px solid #eee;">
          <span style="font-weight: 600; color: #333;">📅 Data da Solicitação:</span>
          <span style="color: #666;">$requestDate</span>
        </div>
        <div style="display: flex; justify-content: space-between; margin: 10px 0; padding: 8px 0;">
          <span style="font-weight: 600; color: #333;">🆔 ID da Solicitação:</span>
          <span style="color: #666;">$requestId</span>
        </div>
      </div>
      
      <h3 style="color: #333; margin: 30px 0 15px 0;">🎯 Próximos Passos</h3>
      <p>Para processar esta solicitação:</p>
      <ol style="color: #666; line-height: 1.8;">
        <li>Clique em "Ver Comprovante" para analisar o documento enviado</li>
        <li>Acesse o "Painel Admin" para aprovar ou rejeitar</li>
        <li>O usuário será notificado automaticamente da sua decisão</li>
      </ol>
      
      <div style="text-align: center; margin: 30px 0;">
        <a href="$proofUrl" style="display: inline-block; background: #FFA726; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; font-weight: 600; margin: 10px 10px 10px 0;">📄 Ver Comprovante</a>
        <a href="$adminPanelUrl" style="display: inline-block; background: #6c757d; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; font-weight: 600; margin: 10px 10px 10px 0;">⚙️ Painel Admin</a>
      </div>
      
      <div style="background: #e3f2fd; border-radius: 6px; padding: 15px; margin: 20px 0;">
        <p style="margin: 0; color: #1565c0;">
          <strong>💡 Lembrete:</strong> O prazo de resposta é de até 3 dias úteis. 
          O usuário será notificado automaticamente quando você processar a solicitação.
        </p>
      </div>
    </div>
    
    <div style="background: #f8f9fa; padding: 20px; text-align: center; color: #666; font-size: 14px;">
      <p>Este email foi enviado automaticamente pelo Sistema Sinais</p>
      <p>📱 Sinais App - Conectando corações preparados para os sinais divinos</p>
    </div>
  </div>
</body>
</html>
''';
  }

  /// Template HTML para aprovação do usuário
  static String _getApprovalTemplate({required String userName}) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Certificação Aprovada</title>
</head>
<body style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 0; background-color: #f5f5f5;">
  <div style="max-width: 600px; margin: 20px auto; background: white; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.1);">
    <div style="background: linear-gradient(135deg, #4CAF50, #45a049); color: white; padding: 40px 20px; text-align: center;">
      <h1 style="margin: 0; font-size: 28px; font-weight: 600;">✅ Certificação Aprovada!</h1>
      <p style="margin: 10px 0 0 0; opacity: 0.9; font-size: 16px;">Parabéns, $userName!</p>
    </div>
    
    <div style="padding: 40px 20px; line-height: 1.7;">
      <div style="text-align: center; font-size: 48px; margin: 20px 0;">
        🎉 🏆 🎊
      </div>
      
      <p style="font-size: 18px; color: #333; text-align: center; margin: 20px 0;">
        <strong>Sua certificação foi aprovada com sucesso!</strong>
      </p>
      
      <p style="color: #666; text-align: center;">
        Você agora faz parte do grupo seleto de membros certificados do Sinais App. 
        Seu perfil receberá o selo especial de "Preparado(a) para os Sinais".
      </p>
      
      <div style="background: #f8f9fa; border-radius: 8px; padding: 25px; margin: 25px 0;">
        <h3 style="color: #4CAF50; margin-top: 0;">🌟 Benefícios da Certificação</h3>
        <ul style="list-style: none; padding: 0;">
          <li style="padding: 8px 0; border-bottom: 1px solid #eee;">✅ Selo de verificação no perfil</li>
          <li style="padding: 8px 0; border-bottom: 1px solid #eee;">✅ Maior visibilidade nas buscas</li>
          <li style="padding: 8px 0; border-bottom: 1px solid #eee;">✅ Acesso a recursos exclusivos</li>
          <li style="padding: 8px 0; border-bottom: 1px solid #eee;">✅ Credibilidade aumentada</li>
          <li style="padding: 8px 0;">✅ Prioridade no suporte</li>
        </ul>
      </div>
      
      <div style="background: linear-gradient(135deg, #fff3e0, #ffe0b2); border-radius: 8px; padding: 20px; margin: 25px 0; text-align: center;">
        <p style="margin: 0; color: #e65100; font-size: 16px; line-height: 1.6;">
          <strong>🙏 Bênção Especial</strong><br>
          "Bem-aventurados os que têm fome e sede de justiça, porque serão fartos."<br>
          <em>Mateus 5:6</em>
        </p>
      </div>
      
      <p style="color: #666; text-align: center; margin: 30px 0;">
        Continue sua jornada espiritual com fé e dedicação. 
        Que Deus abençoe seus passos e guie seu caminho!
      </p>
      
      <div style="text-align: center; margin: 30px 0;">
        <a href="https://sinais.app" style="display: inline-block; background: #4CAF50; color: white; padding: 14px 28px; text-decoration: none; border-radius: 6px; font-weight: 600; font-size: 16px;">📱 Abrir Sinais App</a>
      </div>
    </div>
    
    <div style="background: #f8f9fa; padding: 20px; text-align: center; color: #666; font-size: 14px;">
      <p>Este email foi enviado automaticamente pelo Sistema Sinais</p>
      <p>📱 Sinais App - Conectando corações preparados para os sinais divinos</p>
      <p style="margin-top: 15px; font-size: 12px;">
        Se você tiver dúvidas, entre em contato conosco em sinais.aplicativo@gmail.com
      </p>
    </div>
  </div>
</body>
</html>
''';
  }

  /// Template HTML para rejeição do usuário
  static String _getRejectionTemplate({
    required String userName,
    required String reason,
  }) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0;">
  <title>Solicitação de Certificação - Revisão Necessária</title>
</head>
<body style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 0; background-color: #f5f5f5;">
  <div style="max-width: 600px; margin: 20px auto; background: white; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.1);">
    <div style="background: linear-gradient(135deg, #FF9800, #F57C00); color: white; padding: 40px 20px; text-align: center;">
      <h1 style="margin: 0; font-size: 26px; font-weight: 600;">📋 Solicitação de Certificação</h1>
      <p style="margin: 10px 0 0 0; opacity: 0.9; font-size: 16px;">Revisão Necessária</p>
    </div>
    
    <div style="padding: 40px 20px; line-height: 1.7;">
      <p style="font-size: 18px; color: #333;">Olá, $userName!</p>
      
      <p style="color: #666;">
        Agradecemos seu interesse em obter a certificação no Sinais App. 
        Após análise cuidadosa, identificamos que sua solicitação precisa de alguns ajustes.
      </p>
      
      <div style="background: #fff3cd; border-left: 4px solid #FFA726; padding: 20px; margin: 25px 0; border-radius: 0 8px 8px 0;">
        <h3 style="color: #856404; margin-top: 0;">📝 Motivo da Revisão</h3>
        <p style="color: #856404; margin: 0; line-height: 1.6;">$reason</p>
      </div>
      
      <div style="background: #e3f2fd; border-radius: 8px; padding: 20px; margin: 25px 0;">
        <h3 style="color: #1565c0; margin-top: 0;">🔄 Próximos Passos</h3>
        <ol style="color: #1565c0; line-height: 1.8; padding-left: 20px;">
          <li>Revise o motivo indicado acima</li>
          <li>Prepare a documentação correta</li>
          <li>Envie uma nova solicitação pelo app</li>
          <li>Aguarde nossa análise (até 3 dias úteis)</li>
        </ol>
      </div>
      
      <div style="background: #f8f9fa; border-radius: 8px; padding: 20px; margin: 25px 0;">
        <h3 style="color: #333; margin-top: 0;">💡 Dicas Importantes</h3>
        <ul style="list-style: none; padding: 0; color: #666;">
          <li style="padding: 8px 0; border-bottom: 1px solid #eee;">✓ Certifique-se de que o comprovante está legível</li>
          <li style="padding: 8px 0; border-bottom: 1px solid #eee;">✓ O email da compra deve corresponder ao cadastrado</li>
          <li style="padding: 8px 0; border-bottom: 1px solid #eee;">✓ Verifique se todos os dados estão visíveis</li>
          <li style="padding: 8px 0;">✓ Use um formato de imagem claro (JPG ou PNG)</li>
        </ul>
      </div>
      
      <p style="color: #666; text-align: center; margin: 30px 0;">
        Não desanime! Estamos aqui para ajudar você a conquistar sua certificação. 
        Faça os ajustes necessários e tente novamente.
      </p>
      
      <div style="background: linear-gradient(135deg, #fff3e0, #ffe0b2); border-radius: 8px; padding: 20px; margin: 25px 0; text-align: center;">
        <p style="margin: 0; color: #e65100; font-size: 15px; line-height: 1.6;">
          <strong>🙏 Palavra de Encorajamento</strong><br>
          "Não desanimemos de fazer o bem, pois no tempo próprio colheremos, se não desistirmos."<br>
          <em>Gálatas 6:9</em>
        </p>
      </div>
      
      <div style="text-align: center; margin: 30px 0;">
        <a href="https://sinais.app" style="display: inline-block; background: #FF9800; color: white; padding: 14px 28px; text-decoration: none; border-radius: 6px; font-weight: 600; font-size: 16px;">📱 Tentar Novamente</a>
      </div>
      
      <div style="background: #f1f3f4; border-radius: 6px; padding: 15px; margin: 25px 0; text-align: center;">
        <p style="margin: 0; color: #5f6368; font-size: 14px;">
          <strong>Precisa de ajuda?</strong><br>
          Entre em contato conosco: <a href="mailto:sinais.aplicativo@gmail.com" style="color: #FF9800; text-decoration: none;">sinais.aplicativo@gmail.com</a>
        </p>
      </div>
    </div>
    
    <div style="background: #f8f9fa; padding: 20px; text-align: center; color: #666; font-size: 14px;">
      <p>Este email foi enviado automaticamente pelo Sistema Sinais</p>
      <p>📱 Sinais App - Conectando corações preparados para os sinais divinos</p>
    </div>
  </div>
</body>
</html>
''';
  }

  // Métodos de compatibilidade com a API antiga
  static Future<void> sendApprovalNotification(
      CertificationRequestModel request) async {
    await notifyUserApproval(
      userEmail: request.userEmail,
      userName: request.userDisplayName,
    );
  }

  static Future<void> sendRejectionNotification(
      CertificationRequestModel request) async {
    await notifyUserRejection(
      userEmail: request.userEmail,
      userName: request.userDisplayName,
      reason: request.adminNotes ?? 'Documentação inválida',
    );
  }

  static Future<void> sendNewRequestNotification(
      CertificationRequestModel request) async {
    await notifyAdminNewRequest(
      userName: request.userDisplayName,
      userEmail: request.userEmail,
      purchaseEmail: request.purchaseEmail,
      proofUrl: request.proofImageUrl,
      requestId: request.id ?? 'N/A',
    );
  }
}
