import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_chat/services/distance_calculator.dart';

void main() {
  late DistanceCalculator calculator;

  setUp(() {
    calculator = DistanceCalculator();
  });

  group('DistanceCalculator', () {
    group('calculateDistance', () {
      test('calcula distância entre São Paulo e Rio de Janeiro corretamente',
          () {
        // São Paulo: -23.5505, -46.6333
        // Rio de Janeiro: -22.9068, -43.1729
        // Distância real: ~357km

        final distance = calculator.calculateDistance(
          lat1: -23.5505,
          lon1: -46.6333,
          lat2: -22.9068,
          lon2: -43.1729,
        );

        // Verificar com margem de erro de 5km
        expect(distance, greaterThan(352));
        expect(distance, lessThan(362));
      });

      test('calcula distância entre Brasília e Salvador corretamente', () {
        // Brasília: -15.7939, -47.8828
        // Salvador: -12.9714, -38.5014
        // Distância real: ~1059km

        final distance = calculator.calculateDistance(
          lat1: -15.7939,
          lon1: -47.8828,
          lat2: -12.9714,
          lon2: -38.5014,
        );

        // Verificar com margem de erro de 10km
        expect(distance, greaterThan(1049));
        expect(distance, lessThan(1069));
      });

      test('retorna 0 para mesma localização', () {
        final distance = calculator.calculateDistance(
          lat1: -23.5505,
          lon1: -46.6333,
          lat2: -23.5505,
          lon2: -46.6333,
        );

        expect(distance, equals(0));
      });

      test('calcula distância muito pequena corretamente', () {
        // Duas localizações muito próximas (diferença de 0.001 graus)
        final distance = calculator.calculateDistance(
          lat1: -23.5505,
          lon1: -46.6333,
          lat2: -23.5515,
          lon2: -46.6343,
        );

        // Deve ser menos de 2km
        expect(distance, lessThan(2));
        expect(distance, greaterThan(0));
      });

      test('funciona com coordenadas no hemisfério norte', () {
        // Nova York: 40.7128, -74.0060
        // Los Angeles: 34.0522, -118.2437
        // Distância real: ~3944km

        final distance = calculator.calculateDistance(
          lat1: 40.7128,
          lon1: -74.0060,
          lat2: 34.0522,
          lon2: -118.2437,
        );

        // Verificar com margem de erro de 50km
        expect(distance, greaterThan(3894));
        expect(distance, lessThan(3994));
      });

      test('funciona com coordenadas positivas e negativas', () {
        // Londres: 51.5074, -0.1278
        // Sydney: -33.8688, 151.2093
        // Distância real: ~17015km

        final distance = calculator.calculateDistance(
          lat1: 51.5074,
          lon1: -0.1278,
          lat2: -33.8688,
          lon2: 151.2093,
        );

        // Verificar com margem de erro de 100km
        expect(distance, greaterThan(16915));
        expect(distance, lessThan(17115));
      });

      test('funciona na linha do equador', () {
        // Duas cidades próximas ao equador
        final distance = calculator.calculateDistance(
          lat1: 0.0,
          lon1: 0.0,
          lat2: 0.0,
          lon2: 1.0,
        );

        // 1 grau de longitude no equador ≈ 111km
        expect(distance, greaterThan(105));
        expect(distance, lessThan(115));
      });

      test('funciona próximo aos polos', () {
        // Duas localizações próximas ao polo norte
        final distance = calculator.calculateDistance(
          lat1: 89.0,
          lon1: 0.0,
          lat2: 89.0,
          lon2: 90.0,
        );

        // Distância deve ser pequena devido à convergência dos meridianos
        expect(distance, lessThan(200));
      });
    });

    group('isWithinRadius', () {
      test('retorna true quando dentro do raio', () {
        // São Paulo e Campinas (~90km)
        final isWithin = calculator.isWithinRadius(
          userLat: -23.5505,
          userLon: -46.6333,
          profileLat: -22.9056,
          profileLon: -47.0608,
          maxDistanceKm: 100,
        );

        expect(isWithin, isTrue);
      });

      test('retorna false quando fora do raio', () {
        // São Paulo e Rio de Janeiro (~357km)
        final isWithin = calculator.isWithinRadius(
          userLat: -23.5505,
          userLon: -46.6333,
          profileLat: -22.9068,
          profileLon: -43.1729,
          maxDistanceKm: 300,
        );

        expect(isWithin, isFalse);
      });

      test('retorna true quando exatamente no limite do raio', () {
        final distance = calculator.calculateDistance(
          lat1: -23.5505,
          lon1: -46.6333,
          lat2: -22.9068,
          lon2: -43.1729,
        );

        final isWithin = calculator.isWithinRadius(
          userLat: -23.5505,
          userLon: -46.6333,
          profileLat: -22.9068,
          profileLon: -43.1729,
          maxDistanceKm: distance,
        );

        expect(isWithin, isTrue);
      });

      test('retorna true para mesma localização', () {
        final isWithin = calculator.isWithinRadius(
          userLat: -23.5505,
          userLon: -46.6333,
          profileLat: -23.5505,
          profileLon: -46.6333,
          maxDistanceKm: 1,
        );

        expect(isWithin, isTrue);
      });
    });

    group('calculateDistanceFromMaps', () {
      test('calcula distância corretamente usando Maps', () {
        final userLocation = {
          'latitude': -23.5505,
          'longitude': -46.6333,
        };

        final profileLocation = {
          'latitude': -22.9068,
          'longitude': -43.1729,
        };

        final distance = calculator.calculateDistanceFromMaps(
          userLocation: userLocation,
          profileLocation: profileLocation,
        );

        expect(distance, greaterThan(352));
        expect(distance, lessThan(362));
      });

      test('lança erro quando coordenadas estão ausentes', () {
        final userLocation = {
          'latitude': -23.5505,
        };

        final profileLocation = {
          'latitude': -22.9068,
          'longitude': -43.1729,
        };

        expect(
          () => calculator.calculateDistanceFromMaps(
            userLocation: userLocation,
            profileLocation: profileLocation,
          ),
          throwsArgumentError,
        );
      });

      test('lança erro quando coordenadas são nulas', () {
        final userLocation = {
          'latitude': null,
          'longitude': -46.6333,
        };

        final profileLocation = {
          'latitude': -22.9068,
          'longitude': -43.1729,
        };

        expect(
          () => calculator.calculateDistanceFromMaps(
            userLocation: userLocation,
            profileLocation: profileLocation,
          ),
          throwsArgumentError,
        );
      });
    });

    group('isWithinRadiusFromMaps', () {
      test('retorna true quando dentro do raio', () {
        final userLocation = {
          'latitude': -23.5505,
          'longitude': -46.6333,
        };

        final profileLocation = {
          'latitude': -22.9056,
          'longitude': -47.0608,
        };

        final isWithin = calculator.isWithinRadiusFromMaps(
          userLocation: userLocation,
          profileLocation: profileLocation,
          maxDistanceKm: 100,
        );

        expect(isWithin, isTrue);
      });

      test('retorna false quando coordenadas inválidas', () {
        final userLocation = {
          'latitude': null,
          'longitude': -46.6333,
        };

        final profileLocation = {
          'latitude': -22.9056,
          'longitude': -47.0608,
        };

        final isWithin = calculator.isWithinRadiusFromMaps(
          userLocation: userLocation,
          profileLocation: profileLocation,
          maxDistanceKm: 100,
        );

        expect(isWithin, isFalse);
      });
    });

    group('formatDistance', () {
      test('formata distâncias menores que 1km em metros', () {
        expect(calculator.formatDistance(0.5), equals('500m'));
        expect(calculator.formatDistance(0.123), equals('123m'));
      });

      test('formata distâncias entre 1-10km com 1 decimal', () {
        expect(calculator.formatDistance(1.5), equals('1.5km'));
        expect(calculator.formatDistance(9.8), equals('9.8km'));
      });

      test('formata distâncias maiores que 10km sem decimais', () {
        expect(calculator.formatDistance(15.7), equals('16km'));
        expect(calculator.formatDistance(357.4), equals('357km'));
      });
    });

    group('calculateMidpoint', () {
      test('calcula ponto médio entre duas coordenadas', () {
        // São Paulo e Rio de Janeiro
        final midpoint = calculator.calculateMidpoint(
          lat1: -23.5505,
          lon1: -46.6333,
          lat2: -22.9068,
          lon2: -43.1729,
        );

        // Ponto médio deve estar entre as duas cidades
        expect(midpoint['latitude'], greaterThan(-23.6));
        expect(midpoint['latitude'], lessThan(-22.9));
        expect(midpoint['longitude'], greaterThan(-46.7));
        expect(midpoint['longitude'], lessThan(-43.1));
      });

      test('retorna mesma coordenada quando pontos são iguais', () {
        final midpoint = calculator.calculateMidpoint(
          lat1: -23.5505,
          lon1: -46.6333,
          lat2: -23.5505,
          lon2: -46.6333,
        );

        expect(midpoint['latitude'], closeTo(-23.5505, 0.0001));
        expect(midpoint['longitude'], closeTo(-46.6333, 0.0001));
      });
    });
  });
}
