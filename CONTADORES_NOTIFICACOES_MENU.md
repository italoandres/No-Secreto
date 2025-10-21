# Contadores de Notificações no Menu de Vitrine

## Implementação Completa

Refinei os contadores de notificações no `VitrinePropositoMenuView` para mostrar números precisos e atualizados em tempo real.

## Contadores Implementados

### 1. **Seus Sinais** 🔍
**Conta:** Recomendações semanais não visualizadas

```dart
StreamBuilder<QuerySnapshot>(
  stream: firestore
      .collection('weekly_recommendations')
      .where('userId', isEqualTo: auth.currentUser?.uid)
      .where('viewed', isEqualTo: false)
      .snapshots(),
  builder: (context, snapshot) {
    return snapshot.data?.docs.length ?? 0;
  },
)
```

**Lógica:**
- Busca em `weekly_recommendations`
- Filtra por `userId` do usuário atual
- Conta apenas `viewed: false`
- Atualiza em tempo real

**Quando diminui:**
- Usuário visualiza uma recomendação
- Campo `viewed` muda para `true`

---

### 2. **Notificações de Interesse** 💕
**Conta:** Interesses pendentes e novos (pending/new)

```dart
StreamBuilder<QuerySnapshot>(
  stream: firestore
      .collection('interest_notifications')
      .where('toUserId', isEqualTo: auth.currentUser?.uid)
      .where('status', whereIn: ['pending', 'new'])
      .snapshots(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return 0;
    
    // Filtrar apenas tipos válidos
    final validDocs = snapshot.data!.docs.where((doc) {
      final type = doc.data()['type'] ?? 'interest';
      return ['interest', 'acceptance', 'mutual_match'].contains(type);
    }).toList();
    
    return validDocs.length;
  },
)
```

**Lógica:**
- Busca em `interest_notifications`
- Filtra por `toUserId` do usuário atual
- Status: `pending` ou `new`
- Tipos válidos: `interest`, `acceptance`, `mutual_match`
- Atualiza em tempo real

**Quando diminui:**
- Usuário responde ao interesse (aceita ou rejeita)
- Status muda para `accepted` ou `rejected`
- Notificação sai da contagem

---

### 3. **Matches Aceitos** ❤️
**Conta:** Mensagens não lidas em chats de match

```dart
StreamBuilder<QuerySnapshot>(
  stream: firestore
      .collection('match_chats')
      .where('user1Id', isEqualTo: auth.currentUser?.uid)
      .snapshots(),
  builder: (context, snapshot1) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('match_chats')
          .where('user2Id', isEqualTo: auth.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot2) {
        if (!snapshot1.hasData && !snapshot2.hasData) return 0;
        
        final userId = auth.currentUser?.uid ?? '';
        int totalUnread = 0;
        
        // Contar não lidas do user1
        if (snapshot1.hasData) {
          for (var doc in snapshot1.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final unreadCount = data['unreadCount'] as Map<String, dynamic>?;
            if (unreadCount != null && unreadCount.containsKey(userId)) {
              totalUnread += (unreadCount[userId] as int?) ?? 0;
            }
          }
        }
        
        // Contar não lidas do user2
        if (snapshot2.hasData) {
          for (var doc in snapshot2.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final unreadCount = data['unreadCount'] as Map<String, dynamic>?;
            if (unreadCount != null && unreadCount.containsKey(userId)) {
              totalUnread += (unreadCount[userId] as int?) ?? 0;
            }
          }
        }
        
        return totalUnread;
      },
    );
  },
)
```

**Lógica:**
- Busca em `match_chats` onde usuário é `user1Id` OU `user2Id`
- Soma o campo `unreadCount[userId]` de cada chat
- Atualiza em tempo real

**Quando diminui:**
- Usuário abre o chat e lê as mensagens
- Campo `unreadCount[userId]` é zerado

---

## Visual do Badge

### Design Refinado

```dart
Container(
  padding: const EdgeInsets.symmetric(
    horizontal: 6,
    vertical: 2,
  ),
  decoration: BoxDecoration(
    color: Colors.red,
    borderRadius: BorderRadius.circular(10),
    border: Border.all(
      color: Colors.white,
      width: 2,
    ),
  ),
  constraints: const BoxConstraints(
    minWidth: 20,
    minHeight: 20,
  ),
  child: Text(
    count > 99 ? '99+' : '$count',
    style: const TextStyle(
      color: Colors.white,
      fontSize: 11,
      fontWeight: FontWeight.bold,
    ),
    textAlign: TextAlign.center,
  ),
)
```

**Características:**
- ✅ Fundo vermelho vibrante
- ✅ Borda branca de 2px
- ✅ Bordas arredondadas
- ✅ Texto branco e bold
- ✅ Mostra "99+" se passar de 99
- ✅ Posicionado no canto superior direito do ícone
- ✅ Só aparece se count > 0

---

## Cores dos Cards

Reorganizei as cores para melhor hierarquia visual:

| Card | Cor | Motivo |
|------|-----|--------|
| **Seus Sinais** | Azul (`#39b9ff`) | Exploração, descoberta |
| **Notificações de Interesse** | Rosa (`#fc6aeb`) | Amor, interesse |
| **Matches Aceitos** | Verde (`#4CAF50`) | Sucesso, conexão estabelecida |
| **Encontre por @** | Azul Royal (`#4169E1`) | Busca, pesquisa |
| **Configure Vitrine** | Rosa (`#fc6aeb`) | Personalização |

---

## Fluxo de Atualização

### Seus Sinais
1. Sistema cria recomendações semanais com `viewed: false`
2. **Badge aparece** com número de recomendações
3. Usuário abre "Seus Sinais"
4. Visualiza perfis recomendados
5. Campo `viewed` muda para `true`
6. **Badge diminui** automaticamente

### Notificações de Interesse
1. Alguém envia interesse → `status: 'pending'`
2. **Badge aparece** com número de interesses
3. Usuário abre "Notificações de Interesse"
4. Responde ao interesse (aceita/rejeita)
5. Status muda para `accepted` ou `rejected`
6. **Badge diminui** automaticamente

### Matches Aceitos
1. Match é criado → chat criado com `unreadCount: {userId: 0}`
2. Outra pessoa envia mensagem → `unreadCount: {userId: 1}`
3. **Badge aparece** com número de mensagens não lidas
4. Usuário abre o chat
5. Sistema zera `unreadCount: {userId: 0}`
6. **Badge diminui** automaticamente

---

## Exemplo Visual

```
┌─────────────────────────────────────────┐
│  🔍  Seus Sinais                    [3] │
│      Descubra pessoas com propósito     │
├─────────────────────────────────────────┤
│  🔔  Notificações de Interesse      [5] │
│      Veja quem demonstrou interesse     │
├─────────────────────────────────────────┤
│  ❤️  Matches Aceitos                [2] │
│      Converse com seus matches mútuos   │
└─────────────────────────────────────────┘
```

---

## Como Testar

### Teste 1: Seus Sinais
1. Crie recomendações semanais com `viewed: false`
2. Abra o menu
3. ✅ **Verificar:** Badge mostra número correto
4. Abra "Seus Sinais" e visualize perfis
5. ✅ **Verificar:** Badge diminui conforme visualiza

### Teste 2: Notificações de Interesse
1. Receba interesses de outros usuários
2. Abra o menu
3. ✅ **Verificar:** Badge mostra número de interesses pendentes
4. Responda aos interesses
5. ✅ **Verificar:** Badge diminui conforme responde

### Teste 3: Matches Aceitos
1. Faça match com alguém
2. Peça para a pessoa enviar mensagem
3. Abra o menu
4. ✅ **Verificar:** Badge mostra número de mensagens não lidas
5. Abra o chat e leia as mensagens
6. ✅ **Verificar:** Badge zera

---

## Arquivos Modificados

- `lib/views/vitrine_proposito_menu_view.dart`
  - Adicionados 3 contadores com StreamBuilder
  - Refinado visual do badge
  - Reorganizadas cores dos cards

---

## Status

✅ **Implementação Completa**
- Contadores precisos e em tempo real
- Visual refinado com badges vermelhos
- Atualização automática conforme ações do usuário
- Cores organizadas por hierarquia
- Posicionamento perfeito dos badges
