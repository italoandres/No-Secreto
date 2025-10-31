import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:whatsapp_chat/utils/safe_share_handler.dart';
import 'package:whatsapp_chat/components/audio_recoder_component.dart';
import 'package:whatsapp_chat/components/chat_audio_component.dart';
import 'package:whatsapp_chat/components/chat_img_component.dart';
import 'package:whatsapp_chat/components/chat_outro_formato_component.dart';
import 'package:whatsapp_chat/components/chat_text_component.dart';
import 'package:whatsapp_chat/components/chat_video_component.dart';
import 'package:whatsapp_chat/controllers/audio_controller.dart';
import 'package:whatsapp_chat/controllers/chat_controller.dart';
import 'package:whatsapp_chat/controllers/home_controller.dart';
import 'package:whatsapp_chat/locale/language.dart';
import 'package:whatsapp_chat/models/chat_model.dart';
import 'package:whatsapp_chat/models/emoji_model.dart';
import 'package:whatsapp_chat/models/usuario_model.dart';
import 'package:whatsapp_chat/repositories/chat_repository.dart';
import 'package:whatsapp_chat/repositories/usuario_repository.dart';
import 'package:whatsapp_chat/theme.dart';
import 'package:whatsapp_chat/views/login_view.dart';
import 'package:whatsapp_chat/views/select_language_view.dart';
import 'package:whatsapp_chat/views/stories_view.dart';
import 'package:whatsapp_chat/views/stories_viewer_view.dart';
import 'package:whatsapp_chat/controllers/stories_gallery_controller.dart';
import 'package:whatsapp_chat/models/storie_file_model.dart';
import 'package:whatsapp_chat/repositories/stories_repository.dart';

import '../components/editar_capa_component.dart';
import 'package:whatsapp_chat/components/notification_icon_component.dart';
import 'package:whatsapp_chat/views/community_info_view.dart';
import 'package:whatsapp_chat/views/story_favorites_view.dart';
import 'package:whatsapp_chat/views/username_settings_view.dart';
import 'package:whatsapp_chat/views/enhanced_stories_viewer_view.dart';
import 'package:whatsapp_chat/token_usuario.dart';
import 'package:whatsapp_chat/models/storie_visto_model.dart';
import 'package:whatsapp_chat/views/nosso_proposito_view.dart';
import 'package:whatsapp_chat/views/profile_completion_view.dart';
import 'package:whatsapp_chat/components/vitrine_invite_notification_component.dart';

class SinaisIsaqueView extends StatefulWidget {
  const SinaisIsaqueView({super.key});

  @override
  State<SinaisIsaqueView> createState() => _SinaisIsaqueViewState();
}

class _SinaisIsaqueViewState extends State<SinaisIsaqueView> {
  int totMsgs = 0;
  Map<String, dynamic>? replyToStoryData; // 🙏 NOVO: Dados do story para responder ao Pai
  
  @override
  void initState() {
    super.initState();
    initPlatformState();
    _checkReplyToStory(); // 🙏 NOVO: Verificar se veio de "Responder ao Pai"
  }

  // 🙏 NOVO: Verifica se há dados de story para responder
  void _checkReplyToStory() {
    final arguments = Get.arguments;
    if (arguments != null && arguments is Map<String, dynamic>) {
      if (arguments.containsKey('replyToStory')) {
        setState(() {
          replyToStoryData = arguments['replyToStory'] as Map<String, dynamic>;
        });
        print('🙏 SINAIS ISAQUE: Recebeu dados de reply to story: $replyToStoryData');
      }
    }
  }

  Future<void> initPlatformState() async {
    await SafeShareHandler.initializeSafely(
      onImageReceived: (file, extension) {
        ChatRepository.addImgFile(msg: '', img: file, extensao: extension);
      },
      onVideoReceived: (file) {
        ChatRepository.addVideo(msg: '', video: file);
      },
      onFileReceived: (file, extension, fileName) {
        ChatRepository.addFile(
            file: file, extensao: extension, fileName: fileName);
      },
    );
    return;
  }

  @override
  Widget build(BuildContext context) {
    double appBarHeight = (Get.width * 339 / 1289);

    return Scaffold(
      body: StreamBuilder<UsuarioModel?>(
          stream: UsuarioRepository.getUser(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            UsuarioModel user = snapshot.data!;
            return Scaffold(
              appBar: AppBar(
                toolbarHeight: 0,
              ),
              body: Stack(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Stack(
                        children: [
                          // Capa original mantida
                          Image.asset('lib/assets/img/capa.jpg',
                              width: Get.width),
                          Positioned.fill(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Lado esquerdo - Notificações + Admin + Comunidade
                                Row(
                                  children: [
                                    // Ícone de notificações
                                    Container(
                                      width: 50,
                                      height: 50,
                                      margin: const EdgeInsets.only(left: 16),
                                      decoration: BoxDecoration(
                                        color: Colors.white38,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const NotificationIconComponent(
                                          contexto: 'sinais_isaque'),
                                    ),

                                    // Menu admin (apenas para admins)
                                    if (user.isAdmin == true)
                                      Container(
                                        width: 50,
                                        height: 50,
                                        margin: const EdgeInsets.only(left: 8),
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                              padding: const EdgeInsets.all(0),
                                              backgroundColor: Colors.white38),
                                          onPressed: () => showAdminOpts(user),
                                          child: const Icon(
                                              Icons.admin_panel_settings,
                                              color: Colors.white),
                                        ),
                                      ),

                                    // Ícone da comunidade
                                    Container(
                                      width: 50,
                                      height: 50,
                                      margin: const EdgeInsets.only(left: 8),
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.all(0),
                                            backgroundColor: Colors.white38),
                                        onPressed: () => Get.to(
                                            () => const CommunityInfoView()),
                                        child: Icon(
                                          Icons.people,
                                          color: Colors.amber.shade700,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                // Lado direito - Voltar + Nosso Propósito
                                Row(
                                  children: [
                                    // Botão de voltar
                                    Container(
                                      width: 50,
                                      height: 50,
                                      margin: const EdgeInsets.only(right: 8),
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.all(0),
                                            backgroundColor: Colors.white38),
                                        onPressed: () => Get.back(),
                                        child: const Icon(Icons.arrow_back,
                                            color: Colors.white),
                                      ),
                                    ),
                                    // Acesso ao chat Nosso Propósito
                                    Container(
                                      width: 50,
                                      height: 50,
                                      margin: const EdgeInsets.only(right: 16),
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.all(0),
                                            backgroundColor: Colors.white38),
                                        onPressed: () => Get.to(
                                            () => const NossoPropositoView()),
                                        child: const Text('👩‍❤️‍👨',
                                            style: TextStyle(fontSize: 24)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                      // Componente de convites da vitrine
                      const VitrineInviteNotificationComponent(),
                      Expanded(
                        child: Stack(
                          children: [
                            user.imgBgUrl == null
                                ? Opacity(
                                    opacity: 0.3,
                                    child: Image.asset(
                                        'lib/assets/img/bg_wallpaper.jpg',
                                        width: Get.width,
                                        height: Get.height,
                                        fit: BoxFit.cover))
                                : CachedNetworkImage(
                                    imageUrl: user.imgBgUrl!,
                                    width: Get.width,
                                    height: Get.height,
                                    fit: BoxFit.cover),
                            Stack(
                              children: [
                                StreamBuilder<List<ChatModel>>(
                                    stream: ChatRepository.getAllSinaisIsaque(),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) {
                                        return const Center(
                                            child: CircularProgressIndicator());
                                      }

                                      List<ChatModel> chat = snapshot.data!;
                                      chat.sort((a, b) => b.dataCadastro!
                                          .compareTo(a.dataCadastro!));
                                      List<DateTime> datas = [];

                                      totMsgs = chat.length;

                                      for (var element in chat) {
                                        DateTime d =
                                            element.dataCadastro!.toDate();
                                        DateTime d2 =
                                            DateTime(d.year, d.month, d.day);
                                        if (!datas.contains(d2)) {
                                          datas.add(d2);
                                        }
                                      }

                                      List<Widget> widgets = [];

                                      for (var data in datas) {
                                        String stringData = '';
                                        final diferenca =
                                            DateTime.now().difference(data);
                                        if (diferenca.inDays < 1) {
                                          stringData = AppLanguage.lang('hoje');
                                        } else if (diferenca.inDays <= 2) {
                                          stringData =
                                              AppLanguage.lang('ontem');
                                        } else {
                                          stringData = DateFormat('dd/MM/y')
                                              .format(data);
                                        }
                                        for (var chatItem in chat) {
                                          if (DateFormat('dd/MM/y')
                                                  .format(data) ==
                                              DateFormat('dd/MM/y').format(
                                                  chatItem.dataCadastro!
                                                      .toDate())) {
                                            if (chatItem.tipo ==
                                                ChatType.text) {
                                              widgets.add(ChatTextComponent(
                                                item: chatItem,
                                                usuarioModel: user,
                                                showArrow: true,
                                                textColor: chatItem
                                                            .orginemAdmin ==
                                                        true
                                                    ? const Color(0xFFffb400)
                                                    : Colors.white,
                                              ));
                                            } else if (chatItem.tipo ==
                                                ChatType.img) {
                                              widgets.add(ChatImgComponent(
                                                  item: chatItem,
                                                  usuarioModel: user,
                                                  showArrow: true));
                                            } else if (chatItem.tipo ==
                                                ChatType.video) {
                                              widgets.add(ChatVideoComponent(
                                                  item: chatItem,
                                                  usuarioModel: user,
                                                  showArrow: true));
                                            } else if ([
                                              'mp3',
                                              'm4a',
                                              'ogg',
                                              'opus'
                                            ].contains(
                                                chatItem.fileExtension)) {
                                              widgets.add(ChatAudioComponent(
                                                  item: chatItem,
                                                  usuarioModel: user,
                                                  showArrow: true));
                                            } else {
                                              widgets.add(
                                                  ChatOutroFormatoComponent(
                                                      item: chatItem,
                                                      usuarioModel: user,
                                                      showArrow: true));
                                            }
                                          }
                                        }
                                        widgets.add(
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            7.5)),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 5),
                                                margin: const EdgeInsets.only(
                                                    bottom: 12),
                                                child: Text(
                                                    stringData.toUpperCase()),
                                              ),
                                            ],
                                          ),
                                        );
                                      }

                                      if (datas.isEmpty) {
                                        return Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFfeeecc),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          7.5)),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                              margin: EdgeInsets.only(
                                                  left: 16,
                                                  right: 16,
                                                  bottom: 16,
                                                  top: appBarHeight * 0.6),
                                              child: Text(
                                                  AppLanguage.lang(
                                                      'send_first_msg'),
                                                  style: TextStyle(
                                                      color: Colors
                                                          .grey.shade700)),
                                            ),
                                          ],
                                        );
                                      }

                                      return ListView.builder(
                                          reverse: true,
                                          itemCount: widgets.length,
                                          padding: EdgeInsets.only(
                                              left: 0,
                                              right: 0,
                                              bottom: 16 +
                                                  60 +
                                                  MediaQuery.of(context)
                                                      .padding
                                                      .bottom,
                                              top: appBarHeight * 0.2),
                                          itemBuilder: (BuildContext context,
                                                  int index) =>
                                              widgets[index]);
                                    }),
                                Positioned(
                                  bottom: 8 +
                                      60 +
                                      MediaQuery.of(context).padding.bottom,
                                  right: 16,
                                  child: Obx(() =>
                                      ChatController.showModalFiles.value ==
                                              false
                                          ? const SizedBox()
                                          : _files()),
                                ),
                                Positioned(
                                  bottom: 8 +
                                      60 +
                                      MediaQuery.of(context).padding.bottom,
                                  right: 82,
                                  child: Obx(() =>
                                      ChatController.showModalCamera.value ==
                                              false
                                          ? const SizedBox()
                                          : _camera()),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Imagem sinais_isaque.png por cima de tudo
                  Positioned(
                    top: (Get.width * 339 / 1289) + 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: Get.width * 0.8,
                        height: 60,
                        child: Image.asset(
                          'lib/assets/img/sinais_isaque.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  // Círculo do perfil com sistema moderno de stories (rosa para Sinais de Isaque)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      StreamBuilder<List<StorieVistoModel>>(
                          stream: StoriesRepository.getStoreVisto(),
                          builder: (context, snapshot) {
                            Widget child = Container(
                              width: Get.width * 339 / 1289,
                              height: Get.width * 339 / 1289,
                              margin: EdgeInsets.only(
                                  top: (Get.width * 339 / 1289) * 0.15),
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(Get.width),
                              ),
                              padding: const EdgeInsets.all(3),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius:
                                      BorderRadius.circular(Get.width),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(Get.width),
                                  child: Image.asset(
                                      'lib/assets/img/logo_2.png',
                                      width: Get.width),
                                ),
                              ),
                            );

                            List<StorieVistoModel> vistos = [];
                            List<String> vistosIds = [];
                            if (snapshot.hasData) {
                              vistos = snapshot.data!;
                              vistosIds =
                                  vistos.map((e) => e.idStore!).toList();
                            }

                            print(
                                '🚨 SINAIS ISAQUE: Chamando getAllSinaisIsaque()');
                            return StreamBuilder<List<StorieFileModel>>(
                                stream: StoriesRepository
                                    .getAllSinaisIsaque(), // FORÇANDO MÉTODO ESPECÍFICO
                                builder: (context, snapshot) {
                                  print(
                                      '🚨 SINAIS ISAQUE: StreamBuilder executado - hasData: ${snapshot.hasData}');
                                  if (snapshot.hasData) {
                                    List<StorieFileModel> listStories = [];
                                    for (var element in snapshot.data!) {
                                      if (DateTime.now()
                                              .difference(element.dataCadastro!
                                                  .toDate())
                                              .inMinutes <=
                                          (24 * 60)) {
                                        listStories.add(element);
                                      }
                                    }

                                    // Filtrar por idioma e público-alvo
                                    listStories.removeWhere((element) =>
                                        element.idioma != null &&
                                        element.idioma !=
                                            TokenUsuario().idioma);
                                    listStories.sort((a, b) => a.dataCadastro!
                                        .compareTo(b.dataCadastro!));

                                    if (listStories.isNotEmpty) {
                                      child = InkWell(
                                        borderRadius:
                                            BorderRadius.circular(Get.width),
                                        onTap: () {
                                          // Usar EnhancedStoriesViewerView para funcionalidade TikTok
                                          Get.to(() =>
                                              const EnhancedStoriesViewerView(
                                                contexto: 'sinais_isaque',
                                                userSexo: UserSexo
                                                    .feminino, // Apenas usuários femininos
                                              ));
                                        },
                                        child: Builder(builder: (context) {
                                          // Filtrar stories válidos (24h, idioma, público-alvo)
                                          final now = DateTime.now();
                                          final twentyFourHoursAgo =
                                              now.subtract(
                                                  const Duration(hours: 24));

                                          List<StorieFileModel> validStories =
                                              listStories.where((story) {
                                            // Verificar se está dentro de 24h
                                            final storyDate =
                                                story.dataCadastro?.toDate();
                                            if (storyDate == null ||
                                                storyDate.isBefore(
                                                    twentyFourHoursAgo)) {
                                              return false;
                                            }

                                            // Verificar idioma
                                            if (story.idioma != null &&
                                                story.idioma !=
                                                    TokenUsuario().idioma) {
                                              return false;
                                            }

                                            // Verificar público-alvo (apenas feminino para Sinais de Isaque)
                                            if (story.publicoAlvo != null &&
                                                story.publicoAlvo !=
                                                    UserSexo.feminino) {
                                              return false;
                                            }

                                            return true;
                                          }).toList();

                                          // Verificar quais stories válidos não foram vistos
                                          List<StorieFileModel>
                                              listStoriesNaoVisto = validStories
                                                  .where((element) => !vistosIds
                                                      .contains(element.id))
                                                  .toList();

                                          // Debug para verificar stories não vistos
                                          print(
                                              'DEBUG SINAIS ISAQUE: Stories totais: ${listStories.length}');
                                          print(
                                              'DEBUG SINAIS ISAQUE: Stories válidos: ${validStories.length}');
                                          print(
                                              'DEBUG SINAIS ISAQUE: Stories vistos: ${vistosIds.length}');
                                          print(
                                              'DEBUG SINAIS ISAQUE: Stories não vistos: ${listStoriesNaoVisto.length}');
                                          print(
                                              'DEBUG SINAIS ISAQUE: Círculo rosa: ${listStoriesNaoVisto.isNotEmpty}');

                                          return Container(
                                            width: Get.width * 339 / 1289,
                                            height: Get.width * 339 / 1289,
                                            margin: EdgeInsets.only(
                                                top: (Get.width * 339 / 1289) *
                                                    0.15),
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        Get.width),
                                                gradient: listStoriesNaoVisto
                                                        .isEmpty
                                                    ? null
                                                    : const LinearGradient(
                                                        colors: [
                                                            Color(
                                                                0xFFf76cec), // Rosa para Sinais de Isaque
                                                            Color(0xFFf76cec),
                                                          ],
                                                        end: Alignment.topRight,
                                                        begin: Alignment
                                                            .bottomLeft)),
                                            padding: const EdgeInsets.all(3),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.black,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        Get.width),
                                              ),
                                              padding: const EdgeInsets.all(4),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        Get.width),
                                                child: Image.asset(
                                                    'lib/assets/img/logo_2.png',
                                                    width: Get.width),
                                              ),
                                            ),
                                          );
                                        }),
                                      );
                                    }
                                  }
                                  return child;
                                });
                          }),
                    ],
                  ),
                  // Resto da interface (input de mensagem, etc.)
                  Positioned.fill(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // 🙏 NOVO: Widget de pré-publicação "Responder ao Pai"
                        if (replyToStoryData != null)
                          _buildReplyToStoryPreview(),
                        Obx(() =>
                            ChatController.linkDescricaoModel.value == null
                                ? const SizedBox()
                                : Container(
                                    margin: const EdgeInsets.only(
                                        left: 16, right: 16, bottom: 12),
                                    child: Material(
                                      borderRadius: BorderRadius.circular(16),
                                      color: Colors.white,
                                      elevation: 3,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Row(
                                          children: [
                                            ChatController.linkDescricaoModel
                                                            .value!.imgUrl ==
                                                        null ||
                                                    ChatController
                                                            .linkDescricaoModel
                                                            .value!
                                                            .imgUrl
                                                            ?.isEmpty ==
                                                        true
                                                ? const SizedBox()
                                                : Image.network(
                                                    ChatController
                                                        .linkDescricaoModel
                                                        .value!
                                                        .imgUrl!,
                                                    width: 70,
                                                    height: 70,
                                                    fit: BoxFit.cover),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                      ChatController
                                                          .linkDescricaoModel
                                                          .value!
                                                          .titulo,
                                                      style: const TextStyle(
                                                          color: Colors.black)),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                      ChatController
                                                          .linkDescricaoModel
                                                          .value!
                                                          .descricao,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                          color: Colors.grey)),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () {
                                                ChatController
                                                    .linkDescricaoModel
                                                    .value = null;
                                                ChatController
                                                    .linkDescricaoModel
                                                    .refresh();
                                              },
                                              icon: const Icon(Icons.close),
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  )),
                        Padding(
                          padding: EdgeInsets.only(
                              left: 16,
                              right: 16,
                              bottom:
                                  8 + MediaQuery.of(context).padding.bottom),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Material(
                                  borderRadius: BorderRadius.circular(100),
                                  elevation: 3,
                                  child: Container(
                                    constraints:
                                        const BoxConstraints(minHeight: 48),
                                    child: Obx(() => AudioController
                                                .isGravandoAudio.value ==
                                            true
                                        ? const AudioRecoderComponent()
                                        : Row(
                                            children: [
                                              SizedBox(
                                                width: 40,
                                                child: TextButton(
                                                  style: TextButton.styleFrom(
                                                    shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                                    Get.width)),
                                                  ),
                                                  onPressed: () {
                                                    ChatController.group.value =
                                                        ChatController
                                                            .emujiGroup
                                                            .first
                                                            .en!;
                                                    ChatController
                                                            .showEmoji.value =
                                                        !ChatController
                                                            .showEmoji.value;
                                                  },
                                                  child: Obx(() => Icon(
                                                      ChatController.showEmoji
                                                                  .value ==
                                                              false
                                                          ? Icons
                                                              .emoji_emotions_outlined
                                                          : Icons.keyboard,
                                                      color: Colors.grey)),
                                                ),
                                              ),
                                              Expanded(
                                                child: TextField(
                                                  controller: ChatController
                                                      .msgController,
                                                  scrollController:
                                                      ChatController
                                                          .msgScrollController,
                                                  style: const TextStyle(
                                                      color: Colors.black),
                                                  decoration: InputDecoration(
                                                    enabledBorder:
                                                        InputBorder.none,
                                                    border: InputBorder.none,
                                                    focusedBorder:
                                                        InputBorder.none,
                                                    filled: true,
                                                    fillColor:
                                                        Colors.transparent,
                                                    hintText: AppLanguage.lang(
                                                        'digite_aqui'),
                                                  ),
                                                  maxLines: 3,
                                                  minLines: 1,
                                                  onChanged:
                                                      (String? text) async {
                                                    ChatController.showBtnAudio
                                                            .value =
                                                        text!.trim().isEmpty;

                                                    if (text
                                                            .split('\n')
                                                            .length >
                                                        1) {
                                                      ChatController
                                                          .sendMsgSinaisIsaque(
                                                              isFirst:
                                                                  totMsgs == 0);
                                                      return;
                                                    }

                                                    String? url = ChatController
                                                        .extractURL(text);
                                                    if (url != null) {
                                                      ChatController
                                                              .linkDescricaoModel
                                                              .value =
                                                          await ChatRepository
                                                              .fetchDescription(
                                                                  url);
                                                      ChatController
                                                          .linkDescricaoModel
                                                          .refresh();
                                                    }
                                                  },
                                                ),
                                              ),
                                              SizedBox(
                                                width: 40,
                                                child: Obx(() => TextButton(
                                                      style: TextButton.styleFrom(
                                                          shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(Get
                                                                          .width)),
                                                          backgroundColor: ChatController
                                                                      .showModalCamera
                                                                      .value ==
                                                                  true
                                                              ? AppTheme
                                                                  .materialColor
                                                                  .shade100
                                                              : Colors
                                                                  .transparent),
                                                      onPressed: () {
                                                        ChatController
                                                            .showModalFiles
                                                            .value = false;
                                                        ChatController
                                                                .showModalCamera
                                                                .value =
                                                            !ChatController
                                                                .showModalCamera
                                                                .value;
                                                      },
                                                      child: const Icon(
                                                          Icons
                                                              .camera_alt_outlined,
                                                          color: Colors.grey),
                                                    )),
                                              ),
                                              SizedBox(
                                                width: 40,
                                                child: Obx(() => TextButton(
                                                      style: TextButton.styleFrom(
                                                          shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(Get
                                                                          .width)),
                                                          backgroundColor: ChatController
                                                                      .showModalFiles
                                                                      .value ==
                                                                  true
                                                              ? AppTheme
                                                                  .materialColor
                                                                  .shade100
                                                              : Colors
                                                                  .transparent),
                                                      onPressed: () {
                                                        ChatController
                                                            .showModalCamera
                                                            .value = false;
                                                        ChatController
                                                                .showModalFiles
                                                                .value =
                                                            !ChatController
                                                                .showModalFiles
                                                                .value;
                                                      },
                                                      child: const Icon(
                                                          Icons.attach_file,
                                                          color: Colors.grey),
                                                    )),
                                              ),
                                            ],
                                          )),
                                  ),
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(left: 16),
                                child: InkWell(
                                    onTap: () {
                                      //AudioController.start();
                                      if (ChatController.showBtnAudio.value ==
                                          false) {
                                        ChatController.sendMsgSinaisIsaque(
                                            isFirst: totMsgs == 0);
                                      } else {
                                        if (AudioController
                                                .isGravandoAudio.value ==
                                            false) {
                                          AudioController
                                              .isGravandoAudio.value = true;
                                        } else {
                                          AudioController
                                              .isGravandoAudio.value = false;
                                          AudioController.stop();
                                        }
                                      }
                                    },
                                    child: Material(
                                      color: const Color(
                                          0xFFf76cec), // Rosa específico do Sinais Isaque (fundo do botão)
                                      borderRadius: BorderRadius.circular(100),
                                      elevation: 3,
                                      child: SizedBox(
                                        width: 52,
                                        height: 52,
                                        child: Obx(() => Icon(
                                              ChatController
                                                          .showBtnAudio.value ==
                                                      false
                                                  ? Icons.send
                                                  : (AudioController
                                                              .isGravandoAudio
                                                              .value ==
                                                          true
                                                      ? Icons.stop
                                                      : Icons.mic_rounded),
                                              color: Colors
                                                  .white, // Ícone branco para contrastar com o fundo rosa
                                            )),
                                      ),
                                    )),
                              )
                            ],
                          ),
                        ),
                        Obx(() => ChatController.showEmoji.value == false
                            ? const SizedBox()
                            : _emoji()),
                      ],
                    ),
                  ),
                  Positioned(
                      bottom: 0,
                      child: Obx(
                        () => ChatController.idItensToTrash.isEmpty
                            ? const SizedBox()
                            : Container(
                                decoration:
                                    const BoxDecoration(color: Colors.white),
                                width: Get.width,
                                height: 62,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.delete_outline),
                                        const SizedBox(width: 6),
                                        Text(
                                            '${AppLanguage.lang('deletar')} ${ChatController.idItensToTrash.length == 1 ? '1 ${AppLanguage.lang('msg')}' : '${ChatController.idItensToTrash.length} ${AppLanguage.lang('msgs')}'}'),
                                      ],
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        ChatRepository.deletarItens(
                                            itens: ChatController.idItensToTrash
                                                .map((e) => '$e')
                                                .toList());
                                        ChatController.idItensToTrash.clear();
                                      },
                                      child: Text(AppLanguage.lang('deletar')),
                                    )
                                  ],
                                ),
                              ),
                      ))
                ],
              ),
            );
          }),
    );
  }

  void showAdminOpts(UsuarioModel user) {
    Get.bottomSheet(Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          color: Colors.white,
          child: Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.black12))),
                child: ListTile(
                  title: const Text('Cancelar'),
                  leading: const Icon(Icons.arrow_back),
                  onTap: () => Get.back(),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Stories - Sinais de Meu Isaque'),
                trailing: const Icon(Icons.keyboard_arrow_right),
                leading: const Icon(Icons.auto_stories),
                onTap: () {
                  Get.back();
                  // Garantir que o controller está registrado
                  if (!Get.isRegistered<StoriesGalleryController>()) {
                    Get.put(StoriesGalleryController());
                  }
                  Get.to(() => const StoriesView(contexto: 'sinais_isaque'));
                },
              ),
              const Divider(),
              const Divider(),
              ListTile(
                title: const Text('Editar Perfil'),
                trailing: const Icon(Icons.keyboard_arrow_right),
                leading: const Icon(Icons.edit),
                onTap: () {
                  Get.back();
                  Get.to(() => UsernameSettingsView(user: user));
                },
              ),
              const Divider(),
              ListTile(
                title: const Text('✨ Vitrine de Propósito'),
                trailing: const Icon(Icons.keyboard_arrow_right),
                leading: const Icon(Icons.person_outline),
                onTap: () {
                  Get.back();
                  Get.to(() => const ProfileCompletionView());
                },
              ),
              const Divider(),
              ListTile(
                title: const Text('Sair'),
                trailing: const Icon(Icons.keyboard_arrow_right),
                leading: const Icon(Icons.logout, color: Colors.red),
                onTap: () {
                  Get.back();
                  FirebaseAuth.instance.signOut();
                  Get.offAll(() => const LoginView());
                },
              ),
              Container(
                height: MediaQuery.of(context).padding.bottom + 16,
              )
            ],
          ),
        )
      ],
    ));
  }

  Widget _emoji() {
    return Container(
      color: Colors.white,
      width: Get.width,
      height: Get.width * 0.7,
      child: Container(
        color: AppTheme.materialColor.shade100,
        child: FutureBuilder<List<EmojiModel>>(
            future: ChatRepository.getAllEmoji(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Padding(
                  padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: 8 + MediaQuery.of(context).padding.bottom),
                  child: const Center(child: CircularProgressIndicator()),
                );
              }
              List<EmojiModel> all = snapshot.data!;
              return Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Container(
                    width: Get.width,
                    color: Colors.black12,
                    child: Obx(() => Row(
                          children: [
                            for (var group in ChatController.emujiGroup
                                .where((element) => element.imgAssets != null)
                                .toList())
                              Expanded(
                                  child: Container(
                                decoration: BoxDecoration(
                                    border: Border(
                                        bottom: BorderSide(
                                            color: group.en ==
                                                    ChatController.group.value
                                                ? AppTheme.materialColor
                                                : Colors.transparent,
                                            width: 3))),
                                padding:
                                    const EdgeInsets.only(bottom: 8, top: 12),
                                child: Center(
                                  child: InkWell(
                                    onTap: () =>
                                        ChatController.group.value = group.en!,
                                    child: Image.asset(group.imgAssets!,
                                        width: 24),
                                  ),
                                ),
                              )),
                          ],
                        )),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                          top: 16,
                          bottom: 16 + MediaQuery.of(context).padding.bottom),
                      child: SizedBox(
                        width: Get.width,
                        child: Obx(() => Wrap(
                              children: [
                                for (var emoji in all)
                                  if (emoji.group == ChatController.group.value)
                                    SizedBox(
                                      width: Get.width / 9,
                                      child: Center(
                                        child: InkWell(
                                          onTap: () =>
                                              ChatController.incrementEmoji(
                                                  emoji),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 3),
                                            child: Text(emoji.char!,
                                                style:
                                                    GoogleFonts.notoColorEmoji(
                                                        fontSize: 24)),
                                          ),
                                        ),
                                      ),
                                    )
                              ],
                            )),
                      ),
                    ),
                  ),
                ],
              );
            }),
      ),
    );
  }

  Widget _files() => Material(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Wrap(
                spacing: 16,
                children: [
                  InkWell(
                    onTap: () {
                      ChatController.showModalFiles.value = false;
                      HomeController.disableShowSenha = true;
                      ChatController.galeriaImg();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.materialColor),
                              borderRadius: BorderRadius.circular(8),
                              color: AppTheme.materialColor.shade50),
                          width: 55,
                          height: 45,
                          child: Icon(Icons.photo_size_select_actual_rounded,
                              color: AppTheme.materialColor),
                        ),
                        const SizedBox(height: 6),
                        Text(AppLanguage.lang('fotos'))
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      ChatController.showModalFiles.value = false;
                      HomeController.disableShowSenha = true;
                      await ChatController.galeriaVideo();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.materialColor),
                              borderRadius: BorderRadius.circular(8),
                              color: AppTheme.materialColor.shade50),
                          width: 55,
                          height: 45,
                          child: Icon(Icons.camera_alt,
                              color: AppTheme.materialColor),
                        ),
                        const SizedBox(height: 6),
                        Text(AppLanguage.lang('videos'))
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      ChatController.showModalFiles.value = false;
                      HomeController.disableShowSenha = true;
                      ChatController.getFile(isFirst: totMsgs == 0);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.materialColor),
                              borderRadius: BorderRadius.circular(8),
                              color: AppTheme.materialColor.shade50),
                          width: 55,
                          height: 45,
                          child: Icon(Icons.insert_drive_file_rounded,
                              color: AppTheme.materialColor),
                        ),
                        const SizedBox(height: 6),
                        Text(AppLanguage.lang('arquivos'),
                            style: const TextStyle(fontSize: 13))
                      ],
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      );

  Widget _camera() => Material(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Wrap(
                spacing: 16,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () async {
                      ChatController.showModalCamera.value = false;
                      HomeController.disableShowSenha = true;
                      bool r = await ChatController.cameraImg();
                      if (r == true) {
                        _showImageEdit();
                      }
                    },
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.materialColor),
                              borderRadius: BorderRadius.circular(8),
                              color: AppTheme.materialColor.shade50),
                          width: 55,
                          height: 45,
                          child: Icon(Icons.camera_alt,
                              color: AppTheme.materialColor),
                        ),
                        const SizedBox(height: 6),
                        Text(AppLanguage.lang('foto'))
                      ],
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () async {
                      ChatController.showModalCamera.value = false;
                      HomeController.disableShowSenha = true;
                      await ChatController.cameraVideo();
                    },
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.materialColor),
                              borderRadius: BorderRadius.circular(8),
                              color: AppTheme.materialColor.shade50),
                          width: 55,
                          height: 45,
                          child: Icon(Icons.video_camera_back_rounded,
                              color: AppTheme.materialColor),
                        ),
                        const SizedBox(height: 6),
                        Text(AppLanguage.lang('video'))
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  _showImageEdit() {
    Get.bottomSheet(
        Container(
          width: Get.width,
          height: Get.height,
          color: Colors.black,
          padding: const EdgeInsets.only(top: 20),
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Stack(
                      children: [
                        Image.memory(ChatController.fotoData!,
                            fit: BoxFit.contain),
                        Container(
                          width: 40,
                          height: 40,
                          margin: const EdgeInsets.only(top: 16, left: 16),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(100)),
                                backgroundColor: Colors.black12,
                                padding: const EdgeInsets.all(0)),
                            onPressed: () {
                              Get.back();
                              ChatController.legendaController.clear();
                              ChatController.fotoData = null;
                              ChatController.fotoPath.value = '';
                            },
                            child: const Icon(Icons.close, color: Colors.white),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 52 + 32)
                  ],
                ),
              ),
              Positioned.fill(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 16, right: 16, bottom: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: ChatController.legendaController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                enabledBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                                focusedBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                                hintText: AppLanguage.lang('digite_aqui'),
                                hintStyle:
                                    const TextStyle(color: Colors.white54),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          InkWell(
                              onTap: () async {
                                Get.back();
                                ChatController.sendFoto();
                                ChatController.legendaController.clear();
                                ChatController.fotoData = null;
                                ChatController.fotoPath.value = '';
                              },
                              child: Material(
                                color: AppTheme.materialColor,
                                borderRadius: BorderRadius.circular(100),
                                elevation: 3,
                                child: const SizedBox(
                                  width: 52,
                                  height: 52,
                                  child: Icon(Icons.send),
                                ),
                              ))
                        ],
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
        isScrollControlled: true);
  }

  // 🙏 NOVO: Widget elegante de pré-publicação "Responder ao Pai"
  Widget _buildReplyToStoryPreview() {
    final storyUrl = replyToStoryData!['storyUrl'] as String?;
    final storyType = replyToStoryData!['storyType'] as String?;
    final storyTitle = replyToStoryData!['storyTitle'] as String?;
    final storyDescription = replyToStoryData!['storyDescription'] as String?;
    final userMessage = replyToStoryData!['userMessage'] as String?;

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        elevation: 4,
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.reply, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Resposta ao Pai',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        replyToStoryData = null;
                      });
                    },
                    icon: const Icon(Icons.close, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (storyUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey.shade200,
                        child: storyType == 'video'
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    storyUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, url, error) =>
                                        Container(
                                      color: Colors.grey.shade300,
                                      child: const Icon(Icons.video_library,
                                          size: 32),
                                    ),
                                  ),
                                  Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Icon(
                                        Icons.play_arrow,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Image.network(
                                storyUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, url, error) => Container(
                                  color: Colors.grey.shade300,
                                  child: const Icon(Icons.image, size: 32),
                                ),
                              ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (storyTitle != null && storyTitle.isNotEmpty)
                          Text(
                            storyTitle.length > 40
                                ? '${storyTitle.substring(0, 40)}...'
                                : storyTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (storyDescription != null &&
                            storyDescription.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              storyDescription.length > 60
                                  ? '${storyDescription.substring(0, 60)}...'
                                  : storyDescription,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (userMessage != null && userMessage.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          userMessage,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade800,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _sendReplyToStory(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.send, size: 18, color: Colors.white),
                  label: const Text(
                    'Enviar Resposta ao Pai',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendReplyToStory() async {
    if (replyToStoryData == null) return;

    final storyUrl = replyToStoryData!['storyUrl'] as String?;
    final storyType = replyToStoryData!['storyType'] as String?;
    final storyTitle = replyToStoryData!['storyTitle'] as String?;
    final userMessage = replyToStoryData!['userMessage'] as String? ?? '';
    final storyId = replyToStoryData!['storyId'] as String?;

    String mensagemCompleta = '';
    if (storyTitle != null && storyTitle.isNotEmpty) {
      mensagemCompleta += '📖 $storyTitle\n\n';
    }
    if (userMessage.isNotEmpty) {
      mensagemCompleta += userMessage;
    }

    try {
      await ChatRepository.addText(
        msg: mensagemCompleta,
        contexto: 'sinais_isaque',
        replyToStoryId: storyId,
        replyToStoryUrl: storyUrl,
        replyToStoryType: storyType,
      );

      setState(() {
        replyToStoryData = null;
      });

      Get.rawSnackbar(
        message: 'Resposta enviada ao Pai! 🙏',
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.rawSnackbar(
        message: 'Erro ao enviar resposta',
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      );
    }
  }
}
