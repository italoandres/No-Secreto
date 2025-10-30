import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import '../models/user_data_model.dart';
import '../utils/enhanced_logger.dart';

/// Gerenciador de sincronização de notificações
class NotificationSyncManager {
  static final NotificationSyncManager _instance =
      NotificationSyncManager._internal();
  factory NotificationSyncManager() => _instance;
  NotificationSyncManager._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, StreamController<List<NotificationModel>>>
      _streamControllers = {};
  final Map<String, List<NotificationModel>> _cache = {};
  final Map<String, StreamSubscription> _listeners = {};
  final Map<String, Timer> _periodicTimers = {};

  /// Obtém stream de notificações para um usuário
  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    EnhancedLogger.log(
        '🔄 [SYNC_MANAGER] Iniciando stream unificado para: $userId');

    if (!_streamControllers.containsKey(userId)) {
      _streamControllers[userId] =
          StreamController<List<NotificationModel>>.broadcast();
      _initializeStream(userId);
    }

    return _streamControllers[userId]!.stream;
  }

  /// Inicializa stream para um usuário
  void _initializeStream(String userId) {
    EnhancedLogger.log('🚀 [SYNC_MANAGER] Inicializando stream para: $userId');

    // Carrega dados iniciais
    _loadInitialData(userId);

    // Configura listener em tempo real
    _setupRealtimeListener(userId);

    // Configura sincronização periódica
    _setupPeriodicSync(userId);
  }

  /// Carrega dados iniciais
  Future<void> _loadInitialData(String userId) async {
    try {
      EnhancedLogger.log(
          '📊 [SYNC_MANAGER] Carregando dados iniciais para: $userId');

      // Verifica se há cache válido
      if (_cache.containsKey(userId) && _cache[userId]!.isNotEmpty) {
        EnhancedLogger.log(
            '✅ [SYNC_MANAGER] Usando cache válido: ${_cache[userId]!.length} notificações');
        _streamControllers[userId]?.add(_cache[userId]!);
        return;
      }

      // Busca do Firebase
      final notifications = await _fetchFromFirebase(userId);
      _updateCache(userId, notifications);
      _streamControllers[userId]?.add(notifications);
    } catch (e) {
      EnhancedLogger.log(
          '❌ [SYNC_MANAGER] Erro ao carregar dados iniciais: $e');
      _streamControllers[userId]?.addError(e);
    }
  }

  /// Busca notificações do Firebase
  Future<List<NotificationModel>> _fetchFromFirebase(String userId) async {
    EnhancedLogger.log('🔍 [SYNC_MANAGER] Buscando do Firebase para: $userId');

    try {
      // Busca interesses do usuário
      final interestsQuery = await _firestore
          .collection('interests')
          .where('interestedUserId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      if (interestsQuery.docs.isEmpty) {
        EnhancedLogger.log('📭 [SYNC_MANAGER] Nenhum interesse encontrado');
        return [];
      }

      // Extrai IDs únicos dos usuários
      final userIds = interestsQuery.docs
          .map((doc) => doc.data()['userId'] as String?)
          .where((id) => id != null)
          .cast<String>()
          .toSet()
          .toList();

      if (userIds.isEmpty) {
        EnhancedLogger.log(
            '👥 [SYNC_MANAGER] Nenhum usuário válido encontrado');
        return [];
      }

      // Busca dados dos usuários
      final userData = await _fetchUserDataBatch(userIds);

      // Converte para notificações
      final notifications =
          _convertToNotifications(interestsQuery.docs, userData);

      EnhancedLogger.log(
          '✅ [SYNC_MANAGER] ${notifications.length} notificações processadas');
      return notifications;
    } catch (e) {
      EnhancedLogger.log('❌ [SYNC_MANAGER] Erro ao buscar do Firebase: $e');
      return [];
    }
  }

  /// Busca dados de usuários em lote
  Future<Map<String, UserDataModel>> _fetchUserDataBatch(
      List<String> userIds) async {
    final userData = <String, UserDataModel>{};

    try {
      // Busca em lotes de 10 (limite do Firestore para 'in')
      for (int i = 0; i < userIds.length; i += 10) {
        final batch = userIds.skip(i).take(10).toList();

        final query = await _firestore
            .collection('usuarios')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (final doc in query.docs) {
          userData[doc.id] = UserDataModel(
            userId: doc.id,
            displayName: doc.data()['displayName'] ?? 'Usuário',
            photoURL: doc.data()['photoURL'],
            bio: doc.data()['bio'],
            age: doc.data()['age'],
            city: doc.data()['city'],
          );
        }
      }

      EnhancedLogger.log(
          '👥 [SYNC_MANAGER] ${userData.length} usuários carregados');
      return userData;
    } catch (e) {
      EnhancedLogger.log(
          '❌ [SYNC_MANAGER] Erro ao buscar dados de usuários: $e');
      return {};
    }
  }

  /// Converte documentos em notificações
  List<NotificationModel> _convertToNotifications(
    List<QueryDocumentSnapshot> interestDocs,
    Map<String, UserDataModel> userData,
  ) {
    final notifications = <NotificationModel>[];

    for (final doc in interestDocs) {
      try {
        final data = doc.data() as Map<String, dynamic>;
        final userId = data['userId'] as String?;

        if (userId == null || !userData.containsKey(userId)) continue;

        final user = userData[userId]!;
        final timestamp = data['timestamp'] as Timestamp?;

        final notification = NotificationModel(
          id: doc.id,
          userId: data['interestedUserId'] ?? userId,
          type: 'interest',
          relatedId: doc.id,
          fromUserId: userId,
          fromUserName: user.displayName,
          fromUserAvatar: user.photoURL ?? '',
          content: '${user.displayName} demonstrou interesse em você',
          isRead: false,
          timestamp: timestamp?.toDate() ?? DateTime.now(),
          title: 'Novo interesse',
          message: '${user.displayName} demonstrou interesse em você',
          data: {
            'userId': userId,
            'displayName': user.displayName,
            'photoURL': user.photoURL,
            'interestId': doc.id,
          },
        );

        notifications.add(notification);
      } catch (e) {
        EnhancedLogger.log(
            '❌ [SYNC_MANAGER] Erro ao processar documento ${doc.id}: $e');
      }
    }

    // Ordena por timestamp (mais recente primeiro)
    notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return notifications;
  }

  /// Configura listener em tempo real
  void _setupRealtimeListener(String userId) {
    EnhancedLogger.log(
        '📡 [SYNC_MANAGER] Configurando listener em tempo real para: $userId');

    _listeners[userId] = _firestore
        .collection('interests')
        .where('interestedUserId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .listen(
      (snapshot) async {
        try {
          EnhancedLogger.log(
              '🔄 [SYNC_MANAGER] Atualização em tempo real: ${snapshot.docs.length} documentos');

          if (snapshot.docs.isEmpty) {
            _updateCache(userId, []);
            _streamControllers[userId]?.add([]);
            return;
          }

          // Extrai IDs dos usuários
          final userIds = snapshot.docs
              .map((doc) => doc.data()['userId'] as String?)
              .where((id) => id != null)
              .cast<String>()
              .toSet()
              .toList();

          // Busca dados dos usuários
          final userData = await _fetchUserDataBatch(userIds);

          // Converte para notificações
          final notifications =
              _convertToNotifications(snapshot.docs, userData);

          // Atualiza cache e stream
          _updateCache(userId, notifications);
          _streamControllers[userId]?.add(notifications);
        } catch (e) {
          EnhancedLogger.log(
              '❌ [SYNC_MANAGER] Erro no listener em tempo real: $e');
          _streamControllers[userId]?.addError(e);
        }
      },
      onError: (error) {
        EnhancedLogger.log('❌ [SYNC_MANAGER] Erro no listener: $error');
        _streamControllers[userId]?.addError(error);
      },
    );
  }

  /// Configura sincronização periódica
  void _setupPeriodicSync(String userId) {
    _periodicTimers[userId] = Timer.periodic(Duration(minutes: 5), (_) async {
      try {
        EnhancedLogger.log(
            '⏰ [SYNC_MANAGER] Sincronização periódica para: $userId');

        final notifications = await _fetchFromFirebase(userId);

        if (!_areNotificationsEqual(_cache[userId] ?? [], notifications)) {
          _updateCache(userId, notifications);
          _streamControllers[userId]?.add(notifications);
          EnhancedLogger.log(
              '🔄 [SYNC_MANAGER] Cache atualizado na sincronização periódica');
        }
      } catch (e) {
        EnhancedLogger.log(
            '❌ [SYNC_MANAGER] Erro na sincronização periódica: $e');
      }
    });
  }

  /// Força sincronização
  Future<void> forceSync(String userId) async {
    EnhancedLogger.log(
        '🚀 [SYNC_MANAGER] Forçando sincronização para: $userId');

    try {
      final notifications = await _fetchFromFirebase(userId);
      _updateCache(userId, notifications);
      _streamControllers[userId]?.add(notifications);

      EnhancedLogger.log(
          '✅ [SYNC_MANAGER] Sincronização forçada concluída: ${notifications.length} notificações');
    } catch (e) {
      EnhancedLogger.log('❌ [SYNC_MANAGER] Erro na sincronização forçada: $e');
      rethrow;
    }
  }

  /// Atualiza cache
  void _updateCache(String userId, List<NotificationModel> notifications) {
    _cache[userId] = notifications;
  }

  /// Verifica se duas listas de notificações são iguais
  bool _areNotificationsEqual(
      List<NotificationModel> list1, List<NotificationModel> list2) {
    if (list1.length != list2.length) return false;

    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id) return false;
    }

    return true;
  }

  /// Obtém notificações do cache
  List<NotificationModel>? getCachedNotifications(String userId) {
    return _cache[userId];
  }

  /// Limpa recursos para um usuário
  void dispose(String userId) {
    EnhancedLogger.log('🧹 [SYNC_MANAGER] Limpando recursos para: $userId');

    _listeners[userId]?.cancel();
    _listeners.remove(userId);

    _periodicTimers[userId]?.cancel();
    _periodicTimers.remove(userId);

    _streamControllers[userId]?.close();
    _streamControllers.remove(userId);

    _cache.remove(userId);
  }

  /// Limpa todos os recursos
  void disposeAll() {
    EnhancedLogger.log('🧹 [SYNC_MANAGER] Limpando todos os recursos');

    for (final listener in _listeners.values) {
      listener.cancel();
    }
    _listeners.clear();

    for (final timer in _periodicTimers.values) {
      timer.cancel();
    }
    _periodicTimers.clear();

    for (final controller in _streamControllers.values) {
      controller.close();
    }
    _streamControllers.clear();

    _cache.clear();
  }
}
