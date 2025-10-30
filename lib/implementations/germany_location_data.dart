import '../interfaces/location_data_interface.dart';

/// Dados de localização da Alemanha
class GermanyLocationData implements LocationDataInterface {
  @override
  String get countryName => 'Alemanha';

  @override
  String get countryCode => 'DE';

  @override
  String get stateLabel => 'Estado';

  @override
  bool get useStateAbbreviation => false;

  static const Map<String, List<String>> _statesAndCities = {
    'Baden-Württemberg': [
      'Stuttgart',
      'Mannheim',
      'Karlsruhe',
      'Freiburg',
      'Heidelberg',
      'Ulm'
    ],
    'Baviera': [
      'Munique',
      'Nuremberg',
      'Augsburgo',
      'Regensburgo',
      'Ingolstadt',
      'Würzburg'
    ],
    'Berlim': ['Berlim'],
    'Brandemburgo': ['Potsdam', 'Cottbus', 'Brandenburg', 'Frankfurt (Oder)'],
    'Bremen': ['Bremen', 'Bremerhaven'],
    'Hamburgo': ['Hamburgo'],
    'Hesse': ['Frankfurt', 'Wiesbaden', 'Kassel', 'Darmstadt', 'Offenbach'],
    'Mecklemburgo-Pomerânia Ocidental': [
      'Rostock',
      'Schwerin',
      'Neubrandenburg',
      'Stralsund'
    ],
    'Baixa Saxônia': [
      'Hanôver',
      'Braunschweig',
      'Osnabrück',
      'Oldenburg',
      'Göttingen'
    ],
    'Renânia do Norte-Vestfália': [
      'Colônia',
      'Düsseldorf',
      'Dortmund',
      'Essen',
      'Duisburgo',
      'Bochum',
      'Bonn'
    ],
    'Renânia-Palatinado': [
      'Mainz',
      'Ludwigshafen',
      'Koblenz',
      'Trier',
      'Kaiserslautern'
    ],
    'Sarre': ['Saarbrücken', 'Neunkirchen', 'Homburg'],
    'Saxônia': ['Dresden', 'Leipzig', 'Chemnitz', 'Zwickau'],
    'Saxônia-Anhalt': ['Magdeburgo', 'Halle', 'Dessau'],
    'Schleswig-Holstein': ['Kiel', 'Lübeck', 'Flensburg', 'Neumünster'],
    'Turíngia': ['Erfurt', 'Jena', 'Gera', 'Weimar', 'Eisenach'],
  };

  @override
  List<String> getStates() => _statesAndCities.keys.toList()..sort();

  @override
  List<String> getCitiesForState(String state) => _statesAndCities[state] ?? [];

  @override
  String formatLocation(String city, String state) => '$city, $state';

  @override
  String? getStateAbbreviation(String state) => null;
}
