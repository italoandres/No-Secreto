import 'package:flutter/material.dart';
import '../services/certification_approval_service.dart';
import '../controllers/certification_pagination_controller.dart';
import '../components/paginated_certification_list.dart';
import '../components/certification_filters_component.dart';
import '../utils/debug_utils.dart';

/// Painel administrativo para aprovação de certificações espirituais com paginação
///
/// Esta view permite que administradores:
/// - Visualizem certificações pendentes em tempo real com paginação
/// - Aprovem ou reprovem certificações
/// - Acessem o histórico de certificações processadas com paginação
/// - Filtrem certificações por status, data e admin
class CertificationApprovalPanelPaginatedView extends StatefulWidget {
  @override
  _CertificationApprovalPanelPaginatedViewState createState() =>
      _CertificationApprovalPanelPaginatedViewState();
}

class _CertificationApprovalPanelPaginatedViewState
    extends State<CertificationApprovalPanelPaginatedView>
    with SingleTickerProviderStateMixin {
  final CertificationApprovalService _service = CertificationApprovalService();
  late TabController _tabController;

  // Controllers de paginação
  late CertificationPaginationController _pendingController;
  late CertificationPaginationController _approvedController;
  late CertificationPaginationController _rejectedController;
  late CertificationPaginationController _allHistoryController;

  // Estado
  bool _isAdmin = false;
  bool _isLoadingPermissions = true;
  CertificationFilters _currentFilters = const CertificationFilters();
  List<String> _availableAdmins = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Inicializar controllers de paginação
    _pendingController = CertificationPaginationController();
    _approvedController = CertificationPaginationController();
    _rejectedController = CertificationPaginationController();
    _allHistoryController = CertificationPaginationController();

    _checkAdminPermissions();
    _loadAvailableAdmins();
    _initializeControllers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pendingController.dispose();
    _approvedController.dispose();
    _rejectedController.dispose();
    _allHistoryController.dispose();
    super.dispose();
  }

  /// Inicializa os controllers com os filtros apropriados
  void _initializeControllers() {
    _pendingController.initialize(status: 'pending');
    _approvedController.initialize(status: 'approved');
    _rejectedController.initialize(status: 'rejected');
    _allHistoryController.initialize(); // Sem filtro de status = todas
  }

  /// Verifica se o usuário atual é administrador
  Future<void> _checkAdminPermissions() async {
    final isAdmin = await _service.isCurrentUserAdmin();

    if (mounted) {
      setState(() {
        _isAdmin = isAdmin;
        _isLoadingPermissions = false;
      });

      if (!isAdmin) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Você não tem permissão para acessar este painel'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );

        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    }
  }

  /// Carrega a lista de administradores disponíveis para filtro
  Future<void> _loadAvailableAdmins() async {
    try {
      final admins = await _service.getAvailableAdmins();
      if (mounted) {
        setState(() {
          _availableAdmins = admins;
        });
      }
    } catch (e) {
      safePrint('Erro ao carregar admins: $e');
    }
  }

  /// Atualiza os filtros aplicados
  void _onFiltersChanged(CertificationFilters filters) {
    setState(() {
      _currentFilters = filters;
    });

    // Atualizar controllers com novos filtros
    final filtersMap = _buildFiltersMap(filters);

    _pendingController.updateFilters(
      status: 'pending',
      filters: filtersMap,
    );

    _approvedController.updateFilters(
      status: 'approved',
      filters: filtersMap,
    );

    _rejectedController.updateFilters(
      status: 'rejected',
      filters: filtersMap,
    );

    _allHistoryController.updateFilters(
      filters: filtersMap,
    );
  }

  /// Converte CertificationFilters para Map
  Map<String, dynamic> _buildFiltersMap(CertificationFilters filters) {
    return {
      if (filters.startDate != null) 'startDate': filters.startDate,
      if (filters.endDate != null) 'endDate': filters.endDate,
      if (filters.adminEmail != null) 'adminEmail': filters.adminEmail,
      if (filters.searchText != null && filters.searchText!.isNotEmpty)
        'searchText': filters.searchText,
    };
  }

  /// Callback quando uma certificação é processada
  void _onCertificationProcessed() {
    // Recarregar as listas
    _pendingController.refresh();
    _approvedController.refresh();
    _rejectedController.refresh();
    _allHistoryController.refresh();
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
          isScrollable: true,
          tabs: [
            Tab(
              icon: Icon(Icons.pending_actions),
              text: 'Pendentes',
            ),
            Tab(
              icon: Icon(Icons.check_circle),
              text: 'Aprovadas',
            ),
            Tab(
              icon: Icon(Icons.cancel),
              text: 'Reprovadas',
            ),
            Tab(
              icon: Icon(Icons.history),
              text: 'Todas',
            ),
          ],
        ),
        actions: [
          // Contador de pendentes
          StreamBuilder<int>(
            stream: _service.getPendingCertificationsCountStream(),
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
      body: Column(
        children: [
          // Componente de Filtros
          CertificationFiltersComponent(
            initialFilters: _currentFilters,
            onFiltersChanged: _onFiltersChanged,
            availableAdmins: _availableAdmins,
          ),

          // Conteúdo das abas
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Aba Pendentes
                PaginatedCertificationList(
                  controller: _pendingController,
                  isPendingList: true,
                  onCertificationProcessed: _onCertificationProcessed,
                ),

                // Aba Aprovadas
                PaginatedCertificationList(
                  controller: _approvedController,
                  isPendingList: false,
                ),

                // Aba Reprovadas
                PaginatedCertificationList(
                  controller: _rejectedController,
                  isPendingList: false,
                ),

                // Aba Todas (Histórico Completo)
                PaginatedCertificationList(
                  controller: _allHistoryController,
                  isPendingList: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
