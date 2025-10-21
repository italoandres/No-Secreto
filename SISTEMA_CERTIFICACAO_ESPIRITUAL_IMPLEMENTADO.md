# 🎯 Sistema de Certificação Espiritual - Implementado

## ✅ Status: Fase 1 Concluída

Sistema completo de certificação espiritual com envio de comprovante, aprovação manual e notificações por email.

---

## 📦 Componentes Implementados

### 1. Modelos de Dados ✅

#### `CertificationRequestModel`
- **Localização**: `lib/models/certification_request_model.dart`
- **Funcionalidades**:
  - Enum `CertificationStatus` (pending, approved, rejected, expired)
  - Conversão Firestore (toFirestore/fromFirestore)
  - Métodos auxiliares (isPending, isApproved, canRetry, etc.)
  - Formatação de status em português
  - Cores e ícones por status
  - Cálculo de tempo desde submissão

---

### 2. Repositório ✅

#### `CertificationRepository`
- **Localização**: `lib/repositories/certification_repository.dart`
- **Funcionalidades**:
  - ✅ `submitRequest()` - Submete nova solicitação
  - ✅ `uploadProofFile()` - Upload de comprovante para Firebase Storage
  - ✅ `getRequestByUserId()` - Busca solicitação do usuário
  - ✅ `getRequestById()` - Busca por ID
  - ✅ `getPendingRequests()` - Lista pendentes (admin)
  - ✅ `getAllRequests()` - Lista todas com filtros
  - ✅ `approveRequest()` - Aprova solicitação
  - ✅ `rejectRequest()` - Rejeita solicitação
  - ✅ `addNotificationSent()` - Registra notificação enviada
  - ✅ `expireOldRequests()` - Expira após 7 dias
  - ✅ `hasApprovedCertification()` - Verifica se tem certificação
  - ✅ `watchPendingRequests()` - Stream em tempo real
  - ✅ `watchUserRequest()` - Stream do usuário
  - ✅ `getStatistics()` - Estatísticas para dashboard

---

### 3. Serviços ✅

#### `CertificationService`
- **Localização**: `lib/services/certification_service.dart`
- **Funcionalidades**:
  - ✅ Gerenciamento de estado com GetX
  - ✅ `submitRequest()` - Submete com validações
  - ✅ `refresh()` - Recarrega dados
  - ✅ `checkCertificationStatus()` - Verifica status
  - ✅ `formatTimeSinceSubmission()` - Formata tempo
  - ✅ `calculateAnalysisProgress()` - Calcula progresso
  - ✅ `getStatusMessage()` - Mensagem personalizada
  - ✅ `getNextAction()` - Próxima ação recomendada
  - ✅ Validação de email e arquivo
  - ✅ Notificação automática para admin

#### `EmailService`
- **Localização**: `lib/services/email_service.dart`
- **Funcionalidades**:
  - ✅ `sendAdminCertificationNotification()` - Notifica admin
  - ✅ `sendApprovalNotification()` - Notifica aprovação
  - ✅ `sendRejectionNotification()` - Notifica rejeição
  - ✅ `sendAdminReminder()` - Lembrete para admin
  - ✅ `sendSubmissionConfirmation()` - Confirma recebimento
  - ✅ Templates HTML completos e responsivos

---

### 4. Componentes UI ✅

#### `ProofUploadComponent`
- **Localização**: `lib/components/proof_upload_component.dart`
- **Funcionalidades**:
  - ✅ Upload de foto (câmera)
  - ✅ Upload de foto (galeria)
  - ✅ Upload de PDF
  - ✅ Preview de arquivo selecionado
  - ✅ Validação de tamanho (máx 5MB)
  - ✅ Validação de formato (JPG, PNG, PDF)
  - ✅ Compressão automática de imagens
  - ✅ Interface moderna com bottom sheet
  - ✅ Feedback visual de loading
  - ✅ Exibição de tamanho do arquivo

---

### 5. Telas ✅

#### `CertificationRequestView`
- **Localização**: `lib/views/certification_request_view.dart`
- **Funcionalidades**:
  - ✅ Header com gradiente e ícone
  - ✅ Instruções passo a passo (4 etapas)
  - ✅ Seção de upload de comprovante
  - ✅ Campo de email com validação
  - ✅ Botão de envio com loading
  - ✅ Box de informações importantes
  - ✅ Validação completa do formulário
  - ✅ Feedback visual de erros
  - ✅ Design moderno e intuitivo

#### `CertificationStatusView`
- **Localização**: `lib/views/certification_status_view.dart`
- **Funcionalidades**:
  - ✅ Card de status com gradiente dinâmico
  - ✅ Ícones e cores por status
  - ✅ Barra de progresso (pendente)
  - ✅ Card de detalhes da solicitação
  - ✅ Linha do tempo visual
  - ✅ Botão para nova solicitação (se rejeitado/expirado)
  - ✅ Pull to refresh
  - ✅ Mensagens personalizadas por status
  - ✅ Formatação de datas em português

---

## 🎨 Design System

### Cores
- **Primária**: `#6B46C1` (Roxo espiritual)
- **Sucesso**: `#10B981` (Verde aprovação)
- **Alerta**: `#F59E0B` (Amarelo pendente)
- **Erro**: `#EF4444` (Vermelho rejeição)
- **Cinza**: `#6B7280` (Expirado)

### Ícones
- 📜 Certificação
- 📎 Anexo
- ✅ Aprovado
- ❌ Rejeitado
- ⏳ Pendente
- 👑 Selo de Verificação

---

## 📧 Sistema de Notificações

### Para Admin (sinais.app@gmail.com)
```
Assunto: 🔔 Nova Solicitação de Certificação

Conteúdo:
- Nome do usuário
- Email do app
- Email da compra
- Data de envio
- Comprovante anexado
- Link para painel de aprovação
```

### Para Usuário (Aprovação)
```
Assunto: ✅ Certificação Aprovada - Parabéns!

Conteúdo:
- Mensagem de parabéns
- Selo ativo no perfil
- Benefícios da certificação
- Link para o app
```

### Para Usuário (Rejeição)
```
Assunto: 📋 Solicitação de Certificação

Conteúdo:
- Motivo da rejeição
- Orientações para correção
- Botão para tentar novamente
```

---

## 🔥 Firebase Configuration

### Firestore Collection
```
certification_requests/
├── {requestId}
    ├── userId: string
    ├── userDisplayName: string
    ├── userEmail: string
    ├── purchaseEmail: string
    ├── proofImageUrl: string
    ├── status: string (pending|approved|rejected|expired)
    ├── submittedAt: timestamp
    ├── reviewedAt: timestamp?
    ├── adminNotes: string?
    ├── adminId: string?
    └── notificationsSent: array<string>
```

### Firebase Storage
```
certification_proofs/
└── certification_proof_{userId}_{timestamp}
```

### Índices Necessários
```javascript
// certification_requests
- userId (ASC) + submittedAt (DESC)
- status (ASC) + submittedAt (ASC)
```

### Regras de Segurança
```javascript
match /certification_requests/{requestId} {
  // Usuário pode ler apenas suas próprias solicitações
  allow read: if request.auth != null && 
              resource.data.userId == request.auth.uid;
  
  // Usuário pode criar solicitação
  allow create: if request.auth != null && 
                request.resource.data.userId == request.auth.uid;
  
  // Apenas admin pode atualizar
  allow update: if request.auth != null && 
                isAdmin(request.auth.uid);
}
```

---

## 🚀 Como Usar

### 1. Inicializar o Serviço
```dart
// No main.dart ou app initialization
Get.put(CertificationService());
```

### 2. Navegar para Certificação
```dart
// Do perfil ou vitrine
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const CertificationStatusView(),
  ),
);
```

### 3. Verificar se Usuário Tem Certificação
```dart
final hasCertification = await CertificationService.to
    .checkCertificationStatus(userId);

if (hasCertification) {
  // Mostrar selo no perfil
}
```

---

## 📱 Fluxos de Usuário

### Fluxo 1: Primeira Solicitação
```
1. Usuário acessa "Certificação Espiritual"
2. Vê tela de boas-vindas
3. Clica em "Solicitar Certificação"
4. Anexa comprovante (foto ou PDF)
5. Informa email da compra
6. Envia solicitação
7. Recebe confirmação
8. Admin é notificado por email
```

### Fluxo 2: Acompanhar Status
```
1. Usuário acessa "Certificação Espiritual"
2. Vê card de status (pendente/aprovado/rejeitado)
3. Visualiza detalhes da solicitação
4. Acompanha linha do tempo
5. Recebe notificação quando houver resposta
```

### Fluxo 3: Nova Tentativa (Rejeitado)
```
1. Usuário vê status "Rejeitada"
2. Lê motivo da rejeição
3. Clica em "Enviar Nova Solicitação"
4. Corrige os dados
5. Reenvia comprovante
```

---

## 🎯 Próximos Passos

### Fase 2: Painel Administrativo
- [ ] `AdminCertificationPanel` - Lista de solicitações
- [ ] Visualização de comprovantes
- [ ] Botões aprovar/rejeitar
- [ ] Campo para observações
- [ ] Dashboard com métricas

### Fase 3: Integração com Perfil
- [ ] Selo de verificação no perfil
- [ ] Badge na vitrine de propósito
- [ ] Filtro por certificados no matching
- [ ] Recursos exclusivos

### Fase 4: Automações
- [ ] Lembrete após 24h (admin)
- [ ] Escalação após 3 dias
- [ ] Expiração automática após 7 dias
- [ ] Relatório semanal

---

## 📊 Métricas Disponíveis

```dart
final stats = await CertificationRepository.getStatistics();

// Retorna:
{
  'pending': 5,
  'approved': 120,
  'rejected': 8,
  'expired': 2,
  'total': 135
}
```

---

## 🔒 Segurança

### Validações Implementadas
- ✅ Arquivo máximo 5MB
- ✅ Formatos permitidos: JPG, PNG, PDF
- ✅ Email válido
- ✅ Usuário autenticado
- ✅ Uma solicitação por vez
- ✅ Sanitização de dados

### Logs e Auditoria
- ✅ Registro de todas as ações
- ✅ Timestamp de submissão
- ✅ Timestamp de revisão
- ✅ ID do admin que aprovou/rejeitou
- ✅ Histórico de notificações enviadas

---

## 🎉 Benefícios do Sistema

### Para Usuários
- ✅ Processo simples e intuitivo
- ✅ Feedback em tempo real
- ✅ Transparência no status
- ✅ Selo de credibilidade
- ✅ Recursos exclusivos

### Para Administradores
- ✅ Notificação automática
- ✅ Visualização centralizada
- ✅ Processo de aprovação rápido
- ✅ Histórico completo
- ✅ Métricas e relatórios

### Para o App
- ✅ Maior credibilidade
- ✅ Comunidade verificada
- ✅ Diferencial competitivo
- ✅ Engajamento aumentado
- ✅ Qualidade dos perfis

---

## 📝 Notas Técnicas

### Dependências Necessárias
```yaml
dependencies:
  firebase_storage: ^11.0.0
  image_picker: ^1.0.0
  file_picker: ^6.0.0
  cloud_functions: ^4.0.0
  get: ^4.6.0
```

### Cloud Functions (Backend)
Será necessário implementar as seguintes Cloud Functions:
- `sendAdminCertificationEmail`
- `sendCertificationApprovalEmail`
- `sendCertificationRejectionEmail`
- `sendAdminReminderEmail`
- `sendSubmissionConfirmationEmail`

---

## 🎨 Screenshots (Conceitual)

### Tela de Solicitação
```
┌─────────────────────────────────────┐
│ ← Certificação Espiritual           │
├─────────────────────────────────────┤
│                                     │
│  [Gradiente Roxo]                   │
│     👑                              │
│  Obtenha seu Selo                   │
│  de Verificação                     │
│                                     │
├─────────────────────────────────────┤
│  Como funciona?                     │
│                                     │
│  ① Envie o comprovante              │
│  ② Informe o email                  │
│  ③ Aguarde análise                  │
│  ④ Receba o selo                    │
│                                     │
├─────────────────────────────────────┤
│  📎 Comprovante de Compra *         │
│  [Anexar Arquivo]                   │
│                                     │
│  📧 Email da Compra *               │
│  [exemplo@email.com]                │
│                                     │
│  [📤 Enviar Solicitação]           │
│                                     │
│  ℹ️ Informações Importantes         │
│  • Comprovante legível              │
│  • Máx 5MB                          │
│  • Análise em 3 dias                │
└─────────────────────────────────────┘
```

### Tela de Status (Pendente)
```
┌─────────────────────────────────────┐
│ ← Certificação Espiritual           │
├─────────────────────────────────────┤
│                                     │
│  [Gradiente Laranja]                │
│     ⏳                              │
│  Aguardando Análise                 │
│  Sua solicitação está sendo         │
│  analisada pela nossa equipe        │
│  [████████░░] 80%                   │
│                                     │
├─────────────────────────────────────┤
│  Detalhes da Solicitação            │
│  📧 compra@email.com                │
│  📅 14 out 2024 às 15:30           │
│                                     │
├─────────────────────────────────────┤
│  Linha do Tempo                     │
│  ✅ Solicitação Enviada             │
│  🔄 Em Análise (atual)              │
│  ⏳ Resultado (aguardando)          │
└─────────────────────────────────────┘
```

---

## ✨ Conclusão

Sistema completo de certificação espiritual implementado com sucesso! 

**Próximo passo**: Implementar o painel administrativo para aprovação das solicitações.

---

**Documentação criada em**: 14/10/2024  
**Versão**: 1.0  
**Status**: ✅ Fase 1 Completa
