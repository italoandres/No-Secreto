import 'package:flutter/material.dart';
import '../models/scored_profile.dart';

/// Chips modernos de hobbies com emojis
class HobbiesChipsModern extends StatelessWidget {
  final ScoredProfile profile;

  const HobbiesChipsModern({
    Key? key,
    required this.profile,
  }) : super(key: key);

  // Mapeamento de hobbies para emojis
  static const Map<String, String> _hobbiesEmojis = {
    'Dançando': '💃',
    'Dança': '💃',
    'Viajar': '✈️',
    'Viagens': '✈️',
    'Ciclismo': '🚴',
    'Natação': '🏊',
    'Passeios': '🏛️',
    'Natureza': '🌿',
    'Música': '🎵',
    'Leitura': '📚',
    'Voluntariado': '🤝',
    'Yoga': '🧘',
    'Cinema': '🎬',
    'Culinária': '🍳',
    'Fotografia': '📷',
    'Meditação': '🧘‍♀️',
    'Arte': '🎨',
  };

  String _getEmojiForHobby(String hobby) {
    return _hobbiesEmojis[hobby] ?? '🎯';
  }

  @override
  Widget build(BuildContext context) {
    final hobbies = profile.hobbies;

    if (hobbies.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: hobbies.map((hobby) => _buildHobbyChip(hobby)).toList(),
      ),
    );
  }

  Widget _buildHobbyChip(String hobby) {
    final emoji = _getEmojiForHobby(hobby);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(width: 6),
          Text(
            hobby,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2C3E50),
            ),
          ),
        ],
      ),
    );
  }
}
