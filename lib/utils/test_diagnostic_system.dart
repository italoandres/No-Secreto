import 'dart:async';
import 'dart:math';
import '../services/diagnostic_logger.dart';
import '../services/unified_notification_interface.dart';
import '../services/data_recovery_service.dart';
import '../services/offline_sync_manager.dart';
import '../services/legacy_system_migrator.dart';
import '../views/notification_diagnostic_panel.dart';
import '../utils/enhanced_logger.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Utilitário para testar o sistema de diagnóstico
class DiagnosticSystemTester {
  static final DiagnosticLogger _logger = DiagnosticLogger();
  static final Random _random = Random();
  
  /// Inicializa o sistema de diagnóstico
  static Future<void> initializeDiagnosticSystem() async {
    try {
      EnhancedLogger.log('🚀 [DIAGNOSTIC_TEST] Inicializando sistema de diagnóstico...');
      
      // Inicializa o logger
      await _logger.initialize();
      
      // Registra log de inicialização
      _logger.info(
        DiagnosticLogCategory.system,
        'Sistema de diagnóstico inicializado com sucesso',
        data: {
          'timestamp': DateTime.now().toIso8601String(),
          'version': '1.0.0',
          'features': ['logging', 'real-time', 'filtering', 'export'],
        },
      );
      
      EnhancedLogger.log('✅ [DIAGNOSTIC_TEST] Sistema inicializado com sucesso');
      
    } catch (e, stackTrace) {
      _logger.critical(
        DiagnosticLogCategory.system,
        'Falha na inicialização do sistema de diagnóstico',
        data: {'error': e.toString()},
        stackTrace: stackTrace.toString(),
      );
      
      EnhancedLogger.log('❌ [DIAGNOSTIC_TEST] Erro na inicialização: $e');
      rethrow;
    }
  }
  
  /// Abre o painel de diagnóstico
  static void openDiagnosticPanel(String userId) {
    try {
      _logger.info(
        DiagnosticLogCategory.user,
        'Abrindo painel de diagnóstico',
        userId: userId,
        data: {'action': 'open_panel'},
      );
      
      Get.to(() => NotificationDiagnosticPanel(userId: userId));
      
    } catch (e) {
      _logger.error(
        DiagnosticLogCategory.system,
        'Erro ao abrir painel de diagnóstico',
        userId: userId,
        data: {'error': e.toString()},
      );
    }
  }
  
  /// Gera logs de teste para demonstração
  static Future<void> generateTestLogs(String userId, {int count = 50}) async {
    EnhancedLogger.log('🧪 [DIAGNOSTIC_TEST] Gerando $count logs de teste...');
    
    final categories = DiagnosticLogCategory.values;
    final levels = DiagnosticLogLevel.values;
    
    final messages = [
      'Sistema funcionando normalmente',
      'Notificação processada com sucesso',
      'Sincronização concluída',
      'Cache atualizado',
      'Dados recuperados do backup',
      'Migração de dados iniciada',
      'Performance otimizada',
      'Usuário autenticado',
      'Erro de conexão temporário',
      'Falha na validação de dados',
      'Timeout na operação',
      'Recurso não encontrado',
      'Permissão negada',
      'Limite de taxa excedido',
      'Operação cancelada pelo usuário',
    ];
    
    for (int i = 0; i < count; i++) {
      final category = categories[_random.nextInt(categories.length)];
      final level = levels[_random.nextInt(levels.length)];
      final message = messages[_random.nextInt(messages.length)];
      
      final data = <String, dynamic>{
        'testId': 'test_$i',
        'iteration': i + 1,
        'randomValue': _random.nextDouble(),
      };
      
      // Adiciona dados específicos baseados na categoria
      switch (category) {
        case DiagnosticLogCategory.notification:
          data.addAll({
            'notificationId': 'notif_${_random.nextInt(1000)}',
            'type': ['interest', 'match', 'message'][_random.nextInt(3)],
          });
          break;
        case DiagnosticLogCategory.sync:
          data.addAll({
            'syncId': 'sync_${_random.nextInt(1000)}',
            'itemsProcessed': _random.nextInt(100),
          });
          break;
        case DiagnosticLogCategory.performance:
          data.addAll({
            'operationTime': _random.nextInt(5000),
            'memoryUsage': _random.nextInt(100),
          });
          break;
        default:
          break;
      }
      
      // Adiciona stack trace para logs de erro
      String? stackTrace;
      if (level == DiagnosticLogLevel.error || level == DiagnosticLogLevel.critical) {
        stackTrace = 'Stack trace simulado para teste\\n'
                    'at TestFunction.method() (test_file.dart:${_random.nextInt(100)})\\n'
                    'at TestClass.process() (test_class.dart:${_random.nextInt(50)})';
      }
      
      // Simula tempo de execução para algumas operações
      Duration? executionTime;
      if (_random.nextBool()) {
        executionTime = Duration(milliseconds: _random.nextInt(2000));
      }
      
      _logger.log(
        level,
        category,
        '$message (teste $i)',
        userId: _random.nextBool() ? userId : null,
        data: data,
        stackTrace: stackTrace,
        executionTime: executionTime,
      );
      
      // Pequena pausa para simular logs em tempo real
      if (i % 10 == 0) {
        await Future.delayed(Duration(milliseconds: 100));
      }
    }
    
    EnhancedLogger.log('✅ [DIAGNOSTIC_TEST] $count logs de teste gerados');
  }
  
  /// Simula operações do sistema para gerar logs realistas
  static Future<void> simulateSystemOperations(String userId) async {
    EnhancedLogger.log('🎭 [DIAGNOSTIC_TEST] Simulando operações do sistema...');
    
    // Simula carregamento de notificações
    await _simulateNotificationLoad(userId);
    
    // Simula sincronização
    await _simulateSync(userId);
    
    // Simula recuperação de dados
    await _simulateDataRecovery(userId);
    
    // Simula migração
    await _simulateMigration(userId);
    
    // Simula alguns erros
    await _simulateErrors(userId);
    
    EnhancedLogger.log('✅ [DIAGNOSTIC_TEST] Simulação concluída');
  }
  
  static Future<void> _simulateNotificationLoad(String userId) async {
    _logger.info(
      DiagnosticLogCategory.notification,
      'Iniciando carregamento de notificações',
      userId: userId,
    );
    
    await Future.delayed(Duration(milliseconds: 500));
    
    final notificationCount = _random.nextInt(20) + 5;
    
    _logger.info(
      DiagnosticLogCategory.notification,
      'Notificações carregadas com sucesso',
      userId: userId,
      data: {
        'count': notificationCount,
        'source': 'cache',
      },
      executionTime: Duration(milliseconds: 500),
    );
  }
  
  static Future<void> _simulateSync(String userId) async {
    _logger.info(
      DiagnosticLogCategory.sync,
      'Iniciando sincronização',
      userId: userId,
    );
    
    await Future.delayed(Duration(milliseconds: 800));
    
    if (_random.nextBool()) {
      _logger.info(
        DiagnosticLogCategory.sync,
        'Sincronização concluída',
        userId: userId,
        data: {
          'itemsSynced': _random.nextInt(50),
          'conflicts': 0,
        },
        executionTime: Duration(milliseconds: 800),
      );
    } else {
      _logger.warning(
        DiagnosticLogCategory.sync,
        'Sincronização parcial - alguns itens falharam',
        userId: userId,
        data: {
          'itemsSynced': _random.nextInt(30),
          'itemsFailed': _random.nextInt(5),
        },
        executionTime: Duration(milliseconds: 800),
      );
    }
  }
  
  static Future<void> _simulateDataRecovery(String userId) async {
    _logger.info(
      DiagnosticLogCategory.recovery,
      'Escaneando fontes de recuperação',
      userId: userId,
    );
    
    await Future.delayed(Duration(milliseconds: 300));
    
    final sourcesFound = _random.nextInt(3);
    
    _logger.info(
      DiagnosticLogCategory.recovery,
      'Escaneamento de recuperação concluído',
      userId: userId,
      data: {
        'sourcesFound': sourcesFound,
        'dataAvailable': sourcesFound > 0,
      },
      executionTime: Duration(milliseconds: 300),
    );
  }
  
  static Future<void> _simulateMigration(String userId) async {
    if (_random.nextBool()) {
      _logger.info(
        DiagnosticLogCategory.migration,
        'Verificando necessidade de migração',
        userId: userId,
      );
      
      await Future.delayed(Duration(milliseconds: 200));
      
      _logger.info(
        DiagnosticLogCategory.migration,
        'Nenhuma migração necessária',
        userId: userId,
        data: {'status': 'up_to_date'},
        executionTime: Duration(milliseconds: 200),
      );
    }
  }
  
  static Future<void> _simulateErrors(String userId) async {
    // Simula alguns erros ocasionais
    if (_random.nextInt(10) < 3) {
      _logger.error(
        DiagnosticLogCategory.sync,
        'Falha temporária na conexão',
        userId: userId,
        data: {
          'errorCode': 'NETWORK_TIMEOUT',
          'retryAttempt': 1,
        },
      );
    }
    
    if (_random.nextInt(10) < 2) {
      _logger.warning(
        DiagnosticLogCategory.performance,
        'Operação lenta detectada',
        userId: userId,
        data: {
          'operation': 'data_load',
          'duration': 3500,
          'threshold': 2000,
        },
      );
    }
    
    if (_random.nextInt(20) < 1) {
      _logger.critical(
        DiagnosticLogCategory.system,
        'Erro crítico no sistema',
        userId: userId,
        data: {
          'component': 'notification_processor',
          'impact': 'high',
        },
        stackTrace: 'Critical error stack trace\\nat CriticalComponent.process()\\nat SystemManager.run()',
      );
    }
  }
  
  /// Testa todas as funcionalidades do sistema de diagnóstico
  static Future<void> runComprehensiveTest(String userId) async {
    EnhancedLogger.log('🔬 [DIAGNOSTIC_TEST] Executando teste abrangente...');
    
    try {
      // 1. Inicializa o sistema
      await initializeDiagnosticSystem();
      
      // 2. Gera logs de teste
      await generateTestLogs(userId, count: 30);
      
      // 3. Simula operações do sistema
      await simulateSystemOperations(userId);
      
      // 4. Testa estatísticas
      final stats = _logger.getLogStatistics();
      _logger.info(
        DiagnosticLogCategory.system,
        'Estatísticas do sistema coletadas',
        data: stats,
      );
      
      // 5. Testa exportação
      final exportData = _logger.exportLogsAsJson();
      _logger.info(
        DiagnosticLogCategory.system,
        'Dados exportados com sucesso',
        data: {
          'exportSize': exportData.length,
          'format': 'json',
        },
      );
      
      EnhancedLogger.log('✅ [DIAGNOSTIC_TEST] Teste abrangente concluído com sucesso');
      
      // Mostra notificação de sucesso
      Get.snackbar(
        'Teste Concluído',
        'Sistema de diagnóstico testado com sucesso!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
      
    } catch (e, stackTrace) {
      _logger.critical(
        DiagnosticLogCategory.system,
        'Falha no teste abrangente',
        data: {'error': e.toString()},
        stackTrace: stackTrace.toString(),
      );
      
      EnhancedLogger.log('❌ [DIAGNOSTIC_TEST] Falha no teste: $e');
      
      Get.snackbar(
        'Erro no Teste',
        'Falha ao executar teste: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 5),
      );
    }
  }
  
  /// Limpa todos os logs de teste
  static void clearTestLogs() {
    _logger.clearAllLogs();
    
    EnhancedLogger.log('🧹 [DIAGNOSTIC_TEST] Logs de teste limpos');
    
    Get.snackbar(
      'Logs Limpos',
      'Todos os logs de teste foram removidos',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }
  
  /// Cria um botão de teste rápido para desenvolvimento
  static Widget createQuickTestButton(String userId) {
    return FloatingActionButton.extended(
      onPressed: () => runComprehensiveTest(userId),
      icon: Icon(Icons.bug_report),
      label: Text('Testar Diagnóstico'),
      backgroundColor: Colors.purple,
    );
  }
  
  /// Cria um widget de controle de teste
  static Widget createTestControlWidget(String userId) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Controles de Teste - Sistema de Diagnóstico',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => runComprehensiveTest(userId),
                    icon: Icon(Icons.play_arrow),
                    label: Text('Teste Completo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => generateTestLogs(userId),
                    icon: Icon(Icons.add),
                    label: Text('Gerar Logs'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => openDiagnosticPanel(userId),
                    icon: Icon(Icons.dashboard),
                    label: Text('Abrir Painel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: clearTestLogs,
                    icon: Icon(Icons.clear),
                    label: Text('Limpar Logs'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}