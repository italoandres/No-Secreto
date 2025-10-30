/// Dados de localização de Portugal (Distritos e principais cidades)
class PortugalLocationsData {
  /// Lista de distritos portugueses
  static const List<String> districts = [
    'Aveiro',
    'Beja',
    'Braga',
    'Bragança',
    'Castelo Branco',
    'Coimbra',
    'Évora',
    'Faro',
    'Guarda',
    'Leiria',
    'Lisboa',
    'Portalegre',
    'Porto',
    'Santarém',
    'Setúbal',
    'Viana do Castelo',
    'Vila Real',
    'Viseu',
  ];

  /// Mapa de cidades por distrito (principais cidades)
  static const Map<String, List<String>> citiesByDistrict = {
    'Lisboa': [
      'Lisboa',
      'Sintra',
      'Cascais',
      'Loures',
      'Amadora',
      'Oeiras',
    ],
    'Porto': [
      'Porto',
      'Vila Nova de Gaia',
      'Matosinhos',
      'Gondomar',
      'Maia',
    ],
    'Braga': [
      'Braga',
      'Guimarães',
      'Barcelos',
      'Famalicão',
    ],
    'Aveiro': [
      'Aveiro',
      'Ílhavo',
      'Ovar',
      'Águeda',
    ],
    'Faro': [
      'Faro',
      'Portimão',
      'Albufeira',
      'Loulé',
      'Lagos',
    ],
    'Coimbra': [
      'Coimbra',
      'Figueira da Foz',
      'Cantanhede',
    ],
    'Setúbal': [
      'Setúbal',
      'Almada',
      'Barreiro',
      'Seixal',
    ],
    'Leiria': [
      'Leiria',
      'Marinha Grande',
      'Alcobaça',
    ],
    'Santarém': [
      'Santarém',
      'Torres Novas',
      'Entroncamento',
    ],
    'Viseu': [
      'Viseu',
      'Lamego',
      'Tondela',
    ],
    'Viana do Castelo': [
      'Viana do Castelo',
      'Ponte de Lima',
    ],
    'Vila Real': [
      'Vila Real',
      'Chaves',
      'Peso da Régua',
    ],
    'Évora': [
      'Évora',
      'Estremoz',
    ],
    'Beja': [
      'Beja',
      'Moura',
    ],
    'Bragança': [
      'Bragança',
      'Mirandela',
    ],
    'Castelo Branco': [
      'Castelo Branco',
      'Covilhã',
      'Fundão',
    ],
    'Guarda': [
      'Guarda',
      'Seia',
    ],
    'Portalegre': [
      'Portalegre',
      'Elvas',
    ],
  };

  /// Retorna as cidades de um distrito
  static List<String> getCitiesForDistrict(String district) {
    return citiesByDistrict[district] ?? [];
  }
}
