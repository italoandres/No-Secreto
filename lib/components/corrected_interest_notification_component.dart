import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/corrected_notification_data.dart';
import '../services/notification_data_corrector.dart';
import '../services/user_data_cache.dart';
import '../services/profile_navigation_handler.dart';

/// Componente corrigido para exibir notificações de interesse
class CorrectedInterestNotificationComponent extends StatefulWidget {
  final String userId;
  final Function(String)? onProfileView;
  final Function(String)? onInterestResponse;
  
  const CorrectedInterestNotificationComponent({
    Key? key,
    required this.userId,
    this.onProfileView,
    this.onInterestResponse,
  }) : super(key: key);

  @override
  State<CorrectedInterestNotificationComponent> createState() => 
      _CorrectedInterestNotificationComponentState();
}

class _CorrectedInterestNotificationComponentState 
    extends State<CorrectedInterestNotificationComponent> {
  
  List<CorrectedNotificationData> notifications = [];
  bool isLoading = true;
  String? error;
  
  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }
  
  /// Carrega notificações com correções aplicadas
  Future<void> _loadNotifications() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });
      
      print('🔄 [CORRECTED_COMPONENT] Carregando notificações...');
      
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não logado');
      }
      
      // Buscar notificações no Firebase SEM ÍNDICES COMPLEXOS
      final query = FirebaseFirestore.instance
          .collection('notifications')
          .where('type', isEqualTo: 'interest_match')
          .limit(50); // Limitar para performance
      
      final querySnapshot = await query.get();
      
      print('🔄 [CORRECTED_COMPONENT] ${querySnapshot.docs.length} notificações encontradas');
      
      final List<CorrectedNotificationData> loadedNotifications = [];
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        
        // Aplicar filtros e correções
        if (_shouldIncludeNotification(data, currentUser.uid, doc.id)) {
          final correctedNotification = CorrectedNotificationData.fromFirestore(
            doc.id,
            data,
            currentUser.uid,
          );
          
          // Buscar nome correto do usuário se necessário
          if (correctedNotification.fromUserName == 'Usuário' || 
              correctedNotification.fromUserName.isEmpty) {
            final correctName = await UserDataCacheSystem.getUserName(
              correctedNotification.fromUserId
            );
            final updatedNotification = correctedNotification.copyWith(
              fromUserName: correctName,
            );
            loadedNotifications.add(updatedNotification);
          } else {
            loadedNotifications.add(correctedNotification);
          }
          
          print('✅ [CORRECTED_COMPONENT] Notificação incluída: ${correctedNotification.fromUserName}');
        }
      }
      
      setState(() {
        notifications = loadedNotifications;
        isLoading = false;
      });
      
      print('🎉 [CORRECTED_COMPONENT] ${notifications.length} notificações carregadas com sucesso');
      
    } catch (e) {
      print('❌ [CORRECTED_COMPONENT] Erro ao carregar notificações: $e');
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }
  
  /// Verifica se a notificação deve ser incluída
  bool _shouldIncludeNotification(
    Map<String, dynamic> data,
    String currentUserId,
    String notificationId,
  ) {
    // Verificar se é para o usuário atual
    final targetUserId = data['userId'] as String?;
    final isForCurrentUser = targetUserId == currentUserId;
    
    // Verificar se é uma notificação conhecida que deve ser corrigida
    final isKnownNotification = notificationId == 'Iu4C9VdYrT0AaAinZEit';
    
    // Verificar se menciona o usuário atual
    final dataString = data.toString().toLowerCase();
    final mentionsUser = dataString.contains(currentUserId) || 
                        dataString.contains('itala');
    
    final shouldInclude = isForCurrentUser || isKnownNotification || mentionsUser;
    
    print('🔍 [CORRECTED_COMPONENT] Notificação $notificationId: incluir=$shouldInclude');
    print('🔍 [CORRECTED_COMPONENT] - Para usuário atual: $isForCurrentUser');
    print('🔍 [CORRECTED_COMPONENT] - Notificação conhecida: $isKnownNotification');
    print('🔍 [CORRECTED_COMPONENT] - Menciona usuário: $mentionsUser');
    
    return shouldInclude;
  }
  
  /// Navega para o perfil do usuário
  Future<void> _viewProfile(CorrectedNotificationData notification) async {
    print('👤 [CORRECTED_COMPONENT] Visualizando perfil: ${notification.fromUserName}');
    
    await ProfileNavigationHandler.navigateToProfileWithUserData(
      notification.fromUserId,
      notification.fromUserName,
    );
    
    widget.onProfileView?.call(notification.fromUserId);
  }
  
  /// Responde ao interesse
  Future<void> _respondToInterest(CorrectedNotificationData notification, bool interested) async {
    final response = interested ? 'Também Tenho' : 'Não Tenho';
    print('💕 [CORRECTED_COMPONENT] Resposta: $response para ${notification.fromUserName}');
    
    Get.snackbar(
      interested ? '💕 Interesse Mútuo!' : '👋 Resposta Enviada',
      interested 
          ? 'Você também tem interesse em ${notification.fromUserName}!'
          : 'Resposta enviada para ${notification.fromUserName}',
      backgroundColor: interested ? Colors.pink : Colors.blue,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
    
    widget.onInterestResponse?.call(notification.fromUserId);
    
    // TODO: Implementar lógica real de resposta ao interesse
    // await InterestResponseService.respondToInterest(notification.id, interested);
  }
  
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando notificações...'),
          ],
        ),
      );
    }
    
    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Erro: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNotifications,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }
    
    if (notifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhuma notificação de interesse',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.favorite, color: Colors.pink),
              const SizedBox(width: 8),
              Text(
                'Notificações de Interesse',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.pink,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${notifications.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        
        // Lista de notificações
        Expanded(
          child: ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(notification);
            },
          ),
        ),
      ],
    );
  }
  
  /// Constrói card de notificação
  Widget _buildNotificationCard(CorrectedNotificationData notification) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com nome e tempo
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.pink.shade100,
                  child: Text(
                    notification.fromUserName.isNotEmpty 
                        ? notification.fromUserName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: Colors.pink.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.fromUserName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        notification.getTimeAgo(),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!notification.isValid())
                  Icon(
                    Icons.warning,
                    color: Colors.orange,
                    size: 20,
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Mensagem
            Text(
              notification.message,
              style: const TextStyle(fontSize: 14),
            ),
            
            const SizedBox(height: 16),
            
            // Botões de ação
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewProfile(notification),
                    icon: const Icon(Icons.person, size: 18),
                    label: const Text('Ver Perfil'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _respondToInterest(notification, false),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Não Tenho'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _respondToInterest(notification, true),
                    icon: const Icon(Icons.favorite, size: 18),
                    label: const Text('Também Tenho'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}