import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/welcome_controller.dart';

class WelcomeView extends StatelessWidget {
  const WelcomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(WelcomeController());
    
    print('WelcomeView: Construindo view de boas-vindas');
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // GIF de boas-vindas em tela cheia
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Image.asset(
              'lib/assets/onboarding/slide5.gif',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                print('WelcomeView: Erro ao carregar slide5.gif: $error');
                return Container(
                  color: Colors.blue[900],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.waving_hand, size: 100, color: Colors.white),
                        const SizedBox(height: 20),
                        Text(
                          'Bem-vindo!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Toque para continuar',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'ERRO: slide5.gif não encontrado',
                          style: TextStyle(
                            color: Colors.red[300],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Coloque o arquivo em: lib/assets/onboarding/slide5.gif',
                          style: TextStyle(
                            color: Colors.red[200],
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Toque em qualquer lugar para continuar
          Positioned.fill(
            child: GestureDetector(
              onTap: controller.finishWelcome,
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          
          // Seta moderna no canto inferior direito
          Positioned(
            bottom: 50,
            right: 30,
            child: Obx(() => AnimatedOpacity(
              opacity: controller.showArrow.value ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: controller.showArrow.value
                ? AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: GestureDetector(
                      onTap: controller.finishWelcome,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios,
                          color: Color(0xFF22bc88),
                          size: 24,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            )),
          ),
          
          // Texto "Toque para continuar" no canto inferior esquerdo
          Positioned(
            bottom: 60,
            left: 30,
            child: Obx(() => AnimatedOpacity(
              opacity: controller.showArrow.value ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: Text(
                'Toque para continuar',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            )),
          ),
        ],
      ),
    );
  }
}