import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:emoji_regex/emoji_regex.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🙏 NOVO: Para buscar story
import '../models/usuario_model.dart';
import '../models/storie_file_model.dart'; // 🙏 NOVO: Para converter story
import '../repositories/stories_repository.dart'; // 🔧 NOVO: Para obter nome da coleção
import '../views/enhanced_stories_viewer_view.dart'; // 🙏 NOVO: Para abrir viewer
import 'container_chat_item_component.dart';
import '/models/chat_model.dart';

class ChatTextComponent extends StatelessWidget {
  final ChatModel item;
  final bool showArrow;
  final UsuarioModel usuarioModel;
  final Color textColor;

  const ChatTextComponent(
      {super.key,
      required this.item,
      required this.showArrow,
      required this.usuarioModel,
      required this.textColor});

  @override
  Widget build(BuildContext context) {
    return ContainerChatItemComponent(
      item: item,
      userName: usuarioModel.nome!,
      isAdmin: usuarioModel.isAdmin!,
      username: usuarioModel.username,
      userSexo: usuarioModel.sexo, // Passar o sexo do usuário
      showArrow: showArrow,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🙏 NOVO: Preview do story salvo (Resposta ao Pai)
            item.replyToStory == null
                ? const SizedBox()
                : Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => _showSavedStoryViewer(item.replyToStory!),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.shade900.withOpacity(0.3),
                            border: Border.all(
                              color: Colors.blue.shade300.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: SizedBox(
                            width: Get.width * 0.7,
                            child: Row(
                              children: [
                                // Thumbnail do story
                                if (item.replyToStory!['storyUrl'] != null)
                                  Stack(
                                    children: [
                                      Image.network(
                                        item.replyToStory!['storyUrl'],
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            Container(
                                          width: 70,
                                          height: 70,
                                          color: Colors.grey.shade800,
                                          child: const Icon(
                                            Icons.image,
                                            color: Colors.white54,
                                          ),
                                        ),
                                      ),
                                      // Ícone de play se for vídeo
                                      if (item.replyToStory!['storyType'] == 'video')
                                        Positioned.fill(
                                          child: Center(
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.black54,
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: const Icon(
                                                Icons.play_arrow,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.bookmark,
                                              size: 14,
                                              color: Colors.blue.shade300,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Story Salvo',
                                              style: TextStyle(
                                                color: Colors.blue.shade300,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Toque para rever a mensagem do Pai',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.7),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                    Icons.visibility,
                                    color: Colors.blue.shade300,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
            item.linkDescricaoModel == null
                ? const SizedBox()
                : Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => launchUrl(
                          Uri.parse(item.linkDescricaoModel!.link!),
                          mode: LaunchMode.externalApplication),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white10,
                            ),
                            child: SizedBox(
                              width: Get.width * 0.7,
                              child: Row(
                                children: [
                                  item.linkDescricaoModel!.imgUrl == null ||
                                          item.linkDescricaoModel!.imgUrl
                                                  ?.isEmpty ==
                                              true
                                      ? const SizedBox()
                                      : Image.network(
                                          item.linkDescricaoModel!.imgUrl!,
                                          width: 70,
                                          height: 70,
                                          fit: BoxFit.cover),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(item.linkDescricaoModel!.titulo,
                                            style: const TextStyle(
                                                color: Colors.white)),
                                        const SizedBox(height: 4),
                                        Text(item.linkDescricaoModel!.descricao,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ),
                    ),
                  ),
            RichText(
                text: TextSpan(
                    style: TextStyle(color: textColor, fontSize: 15),
                    children: [
                  for (var i = 0; i < item.text!.split(' ').length; i++)
                    TextSpan(children: [
                      TextSpan(
                          children:
                              splitStringWithLinks(item.text!.split(' ')[i])
                                  .map((e) => TextSpan(children: [
                                        TextSpan(
                                          style: emojiRegex()
                                                  .allMatches(e)
                                                  .isNotEmpty
                                              ? GoogleFonts.notoColorEmoji(
                                                  color: e.isURL
                                                      ? Colors.blue
                                                      : textColor)
                                              : TextStyle(
                                                  color: e.isURL
                                                      ? Colors.blue
                                                      : textColor),
                                          text: e,
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              if (e.isURL) {
                                                launchUrl(Uri.parse(e),
                                                    mode: LaunchMode
                                                        .externalApplication);
                                              }
                                            },
                                        ),
                                        const TextSpan(text: ' ')
                                      ]))
                                  .toList())
                    ])
                ]))
          ],
        ),
      ),
    );
  }

  List<String> splitStringWithLinks(String text) {
    final RegExp linkRegExp = RegExp(
        r'http[s]?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\\(\\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+');
    final Iterable<Match> matches = linkRegExp.allMatches(text);

    int currentIndex = 0;
    final List<String> parts = [];
    for (Match match in matches) {
      if (currentIndex < match.start) {
        parts.add(text.substring(currentIndex, match.start));
      }
      parts.add(match.group(0)!);
      currentIndex = match.end;
    }

    if (currentIndex < text.length) {
      parts.add(text.substring(currentIndex));
    }

    return parts;
  }

  // 🙏 NOVO: Mostra visualizador completo do story salvo
  void _showSavedStoryViewer(Map<String, dynamic> storyData) async {
    final storyId = storyData['storyId'] as String?;
    final contexto = storyData['contexto'] as String? ?? 'principal'; // 🔧 NOVO: Pegar contexto
    
    if (storyId == null) {
      Get.rawSnackbar(
        message: 'Story não encontrado',
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    print('📖 STORY SALVO: Buscando story ID: $storyId');
    print('📖 STORY SALVO: Contexto: $contexto');

    // Mostrar loading
    Get.dialog(
      const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
      barrierDismissible: false,
    );

    try {
      // 🔧 NOVO: Obter nome da coleção correta baseado no contexto
      final collectionName = StoriesRepository.getCollectionNameFromContext(contexto);
      print('📖 STORY SALVO: Buscando na coleção: $collectionName');

      // Buscar o story completo no Firestore NA COLEÇÃO CORRETA
      final storyDoc = await FirebaseFirestore.instance
          .collection(collectionName) // 🔧 CORRIGIDO: Usa coleção correta
          .doc(storyId)
          .get();

      // Fechar loading
      Get.back();

      if (!storyDoc.exists) {
        print('❌ STORY SALVO: Story não encontrado no Firestore');
        print('❌ STORY SALVO: Coleção: $collectionName, ID: $storyId');
        Get.rawSnackbar(
          message: 'Story não está mais disponível',
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        );
        return;
      }

      // 1. VERIFICAR SE O ID EXISTE
      print('🔍 DEBUG: storyDoc.id = "${storyDoc.id}"');
      print('🔍 DEBUG: storyDoc.id is null? ${storyDoc.id == null}');
      print('🔍 DEBUG: storyDoc.id is empty? ${storyDoc.id.isEmpty}');

      // 2. PEGAR OS DADOS
      final storyData = storyDoc.data()! as Map<String, dynamic>;
      print('🔍 DEBUG: storyData keys = ${storyData.keys.toList()}');
      print('🔍 DEBUG: storyData tem "id"? ${storyData.containsKey("id")}');

      // 3. CRIAR MAP COM ID (MÉTODO ALTERNATIVO)
      final storyDataWithId = <String, dynamic>{
        ...storyData,
        'id': storyDoc.id,
      };

      // 4. VERIFICAR SE FOI INJETADO
      print('🔍 DEBUG: storyDataWithId tem "id"? ${storyDataWithId.containsKey("id")}');
      print('🔍 DEBUG: storyDataWithId["id"] = "${storyDataWithId["id"]}"');

      // 5. CRIAR O MODELO
      final story = StorieFileModel.fromJson(storyDataWithId);

      // 6. VERIFICAR O MODELO
      print('🔍 DEBUG: story.id = "${story.id}"');
      print('🔍 DEBUG: story.id is null? ${story.id == null}');

      // Log final
      print('📍 STORY SALVO: ID: ${story.id}');
      print('📍 STORY SALVO: Contexto: ${story.contexto}');

      // Abrir o EnhancedStoriesViewerView com o story completo
      Get.to(
        () => EnhancedStoriesViewerView(
          contexto: story.contexto ?? 'principal',
          userSexo: usuarioModel.sexo,
          initialStories: [story], // Passa apenas este story
          initialIndex: 0,
        ),
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 300),
      );
    } catch (e) {
      // Fechar loading se ainda estiver aberto
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      
      print('❌ STORY SALVO: Erro ao buscar story: $e');
      Get.rawSnackbar(
        message: 'Erro ao carregar story',
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      );
    }
  }
}
