import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/temporary_chat_model.dart';
import '../repositories/temporary_chat_repository.dart';
import '../repositories/spiritual_profile_repository.dart';

class TemporaryChatController extends GetxController {
  final String chatRoomId;

  final Rx<TemporaryChatModel?> chat = Rx<TemporaryChatModel?>(null);
  final RxList<TemporaryChatMessageModel> messages =
      <TemporaryChatMessageModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isSending = false.obs;
  final RxString errorMessage = ''.obs;

  final TextEditingController messageController = TextEditingController();
  StreamSubscription<List<TemporaryChatMessageModel>>? _messagesSubscription;
  Timer? _expirationTimer;

  TemporaryChatController(this.chatRoomId);

  @override
  void onInit() {
    super.onInit();
    loadChat();
  }

  @override
  void onClose() {
    _messagesSubscription?.cancel();
    _expirationTimer?.cancel();
    messageController.dispose();
    debugPrint('🔄 TemporaryChatController fechado');
    super.onClose();
  }

  Future<void> loadChat() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      debugPrint('🔄 Carregando chat temporário: $chatRoomId');

      // Load chat data
      final chatData =
          await TemporaryChatRepository.getChatByRoomId(chatRoomId);
      if (chatData == null) {
        errorMessage.value = 'Chat não encontrado.';
        return;
      }

      // Verify user is participant
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null || !chatData.isParticipant(currentUser.uid)) {
        errorMessage.value = 'Você não tem permissão para acessar este chat.';
        return;
      }

      chat.value = chatData;

      // Start listening to messages
      _startMessagesStream();

      // Mark messages as read
      await TemporaryChatRepository.markMessagesAsRead(
          chatRoomId, currentUser.uid);

      // Set up expiration timer if chat is still active
      if (!chatData.isExpired && chatData.isActive) {
        _setupExpirationTimer();
      }

      debugPrint('✅ Chat carregado: ${chatData.id}');
      debugPrint('   - Expira em: ${chatData.timeRemainingText}');
    } catch (e) {
      debugPrint('❌ Erro ao carregar chat: $e');
      errorMessage.value = 'Erro ao carregar chat. Tente novamente.';
    } finally {
      isLoading.value = false;
    }
  }

  void _startMessagesStream() {
    _messagesSubscription?.cancel();

    _messagesSubscription =
        TemporaryChatRepository.getMessagesStream(chatRoomId).listen(
      (messagesList) {
        messages.value = messagesList;
        debugPrint('📨 Mensagens atualizadas: ${messagesList.length}');
      },
      onError: (error) {
        debugPrint('❌ Erro no stream de mensagens: $error');
      },
    );
  }

  void _setupExpirationTimer() {
    final chatData = chat.value;
    if (chatData == null) return;

    final timeUntilExpiration = chatData.timeUntilExpiration;
    if (timeUntilExpiration.isNegative) return;

    _expirationTimer?.cancel();
    _expirationTimer = Timer(timeUntilExpiration, () {
      debugPrint('⏰ Chat expirou: $chatRoomId');
      // Reload chat to update expiration status
      loadChat();
    });

    debugPrint(
        '⏰ Timer de expiração configurado: ${timeUntilExpiration.inMinutes} minutos');
  }

  Future<void> sendMessage() async {
    final message = messageController.text.trim();
    if (message.isEmpty) return;

    final chatData = chat.value;
    if (chatData == null) {
      Get.snackbar(
        'Erro',
        'Chat não encontrado.',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (chatData.isExpired) {
      Get.snackbar(
        'Chat Expirado',
        'Este chat temporário já expirou.',
        backgroundColor: Colors.orange[100],
        colorText: Colors.orange[800],
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isSending.value = true;
      debugPrint('💬 Enviando mensagem: $message');

      // Clear input immediately for better UX
      messageController.clear();

      await TemporaryChatRepository.sendMessage(chatRoomId, message);

      debugPrint('✅ Mensagem enviada com sucesso');
    } catch (e) {
      debugPrint('❌ Erro ao enviar mensagem: $e');

      // Restore message in input if failed
      messageController.text = message;

      Get.snackbar(
        'Erro',
        'Não foi possível enviar a mensagem. Tente novamente.',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSending.value = false;
    }
  }

  Future<void> moveToNossoProposito() async {
    final chatData = chat.value;
    if (chatData == null) return;

    try {
      debugPrint('🔄 Movendo para Nosso Propósito...');

      // Show confirmation dialog
      final confirmed = await Get.defaultDialog<bool>(
            title: 'Mover para Nosso Propósito',
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.upgrade, size: 48, color: Colors.blue),
                SizedBox(height: 16),
                Text(
                  'Deseja mover esta conversa para o "Nosso Propósito"?',
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Isso criará um chat permanente para relacionamentos sérios.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child:
                    const Text('Mover', style: TextStyle(color: Colors.white)),
              ),
            ],
          ) ??
          false;

      if (!confirmed) return;

      await TemporaryChatRepository.moveToNossoProposito(chatData.id!);

      // Reload chat to update status
      await loadChat();

      Get.snackbar(
        'Sucesso!',
        'Chat movido para "Nosso Propósito" com sucesso!',
        backgroundColor: Colors.green[100],
        colorText: Colors.green[800],
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      debugPrint('❌ Erro ao mover para Nosso Propósito: $e');
      Get.snackbar(
        'Erro',
        'Não foi possível mover o chat. Tente novamente.',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> blockUser() async {
    final chatData = chat.value;
    if (chatData == null) return;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    final otherUserId = chatData.getOtherUserId(currentUserId);
    final otherUserName = chatData.getOtherUserName(currentUserId);

    try {
      debugPrint('🚫 Bloqueando usuário: $otherUserId');

      // Show confirmation dialog
      final confirmed = await Get.defaultDialog<bool>(
            title: 'Bloquear Usuário',
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.block, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Deseja bloquear ${otherUserName ?? 'este usuário'}?',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Esta pessoa não poderá mais interagir com você.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Bloquear',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ) ??
          false;

      if (!confirmed) return;

      await SpiritualProfileRepository.blockUser(otherUserId);

      Get.snackbar(
        'Usuário Bloqueado',
        '${otherUserName ?? 'Usuário'} foi bloqueado com sucesso.',
        backgroundColor: Colors.orange[100],
        colorText: Colors.orange[800],
        snackPosition: SnackPosition.BOTTOM,
      );

      // Return to previous screen
      Get.back();
    } catch (e) {
      debugPrint('❌ Erro ao bloquear usuário: $e');
      Get.snackbar(
        'Erro',
        'Não foi possível bloquear o usuário. Tente novamente.',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Helper methods
  bool get canSendMessages {
    final chatData = chat.value;
    return chatData != null && !chatData.isExpired && chatData.isActive;
  }

  String get chatStatusText {
    final chatData = chat.value;
    if (chatData == null) return 'Chat não encontrado';

    if (chatData.movedToNossoProposito) {
      return 'Movido para Nosso Propósito';
    } else if (chatData.isExpired) {
      return 'Chat expirado';
    } else {
      return 'Chat ativo - ${chatData.timeRemainingText}';
    }
  }

  Color get statusColor {
    final chatData = chat.value;
    if (chatData == null) return Colors.grey;

    if (chatData.movedToNossoProposito) {
      return Colors.green;
    } else if (chatData.isExpired) {
      return Colors.red;
    } else {
      final remaining = chatData.timeUntilExpiration;
      if (remaining.inHours < 24) {
        return Colors.orange;
      } else {
        return Colors.blue;
      }
    }
  }
}
