import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:whatsapp_chat/widgets/terms_acceptance_widget.dart';
import '/controllers/login_controller.dart';

class LoginComEmailView extends StatefulWidget {
  final bool isLogin;

  const LoginComEmailView({super.key, this.isLogin = false});

  @override
  State<LoginComEmailView> createState() => _LoginComEmailViewState();
}

class _LoginComEmailViewState extends State<LoginComEmailView> {
  PageController pageController = PageController();
  final termsAccepted = false.obs;
  final privacyAccepted = false.obs;

  @override
  void initState() {
    super.initState();
    // Se for login, ir direto para a página de login
    if (widget.isLogin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        pageController.jumpToPage(0);
      });
    } else {
      // Se for cadastro, ir para a página de cadastro
      WidgetsBinding.instance.addPostFrameCallback((_) {
        pageController.jumpToPage(1);
      });
    }
  }

  void _showTermsAlert() {
    Get.snackbar(
      'Termos e Condições',
      'É necessário aceitar os Termos e Condições e a Política de Privacidade para continuar.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange[100],
      colorText: Colors.orange[800],
      icon: Icon(Icons.info, color: Colors.orange[600]),
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: Get.width,
        height: Get.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFFF9C4), // Amarelo claro
              const Color(0xFFFFF59D), // Amarelo médio
              Colors.white, // Branco
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: PageView(
          controller: pageController,
          children: [
            _buildLoginPage(),
            _buildCadastroPage(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginPage() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header com botão voltar
            _buildHeader('Acessar sua conta', 'Entre com seu email e senha'),

            SizedBox(height: Get.height * 0.06),

            // Card de login
            _buildLoginCard(),

            const SizedBox(height: 24),

            // Link para cadastro
            _buildSwitchLink(
              'Ainda não tem uma conta?',
              'Criar conta',
              () => pageController.animateToPage(1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCadastroPage() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header com botão voltar
            _buildHeader(
                'Criar sua conta', 'Preencha os dados para se cadastrar'),

            SizedBox(height: Get.height * 0.06),

            // Card de cadastro
            _buildCadastroCard(),

            const SizedBox(height: 24),

            // Link para login
            _buildSwitchLink(
              'Já tem uma conta?',
              'Fazer login',
              () => pageController.animateToPage(0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title, String subtitle) {
    return Column(
      children: [
        // Botão voltar e logo
        Row(
          children: [
            IconButton(
              onPressed: () => Get.back(),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back, color: Colors.grey),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF38b6ff).withOpacity(0.1),
                    const Color(0xFFf76cec).withOpacity(0.1),
                  ],
                ),
              ),
              child: Image.asset('lib/assets/img/logo.png', width: 40),
            ),
            const Spacer(),
            const SizedBox(width: 48), // Para balancear o botão voltar
          ],
        ),

        const SizedBox(height: 32),

        // Título e subtítulo
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..shader = const LinearGradient(
                colors: [
                  Color(0xFF1E88E5), // Azul mais forte
                  Color(0xFF38b6ff), // Azul médio
                  Color(0xFFf76cec), // Rosa
                ],
                stops: [0.0, 0.5, 1.0],
              ).createShader(const Rect.fromLTWH(0.0, 0.0, 300.0, 70.0)),
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 16),

        // Mensagem inspiradora
        Text(
          'Conecte-se com Deus Pai e encontre seu propósito',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Campo Email
          _buildTextField(
            label: 'Email',
            controller: LoginController.emailController,
            keyboardType: TextInputType.emailAddress,
            icon: Icons.email_outlined,
          ),

          const SizedBox(height: 20),

          // Campo Senha
          _buildTextField(
            label: 'Senha',
            controller: LoginController.senhaController,
            isPassword: true,
            icon: Icons.lock_outline,
          ),

          const SizedBox(height: 24),

          // Botão de login
          _buildGradientButton(
            onPressed: () => LoginController.validadeLogin(),
            text: 'Entrar',
            icon: Icons.login,
          ),
        ],
      ),
    );
  }

  Widget _buildCadastroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Campo Nome
          _buildTextField(
            label: 'Nome',
            controller: LoginController.nomeController,
            keyboardType: TextInputType.name,
            icon: Icons.person_outline,
          ),

          const SizedBox(height: 20),

          // Campo Email
          _buildTextField(
            label: 'Email',
            controller: LoginController.emailController,
            keyboardType: TextInputType.emailAddress,
            icon: Icons.email_outlined,
          ),

          const SizedBox(height: 20),

          // Campo Senha
          _buildTextField(
            label: 'Senha',
            controller: LoginController.senhaController,
            isPassword: true,
            icon: Icons.lock_outline,
          ),

          const SizedBox(height: 20),

          // Campo Confirmar Senha
          _buildTextField(
            label: 'Confirmar Senha',
            controller: LoginController.senha2Controller,
            isPassword: true,
            icon: Icons.lock_outline,
          ),

          const SizedBox(height: 24),

          // Widget de aceite dos termos
          TermsAcceptanceWidget(
            termsAccepted: termsAccepted,
            privacyAccepted: privacyAccepted,
          ),

          const SizedBox(height: 24),

          // Botão de cadastro
          Obx(() => _buildGradientButton(
                onPressed: (termsAccepted.value && privacyAccepted.value)
                    ? () => LoginController.validadeCadastro()
                    : () => _showTermsAlert(),
                text: 'Criar Conta',
                icon: Icons.person_add,
                isEnabled: termsAccepted.value && privacyAccepted.value,
              )),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool isPassword = false,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            color: Colors.grey.shade50,
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: isPassword,
            style: GoogleFonts.poppins(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Digite seu $label',
              hintStyle: GoogleFonts.poppins(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
              prefixIcon: Icon(icon, color: Colors.grey.shade500),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGradientButton({
    required VoidCallback onPressed,
    required String text,
    required IconData icon,
    bool isEnabled = true,
  }) {
    return Container(
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: isEnabled
            ? const LinearGradient(
                colors: [
                  Color(0xFF1E88E5), // Azul mais forte
                  Color(0xFF38b6ff), // Azul médio
                  Color(0xFFf76cec), // Rosa
                ],
                stops: [0.0, 0.6, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  Colors.grey.shade400,
                  Colors.grey.shade400,
                ],
              ),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: const Color(0xFF38b6ff).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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

  Widget _buildSwitchLink(
      String question, String linkText, VoidCallback onTap) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF38b6ff).withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            question,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              linkText,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                foreground: Paint()
                  ..shader = const LinearGradient(
                    colors: [
                      Color(0xFF1E88E5), // Azul mais forte
                      Color(0xFF38b6ff), // Azul médio
                      Color(0xFFf76cec), // Rosa
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ).createShader(const Rect.fromLTWH(0.0, 0.0, 250.0, 70.0)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
