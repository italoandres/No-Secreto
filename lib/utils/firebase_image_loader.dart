import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FirebaseImageLoader {
  /// Carrega imagem do Firebase Storage com headers apropriados para Web
  static Widget buildFirebaseImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    debugPrint('🔥 FIREBASE IMAGE: Carregando $imageUrl');

    // Para Flutter Web, usar Image.network com headers específicos
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers':
            'Origin, Content-Type, Accept, Authorization, X-Requested-With',
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          debugPrint('✅ FIREBASE IMAGE: Carregada com sucesso');
          return child;
        }

        final progress = loadingProgress.expectedTotalBytes != null
            ? loadingProgress.cumulativeBytesLoaded /
                loadingProgress.expectedTotalBytes!
            : null;

        return placeholder ??
            Center(
              child: CircularProgressIndicator(
                value: progress,
                color: Colors.white,
              ),
            );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('❌ FIREBASE IMAGE ERROR: $error');
        debugPrint('❌ STACK: $stackTrace');

        // Tentar com CachedNetworkImage como fallback
        return CachedNetworkImage(
          imageUrl: imageUrl,
          width: width,
          height: height,
          fit: fit,
          placeholder: (context, url) =>
              placeholder ??
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
          errorWidget: (context, url, error) {
            debugPrint('❌ CACHED IMAGE ERROR: $error');
            return errorWidget ??
                const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image,
                        color: Colors.red,
                        size: 64,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Erro ao carregar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                );
          },
        );
      },
    );
  }

  /// Versão simplificada para teste
  static Widget buildSimpleImage({
    required String imageUrl,
    BoxFit fit = BoxFit.contain,
  }) {
    debugPrint('🔥 SIMPLE IMAGE: Carregando $imageUrl');

    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Mostrar informações da URL
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.info,
                    color: Colors.blue,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tentando carregar imagem...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'URL: ${imageUrl.length > 60 ? imageUrl.substring(0, 60) + "..." : imageUrl}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Tentar carregar a imagem
            Expanded(
              child: Image.network(
                imageUrl,
                fit: fit,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;

                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'Carregando imagem...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Erro ao carregar imagem',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Erro: $error',
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Possíveis causas:\n• Problema de CORS\n• URL inválida\n• Imagem corrompida',
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
