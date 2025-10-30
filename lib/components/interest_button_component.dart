import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:whatsapp_chat/models/usuario_model.dart';
import 'package:whatsapp_chat/repositories/interest_notification_repository.dart';

class InterestButtonComponent extends StatefulWidget {
  final String targetUserId;
  final String targetUserName;
  final String targetUserEmail;
  final UsuarioModel? currentUser;
  final VoidCallback? onInterestSent;

  const InterestButtonComponent({
    super.key,
    required this.targetUserId,
    required this.targetUserName,
    required this.targetUserEmail,
    this.currentUser,
    this.onInterestSent,
  });

  @override
  State<InterestButtonComponent> createState() =>
      _InterestButtonComponentState();
}

class _InterestButtonComponentState extends State<InterestButtonComponent> {
  bool _isLoading = false;
  bool _hasShownInterest = false;

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyShownInterest();
  }

  Future<void> _checkIfAlreadyShownInterest() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      final hasInterest =
          await InterestNotificationRepository.hasUserShownInterest(
        currentUserId,
        widget.targetUserId,
      );

      if (mounted) {
        setState(() {
          _hasShownInterest = hasInterest;
        });
      }
    } catch (e) {
      print('Erro ao verificar interesse existente: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Não mostrar botão para o próprio usuário
    if (FirebaseAuth.instance.currentUser?.uid == widget.targetUserId) {
      return const SizedBox();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton(
        onPressed:
            _hasShownInterest ? null : (_isLoading ? null : _showInterest),
        style: ElevatedButton.styleFrom(
          backgroundColor: _hasShownInterest
              ? Colors.grey.shade400
              : const Color(0xFFfc6aeb),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: _hasShownInterest ? 0 : 2,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _hasShownInterest ? Icons.check : Icons.favorite,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _hasShownInterest ? 'Interesse Enviado' : 'Tenho Interesse',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _showInterest() async {
    if (_isLoading || _hasShownInterest) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não está logado');
      }

      // Buscar dados do usuário do Firestore se não foram passados
      String fromUserName;
      String fromUserEmail;

      if (widget.currentUser != null) {
        // Usar dados passados como parâmetro
        fromUserName = widget.currentUser!.nome ?? 'Usuário';
        fromUserEmail = widget.currentUser!.email ?? currentUser.email ?? '';
      } else {
        // Buscar do Firestore
        print(
            '🔍 [INTEREST_BUTTON] Buscando dados do usuário do Firestore: ${currentUser.uid}');

        final userDoc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(currentUser.uid)
            .get();

        if (!userDoc.exists) {
          throw Exception('Dados do usuário não encontrados');
        }

        final userData = userDoc.data()!;
        fromUserName = userData['nome'] ?? userData['username'] ?? 'Usuário';
        fromUserEmail = userData['email'] ?? currentUser.email ?? '';

        print(
            '✅ [INTEREST_BUTTON] Dados obtidos: nome=$fromUserName, email=$fromUserEmail');
      }

      if (fromUserEmail.isEmpty) {
        throw Exception('Email do usuário não encontrado');
      }

      if (fromUserName.isEmpty || fromUserName == 'Usuário') {
        print(
            '⚠️ [INTEREST_BUTTON] Nome do usuário está vazio ou genérico: "$fromUserName"');
      }

      print('💕 [INTEREST_BUTTON] Criando notificação de interesse:');
      print('   De: $fromUserName ($fromUserEmail)');
      print('   Para: ${widget.targetUserName} (${widget.targetUserId})');

      await InterestNotificationRepository.createInterestNotification(
        fromUserId: currentUser.uid,
        fromUserName: fromUserName,
        fromUserEmail: fromUserEmail,
        toUserId: widget.targetUserId,
        toUserEmail: widget.targetUserEmail,
        message: 'Tem interesse em conhecer seu perfil melhor',
      );

      if (mounted) {
        setState(() {
          _hasShownInterest = true;
        });
      }

      // Callback para notificar o componente pai
      widget.onInterestSent?.call();

      Get.snackbar(
        'Interesse Enviado! 💕',
        'Sua notificação de interesse foi enviada para ${widget.targetUserName}!',
        backgroundColor: const Color(0xFFfc6aeb),
        colorText: Colors.white,
        icon: const Icon(Icons.favorite, color: Colors.white),
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        e.toString().replaceAll('Exception: ', ''),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

// Versão simplificada para uso rápido
class SimpleInterestButton extends StatelessWidget {
  final String targetUserId;
  final String targetUserName;
  final String targetUserEmail;

  const SimpleInterestButton({
    super.key,
    required this.targetUserId,
    required this.targetUserName,
    required this.targetUserEmail,
  });

  @override
  Widget build(BuildContext context) {
    return InterestButtonComponent(
      targetUserId: targetUserId,
      targetUserName: targetUserName,
      targetUserEmail: targetUserEmail,
    );
  }
}

// Versão compacta para listas
class CompactInterestButton extends StatelessWidget {
  final String targetUserId;
  final String targetUserName;
  final String targetUserEmail;

  const CompactInterestButton({
    super.key,
    required this.targetUserId,
    required this.targetUserName,
    required this.targetUserEmail,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 36,
      child: ElevatedButton(
        onPressed: () => _showInterest(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFfc6aeb),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite, size: 16),
            SizedBox(width: 4),
            Text(
              'Interesse',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  void _showInterest(BuildContext context) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não está logado');
      }

      // Buscar dados do usuário do Firestore
      print(
          '🔍 [INTEREST_BUTTON_COMPACT] Buscando dados do usuário do Firestore: ${currentUser.uid}');

      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('Dados do usuário não encontrados');
      }

      final userData = userDoc.data()!;
      final fromUserName =
          userData['nome'] ?? userData['username'] ?? 'Usuário';
      final fromUserEmail = userData['email'] ?? currentUser.email ?? '';

      print(
          '✅ [INTEREST_BUTTON_COMPACT] Dados obtidos: nome=$fromUserName, email=$fromUserEmail');

      if (fromUserName.isEmpty || fromUserName == 'Usuário') {
        print(
            '⚠️ [INTEREST_BUTTON_COMPACT] Nome do usuário está vazio ou genérico: "$fromUserName"');
      }

      print('💕 [INTEREST_BUTTON_COMPACT] Criando notificação de interesse:');
      print('   De: $fromUserName ($fromUserEmail)');
      print('   Para: $targetUserName ($targetUserId)');

      await InterestNotificationRepository.createInterestNotification(
        fromUserId: currentUser.uid,
        fromUserName: fromUserName,
        fromUserEmail: fromUserEmail,
        toUserId: targetUserId,
        toUserEmail: targetUserEmail,
      );

      Get.snackbar(
        'Interesse Enviado! 💕',
        'Notificação enviada para $targetUserName!',
        backgroundColor: const Color(0xFFfc6aeb),
        colorText: Colors.white,
        icon: const Icon(Icons.favorite, color: Colors.white),
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        e.toString().replaceAll('Exception: ', ''),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
