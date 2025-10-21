import '../interfaces/location_data_interface.dart';

/// Dados de localização da Espanha
class SpainLocationData implements LocationDataInterface {
  @override
  String get countryName => 'Espanha';
  
  @override
  String get countryCode => 'ES';
  
  @override
  String get stateLabel => 'Comunidade Autônoma';
  
  @override
  bool get useStateAbbreviation => false;
  
  static const Map<String, List<String>> _regionsAndCities = {
    'Andaluzia': ['Sevilha', 'Málaga', 'Córdoba', 'Granada', 'Cádiz', 'Almería', 'Huelva', 'Jaén'],
    'Aragão': ['Saragoça', 'Huesca', 'Teruel'],
    'Astúrias': ['Oviedo', 'Gijón', 'Avilés'],
    'Ilhas Baleares': ['Palma de Maiorca', 'Ibiza', 'Mahón'],
    'País Basco': ['Bilbau', 'Vitória', 'San Sebastián'],
    'Ilhas Canárias': ['Las Palmas', 'Santa Cruz de Tenerife', 'La Laguna'],
    'Cantábria': ['Santander', 'Torrelavega'],
    'Castela e Leão': ['Valladolid', 'Burgos', 'Salamanca', 'León', 'Zamora', 'Palência', 'Ávila', 'Segóvia', 'Sória'],
    'Castela-La Mancha': ['Toledo', 'Albacete', 'Ciudad Real', 'Cuenca', 'Guadalajara'],
    'Catalunha': ['Barcelona', 'Tarragona', 'Lérida', 'Gerona'],
    'Comunidade Valenciana': ['Valência', 'Alicante', 'Castellón'],
    'Extremadura': ['Badajoz', 'Cáceres', 'Mérida'],
    'Galiza': ['Vigo', 'A Coruña', 'Ourense', 'Lugo', 'Santiago de Compostela'],
    'Madrid': ['Madrid', 'Móstoles', 'Alcalá de Henares', 'Fuenlabrada', 'Leganés'],
    'Múrcia': ['Múrcia', 'Cartagena', 'Lorca'],
    'Navarra': ['Pamplona', 'Tudela'],
    'La Rioja': ['Logroño', 'Calahorra'],
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
