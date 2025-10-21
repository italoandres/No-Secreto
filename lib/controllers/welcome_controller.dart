import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../views/home_view.dart';

class WelcomeController extends GetxController {
  final PageController pageController = PageController();
  final RxBool showArrow = false.obs;
  Timer? _arrowTimer;
  
  @override
  void onInit() {
    super.onInit();
    print('WelcomeController: Iniciado - slide de boas-vindas');
    startArrowTimer();
  }

  void startArrowTimer() {
    showArrow.value = false;
    _arrowTimer?.cancel();
    _arrowTimer = Timer(const Duration(seconds: 8), () {
      print('WelcomeController: Mostrando seta de boas-vindas');
      showArrow.value = true;
    });
  }

  void finishWelcome() async {
    // Salvar que o usuário já viu o slide de boas-vindas
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('welcome_shown', true);
    
    print('WelcomeController: Finalizando boas-vindas, indo para HomeView');
    // Navegar para o app principal
    Get.offAll(() => const HomeView());
  }

  @override
  void onClose() {
    _arrowTimer?.cancel();
    pageController.dispose();
    super.onClose();
  }
}