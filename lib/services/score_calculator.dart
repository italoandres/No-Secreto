import '../models/match_score.dart';
import '../models/match_level.dart';
import '../models/search_filters_model.dart';

/// Calculador de pontuação de compatibilidade
class ScoreCalculator {
  /// Pontos base por critério (quando não priorizado)
  static const Map<String, double> basePoints = {
    'distance': 10.0, // Dentro do raio
    'age': 10.0, // Dentro da faixa
    'height': 10.0, // Dentro da faixa
    'language': 15.0, // Por idioma em comum
    'education': 20.0, // Correspondência exata
    'children': 15.0, // Correspondência
    'drinking': 10.0, // Correspondência
    'smoking': 10.0, // Correspondência
    'certification': 25.0, // Selo de certificação espiritual
    'deusEPai': 20.0, // Movimento Deus é Pai
    'virginity': 15.0, // Virgindade
    'hobby': 10.0, // Por hobby em comum
  };

  /// Multiplicador quando filtro é priorizado
  static const double priorityMultiplier = 2.0;

  /// Calcula pontuação total do perfil
  MatchScore calculateScore({
    required Map<String, dynamic> profileData,
    required SearchFilters filters,
    required double distance,
  }) {
    final breakdown = <String, double>{};
    double totalScore = 0.0;
    double maxPossibleScore = 0.0;

    // 1. Distância
    final distanceScore = _calculateDistanceScore(
      distance: distance,
      maxDistance: filters.maxDistance.toDouble(),
      isPrioritized: filters.prioritizeDistance,
    );
    breakdown['distance'] = distanceScore['earned']!;
    totalScore += distanceScore['earned']!;
    maxPossibleScore += distanceScore['max']!;

    // 2. Idade
    final ageScore = _calculateAgeScore(
      profileAge: profileData['age'] as int? ?? 0,
      minAge: filters.minAge,
      maxAge: filters.maxAge,
      isPrioritized: filters.prioritizeAge,
    );
    breakdown['age'] = ageScore['earned']!;
    totalScore += ageScore['earned']!;
    maxPossibleScore += ageScore['max']!;

    // 3. Altura
    final profileHeightInt = _convertProfileHeight(profileData['height']);
    final heightScore = _calculateHeightScore(
      profileHeight: profileHeightInt,
      minHeight: filters.minHeight,
      maxHeight: filters.maxHeight,
      isPrioritized: filters.prioritizeHeight,
    );
    breakdown['height'] = heightScore['earned']!;
    totalScore += heightScore['earned']!;
    maxPossibleScore += heightScore['max']!;

    // 4. Idiomas
    if (filters.selectedLanguages.isNotEmpty) {
      final languageScore = _calculateLanguageScore(
        profileLanguages: _getLanguages(profileData),
        filterLanguages: filters.selectedLanguages,
        isPrioritized: filters.prioritizeLanguages,
      );
      breakdown['languages'] = languageScore['earned']!;
      totalScore += languageScore['earned']!;
      maxPossibleScore += languageScore['max']!;
    }

    // 5. Educação
    if (filters.selectedEducation != null) {
      final educationScore = _calculateEducationScore(
        profileEducation: profileData['education'] as String?,
        filterEducation: filters.selectedEducation,
        isPrioritized: filters.prioritizeEducation,
      );
      breakdown['education'] = educationScore['earned']!;
      totalScore += educationScore['earned']!;
      maxPossibleScore += educationScore['max']!;
    }

    // 6. Filhos
    if (filters.selectedChildren != null &&
        filters.selectedChildren != 'Não tenho preferência') {
      final profileChildrenStr = _convertProfileChildren(profileData['children']);
      final childrenScore = _calculateChildrenScore(
        profileChildren: profileChildrenStr,
        filterChildren: filters.selectedChildren,
        isPrioritized: filters.prioritizeChildren,
      );
      breakdown['children'] = childrenScore['earned']!;
      totalScore += childrenScore['earned']!;
      maxPossibleScore += childrenScore['max']!;
    }

    // 7. Beber
    if (filters.selectedDrinking != null &&
        filters.selectedDrinking != 'Não tenho preferência') {
      final drinkingScore = _calculateDrinkingScore(
        profileDrinking: profileData['drinking'] as String?,
        filterDrinking: filters.selectedDrinking,
        isPrioritized: filters.prioritizeDrinking,
      );
      breakdown['drinking'] = drinkingScore['earned']!;
      totalScore += drinkingScore['earned']!;
      maxPossibleScore += drinkingScore['max']!;
    }

    // 8. Fumar
    if (filters.selectedSmoking != null &&
        filters.selectedSmoking != 'Não tenho preferência') {
      final smokingScore = _calculateSmokingScore(
        profileSmoking: profileData['smoking'] as String?,
        filterSmoking: filters.selectedSmoking,
        isPrioritized: filters.prioritizeSmoking,
      );
      breakdown['smoking'] = smokingScore['earned']!;
      totalScore += smokingScore['earned']!;
      maxPossibleScore += smokingScore['max']!;
    }

    // 9. Certificação Espiritual
    if (filters.requiresCertification != null) {
      final certificationScore = _calculateCertificationScore(
        profileCertification: profileData['hasSinaisPreparationSeal'] as bool?,
        filterCertification: filters.requiresCertification,
        isPrioritized: filters.prioritizeCertification,
      );
      breakdown['certification'] = certificationScore['earned']!;
      totalScore += certificationScore['earned']!;
      maxPossibleScore += certificationScore['max']!;
    }

    // 10. Movimento Deus é Pai
    if (filters.requiresDeusEPaiMember != null) {
      final deusEPaiScore = _calculateDeusEPaiScore(
        profileMember: profileData['isDeusEPaiMember'] as bool?,
        filterMember: filters.requiresDeusEPaiMember,
        isPrioritized: filters.prioritizeDeusEPaiMember,
      );
      breakdown['deusEPai'] = deusEPaiScore['earned']!;
      totalScore += deusEPaiScore['earned']!;
      maxPossibleScore += deusEPaiScore['max']!;
    }

    // 11. Virgindade
    if (filters.selectedVirginity != null &&
        filters.selectedVirginity != 'Não tenho preferência') {
      final virginityScore = _calculateVirginityScore(
        profileVirginity: profileData['isVirgin'] as bool?,
        filterVirginity: filters.selectedVirginity,
        isPrioritized: filters.prioritizeVirginity,
      );
      breakdown['virginity'] = virginityScore['earned']!;
      totalScore += virginityScore['earned']!;
      maxPossibleScore += virginityScore['max']!;
    }

    // 12. Hobbies
    if (filters.selectedHobbies.isNotEmpty) {
      final hobbiesScore = _calculateHobbiesScore(
        profileHobbies: _getHobbies(profileData),
        filterHobbies: filters.selectedHobbies,
        isPrioritized: filters.prioritizeHobbies,
      );
      breakdown['hobbies'] = hobbiesScore['earned']!;
      totalScore += hobbiesScore['earned']!;
      maxPossibleScore += hobbiesScore['max']!;
    }

    // Normalizar para 0-100
    final normalizedScore = _normalizeScore(totalScore, maxPossibleScore);
    final level = MatchLevelExtension.fromScore(normalizedScore);

    return MatchScore(
      totalScore: normalizedScore,
      level: level,
      breakdown: breakdown,
    );
  }

  /// Calcula pontos para distância
  Map<String, double> _calculateDistanceScore({
    required double distance,
    required double maxDistance,
    required bool isPrioritized,
  }) {
    final basePoint = basePoints['distance']!;
    final multiplier = isPrioritized ? priorityMultiplier : 1.0;
    final maxPoints = basePoint * multiplier;

    // Ganha pontos se está dentro do raio
    final earnedPoints = distance <= maxDistance ? maxPoints : 0.0;

    return {'earned': earnedPoints, 'max': maxPoints};
  }

  /// Calcula pontos para idade
  Map<String, double> _calculateAgeScore({
    required int profileAge,
    required int minAge,
    required int maxAge,
    required bool isPrioritized,
  }) {
    final basePoint = basePoints['age']!;
    final multiplier = isPrioritized ? priorityMultiplier : 1.0;
    final maxPoints = basePoint * multiplier;

    // Ganha pontos se está dentro da faixa
    final earnedPoints =
        (profileAge >= minAge && profileAge <= maxAge) ? maxPoints : 0.0;

    return {'earned': earnedPoints, 'max': maxPoints};
  }

  /// Calcula pontos para altura
  Map<String, double> _calculateHeightScore({
    required int profileHeight,
    required int minHeight,
    required int maxHeight,
    required bool isPrioritized,
  }) {
    final basePoint = basePoints['height']!;
    final multiplier = isPrioritized ? priorityMultiplier : 1.0;
    final maxPoints = basePoint * multiplier;

    // Ganha pontos se está dentro da faixa
    final earnedPoints =
        (profileHeight >= minHeight && profileHeight <= maxHeight)
            ? maxPoints
            : 0.0;

    return {'earned': earnedPoints, 'max': maxPoints};
  }

  /// Calcula pontos para idiomas
  Map<String, double> _calculateLanguageScore({
    required List<String> profileLanguages,
    required List<String> filterLanguages,
    required bool isPrioritized,
  }) {
    final basePoint = basePoints['language']!;
    final multiplier = isPrioritized ? priorityMultiplier : 1.0;

    // Conta idiomas em comum
    int commonLanguages = 0;
    for (final lang in filterLanguages) {
      if (profileLanguages.contains(lang)) {
        commonLanguages++;
      }
    }

    final earnedPoints = basePoint * commonLanguages * multiplier;
    final maxPoints = basePoint * filterLanguages.length * multiplier;

    return {'earned': earnedPoints, 'max': maxPoints};
  }

  /// Calcula pontos para educação
  Map<String, double> _calculateEducationScore({
    required String? profileEducation,
    required String? filterEducation,
    required bool isPrioritized,
  }) {
    final basePoint = basePoints['education']!;
    final multiplier = isPrioritized ? priorityMultiplier : 1.0;
    final maxPoints = basePoint * multiplier;

    // Ganha pontos se há correspondência exata
    final earnedPoints =
        (profileEducation == filterEducation) ? maxPoints : 0.0;

    return {'earned': earnedPoints, 'max': maxPoints};
  }

  /// Calcula pontos para filhos
  Map<String, double> _calculateChildrenScore({
    required String? profileChildren,
    required String? filterChildren,
    required bool isPrioritized,
  }) {
    final basePoint = basePoints['children']!;
    final multiplier = isPrioritized ? priorityMultiplier : 1.0;
    final maxPoints = basePoint * multiplier;

    // Ganha pontos se há correspondência
    final earnedPoints = (profileChildren == filterChildren) ? maxPoints : 0.0;

    return {'earned': earnedPoints, 'max': maxPoints};
  }

  /// Calcula pontos para beber
  Map<String, double> _calculateDrinkingScore({
    required String? profileDrinking,
    required String? filterDrinking,
    required bool isPrioritized,
  }) {
    final basePoint = basePoints['drinking']!;
    final multiplier = isPrioritized ? priorityMultiplier : 1.0;
    final maxPoints = basePoint * multiplier;

    // Ganha pontos se há correspondência
    final earnedPoints =
        (profileDrinking == filterDrinking) ? maxPoints : 0.0;

    return {'earned': earnedPoints, 'max': maxPoints};
  }

  /// Calcula pontos para fumar
  Map<String, double> _calculateSmokingScore({
    required String? profileSmoking,
    required String? filterSmoking,
    required bool isPrioritized,
  }) {
    final basePoint = basePoints['smoking']!;
    final multiplier = isPrioritized ? priorityMultiplier : 1.0;
    final maxPoints = basePoint * multiplier;

    // Ganha pontos se há correspondência
    final earnedPoints = (profileSmoking == filterSmoking) ? maxPoints : 0.0;

    return {'earned': earnedPoints, 'max': maxPoints};
  }

  /// Normaliza pontuação para escala 0-100
  double _normalizeScore(double rawScore, double maxPossibleScore) {
    if (maxPossibleScore == 0) return 0;
    final normalized = (rawScore / maxPossibleScore) * 100;
    return normalized.clamp(0, 100);
  }

  /// Extrai lista de idiomas do perfil
  List<String> _getLanguages(Map<String, dynamic> profileData) {
    final languages = profileData['languages'];
    if (languages is List) {
      return languages.cast<String>();
    }
    return [];
  }

  /// Converte altura do perfil (pode ser String ou int) para int em cm
  int _convertProfileHeight(dynamic height) {
    if (height == null) return 0;
    
    // Se já é int, retorna direto
    if (height is int) return height;
    
    // Se é String, converte
    if (height is String) {
      // Usa o método do SearchFiltersModel
      return SearchFilters.convertHeightStringToInt(height) ?? 0;
    }
    
    return 0;
  }

  /// Converte filhos do perfil (pode ser bool ou String) para String do filtro
  String? _convertProfileChildren(dynamic children) {
    if (children == null) return null;
    
    // Se já é String, retorna direto
    if (children is String) return children;
    
    // Se é bool, converte
    if (children is bool) {
      return SearchFilters.mapChildrenBoolToString(children);
    }
    
    return null;
  }

  /// Calcula pontos para certificação espiritual
  Map<String, double> _calculateCertificationScore({
    required bool? profileCertification,
    required bool? filterCertification,
    required bool isPrioritized,
  }) {
    final basePoint = ScoreCalculator.basePoints['certification']!;
    final multiplier = isPrioritized ? ScoreCalculator.priorityMultiplier : 1.0;
    final maxPoints = basePoint * multiplier;

    // Ganha pontos se há correspondência
    final earnedPoints = (profileCertification == filterCertification) ? maxPoints : 0.0;

    return {'earned': earnedPoints, 'max': maxPoints};
  }

  /// Calcula pontos para movimento Deus é Pai
  Map<String, double> _calculateDeusEPaiScore({
    required bool? profileMember,
    required bool? filterMember,
    required bool isPrioritized,
  }) {
    final basePoint = ScoreCalculator.basePoints['deusEPai']!;
    final multiplier = isPrioritized ? ScoreCalculator.priorityMultiplier : 1.0;
    final maxPoints = basePoint * multiplier;

    // Ganha pontos se há correspondência
    final earnedPoints = (profileMember == filterMember) ? maxPoints : 0.0;

    return {'earned': earnedPoints, 'max': maxPoints};
  }

  /// Calcula pontos para virgindade
  Map<String, double> _calculateVirginityScore({
    required bool? profileVirginity,
    required String? filterVirginity,
    required bool isPrioritized,
  }) {
    final basePoint = ScoreCalculator.basePoints['virginity']!;
    final multiplier = isPrioritized ? ScoreCalculator.priorityMultiplier : 1.0;
    final maxPoints = basePoint * multiplier;

    // Converte String do filtro para bool
    bool? filterBool;
    if (filterVirginity == 'Virgem') {
      filterBool = true;
    } else if (filterVirginity == 'Não virgem') {
      filterBool = false;
    }

    // Ganha pontos se há correspondência
    final earnedPoints = (profileVirginity == filterBool) ? maxPoints : 0.0;

    return {'earned': earnedPoints, 'max': maxPoints};
  }

  /// Calcula pontos para hobbies
  Map<String, double> _calculateHobbiesScore({
    required List<String> profileHobbies,
    required List<String> filterHobbies,
    required bool isPrioritized,
  }) {
    final basePoint = ScoreCalculator.basePoints['hobby']!;
    final multiplier = isPrioritized ? ScoreCalculator.priorityMultiplier : 1.0;

    // Conta hobbies em comum
    int commonHobbies = 0;
    for (final hobby in filterHobbies) {
      if (profileHobbies.contains(hobby)) {
        commonHobbies++;
      }
    }

    final earnedPoints = basePoint * commonHobbies * multiplier;
    final maxPoints = basePoint * filterHobbies.length * multiplier;

    return {'earned': earnedPoints, 'max': maxPoints};
  }

  /// Extrai lista de hobbies do perfil
  List<String> _getHobbies(Map<String, dynamic> profileData) {
    final hobbies = profileData['hobbies'];
    if (hobbies is List) {
      return hobbies.cast<String>();
    }
    return [];
  }
}
