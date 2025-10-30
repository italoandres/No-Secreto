# Design Document

## Overview

O sistema atual tem uma falha crítica na validação do sexo do usuário durante o login. O problema está no método `_syncUserSexo()` do `LoginRepository`, que sobrescreve o valor correto do Firestore com o valor incorreto do SharedPreferences. A solução é inverter essa lógica: o Firestore deve ser a fonte de verdade e o SharedPreferences deve ser atualizado quando necessário.

## Architecture

### Current Flow (Problematic)
```
Login → TokenUsuario (SharedPreferences) → Sobrescreve Firestore → Inconsistência
```

### New Flow (Corrected)
```
Login → Firestore (Source of Truth) → Atualiza TokenUsuario → Consistência
```

## Components and Interfaces

### 1. LoginRepository Modifications

**Current problematic method:**
```dart
static Future<void> _syncUserSexo() async {
  // PROBLEMA: Pega do TokenUsuario e sobrescreve Firestore
  final sexoFromToken = TokenUsuario().sexo;
  await FirebaseFirestore.instance
      .collection('usuarios')
      .doc(currentUser.uid)
      .update({'sexo': sexoFromToken.name});
}
```

**New corrected method:**
```dart
static Future<void> _validateAndSyncUserSexo() async {
  // SOLUÇÃO: Pega do Firestore e atualiza TokenUsuario se necessário
  final userDoc = await FirebaseFirestore.instance
      .collection('usuarios')
      .doc(currentUser.uid)
      .get();
      
  if (userDoc.exists) {
    final firestoreSexo = userDoc.data()?['sexo'];
    if (firestoreSexo != null) {
      final sexoEnum = UserSexo.values.firstWhere(
        (e) => e.name == firestoreSexo,
        orElse: () => UserSexo.none
      );
      
      // Atualizar TokenUsuario com valor do Firestore
      TokenUsuario().sexo = sexoEnum;
    }
  }
}
```

### 2. UsuarioRepository Modifications

**Remove the problematic correction logic:**
```dart
// REMOVER: Esta lógica está invertida
if (sexoFromFirestore == UserSexo.none && sexoFromToken != UserSexo.none) {
  // Não deve corrigir Firestore baseado no TokenUsuario
}
```

**Add proper validation logic:**
```dart
// ADICIONAR: Validação correta
if (sexoFromFirestore != UserSexo.none) {
  // Atualizar TokenUsuario se diferente
  if (TokenUsuario().sexo != sexoFromFirestore) {
    TokenUsuario().sexo = sexoFromFirestore;
  }
}
```

### 3. Debug Enhancement

**Enhanced debug method:**
```dart
static Future<void> printCurrentUserState() async {
  // Mostrar ambos os valores ANTES da correção
  final tokenSexo = TokenUsuario().sexo;
  
  final userDoc = await FirebaseFirestore.instance
      .collection('usuarios')
      .doc(currentUser.uid)
      .get();
      
  final firestoreSexo = userDoc.data()?['sexo'];
  
  print('ANTES DA CORREÇÃO:');
  print('TokenUsuario Sexo: $tokenSexo');
  print('Firestore Sexo: $firestoreSexo');
  
  // Aplicar correção
  await _validateAndSyncUserSexo();
  
  print('APÓS CORREÇÃO:');
  print('TokenUsuario Sexo: ${TokenUsuario().sexo}');
}
```

## Data Models

### UserSexo Enum
```dart
enum UserSexo {
  none,
  masculino,
  feminino
}
```

### Data Flow Priority
1. **Firestore** = Source of Truth (highest priority)
2. **TokenUsuario** = Local cache (updated from Firestore)
3. **UI Logic** = Based on TokenUsuario value

## Error Handling

### Scenario 1: Firestore has valid sexo, TokenUsuario is different
- **Action**: Update TokenUsuario with Firestore value
- **Log**: "🔄 Sincronizando sexo do Firestore: [sexo]"

### Scenario 2: Firestore has 'none', TokenUsuario has valid sexo
- **Action**: This indicates a new user completing onboarding
- **Log**: "✅ Novo usuário - mantendo sexo do onboarding: [sexo]"

### Scenario 3: Both have 'none'
- **Action**: User needs to complete profile
- **Log**: "⚠️ Usuário precisa completar perfil - sexo não definido"

### Scenario 4: Firestore read fails
- **Action**: Keep current TokenUsuario value, log error
- **Log**: "❌ Erro ao ler Firestore - mantendo valor local: [sexo]"

## Testing Strategy

### Unit Tests
1. Test `_validateAndSyncUserSexo()` with different scenarios
2. Test TokenUsuario update logic
3. Test error handling for Firestore failures

### Integration Tests
1. Test complete login flow with existing users
2. Test new user registration flow
3. Test logout/login cycle maintains correct sexo

### Manual Testing Scenarios
1. **Existing female user**: Login should show "👰‍♀️" button
2. **Existing male user**: Login should show "🤵" button
3. **New user**: Onboarding → Login should maintain selected sexo
4. **Data corruption**: Debug tool should fix inconsistencies

## Implementation Steps

### Phase 1: Fix Core Logic
1. Replace `_syncUserSexo()` with `_validateAndSyncUserSexo()`
2. Update method to read from Firestore first
3. Update TokenUsuario based on Firestore value

### Phase 2: Remove Problematic Code
1. Remove inverse logic from UsuarioRepository
2. Clean up any other places that update Firestore based on TokenUsuario

### Phase 3: Enhance Debug Tools
1. Update debug method to show before/after values
2. Add automatic fix capability
3. Add validation for data consistency

### Phase 4: Testing & Validation
1. Test with existing problematic accounts
2. Verify new user registration still works
3. Confirm UI shows correct buttons for each sexo