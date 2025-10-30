import 'package:flutter/material.dart';

/// Card de filtro de altura com dual range slider (91-214 cm)
class HeightFilterCard extends StatelessWidget {
  final int minHeight;
  final int maxHeight;
  final Function(int, int) onHeightChanged;

  const HeightFilterCard({
    Key? key,
    required this.minHeight,
    required this.maxHeight,
    required this.onHeightChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.height,
                    color: Colors.orange.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Faixa de Altura',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'De 91 cm a 214 cm',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Valor atual
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.height,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$minHeight cm - $maxHeight cm',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Dual Range Slider
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: Colors.orange.shade400,
                inactiveTrackColor: Colors.orange.shade100,
                thumbColor: Colors.orange.shade600,
                overlayColor: Colors.orange.shade100,
                valueIndicatorColor: Colors.orange.shade600,
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 12,
                ),
                overlayShape: const RoundSliderOverlayShape(
                  overlayRadius: 24,
                ),
                valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
                valueIndicatorTextStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: Column(
                children: [
                  // Slider para altura mínima
                  Row(
                    children: [
                      Text(
                        'Mín:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: minHeight.toDouble(),
                          min: 91,
                          max: maxHeight.toDouble() - 1,
                          divisions: maxHeight - 92,
                          label: '$minHeight cm',
                          onChanged: (value) {
                            onHeightChanged(value.round(), maxHeight);
                          },
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: Text(
                          '$minHeight cm',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Slider para altura máxima
                  Row(
                    children: [
                      Text(
                        'Máx:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: maxHeight.toDouble(),
                          min: minHeight.toDouble() + 1,
                          max: 214,
                          divisions: 214 - minHeight,
                          label: '$maxHeight cm',
                          onChanged: (value) {
                            onHeightChanged(minHeight, value.round());
                          },
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: Text(
                          '$maxHeight cm',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Marcadores de referência
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildReferenceMarker('91 cm', 'Mínimo'),
                _buildReferenceMarker('150 cm', 'Baixo'),
                _buildReferenceMarker('170 cm', 'Médio'),
                _buildReferenceMarker('190 cm', 'Alto'),
                _buildReferenceMarker('214 cm', 'Máximo'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferenceMarker(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}
