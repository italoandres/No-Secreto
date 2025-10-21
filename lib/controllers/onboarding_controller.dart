import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/onboarding_model.dart';
import '../token_usuario.dart';
import '../views/select_language_view.dart';
import '../views/login_view.dart';

class OnboardingController extends GetxController {
  final PageController pageController = PageController();
  final RxInt currentIndex = 0.obs;
  final RxBool showArrow = false.obs;
  Timer? _arrowTimer;
  
  final List<OnboardingModel> slides = [
    OnboardingModel(
      title: "",
      description: "",
      assetPath: "lib/assets/onboarding/slide1.gif",
      isVideo: true,
    ),
    OnboardingModel(
      title: "",
      description: "",
      assetPath: "lib/assets/onboarding/slide2.gif",
      isVideo: true,
    ),
    OnboardingModel(
      title: "",
      description: "",
      assetPath: "lib/assets/onboarding/slide3.gif",
      isVideo: true,
    ),
    OnboardingModel(
      title: "",
      description: "",
      assetPath: "lib/assets/onboarding/slide4.gif",
      isVideo: true,
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    print('OnboardingController: Iniciado com ${slides.length} slides');
    startArrowTimer();
  }

  void startArrowTimer() {
    // Cancelar timer anterior para evitar múltiplos timers
    _arrowTimer?.cancel();
    
    print('OnboardingController: Resetando seta no slide ${currentIndex.value}');
    showArrow.value = false;
    
    // A seta será mostrada pelo widget _NonLoopingGif quando a animação terminar
    // Não precisamos mais de timer automático aqui
  }

  void nextSlide() {
    if (currentIndex.value < slides.length - 1) {
      currentIndex.value++;
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      startArrowTimer(); // Reinicia o timer para o próximo slide
    } else {
      // Último slide - ir para login
      finishOnboarding();
    }
  }

  void previousSlide() {
    if (currentIndex.value > 0) {
      currentIndex.value--;
      pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      startArrowTimer(); // Reinicia o timer
    }
  }

  void goToSlide(int index) {
    currentIndex.value = index;
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    startArrowTimer(); // Reinicia o timer
  }

  void finishOnboarding() async {
    // Salvar que o usuário já viu o onboarding
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_time', false);
    
    // Navegar para o próximo fluxo (seleção de idioma ou login)
    Get.offAll(() => TokenUsuario().idioma.isEmpty 
        ? const SelectLanguageView() 
        : const LoginView());
  }

  @override
  void onClose() {
    _arrowTimer?.cancel();
    pageController.dispose();
    super.onClose();
  }
}