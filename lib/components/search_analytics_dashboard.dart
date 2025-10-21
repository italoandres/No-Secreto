import 'package:flutter/material.dart';
import '../services/search_analytics_service.dart';
import '../utils/enhanced_logger.dart';

/// Dashboard visual para analytics de busca
/// Exibe métricas, gráficos e insights em tempo real
class SearchAnalyticsDashboard extends StatefulWidget {
  const SearchAnalyticsDashboard({Key? key}) : super(key: key);

  @override
  State<SearchAnalyticsDashboard> createState() => _SearchAnalyticsDashboardState();
}

class _SearchAnalyticsDashboardState extends State<SearchAnalyticsDashboard> {
  Map<String, dynamic>? _analyticsData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final data = SearchAnalyticsService.instance.getAnalyticsReport();
      
      setState(() {
        _analyticsData = data;
        _isLoading = false;
      });

      EnhancedLogger.info('Analytics dashboard loaded successfully', 
        tag: 'SEARCH_ANALYTICS_DASHBOARD',
        data: {
          'totalEvents': data['summary']['totalEvents'],
          'insightsCount': (data['insights'] as List).length,
        }
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });

      EnhancedLogger.error('Failed to load analytics dashboard', 
        tag: 'SEARCH_ANALYTICS_DASHBOARD',
        error: e
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics de Busca'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar analytics',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAnalytics,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (_analyticsData == null) {
      return const Center(
        child: Text('Nenhum dado disponível'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCards(),
            const SizedBox(height: 24),
            _buildPerformanceChart(),
            const SizedBox(height: 24),
            _buildInsights(),
            const SizedBox(height: 24),
            _buildUsagePatterns(),
            const SizedBox(height: 24),
            _buildTopQueries(),
            const SizedBox(height: 24),
            _buildStrategyUsage(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final summary = _analyticsData!['summary'] as Map<String, dynamic>;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumo Geral',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildSummaryCard(
              'Total de Buscas',
              '${summary['totalEvents']}',
              Icons.search,
              Colors.blue,
            ),
            _buildSummaryCard(
              'Buscas Hoje',
              '${summary['todaySearches']}',
              Icons.today,
              Colors.green,
            ),
            _buildSummaryCard(
              'Tempo Médio',
              '${summary['avgExecutionTime'].toStringAsFixed(0)}ms',
              Icons.timer,
              Colors.orange,
            ),
            _buildSummaryCard(
              'Taxa de Cache',
              '${(summary['cacheHitRate'] * 100).toStringAsFixed(1)}%',
              Icons.cached,
              Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceChart() {
    final performanceTrends = _analyticsData!['performanceTrends'] as List;
    
    if (performanceTrends.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tendências de Performance',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 200,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.show_chart,
                    size: 48,
                    color: Colors.blue[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Gráfico de Performance',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${performanceTrends.length} pontos de dados disponíveis',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInsights() {
    final insights = _analyticsData!['insights'] as List;
    
    if (insights.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Insights Automáticos',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...insights.map((insight) => _buildInsightCard(insight)).toList(),
      ],
    );
  }

  Widget _buildInsightCard(Map<String, dynamic> insight) {
    final priority = insight['priority'] as String;
    Color priorityColor;
    IconData priorityIcon;

    switch (priority) {
      case 'InsightPriority.high':
        priorityColor = Colors.red;
        priorityIcon = Icons.warning;
        break;
      case 'InsightPriority.medium':
        priorityColor = Colors.orange;
        priorityIcon = Icons.info;
        break;
      default:
        priorityColor = Colors.green;
        priorityIcon = Icons.check_circle;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  priorityIcon,
                  color: priorityColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    insight['message'] as String,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if ((insight['recommendations'] as List).isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Recomendações:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              ...(insight['recommendations'] as List).map((rec) => Padding(
                padding: const EdgeInsets.only(left: 16, top: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(
                      child: Text(
                        rec as String,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUsagePatterns() {
    final usagePatterns = _analyticsData!['usagePatterns'] as List;
    
    if (usagePatterns.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Padrões de Uso',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...usagePatterns.map((pattern) => _buildPatternCard(pattern)).toList(),
      ],
    );
  }

  Widget _buildPatternCard(Map<String, dynamic> pattern) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    pattern['description'] as String,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(pattern['confidence'] * 100).toStringAsFixed(0)}% confiança',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildPatternData(pattern['data'] as Map<String, dynamic>),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternData(Map<String, dynamic> data) {
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => (b.value as double).compareTo(a.value as double));

    return Column(
      children: sortedEntries.take(5).map((entry) {
        final percentage = entry.value as double;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  entry.key,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Expanded(
                flex: 3,
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopQueries() {
    final topQueries = _analyticsData!['topQueries'] as List;
    
    if (topQueries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Queries Mais Populares',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: topQueries.map((query) {
                final queryText = query['query'] as String;
                final count = query['count'] as int;
                final percentage = query['percentage'] as double;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          queryText.isEmpty ? '(busca vazia)' : queryText,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        '$count (${percentage.toStringAsFixed(1)}%)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStrategyUsage() {
    final strategyUsage = _analyticsData!['strategyUsage'] as Map<String, dynamic>;
    
    if (strategyUsage.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Uso por Estratégia',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: strategyUsage.entries.map((entry) {
                final strategy = entry.key;
                final data = entry.value as Map<String, dynamic>;
                final count = data['count'] as int;
                final percentage = data['percentage'] as double;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _getStrategyDisplayName(strategy),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        '$count (${percentage.toStringAsFixed(1)}%)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  String _getStrategyDisplayName(String strategy) {
    switch (strategy) {
      case 'firebase_simple':
        return 'Firebase Simples';
      case 'display_name':
        return 'Busca por Nome';
      case 'fallback':
        return 'Fallback';
      default:
        return strategy;
    }
  }
}