# Correção: Sincronização da Foto de Perfil

## Problema Identificado
A foto de perfil estava sendo carregada no `ProfilePhotosTaskView` e salva na collection `spiritual_profiles`, mas não estava aparecendo:
- ❌ Nos chats (principal e sinais)
- ❌ Nos comentários dos stories
- ❌ Para visitantes do perfil
- ❌ No "Nosso Propósito"

## Causa Raiz
A foto estava sendo salva apenas na collection `spiritual_profiles` (campo `mainPhotoUrl`), mas os chats, stories e comentários buscam a foto na collection `usuarios` (campo `imgUrl`). A sincronização entre as duas collections não estava funcionando de forma confiável.

## Solução Implementada

### Arquivo Modificado
`lib/controllers/profile_photos_task_controller.dart`

### Mudanças no Método `updateMainPhoto()`

#### Antes:
```dart
// Apenas tentava sincronizar usando o ProfileDataSynchronizer
await SpiritualProfileRepository.updateProfile(profile.id!, {
  'mainPhotoUrl': imageUrl,
});

if (profile.userId != null) {
  await ProfileDataSynchronizer.updateProfileImage(profile.userId!, imageUrl);
}
```

#### Depois:
```dart
// 1. Atualizar no perfil espiritual
await SpiritualProfileRepository.updateProfile(profile.id!, {
  'mainPhotoUrl': imageUrl,
  'lastSyncAt': FieldValue.serverTimestamp(),
});

// 2. Atualizar DIRETAMENTE na collection usuarios (CRÍTICO)
if (profile.userId != null) {
  try {
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(profile.userId!)
        .update({
      'imgUrl': imageUrl,
      'lastSyncAt': FieldValue.serverTimestamp(),
    });
    
    EnhancedLogger.success('Profile image synced to usuarios collection');
  } catch (e) {
    // Fallback para método alternativo
    await ProfileDataSynchronizer.updateProfileImage(profile.userId!, imageUrl);
  }
}

// 3. Feedback ao usuário
Get.snackbar(
  'Foto Atualizada!',
  'Sua foto de perfil foi atualizada e já está visível para outros usuários.',
  ...
);
```

## Benefícios da Solução

### 1. Sincronização Direta e Confiável
- ✅ Atualiza DIRETAMENTE a collection `usuarios` sem depender de queries
- ✅ Usa o `userId` do perfil para atualizar o documento correto
- ✅ Adiciona timestamp de sincronização para rastreamento

### 2. Fallback Robusto
- ✅ Se a atualização direta falhar, tenta o método alternativo
- ✅ Logs detalhados para debugging
- ✅ Tratamento de erros apropriado

### 3. Feedback ao Usuário
- ✅ Mensagem de sucesso clara
- ✅ Confirma que a foto está visível para outros
- ✅ Melhora a experiência do usuário

## Onde a Foto Agora Aparece

### Collection `spiritual_profiles`
- Campo: `mainPhotoUrl`
- Uso: Vitrine de propósito, perfil espiritual

### Collection `usuarios`
- Campo: `imgUrl`
- Uso: 
  - ✅ Chats (principal e sinais)
  - ✅ Comentários dos stories
  - ✅ "Nosso Propósito"
  - ✅ Qualquer lugar que use UsuarioModel

## Fluxo de Atualização

```
Usuário faz upload da foto
  ↓
EnhancedImagePicker processa e faz upload
  ↓
Chama updateMainPhoto(imageUrl)
  ↓
┌─────────────────────────────────────┐
│ 1. Atualiza spiritual_profiles      │
│    - mainPhotoUrl = imageUrl        │
│    - lastSyncAt = now               │
└─────────────────────────────────────┘
  ↓
┌─────────────────────────────────────┐
│ 2. Atualiza usuarios (DIRETO)      │
│    - imgUrl = imageUrl              │
│    - lastSyncAt = now               │
└─────────────────────────────────────┘
  ↓
┌─────────────────────────────────────┐
│ 3. Atualiza modelo local            │
│    - profile.mainPhotoUrl = imageUrl│
└─────────────────────────────────────┘
  ↓
┌─────────────────────────────────────┐
│ 4. Marca tarefa como completa       │
└─────────────────────────────────────┘
  ↓
┌─────────────────────────────────────┐
│ 5. Mostra feedback ao usuário       │
│    "Foto atualizada e visível!"     │
└─────────────────────────────────────┘
```

## Testes Recomendados

### Teste 1: Upload de Foto
1. ✅ Fazer upload de uma foto no ProfilePhotosTaskView
2. ✅ Verificar se aparece mensagem de sucesso
3. ✅ Verificar no Firestore se `usuarios.imgUrl` foi atualizado
4. ✅ Verificar no Firestore se `spiritual_profiles.mainPhotoUrl` foi atualizado

### Teste 2: Visibilidade em Chats
1. ✅ Abrir um chat com outro usuário
2. ✅ Verificar se a foto aparece no header do chat
3. ✅ Enviar uma mensagem e verificar se a foto aparece ao lado

### Teste 3: Visibilidade em Stories
1. ✅ Comentar em um story
2. ✅ Verificar se a foto aparece ao lado do comentário

### Teste 4: Visibilidade para Visitantes
1. ✅ Acessar o perfil como visitante
2. ✅ Verificar se a foto aparece na vitrine
3. ✅ Verificar se a foto aparece no "Nosso Propósito"

### Teste 5: Sincronização de Timestamps
1. ✅ Verificar se `lastSyncAt` foi atualizado em ambas collections
2. ✅ Verificar se os timestamps são idênticos ou muito próximos

## Logs para Monitoramento

O sistema agora gera logs detalhados:

```
[PHOTOS_TASK] Updating main photo
  - profileId: xxx
  - userId: yyy
  - imageUrl: https://...

[PHOTOS_TASK] Profile image synced to usuarios collection
  - userId: yyy

[PHOTOS_TASK] Main photo updated successfully
```

## Compatibilidade

- ✅ Flutter SDK: Compatível com versão atual do projeto
- ✅ Firebase: Usa APIs padrão do Firestore
- ✅ Não quebra funcionalidades existentes
- ✅ Mantém compatibilidade com ProfileDataSynchronizer

## Impacto

- ✅ Resolve problema de foto não aparecer em chats/stories
- ✅ Melhora confiabilidade da sincronização
- ✅ Adiciona feedback claro ao usuário
- ✅ Facilita debugging com logs detalhados
- ✅ Não afeta performance (operações são rápidas)

## Data da Implementação
18 de Outubro de 2025
