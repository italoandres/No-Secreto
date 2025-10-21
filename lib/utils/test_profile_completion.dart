import 'package:firebase_auth/firebase_auth.dart';
import '../utils/debug_profile_completion.dart';
import '../utils/enhanced_logger.dart';

/// Utilitário para testar a completude do perfil do usuário atual
class TestProfileCompletion {
  static const String _tag = 'TEST_PROFILE_COMPLETION';

  /// Testa o perfil do usuário atual
  static Future<void> testCurrentUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        EnhancedLogger.error('No user logged in', tag: _tag);
        return;
      }

      EnhancedLogger.info('Testing profile completion for current user', 
        tag: _tag,
        data: {'userId': user.uid}
      );

      await DebugProfileCompletion.debugProfileStatus(user.uid);

    } catch (e, stackTrace) {
      EnhancedLogger.error('Error testing profile completion', 
        tag: _tag,
        error: e,
        stackTrace: stackTrace
      );
    }
  }

  /// Força uma verificação manual das tarefas
  static Future<void> checkAllTasks() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        EnhancedLogger.error('No user logged in', tag: _tag);
        return;
      }

      final tasks = ['photos', 'identity', 'biography', 'preferences', 'certification'];
      
      for (final task in tasks) {
        await DebugProfileCompletion.debugTask(user.uid, task);
      }

    } catch (e, stackTrace) {
      EnhancedLogger.error('Error checking all tasks', 
        tag: _tag,
        error: e,
        stackTrace: stackTrace
      );
    }
  }
}