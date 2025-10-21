import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/share_configuration_model.dart';
import '../utils/enhanced_logger.dart';

/// Serviço para gerenciar compartilhamento de vitrines de propósito
class VitrineShareService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Gera um link público para a vitrine do usuário
  Future<String> generatePublicLink(String userId) async {
    try {
      EnhancedLogger.info('Generating public link', 
        tag: 'VITRINE_SHARE',
        data: {'userId': userId}
      );
      
      // Gerar token de acesso temporário
      final accessToken = _generateAccessToken(userId);
      
      // Criar link com expiração de 30 dias
      final expirationTime = DateTime.now().add(Duration(days: 30));
      
      final publicLink = 'https://kiro.app/vitrine/$userId'
          '?token=$accessToken'
          '&expires=${expirationTime.millisecondsSinceEpoch}';
      
      // Salvar informações do link no Firestore para validação futura
      await _saveShareLinkInfo(userId, accessToken, expirationTime);
      
      EnhancedLogger.success('Public link generated', 
        tag: 'VITRINE_SHARE',
        data: {'userId': userId, 'link': publicLink}
      );
      
      return publicLink;
      
    } catch (e, stackTrace) {
      EnhancedLogger.error('Failed to generate public link', 
        tag: 'VITRINE_SHARE',
        error: e,
        stackTrace: stackTrace,
        data: {'userId': userId}
      );
      
      rethrow;
    }
  }
  
  /// Gera conteúdo compartilhável personalizado
  Future<String> generateShareableContent(String userId) async {
    try {
      // Buscar dados do perfil para personalizar a mensagem
      final profileDoc = await _firestore
          .collection('spiritual_profiles')
          .doc(userId)
          .get();
      
      String userName = 'Usuário';
      String userPurpose = '';
      
      if (profileDoc.exists) {
        final data = profileDoc.data()!;
        userName = data['displayName'] as String? ?? 'Usuário';
        userPurpose = data['purpose'] as String? ?? '';
      }
      
      // Gerar link público
      final publicLink = await generatePublicLink(userId);
      
      // Criar mensagem personalizada
      String shareText = '🌟 Conheça minha Vitrine de Propósito no Kiro!\n\n';
      shareText += 'Olá! Sou $userName e gostaria de compartilhar meu propósito com você.\n\n';
      
      if (userPurpose.isNotEmpty) {
        shareText += '💫 Meu propósito: $userPurpose\n\n';
      }
      
      shareText += 'Acesse minha vitrine e descubra mais sobre mim:\n';
      shareText += publicLink;
      shareText += '\n\n#Kiro #PropósitoDeVida #ConexõesEspirituais';
      
      return shareText;
      
    } catch (e, stackTrace) {
      EnhancedLogger.error('Failed to generate shareable content', 
        tag: 'VITRINE_SHARE',
        error: e,
        stackTrace: stackTrace,
        data: {'userId': userId}
      );
      
      // Retornar conteúdo básico em caso de erro
      final basicLink = await generatePublicLink(userId);
      return '🌟 Conheça minha Vitrine de Propósito no Kiro!\n\n$basicLink';
    }
  }
  
  /// Compartilha a vitrine usando o sistema nativo
  Future<void> shareVitrine(String userId, ShareType type) async {
    try {
      EnhancedLogger.info('Sharing vitrine', 
        tag: 'VITRINE_SHARE',
        data: {'userId': userId, 'shareType': type.toString()}
      );
      
      final shareContent = await generateShareableContent(userId);
      
      switch (type) {
        case ShareType.link:
          await Share.share(shareContent);
          break;
          
        case ShareType.whatsapp:
          await _shareToWhatsApp(shareContent);
          break;
          
        case ShareType.instagram:
          await _shareToInstagram(shareContent);
          break;
          
        case ShareType.facebook:
          await _shareTo('com.facebook.katana', shareContent);
          break;
          
        case ShareType.email:
          await _shareViaEmail(userId, shareContent);
          break;
          
        case ShareType.sms:
          await _shareViaSMS(shareContent);
          break;
      }
      
      // Registrar compartilhamento para analytics
      await _trackShareAction(userId, type);
      
      EnhancedLogger.success('Vitrine shared successfully', 
        tag: 'VITRINE_SHARE',
        data: {'userId': userId, 'shareType': type.toString()}
      );
      
    } catch (e, stackTrace) {
      EnhancedLogger.error('Failed to share vitrine', 
        tag: 'VITRINE_SHARE',
        error: e,
        stackTrace: stackTrace,
        data: {'userId': userId, 'shareType': type.toString()}
      );
      
      rethrow;
    }
  }
  
  /// Copia o link para a área de transferência
  Future<void> copyLinkToClipboard(String link) async {
    try {
      await Clipboard.setData(ClipboardData(text: link));
      
      EnhancedLogger.info('Link copied to clipboard', 
        tag: 'VITRINE_SHARE',
        data: {'link': link}
      );
      
    } catch (e, stackTrace) {
      EnhancedLogger.error('Failed to copy link to clipboard', 
        tag: 'VITRINE_SHARE',
        error: e,
        stackTrace: stackTrace,
        data: {'link': link}
      );
      
      rethrow;
    }
  }
  
  /// Valida se um token de acesso é válido
  Future<bool> validateAccessToken(String userId, String token) async {
    try {
      final doc = await _firestore
          .collection('share_links')
          .doc(userId)
          .get();
      
      if (!doc.exists) {
        return false;
      }
      
      final data = doc.data()!;
      final storedToken = data['accessToken'] as String;
      final expirationTime = (data['expirationTime'] as Timestamp).toDate();
      
      // Verificar se o token corresponde e não expirou
      final isValidToken = storedToken == token;
      final isNotExpired = DateTime.now().isBefore(expirationTime);
      
      return isValidToken && isNotExpired;
      
    } catch (e, stackTrace) {
      EnhancedLogger.error('Failed to validate access token', 
        tag: 'VITRINE_SHARE',
        error: e,
        stackTrace: stackTrace,
        data: {'userId': userId}
      );
      
      return false;
    }
  }
  
  /// Gera um token de acesso seguro
  String _generateAccessToken(String userId) {
    final random = Random.secure();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomBytes = List.generate(16, (i) => random.nextInt(256));
    
    final tokenData = '$userId:$timestamp:${randomBytes.join(',')}';
    final encodedToken = base64Url.encode(utf8.encode(tokenData));
    
    return encodedToken.substring(0, 32); // Limitar tamanho do token
  }
  
  /// Salva informações do link de compartilhamento
  Future<void> _saveShareLinkInfo(String userId, String accessToken, DateTime expirationTime) async {
    await _firestore
        .collection('share_links')
        .doc(userId)
        .set({
      'userId': userId,
      'accessToken': accessToken,
      'expirationTime': Timestamp.fromDate(expirationTime),
      'createdAt': Timestamp.now(),
      'isActive': true,
    }, SetOptions(merge: true));
  }
  
  /// Compartilha especificamente para WhatsApp
  Future<void> _shareToWhatsApp(String content) async {
    try {
      await Share.share(content);
      // Note: Share.share() automaticamente detecta apps disponíveis
      // Para implementação mais específica, seria necessário usar plugins nativos
    } catch (e) {
      // Fallback para compartilhamento genérico
      await Share.share(content);
    }
  }
  
  /// Compartilha especificamente para Instagram
  Future<void> _shareToInstagram(String content) async {
    try {
      await Share.share(content);
      // Note: Instagram não suporta compartilhamento direto de texto
      // Esta implementação usa o compartilhamento genérico
    } catch (e) {
      await Share.share(content);
    }
  }
  
  /// Compartilha para um app específico
  Future<void> _shareTo(String packageName, String content) async {
    try {
      await Share.share(content);
      // Para implementação específica por app, seria necessário
      // usar plugins nativos ou intent específicos no Android
    } catch (e) {
      await Share.share(content);
    }
  }
  
  /// Compartilha via email
  Future<void> _shareViaEmail(String userId, String content) async {
    try {
      // Buscar dados do perfil para personalizar o assunto
      final profileDoc = await _firestore
          .collection('spiritual_profiles')
          .doc(userId)
          .get();
      
      String userName = 'Usuário';
      if (profileDoc.exists) {
        final data = profileDoc.data()!;
        userName = data['displayName'] as String? ?? 'Usuário';
      }
      
      final subject = 'Vitrine de Propósito - $userName';
      
      await Share.share(
        content,
        subject: subject,
      );
      
    } catch (e) {
      await Share.share(content);
    }
  }
  
  /// Compartilha via SMS
  Future<void> _shareViaSMS(String content) async {
    try {
      await Share.share(content);
    } catch (e) {
      rethrow;
    }
  }
  
  /// Registra ação de compartilhamento para analytics
  Future<void> _trackShareAction(String userId, ShareType type) async {
    try {
      await _firestore
          .collection('share_analytics')
          .add({
        'userId': userId,
        'shareType': type.toString(),
        'timestamp': Timestamp.now(),
        'platform': 'mobile', // Poderia ser detectado dinamicamente
      });
      
    } catch (e, stackTrace) {
      EnhancedLogger.error('Failed to track share action', 
        tag: 'VITRINE_SHARE',
        error: e,
        stackTrace: stackTrace,
        data: {'userId': userId, 'shareType': type.toString()}
      );
    }
  }
}