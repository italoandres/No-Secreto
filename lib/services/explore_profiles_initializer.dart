import 'package:firebase_auth/firebase_auth.dart';
import 'auto_profile_fixer.dart';
import 'auto_data_populator.dart';

/// Inicializador completo do sistema Explorar Perfis
class ExploreProfilesInitializer {
  static bool _isInitialized = false;

  /// Inicializa todo o sistema automaticamente
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print('🚀 ExploreProfilesInitializer: Iniciando...');
      
      // Aguardar autenticação
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('⚠️ ExploreProfilesInitializer: Usuário não autenticado, aguardando...');
        return;
      }

      // 1. Popular dados de teste se necessário
      await AutoDataPopulator.ensureTestDataExists();
      
      // 2. Corrigir perfil do usuário atual
      await AutoProfileFixer.autoFixIfNeeded();
      
      _isInitialized = true;
      print('✅ ExploreProfilesInitializer: Sistema inicializado com sucesso!');
      
    } catch (e) {
      print('❌ ExploreProfilesInitializer: Erro durante inicialização: $e');
    }
  }

  /// Força reinicialização
  static void reset() {
    _isInitialized = false;
    AutoProfileFixer.reset();
    AutoDataPopulator.reset();
  }

  /// Verifica se está inicializado
  static bool get isInitialized => _isInitialized;
}