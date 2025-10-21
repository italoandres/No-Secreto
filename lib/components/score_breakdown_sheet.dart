import 'package:flutter/material.dart';
import '../models/match_score.dart';

/// Modal com breakdown detalhado da pontuação de compatibilidade
class ScoreBreakdownSheet extends StatelessWidget {
  final MatchScore score;

  const ScoreBreakdownSheet({
    Key? key,
    required this.score,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text(
                  'Detalhes da Compatibilidade',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Veja como calculamos a compatibilidade espiritual',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Score total
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4169E1), Color(0xFF3A5FCD)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.favorite, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Text(
                  '${score.totalScore}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Compatível',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Breakdown por categoria
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pontuação por Categoria',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...score.breakdown.entries.map((entry) {
                    return _buildCategoryItem(
                      entry.key,
                      entry.value,
                      _getCategoryIcon(entry.key),
                      _getCategoryColor(entry.key),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),

          // Botão fechar
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4169E1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Entendi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Item de categoria no breakdown com design elegante
  Widget _buildCategoryItem(
    String category,
    double score,
    IconData icon,
    Color color,
  ) {
    final percentage = (score * 100).toInt();
    final lightColor = color.withOpacity(0.7);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.12),
            lightColor.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, lightColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _getCategoryLabel(category),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, lightColor],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '$percentage%',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: score,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, lightColor],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Retorna ícone para categoria
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'distance':
        return Icons.location_on;
      case 'age':
        return Icons.cake;
      case 'height':
        return Icons.height;
      case 'language':
        return Icons.language;
      case 'education':
        return Icons.school;
      case 'children':
        return Icons.child_care;
      case 'drinking':
        return Icons.local_bar;
      case 'smoking':
        return Icons.smoking_rooms;
      case 'certification':
        return Icons.verified;
      case 'deusepai':
        return Icons.church;
      case 'virginity':
        return Icons.favorite_border;
      case 'hobby':
        return Icons.interests;
      default:
        return Icons.star;
    }
  }

  /// Retorna cor para categoria
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'certification':
        return Colors.amber;
      case 'deusepai':
        return Colors.indigo;
      case 'virginity':
        return Colors.pink;
      case 'hobby':
        return Colors.deepPurple;
      case 'education':
        return Colors.blue;
      case 'language':
        return Colors.teal;
      default:
        return const Color(0xFF4169E1);
    }
  }

  /// Retorna label amigável para categoria
  String _getCategoryLabel(String category) {
    switch (category.toLowerCase()) {
      case 'distance':
        return 'Distância';
      case 'age':
        return 'Idade';
      case 'height':
        return 'Altura';
      case 'language':
        return 'Idiomas';
      case 'education':
        return 'Educação';
      case 'children':
        return 'Filhos';
      case 'drinking':
        return 'Bebidas';
      case 'smoking':
        return 'Fumo';
      case 'certification':
        return 'Certificação Espiritual';
      case 'deusepai':
        return 'Movimento Deus é Pai';
      case 'virginity':
        return 'Virgindade';
      case 'hobby':
        return 'Hobbies em Comum';
      default:
        return category;
    }
  }
}
