import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:photo_view/photo_view.dart';
import 'package:whatsapp_chat/models/usuario_model.dart';
import '../models/progress_model.dart';
import '../repositories/chat_repository.dart';
import 'container_chat_item_component.dart';
import '/models/chat_model.dart';

class ChatImgComponent extends StatelessWidget {

  final ChatModel item;
  final bool showArrow;
  final UsuarioModel usuarioModel;

  const ChatImgComponent({super.key, required this.item, required this.showArrow, required this.usuarioModel});

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
        width: Get.width * 0.6,
        height: Get.width * 0.7,
        margin: const EdgeInsets.only(bottom: 8),
        child: Obx(() => ChatRepository.listObs.value.where((element) => element.id == item.id).toList().isNotEmpty || item.isLoading != false ? Container(
          height: Get.height * 0.25,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white30)
          ),
          child: Center(child: Builder(
            builder: (context) {
              List<ProgressModel> itens = ChatRepository.listObs.value.where((element) => element.id == item.id).toList();
              return CircularPercentIndicator(
                  radius: 30.0,
                  lineWidth: 3.0,
                  animation: true,
                  percent: itens.isEmpty ? 0 : itens.first.progress,
                  progressColor: Colors.white,
                  backgroundColor: Colors.white38,
                );
              }
            )
          ),
        ) : InkWell(
          onTap: () {
            FocusScope.of(context).unfocus();
            _showImgZoom(imgUrl: item.fileUrl!);
          },
          child: CachedNetworkImage(
            imageUrl: item.fileUrl!,
            fit: BoxFit.cover,
            placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.white)),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          )
        )),
      )
    );
  }

  _showImgZoom({
    required String imgUrl
  }) {
    Get.bottomSheet(
      Padding(
        padding: const EdgeInsets.only(
          top: 20
        ),
        child: Stack(
          children: [
            PhotoView(
              imageProvider: NetworkImage(imgUrl),
            ),
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
                onPressed: () => Get.back(),
                child: const Icon(Icons.close, color: Colors.white),
              ),
            )
          ],
        ),
      ),
      isDismissible: true,
      isScrollControlled: true
    );
  }
}