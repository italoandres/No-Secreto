import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/explore_profiles_controller.dart';
import '../controllers/sinais_controller.dart';
import '../components/profile_recommendation_card.dart';
import 'sinais_filters_config_view.dart';

/// Tela limpa para ver recomendações de perfis
class ExploreProfilesView extends StatefulWidget {
  const ExploreProfilesView({Key? key}) : super(key: key);

  @override
  State<ExploreProfilesView> createState() => _ExploreProfilesViewState();
}

class _ExploreProfilesViewState extends State<ExploreProfilesView> {
  bool _showNotification = true;

  @override
  void initState() {
    super.initState();
    // Esconder notificação após 5 segundos
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showNotification = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ExploreProfilesController());
    final sinaisController = Get.put(SinaisController());

    // Carregar dados
    controller.loadUserLocations();
    controller.loadSearchFilters();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Seus Sinais',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF7B68EE),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Ícone de engrenagem para configurar filtros
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SinaisFiltersConfigView(),
                ),
              );
            },
            tooltip: 'Configurar Sinais',
          ),
        ],
      ),
      body: Obx(() {
        if (sinaisController.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF7B68EE),
            ),
          );
        }

        if (sinaisController.error.value.isNotEmpty) {
          return _buildErrorState(sinaisController);
        }

        if (!sinaisController.hasRecommendations) {
          return _buildEmptyState();
        }

        if (sinaisController.allRecommendationsViewed) {
          return _buildAllViewedState();
        }

        final profile = sinaisController.currentProfile;
        if (profile == null) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: sinaisController.refresh,
          color: const Color(0xFF7B68EE),
          child: Stack(
            children: [
              // Card de perfil recomendado
              SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    ProfileRecommendationCard(
                      profile: profile,
                      onInterest: sinaisController.handleInterest,
                      onPass: sinaisController.handlePass,
                      onTapDetails: () =>
                          sinaisController.openProfileDetails(profile),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // Notificação temporária sobre o card
              if (_showNotification)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: AnimatedOpacity(
                    opacity: _showNotification ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.amber[400]!,
                            Colors.orange[400]!,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${sinaisController.remainingProfiles.value} ${sinaisController.remainingProfiles.value == 1 ? "perfil novo restante" : "perfis novos restantes"} esta semana',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            const Text(
              'Sem recomendações no momento',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Complete seu perfil e ajuste seus filtros para receber recomendações personalizadas',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllViewedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.green[400],
            ),
            const SizedBox(height: 24),
            const Text(
              'Você visualizou todos os perfis!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Novas recomendações estarão disponíveis na próxima segunda-feira',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(SinaisController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[400],
            ),
            const SizedBox(height: 24),
            Text(
              controller.error.value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: controller.refresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B68EE),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Tentar Novamente',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
