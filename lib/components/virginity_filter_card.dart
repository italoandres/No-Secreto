import 'package:flutter/material.dart';

class VirginityFilterCard extends StatelessWidget {
  final String? selectedVirginity;
  final Function(String?) onVirginityChanged;

  const VirginityFilterCard({
    Key? key,
    required this.selectedVirginity,
    required this.onVirginityChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.pink[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.favorite_border,
                    color: Colors.pink[400],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Virgindade',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Filtrar por status de virgindade (campo sensível)',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Não tenho preferência'),
                  selected: selectedVirginity == null ||
                      selectedVirginity == 'Não tenho preferência',
                  onSelected: (selected) {
                    if (selected) onVirginityChanged(null);
                  },
                  selectedColor: Colors.pink[100],
                ),
                ChoiceChip(
                  label: const Text('Virgem'),
                  selected: selectedVirginity == 'Virgem',
                  onSelected: (selected) {
                    if (selected) onVirginityChanged('Virgem');
                  },
                  selectedColor: Colors.pink[100],
                ),
                ChoiceChip(
                  label: const Text('Não virgem'),
                  selected: selectedVirginity == 'Não virgem',
                  onSelected: (selected) {
                    if (selected) onVirginityChanged('Não virgem');
                  },
                  selectedColor: Colors.pink[100],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.pink[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.pink[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.pink[400]),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Campo sensível: apenas perfis que compartilharam essa informação serão filtrados',
                      style: TextStyle(fontSize: 11, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
