import '../interfaces/location_data_interface.dart';
import '../utils/portugal_locations_data.dart';

/// Implementação de dados de localização para Portugal
class PortugalLocationData implements LocationDataInterface {
  @override
  String get countryName => 'Portugal';

  @override
  String get countryCode => 'PT';

  @override
  String get stateLabel => 'Distrito';

  @override
  bool get useStateAbbreviation => false;

  @override
  List<String> getStates() {
    return PortugalLocationsData.districts;
  }

  @override
  List<String> getCitiesForState(String district) {
    return PortugalLocationsData.getCitiesForDistrict(district);
  }

  @override
  String formatLocation(String city, String district) {
    return '$city, $district';
  }

  @override
  String? getStateAbbreviation(String state) => null;
}
