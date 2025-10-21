import 'package:flutter/material.dart';
import '../services/certification_approval_service.dart';
import '../models/certification_request_model.dart';

/// Utilitário para testar o CertificationApprovalService
/// 
/// Execute este arquivo para testar as funcionalidades do serviço:
/// - Stream de certificações pendentes
/// - Stream de histórico
/// - Aprovação de certificações
/// - Reprovação de certificações
class TestCertificationApprovalService extends StatefulWidget {
  @override
  _TestCertificationApprovalServiceState createState() =>
      _TestCertificationApprovalServiceState();
}

class _TestCertificationApprovalServiceState
    extends State<TestCertificationApprovalService> {
  final CertificationApprovalService _service = CertificationApprovalService();
  
  int _pendingCount = 0;
  List<CertificationRequestModel> _pendingCertifications = [];
  List<CertificationRequestModel> _historyCertifications = [];
  
  @override
  void initState() {
    super.initState();
    _setupStreams();
  }
  
  void _setupStreams() {
    // Stream de contagem de pendentes
    _service.getPendingCountStream().listen((count) {
      if (mounted) {
        setState(() {
          _pendingCount = count;
        });
      }
    });
    
    // Stream de certificações pendentes
    _service.getPendingCertificationsStream().listen((certifications) {
      if (mounted) {
        setState(() {
          _pendingCertifications = certifications;
        });
      }
    });
    
    // Stream de histórico
    _service.getCertificationHistoryStream().listen((certifications) {
      if (mounted) {
        setState(() {
          _historyCertifications = certifications;
        });
      }
    });
  }
  
  Future<void> _testApproval(String certificationId) async {
    final success = await _service.approveCertification(
      certificationId,
      'admin@test.com',
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Certificação aprovada com sucesso!'
                : 'Erro ao aprovar certificação',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
  
  Future<void> _testRejection(String certificationId) async {
    final success = await _service.rejectCertification(
      certificationId,
      'admin@test.com',
      'Comprovante inválido - teste',
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Certificação reprovada com sucesso!'
                : 'Erro ao reprovar certificação',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Teste: Approval Service'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card de estatísticas
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estatísticas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          'Pendentes',
                          _pendingCount.toString(),
                          Colors.orange,
                        ),
                        _buildStatItem(
                          'Histórico',
                          _historyCertifications.length.toString(),
                          Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 24),
            
            // Certificações pendentes
            Text(
              'Certificações Pendentes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            
            if (_pendingCertifications.isEmpty)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text('Nenhuma certificação pendente'),
                  ),
                ),
              )
            else
              ..._pendingCertifications.map((cert) {
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cert.userName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          cert.userEmail,
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Solicitado em: ${_formatDate(cert.requestedAt)}',
                          style: TextStyle(fontSize: 12),
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _testApproval(cert.id),
                                icon: Icon(Icons.check),
                                label: Text('Aprovar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _testRejection(cert.id),
                                icon: Icon(Icons.close),
                                label: Text('Reprovar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            
            SizedBox(height: 24),
            
            // Histórico
            Text(
              'Histórico de Certificações',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            
            if (_historyCertifications.isEmpty)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text('Nenhuma certificação no histórico'),
                  ),
                ),
              )
            else
              ..._historyCertifications.take(5).map((cert) {
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                cert.userName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            _buildStatusChip(cert.status),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          cert.userEmail,
                          style: TextStyle(color: Colors.grey),
                        ),
                        if (cert.reviewedBy != null) ...[
                          SizedBox(height: 8),
                          Text(
                            'Processado por: ${cert.reviewedBy}',
                            style: TextStyle(fontSize: 12),
                          ),
                          if (cert.reviewedAt != null)
                            Text(
                              'Em: ${_formatDate(cert.reviewedAt!)}',
                              style: TextStyle(fontSize: 12),
                            ),
                        ],
                        if (cert.rejectionReason != null) ...[
                          SizedBox(height: 8),
                          Text(
                            'Motivo: ${cert.rejectionReason}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatusChip(CertificationStatus status) {
    Color color;
    String label;
    
    switch (status) {
      case CertificationStatus.pending:
        color = Colors.orange;
        label = 'Pendente';
        break;
      case CertificationStatus.approved:
        color = Colors.green;
        label = 'Aprovada';
        break;
      case CertificationStatus.rejected:
        color = Colors.red;
        label = 'Reprovada';
        break;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
