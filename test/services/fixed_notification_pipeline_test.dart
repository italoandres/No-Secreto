import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import '../../lib/services/fixed_notification_pipeline.dart';
import '../../lib/services/javascript_error_handler.dart';
import '../../lib/services/error_recovery_system.dart';
import '../../lib/services/real_time_sync_manager.dart';
import '../../lib/controllers/matches_controller.dart';

void main() {
  group('Fixed Notification Pipeline Tests', () {
    late FixedNotificationPipeline pipeline;
    
    setUp(() {
      pipeline = FixedNotificationPipeline.instance;
      
      // Mock GetX controller
      Get.testMode = true;
      Get.put(MatchesController());
    });
    
    tearDown(() {
      Get.reset();
    });
    
    test('should initialize pipeline correctly', () {
      // Act
      pipeline.initialize();
      
      // Assert
      final stats = pipeline.getPipelineStatistics();
      expect(stats['isInitialized'], isTrue);
    });
    
    test('should process interactions robustly', () async {
      // Arrange
      pipeline.initialize();
      const userId = 'test_user_123';
      
      // Act
      final notifications = await pipeline.processInteractionsRobustly(userId);
      
      // Assert
      expect(notifications, isNotNull);
      expect(notifications, isA<List>());
    });
    
    test('should handle empty interactions gracefully', () async {
      // Arrange
      pipeline.initialize();
      const userId = 'user_with_no_interactions';
      
      // Act
      final notifications = await pipeline.processInteractionsRobustly(userId);
      
      // Assert
      expect(notifications, isEmpty);
    });
    
    test('should provide processing statistics', () {
      // Act
      final stats = pipeline.getPipelineStatistics();
      
      // Assert
      expect(stats, containsKey('isInitialized'));
      expect(stats, containsKey('isProcessing'));
      expect(stats, containsKey('userCacheSize'));
      expect(stats, containsKey('timestamp'));
    });
    
    test('should handle concurrent processing requests', () async {
      // Arrange
      pipeline.initialize();
      const userId = 'test_user_concurrent';
      
      // Act
      final future1 = pipeline.processInteractionsRobustly(userId);
      final future2 = pipeline.processInteractionsRobustly(userId);
      
      final results = await Future.wait([future1, future2]);
      
      // Assert
      expect(results[0], isNotNull);
      expect(results[1], isNotNull);
    });
    
    test('should reset pipeline correctly', () {
      // Arrange
      pipeline.initialize();
      
      // Act
      pipeline.reset();
      
      // Assert
      final stats = pipeline.getPipelineStatistics();
      expect(stats['userCacheSize'], equals(0));
      expect(stats['isProcessing'], isFalse);
    });
  });
}