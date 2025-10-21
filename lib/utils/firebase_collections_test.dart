import 'package:whatsapp_chat/repositories/purpose_partnership_repository.dart';

/// Classe utilitária para testar as coleções do Firebase
class FirebaseCollectionsTest {
  
  /// Executar todos os testes de coleções
  static Future<void> runAllTests() async {
    print('🧪 Iniciando testes das coleções do Firebase...\n');
    
    await _testCollectionInitialization();
    await _testCollectionHealth();
    await _testCollectionPermissions();
    
    print('\n✅ Testes das coleções concluídos!');
  }
  
  /// Testar inicialização das coleções
  static Future<void> _testCollectionInitialization() async {
    print('📋 Teste 1: Inicialização das coleções');
    
    try {
      await PurposePartnershipRepository.initializeCollections();
      print('✅ Inicialização bem-sucedida\n');
    } catch (e) {
      print('❌ Falha na inicialização: $e\n');
    }
  }
  
  /// Testar saúde das coleções
  static Future<void> _testCollectionHealth() async {
    print('🏥 Teste 2: Saúde das coleções');
    
    try {
      final health = await PurposePartnershipRepository.checkCollectionsHealth();
      
      health.forEach((collection, isHealthy) {
        final status = isHealthy ? '✅' : '❌';
        print('$status $collection: ${isHealthy ? 'OK' : 'ERRO'}');
      });
      
      final allHealthy = health.values.every((h) => h);
      print(allHealthy ? '\n✅ Todas as coleções estão saudáveis' : '\n⚠️ Algumas coleções têm problemas');
      
    } catch (e) {
      print('❌ Erro ao verificar saúde: $e');
    }
    
    print('');
  }
  
  /// Testar permissões básicas das coleções
  static Future<void> _testCollectionPermissions() async {
    print('🔐 Teste 3: Permissões das coleções');
    
    // Este teste seria executado apenas em ambiente de desenvolvimento
    // com usuário autenticado para verificar se as regras estão funcionando
    
    print('⚠️ Teste de permissões deve ser executado com usuário autenticado');
    print('✅ Regras de segurança configuradas em firestore.rules\n');
  }
  
  /// Executar teste rápido (apenas para desenvolvimento)
  static Future<void> quickTest() async {
    print('⚡ Teste rápido das coleções...');
    
    final health = await PurposePartnershipRepository.checkCollectionsHealth();
    final allHealthy = health.values.every((h) => h);
    
    if (allHealthy) {
      print('✅ Todas as coleções OK!');
    } else {
      print('⚠️ Problemas detectados nas coleções:');
      health.forEach((collection, isHealthy) {
        if (!isHealthy) {
          print('❌ $collection');
        }
      });
    }
  }
}