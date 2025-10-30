import 'package:flutter/material.dart';

/// Card de filtro de filhos com seleção única
class ChildrenFilterCard extends StatelessWidget {
  final String? selectedChildren;
  final Function(String?) onChildrenChanged;

  const ChildrenFilterCard({
    Key? key,
    required this.selectedChildren,
    required this.onChildrenChanged,
  }) : super(key: key);

  static const List<String> _childrenOptions = [
    'Não tenho preferência',
    'Tem filhos',
    'Não tem filhos',
  ];

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
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.child_care,
                    color: Colors.teal.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filhos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'A pessoa tem filhos?',
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
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal.shade200, width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.child_care, color: Colors.teal.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selectedChildren ?? 'Não tenho preferência',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade700,
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
              children: _childrenOptions.map((option) {
                final isSelected = selectedChildren == option ||
                    (selectedChildren == null &&
                        option == 'Não tenho preferência');
                return FilterChip(
                  label: Text(
                    option,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.teal.shade700,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) {
                    onChildrenChanged(
                        option == 'Não tenho preferência' ? null : option);
                  },
                  backgroundColor: Colors.grey.shade100,
                  selectedColor: Colors.teal.shade600,
                  checkmarkColor: Colors.white,
                  side: BorderSide(
                    color: isSelected
                        ? Colors.teal.shade600
                        : Colors.grey.shade300,
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
