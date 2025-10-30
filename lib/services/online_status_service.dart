import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:whatsapp_chat/utils/debug_utils.dart';

/// ⚡ Serviço OTIMIZADO para gerenciar o status online dos usuários
/// 
/// MELHORIAS:
/// - ✅ Debounce para evitar múltiplas chamadas rápidas
/// - ✅ Timeouts adequados
/// - ✅ Logs condicionais (não trava em produção)
/// - ✅ Tratamento robusto de erros
class OnlineStatusService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // ⚡ DEBOUNCE: Aguarda 2 segundos antes de atualizar
  // Evita múltiplas chamadas ao Firestore em sequência rápida
  static Timer? _updateDebounceTimer;
  static Timer? _setOnlineDebounceTimer;
  
  // Cache do último status para evitar atualizações desnecessárias
  static DateTime? _lastUpdateTime;
  static const Duration _minUpdateInterval = Duration(seconds: 30);

  /// Atualiza o lastSeen do usuário atual (COM DEBOUNCE)
  static Future<void> updateLastSeen() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        safePrint('⚠️ updateLastSeen: Usuário não autenticado');
        return;
      }

      // Verificar se precisa atualizar (não atualizar muito frequentemente)
      final now = DateTime.now();
      if (_lastUpdateTime != null) {
        final diff = now.difference(_lastUpdateTime!);
        if (diff < _minUpdateInterval) {
          safePrint('⏭️ updateLastSeen: Pulando atualização (última foi há ${diff.inSeconds}s)');
          return;
        }
      }

      // Cancelar timer anterior se existir
      _updateDebounceTimer?.cancel();
      
      // Criar novo timer com debounce de 2 segundos
      _updateDebounceTimer = Timer(const Duration(seconds: 2), () async {
        try {
          safePrint('📄 Atualizando lastSeen para ${currentUser.uid}');
          
          await _firestore
              .collection('usuarios')
              .doc(currentUser.uid)
              .update({
            'lastSeen': FieldValue.serverTimestamp(),
          }).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              safePrint('⏱️ Timeout ao atualizar lastSeen (não crítico)');
            },
          );

          _lastUpdateTime = DateTime.now();
          safePrint('✅ LastSeen atualizado para ${currentUser.uid}');
        } catch (e) {
          safePrint('⚠️ Erro ao atualizar lastSeen (não crítico): $e');
        }
      });
      
    } catch (e) {
      safePrint('⚠️ Erro em updateLastSeen (não crítico): $e');
      // Não propagar o erro - atualização de lastSeen não é crítica
    }
  }

  /// Marca o usuário como online (chamado quando o app abre) - COM DEBOUNCE
  static Future<void> setUserOnline() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        safePrint('⚠️ setUserOnline: Usuário não autenticado, ignorando');
        return;
      }
      
      // Cancelar timer anterior se existir
      _setOnlineDebounceTimer?.cancel();
      
      // Criar novo timer com debounce de 1 segundo
      _setOnlineDebounceTimer = Timer(const Duration(seconds: 1), () async {
        safePrint('🟢 Marcando usuário como online: ${currentUser.uid}');
        await updateLastSeen();
      });
    } catch (e) {
      safePrint('⚠️ Erro em setUserOnline (não crítico): $e');
    }
  }

  /// Marca o usuário como offline (chamado quando o app fecha)
  static Future<void> setUserOffline() async {
    try {
      // Cancelar qualquer timer pendente
      _updateDebounceTimer?.cancel();
      _setOnlineDebounceTimer?.cancel();
      
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        safePrint('⚠️ setUserOffline: Usuário não autenticado, ignorando');
        return;
      }

      safePrint('🔴 Marcando usuário como offline: ${currentUser.uid}');
      
      // Atualiza o lastSeen para o momento atual antes de sair
      // SEM debounce - precisa ser imediato quando o app fecha
      await _firestore
          .collection('usuarios')
          .doc(currentUser.uid)
          .update({
        'lastSeen': FieldValue.serverTimestamp(),
      }).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          safePrint('⏱️ Timeout ao marcar offline (não crítico)');
        },
      );

      safePrint('✅ Usuário ${currentUser.uid} marcado como offline');
    } catch (e) {
      safePrint('⚠️ Erro ao marcar usuário como offline (não crítico): $e');
      // Não propagar o erro - atualização de status não é crítica
    }
  }
  
  /// Limpa todos os timers (útil para testes e cleanup)
  static void dispose() {
    _updateDebounceTimer?.cancel();
    _setOnlineDebounceTimer?.cancel();
    _updateDebounceTimer = null;
    _setOnlineDebounceTimer = null;
    _lastUpdateTime = null;
  }
}