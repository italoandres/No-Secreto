import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/spiritual_profile_model.dart';
import '../repositories/spiritual_profile_repository.dart';
import '../components/modern_biography_card.dart';
import '../components/modern_text_field.dart';
import '../components/privacy_control_field.dart';

class ProfileBiographyTaskView extends StatefulWidget {
  final SpiritualProfileModel profile;
  final Function(String) onCompleted;

  const ProfileBiographyTaskView({
    super.key,
    required this.profile,
    required this.onCompleted,
  });

  @override
  State<ProfileBiographyTaskView> createState() =>
      _ProfileBiographyTaskViewState();
}

class _ProfileBiographyTaskViewState extends State<ProfileBiographyTaskView> {
  final _purposeController = TextEditingController();
  final _nonNegotiableValueController = TextEditingController();
  final _faithPhraseController = TextEditingController();
  final _aboutMeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool? _isDeusEPaiMember;
  RelationshipStatus? _relationshipStatus;
  bool? _readyForPurposefulRelationship;
  bool? _hasChildren;
  bool? _isVirgin;
  bool? _wasPreviouslyMarried;
  bool _isVirginityPublic = false; // Nova propriedade para controle de privacidade
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    _purposeController.text = widget.profile.purpose ?? '';
    _nonNegotiableValueController.text =
        widget.profile.nonNegotiableValue ?? '';
    _faithPhraseController.text = widget.profile.faithPhrase ?? '';
    _aboutMeController.text = widget.profile.aboutMe ?? '';

    _isDeusEPaiMember = widget.profile.isDeusEPaiMember;
    _relationshipStatus = widget.profile.relationshipStatus;
    _readyForPurposefulRelationship =
        widget.profile.readyForPurposefulRelationship;
    _hasChildren = widget.profile.hasChildren;
    _isVirgin = widget.profile.isVirgin;
    _wasPreviouslyMarried = widget.profile.wasPreviouslyMarried;
    
    // Carregar configuração de privacidade (será implementado no Firestore)
    _loadPrivacySettings();
  }
  
  Future<void> _loadPrivacySettings() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.profile.userId)
          .get();
      
      if (doc.exists) {
        setState(() {
          _isVirginityPublic = doc.data()?['isVirginityPublic'] ?? false;
        });
      }
    } catch (e) {
      print('Erro ao carregar configurações de privacidade: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6B73FF),
              Color(0xFF9B59B6),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildModernAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGuidanceCard(),
                        const SizedBox(height: 20),
                        _buildBiographyForm(),
                        const SizedBox(height: 32),
                        _buildSaveButton(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildModernAppBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Get.back(),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✍️ Biografia Espiritual',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Compartilhe sua jornada de fé',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidanceCard() {
    return ModernBiographyGradientCard(
      title: 'Sua História Espiritual',
      icon: Icons.auto_stories,
      child: const Text(
        'Compartilhe sua jornada de fé e propósito. Seja autêntico e transparente sobre seus valores e intenções espirituais.',
        style: TextStyle(
          fontSize: 15,
          color: Color(0xFF2C3E50),
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildBiographyForm() {
    return Column(
      children: [
        // Purpose question
        ModernBiographyCard(
          title: 'Qual é o seu propósito?',
          icon: Icons.star_outline,
          child: ModernTextField(
            label: '',
            controller: _purposeController,
            maxLines: 3,
            maxLength: 300,
            hint: 'Compartilhe qual é o seu propósito de vida...',
            icon: Icons.lightbulb_outline,
            validator: (value) {
              if (value?.isEmpty == true) {
                return 'Propósito é obrigatório';
              }
              return null;
            },
          ),
        ),

        const SizedBox(height: 16),

        // Deus é Pai movement
        ModernBiographyCard(
          title: 'Você faz parte do movimento Deus é Pai?',
          icon: Icons.groups_outlined,
          child: _buildModernDropdownField(
            _isDeusEPaiMember,
            [
              const DropdownMenuItem(value: true, child: Text('Sim')),
              const DropdownMenuItem(value: false, child: Text('Não')),
            ],
            (value) => setState(() => _isDeusEPaiMember = value),
            'Selecione uma opção',
          ),
        ),

        const SizedBox(height: 16),

        // Relationship status
        ModernBiographyCard(
          title: 'Você está solteiro(a)?',
          icon: Icons.favorite_outline,
          child: FutureBuilder<String?>(
            future: _getUserGender(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final sexo = snapshot.data;
              final isMale = sexo == 'masculino';
              final options = _getRelationshipStatusOptions(isMale);
              final validValue =
                  options.any((item) => item.value == _relationshipStatus)
                      ? _relationshipStatus
                      : null;

              return _buildModernDropdownField(
                validValue,
                options,
                (value) => setState(() => _relationshipStatus = value),
                'Selecione seu status',
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // Ready for purposeful relationship
        ModernBiographyCard(
          title: 'Está disposto(a) a viver um relacionamento com propósito?',
          icon: Icons.handshake_outlined,
          child: _buildModernDropdownField(
            _readyForPurposefulRelationship,
            [
              const DropdownMenuItem(value: true, child: Text('Sim')),
              const DropdownMenuItem(value: false, child: Text('Ainda não sei')),
            ],
            (value) => setState(() => _readyForPurposefulRelationship = value),
            'Selecione uma opção',
          ),
        ),

        const SizedBox(height: 16),

        // Non-negotiable value
        ModernBiographyCard(
          title: 'Qual valor é inegociável para você?',
          icon: Icons.shield_outlined,
          child: ModernTextField(
            label: '',
            controller: _nonNegotiableValueController,
            hint: 'Ex: Fidelidade a Deus',
            icon: Icons.verified_outlined,
            validator: (value) {
              if (value?.isEmpty == true) {
                return 'Valor inegociável é obrigatório';
              }
              return null;
            },
          ),
        ),

        const SizedBox(height: 16),

        // Faith phrase
        ModernBiographyCard(
          title: 'Uma frase que representa sua fé',
          icon: Icons.format_quote,
          child: ModernTextField(
            label: '',
            controller: _faithPhraseController,
            hint: 'Ex: "Lech Lecha. Para onde Deus me mandar, irei."',
            icon: Icons.auto_awesome_outlined,
            validator: (value) {
              if (value?.isEmpty == true) {
                return 'Frase de fé é obrigatória';
              }
              return null;
            },
          ),
        ),

        const SizedBox(height: 16),

        // Children question
        ModernBiographyCard(
          title: 'Você tem filhos?',
          icon: Icons.child_care_outlined,
          child: _buildModernDropdownField(
            _hasChildren,
            [
              const DropdownMenuItem(value: true, child: Text('Sim')),
              const DropdownMenuItem(value: false, child: Text('Não')),
            ],
            (value) => setState(() => _hasChildren = value),
            'Selecione uma opção',
          ),
        ),

        const SizedBox(height: 16),

        // Previous marriage question
        ModernBiographyCard(
          title: 'Você já foi casado(a)?',
          icon: Icons.favorite_border,
          child: _buildModernDropdownField(
            _wasPreviouslyMarried,
            [
              const DropdownMenuItem(value: true, child: Text('Sim')),
              const DropdownMenuItem(value: false, child: Text('Não')),
            ],
            (value) => setState(() => _wasPreviouslyMarried = value),
            'Selecione uma opção',
          ),
        ),

        const SizedBox(height: 16),

        // Virginity question with privacy control - NOVA IMPLEMENTAÇÃO
        PrivacyControlField(
          question: 'Você é virgem?',
          options: const ['Sim', 'Não', 'Prefiro não responder'],
          selectedValue: _isVirgin == null 
              ? 'Prefiro não responder' 
              : (_isVirgin! ? 'Sim' : 'Não'),
          isPublic: _isVirginityPublic,
          onValueChanged: (value) {
            setState(() {
              if (value == 'Prefiro não responder') {
                _isVirgin = null;
              } else {
                _isVirgin = value == 'Sim';
              }
            });
          },
          onPrivacyChanged: (isPublic) {
            setState(() {
              _isVirginityPublic = isPublic;
            });
          },
          hint: 'Opcional - Você pode escolher não responder',
        ),

        const SizedBox(height: 16),

        // About me (optional)
        ModernBiographyCard(
          title: 'Algo que gostaria que soubessem sobre você',
          icon: Icons.person_outline,
          child: ModernTextField(
            label: '',
            controller: _aboutMeController,
            maxLines: 3,
            hint: 'Compartilhe algo especial sobre você... (opcional)',
            icon: Icons.edit_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildModernDropdownField<T>(
    T? value,
    List<DropdownMenuItem<T>> items,
    Function(T?) onChanged,
    String hint, {
    bool isRequired = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 15,
            color: const Color(0xFF7F8C8D).withOpacity(0.8),
            fontWeight: FontWeight.w400,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: const Color(0xFFE9ECEF).withOpacity(0.8),
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: const Color(0xFFE9ECEF).withOpacity(0.8),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF6B73FF),
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Color(0xFF6B73FF),
        ),
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF2C3E50),
          fontWeight: FontWeight.w500,
        ),
        validator: isRequired
            ? (value) {
                if (value == null) {
                  return 'Este campo é obrigatório';
                }
                return null;
              }
            : null,
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6B73FF),
            Color(0xFF9B59B6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B73FF).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSaving ? null : _saveBiography,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            height: 56,
            alignment: Alignment.center,
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
                      Text(
                        'Salvando...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        'Salvar Biografia',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveBiography() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updates = {
        'purpose': _purposeController.text.trim(),
        'isDeusEPaiMember': _isDeusEPaiMember,
        'relationshipStatus': _relationshipStatus?.name,
        'readyForPurposefulRelationship': _readyForPurposefulRelationship,
        'nonNegotiableValue': _nonNegotiableValueController.text.trim(),
        'faithPhrase': _faithPhraseController.text.trim(),
        'aboutMe': _aboutMeController.text.trim().isEmpty
            ? null
            : _aboutMeController.text.trim(),
        'hasChildren': _hasChildren,
        'isVirgin': _isVirgin,
        'wasPreviouslyMarried': _wasPreviouslyMarried,
        'isVirginityPublic': _isVirginityPublic, // Nova configuração de privacidade
      };

      await SpiritualProfileRepository.updateProfile(
          widget.profile.id!, updates);

      // Também salvar no documento do usuário para fácil acesso
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.profile.userId)
          .update({
        'isVirginityPublic': _isVirginityPublic,
      });

      // Mark task as completed
      await SpiritualProfileRepository.updateTaskCompletion(
        widget.profile.id!,
        'biography',
        true,
      );

      widget.onCompleted('biography');
      Get.back();

      Get.snackbar(
        '✅ Sucesso!',
        'Sua biografia foi salva com sucesso.',
        backgroundColor: const Color(0xFF27AE60).withOpacity(0.1),
        colorText: const Color(0xFF27AE60),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.check_circle, color: Color(0xFF27AE60)),
      );
    } catch (e) {
      Get.snackbar(
        '❌ Erro',
        'Não foi possível salvar. Tente novamente.',
        backgroundColor: const Color(0xFFE74C3C).withOpacity(0.1),
        colorText: const Color(0xFFE74C3C),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.error, color: Color(0xFFE74C3C)),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  /// Busca o gênero do usuário do Firestore
  Future<String?> _getUserGender() async {
    try {
      print('🔍 Buscando gênero para userId: ${widget.profile.userId}');

      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.profile.userId)
          .get();

      if (!userDoc.exists) {
        print('❌ Documento do usuário não encontrado');
        return null;
      }

      final data = userDoc.data();
      print('📄 Dados do usuário: $data');

      // O campo é 'sexo' e retorna 'masculino' ou 'feminino'
      final sexo = data?['sexo'] as String?;
      print('✅ Sexo encontrado: $sexo');

      return sexo;
    } catch (e) {
      print('❌ Erro ao buscar gênero: $e');
      return null;
    }
  }

  /// Retorna as opções de status de relacionamento baseadas no gênero
  List<DropdownMenuItem<RelationshipStatus>> _getRelationshipStatusOptions(
      bool isMale) {
    final options = <DropdownMenuItem<RelationshipStatus>>[];

    // Adiciona opção de solteiro/solteira baseado no gênero
    if (isMale) {
      options.add(const DropdownMenuItem(
        value: RelationshipStatus.solteiro,
        child: Text('Solteiro'),
      ));
      options.add(const DropdownMenuItem(
        value: RelationshipStatus.comprometido,
        child: Text('Comprometido'),
      ));
    } else {
      options.add(const DropdownMenuItem(
        value: RelationshipStatus.solteira,
        child: Text('Solteira'),
      ));
      options.add(const DropdownMenuItem(
        value: RelationshipStatus.comprometida,
        child: Text('Comprometida'),
      ));
    }

    // Adiciona opção de não informar
    options.add(const DropdownMenuItem(
      value: RelationshipStatus.naoInformado,
      child: Text('Prefiro não informar'),
    ));

    return options;
  }

  @override
  void dispose() {
    _purposeController.dispose();
    _nonNegotiableValueController.dispose();
    _faithPhraseController.dispose();
    _aboutMeController.dispose();
    super.dispose();
  }
}
