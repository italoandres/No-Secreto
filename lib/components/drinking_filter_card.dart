import 'package:flutter/material.dart';

class DrinkingFilterCard extends StatelessWidget {
  final String? selectedDrinking;
  final Function(String?) onDrinkingChanged;

  const DrinkingFilterCard({
    Key? key,
    required this.selectedDrinking,
    required this.onDrinkingChanged,
  }) : super(key: key);

  static const List<String> _drinkingOptions = [
    'Não tenho preferência',
    'Não bebe',
    'Bebe socialmente',
    'Bebe regularmente',
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
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.local_bar, color: Colors.amber.shade700, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Beber',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'A pessoa consome bebidas alcoólicas?',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
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
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200, width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.local_bar, color: Colors.amber.shade800, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selectedDrinking ?? 'Não tenho preferência',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade800,
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
              children: _drinkingOptions.map((option) {
                final isSelected = selectedDrinking == option || 
                    (selectedDrinking == null && option == 'Não tenho preferência');
                return FilterChip(
                  label: Text(
                    option,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.amber.shade800,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) {
                    onDrinkingChanged(option == 'Não tenho preferência' ? null : option);
                  },
                  backgroundColor: Colors.grey.shade100,
                  selectedColor: Colors.amber.shade700,
                  checkmarkColor: Colors.white,
                  side: BorderSide(
                    color: isSelected ? Colors.amber.shade700 : Colors.grey.shade300,
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
