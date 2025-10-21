import 'package:flutter/material.dart';

/// Seção que exibe informações de localização do perfil
/// 
/// Exibe cidade, estado e país de forma formatada
class LocationInfoSection extends StatelessWidget {
  final String? city;
  final String? state;
  final String? fullLocation;
  final String? country;

  const LocationInfoSection({
    Key? key,
    this.city,
    this.state,
    this.fullLocation,
    this.country,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determinar qual texto exibir
    final locationText = _getLocationText();
    
    // Se não houver localização, não renderizar
    if (locationText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
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
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: Colors.teal[600],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    locationText,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF333333),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Determina qual texto de localização exibir
  String _getLocationText() {
    // Prioridade: fullLocation > city + state + country > city + state > city
    if (fullLocation?.isNotEmpty == true) {
      return fullLocation!;
    }
    
    final parts = <String>[];
    
    if (city?.isNotEmpty == true) {
      parts.add(city!);
    }
    
    if (state?.isNotEmpty == true) {
      parts.add(state!);
    }
    
    if (country?.isNotEmpty == true && country != 'Brasil') {
      // Só adicionar país se não for Brasil (padrão)
      parts.add(country!);
    }
    
    return parts.join(' - ');
  }
}
