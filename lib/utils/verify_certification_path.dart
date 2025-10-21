import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// 🔍 Utilitário para verificar o caminho correto dos documentos de certificação
class VerifyCertificationPath {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Verifica onde o documento foi salvo
  static Future<void> checkDocumentPath(String requestId) async {
    debugPrint('🔍 ========================================');
    debugPrint('🔍 VERIFICANDO CAMINHO DO DOCUMENTO');
    debugPrint('🔍 ========================================');
    debugPrint('🔍 Request ID: $requestId');
    debugPrint('');

    // Tenta encontrar em diferentes caminhos possíveis
    final possiblePaths = [
      'certification_requests',
      'certificationRequests',
      'spiritual_certifications',
      'certifications',
    ];

    for (final path in possiblePaths) {
      try {
        debugPrint('🔍 Verificando: $path/$requestId');
        
        final doc = await _firestore
            .collection(path)
            .doc(requestId)
            .get();

        if (doc.exists) {
          debugPrint('✅ ENCONTRADO!');
          debugPrint('📍 Caminho completo: $path/$requestId');
          debugPrint('📄 Dados: ${doc.data()}');
          debugPrint('');
          debugPrint('🎯 TRIGGER DA CLOUD FUNCTION DEVE SER:');
          debugPrint('   $path/{requestId}');
          debugPrint('');
          return;
        } else {
          debugPrint('❌ Não encontrado em: $path');
        }
      } catch (e) {
        debugPrint('❌ Erro ao verificar $path: $e');
      }
    }

    debugPrint('');
    debugPrint('⚠️  DOCUMENTO NÃO ENCONTRADO EM NENHUM CAMINHO!');
    debugPrint('');
  }

  /// Lista todos os documentos de certificação
  static Future<void> listAllCertifications() async {
    debugPrint('🔍 ========================================');
    debugPrint('🔍 LISTANDO TODAS AS CERTIFICAÇÕES');
    debugPrint('🔍 ========================================');
    debugPrint('');

    final possiblePaths = [
      'certification_requests',
      'certificationRequests',
      'spiritual_certifications',
      'certifications',
    ];

    for (final path in possiblePaths) {
      try {
        debugPrint('📂 Collection: $path');
        
        final snapshot = await _firestore
            .collection(path)
            .limit(5)
            .get();

        if (snapshot.docs.isEmpty) {
          debugPrint('   ❌ Vazia');
        } else {
          debugPrint('   ✅ ${snapshot.docs.length} documentos encontrados:');
          for (final doc in snapshot.docs) {
            debugPrint('      - ID: ${doc.id}');
            debugPrint('        Email: ${doc.data()['userEmail'] ?? 'N/A'}');
            debugPrint('        Status: ${doc.data()['status'] ?? 'N/A'}');
          }
        }
        debugPrint('');
      } catch (e) {
        debugPrint('   ❌ Erro: $e');
        debugPrint('');
      }
    }
  }

  /// Verifica a configuração da Cloud Function
  static void printExpectedTrigger() {
    debugPrint('🔍 ========================================');
    debugPrint('🔍 CONFIGURAÇÃO ESPERADA DA CLOUD FUNCTION');
    debugPrint('🔍 ========================================');
    debugPrint('');
    debugPrint('📝 No arquivo functions/index.js deve ter:');
    debugPrint('');
    debugPrint('exports.sendCertificationRequestEmail = functions.firestore');
    debugPrint('  .document(\'certification_requests/{requestId}\')');
    debugPrint('  .onCreate(async (snap, context) => {');
    debugPrint('    // Código aqui');
    debugPrint('  });');
    debugPrint('');
    debugPrint('⚠️  IMPORTANTE: O caminho deve ser EXATAMENTE igual!');
    debugPrint('');
  }

  /// Executa todas as verificações
  static Future<void> runFullDiagnostic(String requestId) async {
    debugPrint('');
    debugPrint('🚀 ========================================');
    debugPrint('🚀 DIAGNÓSTICO COMPLETO - CERTIFICAÇÃO');
    debugPrint('🚀 ========================================');
    debugPrint('');

    // 1. Verifica o documento específico
    await checkDocumentPath(requestId);

    debugPrint('');
    debugPrint('─────────────────────────────────────────');
    debugPrint('');

    // 2. Lista todos os documentos
    await listAllCertifications();

    debugPrint('');
    debugPrint('─────────────────────────────────────────');
    debugPrint('');

    // 3. Mostra configuração esperada
    printExpectedTrigger();

    debugPrint('');
    debugPrint('🎯 ========================================');
    debugPrint('🎯 PRÓXIMOS PASSOS');
    debugPrint('🎯 ========================================');
    debugPrint('');
    debugPrint('1. Copie o "Caminho completo" encontrado acima');
    debugPrint('2. Verifique se o trigger da Cloud Function usa o mesmo caminho');
    debugPrint('3. Se forem diferentes, corrija o trigger e faça deploy:');
    debugPrint('   cd functions');
    debugPrint('   firebase deploy --only functions');
    debugPrint('');
    debugPrint('4. Teste novamente criando uma nova solicitação');
    debugPrint('');
  }
}

/// 🧪 Função de teste rápido
Future<void> testCertificationPath() async {
  // Use o ID da última solicitação criada
  const lastRequestId = 'ngpdnlaDkDopAFQ7wiib';
  
  await VerifyCertificationPath.runFullDiagnostic(lastRequestId);
}
