import 'package:flutter/material.dart';
import '../services/location_data_provider.dart';
import '../utils/world_locations_data.dart';

/// Utilitário para testar o novo sistema de localização mundial
class TestWorldLocationSystem {
  /// Testa todos os países implementados
  static void testAllImplementedCountries() {
    debugPrint('🌍 TESTANDO SISTEMA DE LOCALIZAÇÃO MUNDIAL');
    debugPrint('=' * 50);
    
    final implementedCountries = [
      'Brasil',
      'Estados Unidos', 
      'Portugal',
      'Canadá'
    ];
    
    for (final country in implementedCountries) {
      _testCountry(country);
      debugPrint('');
    }
    
    // Testar países sem dados estruturados
    _testCountryWithoutData('França');
    _testCountryWithoutData('Japão');
  }
  
  static void _testCountry(String countryName) {
    debugPrint('🏳️ Testando: $countryName');
    
    // Obter código do país
    final countryCode = WorldLocationsData.getCountryCode(countryName);
    debugPrint('   Código: $countryCode');
    
    if (countryCode == null) {
      debugPrint('   ❌ Código não encontrado!');
      return;
    }
    
    // Verificar se tem dados estruturados
    final hasStructuredData = LocationDataProvider.hasStructuredData(countryCode);
    debugPrint('   Dados estruturados: ${hasStructuredData ? "✅ Sim" : "❌ Não"}');
    
    if (!hasStructuredData) {
      return;
    }
    
    // Obter dados de localização
    final locationData = LocationDataProvider.getLocationData(countryCode);
    if (locationData == null) {
      debugPrint('   ❌ Erro ao obter dados de localização!');
      return;
    }
    
    debugPrint('   Label de estado: ${locationData.stateLabel}');
    debugPrint('   Usa siglas: ${locationData.useStateAbbreviation ? "Sim" : "Não"}');
    
    // Obter estados
    final states = locationData.getStates();
    debugPrint('   Estados/Províncias: ${states.length}');
    
    if (states.isNotEmpty) {
      // Testar primeiro estado
      final firstState = states.first;
      debugPrint('   Primeiro estado: $firstState');
      
      // Obter cidades do primeiro estado
      final cities = locationData.getCitiesForState(firstState);
      debugPrint('   Cidades em $firstState: ${cities.length}');
      
      if (cities.isNotEmpty) {
        // Testar formatação
        final firstCity = cities.first;
        final formatted = locationData.formatLocation(firstCity, firstState);
        debugPrint('   Exemplo formatado: $formatted');
        
        // Testar sigla se aplicável
        if (locationData.useStateAbbreviation) {
          final abbr = locationData.getStateAbbreviation(firstState);
          debugPrint('   Sigla de $firstState: $abbr');
        }
      }
    }
  }
  
  static void _testCountryWithoutData(String countryName) {
    debugPrint('🏳️ Testando país sem dados: $countryName');
    
    final countryCode = WorldLocationsData.getCountryCode(countryName);
    debugPrint('   Código: ${countryCode ?? "Não mapeado"}');
    
    if (countryCode != null) {
      final hasStructuredData = LocationDataProvider.hasStructuredData(countryCode);
      debugPrint('   Dados estruturados: ${hasStructuredData ? "✅ Sim" : "❌ Não (esperado)"}');
    } else {
      debugPrint('   ✅ Será usado campo de texto livre');
    }
    
    debugPrint('');
  }
  
  /// Testa cenários específicos de uso
  static void testUsageScenarios() {
    debugPrint('🧪 TESTANDO CENÁRIOS DE USO');
    debugPrint('=' * 50);
    
    // Cenário 1: Usuário brasileiro
    debugPrint('Cenário 1: Usuário brasileiro');
    _simulateUserFlow('Brasil', 'São Paulo', 'Campinas');
    
    // Cenário 2: Usuário americano
    debugPrint('Cenário 2: Usuário americano');
    _simulateUserFlow('Estados Unidos', 'California', 'Los Angeles');
    
    // Cenário 3: Usuário português
    debugPrint('Cenário 3: Usuário português');
    _simulateUserFlow('Portugal', 'Lisboa', 'Lisboa');
    
    // Cenário 4: Usuário de país sem dados estruturados
    debugPrint('Cenário 4: Usuário francês (sem dados estruturados)');
    _simulateUserFlowFreeText('França', 'Paris');
  }
  
  static void _simulateUserFlow(String country, String state, String city) {
    final countryCode = WorldLocationsData.getCountryCode(country);
    if (countryCode == null) {
      debugPrint('   ❌ País não mapeado');
      return;
    }
    
    final locationData = LocationDataProvider.getLocationData(countryCode);
    if (locationData == null) {
      debugPrint('   ❌ Dados não encontrados');
      return;
    }
    
    debugPrint('   1. Selecionou país: $country');
    debugPrint('   2. Label de estado: ${locationData.stateLabel}');
    debugPrint('   3. Selecionou ${locationData.stateLabel.toLowerCase()}: $state');
    debugPrint('   4. Selecionou cidade: $city');
    
    final formatted = locationData.formatLocation(city, state);
    debugPrint('   ✅ Resultado final: $formatted');
    debugPrint('');
  }
  
  static void _simulateUserFlowFreeText(String country, String city) {
    debugPrint('   1. Selecionou país: $country');
    debugPrint('   2. Campo de texto livre aparece');
    debugPrint('   3. Digitou cidade: $city');
    debugPrint('   ✅ Resultado final: $city, $country');
    debugPrint('');
  }
  
  /// Testa performance do sistema
  static void testPerformance() {
    debugPrint('⚡ TESTANDO PERFORMANCE');
    debugPrint('=' * 50);
    
    final stopwatch = Stopwatch()..start();
    
    // Testar carregamento de todos os países
    final countries = WorldLocationsData.getCountryNames();
    debugPrint('Países disponíveis: ${countries.length}');
    
    // Testar carregamento de dados estruturados
    int structuredCount = 0;
    for (final country in countries) {
      final code = WorldLocationsData.getCountryCode(country);
      if (code != null && LocationDataProvider.hasStructuredData(code)) {
        structuredCount++;
      }
    }
    
    stopwatch.stop();
    
    debugPrint('Países com dados estruturados: $structuredCount');
    debugPrint('Tempo de execução: ${stopwatch.elapsedMilliseconds}ms');
    debugPrint('');
  }
}
