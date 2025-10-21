import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para filtros de busca do usuário
class SearchFilters {
  final int maxDistance; // em km (5 a 400+)
  final bool prioritizeDistance; // toggle de preferência de distância
  final int minAge; // idade mínima (18 a 100)
  final int maxAge; // idade máxima (18 a 100)
  final bool prioritizeAge; // toggle de preferência de idade
  final int minHeight; // altura mínima em cm (91 a 214)
  final int maxHeight; // altura máxima em cm (91 a 214)
  final bool prioritizeHeight; // toggle de preferência de altura
  final List<String> selectedLanguages; // idiomas selecionados
  final bool prioritizeLanguages; // toggle de preferência de idiomas
  final String? selectedEducation; // nível de educação selecionado
  final bool prioritizeEducation; // toggle de preferência de educação
  final String? selectedChildren; // filhos
  final bool prioritizeChildren; // toggle de preferência de filhos
  final String? selectedDrinking; // beber
  final bool prioritizeDrinking; // toggle de preferência de beber
  final String? selectedSmoking; // fumar
  final bool prioritizeSmoking; // toggle de preferência de fumar
  final bool? requiresCertification; // selo de certificação espiritual
  final bool prioritizeCertification; // toggle de preferência de certificação
  final bool? requiresDeusEPaiMember; // movimento Deus é Pai
  final bool prioritizeDeusEPaiMember; // toggle de preferência Deus é Pai
  final String? selectedVirginity; // virgindade
  final bool prioritizeVirginity; // toggle de preferência de virgindade
  final List<String> selectedHobbies; // hobbies selecionados
  final bool prioritizeHobbies; // toggle de preferência de hobbies
  final DateTime? lastUpdated;

  const SearchFilters({
    required this.maxDistance,
    required this.prioritizeDistance,
    required this.minAge,
    required this.maxAge,
    required this.prioritizeAge,
    required this.minHeight,
    required this.maxHeight,
    required this.prioritizeHeight,
    required this.selectedLanguages,
    required this.prioritizeLanguages,
    this.selectedEducation,
    required this.prioritizeEducation,
    this.selectedChildren,
    required this.prioritizeChildren,
    this.selectedDrinking,
    required this.prioritizeDrinking,
    this.selectedSmoking,
    required this.prioritizeSmoking,
    this.requiresCertification,
    required this.prioritizeCertification,
    this.requiresDeusEPaiMember,
    required this.prioritizeDeusEPaiMember,
    this.selectedVirginity,
    required this.prioritizeVirginity,
    required this.selectedHobbies,
    required this.prioritizeHobbies,
    this.lastUpdated,
  });

  /// Valores padrão
  factory SearchFilters.defaultFilters() {
    return SearchFilters(
      maxDistance: 50,
      prioritizeDistance: false,
      minAge: 18,
      maxAge: 65,
      prioritizeAge: false,
      minHeight: 150,
      maxHeight: 190,
      prioritizeHeight: false,
      selectedLanguages: [],
      prioritizeLanguages: false,
      selectedEducation: null,
      prioritizeEducation: false,
      selectedChildren: null,
      prioritizeChildren: false,
      selectedDrinking: null,
      prioritizeDrinking: false,
      selectedSmoking: null,
      prioritizeSmoking: false,
      requiresCertification: null,
      prioritizeCertification: false,
      requiresDeusEPaiMember: null,
      prioritizeDeusEPaiMember: false,
      selectedVirginity: null,
      prioritizeVirginity: false,
      selectedHobbies: [],
      prioritizeHobbies: false,
      lastUpdated: DateTime.now(),
    );
  }

  /// Cria a partir de Firestore
  factory SearchFilters.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return SearchFilters.defaultFilters();
    return SearchFilters.fromJson(data);
  }

  /// Cria a partir de JSON
  factory SearchFilters.fromJson(Map<String, dynamic> json) {
    return SearchFilters(
      maxDistance: json['maxDistance'] ?? 50,
      prioritizeDistance: json['prioritizeDistance'] ?? false,
      minAge: json['minAge'] ?? 18,
      maxAge: json['maxAge'] ?? 65,
      prioritizeAge: json['prioritizeAge'] ?? false,
      minHeight: json['minHeight'] ?? 150,
      maxHeight: json['maxHeight'] ?? 190,
      prioritizeHeight: json['prioritizeHeight'] ?? false,
      selectedLanguages: json['selectedLanguages'] != null
          ? List<String>.from(json['selectedLanguages'])
          : [],
      prioritizeLanguages: json['prioritizeLanguages'] ?? false,
      selectedEducation: json['selectedEducation'],
      prioritizeEducation: json['prioritizeEducation'] ?? false,
      selectedChildren: json['selectedChildren'],
      prioritizeChildren: json['prioritizeChildren'] ?? false,
      selectedDrinking: json['selectedDrinking'],
      prioritizeDrinking: json['prioritizeDrinking'] ?? false,
      selectedSmoking: json['selectedSmoking'],
      prioritizeSmoking: json['prioritizeSmoking'] ?? false,
      requiresCertification: json['requiresCertification'],
      prioritizeCertification: json['prioritizeCertification'] ?? false,
      requiresDeusEPaiMember: json['requiresDeusEPaiMember'],
      prioritizeDeusEPaiMember: json['prioritizeDeusEPaiMember'] ?? false,
      selectedVirginity: json['selectedVirginity'],
      prioritizeVirginity: json['prioritizeVirginity'] ?? false,
      selectedHobbies: json['selectedHobbies'] != null
          ? List<String>.from(json['selectedHobbies'])
          : [],
      prioritizeHobbies: json['prioritizeHobbies'] ?? false,
      lastUpdated: json['lastUpdated'] != null
          ? (json['lastUpdated'] as Timestamp).toDate()
          : null,
    );
  }

  /// Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      'maxDistance': maxDistance,
      'prioritizeDistance': prioritizeDistance,
      'minAge': minAge,
      'maxAge': maxAge,
      'prioritizeAge': prioritizeAge,
      'minHeight': minHeight,
      'maxHeight': maxHeight,
      'prioritizeHeight': prioritizeHeight,
      'selectedLanguages': selectedLanguages,
      'prioritizeLanguages': prioritizeLanguages,
      'selectedEducation': selectedEducation,
      'prioritizeEducation': prioritizeEducation,
      'selectedChildren': selectedChildren,
      'prioritizeChildren': prioritizeChildren,
      'selectedDrinking': selectedDrinking,
      'prioritizeDrinking': prioritizeDrinking,
      'selectedSmoking': selectedSmoking,
      'prioritizeSmoking': prioritizeSmoking,
      'requiresCertification': requiresCertification,
      'prioritizeCertification': prioritizeCertification,
      'requiresDeusEPaiMember': requiresDeusEPaiMember,
      'prioritizeDeusEPaiMember': prioritizeDeusEPaiMember,
      'selectedVirginity': selectedVirginity,
      'prioritizeVirginity': prioritizeVirginity,
      'selectedHobbies': selectedHobbies,
      'prioritizeHobbies': prioritizeHobbies,
      'lastUpdated': lastUpdated != null 
          ? Timestamp.fromDate(lastUpdated!) 
          : FieldValue.serverTimestamp(),
    };
  }

  /// Cria cópia com alterações
  SearchFilters copyWith({
    int? maxDistance,
    bool? prioritizeDistance,
    int? minAge,
    int? maxAge,
    bool? prioritizeAge,
    int? minHeight,
    int? maxHeight,
    bool? prioritizeHeight,
    List<String>? selectedLanguages,
    bool? prioritizeLanguages,
    String? selectedEducation,
    bool? prioritizeEducation,
    String? selectedChildren,
    bool? prioritizeChildren,
    String? selectedDrinking,
    bool? prioritizeDrinking,
    String? selectedSmoking,
    bool? prioritizeSmoking,
    bool? requiresCertification,
    bool? prioritizeCertification,
    bool? requiresDeusEPaiMember,
    bool? prioritizeDeusEPaiMember,
    String? selectedVirginity,
    bool? prioritizeVirginity,
    List<String>? selectedHobbies,
    bool? prioritizeHobbies,
    DateTime? lastUpdated,
  }) {
    return SearchFilters(
      maxDistance: maxDistance ?? this.maxDistance,
      prioritizeDistance: prioritizeDistance ?? this.prioritizeDistance,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      prioritizeAge: prioritizeAge ?? this.prioritizeAge,
      minHeight: minHeight ?? this.minHeight,
      maxHeight: maxHeight ?? this.maxHeight,
      prioritizeHeight: prioritizeHeight ?? this.prioritizeHeight,
      selectedLanguages: selectedLanguages ?? this.selectedLanguages,
      prioritizeLanguages: prioritizeLanguages ?? this.prioritizeLanguages,
      selectedEducation: selectedEducation ?? this.selectedEducation,
      prioritizeEducation: prioritizeEducation ?? this.prioritizeEducation,
      selectedChildren: selectedChildren ?? this.selectedChildren,
      prioritizeChildren: prioritizeChildren ?? this.prioritizeChildren,
      selectedDrinking: selectedDrinking ?? this.selectedDrinking,
      prioritizeDrinking: prioritizeDrinking ?? this.prioritizeDrinking,
      selectedSmoking: selectedSmoking ?? this.selectedSmoking,
      prioritizeSmoking: prioritizeSmoking ?? this.prioritizeSmoking,
      requiresCertification: requiresCertification ?? this.requiresCertification,
      prioritizeCertification: prioritizeCertification ?? this.prioritizeCertification,
      requiresDeusEPaiMember: requiresDeusEPaiMember ?? this.requiresDeusEPaiMember,
      prioritizeDeusEPaiMember: prioritizeDeusEPaiMember ?? this.prioritizeDeusEPaiMember,
      selectedVirginity: selectedVirginity ?? this.selectedVirginity,
      prioritizeVirginity: prioritizeVirginity ?? this.prioritizeVirginity,
      selectedHobbies: selectedHobbies ?? this.selectedHobbies,
      prioritizeHobbies: prioritizeHobbies ?? this.prioritizeHobbies,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Formata distância para exibição
  String get formattedDistance {
    if (maxDistance >= 400) {
      return '400+ km';
    }
    return '$maxDistance km';
  }

  /// Formata altura para exibição
  String get formattedHeight {
    return '$minHeight cm - $maxHeight cm';
  }

  /// Formata idiomas para exibição
  String get formattedLanguages {
    if (selectedLanguages.isEmpty) {
      return 'Nenhum idioma selecionado';
    }
    if (selectedLanguages.length == 1) {
      return selectedLanguages.first;
    }
    if (selectedLanguages.length <= 3) {
      return selectedLanguages.join(', ');
    }
    return '${selectedLanguages.take(3).join(', ')} +${selectedLanguages.length - 3}';
  }

  /// Formata educação para exibição
  String get formattedEducation {
    return selectedEducation ?? 'Não tenho preferência';
  }

  /// Verifica se é igual a outro filtro
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SearchFilters) return false;
    
    // Comparar listas de idiomas
    if (selectedLanguages.length != other.selectedLanguages.length) return false;
    for (int i = 0; i < selectedLanguages.length; i++) {
      if (selectedLanguages[i] != other.selectedLanguages[i]) return false;
    }
    
    return other.maxDistance == maxDistance &&
        other.prioritizeDistance == prioritizeDistance &&
        other.minAge == minAge &&
        other.maxAge == maxAge &&
        other.prioritizeAge == prioritizeAge &&
        other.minHeight == minHeight &&
        other.maxHeight == maxHeight &&
        other.prioritizeHeight == prioritizeHeight &&
        other.prioritizeLanguages == prioritizeLanguages &&
        other.selectedEducation == selectedEducation &&
        other.prioritizeEducation == prioritizeEducation &&
        other.selectedChildren == selectedChildren &&
        other.prioritizeChildren == prioritizeChildren &&
        other.selectedDrinking == selectedDrinking &&
        other.prioritizeDrinking == prioritizeDrinking &&
        other.selectedSmoking == selectedSmoking &&
        other.prioritizeSmoking == prioritizeSmoking;
  }

  @override
  int get hashCode => 
      maxDistance.hashCode ^ 
      prioritizeDistance.hashCode ^ 
      minAge.hashCode ^ 
      maxAge.hashCode ^ 
      prioritizeAge.hashCode ^
      minHeight.hashCode ^
      maxHeight.hashCode ^
      prioritizeHeight.hashCode ^
      selectedLanguages.hashCode ^
      prioritizeLanguages.hashCode ^
      selectedEducation.hashCode ^
      prioritizeEducation.hashCode ^
      selectedChildren.hashCode ^
      prioritizeChildren.hashCode ^
      selectedDrinking.hashCode ^
      prioritizeDrinking.hashCode ^
      selectedSmoking.hashCode ^
      prioritizeSmoking.hashCode;

  @override
  String toString() {
    return 'SearchFilters(maxDistance: $maxDistance, prioritizeDistance: $prioritizeDistance, minAge: $minAge, maxAge: $maxAge, prioritizeAge: $prioritizeAge, minHeight: $minHeight, maxHeight: $maxHeight, prioritizeHeight: $prioritizeHeight, selectedLanguages: $selectedLanguages, prioritizeLanguages: $prioritizeLanguages, selectedEducation: $selectedEducation, prioritizeEducation: $prioritizeEducation)';
  }

  /// Converte altura de String (ex: "1.75m") para int em cm (ex: 175)
  static int? convertHeightStringToInt(String? heightStr) {
    if (heightStr == null || heightStr.isEmpty) return null;
    if (heightStr.toLowerCase().contains('prefiro não')) return null;
    
    // Remove "m" e espaços
    final cleanStr = heightStr.replaceAll('m', '').replaceAll(' ', '').trim();
    
    // Tenta converter para double (metros)
    final heightInMeters = double.tryParse(cleanStr);
    if (heightInMeters == null) return null;
    
    // Converte para cm
    return (heightInMeters * 100).round();
  }

  /// Converte altura de int em cm (ex: 175) para String (ex: "1.75m")
  static String convertHeightIntToString(int heightCm) {
    final heightM = heightCm / 100;
    return '${heightM.toStringAsFixed(2)}m';
  }

  /// Mapeia bool de filhos para String do filtro
  static String mapChildrenBoolToString(bool? hasChildren) {
    if (hasChildren == null) return 'Não tenho preferência';
    return hasChildren ? 'Tem filhos' : 'Não tem filhos';
  }

  /// Mapeia String do filtro para bool de filhos
  static bool? mapChildrenStringToBool(String? childrenStr) {
    if (childrenStr == null || childrenStr == 'Não tenho preferência') {
      return null;
    }
    return childrenStr == 'Tem filhos';
  }
}
