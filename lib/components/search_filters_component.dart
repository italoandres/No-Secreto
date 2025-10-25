import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/explore_profiles_controller.dart';

/// Componente de filtros para busca de perfis
class SearchFiltersComponent extends StatelessWidget {
  final ExploreProfilesController controller;

  const SearchFiltersComponent({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Filtros de Busca',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    controller.clearFilters();
                    Get.back();
                  },
                  child: const Text('Limpar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    controller.applyFilters();
                    Get.back();
                  },
                  child: const Text('Aplicar'),
                ),
              ],
            ),
          ),

          // Conteúdo dos filtros
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filtro de idade
                  _buildAgeFilter(),

                  const SizedBox(height: 24),

                  // Filtro de localização
                  _buildLocationFilter(),

                  const SizedBox(height: 24),

                  // Filtro de interesses
                  _buildInterestsFilter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Faixa Etária',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Obx(() => RangeSlider(
              values: RangeValues(
                controller.minAge.value.toDouble(),
                controller.maxAge.value.toDouble(),
              ),
              min: 18,
              max: 65,
              divisions: 47,
              labels: RangeLabels(
                '${controller.minAge.value}',
                '${controller.maxAge.value}',
              ),
              onChanged: (RangeValues values) {
                controller.minAge.value = values.start.round();
                controller.maxAge.value = values.end.round();
              },
            )),
        Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mín: ${controller.minAge.value} anos',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Máx: ${controller.maxAge.value} anos',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            )),
      ],
    );
  }

  Widget _buildLocationFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Localização',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        // Estado
        Obx(() => DropdownButtonFormField<String>(
              value: controller.selectedState.value.isEmpty
                  ? null
                  : controller.selectedState.value,
              decoration: const InputDecoration(
                labelText: 'Estado',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Todos os estados'),
                ),
                ...controller.availableStates
                    .map((state) => DropdownMenuItem<String>(
                          value: state,
                          child: Text(state),
                        )),
              ],
              onChanged: (value) {
                controller.selectedState.value = value ?? '';
              },
            )),

        const SizedBox(height: 12),

        // Cidade
        TextField(
          onChanged: (value) => controller.selectedCity.value = value,
          decoration: const InputDecoration(
            labelText: 'Cidade',
            hintText: 'Digite o nome da cidade',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_city),
          ),
        ),
      ],
    );
  }

  Widget _buildInterestsFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Interesses',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Obx(() => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: controller.availableInterests.map((interest) {
                final isSelected =
                    controller.selectedInterests.contains(interest);
                return FilterChip(
                  label: Text(interest),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      controller.addInterest(interest);
                    } else {
                      controller.removeInterest(interest);
                    }
                  },
                  selectedColor: Colors.blue[100],
                  checkmarkColor: Colors.blue[600],
                );
              }).toList(),
            )),
        const SizedBox(height: 8),
        Obx(() => controller.selectedInterests.isNotEmpty
            ? Text(
                '${controller.selectedInterests.length} interesse(s) selecionado(s)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              )
            : const SizedBox()),
      ],
    );
  }
}
