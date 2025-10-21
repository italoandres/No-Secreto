import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Serviço de notificações para certificação espiritual
/// 
/// Este serviço gerencia as notificações de certificação criadas pela Cloud Function.
/// Ele NÃO cria notificações (isso é feito pela Cloud Function onCertificationStatusChange),
/// mas sim lê, exibe e gerencia a navegação quando o usuário toca nas notificações.
class CertificationNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obter stream de notificações de certificação do usuário
  /// 
  /// Retorna um stream com todas as notificações de certificação (aprovadas e reprovadas)
  /// ordenadas por data de criação (mais recentes primeiro).
  Stream<List<Map<String, dynamic>>> getCertificationNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('type', whereIn: [
          'certification_approved',
          'certification_rejected',
        ])
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id; // Adicionar ID do documento
            return data;
          }).toList();
        });
  }

  /// Obter todas as notificações do usuário (não apenas certificação)
  /// 
  /// Útil para exibir em uma lista geral de notificações
  Stream<List<Map<String, dynamic>>> getAllNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  /// Obter contagem de notificações não lidas de certificação
  Stream<int> getUnreadCertificationNotificationsCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('type', whereIn: [
          'certification_approved',
          'certification_rejected',
        ])
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Obter contagem total de notificações não lidas
  Stream<int> getUnreadNotificationsCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Marcar notificação como lida
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({
            'read': true,
            'readAt': FieldValue.serverTimestamp(),
          });
      
      print('✅ Notificação $notificationId marcada como lida');
    } catch (e) {
      print('❌ Erro ao marcar notificação como lida: $e');
      rethrow;
    }
  }

  /// Marcar todas as notificações como lidas
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      
      final unreadNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();
      
      for (var doc in unreadNotifications.docs) {
        batch.update(doc.reference, {
          'read': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      print('✅ Todas as notificações marcadas como lidas');
    } catch (e) {
      print('❌ Erro ao marcar todas as notificações como lidas: $e');
      rethrow;
    }
  }

  /// Deletar notificação
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();
      
      print('✅ Notificação $notificationId deletada');
    } catch (e) {
      print('❌ Erro ao deletar notificação: $e');
      rethrow;
    }
  }

  /// Deletar todas as notificações lidas
  Future<void> deleteAllRead(String userId) async {
    try {
      final batch = _firestore.batch();
      
      final readNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: true)
          .get();
      
      for (var doc in readNotifications.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      print('✅ Todas as notificações lidas foram deletadas');
    } catch (e) {
      print('❌ Erro ao deletar notificações lidas: $e');
      rethrow;
    }
  }

  /// Lidar com o toque em uma notificação
  /// 
  /// Esta função determina para onde navegar baseado no tipo de ação da notificação.
  /// Também marca a notificação como lida automaticamente.
  Future<void> handleNotificationTap(
    BuildContext context,
    Map<String, dynamic> notification,
  ) async {
    try {
      final notificationId = notification['id'] as String?;
      final actionType = notification['actionType'] as String?;
      final type = notification['type'] as String?;
      
      // Marcar como lida
      if (notificationId != null) {
        await markAsRead(notificationId);
      }
      
      // Navegar baseado no tipo de ação
      if (actionType == 'view_profile') {
        // Certificação aprovada - navegar para o perfil
        print('📱 Navegando para o perfil');
        Get.toNamed('/profile');
      } else if (actionType == 'retry_certification') {
        // Certificação reprovada - navegar para tela de certificação
        print('📱 Navegando para tela de certificação');
        Get.toNamed('/spiritual-certification-request');
      } else if (type == 'certification_approved') {
        // Fallback para aprovação
        Get.toNamed('/profile');
      } else if (type == 'certification_rejected') {
        // Fallback para reprovação
        Get.toNamed('/spiritual-certification-request');
      } else {
        // Tipo desconhecido - apenas fechar
        print('⚠️ Tipo de notificação desconhecido: $type');
      }
    } catch (e) {
      print('❌ Erro ao lidar com toque na notificação: $e');
      
      // Mostrar snackbar de erro
      Get.snackbar(
        'Erro',
        'Não foi possível abrir a notificação',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Obter ícone apropriado para o tipo de notificação
  IconData getNotificationIcon(String type) {
    switch (type) {
      case 'certification_approved':
        return Icons.verified;
      case 'certification_rejected':
        return Icons.info_outline;
      default:
        return Icons.notifications;
    }
  }

  /// Obter cor apropriada para o tipo de notificação
  Color getNotificationColor(String type) {
    switch (type) {
      case 'certification_approved':
        return Colors.green;
      case 'certification_rejected':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  /// Verificar se o usuário tem notificações não lidas
  Future<bool> hasUnreadNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .limit(1)
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Erro ao verificar notificações não lidas: $e');
      return false;
    }
  }

  /// Obter a notificação mais recente de certificação
  Future<Map<String, dynamic>?> getLatestCertificationNotification(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('type', whereIn: [
            'certification_approved',
            'certification_rejected',
          ])
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) {
        return null;
      }
      
      final data = snapshot.docs.first.data();
      data['id'] = snapshot.docs.first.id;
      return data;
    } catch (e) {
      print('❌ Erro ao obter última notificação de certificação: $e');
      return null;
    }
  }
}
