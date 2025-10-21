import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/real_time_monitoring_system.dart';
import '../utils/enhanced_logger.dart';

/// Widget de dashboard para monitoramento em tempo real
class MonitoringDashboardWidget extends StatefulWidget {
  const MonitoringDashboardWidget({Key? key}) : super(key: key);

  @override
  State<MonitoringDashboardWidget> createState() => _MonitoringDashboardWidgetState();
}

class _MonitoringDashboardWidgetState extends State<MonitoringDashboardWidget> {
  late Stream<Map<String, dynamic>> _metricsStream;
  
  @override
  void initState() {
    super.initState();
    
    // Inicializa sistema de monitoramento
    RealTimeMonitoringSystem.instance.initialize();
    
    // Cria stream de métricas
    _metricsStream = Stream.periodic(
      const Duration(seconds: 5),
      (_) => RealTimeMonitoringSystem.instance.getRealTimeMetrics()
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.monitor_heart, color: Colors.blue, size: 24),
              SizedBox(width: 8),
              Text(
                '📊 MONITORAMENTO EM TEMPO REAL',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          StreamBuilder<Map<String, dynamic>>(
            stream: _metricsStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              
              final metrics = snapshot.data!;
              final systemMetrics = metrics['metrics'] as Map<String, dynamic>? ?? {};
              
              return Column(
                children: [
                  // Score de Saúde Geral
                  _buildHealthScoreCard(systemMetrics),
                  const SizedBox(height: 12),
                  
                  // Status dos Componentes
                  _buildComponentsStatus(systemMetrics),
                  const SizedBox(height: 12),
                  
                  // Alertas Recentes
                  _buildRecentAlerts(),
                  const SizedBox(height: 12),
                  
                  // Botões de Ação
                  _buildActionButtons(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
  
  /// Constrói card do score de saúde
  Widget _buildHealthScoreCard(Map<String, dynamic> metrics) {
    final healthScore = metrics['lastHealthScore'] as int? ?? 0;
    final averageScore = metrics['averageHealthScore'] as int? ?? 0;
    
    Color scoreColor;
    IconData scoreIcon;
    
    if (healthScore >= 80) {
      scoreColor = Colors.green;
      scoreIcon = Icons.health_and_safety;
    } else if (healthScore >= 60) {
      scoreColor = Colors.orange;
      scoreIcon = Icons.warning;
    } else {
      scoreColor = Colors.red;
      scoreIcon = Icons.error;
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scoreColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scoreColor, width: 1),
      ),
      child: Row(
        children: [
          Icon(scoreIcon, color: scoreColor, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Score de Saúde: $healthScore%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
                Text(
                  'Média: $averageScore%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Constrói status dos componentes
  Widget _buildComponentsStatus(Map<String, dynamic> metrics) {
    final components = [
      'jsErrorHandler',
      'repository', 
      'converter',
      'errorRecovery',
      'syncManager',
      'pipeline',
      'matchesController'
    ];
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status dos Componentes',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...components.map((component) {
            final componentData = metrics[component] as Map<String, dynamic>?;
            final status = componentData?['status'] as String? ?? 'unknown';
            
            Color statusColor;
            IconData statusIcon;
            
            switch (status) {
              case 'healthy':
                statusColor = Colors.green;
                statusIcon = Icons.check_circle;
                break;
              case 'warning':
                statusColor = Colors.orange;
                statusIcon = Icons.warning;
                break;
              case 'critical':
              case 'error':
                statusColor = Colors.red;
                statusIcon = Icons.error;
                break;
              default:
                statusColor = Colors.grey;
                statusIcon = Icons.help;
            }
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getComponentDisplayName(component),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
  
  /// Constrói alertas recentes
  Widget _buildRecentAlerts() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notifications, color: Colors.red, size: 16),
              SizedBox(width: 8),
              Text(
                'Alertas Recentes',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          FutureBuilder<List<Map<String, dynamic>>>(
            future: Future.value(RealTimeMonitoringSystem.instance.getRecentAlerts(limit: 3)),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text(
                  'Nenhum alerta recente',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                );
              }
              
              return Column(
                children: snapshot.data!.map((alert) {
                  final severity = alert['severity'] as String;
                  final title = alert['title'] as String;
                  final timestamp = DateTime.parse(alert['timestamp'] as String);
                  
                  Color alertColor;
                  switch (severity) {
                    case 'critical':
                      alertColor = Colors.red;
                      break;
                    case 'warning':
                      alertColor = Colors.orange;
                      break;
                    default:
                      alertColor = Colors.blue;
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Icon(Icons.circle, color: alertColor, size: 8),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatTime(timestamp),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
  
  /// Constrói botões de ação
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              RealTimeMonitoringSystem.instance.forceCheck();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Verificação forçada executada!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Verificar Agora', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              _showDetailedReport();
            },
            icon: const Icon(Icons.analytics, size: 16),
            label: const Text('Relatório', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ],
    );
  }
  
  /// Obtém nome de exibição do componente
  String _getComponentDisplayName(String component) {
    switch (component) {
      case 'jsErrorHandler':
        return 'JS Error Handler';
      case 'repository':
        return 'Repository';
      case 'converter':
        return 'Converter';
      case 'errorRecovery':
        return 'Error Recovery';
      case 'syncManager':
        return 'Sync Manager';
      case 'pipeline':
        return 'Pipeline';
      case 'matchesController':
        return 'Matches Controller';
      default:
        return component;
    }
  }
  
  /// Formata timestamp
  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inMinutes < 1) {
      return 'agora';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else {
      return '${diff.inDays}d';
    }
  }
  
  /// Mostra relatório detalhado
  void _showDetailedReport() {
    final metrics = RealTimeMonitoringSystem.instance.getRealTimeMetrics();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Relatório Detalhado'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Monitoramento Ativo: ${metrics['monitoringActive']}'),
              Text('Sistema de Alertas: ${metrics['alertSystemActive']}'),
              Text('Total de Alertas: ${metrics['alertsCount']}'),
              Text('Callbacks Registrados: ${metrics['callbacksCount']}'),
              const SizedBox(height: 16),
              const Text('Métricas Detalhadas:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(metrics.toString()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}
                    color: scoreColor,
                  ),
                ),
                Text(
                  'Média: $averageScore%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            healthScore >= 80 ? 'Saudável' : healthScore >= 60 ? 'Atenção' : 'Crítico',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: scoreColor,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Constrói status dos componentes
  Widget _buildComponentsStatus(Map<String, dynamic> metrics) {
    final components = [
      {'name': 'JavaScript Handler', 'key': 'jsErrorHandler'},
      {'name': 'Repository', 'key': 'repository'},
      {'name': 'Converter', 'key': 'converter'},
      {'name': 'Error Recovery', 'key': 'errorRecovery'},
      {'name': 'Sync Manager', 'key': 'syncManager'},
      {'name': 'Pipeline', 'key': 'pipeline'},
      {'name': 'Matches Controller', 'key': 'matchesController'},
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status dos Componentes:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...components.map((component) {
          final componentData = metrics[component['key']] as Map<String, dynamic>?;
          final status = componentData?['status'] as String? ?? 'unknown';
          
          Color statusColor;
          IconData statusIcon;
          
          switch (status) {
            case 'healthy':
              statusColor = Colors.green;
              statusIcon = Icons.check_circle;
              break;
            case 'warning':
              statusColor = Colors.orange;
              statusIcon = Icons.warning;
              break;
            case 'critical':
            case 'error':
              statusColor = Colors.red;
              statusIcon = Icons.error;
              break;
            default:
              statusColor = Colors.grey;
              statusIcon = Icons.help;
          }
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    component['name']!,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
  
  /// Constrói alertas recentes
  Widget _buildRecentAlerts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Alertas Recentes:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 100,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: Future.value(RealTimeMonitoringSystem.instance.getRecentAlerts(limit: 5)),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    'Nenhum alerta recente',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.all(4),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final alert = snapshot.data![index];
                  final severity = alert['severity'] as String;
                  
                  Color alertColor;
                  switch (severity) {
                    case 'critical':
                      alertColor = Colors.red;
                      break;
                    case 'warning':
                      alertColor = Colors.orange;
                      break;
                    default:
                      alertColor = Colors.blue;
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: alertColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            alert['title'] as String,
                            style: const TextStyle(fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
  
  /// Constrói botões de ação
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              RealTimeMonitoringSystem.instance.forceCheck();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Verificação forçada executada!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text(
              'Verificar Agora',
              style: TextStyle(fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              _showDetailedMetrics();
            },
            icon: const Icon(Icons.analytics, size: 16),
            label: const Text(
              'Detalhes',
              style: TextStyle(fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ],
    );
  }
  
  /// Mostra métricas detalhadas
  void _showDetailedMetrics() {
    final metrics = RealTimeMonitoringSystem.instance.getRealTimeMetrics();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Métricas Detalhadas'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Sistema Inicializado: ${metrics['isInitialized']}'),
              Text('Monitoramento Ativo: ${metrics['monitoringActive']}'),
              Text('Sistema de Alertas Ativo: ${metrics['alertSystemActive']}'),
              Text('Total de Alertas: ${metrics['alertsCount']}'),
              Text('Callbacks Registrados: ${metrics['callbacksCount']}'),
              const SizedBox(height: 16),
              const Text(
                'Componentes:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...((metrics['metrics'] as Map<String, dynamic>?) ?? {}).entries
                  .where((entry) => entry.value is Map<String, dynamic>)
                  .map((entry) {
                final componentData = entry.value as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.key}:',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('  Status: ${componentData['status']}'),
                      Text('  Última Verificação: ${componentData['lastCheck']}'),
                      if (componentData['error'] != null)
                        Text('  Erro: ${componentData['error']}'),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    super.dispose();
  }
}