import 'package:flutter/material.dart';
import '../utils/occupations_data.dart';

/// Componente para seleção de profissão com autocomplete
class OccupationSelectorComponent extends StatefulWidget {
  final String? selectedOccupation;
  final Function(String?) onOccupationChanged;
  final Color primaryColor;

  const OccupationSelectorComponent({
    super.key,
    this.selectedOccupation,
    required this.onOccupationChanged,
    required this.primaryColor,
  });

  @override
  State<OccupationSelectorComponent> createState() =>
      _OccupationSelectorComponentState();
}

class _OccupationSelectorComponentState
    extends State<OccupationSelectorComponent> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<String> _suggestions = [];
  bool _showSuggestions = false;
  String? _selectedOccupation;

  @override
  void initState() {
    super.initState();
    _selectedOccupation = widget.selectedOccupation;
    if (_selectedOccupation != null) {
      _searchController.text = _selectedOccupation!;
    }

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        // Pequeno delay para permitir clique nas sugestões
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() {
              _showSuggestions = false;
            });
          }
        });
      }
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _suggestions = [];
        _showSuggestions = false;
      } else {
        _suggestions = OccupationsData.searchOccupations(query);
        _showSuggestions = _suggestions.isNotEmpty;
      }
    });
  }

  void _selectOccupation(String occupation) {
    setState(() {
      _selectedOccupation = occupation;
      _searchController.text = occupation;
      _showSuggestions = false;
      _suggestions = [];
    });
    _focusNode.unfocus();
    widget.onOccupationChanged(occupation);
  }

  void _clearSelection() {
    setState(() {
      _selectedOccupation = null;
      _searchController.clear();
      _suggestions = [];
      _showSuggestions = false;
    });
    widget.onOccupationChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campo de busca
        TextFormField(
          controller: _searchController,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: 'Profissão/Emprego Atual',
            hintText: 'Digite para buscar...',
            prefixIcon: Icon(Icons.work, color: widget.primaryColor),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearSelection,
                  )
                : Icon(Icons.search, color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: widget.primaryColor, width: 2),
            ),
            helperText: 'Ex: Professor, Engenheiro, Médico...',
            helperStyle: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          onChanged: _onSearchChanged,
          onTap: () {
            if (_searchController.text.isNotEmpty) {
              _onSearchChanged(_searchController.text);
            }
          },
        ),

        // Lista de sugestões
        if (_showSuggestions && _suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 250),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.primaryColor.withOpacity(0.05),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        size: 16,
                        color: widget.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_suggestions.length} resultado${_suggestions.length != 1 ? 's' : ''} encontrado${_suggestions.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: widget.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Lista de sugestões
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final occupation = _suggestions[index];
                      final isSelected = _selectedOccupation == occupation;

                      return InkWell(
                        onTap: () => _selectOccupation(occupation),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? widget.primaryColor.withOpacity(0.1)
                                : null,
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.work_outline,
                                size: 20,
                                color: isSelected
                                    ? widget.primaryColor
                                    : Colors.grey[600],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  occupation,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? widget.primaryColor
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  size: 20,
                                  color: widget.primaryColor,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],

        // Mensagem quando não há resultados
        if (_showSuggestions &&
            _suggestions.isEmpty &&
            _searchController.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange.shade700,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nenhuma profissão encontrada',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Você pode digitar manualmente sua profissão',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
