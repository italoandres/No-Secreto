import 'package:whatsapp_chat/locale/language.dart';
import 'package:whatsapp_chat/widgets/terms_acceptance_widget.dart';
import 'package:google_fonts/google_fonts.dart';

import '/constants.dart';
import '/views/login_com_email_view.dart';
import '/repositories/login_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  PageController pageController = PageController();
  final indexPage = 0.obs;
  final termos = true.obs;
  final termsAccepted = false.obs;
  final privacyAccepted = false.obs;

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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                SizedBox(height: Get.height * 0.08),

                // Logo e título modernos
                _buildHeader(),

                SizedBox(height: Get.height * 0.06),

                // Card principal com conteúdo
                _buildMainCard(),

                SizedBox(height: Get.height * 0.04),

                // Link para criar conta
                _buildCreateAccountLink(),

                SizedBox(height: Get.height * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo com efeito de sombra
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                const Color(0xFF38b6ff).withOpacity(0.1),
                const Color(0xFFf76cec).withOpacity(0.1),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF38b6ff).withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child:
              Image.asset('lib/assets/img/logo.png', width: Get.width * 0.25),
        ),

        const SizedBox(height: 24),

        // Título principal
        Text(
          'No secreto com Deus Pai',
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
        ),

        const SizedBox(height: 8),

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

  Widget _buildMainCard() {
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
          // Título do card
          Text(
            'Bem-vindo de volta!',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              foreground: Paint()
                ..shader = const LinearGradient(
                  colors: [
                    Color(0xFF38b6ff),
                    Color(0xFFf76cec),
                  ],
                ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            AppLanguage.lang('como_continuar'),
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 24),

          // Widget de aceite dos termos
          TermsAcceptanceWidget(
            termsAccepted: termsAccepted,
            privacyAccepted: privacyAccepted,
          ),

          const SizedBox(height: 24),

          // Botões de login modernos
          _buildLoginButtons(),
        ],
      ),
    );
  }

  Widget _buildLoginButtons() {
    return Column(
      children: [
        // Botão Google
        Obx(() => _buildSocialButton(
              onPressed: (termsAccepted.value && privacyAccepted.value)
                  ? () => LoginRepository.loginComGoogle()
                  : () => _showTermsAlert(),
              icon: Image.asset('lib/assets/img/google.png', width: 24),
              text: AppLanguage.lang('entrar_com_google'),
              backgroundColor: Colors.white,
              textColor: Colors.grey.shade700,
              borderColor: Colors.grey.shade300,
              enabled: termsAccepted.value && privacyAccepted.value,
            )),

        const SizedBox(height: 12),

        // Botão Apple
        Obx(() => _buildSocialButton(
              onPressed: (termsAccepted.value && privacyAccepted.value)
                  ? () => LoginRepository.loginComApple()
                  : () => _showTermsAlert(),
              icon: Image.asset('lib/assets/img/apple-logo.png',
                  width: 24, color: Colors.white),
              text: AppLanguage.lang('entrar_com_apple'),
              backgroundColor: Colors.black,
              textColor: Colors.white,
              enabled: termsAccepted.value && privacyAccepted.value,
            )),

        const SizedBox(height: 16),

        // Divisor
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade300)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'ou',
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey.shade300)),
          ],
        ),

        const SizedBox(height: 16),

        // Botão Email com gradiente
        Obx(() => _buildGradientButton(
              onPressed: (termsAccepted.value && privacyAccepted.value)
                  ? () => Get.to(() => const LoginComEmailView(isLogin: true))
                  : () => _showTermsAlert(),
              icon: Icons.email_outlined,
              text: 'Acessar sua conta',
              enabled: termsAccepted.value && privacyAccepted.value,
            )),
      ],
    );
  }

  Widget _buildSocialButton({
    required VoidCallback onPressed,
    required Widget icon,
    required String text,
    required Color backgroundColor,
    required Color textColor,
    Color? borderColor,
    required bool enabled,
  }) {
    return Container(
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? backgroundColor : Colors.grey.shade200,
          foregroundColor: enabled ? textColor : Colors.grey.shade400,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: borderColor != null
                ? BorderSide(
                    color: enabled ? borderColor : Colors.grey.shade300)
                : BorderSide.none,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String text,
    required bool enabled,
  }) {
    return Container(
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: enabled
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
            : null,
        color: enabled ? null : Colors.grey.shade200,
        boxShadow: enabled
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
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: enabled ? Colors.white : Colors.grey.shade400,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: enabled ? Colors.white : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateAccountLink() {
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
            'Ainda não tem uma conta?',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Obx(() => TextButton(
                onPressed: (termsAccepted.value && privacyAccepted.value)
                    ? () =>
                        Get.to(() => const LoginComEmailView(isLogin: false))
                    : () => _showTermsAlert(),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  'Criar conta com email',
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
                      ).createShader(
                          const Rect.fromLTWH(0.0, 0.0, 250.0, 70.0)),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
