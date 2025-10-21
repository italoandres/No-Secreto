import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/explore_profiles_controller.dart';
import '../controllers/sinais_controller.dart';
import '../components/location_filter_section.dart';
import '../components/profile_recommendation_card.dart';
import '../components/interest_card.dart';
import '../components/match_card.dart';
import '../components/distance_filter_card.dart';
import '../components/preference_toggle_card.dart';
import '../components/age_filter_card.dart';
import '../components/age_preference_toggle_card.dart';
import '../components/height_filter_card.dart';
import '../components/height_preference_toggle_card.dart';
import '../components/languages_filter_card.dart';
import '../components/languages_preference_toggle_card.dart';
import '../components/education_filter_card.dart';
import '../components/education_preference_toggle_card.dart';
import '../components/children_filter_card.dart';
import '../components/children_preference_toggle_card.dart';
import '../components/drinking_filter_card.dart';
import '../components/drinking_preference_toggle_card.dart';
import '../components/smoking_filter_card.dart';
import '../components/smoking_preference_toggle_card.dart';
import '../components/certification_filter_card.dart';
import '../components/certification_preference_toggle_card.dart';
import '../components/deus_e_pai_filter_card.dart';
import '../components/deus_e_pai_preference_toggle_card.dart';
import '../components/virginity_filter_card.dart';
import '../components/virginity_preference_toggle_card.dart';
import '../components/hobbies_filter_card.dart';
import '../components/hobbies_preference_toggle_card.dart';

/// Tela para explorar perfis verificados
class ExploreProfilesView extends StatelessWidget {
  const ExploreProfilesView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ExploreProfilesController());
    final sinaisController = Get.put(SinaisController());
    
    // Carregar localizações e filtros do usuário
    controller.loadUserLocations();
    controller.loadSearchFilters();

    return WillPopScope(
      onWillPop: () => controller.showSaveDialog(context),
      child: Scaffold(
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
      ),
      body: Column(
        children: [
          // Tabs Horizontais
          Container(
            color: Colors.white,
            child: Row(
              children: [
                // Tab "Sinais" (Esquerda)
                Expanded(
                  child: GestureDetector(
                    onTap: () => controller.changeTab(0),
                    child: Obx(() => Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: controller.currentTab.value == 0
                                ? const Color(0xFF7B68EE)
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        'Sinais',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: controller.currentTab.value == 0
                              ? const Color(0xFF7B68EE)
                              : Colors.grey[600],
                          fontWeight: controller.currentTab.value == 0
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                    )),
                  ),
                ),
                
                // Tab "Configure Sinais" (Direita)
                Expanded(
                  child: GestureDetector(
                    onTap: () => controller.changeTab(1),
                    child: Obx(() => Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: controller.currentTab.value == 1
                                ? const Color(0xFF7B68EE)
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        'Configure Sinais',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: controller.currentTab.value == 1
                              ? const Color(0xFF7B68EE)
                              : Colors.grey[600],
                          fontWeight: controller.currentTab.value == 1
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                    )),
                  ),
                ),
              ],
            ),
          ),

          // Conteúdo das Tabs
          Expanded(
            child: Obx(() {
              // Tab 0: Sinais (Sistema de Recomendações)
              if (controller.currentTab.value == 0) {
                return _buildSinaisTab(sinaisController);
              }
              
              // Tab 1: Configure Sinais (filtros)
              return SingleChildScrollView(
                child: Column(
                  children: [
                    // Header Motivacional
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF7B68EE).withOpacity(0.05),
                          const Color(0xFF4169E1).withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Espero esses Sinais...',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF7B68EE),
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Levaremos seus sinais em consideração, mas mostraremos as opções mais adequadas entre as disponíveis para você.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // Seção de Filtros de Localização
                  Obx(() => LocationFilterSection(
                    primaryCity: controller.primaryCity.value.isNotEmpty 
                        ? controller.primaryCity.value 
                        : null,
                    primaryState: controller.primaryState.value.isNotEmpty 
                        ? controller.primaryState.value 
                        : null,
                    additionalLocations: controller.additionalLocations.value,
                    onAddLocation: () => controller.showAddLocationDialog(context),
                    onRemoveLocation: (index) => controller.removeAdditionalLocation(index),
                    onEditLocation: (index) => controller.showEditLocationDialog(context, index),
                    canAddMore: controller.canAddMoreLocations(),
                  )),

                  const SizedBox(height: 16),

                  // Seção de Filtros de Distância
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Filtro de Distância
                        Obx(() => DistanceFilterCard(
                          currentDistance: controller.maxDistance.value,
                          onDistanceChanged: (distance) {
                            controller.updateMaxDistance(distance);
                          },
                        )),

                        const SizedBox(height: 16),

                        // Toggle de Preferência de Distância
                        Obx(() => PreferenceToggleCard(
                          isEnabled: controller.prioritizeDistance.value,
                          onToggle: (value) {
                            controller.updatePrioritizeDistance(value);
                          },
                        )),

                        const SizedBox(height: 16),

                        // Filtro de Idade
                        Obx(() => AgeFilterCard(
                          minAge: controller.minAge.value,
                          maxAge: controller.maxAge.value,
                          onAgeRangeChanged: (min, max) {
                            controller.updateAgeRange(min, max);
                          },
                        )),

                        const SizedBox(height: 16),

                        // Toggle de Preferência de Idade
                        Obx(() => AgePreferenceToggleCard(
                          isEnabled: controller.prioritizeAge.value,
                          onToggle: (value) {
                            controller.updatePrioritizeAge(value);
                          },
                        )),

                        const SizedBox(height: 16),

                        // Filtro de Altura
                        Obx(() => HeightFilterCard(
                          minHeight: controller.minHeight.value,
                          maxHeight: controller.maxHeight.value,
                          onHeightChanged: (min, max) {
                            controller.updateHeightRange(min, max);
                          },
                        )),

                        const SizedBox(height: 16),

                        // Toggle de Preferência de Altura
                        Obx(() => HeightPreferenceToggleCard(
                          isEnabled: controller.prioritizeHeight.value,
                          onToggle: (value) {
                            controller.updatePrioritizeHeight(value);
                          },
                        )),

                        const SizedBox(height: 16),

                        // Filtro de Idiomas
                        Obx(() => LanguagesFilterCard(
                          selectedLanguages: controller.selectedLanguages.toList(),
                          onLanguagesChanged: (languages) {
                            controller.updateSelectedLanguages(languages);
                          },
                        )),

                        const SizedBox(height: 16),

                        // Toggle de Preferência de Idiomas
                        Obx(() => LanguagesPreferenceToggleCard(
                          isEnabled: controller.prioritizeLanguages.value,
                          onToggle: (value) {
                            controller.updatePrioritizeLanguages(value);
                          },
                        )),

                        const SizedBox(height: 16),

                        // Filtro de Educação
                        Obx(() => EducationFilterCard(
                          selectedEducation: controller.selectedEducation.value,
                          onEducationChanged: (education) {
                            controller.updateSelectedEducation(education);
                          },
                        )),

                        const SizedBox(height: 16),

                        // Toggle de Preferência de Educação
                        Obx(() => EducationPreferenceToggleCard(
                          isEnabled: controller.prioritizeEducation.value,
                          onToggle: (value) {
                            controller.updatePrioritizeEducation(value);
                          },
                        )),

                        const SizedBox(height: 16),

                        // Filtro de Filhos
                        Obx(() => ChildrenFilterCard(
                          selectedChildren: controller.selectedChildren.value,
                          onChildrenChanged: (children) {
                            controller.updateSelectedChildren(children);
                          },
                        )),

                        const SizedBox(height: 16),

                        // Toggle de Preferência de Filhos
                        Obx(() => ChildrenPreferenceToggleCard(
                          isEnabled: controller.prioritizeChildren.value,
                          onToggle: (value) {
                            controller.updatePrioritizeChildren(value);
                          },
                        )),

                        const SizedBox(height: 16),

                        // Filtro de Beber
                        Obx(() => DrinkingFilterCard(
                          selectedDrinking: controller.selectedDrinking.value,
                          onDrinkingChanged: (drinking) {
                            controller.updateSelectedDrinking(drinking);
                          },
                        )),

                        const SizedBox(height: 16),

                        // Toggle de Preferência de Beber
                        Obx(() => DrinkingPreferenceToggleCard(
                          isEnabled: controller.prioritizeDrinking.value,
                          onToggle: (value) {
                            controller.updatePrioritizeDrinking(value);
                          },
                        )),

                        const SizedBox(height: 16),

                        // Filtro de Fumar
                        Obx(() => SmokingFilterCard(
                          selectedSmoking: controller.selectedSmoking.value,
                          onSmokingChanged: (smoking) {
                            controller.updateSelectedSmoking(smoking);
                          },
                        )),

                        const SizedBox(height: 16),

                        // Toggle de Preferência de Fumar
                        Obx(() => SmokingPreferenceToggleCard(
                          isEnabled: controller.prioritizeSmoking.value,
                          onToggle: (value) {
                            controller.updatePrioritizeSmoking(value);
                          },
                        )),

                        const SizedBox(height: 16),

                        // Filtro de Certificação Espiritual
                        Obx(() => CertificationFilterCard(
                          requiresCertification: controller.requiresCertification.value,
                          onCertificationChanged: (certification) {
                            controller.updateRequiresCertification(certification);
                          },
                        )),

                        const SizedBox(height: 16),

                        // Toggle de Preferência de Certificação
                        Obx(() => CertificationPreferenceToggleCard(
                          isEnabled: controller.prioritizeCertification.value,
                          onToggle: (value) {
                            controller.updatePrioritizeCertification(value);
                          },
                        )),

                        const SizedBox(height: 16),

                        // Filtro de Movimento Deus é Pai
                        Obx(() => DeusEPaiFilterCard(
                          requiresDeusEPaiMember: controller.requiresDeusEPaiMember.value,
                          onDeusEPaiChanged: (member) {
                            controller.updateRequiresDeusEPaiMember(member);
                          },
                        )),

                        const SizedBox(height: 16),

                        // Toggle de Preferência de Deus é Pai
                        Obx(() => DeusEPaiPreferenceToggleCard(
                          isEnabled: controller.prioritizeDeusEPaiMember.value,
                          onToggle: (value) {
                            controller.updatePrioritizeDeusEPaiMember(value);
                          },
                        )),

                        const SizedBox(height: 16),

                        // Filtro de Virgindade
                        Obx(() => VirginityFilterCard(
                          selectedVirginity: controller.selectedVirginity.value,
                          onVirginityChanged: (virginity) {
                            controller.updateSelectedVirginity(virginity);
                          },
                        )),

                        const SizedBox(height: 16),

                        // Toggle de Preferência de Virgindade
                        Obx(() => VirginityPreferenceToggleCard(
                          isEnabled: controller.prioritizeVirginity.value,
                          onToggle: (value) {
                            controller.updatePrioritizeVirginity(value);
                          },
                        )),

                        const SizedBox(height: 16),

                        // Filtro de Hobbies
                        Obx(() => HobbiesFilterCard(
                          selectedHobbies: controller.selectedHobbies.toList(),
                          onHobbiesChanged: (hobbies) {
                            controller.updateSelectedHobbies(hobbies);
                          },
                        )),

                        const SizedBox(height: 16),

                        // Toggle de Preferência de Hobbies
                        Obx(() => HobbiesPreferenceToggleCard(
                          isEnabled: controller.prioritizeHobbies.value,
                          onToggle: (value) {
                            controller.updatePrioritizeHobbies(value);
                          },
                        )),

                        const SizedBox(height: 16),

                        // Botão Salvar Filtros
                        Obx(() {
                          final hasChanges = controller.currentFilters.value != controller.savedFilters.value;
                          
                          return SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: hasChanges ? controller.saveSearchFilters : null,
                              icon: const Icon(Icons.save, size: 20),
                              label: Text(
                                hasChanges ? 'Salvar Filtros' : 'Filtros Salvos',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: hasChanges 
                                    ? const Color(0xFF7B68EE) 
                                    : Colors.grey[400],
                                elevation: hasChanges ? 4 : 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          );
                        }),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
      ),
    );
  }

  /// Constrói a aba Sinais com sub-tabs de Recomendações, Interesses e Matches
  Widget _buildSinaisTab(SinaisController sinaisController) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          // Sub-tabs dentro da aba Sinais
          Container(
            color: Colors.white,
            child: TabBar(
              onTap: sinaisController.changeTab,
              labelColor: const Color(0xFF7B68EE),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF7B68EE),
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.favorite_border, size: 18),
                      const SizedBox(width: 6),
                      const Text('Recomendações'),
                      Obx(() {
                        if (sinaisController.remainingProfiles.value > 0) {
                          return Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7B68EE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${sinaisController.remainingProfiles.value}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.schedule, size: 18),
                      const SizedBox(width: 6),
                      const Text('Interesses'),
                      Obx(() {
                        if (sinaisController.pendingInterests.isNotEmpty) {
                          return Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${sinaisController.pendingInterests.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.favorite, size: 18),
                      const SizedBox(width: 6),
                      const Text('Matches'),
                      Obx(() {
                        if (sinaisController.matches.isNotEmpty) {
                          return Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${sinaisController.matches.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Conteúdo das sub-tabs
          Expanded(
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildRecommendationsTab(sinaisController),
                _buildInterestsTab(sinaisController),
                _buildMatchesTab(sinaisController),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tab de Recomendações
  Widget _buildRecommendationsTab(SinaisController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF7B68EE),
          ),
        );
      }

      if (controller.error.value.isNotEmpty) {
        return _buildErrorState(controller);
      }

      if (!controller.hasRecommendations) {
        return _buildEmptyRecommendations();
      }

      if (controller.allRecommendationsViewed) {
        return _buildAllViewedState();
      }

      final profile = controller.currentProfile;
      if (profile == null) {
        return _buildEmptyRecommendations();
      }

      return RefreshIndicator(
        onRefresh: controller.refresh,
        color: const Color(0xFF7B68EE),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Contador de perfis restantes
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: Colors.amber[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${controller.remainingProfiles.value} ${controller.remainingProfiles.value == 1 ? "perfil restante" : "perfis restantes"} esta semana',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),

              // Card de perfil
              ProfileRecommendationCard(
                profile: profile,
                onInterest: controller.handleInterest,
                onPass: controller.handlePass,
                onTapDetails: () => controller.openProfileDetails(profile),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    });
  }

  /// Tab de Interesses Pendentes
  Widget _buildInterestsTab(SinaisController controller) {
    return Obx(() {
      if (controller.isLoadingInterests.value) {
        return const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF7B68EE),
          ),
        );
      }

      if (controller.pendingInterests.isEmpty) {
        return _buildEmptyInterests();
      }

      return RefreshIndicator(
        onRefresh: controller.loadPendingInterests,
        color: const Color(0xFF7B68EE),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.pendingInterests.length,
          itemBuilder: (context, index) {
            final interest = controller.pendingInterests[index];
            final profile = controller.interestProfiles[interest.fromUserId];
            
            if (profile == null) {
              return const SizedBox.shrink();
            }
            
            return InterestCard(
              interest: interest,
              profile: profile,
              onAccept: () => controller.acceptInterest(interest),
              onReject: () => controller.rejectInterest(interest),
              onViewProfile: () => controller.openProfileDetails(profile),
            );
          },
        ),
      );
    });
  }

  /// Tab de Matches
  Widget _buildMatchesTab(SinaisController controller) {
    return Obx(() {
      if (controller.isLoadingMatches.value) {
        return const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF7B68EE),
          ),
        );
      }

      if (controller.matches.isEmpty) {
        return _buildEmptyMatches();
      }

      return RefreshIndicator(
        onRefresh: controller.loadMatches,
        color: const Color(0xFF7B68EE),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.matches.length,
          itemBuilder: (context, index) {
            final match = controller.matches[index];
            final userId = FirebaseAuth.instance.currentUser?.uid;
            if (userId == null) return const SizedBox.shrink();
            
            final otherUserId = match.getOtherUserId(userId);
            final profile = controller.matchProfiles[otherUserId];
            
            if (profile == null) {
              return const SizedBox.shrink();
            }
            
            return MatchCard(
              match: match,
              profile: profile,
              onOpenChat: () => controller.openChat(match),
              onViewProfile: () => controller.openProfileDetails(profile),
            );
          },
        ),
      );
    });
  }

  /// Estado vazio de recomendações
  Widget _buildEmptyRecommendations() {
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

  /// Estado de todas recomendações visualizadas
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

  /// Estado vazio de interesses
  Widget _buildEmptyInterests() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            const Text(
              'Nenhum interesse pendente',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Demonstre interesse em perfis para vê-los aqui',
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

  /// Estado vazio de matches
  Widget _buildEmptyMatches() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            const Text(
              'Nenhum match ainda',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Quando houver interesse mútuo, você verá seus matches aqui',
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

  /// Estado de erro
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