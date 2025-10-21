import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/spiritual_profile_model.dart';
import '../repositories/spiritual_profile_repository.dart';
import '../utils/gender_colors.dart';
import '../utils/languages_data.dart';
import '../utils/brazil_locations_data.dart';
import '../utils/world_locations_data.dart';

class ProfileIdentityTaskViewEnhanced extends StatefulWidget {
  final SpiritualProfileModel profile;
  final Function(String) onCompleted;

  const ProfileIdentityTaskViewEnhanced({
    super.key,
    required this.profile,
    required this.onCompleted,
  });

  @override
  State<ProfileIdentityTaskViewEnhanced> createState() => _ProfileIdentityTaskViewEnhancedState();
}

class _ProfileIdentityTaskViewEnhancedState extends State<ProfileIdentityTaskViewEnhanced> {
  final _ageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Localização
  String? _selectedCountry = 'Brasil';
  String? _selectedState;
  String? _selectedCity;

  // Idiomas
  List<String> _selectedLanguages = [];

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    _ageController.text = widget.profile.age?.toString() ?? '';
    _selectedCountry = widget.profile.country;
    _selectedState = widget.profile.state;
    _selectedCity = widget.profile.city;
    _selectedLanguages = widget.profile.languages ?? [];
  }

  Color get _primaryColor => GenderColors.getPrimaryColor(widget.profile.gender);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          '🏠 Identidade Espiritual',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGuidanceCard(),
              const SizedBox(height: 24),
              _buildLocationSection(),
              const SizedBox(height: 24),
              _buildLanguagesSection(),
              const SizedBox(height: 24),
              _buildAgeSection(),
              const SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuidanceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            GenderColors.getBackgroundColor(widget.profile.gender),
            GenderColors.getPrimaryColorWithOpacity(widget.profile.gender, 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: GenderColors.getBorderColor(widget.profile.gender),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: _primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Informações Básicas',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Essas informações ajudam outros usuários a conhecer sua localização, idiomas e faixa etária, facilitando conexões com pessoas próximas e compatíveis.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: _primaryColor),
              const SizedBox(width: 8),
              Text(
                'Localização',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // País
          DropdownButtonFormField<String>(
            value: _selectedCountry,
            decoration: InputDecoration(
              labelText: 'País *',
              prefixIcon: const Icon(Icons.public),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _primaryColor, width: 2),
              ),
            ),
            items: WorldLocationsData.countries.map((country) {
              return DropdownMenuItem(
                value: country['name'],
                child: Row(
                  children: [
                    Text(country['flag']!),
                    const SizedBox(width: 8),
                    Expanded(child: Text(country['name']!)),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCountry = value;
                // Reset state and city when country changes
                if (value != 'Brasil') {
                  _selectedState = null;
                  _selectedCity = null;
                }
              });
            },
            validator: (value) => value == null ? 'Selecione um país' : null,
          ),
          
          // Mostrar Estado e Cidade apenas se o país for Brasil
          if (_selectedCountry == 'Brasil') ...[
            const SizedBox(height: 16),
            
            // Estado
            DropdownButtonFormField<String>(
              value: _selectedState,
              decoration: InputDecoration(
                labelText: 'Estado *',
                prefixIcon: const Icon(Icons.map),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _primaryColor, width: 2),
                ),
              ),
              items: BrazilLocationsData.states.map((state) {
                return DropdownMenuItem(
                  value: state,
                  child: Text(state),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedState = value;
                  _selectedCity = null; // Reset city when state changes
                });
              },
              validator: (value) => value == null ? 'Selecione um estado' : null,
            ),
            
            const SizedBox(height: 16),
            
            // Cidade
            DropdownButtonFormField<String>(
              value: _selectedCity,
              decoration: InputDecoration(
                labelText: 'Cidade *',
                prefixIcon: const Icon(Icons.location_city),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _primaryColor, width: 2),
                ),
              ),
              items: _selectedState != null
                  ? BrazilLocationsData.getCitiesForState(_selectedState!).map((city) {
                      return DropdownMenuItem(
                        value: city,
                        child: Text(city),
                      );
                    }).toList()
                  : [],
              onChanged: _selectedState != null
                  ? (value) {
                      setState(() {
                        _selectedCity = value;
                      });
                    }
                  : null,
              validator: (value) => value == null ? 'Selecione uma cidade' : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLanguagesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.language, color: _primaryColor),
              const SizedBox(width: 8),
              Text(
                'Idiomas Falados',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Selecione os idiomas que você fala',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: LanguagesData.languages.map((lang) {
              final isSelected = _selectedLanguages.contains(lang['name']);
              return FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(lang['flag']!),
                    const SizedBox(width: 6),
                    Text(lang['name']!),
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedLanguages.add(lang['name']!);
                    } else {
                      _selectedLanguages.remove(lang['name']!);
                    }
                  });
                },
                selectedColor: GenderColors.getBackgroundColor(widget.profile.gender),
                checkmarkColor: _primaryColor,
                side: BorderSide(
                  color: isSelected ? _primaryColor : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAgeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cake, color: _primaryColor),
              const SizedBox(width: 8),
              Text(
                'Idade',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Sua idade *',
              hintText: 'Ex: 25',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _primaryColor, width: 2),
              ),
            ),
            validator: (value) {
              if (value?.isEmpty == true) {
                return 'Idade é obrigatória';
              }
              final age = int.tryParse(value!);
              if (age == null) {
                return 'Digite uma idade válida';
              }
              if (age < 18 || age > 100) {
                return 'Idade deve estar entre 18 e 100 anos';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveIdentity,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isSaving
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Salvando...',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ],
              )
            : Text(
                'Salvar Identidade',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _saveIdentity() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedLanguages.isEmpty) {
      Get.snackbar(
        'Atenção',
        'Selecione pelo menos um idioma',
        backgroundColor: Colors.orange[100],
        colorText: Colors.orange[800],
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Construir fullLocation baseado no país
      String fullLocation;
      if (_selectedCountry == 'Brasil' && _selectedCity != null && _selectedState != null) {
        fullLocation = '$_selectedCity - $_selectedState';
      } else {
        fullLocation = _selectedCountry ?? '';
      }
      
      final updates = {
        'country': _selectedCountry,
        'state': _selectedState,
        'city': _selectedCity,
        'fullLocation': fullLocation,
        'languages': _selectedLanguages,
        'age': int.parse(_ageController.text.trim()),
      };

      await SpiritualProfileRepository.updateProfile(widget.profile.id!, updates);
      
      // Mark task as completed
      await SpiritualProfileRepository.updateTaskCompletion(
        widget.profile.id!,
        'identity',
        true,
      );

      widget.onCompleted('identity');
      Get.back();

      Get.snackbar(
        'Sucesso!',
        'Sua identidade foi salva com sucesso.',
        backgroundColor: Colors.green[100],
        colorText: Colors.green[800],
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível salvar. Tente novamente.',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }
}
