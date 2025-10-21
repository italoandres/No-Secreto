# 🔧 Fix para Índice do Firebase - Story Likes

## ❌ Problema
```
DEBUG CONTROLLER: Erro no stream de likes: [cloud_firestore/failed-precondition] The query requires an index.
```

## ✅ Solução

### Opção 1: Link Direto (Mais Rápido)
1. Acesse este link direto para criar o índice:
```
https://console.firebase.google.com/v1/r/project/app-no-secreto-com-o-pai/firestore/indexes?create_composite=Clxwcm9qZWN0cy9hcHAtbm8tc2VjcmV0by1jb20tby1wYWkvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL3N0b3J5X2xpa2VzL2luZGV4ZXMvXxABGgsKB3N0b3J5SWQQARoQCgxkYXRhQ2FkYXN0cm8QAhoMCghfX25hbWVfXxACDEBUG
```

2. Clique em "Create Index"
3. Aguarde alguns minutos para o índice ser criado

### Opção 2: Manual
1. Acesse: https://console.firebase.google.com/project/app-no-secreto-com-o-pai/firestore/indexes
2. Clique em "Create Index"
3. Configure:
   - **Collection Group**: `story_likes`
   - **Fields**:
     - `storyId` (Ascending)
     - `dataCadastro` (Ascending) 
     - `__name__` (Ascending)
4. Clique em "Create"

## 🕒 Tempo de Criação
- Normalmente leva 2-5 minutos
- Você receberá um email quando estiver pronto

## ✅ Como Verificar
Após criar o índice, teste novamente os stories. O erro de likes deve desaparecer.