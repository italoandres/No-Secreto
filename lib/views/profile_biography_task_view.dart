import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/spiritual_profile_model.dart';
import '../repositories/spiritual_profile_repository.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          '✍️ Biografia Espiritual',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green[700],
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
              _buildBiographyForm(),
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
          colors: [Colors.green[100]!, Colors.green[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_stories,
                color: Colors.green[700],
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Sua História Espiritual',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Compartilhe sua jornada de fé e propósito. Seja autêntico e transparente sobre seus valores e intenções espirituais.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.green[800],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiographyForm() {
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
          const Text(
            'Perguntas Espirituais',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Purpose question
          TextFormField(
            controller: _purposeController,
            maxLines: 3,
            maxLength: 300,
            decoration: InputDecoration(
              labelText: 'Qual é o seu propósito? *',
              hintText: 'Compartilhe qual é o seu propósito de vida...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green[700]!),
              ),
            ),
            validator: (value) {
              if (value?.isEmpty == true) {
                return 'Propósito é obrigatório';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Deus é Pai movement
          _buildDropdownField(
            'Você faz parte do movimento Deus é Pai? *',
            _isDeusEPaiMember,
            [
              const DropdownMenuItem(value: true, child: Text('Sim')),
              const DropdownMenuItem(value: false, child: Text('Não')),
            ],
            (value) => setState(() => _isDeusEPaiMember = value),
            'Selecione uma opção',
          ),

          const SizedBox(height: 20),

          // Relationship status
          FutureBuilder<String?>(
            future: _getUserGender(),
            builder: (context, snapshot) {
              // Enquanto carrega, mostra loading
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final sexo = snapshot.data;
              final isMale = sexo == 'masculino'; // minúsculo!

              print('🔍 Sexo loaded: $sexo, isMale: $isMale');

              // Obtém as opções válidas para o gênero
              final options = _getRelationshipStatusOptions(isMale);

              // Verifica se o valor atual é válido para as opções disponíveis
              final validValue =
                  options.any((item) => item.value == _relationshipStatus)
                      ? _relationshipStatus
                      : null;

              return _buildDropdownField(
                'Você está solteiro(a)? *',
                validValue,
                options,
                (value) => setState(() => _relationshipStatus = value),
                'Selecione seu status',
              );
            },
          ),

          const SizedBox(height: 20),

          // Ready for purposeful relationship
          _buildDropdownField(
            'Está disposto(a) a viver um relacionamento com propósito? *',
            _readyForPurposefulRelationship,
            [
              const DropdownMenuItem(value: true, child: Text('Sim')),
              const DropdownMenuItem(
                  value: false, child: Text('Ainda não sei')),
            ],
            (value) => setState(() => _readyForPurposefulRelationship = value),
            'Selecione uma opção',
          ),

          const SizedBox(height: 20),

          // Non-negotiable value
          TextFormField(
            controller: _nonNegotiableValueController,
            decoration: InputDecoration(
              labelText: 'Qual valor é inegociável para você? *',
              hintText: 'Ex: Fidelidade a Deus',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green[700]!),
              ),
            ),
            validator: (value) {
              if (value?.isEmpty == true) {
                return 'Valor inegociável é obrigatório';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Faith phrase
          TextFormField(
            controller: _faithPhraseController,
            decoration: InputDecoration(
              labelText: 'Uma frase que representa sua fé *',
              hintText: 'Ex: "Lech Lecha. Para onde Deus me mandar, irei."',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green[700]!),
              ),
            ),
            validator: (value) {
              if (value?.isEmpty == true) {
                return 'Frase de fé é obrigatória';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Children question
          _buildDropdownField(
            'Você tem filhos? *',
            _hasChildren,
            [
              const DropdownMenuItem(value: true, child: Text('Sim')),
              const DropdownMenuItem(value: false, child: Text('Não')),
            ],
            (value) => setState(() => _hasChildren = value),
            'Selecione uma opção',
          ),

          const SizedBox(height: 20),

          // Previous marriage question
          _buildDropdownField(
            'Você já foi casado(a)? *',
            _wasPreviouslyMarried,
            [
              const DropdownMenuItem(value: true, child: Text('Sim')),
              const DropdownMenuItem(value: false, child: Text('Não')),
            ],
            (value) => setState(() => _wasPreviouslyMarried = value),
            'Selecione uma opção',
          ),

          const SizedBox(height: 20),

          // Virginity question (optional/private)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.pink[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.pink[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lock, color: Colors.pink[600], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Pergunta Privada (Opcional)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.pink[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildDropdownField(
                  'Você é virgem?',
                  _isVirgin,
                  [
                    const DropdownMenuItem(value: true, child: Text('Sim')),
                    const DropdownMenuItem(value: false, child: Text('Não')),
                    const DropdownMenuItem(
                        value: null, child: Text('Prefiro não responder')),
                  ],
                  (value) => setState(() => _isVirgin = value),
                  'Opcional - Você pode escolher não responder',
                  isRequired: false,
                ),
                const SizedBox(height: 8),
                Text(
                  'Esta informação é privada e só será compartilhada se você escolher.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // About me (optional)
          TextFormField(
            controller: _aboutMeController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText:
                  'Algo que gostaria que soubessem sobre você (opcional)',
              hintText: 'Compartilhe algo especial sobre você...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green[700]!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField<T>(
    String label,
    T? value,
    List<DropdownMenuItem<T>> items,
    Function(T?) onChanged,
    String hint, {
    bool isRequired = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.green[700]!),
            ),
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
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveBiography,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[700],
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
                'Salvar Biografia',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
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
        // New fields
        'hasChildren': _hasChildren,
        'isVirgin': _isVirgin,
        'wasPreviouslyMarried': _wasPreviouslyMarried,
      };

      await SpiritualProfileRepository.updateProfile(
          widget.profile.id!, updates);

      // Mark task as completed
      await SpiritualProfileRepository.updateTaskCompletion(
        widget.profile.id!,
        'biography',
        true,
      );

      widget.onCompleted('biography');
      Get.back();

      Get.snackbar(
        'Sucesso!',
        'Sua biografia foi salva com sucesso.',
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
