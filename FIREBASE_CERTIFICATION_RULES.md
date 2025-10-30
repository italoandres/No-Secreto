# Regras de Segurança do Firebase - Certificação Espiritual

## 📋 Firestore Rules

Adicione estas regras ao seu arquivo `firestore.rules`:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Função auxiliar para verificar se é admin
    function isAdmin() {
      return request.auth != null && 
             (request.auth.token.email == 'sinais.app@gmail.com' ||
              request.auth.token.email == 'admin@sinais.app');
    }
    
    // Função auxiliar para verificar se é o próprio usuário
    function isOwner(userId) {
      return request.auth != null && request.auth.uid == userId;
    }
    
    // Regras para spiritual_certifications
    match /spiritual_certifications/{certificationId} {
      // Leitura: usuário pode ver suas próprias solicitações, admin vê todas
      allow read: if isOwner(resource.data.userId) || isAdmin();
      
      // Criação: apenas usuário autenticado pode criar sua própria solicitação
      allow create: if request.auth != null && 
                       request.resource.data.userId == request.auth.uid &&
                       request.resource.data.status == 'pending';
      
      // Atualização: apenas admin pode atualizar status
      allow update: if isAdmin() &&
                       // Admin só pode mudar status e campos relacionados
                       request.resource.data.userId == resource.data.userId &&
                       request.resource.data.proofFileUrl == resource.data.proofFileUrl;
      
      // Deleção: apenas admin pode deletar
      allow delete: if isAdmin();
    }
    
    // Regras para atualizar campo isSpiritualCertified no perfil do usuário
    match /usuarios/{userId} {
      // Admin pode atualizar o campo de certificação
      allow update: if isAdmin() &&
                       // Apenas permitir mudança no campo isSpiritualCertified
                       request.resource.data.diff(resource.data).affectedKeys()
                         .hasOnly(['isSpiritualCertified', 'updatedAt']);
    }
  }
}
```

## 🗄️ Storage Rules

Adicione estas regras ao seu arquivo `storage.rules`:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // Função auxiliar para verificar se é admin
    function isAdmin() {
      return request.auth != null && 
             (request.auth.token.email == 'sinais.app@gmail.com' ||
              request.auth.token.email == 'admin@sinais.app');
    }
    
    // Regras para certifications
    match /certifications/{userId}/{fileName} {
      // Leitura: usuário pode ver seus próprios arquivos, admin vê todos
      allow read: if request.auth != null && 
                     (request.auth.uid == userId || isAdmin());
      
      // Escrita: apenas o próprio usuário pode fazer upload
      allow write: if request.auth != null && 
                      request.auth.uid == userId &&
                      // Validar tipo de arquivo
                      (request.resource.contentType.matches('image/.*') ||
                       request.resource.contentType == 'application/pdf') &&
                      // Validar tamanho (máx 5MB)
                      request.resource.size < 5 * 1024 * 1024;
      
      // Deleção: usuário pode deletar seus próprios arquivos, admin pode deletar qualquer um
      allow delete: if request.auth != null && 
                       (request.auth.uid == userId || isAdmin());
    }
  }
}
```

## 🔐 Índices do Firestore

Adicione estes índices ao seu arquivo `firestore.indexes.json`:

```json
{
  "indexes": [
    {
      "collectionGroup": "spiritual_certifications",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "requestedAt",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "spiritual_certifications",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "userId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "requestedAt",
          "order": "DESCENDING"
        }
      ]
    }
  ],
  "fieldOverrides": []
}
```

## 📝 Como Aplicar as Regras

### Opção 1: Firebase Console (Recomendado)

1. Acesse o [Firebase Console](https://console.firebase.google.com/)
2. Selecione seu projeto
3. Vá em **Firestore Database** > **Regras**
4. Cole as regras do Firestore
5. Clique em **Publicar**
6. Vá em **Storage** > **Regras**
7. Cole as regras do Storage
8. Clique em **Publicar**

### Opção 2: Firebase CLI

```bash
# Instalar Firebase CLI (se ainda não tiver)
npm install -g firebase-tools

# Fazer login
firebase login

# Inicializar projeto (se ainda não tiver)
firebase init

# Deploy das regras
firebase deploy --only firestore:rules
firebase deploy --only storage:rules

# Deploy dos índices
firebase deploy --only firestore:indexes
```

## ✅ Testar as Regras

### Teste 1: Usuário pode criar sua própria solicitação
```javascript
// Deve PERMITIR
const userId = auth.currentUser.uid;
await firestore.collection('spiritual_certifications').add({
  userId: userId,
  userName: 'João Silva',
  userEmail: 'joao@example.com',
  purchaseEmail: 'joao@example.com',
  proofFileUrl: 'https://...',
  proofFileName: 'comprovante.pdf',
  status: 'pending',
  requestedAt: new Date(),
});
```

### Teste 2: Usuário NÃO pode criar solicitação para outro usuário
```javascript
// Deve NEGAR
await firestore.collection('spiritual_certifications').add({
  userId: 'outro-usuario-id', // ❌ Diferente do auth.currentUser.uid
  // ...
});
```

### Teste 3: Admin pode atualizar status
```javascript
// Deve PERMITIR (se for admin)
await firestore.collection('spiritual_certifications').doc(certId).update({
  status: 'approved',
  processedAt: new Date(),
});
```

### Teste 4: Usuário NÃO pode atualizar status
```javascript
// Deve NEGAR (se não for admin)
await firestore.collection('spiritual_certifications').doc(certId).update({
  status: 'approved', // ❌ Apenas admin pode mudar status
});
```

### Teste 5: Upload de arquivo
```javascript
// Deve PERMITIR
const userId = auth.currentUser.uid;
const storageRef = storage.ref(`certifications/${userId}/comprovante.pdf`);
await storageRef.put(file); // Arquivo < 5MB e tipo válido
```

### Teste 6: Upload de arquivo muito grande
```javascript
// Deve NEGAR
const file = new File([...], 'grande.pdf', { type: 'application/pdf' });
// Se file.size > 5MB ❌
await storageRef.put(file);
```

## 🔍 Monitoramento

Após aplicar as regras, monitore no Firebase Console:

1. **Firestore** > **Uso** - Verificar operações negadas
2. **Storage** > **Uso** - Verificar uploads negados
3. **Autenticação** > **Usuários** - Verificar emails admin

## ⚠️ Importante

- **Backup**: Sempre faça backup das regras atuais antes de modificar
- **Teste**: Teste as regras em ambiente de desenvolvimento primeiro
- **Admin**: Mantenha a lista de emails admin atualizada
- **Segurança**: Nunca exponha credenciais admin no código cliente

## 📚 Documentação Oficial

- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Storage Security Rules](https://firebase.google.com/docs/storage/security/start)
- [Firestore Indexes](https://firebase.google.com/docs/firestore/query-data/indexing)
