# 🔧 CORREÇÃO - Painel Admin de Certificações

## ❌ O Problema

O painel de admin não estava mostrando as certificações pendentes porque estava buscando na collection errada!

### O que estava acontecendo:

**App salvava em:**
```dart
// lib/repositories/spiritual_certification_repository.dart
static const String _collectionName = 'certification_requests';
```

**Painel de admin buscava em:**
```dart
// lib/services/certification_approval_service.dart
.collection('spiritual_certifications')  // ← ERRADO!
```

**Resultado:** Certificações eram salvas mas não apareciam no painel! 😱

---

## ✅ Correção Aplicada

Todas as referências em `certification_approval_service.dart` foram corrigidas:

### Métodos corrigidos:

1. **getPendingCertificationsStream()**
   - Busca certificações pendentes em tempo real
   - ✅ Agora busca em `certification_requests`

2. **getCertificationHistoryStream()**
   - Busca histórico de certificações
   - ✅ Agora busca em `certification_requests`

3. **approveCertification()**
   - Aprova certificação
   - ✅ Agora atualiza em `certification_requests`

4. **rejectCertification()**
   - Reprova certificação
   - ✅ Agora atualiza em `certification_requests`

5. **getCertificationById()**
   - Busca certificação específica
   - ✅ Agora busca em `certification_requests`

6. **getPendingCount()**
   - Conta certificações pendentes
   - ✅ Agora conta em `certification_requests`

7. **getPendingCountStream()**
   - Stream de contagem de pendentes
   - ✅ Agora monitora `certification_requests`

8. **hasApprovedCertification()**
   - Verifica se usuário tem certificação aprovada
   - ✅ Agora verifica em `certification_requests`

9. **getUserCertifications()**
   - Busca todas as certificações de um usuário
   - ✅ Agora busca em `certification_requests`

---

## 🎯 O Que Funciona Agora

### 1. Usuário solicita certificação
- ✅ Salva em `certification_requests`
- ✅ Email enviado para admin
- ✅ Cloud Function disparada

### 2. Admin abre o painel
- ✅ Busca em `certification_requests`
- ✅ Mostra certificações pendentes
- ✅ Contador em tempo real

### 3. Admin aprova/reprova
- ✅ Atualiza em `certification_requests`
- ✅ Email enviado para usuário
- ✅ Badge atualizado no perfil

---

## 🧪 Como Testar

### 1. Faça uma nova solicitação
```
1. Abra o app como usuário normal
2. Vá em "Certificação Espiritual"
3. Preencha e envie
```

### 2. Verifique no Firestore
```
Firebase Console > Firestore > certification_requests
Deve aparecer o documento com status: "pending"
```

### 3. Abra o painel de admin
```
1. Faça login como admin
2. Menu lateral > "Certificações Espirituais"
3. Deve aparecer na aba "Pendentes"
```

### 4. Aprove ou reprove
```
1. Clique em ✅ ou ❌
2. Deve processar e sumir da lista de pendentes
3. Deve aparecer na aba "Histórico"
```

---

## 📊 Estrutura Correta Agora

```
Firestore
└── certification_requests/
    ├── {requestId1}/
    │   ├── userId: "..."
    │   ├── userName: "..."
    │   ├── status: "pending"
    │   └── ...
    ├── {requestId2}/
    │   ├── userId: "..."
    │   ├── status: "approved"
    │   └── ...
    └── {requestId3}/
        ├── userId: "..."
        ├── status: "rejected"
        └── ...
```

---

## ✅ Checklist de Verificação

- [x] Código corrigido em `certification_approval_service.dart`
- [ ] Teste: Criar nova solicitação
- [ ] Teste: Verificar no Firestore
- [ ] Teste: Abrir painel de admin
- [ ] Teste: Ver certificação pendente
- [ ] Teste: Aprovar certificação
- [ ] Teste: Verificar histórico

---

## 🎉 Agora Sim Vai Funcionar!

Tudo está usando a mesma collection: **`certification_requests`**

- ✅ App salva em `certification_requests`
- ✅ Cloud Functions escutam `certification_requests`
- ✅ Painel de admin busca em `certification_requests`

**Consistência total!** 🚀
