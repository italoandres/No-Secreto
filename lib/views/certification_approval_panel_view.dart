import 'package:flutter/material.dart';
import '../services/certification_approval_service.dart';
import '../models/certification_request_model.dart';
import '../components/certification_request_card.dart';
import '../components/certification_history_card.dart';

/// Painel administrativo para aprovação de certificações espirituais
/// 
/// Esta view permite que administradores:
/// - Visualizem certificações pendentes em tempo real
/// - Aprovem ou reprovem certificações
/// - Acessem o histórico de certificações processadas
/// - Filtrem certificações por status
class CertificationApprovalPanelView extends StatefulWidget {
  @override
  _CertificationApprovalPanelViewState createState() => 
      _CertificationApprovalPanelViewState();
}

class _CertificationApprovalPanelViewState 
    extends State<CertificationApprovalPanelView> with SingleTickerProviderStateMixin {
  final CertificationApprovalService _service = CertificationApprovalService();
  late TabController _tabController;
  bool _isAdmin = false;
  bool _isLoadingPermissions = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkAdminPermissions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Verifica se o usuário atual é administrador
  Future<void> _checkAdminPermissions() async {
    // Por enquanto, assume que todos têm acesso
    // TODO: Implementar verificação real de permissões de admin
    if (mounted) {
      setState(() {
        _isAdmin = true;
        _isLoadingPermissions = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPermissions) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Painel de Certificações'),
          backgroundColor: Colors.orange,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.orange),
              SizedBox(height: 16),
              Text('Verificando permissões...'),
            ],
          ),
        ),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Acesso Negado'),
          backgroundColor: Colors.red,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.block, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Você não tem permissão para acessar este painel',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Painel de Certificações'),
        backgroundColor: Colors.orange,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              icon: Icon(Icons.pending_actions),
              text: 'Pendentes',
            ),
            Tab(
              icon: Icon(Icons.history),
              text: 'Histórico',
            ),
          ],
        ),
        actions: [
          // Contador de pendentes
          StreamBuilder<int>(
            stream: _service.getPendingCountStream(),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              
              if (count == 0) return SizedBox.shrink();
              
              return Padding(
                padding: EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  /// Aba de certificações pendentes
  Widget _buildPendingTab() {
    return StreamBuilder<List<CertificationRequestModel>>(
      stream: _service.getPendingCertificationsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.orange),
                SizedBox(height: 16),
                Text('Carregando certificações pendentes...'),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Erro ao carregar certificações',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {}); // Força rebuild para tentar novamente
                  },
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

        final certifications = snapshot.data ?? [];

        if (certifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Colors.green,
                ),
                SizedBox(height: 16),
                Text(
                  '✅ Nenhuma certificação pendente',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Todas as solicitações foram processadas!',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {}); // Força rebuild
            await Future.delayed(Duration(milliseconds: 500));
          },
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: certifications.length,
            itemBuilder: (context, index) {
              final certification = certifications[index];
              return Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: CertificationRequestCard(
                  certification: certification,
                  onApprove: () => _handleApproval(certification.id),
                  onReject: (reason) => _handleRejection(certification.id, reason),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Aba de histórico de certificações
  Widget _buildHistoryTab() {
    return StreamBuilder<List<CertificationRequestModel>>(
      stream: _service.getCertificationHistoryStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.orange),
                SizedBox(height: 16),
                Text('Carregando histórico...'),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Erro ao carregar histórico',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final certifications = snapshot.data ?? [];

        if (certifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Nenhuma certificação processada',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'O histórico aparecerá aqui após processar certificações',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {}); // Força rebuild
            await Future.delayed(Duration(milliseconds: 500));
          },
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: certifications.length,
            itemBuilder: (context, index) {
              final certification = certifications[index];
              return Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: CertificationHistoryCard(
                  certification: certification,
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Callback quando uma certificação é processada
  void _onCertificationProcessed(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Certificação $action com sucesso!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  /// Handler para aprovação de certificação
  Future<void> _handleApproval(String certificationId) async {
    try {
      // TODO: Obter email do admin atual
      final adminEmail = 'admin@example.com';
      
      final success = await _service.approveCertification(
        certificationId,
        adminEmail,
      );
      
      if (success) {
        _onCertificationProcessed('aprovada');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao aprovar certificação'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// Handler para reprovação de certificação
  Future<void> _handleRejection(String certificationId, String reason) async {
    try {
      // TODO: Obter email do admin atual
      final adminEmail = 'admin@example.com';
      
      final success = await _service.rejectCertification(
        certificationId,
        adminEmail,
        reason,
      );
      
      if (success) {
        _onCertificationProcessed('reprovada');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao reprovar certificação'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
