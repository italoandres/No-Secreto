/// Interface base para provedores de dados de localização
/// 
/// Todos os países com dados estruturados devem implementar esta interface
abstract class LocationDataInterface {
  /// Nome do país
  String get countryName;
  
  /// Código do país (ISO 3166-1 alpha-2)
  String get countryCode;
  
  /// Label para o campo de estado/província/região
  /// Ex: "Estado", "Província", "Distrito", "Região"
  String get stateLabel;
  
  /// Indica se o país usa siglas para estados
  bool get useStateAbbreviation;
  
  /// Retorna lista de estados/províncias/regiões
  List<String> getStates();
  
  /// Retorna lista de cidades para um estado/província
  List<String> getCitiesForState(String state);
  
  /// Retorna formato de localização
  /// Ex: "São Paulo - SP" ou "Paris, Île-de-France"
  String formatLocation(String city, String state);
  
  /// Retorna sigla do estado (se aplicável)
  String? getStateAbbreviation(String state);
}
