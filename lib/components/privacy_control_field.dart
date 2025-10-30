import 'package:flutter/material.dart';
import 'modern_biography_card.dart';

/// Campo especial com controle de privacidade para a pergunta sobre virgindade
/// Permite ao usuário escolher se a informação será pública ou privada
class PrivacyControlField extends StatefulWidget {
  final String question;
  final List<String> options;
  final String? selectedValue;
  final bool? isPublic;
  final Function(String?) onValueChanged;
  final Function(bool) onPrivacyChanged;
  final String? hint;
  final IconData? icon;

  const PrivacyControlField({
    Key? key,
    required this.question,
    required this.options,
    required this.onValueChanged,
    required this.onPrivacyChanged,
    this.selectedValue,
    this.isPublic,
    this.hint,
    this.icon,
  }) : super(key: key);

  @override
  State<PrivacyControlField> createState() => _PrivacyControlFieldState();
}

class _PrivacyControlFieldState extends State<PrivacyControlField>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // Iniciar animação após um pequeno delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ModernBiographyGradientCard(
          title: widget.question,
          icon: widget.icon ?? Icons.privacy_tip_outlined,
          gradientColors: const [
            Color.fromRGBO(255, 255, 255, 0.98),
            Color.fromRGBO(248, 250, 255, 0.95),
            Color.fromRGBO(240, 245, 255, 0.92),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dropdown para resposta
              _buildResponseDropdown(),
              
              const SizedBox(height: 20),
              
              // Controle de privacidade
              _buildPrivacyControl(),
              
              const SizedBox(height: 12),
              
              // Texto explicativo
              _buildExplanationText(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponseDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Sua resposta:",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: widget.selectedValue,
            hint: Text(
              widget.hint ?? "Selecione uma opção",
              style: TextStyle(
                fontSize: 15,
                color: const Color(0xFF7F8C8D).withOpacity(0.8),
                fontWeight: FontWeight.w400,
              ),
            ),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: const Color(0xFFE9ECEF).withOpacity(0.8),
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: const Color(0xFFE9ECEF).withOpacity(0.8),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF6B73FF),
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            items: widget.options.map((option) => DropdownMenuItem(
              value: option,
              child: Text(
                option,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF2C3E50),
                  fontWeight: FontWeight.w500,
                ),
              ),
            )).toList(),
            onChanged: widget.onValueChanged,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF6B73FF),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyControl() {
    final isPublic = widget.isPublic ?? false;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPublic 
            ? const Color(0xFF6B73FF).withOpacity(0.08)
            : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPublic 
              ? const Color(0xFF6B73FF).withOpacity(0.3)
              : const Color(0xFFE9ECEF).withOpacity(0.8),
          width: 1.5,
        ),
        boxShadow: [
          if (isPublic)
            BoxShadow(
              color: const Color(0xFF6B73FF).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isPublic 
                  ? const Color(0xFF6B73FF).withOpacity(0.15)
                  : const Color(0xFF95A5A6).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isPublic ? Icons.visibility : Icons.visibility_off,
              color: isPublic 
                  ? const Color(0xFF6B73FF)
                  : const Color(0xFF95A5A6),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Tornar esta informação pública",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isPublic 
                        ? const Color(0xFF6B73FF)
                        : const Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isPublic 
                      ? "Visível no seu perfil"
                      : "Informação privada",
                  style: TextStyle(
                    fontSize: 12,
                    color: isPublic 
                        ? const Color(0xFF6B73FF).withOpacity(0.8)
                        : const Color(0xFF7F8C8D),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.9,
            child: Switch(
              value: isPublic,
              onChanged: widget.onPrivacyChanged,
              activeColor: const Color(0xFF6B73FF),
              activeTrackColor: const Color(0xFF6B73FF).withOpacity(0.3),
              inactiveThumbColor: const Color(0xFF95A5A6),
              inactiveTrackColor: const Color(0xFF95A5A6).withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationText() {
    final isPublic = widget.isPublic ?? false;
    
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Container(
        key: ValueKey(isPublic),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isPublic 
              ? const Color(0xFF3498DB).withOpacity(0.08)
              : const Color(0xFF95A5A6).withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isPublic 
                ? const Color(0xFF3498DB).withOpacity(0.2)
                : const Color(0xFF95A5A6).withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isPublic ? Icons.info_outline : Icons.lock_outline,
              color: isPublic 
                  ? const Color(0xFF3498DB)
                  : const Color(0xFF95A5A6),
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isPublic
                    ? "Esta informação será exibida em seu perfil público e poderá ser vista por outros usuários."
                    : "Esta informação permanecerá privada e não será exibida em seu perfil público.",
                style: TextStyle(
                  fontSize: 12,
                  color: isPublic 
                      ? const Color(0xFF3498DB)
                      : const Color(0xFF95A5A6),
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
