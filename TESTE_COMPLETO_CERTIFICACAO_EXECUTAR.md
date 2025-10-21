# 🧪 TESTE COMPLETO - Sistema de Certificação Espiritual

## ⏱️ Tempo Estimado: 5 minutos

Este teste valida **TODO** o sistema de certificação em um único fluxo automatizado.

---

## 🎯 O Que Este Teste Valida

### ✅ Fase 1: Criação de Solicitação
- Cria uma nova solicitação de certificação
- Valida dados do usuário
- Gera ID único da solicitação

### ✅ Fase 2: Aprovação
- Aprova a certificação automaticamente
- Atualiza status para "approved"
- Registra data de aprovação

### ✅ Fase 3: Badge no Perfil
- Verifica se `hasSpiritualCertification = true`
- Confirma tipo de certificação
- Valida atualização do perfil

### ✅ Fase 4: Auditoria
- Lista logs de auditoria
- Verifica registro de ações
- Mostra histórico completo

### ✅ Fase 5: Visualização do Selo
- Gera representação visual do selo
- Mostra status de certificação
- Exibe tipo de certificação

---

## 🚀 Como Executar

### Opção 1: Adicionar ao Main.dart (RECOMENDADO)

```dart
import 'package:flutter/material.dart';
import 'utils/test_certification_complete.dart';

// No seu main.dart, adicione uma rota ou botão:

FloatingActionButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CertificationCompleteTest(),
      ),
    );
  },
  child: const Icon(Icons.science),
  tooltip: 'Teste Completo Certificação',
)
```

### Opção 2: Criar Tela de Testes

```dart
// Em alguma tela administrativa ou de debug:

ListTile(
  leading: const Icon(Icons.verified, color: Colors.deepPurple),
  title: const Text('Teste Completo - Certificação'),
  subtitle: const Text('Valida todo o fluxo (5 min)'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CertificationCompleteTest(),
      ),
    );
  },
)
```

### Opção 3: Executar Diretamente

```dart
// Cole este código em qualquer lugar do seu app:

import 'utils/test_certification_complete.dart';

// Depois navegue:
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const CertificationCompleteTest(),
  ),
);
```

---

## 📱 Interface do Teste

### Tela Principal

```
┌─────────────────────────────────────┐
│  🧪 Teste Completo - Certificação   │
├─────────────────────────────────────┤
│                                     │
│  🚀 Executando teste completo...    │
│         ⏳ (loading spinner)        │
│                                     │
├─────────────────────────────────────┤
│  LOGS:                              │
│                                     │
│  12:34:56 - 📝 FASE 1: Criando...  │
│  12:34:58 - ✅ Solicitação criada  │
│  12:35:00 - ✅ FASE 2: Aprovando.. │
│  12:35:02 - ✅ Certificação aprov. │
│  12:35:04 - 🏅 FASE 3: Verifican.. │
│  12:35:05 - ✅ Badge no perfil: SIM│
│  12:35:06 - 📊 FASE 4: Auditoria.. │
│  12:35:07 - 📊 Logs encontrados: 3 │
│  12:35:08 - 🎨 FASE 5: Visualiza.. │
│                                     │
│  ═══════════════════════════════   │
│      SELO DE CERTIFICAÇÃO          │
│  ═══════════════════════════════   │
│                                     │
│         ⭐ CERTIFICADO ⭐           │
│                                     │
│  Este perfil possui certificação   │
│       espiritual verificada        │
│                                     │
│  Tipo: Seminário Teológico         │
│  Status: ✅ ATIVO                  │
│                                     │
│  ═══════════════════════════════   │
│                                     │
│  🎉 TODOS OS TESTES PASSARAM!      │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  [▶️ Executar Teste Completo]      │
│                                     │
└─────────────────────────────────────┘
```

---

## 📊 Resultados Esperados

### ✅ Sucesso Total

```
✅ TESTE COMPLETO CONCLUÍDO COM SUCESSO!

🎉 TODOS OS TESTES PASSARAM!
✅ Solicitação criada
✅ Certificação aprovada
✅ Badge aparece no perfil
✅ Auditoria registrada
✅ Selo visual funcionando
```

### ❌ Se Houver Erro

O teste mostrará exatamente onde falhou:

```
❌ Erro no teste: Badge não foi adicionado ao perfil

Logs:
✅ Solicitação criada: abc123
✅ Certificação aprovada com sucesso
📋 Status atual: approved
❌ Badge no perfil: NÃO ❌
```

---

## 🔍 O Que Verificar no Firebase

### 1. Collection: `spiritual_certifications`

```javascript
{
  id: "abc123",
  userId: "user123",
  status: "approved",  // ← Deve estar "approved"
  approvalDate: Timestamp,
  adminNotes: "Aprovado no teste completo"
}
```

### 2. Collection: `usuarios`

```javascript
{
  uid: "user123",
  hasSpiritualCertification: true,  // ← Deve ser true
  spiritualCertificationType: "seminary",
  certificationDate: Timestamp
}
```

### 3. Collection: `certification_audit_logs`

```javascript
[
  {
    requestId: "abc123",
    action: "request_created",
    timestamp: Timestamp
  },
  {
    requestId: "abc123",
    action: "status_changed",
    oldStatus: "pending",
    newStatus: "approved",
    timestamp: Timestamp
  }
]
```

---

## 🎯 Checklist de Validação

Após executar o teste, confirme:

- [ ] Solicitação foi criada no Firestore
- [ ] Status mudou de "pending" para "approved"
- [ ] Campo `hasSpiritualCertification` = true no perfil
- [ ] Campo `spiritualCertificationType` foi preenchido
- [ ] Logs de auditoria foram criados
- [ ] Selo visual aparece corretamente
- [ ] Nenhum erro no console

---

## 🐛 Troubleshooting

### Erro: "Usuário não autenticado"
**Solução:** Faça login no app antes de executar o teste

### Erro: "Perfil não encontrado"
**Solução:** Certifique-se de que o usuário tem um documento na collection `usuarios`

### Erro: "Badge não foi adicionado ao perfil"
**Solução:** Verifique se o Cloud Function `onCertificationStatusChange` está ativo

### Erro: "Nenhum log de auditoria encontrado"
**Solução:** Verifique se o serviço de auditoria está configurado corretamente

---

## 📈 Próximos Passos

Após o teste passar com sucesso:

1. ✅ **Teste Manual**: Solicite uma certificação real pela interface
2. ✅ **Teste Admin**: Acesse o painel admin e aprove manualmente
3. ✅ **Teste Visual**: Veja o selo aparecer em perfis certificados
4. ✅ **Teste Email**: Verifique se emails de aprovação são enviados

---

## 🎉 Resultado Final

Se todos os testes passarem, você verá:

```
═══════════════════════════════════
      SELO DE CERTIFICAÇÃO       
═══════════════════════════════════

         ⭐ CERTIFICADO ⭐        

  Este perfil possui certificação
       espiritual verificada      

  Tipo: Seminário Teológico
  Status: ✅ ATIVO                

═══════════════════════════════════

🎉 SISTEMA 100% FUNCIONAL!
```

---

## 📞 Suporte

Se encontrar problemas:

1. Verifique os logs no console do Flutter
2. Verifique os logs no Firebase Console
3. Revise as regras de segurança do Firestore
4. Confirme que as Cloud Functions estão ativas

---

**Tempo total do teste:** ~5 minutos  
**Última atualização:** Hoje  
**Status:** ✅ Pronto para uso
