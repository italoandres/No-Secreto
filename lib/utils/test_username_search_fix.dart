import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/spiritual_profile_model.dart';
import 'vitrine_profile_filter.dart';

/// Teste específico para verificar se a busca por username está funcionando
class TestUsernameSearchFix {
  static Future<void> testUsernameSearch() async {
    print('🔍 === TESTE BUSCA POR USERNAME ===');
    
    try {
      // Teste 1: Busca por "itala3" (username específico)
      print('\n📊 TESTE 1: Busca por "itala3"');
      final results1 = await VitrineProfileFilter.searchCompleteVitrineProfiles(
        query: 'itala3',
        limit: 10,
      );
      
      print('✅ Resultados para "itala3": ${results1.length}');
      for (var profile in results1) {
        print('   • ${profile.displayName} (@${profile.username}) - ${profile.city}');
      }
      
      // Teste 2: Busca por "itala" (parcial)
      print('\n📊 TESTE 2: Busca por "itala"');
      final results2 = await VitrineProfileFilter.searchCompleteVitrineProfiles(
        query: 'itala',
        limit: 10,
      );
      
      print('✅ Resultados para "itala": ${results2.length}');
      for (var profile in results2) {
        print('   • ${profile.displayName} (@${profile.username}) - ${profile.city}');
      }
      
      // Teste 3: Verificar se itala3 está nos resultados
      print('\n🎯 VERIFICAÇÃO ESPECÍFICA:');
      final hasItala3 = results1.any((p) => p.username == 'itala3');
      print('   • Perfil @itala3 encontrado: ${hasItala3 ? "✅ SIM" : "❌ NÃO"}');
      
      if (hasItala3) {
        final itala3Profile = results1.firstWhere((p) => p.username == 'itala3');
        print('   • Dados do @itala3:');
        print('     - Nome: ${itala3Profile.displayName}');
        print('     - Username: ${itala3Profile.username}');
        print('     - Cidade: ${itala3Profile.city}');
        print('     - Bio: ${itala3Profile.bio?.substring(0, 50) ?? "Vazia"}...');
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
        title: const Text('Teste Busca Username'),
        backgroundColor: Colors.purple,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search,
              size: 80,
              color: Colors.purple,
            ),
            const SizedBox(height: 20),
            const Text(
              'Teste de Busca por Username',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Verificar se @itala3 é encontrado',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () async {
                await testUsernameSearch();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
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