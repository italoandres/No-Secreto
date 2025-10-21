import 'package:firebase_auth/firebase_auth.dart';
import '../utils/quick_populate_profiles.dart';
import '../utils/fix_existing_profile_for_exploration.dart';

/// Sistema que corrige automaticamente quando o app inicia
/// VOCÊ NÃO PRECISA FAZER NADA - ISSO RODA SOZINHO!
class AutoFixOnStartup {
  static bool _hasRun = false;

  /// Executa correção automática quando o app inicia
  static Future<void> runAutoFix() async {
    // Evitar executar múltiplas vezes
    if (_hasRun) return;
    _hasRun = true;

    try {
      print('🚀🚀🚀 INICIANDO CORREÇÃO AUTOMÁTICA! 🚀🚀🚀');
      print('=' * 60);
      
      // Aguardar um pouco para o app carregar
      await Future.delayed(Duration(seconds: 5));
      
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('⚠️ Usuário não logado ainda, tentando novamente em 10 segundos...');
        await Future.delayed(Duration(seconds: 10));
        _hasRun = false; // Permitir nova tentativa
        return runAutoFix();
      }

      print('✅ Usuário logado: ${currentUser.uid}');
      print('🔍 Verificando se precisa corrigir...');

      // 1. POPULAR DADOS DE TESTE PRIMEIRO
      print('\n1️⃣ POPULANDO DADOS DE TESTE...');
      try {
        await QuickPopulateProfiles.populateNow();
        print('✅ Dados de teste criados com sucesso!');
      } catch (e) {
        print('⚠️ Erro ao popular dados (pode já existir): $e');
      }

      // 2. CORRIGIR SEU PERFIL
      print('\n2️⃣ CORRIGINDO SEU PERFIL...');
      try {
        await FixExistingProfileForExploration.runCompleteCheck();
        print('✅ Seu perfil foi corrigido!');
      } catch (e) {
        print('⚠️ Erro ao corrigir perfil: $e');
      }

      print('\n' + '=' * 60);
      print('🎉🎉🎉 CORREÇÃO AUTOMÁTICA CONCLUÍDA! 🎉🎉🎉');
      print('📱 AGORA TESTE: Toque no ícone 🔍 na barra superior');
      print('📊 VOCÊ DEVE VER: 7 perfis (6 de teste + o seu)');
      print('🔍 BUSQUE POR: seu nome, "maria", "joão"');
      print('=' * 60);
      
    } catch (e) {
      print('❌ ERRO DURANTE CORREÇÃO AUTOMÁTICA: $e');
    }
  }

  /// Força nova execução (para testes)
  static void reset() {
    _hasRun = false;
  }
}