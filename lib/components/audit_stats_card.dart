import 'package:flutter/material.dart';

/// Card para exibir estatísticas de logs de auditoria
///
/// Mostra:
/// - Título da seção
/// - Lista de estatísticas com valores
/// - Cores personalizadas por item (opcional)
/// - Gráfico de barras simples
class AuditStatsCard extends StatelessWidget {
  final String title;
  final Map<String, int> stats;
  final Map<String, Color>? colors;

  const AuditStatsCard({
    Key? key,
    required this.title,
    required this.stats,
    this.colors,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return SizedBox.shrink();
    }

    final maxValue = stats.values.reduce((a, b) => a > b ? a : b);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 16),

            // Lista de estatísticas
            ...stats.entries.map((entry) {
              final color = colors?[entry.key] ?? Colors.blue;
              final percentage = maxValue > 0 ? entry.value / maxValue : 0.0;

              return Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label e valor
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${entry.value}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 6),

                    // Barra de progresso
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
