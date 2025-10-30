# 🔍 ANÁLISE: Coleções Faltando no Firestore Rules

## ❌ Erros Reportados
```
ChatView: Erro no stream of stories vistos: [cloud_firestore/permission-denied]
ChatView: Erro no stream de chats: [cloud_firestore/permission-denied]
[EXPLORE_PROFILES] Failed to fetch profiles: [cloud_firestore/permission-denied]
```

## 🔍 Coleções Identificadas no Código

### 1. Stories Vistos
- **Coleção no código**: `stores_visto` (linha 818, 832, 1029, 1035 em stories_repository.dart)
- **Status no firestore.rules**: ❌ NÃO EXISTE
- **Ação**: ADICIONAR regra

### 2. Chats
- **Coleção no código**: `chats` 
- **Status no firestore.rules**: ✅ JÁ EXISTE (linha 87)
- **Regra atual**: `allow read, write: if request.auth != null;`
- **Ação**: VERIFICAR se há subcoleções ou outras variações

### 3. Profiles
- **Coleção no código**: `profiles`
- **Status no firestore.rules**: ✅ JÁ EXISTE (linha 283)
- **Regra atual**: `allow read: if request.auth != null;`
- **Ação**: VERIFICAR se há outras coleções relacionadas

## 📋 PLANO DE CORREÇÃO

### PASSO 1: Adicionar regra para `stores_visto`
```javascript
match /stores_visto/{docId} {
  allow read: if request.auth != null;
  allow create, update: if request.auth != null && 
    request.resource.data.idUser == request.auth.uid;
  allow delete: if request.auth != null && 
    resource.data.idUser == request.auth.uid;
}
```

### PASSO 2: Verificar outras coleções de stories
- Buscar por: `stories_files`, `stories_sinais_rebeca`, etc.

### PASSO 3: Verificar subcoleções de chats
- Buscar por: `chats/{chatId}/messages`, etc.

### PASSO 4: Deploy e teste

## 🎯 PRÓXIMA AÇÃO
Buscar TODAS as coleções usadas no código antes de fazer qualquer alteração.
