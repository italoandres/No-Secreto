import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Serviço para gerenciar o status online dos usuários
class OnlineStatusService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// Atualiza o lastSeen do usuário atual
  static Future<void> updateLastSeen() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;
      
      await _firestore
          .collection('usuarios')
          .doc(currentUser.uid)
          .update({
        'lastSeen': FieldValue.serverTimestamp(),
      });
      
      print('✅ LastSeen atualizado para ${currentUser.uid}');
    } catch (e) {
      print('⚠️ Erro ao atualizar lastSeen: $e');
    }
  }
  
  /// Marca o usuário como online (chamado quando o app abre)
  static Future<void> setUserOnline() async {
    await updateLastSeen();
  }
  
  /// Marca o usuário como offline (chamado quando o app fecha)
  static Future<void> setUserOffline() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;
      
      // Atualiza o lastSeen para o momento atual antes de sair
      await _firestore
          .collection('usuarios')
          .doc(currentUser.uid)
          .update({
        'lastSeen': FieldValue.serverTimestamp(),
      });
      
      print('✅ Usuário ${currentUser.uid} marcado como offline');
    } catch (e) {
      print('⚠️ Erro ao marcar usuário como offline: $e');
    }
  }
}
