/// Dados de localização do Canadá (Províncias/Territórios e principais cidades)
class CanadaLocationsData {
  /// Lista de províncias e territórios canadenses
  static const List<String> provinces = [
    'Alberta',
    'British Columbia',
    'Manitoba',
    'New Brunswick',
    'Newfoundland and Labrador',
    'Northwest Territories',
    'Nova Scotia',
    'Nunavut',
    'Ontario',
    'Prince Edward Island',
    'Quebec',
    'Saskatchewan',
    'Yukon',
  ];

  /// Mapa de siglas das províncias/territórios
  static const Map<String, String> provinceAbbreviations = {
    'Alberta': 'AB',
    'British Columbia': 'BC',
    'Manitoba': 'MB',
    'New Brunswick': 'NB',
    'Newfoundland and Labrador': 'NL',
    'Northwest Territories': 'NT',
    'Nova Scotia': 'NS',
    'Nunavut': 'NU',
    'Ontario': 'ON',
    'Prince Edward Island': 'PE',
    'Quebec': 'QC',
    'Saskatchewan': 'SK',
    'Yukon': 'YT',
  };

  /// Mapa de cidades por província/território
  static const Map<String, List<String>> citiesByProvince = {
    'Ontario': [
      'Toronto',
      'Ottawa',
      'Mississauga',
      'Hamilton',
      'London',
      'Kitchener',
    ],
    'Quebec': [
      'Montreal',
      'Quebec City',
      'Laval',
      'Gatineau',
      'Sherbrooke',
    ],
    'British Columbia': [
      'Vancouver',
      'Victoria',
      'Surrey',
      'Burnaby',
      'Richmond',
    ],
    'Alberta': [
      'Calgary',
      'Edmonton',
      'Red Deer',
      'Lethbridge',
    ],
    'Manitoba': [
      'Winnipeg',
      'Brandon',
    ],
    'Saskatchewan': [
      'Saskatoon',
      'Regina',
    ],
    'Nova Scotia': [
      'Halifax',
      'Dartmouth',
    ],
    'New Brunswick': [
      'Moncton',
      'Saint John',
      'Fredericton',
    ],
    'Newfoundland and Labrador': [
      'St. John\'s',
      'Mount Pearl',
    ],
    'Prince Edward Island': [
      'Charlottetown',
      'Summerside',
    ],
    'Northwest Territories': [
      'Yellowknife',
    ],
    'Yukon': [
      'Whitehorse',
    ],
    'Nunavut': [
      'Iqaluit',
    ],
  };

  /// Retorna as cidades de uma província/território
  static List<String> getCitiesForProvince(String province) {
    return citiesByProvince[province] ?? [];
  }

  /// Retorna a sigla de uma província/território
  static String? getProvinceAbbreviation(String province) {
    return provinceAbbreviations[province];
  }
}
