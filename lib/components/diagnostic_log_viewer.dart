import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import '../services/diagnostic_logger.dart';
import '../utils/enhanced_logger.dart';

/// Visualizador de logs de diagnóstico em tempo real
class DiagnosticLogViewer extends StatefulWidget {
  final String? userId;
  final DiagnosticLogCategory? category;
  final DiagnosticLogLevel? level;
  final bool showRealTime;
  final int maxLogs;

  const DiagnosticLogViewer({
    Key? key,
    this.userId,
    this.category,
    this.level,
    this.showRealTime = true,
    this.maxLogs = 500,
  }) : super(key: key);

  @override
  State<DiagnosticLogViewer> createState() => _DiagnosticLogViewerState();
}

class _DiagnosticLogViewerState extends State<DiagnosticLogViewer> {
  final DiagnosticLogger _logger = DiagnosticLogger();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  List<DiagnosticLogEntry> _logs = [];
  StreamSubscription<DiagnosticLogEntry>? _logSubscription;
  
  DiagnosticLogLevel? _selectedLevel;
  DiagnosticLogCategory? _selectedCategory;
  String _searchText = '';
  bool _autoScroll = true;
  bool _showDetails = false;
  DiagnosticLogEntry? _selectedLog;

  @override
  void initState() {
    super.initState();
    _selectedLevel = widget.level;
    _selectedCategory = widget.category;
    
    _loadLogs();
    
    if (widget.showRealTime) {
      _setupRealTimeUpdates();
    }
  }

  @override
  void dispose() {
    _logSubscription?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadLogs() {
    final filter = DiagnosticLogFilter(
      userId: widget.userId,
      levels: _selectedLevel != null ? [_selectedLevel!] : null,
      categories: _selectedCategory != null ? [_selectedCategory!] : null,
      searchText: _searchText.isNotEmpty ? _searchText : null,
      limit: widget.maxLogs,
    );
    
    setState(() {
      _logs = _logger.getLogs(filter);
    });
  }

  void _setupRealTimeUpdates() {
    _logSubscription = _logger.logStream.listen((newLog) {
      // Verifica se o log atende aos filtros
      final filter = DiagnosticLogFilter(
        userId: widget.userId,
        levels: _selectedLevel != null ? [_selectedLevel!] : null,
        categories: _selectedCategory != null ? [_selectedCategory!] : null,
        searchText: _searchText.isNotEmpty ? _searchText : null,
      );
      
      if (filter.matches(newLog)) {
        setState(() {
          _logs.insert(0, newLog);
          
          // Remove logs antigos se exceder o limite
          if (_logs.length > widget.maxLogs) {
            _logs.removeRange(widget.maxLogs, _logs.length);
          }
        });
        
        // Auto-scroll para o topo se habilitado
        if (_autoScroll && _scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchText = value;
    });
    _loadLogs();
  }

  void _onLevelChanged(DiagnosticLogLevel? level) {
    setState(() {
      _selectedLevel = level;
    });
    _loadLogs();
  }

  void _onCategoryChanged(DiagnosticLogCategory? category) {
    setState(() {
      _selectedCategory = category;
    });
    _loadLogs();
  }

  void _clearLogs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Limpar Logs'),
        content: Text('Tem certeza que deseja limpar todos os logs?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              _logger.clearAllLogs();
              setState(() {
                _logs.clear();
              });
              Navigator.of(context).pop();
            },
            child: Text('Limpar'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  void _exportLogs() {
    final filter = DiagnosticLogFilter(
      userId: widget.userId,
      levels: _selectedLevel != null ? [_selectedLevel!] : null,
      categories: _selectedCategory != null ? [_selectedCategory!] : null,
      searchText: _searchText.isNotEmpty ? _searchText : null,
    );
    
    final exportData = _logger.exportLogsAsJson(filter);
    
    // Copia para clipboard
    Clipboard.setData(ClipboardData(text: exportData));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logs exportados para clipboard'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showLogDetails(DiagnosticLogEntry log) {
    setState(() {
      _selectedLog = log;
      _showDetails = true;
    });
  }

  Color _getLevelColor(DiagnosticLogLevel level) {
    switch (level) {
      case DiagnosticLogLevel.debug:
        return Colors.grey;
      case DiagnosticLogLevel.info:
        return Colors.blue;
      case DiagnosticLogLevel.warning:
        return Colors.orange;
      case DiagnosticLogLevel.error:
        return Colors.red;
      case DiagnosticLogLevel.critical:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilters(),
        _buildToolbar(),
        Expanded(
          child: _showDetails && _selectedLog != null
              ? _buildLogDetails()
              : _buildLogsList(),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Card(
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Barra de pesquisa
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Pesquisar logs...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: _searchText.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(),
              ),
              onChanged: _onSearchChanged,
            ),
            SizedBox(height: 16),
            
            // Filtros
            Row(
              children: [
                // Filtro de nível
                Expanded(
                  child: DropdownButtonFormField<DiagnosticLogLevel?>(
                    value: _selectedLevel,
                    decoration: InputDecoration(
                      labelText: 'Nível',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem<DiagnosticLogLevel?>(
                        value: null,
                        child: Text('Todos os níveis'),
                      ),
                      ...DiagnosticLogLevel.values.map((level) =>
                        DropdownMenuItem<DiagnosticLogLevel?>(
                          value: level,
                          child: Row(
                            children: [
                              Text(_getLevelIcon(level)),
                              SizedBox(width: 8),
                              Text(_getLevelName(level)),
                            ],
                          ),
                        ),
                      ),
                    ],
                    onChanged: _onLevelChanged,
                  ),
                ),
                SizedBox(width: 16),
                
                // Filtro de categoria
                Expanded(
                  child: DropdownButtonFormField<DiagnosticLogCategory?>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Categoria',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem<DiagnosticLogCategory?>(
                        value: null,
                        child: Text('Todas as categorias'),
                      ),
                      ...DiagnosticLogCategory.values.map((category) =>
                        DropdownMenuItem<DiagnosticLogCategory?>(
                          value: category,
                          child: Row(
                            children: [
                              Text(_getCategoryIcon(category)),
                              SizedBox(width: 8),
                              Text(_getCategoryName(category)),
                            ],
                          ),
                        ),
                      ),
                    ],
                    onChanged: _onCategoryChanged,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            '${_logs.length} logs',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Spacer(),
          
          // Auto-scroll toggle
          Row(
            children: [
              Text('Auto-scroll'),
              Switch(
                value: _autoScroll,
                onChanged: (value) {
                  setState(() {
                    _autoScroll = value;
                  });
                },
              ),
            ],
          ),
          SizedBox(width: 16),
          
          // Botões de ação
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadLogs,
            tooltip: 'Atualizar',
          ),
          IconButton(
            icon: Icon(Icons.file_download),
            onPressed: _exportLogs,
            tooltip: 'Exportar',
          ),
          IconButton(
            icon: Icon(Icons.clear_all),
            onPressed: _clearLogs,
            tooltip: 'Limpar logs',
          ),
        ],
      ),
    );
  }

  Widget _buildLogsList() {
    if (_logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhum log encontrado',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        final log = _logs[index];
        return _buildLogItem(log);
      },
    );
  }

  Widget _buildLogItem(DiagnosticLogEntry log) {
    final levelColor = _getLevelColor(log.level);
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: InkWell(
        onTap: () => _showLogDetails(log),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: levelColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(log.levelIcon),
                        SizedBox(width: 4),
                        Text(log.categoryIcon),
                        SizedBox(width: 8),
                        Text(
                          _formatTimestamp(log.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (log.userId != null) ...[
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              log.userId!,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue[800],
                              ),
                            ),
                          ),
                        ],
                        if (log.executionTime != null) ...[
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${log.executionTime!.inMilliseconds}ms',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green[800],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      log.message,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (log.data.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(
                        'Data: ${log.data.toString()}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogDetails() {
    final log = _selectedLog!;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header com botão voltar
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _showDetails = false;
                    _selectedLog = null;
                  });
                },
              ),
              Text(
                'Detalhes do Log',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          // Card principal com detalhes
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabeçalho do log
                  Row(
                    children: [
                      Text(log.levelIcon, style: TextStyle(fontSize: 24)),
                      SizedBox(width: 8),
                      Text(log.categoryIcon, style: TextStyle(fontSize: 24)),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getLevelName(log.level),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _getLevelColor(log.level),
                              ),
                            ),
                            Text(
                              _getCategoryName(log.category),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  
                  // Informações básicas
                  _buildDetailRow('ID', log.id),
                  _buildDetailRow('Timestamp', _formatTimestamp(log.timestamp)),
                  if (log.userId != null) _buildDetailRow('User ID', log.userId!),
                  if (log.executionTime != null) 
                    _buildDetailRow('Tempo de Execução', '${log.executionTime!.inMilliseconds}ms'),
                  
                  SizedBox(height: 16),
                  
                  // Mensagem
                  Text(
                    'Mensagem',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      log.message,
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  
                  // Dados adicionais
                  if (log.data.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Text(
                      'Dados Adicionais',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _formatJson(log.data),
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                  
                  // Stack trace
                  if (log.stackTrace != null) ...[
                    SizedBox(height: 16),
                    Text(
                      'Stack Trace',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        log.stackTrace!,
                        style: TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          SizedBox(height: 16),
          
          // Botões de ação
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: log.message));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Mensagem copiada')),
                    );
                  },
                  icon: Icon(Icons.copy),
                  label: Text('Copiar Mensagem'),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final logJson = log.toJson();
                    Clipboard.setData(ClipboardData(text: _formatJson(logJson)));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Log completo copiado')),
                    );
                  },
                  icon: Icon(Icons.code),
                  label: Text('Copiar JSON'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')} '
           '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:'
           '${timestamp.second.toString().padLeft(2, '0')}';
  }

  String _formatJson(Map<String, dynamic> data) {
    try {
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (e) {
      return data.toString();
    }
  }

  String _getLevelIcon(DiagnosticLogLevel level) {
    switch (level) {
      case DiagnosticLogLevel.debug:
        return '🐛';
      case DiagnosticLogLevel.info:
        return 'ℹ️';
      case DiagnosticLogLevel.warning:
        return '⚠️';
      case DiagnosticLogLevel.error:
        return '❌';
      case DiagnosticLogLevel.critical:
        return '🚨';
    }
  }

  String _getLevelName(DiagnosticLogLevel level) {
    switch (level) {
      case DiagnosticLogLevel.debug:
        return 'Debug';
      case DiagnosticLogLevel.info:
        return 'Info';
      case DiagnosticLogLevel.warning:
        return 'Warning';
      case DiagnosticLogLevel.error:
        return 'Error';
      case DiagnosticLogLevel.critical:
        return 'Critical';
    }
  }

  String _getCategoryIcon(DiagnosticLogCategory category) {
    switch (category) {
      case DiagnosticLogCategory.system:
        return '⚙️';
      case DiagnosticLogCategory.notification:
        return '🔔';
      case DiagnosticLogCategory.sync:
        return '🔄';
      case DiagnosticLogCategory.recovery:
        return '🔧';
      case DiagnosticLogCategory.migration:
        return '📦';
      case DiagnosticLogCategory.performance:
        return '⚡';
      case DiagnosticLogCategory.user:
        return '👤';
      case DiagnosticLogCategory.error:
        return '💥';
    }
  }

  String _getCategoryName(DiagnosticLogCategory category) {
    switch (category) {
      case DiagnosticLogCategory.system:
        return 'Sistema';
      case DiagnosticLogCategory.notification:
        return 'Notificação';
      case DiagnosticLogCategory.sync:
        return 'Sincronização';
      case DiagnosticLogCategory.recovery:
        return 'Recuperação';
      case DiagnosticLogCategory.migration:
        return 'Migração';
      case DiagnosticLogCategory.performance:
        return 'Performance';
      case DiagnosticLogCategory.user:
        return 'Usuário';
      case DiagnosticLogCategory.error:
        return 'Erro';
    }
  }
}