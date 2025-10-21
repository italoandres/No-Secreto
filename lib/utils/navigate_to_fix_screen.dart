import 'package:flutter/material.dart';
import '../views/fix_explore_profiles_test_view.dart';

/// Utilitário para navegar para a tela de correção
class NavigateToFixScreen {
  
  /// Navega para a tela de correção do Explorar Perfis
  static void navigateToFixScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FixExploreProfilesTestView(),
      ),
    );
  }
  
  /// Cria um botão que navega para a tela de correção
  static Widget buildNavigationButton(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: () => navigateToFixScreen(context),
        icon: const Icon(Icons.build_circle),
        label: const Text(
          '🔧 Abrir Tela de Correção',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
  
  /// Mostra um dialog com opção de navegar
  static void showFixDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('🔧 Corrigir Explorar Perfis'),
          content: const Text(
            'Seu perfil não está aparecendo no "Explorar Perfis".\n\n'
            'Deseja abrir a tela de correção para resolver isso automaticamente?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                navigateToFixScreen(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('🚀 Corrigir Agora'),
            ),
          ],
        );
      },
    );
  }
}