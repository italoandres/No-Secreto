# Design Document

## Overview

Este design visa reorganizar a interface de personalização do usuário no chat principal, consolidando todas as opções de customização (username, nome, foto de perfil e papel de parede) em um menu único e intuitivo. A solução remove redundâncias na interface e melhora a experiência do usuário.

## Architecture

### Current State Analysis
- **Chat View**: Possui ícone de câmera no AppBar (canto superior direito)
- **Profile Menu**: Já existe menu "Editar Perfil" com username e nome
- **Redundancy**: Foto de perfil pode ser alterada em dois lugares diferentes

### Target State
- **Unified Profile Menu**: Todas as opções de personalização em um local
- **Clean Chat Interface**: Remoção do ícone de câmera redundante
- **Improved UX**: Interface mais organizada e intuitiva

## Components and Interfaces

### 1. Chat View Modifications
**File**: `lib/views/chat_view.dart`

**Changes**:
- Remove camera icon from AppBar actions
- Keep existing three-dots menu functionality
- Maintain wallpaper display functionality

**Interface**:
```dart
AppBar(
  // Remove: IconButton with camera icon
  actions: [
    // Keep only: PopupMenuButton with existing options
  ]
)
```

### 2. Profile Edit Dialog Enhancement
**File**: `lib/views/chat_view.dart` (within _showEditProfileDialog)

**Current Structure**:
```dart
_showEditProfileDialog() {
  // Username field
  // Name field
  // Save button
}
```

**Enhanced Structure**:
```dart
_showEditProfileDialog() {
  // Username field
  // Name field
  // Profile photo section with preview and change button
  // Wallpaper section with preview and change button
  // Save button
}
```

### 3. Image Selection Methods
**New Methods to Add**:

```dart
// Profile photo selection
Future<void> _selectProfilePhoto() async {
  // Use existing photo selection logic
  // Update user profile photo
  // Refresh UI
}

// Wallpaper selection  
Future<void> _selectWallpaper() async {
  // Use existing wallpaper selection logic
  // Apply wallpaper immediately
  // Save to preferences
}
```

## Data Models

### User Profile Data
**Current**: Username, Name, Profile Photo URL
**Enhanced**: Username, Name, Profile Photo URL, Wallpaper URL/Path

### Storage Structure
```dart
// SharedPreferences keys
static const String WALLPAPER_KEY = 'chat_wallpaper';
static const String PROFILE_PHOTO_KEY = 'profile_photo_url';

// User document structure (Firestore)
{
  'username': String,
  'nome': String, 
  'profilePhotoUrl': String?,
  'wallpaperUrl': String?, // New field
}
```

## Error Handling

### Image Selection Errors
```dart
try {
  // Image selection logic
} catch (e) {
  Get.rawSnackbar(
    message: 'Erro ao selecionar imagem: $e',
    backgroundColor: Colors.red,
  );
}
```

### Upload Errors
```dart
try {
  // Upload logic
} catch (e) {
  // Revert to previous image
  // Show error message
  Get.rawSnackbar(
    message: 'Erro no upload. Imagem anterior mantida.',
    backgroundColor: Colors.orange,
  );
}
```

### Network Errors
- Graceful degradation when offline
- Cache previous wallpaper locally
- Retry mechanism for failed uploads

## Testing Strategy

### Unit Tests
- Test image selection methods
- Test wallpaper application logic
- Test error handling scenarios
- Test data persistence

### Integration Tests
- Test complete profile edit flow
- Test wallpaper change and immediate application
- Test navigation between chat and profile edit
- Test image upload and storage

### UI Tests
- Verify camera icon removal
- Verify enhanced profile dialog layout
- Test image preview functionality
- Test responsive design on different screen sizes

### User Acceptance Tests
- User can access all profile options in one place
- Wallpaper changes apply immediately
- Interface is cleaner without camera icon
- All existing functionality is preserved

## Implementation Notes

### Phase 1: Remove Camera Icon
1. Locate camera icon in chat_view.dart AppBar
2. Remove IconButton from actions array
3. Test that three-dots menu still works

### Phase 2: Enhance Profile Dialog
1. Add profile photo section with preview
2. Add wallpaper section with preview  
3. Implement image selection methods
4. Add proper error handling

### Phase 3: Integration & Testing
1. Test complete user flow
2. Verify immediate wallpaper application
3. Test error scenarios
4. Performance testing with large images

### Technical Considerations
- **Image Optimization**: Compress images before upload
- **Caching**: Cache wallpapers locally for performance
- **Memory Management**: Dispose image controllers properly
- **Permissions**: Ensure gallery access permissions are handled