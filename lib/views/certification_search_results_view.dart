import 'package:flutter/material.dart';
import '../services/certification_search_service.dart';
import '../models/certification_request_model.dart';
import '../components/certification_search_bar.dart';
import '../components/highlighted_certification_text.dart';
import '../components/certification_request_card.dart';
import '../components/certification_history_card.dart';

/// View de resultados de busca de certificações
/// 
/// Exibe resultados de busca com:
/// - Destaque de termos encontrados
/// - Estatísticas de busca
/// - Filtros rápidos
class CertificationSearchResultsView extends StatefulWidget {
  @override
  _CertificationSearchResultsViewState createState() => 
      _CertificationSearchResultsViewState();
}

class _CertificationSearchResultsViewState 
    extends State<CertificationSearchResultsView> {
  
  final CertificationSearchService _searchService = CertificationSearchService();
  
  List<CertificationRequestModel> _results = [];
  String _currentSearchTerm = '';
  bool _isSearching = false;
  String? _selectedStatus;
  DateTime? _searchStartTime;
  
  @override
  void dispose() {
    _searchService.dispose();
    super.dispose();
  }
  
  Future<void> _performSearch(String searchTerm) async {
    if (searchTerm.trim().isEmpty) {
      setState(() {
        _results = [];
        _currentSearchTerm = '';
      });
      return;
    }
    
    setState(() {
      _isSearching = true;
      _currentSearchTerm = searchTerm;
      _searchStartTime = DateTime.now();
    });
    
    try {
      final results = await _searchService.searchCertifications(
        searchTerm: searchTerm,
        status: _selectedStatus,
      );
      
      if (mounted) {
        setState(() {
          _results = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao buscar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _onClear() {
    setState(() {
      _results = [];
      _currentSearchTerm = '';
      _selectedStatus = null;
    });
  }
  
  void _onStatusFilterChanged(String? status) {
    setState(() {
      _selectedStatus = status;
    });
    
    if (_currentSearchTerm.isNotEmpty) {
      _performSearch(_currentSearchTerm);
    }
  }
  
  String _getSearchDuration() {
    if (_searchStartTime == null) return '';
    
    final duration = DateTime.now().difference(_searchStartTime!);
    return '${duration.inMilliseconds}ms';
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Buscar Certificações'),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          // Barra de busca
          CertificationSearchBar(
            onSearch: _performSearch,
            onClear: _onClear,
            hint: 'Buscar por nome, email ou email de compra...',
          ),
          
          // Filtros rápidos
          if (_currentSearchTerm.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Filtrar por status:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(width: 12),
                  _buildStatusChip('Todos', null),
                  SizedBox(width: 8),
                  _buildStatusChip('Pendentes', 'pending'),
                  SizedBox(width: 8),
                  _buildStatusChip('Aprovadas', 'approved'),
                  SizedBox(width: 8),
                  _buildStatusChip('Reprovadas', 'rejected'),
                ],
              ),
            ),
          
          // Estatísticas de busca
          if (_currentSearchTerm.isNotEmpty && !_isSearching)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border(
                  bottom: BorderSide(color: Colors.orange.shade200),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    size: 16,
                    color: Colors.orange.shade700,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_results.length} resultado(s) para "$_currentSearchTerm"',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    _getSearchDuration(),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
          
          // Resultados
          Expanded(
            child: _buildResults(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusChip(String label, String? status) {
    final isSelected = _selectedStatus == status;
    
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : Colors.grey.shade700,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        _onStatusFilterChanged(selected ? status : null);
      },
      selectedColor: Colors.orange,
      checkmarkColor: Colors.white,
      backgroundColor: Colors.grey.shade200,
    );
  }
  
  Widget _buildResults() {
    // Estado de carregamento
    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.orange),
            SizedBox(height: 16),
            Text('Buscando certificações...'),
          ],
        ),
      );
    }
    
    // Estado inicial (sem busca)
    if (_currentSearchTerm.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: 16),
            Text(
              'Digite um nome ou email para buscar',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'A busca é feita em tempo real',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      );
    }
    
    // Sem resultados
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: 16),
            Text(
              'Nenhum resultado encontrado',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tente buscar por outro termo',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      );
    }
    
    // Lista de resultados
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final certification = _results[index];
        
        return Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: _buildResultCard(certification),
        );
      },
    );
  }
  
  Widget _buildResultCard(CertificationRequestModel certification) {
    final isPending = certification.status == CertificationStatus.pending;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nome com destaque
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 20,
                  color: Colors.grey.shade600,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: HighlightedCertificationText(
                    text: certification.userName,
                    searchTerm: _currentSearchTerm,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusBadge(certification.status),
              ],
            ),
            
            SizedBox(height: 12),
            
            // Email com destaque
            Row(
              children: [
                Icon(
                  Icons.email,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: HighlightedCertificationText(
                    text: certification.userEmail,
                    searchTerm: _currentSearchTerm,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 8),
            
            // Email de compra com destaque
            Row(
              children: [
                Icon(
                  Icons.shopping_cart,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: HighlightedCertificationText(
                    text: certification.purchaseEmail,
                    searchTerm: _currentSearchTerm,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12),
            
            // Data
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Colors.grey.shade400,
                ),
                SizedBox(width: 6),
                Text(
                  _formatDate(certification.requestedAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            
            // Botão de ação
            if (isPending) ...[
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navegar para detalhes
                    Navigator.pop(context, certification);
                  },
                  icon: Icon(Icons.visibility),
                  label: Text('Ver Detalhes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusBadge(CertificationStatus status) {
    Color color;
    String label;
    IconData icon;
    
    switch (status) {
      case CertificationStatus.pending:
        color = Colors.orange;
        label = 'Pendente';
        icon = Icons.hourglass_empty;
        break;
      case CertificationStatus.approved:
        color = Colors.green;
        label = 'Aprovada';
        icon = Icons.check_circle;
        break;
      case CertificationStatus.rejected:
        color = Colors.red;
        label = 'Reprovada';
        icon = Icons.cancel;
        break;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
