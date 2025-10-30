import 'package:flutter/material.dart';

/// Card com toggle de preferência de hobbies
class HobbiesPreferenceToggleCard extends StatelessWidget {
  final bool isEnabled;
  final Function(bool) onToggle;

  const HobbiesPreferenceToggleCard({
    Key? key,
    required this.isEnabled,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEnabled
              ? Colors.deepPurple.withOpacity(0.3)
              : Colors.grey[300]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isEnabled
                ? Colors.deepPurple.withOpacity(0.08)
                : Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header com toggle
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isEnabled
                      ? Colors.deepPurple.withOpacity(0.1)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.favorite,
                  color: isEnabled ? Colors.deepPurple[500] : Colors.grey[400],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tenho interesse nesses sinais em pessoas que correspondem a essa preferência',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color:
                        isEnabled ? const Color(0xFF333333) : Colors.grey[700],
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Transform.scale(
                scale: 1.1,
                child: Switch(
                  value: isEnabled,
                  onChanged: onToggle,
                  activeColor: Colors.deepPurple[500],
                  activeTrackColor: Colors.deepPurple.withOpacity(0.5),
                  inactiveThumbColor: Colors.grey[400],
                  inactiveTrackColor: Colors.grey[300],
                ),
              ),
            ],
          ),

          // Mensagem explicativa (aparece quando ativado)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: isEnabled
                ? Column(
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.deepPurple.withOpacity(0.08),
                              Colors.deepPurple[300]!.withOpacity(0.08),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.deepPurple.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.lightbulb_outline,
                                color: Colors.deepPurple[500],
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Como funciona?',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple[500],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Com este sinal, podemos saber em quais tipos de perfil tem mais interesse, mas ainda sim podem aparecer outros que não correspondem exatamente.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[800],
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),

          // Dica quando desativado
          if (!isEnabled) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.grey[200]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.grey[600],
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ative para priorizar perfis com hobbies em comum',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
