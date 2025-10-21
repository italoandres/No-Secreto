/// Dados de localização mundial (Países e principais cidades)
class WorldLocationsData {
  /// Lista de países do mundo (ordenados por relevância)
  static const List<Map<String, String>> countries = [
    // Países de língua portuguesa (prioridade)
    {'code': 'BR', 'name': 'Brasil', 'flag': '🇧🇷'},
    {'code': 'PT', 'name': 'Portugal', 'flag': '🇵🇹'},
    {'code': 'AO', 'name': 'Angola', 'flag': '🇦🇴'},
    {'code': 'MZ', 'name': 'Moçambique', 'flag': '🇲🇿'},
    {'code': 'CV', 'name': 'Cabo Verde', 'flag': '🇨🇻'},
    {'code': 'GW', 'name': 'Guiné-Bissau', 'flag': '🇬🇼'},
    {'code': 'ST', 'name': 'São Tomé e Príncipe', 'flag': '🇸🇹'},
    {'code': 'TL', 'name': 'Timor-Leste', 'flag': '🇹🇱'},
    {'code': 'GQ', 'name': 'Guiné Equatorial', 'flag': '🇬🇶'},
    
    // Américas
    {'code': 'US', 'name': 'Estados Unidos', 'flag': '🇺🇸'},
    {'code': 'CA', 'name': 'Canadá', 'flag': '🇨🇦'},
    {'code': 'MX', 'name': 'México', 'flag': '🇲🇽'},
    {'code': 'AR', 'name': 'Argentina', 'flag': '🇦🇷'},
    {'code': 'CL', 'name': 'Chile', 'flag': '🇨🇱'},
    {'code': 'CO', 'name': 'Colômbia', 'flag': '🇨🇴'},
    {'code': 'PE', 'name': 'Peru', 'flag': '🇵🇪'},
    {'code': 'VE', 'name': 'Venezuela', 'flag': '🇻🇪'},
    {'code': 'EC', 'name': 'Equador', 'flag': '🇪🇨'},
    {'code': 'BO', 'name': 'Bolívia', 'flag': '🇧🇴'},
    {'code': 'PY', 'name': 'Paraguai', 'flag': '🇵🇾'},
    {'code': 'UY', 'name': 'Uruguai', 'flag': '🇺🇾'},
    {'code': 'CR', 'name': 'Costa Rica', 'flag': '🇨🇷'},
    {'code': 'PA', 'name': 'Panamá', 'flag': '🇵🇦'},
    {'code': 'CU', 'name': 'Cuba', 'flag': '🇨🇺'},
    {'code': 'DO', 'name': 'República Dominicana', 'flag': '🇩🇴'},
    {'code': 'GT', 'name': 'Guatemala', 'flag': '🇬🇹'},
    {'code': 'HN', 'name': 'Honduras', 'flag': '🇭🇳'},
    {'code': 'SV', 'name': 'El Salvador', 'flag': '🇸🇻'},
    {'code': 'NI', 'name': 'Nicarágua', 'flag': '🇳🇮'},
    {'code': 'JM', 'name': 'Jamaica', 'flag': '🇯🇲'},
    {'code': 'TT', 'name': 'Trinidad e Tobago', 'flag': '🇹🇹'},
    
    // Europa
    {'code': 'GB', 'name': 'Reino Unido', 'flag': '🇬🇧'},
    {'code': 'DE', 'name': 'Alemanha', 'flag': '🇩🇪'},
    {'code': 'FR', 'name': 'França', 'flag': '🇫🇷'},
    {'code': 'IT', 'name': 'Itália', 'flag': '🇮🇹'},
    {'code': 'ES', 'name': 'Espanha', 'flag': '🇪🇸'},
    {'code': 'NL', 'name': 'Holanda', 'flag': '🇳🇱'},
    {'code': 'BE', 'name': 'Bélgica', 'flag': '🇧🇪'},
    {'code': 'CH', 'name': 'Suíça', 'flag': '🇨🇭'},
    {'code': 'AT', 'name': 'Áustria', 'flag': '🇦🇹'},
    {'code': 'SE', 'name': 'Suécia', 'flag': '🇸🇪'},
    {'code': 'NO', 'name': 'Noruega', 'flag': '🇳🇴'},
    {'code': 'DK', 'name': 'Dinamarca', 'flag': '🇩🇰'},
    {'code': 'FI', 'name': 'Finlândia', 'flag': '🇫🇮'},
    {'code': 'IE', 'name': 'Irlanda', 'flag': '🇮🇪'},
    {'code': 'PL', 'name': 'Polônia', 'flag': '🇵🇱'},
    {'code': 'CZ', 'name': 'República Tcheca', 'flag': '🇨🇿'},
    {'code': 'HU', 'name': 'Hungria', 'flag': '🇭🇺'},
    {'code': 'RO', 'name': 'Romênia', 'flag': '🇷🇴'},
    {'code': 'GR', 'name': 'Grécia', 'flag': '🇬🇷'},
    {'code': 'RU', 'name': 'Rússia', 'flag': '🇷🇺'},
    {'code': 'UA', 'name': 'Ucrânia', 'flag': '🇺🇦'},
    
    // Ásia
    {'code': 'CN', 'name': 'China', 'flag': '🇨🇳'},
    {'code': 'JP', 'name': 'Japão', 'flag': '🇯🇵'},
    {'code': 'KR', 'name': 'Coreia do Sul', 'flag': '🇰🇷'},
    {'code': 'IN', 'name': 'Índia', 'flag': '🇮🇳'},
    {'code': 'ID', 'name': 'Indonésia', 'flag': '🇮🇩'},
    {'code': 'TH', 'name': 'Tailândia', 'flag': '🇹🇭'},
    {'code': 'VN', 'name': 'Vietnã', 'flag': '🇻🇳'},
    {'code': 'PH', 'name': 'Filipinas', 'flag': '🇵🇭'},
    {'code': 'MY', 'name': 'Malásia', 'flag': '🇲🇾'},
    {'code': 'SG', 'name': 'Singapura', 'flag': '🇸🇬'},
    {'code': 'PK', 'name': 'Paquistão', 'flag': '🇵🇰'},
    {'code': 'BD', 'name': 'Bangladesh', 'flag': '🇧🇩'},
    {'code': 'TR', 'name': 'Turquia', 'flag': '🇹🇷'},
    {'code': 'IL', 'name': 'Israel', 'flag': '🇮🇱'},
    {'code': 'SA', 'name': 'Arábia Saudita', 'flag': '🇸🇦'},
    {'code': 'AE', 'name': 'Emirados Árabes', 'flag': '🇦🇪'},
    {'code': 'IQ', 'name': 'Iraque', 'flag': '🇮🇶'},
    {'code': 'IR', 'name': 'Irã', 'flag': '🇮🇷'},
    
    // Oceania
    {'code': 'AU', 'name': 'Austrália', 'flag': '🇦🇺'},
    {'code': 'NZ', 'name': 'Nova Zelândia', 'flag': '🇳🇿'},
    
    // África
    {'code': 'ZA', 'name': 'África do Sul', 'flag': '🇿🇦'},
    {'code': 'EG', 'name': 'Egito', 'flag': '🇪🇬'},
    {'code': 'NG', 'name': 'Nigéria', 'flag': '🇳🇬'},
    {'code': 'KE', 'name': 'Quênia', 'flag': '🇰🇪'},
    {'code': 'ET', 'name': 'Etiópia', 'flag': '🇪🇹'},
    {'code': 'GH', 'name': 'Gana', 'flag': '🇬🇭'},
    {'code': 'MA', 'name': 'Marrocos', 'flag': '🇲🇦'},
    {'code': 'TN', 'name': 'Tunísia', 'flag': '🇹🇳'},
    {'code': 'DZ', 'name': 'Argélia', 'flag': '🇩🇿'},
    {'code': 'SN', 'name': 'Senegal', 'flag': '🇸🇳'},
    {'code': 'UG', 'name': 'Uganda', 'flag': '🇺🇬'},
    {'code': 'TZ', 'name': 'Tanzânia', 'flag': '🇹🇿'},
    {'code': 'ZW', 'name': 'Zimbábue', 'flag': '🇿🇼'},
    
    // Outros países relevantes
    {'code': 'AF', 'name': 'Afeganistão', 'flag': '🇦🇫'},
    {'code': 'AL', 'name': 'Albânia', 'flag': '🇦🇱'},
    {'code': 'AM', 'name': 'Armênia', 'flag': '🇦🇲'},
    {'code': 'AZ', 'name': 'Azerbaijão', 'flag': '🇦🇿'},
    {'code': 'BH', 'name': 'Bahrein', 'flag': '🇧🇭'},
    {'code': 'BY', 'name': 'Bielorrússia', 'flag': '🇧🇾'},
    {'code': 'BZ', 'name': 'Belize', 'flag': '🇧🇿'},
    {'code': 'BJ', 'name': 'Benin', 'flag': '🇧🇯'},
    {'code': 'BT', 'name': 'Butão', 'flag': '🇧🇹'},
    {'code': 'BA', 'name': 'Bósnia e Herzegovina', 'flag': '🇧🇦'},
    {'code': 'BW', 'name': 'Botsuana', 'flag': '🇧🇼'},
    {'code': 'BN', 'name': 'Brunei', 'flag': '🇧🇳'},
    {'code': 'BG', 'name': 'Bulgária', 'flag': '🇧🇬'},
    {'code': 'BF', 'name': 'Burkina Faso', 'flag': '🇧🇫'},
    {'code': 'BI', 'name': 'Burundi', 'flag': '🇧🇮'},
    {'code': 'KH', 'name': 'Camboja', 'flag': '🇰🇭'},
    {'code': 'CM', 'name': 'Camarões', 'flag': '🇨🇲'},
    {'code': 'TD', 'name': 'Chade', 'flag': '🇹🇩'},
    {'code': 'CY', 'name': 'Chipre', 'flag': '🇨🇾'},
    {'code': 'KM', 'name': 'Comores', 'flag': '🇰🇲'},
    {'code': 'CG', 'name': 'Congo', 'flag': '🇨🇬'},
    {'code': 'CD', 'name': 'Congo (RDC)', 'flag': '🇨🇩'},
    {'code': 'KP', 'name': 'Coreia do Norte', 'flag': '🇰🇵'},
    {'code': 'CI', 'name': 'Costa do Marfim', 'flag': '🇨🇮'},
    {'code': 'HR', 'name': 'Croácia', 'flag': '🇭🇷'},
    {'code': 'DJ', 'name': 'Djibuti', 'flag': '🇩🇯'},
    {'code': 'ER', 'name': 'Eritreia', 'flag': '🇪🇷'},
    {'code': 'SK', 'name': 'Eslováquia', 'flag': '🇸🇰'},
    {'code': 'SI', 'name': 'Eslovênia', 'flag': '🇸🇮'},
    {'code': 'EE', 'name': 'Estônia', 'flag': '🇪🇪'},
    {'code': 'FJ', 'name': 'Fiji', 'flag': '🇫🇯'},
    {'code': 'GA', 'name': 'Gabão', 'flag': '🇬🇦'},
    {'code': 'GM', 'name': 'Gâmbia', 'flag': '🇬🇲'},
    {'code': 'GE', 'name': 'Geórgia', 'flag': '🇬🇪'},
    {'code': 'GN', 'name': 'Guiné', 'flag': '🇬🇳'},
    {'code': 'GY', 'name': 'Guiana', 'flag': '🇬🇾'},
    {'code': 'HT', 'name': 'Haiti', 'flag': '🇭🇹'},
    {'code': 'IS', 'name': 'Islândia', 'flag': '🇮🇸'},
    {'code': 'JO', 'name': 'Jordânia', 'flag': '🇯🇴'},
    {'code': 'KZ', 'name': 'Cazaquistão', 'flag': '🇰🇿'},
    {'code': 'KW', 'name': 'Kuwait', 'flag': '🇰🇼'},
    {'code': 'KG', 'name': 'Quirguistão', 'flag': '🇰🇬'},
    {'code': 'LA', 'name': 'Laos', 'flag': '🇱🇦'},
    {'code': 'LV', 'name': 'Letônia', 'flag': '🇱🇻'},
    {'code': 'LB', 'name': 'Líbano', 'flag': '🇱🇧'},
    {'code': 'LS', 'name': 'Lesoto', 'flag': '🇱🇸'},
    {'code': 'LR', 'name': 'Libéria', 'flag': '🇱🇷'},
    {'code': 'LY', 'name': 'Líbia', 'flag': '🇱🇾'},
    {'code': 'LI', 'name': 'Liechtenstein', 'flag': '🇱🇮'},
    {'code': 'LT', 'name': 'Lituânia', 'flag': '🇱🇹'},
    {'code': 'LU', 'name': 'Luxemburgo', 'flag': '🇱🇺'},
    {'code': 'MK', 'name': 'Macedônia do Norte', 'flag': '🇲🇰'},
    {'code': 'MG', 'name': 'Madagascar', 'flag': '🇲🇬'},
    {'code': 'MW', 'name': 'Malawi', 'flag': '🇲🇼'},
    {'code': 'MV', 'name': 'Maldivas', 'flag': '🇲🇻'},
    {'code': 'ML', 'name': 'Mali', 'flag': '🇲🇱'},
    {'code': 'MT', 'name': 'Malta', 'flag': '🇲🇹'},
    {'code': 'MR', 'name': 'Mauritânia', 'flag': '🇲🇷'},
    {'code': 'MU', 'name': 'Maurício', 'flag': '🇲🇺'},
    {'code': 'MD', 'name': 'Moldávia', 'flag': '🇲🇩'},
    {'code': 'MC', 'name': 'Mônaco', 'flag': '🇲🇨'},
    {'code': 'MN', 'name': 'Mongólia', 'flag': '🇲🇳'},
    {'code': 'ME', 'name': 'Montenegro', 'flag': '🇲🇪'},
    {'code': 'MM', 'name': 'Mianmar', 'flag': '🇲🇲'},
    {'code': 'NA', 'name': 'Namíbia', 'flag': '🇳🇦'},
    {'code': 'NR', 'name': 'Nauru', 'flag': '🇳🇷'},
    {'code': 'NP', 'name': 'Nepal', 'flag': '🇳🇵'},
    {'code': 'NE', 'name': 'Níger', 'flag': '🇳🇪'},
    {'code': 'OM', 'name': 'Omã', 'flag': '🇴🇲'},
    {'code': 'PW', 'name': 'Palau', 'flag': '🇵🇼'},
    {'code': 'PS', 'name': 'Palestina', 'flag': '🇵🇸'},
    {'code': 'PG', 'name': 'Papua Nova Guiné', 'flag': '🇵🇬'},
    {'code': 'QA', 'name': 'Catar', 'flag': '🇶🇦'},
    {'code': 'CF', 'name': 'República Centro-Africana', 'flag': '🇨🇫'},
    {'code': 'RW', 'name': 'Ruanda', 'flag': '🇷🇼'},
    {'code': 'KN', 'name': 'São Cristóvão e Névis', 'flag': '🇰🇳'},
    {'code': 'LC', 'name': 'Santa Lúcia', 'flag': '🇱🇨'},
    {'code': 'VC', 'name': 'São Vicente e Granadinas', 'flag': '🇻🇨'},
    {'code': 'WS', 'name': 'Samoa', 'flag': '🇼🇸'},
    {'code': 'SM', 'name': 'San Marino', 'flag': '🇸🇲'},
    {'code': 'SC', 'name': 'Seychelles', 'flag': '🇸🇨'},
    {'code': 'SL', 'name': 'Serra Leoa', 'flag': '🇸🇱'},
    {'code': 'SY', 'name': 'Síria', 'flag': '🇸🇾'},
    {'code': 'SO', 'name': 'Somália', 'flag': '🇸🇴'},
    {'code': 'LK', 'name': 'Sri Lanka', 'flag': '🇱🇰'},
    {'code': 'SZ', 'name': 'Essuatíni', 'flag': '🇸🇿'},
    {'code': 'SD', 'name': 'Sudão', 'flag': '🇸🇩'},
    {'code': 'SS', 'name': 'Sudão do Sul', 'flag': '🇸🇸'},
    {'code': 'SR', 'name': 'Suriname', 'flag': '🇸🇷'},
    {'code': 'TJ', 'name': 'Tajiquistão', 'flag': '🇹🇯'},
    {'code': 'TW', 'name': 'Taiwan', 'flag': '🇹🇼'},
    {'code': 'TG', 'name': 'Togo', 'flag': '🇹🇬'},
    {'code': 'TO', 'name': 'Tonga', 'flag': '🇹🇴'},
    {'code': 'TM', 'name': 'Turcomenistão', 'flag': '🇹🇲'},
    {'code': 'TV', 'name': 'Tuvalu', 'flag': '🇹🇻'},
    {'code': 'UZ', 'name': 'Uzbequistão', 'flag': '🇺🇿'},
    {'code': 'VU', 'name': 'Vanuatu', 'flag': '🇻🇺'},
    {'code': 'VA', 'name': 'Vaticano', 'flag': '🇻🇦'},
    {'code': 'YE', 'name': 'Iêmen', 'flag': '🇾🇪'},
    {'code': 'ZM', 'name': 'Zâmbia', 'flag': '🇿🇲'},
  ];
  
  /// Retorna a lista de nomes dos países
  static List<String> getCountryNames() {
    return countries.map((country) => country['name']!).toList();
  }
  
  /// Retorna o nome do país pelo código
  static String getCountryName(String code) {
    final country = countries.firstWhere(
      (c) => c['code'] == code,
      orElse: () => {'name': code},
    );
    return country['name']!;
  }
  
  /// Retorna a bandeira do país pelo código
  static String getCountryFlag(String code) {
    final country = countries.firstWhere(
      (c) => c['code'] == code,
      orElse: () => {'flag': '🌐'},
    );
    return country['flag']!;
  }
  
  /// Retorna o código do país pelo nome
  static String? getCountryCode(String name) {
    final country = countries.firstWhere(
      (c) => c['name'] == name,
      orElse: () => {},
    );
    return country['code'];
  }
  
  /// Verifica se é um país de língua portuguesa
  static bool isPortugueseSpeakingCountry(String countryName) {
    const portugueseCountries = [
      'Brasil',
      'Portugal',
      'Angola',
      'Moçambique',
      'Cabo Verde',
      'Guiné-Bissau',
      'São Tomé e Príncipe',
      'Timor-Leste',
      'Guiné Equatorial',
    ];
    return portugueseCountries.contains(countryName);
  }
}
