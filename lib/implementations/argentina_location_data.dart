import '../interfaces/location_data_interface.dart';

/// Dados de localização da Argentina
class ArgentinaLocationData implements LocationDataInterface {
  @override
  String get countryName => 'Argentina';
  
  @override
  String get countryCode => 'AR';
  
  @override
  String get stateLabel => 'Província';
  
  @override
  bool get useStateAbbreviation => false;
  
  // Províncias da Argentina
  static const Map<String, List<String>> _provincesAndCities = {
    'Buenos Aires': ['Buenos Aires', 'La Plata', 'Mar del Plata', 'Bahía Blanca', 'Tandil', 'Quilmes', 'Avellaneda'],
    'Córdoba': ['Córdoba', 'Villa Carlos Paz', 'Río Cuarto', 'Villa María', 'San Francisco'],
    'Santa Fe': ['Rosario', 'Santa Fe', 'Rafaela', 'Venado Tuerto', 'Reconquista'],
    'Mendoza': ['Mendoza', 'San Rafael', 'Godoy Cruz', 'Luján de Cuyo', 'Maipú'],
    'Tucumán': ['San Miguel de Tucumán', 'Yerba Buena', 'Tafí Viejo', 'Concepción', 'Aguilares'],
    'Salta': ['Salta', 'San Ramón de la Nueva Orán', 'Tartagal', 'Metán', 'Cafayate'],
    'Entre Ríos': ['Paraná', 'Concordia', 'Gualeguaychú', 'Concepción del Uruguay', 'Victoria'],
    'Misiones': ['Posadas', 'Oberá', 'Eldorado', 'Puerto Iguazú', 'Apóstoles'],
    'Chaco': ['Resistencia', 'Presidencia Roque Sáenz Peña', 'Barranqueras', 'Villa Ángela', 'Charata'],
    'Corrientes': ['Corrientes', 'Goya', 'Paso de los Libres', 'Mercedes', 'Curuzú Cuatiá'],
    'Santiago del Estero': ['Santiago del Estero', 'La Banda', 'Termas de Río Hondo', 'Frías', 'Añatuya'],
    'San Juan': ['San Juan', 'Rawson', 'Chimbas', 'Rivadavia', 'Pocito'],
    'Jujuy': ['San Salvador de Jujuy', 'San Pedro', 'Libertador General San Martín', 'Palpalá', 'La Quiaca'],
    'Río Negro': ['Viedma', 'San Carlos de Bariloche', 'General Roca', 'Cipolletti', 'Villa Regina'],
    'Neuquén': ['Neuquén', 'San Martín de los Andes', 'Cutral Có', 'Zapala', 'Centenario'],
    'Formosa': ['Formosa', 'Clorinda', 'Pirané', 'El Colorado', 'Ingeniero Juárez'],
    'Chubut': ['Rawson', 'Comodoro Rivadavia', 'Trelew', 'Puerto Madryn', 'Esquel'],
    'San Luis': ['San Luis', 'Villa Mercedes', 'Merlo', 'La Punta', 'Justo Daract'],
    'Catamarca': ['San Fernando del Valle de Catamarca', 'Andalgalá', 'Belén', 'Tinogasta', 'Santa María'],
    'La Rioja': ['La Rioja', 'Chilecito', 'Arauco', 'Chamical', 'Aimogasta'],
    'La Pampa': ['Santa Rosa', 'General Pico', 'Toay', 'Eduardo Castex', 'Realicó'],
    'Santa Cruz': ['Río Gallegos', 'Caleta Olivia', 'Pico Truncado', 'Puerto Deseado', 'El Calafate'],
    'Tierra del Fuego': ['Ushuaia', 'Río Grande', 'Tolhuin'],
  };
  
  @override
  List<String> getStates() {
    return _provincesAndCities.keys.toList()..sort();
  }
  
  @override
  List<String> getCitiesForState(String state) {
    return _provincesAndCities[state] ?? [];
  }
  
  @override
  String formatLocation(String city, String state) {
    return '$city, $state';
  }
  
  @override
  String? getStateAbbreviation(String state) {
    return null; // Argentina não usa siglas
  }
}
