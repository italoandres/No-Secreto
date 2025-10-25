import '../utils/quick_populate_profiles.dart';
import '../utils/fix_existing_profile_for_exploration.dart';

/// Serviço que popula dados automaticamente se necessário
class AutoDataPopulator {
  static bool _hasRun = false;

  /// Popula dados de teste se não existirem
  static Future<void> ensureTestDataExists() async {
    if (_hasRun) return;
    _hasRun = true;

    try {
      print('🔍 AutoDataPopulator: Verificando dados de teste...');

      // Verificar se já existem dados
      final hasData = await QuickPopulateProfiles.checkData();

      if (!hasData) {
        print('🚀 AutoDataPopulator: Populando dados de teste...');
        await QuickPopulateProfiles.populateNow();
        print('✅ AutoDataPopulator: Dados de teste criados!');
      } else {
        print('✅ AutoDataPopulator: Dados de teste já existem');
      }

      // Também corrigir perfil do usuário atual se necessário
      await FixExistingProfileForExploration.autoFixIfNeeded();
    } catch (e) {
      print('⚠️ AutoDataPopulator: Erro: $e');
    }
  }

  /// Força nova verificação
  static void reset() {
    _hasRun = false;
  }
}
