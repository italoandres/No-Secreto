import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/real_notification_model.dart';
import '../utils/enhanced_logger.dart';

/// Status de sincronização offline/online
enum SyncStatus {
  offline,
  syncing,
  synced,
  error
}

/// Dados de sincronização
class SyncData {
  final DateTime lastSync;
  final SyncStatus status;
  final int pendingChanges;
  final String? errorMessage;

  SyncData({
    required this.lastSync,
    required this.status,
    required this.pendingChanges,
    this.errorMessage,
  });

  Map<String, dynamic> toJson() => {
    'lastSync': lastSync.toIso8601String(),
    'status': status.toString(),
    'pendingChanges': pendingChanges,
    'errorMessage': errorMessage,
  };

  factory SyncData.fromJson(Map<String, dynamic> json) => SyncData(
    lastSync: DateTime.parse(json['lastSync']),
    status: SyncStatus.values.firstWhere(
      (s) => s.toString() == json['status'],
      orElse: () => SyncStatus.offline,
    ),
    pendingChanges: json['pendingChanges'] ?? 0,
    errorMessage: json['errorMessage'],
  );
}

/// Armazenamento local robusto para notificações
class NotificationLocalStorage {
  static final NotificationLocalStorage _instance = NotificationLocalStorage._internal();
  factory NotificationLocalStorage() => _instance;
  NotificationLocalStorage._internal();

  SharedPreferences? _prefs;
  final Map<String, List<RealNotificationModel>> _memoryCache = {};
  final Map<String, SyncData> _syncStatus = {};
  final Map<String, Timer> _autoSaveTimers = {};

  static const String _notificationsPrefix = 'notifications_';
  static const String _syncPrefix = 'sync_';
  static const String _backupPrefix = 'backup_';
  static const String _metadataPrefix = 'metadata_';

  /// Inicializa o armazenamento local
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      EnhancedLogger.log('📱 [LOCAL_STORAGE] Armazenamento local inicializado');
      
      // Carrega dados de sincronização
      await _loadSyncStatus();
      
      // Inicia limpeza automática
      _startAutomaticCleanup();
      
    } catch (e) {
      EnhancedLogger.log('❌ [LOCAL_STORAGE] Erro na inicialização: $e');
      throw Exception('Falha na inicialização do armazenamento local: $e');
    }
  }

  /// Salva notificações no armazenamento local
  Future<bool> saveNotifications(String userId, List<RealNotificationModel> notifications) async {
    try {
      await _ensureInitialized();
      
      EnhancedLogger.log('💾 [LOCAL_STORAGE] Salvando ${notifications.length} notificações para: $userId');
      
      // Converte para JSON
      final jsonData = notifications.map((n) => n.toJson()).toList();
      final jsonString = jsonEncode(jsonData);
      
      // Salva no SharedPreferences
      final key = '$_notificationsPrefix$userId';
      final success = await _prefs!.setString(key, jsonString);
      
      if (success) {
        // Atualiza cache em memória
        _memoryCache[userId] = List.from(notifications);
        
        // Salva metadata
        await _saveMetadata(userId, notifications.length);
        
        // Cria backup automático
        await _createBackup(userId, notifications);
        
        // Agenda auto-save
        _scheduleAutoSave(userId);
        
        EnhancedLogger.log('✅ [LOCAL_STORAGE] Notificações salvas com sucesso');
        return true;
      }
      
      return false;
      
    } catch (e) {
      EnhancedLogger.log('❌ [LOCAL_STORAGE] Erro ao salvar notificações: $e');
      return false;
    }
  }

  /// Carrega notificações do armazenamento local
  Future<List<RealNotificationModel>> loadNotifications(String userId) async {
    try {
      await _ensureInitialized();
      
      // Verifica cache em memória primeiro
      if (_memoryCache.containsKey(userId)) {
        EnhancedLogger.log('🧠 [LOCAL_STORAGE] Carregando do cache em memória: ${_memoryCache[userId]!.length} notificações');
        return List.from(_memoryCache[userId]!);
      }
      
      // Carrega do SharedPreferences
      final key = '$_notificationsPrefix$userId';
      final jsonString = _prefs!.getString(key);
      
      if (jsonString == null) {
        EnhancedLogger.log('📭 [LOCAL_STORAGE] Nenhuma notificação encontrada para: $userId');
        return [];
      }
      
      // Converte de JSON
      final jsonData = jsonDecode(jsonString) as List;
      final notifications = jsonData
          .map((json) => RealNotificationModel.fromJson(json))
          .toList();
      
      // Atualiza cache em memória
      _memoryCache[userId] = List.from(notifications);
      
      EnhancedLogger.log('📱 [LOCAL_STORAGE] Carregadas ${notifications.length} notificações do armazenamento');
      return notifications;
      
    } catch (e) {
      EnhancedLogger.log('❌ [LOCAL_STORAGE] Erro ao carregar notificações: $e');
      
      // Tenta recuperar do backup
      return await _recoverFromBackup(userId);
    }
  }

  /// Adiciona uma notificação ao armazenamento
  Future<bool> addNotification(String userId, RealNotificationModel notification) async {
    try {
      final currentNotifications = await loadNotifications(userId);
      
      // Verifica se já existe
      final exists = currentNotifications.any((n) => n.id == notification.id);
      if (exists) {
        EnhancedLogger.log('⚠️ [LOCAL_STORAGE] Notificação já existe: ${notification.id}');
        return true;
      }
      
      // Adiciona nova notificação
      currentNotifications.add(notification);
      
      // Salva lista atualizada
      return await saveNotifications(userId, currentNotifications);
      
    } catch (e) {
      EnhancedLogger.log('❌ [LOCAL_STORAGE] Erro ao adicionar notificação: $e');
      return false;
    }
  }

  /// Remove uma notificação do armazenamento
  Future<bool> removeNotification(String userId, String notificationId) async {
    try {
      final currentNotifications = await loadNotifications(userId);
      
      // Remove a notificação
      final initialCount = currentNotifications.length;
      currentNotifications.removeWhere((n) => n.id == notificationId);
      
      if (currentNotifications.length < initialCount) {
        // Salva lista atualizada
        return await saveNotifications(userId, currentNotifications);
      }
      
      return true;
      
    } catch (e) {
      EnhancedLogger.log('❌ [LOCAL_STORAGE] Erro ao remover notificação: $e');
      return false;
    }
  }

  /// Atualiza uma notificação no armazenamento
  Future<bool> updateNotification(String userId, RealNotificationModel notification) async {
    try {
      final currentNotifications = await loadNotifications(userId);
      
      // Encontra e atualiza a notificação
      final index = currentNotifications.indexWhere((n) => n.id == notification.id);
      if (index != -1) {
        currentNotifications[index] = notification;
        return await saveNotifications(userId, currentNotifications);
      }
      
      // Se não encontrou, adiciona como nova
      return await addNotification(userId, notification);
      
    } catch (e) {
      EnhancedLogger.log('❌ [LOCAL_STORAGE] Erro ao atualizar notificação: $e');
      return false;
    }
  }

  /// Limpa todas as notificações de um usuário
  Future<bool> clearNotifications(String userId) async {
    try {
      await _ensureInitialized();
      
      // Remove do SharedPreferences
      final key = '$_notificationsPrefix$userId';
      await _prefs!.remove(key);
      
      // Remove do cache em memória
      _memoryCache.remove(userId);
      
      // Remove metadata
      await _prefs!.remove('$_metadataPrefix$userId');
      
      // Remove backup
      await _prefs!.remove('$_backupPrefix$userId');
      
      // Remove status de sincronização
      _syncStatus.remove(userId);
      await _prefs!.remove('$_syncPrefix$userId');
      
      // Cancela auto-save
      _autoSaveTimers[userId]?.cancel();
      _autoSaveTimers.remove(userId);
      
      EnhancedLogger.log('🧹 [LOCAL_STORAGE] Notificações limpas para: $userId');
      return true;
      
    } catch (e) {
      EnhancedLogger.log('❌ [LOCAL_STORAGE] Erro ao limpar notificações: $e');
      return false;
    }
  }

  /// Obtém status de sincronização
  SyncData getSyncStatus(String userId) {
    return _syncStatus[userId] ?? SyncData(
      lastSync: DateTime.now().subtract(Duration(days: 1)),
      status: SyncStatus.offline,
      pendingChanges: 0,
    );
  }

  /// Atualiza status de sincronização
  Future<void> updateSyncStatus(String userId, SyncData syncData) async {
    try {
      await _ensureInitialized();
      
      _syncStatus[userId] = syncData;
      
      // Salva no SharedPreferences
      final key = '$_syncPrefix$userId';
      await _prefs!.setString(key, jsonEncode(syncData.toJson()));
      
      EnhancedLogger.log('🔄 [LOCAL_STORAGE] Status de sincronização atualizado: ${syncData.status}');
      
    } catch (e) {
      EnhancedLogger.log('❌ [LOCAL_STORAGE] Erro ao atualizar status de sincronização: $e');
    }
  }

  /// Verifica se há dados locais para um usuário
  Future<bool> hasLocalData(String userId) async {
    try {
      await _ensureInitialized();
      
      final key = '$_notificationsPrefix$userId';
      return _prefs!.containsKey(key);
      
    } catch (e) {
      EnhancedLogger.log('❌ [LOCAL_STORAGE] Erro ao verificar dados locais: $e');
      return false;
    }
  }

  /// Obtém tamanho dos dados armazenados
  Future<int> getStorageSize(String userId) async {
    try {
      await _ensureInitialized();
      
      final key = '$_notificationsPrefix$userId';
      final data = _prefs!.getString(key);
      
      return data?.length ?? 0;
      
    } catch (e) {
      EnhancedLogger.log('❌ [LOCAL_STORAGE] Erro ao obter tamanho do armazenamento: $e');
      return 0;
    }
  }

  /// Obtém estatísticas do armazenamento
  Future<Map<String, dynamic>> getStorageStats(String userId) async {
    try {
      final notifications = await loadNotifications(userId);
      final syncStatus = getSyncStatus(userId);
      final storageSize = await getStorageSize(userId);
      final hasBackup = await _hasBackup(userId);
      
      return {
        'notificationsCount': notifications.length,
        'storageSize': storageSize,
        'lastSync': syncStatus.lastSync.toIso8601String(),
        'syncStatus': syncStatus.status.toString(),
        'pendingChanges': syncStatus.pendingChanges,
        'hasBackup': hasBackup,
        'hasMemoryCache': _memoryCache.containsKey(userId),
        'memoryCacheSize': _memoryCache[userId]?.length ?? 0,
      };
      
    } catch (e) {
      EnhancedLogger.log('❌ [LOCAL_STORAGE] Erro ao obter estatísticas: $e');
      return {};
    }
  }

  /// Força sincronização de dados
  Future<bool> forceSync(String userId) async {
    try {
      EnhancedLogger.log('🔄 [LOCAL_STORAGE] Forçando sincronização para: $userId');
      
      // Atualiza status para sincronizando
      await updateSyncStatus(userId, SyncData(
        lastSync: DateTime.now(),
        status: SyncStatus.syncing,
        pendingChanges: 0,
      ));
      
      // Simula sincronização (em implementação real, seria com servidor)
      await Future.delayed(Duration(milliseconds: 500));
      
      // Atualiza status para sincronizado
      await updateSyncStatus(userId, SyncData(
        lastSync: DateTime.now(),
        status: SyncStatus.synced,
        pendingChanges: 0,
      ));
      
      EnhancedLogger.log('✅ [LOCAL_STORAGE] Sincronização concluída');
      return true;
      
    } catch (e) {
      EnhancedLogger.log('❌ [LOCAL_STORAGE] Erro na sincronização: $e');
      
      // Atualiza status para erro
      await updateSyncStatus(userId, SyncData(
        lastSync: DateTime.now(),
        status: SyncStatus.error,
        pendingChanges: 0,
        errorMessage: e.toString(),
      ));
      
      return false;
    }
  }

  /// Garante que o armazenamento está inicializado
  Future<void> _ensureInitialized() async {
    if (_prefs == null) {
      await initialize();
    }
  }

  /// Salva metadata das notificações
  Future<void> _saveMetadata(String userId, int count) async {
    try {
      final metadata = {
        'count': count,
        'lastUpdate': DateTime.now().toIso8601String(),
        'version': '1.0',
      };
      
      final key = '$_metadataPrefix$userId';
      await _prefs!.setString(key, jsonEncode(metadata));
      
    } catch (e) {
      EnhancedLogger.log('⚠️ [LOCAL_STORAGE] Erro ao salvar metadata: $e');
    }
  }

  /// Cria backup automático
  Future<void> _createBackup(String userId, List<RealNotificationModel> notifications) async {
    try {
      // Mantém apenas os últimos 50 para backup
      final backupData = notifications.take(50).map((n) => n.toJson()).toList();
      
      final backup = {
        'data': backupData,
        'timestamp': DateTime.now().toIso8601String(),
        'count': backupData.length,
      };
      
      final key = '$_backupPrefix$userId';
      await _prefs!.setString(key, jsonEncode(backup));
      
    } catch (e) {
      EnhancedLogger.log('⚠️ [LOCAL_STORAGE] Erro ao criar backup: $e');
    }
  }

  /// Recupera dados do backup
  Future<List<RealNotificationModel>> _recoverFromBackup(String userId) async {
    try {
      EnhancedLogger.log('🔄 [LOCAL_STORAGE] Tentando recuperar do backup');
      
      final key = '$_backupPrefix$userId';
      final backupString = _prefs!.getString(key);
      
      if (backupString == null) {
        EnhancedLogger.log('📭 [LOCAL_STORAGE] Nenhum backup encontrado');
        return [];
      }
      
      final backup = jsonDecode(backupString);
      final jsonData = backup['data'] as List;
      
      final notifications = jsonData
          .map((json) => RealNotificationModel.fromJson(json))
          .toList();
      
      EnhancedLogger.log('✅ [LOCAL_STORAGE] Recuperadas ${notifications.length} notificações do backup');
      return notifications;
      
    } catch (e) {
      EnhancedLogger.log('❌ [LOCAL_STORAGE] Erro na recuperação do backup: $e');
      return [];
    }
  }

  /// Verifica se há backup disponível
  Future<bool> _hasBackup(String userId) async {
    try {
      final key = '$_backupPrefix$userId';
      return _prefs!.containsKey(key);
    } catch (e) {
      return false;
    }
  }

  /// Carrega status de sincronização
  Future<void> _loadSyncStatus() async {
    try {
      final keys = _prefs!.getKeys().where((key) => key.startsWith(_syncPrefix));
      
      for (final key in keys) {
        final userId = key.replaceFirst(_syncPrefix, '');
        final jsonString = _prefs!.getString(key);
        
        if (jsonString != null) {
          final syncData = SyncData.fromJson(jsonDecode(jsonString));
          _syncStatus[userId] = syncData;
        }
      }
      
      EnhancedLogger.log('📊 [LOCAL_STORAGE] Status de sincronização carregado para ${_syncStatus.length} usuários');
      
    } catch (e) {
      EnhancedLogger.log('⚠️ [LOCAL_STORAGE] Erro ao carregar status de sincronização: $e');
    }
  }

  /// Agenda auto-save
  void _scheduleAutoSave(String userId) {
    // Cancela timer anterior se existir
    _autoSaveTimers[userId]?.cancel();
    
    // Agenda novo auto-save em 30 segundos
    _autoSaveTimers[userId] = Timer(Duration(seconds: 30), () async {
      try {
        if (_memoryCache.containsKey(userId)) {
          await saveNotifications(userId, _memoryCache[userId]!);
          EnhancedLogger.log('💾 [LOCAL_STORAGE] Auto-save executado para: $userId');
        }
      } catch (e) {
        EnhancedLogger.log('⚠️ [LOCAL_STORAGE] Erro no auto-save: $e');
      }
    });
  }

  /// Inicia limpeza automática
  void _startAutomaticCleanup() {
    Timer.periodic(Duration(hours: 6), (timer) async {
      try {
        await _performCleanup();
      } catch (e) {
        EnhancedLogger.log('⚠️ [LOCAL_STORAGE] Erro na limpeza automática: $e');
      }
    });
  }

  /// Executa limpeza de dados antigos
  Future<void> _performCleanup() async {
    try {
      EnhancedLogger.log('🧹 [LOCAL_STORAGE] Executando limpeza automática');
      
      final keys = _prefs!.getKeys();
      final now = DateTime.now();
      
      // Remove backups antigos (mais de 7 dias)
      for (final key in keys.where((k) => k.startsWith(_backupPrefix))) {
        final backupString = _prefs!.getString(key);
        if (backupString != null) {
          try {
            final backup = jsonDecode(backupString);
            final timestamp = DateTime.parse(backup['timestamp']);
            
            if (now.difference(timestamp).inDays > 7) {
              await _prefs!.remove(key);
              EnhancedLogger.log('🗑️ [LOCAL_STORAGE] Backup antigo removido: $key');
            }
          } catch (e) {
            // Remove backup corrompido
            await _prefs!.remove(key);
          }
        }
      }
      
      EnhancedLogger.log('✅ [LOCAL_STORAGE] Limpeza automática concluída');
      
    } catch (e) {
      EnhancedLogger.log('❌ [LOCAL_STORAGE] Erro na limpeza automática: $e');
    }
  }

  /// Dispose dos recursos
  void dispose() {
    // Cancela todos os timers
    for (final timer in _autoSaveTimers.values) {
      timer.cancel();
    }
    _autoSaveTimers.clear();
    
    // Limpa cache em memória
    _memoryCache.clear();
    _syncStatus.clear();
    
    EnhancedLogger.log('🧹 [LOCAL_STORAGE] Recursos liberados');
  }
}