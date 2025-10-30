import '../models/storie_file_model.dart';
import './context_validator.dart';
import './context_log_analyzer.dart';
import './context_utils_test.dart';
import './context_isolation_tests.dart';

// Validação de contexto
export 'context_validator.dart';

// Filtro de stories por contexto
export 'story_context_filter.dart';

// Debug e logging de contexto
export 'context_debug.dart';

// Análise de logs de contexto
export 'context_log_analyzer.dart';

// Testes das utilidades (apenas para desenvolvimento)
export 'context_utils_test.dart';

// Testes de isolamento de contexto
export 'context_isolation_tests.dart';

/// Classe principal para acesso às utilidades de contexto
///
/// Esta classe fornece uma interface unificada para acessar
/// todas as funcionalidades de contexto.
class ContextUtils {
  /// Valida um contexto
  static bool isValid(String? contexto) {
    return ContextValidator.isValidContext(contexto);
  }

  /// Normaliza um contexto
  static String normalize(String? contexto) {
    return ContextValidator.normalizeContext(contexto);
  }

  /// Obtém a coleção para um contexto
  static String getCollection(String contexto) {
    return ContextValidator.getCollectionForContext(contexto);
  }

  /// Filtra stories por contexto
  static List<T> filter<T>(
      List<T> items, String context, bool Function(T, String) validator) {
    return items.where((item) => validator(item, context)).toList();
  }

  /// Executa testes das utilidades
  static void runTests() {
    ContextUtilsTest.runAllTests();
  }

  /// Simula vazamento de contexto para testes
  static void simulateLeak() {
    ContextUtilsTest.simulateContextLeak();
  }

  /// Analisa uma lista de stories e gera relatório
  static Map<String, dynamic> analyzeStories(
      List<StorieFileModel> stories, String expectedContext) {
    return ContextLogAnalyzer.analyzeStories(stories, expectedContext);
  }

  /// Gera relatório de saúde do sistema
  static Map<String, dynamic> generateHealthReport() {
    return ContextLogAnalyzer.generateHealthReport();
  }

  /// Executa testes do sistema
  static Map<String, dynamic> runSystemTests() {
    return ContextLogAnalyzer.runSystemTests();
  }

  /// Imprime relatório formatado
  static void printReport(Map<String, dynamic> report) {
    ContextLogAnalyzer.printReport(report);
  }

  /// Executa testes completos de isolamento de contexto
  static Future<Map<String, dynamic>> runIsolationTests() async {
    return await ContextIsolationTests.runAllTests();
  }

  /// Imprime relatório de testes de isolamento
  static void printTestReport(Map<String, dynamic> report) {
    ContextIsolationTests.printTestReport(report);
  }
}
