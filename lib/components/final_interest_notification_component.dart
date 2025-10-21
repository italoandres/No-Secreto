import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../views/notifications_view.dart';

/// Componente FINAL de notificação de interesse - SOLUÇÃO DEFINITIVA
class FinalInterestNotificationComponent extends StatefulWidget {
  const FinalInterestNotificationComponent({super.key});

  @override
  State<FinalInterestNotificationComponent> createState() => 
      _FinalInterestNotificationComponentState();
}

class _FinalInterestNotificationComponentState 
    extends State<FinalInterestNotificationComponent> {
  
  int _unreadCount = 0;
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

    print('🔄 Configurando listener para notificações de interesse...');

    // Stream DIRETO do Firebase - sem intermediários
    _subscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: currentUser.uid)
        .snapshots()
        .listen(
      (snapshot) {
        // Filtrar manualmente para evitar problemas de índice
        final interestNotifications = snapshot.docs.where((doc) {
          final data = doc.data();
          return data['type'] == 'interest_match' && 
                 data['isRead'] == false;
        }).toList();

        setState(() {
          _unreadCount = interestNotifications.length;
          _isLoading = false;
        });

        print('✅ Notificações atualizadas em tempo real: $_unreadCount');
      },
      onError: (error) {
        print('❌ Erro no listener: $error');
        setState(() {
          _unreadCount = 0;
          _isLoading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50, 
      height: 50,
      margin: const EdgeInsets.only(left: 16),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(0),
          backgroundColor: Colors.white38,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        onPressed: () {
          if (_unreadCount > 0) {
            Get.to(() => const NotificationsView(contexto: 'interest_matches'));
          } else {
            Get.snackbar(
              '💕 Notificações de Interesse',
              'Você não tem notificações de interesse no momento.\nUse o botão TESTE para criar algumas!',
              backgroundColor: Colors.pink.withOpacity(0.8),
              colorText: Colors.white,
              duration: const Duration(seconds: 3),
            );
          }
        },
        child: Stack(
          children: [
            // Ícone de coração sempre visível
            const Center(
              child: Icon(
                Icons.favorite_outline,
                color: Colors.white,
                size: 24,
              ),
            ),
            
            // Badge sempre visível se houver notificações
            if (_unreadCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white,
                      width: 1.5,
                    ),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            
            // Indicador de carregamento
            if (_isLoading)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Versão de EMERGÊNCIA que sempre mostra notificações
class EmergencyInterestNotificationComponent extends StatelessWidget {
  const EmergencyInterestNotificationComponent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50, 
      height: 50,
      margin: const EdgeInsets.only(left: 16),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(0),
          backgroundColor: Colors.white38,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        onPressed: () {
          // Mostrar tela customizada de notificações
          Get.bottomSheet(
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '💕 Notificações de Interesse',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  
                  // Simulação de notificações
                  _buildNotificationItem('Maria Silva', 'há 2 horas'),
                  _buildNotificationItem('Ana Costa', 'há 1 dia'),
                  _buildNotificationItem('Julia Santos', 'há 2 dias'),
                  
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    child: const Text('Fechar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        child: Stack(
          children: [
            // Ícone de coração sempre visível
            const Center(
              child: Icon(
                Icons.favorite,
                color: Colors.white,
                size: 24,
              ),
            ),
            
            // Badge sempre visível
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white,
                    width: 1.5,
                  ),
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: const Text(
                  '3',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(String name, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.pink.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.pink,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'demonstrou interesse no seu perfil',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  time,
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}