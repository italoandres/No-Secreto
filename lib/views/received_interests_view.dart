import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/interest_notification_repository.dart';
import '../models/interest_notification_model.dart';
import '../components/enhanced_interest_notification_card.dart';
import '../utils/debug_received_interests.dart';

/// Tela para mostrar todos os convites de interesse recebidos
class ReceivedInterestsView extends StatefulWidget {
  const ReceivedInterestsView({Key? key}) : super(key: key);

  @override
  State<ReceivedInterestsView> createState() => _ReceivedInterestsViewState();
}

class _ReceivedInterestsViewState extends State<ReceivedInterestsView> {
  List<InterestNotificationModel> _notifications = [];
  bool _isLoading = true;
  String _filter = 'all'; // 'all', 'pending', 'viewed'

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      setState(() {
        _isLoading = true;
      });

      final notifications = await InterestNotificationRepository.getReceivedInterestNotifications(currentUser.uid);

      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Erro ao carregar notificações: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<InterestNotificationModel> get _filteredNotifications {
    switch (_filter) {
      case 'pending':
        return _notifications.where((n) => n.status == 'pending').toList();
      case 'viewed':
        return _notifications.where((n) => n.status == 'viewed').toList();
      default:
        return _notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Convites Recebidos'),
        backgroundColor: Colors.pink.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterChip('Todos', 'all'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFilterChip('Pendentes', 'pending'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFilterChip('Visualizados', 'viewed'),
                ),
              ],
            ),
          ),
          
          // Botão de Debug
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orange.shade50,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _debugNotifications(),
                    icon: const Icon(Icons.bug_report),
                    label: const Text('Debug Notificações'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _createTestNotification(),
                    icon: const Icon(Icons.add_alert),
                    label: const Text('Criar Teste'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de notificações
          Expanded(
            child: _buildNotificationsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _filter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.pink.shade600 : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando convites...'),
          ],
        ),
      );
    }

    final filteredNotifications = _filteredNotifications;

    if (filteredNotifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _getEmptyMessage(),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNotifications,
              child: const Text('Atualizar'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredNotifications.length,
        itemBuilder: (context, index) {
          final notification = filteredNotifications[index];
          return Column(
            children: [
              EnhancedInterestNotificationCard(
                notification: notification,
                onResponse: () {
                  // Recarregar lista após resposta
                  _loadNotifications();
                },
              ),
              if (index < filteredNotifications.length - 1)
                const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }

  String _getEmptyMessage() {
    switch (_filter) {
      case 'pending':
        return 'Nenhum convite pendente.\nTodos os convites foram visualizados ou respondidos.';
      case 'viewed':
        return 'Nenhum convite visualizado.\nConvites aparecem aqui após você ver o perfil.';
      default:
        return 'Nenhum convite recebido ainda.\nQuando alguém demonstrar interesse, aparecerá aqui.';
    }
  }

  /// Debug das notificações
  Future<void> _debugNotifications() async {
    await DebugReceivedInterests.investigateReceivedInterests();
    
    Get.snackbar(
      'Debug Executado',
      'Veja os logs no console para detalhes',
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
  }

  /// Criar notificação de teste
  Future<void> _createTestNotification() async {
    await DebugReceivedInterests.createTestNotification();
    
    Get.snackbar(
      'Teste Criado',
      'Notificação de teste adicionada. Atualize a lista.',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
    
    // Recarregar lista
    _loadNotifications();
  }
}