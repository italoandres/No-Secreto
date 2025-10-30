import 'package:whatsapp_chat/utils/debug_utils.dart';

/// Configurações e utilitários para debug de contexto
///
/// Esta classe centraliza as configurações de debug e fornece
/// métodos padronizados para logging de operações de contexto.
class ContextDebug {
  /// Flag para habilitar logs detalhados de contexto
  static const bool ENABLE_CONTEXT_LOGS = true;

  /// Flag para validação rigorosa de contexto
  static const bool VALIDATE_CONTEXT_STRICT = true;

  /// Flag para filtrar automaticamente contextos inválidos
  static const bool FILTER_INVALID_CONTEXTS = true;

  /// Flag para detectar vazamentos de contexto
  static const bool DETECT_CONTEXT_LEAKS = true;

  /// Flag para logs de performance de consultas
  static const bool LOG_QUERY_PERFORMANCE = true;

  /// Prefixos para diferentes tipos de log
  static const String _PREFIX_LOAD = '📥 CONTEXT_LOAD';
  static const String _PREFIX_FILTER = '🔍 CONTEXT_FILTER';
  static const String _PREFIX_VALIDATE = '✅ CONTEXT_VALIDATE';
  static const String _PREFIX_ERROR = '❌ CONTEXT_ERROR';
  static const String _PREFIX_LEAK = '🚨 CONTEXT_LEAK';
  static const String _PREFIX_PERF = '⚡ CONTEXT_PERF';

  /// Log de carregamento de stories por contexto
  ///
  /// [context] - O contexto sendo carregado
  /// [collection] - A coleção sendo consultada
  /// [count] - Número de stories carregados
  /// [operation] - Nome da operação
  static void logLoad(
      String context, String collection, int count, String operation) {
    if (!ENABLE_CONTEXT_LOGS) return;

    safePrint('$_PREFIX_LOAD: $operation');
    safePrint('   - Contexto: "$context"');
    safePrint('   - Coleção: "$collection"');
    safePrint('   - Stories carregados: $count');
  }

  /// Log de operação de filtro
  ///
  /// [context] - O contexto sendo filtrado
  /// [originalCount] - Número original de stories
  /// [filteredCount] - Número após filtro
  /// [operation] - Nome da operação
  static void logFilter(
      String context, int originalCount, int filteredCount, String operation) {
    if (!ENABLE_CONTEXT_LOGS) return;

    final removed = originalCount - filteredCount;
    safePrint('$_PREFIX_FILTER: $operation');
    safePrint('   - Contexto: "$context"');
    safePrint('   - Stories originais: $originalCount');
    safePrint('   - Stories após filtro: $filteredCount');
    if (removed > 0) {
      safePrint('   - ⚠️ Stories removidos: $removed');
    }
  }

  /// Log de validação de contexto
  ///
  /// [context] - O contexto sendo validado
  /// [isValid] - Se o contexto é válido
  /// [operation] - Nome da operação
  static void logValidation(String? context, bool isValid, String operation) {
    if (!ENABLE_CONTEXT_LOGS) return;

    if (isValid) {
      safePrint('$_PREFIX_VALIDATE: $operation - Contexto "$context" é válido');
    } else {
      safePrint('$_PREFIX_ERROR: $operation - Contexto "$context" é inválido');
    }
  }

  /// Log de vazamento de contexto detectado
  ///
  /// [expectedContext] - O contexto esperado
  /// [leaks] - Mapa de vazamentos detectados
  /// [operation] - Nome da operação
  static void logLeak(
      String expectedContext, Map<String, int> leaks, String operation) {
    if (!ENABLE_CONTEXT_LOGS || !DETECT_CONTEXT_LEAKS) return;

    safePrint(
        '$_PREFIX_LEAK: $operation - Vazamentos detectados para contexto "$expectedContext":');
    leaks.forEach((context, count) {
      safePrint('   - $count stories do contexto "$context"');
    });
  }

  /// Log de performance de consulta
  ///
  /// [operation] - Nome da operação
  /// [duration] - Duração da operação
  /// [context] - Contexto da consulta
  /// [count] - Número de resultados
  static void logPerformance(
      String operation, Duration duration, String context, int count) {
    if (!ENABLE_CONTEXT_LOGS || !LOG_QUERY_PERFORMANCE) return;

    safePrint('$_PREFIX_PERF: $operation');
    safePrint('   - Contexto: "$context"');
    safePrint('   - Duração: ${duration.inMilliseconds}ms');
    safePrint('   - Resultados: $count');
  }

  /// Log de erro crítico de contexto
  ///
  /// [operation] - Nome da operação
  /// [error] - Descrição do erro
  /// [context] - Contexto relacionado ao erro
  static void logCriticalError(
      String operation, String error, String? context) {
    safePrint('$_PREFIX_ERROR: ERRO CRÍTICO em $operation');
    safePrint('   - Contexto: "$context"');
    safePrint('   - Erro: $error');
  }

  /// Executa uma operação com medição de performance
  ///
  /// [operation] - Nome da operação
  /// [context] - Contexto da operação
  /// [function] - Função a ser executada
  /// Retorna o resultado da função
  static T measurePerformance<T>(
      String operation, String context, T Function() function) {
    if (!LOG_QUERY_PERFORMANCE) {
      return function();
    }

    final stopwatch = Stopwatch()..start();
    final result = function();
    stopwatch.stop();

    // Tentar determinar contagem se o resultado for uma lista
    int count = 0;
    if (result is List) {
      count = result.length;
    }

    logPerformance(operation, stopwatch.elapsed, context, count);
    return result;
  }

  /// Cria um resumo de debug para uma operação de contexto
  ///
  /// [operation] - Nome da operação
  /// [context] - Contexto da operação
  /// [data] - Dados adicionais para o resumo
  static void logSummary(
      String operation, String context, Map<String, dynamic> data) {
    if (!ENABLE_CONTEXT_LOGS) return;

    safePrint('📋 CONTEXT_SUMMARY: $operation');
    safePrint('   - Contexto: "$context"');
    data.forEach((key, value) {
      safePrint('   - $key: $value');
    });
  }
}