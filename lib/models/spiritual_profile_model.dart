import 'package:cloud_firestore/cloud_firestore.dart';
import 'additional_location_model.dart';

class SpiritualProfileModel {
  String? id;
  String? userId;

  // Profile Completion Status
  bool isProfileComplete;
  Map<String, bool> completionTasks;
  DateTime? profileCompletedAt;
  bool? hasBeenShown; // Se a tela de parabéns já foi mostrada

  // Additional Locations for Match (max 2)
  List<AdditionalLocation>? additionalLocations;

  // Search Filters
  Map<String, dynamic>? searchFilters;

  // Photos (up to 3)
  String? mainPhotoUrl; // Required
  String? secondaryPhoto1Url; // Optional
  String? secondaryPhoto2Url; // Optional

  // Spiritual Identity
  String? city; // "São Paulo - SP"
  String? state; // "SP", "RJ", etc.
  String? fullLocation; // "São Paulo - SP"
  String? country; // "Brasil"
  List<String>? languages; // Idiomas falados
  int? age;
  String? height; // Altura (ex: "1.75m" ou "Prefiro não dizer")
  String? occupation; // Profissão/Emprego atual
  String? education; // Nível educacional
  String? universityCourse; // Curso superior
  String? courseStatus; // Status do curso: "Se formando" ou "Formado(a)"
  String? university; // Instituição de ensino
  String? smokingStatus; // Status de fumante
  String? drinkingStatus; // Status de consumo de álcool
  List<String>? hobbies; // Hobbies e interesses

  // Biography Questions
  String? purpose; // "Qual é o seu propósito?" (300 chars)
  bool? isDeusEPaiMember; // "Você faz parte do movimento Deus é Pai?"
  RelationshipStatus? relationshipStatus; // Solteiro/Comprometido
  bool?
      readyForPurposefulRelationship; // "Disposto a viver relacionamento com propósito?"
  String? nonNegotiableValue; // "Qual valor é inegociável?"
  String? faithPhrase; // "Uma frase que representa sua fé"
  String? aboutMe; // "Algo que gostaria que soubessem" (optional)

  // Spiritual Certification
  bool? hasSinaisPreparationSeal; // "Preparado(a) para os Sinais"
  DateTime? sealObtainedAt;

  // Family and Relationship History
  bool? hasChildren; // "Você tem filhos?"
  String? childrenDetails; // "2 filhos" ou "Sem filhos"
  bool? isVirgin; // "Você é virgem?" (optional/private)
  bool? wasPreviouslyMarried; // "Você já foi casado(a)?"

  // Interaction Settings
  bool allowInteractions; // Can receive "Tenho Interesse"
  List<String> blockedUsers;

  // Sync fields with usuario collection
  String? displayName; // Synced with usuario.nome
  String? username; // Synced with usuario.username
  DateTime? lastSyncAt; // Last sync with usuario collection

  // Additional fields for compatibility
  bool? isVerified;
  bool? hasCompletedCourse;
  String? bio;
  List<String>? interests;

  // Search and profile type fields
  String? profileType; // 'spiritual' or 'vitrine'
  List<String>? searchKeywords;
  String? photoUrl; // Alias for mainPhotoUrl
  bool? isActive;

  DateTime? createdAt;
  DateTime? updatedAt;

  SpiritualProfileModel({
    this.id,
    this.userId,
    this.isProfileComplete = false,
    this.completionTasks = const {
      'photos': false,
      'identity': false,
      'biography': false,
      'preferences': false,
      'certification': false,
    },
    this.profileCompletedAt,
    this.hasBeenShown,
    this.additionalLocations,
    this.searchFilters,
    this.mainPhotoUrl,
    this.secondaryPhoto1Url,
    this.secondaryPhoto2Url,
    this.city,
    this.state,
    this.fullLocation,
    this.country,
    this.languages,
    this.age,
    this.height,
    this.occupation,
    this.education,
    this.universityCourse,
    this.courseStatus,
    this.university,
    this.smokingStatus,
    this.drinkingStatus,
    this.hobbies,
    this.purpose,
    this.isDeusEPaiMember,
    this.relationshipStatus,
    this.readyForPurposefulRelationship,
    this.nonNegotiableValue,
    this.faithPhrase,
    this.aboutMe,
    this.hasSinaisPreparationSeal,
    this.sealObtainedAt,
    this.hasChildren,
    this.childrenDetails,
    this.isVirgin,
    this.wasPreviouslyMarried,
    this.allowInteractions = true,
    this.blockedUsers = const [],
    this.displayName,
    this.username,
    this.lastSyncAt,
    this.isVerified,
    this.hasCompletedCourse,
    this.bio,
    this.interests,
    this.profileType,
    this.searchKeywords,
    this.photoUrl,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  static SpiritualProfileModel fromMap(Map<String, dynamic> json) {
    return fromJson(json);
  }

  static SpiritualProfileModel fromJson(Map<String, dynamic> json) {
    return SpiritualProfileModel(
      id: json['id'],
      userId: json['userId'],
      isProfileComplete:
          json['isProfileComplete'] is bool ? json['isProfileComplete'] : false,
      completionTasks: json['completionTasks'] != null
          ? Map<String, bool>.from(json['completionTasks'])
          : {
              'photos': false,
              'identity': false,
              'biography': false,
              'preferences': false,
              'certification': false,
            },
      profileCompletedAt: json['profileCompletedAt']?.toDate(),
      hasBeenShown: json['hasBeenShown'] is bool ? json['hasBeenShown'] : false,
      additionalLocations: json['additionalLocations'] != null
          ? (json['additionalLocations'] as List)
              .map((loc) =>
                  AdditionalLocation.fromJson(loc as Map<String, dynamic>))
              .toList()
          : null,
      searchFilters: json['searchFilters'] != null
          ? Map<String, dynamic>.from(json['searchFilters'])
          : null,
      mainPhotoUrl: json['mainPhotoUrl'],
      secondaryPhoto1Url: json['secondaryPhoto1Url'],
      secondaryPhoto2Url: json['secondaryPhoto2Url'],
      city: json['city'],
      state: json['state'],
      fullLocation: json['fullLocation'],
      country: json['country'],
      languages: json['languages'] != null
          ? List<String>.from(json['languages'])
          : null,
      age: json['age'],
      height: json['height'],
      occupation: json['occupation'],
      education: json['education'],
      universityCourse: json['universityCourse'],
      courseStatus: json['courseStatus'],
      university: json['university'],
      smokingStatus: json['smokingStatus'],
      drinkingStatus: json['drinkingStatus'],
      hobbies:
          json['hobbies'] != null ? List<String>.from(json['hobbies']) : null,
      purpose: json['purpose'],
      isDeusEPaiMember: json['isDeusEPaiMember'] is bool
          ? json['isDeusEPaiMember']
          : (json['isDeusEPaiMember'] != null ? true : null),
      relationshipStatus: json['relationshipStatus'] != null
          ? RelationshipStatus.values.byName(json['relationshipStatus'])
          : null,
      readyForPurposefulRelationship:
          json['readyForPurposefulRelationship'] is bool
              ? json['readyForPurposefulRelationship']
              : (json['readyForPurposefulRelationship'] != null ? true : null),
      nonNegotiableValue: json['nonNegotiableValue'],
      faithPhrase: json['faithPhrase'],
      aboutMe: json['aboutMe'],
      hasSinaisPreparationSeal: json['hasSinaisPreparationSeal'] is bool
          ? json['hasSinaisPreparationSeal']
          : (json['hasSinaisPreparationSeal'] != null ? true : false),
      sealObtainedAt: json['sealObtainedAt']?.toDate(),
      hasChildren: json['hasChildren'] is bool
          ? json['hasChildren']
          : (json['hasChildren'] != null ? true : null),
      childrenDetails: json['childrenDetails'],
      isVirgin: json['isVirgin'] is bool
          ? json['isVirgin']
          : (json['isVirgin'] != null ? true : null),
      wasPreviouslyMarried: json['wasPreviouslyMarried'] is bool
          ? json['wasPreviouslyMarried']
          : (json['wasPreviouslyMarried'] != null ? true : null),
      allowInteractions:
          json['allowInteractions'] is bool ? json['allowInteractions'] : true,
      blockedUsers: json['blockedUsers'] != null
          ? List<String>.from(json['blockedUsers'])
          : [],
      displayName: json['displayName'],
      username: json['username'],
      lastSyncAt: json['lastSyncAt'] != null
          ? (json['lastSyncAt'] as Timestamp).toDate()
          : null,
      isVerified: json['isVerified'] as bool?,
      hasCompletedCourse: json['hasCompletedCourse'] as bool?,
      bio: json['bio'] as String?,
      interests: json['interests'] != null
          ? List<String>.from(json['interests'])
          : null,
      profileType: json['profileType'] as String?,
      searchKeywords: json['searchKeywords'] != null
          ? List<String>.from(json['searchKeywords'])
          : null,
      photoUrl: json['photoUrl'] as String?,
      isActive: json['isActive'] as bool?,
      createdAt: json['createdAt']?.toDate(),
      updatedAt: json['updatedAt']?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'isProfileComplete': isProfileComplete,
      'completionTasks': completionTasks,
      'profileCompletedAt': profileCompletedAt != null
          ? Timestamp.fromDate(profileCompletedAt!)
          : null,
      'hasBeenShown': hasBeenShown ?? false,
      'additionalLocations':
          additionalLocations?.map((loc) => loc.toJson()).toList(),
      'searchFilters': searchFilters,
      'mainPhotoUrl': mainPhotoUrl,
      'secondaryPhoto1Url': secondaryPhoto1Url,
      'secondaryPhoto2Url': secondaryPhoto2Url,
      'city': city,
      'state': state,
      'fullLocation': fullLocation,
      'country': country,
      'languages': languages,
      'age': age,
      'height': height,
      'occupation': occupation,
      'education': education,
      'universityCourse': universityCourse,
      'courseStatus': courseStatus,
      'university': university,
      'smokingStatus': smokingStatus,
      'drinkingStatus': drinkingStatus,
      'hobbies': hobbies,
      'purpose': purpose,
      'isDeusEPaiMember': isDeusEPaiMember,
      'relationshipStatus': relationshipStatus?.name,
      'readyForPurposefulRelationship': readyForPurposefulRelationship,
      'nonNegotiableValue': nonNegotiableValue,
      'faithPhrase': faithPhrase,
      'aboutMe': aboutMe,
      'hasSinaisPreparationSeal': hasSinaisPreparationSeal,
      'sealObtainedAt':
          sealObtainedAt != null ? Timestamp.fromDate(sealObtainedAt!) : null,
      'hasChildren': hasChildren,
      'childrenDetails': childrenDetails,
      'isVirgin': isVirgin,
      'wasPreviouslyMarried': wasPreviouslyMarried,
      'allowInteractions': allowInteractions,
      'blockedUsers': blockedUsers,
      'displayName': displayName,
      'username': username,
      'lastSyncAt': lastSyncAt != null ? Timestamp.fromDate(lastSyncAt!) : null,
      'isVerified': isVerified,
      'hasCompletedCourse': hasCompletedCourse,
      'bio': bio,
      'interests': interests,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Helper methods
  double get completionPercentage {
    if (completionTasks.isEmpty) return 0.0;

    // Certificação é OPCIONAL - não conta no progresso
    final requiredTasks = Map<String, bool>.from(completionTasks);
    requiredTasks.remove('certification'); // Remove certificação do cálculo

    if (requiredTasks.isEmpty) return 0.0;

    int completedTasks =
        requiredTasks.values.where((completed) => completed).length;
    return completedTasks / requiredTasks.length;
  }

  bool get hasRequiredPhotos => mainPhotoUrl?.isNotEmpty == true;

  bool get hasBasicInfo =>
      city?.isNotEmpty == true &&
      age != null &&
      hasChildren != null &&
      wasPreviouslyMarried != null;

  bool get hasBiography =>
      purpose?.isNotEmpty == true &&
      isDeusEPaiMember != null &&
      relationshipStatus != null &&
      readyForPurposefulRelationship != null &&
      nonNegotiableValue?.isNotEmpty == true &&
      faithPhrase?.isNotEmpty == true;

  List<String> get missingRequiredFields {
    List<String> missing = [];

    if (!hasRequiredPhotos) missing.add('Foto principal');
    if (city?.isEmpty == true) missing.add('Cidade');
    if (age == null) missing.add('Idade');
    if (hasChildren == null) missing.add('Tem filhos?');
    if (wasPreviouslyMarried == null) missing.add('Já foi casado(a)?');
    if (purpose?.isEmpty == true) missing.add('Propósito');
    if (isDeusEPaiMember == null) missing.add('Movimento Deus é Pai');
    if (relationshipStatus == null) missing.add('Status de relacionamento');
    if (readyForPurposefulRelationship == null)
      missing.add('Relacionamento com propósito');
    if (nonNegotiableValue?.isEmpty == true) missing.add('Valor inegociável');
    if (faithPhrase?.isEmpty == true) missing.add('Frase de fé');

    return missing;
  }

  bool get canShowPublicProfile =>
      isProfileComplete && missingRequiredFields.isEmpty;

  // New validation methods for enhanced fields
  bool get hasLocationInfo =>
      city?.isNotEmpty == true || fullLocation?.isNotEmpty == true;

  bool get hasFamilyInfo => hasChildren != null;

  String get displayLocation =>
      fullLocation ?? city ?? 'Localização não informada';

  String get childrenStatusText {
    if (hasChildren == null) return 'Não informado';
    if (hasChildren == true) {
      return childrenDetails ?? 'Tem filhos';
    }
    return 'Sem filhos';
  }

  String get marriageHistoryText {
    if (wasPreviouslyMarried == null) return 'Não informado';
    return wasPreviouslyMarried! ? 'Já foi casado(a)' : 'Nunca foi casado(a)';
  }

  // Privacy-aware getters
  String? get virginityStatusText {
    if (isVirgin == null) return null; // Private/not shared
    return isVirgin! ? 'Virgem' : 'Não virgem';
  }

  SpiritualProfileModel copyWith({
    String? id,
    String? userId,
    bool? isProfileComplete,
    Map<String, bool>? completionTasks,
    DateTime? profileCompletedAt,
    String? mainPhotoUrl,
    String? secondaryPhoto1Url,
    String? secondaryPhoto2Url,
    String? city,
    String? state,
    String? fullLocation,
    String? country,
    List<String>? languages,
    int? age,
    String? height,
    String? occupation,
    String? education,
    String? universityCourse,
    String? courseStatus,
    String? university,
    String? smokingStatus,
    String? drinkingStatus,
    List<String>? hobbies,
    String? purpose,
    bool? isDeusEPaiMember,
    RelationshipStatus? relationshipStatus,
    bool? readyForPurposefulRelationship,
    String? nonNegotiableValue,
    String? faithPhrase,
    String? aboutMe,
    bool? hasSinaisPreparationSeal,
    DateTime? sealObtainedAt,
    bool? hasChildren,
    String? childrenDetails,
    bool? isVirgin,
    bool? wasPreviouslyMarried,
    bool? allowInteractions,
    List<String>? blockedUsers,
    String? displayName,
    String? username,
    DateTime? lastSyncAt,
    bool? isVerified,
    bool? hasCompletedCourse,
    String? bio,
    List<String>? interests,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SpiritualProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      completionTasks: completionTasks ?? this.completionTasks,
      profileCompletedAt: profileCompletedAt ?? this.profileCompletedAt,
      mainPhotoUrl: mainPhotoUrl ?? this.mainPhotoUrl,
      secondaryPhoto1Url: secondaryPhoto1Url ?? this.secondaryPhoto1Url,
      secondaryPhoto2Url: secondaryPhoto2Url ?? this.secondaryPhoto2Url,
      city: city ?? this.city,
      state: state ?? this.state,
      fullLocation: fullLocation ?? this.fullLocation,
      country: country ?? this.country,
      languages: languages ?? this.languages,
      age: age ?? this.age,
      height: height ?? this.height,
      occupation: occupation ?? this.occupation,
      education: education ?? this.education,
      universityCourse: universityCourse ?? this.universityCourse,
      courseStatus: courseStatus ?? this.courseStatus,
      university: university ?? this.university,
      smokingStatus: smokingStatus ?? this.smokingStatus,
      drinkingStatus: drinkingStatus ?? this.drinkingStatus,
      hobbies: hobbies ?? this.hobbies,
      purpose: purpose ?? this.purpose,
      isDeusEPaiMember: isDeusEPaiMember ?? this.isDeusEPaiMember,
      relationshipStatus: relationshipStatus ?? this.relationshipStatus,
      readyForPurposefulRelationship:
          readyForPurposefulRelationship ?? this.readyForPurposefulRelationship,
      nonNegotiableValue: nonNegotiableValue ?? this.nonNegotiableValue,
      faithPhrase: faithPhrase ?? this.faithPhrase,
      aboutMe: aboutMe ?? this.aboutMe,
      hasSinaisPreparationSeal:
          hasSinaisPreparationSeal ?? this.hasSinaisPreparationSeal,
      sealObtainedAt: sealObtainedAt ?? this.sealObtainedAt,
      hasChildren: hasChildren ?? this.hasChildren,
      childrenDetails: childrenDetails ?? this.childrenDetails,
      isVirgin: isVirgin ?? this.isVirgin,
      wasPreviouslyMarried: wasPreviouslyMarried ?? this.wasPreviouslyMarried,
      allowInteractions: allowInteractions ?? this.allowInteractions,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      isVerified: isVerified ?? this.isVerified,
      hasCompletedCourse: hasCompletedCourse ?? this.hasCompletedCourse,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum RelationshipStatus {
  solteiro,
  solteira,
  comprometido,
  comprometida,
  naoInformado
}

// Interest and Matching Models
class InterestModel {
  String? id;
  String fromUserId;
  String toUserId;
  DateTime createdAt;
  bool isActive;

  InterestModel({
    this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.createdAt,
    this.isActive = true,
  });

  static InterestModel fromJson(Map<String, dynamic> json) {
    return InterestModel(
      id: json['id'],
      fromUserId: json['fromUserId'],
      toUserId: json['toUserId'],
      createdAt: json['createdAt'].toDate(),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }

  InterestModel copyWith({
    String? id,
    String? fromUserId,
    String? toUserId,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return InterestModel(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

class MutualInterestModel {
  String? id;
  String user1Id;
  String user2Id;
  DateTime matchedAt;
  bool chatEnabled;
  DateTime? chatExpiresAt; // 7 days from match
  bool movedToNossoProposito;

  MutualInterestModel({
    this.id,
    required this.user1Id,
    required this.user2Id,
    required this.matchedAt,
    this.chatEnabled = true,
    this.chatExpiresAt,
    this.movedToNossoProposito = false,
  });

  static MutualInterestModel fromJson(Map<String, dynamic> json) {
    return MutualInterestModel(
      id: json['id'],
      user1Id: json['user1Id'],
      user2Id: json['user2Id'],
      matchedAt: json['matchedAt'].toDate(),
      chatEnabled: json['chatEnabled'] ?? true,
      chatExpiresAt: json['chatExpiresAt']?.toDate(),
      movedToNossoProposito: json['movedToNossoProposito'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user1Id': user1Id,
      'user2Id': user2Id,
      'matchedAt': Timestamp.fromDate(matchedAt),
      'chatEnabled': chatEnabled,
      'chatExpiresAt':
          chatExpiresAt != null ? Timestamp.fromDate(chatExpiresAt!) : null,
      'movedToNossoProposito': movedToNossoProposito,
    };
  }

  bool get isChatExpired =>
      chatExpiresAt != null && DateTime.now().isAfter(chatExpiresAt!);

  Duration? get timeUntilExpiration =>
      chatExpiresAt?.difference(DateTime.now());
}
