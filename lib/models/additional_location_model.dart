import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para localizações adicionais de interesse do usuário
class AdditionalLocation {
  final String city;
  final String state;
  final DateTime addedAt;
  final DateTime? lastEditedAt;

  AdditionalLocation({
    required this.city,
    required this.state,
    required this.addedAt,
    this.lastEditedAt,
  });

  /// Verifica se a localização pode ser editada (30 dias desde última edição)
  bool get canEdit {
    if (lastEditedAt == null) return true;
    final daysSinceEdit = DateTime.now().difference(lastEditedAt!).inDays;
    return daysSinceEdit >= 30;
  }

  /// Retorna quantos dias faltam para poder editar
  int get daysUntilCanEdit {
    if (canEdit) return 0;
    final daysSinceEdit = DateTime.now().difference(lastEditedAt!).inDays;
    return 30 - daysSinceEdit;
  }

  /// Retorna texto formatado para exibição
  String get displayText => '$city - $state';

  /// Retorna mensagem de status de edição
  String get editStatusMessage {
    if (canEdit) return 'Editável agora';
    return 'Editável em $daysUntilCanEdit ${daysUntilCanEdit == 1 ? 'dia' : 'dias'}';
  }

  /// Cria cópia com campos atualizados
  AdditionalLocation copyWith({
    String? city,
    String? state,
    DateTime? addedAt,
    DateTime? lastEditedAt,
  }) {
    return AdditionalLocation(
      city: city ?? this.city,
      state: state ?? this.state,
      addedAt: addedAt ?? this.addedAt,
      lastEditedAt: lastEditedAt ?? this.lastEditedAt,
    );
  }

  /// Converte para JSON para salvar no Firestore
  Map<String, dynamic> toJson() => {
        'city': city,
        'state': state,
        'addedAt': Timestamp.fromDate(addedAt),
        'lastEditedAt':
            lastEditedAt != null ? Timestamp.fromDate(lastEditedAt!) : null,
      };

  /// Cria instância a partir de JSON do Firestore
  factory AdditionalLocation.fromJson(Map<String, dynamic> json) {
    return AdditionalLocation(
      city: json['city'] as String,
      state: json['state'] as String,
      addedAt: (json['addedAt'] as Timestamp).toDate(),
      lastEditedAt: json['lastEditedAt'] != null
          ? (json['lastEditedAt'] as Timestamp).toDate()
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdditionalLocation &&
        other.city == city &&
        other.state == state;
  }

  @override
  int get hashCode => city.hashCode ^ state.hashCode;

  @override
  String toString() =>
      'AdditionalLocation(city: $city, state: $state, canEdit: $canEdit)';
}
