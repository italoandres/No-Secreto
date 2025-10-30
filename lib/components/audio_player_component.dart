import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icon_decoration/icon_decoration.dart';
import 'package:intl/intl.dart';
import 'package:whatsapp_chat/models/usuario_model.dart';
import 'package:whatsapp_chat/theme.dart';
import '/controllers/audio_controller.dart';

class AudioPlayerComponent extends StatefulWidget {
  final String audioUrl;
  final String fileName;
  final double width;
  final UsuarioModel user;
  final bool? isLocal;
  const AudioPlayerComponent(
      {super.key,
      required this.audioUrl,
      required this.fileName,
      required this.width,
      required this.user,
      this.isLocal});

  @override
  State<AudioPlayerComponent> createState() => _AudioPlayerComponentState();
}

class _AudioPlayerComponentState extends State<AudioPlayerComponent> {
  PlayerController controller = PlayerController();
  final currentDuration = 0.obs;
  final maxDuration = 0.obs;
  final status = Rx<PlayerState>(PlayerState.stopped);

  @override
  void initState() {
    _start();
    super.initState();
  }

  _start() async {
    await controller.preparePlayer(
        path: widget.isLocal == true
            ? widget.audioUrl
            : await AudioController.downloadAudioFromUrl(
                url: widget.audioUrl, fileName: widget.fileName),
        shouldExtractWaveform: true,
        noOfSamples: (widget.width - 32 - 62 - 50) ~/ 6);

    controller.onPlayerStateChanged.listen((state) {
      status.value = state;
    });
    maxDuration.value = controller.maxDuration;
    controller.onCurrentDurationChanged.listen((duration) {
      currentDuration.value = duration;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Stack(
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: Image.network(widget.user.imgUrl ?? '',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(1000),
                                color: Colors.white),
                            padding: const EdgeInsets.all(8),
                            width: 50,
                            height: 50,
                            child: Image.asset('lib/assets/img/user.png',
                                fit: BoxFit.contain, color: Colors.grey))),
                  ),
                  IconButton(
                    onPressed: () async {
                      if (controller.playerState == PlayerState.initialized ||
                          controller.playerState == PlayerState.paused) {
                        controller.startPlayer();
                      } else if (controller.playerState ==
                          PlayerState.playing) {
                        controller.pausePlayer();
                      }
                    },
                    icon: Obx(() => Icon(
                        status.value == PlayerState.playing
                            ? Icons.pause
                            : Icons.play_arrow_rounded,
                        color: Colors.white)),
                  ),
                  Expanded(
                    child: AudioFileWaveforms(
                      size: Size(widget.width, 50.0),
                      playerController: controller,
                      enableSeekGesture: true,
                      waveformType: WaveformType.fitWidth,
                      playerWaveStyle: const PlayerWaveStyle(
                        fixedWaveColor: Colors.white54,
                        liveWaveColor: Colors.white,
                        spacing: 6,
                      ),
                    ),
                  ),
                ],
              ),
              const Positioned(
                  bottom: -3,
                  left: 35,
                  child: DecoratedIcon(
                    icon:
                        Icon(Icons.mic_rounded, color: Colors.white, size: 30),
                    decoration: IconDecoration(
                        border: IconBorder(
                            width: 4, color: AppTheme.chatBalaoColor)),
                  ))
            ],
          ),
        ),
        Positioned.fill(
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.only(left: 102),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Obx(() => Text(
                    DateFormat('mm:ss').format(DateTime.utc(0)
                        .add(Duration(seconds: currentDuration ~/ 1000))),
                    style:
                        const TextStyle(fontSize: 12, color: Colors.white70))),
                Obx(() => Text(
                    DateFormat('mm:ss').format(DateTime.utc(0)
                        .add(Duration(seconds: maxDuration ~/ 1000))),
                    style:
                        const TextStyle(fontSize: 12, color: Colors.white70)))
              ],
            ),
          ),
        )
      ],
    );
  }
}
