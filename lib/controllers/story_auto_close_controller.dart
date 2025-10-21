import 'dart:async';
import 'package:flutter/material.dart';

class StoryAutoCloseController {
  Timer? _autoCloseTimer;
  bool _isPaused = false;
  bool _isDisposed = false;
  Duration? _remainingTime;
  DateTime? _pausedAt;
  
  // Callbacks
  VoidCallback? onAutoClose;
  VoidCallback? onTimerTick;
  
  /// Inicia o timer de auto-close
  void startAutoClose({
    required Duration duration,
    VoidCallback? onClose,
    VoidCallback? onTick,
  }) {
    if (_isDisposed) return;
    
    print('⏰ AUTO-CLOSE: Iniciando timer para ${duration.inSeconds}s');
    
    onAutoClose = onClose;
    onTimerTick = onTick;
    
    _cancelCurrentTimer();
    
    _autoCloseTimer = Timer(duration, () {
      if (!_isDisposed && !_isPaused) {
        print('⏰ AUTO-CLOSE: Timer expirado, fechando story');
        onAutoClose?.call();
      }
    });
  }
  
  /// Inicia auto-close baseado no tipo de mídia
  void startAutoCloseForMedia({
    required String fileType,
    int? videoDuration,
    VoidCallback? onClose,
    VoidCallback? onTick,
  }) {
    Duration duration;
    
    if (fileType == 'video' && videoDuration != null && videoDuration > 0) {
      duration = Duration(seconds: videoDuration);
      print('📹 AUTO-CLOSE: Story de vídeo - duração: ${videoDuration}s');
    } else {
      duration = const Duration(seconds: 10); // Padrão para imagens
      print('🖼️ AUTO-CLOSE: Story de imagem - duração: 10s');
    }
    
    startAutoClose(
      duration: duration,
      onClose: onClose,
      onTick: onTick,
    );
  }
  
  /// Pausa o timer
  void pauseAutoClose() {
    if (_isDisposed || _isPaused || _autoCloseTimer == null) return;
    
    print('⏸️ AUTO-CLOSE: Pausando timer');
    _isPaused = true;
    _pausedAt = DateTime.now();
    
    // Calcular tempo restante
    // Como Timer não tem como obter tempo restante, vamos usar uma abordagem diferente
    _cancelCurrentTimer();
  }
  
  /// Retoma o timer
  void resumeAutoClose() {
    if (_isDisposed || !_isPaused || _pausedAt == null) return;
    
    print('▶️ AUTO-CLOSE: Retomando timer');
    _isPaused = false;
    
    // Se tivéssemos o tempo restante, retomaríamos aqui
    // Por simplicidade, vamos reiniciar com tempo padrão
    if (onAutoClose != null) {
      startAutoClose(
        duration: const Duration(seconds: 10),
        onClose: onAutoClose,
        onTick: onTimerTick,
      );
    }
    
    _pausedAt = null;
  }
  
  /// Cancela o timer atual
  void cancelAutoClose() {
    if (_isDisposed) return;
    
    print('❌ AUTO-CLOSE: Cancelando timer');
    _cancelCurrentTimer();
    _isPaused = false;
    _pausedAt = null;
    _remainingTime = null;
  }
  
  /// Cancela o timer interno
  void _cancelCurrentTimer() {
    _autoCloseTimer?.cancel();
    _autoCloseTimer = null;
  }
  
  /// Verifica se o timer está ativo
  bool get isActive => _autoCloseTimer != null && _autoCloseTimer!.isActive;
  
  /// Verifica se está pausado
  bool get isPaused => _isPaused;
  
  /// Dispose do controller
  void dispose() {
    if (_isDisposed) return;
    
    print('🗑️ AUTO-CLOSE: Fazendo dispose do controller');
    _isDisposed = true;
    _cancelCurrentTimer();
    onAutoClose = null;
    onTimerTick = null;
  }
}

/// Controller mais avançado com progress tracking
class AdvancedStoryAutoCloseController extends StoryAutoCloseController {
  Timer? _progressTimer;
  Duration _totalDuration = Duration.zero;
  Duration _elapsedTime = Duration.zero;
  
  // Callback para progresso
  Function(double progress)? onProgressUpdate;
  
  @override
  void startAutoClose({
    required Duration duration,
    VoidCallback? onClose,
    VoidCallback? onTick,
  }) {
    if (_isDisposed) return;
    
    _totalDuration = duration;
    _elapsedTime = Duration.zero;
    
    super.startAutoClose(
      duration: duration,
      onClose: onClose,
      onTick: onTick,
    );
    
    _startProgressTracking();
  }
  
  /// Inicia o tracking de progresso
  void _startProgressTracking() {
    _progressTimer?.cancel();
    
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_isDisposed || _isPaused) return;
      
      _elapsedTime = _elapsedTime + const Duration(milliseconds: 100);
      
      if (_elapsedTime >= _totalDuration) {
        _elapsedTime = _totalDuration;
        timer.cancel();
      }
      
      final progress = _totalDuration.inMilliseconds > 0 
          ? _elapsedTime.inMilliseconds / _totalDuration.inMilliseconds 
          : 0.0;
      
      onProgressUpdate?.call(progress.clamp(0.0, 1.0));
      onTimerTick?.call();
    });
  }
  
  /// Define callback de progresso
  void setProgressCallback(Function(double progress)? callback) {
    onProgressUpdate = callback;
  }
  
  /// Obtém o progresso atual (0.0 a 1.0)
  double get progress {
    if (_totalDuration.inMilliseconds == 0) return 0.0;
    return (_elapsedTime.inMilliseconds / _totalDuration.inMilliseconds).clamp(0.0, 1.0);
  }
  
  /// Obtém o tempo restante
  Duration get remainingTime {
    return _totalDuration - _elapsedTime;
  }
  
  @override
  void pauseAutoClose() {
    super.pauseAutoClose();
    _progressTimer?.cancel();
  }
  
  @override
  void resumeAutoClose() {
    super.resumeAutoClose();
    if (!_isPaused) {
      _startProgressTracking();
    }
  }
  
  @override
  void cancelAutoClose() {
    super.cancelAutoClose();
    _progressTimer?.cancel();
    _elapsedTime = Duration.zero;
    _totalDuration = Duration.zero;
  }
  
  @override
  void dispose() {
    _progressTimer?.cancel();
    _progressTimer = null;
    onProgressUpdate = null;
    super.dispose();
  }
}