import 'package:flutter/material.dart';

/// Seção que exibe idiomas falados pelo usuário
/// 
/// Exibe lista de idiomas em formato de lista com ícones
class LanguagesSection extends StatelessWidget {
  final List<String>? languages;

  const LanguagesSection({
    Key? key,
    this.languages,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Se não houver idiomas, não renderizar
    if (languages?.isEmpty ?? true) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🗣️ Idiomas',
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
                for (int i = 0; i < languages!.length; i++) ...[
                  _buildLanguageItem(languages![i]),
                  if (i < languages!.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói um item de idioma
  Widget _buildLanguageItem(String language) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.language,
            color: Colors.orange[600],
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            language,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF333333),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        // Badge de nível (se houver)
        if (_hasLevel(language))
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Text(
              _getLevel(language),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.orange[700],
              ),
            ),
          ),
      ],
    );
  }

  /// Verifica se o idioma tem nível especificado
  bool _hasLevel(String language) {
    return language.contains('(') && language.contains(')');
  }

  /// Extrai o nível do idioma
  String _getLevel(String language) {
    if (!_hasLevel(language)) return '';
    
    final start = language.indexOf('(');
    final end = language.indexOf(')');
    
    if (start != -1 && end != -1 && end > start) {
      return language.substring(start + 1, end);
    }
    
    return '';
  }
}
