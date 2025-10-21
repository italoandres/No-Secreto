import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Componente para NOTIFICAÇÕES REAIS de interesse (não de teste)
class RealInterestNotificationComponent extends StatefulWidget {
  final String userId;
  final Function(String)? onProfileView;
  final Function(String)? onInterestResponse;
  
  const RealInterestNotificationComponent({
    Key? key,
    required this.userId,
    this.onProfileView,
    this.onInterestResponse,
  }) : super(key: key);

  @override
  State<RealInterestNotificationComponent> createState() => 
      _RealInterestNotificationComponentState();
}

class _RealInterestNotificationComponentState 
    extends State<RealInterestNotificationComponent> {
  
  List<Map<String, dynamic>> realNotifications = [];
  bool isLoading = true;
  String? error;
  
  @override
  void initState() {
    super.initState();
    _loadRealNotifications();
  }
  
  /// Carrega APENAS notificações REAIS (não de teste)
  Future<void> _loadRealNotifications() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });
      
      print('🔍 [REAL_NOTIFICATIONS] Buscando APENAS notificações REAIS...');
      
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não logado');
      }
      
      // 1. BUSCAR INTERAÇÕES REAIS (likes, matches, etc.)
      final realInteractions = await _findRealInteractions(currentUser.uid);
      
      // 2. BUSCAR NOTIFICAÇÕES BASEADAS NAS INTERAÇÕES REAIS
      final realNotificationsList = await _findNotificationsFromInteractions(
        realInteractions, 
        currentUser.uid
      );
      
      setState(() {
        realNotifications = realNotificationsList;
        isLoading = false;
      });
      
      print('🎉 [REAL_NOTIFICATIONS] ${realNotifications.length} notificações REAIS encontradas');
      
    } catch (e) {
      print('❌ [REAL_NOTIFICATIONS] Erro: $e');
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }
  
  /// Busca interações reais (likes, matches, interests)
  Future<List<Map<String, dynamic>>> _findRealInteractions(String currentUserId) async {
    print('🔍 [REAL_NOTIFICATIONS] Buscando interações reais...');
    
    final List<Map<String, dynamic>> interactions = [];
    
    try {
      // Buscar em diferentes coleções de interações
      final collections = ['likes', 'interests', 'matches', 'user_interactions'];
      
      for (final collectionName in collections) {
        try {
          final querySnapshot = await FirebaseFirestore.instance
              .collection(collectionName)
              .where('targetUserId', isEqualTo: currentUserId)
              .limit(50)
              .get();
          
          print('📊 [REAL_NOTIFICATIONS] $collectionName: ${querySnapshot.docs.length} interações');
          
          for (final doc in querySnapshot.docs) {
            final data = doc.data();
            data['id'] = doc.id;
            data['collection'] = collectionName;
            interactions.add(data);
          }
        } catch (e) {
          print('⚠️ [REAL_NOTIFICATIONS] Erro em $collectionName: $e');
        }
      }
      
      print('📊 [REAL_NOTIFICATIONS] Total de interações reais: ${interactions.length}');
      return interactions;
      
    } catch (e) {
      print('❌ [REAL_NOTIFICATIONS] Erro ao buscar interações: $e');
      return [];
    }
  }
  
  /// Busca notificações baseadas nas interações reais
  Future<List<Map<String, dynamic>>> _findNotificationsFromInteractions(
    List<Map<String, dynamic>> interactions,
    String currentUserId,
  ) async {
    print('🔍 [REAL_NOTIFICATIONS] Convertendo interações em notificações...');
    
    final List<Map<String, dynamic>> notifications = [];
    
    for (final interaction in interactions) {
      try {
        final fromUserId = interaction['fromUserId'] as String? ?? 
                          interaction['userId'] as String? ?? 
                          interaction['sourceUserId'] as String?;
        
        if (fromUserId == null || fromUserId == currentUserId) continue;
        
        // Buscar dados do usuário que fez a interação
        final userData = await _getUserData(fromUserId);
        if (userData == null) continue;
        
        // Criar notificação baseada na interação real
        final notification = {
          'id': interaction['id'],
          'fromUserId': fromUserId,
          'fromUserName': userData['nome'] ?? userData['name'] ?? 'Usuário',
          'fromUserUsername': userData['username'] ?? '',
          'fromUserEmail': userData['email'] ?? '',
          'message': _getMessageFromInteraction(interaction),
          'timestamp': interaction['createdAt'] ?? interaction['timestamp'] ?? Timestamp.now(),
          'isRead': false,
          'type': 'real_interest',
          'interactionType': interaction['collection'],
          'originalInteraction': interaction,
          'isReal': true, // Marcador de notificação real
        };
        
        notifications.add(notification);
        
        print('✅ [REAL_NOTIFICATIONS] Notificação real criada: ${notification['fromUserName']}');
        
      } catch (e) {
        print('⚠️ [REAL_NOTIFICATIONS] Erro ao processar interação: $e');
      }
    }
    
    // Ordenar por data (mais recentes primeiro)
    notifications.sort((a, b) {
      final aTime = a['timestamp'] as Timestamp?;
      final bTime = b['timestamp'] as Timestamp?;
      if (aTime == null || bTime == null) return 0;
      return bTime.compareTo(aTime);
    });
    
    return notifications;
  }
  
  /// Busca dados do usuário
  Future<Map<String, dynamic>?> _getUserData(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        return userDoc.data();
      }
    } catch (e) {
      print('⚠️ [REAL_NOTIFICATIONS] Erro ao buscar usuário $userId: $e');
    }
    return null;
  }
  
  /// Gera mensagem baseada no tipo de interação
  String _getMessageFromInteraction(Map<String, dynamic> interaction) {
    final collection = interaction['collection'] as String?;
    
    switch (collection) {
      case 'likes':
        return 'curtiu seu perfil';
      case 'interests':
        return 'demonstrou interesse em você';
      case 'matches':
        return 'deu match com você';
      case 'user_interactions':
        return 'interagiu com seu perfil';
      default:
        return 'tem interesse em conhecer você melhor';
    }
  }
  
  /// Navega para o perfil do usuário
  Future<void> _viewProfile(Map<String, dynamic> notification) async {
    final userName = notification['fromUserName'] as String;
    final userId = notification['fromUserId'] as String;
    
    print('👤 [REAL_NOTIFICATIONS] Visualizando perfil REAL: $userName ($userId)');
    
    Get.snackbar(
      '👤 Abrindo Perfil Real',
      'Carregando perfil de $userName...',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
    
    widget.onProfileView?.call(userId);
  }
  
  /// Responde ao interesse
  Future<void> _respondToInterest(Map<String, dynamic> notification, bool interested) async {
    final userName = notification['fromUserName'] as String;
    final userId = notification['fromUserId'] as String;
    final response = interested ? 'Também Tenho' : 'Não Tenho';
    
    print('💕 [REAL_NOTIFICATIONS] Resposta REAL: $response para $userName');
    
    Get.snackbar(
      interested ? '💕 Interesse Mútuo Real!' : '👋 Resposta Enviada',
      interested 
          ? 'Você também tem interesse em $userName!'
          : 'Resposta enviada para $userName',
      backgroundColor: interested ? Colors.pink : Colors.blue,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
    
    widget.onInterestResponse?.call(userId);
  }
  
  /// Retorna tempo relativo
  String _getTimeAgo(dynamic timestamp) {
    if (timestamp is! Timestamp) return 'agora';
    
    final now = DateTime.now();
    final time = timestamp.toDate();
    final difference = now.difference(time);
    
    if (difference.inDays > 0) {
      return 'há ${difference.inDays} dia${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'há ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'há ${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'agora';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.green),
            SizedBox(height: 16),
            Text('Buscando notificações reais...'),
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
              onPressed: _loadRealNotifications,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }
    
    if (realNotifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhuma notificação real encontrada',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Quando alguém realmente curtir você, aparecerá aqui',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
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
              const Icon(Icons.verified, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                'Notificações Reais',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${realNotifications.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        
        // Lista de notificações reais
        Expanded(
          child: ListView.builder(
            itemCount: realNotifications.length,
            itemBuilder: (context, index) {
              final notification = realNotifications[index];
              return _buildRealNotificationCard(notification);
            },
          ),
        ),
      ],
    );
  }
  
  /// Constrói card de notificação real
  Widget _buildRealNotificationCard(Map<String, dynamic> notification) {
    final userName = notification['fromUserName'] as String? ?? 'Usuário';
    final message = notification['message'] as String? ?? 'tem interesse em você';
    final timeAgo = _getTimeAgo(notification['timestamp']);
    final interactionType = notification['interactionType'] as String? ?? 'interest';
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com nome e tempo
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green.shade100,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: Colors.green.shade700,
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
                        userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Indicadores
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'REAL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        interactionType.toUpperCase(),
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Mensagem
            Text(
              message,
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
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green),
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
                      backgroundColor: Colors.green,
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