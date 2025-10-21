import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario_model.dart';
import '../repositories/username_repository.dart';
import '../repositories/usuario_repository.dart';
import '../utils/username_validator.dart';
import '../locale/language.dart';
import '../controllers/completar_perfil_controller.dart';
import '../views/login_view.dart';
import '../views/select_language_view.dart';
import '../repositories/purpose_partnership_repository.dart';
import '../models/purpose_partnership_model.dart';



class UsernameSettingsView extends StatefulWidget {
  final UsuarioModel user;
  
  const UsernameSettingsView({super.key, required this.user});

  @override
  State<UsernameSettingsView> createState() => _UsernameSettingsViewState();
}

class _UsernameSettingsViewState extends State<UsernameSettingsView> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  Timer? _debounceTimer;
  UsernameValidationResult _usernameValidation = const UsernameValidationResult(
    isValid: false,
    isAvailable: false,
  );
  

  bool _isSaving = false;
  bool _passwordEnabled = false;

  @override
  void initState() {
    super.initState();
    _initializeFields();
    _initializeImageControllers();
    _loadPasswordSettings();
  }
  
  void _loadPasswordSettings() async {
    // Verificar se o usuário tem senha configurada (se não é login social)
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Se o usuário tem providerData com password, significa que tem senha
      bool hasPassword = user.providerData.any((provider) => provider.providerId == 'password');
      setState(() {
        _passwordEnabled = hasPassword;
      });
    }
  }
  
  void _initializeImageControllers() {
    // Limpar dados anteriores (apenas papel de parede, não mais foto de perfil)
    CompletarPerfilController.imgBgPath.value = '';
    CompletarPerfilController.imgBgData = null;
    // Não limpar mais imgPath e imgData pois não são usados aqui
  }
  
  Future<void> _saveOnlyImages() async {
    setState(() {
      _isSaving = true;
    });
    
    try {
      // Salvar apenas papel de parede do chat (não mais foto de perfil)
      if (CompletarPerfilController.imgBgData != null) {
        await UsuarioRepository.completarPerfil(
          imgBgData: CompletarPerfilController.imgBgData,
          imgData: null, // Não salvar mais foto de perfil aqui
          sexo: widget.user.sexo!
        );
        
        // Limpar os dados do controller após salvar
        CompletarPerfilController.imgBgPath.value = '';
        CompletarPerfilController.imgBgData = null;
      }
      
      Get.rawSnackbar(
        message: 'Papel de parede atualizado com sucesso!',
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      );
      
      await Future.delayed(const Duration(milliseconds: 500));
      Get.back();
    } catch (e) {
      Get.rawSnackbar(
        message: 'Erro ao salvar imagens: ${e.toString()}',
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _initializeFields() {
    _nameController.text = widget.user.nome ?? '';
    _usernameController.text = widget.user.username ?? '';
    
    // Se já tem username, validar
    if (widget.user.username?.isNotEmpty == true) {
      _validateUsername(widget.user.username!);
    }
  }

  void _onUsernameChanged(String value) {
    _debounceTimer?.cancel();
    
    if (value.isEmpty) {
      setState(() {
        _usernameValidation = UsernameValidationResult.empty;
      });
      return;
    }
    
    setState(() {
      _usernameValidation = UsernameValidationResult.checking;
    });
    
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _validateUsername(value);
    });
  }

  Future<void> _validateUsername(String username) async {
    if (!mounted) return;
    
    // Primeiro validar formato
    final formatValidation = UsernameValidator.validate(username);
    if (!formatValidation.isValid) {
      setState(() {
        _usernameValidation = UsernameValidationResult(
          isValid: false,
          isAvailable: false,
          errorMessage: formatValidation.errorMessage,
          suggestions: formatValidation.suggestions,
        );
      });
      return;
    }
    
    // Depois verificar disponibilidade
    try {
      final isAvailable = await UsernameRepository.canUserUseUsername(username);
      
      if (mounted) {
        setState(() {
          _usernameValidation = UsernameValidationResult(
            isValid: true,
            isAvailable: isAvailable,
            errorMessage: isAvailable ? null : 'Este username já está em uso',
            suggestions: isAvailable ? [] : formatValidation.suggestions,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _usernameValidation = const UsernameValidationResult(
            isValid: false,
            isAvailable: false,
            errorMessage: 'Erro ao verificar disponibilidade',
          );
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    // Verificar se há mudanças no papel de parede (não mais foto de perfil)
    bool hasImageChanges = CompletarPerfilController.imgBgData != null;
    
    // Lista de problemas encontrados
    List<String> problemas = [];
    
    // Validar nome
    if (_nameController.text.trim().isEmpty) {
      problemas.add('• Nome de exibição é obrigatório');
    }
    
    // Validar username
    if (_usernameController.text.trim().isEmpty) {
      problemas.add('• Username é obrigatório');
    } else if (!_usernameValidation.isValid) {
      problemas.add('• Username inválido: ${_usernameValidation.errorMessage ?? "formato incorreto"}');
    } else if (!_usernameValidation.isAvailable) {
      problemas.add('• Username não disponível: ${_usernameValidation.errorMessage ?? "já está em uso"}');
    }
    
    // Se há problemas nos campos obrigatórios e não há mudanças de imagem, mostrar aviso
    if (problemas.isNotEmpty && !hasImageChanges) {
      Get.defaultDialog(
        title: 'Campos Obrigatórios',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Para salvar o perfil, você precisa preencher:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            ...problemas.map((problema) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                problema,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            )),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Get.back(),
            child: const Text('Entendi'),
          ),
        ],
      );
      return;
    }
    
    // Se há mudanças de imagem mas problemas nos campos, perguntar se quer salvar só as imagens
    if (problemas.isNotEmpty && hasImageChanges) {
      // Usar um dialog mais simples para evitar crashes
      await Get.defaultDialog(
        title: 'Salvar Apenas Imagens?',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Há problemas nos campos de texto, mas você pode salvar apenas as imagens.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            const Text(
              'Deseja continuar salvando apenas as imagens?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _saveOnlyImages();
            },
            child: const Text('Salvar Papel de Parede'),
          ),
        ],
      );
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      // Salvar dados de texto apenas se não há problemas
      if (problemas.isEmpty) {
        // Salvar username
        await UsernameRepository.saveUsername(
          widget.user.id!,
          _usernameController.text,
        );
        
        // Atualizar nome no perfil do usuário
        await UsuarioRepository.updateUser({
          'nome': _nameController.text.trim(),
        });
      }
      
      // Salvar papel de parede se foi alterado (não mais foto de perfil)
      if (CompletarPerfilController.imgBgData != null) {
        print('DEBUG: Salvando papel de parede...');
        print('DEBUG: imgBgData != null: ${CompletarPerfilController.imgBgData != null}');
        
        await UsuarioRepository.completarPerfil(
          imgBgData: CompletarPerfilController.imgBgData,
          imgData: null, // Não salvar mais foto de perfil aqui
          sexo: widget.user.sexo!
        );
        
        print('DEBUG: Papel de parede salvo com sucesso!');
        
        // Limpar os dados do controller após salvar
        CompletarPerfilController.imgBgPath.value = '';
        CompletarPerfilController.imgBgData = null;
      }
      
      // Mensagem de sucesso específica
      String mensagem;
      if (problemas.isEmpty && hasImageChanges) {
        mensagem = 'Perfil e papel de parede atualizados com sucesso!';
      } else if (problemas.isEmpty) {
        mensagem = 'Perfil atualizado com sucesso!';
      } else if (hasImageChanges) {
        mensagem = 'Papel de parede atualizado com sucesso!';
      } else {
        mensagem = 'Atualização realizada!';
      }
      
      Get.rawSnackbar(
        message: mensagem,
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      );
      
      // Aguardar um pouco para garantir que o Firestore foi atualizado
      await Future.delayed(const Duration(milliseconds: 500));
      
      Get.back();
    } catch (e) {
      print('ERRO AO SALVAR: $e');
      Get.rawSnackbar(
        message: 'Erro ao salvar: ${e.toString()}',
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildUsernameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _usernameController,
          decoration: InputDecoration(
            labelText: 'Username *',
            hintText: 'seu_username',
            prefixText: '@',
            prefixStyle: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
            suffixIcon: _buildUsernameStatusIcon(),
            border: const OutlineInputBorder(),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blue),
            ),
            helperText: 'Campo obrigatório',
            helperStyle: const TextStyle(color: Colors.red, fontSize: 12),
          ),
          onChanged: _onUsernameChanged,
          validator: (value) {
            if (value?.isEmpty == true) {
              return AppLanguage.lang('username_obrigatorio');
            }
            if (!_usernameValidation.isValid) {
              return _usernameValidation.errorMessage;
            }
            if (!_usernameValidation.isAvailable) {
              return _usernameValidation.errorMessage;
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        _buildUsernameStatus(),
        if (_usernameValidation.suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildSuggestions(),
        ],
      ],
    );
  }

  Widget? _buildUsernameStatusIcon() {
    if (_usernameValidation.isChecking) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    
    if (_usernameValidation.isValid && _usernameValidation.isAvailable) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }
    
    if (_usernameValidation.errorMessage != null) {
      return const Icon(Icons.error, color: Colors.red);
    }
    
    return null;
  }

  Widget _buildUsernameStatus() {
    if (_usernameValidation.isChecking) {
      return Row(
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 1),
          ),
          const SizedBox(width: 8),
          Text(
            AppLanguage.lang('verificando_username'),
            style: const TextStyle(color: Colors.orange, fontSize: 12),
          ),
        ],
      );
    }
    
    if (_usernameValidation.isValid && _usernameValidation.isAvailable) {
      return Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Text(
            AppLanguage.lang('username_disponivel'),
            style: const TextStyle(color: Colors.green, fontSize: 12),
          ),
        ],
      );
    }
    
    if (_usernameValidation.errorMessage != null) {
      return Row(
        children: [
          const Icon(Icons.error, color: Colors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _usernameValidation.errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        ],
      );
    }
    
    return const SizedBox();
  }

  Widget _buildSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLanguage.lang('sugestoes'),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: _usernameValidation.suggestions.map((suggestion) {
            return ActionChip(
              label: Text('@$suggestion'),
              onPressed: () {
                _usernameController.text = suggestion;
                _onUsernameChanged(suggestion);
              },
              backgroundColor: Colors.blue.withOpacity(0.1),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildLanguageSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.language, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'Idioma',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Botão para alterar idioma
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Get.to(() => const SelectLanguageView());
              },
              icon: const Icon(Icons.flag_outlined),
              label: Text(AppLanguage.lang('alterar_idioma')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Altere o idioma do aplicativo',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAccountSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_circle_outlined, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                'Conta',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Botão para deletar conta
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                _showDeleteAccountDialog();
              },
              icon: const Icon(Icons.delete_outline),
              label: Text(AppLanguage.lang('deletar_minha_conta')),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Esta ação não pode ser desfeita',
            style: TextStyle(
              fontSize: 12,
              color: Colors.red.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteAccountDialog() {
    Get.defaultDialog(
      title: AppLanguage.lang('aviso'),
      content: Text(
        AppLanguage.lang('aviso_delete_conta'), 
        textAlign: TextAlign.center
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text(AppLanguage.lang('nao')),
        ),
        ElevatedButton(
          onPressed: () async {
            Get.back(); // Fechar dialog
            
            try {
              // Mostrar loading
              Get.defaultDialog(
                title: 'Deletando Conta',
                content: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Deletando sua conta...'),
                  ],
                ),
                barrierDismissible: false,
              );
              
              // Deletar dados do Firestore
              await FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .delete();
              
              // Fazer logout
              await FirebaseAuth.instance.signOut();
              
              Get.back(); // Fechar loading
              
              // Ir para tela de login
              Get.offAll(() => const LoginView());
              
              Get.rawSnackbar(
                message: 'Conta deletada com sucesso',
                backgroundColor: Colors.green,
              );
            } catch (e) {
              Get.back(); // Fechar loading
              Get.rawSnackbar(
                message: 'Erro ao deletar conta: $e',
                backgroundColor: Colors.red,
              );
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text(
            AppLanguage.lang('sim'), 
            style: const TextStyle(color: Colors.white)
          ),
        ),
      ],
    );
  }
  
  Widget _buildSecuritySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.security, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                'Segurança',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Switch para ativar/desativar senha
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Senha do Aplicativo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _passwordEnabled 
                        ? 'App protegido com senha ao abrir'
                        : 'App sem proteção por senha',
                      style: TextStyle(
                        fontSize: 12,
                        color: _passwordEnabled ? Colors.green.shade600 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _passwordEnabled,
                onChanged: (value) {
                  if (value) {
                    // Ativar senha - mostrar dialog para criar/configurar
                    _showPasswordDialog();
                  } else {
                    // Desativar senha - mostrar confirmação
                    _showDisablePasswordDialog();
                  }
                },
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Botão para criar/editar senha
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                _showPasswordDialog();
              },
              icon: const Icon(Icons.key),
              label: Text(_passwordEnabled ? 'Alterar Senha' : 'Criar Senha'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showDisablePasswordDialog() {
    Get.defaultDialog(
      title: 'Desativar Senha',
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning, color: Colors.orange, size: 48),
          SizedBox(height: 16),
          Text(
            'Tem certeza que deseja desativar a proteção por senha?',
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'O app ficará acessível sem senha.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _passwordEnabled = false;
            });
            Get.back();
            Get.rawSnackbar(
              message: 'Proteção por senha desativada',
              backgroundColor: Colors.orange,
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: const Text('Desativar', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
  
  void _savePassword(String password) async {
    try {
      Get.defaultDialog(
        title: 'Configurando Senha',
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Configurando proteção por senha...'),
          ],
        ),
        barrierDismissible: false,
      );
      
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Se o usuário não tem senha (login social), criar uma
        bool hasPassword = user.providerData.any((provider) => provider.providerId == 'password');
        
        if (!hasPassword) {
          // Usuário logou com Google/Apple, precisa criar senha
          await user.updatePassword(password);
        } else {
          // Usuário já tem senha, apenas atualizar
          await user.updatePassword(password);
        }
        
        setState(() {
          _passwordEnabled = true;
        });
        
        Get.back(); // Fechar dialog de loading
        Get.rawSnackbar(
          message: 'Senha configurada com sucesso!',
          backgroundColor: Colors.green,
        );
      }
    } catch (e) {
      Get.back(); // Fechar dialog de loading
      Get.rawSnackbar(
        message: 'Erro ao configurar senha: $e',
        backgroundColor: Colors.red,
      );
    }
  }
  
  void _showPasswordDialog() {
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscurePassword = true;
    bool obscureConfirm = true;
    
    Get.defaultDialog(
      title: 'Configurar Senha',
      content: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Defina uma senha para proteger o aplicativo',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              
              // Campo de senha
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Nova Senha',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Campo de confirmação
              TextField(
                controller: confirmPasswordController,
                obscureText: obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirmar Senha',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(obscureConfirm ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        obscureConfirm = !obscureConfirm;
                      });
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (passwordController.text.isEmpty) {
              Get.rawSnackbar(
                message: 'Digite uma senha',
                backgroundColor: Colors.red,
              );
              return;
            }
            
            if (passwordController.text != confirmPasswordController.text) {
              Get.rawSnackbar(
                message: 'Senhas não coincidem',
                backgroundColor: Colors.red,
              );
              return;
            }
            
            if (passwordController.text.length < 4) {
              Get.rawSnackbar(
                message: 'Senha deve ter pelo menos 4 caracteres',
                backgroundColor: Colors.red,
              );
              return;
            }
            
            // Salvar senha usando o sistema existente do Firebase
            _savePassword(passwordController.text);
            Get.back();
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
  
  Widget _buildWallpaperSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Papel de Parede do Chat',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 80,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Obx(() => CompletarPerfilController.imgBgPath.value.isNotEmpty && CompletarPerfilController.imgBgData != null
                      ? Image.memory(
                          CompletarPerfilController.imgBgData!,
                          fit: BoxFit.cover,
                        )
                      : widget.user.imgBgUrl != null
                          ? Image.network(
                              widget.user.imgBgUrl!,
                              fit: BoxFit.cover,
                            )
                          : Opacity(
                              opacity: 0.3,
                              child: Image.asset(
                                'lib/assets/img/bg_wallpaper.jpg',
                                fit: BoxFit.cover,
                              ),
                            )),
                ),
              ),
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => CompletarPerfilController.changeImgBg(),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.black.withOpacity(0.2),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              color: Colors.white,
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Alterar Papel de Parede',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Toque para alterar o papel de parede do chat',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLanguage.lang('editar_perfil')),
        backgroundColor: Colors.blue,
        actions: [
          TextButton(
            onPressed: _isSaving || 
                      (!_usernameValidation.isValid || !_usernameValidation.isAvailable) &&
                      (CompletarPerfilController.imgData == null && CompletarPerfilController.imgBgData == null)
                ? null
                : _saveChanges,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Salvar',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Seção de Personalização
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.palette, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Personalização',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Papel de Parede
                  _buildWallpaperSection(),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Seção de Informações do Perfil
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_outline, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Informações do Perfil',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.orange, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Campos marcados com * são obrigatórios para salvar o perfil completo',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Nome
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: '${AppLanguage.lang('nome_exibicao')} *',
                      hintText: AppLanguage.lang('seu_nome_completo'),
                      border: const OutlineInputBorder(),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                      helperText: 'Campo obrigatório',
                      helperStyle: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                    validator: (value) {
                      if (value?.trim().isEmpty == true) {
                        return AppLanguage.lang('nome_obrigatorio');
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Username
                  _buildUsernameField(),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Informações sobre username
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        AppLanguage.lang('sobre_username'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Deve ter entre 3 e 20 caracteres\n'
                    '• Pode conter letras, números e underscore\n'
                    '• Deve começar com uma letra\n'
                    '• Será único em toda a plataforma',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Seção de Idioma
            _buildLanguageSection(),
            
            const SizedBox(height: 24),
            
            // Seção de Segurança
            _buildSecuritySection(),
            
            const SizedBox(height: 24),
            
            // Seção de Parceria (Nosso Propósito)
            _buildPartnershipSection(),
            
            const SizedBox(height: 24),
            
            // Seção de Conta (Deletar)
            _buildAccountSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnershipSection() {
    return FutureBuilder<PurposePartnershipModel?>(
      future: PurposePartnershipRepository.getUserPartnership(widget.user.id!),
      builder: (context, snapshot) {
        // Se não há parceria ativa, não mostrar a seção
        if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.isActivePartnership) {
          return const SizedBox();
        }

        final partnership = snapshot.data!;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.pink.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.pink.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.favorite, color: Colors.pink),
                  const SizedBox(width: 8),
                  const Text(
                    'Nosso Propósito',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Informações da parceria
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.people, color: Colors.grey, size: 16),
                        const SizedBox(width: 8),
                        const Text(
                          'Parceria Ativa',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Você está conectado(a) em uma parceria do Nosso Propósito.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Botão de excluir parceiro
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showDeletePartnershipDialog(partnership),
                  icon: const Icon(Icons.person_remove),
                  label: const Text('Excluir Parceiro Nosso Propósito'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Aviso
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ao excluir o parceiro, o chat será reiniciado do zero e você perderá toda a conversa.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeletePartnershipDialog(PurposePartnershipModel partnership) {
    // Buscar informações do parceiro
    final currentUserId = widget.user.id!;
    final partnerId = partnership.user1Id == currentUserId 
        ? partnership.user2Id 
        : partnership.user1Id;

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Excluir Parceiro'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tem certeza que deseja excluir o parceiro do Nosso Propósito?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        'Consequências:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• O chat se iniciará do zero\n'
                    '• Você perderá toda a conversa\n'
                    '• A parceria será desfeita\n'
                    '• Será necessário enviar novo convite',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => _deletePartnership(partnership),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir Parceiro'),
          ),
        ],
      ),
    );
  }

  void _deletePartnership(PurposePartnershipModel partnership) async {
    try {
      // Mostrar loading
      Get.back(); // Fechar dialog
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
          ),
        ),
        barrierDismissible: false,
      );

      // Desconectar parceria
      await PurposePartnershipRepository.disconnectPartnership(partnership.id!);
      
      // Fechar loading
      Get.back();
      
      // Mostrar sucesso
      Get.snackbar(
        'Parceiro Excluído! 💔',
        'A parceria foi desfeita. O chat foi reiniciado do zero.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.person_remove, color: Colors.white),
        duration: const Duration(seconds: 4),
      );
      
      // Atualizar a tela
      setState(() {});
      
    } catch (e) {
      // Fechar loading se ainda estiver aberto
      if (Get.isDialogOpen == true) {
        Get.back();
      }
      
      // Mostrar erro
      Get.snackbar(
        'Erro ao Excluir Parceiro',
        e.toString().replaceAll('Exception: ', ''),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
        duration: const Duration(seconds: 4),
      );
    }
  }
}