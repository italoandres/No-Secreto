import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/enhanced_logger.dart';

/// Tipos de operações de loading
enum LoadingType {
  loadingMatches,
  loadingMessages,
  sendingMessage,
  markingAsRead,
  creatingChat,
  loadingProfile,
  refreshing,
  retrying,
}

/// Estado de loading para uma operação específica
class LoadingState {
  final LoadingType type;
  final bool isLoading;
  final String? message;
  final DateTime timestamp;
  final String? operationId;

  LoadingState({
    required this.type,
    required this.isLoading,
    this.message,
    DateTime? timestamp,
    this.operationId,
  }) : timestamp = timestamp ?? DateTime.now();

  LoadingState copyWith({
    LoadingType? type,
    bool? isLoading,
    String? message,
    DateTime? timestamp,
    String? operationId,
  }) {
    return LoadingState(
      type: type ?? this.type,
      isLoading: isLoading ?? this.isLoading,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      operationId: operationId ?? this.operationId,
    );
  }

  @override
  String toString() {
    return 'LoadingState(type: $type, isLoading: $isLoading, message: $message)';
  }
}

/// Gerenciador centralizado de estados de loading
class MatchLoadingManager extends GetxController {
  static MatchLoadingManager get instance => Get.find<MatchLoadingManager>();

  final RxMap<LoadingType, LoadingState> _loadingStates =
      <LoadingType, LoadingState>{}.obs;
  final RxBool _hasAnyLoading = false.obs;

  /// Verificar se uma operação específica está carregando
  bool isLoading(LoadingType type) {
    return _loadingStates[type]?.isLoading ?? false;
  }

  /// Verificar se há qualquer operação carregando
  bool get hasAnyLoading => _hasAnyLoading.value;

  /// Obter estado de loading específico
  LoadingState? getLoadingState(LoadingType type) {
    return _loadingStates[type];
  }

  /// Obter mensagem de loading específica
  String? getLoadingMessage(LoadingType type) {
    return _loadingStates[type]?.message;
  }

  /// Iniciar loading para uma operação
  void startLoading(
    LoadingType type, {
    String? message,
    String? operationId,
  }) {
    final state = LoadingState(
      type: type,
      isLoading: true,
      message: message ?? _getDefaultMessage(type),
      operationId: operationId,
    );

    _loadingStates[type] = state;
    _updateHasAnyLoading();

    EnhancedLogger.debug(
      'Loading started: ${type.toString()} - ${state.message}',
      tag: 'MATCH_LOADING',
    );
  }

  /// Parar loading para uma operação
  void stopLoading(LoadingType type) {
    if (_loadingStates.containsKey(type)) {
      final currentState = _loadingStates[type]!;
      _loadingStates[type] = currentState.copyWith(isLoading: false);
      _updateHasAnyLoading();

      EnhancedLogger.debug(
        'Loading stopped: ${type.toString()}',
        tag: 'MATCH_LOADING',
      );
    }
  }

  /// Parar todos os loadings
  void stopAllLoading() {
    for (final type in _loadingStates.keys.toList()) {
      stopLoading(type);
    }
    EnhancedLogger.debug('All loading stopped', tag: 'MATCH_LOADING');
  }

  /// Atualizar mensagem de loading
  void updateLoadingMessage(LoadingType type, String message) {
    if (_loadingStates.containsKey(type)) {
      final currentState = _loadingStates[type]!;
      _loadingStates[type] = currentState.copyWith(message: message);
    }
  }

  /// Executar operação com loading automático
  Future<T> withLoading<T>(
    LoadingType type,
    Future<T> Function() operation, {
    String? message,
    String? operationId,
    Duration? timeout,
  }) async {
    startLoading(type, message: message, operationId: operationId);

    try {
      final result = timeout != null
          ? await operation().timeout(timeout)
          : await operation();

      stopLoading(type);
      return result;
    } catch (error) {
      stopLoading(type);
      rethrow;
    }
  }

  /// Executar múltiplas operações com loading
  Future<List<T>> withMultipleLoading<T>(
    List<LoadingType> types,
    List<Future<T> Function()> operations, {
    List<String>? messages,
  }) async {
    assert(types.length == operations.length,
        'Types and operations must have same length');

    // Iniciar todos os loadings
    for (int i = 0; i < types.length; i++) {
      startLoading(
        types[i],
        message: messages?[i],
      );
    }

    try {
      final results = await Future.wait(
        operations.map((op) => op()).toList(),
      );

      // Parar todos os loadings
      for (final type in types) {
        stopLoading(type);
      }

      return results;
    } catch (error) {
      // Parar todos os loadings em caso de erro
      for (final type in types) {
        stopLoading(type);
      }
      rethrow;
    }
  }

  /// Atualizar flag de "tem algum loading"
  void _updateHasAnyLoading() {
    final hasLoading = _loadingStates.values.any((state) => state.isLoading);
    _hasAnyLoading.value = hasLoading;
  }

  /// Obter mensagem padrão para cada tipo de loading
  String _getDefaultMessage(LoadingType type) {
    switch (type) {
      case LoadingType.loadingMatches:
        return 'Carregando matches...';
      case LoadingType.loadingMessages:
        return 'Carregando mensagens...';
      case LoadingType.sendingMessage:
        return 'Enviando mensagem...';
      case LoadingType.markingAsRead:
        return 'Marcando como lida...';
      case LoadingType.creatingChat:
        return 'Criando chat...';
      case LoadingType.loadingProfile:
        return 'Carregando perfil...';
      case LoadingType.refreshing:
        return 'Atualizando...';
      case LoadingType.retrying:
        return 'Tentando novamente...';
    }
  }

  /// Obter todos os estados de loading ativos
  Map<LoadingType, LoadingState> getActiveLoadingStates() {
    return Map.fromEntries(
      _loadingStates.entries.where((entry) => entry.value.isLoading),
    );
  }

  /// Obter estatísticas de loading
  Map<String, dynamic> getLoadingStats() {
    final activeStates = getActiveLoadingStates();
    final totalOperations = _loadingStates.length;
    final activeOperations = activeStates.length;

    return {
      'totalOperations': totalOperations,
      'activeOperations': activeOperations,
      'hasAnyLoading': hasAnyLoading,
      'activeTypes': activeStates.keys.map((k) => k.toString()).toList(),
      'longestRunning': _getLongestRunningOperation(),
    };
  }

  /// Obter operação que está rodando há mais tempo
  String? _getLongestRunningOperation() {
    final activeStates = getActiveLoadingStates();
    if (activeStates.isEmpty) return null;

    final oldest = activeStates.values
        .reduce((a, b) => a.timestamp.isBefore(b.timestamp) ? a : b);

    final duration = DateTime.now().difference(oldest.timestamp);
    return '${oldest.type.toString()} (${duration.inSeconds}s)';
  }

  /// Stream para observar mudanças em loading específico
  Stream<bool> watchLoading(LoadingType type) {
    return _loadingStates.stream
        .map((states) => states[type]?.isLoading ?? false);
  }

  /// Stream para observar se há qualquer loading
  Stream<bool> get watchAnyLoading => _hasAnyLoading.stream;

  /// Limpar estados antigos (mais de 1 hora)
  void cleanupOldStates() {
    final cutoff = DateTime.now().subtract(const Duration(hours: 1));
    final toRemove = <LoadingType>[];

    for (final entry in _loadingStates.entries) {
      if (!entry.value.isLoading && entry.value.timestamp.isBefore(cutoff)) {
        toRemove.add(entry.key);
      }
    }

    for (final type in toRemove) {
      _loadingStates.remove(type);
    }

    if (toRemove.isNotEmpty) {
      EnhancedLogger.debug(
        'Cleaned up ${toRemove.length} old loading states',
        tag: 'MATCH_LOADING',
      );
    }
  }

  @override
  void onInit() {
    super.onInit();

    // Limpar estados antigos periodicamente
    ever(_hasAnyLoading, (hasLoading) {
      if (!hasLoading) {
        Future.delayed(const Duration(minutes: 5), cleanupOldStates);
      }
    });
  }
}

/// Widget para exibir loading com mensagem
class MatchLoadingWidget extends StatelessWidget {
  final LoadingType type;
  final Widget? child;
  final String? customMessage;
  final bool showMessage;
  final Color? color;
  final double? size;

  const MatchLoadingWidget({
    super.key,
    required this.type,
    this.child,
    this.customMessage,
    this.showMessage = true,
    this.color,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MatchLoadingManager>(
      builder: (manager) {
        final isLoading = manager.isLoading(type);
        final message = customMessage ?? manager.getLoadingMessage(type);

        if (!isLoading && child != null) {
          return child!;
        }

        if (!isLoading) {
          return const SizedBox.shrink();
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: size ?? 24,
              height: size ?? 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  color ?? Theme.of(context).primaryColor,
                ),
              ),
            ),
            if (showMessage && message != null) ...[
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Widget para overlay de loading em tela cheia
class MatchLoadingOverlay extends StatelessWidget {
  final LoadingType type;
  final Widget child;
  final String? customMessage;
  final Color? backgroundColor;

  const MatchLoadingOverlay({
    super.key,
    required this.type,
    required this.child,
    this.customMessage,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MatchLoadingManager>(
      builder: (manager) {
        final isLoading = manager.isLoading(type);
        final message = customMessage ?? manager.getLoadingMessage(type);

        return Stack(
          children: [
            child,
            if (isLoading)
              Container(
                color: backgroundColor ?? Colors.black.withOpacity(0.3),
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          if (message != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              message,
                              style: const TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
