
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:whatsapp_chat/controllers/chat_controller.dart';
import 'package:whatsapp_chat/locale/language.dart';
import 'package:whatsapp_chat/repositories/chat_repository.dart';
import '/models/chat_model.dart';
import '/models/usuario_model.dart';
import '/theme.dart';

class ContainerChatItemComponent extends StatefulWidget {

  final ChatModel item;
  final bool showArrow;
  final Widget child;
  final String userName;
  final bool isAdmin;
  final String? username;
  final UserSexo? userSexo; // Adicionar sexo do usuário
  const ContainerChatItemComponent({super.key, required this.item, required this.showArrow, required this.child, required this.userName, required this.isAdmin, this.username, this.userSexo});

  @override
  State<ContainerChatItemComponent> createState() => _ContainerChatItemComponentState();
}

class _ContainerChatItemComponentState extends State<ContainerChatItemComponent> {
  
  // Método para determinar a cor do nome baseada no sexo
  Color _getNameColor() {
    if (widget.userSexo == UserSexo.feminino) {
      return const Color(0xFFfc6aeb); // Rosa para feminino
    } else if (widget.userSexo == UserSexo.masculino) {
      return const Color(0xFF39b9ff); // Azul para masculino
    } else {
      return const Color(0xFF1ebea5); // Cor padrão (verde)
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if(widget.item.orginemAdmin == true) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      GestureDetector(
                        onLongPress: () {
                          ChatController.idItensToTrash.add(widget.item.id);
                        },
                        onTap: () {
                          if(ChatController.idItensToTrash.isNotEmpty) {
                            ChatController.idItensToTrash.add(widget.item.id);
                          }
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomLeft: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                            color: AppTheme.chatBalaoColor
                          ),
                          padding: const EdgeInsets.only(
                            left: 12, right: 12, top: 12, bottom: 16
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(right: 16, bottom: 8),
                                child: InkWell(
                                  onDoubleTap: () => _alterarData(), 
                                  child: Text(AppLanguage.lang('pai'), overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white))
                                )
                              ),
                              Stack(
                                children: [
                                  Container(
                                    constraints: BoxConstraints(
                                      minWidth: 150,
                                      maxWidth: Get.width * 0.6
                                    ),
                                    child: widget.child
                                  ),
                                  Positioned.fill(
                                    child: Obx(() => ChatController.idItensToTrash.isEmpty ? const SizedBox() : Container(
                                      color: Colors.transparent,
                                    ))
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 6,
                        right: 12,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(DateFormat('HH:mm').format(widget.item.dataCadastro!.toDate()), style: const TextStyle(fontSize: 10, color: Colors.white70)),
                            const SizedBox(width: 4),
                            Image.asset('lib/assets/img/read.png', width: 15, color: AppTheme.materialColor)
                          ],
                        ),
                      )
                    ],
                  ),
                  widget.showArrow == false ? const SizedBox(width: 8) : Image.asset('lib/assets/img/mini_arrow.png', width: 8, color: AppTheme.chatBalaoColor),
                ],
              ),
            ),
            Positioned.fill(
              child: Obx(() => !ChatController.idItensToTrash.contains(widget.item.id) ? const SizedBox() : InkWell(
                onTap: () => ChatController.idItensToTrash.removeWhere((element) => element == widget.item.id),
                child: Container(
                  color: AppTheme.materialColor.shade200,
                ),
              )),
            )
          ],
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                widget.showArrow == false ? const SizedBox(width: 8) : Image.asset('lib/assets/img/mini_arrow_2.png', width: 8, color: AppTheme.chatBalaoColor),
                Stack(
                  children: [
                    GestureDetector(
                      onLongPress: () {
                        ChatController.idItensToTrash.add(widget.item.id);
                      },
                      onTap: () {
                        if(ChatController.idItensToTrash.isNotEmpty) {
                          ChatController.idItensToTrash.add(widget.item.id);
                        }
                      },
                      child: Container(
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                          color: AppTheme.chatBalaoColor
                        ),
                        padding: const EdgeInsets.only(
                          left: 12, right: 12, top: 12, bottom: 16
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(right: 16, bottom: 8),
                              child: InkWell(
                                onDoubleTap: () => _alterarData(),
                                child: Text(
                                  widget.username != null && widget.username!.isNotEmpty 
                                    ? '${widget.userName} (@${widget.username})'
                                    : widget.userName, 
                                  overflow: TextOverflow.ellipsis, 
                                  style: TextStyle(fontWeight: FontWeight.w500, color: _getNameColor())
                                )
                              )
                            ),
                            Stack(
                              children: [
                                Container(
                                  constraints: BoxConstraints(
                                    minWidth: 150,
                                    maxWidth: Get.width * 0.6
                                  ),
                                  child: widget.child
                                ),
                                Positioned.fill(
                                  child: Obx(() => ChatController.idItensToTrash.isEmpty ? const SizedBox() : Container(
                                    color: Colors.transparent,
                                  ))
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 12,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('${AppLanguage.lang('visualizou_as')} ${DateFormat('HH:mm').format(widget.item.dataCadastro!.toDate())}', style: const TextStyle(fontSize: 10, color: Colors.white70)),
                          const SizedBox(width: 4),
                          Image.asset('lib/assets/img/read.png', width: 15, color: AppTheme.materialColor)
                        ],
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: Obx(() => !ChatController.idItensToTrash.contains(widget.item.id) ? const SizedBox() : InkWell(
              onTap: () => ChatController.idItensToTrash.removeWhere((element) => element == widget.item.id),
              child: Container(
                color: AppTheme.materialColor.shade200,
              ),
            )),
          )
        ],
      ),
    );
  }

  _alterarData() async {
    if(widget.isAdmin != true) {
      return;
    }
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: widget.item.dataCadastro!.toDate(),
      locale: const Locale('pt', 'BR'),
      firstDate:DateTime(2000),
      lastDate: DateTime(2101)
    );

    if(pickedDate != null) {
      
      Future.delayed(Duration.zero, () async {
        
        TimeOfDay? newTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: widget.item.dataCadastro!.toDate().hour, minute: widget.item.dataCadastro!.toDate().minute),
        );

        if(newTime != null) {
          DateTime newDate = pickedDate.add(Duration(hours: newTime.hour, minutes: newTime.minute, seconds: widget.item.dataCadastro!.toDate().second));

          final inputController = TextEditingController(text: DateFormat('dd/MM/y HH:mm:ss').format(newDate));

          Get.defaultDialog(
            title: AppLanguage.lang('salvar'),
            content: TextField(
              autofocus: true,
              textAlign: TextAlign.center,
              controller: inputController,
              inputFormatters: [
                MaskTextInputFormatter(
                  initialText: DateFormat('dd/MM/y HH:mm:ss').format(newDate),
                  mask: '##/##/#### ##:##:##', 
                  filter: { "#": RegExp(r'[0-9]') },
                )
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Get.back(),
                child: Text(AppLanguage.lang('cancelar')),
              ),
              ElevatedButton(
                onPressed: () {
                  Get.back();
                  DateTime tempDate = DateFormat("dd/MM/y HH:mm:ss").parse(inputController.text);
                  ChatRepository.updateDataCadastroItem(id: widget.item.id!, data: tempDate);
                },
                child: Text(AppLanguage.lang('salvar')),
              ),
            ]
          );
        }
      });
    }
  }
}

class DateTimeMask extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Remove qualquer formatação anterior
    String unmaskedText = newValue.text.replaceAll(RegExp('[^0-9]'), '');

    // Verifica se o texto é vazio
    if (unmaskedText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Formata o texto no formato desejado
    String formattedText = '';
    for (int i = 0; i < unmaskedText.length; i++) {
      if (i == 2 || i == 4) {
        formattedText += '/';
      } else if (i == 6) {
        formattedText += ' ';
      } else if (i == 8 || i == 10) {
        formattedText += ':';
      }
      formattedText += unmaskedText[i];
    }

    // Retorna o novo valor formatado
    return newValue.copyWith(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
