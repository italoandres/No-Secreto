# Design Document

## Overview

Este documento descreve o design para implementar um sistema de notificações específico para o chat "Nosso Propósito", substituindo o ícone de 3 pontos por funcionalidade de notificações independente com suporte a stories salvos.

## Architecture

### Component Structure
```
NossoPropositoView
├── AppBar (existing)
│   ├── Menu/Admin Button (existing)
│   ├── Community Button (existing)
│   └── NotificationIconComponent (NEW - replaces 3-dots menu)
├── Chat Content (existing)
└── Stories Integration (existing)
```

### Data Flow
```
User Action → NotificationIconComponent → NotificationsView(contexto: 'nosso_proposito') → NotificationService → Firebase
```

## Components and Interfaces

### 1. NotificationIconComponent Enhancement

**Purpose:** Extend existing component to support context-specific filtering

**Interface:**
```dart
class NotificationIconComponent extends StatelessWidget {
  final String? contexto;
  final Color? iconColor;
  final double? iconSize;
  
  const NotificationIconComponent({
    Key? key,
    this.contexto,
    this.iconColor,
    this.iconSize,
  }) : super(key: key);
}
```

**Key Features:**
- Context-aware notification counting
- Visual consistency with chat theme
- Badge display for unread notifications
- Tap handling for navigation

### 2. NotificationService Context Filtering

**Purpose:** Filter notifications by context

**New Methods:**
```dart
class NotificationService {
  // Get notifications for specific context
  static Stream<List<NotificationModel>> getContextNotifications(
    String userId, 
    String contexto
  );
  
  // Get unread count for specific context
  static Stream<int> getContextUnreadCount(
    String userId, 
    String contexto
  );
  
  // Mark context notifications as read
  static Future<void> markContextNotificationsAsRead(
    String userId, 
    String contexto
  );
}
```

### 3. NotificationsView Context Support

**Purpose:** Display context-filtered notifications

**Enhancements:**
- Context parameter handling
- Context-specific story favorites integration
- Context-aware empty state messages
- Context-specific styling

### 4. Story Favorites Integration

**Purpose:** Access saved stories for specific context

**Interface:**
```dart
class StoryFavoritesView extends StatefulWidget {
  final String contexto;
  
  const StoryFavoritesView({
    Key? key,
    required this.contexto,
  }) : super(key: key);
}
```

## Data Models

### NotificationModel Enhancement

**Current Structure:** (No changes needed)
```dart
class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String relatedId;
  final String fromUserId;
  final String fromUserName;
  final String fromUserAvatar;
  final String content;
  final bool isRead;
  final DateTime createdAt;
  // Context will be inferred from story/chat context
}
```

### Context Mapping Strategy

**Context Identification:**
- Stories: Use existing context field in StorieFileModel
- Notifications: Derive context from related story/chat
- Favorites: Filter by context parameter

## Error Handling

### Notification Loading Errors
- **Scenario:** Firebase connection issues
- **Handling:** Show retry button with error message
- **Fallback:** Display cached notifications if available

### Context Filtering Errors
- **Scenario:** Invalid context parameter
- **Handling:** Default to showing all notifications
- **Logging:** Log context errors for debugging

### Story Favorites Errors
- **Scenario:** Stories not loading
- **Handling:** Show empty state with refresh option
- **Fallback:** Display generic message

## Testing Strategy

### Unit Tests
1. **NotificationService Context Filtering**
   - Test context parameter validation
   - Test notification filtering logic
   - Test unread count calculation

2. **NotificationIconComponent**
   - Test badge display logic
   - Test context parameter handling
   - Test tap navigation

### Integration Tests
1. **End-to-End Notification Flow**
   - Create notification in "nosso_proposito" context
   - Verify it appears in context-filtered view
   - Verify it doesn't appear in other contexts

2. **Story Favorites Integration**
   - Save story in "nosso_proposito" context
   - Verify it appears in context-filtered favorites
   - Verify navigation from notifications view

### Widget Tests
1. **NotificationsView Context Rendering**
   - Test context-specific empty states
   - Test context-specific story favorites button
   - Test context parameter propagation

## Implementation Phases

### Phase 1: Core Infrastructure
1. Enhance NotificationIconComponent with context support
2. Add context filtering to NotificationService
3. Update NotificationsView to handle context parameter

### Phase 2: UI Integration
1. Replace 3-dots menu in NossoPropositoView
2. Position notification icon appropriately
3. Ensure visual consistency

### Phase 3: Story Favorites Integration
1. Add story favorites button to context notifications
2. Implement context filtering in StoryFavoritesView
3. Test cross-navigation between notifications and favorites

### Phase 4: Testing and Polish
1. Implement comprehensive test suite
2. Add error handling and edge cases
3. Performance optimization and caching

## Visual Design Specifications

### Icon Positioning
- **Location:** Replace 3-dots menu position
- **Size:** 50x50 container (consistent with other buttons)
- **Background:** Colors.white38 (consistent with theme)
- **Icon:** Icons.notifications_outlined, white color

### Badge Design
- **Color:** Red background with white border
- **Size:** Minimum 18x18, auto-expand for larger numbers
- **Position:** Top-right corner of icon
- **Text:** White, bold, 10px font size

### Integration Points
- **Left Side:** After community icon
- **Spacing:** 8px margin from community icon
- **Alignment:** Vertically centered with other buttons

## Performance Considerations

### Notification Queries
- **Optimization:** Use compound indexes for userId + context filtering
- **Caching:** Implement local caching for frequently accessed notifications
- **Pagination:** Implement pagination for large notification lists

### Real-time Updates
- **Strategy:** Use Firestore real-time listeners with context filtering
- **Efficiency:** Minimize listener scope to reduce bandwidth
- **Memory:** Properly dispose listeners to prevent memory leaks

## Security Considerations

### Context Validation
- **Input Sanitization:** Validate context parameters
- **Access Control:** Ensure users can only access their own notifications
- **Data Isolation:** Prevent cross-context data leakage

### Firebase Rules
```javascript
// Firestore security rules for context-aware notifications
match /notifications/{notificationId} {
  allow read, write: if request.auth != null 
    && request.auth.uid == resource.data.userId;
}
```