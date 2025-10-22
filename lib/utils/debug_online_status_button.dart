import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:whatsapp_chat/routes.dart';

/// Botão flutuante para acessar a tela de debug do status online
/// Aparece apenas em modo debug
class DebugOnlineStatusButton extends StatelessWidget {
  const DebugOnlineStatusButton({super.key});

  @override
  Widget build(BuildContext context) {
    // Só mostra em modo debug
    if (!kDebugMode) return const SizedBox.shrink();

    return Positioned(
      bottom: 80,
      right: 16,
      child: FloatingActionButton(
        mini: true,
        backgroundColor: Colors.green,
        onPressed: () {
          Get.toNamed(PageRoutes.debugOnlineStatus);
        },
        child: const Icon(Icons.wifi, color: Colors.white, size: 20),
      ),
    );
  }
}
