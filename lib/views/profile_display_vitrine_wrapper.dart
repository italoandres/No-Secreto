import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/vitrine_demo_controller.dart';
import '../models/spiritual_profile_model.dart';
import '../repositories/spiritual_profile_repository.dart';
import '../theme.dart';
import '../utils/enhanced_logger.dart';
import '../components/profile_header_section.dart';
import '../components/basic_info_section.dart';
import '../components/spiritual_info_section.dart';
import '../components/relationship_status_section.dart';
import '../components/interest_button_component.dart';

/// Wrapper para visualização de perfil de vitrine na busca
class ProfileDisplayVitrineWrapper extends StatefulWidget {
  final String userId;

  const ProfileDisplayVitrineWrapper({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<ProfileDisplayVitrineWrapper> createState() =>
      _ProfileDisplayVitrineWrapperState();
}

class _ProfileDisplayVitrineWrapperState
    extends State<ProfileDisplayVitrineWrapper> {
  final VitrineDemoController controller = Get.put(VitrineDemoController());

  SpiritualProfileModel? profileData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    EnhancedLogger.info('ProfileDisplayVitrineWrapper initState called',
        tag: 'PROFILE_DISPLAY_VITRINE', data: {'userId': widget.userId});
    _loadVitrineData();
  }

  Future<void> _loadVitrineData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      EnhancedLogger.info('Loading vitrine data for user',
          tag: 'PROFILE_DISPLAY_VITRINE', data: {'userId': widget.userId});

      final profile =
          await SpiritualProfileRepository.getProfileByUserId(widget.userId);

      if (profile == null) {
        setState(() {
          errorMessage = 'Perfil de vitrine não encontrado';
          isLoading = false;
        });
        return;
      }

      setState(() {
        profileData = profile;
        isLoading = false;
      });

      EnhancedLogger.info('Vitrine data loaded successfully',
          tag: 'PROFILE_DISPLAY_VITRINE',
          data: {
            'userId': widget.userId,
            'profileId': profile.id,
            'displayName': profile.displayName,
          });
    } catch (e, stackTrace) {
      EnhancedLogger.error('Error loading vitrine data',
          tag: 'PROFILE_DISPLAY_VITRINE',
          data: {'userId': widget.userId, 'error': e.toString()},
          stackTrace: stackTrace);

      setState(() {
        errorMessage = 'Erro ao carregar perfil: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Text(
          profileData?.displayName ?? 'Perfil',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
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

    if (errorMessage != null) {
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
              errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadVitrineData,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (profileData == null) {
      return const Center(
        child: Text('Perfil não encontrado'),
      );
    }

    return _buildVitrineContent();
  }

  Widget _buildVitrineContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header com foto e informações básicas
          ProfileHeaderSection(
            photoUrl: profileData!.mainPhotoUrl,
            displayName: profileData!.displayName ?? 'Usuário',
            hasVerification: true,
            username: profileData!.username,
          ),

          const SizedBox(height: 24),

          // Informações básicas
          BasicInfoSection(
            city: profileData!.city,
            fullLocation:
                '${profileData!.city ?? ''} - ${profileData!.state ?? ''}'
                    .trim(),
            age: profileData!.age,
            isDeusEPaiMember: true, // Assumir que perfis de vitrine são membros
          ),

          const SizedBox(height: 24),

          // Informações espirituais
          SpiritualInfoSection(
            purpose: profileData!.purpose ?? profileData!.aboutMe,
            faithPhrase: profileData!.faithPhrase,
            readyForPurposefulRelationship:
                profileData!.readyForPurposefulRelationship,
            nonNegotiableValue: profileData!.nonNegotiableValue,
          ),

          const SizedBox(height: 24),

          // Status de relacionamento
          RelationshipStatusSection(
            relationshipStatus: profileData!.relationshipStatus,
            hasChildren: profileData!.hasChildren,
            childrenDetails:
                profileData!.hasChildren == true ? 'Tem filhos' : null,
            isVirgin: null, // Não expor informação sensível
            wasPreviouslyMarried: null, // Não expor informação sensível
          ),

          const SizedBox(height: 32),

          // Botão de interesse (apenas se não for o próprio perfil)
          InterestButtonComponent(
            targetUserId: widget.userId,
            targetUserName: 'Usuário', // Será obtido dinamicamente
            targetUserEmail: 'usuario@exemplo.com', // Será obtido dinamicamente
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
