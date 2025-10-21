import 'package:flutter/material.dart';

/// Seção que exibe hobbies e interesses do perfil
/// 
/// Exibe lista de hobbies em formato de chips/tags
class HobbiesSection extends StatelessWidget {
  final List<String>? hobbies;

  const HobbiesSection({
    Key? key,
    this.hobbies,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Se não houver hobbies, não renderizar
    if (hobbies?.isEmpty ?? true) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎯 Hobbies e Interesses',
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
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: hobbies!.map((hobby) => _buildHobbyChip(hobby)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói um chip de hobby
  Widget _buildHobbyChip(String hobby) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getHobbyIcon(hobby),
            size: 18,
            color: Colors.purple[600],
          ),
          const SizedBox(width: 8),
          Text(
            hobby,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.purple[700],
            ),
          ),
        ],
      ),
    );
  }

  /// Retorna um ícone apropriado para o hobby
  IconData _getHobbyIcon(String hobby) {
    final hobbyLower = hobby.toLowerCase();
    
    // Música
    if (hobbyLower.contains('música') || hobbyLower.contains('musica') || 
        hobbyLower.contains('cantar') || hobbyLower.contains('tocar')) {
      return Icons.music_note;
    }
    
    // Leitura
    if (hobbyLower.contains('ler') || hobbyLower.contains('leitura') || 
        hobbyLower.contains('livro')) {
      return Icons.menu_book;
    }
    
    // Esportes
    if (hobbyLower.contains('esporte') || hobbyLower.contains('futebol') || 
        hobbyLower.contains('corrida') || hobbyLower.contains('academia')) {
      return Icons.sports_soccer;
    }
    
    // Arte
    if (hobbyLower.contains('arte') || hobbyLower.contains('pintura') || 
        hobbyLower.contains('desenho')) {
      return Icons.palette;
    }
    
    // Culinária
    if (hobbyLower.contains('cozinhar') || hobbyLower.contains('culinária') || 
        hobbyLower.contains('culinaria')) {
      return Icons.restaurant;
    }
    
    // Viagem
    if (hobbyLower.contains('viajar') || hobbyLower.contains('viagem')) {
      return Icons.flight;
    }
    
    // Cinema/Filmes
    if (hobbyLower.contains('filme') || hobbyLower.contains('cinema') || 
        hobbyLower.contains('série') || hobbyLower.contains('serie')) {
      return Icons.movie;
    }
    
    // Fotografia
    if (hobbyLower.contains('foto') || hobbyLower.contains('fotografia')) {
      return Icons.camera_alt;
    }
    
    // Jogos
    if (hobbyLower.contains('jogo') || hobbyLower.contains('game')) {
      return Icons.sports_esports;
    }
    
    // Natureza
    if (hobbyLower.contains('natureza') || hobbyLower.contains('trilha') || 
        hobbyLower.contains('camping')) {
      return Icons.nature;
    }
    
    // Padrão
    return Icons.star;
  }
}
