import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper para verificar status de certificação de forma segura
class CertificationStatusHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Verifica se o usuário tem certificação aprovada
  /// Retorna de forma segura para evitar erro INTERNAL ASSERTION FAILED
  static Future<bool> hasApprovedCertification(String userId) async {
    try {
      print('🔍 Verificando certificação para userId: $userId');

      // PRIMEIRO: Verificar TODAS as certificações aprovadas
      final allApproved = await _firestore
          .collection('spiritual_certifications')
          .where('status', isEqualTo: 'approved')
          .get();

      print(
          '📊 Total de certificações aprovadas no sistema: ${allApproved.docs.length}');

      if (allApproved.docs.isNotEmpty) {
        print('📋 Listando todas as certificações aprovadas:');
        for (var doc in allApproved.docs) {
          final data = doc.data();
          print('   - Doc ID: ${doc.id}');
          print('     UserId: ${data['userId']}');
          print('     Email: ${data['userEmail']}');
          print('     Status: ${data['status']}');
        }
      }

      // SEGUNDO: Buscar específica do usuário
      final snapshot = await _firestore
          .collection('spiritual_certifications')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'approved')
          .limit(1)
          .get();

      print(
          '📊 Documentos encontrados para userId $userId: ${snapshot.docs.length}');

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        print('✅ Certificação aprovada encontrada:');
        print('   - ID: ${doc.id}');
        print('   - Status: ${doc.data()['status']}');
        print('   - UserId: ${doc.data()['userId']}');
      } else {
        print('⚠️ Nenhuma certificação aprovada encontrada para este userId');
        print('💡 Dica: Verifique se o userId no Firestore está correto');
      }

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Erro ao verificar certificação: $e');
      return false; // Em caso de erro, retorna false
    }
  }

  /// Retorna o status da certificação para exibição
  /// - "Aprovado" se certificação aprovada
  /// - "Destaque seu Perfil" caso contrário
  static Future<String> getCertificationDisplayStatus(String userId) async {
    try {
      final hasApproved = await hasApprovedCertification(userId);
      return hasApproved ? 'Aprovado' : 'Destaque seu Perfil';
    } catch (e) {
      print('❌ Erro ao obter status: $e');
      return 'Destaque seu Perfil';
    }
  }

  /// Verifica se o usuário tem certificação pendente
  static Future<bool> hasPendingCertification(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('spiritual_certifications')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Erro ao verificar certificação pendente: $e');
      return false;
    }
  }
}
