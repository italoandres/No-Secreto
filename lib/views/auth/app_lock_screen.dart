import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import '../../models/auth/auth_method.dart';
import '../../models/auth/biometric_info.dart';
import '../../services/auth/biometric_auth_service.dart';

/// Tela de bloqueio que solicita autenticação
class AppLockScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const AppLockScreen({
    super.key,
    required this.onAuthenticated,
  });

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final BiometricAuthService _authService = BiometricAuthService();
  final TextEditingController _passwordController = TextEditingController();

  int _failedAttempts = 0;
  bool _isAuthenticating = false;
  String? _errorMessage;
  AuthMethod _authMethod = AuthMethod.none;
  BiometricInfo? _biometricInfo;
  bool _deviceHasBiometricHardware = false;
  bool _biometricIsEnrolled = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Carregar método de autenticação
      _authMethod = await _authService.getPreferredAuthMethod();
      
      // Verificar biometria de forma mais robusta
      final localAuth = LocalAuthentication();
      
      // 1. Verificar se dispositivo suporta biometria
      _deviceHasBiometricHardware = await localAuth.isDeviceSupported();
      
      // 2. Se suporta, verificar se há biometrias cadastradas
      if (_deviceHasBiometricHardware) {
        final availableBiometrics = await localAuth.getAvailableBiometrics();
        _biometricIsEnrolled = availableBiometrics.isNotEmpty;
      } else {
        _biometricIsEnrolled = false;
      }

      // Carregar informações de biometria se disponível
      if (_authMethod == AuthMethod.biometric ||
          _authMethod == AuthMethod.biometricWithPasswordFallback) {
        _biometricInfo = await _authService.getBiometricInfo();
      }

      // Marcar como inicializado
      setState(() {
        _isInitialized = true;
      });

      // ✅ NOVA LÓGICA: Só chama biometria automaticamente se usuário já habilitou antes
      final autoBiometricEnabled = await _authService.getAutoBiometricEnabled();
      
      if (autoBiometricEnabled && 
          _biometricIsEnrolled && 
          _biometricInfo?.isAvailable == true) {
        // Usuário já optou por biometria automática anteriormente
        await _authenticateWithBiometric();
      }
      // Caso contrário, aguarda usuário clicar no botão "Usar Biometria"
    } catch (e) {
      // Em caso de erro, marcar como inicializado mesmo assim
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _authenticateWithBiometric() async {
    if (_isAuthenticating) {
      return;
    }

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    try {
      final authenticated = await _authService.authenticate(
        reason: 'Autentique-se para acessar o aplicativo',
      );

      if (authenticated) {
        widget.onAuthenticated();
      } else {
        _failedAttempts++;
        if (_failedAttempts >= 3) {
          _switchToPasswordFallback();
        } else {
          setState(() {
            _errorMessage = 'Autenticação falhou. Tente novamente.';
          });
        }
      }
    } catch (e) {
      _failedAttempts++;
      if (_failedAttempts >= 3 ||
          _authMethod == AuthMethod.biometricWithPasswordFallback) {
        _switchToPasswordFallback();
      } else {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  void _switchToPasswordFallback() {
    setState(() {
      _errorMessage = 'Use sua senha para continuar';
      _failedAttempts = 0;
    });
  }

  Future<void> _openBiometricSettings() async {
    // Mostrar dialog explicativo
    Get.defaultDialog(
      title: 'Configurar Biometria',
      titleStyle: const TextStyle(color: Colors.white),
      backgroundColor: const Color(0xFF1565C0),
      content: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(Icons.fingerprint, size: 64, color: Colors.orange),
            SizedBox(height: 20),
            Text(
              'Para usar biometria no app, você precisa configurá-la primeiro nas configurações do Android.',
              style: TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Text(
              'Vá em:',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            SizedBox(height: 8),
            Text(
              'Configurações → Segurança → Biometria',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Text(
              'Depois de configurar, volte ao app e a biometria estará disponível!',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Get.back();
          },
          child: const Text(
            'Entendi',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            Get.back();
            
            // Aguardar um pouco e recarregar
            await Future.delayed(const Duration(seconds: 1));
            await _initialize();
            
            Get.rawSnackbar(
              message: 'Verificando biometria...',
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 2),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Já Configurei'),
        ),
      ],
    );
  }

  Future<void> _authenticateWithPassword() async {
    final password = _passwordController.text;

    if (password.isEmpty) {
      setState(() {
        _errorMessage = 'Digite sua senha';
      });
      return;
    }

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    try {
      final isCorrect = await _authService.verifyPassword(password);

      if (isCorrect) {
        widget.onAuthenticated();
      } else {
        setState(() {
          _errorMessage = 'Senha incorreta';
          _passwordController.clear();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao verificar senha: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar loading enquanto inicializa
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.blue,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.blue,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(60),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: Image.asset(
                      'lib/assets/img/logo_2.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Título
                const Text(
                  '🔒 App Protegido',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 48),

                // UI de autenticação - SEMPRE mostra senha
                _buildPasswordUI(),

                // Mensagem de erro
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordUI() {
    return Column(
      children: [
        // Ícone de senha
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(40),
          ),
          child: const Icon(
            Icons.lock_outline,
            size: 48,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 24),

        // Texto
        const Text(
          'Digite sua senha',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 32),

        // Campo de senha
        TextField(
          controller: _passwordController,
          obscureText: true,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            hintText: 'Senha',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
            prefixIcon: const Icon(Icons.lock, color: Colors.white),
          ),
          onSubmitted: (_) => _authenticateWithPassword(),
        ),

        const SizedBox(height: 16),

        // Botão de autenticar
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isAuthenticating ? null : _authenticateWithPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: _isAuthenticating
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Entrar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 20),

        // Opções baseadas no estado da biometria
        if (_authMethod == AuthMethod.biometricWithPasswordFallback) ...[
          // CASO 1: ✅ Biometria configurada e funcionando
          if (_biometricIsEnrolled && _biometricInfo?.isAvailable == true)
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    setState(() {
                      _errorMessage = null;
                    });
                    
                    // ✅ Salvar preferência: usuário quer biometria automática
                    await _authService.setAutoBiometricEnabled(true);
                    
                    // Autenticar
                    await _authenticateWithBiometric();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(_biometricInfo!.iconData),
                  label: const Text(
                    'Usar Biometria',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Ou use sua senha acima',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ],
            ),

          // CASO 2: ⚠️ Aparelho tem sensor MAS não configurado
          if (_deviceHasBiometricHardware && !_biometricIsEnrolled)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.withOpacity(0.3), width: 2),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Seu aparelho suporta biometria, mas você ainda não a configurou.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openBiometricSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.fingerprint, size: 24),
                      label: const Text(
                        'Configurar Biometria Agora',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // CASO 3: ❌ Aparelho não tem sensor de biometria
          if (!_deviceHasBiometricHardware)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white70, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Seu aparelho não possui sensor de biometria.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
}
