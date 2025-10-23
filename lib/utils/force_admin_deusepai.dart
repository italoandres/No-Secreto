import 'package:cloud_firestore/cloud_firestore.dart';

/// Script para forçar deusepaimovement@gmail.com como admin
/// Execute este script UMA VEZ para corrigir o problema
class ForceAdminDeusepai {
  static Future<void> execute() async {
    try {
      print('🔧 Iniciando correção de admin...');
      
      final firestore = FirebaseFirestore.instance;
      
      // Buscar usuário por email
      final query = await firestore
          .collection('usuarios')
          .where('email', isEqualTo: 'deusepaimovement@gmail.com')
          .limit(1)
          .get();
      
      if (query.docs.isEmpty) {
        print('❌ Usuário deusepaimovement@gmail.com não encontrado!');
        print('   Certifique-se de que o usuário já foi criado no app.');
        return;
      }
      
      final userDoc = query.docs.first;
      final userId = userDoc.id;
      
      print('✅ Usuário encontrado: $userId');
      print('📝 Atualizando isAdmin para true...');
      
      // Forçar isAdmin = true
      await firestore.collection('usuarios').doc(userId).update({
        'isAdmin': true,
      });
      
      print('✅ SUCESSO! deusepaimovement@gmail.com agora é admin!');
      print('');
      print('📋 Próximos passos:');
      print('   1. Faça logout do app');
      print('   2. Faça login novamente com deusepaimovement@gmail.com');
      print('   3. Você deve ver os botões de admin!');
      
    } catch (e) {
      print('❌ ERRO ao forçar admin: $e');
      print('');
      print('💡 Possíveis soluções:');
      print('   1. Verifique se o usuário existe no Firestore');
      print('   2. Verifique as permissões do Firestore');
      print('   3. Tente fazer login com o usuário primeiro');
    }
  }
}
