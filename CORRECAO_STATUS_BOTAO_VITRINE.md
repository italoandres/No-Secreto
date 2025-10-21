# Correção: Status Dinâmico do Botão na Vitrine

## Problema Identificado

Quando o usuário pesquisava por @ (username) e acessava um perfil:
- ❌ O botão sempre aparecia como "Tenho Interesse"
- ❌ Mesmo se já tivesse dado match, o botão não mudava para "Conversar"
- ❌ Não verificava o status real do relacionamento entre os usuários

## Causa Raiz

A busca por username navegava para `EnhancedVitrineDisplayView` sem passar o parâmetro `interestStatus`:

```dart
Get.to(
  () => const EnhancedVitrineDisplayView(),
  arguments: {
    'userId': profile['userId'],
    'isOwnProfile': false,
    'fromCelebration': false,
    // ❌ Faltava: 'interestStatus': ???
  },
);
```

## Solução Implementada

### 1. Verificação Dinâmica do Status

Adicionei uma nova função `_checkInterestStatus()` que verifica dinamicamente o relacionamento entre os usuários:

```dart
Future<void> _checkInterestStatus() async {
  final currentUserId = _getCurrentUserId();
  
  // 1. Verificar se existe chat (match confirmado)
  final chatId = 'match_${sortedIds[0]}_${sortedIds[1]}';
  final chatDoc = await FirebaseFirestore.instance
      .collection('match_chats')
      .doc(chatId)
      .get();
  
  if (chatDoc.exists) {
    setState(() {
      interestStatus = 'accepted'; // Mostra botão "Conversar"
    });
    return;
  }
  
  // 2. Verificar se existe interesse pendente do outro usuário
  final notifications = await FirebaseFirestore.instance
      .collection('interest_notifications')
      .where('fromUserId', isEqualTo: userId)
      .where('toUserId', isEqualTo: currentUserId)
      .where('status', whereIn: ['pending', 'viewed', 'new'])
      .limit(1)
      .get();
  
  if (notifications.docs.isNotEmpty) {
    setState(() {
      interestStatus = 'pending'; // Mostra botão "Também Tenho"
    });
    return;
  }
  
  // 3. Verificar se o usuário atual já enviou interesse
  final sentInterest = await FirebaseFirestore.instance
      .collection('interest_notifications')
      .where('fromUserId', isEqualTo: currentUserId)
      .where('toUserId', isEqualTo: userId)
      .where('status', whereIn: ['pending', 'viewed', 'new'])
      .limit(1)
      .get();
  
  if (sentInterest.docs.isNotEmpty) {
    setState(() {
      interestStatus = 'sent'; // Mostra botão "Interesse Enviado"
    });
    return;
  }
  
  // 4. Nenhum interesse encontrado
  setState(() {
    interestStatus = null; // Mostra botão "Tenho Interesse"
  });
}
```

### 2. Chamada Automática da Verificação

A verificação é chamada automaticamente após carregar os dados da vitrine, **apenas se** o `interestStatus` não foi fornecido nos argumentos:

```dart
// Verificar se tem certificação aprovada
await _checkCertificationStatus();

// Se interestStatus não foi fornecido, verificar dinamicamente
if (interestStatus == null && !isOwnProfile) {
  await _checkInterestStatus();
}
```

## Lógica de Verificação

A função verifica na seguinte ordem:

### 1. **Chat Existe?** → `interestStatus = 'accepted'`
- Verifica se existe documento em `match_chats`
- Se existe = match confirmado
- **Botão:** "Conversar" (verde)

### 2. **Interesse Pendente Recebido?** → `interestStatus = 'pending'`
- Verifica se o outro usuário enviou interesse
- Status: `pending`, `viewed` ou `new`
- **Botão:** "Também Tenho" (rosa)

### 3. **Interesse Já Enviado?** → `interestStatus = 'sent'`
- Verifica se o usuário atual já enviou interesse
- Status: `pending`, `viewed` ou `new`
- **Botão:** "Interesse Enviado" (cinza, desabilitado)

### 4. **Nenhum Interesse?** → `interestStatus = null`
- Nenhuma notificação ou chat encontrado
- **Botão:** "Tenho Interesse" (rosa)

## Fluxos de Uso

### Fluxo 1: Busca por @ com Match Existente

1. Usuário pesquisa por `@italo19`
2. Clica em "Ver Perfil Completo"
3. `EnhancedVitrineDisplayView` carrega
4. `_checkInterestStatus()` é chamada
5. Encontra chat existente
6. ✅ **Botão aparece como "Conversar"**

### Fluxo 2: Busca por @ com Interesse Pendente

1. Usuário pesquisa por `@itala2`
2. `@itala2` já enviou interesse para o usuário
3. Clica em "Ver Perfil Completo"
4. `_checkInterestStatus()` é chamada
5. Encontra notificação pendente
6. ✅ **Botão aparece como "Também Tenho"**

### Fluxo 3: Busca por @ com Interesse Enviado

1. Usuário pesquisa por `@italo3`
2. Usuário já enviou interesse para `@italo3`
3. Clica em "Ver Perfil Completo"
4. `_checkInterestStatus()` é chamada
5. Encontra interesse enviado
6. ✅ **Botão aparece como "Interesse Enviado" (desabilitado)**

### Fluxo 4: Busca por @ sem Interesse

1. Usuário pesquisa por `@novousuario`
2. Nenhum interesse ou match existe
3. Clica em "Ver Perfil Completo"
4. `_checkInterestStatus()` é chamada
5. Não encontra nada
6. ✅ **Botão aparece como "Tenho Interesse"**

## Compatibilidade

A solução é **retrocompatível** com os fluxos existentes:

| Origem | interestStatus Fornecido? | Comportamento |
|--------|---------------------------|---------------|
| Interest Dashboard | ✅ Sim (`pending`) | Usa o fornecido, não verifica |
| Notificação | ✅ Sim (`pending`) | Usa o fornecido, não verifica |
| Busca por @ | ❌ Não | Verifica dinamicamente |
| Explore Profiles | ❌ Não | Verifica dinamicamente |
| Link Direto | ❌ Não | Verifica dinamicamente |

## Logs de Debug

```
2025-10-21T03:00:00.000 [INFO] [VITRINE_DISPLAY] Checking interest status dynamically
📊 Data: {currentUserId: qZrIbFibaQgyZSYCXTJHzxE1sVv1, targetUserId: By4mfu3XrbPA0vJOpfN2hf2a2ic2}

2025-10-21T03:00:00.500 [INFO] [VITRINE_DISPLAY] Match found - chat exists
📊 Data: {chatId: match_By4mfu3XrbPA0vJOpfN2hf2a2ic2_qZrIbFibaQgyZSYCXTJHzxE1sVv1, interestStatus: accepted}
```

## Como Testar

### Teste 1: Match Existente
1. Faça match com um usuário (ex: italo19)
2. Vá para busca por @
3. Digite `@italo19`
4. Clique em "Ver Perfil Completo"
5. ✅ **Verificar:** Botão deve ser "Conversar" (verde)

### Teste 2: Interesse Pendente
1. Faça login com usuário A
2. Envie interesse para usuário B
3. Faça login com usuário B
4. Busque por @ do usuário A
5. Clique em "Ver Perfil Completo"
6. ✅ **Verificar:** Botão deve ser "Também Tenho" (rosa)

### Teste 3: Interesse Enviado
1. Envie interesse para um usuário
2. Busque por @ desse usuário
3. Clique em "Ver Perfil Completo"
4. ✅ **Verificar:** Botão deve ser "Interesse Enviado" (cinza, desabilitado)

### Teste 4: Sem Interesse
1. Busque por @ de um usuário novo
2. Clique em "Ver Perfil Completo"
3. ✅ **Verificar:** Botão deve ser "Tenho Interesse" (rosa)

## Arquivos Modificados

- `lib/views/enhanced_vitrine_display_view.dart`
  - Adicionada função `_checkInterestStatus()`
  - Chamada automática após carregar dados da vitrine

## Status

✅ **Implementação Completa**
- Verificação dinâmica do status do interesse
- Compatível com todos os fluxos existentes
- Botão sempre mostra o estado correto
- Logs detalhados para debug
