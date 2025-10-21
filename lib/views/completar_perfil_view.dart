import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:whatsapp_chat/controllers/login_controller.dart';
import 'package:whatsapp_chat/locale/language.dart';
import '/controllers/completar_perfil_controller.dart';
import '/models/usuario_model.dart';
import '/repositories/usuario_repository.dart';

class CompletarPerfilView extends StatelessWidget {

  final UsuarioModel user;
  const CompletarPerfilView({super.key, required this.user});

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
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
                          child: Obx(() => CompletarPerfilController.imgPath.value.isEmpty ? Image.network(user.imgUrl!, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.person_2_rounded, size: 100, color: Colors.black12)) : Image.memory(CompletarPerfilController.imgData!, fit: BoxFit.cover))
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
            const SizedBox(height: 12),
            Text('${AppLanguage.lang('ola')}, ${user.nome?.split(' ')[0]}!', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 17)),
            Text(AppLanguage.lang('cadastrar_img_chat'), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Obx(() => CompletarPerfilController.imgBgPath.value.isEmpty ? Opacity(opacity: 0.3, child: Image.asset('lib/assets/img/bg_wallpaper.jpg', fit: BoxFit.cover)) : Image.memory(CompletarPerfilController.imgBgData!, fit: BoxFit.cover)),
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
                          width: 50, height: 50,  
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(Get.width),
                            color: Colors.black12
                          ),
                          child: const Icon(Icons.add_photo_alternate_outlined),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${AppLanguage.lang('sexo_opcional')}:', style: const TextStyle(fontWeight: FontWeight.w500)),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8)
                  ),
                  padding: const EdgeInsets.only(left: 12),
                  child: Obx(() => DropdownButton<UserSexo>(
                    value: LoginController.sexo.value,
                    hint: Text(AppLanguage.lang('selecionar_sexo')),
                    icon: const Icon(Icons.keyboard_arrow_down),
                    underline: const SizedBox(),
                    isExpanded: true,
                    onChanged: (UserSexo? value) {
                      LoginController.sexo.value = value!;
                    },
                    items: UserSexo.values.map<DropdownMenuItem<UserSexo>>((UserSexo value) {
                      return DropdownMenuItem<UserSexo>(
                        value: value,
                        child: Text(value == UserSexo.none ? AppLanguage.lang('n_informar') : value.name.capitalizeFirst!),
                      );
                    }).toList(),
                  ),
                )),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 52, width: Get.width,
              child: ElevatedButton(
                onPressed: () {
                  if(CompletarPerfilController.imgBgData == null) {
                    Get.defaultDialog(
                      title: AppLanguage.lang('aviso'),
                      content: Text(AppLanguage.lang('vc_realmente_deseja_continuar_sem_papel'), textAlign: TextAlign.center),
                      actions: [
                        ElevatedButton(
                          onPressed: () => Get.back(),
                          child: Text(AppLanguage.lang('nao')),
                        ),
                        ElevatedButton(
                          onPressed: () => UsuarioRepository.completarPerfil(
                            imgData: CompletarPerfilController.imgData, 
                            imgBgData: CompletarPerfilController.imgBgData,
                            sexo: LoginController.sexo.value
                          ),
                          child: Text(AppLanguage.lang('sim')),
                        )
                      ]
                    );
                    return;
                  }

                  UsuarioRepository.completarPerfil(
                    imgData: CompletarPerfilController.imgData, 
                    imgBgData: CompletarPerfilController.imgBgData,
                    sexo: LoginController.sexo.value
                  );
                },
                child: Text(AppLanguage.lang('continuar')),
              ),
            )
          ],
        ),
      ),
    );
  }
}