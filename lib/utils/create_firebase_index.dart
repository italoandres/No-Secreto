import 'package:url_launcher/url_launcher.dart';

/// Cria índice do Firebase automaticamente
class CreateFirebaseIndex {
  
  /// URL para criar o índice necessário
  static const String indexUrl = 'https://console.firebase.google.com/v1/r/project/app-no-secreto-com-o-pai/firestore/indexes?create_composite=CmNwcm9qZWN0cy9hcHAtbm8tc2VjcmV0by1jb20tby1wYWkvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL3NwaXJpdHVhbF9wcm9maWxlcy9pbmRleGVzL18QARoSCg5zZWFyY2hLZXl3b3JkcxgBGhwKGGhhc0NvbXBsZXRlZFNpbmFpc0NvdXJzZRABGgwKCGlzQWN0aXZlEAEaDgoKaXNWZXJpZmllZRABGgcKA2FnZRABGgwKCF9fbmFtZV9fEAE';
  
  /// Abre o Firebase Console para criar o índice
  static Future<void> openFirebaseConsole() async {
    try {
      print('🔥 Abrindo Firebase Console para criar índice...');
      
      final uri = Uri.parse(indexUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('✅ Firebase Console aberto! Clique em "Criar Índice"');
      } else {
        print('❌ Não foi possível abrir o Firebase Console');
        print('🔗 Copie este link e abra no navegador:');
        print(indexUrl);
      }
    } catch (e) {
      print('❌ Erro ao abrir Firebase Console: $e');
      print('🔗 Copie este link e abra no navegador:');
      print(indexUrl);
    }
  }
  
  /// Instruções para criar o índice manualmente
  static void printInstructions() {
    print('');
    print('🔥 INSTRUÇÕES PARA CRIAR ÍNDICE:');
    print('=' * 50);
    print('1. Acesse: https://console.firebase.google.com');
    print('2. Selecione o projeto: app-no-secreto-com-o-pai');
    print('3. Vá em: Firestore Database > Índices');
    print('4. Clique em: Criar Índice');
    print('5. Configure:');
    print('   - Coleção: spiritual_profiles');
    print('   - Campos:');
    print('     * searchKeywords (Array-contains)');
    print('     * hasCompletedSinaisCourse (Ascending)');
    print('     * isActive (Ascending)');
    print('     * isVerified (Ascending)');
    print('     * age (Ascending)');
    print('     * __name__ (Ascending)');
    print('6. Clique em: Criar');
    print('7. Aguarde 2-3 minutos');
    print('8. Teste novamente o Explorar Perfis');
    print('=' * 50);
    print('');
  }
}