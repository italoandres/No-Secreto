import 'package:flutter/material.dart';

/// Campo de texto moderno e elegante para ProfileBiographyTaskView
/// Segue o mesmo padrão visual de ProfileIdentityTaskView
class ModernTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final int? maxLines;
  final int? minLines;
  final IconData? icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool enabled;
  final bool obscureText;
  final int? maxLength;
  final TextCapitalization textCapitalization;

  const ModernTextField({
    Key? key,
    required this.label,
    required this.controller,
    this.hint,
    this.maxLines,
    this.minLines,
    this.icon,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.obscureText = false,
    this.maxLength,
    this.textCapitalization = TextCapitalization.sentences,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          maxLines: obscureText ? 1 : maxLines,
          minLines: minLines,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          enabled: enabled,
          obscureText: obscureText,
          maxLength: maxLength,
          textCapitalization: textCapitalization,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 15,
              color: const Color(0xFF7F8C8D).withOpacity(0.8),
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: icon != null
                ? Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B73FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: const Color(0xFF6B73FF),
                      size: 20,
                    ),
                  )
                : null,
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFE74C3C),
                width: 2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFE74C3C),
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFFE9ECEF).withOpacity(0.5),
                width: 1,
              ),
            ),
            filled: true,
            fillColor: enabled
                ? const Color(0xFFF8F9FA)
                : const Color(0xFFF8F9FA).withOpacity(0.5),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            counterStyle: const TextStyle(
              fontSize: 12,
              color: Color(0xFF7F8C8D),
            ),
          ),
        ),
      ],
    );
  }
}
