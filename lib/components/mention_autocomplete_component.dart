import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:whatsapp_chat/models/usuario_model.dart';
import 'package:whatsapp_chat/repositories/purpose_partnership_repository.dart';

class MentionAutocompleteComponent extends StatelessWidget {
  final String query;
  final Function(UsuarioModel) onUserSelected;
  final VoidCallback onDismiss;

  const MentionAutocompleteComponent({
    super.key,
    required this.query,
    required this.onUserSelected,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (query.length < 2) {
      return const SizedBox();
    }

    return FutureBuilder<List<UsuarioModel>>(
      future: PurposePartnershipRepository.searchUsersByName(query),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox();
        }

        final users = snapshot.data!;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF39b9ff).withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.alternate_email,
                        color: Color(0xFF39b9ff), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Mencionar usuário',
                      style: TextStyle(
                        color: const Color(0xFF39b9ff),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: onDismiss,
                      child: const Icon(Icons.close,
                          color: Color(0xFF39b9ff), size: 16),
                    ),
                  ],
                ),
              ),
              // Lista de usuários
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return _buildUserItem(user);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserItem(UsuarioModel user) {
    return InkWell(
      onTap: () => onUserSelected(user),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF39b9ff).withOpacity(0.1),
              ),
              child: user.imgUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        user.imgUrl!,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildDefaultAvatar(user.nome);
                        },
                      ),
                    )
                  : _buildDefaultAvatar(user.nome),
            ),
            const SizedBox(width: 12),
            // Nome e email
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.username != null && user.username!.isNotEmpty
                        ? '@${user.username}'
                        : user.nome ?? 'Usuário',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (user.email != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      user.email!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Ícone de menção
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFfc6aeb).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.alternate_email,
                color: Color(0xFFfc6aeb),
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(String? name) {
    final initial = (name?.isNotEmpty == true) ? name![0].toUpperCase() : '?';
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: Color(0xFF39b9ff),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
