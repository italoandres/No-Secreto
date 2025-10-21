# Design Document - TikTok Stories System

## Overview

O sistema TikTok Stories transforma o módulo de Stories existente em uma experiência social completa, similar ao TikTok, com foco em engajamento e interatividade. O sistema será construído usando Flutter com arquitetura MVC, Firebase para backend e notificações, e otimizações para performance e consumo de dados.

## Architecture

### High-Level Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Presentation  │    │    Business     │    │      Data       │
│     Layer       │◄──►│     Logic       │◄──►│     Layer       │
│                 │    │     Layer       │    │                 │
│ - Stories View  │    │ - Controllers   │    │ - Repositories  │
│ - Comments UI   │    │ - Services      │    │ - Models        │
│ - Interactions  │    │ - Validators    │    │ - Firebase      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Core Components

1. **Stories Display System**: Tela cheia vertical com navegação lateral
2. **Interaction System**: Curtidas, salvos, comentários
3. **Comment System**: Threads, respostas, menções
4. **Notification System**: Push notifications para interações
5. **Auto-Publishing System**: Publicação sequencial automática
6. **Moderation System**: Filtro automático de conteúdo
7. **Analytics System**: Coleta de métricas de engajamento

## Components and Interfaces

### 1. Stories Display Components

#### TikTokStoriesView
```dart
class TikTokStoriesView extends StatefulWidget {
  final List<Story> stories;
  final int initialIndex;
  final Function(Story) onStoryComplete;
}
```

#### StoryVideoPlayer
```dart
class StoryVideoPlayer extends StatefulWidget {
  final Story story;
  final bool isActive;
  final Function onDoubleTap;
  final Function onSingleTap;
}
```

### 2. Interaction Components

#### StoryInteractionsPanel
```dart
class StoryInteractionsPanel extends StatelessWidget {
  final Story story;
  final Function onLike;
  final Function onSave;
  final Function onComment;
  final Function onShare;
}
```

#### LikeAnimationWidget
```dart
class LikeAnimationWidget extends StatefulWidget {
  final bool isVisible;
  final Offset position;
}
```

### 3. Comment System Components

#### StoryCommentsBottomSheet
```dart
class StoryCommentsBottomSheet extends StatefulWidget {
  final String storyId;
  final Function(Comment) onCommentAdded;
}
```

#### CommentThreadWidget
```dart
class CommentThreadWidget extends StatefulWidget {
  final Comment comment;
  final List<Comment> replies;
  final Function(Comment) onReply;
  final Function(String) onMention;
}
```

#### UserMentionSelector
```dart
class UserMentionSelector extends StatefulWidget {
  final String query;
  final Function(User) onUserSelected;
}
```

## Data Models

### Story Model
```dart
class Story {
  final String id;
  final String userId;
  final String username;
  final String userAvatar;
  final String videoUrl;
  final String thumbnailUrl;
  final DateTime createdAt;
  final int duration;
  final StoryStats stats;
  final bool isLiked;
  final bool isSaved;
}

class StoryStats {
  final int views;
  final int likes;
  final int comments;
  final int shares;
  final int watchTime; // em segundos
}
```

### Comment Model
```dart
class Comment {
  final String id;
  final String storyId;
  final String userId;
  final String username;
  final String userAvatar;
  final String text;
  final List<UserMention> mentions;
  final DateTime createdAt;
  final int likes;
  final bool isLiked;
  final String? parentCommentId;
  final List<Comment> replies;
  final bool isModerated;
}

class UserMention {
  final String userId;
  final String username;
  final int startIndex;
  final int endIndex;
}
```

### Notification Model
```dart
class StoryNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String storyId;
  final String? commentId;
  final String triggerUserId;
  final String triggerUsername;
  final DateTime createdAt;
  final bool isRead;
}

enum NotificationType {
  commentLiked,
  commentReplied,
  userMentioned,
  storyLiked
}
```

## Services and Controllers

### StoriesController
```dart
class StoriesController extends GetxController {
  // Story navigation and playback
  void nextStory();
  void previousStory();
  void pauseStory();
  void resumeStory();
  
  // Interactions
  Future<void> likeStory(String storyId);
  Future<void> saveStory(String storyId);
  Future<void> shareStory(String storyId);
  
  // Auto-publishing
  void startAutoPublishing();
  void loadNextBatch();
}
```

### CommentsController
```dart
class CommentsController extends GetxController {
  Future<void> loadComments(String storyId);
  Future<void> addComment(String storyId, String text, List<UserMention> mentions);
  Future<void> replyToComment(String commentId, String text);
  Future<void> likeComment(String commentId);
  Future<List<User>> searchUsers(String query);
}
```

### NotificationController
```dart
class NotificationController extends GetxController {
  Future<void> sendNotification(StoryNotification notification);
  Future<void> markAsRead(String notificationId);
  Future<List<StoryNotification>> getUserNotifications();
}
```

## Repositories

### StoriesRepository
```dart
class StoriesRepository {
  Future<List<Story>> getStories({int limit, String? lastStoryId});
  Future<Story> getStoryById(String id);
  Future<void> incrementViews(String storyId);
  Future<void> updateWatchTime(String storyId, int seconds);
  Future<void> likeStory(String storyId, String userId);
  Future<void> saveStory(String storyId, String userId);
}
```

### CommentsRepository
```dart
class CommentsRepository {
  Future<List<Comment>> getComments(String storyId);
  Future<Comment> addComment(Comment comment);
  Future<void> likeComment(String commentId, String userId);
  Future<List<Comment>> getReplies(String commentId);
}
```

### ModerationRepository
```dart
class ModerationRepository {
  Future<bool> isContentAppropriate(String text);
  Future<void> reportComment(String commentId, String reason);
  Future<List<String>> getBannedWords();
}
```

## Error Handling

### Network Errors
- Implementar retry automático para falhas de rede
- Cache local para stories já carregados
- Fallback para modo offline com conteúdo em cache

### Validation Errors
- Validação de comentários antes do envio
- Sanitização de input do usuário
- Verificação de menções válidas

### Performance Errors
- Lazy loading de comentários
- Paginação de stories
- Compressão de vídeos
- Cache inteligente de thumbnails

## Testing Strategy

### Unit Tests
- Testes para todos os controllers
- Testes para validação de comentários
- Testes para sistema de menções
- Testes para filtro de moderação

### Integration Tests
- Fluxo completo de visualização de stories
- Sistema de comentários e respostas
- Notificações push
- Auto-publishing de stories

### Widget Tests
- Componentes de interação
- Animações de curtida
- Bottom sheet de comentários
- Player de vídeo

### Performance Tests
- Consumo de memória com muitos stories
- Tempo de carregamento de comentários
- Eficiência do cache de vídeos
- Responsividade da interface

## Security Considerations

### Authentication
- Verificação de usuário autenticado para comentários
- Validação de tokens JWT
- Rate limiting para interações

### Content Moderation
- Filtro automático de palavras inadequadas
- Sistema de denúncias
- Moderação manual para casos complexos
- Blacklist de usuários problemáticos

### Data Privacy
- Criptografia de dados sensíveis
- Conformidade com LGPD
- Anonização de analytics
- Controle de privacidade do usuário

## Performance Optimizations

### Video Handling
- Compressão adaptativa baseada na conexão
- Pre-loading do próximo vídeo
- Cache inteligente com LRU
- Streaming progressivo

### UI Performance
- Virtual scrolling para comentários
- Lazy loading de avatares
- Debounce em buscas de usuários
- Otimização de animações

### Data Management
- Paginação eficiente
- Sincronização incremental
- Compressão de payloads
- Cache distribuído

## Analytics and Monitoring

### Engagement Metrics
- Tempo de visualização por story
- Taxa de conclusão de vídeos
- Interações por usuário
- Comentários por story

### Performance Metrics
- Tempo de carregamento
- Taxa de erro de rede
- Uso de memória
- Crash reports

### Business Metrics
- Retenção de usuários
- Stories mais populares
- Horários de maior engajamento
- Crescimento da base de usuários