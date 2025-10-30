# 🔗 Link para Criar Índice Firebase - Notificações de Interesse

## Link Direto para Firebase Console

**Clique no link abaixo para criar o índice necessário:**

👉 **[CRIAR ÍNDICE NO FIREBASE CONSOLE](https://console.firebase.google.com/project/_/firestore/indexes?create_composite=Interests:to,timestamp)**

## Configuração do Índice

Quando o Firebase Console abrir, configure o índice com:

- **Coleção:** `interests`
- **Campo 1:** `to` (Ascending)
- **Campo 2:** `timestamp` (Descending)

## Instruções Passo a Passo

1. 🌐 Clique no link acima
2. 📁 Selecione seu projeto Firebase
3. 🔧 Verifique se os campos estão corretos:
   - Collection: `interests`
   - Field 1: `to` (Ascending)
   - Field 2: `timestamp` (Descending)
4. ✅ Clique em "Create"
5. ⏳ Aguarde a criação (pode levar alguns minutos)

## Alternativa: Firebase CLI

Se preferir usar o CLI, adicione ao seu `firestore.indexes.json`:

```json
{
  "indexes": [
    {
      "collectionGroup": "interests",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "to",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "timestamp",
          "order": "DESCENDING"
        }
      ]
    }
  ]
}
```

Depois execute:
```bash
firebase deploy --only firestore:indexes
```

## Por que este índice é necessário?

Este índice é necessário para que o sistema possa buscar eficientemente todos os interesses onde um usuário específico é o destinatário (`to`), ordenados por data (`timestamp`).

Sem este índice, as queries falharão e as notificações reais não funcionarão.

## Verificação

Após criar o índice, você pode testar se está funcionando executando o debug de notificações reais no app.

---

**⚠️ IMPORTANTE:** O índice pode levar alguns minutos para ser criado. Você receberá um email quando estiver pronto.