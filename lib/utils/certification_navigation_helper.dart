import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../views/spiritual_certification_request_view.dart';
import '../views/spiritual_certification_admin_view.dart';

/// Helper de navegação para certificação espiritual
class CertificationNavigationHelper {
  /// Navegar para tela de solicitação de certificação
  static void navigateToCertificationRequest(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SpiritualCertificationRequestView(),
      ),
    );
  }

  /// Navegar para painel admin de certificações
  static void navigateToCertificationAdmin(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SpiritualCertificationAdminView(),
      ),
    );
  }

  /// Navegar usando GetX (se disponível)
  static void navigateToCertificationRequestGetX() {
    Get.to(() => const SpiritualCertificationRequestView());
  }

  /// Navegar para admin usando GetX (se disponível)
  static void navigateToCertificationAdminGetX() {
    Get.to(() => const SpiritualCertificationAdminView());
  }

  /// Verificar se usuário é admin
  static bool isAdmin(String? userEmail) {
    if (userEmail == null) return false;

    // Lista de emails admin
    const adminEmails = [
      'sinais.app@gmail.com',
      'admin@sinais.app',
    ];

    return adminEmails.contains(userEmail.toLowerCase());
  }

  /// Mostrar diálogo de informações sobre certificação
  static void showCertificationInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.workspace_premium,
                color: Colors.amber.shade700,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Certificação Espiritual',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'O que é?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'A Certificação Espiritual é um selo dourado que comprova que você concluiu o curso "No Secreto com o Pai".',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Como obter?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade900,
                ),
              ),
              const SizedBox(height: 8),
              _buildInfoItem(
                '1. Envie o comprovante de compra do curso',
              ),
              _buildInfoItem(
                '2. Aguarde a análise da equipe',
              ),
              _buildInfoItem(
                '3. Receba o selo dourado em seu perfil',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.amber.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'O processo de análise pode levar até 48 horas.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              navigateToCertificationRequest(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Solicitar Agora'),
          ),
        ],
      ),
    );
  }

  static Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.amber.shade700,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget de menu item para certificação
class CertificationMenuItem extends StatelessWidget {
  final VoidCallback onTap;
  final bool showBadge;

  const CertificationMenuItem({
    Key? key,
    required this.onTap,
    this.showBadge = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.amber.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.workspace_premium,
          color: Colors.amber.shade700,
          size: 24,
        ),
      ),
      title: const Text(
        'Certificação Espiritual',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: const Text(
        'Solicite seu selo dourado',
        style: TextStyle(fontSize: 13),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showBadge)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Novo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right,
            color: Colors.grey.shade400,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
