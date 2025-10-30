import 'package:flutter/material.dart';
import '../theme.dart';

/// Seção de informações espirituais com propósito, frase de fé e relacionamento
class SpiritualInfoSection extends StatelessWidget {
  final String? purpose;
  final String? faithPhrase;
  final bool? readyForPurposefulRelationship;
  final String? nonNegotiableValue;

  const SpiritualInfoSection({
    Key? key,
    this.purpose,
    this.faithPhrase,
    this.readyForPurposefulRelationship,
    this.nonNegotiableValue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          _buildSectionTitle('Informações Espirituais'),
          const SizedBox(height: 16),

          // Purpose
          if (purpose?.isNotEmpty == true) ...[
            _buildSpiritualCard(
              icon: Icons.favorite,
              iconColor: Colors.pink[400]!,
              title: 'Meu Propósito',
              content: purpose!,
              isExpandable: true,
            ),
            const SizedBox(height: 16),
          ],

          // Faith Phrase
          if (faithPhrase?.isNotEmpty == true) ...[
            _buildSpiritualCard(
              icon: Icons.auto_awesome,
              iconColor: Colors.amber[600]!,
              title: 'Frase de Fé',
              content: faithPhrase!,
              isQuote: true,
            ),
            const SizedBox(height: 16),
          ],

          // Relationship Readiness
          if (readyForPurposefulRelationship != null) ...[
            _buildReadinessIndicator(),
            const SizedBox(height: 16),
          ],

          // Non-negotiable Value
          if (nonNegotiableValue?.isNotEmpty == true) ...[
            _buildSpiritualCard(
              icon: Icons.shield,
              iconColor: Colors.blue[600]!,
              title: 'Valor Inegociável',
              content: nonNegotiableValue!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF333333),
      ),
    );
  }

  Widget _buildSpiritualCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
    bool isExpandable = false,
    bool isQuote = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Content
          if (isQuote) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  left: BorderSide(
                    color: iconColor,
                    width: 4,
                  ),
                ),
              ),
              child: Text(
                '"$content"',
                style: const TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF333333),
                  height: 1.5,
                ),
              ),
            ),
          ] else ...[
            Text(
              content,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF333333),
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReadinessIndicator() {
    bool isReady = readyForPurposefulRelationship == true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isReady
              ? [
                  const Color(0xFF4CAF50).withOpacity(0.1),
                  const Color(0xFF4CAF50).withOpacity(0.05),
                ]
              : [
                  Colors.grey[100]!,
                  Colors.grey[50]!,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isReady
              ? const Color(0xFF4CAF50).withOpacity(0.3)
              : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isReady ? const Color(0xFF4CAF50) : Colors.grey[400],
              shape: BoxShape.circle,
            ),
            child: Icon(
              isReady ? Icons.favorite : Icons.favorite_border,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Relacionamento com Propósito',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isReady
                      ? 'Disposto(a) a viver um relacionamento com propósito'
                      : 'Não está buscando relacionamento no momento',
                  style: TextStyle(
                    fontSize: 14,
                    color: isReady ? const Color(0xFF4CAF50) : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
