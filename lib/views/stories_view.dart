import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:whatsapp_chat/components/video_player.dart';
import 'package:whatsapp_chat/controllers/stories_controller.dart';
import 'package:whatsapp_chat/controllers/stories_gallery_controller.dart';
import 'package:whatsapp_chat/models/storie_file_model.dart';
import 'package:whatsapp_chat/repositories/stories_repository.dart';
import 'package:whatsapp_chat/theme.dart';
import 'package:whatsapp_chat/token_usuario.dart';
import 'package:whatsapp_chat/views/story_favorites_view.dart';
import 'package:whatsapp_chat/utils/enhanced_image_loader.dart';
import 'package:whatsapp_chat/utils/debug_utils.dart';

class StoriesView extends StatelessWidget {
  final String? contexto; // Novo parâmetro para filtrar por contexto

  const StoriesView({Key? key, this.contexto}) : super(key: key);

  Widget _buildStoryItem(StorieFileModel item) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: ((Get.width - 56) / 3),
              height: ((Get.width - 56) / 3) * (16 / 9),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item.fileType == StorieFileType.img
                    ? EnhancedImageLoader.buildCachedImage(
                        imageUrl: item.fileUrl!,
                        fit: BoxFit.cover,
                        placeholder: const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error, color: Colors.red),
                              Text('Erro ao carregar',
                                  style: TextStyle(fontSize: 10)),
                            ],
                          ),
                        ),
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          // 🆕 Exibir thumbnail ao invés de vídeo
                          EnhancedImageLoader.buildCachedImage(
                            imageUrl: item.videoThumbnail ?? item.fileUrl!,
                            fit: BoxFit.cover,
                            placeholder: const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: const Center(
                              child: Icon(Icons.videocam, size: 48, color: Colors.white54),
                            ),
                          ),
                          // 🆕 Ícone de play sobreposto
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            Positioned.fill(
              child: Column(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Colors.black54, Colors.transparent],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    height: 38,
                    width: Get.width,
                    child: Center(
                        child: Text(
                            StoriesController.formatarDataParaHorasAtras(
                                item.dataCadastro!.toDate()),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.white))),
                  ),
                ],
              ),
            ),

            // Indicador de contexto
            if (item.contexto != null)
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: item.contexto == 'sinais_isaque'
                        ? Colors.pink
                        : item.contexto == 'sinais_rebeca'
                            ? Colors.blue
                            : Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.contexto == 'sinais_isaque'
                        ? '🤵'
                        : item.contexto == 'sinais_rebeca'
                            ? '👰‍♀️'
                            : item.contexto == 'nosso_proposito'
                                ? '💕'
                                : '💬',
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
          ],
        ),
        Container(
          width: ((Get.width - 96) / 3),
          height: 40,
          margin: const EdgeInsets.only(top: 8),
          child: OutlinedButton(
            onPressed: () => _deleteStory(item),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
            child: const Text('Deletar', style: TextStyle(fontSize: 12)),
          ),
        )
      ],
    );
  }

  // Cor do botão de favoritos baseada no contexto
  Color _getFavoritesButtonColor() {
    switch (contexto) {
      case 'sinais_rebeca':
        return const Color(0xFF38b6ff); // Azul para Sinais Rebeca
      case 'sinais_isaque':
        return const Color(0xFFf76cec); // Rosa para Sinais Isaque
      case 'nosso_proposito':
        return Colors.purple.shade400; // Roxo para Nosso Propósito
      default:
        return Colors.yellow.shade700; // Amarelo para Principal
    }
  }

  // Ícone do botão de favoritos baseado no contexto
  Widget _getFavoritesButtonIcon() {
    if (contexto == 'nosso_proposito') {
      // Ícone metade azul e metade rosa para Nosso Propósito
      return SizedBox(
        width: 24,
        height: 24,
        child: Stack(
          children: [
            // Metade esquerda azul
            Positioned(
              left: 0,
              top: 0,
              child: ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.5,
                  child: Icon(
                    Icons.bookmark,
                    color: const Color(0xFF38b6ff), // Azul
                    size: 24,
                  ),
                ),
              ),
            ),
            // Metade direita rosa
            Positioned(
              right: 0,
              top: 0,
              child: ClipRect(
                child: Align(
                  alignment: Alignment.centerRight,
                  widthFactor: 0.5,
                  child: Icon(
                    Icons.bookmark,
                    color: const Color(0xFFf76cec), // Rosa
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Ícone normal para outros contextos
      return const Icon(Icons.bookmark, color: Colors.white);
    }
  }

  // Verifica se o usuário é admin
  bool _isAdmin() {
    return false; // Certificação removida temporariamente
  }

  void _deleteStory(StorieFileModel item) {
    Get.defaultDialog(
      title: 'Confirmar exclusão',
      content: const Text('Tem certeza que deseja deletar este story?'),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            Get.back(); // Fechar dialog

            try {
              await StoriesRepository.delete(id: item.id!, contexto: contexto);
              Get.rawSnackbar(
                message: 'Story deletado com sucesso!',
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              );
            } catch (e) {
              Get.rawSnackbar(
                message: 'Erro ao deletar story: $e',
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              );
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Deletar', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      // Garantir que o controller está registrado
      if (!Get.isRegistered<StoriesGalleryController>()) {
        Get.put(StoriesGalleryController());
      }

      String titulo = contexto == 'sinais_isaque'
          ? 'Stories - Sinais de Meu Isaque'
          : contexto == 'sinais_rebeca'
              ? 'Stories - Sinais de Minha Rebeca'
              : contexto == 'nosso_proposito'
                  ? 'Stories - Nosso Propósito'
                  : 'Stories';

      return Scaffold(
        appBar: AppBar(
          title: Text(titulo),
          backgroundColor: AppTheme.materialColor,
          leading: IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back, color: Colors.black),
          ),
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Botão de favoritos
            FloatingActionButton(
              heroTag: "favorites",
              onPressed: () {
                final contextoAtual = contexto ?? 'principal';
                print(
                    '🟡 BOTÃO AMARELO: Abrindo favoritos do contexto: $contextoAtual');
                Get.to(() => StoryFavoritesView(contexto: contextoAtual));
              },
              backgroundColor: _getFavoritesButtonColor(),
              child: _getFavoritesButtonIcon(),
            ),
            const SizedBox(height: 16),
            // Botão de adicionar
            FloatingActionButton(
              heroTag: "add",
              onPressed: () async {
                try {
                  await StoriesController.getFile(contexto: contexto);
                } catch (e) {
                  print('Erro ao abrir seletor de arquivos: $e');
                  Get.rawSnackbar(
                    message: 'Erro ao abrir galeria: $e',
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 3),
                  );
                }
              },
              backgroundColor: AppTheme.materialColor,
              child: const Icon(Icons.add, color: Colors.black),
            ),
          ],
        ),
        body: GetX<StoriesGalleryController>(builder: (controller) {
          // O refreshTrigger força rebuild quando há mudanças
          controller.refreshTrigger;

          return StreamBuilder<List<StorieFileModel>>(
              stream: contexto != null
                  ? StoriesRepository.getAllByContext(contexto!)
                  : StoriesRepository.getAll(),
              builder: (context, snapshot) {
                // Estado de loading
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Carregando stories...'),
                      ],
                    ),
                  );
                }

                // Estado de erro
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Erro ao carregar stories: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            // Forçar rebuild do stream
                            (context as Element).markNeedsBuild();
                          },
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  );
                }

                // Verificar se há dados
                if (!snapshot.hasData) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Carregando...'),
                      ],
                    ),
                  );
                }

                List<StorieFileModel> all = snapshot.data!;

                // Ordenar por data (mais recentes primeiro)
                all.sort((a, b) => b.dataCadastro!.compareTo(a.dataCadastro!));

                // Estado vazio
                if (all.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.photo_library_outlined,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          contexto == 'sinais_isaque'
                              ? 'Nenhum story encontrado para "Sinais de Meu Isaque"'
                              : 'Nenhum story encontrado',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Clique no botão + para adicionar o primeiro story',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                // Lista de stories
                return RefreshIndicator(
                  onRefresh: () async {
                    // Forçar atualização do stream
                    await Future.delayed(const Duration(milliseconds: 500));
                    (context as Element).markNeedsBuild();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header com informações
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${all.length} story${all.length != 1 ? 's' : ''} encontrado${all.length != 1 ? 's' : ''}',
                                  style: TextStyle(color: Colors.blue.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Grid de stories
                        Wrap(
                          spacing: 12,
                          runSpacing: 16,
                          children:
                              all.map((item) => _buildStoryItem(item)).toList(),
                        ),
                      ],
                    ),
                  ),
                );
              });
        }),
      );
    } catch (e) {
      safePrint('Erro na tela de stories: $e');
      return Scaffold(
        appBar: AppBar(
          title: const Text('Stories'),
          leading: IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Erro ao carregar tela de stories'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Get.back(),
                child: const Text('Voltar'),
              ),
            ],
          ),
        ),
      );
    }
  }
}
