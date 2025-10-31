import 'package:flutter/material.dart';

class StoryActionMenu extends StatefulWidget {
  final VoidCallback? onCommentTap;
  final VoidCallback? onSaveTap;
  final VoidCallback? onShareTap;
  final VoidCallback? onDownloadTap;
  final VoidCallback? onReplyTap;

  const StoryActionMenu({
    super.key,
    this.onCommentTap,
    this.onSaveTap,
    this.onShareTap,
    this.onDownloadTap,
    this.onReplyTap,
  });

  @override
  State<StoryActionMenu> createState() => _StoryActionMenuState();
}

class _StoryActionMenuState extends State<StoryActionMenu>
    with TickerProviderStateMixin {
  late AnimationController _pulseController1;
  AnimationController? _pulseController2;
  AnimationController? _pulseController3;
  AnimationController? _pulseController4;
  AnimationController? _pulseController5;

  @override
  void initState() {
    super.initState();

    // Controller 1 - Inicia imediatamente
    _pulseController1 = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    // Controller 2 - Inicia após 200ms
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _pulseController2 = AnimationController(
          duration: const Duration(milliseconds: 1000),
          vsync: this,
        )..repeat(reverse: true);
      }
    });

    // Controller 3 - Inicia após 400ms
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _pulseController3 = AnimationController(
          duration: const Duration(milliseconds: 1000),
          vsync: this,
        )..repeat(reverse: true);
      }
    });

    // Controller 4 - Inicia após 600ms
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _pulseController4 = AnimationController(
          duration: const Duration(milliseconds: 1000),
          vsync: this,
        )..repeat(reverse: true);
      }
    });

    // Controller 5 - Inicia após 800ms
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _pulseController5 = AnimationController(
          duration: const Duration(milliseconds: 1000),
          vsync: this,
        )..repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _pulseController1.dispose();
    _pulseController2?.dispose();
    _pulseController3?.dispose();
    _pulseController4?.dispose();
    _pulseController5?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade100,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botão 1: Interaja sobre o tema (primário com pulso)
          _buildPulsingButton(
            controller: _pulseController1,
            icon: Icons.chat_bubble_outline,
            label: 'Interaja sobre o tema',
            onTap: widget.onCommentTap,
            isPrimary: true,
          ),

          const SizedBox(height: 16),

          // Botão 2: Salve em seus favoritos
          if (_pulseController2 != null)
            _buildPulsingButton(
              controller: _pulseController2!,
              icon: Icons.bookmark_border,
              label: 'Salve em seus favoritos',
              onTap: widget.onSaveTap,
            ),

          const SizedBox(height: 16),

          // Botão 3: Cumpra o Ide (Compartilhar)
          if (_pulseController3 != null)
            _buildPulsingButton(
              controller: _pulseController3!,
              icon: Icons.share,
              label: 'Cumpra o Ide (Compartilhar)',
              onTap: widget.onShareTap,
            ),

          const SizedBox(height: 16),

          // Botão 4: Baixe em seu aparelho
          if (_pulseController4 != null)
            _buildPulsingButton(
              controller: _pulseController4!,
              icon: Icons.download,
              label: 'Baixe em seu aparelho',
              onTap: widget.onDownloadTap,
            ),

          const SizedBox(height: 16),

          // Botão 5: Responder ao Pai
          if (_pulseController5 != null)
            _buildPulsingButton(
              controller: _pulseController5!,
              icon: Icons.reply,
              label: 'Responder ao Pai',
              onTap: widget.onReplyTap,
            ),
        ],
      ),
    );
  }

  Widget _buildPulsingButton({
    required AnimationController controller,
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    bool isPrimary = false,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final scale = 1.0 + (controller.value * 0.05); // 1.0 to 1.05

        return Transform.scale(
          scale: scale,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  gradient: isPrimary
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blue.shade400,
                            Colors.purple.shade400,
                          ],
                        )
                      : null,
                  color: isPrimary ? null : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isPrimary
                        ? Colors.transparent
                        : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      color: isPrimary ? Colors.white : Colors.grey.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color:
                              isPrimary ? Colors.white : Colors.grey.shade800,
                          fontSize: 16,
                          fontWeight:
                              isPrimary ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
