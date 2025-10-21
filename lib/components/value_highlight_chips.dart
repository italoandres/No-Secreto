import 'package:flutter/material.dart';
import '../models/scored_profile.dart';

/// Chips destacando valores e princípios espirituais do perfil
class ValueHighlightChips extends StatelessWidget {
  final ScoredProfile profile;

  const ValueHighlightChips({
    Key? key,
    required this.profile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Seção: Propósito
        if (_hasPurpose())
          _buildSection(
            title: '💫 Propósito',
            children: _buildPurpose(),
          ),

        // Seção: Valores Espirituais
        if (_hasSpiritualValues())
          _buildSection(
            title: '✨ Valores Espirituais',
            children: _buildSpiritualValues(),
          ),

        // Seção: Informações Pessoais
        if (_hasPersonalInfo())
          _buildSection(
            title: '👤 Informações Pessoais',
            children: _buildPersonalInfo(),
          ),

        const SizedBox(height: 16),
      ],
    );
  }

  /// Seção com título elegante e chips
  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16, top: 20),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF4169E1),
                      Color(0xFF6A5ACD),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        ...children,
      ],
    );
  }

  /// Verifica se tem propósito
  bool _hasPurpose() {
    final purpose = profile.profileData['purpose'] as String?;
    return purpose != null && purpose.isNotEmpty;
  }

  /// Verifica se tem valores espirituais
  bool _hasSpiritualValues() {
    return profile.hasCertification ||
        profile.isDeusEPaiMember ||
        profile.virginityStatus != null;
  }

  /// Verifica se tem informações pessoais
  bool _hasPersonalInfo() {
    return profile.education != null ||
        profile.languages.isNotEmpty ||
        profile.children != null ||
        profile.drinking != null ||
        profile.smoking != null;
  }

  /// Constrói seção de propósito com design premium
  List<Widget> _buildPurpose() {
    final purpose = profile.profileData['purpose'] as String?;
    if (purpose == null || purpose.isEmpty) return [];

    return [
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF4169E1).withOpacity(0.12),
              const Color(0xFF6A5ACD).withOpacity(0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF4169E1).withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4169E1).withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {}, // Pode adicionar ação futura
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF4169E1),
                          Color(0xFF6A5ACD),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4169E1).withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Busco',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4169E1),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          purpose,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF4169E1),
                          Color(0xFF6A5ACD),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4169E1).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ];
  }

  /// Constrói chips de valores espirituais
  List<Widget> _buildSpiritualValues() {
    final chips = <Widget>[];

    // Certificação Espiritual
    if (profile.hasCertification) {
      chips.add(_buildValueChip(
        icon: Icons.verified,
        label: 'Certificação Espiritual',
        sublabel: 'Perfil verificado pela comunidade',
        color: Colors.amber,
        isHighlighted: true,
      ));
    }

    // Virgindade
    if (profile.virginityStatus != null) {
      chips.add(_buildValueChip(
        icon: Icons.favorite_border,
        label: 'Virgindade',
        sublabel: profile.virginityStatus!,
        color: Colors.pink,
        isHighlighted: true,
      ));
    }

    return chips;
  }

  /// Constrói chips de informações pessoais
  List<Widget> _buildPersonalInfo() {
    final chips = <Widget>[];

    // Educação
    if (profile.education != null) {
      chips.add(_buildValueChip(
        icon: Icons.school,
        label: 'Educação',
        sublabel: profile.education!,
        color: Colors.blue,
        isHighlighted: true,
      ));
    }

    // Idiomas
    if (profile.languages.isNotEmpty) {
      chips.add(_buildValueChip(
        icon: Icons.language,
        label: 'Idiomas',
        sublabel: profile.languages.join(', '),
        color: Colors.teal,
        isHighlighted: true,
      ));
    }

    // Filhos
    if (profile.children != null) {
      chips.add(_buildValueChip(
        icon: Icons.child_care,
        label: 'Filhos',
        sublabel: profile.children!,
        color: Colors.orange,
        isHighlighted: true,
      ));
    }

    // Bebidas
    if (profile.drinking != null) {
      chips.add(_buildValueChip(
        icon: Icons.local_bar,
        label: 'Bebidas',
        sublabel: profile.drinking!,
        color: Colors.purple,
        isHighlighted: true,
      ));
    }

    // Fumo
    if (profile.smoking != null) {
      chips.add(_buildValueChip(
        icon: Icons.smoking_rooms,
        label: 'Fumo',
        sublabel: profile.smoking!,
        color: Colors.brown,
        isHighlighted: true,
      ));
    }

    return chips;
  }

  /// Chip individual de valor com design elegante
  Widget _buildValueChip({
    required IconData icon,
    required String label,
    required String sublabel,
    required Color color,
    bool isHighlighted = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: isHighlighted
            ? LinearGradient(
                colors: [
                  color.withOpacity(0.15),
                  color.withOpacity(0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isHighlighted ? null : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted ? color.withOpacity(0.3) : Colors.grey[200]!,
          width: isHighlighted ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isHighlighted
                ? color.withOpacity(0.15)
                : Colors.black.withOpacity(0.03),
            blurRadius: isHighlighted ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {}, // Pode adicionar ação futura
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Ícone com gradiente
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: isHighlighted
                        ? LinearGradient(
                            colors: [
                              color.withOpacity(0.8),
                              color,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : LinearGradient(
                            colors: [
                              Colors.grey[100]!,
                              Colors.grey[50]!,
                            ],
                          ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isHighlighted
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: isHighlighted ? Colors.white : Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                // Textos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isHighlighted ? color : const Color(0xFF2C3E50),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sublabel,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
