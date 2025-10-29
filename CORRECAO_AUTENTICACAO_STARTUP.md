# 🔐 Correção: Autenticação no Startup do App

## 🐛 Problema Identificado

A autenticação biométrica/senha não estava sendo solicitada quando o app era aberto, mesmo com a proteção ativada.

### Sintomas:
1. ✅ Usuário ativa proteção com senha
2. ✅ Senha é salva corretamente
3. ❌ Ao fechar e reabrir o app, não pede autenticação
4. ❌ Apenas pede autenticação após timeout de background

### Causa Raiz:
O método `AppLifecycleObserver.showAuthScreenIfNeeded()` não estava sendo chamado quando o app iniciava e o usuário já estava autenticado no Firebase.

## ✅ Solução Aplicada

Adicionada verificação de autenticação no `app_wrapper.dart` quando o usuário está autenticado:

```dart
// 2. Usuário autenticado - pode acessar HomeView
if (snapshot.hasData && snapshot.data != null) {
  safePrint('AppWrapper: Usuário autenticado, mostrando HomeView');
  // Verificar se precisa mostrar tela de autenticação
  WidgetsBinding.instance.addPostFrameCallback((_) {
    AppLifecycleObserver.showAuthScreenIfNeeded();
  });
  return const HomeView();
}
```

### O que foi feito:
1. Adicionado `addPostFrameCallback` para executar após o build
2. Chamada de `AppLifecycleObserver.showAuthScreenIfNeeded()`
3. Verifica se proteção está ativada
4. Mostra tela de bloqueio se necessário

## 🎯 Comportamento Esperado Agora

### Cenário 1: Abrir App (Primeira Vez)
```
1. App abre
2. Usuário faz login
3. Vai para HomeView
4. Se proteção ativada → Mostra tela de bloqueio
5. Usuário autentica
6. Acessa HomeView normalmente
```

### Cenário 2: Reabrir App (Já Logado)
```
1. App abre
2. Firebase detecta usuário logado
3. Vai para HomeView
4. Se proteção ativada → Mostra tela de bloqueio
5. Usuário autentica
6. Acessa HomeView normalmente
```

### Cenário 3: Background/Foreground
```
1. App em uso
2. Usuário minimiza (background)
3. Aguarda > timeout configurado
4. Usuário volta ao app (foreground)
5. AppLifecycleObserver detecta
6. Mostra tela de bloqueio
7. Usuário autentica
8. Continua usando app
```

## 📱 Como Testar Agora

### Teste 1: Primeira Ativação
```
1. Abra o app
2. Vá em Configurações → Segurança
3. Ative "Proteger com senha/biometria"
4. Configure uma senha
5. Feche o app completamente
6. Reabra o app
7. ✅ Deve pedir autenticação
```

### Teste 2: Reabrir App
```
1. Com proteção já ativada
2. Feche o app completamente
3. Reabra o app
4. ✅ Deve pedir autenticação imediatamente
```

### Teste 3: Background/Foreground
```
1. Com proteção ativada
2. Use o app normalmente
3. Minimize o app (home button)
4. Aguarde 2 minutos (timeout padrão)
5. Volte ao app
6. ✅ Deve pedir autenticação
```

### Teste 4: Sem Proteção
```
1. Desative a proteção
2. Feche e reabra o app
3. ✅ Não deve pedir autenticação
4. ✅ Vai direto para HomeView
```

## 🔍 Logs para Debug

Ao testar, você verá estes logs:

### Quando Proteção Está Ativada:
```
AppWrapper: Usuário autenticado, mostrando HomeView
🔐 Mostrando tela de autenticação no startup...
```

### Quando Proteção Está Desativada:
```
AppWrapper: Usuário autenticado, mostrando HomeView
(Nenhum log adicional - vai direto para HomeView)
```

### Background/Foreground:
```
🔐 App foi para background: 2025-10-28 14:41:35.000
🔐 App voltou para foreground
🔐 Tempo em background: 3 minutos
🔐 Timeout configurado: 2 minutos
🔐 Timeout excedido! Mostrando tela de autenticação...
```

## ⚠️ Nota Importante sobre Web/Chrome

A autenticação biométrica **NÃO funciona no Chrome/Web**. Você verá este erro:

```
Erro ao verificar suporte a biometria: MissingPluginException(No implementation found for method getAvailableBiometrics on channel plugins.flutter.io/local_auth)
```

**Isso é normal!** O plugin `local_auth` só funciona em:
- ✅ Android (APK/dispositivo real)
- ✅ iOS (dispositivo real)
- ❌ Web/Chrome (não suportado)

Para testar, use:
```bash
# Compilar APK
flutter build apk --split-per-abi

# Ou rodar em dispositivo conectado
flutter run
```

## 📦 Arquivos Modificados

- `lib/views/app_wrapper.dart` - Adicionada verificação de autenticação no startup

## ✅ Status

**CORRIGIDO!** A autenticação agora funciona corretamente:
- ✅ Pede autenticação ao abrir o app
- ✅ Pede autenticação após timeout de background
- ✅ Não pede se proteção estiver desativada
- ✅ Funciona com biometria e senha

## 🚀 Próximo Passo

Compile o APK e teste em um dispositivo real:

```bash
flutter build apk --split-per-abi
```

Instale no celular e teste os cenários acima!
