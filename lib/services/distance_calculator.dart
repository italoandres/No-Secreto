import 'dart:math' as math;

/// Calculador de distância geográfica usando fórmula de Haversine
class DistanceCalculator {
  /// Raio médio da Terra em quilômetros
  static const double earthRadiusKm = 6371.0;

  /// Calcula a distância entre duas coordenadas geográficas
  /// usando a fórmula de Haversine
  ///
  /// Parâmetros:
  /// - [lat1]: Latitude do ponto 1 em graus
  /// - [lon1]: Longitude do ponto 1 em graus
  /// - [lat2]: Latitude do ponto 2 em graus
  /// - [lon2]: Longitude do ponto 2 em graus
  ///
  /// Retorna a distância em quilômetros
  double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    // Converter graus para radianos
    final lat1Rad = _degreesToRadians(lat1);
    final lon1Rad = _degreesToRadians(lon1);
    final lat2Rad = _degreesToRadians(lat2);
    final lon2Rad = _degreesToRadians(lon2);

    // Diferenças
    final dLat = lat2Rad - lat1Rad;
    final dLon = lon2Rad - lon1Rad;

    // Fórmula de Haversine
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.pow(math.sin(dLon / 2), 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    // Distância em quilômetros
    final distance = earthRadiusKm * c;

    return distance;
  }

  /// Verifica se um perfil está dentro do raio máximo configurado
  ///
  /// Parâmetros:
  /// - [userLat]: Latitude do usuário
  /// - [userLon]: Longitude do usuário
  /// - [profileLat]: Latitude do perfil
  /// - [profileLon]: Longitude do perfil
  /// - [maxDistanceKm]: Distância máxima em quilômetros
  ///
  /// Retorna true se o perfil está dentro do raio
  bool isWithinRadius({
    required double userLat,
    required double userLon,
    required double profileLat,
    required double profileLon,
    required double maxDistanceKm,
  }) {
    final distance = calculateDistance(
      lat1: userLat,
      lon1: userLon,
      lat2: profileLat,
      lon2: profileLon,
    );

    return distance <= maxDistanceKm;
  }

  /// Calcula distância entre localizações usando Map
  double calculateDistanceFromMaps({
    required Map<String, dynamic> userLocation,
    required Map<String, dynamic> profileLocation,
  }) {
    final userLat = userLocation['latitude'] as double?;
    final userLon = userLocation['longitude'] as double?;
    final profileLat = profileLocation['latitude'] as double?;
    final profileLon = profileLocation['longitude'] as double?;

    if (userLat == null ||
        userLon == null ||
        profileLat == null ||
        profileLon == null) {
      throw ArgumentError('Coordenadas inválidas ou ausentes');
    }

    return calculateDistance(
      lat1: userLat,
      lon1: userLon,
      lat2: profileLat,
      lon2: profileLon,
    );
  }

  /// Verifica se está dentro do raio usando Map
  bool isWithinRadiusFromMaps({
    required Map<String, dynamic> userLocation,
    required Map<String, dynamic> profileLocation,
    required double maxDistanceKm,
  }) {
    try {
      final distance = calculateDistanceFromMaps(
        userLocation: userLocation,
        profileLocation: profileLocation,
      );
      return distance <= maxDistanceKm;
    } catch (e) {
      return false;
    }
  }

  /// Converte graus para radianos
  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }

  /// Converte radianos para graus
  double _radiansToDegrees(double radians) {
    return radians * 180.0 / math.pi;
  }

  /// Formata distância para exibição
  String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).toStringAsFixed(0)}m';
    } else if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)}km';
    } else {
      return '${distanceKm.toStringAsFixed(0)}km';
    }
  }

  /// Calcula o ponto médio entre duas coordenadas
  Map<String, double> calculateMidpoint({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final lat1Rad = _degreesToRadians(lat1);
    final lon1Rad = _degreesToRadians(lon1);
    final lat2Rad = _degreesToRadians(lat2);
    final lon2Rad = _degreesToRadians(lon2);

    final dLon = lon2Rad - lon1Rad;

    final bx = math.cos(lat2Rad) * math.cos(dLon);
    final by = math.cos(lat2Rad) * math.sin(dLon);

    final lat3Rad = math.atan2(
      math.sin(lat1Rad) + math.sin(lat2Rad),
      math.sqrt((math.cos(lat1Rad) + bx) * (math.cos(lat1Rad) + bx) + by * by),
    );

    final lon3Rad = lon1Rad + math.atan2(by, math.cos(lat1Rad) + bx);

    return {
      'latitude': _radiansToDegrees(lat3Rad),
      'longitude': _radiansToDegrees(lon3Rad),
    };
  }
}
