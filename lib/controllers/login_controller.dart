import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:whatsapp_chat/models/usuario_model.dart';
import 'package:whatsapp_chat/token_usuario.dart';

import '../repositories/login_repository.dart';
import 'completar_perfil_controller.dart';

class LoginController {
  static final emailController = TextEditingController();
  static final senhaController = TextEditingController();
  static final senha2Controller = TextEditingController();
  static final nomeController = TextEditingController();
  static final sexo = Rx<UserSexo>(UserSexo.none);

  /// Função para mostrar guia de configuração do Firebase Console
  static void mostrarGuiaConfiguracao() {
    Get.defaultDialog(
        title: '⚙️ Configurar Firebase Console',
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🔧 PASSOS PARA CONFIGURAR RECUPERAÇÃO DE SENHA:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text('1. Acesse: console.firebase.google.com'),
              const Text('2. Selecione seu projeto'),
              const Text('3. Vá em "Authentication"'),
              const Text('4. Clique em "Templates"'),
              const Text('5. Configure "Password reset"'),
              const Text('6. Defina remetente e template'),
              const Text('7. Salve as configurações'),
              const SizedBox(height: 12),
              const Text(
                '📧 VERIFICAR TAMBÉM:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('• Settings > Authorized domains'),
              const Text('• Project Settings > General'),
              const Text('• Authentication > Sign-in method'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Get.back(),
            child: const Text('Entendi'),
          )
        ]);
  }

  /// Verifica se o Firebase está configurado para envio de emails
  static Future<bool> _verificarConfiguracaoEmail() async {
    try {
      // Verificar se há configurações básicas do Firebase
      final auth = FirebaseAuth.instance;
      if (auth.app.options.apiKey.isEmpty) {
        debugPrint('❌ API Key não configurada');
        return false;
      }

      if (auth.app.options.projectId.isEmpty) {
        debugPrint('❌ Project ID não configurado');
        return false;
      }

      debugPrint('✅ Configurações básicas do Firebase OK');
      return true;
    } catch (e) {
      debugPrint('❌ Erro ao verificar configuração: $e');
      return false;
    }
  }

  static void clean() {
    emailController.clear();
    senhaController.clear();
    senha2Controller.clear();
    nomeController.clear();
  }

  static validadeLogin() {
    debugPrint('=== INÍCIO VALIDAÇÃO LOGIN ===');

    String email = emailController.text.trim();
    String senha = senhaController.text.trim();

    debugPrint('Email digitado: $email');
    debugPrint(
        'Senha digitada: ${senha.isNotEmpty ? '[SENHA PREENCHIDA]' : '[SENHA VAZIA]'}');

    if (email == '' || senha == '') {
      debugPrint('❌ Campos obrigatórios vazios');
      Get.rawSnackbar(message: 'Todos os campos são obrigatórios!');
      return;
    }

    if (!email.isEmail) {
      debugPrint('❌ Email inválido: $email');
      Get.rawSnackbar(message: 'Digite um E-mail válido!');
      return;
    }

    debugPrint('✅ Validação passou, chamando LoginRepository.login');
    LoginRepository.login(email: email, senha: senha);
    debugPrint('=== FIM VALIDAÇÃO LOGIN ===');
  }

  static validadeCadastro() {
    String nome = nomeController.text.trim();
    String email = emailController.text.trim();
    String senha = senhaController.text.trim();
    String senha2 = senha2Controller.text.trim();

    if (email == '' || senha == '' || nome == '' || senha2 == '') {
      Get.rawSnackbar(message: 'Todos os campos são obrigatórios!');
      return;
    }

    if (!email.isEmail) {
      Get.rawSnackbar(message: 'Digite um E-mail válido!');
      return;
    }

    if (senha.length < 6) {
      Get.rawSnackbar(message: 'A Senha deve ter pelo menos 6 caracteres!');
      return;
    }

    if (senha != senha2) {
      Get.rawSnackbar(message: 'A Senha deve ser igual a confirmação!');
      return;
    }

    // Papel de parede não é mais obrigatório na nova interface modernizada

    LoginRepository.cadastrarComEmail(
        email: email,
        senha: senha,
        nome: nome,
        imgBgData: CompletarPerfilController.imgBgData,
        imgData: CompletarPerfilController.imgData,
        sexo: TokenUsuario().sexo // Usar sexo selecionado na página de idioma
        );
  }

  static Future<void> recuperarSenhaSemEmail() async {
    Get.defaultDialog(
        title: 'Solicitando...',
        content: const CircularProgressIndicator(),
        barrierDismissible: false);

    try {
      final userEmail = FirebaseAuth.instance.currentUser?.email;
      if (userEmail == null) {
        Get.back();
        Get.defaultDialog(
            title: '❌ Erro',
            content: const Text(
                'Usuário não está logado ou email não disponível.',
                textAlign: TextAlign.center),
            actions: [
              ElevatedButton(
                onPressed: () => Get.back(),
                child: const Text('Ok'),
              )
            ]);
        return;
      }

      await FirebaseAuth.instance.sendPasswordResetEmail(email: userEmail);
      Get.back();
      Get.back();
      Get.defaultDialog(
          title: '✅ Email Enviado',
          content: Text(
            'Um link para redefinir sua senha foi enviado para:\n\n$userEmail\n\nVerifique sua caixa de entrada e spam.',
            textAlign: TextAlign.center,
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('Ok'),
            )
          ]);
    } on FirebaseAuthException catch (e) {
      Get.back();
      debugPrint('Password Reset Error: ${e.code} - ${e.message}');

      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage =
              '❌ Usuário não encontrado!\n\nEste email não está mais cadastrado no sistema.';
          break;
        case 'invalid-email':
          errorMessage =
              '❌ Email inválido!\n\nO email do usuário atual não é válido.';
          break;
        case 'too-many-requests':
          errorMessage =
              '❌ Muitas tentativas!\n\nAguarde alguns minutos antes de tentar novamente.';
          break;
        case 'network-request-failed':
          errorMessage =
              '❌ Erro de conexão!\n\nVerifique sua internet e tente novamente.';
          break;
        case 'auth/configuration-not-found':
          errorMessage =
              '❌ Configuração não encontrada!\n\nRecuperação de senha não está configurada.';
          break;
        default:
          errorMessage =
              '❌ Falha ao enviar solicitação!\n\nErro: ${e.code}\n\nTente novamente ou contate o suporte.';
      }

      Get.defaultDialog(
          title: 'Erro na Recuperação',
          content: Text(errorMessage, textAlign: TextAlign.center),
          actions: [
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('Ok'),
            )
          ]);
    } catch (e) {
      Get.back();
      debugPrint('Unexpected error in password reset: $e');
      Get.defaultDialog(
          title: 'Erro Inesperado',
          content: Text(
            '❌ Erro inesperado ao enviar email de recuperação.\n\nTente novamente ou contate o suporte.\n\nDetalhes: $e',
            textAlign: TextAlign.center,
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('Ok'),
            )
          ]);
    }
  }

  /// Função para testar conectividade básica com Firebase
  static Future<void> testarConectividadeFirebase() async {
    debugPrint('=== TESTE CONECTIVIDADE FIREBASE ===');

    try {
      // Testar Firebase Auth
      final auth = FirebaseAuth.instance;
      debugPrint('✅ Firebase Auth inicializado: ${auth.app.name}');
      debugPrint('✅ Project ID: ${auth.app.options.projectId}');
      debugPrint('✅ API Key: ${auth.app.options.apiKey.substring(0, 10)}...');

      // Testar Firestore
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('test').limit(1).get();
      debugPrint('✅ Firestore conectado e acessível');

      // Testar criação de usuário simples
      try {
        await auth.createUserWithEmailAndPassword(
            email: 'teste${DateTime.now().millisecondsSinceEpoch}@teste.com',
            password: '123456');
        debugPrint('✅ Criação de usuário funcionando');
        await auth.currentUser?.delete();
        debugPrint('✅ Usuário de teste removido');
      } catch (e) {
        debugPrint('❌ Erro ao criar usuário de teste: $e');
      }
    } catch (e) {
      debugPrint('❌ Erro de conectividade Firebase: $e');
    }

    debugPrint('=== FIM TESTE CONECTIVIDADE ===');
  }

  /// Função para testar especificamente a recuperação de senha
  static Future<void> testarRecuperacaoSenha() async {
    debugPrint('=== TESTE RECUPERAÇÃO DE SENHA ===');

    try {
      // Testar com um email fictício para ver o tipo de erro
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: 'teste@exemplo.com');
    } catch (e) {
      debugPrint('Erro esperado com email fictício: $e');

      if (e.toString().contains('configuration-not-found') ||
          e.toString().contains('auth/configuration-not-found')) {
        debugPrint(
            '❌ PROBLEMA: Templates de email não configurados no Firebase Console');
      } else if (e.toString().contains('user-not-found')) {
        debugPrint(
            '✅ CONFIGURAÇÃO OK: Firebase consegue processar emails (usuário não encontrado é esperado)');
      } else {
        debugPrint('❓ ERRO INESPERADO: $e');
      }
    }

    debugPrint('=== FIM TESTE RECUPERAÇÃO ===');
  }

  /// Função para testar configuração do Firebase (apenas para debug)
  static Future<void> testarConfiguracaoFirebase() async {
    debugPrint('=== TESTE CONFIGURAÇÃO FIREBASE ===');

    try {
      // Testar se Firebase Auth está inicializado
      final auth = FirebaseAuth.instance;
      debugPrint('✅ Firebase Auth inicializado: ${auth.app.name}');

      // Testar se Firestore está acessível
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('test').limit(1).get();
      debugPrint('✅ Firestore acessível');

      // Verificar configurações do projeto
      debugPrint('App ID: ${auth.app.options.appId}');
      debugPrint('Project ID: ${auth.app.options.projectId}');
    } catch (e) {
      debugPrint('❌ Erro na configuração Firebase: $e');
    }

    debugPrint('=== FIM TESTE CONFIGURAÇÃO ===');
  }

  /// Função para diagnosticar problemas com recuperação de senha
  static Future<void> _diagnosticarRecuperacaoSenha(String email) async {
    debugPrint('=== DIAGNÓSTICO RECUPERAÇÃO DE SENHA ===');
    debugPrint('Email: $email');
    debugPrint('Firebase Auth instance: ${FirebaseAuth.instance}');
    debugPrint('Current user: ${FirebaseAuth.instance.currentUser?.email}');

    try {
      // Verificar se o usuário existe
      final methods =
          await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      debugPrint('Sign-in methods for $email: $methods');

      if (methods.isEmpty) {
        debugPrint('❌ Email não está cadastrado no Firebase Auth');
      } else {
        debugPrint('✅ Email encontrado com métodos: $methods');
      }
    } catch (e) {
      debugPrint('❌ Erro ao verificar email: $e');
    }

    debugPrint('=== FIM DIAGNÓSTICO ===');
  }

  static Future<void> recuperarSenha() async {
    final emailController = TextEditingController();

    Get.defaultDialog(
        title: 'Recuperar senha',
        titlePadding: const EdgeInsets.only(top: 16),
        contentPadding: const EdgeInsets.all(16),
        content: Column(
          children: [
            const Text(
                'Digite abaixo seu E-mail de acesso que enviaremos um link para recuperação de sua senha',
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(hintText: 'Digite aqui...'),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: Get.width * 0.25,
            height: 45,
            child: TextButton(
                onPressed: () => Get.back(), child: const Text('Cancelar')),
          ),
          SizedBox(
            width: Get.width * 0.25,
            height: 45,
            child: TextButton(
              onPressed: () async {
                // Executar teste de configuração
                await testarRecuperacaoSenha();
                await testarConfiguracaoFirebase();
                Get.rawSnackbar(
                  message:
                      '🔍 Testes executados! Verifique os logs no console.',
                  duration: const Duration(seconds: 3),
                );
              },
              child: const Text('Testar', style: TextStyle(fontSize: 12)),
            ),
          ),
          SizedBox(
            width: Get.width * 0.3,
            height: 45,
            child: ElevatedButton(
                onPressed: () async {
                  if (emailController.text.trim() != '') {
                    if (!emailController.text.isEmail) {
                      Get.rawSnackbar(message: 'Digite um E-mail válido!');
                      return;
                    }

                    Get.defaultDialog(
                        title: 'Solicitando...',
                        content: const CircularProgressIndicator(),
                        barrierDismissible: false);

                    try {
                      final email = emailController.text.trim();

                      // Verificar configuração do Firebase
                      final configOk = await _verificarConfiguracaoEmail();
                      if (!configOk) {
                        Get.back();
                        Get.defaultDialog(
                            title: '❌ Configuração Incompleta',
                            content: const Text(
                              'O Firebase não está configurado corretamente para envio de emails.\n\nContate o administrador do sistema.',
                              textAlign: TextAlign.center,
                            ),
                            actions: [
                              ElevatedButton(
                                onPressed: () => Get.back(),
                                child: const Text('Ok'),
                              )
                            ]);
                        return;
                      }

                      // Executar diagnóstico em modo debug
                      await _diagnosticarRecuperacaoSenha(email);

                      // Verificar se o email existe antes de tentar enviar
                      try {
                        final methods = await FirebaseAuth.instance
                            .fetchSignInMethodsForEmail(email);
                        if (methods.isEmpty) {
                          Get.back();
                          Get.defaultDialog(
                              title: '❌ Email Não Encontrado',
                              content: Text(
                                'O email "$email" não está cadastrado no sistema.\n\nVerifique se digitou corretamente ou crie uma nova conta.',
                                textAlign: TextAlign.center,
                              ),
                              actions: [
                                ElevatedButton(
                                  onPressed: () => Get.back(),
                                  child: const Text('Ok'),
                                )
                              ]);
                          return;
                        }
                      } catch (e) {
                        debugPrint('Erro ao verificar email: $e');
                        // Continuar mesmo se não conseguir verificar
                      }

                      await FirebaseAuth.instance
                          .sendPasswordResetEmail(email: email);
                      Get.back();
                      Get.back();
                      Get.defaultDialog(
                          title: '✅ Email Enviado',
                          content: Text(
                            'Um link para redefinir sua senha foi enviado para:\n\n${emailController.text.trim()}\n\nVerifique sua caixa de entrada e spam.',
                            textAlign: TextAlign.center,
                          ),
                          actions: [
                            ElevatedButton(
                              onPressed: () => Get.back(),
                              child: const Text('Ok'),
                            )
                          ]);
                    } on FirebaseAuthException catch (e) {
                      Get.back();
                      debugPrint('=== ERRO DETALHADO FIREBASE AUTH ===');
                      debugPrint('Código: ${e.code}');
                      debugPrint('Mensagem: ${e.message}');
                      debugPrint('Plugin: ${e.plugin}');
                      debugPrint('Stack trace: ${e.stackTrace}');
                      debugPrint('=== FIM ERRO DETALHADO ===');

                      String errorMessage;
                      String errorTitle = 'Erro na Recuperação';

                      switch (e.code) {
                        case 'user-not-found':
                          errorMessage =
                              '❌ Email não encontrado!\n\nEste email não está cadastrado no sistema.';
                          break;
                        case 'invalid-email':
                          errorMessage =
                              '❌ Email inválido!\n\nVerifique se o email está correto.';
                          break;
                        case 'too-many-requests':
                          errorMessage =
                              '❌ Muitas tentativas!\n\nAguarde alguns minutos antes de tentar novamente.';
                          break;
                        case 'network-request-failed':
                          errorMessage =
                              '❌ Erro de conexão!\n\nVerifique sua internet e tente novamente.';
                          break;
                        case 'auth/configuration-not-found':
                        case 'configuration-not-found':
                          errorTitle = '⚙️ Configuração Necessária';
                          errorMessage =
                              '❌ Templates de email não configurados!\n\n🔧 SOLUÇÃO:\n1. Acesse Firebase Console\n2. Vá em Authentication > Templates\n3. Configure o template "Password reset"\n4. Tente novamente';
                          break;
                        case 'unauthorized-domain':
                          errorTitle = '🌐 Domínio Não Autorizado';
                          errorMessage =
                              '❌ Domínio não autorizado!\n\n🔧 SOLUÇÃO:\n1. Acesse Firebase Console\n2. Vá em Authentication > Settings\n3. Adicione seu domínio em "Authorized domains"\n4. Tente novamente';
                          break;
                        case 'unknown':
                        case 'internal-error':
                          errorTitle = '🔍 Erro de Configuração';
                          errorMessage =
                              '❌ Erro interno do Firebase!\n\n🔧 POSSÍVEIS CAUSAS:\n• Templates de email não configurados\n• Projeto Firebase mal configurado\n• Chaves de API incorretas\n\n📞 CONTATE O ADMINISTRADOR\nCódigo: ${e.code}\nDetalhes: ${e.message}';
                          break;
                        default:
                          errorTitle = '❓ Erro Desconhecido';
                          errorMessage =
                              '❌ Falha ao enviar solicitação!\n\n🔍 DETALHES TÉCNICOS:\nCódigo: ${e.code}\nMensagem: ${e.message}\n\n🔧 AÇÕES:\n1. Tente novamente em alguns minutos\n2. Verifique sua conexão\n3. Contate o suporte se persistir';
                      }

                      Get.defaultDialog(
                          title: errorTitle,
                          content: SingleChildScrollView(
                            child:
                                Text(errorMessage, textAlign: TextAlign.left),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Get.back();
                                mostrarGuiaConfiguracao();
                              },
                              child: const Text('Como Configurar'),
                            ),
                            TextButton(
                              onPressed: () {
                                Get.back();
                                // Mostrar informações técnicas adicionais
                                Get.defaultDialog(
                                    title: '🔧 Informações Técnicas',
                                    content: SingleChildScrollView(
                                      child: Text(
                                        'CÓDIGO: ${e.code}\n\nMENSAGEM: ${e.message}\n\nPLUGIN: ${e.plugin}\n\nEMAIL TESTADO: ${emailController.text.trim()}\n\nPROJETO: ${FirebaseAuth.instance.app.options.projectId}',
                                        textAlign: TextAlign.left,
                                        style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 12),
                                      ),
                                    ),
                                    actions: [
                                      ElevatedButton(
                                        onPressed: () => Get.back(),
                                        child: const Text('Fechar'),
                                      )
                                    ]);
                              },
                              child: const Text('Detalhes'),
                            ),
                            ElevatedButton(
                              onPressed: () => Get.back(),
                              child: const Text('Ok'),
                            )
                          ]);
                    } catch (e) {
                      Get.back();
                      debugPrint('Unexpected error in password reset: $e');
                      Get.defaultDialog(
                          title: 'Erro Inesperado',
                          content: Text(
                            '❌ Erro inesperado ao enviar email de recuperação.\n\nTente novamente ou contate o suporte.\n\nDetalhes: $e',
                            textAlign: TextAlign.center,
                          ),
                          actions: [
                            ElevatedButton(
                              onPressed: () => Get.back(),
                              child: const Text('Ok'),
                            )
                          ]);
                    }
                  }
                },
                child: const Text('Enviar')),
          )
        ]);
  }
}
