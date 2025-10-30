# Design Document

## Overview

Este design transforma o modal de comentários dos Stories de uma página tradicional (MaterialPageRoute) em um Bottom Sheet moderno e interativo, inspirado nas melhores práticas de UX do Instagram e Telegram. A solução mantém 100% da funcionalidade backend existente enquanto moderniza completamente a apresentação visual e interações.

## Architecture

### Component Structure

```
EnhancedStoriesViewerView (existente)
  └─> showModalBottomSheet (NOVO - substitui Navigator.push)
       └─> ModernCommunityCommentsView (NOVO - wrapper moderno)
            ├─> DraggableScrollableSheet (NOVO - controle de arrasto)
            ├─> ModalHeader (NOVO - cabeçalho fixo)
            ├─> CommentsScrollableContent (NOVO)
            │    ├─> SectionHeader (NOVO - "Chats em Alta", etc)
            │    ├─> ModernCommentCard (REFATORADO)
            │    │    ├─> UserInfoRow (NOVO)
            │    │    ├─> CommentText (NOVO)
            │    │    └─> EngagementActionsRow (NOVO)
            │    └─> [Repetir para cada seção]
            └─> FixedCommentInput (NOVO - rodapé fixo)
```

### Data Flow

```
1. User taps "Comentários" button
   ↓
2. EnhancedStoriesViewerView calls showModalBottomSheet
   ↓
3. ModernCommunityCommentsView initializes
   ↓
4. StoryInteractionsRepository loads comments (EXISTENTE - sem mudanças)
   ↓
5. Comments organized into sections (NOVA lógica de UI)
   ↓
6. Real-time updates via existing listeners (PRESERVADO)
```

## Components and Interfaces

### 1. ModernCommunityCommentsView

**Responsabilidade:** Container principal do modal moderno

**Interface:**
```dart
class ModernCommunityCommentsView extends StatefulWidget {
  final String storyId;
  final String storyTitle;
  final String storyDescription;
  
  const ModernCommunityCommentsView({
    required this.storyId,
    required this.storyTitle,
    required this.storyDescription,
  });
}
```

**Características:**
- Usa DraggableScrollableSheet para controle de altura
- initialChildSize: 0.9 (90% da tela)
- minChildSize: 0.5 (50% da tela quando arrastado)
- maxChildSize: 0.95 (95% da tela quando expandido)
- Fundo branco com borderRadius superior (20.0)
- Sombra sutil para profundidade

### 2. ModalHeader

**Responsabilidade:** Cabeçalho fixo com informações do Story

**Interface:**
```dart
class ModalHeader extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onClose;
}
```

**Layout:**
```
┌─────────────────────────────────────┐
│ [←]  SINAIS DE MINHA REBECA        │ ← Bold, 16px
│      Como discernir quando é Deus   │ ← Grey, 13px
│      [Ver mais ▼]                   │ ← Link, 12px
└─────────────────────────────────────┘
```

**Características:**
- Altura fixa: 80px
- Padding: 16px horizontal, 12px vertical
- Botão voltar à esquerda
- Título truncado com maxLines: 1
- Descrição expansível (collapsed por padrão)

### 3. ModernCommentCard

**Responsabilidade:** Card individual de comentário com hierarquia visual clara

**Interface:**
```dart
class ModernCommentCard extends StatelessWidget {
  final CommunityCommentModel comment;
  final VoidCallback onLike;
  final VoidCallback onReply;
  final bool isHighlighted; // Para "Chats em Alta"
}
```

**Layout:**
```
┌─────────────────────────────────────┐
│ 👤 Italo Lior          há 1h        │ ← Bold 16px | Grey 12px
│ ❤️ 42  💭 12  Última há 3h          │ ← Grey 13px, ícones coloridos
│                                     │
│ Senti que era ela, mas depois       │ ← Regular 15px
│ tudo esfriou...                     │
│                                     │
│ [♡ Curtir]  [💬 Responder]          │ ← Botões de ação
└─────────────────────────────────────┘
```

**Características:**
- Padding: 16px
- Margin bottom: 12px
- Background: Colors.grey[50] para cards normais
- Background: Gradient sutil para "Chats em Alta"
- Border radius: 12px
- Sombra leve: elevation 1

**Hierarquia Visual:**
1. **Nome do usuário:** FontWeight.bold, fontSize: 16, color: Colors.black87
2. **Data/hora:** FontWeight.normal, fontSize: 12, color: Colors.grey[600]
3. **Estatísticas:** FontWeight.w500, fontSize: 13, color: Colors.grey[700]
4. **Texto do comentário:** FontWeight.normal, fontSize: 15, color: Colors.black87
5. **Botões de ação:** fontSize: 14, color: Theme primary

### 4. EngagementActionsRow

**Responsabilidade:** Botões de interação (curtir e responder)

**Interface:**
```dart
class EngagementActionsRow extends StatelessWidget {
  final int likeCount;
  final bool isLiked;
  final VoidCallback onLike;
  final VoidCallback onReply;
}
```

**Layout:**
```
[♡ Curtir (42)]    [💬 Responder]
```

**Características:**
- Altura: 40px
- Espaçamento entre botões: 16px
- Ícone de coração:
  - Não curtido: Icons.favorite_border, Colors.grey[600]
  - Curtido: Icons.favorite, Colors.red[400]
- Botão "Responder": TextButton com ícone de chat
- Animação de scale ao tocar (0.95)

### 5. SectionHeader

**Responsabilidade:** Cabeçalho de seção (Chats em Alta, Recentes, Pai)

**Interface:**
```dart
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? accentColor;
}
```

**Layout:**
```
🔥 CHATS EM ALTA
```

**Características:**
- Padding: 20px horizontal, 16px vertical
- fontSize: 18, FontWeight.w600
- Ícone à esquerda com tamanho 24px
- Cor do ícone baseada na seção:
  - Alta: Colors.orange[600]
  - Recentes: Colors.green[600]
  - Pai: Colors.purple[600]

### 6. FixedCommentInput

**Responsabilidade:** Campo de entrada fixo no rodapé

**Interface:**
```dart
class FixedCommentInput extends StatefulWidget {
  final Function(String) onSubmit;
  final String placeholder;
}
```

**Layout:**
```
┌─────────────────────────────────────┐
│ [Escreva o que o Pai falou...] [➤] │
└─────────────────────────────────────┘
```

**Características:**
- Altura: 60px
- Background: Colors.white
- Border top: 1px solid Colors.grey[300]
- TextField com:
  - Border radius: 24px
  - Background: Colors.grey[100]
  - Padding: 12px horizontal
  - maxLines: 3
- Botão enviar:
  - Circular, 44px
  - Cor primária do tema
  - Ícone: Icons.send
  - Desabilitado quando texto vazio

## Data Models

### CommentSection (NOVO)

```dart
enum CommentSection {
  trending,  // Chats em Alta (>20 reações ou >5 respostas)
  recent,    // Chats Recentes (<24h e baixo engajamento)
  featured,  // Chats do Pai (curados/fixados)
}

class SectionedComments {
  final List<CommunityCommentModel> trending;
  final List<CommunityCommentModel> recent;
  final List<CommunityCommentModel> featured;
  
  SectionedComments({
    required this.trending,
    required this.recent,
    required this.featured,
  });
}
```

### CommunityCommentModel (EXISTENTE - sem mudanças)

Mantém todos os campos existentes:
- id, storyId, userId, userName, userPhotoUrl
- commentText, timestamp
- likesCount, repliesCount
- isLiked, isPinned

## Error Handling

### Cenários de Erro

1. **Falha ao carregar comentários**
   - Exibir estado vazio com mensagem amigável
   - Botão "Tentar novamente"
   - Manter modal aberto

2. **Falha ao enviar comentário**
   - Mostrar SnackBar com erro
   - Manter texto digitado no campo
   - Permitir reenvio

3. **Perda de conexão durante scroll**
   - Manter comentários já carregados visíveis
   - Indicador discreto de "offline" no topo
   - Reconectar automaticamente quando possível

4. **Modal não abre**
   - Fallback para página tradicional (código existente)
   - Log de erro para debug

## Testing Strategy

### Unit Tests

1. **SectionedComments Logic**
   - Teste de categorização de comentários
   - Verificar ordenação por engajamento
   - Validar filtros de tempo

2. **EngagementActionsRow**
   - Teste de toggle de like
   - Verificar contadores
   - Validar callbacks

### Widget Tests

1. **ModernCommentCard**
   - Renderização correta de dados
   - Hierarquia visual (tamanhos de fonte)
   - Interações de botões

2. **FixedCommentInput**
   - Validação de entrada
   - Estado do botão enviar
   - Comportamento do teclado

3. **ModalHeader**
   - Expansão de descrição
   - Botão de fechar
   - Truncamento de texto

### Integration Tests

1. **Modal Opening Flow**
   - Abrir modal a partir do Story
   - Animação de deslize
   - Gesto de pull-to-dismiss

2. **Comment Submission Flow**
   - Digitar comentário
   - Enviar
   - Verificar aparição na lista

3. **Real-time Updates**
   - Simular novo comentário de outro usuário
   - Verificar atualização automática
   - Validar posicionamento na seção correta

## Visual Design Specifications

### Colors

```dart
// Backgrounds
modalBackground: Colors.white
cardBackground: Colors.grey[50]
cardBackgroundHighlighted: LinearGradient(
  colors: [Colors.orange[50], Colors.white],
)
inputBackground: Colors.grey[100]

// Text
primaryText: Colors.black87
secondaryText: Colors.grey[600]
tertiaryText: Colors.grey[500]

// Accents
trendingAccent: Colors.orange[600]
recentAccent: Colors.green[600]
featuredAccent: Colors.purple[600]
likeColor: Colors.red[400]
```

### Typography

```dart
// Headers
sectionTitle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)
modalTitle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)

// Comment Card
userName: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
commentText: TextStyle(fontSize: 15, fontWeight: FontWeight.normal)
timestamp: TextStyle(fontSize: 12, color: Colors.grey[600])
stats: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)

// Actions
actionButton: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)
```

### Spacing

```dart
// Padding
modalPadding: 16.0
cardPadding: 16.0
sectionPadding: 20.0 (horizontal), 16.0 (vertical)

// Margins
cardMargin: 12.0 (bottom)
sectionMargin: 24.0 (bottom)

// Border Radius
modalRadius: 20.0
cardRadius: 12.0
inputRadius: 24.0
```

### Animations

```dart
// Modal Opening
duration: 300ms
curve: Curves.easeOutCubic

// Button Press
duration: 150ms
curve: Curves.easeInOut
scale: 0.95

// Like Animation
duration: 200ms
curve: Curves.elasticOut
scale: 1.2 → 1.0
```

## Implementation Notes

### Migration Strategy

1. **Fase 1:** Criar novos componentes sem afetar código existente
2. **Fase 2:** Substituir Navigator.push por showModalBottomSheet
3. **Fase 3:** Testar ambos os fluxos em paralelo
4. **Fase 4:** Remover código antigo após validação

### Performance Considerations

- Usar `ListView.builder` para listas longas
- Implementar lazy loading para comentários (paginar a cada 20)
- Cache de imagens de perfil com `CachedNetworkImage`
- Debounce no campo de busca (se implementado futuramente)

### Accessibility

- Todos os botões com Semantics labels
- Contraste de cores WCAG AA compliant
- Tamanhos de toque mínimos: 44x44px
- Suporte a leitores de tela

### Backward Compatibility

- Manter `CommunityCommentsView` original como fallback
- Feature flag para habilitar/desabilitar novo modal
- Logs de analytics para comparar engajamento
