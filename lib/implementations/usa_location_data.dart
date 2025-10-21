import '../interfaces/location_data_interface.dart';
import '../utils/usa_locations_data.dart';

/// Implementação de dados de localização para os Estados Unidos
class USALocationData implements LocationDataInterface {
  @override
  String get countryName => 'Estados Unidos';
  
  @override
  String get countryCode => 'US';
  
  @override
  String get stateLabel => 'Estado';
  
  @override
  bool get useStateAbbreviation => true;
  
  @override
  List<String> getStates() {
    return USALocationsData.states;
  }
  
  @override
  List<String> getCitiesForState(String state) {
    return USALocationsData.getCitiesForState(state);
  }
  
  @override
  String formatLocation(String city, String state) {
    final abbr = getStateAbbreviation(state);
    if (abbr != null) {
      return '$city, $abbr';
    }
    return '$city, $state';
  }
  
  @override
  String? getStateAbbreviation(String state) {
    return USALocationsData.getStateAbbreviation(state);
  }
}
