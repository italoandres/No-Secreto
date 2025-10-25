import 'package:flutter/material.dart';

class DrinkingPreferenceToggleCard extends StatelessWidget {
  final bool isEnabled;
  final Function(bool) onToggle;

  const DrinkingPreferenceToggleCard({
    Key? key,
    required this.isEnabled,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color:
                        isEnabled ? Colors.amber.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isEnabled ? Icons.check_circle : Icons.local_bar,
                    color: isEnabled
                        ? Colors.amber.shade700
                        : Colors.grey.shade400,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tenho mais interesse em pessoas que correspondam esses sinais',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isEnabled ? 'Ativado' : 'Desativado',
                        style: TextStyle(
                          fontSize: 13,
                          color: isEnabled
                              ? Colors.amber.shade700
                              : Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isEnabled,
                  onChanged: onToggle,
                  activeColor: Colors.amber.shade700,
                  activeTrackColor: Colors.amber.shade200,
                ),
              ],
            ),
          ),
          if (isEnabled)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200, width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.amber.shade800, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Dessa forma, podemos saber os sinais de perfil que você tem mais interesse, mas ainda sim pode aparecer outros que não correspondem exatamente.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
