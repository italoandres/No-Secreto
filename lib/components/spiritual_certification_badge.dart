import 'package:flutter/material.dart';

/// Badge de Certificação Espiritual
/// 
/// Componente visual que indica que um usuário foi certificado espiritualmente.
/// Exibe um badge dourado/laranja com ícone de verificação e texto.
/// Ao clicar, mostra um dialog informativo sobre a certificação.
class SpiritualCertificationBadge extends StatelessWidget {
  final bool isCertified;
  final double size;
  final bool showLabel;
  final VoidCallback? onTap;

  const SpiritualCertificationBadge({
    Key? key,
    required this.isCertified,
    this.size = 60,
    this.showLabel = true,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isCertified) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap ?? () => _showCertificationInfo(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Badge circular com gradiente
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.amber.shade400,
                  Colors.amber.shade700,
                  Colors.amber.shade900,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.shade700.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.verified,
              color: Colors.white,
              size: size * 0.6,
            ),
          ),
          
          if (showLabel) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber.shade400,
                    Colors.amber.shade600,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.shade400.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Certificado ✓',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
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

  void _showCertificationInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CertificationInfoDialog(),
    );
  }
}

/// Dialog informativo sobre a certificação espiritual
class CertificationInfoDialog extends StatelessWidget {
  const CertificationInfoDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.amber.shade50,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícone de certificação
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.amber.shade400,
                    Colors.amber.shade700,
                    Colors.amber.shade900,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.shade700.withOpacity(0.5),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.verified,
                color: Colors.white,
                size: 48,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Título
            Text(
              'Certificação Espiritual',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade900,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // Descrição
            Text(
              'Este usuário foi certificado espiritualmente pela nossa equipe.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Informações adicionais
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.amber.shade200,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoItem(
                    icon: Icons.check_circle_outline,
                    text: 'Identidade verificada',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoItem(
                    icon: Icons.church_outlined,
                    text: 'Compromisso espiritual confirmado',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoItem(
                    icon: Icons.shield_outlined,
                    text: 'Perfil confiável e autêntico',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Botão de fechar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Entendi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.amber.shade700,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),
        ),
      ],
    );
  }
}

/// Badge compacto para uso em listas e cards
class CompactCertificationBadge extends StatelessWidget {
  final bool isCertified;
  final double size;

  const CompactCertificationBadge({
    Key? key,
    required this.isCertified,
    this.size = 24,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isCertified) {
      return const SizedBox.shrink();
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber.shade400,
            Colors.amber.shade700,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.shade700.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Icon(
        Icons.verified,
        color: Colors.white,
        size: size * 0.7,
      ),
    );
  }
}

/// Badge inline para uso ao lado de nomes
class InlineCertificationBadge extends StatelessWidget {
  final bool isCertified;

  const InlineCertificationBadge({
    Key? key,
    required this.isCertified,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isCertified) {
      return const SizedBox.shrink();
    }

    return Tooltip(
      message: 'Certificado Espiritualmente',
      child: Icon(
        Icons.verified,
        color: Colors.amber.shade700,
        size: 20,
      ),
    );
  }
}
