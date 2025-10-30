import 'package:flutter/material.dart';

class HobbiesFilterCard extends StatefulWidget {
  final List<String> selectedHobbies;
  final Function(List<String>) onHobbiesChanged;

  const HobbiesFilterCard({
    Key? key,
    required this.selectedHobbies,
    required this.onHobbiesChanged,
  }) : super(key: key);

  @override
  State<HobbiesFilterCard> createState() => _HobbiesFilterCardState();
}

class _HobbiesFilterCardState extends State<HobbiesFilterCard> {
  final List<String> availableHobbies = [
    'Esportes',
    'Música',
    'Leitura',
    'Cinema',
    'Viagens',
    'Culinária',
    'Arte',
    'Fotografia',
    'Dança',
    'Yoga',
    'Meditação',
    'Voluntariado',
    'Natureza',
    'Tecnologia',
    'Jogos',
    'Escrita',
  ];

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
                    color: Colors.deepPurple[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.interests,
                    color: Colors.deepPurple[500],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hobbies e Interesses',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${widget.selectedHobbies.length} selecionados',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (widget.selectedHobbies.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () => widget.onHobbiesChanged([]),
                    tooltip: 'Limpar seleção',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Selecione hobbies em comum que você procura',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableHobbies.map((hobby) {
                final isSelected = widget.selectedHobbies.contains(hobby);
                return FilterChip(
                  label: Text(hobby),
                  selected: isSelected,
                  onSelected: (selected) {
                    final newHobbies =
                        List<String>.from(widget.selectedHobbies);
                    if (selected) {
                      newHobbies.add(hobby);
                    } else {
                      newHobbies.remove(hobby);
                    }
                    widget.onHobbiesChanged(newHobbies);
                  },
                  selectedColor: Colors.deepPurple[100],
                  checkmarkColor: Colors.deepPurple[500],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
