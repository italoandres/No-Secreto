import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:whatsapp_chat/repositories/chat_repository.dart';

import '../models/chat_model.dart';
import 'chat_controller.dart';

class AudioController {
  static final isGravandoAudio = false.obs;
  static final record = AudioRecorder();
  static Future<bool> isRecording() async => await record.isRecording();
  static Future<void> stop() async {
    String? path = await record.stop();
    if (kDebugMode) {
      print(path);
    }

    if (path == null) {
      return;
    }

    await ChatRepository.addFile(
        file: File(path),
        fileName: '${DateTime.now().millisecondsSinceEpoch}.m4a',
        extensao: 'm4a');
    List<ChatModel> all = await ChatRepository.getAllFuture();

    if (all.length == 1) {
      ChatController.mensagensDoPaiAposPrimeiraMsg();
    }
  }

  static void start() async {
    bool p = await record.hasPermission();
    if (p) {
      Directory tempDir = await getApplicationDocumentsDirectory();
      // Start recording
      await record.start(
        RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: '${tempDir.path}/myFile.m4a',
      );
    }
  }

  static Future<String> downloadAudioFromUrl({
    required String url,
    required String fileName,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = dir.path;
    final file = File('$path/$fileName');
    final response = await http.get(Uri.parse(url));
    await file.writeAsBytes(response.bodyBytes);
    return file.path;
  }
}
