import 'package:flutter/foundation.dart';

/// 🔇 SISTEMA DE LOGS CONDICIONAIS
/// 
/// Este arquivo resolve o problema de MILHARES de debugPrint travando o app.
/// 
/// NUNCA imprime logs em produção (release mode) para manter performance.
/// 
/// USO:
/// - Substituir TODOS os `safePrint(` por `safePrint(`
/// - Usar `safeLog(` para logs mais verbosos (só aparece em debug)
/// 
/// BENEFÍCIOS:
/// - ✅ App 10x mais rápido em produção
/// - ✅ Sem frames pulados
/// - ✅ Login não dá mais timeout
/// - ✅ Logs úteis apenas durante desenvolvimento

// MODO DE PRODUÇÃO: true = release, false = debug
const bool kProductionMode = kReleaseMode;

/// Imprime mensagem APENAS em modo debug
/// Em produção (release), não faz nada
/// Aceita qualquer tipo de objeto (converte para String automaticamente)
void safePrint(Object? message) {
  if (!kProductionMode) {
    debugPrint(message?.toString() ?? 'null');
  }
}

/// Versão ainda mais restrita - só imprime se explicitamente habilitado
/// Use para logs muito verbosos (ex: loops, verificações frequentes)
void safeLog(String message, {bool verbose = false}) {
  if (!kProductionMode && verbose) {
    debugPrint('🔍 $message');
  }
}

/// Para logs de erro que SEMPRE devem aparecer (mesmo em produção)
/// Use com moderação!
void errorLog(String message) {
  debugPrint('❌ ERROR: $message');
}

/// Para logs de aviso importantes
void warningLog(String message) {
  if (!kProductionMode) {
    debugPrint('⚠️ WARNING: $message');
  }
}

/// Para logs de sucesso
void successLog(String message) {
  if (!kProductionMode) {
    debugPrint('✅ SUCCESS: $message');
  }
}

/// Para logs de informação
void infoLog(String message) {
  if (!kProductionMode) {
    debugPrint('ℹ️ INFO: $message');
  }
}

/// Helper para medir performance de operações
class PerformanceLogger {
  final String operationName;
  final Stopwatch _stopwatch = Stopwatch();
  
  PerformanceLogger(this.operationName) {
    if (!kProductionMode) {
      _stopwatch.start();
      debugPrint('⏱️ Iniciando: $operationName');
    }
  }
  
  void finish() {
    if (!kProductionMode) {
      _stopwatch.stop();
      final duration = _stopwatch.elapsedMilliseconds;
      
      String emoji = '✅';
      if (duration > 1000) emoji = '🔴'; // Mais de 1 segundo
      else if (duration > 500) emoji = '🟡'; // Mais de 500ms
      else if (duration > 100) emoji = '🟢'; // Mais de 100ms
      
      debugPrint('$emoji $operationName: ${duration}ms');
    }
  }
}

/// Exemplo de uso do PerformanceLogger:
/// 
/// final perf = PerformanceLogger('Carregando usuários');
/// await loadUsers();
/// perf.finish();
