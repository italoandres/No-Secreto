import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/token_usuario.dart';
import '/views/select_language_view.dart';
import '/views/onboarding_view.dart';
import '/views/login_view.dart';
import '/views/home_view.dart';

class AppWrapper extends StatefulWidget {
  const AppWrapper({Key? key}) : super(key: key);

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  bool? _isFirstTime;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    try {
      // Adicionar delay para evitar travamento na inicialização
      await Future.delayed(const Duration(milliseconds: 100));

      final prefs = await SharedPreferences.getInstance();
      // Verificar se é primeira vez normalmente
      final isFirstTime = prefs.getBool('first_time') ?? true;

      if (mounted) {
        setState(() {
          _isFirstTime = isFirstTime;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('AppWrapper: Erro ao verificar primeira vez: $e');
      if (mounted) {
        setState(() {
          _isFirstTime = true; // Fallback para onboarding
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('AppWrapper: _isLoading=$_isLoading, _isFirstTime=$_isFirstTime');

    if (_isLoading) {
      print('AppWrapper: Mostrando loading');
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Carregando...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Se é a primeira vez, mostra onboarding
    if (_isFirstTime == true) {
      print('AppWrapper: Mostrando OnboardingView');
      return const OnboardingView();
    }

    // Fluxo normal do app
    print('AppWrapper: Mostrando fluxo normal do app');
    return TokenUsuario().idioma.isEmpty
        ? const SelectLanguageView()
        : (FirebaseAuth.instance.currentUser == null
            ? const LoginView()
            : const HomeView());
  }
}
