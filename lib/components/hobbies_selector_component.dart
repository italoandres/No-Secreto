import 'package:flutter/material.dart';
import '../utils/hobbies_interests_data.dart';

/// Componente para seleção de hobbies e interesses
class HobbiesSelectorComponent extends StatefulWidget {
  final List<String> selectedHobbies;
  final Function(List<String>) onHobbiesChanged;
  final Color primaryColor;
  final int? maxSelection;
  final int minSelection;

  const HobbiesSelectorComponent({
    super.key,
    required this.selectedHobbies,
    required this.onHobbiesChanged,
    required this.primaryColor,
    this.maxSelection,
    this.minSelection = 1,
  });

  @override
  State<HobbiesSelectorComponent> createState() =>
      _HobbiesSelectorComponentState();
}

class _HobbiesSelectorComponentState extends State<HobbiesSelectorComponent> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _selectedHobbies = [];
  List<Map<String, String>> _filteredHobbies = [];
  bool _showSearch = false;
  String _selectedCategory = 'Todos';

  @override
  void initState() {
    super.initState();
    _selectedHobbies = List.from(widget.selectedHobbies);
    _filteredHobbies = HobbiesInterestsData.getAllHobbies();
  }

  void _toggleHobby(String hobbyName) {
    setState(() {
      if (_selectedHobbies.contains(hobbyName)) {
        _selectedHobbies.remove(hobbyName);
      } else {
        // Verificar limite máximo
        if (widget.maxSelection == null ||
            _selectedHobbies.length < widget.maxSelection!) {
          _selectedHobbies.add(hobbyName);
        } else {
          // Mostrar mensagem de limite
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Máximo de ${widget.maxSelection} hobbies permitidos'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }
      }
    });
    widget.onHobbiesChanged(_selectedHobbies);
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredHobbies = _selectedCategory == 'Todos'
            ? HobbiesInterestsData.getAllHobbies()
            : HobbiesInterestsData.getHobbiesByCategory()[_selectedCategory] ??
                [];
      } else {
        _filteredHobbies = HobbiesInterestsData.searchHobbies(query);
      }
    });
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _searchController.clear();
      if (category == 'Todos') {
        _filteredHobbies = HobbiesInterestsData.getAllHobbies();
      } else {
        _filteredHobbies =
            HobbiesInterestsData.getHobbiesByCategory()[category] ?? [];
      }
    });
  }

  Widget _buildHobbyChip(Map<String, String> hobby) {
    final isSelected = _selectedHobbies.contains(hobby['name']);
    return GestureDetector(
      onTap: () => _toggleHobby(hobby['name']!),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? widget.primaryColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? widget.primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: widget.primaryColor.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hobby['emoji']!,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 6),
            Text(
              hobby['name']!,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.check_circle,
                size: 16,
                color: Colors.white,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = [
      'Todos',
      ...HobbiesInterestsData.getHobbiesByCategory().keys
    ];
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;
          return GestureDetector(
            onTap: () => _filterByCategory(category),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? widget.primaryColor.withOpacity(0.1)
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? widget.primaryColor : Colors.grey[300]!,
                ),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? widget.primaryColor : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedCounter() {
    final count = _selectedHobbies.length;
    final minText =
        widget.minSelection > 0 ? ' (mín. ${widget.minSelection})' : '';
    final maxText =
        widget.maxSelection != null ? ' (máx. ${widget.maxSelection})' : '';
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: count >= widget.minSelection
            ? Colors.green.shade50
            : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: count >= widget.minSelection
              ? Colors.green.shade200
              : Colors.orange.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            count >= widget.minSelection
                ? Icons.check_circle
                : Icons.info_outline,
            color: count >= widget.minSelection
                ? Colors.green.shade700
                : Colors.orange.shade700,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              count >= widget.minSelection
                  ? '$count hobbies selecionados$maxText'
                  : 'Selecione pelo menos ${widget.minSelection} hobby$minText$maxText',
              style: TextStyle(
                color: count >= widget.minSelection
                    ? Colors.green.shade700
                    : Colors.orange.shade700,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Contador de selecionados
        _buildSelectedCounter(),
        // Botão de busca
        Row(
          children: [
            Expanded(
              child: Text(
                'Escolha seus hobbies e interesses:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _showSearch = !_showSearch;
                  if (!_showSearch) {
                    _searchController.clear();
                    _onSearchChanged('');
                  }
                });
              },
              icon: Icon(
                _showSearch ? Icons.close : Icons.search,
                color: widget.primaryColor,
              ),
            ),
          ],
        ),
        // Campo de busca
        if (_showSearch) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar hobbies...',
              prefixIcon: Icon(Icons.search, color: widget.primaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: widget.primaryColor, width: 2),
              ),
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 16),
        ],
        // Filtros de categoria (apenas se não estiver buscando)
        if (!_showSearch || _searchController.text.isEmpty)
          _buildCategoryFilter(),
        // Lista de hobbies
        Container(
          constraints: const BoxConstraints(maxHeight: 300),
          child: SingleChildScrollView(
            child: Wrap(
              children: _filteredHobbies
                  .map((hobby) => _buildHobbyChip(hobby))
                  .toList(),
            ),
          ),
        ),
        // Hobbies selecionados (se houver)
        if (_selectedHobbies.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Selecionados (${_selectedHobbies.length}):',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: widget.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            children: _selectedHobbies.map((hobbyName) {
              final hobby = HobbiesInterestsData.getAllHobbies()
                  .firstWhere((h) => h['name'] == hobbyName);
              return _buildHobbyChip(hobby);
            }).toList(),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
