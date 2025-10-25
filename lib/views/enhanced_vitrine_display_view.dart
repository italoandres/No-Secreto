import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/vitrine_demo_controller.dart';
import '../models/spiritual_profile_model.dart';
import '../models/share_configuration_model.dart';
import '../services/vitrine_share_service.dart';
import '../repositories/spiritual_profile_repository.dart';
import '../repositories/interest_notification_repository.dart';
import '../theme.dart';
import '../utils/enhanced_logger.dart';
import '../utils/certification_status_helper.dart';
import '../components/profile_header_section.dart';
import '../components/basic_info_section.dart';
import '../components/spiritual_info_section.dart';
import '../components/relationship_status_section.dart';
import '../components/interest_button_component.dart';
import '../components/location_info_section.dart';
import '../components/education_info_section.dart';
import '../components/lifestyle_info_section.dart';
import '../components/hobbies_section.dart';
import '../components/languages_section.dart';
import '../components/photo_gallery_section.dart';

/// Tela de visualização aprimorada da vitrine de propósito
class EnhancedVitrineDisplayView extends StatefulWidget {
  const EnhancedVitrineDisplayView({Key? key}) : super(key: key);

  @override
  State<EnhancedVitrineDisplayView> createState() =>
      _EnhancedVitrineDisplayViewState();
}

class _EnhancedVitrineDisplayViewState
    extends State<EnhancedVitrineDisplayView> {
  final VitrineDemoController controller = Get.put(VitrineDemoController());
  final VitrineShareService shareService = VitrineShareService();

  String? userId;
  bool isOwnProfile = false;
  bool fromCelebration = false;
  String? interestStatus; // 'pending', 'accepted', 'rejected', null
  SpiritualProfileModel? profileData;
  bool isLoading = true;
  String? errorMessage;
  bool hasApprovedCertification = false;

  @override
  void initState() {
    super.initState();
    EnhancedLogger.info('EnhancedVitrineDisplayView initState called',
        tag: 'VITRINE_DISPLAY');
    _initializeData();
  }

  /// Helper para obter currentUserId com fallback para Firebase Auth
  String _getCurrentUserId() {
    String currentUserId = controller.currentUserId.value;

    if (currentUserId.isEmpty) {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        currentUserId = firebaseUser.uid;
        EnhancedLogger.info('Usando Firebase Auth como fallback',
            tag: 'VITRINE_DISPLAY', data: {'currentUserId': currentUserId});
      }
    }

    return currentUserId;
  }

  void _initializeData() {
    final arguments = Get.arguments as Map<String, dynamic>? ?? {};

    // Tentar pegar userId dos argumentos ou do controller com fallback para Firebase Auth
    userId = arguments['userId'] as String? ?? _getCurrentUserId();
    isOwnProfile = arguments['isOwnProfile'] as bool? ?? true;
    interestStatus = arguments['interestStatus'] as String?;

    EnhancedLogger.info('Argumentos recebidos', tag: 'VITRINE_DISPLAY', data: {
      'userId': userId,
      'isOwnProfile': isOwnProfile,
      'interestStatus': interestStatus,
    });
    fromCelebration = arguments['fromCelebration'] as bool? ?? false;

    EnhancedLogger.info('Initializing vitrine data',
        tag: 'VITRINE_DISPLAY',
        data: {
          'userId': userId,
          'isOwnProfile': isOwnProfile,
          'fromCelebration': fromCelebration,
          'arguments': arguments,
          'controllerUserId': controller.currentUserId.value,
          'willShowButton': !isOwnProfile,
        });

    if (userId?.isNotEmpty == true) {
      _loadVitrineData();
    } else {
      EnhancedLogger.error('User ID not found',
          tag: 'VITRINE_DISPLAY', data: {'userId': userId});
      setState(() {
        errorMessage = 'ID do usuário não encontrado';
        isLoading = false;
      });
    }
  }

  Future<void> _loadVitrineData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      EnhancedLogger.info('Loading vitrine data',
          tag: 'VITRINE_DISPLAY',
          data: {'userId': userId, 'isOwnProfile': isOwnProfile});

      // Usar o repositório para buscar o perfil corretamente
      EnhancedLogger.info('Searching for profile',
          tag: 'VITRINE_DISPLAY',
          data: {'userId': userId, 'searchMethod': 'getProfileByUserId'});

      profileData =
          await SpiritualProfileRepository.getProfileByUserId(userId!);

      if (profileData != null) {
        EnhancedLogger.success('Vitrine data loaded successfully',
            tag: 'VITRINE_DISPLAY',
            data: {
              'userId': userId,
              'hasData': profileData != null,
              'profileId': profileData!.id,
              'profileName': profileData!.displayName,
              'isComplete': profileData!.isProfileComplete
            });

        // Verificar se tem certificação aprovada
        await _checkCertificationStatus();

        // Se interestStatus não foi fornecido, verificar dinamicamente
        if (interestStatus == null && !isOwnProfile) {
          await _checkInterestStatus();
        }
      } else {
        // Tentar buscar usando o método alternativo
        EnhancedLogger.warning(
            'Profile not found with getProfileByUserId, trying getOrCreateCurrentUserProfile',
            tag: 'VITRINE_DISPLAY',
            data: {'userId': userId});

        try {
          profileData =
              await SpiritualProfileRepository.getOrCreateCurrentUserProfile();

          if (profileData != null && profileData!.userId == userId) {
            EnhancedLogger.success('Profile found with alternative method',
                tag: 'VITRINE_DISPLAY',
                data: {
                  'userId': userId,
                  'profileId': profileData!.id,
                  'method': 'getOrCreateCurrentUserProfile'
                });
          } else {
            profileData = null;
            errorMessage = 'Perfil não encontrado';

            EnhancedLogger.error('Profile not found with any method',
                tag: 'VITRINE_DISPLAY',
                data: {
                  'userId': userId,
                  'alternativeProfileUserId': profileData?.userId,
                  'alternativeProfileId': profileData?.id
                });
          }
        } catch (e) {
          errorMessage = 'Erro ao buscar perfil';

          EnhancedLogger.error('Error searching for profile',
              tag: 'VITRINE_DISPLAY', error: e, data: {'userId': userId});
        }
      }
    } catch (e, stackTrace) {
      errorMessage = 'Erro ao carregar vitrine';

      EnhancedLogger.error('Failed to load vitrine data',
          tag: 'VITRINE_DISPLAY',
          error: e,
          stackTrace: stackTrace,
          data: {'userId': userId});
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Verifica se o usuário tem certificação espiritual aprovada
  Future<void> _checkCertificationStatus() async {
    try {
      if (userId == null || userId!.isEmpty) return;

      // Usar o helper que já funciona corretamente
      final hasApproved =
          await CertificationStatusHelper.hasApprovedCertification(userId!);

      if (mounted) {
        setState(() {
          hasApprovedCertification = hasApproved;
        });
      }

      EnhancedLogger.info('Certification status checked',
          tag: 'VITRINE_DISPLAY',
          data: {
            'userId': userId,
            'hasApprovedCertification': hasApprovedCertification,
          });
    } catch (e) {
      EnhancedLogger.error('Error checking certification status',
          tag: 'VITRINE_DISPLAY', error: e, data: {'userId': userId});
      // Em caso de erro, não mostrar o selo
      if (mounted) {
        setState(() {
          hasApprovedCertification = false;
        });
      }
    }
  }

  /// Verifica dinamicamente o status do interesse entre os usuários
  Future<void> _checkInterestStatus() async {
    try {
      final currentUserId = _getCurrentUserId();

      if (currentUserId.isEmpty || userId == null || userId!.isEmpty) {
        return;
      }

      EnhancedLogger.info('Checking interest status dynamically',
          tag: 'VITRINE_DISPLAY',
          data: {
            'currentUserId': currentUserId,
            'targetUserId': userId,
          });

      // Verificar se existe chat entre os usuários (indica match)
      final sortedIds = [currentUserId, userId!]..sort();
      final chatId = 'match_${sortedIds[0]}_${sortedIds[1]}';

      final chatDoc = await FirebaseFirestore.instance
          .collection('match_chats')
          .doc(chatId)
          .get();

      if (chatDoc.exists) {
        // Existe chat = match confirmado
        if (mounted) {
          setState(() {
            interestStatus = 'accepted';
          });
        }

        EnhancedLogger.info('Match found - chat exists',
            tag: 'VITRINE_DISPLAY',
            data: {
              'chatId': chatId,
              'interestStatus': 'accepted',
            });
        return;
      }

      // Verificar se existe notificação de interesse
      final notifications = await FirebaseFirestore.instance
          .collection('interest_notifications')
          .where('fromUserId', isEqualTo: userId)
          .where('toUserId', isEqualTo: currentUserId)
          .where('status', whereIn: ['pending', 'viewed', 'new'])
          .limit(1)
          .get();

      if (notifications.docs.isNotEmpty) {
        // Existe interesse pendente do outro usuário
        if (mounted) {
          setState(() {
            interestStatus = 'pending';
          });
        }

        EnhancedLogger.info('Pending interest found',
            tag: 'VITRINE_DISPLAY',
            data: {
              'notificationId': notifications.docs.first.id,
              'interestStatus': 'pending',
            });
        return;
      }

      // Verificar se o usuário atual já enviou interesse
      final sentInterest = await FirebaseFirestore.instance
          .collection('interest_notifications')
          .where('fromUserId', isEqualTo: currentUserId)
          .where('toUserId', isEqualTo: userId)
          .where('status', whereIn: ['pending', 'viewed', 'new'])
          .limit(1)
          .get();

      if (sentInterest.docs.isNotEmpty) {
        // Usuário atual já enviou interesse
        if (mounted) {
          setState(() {
            interestStatus = 'sent';
          });
        }

        EnhancedLogger.info('Interest already sent',
            tag: 'VITRINE_DISPLAY',
            data: {
              'notificationId': sentInterest.docs.first.id,
              'interestStatus': 'sent',
            });
        return;
      }

      // Nenhum interesse encontrado
      if (mounted) {
        setState(() {
          interestStatus = null;
        });
      }

      EnhancedLogger.info('No interest found', tag: 'VITRINE_DISPLAY', data: {
        'interestStatus': null,
      });
    } catch (e) {
      EnhancedLogger.error('Error checking interest status',
          tag: 'VITRINE_DISPLAY',
          error: e,
          data: {
            'currentUserId': _getCurrentUserId(),
            'targetUserId': userId,
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar AppBar se vier da celebration OU se for visualização como visitante
    final shouldShowAppBar = fromCelebration || !isOwnProfile;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: shouldShowAppBar
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => Get.back(),
                tooltip: 'Voltar',
              ),
              title: Text(
                fromCelebration
                    ? 'Minha Vitrine'
                    : 'Visualização como Visitante',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              if (isOwnProfile && !fromCelebration) _buildOwnProfileBanner(),
              Expanded(
                child: isLoading
                    ? _buildLoadingState()
                    : errorMessage != null
                        ? _buildErrorState()
                        : _buildVitrineContent(),
              ),
            ],
          ),

          // Fixed bottom button
          if (!isLoading && errorMessage == null && profileData != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: _buildActionButton(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Banner indicando visualização própria
  Widget _buildOwnProfileBanner() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            border: Border(
              bottom: BorderSide(color: AppColors.info, width: 2),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                Icon(Icons.preview, color: AppColors.info, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Você está visualizando sua vitrine como outros a verão',
                    style: TextStyle(
                      color: AppColors.info,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                // Botão para testar como visitante
                TextButton.icon(
                  onPressed: () {
                    // Recarregar a vitrine como se fosse outro usuário
                    Get.off(() => const EnhancedVitrineDisplayView(),
                        arguments: {
                          'userId': userId,
                          'isOwnProfile': false, // Simular como visitante
                        });
                  },
                  icon: Icon(Icons.visibility, color: AppColors.info, size: 16),
                  label: Text(
                    'Ver como visitante',
                    style: TextStyle(
                      color: AppColors.info,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Botão de voltar para ProfileCompletionView
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: OutlinedButton.icon(
            onPressed: () {
              EnhancedLogger.info(
                  'Returning to ProfileCompletionView from vitrine',
                  tag: 'VITRINE_DISPLAY',
                  data: {'userId': userId});
              Get.back();
            },
            icon: Icon(Icons.arrow_back, size: 18),
            label: Text('Voltar para Vitrine de Propósito'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  /// Estado de carregamento
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Carregando vitrine...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// Estado de erro
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Ops! Algo deu errado',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Erro desconhecido',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadVitrineData,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Conteúdo principal da vitrine
  Widget _buildVitrineContent() {
    if (profileData == null) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header Section
          ProfileHeaderSection(
            photoUrl: profileData!.mainPhotoUrl,
            displayName: profileData!.displayName ?? 'Usuário',
            hasVerification:
                hasApprovedCertification, // Apenas se certificação aprovada
            username: profileData!.username,
          ),

          // Photo Gallery Section (MOVIDO PARA CIMA - logo abaixo do nome/@)
          PhotoGallerySection(
            mainPhotoUrl: profileData!.mainPhotoUrl,
            secondaryPhoto1Url: profileData!.secondaryPhoto1Url,
            secondaryPhoto2Url: profileData!.secondaryPhoto2Url,
          ),
          const SizedBox(height: 16),

          // Location Info Section (NOVO)
          LocationInfoSection(
            city: profileData!.city,
            state: profileData!.state,
            fullLocation: profileData!.fullLocation,
            country: profileData!.country,
          ),
          const SizedBox(height: 24),

          // Basic Info Section
          BasicInfoSection(
            city: profileData!.city,
            fullLocation: profileData!.fullLocation,
            age: profileData!.age,
            isDeusEPaiMember: profileData!.isDeusEPaiMember,
          ),
          const SizedBox(height: 24),

          // Languages Section (NOVO)
          LanguagesSection(
            languages: profileData!.languages,
          ),
          const SizedBox(height: 24),

          // Spiritual Info Section
          SpiritualInfoSection(
            purpose: profileData!.purpose,
            faithPhrase: profileData!.faithPhrase,
            readyForPurposefulRelationship:
                profileData!.readyForPurposefulRelationship,
            nonNegotiableValue: profileData!.nonNegotiableValue,
          ),
          const SizedBox(height: 24),

          // Education Info Section (NOVO)
          EducationInfoSection(
            education: profileData!.education,
            universityCourse: profileData!.universityCourse,
            courseStatus: profileData!.courseStatus,
            university: profileData!.university,
            occupation: profileData!.occupation,
          ),
          const SizedBox(height: 24),

          // Lifestyle Info Section (NOVO)
          LifestyleInfoSection(
            height: profileData!.height,
            smokingStatus: profileData!.smokingStatus,
            drinkingStatus: profileData!.drinkingStatus,
          ),
          const SizedBox(height: 24),

          // Hobbies Section (NOVO)
          HobbiesSection(
            hobbies: profileData!.hobbies,
          ),
          const SizedBox(height: 24),

          // Relationship Status Section (com isVirgin)
          RelationshipStatusSection(
            relationshipStatus: profileData!.relationshipStatus,
            hasChildren: profileData!.hasChildren,
            childrenDetails: profileData!.childrenDetails,
            isVirgin: profileData!.isVirgin, // Agora público
            wasPreviouslyMarried: profileData!.wasPreviouslyMarried,
          ),
          const SizedBox(height: 24),

          // Additional Info (About Me)
          if (profileData!.aboutMe?.isNotEmpty == true) ...[
            _buildAdditionalInfoSection(),
            const SizedBox(height: 24),
          ],

          const SizedBox(height: 100), // Espaço para botão fixo inferior
        ],
      ),
    );
  }

  /// Estado vazio
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Vitrine em construção',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete seu perfil para que outros possam conhecê-lo melhor',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (isOwnProfile) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Get.toNamed('/profile-completion'),
                icon: const Icon(Icons.edit),
                label: const Text('Completar perfil'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Header da vitrine com foto e informações básicas
  Widget _buildVitrineHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Foto de perfil
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.1),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: profileData?.mainPhotoUrl?.isNotEmpty == true
                ? ClipOval(
                    child: Image.network(
                      profileData!.mainPhotoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDefaultAvatar();
                      },
                    ),
                  )
                : _buildDefaultAvatar(),
          ),
          const SizedBox(height: 16),
          // Nome
          Text(
            profileData?.displayName ?? 'Nome não informado',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Username
          if (profileData?.username?.isNotEmpty == true)
            Text(
              '@${profileData!.username}',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  /// Avatar padrão com iniciais
  Widget _buildDefaultAvatar() {
    final name = profileData?.displayName ?? 'U';
    final initials = name
        .split(' ')
        .map((n) => n.isNotEmpty ? n[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// Seção de propósito
  Widget _buildPurposeSection() {
    final purpose = profileData?.purpose;

    if (purpose?.isEmpty != false) {
      return _buildMissingSection(
        'Propósito de Vida',
        'O propósito ainda não foi compartilhado',
        Icons.favorite_outline,
      );
    }

    return _buildSection(
      'Propósito de Vida',
      purpose!,
      Icons.favorite,
      AppColors.primary,
    );
  }

  /// Seção de biografia
  Widget _buildBiographySection() {
    final biography = profileData?.aboutMe;

    if (biography?.isEmpty != false) {
      return _buildMissingSection(
        'Sobre mim',
        'A biografia ainda não foi compartilhada',
        Icons.person_outline,
      );
    }

    return _buildSection(
      'Sobre mim',
      biography!,
      Icons.person,
      AppColors.secondary,
    );
  }

  /// Seção genérica
  Widget _buildSection(
      String title, String content, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Seção para dados faltantes
  Widget _buildMissingSection(String title, String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.grey, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
          if (isOwnProfile) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => Get.toNamed('/profile-completion'),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Adicionar'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Galeria de fotos
  Widget _buildPhotoGallery() {
    // Placeholder para galeria de fotos
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.photo_library,
                    color: AppColors.accent, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Galeria',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo, color: Colors.grey, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'Nenhuma foto adicionada',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Seção de informações adicionais (Sobre mim)
  Widget _buildAdditionalInfoSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sobre Mim',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.person,
                        color: Colors.purple[600],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Algo que gostaria que soubessem',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  profileData!.aboutMe!,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF333333),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Seção de contato/interesse
  Widget _buildContactSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.connect_without_contact,
                    color: AppColors.success, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Conectar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!isOwnProfile) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Implementar lógica de conexão
                  Get.snackbar(
                    'Em breve',
                    'Funcionalidade de conexão será implementada em breve',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
                icon: const Icon(Icons.message),
                label: const Text('Enviar mensagem'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ] else ...[
            Text(
              'Outros usuários poderão se conectar com você através desta vitrine',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Barra de ações
  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Status indicator
            _buildStatusChip(),
            const Spacer(),
            // Botão voltar
            IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Voltar',
            ),
            if (isOwnProfile) ...[
              // Share button
              IconButton(
                onPressed: _showShareOptions,
                icon: const Icon(Icons.share),
                tooltip: 'Compartilhar vitrine',
              ),
              // Edit button
              IconButton(
                onPressed: () => Get.toNamed('/profile-completion'),
                icon: const Icon(Icons.edit),
                tooltip: 'Editar vitrine',
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Chip de status
  Widget _buildStatusChip() {
    return Obx(() {
      final isActive = controller.isVitrineActive.value;
      return Chip(
        avatar: Icon(
          isActive ? Icons.public : Icons.public_off,
          size: 16,
          color: isActive ? AppColors.success : Colors.grey,
        ),
        label: Text(
          isActive ? 'Pública' : 'Privada',
          style: TextStyle(
            color: isActive ? AppColors.success : Colors.grey,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        backgroundColor: isActive
            ? AppColors.success.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
      );
    });
  }

  /// Mostra opções de compartilhamento
  void _showShareOptions() {
    if (!controller.isVitrineActive.value) {
      Get.snackbar(
        'Vitrine inativa',
        'Ative sua vitrine para poder compartilhá-la',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Compartilhar Vitrine',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: ShareType.values.map((type) {
                return _buildShareOption(type);
              }).toList(),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }

  /// Opção de compartilhamento
  Widget _buildShareOption(ShareType type) {
    return GestureDetector(
      onTap: () async {
        Get.back();

        try {
          if (type == ShareType.link) {
            final link = await controller.generateShareLink();
            await shareService.copyLinkToClipboard(link);
            Get.snackbar(
              'Link copiado',
              'O link da sua vitrine foi copiado para a área de transferência',
              snackPosition: SnackPosition.BOTTOM,
            );
          } else {
            await shareService.shareVitrine(userId!, type);
          }

          controller.trackShareAction(type.toString());
        } catch (e) {
          Get.snackbar(
            'Erro',
            'Não foi possível compartilhar a vitrine',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      },
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              _getShareIcon(type),
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              type.displayName,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Ícone para tipo de compartilhamento
  IconData _getShareIcon(ShareType type) {
    switch (type) {
      case ShareType.link:
        return Icons.link;
      case ShareType.whatsapp:
        return Icons.message;
      case ShareType.instagram:
        return Icons.camera_alt;
      case ShareType.facebook:
        return Icons.facebook;
      case ShareType.email:
        return Icons.email;
      case ShareType.sms:
        return Icons.sms;
    }
  }

  /// Construir botão de ação baseado no contexto
  Widget _buildActionButton() {
    // Se já tem match (interesse aceito), mostrar botão de conversar
    if (interestStatus == 'accepted' || interestStatus == 'mutual_match') {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: _navigateToChat,
          icon: const Icon(Icons.chat),
          label: const Text('Conversar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
        ),
      );
    }

    // Se é notificação pendente, mostrar botão "Também Tenho"
    if (interestStatus == 'pending' ||
        interestStatus == 'viewed' ||
        interestStatus == 'new') {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: _respondWithInterest,
          icon: const Icon(Icons.favorite),
          label: const Text('Também Tenho'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pink,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
        ),
      );
    }

    // Caso padrão: botão de demonstrar interesse
    return Padding(
      padding: const EdgeInsets.all(16),
      child: InterestButtonComponent(
        targetUserId: profileData!.userId!,
        targetUserName: 'Usuário',
        targetUserEmail: 'usuario@exemplo.com',
      ),
    );
  }

  /// Navegar para chat
  void _navigateToChat() {
    if (userId == null) return;

    // Obter currentUserId com fallback para Firebase Auth
    final currentUserId = _getCurrentUserId();

    // Validar currentUserId
    if (currentUserId.isEmpty) {
      EnhancedLogger.error('currentUserId está vazio mesmo com fallback!',
          tag: 'VITRINE_DISPLAY');
      Get.snackbar(
        'Erro',
        'Não foi possível identificar seu usuário',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    EnhancedLogger.info('Gerando chatId', tag: 'VITRINE_DISPLAY', data: {
      'currentUserId': currentUserId,
      'otherUserId': userId,
    });

    final sortedIds = [currentUserId, userId!]..sort();
    final chatId = 'match_${sortedIds[0]}_${sortedIds[1]}';

    EnhancedLogger.info('Navegando para match-chat',
        tag: 'VITRINE_DISPLAY',
        data: {
          'chatId': chatId,
          'currentUserId': currentUserId,
          'otherUserId': userId,
        });

    Get.toNamed('/match-chat', arguments: {
      'chatId': chatId,
      'otherUserId': userId,
      'otherUserName': profileData?.displayName ?? 'Usuário',
      'otherUserPhoto': profileData?.mainPhotoUrl,
      'matchDate': DateTime.now(), // Data do match
    });
  }

  /// Responder com interesse (Também Tenho)
  void _respondWithInterest() async {
    if (userId == null) return;

    try {
      // Obter currentUserId com fallback para Firebase Auth
      final currentUserId = _getCurrentUserId();

      if (currentUserId.isEmpty) {
        EnhancedLogger.error('currentUserId está vazio mesmo com fallback!',
            tag: 'VITRINE_DISPLAY');
        Get.snackbar(
          'Erro',
          'Não foi possível identificar seu usuário',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      EnhancedLogger.info('Respondendo com interesse',
          tag: 'VITRINE_DISPLAY',
          data: {
            'fromUserId': userId,
            'toUserId': currentUserId,
          });

      // Buscar a notificação pendente
      // fromUserId = quem enviou (userId do perfil)
      // toUserId = quem recebeu (currentUserId)
      final notifications = await FirebaseFirestore.instance
          .collection('interest_notifications')
          .where('fromUserId', isEqualTo: userId)
          .where('toUserId', isEqualTo: currentUserId)
          .where('status', whereIn: ['pending', 'viewed', 'new'])
          .limit(1)
          .get();

      EnhancedLogger.info('Busca de notificação',
          tag: 'VITRINE_DISPLAY',
          data: {
            'encontradas': notifications.docs.length,
          });

      if (notifications.docs.isEmpty) {
        EnhancedLogger.error('Notificação não encontrada',
            tag: 'VITRINE_DISPLAY',
            data: {
              'fromUserId': userId,
              'toUserId': currentUserId,
            });

        Get.snackbar(
          'Erro',
          'Notificação não encontrada',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final notificationId = notifications.docs.first.id;

      EnhancedLogger.info('Respondendo notificação',
          tag: 'VITRINE_DISPLAY', data: {'notificationId': notificationId});

      // Responder com accepted
      await InterestNotificationRepository.respondToInterestNotification(
        notificationId,
        'accepted',
      );

      // Obter nome do perfil para exibir na notificação
      final profileName = profileData?.displayName ?? 'esta pessoa';

      // Mostrar notificação de match com opção de conversar
      Get.snackbar(
        '💕 Match! Interesse Aceito!',
        'Você e $profileName demonstraram interesse! Agora vocês podem conversar.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: const Icon(Icons.favorite, color: Colors.white),
        duration: const Duration(seconds: 5),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        mainButton: TextButton(
          onPressed: () {
            // Fechar snackbar
            Get.closeCurrentSnackbar();

            // Gerar ID do chat
            final sortedIds = [currentUserId, userId!]..sort();
            final chatId = 'match_${sortedIds[0]}_${sortedIds[1]}';

            // Navegar para o chat
            Get.back(); // Voltar da vitrine
            Get.toNamed('/match-chat', arguments: {
              'chatId': chatId,
              'otherUserId': userId,
              'otherUserName': profileName,
              'matchDate': DateTime.now(),
            });
          },
          child: const Text(
            'Conversar',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );

      // Voltar para o dashboard após 1 segundo (dar tempo para ver a notificação)
      Future.delayed(const Duration(seconds: 1), () {
        if (Get.isSnackbarOpen == false) {
          Get.back();
        }
      });
    } catch (e) {
      EnhancedLogger.error('Erro ao responder interesse: $e',
          tag: 'VITRINE_DISPLAY');

      Get.snackbar(
        'Erro',
        'Não foi possível responder ao interesse',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
