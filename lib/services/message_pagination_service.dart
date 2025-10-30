import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message_model.dart';
import '../utils/enhanced_logger.dart';

/// Configuração de paginação para mensagens
class PaginationConfig {
  final int pageSize;
  final int maxPages;
  final Duration cacheTimeout;

  const PaginationConfig({
    this.pageSize = 20,
    this.maxPages = 10,
    this.cacheTimeout = const Duration(minutes: 5),
  });

  /// Configuração padrão
  static const PaginationConfig defaultConfig = PaginationConfig();

  /// Configuração para carregamento inicial (mais mensagens)
  static const PaginationConfig initialLoad = PaginationConfig(
    pageSize: 50,
    maxPages: 5,
  );

  /// Configuração para carregamento rápido (menos mensagens)
  static const PaginationConfig quickLoad = PaginationConfig(
    pageSize: 10,
    maxPages: 20,
  );
}

/// Resultado de uma página de mensagens
class MessagePage {
  final List<ChatMessageModel> messages;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
  final int pageNumber;
  final DateTime loadedAt;

  MessagePage({
    required this.messages,
    this.lastDocument,
    required this.hasMore,
    required this.pageNumber,
    DateTime? loadedAt,
  }) : loadedAt = loadedAt ?? DateTime.now();

  @override
  String toString() {
    return 'MessagePage(messages: ${messages.length}, hasMore: $hasMore, page: $pageNumber)';
  }
}

/// Serviço de paginação para mensagens de chat
class MessagePaginationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Map<String, List<MessagePage>> _pageCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};

  /// Carregar primeira página de mensagens
  static Future<MessagePage> loadFirstPage(
    String chatId, {
    PaginationConfig config = PaginationConfig.defaultConfig,
  }) async {
    try {
      EnhancedLogger.info('Loading first page for chat $chatId',
          tag: 'MESSAGE_PAGINATION');

      final query = _firestore
          .collection('chat_messages')
          .where('chatId', isEqualTo: chatId)
          .orderBy('timestamp', descending: true)
          .limit(config.pageSize);

      final snapshot = await query.get();
      final messages = snapshot.docs
          .map((doc) =>
              ChatMessageModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      final page = MessagePage(
        messages: messages,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        hasMore: snapshot.docs.length == config.pageSize,
        pageNumber: 1,
      );

      // Inicializar cache
      _pageCache[chatId] = [page];
      _cacheTimestamps[chatId] = DateTime.now();

      EnhancedLogger.info('Loaded ${messages.length} messages in first page',
          tag: 'MESSAGE_PAGINATION');
      return page;
    } catch (e) {
      EnhancedLogger.error('Error loading first page for chat $chatId: $e',
          tag: 'MESSAGE_PAGINATION');
      rethrow;
    }
  }

  /// Carregar próxima página de mensagens
  static Future<MessagePage?> loadNextPage(
    String chatId, {
    PaginationConfig config = PaginationConfig.defaultConfig,
  }) async {
    try {
      final cachedPages = _pageCache[chatId];
      if (cachedPages == null || cachedPages.isEmpty) {
        EnhancedLogger.warning('No cached pages found, loading first page',
            tag: 'MESSAGE_PAGINATION');
        return await loadFirstPage(chatId, config: config);
      }

      final lastPage = cachedPages.last;
      if (!lastPage.hasMore) {
        EnhancedLogger.debug('No more pages available for chat $chatId',
            tag: 'MESSAGE_PAGINATION');
        return null;
      }

      if (lastPage.lastDocument == null) {
        EnhancedLogger.warning('Last document is null, cannot load next page',
            tag: 'MESSAGE_PAGINATION');
        return null;
      }

      // Verificar limite de páginas
      if (cachedPages.length >= config.maxPages) {
        EnhancedLogger.info(
            'Maximum pages reached (${config.maxPages}), removing oldest',
            tag: 'MESSAGE_PAGINATION');
        cachedPages.removeAt(0); // Remove página mais antiga
      }

      EnhancedLogger.info(
          'Loading page ${lastPage.pageNumber + 1} for chat $chatId',
          tag: 'MESSAGE_PAGINATION');

      final query = _firestore
          .collection('chat_messages')
          .where('chatId', isEqualTo: chatId)
          .orderBy('timestamp', descending: true)
          .startAfterDocument(lastPage.lastDocument!)
          .limit(config.pageSize);

      final snapshot = await query.get();
      final messages = snapshot.docs
          .map((doc) =>
              ChatMessageModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      final nextPage = MessagePage(
        messages: messages,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        hasMore: snapshot.docs.length == config.pageSize,
        pageNumber: lastPage.pageNumber + 1,
      );

      // Adicionar ao cache
      cachedPages.add(nextPage);
      _cacheTimestamps[chatId] = DateTime.now();

      EnhancedLogger.info(
          'Loaded ${messages.length} messages in page ${nextPage.pageNumber}',
          tag: 'MESSAGE_PAGINATION');
      return nextPage;
    } catch (e) {
      EnhancedLogger.error('Error loading next page for chat $chatId: $e',
          tag: 'MESSAGE_PAGINATION');
      rethrow;
    }
  }

  /// Obter todas as mensagens carregadas (de todas as páginas)
  static List<ChatMessageModel> getAllLoadedMessages(String chatId) {
    final cachedPages = _pageCache[chatId];
    if (cachedPages == null || cachedPages.isEmpty) {
      return [];
    }

    final allMessages = <ChatMessageModel>[];
    for (final page in cachedPages) {
      allMessages.addAll(page.messages);
    }

    return allMessages;
  }

  /// Verificar se há mais páginas disponíveis
  static bool hasMorePages(String chatId) {
    final cachedPages = _pageCache[chatId];
    if (cachedPages == null || cachedPages.isEmpty) {
      return true; // Assumir que há páginas se não carregamos nenhuma ainda
    }

    return cachedPages.last.hasMore;
  }

  /// Obter número de páginas carregadas
  static int getLoadedPagesCount(String chatId) {
    final cachedPages = _pageCache[chatId];
    return cachedPages?.length ?? 0;
  }

  /// Obter número total de mensagens carregadas
  static int getTotalLoadedMessages(String chatId) {
    return getAllLoadedMessages(chatId).length;
  }

  /// Verificar se cache está válido
  static bool _isCacheValid(String chatId, PaginationConfig config) {
    final timestamp = _cacheTimestamps[chatId];
    if (timestamp == null) return false;

    final now = DateTime.now();
    return now.difference(timestamp) < config.cacheTimeout;
  }

  /// Invalidar cache de um chat específico
  static void invalidateCache(String chatId) {
    _pageCache.remove(chatId);
    _cacheTimestamps.remove(chatId);

    EnhancedLogger.info('Cache invalidated for chat $chatId',
        tag: 'MESSAGE_PAGINATION');
  }

  /// Limpar todo o cache
  static void clearAllCache() {
    final chatCount = _pageCache.length;
    _pageCache.clear();
    _cacheTimestamps.clear();

    EnhancedLogger.info('All pagination cache cleared ($chatCount chats)',
        tag: 'MESSAGE_PAGINATION');
  }

  /// Pré-carregar mensagens para um chat
  static Future<void> preloadMessages(
    String chatId, {
    int pagesToPreload = 2,
    PaginationConfig config = PaginationConfig.defaultConfig,
  }) async {
    try {
      EnhancedLogger.info('Preloading $pagesToPreload pages for chat $chatId',
          tag: 'MESSAGE_PAGINATION');

      // Carregar primeira página se não estiver carregada
      if (!_pageCache.containsKey(chatId)) {
        await loadFirstPage(chatId, config: config);
      }

      // Carregar páginas adicionais
      for (int i = 1; i < pagesToPreload; i++) {
        final nextPage = await loadNextPage(chatId, config: config);
        if (nextPage == null) break; // Não há mais páginas
      }

      EnhancedLogger.info('Preloading completed for chat $chatId',
          tag: 'MESSAGE_PAGINATION');
    } catch (e) {
      EnhancedLogger.error('Error preloading messages for chat $chatId: $e',
          tag: 'MESSAGE_PAGINATION');
    }
  }

  /// Carregar mensagens mais recentes (para atualizações em tempo real)
  static Future<List<ChatMessageModel>> loadRecentMessages(
    String chatId, {
    DateTime? since,
    int limit = 10,
  }) async {
    try {
      final sinceTime =
          since ?? DateTime.now().subtract(const Duration(minutes: 5));

      EnhancedLogger.debug(
          'Loading recent messages since $sinceTime for chat $chatId',
          tag: 'MESSAGE_PAGINATION');

      final query = _firestore
          .collection('chat_messages')
          .where('chatId', isEqualTo: chatId)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(sinceTime))
          .orderBy('timestamp', descending: false)
          .limit(limit);

      final snapshot = await query.get();
      final messages = snapshot.docs
          .map((doc) =>
              ChatMessageModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      EnhancedLogger.info('Loaded ${messages.length} recent messages',
          tag: 'MESSAGE_PAGINATION');
      return messages;
    } catch (e) {
      EnhancedLogger.error('Error loading recent messages for chat $chatId: $e',
          tag: 'MESSAGE_PAGINATION');
      return [];
    }
  }

  /// Otimizar cache removendo páginas antigas
  static void optimizeCache({
    Duration maxAge = const Duration(minutes: 10),
    int maxChatsInCache = 10,
  }) {
    try {
      final now = DateTime.now();
      final chatsToRemove = <String>[];

      // Encontrar chats com cache expirado
      for (final entry in _cacheTimestamps.entries) {
        if (now.difference(entry.value) > maxAge) {
          chatsToRemove.add(entry.key);
        }
      }

      // Remover chats expirados
      for (final chatId in chatsToRemove) {
        invalidateCache(chatId);
      }

      // Limitar número de chats em cache
      if (_pageCache.length > maxChatsInCache) {
        final sortedEntries = _cacheTimestamps.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value));

        final oldestChats = sortedEntries
            .take(_pageCache.length - maxChatsInCache)
            .map((e) => e.key)
            .toList();

        for (final chatId in oldestChats) {
          invalidateCache(chatId);
        }
      }

      EnhancedLogger.info(
          'Cache optimization completed, removed ${chatsToRemove.length} expired chats',
          tag: 'MESSAGE_PAGINATION');
    } catch (e) {
      EnhancedLogger.error('Error optimizing cache: $e',
          tag: 'MESSAGE_PAGINATION');
    }
  }

  /// Obter estatísticas de paginação
  static Map<String, dynamic> getPaginationStats() {
    try {
      int totalPages = 0;
      int totalMessages = 0;
      final chatStats = <String, Map<String, dynamic>>{};

      for (final entry in _pageCache.entries) {
        final chatId = entry.key;
        final pages = entry.value;

        final messagesCount =
            pages.fold<int>(0, (sum, page) => sum + page.messages.length);
        totalPages += pages.length;
        totalMessages += messagesCount;

        chatStats[chatId] = {
          'pages': pages.length,
          'messages': messagesCount,
          'hasMore': pages.isNotEmpty ? pages.last.hasMore : false,
          'lastLoaded': _cacheTimestamps[chatId]?.toIso8601String(),
        };
      }

      return {
        'totalChatsInCache': _pageCache.length,
        'totalPages': totalPages,
        'totalMessages': totalMessages,
        'averagePagesPerChat':
            _pageCache.isNotEmpty ? totalPages / _pageCache.length : 0,
        'averageMessagesPerChat':
            _pageCache.isNotEmpty ? totalMessages / _pageCache.length : 0,
        'chatStats': chatStats,
      };
    } catch (e) {
      EnhancedLogger.error('Error getting pagination stats: $e',
          tag: 'MESSAGE_PAGINATION');
      return {
        'error': e.toString(),
        'totalChatsInCache': 0,
        'totalPages': 0,
        'totalMessages': 0,
      };
    }
  }

  /// Stream para monitorar novas mensagens em tempo real
  static Stream<List<ChatMessageModel>> watchRecentMessages(
    String chatId, {
    int limit = 20,
  }) {
    return _firestore
        .collection('chat_messages')
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                ChatMessageModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }
}
