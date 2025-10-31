import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Para detectar Web
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/storie_file_model.dart';
import '../repositories/story_interactions_repository.dart';
import '../repositories/stories_repository.dart';
import '../views/enhanced_stories_viewer_view.dart';
import '../utils/context_utils.dart';

// Importação condicional - só importa no mobile
import 'dart:typed_data';
// NOTA: video_thumbnail não funciona na web, só no mobile
// Se quiser usar, adicione: import 'package:video_thumbnail/video_thumbnail.dart';
// Mas só funcionará em Android/iOS, não na Web

class StoryFavoritesView extends StatefulWidget {
  final String? contexto;

  const StoryFavoritesView({super.key, this.contexto});

  @override
  State<StoryFavoritesView> createState() => _StoryFavoritesViewState();
}

class _StoryFavoritesViewState extends State<StoryFavoritesView> {
  List<StorieFileModel> favoriteStories = [];
  bool isLoading = true;
  StreamSubscription? _favoritesSubscription;
  
  // Cache para stories
  final Map<String, StorieFileModel> _storiesCache = {};
  
  // Debouncer
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadFavoriteStories();
  }

  @override
  void dispose() {
    _favoritesSubscription?.cancel();
    _debounceTimer?.cancel();
    _storiesCache.clear();
    super.dispose();
  }

  Future<void> _loadFavoriteStories() async {
    try {
      if (mounted) {
        setState(() => isLoading = true);
      }

      final normalizedContext = widget.contexto != null
          ? ContextValidator.normalizeContext(widget.contexto!)
          : null;

      print('📚 FAVORITES: Carregando para contexto: ${normalizedContext ?? "TODOS"}');

      final favoritesStream = normalizedContext != null
          ? StoryInteractionsRepository.getUserFavoritesStream(
              contexto: normalizedContext)
          : StoryInteractionsRepository.getAllUserFavoritesStream();

      _favoritesSubscription = favoritesStream.listen((favoriteIds) {
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 300), () {
          _loadStoriesFromIds(favoriteIds, normalizedContext);
        });
      });
    } catch (e) {
      print('❌ FAVORITES: Erro ao carregar: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // Carregar stories em paralelo
  Future<void> _loadStoriesFromIds(
      List<String> favoriteIds, String? normalizedContext) async {
    if (favoriteIds.isEmpty) {
      if (mounted) {
        setState(() {
          favoriteStories = [];
          isLoading = false;
        });
      }
      return;
    }

    try {
      // Buscar todos os stories em paralelo
      final futures = favoriteIds.map((storyId) async {
        if (_storiesCache.containsKey(storyId)) {
          return _storiesCache[storyId];
        }

        final story = await StoriesRepository.getStoryById(storyId);
        
        if (story != null) {
          _storiesCache[storyId] = story;
          
          if (normalizedContext != null) {
            if (!StoryContextFilter.validateStoryContext(
                story, normalizedContext)) {
              print('⚠️ FAVORITES: Story ${story.id} não pertence ao contexto $normalizedContext');
              return null;
            }
          }
        }
        
        return story;
      });

      final results = await Future.wait(futures);
      List<StorieFileModel> stories = results
          .whereType<StorieFileModel>()
          .toList();

      if (normalizedContext != null) {
        stories = StoryContextFilter.filterByContext(stories, normalizedContext);
      }

      // Ordenar por data (mais recentes primeiro)
      stories.sort((a, b) {
        final dateA = a.dataCadastro ?? Timestamp.now();
        final dateB = b.dataCadastro ?? Timestamp.now();
        return dateB.compareTo(dateA);
      });

      if (mounted) {
        setState(() {
          favoriteStories = stories;
          isLoading = false;
        });
      }

      print('✅ FAVORITES: ${stories.length} stories carregados e ordenados');
    } catch (e) {
      print('❌ FAVORITES: Erro ao carregar stories: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String _getTitleByContext() {
    final normalizedContext = widget.contexto != null
        ? ContextValidator.normalizeContext(widget.contexto!)
        : null;

    switch (normalizedContext) {
      case 'sinais_rebeca':
        return 'Favoritos - Sinais Rebeca';
      case 'sinais_isaque':
        return 'Favoritos - Sinais Isaque';
      case 'nosso_proposito':
        return 'Favoritos - Nosso Propósito';
      case 'principal':
        return 'Favoritos - Chat Principal';
      default:
        return 'Todos os Favoritos';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          _getTitleByContext(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : favoriteStories.isEmpty
              ? _buildEmptyState()
              : _buildFavoritesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 64,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhum story favorito',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Salve stories tocando no ícone de favorito\nEles ficarão salvos aqui permanentemente',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Layout estilo TikTok - 3 colunas
  Widget _buildFavoritesList() {
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 colunas como TikTok
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 9 / 16,
      ),
      itemCount: favoriteStories.length,
      itemBuilder: (context, index) {
        return _buildStoryThumbnail(favoriteStories[index], index);
      },
    );
  }

  Widget _buildStoryThumbnail(StorieFileModel story, int index) {
    return GestureDetector(
      onTap: () => _openStoryViewer(story, index),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail da mídia
          _buildMediaThumbnail(story),

          // Ícone de favorito
          _buildFavoriteIcon(),

          // Ícone de tipo de mídia
          if (story.fileType == StorieFileType.video)
            _buildVideoIcon(),
        ],
      ),
    );
  }

  void _openStoryViewer(StorieFileModel story, int index) {
    final storyContext = ContextValidator.normalizeContext(story.contexto);
    final contextToUse = widget.contexto != null
        ? ContextValidator.normalizeContext(widget.contexto!)
        : storyContext;

    final validStories = widget.contexto != null
        ? StoryContextFilter.filterByContext(favoriteStories, contextToUse)
        : favoriteStories;

    Get.to(() => EnhancedStoriesViewerView(
          contexto: contextToUse,
          userSexo: null,
          initialStories: validStories,
          initialIndex: index,
        ));
  }

  // CORRIGIDO: Tratamento de thumbnail que funciona na WEB e Mobile
  Widget _buildMediaThumbnail(StorieFileModel story) {
    // CASO 1: Vídeo com thumbnail salva (prioridade)
    if (story.fileType == StorieFileType.video &&
        story.videoThumbnail?.isNotEmpty == true) {
      return _buildImageThumbnail(story.videoThumbnail!);
    }
    
    // CASO 2: Vídeo SEM thumbnail
    if (story.fileType == StorieFileType.video) {
      // Na web, não podemos extrair thumbnail de vídeo
      // Então mostramos um placeholder bonito
      if (kIsWeb) {
        return _buildVideoPlaceholderWeb(story);
      }
      
      // No mobile, você PODERIA usar video_thumbnail aqui
      // Mas por enquanto vamos usar placeholder também para evitar erros
      return _buildVideoPlaceholder(story);
    }
    
    // CASO 3: Imagem (CORRETO: usar .img, não .image)
    if (story.fileType == StorieFileType.img &&
        story.fileUrl?.isNotEmpty == true) {
      return _buildImageThumbnail(story.fileUrl!);
    }

    // CASO 4: Fallback
    return _buildPlaceholder(story.fileType == StorieFileType.video);
  }

  // Placeholder específico para vídeos na WEB
  Widget _buildVideoPlaceholderWeb(StorieFileModel story) {
    return Container(
      color: Colors.grey.shade900,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Gradiente de fundo
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.grey.shade800,
                  Colors.grey.shade900,
                ],
              ),
            ),
          ),
          
          // Ícone central
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_circle_outline,
                  color: Colors.white.withOpacity(0.5),
                  size: 40,
                ),
                const SizedBox(height: 8),
                if (story.titulo?.isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      story.titulo!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Placeholder para vídeos no mobile (também sem thumbnail por enquanto)
  Widget _buildVideoPlaceholder(StorieFileModel story) {
    return Container(
      color: Colors.grey.shade900,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.grey.shade800,
                  Colors.grey.shade900,
                ],
              ),
            ),
          ),
          Center(
            child: Icon(
              Icons.videocam,
              color: Colors.white.withOpacity(0.4),
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  // Carregar imagens (funciona na web e mobile)
  Widget _buildImageThumbnail(String imageUrl) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 150),
      fadeOutDuration: const Duration(milliseconds: 150),
      maxWidthDiskCache: 400,
      maxHeightDiskCache: 700,
      placeholder: (context, url) => _buildLoadingPlaceholder(),
      errorWidget: (context, url, error) {
        print('❌ THUMBNAIL ERROR: $error para URL: $url');
        return _buildErrorPlaceholder();
      },
    );
  }

  Widget _buildPlaceholder(bool isVideo) {
    return Container(
      color: Colors.grey.shade900,
      child: Center(
        child: Icon(
          isVideo ? Icons.videocam_off : Icons.image_not_supported,
          color: Colors.white24,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      color: Colors.grey.shade900,
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: Colors.white38,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.grey.shade900,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            color: Colors.white24,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            'Preview\nindisponível',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.2),
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteIcon() {
    return Positioned(
      top: 4,
      right: 4,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.favorite,
          color: Colors.red,
          size: 12,
        ),
      ),
    );
  }

  Widget _buildVideoIcon() {
    return Positioned(
      top: 4,
      left: 4,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(
          Icons.play_arrow,
          color: Colors.white,
          size: 14,
        ),
      ),
    );
  }
}