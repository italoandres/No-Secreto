import 'package:crypto/crypto.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_admin/firebase_admin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:whatsapp_chat/locale/language.dart';
import 'package:whatsapp_chat/models/storie_file_model.dart';
import 'package:whatsapp_chat/models/usuario_model.dart';
import 'package:whatsapp_chat/repositories/stories_repository.dart';
import '/repositories/usuario_repository.dart';
import '/views/login_view.dart';
import '/views/welcome_view.dart';
import '/token_usuario.dart';

import '../controllers/login_controller.dart';
import '../views/home_view.dart';

class LoginRepository {
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

  // Helper para navegar após login/inscrição
  static Future<void> _navigateAfterAuth() async {
    debugPrint('=== INÍCIO _navigateAfterAuth ===');

    try {
      // CORREÇÃO: Validar e sincronizar sexo do Firestore para TokenUsuario
      await _validateAndSyncUserSexo();

      final prefs = await SharedPreferences.getInstance();
      debugPrint('✅ SharedPreferences obtido');

      final welcomeShown = prefs.getBool('welcome_shown') ?? false;
      debugPrint('Welcome shown: $welcomeShown');

      if (!welcomeShown) {
        debugPrint('LoginRepository: Mostrando WelcomeView (slide5)');
        Get.offAll(() => const WelcomeView());
        debugPrint('✅ Navegação para WelcomeView executada');
      } else {
        debugPrint(
            'LoginRepository: Welcome já visto, indo direto para HomeView');
        Get.offAll(() => const HomeView());
        debugPrint('✅ Navegação para HomeView executada');
      }
    } catch (e) {
      debugPrint('❌ Erro em _navigateAfterAuth: $e');
      // Fallback para HomeView em caso de erro
      Get.offAll(() => const HomeView());
    }

    debugPrint('=== FIM _navigateAfterAuth ===');
  }

  // Helper para validar e sincronizar sexo do Firestore para TokenUsuario
  static Future<void> _validateAndSyncUserSexo() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      debugPrint('🔍 Validando sexo do usuário...');

      // Ler sexo do Firestore (fonte de verdade)
      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) {
        debugPrint('❌ Documento do usuário não existe no Firestore');
        return;
      }

      final userData = userDoc.data();
      final firestoreSexoString = userData?['sexo'] as String?;

      debugPrint('📊 Sexo no Firestore: $firestoreSexoString');
      debugPrint('📊 Sexo no TokenUsuario: ${TokenUsuario().sexo.name}');

      if (firestoreSexoString != null && firestoreSexoString != 'none') {
        // Converter string para enum
        UserSexo firestoreSexo;
        try {
          firestoreSexo = UserSexo.values.firstWhere(
              (e) => e.name == firestoreSexoString,
              orElse: () => UserSexo.none);
        } catch (e) {
          debugPrint('❌ Erro ao converter sexo do Firestore: $e');
          return;
        }

        // Verificar se precisa atualizar TokenUsuario
        if (TokenUsuario().sexo != firestoreSexo) {
          debugPrint(
              '🔄 Atualizando TokenUsuario: ${TokenUsuario().sexo.name} → ${firestoreSexo.name}');
          TokenUsuario().sexo = firestoreSexo;
          debugPrint(
              '✅ TokenUsuario atualizado com valor do Firestore: ${firestoreSexo.name}');
        } else {
          debugPrint('✅ Sexo já está sincronizado: ${firestoreSexo.name}');
        }
      } else {
        debugPrint(
            '⚠️ Sexo não definido no Firestore - usuário pode precisar completar perfil');
      }
    } catch (e) {
      debugPrint('❌ Erro ao validar sexo: $e');
    }
  }

  static App? appFirebaseAdmin;

  static Future<bool> initFirebaseAdmin() async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/service-account.json');
    final String response =
        await rootBundle.loadString('lib/assets/outros/service-account.json');

    final data = jsonEncode(
        json.decode(response)); // source from original service-account.json
    await file.writeAsString(data);
    final credential = FirebaseAdmin.instance.certFromPath(file.path);

    appFirebaseAdmin = FirebaseAdmin.instance.initializeApp(
      AppOptions(
        credential: credential,
        projectId: "no-secreto-com-deus-pai",
      ),
    );

    return true;
  }

  static String generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Returns the sha256 hash of [input] in hex notation.
  static String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static Future<void> loginComGoogle() async {
    debugPrint('Google Sign-In: Starting authentication process');

    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: ['email'],
    );

    try {
      debugPrint('Google Sign-In: Calling googleSignIn.signIn()');
      GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('Google Sign-In: User cancelled the sign-in');
        return;
      }

      debugPrint('Google Sign-In: User signed in: ${googleUser.email}');
      GoogleSignInAuthentication? googleAuth = await googleUser.authentication;

      if (googleAuth == null) {
        debugPrint('Google Sign-In: Authentication is null');
        return;
      }

      debugPrint('Google Sign-In: Got authentication tokens');
      debugPrint(
          'Google Sign-In: idToken available: ${googleAuth.idToken != null}');

      OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      debugPrint('Google Sign-In: Creating Firebase credential');
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user == null) {
        debugPrint('Google Sign-In: Firebase user is null');
        Get.rawSnackbar(
            message: AppLanguage.lang('falha_ao_entrar_com_google'));
        return;
      }

      debugPrint('Google Sign-In: Firebase authentication successful');

      Get.defaultDialog(
          title: AppLanguage.lang('validando'),
          content: const CircularProgressIndicator(),
          barrierDismissible: false);

      final query = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userCredential.user!.uid)
          .get();

      debugPrint('Google Sign-In: User authenticated successfully');
      debugPrint('Google Sign-In: User ID: ${userCredential.user!.uid}');
      debugPrint('Google Sign-In: User exists in Firestore: ${query.exists}');

      if (!query.exists) {
        debugPrint('Google Sign-In: Creating new user document');
        // Create new user document with basic information from Firebase Auth
        final userEmail = userCredential.user?.email;
        final isAdmin = _isAdminEmail(userEmail);

        debugPrint('Google Sign-In: Email: $userEmail, IsAdmin: $isAdmin');

        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(userCredential.user!.uid)
            .set({
          'nome': userCredential.user?.displayName ?? 'Usuário Google',
          'email': userEmail,
          'dataCadastro': DateTime.now(),
          'imgUrl':
              '', // Skip profile picture for web to avoid People API issues
          'isAdmin': isAdmin, // Definir admin automaticamente baseado no email
        });
        setStoriesAntigos();
        Get.back();
        debugPrint('Google Sign-In: Showing password setup dialog');
        _cadastrarSenha();
        return; // Important: return here to prevent further execution
      }

      if (query.exists) {
        debugPrint('Google Sign-In: User exists, checking password status');

        // Verificar e atualizar status de admin se necessário
        final userEmail = userCredential.user?.email;
        final shouldBeAdmin = _isAdminEmail(userEmail);
        final currentIsAdmin = query.data()!['isAdmin'] ?? false;

        if (shouldBeAdmin != currentIsAdmin) {
          debugPrint(
              'Google Sign-In: Updating admin status for $userEmail to $shouldBeAdmin');
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(userCredential.user!.uid)
              .update({
            'isAdmin': shouldBeAdmin,
          });
        }

        if ('${query.data()!['senhaIsSeted']}' != 'true') {
          debugPrint(
              'Google Sign-In: Password not set, showing password setup');
          Get.back();
          _cadastrarSenha();
        } else {
          debugPrint('Google Sign-In: Password set, navigating to home');
          // Set default language if not set
          if (TokenUsuario().idioma.isEmpty) {
            TokenUsuario().idioma = 'pt';
          }
          Get.back();
          await _navigateAfterAuth();
        }
      }
    } on FirebaseAuthException catch (e) {
      Get.back();
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');

      if (e.code == 'user-disabled') {
        Get.rawSnackbar(
            message:
                AppLanguage.lang('conta_desabilitada') ?? 'Conta desabilitada');
      } else if (e.code == 'invalid-credential') {
        Get.rawSnackbar(
            message: AppLanguage.lang('credenciais_invalidas') ??
                'Credenciais inválidas');
      } else {
        Get.rawSnackbar(message: AppLanguage.lang('falha_ao_validar_acesso'));
      }
    } catch (e) {
      // Check if it's a People API error (which we can ignore for basic authentication)
      String errorMessage = e.toString();
      if (errorMessage.contains('People API') ||
          errorMessage.contains('people.googleapis.com')) {
        debugPrint('People API error (expected for demo): $e');
        // Continue with authentication flow despite People API error
        // Don't return here - let the authentication complete
      } else {
        Get.back();
        Get.rawSnackbar(message: AppLanguage.lang('falha_ao_validar_acesso'));
        debugPrint('Google Sign-In Error: $e');
        return;
      }
    }
  }

  static loginComApple() async {
    if (kIsWeb || !Platform.isIOS) {
      Get.rawSnackbar(
          message:
              'Opção temporariamente indisponível para aparelhos Android!');
      return;
    }

    final rawNonce = generateNonce();
    final nonce = sha256ofString(rawNonce);

    String? email;
    String? nome;
    String? uid;

    final credential = await SignInWithApple.getAppleIDCredential(scopes: [
      AppleIDAuthorizationScopes.email,
      AppleIDAuthorizationScopes.fullName,
    ], nonce: nonce);
    email = credential.email ?? '';
    uid = credential.userIdentifier;
    nome = credential.givenName ?? '';

    debugPrint(uid);
    debugPrint(email);
    debugPrint(nome);

    Get.defaultDialog(
        title: AppLanguage.lang('validando'),
        content: const CircularProgressIndicator(),
        barrierDismissible: false);

    final oauthCredential = OAuthProvider("apple.com").credential(
      idToken: credential.identityToken,
      rawNonce: rawNonce,
    );

    if (kDebugMode) {
      print(oauthCredential.idToken);
      print(oauthCredential.accessToken);
    }

    try {
      final nCredential =
          await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      final query = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(nCredential.user!.uid)
          .get();

      if (!query.exists) {
        String imgUrl = '';
        final isAdmin = _isAdminEmail(email);

        debugPrint('Apple Sign-In: Email: $email, IsAdmin: $isAdmin');

        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(nCredential.user!.uid)
            .set({
          'nome': nome,
          'email': email,
          'dataCadastro': DateTime.now(),
          'imgUrl': imgUrl,
          'isAdmin': isAdmin, // Definir admin automaticamente baseado no email
        });
        setStoriesAntigos();
      }

      await _navigateAfterAuth();
    } catch (e) {
      Get.back();
      Get.rawSnackbar(message: AppLanguage.lang('falha_ao_validar_acesso'));

      debugPrint('$e');
    }
  }

  static Future<void> _cadastrarSenha() async {
    final senhaController = TextEditingController();

    Get.defaultDialog(
        title: AppLanguage.lang('cadastrar_senha'),
        titlePadding: const EdgeInsets.only(top: 16),
        contentPadding: const EdgeInsets.all(16),
        content: Column(
          children: [
            Text(AppLanguage.lang('defina_senha'), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextField(
              controller: senhaController,
              textAlign: TextAlign.center,
              decoration:
                  InputDecoration(hintText: AppLanguage.lang('digite_aqui')),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: Get.width * 0.3,
            height: 45,
            child: TextButton(
                onPressed: () => Get.back(),
                child: Text(AppLanguage.lang('cancelar'))),
          ),
          SizedBox(
            width: Get.width * 0.3,
            height: 45,
            child: ElevatedButton(
                onPressed: () async {
                  if (senhaController.text.trim() != '') {
                    if (senhaController.text.length < 6) {
                      Get.rawSnackbar(
                          message: AppLanguage.lang('aviso_senha_6'));
                      return;
                    }

                    Get.defaultDialog(
                        title: AppLanguage.lang('validando'),
                        content: const CircularProgressIndicator(),
                        barrierDismissible: false);

                    try {
                      debugPrint(
                          'Password setup: Starting password setup process');

                      // Firebase Admin is not available on web, so we'll skip password update for web
                      if (!kIsWeb && appFirebaseAdmin != null) {
                        debugPrint(
                            'Password setup: Updating password via Firebase Admin');
                        await appFirebaseAdmin!.auth().updateUser(
                            FirebaseAuth.instance.currentUser!.uid,
                            password: senhaController.text);
                      } else {
                        debugPrint(
                            'Password setup: Skipping Firebase Admin password update (web or admin not available)');
                      }

                      debugPrint('Password setup: Updating Firestore document');
                      await FirebaseFirestore.instance
                          .collection('usuarios')
                          .doc(FirebaseAuth.instance.currentUser!.uid)
                          .update({'senhaIsSeted': true});

                      debugPrint('Password setup: Navigating after auth');
                      await _navigateAfterAuth();
                    } catch (e) {
                      Get.back();
                      Get.rawSnackbar(
                          message: AppLanguage.lang('error_login') ??
                              'Erro ao definir senha');
                      debugPrint('Password setup error: $e');
                    }
                  }
                },
                child: Text(AppLanguage.lang('finalizar'))),
          )
        ]);
  }

  static Future<String> _uploadFile(Uint8List fileData) async {
    Reference ref = FirebaseStorage.instance
        .ref()
        .child('usuarios/${DateTime.now().millisecondsSinceEpoch}.png');

    final snapshot =
        ref.putData(fileData, SettableMetadata(contentType: 'image/png'));
    snapshot.snapshotEvents.listen((event) {});

    await snapshot;
    return await ref.getDownloadURL();
  }

  static Future<void> login({
    required String email,
    required String senha,
  }) async {
    Get.defaultDialog(
        title: AppLanguage.lang('validando'),
        content: const CircularProgressIndicator(),
        barrierDismissible: false);

    // Timeout de 60 segundos para conexões lentas (APK em celular)
    Timer? timeoutTimer = Timer(const Duration(seconds: 60), () {
      debugPrint('❌ TIMEOUT: Login demorou mais de 60 segundos');
      if (Get.isDialogOpen == true) {
        Get.back();
        Get.rawSnackbar(
          message:
              'Login demorou muito. Verifique sua conexão e tente novamente.',
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        );
      }
    });

    try {
      debugPrint('=== INÍCIO LOGIN ===');
      debugPrint('Email: $email');

      UserCredential user = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: senha);
      debugPrint('✅ Firebase Auth OK - UID: ${user.user?.uid}');

      final query = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.user!.uid)
          .get();
      debugPrint('✅ Firestore Query OK - Exists: ${query.exists}');

      Get.back();
      if (query.exists) {
        debugPrint('✅ Usuário existe no Firestore');

        // Verificar e atualizar status de admin se necessário
        final userEmail = user.user?.email;
        final shouldBeAdmin = _isAdminEmail(userEmail);
        final currentIsAdmin = query.data()!['isAdmin'] ?? false;

        debugPrint(
            'Admin check - Email: $userEmail, Should be admin: $shouldBeAdmin, Current: $currentIsAdmin');

        Map<String, dynamic> updateData = {'senhaIsSeted': true};

        if (shouldBeAdmin != currentIsAdmin) {
          debugPrint(
              'Email Login: Updating admin status for $userEmail to $shouldBeAdmin');
          updateData['isAdmin'] = shouldBeAdmin;
        }

        debugPrint('🔄 Atualizando dados do usuário...');
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.user!.uid)
            .update(updateData);
        debugPrint('✅ Dados atualizados');

        // Set default language if not set
        if (TokenUsuario().idioma.isEmpty) {
          TokenUsuario().idioma = 'pt';
        }

        debugPrint('🧹 Limpando controller...');
        LoginController.clean();

        debugPrint('🚀 Navegando após auth...');
        await _navigateAfterAuth();
        debugPrint('✅ Navegação concluída');

        // Cancelar timeout
        timeoutTimer?.cancel();
      } else {
        debugPrint('❌ Usuário não existe no Firestore');
        Get.rawSnackbar(message: AppLanguage.lang('usuario_n_econtrado'));
        FirebaseAuth.instance.signOut();
        timeoutTimer?.cancel();
      }
    } on FirebaseAuthException catch (e) {
      Get.back();
      timeoutTimer?.cancel();
      debugPrint('❌ FirebaseAuthException: ${e.code}');
      debugPrint('❌ Mensagem: ${e.message}');

      if (e.code == 'user-not-found') {
        Get.rawSnackbar(message: AppLanguage.lang('email_incorreto'));
      } else if (e.code == 'wrong-password') {
        Get.rawSnackbar(message: AppLanguage.lang('senha_incorreta'));
      } else if (e.code == 'network-request-failed') {
        Get.rawSnackbar(
            message:
                '🌐 Erro de conexão. Verifique sua internet e tente novamente.');
      } else if (e.code == 'unknown' &&
          e.message?.contains('Connection reset by peer') == true) {
        Get.rawSnackbar(
            message:
                '🔄 Problema de conexão. Tente novamente em alguns segundos.');
      } else {
        Get.rawSnackbar(message: AppLanguage.lang('error_login'));
      }
    } catch (e) {
      Get.back();
      timeoutTimer?.cancel();
      debugPrint('❌ Erro geral no login: $e');
      Get.rawSnackbar(
        message: 'Erro inesperado no login. Tente novamente.',
        backgroundColor: Colors.red,
      );
    }
  }

  static Future<void> cadastrarComEmail({
    required String email,
    required String senha,
    required String nome,
    Uint8List? imgBgData,
    Uint8List? imgData,
    required UserSexo sexo,
  }) async {
    Get.defaultDialog(
        title: AppLanguage.lang('validando'),
        content: const CircularProgressIndicator(),
        barrierDismissible: false);

    try {
      UserCredential user = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: senha);

      final isAdmin = _isAdminEmail(email);
      debugPrint('Email Signup: Email: $email, IsAdmin: $isAdmin');

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.user!.uid)
          .set({
        'nome': nome,
        'email': email,
        'senhaIsSeted': true,
        'dataCadastro': DateTime.now(),
        'isAdmin': isAdmin, // Definir admin automaticamente baseado no email
      });
      setStoriesAntigos();
      Get.back();
      await UsuarioRepository.completarPerfil(
          imgData: imgData, imgBgData: imgBgData, sexo: sexo);
    } on FirebaseAuthException catch (e) {
      Get.back();
      debugPrint(e.code);
      debugPrint(e.message);

      if (e.code == 'user-not-found') {
        Get.rawSnackbar(message: AppLanguage.lang('email_incorreto'));
      } else if (e.code == 'wrong-password') {
        Get.rawSnackbar(message: AppLanguage.lang('senha_incorreta'));
      } else if (e.code == 'email-already-in-use') {
        Get.rawSnackbar(message: AppLanguage.lang('email_indisponivel'));
      } else {
        Get.rawSnackbar(message: AppLanguage.lang('error_login'));
      }
    } catch (e) {
      debugPrint('$e');
    }
  }

  static Future<void> deleteAccount({
    required String senha,
  }) async {
    Get.defaultDialog(
        title: AppLanguage.lang('validando'),
        content: const CircularProgressIndicator(),
        barrierDismissible: false);

    try {
      UserCredential user = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
              email: FirebaseAuth.instance.currentUser!.email!,
              password: senha);

      user.user!.delete();
      Get.offAll(() => const LoginView());
    } on FirebaseAuthException catch (e) {
      Get.back();
      debugPrint(e.code);

      if (e.code == 'user-not-found') {
        Get.rawSnackbar(message: AppLanguage.lang('email_incorreto'));
      } else if (e.code == 'wrong-password') {
        Get.rawSnackbar(message: AppLanguage.lang('senha_incorreta'));
      } else {
        Get.rawSnackbar(message: AppLanguage.lang('error_login'));
      }
    }
  }

  static Future<void> setStoriesAntigos() async {
    List<StorieFileModel> itens = await StoriesRepository.getAllFuture();
    itens.sort((a, b) => a.dataCadastro!.compareTo(b.dataCadastro!));

    for (var i = 0; i < itens.length; i++) {
      var old = StorieFileModel.toJson(itens[i]);
      old['dataCadastro'] = DateTime.now().add(Duration(days: i));
      old['idUsuario'] = FirebaseAuth.instance.currentUser!.uid;
      FirebaseFirestore.instance.collection('stories_antigos').add(old);
    }
  }
}
