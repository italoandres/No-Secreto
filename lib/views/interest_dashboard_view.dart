import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/interest_notification_repository.dart';
import '../models/interest_notification_model.dart';
import '../services/interest_system_integrator.dart';
import '../utils/enhanced_logger.dart';
import '../utils/debug_utils.dart';
import '../components/enhanced_interest_notification_card.dart';
import '../views/received_interests_view.dart';

/// Dashboard completo do sistema de interesse
class InterestDashboardView extends StatefulWidget {
  const InterestDashboardView({Key? key}) : super(key: key);

  @override
  State<InterestDashboardView> createState() => _InterestDashboardViewState();
}

class _InterestDashboardViewState extends State<InterestDashboardView>
    with SingleTickerProviderStateMixin {
  final InterestSystemIntegrator _integrator = InterestSystemIntegrator();

  late TabController _tabController;
  Map<String, int> _stats = {};
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Carregar estatísticas
      final stats = await _integrator.getInterestStats(currentUser.uid);

      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoadingStats = false;
        });
      }

      EnhancedLogger.info('Dashboard data loaded',
          tag: 'INTEREST_DASHBOARD', data: {'stats': stats});
    } catch (e) {
      EnhancedLogger.error('Erro ao carregar dados do dashboard: $e',
          tag: 'INTEREST_DASHBOARD');

      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Gerencie seus Matches'),
        backgroundColor: Colors.pink.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.notifications), text: 'Notificações'),
            Tab(icon: Icon(Icons.analytics), text: 'Estatísticas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationsTab(),
          _buildStatsTab(),
        ],
      ),
    );
  }

  Widget _buildNotificationsTab() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(
        child: Text('Você precisa estar logado para ver as notificações'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.pink.withOpacity(0.1),
                  Colors.purple.withOpacity(0.1)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.favorite, color: Colors.pink, size: 32),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notificações de Interesse',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Veja quem demonstrou interesse no seu perfil',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Lista de notificações
          StreamBuilder<List<InterestNotificationModel>>(
            stream: InterestNotificationRepository.getUserInterestNotifications(
                currentUser.uid),
            builder: (context, snapshot) {
              // ✅ TRATAMENTO DE ERRO OBRIGATÓRIO
              if (snapshot.hasError) {
                safePrint('InterestDashboard: Erro no stream de notificações: ${snapshot.error}');
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text(
                        'Erro ao carregar notificações',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                );
              }
              
              // DEBUG: Log do estado do stream
              safePrint('🔍 [INTEREST_DASHBOARD] Stream state: ${snapshot.connectionState}');
              safePrint('🔍 [INTEREST_DASHBOARD] Has data: ${snapshot.hasData}');
              safePrint('🔍 [INTEREST_DASHBOARD] Data length: ${snapshot.data?.length ?? 0}');

              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                safePrint('📋 [INTEREST_DASHBOARD] Notificações recebidas:');
                for (var notif in snapshot.data!) {
                  safePrint('   - ID: ${notif.id}, Type: ${notif.type}, Status: ${notif.status}, From: ${notif.fromUserName}');
                }
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                print('❌ [INTEREST_DASHBOARD] Erro: ${snapshot.error}');
                return Center(
                  child:
                      Text('Erro ao carregar notificações: ${snapshot.error}'),
                );
              }

              final notifications = snapshot.data ?? [];

              if (notifications.isEmpty) {
                print('⚠️ [INTEREST_DASHBOARD] Nenhuma notificação encontrada');
                return const Center(
                  child: Column(
                    children: [
                      SizedBox(height: 50),
                      Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Nenhuma notificação de interesse ainda',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              print(
                  '✅ [INTEREST_DASHBOARD] Exibindo ${notifications.length} notificações');
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return EnhancedInterestNotificationCard(
                    notification: notification,
                    onResponse: () {
                      // Recarregar dados após resposta
                      _loadDashboardData();
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Estatísticas principais
          _buildStatsCards(),

          const SizedBox(height: 24),

          // Informações adicionais
          _buildInfoCard(),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    if (_isLoadingStats) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Suas Estatísticas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Enviados',
                _stats['sent'] ?? 0,
                Icons.send,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildClickableStatCard(
                'Recebidos',
                _stats['received'] ?? 0,
                Icons.inbox,
                Colors.green,
                () => _navigateToReceivedInterests(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Aceitos',
                _stats['accepted'] ?? 0,
                Icons.favorite,
                Colors.pink,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClickableStatCard(
      String label, int value, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Stack(
              children: [
                Icon(icon, color: color, size: 32),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.touch_app,
                      color: Colors.white,
                      size: 8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Toque para ver',
              style: TextStyle(
                fontSize: 10,
                color: Colors.blue[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToReceivedInterests() {
    Get.to(() => const ReceivedInterestsView());
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Como Funciona',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            '• Quando alguém demonstra interesse no seu perfil, você recebe uma notificação\n'
            '• Você pode responder "Também Tenho" ou "Não Tenho"\n'
            '• Se ambos demonstrarem interesse, vocês podem se conectar\n'
            '• Use a aba "Explorar Perfis" para encontrar pessoas interessantes',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
