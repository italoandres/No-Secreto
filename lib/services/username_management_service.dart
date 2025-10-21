import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/enhanced_logger.dart';
import '../utils/error_handler.dart';
import '../utils/data_validator.dart';
import 'profile_data_synchronizer.dart';

/// Serviço para gerenciamento de usernames
class UsernameManagementService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Verifica se um username está disponível
  static Future<bool> isUsernameAvailable(String username) async {
    return await ErrorHandler.safeExecute(
      () async {
        // Validar formato
        if (!DataValidator.isValidUsernameFormat(username)) {
          return false;
        }
        
        EnhancedLogger.debug('Checking username availability', tag: 'USERNAME', data: {
          'username': username,
        });
        
        // Verificar na collection usuarios
        final userQuery = await _firestore
            .collection('usuarios')
            .where('username', isEqualTo: username)
            .limit(1)
            .get();
        
        if (userQuery.docs.isNotEmpty) {
          return false;
        }
        
        // Verificar na collection spiritual_profiles
        final profileQuery = await _firestore
            .collection('spiritual_profiles')
            .where('username', isEqualTo: username)
            .limit(1)
            .get();
        
        return profileQuery.docs.isEmpty;
      },
      context: 'UsernameManagementService.isUsernameAvailable',
      fallbackValue: false,
    ) ?? false;
  }
  
  /// Atualiza username do usuário atual
  static Future<bool> updateUsername(String userId, String newUsername) async {
    return await ErrorHandler.safeExecute(
      () async {
        // Validar formato
        if (!DataValidator.isValidUsernameFormat(newUsername)) {
          ErrorHandler.showWarning('Username deve ter entre 3-30 caracteres, começar com letra/número e conter apenas letras, números, pontos e underscores.');
          return false;
        }
        
        // Verificar disponibilidade
        final isAvailable = await isUsernameAvailable(newUsername);
        if (!isAvailable) {
          ErrorHandler.showWarning('Este username já está em uso. Tente outro.');
          return false;
        }
        
        EnhancedLogger.info('Updating username', tag: 'USERNAME', data: {
          'userId': userId,
          'newUsername': newUsername,
        });
        
        // Obter username atual para histórico
        final currentUserDoc = await _firestore.collection('usuarios').doc(userId).get();
        final currentUsername = currentUserDoc.data()?['username'] as String?;
        
        // Atualizar histórico de usernames
        List<String> usernameHistory = [];
        if (currentUserDoc.exists && currentUserDoc.data()?['usernameHistory'] != null) {
          usernameHistory = List<String>.from(currentUserDoc.data()!['usernameHistory']);
        }
        
        if (currentUsername != null && currentUsername.isNotEmpty) {
          usernameHistory.add(currentUsername);
          // Manter apenas os últimos 5 usernames
          if (usernameHistory.length > 5) {
            usernameHistory = usernameHistory.sublist(usernameHistory.length - 5);
          }
        }
        
        // Usar o sincronizador para atualizar em ambas as collections
        await ProfileDataSynchronizer.updateUsername(userId, newUsername);
        
        // Atualizar histórico na collection usuarios
        await _firestore.collection('usuarios').doc(userId).update({
          'usernameHistory': usernameHistory,
          'usernameChangedAt': Timestamp.fromDate(DateTime.now()),
        });
        
        EnhancedLogger.success('Username updated successfully', tag: 'USERNAME', data: {
          'userId': userId,
          'newUsername': newUsername,
          'historyCount': usernameHistory.length,
        });
        
        ErrorHandler.showSuccess('Username atualizado com sucesso!');
        return true;
      },
      context: 'UsernameManagementService.updateUsername',
      fallbackValue: false,
    ) ?? false;
  }
  
  /// Gera sugestões de username baseado no nome
  static Future<List<String>> generateSuggestions(String baseName) async {
    return await ErrorHandler.safeExecute(
      () async {
        EnhancedLogger.debug('Generating username suggestions', tag: 'USERNAME', data: {
          'baseName': baseName,
        });
        
        final suggestions = DataValidator.generateUsernameSuggestions(baseName);
        final availableSuggestions = <String>[];
        
        // Verificar disponibilidade de cada sugestão
        for (final suggestion in suggestions) {
          final isAvailable = await isUsernameAvailable(suggestion);
          if (isAvailable) {
            availableSuggestions.add(suggestion);
          }
          
          // Parar quando tiver 5 sugestões disponíveis
          if (availableSuggestions.length >= 5) {
            break;
          }
        }
        
        EnhancedLogger.debug('Username suggestions generated', tag: 'USERNAME', data: {
          'baseName': baseName,
          'totalSuggestions': suggestions.length,
          'availableSuggestions': availableSuggestions.length,
        });
        
        return availableSuggestions;
      },
      context: 'UsernameManagementService.generateSuggestions',
      fallbackValue: <String>[],
    ) ?? <String>[];
  }
  
  /// Obtém histórico de usernames do usuário
  static Future<List<String>> getUsernameHistory(String userId) async {
    return await ErrorHandler.safeExecute(
      () async {
        final userDoc = await _firestore.collection('usuarios').doc(userId).get();
        
        if (!userDoc.exists || userDoc.data()?['usernameHistory'] == null) {
          return <String>[];
        }
        
        return List<String>.from(userDoc.data()!['usernameHistory']);
      },
      context: 'UsernameManagementService.getUsernameHistory',
      fallbackValue: <String>[],
    ) ?? <String>[];
  }
  
  /// Verifica se o usuário pode alterar o username (limite de tempo)
  static Future<bool> canChangeUsername(String userId) async {
    return await ErrorHandler.safeExecute(
      () async {
        final userDoc = await _firestore.collection('usuarios').doc(userId).get();
        
        if (!userDoc.exists) {
          return false;
        }
        
        final lastChange = userDoc.data()?['usernameChangedAt'] as Timestamp?;
        if (lastChange == null) {
          return true; // Primeira vez alterando
        }
        
        // Permitir alteração apenas após 30 dias
        final daysSinceLastChange = DateTime.now().difference(lastChange.toDate()).inDays;
        return daysSinceLastChange >= 30;
      },
      context: 'UsernameManagementService.canChangeUsername',
      fallbackValue: false,
    ) ?? false;
  }
  
  /// Obtém informações sobre quando o usuário pode alterar o username novamente
  static Future<UsernameChangeInfo> getChangeInfo(String userId) async {
    return await ErrorHandler.safeExecute(
      () async {
        final userDoc = await _firestore.collection('usuarios').doc(userId).get();
        
        if (!userDoc.exists) {
          return UsernameChangeInfo(
            canChange: false,
            daysUntilNextChange: 0,
            lastChangeDate: null,
            currentUsername: null,
          );
        }
        
        final data = userDoc.data()!;
        final currentUsername = data['username'] as String?;
        final lastChange = data['usernameChangedAt'] as Timestamp?;
        
        if (lastChange == null) {
          return UsernameChangeInfo(
            canChange: true,
            daysUntilNextChange: 0,
            lastChangeDate: null,
            currentUsername: currentUsername,
          );
        }
        
        final daysSinceLastChange = DateTime.now().difference(lastChange.toDate()).inDays;
        final canChange = daysSinceLastChange >= 30;
        final daysUntilNextChange = canChange ? 0 : (30 - daysSinceLastChange);
        
        return UsernameChangeInfo(
          canChange: canChange,
          daysUntilNextChange: daysUntilNextChange,
          lastChangeDate: lastChange.toDate(),
          currentUsername: currentUsername,
        );
      },
      context: 'UsernameManagementService.getChangeInfo',
      fallbackValue: UsernameChangeInfo(
        canChange: false,
        daysUntilNextChange: 30,
        lastChangeDate: null,
        currentUsername: null,
      ),
    ) ?? UsernameChangeInfo(
      canChange: false,
      daysUntilNextChange: 30,
      lastChangeDate: null,
      currentUsername: null,
    );
  }
  
  /// Reserva um username temporariamente (para evitar conflitos durante o processo)
  static Future<String?> reserveUsername(String username) async {
    return await ErrorHandler.safeExecute(
      () async {
        final reservationId = '${DateTime.now().millisecondsSinceEpoch}_${FirebaseAuth.instance.currentUser?.uid}';
        
        await _firestore.collection('username_reservations').doc(username).set({
          'reservationId': reservationId,
          'userId': FirebaseAuth.instance.currentUser?.uid,
          'reservedAt': Timestamp.fromDate(DateTime.now()),
          'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 5))),
        });
        
        return reservationId;
      },
      context: 'UsernameManagementService.reserveUsername',
    );
  }
  
  /// Libera uma reserva de username
  static Future<void> releaseUsernameReservation(String username) async {
    await ErrorHandler.safeExecute(
      () async {
        await _firestore.collection('username_reservations').doc(username).delete();
      },
      context: 'UsernameManagementService.releaseUsernameReservation',
      showUserMessage: false,
    );
  }
  
  /// Limpa reservas expiradas
  static Future<void> cleanExpiredReservations() async {
    await ErrorHandler.safeExecute(
      () async {
        final now = Timestamp.fromDate(DateTime.now());
        final expiredQuery = await _firestore
            .collection('username_reservations')
            .where('expiresAt', isLessThan: now)
            .get();
        
        final batch = _firestore.batch();
        for (final doc in expiredQuery.docs) {
          batch.delete(doc.reference);
        }
        
        await batch.commit();
        
        EnhancedLogger.info('Cleaned expired username reservations', tag: 'USERNAME', data: {
          'count': expiredQuery.docs.length,
        });
      },
      context: 'UsernameManagementService.cleanExpiredReservations',
      showUserMessage: false,
    );
  }
}

/// Informações sobre alteração de username
class UsernameChangeInfo {
  final bool canChange;
  final int daysUntilNextChange;
  final DateTime? lastChangeDate;
  final String? currentUsername;
  
  UsernameChangeInfo({
    required this.canChange,
    required this.daysUntilNextChange,
    required this.lastChangeDate,
    required this.currentUsername,
  });
}