import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/spiritual_profile_model.dart';
import '../repositories/spiritual_profile_repository.dart';
import '../utils/gender_colors.dart';
import '../utils/languages_data.dart';
import '../utils/world_locations_data.dart';
import '../services/location_data_provider.dart';
import '../services/location_error_handler.dart';
import '../interfaces/location_data_interface.dart';
import '../components/height_selector_component.dart';
import '../components/occupation_selector_component.dart';
import '../components/education_selector_component.dart';
import '../components/university_course_selector_component.dart';
import '../components/university_course_complete_selector_component.dart';
import '../components/hobbies_selector_component.dart';
import '../utils/university_courses_data.dart';

class ProfileIdentityTaskView extends StatefulWidget {
  final SpiritualProfileModel profile;
  final Function(String) onCompleted;

  const ProfileIdentityTaskView({
    super.key,
    required this.profile,
    required this.onCompleted,
  });

  @override
  State<ProfileIdentityTaskView> createState() =>
      _ProfileIdentityTaskViewState();
}

class _ProfileIdentityTaskViewState extends State<ProfileIdentityTaskView> {
  final _ageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Localização
  String? _selectedCountry;
  String? _selectedCountryCode;
  String? _selectedState;
  String? _selectedCity;
  final TextEditingController _cityController = TextEditingController();

  // Dados dinâmicos
  List<String> _availableStates = [];
  List<String> _availableCities = [];
  LocationDataInterface? _locationData;
  String? _errorMessage;

  // Idiomas
  List<String> _selectedLanguages = [];

  // Altura
  String? _selectedHeight;

  // Profissão
  String? _selectedOccupation;

  // Escolaridade
  String? _selectedEducation;

  // Curso Superior
  String? _selectedUniversityCourse;
  String? _selectedCourseStatus;
  String? _selectedUniversity;

  // Status de Fumante
  String? _selectedSmokingStatus;

  // Status de Bebida Alcólica
  String? _selectedDrinkingStatus;

  // Status de Tatuagens
  String? _selectedTattoosStatus;

  // Hobbies e Interesses
  List<String> _selectedHobbies = [];

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
    _cityController.text = widget.profile.city ?? '';
    _selectedLanguages = widget.profile.languages ?? [];
    _selectedHeight = widget.profile.height;
    _selectedOccupation = widget.profile.occupation;
    _selectedEducation = widget.profile.education;
    _selectedUniversityCourse = widget.profile.universityCourse;
    _selectedCourseStatus = widget.profile.courseStatus;
    _selectedUniversity = widget.profile.university;
    _selectedSmokingStatus = widget.profile.smokingStatus;
    _selectedDrinkingStatus = widget.profile.drinkingStatus;
    _selectedTattoosStatus = widget.profile.tattoosStatus;
    _selectedHobbies = widget.profile.hobbies ?? [];

    // Carregar dados estruturados se país já selecionado
    if (_selectedCountry != null) {
      _updateStatesForCountry(_selectedCountry!);
      if (_selectedState != null) {
        _updateCitiesForState(_selectedState!);
      }
    }
  }

  void _updateStatesForCountry(String country) {
    setState(() {
      _selectedState = null;
      _selectedCity = null;
      _availableStates = [];
      _availableCities = [];
      _locationData = null;
      _errorMessage = null;

      // Obter código do país
      _selectedCountryCode = WorldLocationsData.getCountryCode(country);

      if (_selectedCountryCode != null) {
        try {
          // Verificar se país tem dados estruturados
          if (LocationDataProvider.hasStructuredData(_selectedCountryCode!)) {
            _locationData =
                LocationDataProvider.getLocationData(_selectedCountryCode!);
            if (_locationData != null) {
              _availableStates = _locationData!.getStates();
            }
          }
        } catch (error) {
          LocationErrorHandler.handleDataLoadError(
              _selectedCountryCode!, error);
          _errorMessage = LocationErrorHandler.getFallbackMessage(country);
        }
      }
    });
  }

  void _updateCitiesForState(String state) {
    setState(() {
      _selectedCity = null;
      _availableCities = [];

      if (_locationData != null) {
        try {
          _availableCities = _locationData!.getCitiesForState(state);
        } catch (error) {
          LocationErrorHandler.handleDataLoadError(
              _selectedCountryCode!, error);
          _errorMessage = 'Erro ao carregar cidades para $state';
        }
      }
    });
  }

  String _getStateLabel() {
    return _locationData?.stateLabel ?? 'Estado';
  }

  String _buildFullLocation() {
    if (_locationData != null &&
        _selectedState != null &&
        _selectedCity != null) {
      return _locationData!.formatLocation(_selectedCity!, _selectedState!);
    } else if (_selectedCity != null && _selectedCountry != null) {
      return '$_selectedCity, $_selectedCountry';
    } else if (_cityController.text.isNotEmpty && _selectedCountry != null) {
      return '${_cityController.text}, $_selectedCountry';
    }
    return '';
  }

  Color get _primaryColor => const Color(0xFF39b9ff); // Cor padrão azul

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          '🏠 Identidade Espiritual',
          style: TextStyle(
            fontWeight: FontWeight.bold,
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
              const SizedBox(height: 24),
              _buildHeightSection(),
              const SizedBox(height: 24),
              _buildOccupationSection(),
              const SizedBox(height: 24),
              _buildEducationSection(),

              // Mostrar curso superior apenas se necessário
              if (UniversityCoursesData.requiresUniversityCourse(
                  _selectedEducation)) ...[
                const SizedBox(height: 24),
                _buildUniversityCourseSection(),
              ],

              const SizedBox(height: 24),
              _buildSmokingSection(),

              const SizedBox(height: 24),
              _buildDrinkingSection(),

              const SizedBox(height: 24),
              _buildTattoosSection(),

              const SizedBox(height: 24),
              _buildHobbiesSection(),

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
            _primaryColor.withOpacity(0.1),
            _primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _primaryColor.withOpacity(0.3),
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
                style: TextStyle(
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
            style: TextStyle(
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
              const Text(
                'Localização',
                style: TextStyle(
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
            items: WorldLocationsData.getCountryNames().map((country) {
              return DropdownMenuItem(
                value: country,
                child: Text(country),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                _updateStatesForCountry(value);
                setState(() {
                  _selectedCountry = value;
                });
              }
            },
            validator: (value) => value == null ? 'Selecione um país' : null,
          ),

          const SizedBox(height: 16),

          // Estado/Província/Distrito (para países com dados estruturados)
          if (_locationData != null) ...[
            DropdownButtonFormField<String>(
              value: _selectedState,
              decoration: InputDecoration(
                labelText: '${_getStateLabel()} *',
                prefixIcon: const Icon(Icons.map),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _primaryColor, width: 2),
                ),
                errorText: _errorMessage,
              ),
              items: _availableStates.map((state) {
                return DropdownMenuItem(
                  value: state,
                  child: Text(state),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  _updateCitiesForState(value);
                  setState(() {
                    _selectedState = value;
                  });
                }
              },
              validator: (value) => value == null
                  ? 'Selecione ${_getStateLabel().toLowerCase()}'
                  : null,
            ),
            const SizedBox(height: 16),
          ],

          // Cidade
          if (_locationData != null && _selectedState != null)
            // Dropdown de cidades para países com dados estruturados
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
              items: _availableCities.map((city) {
                return DropdownMenuItem(
                  value: city,
                  child: Text(city),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCity = value;
                });
              },
              validator: (value) =>
                  value == null ? 'Selecione uma cidade' : null,
            )
          else if (_selectedCountry != null && _locationData == null)
            // Campo de texto para países sem dados estruturados
            TextFormField(
              controller: _cityController,
              decoration: InputDecoration(
                labelText: 'Cidade *',
                hintText: 'Digite sua cidade',
                prefixIcon: const Icon(Icons.location_city),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _primaryColor, width: 2),
                ),
                helperText: _errorMessage ?? 'Digite o nome da sua cidade',
                helperStyle: TextStyle(
                  color:
                      _errorMessage != null ? Colors.orange : Colors.grey[600],
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _selectedCity = value.trim();
                });
              },
              validator: (value) {
                if (value?.trim().isEmpty == true) {
                  return 'Digite sua cidade';
                }
                return null;
              },
            ),
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
              const Text(
                'Idiomas Falados',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Selecione os idiomas que você fala',
            style: TextStyle(
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
                selectedColor: _primaryColor.withOpacity(0.1),
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
              const Text(
                'Idade',
                style: TextStyle(
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

  Widget _buildHeightSection() {
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
              Icon(Icons.height, color: _primaryColor),
              const SizedBox(width: 8),
              const Text(
                'Altura',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Selecione sua altura ou escolha não informar',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          HeightSelectorComponent(
            selectedHeight: _selectedHeight,
            onHeightChanged: (height) {
              setState(() {
                _selectedHeight = height;
              });
            },
            primaryColor: _primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildOccupationSection() {
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
              Icon(Icons.work, color: _primaryColor),
              const SizedBox(width: 8),
              const Text(
                'Profissão/Emprego',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Digite para buscar sua profissão atual',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          OccupationSelectorComponent(
            selectedOccupation: _selectedOccupation,
            onOccupationChanged: (occupation) {
              setState(() {
                _selectedOccupation = occupation;
              });
            },
            primaryColor: _primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildEducationSection() {
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
              Icon(Icons.school, color: _primaryColor),
              const SizedBox(width: 8),
              const Text(
                'Nível Educacional',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Selecione seu nível de escolaridade',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          EducationSelectorComponent(
            selectedEducation: _selectedEducation,
            onEducationChanged: (education) {
              setState(() {
                _selectedEducation = education;
                // Limpar dados de curso superior se não for mais necessário
                if (!UniversityCoursesData.requiresUniversityCourse(
                    education)) {
                  _selectedUniversityCourse = null;
                  _selectedCourseStatus = null;
                  _selectedUniversity = null;
                }
              });
            },
            primaryColor: _primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildUniversityCourseSection() {
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
              Icon(Icons.menu_book, color: _primaryColor),
              const SizedBox(width: 8),
              const Text(
                'Formação Superior',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Campo de instituição
          UniversityCourseSelectorComponent(
            selectedCourse: null,
            selectedUniversity: _selectedUniversity,
            onCourseChanged: (_) {},
            onUniversityChanged: (university) {
              setState(() {
                _selectedUniversity = university;
              });
            },
            primaryColor: _primaryColor,
          ),

          const SizedBox(height: 16),
          Text(
            'Qual curso você fez/está fazendo?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          UniversityCourseCompleteSelectorComponent(
            selectedCourse: _selectedUniversityCourse,
            onCourseChanged: (course) {
              setState(() {
                _selectedUniversityCourse = course;
              });
            },
            primaryColor: _primaryColor,
            hintText:
                'Digite para buscar seu curso (ex: Direito, Psicologia...)',
          ),

          const SizedBox(height: 16),
          Text(
            'Status do curso:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCourseStatus = 'Se formando';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _selectedCourseStatus == 'Se formando'
                          ? _primaryColor
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedCourseStatus == 'Se formando'
                            ? _primaryColor
                            : Colors.grey[300]!,
                        width: _selectedCourseStatus == 'Se formando' ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.school_outlined,
                          color: _selectedCourseStatus == 'Se formando'
                              ? Colors.white
                              : Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Se formando',
                          style: TextStyle(
                            color: _selectedCourseStatus == 'Se formando'
                                ? Colors.white
                                : Colors.grey[700],
                            fontWeight: _selectedCourseStatus == 'Se formando'
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCourseStatus = 'Formado(a)';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _selectedCourseStatus == 'Formado(a)'
                          ? _primaryColor
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedCourseStatus == 'Formado(a)'
                            ? _primaryColor
                            : Colors.grey[300]!,
                        width: _selectedCourseStatus == 'Formado(a)' ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.school,
                          color: _selectedCourseStatus == 'Formado(a)'
                              ? Colors.white
                              : Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Formado(a)',
                          style: TextStyle(
                            color: _selectedCourseStatus == 'Formado(a)'
                                ? Colors.white
                                : Colors.grey[700],
                            fontWeight: _selectedCourseStatus == 'Formado(a)'
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmokingSection() {
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
              Icon(Icons.smoking_rooms, color: _primaryColor),
              const SizedBox(width: 8),
              const Text(
                'Você fuma?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Selecione uma opção',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),

          // Opções de status de fumante
          Column(
            children: [
              _buildSmokingOption('sim_frequentemente', 'Sim, frequentemente',
                  Icons.smoking_rooms),
              const SizedBox(height: 12),
              _buildSmokingOption('sim_as_vezes', 'Sim, às vezes',
                  Icons.smoking_rooms_outlined),
              const SizedBox(height: 12),
              _buildSmokingOption('nao', 'Não', Icons.smoke_free),
              const SizedBox(height: 12),
              _buildSmokingOption('prefiro_nao_informar',
                  'Prefiro não informar', Icons.help_outline),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmokingOption(String value, String label, IconData icon) {
    final isSelected = _selectedSmokingStatus == value;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedSmokingStatus = value;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? _primaryColor : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? _primaryColor : Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: _primaryColor,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrinkingSection() {
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
              Icon(Icons.local_bar, color: _primaryColor),
              const SizedBox(width: 8),
              const Text(
                'Você consome bebida alcólica?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Selecione uma opção',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),

          // Opções de status de bebida
          Column(
            children: [
              _buildDrinkingOption(
                  'sim_frequentemente', 'Sim, frequentemente', Icons.local_bar),
              const SizedBox(height: 12),
              _buildDrinkingOption(
                  'sim_as_vezes', 'Sim, às vezes', Icons.local_bar_outlined),
              const SizedBox(height: 12),
              _buildDrinkingOption('nao', 'Não', Icons.block),
              const SizedBox(height: 12),
              _buildDrinkingOption('prefiro_nao_informar',
                  'Prefiro não informar', Icons.help_outline),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrinkingOption(String value, String label, IconData icon) {
    final isSelected = _selectedDrinkingStatus == value;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedDrinkingStatus = value;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? _primaryColor : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? _primaryColor : Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: _primaryColor,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTattoosSection() {
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
              Icon(Icons.brush, color: _primaryColor),
              const SizedBox(width: 8),
              const Text(
                'Você tem tatuagens?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Selecione uma opção',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),

          // Opções de status de tatuagens
          Column(
            children: [
              _buildTattoosOption('nao', 'Não', Icons.block),
              const SizedBox(height: 12),
              _buildTattoosOption('sim_poucas', 'Sim, poucas', Icons.brush_outlined),
              const SizedBox(height: 12),
              _buildTattoosOption('mais_de_5', 'Mais de 5', Icons.brush),
              const SizedBox(height: 12),
              _buildTattoosOption('mais_de_10', 'Mais de 10', Icons.palette),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTattoosOption(String value, String label, IconData icon) {
    final isSelected = _selectedTattoosStatus == value;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedTattoosStatus = value;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? _primaryColor : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? _primaryColor : Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: _primaryColor,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHobbiesSection() {
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
              Icon(Icons.interests, color: _primaryColor),
              const SizedBox(width: 8),
              const Text(
                'Seus hobbies e interesses',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione pelo menos 1 para encontrar matches nas coisas que você curte',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          HobbiesSelectorComponent(
            selectedHobbies: _selectedHobbies,
            onHobbiesChanged: (hobbies) {
              setState(() {
                _selectedHobbies = hobbies;
              });
            },
            primaryColor: _primaryColor,
            minSelection: 1,
            maxSelection: 10,
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
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Salvando...'),
                ],
              )
            : const Text(
                'Salvar Identidade',
                style: TextStyle(
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

    // Validar hobbies (mínimo 1)
    if (_selectedHobbies.isEmpty) {
      Get.snackbar(
        'Atenção',
        'Selecione pelo menos 1 hobby ou interesse',
        backgroundColor: Colors.orange[100],
        colorText: Colors.orange[800],
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Validar campos de curso superior (se aplicável)
    if (UniversityCoursesData.requiresUniversityCourse(_selectedEducation)) {
      if (_selectedUniversity == null || _selectedUniversity!.isEmpty) {
        Get.snackbar(
          'Atenção',
          'Informe a instituição de ensino',
          backgroundColor: Colors.orange[100],
          colorText: Colors.orange[800],
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      if (_selectedUniversityCourse == null ||
          _selectedUniversityCourse!.isEmpty) {
        Get.snackbar(
          'Atenção',
          'Selecione o curso que você fez/está fazendo',
          backgroundColor: Colors.orange[100],
          colorText: Colors.orange[800],
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      if (_selectedCourseStatus == null || _selectedCourseStatus!.isEmpty) {
        Get.snackbar(
          'Atenção',
          'Selecione o status do curso (Se formando ou Formado)',
          backgroundColor: Colors.orange[100],
          colorText: Colors.orange[800],
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Determinar cidade final
      final finalCity = _selectedCity ?? _cityController.text.trim();

      // Gerar localização formatada usando o novo sistema
      final fullLocation = _buildFullLocation();

      final updates = {
        'country': _selectedCountry,
        'countryCode': _selectedCountryCode,
        'state': _selectedState,
        'city': finalCity,
        'fullLocation': fullLocation,
        'hasStructuredData': _locationData != null,
        'languages': _selectedLanguages,
        'age': int.parse(_ageController.text.trim()),
        'height': _selectedHeight,
        'occupation': _selectedOccupation,
        'education': _selectedEducation,
        'universityCourse': _selectedUniversityCourse,
        'courseStatus': _selectedCourseStatus,
        'university': _selectedUniversity,
        'smokingStatus': _selectedSmokingStatus,
        'drinkingStatus': _selectedDrinkingStatus,
        'tattoosStatus': _selectedTattoosStatus,
        'hobbies': _selectedHobbies.isNotEmpty ? _selectedHobbies : null,
      };

      await SpiritualProfileRepository.updateProfile(
          widget.profile.id!, updates);

      // Mark task as completed
      await SpiritualProfileRepository.updateTaskCompletion(
        widget.profile.id!,
        'identity',
        true,
      );

      widget.onCompleted('identity');
      Get.back();

      // Mostrar feedback da localização formatada
      if (fullLocation.isNotEmpty) {
        Get.snackbar(
          'Sucesso!',
          'Localização salva: $fullLocation',
          backgroundColor: Colors.green[100],
          colorText: Colors.green[800],
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      } else {
        Get.snackbar(
          'Sucesso!',
          'Sua identidade foi salva com sucesso.',
          backgroundColor: Colors.green[100],
          colorText: Colors.green[800],
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
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
    _cityController.dispose();
    super.dispose();
  }
}
