import '../interfaces/location_data_interface.dart';

/// Dados de localização do México
class MexicoLocationData implements LocationDataInterface {
  @override
  String get countryName => 'México';

  @override
  String get countryCode => 'MX';

  @override
  String get stateLabel => 'Estado';

  @override
  bool get useStateAbbreviation => false;

  // Estados do México
  static const Map<String, List<String>> _statesAndCities = {
    'Aguascalientes': [
      'Aguascalientes',
      'Jesús María',
      'Calvillo',
      'Rincón de Romos',
      'Pabellón de Arteaga'
    ],
    'Baja California': [
      'Tijuana',
      'Mexicali',
      'Ensenada',
      'Rosarito',
      'Tecate'
    ],
    'Baja California Sur': [
      'La Paz',
      'Cabo San Lucas',
      'San José del Cabo',
      'Ciudad Constitución',
      'Loreto'
    ],
    'Campeche': [
      'Campeche',
      'Ciudad del Carmen',
      'Champotón',
      'Escárcega',
      'Calkiní'
    ],
    'Chiapas': [
      'Tuxtla Gutiérrez',
      'Tapachula',
      'San Cristóbal de las Casas',
      'Comitán',
      'Palenque'
    ],
    'Chihuahua': [
      'Chihuahua',
      'Ciudad Juárez',
      'Cuauhtémoc',
      'Delicias',
      'Parral'
    ],
    'Coahuila': ['Saltillo', 'Torreón', 'Monclova', 'Piedras Negras', 'Acuña'],
    'Colima': [
      'Colima',
      'Manzanillo',
      'Tecomán',
      'Villa de Álvarez',
      'Armería'
    ],
    'Durango': [
      'Durango',
      'Gómez Palacio',
      'Lerdo',
      'Santiago Papasquiaro',
      'Guadalupe Victoria'
    ],
    'Guanajuato': [
      'León',
      'Irapuato',
      'Celaya',
      'Salamanca',
      'Guanajuato',
      'San Miguel de Allende'
    ],
    'Guerrero': ['Acapulco', 'Chilpancingo', 'Iguala', 'Zihuatanejo', 'Taxco'],
    'Hidalgo': ['Pachuca', 'Tulancingo', 'Tula', 'Tepeji del Río', 'Tizayuca'],
    'Jalisco': [
      'Guadalajara',
      'Zapopan',
      'Tlaquepaque',
      'Tonalá',
      'Puerto Vallarta',
      'Lagos de Moreno'
    ],
    'México': [
      'Toluca',
      'Ecatepec',
      'Nezahualcóyotl',
      'Naucalpan',
      'Tlalnepantla',
      'Texcoco'
    ],
    'Michoacán': [
      'Morelia',
      'Uruapan',
      'Zamora',
      'Lázaro Cárdenas',
      'Pátzcuaro'
    ],
    'Morelos': ['Cuernavaca', 'Jiutepec', 'Cuautla', 'Temixco', 'Yautepec'],
    'Nayarit': [
      'Tepic',
      'Bahía de Banderas',
      'Santiago Ixcuintla',
      'Compostela',
      'Tuxpan'
    ],
    'Nuevo León': [
      'Monterrey',
      'Guadalupe',
      'San Nicolás de los Garza',
      'Apodaca',
      'San Pedro Garza García'
    ],
    'Oaxaca': [
      'Oaxaca de Juárez',
      'Salina Cruz',
      'Juchitán',
      'Tuxtepec',
      'Puerto Escondido'
    ],
    'Puebla': [
      'Puebla',
      'Tehuacán',
      'San Martín Texmelucan',
      'Atlixco',
      'Cholula'
    ],
    'Querétaro': [
      'Querétaro',
      'San Juan del Río',
      'Corregidora',
      'El Marqués',
      'Tequisquiapan'
    ],
    'Quintana Roo': [
      'Cancún',
      'Playa del Carmen',
      'Chetumal',
      'Cozumel',
      'Tulum'
    ],
    'San Luis Potosí': [
      'San Luis Potosí',
      'Soledad de Graciano Sánchez',
      'Ciudad Valles',
      'Matehuala',
      'Rioverde'
    ],
    'Sinaloa': ['Culiacán', 'Mazatlán', 'Los Mochis', 'Guasave', 'Guamúchil'],
    'Sonora': [
      'Hermosillo',
      'Ciudad Obregón',
      'Nogales',
      'San Luis Río Colorado',
      'Navojoa'
    ],
    'Tabasco': [
      'Villahermosa',
      'Cárdenas',
      'Comalcalco',
      'Huimanguillo',
      'Macuspana'
    ],
    'Tamaulipas': [
      'Ciudad Victoria',
      'Reynosa',
      'Matamoros',
      'Nuevo Laredo',
      'Tampico'
    ],
    'Tlaxcala': [
      'Tlaxcala',
      'Apizaco',
      'Huamantla',
      'San Pablo del Monte',
      'Chiautempan'
    ],
    'Veracruz': [
      'Veracruz',
      'Xalapa',
      'Coatzacoalcos',
      'Córdoba',
      'Poza Rica',
      'Orizaba'
    ],
    'Yucatán': ['Mérida', 'Valladolid', 'Tizimín', 'Progreso', 'Ticul'],
    'Zacatecas': ['Zacatecas', 'Fresnillo', 'Guadalupe', 'Jerez', 'Río Grande'],
    'Ciudad de México': ['Ciudad de México'],
  };

  @override
  List<String> getStates() {
    return _statesAndCities.keys.toList()..sort();
  }

  @override
  List<String> getCitiesForState(String state) {
    return _statesAndCities[state] ?? [];
  }

  @override
  String formatLocation(String city, String state) {
    return '$city, $state';
  }

  @override
  String? getStateAbbreviation(String state) {
    return null; // México não usa siglas comumente
  }
}
