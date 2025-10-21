import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/certification_request_model.dart';
import '../components/certification_proof_viewer.dart';

/// Card para exibir uma certificação do histórico
/// 
/// Exibe:
/// - Status final (aprovado/reprovado)
/// - Informações do usuário
/// - Quem processou e quando
/// - Motivo da reprovação (se aplicável)
/// - Comprovante original
class CertificationHistoryCard extends StatelessWidget {
  final CertificationRequestModel certification;

  const CertificationHistoryCard({
    Key? key,
    required this.certification,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isApproved = certification.isApproved;
    final statusColor = isApproved ? Colors.green : Colors.red;
    final statusIcon = isApproved ? Icons.check_circle : Icons.cancel;
    final statusText = isApproved ? 'APROVADO' : 'REPROVADO';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.3), width: 2),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho com status
            _buildHeader(statusColor, statusIcon, statusText),
            
            Divider(height: 24),
            
            // Informações do usuário
            _buildUserInfo(),
            
            SizedBox(height: 12),
            
            // Informações de processamento
            _buildProcessingInfo(),
            
            // Motivo da reprovação (se aplicável)
            if (!isApproved && certification.rejectionReason != null) ...[
              SizedBox(height: 12),
              _buildRejectionReason(),
            ],
            
            SizedBox(height: 12),
            
            // Botão para ver comprovante
            _buildViewProofButton(context),
          ],
        ),
      ),
    );
  }

  /// Cabeçalho com status
  Widget _buildHeader(Color statusColor, IconData statusIcon, String statusText) {
    return Row(
      children: [
        // Ícone de status
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(statusIcon, color: statusColor, size: 32),
        ),
        
        SizedBox(width: 12),
        
        // Nome e status
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                certification.userName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Informações do usuário
  Widget _buildUserInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(
          icon: Icons.email,
          label: 'Email',
          value: certification.userEmail,
        ),
        SizedBox(height: 8),
        _buildInfoRow(
          icon: Icons.shopping_cart,
          label: 'Email de Compra',
          value: certification.purchaseEmail,
        ),
      ],
    );
  }

  /// Informações de processamento
  Widget _buildProcessingInfo() {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final processedDate = certification.processedAt != null
        ? dateFormat.format(certification.processedAt!)
        : 'Data não disponível';

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informações de Processamento',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          _buildInfoRow(
            icon: Icons.person,
            label: 'Processado por',
            value: certification.reviewedBy ?? 'Admin',
            compact: true,
          ),
          SizedBox(height: 6),
          _buildInfoRow(
            icon: Icons.access_time,
            label: 'Data',
            value: processedDate,
            compact: true,
          ),
        ],
      ),
    );
  }

  /// Motivo da reprovação
  Widget _buildRejectionReason() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text(
                'Motivo da Reprovação',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            certification.rejectionReason!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.red[900],
            ),
          ),
        ],
      ),
    );
  }

  /// Botão para ver comprovante
  Widget _buildViewProofButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showFullProof(context),
        icon: Icon(Icons.image),
        label: Text('Ver Comprovante Original'),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  /// Linha de informação
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool compact = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: compact ? 16 : 20, color: Colors.grey[600]),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: compact ? 11 : 12,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: compact ? 12 : 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Mostra o comprovante em tela cheia
  void _showFullProof(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CertificationProofViewer(
          proofUrl: certification.proofFileUrl,
          fileName: certification.proofFileName,
        ),
      ),
    );
  }
}
