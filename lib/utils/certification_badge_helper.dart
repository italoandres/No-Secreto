import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../components/spiritual_certification_badge.dart';

/// Helper para integração do badge de certificação em diferentes contextos
///
/// Facilita a exibição do badge de certificação espiritual em várias telas
/// do aplicativo, com métodos específicos para cada contexto.
class CertificationBadgeHelper {
  /// Verifica se o usuário é certificado a partir dos dados do Firestore
  static bool isCertified(Map<String, dynamic>? userData) {
    if (userData == null) return false;
    return userData['spirituallyCertified'] == true;
  }

  /// Obtém o status de certificação de um usuário pelo ID
  static Future<bool> isUserCertified(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .get();

      return isCertified(doc.data());
    } catch (e) {
      print('Erro ao verificar certificação: $e');
      return false;
    }
  }

  /// Badge para perfil próprio (com label e tamanho grande)
  static Widget buildOwnProfileBadge({
    required BuildContext context,
    required String userId,
    double size = 70,
    bool showLabel = true,
  }) {
    return FutureBuilder<bool>(
      future: isUserCertified(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildLoadingBadge(size);
        }

        if (!snapshot.data!) {
          return _buildNotCertifiedButton(context, size);
        }

        return SpiritualCertificationBadge(
          isCertified: true,
          size: size,
          showLabel: showLabel,
        );
      },
    );
  }

  /// Badge para perfil de outros usuários (sem botão de solicitação)
  static Widget buildOtherProfileBadge({
    required String userId,
    double size = 60,
    bool showLabel = true,
  }) {
    return FutureBuilder<bool>(
      future: isUserCertified(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildLoadingBadge(size);
        }

        return SpiritualCertificationBadge(
          isCertified: snapshot.data!,
          size: size,
          showLabel: showLabel,
        );
      },
    );
  }

  /// Badge compacto para cards da vitrine
  static Widget buildVitrineCardBadge({
    required String userId,
    double size = 32,
  }) {
    return FutureBuilder<bool>(
      future: isUserCertified(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(width: size, height: size);
        }

        return Positioned(
          top: 8,
          right: 8,
          child: CompactCertificationBadge(
            isCertified: snapshot.data!,
            size: size,
          ),
        );
      },
    );
  }

  /// Badge inline para listas e resultados de busca
  static Widget buildInlineBadge({
    required String userId,
    double size = 20,
  }) {
    return FutureBuilder<bool>(
      future: isUserCertified(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(width: size, height: size);
        }

        if (!snapshot.data!) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Icon(
            Icons.verified,
            color: Colors.amber.shade700,
            size: size,
          ),
        );
      },
    );
  }

  /// Badge com stream para atualizações em tempo real
  static Widget buildStreamBadge({
    required String userId,
    required bool isOwnProfile,
    BuildContext? context,
    double size = 70,
    bool showLabel = true,
  }) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildLoadingBadge(size);
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        final certified = isCertified(userData);

        if (isOwnProfile && !certified && context != null) {
          return _buildNotCertifiedButton(context, size);
        }

        return SpiritualCertificationBadge(
          isCertified: certified,
          size: size,
          showLabel: showLabel,
        );
      },
    );
  }

  /// Widget de loading enquanto verifica certificação
  static Widget _buildLoadingBadge(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade200,
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.5,
          height: size * 0.5,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.grey.shade400,
            ),
          ),
        ),
      ),
    );
  }

  /// Botão para solicitar certificação (quando não certificado)
  static Widget _buildNotCertifiedButton(BuildContext context, double size) {
    return GestureDetector(
      onTap: () => _navigateToCertificationRequest(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey.shade300,
                  Colors.grey.shade500,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade400.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.verified_outlined,
              color: Colors.white,
              size: size * 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade600.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Solicitar Certificação',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Navega para a tela de solicitação de certificação
  static void _navigateToCertificationRequest(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.verified,
              color: Colors.amber.shade700,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text('Certificação Espiritual'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seja certificado espiritualmente e ganhe mais credibilidade no aplicativo!',
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.amber.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBenefitItem('✓ Destaque no perfil'),
                  _buildBenefitItem('✓ Maior confiabilidade'),
                  _buildBenefitItem('✓ Badge exclusivo'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Agora não'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Navegar para tela de solicitação
              // Navigator.pushNamed(context, '/certification-request');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Solicitar'),
          ),
        ],
      ),
    );
  }

  static Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }

  /// Obtém dados completos de certificação de um usuário
  static Future<CertificationData?> getCertificationData(String userId) async {
    try {
      final certDoc = await FirebaseFirestore.instance
          .collection('certifications')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'approved')
          .limit(1)
          .get();

      if (certDoc.docs.isEmpty) {
        return null;
      }

      final data = certDoc.docs.first.data();
      return CertificationData(
        userId: userId,
        isCertified: true,
        approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
        certificationId: certDoc.docs.first.id,
      );
    } catch (e) {
      print('Erro ao obter dados de certificação: $e');
      return null;
    }
  }
}

/// Dados de certificação de um usuário
class CertificationData {
  final String userId;
  final bool isCertified;
  final DateTime? approvedAt;
  final String? certificationId;

  CertificationData({
    required this.userId,
    required this.isCertified,
    this.approvedAt,
    this.certificationId,
  });
}

/// Widget wrapper para facilitar uso em diferentes contextos
class CertificationBadgeWrapper extends StatelessWidget {
  final String userId;
  final bool isOwnProfile;
  final CertificationBadgeType type;
  final double? size;
  final bool? showLabel;

  const CertificationBadgeWrapper({
    Key? key,
    required this.userId,
    required this.isOwnProfile,
    required this.type,
    this.size,
    this.showLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case CertificationBadgeType.ownProfile:
        return CertificationBadgeHelper.buildOwnProfileBadge(
          context: context,
          userId: userId,
          size: size ?? 70,
          showLabel: showLabel ?? true,
        );

      case CertificationBadgeType.otherProfile:
        return CertificationBadgeHelper.buildOtherProfileBadge(
          userId: userId,
          size: size ?? 60,
          showLabel: showLabel ?? true,
        );

      case CertificationBadgeType.vitrineCard:
        return CertificationBadgeHelper.buildVitrineCardBadge(
          userId: userId,
          size: size ?? 32,
        );

      case CertificationBadgeType.inline:
        return CertificationBadgeHelper.buildInlineBadge(
          userId: userId,
          size: size ?? 20,
        );

      case CertificationBadgeType.stream:
        return CertificationBadgeHelper.buildStreamBadge(
          userId: userId,
          isOwnProfile: isOwnProfile,
          context: context,
          size: size ?? 70,
          showLabel: showLabel ?? true,
        );

      case CertificationBadgeType.profileHeader:
        return CertificationBadgeHelper.buildStreamBadge(
          userId: userId,
          isOwnProfile: isOwnProfile,
          context: context,
          size: size ?? 80,
          showLabel: showLabel ?? true,
        );
    }
  }
}

/// Tipos de badge disponíveis
enum CertificationBadgeType {
  ownProfile, // Perfil próprio com botão de solicitação
  otherProfile, // Perfil de outros usuários
  vitrineCard, // Card da vitrine (compacto)
  inline, // Inline em listas
  stream, // Com stream em tempo real
  profileHeader, // Header de perfil com tamanho maior
}
