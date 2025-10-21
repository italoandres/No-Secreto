import 'package:flutter/material.dart';
import '../services/explore_profiles_initializer.dart';
import '../utils/quick_populate_profiles.dart';
import '../utils/fix_existing_profile_for_exploration.dart';

/// Executa correção completa AGORA
class ExecuteCompleteFixNow {
  
  /// EXECUTA TUDO AGORA - Chame este método
  static Future<void> fixEverythingNow() async {
    print('🚀🚀🚀 EXECUTANDO CORREÇÃO COMPLETA AGORA! 🚀🚀🚀');
    print('=' * 60);
    
    try {
      // 1. POPULAR DADOS DE TESTE PRIMEIRO
      print('\n1️⃣ POPULANDO DADOS DE TESTE...');
      await QuickPopulateProfiles.populateNow();
      print('✅ Dados de teste populados!');
      
      // 2. CORRIGIR SEU PERFIL
      print('\n2️⃣ CORRIGINDO SEU PERFIL...');
      await FixExistingProfileForExploration.runCompleteCheck();
      print('✅ Seu perfil corrigido!');
      
      // 3. INICIALIZAR SISTEMA
      print('\n3️⃣ INICIALIZANDO SISTEMA...');
      await ExploreProfilesInitializer.initialize();
      print('✅ Sistema inicializado!');
      
      print('\n' + '=' * 60);
      print('🎉🎉🎉 CORREÇÃO COMPLETA EXECUTADA! 🎉🎉🎉');
      print('📱 AGORA TESTE: Toque no ícone 🔍 na barra superior');
      print('📊 VOCÊ DEVE VER: 7 perfis (6 de teste + o seu)');
      print('🔍 BUSQUE POR: "italo" ou "maria" ou "joão"');
      print('=' * 60);
      
    } catch (e) {
      print('❌ ERRO DURANTE EXECUÇÃO: $e');
      rethrow;
    }
  }
  
  /// Widget para executar com botão
  static Widget buildFixButton() {
    return _FixButtonWidget();
  }
}

class _FixButtonWidget extends StatefulWidget {
  @override
  State<_FixButtonWidget> createState() => _FixButtonWidgetState();
}

class _FixButtonWidgetState extends State<_FixButtonWidget> {
  bool _isLoading = false;
  bool _isFixed = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _executeFixNow,
        icon: _isLoading 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(_isFixed ? Icons.check_circle : Icons.rocket_launch),
        label: Text(
          _isLoading 
              ? 'Executando Correção...'
              : _isFixed 
                  ? '🎉 CORRIGIDO! Teste o ícone 🔍'
                  : '🚀 EXECUTAR CORREÇÃO COMPLETA AGORA',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isFixed ? Colors.green[600] : Colors.red[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Future<void> _executeFixNow() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Executar correção completa
      await ExecuteCompleteFixNow.fixEverythingNow();
      
      setState(() {
        _isFixed = true;
      });

      // Mostrar mensagem de sucesso
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '🎉 CORREÇÃO COMPLETA EXECUTADA!\n'
              '📱 Agora teste o ícone 🔍 na barra superior\n'
              '📊 Você deve ver 7 perfis agora!',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 6),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}