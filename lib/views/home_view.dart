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

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    NotificationController.startFCM();
  }

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
              return const ChatView();
            }));
  }
}
