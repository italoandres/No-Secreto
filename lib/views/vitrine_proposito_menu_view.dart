import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../views/profile_completion_view.dart';
import '../views/search_profile_by_username_view.dart';

/// Página dedicada para Vitrine de Propósito
class VitrinePropositoMenuView extends StatelessWidget {
  const VitrinePropositoMenuView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final FirebaseAuth auth = FirebaseAuth.instance;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Vitrine de Propósito'),
        backgroundColor: const Color(0xFF4169E1),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header da seção com gradiente
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.pink.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_search,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'VITRINE DE PROPÓSITO',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Gerencie seus matches, explore perfis e configure sua vitrine',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Descrição
            Text(
              'O que você pode fazer:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),

            const SizedBox(height: 16),

            // Seus Sinais
            _buildMenuCard(
              icon: Icons.explore,
              title: 'Seus Sinais',
              subtitle: 'Descubra pessoas com propósito',
              color: const Color(0xFF39b9ff),
              onTap: () => Get.toNamed('/explore-profiles'),
              badgeCount: StreamBuilder<QuerySnapshot>(
                stream: firestore
                    .collection('weekly_recommendations')
                    .where('userId', isEqualTo: auth.currentUser?.uid)
                    .where('viewed', isEqualTo: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  return snapshot.data?.docs.length ?? 0;
                },
              ),
            ),

            const SizedBox(height: 12),

            // Notificações de interesse
            _buildMenuCard(
              icon: Icons.notifications_active,
              title: 'Notificações de Interesse',
              subtitle: 'Veja quem demonstrou interesse',
              color: const Color(0xFFfc6aeb),
              onTap: () => Get.toNamed('/interest-dashboard'),
              badgeCount: StreamBuilder<QuerySnapshot>(
                stream: firestore
                    .collection('interest_notifications')
                    .where('toUserId', isEqualTo: auth.currentUser?.uid)
                    .where('status', whereIn: ['pending', 'new'])
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return 0;
                  
                  // Filtrar apenas tipos válidos
                  final validDocs = snapshot.data!.docs.where((doc) {
                    final type = doc.data()['type'] ?? 'interest';
                    return ['interest', 'acceptance', 'mutual_match'].contains(type);
                  }).toList();
                  
                  return validDocs.length;
                },
              ),
            ),

            const SizedBox(height: 12),

            // Matches Aceitos (PRINCIPAL)
            _buildMenuCard(
              icon: Icons.favorite,
              title: 'Matches Aceitos',
              subtitle: 'Converse com seus matches mútuos',
              color: const Color(0xFF4CAF50),
              onTap: () => Get.toNamed('/accepted-matches'),
              badgeCount: StreamBuilder<QuerySnapshot>(
                stream: firestore
                    .collection('match_chats')
                    .where('user1Id', isEqualTo: auth.currentUser?.uid)
                    .snapshots(),
                builder: (context, snapshot1) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: firestore
                        .collection('match_chats')
                        .where('user2Id', isEqualTo: auth.currentUser?.uid)
                        .snapshots(),
                    builder: (context, snapshot2) {
                      if (!snapshot1.hasData && !snapshot2.hasData) return 0;
                      
                      final userId = auth.currentUser?.uid ?? '';
                      int totalUnread = 0;
                      
                      // Contar não lidas do user1
                      if (snapshot1.hasData) {
                        for (var doc in snapshot1.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          final unreadCount = data['unreadCount'] as Map<String, dynamic>?;
                          if (unreadCount != null && unreadCount.containsKey(userId)) {
                            totalUnread += (unreadCount[userId] as int?) ?? 0;
                          }
                        }
                      }
                      
                      // Contar não lidas do user2
                      if (snapshot2.hasData) {
                        for (var doc in snapshot2.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          final unreadCount = data['unreadCount'] as Map<String, dynamic>?;
                          if (unreadCount != null && unreadCount.containsKey(userId)) {
                            totalUnread += (unreadCount[userId] as int?) ?? 0;
                          }
                        }
                      }
                      
                      return totalUnread;
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // NOVO: Encontre Perfil por @
            _buildMenuCard(
              icon: Icons.search,
              title: 'Encontre Perfil por @',
              subtitle: 'Busque perfis pelo username',
              color: const Color(0xFF4169E1),
              onTap: () {
                Get.to(() => const SearchProfileByUsernameView());
              },
            ),

            const SizedBox(height: 16),

            // Configure sua vitrine
            _buildMenuCard(
              icon: Icons.edit,
              title: 'Configure sua vitrine de propósito',
              subtitle: 'Edite seu perfil espiritual',
              color: const Color(0xFFfc6aeb),
              onTap: () {
                Get.to(() => const ProfileCompletionView());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    StreamBuilder<int>? badgeCount,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            if (badgeCount != null)
              Positioned(
                right: -8,
                top: -8,
                child: badgeCount.builder(
                  badgeCount.stream!,
                  (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    if (count == 0) return const SizedBox.shrink();
                    
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
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
                        count > 99 ? '99+' : '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
