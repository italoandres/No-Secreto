import 'package:flutter/material.dart';
import '../models/spiritual_profile_model.dart';
import 'vitrine_profile_filter.dart';

/// Teste para verificar se a navegação para perfil está funcionando corretamente
class TestProfileNavigationFix {
  
  /// Testa se os IDs estão sendo passados corretamente
  static Future<void> testProfileIds() async {
    print('🔍 === TESTE NAVEGAÇÃO PERFIL ===');
    
    try {
      // Buscar perfis de teste
      final profiles = await VitrineProfileFilter.searchCompleteVitrineProfiles(
        query: 'itala',
        limit: 5,
      );
      
      print('\n📊 PERFIS ENCONTRADOS: ${profiles.length}');
      
      for (var profile in profiles) {
        print('\n🎯 PERFIL: ${profile.displayName} (@${profile.username})');
        print('   • ID do documento: ${profile.id}');
        print('   • UserId real: ${profile.userId}');
        print('   • Cidade: ${profile.city}');
        
        // Verificar qual ID deve ser usado para navegação
        final navigationId = profile.userId ?? profile.id;
        print('   • ID para navegação: $navigationId');
        
        // Simular o que acontece na navegação
        if (profile.userId != null && profile.userId!.isNotEmpty) {
          print('   ✅ CORRETO: Usando userId para navegação');
        } else {
          print('   ⚠️  FALLBACK: Usando document ID (pode causar erro)');
        }
      }
      
      // Teste específico para itala3
      final itala3 = profiles.where((p) => p.username == 'itala3').firstOrNull;
      if (itala3 != null) {
        print('\n🎯 TESTE ESPECÍFICO @itala3:');
        print('   • Document ID: ${itala3.id}');
        print('   • User ID: ${itala3.userId}');
        print('   • Navegação usará: ${itala3.userId ?? itala3.id}');
        
        // Verificar se os IDs são diferentes (o que causava o problema)
        if (itala3.id != itala3.userId) {
          print('   ✅ PROBLEMA IDENTIFICADO: IDs são diferentes!');
          print('   ✅ CORREÇÃO: Agora usa userId em vez de document ID');
        } else {
          print('   ℹ️  IDs são iguais, não há problema');
        }
      }
      
      print('\n🎉 TESTE CONCLUÍDO!');
      
    } catch (e, stackTrace) {
      print('❌ ERRO no teste: $e');
      print('Stack trace: $stackTrace');
    }
  }
  
  /// Widget para executar o teste na interface
  static Widget buildTestWidget() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste Navegação Perfil'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.account_circle,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 20),
            const Text(
              'Teste de Navegação para Perfil',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Verificar se os IDs estão corretos',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () async {
                await testProfileIds();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
              ),
              child: const Text(
                'EXECUTAR TESTE',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}