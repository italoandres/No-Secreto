import 'package:flutter/material.dart';
import '../services/certification_statistics_service.dart';
import '../components/certification_charts.dart';

/// Dashboard de estatísticas de certificações
/// 
/// Exibe métricas, gráficos e análises do sistema de certificações:
/// - Visão geral com números principais
/// - Gráficos de tendências e distribuição
/// - Ranking de administradores
/// - Métricas de performance
class CertificationDashboardView extends StatefulWidget {
  @override
  _CertificationDashboardViewState createState() => 
      _CertificationDashboardViewState();
}

class _CertificationDashboardViewState extends State<CertificationDashboardView>
    with SingleTickerProviderStateMixin {
  
  final CertificationStatisticsService _statsService = CertificationStatisticsService();
  late TabController _tabController;
  
  // Estados de carregamento
  bool _isLoadingOverall = true;
  bool _isLoadingDaily = true;
  bool _isLoadingAdmin = true;
  bool _isLoadingProcessing = true;
  bool _isLoadingMonthly = true;
  
  // Dados
  CertificationOverallStats? _overallStats;
  List<DailyStats> _dailyStats = [];
  List<AdminStats> _adminStats = [];
  ProcessingTimeStats? _processingStats;
  List<MonthlyTrend> _monthlyTrends = [];
  
  // Configurações
  int _selectedDays = 30;
  int _selectedMonths = 6;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadAllData() async {
    await Future.wait([
      _loadOverallStats(),
      _loadDailyStats(),
      _loadAdminStats(),
      _loadProcessingStats(),
      _loadMonthlyTrends(),
    ]);
  }
  
  Future<void> _loadOverallStats() async {
    setState(() => _isLoadingOverall = true);
    try {
      final stats = await _statsService.getOverallStats();
      if (mounted) {
        setState(() {
          _overallStats = stats;
          _isLoadingOverall = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingOverall = false);
        _showError('Erro ao carregar estatísticas gerais: $e');
      }
    }
  }
  
  Future<void> _loadDailyStats() async {
    setState(() => _isLoadingDaily = true);
    try {
      final stats = await _statsService.getDailyStats(_selectedDays);
      if (mounted) {
        setState(() {
          _dailyStats = stats;
          _isLoadingDaily = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDaily = false);
        _showError('Erro ao carregar estatísticas diárias: $e');
      }
    }
  }
  
  Future<void> _loadAdminStats() async {
    setState(() => _isLoadingAdmin = true);
    try {
      final stats = await _statsService.getAdminRanking();
      if (mounted) {
        setState(() {
          _adminStats = stats;
          _isLoadingAdmin = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAdmin = false);
        _showError('Erro ao carregar ranking de admins: $e');
      }
    }
  }
  
  Future<void> _loadProcessingStats() async {
    setState(() => _isLoadingProcessing = true);
    try {
      final stats = await _statsService.getProcessingTimeStats();
      if (mounted) {
        setState(() {
          _processingStats = stats;
          _isLoadingProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingProcessing = false);
        _showError('Erro ao carregar estatísticas de tempo: $e');
      }
    }
  }
  
  Future<void> _loadMonthlyTrends() async {
    setState(() => _isLoadingMonthly = true);
    try {
      final trends = await _statsService.getMonthlyTrends(_selectedMonths);
      if (mounted) {
        setState(() {
          _monthlyTrends = trends;
          _isLoadingMonthly = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMonthly = false);
        _showError('Erro ao carregar tendências mensais: $e');
      }
    }
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard de Certificações'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadAllData,
            tooltip: 'Atualizar dados',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(icon: Icon(Icons.dashboard), text: 'Visão Geral'),
            Tab(icon: Icon(Icons.trending_up), text: 'Tendências'),
            Tab(icon: Icon(Icons.leaderboard), text: 'Ranking'),
            Tab(icon: Icon(Icons.timer), text: 'Performance'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildTrendsTab(),
          _buildRankingTab(),
          _buildPerformanceTab(),
        ],
      ),
    );
  }
  
  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadOverallStats,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoadingOverall)
              Center(child: CircularProgressIndicator())
            else if (_overallStats != null) ...[
              _buildMetricsGrid(_overallStats!),
              SizedBox(height: 24),
              
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Distribuição por Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: CertificationPieChart(stats: _overallStats!),
                            ),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ChartLegend(
                                    items: [
                                      LegendItem(
                                        color: Colors.orange,
                                        label: 'Pendentes (${_overallStats!.pending})',
                                      ),
                                      LegendItem(
                                        color: Colors.green,
                                        label: 'Aprovadas (${_overallStats!.approved})',
                                      ),
                                      LegendItem(
                                        color: Colors.red,
                                        label: 'Reprovadas (${_overallStats!.rejected})',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildTrendsTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadDailyStats();
        await _loadMonthlyTrends();
      },
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Período: '),
                DropdownButton<int>(
                  value: _selectedDays,
                  items: [7, 15, 30, 60, 90].map((days) {
                    return DropdownMenuItem(
                      value: days,
                      child: Text('$days dias'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedDays = value);
                      _loadDailyStats();
                    }
                  },
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tendências Diárias ($_selectedDays dias)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    if (_isLoadingDaily)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else
                      Column(
                        children: [
                          SizedBox(
                            height: 250,
                            child: DailyTrendsLineChart(dailyStats: _dailyStats),
                          ),
                          SizedBox(height: 16),
                          ChartLegend(
                            items: [
                              LegendItem(color: Colors.blue, label: 'Solicitações'),
                              LegendItem(color: Colors.green, label: 'Aprovações'),
                              LegendItem(color: Colors.red, label: 'Reprovações'),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRankingTab() {
    return RefreshIndicator(
      onRefresh: _loadAdminStats,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ranking de Administradores',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    if (_isLoadingAdmin)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else
                      AdminRankingChart(adminStats: _adminStats),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPerformanceTab() {
    return RefreshIndicator(
      onRefresh: _loadProcessingStats,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tempo de Processamento',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    if (_isLoadingProcessing)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_processingStats != null) ...[
                      _buildProcessingMetrics(_processingStats!),
                      SizedBox(height: 24),
                      SizedBox(
                        height: 250,
                        child: ProcessingTimeBarChart(stats: _processingStats!),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMetricsGrid(CertificationOverallStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          'Total',
          stats.total.toString(),
          Icons.all_inclusive,
          Colors.blue,
        ),
        _buildMetricCard(
          'Pendentes',
          stats.pending.toString(),
          Icons.pending,
          Colors.orange,
        ),
        _buildMetricCard(
          'Aprovadas',
          stats.approved.toString(),
          Icons.check_circle,
          Colors.green,
        ),
        _buildMetricCard(
          'Reprovadas',
          stats.rejected.toString(),
          Icons.cancel,
          Colors.red,
        ),
        _buildMetricCard(
          'Este Mês',
          stats.thisMonth.toString(),
          Icons.calendar_month,
          Colors.purple,
        ),
        _buildMetricCard(
          'Hoje',
          stats.today.toString(),
          Icons.today,
          Colors.teal,
        ),
      ],
    );
  }
  
  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProcessingMetrics(ProcessingTimeStats stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Média',
                '${stats.avgHours.toStringAsFixed(1)}h',
                Colors.blue,
              ),
            ),
            Expanded(
              child: _buildStatItem(
                'Mínimo',
                '${stats.minHours}h',
                Colors.green,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Máximo',
                '${stats.maxHours}h',
                Colors.red,
              ),
            ),
            Expanded(
              child: _buildStatItem(
                'Mediana',
                '${stats.medianHours.toStringAsFixed(1)}h',
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildStatItem(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
