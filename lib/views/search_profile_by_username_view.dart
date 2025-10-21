import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../views/enhanced_vitrine_display_view.dart';

/// Tela para buscar perfis por @username
class SearchProfileByUsernameView extends StatefulWidget {
  const SearchProfileByUsernameView({Key? key}) : super(key: key);

  @override
  State<SearchProfileByUsernameView> createState() =>
      _SearchProfileByUsernameViewState();
}

class _SearchProfileByUsernameViewState
    extends State<SearchProfileByUsernameView> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isSearching = false;
  Map<String, dynamic>? _foundProfile;
  String? _errorMessage;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchByUsername() async {
    final username = _searchController.text.trim();
    
    if (username.isEmpty) {
      setState(() {
        _errorMessage = 'Digite um username para buscar';
        _foundProfile = null;
      });
      return;
    }

    // Remove @ se o usuário digitou
    final cleanUsername = username.startsWith('@') 
        ? username.substring(1) 
        : username;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _foundProfile = null;
    });

    try {
      // Buscar na coleção spiritual_profiles pelo username
      final querySnapshot = await _firestore
          .collection('spiritual_profiles')
          .where('username', isEqualTo: cleanUsername)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          _errorMessage = 'Nenhum perfil encontrado com @$cleanUsername';
          _isSearching = false;
        });
        return;
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data();
      
      setState(() {
        _foundProfile = {
          'userId': data['userId'] ?? doc.id,
          'displayName': data['displayName'] ?? 'Sem nome',
          'username': data['username'] ?? '',
          'mainPhotoUrl': data['mainPhotoUrl'] ?? '',
          'city': data['city'] ?? '',
          'state': data['state'] ?? '',
        };
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao buscar perfil: $e';
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Buscar por @'),
        backgroundColor: const Color(0xFF4169E1),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com ícone
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF4169E1),
                    const Color(0xFF6A5ACD),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.search,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Encontre Perfil por @',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Digite o username para encontrar o perfil',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Campo de busca
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '@username',
                prefixIcon: const Icon(Icons.alternate_email),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchByUsername,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF4169E1),
                    width: 2,
                  ),
                ),
              ),
              onSubmitted: (_) => _searchByUsername(),
            ),

            const SizedBox(height: 16),

            // Botão de busca
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSearching ? null : _searchByUsername,
                icon: _isSearching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.search),
                label: Text(
                  _isSearching ? 'Buscando...' : 'Buscar Perfil',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4169E1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Mensagem de erro
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Perfil encontrado
            if (_foundProfile != null) _buildFoundProfile(),
          ],
        ),
      ),
    );
  }

  Widget _buildFoundProfile() {
    final profile = _foundProfile!;
    final displayName = profile['displayName'] ?? 'Sem nome';
    final username = profile['username'] ?? '';
    final mainPhotoUrl = profile['mainPhotoUrl'] ?? '';
    final city = profile['city'] ?? '';
    final state = profile['state'] ?? '';

    print('📸 Building found profile');
    print('📸 Display Name: $displayName');
    print('📸 Username: $username');
    print('📸 Main Photo URL: $mainPhotoUrl');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Foto e informações
          Row(
            children: [
              // Foto
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: mainPhotoUrl.isNotEmpty
                    ? NetworkImage(mainPhotoUrl)
                    : null,
                child: mainPhotoUrl.isEmpty
                    ? Icon(Icons.person, size: 40, color: Colors.grey.shade400)
                    : null,
              ),
              const SizedBox(width: 16),
              // Informações
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@$username',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (city.isNotEmpty || state.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$city${city.isNotEmpty && state.isNotEmpty ? ', ' : ''}$state',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Botão para ver perfil completo
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Get.to(
                  () => const EnhancedVitrineDisplayView(),
                  arguments: {
                    'userId': profile['userId'],
                    'isOwnProfile': false,
                    'fromCelebration': false,
                  },
                );
              },
              icon: const Icon(Icons.visibility),
              label: const Text('Ver Perfil Completo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4169E1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
