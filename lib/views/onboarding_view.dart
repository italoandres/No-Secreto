import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/onboarding_controller.dart';

// Widget customizado para GIFs sem loop
class _NonLoopingGif extends StatefulWidget {
  final String assetPath;
  final VoidCallback? onAnimationComplete;
  
  const _NonLoopingGif({
    required this.assetPath,
    this.onAnimationComplete,
  });

  @override
  State<_NonLoopingGif> createState() => _NonLoopingGifState();
}

class _NonLoopingGifState extends State<_NonLoopingGif> with TickerProviderStateMixin {
  late AnimationController _controller;
  bool _hasCompleted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3), // Duração estimada do GIF
      vsync: this,
    );
    
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_hasCompleted) {
        _hasCompleted = true;
        widget.onAnimationComplete?.call();
      }
    });
    
    // Inicia a animação uma única vez
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Image.asset(
          widget.assetPath,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) return child;
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 300),
              child: child,
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.red[100],
              child: const Center(
                child: Icon(Icons.error, size: 64, color: Colors.red),
              ),
            );
          },
        );
      },
    );
  }
}

class OnboardingView extends StatelessWidget {
  const OnboardingView({Key? key}) : super(key: key);
  
  Future<void> _preloadImage(String assetPath) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Pequeno delay para evitar travamento
      // Simula carregamento da imagem
      return;
    } catch (e) {
      throw Exception('Erro ao carregar $assetPath: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OnboardingController());
    
    print('OnboardingView: Construindo view com ${controller.slides.length} slides');
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // PageView com os slides
          PageView.builder(
            controller: controller.pageController,
            onPageChanged: (index) {
              print('OnboardingView: Mudou para slide $index');
              controller.currentIndex.value = index;
              controller.startArrowTimer();
            },
            itemCount: controller.slides.length,
            itemBuilder: (context, index) {
              final slide = controller.slides[index];
              print('OnboardingView: Construindo slide $index - ${slide.assetPath}');
              
              return Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black,
                child: FutureBuilder(
                  future: _preloadImage(slide.assetPath),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }
                    
                    if (snapshot.hasError) {
                      print('OnboardingView: Erro ao carregar ${slide.assetPath}: ${snapshot.error}');
                      return Container(
                        color: Colors.red[100],
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error, size: 64, color: Colors.red[600]),
                              const SizedBox(height: 16),
                              Text('ERRO: GIF ${index + 1} não encontrado', 
                                 style: TextStyle(color: Colors.red[600], fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text('Arquivo: ${slide.assetPath}', 
                                 style: TextStyle(color: Colors.red[500], fontSize: 12)),
                            ],
                          ),
                        ),
                      );
                    }
                    
                    // Carregamento bem-sucedido - GIF sem loop
                    return _NonLoopingGif(
                      assetPath: slide.assetPath,
                      onAnimationComplete: () {
                        // Quando a animação termina, mostra a seta
                        controller.showArrow.value = true;
                      },
                    );
                  },
                ),
              );
            },
          ),
          
          // Botões de navegação
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Botão Voltar (só aparece a partir do slide 2)
                Padding(
                  padding: const EdgeInsets.only(left: 30),
                  child: controller.currentIndex.value > 0
                    ? AnimatedOpacity(
                        opacity: controller.showArrow.value ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 500),
                        child: GestureDetector(
                          onTap: controller.previousSlide,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios,
                              color: Color(0xFF22bc88),
                              size: 24,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox(width: 60), // Espaço vazio para manter alinhamento
                ),
                
                // Botão Avançar
                Padding(
                  padding: const EdgeInsets.only(right: 30),
                  child: AnimatedOpacity(
                    opacity: controller.showArrow.value ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: controller.showArrow.value
                      ? AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: GestureDetector(
                            onTap: controller.nextSlide,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
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
                  ),
                ),
              ],
            )),
          ),
          
          // Indicadores de página (pontos)
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                controller.slides.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: controller.currentIndex.value == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: controller.currentIndex.value == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            )),
          ),
          
          // Botão "Pular" no canto superior direito
          Positioned(
            top: 50,
            right: 20,
            child: SafeArea(
              child: TextButton(
                onPressed: controller.finishOnboarding,
                child: Text(
                  'Pular',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}