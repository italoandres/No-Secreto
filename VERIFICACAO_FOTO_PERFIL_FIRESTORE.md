# Verificação: Foto de Perfil no Firestore

## Problema Atual
A foto não está aparecendo no Chrome, mas pode ser por:
1. ❌ Erro de CORS no navegador
2. ❌ Dados não sincronizados no Firestore
3. ❌ Cache do navegador

## Soluções Implementadas

### 1. Tratamento Especial para Web (Chrome)
**Arquivo**: `lib/components/profile_header_section.dart`

```dart
// Usa Image.network para web (evita problemas de CORS)
// Usa CachedNetworkImage para mobile (melhor performance)
kIsWeb
  ? Image.network(photoUrl!, ...)
  : CachedNetworkImage(imageUrl: photoUrl!, ...)
```

### 2. Sincronização Direta no Firestore
**Arquivo**: `lib/controllers/profile_photos_task_controller.dart`

O controller agora atualiza DIRETAMENTE ambas as collections:
- `spiritual_profiles.mainPhotoUrl`
- `usuarios.imgUrl`

## Como Verificar no Firestore

### Passo 1: Verificar Collection `usuarios`
1. Abra o Firebase Console
2. Vá em Firestore Database
3. Abra a collection `usuarios`
4. Procure o documento com ID: `qZrIbFibaQgyZSYCXTJHzxE1sVv1`
5. Verifique o campo `imgUrl`:
   ```
   imgUrl: "https://firebasestorage.googleapis.com/v0/b/app-no-secreto-com-o-pai.firebasestorage.app/o/spiritual_profiles%2FqZrIbFibaQgyZSYCXTJHzxE1sVv1%2Fmain_photo_1760765892122.jpg?alt=media&token=f857a941-25df-4cb3-ae2b-29fdec619f15"
   ```

### Passo 2: Verificar Collection `spiritual_profiles`
1. Abra a collection `spiritual_profiles`
2. Procure o documento com `userId: qZrIbFibaQgyZSYCXTJHzxE1sVv1`
3. Verifique o campo `mainPhotoUrl`:
   ```
   mainPhotoUrl: "https://firebasestorage.googleapis.com/v0/b/..."
   ```

### Passo 3: Verificar Timestamps
Ambos os documentos devem ter:
```
lastSyncAt: [timestamp recente]
```

## Teste no Chrome

### Opção 1: Limpar Cache e Recarregar
1. Abra DevTools (F12)
2. Clique com botão direito no botão de reload
3. Selecione "Empty Cache and Hard Reload"
4. Aguarde a página recarregar

### Opção 2: Modo Anônimo
1. Abra uma janela anônima (Ctrl+Shift+N)
2. Acesse o app
3. Faça login
4. Verifique se a foto aparece

### Opção 3: Verificar URL da Imagem Diretamente
1. Copie a URL da imagem do Firestore
2. Cole em uma nova aba do navegador
3. Se a imagem carregar, o problema é no componente
4. Se não carregar, o problema é CORS ou permissões do Storage

## Verificar Permissões do Firebase Storage

### Regras Necessárias
Arquivo: `storage.rules`

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /spiritual_profiles/{userId}/{allPaths=**} {
      // Permitir leitura pública
      allow read: if true;
      
      // Permitir escrita apenas para o próprio usuário
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Logs para Monitorar

Procure por estes logs no console:

### Sucesso:
```
[PHOTOS_TASK] Updating main photo
  - profileId: flzsmpZNRvAZ9UC9Si5U
  - userId: qZrIbFibaQgyZSYCXTJHzxE1sVv1
  - imageUrl: https://...

[PHOTOS_TASK] Profile image synced to usuarios collection
  - userId: qZrIbFibaQgyZSYCXTJHzxE1sVv1

[PHOTOS_TASK] Main photo updated successfully
```

### Erro:
```
❌ Error loading profile image (Web): ...
📸 Image URL: https://...
```

## Solução Temporária: Forçar Atualização Manual

Se a foto não aparecer, você pode forçar a sincronização:

1. Abra o console do navegador (F12)
2. Execute este código:

```javascript
// Verificar dados no Firestore
firebase.firestore().collection('usuarios')
  .doc('qZrIbFibaQgyZSYCXTJHzxE1sVv1')
  .get()
  .then(doc => {
    console.log('Usuario imgUrl:', doc.data().imgUrl);
  });

firebase.firestore().collection('spiritual_profiles')
  .where('userId', '==', 'qZrIbFibaQgyZSYCXTJHzxE1sVv1')
  .get()
  .then(snapshot => {
    snapshot.forEach(doc => {
      console.log('Profile mainPhotoUrl:', doc.data().mainPhotoUrl);
    });
  });
```

## Próximos Passos

### Se a foto NÃO está no Firestore:
1. ✅ Faça upload da foto novamente
2. ✅ Verifique os logs no console
3. ✅ Confirme que não há erros de permissão

### Se a foto ESTÁ no Firestore mas não aparece:
1. ✅ Problema é CORS ou cache do navegador
2. ✅ Teste em modo anônimo
3. ✅ Teste em outro navegador (Firefox, Edge)
4. ✅ Teste no mobile (se disponível)

### Se a foto aparece em outros lugares mas não na vitrine:
1. ✅ Problema é no componente ProfileHeaderSection
2. ✅ Verifique os logs de erro no console
3. ✅ Verifique se `photoUrl` está sendo passado corretamente

## Teste Rápido

Execute este teste para verificar tudo:

1. **Upload**: Faça upload de uma nova foto
2. **Aguarde**: Espere a mensagem "Foto Atualizada!"
3. **Verifique Firestore**: Confirme que ambas collections foram atualizadas
4. **Limpe Cache**: Faça hard reload (Ctrl+Shift+R)
5. **Verifique Vitrine**: Acesse a vitrine e veja se aparece

## Diferença Web vs Mobile

### Web (Chrome):
- ✅ Usa `Image.network` (sem cache)
- ✅ Melhor compatibilidade com CORS
- ❌ Pode ter problemas com Storage Rules

### Mobile:
- ✅ Usa `CachedNetworkImage` (com cache)
- ✅ Melhor performance
- ✅ Sem problemas de CORS

## Data da Implementação
18 de Outubro de 2025
