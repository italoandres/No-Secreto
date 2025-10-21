import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Ferramenta de diagnóstico para notificações de interesse
class DiagnoseInterestNotifications {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Executar diagnóstico completo
  static Future<void> runFullDiagnosis() async {
    print('\n🔍 ========== DIAGNÓSTICO DE NOTIFICAÇÕES ==========\n');
    
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print('❌ Usuário não está logado');
      return;
    }
    
    print('👤 Usuário atual: ${currentUser.uid}');
    print('📧 Email: ${currentUser.email}\n');
    
    await _checkAllNotifications(currentUser.uid);
    await _checkFilteredNotifications(currentUser.uid);
    await _simulateFilters(currentUser.uid);
    
    print('\n🔍 ========== FIM DO DIAGNÓSTICO ==========\n');
  }
  
  /// Verificar todas as notificações do usuário
  static Future<void> _checkAllNotifications(String userId) async {
    print('📊 1. VERIFICANDO TODAS AS NOTIFICAÇÕES\n');
    
    try {
      final query = await _firestore
          .collection('interest_notifications')
          .where('toUserId', isEqualTo: userId)
          .get();
      
      print('   Total de notificações encontradas: ${query.docs.length}\n');
      
      if (query.docs.isEmpty) {
        print('   ⚠️ Nenhuma notificação encontrada para este usuário\n');
        return;
      }
      
      for (var doc in query.docs) {
        final data = doc.data();
        print('   📋 Notificação ID: ${doc.id}');
        print('      - Tipo: ${data['type'] ?? 'N/A'}');
        print('      - Status: ${data['status'] ?? 'N/A'}');
        print('      - De: ${data['fromUserName'] ?? 'N/A'} (${data['fromUserId'] ?? 'N/A'})');
        print('      - Mensagem: ${data['message'] ?? 'N/A'}');
        print('      - Data: ${data['dataCriacao'] ?? 'N/A'}');
        print('');
      }
    } catch (e) {
      print('   ❌ Erro ao buscar notificações: $e\n');
    }
  }
  
  /// Verificar notificações após aplicar filtros
  static Future<void> _checkFilteredNotifications(String userId) async {
    print('🔍 2. VERIFICANDO NOTIFICAÇÕES FILTRADAS\n');
    
    try {
      final query = await _firestore
          .collection('interest_notifications')
          .where('toUserId', isEqualTo: userId)
          .get();
      
      const validTypes = ['interest', 'acceptance', 'mutual_match'];
      const validStatuses = ['pending', 'viewed', 'new'];
      
      print('   Filtros aplicados:');
      print('   - Tipos válidos: $validTypes');
      print('   - Status válidos: $validStatuses\n');
      
      int passedFilter = 0;
      int failedFilter = 0;
      
      for (var doc in query.docs) {
        final data = doc.data();
        final type = data['type'] ?? 'interest';
        final status = data['status'] ?? 'pending';
        
        final isValidType = validTypes.contains(type);
        final isValidStatus = validStatuses.contains(status);
        
        if (isValidType && isValidStatus) {
          passedFilter++;
          print('   ✅ PASSOU: ID=${doc.id}, type=$type, status=$status');
        } else {
          failedFilter++;
          print('   ❌ FALHOU: ID=${doc.id}, type=$type, status=$status');
          if (!isValidType) print('      Motivo: Tipo inválido');
          if (!isValidStatus) print('      Motivo: Status inválido');
        }
      }
      
      print('\n   📊 Resultado:');
      print('      - Passaram no filtro: $passedFilter');
      print('      - Falharam no filtro: $failedFilter\n');
      
    } catch (e) {
      print('   ❌ Erro ao filtrar notificações: $e\n');
    }
  }
  
  /// Simular aplicação de diferentes filtros
  static Future<void> _simulateFilters(String userId) async {
    print('🧪 3. SIMULANDO DIFERENTES FILTROS\n');
    
    try {
      final query = await _firestore
          .collection('interest_notifications')
          .where('toUserId', isEqualTo: userId)
          .get();
      
      if (query.docs.isEmpty) {
        print('   ⚠️ Nenhuma notificação para simular\n');
        return;
      }
      
      // Filtro 1: Apenas pending
      final pendingOnly = query.docs.where((doc) {
        final status = doc.data()['status'] ?? 'pending';
        return status == 'pending';
      }).length;
      print('   Filtro 1 (status=pending): $pendingOnly notificações');
      
      // Filtro 2: Pending ou viewed
      final pendingOrViewed = query.docs.where((doc) {
        final status = doc.data()['status'] ?? 'pending';
        return status == 'pending' || status == 'viewed';
      }).length;
      print('   Filtro 2 (status=pending|viewed): $pendingOrViewed notificações');
      
      // Filtro 3: Pending, viewed ou new
      final allStatuses = query.docs.where((doc) {
        final status = doc.data()['status'] ?? 'pending';
        return status == 'pending' || status == 'viewed' || status == 'new';
      }).length;
      print('   Filtro 3 (status=pending|viewed|new): $allStatuses notificações');
      
      // Filtro 4: Tipo interest
      final interestType = query.docs.where((doc) {
        final type = doc.data()['type'] ?? 'interest';
        return type == 'interest';
      }).length;
      print('   Filtro 4 (type=interest): $interestType notificações');
      
      // Filtro 5: Tipo interest + status pending
      final interestPending = query.docs.where((doc) {
        final type = doc.data()['type'] ?? 'interest';
        final status = doc.data()['status'] ?? 'pending';
        return type == 'interest' && status == 'pending';
      }).length;
      print('   Filtro 5 (type=interest + status=pending): $interestPending notificações');
      
      // Filtro 6: Todos os tipos válidos + todos os status válidos
      const validTypes = ['interest', 'acceptance', 'mutual_match'];
      const validStatuses = ['pending', 'viewed', 'new'];
      final allValid = query.docs.where((doc) {
        final type = doc.data()['type'] ?? 'interest';
        final status = doc.data()['status'] ?? 'pending';
        return validTypes.contains(type) && validStatuses.contains(status);
      }).length;
      print('   Filtro 6 (todos tipos + status válidos): $allValid notificações\n');
      
    } catch (e) {
      print('   ❌ Erro ao simular filtros: $e\n');
    }
  }
  
  /// Gerar relatório de diagnóstico
  static Future<String> generateReport() async {
    final buffer = StringBuffer();
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      return 'Usuário não está logado';
    }
    
    buffer.writeln('RELATÓRIO DE DIAGNÓSTICO DE NOTIFICAÇÕES');
    buffer.writeln('=' * 50);
    buffer.writeln('Usuário: ${currentUser.uid}');
    buffer.writeln('Email: ${currentUser.email}');
    buffer.writeln('Data: ${DateTime.now()}');
    buffer.writeln('=' * 50);
    buffer.writeln('');
    
    try {
      final query = await _firestore
          .collection('interest_notifications')
          .where('toUserId', isEqualTo: currentUser.uid)
          .get();
      
      buffer.writeln('Total de notificações: ${query.docs.length}');
      buffer.writeln('');
      
      const validTypes = ['interest', 'acceptance', 'mutual_match'];
      const validStatuses = ['pending', 'viewed', 'new'];
      
      int valid = 0;
      int invalid = 0;
      
      for (var doc in query.docs) {
        final data = doc.data();
        final type = data['type'] ?? 'interest';
        final status = data['status'] ?? 'pending';
        
        final isValid = validTypes.contains(type) && validStatuses.contains(status);
        
        if (isValid) {
          valid++;
        } else {
          invalid++;
        }
        
        buffer.writeln('Notificação ${doc.id}:');
        buffer.writeln('  - Tipo: $type');
        buffer.writeln('  - Status: $status');
        buffer.writeln('  - Válida: ${isValid ? "SIM" : "NÃO"}');
        buffer.writeln('');
      }
      
      buffer.writeln('=' * 50);
      buffer.writeln('RESUMO:');
      buffer.writeln('  - Notificações válidas: $valid');
      buffer.writeln('  - Notificações inválidas: $invalid');
      buffer.writeln('=' * 50);
      
    } catch (e) {
      buffer.writeln('ERRO: $e');
    }
    
    return buffer.toString();
  }
}
