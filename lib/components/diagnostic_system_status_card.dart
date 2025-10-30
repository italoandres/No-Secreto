import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/notification_diagnostic_controller.dart';

/// Card de status do sistema para diagnóstico
class DiagnosticSystemStatusCard extends StatelessWidget {
  final String? userId;

  const DiagnosticSystemStatusCard({
    Key? key,
    this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationDiagnosticController>();

    return Obx(() => Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  _getStatusColor(controller.systemStatus.value)
                      .withOpacity(0.1),
                  _getStatusColor(controller.systemStatus.value)
                      .withOpacity(0.05),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getStatusColor(controller.systemStatus.value)
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getStatusIcon(controller.systemStatus.value),
                        color: _getStatusColor(controller.systemStatus.value),
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status do Sistema',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          Text(
                            controller.systemStatus.value,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(
                                  controller.systemStatus.value),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (controller.isRunningDiagnostic.value)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                            _getStatusColor(controller.systemStatus.value),
                          ),
                        ),
                      ),
                  ],
                ),

                SizedBox(height: 16),

                // Métricas principais
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'Cache',
                        controller.cacheSize.value,
                        Icons.storage,
                        Colors.blue,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        'Memória',
                        controller.memoryUsage.value,
                        Icons.memory,
                        Colors.purple,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        'Ops/min',
                        controller.operationsPerMinute.value,
                        Icons.speed,
                        Colors.green,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Barra de progresso se diagnóstico em andamento
                if (controller.isRunningDiagnostic.value) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.currentAction.value,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: controller.diagnosticProgress.value,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation(
                          _getStatusColor(controller.systemStatus.value),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${(controller.diagnosticProgress.value * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                ],

                // Alertas do sistema
                if (controller.systemAlerts.isNotEmpty) ...[
                  Text(
                    'Alertas Recentes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 100,
                    child: ListView.builder(
                      itemCount: controller.systemAlerts.take(3).length,
                      itemBuilder: (context, index) {
                        final alert = controller.systemAlerts[index];
                        return _buildAlertItem(alert);
                      },
                    ),
                  ),
                ],

                // Informações adicionais
                Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Última atualização: ${controller.lastUpdate.value}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      'Uptime: ${controller.systemUptime.value}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildMetricCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(Map<String, dynamic> alert) {
    final alertColor = _getAlertColor(alert['type']);

    return Container(
      margin: EdgeInsets.only(bottom: 4),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: alertColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: alertColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            _getAlertIcon(alert['type']),
            color: alertColor,
            size: 16,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              alert['message'],
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'saudável':
      case 'healthy':
        return Colors.green;
      case 'atenção':
      case 'warning':
        return Colors.orange;
      case 'erro':
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'saudável':
      case 'healthy':
        return Icons.check_circle;
      case 'atenção':
      case 'warning':
        return Icons.warning;
      case 'erro':
      case 'error':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  Color _getAlertColor(String type) {
    switch (type.toLowerCase()) {
      case 'erro':
      case 'error':
        return Colors.red;
      case 'atenção':
      case 'warning':
        return Colors.orange;
      case 'info':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getAlertIcon(String type) {
    switch (type.toLowerCase()) {
      case 'erro':
      case 'error':
        return Icons.error;
      case 'atenção':
      case 'warning':
        return Icons.warning;
      case 'info':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }
}
