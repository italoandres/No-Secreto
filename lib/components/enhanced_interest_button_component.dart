import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/interest_system_integrator.dart';
import '../models/interest_notification_model.dart';
import '../theme.dart';
import '../utils/enhanced_logger.dart';

/// Componente aprimorado de botão de interesse
class EnhancedInterestButtonComponent extends StatefulWidget {
  final String targetUserId;
  final String targetUserName;
  final String? targetUserEmail;
  final String? customMessage;
  final VoidCallback? onInterestSent;
  final bool showStats;

  const EnhancedInterestButtonComponent({
    Key? key,
    required this.targetUserId,
    required this.targetUserName,
    this.targetUserEmail,
    this.customMessage,
    this.onInterestSent,
    this.showStats = false,
  }) : super(key: key);

  @override
  State<EnhancedInterestButtonComponent> createState() => _EnhancedInterestButtonComponentState();
}

class _EnhancedInterestButtonComponentState extends State<EnhancedInterestButtonComponent>
    with SingleTickerProviderStateMixin {
  final InterestSystemIntegrator _integrator = InterestSystemIntegrator();
  
  bool _isLoading = false;
  bool _hasInterest = false;
  InterestNotificationModel? _existingInterest;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _checkExistingInterest();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingInterest() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid == widget.targetUserId) {
      return;
    }

    try {
      final existing = await _integrator.checkMutualInterest(
        userId1: currentUser.uid,
        userId2: widget.targetUserId,
      );

      if (mounted) {
        setState(() {
          _existingInterest = existing;
          _hasInterest = existing != null;
        });
      }
    } catch (e) {
      EnhancedLogger.error('Erro ao verificar interesse existente: $e', 
        tag: 'ENHANCED_INTEREST_BUTTON'
      );
    }
  }

  Future<void> _sendInterest() async {
    if (_isLoading || _hasInterest) return;

    setState(() {
      _isLoading = true;
    });

    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    final success = await _integrator.sendInterest(
      targetUserId: widget.targetUserId,
      targetUserName: widget.targetUserName,
      targetUserEmail: widget.targetUserEmail,
      message: widget.customMessage,
    );

    if (success) {
      setState(() {
        _hasInterest = true;
      });
      widget.onInterestSent?.call();
      await _checkExistingInterest(); // Atualizar status
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    // Não mostrar para o próprio perfil
    if (currentUser == null || currentUser.uid == widget.targetUserId) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Botão principal
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: _buildMainButton(),
              );
            },
          ),
          
          // Status do interesse
          if (_hasInterest && _existingInterest != null) ...[
            const SizedBox(height: 12),
            _buildInterestStatus(),
          ],

          // Estatísticas (opcional)
          if (widget.showStats) ...[
            const SizedBox(height: 16),
            _buildStatsSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildMainButton() {
    if (_hasInterest) {
      return _buildInterestSentButton();
    }

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _sendInterest,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading) ...[
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                ] else ...[
                  const Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                ],
                Text(
                  _isLoading ? 'Enviando...' : 'Tenho Interesse 💕',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInterestSentButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 24,
            ),
            SizedBox(width: 12),
            Text(
              'Interesse Enviado ✅',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterestStatus() {
    if (_existingInterest == null) return const SizedBox.shrink();

    String statusText;
    Color statusColor;
    IconData statusIcon;

    switch (_existingInterest!.status) {
      case InterestStatus.pending:
        statusText = 'Aguardando resposta...';
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      case InterestStatus.accepted:
        statusText = 'Interesse aceito! 🎉';
        statusColor = Colors.green;
        statusIcon = Icons.celebration;
        break;
      case InterestStatus.rejected:
        statusText = 'Não houve interesse mútuo';
        statusColor = Colors.grey;
        statusIcon = Icons.info;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: statusColor, size: 16),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return FutureBuilder<Map<String, int>>(
      future: _integrator.getInterestStats(widget.targetUserId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final stats = snapshot.data!;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Enviados', stats['sent'] ?? 0, Icons.send),
              _buildStatItem('Recebidos', stats['received'] ?? 0, Icons.inbox),
              _buildStatItem('Aceitos', stats['accepted'] ?? 0, Icons.favorite),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, int value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}