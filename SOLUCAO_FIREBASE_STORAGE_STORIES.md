# 🔧 Solução: Firebase Storage - Upload de Stories

## Problema Identificado

❌ Erro ao fazer upload de imagens para stories:
```
Firebase Storage: An unknown error occurred (storage/unknown)
```

## Causa

O Firebase Storage está com **regras restritivas** ou **não configurado** no projeto novo.

## Solução Passo a Passo

### PASSO 1: Verificar se Storage está Habilitado

1. Acesse o Firebase Console: https://console.firebase.google.com
2. Selecione seu projeto: **deusepaimovement**
3. No menu lateral, clique em **Storage**
4. Se aparecer "Get Started", clique para habilitar
5. Escolha localização: **southamerica-east1** (São Paulo)

### PASSO 2: Configurar Regras do Storage

1. No Firebase Console, vá em **Storage** → **Rules**
2. Substitua as regras atuais por estas:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Regras para stories
    match /stories_files/{fileName} {
      // Permitir leitura para todos autenticados
      allow read: if request.auth != null;
      
      // Permitir upload apenas do próprio usuário
      allow write: if request.auth != null &&
                      fileName.matches('.*' + request.auth.uid + '.*');
    }
    
    // Regras para fotos de perfil
    match /profile_photos/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
                      fileName.matches('.*' + request.auth.uid + '.*');
    }
    
    // Regras para outras pastas (catch-all)
    match /{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

3. Clique em **Publish** para aplicar

### PASSO 3: Criar Arquivo storage.rules Local

Crie o arquivo `storage.rules` na raiz do projeto:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /stories_files/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
                      fileName.matches('.*' + request.auth.uid + '.*');
    }
    
    match /profile_photos/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
                      fileName.matches('.*' + request.auth.uid + '.*');
    }
    
    match /{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

### PASSO 4: Fazer Deploy das Regras

Execute no terminal:

```powershell
firebase deploy --only storage
```

### PASSO 5: Verificar Configuração do Projeto

Verifique se o app está usando o projeto correto:

1. Abra `firebase_options.dart` (ou `lib/firebase_options.dart`)
2. Confirme que o `storageBucket` está correto
3. Deve ser algo como: `deusepaimovement.appspot.com`

### PASSO 6: Testar Upload

1. Abra o app
2. Tente publicar um story
3. Verifique os logs - não deve ter mais erro `storage/unknown`

## Verificação Rápida

### Console do Firebase

1. Vá em **Storage** → **Files**
2. Após upload bem-sucedido, você deve ver:
   - Pasta `stories_files/`
   - Arquivo com nome: `JyFHMWQul7P9Wj1kOHwvRwKJUZ62_[timestamp].png`

### Logs do App

Deve aparecer:
```
DEBUG REPO: Upload concluído com sucesso
DEBUG REPO: URL da imagem: https://...
```

## Troubleshooting

### Se ainda der erro após PASSO 2:

**Opção A: Regras Mais Permissivas (Temporário)**

Use regras mais abertas para testar:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

**Opção B: Verificar Autenticação**

Confirme que o usuário está autenticado:
- Logs devem mostrar: `DEBUG REPO: Está autenticado: true`
- Se false, o problema é de autenticação, não Storage

**Opção C: Verificar Quota**

1. Firebase Console → **Storage** → **Usage**
2. Confirme que tem espaço disponível
3. Plano Spark: 5GB grátis

## Resumo dos Comandos

```powershell
# 1. Fazer deploy das regras do Storage
firebase deploy --only storage

# 2. Verificar projeto ativo
firebase projects:list

# 3. Selecionar projeto correto (se necessário)
firebase use deusepaimovement
```

## Status Final

Após seguir todos os passos:

✅ Storage habilitado
✅ Regras configuradas
✅ Deploy realizado
✅ Upload funcionando

Pronto para publicar stories! 🎯
