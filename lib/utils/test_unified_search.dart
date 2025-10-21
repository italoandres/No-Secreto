import 'package:flutter/material.dart';
import '../utils/unified_profile_search.dart';
import '../utils/enhanced_logger.dart';

/// Widget para testar a busca unificada
class TestUnifiedSearchWidget extends StatefulWidget {
  const TestUnifiedSearchWidget({Key? key}) : super(key: key);

  @override
  State<TestUnifiedSearchWidget> createState() => _TestUnifiedSearchWidgetState();
}

class _TestUnifiedSearchWidgetState extends State<TestUnifiedSearchWidget> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _results = [];
  bool _isLoading = false;
  String _lastQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste Busca Unificada'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Campo de busca
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Digite o nome para buscar',
                hintText: 'Ex: itala, maria, joão',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                if (value.length >= 2) {
                  _performSearch(value);
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Botões de teste rápido
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => _performSearch('itala'),
                  child: const Text('Buscar "itala"'),
                ),
                ElevatedButton(
                  onPressed: () => _performSearch('it'),
                  child: const Text('Buscar "it"'),
                ),
                ElevatedButton(
                  onPressed: () => _performSearch(''),
                  child: const Text('Buscar todos'),
                ),
                ElevatedButton(
                  onPressed: _testDetailedSearch,
                  child: const Text('Teste Detalhado'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Status
            if (_isLoading)
              const CircularProgressIndicator()
            else
              Text(
                'Última busca: "$_lastQuery" - ${_results.length} resultados',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            
            const SizedBox(height: 16),
            
            // Resultados
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final profile = _results[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: profile.profileType == 'vitrine' 
                            ? Colors.purple 
                            : Colors.blue,
                        child: Text(
                          profile.profileType == 'vitrine' ? 'V' : 'S',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(profile.displayName ?? 'Sem nome'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tipo: ${profile.profileType ?? 'spiritual'}'),
                          Text('Idade: ${profile.age ?? 'N/A'}'),
                          Text('Cidade: ${profile.city ?? 'N/A'}'),
                          if (profile.searchKeywords != null)
                            Text('Keywords: ${profile.searchKeywords!.join(', ')}'),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _lastQuery = query;
    });

    try {
      final results = await UnifiedProfileSearch.searchAllProfiles(
        query: query.isEmpty ? null : query,
        limit: 20,
      );

      setState(() {
        _results = results;
        _isLoading = false;
      });

      print('🔍 BUSCA REALIZADA:');
      print('Query: "$query"');
      print('Resultados: ${results.length}');
      for (final profile in results.take(3)) {
        print('  - ${profile.displayName} (${profile.profileType ?? 'spiritual'})');
      }

    } catch (e) {
      setState(() {
        _results = [];
        _isLoading = false;
      });

      print('❌ ERRO NA BUSCA: $e');
    }
  }

  Future<void> _testDetailedSearch() async {
    print('\n🔍 TESTE DETALHADO DA BUSCA UNIFICADA');
    print('=' * 50);

    await UnifiedProfileSearch.testUnifiedSearch();
  }
}

/// Função para abrir o widget de teste
void openUnifiedSearchTest(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const TestUnifiedSearchWidget(),
    ),
  );
}