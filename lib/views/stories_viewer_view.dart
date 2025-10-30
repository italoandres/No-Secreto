import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../models/storie_file_model.dart';
import '../models/usuario_model.dart';
import '../repositories/stories_repository.dart';

class StoriesViewerView extends StatefulWidget {
  final String contexto;
  final UserSexo? userSexo;

  const StoriesViewerView({
    super.key,
    required this.contexto,
    required this.userSexo,
  });

  @override
  State<StoriesViewerView> createState() => _StoriesViewerViewState();
}

class _StoriesViewerViewState extends State<StoriesViewerView>
    with TickerProviderStateMixin {
  List<StorieFileModel> stories = [];
  int currentIndex = 0;
  bool isLoading = true;
  Timer? autoAdvanceTimer;
  AnimationController? progressController;
  VideoPlayerController? videoController;

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  @override
  void dispose() {
    autoAdvanceTimer?.cancel();
    progressController?.dispose();
    videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadStories() async {
    print('DEBUG VIEWER: Carregando stories para contexto: ${widget.contexto}');
    print('DEBUG VIEWER: Usuário sexo: ${widget.userSexo}');

    try {
      // Carregar stories do repositório
      final allStories = await _getStoriesFromRepository();

      // Filtrar stories válidos (24h e público-alvo)
      final validStories = _filterValidStories(allStories);

      print('DEBUG VIEWER: Total stories carregados: ${allStories.length}');
      print(
          'DEBUG VIEWER: Stories válidos após filtro: ${validStories.length}');

      setState(() {
        stories = validStories;
        isLoading = false;
      });

      if (stories.isNotEmpty) {
        _startCurrentStory();
      }
    } catch (e) {
      print('DEBUG VIEWER: Erro ao carregar stories: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<List<StorieFileModel>> _getStoriesFromRepository() async {
    // Usar o método correto baseado no contexto
    Stream<List<StorieFileModel>> stream;
    switch (widget.contexto) {
      case 'sinais_isaque':
        stream = StoriesRepository.getAllSinaisIsaque();
        break;
      case 'sinais_rebeca':
        stream = StoriesRepository.getAllSinaisRebeca();
        break;
      default:
        stream = StoriesRepository.getAll();
    }
    return await stream.first;
  }

  List<StorieFileModel> _filterValidStories(List<StorieFileModel> allStories) {
    final now = DateTime.now();
    final twentyFourHoursAgo = now.subtract(const Duration(hours: 24));

    return allStories.where((story) {
      // Filtrar APENAS por tempo (24 horas) - NÃO filtrar por stories vistos
      final storyDate = story.dataCadastro?.toDate();
      if (storyDate == null || storyDate.isBefore(twentyFourHoursAgo)) {
        print(
            'DEBUG VIEWER: Story ${story.id} filtrado por tempo (mais de 24h)');
        return false;
      }

      // Filtrar por público-alvo
      if (story.publicoAlvo == null) {
        print('DEBUG VIEWER: Story ${story.id} visível para todos');
        return true; // Visível para todos
      }

      final isValidForUser = story.publicoAlvo == widget.userSexo;
      print(
          'DEBUG VIEWER: Story ${story.id} publicoAlvo: ${story.publicoAlvo}, userSexo: ${widget.userSexo}, válido: $isValidForUser');
      return isValidForUser;
    }).toList();
  }

  void _startCurrentStory() {
    if (currentIndex >= stories.length) return;

    final currentStory = stories[currentIndex];
    print(
        'DEBUG VIEWER: Iniciando story ${currentIndex + 1}/${stories.length}');

    // Marcar story como visto
    if (currentStory.id != null) {
      StoriesRepository.addVisto(currentStory.id!, contexto: widget.contexto);
    }

    // Cancelar timer anterior
    autoAdvanceTimer?.cancel();
    progressController?.dispose();

    // Criar novo controller de progresso
    progressController = AnimationController(
      duration: _getStoryDuration(currentStory),
      vsync: this,
    );

    // Iniciar progresso
    progressController!.forward();

    // Configurar auto-advance
    if (currentStory.fileType == StorieFileType.img) {
      _startImageTimer();
    } else {
      _startVideoTimer(currentStory);
    }
  }

  Duration _getStoryDuration(StorieFileModel story) {
    if (story.fileType == StorieFileType.img) {
      return const Duration(seconds: 5);
    } else {
      return Duration(seconds: story.videoDuration ?? 10);
    }
  }

  void _startImageTimer() {
    autoAdvanceTimer = Timer(const Duration(seconds: 5), () {
      _nextStory();
    });
  }

  void _startVideoTimer(StorieFileModel story) {
    final duration = story.videoDuration ?? 10;
    autoAdvanceTimer = Timer(Duration(seconds: duration), () {
      _nextStory();
    });
  }

  void _nextStory() {
    if (currentIndex < stories.length - 1) {
      setState(() {
        currentIndex++;
      });
      _startCurrentStory();
    } else {
      // Último story, fechar viewer
      _closeViewer();
    }
  }

  void _previousStory() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
      });
      _startCurrentStory();
    }
  }

  void _closeViewer() {
    print('DEBUG VIEWER: Fechando viewer');
    Get.back();
  }

  Widget _buildFallbackImage(String imageUrl) {
    print('DEBUG VIEWER: Tentando fallback para: $imageUrl');

    // Tentar diferentes variações da URL
    final variations = [
      imageUrl,
      imageUrl.replaceAll('&', '%26'), // Encode &
      imageUrl.split('?').first, // Remove query parameters
    ];

    return FutureBuilder<Widget>(
      future: _tryImageVariations(variations),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        if (snapshot.hasData) {
          return snapshot.data!;
        }

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white54, size: 48),
              const SizedBox(height: 8),
              const Text(
                'Não foi possível carregar a imagem',
                style: TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 8),
              Text(
                'URL: $imageUrl',
                style: const TextStyle(color: Colors.white38, fontSize: 10),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    // Força rebuild para tentar novamente
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white24,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Widget> _tryImageVariations(List<String> urls) async {
    for (int i = 0; i < urls.length; i++) {
      final url = urls[i];
      print('DEBUG VIEWER: Tentando variação ${i + 1}: $url');

      try {
        // Tentar carregar a imagem
        final widget = Image.network(
          url,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              print('DEBUG VIEWER: Variação ${i + 1} carregada com sucesso');
              return child;
            }
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('DEBUG VIEWER: Variação ${i + 1} falhou: $error');
            throw Exception('Failed to load image variation ${i + 1}');
          },
        );

        return widget;
      } catch (e) {
        print('DEBUG VIEWER: Variação ${i + 1} falhou: $e');
        continue;
      }
    }

    throw Exception('All image variations failed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : stories.isEmpty
                ? _buildEmptyState()
                : _buildStoriesViewer(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: Colors.white54,
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhum story disponível',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Não há stories recentes para exibir',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _closeViewer,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white24,
              foregroundColor: Colors.white,
            ),
            child: const Text('Voltar'),
          ),
        ],
      ),
    );
  }

  Widget _buildStoriesViewer() {
    final currentStory = stories[currentIndex];

    return Stack(
      children: [
        // Conteúdo principal
        _buildStoryContent(currentStory),

        // Barra de progresso
        _buildProgressBar(),

        // Controles
        _buildControls(),

        // Detector de gestos
        _buildGestureDetector(),
      ],
    );
  }

  Widget _buildStoryContent(StorieFileModel story) {
    return Center(
      child: story.fileType == StorieFileType.img
          ? _buildImageContent(story)
          : _buildVideoContent(story),
    );
  }

  Widget _buildImageContent(StorieFileModel story) {
    print('DEBUG VIEWER: Carregando imagem: ${story.fileUrl}');

    if (story.fileUrl == null || story.fileUrl!.isEmpty) {
      print('DEBUG VIEWER: URL da imagem está vazia');
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.white54, size: 48),
            SizedBox(height: 8),
            Text(
              'URL da imagem inválida',
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      );
    }

    // Usar Image.network diretamente para melhor compatibilidade no Chrome
    return Image.network(
      story.fileUrl!,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          print('DEBUG VIEWER: Imagem carregada com sucesso');
          return child;
        }

        final progress = loadingProgress.expectedTotalBytes != null
            ? loadingProgress.cumulativeBytesLoaded /
                loadingProgress.expectedTotalBytes!
            : null;

        print(
            'DEBUG VIEWER: Carregando... ${progress != null ? '${(progress * 100).toInt()}%' : ''}');

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Colors.white,
                value: progress,
              ),
              if (progress != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(color: Colors.white54),
                ),
              ],
            ],
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        print('DEBUG VIEWER: Erro ao carregar imagem: $error');
        print('DEBUG VIEWER: Stack trace: $stackTrace');

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white54, size: 48),
              const SizedBox(height: 8),
              const Text(
                'Erro ao carregar imagem',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text(
                      'URL:',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      story.fileUrl!,
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Erro:',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      error.toString(),
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    // Força rebuild para tentar novamente
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white24,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVideoContent(StorieFileModel story) {
    // TODO: Implementar player de vídeo
    return const Center(
      child: Text(
        'Player de vídeo será implementado',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Row(
        children: List.generate(stories.length, (index) {
          return Expanded(
            child: Container(
              height: 3,
              margin:
                  EdgeInsets.only(right: index < stories.length - 1 ? 4 : 0),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(1.5),
              ),
              child: AnimatedBuilder(
                animation: progressController ?? AlwaysStoppedAnimation(0),
                builder: (context, child) {
                  double progress = 0;
                  if (index < currentIndex) {
                    progress = 1.0;
                  } else if (index == currentIndex) {
                    progress = progressController?.value ?? 0;
                  }

                  return LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.transparent,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  );
                },
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      top: 60,
      right: 16,
      child: Row(
        children: [
          // Botão fechar
          IconButton(
            onPressed: _closeViewer,
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black26,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGestureDetector() {
    return Positioned.fill(
      child: Row(
        children: [
          // Área esquerda - voltar story
          Expanded(
            child: GestureDetector(
              onTap: _previousStory,
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          // Área direita - próximo story
          Expanded(
            child: GestureDetector(
              onTap: _nextStory,
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
