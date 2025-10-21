import 'package:flutter/material.dart';
import '../controllers/certification_pagination_controller.dart';
import '../models/certification_request_model.dart';
import 'certification_request_card.dart';
import 'certification_history_card.dart';

/// Lista paginada de certificações
/// 
/// Componente reutilizável que exibe certificações com paginação automática
/// ao rolar até o final da lista
class PaginatedCertificationList extends StatefulWidget {
  final CertificationPaginationController controller;
  final bool isPendingList;
  final VoidCallback? onCertificationProcessed;
  
  const PaginatedCertificationList({
    Key? key,
    required this.controller,
    this.isPendingList = false,
    this.onCertificationProcessed,
  }) : super(key: key);
  
  @override
  State<PaginatedCertificationList> createState() => _PaginatedCertificationListState();
}

class _PaginatedCertificationListState extends State<PaginatedCertificationList> {
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    widget.controller.addListener(_onControllerUpdate);
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }
  
  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }
  
  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      // Carregar mais quando estiver próximo do final
      widget.controller.loadNextPage();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Estado de carregamento inicial
    if (widget.controller.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.orange),
            SizedBox(height: 16),
            Text('Carregando certificações...'),
          ],
        ),
      );
    }
    
    // Estado de erro
    if (widget.controller.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Erro ao carregar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              widget.controller.error!,
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => widget.controller.refresh(),
              icon: Icon(Icons.refresh),
              label: Text('Tentar Novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
            ),
          ],
        ),
      );
    }
    
    // Lista vazia
    if (widget.controller.certifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.isPendingList 
                  ? Icons.check_circle_outline 
                  : Icons.history,
              size: 64,
              color: widget.isPendingList ? Colors.green : Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              widget.isPendingList
                  ? '✅ Nenhuma certificação pendente'
                  : '📋 Nenhuma certificação no histórico',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              widget.isPendingList
                  ? 'Todas as solicitações foram processadas!'
                  : 'Ainda não há certificações processadas',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    // Lista com dados
    return RefreshIndicator(
      onRefresh: () => widget.controller.refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(16),
        itemCount: widget.controller.certifications.length + 
                   (widget.controller.hasMore ? 1 : 0) + 1, // +1 para o header
        itemBuilder: (context, index) {
          // Header com informações
          if (index == 0) {
            return _buildHeader();
          }
          
          final certIndex = index - 1;
          
          // Indicador de carregamento no final
          if (certIndex >= widget.controller.certifications.length) {
            return _buildLoadingIndicator();
          }
          
          final certification = widget.controller.certifications[certIndex];
          
          return Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: widget.isPendingList
                ? CertificationRequestCard(
                    certification: certification,
                    onApproved: () {
                      widget.controller.removeCertification(certification.id);
                      widget.onCertificationProcessed?.call();
                    },
                    onRejected: () {
                      widget.controller.removeCertification(certification.id);
                      widget.onCertificationProcessed?.call();
                    },
                  )
                : CertificationHistoryCard(
                    certification: certification,
                  ),
          );
        },
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '${widget.controller.totalLoaded} ${widget.isPendingList ? "pendente(s)" : "no histórico"}',
              style: TextStyle(
                color: Colors.orange.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (widget.controller.hasMore)
            Text(
              'Mais disponíveis',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildLoadingIndicator() {
    if (!widget.controller.isLoadingMore) {
      return SizedBox.shrink();
    }
    
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: Column(
        children: [
          CircularProgressIndicator(
            color: Colors.orange,
            strokeWidth: 2,
          ),
          SizedBox(height: 8),
          Text(
            'Carregando mais...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
