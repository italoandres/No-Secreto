import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/spiritual_profile_model.dart';
import '../models/additional_location_model.dart';
import '../models/search_filters_model.dart';
import '../repositories/explore_profiles_repository.dart';
import '../repositories/spiritual_profile_repository.dart';
import '../components/location_selector_dialog.dart';
import '../components/save_filters_dialog.dart';
import '../utils/enhanced_logger.dart';

/// Controller para exploração de perfis
class ExploreProfilesController extends GetxController {
  final RxList<SpiritualProfileModel> profiles = <SpiritualProfileModel>[].obs;
  final RxList<SpiritualProfileModel> searchResults = <SpiritualProfileModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSearching = false.obs;
  final RxString error = ''.obs;
  final RxString searchQuery = ''.obs;
  
  // Filtros
  final RxInt minAge = 18.obs;
  final RxInt maxAge = 65.obs;
  final RxString selectedCity = ''.obs;
  final RxString selectedState = ''.obs;
  final RxList<String> selectedInterests = <String>[].obs;
  
  // Tabs
  final RxInt currentTab = 0.obs;
  final RxList<SpiritualProfileModel> popularProfiles = <SpiritualProfileModel>[].obs;
  final RxList<SpiritualProfileModel> recentProfiles = <SpiritualProfileModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadInitialProfiles();
  }

  /// Carrega perfis iniciais
  Future<void> loadInitialProfiles() async {
    try {
      isLoading.value = true;
      error.value = '';

      EnhancedLogger.info('Loading initial profiles', 
        tag: 'EXPLORE_PROFILES_CONTROLLER'
      );

      // Carregar perfis por engajamento (feed principal)
      final engagementProfiles = await ExploreProfilesRepository.getProfilesByEngagement(limit: 20);
      profiles.value = engagementProfiles;

      // Carregar perfis populares
      final popular = await ExploreProfilesRepository.getPopularProfiles(limit: 10);
      popularProfiles.value = popular;

      // Carregar perfis recentes (verificados)
      final recent = await ExploreProfilesRepository.getVerifiedProfiles(limit: 15);
      recentProfiles.value = recent;

      EnhancedLogger.success('Initial profiles loaded', 
        tag: 'EXPLORE_PROFILES_CONTROLLER',
        data: {
          'totalProfiles': profiles.length,
          'popularProfiles': popularProfiles.length,
          'recentProfiles': recentProfiles.length,
        }
      );
    } catch (e) {
      error.value = 'Erro ao carregar perfis';
      EnhancedLogger.error('Failed to load initial profiles', 
        tag: 'EXPLORE_PROFILES_CONTROLLER',
        error: e
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Busca perfis por query
  Future<void> searchProfiles(String query) async {
    try {
      if (query.trim().isEmpty) {
        searchResults.clear();
        searchQuery.value = '';
        return;
      }

      isSearching.value = true;
      searchQuery.value = query;

      EnhancedLogger.info('Searching profiles', 
        tag: 'EXPLORE_PROFILES_CONTROLLER',
        data: {'query': query}
      );

      final results = await ExploreProfilesRepository.searchProfiles(
        query: query,
        minAge: minAge.value,
        maxAge: maxAge.value,
        city: selectedCity.value.isNotEmpty ? selectedCity.value : null,
        state: selectedState.value.isNotEmpty ? selectedState.value : null,
        interests: selectedInterests.isNotEmpty ? selectedInterests : null,
        limit: 30,
      );

      searchResults.value = results;

      EnhancedLogger.success('Profile search completed', 
        tag: 'EXPLORE_PROFILES_CONTROLLER',
        data: {'query': query, 'results': results.length}
      );
    } catch (e) {
      EnhancedLogger.error('Failed to search profiles', 
        tag: 'EXPLORE_PROFILES_CONTROLLER',
        error: e,
        data: {'query': query}
      );
    } finally {
      isSearching.value = false;
    }
  }

  /// Limpa busca
  void clearSearch() {
    searchQuery.value = '';
    searchResults.clear();
  }

  /// Aplica filtros
  Future<void> applyFilters() async {
    try {
      isLoading.value = true;

      EnhancedLogger.info('Applying filters', 
        tag: 'EXPLORE_PROFILES_CONTROLLER',
        data: {
          'minAge': minAge.value,
          'maxAge': maxAge.value,
          'city': selectedCity.value,
          'state': selectedState.value,
          'interests': selectedInterests,
        }
      );

      final filteredProfiles = await ExploreProfilesRepository.searchProfiles(
        minAge: minAge.value,
        maxAge: maxAge.value,
        city: selectedCity.value.isNotEmpty ? selectedCity.value : null,
        state: selectedState.value.isNotEmpty ? selectedState.value : null,
        interests: selectedInterests.isNotEmpty ? selectedInterests : null,
        limit: 30,
      );

      profiles.value = filteredProfiles;

      EnhancedLogger.success('Filters applied', 
        tag: 'EXPLORE_PROFILES_CONTROLLER',
        data: {'results': filteredProfiles.length}
      );
    } catch (e) {
      EnhancedLogger.error('Failed to apply filters', 
        tag: 'EXPLORE_PROFILES_CONTROLLER',
        error: e
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Limpa filtros
  void clearFilters() {
    minAge.value = 18;
    maxAge.value = 65;
    selectedCity.value = '';
    selectedState.value = '';
    selectedInterests.clear();
    loadInitialProfiles();
  }

  /// Registra visualização de perfil
  Future<void> viewProfile(String profileId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await ExploreProfilesRepository.recordProfileView(currentUser.uid, profileId);
        
        EnhancedLogger.info('Profile view recorded', 
          tag: 'EXPLORE_PROFILES_CONTROLLER',
          data: {'profileId': profileId}
        );
      }
    } catch (e) {
      EnhancedLogger.error('Failed to record profile view', 
        tag: 'EXPLORE_PROFILES_CONTROLLER',
        error: e,
        data: {'profileId': profileId}
      );
    }
  }

  /// Muda tab ativa
  void changeTab(int index) {
    currentTab.value = index;
  }

  /// Obtém lista de perfis baseada na tab atual
  List<SpiritualProfileModel> get currentProfiles {
    if (searchQuery.value.isNotEmpty) {
      return searchResults;
    }
    
    switch (currentTab.value) {
      case 0: // Feed principal (por engajamento)
        return profiles;
      case 1: // Populares
        return popularProfiles;
      case 2: // Recentes
        return recentProfiles;
      default:
        return profiles;
    }
  }

  /// Recarrega perfis
  Future<void> refreshProfiles() async {
    await loadInitialProfiles();
  }

  /// Adiciona interesse aos filtros
  void addInterest(String interest) {
    if (!selectedInterests.contains(interest)) {
      selectedInterests.add(interest);
    }
  }

  /// Remove interesse dos filtros
  void removeInterest(String interest) {
    selectedInterests.remove(interest);
  }

  /// Lista de interesses disponíveis
  List<String> get availableInterests => [
    'Oração',
    'Estudo Bíblico',
    'Música Gospel',
    'Ministério',
    'Evangelização',
    'Jovens',
    'Casais',
    'Família',
    'Liderança',
    'Adoração',
    'Missões',
    'Discipulado',
  ];

  /// Lista de estados brasileiros
  List<String> get availableStates => [
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO',
    'MA', 'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI',
    'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO'
  ];

  /// Obtém estatísticas dos perfis
  Map<String, dynamic> get profileStats {
    return {
      'total': profiles.length,
      'popular': popularProfiles.length,
      'recent': recentProfiles.length,
      'searchResults': searchResults.length,
      'hasFilters': selectedCity.value.isNotEmpty || 
                   selectedState.value.isNotEmpty || 
                   selectedInterests.isNotEmpty ||
                   minAge.value != 18 ||
                   maxAge.value != 65,
    };
  }

  // ===== LOCATION MANAGEMENT =====
  
  /// Localizações adicionais do usuário
  final Rx<List<AdditionalLocation>> additionalLocations = Rx<List<AdditionalLocation>>([]);
  
  /// Localização principal do usuário (do perfil)
  final RxString primaryCity = ''.obs;
  final RxString primaryState = ''.obs;
  
  /// Carrega localizações do usuário
  Future<void> loadUserLocations() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      
      EnhancedLogger.info('Loading user locations', 
        tag: 'EXPLORE_PROFILES_CONTROLLER',
        data: {'userId': currentUser.uid}
      );
      
      // Buscar perfil do usuário
      final profile = await SpiritualProfileRepository.getProfileByUserId(currentUser.uid);
      
      if (profile != null) {
        // Carregar localização principal
        primaryCity.value = profile.city ?? '';
        primaryState.value = profile.state ?? '';
        
        // Carregar localizações adicionais
        additionalLocations.value = profile.additionalLocations ?? [];
        
        EnhancedLogger.success('User locations loaded', 
          tag: 'EXPLORE_PROFILES_CONTROLLER',
          data: {
            'primaryCity': primaryCity.value,
            'primaryState': primaryState.value,
            'additionalLocations': additionalLocations.value.length,
          }
        );
      }
    } catch (e) {
      EnhancedLogger.error('Failed to load user locations', 
        tag: 'EXPLORE_PROFILES_CONTROLLER',
        error: e
      );
    }
  }
  
  /// Adiciona localização adicional
  Future<void> addAdditionalLocation(String city, String state) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        Get.snackbar(
          'Erro',
          'Você precisa estar logado',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[800],
        );
        return;
      }
      
      // Validar limite
      if (additionalLocations.value.length >= 2) {
        Get.snackbar(
          'Limite Atingido',
          'Você já tem 2 localizações adicionais',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange[100],
          colorText: Colors.orange[800],
        );
        return;
      }
      
      EnhancedLogger.info('Adding additional location', 
        tag: 'EXPLORE_PROFILES_CONTROLLER',
        data: {'city': city, 'state': state}
      );
      
      // Criar nova localização
      final newLocation = AdditionalLocation(
        city: city,
        state: state,
        addedAt: DateTime.now(),
      );
      
      // Atualizar lista local
      final updatedList = List<AdditionalLocation>.from(additionalLocations.value);
      updatedList.add(newLocation);
      additionalLocations.value = updatedList;
      
      // Salvar no Firestore
      final profile = await SpiritualProfileRepository.getProfileByUserId(currentUser.uid);
      if (profile != null) {
        await SpiritualProfileRepository.updateProfile(profile.id!, {
          'additionalLocations': updatedList.map((loc) => loc.toJson()).toList(),
        });
      }
      
      EnhancedLogger.success('Additional location added', 
        tag: 'EXPLORE_PROFILES_CONTROLLER'
      );
      
      Get.snackbar(
        'Sucesso!',
        'Localização "$city - $state" adicionada',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[100],
        colorText: Colors.green[800],
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      EnhancedLogger.error('Failed to add additional location', 
        tag: 'EXPLORE_PROFILES_CONTROLLER',
        error: e
      );
      
      Get.snackbar(
        'Erro',
        'Não foi possível adicionar a localização',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
    }
  }
  
  /// Remove localização adicional
  Future<void> removeAdditionalLocation(int index) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      
      if (index < 0 || index >= additionalLocations.value.length) return;
      
      final locationToRemove = additionalLocations.value[index];
      
      EnhancedLogger.info('Removing additional location', 
        tag: 'EXPLORE_PROFILES_CONTROLLER',
        data: {'index': index, 'location': locationToRemove.displayText}
      );
      
      // Atualizar lista local
      final updatedList = List<AdditionalLocation>.from(additionalLocations.value);
      updatedList.removeAt(index);
      additionalLocations.value = updatedList;
      
      // Salvar no Firestore
      final profile = await SpiritualProfileRepository.getProfileByUserId(currentUser.uid);
      if (profile != null) {
        await SpiritualProfileRepository.updateProfile(profile.id!, {
          'additionalLocations': updatedList.map((loc) => loc.toJson()).toList(),
        });
      }
      
      EnhancedLogger.success('Additional location removed', 
        tag: 'EXPLORE_PROFILES_CONTROLLER'
      );
      
      Get.snackbar(
        'Removido',
        'Localização "${locationToRemove.displayText}" removida',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.grey[100],
        colorText: Colors.grey[800],
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      EnhancedLogger.error('Failed to remove additional location', 
        tag: 'EXPLORE_PROFILES_CONTROLLER',
        error: e
      );
      
      Get.snackbar(
        'Erro',
        'Não foi possível remover a localização',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
    }
  }
  
  /// Edita localização adicional
  Future<void> editAdditionalLocation(int index, String city, String state) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      
      if (index < 0 || index >= additionalLocations.value.length) return;
      
      final location = additionalLocations.value[index];
      
      // Verificar se pode editar
      if (!location.canEdit) {
        Get.snackbar(
          'Não Permitido',
          'Você poderá editar em ${location.daysUntilCanEdit} ${location.daysUntilCanEdit == 1 ? 'dia' : 'dias'}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange[100],
          colorText: Colors.orange[800],
        );
        return;
      }
      
      EnhancedLogger.info('Editing additional location', 
        tag: 'EXPLORE_PROFILES_CONTROLLER',
        data: {'index': index, 'newCity': city, 'newState': state}
      );
      
      // Atualizar localização
      final updatedLocation = location.copyWith(
        city: city,
        state: state,
        lastEditedAt: DateTime.now(),
      );
      
      // Atualizar lista local
      final updatedList = List<AdditionalLocation>.from(additionalLocations.value);
      updatedList[index] = updatedLocation;
      additionalLocations.value = updatedList;
      
      // Salvar no Firestore
      final profile = await SpiritualProfileRepository.getProfileByUserId(currentUser.uid);
      if (profile != null) {
        await SpiritualProfileRepository.updateProfile(profile.id!, {
          'additionalLocations': updatedList.map((loc) => loc.toJson()).toList(),
        });
      }
      
      EnhancedLogger.success('Additional location edited', 
        tag: 'EXPLORE_PROFILES_CONTROLLER'
      );
      
      Get.snackbar(
        'Atualizado!',
        'Localização alterada para "$city - $state"',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[100],
        colorText: Colors.green[800],
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      EnhancedLogger.error('Failed to edit additional location', 
        tag: 'EXPLORE_PROFILES_CONTROLLER',
        error: e
      );
      
      Get.snackbar(
        'Erro',
        'Não foi possível editar a localização',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
    }
  }
  
  /// Verifica se pode adicionar mais localizações
  bool canAddMoreLocations() {
    return additionalLocations.value.length < 2;
  }
  
  /// Mostra dialog para adicionar localização
  void showAddLocationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => LocationSelectorDialog(
        onLocationSelected: (city, state) {
          addAdditionalLocation(city, state);
        },
      ),
    );
  }
  
  /// Mostra dialog para editar localização
  void showEditLocationDialog(BuildContext context, int index) {
    final location = additionalLocations.value[index];
    
    if (!location.canEdit) {
      Get.snackbar(
        'Não Permitido',
        'Você poderá editar em ${location.daysUntilCanEdit} ${location.daysUntilCanEdit == 1 ? 'dia' : 'dias'}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange[100],
        colorText: Colors.orange[800],
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => LocationSelectorDialog(
        onLocationSelected: (city, state) {
          editAdditionalLocation(index, city, state);
        },
      ),
    );
  }

  // ===== DISTANCE FILTER MANAGEMENT =====
  
  /// Filtros de busca atuais
  final Rx<SearchFilters> currentFilters = SearchFilters.defaultFilters().obs;
  
  /// Filtros salvos (para comparação)
  final Rx<SearchFilters> savedFilters = SearchFilters.defaultFilters().obs;
  
  /// Distância máxima (para binding com slider)
  final RxInt maxDistance = 50.obs;
  
  /// Toggle de preferência de distância (para binding com switch)
  final RxBool prioritizeDistance = false.obs;
  
  /// Toggle de preferência de idade (para binding com switch)
  final RxBool prioritizeAge = false.obs;
  
  /// Altura mínima (para binding com slider)
  final RxInt minHeight = 150.obs;
  
  /// Altura máxima (para binding com slider)
  final RxInt maxHeight = 190.obs;
  
  /// Toggle de preferência de altura (para binding com switch)
  final RxBool prioritizeHeight = false.obs;
  
  /// Idiomas selecionados (para binding com lista)
  final RxList<String> selectedLanguages = <String>[].obs;
  
  /// Toggle de preferência de idiomas (para binding com switch)
  final RxBool prioritizeLanguages = false.obs;
  
  /// Educação selecionada (para binding com dropdown/chips)
  final Rx<String?> selectedEducation = Rx<String?>(null);
  
  /// Toggle de preferência de educação (para binding com switch)
  final RxBool prioritizeEducation = false.obs;
  
  /// Filhos selecionado (para binding com chips)
  final Rx<String?> selectedChildren = Rx<String?>(null);
  
  /// Toggle de preferência de filhos (para binding com switch)
  final RxBool prioritizeChildren = false.obs;
  
  /// Beber selecionado (para binding com chips)
  final Rx<String?> selectedDrinking = Rx<String?>(null);
  
  /// Toggle de preferência de beber (para binding com switch)
  final RxBool prioritizeDrinking = false.obs;
  
  /// Fumar selecionado (para binding com chips)
  final Rx<String?> selectedSmoking = Rx<String?>(null);
  
  /// Toggle de preferência de fumar (para binding com switch)
  final RxBool prioritizeSmoking = false.obs;
  
  /// Certificação espiritual (para binding com chips)
  final Rx<bool?> requiresCertification = Rx<bool?>(null);
  
  /// Toggle de preferência de certificação (para binding com switch)
  final RxBool prioritizeCertification = false.obs;
  
  /// Movimento Deus é Pai (para binding com chips)
  final Rx<bool?> requiresDeusEPaiMember = Rx<bool?>(null);
  
  /// Toggle de preferência de Deus é Pai (para binding com switch)
  final RxBool prioritizeDeusEPaiMember = false.obs;
  
  /// Virgindade selecionada (para binding com chips)
  final Rx<String?> selectedVirginity = Rx<String?>(null);
  
  /// Toggle de preferência de virgindade (para binding com switch)
  final RxBool prioritizeVirginity = false.obs;
  
  /// Hobbies selecionados (para binding com chips)
  final RxList<String> selectedHobbies = <String>[].obs;
  
  /// Toggle de preferência de hobbies (para binding com switch)
  final RxBool prioritizeHobbies = false.obs;
  
  /// Verifica se há alterações não salvas
  RxBool get hasUnsavedChanges {
    return (currentFilters.value != savedFilters.value).obs;
  }
  
  /// Carrega filtros salvos do Firestore
  Future<void> loadSearchFilters() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      
      EnhancedLogger.info('Loading search filters', 
        tag: 'EXPLORE_PROFILES_CONTROLLER',
        data: {'userId': currentUser.uid}
      );
      
      // Buscar perfil do usuário
      final profile = await SpiritualProfileRepository.getProfileByUserId(currentUser.uid);
      
      if (profile != null && profile.searchFilters != null) {
        final filters = SearchFilters.fromJson(profile.searchFilters!);
        currentFilters.value = filters;
        savedFilters.value = filters;
        maxDistance.value = filters.maxDistance;
        prioritizeDistance.value = filters.prioritizeDistance;
        minAge.value = filters.minAge;
        maxAge.value = filters.maxAge;
        prioritizeAge.value = filters.prioritizeAge;
        minHeight.value = filters.minHeight;
        maxHeight.value = filters.maxHeight;
        prioritizeHeight.value = filters.prioritizeHeight;
        selectedLanguages.value = filters.selectedLanguages;
        prioritizeLanguages.value = filters.prioritizeLanguages;
        selectedEducation.value = filters.selectedEducation;
        prioritizeEducation.value = filters.prioritizeEducation;
        selectedChildren.value = filters.selectedChildren;
        prioritizeChildren.value = filters.prioritizeChildren;
        selectedDrinking.value = filters.selectedDrinking;
        prioritizeDrinking.value = filters.prioritizeDrinking;
        selectedSmoking.value = filters.selectedSmoking;
        prioritizeSmoking.value = filters.prioritizeSmoking;
        requiresCertification.value = filters.requiresCertification;
        prioritizeCertification.value = filters.prioritizeCertification;
        requiresDeusEPaiMember.value = filters.requiresDeusEPaiMember;
        prioritizeDeusEPaiMember.value = filters.prioritizeDeusEPaiMember;
        selectedVirginity.value = filters.selectedVirginity;
        prioritizeVirginity.value = filters.prioritizeVirginity;
        selectedHobbies.value = filters.selectedHobbies;
        prioritizeHobbies.value = filters.prioritizeHobbies;
        
        EnhancedLogger.success('Search filters loaded', 
          tag: 'EXPLORE_PROFILES_CONTROLLER',
          data: {
            'maxDistance': filters.maxDistance,
            'prioritizeDistance': filters.prioritizeDistance,
            'minAge': filters.minAge,
            'maxAge': filters.maxAge,
            'prioritizeAge': filters.prioritizeAge,
            'minHeight': filters.minHeight,
            'maxHeight': filters.maxHeight,
            'prioritizeHeight': filters.prioritizeHeight,
            'selectedLanguages': filters.selectedLanguages,
            'prioritizeLanguages': filters.prioritizeLanguages,
            'selectedEducation': filters.selectedEducation,
            'prioritizeEducation': filters.prioritizeEducation,
            'selectedChildren': filters.selectedChildren,
            'prioritizeChildren': filters.prioritizeChildren,
            'selectedDrinking': filters.selectedDrinking,
            'prioritizeDrinking': filters.prioritizeDrinking,
            'selectedSmoking': filters.selectedSmoking,
            'prioritizeSmoking': filters.prioritizeSmoking,
            'requiresCertification': filters.requiresCertification,
            'prioritizeCertification': filters.prioritizeCertification,
            'requiresDeusEPaiMember': filters.requiresDeusEPaiMember,
            'prioritizeDeusEPaiMember': filters.prioritizeDeusEPaiMember,
            'selectedVirginity': filters.selectedVirginity,
            'prioritizeVirginity': filters.prioritizeVirginity,
            'selectedHobbies': filters.selectedHobbies,
            'prioritizeHobbies': filters.prioritizeHobbies,
          }
        );
      } else {
        // Usar filtros padrão
        final defaultFilters = SearchFilters.defaultFilters();
        currentFilters.value = defaultFilters;
        savedFilters.value = defaultFilters;
        maxDistance.value = defaultFilters.maxDistance;
        prioritizeDistance.value = defaultFilters.prioritizeDistance;
        minAge.value = defaultFilters.minAge;
        maxAge.value = defaultFilters.maxAge;
        prioritizeAge.value = defaultFilters.prioritizeAge;
        minHeight.value = defaultFilters.minHeight;
        maxHeight.value = defaultFilters.maxHeight;
        prioritizeHeight.value = defaultFilters.prioritizeHeight;
        selectedLanguages.value = defaultFilters.selectedLanguages;
        prioritizeLanguages.value = defaultFilters.prioritizeLanguages;
        selectedEducation.value = defaultFilters.selectedEducation;
        prioritizeEducation.value = defaultFilters.prioritizeEducation;
        selectedChildren.value = defaultFilters.selectedChildren;
        prioritizeChildren.value = defaultFilters.prioritizeChildren;
        selectedDrinking.value = defaultFilters.selectedDrinking;
        prioritizeDrinking.value = defaultFilters.prioritizeDrinking;
        selectedSmoking.value = defaultFilters.selectedSmoking;
        prioritizeSmoking.value = defaultFilters.prioritizeSmoking;
        requiresCertification.value = defaultFilters.requiresCertification;
        prioritizeCertification.value = defaultFilters.prioritizeCertification;
        requiresDeusEPaiMember.value = defaultFilters.requiresDeusEPaiMember;
        prioritizeDeusEPaiMember.value = defaultFilters.prioritizeDeusEPaiMember;
        selectedVirginity.value = defaultFilters.selectedVirginity;
        prioritizeVirginity.value = defaultFilters.prioritizeVirginity;
        selectedHobbies.value = defaultFilters.selectedHobbies;
        prioritizeHobbies.value = defaultFilters.prioritizeHobbies;
        
        EnhancedLogger.info('Using default search filters', 
          tag: 'EXPLORE_PROFILES_CONTROLLER'
        );
      }
    } catch (e) {
      EnhancedLogger.error('Failed to load search filters', 
        tag: 'EXPLORE_PROFILES_CONTROLLER',
        error: e
      );
    }
  }
  
  /// Salva filtros no Firestore
  Future<void> saveSearchFilters() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        Get.snackbar(
          'Erro',
          'Você precisa estar logado',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[800],
        );
        return;
      }
      
      EnhancedLogger.info('Saving search filters', 
        tag: 'EXPLORE_PROFILES_CONTROLLER',
        data: {
          'maxDistance': maxDistance.value,
          'prioritizeDistance': prioritizeDistance.value,
          'minAge': minAge.value,
          'maxAge': maxAge.value,
          'prioritizeAge': prioritizeAge.value,
          'minHeight': minHeight.value,
          'maxHeight': maxHeight.value,
          'prioritizeHeight': prioritizeHeight.value,
          'selectedLanguages': selectedLanguages,
          'prioritizeLanguages': prioritizeLanguages.value,
          'selectedEducation': selectedEducation.value,
          'prioritizeEducation': prioritizeEducation.value,
          'selectedChildren': selectedChildren.value,
          'prioritizeChildren': prioritizeChildren.value,
          'selectedDrinking': selectedDrinking.value,
          'prioritizeDrinking': prioritizeDrinking.value,
          'selectedSmoking': selectedSmoking.value,
          'prioritizeSmoking': prioritizeSmoking.value,
          'requiresCertification': requiresCertification.value,
          'prioritizeCertification': prioritizeCertification.value,
          'requiresDeusEPaiMember': requiresDeusEPaiMember.value,
          'prioritizeDeusEPaiMember': prioritizeDeusEPaiMember.value,
          'selectedVirginity': selectedVirginity.value,
          'prioritizeVirginity': prioritizeVirginity.value,
          'selectedHobbies': selectedHobbies,
          'prioritizeHobbies': prioritizeHobbies.value,
        }
      );
      
      // Criar novo filtro com valores atuais
      final newFilters = SearchFilters(
        maxDistance: maxDistance.value,
        prioritizeDistance: prioritizeDistance.value,
        minAge: minAge.value,
        maxAge: maxAge.value,
        prioritizeAge: prioritizeAge.value,
        minHeight: minHeight.value,
        maxHeight: maxHeight.value,
        prioritizeHeight: prioritizeHeight.value,
        selectedLanguages: selectedLanguages.toList(),
        prioritizeLanguages: prioritizeLanguages.value,
        selectedEducation: selectedEducation.value,
        prioritizeEducation: prioritizeEducation.value,
        selectedChildren: selectedChildren.value,
        prioritizeChildren: prioritizeChildren.value,
        selectedDrinking: selectedDrinking.value,
        prioritizeDrinking: prioritizeDrinking.value,
        selectedSmoking: selectedSmoking.value,
        prioritizeSmoking: prioritizeSmoking.value,
        requiresCertification: requiresCertification.value,
        prioritizeCertification: prioritizeCertification.value,
        requiresDeusEPaiMember: requiresDeusEPaiMember.value,
        prioritizeDeusEPaiMember: prioritizeDeusEPaiMember.value,
        selectedVirginity: selectedVirginity.value,
        prioritizeVirginity: prioritizeVirginity.value,
        selectedHobbies: selectedHobbies.toList(),
        prioritizeHobbies: prioritizeHobbies.value,
        lastUpdated: DateTime.now(),
      );
      
      // Salvar no Firestore
      final profile = await SpiritualProfileRepository.getProfileByUserId(currentUser.uid);
      if (profile != null) {
        await SpiritualProfileRepository.updateProfile(profile.id!, {
          'searchFilters': newFilters.toJson(),
        });
      }
      
      // Atualizar filtros salvos
      currentFilters.value = newFilters;
      savedFilters.value = newFilters;
      
      EnhancedLogger.success('Search filters saved', 
        tag: 'EXPLORE_PROFILES_CONTROLLER'
      );
      
      Get.snackbar(
        'Sucesso!',
        'Filtros de busca salvos',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[100],
        colorText: Colors.green[800],
        duration: const Duration(seconds: 2),
        icon: const Icon(Icons.check_circle, color: Colors.green),
      );
    } catch (e) {
      EnhancedLogger.error('Failed to save search filters', 
        tag: 'EXPLORE_PROFILES_CONTROLLER',
        error: e
      );
      
      Get.snackbar(
        'Erro',
        'Não foi possível salvar os filtros',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
    }
  }
  
  /// Reseta filtros para valores padrão
  void resetFilters() {
    final defaultFilters = SearchFilters.defaultFilters();
    maxDistance.value = defaultFilters.maxDistance;
    prioritizeDistance.value = defaultFilters.prioritizeDistance;
    minAge.value = defaultFilters.minAge;
    maxAge.value = defaultFilters.maxAge;
    prioritizeAge.value = defaultFilters.prioritizeAge;
    minHeight.value = defaultFilters.minHeight;
    maxHeight.value = defaultFilters.maxHeight;
    prioritizeHeight.value = defaultFilters.prioritizeHeight;
    selectedLanguages.value = defaultFilters.selectedLanguages;
    prioritizeLanguages.value = defaultFilters.prioritizeLanguages;
    selectedEducation.value = defaultFilters.selectedEducation;
    prioritizeEducation.value = defaultFilters.prioritizeEducation;
    selectedChildren.value = defaultFilters.selectedChildren;
    prioritizeChildren.value = defaultFilters.prioritizeChildren;
    selectedDrinking.value = defaultFilters.selectedDrinking;
    prioritizeDrinking.value = defaultFilters.prioritizeDrinking;
    selectedSmoking.value = defaultFilters.selectedSmoking;
    prioritizeSmoking.value = defaultFilters.prioritizeSmoking;
    requiresCertification.value = defaultFilters.requiresCertification;
    prioritizeCertification.value = defaultFilters.prioritizeCertification;
    requiresDeusEPaiMember.value = defaultFilters.requiresDeusEPaiMember;
    prioritizeDeusEPaiMember.value = defaultFilters.prioritizeDeusEPaiMember;
    selectedVirginity.value = defaultFilters.selectedVirginity;
    prioritizeVirginity.value = defaultFilters.prioritizeVirginity;
    selectedHobbies.value = defaultFilters.selectedHobbies;
    prioritizeHobbies.value = defaultFilters.prioritizeHobbies;
    currentFilters.value = defaultFilters;
    
    EnhancedLogger.info('Filters reset to default', 
      tag: 'EXPLORE_PROFILES_CONTROLLER'
    );
  }
  
  /// Atualiza distância máxima
  void updateMaxDistance(int distance) {
    maxDistance.value = distance;
    currentFilters.value = currentFilters.value.copyWith(
      maxDistance: distance,
    );
  }
  
  /// Atualiza toggle de preferência de distância
  void updatePrioritizeDistance(bool value) {
    prioritizeDistance.value = value;
    currentFilters.value = currentFilters.value.copyWith(
      prioritizeDistance: value,
    );
  }
  
  /// Atualiza faixa etária
  void updateAgeRange(int min, int max) {
    minAge.value = min;
    maxAge.value = max;
    currentFilters.value = currentFilters.value.copyWith(
      minAge: min,
      maxAge: max,
    );
  }
  
  /// Atualiza toggle de preferência de idade
  void updatePrioritizeAge(bool value) {
    prioritizeAge.value = value;
    currentFilters.value = currentFilters.value.copyWith(
      prioritizeAge: value,
    );
  }
  
  /// Atualiza faixa de altura
  void updateHeightRange(int min, int max) {
    minHeight.value = min;
    maxHeight.value = max;
    currentFilters.value = currentFilters.value.copyWith(
      minHeight: min,
      maxHeight: max,
    );
  }
  
  /// Atualiza toggle de preferência de altura
  void updatePrioritizeHeight(bool value) {
    prioritizeHeight.value = value;
    currentFilters.value = currentFilters.value.copyWith(
      prioritizeHeight: value,
    );
  }
  
  /// Mostra dialog de confirmação ao voltar
  Future<bool> showSaveDialog(BuildContext context) async {
    if (currentFilters.value == savedFilters.value) {
      return true; // Sem alterações, pode voltar
    }
    
    final result = await SaveFiltersDialog.show(context);
    
    if (result == true) {
      // Salvar
      await saveSearchFilters();
      return true;
    } else if (result == false) {
      // Descartar
      resetToSavedFilters();
      return true;
    }
    
    return false; // Cancelou
  }
  
  /// Restaura filtros para valores salvos
  void resetToSavedFilters() {
    maxDistance.value = savedFilters.value.maxDistance;
    prioritizeDistance.value = savedFilters.value.prioritizeDistance;
    minAge.value = savedFilters.value.minAge;
    maxAge.value = savedFilters.value.maxAge;
    prioritizeAge.value = savedFilters.value.prioritizeAge;
    minHeight.value = savedFilters.value.minHeight;
    maxHeight.value = savedFilters.value.maxHeight;
    prioritizeHeight.value = savedFilters.value.prioritizeHeight;
    selectedLanguages.value = savedFilters.value.selectedLanguages;
    prioritizeLanguages.value = savedFilters.value.prioritizeLanguages;
    selectedEducation.value = savedFilters.value.selectedEducation;
    prioritizeEducation.value = savedFilters.value.prioritizeEducation;
    selectedChildren.value = savedFilters.value.selectedChildren;
    prioritizeChildren.value = savedFilters.value.prioritizeChildren;
    selectedDrinking.value = savedFilters.value.selectedDrinking;
    prioritizeDrinking.value = savedFilters.value.prioritizeDrinking;
    selectedSmoking.value = savedFilters.value.selectedSmoking;
    prioritizeSmoking.value = savedFilters.value.prioritizeSmoking;
    requiresCertification.value = savedFilters.value.requiresCertification;
    prioritizeCertification.value = savedFilters.value.prioritizeCertification;
    requiresDeusEPaiMember.value = savedFilters.value.requiresDeusEPaiMember;
    prioritizeDeusEPaiMember.value = savedFilters.value.prioritizeDeusEPaiMember;
    selectedVirginity.value = savedFilters.value.selectedVirginity;
    prioritizeVirginity.value = savedFilters.value.prioritizeVirginity;
    selectedHobbies.value = savedFilters.value.selectedHobbies;
    prioritizeHobbies.value = savedFilters.value.prioritizeHobbies;
    currentFilters.value = savedFilters.value;
    
    EnhancedLogger.info('Filters reset to saved values', 
      tag: 'EXPLORE_PROFILES_CONTROLLER'
    );
  }
  
  /// Atualiza idiomas selecionados
  void updateSelectedLanguages(List<String> languages) {
    selectedLanguages.value = languages;
    currentFilters.value = currentFilters.value.copyWith(
      selectedLanguages: languages,
    );
  }
  
  /// Atualiza toggle de preferência de idiomas
  void updatePrioritizeLanguages(bool value) {
    prioritizeLanguages.value = value;
    currentFilters.value = currentFilters.value.copyWith(
      prioritizeLanguages: value,
    );
  }
  
  /// Atualiza educação selecionada
  void updateSelectedEducation(String? education) {
    selectedEducation.value = education;
    currentFilters.value = currentFilters.value.copyWith(
      selectedEducation: education,
    );
  }
  
  /// Atualiza toggle de preferência de educação
  void updatePrioritizeEducation(bool value) {
    prioritizeEducation.value = value;
    currentFilters.value = currentFilters.value.copyWith(
      prioritizeEducation: value,
    );
  }
  
  /// Atualiza filhos selecionado
  void updateSelectedChildren(String? children) {
    selectedChildren.value = children;
    currentFilters.value = currentFilters.value.copyWith(
      selectedChildren: children,
    );
  }
  
  /// Atualiza toggle de preferência de filhos
  void updatePrioritizeChildren(bool value) {
    prioritizeChildren.value = value;
    currentFilters.value = currentFilters.value.copyWith(
      prioritizeChildren: value,
    );
  }
  
  /// Atualiza beber selecionado
  void updateSelectedDrinking(String? drinking) {
    selectedDrinking.value = drinking;
    currentFilters.value = currentFilters.value.copyWith(
      selectedDrinking: drinking,
    );
  }
  
  /// Atualiza toggle de preferência de beber
  void updatePrioritizeDrinking(bool value) {
    prioritizeDrinking.value = value;
    currentFilters.value = currentFilters.value.copyWith(
      prioritizeDrinking: value,
    );
  }
  
  /// Atualiza fumar selecionado
  void updateSelectedSmoking(String? smoking) {
    selectedSmoking.value = smoking;
    currentFilters.value = currentFilters.value.copyWith(
      selectedSmoking: smoking,
    );
  }
  
  /// Atualiza toggle de preferência de fumar
  void updatePrioritizeSmoking(bool value) {
    prioritizeSmoking.value = value;
    currentFilters.value = currentFilters.value.copyWith(
      prioritizeSmoking: value,
    );
  }
  
  /// Atualiza certificação espiritual selecionada
  void updateRequiresCertification(bool? certification) {
    requiresCertification.value = certification;
    currentFilters.value = currentFilters.value.copyWith(
      requiresCertification: certification,
    );
  }
  
  /// Atualiza toggle de preferência de certificação
  void updatePrioritizeCertification(bool value) {
    prioritizeCertification.value = value;
    currentFilters.value = currentFilters.value.copyWith(
      prioritizeCertification: value,
    );
  }
  
  /// Atualiza movimento Deus é Pai selecionado
  void updateRequiresDeusEPaiMember(bool? member) {
    requiresDeusEPaiMember.value = member;
    currentFilters.value = currentFilters.value.copyWith(
      requiresDeusEPaiMember: member,
    );
  }
  
  /// Atualiza toggle de preferência de Deus é Pai
  void updatePrioritizeDeusEPaiMember(bool value) {
    prioritizeDeusEPaiMember.value = value;
    currentFilters.value = currentFilters.value.copyWith(
      prioritizeDeusEPaiMember: value,
    );
  }
  
  /// Atualiza virgindade selecionada
  void updateSelectedVirginity(String? virginity) {
    selectedVirginity.value = virginity;
    currentFilters.value = currentFilters.value.copyWith(
      selectedVirginity: virginity,
    );
  }
  
  /// Atualiza toggle de preferência de virgindade
  void updatePrioritizeVirginity(bool value) {
    prioritizeVirginity.value = value;
    currentFilters.value = currentFilters.value.copyWith(
      prioritizeVirginity: value,
    );
  }
  
  /// Atualiza hobbies selecionados
  void updateSelectedHobbies(List<String> hobbies) {
    selectedHobbies.value = hobbies;
    currentFilters.value = currentFilters.value.copyWith(
      selectedHobbies: hobbies,
    );
  }
  
  /// Atualiza toggle de preferência de hobbies
  void updatePrioritizeHobbies(bool value) {
    prioritizeHobbies.value = value;
    currentFilters.value = currentFilters.value.copyWith(
      prioritizeHobbies: value,
    );
  }
}