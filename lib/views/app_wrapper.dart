import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/token_usuario.dart';
import '/views/select_language_view.dart';
import '/views/onboarding_view.dart';
import '/views/login_view.dart';
import '/views/home_view.dart';
import '/utils/debug_utils.dart';
import '/services/auth/app_lifecycle_observer.dart';
import '/services/auth/biometric_auth_service.dart';

class AppWrapper extends StatefulWidget {
  const AppWrapper({Key? key}) : super(key: key);

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  bool? _isFirstTime;
  bool _isLoading = true;
  final AppLifecycleObserver _lifecycleObserver = AppLifecycleObserver();

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
    // Adicionar observer para detectar background/foreground
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
  }

  @override
  void dispose() {
    // Remover observer ao destruir widget
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
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
      safePrint('AppWrapper: Erro ao verificar primeira vez: $e');
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
    safePrint('AppWrapper: _isLoading=$_isLoading, _isFirstTime=$_isFirstTime');

    if (_isLoading) {
      safePrint('AppWrapper: Mostrando loading');
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
      safePrint('AppWrapper: Mostrando OnboardingView');
      return const OnboardingView();
    }

    // Fluxo normal do app com AuthGate
    safePrint('AppWrapper: Mostrando fluxo normal do app');
    
    // Se não tem idioma selecionado, vai para seleção de idioma
    if (TokenUsuario().idioma.isEmpty) {
      return const SelectLanguageView();
    }
    
    // AuthGate: Garante que só acessa HomeView quando autenticado
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Ainda verificando autenticação
        if (snapshot.connectionState == ConnectionState.waiting) {
          safePrint('AppWrapper: Aguardando confirmação de autenticação');
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Verificando autenticação...',
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
        
        // 2. Usuário autenticado - pode acessar HomeView
        if (snapshot.hasData && snapshot.data != null) {
          safePrint('AppWrapper: Usuário autenticado, mostrando HomeView');
          // Verificar se precisa mostrar tela de autenticação
          WidgetsBinding.instance.addPostFrameCallback((_) {
            AppLifecycleObserver.showAuthScreenIfNeeded();
          });
          return const HomeView();
        }
        
        // 3. Não autenticado - vai para login
        safePrint('AppWrapper: Usuário não autenticado, mostrando LoginView');
        return const LoginView();
      },
    );
  }
}
