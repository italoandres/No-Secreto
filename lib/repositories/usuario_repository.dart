import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:whatsapp_chat/locale/language.dart';
import 'package:whatsapp_chat/token_usuario.dart';
import 'package:whatsapp_chat/views/home_view.dart';
import 'package:whatsapp_chat/views/welcome_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../views/login_view.dart';
import '../models/usuario_model.dart';
import '../services/data_migration_service.dart';
import '../utils/enhanced_logger.dart';

class UsuarioRepository {

  // Lista de emails que são automaticamente admin
  static const List<String> adminEmails = [
    'italolior@gmail.com',
    'deusepaimovement@gmail.com',
  ];

  // Helper para verificar se um email é admin
  static bool _isAdminEmail(String? email) {
    if (email == null) return false;
    return adminEmails.contains(email.toLowerCase().trim());
  }

  // Helper para navegar após completar perfil
  static Future<void> _navigateAfterAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final welcomeShown = prefs.getBool('welcome_shown') ?? false;
    
    if (!welcomeShown) {
      debugPrint('UsuarioRepository: Mostrando WelcomeView (slide5)');
      Get.offAll(() => const WelcomeView());
    } else {
      debugPrint('UsuarioRepository: Welcome já visto, indo direto para HomeView');
      Get.offAll(() => const HomeView());
    }
  }

  static Stream<UsuarioModel?> getUser() {

    return FirebaseFirestore.instance.collection('usuarios').doc(FirebaseAuth.instance.currentUser == null ? 'deletado' : FirebaseAuth.instance.currentUser!.uid).snapshots().asyncMap((event) async {
      if(event.exists == false) {
        await FirebaseAuth.instance.signOut();
        FirebaseAuth.instance.authStateChanges();
        Future.delayed(Duration.zero, () => Get.offAll(() => const LoginView()));
        return null;
      }

      // Migrar dados do usuário se necessário
      final rawData = event.data()!;
      final migratedData = await DataMigrationService.migrateUserData(event.id, rawData);
      
      UsuarioModel u = UsuarioModel.fromJson(migratedData);
      u.id = event.id;

      // Verificar se o status de admin precisa ser atualizado
      final shouldBeAdmin = _isAdminEmail(u.email);
      final currentIsAdmin = u.isAdmin ?? false;
      
      if (shouldBeAdmin != currentIsAdmin) {
        EnhancedLogger.info('Updating admin status for user', tag: 'USER', data: {
          'email': u.email,
          'newStatus': shouldBeAdmin
        });
        // Atualizar no Firestore
        FirebaseFirestore.instance.collection('usuarios').doc(u.id).update({
          'isAdmin': shouldBeAdmin,
        });
        // Atualizar no modelo local
        u.isAdmin = shouldBeAdmin;
      }

      // CORREÇÃO: Sincronizar TokenUsuario com valor do Firestore (fonte de verdade)
      final sexoFromFirestore = u.sexo ?? UserSexo.none;
      
      // Se o Firestore tem um sexo válido, garantir que TokenUsuario está sincronizado
      if (sexoFromFirestore != UserSexo.none) {
        if (TokenUsuario().sexo != sexoFromFirestore) {
          EnhancedLogger.sync('Synchronizing TokenUsuario with Firestore', u.id!, data: {
            'from': TokenUsuario().sexo.name,
            'to': sexoFromFirestore.name
          });
          TokenUsuario().sexo = sexoFromFirestore;
        }
      }

      TokenUsuario().isAdmin = u.isAdmin!;
      TokenUsuario().sexo = u.sexo!;
      
      EnhancedLogger.debug('User data loaded', tag: 'USER', data: {
        'userId': u.id,
        'nome': u.nome,
        'username': u.username,
        'email': u.email,
        'hasPhoto': u.imgUrl != null,
      });
      
      return u;
    });
  }

  // ============================================================================
  // 🚀 OTIMIZADO: getAll() com limit e pagination
  // ============================================================================
  
  /// Busca usuários com limit e pagination
  /// 
  /// [limit] - Número máximo de usuários a retornar (padrão: 20)
  /// [lastDocument] - Último documento da página anterior (para pagination)
  /// [orderByField] - Campo para ordenar (padrão: 'nome')
  /// [descending] - Ordem descendente (padrão: false)
  static Future<List<UsuarioModel>> getAll({
    int limit = 20,
    DocumentSnapshot? lastDocument,
    String orderByField = 'nome',
    bool descending = false,
  }) async {
    List<UsuarioModel> all = [];

    try {
      Query query = FirebaseFirestore.instance
          .collection('usuarios')
          .orderBy(orderByField, descending: descending)
          .limit(limit);

      // Pagination: começar depois do último documento
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      
      for (var element in snapshot.docs) {
        try {
          UsuarioModel u = UsuarioModel.fromJson(element.data() as Map<String, dynamic>);
          u.id = element.id;
          all.add(u);
        } catch (e) {
          debugPrint('Erro ao processar usuário ${element.id}: $e');
        }
      }

      debugPrint('UsuarioRepository: ${all.length} usuários carregados (limit: $limit)');

      return all;
    } catch (e) {
      debugPrint('UsuarioRepository: Erro ao buscar usuários: $e');
      return [];
    }
  }

  /// Busca usuários com filtro de sexo (para explore profiles)
  static Future<List<UsuarioModel>> getUsersBySexo({
    required UserSexo sexo,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    List<UsuarioModel> all = [];

    try {
      Query query = FirebaseFirestore.instance
          .collection('usuarios')
          .where('sexo', isEqualTo: sexo.name)
          .where('perfilIsComplete', isEqualTo: true)
          .orderBy('nome')
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      
      for (var element in snapshot.docs) {
        try {
          UsuarioModel u = UsuarioModel.fromJson(element.data() as Map<String, dynamic>);
          u.id = element.id;
          all.add(u);
        } catch (e) {
          debugPrint('Erro ao processar usuário: $e');
        }
      }

      debugPrint('UsuarioRepository: ${all.length} usuários (sexo: ${sexo.name}) carregados');

      return all;
    } catch (e) {
      debugPrint('UsuarioRepository: Erro ao buscar usuários por sexo: $e');
      return [];
    }
  }

  /// Busca próxima página de usuários
  static Future<List<UsuarioModel>> getNextPage(DocumentSnapshot lastDocument) async {
    return getAll(
      limit: 20,
      lastDocument: lastDocument,
    );
  }

  // ============================================================================

  static Future<bool> validateSenha(String senha) async {

    Get.defaultDialog(
      title: AppLanguage.lang('validando'),
      content: const CircularProgressIndicator(),
      barrierDismissible: false
    );
    
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: FirebaseAuth.instance.currentUser!.email!,
        password: senha
      );
      
      Get.back();
      return true;
    } on FirebaseAuthException catch (e) {

      Get.back();
      debugPrint(e.code);
      debugPrint(e.message);
      
      return false;
    } catch(e) {
      debugPrint('$e');
      return false;
    }
  }

  static Future<void> completarPerfil({
    required Uint8List? imgData,
    required Uint8List? imgBgData,
    required UserSexo sexo,
  }) async {
    
    if(imgData != null) {
      Get.defaultDialog(
        title: AppLanguage.lang('validando_img_perfil'),
        content: const CircularProgressIndicator(),
        barrierDismissible: false
      );
      await FirebaseFirestore.instance.collection('usuarios').doc(FirebaseAuth.instance.currentUser!.uid).update({
        'imgUrl': await _uploadFile(imgData),
      });

      Get.back();
    }

    if(imgBgData != null) {
      Get.defaultDialog(
        title: AppLanguage.lang('validando_papel'),
        content: const CircularProgressIndicator(),
        barrierDismissible: false
      );
      
      print('DEBUG REPO: Fazendo upload do papel de parede...');
      String imgBgUrl = await _uploadFile(imgBgData);
      print('DEBUG REPO: URL do papel de parede: $imgBgUrl');
      
      await FirebaseFirestore.instance.collection('usuarios').doc(FirebaseAuth.instance.currentUser!.uid).update({
        'imgBgUrl': imgBgUrl,
      });
      
      print('DEBUG REPO: Papel de parede salvo no Firestore!');

      Get.back();
    }

    Get.defaultDialog(
      title: AppLanguage.lang('finalizando'),
      content: const CircularProgressIndicator(),
      barrierDismissible: false
    );
    await FirebaseFirestore.instance.collection('usuarios').doc(FirebaseAuth.instance.currentUser!.uid).update({
      'perfilIsComplete': true,
      'sexo': sexo.name
    });
    
    await _navigateAfterAuth();
  }

  static Future<String> _uploadFile(Uint8List fileData) async {

    Reference ref = FirebaseStorage.instance.ref().child('usuarios/${DateTime.now().millisecondsSinceEpoch}.png');

    final snapshot = ref.putData(fileData, SettableMetadata(contentType: 'image/png'));
    snapshot.snapshotEvents.listen((event) {});

    await snapshot;
    return await ref.getDownloadURL();
  }

  /// Atualiza dados do usuário atual
  static Future<void> updateUser(Map<String, dynamic> data) async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception('Usuário não autenticado');
    }

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .update(data);
  }
  
  /// Sincroniza o status de admin de todos os usuários baseado na lista de emails admin
  static Future<void> syncAllUsersAdminStatus() async {
    try {
      debugPrint('UsuarioRepository: Iniciando sincronização de status admin');
      
      final querySnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .get();
      
      int updatedCount = 0;
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final email = data['email'] as String?;
        final currentIsAdmin = data['isAdmin'] ?? false;
        final shouldBeAdmin = _isAdminEmail(email);
        
        if (shouldBeAdmin != currentIsAdmin) {
          await doc.reference.update({'isAdmin': shouldBeAdmin});
          updatedCount++;
          debugPrint('UsuarioRepository: Updated admin status for $email to $shouldBeAdmin');
        }
      }
      
      debugPrint('UsuarioRepository: Sincronização concluída. $updatedCount usuários atualizados.');
    } catch (e) {
      debugPrint('UsuarioRepository: Erro na sincronização: $e');
    }
  }

  /// Obtém dados de um usuário específico por ID
  static Future<UsuarioModel?> getUserById(String userId) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .get();
      
      if (doc.exists) {
        UsuarioModel user = UsuarioModel.fromJson(doc.data() as Map<String, dynamic>);
        user.id = doc.id;
        return user;
      }
      
      return null;
    } catch (e) {
      print('DEBUG USUARIO: Erro ao buscar usuário por ID: $e');
      return null;
    }
  }
}