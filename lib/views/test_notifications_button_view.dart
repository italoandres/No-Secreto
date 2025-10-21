import 'package:flutter/material.dart';
import '../utils/create_test_interests.dart';
import '../utils/debug_real_notifications.dart';

/// Tela com botão para criar dados de teste das notificações
class TestNotificationsButtonView extends StatefulWidget {
  const TestNotificationsButtonView({Key? key}) : super(key: key);

  @override
  State<TestNotificationsButtonView> createState() => _TestNotificationsButtonViewState();
}

class _TestNotificationsButtonViewState extends State<TestNotificationsButtonView> {
  bool _isLoading = false;
  String _status = '';

  Future<void> _createTestData() async {
    setState(() {
      _isLoading = true;
      _status = 'Criando dados de teste...';
    });

    try {
      // 1. Verificar dados existentes
      await CreateTestInterests.checkExistingInterests();
      
      setState(() {
        _status = 'Criando interesses de teste...';
      });
      
      // 2. Criar dados de teste
      await CreateTestInterests.createTestInterestsForItala();
      
      setState(() {
        _status = 'Testando notificações...';
      });
      
      // 3. Testar notificações
      await DebugRealNotifications.quickTest('St2kw3cgX2MMPxlLRmBDjYm2nO22');
      
      setState(() {
        _status = '✅ Sucesso! Dados de teste criados. Verifique as notificações no app.';
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _status = '❌ Erro: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _checkData() async {
    setState(() {
      _isLoading = true;
      _status = 'Verificando dados existentes...';
    });

    try {
      await CreateTestInterests.checkExistingInterests();
      
      setState(() {
        _status = '✅ Verificação concluída. Veja o console para detalhes.';
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _status = '❌ Erro: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _clearTestData() async {
    setState(() {
      _isLoading = true;
      _status = 'Limpando dados de teste...';
    });

    try {
      await CreateTestInterests.clearTestInterests();
      
      setState(() {
        _status = '✅ Dados de teste removidos.';
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _status = '❌ Erro: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Teste de Notificações'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎯 Problema Identificado',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'O sistema de notificações está funcionando, mas não há dados reais na coleção "interests" do Firebase.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🚀 Solução',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Clique no botão abaixo para criar dados de teste. Isso simulará 3 pessoas demonstrando interesse por você.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Botão principal
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _createTestData,
              icon: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.science),
              label: Text(_isLoading ? 'Criando...' : '🧪 Criar Dados de Teste'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Botões secundários
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _checkData,
                    icon: const Icon(Icons.search),
                    label: const Text('Verificar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _clearTestData,
                    icon: const Icon(Icons.delete),
                    label: const Text('Limpar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Status
            if (_status.isNotEmpty)
              Card(
                color: _status.contains('✅') ? Colors.green[50] : 
                       _status.contains('❌') ? Colors.red[50] : Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _status,
                    style: TextStyle(
                      fontSize: 14,
                      color: _status.contains('✅') ? Colors.green[800] : 
                             _status.contains('❌') ? Colors.red[800] : Colors.blue[800],
                    ),
                  ),
                ),
              ),
            
            const Spacer(),
            
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📋 O que acontecerá:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('• João Silva demonstrará interesse por você'),
                    Text('• Pedro Santos demonstrará interesse por você'),
                    Text('• Carlos Lima demonstrará interesse por você'),
                    SizedBox(height: 8),
                    Text(
                      'Depois disso, você verá as notificações reais no app!',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}