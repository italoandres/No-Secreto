import 'package:cloud_firestore/cloud_firestore.dart';

/// Debug para verificar dados nas duas coleções
class DualCollectionDebug {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Investigar dados nas duas coleções
  static Future<void> debugBothCollections() async {
    print('\n🔍 === INVESTIGAÇÃO DUAS COLEÇÕES ===');
    
    try {
      // 1. Verificar coleção usuarios
      print('\n📊 1. COLEÇÃO USUARIOS:');
      final usuariosSnapshot = await _firestore.collection('usuarios').get();
      print('   Total documentos: ${usuariosSnapshot.docs.length}');
      
      for (final doc in usuariosSnapshot.docs) {
        final data = doc.data();
        final nome = data['nome'] as String? ?? '';
        final username = data['username'] as String? ?? '';
        
        if (nome.toLowerCase().contains('itala') || username.toLowerCase().contains('itala')) {
          print('\n   🎯 ITALA em usuarios:');
          print('      • ID: ${doc.id}');
          print('      • Nome: $nome');
          print('      • Username: $username');
          print('      • IsActive: ${data['isActive']}');
          print('      • Cidade: ${data['cidade'] ?? "AUSENTE"}');
          print('      • Bio: ${data['bio'] != null && (data['bio'] as String).isNotEmpty ? "Preenchida" : "AUSENTE"}');
        }
      }
      
      // 2. Verificar coleção spiritual_profiles
      print('\n📊 2. COLEÇÃO SPIRITUAL_PROFILES:');
      final spiritualSnapshot = await _firestore.collection('spiritual_profiles').get();
      print('   Total documentos: ${spiritualSnapshot.docs.length}');
      
      for (final doc in spiritualSnapshot.docs) {
        final data = doc.data();
        final displayName = data['displayName'] as String? ?? '';
        final username = data['username'] as String? ?? '';
        
        if (displayName.toLowerCase().contains('itala') || username.toLowerCase().contains('itala')) {
          print('\n   🎯 ITALA em spiritual_profiles:');
          print('      • ID: ${doc.id}');
          print('      • DisplayName: $displayName');
          print('      • Username: $username');
          print('      • UserId: ${data['userId']}');
          print('      • City: ${data['city'] ?? "AUSENTE"}');
          print('      • State: ${data['state'] ?? "AUSENTE"}');
          print('      • AboutMe: ${data['aboutMe'] != null && (data['aboutMe'] as String).isNotEmpty ? "Preenchida" : "AUSENTE"}');
          print('      • Age: ${data['age'] ?? "AUSENTE"}');
          print('      • IsProfileComplete: ${data['isProfileComplete']}');
        }
      }
      
      // 3. Verificar se há correspondência entre as coleções
      print('\n📊 3. VERIFICANDO CORRESPONDÊNCIAS:');
      for (final usuarioDoc in usuariosSnapshot.docs) {
        final usuarioData = usuarioDoc.data();
        final nome = usuarioData['nome'] as String? ?? '';
        final username = usuarioData['username'] as String? ?? '';
        
        if (nome.toLowerCase().contains('itala') || username.toLowerCase().contains('itala')) {
          // Procurar perfil espiritual correspondente
          final spiritualDoc = spiritualSnapshot.docs.where((doc) {
            final data = doc.data();
            return data['userId'] == usuarioDoc.id;
          }).firstOrNull;
          
          print('\n   🔗 CORRESPONDÊNCIA para ${usuarioDoc.id}:');
          print('      • Usuario: $nome ($username)');
          print('      • Spiritual Profile: ${spiritualDoc != null ? "EXISTE" : "NÃO EXISTE"}');
          
          if (spiritualDoc != null) {
            final spiritualData = spiritualDoc.data();
            print('      • Spiritual ID: ${spiritualDoc.id}');
            print('      • Completo: ${spiritualData['isProfileComplete']}');
          }
        }
      }
      
    } catch (e) {
      print('❌ ERRO: $e');
    }
    
    print('\n🔍 === FIM INVESTIGAÇÃO DUAS COLEÇÕES ===\n');
  }
}