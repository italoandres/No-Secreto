import 'package:shared_preferences/shared_preferences.dart';

/// Rastreia negações de permissões e determina quando re-perguntar
/// 
/// Usado para evitar incomodar o usuário constantemente com pedidos
/// de permissão que já foram negados. Aguarda 7 dias antes de perguntar novamente.
class PermissionTracker {
  static const String _keyLastDenial = 'last_system_alert_denial';
  static const int _daysBeforeReask = 7;
  
  /// Salva o timestamp da negação de permissão
  /// 
  /// Deve ser chamado quando o usuário nega a permissão de sobrepor apps
  Future<void> recordDenial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(_keyLastDenial, now);
      print('📝 PERMISSION_TRACKER: Negação registrada em ${DateTime.now()}');
    } catch (e) {
      print('⚠️ PERMISSION_TRACKER: Erro ao registrar negação: $e');
    }
  }
  
  /// Verifica se deve perguntar novamente sobre a permissão
  /// 
  /// Retorna true se:
  /// - Nunca foi negado antes (primeira vez)
  /// - Passaram 7 dias ou mais desde a última negação
  /// 
  /// Retorna false se:
  /// - Passaram menos de 7 dias desde a última negação
  Future<bool> shouldAskAgain() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastDenialTimestamp = prefs.getInt(_keyLastDenial);
      
      // Se nunca foi negado, pode perguntar
      if (lastDenialTimestamp == null) {
        print('✅ PERMISSION_TRACKER: Primeira vez, pode perguntar');
        return true;
      }
      
      // Calcular dias desde última negação
      final lastDenial = DateTime.fromMillisecondsSinceEpoch(lastDenialTimestamp);
      final now = DateTime.now();
      final daysSince = now.difference(lastDenial).inDays;
      
      final shouldAsk = daysSince >= _daysBeforeReask;
      
      if (shouldAsk) {
        print('✅ PERMISSION_TRACKER: Passaram $daysSince dias, pode perguntar novamente');
      } else {
        print('⏳ PERMISSION_TRACKER: Passaram apenas $daysSince dias, aguardar ${_daysBeforeReask - daysSince} dias');
      }
      
      return shouldAsk;
    } catch (e) {
      print('⚠️ PERMISSION_TRACKER: Erro ao verificar, permitindo pergunta: $e');
      // Em caso de erro, permitir pergunta (comportamento seguro)
      return true;
    }
  }
  
  /// Limpa o registro de negação quando a permissão é concedida
  /// 
  /// Deve ser chamado quando o usuário finalmente concede a permissão
  Future<void> clearDenial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyLastDenial);
      print('🧹 PERMISSION_TRACKER: Registro de negação limpo');
    } catch (e) {
      print('⚠️ PERMISSION_TRACKER: Erro ao limpar registro: $e');
    }
  }
  
  /// Obtém quantos dias se passaram desde a última negação
  /// 
  /// Útil para debug e logs. Retorna 0 se nunca foi negado.
  Future<int> daysSinceLastDenial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastDenialTimestamp = prefs.getInt(_keyLastDenial);
      
      if (lastDenialTimestamp == null) {
        return 0;
      }
      
      final lastDenial = DateTime.fromMillisecondsSinceEpoch(lastDenialTimestamp);
      final now = DateTime.now();
      return now.difference(lastDenial).inDays;
    } catch (e) {
      print('⚠️ PERMISSION_TRACKER: Erro ao calcular dias: $e');
      return 0;
    }
  }
}
