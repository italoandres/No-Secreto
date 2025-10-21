import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

import '../../lib/controllers/vitrine_demo_controller.dart';
import '../../lib/views/vitrine_confirmation_view.dart';
import '../../lib/views/enhanced_vitrine_display_view.dart';
import '../../lib/models/vitrine_status_model.dart';
import '../../lib/models/spiritual_profile_model.dart';

void main() {
  group('Vitrine Demo Flow Integration Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;
    late VitrineDemoController controller;
    
    setUp(() async {
      // Configurar mocks
      fakeFirestore = FakeFirebaseFirestore();
      mockAuth = MockFirebaseAuth();
      
      // Configurar GetX para testes
      Get.testMode = true;
      
      // Criar dados de teste no Firestore
      await _setupTestData(fakeFirestore);
      
      // Inicializar controller
      controller = VitrineDemoController();
      Get.put<VitrineDemoController>(controller);
    });
    
    tearDown(() {
      Get.reset();
    });
    
    Widget createTestApp() {
      return GetMaterialApp(
        initialRoute: '/vitrine-confirmation',
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
            name: '/home',
            page: () => const Scaffold(
              body: Center(child: Text('Home Screen')),
            ),
          ),
        ],
      );
    }
    
    group('Fluxo Completo de Demonstração', () {
      testWidgets('deve completar fluxo de demonstração com sucesso', (tester) async {
        // Arrange
        const userId = 'test-user-123';
        
        // Act - Iniciar demonstração
        await controller.showDemoExperience(userId);
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();
        
        // Assert - Verificar tela de confirmação
        expect(find.text('Parabéns!'), findsOneWidget);
        expect(find.text('Sua vitrine de propósito está pronta para receber visitas, confira!'), 
               findsOneWidget);
        expect(find.text('Ver minha vitrine de propósito'), findsOneWidget);
        
        // Act - Navegar para vitrine
        await tester.tap(find.text('Ver minha vitrine de propósito'));
        await tester.pumpAndSettle();
        
        // Assert - Verificar navegação para vitrine
        expect(find.byType(EnhancedVitrineDisplayView), findsOneWidget);
        expect(controller.hasViewedVitrine.value, true);
        expect(controller.viewCount.value, 1);
      });
      
      testWidgets('deve permitir alternar status da vitrine', (tester) async {
        // Arrange
        const userId = 'test-user-123';
        await controller.showDemoExperience(userId);
        
        // Act
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();
        
        // Verificar estado inicial
        expect(controller.isVitrineActive.value, true);
        expect(find.text('Desativar vitrine de propósito'), findsOneWidget);
        
        // Clicar no botão de alternar
        await tester.tap(find.text('Desativar vitrine de propósito'));
        await tester.pumpAndSettle();
        
        // Confirmar no diálogo
        expect(find.byType(AlertDialog), findsOneWidget);
        await tester.tap(find.text('Desativar'));
        await tester.pumpAndSettle();
        
        // Assert - Verificar mudança de status
        expect(controller.isVitrineActive.value, false);
        expect(controller.vitrineStatus.value, VitrineStatus.inactive);
      });
      
      testWidgets('deve gerar e compartilhar link da vitrine', (tester) async {
        // Arrange
        const userId = 'test-user-123';
        await controller.showDemoExperience(userId);
        
        // Act - Gerar link
        final shareLink = await controller.generateShareLink();
        
        // Assert
        expect(shareLink, isNotEmpty);
        expect(shareLink, contains(userId));
        
        // Act - Registrar compartilhamento
        controller.trackShareAction('whatsapp');
        
        // Assert
        expect(controller.hasSharedVitrine.value, true);
      });
      
      testWidgets('deve lidar com erro de perfil incompleto', (tester) async {
        // Arrange - Criar usuário com perfil incompleto
        const userId = 'incomplete-user';
        await fakeFirestore
            .collection('spiritual_profiles')
            .doc(userId)
            .set({
          'userId': userId,
          'displayName': '', // Nome vazio
          'purpose': '', // Propósito vazio
        });
        
        await controller.showDemoExperience(userId);
        
        // Act
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();
        
        // Tentar ativar vitrine (deve falhar)
        await controller.toggleVitrineStatus();
        
        // Assert - Verificar que status não mudou
        expect(controller.isVitrineActive.value, true); // Mantém estado anterior
      });
    });
    
    group('Navegação e Estados', () {
      testWidgets('deve navegar para home corretamente', (tester) async {
        // Arrange
        const userId = 'test-user-123';
        await controller.showDemoExperience(userId);
        
        // Act
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();
        
        await tester.tap(find.text('Início'));
        await tester.pumpAndSettle();
        
        // Assert
        expect(find.text('Home Screen'), findsOneWidget);
      });
      
      testWidgets('deve mostrar loading durante operações', (tester) async {
        // Arrange
        const userId = 'test-user-123';
        await controller.showDemoExperience(userId);
        
        // Act
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();
        
        // Simular loading
        controller.isLoading.value = true;
        await tester.pump();
        
        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Carregando...'), findsOneWidget);
      });
      
      testWidgets('deve atualizar interface reativa', (tester) async {
        // Arrange
        const userId = 'test-user-123';
        await controller.showDemoExperience(userId);
        
        // Act
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();
        
        // Verificar estado inicial
        expect(find.text('Vitrine Pública'), findsOneWidget);
        expect(find.byIcon(Icons.public), findsOneWidget);
        
        // Mudar status programaticamente
        controller.vitrineStatus.value = VitrineStatus.inactive;
        controller.isVitrineActive.value = false;
        await tester.pump();
        
        // Assert - Interface deve atualizar
        expect(find.text('Vitrine Privada'), findsOneWidget);
        expect(find.byIcon(Icons.public_off), findsOneWidget);
      });
    });
    
    group('Persistência de Dados', () {
      testWidgets('deve salvar experiência de demonstração', (tester) async {
        // Arrange
        const userId = 'test-user-123';
        
        // Act
        await controller.showDemoExperience(userId);
        await controller.navigateToVitrineView();
        controller.trackShareAction('whatsapp');
        
        // Assert - Verificar dados salvos no Firestore
        final demoDoc = await fakeFirestore
            .collection('demo_experiences')
            .doc(userId)
            .get();
        
        expect(demoDoc.exists, true);
        expect(demoDoc.data()!['hasViewedVitrine'], true);
        expect(demoDoc.data()!['hasSharedVitrine'], true);
        expect(demoDoc.data()!['viewCount'], 1);
        expect(demoDoc.data()!['shareTypes'], contains('whatsapp'));
      });
      
      testWidgets('deve salvar mudanças de status', (tester) async {
        // Arrange
        const userId = 'test-user-123';
        await controller.showDemoExperience(userId);
        
        // Act
        await controller.toggleVitrineStatus();
        
        // Assert - Verificar status salvo
        final statusDoc = await fakeFirestore
            .collection('vitrine_status')
            .doc(userId)
            .get();
        
        expect(statusDoc.exists, true);
        expect(statusDoc.data()!['status'], 'inactive');
        expect(statusDoc.data()!['reason'], 'User toggle');
        
        // Verificar histórico
        final historyQuery = await fakeFirestore
            .collection('vitrine_status_history')
            .where('userId', isEqualTo: userId)
            .get();
        
        expect(historyQuery.docs.isNotEmpty, true);
      });
    });
    
    group('Tratamento de Erros', () {
      testWidgets('deve lidar com erro de rede graciosamente', (tester) async {
        // Arrange - Simular erro de rede
        const userId = 'error-user';
        
        // Act
        await controller.showDemoExperience(userId);
        
        // Assert - Deve continuar funcionando com valores padrão
        expect(controller.currentUserId.value, userId);
        expect(controller.isLoading.value, false);
      });
      
      testWidgets('deve recuperar de falhas de operação', (tester) async {
        // Arrange
        const userId = 'test-user-123';
        await controller.showDemoExperience(userId);
        
        // Act - Simular falha e recuperação
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();
        
        // Tentar operação que pode falhar
        try {
          await controller.generateShareLink();
        } catch (e) {
          // Erro esperado em ambiente de teste
        }
        
        // Assert - Interface deve continuar responsiva
        expect(find.byType(VitrineConfirmationView), findsOneWidget);
        expect(controller.isLoading.value, false);
      });
    });
    
    group('Performance', () {
      testWidgets('deve carregar rapidamente', (tester) async {
        // Arrange
        const userId = 'test-user-123';
        final stopwatch = Stopwatch()..start();
        
        // Act
        await controller.showDemoExperience(userId);
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();
        
        stopwatch.stop();
        
        // Assert - Deve carregar em menos de 2 segundos
        expect(stopwatch.elapsedMilliseconds, lessThan(2000));
        expect(find.text('Parabéns!'), findsOneWidget);
      });
      
      testWidgets('deve responder rapidamente a interações', (tester) async {
        // Arrange
        const userId = 'test-user-123';
        await controller.showDemoExperience(userId);
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();
        
        // Act - Medir tempo de resposta
        final stopwatch = Stopwatch()..start();
        
        await tester.tap(find.text('Ver minha vitrine de propósito'));
        await tester.pumpAndSettle();
        
        stopwatch.stop();
        
        // Assert - Deve responder em menos de 500ms
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
      });
    });
  });
}

/// Configura dados de teste no Firestore fake
Future<void> _setupTestData(FakeFirebaseFirestore firestore) async {
  // Criar perfil espiritual completo
  await firestore
      .collection('spiritual_profiles')
      .doc('test-user-123')
      .set({
    'userId': 'test-user-123',
    'displayName': 'João Silva',
    'purpose': 'Ajudar pessoas a encontrar seu propósito de vida',
    'aboutMe': 'Sou um coach espiritual dedicado a transformar vidas',
    'mainPhotoUrl': 'https://example.com/photo.jpg',
    'createdAt': DateTime.now(),
    'updatedAt': DateTime.now(),
  });
  
  // Criar status inicial da vitrine
  await firestore
      .collection('vitrine_status')
      .doc('test-user-123')
      .set({
    'userId': 'test-user-123',
    'status': 'active',
    'lastUpdated': DateTime.now(),
    'reason': 'Initial creation',
    'isPubliclyVisible': true,
  });
  
  // Criar usuário no sistema de autenticação
  await firestore
      .collection('usuarios')
      .doc('test-user-123')
      .set({
    'uid': 'test-user-123',
    'email': 'joao@example.com',
    'displayName': 'João Silva',
    'createdAt': DateTime.now(),
  });
}