import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/enhanced_logger.dart';

/// Debug profundo para investigar perfis de vitrine
class DeepVitrineDebug {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Investigação completa do problema do perfil @itala3
  static Future<void> investigateItala3Profile() async {
    print('\n🔍 INVESTIGAÇÃO PROFUNDA: Perfil @itala3');
    print('=' * 60);
    
    try {
      // 1. Verificar TODOS os usuários na coleção usuarios
      await _debugAllUsers();
      
      // 2. Verificar especificamente perfis com "itala" no nome
      await _debugItalaProfiles();
      
      // 3. Verificar perfis com username "itala3"
      await _debugUsernameItala3();
      
      // 4. Verificar estrutura dos documentos
      await _debugDocumentStructure();
      
      // 5. Testar filtros individualmente
      await _testIndividualFilters();
      
    } catch (e) {
      print('❌ Erro na investigação: $e');
    }
  }

  /// Debug de todos os usuários
  static Future<void> _debugAllUsers() async {
    print('\n📊 1. TODOS OS USUÁRIOS NA COLEÇÃO');
    print('-' * 40);
    
    try {
      final snapshot = await _firestore
          .collection('usuarios')
          .limit(100) // Aumentar limite para ver mais perfis
          .get();
      
      print('✅ Total de usuários encontrados: ${snapshot.docs.length}');
      
      for (int i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final data = doc.data();
        final nome = data['nome'] as String? ?? 'Sem nome';
        final username = data['username'] as String? ?? 'N/A';
        final isActive = data['isActive'] as bool? ?? false;
        
        print('   ${i + 1}. ID: ${doc.id}');
        print('      Nome: $nome');
        print('      Username: $username');
        print('      IsActive: $isActive');
        
        // Destacar perfis com "itala" no nome ou username
        if (nome.toLowerCase().contains('itala') || 
            username.toLowerCase().contains('itala')) {
          print('      🎯 *** PERFIL ITALA ENCONTRADO! ***');
          print('      📋 Dados completos:');
          data.forEach((key, value) {
            print('         $key: $value');
          });
        }
        print('');
      }
      
    } catch (e) {
      print('❌ Erro ao buscar todos os usuários: $e');
    }
  }

  /// Debug específico para perfis com "itala"
  static Future<void> _debugItalaProfiles() async {
    print('\n📊 2. PERFIS COM "ITALA" NO NOME');
    print('-' * 40);
    
    try {
      // Buscar por nome contendo "itala"
      final snapshot = await _firestore
          .collection('usuarios')
          .get(); // Buscar todos e filtrar no código
      
      int italaCount = 0;
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final nome = (data['nome'] as String? ?? '').toLowerCase();
        final username = (data['username'] as String? ?? '').toLowerCase();
        
        if (nome.contains('itala') || username.contains('itala')) {
          italaCount++;
          print('🔍 PERFIL ITALA #$italaCount:');
          print('   ID: ${doc.id}');
          print('   Dados completos:');
          data.forEach((key, value) {
            print('      $key: $value');
          });
          print('');
        }
      }
      
      print('📊 Total de perfis "Itala" encontrados: $italaCount');
      
    } catch (e) {
      print('❌ Erro ao buscar perfis Itala: $e');
    }
  }

  /// Debug específico para username "itala3"
  static Future<void> _debugUsernameItala3() async {
    print('\n📊 3. BUSCA POR USERNAME "itala3"');
    print('-' * 40);
    
    try {
      // Tentar buscar por username exato
      final snapshot = await _firestore
          .collection('usuarios')
          .where('username', isEqualTo: 'itala3')
          .get();
      
      print('✅ Documentos encontrados com username "itala3": ${snapshot.docs.length}');
      
      for (final doc in snapshot.docs) {
        print('🎯 PERFIL ENCONTRADO:');
        print('   ID: ${doc.id}');
        print('   Dados:');
        doc.data().forEach((key, value) {
          print('      $key: $value');
        });
      }
      
      // Também tentar sem filtro e buscar no código
      print('\n🔍 Buscando "itala3" em todos os usernames...');
      final allSnapshot = await _firestore
          .collection('usuarios')
          .get();
      
      int found = 0;
      for (final doc in allSnapshot.docs) {
        final username = doc.data()['username'] as String? ?? '';
        if (username.toLowerCase() == 'itala3') {
          found++;
          print('✅ Encontrado via busca manual: ${doc.id}');
          print('   Username: $username');
        }
      }
      
      print('📊 Total encontrados via busca manual: $found');
      
    } catch (e) {
      print('❌ Erro ao buscar username itala3: $e');
    }
  }

  /// Debug da estrutura dos documentos
  static Future<void> _debugDocumentStructure() async {
    print('\n📊 4. ESTRUTURA DOS DOCUMENTOS');
    print('-' * 40);
    
    try {
      final snapshot = await _firestore
          .collection('usuarios')
          .limit(3)
          .get();
      
      print('✅ Analisando estrutura de ${snapshot.docs.length} documentos:');
      
      for (int i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final data = doc.data();
        
        print('\\n📋 Documento ${i + 1} (${doc.id}):');
        print('   Campos disponíveis:');
        data.keys.forEach((key) {
          final value = data[key];
          final type = value.runtimeType;
          print('      $key: $type = $value');
        });
      }
      
    } catch (e) {
      print('❌ Erro ao analisar estrutura: $e');
    }
  }

  /// Testar filtros individualmente
  static Future<void> _testIndividualFilters() async {
    print('\n📊 5. TESTE DE FILTROS INDIVIDUAIS');
    print('-' * 40);
    
    try {
      // Teste 1: Apenas isActive = true
      print('🔍 Teste 1: isActive = true');
      final activeSnapshot = await _firestore
          .collection('usuarios')
          .where('isActive', isEqualTo: true)
          .get();
      print('   Resultados: ${activeSnapshot.docs.length}');
      
      // Teste 2: Apenas username não nulo
      print('\\n🔍 Teste 2: username não nulo');
      final usernameSnapshot = await _firestore
          .collection('usuarios')
          .get();
      
      int withUsername = 0;
      int withValidUsername = 0;
      
      for (final doc in usernameSnapshot.docs) {
        final username = doc.data()['username'] as String?;
        if (username != null) {
          withUsername++;
          if (username.isNotEmpty && username != 'N/A') {
            withValidUsername++;
          }
        }
      }
      
      print('   Com username não nulo: $withUsername');
      print('   Com username válido: $withValidUsername');
      
      // Teste 3: Com bio preenchida
      print('\\n🔍 Teste 3: bio preenchida');
      int withBio = 0;
      
      for (final doc in usernameSnapshot.docs) {
        final bio = doc.data()['bio'] as String?;
        if (bio != null && bio.isNotEmpty) {
          withBio++;
        }
      }
      
      print('   Com bio preenchida: $withBio');
      
      // Teste 4: Com localização
      print('\\n🔍 Teste 4: com localização');
      int withLocation = 0;
      
      for (final doc in usernameSnapshot.docs) {
        final cidade = doc.data()['cidade'] as String?;
        final estado = doc.data()['estado'] as String?;
        if ((cidade != null && cidade.isNotEmpty) || 
            (estado != null && estado.isNotEmpty)) {
          withLocation++;
        }
      }
      
      print('   Com localização: $withLocation');
      
      // Teste 5: Com nascimento
      print('\\n🔍 Teste 5: com data de nascimento');
      int withBirthdate = 0;
      
      for (final doc in usernameSnapshot.docs) {
        final nascimento = doc.data()['nascimento'];
        if (nascimento != null) {
          withBirthdate++;
        }
      }
      
      print('   Com data de nascimento: $withBirthdate');
      
      // Teste 6: Perfis que atendem TODOS os critérios
      print('\\n🔍 Teste 6: perfis que atendem TODOS os critérios');
      int completeProfiles = 0;
      
      for (final doc in usernameSnapshot.docs) {
        final data = doc.data();
        
        final username = data['username'] as String?;
        final nome = data['nome'] as String?;
        final cidade = data['cidade'] as String?;
        final estado = data['estado'] as String?;
        final bio = data['bio'] as String?;
        final nascimento = data['nascimento'];
        final isActive = data['isActive'] as bool?;
        
        // Aplicar todos os critérios
        if (username != null && username.isNotEmpty && username != 'N/A' &&
            nome != null && nome.isNotEmpty &&
            ((cidade != null && cidade.isNotEmpty) || (estado != null && estado.isNotEmpty)) &&
            bio != null && bio.isNotEmpty &&
            nascimento != null &&
            isActive == true) {
          completeProfiles++;
          
          print('   ✅ Perfil completo: ${data['nome']} (@${data['username']})');
          print('      ID: ${doc.id}');
          print('      Cidade: ${data['cidade'] ?? 'N/A'}');
          print('      Estado: ${data['estado'] ?? 'N/A'}');
          print('      Bio: ${(data['bio'] as String? ?? '').length} caracteres');
        }
      }
      
      print('\\n📊 RESUMO DOS TESTES:');
      print('   • Perfis ativos: ${activeSnapshot.docs.length}');
      print('   • Com username válido: $withValidUsername');
      print('   • Com bio: $withBio');
      print('   • Com localização: $withLocation');
      print('   • Com nascimento: $withBirthdate');
      print('   • Perfis COMPLETOS: $completeProfiles');
      
    } catch (e) {
      print('❌ Erro nos testes de filtros: $e');
    }
  }

  /// Registra função global para debug no console
  static void registerGlobalDebugFunction() {
    print('✅ Função de debug profundo registrada!');
    print('💡 Execute: DeepVitrineDebug.investigateItala3Profile()');
  }
}