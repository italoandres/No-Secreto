import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/enhanced_image_loader.dart';
import 'package:video_player/video_player.dart';
import '../models/storie_file_model.dart';
import '../models/usuario_model.dart';
import '../repositories/stories_repository.dart';
import '../controllers/story_interactions_controller.dart';
import '../controllers/story_auto_close_controller.dart';
import '../components/story_interactions_component.dart';
import '../components/story_comments_component.dart';
import 'stories/community_comments_view.dart';
import '../utils/enhanced_image_loader.dart';
import '../utils/firebase_image_loader.dart';
import '../utils/context_utils.dart';
import 'package:whatsapp_chat/utils/debug_utils.dart';

class EnhancedStoriesViewerView extends StatefulWidget {
  final String contexto;
  final UserSexo? userSexo;
  final List<StorieFileModel>? initialStories; // Para stories favoritos
  final int? initialIndex; // Índice inicial

  const EnhancedStoriesViewerView({
    super.key,
    required this.contexto,
    required this.userSexo,
    this.initialStories,
    this.initialIndex,
  });

  @override
  State<EnhancedStoriesViewerView> createState() =>
      _EnhancedStoriesViewerViewState();
}

class _EnhancedStoriesViewerViewState extends State<EnhancedStoriesViewerView>
    with TickerProviderStateMixin {
  List<StorieFileModel> stories = [];
  int currentIndex = 0;
  bool isLoading = true;
  bool isPaused = false;
  Timer? autoAdvanceTimer;
  AnimationController? progressController;
  VideoPlayerController? videoController;
  PageController pageController = PageController();

  // Interactions controller
  late StoryInteractionsController interactionsController;

  // Auto-close controller
  late AdvancedStoryAutoCloseController autoCloseController;

  // Animation controllers for interactions
  AnimationController? likeAnimationController;
  Animation<double>? likeAnimation;

  // Estado para controlar expansão da descrição
  bool isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();

    // Validar contexto no início
    final normalizedContext =
        ContextValidator.normalizeContext(widget.contexto);
    if (!ContextValidator.validateAndLog(
        widget.contexto, 'EnhancedStoriesViewer_initState')) {
      ContextDebug.logCriticalError('EnhancedStoriesViewer',
          'Contexto inválido no initState', normalizedContext);
    }

    // Validar stories iniciais se fornecidos
    if (widget.initialStories != null) {
      final validInitialStories = StoryContextFilter.filterByContext(
          widget.initialStories!, normalizedContext);
      final hasLeaks = StoryContextFilter.detectContextLeaks(
          widget.initialStories!, normalizedContext);

      if (hasLeaks) {
        ContextDebug.logCriticalError('EnhancedStoriesViewer',
            'VAZAMENTO DETECTADO nos stories iniciais', normalizedContext);
      }

      ContextDebug.logSummary(
          'EnhancedStoriesViewer_initState', normalizedContext, {
        'initialStoriesProvided': widget.initialStories!.length,
        'validInitialStories': validInitialStories.length,
        'initialIndex': widget.initialIndex,
        'hasLeaks': hasLeaks
      });
    }

    interactionsController = Get.put(StoryInteractionsController());
    autoCloseController = AdvancedStoryAutoCloseController();
    _setupAnimations();
    _setupAutoCloseController();
    _loadStories();
  }

  @override
  void dispose() {
    print('DEBUG VIEWER: Disposing viewer');

    // Para todos os timers primeiro
    autoAdvanceTimer?.cancel();

    // Limpa todos os recursos
    _cleanupPreviousStory();

    // Dispose dos controladores
    try {
      autoCloseController.dispose();
    } catch (e) {
      print('Erro ao fazer dispose do autoCloseController: $e');
    }

    likeAnimationController?.dispose();
    pageController.dispose();
    progressController?.dispose();

    // Para e libera vídeo
    videoController?.pause();
    videoController?.dispose();

    // Remove controller apenas se foi criado aqui
    if (Get.isRegistered<StoryInteractionsController>()) {
      Get.delete<StoryInteractionsController>();
    }

    super.dispose();
  }

  void _setupAnimations() {
    likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500), // Mais lenta
      vsync: this,
    );

    likeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: likeAnimationController!,
      curve: Curves.elasticOut,
    ));
  }

  void _setupAutoCloseController() {
    autoCloseController.setProgressCallback((progress) {
      // Atualizar barra de progresso se necessário
      progressController?.value = progress;
    });
  }

  Future<void> _loadStories() async {
    try {
      // Se stories iniciais foram fornecidos (ex: favoritos), usar eles
      if (widget.initialStories != null) {
        final normalizedContext =
            ContextValidator.normalizeContext(widget.contexto);

        ContextDebug.logSummary(
            'EnhancedStoriesViewer_useInitialStories', normalizedContext, {
          'initialStoriesCount': widget.initialStories!.length,
          'initialIndex': widget.initialIndex
        });

        // VALIDAÇÃO CRÍTICA: Filtrar stories iniciais por contexto
        final validInitialStories = StoryContextFilter.filterByContext(
            widget.initialStories!, normalizedContext);

        // Detectar vazamentos nos stories iniciais
        final hasLeaks = StoryContextFilter.detectContextLeaks(
            widget.initialStories!, normalizedContext);
        if (hasLeaks) {
          ContextDebug.logCriticalError(
              'EnhancedStoriesViewer',
              'VAZAMENTO CRÍTICO nos stories iniciais fornecidos',
              normalizedContext);
        }

        ContextDebug.logFilter(
            normalizedContext,
            widget.initialStories!.length,
            validInitialStories.length,
            'EnhancedStoriesViewer_useInitialStories');

        setState(() {
          stories = validInitialStories; // USAR STORIES VALIDADOS
          currentIndex = widget.initialIndex ?? 0;
          isLoading = false;
        });

        if (stories.isNotEmpty) {
          // Ajustar pageController para o índice inicial
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (pageController.hasClients) {
              pageController.jumpToPage(currentIndex);
            }
            _initializeCurrentStory();
          });
        }
        return;
      }

      // Validar contexto antes de carregar stories
      final normalizedContext =
          ContextValidator.normalizeContext(widget.contexto);
      if (!ContextValidator.validateAndLog(
          widget.contexto, 'EnhancedStoriesViewer_loadStories')) {
        ContextDebug.logCriticalError(
            'EnhancedStoriesViewer',
            'Contexto inválido, usando contexto normalizado',
            normalizedContext);
      }

      ContextDebug.logSummary(
          'EnhancedStoriesViewer_loadStories', normalizedContext, {
        'originalContext': widget.contexto,
        'normalizedContext': normalizedContext,
        'userSexo': widget.userSexo?.name,
        'operation': 'LOAD_STORIES_FOR_VIEWER'
      });

      final loadedStories = await StoriesRepository.getStoriesByContexto(
        normalizedContext, // USAR CONTEXTO NORMALIZADO
        widget.userSexo,
      );

      // VALIDAÇÃO ADICIONAL: Filtrar stories que não pertencem ao contexto esperado
      final validStories =
          StoryContextFilter.filterByContext(loadedStories, normalizedContext);

      // Detectar vazamentos de contexto
      final hasLeaks = StoryContextFilter.detectContextLeaks(
          loadedStories, normalizedContext);
      if (hasLeaks) {
        ContextDebug.logCriticalError('EnhancedStoriesViewer',
            'VAZAMENTO DE CONTEXTO DETECTADO no viewer', normalizedContext);
      }

      ContextDebug.logFilter(normalizedContext, loadedStories.length,
          validStories.length, 'EnhancedStoriesViewer_loadStories');

      setState(() {
        stories = validStories; // USAR STORIES VALIDADOS
        isLoading = false;
      });

      if (stories.isNotEmpty) {
        _initializeCurrentStory();
      }
    } catch (e) {
      print('DEBUG ENHANCED VIEWER: Erro ao carregar stories: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _initializeCurrentStory() {
    if (currentIndex >= stories.length) return;

    final currentStory = stories[currentIndex];
    safePrint(
        '🎬 VIEWER: Inicializando story ${currentStory.id} (${currentIndex + 1}/${stories.length})');
    safePrint(
        '🎬 VIEWER: Tipo: ${currentStory.fileType?.name}, URL: ${currentStory.fileUrl}');

    // Limpa recursos do story anterior
    _cleanupPreviousStory();

    // Initialize interactions for current story
    interactionsController.initializeStory(currentStory.id!,
        contexto: widget.contexto);

    // Marcar story como visto ao inicializar
    _markCurrentStoryAsViewed();

    // Iniciar auto-close baseado no tipo de mídia
    _startAutoCloseForCurrentStory(currentStory);

    if (currentStory.fileType == StorieFileType.video) {
      _initializeVideo(currentStory.fileUrl!);
    } else {
      _startImageTimer();
    }
  }

  void _cleanupPreviousStory() {
    // Para timers
    autoAdvanceTimer?.cancel();
    autoCloseController.cancelAutoClose();
    progressController?.dispose();
    progressController = null;

    // Para e libera vídeo anterior
    videoController?.pause();
    videoController?.dispose();
    videoController = null;
  }

  void _initializeVideo(String videoUrl) {
    print('DEBUG VIDEO: Inicializando vídeo: $videoUrl');

    videoController = VideoPlayerController.networkUrl(
      Uri.parse(videoUrl),
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
        allowBackgroundPlayback: false,
      ),
    );

    videoController!.initialize().then((_) {
      if (mounted && videoController != null) {
        setState(() {});

        // 🆕 GARANTIR QUE O VÍDEO NÃO FAÇA LOOP
        videoController!.setLooping(false);

        videoController!.play();
        // VSL: Sem looping - vídeo pausa no último frame

        // Start progress animation apenas se necessário
        progressController ??= AnimationController(
          duration: videoController!.value.duration,
          vsync: this,
        );
        progressController!.forward();
      }
    }).catchError((error) {
      print('DEBUG VIDEO: Erro ao inicializar vídeo: $error');
    });
  }

  void _startImageTimer() {
    progressController?.dispose();
    progressController = AnimationController(
      duration: const Duration(seconds: 10), // 10 segundos para imagens
      vsync: this,
    );

    progressController!.forward();

    // VSL: Sem auto-advance - usuário controla o avanço manualmente
  }

  void _nextStory() {
    // Marcar story atual como visto antes de avançar
    if (currentIndex < stories.length) {
      _markCurrentStoryAsViewed();
    }

    if (currentIndex < stories.length - 1) {
      setState(() {
        currentIndex++;
      });
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Fim dos stories - tentar carregar mais ou fechar
      _handleEndOfStories();
    }
  }

  /// Lida com o fim dos stories - carrega mais ou fecha
  Future<void> _handleEndOfStories() async {
    // Se são stories favoritos, não carrega mais - apenas fecha
    if (widget.initialStories != null) {
      Get.back();
      return;
    }

    try {
      // Validar contexto antes de carregar mais stories
      final normalizedContext =
          ContextValidator.normalizeContext(widget.contexto);

      ContextDebug.logSummary(
          'EnhancedStoriesViewer_loadMoreStories', normalizedContext, {
        'currentStoriesCount': stories.length,
        'operation': 'LOAD_MORE_STORIES'
      });

      // Tentar carregar mais stories do mesmo contexto
      final moreStories = await StoriesRepository.getStoriesByContexto(
        normalizedContext, // USAR CONTEXTO NORMALIZADO
        widget.userSexo,
      );

      // VALIDAÇÃO ADICIONAL: Filtrar stories que não pertencem ao contexto esperado
      final validMoreStories =
          StoryContextFilter.filterByContext(moreStories, normalizedContext);

      // Detectar vazamentos de contexto
      final hasLeaks =
          StoryContextFilter.detectContextLeaks(moreStories, normalizedContext);
      if (hasLeaks) {
        ContextDebug.logCriticalError(
            'EnhancedStoriesViewer',
            'VAZAMENTO DE CONTEXTO DETECTADO ao carregar mais stories',
            normalizedContext);
      }

      // Filtrar stories que já foram exibidos
      final currentIds = stories.map((s) => s.id).toSet();
      final newStories = validMoreStories
          .where((s) => !currentIds.contains(s.id))
          .toList(); // USAR STORIES VALIDADOS

      if (newStories.isNotEmpty) {
        print(
            'DEBUG VIEWER: Carregando ${newStories.length} stories adicionais');
        setState(() {
          stories.addAll(newStories);
          currentIndex++;
        });

        pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        // Não há mais stories - recomeçar do início ou fechar
        _restartStoriesOrClose();
      }
    } catch (e) {
      print('DEBUG VIEWER: Erro ao carregar mais stories: $e');
      Get.back();
    }
  }

  /// Recomeça os stories do início ou fecha
  void _restartStoriesOrClose() {
    // Para contexto principal, recomeçar do início para conteúdo infinito
    if (widget.contexto == 'principal' && stories.isNotEmpty) {
      print(
          'DEBUG VIEWER: Recomeçando stories do início para conteúdo infinito');
      setState(() {
        currentIndex = 0;
      });
      pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      // Para outros contextos, fechar
      Get.back();
    }
  }

  /// Marca o story atual como visto
  void _markCurrentStoryAsViewed() {
    if (currentIndex < stories.length && stories[currentIndex].id != null) {
      StoriesRepository.addVisto(stories[currentIndex].id!,
          contexto: widget.contexto);
      print(
          'DEBUG VIEWER: Story ${stories[currentIndex].id} marcado como visto');

      // Forçar atualização do estado do chat para atualizar o círculo verde
      _notifyStoryViewed();
    }
  }

  /// Notifica que um story foi visto para atualizar a UI do chat
  void _notifyStoryViewed() {
    // Usar um pequeno delay para garantir que o Firestore foi atualizado
    Future.delayed(const Duration(milliseconds: 500), () {
      // Força rebuild dos streams no chat
      print(
          'DEBUG VIEWER: Notificando que story foi visto para atualizar círculo verde');
    });
  }

  /// Inicia auto-close para o story atual
  void _startAutoCloseForCurrentStory(StorieFileModel story) {
    safePrint('⏰ AUTO-CLOSE: Iniciando para story ${story.id}');
    // VSL: Desabilitado - não queremos auto-advance
    // autoCloseController.startAutoCloseForMedia(
    //   fileType: story.fileType?.name ?? 'img',
    //   videoDuration: story.videoDuration,
    //   onClose: () {
    //     safePrint('⏰ AUTO-CLOSE: Story fechado automaticamente');
    //     _nextStory();
    //   },
    // );
  }

  /// Pausa o auto-close (quando usuário pressiona e segura)
  void _pauseAutoClose() {
    print('⏸️ VIEWER: Pausando auto-close');
    autoCloseController.pauseAutoClose();
  }

  /// Retoma o auto-close (quando usuário solta o toque)
  void _resumeAutoClose() {
    print('▶️ VIEWER: Retomando auto-close');
    autoCloseController.resumeAutoClose();
  }

  /// Alterna entre pause e play do story
  void _togglePause() {
    print('🎮 PAUSE: Alternando estado - atual: $isPaused');
    setState(() {
      isPaused = !isPaused;
    });

    if (isPaused) {
      print('⏸️ PAUSE: Pausando story');
      // Pausa o timer de auto-advance
      autoAdvanceTimer?.cancel();
      // Pausa o auto-close controller
      autoCloseController.pauseAutoClose();
      // Pausa o progress controller
      progressController?.stop();
      // Pausa vídeo se existir
      videoController?.pause();
    } else {
      print('▶️ PLAY: Retomando story');
      // Retoma o auto-close controller
      autoCloseController.resumeAutoClose();
      // Retoma o progress controller
      progressController?.forward();
      // Retoma vídeo se existir
      videoController?.play();
    }

    print('🎮 PAUSE: Novo estado: $isPaused');
  }

  void _previousStory() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
      });
      pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onDoubleTap() {
    print('💖 LIKE: Duplo toque detectado');
    // Double tap to like
    interactionsController.toggleLike();
    _showLikeAnimation();
  }

  void _showLikeAnimation() {
    print('✨ LIKE: Iniciando animação');
    likeAnimationController!.reset();
    likeAnimationController!.forward().then((_) {
      // Aguarda um pouco antes de resetar para ser mais visível
      Timer(const Duration(milliseconds: 800), () {
        if (mounted) {
          likeAnimationController!.reset();
        }
      });
    });
  }

  void _showComments() {
    final story = stories[currentIndex];
    
    // Navegação tradicional para tela de comentários
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CommunityCommentsView(
          story: story,
        ),
      ),
    );
  }

  /// Mostra modal com descrição completa estilo TikTok
  void _showDescriptionModal(StorieFileModel story) {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.4,
        decoration: const BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    if (story.titulo?.isNotEmpty == true) ...[
                      Text(
                        story.titulo!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Descrição completa
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          story.descricao ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (stories.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.photo_library_outlined,
                color: Colors.white,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Nenhum story disponível',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Get.back(),
                child: const Text('Voltar'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Stories PageView
          PageView.builder(
            controller: pageController,
            itemCount: stories.length,
            onPageChanged: (index) {
              safePrint('📄 VIEWER: Mudando para página $index');
              setState(() {
                currentIndex = index;
              });
              _initializeCurrentStory();
            },
            itemBuilder: (context, index) {
              safePrint('📄 VIEWER: Construindo página $index');
              return _buildStoryContent(stories[index]);
            },
          ),

          // Progress indicators com indicação de pause
          Positioned(
            top: 50,
            left: 16,
            right: 80, // Mais espaço para os botões
            child: Row(
              children: List.generate(
                stories.length,
                (index) => Expanded(
                  child: Container(
                    height: 3,
                    margin: EdgeInsets.only(
                        right: index < stories.length - 1 ? 4 : 0),
                    decoration: BoxDecoration(
                      color: index < currentIndex
                          ? Colors.white
                          : index == currentIndex
                              ? (isPaused
                                  ? Colors.orange
                                  : Colors.white.withOpacity(0.5))
                              : Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: index == currentIndex &&
                            progressController != null &&
                            !isPaused
                        ? AnimatedBuilder(
                            animation: progressController!,
                            builder: (context, child) {
                              return LinearProgressIndicator(
                                value: progressController!.value,
                                backgroundColor: Colors.transparent,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              );
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),

          // Botões superiores (pause e close)
          Positioned(
            top: 50,
            right: 16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botão de pause/play
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _togglePause,
                    icon: Icon(
                      isPaused ? Icons.play_arrow : Icons.pause,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Botão de fechar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () {
                      print('DEBUG: Botão fechar pressionado');
                      // Para todos os timers e controladores
                      autoAdvanceTimer?.cancel();
                      autoCloseController.dispose();
                      videoController?.pause();
                      progressController?.stop();
                      // Fecha o viewer
                      Navigator.of(context).pop();
                    },
                    icon:
                        const Icon(Icons.close, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
          ),

          // Tap areas for navigation (excluindo área dos botões superiores)
          Positioned(
            top: 100, // Abaixo dos botões superiores
            left: 0,
            right: 0,
            bottom: 0,
            child: Row(
              children: [
                // Left tap area - previous story
                Expanded(
                  flex: 3,
                  child: GestureDetector(
                    onTap: _previousStory,
                    onLongPressStart: (_) => _pauseAutoClose(),
                    onLongPressEnd: (_) => _resumeAutoClose(),
                    child: Container(color: Colors.transparent),
                  ),
                ),
                // Center tap area - APENAS duplo toque para curtir
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onDoubleTap: _onDoubleTap,
                    child: Container(color: Colors.transparent),
                  ),
                ),
                // Right tap area - next story
                Expanded(
                  flex: 3,
                  child: GestureDetector(
                    onTap: _nextStory,
                    onDoubleTap: _onDoubleTap,
                    onLongPressStart: (_) => _pauseAutoClose(),
                    onLongPressEnd: (_) => _resumeAutoClose(),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ],
            ),
          ),

          // Botão de pause no centro (visível apenas quando pausado)
          if (isPaused)
            Center(
              child: GestureDetector(
                onTap: _togglePause,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),

          // Story info overlay removido para evitar duplicação

          // Interactions panel
          if (stories.isNotEmpty)
            StoryInteractionsComponent(
              storyId: stories[currentIndex].id!,
              onCommentTap: _showComments,
            ),

          // Like animation overlay - APENAS quando animando (invisível por padrão)
          if (likeAnimation!.isAnimating)
            Center(
              child: AnimatedBuilder(
                animation: likeAnimation!,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Partículas de luz subindo
                      ...List.generate(8, (index) {
                        final angle = (index * 45.0) *
                            (3.14159 / 180); // Converter para radianos
                        final distance = likeAnimation!.value * 100;
                        return Transform.translate(
                          offset: Offset(
                            distance * cos(angle),
                            -distance * sin(angle) -
                                (likeAnimation!.value * 50),
                          ),
                          child: Opacity(
                            opacity:
                                (1.0 - likeAnimation!.value).clamp(0.0, 1.0),
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.8),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(0.5),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),

                      // Emoji principal com efeito crescente
                      Transform.scale(
                        scale: 0.5 +
                            (likeAnimation!.value *
                                1.5), // Cresce de 0.5x para 2x
                        child: Opacity(
                          opacity: (1.0 - likeAnimation!.value).clamp(0.0, 1.0),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.4),
                                  blurRadius: 20 * likeAnimation!.value,
                                  spreadRadius: 5 * likeAnimation!.value,
                                ),
                              ],
                            ),
                            child: const Text(
                              '🙏',
                              style: TextStyle(fontSize: 80),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStoryContent(StorieFileModel story) {
    safePrint(
        '🖼️ VIEWER: Construindo conteúdo do story ${story.id} - Tipo: ${story.fileType?.name}');
    safePrint('🖼️ VIEWER: URL da imagem: ${story.fileUrl}');

    if (story.fileType == StorieFileType.video) {
      return _buildVideoContent(story);
    } else {
      return _buildImageContent(story);
    }
  }

  Widget _buildVideoContent(StorieFileModel story) {
    if (videoController == null || !videoController!.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: videoController!.value.aspectRatio,
        child: VideoPlayer(videoController!),
      ),
    );
  }

  Widget _buildImageContent(StorieFileModel story) {
    safePrint('🖼️ VIEWER: Construindo imagem para story ${story.id}');
    safePrint('🖼️ VIEWER: URL completa: ${story.fileUrl}');

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Stack(
        children: [
          // Imagem em tela cheia - TOTALMENTE VERTICAL
          Positioned.fill(
            child: _buildImageWithFallbacks(story),
          ),

          // Overlay com informações do story (parte inferior) - RESTAURADO
          if (story.titulo?.isNotEmpty == true ||
              story.descricao?.isNotEmpty == true)
            Positioned(
              bottom: 120, // Acima dos botões de interação
              left: 16,
              right: 100, // Espaço para botões laterais
              child: GestureDetector(
                onTap: () {
                  if (story.descricao?.isNotEmpty == true &&
                      story.descricao!.length > 100) {
                    _showDescriptionModal(story);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.black.withOpacity(0.6),
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (story.titulo?.isNotEmpty == true)
                        Text(
                          story.titulo!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 4,
                                offset: Offset(1, 1),
                              ),
                            ],
                          ),
                        ),
                      if (story.titulo?.isNotEmpty == true &&
                          story.descricao?.isNotEmpty == true)
                        const SizedBox(height: 8),
                      if (story.descricao?.isNotEmpty == true)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              story.descricao!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                                shadows: [
                                  Shadow(
                                    color: Colors.black,
                                    blurRadius: 3,
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (story.descricao!.length > 100)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.touch_app,
                                      color: Colors.orange.withOpacity(0.8),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Toque para ver mais...',
                                      style: TextStyle(
                                        color: Colors.orange.withOpacity(0.8),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),

          // Botão de pause/play mais visível
          if (isPaused)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
            ),

          // Indicador de pause sutil quando pausado
          if (isPaused)
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Pausado - Toque para continuar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageWithFallbacks(StorieFileModel story) {
    safePrint(
        '🖼️ VIEWER: Construindo imagem com proxy para story ${story.id}');
    safePrint('🖼️ VIEWER: URL original: ${story.fileUrl}');

    if (story.fileUrl == null || story.fileUrl!.isEmpty) {
      return _buildFallbackContent(story, 'URL da imagem não disponível');
    }

    return EnhancedImageLoader.buildCachedImage(
      imageUrl: story.fileUrl!,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover, // Mantém cobertura total da tela
      placeholder: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        ),
      ),
      errorWidget: _buildFallbackContent(story, 'Erro ao carregar imagem'),
    );
  }

  Widget _buildFallbackContent(StorieFileModel story, String errorMessage) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey[900]!,
            Colors.black,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícone representativo
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: const Icon(
                Icons.image,
                size: 80,
                color: Colors.blue,
              ),
            ),

            const SizedBox(height: 24),

            // Mensagem de erro
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.orange,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    errorMessage,
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
