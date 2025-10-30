import 'package:flutter/material.dart';

/// Card com slider para filtro de distância
class DistanceFilterCard extends StatelessWidget {
  final int currentDistance;
  final Function(int) onDistanceChanged;

  const DistanceFilterCard({
    Key? key,
    required this.currentDistance,
    required this.onDistanceChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF7B68EE).withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B68EE).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF7B68EE).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Color(0xFF7B68EE),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Distância de Você',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Até onde você quer buscar?',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Valor atual destacado
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF7B68EE).withOpacity(0.1),
                    const Color(0xFF4169E1).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF7B68EE).withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Text(
                _formatDistance(currentDistance),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7B68EE),
                  letterSpacing: 1,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Slider
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFF7B68EE),
              inactiveTrackColor: const Color(0xFF7B68EE).withOpacity(0.2),
              thumbColor: const Color(0xFF7B68EE),
              overlayColor: const Color(0xFF7B68EE).withOpacity(0.2),
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 12,
                elevation: 4,
              ),
              overlayShape: const RoundSliderOverlayShape(
                overlayRadius: 24,
              ),
              trackHeight: 6,
              valueIndicatorColor: const Color(0xFF7B68EE),
              valueIndicatorTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: Slider(
              value: currentDistance.toDouble(),
              min: 5,
              max: 400,
              divisions: 79, // (400-5)/5 = 79 divisões de 5km
              label: _formatDistance(currentDistance),
              onChanged: (value) {
                // Arredondar para múltiplos de 5
                final roundedValue = (value / 5).round() * 5;
                onDistanceChanged(roundedValue);
              },
            ),
          ),

          const SizedBox(height: 8),

          // Labels min/max
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '5 km',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '400+ km',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Info adicional
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.blue[100]!,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue[700],
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Perfis dentro desta distância da sua cidade',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[900],
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDistance(int distance) {
    if (distance >= 400) {
      return '400+ km';
    }
    return '$distance km';
  }
}
