# Design Document

## Overview

O sistema de perfis espirituais será construído como uma extensão do sistema atual de usuários, criando uma "vitrine de propósito" completa. O design foca em três componentes principais: um sistema de conclusão de tarefas dinâmico, uma página de perfil completa acessível via username, e um sistema de interações seguras baseado em interesse mútuo.

## Architecture

### Current System Integration
```
Existing: UsuarioModel + CompletarPerfilView (basic)
New: SpiritualProfileModel + ProfileCompletionView (advanced) + ProfileDisplayView
```

### Data Flow
```
User Login → Profile Completion Tasks → Spiritual Profile Creation → Public Profile Display → Interaction System
```

## Components and Interfaces

### 1. Enhanced User Model

**New SpiritualProfileModel:**
```dart
class SpiritualProfileModel {
  String? userId;
  
  // Profile Completion Status
  bool isProfileComplete;
  Map<String, bool> completionTasks; // Task completion tracking
  DateTime? profileCompletedAt;
  
  // Photos (up to 3)
  String? mainPhotoUrl; // Required
  String? secondaryPhoto1Url; // Optional
  String? secondaryPhoto2Url; // Optional
  
  // Spiritual Identity
  String? city; // "São Paulo - SP"
  int? age;
  
  // Biography Questions
  String? purpose; // "Qual é o seu propósito?" (300 chars)
  bool? isDeusEPaiMember; // "Você faz parte do movimento Deus é Pai?"
  RelationshipStatus? relationshipStatus; // Solteiro/Comprometido
  bool? readyForPurposefulRelationship; // "Disposto a viver relacionamento com propósito?"
  String? nonNegotiableValue; // "Qual valor é inegociável?"
  String? faithPhrase; // "Uma frase que representa sua fé"
  String? aboutMe; // "Algo que gostaria que soubessem" (optional)
  
  // Spiritual Certification
  bool? hasSinaisPreparationSeal; // "Preparado(a) para os Sinais"
  DateTime? sealObtainedAt;
  
  // Interaction Settings
  bool allowInteractions; // Can receive "Tenho Interesse"
  List<String> blockedUsers;
  
  DateTime? createdAt;
  DateTime? updatedAt;
}

enum RelationshipStatus {
  solteiro,
  comprometido,
  naoInformado
}
```

### 2. Profile Completion System

**ProfileCompletionView:**
```dart
class ProfileCompletionView extends StatefulWidget {
  // Dynamic task completion interface
  // Progress tracking with visual indicators
  // Step-by-step guided completion
}
```

**Completion Tasks:**
1. **Photos Upload** (Required: 1, Optional: 2)
2. **Spiritual Identity** (City, Age)
3. **Biography Questions** (7 structured questions)
4. **Interaction Preferences** (Allow connections)
5. **Spiritual Certification** (Optional seal)

**Task Completion UI:**
```dart
Widget buildTaskCard(String taskName, bool isCompleted, VoidCallback onTap) {
  return Card(
    child: ListTile(
      leading: Icon(
        isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
        color: isCompleted ? Colors.green : Colors.grey,
      ),
      title: Text(taskName),
      subtitle: Text(isCompleted ? 'Concluído' : 'Pendente'),
      trailing: Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    ),
  );
}
```

### 3. Public Profile Display

**ProfileDisplayView:**
```dart
class ProfileDisplayView extends StatelessWidget {
  final String userId;
  
  // Layout sections:
  // 1. Header with photos and basic info
  // 2. Spiritual identity section
  // 3. Biography with structured answers
  // 4. Interaction buttons (if applicable)
  // 5. Safety warning banner
}
```

**Profile Layout Structure:**
```
┌─────────────────────────────────────┐
│ @PropósitoDeJoão                    │
│ 📍 São Paulo - SP | 34 anos         │
│ 🟢 Solteiro | Movimento Deus é Pai  │
├─────────────────────────────────────┤
│ [Foto 1] [Foto 2] [Foto 3]         │
├─────────────────────────────────────┤
│ 🧭 Meu Propósito: [texto]           │
│ 📌 Valor Inegociável: [texto]       │
│ 🙏 Minha frase de fé: [texto]       │
│ 💬 Sobre mim: [texto]               │
├─────────────────────────────────────┤
│ 🏆 Preparado(a) para os Sinais ✓    │
├─────────────────────────────────────┤
│ [Tenho Interesse] [Conhecer Melhor] │
├─────────────────────────────────────┤
│ ⚠️ "Este app é um terreno sagrado"   │
└─────────────────────────────────────┘
```

### 4. Interaction System

**Interest Management:**
```dart
class InterestModel {
  String id;
  String fromUserId;
  String toUserId;
  DateTime createdAt;
  bool isActive;
}

class MutualInterestModel {
  String id;
  String user1Id;
  String user2Id;
  DateTime matchedAt;
  bool chatEnabled;
  DateTime? chatExpiresAt; // 7 days from match
  bool movedToNossoProposito;
}
```

**Chat Integration Flow:**
1. User A clicks "Tenho Interesse" on User B's profile
2. System creates InterestModel record
3. When User B also clicks "Tenho Interesse" on User A:
   - System creates MutualInterestModel
   - Enables "Conhecer Melhor" button for both users
4. "Conhecer Melhor" opens temporary 7-day chat
5. After 7 days, option to move to "Nosso Propósito" chat

### 5. Navigation Integration

**Username Click Handler:**
```dart
// In existing components (stories, comments, etc.)
onUsernameClick: (String username) {
  // Find user by username
  final userId = await UsernameRepository.getUserIdByUsername(username);
  if (userId != null) {
    // Check if profile is complete
    final profile = await SpiritualProfileRepository.getProfile(userId);
    if (profile?.isProfileComplete == true) {
      Get.to(() => ProfileDisplayView(userId: userId));
    } else {
      Get.snackbar('Perfil', 'Este usuário ainda está completando seu perfil');
    }
  }
}
```

## Data Models

### Database Collections

**spiritual_profiles:**
```json
{
  "userId": "string",
  "isProfileComplete": "boolean",
  "completionTasks": {
    "photos": "boolean",
    "identity": "boolean", 
    "biography": "boolean",
    "preferences": "boolean",
    "certification": "boolean"
  },
  "mainPhotoUrl": "string",
  "secondaryPhoto1Url": "string?",
  "secondaryPhoto2Url": "string?",
  "city": "string",
  "age": "number",
  "purpose": "string",
  "isDeusEPaiMember": "boolean",
  "relationshipStatus": "string",
  "readyForPurposefulRelationship": "boolean",
  "nonNegotiableValue": "string",
  "faithPhrase": "string",
  "aboutMe": "string?",
  "hasSinaisPreparationSeal": "boolean",
  "allowInteractions": "boolean",
  "blockedUsers": ["string"],
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

**user_interests:**
```json
{
  "fromUserId": "string",
  "toUserId": "string", 
  "createdAt": "timestamp",
  "isActive": "boolean"
}
```

**mutual_interests:**
```json
{
  "user1Id": "string",
  "user2Id": "string",
  "matchedAt": "timestamp",
  "chatEnabled": "boolean",
  "chatExpiresAt": "timestamp",
  "movedToNossoProposito": "boolean"
}
```

## Error Handling

### Profile Completion Validation
- **Photos**: Validate image format, size, content appropriateness
- **Text Fields**: Character limits, required field validation
- **Age**: Numeric validation, reasonable range (18-100)
- **City**: Format validation "City - State"

### Profile Display Security
- **Privacy**: Only show complete profiles
- **Blocking**: Respect blocked user lists
- **Content Moderation**: Flag inappropriate content
- **Interaction Limits**: Prevent spam/abuse

### Chat Integration Safety
- **Mutual Consent**: Both users must express interest
- **Time Limits**: 7-day temporary chat expiration
- **Escalation Path**: Clear path to "Nosso Propósito"
- **Moderation**: Admin oversight capabilities

## Testing Strategy

### Unit Tests
1. SpiritualProfileModel serialization/deserialization
2. Task completion logic validation
3. Interest matching algorithm
4. Profile display permission logic

### Integration Tests
1. Complete profile creation flow
2. Username click → profile display
3. Interest expression → mutual matching
4. Chat creation and expiration

### UI Tests
1. Profile completion task interface
2. Profile display layout responsiveness
3. Interaction button states
4. Safety warning visibility

## Implementation Phases

### Phase 1: Core Profile System
1. Create SpiritualProfileModel and repository
2. Build ProfileCompletionView with task system
3. Implement basic ProfileDisplayView
4. Add navigation from username clicks

### Phase 2: Enhanced Features
1. Add photo upload and management
2. Implement structured biography questions
3. Add spiritual certification system
4. Create interaction preference settings

### Phase 3: Social Interactions
1. Build interest expression system
2. Implement mutual interest matching
3. Create temporary chat integration
4. Add "Nosso Propósito" escalation path

### Phase 4: Safety & Moderation
1. Add content moderation tools
2. Implement blocking/reporting system
3. Create admin oversight dashboard
4. Add safety warnings and guidelines