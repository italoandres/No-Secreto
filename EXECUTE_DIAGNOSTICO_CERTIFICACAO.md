# 🚀 EXECUTE AGORA: Diagnóstico de Certificação

## 📋 Passo a Passo

### Opção 1: Executar no App (RECOMENDADO)

1. **Adicione no seu `main.dart` ou em qualquer tela de teste:**

```dart
import 'package:flutter/material.dart';
import 'utils/verify_certification_path.dart';

// Adicione um botão em qualquer tela:
ElevatedButton(
  onPressed: () async {
    await VerifyCertificationPath.runFullDiagnostic('ngpdnlaDkDopAFQ7wiib');
  },
  child: Text('🔍 Diagnosticar Certificação'),
)
```

2. **Execute o app e clique no botão**

3. **Veja o console/log** - ele vai mostrar:
   - ✅ Onde o documento foi salvo
   - 📍 Caminho completo
   - 🎯 Como deve ser o trigger da Cloud Function

---

### Opção 2: Verificar Manualmente no Firebase Console

1. **Abra:** https://console.firebase.google.com

2. **Selecione:** `app-no-secreto-com-o-pai`

3. **Vá em:** Firestore Database (menu lateral)

4. **Procure a collection:**
   - `certification_requests` ← Deve ser este
   - Ou `certificationRequests`
   - Ou outro nome

5. **Encontre o documento:** `ngpdnlaDkDopAFQ7wiib`

6. **Anote o caminho completo** (exemplo: `certification_requests/ngpdnlaDkDopAFQ7wiib`)

---

## 🔍 O Que Você Vai Descobrir

O diagnóstico vai mostrar algo assim:

```
🔍 ========================================
🔍 VERIFICANDO CAMINHO DO DOCUMENTO
🔍 ========================================
🔍 Request ID: ngpdnlaDkDopAFQ7wiib

🔍 Verificando: certification_requests/ngpdnlaDkDopAFQ7wiib
✅ ENCONTRADO!
📍 Caminho completo: certification_requests/ngpdnlaDkDopAFQ7wiib
📄 Dados: {userName: italo, userEmail: italo3@gmail.com, ...}

🎯 TRIGGER DA CLOUD FUNCTION DEVE SER:
   certification_requests/{requestId}
```

---

## 🎯 Depois do Diagnóstico

### Se o caminho for `certification_requests`:

✅ **Está correto!** O problema pode ser:

1. **Credenciais do Gmail**
   ```bash
   cd functions
   firebase functions:config:get
   ```

2. **Function não deployada**
   ```bash
   firebase deploy --only functions
   ```

3. **Logs da function**
   ```bash
   firebase functions:log
   ```

### Se o caminho for DIFERENTE:

❌ **Precisamos corrigir!**

Vou atualizar o trigger da Cloud Function para o caminho correto.

**Me diga qual caminho foi encontrado!**

---

## 🧪 Teste Manual Rápido

Enquanto isso, teste se a function funciona:

1. **No Firestore Console**, crie um documento manualmente:
   - Collection: `certification_requests`
   - Document ID: `teste_manual_agora`
   - Campos:
     ```
     userName: "Teste"
     userEmail: "teste@gmail.com"
     purchaseEmail: "compra@gmail.com"
     requestedAt: [clique no relógio para timestamp]
     status: "pending"
     ```

2. **Aguarde 10 segundos**

3. **Verifique o email:** `sinais.aplicativo@gmail.com`

**Email chegou?**
- ✅ SIM: Function funciona, problema é só o caminho
- ❌ NÃO: Problema nas credenciais ou na function

---

## 📞 Me Avise

Depois de executar, me diga:

1. **Qual o caminho encontrado?**
   - Exemplo: `certification_requests/ngpdnlaDkDopAFQ7wiib`

2. **O teste manual funcionou?**
   - Email chegou?

3. **O que apareceu nos logs?**
   - Erros?
   - Nada?

Vou corrigir imediatamente! 🚀
