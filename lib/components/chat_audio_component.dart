import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:whatsapp_chat/models/usuario_model.dart';
import 'container_chat_item_component.dart';
import '/models/chat_model.dart';
import 'audio_player_component.dart';

class ChatAudioComponent extends StatelessWidget {
  final ChatModel item;
  final bool showArrow;
  final UsuarioModel usuarioModel;

  const ChatAudioComponent(
      {super.key,
      required this.item,
      required this.showArrow,
      required this.usuarioModel});

  @override
  Widget build(BuildContext context) {
    return ContainerChatItemComponent(
        item: item,
        userName: usuarioModel.nome!,
        showArrow: showArrow,
        isAdmin: usuarioModel.isAdmin!,
        username: usuarioModel.username,
        userSexo: usuarioModel.sexo, // Passar o sexo do usuário
        child: Container(
          width: Get.width * 0.7,
          margin: const EdgeInsets.only(bottom: 8),
          child: item.isLoading == true
              ? Container(
                  height: 50,
                  decoration:
                      BoxDecoration(border: Border.all(color: Colors.white30)),
                  child: const Center(
                      child: CircularProgressIndicator(
                    color: Colors.white,
                  )),
                )
              : AudioPlayerComponent(
                  audioUrl: item.fileUrl!,
                  fileName: item.fileName!,
                  width: Get.width * 0.7,
                  user: usuarioModel,
                ),
        ));
  }
}
