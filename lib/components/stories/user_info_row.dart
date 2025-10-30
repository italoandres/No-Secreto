import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Linha de informações do usuário (foto, nome e timestamp)
/// Exibe no topo do card de comentário
class UserInfoRow extends StatelessWidget {
  final String userName;
  final String? userPhotoUrl;
  final String timestamp;

  const UserInfoRow({
    super.key,
    required this.userName,
    this.userPhotoUrl,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Foto de perfil
        CircleAvatar(
          radius: 16,
          backgroundColor: Colors.grey[300],
          backgroundImage: userPhotoUrl != null && userPhotoUrl!.isNotEmpty
              ? CachedNetworkImageProvider(userPhotoUrl!)
              : null,
          child: userPhotoUrl == null || userPhotoUrl!.isEmpty
              ? Icon(
                  Icons.person,
                  size: 20,
                  color: Colors.grey[600],
                )
              : null,
        ),
        
        const SizedBox(width: 12),
        
        // Nome do usuário
        Expanded(
          child: Text(
            userName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Timestamp
        Text(
          timestamp,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
