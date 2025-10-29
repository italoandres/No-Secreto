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
import 'package:whatsapp_chat/models/emoji_grupo_model.dart';
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

class SinaisRebecaView extends StatefulWidget {
  const SinaisRebecaView({super.key});

  @override
  State<SinaisRebecaView> createState() => _SinaisRebecaViewState();
}

class _SinaisRebecaViewState extends State<SinaisRebecaView> {
  int totMsgs = 0;
  @override
  void initState() {
    super.initState();
    initPlatformState();
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
                                          contexto: 'sinais_rebeca'),
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
                                    stream: ChatRepository.getAllSinaisRebeca(),
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
                                                    ? const Color(0xFF38b6ff)
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
                  // Imagem sinais_rebeca.png por cima de tudo
                  Positioned(
                    top: (Get.width * 339 / 1289) + 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: Get.width * 0.8,
                        height: 60,
                        child: Image.asset(
                          'lib/assets/img/sinais_rebeca.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  // Círculo do perfil com sistema moderno de stories (azul para Sinais de Rebeca)
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
                                '🚨 SINAIS REBECA: Chamando getAllSinaisRebeca()');
                            return StreamBuilder<List<StorieFileModel>>(
                                stream: StoriesRepository
                                    .getAllSinaisRebeca(), // FORÇANDO MÉTODO ESPECÍFICO
                                builder: (context, snapshot) {
                                  print(
                                      '🚨 SINAIS REBECA: StreamBuilder executado - hasData: ${snapshot.hasData}');
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
                                                contexto: 'sinais_rebeca',
                                                userSexo: UserSexo
                                                    .masculino, // Apenas usuários masculinos
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

                                            // Verificar público-alvo (apenas masculino para Sinais de Rebeca)
                                            if (story.publicoAlvo != null &&
                                                story.publicoAlvo !=
                                                    UserSexo.masculino) {
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
                                              'DEBUG SINAIS REBECA: Stories totais: ${listStories.length}');
                                          print(
                                              'DEBUG SINAIS REBECA: Stories válidos: ${validStories.length}');
                                          print(
                                              'DEBUG SINAIS REBECA: Stories vistos: ${vistosIds.length}');
                                          print(
                                              'DEBUG SINAIS REBECA: Stories não vistos: ${listStoriesNaoVisto.length}');
                                          print(
                                              'DEBUG SINAIS REBECA: Círculo azul: ${listStoriesNaoVisto.isNotEmpty}');

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
                                                                0xFF38b6ff), // Azul para Sinais de Rebeca
                                                            Color(0xFF38b6ff),
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
                                                      _sendMsgSinaisRebeca(
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
                                                              ? const Color(
                                                                      0xFF38b6ff)
                                                                  .withOpacity(
                                                                      0.1)
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
                                                              ? const Color(
                                                                      0xFF38b6ff)
                                                                  .withOpacity(
                                                                      0.1)
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
                                      if (ChatController.showBtnAudio.value ==
                                          false) {
                                        _sendMsgSinaisRebeca(
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
                                      color: const Color(0xFF38b6ff),
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
                                              color: Colors.white,
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
                  )
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
                title: const Text('Stories - Sinais de Minha Rebeca'),
                trailing: const Icon(Icons.keyboard_arrow_right),
                leading: const Icon(Icons.auto_stories),
                onTap: () {
                  Get.back();
                  // Garantir que o controller está registrado
                  if (!Get.isRegistered<StoriesGalleryController>()) {
                    Get.put(StoriesGalleryController());
                  }
                  Get.to(() => const StoriesView(contexto: 'sinais_rebeca'));
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

  void _sendMsgSinaisRebeca({required bool isFirst}) {
    String msg = ChatController.msgController.text.trim();
    if (msg.isEmpty) return;

    ChatRepository.addText(msg: msg, contexto: 'sinais_rebeca');
    ChatController.msgController.clear();
    ChatController.linkDescricaoModel.value = null;
    ChatController.linkDescricaoModel.refresh();

    // Enviar mensagens automáticas do Pai após a primeira mensagem
    if (isFirst) {
      ChatController.mensagensSinaisRebecaAposPrimeiraMsg();
    }
  }

  Widget _emoji() {
    return Material(
      borderRadius: BorderRadius.circular(8),
      color: Colors.white,
      elevation: 2,
      child: Container(
        height: 250,
        width: Get.width,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 40,
              child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: ChatController.emujiGroup.length,
                  itemBuilder: (BuildContext context, int index) {
                    EmojiGrupoModel grupo = ChatController.emujiGroup[index];
                    return Obx(() => InkWell(
                          onTap: () => ChatController.group.value = grupo.en!,
                          child: Container(
                            decoration: BoxDecoration(
                                color: ChatController.group.value == grupo.en
                                    ? const Color(0xFF38b6ff).withOpacity(0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: grupo.imgAssets == null
                                ? Text(grupo.pt!)
                                : Image.asset(grupo.imgAssets!,
                                    width: 24, height: 24),
                          ),
                        ));
                  }),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<EmojiModel>>(
                  future: ChatRepository.getAllEmoji(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    List<EmojiModel> emojis = snapshot.data!
                        .where((element) =>
                            element.group == ChatController.group.value)
                        .toList();
                    return GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 9, childAspectRatio: 1),
                        itemCount: emojis.length,
                        itemBuilder: (BuildContext context, int index) {
                          EmojiModel emoji = emojis[index];
                          return Container(
                            width: Get.width / 9,
                            child: Center(
                              child: InkWell(
                                onTap: () =>
                                    ChatController.incrementEmoji(emoji),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 3),
                                  child: Text(emoji.char!,
                                      style: GoogleFonts.notoColorEmoji(
                                          fontSize: 24)),
                                ),
                              ),
                            ),
                          );
                        });
                  }),
            ),
          ],
        ),
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
                              border:
                                  Border.all(color: const Color(0xFF38b6ff)),
                              borderRadius: BorderRadius.circular(8),
                              color: const Color(0xFF38b6ff).withOpacity(0.1)),
                          width: 55,
                          height: 45,
                          child: const Icon(
                              Icons.photo_size_select_actual_rounded,
                              color: Color(0xFF38b6ff)),
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
                              border:
                                  Border.all(color: const Color(0xFF38b6ff)),
                              borderRadius: BorderRadius.circular(8),
                              color: const Color(0xFF38b6ff).withOpacity(0.1)),
                          width: 55,
                          height: 45,
                          child: const Icon(Icons.camera_alt,
                              color: Color(0xFF38b6ff)),
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
                              border:
                                  Border.all(color: const Color(0xFF38b6ff)),
                              borderRadius: BorderRadius.circular(8),
                              color: const Color(0xFF38b6ff).withOpacity(0.1)),
                          width: 55,
                          height: 45,
                          child: const Icon(Icons.insert_drive_file_rounded,
                              color: Color(0xFF38b6ff)),
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
                        // TODO: Implementar _showImageEdit se necessário
                      }
                    },
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                              border:
                                  Border.all(color: const Color(0xFF38b6ff)),
                              borderRadius: BorderRadius.circular(8),
                              color: const Color(0xFF38b6ff).withOpacity(0.1)),
                          width: 55,
                          height: 45,
                          child: const Icon(Icons.camera_alt,
                              color: Color(0xFF38b6ff)),
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
                              border:
                                  Border.all(color: const Color(0xFF38b6ff)),
                              borderRadius: BorderRadius.circular(8),
                              color: const Color(0xFF38b6ff).withOpacity(0.1)),
                          width: 55,
                          height: 45,
                          child: const Icon(Icons.video_camera_back_rounded,
                              color: Color(0xFF38b6ff)),
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
}
