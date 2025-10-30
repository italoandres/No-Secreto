# Design Document

## Overview

Este documento descreve o design técnico para implementar o selo de certificação espiritual no perfil público/vitrine dos usuários. A solução reutiliza o helper existente `CertificationStatusHelper` e aplica o mesmo design visual do selo dourado já implementado no `ProfileCompletionView`, garantindo consistência visual em toda a aplicação.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Profile Display Views                     │
│  ┌──────────────────────┐  ┌──────────────────────────────┐ │
│  │ ProfileDisplayView   │  │ EnhancedVitrineDisplayView   │ │
│  └──────────┬───────────┘  └──────────┬───────────────────┘ │
│             │                         │                      │
│             └─────────┬───────────────┘                      │
└───────────────────────┼──────────────────────────────────────┘
                        │
                        ▼
        ┌───────────────────────────────┐
        │  CertificationStatusHelper    │
        │  (Existing Utility)           │
        └───────────────┬───────────────┘
                        │
                        ▼
        ┌───────────────────────────────┐
        │  Firestore                    │
        │  certification_requests       │
        │  collection                   │
        └───────────────────────────────┘
```

### Component Interaction Flow

1. **Profile View Load**: Quando uma view de perfil é carregada, ela recebe o `userId` do perfil a ser exibido
2. **Certification Check**: A view chama `CertificationStatusHelper.hasApprovedCertification(userId)`
3. **Firestore Query**: O helper busca na collection `certification_requests` por documentos com `userId` e `status == 'approved'`
4. **UI Update**: Com base no resultado, a view exibe ou oculta o selo dourado
5. **Error Handling**: Em caso de erro, o selo é ocultado silenciosamente

## Components and Interfaces

### 1. CertificationStatusHelper (Existing)

**Location**: `lib/utils/certification_status_helper.dart`

**Current Implementation**:
```dart
class CertificationStatusHelper {
  static Future<bool> hasApprovedCertification(String? userId) async {
    if (userId == null || userId.isEmpty) return false;
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('certification_requests')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'approved')
          .limit(1)
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      EnhancedLogger.error('Error checking certification status', 
        tag: 'CERTIFICATION_HELPER',
        error: e
      );
      return false;
    }
  }
}
```

**Usage**: Este helper já está implementado e testado. Será reutilizado sem modificações.

### 2. ProfileDisplayView Modifications

**Location**: `lib/views/profile_display_view.dart`

**Changes Required**:

1. **Add State Variable**:
```dart
bool hasApprovedCertification = false;
```

2. **Add Certification Check Method**:
```dart
Future<void> _checkCertificationStatus() async {
  try {
    if (userId == null) return;
    
    final hasApproved = await CertificationStatusHelper.hasApprovedCertification(userId);
    
    setState(() {
      hasApprovedCertification = hasApproved;
    });
    
    EnhancedLogger.info('Certification status checked', 
      tag: 'PROFILE_DISPLAY',
      data: {
        'userId': userId,
        'hasApprovedCertification': hasApprovedCertification,
      }
    );
  } catch (e) {
    EnhancedLogger.error('Error checking certification status', 
      tag: 'PROFILE_DISPLAY',
      error: e,
      data: {'userId': userId}
    );
    setState(() {
      hasApprovedCertification = false;
    });
  }
}
```

3. **Call Check in Load Method**:
```dart
// Inside the existing load method, after profile is loaded
if (profile != null) {
  await _checkCertificationStatus();
}
```

4. **Update AppBar to Show Badge**:
```dart
Widget _buildAppBar(UsuarioModel user, SpiritualProfileModel profile) {
  return SliverAppBar(
    expandedHeight: 120,
    floating: false,
    pinned: true,
    backgroundColor: Colors.blue[700],
    iconTheme: const IconThemeData(color: Colors.white),
    flexibleSpace: FlexibleSpaceBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '@${user.username ?? user.nome}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          // Selo de certificação espiritual (dourado)
          if (hasApprovedCertification) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: 'Certificação Espiritual Aprovada',
              child: Icon(
                Icons.verified,
                color: Colors.amber[700],
                size: 24,
              ),
            ),
          ],
          // Selo de preparação para os sinais (mantido)
          if (profile.hasSinaisPreparationSeal == true) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber[600],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '🏆',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ],
      ),
      centerTitle: false,
    ),
  );
}
```

### 3. EnhancedVitrineDisplayView Modifications

**Location**: `lib/views/enhanced_vitrine_display_view.dart`

**Changes Required**:

1. **State Variable Already Exists**:
```dart
bool hasApprovedCertification = false; // Already present
```

2. **Certification Check Method Already Exists**:
```dart
Future<void> _checkCertificationStatus() async {
  // Already implemented - no changes needed
}
```

3. **Update ProfileHeaderSection Component**:

The `ProfileHeaderSection` component already receives `hasVerification` parameter:
```dart
ProfileHeaderSection(
  photoUrl: profileData!.mainPhotoUrl,
  displayName: profileData!.displayName ?? 'Usuário',
  hasVerification: hasApprovedCertification, // Already passing this
  username: profileData!.username,
),
```

**Action**: Verify that `ProfileHeaderSection` component properly displays the badge.

### 4. ProfileHeaderSection Component

**Location**: `lib/components/profile_header_section.dart`

**Expected Implementation**:
```dart
class ProfileHeaderSection extends StatelessWidget {
  final String? photoUrl;
  final String displayName;
  final bool hasVerification;
  final String? username;

  const ProfileHeaderSection({
    Key? key,
    this.photoUrl,
    required this.displayName,
    this.hasVerification = false,
    this.username,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile photo
          _buildProfilePhoto(),
          const SizedBox(height: 16),
          
          // Name with verification badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (hasVerification) ...[
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Certificação Espiritual Aprovada',
                  child: Icon(
                    Icons.verified,
                    color: Colors.amber[700],
                    size: 24,
                  ),
                ),
              ],
            ],
          ),
          
          // Username
          if (username?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              '@$username',
              style: TextStyle(
                fontSize: 16,
                color: Colors.blue[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  // ... rest of the component
}
```

## Data Models

### Certification Request Model (Existing)

**Collection**: `certification_requests`

**Document Structure**:
```json
{
  "userId": "string",
  "status": "approved" | "pending" | "rejected",
  "requestDate": "timestamp",
  "approvalDate": "timestamp",
  "reviewedBy": "string",
  "notes": "string"
}
```

**Indexes Required** (Already exist):
- Composite index: `userId` (Ascending) + `status` (Ascending)

## Error Handling

### Error Scenarios and Handling

1. **Firestore Query Fails**:
   - **Handling**: Catch exception, log error, return `false` (hide badge)
   - **User Impact**: Badge not shown, but profile loads normally
   - **Logging**: Error logged with `EnhancedLogger`

2. **User ID is Null/Empty**:
   - **Handling**: Early return with `false`
   - **User Impact**: Badge not shown
   - **Logging**: No error logged (expected scenario)

3. **Network Timeout**:
   - **Handling**: Firestore timeout caught, return `false`
   - **User Impact**: Badge not shown temporarily
   - **Logging**: Error logged with timeout details

4. **Permission Denied**:
   - **Handling**: Firestore permission error caught, return `false`
   - **User Impact**: Badge not shown
   - **Logging**: Error logged with permission details

### Error Handling Strategy

```dart
try {
  final hasApproved = await CertificationStatusHelper.hasApprovedCertification(userId);
  setState(() {
    hasApprovedCertification = hasApproved;
  });
} catch (e) {
  // Log error but don't show to user
  EnhancedLogger.error('Error checking certification', error: e);
  
  // Fail gracefully - hide badge
  setState(() {
    hasApprovedCertification = false;
  });
}
```

## Testing Strategy

### Unit Tests

1. **CertificationStatusHelper Tests** (Already exist):
   - Test with valid userId and approved certification
   - Test with valid userId and no certification
   - Test with null userId
   - Test with empty userId
   - Test with Firestore error

### Integration Tests

1. **ProfileDisplayView Tests**:
   - Load profile with approved certification → Badge shown
   - Load profile without certification → Badge hidden
   - Load profile with Firestore error → Badge hidden, profile loads
   - Load own profile with certification → Badge shown

2. **EnhancedVitrineDisplayView Tests**:
   - Same scenarios as ProfileDisplayView
   - Verify ProfileHeaderSection receives correct `hasVerification` value

### Manual Testing Checklist

- [ ] View profile of user with approved certification → Badge visible
- [ ] View profile of user without certification → Badge hidden
- [ ] View own profile with certification → Badge visible
- [ ] View profile with network disconnected → Profile loads, badge hidden
- [ ] Approve certification, refresh profile → Badge appears
- [ ] Revoke certification, refresh profile → Badge disappears

## Visual Design

### Badge Specifications

**Icon**: `Icons.verified` (Material Icons)
**Color**: `Colors.amber[700]` (Golden/Amber shade 700)
**Size**: 24px
**Tooltip**: "Certificação Espiritual Aprovada"

### Placement

1. **ProfileDisplayView**: 
   - Location: AppBar title, next to username
   - Alignment: Horizontal row with 8px spacing

2. **EnhancedVitrineDisplayView**:
   - Location: ProfileHeaderSection, next to display name
   - Alignment: Horizontal row with 8px spacing

### Visual Consistency

The badge design matches the existing implementation in `ProfileCompletionView`:
- Same icon (`Icons.verified`)
- Same color (`Colors.amber[700]`)
- Same size (24px)
- Same tooltip message

## Performance Considerations

### Optimization Strategies

1. **Single Query**: Use `.limit(1)` to fetch only one document
2. **Async Loading**: Load certification status asynchronously, don't block profile load
3. **Error Tolerance**: Fail gracefully without impacting profile display
4. **No Caching**: Don't cache across sessions (certification status may change)
5. **Session Caching**: Cache result during single profile view session

### Performance Metrics

- **Query Time**: < 500ms (typical Firestore query)
- **UI Impact**: 0ms (async, non-blocking)
- **Memory**: Minimal (single boolean state variable)

## Future Enhancements

### Search Filter Integration (Future)

**Preparation**:
- Status stored in accessible state variable
- Consistent field naming (`hasApprovedCertification`)
- Documented data structure

**Future Implementation**:
```dart
// Future search filter example
Query query = FirebaseFirestore.instance
    .collection('spiritual_profiles')
    .where('hasApprovedCertification', isEqualTo: true);
```

**Note**: This requires adding `hasApprovedCertification` field to user profiles, which is out of scope for this spec.

## Security Considerations

### Data Access

- **Read Access**: Public (anyone can check certification status)
- **Write Access**: Admin only (certification approval)
- **Firestore Rules**: Already configured correctly

### Privacy

- Certification status is intentionally public
- No sensitive data exposed
- User consents to public display when requesting certification

## Dependencies

### Existing Dependencies (No Changes)

- `cloud_firestore`: Firestore database access
- `get`: State management and navigation
- `CertificationStatusHelper`: Utility for checking certification status
- `EnhancedLogger`: Logging utility

### New Dependencies

None - all required dependencies already exist.

## Migration Plan

### Deployment Steps

1. **Phase 1**: Update `ProfileDisplayView`
   - Add certification check
   - Update AppBar to show badge
   - Test with existing users

2. **Phase 2**: Verify `EnhancedVitrineDisplayView`
   - Confirm `ProfileHeaderSection` displays badge correctly
   - Test with existing users

3. **Phase 3**: Monitor and Validate
   - Monitor logs for errors
   - Validate badge appears for certified users
   - Collect user feedback

### Rollback Plan

If issues occur:
1. Remove badge display code from views
2. Keep certification check logic (no harm)
3. Investigate and fix issues
4. Redeploy with fixes

## Documentation

### Code Comments

Add comments to clarify:
- Purpose of certification check
- Why errors are handled silently
- Badge placement rationale

### User Documentation

Update user-facing documentation:
- Explain certification badge meaning
- How to obtain certification
- Badge visibility (public)

## Success Criteria

1. ✅ Badge appears on profiles of users with approved certification
2. ✅ Badge hidden on profiles without certification
3. ✅ Badge visible to all visitors (not just profile owner)
4. ✅ Profile loads successfully even if certification check fails
5. ✅ Visual consistency with existing badge in ProfileCompletionView
6. ✅ No performance degradation in profile loading
7. ✅ Proper error logging for debugging
