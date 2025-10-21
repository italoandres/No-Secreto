import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:whatsapp_chat/token_usuario.dart';
import 'package:whatsapp_chat/models/usuario_model.dart';

class DebugUserState {
  static Future<void> printCurrentUserState() async {
    print('=== DEBUG USER STATE ===');
    
    // 1. Firebase Auth
    final currentUser = FirebaseAuth.instance.currentUser;
    print('Firebase Auth User: ${currentUser?.uid}');
    print('Firebase Auth Email: ${currentUser?.email}');
    
    // 2. TokenUsuario (SharedPreferences) - ANTES da correção
    final tokenSexoAntes = TokenUsuario().sexo;
    print('TokenUsuario Sexo (ANTES): $tokenSexoAntes');
    print('TokenUsuario Idioma: ${TokenUsuario().idioma}');
    
    // 3. Firestore User Document (FONTE DE VERDADE)
    String? firestoreSexo;
    if (currentUser != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(currentUser.uid)
            .get();
            
        if (userDoc.exists) {
          final userData = userDoc.data();
          firestoreSexo = userData?['sexo'];
          print('Firestore User Data (FONTE DE VERDADE):');
          print('  - sexo: $firestoreSexo');
          print('  - nome: ${userData?['nome']}');
          print('  - email: ${userData?['email']}');
          print('  - isAdmin: ${userData?['isAdmin']}');
          
          // Converter para modelo
          final userModel = UsuarioModel.fromJson(userData!);
          print('UserModel Sexo: ${userModel.sexo}');
          
          // 4. DETECTAR INCONSISTÊNCIA
          if (firestoreSexo != null && firestoreSexo != 'none') {
            final firestoreSexoEnum = UserSexo.values.firstWhere(
              (e) => e.name == firestoreSexo,
              orElse: () => UserSexo.none
            );
            
            if (tokenSexoAntes != firestoreSexoEnum) {
              print('🚨 INCONSISTÊNCIA DETECTADA!');
              print('   TokenUsuario: $tokenSexoAntes');
              print('   Firestore: $firestoreSexoEnum');
              print('   → Firestore é a fonte de verdade');
            } else {
              print('✅ DADOS CONSISTENTES');
            }
          }
        } else {
          print('Firestore: User document does not exist!');
        }
      } catch (e) {
        print('Error reading Firestore: $e');
      }
    }
    
    // 5. TokenUsuario (SharedPreferences) - DEPOIS da correção automática
    final tokenSexoDepois = TokenUsuario().sexo;
    if (tokenSexoAntes != tokenSexoDepois) {
      print('🔄 CORREÇÃO APLICADA:');
      print('   Antes: $tokenSexoAntes');
      print('   Depois: $tokenSexoDepois');
    }
    
    print('=== END DEBUG ===');
  }
  
  static Future<void> fixUserSexo() async {
    print('=== FIXING USER SEXO ===');
    
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print('No authenticated user');
      return;
    }
    
    try {
      // Ler sexo do Firestore (fonte de verdade)
      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(currentUser.uid)
          .get();
          
      if (!userDoc.exists) {
        print('User document does not exist in Firestore');
        return;
      }
      
      final userData = userDoc.data();
      final firestoreSexoString = userData?['sexo'] as String?;
      
      print('Sexo from Firestore (source of truth): $firestoreSexoString');
      print('Sexo from TokenUsuario (before fix): ${TokenUsuario().sexo}');
      
      if (firestoreSexoString != null && firestoreSexoString != 'none') {
        // Converter string para enum
        final firestoreSexo = UserSexo.values.firstWhere(
          (e) => e.name == firestoreSexoString,
          orElse: () => UserSexo.none
        );
        
        // Atualizar TokenUsuario com valor do Firestore
        if (TokenUsuario().sexo != firestoreSexo) {
          TokenUsuario().sexo = firestoreSexo;
          print('✅ TokenUsuario updated with Firestore value: ${firestoreSexo.name}');
        } else {
          print('✅ TokenUsuario already synchronized with Firestore');
        }
      } else {
        print('⚠️ Firestore sexo is null or none - user may need to complete profile');
      }
    } catch (e) {
      print('Error fixing user sexo: $e');
    }
    
    print('=== FIX COMPLETE ===');
  }
}