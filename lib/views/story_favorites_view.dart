import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/storie_file_model.dart';
import '../repositories/story_interactions_repository.dart';
import '../repositories/stories_repository.dart';
import '../views/enhanced_stories_viewer_view.dart';
import '../utils/enhanced_image_loader.dart';
import '../utils/context_utils.dart';

class StoryFavoritesView extends StatefulWidget {
  final String? contexto; // Contexto específico ou null para todos

  const StoryFavoritesView({super.key, this.contexto});

  @override
  State<StoryFavoritesView> createState() => _StoryFavoritesViewState();
}

class _StoryFavoritesViewState extends State<StoryFavoritesView> {
  List<StorieFileModel> favoriteStories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    // Validar contexto no início
    if (widget.contexto != null) {
      final normalizedContext =
          ContextValidator.normalizeContext(widget.contexto);
      if (!ContextValidator.validateAndLog(
          widget.contexto, 'StoryFavoritesView_initState')) {
        ContextDebug.logCriticalError('StoryFavoritesView',
            'Contexto inválido no initState', normalizedContext);
      }

      ContextDebug.logSummary(
          'StoryFavoritesView_initState', normalizedContext, {
        'originalContext': widget.contexto,
        'normalizedContext': normalizedContext,
        'operation': 'INIT_FAVORITES_VIEW'
      });
    }

    _loadFavoriteStories();
  }

  Future<void> _loadFavoriteStories() async {
    try {
      if (mounted) {
        setState(() {
          isLoading = true;
        });
      }

      // Validar e normalizar contexto
      final normalizedContext = widget.contexto != null
          ? ContextValidator.normalizeContext(widget.contexto!)
          : null;

      if (widget.contexto != null &&
          !ContextValidator.validateAndLog(
              widget.contexto, 'StoryFavoritesView_loadFavorites')) {
        ContextDebug.logCriticalError(
            'StoryFavoritesView',
            'Contexto inválido, usando contexto normalizado',
            normalizedContext!);
      }

      ContextDebug.logSummary(
          'StoryFavoritesView_loadFavorites', normalizedContext ?? 'ALL', {
        'originalContext': widget.contexto,
        'normalizedContext': normalizedContext,
        'operation': 'LOAD_FAVORITE_STORIES'
      });

      // Escutar mudanças nos favoritos do usuário
      final favoritesStream = normalizedContext != null
          ? StoryInteractionsRepository.getUserFavoritesStream(
              contexto: normalizedContext)
          : StoryInteractionsRepository.getAllUserFavoritesStream();

      print(
          '📚 FAVORITES VIEW: Usando stream para contexto: ${widget.contexto ?? "TODOS"}');

      favoritesStream.listen((favoriteIds) async {
        print(
            '📚 FAVORITES VIEW: Recebidos ${favoriteIds.length} IDs de favoritos: $favoriteIds');

        if (favoriteIds.isEmpty) {
          print('📚 FAVORITES VIEW: Nenhum favorito encontrado');
          if (mounted) {
            setState(() {
              favoriteStories = [];
              isLoading = false;
            });
          }
          return;
        }

        // Buscar os stories favoritos
        List<StorieFileModel> stories = [];
        for (String storyId in favoriteIds) {
          ContextDebug.logSummary(
              'StoryFavoritesView_fetchStory',
              normalizedContext ?? 'ALL',
              {'storyId': storyId, 'operation': 'FETCH_FAVORITE_STORY'});

          final story = await StoriesRepository.getStoryById(storyId);
          if (story != null) {
            // VALIDAÇÃO CRÍTICA: Verificar se o story pertence ao contexto esperado
            if (normalizedContext != null) {
              if (!StoryContextFilter.validateStoryContext(
                  story, normalizedContext)) {
                ContextDebug.logCriticalError(
                    'StoryFavoritesView',
                    'VAZAMENTO CRÍTICO - Story favorito ${story.id} tem contexto "${story.contexto}" mas deveria ser "$normalizedContext"',
                    normalizedContext);
                continue; // Pular este story
              }
            }

            ContextDebug.logSummary(
                'StoryFavoritesView_storyFound', normalizedContext ?? 'ALL', {
              'storyId': storyId,
              'storyTitle': story.titulo ?? 'Sem título',
              'storyContext': story.contexto
            });

            stories.add(story);
          } else {
            ContextDebug.logCriticalError(
                'StoryFavoritesView',
                'Story favorito não encontrado para ID: $storyId',
                normalizedContext ?? 'ALL');
          }
        }

        // VALIDAÇÃO ADICIONAL: Filtrar stories por contexto se especificado
        if (normalizedContext != null) {
          final originalCount = stories.length;
          stories =
              StoryContextFilter.filterByContext(stories, normalizedContext);

          // Detectar vazamentos
          final hasLeaks =
              StoryContextFilter.detectContextLeaks(stories, normalizedContext);
          if (hasLeaks) {
            ContextDebug.logCriticalError(
                'StoryFavoritesView',
                'VAZAMENTOS DETECTADOS nos stories favoritos',
                normalizedContext);
          }

          ContextDebug.logFilter(normalizedContext, originalCount,
              stories.length, 'StoryFavoritesView_filterStories');
        }

        ContextDebug.logSummary(
            'StoryFavoritesView_storiesLoaded', normalizedContext ?? 'ALL', {
          'totalStories': stories.length,
          'favoriteIds': favoriteIds.length
        });

        // Ordenar por data de favoritamento (mais recentes primeiro)
        stories.sort((a, b) =>
            (b.dataCadastro?.compareTo(a.dataCadastro ?? Timestamp.now()) ??
                0));

        if (mounted) {
          setState(() {
            favoriteStories = stories;
            isLoading = false;
          });
        }
      });
    } catch (e) {
      print('❌ FAVORITES VIEW: Erro ao carregar favoritos: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String _getTitleByContext() {
    // Validar e normalizar contexto para o título
    final normalizedContext = widget.contexto != null
        ? ContextValidator.normalizeContext(widget.contexto!)
        : null;

    if (widget.contexto != null &&
        !ContextValidator.validateAndLog(
            widget.contexto, 'StoryFavoritesView_getTitle')) {
      ContextDebug.logCriticalError(
          'StoryFavoritesView',
          'Contexto inválido para título, usando contexto normalizado',
          normalizedContext!);
    }

    ContextDebug.logSummary(
        'StoryFavoritesView_getTitle', normalizedContext ?? 'ALL', {
      'originalContext': widget.contexto,
      'normalizedContext': normalizedContext,
      'operation': 'GENERATE_TITLE'
    });

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
        title: Text(
          _getTitleByContext(),
          style: const TextStyle(color: Colors.white),
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
          const Icon(
            Icons.bookmark_border,
            color: Colors.white54,
            size: 64,
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
            'Salve stories tocando no ícone de salvar',
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

  Widget _buildFavoritesList() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 9 / 16, // Proporção de story
      ),
      itemCount: favoriteStories.length,
      itemBuilder: (context, index) {
        return _buildStoryThumbnail(favoriteStories[index], index);
      },
    );
  }

  Widget _buildStoryThumbnail(StorieFileModel story, int index) {
    return GestureDetector(
      onTap: () {
        // Validar contexto do story antes de abrir o viewer
        final storyContext = ContextValidator.normalizeContext(story.contexto);

        // VALIDAÇÃO ADICIONAL: Filtrar stories para garantir que apenas stories do contexto correto sejam passados
        final contextToUse = widget.contexto != null
            ? ContextValidator.normalizeContext(widget.contexto!)
            : storyContext;

        final validStories = widget.contexto != null
            ? StoryContextFilter.filterByContext(favoriteStories, contextToUse)
            : favoriteStories;

        ContextDebug.logSummary('StoryFavoritesView_openViewer', contextToUse, {
          'storyId': story.id,
          'storyContext': story.contexto,
          'normalizedStoryContext': storyContext,
          'viewerContext': contextToUse,
          'totalStories': favoriteStories.length,
          'validStories': validStories.length,
          'initialIndex': index
        });

        // Detectar vazamentos antes de abrir o viewer
        if (widget.contexto != null) {
          final hasLeaks = StoryContextFilter.detectContextLeaks(
              favoriteStories, contextToUse);
          if (hasLeaks) {
            ContextDebug.logCriticalError('StoryFavoritesView',
                'VAZAMENTOS DETECTADOS antes de abrir viewer', contextToUse);
          }
        }

        // Abrir story viewer começando do story selecionado
        Get.to(() => EnhancedStoriesViewerView(
              contexto: contextToUse, // USAR CONTEXTO VALIDADO
              userSexo: null,
              initialStories: validStories, // USAR STORIES VALIDADOS
              initialIndex: index,
            ));
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Thumbnail da mídia
              _buildMediaThumbnail(story),

              // Overlay com informações
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (story.titulo?.isNotEmpty == true)
                        Text(
                          story.titulo!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (story.descricao?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          story.descricao!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 10,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Ícone de favorito
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.red,
                    size: 16,
                  ),
                ),
              ),

              // Ícone de tipo de mídia
              if (story.fileType == StorieFileType.video)
                const Positioned(
                  top: 8,
                  left: 8,
                  child: Icon(
                    Icons.play_circle_filled,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaThumbnail(StorieFileModel story) {
    if (story.fileType == StorieFileType.video &&
        story.videoThumbnail?.isNotEmpty == true) {
      // Usar thumbnail do vídeo
      return EnhancedImageLoader.buildCachedImage(
        imageUrl: story.videoThumbnail!,
        fit: BoxFit.cover,
        placeholder: Container(
          color: Colors.grey.shade800,
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ),
        ),
        errorWidget: Container(
          color: Colors.grey.shade800,
          child: const Icon(
            Icons.error,
            color: Colors.white54,
          ),
        ),
      );
    } else if (story.fileUrl?.isNotEmpty == true) {
      // Usar a própria imagem
      return EnhancedImageLoader.buildCachedImage(
        imageUrl: story.fileUrl!,
        fit: BoxFit.cover,
        placeholder: Container(
          color: Colors.grey.shade800,
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ),
        ),
        errorWidget: Container(
          color: Colors.grey.shade800,
          child: const Icon(
            Icons.error,
            color: Colors.white54,
          ),
        ),
      );
    }

    // Fallback
    return Container(
      color: Colors.grey.shade800,
      child: const Icon(
        Icons.photo,
        color: Colors.white54,
        size: 32,
      ),
    );
  }
}
