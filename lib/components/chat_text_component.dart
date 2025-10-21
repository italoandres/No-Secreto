import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:emoji_regex/emoji_regex.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/usuario_model.dart';
import 'container_chat_item_component.dart';
import '/models/chat_model.dart';

class ChatTextComponent extends StatelessWidget {

  final ChatModel item;
  final bool showArrow;
  final UsuarioModel usuarioModel;
  final Color textColor;

  const ChatTextComponent({super.key, required this.item, required this.showArrow, required this.usuarioModel, required this.textColor});

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
              item.linkDescricaoModel == null ? const SizedBox() : Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => launchUrl(
                    Uri.parse(item.linkDescricaoModel!.link!),
                    mode: LaunchMode.externalApplication
                  ),
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
                            item.linkDescricaoModel!.imgUrl?.isEmpty == true ? const SizedBox() : Image.network(item.linkDescricaoModel!.imgUrl!, width: 70, height: 70, fit: BoxFit.cover),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.linkDescricaoModel!.titulo, style: const TextStyle(color: Colors.white)),
                                  const SizedBox(height: 4),
                                  Text(item.linkDescricaoModel!.descricao, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    ),
                  ),
                ),
              ),
              RichText(text: TextSpan(
                style: TextStyle(color: textColor, fontSize: 15),
                children: [
                  for(var i = 0; i < item.text!.split(' ').length; i++)
                  TextSpan(
                    children: [
                      TextSpan(
                        children: splitStringWithLinks(item.text!.split(' ')[i]).map((e) => TextSpan(
                          children: [
                            TextSpan(
                              style: emojiRegex().allMatches(e).isNotEmpty ? GoogleFonts.notoColorEmoji(color: e.isURL ? Colors.blue : textColor) : TextStyle(color: e.isURL ? Colors.blue : textColor),
                              text: e,
                              recognizer: TapGestureRecognizer()..onTap = () {
                                if(e.isURL) {
                                  launchUrl(
                                    Uri.parse(e),
                                    mode: LaunchMode.externalApplication
                                  );
                                }
                              },
                            ),
                            const TextSpan(
                              text: ' '
                            )
                          ]
                        )).toList())
                    ]
                  )
                ]
              ))
            ],
          ),
      ),
    );
  }

  List<String> splitStringWithLinks(String text) {
    final RegExp linkRegExp = RegExp(r'http[s]?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\\(\\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+');
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
}