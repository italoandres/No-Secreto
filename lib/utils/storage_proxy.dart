class StorageProxy {
  static const String _functionUrl = 'https://us-central1-app-no-secreto-com-o-pai.cloudfunctions.net/getStorageImage';
  
  /// Converte URL do Firebase Storage para usar nossa Cloud Function
  static String getProxiedUrl(String firebaseStorageUrl) {
    try {
      // Extrair o path do arquivo da URL do Firebase Storage
      final uri = Uri.parse(firebaseStorageUrl);
      
      // Formato: /v0/b/bucket/o/path%2Fto%2Ffile.ext
      final pathSegments = uri.pathSegments;
      
      if (pathSegments.length >= 4 && pathSegments[0] == 'v0' && pathSegments[1] == 'b' && pathSegments[3] == 'o') {
        // Extrair o path do arquivo (depois de /o/)
        final encodedPath = pathSegments.skip(4).join('/');
        final decodedPath = Uri.decodeComponent(encodedPath);
        
        // Construir URL da Cloud Function
        final proxiedUrl = '$_functionUrl?path=${Uri.encodeComponent(decodedPath)}';
        
        print('🔄 PROXY: Convertendo URL');
        print('📥 Original: $firebaseStorageUrl');
        print('📤 Proxied: $proxiedUrl');
        
        return proxiedUrl;
      }
      
      print('⚠️ PROXY: URL não reconhecida como Firebase Storage, usando original');
      return firebaseStorageUrl;
      
    } catch (e) {
      print('❌ PROXY: Erro ao converter URL: $e');
      return firebaseStorageUrl;
    }
  }
  
  /// Verifica se uma URL é do Firebase Storage
  static bool isFirebaseStorageUrl(String url) {
    return url.contains('firebasestorage.googleapis.com');
  }
}