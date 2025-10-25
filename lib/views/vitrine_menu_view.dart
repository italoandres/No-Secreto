import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VitrineMenuView extends StatelessWidget {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Vitrine de Propósito',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Header com informações
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF39b9ff), Color(0xFFfc6aeb)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.storefront,
                  color: Colors.white,
                  size: 48,
                ),
                SizedBox(height: 12),
                Text(
                  'Sua Vitrine de Propósito',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Gerencie seu perfil e conexões',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Matches Aceitos (PRINCIPAL)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.all(16),
              leading: Icon(
                Icons.favorite,
                color: Color(0xFFfc6aeb),
                size: 32,
              ),
              title: Text(
                'Matches Aceitos',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Converse com seus matches mútuos',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Get.toNamed('/accepted-matches'),
            ),
          ),

          SizedBox(height: 12),

          // Gerencie seus matches (Notificações de interesse)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.all(16),
              leading: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('interest_notifications')
                    .where('toUserId', isEqualTo: _auth.currentUser?.uid)
                    .where('type', isEqualTo: 'mutual_match')
                    .where('status', isEqualTo: 'new')
                    .snapshots(),
                builder: (context, snapshot) {
                  final count = snapshot.data?.docs.length ?? 0;
                  return Badge(
                    label: Text('$count'),
                    isLabelVisible: count > 0,
                    child: Icon(
                      Icons.notifications_active,
                      color: Color(0xFF39b9ff),
                      size: 32,
                    ),
                  );
                },
              ),
              title: Text(
                'Notificações de Interesse',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Veja quem demonstrou interesse',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Get.toNamed('/interest-dashboard'),
            ),
          ),

          SizedBox(height: 12),

          // Explorar perfis
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.all(16),
              leading: Icon(
                Icons.explore,
                color: Color(0xFF39b9ff),
                size: 32,
              ),
              title: Text(
                'Explorar perfis',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Descubra pessoas com propósito',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Get.toNamed('/explore-profiles'),
            ),
          ),

          SizedBox(height: 12),

          // Configure sua vitrine
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.all(16),
              leading: Icon(
                Icons.edit,
                color: Color(0xFFfc6aeb),
                size: 32,
              ),
              title: Text(
                'Configure sua vitrine de propósito',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Edite seu perfil espiritual',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Get.toNamed('/vitrine-confirmation'),
            ),
          ),
        ],
      ),
    );
  }
}
