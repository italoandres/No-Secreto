import 'package:flutter/material.dart';

/// Texto do comentário com estilo apropriado
/// Suporta múltiplas linhas com quebra automática
class CommentText extends StatelessWidget {
  final String text;

  const CommentText({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.normal,
        color: Colors.black87,
        height: 1.4,
      ),
    );
  }
}
