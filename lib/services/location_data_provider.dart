import '../interfaces/location_data_interface.dart';
import '../implementations/brazil_location_data.dart';
import '../implementations/usa_location_data.dart';
import '../implementations/portugal_location_data.dart';
import '../implementations/canada_location_data.dart';
import '../implementations/argentina_location_data.dart';
import '../implementations/mexico_location_data.dart';
import '../implementations/spain_location_data.dart';
import '../implementations/france_location_data.dart';
import '../implementations/italy_location_data.dart';
import '../implementations/germany_location_data.dart';
import '../implementations/uk_location_data.dart';

/// Factory para fornecer dados de localização por país
///
/// Gerencia todos os provedores de dados estruturados disponíveis
class LocationDataProvider {
  static final Map<String, LocationDataInterface> _providers = {
    'BR': BrazilLocationData(),
    'US': USALocationData(),
    'PT': PortugalLocationData(),
    'CA': CanadaLocationData(),
    'AR': ArgentinaLocationData(),
    'MX': MexicoLocationData(),
    'ES': SpainLocationData(),
    'FR': FranceLocationData(),
    'IT': ItalyLocationData(),
    'DE': GermanyLocationData(),
    'GB': UKLocationData(),
  };

  /// Verifica se um país tem dados estruturados
  static bool hasStructuredData(String countryCode) {
    return _providers.containsKey(countryCode);
  }

  /// Retorna o provedor de dados para um país
  static LocationDataInterface? getLocationData(String countryCode) {
    return _providers[countryCode];
  }

  /// Retorna lista de códigos de países com dados estruturados
  static List<String> getCountriesWithStructuredData() {
    return _providers.keys.toList();
  }

  /// Retorna lista de nomes de países com dados estruturados
  static List<String> getCountryNamesWithStructuredData() {
    return _providers.values.map((p) => p.countryName).toList();
  }

  /// Registra um novo provedor de dados
  /// Usado internamente para adicionar países
  static void _registerProvider(LocationDataInterface provider) {
    _providers[provider.countryCode] = provider;
  }
}
