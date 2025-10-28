import 'package:flutter/material.dart';
import '../models/spiritual_profile_model.dart';
import '../theme.dart';

/// Seção de status de relacionamento com informações familiares e histórico
class RelationshipStatusSection extends StatelessWidget {
  final RelationshipStatus? relationshipStatus;
  final bool? hasChildren;
  final String? childrenDetails;
  final bool? isVirgin;
  final bool? wasPreviouslyMarried;
  final bool isVirginityPublic; // Nova propriedade para controle de privacidade

  const RelationshipStatusSection({
    Key? key,
    this.relationshipStatus,
    this.hasChildren,
    this.childrenDetails,
    this.isVirgin,
    this.wasPreviouslyMarried,
    this.isVirginityPublic = false, // Por padrão é privado
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          _buildSectionTitle('Status de Relacionamento'),
          const SizedBox(height: 16),

          // Status Cards Grid
          _buildStatusGrid(),
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

  Widget _buildStatusGrid() {
    List<Widget> statusCards = [];

    // Marital Status
    if (relationshipStatus != null) {
      statusCards.add(_buildStatusCard(
        icon: _getMaritalStatusIcon(),
        iconColor: _getMaritalStatusColor(),
        title: 'Estado Civil',
        value: _getMaritalStatusText(),
        isHighlighted: relationshipStatus == RelationshipStatus.solteiro,
      ));
    }

    // Children Status
    if (hasChildren != null) {
      statusCards.add(_buildStatusCard(
        icon: hasChildren! ? Icons.family_restroom : Icons.person,
        iconColor: hasChildren! ? Colors.green[600]! : Colors.blue[600]!,
        title: 'Filhos',
        value: _getChildrenStatusText(),
      ));
    }

    // Previous Marriage
    if (wasPreviouslyMarried != null) {
      statusCards.add(_buildStatusCard(
        icon: wasPreviouslyMarried! ? Icons.history : Icons.new_releases,
        iconColor:
            wasPreviouslyMarried! ? Colors.orange[600]! : Colors.teal[600]!,
        title: 'Histórico',
        value: _getMarriageHistoryText(),
      ));
    }

    // Virginity Status - APENAS SE PÚBLICO
    // Só exibe se o usuário marcou como público (isVirginityPublic = true)
    if (isVirgin != null && isVirginityPublic) {
      statusCards.add(_buildStatusCard(
        icon: Icons.favorite_border,
        iconColor: Colors.pink[400]!,
        title: 'Intimidade',
        value: _getVirginityStatusText(),
        isPrivate: false, // Usuário escolheu tornar público
      ));
    }

    return Column(
      children: [
        // First row
        if (statusCards.length >= 2) ...[
          Row(
            children: [
              Expanded(child: statusCards[0]),
              const SizedBox(width: 12),
              Expanded(child: statusCards[1]),
            ],
          ),
          const SizedBox(height: 12),
        ] else if (statusCards.length == 1) ...[
          statusCards[0],
          const SizedBox(height: 12),
        ],

        // Second row
        if (statusCards.length >= 4) ...[
          Row(
            children: [
              Expanded(child: statusCards[2]),
              const SizedBox(width: 12),
              Expanded(child: statusCards[3]),
            ],
          ),
        ] else if (statusCards.length == 3) ...[
          Row(
            children: [
              Expanded(child: statusCards[2]),
              const Expanded(child: SizedBox()), // Empty space
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    bool isHighlighted = false,
    bool isPrivate = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isHighlighted ? AppColors.primary.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted
              ? AppColors.primary.withOpacity(0.3)
              : Colors.grey[200]!,
          width: isHighlighted ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and privacy indicator
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
              const Spacer(),
              if (isPrivate)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock,
                        size: 12,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'Privado',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),

          // Value
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color:
                  isHighlighted ? AppColors.primary : const Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for status text and icons
  IconData _getMaritalStatusIcon() {
    switch (relationshipStatus) {
      case RelationshipStatus.solteiro:
      case RelationshipStatus.solteira:
        return Icons.person;
      case RelationshipStatus.comprometido:
      case RelationshipStatus.comprometida:
        return Icons.favorite;
      case RelationshipStatus.naoInformado:
        return Icons.help_outline;
      case null:
        return Icons.help_outline;
    }
  }

  Color _getMaritalStatusColor() {
    switch (relationshipStatus) {
      case RelationshipStatus.solteiro:
      case RelationshipStatus.solteira:
        return Colors.green[600]!;
      case RelationshipStatus.comprometido:
      case RelationshipStatus.comprometida:
        return Colors.red[600]!;
      case RelationshipStatus.naoInformado:
        return Colors.grey[600]!;
      case null:
        return Colors.grey[600]!;
    }
  }

  String _getMaritalStatusText() {
    switch (relationshipStatus) {
      case RelationshipStatus.solteiro:
        return 'Solteiro';
      case RelationshipStatus.solteira:
        return 'Solteira';
      case RelationshipStatus.comprometido:
        return 'Comprometido';
      case RelationshipStatus.comprometida:
        return 'Comprometida';
      case RelationshipStatus.naoInformado:
        return 'Não informado';
      case null:
        return 'Não informado';
    }
  }

  String _getChildrenStatusText() {
    if (hasChildren == null) return 'Não informado';
    if (hasChildren == true) {
      return childrenDetails ?? 'Tem filhos';
    }
    return 'Sem filhos';
  }

  String _getMarriageHistoryText() {
    if (wasPreviouslyMarried == null) return 'Não informado';
    return wasPreviouslyMarried! ? 'Já foi casado(a)' : 'Nunca casou';
  }

  String _getVirginityStatusText() {
    if (isVirgin == null) return 'Não informado';
    return isVirgin! ? 'Virgem' : 'Não virgem';
  }
}
