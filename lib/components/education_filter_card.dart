import 'package:flutter/material.dart';

/// Card de filtro de educação com seleção única
class EducationFilterCard extends StatelessWidget {
  final String? selectedEducation;
  final Function(String?) onEducationChanged;

  const EducationFilterCard({
    Key? key,
    required this.selectedEducation,
    required this.onEducationChanged,
  }) : super(key: key);

  // Níveis de educação disponíveis
  static const List<String> _educationLevels = [
    'Não tenho preferência',
    'Ensino Médio',
    'Ensino Superior',
    'Pós-graduação',
    'Mestrado',
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
            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.school,
                    color: Colors.purple.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Educação',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Qual é o nível de escolaridade da pessoa?',
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

            // Seleção atual
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.purple.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.school,
                    color: Colors.purple.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selectedEducation ?? 'Não tenho preferência',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Opções de educação
            Text(
              'Selecione o nível',
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
              children: _educationLevels.map((level) {
                final isSelected = selectedEducation == level || 
                    (selectedEducation == null && level == 'Não tenho preferência');
                
                return FilterChip(
                  label: Text(
                    level,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.purple.shade700,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) {
                    // Se selecionar "Não tenho preferência", passa null
                    if (level == 'Não tenho preferência') {
                      onEducationChanged(null);
                    } else {
                      onEducationChanged(level);
                    }
                  },
                  backgroundColor: Colors.grey.shade100,
                  selectedColor: Colors.purple.shade600,
                  checkmarkColor: Colors.white,
                  side: BorderSide(
                    color: isSelected ? Colors.purple.shade600 : Colors.grey.shade300,
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
