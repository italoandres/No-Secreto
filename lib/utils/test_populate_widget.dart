import 'package:flutter/material.dart';
import 'quick_populate_profiles.dart';

/// Widget simples para testar população de dados
class TestPopulateWidget extends StatefulWidget {
  const TestPopulateWidget({Key? key}) : super(key: key);

  @override
  State<TestPopulateWidget> createState() => _TestPopulateWidgetState();
}

class _TestPopulateWidgetState extends State<TestPopulateWidget> {
  String _status = 'Pronto para testar';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste: Popular Dados'),
        backgroundColor: Colors.blue[600],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _status,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 24),

            // Botões
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              ElevatedButton(
                onPressed: _populateData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('🚀 POPULAR DADOS AGORA'),
              ),

              const SizedBox(height: 12),

              ElevatedButton(
                onPressed: _checkData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('🔍 VERIFICAR DADOS'),
              ),

              const SizedBox(height: 12),

              ElevatedButton(
                onPressed: _clearData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('🗑️ LIMPAR DADOS'),
              ),
            ],

            const SizedBox(height: 24),

            // Instruções
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📋 Instruções:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. Clique em "POPULAR DADOS AGORA"\n'
                    '2. Aguarde 1-2 minutos\n'
                    '3. Teste o sistema Explorar Perfis\n'
                    '4. Procure o ícone 🔍 na barra superior',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _populateData() async {
    setState(() {
      _isLoading = true;
      _status = '🚀 Populando dados...';
    });

    try {
      await QuickPopulateProfiles.populateNow();
      setState(() {
        _status = '🎉 Dados populados com sucesso!\n'
                  'Agora teste o sistema Explorar Perfis!';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Erro: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkData() async {
    setState(() {
      _isLoading = true;
      _status = '🔍 Verificando dados...';
    });

    try {
      final hasData = await QuickPopulateProfiles.checkData();
      setState(() {
        _status = hasData 
            ? '✅ Dados encontrados! Sistema deve funcionar.'
            : '⚠️ Nenhum dado encontrado. Clique em "POPULAR DADOS".';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Erro ao verificar: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearData() async {
    setState(() {
      _isLoading = true;
      _status = '🧹 Removendo dados...';
    });

    try {
      await QuickPopulateProfiles.clearData();
      setState(() {
        _status = '✅ Dados removidos com sucesso!';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Erro ao remover: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}