import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../views/notifications_view.dart';

/// Componente SIMPLES de notificação de interesse que funciona SEM índices do Firebase
class SimpleInterestNotificationComponent extends StatelessWidget {
  const SimpleInterestNotificationComponent({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot>(
      // Query SIMPLES que não precisa de índice
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: currentUser.uid)
          .where('type', isEqualTo: 'interest_match')
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        // Contar notificações não lidas
        final unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
        
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
              Get.to(() => const NotificationsView(contexto: 'interest_matches'));
            },
            child: Stack(
              children: [
                // Ícone de coração centralizado
                const Center(
                  child: Icon(
                    Icons.favorite_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                
                // Badge com contador (só aparece se houver notificações)
                if (unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white,
                          width: 1,
                        ),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
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
      },
    );
  }
}

/// Versão com fallback para dados existentes
class FallbackInterestNotificationComponent extends StatelessWidget {
  const FallbackInterestNotificationComponent({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot>(
      // Tentar primeiro a query simples
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        int unreadCount = 0;
        
        if (snapshot.hasData) {
          // Filtrar manualmente as notificações de interesse não lidas
          unreadCount = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['type'] == 'interest_match' && 
                   data['isRead'] == false;
          }).length;
        }
        
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
              Get.to(() => const NotificationsView(contexto: 'interest_matches'));
            },
            child: Stack(
              children: [
                // Ícone de coração centralizado
                const Center(
                  child: Icon(
                    Icons.favorite_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                
                // Badge com contador (só aparece se houver notificações)
                if (unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white,
                          width: 1,
                        ),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
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
      },
    );
  }
}

/// Versão que usa dados hardcoded para teste
class TestInterestNotificationComponent extends StatelessWidget {
  const TestInterestNotificationComponent({super.key});

  @override
  Widget build(BuildContext context) {
    // Simular 2 notificações para teste
    const unreadCount = 2;
    
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
          Get.snackbar(
            '💕 Notificações de Interesse',
            'Você tem $unreadCount pessoas interessadas!',
            backgroundColor: Colors.pink,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
        },
        child: Stack(
          children: [
            // Ícone de coração centralizado
            const Center(
              child: Icon(
                Icons.favorite,
                color: Colors.white,
                size: 24,
              ),
            ),
            
            // Badge com contador
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white,
                    width: 1,
                  ),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
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
}