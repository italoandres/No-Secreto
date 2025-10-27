import 'package:flutter/foundation.dart';
import 'package:whatsapp_chat/utils/debug_utils.dart'; // ✅ IMPORT ADICIONADO

/// Gerencia erros relacionados ao carregamento de dados de localização
class LocationErrorHandler {
  /// Trata erro ao carregar dados de um país
  static void handleDataLoadError(String countryCode, dynamic error) {
    // Log erro para debugging
    safePrint(
        '❌ Erro ao carregar dados de localização de $countryCode: $error');

    // TODO: Adicionar analytics quando necessário
    // FirebaseAnalytics.instance.logEvent(
    //   name: 'location_data_error',
    //   parameters: {
    //     'country_code': countryCode,
    //     'error': error.toString(),
    //   },
    // );
  }

  /// Retorna mensagem de fallback amigável
  static String getFallbackMessage(String countryName) {
    return 'Não foi possível carregar as cidades de $countryName. '
        'Por favor, digite sua cidade manualmente.';
  }

  /// Verifica se um erro é crítico
  static bool isCriticalError(dynamic error) {
    // Erros de rede ou parsing são críticos
    return error is FormatException ||
        error is TypeError ||
        error.toString().contains('network');
  }

  /// Retorna mensagem de erro apropriada
  static String getErrorMessage(dynamic error) {
    if (error is FormatException) {
      return 'Erro ao processar dados de localização';
    } else if (error is TypeError) {
      return 'Erro ao carregar dados de localização';
    } else {
      return 'Erro inesperado ao carregar localização';
    }
  }
}