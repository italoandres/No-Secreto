# 🔥 Configuração de Índices do Firebase para Favoritos

## ❌ Problema Identificado
```
[cloud_firestore/failed-precondition] The query requires an index.
```

## ✅ Solução: Criar Índices Necessários

### **1. Acesse o Firebase Console**
1. Vá para: https://console.firebase.google.com/
2. Selecione seu projeto: `app-no-secreto-com-o-pai`
3. Navegue para: **Firestore Database** → **Indexes**

### **2. Criar Índice para story_favorites**

#### **Índice 1: Básico**
- **Collection ID**: `story_favorites`
- **Fields**:
  - `userId` (Ascending)
  - `dataCadastro` (Descending)
- **Query scope**: Collection

#### **Índice 2: Com __name__**
- **Collection ID**: `story_favorites`
- **Fields**:
  - `userId` (Ascending)
  - `dataCadastro` (Descending)
  - `__name__` (Descending)
- **Query scope**: Collection

### **3. Link Direto para Criação**
Clique no link do erro para criar automaticamente:
```
https://console.firebase.google.com/v1/r/project/app-no-secreto-com-o-pai/firestore/indexes?create_composite=CmBwcm9qZWN0cy9hcHAtbm8tc2VjcmV0by1jb20tby1wYWkvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL3N0b3J5X2Zhdm9yaXRlcy9pbmRleGVzL18QARoKCgZ1c2VySWQQARoQCgxkYXRhQ2FkYXN0cm8QAhoMCghfX25hbWVfXxAC
```

### **4. Aguardar Criação**
- Os índices podem levar alguns minutos para serem criados
- Status aparecerá como "Building" → "Enabled"

### **5. Testar Após Criação**
1. Salve um story nos favoritos
2. Vá para a galeria de favoritos
3. Verifique se o story aparece corretamente

## 📋 Arquivo de Configuração Atualizado
O arquivo `firestore.indexes.json` foi atualizado com os índices necessários:

```json
{
  "collectionGroup": "story_favorites",
  "queryScope": "COLLECTION",
  "fields": [
    {
      "fieldPath": "userId",
      "order": "ASCENDING"
    },
    {
      "fieldPath": "dataCadastro",
      "order": "DESCENDING"
    }
  ]
}
```

## 🚀 Deploy dos Índices
Para aplicar via Firebase CLI:
```bash
firebase deploy --only firestore:indexes
```

## ✅ Verificação
Após criar os índices, o sistema de favoritos funcionará corretamente:
- ✅ Salvar stories nos favoritos
- ✅ Visualizar na galeria de favoritos
- ✅ Sincronização em tempo real
- ✅ Ordenação por data de salvamento