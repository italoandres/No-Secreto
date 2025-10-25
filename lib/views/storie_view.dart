import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../repositories/stories_repository.dart';
import '/components/video_player.dart';
import '/constants.dart';
import '/locale/language.dart';
import '/models/storie_file_model.dart';

class StorieView extends StatefulWidget {
  final List<StorieFileModel> listFiles;
  const StorieView({super.key, required this.listFiles});

  @override
  State<StorieView> createState() => _StorieViewState();
}

class _StorieViewState extends State<StorieView> {
  final indexPage = 0.obs;
  final countTimer = 0.obs;
  final pageController = PageController();
  bool isPaused = false;
  bool isStoped = false;
  final timestampPublicacao = Rx<Timestamp>(Timestamp.now());

  @override
  void initState() {
    timestampPublicacao.value = widget.listFiles[0].dataCadastro!;
    timestampPublicacao.refresh();
    StoriesRepository.addVisto(widget.listFiles.first.id!);
    loop();
    super.initState();
  }

  loop() {
    Future.delayed(const Duration(seconds: 1), () {
      if (isPaused == false) {
        countTimer.value++;
      }

      if (isStoped == false) {
        loop();
      }
    });
  }

  @override
  void dispose() {
    isStoped = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
        ),
        backgroundColor: Colors.black,
        body: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            SizedBox(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8, right: 2, top: 12),
                    child: Row(
                      children: [
                        for (var i = 0; i < widget.listFiles.length; i++)
                          widget.listFiles[i].fileType == StorieFileType.img
                              ? Expanded(
                                  child: Row(
                                    children: [
                                      _progress(i, 15),
                                      i > 0
                                          ? const SizedBox(width: 6)
                                          : const SizedBox(width: 6)
                                    ],
                                  ),
                                )
                              : Expanded(
                                  child: Row(
                                    children: [
                                      _progress(i,
                                          widget.listFiles[i].videoDuration!),
                                      i > 0
                                          ? const SizedBox(width: 6)
                                          : const SizedBox(width: 6)
                                    ],
                                  ),
                                )
                      ],
                    ),
                  ),
                  AppBar(
                    leading: IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    backgroundColor: Colors.transparent,
                    title: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.white24),
                              borderRadius: BorderRadius.circular(100)),
                          child: ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: Image.asset('lib/assets/img/logo_2.png')),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(Constants.appName,
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.white)),
                              Text('Nova publicação',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.white60)),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  PageView(
                    onPageChanged: (val) {
                      indexPage.value = val;
                      timestampPublicacao.value =
                          widget.listFiles[val].dataCadastro!;
                      timestampPublicacao.refresh();
                      countTimer.value = 0;
                      StoriesRepository.addVisto(widget.listFiles[val].id!);
                    },
                    controller: pageController,
                    children: [
                      for (var item in widget.listFiles)
                        Stack(
                          children: [
                            SizedBox(
                              width: Get.width,
                              height: Get.height,
                              child: GestureDetector(
                                onTapDown: (_) {
                                  isPaused = true;
                                },
                                onTapUp: (_) {
                                  isPaused = false;
                                },
                                child: item.fileType == StorieFileType.img
                                    ? CachedNetworkImage(
                                        imageUrl: item.fileUrl!,
                                        fit: BoxFit.contain,
                                        placeholder: (context, url) =>
                                            const Center(
                                                child:
                                                    CircularProgressIndicator()),
                                      )
                                    : VideoPlayer(
                                        url: item.fileUrl!,
                                        isLoacal: false,
                                        width: Get.width,
                                        autoPlay: true,
                                        disablePause: true,
                                        disableControls: true,
                                        pauseWithGesture: true,
                                      ),
                              ),
                            ),
                            item.link!.isEmpty
                                ? const SizedBox()
                                : Positioned(
                                    top: Get.width * 0.1,
                                    child: SizedBox(
                                      width: Get.width,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          TextButton(
                                            style: TextButton.styleFrom(
                                                backgroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8))),
                                            onPressed: () async {
                                              launchUrl(Uri.parse(item.link!),
                                                  mode: LaunchMode
                                                      .externalApplication);
                                            },
                                            child: Row(
                                              children: [
                                                Image.asset(
                                                    'lib/assets/img/link.png',
                                                    width: 20,
                                                    color: Colors.blueAccent),
                                                const SizedBox(width: 12),
                                                const Text('Link',
                                                    style: TextStyle(
                                                        color:
                                                            Colors.blueAccent,
                                                        fontSize: 18)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                          ],
                        )
                    ],
                  ),
                  Positioned.fill(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.only(
                            topRight:
                                Radius.elliptical(Get.width * 0.2, Get.height),
                            bottomRight:
                                Radius.elliptical(Get.width * 0.2, Get.height),
                          ),
                          highlightColor: Colors.black,
                          focusColor: Colors.black,
                          splashColor: Colors.black,
                          hoverColor: Colors.black,
                          onTap: () => pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.bounceInOut),
                          child: Container(
                            width: Get.width * 0.2,
                            decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.elliptical(
                                      Get.width * 0.2, Get.height),
                                  bottomRight: Radius.elliptical(
                                      Get.width * 0.2, Get.height),
                                )),
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.only(
                            topLeft:
                                Radius.elliptical(Get.width * 0.2, Get.height),
                            bottomLeft:
                                Radius.elliptical(Get.width * 0.2, Get.height),
                          ),
                          highlightColor: Colors.black,
                          focusColor: Colors.black,
                          splashColor: Colors.black,
                          hoverColor: Colors.black,
                          onTap: () => pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.bounceInOut),
                          child: Container(
                            width: Get.width * 0.2,
                            decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.elliptical(
                                      Get.width * 0.2, Get.height),
                                  bottomLeft: Radius.elliptical(
                                      Get.width * 0.2, Get.height),
                                )),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                    right: 16,
                    child: TextButton(
                      style: TextButton.styleFrom(
                          backgroundColor: Colors.black12,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8))),
                      onPressed: () => shareFileFromUrl(
                          widget.listFiles[indexPage.value].fileUrl!),
                      child: Column(
                        children: [
                          const Icon(Icons.ios_share, color: Colors.white),
                          const SizedBox(height: 4),
                          Text(AppLanguage.lang('compartilhar'),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.normal)),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ));
  }

  Widget _progress(int index, int totTimer) => Expanded(
        child: Obx(() {
          if (totTimer == countTimer.value) {
            if (indexPage.value + 1 == widget.listFiles.length) {
              Future.delayed(const Duration(seconds: 1), () => Get.back());
            } else {
              Future.delayed(const Duration(seconds: 1), () {
                pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.bounceInOut);
              });
            }
          }
          return indexPage.value == index
              ? Obx(() => LinearPercentIndicator(
                    lineHeight: 3.0,
                    percent: (countTimer / totTimer) > 1
                        ? 1
                        : (countTimer / totTimer),
                    backgroundColor: Colors.white24,
                    padding: const EdgeInsets.all(0),
                    progressColor: Colors.white70,
                    barRadius: const Radius.circular(10),
                  ))
              : Container(
                  height: 3,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: indexPage.value > index
                          ? Colors.white70
                          : Colors.white24),
                );
        }),
      );

  void shareFileFromUrl(String fileUrl) async {
    final downloadProgress = 0.0.obs;
    CancelToken cancelToken = CancelToken();

    final uri = Uri.parse(fileUrl);
    final path = uri.path;
    final segments = path.split('/');
    final fileName = segments.last;
    final extension = fileName.split('.').last;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: SizedBox(
            height: 100.0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(AppLanguage.lang('baixando_file')),
                const SizedBox(height: 20.0),
                Obx(() =>
                    LinearProgressIndicator(value: downloadProgress.value)),
              ],
            ),
          ),
        );
      },
    );

    try {
      final dio = Dio();
      final response = await dio.get(
        fileUrl,
        onReceiveProgress: (receivedBytes, totalBytes) {
          if (totalBytes != -1) {
            setState(() {
              downloadProgress.value = receivedBytes / totalBytes;
            });
          }
        },
        options: Options(responseType: ResponseType.stream),
        cancelToken: cancelToken,
      );

      final fileName = 'fileToShare.$extension';
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$fileName';

      final file = File(filePath);
      final responseStream = response.data.stream;

      await responseStream.listen(
        (data) {
          file.writeAsBytesSync(data, mode: FileMode.append);
        },
        cancelOnError: true,
        onDone: () async {
          Navigator.of(context, rootNavigator: true)
              .pop(); // Fecha o diálogo de progresso

          await Share.shareXFiles([XFile(filePath)],
              text: '${AppLanguage.lang('confira_este_file')}:');
        },
        onError: (error) {
          if (kDebugMode) {
            print('Erro ao compartilhar arquivo: $error');
          }
          Navigator.of(context, rootNavigator: true)
              .pop(); // Fecha o diálogo de progresso
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao compartilhar arquivo: $e');
      }
      Navigator.of(context, rootNavigator: true)
          .pop(); // Fecha o diálogo de progresso
    } finally {
      cancelToken.cancel();
    }
  }
}
