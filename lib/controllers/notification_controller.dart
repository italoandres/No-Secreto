import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:whatsapp_chat/repositories/usuario_repository.dart';
import 'package:whatsapp_chat/views/storie_view.dart';

import '../models/storie_file_model.dart';
import '../models/usuario_model.dart';
import '../repositories/notificacoes_repository.dart';
import '../repositories/stories_repository.dart';
import '../repositories/chat_repository.dart';
import '../token_usuario.dart';

void onDidReceiveLocalNotification(
    int id, String? title, String? body, String? payload) async {
  await Firebase.initializeApp();
}

void onDidReceiveBackgroundNotificationResponse(NotificationResponse n) async {
  await Firebase.initializeApp();

  // Se for a notificação de 3 dias de inatividade
  if (n.payload == 'local_notification_agendado') {
    // Enviar mensagem automática no chat principal
    await ChatRepository.sendAutomaticPaiMessage();
  }
}

class NotificationController {
  static final NotificationController _notificationController =
      NotificationController._internal();

  factory NotificationController() {
    return _notificationController;
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationController._internal();

  Future<void> initNotification() async {
    // Android initialization
    AndroidInitializationSettings initializationSettingsAndroid =
        const AndroidInitializationSettings('@mipmap/ic_launcher');

    // ios initialization
    DarwinInitializationSettings initializationSettingsIOS =
        const DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS);
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveBackgroundNotificationResponse:
          onDidReceiveBackgroundNotificationResponse,
      onDidReceiveNotificationResponse:
          onDidReceiveBackgroundNotificationResponse,
    );
  }

  Future<void> setNotification() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    if (TokenUsuario().lastId > 0) {
      cancelar(TokenUsuario().lastId);
    }
    int newId = TokenUsuario().lastId + 1;
    await flutterLocalNotificationsPlugin.zonedSchedule(
      newId,
      'Pai',
      '${TokenUsuario().sexo == UserSexo.masculino ? 'Filho' : 'Filha'} como você está?',
      tz.TZDateTime.now(tz.local).add(const Duration(days: 3)
          //const Duration(seconds: 3)
          ),
      const NotificationDetails(
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: false,
            presentSound: true,
          ),
          android: AndroidNotificationDetails(
            'channel id',
            'channel name',
            importance: Importance.max,
            priority: Priority.high,
          )),
      payload: 'local_notification_agendado',
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    TokenUsuario().lastId = newId;
  }

  cancelar(int id) => flutterLocalNotificationsPlugin.cancel(id);

  static Future<void> startFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Topic subscription is not supported on web
    if (!kIsWeb) {
      await FirebaseMessaging.instance.subscribeToTopic('usuarios');
      await FirebaseMessaging.instance.unsubscribeFromTopic('en');
      await FirebaseMessaging.instance.unsubscribeFromTopic('pt');
      await FirebaseMessaging.instance.unsubscribeFromTopic('es');
      await FirebaseMessaging.instance.unsubscribeFromTopic('sexo_m');
      await FirebaseMessaging.instance.unsubscribeFromTopic('sexo_f');
      await FirebaseMessaging.instance.subscribeToTopic(TokenUsuario().idioma);
    }
    UsuarioModel? user = await UsuarioRepository.getUser().first;
    if (user != null && !kIsWeb) {
      if (user.sexo == UserSexo.feminino) {
        await FirebaseMessaging.instance.subscribeToTopic('sexo_f');
      } else {
        await FirebaseMessaging.instance.subscribeToTopic('sexo_m');
      }
    }
    String? tokenFcm = await FirebaseMessaging.instance.getToken();
    await NotificacoesRepository.updateUserFcmToken(token: '$tokenFcm');
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) =>
        _showNotificationFCM(message, 'onMessageOpenedApp'));
    FirebaseMessaging.onMessage.listen(
        (RemoteMessage event) => _showNotificationFCM(event, 'onMessage'));
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    _showNotificationFCM(message, 'onBackgroundMessage');
  }

  static _showNotificationFCM(RemoteMessage message, String origem) {
    if (origem == 'onMessageOpenedApp' &&
        '${message.data['abrir_stories']}' == 'true') {
      Future.delayed(Duration.zero, () async {
        Get.defaultDialog(
            title: 'Carregando...',
            content: const CircularProgressIndicator(),
            barrierDismissible: false);
        List<StorieFileModel> storiesAntigos =
            await StoriesRepository.getAllAntigos().first;
        List<StorieFileModel> storiesNovos =
            await StoriesRepository.getAll().first;
        List<StorieFileModel> listStories = [];
        for (var element in storiesNovos) {
          if (DateTime.now()
                  .difference(element.dataCadastro!.toDate())
                  .inMinutes <=
              (24 * 60)) {
            listStories.add(element);
          }
        }
        for (var element in storiesAntigos) {
          if (DateTime.now()
                      .difference(element.dataCadastro!.toDate())
                      .inMinutes <=
                  (24 * 60) &&
              DateTime.now()
                      .difference(element.dataCadastro!.toDate())
                      .inMinutes >
                  0) {
            listStories.add(element);
          }
        }
        listStories.removeWhere((element) =>
            element.idioma != null && element.idioma != TokenUsuario().idioma);
        listStories.sort((a, b) => a.dataCadastro!.compareTo(b.dataCadastro!));
        Get.back();
        if (listStories.isNotEmpty) {
          Get.to(() => StorieView(listFiles: listStories));
        }
      });
      return;
    }

    Get.defaultDialog(
        title: '${message.notification!.title}',
        content: message.notification!.android?.imageUrl == null
            ? Text('${message.notification!.body}')
            : Column(
                children: [
                  Text('${message.notification!.body}'),
                  Image.network('${message.notification!.android?.imageUrl}',
                      errorBuilder:
                          (BuildContext context, Object o, StackTrace? s) {
                    return const SizedBox();
                  })
                ],
              ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            onPressed: () async {
              Get.back();
              final url = message.notification!.android?.link;
              if (url != null) {
                if (!await launchUrl(Uri.parse(url)))
                  throw 'Could not launch $url';
              }
            },
            child: const Text('Ok'),
          )
        ]);
  }

  static Future<void> sendNotificationToTopic(
      {required String titulo,
      required String msg,
      required bool abrirStories,
      String? topico}) async {
    Map<String, String> headerMap = {
      'Content-Type': 'application/json',
      'Authorization':
          'key=AAAA_nph8uo:APA91bFkfuLlOW0pmowFmlE4Pfd3M9K-xSaJ5ZGN_7HICb26CKTSjs0JelQlXazYP0RUVbpZ_l-lxWzPxE0HJ9bx8ZAuxm8AjkTvHGvJTEJiJcF57UQ-RiyBFZkEPAYCNguLLkRkyKDR',
    };
    Map notificationMap = {'body': msg, 'title': titulo};
    Map sendNotificationMap = {
      "notification": notificationMap,
      "priority": "high",
      "to": '/topics/${topico ?? 'usuarios'}',
    };

    if (abrirStories == true) {
      sendNotificationMap['data'] = {'abrir_stories': 'true'};
    }

    final res = await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: headerMap,
      body: jsonEncode(sendNotificationMap),
    );

    debugPrint('-------');
    debugPrint(res.body);
    debugPrint('-------');
  }
}
