import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/spiritual_profile_model.dart';
import '../models/usuario_model.dart';
import '../controllers/profile_display_controller.dart';
import '../utils/certification_status_helper.dart';
import '../utils/enhanced_logger.dart';

class ProfileDisplayView extends StatefulWidget {
  final String userId;

  const ProfileDisplayView({
    super.key,
    required this.userId,
  });

  @override
  State<ProfileDisplayView> createState() => _ProfileDisplayViewState();
}

class _ProfileDisplayViewState extends State<ProfileDisplayView> {
  bool hasApprovedCertification = false;
  late ProfileDisplayController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(ProfileDisplayController(widget.userId));
    _checkCertificationStatus();
  }

  /// Verifica se o usuário tem certificação espiritual aprovada
  Future<void> _checkCertificationStatus() async {
    try {
      if (widget.userId.isEmpty) return;

      final hasApproved =
          await CertificationStatusHelper.hasApprovedCertification(
              widget.userId);

      if (mounted) {
        setState(() {
          hasApprovedCertification = hasApproved;
        });
      }

      EnhancedLogger.info('Certification status checked',
          tag: 'PROFILE_DISPLAY',
          data: {
            'userId': widget.userId,
            'hasApprovedCertification': hasApprovedCertification,
          });
    } catch (e) {
      EnhancedLogger.error('Error checking certification status',
          tag: 'PROFILE_DISPLAY', error: e, data: {'userId': widget.userId});
      // Em caso de erro, ocultar o selo silenciosamente
      if (mounted) {
        setState(() {
          hasApprovedCertification = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Carregando perfil...'),
              ],
            ),
          );
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  controller.errorMessage.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  child: const Text('Voltar'),
                ),
              ],
            ),
          );
        }

        final profile = controller.spiritualProfile.value;
        final user = controller.user.value;

        if (profile == null || user == null) {
          return const Center(child: Text('Perfil não encontrado'));
        }

        return CustomScrollView(
          slivers: [
            _buildAppBar(user, profile),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildPhotosSection(profile),
                  const SizedBox(height: 16),
                  _buildIdentitySection(user, profile),
                  const SizedBox(height: 16),
                  _buildBiographySection(profile),
                  const SizedBox(height: 16),
                  _buildInteractionSection(controller, profile),
                  const SizedBox(height: 16),
                  _buildSafetyWarning(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildAppBar(UsuarioModel user, SpiritualProfileModel profile) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.blue[700],
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '@${user.username ?? user.nome}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            // Selo de certificação espiritual (dourado) - visível para todos
            if (hasApprovedCertification) ...[
              const SizedBox(width: 8),
              Tooltip(
                message: 'Certificação Espiritual Aprovada',
                child: Icon(
                  Icons.verified,
                  color: Colors.amber[700],
                  size: 24,
                ),
              ),
            ],
            // Selo de preparação para os sinais (mantido)
            if (profile.hasSinaisPreparationSeal == true) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber[600],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '🏆',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ],
        ),
        centerTitle: false,
      ),
    );
  }

  Widget _buildPhotosSection(SpiritualProfileModel profile) {
    final photos = <String?>[];
    if (profile.mainPhotoUrl?.isNotEmpty == true) {
      photos.add(profile.mainPhotoUrl);
    }
    if (profile.secondaryPhoto1Url?.isNotEmpty == true) {
      photos.add(profile.secondaryPhoto1Url);
    }
    if (profile.secondaryPhoto2Url?.isNotEmpty == true) {
      photos.add(profile.secondaryPhoto2Url);
    }

    if (photos.isEmpty) {
      return const SizedBox();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📸 Fotos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              itemBuilder: (context, index) {
                return Container(
                  width: photos.length == 1 ? Get.width - 32 : 160,
                  margin: EdgeInsets.only(
                    right: index < photos.length - 1 ? 12 : 0,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: photos[index]!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.error,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentitySection(
      UsuarioModel user, SpiritualProfileModel profile) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline,
                color: Colors.blue[700],
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Identidade Espiritual',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Location and age
          if (profile.city?.isNotEmpty == true || profile.age != null) ...[
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  '${profile.city ?? ''} ${profile.age != null ? '| ${profile.age} anos' : ''}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Relationship status
          if (profile.relationshipStatus != null) ...[
            Row(
              children: [
                Icon(
                  profile.relationshipStatus == RelationshipStatus.solteiro
                      ? Icons.favorite_border
                      : Icons.favorite,
                  color:
                      profile.relationshipStatus == RelationshipStatus.solteiro
                          ? Colors.green[600]
                          : Colors.red[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _getRelationshipStatusText(profile.relationshipStatus!),
                  style: TextStyle(
                    fontSize: 16,
                    color: profile.relationshipStatus ==
                            RelationshipStatus.solteiro
                        ? Colors.green[700]
                        : Colors.red[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Deus é Pai movement
          if (profile.isDeusEPaiMember != null) ...[
            Row(
              children: [
                Icon(
                  profile.isDeusEPaiMember == true
                      ? Icons.check_circle
                      : Icons.cancel,
                  color: profile.isDeusEPaiMember == true
                      ? Colors.blue[600]
                      : Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  profile.isDeusEPaiMember == true
                      ? 'Faz parte do movimento Deus é Pai'
                      : 'Não faz parte do movimento Deus é Pai',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBiographySection(SpiritualProfileModel profile) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_stories,
                color: Colors.green[700],
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Biografia Espiritual',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Purpose
          if (profile.purpose?.isNotEmpty == true) ...[
            _buildBiographyItem(
              '🧭',
              'Meu Propósito',
              profile.purpose!,
            ),
            const SizedBox(height: 16),
          ],

          // Non-negotiable value
          if (profile.nonNegotiableValue?.isNotEmpty == true) ...[
            _buildBiographyItem(
              '📌',
              'Valor Inegociável',
              profile.nonNegotiableValue!,
            ),
            const SizedBox(height: 16),
          ],

          // Faith phrase
          if (profile.faithPhrase?.isNotEmpty == true) ...[
            _buildBiographyItem(
              '🙏',
              'Minha frase de fé',
              profile.faithPhrase!,
            ),
            const SizedBox(height: 16),
          ],

          // About me
          if (profile.aboutMe?.isNotEmpty == true) ...[
            _buildBiographyItem(
              '💬',
              'Algo sobre mim',
              profile.aboutMe!,
            ),
            const SizedBox(height: 16),
          ],

          // Ready for purposeful relationship
          if (profile.readyForPurposefulRelationship != null) ...[
            Row(
              children: [
                const Text('💕', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Relacionamento com propósito',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.readyForPurposefulRelationship == true
                            ? 'Sim, estou disposto(a)'
                            : 'Ainda não sei',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBiographyItem(String emoji, String title, String content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInteractionSection(
      ProfileDisplayController controller, SpiritualProfileModel profile) {
    // Only show interaction section if profile allows interactions and user is single
    if (!profile.allowInteractions ||
        profile.relationshipStatus != RelationshipStatus.solteiro) {
      return const SizedBox();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.favorite_outline,
                color: Colors.pink[700],
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Interações',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() {
            if (controller.hasExpressedInterest.value) {
              return _buildInterestExpressedButton();
            } else if (controller.hasMutualInterest.value) {
              return _buildMutualInterestButtons(controller);
            } else {
              return _buildExpressInterestButton(controller);
            }
          }),
        ],
      ),
    );
  }

  Widget _buildExpressInterestButton(ProfileDisplayController controller) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: controller.isProcessingInterest.value
            ? null
            : () => controller.expressInterest(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pink[600],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: controller.isProcessingInterest.value
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.favorite),
        label: Text(
          controller.isProcessingInterest.value
              ? 'Processando...'
              : '💕 Tenho Interesse',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildInterestExpressedButton() {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.orange[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule, color: Colors.orange[700]),
          const SizedBox(width: 8),
          Text(
            'Interesse demonstrado',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.orange[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMutualInterestButtons(ProfileDisplayController controller) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[300]!),
          ),
          child: Row(
            children: [
              Icon(Icons.favorite, color: Colors.green[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '💕 Interesse mútuo!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () => controller.startTemporaryChat(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.chat),
            label: const Text(
              '💬 Conhecer Melhor',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSafetyWarning() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.security,
            color: Colors.amber[700],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '⚠️ Este app é um terreno sagrado. Conexões aqui devem honrar Deus.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.amber[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRelationshipStatusText(RelationshipStatus status) {
    switch (status) {
      case RelationshipStatus.solteiro:
        return '🟢 Solteiro';
      case RelationshipStatus.solteira:
        return '🟢 Solteira';
      case RelationshipStatus.comprometido:
        return '🔴 Comprometido';
      case RelationshipStatus.comprometida:
        return '🔴 Comprometida';
      case RelationshipStatus.naoInformado:
        return '⚪ Não informado';
    }
  }
}
