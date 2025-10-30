import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pod_player/pod_player.dart';
import 'package:whatsapp_chat/locale/language.dart';

class VideoPlayer extends StatefulWidget {
  final String url;
  final String? videoThumbnail;
  final bool isLoacal;
  final double width;
  final double? height;
  final bool? autoPlay;
  final bool? disablePause;
  final bool? disableControls;
  final bool? pauseWithGesture;
  const VideoPlayer(
      {super.key,
      required this.url,
      required this.isLoacal,
      required this.width,
      this.height,
      this.videoThumbnail,
      this.autoPlay,
      this.disablePause,
      this.disableControls,
      this.pauseWithGesture});

  @override
  State<VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
  PodPlayerController? videoController;
  final _scrollController = ScrollController();
  final ratio = (16 / 9).obs;

  @override
  void dispose() {
    if (videoController != null) {
      videoController!.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    videoController = PodPlayerController(
        playVideoFrom: widget.isLoacal
            ? PlayVideoFrom.file(
                File(widget.url),
              )
            : PlayVideoFrom.network(
                widget.url,
              ),
        podPlayerConfig: PodPlayerConfig(
          autoPlay: widget.autoPlay ?? false,
          isLooping: false,
        ))
      ..initialise().then((value) {
        if (videoController!.videoPlayerValue != null) {
          ratio.value = videoController!.videoPlayerValue!.aspectRatio;
        }

        videoController!.videoPlayerValue?.aspectRatio;
        if (widget.height != null) {
          Future.delayed(Duration.zero, () {
            double scrollviewHeight =
                _scrollController.position.maxScrollExtent -
                    _scrollController.position.minScrollExtent +
                    _scrollController.position.viewportDimension;

            double scrollToPosition = scrollviewHeight / 2 -
                _scrollController.position.viewportDimension / 2;
            _scrollController.jumpTo(scrollToPosition);
          });
        }
      });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.height == null
        ? Obx(() => SizedBox(
              //height: (videoH.value * widget.width / videoW.value / 1.5) + 28,
              width: widget.width,
              child: GestureDetector(
                onTapDown: (_) {
                  if (widget.pauseWithGesture == true) {
                    videoController!.pause();
                  }
                },
                onTapUp: (_) {
                  if (widget.pauseWithGesture == true) {
                    videoController!.play();
                  }
                },
                child: PodVideoPlayer(
                  controller: videoController!,
                  videoAspectRatio: ratio.value,
                  frameAspectRatio: ratio.value,
                  videoThumbnail: widget.videoThumbnail == null
                      ? null
                      : DecorationImage(
                          image: NetworkImage(widget.videoThumbnail!)),
                  podProgressBarConfig: widget.disableControls != true
                      ? const PodProgressBarConfig()
                      : const PodProgressBarConfig(
                          height: 0,
                          circleHandlerRadius: 0,
                        ),
                  overlayBuilder: widget.disableControls != true
                      ? null
                      : (OverLayOptions o) => const SizedBox(),
                  podPlayerLabels: PodPlayerLabels(
                      playbackSpeed: AppLanguage.lang('velocidade_reproducao'),
                      loopVideo: 'Loop'),
                ),
              ),
            ))
        : SizedBox(
            width: widget.width,
            height: widget.height,
            child: Obx(() => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  controller: _scrollController,
                  physics: const NeverScrollableScrollPhysics(),
                  child: PodVideoPlayer(
                    controller: videoController!,
                    podProgressBarConfig: const PodProgressBarConfig(
                      height: 0,
                      circleHandlerRadius: 0,
                    ),
                    overlayBuilder: (OverLayOptions o) {
                      return Container(
                          color: Colors.black26,
                          child: widget.disablePause == true
                              ? const SizedBox()
                              : Center(
                                  child: IconButton(
                                  padding: const EdgeInsets.all(0),
                                  onPressed: () {
                                    setState(() {
                                      videoController!.togglePlayPause();
                                    });
                                  },
                                  icon: Icon(
                                      videoController!.isVideoPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      size: 40,
                                      color: Colors.white),
                                )));
                    },
                    videoAspectRatio: ratio.value,
                    frameAspectRatio: ratio.value,
                    alwaysShowProgressBar: false,
                    videoThumbnail: widget.videoThumbnail == null
                        ? null
                        : DecorationImage(
                            image: NetworkImage(widget.videoThumbnail!)),
                    podPlayerLabels: PodPlayerLabels(
                        playbackSpeed:
                            AppLanguage.lang('velocidade_reproducao'),
                        loopVideo: 'Loop'),
                  ),
                )),
          );
  }
}
