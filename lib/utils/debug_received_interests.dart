import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Debug para investigar notificações recebidas
class DebugReceivedInterests {
  
  /// Investigar completamente as notificações
  static Future<void> investigateReceivedInterests() async {
    print('🔍 INVESTIGANDO NOTIFICAÇÕES RECEBIDAS');
    print('=' * 60);
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ Usuário não logado');
        return;
      }
      
      final userId = currentUser.uid;
      print('👤 Usuário: $userId');
      print('📧 Email: ${currentUser.email}');
      
      // 1. Verificar todas as notificações
      await _checkAllNotifications(userId);
      
      // 2. Verificar estatísticas
      await _checkStats(userId);
      
      // 3. Verificar estrutura dos dados
      await _checkDataStructure();
      
      print('');
      print('🎯 INVESTIGAÇÃO CONCLUÍDA!');
      
    } catch (e) {
      print('❌ Erro na investigação: $e');
    }
  }
  
  /// Verificar todas as notificações
  static Future<void> _checkAllNotifications(String userId) async {
    print('');
    print('📋 VERIFICANDO TODAS AS NOTIFICAÇÕES:');
    
    try {
      // Buscar TODAS as notificações relacionadas ao usuário
      final sentQuery = await FirebaseFirestore.instance
          .collection('interest_notifications')
          .where('fromUserId', isEqualTo: userId)
          .get();
      
      final receivedQuery = await FirebaseFirestore.instance
          .collection('interest_notifications')
          .where('toUserId', isEqualTo: userId)
          .get();
      
      print('   📤 Notificações ENVIADAS: ${sentQuery.docs.length}');
      for (var doc in sentQuery.docs) {
        final data = doc.data();
        print('      ID: ${doc.id}');
        print('      Para: ${data['toUserId']}');
        print('      Status: ${data['status']}');
        print('      Tipo: ${data['type']}');
        print('      ---');
      }
      
      print('   📥 Notificações RECEBIDAS: ${receivedQuery.docs.length}');
      for (var doc in receivedQuery.docs) {
        final data = doc.data();
        print('      ID: ${doc.id}');
        print('      De: ${data['fromUserId']} (${data['fromUserName']})');
        print('      Status: ${data['status']}');
        print('      Tipo: ${data['type']}');
        print('      Mensagem: ${data['message']}');
        print('      Data: ${data['dataCriacao']}');
        print('      ---');
      }
      
    } catch (e) {
      print('❌ Erro ao verificar notificações: $e');
    }
  }
  
  /// Verificar estatísticas
  static Future<void> _checkStats(String userId) async {
    print('');
    print('📊 VERIFICANDO ESTATÍSTICAS:');
    
    try {
      // Calcular estatísticas manualmente
      final sentQuery = await FirebaseFirestore.instance
          .collection('interest_notifications')
          .where('fromUserId', isEqualTo: userId)
          .get();
      
      final receivedQuery = await FirebaseFirestore.instance
          .collection('interest_notifications')
          .where('toUserId', isEqualTo: userId)
          .get();
      
      final sent = sentQuery.docs.length;
      final received = receivedQuery.docs.length;
      
      final acceptedSent = sentQuery.docs
          .where((doc) => doc.data()['status'] == 'accepted')
          .length;
      
      final acceptedReceived = receivedQuery.docs
          .where((doc) => doc.data()['status'] == 'accepted')
          .length;
      
      print('   📤 Enviados: $sent');
      print('   📥 Recebidos: $received');
      print('   ✅ Aceitos (enviados): $acceptedSent');
      print('   ✅ Aceitos (recebidos): $acceptedReceived');
      
      // Verificar status específicos
      final pending = receivedQuery.docs
          .where((doc) => doc.data()['status'] == 'pending')
          .length;
      
      final viewed = receivedQuery.docs
          .where((doc) => doc.data()['status'] == 'viewed')
          .length;
      
      final rejected = receivedQuery.docs
          .where((doc) => doc.data()['status'] == 'rejected')
          .length;
      
      print('   🔄 Pendentes: $pending');
      print('   👁️ Visualizados: $viewed');
      print('   ❌ Rejeitados: $rejected');
      
    } catch (e) {
      print('❌ Erro ao verificar estatísticas: $e');
    }
  }
  
  /// Verificar estrutura dos dados
  static Future<void> _checkDataStructure() async {
    print('');
    print('🏗️ VERIFICANDO ESTRUTURA DOS DADOS:');
    
    try {
      final query = await FirebaseFirestore.instance
          .collection('interest_notifications')
          .limit(3)
          .get();
      
      if (query.docs.isEmpty) {
        print('   ⚠️ Nenhuma notificação encontrada na coleção');
        return;
      }
      
      print('   📋 Estrutura dos documentos:');
      for (int i = 0; i < query.docs.length; i++) {
        final doc = query.docs[i];
        final data = doc.data();
        
        print('   Documento ${i + 1}:');
        for (var key in data.keys) {
          print('      $key: ${data[key]} (${data[key].runtimeType})');
        }
        print('      ---');
      }
      
    } catch (e) {
      print('❌ Erro ao verificar estrutura: $e');
    }
  }
  
  /// Criar notificação de teste
  static Future<void> createTestNotification() async {
    print('');
    print('🧪 CRIANDO NOTIFICAÇÃO DE TESTE:');
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ Usuário não logado');
        return;
      }
      
      // Criar notificação de teste para o próprio usuário
      await FirebaseFirestore.instance
          .collection('interest_notifications')
          .add({
        'fromUserId': 'test_user_id',
        'fromUserName': 'Usuário Teste',
        'fromUserEmail': 'teste@gmail.com',
        'toUserId': currentUser.uid,
        'toUserEmail': currentUser.email,
        'type': 'interest',
        'message': 'Demonstrou interesse no seu perfil (TESTE)',
        'status': 'pending',
        'dataCriacao': Timestamp.now(),
        'dataResposta': null,
      });
      
      print('✅ Notificação de teste criada!');
      
    } catch (e) {
      print('❌ Erro ao criar notificação de teste: $e');
    }
  }
}