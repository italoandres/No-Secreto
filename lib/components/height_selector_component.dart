import 'package:flutter/material.dart';

/// Componente para seleção de altura com tabela de números
class HeightSelectorComponent extends StatefulWidget {
  final String? selectedHeight;
  final Function(String?) onHeightChanged;
  final Color primaryColor;

  const HeightSelectorComponent({
    super.key,
    this.selectedHeight,
    required this.onHeightChanged,
    required this.primaryColor,
  });

  @override
  State<HeightSelectorComponent> createState() => _HeightSelectorComponentState();
}

class _HeightSelectorComponentState extends State<HeightSelectorComponent> {
  String? _selectedHeight;
  bool _showHeightGrid = false;

  @override
  void initState() {
    super.initState();
    _selectedHeight = widget.selectedHeight;
  }

  // Gerar lista de alturas de 1.40m a 2.20m
  List<String> _generateHeights() {
    List<String> heights = [];
    
    // Adicionar alturas de 140cm a 220cm
    for (int cm = 140; cm <= 220; cm++) {
      double meters = cm / 100.0;
      heights.add('${meters.toStringAsFixed(2)}m');
    }
    
    return heights;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campo de seleção de altura
        GestureDetector(
          onTap: () {
            setState(() {
              _showHeightGrid = !_showHeightGrid;
            });
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: _showHeightGrid ? widget.primaryColor : Colors.grey.shade300,
                width: _showHeightGrid ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.height,
                  color: _showHeightGrid ? widget.primaryColor : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedHeight ?? 'Selecione sua altura',
                    style: TextStyle(
                      fontSize: 16,
                      color: _selectedHeight != null ? Colors.black87 : Colors.grey,
                    ),
                  ),
                ),
                Icon(
                  _showHeightGrid ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: widget.primaryColor,
                ),
              ],
            ),
          ),
        ),
        
        // Grid de seleção de altura
        if (_showHeightGrid) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selecione sua altura:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: widget.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Opção "Prefiro não dizer"
                _buildHeightOption('Prefiro não dizer', isSpecial: true),
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                
                // Grid de alturas
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _generateHeights().length,
                  itemBuilder: (context, index) {
                    final heights = _generateHeights();
                    final height = heights[index];
                    return _buildHeightOption(height);
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHeightOption(String height, {bool isSpecial = false}) {
    final isSelected = _selectedHeight == height;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedHeight = height;
          _showHeightGrid = false;
        });
        widget.onHeightChanged(height);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? widget.primaryColor.withOpacity(0.1)
              : (isSpecial ? Colors.orange.shade50 : Colors.white),
          border: Border.all(
            color: isSelected 
                ? widget.primaryColor 
                : (isSpecial ? Colors.orange.shade300 : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            height,
            style: TextStyle(
              fontSize: isSpecial ? 14 : 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected 
                  ? widget.primaryColor 
                  : (isSpecial ? Colors.orange.shade700 : Colors.black87),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
