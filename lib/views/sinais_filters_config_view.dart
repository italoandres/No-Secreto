import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/explore_profiles_controller.dart';
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

/// Tela de configuração de filtros dos Sinais
class SinaisFiltersConfigView extends StatelessWidget {
  const SinaisFiltersConfigView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ExploreProfilesController>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Configure Seus Sinais',
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
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Motivacional
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF7B68EE).withOpacity(0.1),
                    const Color(0xFF4169E1).withOpacity(0.1),
                  ],
                ),
              ),
              child: Text(
                'Levaremos seus sinais em consideração, mas mostraremos as opções mais adequadas entre as disponíveis para você.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Localização
                  Obx(() => LocationFilterSection(
                        primaryCity: controller.primaryCity.value.isNotEmpty
                            ? controller.primaryCity.value
                            : null,
                        primaryState: controller.primaryState.value.isNotEmpty
                            ? controller.primaryState.value
                            : null,
                        additionalLocations:
                            controller.additionalLocations.value,
                        onAddLocation: () =>
                            controller.showAddLocationDialog(context),
                        onRemoveLocation: (index) =>
                            controller.removeAdditionalLocation(index),
                        onEditLocation: (index) =>
                            controller.showEditLocationDialog(context, index),
                        canAddMore: controller.canAddMoreLocations(),
                      )),
                  const SizedBox(height: 16),

                  // Distância
                  Obx(() => DistanceFilterCard(
                        currentDistance: controller.maxDistance.value,
                        onDistanceChanged: controller.updateMaxDistance,
                      )),
                  const SizedBox(height: 16),
                  Obx(() => PreferenceToggleCard(
                        isEnabled: controller.prioritizeDistance.value,
                        onToggle: controller.updatePrioritizeDistance,
                      )),
                  const SizedBox(height: 16),

                  // Idade
                  Obx(() => AgeFilterCard(
                        minAge: controller.minAge.value,
                        maxAge: controller.maxAge.value,
                        onAgeRangeChanged: controller.updateAgeRange,
                      )),
                  const SizedBox(height: 16),
                  Obx(() => AgePreferenceToggleCard(
                        isEnabled: controller.prioritizeAge.value,
                        onToggle: controller.updatePrioritizeAge,
                      )),
                  const SizedBox(height: 16),

                  // Altura
                  Obx(() => HeightFilterCard(
                        minHeight: controller.minHeight.value,
                        maxHeight: controller.maxHeight.value,
                        onHeightChanged: controller.updateHeightRange,
                      )),
                  const SizedBox(height: 16),
                  Obx(() => HeightPreferenceToggleCard(
                        isEnabled: controller.prioritizeHeight.value,
                        onToggle: controller.updatePrioritizeHeight,
                      )),
                  const SizedBox(height: 16),

                  // Idiomas
                  Obx(() => LanguagesFilterCard(
                        selectedLanguages:
                            controller.selectedLanguages.toList(),
                        onLanguagesChanged:
                            controller.updateSelectedLanguages,
                      )),
                  const SizedBox(height: 16),
                  Obx(() => LanguagesPreferenceToggleCard(
                        isEnabled: controller.prioritizeLanguages.value,
                        onToggle: controller.updatePrioritizeLanguages,
                      )),
                  const SizedBox(height: 16),

                  // Educação
                  Obx(() => EducationFilterCard(
                        selectedEducation: controller.selectedEducation.value,
                        onEducationChanged:
                            controller.updateSelectedEducation,
                      )),
                  const SizedBox(height: 16),
                  Obx(() => EducationPreferenceToggleCard(
                        isEnabled: controller.prioritizeEducation.value,
                        onToggle: controller.updatePrioritizeEducation,
                      )),
                  const SizedBox(height: 16),

                  // Filhos
                  Obx(() => ChildrenFilterCard(
                        selectedChildren: controller.selectedChildren.value,
                        onChildrenChanged: controller.updateSelectedChildren,
                      )),
                  const SizedBox(height: 16),
                  Obx(() => ChildrenPreferenceToggleCard(
                        isEnabled: controller.prioritizeChildren.value,
                        onToggle: controller.updatePrioritizeChildren,
                      )),
                  const SizedBox(height: 16),

                  // Beber
                  Obx(() => DrinkingFilterCard(
                        selectedDrinking: controller.selectedDrinking.value,
                        onDrinkingChanged: controller.updateSelectedDrinking,
                      )),
                  const SizedBox(height: 16),
                  Obx(() => DrinkingPreferenceToggleCard(
                        isEnabled: controller.prioritizeDrinking.value,
                        onToggle: controller.updatePrioritizeDrinking,
                      )),
                  const SizedBox(height: 16),

                  // Fumar
                  Obx(() => SmokingFilterCard(
                        selectedSmoking: controller.selectedSmoking.value,
                        onSmokingChanged: controller.updateSelectedSmoking,
                      )),
                  const SizedBox(height: 16),
                  Obx(() => SmokingPreferenceToggleCard(
                        isEnabled: controller.prioritizeSmoking.value,
                        onToggle: controller.updatePrioritizeSmoking,
                      )),
                  const SizedBox(height: 16),

                  // Certificação
                  Obx(() => CertificationFilterCard(
                        requiresCertification:
                            controller.requiresCertification.value,
                        onCertificationChanged:
                            controller.updateRequiresCertification,
                      )),
                  const SizedBox(height: 16),
                  Obx(() => CertificationPreferenceToggleCard(
                        isEnabled: controller.prioritizeCertification.value,
                        onToggle: controller.updatePrioritizeCertification,
                      )),
                  const SizedBox(height: 16),

                  // Deus é Pai
                  Obx(() => DeusEPaiFilterCard(
                        requiresDeusEPaiMember:
                            controller.requiresDeusEPaiMember.value,
                        onDeusEPaiChanged:
                            controller.updateRequiresDeusEPaiMember,
                      )),
                  const SizedBox(height: 16),
                  Obx(() => DeusEPaiPreferenceToggleCard(
                        isEnabled: controller.prioritizeDeusEPaiMember.value,
                        onToggle: controller.updatePrioritizeDeusEPaiMember,
                      )),
                  const SizedBox(height: 16),

                  // Virgindade
                  Obx(() => VirginityFilterCard(
                        selectedVirginity:
                            controller.selectedVirginity.value,
                        onVirginityChanged:
                            controller.updateSelectedVirginity,
                      )),
                  const SizedBox(height: 16),
                  Obx(() => VirginityPreferenceToggleCard(
                        isEnabled: controller.prioritizeVirginity.value,
                        onToggle: controller.updatePrioritizeVirginity,
                      )),
                  const SizedBox(height: 16),

                  // Hobbies
                  Obx(() => HobbiesFilterCard(
                        selectedHobbies: controller.selectedHobbies.toList(),
                        onHobbiesChanged: controller.updateSelectedHobbies,
                      )),
                  const SizedBox(height: 16),
                  Obx(() => HobbiesPreferenceToggleCard(
                        isEnabled: controller.prioritizeHobbies.value,
                        onToggle: controller.updatePrioritizeHobbies,
                      )),
                  const SizedBox(height: 16),

                  // Botão Salvar
                  Obx(() {
                    final hasChanges = controller.currentFilters.value !=
                        controller.savedFilters.value;

                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            hasChanges ? controller.saveSearchFilters : null,
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
      ),
    );
  }
}
