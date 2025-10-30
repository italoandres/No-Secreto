# Como Resetar o Onboarding

Para forçar o onboarding a aparecer novamente, você pode:

## Opção 1: Limpar dados do app (Android)
```bash
flutter clean
flutter pub get
flutter run
```
Depois vá em Configurações > Apps > Seu App > Armazenamento > Limpar dados

## Opção 2: Desinstalar e reinstalar o app
```bash
flutter clean
flutter pub get
flutter build apk --debug
flutter install
```

## Opção 3: Adicionar código temporário para resetar
No arquivo `lib/views/app_wrapper.dart`, temporariamente mude:
```dart
final isFirstTime = kIsWeb ? false : (prefs.getBool('first_time') ?? true);
```
Para:
```dart
final isFirstTime = true; // Força onboarding sempre
```

## Estrutura do Onboarding Restaurada:

✅ **Assets**: 4 GIFs em `lib/assets/onboarding/`
- slide1.gif
- slide2.gif  
- slide3.gif
- slide4.gif

✅ **Controller**: `OnboardingController` com timer de 12s para mostrar seta

✅ **View**: `OnboardingView` com:
- PageView para slides
- Seta animada após 12s
- Indicadores de página (pontos)
- Botão "Pular"
- Navegação por gestos

✅ **Fluxo**: Onboarding → Seleção de Idioma → Login → Home

✅ **Configuração**: Assets declarados no pubspec.yaml

## Status: ✅ ONBOARDING RESTAURADO E FUNCIONAL