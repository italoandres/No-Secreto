import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/notification_diagnostic_controller.dart';
import '../components/diagnostic_system_status_card.dart';
import '../components/diagnostic_performance_chart.dart';
import '../components/diagnostic_logs_viewer.dart';
import '../components/diagnostic_manual_controls.dart';
import '../components/diagnostic_health_monitor.dart';

/// Dashboard principal de diagnóstico de notificações
class NotificationDiagnosticDashboard extends StatelessWidget {
  final String? userId;

  const NotificationDiagnosticDashboard({
    Key? key,
    this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NotificationDiagnosticController());

    return Scaffold(
      appBar: AppBar(
        title: Text('Diagnóstico de Notificações'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => controller.refreshAllData(),
            icon: Icon(Icons.refresh),
            tooltip: 'Atualizar dados',
          ),
          PopupMenuButton<String>(
            onSelected: (value) => controller.handleMenuAction(value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'export_logs',
                child: Row(
                  children: [
                    Icon(Icons.download, size: 20),
                    SizedBox(width: 8),
                    Text('Exportar Logs'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear_cache',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, size: 20),
                    SizedBox(width: 8),
                    Text('Limpar Cache'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'reset_system',
                child: Row(
                  children: [
                    Icon(Icons.restore, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Reset Sistema', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade800,
              Colors.blue.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header com informações do usuário
                _buildUserHeader(controller),

                SizedBox(height: 20),

                // Status geral do sistema
                DiagnosticSystemStatusCard(userId: userId),

                SizedBox(height: 20),

                // Monitor de saúde em tempo real
                DiagnosticHealthMonitor(userId: userId),

                SizedBox(height: 20),

                // Controles manuais
                DiagnosticManualControls(userId: userId),

                SizedBox(height: 20),

                // Gráficos de performance
                DiagnosticPerformanceChart(userId: userId),

                SizedBox(height: 20),

                // Visualizador de logs
                DiagnosticLogsViewer(userId: userId),

                SizedBox(height: 20),

                // Ações rápidas
                _buildQuickActions(controller),

                SizedBox(height: 20),

                // Informações do sistema
                _buildSystemInfo(controller),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => controller.runFullDiagnostic(userId),
        icon: Icon(Icons.medical_services),
        label: Text('Diagnóstico Completo'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildUserHeader(NotificationDiagnosticController controller) {
    return Obx(() => Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade400],
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Icon(
                    Icons.person,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userId ?? 'Sistema Global',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Status: ${controller.systemStatus.value}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      Text(
                        'Última atualização: ${controller.lastUpdate.value}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(controller.systemStatus.value),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusText(controller.systemStatus.value),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildQuickActions(NotificationDiagnosticController controller) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ações Rápidas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildQuickActionButton(
                  'Força Sync',
                  Icons.sync,
                  Colors.blue,
                  () => controller.forceSync(userId),
                ),
                _buildQuickActionButton(
                  'Resolver Conflitos',
                  Icons.build_circle,
                  Colors.orange,
                  () => controller.resolveConflicts(userId),
                ),
                _buildQuickActionButton(
                  'Recuperar Dados',
                  Icons.restore,
                  Colors.green,
                  () => controller.recoverData(userId),
                ),
                _buildQuickActionButton(
                  'Validar Sistema',
                  Icons.verified,
                  Colors.purple,
                  () => controller.validateSystem(userId),
                ),
                _buildQuickActionButton(
                  'Limpar Cache',
                  Icons.clear_all,
                  Colors.red.shade400,
                  () => controller.clearCache(userId),
                ),
                _buildQuickActionButton(
                  'Teste Stress',
                  Icons.speed,
                  Colors.teal,
                  () => controller.runStressTest(userId),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildSystemInfo(NotificationDiagnosticController controller) {
    return Obx(() => Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informações do Sistema',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 16),
                _buildInfoRow('Versão', controller.systemVersion.value),
                _buildInfoRow('Uptime', controller.systemUptime.value),
                _buildInfoRow('Memória Usada', controller.memoryUsage.value),
                _buildInfoRow('Cache Size', controller.cacheSize.value),
                _buildInfoRow(
                    'Operações/min', controller.operationsPerMinute.value),
                _buildInfoRow(
                    'Última Sincronização', controller.lastSyncTime.value),
              ],
            ),
          ),
        ));
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'healthy':
      case 'saudável':
        return Colors.green;
      case 'warning':
      case 'atenção':
        return Colors.orange;
      case 'error':
      case 'erro':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'healthy':
        return 'SAUDÁVEL';
      case 'warning':
        return 'ATENÇÃO';
      case 'error':
        return 'ERRO';
      default:
        return 'DESCONHECIDO';
    }
  }
}
