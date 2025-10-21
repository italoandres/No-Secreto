import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:whatsapp_chat/locale/language.dart';
import 'package:whatsapp_chat/models/usuario_model.dart';
import 'package:whatsapp_chat/repositories/usuario_repository.dart';

import '../controllers/completar_perfil_controller.dart';

class EditarCapaComponent extends StatefulWidget {
  final UsuarioModel user;
  const EditarCapaComponent({super.key, required this.user});

  @override
  State<EditarCapaComponent> createState() => _EditarCapaComponentState();
}

class _EditarCapaComponentState extends State<EditarCapaComponent> {

  @override
  void initState() {
    CompletarPerfilController.imgBgPath.value = '';
    CompletarPerfilController.imgBgData = null;
    CompletarPerfilController.imgPath.value = '';
    CompletarPerfilController.imgData = null;
    super.initState();
  }
  @override
  Widget build(BuildContext context){
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black12),
                            borderRadius: BorderRadius.circular(Get.width)
                          ),
                          width: 120,
                          height: 120,
                          margin: const EdgeInsets.only(bottom: 35/2.5),
                          child: InkWell(
                            onTap: () => CompletarPerfilController.changeImg(),
                            borderRadius: BorderRadius.circular(Get.width),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(Get.width),
                              child: Obx(() => CompletarPerfilController.imgPath.value.isEmpty ? (
                                widget.user.imgUrl == null ? Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Image.asset('lib/assets/img/user.png', color: Colors.black12),
                                ) : ClipRRect(
                                  borderRadius: BorderRadius.circular(1000),
                                  child: Image.network(
                                    widget.user.imgUrl!, 
                                    fit: BoxFit.cover, 
                                    width: 120,
                                    height: 120,
                                  )
                                )
                              ) : Image.memory(CompletarPerfilController.imgData!, fit: BoxFit.cover))
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: (120 / 2) - (35/2),
                          child: SizedBox(
                            width: 35, height: 35,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(Get.width)
                                ),
                                padding: const EdgeInsets.all(0)
                              ),
                              onPressed: () => CompletarPerfilController.changeImg(),
                              child: const Icon(Icons.edit, size: 15, color: Colors.white),
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
              Text('${AppLanguage.lang('ola')}, ${widget.user.nome?.split(' ')[0]}!', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 17)),
              Text(AppLanguage.lang('msg_editar_papel'), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Container(
                margin: const EdgeInsets.only(bottom: 32),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Obx(() => CompletarPerfilController.imgBgPath.value.isEmpty ? (
                          widget.user.imgBgUrl == null ? Opacity(opacity: 0.3, child: Image.asset('lib/assets/img/bg_wallpaper.jpg', fit: BoxFit.cover)) : Image.network(widget.user.imgBgUrl!, fit: BoxFit.cover)
                        ) : Image.memory(CompletarPerfilController.imgBgData!, fit: BoxFit.cover)),
                      )
                    ),
                    InkWell(
                      onTap: () => CompletarPerfilController.changeImgBg(),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: Get.width - 32,
                        height: (Get.width - 32) / 2,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black12),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.black12
                        ),
                        child: Center(
                          child: Container(
                            height: 50,  
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(Get.width),
                              color: Colors.white10,
                              border: Border.all(color: Colors.white30),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: [
                                const Icon(Icons.add_photo_alternate_outlined),
                                Text(AppLanguage.lang('select_img'))
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 52,
                width: Get.width,
                margin: const EdgeInsets.only(bottom: 16),
                child: ElevatedButton(
                  onPressed: () {
                    Get.back();
                    UsuarioRepository.completarPerfil(
                      imgBgData: CompletarPerfilController.imgBgData,
                      imgData: CompletarPerfilController.imgData,
                      sexo: widget.user.sexo!
                    );
                  },
                  child: Text(AppLanguage.lang('salvar')),
                ),
              ),
              SizedBox(
                height: 38,
                width: Get.width,
                child: TextButton(
                  onPressed: () => Get.back(),
                  child: Text(AppLanguage.lang('cancelar')),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}