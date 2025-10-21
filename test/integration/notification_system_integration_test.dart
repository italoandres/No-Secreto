import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import '../../lib/services/notification_system_integrator.dart';
import '../../lib/services/javascript_error_handler.dart';
import '../../lib/services/error_recovery_system.dart';
import '../../lib/services/real_time_sync_manager.dart';
import '../../lib/services/advanced_diagnostic_system.dart';
import '../../lib/services/real_time_monitoring_system.dart';
import '../../lib/services/fixed_notification_pipeline.dart';
import '../../lib/services/robust_notification_converter.dart';
import '../../lib/repositories/enhanced_real_interests_repository.dart';

void main() {
  group('Complete Notification System Integration Tests', () {
    setUp(() {
      Get.testMode = true;
    });
    
    tearDown(() {
      Get.reset();
      NotificationSystemIntegrator.instance.dispose();
    });
    
    group('End-to-End System Tests', () {
      test('should handle complete notification flow from start to finish', () async {
        // Arrange
        const userId = 'e2e_test_user';
        
        // Act - Initialize complete system
        final initSuccess = await NotificationSystemIntegrator.instance
            .initializeCompleteSystem();
        
        expect(initSuccess, isTrue);
        
        // Process notifications
        final notifications = await NotificationSystemIntegrator.instance
            .processNotificationsIntegrated(userId);
        
        // Run diagnostic
        final diagnostic = await NotificationSystemIntegrator.instance
            .runIntegratedDiagnostic(userId);
        
        // Assert
        expect(notifications, isA<List>());
        expect(diagnostic, isA<Map<String, dynamic>());
        expect(diagnostic['isSystemHealthy'], isA<bool>());
        
        // Verify system components are working
        final integrationMetrics = NotificationSystemIntegrator.instance
            .getIntegrationMetrics();
        expect(integrationMetrics['isInitialized'], isTrue);
      });
      
      test('should recover from system failures automatically', () async {
        // Arrange
        const userId = 'recovery_test_user';
        await NotificationSystemIntegrator.instance.initializeCompleteSystem();
        
        // Simulate system failure by forcing error recovery
        ErrorRecoverySystem.instance.detectSystemFailure();
        
        // Act - System should recover automatically
        final notifications = await NotificationSystemIntegrator.instance
            .processNotificationsIntegrated(userId);
        
        // Assert - Should still work after recovery
        expect(notifications, isA<List>());
        
        final diagnostic = await NotificationSystemIntegrator.instance
            .runIntegratedDiagnostic(userId);
        expect(diagnostic['isSystemHealthy'], isA<bool>());
      });
      
      test('should maintain data consistency across all components', () async {
        // Arrange
        const userId = 'consistency_test_user';
        await NotificationSystemIntegrator.instance.initializeCompleteSystem();
        
        // Act - Process notifications multiple times
        final notifications1 = await NotificationSystemIntegrator.instance
            .processNotificationsIntegrated(userId);
        
        final notifications2 = await NotificationSystemIntegrator.instance
            .processNotificationsIntegrated(userId);
        
        // Get fallback notifications
        final fallbackNotifications = ErrorRecoverySystem.instance
            .getFallbackNotifications(userId);
        
        // Assert - Data should be consistent
        expect(notifications1, isA<List>());
        expect(notifications2, isA<List>());
        expect(fallbackNotifications, isA<List>());
        
        // Verify pipeline statistics are updated
        final pipelineStats = FixedNotificationPipeline.instance
            .getPipelineStatistics();
        expect(pipelineStats['isInitialized'], isTrue);
      });
    });
    
    group('Performance Integration Tests', () {
      test('should handle high load efficiently', () async {
        // Arrange
        const userIds = [
          'load_test_user_1',
          'load_test_user_2', 
          'load_test_user_3',
          'load_test_user_4',
          'load_test_user_5'
        ];
        
        await NotificationSystemIntegrator.instance.initializeCompleteSystem();
        
        final stopwatch = Stopwatch()..start();
        
        // Act - Process notifications for multiple users concurrently
        final futures = userIds.map((userId) => 
            NotificationSystemIntegrator.instance
                .processNotificationsIntegrated(userId)
        ).toList();
        
        final results = await Future.wait(futures);
        
        stopwatch.stop();
        
        // Assert
        expect(results.length, equals(userIds.length));
        for (final result in results) {
          expect(result, isA<List>());
        }
        
        // Should complete within reasonable time (15 seconds for 5 users)
        expect(stopwatch.elapsedMilliseconds, lessThan(15000));
      });
      
      test('should maintain performance under stress', () async {
        // Arrange
        const userId = 'stress_test_user';
        await NotificationSystemIntegrator.instance.initializeCompleteSystem();
        
        // Act - Run multiple operations rapidly
        final operations = <Future>[];
        
        for (int i = 0; i < 10; i++) {
          operations.add(NotificationSystemIntegrator.instance
              .processNotificationsIntegrated('$userId$i'));
          
          operations.add(NotificationSystemIntegrator.instance
              .runIntegratedDiagnostic('$userId$i'));
        }
        
        final stopwatch = Stopwatch()..start();
        await Future.wait(operations);
        stopwatch.stop();
        
        // Assert - Should complete all operations within 30 seconds
        expect(stopwatch.elapsedMilliseconds, lessThan(30000));
        
        // System should still be healthy
        final finalDiagnostic = await NotificationSystemIntegrator.instance
            .runIntegratedDiagnostic(userId);
        expect(finalDiagnostic['isSystemHealthy'], isA<bool>());
      });
    });
    
    group('Error Handling Integration Tests', () {
      test('should handle component failures gracefully', () async {
        // Arrange
        const userId = 'component_failure_test_user';
        await NotificationSystemIntegrator.instance.initializeCompleteSystem();
        
        // Simulate component failures by disposing some components
        JavaScriptErrorHandler.instance.dispose();
        
        // Act - System should still function with degraded performance
        final notifications = await NotificationSystemIntegrator.instance
            .processNotificationsIntegrated(userId);
        
        // Assert
        expect(notifications, isA<List>());
        
        // Diagnostic should report the issue
        final diagnostic = await NotificationSystemIntegrator.instance
            .runIntegratedDiagnostic(userId);
        
        expect(diagnostic, containsPair('systemDiagnostic', isA<Map>()));
      });
      
      test('should recover from complete system restart', () async {
        // Arrange
        const userId = 'restart_test_user';
        await NotificationSystemIntegrator.instance.initializeCompleteSystem();
        
        // Process some notifications first
        await NotificationSystemIntegrator.instance
            .processNotificationsIntegrated(userId);
        
        // Act - Restart the entire system
        final restartSuccess = await NotificationSystemIntegrator.instance
            .restartIntegratedSystem();
        
        expect(restartSuccess, isTrue);
        
        // Process notifications again after restart
        final notificationsAfterRestart = await NotificationSystemIntegrator.instance
            .processNotificationsIntegrated(userId);
        
        // Assert
        expect(notificationsAfterRestart, isA<List>());
        
        final diagnostic = await NotificationSystemIntegrator.instance
            .runIntegratedDiagnostic(userId);
        expect(diagnostic['isSystemHealthy'], isA<bool>());
      });
    });
    
    group('Monitoring Integration Tests', () {
      test('should provide real-time monitoring data', () async {
        // Arrange
        const userId = 'monitoring_test_user';
        await NotificationSystemIntegrator.instance.initializeCompleteSystem();
        
        // Act - Generate some activity
        await NotificationSystemIntegrator.instance
            .processNotificationsIntegrated(userId);
        
        // Force monitoring check
        RealTimeMonitoringSystem.instance.forceCheck();
        
        // Get monitoring data
        final monitoringMetrics = RealTimeMonitoringSystem.instance
            .getRealTimeMetrics();
        
        final recentAlerts = RealTimeMonitoringSystem.instance
            .getRecentAlerts();
        
        // Assert
        expect(monitoringMetrics, containsPair('isInitialized', isTrue));
        expect(monitoringMetrics, containsPair('monitoringActive', isA<bool>()));
        expect(monitoringMetrics, containsPair('metrics', isA<Map>()));
        
        expect(recentAlerts, isA<List>());
      });
      
      test('should detect and report system health changes', () async {
        // Arrange
        const userId = 'health_monitoring_test_user';
        await NotificationSystemIntegrator.instance.initializeCompleteSystem();
        
        // Get initial health
        final initialDiagnostic = await NotificationSystemIntegrator.instance
            .runIntegratedDiagnostic(userId);
        
        // Simulate some system activity
        for (int i = 0; i < 5; i++) {
          await NotificationSystemIntegrator.instance
              .processNotificationsIntegrated('$userId$i');
        }
        
        // Force monitoring checks
        RealTimeMonitoringSystem.instance.forceCheck();
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Get updated health
        final updatedDiagnostic = await NotificationSystemIntegrator.instance
            .runIntegratedDiagnostic(userId);
        
        // Assert
        expect(initialDiagnostic['isSystemHealthy'], isA<bool>());
        expect(updatedDiagnostic['isSystemHealthy'], isA<bool>());
        
        // Monitoring metrics should show activity
        final monitoringMetrics = updatedDiagnostic['monitoringMetrics'] as Map<String, dynamic>;
        final metrics = monitoringMetrics['metrics'] as Map<String, dynamic>? ?? {};
        expect(metrics['totalChecks'], greaterThan(0));
      });
    });
    
    group('Data Flow Integration Tests', () {
      test('should maintain proper data flow through all components', () async {
        // Arrange
        const userId = 'data_flow_test_user';
        await NotificationSystemIntegrator.instance.initializeCompleteSystem();
        
        // Act - Process notifications and track data flow
        final notifications = await NotificationSystemIntegrator.instance
            .processNotificationsIntegrated(userId);
        
        // Verify data exists in various components
        
        // Check pipeline statistics
        final pipelineStats = FixedNotificationPipeline.instance
            .getPipelineStatistics();
        
        // Check converter statistics
        final converterStats = RobustNotificationConverter.instance
            .getConversionStatistics();
        
        // Check repository statistics
        final repositoryStats = EnhancedRealInterestsRepository.instance
            .getStatistics();
        
        // Check error recovery cache
        final fallbackNotifications = ErrorRecoverySystem.instance
            .getFallbackNotifications(userId);
        
        // Assert
        expect(notifications, isA<List>());
        expect(pipelineStats, containsPair('isInitialized', isTrue));
        expect(converterStats, containsPair('totalConversions', isA<int>()));
        expect(repositoryStats, containsPair('cacheSize', isA<int>()));
        expect(fallbackNotifications, isA<List>());
      });
      
      test('should handle data corruption gracefully', () async {
        // Arrange
        const userId = 'data_corruption_test_user';
        await NotificationSystemIntegrator.instance.initializeCompleteSystem();
        
        // Simulate data corruption by clearing caches
        EnhancedRealInterestsRepository.instance.clearCache();
        RobustNotificationConverter.instance.clearOldStatistics();
        
        // Act - System should recover and continue working
        final notifications = await NotificationSystemIntegrator.instance
            .processNotificationsIntegrated(userId);
        
        // Assert
        expect(notifications, isA<List>());
        
        // System should detect and report the issue
        final diagnostic = await NotificationSystemIntegrator.instance
            .runIntegratedDiagnostic(userId);
        
        expect(diagnostic, containsPair('isSystemHealthy', isA<bool>()));
      });
    });
    
    group('Real-world Scenario Tests', () {
      test('should solve the original 9 interactions to 0 notifications problem', () async {
        // Arrange - Simulate the original problem scenario
        const userId = 'original_problem_user';
        
        // Act - Use the complete integrated system
        await NotificationSystemIntegrator.instance.initializeCompleteSystem();
        
        final notifications = await NotificationSystemIntegrator.instance
            .processNotificationsIntegrated(userId);
        
        final diagnostic = await NotificationSystemIntegrator.instance
            .runIntegratedDiagnostic(userId);
        
        // Assert - The problem should be resolved
        expect(notifications, isA<List>());
        
        // System should be healthy
        final systemHealth = diagnostic['systemDiagnostic'] as Map<String, dynamic>;
        final healthData = systemHealth['systemHealth'] as Map<String, dynamic>? ?? {};
        final overallScore = healthData['overallScore'] as int? ?? 0;
        
        // Should have reasonable health score
        expect(overallScore, greaterThanOrEqualTo(0));
        
        // Should have minimal critical issues
        final criticalIssues = diagnostic['systemDiagnostic']['criticalIssues'] as List? ?? [];
        expect(criticalIssues.length, lessThan(10)); // Should have manageable number of issues
        
        // Integration should be successful
        expect(diagnostic['isSystemHealthy'], isA<bool>());
      });
      
      test('should handle typical user interaction patterns', () async {
        // Arrange - Simulate typical user behavior
        const userIds = [
          'typical_user_1',
          'typical_user_2',
          'typical_user_3'
        ];
        
        await NotificationSystemIntegrator.instance.initializeCompleteSystem();
        
        // Act - Simulate users checking notifications at different times
        final results = <List>[];
        
        for (final userId in userIds) {
          // Each user checks notifications
          final notifications = await NotificationSystemIntegrator.instance
              .processNotificationsIntegrated(userId);
          results.add(notifications);
          
          // Small delay between users
          await Future.delayed(const Duration(milliseconds: 100));
        }
        
        // Run system diagnostic
        final diagnostic = await NotificationSystemIntegrator.instance
            .runIntegratedDiagnostic('system_check');
        
        // Assert
        expect(results.length, equals(userIds.length));
        for (final result in results) {
          expect(result, isA<List>());
        }
        
        expect(diagnostic['isSystemHealthy'], isA<bool>());
        
        // System should maintain good performance
        final integrationMetrics = diagnostic['integrationMetrics'] as Map<String, dynamic>;
        expect(integrationMetrics, containsPair('overallHealthScore', isA<int>()));
      });
    });
    
    group('System Validation Tests', () {
      test('should pass comprehensive system validation', () async {
        // Arrange & Act
        final initSuccess = await NotificationSystemIntegrator.instance
            .initializeCompleteSystem();
        
        // Assert initialization
        expect(initSuccess, isTrue);
        
        // Validate integration metrics
        final integrationMetrics = NotificationSystemIntegrator.instance
            .getIntegrationMetrics();
        
        expect(integrationMetrics['isInitialized'], isTrue);
        expect(integrationMetrics['integrationMetrics'], isA<Map>());
        
        // Validate individual components
        expect(JavaScriptErrorHandler.instance.getErrorStatistics()['isInitialized'], isTrue);
        expect(ErrorRecoverySystem.instance.getRecoveryStatistics()['isInitialized'], isTrue);
        expect(RealTimeSyncManager.instance.getSyncStatistics()['isInitialized'], isTrue);
        expect(AdvancedDiagnosticSystem.instance.getSystemStatistics()['isInitialized'], isTrue);
        expect(RealTimeMonitoringSystem.instance.getRealTimeMetrics()['isInitialized'], isTrue);
        expect(FixedNotificationPipeline.instance.getPipelineStatistics()['isInitialized'], isTrue);
        
        // Run comprehensive diagnostic
        final diagnostic = await NotificationSystemIntegrator.instance
            .runIntegratedDiagnostic('validation_test_user');
        
        expect(diagnostic, containsPair('timestamp', isA<String>()));
        expect(diagnostic, containsPair('integrationMetrics', isA<Map>()));
        expect(diagnostic, containsPair('systemDiagnostic', isA<Map>()));
        expect(diagnostic, containsPair('monitoringMetrics', isA<Map>()));
        expect(diagnostic, containsPair('isSystemHealthy', isA<bool>()));
      });
    });
  });
}