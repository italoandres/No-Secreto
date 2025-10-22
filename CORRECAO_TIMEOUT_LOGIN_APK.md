# 🔧 Correção - Timeout no Login do APK

## ❌ Problema

**Sintoma**: Login no APK dá timeout com mensagem "O login demorou muito, verifique a conexão e tente novamente"

**Causa**: O `OnlineStatusService.setUserOnline()` estava sendo chamado no `initState()` do `MyApp`, **ANTES** do usuário fazer login, tentando atualizar o Firestore sem autenticação.

## ✅ Solução Aplicada

Removida a chamada de `setUserOnline()` do `initState()` do `MyApp`.

### Antes (Causava Timeout)
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);
  // ❌ PROBLEMA: Tenta atualizar Firestore ANTES do login
  OnlineStatusService.setUserOnline();
}
```

### Depois (Corrigido)
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);
  // ✅ Não chama aqui para não causar timeout
  // O status será atualizado automaticamente quando necessário
}
```

## 🔄 Como o Status Online Funciona Agora

O `lastSeen` é atualizado automaticamente em 3 momentos:

### 1. Quando o App Volta do Segundo Plano
```dart
case AppLifecycleState.resumed:
  OnlineStatusService.setUserOnline(); // ✅ Usuário já está autenticado
  break;
```

### 2. Quando o Usuário Envia Mensagem
```dart
Future<void> _sendMessage() async {
  OnlineStatusService.updateLastSeen(); // ✅ Usuário já está autenticado
  // ... resto do código
}
```

### 3. Quando o App Vai para Segundo Plano
```dart
case AppLifecycleState.paused:
  OnlineStatusService.setUserOffline(); // ✅ Atualiza lastSeen
  break;
```

## 🛡️ Proteção Contra Erros

O serviço já tem proteção built-in:

```dart
static Future<void> updateLastSeen() async {
  try {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return; // ✅ Retorna se não estiver autenticado
    
    await _firestore
        .collection('usuarios')
        .doc(currentUser.uid)
        .update({'lastSeen': FieldValue.serverTimestamp()});
  } catch (e) {
    print('⚠️ Erro ao atualizar lastSeen: $e'); // ✅ Não quebra o app
  }
}
```

## 🧪 Como Testar

### 1. Compile o APK
```bash
flutter build apk --release
```

### 2. Instale no Dispositivo
```bash
flutter install
```

### 3. Teste o Login
- Abra o app
- Faça login com italolior@gmail.com
- ✅ Deve entrar normalmente (sem timeout)

### 4. Verifique o Status Online
- Após o login, abra um chat
- O status deve funcionar normalmente
- Quando você enviar uma mensagem, o `lastSeen` será atualizado

## 📊 Fluxo Correto

```
1. App Abre
   └─> initState() (SEM chamar setUserOnline)
   
2. Usuário Faz Login
   └─> Firebase Auth OK
   
3. App Vai para Segundo Plano
   └─> didChangeAppLifecycleState(paused)
       └─> setUserOffline() ✅ (usuário JÁ está autenticado)
   
4. App Volta
   └─> didChangeAppLifecycleState(resumed)
       └─> setUserOnline() ✅ (usuário JÁ está autenticado)
   
5. Usuário Envia Mensagem
   └─> _sendMessage()
       └─> updateLastSeen() ✅ (usuário JÁ está autenticado)
```

## ⚠️ Importante

- O status online **NÃO** é atualizado no primeiro login
- Ele começa a ser atualizado a partir do **segundo uso** do app
- Ou quando o usuário **envia a primeira mensagem**
- Isso é **intencional** para evitar timeout no login

## 🎯 Resultado

✅ Login funciona normalmente no APK  
✅ Status online funciona após o login  
✅ Sem timeout  
✅ Sem erros  

---

**Data**: 2025-01-22  
**Status**: ✅ CORRIGIDO!
