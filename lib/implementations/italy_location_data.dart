import '../interfaces/location_data_interface.dart';

/// Dados de localização da Itália
class ItalyLocationData implements LocationDataInterface {
  @override
  String get countryName => 'Itália';
  
  @override
  String get countryCode => 'IT';
  
  @override
  String get stateLabel => 'Região';
  
  @override
  bool get useStateAbbreviation => false;
  
  static const Map<String, List<String>> _regionsAndCities = {
    'Lácio': ['Roma', 'Latina', 'Frosinone', 'Viterbo', 'Rieti'],
    'Lombardia': ['Milão', 'Bréscia', 'Monza', 'Bérgamo', 'Como', 'Varese'],
    'Campânia': ['Nápoles', 'Salerno', 'Caserta', 'Benevento', 'Avellino'],
    'Sicília': ['Palermo', 'Catânia', 'Messina', 'Siracusa', 'Trapani'],
    'Vêneto': ['Veneza', 'Verona', 'Pádua', 'Vicenza', 'Treviso'],
    'Emília-Romanha': ['Bolonha', 'Parma', 'Módena', 'Reggio Emilia', 'Ravena'],
    'Piemonte': ['Turim', 'Novara', 'Alessandria', 'Asti', 'Cuneo'],
    'Apúlia': ['Bari', 'Taranto', 'Foggia', 'Lecce', 'Brindisi'],
    'Toscana': ['Florença', 'Pisa', 'Livorno', 'Arezzo', 'Siena', 'Lucca'],
    'Calábria': ['Reggio Calábria', 'Catanzaro', 'Cosenza', 'Crotone', 'Vibo Valentia'],
    'Sardenha': ['Cagliari', 'Sassari', 'Olbia', 'Nuoro', 'Oristano'],
    'Ligúria': ['Gênova', 'La Spezia', 'Savona', 'Imperia'],
    'Marcas': ['Ancona', 'Pesaro', 'Macerata', 'Ascoli Piceno', 'Fermo'],
    'Abruzos': ['L\'Aquila', 'Pescara', 'Teramo', 'Chieti'],
    'Friuli-Veneza Júlia': ['Trieste', 'Udine', 'Pordenone', 'Gorizia'],
    'Trentino-Alto Ádige': ['Trento', 'Bolzano', 'Rovereto', 'Merano'],
    'Úmbria': ['Perugia', 'Terni', 'Foligno', 'Spoleto'],
    'Basilicata': ['Potenza', 'Matera'],
    'Molise': ['Campobasso', 'Isernia'],
    'Vale de Aosta': ['Aosta'],
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
