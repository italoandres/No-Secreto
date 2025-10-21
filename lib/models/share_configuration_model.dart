/// Enum para diferentes tipos de compartilhamento
enum ShareType {
  link,
  whatsapp,
  instagram,
  facebook,
  email,
  sms
}

/// Extensão para obter informações sobre tipos de compartilhamento
extension ShareTypeExtension on ShareType {
  String get displayName {
    switch (this) {
      case ShareType.link:
        return 'Copiar Link';
      case ShareType.whatsapp:
        return 'WhatsApp';
      case ShareType.instagram:
        return 'Instagram';
      case ShareType.facebook:
        return 'Facebook';
      case ShareType.email:
        return 'Email';
      case ShareType.sms:
        return 'SMS';
    }
  }
  
  String get iconName {
    switch (this) {
      case ShareType.link:
        return 'link';
      case ShareType.whatsapp:
        return 'whatsapp';
      case ShareType.instagram:
        return 'instagram';
      case ShareType.facebook:
        return 'facebook';
      case ShareType.email:
        return 'email';
      case ShareType.sms:
        return 'sms';
    }
  }
  
  String get packageName {
    switch (this) {
      case ShareType.whatsapp:
        return 'com.whatsapp';
      case ShareType.instagram:
        return 'com.instagram.android';
      case ShareType.facebook:
        return 'com.facebook.katana';
      default:
        return '';
    }
  }
}

/// Configuração para compartilhamento de vitrine
class ShareConfiguration {
  final String title;
  final String description;
  final String? imageUrl;
  final String deepLink;
  final Map<String, String> platformSpecificData;
  
  const ShareConfiguration({
    required this.title,
    required this.description,
    this.imageUrl,
    required this.deepLink,
    this.platformSpecificData = const {},
  });
  
  /// Gera texto de compartilhamento personalizado por plataforma
  String generateShareText(ShareType type) {
    switch (type) {
      case ShareType.whatsapp:
        return _generateWhatsAppText();
      case ShareType.instagram:
        return _generateInstagramText();
      case ShareType.facebook:
        return _generateFacebookText();
      case ShareType.email:
        return _generateEmailText();
      case ShareType.sms:
        return _generateSMSText();
      case ShareType.link:
      default:
        return _generateGenericText();
    }
  }
  
  /// Obtém dados específicos da plataforma
  Map<String, dynamic> getPlatformData(ShareType type) {
    final baseData = {
      'title': title,
      'description': description,
      'url': deepLink,
    };
    
    if (imageUrl != null) {
      baseData['image'] = imageUrl!;
    }
    
    // Adicionar dados específicos da plataforma
    switch (type) {
      case ShareType.whatsapp:
        baseData['parse_mode'] = 'text';
        break;
      case ShareType.facebook:
        baseData['hashtag'] = '#Kiro';
        break;
      case ShareType.email:
        baseData['subject'] = title;
        break;
      default:
        break;
    }
    
    // Mesclar com dados específicos fornecidos
    baseData.addAll(platformSpecificData);
    
    return baseData;
  }
  
  /// Gera texto genérico para compartilhamento
  String _generateGenericText() {
    String text = '🌟 $title\n\n';
    text += '$description\n\n';
    text += 'Acesse: $deepLink\n\n';
    text += '#Kiro #PropósitoDeVida #ConexõesEspirituais';
    return text;
  }
  
  /// Gera texto otimizado para WhatsApp
  String _generateWhatsAppText() {
    String text = '🌟 *$title*\n\n';
    text += '$description\n\n';
    text += '👆 _Toque no link para conhecer minha vitrine:_\n';
    text += '$deepLink\n\n';
    text += '✨ #Kiro #PropósitoDeVida';
    return text;
  }
  
  /// Gera texto otimizado para Instagram
  String _generateInstagramText() {
    String text = '🌟 $title\n\n';
    text += '$description\n\n';
    text += 'Link na bio ou acesse:\n';
    text += '$deepLink\n\n';
    text += '#Kiro #PropósitoDeVida #ConexõesEspirituais #Espiritualidade #AutoConhecimento';
    return text;
  }
  
  /// Gera texto otimizado para Facebook
  String _generateFacebookText() {
    String text = '🌟 $title\n\n';
    text += '$description\n\n';
    text += 'Conheça minha vitrine de propósito e descubra mais sobre minha jornada espiritual.\n\n';
    text += 'Acesse: $deepLink\n\n';
    text += '#Kiro #PropósitoDeVida #ConexõesEspirituais #Espiritualidade';
    return text;
  }
  
  /// Gera texto otimizado para Email
  String _generateEmailText() {
    String text = 'Olá!\n\n';
    text += 'Gostaria de compartilhar minha Vitrine de Propósito com você.\n\n';
    text += '$description\n\n';
    text += 'Você pode conhecer mais sobre mim acessando o link abaixo:\n';
    text += '$deepLink\n\n';
    text += 'Espero que goste!\n\n';
    text += 'Com carinho,\n';
    text += 'Enviado via Kiro - App de Conexões Espirituais';
    return text;
  }
  
  /// Gera texto otimizado para SMS
  String _generateSMSText() {
    String text = '🌟 $title\n\n';
    text += '$description\n\n';
    text += 'Acesse: $deepLink\n\n';
    text += 'Enviado via Kiro';
    return text;
  }
  
  /// Cria configuração padrão para vitrine
  factory ShareConfiguration.forVitrine({
    required String userName,
    required String userPurpose,
    required String vitrineUrl,
    String? profileImageUrl,
  }) {
    return ShareConfiguration(
      title: 'Vitrine de Propósito - $userName',
      description: userPurpose.isNotEmpty 
        ? 'Meu propósito: $userPurpose'
        : 'Conheça minha jornada espiritual e meu propósito de vida.',
      imageUrl: profileImageUrl,
      deepLink: vitrineUrl,
      platformSpecificData: {
        'userName': userName,
        'userPurpose': userPurpose,
      },
    );
  }
  
  @override
  String toString() {
    return 'ShareConfiguration('
           'title: $title, '
           'description: $description, '
           'deepLink: $deepLink'
           ')';
  }
}