# 🔥 Firebase Indexes Setup Guide

## ⚠️ IMPORTANTE: Índices Necessários para Stories

Os logs mostram que precisamos criar índices específicos para as consultas de likes e comentários funcionarem.

## 📋 Índices que Precisam Ser Criados

### 1. story_likes Index
**Collection Group:** `story_likes`
**Fields:**
- `storyId` (Ascending)
- `dataCadastro` (Descending) 
- `__name__` (Descending)

### 2. story_comments Index  
**Collection Group:** `story_comments`
**Fields:**
- `isBlocked` (Ascending)
- `parentCommentId` (Ascending)
- `storyId` (Ascending)
- `dataCadastro` (Ascending)
- `__name__` (Ascending)

## 🚀 Como Aplicar os Índices

### Opção 1: Firebase Console (Recomendado)
1. Acesse: https://console.firebase.google.com/
2. Selecione seu projeto: `app-no-secreto-com-o-pai`
3. Vá em **Firestore Database** → **Indexes**
4. Clique em **Create Index**
5. Configure cada índice conforme especificado acima

### Opção 2: Links Diretos dos Erros
Use os links que aparecem nos logs de erro:

**Para story_likes:**
```
https://console.firebase.google.com/v1/r/project/app-no-secreto-com-o-pai/firestore/indexes?create_composite=Clxwcm9qZWN0cy9hcHAtbm8tc2VjcmV0by1jb20tby1wYWkvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL3N0b3J5X2xpa2VzL2luZGV4ZXMvXxABGgsKB3N0b3J5SWQQARoQCgxkYXRhQ2FkYXN0cm8QAhoMCghfX25hbWVfXxACDEBUG
```

**Para story_comments:**
```
https://console.firebase.google.com/v1/r/project/app-no-secreto-com-o-pai/firestore/indexes?create_composite=Cl9wcm9qZWN0cy9hcHAtbm8tc2VjcmV0by1jb20tby1wYWkvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL3N0b3J5X2NvbW1lbnRzL2luZGV4ZXMvXxABGg0KCWlzQmxvY2tlZBABGhMKD3BhcmVudENvbW1lbnRJZBABGgsKB3N0b3J5SWQQARoQCgxkYXRhQ2FkYXN0cm8QARoMCghfX25hbWVfXxABDEBUG
```

### Opção 3: Firebase CLI (Se disponível)
```bash
# Instalar Firebase CLI
npm install -g firebase-tools

# Fazer login
firebase login

# Aplicar índices
firebase deploy --only firestore:indexes
```

## ✅ Como Verificar se Funcionou

Após criar os índices:
1. Aguarde alguns minutos para propagação
2. Teste os stories novamente
3. Verifique se os erros de índice desapareceram dos logs
4. Os likes e comentários devem funcionar normalmente

## 📝 Status dos Índices

- [ ] story_likes index criado
- [ ] story_comments index criado  
- [ ] Testes realizados
- [ ] Erros de índice resolvidos

## 🔍 Arquivo Atualizado

O arquivo `firestore.indexes.json` já foi atualizado com as configurações corretas dos índices.