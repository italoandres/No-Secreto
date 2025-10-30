# 🔍 CAUSA RAIZ DO TIMEOUT NO LOGIN

## ✅ Descoberta

As chaves SHA estão **CORRETAS** no Firebase. O problema do timeout de 30 segundos **NÃO é causado pelas chaves SHA**.

## 🎯 Causa Real Identificada

Analisando o código em `lib/repositories/login_repository.dart`, o método `loginComGoogle()` tem um fluxo que pode causar timeout:

### Linha 189-195 (Problema Potencial):
```dart
GoogleSignInAccount? googleUser = await googleSignIn.signIn();

if (googleUser == null) {
  safePrint('Google Sign-In: User cancelled the sign-in');
  return;
}
```

### Linha 218-220 (Dialog de Loading):
```dart
Get.defaultDialog(
    title: AppLanguage.lang('validando'),
    content: const CircularProgressIndicator(),
    barrierDismissible: false);
```

## 🔍 Possíveis Causas do Timeout

### 1. **Problema de Configuração do Google Sign-In no APK Release**
   - O Google Sign-In pode estar configurado apenas para debug
   - SHA-1 está correta, mas pode faltar configuração adicional

### 2. **Problema de Rede/Firewall**
   - O APK release pode estar bloqueado por algum firewall
   - Timeout de 30s sugere que está esperando resposta que nunca chega

### 3. **Problema com google-services.json**
   - O arquivo pode estar desatualizado
   - Pode ter configurações diferentes para debug vs release

### 4. **Problema com OAuth Client ID**
   - Pode estar faltando o OAuth Client ID para Android (Release)
   - Apenas o debug pode estar configurado

## 🔧 Soluções Recomendadas

### Solução 1: Verificar google-services.json
```powershell
# Baixar novo google-services.json do Firebase Console
# Substituir o arquivo em: android/app/google-services.json
```

### Solução 2: Adicionar OAuth Client ID para Release
1. Acesse: https://console.cloud.google.com/apis/credentials
2. Verifique se existe um "OAuth 2.0 Client ID" para Android (Release)
3. Se não existir, crie um novo com a SHA-1 do release keystore

### Solução 3: Adicionar Timeout Explícito no Código
Modificar o método `loginComGoogle()` para ter timeout explícito:

```dart
static Future<void> loginComGoogle() async {
  safePrint('Google Sign-In: Starting authentication process');

  final GoogleSignIn googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  try {
    safePrint('Google Sign-In: Calling googleSignIn.signIn()');
    
    // ADICIONAR TIMEOUT EXPLÍCITO
    GoogleSignInAccount? googleUser = await googleSignIn.signIn()
        .timeout(
          const Duration(seconds: 60),
          onTimeout: () {
            safePrint('Google Sign-In: TIMEOUT após 60 segundos');
            Get.rawSnackbar(
              message: 'Timeout ao fazer login. Verifique sua conexão.',
              duration: const Duration(seconds: 5),
            );
            return null;
          },
        );
    
    // ... resto do código
```

### Solução 4: Verificar Configuração no Firebase Console

**PASSO A PASSO:**

1. Acesse: https://console.firebase.google.com
2. Selecione seu projeto
3. Vá em "Authentication" → "Sign-in method"
4. Verifique se "Google" está habilitado
5. Clique em "Google" e verifique:
   - ✅ Status: Enabled
   - ✅ Web SDK configuration está preenchido
   - ✅ Support email está configurado

6. Vá em "Project Settings" → "General"
7. Role até "Your apps" → Android app
8. Verifique:
   - ✅ SHA-1: `18:EA:F9:C1:2C:61:48:27:C6:8C:E6:30:BC:58:17:24:A0:E5:7B:53`
   - ✅ SHA-256: `82:7A:FA:18:96:D4:B2:92:EE:1E:1F:5B:C7:96:2A:E5:15:66:D2:13:1D:9D:E1:61:DE:85:B3:8E:9D:4E:06:03`
   - ✅ Baixe o `google-services.json` mais recente

## 📊 Próximos Passos

### Opção A: Verificação Rápida (5 minutos)
1. Baixar novo `google-services.json` do Firebase
2. Substituir em `android/app/`
3. Rebuild do APK
4. Testar

### Opção B: Verificação Completa (15 minutos)
1. Verificar OAuth Client IDs no Google Cloud Console
2. Criar novo OAuth Client ID para Release (se não existir)
3. Baixar novo `google-services.json`
4. Adicionar timeout explícito no código
5. Rebuild e testar

### Opção C: Debug Detalhado (30 minutos)
1. Adicionar logs mais detalhados
2. Capturar logs do logcat durante o login
3. Identificar exatamente onde trava
4. Aplicar correção específica

## 🎯 Recomendação

Começar com **Opção A** (mais rápida). Se não resolver, partir para **Opção B**.

O problema muito provavelmente é:
- ❌ Não é as chaves SHA (já confirmamos que estão corretas)
- ✅ Provavelmente é configuração do OAuth Client ID
- ✅ Ou google-services.json desatualizado
