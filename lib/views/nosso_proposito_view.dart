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
import 'package:whatsapp_chat/controllers/notification_controller.dart';
import 'package:whatsapp_chat/locale/language.dart';
import 'package:whatsapp_chat/models/chat_model.dart';
import 'package:whatsapp_chat/models/emoji_model.dart';
import 'package:whatsapp_chat/models/usuario_model.dart';
import 'package:whatsapp_chat/repositories/chat_repository.dart';
import 'package:whatsapp_chat/repositories/stories_repository.dart';
import 'package:whatsapp_chat/repositories/usuario_repository.dart';
import 'package:whatsapp_chat/theme.dart';
import 'package:whatsapp_chat/token_usuario.dart';
import 'package:whatsapp_chat/views/community_info_view.dart';
import 'package:whatsapp_chat/views/login_view.dart';

import 'package:whatsapp_chat/views/select_language_view.dart';
import 'package:whatsapp_chat/views/sinais_isaque_view.dart';
import 'package:whatsapp_chat/views/sinais_rebeca_view.dart';
import 'package:whatsapp_chat/views/stories_view.dart';
import 'package:whatsapp_chat/views/enhanced_stories_viewer_view.dart';
import 'package:whatsapp_chat/views/story_favorites_view.dart';
import 'package:whatsapp_chat/views/username_settings_view.dart';
import 'package:whatsapp_chat/views/notifications_view.dart';
import 'package:whatsapp_chat/views/profile_completion_view.dart';

import '../components/editar_capa_component.dart';
import '../components/mention_autocomplete_component.dart';
import '../components/purpose_invites_component.dart';
import '../components/purpose_invite_button_component.dart';
import '../components/chat_restriction_banner_component.dart';
import '../components/nosso_proposito_notification_component.dart';
import '../models/storie_file_model.dart';
import '../models/storie_visto_model.dart';
import '../models/purpose_partnership_model.dart';
import '../models/purpose_chat_model.dart';
import '../repositories/purpose_partnership_repository.dart';

class NossoPropositoView extends StatefulWidget {
  const NossoPropositoView({super.key});

  @override
  State<NossoPropositoView> createState() => _NossoPropositoViewState();
}

class _NossoPropositoViewState extends State<NossoPropositoView> {
  int totMsgs = 0;
  final Rx<PurposePartnershipModel?> partnership =
      Rx<PurposePartnershipModel?>(null);

  // Sistema de @menções
  final RxBool showMentionAutocomplete = false.obs;
  final RxString mentionQuery = ''.obs;
  int mentionStartIndex = -1;

  @override
  void initState() {
    super.initState();

    // Executar inicializações de forma segura
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _safeInitialization();
    });
  }

  void _safeInitialization() async {
    try {
      await initPlatformState();
      _setupMentionListener();
      await _loadPartnership();
    } catch (e) {
      print('Erro na inicialização: $e');
      // Continuar mesmo com erro para não quebrar a tela
    }
  }

  void _setupMentionListener() {
    ChatController.msgController.addListener(() {
      _handleMentionInput();
    });
  }

  void _handleMentionInput() {
    final text = ChatController.msgController.text;
    final cursorPosition = ChatController.msgController.selection.baseOffset;

    print('🔍 Debug menção:');
    print('   text: "$text"');
    print('   cursorPosition: $cursorPosition');

    // Procurar por @ antes da posição do cursor
    int atIndex = -1;
    for (int i = cursorPosition - 1; i >= 0; i--) {
      if (text[i] == '@') {
        atIndex = i;
        break;
      } else if (text[i] == ' ' || text[i] == '\n') {
        break;
      }
    }

    print('   atIndex: $atIndex');

    if (atIndex != -1 && cursorPosition > atIndex) {
      // Extrair query da menção
      final query = text.substring(atIndex + 1, cursorPosition);
      print('   query: "$query"');

      if (query.isNotEmpty && !query.contains(' ')) {
        mentionStartIndex = atIndex;
        mentionQuery.value = query;
        showMentionAutocomplete.value = true;
        print('   ✅ Mostrando autocomplete');
        return;
      }
    }

    // Esconder autocomplete se não há menção válida
    showMentionAutocomplete.value = false;
    print('   ❌ Escondendo autocomplete');
  }

  Future<void> _loadPartnership() async {
    try {
      // Verificar se o usuário está autenticado
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('Usuário não autenticado');
        return;
      }

      // Tentar carregar parceria com timeout
      final userPartnership =
          await PurposePartnershipRepository.getUserPartnership(currentUser.uid)
              .timeout(const Duration(seconds: 10));
      partnership.value = userPartnership;
    } catch (e) {
      print('Erro ao carregar parceria: $e');
      // Não quebrar a tela se houver erro
      partnership.value = null;
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
                          Image.asset('lib/assets/img/capa.jpg',
                              width: Get.width),
                          Positioned.fill(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Lado esquerdo - Notificações/Admin + Menu + Comunidade
                                Row(
                                  children: [
                                    // Notificações (usuário normal) ou Admin (admin)
                                    user.isAdmin != true
                                        ? const NossoPropositoNotificationComponent()
                                        : Container(
                                            width: 50,
                                            height: 50,
                                            margin:
                                                const EdgeInsets.only(left: 16),
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                  padding:
                                                      const EdgeInsets.all(0),
                                                  backgroundColor:
                                                      Colors.white38),
                                              onPressed: () =>
                                                  showAdminOpts(user),
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
                                Row(
                                  children: [
                                    // Botão voltar (no lugar do ícone "Nosso Propósito")
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
                                    // Botão 🤵 apenas para usuários do sexo feminino
                                    if (user.sexo == UserSexo.feminino)
                                      Container(
                                        width: 50,
                                        height: 50,
                                        margin: const EdgeInsets.only(right: 8),
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                              padding: const EdgeInsets.all(0),
                                              backgroundColor: Colors.white38),
                                          onPressed: () => Get.to(
                                              () => const SinaisIsaqueView()),
                                          child: const Text('🤵',
                                              style: TextStyle(fontSize: 24)),
                                        ),
                                      ),
                                    // Botão 👰‍♀️ apenas para usuários do sexo masculino
                                    if (user.sexo == UserSexo.masculino)
                                      Container(
                                        width: 50,
                                        height: 50,
                                        margin: const EdgeInsets.only(right: 8),
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                              padding: const EdgeInsets.all(0),
                                              backgroundColor: Colors.white38),
                                          onPressed: () => Get.to(
                                              () => const SinaisRebecaView()),
                                          child: const Text('👰‍♀️',
                                              style: TextStyle(fontSize: 24)),
                                        ),
                                      ),
                                  ],
                                )
                              ],
                            ),
                          )
                        ],
                      ),
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
                                Obx(() => partnership.value != null &&
                                        partnership.value!.isActivePartnership
                                    ? _buildSharedChat(user)
                                    : _buildIndividualChat(user)),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Builder(builder: (context) {
                        Widget child = Container(
                          width: Get.width * 339 / 1289,
                          height: Get.width * 339 / 1289,
                          margin: EdgeInsets.only(
                              top: (Get.width * 339 / 1289) * 0.15),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(Get.width),
                              border: Border.all(
                                  color: Colors.black,
                                  width: (Get.width * 339 / 1289) * 0.03),
                              color: Colors.white),
                          child: ClipRRect(
                              borderRadius: BorderRadius.circular(Get.width),
                              child: Image.asset('lib/assets/img/logo_2.png')),
                        );
                        return StreamBuilder<List<StorieVistoModel>>(
                            stream: StoriesRepository.getStoreVisto(),
                            builder: (context, snapshot) {
                              List<StorieVistoModel> vistos = [];
                              List<String> vistosIds = [];
                              if (snapshot.hasData) {
                                vistos = snapshot.data!;
                                vistosIds =
                                    vistos.map((e) => e.idStore!).toList();
                              }
                              return StreamBuilder<List<StorieFileModel>>(
                                  stream: StoriesRepository.getAllAntigos(),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return child;
                                    }
                                    List<StorieFileModel> storiesAntigos =
                                        snapshot.data!;
                                    return StreamBuilder<List<StorieFileModel>>(
                                        stream:
                                            StoriesRepository.getAllByContext(
                                                'nosso_proposito'),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData) {
                                            List<StorieFileModel> listStories =
                                                [];
                                            for (var element
                                                in snapshot.data!) {
                                              if (DateTime.now()
                                                      .difference(element
                                                          .dataCadastro!
                                                          .toDate())
                                                      .inMinutes <=
                                                  (24 * 60)) {
                                                listStories.add(element);
                                              }
                                            }
                                            for (var element
                                                in storiesAntigos) {
                                              if (DateTime.now()
                                                          .difference(element
                                                              .dataCadastro!
                                                              .toDate())
                                                          .inMinutes <=
                                                      (24 * 60) &&
                                                  DateTime.now()
                                                          .difference(element
                                                              .dataCadastro!
                                                              .toDate())
                                                          .inMinutes >
                                                      0) {
                                                listStories.add(element);
                                              }
                                            }
                                            listStories.removeWhere((element) =>
                                                element.idioma != null &&
                                                element.idioma !=
                                                    TokenUsuario().idioma);
                                            listStories.sort((a, b) => a
                                                .dataCadastro!
                                                .compareTo(b.dataCadastro!));

                                            if (listStories.isNotEmpty) {
                                              child = InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        Get.width),
                                                onTap: () {
                                                  // Usar EnhancedStoriesViewerView para funcionalidade TikTok
                                                  Get.to(() =>
                                                      const EnhancedStoriesViewerView(
                                                        contexto:
                                                            'nosso_proposito',
                                                        userSexo:
                                                            null, // Todos os usuários
                                                      ));
                                                },
                                                child:
                                                    Builder(builder: (context) {
                                                  // Filtrar stories válidos (24h, idioma, público-alvo)
                                                  final now = DateTime.now();
                                                  final twentyFourHoursAgo = now
                                                      .subtract(const Duration(
                                                          hours: 24));

                                                  List<StorieFileModel>
                                                      validStories = listStories
                                                          .where((story) {
                                                    // Verificar se está dentro de 24h
                                                    final storyDate = story
                                                        .dataCadastro
                                                        ?.toDate();
                                                    if (storyDate == null ||
                                                        storyDate.isBefore(
                                                            twentyFourHoursAgo)) {
                                                      return false;
                                                    }

                                                    // Verificar idioma
                                                    if (story.idioma != null &&
                                                        story.idioma !=
                                                            TokenUsuario()
                                                                .idioma) {
                                                      return false;
                                                    }

                                                    // Verificar público-alvo (removido para contexto nosso_proposito - stories para ambos os sexos)
                                                    // No contexto "Nosso Propósito", stories são visíveis para ambos os sexos

                                                    return true;
                                                  }).toList();

                                                  // Verificar quais stories válidos não foram vistos
                                                  List<StorieFileModel>
                                                      listStoriesNaoVisto =
                                                      validStories
                                                          .where((element) =>
                                                              !vistosIds
                                                                  .contains(
                                                                      element
                                                                          .id))
                                                          .toList();

                                                  // Debug para verificar stories não vistos
                                                  print(
                                                      'DEBUG CHAT: Stories totais: ${listStories.length}');
                                                  print(
                                                      'DEBUG CHAT: Stories válidos: ${validStories.length}');
                                                  print(
                                                      'DEBUG CHAT: Stories vistos: ${vistosIds.length}');
                                                  print(
                                                      'DEBUG CHAT: Stories não vistos: ${listStoriesNaoVisto.length}');
                                                  print(
                                                      'DEBUG CHAT: Círculo verde: ${listStoriesNaoVisto.isNotEmpty}');

                                                  return Container(
                                                    width:
                                                        Get.width * 339 / 1289,
                                                    height:
                                                        Get.width * 339 / 1289,
                                                    margin: EdgeInsets.only(
                                                        top: (Get.width *
                                                                339 /
                                                                1289) *
                                                            0.15),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              Get.width),
                                                      color: listStoriesNaoVisto
                                                              .isEmpty
                                                          ? null
                                                          : const Color(
                                                              0xFF39b9ff), // Azul por fora
                                                    ),
                                                    padding:
                                                        const EdgeInsets.all(3),
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        color: listStoriesNaoVisto
                                                                .isEmpty
                                                            ? Colors.black
                                                            : const Color(
                                                                0xFFfc6aeb), // Rosa por dentro
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                                    Get.width),
                                                      ),
                                                      padding:
                                                          const EdgeInsets.all(
                                                              4),
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
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
                                  });
                            });
                      }),
                    ],
                  ),
                  // Imagem "NOSSO PROPÓSITO" original transparente logo abaixo da logo
                  Positioned(
                    top: (Get.width * 339 / 1289) + 20, // Logo abaixo da logo
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: Get.width * 0.8, // 80% da largura da tela
                        height: 60, // Altura fixa para a imagem
                        child: Image.asset(
                          'lib/assets/img/nosso_proposito_banner.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback caso a imagem não carregue - usando a imagem original que você anexou
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Stack(
                                children: [
                                  // Fundo com pinceladas brancas (como na imagem original)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      margin: const EdgeInsets.all(2),
                                    ),
                                  ),
                                  // Conteúdo exato da imagem original
                                  Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // Casal da imagem original
                                        const Text('👩‍❤️‍👨',
                                            style: TextStyle(fontSize: 24)),
                                        const SizedBox(width: 8),
                                        // Texto "NOSSO PROPÓSITO" com as cores da imagem original
                                        Text(
                                          'NOSSO PROPÓSITO',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            foreground: Paint()
                                              ..shader = const LinearGradient(
                                                colors: [
                                                  Color(0xFF39b9ff), // Azul
                                                  Color(0xFFfc6aeb), // Rosa
                                                ],
                                              ).createShader(
                                                  const Rect.fromLTWH(
                                                      0.0, 0.0, 200.0, 70.0)),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Ícone de alvo da imagem original
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFfc6aeb),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.gps_fixed,
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  // Indicador de parceria ativa
                  Obx(() => partnership.value != null &&
                          partnership.value!.isActivePartnership
                      ? Positioned(
                          top: (Get.width * 339 / 1289) +
                              90, // Abaixo da logo "NOSSO PROPÓSITO"
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF39b9ff).withOpacity(0.9),
                                    const Color(0xFFfc6aeb).withOpacity(0.9),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.favorite,
                                      color: Colors.white, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Chat Compartilhado Ativo',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : const SizedBox()),
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
                        // Componente de autocomplete para @menções
                        Obx(() => showMentionAutocomplete.value
                            ? Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: MentionAutocompleteComponent(
                                  query: mentionQuery.value,
                                  onUserSelected: _onMentionUserSelected,
                                  onDismiss: () =>
                                      showMentionAutocomplete.value = false,
                                ),
                              )
                            : const SizedBox()),
                        // Botão de convite (apenas quando não tem parceiro)
                        Obx(() => partnership.value == null ||
                                !partnership.value!.isActivePartnership
                            ? PurposeInviteButtonComponent(
                                user: user,
                                onPressed: () => _showAddPartnerDialog(user),
                                isLoading: false,
                              )
                            : const SizedBox()),
                        // Banner de restrição (apenas quando não tem parceiro)
                        Obx(() => partnership.value == null ||
                                !partnership.value!.isActivePartnership
                            ? ChatRestrictionBannerComponent(
                                user: user,
                                onAddPartner: () => _showAddPartnerDialog(user),
                              )
                            : const SizedBox()),
                        // Componente de convites de parceria
                        const PurposeInvitesComponent(),
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
                                                child: Obx(() => TextField(
                                                      controller: ChatController
                                                          .msgController,
                                                      enabled: partnership
                                                                  .value !=
                                                              null &&
                                                          partnership.value!
                                                              .isActivePartnership,
                                                      style: TextStyle(
                                                        color: partnership
                                                                        .value !=
                                                                    null &&
                                                                partnership
                                                                    .value!
                                                                    .isActivePartnership
                                                            ? Colors.black
                                                            : Colors
                                                                .grey.shade400,
                                                      ),
                                                      decoration:
                                                          InputDecoration(
                                                        enabledBorder:
                                                            InputBorder.none,
                                                        border:
                                                            InputBorder.none,
                                                        focusedBorder:
                                                            InputBorder.none,
                                                        filled: true,
                                                        fillColor:
                                                            Colors.transparent,
                                                        hintText: partnership
                                                                        .value !=
                                                                    null &&
                                                                partnership
                                                                    .value!
                                                                    .isActivePartnership
                                                            ? AppLanguage.lang(
                                                                'digite_aqui')
                                                            : 'Adicione um parceiro para conversar...',
                                                        hintStyle: TextStyle(
                                                          color: partnership
                                                                          .value !=
                                                                      null &&
                                                                  partnership
                                                                      .value!
                                                                      .isActivePartnership
                                                              ? Colors
                                                                  .grey.shade600
                                                              : Colors.grey
                                                                  .shade400,
                                                        ),
                                                      ),
                                                      maxLines: 3,
                                                      minLines: 1,
                                                      onChanged:
                                                          (String? text) async {
                                                        ChatController
                                                                .showBtnAudio
                                                                .value =
                                                            text!
                                                                .trim()
                                                                .isEmpty;

                                                        if (text
                                                                .split('\n')
                                                                .length >
                                                            1) {
                                                          ChatController
                                                              .sendMsg(
                                                                  isFirst:
                                                                      totMsgs ==
                                                                          0);
                                                          return;
                                                        }

                                                        String? url =
                                                            ChatController
                                                                .extractURL(
                                                                    text);
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
                                                    )),
                                              ),
                                              SizedBox(
                                                width: 40,
                                                child: Obx(() => Container(
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                        gradient: ChatController
                                                                    .showModalCamera
                                                                    .value ==
                                                                true
                                                            ? const LinearGradient(
                                                                colors: [
                                                                  Color(
                                                                      0xFF38b6ff), // Azul
                                                                  Color(
                                                                      0xFFf76cec), // Rosa
                                                                ],
                                                                begin: Alignment
                                                                    .topLeft,
                                                                end: Alignment
                                                                    .bottomRight,
                                                              )
                                                            : null,
                                                      ),
                                                      child: TextButton(
                                                        style: TextButton.styleFrom(
                                                            shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            20)),
                                                            backgroundColor:
                                                                Colors
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
                                                        child: Icon(
                                                          Icons
                                                              .camera_alt_outlined,
                                                          color: ChatController
                                                                      .showModalCamera
                                                                      .value ==
                                                                  true
                                                              ? Colors.white
                                                              : const Color(
                                                                  0xFF38b6ff),
                                                        ),
                                                      ),
                                                    )),
                                              ),
                                              SizedBox(
                                                width: 40,
                                                child: Obx(() => Container(
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                        gradient: ChatController
                                                                    .showModalFiles
                                                                    .value ==
                                                                true
                                                            ? const LinearGradient(
                                                                colors: [
                                                                  Color(
                                                                      0xFF38b6ff), // Azul
                                                                  Color(
                                                                      0xFFf76cec), // Rosa
                                                                ],
                                                                begin: Alignment
                                                                    .topLeft,
                                                                end: Alignment
                                                                    .bottomRight,
                                                              )
                                                            : null,
                                                      ),
                                                      child: TextButton(
                                                        style: TextButton.styleFrom(
                                                            shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            20)),
                                                            backgroundColor:
                                                                Colors
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
                                                        child: Icon(
                                                          Icons.attach_file,
                                                          color: ChatController
                                                                      .showModalFiles
                                                                      .value ==
                                                                  true
                                                              ? Colors.white
                                                              : const Color(
                                                                  0xFFf76cec),
                                                        ),
                                                      ),
                                                    )),
                                              ),
                                            ],
                                          )),
                                  ),
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(left: 16),
                                child: Obx(() => InkWell(
                                    onTap: partnership.value != null &&
                                            partnership
                                                .value!.isActivePartnership
                                        ? () {
                                            //AudioController.start();
                                            if (ChatController
                                                    .showBtnAudio.value ==
                                                false) {
                                              _sendMessage();
                                            } else {
                                              if (AudioController
                                                      .isGravandoAudio.value ==
                                                  false) {
                                                AudioController.isGravandoAudio
                                                    .value = true;
                                              } else {
                                                AudioController.isGravandoAudio
                                                    .value = false;
                                                AudioController.stop();
                                              }
                                            }
                                          }
                                        : null,
                                    child: Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(100),
                                        gradient: partnership.value != null &&
                                                partnership
                                                    .value!.isActivePartnership
                                            ? const LinearGradient(
                                                colors: [
                                                  Color(0xFF38b6ff), // Azul
                                                  Color(0xFFf76cec), // Rosa
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              )
                                            : LinearGradient(
                                                colors: [
                                                  Colors.grey.shade400,
                                                  Colors.grey.shade500,
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                        boxShadow: partnership.value != null &&
                                                partnership
                                                    .value!.isActivePartnership
                                            ? [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.2),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ]
                                            : [],
                                      ),
                                      child: Obx(() => Icon(
                                            partnership.value != null &&
                                                    partnership.value!
                                                        .isActivePartnership
                                                ? (ChatController.showBtnAudio
                                                            .value ==
                                                        false
                                                    ? Icons.send
                                                    : (AudioController
                                                                .isGravandoAudio
                                                                .value ==
                                                            true
                                                        ? Icons.stop
                                                        : Icons.mic_rounded))
                                                : Icons.block,
                                            color: Colors.white,
                                            size: 24,
                                          )),
                                    ))),
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
                            // Expanded(
                            //   child: Container(
                            //     decoration: BoxDecoration(
                            //       border: Border(bottom: BorderSide(color: '' == ChatController.group.value ? AppTheme.materialColor : Colors.transparent, width: 3))
                            //     ),
                            //     padding: const EdgeInsets.only(bottom: 8, top: 12),
                            //     child: Center(
                            //       child: InkWell(
                            //         onTap: () => ChatController.group.value = '',
                            //         child: const Icon(Icons.access_time_sharp, size: 24),
                            //       ),
                            //     ),
                            //   ),
                            // ),
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
                            borderRadius: BorderRadius.circular(8),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF38b6ff), // Azul
                                Color(0xFFf76cec), // Rosa
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          width: 55,
                          height: 45,
                          child: const Icon(
                              Icons.photo_size_select_actual_rounded,
                              color: Colors.white),
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
                            borderRadius: BorderRadius.circular(8),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF38b6ff), // Azul
                                Color(0xFFf76cec), // Rosa
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          width: 55,
                          height: 45,
                          child:
                              const Icon(Icons.camera_alt, color: Colors.white),
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
                            borderRadius: BorderRadius.circular(8),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF38b6ff), // Azul
                                Color(0xFFf76cec), // Rosa
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          width: 55,
                          height: 45,
                          child: const Icon(Icons.insert_drive_file_rounded,
                              color: Colors.white),
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
                            borderRadius: BorderRadius.circular(8),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF38b6ff), // Azul
                                Color(0xFFf76cec), // Rosa
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          width: 55,
                          height: 45,
                          child:
                              const Icon(Icons.camera_alt, color: Colors.white),
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
                            borderRadius: BorderRadius.circular(8),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF38b6ff), // Azul
                                Color(0xFFf76cec), // Rosa
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          width: 55,
                          height: 45,
                          child: const Icon(Icons.video_camera_back_rounded,
                              color: Colors.white),
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
                            child: SizedBox(
                              child: TextField(
                                controller: ChatController.legendaController,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  hintText:
                                      '${AppLanguage.lang('adicione_uma_legenda')}...',
                                  enabledBorder: const OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(50)),
                                      borderSide: BorderSide.none),
                                  border: const OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(50)),
                                      borderSide: BorderSide.none),
                                  focusedBorder: const OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(50)),
                                      borderSide: BorderSide.none),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 52,
                            height: 52,
                            margin: const EdgeInsets.only(left: 12),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(0),
                              ),
                              onPressed: () {
                                ChatController.sendFoto();
                                Get.back();
                              },
                              child: const Icon(Icons.send),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
        isDismissible: true,
        isScrollControlled: true);
  }

  showAdminOpts(UsuarioModel user) => Get.bottomSheet(Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            color: Colors.white,
            child: Column(
              children: [
                Container(
                  decoration: const BoxDecoration(
                      border:
                          Border(bottom: BorderSide(color: Colors.black12))),
                  child: ListTile(
                    title: const Text('Cancelar'),
                    leading: const Icon(Icons.arrow_back),
                    onTap: () => Get.back(),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: const Text('Stories'),
                  trailing: const Icon(Icons.keyboard_arrow_right),
                  leading: const Icon(Icons.photo_camera_back),
                  onTap: () {
                    Get.back();
                    Get.to(() => const StoriesView());
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Notificações'),
                  trailing: const Icon(Icons.keyboard_arrow_right),
                  leading: const Icon(Icons.notification_add_outlined),
                  onTap: () {
                    Get.back();
                    addNotification();
                  },
                ),
                const Divider(),
                ListTile(
                  title: Text(AppLanguage.lang('editar_perfil')),
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
                  leading: const Icon(Icons.logout),
                  onTap: () async {
                    Get.back();
                    await FirebaseAuth.instance.signOut();
                    FirebaseAuth.instance.authStateChanges();
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

  addNotification() {
    final msgControl = TextEditingController();
    final tituloControl = TextEditingController();
    final temDistincaoDeSexo = false.obs;
    final masculinos = [''].obs;
    final femininos = [''].obs;

    Get.defaultDialog(
        title: 'Notificação',
        content: Container(
          constraints: BoxConstraints(maxHeight: Get.height * 0.7),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: TextField(
                    controller: tituloControl,
                    decoration: const InputDecoration(label: Text('Título')),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: TextField(
                    controller: msgControl,
                    decoration: const InputDecoration(label: Text('Mensagem')),
                    maxLines: 2,
                  ),
                ),
                Row(
                  children: const [
                    Text('Tem distinção de sexo?'),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: Get.width,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Obx(() => Wrap(
                        alignment: WrapAlignment.start,
                        spacing: 12,
                        children: [
                          SizedBox(
                            height: 36,
                            child: OutlinedButton.icon(
                              onPressed: () => temDistincaoDeSexo.value = false,
                              label: const Text('Não'),
                              icon: Icon(temDistincaoDeSexo.value == false
                                  ? Icons.check_circle
                                  : Icons.circle_outlined),
                            ),
                          ),
                          SizedBox(
                            height: 36,
                            child: OutlinedButton.icon(
                              onPressed: () => temDistincaoDeSexo.value = true,
                              label: const Text('Sim'),
                              icon: Icon(temDistincaoDeSexo.value == true
                                  ? Icons.check_circle
                                  : Icons.circle_outlined),
                            ),
                          )
                        ],
                      )),
                ),
                Obx(() => temDistincaoDeSexo.value == false
                    ? const SizedBox()
                    : Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          children: [
                            Obx(() => Table(
                                  border:
                                      TableBorder.all(color: Colors.black26),
                                  children: [
                                    const TableRow(children: [
                                      Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text('Masculino',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text('Feminino',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      )
                                    ]),
                                    for (var i = 0; i < masculinos.length; i++)
                                      TableRow(children: [
                                        TextField(
                                          decoration: const InputDecoration(
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      horizontal: 8),
                                              hintText: 'Digite aqui...'),
                                          onChanged: (String? text) {
                                            masculinos[i] = text!;
                                          },
                                        ),
                                        TextField(
                                          decoration: const InputDecoration(
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      horizontal: 8),
                                              hintText: 'Digite aqui...'),
                                          onChanged: (String? text) {
                                            femininos[i] = text!;
                                          },
                                        ),
                                      ])
                                  ],
                                )),
                            OutlinedButton.icon(
                              onPressed: () {
                                masculinos.add('');
                                femininos.add('');
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Adicionar nova linha'),
                            )
                          ],
                        ),
                      )),
                SizedBox(
                  height: 52,
                  width: Get.width,
                  child: ElevatedButton(
                    onPressed: () async {
                      String titulo = tituloControl.text.trim();
                      String msg = msgControl.text.trim();
                      if (titulo.isEmpty || msg.isEmpty) {
                        Get.rawSnackbar(message: 'Preencha todos os campos!');
                        return;
                      }
                      Get.back();
                      String tituloF = titulo.replaceAll('', '');
                      String msgF = msg.replaceAll('', '');
                      for (var i = 0; i < masculinos.length; i++) {
                        tituloF =
                            tituloF.replaceAll(masculinos[i], femininos[i]);
                      }
                      for (var i = 0; i < masculinos.length; i++) {
                        msgF = msgF.replaceAll(masculinos[i], femininos[i]);
                      }
                      if (temDistincaoDeSexo.value == true) {
                        await NotificationController.sendNotificationToTopic(
                            titulo: titulo,
                            msg: msg,
                            abrirStories: false,
                            topico: 'sexo_m');
                        await NotificationController.sendNotificationToTopic(
                            titulo: tituloF,
                            msg: msgF,
                            abrirStories: false,
                            topico: 'sexo_f');
                      } else {
                        await NotificationController.sendNotificationToTopic(
                            titulo: titulo, msg: msg, abrirStories: false);
                      }
                    },
                    child: const Text('Enviar'),
                  ),
                )
              ],
            ),
          ),
        ));
  }

  // Chat compartilhado (quando há parceria ativa)
  Widget _buildSharedChat(UsuarioModel user) {
    return StreamBuilder<List<PurposeChatModel>>(
      stream: PurposePartnershipRepository.getSharedChat(
          partnership.value!.chatId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        List<PurposeChatModel> messages = snapshot.data!;
        messages.sort((a, b) => b.dataCadastro!.compareTo(a.dataCadastro!));

        if (messages.isEmpty) {
          return Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  top: (Get.width * 339 / 1289) * 0.2),
              decoration: BoxDecoration(
                  color: const Color(0xFFfeeecc),
                  borderRadius: BorderRadius.circular(7.5)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('💕', style: TextStyle(fontSize: 32)),
                  const SizedBox(height: 8),
                  Text(
                    'Bem-vindos ao chat compartilhado!\nAgora vocês podem conversar com Deus juntos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          );
        }

        List<Widget> widgets = [];
        List<DateTime> datas = [];

        for (var element in messages) {
          DateTime d = element.dataCadastro!.toDate();
          DateTime d2 = DateTime(d.year, d.month, d.day);
          if (!datas.contains(d2)) {
            datas.add(d2);
          }
        }

        for (var data in datas) {
          String stringData = '';
          final diferenca = DateTime.now().difference(data);
          if (diferenca.inDays < 1) {
            stringData = AppLanguage.lang('hoje');
          } else if (diferenca.inDays <= 2) {
            stringData = AppLanguage.lang('ontem');
          } else {
            stringData = DateFormat('dd/MM/y').format(data);
          }

          for (var chatItem in messages) {
            if (DateFormat('dd/MM/y').format(data) ==
                DateFormat('dd/MM/y').format(chatItem.dataCadastro!.toDate())) {
              // SEMPRE criar usuário baseado nos dados da mensagem para garantir cor correta
              // Debug para verificar o valor do autorSexo
              print(
                  '🎨 DEBUG OUTROS: autorSexo = "${chatItem.autorSexo}", autorNome = "${chatItem.autorNome}"');

              // Converter string do sexo para enum UserSexo
              UserSexo userSexo = UserSexo.none;
              if (chatItem.autorSexo == 'feminino') {
                userSexo = UserSexo.feminino;
              } else if (chatItem.autorSexo == 'masculino') {
                userSexo = UserSexo.masculino;
              } else if (chatItem.autorSexo == null ||
                  chatItem.autorSexo == 'none') {
                // Fallback: Se é o usuário atual, usar seu sexo
                if (chatItem.idDe == user.id) {
                  userSexo = user.sexo ?? UserSexo.none;
                } else {
                  // Para mensagens antigas sem autorSexo, usar lógica baseada no nome ou ID
                  // Temporariamente usar verde (none) até que novas mensagens sejam enviadas
                  userSexo = UserSexo.none;
                }
              }

              // Criar usuário com dados corretos do autor da mensagem
              UsuarioModel messageUser = UsuarioModel(
                id: chatItem.idDe ?? 'unknown',
                nome: chatItem.autorNome ?? 'Usuário',
                email: '', // Não necessário para exibição
                sexo: userSexo, // Usar o sexo correto do autor (SEMPRE)
                isAdmin: chatItem.isFromAdmin, // Preservar se é admin
                username: null, // Não necessário para exibição
              );

              if (chatItem.tipo == ChatType.text) {
                widgets.add(_buildSharedChatTextComponent(chatItem, user));
              } else if (chatItem.tipo == ChatType.img) {
                widgets.add(ChatImgComponent(
                    item: chatItem.toChatModel(),
                    usuarioModel: messageUser,
                    showArrow: true));
              } else if (chatItem.tipo == ChatType.video) {
                widgets.add(ChatVideoComponent(
                    item: chatItem.toChatModel(),
                    usuarioModel: messageUser,
                    showArrow: true));
              } else if (['mp3', 'm4a', 'ogg', 'opus']
                  .contains(chatItem.fileExtension)) {
                widgets.add(ChatAudioComponent(
                    item: chatItem.toChatModel(),
                    usuarioModel: messageUser,
                    showArrow: true));
              } else {
                widgets.add(ChatOutroFormatoComponent(
                    item: chatItem.toChatModel(),
                    usuarioModel: messageUser,
                    showArrow: true));
              }
            }
          }

          widgets.add(
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(7.5)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Text(stringData.toUpperCase()),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          reverse: true,
          itemCount: widgets.length,
          padding: EdgeInsets.only(
              left: 0,
              right: 0,
              bottom: 16 + 60 + MediaQuery.of(context).padding.bottom,
              top: (Get.width * 339 / 1289) * 0.2),
          itemBuilder: (BuildContext context, int index) => widgets[index],
        );
      },
    );
  }

  // Chat individual (quando não há parceria)
  Widget _buildIndividualChat(UsuarioModel user) {
    return StreamBuilder<List<ChatModel>>(
      stream: ChatRepository.getAll(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        List<ChatModel> chat = snapshot.data!;
        chat.sort((a, b) => b.dataCadastro!.compareTo(a.dataCadastro!));
        List<DateTime> datas = [];

        totMsgs = chat.length;

        for (var element in chat) {
          DateTime d = element.dataCadastro!.toDate();
          DateTime d2 = DateTime(d.year, d.month, d.day);
          if (!datas.contains(d2)) {
            datas.add(d2);
          }
        }

        List<Widget> widgets = [];

        for (var data in datas) {
          String stringData = '';
          final diferenca = DateTime.now().difference(data);
          if (diferenca.inDays < 1) {
            stringData = AppLanguage.lang('hoje');
          } else if (diferenca.inDays <= 2) {
            stringData = AppLanguage.lang('ontem');
          } else {
            stringData = DateFormat('dd/MM/y').format(data);
          }
          for (var chatItem in chat) {
            if (DateFormat('dd/MM/y').format(data) ==
                DateFormat('dd/MM/y').format(chatItem.dataCadastro!.toDate())) {
              if (chatItem.tipo == ChatType.text) {
                widgets.add(ChatTextComponent(
                  item: chatItem,
                  usuarioModel: user,
                  showArrow: true,
                  textColor: chatItem.orginemAdmin == true
                      ? const Color(0xFFffb400)
                      : Colors.white,
                ));
              } else if (chatItem.tipo == ChatType.img) {
                widgets.add(ChatImgComponent(
                    item: chatItem, usuarioModel: user, showArrow: true));
              } else if (chatItem.tipo == ChatType.video) {
                widgets.add(ChatVideoComponent(
                    item: chatItem, usuarioModel: user, showArrow: true));
              } else if (['mp3', 'm4a', 'ogg', 'opus']
                  .contains(chatItem.fileExtension)) {
                widgets.add(ChatAudioComponent(
                    item: chatItem, usuarioModel: user, showArrow: true));
              } else {
                widgets.add(ChatOutroFormatoComponent(
                    item: chatItem, usuarioModel: user, showArrow: true));
              }
            }
          }
          widgets.add(
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(7.5)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Text(stringData.toUpperCase()),
                ),
              ],
            ),
          );
        }

        if (datas.isEmpty) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                    color: const Color(0xFFfeeecc),
                    borderRadius: BorderRadius.circular(7.5)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    top: (Get.width * 339 / 1289) * 0.6),
                child: Text(AppLanguage.lang('send_first_msg'),
                    style: TextStyle(color: Colors.grey.shade700)),
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
              bottom: 16 + 60 + MediaQuery.of(context).padding.bottom,
              top: (Get.width * 339 / 1289) * 0.2),
          itemBuilder: (BuildContext context, int index) => widgets[index],
        );
      },
    );
  }

  // Componente de texto para chat compartilhado com posicionamento específico
  Widget _buildSharedChatTextComponent(
      PurposeChatModel chatItem, UsuarioModel currentUser) {
    // SEMPRE criar o usuário baseado nos dados da mensagem para garantir cor correta
    // Debug para verificar o valor do autorSexo
    print(
        '🎨 DEBUG SEXO: autorSexo = "${chatItem.autorSexo}", autorNome = "${chatItem.autorNome}"');

    // Converter string do sexo para enum UserSexo
    UserSexo userSexo = UserSexo.none;
    if (chatItem.autorSexo == 'feminino') {
      userSexo = UserSexo.feminino;
    } else if (chatItem.autorSexo == 'masculino') {
      userSexo = UserSexo.masculino;
    } else if (chatItem.autorSexo == null || chatItem.autorSexo == 'none') {
      // Fallback: Se é o usuário atual, usar seu sexo
      if (chatItem.idDe == currentUser.id) {
        userSexo = currentUser.sexo ?? UserSexo.none;
      } else {
        // Para mensagens antigas sem autorSexo, usar lógica baseada no nome ou ID
        // Temporariamente usar verde (none) até que novas mensagens sejam enviadas
        userSexo = UserSexo.none;
      }
    }

    print('🎨 DEBUG ENUM: userSexo = $userSexo');

    // Criar usuário com dados corretos do autor da mensagem
    UsuarioModel messageUser = UsuarioModel(
      id: chatItem.idDe ?? 'unknown',
      nome: chatItem.autorNome ?? 'Usuário',
      email: '', // Não necessário para exibição
      sexo: userSexo, // Usar o sexo correto do autor (SEMPRE)
      isAdmin: chatItem.isFromAdmin, // Preservar se é admin
      username: null, // Não necessário para exibição
    );

    return ChatTextComponent(
      item: chatItem.toChatModel(),
      usuarioModel: messageUser,
      showArrow: true,
      textColor: chatItem.isFromAdmin
          ? const Color(0xFFffb400) // Admin (Pai) - lado direito
          : (chatItem.isFromCouple
              ? Colors.white // Casal - lado esquerdo
              : Colors.white),
    );
  }

  // Método para enviar mensagem (individual ou compartilhada)
  void _sendMessage() async {
    if (ChatController.msgController.text.trim().isEmpty) return;

    try {
      if (partnership.value != null && partnership.value!.isActivePartnership) {
        // Chat compartilhado
        await _sendSharedMessage();
      } else {
        // Chat individual (original)
        ChatController.sendMsg(isFirst: totMsgs == 0);
      }
    } catch (e) {
      Get.snackbar(
        'Erro ao Enviar Mensagem',
        e.toString().replaceAll('Exception: ', ''),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
      );
    }
  }

  // Enviar mensagem no chat compartilhado
  Future<void> _sendSharedMessage() async {
    final message = ChatController.msgController.text.trim();
    final chatId = partnership.value!.chatId!;
    final participantIds = [
      partnership.value!.user1Id!,
      partnership.value!.user2Id!
    ];

    // Verificar se há @menção na mensagem
    String? mentionedUserId = await _extractMentionFromMessage(message);

    print('🔍 Debug menção:');
    print('   message: "$message"');
    print('   mentionedUserId: $mentionedUserId');

    if (mentionedUserId != null) {
      try {
        // Enviar convite de menção
        final currentUser = UsuarioModel(
          id: FirebaseAuth.instance.currentUser!.uid,
          nome: FirebaseAuth.instance.currentUser!.displayName,
          email: FirebaseAuth.instance.currentUser!.email,
        );

        print('📤 Enviando convite de menção para: $mentionedUserId');

        await PurposePartnershipRepository.sendMentionInvite(
            mentionedUserId, message, currentUser);

        Get.snackbar(
          'Convite de Menção Enviado! 📩',
          'O usuário mencionado receberá um convite para participar.',
          backgroundColor: const Color(0xFFfc6aeb),
          colorText: Colors.white,
          icon: const Icon(Icons.alternate_email, color: Colors.white),
          duration: const Duration(seconds: 4),
        );

        print('✅ Convite de menção enviado com sucesso');
      } catch (e) {
        print('❌ Erro ao enviar convite de menção: $e');
        Get.snackbar(
          'Erro ao Enviar Menção',
          'Não foi possível enviar o convite de menção.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          icon: const Icon(Icons.error, color: Colors.white),
        );
      }
    }

    // Enviar mensagem no chat compartilhado
    await PurposePartnershipRepository.sendSharedMessage(
      chatId,
      message,
      participantIds,
      mentionedUserId: mentionedUserId,
    );

    // Limpar campo de texto
    ChatController.msgController.clear();
    ChatController.showBtnAudio.value = true;
    ChatController.linkDescricaoModel.value = null;
    ChatController.linkDescricaoModel.refresh();
  }

  // Callback quando usuário é selecionado no autocomplete
  void _onMentionUserSelected(UsuarioModel user) {
    final text = ChatController.msgController.text;
    final beforeMention = text.substring(0, mentionStartIndex);
    final afterMention =
        text.substring(ChatController.msgController.selection.baseOffset);

    // Usar username se disponível, senão usar nome
    final mentionText = user.username != null && user.username!.isNotEmpty
        ? user.username!
        : user.nome ?? 'usuario';

    final newText = '$beforeMention@$mentionText $afterMention';
    ChatController.msgController.text = newText;

    // Posicionar cursor após a menção (incluindo espaço)
    final newCursorPosition = beforeMention.length + mentionText.length + 2;
    ChatController.msgController.selection =
        TextSelection.collapsed(offset: newCursorPosition);

    // Esconder autocomplete
    showMentionAutocomplete.value = false;
  }

  // Extrair @menção da mensagem
  Future<String?> _extractMentionFromMessage(String message) async {
    final mentionRegex = RegExp(r'@(\w+)');
    final matches = mentionRegex.allMatches(message);

    if (matches.isNotEmpty) {
      // Por enquanto, pegar apenas a primeira menção
      final match = matches.first;
      final mentionedUsername = match.group(1);

      // Converter username para userId usando busca
      return await _getUserIdByName(mentionedUsername);
    }
    return null;
  }

  // Buscar userId por username/nome
  Future<String?> _getUserIdByName(String? name) async {
    if (name == null || name.isEmpty) return null;

    try {
      // Buscar usuários por nome
      final users = await PurposePartnershipRepository.searchUsersByName(name);

      if (users.isNotEmpty) {
        // Procurar por match exato de username primeiro
        for (var user in users) {
          if (user.username != null &&
              user.username!.toLowerCase() == name.toLowerCase()) {
            return user.id;
          }
        }

        // Se não encontrou por username, procurar por nome
        for (var user in users) {
          if (user.nome != null &&
              user.nome!.toLowerCase().contains(name.toLowerCase())) {
            return user.id;
          }
        }
      }
    } catch (e) {
      print('Erro ao buscar usuário por nome: $e');
    }

    return null;
  }

  // Buscar usuários para autocomplete
  void _searchUsersForAutocomplete(
      String username,
      RxList<UsuarioModel> searchResults,
      RxBool showAutocomplete,
      UsuarioModel currentUser) async {
    try {
      final users =
          await PurposePartnershipRepository.searchUsersByName(username);

      // Filtrar usuários válidos
      final validUsers = users.where((foundUser) {
        // Não mostrar o próprio usuário
        if (foundUser.id == FirebaseAuth.instance.currentUser?.uid)
          return false;

        // Não mostrar usuários do mesmo sexo
        if (foundUser.sexo == currentUser.sexo) return false;

        return true;
      }).toList();

      searchResults.value = validUsers;
      showAutocomplete.value = validUsers.isNotEmpty;
    } catch (e) {
      print('Erro ao buscar usuários: $e');
      searchResults.clear();
      showAutocomplete.value = false;
    }
  }

  // Buscar usuário por username (será chamado dentro do dialog)
  void _searchUserByUsername(
      String username,
      RxString errorMessage,
      RxBool isValidSearch,
      RxBool showUserProfile,
      Rx<UsuarioModel?> selectedUser,
      UsuarioModel currentUser) async {
    try {
      final users =
          await PurposePartnershipRepository.searchUsersByName(username);
      if (users.isNotEmpty) {
        final foundUser = users.first;

        // Verificar se não é o mesmo usuário
        if (foundUser.id == FirebaseAuth.instance.currentUser!.uid) {
          errorMessage.value = 'Você não pode convidar a si mesmo';
          isValidSearch.value = false;
          showUserProfile.value = false;
          selectedUser.value = null;
          return;
        }

        // Verificar se não é do mesmo sexo
        if (foundUser.sexo == currentUser.sexo) {
          errorMessage.value = 'Não é possível adicionar usuário do mesmo sexo';
          isValidSearch.value = false;
          showUserProfile.value = false;
          selectedUser.value = null;
          return;
        }

        // Usuário válido encontrado
        selectedUser.value = foundUser;
        showUserProfile.value = true;
        isValidSearch.value = true;
        errorMessage.value = '';
      } else {
        errorMessage.value = 'Usuário não encontrado';
        isValidSearch.value = false;
        showUserProfile.value = false;
        selectedUser.value = null;
      }
    } catch (e) {
      errorMessage.value = 'Erro ao buscar usuário';
      isValidSearch.value = false;
      showUserProfile.value = false;
      selectedUser.value = null;
    }
  }

  void _showAddPartnerDialog(UsuarioModel user) {
    final TextEditingController searchController = TextEditingController();
    final TextEditingController messageController = TextEditingController();
    final RxString errorMessage = ''.obs;
    final RxBool isValidSearch = false.obs;
    final Rx<UsuarioModel?> selectedUser = Rx<UsuarioModel?>(null);
    final RxBool showUserProfile = false.obs;
    final RxBool showAutocomplete = false.obs;
    final RxList<UsuarioModel> searchResults = <UsuarioModel>[].obs;

    // Validação de busca por @ em tempo real
    searchController.addListener(() {
      final query = searchController.text.trim();
      if (query.isEmpty) {
        errorMessage.value = '';
        isValidSearch.value = false;
        showUserProfile.value = false;
        showAutocomplete.value = false;
        selectedUser.value = null;
        searchResults.clear();
      } else if (!query.startsWith('@')) {
        errorMessage.value = 'Digite @ seguido do username';
        isValidSearch.value = false;
        showUserProfile.value = false;
        showAutocomplete.value = false;
        selectedUser.value = null;
        searchResults.clear();
      } else if (query.length < 3) {
        errorMessage.value = 'Digite pelo menos 2 caracteres após @';
        isValidSearch.value = false;
        showUserProfile.value = false;
        showAutocomplete.value = false;
        selectedUser.value = null;
        searchResults.clear();
      } else {
        errorMessage.value = '';
        _searchUsersForAutocomplete(
            query.substring(1), searchResults, showAutocomplete, user);
      }
    });

    Get.dialog(
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.favorite, color: Color(0xFFfc6aeb)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Add Parceiro(a) ao Propósito',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF39b9ff),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF39b9ff).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: Color(0xFF39b9ff), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Digite @ seguido do nome para encontrar seu(sua) parceiro(a).',
                              style: TextStyle(
                                color: const Color(0xFF39b9ff),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: '@nome_do_usuario',
                        prefixIcon: const Icon(Icons.alternate_email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFF39b9ff)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Autocomplete de usuários
                    Obx(() => showAutocomplete.value && searchResults.isNotEmpty
                        ? Container(
                            constraints: const BoxConstraints(maxHeight: 200),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: searchResults.length,
                              itemBuilder: (context, index) {
                                final foundUser = searchResults[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: foundUser.imgUrl != null
                                        ? NetworkImage(foundUser.imgUrl!)
                                        : null,
                                    backgroundColor: const Color(0xFF39b9ff)
                                        .withOpacity(0.1),
                                    child: foundUser.imgUrl == null
                                        ? Text(
                                            foundUser.nome?.isNotEmpty == true
                                                ? foundUser.nome![0]
                                                    .toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              color: Color(0xFF39b9ff),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : null,
                                  ),
                                  title: Text(
                                    foundUser.username != null &&
                                            foundUser.username!.isNotEmpty
                                        ? '@${foundUser.username}'
                                        : foundUser.nome ?? 'Usuário',
                                  ),
                                  subtitle: Text(foundUser.email ?? ''),
                                  trailing: Icon(
                                    foundUser.sexo == UserSexo.masculino
                                        ? Icons.male
                                        : Icons.female,
                                    color: foundUser.sexo == UserSexo.masculino
                                        ? Colors.blue
                                        : Colors.pink,
                                  ),
                                  onTap: () {
                                    selectedUser.value = foundUser;
                                    final displayName =
                                        foundUser.username != null &&
                                                foundUser.username!.isNotEmpty
                                            ? '@${foundUser.username}'
                                            : '@${foundUser.nome}';
                                    searchController.text = displayName;
                                    showAutocomplete.value = false;
                                    showUserProfile.value = true;
                                    isValidSearch.value = true;
                                    errorMessage.value = '';
                                  },
                                );
                              },
                            ),
                          )
                        : const SizedBox()),
                    const SizedBox(height: 8),
                    // Perfil do usuário encontrado
                    Obx(() => showUserProfile.value &&
                            selectedUser.value != null
                        ? Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color:
                                      const Color(0xFF39b9ff).withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                // Avatar
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF39b9ff)
                                        .withOpacity(0.1),
                                  ),
                                  child: selectedUser.value!.imgUrl != null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          child: Image.network(
                                            selectedUser.value!.imgUrl!,
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Center(
                                                child: Text(
                                                  selectedUser.value!.nome
                                                              ?.isNotEmpty ==
                                                          true
                                                      ? selectedUser
                                                          .value!.nome![0]
                                                          .toUpperCase()
                                                      : '?',
                                                  style: const TextStyle(
                                                    color: Color(0xFF39b9ff),
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        )
                                      : Center(
                                          child: Text(
                                            selectedUser.value!.nome
                                                        ?.isNotEmpty ==
                                                    true
                                                ? selectedUser.value!.nome![0]
                                                    .toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              color: Color(0xFF39b9ff),
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                // Informações do usuário
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        selectedUser.value!.username != null &&
                                                selectedUser
                                                    .value!.username!.isNotEmpty
                                            ? '@${selectedUser.value!.username}'
                                            : selectedUser.value!.nome ??
                                                'Usuário',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (selectedUser.value!.email !=
                                          null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          selectedUser.value!.email!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                // Ícone de verificação
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox()),
                    const SizedBox(height: 8),
                    // Caixa de mensagem personalizada
                    Obx(() => showUserProfile.value
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mensagem do convite:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: messageController,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  hintText:
                                      'Escreva uma mensagem personalizada para o convite...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color: Color(0xFF39b9ff)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          )
                        : const SizedBox()),
                    const SizedBox(height: 8),
                    Obx(() => errorMessage.value.isNotEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.red, size: 16),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    errorMessage.value,
                                    style: const TextStyle(
                                        color: Colors.red, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox()),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Get.back(),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Obx(() => ElevatedButton(
                                onPressed: isValidSearch.value &&
                                        selectedUser.value != null
                                    ? () {
                                        _sendPartnerInviteWithMessage(
                                            selectedUser.value!,
                                            messageController.text.trim(),
                                            user);
                                        Get.back();
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isValidSearch.value
                                      ? const Color(0xFF39b9ff)
                                      : Colors.grey.shade300,
                                ),
                                child: Text(
                                  'Enviar Convite',
                                  style: TextStyle(
                                    color: isValidSearch.value
                                        ? Colors.white
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              )),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendPartnerInviteWithMessage(
      UsuarioModel targetUser, String message, UsuarioModel currentUser) async {
    try {
      // Debug dos IDs
      print('🔍 Debug IDs:');
      print('   targetUser.id: ${targetUser.id}');
      print('   targetUser.email: ${targetUser.email}');
      print('   currentUser.id: ${currentUser.id}');
      print('   currentUser.nome: ${currentUser.nome}');

      // Verificar se os IDs existem
      if (targetUser.id == null || targetUser.id!.isEmpty) {
        throw Exception('ID do usuário de destino é inválido');
      }

      if (currentUser.id == null || currentUser.id!.isEmpty) {
        throw Exception('ID do usuário atual é inválido');
      }

      // Mostrar loading
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF39b9ff)),
          ),
        ),
        barrierDismissible: false,
      );

      // Verificar se o email existe
      if (targetUser.email == null || targetUser.email!.isEmpty) {
        throw Exception('Usuário não possui email válido');
      }

      // Enviar convite usando o repository com mensagem personalizada
      await PurposePartnershipRepository.sendPartnershipInviteWithMessage(
          targetUser.email!,
          message.isNotEmpty
              ? message
              : 'Gostaria de conversar com Deus juntos no Propósito!',
          currentUser);

      // Fechar loading
      Get.back();

      // Mostrar sucesso
      Get.snackbar(
        'Convite Enviado! 💕',
        'Convite para ${targetUser.nome} foi enviado com sucesso!',
        backgroundColor: const Color(0xFF39b9ff),
        colorText: Colors.white,
        icon: const Icon(Icons.favorite, color: Colors.white),
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      // Fechar loading se ainda estiver aberto
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      // Mostrar erro
      Get.snackbar(
        'Erro ao Enviar Convite',
        e.toString().replaceAll('Exception: ', ''),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
        duration: const Duration(seconds: 4),
      );
    }
  }

  void _sendPartnerInvite(String searchTerm, UsuarioModel currentUser) async {
    try {
      // Mostrar loading
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF39b9ff)),
          ),
        ),
        barrierDismissible: false,
      );

      // Enviar convite usando o repository
      await PurposePartnershipRepository.sendPartnershipInvite(
          searchTerm, currentUser);

      // Fechar loading
      Get.back();

      // Mostrar sucesso
      Get.snackbar(
        'Convite Enviado! 💕',
        'Convite para "$searchTerm" foi enviado com sucesso!',
        backgroundColor: const Color(0xFF39b9ff),
        colorText: Colors.white,
        icon: const Icon(Icons.favorite, color: Colors.white),
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      // Fechar loading se ainda estiver aberto
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      // Mostrar erro
      Get.snackbar(
        'Erro ao Enviar Convite',
        e.toString().replaceAll('Exception: ', ''),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
        duration: const Duration(seconds: 4),
      );
    }
  }
}
