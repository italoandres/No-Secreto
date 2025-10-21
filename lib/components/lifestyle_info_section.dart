import 'package:flutter/material.dart';

/// Seção que exibe informações de estilo de vida do perfil
/// 
/// Exibe altura, status de fumante e consumo de bebida
class LifestyleInfoSection extends StatelessWidget {
  final String? height;
  final String? smokingStatus;
  final String? drinkingStatus;

  const LifestyleInfoSection({
    Key? key,
    this.height,
    this.smokingStatus,
    this.drinkingStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Se não houver nenhuma informação de estilo de vida, não renderizar
    if (!_hasLifestyleInfo()) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🌟 Estilo de Vida',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Altura
                if (height?.isNotEmpty == true) ...[
                  _buildLifestyleItem(
                    icon: Icons.height,
                    iconColor: Colors.green[600]!,
                    iconBgColor: Colors.green[100]!,
                    label: 'Altura',
                    value: height!,
                  ),
                  if (smokingStatus?.isNotEmpty == true || drinkingStatus?.isNotEmpty == true)
                    const SizedBox(height: 16),
                ],
                
                // Status de Fumante
                if (smokingStatus?.isNotEmpty == true) ...[
                  _buildLifestyleItem(
                    icon: Icons.smoke_free,
                    iconColor: Colors.orange[600]!,
                    iconBgColor: Colors.orange[100]!,
                    label: 'Fumante',
                    value: smokingStatus!,
                  ),
                  if (drinkingStatus?.isNotEmpty == true)
                    const SizedBox(height: 16),
                ],
                
                // Status de Bebida
                if (drinkingStatus?.isNotEmpty == true) ...[
                  _buildLifestyleItem(
                    icon: Icons.local_bar,
                    iconColor: Colors.purple[600]!,
                    iconBgColor: Colors.purple[100]!,
                    label: 'Bebida',
                    value: drinkingStatus!,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói um item de estilo de vida
  Widget _buildLifestyleItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF333333),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Verifica se há informações de estilo de vida
  bool _hasLifestyleInfo() {
    return height?.isNotEmpty == true ||
           smokingStatus?.isNotEmpty == true ||
           drinkingStatus?.isNotEmpty == true;
  }
}
