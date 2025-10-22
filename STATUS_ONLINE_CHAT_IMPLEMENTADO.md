# Status Online no Chat - Implementado

## Resumo
Adicionado indicador de status online/último login no AppBar do RomanticMatchChatView.

## ✅ O que foi implementado

### Visual
- **Bolinha de status** (8x8px) ao lado do texto
  - Verde = Online
  - Cinza = Offline
- **Texto de status** abaixo do nome do usuário
  - "Online" quando ativo
  - "Online há X minutos/horas/dias" quando offline

### Código Implementado

```dart
Row(
  children: [
    Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getOnlineStatusColor(),
      ),
    ),
    const SizedBox(width: 6),
    Text(
      _getLastSeenText(),
      style: GoogleFonts.poppins(
        fontSize: 11,
        color: Colors.grey[600],
        fontWeight: FontWeight.w400,
      ),
    ),
  ],
),
```

## 🔧 Como Integrar com Dados Reais do Firestore

### 1. Adicionar Campo no Firestore

Adicione um campo `lastSeen` na collection `usuarios`:

```javascript
{
  userId: "abc123",
  nome: "João",
  lastSeen: Timestamp, // Atualizar sempre que o usuário usar o app
  // ... outros campos
}
```

### 2. Atualizar lastSeen Automaticamente

No seu app, atualize o `lastSeen` quando:
- Usuário abre o app
- Usuário envia uma mensagem
- Usuário navega entre telas (opcional)

```dart
// Exemplo de atualização
await FirebaseFirestore.instance
    .collection('usuarios')
    .doc(currentUserId)
    .update({
  'lastSeen': FieldValue.serverTimestamp(),
});
```

### 3. Carregar lastSeen no Chat

Adicione uma variável de estado:

```dart
DateTime? _otherUserLastSeen;

@override
void initState() {
  super.initState();
  _initializeAnimations();
  _loadUserPhoto();
  _loadUserLastSeen(); // Adicionar esta linha
  _checkForMessages();
  _markMessagesAsRead();
}

Future<void> _loadUserLastSeen() async {
  try {
    final userDoc = await _firestore
        .collection('usuarios')
        .doc(widget.otherUserId)
        .get();

    if (userDoc.exists) {
      final userData = userDoc.data();
      final lastSeenTimestamp = userData?['lastSeen'] as Timestamp?;
      
      setState(() {
        _otherUserLastSeen = lastSeenTimestamp?.toDate();
      });
    }
  } catch (e) {
    print('Erro ao carregar lastSeen: $e');
  }
}
```

### 4. Implementar Lógica de Status

Substitua os métodos placeholder:

```dart
Color _getOnlineStatusColor() {
  if (_otherUserLastSeen == null) return Colors.grey;
  
  final now = DateTime.now();
  final difference = now.difference(_otherUserLastSeen!);
  
  // Online se visto nos últimos 5 minutos
  if (difference.inMinutes < 5) {
    return Colors.green;
  }
  
  return Colors.grey;
}

String _getLastSeenText() {
  if (_otherUserLastSeen == null) return 'Offline';
  
  final now = DateTime.now();
  final difference = now.difference(_otherUserLastSeen!);
  
  // Online (menos de 5 minutos)
  if (difference.inMinutes < 5) {
    return 'Online';
  }
  
  // Minutos (5-59 minutos)
  if (difference.inMinutes < 60) {
    return 'Online há ${difference.inMinutes} minutos';
  }
  
  // Horas (1-23 horas)
  if (difference.inHours < 24) {
    final hours = difference.inHours;
    return 'Online há $hours ${hours == 1 ? "hora" : "horas"}';
  }
  
  // Dias
  final days = difference.inDays;
  return 'Online há $days ${days == 1 ? "dia" : "dias"}';
}
```

### 5. Atualizar em Tempo Real (Opcional)

Para atualizar o status em tempo real, use um StreamBuilder:

```dart
StreamBuilder<DocumentSnapshot>(
  stream: _firestore
      .collection('usuarios')
      .doc(widget.otherUserId)
      .snapshots(),
  builder: (context, snapshot) {
    if (snapshot.hasData && snapshot.data!.exists) {
      final userData = snapshot.data!.data() as Map<String, dynamic>;
      final lastSeenTimestamp = userData['lastSeen'] as Timestamp?;
      _otherUserLastSeen = lastSeenTimestamp?.toDate();
    }
    
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getOnlineStatusColor(),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          _getLastSeenText(),
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  },
)
```

## 🎨 Resultado Visual

### Antes
```
[Foto] João
       Match Mútuo 💕
```

### Depois
```
[Foto] João
       ● Online
```

ou

```
[Foto] João
       ● Online há 23 minutos
```

## 📝 Notas Importantes

1. **Performance**: Atualizar `lastSeen` a cada ação pode gerar muitas escritas no Firestore. Considere:
   - Atualizar apenas a cada 1-2 minutos
   - Usar Cloud Functions para atualizar automaticamente

2. **Privacidade**: Considere adicionar uma opção para o usuário ocultar seu status online

3. **Cores do Status**:
   - Verde (`Colors.green`): Online (< 5 minutos)
   - Cinza (`Colors.grey`): Offline (> 5 minutos)

4. **Placeholder Atual**: Por enquanto, sempre mostra "Online" com bolinha verde. Implemente a integração com Firestore para funcionalidade real.

---

**Data**: 2025-01-XX
**Status**: ✅ Visual implementado, aguardando integração com Firestore
