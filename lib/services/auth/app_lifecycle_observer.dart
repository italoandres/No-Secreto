import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'biometric_auth_service.dart';
import '../../views/auth/app_lock_screen.dart';

/// Observer para detectar quando app vai para background/foreground
class AppLifecycleObserver extends WidgetsBindingObserver {
  final BiometricAuthService _authService = BiometricAuthService();
  DateTime? _backgroundTime;
  bool _isShowingLockScreen = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        // App foi para background
        _backgroundTime = DateTime.now();
        break;

      case AppLifecycleState.resumed:
        // App voltou para foreground
        _checkIfAuthNeeded();
        break;

      default:
        break;
    }
  }

  void _checkIfAuthNeeded() async {
    // Evitar mostrar múltiplas telas de bloqueio
    if (_isShowingLockScreen) return;

    // Verificar se proteção está ativada
    final isEnabled = await _authService.isAppLockEnabled();
    if (!isEnabled) return;

    // Verificar se precisa autenticar baseado no timeout
    final needsAuth = await _authService.needsAuthentication();

    if (needsAuth && _backgroundTime != null) {
      final duration = DateTime.now().difference(_backgroundTime!);
      final timeoutMinutes = await _authService.getTimeoutMinutes();

      if (duration.inMinutes >= timeoutMinutes) {
        _showAuthScreen();
      }
    }
  }

  void _showAuthScreen() {
    if (_isShowingLockScreen) return;

    _isShowingLockScreen = true;

    // Mostrar tela de bloqueio como dialog fullscreen
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false, // Impedir voltar sem autenticar
        child: AppLockScreen(
          onAuthenticated: () {
            _isShowingLockScreen = false;
            Get.back(); // Fechar dialog
          },
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Método para mostrar tela de autenticação manualmente (ex: ao abrir app)
  static Future<void> showAuthScreenIfNeeded() async {
    final authService = BiometricAuthService();

    // Verificar se proteção está ativada
    final isEnabled = await authService.isAppLockEnabled();
    if (!isEnabled) return;

    // Verificar se precisa autenticar
    final needsAuth = await authService.needsAuthentication();
    if (!needsAuth) return;

    // Mostrar tela de bloqueio
    await Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: AppLockScreen(
          onAuthenticated: () {
            Get.back();
          },
        ),
      ),
      barrierDismissible: false,
    );
  }
}
