import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:whatsapp_chat/models/interest_notification_model.dart';
import 'package:whatsapp_chat/repositories/interest_notification_repository.dart';

class InterestNotificationsComponent extends StatelessWidget {
  const InterestNotificationsComponent({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<InterestNotificationModel>>(
      stream: InterestNotificationRepository.getUserInterestNotifications(
          FirebaseAuth.instance.currentUser!.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final notifications = snapshot.data!;
        if (notifications.isEmpty) {
          return const SizedBox();
        }

        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header (mesmo design dos convites)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF39b9ff),
                      const Color(0xFFfc6aeb),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.favorite, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Notificações de Interesse',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${notifications.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Lista de notificações
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: notifications.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: Colors.grey.shade200,
                ),
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return _buildNotificationItem(notification);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem(InterestNotificationModel notification) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho com nome e tempo
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFfc6aeb).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Interesse',
                  style: TextStyle(
                    color: const Color(0xFFfc6aeb),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'De: ${notification.fromUserName}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                _formatDate(notification.dataCriacao),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Mensagem
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              notification.message ??
                  'Tem interesse em conhecer seu perfil melhor',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Botões de ação (mesmo layout dos convites)
          Row(
            children: [
              // Botão Não Tenho
              Expanded(
                child: TextButton(
                  onPressed: () =>
                      _respondToNotification(notification, 'rejected'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                  ),
                  child: const Text('Não Tenho'),
                ),
              ),
              const SizedBox(width: 4),
              // Botão Ver Perfil
              Expanded(
                child: TextButton(
                  onPressed: () => _viewProfile(notification),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF39b9ff),
                  ),
                  child: const Text('Ver Perfil'),
                ),
              ),
              const SizedBox(width: 4),
              // Botão Também Tenho
              Expanded(
                child: ElevatedButton(
                  onPressed: () =>
                      _respondToNotification(notification, 'accepted'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFfc6aeb),
                  ),
                  child: const Text(
                    'Também Tenho',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _respondToNotification(
      InterestNotificationModel notification, String action) async {
    // Implementação idêntica ao _respondToInvite dos convites
    try {
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFfc6aeb)),
          ),
        ),
        barrierDismissible: false,
      );

      await InterestNotificationRepository.respondToInterestNotification(
        notification.id!,
        action,
      );

      Get.back();

      if (action == 'accepted') {
        Get.snackbar(
          'Interesse Mútuo! 💕',
          'Vocês demonstraram interesse mútuo!',
          backgroundColor: const Color(0xFFfc6aeb),
          colorText: Colors.white,
          icon: const Icon(Icons.favorite, color: Colors.white),
          duration: const Duration(seconds: 3),
        );
      } else {
        Get.snackbar(
          'Interesse Recusado',
          'O interesse foi recusado.',
          backgroundColor: Colors.grey.shade600,
          colorText: Colors.white,
          icon: const Icon(Icons.info, color: Colors.white),
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      Get.snackbar(
        'Erro',
        e.toString().replaceAll('Exception: ', ''),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
        duration: const Duration(seconds: 4),
      );
    }
  }

  void _viewProfile(InterestNotificationModel notification) async {
    try {
      // Buscar dados do usuário interessado
      final user = await InterestNotificationRepository.getUserById(
          notification.fromUserId!);
      if (user == null) {
        Get.snackbar(
          'Erro',
          'Perfil do usuário não encontrado',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          icon: const Icon(Icons.error, color: Colors.white),
        );
        return;
      }

      // Navegar para o perfil do usuário interessado
      // Implementar navegação baseada na estrutura existente
      // Por exemplo: Get.toNamed('/profile', arguments: user);

      // Por enquanto, mostrar informações básicas
      Get.dialog(
        AlertDialog(
          title: Text('Perfil de ${user.nome}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nome: ${user.nome ?? 'Não informado'}'),
              Text('Email: ${user.email ?? 'Não informado'}'),
              Text('Idade: ${user.idade ?? 'Não informada'}'),
              Text('Cidade: ${user.cidade ?? 'Não informada'}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Fechar'),
            ),
            ElevatedButton(
              onPressed: () {
                Get.back();
                _respondToNotification(notification, 'accepted');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFfc6aeb),
              ),
              child: const Text(
                'Também Tenho',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao carregar perfil: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
      );
    }
  }

  String _formatDate(Timestamp? timestamp) {
    // Mesma implementação do PurposeInvitesComponent
    if (timestamp == null) return '';

    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Agora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return DateFormat('dd/MM').format(date);
    }
  }
}
