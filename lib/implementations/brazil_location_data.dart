import '../interfaces/location_data_interface.dart';
import '../utils/brazil_locations_data.dart';

/// Implementação de dados de localização para o Brasil
class BrazilLocationData implements LocationDataInterface {
  @override
  String get countryName => 'Brasil';
  
  @override
  String get countryCode => 'BR';
  
  @override
  String get stateLabel => 'Estado';
  
  @override
  bool get useStateAbbreviation => true;
  
  @override
  List<String> getStates() {
    return BrazilLocationsData.states;
  }
  
  @override
  List<String> getCitiesForState(String state) {
    return BrazilLocationsData.getCitiesForState(state);
  }
  
  @override
  String formatLocation(String city, String state) {
    final abbr = getStateAbbreviation(state);
    if (abbr != null) {
      return '$city - $abbr';
    }
    return '$city, $state';
  }
  
  @override
  String? getStateAbbreviation(String state) {
    return BrazilLocationsData.getStateAbbreviation(state);
  }
}
