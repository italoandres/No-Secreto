import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/spiritual_profile_model.dart';
import '../repositories/spiritual_profile_repository.dart';
// import '../controllers/matches_controller.dart'; // Removido - sistema de matches excluído
import '../theme.dart';
import '../utils/enhanced_logger.dart';

/// Componente para exibir notificações de convites da vitrine de propósito
class VitrineInviteNotificationComponent extends StatefulWidget {
  const VitrineInviteNotificationComponent({Key? key}) : super(key: key);

  @override
  State<VitrineInviteNotificationComponent> createState() =>
      _VitrineInviteNotificationComponentState();
}

class _VitrineInviteNotificationComponentState
    extends State<VitrineInviteNotificationComponent> {
  List<InterestModel> _pendingInvites = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initializeComponent();
  }

  Future<void> _initializeComponent() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    _currentUserId = currentUser.uid;

    // MatchesController removido - usando sistema de notificações de interesse

    await _loadPendingInvites();
  }

  Future<void> _loadPendingInvites() async {
    if (_currentUserId == null) return;

    try {
      EnhancedLogger.info('Loading pending vitrine invites',
          tag: 'VITRINE_INVITES', data: {'userId': _currentUserId});

      final invites =
          await SpiritualProfileRepository.getPendingInterestsForUser(
              _currentUserId!);

      // Filtrar convites válidos e remover duplicatas
      final validInvites = invites.where((invite) {
        if (invite.fromUserId.isEmpty) {
          EnhancedLogger.error('Filtering out invite with empty fromUserId',
              tag: 'VITRINE_INVITES',
              data: {'inviteId': invite.id, 'toUserId': invite.toUserId});
          return false;
        }
        return true;
      }).toList();

      // Remover duplicatas baseado no fromUserId (manter apenas o mais recente)
      final uniqueInvites = <String, InterestModel>{};
      for (final invite in validInvites) {
        final existingInvite = uniqueInvites[invite.fromUserId];
        if (existingInvite == null ||
            (invite.createdAt != null &&
                existingInvite.createdAt != null &&
                invite.createdAt.isAfter(existingInvite.createdAt))) {
          uniqueInvites[invite.fromUserId] = invite;
        }
      }

      setState(() {
        _pendingInvites = uniqueInvites.values.toList();
        _isLoading = false;
      });

      EnhancedLogger.success('Pending invites loaded',
          tag: 'VITRINE_INVITES',
          data: {
            'userId': _currentUserId,
            'totalInvites': invites.length,
            'uniqueInvites': _pendingInvites.length
          });
    } catch (e) {
      EnhancedLogger.error('Failed to load pending invites',
          tag: 'VITRINE_INVITES', error: e, data: {'userId': _currentUserId});

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleAcceptInvite(InterestModel invite) async {
    try {
      EnhancedLogger.info('Accepting vitrine invite - creating match',
          tag: 'VITRINE_INVITES',
          data: {'from': invite.fromUserId, 'to': invite.toUserId});

      // 1. Criar interesse mútuo no sistema antigo (compatibilidade)
      await SpiritualProfileRepository.createMutualInterest(
          invite.fromUserId, _currentUserId!);

      // 2. Sistema de matches removido - usando notificações de interesse
      // Aqui poderia integrar com o novo sistema se necessário

      // Remover da lista local
      setState(() {
        _pendingInvites.removeWhere((i) => i.id == invite.id);
      });

      // Sistema de matches removido - mostrar feedback simples
      {
        // Fallback para sistema antigo
        Get.snackbar(
          '💕 É um Match!',
          'Vocês têm interesse mútuo! Agora podem conversar no "Nosso Propósito".',
          backgroundColor: Colors.pink[100],
          colorText: Colors.pink[800],
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 5),
          icon: const Icon(Icons.favorite, color: Colors.pink),
        );
      }
    } catch (e) {
      EnhancedLogger.error('Failed to create match',
          tag: 'VITRINE_INVITES',
          error: e,
          data: {'from': invite.fromUserId, 'to': invite.toUserId});

      Get.snackbar(
        'Erro',
        'Não foi possível aceitar o convite. Tente novamente.',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> _handleDeclineInvite(InterestModel invite) async {
    try {
      EnhancedLogger.info('Declining vitrine invite',
          tag: 'VITRINE_INVITES',
          data: {'from': invite.fromUserId, 'to': invite.toUserId});

      // Marcar como inativo (recusado)
      await SpiritualProfileRepository.declineInterest(invite.id!);

      // Remover da lista local
      setState(() {
        _pendingInvites.removeWhere((i) => i.id == invite.id);
      });

      // Mostrar feedback
      Get.snackbar(
        'Convite Recusado',
        'O convite foi recusado respeitosamente.',
        backgroundColor: Colors.orange[100],
        colorText: Colors.orange[800],
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );

      EnhancedLogger.success('Vitrine invite declined',
          tag: 'VITRINE_INVITES',
          data: {'from': invite.fromUserId, 'to': invite.toUserId});
    } catch (e) {
      EnhancedLogger.error('Failed to decline invite',
          tag: 'VITRINE_INVITES',
          error: e,
          data: {'from': invite.fromUserId, 'to': invite.toUserId});

      Get.snackbar(
        'Erro',
        'Não foi possível recusar o convite. Tente novamente.',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> _viewProfile(String? userId) async {
    try {
      if (userId == null || userId.isEmpty) {
        EnhancedLogger.error('Invalid userId for profile view',
            tag: 'VITRINE_INVITES', data: {'userId': userId});

        Get.snackbar(
          'Erro',
          'Não foi possível acessar o perfil. Usuário inválido.',
          backgroundColor: Colors.red[100],
          colorText: Colors.red[800],
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 2),
        );
        return;
      }

      EnhancedLogger.info('Navigating to profile',
          tag: 'VITRINE_INVITES', data: {'userId': userId});

      // Navegar para a vitrine da pessoa
      Get.toNamed('/vitrine-display', arguments: {
        'userId': userId,
        'isOwnProfile': false,
      });
    } catch (e) {
      EnhancedLogger.error('Failed to view profile',
          tag: 'VITRINE_INVITES', error: e, data: {'userId': userId});

      Get.snackbar(
        'Erro',
        'Não foi possível acessar o perfil. Tente novamente.',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    if (_pendingInvites.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children:
            _pendingInvites.map((invite) => _buildInviteCard(invite)).toList(),
      ),
    );
  }

  Widget _buildInviteCard(InterestModel invite) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '💕 Novo Interesse na Vitrine!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Alguém demonstrou interesse em você',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Message
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Uma pessoa especial demonstrou interesse em conhecer você melhor através da sua vitrine de propósito. Que tal dar uma olhada no perfil dela?',
              style: TextStyle(
                color: Colors.white.withOpacity(0.95),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Action buttons
          Column(
            children: [
              // Ver Perfil button (full width)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _viewProfile(invite.fromUserId),
                  icon: const Icon(Icons.visibility,
                      color: Colors.white, size: 18),
                  label: const Text(
                    'Ver Perfil',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Accept and Decline buttons (side by side)
              Row(
                children: [
                  // Accept Button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleAcceptInvite(invite),
                      icon: const Icon(Icons.favorite,
                          color: Colors.pink, size: 18),
                      label: const Text(
                        'Também Tenho Interesse',
                        style: TextStyle(
                          color: Colors.pink,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Decline Button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handleDeclineInvite(invite),
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 16),
                      label: const Text(
                        'Não Tenho',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: Colors.white.withOpacity(0.7), width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
