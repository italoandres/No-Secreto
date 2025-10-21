import 'package:flutter/material.dart';
import '../services/certification_search_service.dart';

/// Barra de busca avançada para certificações
/// 
/// Componente com funcionalidades:
/// - Busca em tempo real com debounce
/// - Histórico de buscas
/// - Sugestões automáticas
/// - Destaque visual
class CertificationSearchBar extends StatefulWidget {
  final Function(String) onSearch;
  final Function()? onClear;
  final String? initialValue;
  final String? hint;
  
  const CertificationSearchBar({
    Key? key,
    required this.onSearch,
    this.onClear,
    this.initialValue,
    this.hint,
  }) : super(key: key);
  
  @override
  State<CertificationSearchBar> createState() => _CertificationSearchBarState();
}

class _CertificationSearchBarState extends State<CertificationSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final CertificationSearchService _searchService = CertificationSearchService();
  
  List<String> _suggestions = [];
  bool _showSuggestions = false;
  bool _isSearching = false;
  
  @override
  void initState() {
    super.initState();
    
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
    }
    
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
    
    _loadHistory();
  }
  
  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    _searchService.dispose();
    super.dispose();
  }
  
  void _onTextChanged() {
    final text = _controller.text;
    
    if (text.isEmpty) {
      setState(() {
        _isSearching = false;
      });
      widget.onClear?.call();
      _loadHistory();
    } else {
      setState(() {
        _isSearching = true;
      });
      _loadSuggestions(text);
      widget.onSearch(text);
    }
  }
  
  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _loadHistory();
      setState(() {
        _showSuggestions = true;
      });
    } else {
      // Delay para permitir clique nas sugestões
      Future.delayed(Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _showSuggestions = false;
          });
        }
      });
    }
  }
  
  Future<void> _loadHistory() async {
    final history = await _searchService.getSearchHistory();
    if (mounted) {
      setState(() {
        _suggestions = history;
      });
    }
  }
  
  Future<void> _loadSuggestions(String term) async {
    final suggestions = await _searchService.getSuggestions(term);
    if (mounted) {
      setState(() {
        _suggestions = suggestions;
      });
    }
  }
  
  void _selectSuggestion(String suggestion) {
    _controller.text = suggestion;
    _focusNode.unfocus();
    widget.onSearch(suggestion);
  }
  
  Future<void> _clearHistory() async {
    await _searchService.clearSearchHistory();
    setState(() {
      _suggestions = [];
    });
  }
  
  Future<void> _removeFromHistory(String term) async {
    await _searchService.removeFromHistory(term);
    _loadHistory();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Campo de busca
        Container(
          margin: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: widget.hint ?? 'Buscar por nome ou email...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIcon: Icon(
                Icons.search,
                color: _isSearching ? Colors.orange : Colors.grey,
              ),
              suffixIcon: _controller.text.isNotEmpty
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isSearching)
                          Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.orange,
                                ),
                              ),
                            ),
                          ),
                        IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _controller.clear();
                            widget.onClear?.call();
                          },
                        ),
                      ],
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                widget.onSearch(value);
                _focusNode.unfocus();
              }
            },
          ),
        ),
        
        // Sugestões
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.history,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      SizedBox(width: 8),
                      Text(
                        _controller.text.isEmpty
                            ? 'Buscas recentes'
                            : 'Sugestões',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Spacer(),
                      if (_controller.text.isEmpty)
                        TextButton(
                          onPressed: _clearHistory,
                          child: Text(
                            'Limpar',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                Divider(height: 1),
                
                // Lista de sugestões
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = _suggestions[index];
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        _controller.text.isEmpty
                            ? Icons.history
                            : Icons.search,
                        size: 20,
                        color: Colors.grey.shade400,
                      ),
                      title: Text(
                        suggestion,
                        style: TextStyle(fontSize: 14),
                      ),
                      trailing: _controller.text.isEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.close,
                                size: 18,
                                color: Colors.grey.shade400,
                              ),
                              onPressed: () => _removeFromHistory(suggestion),
                            )
                          : null,
                      onTap: () => _selectSuggestion(suggestion),
                    );
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}
