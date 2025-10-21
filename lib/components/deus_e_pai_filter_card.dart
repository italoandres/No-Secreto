import 'package:flutter/material.dart';

class DeusEPaiFilterCard extends StatelessWidget {
  final bool? requiresDeusEPaiMember;
  final Function(bool?) onDeusEPaiChanged;

  const DeusEPaiFilterCard({
    Key? key,
    required this.requiresDeusEPaiMember,
    required this.onDeusEPaiChanged,
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
                    color: Colors.indigo[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.church,
                    color: Colors.indigo[600],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Movimento Deus é Pai',
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
              'Deseja filtrar por participação no movimento Deus é Pai?',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Não tenho preferência'),
                  selected: requiresDeusEPaiMember == null,
                  onSelected: (selected) {
                    if (selected) onDeusEPaiChanged(null);
                  },
                  selectedColor: Colors.indigo[100],
                ),
                ChoiceChip(
                  label: const Text('Apenas membros'),
                  selected: requiresDeusEPaiMember == true,
                  onSelected: (selected) {
                    if (selected) onDeusEPaiChanged(true);
                  },
                  selectedColor: Colors.indigo[100],
                ),
                ChoiceChip(
                  label: const Text('Não membros'),
                  selected: requiresDeusEPaiMember == false,
                  onSelected: (selected) {
                    if (selected) onDeusEPaiChanged(false);
                  },
                  selectedColor: Colors.indigo[100],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
