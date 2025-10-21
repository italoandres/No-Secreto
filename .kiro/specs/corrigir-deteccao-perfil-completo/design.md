# Design Document

## Overview

Este design resolve o problema de detecção de perfil completo invertendo a ordem de validação no `ProfileCompletionDetector`. Em vez de verificar primeiro o campo `isProfileComplete` (que pode estar desatualizado), o sistema agora valida os dados reais do perfil (tarefas, progresso, campos obrigatórios) e usa essa validação como fonte de verdade. Quando detecta inconsistência, o sistema corrige automaticamente o campo `isProfileComplete` no Firestore.

## Architecture

### Fluxo Atual (Problemático)
```
1. Usuário completa última tarefa
2. ProfileCompletionDetector._validateProfileCompletion() é chamado
3. Verifica isProfileComplete == true? → false → retorna false imediatamente
4. Nunca valida os dados reais
5. Perfil nunca é detectado como completo
```

### Novo Fluxo (Corrigido)
```
1. Usuário completa última tarefa
2. ProfileCompletionDetector._validateProfileCompletion() é chamado
3. Valida dados reais:
   - mainPhotoUrl preenchida?
   - hasBasicInfo == true?
   - hasBiography == true?
   - Todas tarefas obrigatórias == true?
   - completionPercentage >= 1.0?
4. Se todos válidos → perfil está completo
5. Se isProfileComplete != resultado da validação → corrigir no Firestore
6. Retornar resultado da validação real
7. Mostrar VitrineConfirmationView
```

## Components and Interfaces

### 1. ProfileCompletionDetector (Modificado)

**Método: _validateProfileCompletion()**
```dart
static bool _validateProfileCompletion(SpiritualProfileModel profile) {
  // NOVA LÓGICA: Validar dados reais primeiro
  
  // 1. Verificar foto principal
  if (profile.mainPhotoUrl?.isEmpty ?? true) return false;
  
  // 2. Verificar informações básicas
  if (!profile.hasBasicInfo) return false;
  
  // 3. Verificar biografia
  if (!profile.hasBiography) return false;
  
  // 4. Verificar tarefas obrigatórias
  final tasks = profile.completionTasks;
  final requiredTasks = ['photos', 'identity', 'biography', 'preferences'];
  for (final task in requiredTasks) {
    if (tasks[task] != true) return false;
  }
  
  // 5. Verificar percentual
  if ((profile.completionPercentage ?? 0.0) < 1.0) return false;
  
  // RESULTADO: Perfil está completo baseado em dados reais
  final isReallyComplete = true;
  
  // 6. Verificar inconsistência e corrigir
  if (profile.isProfileComplete != isReallyComplete) {
    _fixProfileCompletionInconsistency(profile.id!, isReallyComplete);
  }
  
  return isReallyComplete;
}
```

**Novo Método: _fixProfileCompletionInconsistency()**
```dart
static Future<void> _fixProfileCompletionInconsistency(
  String profileId, 
  bool correctValue
) async {
  EnhancedLogger.warning('Fixing profile completion inconsistency',
    tag: _tag,
    data: {
      'profileId': profileId,
      'correctValue': correctValue,
    }
  );
  
  await SpiritualProfileRepository.updateProfile(profileId, {
    'isProfileComplete': correctValue,
  });
  
  // Invalidar cache para forçar nova verificação
  _statusCache.clear();
  
  EnhancedLogger.success('Profile completion inconsistency fixed',
    tag: _tag,
    data: {'profileId': profileId}
  );
}
```

### 2. ProfileCompletionController (Sem Mudanças Necessárias)

O controller já tem a lógica correta para mostrar a `VitrineConfirmationView` quando o detector retorna `true`. Não precisa de modificações.

### 3. SpiritualProfileRepository (Sem Mudanças Necessárias)

O método `updateProfile()` já existe e funciona corretamente.

## Data Models

### SpiritualProfileModel (Sem Mudanças)

Os campos já existem:
- `isProfileComplete`: bool
- `mainPhotoUrl`: String?
- `hasBasicInfo`: bool
- `hasBiography`: bool
- `completionTasks`: Map<String, bool>
- `completionPercentage`: double?

### ProfileCompletionStatus (Sem Mudanças)

O modelo já funciona corretamente.

## Error Handling

### Cenário 1: Erro ao Atualizar Firestore
```dart
try {
  await SpiritualProfileRepository.updateProfile(profileId, {
    'isProfileComplete': correctValue,
  });
} catch (e, stackTrace) {
  EnhancedLogger.error('Failed to fix profile completion',
    tag: _tag,
    error: e,
    stackTrace: stackTrace,
  );
  // Não propagar erro - a validação real ainda é válida
}
```

### Cenário 2: Perfil Nulo
```dart
if (profile == null) {
  EnhancedLogger.warning('Profile not found', tag: _tag);
  return false;
}
```

### Cenário 3: Dados Incompletos
```dart
// Cada verificação retorna false se dados estão incompletos
// Logs detalhados já existem no código atual
```

## Testing Strategy

### Testes Unitários

1. **Teste: Perfil 100% completo mas isProfileComplete = false**
   - Input: Profile com todas tarefas true, 100% progresso, isProfileComplete = false
   - Expected: _validateProfileCompletion() retorna true
   - Expected: _fixProfileCompletionInconsistency() é chamado
   - Expected: Firestore é atualizado com isProfileComplete = true

2. **Teste: Perfil incompleto mas isProfileComplete = true**
   - Input: Profile com tarefas faltando, isProfileComplete = true
   - Expected: _validateProfileCompletion() retorna false
   - Expected: _fixProfileCompletionInconsistency() é chamado
   - Expected: Firestore é atualizado com isProfileComplete = false

3. **Teste: Perfil completo e isProfileComplete = true (consistente)**
   - Input: Profile com todas tarefas true, 100% progresso, isProfileComplete = true
   - Expected: _validateProfileCompletion() retorna true
   - Expected: _fixProfileCompletionInconsistency() NÃO é chamado
   - Expected: Nenhuma atualização no Firestore

### Testes de Integração

1. **Teste: Completar última tarefa e ver confirmação**
   - Ação: Completar tarefa de preferências (última tarefa)
   - Expected: VitrineConfirmationView aparece em até 1 segundo
   - Expected: Campo isProfileComplete é atualizado para true
   - Expected: hasBeenShown é marcado como true

2. **Teste: Perfil já completo não mostra confirmação novamente**
   - Ação: Abrir ProfileCompletionView com perfil já completo
   - Expected: VitrineConfirmationView NÃO aparece
   - Expected: Seção de perfil completo é mostrada

### Testes Manuais

1. **Cenário do Usuário Atual**
   - Perfil: flzsmpZNRvAZ9UC9Si5U
   - Estado: 100% progresso, isProfileComplete = false
   - Ação: Abrir ProfileCompletionView
   - Expected: Correção automática + VitrineConfirmationView

## Performance Considerations

### Cache Invalidation
- Quando `_fixProfileCompletionInconsistency()` é chamado, o cache é limpo
- Isso força uma nova verificação na próxima consulta
- Evita usar dados desatualizados

### Evitar Loops Infinitos
- A correção só acontece se houver inconsistência real
- Após correção, o valor fica consistente
- Próximas verificações não acionam correção

### Async Operations
- A correção é assíncrona mas não bloqueia a validação
- O resultado da validação real é retornado imediatamente
- A atualização do Firestore acontece em background

## Security Considerations

### Firestore Rules
As regras já permitem que o usuário atualize seu próprio perfil:
```javascript
match /spiritual_profiles/{profileId} {
  allow update: if request.auth != null && 
                request.resource.data.userId == request.auth.uid;
}
```

### Validação de Dados
- Todas as verificações são feitas no lado do cliente
- O Firestore valida que o usuário só pode atualizar seu próprio perfil
- Não há risco de segurança adicional

## Migration Strategy

### Fase 1: Implementar Nova Lógica
- Modificar `_validateProfileCompletion()` no `ProfileCompletionDetector`
- Adicionar `_fixProfileCompletionInconsistency()`
- Testar com perfil problemático atual

### Fase 2: Monitorar Logs
- Verificar quantos perfis têm inconsistências
- Monitorar se as correções estão funcionando
- Identificar padrões de inconsistência

### Fase 3: Correção em Massa (Opcional)
- Se houver muitos perfis inconsistentes
- Criar script para corrigir todos de uma vez
- Executar fora do horário de pico

## Rollback Plan

Se a mudança causar problemas:

1. **Reverter Código**
   - Restaurar versão anterior do `ProfileCompletionDetector`
   - Deploy imediato

2. **Limpar Cache**
   - Reiniciar app para limpar cache local
   - Usuários verão comportamento anterior

3. **Sem Impacto em Dados**
   - As correções feitas no Firestore são válidas
   - Não precisa reverter dados
