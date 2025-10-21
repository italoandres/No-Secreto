import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/fix_timestamp_chat_errors.dart';

/// Monitor automático para detectar e corrigir erros de chat
class AutoChatMonitor {
  static Timer? _monitorTimer;
  static bool _isMonitoring = false;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Inicia o monitoramento automático
  static void startMonitoring() {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    print('🔍 [AUTO_MONITOR] Iniciando monitoramento automático de chat...');
    
    // Verificar a cada 30 segundos
    _monitorTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _checkAndFixChatErrors();
    });
    
    // Executar verificação inicial após 5 segundos
    Timer(Duration(seconds: 5), () {
      _checkAndFixChatErrors();
    });
  }

  /// Para o monitoramento
  static void stopMonitoring() {
    _monitorTimer?.cancel();
    _isMonitoring = false;
    print('⏹️ [AUTO_MONITOR] Monitoramento parado');
  }

  /// Verifica e corrige erros de chat automaticamente
  static Future<void> _checkAndFixChatErrors() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      print('🔍 [AUTO_MONITOR] Verificando erros de chat...');
      
      // Verificar se há chats com timestamps null
      final problematicChats = await _findProblematicChats();
      
      if (problematicChats.isNotEmpty) {
        print('🚨 [AUTO_MONITOR] ${problematicChats.length} chats com problemas detectados');
        
        // Corrigir automaticamente
        await TimestampChatErrorsFixer.fixAllTimestampErrors();
        
        print('✅ [AUTO_MONITOR] Correção automática aplicada');
      } else {
        print('✅ [AUTO_MONITOR] Nenhum problema detectado');
      }
      
    } catch (e) {
      print('❌ [AUTO_MONITOR] Erro no monitoramento: $e');
    }
  }

  /// Encontra chats com problemas
  static Future<List<String>> _findProblematicChats() async {
    final problematicChats = <String>[];
    
    try {
      // Buscar chats com timestamps null
      final chatsQuery = await _firestore
          .collection('match_chats')
          .limit(10) // Verificar apenas os primeiros 10 para performance
          .get();
      
      for (final doc in chatsQuery.docs) {
        final data = doc.data();
        
        // Verificar se tem timestamps null
        if (data['createdAt'] == null || 
            data['lastMessageAt'] == null || 
            data['expiresAt'] == null) {
          problematicChats.add(doc.id);
        }
      }
      
    } catch (e) {
      print('❌ [AUTO_MONITOR] Erro ao buscar chats problemáticos: $e');
    }
    
    return problematicChats;
  }

  /// Verifica se um chat específico tem problemas
  static Future<bool> checkSpecificChat(String chatId) async {
    try {
      final chatDoc = await _firestore
          .collection('match_chats')
          .doc(chatId)
          .get();
      
      if (!chatDoc.exists) {
        print('⚠️ [AUTO_MONITOR] Chat não existe: $chatId');
        return true; // Chat não existe é um problema
      }
      
      final data = chatDoc.data()!;
      
      // Verificar timestamps null
      if (data['createdAt'] == null || 
          data['lastMessageAt'] == null || 
          data['expiresAt'] == null) {
        print('⚠️ [AUTO_MONITOR] Chat com timestamps null: $chatId');
        return true;
      }
      
      return false; // Chat está OK
      
    } catch (e) {
      print('❌ [AUTO_MONITOR] Erro ao verificar chat $chatId: $e');
      return true; // Em caso de erro, considerar problemático
    }
  }

  /// Corrige um chat específico se necessário
  static Future<void> fixChatIfNeeded(String chatId) async {
    try {
      final hasProblems = await checkSpecificChat(chatId);
      
      if (hasProblems) {
        print('🔧 [AUTO_MONITOR] Corrigindo chat específico: $chatId');
        await TimestampChatErrorsFixer.fixSpecificMissingChat();
        print('✅ [AUTO_MONITOR] Chat específico corrigido');
      }
      
    } catch (e) {
      print('❌ [AUTO_MONITOR] Erro ao corrigir chat específico: $e');
    }
  }

  /// Força uma verificação manual
  static Future<void> forceCheck() async {
    print('🔍 [AUTO_MONITOR] Verificação manual forçada');
    await _checkAndFixChatErrors();
  }

  /// Status do monitoramento
  static bool get isMonitoring => _isMonitoring;
}

/// Mixin para adicionar monitoramento automático a widgets
mixin AutoChatMonitorMixin {
  void startChatMonitoring() {
    AutoChatMonitor.startMonitoring();
  }
  
  void stopChatMonitoring() {
    AutoChatMonitor.stopMonitoring();
  }
  
  Future<void> checkChatHealth(String chatId) async {
    await AutoChatMonitor.fixChatIfNeeded(chatId);
  }
}