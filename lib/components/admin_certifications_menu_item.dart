import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../views/certification_approval_panel_view.dart';
import '../services/certification_approval_service.dart';

/// Item de menu para acesso ao painel de certificações
/// 
/// Exibe:
/// - Ícone de certificação
/// - Texto "Certificações"
/// - Badge com contador de pendentes
/// - Navegação para o painel administrativo
class AdminCertificationsMenuItem extends StatelessWidget {
  final bool isAdmin;
  final VoidCallback? onTap;
  
  const AdminCertificationsMenuItem({
    Key? key,
    required this.isAdmin,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Só exibe se for admin
    if (!isAdmin) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<int>(
      stream: _getPendingCountStream(),
      builder: (context, snapshot) {
        final pendingCount = snapshot.data ?? 0;
        
        return ListTile(
          leading: Stack(
            children: [
              const Icon(
                Icons.verified_user,
                color: Colors.orange,
                size: 28,
              ),
              if (pendingCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 1.5,
                      ),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      pendingCount > 99 ? '99+' : '$pendingCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          title: const Text(
            'Certificações',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: pendingCount > 0
              ? Text(
                  '$pendingCount pendente${pendingCount > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                )
              : null,
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            if (onTap != null) {
              onTap!();
            } else {
              _navigateToCertificationPanel(context);
            }
          },
        );
      },
    );
  }

  /// Obtém stream com contagem de certificações pendentes
  Stream<int> _getPendingCountStream() {
    final service = CertificationApprovalService();
    return service.getPendingCertifications().map((list) => list.length);
  }

  /// Navega para o painel de certificações
  void _navigateToCertificationPanel(BuildContext context) {
    Get.to(() => const CertificationApprovalPanelView());
  }
}

/// Versão compacta para drawer/menu lateral
class CompactAdminCertificationsMenuItem extends StatelessWidget {
  final bool isAdmin;
  
  const CompactAdminCertificationsMenuItem({
    Key? key,
    required this.isAdmin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isAdmin) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<int>(
      stream: _getPendingCountStream(),
      builder: (context, snapshot) {
        final pendingCount = snapshot.data ?? 0;
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _navigateToCertificationPanel(context),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.verified_user,
                          color: Colors.orange,
                          size: 24,
                        ),
                      ),
                      if (pendingCount > 0)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              pendingCount > 9 ? '9+' : '$pendingCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Certificações',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pendingCount > 0
                              ? '$pendingCount aguardando análise'
                              : 'Nenhuma pendente',
                          style: TextStyle(
                            fontSize: 13,
                            color: pendingCount > 0
                                ? Colors.orange[700]
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Stream<int> _getPendingCountStream() {
    final service = CertificationApprovalService();
    return service.getPendingCertifications().map((list) => list.length);
  }

  void _navigateToCertificationPanel(BuildContext context) {
    Get.to(() => const CertificationApprovalPanelView());
  }
}

/// Badge flutuante para exibir contador de pendentes
class CertificationPendingBadge extends StatelessWidget {
  final bool isAdmin;
  
  const CertificationPendingBadge({
    Key? key,
    required this.isAdmin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isAdmin) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<int>(
      stream: _getPendingCountStream(),
      builder: (context, snapshot) {
        final pendingCount = snapshot.data ?? 0;
        
        if (pendingCount == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            pendingCount > 99 ? '99+' : '$pendingCount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  Stream<int> _getPendingCountStream() {
    final service = CertificationApprovalService();
    return service.getPendingCertifications().map((list) => list.length);
  }
}

/// Botão de ação flutuante para acesso rápido
class QuickAccessCertificationButton extends StatelessWidget {
  final bool isAdmin;
  
  const QuickAccessCertificationButton({
    Key? key,
    required this.isAdmin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isAdmin) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<int>(
      stream: _getPendingCountStream(),
      builder: (context, snapshot) {
        final pendingCount = snapshot.data ?? 0;
        
        // Só exibe se houver pendentes
        if (pendingCount == 0) {
          return const SizedBox.shrink();
        }

        return FloatingActionButton.extended(
          onPressed: () => _navigateToCertificationPanel(context),
          backgroundColor: Colors.orange,
          icon: Stack(
            children: [
              const Icon(Icons.verified_user),
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    pendingCount > 9 ? '9+' : '$pendingCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          label: Text(
            '$pendingCount Certificaç${pendingCount > 1 ? 'ões' : 'ão'}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  Stream<int> _getPendingCountStream() {
    final service = CertificationApprovalService();
    return service.getPendingCertifications().map((list) => list.length);
  }

  void _navigateToCertificationPanel(BuildContext context) {
    Get.to(() => const CertificationApprovalPanelView());
  }
}
