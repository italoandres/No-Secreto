import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum UsernameAvailability {
  available,
  unavailable,
  checking,
  error
}

class UsernameRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Verifica se um username está disponível
  static Future<bool> isUsernameAvailable(String username) async {
    try {
      String cleanUsername = username.replaceAll('@', '').toLowerCase().trim();
      
      if (cleanUsername.isEmpty) {
        return false;
      }
      
      // Verificar na coleção de usernames
      DocumentSnapshot doc = await _firestore
          .collection('usernames')
          .doc(cleanUsername)
          .get();
      
      return !doc.exists;
    } catch (e) {
      print('DEBUG USERNAME: Erro ao verificar disponibilidade: $e');
      return false;
    }
  }
  
  /// Salva um username para um usuário
  static Future<void> saveUsername(String userId, String username) async {
    try {
      String cleanUsername = username.replaceAll('@', '').toLowerCase().trim();
      
      if (cleanUsername.isEmpty) {
        throw Exception('Username não pode estar vazio');
      }
      
      // Usar transação para garantir atomicidade
      await _firestore.runTransaction((transaction) async {
        // Verificar se username ainda está disponível
        DocumentReference usernameRef = _firestore.collection('usernames').doc(cleanUsername);
        DocumentSnapshot usernameDoc = await transaction.get(usernameRef);
        
        if (usernameDoc.exists) {
          Map<String, dynamic> data = usernameDoc.data() as Map<String, dynamic>;
          if (data['userId'] != userId) {
            throw Exception('Username não está mais disponível');
          }
        }
        
        // Buscar username anterior do usuário para limpeza
        DocumentReference userRef = _firestore.collection('usuarios').doc(userId);
        DocumentSnapshot userDoc = await transaction.get(userRef);
        
        String? oldUsername;
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          oldUsername = userData['username'];
        }
        
        // Remover username anterior se existir
        if (oldUsername != null && oldUsername.isNotEmpty) {
          String oldCleanUsername = oldUsername.replaceAll('@', '').toLowerCase().trim();
          if (oldCleanUsername != cleanUsername) {
            DocumentReference oldUsernameRef = _firestore.collection('usernames').doc(oldCleanUsername);
            transaction.delete(oldUsernameRef);
          }
        }
        
        // Salvar novo username
        transaction.set(usernameRef, {
          'userId': userId,
          'username': cleanUsername,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        // Atualizar perfil do usuário
        transaction.update(userRef, {
          'username': cleanUsername,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      
      print('DEBUG USERNAME: Username $cleanUsername salvo para usuário $userId');
    } catch (e) {
      print('DEBUG USERNAME: Erro ao salvar username: $e');
      rethrow;
    }
  }
  
  /// Remove um username
  static Future<void> deleteUsername(String username) async {
    try {
      String cleanUsername = username.replaceAll('@', '').toLowerCase().trim();
      
      if (cleanUsername.isEmpty) {
        return;
      }
      
      await _firestore.collection('usernames').doc(cleanUsername).delete();
      print('DEBUG USERNAME: Username $cleanUsername removido');
    } catch (e) {
      print('DEBUG USERNAME: Erro ao remover username: $e');
      rethrow;
    }
  }
  
  /// Busca o username de um usuário pelo ID
  static Future<String?> getUsernameByUserId(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('usuarios').doc(userId).get();
      
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['username'];
      }
      
      return null;
    } catch (e) {
      print('DEBUG USERNAME: Erro ao buscar username por ID: $e');
      return null;
    }
  }
  
  /// Busca o ID do usuário por username
  static Future<String?> getUserIdByUsername(String username) async {
    try {
      String cleanUsername = username.replaceAll('@', '').toLowerCase().trim();
      
      if (cleanUsername.isEmpty) {
        return null;
      }
      
      DocumentSnapshot doc = await _firestore.collection('usernames').doc(cleanUsername).get();
      
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['userId'];
      }
      
      return null;
    } catch (e) {
      print('DEBUG USERNAME: Erro ao buscar ID por username: $e');
      return null;
    }
  }
  
  /// Verifica se o usuário atual pode usar um username
  static Future<bool> canUserUseUsername(String username) async {
    try {
      String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        return false;
      }
      
      String cleanUsername = username.replaceAll('@', '').toLowerCase().trim();
      
      // Verificar se username está disponível ou já pertence ao usuário atual
      DocumentSnapshot doc = await _firestore.collection('usernames').doc(cleanUsername).get();
      
      if (!doc.exists) {
        return true; // Disponível
      }
      
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return data['userId'] == currentUserId; // Já pertence ao usuário atual
    } catch (e) {
      print('DEBUG USERNAME: Erro ao verificar se usuário pode usar username: $e');
      return false;
    }
  }
  
  /// Limpa usernames órfãos (sem usuário correspondente)
  static Future<void> cleanupOrphanedUsernames() async {
    try {
      QuerySnapshot usernamesSnapshot = await _firestore.collection('usernames').get();
      
      for (DocumentSnapshot usernameDoc in usernamesSnapshot.docs) {
        Map<String, dynamic> data = usernameDoc.data() as Map<String, dynamic>;
        String userId = data['userId'];
        
        // Verificar se usuário ainda existe
        DocumentSnapshot userDoc = await _firestore.collection('usuarios').doc(userId).get();
        
        if (!userDoc.exists) {
          // Usuário não existe mais, remover username
          await usernameDoc.reference.delete();
          print('DEBUG USERNAME: Username órfão removido: ${usernameDoc.id}');
        }
      }
    } catch (e) {
      print('DEBUG USERNAME: Erro na limpeza de usernames órfãos: $e');
    }
  }
}