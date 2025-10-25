import 'package:flutter/material.dart';

/// Dialog para selecionar cidade e estado
class LocationSelectorDialog extends StatefulWidget {
  final Function(String city, String state) onLocationSelected;

  const LocationSelectorDialog({
    Key? key,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  State<LocationSelectorDialog> createState() => _LocationSelectorDialogState();
}

class _LocationSelectorDialogState extends State<LocationSelectorDialog> {
  String? selectedState;
  String? selectedCity;

  // Estados brasileiros
  final List<String> estados = [
    'AC',
    'AL',
    'AP',
    'AM',
    'BA',
    'CE',
    'DF',
    'ES',
    'GO',
    'MA',
    'MT',
    'MS',
    'MG',
    'PA',
    'PB',
    'PR',
    'PE',
    'PI',
    'RJ',
    'RN',
    'RS',
    'RO',
    'RR',
    'SC',
    'SP',
    'SE',
    'TO'
  ];

  // Principais cidades por estado (simplificado)
  final Map<String, List<String>> cidadesPorEstado = {
    'SP': [
      'São Paulo',
      'Campinas',
      'Santos',
      'Ribeirão Preto',
      'Sorocaba',
      'São José dos Campos',
      'Bauru'
    ],
    'RJ': [
      'Rio de Janeiro',
      'Niterói',
      'Duque de Caxias',
      'Nova Iguaçu',
      'Petrópolis'
    ],
    'MG': ['Belo Horizonte', 'Uberlândia', 'Contagem', 'Juiz de Fora', 'Betim'],
    'BA': [
      'Salvador',
      'Feira de Santana',
      'Vitória da Conquista',
      'Camaçari',
      'Itabuna'
    ],
    'PR': ['Curitiba', 'Londrina', 'Maringá', 'Ponta Grossa', 'Cascavel'],
    'RS': ['Porto Alegre', 'Caxias do Sul', 'Pelotas', 'Canoas', 'Santa Maria'],
    'PE': [
      'Recife',
      'Jaboatão dos Guararapes',
      'Olinda',
      'Caruaru',
      'Petrolina'
    ],
    'CE': ['Fortaleza', 'Caucaia', 'Juazeiro do Norte', 'Maracanaú', 'Sobral'],
    'PA': ['Belém', 'Ananindeua', 'Santarém', 'Marabá', 'Castanhal'],
    'SC': ['Florianópolis', 'Joinville', 'Blumenau', 'São José', 'Chapecó'],
    'GO': [
      'Goiânia',
      'Aparecida de Goiânia',
      'Anápolis',
      'Rio Verde',
      'Luziânia'
    ],
    'MA': ['São Luís', 'Imperatriz', 'São José de Ribamar', 'Timon', 'Caxias'],
    'ES': ['Vitória', 'Vila Velha', 'Serra', 'Cariacica', 'Linhares'],
    'PB': ['João Pessoa', 'Campina Grande', 'Santa Rita', 'Patos', 'Bayeux'],
    'RN': [
      'Natal',
      'Mossoró',
      'Parnamirim',
      'São Gonçalo do Amarante',
      'Macaíba'
    ],
    'AL': [
      'Maceió',
      'Arapiraca',
      'Rio Largo',
      'Palmeira dos Índios',
      'União dos Palmares'
    ],
    'MT': [
      'Cuiabá',
      'Várzea Grande',
      'Rondonópolis',
      'Sinop',
      'Tangará da Serra'
    ],
    'MS': ['Campo Grande', 'Dourados', 'Três Lagoas', 'Corumbá', 'Ponta Porã'],
    'PI': ['Teresina', 'Parnaíba', 'Picos', 'Piripiri', 'Floriano'],
    'DF': ['Brasília', 'Taguatinga', 'Ceilândia', 'Samambaia', 'Planaltina'],
    'SE': [
      'Aracaju',
      'Nossa Senhora do Socorro',
      'Lagarto',
      'Itabaiana',
      'Estância'
    ],
    'RO': ['Porto Velho', 'Ji-Paraná', 'Ariquemes', 'Cacoal', 'Vilhena'],
    'AC': [
      'Rio Branco',
      'Cruzeiro do Sul',
      'Sena Madureira',
      'Tarauacá',
      'Feijó'
    ],
    'AM': ['Manaus', 'Parintins', 'Itacoatiara', 'Manacapuru', 'Coari'],
    'RR': ['Boa Vista', 'Rorainópolis', 'Caracaraí', 'Alto Alegre', 'Mucajaí'],
    'AP': ['Macapá', 'Santana', 'Laranjal do Jari', 'Oiapoque', 'Mazagão'],
    'TO': [
      'Palmas',
      'Araguaína',
      'Gurupi',
      'Porto Nacional',
      'Paraíso do Tocantins'
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B68EE).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.add_location_alt,
                    color: Color(0xFF7B68EE),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Adicionar Localização',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Dropdown de Estado
            const Text(
              'Estado',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedState,
                  isExpanded: true,
                  hint: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Selecione o estado'),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  borderRadius: BorderRadius.circular(12),
                  items: estados.map((estado) {
                    return DropdownMenuItem(
                      value: estado,
                      child: Text(estado),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedState = value;
                      selectedCity = null; // Reset cidade ao mudar estado
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Dropdown de Cidade
            const Text(
              'Cidade',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: selectedState == null
                      ? Colors.grey[200]!
                      : Colors.grey[300]!,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedCity,
                  isExpanded: true,
                  hint: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      selectedState == null
                          ? 'Selecione o estado primeiro'
                          : 'Selecione a cidade',
                      style: TextStyle(
                        color: selectedState == null
                            ? Colors.grey[400]
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  borderRadius: BorderRadius.circular(12),
                  items: selectedState != null
                      ? (cidadesPorEstado[selectedState!] ?? []).map((cidade) {
                          return DropdownMenuItem(
                            value: cidade,
                            child: Text(cidade),
                          );
                        }).toList()
                      : [],
                  onChanged: selectedState != null
                      ? (value) {
                          setState(() {
                            selectedCity = value;
                          });
                        }
                      : null,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Mensagem informativa
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4169E1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF4169E1).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFF4169E1),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Você pode editar esta localização uma vez por mês.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Botões
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: selectedCity != null && selectedState != null
                      ? () {
                          widget.onLocationSelected(
                              selectedCity!, selectedState!);
                          Navigator.of(context).pop();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B68EE),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: const Text(
                    'Adicionar',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
