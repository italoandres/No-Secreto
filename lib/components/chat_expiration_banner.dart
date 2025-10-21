import 'package:flutter/material.dart';
import 'dart:async';

class ChatExpirationBanner extends StatefulWidget {
  final DateTime matchDate;
  final bool isExpired;
  final VoidCallback? onExpired;
  final bool showAnimation;

  const ChatExpirationBanner({
    super.key,
    required this.matchDate,
    required this.isExpired,
    this.onExpired,
    this.showAnimation = true,
  });

  @override
  State<ChatExpirationBanner> createState() => _ChatExpirationBannerState();
}

class _ChatExpirationBannerState extends State<ChatExpirationBanner>
    with TickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startTimer();
  }

  void _setupAnimations() {
    // Animação de pulso para estados críticos
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Animação de slide para entrada
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    if (widget.showAnimation) {
      _slideController.forward();
    } else {
      _slideController.value = 1.0;
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          // Força rebuild para atualizar o tempo
        });
        
        // Verificar se expirou
        if (_isExpired() && widget.onExpired != null) {
          widget.onExpired!();
        }
      }
    });

    // Iniciar animação de pulso se crítico
    if (_isCritical() && !widget.isExpired) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  bool _isExpired() {
    final now = DateTime.now();
    final expirationDate = widget.matchDate.add(const Duration(days: 30));
    return now.isAfter(expirationDate);
  }

  int _getDaysRemaining() {
    if (widget.isExpired || _isExpired()) return 0;
    
    final now = DateTime.now();
    final expirationDate = widget.matchDate.add(const Duration(days: 30));
    final difference = expirationDate.difference(now);
    
    return difference.inDays;
  }

  bool _isCritical() {
    final daysRemaining = _getDaysRemaining();
    return daysRemaining <= 3 && daysRemaining > 0;
  }

  bool _isWarning() {
    final daysRemaining = _getDaysRemaining();
    return daysRemaining <= 7 && daysRemaining > 3;
  }

  Color _getBannerColor() {
    if (widget.isExpired || _isExpired()) {
      return Colors.red[600]!;
    } else if (_isCritical()) {
      return Colors.orange[600]!;
    } else if (_isWarning()) {
      return Colors.amber[600]!;
    } else {
      return const Color(0xFFFF6B9D);
    }
  }

  IconData _getBannerIcon() {
    if (widget.isExpired || _isExpired()) {
      return Icons.block;
    } else if (_isCritical()) {
      return Icons.warning;
    } else if (_isWarning()) {
      return Icons.schedule;
    } else {
      return Icons.favorite_border;
    }
  }

  String _getBannerText() {
    if (widget.isExpired || _isExpired()) {
      return 'Chat Expirado';
    }
    
    final daysRemaining = _getDaysRemaining();
    
    if (daysRemaining == 0) {
      return 'Expira hoje!';
    } else if (daysRemaining == 1) {
      return 'Expira amanhã!';
    } else if (daysRemaining <= 7) {
      return 'Expira em $daysRemaining dias';
    } else {
      return '$daysRemaining dias restantes';
    }
  }

  String _getBannerSubtext() {
    if (widget.isExpired || _isExpired()) {
      return 'Não é mais possível enviar mensagens';
    } else if (_isCritical()) {
      return 'Envie uma mensagem para manter o chat ativo!';
    } else if (_isWarning()) {
      return 'Continue conversando para não perder o contato';
    } else {
      return 'Aproveite para conhecer melhor essa pessoa';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isCritical() && !widget.isExpired ? _pulseAnimation.value : 1.0,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getBannerColor(),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _getBannerColor().withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getBannerIcon(),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getBannerText(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getBannerSubtext(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!widget.isExpired && !_isExpired()) ...[
                    const SizedBox(width: 8),
                    _buildProgressIndicator(),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final daysRemaining = _getDaysRemaining();
    final totalDays = 30;
    final progress = (totalDays - daysRemaining) / totalDays;
    
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        children: [
          CircularProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withValues(alpha: 0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 3,
          ),
          Center(
            child: Text(
              '$daysRemaining',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget compacto para mostrar apenas o tempo restante
class CompactExpirationIndicator extends StatelessWidget {
  final DateTime matchDate;
  final bool isExpired;

  const CompactExpirationIndicator({
    super.key,
    required this.matchDate,
    required this.isExpired,
  });

  int _getDaysRemaining() {
    if (isExpired) return 0;
    
    final now = DateTime.now();
    final expirationDate = matchDate.add(const Duration(days: 30));
    final difference = expirationDate.difference(now);
    
    return difference.inDays.clamp(0, 30);
  }

  Color _getIndicatorColor() {
    if (isExpired) return Colors.red[600]!;
    
    final daysRemaining = _getDaysRemaining();
    if (daysRemaining <= 3) {
      return Colors.orange[600]!;
    } else if (daysRemaining <= 7) {
      return Colors.amber[600]!;
    } else {
      return const Color(0xFFFF6B9D);
    }
  }

  @override
  Widget build(BuildContext context) {
    final daysRemaining = _getDaysRemaining();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getIndicatorColor(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isExpired ? Icons.block : Icons.schedule,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            isExpired ? 'Expirado' : '${daysRemaining}d',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget para mostrar histórico de expiração
class ExpirationHistoryCard extends StatelessWidget {
  final DateTime matchDate;
  final DateTime expirationDate;
  final String otherUserName;

  const ExpirationHistoryCard({
    super.key,
    required this.matchDate,
    required this.expirationDate,
    required this.otherUserName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history,
                color: Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Chat com $otherUserName',
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildDateRow('Match:', matchDate),
          const SizedBox(height: 4),
          _buildDateRow('Expirou:', expirationDate),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.block,
                  color: Colors.red[600],
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Chat expirado após 30 dias',
                  style: TextStyle(
                    color: Colors.red[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRow(String label, DateTime date) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${date.day}/${date.month}/${date.year}',
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}