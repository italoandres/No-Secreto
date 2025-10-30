import 'package:flutter/material.dart';

/// Componente para seleção de nível educacional
class EducationSelectorComponent extends StatefulWidget {
  final String? selectedEducation;
  final Function(String?) onEducationChanged;
  final Color primaryColor;

  const EducationSelectorComponent({
    super.key,
    this.selectedEducation,
    required this.onEducationChanged,
    required this.primaryColor,
  });

  @override
  State<EducationSelectorComponent> createState() =>
      _EducationSelectorComponentState();
}

class _EducationSelectorComponentState
    extends State<EducationSelectorComponent> {
  String? _selectedEducation;

  // Níveis educacionais disponíveis
  final List<Map<String, String>> _educationLevels = [
    {
      'value': 'ensino_fundamental',
      'label': 'Ensino Fundamental',
      'icon': '📚'
    },
    {'value': 'ensino_medio', 'label': 'Ensino Médio', 'icon': '🎓'},
    {'value': 'ensino_tecnico', 'label': 'Ensino Técnico', 'icon': '🔧'},
    {'value': 'ensino_superior', 'label': 'Ensino Superior', 'icon': '🎓'},
    {'value': 'pos_graduacao', 'label': 'Pós-Graduação', 'icon': '📖'},
    {'value': 'mestrado', 'label': 'Mestrado', 'icon': '🎯'},
    {'value': 'doutorado', 'label': 'Doutorado', 'icon': '🏆'},
    {
      'value': 'prefiro_nao_informar',
      'label': 'Prefiro não informar',
      'icon': '🔒'
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedEducation = widget.selectedEducation;
  }

  void _selectEducation(String value) {
    setState(() {
      _selectedEducation = value;
    });
    widget.onEducationChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Lista de opções
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _educationLevels.length,
          itemBuilder: (context, index) {
            final level = _educationLevels[index];
            final isSelected = _selectedEducation == level['value'];
            final isSpecial = level['value'] == 'prefiro_nao_informar';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => _selectEducation(level['value']!),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? widget.primaryColor.withOpacity(0.1)
                        : (isSpecial ? Colors.orange.shade50 : Colors.white),
                    border: Border.all(
                      color: isSelected
                          ? widget.primaryColor
                          : (isSpecial
                              ? Colors.orange.shade300
                              : Colors.grey.shade300),
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Ícone
                      Text(
                        level['icon']!,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 16),

                      // Label
                      Expanded(
                        child: Text(
                          level['label']!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? widget.primaryColor
                                : (isSpecial
                                    ? Colors.orange.shade700
                                    : Colors.black87),
                          ),
                        ),
                      ),

                      // Check icon
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: widget.primaryColor,
                          size: 24,
                        )
                      else
                        Icon(
                          Icons.radio_button_unchecked,
                          color: Colors.grey.shade400,
                          size: 24,
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
