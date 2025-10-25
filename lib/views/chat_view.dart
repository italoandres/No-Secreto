
import 'dart:io';
import 'dart:async'; // ✨ NOVO: Para Timer
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
import 'package:whatsapp_chat/components/notification_icon_component.dart';
import 'package:whatsapp_chat/views/nosso_proposito_view.dart';
import 'package:whatsapp_chat/views/select_language_view.dart';
import 'package:whatsapp_chat/views/sinais_isaque_view.dart';
import 'package:whatsapp_chat/views/sinais_rebeca_view.dart';
import 'package:whatsapp_chat/views/stories_view.dart';
import 'package:whatsapp_chat/views/enhanced_stories_viewer_view.dart';
import 'package:whatsapp_chat/views/story_favorites_view.dart';
import 'package:whatsapp_chat/views/username_settings_view.dart';
import 'package:whatsapp_chat/views/profile_completion_view.dart';
import 'simple_certification_panel.dart';

import '../components/editar_capa_component.dart';
import '../components/purpose_invites_component.dart';
import '../models/storie_file_model.dart';
import '../models/storie_visto_model.dart';


class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {

  int totMsgs = 0;
  Timer? _onlineTimer; // ✨ NOVO: Timer para tracking de status online
  
  @override
  void initState() {
    super.initState();
    initPlatformState();
    _startOnlineTracking(); // ✨ NOVO: Iniciar tracking
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
        ChatRepository.addFile(file: file, extensao: extension, fileName: fileName);
      },
    );
    if (!mounted) return;
  }
  
  // ✨ NOVO: Método para iniciar tracking de status online
  void _startOnlineTracking() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    // Marcar como online imediatamente
    FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .update({
      'lastSeen': FieldValue.serverTimestamp(),
      'isOnline': true,
    }).catchError((e) {
      debugPrint('⚠️ Erro ao atualizar status online: $e');
    });
    
    // Atualizar a cada 30 segundos
    _onlineTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        FirebaseFirestore.instance
            .collection('usuarios')
            .doc(userId)
            .update({
          'lastSeen': FieldValue.serverTimestamp(),
          'isOnline': true,
        }).catchError((e) {
          debugPrint('⚠️ Erro ao atualizar status online: $e');
        });
      }
    });
  }

  // ✨ NOVO: Método para parar tracking
  void _stopOnlineTracking() {
    _onlineTimer?.cancel();
    
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .update({
        'lastSeen': FieldValue.serverTimestamp(),
        'isOnline': false,
      }).catchError((e) {
        debugPrint('⚠️ Erro ao marcar como offline: $e');
      });
    }
  }

  @override
  void dispose() {
    _stopOnlineTracking(); // ✨ NOVO: Parar tracking ao sair
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {

    double appBarHeight = (Get.width * 339 / 1289);

    return Scaffold(
      body: StreamBuilder<UsuarioModel?>(
        stream: UsuarioRepository.getUser(),
        builder: (context, snapshot) {
          if(!snapshot.hasData) {
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
                        Image.asset('lib/assets/img/capa.jpg', width: Get.width),
                        Positioned.fill(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Lado esquerdo - Notificações + Comunidade
                              Row(
                                children: [
                                  // Ícone de notificações
                                  Container(
                                    width: 50, height: 50,
                                    margin: const EdgeInsets.only(left: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white38,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const NotificationIconComponent(contexto: 'principal'),
                                  ),
                                  
                                  // Menu admin (apenas para admins)
                                  if (user.isAdmin == true)
                                    Container(
                                      width: 50, height: 50,
                                      margin: const EdgeInsets.only(left: 8),
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.all(0),
                                          backgroundColor: Colors.white38
                                        ),
                                        onPressed: () => showAdminOpts(user),
                                        child: const Icon(Icons.admin_panel_settings, color: Colors.white),
                                      ),
                                    ),
                                  
                                  // Ícone da comunidade
                                  Container(
                                    width: 50, height: 50,
                                    margin: const EdgeInsets.only(left: 8),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.all(0),
                                        backgroundColor: Colors.white38
                                      ),
                                      onPressed: () => Get.to(() => const CommunityInfoView()),
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
                                  // Botão 🤵 apenas para usuários do sexo feminino
                                  if(user.sexo == UserSexo.feminino)
                                  Container(
                                    width: 50, height: 50,
                                    margin: const EdgeInsets.only(right: 8),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.all(0),
                                        backgroundColor: Colors.white38
                                      ),
                                      onPressed: () => Get.to(() => const SinaisIsaqueView()),
                                      child: const Text('🤵', style: TextStyle(fontSize: 24)),
                                    ),
                                  ),
                                  // Botão 👰‍♀️ apenas para usuários do sexo masculino
                                  if(user.sexo == UserSexo.masculino)
                                  Container(
                                    width: 50, height: 50,
                                    margin: const EdgeInsets.only(right: 8),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.all(0),
                                        backgroundColor: Colors.white38
                                      ),
                                      onPressed: () => Get.to(() => const SinaisRebecaView()),
                                      child: const Text('👰‍♀️', style: TextStyle(fontSize: 24)),
                                    ),
                                  ),
                                  // Botão "Nosso Propósito" (futuro chat de casal)
                                  Container(
                                    width: 50, height: 50,
                                    margin: const EdgeInsets.only(right: 8),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.all(0),
                                        backgroundColor: Colors.white38
                                      ),
                                      onPressed: () => Get.to(() => const NossoPropositoView()),
                                      child: const Text('👩‍❤️‍👨', style: TextStyle(fontSize: 20)),
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
                          user.imgBgUrl == null ? Opacity(
                            opacity: 0.3,
                            child: Image.asset('lib/assets/img/bg_wallpaper.jpg', width: Get.width, height: Get.height, fit: BoxFit.cover)
                          ) : CachedNetworkImage(imageUrl: user.imgBgUrl!, width: Get.width, height: Get.height, fit: BoxFit.cover),
                          Stack(
                            children: [
                              StreamBuilder<List<ChatModel>>(
                                stream: ChatRepository.getAll(),
                                builder: (context, snapshot) {
                                  if(!snapshot.hasData) {
                                    return const Center(child: CircularProgressIndicator());
                                  }
                    
                                  List<ChatModel> chat = snapshot.data!;
                                  chat.sort((a, b) => b.dataCadastro!.compareTo(a.dataCadastro!));
                                  List<DateTime> datas = [];

                                  totMsgs = chat.length;
                    
                                  for (var element in chat) {
                                    DateTime d = element.dataCadastro!.toDate();
                                    DateTime d2 = DateTime(d.year, d.month, d.day);
                                    if(!datas.contains(d2)) {
                                      datas.add(d2);
                                    }
                                  }
                    
                                  List<Widget> widgets = [];
                    
                                  for (var data in datas) {
                                    String stringData = '';
                                    final diferenca = DateTime.now().difference(data);
                                    if(diferenca.inDays < 1) {
                                      stringData = AppLanguage.lang('hoje');
                                    } else if(diferenca.inDays <= 2) {
                                      stringData = AppLanguage.lang('ontem');
                                    } else {
                                      stringData = DateFormat('dd/MM/y').format(data);
                                    }
                                    for (var chatItem in chat) {
                    
                                      if(DateFormat('dd/MM/y').format(data) == DateFormat('dd/MM/y').format(chatItem.dataCadastro!.toDate())) {
                                        if(chatItem.tipo == ChatType.text) {
                                          widgets.add(ChatTextComponent(
                                            item: chatItem, 
                                            usuarioModel: user, 
                                            showArrow: true,
                                            textColor: chatItem.orginemAdmin == true ? const Color(0xFFffb400) : Colors.white,
                                          ));
                                        } else if(chatItem.tipo == ChatType.img) {
                                          widgets.add(ChatImgComponent(item: chatItem, usuarioModel: user, showArrow: true));
                                        } else if(chatItem.tipo == ChatType.video) {
                                          widgets.add(ChatVideoComponent(item: chatItem, usuarioModel: user, showArrow: true));
                                        } else if(['mp3','m4a','ogg','opus'].contains(chatItem.fileExtension)) {
                                          widgets.add(ChatAudioComponent(item: chatItem, usuarioModel: user, showArrow: true));
                                        } else {
                                          widgets.add(ChatOutroFormatoComponent(item: chatItem, usuarioModel: user, showArrow: true));
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
                                              borderRadius: BorderRadius.circular(7.5)
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                            margin: const EdgeInsets.only(bottom: 12),
                                            child: Text(stringData.toUpperCase()),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                    
                                  if(datas.isEmpty) {
                                    return Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFfeeecc),
                                            borderRadius: BorderRadius.circular(7.5)
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          margin: EdgeInsets.only(
                                            left: 16, right: 16, bottom: 16, top: appBarHeight * 0.2
                                          ),
                                          child: Text(AppLanguage.lang('send_first_msg'), style: TextStyle(color: Colors.grey.shade700)),
                                        ),
                                      ],
                                    );
                                  }
                    
                                  return ListView.builder(
                                    reverse: true,
                                    itemCount: widgets.length,
                                    padding: EdgeInsets.only(
                                      left: 0, right: 0, bottom: 16 + 60 + MediaQuery.of(context).padding.bottom, top: appBarHeight * 0.2
                                    ),
                                    itemBuilder: (BuildContext context, int index) => widgets[index]
                                  );
                                }
                              ),
                              

                              Positioned(
                                bottom: 8 + 60 + MediaQuery.of(context).padding.bottom, right: 16,
                                child: Obx(() => ChatController.showModalFiles.value == false ? const SizedBox() : _files()),
                              ),
                              Positioned(
                                bottom: 8 + 60 + MediaQuery.of(context).padding.bottom, right: 82,
                                child: Obx(() => ChatController.showModalCamera.value == false ? const SizedBox() : _camera()),
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
                    Builder(
                      builder: (context) {
                        Widget child = Container(
                          width: Get.width * 339 / 1289,
                          height: Get.width * 339 / 1289,
                          margin: EdgeInsets.only(top: (Get.width * 339 / 1289) * 0.15),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(Get.width),
                            border: Border.all(color: Colors.black, width: (Get.width * 339 / 1289) * 0.03),
                            color: Colors.white
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(Get.width),
                            child: Image.asset('lib/assets/img/logo_2.png')
                          ),
                        );
                        return StreamBuilder<List<StorieVistoModel>>(
                          stream: StoriesRepository.getStoreVisto(),
                          builder: (context, snapshot) {
                            List<StorieVistoModel> vistos = [];
                            List<String> vistosIds = [];
                            if(snapshot.hasData) {
                              vistos = snapshot.data!;
                              vistosIds = vistos.map((e) => e.idStore!).toList();
                            }
                            return StreamBuilder<List<StorieFileModel>>(
                              stream: StoriesRepository.getAllAntigos(),
                              builder: (context, snapshot) {
                                if(!snapshot.hasData) {
                                  return child;
                                }
                                List<StorieFileModel> storiesAntigos = snapshot.data!;
                                return StreamBuilder<List<StorieFileModel>>(
                                  stream: StoriesRepository.getAll(),
                                  builder: (context, snapshot) {
                                
                                    if(snapshot.hasData) {
                                      List<StorieFileModel> listStories = [];
                                      for (var element in snapshot.data!) {
                                        if(DateTime.now().difference(element.dataCadastro!.toDate()).inMinutes <= (24 * 60)) {
                                          listStories.add(element);
                                        }
                                      }
                                      for (var element in storiesAntigos) {
                                        if(DateTime.now().difference(element.dataCadastro!.toDate()).inMinutes <= (24 * 60) && 
                                          DateTime.now().difference(element.dataCadastro!.toDate()).inMinutes > 0) {
                                          listStories.add(element);
                                        }
                                      }
                                      listStories.removeWhere((element) => element.idioma != null && element.idioma != TokenUsuario().idioma);
                                      listStories.sort((a, b) => a.dataCadastro!.compareTo(b.dataCadastro!)); 
                                
                                      if(listStories.isNotEmpty) {
                                        child = InkWell(
                                          borderRadius: BorderRadius.circular(Get.width),
                                          onTap: () {
                                            // Usar EnhancedStoriesViewerView para funcionalidade TikTok
                                            Get.to(() => const EnhancedStoriesViewerView(
                                              contexto: 'principal',
                                              userSexo: null, // Todos os usuários
                                            ));
                                          },
                                          child: Builder(
                                            builder: (context) {
                                              // Filtrar stories válidos (24h, idioma, público-alvo)
                                              final now = DateTime.now();
                                              final twentyFourHoursAgo = now.subtract(const Duration(hours: 24));
                                              
                                              List<StorieFileModel> validStories = listStories.where((story) {
                                                // Verificar se está dentro de 24h
                                                final storyDate = story.dataCadastro?.toDate();
                                                if (storyDate == null || storyDate.isBefore(twentyFourHoursAgo)) {
                                                  return false;
                                                }
                                                
                                                // Verificar idioma
                                                if (story.idioma != null && story.idioma != TokenUsuario().idioma) {
                                                  return false;
                                                }
                                                
                                                // Verificar público-alvo
                                                if (story.publicoAlvo != null && story.publicoAlvo != user.sexo) {
                                                  return false;
                                                }
                                                
                                                return true;
                                              }).toList();
                                              
                                              // Verificar quais stories válidos não foram vistos
                                              List<StorieFileModel> listStoriesNaoVisto = validStories.where((element) => !vistosIds.contains(element.id)).toList();
                                              
                                              // Debug para verificar stories não vistos
                                              print('DEBUG CHAT: Stories totais: ${listStories.length}');
                                              print('DEBUG CHAT: Stories válidos: ${validStories.length}');
                                              print('DEBUG CHAT: Stories vistos: ${vistosIds.length}');
                                              print('DEBUG CHAT: Stories não vistos: ${listStoriesNaoVisto.length}');
                                              print('DEBUG CHAT: Círculo verde: ${listStoriesNaoVisto.isNotEmpty}');
                                              
                                              return Container(
                                                width: Get.width * 339 / 1289,
                                                height: Get.width * 339 / 1289,
                                                margin: EdgeInsets.only(top: (Get.width * 339 / 1289) * 0.15),
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(Get.width),
                                                  gradient: listStoriesNaoVisto.isEmpty ? null : const LinearGradient(
                                                    colors: [
                                                      // Color(0xFFFAC60D),
                                                      // Color(0xFFE402CA),
                                                      Color(0xFF0eed33),
                                                      Color(0xFF0eed33),
                                                    ],
                                                    end: Alignment.topRight,
                                                    begin: Alignment.bottomLeft
                                                  )
                                                ),
                                                padding: const EdgeInsets.all(3),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.black,
                                                    borderRadius: BorderRadius.circular(Get.width),
                                                  ),
                                                  padding: const EdgeInsets.all(4),
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(Get.width),
                                                    child: Image.asset('lib/assets/img/logo_2.png', width: Get.width),
                                                  ),
                                                ),
                                              );
                                            }
                                          ),
                                        );
                                      }
                                    }
                                    return child;
                                  }
                                );
                              }
                            );
                          }
                        );
                      }
                    ),
                  ],
                ),
                Positioned.fill(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Obx(() => ChatController.linkDescricaoModel.value == null ? const SizedBox() : Container(
                        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                        child: Material(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white,
                          elevation: 3,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Row(
                              children: [
                                ChatController.linkDescricaoModel.value!.imgUrl == null || 
                                ChatController.linkDescricaoModel.value!.imgUrl?.isEmpty == true ? const SizedBox() : Image.network(ChatController.linkDescricaoModel.value!.imgUrl!, width: 70, height: 70, fit: BoxFit.cover),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(ChatController.linkDescricaoModel.value!.titulo, style: const TextStyle(color: Colors.black)),
                                      const SizedBox(height: 4),
                                      Text(ChatController.linkDescricaoModel.value!.descricao, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    ChatController.linkDescricaoModel.value = null;
                                    ChatController.linkDescricaoModel.refresh();
                                  },
                                  icon: const Icon(Icons.close),
                                )
                              ],
                            ),
                          ),
                        ),
                      )),
                      Padding(
                        padding: EdgeInsets.only(left: 16, right: 16, bottom: 8 + MediaQuery.of(context).padding.bottom),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Material(
                                borderRadius: BorderRadius.circular(100),
                                elevation: 3,
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minHeight: 48
                                  ),
                                  child: Obx(() => AudioController.isGravandoAudio.value == true ? const AudioRecoderComponent() : Row(
                                    children: [
                                      SizedBox(
                                        width: 40,
                                        child: TextButton(
                                          style: TextButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(Get.width)
                                            ),
                                          ),
                                          onPressed: () {
                                            ChatController.group.value = ChatController.emujiGroup.first.en!;
                                            ChatController.showEmoji.value = !ChatController.showEmoji.value;
                                          },
                                          child: Obx(() => Icon(ChatController.showEmoji.value == false ? Icons.emoji_emotions_outlined : Icons.keyboard, color: Colors.grey)),
                                        ),
                                      ),
                                      Expanded(
                                        child: TextField(
                                          controller: ChatController.msgController,
                                          scrollController: ChatController.msgScrollController,
                                          style: const TextStyle(color: Colors.black),
                                          decoration: InputDecoration(
                                            enabledBorder: InputBorder.none,
                                            border: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            filled: true,
                                            fillColor: Colors.transparent,
                                            hintText: AppLanguage.lang('digite_aqui'),
                                          ),
                                          maxLines: 3,
                                          minLines: 1,
                                          onChanged: (String? text) async {
                                            ChatController.showBtnAudio.value = text!.trim().isEmpty;
                                            
                                            if(text.split('\n').length > 1) {
                                              ChatController.sendMsg(isFirst: totMsgs == 0);
                                              return;
                                            }
                
                                            String? url = ChatController.extractURL(text);
                                            if(url != null) {
                                              ChatController.linkDescricaoModel.value = await ChatRepository.fetchDescription(url);
                                              ChatController.linkDescricaoModel.refresh();
                                            }
                                          },
                                        ),
                                      ),
                                      SizedBox(
                                        width: 40,
                                        child: Obx(() => TextButton(
                                          style: TextButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(Get.width)
                                            ),
                                            backgroundColor: ChatController.showModalCamera.value == true ? AppTheme.materialColor.shade100 : Colors.transparent
                                          ),
                                          onPressed: () {
                                            ChatController.showModalFiles.value = false;
                                            ChatController.showModalCamera.value = !ChatController.showModalCamera.value;
                                          },
                                          child: const Icon(Icons.camera_alt_outlined, color: Colors.grey),
                                        )),
                                      ),
                                      SizedBox(
                                        width: 40,
                                        child: Obx(() => TextButton(
                                          style: TextButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(Get.width)
                                            ),
                                            backgroundColor: ChatController.showModalFiles.value == true ? AppTheme.materialColor.shade100 : Colors.transparent
                                          ),
                                          onPressed: () {
                                            ChatController.showModalCamera.value = false;
                                            ChatController.showModalFiles.value = !ChatController.showModalFiles.value;
                                          },
                                          child: const Icon(Icons.attach_file, color: Colors.grey),
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
                                  if(ChatController.showBtnAudio.value == false) {
                                    ChatController.sendMsg(isFirst: totMsgs == 0);
                                  } else {
                                    if(AudioController.isGravandoAudio.value == false) {
                                      AudioController.isGravandoAudio.value = true;
                                    } else {
                                      AudioController.isGravandoAudio.value = false;
                                      AudioController.stop();
                                    }
                                  }
                                },
                                child: Material(
                                  color: AppTheme.materialColor,
                                  borderRadius: BorderRadius.circular(100),
                                  elevation: 3,
                                  child: SizedBox(
                                    width: 52, height: 52,
                                    child: Obx(() => Icon(
                                      ChatController.showBtnAudio.value == false ? Icons.send : (AudioController.isGravandoAudio.value == true ? Icons.stop : Icons.mic_rounded)
                                    )),
                                  ),
                                )
                              ),
                            )
                          ],
                        ),
                      ),
                      Obx(() => ChatController.showEmoji.value == false ? const SizedBox() : _emoji()),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 0,
                  child: Obx(() => ChatController.idItensToTrash.isEmpty ? const SizedBox() : Container(
                    decoration: const BoxDecoration(
                      color: Colors.white
                    ),
                    width: Get.width,
                    height: 62,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.delete_outline),
                            const SizedBox(width: 6),
                            Text('${AppLanguage.lang('deletar')} ${ChatController.idItensToTrash.length == 1 ? '1 ${AppLanguage.lang('msg')}' : '${ChatController.idItensToTrash.length} ${AppLanguage.lang('msgs')}'}'),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () {
                            ChatRepository.deletarItens(itens: ChatController.idItensToTrash.map((e) => '$e').toList());
                            ChatController.idItensToTrash.clear();
                          },
                          child: Text(AppLanguage.lang('deletar')),
                        )
                      ],
                    ),
                  ),
                )),
                // Componente de convites do Propósito
                const Positioned(
                  top: 100,
                  left: 0,
                  right: 0,
                  child: PurposeInvitesComponent(),
                ),
              ],
            ),
          );
        }
      ),
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
            if(!snapshot.hasData) {
              return Padding(
                padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8 + MediaQuery.of(context).padding.bottom),
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
                      for(var group in ChatController.emujiGroup.where((element) => element.imgAssets != null).toList())
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: group.en == ChatController.group.value ? AppTheme.materialColor : Colors.transparent, width: 3))
                          ),
                          padding: const EdgeInsets.only(bottom: 8, top: 12),
                          child: Center(
                            child: InkWell(
                              onTap: () => ChatController.group.value = group.en!,
                              child: Image.asset(group.imgAssets!, width: 24),
                            ),
                          ),
                        )
                      ),
                    ],
                  )),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(top: 16, bottom: 16 + MediaQuery.of(context).padding.bottom),
                    child: SizedBox(
                      width: Get.width,
                      child: Obx(() => Wrap(
                        children: [
                          
                          for(var emoji in all)
                          if(emoji.group == ChatController.group.value)
                          SizedBox(
                            width: Get.width / 9,
                            child: Center(
                              child: InkWell(
                                onTap: () => ChatController.incrementEmoji(emoji),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 3),
                                  child: Text(emoji.char!, style: GoogleFonts.notoColorEmoji(fontSize: 24)),
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
          }
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
                        border: Border.all(color: AppTheme.materialColor),
                        borderRadius: BorderRadius.circular(8),
                        color: AppTheme.materialColor.shade50
                      ),
                      width: 55, height: 45,
                      child: Icon(Icons.photo_size_select_actual_rounded, color: AppTheme.materialColor),
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
                        color: AppTheme.materialColor.shade50
                      ),
                      width: 55, height: 45,
                      child: Icon(Icons.camera_alt, color: AppTheme.materialColor),
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
                        color: AppTheme.materialColor.shade50
                      ),
                      width: 55, height: 45,
                      child: Icon(Icons.insert_drive_file_rounded, color: AppTheme.materialColor),
                    ),
                    const SizedBox(height: 6),
                    Text(AppLanguage.lang('arquivos'), style: const TextStyle(fontSize: 13))
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
                  if(r == true) {
                    _showImageEdit();
                  }
                },
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.materialColor),
                        borderRadius: BorderRadius.circular(8),
                        color: AppTheme.materialColor.shade50
                      ),
                      width: 55, height: 45,
                      child: Icon(Icons.camera_alt, color: AppTheme.materialColor),
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
                        color: AppTheme.materialColor.shade50
                      ),
                      width: 55, height: 45,
                      child: Icon(Icons.video_camera_back_rounded, color: AppTheme.materialColor),
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
                      Image.memory(ChatController.fotoData!, fit: BoxFit.contain),
                      Container(
                        width: 40, height: 40,
                        margin: const EdgeInsets.only(top: 16, left: 16),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100)
                            ),
                            backgroundColor: Colors.black12,
                            padding: const EdgeInsets.all(0)
                          ),
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
                  const SizedBox(height: 52+32)
                ],
              ),
            ),
            Positioned.fill(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            child: TextField(
                              controller: ChatController.legendaController,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                hintText: '${AppLanguage.lang('adicione_uma_legenda')}...',
                                enabledBorder: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(50)),
                                  borderSide: BorderSide.none
                                ),
                                border: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(50)),
                                  borderSide: BorderSide.none
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(50)),
                                  borderSide: BorderSide.none
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 52, height: 52,
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
      isScrollControlled: true
    );
  }

  showAdminOpts(UsuarioModel user) => Get.bottomSheet(
    Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          color: Colors.white,
          child: Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.black12))
                ),
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
                title: const Text('📜 Certificações Espirituais'),
                trailing: const Icon(Icons.keyboard_arrow_right),
                leading: const Icon(Icons.verified_user),
                onTap: () {
                  Get.back();
                  // Usando painel simples temporariamente para diagnóstico
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SimpleCertificationPanel(),
                    ),
                  );
                },
              ),
              
              // DEBUG TEMPORÁRIO: Para investigar o problema
              const Divider(),
              ListTile(
                title: const Text('🔧 Debug User State'),
                trailing: const Icon(Icons.bug_report),
                leading: const Icon(Icons.settings),
                onTap: () async {
                  Get.back();
                  // REMOVIDO: await DebugUserState.printCurrentUserState();
                  // REMOVIDO: await DebugUserState.fixUserSexo();
                  
                  Get.snackbar(
                    'Debug',
                    'Estado do usuário verificado! Verifique o console.',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.green[100],
                    colorText: Colors.green[800],
                    duration: const Duration(seconds: 3),
                  );
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
    )
  );

  addNotification() {
    final msgControl = TextEditingController();
    final tituloControl = TextEditingController();
    final temDistincaoDeSexo = false.obs;
    final temDistincaoDeIdioma = false.obs;
    final idiomasSelecionados = <String>[].obs; // pt, en, es
    final masculinos = [''].obs;
    final femininos = [''].obs;

    Get.defaultDialog(
      title: 'Notificação',
      content: Container(
        constraints: BoxConstraints(
          maxHeight: Get.height * 0.7
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: TextField(
                  controller: tituloControl,
                  decoration: const InputDecoration(
                    label: Text('Título')
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: TextField(
                  controller: msgControl,
                  decoration: const InputDecoration(
                    label: Text('Mensagem')
                  ),
                  maxLines: 2,
                ),
              ),
              
              // Filtro de Idioma
              Row(
                children: const [
                  Text('Filtrar por idioma?'),
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
                        onPressed: () {
                          temDistincaoDeIdioma.value = false;
                          idiomasSelecionados.clear();
                        },
                        label: const Text('Não'),
                        icon: Icon(temDistincaoDeIdioma.value == false ? Icons.check_circle : Icons.circle_outlined),
                      ),
                    ),
                    SizedBox(
                      height: 36,
                      child: OutlinedButton.icon(
                        onPressed: () => temDistincaoDeIdioma.value = true,
                        label: const Text('Sim'),
                        icon: Icon(temDistincaoDeIdioma.value == true ? Icons.check_circle : Icons.circle_outlined),
                      ),
                    )
                  ],
                )),
              ),
              
              // Seleção de idiomas
              Obx(() => temDistincaoDeIdioma.value == false ? const SizedBox() : Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Selecione os idiomas:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('🇧🇷 Português'),
                          selected: idiomasSelecionados.contains('pt'),
                          onSelected: (selected) {
                            if (selected) {
                              idiomasSelecionados.add('pt');
                            } else {
                              idiomasSelecionados.remove('pt');
                            }
                          },
                        ),
                        FilterChip(
                          label: const Text('🇺🇸 English'),
                          selected: idiomasSelecionados.contains('en'),
                          onSelected: (selected) {
                            if (selected) {
                              idiomasSelecionados.add('en');
                            } else {
                              idiomasSelecionados.remove('en');
                            }
                          },
                        ),
                        FilterChip(
                          label: const Text('🇪🇸 Español'),
                          selected: idiomasSelecionados.contains('es'),
                          onSelected: (selected) {
                            if (selected) {
                              idiomasSelecionados.add('es');
                            } else {
                              idiomasSelecionados.remove('es');
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              )),
              
              // Filtro de Sexo
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
                        icon: Icon(temDistincaoDeSexo.value == false ? Icons.check_circle : Icons.circle_outlined),
                      ),
                    ),
                    SizedBox(
                      height: 36,
                      child: OutlinedButton.icon(
                        onPressed: () => temDistincaoDeSexo.value = true,
                        label: const Text('Sim'),
                        icon: Icon(temDistincaoDeSexo.value == true ? Icons.check_circle : Icons.circle_outlined),
                      ),
                    )
                  ],
                )),
              ),
              Obx(() => temDistincaoDeSexo.value == false ? const SizedBox() : Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    Obx(() => Table(
                      border: TableBorder.all(color: Colors.black26),
                      children: [
                        const TableRow(
                          children: [
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Masculino', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Feminino', style: TextStyle(fontWeight: FontWeight.bold)),
                            )
                          ]
                        ),
                        for(var i = 0; i < masculinos.length; i++)
                        TableRow(
                          children: [
                            TextField(
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(horizontal: 8),
                                hintText: 'Digite aqui...'
                              ),
                              onChanged: (String? text) {
                                masculinos[i] = text!;
                              },
                            ),
                            TextField(
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(horizontal: 8),
                                hintText: 'Digite aqui...'
                              ),
                              onChanged: (String? text) {
                                femininos[i] = text!;
                              },
                            ),
                          ]
                        )
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
                    if(titulo.isEmpty || msg.isEmpty) {
                      Get.rawSnackbar(message: 'Preencha todos os campos!');
                      return;
                    }
                    
                    // Validar filtro de idioma
                    if(temDistincaoDeIdioma.value == true && idiomasSelecionados.isEmpty) {
                      Get.rawSnackbar(message: 'Selecione pelo menos um idioma!');
                      return;
                    }
                    
                    Get.back();
                    String tituloF = titulo.replaceAll('', '');
                    String msgF = msg.replaceAll('', '');
                    for (var i = 0; i < masculinos.length; i++) {
                      tituloF = tituloF.replaceAll(masculinos[i], femininos[i]);
                    }
                    for (var i = 0; i < masculinos.length; i++) {
                      msgF = msgF.replaceAll(masculinos[i], femininos[i]);
                    }
                    
                    // Enviar notificações com filtros
                    if(temDistincaoDeIdioma.value == true) {
                      // Com filtro de idioma
                      for (var idioma in idiomasSelecionados) {
                        if(temDistincaoDeSexo.value == true) {
                          // Com filtro de sexo E idioma
                          await NotificationController.sendNotificationToTopic(
                            titulo: titulo, 
                            msg: msg, 
                            abrirStories: false, 
                            topico: 'sexo_m_${idioma}'
                          );
                          await NotificationController.sendNotificationToTopic(
                            titulo: tituloF, 
                            msg: msgF, 
                            abrirStories: false, 
                            topico: 'sexo_f_${idioma}'
                          );
                        } else {
                          // Apenas filtro de idioma
                          await NotificationController.sendNotificationToTopic(
                            titulo: titulo, 
                            msg: msg, 
                            abrirStories: false, 
                            topico: 'idioma_${idioma}'
                          );
                        }
                      }
                    } else {
                      // Sem filtro de idioma
                      if(temDistincaoDeSexo.value == true) {
                        // Apenas filtro de sexo
                        await NotificationController.sendNotificationToTopic(
                          titulo: titulo, 
                          msg: msg, 
                          abrirStories: false, 
                          topico: 'sexo_m'
                        );
                        await NotificationController.sendNotificationToTopic(
                          titulo: tituloF, 
                          msg: msgF, 
                          abrirStories: false, 
                          topico: 'sexo_f'
                        );
                      } else {
                        // Sem filtros
                        await NotificationController.sendNotificationToTopic(
                          titulo: titulo, 
                          msg: msg, 
                          abrirStories: false
                        );
                      }
                    }
                    
                    Get.rawSnackbar(
                      message: 'Notificação enviada com sucesso!',
                      backgroundColor: Colors.green,
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                  child: const Text('Enviar'),
                ),
              )
            ],
          ),
        ),
      )
    );
  }
  

}