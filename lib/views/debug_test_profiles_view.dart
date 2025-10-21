import 'package:flutter/material.dart';
import '../utils/create_test_profiles_sinais.dart';
import '../utils/create_test_interests_matches.dart';
import '../utils/update_test_profiles_purpose.dart';
import '../utils/update_profiles_deus_e_pai.dart';
import '../utils/update_profiles_hobbies.dart';

/// View de debug para criar/remover perfis de teste
class DebugTestProfilesView extends StatefulWidget {
  const DebugTestProfilesView({Key? key}) : super(key: key);

  @override
  State<DebugTestProfilesView> createState() => _DebugTestProfilesViewState();
}

class _DebugTestProfilesViewState extends State<DebugTestProfilesView> {
  bool _isLoading = false;
  String _message = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug - Perfis de Teste'),
        backgroundColor: const Color(0xFF4169E1),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.bug_report,
                size: 80,
                color: Color(0xFF4169E1),
              ),
              const SizedBox(height: 32),
              const Text(
                'Gerenciar Perfis de Teste',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Crie perfis de teste para visualizar na aba Sinais',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // Seção: Perfis
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '👥 Perfis de Teste',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Botão Criar Perfis
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _createProfiles,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text(
                    'Criar 6 Perfis de Teste',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Botão Atualizar Perfis (adicionar campo purpose)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _updateProfiles,
                  icon: const Icon(Icons.update),
                  label: const Text(
                    'Atualizar Perfis (Adicionar Propósito)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Botão Atualizar Deus é Pai
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _updateDeusEPai,
                  icon: const Icon(Icons.church),
                  label: const Text(
                    'Atualizar Deus é Pai',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Botão Atualizar Hobbies
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _updateHobbies,
                  icon: const Icon(Icons.interests),
                  label: const Text(
                    'Atualizar Hobbies',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Seção: Interesses e Matches
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '💕 Interesses e Matches',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Botão Criar Interesses
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _createInterests,
                  icon: const Icon(Icons.favorite_border),
                  label: const Text(
                    'Criar 3 Interesses',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Botão Criar Matches
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _createMatches,
                  icon: const Icon(Icons.favorite),
                  label: const Text(
                    'Criar 2 Matches',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Botão Criar Tudo
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _createAll,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text(
                    'Criar Tudo (Perfis + Interesses + Matches)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4169E1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Seção: Limpeza
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '🗑️ Limpeza',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Botão Remover Tudo
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _deleteAll,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text(
                    'Remover Tudo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Loading indicator
              if (_isLoading)
                const CircularProgressIndicator(),
              
              // Message
              if (_message.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Text(
                    _message,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[900],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              const SizedBox(height: 32),
              
              // Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber[900]),
                        const SizedBox(width: 8),
                        Text(
                          'Perfis que serão criados:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildProfileInfo('1. Maria Silva (28)', 'Certificada + Movimento'),
                    _buildProfileInfo('2. Ana Costa (25)', 'Certificada'),
                    _buildProfileInfo('3. Juliana Santos (30)', 'Movimento'),
                    _buildProfileInfo('4. Beatriz Oliveira (27)', 'Perfil completo'),
                    _buildProfileInfo('5. Carolina Ferreira (26)', 'Certificada + Movimento'),
                    _buildProfileInfo('6. Fernanda Lima (29)', 'Perfil básico'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfo(String name, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.person, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$name - $description',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createProfiles() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      await CreateTestProfilesSinais.createTestProfiles();
      setState(() {
        _message = '✅ 6 perfis criados com sucesso!\nAgora você pode testar a aba Sinais.';
      });
    } catch (e) {
      setState(() {
        _message = '❌ Erro ao criar perfis: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfiles() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      await UpdateTestProfilesPurpose.updateProfiles();
      setState(() {
        _message = '✅ Perfis atualizados com sucesso!\n\n'
            'Campo "Propósito" adicionado a todos os perfis.\n'
            'Agora você verá a seção 💫 Propósito nos cards!';
      });
    } catch (e) {
      setState(() {
        _message = '❌ Erro ao atualizar perfis: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateDeusEPai() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      await UpdateProfilesDeusEPai.updateAllTestProfiles();
      setState(() {
        _message = '✅ Perfis atualizados com sucesso!\n\n'
            'Campo "isDeusEPaiMember" adicionado.\n'
            'Agora você verá o chip ⛪ Membro do Movimento!';
      });
    } catch (e) {
      setState(() {
        _message = '❌ Erro ao atualizar perfis: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateHobbies() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      await UpdateProfilesHobbies.updateProfiles();
      setState(() {
        _message = '✅ Hobbies atualizados com sucesso!\n\n'
            'Todos os perfis agora têm hobbies.\n'
            'Você verá a seção 🎯 Hobbies nos cards!';
      });
    } catch (e) {
      setState(() {
        _message = '❌ Erro ao atualizar hobbies: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createInterests() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      await CreateTestInterestsMatches.createTestInterests();
      setState(() {
        _message = '✅ 3 interesses criados!\n(Maria, Ana e Carolina demonstraram interesse em você)';
      });
    } catch (e) {
      setState(() {
        _message = '❌ Erro ao criar interesses: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createMatches() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      await CreateTestInterestsMatches.createTestMatches();
      setState(() {
        _message = '✅ 2 matches criados!\n(Juliana e Beatriz)';
      });
    } catch (e) {
      setState(() {
        _message = '❌ Erro ao criar matches: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createAll() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      await CreateTestProfilesSinais.createTestProfiles();
      await CreateTestInterestsMatches.createTestInterests();
      await CreateTestInterestsMatches.createTestMatches();
      setState(() {
        _message = '✅ Tudo criado com sucesso!\n\n'
            '• 6 perfis de teste\n'
            '• 3 interesses (Maria, Ana, Carolina)\n'
            '• 2 matches (Juliana, Beatriz)\n\n'
            'Agora você pode testar todas as abas!';
      });
    } catch (e) {
      setState(() {
        _message = '❌ Erro ao criar dados: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAll() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      await CreateTestProfilesSinais.deleteTestProfiles();
      await CreateTestInterestsMatches.deleteTestInterestsAndMatches();
      setState(() {
        _message = '✅ Todos os dados de teste foram removidos!';
      });
    } catch (e) {
      setState(() {
        _message = '❌ Erro ao remover dados: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
