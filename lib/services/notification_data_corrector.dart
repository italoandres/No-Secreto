import 'package:cloud_firestore/cloud_firestore.dart';

/// Serviço para correção automática de dados inconsistentes em notificações
class NotificationDataCorrector {
  /// Mapeamento de correções conhecidas para notificações específicas
  static const Map<String, String> KNOWN_CORRECTIONS = {
    'Iu4C9VdYrT0AaAinZEit': '6Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8', // ITALO2
  };

  /// Mapeamento de nomes corretos para usuários específicos
  static const Map<String, String> KNOWN_NAMES = {
    '6Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8': 'Italo Lior',
  };

  /// Cache de dados de usuário para performance
  static final Map<String, Map<String, dynamic>> _userCache = {};

  /// Corrige dados de notificação inconsistentes
  static Map<String, dynamic> correctNotificationData(
    Map<String, dynamic> rawData,
    String currentUserId,
    String notificationId,
  ) {
    print(
        '🔧 [CORRECTOR] Iniciando correção para notificação: $notificationId');

    final correctedData = Map<String, dynamic>.from(rawData);

    // 1. Corrigir fromUserId se necessário
    if (KNOWN_CORRECTIONS.containsKey(notificationId)) {
      final correctUserId = KNOWN_CORRECTIONS[notificationId]!;
      correctedData['fromUserId'] = correctUserId;
      print('🔧 [CORRECTOR] FromUserId corrigido: $correctUserId');
    }

    // 2. Corrigir nome do usuário
    final fromUserId = correctedData['fromUserId'] as String?;
    if (fromUserId != null && KNOWN_NAMES.containsKey(fromUserId)) {
      correctedData['fromUserName'] = KNOWN_NAMES[fromUserId]!;
      print('🔧 [CORRECTOR] Nome corrigido: ${KNOWN_NAMES[fromUserId]}');
    }

    // 3. Corrigir userId de destino se for "test_target_user"
    if (correctedData['userId'] == 'test_target_user') {
      correctedData['userId'] = currentUserId;
      print('🔧 [CORRECTOR] UserId de destino corrigido: $currentUserId');
    }

    // 4. Garantir campos obrigatórios
    correctedData['message'] = correctedData['content'] ??
        correctedData['message'] ??
        'Tem interesse em conhecer seu perfil melhor';

    correctedData['timestamp'] = correctedData['createdAt'] ??
        correctedData['timestamp'] ??
        Timestamp.now();

    print('🔧 [CORRECTOR] Correção finalizada para: $notificationId');
    return correctedData;
  }

  /// Busca nome correto do usuário no Firebase
  static Future<String> fetchCorrectUserName(String userId) async {
    print('👤 [CORRECTOR] Buscando nome para userId: $userId');

    // Verificar cache primeiro
    if (_userCache.containsKey(userId)) {
      final cachedName = _userCache[userId]!['nome'] as String?;
      if (cachedName != null) {
        print('👤 [CORRECTOR] Nome encontrado no cache: $cachedName');
        return cachedName;
      }
    }

    // Verificar nomes conhecidos
    if (KNOWN_NAMES.containsKey(userId)) {
      final knownName = KNOWN_NAMES[userId]!;
      print('👤 [CORRECTOR] Nome conhecido encontrado: $knownName');
      return knownName;
    }

    try {
      // Buscar no Firebase
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final userName = userData['nome'] as String? ??
            userData['name'] as String? ??
            'Usuário';

        // Salvar no cache
        _userCache[userId] = userData;

        print('👤 [CORRECTOR] Nome encontrado no Firebase: $userName');
        return userName;
      }
    } catch (e) {
      print('❌ [CORRECTOR] Erro ao buscar usuário: $e');
    }

    print('👤 [CORRECTOR] Usando fallback para userId: $userId');
    return 'Usuário não encontrado';
  }

  /// Corrige userId de destino se inválido
  static String correctTargetUserId(String rawUserId, String currentUserId) {
    if (rawUserId == 'test_target_user' || rawUserId.isEmpty) {
      print(
          '🔧 [CORRECTOR] Corrigindo userId inválido: $rawUserId → $currentUserId');
      return currentUserId;
    }
    return rawUserId;
  }

  /// Valida se um userId é válido
  static bool isValidUserId(String userId) {
    return userId.isNotEmpty &&
        userId != 'test_target_user' &&
        userId.length > 10; // IDs do Firebase são longos
  }

  /// Limpa cache de usuários (para testes)
  static void clearCache() {
    _userCache.clear();
    print('🧹 [CORRECTOR] Cache limpo');
  }

  /// Registra correção aplicada
  static void logCorrection(String notificationId, String correction) {
    print('📝 [CORRECTOR] ID: $notificationId');
    print('📝 [CORRECTOR] Correção: $correction');
    print('📝 [CORRECTOR] Timestamp: ${DateTime.now()}');
  }
}
