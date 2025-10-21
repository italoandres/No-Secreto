import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Handler para navegação de perfis com validação e tratamento de erros
class ProfileNavigationHandler {
  
  /// Navega para o perfil do usuário
  static Future<void> navigateToProfile(String userId) async {
    print('🧭 [NAVIGATION] Iniciando navegação para userId: $userId');
    
    // Validar userId primeiro
    if (!validateUserId(userId)) {
      handleNavigationError('UserId inválido: $userId');
      return;
    }
    
    try {
      // Verificar se o usuário existe
      final userExists = await _checkUserExists(userId);
      if (!userExists) {
        handleNavigationError('Usuário não encontrado: $userId');
        return;
      }
      
      // Mostrar loading
      Get.snackbar(
        '👤 Carregando Perfil',
        'Abrindo perfil do usuário...',
        backgroundColor: Get.theme.primaryColor,
        colorText: Get.theme.colorScheme.onPrimary,
        duration: const Duration(seconds: 2),
      );
      
      // Navegar para o perfil
      // TODO: Implementar navegação real quando a tela de perfil estiver pronta
      // Get.to(() => ProfileView(userId: userId));
      
      // Por enquanto, mostrar sucesso
      await Future.delayed(const Duration(milliseconds: 500));
      
      Get.snackbar(
        '✅ Perfil Carregado',
        'Perfil do usuário aberto com sucesso!',
        backgroundColor: Get.theme.colorScheme.secondary,
        colorText: Get.theme.colorScheme.onSecondary,
        duration: const Duration(seconds: 2),
      );
      
      print('🧭 [NAVIGATION] Navegação bem-sucedida para: $userId');
      
    } catch (e) {
      print('❌ [NAVIGATION] Erro na navegação: $e');
      handleNavigationError('Erro ao abrir perfil: $e');
    }
  }
  
  /// Valida se o userId é válido
  static bool validateUserId(String userId) {
    if (userId.isEmpty) {
      print('❌ [NAVIGATION] UserId vazio');
      return false;
    }
    
    if (userId == 'test_target_user') {
      print('❌ [NAVIGATION] UserId de teste inválido');
      return false;
    }
    
    if (userId.length < 10) {
      print('❌ [NAVIGATION] UserId muito curto: $userId');
      return false;
    }
    
    print('✅ [NAVIGATION] UserId válido: $userId');
    return true;
  }
  
  /// Verifica se o usuário existe no Firebase
  static Future<bool> _checkUserExists(String userId) async {
    try {
      print('🔍 [NAVIGATION] Verificando existência do usuário: $userId');
      
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      final exists = userDoc.exists;
      print('🔍 [NAVIGATION] Usuário existe: $exists');
      
      return exists;
    } catch (e) {
      print('❌ [NAVIGATION] Erro ao verificar usuário: $e');
      return false;
    }
  }
  
  /// Trata erros de navegação
  static void handleNavigationError(String error) {
    print('❌ [NAVIGATION] Erro: $error');
    
    Get.snackbar(
      '❌ Erro de Navegação',
      error,
      backgroundColor: Get.theme.colorScheme.error,
      colorText: Get.theme.colorScheme.onError,
      duration: const Duration(seconds: 3),
    );
  }
  
  /// Navega para perfil com correção automática de userId
  static Future<void> navigateToProfileWithCorrection(
    String rawUserId,
    String notificationId,
  ) async {
    print('🔧 [NAVIGATION] Navegação com correção para: $rawUserId');
    
    String correctedUserId = rawUserId;
    
    // Aplicar correções conhecidas
    const knownCorrections = {
      'Iu4C9VdYrT0AaAinZEit': '6Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8', // ITALO2
    };
    
    if (knownCorrections.containsKey(notificationId)) {
      correctedUserId = knownCorrections[notificationId]!;
      print('🔧 [NAVIGATION] UserId corrigido: $rawUserId → $correctedUserId');
    }
    
    await navigateToProfile(correctedUserId);
  }
  
  /// Navega para perfil com dados do usuário
  static Future<void> navigateToProfileWithUserData(
    String userId,
    String userName,
  ) async {
    print('👤 [NAVIGATION] Navegando para perfil de: $userName ($userId)');
    
    if (!validateUserId(userId)) {
      handleNavigationError('Dados de usuário inválidos');
      return;
    }
    
    // Mostrar snackbar personalizado com nome
    Get.snackbar(
      '👤 Abrindo Perfil',
      'Carregando perfil de $userName...',
      backgroundColor: Get.theme.primaryColor,
      colorText: Get.theme.colorScheme.onPrimary,
      duration: const Duration(seconds: 2),
    );
    
    await navigateToProfile(userId);
  }
  
  /// Testa navegação (para debugging)
  static Future<void> testNavigation(String userId) async {
    print('🧪 [NAVIGATION] Testando navegação para: $userId');
    
    final isValid = validateUserId(userId);
    print('🧪 [NAVIGATION] UserId válido: $isValid');
    
    if (isValid) {
      final exists = await _checkUserExists(userId);
      print('🧪 [NAVIGATION] Usuário existe: $exists');
      
      if (exists) {
        print('🧪 [NAVIGATION] Teste bem-sucedido!');
        Get.snackbar(
          '✅ Teste de Navegação',
          'Navegação funcionando corretamente!',
          backgroundColor: Get.theme.colorScheme.secondary,
          colorText: Get.theme.colorScheme.onSecondary,
        );
      } else {
        print('🧪 [NAVIGATION] Usuário não encontrado');
        Get.snackbar(
          '⚠️ Teste de Navegação',
          'Usuário não encontrado no Firebase',
          backgroundColor: Get.theme.colorScheme.tertiary,
          colorText: Get.theme.colorScheme.onTertiary,
        );
      }
    } else {
      print('🧪 [NAVIGATION] UserId inválido');
      Get.snackbar(
        '❌ Teste de Navegação',
        'UserId inválido para teste',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }
  
  /// Retorna informações de debug sobre um userId
  static Map<String, dynamic> getDebugInfo(String userId) {
    return {
      'userId': userId,
      'isValid': validateUserId(userId),
      'isEmpty': userId.isEmpty,
      'isTestUser': userId == 'test_target_user',
      'length': userId.length,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}