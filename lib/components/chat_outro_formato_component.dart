import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:whatsapp_chat/models/usuario_model.dart';
import '/controllers/chat_controller.dart';
import 'container_chat_item_component.dart';
import '/models/chat_model.dart';

class ChatOutroFormatoComponent extends StatelessWidget {
  final ChatModel item;
  final bool showArrow;
  final UsuarioModel usuarioModel;

  const ChatOutroFormatoComponent(
      {super.key,
      required this.item,
      required this.showArrow,
      required this.usuarioModel});

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
        child: InkWell(
          onTap: () async {
            if (item.fileExtension?.toLowerCase() == 'pdf') {
              ChatController.openFile(item.fileUrl!, item.fileName!, item.id!);
            } else {
              await launchUrl(Uri.parse(item.fileUrl!),
                  mode: LaunchMode.externalApplication);
            }
          },
          child: item.fileExtension?.toLowerCase() == 'pdf'
              ? Row(
                  children: [
                    Image.asset('lib/assets/img/pdf.png', width: 20),
                    const SizedBox(width: 6),
                    Flexible(
                        child: Text('${item.fileName}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 15))),
                  ],
                )
              : Row(
                  children: [
                    Flexible(
                        child: Text('${item.fileName}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 15))),
                    const SizedBox(width: 6),
                    Image.asset('lib/assets/img/download.png',
                        width: 17, color: Colors.white)
                  ],
                ),
        ),
      ),
    );
  }
}
