import 'package:flutter/material.dart';

class CertificationFilterCard extends StatelessWidget {
  final bool? requiresCertification;
  final Function(bool?) onCertificationChanged;

  const CertificationFilterCard({
    Key? key,
    required this.requiresCertification,
    required this.onCertificationChanged,
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
                    color: Colors.amber[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.verified,
                    color: Colors.amber[700],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Selo de Certificação Espiritual',
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
              'Deseja filtrar apenas perfis com selo de certificação espiritual?',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Não tenho preferência'),
                  selected: requiresCertification == null,
                  onSelected: (selected) {
                    if (selected) onCertificationChanged(null);
                  },
                  selectedColor: Colors.amber[100],
                ),
                ChoiceChip(
                  label: const Text('Apenas certificados'),
                  selected: requiresCertification == true,
                  onSelected: (selected) {
                    if (selected) onCertificationChanged(true);
                  },
                  selectedColor: Colors.amber[100],
                ),
                ChoiceChip(
                  label: const Text('Sem certificação'),
                  selected: requiresCertification == false,
                  onSelected: (selected) {
                    if (selected) onCertificationChanged(false);
                  },
                  selectedColor: Colors.amber[100],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
