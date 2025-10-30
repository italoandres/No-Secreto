# 🔥 Guia: Criar Índices do Firestore para Matches Aceitos

## ❌ Problema no APK

O APK está dando erro ao buscar matches aceitos porque falta criar índices compostos no Firestore.

**Erro típico:**
```
The query requires an index. You can create it here: https://console.firebase.google.com/...
```

## ✅ Solução: Criar Índices Compostos

### Índice 1: Buscar Matches Aceitos por Usuário

**Collection:** `interest_notifications`

**Campos:**
1. `toUserId` (Ascending)
2. `status` (Ascending)
3. `dataResposta` (Descending) - Para ordenar por mais recentes

**Como criar:**

1. Acesse o [Firebase Console](https://console.firebase.google.com/)
2. Selecione seu projeto
3. Vá em **Firestore Database** → **Indexes** → **Composite**
4. Clique em **Create Index**
5. Preencha:
   - **Collection ID:** `interest_notifications`
   - **Fields to index:**
     - Campo: `toUserId`, Order: `Ascending`
     - Campo: `status`, Order: `Ascending`
     - Campo: `dataResposta`, Order: `Descending`
   - **Query scope:** `Collection`
6. Clique em **Create**

### Índice 2: Buscar Notificações por Status e Data

**Collection:** `interest_notifications`

**Campos:**
1. `toUserId` (Ascending)
2. `type` (Ascending)
3. `status` (Ascending)
4. `dataCriacao` (Descending)

**Como criar:**

1. No Firebase Console, vá em **Firestore Database** → **Indexes** → **Composite**
2. Clique em **Create Index**
3. Preencha:
   - **Collection ID:** `interest_notifications`
   - **Fields to index:**
     - Campo: `toUserId`, Order: `Ascending`
     - Campo: `type`, Order: `Ascending`
     - Campo: `status`, Order: `Ascending`
     - Campo: `dataCriacao`, Order: `Descending`
   - **Query scope:** `Collection`
4. Clique em **Create**

## ⏱️ Tempo de Criação

- Os índices levam alguns minutos para serem criados
- Você verá o status "Building" enquanto estão sendo criados
- Quando ficarem "Enabled", o APK vai funcionar

## 🧪 Como Testar

1. **Aguarde** os índices serem criados (status "Enabled")
2. **Reinstale** o APK no celular
3. **Faça login** no app
4. **Aceite um interesse** de alguém
5. **Vá para** "Matches Aceitos"
6. **Verifique** se o match aparece na lista

## 📊 Queries que Usam Esses Índices

### Query 1: Buscar matches aceitos
```dart
_firestore
  .collection('interest_notifications')
  .where('toUserId', isEqualTo: userId)
  .where('status', isEqualTo: 'accepted')
  .orderBy('dataResposta', descending: true)
```

### Query 2: Buscar notificações por tipo
```dart
_firestore
  .collection('interest_notifications')
  .where('toUserId', isEqualTo: userId)
  .where('type', isEqualTo: 'interest')
  .where('status', isEqualTo: 'accepted')
  .orderBy('dataCriacao', descending: true)
```

## 🔍 Como Verificar se os Índices Estão Funcionando

1. Abra o **Logcat** no Android Studio
2. Rode o APK
3. Vá para "Matches Aceitos"
4. **Se funcionar:** Você verá os matches na lista
5. **Se não funcionar:** Você verá um erro com link para criar o índice

## 💡 Dica

Se você ver um erro com um link do Firebase, **clique no link**! Ele vai te levar direto para a página de criação do índice com os campos já preenchidos.

## ✅ Checklist

- [ ] Índice 1 criado (toUserId + status + dataResposta)
- [ ] Índice 2 criado (toUserId + type + status + dataCriacao)
- [ ] Índices com status "Enabled"
- [ ] APK reinstalado
- [ ] Teste realizado com sucesso

## 🎯 Resultado Esperado

Depois de criar os índices, o APK deve:
- ✅ Carregar matches aceitos automaticamente
- ✅ Atualizar em tempo real quando houver novos matches
- ✅ Mostrar nome, idade, cidade e foto
- ✅ Exibir "Faltam X dias para encerrar o chat"
- ✅ Funcionar sem erros

---

**Observação:** O Chrome funciona sem índices porque o Firestore permite queries simples sem índices em desenvolvimento. O APK precisa dos índices porque usa queries compostas mais complexas.
