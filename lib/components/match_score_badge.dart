import 'package:flutter/material.dart';
import '../models/match_score.dart';
import 'score_breakdown_sheet.dart';

/// Badge visual com percentual de compatibilidade
class MatchScoreBadge extends StatelessWidget {
  final MatchScore score;

  const MatchScoreBadge({
    Key? key,
    required this.score,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showScoreBreakdown(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: _getGradientColors(score.totalScore),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _getMainColor(score.totalScore).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícone de coração
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            // Texto de compatibilidade
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Compatibilidade',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '${score.totalScore}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getCompatibilityLabel(score.totalScore),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 8),
            // Ícone de info
            Icon(
              Icons.info_outline,
              size: 18,
              color: Colors.white.withOpacity(0.8),
            ),
          ],
        ),
      ),
    );
  }

  /// Exibe modal com breakdown detalhado do score
  void _showScoreBreakdown(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ScoreBreakdownSheet(score: score),
    );
  }

  /// Retorna gradiente baseado no score
  LinearGradient _getGradientColors(double score) {
    if (score >= 90) {
      return const LinearGradient(
        colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (score >= 75) {
      return const LinearGradient(
        colors: [Color(0xFF4169E1), Color(0xFF3A5FCD)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (score >= 60) {
      return const LinearGradient(
        colors: [Color(0xFFF39C12), Color(0xFFE67E22)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      return LinearGradient(
        colors: [Colors.grey[500]!, Colors.grey[600]!],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }

  /// Retorna cor principal baseada no score
  Color _getMainColor(double score) {
    if (score >= 90) return const Color(0xFF2ECC71);
    if (score >= 75) return const Color(0xFF4169E1);
    if (score >= 60) return const Color(0xFFF39C12);
    return Colors.grey[500]!;
  }

  /// Retorna label de compatibilidade
  String _getCompatibilityLabel(double score) {
    if (score >= 90) return 'Excelente';
    if (score >= 75) return 'Muito Boa';
    if (score >= 60) return 'Boa';
    return 'Regular';
  }
}
