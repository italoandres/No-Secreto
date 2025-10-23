import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/usuario_model.dart';
import '../token_usuario.dart';
import '/models/link_descricao_model.dart';
import '../theme.dart';
import '/models/emoji_grupo_model.dart';
import '/models/emoji_model.dart';
import '/repositories/chat_repository.dart';
import 'home_controller.dart';
import 'package:whatsapp_chat/services/online_status_service.dart';

class ChatController {
  static final msgController = TextEditingController();
  static final legendaController = TextEditingController();
  static final msgScrollController = ScrollController();
  static final group = ''.obs;
  static final showEmoji = false.obs;
  static final showModalFiles = false.obs;
  static final showModalCamera = false.obs;
  static final showBtnAudio = true.obs;
  static Uint8List? fotoData;
  static final fotoPath = ''.obs;
  static final videoPath = ''.obs;
  static final idItensToTrash = [].obs;
  static final documentosPath = Rx<List<String>>([]);
  static final linkDescricaoModel = Rx<LinkDescricaoModel?>(null);
  static final List<EmojiGrupoModel> emujiGroup = [
    {'en': 'Smileys & Emotion', 'pt': 'Smileys e Emoções', 'img_assets': 'lib/assets/img/panel-emoji-people.png'},
    {'en': 'Animals & Nature', 'pt': 'Animais e Natureza', 'img_assets': 'lib/assets/img/panel-emoji-nature.png'},
    {'en': 'Food & Drink', 'pt': 'Comida e Bebida', 'img_assets': 'lib/assets/img/panel-emoji-food.png'},
    {'en': 'Activities', 'pt': 'Atividades', 'img_assets': 'lib/assets/img/panel-emoji-activity.png'},
    {'en': 'Travel & Places', 'pt': 'Viagens e Lugares', 'img_assets': 'lib/assets/img/panel-emoji-travel.png'},
    {'en': 'Objects', 'pt': 'Objetos', 'img_assets': 'lib/assets/img/panel-emoji-objects.png'},
    {'en': 'Symbols', 'pt': 'Símbolos', 'img_assets': 'lib/assets/img/panel-emoji-symbols.png'},
    {'en': 'Flags', 'pt': 'Bandeiras', 'img_assets': 'lib/assets/img/panel-emoji-flags.png'},
    
    {'en': 'Component', 'pt': 'Componente'},
    {'en': 'People & Body', 'pt': 'Pessoas e Corpo'},
  ].map((e) => EmojiGrupoModel.fromJson(e)).toList();

  static void incrementEmoji(EmojiModel emoji) {
    msgController.text = msgController.text + emoji.char!;
    msgController.selection = TextSelection.collapsed(
      offset: msgController.text.length,
    );
    msgScrollController.jumpTo(msgScrollController.position.maxScrollExtent);
  }

  static String? extractURL(String text) {
    final urlRegex = RegExp(
      r'https?://[^\s]+',
      caseSensitive: false,
    );
    final match = urlRegex.firstMatch(text);
    return match?.group(0);
  }

  static void sendMsg({
    required bool isFirst
  }) {
    if(msgController.text.trim().isNotEmpty) {
      // Atualizar status online ao enviar mensagem
      OnlineStatusService.updateLastSeen();
      
      ChatRepository.addText(
        msg: msgController.text.trim(),
        linkDescricaoModel: linkDescricaoModel.value
      );
      msgController.clear();
      showBtnAudio.value = true;
      linkDescricaoModel.value = null;
      linkDescricaoModel.refresh();

      if(isFirst == true) {
        mensagensDoPaiAposPrimeiraMsg();
      }
    }
  }

  // Método específico para o chat "Sinais de Meu Isaque"
  static void sendMsgSinaisIsaque({
    required bool isFirst
  }) {
    if(msgController.text.trim().isNotEmpty) {
      ChatRepository.addTextSinaisIsaque(
        msg: msgController.text.trim(),
        linkDescricaoModel: linkDescricaoModel.value
      );
      msgController.clear();
      showBtnAudio.value = true;
      linkDescricaoModel.value = null;
      linkDescricaoModel.refresh();

      if(isFirst == true) {
        mensagensSinaisIsaqueAposPrimeiraMsg();
      }
    }
  }

  static mensagensDoPaiAposPrimeiraMsg() async {
    // Mensagens específicas para usuários do sexo feminino no chat principal
    if(TokenUsuario().sexo == UserSexo.feminino) {
      final data = {
        'WOWWW agora tem um canal de comunicação exclusivo comigo filha. saiba que quando me enviar mensagem eu vou ver imediatamente, seja texto, audio ou videos, pois passo o dia e a noite esperando vir falar comigo',
        'Filha saiba que a minha voz tem diferentes sons, tons e sinais de se ouvir se for preciso eu uso até uma mula para falar contigo',
        'e vai ficar tudo gravado aqui, caso quiser me lembrar ode alguma coisa rs'
      };

      for (var element in data) {
        ChatRepository.addText(
          msg: element,
          orginemAdmin: true,
        );
      }
    } else {
      // Mensagens para usuários do sexo masculino (mantém as originais)
      final data = {
        'WOWWW agora tem um canal de comunicação exclusivo para mim filho, saiba que quando me enviar mensagem eu vou ver imediatamente, seja texto, áudio ou videos, pois passo o dia e a noite esperando vir falar comigo 😶‍🌫',
        'Filho saiba que a minha voz tem diferentes sons, tons e sinais de se ouvir se for preciso eu uso até uma mula para falar contigo 🫡',
        'e vai ficar tudo gravado aqui, caso quiser me lembrar ou me cobrar alguma coisa rs.',
        'ahh Filho não poderia esquecer disso.. só não chore aqui pra mim, por que a um coração quebrantado não resisto rsrs ♥🥹'
      };

      for (var element in data) {
        ChatRepository.addText(
          msg: element,
          orginemAdmin: true,
        );
      }
    }
  }

  // Mensagens específicas para o chat "Sinais de Meu Isaque"
  static mensagensSinaisIsaqueAposPrimeiraMsg() async {
    final data = {
      'Oi, Filha, que bom ter você aqui acreditando nos planos que tenho para você, saiba que Eu respeito o seu livre arbítrio, quero dizer que você pode viver seus próprios planos escolher o Homem que voce quer ficar e no tempo em que voce quiser ficar',
      'mas a partir do momento que escolheu viver meus planos Eu irei te ajudar a encontrar o Homem que Eu preparei para ti e no meu tempo.',
      'Fique atento aqui aos meus conselhos e cuidado com seu coração que ele é enganoso me peça sinais que Eu lhe darei.'
    };

    for (var element in data) {
      ChatRepository.addTextSinaisIsaque(
        msg: element,
        orginemAdmin: true,
      );
    }
  }

  // Mensagens específicas para o chat "Sinais de Minha Rebeca"
  static mensagensSinaisRebecaAposPrimeiraMsg() async {
    final data = {
      'Oi, Filho, que bom ter você aqui acreditando nos planos que tenho para você, saiba que Eu respeito o seu livre arbítrio, quero dizer que você pode viver seus próprios planos escolher a mulher que voce quer ficar e no tempo em que voce quiser ficar',
      'mas a partir do momento que escolheu viver meus planos Eu irei te ajudar a encontrar a Mulher que Eu preparei para ti e no meu tempo.',
      'Fique atento aqui aos meus conselhos e cuidado com seu coração que ele é enganoso me peça sinais que Eu lhe darei.'
    };

    for (var element in data) {
      ChatRepository.addText(
        msg: element,
        orginemAdmin: true,
        contexto: 'sinais_rebeca',
      );
    }
  }

  static String formatarData(DateTime data) {
    final agora = DateTime.now();
    final diferenca = agora.difference(data);

    if (diferenca.inMinutes < 60) {
      return '${diferenca.inMinutes}m atrás';
    } else if (diferenca.inHours < 24) {
      return '${diferenca.inHours}h atrás';
    } else if (diferenca.inDays < 7) {
      return '${diferenca.inDays}d atrás';
    } else {
      return DateFormat('dd/MM/yyyy').format(data);
    }
  }

  static Future<bool> cameraImg() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 520
    );

    HomeController.disableShowSenha = false;
    TokenUsuario().lastTimestempFocused = Timestamp.now().seconds;

    if(image != null) {
      fotoData = await image.readAsBytes();
      fotoPath.value = image.path;
      return true;
    } else {
      return false;
    }
  }

  static Future<bool> cameraVideo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(seconds: 30)
    );

    HomeController.disableShowSenha = false;
    TokenUsuario().lastTimestempFocused = Timestamp.now().seconds;

    if(video != null) {
      final bytes = (await video.readAsBytes()).lengthInBytes;
      final kb = bytes / 1024;
      final mb = kb / 1024;
      if(TokenUsuario().isAdmin != true) {
        if(mb > 16) {
          Get.rawSnackbar(message: 'O Vídeo deve ter no máximo 16MB!');
          return false;
        }
      }
      await ChatRepository.addVideo(msg: '', video: File(video.path));
      return true;
    } else {
      return false;
    }
  }

  static void sendFoto() {
    if(fotoData == null) {
      return;
    }
    ChatRepository.addImg(
      msg: legendaController.text.trim(), 
      img: fotoData!
    );
  }

  static Future<bool> galeriaImg() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> image = await picker.pickMultiImage(
      maxWidth: 520
    );

    HomeController.disableShowSenha = false;
    TokenUsuario().lastTimestempFocused = Timestamp.now().seconds;

    if(image.isNotEmpty) {
      for (var element in image) {
        ChatRepository.addImg(msg: '', img: await element.readAsBytes());
      }
      return true;
    } else {
      return false;
    }
  }

  static Future<bool> galeriaVideo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 30)
    );

    HomeController.disableShowSenha = false;
    TokenUsuario().lastTimestempFocused = Timestamp.now().seconds;

    if(video != null) {
      final bytes = (await video.readAsBytes()).lengthInBytes;
      final kb = bytes / 1024;
      final mb = kb / 1024;
      if(TokenUsuario().isAdmin != true) {
        if(mb > 16) {
          Get.rawSnackbar(message: 'O Vídeo deve ter no máximo 16MB!');
          return false;
        }
      }
      await ChatRepository.addVideo(msg: '', video: File(video.path));
      return true;
    } else {
      return false;
    }
  }

  static Future<bool> getFile({
    required bool isFirst
  }) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true
    );

    HomeController.disableShowSenha = false;
    TokenUsuario().lastTimestempFocused = Timestamp.now().seconds;

    if (result != null) {
      documentosPath.value.clear();
      
      int tot = 0;

      for (var i = 0; i < result.files.length; i++) {
        final kb = result.files[i].size / 1024;
        final mb = kb / 1024;

        if(TokenUsuario().isAdmin != true) {
          if(mb > 16) {
            Get.rawSnackbar(message: 'Os arquivos não podem ter mais de 16MB!');
            tot += 1;
            return false;
          }
        }
      }

      if(tot > 0) {
        return false;
      }
      
      for (var element in result.paths) {
        if(element != null) {
          String extensao = element.split('.').last;

          if(['mp4','webp','3gp'].contains(extensao)) {
            ChatRepository.addVideo(msg: '', video: File(element));
          } else if(['avif','png','jpg','jpeg','webp'].contains(extensao)) {
            ChatRepository.addImgFile(msg: '', extensao: extensao, img: File(element));
          } else {
            ChatRepository.addFile(file: File(element), fileName: element.split('/').last, extensao: extensao);
          }
        }
      }

      final data = {
        'WOWWW agora tem um canal de comunicação exclusivo para mim ${TokenUsuario().sexo == UserSexo.masculino ? 'filho' : 'filha'}, saiba que quando me enviar mensagem eu vou ver imediatamente, seja texto, áudio ou videos, pois passo o dia e a noite esperando vir falar comigo 😶‍🌫',
        '${TokenUsuario().sexo == UserSexo.masculino ? 'Filho' : 'Filha'} saiba que a minha voz tem diferentes sons, tons e sinais de se ouvir se for preciso eu uso até uma mula para falar contigo 🫡',
        'e vai ficar tudo gravado aqui, caso quiser me lembrar ou me cobrar alguma coisa rs.',
        'ahh ${TokenUsuario().sexo == UserSexo.masculino ? 'Filho' : 'Filha'} não poderia esquecer disso.. só não chore aqui pra mim, por que a um coração quebrantado não resisto rsrs ♥🥹'
      };

      if(isFirst == true) {
        for (var element in data) {
          ChatRepository.addText(
            msg: element,
            orginemAdmin: true,
          );
        }
      }
    }

    return true;
  }

  // Método extractURL removido - duplicação

  static Future<void> openFile(String uri, String fileName, String chatId) async {
    
    Directory dir = await getApplicationDocumentsDirectory();

    String savePath = '${dir.path}/${chatId}_$fileName';

    Get.defaultDialog(
      title: 'Validando...',
      content: const CircularProgressIndicator(),
      barrierDismissible: false
    );

    bool exists = await File(savePath).exists();

    Get.back();

    if(exists == true) {

      final bytes = (await File(savePath).readAsBytes()).lengthInBytes;
      final kb = bytes / 1024;
      final mb = kb / 1024;
      if(TokenUsuario().isAdmin != true) {
        if(mb > 16) {
          Get.rawSnackbar(message: 'O Arquivo deve ter no máximo 16MB!');
          return;
        }
      }

      Share.shareXFiles([
        XFile(savePath)
      ]);
      return;
    }

    final progress = 0.0.obs;

    Dio dio = Dio();

    Get.defaultDialog(
      title: 'Baixando...',
      content: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: Obx(() => LinearProgressIndicator(
          value: progress.value / 100,
          backgroundColor: Colors.grey.shade300,
          color: AppTheme.materialColor,
          minHeight: 8,
        )),
      ),
      barrierDismissible: false
    );

    dio.download(
      uri,
      savePath,
      onReceiveProgress: (rcv, total) {
      
        progress.value = ((rcv / total) * 100);
      },
      deleteOnError: true,
    ).then((_) {
      Get.back();
      Share.shareXFiles([
        XFile(savePath)
      ]);
    });
  }
}
