import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:whatsapp_chat/models/purpose_invite_model.dart';
import 'package:whatsapp_chat/repositories/purpose_partnership_repository.dart';

class PurposeInvitesComponent extends StatelessWidget {
  const PurposeInvitesComponent({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PurposeInviteModel>>(
      stream: PurposePartnershipRepository.getUserInvites(
          FirebaseAuth.instance.currentUser!.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final invites = snapshot.data!;
        if (invites.isEmpty) {
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
              // Header
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
                      'Convites do Propósito',
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
                        '${invites.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Lista de convites
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: invites.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: Colors.grey.shade200,
                ),
                itemBuilder: (context, index) {
                  final invite = invites[index];
                  return _buildInviteItem(invite);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInviteItem(PurposeInviteModel invite) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tipo de convite e remetente
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: invite.isPartnership
                      ? const Color(0xFF39b9ff).withOpacity(0.1)
                      : const Color(0xFFfc6aeb).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  invite.isPartnership ? 'Parceria' : 'Menção',
                  style: TextStyle(
                    color: invite.isPartnership
                        ? const Color(0xFF39b9ff)
                        : const Color(0xFFfc6aeb),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'De: ${invite.fromUserName}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                _formatDate(invite.dataCriacao),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Mensagem do convite
          if (invite.isMention && invite.message != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '@${invite.fromUserName} escreveu essa mensagem para você como forma de te chamar para o propósito:',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '"${invite.message}"',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ] else if (invite.isPartnership) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mensagem do convite:',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    invite.message ??
                        'Quer conversar com Deus juntos no Propósito?',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Botões de ação
          Row(
            children: [
              // Botão Recusar
              Expanded(
                child: TextButton(
                  onPressed: () => _respondToInvite(invite, false, false),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                  ),
                  child: const Text('Recusar'),
                ),
              ),
              const SizedBox(width: 4),
              // Botão Bloquear
              Expanded(
                child: TextButton(
                  onPressed: () => _respondToInvite(invite, false, true),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Bloquear'),
                ),
              ),
              const SizedBox(width: 4),
              // Botão Aceitar
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _respondToInvite(invite, true, false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: invite.isPartnership
                        ? const Color(0xFF39b9ff)
                        : const Color(0xFFfc6aeb),
                  ),
                  child: Text(
                    invite.isPartnership ? 'Aceitar' : 'Participar',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _respondToInvite(
      PurposeInviteModel invite, bool accepted, bool blocked) async {
    try {
      // Mostrar loading
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF39b9ff)),
          ),
        ),
        barrierDismissible: false,
      );

      // Responder ao convite
      final action = blocked ? 'blocked' : (accepted ? 'accepted' : 'rejected');
      await PurposePartnershipRepository.respondToInviteWithAction(
          invite.id!, action);

      // Fechar loading
      Get.back();

      // Mostrar feedback
      if (blocked) {
        Get.snackbar(
          'Usuário Bloqueado 🚫',
          '${invite.fromUserName} foi bloqueado e não poderá mais enviar convites.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          icon: const Icon(Icons.block, color: Colors.white),
          duration: const Duration(seconds: 3),
        );
      } else if (accepted) {
        Get.snackbar(
          invite.isPartnership ? 'Parceria Aceita! 💕' : 'Convite Aceito! 🎉',
          invite.isPartnership
              ? 'Agora vocês podem conversar com Deus juntos!'
              : 'Você foi adicionado(a) à conversa!',
          backgroundColor: const Color(0xFF39b9ff),
          colorText: Colors.white,
          icon: const Icon(Icons.favorite, color: Colors.white),
          duration: const Duration(seconds: 3),
        );
      } else {
        Get.snackbar(
          'Convite Recusado',
          'O convite foi recusado.',
          backgroundColor: Colors.grey.shade600,
          colorText: Colors.white,
          icon: const Icon(Icons.info, color: Colors.white),
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      // Fechar loading se ainda estiver aberto
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      // Mostrar erro
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

  String _formatDate(Timestamp? timestamp) {
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
