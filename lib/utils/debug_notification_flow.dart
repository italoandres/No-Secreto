import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Debug do fluxo de notificações para identificar problemas
class DebugNotificationFlow {
  
  /// Verificar estado atual das notificações
  static Future<void> debugCurrentState() async {
    print('🔍 DEBUGANDO ESTADO ATUAL DAS NOTIFICAÇÕES');
    print('=' * 60);
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ Usuário não logado');
        return;
      }
      
      print('✅ Usuário atual: ${currentUser.uid}');
      print('📧 Email: ${currentUser.email}');
      
      // 1. Verificar coleção de notificações
      await _debugNotificationsCollection(currentUser.uid);
      
      // 2. Verificar usuários específicos
      await _debugSpecificUsers();
      
      // 3. Verificar estrutura dos dados
      await _debugDataStructure();
      
      print('');
      print('🎯 DEBUG CONCLUÍDO!');
      
    } catch (e) {
      print('❌ Erro no debug: $e');
    }
  }
  
  /// Debug da coleção de notificações
  static Future<void> _debugNotificationsCollection(String currentUserId) async {
    print('');
    print('📋 DEBUGANDO COLEÇÃO DE NOTIFICAÇÕES:');
    
    try {
      // Buscar todas as notificações relacionadas ao usuário atual
      final sentQuery = await FirebaseFirestore.instance
          .collection('interest_notifications')
          .where('fromUserId', isEqualTo: currentUserId)
          .get();
      
      final receivedQuery = await FirebaseFirestore.instance
          .collection('interest_notifications')
          .where('toUserId', isEqualTo: currentUserId)
          .get();
      
      print('   📤 Notificações ENVIADAS: ${sentQuery.docs.length}');
      for (var doc in sentQuery.docs) {
        final data = doc.data();
        print('      ID: ${doc.id}');
        print('      Para: ${data['toUserId']}');
        print('      Status: ${data['status']}');
        print('      Tipo: ${data['type']}');
        print('      Data: ${data['dataCriacao']}');
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
      print('❌ Erro ao debugar coleção: $e');
    }
  }
  
  /// Debug de usuários específicos
  static Future<void> _debugSpecificUsers() async {
    print('');
    print('👥 DEBUGANDO USUÁRIOS ESPECÍFICOS:');
    
    try {
      // Buscar usuários italo e itala3
      final usersQuery = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('email', whereIn: ['italo1@gmail.com', 'itala3@gmail.com'])
          .get();
      
      print('   👤 Usuários encontrados: ${usersQuery.docs.length}');
      
      for (var doc in usersQuery.docs) {
        final data = doc.data();
        print('      ID: ${doc.id}');
        print('      Nome: ${data['nome']}');
        print('      Email: ${data['email']}');
        print('      ---');
      }
      
    } catch (e) {
      print('❌ Erro ao debugar usuários: $e');
    }
  }
  
  /// Debug da estrutura dos dados
  static Future<void> _debugDataStructure() async {
    print('');
    print('🏗️ DEBUGANDO ESTRUTURA DOS DADOS:');
    
    try {
      // Verificar se a coleção existe
      final collectionRef = FirebaseFirestore.instance.collection('interest_notifications');
      final snapshot = await collectionRef.limit(1).get();
      
      if (snapshot.docs.isEmpty) {
        print('   ⚠️ Coleção interest_notifications está VAZIA');
        print('   💡 Isso pode explicar por que não há notificações');
      } else {
        print('   ✅ Coleção interest_notifications existe');
        final firstDoc = snapshot.docs.first;
        print('   📋 Estrutura do primeiro documento:');
        
        final data = firstDoc.data();
        for (var key in data.keys) {
          print('      $key: ${data[key]} (${data[key].runtimeType})');
        }
      }
      
    } catch (e) {
      print('❌ Erro ao debugar estrutura: $e');
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
      
      // Buscar outro usuário para teste
      final usersQuery = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('email', isNotEqualTo: currentUser.email)
          .limit(1)
          .get();
      
      if (usersQuery.docs.isEmpty) {
        print('❌ Nenhum outro usuário encontrado para teste');
        return;
      }
      
      final targetUser = usersQuery.docs.first;
      final targetData = targetUser.data();
      
      // Criar notificação de teste
      await FirebaseFirestore.instance
          .collection('interest_notifications')
          .add({
        'fromUserId': currentUser.uid,
        'fromUserName': 'Usuário Teste',
        'fromUserEmail': currentUser.email,
        'toUserId': targetUser.id,
        'toUserEmail': targetData['email'],
        'type': 'interest',
        'message': 'Demonstrou interesse no seu perfil (TESTE)',
        'status': 'pending',
        'dataCriacao': Timestamp.now(),
        'dataResposta': null,
      });
      
      print('✅ Notificação de teste criada!');
      print('   De: ${currentUser.uid}');
      print('   Para: ${targetUser.id}');
      
    } catch (e) {
      print('❌ Erro ao criar notificação de teste: $e');
    }
  }
  
  /// Widget para debug na interface
  static Widget buildDebugWidget() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Notificações'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Debug do Sistema de Notificações',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 20),
            
            ElevatedButton.icon(
              onPressed: () => debugCurrentState(),
              icon: const Icon(Icons.bug_report),
              label: const Text('Debug Estado Atual'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton.icon(
              onPressed: () => createTestNotification(),
              icon: const Icon(Icons.add_alert),
              label: const Text('Criar Notificação de Teste'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 20),
            
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'O que este debug verifica:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('🔍 Estado atual das notificações'),
                    Text('👥 Usuários específicos (italo, itala3)'),
                    Text('🏗️ Estrutura dos dados no Firebase'),
                    Text('📊 Contadores e estatísticas'),
                    Text('🧪 Criação de notificações de teste'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            const Card(
              color: Colors.yellow,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ IMPORTANTE:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('Veja os resultados no CONSOLE/DEBUG do seu IDE'),
                    Text('Os logs aparecem na saída de debug, não na tela'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}