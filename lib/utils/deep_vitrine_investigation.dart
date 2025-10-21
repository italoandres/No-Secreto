import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/enhanced_logger.dart';

/// Investigação profunda do problema de perfis de vitrine
class DeepVitrineInvestigation {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Investigação completa do problema
  static Future<void> investigateVitrineIssue() async {
    print('\n🔍 INVESTIGAÇÃO PROFUNDA: Problema dos Perfis de Vitrine');
    print('=' * 70);
    
    try {
      // 1. Verificar TODOS os usuários sem filtros
      await _checkAllUsers();
      
      // 2. Verificar especificamente por @itala3 e @itala4
      await _checkSpecificUser('itala3');
      await _checkSpecificUser('itala4');
      
      // 3. Verificar query do Firebase com filtros
      await _checkFirebaseQuery();
      
      // 4. Testar critérios de validação
      await _testValidationCriteria();
      
    } catch (e) {
      print('❌ ERRO NA INVESTIGAÇÃO: $e');
    }
  }

  /// 1. Verificar TODOS os usuários sem filtros
  static Future<void> _checkAllUsers() async {
    print('\n📊 1. VERIFICANDO TODOS OS USUÁRIOS (SEM FILTROS)');
    print('-' * 50);
    
    try {
      final snapshot = await _firestore
          .collection('usuarios')
          .get();
      
      print('✅ Total de usuários no banco: ${snapshot.docs.length}');
      
      int italaCount = 0;
      int completeProfiles = 0;
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final nome = data['nome'] as String? ?? '';
        final username = data['username'] as String? ?? '';
        
        // Contar perfis com nome contendo "itala"
        if (nome.toLowerCase().contains('itala') || username.toLowerCase().contains('itala')) {
          italaCount++;
          print('\n🎯 PERFIL ITALA ENCONTRADO:');
          print('   • ID: ${doc.id}');
          print('   • Nome: $nome');
          print('   • Username: $username');
          print('   • Email: ${data['email'] ?? 'N/A'}');
          print('   • Cidade: ${data['cidade'] ?? 'N/A'}');
          print('   • Estado: ${data['estado'] ?? 'N/A'}');
          print('   • Bio: ${(data['bio'] as String? ?? '').length > 0 ? 'Preenchida (${(data['bio'] as String).length} chars)' : 'Vazia'}');
          print('   • Nascimento: ${data['nascimento'] != null ? 'Preenchido' : 'Vazio'}');
          print('   • IsActive: ${data['isActive'] ?? 'N/A'}');
          print('   • Foto: ${data['foto'] != null ? 'Tem foto' : 'Sem foto'}');
          
          // Verificar se atende critérios de vitrine
          if (_meetsVitrineRequirements(data)) {
            completeProfiles++;
            print('   ✅ ATENDE CRITÉRIOS DE VITRINE COMPLETA!');
          } else {
            print('   ❌ NÃO atende critérios: ${_getFailureReason(data)}');
          }
        }
      }
      
      print('\n📊 RESUMO GERAL:');
      print('   • Total de usuários: ${snapshot.docs.length}');
      print('   • Perfis "Itala" encontrados: $italaCount');
      print('   • Perfis que atendem critérios de vitrine: $completeProfiles');
      
    } catch (e) {
      print('❌ Erro ao verificar usuários: $e');
    }
  }

  /// 2. Verificar especificamente por @itala3/@itala4
  static Future<void> _checkSpecificUser(String searchTerm) async {
    print('\n📊 2. VERIFICANDO ESPECIFICAMENTE: "$searchTerm"');
    print('-' * 50);
    
    try {
      // Buscar por nome
      final nameQuery = await _firestore
          .collection('usuarios')
          .where('nome', isGreaterThanOrEqualTo: searchTerm.toLowerCase())
          .where('nome', isLessThanOrEqualTo: searchTerm.toLowerCase() + '\uf8ff')
          .get();
      
      print('🔍 Busca por NOME "$searchTerm": ${nameQuery.docs.length} resultados');
      
      // Buscar por username
      final usernameQuery = await _firestore
          .collection('usuarios')
          .where('username', isGreaterThanOrEqualTo: searchTerm.toLowerCase())
          .where('username', isLessThanOrEqualTo: searchTerm.toLowerCase() + '\uf8ff')
          .get();
      
      print('🔍 Busca por USERNAME "$searchTerm": ${usernameQuery.docs.length} resultados');
      
      // Mostrar detalhes de cada resultado
      final allResults = [...nameQuery.docs, ...usernameQuery.docs];
      final uniqueResults = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
      
      for (final doc in allResults) {
        uniqueResults[doc.id] = doc;
      }
      
      print('\n📋 RESULTADOS ÚNICOS ENCONTRADOS: ${uniqueResults.length}');
      for (final doc in uniqueResults.values) {
        final data = doc.data();
        print('\n   📄 Documento: ${doc.id}');
        print('      • Nome: ${data['nome']}');
        print('      • Username: ${data['username']}');
        print('      • Critérios de vitrine: ${_meetsVitrineRequirements(data) ? 'ATENDE' : 'NÃO ATENDE'}');
        if (!_meetsVitrineRequirements(data)) {
          print('      • Motivo: ${_getFailureReason(data)}');
        }
      }
      
    } catch (e) {
      print('❌ Erro na busca específica: $e');
    }
  }

  /// 3. Verificar query do Firebase com filtros
  static Future<void> _checkFirebaseQuery() async {
    print('\n📊 3. TESTANDO QUERY DO FIREBASE COM FILTROS');
    print('-' * 50);
    
    try {
      // Testar query sem filtros (como está sendo feita atualmente)
      final noFilterQuery = await _firestore
          .collection('usuarios')
          .limit(50)
          .get();
      
      print('🔍 Usuários sem filtro (limit 50): ${noFilterQuery.docs.length}');
      
      int vitrineNoFilterCount = 0;
      for (final doc in noFilterQuery.docs) {
        if (_meetsVitrineRequirements(doc.data())) {
          vitrineNoFilterCount++;
        }
      }
      print('✅ Destes, quantos atendem critérios de vitrine: $vitrineNoFilterCount');
      
    } catch (e) {
      print('❌ Erro ao testar queries: $e');
    }
  }

  /// 4. Testar critérios de validação
  static Future<void> _testValidationCriteria() async {
    print('\n📊 4. TESTANDO CRITÉRIOS DE VALIDAÇÃO');
    print('-' * 50);
    
    // Criar perfil de teste para validar critérios
    final testProfile = {
      'nome': 'itala4',
      'username': 'itala4',
      'bio': 'Bio de teste para perfil de vitrine',
      'cidade': 'São Paulo',
      'estado': 'SP',
      'nascimento': Timestamp.now(),
      'isActive': true,
      'email': 'itala4@test.com',
      'foto': 'https://example.com/foto.jpg',
    };
    
    print('🧪 TESTANDO PERFIL DE EXEMPLO:');
    print('   • Nome: ${testProfile['nome']}');
    print('   • Username: ${testProfile['username']}');
    print('   • Bio: ${testProfile['bio']}');
    print('   • Cidade: ${testProfile['cidade']}');
    print('   • Estado: ${testProfile['estado']}');
    print('   • Nascimento: ${testProfile['nascimento'] != null ? 'Preenchido' : 'Vazio'}');
    print('   • IsActive: ${testProfile['isActive']}');
    
    final meetsRequirements = _meetsVitrineRequirements(testProfile);
    print('\n✅ RESULTADO: ${meetsRequirements ? 'ATENDE TODOS OS CRITÉRIOS' : 'NÃO ATENDE'}');
    
    if (!meetsRequirements) {
      print('❌ Motivo: ${_getFailureReason(testProfile)}');
    }
  }

  /// Verifica se o perfil atende aos requisitos de vitrine
  static bool _meetsVitrineRequirements(Map<String, dynamic> userData) {
    // 1. Username obrigatório
    final username = userData['username'] as String?;
    if (username == null || username.isEmpty || username == 'N/A') {
      return false;
    }

    // 2. Nome obrigatório
    final nome = userData['nome'] as String?;
    if (nome == null || nome.isEmpty) {
      return false;
    }

    // 3. Localização (cidade OU estado)
    final cidade = userData['cidade'] as String?;
    final estado = userData['estado'] as String?;
    if ((cidade == null || cidade.isEmpty) && (estado == null || estado.isEmpty)) {
      return false;
    }

    // 4. Bio obrigatória
    final bio = userData['bio'] as String?;
    if (bio == null || bio.isEmpty) {
      return false;
    }

    // 5. Data de nascimento obrigatória
    final nascimento = userData['nascimento'];
    if (nascimento == null) {
      return false;
    }

    // 6. Perfil ativo
    final isActive = userData['isActive'] as bool?;
    if (isActive != true) {
      return false;
    }

    return true;
  }

  /// Retorna o motivo pelo qual o perfil não atende aos critérios
  static String _getFailureReason(Map<String, dynamic> userData) {
    final reasons = <String>[];

    final username = userData['username'] as String?;
    if (username == null || username.isEmpty || username == 'N/A') {
      reasons.add('Username ausente/inválido');
    }

    final nome = userData['nome'] as String?;
    if (nome == null || nome.isEmpty) {
      reasons.add('Nome ausente');
    }

    final cidade = userData['cidade'] as String?;
    final estado = userData['estado'] as String?;
    if ((cidade == null || cidade.isEmpty) && (estado == null || estado.isEmpty)) {
      reasons.add('Localização ausente');
    }

    final bio = userData['bio'] as String?;
    if (bio == null || bio.isEmpty) {
      reasons.add('Bio ausente');
    }

    final nascimento = userData['nascimento'];
    if (nascimento == null) {
      reasons.add('Data nascimento ausente');
    }

    final isActive = userData['isActive'] as bool?;
    if (isActive != true) {
      reasons.add('Perfil inativo');
    }

    return reasons.isEmpty ? 'Motivo desconhecido' : reasons.join(', ');
  }

  /// Executa investigação rápida via console
  static void registerConsoleFunction() {
    print('✅ Função de investigação registrada!');
    print('💡 Para executar a investigação completa, chame:');
    print('   DeepVitrineInvestigation.investigateVitrineIssue()');
  }
}