import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/real_notification_model.dart';
import '../models/user_data_model.dart';
import '../services/unified_notification_cache.dart';
import '../utils/enhanced_logger.dart';

/// Repositório de fonte única para notificações
/// Centraliza acesso aos dados eliminando conflitos
class SingleSourceNotificationRepository {
  static final SingleSourceNotificationRepository _instance =
      SingleSourceNotificationRepository._internal();
  factory SingleSourceNotificationRepository() => _instance;
  SingleSourceNotificationRepository._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UnifiedNotificationCache _cache = UnifiedNotificationCache();

  final Map<String, StreamSubscription> _activeListeners = {};
  final Map<String, StreamController<List<RealNotificationModel>>>
      _streamControllers = {};

  /// FONTE ÚNICA - Obtém notificações com cache inteligente
  Future<List<RealNotificationModel>> getNotifications(String userId) async {
    EnhancedLogger.log('🎯 [SINGLE_SOURCE] Obtendo notificações para: $userId');

    try {
      // Verifica cache primeiro
      final cachedData = _cache.getCachedNotifications(userId);
      if (cachedData != null) {
        EnhancedLogger.log(
            '⚡ [SINGLE_SOURCE] Retornando do cache: ${cachedData.length} notificações');
        return cachedData;
      }

      // Busca do Firebase se não há cache válido
      final notifications = await _fetchFromFirebase(userId);

      // Atualiza cache
      _cache.updateCache(userId, notifications);

      EnhancedLogger.log(
          '✅ [SINGLE_SOURCE] Obtidas ${notifications.length} notificações do Firebase');
      return notifications;
    } catch (e) {
      EnhancedLogger.log('❌ [SINGLE_SOURCE] Erro ao obter notificações: $e');
      return [];
    }
  }

  /// STREAM ÚNICO - Observa notificações em tempo real
  Stream<List<RealNotificationModel>> watchNotifications(String userId) {
    EnhancedLogger.log('📡 [SINGLE_SOURCE] Iniciando watch para: $userId');

    if (!_streamControllers.containsKey(userId)) {
      _streamControllers[userId] =
          StreamController<List<RealNotificationModel>>.broadcast();
      _setupRealtimeListener(userId);
    }

    return _streamControllers[userId]!.stream;
  }

  /// Configura listener em tempo real
  void _setupRealtimeListener(String userId) {
    EnhancedLogger.log(
        '🔄 [SINGLE_SOURCE] Configurando listener para: $userId');

    // Cancela listener anterior se existir
    _activeListeners[userId]?.cancel();

    // Envia dados do cache imediatamente se disponíveis
    final cachedData = _cache.getCachedNotifications(userId);
    if (cachedData != null) {
      _streamControllers[userId]?.add(cachedData);
    }

    // Configura listener do Firebase
    _activeListeners[userId] = _firestore
        .collection('interests')
        .where('targetUserId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen(
          (snapshot) => _handleFirebaseUpdate(userId, snapshot),
          onError: (error) => _handleFirebaseError(userId, error),
        );
  }

  /// Processa atualizações do Firebase
  Future<void> _handleFirebaseUpdate(
      String userId, QuerySnapshot snapshot) async {
    try {
      EnhancedLogger.log(
          '📨 [SINGLE_SOURCE] Atualização do Firebase: ${snapshot.docs.length} documentos');

      if (snapshot.docs.isEmpty) {
        _updateStream(userId, []);
        return;
      }

      // Processa documentos
      final notifications =
          await _processFirebaseDocuments(snapshot.docs, userId);

      // Atualiza cache e stream
      _cache.updateCache(userId, notifications);
      _updateStream(userId, notifications);
    } catch (e) {
      EnhancedLogger.log('❌ [SINGLE_SOURCE] Erro ao processar atualização: $e');
    }
  }

  /// Processa erro do Firebase
  void _handleFirebaseError(String userId, dynamic error) {
    EnhancedLogger.log(
        '❌ [SINGLE_SOURCE] Erro no listener do Firebase: $error');
    _streamControllers[userId]?.addError(error);
  }

  /// Atualiza stream com novas notificações
  void _updateStream(String userId, List<RealNotificationModel> notifications) {
    _streamControllers[userId]?.add(notifications);
    EnhancedLogger.log(
        '📡 [SINGLE_SOURCE] Stream atualizado: ${notifications.length} notificações');
  }

  /// Busca dados do Firebase
  Future<List<RealNotificationModel>> _fetchFromFirebase(String userId) async {
    EnhancedLogger.log('🔍 [SINGLE_SOURCE] Buscando do Firebase para: $userId');

    try {
      final query = await _firestore
          .collection('interests')
          .where('targetUserId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      return await _processFirebaseDocuments(query.docs, userId);
    } catch (e) {
      EnhancedLogger.log('❌ [SINGLE_SOURCE] Erro na busca do Firebase: $e');
      return [];
    }
  }

  /// Processa documentos do Firebase
  Future<List<RealNotificationModel>> _processFirebaseDocuments(
    List<QueryDocumentSnapshot> docs,
    String userId,
  ) async {
    if (docs.isEmpty) {
      EnhancedLogger.log('📭 [SINGLE_SOURCE] Nenhum documento encontrado');
      return [];
    }

    // Extrai IDs únicos dos usuários
    final userIds = <String>{};
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final fromUserId = data['fromUserId'] as String?;
      if (fromUserId != null && fromUserId != userId) {
        userIds.add(fromUserId);
      }
    }

    if (userIds.isEmpty) {
      EnhancedLogger.log('👥 [SINGLE_SOURCE] Nenhum usuário válido encontrado');
      return [];
    }

    // Busca dados dos usuários
    final userData = await _fetchUserDataOptimized(userIds.toList());

    // Converte em notificações
    final notifications = _convertToNotifications(docs, userData);

    EnhancedLogger.log(
        '✅ [SINGLE_SOURCE] Processados ${notifications.length} notificações');
    return notifications;
  }

  /// Busca dados de usuários de forma otimizada
  Future<Map<String, UserDataModel>> _fetchUserDataOptimized(
      List<String> userIds) async {
    final userData = <String, UserDataModel>{};

    try {
      // Processa em lotes para otimização
      const batchSize = 10;
      for (int i = 0; i < userIds.length; i += batchSize) {
        final batch = userIds.skip(i).take(batchSize).toList();

        final query = await _firestore
            .collection('usuarios')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (final doc in query.docs) {
          final data = doc.data();
          userData[doc.id] = UserDataModel(
            uid: doc.id,
            nome: data['nome'] ?? 'Usuário',
            username: data['username'] ?? doc.id,
            email: data['email'] ?? '',
            photoURL: data['photoURL'],
          );
        }
      }

      EnhancedLogger.log(
          '👥 [SINGLE_SOURCE] Carregados ${userData.length} usuários');
      return userData;
    } catch (e) {
      EnhancedLogger.log('❌ [SINGLE_SOURCE] Erro ao carregar usuários: $e');
      return {};
    }
  }

  /// Converte documentos em notificações
  List<RealNotificationModel> _convertToNotifications(
    List<QueryDocumentSnapshot> docs,
    Map<String, UserDataModel> userData,
  ) {
    final notifications = <RealNotificationModel>[];
    final groupedByUser = <String, List<QueryDocumentSnapshot>>{};

    // Agrupa por usuário
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final fromUserId = data['fromUserId'] as String?;
      if (fromUserId != null) {
        groupedByUser.putIfAbsent(fromUserId, () => []).add(doc);
      }
    }

    // Cria notificações agrupadas
    for (final entry in groupedByUser.entries) {
      final fromUserId = entry.key;
      final userDocs = entry.value;
      final user = userData[fromUserId];

      if (user == null) continue;

      // Usa documento mais recente para dados principais
      final latestDoc = userDocs.first;
      final latestData = latestDoc.data() as Map<String, dynamic>;
      final timestamp = latestData['timestamp'] as Timestamp?;

      final notification = RealNotificationModel(
        id: latestDoc.id,
        fromUserId: fromUserId,
        fromUserName: user.nome,
        fromUserPhoto: user.photoURL,
        message: _generateMessage(user.nome, userDocs.length),
        timestamp: timestamp?.toDate() ?? DateTime.now(),
        isRead: false,
        type: 'interest',
        count: userDocs.length,
      );

      notifications.add(notification);
    }

    // Ordena por timestamp (mais recente primeiro)
    notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return notifications;
  }

  /// Gera mensagem baseada na contagem
  String _generateMessage(String userName, int count) {
    if (count == 1) {
      return '$userName se interessou por você';
    } else {
      return '$userName se interessou por você ($count vezes)';
    }
  }

  /// Invalida cache para um usuário
  Future<void> invalidateCache(String userId) async {
    EnhancedLogger.log('🗑️ [SINGLE_SOURCE] Invalidando cache para: $userId');

    _cache.invalidateCache(userId);

    // Força nova busca
    final notifications = await _fetchFromFirebase(userId);
    _cache.updateCache(userId, notifications);
    _updateStream(userId, notifications);
  }

  /// Força atualização completa
  Future<void> forceRefresh(String userId) async {
    EnhancedLogger.log('🚀 [SINGLE_SOURCE] Forçando atualização para: $userId');

    try {
      // Invalida cache
      _cache.invalidateCache(userId);

      // Busca dados atualizados
      final notifications = await _fetchFromFirebase(userId);

      // Atualiza cache e stream
      _cache.updateCache(userId, notifications);
      _updateStream(userId, notifications);

      EnhancedLogger.log('✅ [SINGLE_SOURCE] Atualização forçada concluída');
    } catch (e) {
      EnhancedLogger.log('❌ [SINGLE_SOURCE] Erro na atualização forçada: $e');
      rethrow;
    }
  }

  /// Verifica se há dados em cache
  bool hasCachedData(String userId) {
    return _cache.hasCachedData(userId);
  }

  /// Obtém estatísticas do repositório
  Map<String, dynamic> getRepositoryStats() {
    return {
      'activeListeners': _activeListeners.length,
      'activeStreams': _streamControllers.length,
      'cache': _cache.getCacheStats(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Limpa recursos para um usuário
  void disposeUser(String userId) {
    EnhancedLogger.log('🧹 [SINGLE_SOURCE] Limpando recursos para: $userId');

    _activeListeners[userId]?.cancel();
    _activeListeners.remove(userId);

    _streamControllers[userId]?.close();
    _streamControllers.remove(userId);

    _cache.disposeUser(userId);
  }

  /// Limpa todos os recursos
  void dispose() {
    EnhancedLogger.log('🧹 [SINGLE_SOURCE] Limpando todos os recursos');

    for (final listener in _activeListeners.values) {
      listener.cancel();
    }
    _activeListeners.clear();

    for (final controller in _streamControllers.values) {
      controller.close();
    }
    _streamControllers.clear();

    _cache.dispose();
  }
}
