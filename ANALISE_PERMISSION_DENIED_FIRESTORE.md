# 🔍 Análise: Permission Denied no Firestore

## Erros Reportados

```
❌ Erro no stream de sistema: [cloud_firestore/permission-denied]
❌ Erro no stream de stories: [cloud_firestore/permission-denied]
❌ [UNIFIED_CONTROLLER] Erro no stream de interesse: [cloud_firestore/permission-denied]
```

## Problema Identificado

O arquivo `firestore.rules` tem uma **regra catch-all no final**:

```javascript
match /{document=**} {
  allow read, write: if request.auth != null;
}
```

**MAS** as regras específicas ANTES dela podem estar bloqueando o acesso!

## Regras Problemáticas

### 1. Sistema (linha 127)
```javascript
match /sistema/{docId} {
  allow read: if request.auth != null;
  allow write: if request.auth != null;
}
```
✅ **Parece OK**, mas pode ter problema com subcoleções

### 2. Stories (linha 95)
```javascript
match /stories/{storyId} {
  allow read: if request.auth != null;
  allow create: if request.auth != null && 
    request.auth.uid == request.resource.data.userId;
  allow update, delete: if request.auth != null && 
    request.auth.uid == resource.data.userId;
}
```
✅ **Leitura OK**, mas subcoleções podem estar bloqueadas

### 3. Interests (linha 447)
```javascript
match /interests/{interestId} {
  allow read: if request.auth != null;
  allow create: if request.auth != null && 
    request.auth.uid == request.resource.data.fromUserId &&
    request.resource.data.keys().hasAll(['fromUserId', 'toUserId', 'timestamp', 'status']);
  allow update: if request.auth != null && 
    (request.auth.uid == resource.data.fromUserId || 
     request.auth.uid == resource.data.toUserId);
}
```
✅ **Leitura OK**, mas pode ter problema com queries

### 4. Interest Notifications (linha 157)
```javascript
match /interest_notifications/{notificationId} {
  allow read: if request.auth != null;
  allow create: if request.auth != null;
  allow update: if request.auth != null && 
    (request.auth.uid == resource.data.fromUserId || 
     request.auth.uid == resource.data.toUserId);
  allow delete: if request.auth != null && 
    request.auth.uid == resource.data.toUserId;
}
```
✅ **Leitura OK**

## Possíveis Causas

### Causa 1: Subcoleções Não Mapeadas
Se o código está tentando acessar:
- `sistema/{docId}/subcollection/{subDocId}`
- `stories/{storyId}/subcollection/{subDocId}`

As regras específicas NÃO cobrem subcoleções!

### Causa 2: Queries com Filtros
Queries com `.where()` podem falhar se a regra não permite acesso a TODOS os documentos da coleção.

### Causa 3: Ordem das Regras
Regras específicas têm precedência sobre a catch-all. Se uma regra específica nega, a catch-all não é avaliada.

## Solução

### Opção 1: Usar `{document=**}` nas Regras Específicas
```javascript
// ANTES (só cobre documentos diretos)
match /sistema/{docId} {
  allow read: if request.auth != null;
}

// DEPOIS (cobre documentos E subcoleções)
match /sistema/{document=**} {
  allow read: if request.auth != null;
}
```

### Opção 2: Simplificar Regras
Remover regras específicas que estão duplicando a catch-all:

```javascript
// Se a catch-all já permite tudo, não precisa de regras específicas
// EXCETO para regras mais restritivas (como admin-only)
```

### Opção 3: Garantir Catch-All Funciona
Mover regras muito restritivas para DEPOIS da catch-all (não recomendado).

## Recomendação

**Adicionar `{document=**}` nas regras que podem ter subcoleções:**

1. `sistema/{document=**}` - Para cobrir subcoleções
2. `stories/{document=**}` - Para cobrir stories_files, etc.
3. `interests/{document=**}` - Para cobrir interest_notifications

Isso garante que subcoleções também sejam acessíveis.
