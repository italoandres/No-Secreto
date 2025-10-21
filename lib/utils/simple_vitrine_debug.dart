import 'package:cloud_firestore/cloud_firestore.dart';

/// Debug simples e direto para investigar o problema de vitrine
class SimpleVitrineDebug {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Investigação simples e direta
  static Future<void> debugVitrineIssue() async {
    print('\n🔍 === INVESTIGAÇÃO SIMPLES VITRINE ===');
    
    try {
      // 1. Buscar TODOS os usuários
      final snapshot = await _firestore.collection('usuarios').get();
      print('📊 Total usuários no banco: ${snapshot.docs.length}');
      
      // 2. Procurar perfis "itala"
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final nome = data['nome'] as String? ?? '';
        final username = data['username'] as String? ?? '';
        
        if (nome.toLowerCase().contains('itala') || username.toLowerCase().contains('itala')) {
          print('\n🎯 PERFIL ITALA ENCONTRADO:');
          print('   • ID: ${doc.id}');
          print('   • Nome: $nome');
          print('   • Username: $username');
          print('   • Email: ${data['email']}');
          print('   • IsActive: ${data['isActive']}');
          
          // Verificar campos obrigatórios para vitrine
          final cidade = data['cidade'] as String?;
          final estado = data['estado'] as String?;
          final bio = data['bio'] as String?;
          final nascimento = data['nascimento'];
          
          print('   • Cidade: ${cidade ?? "AUSENTE"}');
          print('   • Estado: ${estado ?? "AUSENTE"}');
          print('   • Bio: ${bio != null && bio.isNotEmpty ? "Preenchida (${bio.length} chars)" : "AUSENTE"}');
          print('   • Nascimento: ${nascimento != null ? "Preenchido" : "AUSENTE"}');
          
          // Verificar se atende critérios
          final atendeVitrine = _checkVitrineRequirements(data);
          print('   • ✅ ATENDE VITRINE: $atendeVitrine');
          
          if (!atendeVitrine) {
            print('   • ❌ MOTIVOS: ${_getFailureReasons(data)}');
          }
        }
      }
      
    } catch (e) {
      print('❌ ERRO: $e');
    }
    
    print('\n🔍 === FIM INVESTIGAÇÃO ===\n');
  }

  /// Verifica se atende aos requisitos de vitrine
  static bool _checkVitrineRequirements(Map<String, dynamic> data) {
    // 1. Username
    final username = data['username'] as String?;
    if (username == null || username.isEmpty) return false;
    
    // 2. Nome
    final nome = data['nome'] as String?;
    if (nome == null || nome.isEmpty) return false;
    
    // 3. Localização
    final cidade = data['cidade'] as String?;
    final estado = data['estado'] as String?;
    if ((cidade == null || cidade.isEmpty) && (estado == null || estado.isEmpty)) return false;
    
    // 4. Bio
    final bio = data['bio'] as String?;
    if (bio == null || bio.isEmpty) return false;
    
    // 5. Nascimento
    final nascimento = data['nascimento'];
    if (nascimento == null) return false;
    
    // 6. Ativo
    final isActive = data['isActive'] as bool?;
    if (isActive != true) return false;
    
    return true;
  }

  /// Retorna os motivos de falha
  static List<String> _getFailureReasons(Map<String, dynamic> data) {
    final reasons = <String>[];
    
    final username = data['username'] as String?;
    if (username == null || username.isEmpty) reasons.add('Username ausente');
    
    final nome = data['nome'] as String?;
    if (nome == null || nome.isEmpty) reasons.add('Nome ausente');
    
    final cidade = data['cidade'] as String?;
    final estado = data['estado'] as String?;
    if ((cidade == null || cidade.isEmpty) && (estado == null || estado.isEmpty)) {
      reasons.add('Localização ausente');
    }
    
    final bio = data['bio'] as String?;
    if (bio == null || bio.isEmpty) reasons.add('Bio ausente');
    
    final nascimento = data['nascimento'];
    if (nascimento == null) reasons.add('Nascimento ausente');
    
    final isActive = data['isActive'] as bool?;
    if (isActive != true) reasons.add('Perfil inativo');
    
    return reasons;
  }
}