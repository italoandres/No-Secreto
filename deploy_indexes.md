# 🔥 Deploy dos Índices do Firestore

## Comando para aplicar os índices:

```bash
firebase deploy --only firestore:indexes
```

## Ou criar o índice manualmente:

1. Acesse: https://console.firebase.google.com/project/app-no-secreto-com-o-pai/firestore/indexes
2. Clique em "Create Index"
3. Configure:
   - Collection ID: `purpose_invites`
   - Fields:
     - `toUserId` (Ascending)
     - `status` (Ascending) 
     - `dataCriacao` (Descending)

## Link direto do erro:
https://console.firebase.google.com/v1/r/project/app-no-secreto-com-o-pai/firestore/indexes?create_composite=CmBwcm9qZWN0cy9hcHAtbm8tc2VjcmV0by1jb20tby1wYWkvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL3B1cnBvc2VfaW52aXRlcy9pbmRleGVzL18QARoKCgZzdGF0dXMQARoMCgh0b1VzZXJJZBABGg8KC2RhdGFDcmlhY2FvEAIaDAoIX19uYW1lX18QAg