import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:whatsapp_chat/controllers/home_controller.dart';
import 'package:whatsapp_chat/controllers/login_controller.dart';
import 'package:whatsapp_chat/controllers/notification_controller.dart';
import 'package:whatsapp_chat/locale/language.dart';
import 'package:whatsapp_chat/models/usuario_model.dart';
import 'package:whatsapp_chat/repositories/usuario_repository.dart';
import 'package:whatsapp_chat/token_usuario.dart';
import 'package:whatsapp_chat/views/chat_view.dart';
import 'package:whatsapp_chat/views/completar_perfil_view.dart';
import 'package:whatsapp_chat/views/login_view.dart';
import 'package:whatsapp_chat/utils/debug_utils.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with WidgetsBindingObserver {
  final showSenha = false.obs;

  @override
  void initState() {
    super.initState();
    NotificationController.startFCM();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kDebugMode) {
      safePrint(state);
    }
    if (state != AppLifecycleState.resumed) {
      showSenha.value = true;
      TokenUsuario().lastTimestempFocused = Timestamp.now().seconds;
    } else {
      if (HomeController.disableShowSenha == true) {
        showSenha.value = false;
      } else {
        final DateTime timestamp1 = DateTime.now();
        final DateTime timestamp2 = Timestamp.fromMillisecondsSinceEpoch(
                TokenUsuario().lastTimestempFocused * 1000)
            .toDate();
        Duration difference = timestamp1.difference(timestamp2);
        if (kDebugMode) {
          safePrint('---difference.inSeconds---');
          safePrint(difference.inSeconds);
          safePrint('---difference.inSeconds---');
          safePrint('---HomeController.disableShowSenha---');
          safePrint(HomeController.disableShowSenha);
          safePrint('---HomeController.disableShowSenha---');
        }
        TokenUsuario().lastTimestempFocused = Timestamp.now().seconds;
        if (difference.inSeconds > 5) {
          showSenha.value = true;
        } else {
          showSenha.value = false;
        }
      }
    }
  }

  final senhaController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: null,
        body: StreamBuilder<UsuarioModel?>(
            stream: UsuarioRepository.getUser(),
            builder: (context, snapshot) {
              // ✅ TRATAMENTO DE ERRO OBRIGATÓRIO
              if (snapshot.hasError) {
                safePrint('HomeView: Erro no stream de usuário: ${snapshot.error}');
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Erro ao carregar dados do usuário',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Tentar recarregar
                          setState(() {});
                        },
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                );
              }
              
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              UsuarioModel user = snapshot.data!;
              if (user.senhaIsSeted != true &&
                  (kIsWeb ? false : Platform.isAndroid)) {
                return const LoginView();
              }
              if (user.perfilIsComplete != true) {
                return CompletarPerfilView(user: user);
              }
              return Stack(
                children: [
                  const ChatView(),
                  Obx(() => showSenha.value == false ||
                          (kIsWeb ? true : !Platform.isAndroid)
                      ? const SizedBox()
                      : SingleChildScrollView(
                          child: Container(
                            color: Colors.white,
                            constraints: BoxConstraints(minHeight: Get.height),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset('lib/assets/img/logo.png',
                                    width: Get.width * 0.42),
                                const SizedBox(height: 52),
                                Text(AppLanguage.lang('digite_senha_abaixo'),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 18)),
                                const SizedBox(height: 32),
                                TextField(
                                  textAlign: TextAlign.center,
                                  controller: senhaController,
                                  decoration: InputDecoration(
                                    hintText: AppLanguage.lang('digite_aqui'),
                                  ),
                                  obscureText: true,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      height: 35,
                                      margin: const EdgeInsets.only(bottom: 16),
                                      child: TextButton(
                                        style: TextButton.styleFrom(
                                            padding: const EdgeInsets.all(0)),
                                        onPressed: () => LoginController
                                            .recuperarSenhaSemEmail(),
                                        child: Text(
                                            AppLanguage.lang('esqueci_senha')),
                                      ),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: Get.width,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      if (senhaController.text.trim().isEmpty) {
                                        return;
                                      }
                                      bool r =
                                          await UsuarioRepository.validateSenha(
                                              senhaController.text.trim());
                                      if (r == false) {
                                        Get.rawSnackbar(
                                            message: AppLanguage.lang(
                                                'senha_invalida'));
                                        return;
                                      }

                                      showSenha.value = false;
                                      senhaController.clear();
                                    },
                                    child: Text(AppLanguage.lang('continuar')),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ))
                ],
              );
            }));
  }
}
