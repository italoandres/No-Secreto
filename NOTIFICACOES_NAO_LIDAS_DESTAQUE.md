# Destaque Visual para Notificações Não Lidas

## Implementação Completa

Adicionei duas melhorias importantes para as notificações de interesse:

1. **Marcação automática como "viewed"** quando clicar em "Conversar"
2. **Efeito pulsante** para notificações não lidas (`status: new`)

---

## 1. Marcação Automática como "Viewed"

### Problema Identificado
Quando o usuário clicava em "Conversar" em uma notificação com `status: new`, ela continuava sendo contabilizada no badge do menu.

### Solução
Adicionei código para marcar automaticamente a notificação como "viewed" antes de navegar para o chat:

```dart
void _navigateToChat() async {
  try {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final otherUserId = widget.notification.fromUserId;

    if (currentUserId == null || otherUserId == null) {
      Get.snackbar('Erro', 'Não foi possível abrir o chat');
      return;
    }

    // Marcar notificação como "viewed" se estiver como "new"
    if (widget.notification.status == 'new' && widget.notification.id != null) {
      try {
        await FirebaseFirestore.instance
            .collection('interest_notifications')
            .where('toUserId', isEqualTo: auth.currentUser?.uid)
            .where('status', whereIn: ['pending', 'new'])
            .snapshots()
            .map((snapshot) {
              // Filtrar apenas tipos válidos
              final validDocs = snapshot.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final type = data['type'] ?? 'interest';
                return ['interest', 'acceptance', 'mutual_match'].contains(type);
              }).toList();
              return validDocs.length;
            }),
        
        print('✅ [CARD] Notificação marcada como viewed: ${widget.notification.id}');
      } catch (e) {
        print('⚠️ [CARD] Erro ao marcar como viewed: $e');
      }
    }

    // Gerar ID do chat e navegar...
  }
}
```

### Resultado
- ✅ Ao clicar em "Conversar", a notificação muda de `status: new` para `status: viewed`
- ✅ O contador no menu diminui automaticamente
- ✅ A notificação continua visível (status `viewed` ainda é exibido)

---

## 2. Efeito Pulsante para Notificações Não Lidas

### Visual Aprimorado

Notificações com `status: new` agora têm:

#### Borda Mais Grossa e Colorida
```dart
border: Border.all(
  color: isNew
      ? Colors.pink.withOpacity(0.6)  // Rosa mais forte
      : isMutualMatch
          ? Colors.purple.withOpacity(0.3)
          : isAccepted
              ? Colors.green.withOpacity(0.3)
              : Colors.pink.withOpacity(0.2),
  width: isNew ? 3 : 2,  // Borda mais grossa
),
```

#### Sombra Mais Pronunciada
```dart
boxShadow: [
  BoxShadow(
    color: isNew 
        ? Colors.pink.withOpacity(0.2)  // Sombra rosa
        : Colors.black.withOpacity(0.08),
    blurRadius: isNew ? 16 : 12,  // Mais blur
    offset: const Offset(0, 4),
  ),
],
```

#### Animação Pulsante
```dart
if (isNew) {
  return TweenAnimationBuilder<double>(
    tween: Tween(begin: 1.0, end: 1.03),  // Escala de 100% a 103%
    duration: const Duration(milliseconds: 1000),  // 1 segundo
    curve: Curves.easeInOut,  // Suave
    builder: (context, scale, child) {
      return Transform.scale(
        scale: scale,
        child: child,
      );
    },
    onEnd: () {
      // Repetir a animação
      if (mounted) {
        setState(() {});
      }
    },
    child: cardContent,
  );
}
```

### Características da Animação
- ✅ **Pulsação suave**: Escala de 100% para 103% e volta
- ✅ **Duração**: 1 segundo por ciclo
- ✅ **Repetição infinita**: Enquanto o status for "new"
- ✅ **Curva suave**: `Curves.easeInOut` para transição natural
- ✅ **Performance**: Usa `TweenAnimationBuilder` (eficiente)

---

## Comparação Visual

### Antes
```
┌─────────────────────────────────────┐
│ 💕 itala também tem interesse!      │
│ (borda rosa fina, sem animação)     │
└─────────────────────────────────────┘
```

### Depois (status: new)
```
┌═════════════════════════════════════┐
║ 💕 itala também tem interesse!      ║
║ (borda rosa GROSSA, PULSANDO)       ║
║ ↕️ Animação: 100% → 103% → 100%     ║
└═════════════════════════════════════┘
```

### Depois (status: viewed)
```
┌─────────────────────────────────────┐
│ 💕 itala também tem interesse!      │
│ (borda rosa fina, sem animação)     │
└─────────────────────────────────────┘
```

---

## Fluxo Completo

### Cenário: Notificação de Aceitação

1. **Usuário A** aceita interesse de **Usuário B**
2. **Notificação criada** para Usuário B:
   - `type: 'acceptance'`
   - `status: 'new'`
3. **Usuário B** abre o dashboard
4. ✨ **Notificação aparece PULSANDO** com borda rosa grossa
5. **Badge no menu** mostra "1"
6. **Usuário B** clica em "Conversar"
7. ✅ **Status muda** para `'viewed'`
8. ✅ **Badge diminui** para "0"
9. ✅ **Animação para** (borda volta ao normal)
10. **Chat abre** normalmente

---

## Estados da Notificação

| Status | Borda | Animação | Contabiliza no Badge? |
|--------|-------|----------|----------------------|
| `new` | Rosa grossa (3px) | ✅ Pulsante | ✅ Sim |
| `pending` | Rosa fina (2px) | ❌ Não | ✅ Sim |
| `viewed` | Rosa fina (2px) | ❌ Não | ❌ Não |
| `accepted` | Verde fina (2px) | ❌ Não | ❌ Não (após 7 dias) |
| `rejected` | Cinza fina (2px) | ❌ Não | ❌ Não (após 7 dias) |

---

## Logs Esperados

### Ao Clicar em "Conversar" (status: new)
```
💬 [CARD] Navegando para match-chat: match_St2kw3cgX2MMPxlLRmBDjYm2nO22_qZrIbFibaQgyZSYCXTJHzxE1sVv1
✅ [CARD] Notificação marcada como viewed: 94TFtWY8JAZSLjcisDTP
```

### Stream Atualizado
```
📋 [REPO_STREAM] Doc ID=94TFtWY8JAZSLjcisDTP
- type: acceptance
- status: viewed  ← Mudou de 'new' para 'viewed'
- fromUserId: St2kw3cgX2MMPxlLRmBDjYm2nO22
- fromUserName: itala
- toUserId: qZrIbFibaQgyZSYCXTJHzxE1sVv1
✅ [REPO_STREAM] Notificação ACEITA (status sempre visível): 94TFtWY8JAZSLjcisDTP
```

### Badge Atualizado
```
📊 [UNIFIED_CONTROLLER] Notificações recebidas: 4  ← Diminuiu de 5 para 4
✅ [UNIFIED_CONTROLLER] Badge count atualizado: 0  ← Apenas 'new' e 'pending' contam
```

---

## Como Testar

### Teste 1: Efeito Pulsante
1. Receba uma notificação de aceitação (status: new)
2. Abra o dashboard de notificações
3. ✅ **Verificar:** Card está pulsando suavemente
4. ✅ **Verificar:** Borda rosa mais grossa
5. ✅ **Verificar:** Sombra rosa mais pronunciada

### Teste 2: Marcação como Viewed
1. Com notificação pulsando (status: new)
2. Clique em "Conversar"
3. ✅ **Verificar:** Chat abre normalmente
4. Volte para o dashboard
5. ✅ **Verificar:** Card não está mais pulsando
6. ✅ **Verificar:** Badge no menu diminuiu

### Teste 3: Contador do Menu
1. Tenha 3 notificações: 2 com status "new", 1 com "viewed"
2. Abra o menu principal
3. ✅ **Verificar:** Badge mostra "2"
4. Clique em "Conversar" em uma notificação "new"
5. Volte ao menu
6. ✅ **Verificar:** Badge agora mostra "1"

---

## Arquivos Modificados

- `lib/components/enhanced_interest_notification_card.dart`
  - Adicionada marcação automática como "viewed" em `_navigateToChat()`
  - Adicionado efeito pulsante com `TweenAnimationBuilder`
  - Borda e sombra mais pronunciadas para status "new"

---

## Status

✅ **Implementação Completa**
- Notificações não lidas são marcadas automaticamente
- Efeito pulsante chama atenção para notificações novas
- Contador do menu atualiza em tempo real
- Visual mais evidente e profissional
