import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/scored_profile.dart';
import '../models/interest.dart';
import '../models/match.dart';
import '../services/weekly_recommendations_service.dart';
import '../utils/enhanced_logger.dart';

/// Controller para gerenciar estado da aba Sinais
class SinaisController extends GetxController {
  // Estado de carregamento
  final RxBool isLoading = false.obs;
  final RxBool isLoadingInterests = false.obs;
  final RxBool isLoadingMatches = false.obs;
  final RxString error = ''.obs;

  // Recomendações semanais
  final RxList<ScoredProfile> recommendations = <ScoredProfile>[].obs;
  final RxInt currentProfileIndex = 0.obs;

  // Interesses e Matches
  final RxList<Interest> pendingInterests = <Interest>[].obs;
  final RxList<Match> matches = <Match>[].obs;

  // Estatísticas
  final RxInt remainingProfiles = 0.obs;
  final RxString weekKey = ''.obs;

  // Tab atual
  final RxInt currentTab = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadWeeklyRecommendations();
    loadPendingInterests();
    loadMatches();
  }

  /// Carrega recomendações semanais
  Future<void> loadWeeklyRecommendations() async {
    try {
      isLoading.value = true;
      error.value = '';

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        error.value = 'Usuário não autenticado';
        return;
      }

      EnhancedLogger.info(
        'Loading weekly recommendations',
        tag: 'SINAIS_CONTROLLER',
        data: {'userId': userId},
      );

      final recs =
          await WeeklyRecommendationsService.getWeeklyRecommendations(userId);

      recommendations.value = recs;
      currentProfileIndex.value = 0;
      remainingProfiles.value = recs.length;

      EnhancedLogger.success(
        'Weekly recommendations loaded',
        tag: 'SINAIS_CONTROLLER',
        data: {'count': recs.length},
      );
    } catch (e) {
      error.value = 'Erro ao carregar recomendações';
      EnhancedLogger.error(
        'Failed to load recommendations',
        tag: 'SINAIS_CONTROLLER',
        error: e,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Carrega interesses pendentes
  Future<void> loadPendingInterests() async {
    try {
      isLoadingInterests.value = true;

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final interests =
          await WeeklyRecommendationsService.getPendingInterests(userId);

      pendingInterests.value = interests;

      // Carregar perfis dos interesses
      await loadInterestProfiles();

      EnhancedLogger.info(
        'Pending interests loaded',
        tag: 'SINAIS_CONTROLLER',
        data: {'count': interests.length},
      );
    } catch (e) {
      EnhancedLogger.error(
        'Failed to load pending interests',
        tag: 'SINAIS_CONTROLLER',
        error: e,
      );
    } finally {
      isLoadingInterests.value = false;
    }
  }

  /// Carrega matches
  Future<void> loadMatches() async {
    try {
      isLoadingMatches.value = true;

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final userMatches =
          await WeeklyRecommendationsService.getUserMatches(userId);

      matches.value = userMatches;

      // Carregar perfis dos matches
      await loadMatchProfiles();

      EnhancedLogger.info(
        'Matches loaded',
        tag: 'SINAIS_CONTROLLER',
        data: {'count': userMatches.length},
      );
    } catch (e) {
      EnhancedLogger.error(
        'Failed to load matches',
        tag: 'SINAIS_CONTROLLER',
        error: e,
      );
    } finally {
      isLoadingMatches.value = false;
    }
  }

  /// Manipula demonstração de interesse
  Future<void> handleInterest() async {
    try {
      if (currentProfileIndex.value >= recommendations.length) {
        return;
      }

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final profile = recommendations[currentProfileIndex.value];

      EnhancedLogger.info(
        'Registering interest',
        tag: 'SINAIS_CONTROLLER',
        data: {'profileId': profile.userId},
      );

      // Registrar interesse
      final hasMatch = await WeeklyRecommendationsService.registerInterest(
        userId,
        profile.userId,
      );

      // Marcar como visualizado
      await WeeklyRecommendationsService.markProfileAsViewed(
        userId,
        profile.userId,
      );

      if (hasMatch) {
        // Mostrar animação de match
        _showMatchAnimation(profile);
        // Recarregar matches
        await loadMatches();
      } else {
        // Adicionar aos interesses pendentes
        await loadPendingInterests();
      }

      // Avançar para próximo perfil
      _moveToNextProfile();

      EnhancedLogger.success(
        'Interest registered',
        tag: 'SINAIS_CONTROLLER',
        data: {'hasMatch': hasMatch},
      );
    } catch (e) {
      EnhancedLogger.error(
        'Failed to handle interest',
        tag: 'SINAIS_CONTROLLER',
        error: e,
      );
      Get.snackbar(
        'Erro',
        'Não foi possível registrar interesse',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Manipula passar perfil
  Future<void> handlePass() async {
    try {
      if (currentProfileIndex.value >= recommendations.length) {
        return;
      }

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final profile = recommendations[currentProfileIndex.value];

      EnhancedLogger.info(
        'Passing profile',
        tag: 'SINAIS_CONTROLLER',
        data: {'profileId': profile.userId},
      );

      // Marcar como passado
      await WeeklyRecommendationsService.markProfileAsPassed(
        userId,
        profile.userId,
      );

      // Avançar para próximo perfil
      _moveToNextProfile();

      EnhancedLogger.success(
        'Profile passed',
        tag: 'SINAIS_CONTROLLER',
      );
    } catch (e) {
      EnhancedLogger.error(
        'Failed to pass profile',
        tag: 'SINAIS_CONTROLLER',
        error: e,
      );
    }
  }

  /// Abre detalhes completos do perfil
  Future<void> openProfileDetails(ScoredProfile profile) async {
    try {
      EnhancedLogger.info(
        'Opening profile details',
        tag: 'SINAIS_CONTROLLER',
        data: {'profileId': profile.userId},
      );

      final result = await Get.toNamed(
        '/sinais-profile-detail',
        arguments: profile,
      );

      // Se retornou 'interest', registrar interesse
      if (result == 'interest') {
        await handleInterest();
      }
    } catch (e) {
      EnhancedLogger.error(
        'Failed to open profile details',
        tag: 'SINAIS_CONTROLLER',
        error: e,
      );
    }
  }

  /// Move para próximo perfil
  void _moveToNextProfile() {
    if (currentProfileIndex.value < recommendations.length - 1) {
      currentProfileIndex.value++;
      remainingProfiles.value =
          recommendations.length - currentProfileIndex.value;
    } else {
      // Acabaram as recomendações
      remainingProfiles.value = 0;
      EnhancedLogger.info(
        'All recommendations viewed',
        tag: 'SINAIS_CONTROLLER',
      );
    }
  }

  /// Mostra animação de match
  void _showMatchAnimation(ScoredProfile profile) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4169E1), Color(0xFF7B68EE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.favorite,
                color: Colors.white,
                size: 80,
              ),
              const SizedBox(height: 24),
              const Text(
                'É um Match! 🎉',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Você e ${profile.name} demonstraram interesse mútuo!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Get.back();
                  // Navegar para tab de matches
                  currentTab.value = 2;
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF4169E1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Ver Matches',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  /// Obtém perfil atual
  ScoredProfile? get currentProfile {
    if (currentProfileIndex.value < recommendations.length) {
      return recommendations[currentProfileIndex.value];
    }
    return null;
  }

  /// Verifica se tem recomendações
  bool get hasRecommendations => recommendations.isNotEmpty;

  /// Verifica se acabaram as recomendações
  bool get allRecommendationsViewed =>
      currentProfileIndex.value >= recommendations.length;

  /// Muda tab
  void changeTab(int index) {
    currentTab.value = index;
  }

  /// Recarrega tudo
  Future<void> refresh() async {
    await Future.wait([
      loadWeeklyRecommendations(),
      loadPendingInterests(),
      loadMatches(),
    ]);
  }

  // Mapas para armazenar perfis dos interesses e matches
  final RxMap<String, ScoredProfile> interestProfiles =
      <String, ScoredProfile>{}.obs;
  final RxMap<String, ScoredProfile> matchProfiles =
      <String, ScoredProfile>{}.obs;

  /// Carrega perfis completos dos interesses
  Future<void> loadInterestProfiles() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final profiles =
          await WeeklyRecommendationsService.getProfilesForInterests(
        userId,
        pendingInterests,
      );

      interestProfiles.value = profiles;
    } catch (e) {
      EnhancedLogger.error(
        'Failed to load interest profiles',
        tag: 'SINAIS_CONTROLLER',
        error: e,
      );
    }
  }

  /// Carrega perfis completos dos matches
  Future<void> loadMatchProfiles() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final profiles = await WeeklyRecommendationsService.getProfilesForMatches(
        userId,
        matches,
      );

      matchProfiles.value = profiles;
    } catch (e) {
      EnhancedLogger.error(
        'Failed to load match profiles',
        tag: 'SINAIS_CONTROLLER',
        error: e,
      );
    }
  }

  /// Aceita um interesse (cria match)
  Future<void> acceptInterest(Interest interest) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      EnhancedLogger.info(
        'Accepting interest',
        tag: 'SINAIS_CONTROLLER',
        data: {'interestId': interest.id, 'fromUserId': interest.fromUserId},
      );

      // Registrar interesse recíproco (isso cria o match)
      await WeeklyRecommendationsService.registerInterest(
        userId,
        interest.fromUserId,
      );

      // Remover da lista de pendentes
      pendingInterests.removeWhere((i) => i.id == interest.id);
      interestProfiles.remove(interest.fromUserId);

      // Recarregar matches
      await loadMatches();
      await loadMatchProfiles();

      // Mostrar mensagem de sucesso
      Get.snackbar(
        '💕 É um Match!',
        'Vocês demonstraram interesse mútuo!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.pink[100],
        duration: const Duration(seconds: 3),
      );

      EnhancedLogger.success(
        'Interest accepted - Match created',
        tag: 'SINAIS_CONTROLLER',
      );
    } catch (e) {
      EnhancedLogger.error(
        'Failed to accept interest',
        tag: 'SINAIS_CONTROLLER',
        error: e,
      );
      Get.snackbar(
        'Erro',
        'Não foi possível aceitar o interesse',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Recusa um interesse
  Future<void> rejectInterest(Interest interest) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      EnhancedLogger.info(
        'Rejecting interest',
        tag: 'SINAIS_CONTROLLER',
        data: {'interestId': interest.id},
      );

      // Marcar como passado
      await WeeklyRecommendationsService.markProfileAsPassed(
        userId,
        interest.fromUserId,
      );

      // Remover da lista
      pendingInterests.removeWhere((i) => i.id == interest.id);
      interestProfiles.remove(interest.fromUserId);

      EnhancedLogger.success(
        'Interest rejected',
        tag: 'SINAIS_CONTROLLER',
      );
    } catch (e) {
      EnhancedLogger.error(
        'Failed to reject interest',
        tag: 'SINAIS_CONTROLLER',
        error: e,
      );
    }
  }

  /// Abre chat com um match
  Future<void> openChat(Match match) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final otherUserId = match.getOtherUserId(userId);

      EnhancedLogger.info(
        'Opening chat',
        tag: 'SINAIS_CONTROLLER',
        data: {'matchId': match.id, 'otherUserId': otherUserId},
      );

      // Navegar para o chat
      Get.toNamed('/chat', arguments: {
        'userId': otherUserId,
        'matchId': match.id,
      });
    } catch (e) {
      EnhancedLogger.error(
        'Failed to open chat',
        tag: 'SINAIS_CONTROLLER',
        error: e,
      );
      Get.snackbar(
        'Erro',
        'Não foi possível abrir o chat',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  void onClose() {
    // Limpar recursos
    super.onClose();
  }
}
