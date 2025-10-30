import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:whatsapp_chat/models/usuario_model.dart';
import 'package:whatsapp_chat/repositories/chat_repository.dart';
import '../models/progress_model.dart';
import 'container_chat_item_component.dart';
import '/models/chat_model.dart';
import 'video_player.dart';

class ChatVideoComponent extends StatelessWidget {
  final ChatModel item;
  final bool showArrow;
  final UsuarioModel usuarioModel;

  const ChatVideoComponent(
      {super.key,
      required this.item,
      required this.showArrow,
      required this.usuarioModel});

  @override
  Widget build(BuildContext context) {
    double w = Get.height * 0.4;
    return ContainerChatItemComponent(
        item: item,
        userName: usuarioModel.nome!,
        isAdmin: usuarioModel.isAdmin!,
        username: usuarioModel.username,
        userSexo: usuarioModel.sexo, // Passar o sexo do usuário
        showArrow: showArrow,
        child: Container(
            width: w,
            margin: const EdgeInsets.only(bottom: 8),
            child: Obx(() => ChatRepository.listObs.value
                        .where((element) => element.id == item.id)
                        .toList()
                        .isNotEmpty ||
                    item.isLoading != false
                ? Container(
                    height: Get.height * 0.25,
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.white30)),
                    child: Center(child: Builder(builder: (context) {
                      List<ProgressModel> itens = ChatRepository.listObs.value
                          .where((element) => element.id == item.id)
                          .toList();
                      return CircularPercentIndicator(
                        radius: 30.0,
                        lineWidth: 3.0,
                        animation: true,
                        percent: itens.isEmpty ? 0 : itens.first.progress,
                        progressColor: Colors.white,
                        backgroundColor: Colors.white38,
                      );
                    })),
                  )
                : VideoPlayer(
                    url: item.fileUrl!,
                    videoThumbnail: item.videoThumbnail,
                    isLoacal: false,
                    width: w))));
  }
}
