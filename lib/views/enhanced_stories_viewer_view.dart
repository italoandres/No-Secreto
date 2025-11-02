import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import '../utils/enhanced_image_loader.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
// Conditional import for web downloads
import '../utils/download_helper.dart' if (dart.library.html) '../utils/download_helper_web.dart' if (dart.library.io) '../utils/download_helper_mobile.dart';
import '../models/storie_file_model.dart';
import '../models/usuario_model.dart';
import '../repositories/stories_repository.dart';
import '../controllers/story_interactions_controller.dart';
import '../controllers/story_auto_close_controller.dart';
import '../components/story_interactions_component.dart';
import '../components/story_comments_component.dart';
import '../components/story_action_menu.dart';
import 'stories/community_comments_view.dart';
import '../utils/enhanced_image_loader.dart';
import '../utils/firebase_image_loader.dart';
import '../utils/context_utils.dart';
import 'package:whatsapp_chat/utils/debug_utils.dart';
import 'chat_view.dart'; // 🙏 NOVO: Para navegação direta
import 'sinais_isaque_view.dart'; // 🙏 NOVO: Para navegação direta
import 'sinais_rebeca_view.dart'; // 🙏 NOVO: Para navegação direta
import 'nosso_proposito_view.dart'; // 🙏 NOVO: Para navegação direta
import '../utils/watermark_processor.dart'; // 🎬 NOVO: Processador de marca d'água

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
  Timer? autoAdvanceTimer;
  AnimationController? progressController;
  VideoPlayerController? videoController;
  PageController pageController = PageController();
  
  // 🎵 FASE 2: Animação e Áudio de Download
  ValueNotifier<bool> isDownloading = ValueNotifier<bool>(false);
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Timer para sincronização manual de imagens (igual ao vídeo)
  Timer? imageProgressTimer;
  DateTime? imageStartTime;
  Duration? imagePausedDuration;
  
  // 🆕 SISTEMA DE PRELOAD INSTANTÂNEO
  // Cache de vídeos precarregados (índice → VideoPlayerController)
  Map<int, VideoPlayerController> preloadedVideos = {};
  
  // Cache de status de preload de imagens (índices já precarregados)
  Set<int> preloadedImages = {};
  
  // Índices sendo precarregados no momento (evitar duplicação)
  Set<int> currentlyPreloading = {};

  // Interactions controller
  late StoryInteractionsController interactionsController;

  // Auto-close controller
  late AdvancedStoryAutoCloseController autoCloseController;

  // Animation controllers for interactions
  AnimationController? likeAnimationController;
  Animation<double>? likeAnimation;

  // Estado para controlar expansão da descrição
  bool isDescriptionExpanded = false;

  // ValueNotifier para revelar menu de interações
  ValueNotifier<bool> menuRevealNotifier = ValueNotifier<bool>(false);
  
  // ValueNotifier para estado de pause (evita rebuild completo)
  ValueNotifier<bool> isPausedNotifier = ValueNotifier<bool>(false);

  // 🎬 CONTROLE DE PROGRESSO DO PROCESSAMENTO
  ValueNotifier<double> processingProgress = ValueNotifier<double>(0.0);
  ValueNotifier<String> processingStatus = ValueNotifier<String>('');

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
  @override
  void dispose() {
    print('DEBUG VIEWER: Disposing viewer');

    // 🎵 FASE 2: Limpar recursos de áudio e animação
    _audioPlayer.dispose();
    isDownloading.dispose();

    // Para todos os timers primeiro
    autoAdvanceTimer?.cancel();

    // Limpa todos os recursos
    _cleanupPreviousStory();
    
    // 🧹 LIMPAR CACHE DE VÍDEOS PRECARREGADOS
    print('🧹 DISPOSE: Limpando ${preloadedVideos.length} vídeos precarregados');
    for (final controller in preloadedVideos.values) {
      controller.dispose();
    }
    preloadedVideos.clear();
    preloadedImages.clear();
    currentlyPreloading.clear();

    // Dispose dos controladores
    try {
      autoCloseController.dispose();
    } catch (e) {
      print('Erro ao fazer dispose do autoCloseController: $e');
    }

    likeAnimationController?.dispose();
    pageController.dispose();
    progressController?.dispose();
    menuRevealNotifier.dispose();
    isPausedNotifier.dispose();

    // Remove listener de sincronização
    videoController?.removeListener(_syncVideoProgress);
    
    // Para e libera vídeo
    videoController?.pause();
    videoController?.dispose();

    // Remove controller apenas se foi criado aqui
    if (Get.isRegistered<StoryInteractionsController>()) {
      Get.delete<StoryInteractionsController>();
    }

    processingProgress.dispose();
    processingStatus.dispose();

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

    // Resetar menu oculto para novo story
    menuRevealNotifier.value = false;

    // Initialize interactions for current story
    interactionsController.initializeStory(currentStory.id!,
        contexto: widget.contexto);

    // Marcar story como visto ao inicializar
    _markCurrentStoryAsViewed();

    // Iniciar auto-close baseado no tipo de mídia
    _startAutoCloseForCurrentStory(currentStory);

    if (currentStory.fileType == StorieFileType.video) {
      // 🚀 VERIFICAR SE JÁ FOI PRECARREGADO
      if (preloadedVideos.containsKey(currentIndex)) {
        print('⚡ VIEWER: Usando vídeo PRECARREGADO $currentIndex (INSTANTÂNEO!)');
        videoController = preloadedVideos[currentIndex];
        preloadedVideos.remove(currentIndex); // Remover do cache de preload
        
        // Adicionar listeners e configurar
        videoController!.addListener(_syncVideoProgress);
        progressController = AnimationController(
          duration: videoController!.value.duration,
          vsync: this,
        );
        progressController!.addListener(_checkProgressCompletion);
        
        // Iniciar reprodução
        if (mounted) {
          setState(() {}); // Atualizar UI
          videoController!.play();
          progressController!.forward();
        }
        
        print('🎥 VIEWER: Vídeo iniciado INSTANTANEAMENTE! 🚀');
      } else {
        // Fallback: carregar normalmente se não estava precarregado
        print('⏳ VIEWER: Vídeo não estava precarregado, carregando...');
        _initializeVideo(currentStory.fileUrl!);
      }
    } else {
      // Para imagens, o cached_network_image já cuida do preload
      _startImageTimer();
    }
    
    // 🚀 PRECARREGAR STORIES ADJACENTES (próximos + anterior)
    // Delay pequeno para não competir com o story atual
    Future.delayed(Duration(milliseconds: 200), () {
      if (mounted) {
        _preloadAdjacentStories();
      }
    });
  }

  void _cleanupPreviousStory() {
    // Para timers
    autoAdvanceTimer?.cancel();
    imageProgressTimer?.cancel();
    autoCloseController.cancelAutoClose();
    progressController?.dispose();
    progressController = null;
    
    // Limpar variáveis de imagem
    imageStartTime = null;
    imagePausedDuration = null;

    // Para e libera vídeo anterior
    videoController?.pause();
    videoController?.dispose();
    videoController = null;
  }

  void _initializeVideo(String videoUrl) {
    print('DEBUG VIDEO: Inicializando vídeo: $videoUrl');
    
    // Se já existe um controller de vídeo inicializado e está pausado, não recriar
    if (videoController != null && 
        videoController!.value.isInitialized && 
        isPausedNotifier.value) {
      print('⏸️ VIDEO: Controller já existe e está pausado, mantendo estado');
      return;
    }

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

        // Criar progress controller
        progressController ??= AnimationController(
          duration: videoController!.value.duration,
          vsync: this,
        );
        
        // NOVO: Adicionar listener para sincronizar continuamente
        videoController!.addListener(_syncVideoProgress);
        progressController!.addListener(_checkProgressCompletion);
        progressController!.forward();
        
        print('🎥 VIDEO: Listeners adicionados - sincronização ativa');
      }
    }).catchError((error) {
      print('DEBUG VIDEO: Erro ao inicializar vídeo: $error');
    });
  }

  void _startImageTimer() {
    // PROTEÇÃO ABSOLUTA: Se progressController JÁ EXISTE, NÃO RECRIAR!
    if (progressController != null) {
      final currentProgress = (progressController!.value * 100).toStringAsFixed(1);
      final isPaused = isPausedNotifier.value;
      
      print('⚠️ TIMER: Controller JÁ EXISTE! Progresso: $currentProgress%, Pausado: $isPaused');
      print('⚠️ TIMER: BLOQUEANDO recriação do controller para evitar reset');
      
      // Se está pausado, não fazer nada
      if (isPaused) {
        print('⏸️ TIMER: Controller pausado, mantendo estado');
        return;
      }
      
      // Se já está animando ou tem progresso > 0, não recriar!
      if (progressController!.value > 0.0) {
        print('▶️ TIMER: Controller já tem progresso (${currentProgress}%), mantendo estado');
        return;
      }
      
      // Se chegou aqui, controller existe mas está em 0 e não pausado
      // Pode ser que precise reiniciar
      print('🔄 TIMER: Controller em 0%, permitindo reinício');
    }
    
    print('🆕 TIMER: Criando novo controller e timer para imagem (15s)');
    
    // Limpar timer anterior se existir
    imageProgressTimer?.cancel();
    imageProgressTimer = null;
    
    // Marcar hora de início
    imageStartTime = DateTime.now();
    imagePausedDuration = Duration.zero;
    
    // Criar controller
    progressController?.dispose();
    progressController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );

    progressController!.addListener(_checkProgressCompletion);
    print('✅ TIMER: Listener _checkProgressCompletion adicionado ao controller');
    
    // NOVO: Usar Timer periódico para atualizar progresso manualmente
    imageProgressTimer = Timer.periodic(Duration(milliseconds: 16), (timer) {
      _syncImageProgress();
    });
    
    print('✅ TIMER: Timer periódico iniciado - sincronização manual ativa');

    // VSL: Sem auto-advance - usuário controla o avanço manualmente
  }

  /// Verifica se o progressController chegou a 100% para revelar menu
  void _checkProgressCompletion() {
    if (progressController != null) {
      final currentValue = progressController!.value;
      
      // Log detalhado para debug
      if (currentValue >= 0.95) {
        print('📊 PROGRESS: ${(currentValue * 100).toStringAsFixed(1)}% (quase completando)');
      }
      
      if (currentValue >= 1.0) {
        // Story completado - revelar menu de interações
        if (!menuRevealNotifier.value) {
          menuRevealNotifier.value = true;
          print('🎉 MENU: Revelando botões de interação (story completado a 100%)');
        }
      }
    }
  }

  /// Sincroniza o progressController com a posição real do vídeo
  /// USANDO CURVA VSL (80% da barra = 40% do tempo real)
  void _syncVideoProgress() {
    if (videoController != null && 
        videoController!.value.isInitialized && 
        progressController != null &&
        !isPausedNotifier.value) {
      final position = videoController!.value.position;
      final duration = videoController!.value.duration;
      
      if (duration.inMilliseconds > 0) {
        // Progresso REAL do vídeo (0.0 a 1.0)
        final progressoReal = position.inMilliseconds / duration.inMilliseconds;
        
        // 🎯 APLICAR CURVA VSL (a mágica acontece aqui!)
        final progressoFicticio = _calcularBarraFicticia(progressoReal);
        
        // Atualizar progressController com progresso FICTÍCIO
        progressController!.value = progressoFicticio.clamp(0.0, 1.0);
        
        // Debug: Log quando estiver próximo do fim
        if (progressoFicticio >= 0.95 && progressoFicticio < 1.0) {
          print('🎥 VSL: Real: ${(progressoReal*100).toStringAsFixed(1)}% → Barra: ${(progressoFicticio*100).toStringAsFixed(1)}%');
        }
      }
    }
  }

  /// Sincroniza o progressController com o tempo decorrido para imagens
  void _syncImageProgress() {
    if (progressController != null && 
        imageStartTime != null &&
        !isPausedNotifier.value) {
      
      const imageDuration = Duration(seconds: 15);
      final elapsed = DateTime.now().difference(imageStartTime!);
      final progress = elapsed.inMilliseconds / imageDuration.inMilliseconds;
      
      // Atualizar progressController para refletir o tempo decorrido
      progressController!.value = progress.clamp(0.0, 1.0);
      
      // Debug: Log quando estiver próximo do fim
      if (progress >= 0.95 && progress < 1.0) {
        print('🖼️ IMAGE SYNC: ${(progress * 100).toStringAsFixed(1)}%');
      }
    }
  }

  /// 🎯 Calcula o progresso FICTÍCIO da barra VSL
  /// 
  /// **Regra VSL:**
  /// - Primeiros 40% do vídeo = 80% da barra (FASE RÁPIDA ⚡)
  /// - Últimos 60% do vídeo = 20% da barra (FASE LENTA 🐌)
  /// 
  /// **Por quê isso funciona?**
  /// - Usuário vê barra em 80% aos 24s de um vídeo de 60s
  /// - Pensa: "Quase acabando! Vou ver até o fim!"
  /// - Resultado: Assiste o vídeo COMPLETO 🎯
  double _calcularBarraFicticia(double progressoReal) {
    // Garantir que está entre 0.0 e 1.0
    progressoReal = progressoReal.clamp(0.0, 1.0);
    
    if (progressoReal <= 0.4) {
      // 📊 FASE RÁPIDA (0% a 40% do vídeo = 0% a 80% da barra)
      // Exemplo: 20% do vídeo → 40% da barra
      //          40% do vídeo → 80% da barra
      return progressoReal * 2.0;
      
    } else {
      // 🐌 FASE LENTA (40% a 100% do vídeo = 80% a 100% da barra)
      // Exemplo: 60% do vídeo → 87% da barra
      //          80% do vídeo → 93% da barra
      //         100% do vídeo → 100% da barra
      
      double progressoRestante = progressoReal - 0.4; // 0.0 a 0.6
      double percentualRestante = progressoRestante / 0.6; // Normaliza (0.0 a 1.0)
      double barraRestante = percentualRestante * 0.2; // 0.0 a 0.2 (20% da barra)
      return 0.8 + barraRestante; // 0.8 a 1.0 (80% a 100%)
    }
  }

  /// 🎉 Revela o menu de CTA quando a barra chegar em 100%
  void _revelarMenu() {
    if (!menuRevealNotifier.value) {
      print('🎯 VSL: Barra chegou em 100% - Revelando menu de interações!');
      menuRevealNotifier.value = true;
    }
  }

  // ========================================
  // 🚀 SISTEMA DE PRELOAD INSTANTÂNEO
  // ========================================

  /// 🎥 Precarrega um vídeo em background para carregamento instantâneo
  Future<void> _preloadVideo(int index) async {
    // Verificar se já está precarregando ou já foi precarregado
    if (currentlyPreloading.contains(index) || 
        preloadedVideos.containsKey(index)) {
      return;
    }
    
    // Verificar se índice é válido
    if (index < 0 || index >= stories.length) return;
    
    final story = stories[index];
    if (story.fileType != StorieFileType.video || story.fileUrl == null) {
      return;
    }
    
    print('🎥 PRELOAD: Iniciando preload do vídeo $index');
    currentlyPreloading.add(index);
    
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(story.fileUrl!),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );
      
      await controller.initialize();
      controller.setLooping(false);
      
      // Salvar no cache
      if (mounted) {
        preloadedVideos[index] = controller;
        print('✅ PRELOAD: Vídeo $index precarregado com sucesso');
      } else {
        controller.dispose();
      }
      
    } catch (e) {
      print('❌ PRELOAD: Erro ao precarregar vídeo $index: $e');
    } finally {
      currentlyPreloading.remove(index);
    }
  }

  /// 🖼️ Precarrega uma imagem em background para carregamento instantâneo
  Future<void> _preloadImage(int index) async {
    // Verificar se já foi precarregado
    if (preloadedImages.contains(index)) return;
    
    // Verificar se índice é válido
    if (index < 0 || index >= stories.length) return;
    
    final story = stories[index];
    if (story.fileType == StorieFileType.video || story.fileUrl == null) {
      return;
    }
    
    print('🖼️ PRELOAD: Iniciando preload da imagem $index');
    
    try {
      // Usar precacheImage do Flutter para forçar download
      await precacheImage(
        CachedNetworkImageProvider(story.fileUrl!),
        context,
      );
      
      if (mounted) {
        preloadedImages.add(index);
        print('✅ PRELOAD: Imagem $index precarregada com sucesso');
      }
      
    } catch (e) {
      print('❌ PRELOAD: Erro ao precarregar imagem $index: $e');
    }
  }

  /// 🔄 Precarrega os stories adjacentes (anterior + próximos 2)
  void _preloadAdjacentStories() {
    print('🔄 PRELOAD: Iniciando preload dos stories adjacentes');
    print('🔄 PRELOAD: Índice atual: $currentIndex');
    
    // Precarregar anterior (para voltar rápido)
    if (currentIndex > 0) {
      final prevIndex = currentIndex - 1;
      final prevStory = stories[prevIndex];
      
      if (prevStory.fileType == StorieFileType.video) {
        _preloadVideo(prevIndex);
      } else {
        _preloadImage(prevIndex);
      }
    }
    
    // Precarregar próximos 2 stories (para avançar instantâneo)
    for (int i = 1; i <= 2; i++) {
      final nextIndex = currentIndex + i;
      if (nextIndex >= stories.length) break;
      
      final nextStory = stories[nextIndex];
      
      if (nextStory.fileType == StorieFileType.video) {
        _preloadVideo(nextIndex);
      } else {
        _preloadImage(nextIndex);
      }
    }
  }

  /// 🧹 Limpa stories distantes da memória (gerenciamento de memória)
  void _cleanupDistantStories() {
    print('🧹 CLEANUP: Limpando stories distantes da memória');
    
    // Lista de índices a manter (buffer de 4 stories)
    final indicesToKeep = <int>{};
    
    // Manter anterior
    if (currentIndex > 0) {
      indicesToKeep.add(currentIndex - 1);
    }
    
    // Manter atual
    indicesToKeep.add(currentIndex);
    
    // Manter próximos 2
    for (int i = 1; i <= 2; i++) {
      if (currentIndex + i < stories.length) {
        indicesToKeep.add(currentIndex + i);
      }
    }
    
    // Limpar vídeos não utilizados
    final videoIndicesToRemove = preloadedVideos.keys
        .where((index) => !indicesToKeep.contains(index))
        .toList();
    
    for (final index in videoIndicesToRemove) {
      print('🗑️ CLEANUP: Removendo vídeo $index da memória');
      preloadedVideos[index]?.dispose();
      preloadedVideos.remove(index);
    }
    
    // Limpar marcação de imagens precarregadas
    // (o cached_network_image cuida da memória, só limpamos a marcação)
    preloadedImages.removeWhere((index) => !indicesToKeep.contains(index));
    
    print('✅ CLEANUP: Memória otimizada - mantendo ${indicesToKeep.length} stories');
  }

  // ========================================
  // FIM DO SISTEMA DE PRELOAD
  // ========================================

  void _nextStory() {
    // ESCONDE O MENU ANTES DE IR PARA O PRÓXIMO
    menuRevealNotifier.value = false;

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
      
      // 🧹 LIMPAR STORIES DISTANTES DA MEMÓRIA
      _cleanupDistantStories();
    } else {
      // Fim dos stories - tentar carregar mais ou fechar
      _handleEndOfStories();
    }
  }

  void _replayStory() {
    print('🔄 REPLAY: Reiniciando story atual');

    // 1. Se for um vídeo, volte ao início e toque
    if (videoController != null && videoController!.value.isInitialized) {
      videoController?.seekTo(Duration.zero);
      videoController?.play();
    }

    // 2. Reinicie a barra de progresso (a VSL de 15s ou do vídeo)
    progressController?.reset();
    progressController?.forward();

    // 3. Esconda o menu de ações de novo
    menuRevealNotifier.value = false;
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
    final wasPaused = isPausedNotifier.value;
    print('🎮 PAUSE: Alternando estado - atual: $wasPaused');
    
    // IMPORTANTE: Salvar o valor atual do progressController ANTES de mudar o estado
    final currentProgress = progressController?.value ?? 0.0;
    
    // Usar ValueNotifier ao invés de setState para evitar rebuild completo
    isPausedNotifier.value = !wasPaused;

    if (isPausedNotifier.value) {
      print('⏸️ PAUSE: Pausando story no progresso: ${(currentProgress * 100).toStringAsFixed(1)}%');
      // Pausa o timer de auto-advance
      autoAdvanceTimer?.cancel();
      // Pausa o auto-close controller
      autoCloseController.pauseAutoClose();
      // Pausa o progress controller (mantém posição atual)
      progressController?.stop();
      // Pausa vídeo se existir
      videoController?.pause();
      // Pausa timer de sincronização de imagem
      imageProgressTimer?.cancel();
      // Salvar tempo pausado
      if (imageStartTime != null) {
        imagePausedDuration = (imagePausedDuration ?? Duration.zero) + DateTime.now().difference(imageStartTime!);
        print('⏸️ PAUSE: Tempo pausado total: ${imagePausedDuration!.inSeconds}s');
      }
    } else {
      print('▶️ PLAY: Retomando story do progresso: ${(currentProgress * 100).toStringAsFixed(1)}%');
      // Retoma o auto-close controller
      autoCloseController.resumeAutoClose();
      
      // Retoma vídeo se existir (o listener _syncVideoProgress vai cuidar do progressController)
      if (videoController != null && videoController!.value.isInitialized) {
        videoController!.play();
        print('▶️ PLAY: Vídeo retomado - sync automático ativo');
      } else {
        // Para IMAGENS: Retomar timer de sincronização manual
        if (progressController != null && imageStartTime != null) {
          print('▶️ PLAY: Retomando sincronização manual de imagem');
          
          // Ajustar hora de início para compensar o tempo pausado
          imageStartTime = DateTime.now().subtract(imagePausedDuration ?? Duration.zero);
          
          // Reiniciar timer periódico
          imageProgressTimer?.cancel();
          imageProgressTimer = Timer.periodic(Duration(milliseconds: 16), (timer) {
            _syncImageProgress();
          });
          
          print('✅ PLAY: Timer de sincronização retomado - progresso mantido em ${(currentProgress * 100).toStringAsFixed(1)}%');
        } else {
          print('⚠️ PLAY: Não há timer/controller para retomar');
        }
      }
    }

    print('🎮 PAUSE: Novo estado: ${isPausedNotifier.value}');
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

  /// Faz download do story atual com marca d'água
  /// 🎬 VERSÃO FINAL: Com marca d'água aplicada no arquivo baixado
  Future<void> _downloadStory() async {
    final story = stories[currentIndex];
    
    // Validar se tem URL
    if (story.fileUrl == null || story.fileUrl!.isEmpty) {
      Get.rawSnackbar(
        message: 'Erro: Story sem URL válida',
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    print('📥 DOWNLOAD: Iniciando download com marca d\'água do story ${story.id}');
    print('📥 DOWNLOAD: URL: ${story.fileUrl}');
    print('📥 DOWNLOAD: Tipo: ${story.fileType?.name}');
    print('📥 DOWNLOAD: Plataforma: ${kIsWeb ? "WEB" : "MOBILE"}');

    // 🔐 Verificar permissões no Mobile
    if (!kIsWeb) {
      // Verificar versão do Android para decidir qual permissão usar
      PermissionStatus status;
      
      // Tentar Permission.photos primeiro (Android 13+)
      status = await Permission.photos.status;
      
      if (status.isDenied) {
        // Pedir permissão
        status = await Permission.photos.request();
      }
      
      // Se photos não funcionar, tentar storage (Android < 13)
      if (!status.isGranted) {
        status = await Permission.storage.status;
        
        if (status.isDenied) {
          status = await Permission.storage.request();
        }
      }
      
      // Se ainda não tiver permissão, verificar se foi negada permanentemente
      if (!status.isGranted) {
        if (status.isPermanentlyDenied) {
          // Usuário negou permanentemente, precisa ir nas configurações
          Get.rawSnackbar(
            message: 'Permissão negada. Vá em Configurações → Permissões para habilitar.',
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
            mainButton: TextButton(
              onPressed: () => openAppSettings(),
              child: const Text('Abrir Configurações', style: TextStyle(color: Colors.white)),
            ),
          );
        } else {
          Get.rawSnackbar(
            message: 'Permissão de armazenamento necessária para salvar stories.',
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          );
        }
        print('⚠️ DOWNLOAD: Permissão negada (status: ${status.name})');
        return;
      }
      print('✅ DOWNLOAD: Permissão concedida');
    }

    // 🎵 Ativar animação e áudio
    isDownloading.value = true;

    try {
      if (kIsWeb) {
        // =============================================
        // WEB: Download direto (sem processamento)
        // =============================================
        final ext = (story.fileType == StorieFileType.video) ? '.mp4' : '.jpg';
        final fileName = 'story_${story.id}$ext';

        print('🌐 WEB: Baixando arquivo original: $fileName');
        downloadFileWeb(story.fileUrl!, fileName);

        Get.rawSnackbar(
          message: 'Download iniciado! (Web não suporta marca d\'água)',
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 3),
        );
      } else {
        // =============================================
        // MOBILE: Download com processamento de marca d'água
        // =============================================
        // 🦁 Tocar rugido
        _audioPlayer.play(AssetSource('audios/rugido_leao.mp3'));
        print('🦁 MOBILE: Rugido tocando!');

        // 1. Baixar arquivo original
        final tempDir = await getTemporaryDirectory();
        final ext = (story.fileType == StorieFileType.video) ? '.mp4' : '.jpg';
        final tempPath = '${tempDir.path}/original_${story.id}$ext';

        print('📱 MOBILE: Baixando arquivo original...');
        processingStatus.value = 'Baixando...';

        await Dio().download(
          story.fileUrl!,
          tempPath,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              final progress = received / total * 0.3; // 30% do progresso total
              processingProgress.value = progress;
              print('📱 DOWNLOAD: ${(progress * 100).toStringAsFixed(0)}%');
            }
          },
        );

        print('✅ MOBILE: Arquivo baixado, iniciando processamento...');

        // 2. Processar com marca d'água
        String? processedPath;

        if (story.fileType == StorieFileType.video) {
          // PROCESSAR VÍDEO
          final videoDuration = story.videoDuration?.toDouble() ?? 15.0;
          print('🎬 MOBILE: Processando vídeo (duração: $videoDuration s)...');

          processedPath = await WatermarkProcessor.processVideoWithWatermark(
            inputVideoPath: tempPath,
            videoDuration: videoDuration,
            onProgress: (progress, status) {
              // Progresso de 30% a 100%
              processingProgress.value = 0.3 + (progress * 0.7);
              processingStatus.value = status;
              print('🎬 PROCESSAMENTO: ${(processingProgress.value * 100).toStringAsFixed(0)}% - $status');
            },
          );

          if (processedPath != null) {
            print('✅ MOBILE: Vídeo processado com sucesso!');
            await Gal.putVideo(processedPath);
            print('✅ MOBILE: Vídeo salvo na galeria!');
          }
        } else {
          // PROCESSAR IMAGEM
          print('📸 MOBILE: Processando imagem...');

          processedPath = await WatermarkProcessor.processImageWithWatermark(
            inputImagePath: tempPath,
            onProgress: (progress, status) {
              // Progresso de 30% a 100%
              processingProgress.value = 0.3 + (progress * 0.7);
              processingStatus.value = status;
              print('📸 PROCESSAMENTO: ${(processingProgress.value * 100).toStringAsFixed(0)}% - $status');
            },
          );

          if (processedPath != null) {
            print('✅ MOBILE: Imagem processada com sucesso!');
            await Gal.putImage(processedPath);
            print('✅ MOBILE: Imagem salva na galeria!');
          }
        }

        // 3. Verificar sucesso
        if (processedPath == null) {
          throw Exception('Falha no processamento da marca d\'água');
        }

        // 4. Limpar arquivo temporário original
        try {
          await File(tempPath).delete();
        } catch (e) {
          print('⚠️ Erro ao deletar arquivo temporário: $e');
        }
      }

      // Feedback de SUCESSO
      Get.rawSnackbar(
        message: 'Salvo com sucesso! 🎉',
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      );
      print('✅ DOWNLOAD: Concluído com sucesso!');
    } catch (e, stackTrace) {
      // Feedback de ERRO
      print('❌ DOWNLOAD: Erro: $e');
      print('📋 Stack: $stackTrace');
      Get.rawSnackbar(
        message: 'Erro ao salvar o story: $e',
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      );
    } finally {
      // Desligar animação após 1 segundo
      await Future.delayed(const Duration(milliseconds: 1000));
      isDownloading.value = false;
      processingProgress.value = 0.0;
      processingStatus.value = '';
      print('🎬 DOWNLOAD: Animação finalizada');
    }
  }

  void _showComments() async {
    final story = stories[currentIndex];

    // PASSO 1: Pausar tudo antes de abrir comentários
    _pauseAutoClose();
    videoController?.pause();
    progressController?.stop();

    // PASSO 2: Navegar e ESPERAR o usuário voltar
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CommunityCommentsView(
          story: story,
        ),
      ),
    );

    // PASSO 3: Retomar tudo quando o usuário voltar
    _resumeAutoClose();
    if (videoController != null && videoController!.value.isInitialized) {
      videoController!.play();
    }
    // Retomar progressController de onde parou
    if (progressController != null) {
      progressController!.forward(from: progressController!.value);
    }
  }

  void _showReplyOptions() {
    final currentStory = stories[currentIndex];
    
    print('💬 RESPONDER: Iniciando resposta ao Pai');
    print('💬 RESPONDER: Story ID: ${currentStory.id}');
    print('💬 RESPONDER: Contexto: ${widget.contexto}');
    
    // Fechar o viewer de stories
    Navigator.of(context).pop();
    
    // Preparar dados do story para resposta
    final replyData = {
      'replyToStory': {
        'storyId': currentStory.id,
        'storyTitle': currentStory.titulo,
        'storyDescription': currentStory.descricao,
        'storyUrl': currentStory.fileUrl,
        'storyType': currentStory.fileType?.name ?? 'image',
        'contexto': currentStory.contexto ?? widget.contexto, // 🔧 NOVO: Salvar contexto
        'userMessage': '', // Será preenchido pelo usuário no chat
        'timestamp': DateTime.now().toIso8601String(),
      }
    };
    
    // Navegar para o chat correto baseado no contexto
    Widget chatWidget;
    switch (widget.contexto) {
      case 'sinais_isaque':
        chatWidget = const SinaisIsaqueView();
        break;
      case 'sinais_rebeca':
        chatWidget = const SinaisRebecaView();
        break;
      case 'nosso_proposito':
        chatWidget = const NossoPropositoView();
        break;
      case 'principal':
      default:
        chatWidget = const ChatView();
        break;
    }
    
    print('💬 RESPONDER: Navegando para chat ${widget.contexto}');
    
    // Navegar para o chat com os dados do story
    Get.to(
      () => chatWidget,
      arguments: replyData,
    );
    
    print('💬 RESPONDER: Dados enviados: $replyData');
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
                    child: ValueListenableBuilder<bool>(
                      valueListenable: isPausedNotifier,
                      builder: (context, isPaused, child) {
                        // Cor de fundo do container (não preenche quando é o story atual)
                        final backgroundColor = index < currentIndex
                            ? Colors.white
                            : index == currentIndex
                                ? Colors.white.withOpacity(0.5)
                                : Colors.white.withOpacity(0.3);
                        
                        return Container(
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: index == currentIndex &&
                                  progressController != null
                              ? AnimatedBuilder(
                                  animation: progressController!,
                                  builder: (context, child) {
                                    return LinearProgressIndicator(
                                      value: progressController!.value,
                                      backgroundColor: Colors.transparent,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        isPaused ? Colors.orange : Colors.white
                                      ),
                                    );
                                  },
                                )
                              : null,
                        );
                      },
                    ),
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
                ValueListenableBuilder<bool>(
                  valueListenable: isPausedNotifier,
                  builder: (context, isPaused, child) {
                    return Container(
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
                    );
                  },
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
          ValueListenableBuilder<bool>(
            valueListenable: isPausedNotifier,
            builder: (context, isPaused, child) {
              if (!isPaused) return const SizedBox.shrink();
              
              return Center(
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
              );
            },
          ),

          // Story info overlay removido para evitar duplicação

          // 🎵 FASE 2: Interactions panel OU Animação de Download
          if (stories.isNotEmpty)
            ValueListenableBuilder<bool>(
              valueListenable: isDownloading,
              builder: (context, isDownloadingNow, child) {
                if (isDownloadingNow) {
                  // 1. SE ESTIVER BAIXANDO: Mostra a ANIMAÇÃO DA LOGO
                  return Positioned(
                    bottom: 120, // Posição do antigo botão de download
                    right: 16,
                    child: DownloadAnimationWidget(
                      logoWidget: Image.asset(
                        'lib/assets/img/logo_leao.png',
                        width: 60,
                        height: 60,
                      ),
                    ),
                  );
                } else {
                  // 2. SE NÃO ESTIVER BAIXANDO: Mostra o MENU LATERAL normal
                  return StoryInteractionsComponent(
                    storyId: stories[currentIndex].id!,
                    onCommentTap: _showComments,
                  );
                }
              },
            ),

          // 🎬 Indicador de progresso do processamento
          ValueListenableBuilder<bool>(
            valueListenable: isDownloading,
            builder: (context, downloading, child) {
              if (!downloading) return const SizedBox.shrink();
              
              return Positioned(
                left: 0,
                right: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  color: Colors.black.withOpacity(0.8),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo animada (mesma do widget existente)
                        DownloadAnimationWidget(
                          logoWidget: Image.asset(
                            'lib/assets/img/logo_leao.png',
                            width: 150,
                            height: 150,
                          ),
                        ),
                        const SizedBox(height: 40),
                        
                        // Barra de progresso
                        ValueListenableBuilder<double>(
                          valueListenable: processingProgress,
                          builder: (context, progress, child) {
                            return Container(
                              width: 280,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: progress,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Colors.orange, Colors.deepOrange],
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Status do processamento
                        ValueListenableBuilder<String>(
                          valueListenable: processingStatus,
                          builder: (context, status, child) {
                            if (status.isEmpty) return const SizedBox.shrink();
                            return Text(
                              status,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        
                        // Porcentagem
                        ValueListenableBuilder<double>(
                          valueListenable: processingProgress,
                          builder: (context, progress, child) {
                            return Text(
                              '${(progress * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Modern Action Menu Overlay
          ValueListenableBuilder<bool>(
            valueListenable: menuRevealNotifier,
            builder: (context, isMenuRevealed, child) {
              return IgnorePointer(
                ignoring: !isMenuRevealed,
                child: AnimatedOpacity(
                  opacity: isMenuRevealed ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  // GestureDetector para capturar swipes horizontais
                  child: GestureDetector(
                    // 1. LÓGICA DE SWIPE
                    onHorizontalDragEnd: (details) {
                      if (details.primaryVelocity! < 0) {
                        // Deslizou para a ESQUERDA -> Próximo Story
                        _nextStory();
                      } else if (details.primaryVelocity! > 0) {
                        // Deslizou para a DIREITA -> Replay
                        _replayStory();
                      }
                    },
                    // 2. FUNDO PRETO
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                      width: double.infinity,
                      height: double.infinity,
                      // 3. ÁREAS DE TAP + MENU NO CENTRO
                      child: Stack(
                        children: [
                          // Áreas de tap (esquerda e direita)
                          Row(
                            children: [
                              // Área ESQUERDA - Voltar story
                              Expanded(
                                flex: 3,
                                child: GestureDetector(
                                  onTap: _previousStory,
                                  child: Container(color: Colors.transparent),
                                ),
                              ),
                              // Área CENTRAL - Sem ação (onde fica o menu)
                              Expanded(
                                flex: 4,
                                child: Container(color: Colors.transparent),
                              ),
                              // Área DIREITA - Avançar story
                              Expanded(
                                flex: 3,
                                child: GestureDetector(
                                  onTap: _nextStory,
                                  child: Container(color: Colors.transparent),
                                ),
                              ),
                            ],
                          ),
                          // Menu centralizado (por cima das áreas de tap)
                          Center(
                            // GestureDetector interno para "consumir" gestos nos botões
                            child: GestureDetector(
                              onTap: () {
                                // Consome o tap para não passar para as áreas abaixo
                              },
                              onHorizontalDragEnd: (details) {
                                // Consome o swipe se começar em cima do menu
                              },
                              child: StoryActionMenu(
                                onCommentTap: _showComments,
                                onSaveTap: () {
                                  final controller =
                                      Get.find<StoryInteractionsController>();
                                  controller.toggleFavorite();
                                },
                                onShareTap: () {
                                  final controller =
                                      Get.find<StoryInteractionsController>();
                                  controller.shareStory();
                                },
                                onDownloadTap: _downloadStory,
                                onReplyTap: _showReplyOptions,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Botão FECHAR POR CIMA do overlay (quando menu está visível)
          // APENAS FECHAR - sem botão PAUSE (não faz sentido pausar quando menu está aberto)
          ValueListenableBuilder<bool>(
            valueListenable: menuRevealNotifier,
            builder: (context, isMenuRevealed, child) {
              if (!isMenuRevealed) return const SizedBox.shrink();
              
              return Positioned(
                top: 50,
                right: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () {
                      print('DEBUG: Botão fechar pressionado (overlay)');
                      // Para todos os timers e controladores
                      autoAdvanceTimer?.cancel();
                      autoCloseController.dispose();
                      videoController?.pause();
                      progressController?.stop();
                      // Fecha o viewer
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.close,
                        color: Colors.white, size: 24),
                  ),
                ),
              );
            },
          ),

          // Botão de pause CENTRAL (quando pausado E menu visível)
          ValueListenableBuilder<bool>(
            valueListenable: isPausedNotifier,
            builder: (context, isPaused, child) {
              return ValueListenableBuilder<bool>(
                valueListenable: menuRevealNotifier,
                builder: (context, menuRevealed, child) {
                  if (!isPaused || !menuRevealed) return const SizedBox.shrink();
                  
                  return Center(
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
                  );
                },
              );
            },
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
          ValueListenableBuilder<bool>(
            valueListenable: isPausedNotifier,
            builder: (context, isPaused, child) {
              if (!isPaused) return const SizedBox.shrink();
              
              return Positioned(
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
              );
            },
          ),

          // Indicador de pause sutil quando pausado
          ValueListenableBuilder<bool>(
            valueListenable: isPausedNotifier,
            builder: (context, isPaused, child) {
              if (!isPaused) return const SizedBox.shrink();
              
              return Positioned(
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
              );
            },
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


// #################################################
// 🎵 FASE 2: WIDGET DA ANIMAÇÃO DE DOWNLOAD
// #################################################
class DownloadAnimationWidget extends StatefulWidget {
  final Widget logoWidget; // Para passar a logo como um widget

  const DownloadAnimationWidget({
    super.key,
    required this.logoWidget,
  });

  @override
  _DownloadAnimationWidgetState createState() =>
      _DownloadAnimationWidgetState();
}

class _DownloadAnimationWidgetState extends State<DownloadAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotationAnimation; // Para o efeito de "tremer"

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true); // Faz a animação "ir e voltar"

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.0, -0.5), // Desliza para cima
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _rotationAnimation = Tween<double>(
      begin: -0.05, // Pequena rotação para a esquerda
      end: 0.05, // Pequena rotação para a direita
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutSine, // Curva suave para o tremor
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: RotationTransition(
        // Adiciona a rotação para o tremor
        turns: _rotationAnimation,
        child: widget.logoWidget, // Usa a logo passada
      ),
    );
  }
}
// FIM DO WIDGET DA ANIMAÇÃO
