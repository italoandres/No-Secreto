import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:record/record.dart';
import 'package:whatsapp_chat/locale/language.dart';
import '/controllers/audio_controller.dart';

class AudioRecoderComponent extends StatefulWidget {
  const AudioRecoderComponent({Key? key}) : super(key: key);

  @override
  State<AudioRecoderComponent> createState() => _AudioRecoderComponentState();
}

class _AudioRecoderComponentState extends State<AudioRecoderComponent> {
  StreamSubscription<RecordState>? recordSub;
  Timer? _timer;
  final _recordDuration = 0.obs;

  @override
  void initState() {
    AudioController.start();
    recordSub = AudioController.record.onStateChanged().listen((recordState) {
      if (recordState == RecordState.record) {
        _timer?.cancel();
        _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
          _recordDuration.value++;
        });
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    recordSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.mic, color: Colors.red),
                const SizedBox(width: 6),
                Obx(() => Text(DateFormat('mm:ss').format(DateTime.utc(0)
                    .add(Duration(seconds: _recordDuration.value)))))
              ],
            ),
            Text(AppLanguage.lang('gravando'),
                style: const TextStyle(color: Colors.grey))
          ],
        ));
  }
}
