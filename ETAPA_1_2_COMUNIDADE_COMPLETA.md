# ✅ ETAPA 1 e 2 CONCLUÍDA: Modelo + Repositório

## 📦 Arquivos Criados/Modificados

### 1. ✅ Novo Modelo: `lib/models/community_comment_model.dart`

Modelo completo com:
- Todos os campos necessários (commentId, storyId, userId, userName, userAvatarUrl, text, etc.)
- `fromFirestore()` para ler do banco
- `toJson()` para escrever no banco
- `copyWith()` para atualizações imutáveis

### 2. ✅ Repositório Atualizado: `lib/repositories/story_interactions_repository.dart`

Adicionados 3 novos métodos de stream:

#### `getHotChatsStream(String storyId)`
- Busca comentários raiz com mais respostas
- Ordena por `replyCount` (descendente)
- Limita a Top 5
- **Tempo real** via `.snapshots()`

#### `getRecentChatsStream(String storyId)`
- Busca comentários raiz mais recentes
- Ordena por `createdAt` (descendente)
- Limita a 20 (para paginação futura)
- **Tempo real** via `.snapshots()`

#### `getChatRepliesStream(String parentCommentId)`
- Busca respostas de um comentário específico
- Ordena por `createdAt` (ascendente - mais antiga primeiro)
- Sem limite (todas as respostas)
- **Tempo real** via `.snapshots()`

---

## 📋 RESPOSTA À PERGUNTA CRÍTICA

**Pergunta**: De qual coleção copiar `userName` e `userAvatarUrl`?

**Resposta**: 
```
Coleção: spiritual_profiles
```

Encontrei no arquivo `lib/repositories/spiritual_profile_repository.dart`:
```dart
static const String _collection = 'spiritual_profiles';
```

Esta é a coleção da "vitrine de propósito" que contém:
- `userId` (referência ao usuário)
- Nome completo
- Foto de perfil
- Dados espirituais

---

## 🎯 Próximos Passos (AGUARDANDO SUA CONFIRMAÇÃO)

Antes de prosseguir para a ETAPA 3 (UI), preciso confirmar:

1. ✅ A coleção `spiritual_profiles` está correta?
2. ✅ Os campos são `nome` e `imgUrl` ou têm outros nomes?
3. ✅ Devo criar um método helper para buscar esses dados ao postar comentário?

**Aguardando sua confirmação para prosseguir! 🙏**

---

## 📊 Estrutura de Dados no Firestore

### Coleção: `community_comments`

```
community_comments/
  ├─ {commentId1}
  │   ├─ storyId: "story123"
  │   ├─ userId: "user456"
  │   ├─ userName: "João Silva"
  │   ├─ userAvatarUrl: "https://..."
  │   ├─ text: "Senti que era ela..."
  │   ├─ createdAt: Timestamp
  │   ├─ parentId: null (comentário raiz)
  │   ├─ replyCount: 42
  │   ├─ reactionCount: 210
  │   ├─ lastReplyAt: Timestamp
  │   └─ isCurated: false
  │
  ├─ {commentId2}
  │   ├─ storyId: "story123"
  │   ├─ userId: "user789"
  │   ├─ userName: "Maria Santos"
  │   ├─ text: "Concordo totalmente!"
  │   ├─ parentId: "commentId1" (resposta ao comentário 1)
  │   ├─ replyCount: 0
  │   └─ ...
```

---

## 🔥 Vantagens da Nova Arquitetura

1. **Zero N+1 Queries** - Cada stream é independente e eficiente
2. **Tempo Real Nativo** - `.snapshots()` garante atualizações instantâneas
3. **Escalável** - Queries otimizadas com índices corretos
4. **Separação Clara** - Chats em Alta vs Recentes vs Respostas
5. **Performance** - Limites e ordenação no servidor (Firestore)

---

## ⚠️ Índices Necessários no Firestore

Após implementar, o Firestore vai pedir estes índices compostos:

1. `community_comments`: `storyId` (ASC) + `parentId` (ASC) + `replyCount` (DESC)
2. `community_comments`: `storyId` (ASC) + `parentId` (ASC) + `createdAt` (DESC)
3. `community_comments`: `parentId` (ASC) + `createdAt` (ASC)

O Firebase vai gerar os links automaticamente no console quando você testar! 🚀

---

**PARADO AQUI - Aguardando confirmação para ETAPA 3 (UI)** ✋
