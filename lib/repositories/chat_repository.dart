import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:ffmpeg_kit_flutter_min_gpl/ffprobe_kit.dart'; // Removido temporariamente
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:whatsapp_chat/controllers/notification_controller.dart';
import 'package:whatsapp_chat/locale/language.dart';
import 'package:whatsapp_chat/models/chat_model.dart';
import 'package:whatsapp_chat/models/emoji_model.dart';
import 'package:whatsapp_chat/models/link_descricao_model.dart';
import 'package:whatsapp_chat/models/progress_model.dart';
import 'package:whatsapp_chat/token_usuario.dart';
import 'package:whatsapp_chat/models/usuario_model.dart';
import 'package:whatsapp_chat/services/automatic_message_service.dart';
import '../utils/debug_utils.dart';

class ChatRepository {
  static final listObs = Rx<List<ProgressModel>>([]);
  static Future<List<EmojiModel>> getAllEmoji() async {
    final String response =
        await rootBundle.loadString('lib/assets/outros/emoji.json');
    final dados = await json.decode(response);
    List<EmojiModel> all = [];
    for (var element in dados) {
      all.add(EmojiModel.fromJson(element));
    }

    return all;
  }

  static Future<bool> addText({
    required String msg,
    bool? orginemAdmin,
    LinkDescricaoModel? linkDescricaoModel,
    String? contexto,
    String? replyToStoryId, // 🙏 NOVO: ID do story sendo respondido
    String? replyToStoryUrl, // 🙏 NOVO: URL da mídia do story
    String? replyToStoryType, // 🙏 NOVO: Tipo da mídia (image/video)
  }) async {
    Map<String, dynamic> data = {
      'dataCadastro': DateTime.now(),
      'idDe': FirebaseAuth.instance.currentUser?.uid,
      'tipo': ChatType.text.name,
      'orginemAdmin': orginemAdmin,
      'text': msg,
    };

    if (linkDescricaoModel != null) {
      data['linkDescricaoModel'] =
          LinkDescricaoModel.toJson(linkDescricaoModel);
    }

    // 🙏 NOVO: Adicionar dados do story se for uma resposta ao Pai
    if (replyToStoryId != null) {
      data['replyToStory'] = {
        'storyId': replyToStoryId,
        'storyUrl': replyToStoryUrl,
        'storyType': replyToStoryType,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }

    // Escolher coleção baseada no contexto
    String colecao = _getCollectionByContext(contexto);
    await FirebaseFirestore.instance.collection(colecao).add(data);
    NotificationController().setNotification();

    // Resetar timer de mensagens automáticas
    AutomaticMessageService.resetInactivityTimer();

    return true;
  }

  // Método helper para escolher a coleção baseada no contexto
  static String _getCollectionByContext(String? contexto) {
    switch (contexto) {
      case 'sinais_isaque':
        return 'chat_sinais_isaque';
      case 'sinais_rebeca':
        return 'chat_sinais_rebeca';
      default:
        return 'chat';
    }
  }

  // Método específico para adicionar texto no chat "Sinais de Meu Isaque"
  static Future<bool> addTextSinaisIsaque({
    required String msg,
    bool? orginemAdmin,
    LinkDescricaoModel? linkDescricaoModel,
  }) async {
    Map<String, dynamic> data = {
      'dataCadastro': DateTime.now(),
      'idDe': FirebaseAuth.instance.currentUser?.uid,
      'tipo': ChatType.text.name,
      'orginemAdmin': orginemAdmin,
      'text': msg,
    };

    if (linkDescricaoModel != null) {
      data['linkDescricaoModel'] =
          LinkDescricaoModel.toJson(linkDescricaoModel);
    }

    await FirebaseFirestore.instance.collection('chat_sinais_isaque').add(data);
    NotificationController().setNotification();

    // Resetar timer de mensagens automáticas
    AutomaticMessageService.resetInactivityTimer();

    return true;
  }

  static Future<bool> addImg({
    required String msg,
    required Uint8List img,
  }) async {
    final query = await FirebaseFirestore.instance.collection('chat').add({
      'dataCadastro': DateTime.now(),
      'idDe': FirebaseAuth.instance.currentUser?.uid,
      'tipo': ChatType.img.name,
      'fileExtension': 'png',
      'text': msg,
      'isLoading': true
    });

    FirebaseFirestore.instance.collection('chat').doc(query.id).update({
      'fileUrl': await _uploadImg(img, idDocument: query.id),
      'isLoading': false
    });
    NotificationController().setNotification();

    // Resetar timer de mensagens automáticas
    AutomaticMessageService.resetInactivityTimer();

    return true;
  }

  static Future<bool> addImgFile({
    required String msg,
    required String extensao,
    required File img,
    String? contexto,
  }) async {
    String colecao = _getCollectionByContext(contexto);
    final query = await FirebaseFirestore.instance.collection(colecao).add({
      'dataCadastro': DateTime.now(),
      'idDe': FirebaseAuth.instance.currentUser?.uid,
      'tipo': ChatType.img.name,
      'fileExtension': extensao,
      'text': msg,
      'isLoading': true
    });

    FirebaseFirestore.instance.collection(colecao).doc(query.id).update({
      'fileUrl': await _uploadFile(file: img, extensao: extensao),
      'isLoading': false
    });
    NotificationController().setNotification();

    // Resetar timer de mensagens automáticas
    AutomaticMessageService.resetInactivityTimer();

    return true;
  }

  static Future<bool> addVideo({
    required String msg,
    required File video,
    String? contexto,
  }) async {
    // Validação simplificada do vídeo usando video_thumbnail
    try {
      final thumbnail = await VideoThumbnail.thumbnailData(
        video: video.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 128,
        quality: 25,
      );

      if (thumbnail == null) {
        Get.rawSnackbar(message: AppLanguage.lang('falha_ao_validar_video'));
        return false;
      }
    } catch (e) {
      Get.rawSnackbar(message: AppLanguage.lang('falha_ao_validar_video'));
      return false;
    }

    Uint8List? thumbnail = await VideoThumbnail.thumbnailData(
      video: video.path,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 480,
      quality: 25,
    );

    if (thumbnail == null) {
      Get.rawSnackbar(message: AppLanguage.lang('falha_ao_validar_video'));
      return false;
    }

    String thumbnailImg = await _uploadImg(thumbnail);

    String colecao = _getCollectionByContext(contexto);
    final query = await FirebaseFirestore.instance.collection(colecao).add({
      'dataCadastro': DateTime.now(),
      'idDe': FirebaseAuth.instance.currentUser?.uid,
      'tipo': ChatType.video.name,
      'fileExtension': video.path.split('.').last,
      'text': msg,
      'isLoading': true
    });

    FirebaseFirestore.instance.collection(colecao).doc(query.id).update({
      'videoThumbnail': thumbnailImg,
      'videoDuration':
          0, // Duração será definida posteriormente quando o FFmpeg for reintegrado
      'fileUrl':
          await _uploadVideo(video, video.path.split('.').last, query.id),
      'isLoading': false
    });
    NotificationController().setNotification();

    // Resetar timer de mensagens automáticas
    AutomaticMessageService.resetInactivityTimer();

    return true;
  }

  static Future<bool> addFile({
    required File file,
    required String fileName,
    required String extensao,
    String? contexto,
  }) async {
    String colecao = _getCollectionByContext(contexto);
    final query = await FirebaseFirestore.instance.collection(colecao).add({
      'dataCadastro': DateTime.now(),
      'idDe': FirebaseAuth.instance.currentUser?.uid,
      'tipo': ChatType.outro.name,
      'fileExtension': extensao,
      'fileName': fileName,
      'isLoading': true
    });

    FirebaseFirestore.instance.collection(colecao).doc(query.id).update({
      'fileUrl': await _uploadFile(file: file, extensao: extensao),
      'isLoading': false
    });

    NotificationController().setNotification();

    // Resetar timer de mensagens automáticas
    AutomaticMessageService.resetInactivityTimer();

    return true;
  }

  static Stream<List<ChatModel>> getAll() {
    return FirebaseFirestore.instance
        .collection('chat')
        .where('idDe', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .snapshots()
        .map((event) => event.docs.map((e) {
              ChatModel chat = ChatModel.fromJson(e.data());
              chat.id = e.id;
              return chat;
            }).toList());
  }

  // Método específico para o chat "Sinais de Meu Isaque"
  static Stream<List<ChatModel>> getAllSinaisIsaque() {
    return FirebaseFirestore.instance
        .collection('chat_sinais_isaque')
        .where('idDe', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .snapshots()
        .map((event) => event.docs.map((e) {
              ChatModel chat = ChatModel.fromJson(e.data());
              chat.id = e.id;
              return chat;
            }).toList());
  }

  // Método específico para o chat "Sinais de Minha Rebeca"
  static Stream<List<ChatModel>> getAllSinaisRebeca() {
    return FirebaseFirestore.instance
        .collection('chat_sinais_rebeca')
        .where('idDe', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .snapshots()
        .map((event) => event.docs.map((e) {
              ChatModel chat = ChatModel.fromJson(e.data());
              chat.id = e.id;
              return chat;
            }).toList());
  }

  static Future<List<ChatModel>> getAllFuture() async {
    List<ChatModel> all = [];

    final query = await FirebaseFirestore.instance
        .collection('chat')
        .where('idDe', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .get();

    for (var e in query.docs) {
      ChatModel chat = ChatModel.fromJson(e.data());
      chat.id = e.id;
      all.add(chat);
    }
    return all;
  }

  static void deletarItens({required List<String> itens}) async {
    for (var element in itens) {
      FirebaseFirestore.instance.collection('chat').doc(element).delete();
    }
  }

  static void updateDataCadastroItem({
    required String id,
    required DateTime data,
  }) async {
    FirebaseFirestore.instance
        .collection('chat')
        .doc(id)
        .update({'dataCadastro': data});
  }

  static Future<String> _uploadImg(Uint8List fileData,
      {String? idDocument}) async {
    Reference ref = FirebaseStorage.instance
        .ref()
        .child('chat/${DateTime.now().millisecondsSinceEpoch}.png');

    final snapshot =
        ref.putData(fileData, SettableMetadata(contentType: 'image/png'));
    snapshot.snapshotEvents.listen((event) {
      if (idDocument != null) {
        double progress =
            event.bytesTransferred.toDouble() / event.totalBytes.toDouble();

        listObs.value.removeWhere((element) => element.id == idDocument);
        if (progress < 1) {
          listObs.value.add(ProgressModel(id: idDocument, progress: progress));
        }

        listObs.refresh();
      }
    });

    await snapshot;
    return await ref.getDownloadURL();
  }

  static Future<String> _uploadVideo(
      File file, String extensao, String idDocument) async {
    Reference ref = FirebaseStorage.instance
        .ref()
        .child('chat/${DateTime.now().millisecondsSinceEpoch}.$extensao');

    final snapshot = ref.putFile(file);
    snapshot.snapshotEvents.listen((event) {
      double progress =
          event.bytesTransferred.toDouble() / event.totalBytes.toDouble();

      listObs.value.removeWhere((element) => element.id == idDocument);
      if (progress < 1) {
        listObs.value.add(ProgressModel(id: idDocument, progress: progress));
      }

      listObs.refresh();
    });

    await snapshot;
    return await ref.getDownloadURL();
  }

  static Future<String> _uploadFile({
    required File file,
    required String extensao,
  }) async {
    Reference ref = FirebaseStorage.instance
        .ref()
        .child('chat/${DateTime.now().millisecondsSinceEpoch}.$extensao');

    final snapshot = ref.putFile(file);
    snapshot.snapshotEvents.listen((event) {});

    await snapshot;
    return await ref.getDownloadURL();
  }

  // Método para enviar mensagem automática do Pai após 3 dias de inatividade
  static Future<bool> sendAutomaticPaiMessage() async {
    try {
      // Mensagem personalizada baseada no gênero do usuário
      String message = TokenUsuario().sexo == UserSexo.masculino
          ? 'Filho como você está?'
          : 'Filha como você está?';

      Map<String, dynamic> data = {
        'dataCadastro': DateTime.now(),
        'idDe': 'system_pai', // ID especial para mensagens do Pai
        'tipo': ChatType.text.name,
        'orgigemAdmin': true, // Marca como mensagem administrativa
        'text': message,
        'isLoading': false,
        'nomeUser': 'Pai', // Nome do remetente
        'isSystemMessage': true, // Flag para identificar mensagens do sistema
      };

      // Enviar para o chat principal
      await FirebaseFirestore.instance.collection('chat').add(data);

      return true;
    } catch (e) {
      safePrint('Erro ao enviar mensagem automática do Pai: $e');
      return false;
    }
  }

  // Método para enviar mensagem automática do Pai em contextos específicos
  static Future<bool> sendAutomaticPaiMessageToContext(String contexto) async {
    try {
      // Mensagem personalizada baseada no gênero do usuário
      String message = TokenUsuario().sexo == UserSexo.masculino
          ? 'Filho como você está?'
          : 'Filha como você está?';

      Map<String, dynamic> data = {
        'dataCadastro': DateTime.now(),
        'idDe': 'system_pai', // ID especial para mensagens do Pai
        'tipo': ChatType.text.name,
        'orgigemAdmin': true, // Marca como mensagem administrativa
        'text': message,
        'isLoading': false,
        'nomeUser': 'Pai', // Nome do remetente
        'isSystemMessage': true, // Flag para identificar mensagens do sistema
      };

      // Escolher coleção baseada no contexto
      String colecao = _getCollectionByContext(contexto);
      await FirebaseFirestore.instance.collection(colecao).add(data);

      return true;
    } catch (e) {
      safePrint(
          'Erro ao enviar mensagem automática do Pai para contexto $contexto: $e');
      return false;
    }
  }

  static Future<LinkDescricaoModel?> fetchDescription(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final document = html_parser.parse(response.body);
      String? title;
      String? description;
      String? imageUrl;

      final metaTags = document.getElementsByTagName('meta');
      for (var tag in metaTags) {
        final propertyAttribute = tag.attributes['property'];
        final contentAttribute = tag.attributes['content'];
        if (propertyAttribute == 'og:description' && contentAttribute != null) {
          description = contentAttribute;
        } else if (propertyAttribute == 'og:image' &&
            contentAttribute != null) {
          imageUrl = contentAttribute;
        } else if (propertyAttribute == 'og:title' &&
            contentAttribute != null) {
          title = contentAttribute;
        }

        title ??= document.head?.querySelector('title')?.text;

        if (description == null) {
          final propertyAttribute = tag.attributes['name'];
          final contentAttribute = tag.attributes['content'];

          if (propertyAttribute == 'description' && contentAttribute != null) {
            description = contentAttribute;
          }
        }

        if (imageUrl == null || imageUrl.trim().isEmpty) {
          final imageElements = document.getElementsByTagName('img');

          for (var imageElement in imageElements) {
            final modeAttribute = imageElement.attributes['mode'];
            if (modeAttribute == '4') {
              imageUrl = imageElement.attributes['src'];
            }
          }
        }
      }

      if (title != null && description != null) {
        return LinkDescricaoModel(
            titulo: title, descricao: description, imgUrl: imageUrl);
      }
    }
    return null;
  }
}
