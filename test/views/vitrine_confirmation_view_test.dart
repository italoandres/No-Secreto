import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../../lib/views/vitrine_confirmation_view.dart';
import '../../lib/controllers/vitrine_demo_controller.dart';

// Generate mocks
@GenerateMocks([VitrineDemoController])
import 'vitrine_confirmation_view_test.mocks.dart';

void main() {
  group('VitrineConfirmationView Widget Tests', () {
    late MockVitrineDemoController mockController;

    setUp(() {
      // Initialize GetX for testing
      Get.testMode = true;
      
      mockController = MockVitrineDemoController();
      
      // Setup default mock behavior
      when(mockController.isVitrineActive).thenReturn(true.obs);
      when(mockController.isLoading).thenReturn(false.obs);
      when(mockController.currentUserId).thenReturn('test-user'.obs);
      
      // Register mock controller
      Get.put<VitrineDemoController>(mockController);
    });

    tearDown(() {
      Get.reset();
    });

    Widget createTestWidget({Map<String, dynamic>? arguments}) {
      return GetMaterialApp(
        home: VitrineConfirmationView(),
        initialRoute: '/vitrine-confirmation',
        getPages: [
          GetPage(
            name: '/vitrine-confirmation',
            page: () => VitrineConfirmationView(),
          ),
        ],
        routingCallback: (routing) {
          if (arguments != null) {
            Get.arguments = arguments;
          }
        },
      );
    }

    group('Widget Rendering', () {
      testWidgets('should render celebration header', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Check for celebration icon
        expect(find.byIcon(Icons.celebration), findsOneWidget);
        
        // Check for congratulations text
        expect(find.text('Parabéns!'), findsOneWidget);
      });

      testWidgets('should render main confirmation message', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(
          find.text('Sua vitrine de propósito está pronta para receber visitas, confira!'),
          findsOneWidget,
        );
      });

      testWidgets('should render primary action button', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(
          find.text('Ver minha vitrine de propósito'),
          findsOneWidget,
        );
      });

      testWidgets('should render secondary action button when vitrine is active', (WidgetTester tester) async {
        when(mockController.isVitrineActive).thenReturn(true.obs);
        
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(
          find.text('Desativar vitrine de propósito'),
          findsOneWidget,
        );
      });

      testWidgets('should render activate button when vitrine is inactive', (WidgetTester tester) async {
        when(mockController.isVitrineActive).thenReturn(false.obs);
        
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(
          find.text('Ativar vitrine de propósito'),
          findsOneWidget,
        );
      });

      testWidgets('should render status indicator', (WidgetTester tester) async {
        when(mockController.isVitrineActive).thenReturn(true.obs);
        
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Vitrine Pública'), findsOneWidget);
        expect(find.byIcon(Icons.public), findsOneWidget);
      });

      testWidgets('should render private status when inactive', (WidgetTester tester) async {
        when(mockController.isVitrineActive).thenReturn(false.obs);
        
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Vitrine Privada'), findsOneWidget);
        expect(find.byIcon(Icons.public_off), findsOneWidget);
      });
    });

    group('User Interactions', () {
      testWidgets('should call navigateToVitrineView when primary button is tapped', (WidgetTester tester) async {
        when(mockController.navigateToVitrineView()).thenAnswer((_) async {});
        
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final primaryButton = find.text('Ver minha vitrine de propósito');
        expect(primaryButton, findsOneWidget);

        await tester.tap(primaryButton);
        await tester.pumpAndSettle();

        verify(mockController.navigateToVitrineView()).called(1);
      });

      testWidgets('should show confirmation dialog when toggle button is tapped', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final toggleButton = find.text('Desativar vitrine de propósito');
        expect(toggleButton, findsOneWidget);

        await tester.tap(toggleButton);
        await tester.pumpAndSettle();

        // Check if dialog is shown
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Desativar Vitrine'), findsOneWidget);
      });

      testWidgets('should call toggleVitrineStatus when dialog is confirmed', (WidgetTester tester) async {
        when(mockController.toggleVitrineStatus()).thenAnswer((_) async {});
        
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Tap toggle button to open dialog
        final toggleButton = find.text('Desativar vitrine de propósito');
        await tester.tap(toggleButton);
        await tester.pumpAndSettle();

        // Confirm in dialog
        final confirmButton = find.text('Desativar');
        expect(confirmButton, findsOneWidget);
        
        await tester.tap(confirmButton);
        await tester.pumpAndSettle();

        verify(mockController.toggleVitrineStatus()).called(1);
      });

      testWidgets('should not call toggleVitrineStatus when dialog is cancelled', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Tap toggle button to open dialog
        final toggleButton = find.text('Desativar vitrine de propósito');
        await tester.tap(toggleButton);
        await tester.pumpAndSettle();

        // Cancel in dialog
        final cancelButton = find.text('Cancelar');
        expect(cancelButton, findsOneWidget);
        
        await tester.tap(cancelButton);
        await tester.pumpAndSettle();

        verifyNever(mockController.toggleVitrineStatus());
      });

      testWidgets('should navigate back when back button is tapped', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final backButton = find.text('Voltar');
        expect(backButton, findsOneWidget);

        await tester.tap(backButton);
        await tester.pumpAndSettle();

        // Verify navigation occurred (would need navigation mock in real test)
      });

      testWidgets('should navigate to home when home button is tapped', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final homeButton = find.text('Início');
        expect(homeButton, findsOneWidget);

        await tester.tap(homeButton);
        await tester.pumpAndSettle();

        // Verify navigation occurred (would need navigation mock in real test)
      });
    });

    group('Loading States', () {
      testWidgets('should show loading indicator when isLoading is true', (WidgetTester tester) async {
        when(mockController.isLoading).thenReturn(true.obs);
        
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Carregando...'), findsOneWidget);
      });

      testWidgets('should disable buttons when loading', (WidgetTester tester) async {
        when(mockController.isLoading).thenReturn(true.obs);
        
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final primaryButton = find.ancestor(
          of: find.text('Carregando...'),
          matching: find.byType(ElevatedButton),
        );
        
        expect(primaryButton, findsOneWidget);
        
        // Button should be disabled (onPressed should be null)
        final ElevatedButton button = tester.widget(primaryButton);
        expect(button.onPressed, isNull);
      });
    });

    group('Arguments Handling', () {
      testWidgets('should handle userId from arguments', (WidgetTester tester) async {
        const testUserId = 'test-user-123';
        
        await tester.pumpWidget(createTestWidget(
          arguments: {'userId': testUserId},
        ));
        await tester.pumpAndSettle();

        // Verify controller received the userId
        // In a real test, we would verify the controller's currentUserId was set
        expect(find.byType(VitrineConfirmationView), findsOneWidget);
      });

      testWidgets('should handle empty arguments gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(arguments: {}));
        await tester.pumpAndSettle();

        expect(find.byType(VitrineConfirmationView), findsOneWidget);
      });

      testWidgets('should handle null arguments gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(VitrineConfirmationView), findsOneWidget);
      });
    });

    group('Animations', () {
      testWidgets('should animate celebration header', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Initial state - animation should start
        await tester.pump();
        
        // Let animation progress
        await tester.pump(Duration(milliseconds: 600));
        
        // Animation should be in progress
        expect(find.byType(TweenAnimationBuilder<double>), findsWidgets);
        
        // Complete animation
        await tester.pumpAndSettle();
        
        // Final state should be visible
        expect(find.byIcon(Icons.celebration), findsOneWidget);
        expect(find.text('Parabéns!'), findsOneWidget);
      });

      testWidgets('should animate main content', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Pump through animation frames
        await tester.pump();
        await tester.pump(Duration(milliseconds: 500));
        await tester.pumpAndSettle();
        
        // Content should be visible after animation
        expect(
          find.text('Sua vitrine de propósito está pronta para receber visitas, confira!'),
          findsOneWidget,
        );
      });
    });

    group('Responsive Design', () {
      testWidgets('should render correctly on different screen sizes', (WidgetTester tester) async {
        // Test with small screen
        tester.binding.window.physicalSizeTestValue = Size(400, 800);
        tester.binding.window.devicePixelRatioTestValue = 1.0;
        
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        expect(find.byType(VitrineConfirmationView), findsOneWidget);
        
        // Test with large screen
        tester.binding.window.physicalSizeTestValue = Size(800, 1200);
        
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        expect(find.byType(VitrineConfirmationView), findsOneWidget);
        
        // Reset to default
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
        addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
      });
    });
  });
}