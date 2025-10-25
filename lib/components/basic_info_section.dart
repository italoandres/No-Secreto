import 'package:flutter/material.dart';
import '../theme.dart';

/// Seção de informações básicas com localização, idade e movimento "Deus é Pai"
class BasicInfoSection extends StatelessWidget {
  final String? city;
  final String? fullLocation;
  final int? age;
  final bool? isDeusEPaiMember;

  const BasicInfoSection({
    Key? key,
    this.city,
    this.fullLocation,
    this.age,
    this.isDeusEPaiMember,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // Location and Age Row
          Row(
            children: [
              // Location Info
              if (_hasLocationInfo()) ...[
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.location_on,
                    iconColor: Colors.red[400]!,
                    title: 'Localização',
                    value: _getDisplayLocation(),
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // Age Info
              if (age != null) ...[
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.cake,
                    iconColor: Colors.orange[400]!,
                    title: 'Idade',
                    value: '$age anos',
                  ),
                ),
              ],
            ],
          ),

          // Deus é Pai Movement Badge
          if (isDeusEPaiMember == true) ...[
            const SizedBox(height: 16),
            _buildMovementBadge(),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
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
          Row(
            children: [
              Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Movimento Deus é Pai',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  bool _hasLocationInfo() {
    return fullLocation?.isNotEmpty == true || city?.isNotEmpty == true;
  }

  String _getDisplayLocation() {
    return fullLocation ?? city ?? 'Não informado';
  }
}
