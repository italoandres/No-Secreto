import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:whatsapp_chat/components/audio_player_component.dart';
import 'package:whatsapp_chat/locale/language.dart';
import 'package:whatsapp_chat/models/usuario_model.dart';
import 'package:whatsapp_chat/repositories/usuario_repository.dart';

class PreviewAudioGravacaoComponent extends StatefulWidget {

  final String audioPath;
  const PreviewAudioGravacaoComponent({super.key, required this.audioPath});

  @override
  State<PreviewAudioGravacaoComponent> createState() => _PreviewAudioGravacaoComponentState();
}

class _PreviewAudioGravacaoComponentState extends State<PreviewAudioGravacaoComponent> {
  final legendaController = TextEditingController();
  @override
  Widget build(BuildContext context){
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: Get.width,
          color: Colors.white,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.black12))
                ),
                child: ListTile(
                  title: Text(AppLanguage.lang('enviar_arquivo')),
                  leading: IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: StreamBuilder<UsuarioModel?>(
                  stream: UsuarioRepository.getUser(),
                  builder: (context, snapshot) {
                    if(!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    UsuarioModel user = snapshot.data!;
                    
                    return Column(
                      children: [
                        AudioPlayerComponent(
                          audioUrl: widget.audioPath, 
                          fileName: '', 
                          width: Get.width, user: user
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                child: TextField(
                                  controller: legendaController,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                    hintText: AppLanguage.lang('add_legenda'),
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
                                  
                                  Get.back();
                                },
                                child: const Icon(Icons.send),
                              ),
                            )
                          ],
                        ),
                      ],
                    );
                  }
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}