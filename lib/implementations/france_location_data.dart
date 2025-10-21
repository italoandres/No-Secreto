import '../interfaces/location_data_interface.dart';

/// Dados de localização da França
class FranceLocationData implements LocationDataInterface {
  @override
  String get countryName => 'França';
  
  @override
  String get countryCode => 'FR';
  
  @override
  String get stateLabel => 'Região';
  
  @override
  bool get useStateAbbreviation => false;
  
  static const Map<String, List<String>> _regionsAndCities = {
    'Île-de-France': ['Paris', 'Versalhes', 'Boulogne-Billancourt', 'Saint-Denis', 'Argenteuil'],
    'Auvergne-Rhône-Alpes': ['Lyon', 'Grenoble', 'Saint-Étienne', 'Annecy', 'Chambéry'],
    'Nouvelle-Aquitaine': ['Bordeaux', 'Limoges', 'Poitiers', 'La Rochelle', 'Pau'],
    'Occitanie': ['Toulouse', 'Montpellier', 'Nîmes', 'Perpignan', 'Béziers'],
    'Hauts-de-France': ['Lille', 'Amiens', 'Roubaix', 'Tourcoing', 'Dunkerque'],
    'Provence-Alpes-Côte d\'Azur': ['Marselha', 'Nice', 'Toulon', 'Aix-en-Provence', 'Cannes'],
    'Grand Est': ['Estrasburgo', 'Reims', 'Metz', 'Mulhouse', 'Nancy'],
    'Pays de la Loire': ['Nantes', 'Angers', 'Le Mans', 'Saint-Nazaire', 'Cholet'],
    'Bretanha': ['Rennes', 'Brest', 'Quimper', 'Lorient', 'Vannes'],
    'Normandia': ['Rouen', 'Le Havre', 'Caen', 'Cherbourg', 'Évreux'],
    'Bourgogne-Franche-Comté': ['Dijon', 'Besançon', 'Belfort', 'Chalon-sur-Saône', 'Nevers'],
    'Centre-Val de Loire': ['Tours', 'Orléans', 'Bourges', 'Blois', 'Châteauroux'],
    'Córsega': ['Ajaccio', 'Bastia', 'Porto-Vecchio'],
  };
  
  @override
  List<String> getStates() => _regionsAndCities.keys.toList()..sort();
  
  @override
  List<String> getCitiesForState(String state) => _regionsAndCities[state] ?? [];
  
  @override
  String formatLocation(String city, String state) => '$city, $state';
  
  @override
  String? getStateAbbreviation(String state) => null;
}
