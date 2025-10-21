
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '/token_usuario.dart';
import '/views/home_view.dart';
import '/views/login_view.dart';
import '/locale/language.dart';
import '/constants.dart';
import '/models/usuario_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SelectLanguageView extends StatefulWidget {
const SelectLanguageView({ Key? key }) : super(key: key);

  @override
  State<SelectLanguageView> createState() => _SelectLanguageViewState();
}

class _SelectLanguageViewState extends State<SelectLanguageView> {
  String idioma = '';
  UserSexo? sexo;

  @override
  Widget build(BuildContext context){
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
              Colors.white,             // Branco
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
                
                // Header com logo e títulos
                _buildHeader(),
                
                SizedBox(height: Get.height * 0.08),
                
                // Card principal com seleção de idioma
                _buildLanguageCard(),
                
                SizedBox(height: Get.height * 0.04),
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
          child: Image.asset('lib/assets/img/logo.png', width: Get.width * 0.25),
        ),
        
        const SizedBox(height: 24),
        
        // Título principal
        Text(
          AppLanguage.lang('bem_vindo_ao', idioma: idioma),
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8),
        
        // Nome do app
        Text(
          Constants.appName,
          style: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..shader = const LinearGradient(
                colors: [
                  Color(0xFF38b6ff),
                  Color(0xFFf76cec),
                ],
              ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
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
            foreground: Paint()
              ..shader = const LinearGradient(
                colors: [
                  Color(0xFF38b6ff),
                  Color(0xFFf76cec),
                ],
              ).createShader(const Rect.fromLTWH(0.0, 0.0, 300.0, 70.0)),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLanguageCard() {
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
            'Selecione seu idioma',
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
            AppLanguage.lang('para_continuar', idioma: idioma),
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Dropdown de idiomas
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              color: Colors.grey.shade50,
            ),
            child: DropdownButton<String>(
              value: idioma.isEmpty ? null : idioma,
              icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade500),
              hint: Text(
                AppLanguage.lang('selecionar_idioma', idioma: idioma),
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade500,
                  fontSize: 16,
                ),
              ),
              underline: const SizedBox(),
              isExpanded: true,
              onChanged: (String? value) {
                setState(() {
                  idioma = value!;
                });
              },
              items: AppLanguage.languages().map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Text(
                          AppLanguage.lang('${value}Flag', idioma: idioma),
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          AppLanguage.lang(value, idioma: idioma),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Seleção de sexo
          Text(
            'Selecione seu sexo',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Dropdown de sexo
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              color: Colors.grey.shade50,
            ),
            child: DropdownButton<UserSexo>(
              value: sexo,
              icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade500),
              hint: Text(
                'Selecionar sexo',
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade500,
                  fontSize: 16,
                ),
              ),
              underline: const SizedBox(),
              isExpanded: true,
              onChanged: (UserSexo? value) {
                setState(() {
                  sexo = value;
                });
              },
              items: [
                DropdownMenuItem<UserSexo>(
                  value: UserSexo.feminino,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.female, color: Colors.pink, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Feminino',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                DropdownMenuItem<UserSexo>(
                  value: UserSexo.masculino,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.male, color: Colors.blue, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Masculino',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Botão continuar
          _buildContinueButton(),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return Container(
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: (idioma.isNotEmpty && sexo != null)
          ? const LinearGradient(
              colors: [
                Color(0xFF38b6ff),
                Color(0xFFf76cec),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : LinearGradient(
              colors: [
                Colors.grey.shade400,
                Colors.grey.shade400,
              ],
            ),
        boxShadow: (idioma.isNotEmpty && sexo != null) 
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
          onTap: () {
            if(idioma.isEmpty) {
              Get.snackbar(
                'Idioma necessário',
                'Por favor, selecione um idioma para continuar.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.orange[100],
                colorText: Colors.orange[800],
                icon: Icon(Icons.language, color: Colors.orange[600]),
                duration: const Duration(seconds: 3),
                margin: const EdgeInsets.all(16),
                borderRadius: 8,
              );
              return;
            }
            
            if(sexo == null) {
              Get.snackbar(
                'Sexo necessário',
                'Por favor, selecione seu sexo para continuar.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.orange[100],
                colorText: Colors.orange[800],
                icon: Icon(Icons.person, color: Colors.orange[600]),
                duration: const Duration(seconds: 3),
                margin: const EdgeInsets.all(16),
                borderRadius: 8,
              );
              return;
            }
            
            // Salvar idioma e sexo
            TokenUsuario().idioma = idioma;
            TokenUsuario().sexo = sexo!;
            
            if(FirebaseAuth.instance.currentUser == null) {
              Get.offAll(() => const LoginView());
            } else {
              Get.offAll(() => const HomeView());
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  AppLanguage.lang('continuar', idioma: idioma),
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
}