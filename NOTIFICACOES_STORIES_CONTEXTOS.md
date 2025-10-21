# Notificações de Stories por Contexto 📖

## Visão Geral

O sistema de notificações já está configurado para exibir notificações de stories de TODOS os contextos na aba "Stories" da NotificationsView:

- 🤵 **Sinais de Meu Isaque** (sinais_isaque) - Para mulheres
- 👰‍♀️ **Sinais de Minha Rebeca** (sinais_rebeca) - Para homens  
- 💕 **Nosso Propósito** (nosso_proposito) - Para ambos
- 💬 **Principal** (principal) - Contexto geral

## Como Funciona

### 1. Repositório Busca Todas as Notificações

```dart
// NotificationRepository.getUserNotifications(userId)
// Busca TODAS as notificações do usuário, independente do contexto

_firestore
  .collection('notifications')
  .where('userId', isEqualTo: userId)
  .orderBy('createdAt', descending: true)
  .limit(50)
```

### 2. Controller Filtra por Tipo

```dart
// UnifiedNotificationController._loadStoriesNotifications()
// Filtra apenas notificações de stories

final storyNotifications = notifications.where((n) {
  final type = n.type;
  return type == 'like' || 
         type == 'comment' || 
         type == 'mention' || 
         type == 'reply' || 
         type == 'comment_like';
}).toList();
```

### 3. Widget Exibe com Contexto Visual

O `StoryNotificationItem` exibe:
- Avatar do usuário que interagiu
- Nome + ação (curtiu, comentou, mencionou)
- Preview do conteúdo (se houver)
- Timestamp relativo (há 2 horas, há 1 dia)
- Badge com emoji do tipo de interação
- Indicador de não lida (ponto azul)

## Tipos de Notificações de Stories

### 1. Curtidas (like)
- 👍 Emoji: Coração
- Cor: Vermelho
- Ação: "curtiu seu story"

### 2. Comentários (comment)
- 💬 Emoji: Balão de fala
- Cor: Azul
- Ação: "comentou no seu story"
- Mostra preview do comentário

### 3. Menções (mention)
- @ Emoji: Arroba
- Cor: Roxo
- Ação: "mencionou você em um story"
- Card roxo especial com badge @

### 4. Respostas (reply)
- ↩️ Emoji: Seta de resposta
- Cor: Verde
- Ação: "respondeu seu comentário"
- Mostra preview da resposta

### 5. Curtidas em Comentários (comment_like)
- ❤️ Emoji: Coração pequeno
- Cor: Rosa
- Ação: "curtiu seu comentário"

## Estrutura da Notificação no Firebase

```json
{
  "id": "abc123",
  "userId": "user_id_destinatario",
  "fromUserId": "user_id_remetente",
  "fromUserName": "João Silva",
  "fromUserAvatar": "https://...",
  "type": "like|comment|mention|reply|comment_like",
  "message": "Texto do comentário/resposta",
  "content": "Conteúdo adicional",
  "storyId": "story_id",
  "contexto": "sinais_isaque|sinais_rebeca|nosso_proposito|principal",
  "isRead": false,
  "createdAt": Timestamp,
  "timestamp": DateTime
}
```

## Fluxo de Dados

```
Firebase Firestore (notifications collection)
    ↓
NotificationRepository.getUserNotifications(userId)
    ↓ (busca TODAS as notificações)
UnifiedNotificationController._loadStoriesNotifications()
    ↓ (filtra por tipo: like, comment, mention, reply, comment_like)
storiesNotifications observable
    ↓
NotificationsView → Stories Tab
    ↓
NotificationItemFactory.createNotificationItem()
    ↓
StoryNotificationItem (widget)
    ↓
UI exibe notificação com contexto visual
```

## Verificação

### ✅ Sistema Já Configurado

1. **Repository:** Busca todas as notificações ✅
2. **Controller:** Filtra por tipo de story ✅
3. **Widget:** Exibe com contexto visual ✅
4. **Badge:** Conta não lidas ✅
5. **Navegação:** Ao clicar, vai para o story ✅

### 🔍 Como Testar

1. **Criar notificação de teste:**
   - Vá para StoriesView de um contexto (sinais_isaque, sinais_rebeca, etc)
   - Publique um story
   - Peça para outro usuário curtir/comentar

2. **Verificar na NotificationsView:**
   - Abra NotificationsView
   - Vá para aba "Stories"
   - Deve aparecer a notificação com:
     - Avatar do usuário
     - Nome + ação
     - Preview (se comentário)
     - Timestamp
     - Badge do tipo
     - Ponto azul (se não lida)

3. **Verificar badge:**
   - Badge vermelho no ícone de sino deve aumentar
   - Ao clicar na notificação, badge deve diminuir

## Contextos Visuais

### Sinais de Meu Isaque (sinais_isaque)
- 🤵 Emoji: Noivo
- Cor: Rosa (#f76cec)
- Para: Mulheres
- Stories de homens para mulheres verem

### Sinais de Minha Rebeca (sinais_rebeca)
- 👰‍♀️ Emoji: Noiva
- Cor: Azul (#38b6ff)
- Para: Homens
- Stories de mulheres para homens verem

### Nosso Propósito (nosso_proposito)
- 💕 Emoji: Dois corações
- Cor: Gradiente rosa-azul
- Para: Ambos
- Stories de propósito compartilhado

### Principal (principal)
- 💬 Emoji: Balão de fala
- Cor: Verde
- Para: Todos
- Stories gerais da comunidade

## Diferença entre StoriesView e NotificationsView

### StoriesView
- Mostra os STORIES (fotos/vídeos)
- Filtrado por contexto específico
- Para visualizar conteúdo

### NotificationsView → Stories Tab
- Mostra as NOTIFICAÇÕES sobre stories
- Todas as notificações juntas (todos os contextos)
- Para ver quem interagiu com seus stories

## Exemplo de Uso

```dart
// Usuário publica story em "Sinais de Meu Isaque"
StoriesController.getFile(contexto: 'sinais_isaque');

// Outro usuário curte o story
// Sistema cria notificação automaticamente:
NotificationRepository.createNotification(
  NotificationModel(
    userId: 'dono_do_story',
    fromUserId: 'quem_curtiu',
    type: 'like',
    contexto: 'sinais_isaque',
    storyId: 'story_id',
    // ...
  )
);

// Notificação aparece em:
// 1. Badge vermelho no ícone de sino (+1)
// 2. NotificationsView → Stories Tab
// 3. Com contexto visual (emoji 🤵, cor rosa)
```

## Conclusão

✅ **O sistema JÁ ESTÁ FUNCIONANDO!**

Todas as notificações de stories de todos os contextos (sinais_isaque, sinais_rebeca, nosso_proposito, principal) já aparecem na aba "Stories" da NotificationsView.

Não é necessário fazer nenhuma configuração adicional. O sistema está completo e operacional! 🎉
