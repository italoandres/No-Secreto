import 'package:flutter/material.dart';
import '../utils/certification_badge_helper.dart';
import '../components/spiritual_certification_badge.dart';

/// Exemplos práticos de integração do badge de certificação
/// 
/// Este arquivo contém exemplos de como integrar o badge de certificação
/// em diferentes telas e contextos do aplicativo.

// ============================================================================
// 1. PERFIL PRÓPRIO - Tela Principal do Perfil
// ============================================================================

class ProfileViewWithBadge extends StatelessWidget {
  final String currentUserId;

  const ProfileViewWithBadge({
    Key? key,
    required this.currentUserId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header do perfil com foto
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Foto do perfil
                  const CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage('https://example.com/photo.jpg'),
                  ),
                  const SizedBox(height: 16),
                  
                  // Nome do usuário
                  const Text(
                    'João Silva',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // ✅ BADGE DE CERTIFICAÇÃO - PERFIL PRÓPRIO
                  CertificationBadgeHelper.buildOwnProfileBadge(
                    context: context,
                    userId: currentUserId,
                    size: 80,
                    showLabel: true,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Outras informações do perfil...
                  const Text(
                    'Buscando relacionamento sério baseado em valores cristãos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Outras seções do perfil...
            _buildProfileSection('Informações Básicas', [
              _buildInfoRow('Idade', '28 anos'),
              _buildInfoRow('Localização', 'São Paulo, SP'),
              _buildInfoRow('Profissão', 'Engenheiro'),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 2. PERFIL DE OUTROS USUÁRIOS - Visualização de Perfil
// ============================================================================

class OtherProfileViewWithBadge extends StatelessWidget {
  final String userId;
  final String userName;
  final String userPhotoUrl;

  const OtherProfileViewWithBadge({
    Key? key,
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(userName),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Menu de opções
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header do perfil
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Foto do perfil
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(userPhotoUrl),
                  ),
                  const SizedBox(height: 16),
                  
                  // Nome do usuário
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // ✅ BADGE DE CERTIFICAÇÃO - OUTRO PERFIL
                  // Só aparece se o usuário for certificado
                  CertificationBadgeHelper.buildOtherProfileBadge(
                    userId: userId,
                    size: 70,
                    showLabel: true,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Botões de ação
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          // Demonstrar interesse
                        },
                        icon: const Icon(Icons.favorite),
                        label: const Text('Interesse'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          // Iniciar conversa
                        },
                        icon: const Icon(Icons.chat),
                        label: const Text('Conversar'),
                      ),
                    ],
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

// ============================================================================
// 3. CARDS DA VITRINE - Lista de Perfis
// ============================================================================

class VitrineProfileCard extends StatelessWidget {
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final int age;
  final String location;

  const VitrineProfileCard({
    Key? key,
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.age,
    required this.location,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Conteúdo do card
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Foto do usuário
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  image: DecorationImage(
                    image: NetworkImage(userPhotoUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              
              // Informações do usuário
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nome com badge inline
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // ✅ BADGE INLINE - VITRINE
                        CertificationBadgeHelper.buildInlineBadge(
                          userId: userId,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Idade e localização
                    Text(
                      '$age anos • $location',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Botões de ação
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              // Ver perfil completo
                            },
                            child: const Text('Ver Perfil'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            // Demonstrar interesse
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                            foregroundColor: Colors.white,
                            shape: const CircleBorder(),
                          ),
                          child: const Icon(Icons.favorite),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // ✅ BADGE POSICIONADO - VITRINE
          CertificationBadgeHelper.buildVitrineCardBadge(
            userId: userId,
            size: 32,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 4. RESULTADOS DE BUSCA - Lista de Usuários
// ============================================================================

class SearchResultItem extends StatelessWidget {
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final int age;
  final String location;

  const SearchResultItem({
    Key? key,
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.age,
    required this.location,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      leading: CircleAvatar(
        radius: 30,
        backgroundImage: NetworkImage(userPhotoUrl),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              userName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // ✅ BADGE INLINE - BUSCA
          CertificationBadgeHelper.buildInlineBadge(
            userId: userId,
            size: 18,
          ),
        ],
      ),
      subtitle: Text(
        '$age anos • $location',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.arrow_forward_ios),
        onPressed: () {
          // Navegar para perfil
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtherProfileViewWithBadge(
                userId: userId,
                userName: userName,
                userPhotoUrl: userPhotoUrl,
              ),
            ),
          );
        },
      ),
      onTap: () {
        // Navegar para perfil
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtherProfileViewWithBadge(
              userId: userId,
              userName: userName,
              userPhotoUrl: userPhotoUrl,
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// 5. CHAT - Header da Conversa
// ============================================================================

class ChatViewWithBadge extends StatelessWidget {
  final String otherUserId;
  final String otherUserName;
  final String otherUserPhotoUrl;

  const ChatViewWithBadge({
    Key? key,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserPhotoUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(otherUserPhotoUrl),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          otherUserName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // ✅ BADGE INLINE - CHAT
                      CertificationBadgeHelper.buildInlineBadge(
                        userId: otherUserId,
                        size: 16,
                      ),
                    ],
                  ),
                  Text(
                    'Online',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              // Videochamada
            },
          ),
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              // Chamada
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Menu
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Lista de mensagens
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Mensagens do chat...
                _buildMessage('Olá! Como você está?', true),
                _buildMessage('Oi! Estou bem, obrigada! E você?', false),
                _buildMessage('Também estou bem! Vi que você é certificada espiritualmente, que legal!', true),
              ],
            ),
          ),
          
          // Campo de entrada de mensagem
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Digite sua mensagem...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: () {
                    // Enviar mensagem
                  },
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
