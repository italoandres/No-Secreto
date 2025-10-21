import 'package:flutter/material.dart';
import 'populate_explore_profiles_test_data.dart';

/// Widget de teste para popular dados do sistema Explorar Perfis
class TestExploreProfilesData extends StatefulWidget {
  const TestExploreProfilesData({Key? key}) : super(key: key);

  @override
  State<TestExploreProfilesData> createState() => _TestExploreProfilesDataState();
}

class _TestExploreProfilesDataState extends State<TestExploreProfilesData> {
  bool _isLoading = false;
  String _status = 'Pronto para popular dados de teste';
  bool _dataExists = false;

  @override
  void initState() {
    super.initState();
    _checkDataExists();
  }

  Future<void> _checkDataExists() async {
    try {
      final exists = await PopulateExploreProfilesTestData.testDataExists();
      setState(() {
        _dataExists = exists;
        _status = exists 
            ? '✅ Dados de teste já existem' 
            : '⚠️ Dados de teste não encontrados';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Erro ao verificar dados: $e';
      });
    }
  }

  Future<void> _populateData() async {
    setState(() {
      _isLoading = true;
      _status = '🚀 Populando dados de teste...';
    });

    try {
      await PopulateExploreProfilesTestData.populateTestData();
      setState(() {
        _status = '🎉 Dados populados com sucesso!';
        _dataExists = true;
      });
    } catch (e) {
      setState(() {
        _status = '❌ Erro ao popular dados: $e';
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
      _status = '🧹 Removendo dados de teste...';
    });

    try {
      await PopulateExploreProfilesTestData.clearTestData();
      setState(() {
        _status = '✅ Dados removidos com sucesso!';
        _dataExists = false;
      });
    } catch (e) {
      setState(() {
        _status = '❌ Erro ao remover dados: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste: Explorar Perfis'),
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
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _status,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),

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
                    '1. Primeiro, crie os índices no Firebase Console\n'
                    '2. Aguarde os índices ficarem "Enabled"\n'
                    '3. Clique em "Popular Dados" abaixo\n'
                    '4. Teste o sistema Explorar Perfis',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Botões
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else ...[
              ElevatedButton.icon(
                onPressed: _dataExists ? null : _populateData,
                icon: const Icon(Icons.add_circle),
                label: const Text('Popular Dados de Teste'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),

              const SizedBox(height: 12),

              ElevatedButton.icon(
                onPressed: _dataExists ? _clearData : null,
                icon: const Icon(Icons.delete_sweep),
                label: const Text('Remover Dados de Teste'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: _checkDataExists,
                icon: const Icon(Icons.refresh),
                label: const Text('Verificar Status'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],

            const Spacer(),

            // Informações adicionais
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚠️ Importante:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.amber[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Os dados de teste serão adicionados às coleções:\n'
                    '• spiritual_profiles\n'
                    '• profile_engagement\n\n'
                    'Certifique-se de que os índices do Firebase estão criados antes de popular os dados.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.amber[700],
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
}