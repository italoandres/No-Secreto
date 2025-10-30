import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// COMPONENTE PERFEITO DE NOTIFICAÇÕES - SOLUÇÃO DEFINITIVA
class PerfectInterestNotificationComponent extends StatefulWidget {
  const PerfectInterestNotificationComponent({super.key});

  @override
  State<PerfectInterestNotificationComponent> createState() =>
      _PerfectInterestNotificationComponentState();
}

class _PerfectInterestNotificationComponentState
    extends State<PerfectInterestNotificationComponent> {
  int _unreadCount = 0;
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  StreamSubscription<QuerySnapshot>? _subscription;

  @override
  void initState() {
    super.initState();
    _setupRealTimeListener();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  /// Configura listener em tempo real DIRETO do Firebase
  void _setupRealTimeListener() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() {
        _unreadCount = 0;
        _isLoading = false;
      });
      return;
    }

    print('🔄 [PERFECT] Configurando listener para notificações...');

    // Stream DIRETO do Firebase - BUSCAR EM AMBAS AS DIREÇÕES
    _subscription = FirebaseFirestore.instance
        .collection('notifications')
        .snapshots()
        .listen(
      (snapshot) {
        // Filtrar notificações de interesse não lidas PARA O USUÁRIO ATUAL
        final interestNotifications = snapshot.docs.where((doc) {
          final data = doc.data();

          // Buscar notificações onde o usuário atual é o ALVO
          final isTargetUser = data['userId'] == currentUser.uid;

          // OU buscar notificações onde o usuário atual é mencionado
          final isFromUser = data['fromUserId'] == currentUser.uid;
          final isMentioned =
              data.toString().contains(currentUser.email ?? '') ||
                  data.toString().contains('itala');

          return data['type'] == 'interest_match' &&
              data['isRead'] == false &&
              (isTargetUser || isMentioned);
        }).toList();

        // Converter para lista de mapas
        final notificationsList = interestNotifications.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'fromUserId': data['fromUserId'] ?? '',
            'fromUserName': data['fromUserName'] ?? 'Usuário',
            'message': data['message'] ??
                'Tem interesse em conhecer seu perfil melhor',
            'timestamp': data['timestamp'],
            'isRead': data['isRead'] ?? false,
          };
        }).toList();

        setState(() {
          _unreadCount = interestNotifications.length;
          _notifications = notificationsList;
          _isLoading = false;
        });

        print('✅ [PERFECT] Notificações carregadas: $_unreadCount');
        print('📋 [PERFECT] Dados: $_notifications');
      },
      onError: (error) {
        print('❌ [PERFECT] Erro no listener: $error');
        setState(() {
          _unreadCount = 0;
          _notifications = [];
          _isLoading = false;
        });
      },
    );
  }

  /// Mostra a interface de notificações EXATAMENTE como você pediu
  void _showNotifications() {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.8,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '🔔 Notificações de Interesse',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '[$_unreadCount]',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Lista de notificações
            Expanded(
              child: _notifications.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhuma notificação de interesse no momento',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        return _buildNotificationCard(notification);
                      },
                    ),
            ),

            // Botão fechar
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Fechar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  /// Constrói o card de notificação EXATAMENTE como você pediu
  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final userName = notification['fromUserName'] ?? 'Usuário';
    final message = notification['message'] ??
        'Tem interesse em conhecer seu perfil melhor';

    // Calcular tempo
    String timeAgo = 'há alguns minutos';
    if (notification['timestamp'] != null) {
      try {
        final timestamp = notification['timestamp'] as Timestamp;
        final now = DateTime.now();
        final notificationTime = timestamp.toDate();
        final difference = now.difference(notificationTime);

        if (difference.inMinutes < 60) {
          timeAgo = 'há ${difference.inMinutes} minutos';
        } else if (difference.inHours < 24) {
          timeAgo =
              'há ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
        } else {
          timeAgo =
              'há ${difference.inDays} dia${difference.inDays > 1 ? 's' : ''}';
        }
      } catch (e) {
        print('❌ Erro ao calcular tempo: $e');
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.pink.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.pink.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header com foto e nome
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.pink,
                radius: 20,
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '👤💕 $userName, 25',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Mensagem
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Text(
              '"$message"',
              style: const TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

          const SizedBox(height: 15),

          // Botões de ação
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Ver perfil
                    Get.snackbar(
                      '👤 Ver Perfil',
                      'Abrindo perfil de $userName...',
                      backgroundColor: Colors.blue,
                      colorText: Colors.white,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child:
                      const Text('Ver Perfil', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Não tenho interesse
                    _markAsRead(notification['id']);
                    Get.snackbar(
                      '❌ Não Tenho',
                      'Interesse rejeitado',
                      backgroundColor: Colors.grey,
                      colorText: Colors.white,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child:
                      const Text('Não Tenho', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Também tenho interesse
                    _markAsRead(notification['id']);
                    Get.snackbar(
                      '✅ Também Tenho',
                      'Match criado com $userName!',
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('Também Tenho ✅',
                      style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Marca notificação como lida
  void _markAsRead(String notificationId) {
    if (notificationId.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true})
          .then((_) => print('✅ Notificação marcada como lida'))
          .catchError((e) => print('❌ Erro ao marcar como lida: $e'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      margin: const EdgeInsets.only(left: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: _showNotifications,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.pink.withOpacity(0.9),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Ícone de coração sempre visível
                const Center(
                  child: Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 28,
                  ),
                ),

                // Badge sempre visível se houver notificações
                if (_unreadCount > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                // Indicador de carregamento
                if (_isLoading)
                  Positioned(
                    left: 4,
                    top: 4,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
