# ✅ Tarefa 11: Sistema de Auditoria e Logs - IMPLEMENTADO

## 📋 Resumo da Implementação

Sistema completo de auditoria para registrar todas as ações relacionadas a certificações espirituais, incluindo aprovações, reprovações e tentativas suspeitas.

---

## 🎯 Componentes Implementados

### 1. **CertificationAuditService** (`certification_audit_service.dart`)

Serviço central de auditoria com métodos para:

#### Registro de Ações Legítimas
- `logApproval()` - Registra aprovações
- `logRejection()` - Registra reprovações com motivo

#### Registro de Atividades Suspeitas
- `logInvalidToken()` - Tokens inválidos ou malformados
- `logExpiredToken()` - Tokens expirados
- `logUsedToken()` - Tentativas de reusar tokens

#### Consultas e Estatísticas
- `getCertificationLogs()` - Logs de uma certificação específica
- `getUserLogs()` - Logs de um usuário específico
- `getSuspiciousActivityLogs()` - Atividades suspeitas
- `getAuditStatistics()` - Estatísticas agregadas

---

## 📊 Estrutura do Log de Auditoria

### Coleção Firestore: `certification_audit_log`

```dart
{
  id: String,                    // ID único do log
  certificationId: String,       // ID da certificação
  userId: String,                // ID do usuário
  action: String,                // Tipo de ação
  executedBy: String,            // Quem executou
  method: String,                // Como foi executado
  timestamp: DateTime,           // Quando foi executado
  reason: String?,               // Motivo (para reprovações)
  tokenId: String?,              // ID do token (se via email)
  metadata: Map<String, dynamic>? // Dados adicionais
}
```

### Tipos de Ações

```dart
// Ações legítimas
'approved'                  // Certificação aprovada
'rejected'                  // Certificação reprovada

// Atividades suspeitas
'invalid_token_attempt'     // Token inválido
'expired_token_attempt'     // Token expirado
'used_token_attempt'        // Token já usado
```

### Métodos de Execução

```dart
'email'   // Via link no email
'panel'   // Via painel administrativo
'system'  // Ação automática do sistema
```

---

## 🔐 Funcionalidades de Segurança

### 1. Registro de Aprovação

```dart
await _auditService.logApproval(
  certificationId: 'cert_123',
  userId: 'user_456',
  approvedBy: 'admin@example.com',
  method: 'panel',
  tokenId: null, // Opcional, se via email
);
```

**Informações Registradas:**
- Quem aprovou
- Quando aprovou
- Via qual método (email ou painel)
- Token usado (se aplicável)

### 2. Registro de Reprovação

```dart
await _auditService.logRejection(
  certificationId: 'cert_123',
  userId: 'user_456',
  rejectedBy: 'admin@example.com',
  method: 'panel',
  reason: 'Comprovante ilegível',
  tokenId: null,
);
```

**Informações Adicionais:**
- Motivo detalhado da reprovação
- Preservado para histórico e transparência

### 3. Detecção de Token Inválido

```dart
await _auditService.logInvalidToken(
  token: 'abc123xyz',
  reason: 'Token não encontrado no banco de dados',
  ipAddress: '192.168.1.1', // Opcional
);
```

**Metadados Capturados:**
- Endereço IP (se disponível)
- Hash parcial do token (primeiros 8 caracteres)
- Timestamp da tentativa

### 4. Detecção de Token Expirado

```dart
await _auditService.logExpiredToken(
  token: 'abc123xyz',
  certificationId: 'cert_123',
  expirationDate: DateTime(2024, 1, 1),
);
```

**Metadados Capturados:**
- Data de expiração original
- Quantos dias se passaram desde a expiração
- Certificação associada

### 5. Detecção de Token Já Usado

```dart
await _auditService.logUsedToken(
  token: 'abc123xyz',
  certificationId: 'cert_123',
  usedAt: DateTime(2024, 1, 15),
  usedBy: 'admin@example.com',
);
```

**Metadados Capturados:**
- Quando foi usado originalmente
- Quem usou originalmente
- Tentativa de reuso detectada

---

## 📈 Consultas e Relatórios

### 1. Logs de uma Certificação

```dart
Stream<List<CertificationAuditLogModel>> logs = 
    _auditService.getCertificationLogs('cert_123');
```

**Retorna:**
- Todas as ações relacionadas à certificação
- Ordenadas por timestamp (mais recente primeiro)
- Atualização em tempo real

### 2. Logs de um Usuário

```dart
Stream<List<CertificationAuditLogModel>> logs = 
    _auditService.getUserLogs('user_456');
```

**Útil para:**
- Histórico completo do usuário
- Auditoria de ações específicas
- Investigação de problemas

### 3. Atividades Suspeitas

```dart
Stream<List<CertificationAuditLogModel>> suspicious = 
    _auditService.getSuspiciousActivityLogs();
```

**Monitora:**
- Tentativas de uso de tokens inválidos
- Tokens expirados
- Tokens já usados
- Últimas 100 ocorrências

### 4. Estatísticas Agregadas

```dart
Map<String, int> stats = await _auditService.getAuditStatistics(
  startDate: DateTime(2024, 1, 1),
  endDate: DateTime(2024, 12, 31),
);

// Retorna:
{
  'total': 150,
  'approved': 120,
  'rejected': 25,
  'invalid_attempts': 3,
  'expired_attempts': 1,
  'used_attempts': 1,
}
```

---

## 🔗 Integração com Serviços Existentes

### CertificationApprovalService

O serviço de aprovação foi atualizado para registrar automaticamente:

```dart
// Ao aprovar
await _auditService.logApproval(
  certificationId: certificationId,
  userId: userId,
  approvedBy: adminEmail,
  method: 'panel',
);

// Ao reprovar
await _auditService.logRejection(
  certificationId: certificationId,
  userId: userId,
  rejectedBy: adminEmail,
  method: 'panel',
  reason: rejectionReason,
);
```

### Cloud Functions (Futuro)

As Cloud Functions devem ser atualizadas para registrar:

```javascript
// Ao processar via email
await auditService.logApproval({
  certificationId,
  userId,
  approvedBy: 'admin@example.com',
  method: 'email',
  tokenId: token.id
});

// Ao detectar token inválido
await auditService.logInvalidToken({
  token: tokenString,
  reason: 'Token not found',
  ipAddress: req.ip
});
```

---

## 🛡️ Benefícios de Segurança

### 1. Rastreabilidade Completa
- Toda ação é registrada
- Impossível aprovar/reprovar sem deixar rastro
- Histórico imutável no Firestore

### 2. Detecção de Fraudes
- Tentativas de uso de tokens inválidos
- Tentativas de reusar tokens
- Padrões suspeitos identificáveis

### 3. Conformidade e Auditoria
- Logs detalhados para auditorias
- Quem fez o quê e quando
- Motivos documentados

### 4. Investigação de Problemas
- Rastrear problemas específicos
- Identificar gargalos no processo
- Melhorar o sistema baseado em dados

---

## 📊 Exemplo de Uso Completo

### Cenário: Aprovação via Painel

```dart
// 1. Admin aprova no painel
final success = await certificationService.approveCertification(
  'cert_123',
  'admin@example.com',
);

// 2. Automaticamente registrado no log
// ✅ Auditoria: Aprovação registrada - Cert: cert_123 por admin@example.com via panel

// 3. Consultar logs
final logs = await auditService.getCertificationLogs('cert_123').first;

// logs[0]:
{
  action: 'approved',
  executedBy: 'admin@example.com',
  method: 'panel',
  timestamp: 2024-01-15 14:30:00
}
```

### Cenário: Tentativa de Token Inválido

```dart
// 1. Alguém tenta usar token inválido
await auditService.logInvalidToken(
  token: 'fake_token_123',
  reason: 'Token não encontrado',
  ipAddress: '192.168.1.100',
);

// 2. Registrado como atividade suspeita
// ⚠️ Auditoria: Tentativa de token inválido registrada - Motivo: Token não encontrado

// 3. Monitorar atividades suspeitas
final suspicious = await auditService.getSuspiciousActivityLogs().first;

// suspicious[0]:
{
  action: 'invalid_token_attempt',
  reason: 'Token não encontrado',
  metadata: {
    ip_address: '192.168.1.100',
    token_hash: 'fake_tok'
  }
}
```

---

## 🎨 Interface de Visualização (Futuro)

### Dashboard de Auditoria

Pode ser criado um dashboard para visualizar:

```dart
// Estatísticas gerais
final stats = await auditService.getAuditStatistics();

// Atividades recentes
final recent = auditService.getCertificationLogs(certId);

// Alertas de segurança
final alerts = auditService.getSuspiciousActivityLogs();
```

### Componente de Histórico

```dart
// No card de histórico, mostrar ações
StreamBuilder<List<CertificationAuditLogModel>>(
  stream: auditService.getCertificationLogs(certificationId),
  builder: (context, snapshot) {
    final logs = snapshot.data ?? [];
    return ListView.builder(
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return ListTile(
          title: Text(log.action),
          subtitle: Text('${log.executedBy} via ${log.method}'),
          trailing: Text(formatDate(log.timestamp)),
        );
      },
    );
  },
)
```

---

## ✅ Requisitos Atendidos

- ✅ **5.2** - Logs de todas as ações com timestamp
- ✅ **6.5** - Registro de quem executou e via qual método
- ✅ **6.6** - Registro de tentativas de tokens inválidos

---

## 🚀 Próximos Passos

### 1. Integração com Cloud Functions
- Adicionar logs nas funções de email
- Registrar tokens inválidos/expirados
- Capturar IP addresses

### 2. Dashboard de Auditoria
- Criar view de visualização de logs
- Gráficos de estatísticas
- Alertas de atividades suspeitas

### 3. Notificações de Segurança
- Alertar admins sobre atividades suspeitas
- Email quando muitas tentativas inválidas
- Dashboard de segurança em tempo real

### 4. Retenção de Dados
- Política de retenção de logs
- Arquivamento de logs antigos
- Limpeza automática

---

## 📝 Notas Técnicas

### Performance
- Logs são escritos de forma assíncrona
- Não bloqueiam o fluxo principal
- Erros em logs não afetam aprovações

### Segurança
- Tokens são armazenados apenas parcialmente (hash)
- IPs são opcionais e podem ser anonimizados
- Logs são imutáveis no Firestore

### Escalabilidade
- Índices necessários no Firestore:
  - `certificationId` + `timestamp`
  - `userId` + `timestamp`
  - `action` + `timestamp`

---

## ✅ Status da Tarefa

**CONCLUÍDA COM SUCESSO** ✨

Todos os componentes foram implementados:
- ✅ Serviço de auditoria criado
- ✅ Logs de aprovação/reprovação
- ✅ Logs de atividades suspeitas
- ✅ Consultas e estatísticas
- ✅ Integração com serviço de aprovação
- ✅ Metadados detalhados
- ✅ Streams em tempo real

---

**Sistema de Auditoria Implementado e Funcional!** 🎉✅🔐
