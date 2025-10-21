import 'package:flutter/material.dart';

/// Card de filtro de idiomas com busca e seleção múltipla
class LanguagesFilterCard extends StatefulWidget {
  final List<String> selectedLanguages;
  final Function(List<String>) onLanguagesChanged;

  const LanguagesFilterCard({
    Key? key,
    required this.selectedLanguages,
    required this.onLanguagesChanged,
  }) : super(key: key);

  @override
  State<LanguagesFilterCard> createState() => _LanguagesFilterCardState();
}

class _LanguagesFilterCardState extends State<LanguagesFilterCard> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Idiomas principais em destaque
  static const List<String> _featuredLanguages = [
    'Português',
    'Inglês',
    'Espanhol',
    'Francês',
    'Italiano',
    'Alemão',
  ];

  // Lista completa de idiomas (excluindo os principais para evitar duplicação)
  static const List<String> _otherLanguages = [
    'Árabe',
    'Chinês (Mandarim)',
    'Japonês',
    'Coreano',
    'Russo',
    'Hindi',
    'Bengali',
    'Punjabi',
    'Javanês',
    'Vietnamita',
    'Turco',
    'Polonês',
    'Ucraniano',
    'Holandês',
    'Grego',
    'Sueco',
    'Norueguês',
    'Dinamarquês',
    'Finlandês',
    'Tcheco',
    'Húngaro',
    'Romeno',
    'Tailandês',
    'Hebraico',
    'Indonésio',
    'Malaio',
    'Filipino (Tagalog)',
    'Swahili',
    'Catalão',
    'Croata',
    'Sérvio',
    'Búlgaro',
    'Eslovaco',
    'Esloveno',
    'Lituano',
    'Letão',
    'Estoniano',
    'Islandês',
    'Albanês',
    'Macedônio',
    'Bósnio',
    'Georgiano',
    'Armênio',
    'Persa (Farsi)',
    'Urdu',
    'Pashto',
    'Amárico',
    'Somali',
    'Zulu',
    'Xhosa',
    'Afrikaans',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _filteredLanguages {
    if (_searchQuery.isEmpty) {
      return [];
    }
    // Buscar em todos os idiomas (principais + outros)
    final allLanguages = [..._featuredLanguages, ..._otherLanguages];
    return allLanguages
        .where((lang) => lang.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _toggleLanguage(String language) {
    final newList = List<String>.from(widget.selectedLanguages);
    if (newList.contains(language)) {
      newList.remove(language);
    } else {
      newList.add(language);
    }
    widget.onLanguagesChanged(newList);
  }

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
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.language,
                    color: Colors.blue.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Idiomas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.selectedLanguages.isEmpty
                            ? 'Nenhum idioma selecionado'
                            : '${widget.selectedLanguages.length} ${widget.selectedLanguages.length == 1 ? 'idioma selecionado' : 'idiomas selecionados'}',
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

            // Idiomas selecionados
            if (widget.selectedLanguages.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.shade200,
                    width: 1,
                  ),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.selectedLanguages.map((language) {
                    return Chip(
                      label: Text(
                        language,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () => _toggleLanguage(language),
                      backgroundColor: Colors.blue.shade100,
                      deleteIconColor: Colors.blue.shade700,
                      side: BorderSide(color: Colors.blue.shade300),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Idiomas principais
            Text(
              'Idiomas Principais',
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
              children: _featuredLanguages.map((language) {
                final isSelected = widget.selectedLanguages.contains(language);
                return FilterChip(
                  label: Text(
                    language,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.blue.shade700,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) => _toggleLanguage(language),
                  backgroundColor: Colors.grey.shade100,
                  selectedColor: Colors.blue.shade600,
                  checkmarkColor: Colors.white,
                  side: BorderSide(
                    color: isSelected ? Colors.blue.shade600 : Colors.grey.shade300,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),
            Divider(color: Colors.grey.shade300),
            const SizedBox(height: 16),

            // Subtítulo da busca
            Text(
              'Pesquise idiomas fora das principais',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),

            // Barra de busca
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar idioma...',
                prefixIcon: Icon(Icons.search, color: Colors.blue.shade600),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),

            // Resultados da busca (só aparece quando há busca)
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Resultados da Busca',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 12),
              
              // Idiomas encontrados como FilterChips
              if (_filteredLanguages.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'Nenhum idioma encontrado',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _filteredLanguages.map((language) {
                    final isSelected = widget.selectedLanguages.contains(language);
                    return FilterChip(
                      label: Text(
                        language,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.blue.shade700,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (_) => _toggleLanguage(language),
                      backgroundColor: Colors.grey.shade100,
                      selectedColor: Colors.blue.shade600,
                      checkmarkColor: Colors.white,
                      side: BorderSide(
                        color: isSelected ? Colors.blue.shade600 : Colors.grey.shade300,
                      ),
                    );
                  }).toList(),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
