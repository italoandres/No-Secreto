import 'package:firebase_auth/firebase_auth.dart';
import '../utils/fix_existing_profile_for_exploration.dart';

/// Serviço que automaticamente corrige perfis quando necessário
class AutoProfileFixer {
  static bool _hasRun = false;

  /// Executa correção automática se necessário
  static Future<void> autoFixIfNeeded() async {
    // Evitar execução múltipla
    if (_hasRun) return;
    _hasRun = true;

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      print('🔍 AutoProfileFixer: Verificando perfil...');

      // Verificar se perfil está visível
      final isVisible = await FixExistingProfileForExploration.checkProfileVisibility();
      
      if (!isVisible) {
        print('🚀 AutoProfileFixer: Corrigindo perfil automaticamente...');
        await FixExistingProfileForExploration.fixCurrentUserProfile();
        print('✅ AutoProfileFixer: Perfil corrigido!');
      } else {
        print('✅ AutoProfileFixer: Perfil já está visível');
      }
    } catch (e) {
      print('⚠️ AutoProfileFixer: Erro durante correção automática: $e');
    }
  }

  /// Força nova verificação
  static void reset() {
    _hasRun = false;
  }
}