import 'package:flutter/material.dart';

class SmokingFilterCard extends StatelessWidget {
  final String? selectedSmoking;
  final Function(String?) onSmokingChanged;

  const SmokingFilterCard({
    Key? key,
    required this.selectedSmoking,
    required this.onSmokingChanged,
  }) : super(key: key);

  static const List<String> _smokingOptions = [
    'Não tenho preferência',
    'Não fuma',
    'Fuma ocasionalmente',
    'Fuma regularmente',
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.smoking_rooms,
                      color: Colors.red.shade600, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fumar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'A pessoa fuma?',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200, width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.smoking_rooms,
                      color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selectedSmoking ?? 'Não tenho preferência',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Selecione uma opção',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _smokingOptions.map((option) {
                final isSelected = selectedSmoking == option ||
                    (selectedSmoking == null &&
                        option == 'Não tenho preferência');
                return FilterChip(
                  label: Text(
                    option,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.red.shade700,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) {
                    onSmokingChanged(
                        option == 'Não tenho preferência' ? null : option);
                  },
                  backgroundColor: Colors.grey.shade100,
                  selectedColor: Colors.red.shade600,
                  checkmarkColor: Colors.white,
                  side: BorderSide(
                    color:
                        isSelected ? Colors.red.shade600 : Colors.grey.shade300,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
