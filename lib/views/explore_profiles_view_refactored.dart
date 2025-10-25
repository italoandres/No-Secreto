import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/explore_profiles_controller.dart';
import '../controllers/sinais_controller.dart';
import '../components/location_filter_section.dart';
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

/// Tela limpa para configurar sinais e ver recomendações
class ExploreProfilesView extends StatefulWidget {
  const ExploreProfilesView({Key? key}) : super(key: key);

  @override
  State<ExploreProfilesView> createState() => _ExploreProfilesViewState();
}

class _ExploreProfilesViewState extends State<ExploreProfilesView> {
  final ScrollController _scrollController = ScrollController();
  bool _showNotification = true;

  @override
  void initState() {
    super.initState();
    // Esconder notificação após 3 segundos
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showNotification = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // SliverAppBar com foto que colapsa
            SliverAppBar(
              expandedHeight: 300,
              floating: false,
              pinned: true,
              backgroundColor: const Color(0xFF7B68EE),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                // Ícone de engrenagem para configurações
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: () {
                    // Scroll para a seção de configurações
                    _scrollController.animateTo(
                      400,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  },
                  tooltip: 'Configurar Sinais',
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Seus Sinais',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 3.0,
                        color: Color.fromARGB(100, 0, 0, 0),
                      ),
                    ],
                  ),
                ),
                background: Obx(() {
                  final profile = sinaisController.currentProfile;
                  if (profile == null) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF7B68EE),
                            const Color(0xFF4169E1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.favorite_border,
                          size: 80,
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                    );
                  }

                  // Foto do perfil recomendado
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // Imagem de fundo
                      Image.network(
                        profile.photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.person,
                              size: 80,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                      // Gradiente para melhor legibilidade do título
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),

            // Notificação temporária de perfis novos
            if (_showNotification)
              SliverToBoxAdapter(
                child: Obx(() {
                  final remaining = sinaisController.remainingProfiles.value;
                  if (remaining == 0) return const SizedBox.shrink();

                  return AnimatedOpacity(
                    opacity: _showNotification ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: Container(
                      margin: const EdgeInsets.all(16),
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
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
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
                              '$remaining ${remaining == 1 ? "perfil novo restante" : "perfis novos restantes"} esta semana',
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
                  );
                }),
              ),

            // Conteúdo principal: Informações do perfil atual
            SliverToBoxAdapter(
              child: Obx(() {
                final profile = sinaisController.currentProfile;

                if (sinaisController.isLoading.value) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF7B68EE),
                      ),
                    ),
                  );
                }

                if (profile == null) {
                  return _buildEmptyState();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informações básicas do perfil
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nome e idade
                          Row(
                            children: [
                              Text(
                                '${profile.name}, ${profile.age}',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (profile.hasCertification)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.verified,
                                        size: 16,
                                        color: Colors.amber[700],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Certificado',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber[900],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Localização
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 18,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${profile.city}, ${profile.state}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                '${profile.distance.toStringAsFixed(1)}km',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Compatibilidade
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green[400]!,
                                  Colors.green[600]!,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.favorite,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Compatibilidade',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '${profile.score.totalScore.toStringAsFixed(0)}% Excelente',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(
                                    Icons.info_outline,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    // Mostrar detalhes do score
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // NOVO: Propósito
                          if (profile.profileData['proposito'] != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: Colors.amber[700],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Propósito',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2C3E50),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.amber[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.amber[200]!,
                                    ),
                                  ),
                                  child: Text(
                                    profile.profileData['proposito'] as String,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey[800],
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),

                          // Valores Espirituais
                          const Text(
                            '⭐ Valores Espirituais',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Certificação Espiritual
                          if (profile.hasCertification)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.amber[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.amber[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.verified,
                                    color: Colors.amber[700],
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Certificação Espiritual',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2C3E50),
                                          ),
                                        ),
                                        Text(
                                          'Perfil verificado pela comunidade',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green[600],
                                    size: 24,
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 24),

                          // Botões de ação
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: sinaisController.handlePass,
                                  icon: const Icon(Icons.close),
                                  label: const Text('Passar'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.grey[700],
                                    side: BorderSide(color: Colors.grey[300]!),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  onPressed: sinaisController.handleInterest,
                                  icon: const Icon(Icons.favorite),
                                  label: const Text('Tenho Interesse'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF7B68EE),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),

                    // Divider
                    Divider(
                      thickness: 8,
                      color: Colors.grey[200],
                    ),

                    // Seção de Configurações
                    _buildConfigurationSection(controller),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
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
            'Configure seus sinais abaixo para receber recomendações personalizadas',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildConfigurationSection(ExploreProfilesController controller) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.settings,
                color: Color(0xFF7B68EE),
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Configure Seus Sinais',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Levaremos seus sinais em consideração, mas mostraremos as opções mais adequadas entre as disponíveis para você.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

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
                onRemoveLocation: (index) =>
                    controller.removeAdditionalLocation(index),
                onEditLocation: (index) =>
                    controller.showEditLocationDialog(context, index),
                canAddMore: controller.canAddMoreLocations(),
              )),

          const SizedBox(height: 16),

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
            final hasChanges = controller.currentFilters.value !=
                controller.savedFilters.value;

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
                  backgroundColor:
                      hasChanges ? const Color(0xFF7B68EE) : Colors.grey[400],
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
    );
  }
}
