import 'package:flutter/material.dart';
import '../models/additional_location_model.dart';
import 'primary_location_card.dart';
import 'additional_location_card.dart';
import 'location_selector_dialog.dart';

/// Seção completa de filtros de localização
class LocationFilterSection extends StatelessWidget {
  final String? primaryCity;
  final String? primaryState;
  final List<AdditionalLocation> additionalLocations;
  final VoidCallback onAddLocation;
  final Function(int index) onRemoveLocation;
  final Function(int index) onEditLocation;
  final bool canAddMore;

  const LocationFilterSection({
    Key? key,
    this.primaryCity,
    this.primaryState,
    required this.additionalLocations,
    required this.onAddLocation,
    required this.onRemoveLocation,
    required this.onEditLocation,
    required this.canAddMore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título da seção
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7B68EE).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Color(0xFF7B68EE),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Localização de Encontros',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Localização Principal
          if (primaryCity != null && primaryState != null)
            PrimaryLocationCard(
              city: primaryCity!,
              state: primaryState!,
            )
          else
            _buildNoLocationCard(context),

          const SizedBox(height: 20),

          // Título de Localizações Adicionais
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.add_location,
                    color: Color(0xFF4169E1),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Localizações Adicionais',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
              // Contador
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4169E1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF4169E1).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  '${additionalLocations.length} de 2',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4169E1),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Lista de Localizações Adicionais
          if (additionalLocations.isEmpty)
            _buildEmptyLocationsCard()
          else
            ...additionalLocations.asMap().entries.map((entry) {
              return AdditionalLocationCard(
                key: ValueKey(entry.value.displayText),
                location: entry.value,
                index: entry.key,
                onEdit: () => onEditLocation(entry.key),
                onRemove: () => onRemoveLocation(entry.key),
              );
            }).toList(),

          const SizedBox(height: 12),

          // Botão Adicionar Localização
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: canAddMore ? onAddLocation : null,
              icon: Icon(
                Icons.add_circle_outline,
                size: 20,
                color: canAddMore ? const Color(0xFF7B68EE) : Colors.grey[400],
              ),
              label: Text(
                canAddMore
                    ? 'Adicionar Localização'
                    : 'Limite de 2 localizações atingido',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color:
                      canAddMore ? const Color(0xFF7B68EE) : Colors.grey[400],
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(
                  color:
                      canAddMore ? const Color(0xFF7B68EE) : Colors.grey[300]!,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: canAddMore
                    ? const Color(0xFF7B68EE).withOpacity(0.05)
                    : Colors.grey[50],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Card quando não há localização principal
  Widget _buildNoLocationCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange[200]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.location_off,
            color: Colors.orange[700],
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Localização não disponível',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.orange[900],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Complete seu perfil para adicionar localização',
            style: TextStyle(
              fontSize: 13,
              color: Colors.orange[800],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Card quando não há localizações adicionais
  Widget _buildEmptyLocationsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.add_location_alt_outlined,
            color: Colors.grey[400],
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Nenhuma localização adicional',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Adicione até 2 localizações de interesse',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
