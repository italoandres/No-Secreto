import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vitrine_status_model.dart';
import '../models/demo_experience_model.dart';
import '../services/vitrine_share_service.dart';
import '../utils/enhanced_logger.dart';

/// Controller para gerenciar a experiência de demonstração da vitrine de propósito
class VitrineDemoController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final VitrineShareService _shareService = VitrineShareService();

  // Estado reativo da vitrine
  final RxBool isVitrineActive = true.obs;
  final RxBool isLoading = false.obs;
  final Rx<VitrineStatus> vitrineStatus = VitrineStatus.active.obs;
  final RxString currentUserId = ''.obs;

  // Estado da experiência de demonstração
  final RxBool hasViewedVitrine = false.obs;
  final RxBool hasSharedVitrine = false.obs;
  final RxInt viewCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    EnhancedLogger.info('VitrineDemoController initialized',
        tag: 'VITRINE_DEMO');
  }

  /// Inicia a experiência de demonstração após completar o perfil
  Future<void> showDemoExperience(String userId) async {
    try {
      isLoading.value = true;
      currentUserId.value = userId;

      EnhancedLogger.info('Starting demo experience',
          tag: 'VITRINE_DEMO', data: {'userId': userId});

      // Carregar status atual da vitrine
      await _loadVitrineStatus(userId);

      // Registrar início da experiência
      await _trackDemoStart(userId);

      // Navegar para tela de confirmação
      Get.toNamed('/vitrine-confirmation', arguments: {'userId': userId});
    } catch (e, stackTrace) {
      EnhancedLogger.error('Failed to start demo experience',
          tag: 'VITRINE_DEMO',
          error: e,
          stackTrace: stackTrace,
          data: {'userId': userId});

      // Mostrar erro para o usuário
      Get.snackbar(
        'Erro',
        'Não foi possível carregar a demonstração da vitrine',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Alterna o status da vitrine (ativa/inativa)
  Future<void> toggleVitrineStatus() async {
    try {
      isLoading.value = true;
      final userId = currentUserId.value;

      if (userId.isEmpty) {
        throw Exception('User ID not found');
      }

      final newStatus =
          isVitrineActive.value ? VitrineStatus.inactive : VitrineStatus.active;

      EnhancedLogger.info('Toggling vitrine status',
          tag: 'VITRINE_DEMO',
          data: {
            'userId': userId,
            'currentStatus': vitrineStatus.value.toString(),
            'newStatus': newStatus.toString(),
          });

      // Atualizar status no Firestore
      await _updateVitrineStatus(userId, newStatus);

      // Atualizar estado local
      vitrineStatus.value = newStatus;
      isVitrineActive.value = newStatus == VitrineStatus.active;

      // Registrar mudança para analytics
      await _trackStatusToggle(userId, newStatus);

      // Mostrar feedback para o usuário
      Get.snackbar(
        'Status atualizado',
        newStatus == VitrineStatus.active
            ? 'Sua vitrine está agora pública'
            : 'Sua vitrine está agora privada',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e, stackTrace) {
      EnhancedLogger.error('Failed to toggle vitrine status',
          tag: 'VITRINE_DEMO',
          error: e,
          stackTrace: stackTrace,
          data: {'userId': currentUserId.value});

      Get.snackbar(
        'Erro',
        'Não foi possível alterar o status da vitrine',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Navega para a visualização da vitrine
  Future<void> navigateToVitrineView() async {
    try {
      final userId = currentUserId.value;

      if (userId.isEmpty) {
        throw Exception('User ID not found');
      }

      EnhancedLogger.info('Navigating to vitrine view',
          tag: 'VITRINE_DEMO', data: {'userId': userId});

      // Registrar visualização
      if (!hasViewedVitrine.value) {
        await _trackFirstVitrineView(userId);
        hasViewedVitrine.value = true;
      }

      viewCount.value++;

      // Navegar para visualização da vitrine
      Get.toNamed('/vitrine-display', arguments: {
        'userId': userId,
        'isOwnProfile': true,
      });
    } catch (e, stackTrace) {
      EnhancedLogger.error('Failed to navigate to vitrine view',
          tag: 'VITRINE_DEMO',
          error: e,
          stackTrace: stackTrace,
          data: {'userId': currentUserId.value});

      Get.snackbar(
        'Erro',
        'Não foi possível abrir a vitrine',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Gera link de compartilhamento da vitrine
  Future<String> generateShareLink() async {
    try {
      final userId = currentUserId.value;

      if (userId.isEmpty) {
        throw Exception('User ID not found');
      }

      if (!isVitrineActive.value) {
        throw Exception('Cannot share inactive vitrine');
      }

      EnhancedLogger.info('Generating share link',
          tag: 'VITRINE_DEMO', data: {'userId': userId});

      final shareLink = await _shareService.generatePublicLink(userId);

      EnhancedLogger.success('Share link generated',
          tag: 'VITRINE_DEMO', data: {'userId': userId, 'link': shareLink});

      return shareLink;
    } catch (e, stackTrace) {
      EnhancedLogger.error('Failed to generate share link',
          tag: 'VITRINE_DEMO',
          error: e,
          stackTrace: stackTrace,
          data: {'userId': currentUserId.value});

      rethrow;
    }
  }

  /// Carrega o status atual da vitrine do Firestore
  Future<void> _loadVitrineStatus(String userId) async {
    try {
      final doc =
          await _firestore.collection('vitrine_status').doc(userId).get();

      if (doc.exists) {
        final statusInfo = VitrineStatusInfo.fromFirestore(doc.data()!);
        vitrineStatus.value = statusInfo.status;
        isVitrineActive.value = statusInfo.isPubliclyVisible;

        EnhancedLogger.info('Vitrine status loaded',
            tag: 'VITRINE_DEMO',
            data: {
              'userId': userId,
              'status': statusInfo.status.toString(),
              'isActive': statusInfo.isPubliclyVisible,
            });
      } else {
        // Criar status padrão se não existir
        await _createDefaultVitrineStatus(userId);
      }
    } catch (e, stackTrace) {
      EnhancedLogger.error('Failed to load vitrine status',
          tag: 'VITRINE_DEMO',
          error: e,
          stackTrace: stackTrace,
          data: {'userId': userId});

      // Usar valores padrão em caso de erro
      vitrineStatus.value = VitrineStatus.active;
      isVitrineActive.value = true;
    }
  }

  /// Cria status padrão da vitrine para novos usuários
  Future<void> _createDefaultVitrineStatus(String userId) async {
    final defaultStatus = VitrineStatusInfo(
      userId: userId,
      status: VitrineStatus.active,
      lastUpdated: DateTime.now(),
      reason: 'Initial creation',
    );

    await _firestore
        .collection('vitrine_status')
        .doc(userId)
        .set(defaultStatus.toFirestore());

    vitrineStatus.value = VitrineStatus.active;
    isVitrineActive.value = true;

    EnhancedLogger.info('Default vitrine status created',
        tag: 'VITRINE_DEMO', data: {'userId': userId});
  }

  /// Atualiza o status da vitrine no Firestore
  Future<void> _updateVitrineStatus(
      String userId, VitrineStatus newStatus) async {
    final statusInfo = VitrineStatusInfo(
      userId: userId,
      status: newStatus,
      lastUpdated: DateTime.now(),
      reason: 'User toggle',
    );

    await _firestore
        .collection('vitrine_status')
        .doc(userId)
        .set(statusInfo.toFirestore(), SetOptions(merge: true));
  }

  /// Registra início da experiência de demonstração
  Future<void> _trackDemoStart(String userId) async {
    try {
      final demoData = DemoExperienceData(
        userId: userId,
        completionTime: DateTime.now(),
        hasViewedVitrine: false,
        hasSharedVitrine: false,
        viewCount: 0,
        actionsPerformed: ['demo_started'],
      );

      await _firestore
          .collection('demo_experiences')
          .doc(userId)
          .set(demoData.toFirestore(), SetOptions(merge: true));
    } catch (e, stackTrace) {
      EnhancedLogger.error('Failed to track demo start',
          tag: 'VITRINE_DEMO',
          error: e,
          stackTrace: stackTrace,
          data: {'userId': userId});
    }
  }

  /// Registra primeira visualização da vitrine
  Future<void> _trackFirstVitrineView(String userId) async {
    try {
      await _firestore.collection('demo_experiences').doc(userId).update({
        'hasViewedVitrine': true,
        'firstViewTime': Timestamp.now(),
        'actionsPerformed': FieldValue.arrayUnion(['first_view']),
      });
    } catch (e, stackTrace) {
      EnhancedLogger.error('Failed to track first vitrine view',
          tag: 'VITRINE_DEMO',
          error: e,
          stackTrace: stackTrace,
          data: {'userId': userId});
    }
  }

  /// Registra mudança de status para analytics
  Future<void> _trackStatusToggle(
      String userId, VitrineStatus newStatus) async {
    try {
      await _firestore.collection('demo_experiences').doc(userId).update({
        'lastStatusChange': Timestamp.now(),
        'currentStatus': newStatus.toString(),
        'actionsPerformed': FieldValue.arrayUnion(['status_toggle']),
      });
    } catch (e, stackTrace) {
      EnhancedLogger.error('Failed to track status toggle',
          tag: 'VITRINE_DEMO',
          error: e,
          stackTrace: stackTrace,
          data: {'userId': userId, 'newStatus': newStatus.toString()});
    }
  }

  /// Registra ação de compartilhamento
  void trackShareAction(String shareType) {
    try {
      final userId = currentUserId.value;

      if (userId.isNotEmpty) {
        hasSharedVitrine.value = true;

        _firestore.collection('demo_experiences').doc(userId).update({
          'hasSharedVitrine': true,
          'lastShareTime': Timestamp.now(),
          'shareType': shareType,
          'actionsPerformed': FieldValue.arrayUnion(['share_$shareType']),
        });
      }
    } catch (e, stackTrace) {
      EnhancedLogger.error('Failed to track share action',
          tag: 'VITRINE_DEMO',
          error: e,
          stackTrace: stackTrace,
          data: {'userId': currentUserId.value, 'shareType': shareType});
    }
  }
}
