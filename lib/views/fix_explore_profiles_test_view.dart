import 'package:flutter/material.dart';
import '../utils/execute_complete_fix_now.dart';
import '../components/profile_visibility_banner.dart';
import '../components/quick_fix_profile_button.dart';

/// Tela de teste para corrigir Explorar Perfis
class FixExploreProfilesTestView extends StatelessWidget {
  const FixExploreProfilesTestView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔧 Corrigir Explorar Perfis'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner de aviso
            ProfileVisibilityBanner(),
            
            const SizedBox(height: 20),
            
            // Título principal
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                border: Border.all(color: Colors.red[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Icon(Icons.warning, color: Colors.red[600], size: 32),
                  const SizedBox(height: 8),
                  Text(
                    '⚠️ PROBLEMA DETECTADO',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Seu perfil não está aparecendo no "Explorar Perfis" e não há dados de teste.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red[700],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Problemas identificados
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                border: Border.all(color: Colors.orange[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🔍 PROBLEMAS IDENTIFICADOS:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildProblemItem('❌ Perfis encontrados: 0'),
                  _buildProblemItem('❌ Seu perfil não está visível'),
                  _buildProblemItem('❌ Faltam dados de teste'),
                  _buildProblemItem('❌ Índices do Firebase podem estar faltando'),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Solução
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                border: Border.all(color: Colors.green[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✅ SOLUÇÃO AUTOMÁTICA:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSolutionItem('🔧 Corrigir seu perfil automaticamente'),
                  _buildSolutionItem('📊 Criar 6 perfis de teste'),
                  _buildSolutionItem('🚀 Inicializar sistema completo'),
                  _buildSolutionItem('✅ Garantir que tudo funcione'),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Botão principal de execução
            ExecuteCompleteFixNow.buildFixButton(),
            
            const SizedBox(height: 16),
            
            // Botão alternativo
            QuickFixProfileButton(),
            
            const SizedBox(height: 24),
            
            // Instruções
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(color: Colors.blue[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📱 COMO TESTAR APÓS CORREÇÃO:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInstructionItem('1. Clique no botão vermelho acima'),
                  _buildInstructionItem('2. Aguarde a execução (30-60 segundos)'),
                  _buildInstructionItem('3. Toque no ícone 🔍 na barra superior'),
                  _buildInstructionItem('4. Você deve ver 7 perfis agora'),
                  _buildInstructionItem('5. Busque por "italo", "maria" ou "joão"'),
                  _buildInstructionItem('6. Seu perfil deve aparecer na busca'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProblemItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: Colors.orange[700],
        ),
      ),
    );
  }
  
  Widget _buildSolutionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: Colors.green[700],
        ),
      ),
    );
  }
  
  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: Colors.blue[700],
        ),
      ),
    );
  }
}