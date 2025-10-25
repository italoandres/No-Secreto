import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/certification_request_model.dart';

/// Componente para exibir histórico de solicitações de certificação
class CertificationHistoryComponent extends StatelessWidget {
  final List<CertificationRequestModel> requests;
  final Function(CertificationRequestModel)? onResubmit;
  final bool showResubmitButton;

  const CertificationHistoryComponent({
    Key? key,
    required this.requests,
    this.onResubmit,
    this.showResubmitButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'Histórico de Solicitações',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade800,
                ),
          ),
        ),

        const SizedBox(height: 12),

        // Lista de solicitações
        ...requests.map((request) => _buildRequestCard(context, request)),
      ],
    );
  }

  /// Estado vazio
  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma solicitação ainda',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Suas solicitações aparecerão aqui',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// Card de solicitação
  Widget _buildRequestCard(
      BuildContext context, CertificationRequestModel request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(request.status).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho com status
          Row(
            children: [
              // Ícone de status
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getStatusColor(request.status).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  request.status.icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),

              const SizedBox(width: 12),

              // Status e data
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.status.displayName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(request.status),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(request.requestedAt),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // Badge de status
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(request.status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getStatusBadgeText(request.status),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          // Informações adicionais
          if (request.reviewedAt != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  'Analisado em ${_formatDate(request.reviewedAt!)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ],

          // Motivo da rejeição
          if (request.isRejected && request.rejectionReason != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Motivo da rejeição:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    request.rejectionReason!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.red.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Botão de reenvio
          if (request.canResubmit &&
              showResubmitButton &&
              onResubmit != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => onResubmit!(request),
                icon: const Icon(Icons.refresh),
                label: const Text('Reenviar Solicitação'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],

          // Mensagem de aguardo
          if (request.isPending) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.hourglass_empty,
                    size: 18,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sua solicitação está sendo analisada. Você será notificado em breve.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Mensagem de aprovação
          if (request.isApproved) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 18,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Parabéns! Seu perfil agora exibe o selo de certificação espiritual.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Obter cor do status
  Color _getStatusColor(CertificationStatus status) {
    switch (status) {
      case CertificationStatus.pending:
        return Colors.orange;
      case CertificationStatus.approved:
        return Colors.green;
      case CertificationStatus.rejected:
        return Colors.red;
    }
  }

  /// Obter texto do badge de status
  String _getStatusBadgeText(CertificationStatus status) {
    switch (status) {
      case CertificationStatus.pending:
        return 'EM ANÁLISE';
      case CertificationStatus.approved:
        return 'APROVADO';
      case CertificationStatus.rejected:
        return 'REJEITADO';
    }
  }

  /// Formatar data
  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy \'às\' HH:mm', 'pt_BR').format(date);
  }
}
