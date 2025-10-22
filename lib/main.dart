
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:whatsapp_chat/repositories/login_repository.dart';
import 'package:whatsapp_chat/services/automatic_message_service.dart';
import '/views/select_language_view.dart';
import '/views/onboarding_view.dart';
import '/views/app_wrapper.dart';
import '/test_onboarding.dart';
import '/views/vitrine_confirmation_view.dart';
import '/views/enhanced_vitrine_display_view.dart';
import '/views/explore_profiles_view.dart';
import '/views/profile_display_view.dart';
import '/views/profile_display_vitrine_wrapper.dart';
import '/views/interest_dashboard_view.dart';
import '/views/simple_accepted_matches_view.dart';
import '/views/romantic_match_chat_view.dart';
import '/views/vitrine_menu_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/utils/test_vitrine_complete_search.dart'; // 🔍 DEBUG VITRINE
import '/utils/deep_vitrine_investigation.dart'; // 🔍 INVESTIGAÇÃO PROFUNDA
import '/utils/simple_vitrine_debug.dart'; // 🔍 DEBUG SIMPLES
import '/utils/dual_collection_debug.dart'; // 🔍 DEBUG DUAS COLEÇÕES
import '/utils/force_notifications_now.dart'; // 🚀 SOLUÇÃO DEFINITIVA NOTIFICAÇÕES
import '/utils/fix_timestamp_chat_errors.dart'; // 🔧 CORREÇÃO DE TIMESTAMPS
import '/services/auto_chat_monitor.dart'; // 🔍 MONITOR AUTOMÁTICO

import '/theme.dart';
import '/token_usuario.dart';
import '/views/home_view.dart';
import 'controllers/notification_controller.dart';
import 'routes.dart';
import 'views/login_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/route_manager.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Otimizações de performance
  if (!kIsWeb) {
    // Configurar orientação para evitar rebuilds desnecessários
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // Otimizar renderização
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));
  }
  
  // Only initialize platform-specific features on non-web platforms
  if (!kIsWeb) {
    try {
      tz.initializeTimeZones();
      NotificationController().initNotification();
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    } catch (e) {
      debugPrint('⚠️ Erro na inicialização de recursos específicos da plataforma: $e');
    }
  }
  
  await TokenUsuario().initTokenUsuario();
  if(!kIsWeb) {
    try {
      await Firebase.initializeApp();
      debugPrint('✅ Firebase inicializado com sucesso');
      
      // Firebase Admin desabilitado para evitar crashes em dispositivos reais
      // if(kDebugMode && LoginRepository.appFirebaseAdmin == null) {
      //   try {
      //     await LoginRepository.initFirebaseAdmin();
      //     debugPrint('✅ Firebase Admin inicializado');
      //   } catch (e) {
      //     debugPrint('⚠️ Firebase Admin não pôde ser inicializado: $e');
      //   }
      // }
      
      try {
        FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
        FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
        debugPrint('✅ Crashlytics configurado');
      } catch (e) {
        debugPrint('⚠️ Erro ao configurar Crashlytics: $e');
      }
      
      // Inicializar serviço de mensagens automáticas
      try {
        AutomaticMessageService.initialize();
        debugPrint('✅ Serviço de mensagens automáticas inicializado');
      } catch (e) {
        debugPrint('⚠️ Erro ao inicializar serviço de mensagens automáticas: $e');
      }
      
      // Sistema de matches removido - usando sistema de notificações de interesse
      debugPrint('✅ Sistema de notificações de interesse ativo');
      
      // 🔍 DEBUG: Registrar funções de teste de vitrine
      if (kDebugMode) {
        TestVitrineCompleteSearch.registerGlobalTestFunction();
        DeepVitrineInvestigation.registerConsoleFunction();
      }
      
      // 🔧 CORREÇÃO DE EMERGÊNCIA: COMENTADO - Causava erros de permissão
      // Future.delayed(const Duration(seconds: 3), () async {
      //   try {
      //     debugPrint('🚀 INICIANDO CORREÇÃO DE EMERGÊNCIA DE TIMESTAMPS...');
      //     await TimestampChatErrorsFixer.fixAllTimestampErrors();
      //     debugPrint('✅ CORREÇÃO DE TIMESTAMPS CONCLUÍDA!');
      //     
      //     // Iniciar monitoramento automático após correção
      //     AutoChatMonitor.startMonitoring();
      //     debugPrint('🔍 MONITOR AUTOMÁTICO DE CHAT INICIADO!');
      //   } catch (e) {
      //     debugPrint('❌ Erro na correção de timestamps: $e');
      //   }
      // });
      
      // 🚀 SOLUÇÃO DEFINITIVA: COMENTADO - Causava erros de permissão
      // Future.delayed(const Duration(seconds: 8), () async {
      //   try {
      //     await ForceNotificationsNow.execute('St2kw3cgX2MMPxlLRmBDjYm2nO22');
      //     debugPrint('🎉 SOLUÇÃO DEFINITIVA DE NOTIFICAÇÕES EXECUTADA!');
      //   } catch (e) {
      //     debugPrint('⚠️ Erro na solução definitiva: $e');
      //   }
      // });
    } catch (e) {
      debugPrint('❌ Erro na inicialização do Firebase: $e');
      // Continuar mesmo com erro do Firebase
    }
  } else {
    setPathUrlStrategy();
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyBstIEyw9AhXwnrfnCy4234SbTHdYtmVsw",
        authDomain: "app-no-secreto-com-o-pai.firebaseapp.com",
        projectId: "app-no-secreto-com-o-pai",
        storageBucket: "app-no-secreto-com-o-pai.firebasestorage.app",
        messagingSenderId: "490614568896",
        appId: "1:490614568896:web:3fef2cd88964958aff7a25",
        measurementId: "G-E1NQZXWKDN"
      )
    );
    
    // 🔍 DEBUG: COMENTADO - Causava erros de permissão no Firestore
    // if (kDebugMode) {
    //   Future.delayed(const Duration(seconds: 3), () {
    //     DualCollectionDebug.debugBothCollections();
    //   });
    //   
    //   // 🔧 CORREÇÃO DE EMERGÊNCIA NA WEB: Executar fix de timestamps após 5 segundos
    //   Future.delayed(const Duration(seconds: 5), () async {
    //     try {
    //       debugPrint('🚀 INICIANDO CORREÇÃO DE EMERGÊNCIA DE TIMESTAMPS NA WEB...');
    //       await TimestampChatErrorsFixer.fixAllTimestampErrors();
    //       debugPrint('✅ CORREÇÃO DE TIMESTAMPS NA WEB CONCLUÍDA!');
    //       
    //       // Iniciar monitoramento automático na web
    //       AutoChatMonitor.startMonitoring();
    //       debugPrint('🔍 MONITOR AUTOMÁTICO DE CHAT INICIADO NA WEB!');
    //     } catch (e) {
    //       debugPrint('❌ Erro na correção de timestamps na web: $e');
    //     }
    //   });
    //   
    //   // 🚀 SOLUÇÃO DEFINITIVA: Executar fix de notificações reais na web após 10 segundos
    //   Future.delayed(const Duration(seconds: 10), () async {
    //     try {
    //       await ForceNotificationsNow.execute('St2kw3cgX2MMPxlLRmBDjYm2nO22');
    //       debugPrint('🎉 SOLUÇÃO DEFINITIVA DE NOTIFICAÇÕES EXECUTADA NA WEB!');
    //     } catch (e) {
    //       debugPrint('⚠️ Erro na solução definitiva na web: $e');
    //     }
    //   });
    // }
  }

  runApp(GetMaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.theme,
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [
      Locale('pt', 'BR'),
      Locale('en', 'US'),
      Locale('es', 'ES'),
    ],
    locale: const Locale('pt', 'BR'), // Set default locale for web
    builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!),
    home: const MyApp(), // Always use MyApp which includes onboarding flow
    // home: const TestOnboardingView(), // Descomente para testar assets
    
    // Configurar rotas GetX para vitrine
    getPages: [
      GetPage(
        name: '/vitrine-confirmation',
        page: () => const VitrineConfirmationView(),
      ),
      GetPage(
        name: '/vitrine-display',
        page: () => const EnhancedVitrineDisplayView(),
      ),
      GetPage(
        name: '/vitrine-menu',
        page: () => VitrineMenuView(),
        transition: Transition.rightToLeft,
      ),
      // Rota /matches redirecionada para dashboard de interesse
      GetPage(
        name: '/matches',
        page: () => const InterestDashboardView(),
        transition: Transition.rightToLeft,
      ),
      GetPage(
        name: '/interest-dashboard',
        page: () => const InterestDashboardView(),
        transition: Transition.rightToLeft,
      ),
      GetPage(
        name: '/explore-profiles',
        page: () => const ExploreProfilesView(),
      ),
      GetPage(
        name: '/profile-display',
        page: () {
          final arguments = Get.arguments as Map<String, dynamic>?;
          final profileId = arguments?['profileId'] as String?;
          if (profileId == null) {
            return const Scaffold(
              body: Center(child: Text('Perfil não encontrado')),
            );
          }
          // Usar a versão bonita da vitrine para visualização de perfis
          return ProfileDisplayVitrineWrapper(userId: profileId);
        },
      ),
      // Rotas do sistema de matches aceitos
      GetPage(
        name: '/accepted-matches',
        page: () => const SimpleAcceptedMatchesView(),
        transition: Transition.rightToLeft,
        transitionDuration: const Duration(milliseconds: 300),
      ),
      GetPage(
        name: '/match-chat',
        page: () {
          final arguments = Get.arguments as Map<String, dynamic>?;
          final chatId = arguments?['chatId'] as String?;
          final otherUserId = arguments?['otherUserId'] as String?;
          final otherUserName = arguments?['otherUserName'] as String?;
          final otherUserPhoto = arguments?['otherUserPhoto'] as String?;
          final matchDate = arguments?['matchDate'] as DateTime?;
          
          if (chatId == null || otherUserId == null || otherUserName == null || matchDate == null) {
            return const Scaffold(
              body: Center(child: Text('Parâmetros de chat inválidos')),
            );
          }
          
          return RomanticMatchChatView(
            chatId: chatId,
            otherUserId: otherUserId,
            otherUserName: otherUserName,
            otherUserPhotoUrl: otherUserPhoto,
          );
        },
        transition: Transition.rightToLeft,
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ],
    
    onGenerateRoute: !kIsWeb ? null : (RouteSettings settings) {
      return MaterialPageRoute(
        settings: settings,
        builder: (context) => PageRoutes.getPageFromString(settings.name!.split('?')[0])
      );
    },
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context){
    return const AppWrapper();
  }
}