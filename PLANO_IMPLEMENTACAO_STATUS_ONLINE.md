# 📝 PLANO DE IMPLEMENTAÇÃO - Status Online

**Data:** 22/10/2025  
**Status:** 🟡 AGUARDANDO APROVAÇÃO

---

## 🎯 OBJETIVO

Adicionar sistema de status online (Online/Offline) SEM remover ou modificar código existente.

---

## 📋 MUDANÇAS NECESSÁRIAS

### 1. ADICIONAR CAMPOS NO MODEL (usuario_model.dart)

**Arquivo:** `lib/models/usuario_model.dart`

**O QUE ADICIONAR:**
```dart
// ✨ NOVOS CAMPOS (adicionar na classe UsuarioModel)
Timestamp? lastSeen;      // Última vez que usuário foi visto online
bool? isOnline;           // Se está online agora
```

**ONDE ADICIONAR:** Após a linha 14 (após `DateTime? lastSyncAt;`)

**CÓDIGO COMPLETO A ADICIONAR:**
```dart
class UsuarioModel {
  String? id;
  String? imgUrl;
  String? imgBgUrl;
  String? nome;
  String? email;
  bool? perfilIsComplete;
  Timestamp? dataCadastro;
  bool? isAdmin;
  bool? senhaIsSeted;
  UserSexo? sexo;
  String? username;
  List<String>? usernameHistory;
  Timestamp? usernameChangedAt;
  DateTime? lastSyncAt;
  
  // ✨ NOVOS CAMPOS ADICIONADOS
  Timestamp? lastSeen;      // Última vez online
  bool? isOnline;           // Status online atual

  UsuarioModel({
    this.id,
    this.imgUrl,
    this.imgBgUrl,
    this.nome,
    this.email,
    this.perfilIsComplete,
    this.dataCadastro,
    this.isAdmin,
    this.senhaIsSeted,
    this.sexo,
    this.username,
    this.usernameHistory,
    this.usernameChangedAt,
    this.lastSyncAt,
    // ✨ NOVOS PARÂMETROS
    this.lastSeen,
    this.isOnline,
  });
```

**TAMBÉM ADICIONAR NO fromJson (após linha 50):**
```dart
lastSeen: json['lastSeen'],
isOnline: json['isOnline'] ?? false,
```

**TAMBÉM ADICIONAR NO toJson (após linha 75):**
```dart
'lastSeen': lastSeen,
'isOnline': isOnline,
```

---

### 2. ADICIONAR TRACKING NO CHATVIEW (chat_view.dart)

**Arquivo:** `lib/views/chat_view.dart`

#### 2.1 Adicionar import do Timer
**ONDE:** Após linha 1 (após `import 'dart:io';`)
```dart
import 'dart:async'; // ✨ NOVO IMPORT
```

#### 2.2 Adicionar variável Timer na classe
**ONDE:** Após linha 69 (após `int totMsgs = 0;`)
```dart
Timer? _onlineTimer; // ✨ NOVO: Timer para tracking de status online
```

#### 2.3 Adicionar método de tracking
**ONDE:** Após o método `initPlatformState()` (após linha 85)
```dart
// ✨ NOVO: Método para iniciar tracking de status online
void _startOnlineTracking() {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;
  
  // Marcar como online imediatamente
  FirebaseFirestore.instance
      .collection('usuarios')
      .doc(userId)
      .update({
    'lastSeen': FieldValue.serverTimestamp(),
    'isOnline': true,
  }).catchError((e) {
    safePrint('⚠️ Erro ao atualizar status online: $e');
  });
  
  // Atualizar a cada 30 segundos
  _onlineTimer = Timer.periodic(const Duration(seconds: 30), (_) {
    if (mounted) {
      FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .update({
        'lastSeen': FieldValue.serverTimestamp(),
        'isOnline': true,
      }).catchError((e) {
        safePrint('⚠️ Erro ao atualizar status online: $e');
      });
    }
  });
}

// ✨ NOVO: Método para parar tracking
void _stopOnlineTracking() {
  _onlineTimer?.cancel();
  
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId != null) {
    FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .update({
      'lastSeen': FieldValue.serverTimestamp(),
      'isOnline': false,
    }).catchError((e) {
      safePrint('⚠️ Erro ao marcar como offline: $e');
    });
  }
}
```

#### 2.4 Chamar tracking no initState
**ONDE:** Dentro do método `initState()` (após linha 73)
```dart
@override
void initState() {
  super.initState();
  initPlatformState();
  _startOnlineTracking(); // ✨ NOVO: Iniciar tracking
}
```

#### 2.5 Adicionar dispose para limpar
**ONDE:** Após o método `build()` (criar novo método)
```dart
@override
void dispose() {
  _stopOnlineTracking(); // ✨ NOVO: Parar tracking ao sair
  super.dispose();
}
```

---

### 3. ADICIONAR INDICADOR VISUAL (simple_accepted_matches_view.dart)

**Arquivo:** `lib/views/simple_accepted_matches_view.dart`

#### 3.1 Adicionar método helper para calcular status
**ONDE:** Dentro da classe `_SimpleAcceptedMatchesViewState` (após linha 25)
```dart
// ✨ NOVO: Calcular se usuário está online
bool _isUserOnline(Timestamp? lastSeen, bool? isOnline) {
  if (isOnline == true) return true;
  
  if (lastSeen == null) return false;
  
  final now = DateTime.now();
  final lastSeenDate = lastSeen.toDate();
  final difference = now.difference(lastSeenDate);
  
  // Considera online se visto nos últimos 2 minutos
  return difference.inMinutes < 2;
}

// ✨ NOVO: Widget do indicador de status
Widget _buildOnlineIndicator(bool isOnline) {
  return Container(
    width: 12,
    height: 12,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: isOnline ? Colors.green : Colors.grey,
      border: Border.all(color: Colors.white, width: 2),
    ),
  );
}
```

#### 3.2 Adicionar indicador no card do match
**ONDE:** No método `itemBuilder` da ListView (onde constrói cada card)

**NOTA:** Preciso ver o código completo do itemBuilder para saber exatamente onde adicionar. Por enquanto, o indicador será:

```dart
// ✨ ADICIONAR no Stack da foto do perfil
Positioned(
  right: 4,
  bottom: 4,
  child: _buildOnlineIndicator(
    _isUserOnline(match.lastSeen, match.isOnline)
  ),
)
```

---

## 🔍 PONTOS DE ATENÇÃO

### ✅ O QUE ESTAMOS FAZENDO:
1. Adicionando campos novos no model
2. Adicionando Timer para tracking
3. Adicionando indicador visual
4. Usando `catchError` para não quebrar se der erro

### ❌ O QUE NÃO ESTAMOS FAZENDO:
1. Removendo código existente
2. Modificando lógica existente
3. Mudando estrutura de arquivos
4. Reescrevendo funções que funcionam

---

## 🧪 TESTES NECESSÁRIOS

### Teste 1: Tracking Funciona
- [ ] Abrir app
- [ ] Verificar no Firestore se `isOnline` = true
- [ ] Verificar se `lastSeen` está atualizando

### Teste 2: Indicador Aparece
- [ ] Abrir lista de matches
- [ ] Verificar se bolinha verde aparece
- [ ] Fechar app de um usuário
- [ ] Verificar se bolinha fica cinza

### Teste 3: Não Quebrou Nada
- [ ] Login ainda funciona?
- [ ] Chat ainda funciona?
- [ ] Matches ainda aparecem?
- [ ] Não há erros no console?

---

## ⚠️ RISCOS E MITIGAÇÕES

### Risco 1: Timer não é cancelado
**Mitigação:** Sempre cancelar no dispose()

### Risco 2: Erro ao atualizar Firestore
**Mitigação:** Usar catchError() em todos os updates

### Risco 3: Memory leak
**Mitigação:** Verificar que Timer é cancelado e usar `if (mounted)`

### Risco 4: Muitas escritas no Firestore
**Mitigação:** Atualizar apenas a cada 30 segundos (não em tempo real)

---

## 📊 ESTRUTURA FIRESTORE

### Collection: `usuarios`
```json
{
  "id": "user123",
  "nome": "João",
  "email": "joao@example.com",
  // ... campos existentes ...
  
  // ✨ NOVOS CAMPOS
  "lastSeen": Timestamp,  // Última vez online
  "isOnline": true        // Status atual
}
```

---

## 🚀 ORDEM DE IMPLEMENTAÇÃO

1. **Primeiro:** Adicionar campos no UsuarioModel
2. **Segundo:** Adicionar tracking no ChatView
3. **Terceiro:** Testar se tracking funciona
4. **Quarto:** Adicionar indicador visual
5. **Quinto:** Testar tudo junto

---

## ✅ APROVADO PELO USUÁRIO

**Decisões confirmadas:**
1. ✅ Intervalo: 30 segundos
2. ✅ Definição de online: Visto nos últimos 5 minutos (copiar do RomanticMatchChatView)
3. ✅ Cor: Verde (online) e cinza (offline)
4. ✅ **Onde mostrar: APENAS no chat de conversa (como no print "Online há 17 horas")**
5. ✅ **Estratégia: Copiar código do RomanticMatchChatView para o ChatView antigo**

---

## 🎯 ESTRATÉGIA FINAL

**COPIAR código do NOVO (RomanticMatchChatView) para o VELHO (ChatView)**

Já existe implementação completa em `lib/views/romantic_match_chat_view.dart`:
- Método `_getLastSeenText()` (linha ~360)
- Método `_getOnlineStatusColor()` (linha ~350)
- Stream de status do usuário

**Vamos ADICIONAR essa mesma lógica no ChatView antigo!**

---

**PRONTO PARA IMPLEMENTAR! 🚀**
