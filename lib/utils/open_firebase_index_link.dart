import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FirebaseIndexHelper {
  static const String indexUrl = 
    'https://console.firebase.google.com/v1/r/project/app-no-secreto-com-o-pai/firestore/indexes?create_composite=CmNwcm9qZWN0cy9hcHAtbm8tc2VjcmV0by1jb20tby1wYWkvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL3NwaXJpdHVhbF9wcm9maWxlcy9pbmRleGVzL18QARoSCg5zZWFyY2hLZXl3b3JkcxgBGhwKGGhhc0NvbXBsZXRlZFNpbmFpc0NvdXJzZRABGgwKCGlzQWN0aXZlEAEaDgoKaXNWZXJpZmllZBABGgcKA2FnZRABGgwKCF9fbmFtZV9fEAE';

  static Future<void> openFirebaseIndexCreation() async {
    try {
      final Uri uri = Uri.parse(indexUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('🔥 Link do Firebase aberto com sucesso!');
      } else {
        print('❌ Não foi possível abrir o link');
      }
    } catch (e) {
      print('❌ Erro ao abrir link: $e');
    }
  }

  static Widget buildIndexCreationButton() {
    return Container(
      margin: EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: openFirebaseIndexCreation,
        icon: Icon(Icons.open_in_browser, color: Colors.white),
        label: Text(
          'CRIAR ÍNDICE FIREBASE',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  static Widget buildIndexInstructions() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'ÍNDICE FIREBASE NECESSÁRIO',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '1. Clique no botão laranja abaixo\n'
            '2. No Firebase Console, clique em "Criar"\n'
            '3. Aguarde 2-3 minutos\n'
            '4. Teste a busca novamente',
            style: TextStyle(color: Colors.orange.shade700),
          ),
        ],
      ),
    );
  }
}