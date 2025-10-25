import '../interfaces/location_data_interface.dart';
import '../utils/canada_locations_data.dart';

/// Implementação de dados de localização para o Canadá
class CanadaLocationData implements LocationDataInterface {
  @override
  String get countryName => 'Canadá';

  @override
  String get countryCode => 'CA';

  @override
  String get stateLabel => 'Província/Território';

  @override
  bool get useStateAbbreviation => true;

  @override
  List<String> getStates() {
    return CanadaLocationsData.provinces;
  }

  @override
  List<String> getCitiesForState(String province) {
    return CanadaLocationsData.getCitiesForProvince(province);
  }

  @override
  String formatLocation(String city, String province) {
    final abbr = getStateAbbreviation(province);
    if (abbr != null) {
      return '$city, $abbr';
    }
    return '$city, $province';
  }

  @override
  String? getStateAbbreviation(String province) {
    return CanadaLocationsData.getProvinceAbbreviation(province);
  }
}
