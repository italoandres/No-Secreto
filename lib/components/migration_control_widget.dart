import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/legacy_system_migrator.dart';
import '../utils/enhanced_logger.dart';

/// Widget para controle manual da migração de sistemas
class MigrationControlWidget extends StatefulWidget {
  final String userId;
  final VoidCallback? onMigrationComplete;

  const MigrationControlWidget({
    Key? key,
    required this.userId,
    this.onMigrationComplete,
  }) : super(key: key);

  @override
  State<MigrationControlWidget> createState() => _MigrationControlWidgetState();
}

class _MigrationControlWidgetState extends State<MigrationControlWidget> {
  final LegacySystemMigrator _migrator = LegacySystemMigrator();
  
  MigrationStatus _currentStatus = MigrationStatus.notStarted;
  bool _isLoading = false;
  String _statusMessage = '';
  Map<String, dynamic> _migrationStats = {};
  List<String> _recommendations = [];

  @override
  void initState() {
    super.initState();
    _updateStatus();
  }

  void _updateStatus() {
    setState(() {
      _currentStatus = _migrator.getMigrationStatus(widget.userId);
      _migrationStats = _migrator.getMigrationStats(widget.userId);
      
      final report = _migrator.getMigrationReport(widget.userId);
      _recommendations = List<String>.from(report['recommendations'] ?? []);
      
      _statusMessage = _getStatusMessage(_currentStatus);
    });
  }

  String _getStatusMessage(MigrationStatus status) {
    switch (status) {
      case MigrationStatus.notStarted:
        return 'Sistema legado ativo. Migração não iniciada.';
      case MigrationStatus.inProgress:
        return 'Migração em progresso...';
      case MigrationStatus.completed:
        return 'Migração concluída com sucesso!';
      case MigrationStatus.failed:
        return 'Migração falhou. Verifique os logs.';
      case MigrationStatus.rollback:
        return 'Sistema revertido para estado anterior.';
    }
  }

  Color _getStatusColor(MigrationStatus status) {
    switch (status) {
      case MigrationStatus.notStarted:
        return Colors.grey;
      case MigrationStatus.inProgress:
        return Colors.orange;
      case MigrationStatus.completed:
        return Colors.green;
      case MigrationStatus.failed:
        return Colors.red;
      case MigrationStatus.rollback:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(MigrationStatus status) {
    switch (status) {
      case MigrationStatus.notStarted:
        return Icons.play_circle_outline;
      case MigrationStatus.inProgress:
        return Icons.sync;
      case MigrationStatus.completed:
        return Icons.check_circle;
      case MigrationStatus.failed:
        return Icons.error;
      case MigrationStatus.rollback:
        return Icons.undo;
    }
  }

  Future<void> _executeMigration() async {
    setState(() {
      _isLoading = true;
    });

    try {
      EnhancedLogger.log('🚀 [MIGRATION_WIDGET] Iniciando migração via interface');
      
      final result = await _migrator.migrateUserToUnifiedSystem(widget.userId);
      
      _updateStatus();
      
      if (result.isSuccess) {
        _showSuccessSnackbar('Migração concluída com sucesso!');
        widget.onMigrationComplete?.call();
      } else {
        _showErrorSnackbar('Migração falhou: ${result.message}');
      }
      
    } catch (e) {
      EnhancedLogger.log('❌ [MIGRATION_WIDGET] Erro na migração: $e');
      _showErrorSnackbar('Erro na migração: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _executeRollback() async {
    setState(() {
      _isLoading = true;
    });

    try {
      EnhancedLogger.log('⏪ [MIGRATION_WIDGET] Iniciando rollback via interface');
      
      final result = await _migrator.rollbackMigration(widget.userId);
      
      _updateStatus();
      
      if (result.isSuccess) {
        _showSuccessSnackbar('Rollback concluído com sucesso!');
      } else {
        _showErrorSnackbar('Rollback falhou: ${result.message}');
      }
      
    } catch (e) {
      EnhancedLogger.log('❌ [MIGRATION_WIDGET] Erro no rollback: $e');
      _showErrorSnackbar('Erro no rollback: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessSnackbar(String message) {
    Get.snackbar(
      'Sucesso',
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      icon: Icon(Icons.check_circle, color: Colors.white),
    );
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Erro',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      icon: Icon(Icons.error, color: Colors.white),
    );
  }

  void _showMigrationDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalhes da Migração'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Status: ${_currentStatus.toString()}'),
              SizedBox(height: 8),
              Text('Duração: ${_migrationStats['duration'] ?? 0}ms'),
              SizedBox(height: 8),
              Text('Sistemas migrados: ${_migrationStats['migratedSystems'] ?? []}'),
              SizedBox(height: 16),
              Text('Recomendações:', style: TextStyle(fontWeight: FontWeight.bold)),
              ..._recommendations.map((rec) => Padding(
                padding: EdgeInsets.only(left: 8, top: 4),
                child: Text('• $rec'),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.system_update,
                  size: 24,
                  color: Theme.of(context).primaryColor,
                ),
                SizedBox(width: 8),
                Text(
                  'Migração de Sistema',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                IconButton(
                  onPressed: _updateStatus,
                  icon: Icon(Icons.refresh),
                  tooltip: 'Atualizar status',
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Status atual
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor(_currentStatus).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getStatusColor(_currentStatus).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(_currentStatus),
                    color: _getStatusColor(_currentStatus),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentStatus.toString().split('.').last.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(_currentStatus),
                          ),
                        ),
                        Text(
                          _statusMessage,
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 16),
            
            // Estatísticas rápidas
            if (_migrationStats.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Duração',
                      '${_migrationStats['duration'] ?? 0}ms',
                      Icons.timer,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Sistemas',
                      '${(_migrationStats['migratedSystems'] as List?)?.length ?? 0}',
                      Icons.apps,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
            ],
            
            // Botões de ação
            Row(
              children: [
                if (_currentStatus == MigrationStatus.notStarted || 
                    _currentStatus == MigrationStatus.failed) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _executeMigration,
                      icon: _isLoading 
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.play_arrow),
                      label: Text(_isLoading ? 'Migrando...' : 'Iniciar Migração'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
                
                if (_currentStatus == MigrationStatus.completed || 
                    _currentStatus == MigrationStatus.failed) ...[
                  if (_currentStatus == MigrationStatus.completed) SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _executeRollback,
                      icon: Icon(Icons.undo),
                      label: Text('Rollback'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
                
                SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _showMigrationDetails,
                  icon: Icon(Icons.info_outline),
                  label: Text('Detalhes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            
            // Recomendações
            if (_recommendations.isNotEmpty) ...[
              SizedBox(height: 16),
              Text(
                'Recomendações:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _recommendations.take(2).map((rec) => Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline, size: 16, color: Colors.blue),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            rec,
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}