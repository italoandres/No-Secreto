import '../interfaces/location_data_interface.dart';

/// Dados de localização do Reino Unido
class UKLocationData implements LocationDataInterface {
  @override
  String get countryName => 'Reino Unido';

  @override
  String get countryCode => 'GB';

  @override
  String get stateLabel => 'Região';

  @override
  bool get useStateAbbreviation => false;

  static const Map<String, List<String>> _regionsAndCities = {
    'Inglaterra - Londres': [
      'Londres',
      'Westminster',
      'Camden',
      'Greenwich',
      'Croydon'
    ],
    'Inglaterra - Sudeste': [
      'Brighton',
      'Oxford',
      'Reading',
      'Southampton',
      'Portsmouth',
      'Canterbury'
    ],
    'Inglaterra - Sudoeste': [
      'Bristol',
      'Plymouth',
      'Exeter',
      'Bournemouth',
      'Swindon'
    ],
    'Inglaterra - Leste': [
      'Cambridge',
      'Norwich',
      'Ipswich',
      'Colchester',
      'Peterborough'
    ],
    'Inglaterra - Midlands Orientais': [
      'Leicester',
      'Nottingham',
      'Derby',
      'Lincoln',
      'Northampton'
    ],
    'Inglaterra - Midlands Ocidentais': [
      'Birmingham',
      'Coventry',
      'Wolverhampton',
      'Stoke-on-Trent',
      'Worcester'
    ],
    'Inglaterra - Yorkshire': [
      'Leeds',
      'Sheffield',
      'Bradford',
      'York',
      'Hull'
    ],
    'Inglaterra - Noroeste': [
      'Manchester',
      'Liverpool',
      'Preston',
      'Lancaster',
      'Chester'
    ],
    'Inglaterra - Nordeste': [
      'Newcastle',
      'Sunderland',
      'Durham',
      'Middlesbrough'
    ],
    'Escócia': [
      'Edimburgo',
      'Glasgow',
      'Aberdeen',
      'Dundee',
      'Inverness',
      'Stirling'
    ],
    'País de Gales': ['Cardiff', 'Swansea', 'Newport', 'Wrexham', 'Bangor'],
    'Irlanda do Norte': ['Belfast', 'Derry', 'Lisburn', 'Newry', 'Armagh'],
  };

  @override
  List<String> getStates() => _regionsAndCities.keys.toList()..sort();

  @override
  List<String> getCitiesForState(String state) =>
      _regionsAndCities[state] ?? [];

  @override
  String formatLocation(String city, String state) => '$city, $state';

  @override
  String? getStateAbbreviation(String state) => null;
}
