# Design Document - Sistema de Verificação de Certificação Espiritual

## Overview

Este documento descreve o design técnico para implementar um sistema completo de verificação de certificação espiritual. O sistema permite que usuários solicitem o selo "Preparado(a) para os Sinais" enviando comprovante de conclusão do curso, com aprovação manual pelo administrador e notificações por email.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    User Interface Layer                      │
├─────────────────────────────────────────────────────────────┤
│  - Enhanced Certification Request View (modificada)          │
│  - Admin Certification Panel View (já existe)                │
│  - Certification Status Component                            │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Service Layer                             │
├─────────────────────────────────────────────────────────────┤
│  - CertificationRequestService (novo)                        │
│  - FileUploadService (novo)                                  │
│  - EmailNotificationService (aprimorado)                     │
│  - AdminCertificationService (já existe)                     │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Repository Layer                          │
├─────────────────────────────────────────────────────────────┤
│  - CertificationRepository (aprimorado)                      │
│  - StorageRepository (novo)                                  │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Firebase Backend                          │
├─────────────────────────────────────────────────────────────┤
│  - Firestore: certification_requests collection              │
│  - Storage: certification_proofs bucket                      │
│  - Cloud Functions: Email notifications                      │
└─────────────────────────────────────────────────────────────┘
```

## Components and Interfaces

### 1. Enhanced Certification Request View

**Responsabilidade:** Interface principal para usuários solicitarem certificação

**Componentes:**
- Formulário de solicitação
- Upload de comprovante
- Campos de email
- Status da solicitação
- Feedback visual

**Estados:**
- `no_request`: Usuário nunca solicitou
- `pending`: Solicitação aguardando aprovação
- `approved`: Selo aprovado e ativo
- `rejected`: Solicitação rejeitada

**Interface:**
```dart
class EnhancedCertificationRequestView extends StatefulWidget {
  final String userId;
  final String userEmail;
  
  @override
  State<EnhancedCertificationRequestView> createState() => 
      _EnhancedCertificationRequestViewState();
}

class _EnhancedCertificationRequestViewState 
    extends State<EnhancedCertificationRequestView> {
  
  // Controllers
  final TextEditingController _purchaseEmailController;
  final TextEditingController _appEmailController;
  
  // State
  CertificationRequestModel? _currentRequest;
  File? _selectedProof;
  bool _isUploading = false;
  bool _isSubmitting = false;
  
  // Methods
  Future<void> _loadCurrentRequest();
  Future<void> _pickProofFile();
  Future<void> _submitRequest();
  Widget _buildFormView();
  Widget _buildPendingView();
  Widget _buildApprovedView();
  Widget _buildRejectedView();
}
```

### 2. Certification Request Service

**Responsabilidade:** Gerenciar lógica de negócio das solicitações

**Interface:**
```dart
class CertificationRequestService {
  final CertificationRepository _repository;
  final FileUploadService _uploadService;
  final EmailNotificationService _emailService;
  
  // Criar nova solicitação
  Future<String> createRequest({
    required String userId,
    required String userEmail,
    required String purchaseEmail,
    required File proofFile,
  });
  
  // Buscar solicitação do usuário
  Future<CertificationRequestModel?> getUserRequest(String userId);
  
  // Aprovar solicitação (admin)
  Future<void> approveRequest(String requestId, String adminId);
  
  // Rejeitar solicitação (admin)
  Future<void> rejectRequest(
    String requestId, 
    String adminId, 
    String reason,
  );
  
  // Reenviar solicitação após rejeição
  Future<String> resubmitRequest({
    required String userId,
    required String userEmail,
    required String purchaseEmail,
    required File proofFile,
  });
}
```

### 3. File Upload Service

**Responsabilidade:** Gerenciar upload de arquivos para Firebase Storage

**Interface:**
```dart
class FileUploadService {
  final FirebaseStorage _storage;
  
  // Upload de comprovante
  Future<String> uploadCertificationProof({
    required String userId,
    required File file,
    required Function(double) onProgress,
  });
  
  // Deletar comprovante
  Future<void> deleteProof(String proofUrl);
  
  // Validar arquivo
  bool validateFile(File file);
  
  // Obter extensão do arquivo
  String getFileExtension(File file);
}
```

### 4. Email Notification Service (Enhanced)

**Responsabilidade:** Enviar emails de notificação

**Interface:**
```dart
class EmailNotificationService {
  // Notificar admin sobre nova solicitação
  Future<void> notifyAdminNewRequest({
    required String userName,
    required String userEmail,
    required String purchaseEmail,
    required String proofUrl,
    required String requestId,
  });
  
  // Notificar usuário sobre aprovação
  Future<void> notifyUserApproval({
    required String userEmail,
    required String userName,
  });
  
  // Notificar usuário sobre rejeição
  Future<void> notifyUserRejection({
    required String userEmail,
    required String userName,
    required String reason,
  });
  
  // Templates de email
  String _getAdminNotificationTemplate(...);
  String _getApprovalTemplate(...);
  String _getRejectionTemplate(...);
}
```

### 5. Certification Status Component

**Responsabilidade:** Exibir status visual da solicitação

**Interface:**
```dart
class CertificationStatusComponent extends StatelessWidget {
  final CertificationRequestModel request;
  final VoidCallback? onResubmit;
  
  @override
  Widget build(BuildContext context) {
    switch (request.status) {
      case CertificationStatus.pending:
        return _buildPendingStatus();
      case CertificationStatus.approved:
        return _buildApprovedStatus();
      case CertificationStatus.rejected:
        return _buildRejectedStatus();
    }
  }
  
  Widget _buildPendingStatus();
  Widget _buildApprovedStatus();
  Widget _buildRejectedStatus();
}
```

## Data Models

### CertificationRequestModel (Enhanced)

```dart
class CertificationRequestModel {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;        // Email do app
  final String purchaseEmail;    // Email da compra
  final String proofUrl;         // URL do comprovante no Storage
  final CertificationStatus status;
  final DateTime requestedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;      // ID do admin
  final String? rejectionReason;
  
  CertificationRequestModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.purchaseEmail,
    required this.proofUrl,
    required this.status,
    required this.requestedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
  });
  
  factory CertificationRequestModel.fromFirestore(
    DocumentSnapshot doc,
  );
  
  Map<String, dynamic> toFirestore();
}

enum CertificationStatus {
  pending,
  approved,
  rejected,
}
```

### FileUploadResult

```dart
class FileUploadResult {
  final String downloadUrl;
  final String storagePath;
  final int fileSize;
  final String fileType;
  
  FileUploadResult({
    required this.downloadUrl,
    required this.storagePath,
    required this.fileSize,
    required this.fileType,
  });
}
```

## Error Handling

### Validation Errors

```dart
class CertificationValidationException implements Exception {
  final String message;
  final CertificationValidationError errorType;
  
  CertificationValidationException(this.message, this.errorType);
}

enum CertificationValidationError {
  invalidEmail,
  missingProof,
  fileTooLarge,
  invalidFileType,
  duplicateRequest,
  userNotAuthenticated,
}
```

### Upload Errors

```dart
class FileUploadException implements Exception {
  final String message;
  final FileUploadError errorType;
  
  FileUploadException(this.message, this.errorType);
}

enum FileUploadError {
  networkError,
  storageError,
  permissionDenied,
  fileTooLarge,
  invalidFormat,
}
```

### Error Handling Strategy

1. **Validação no Frontend:**
   - Validar formato de email
   - Validar tamanho do arquivo (max 5MB)
   - Validar tipo de arquivo (imagem ou PDF)

2. **Validação no Backend:**
   - Security Rules do Firebase
   - Validação de duplicatas
   - Validação de autenticação

3. **Feedback ao Usuário:**
   - Mensagens claras e acionáveis
   - Sugestões de correção
   - Retry automático quando apropriado

## Testing Strategy

### Unit Tests

1. **CertificationRequestService:**
   - Criar solicitação com dados válidos
   - Validar emails
   - Aprovar/rejeitar solicitações
   - Reenviar após rejeição

2. **FileUploadService:**
   - Upload de arquivo válido
   - Validação de tamanho
   - Validação de tipo
   - Tratamento de erros

3. **EmailNotificationService:**
   - Envio de email ao admin
   - Envio de email ao usuário
   - Templates corretos
   - Tratamento de falhas

### Integration Tests

1. **Fluxo Completo de Solicitação:**
   - Usuário preenche formulário
   - Upload de comprovante
   - Salvamento no Firebase
   - Envio de email ao admin

2. **Fluxo de Aprovação:**
   - Admin aprova solicitação
   - Selo adicionado ao perfil
   - Email enviado ao usuário

3. **Fluxo de Rejeição:**
   - Admin rejeita com motivo
   - Email enviado ao usuário
   - Usuário pode reenviar

### Widget Tests

1. **EnhancedCertificationRequestView:**
   - Renderização correta dos estados
   - Validação de formulário
   - Upload de arquivo
   - Feedback visual

2. **CertificationStatusComponent:**
   - Status pendente
   - Status aprovado
   - Status rejeitado

## Firebase Structure

### Firestore Collections

```
certification_requests/
  {requestId}/
    userId: string
    userName: string
    userEmail: string
    purchaseEmail: string
    proofUrl: string
    status: string (pending|approved|rejected)
    requestedAt: timestamp
    reviewedAt: timestamp?
    reviewedBy: string?
    rejectionReason: string?
```

### Storage Structure

```
certification_proofs/
  {userId}/
    {timestamp}_{filename}.{ext}
```

### Security Rules

**Firestore:**
```javascript
match /certification_requests/{requestId} {
  // Usuários podem criar suas próprias solicitações
  allow create: if request.auth != null 
    && request.resource.data.userId == request.auth.uid;
  
  // Usuários podem ler suas próprias solicitações
  allow read: if request.auth != null 
    && resource.data.userId == request.auth.uid;
  
  // Apenas admins podem atualizar (aprovar/rejeitar)
  allow update: if request.auth != null 
    && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
  
  // Admins podem ler todas as solicitações
  allow list: if request.auth != null 
    && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
}
```

**Storage:**
```javascript
match /certification_proofs/{userId}/{filename} {
  // Usuários podem fazer upload de seus próprios comprovantes
  allow write: if request.auth != null 
    && request.auth.uid == userId
    && request.resource.size < 5 * 1024 * 1024; // 5MB max
  
  // Usuários podem ler seus próprios comprovantes
  allow read: if request.auth != null 
    && request.auth.uid == userId;
  
  // Admins podem ler todos os comprovantes
  allow read: if request.auth != null 
    && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
}
```

## Email Templates

### Template para Admin (Nova Solicitação)

```html
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background: #FFA726; color: white; padding: 20px; text-align: center; }
    .content { background: #f5f5f5; padding: 20px; }
    .button { background: #FFA726; color: white; padding: 12px 24px; 
              text-decoration: none; border-radius: 4px; display: inline-block; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🏆 Nova Solicitação de Certificação</h1>
    </div>
    <div class="content">
      <p><strong>Usuário:</strong> {{userName}}</p>
      <p><strong>Email do App:</strong> {{userEmail}}</p>
      <p><strong>Email da Compra:</strong> {{purchaseEmail}}</p>
      <p><strong>Data:</strong> {{requestDate}}</p>
      
      <p><a href="{{proofUrl}}" class="button">Ver Comprovante</a></p>
      <p><a href="{{adminPanelUrl}}" class="button">Ir para Painel Admin</a></p>
    </div>
  </div>
</body>
</html>
```

### Template para Usuário (Aprovação)

```html
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background: #4CAF50; color: white; padding: 20px; text-align: center; }
    .content { background: #f5f5f5; padding: 20px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>✅ Certificação Aprovada!</h1>
    </div>
    <div class="content">
      <p>Olá {{userName}},</p>
      
      <p>Parabéns! Sua solicitação de certificação foi aprovada.</p>
      
      <p>O selo "Preparado(a) para os Sinais" agora está ativo no seu perfil!</p>
      
      <h3>Benefícios do Selo:</h3>
      <ul>
        <li>Seu perfil será destacado para outros usuários</li>
        <li>Outros podem filtrar e encontrar pessoas com preparação espiritual</li>
        <li>Demonstra seu comprometimento com os ensinamentos</li>
        <li>Facilita conexões com pessoas do mesmo nível espiritual</li>
      </ul>
      
      <p>Que Deus abençoe sua jornada!</p>
    </div>
  </div>
</body>
</html>
```

### Template para Usuário (Rejeição)

```html
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background: #F44336; color: white; padding: 20px; text-align: center; }
    .content { background: #f5f5f5; padding: 20px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>❌ Solicitação Não Aprovada</h1>
    </div>
    <div class="content">
      <p>Olá {{userName}},</p>
      
      <p>Infelizmente sua solicitação de certificação não foi aprovada.</p>
      
      <p><strong>Motivo:</strong> {{rejectionReason}}</p>
      
      <p>Você pode enviar uma nova solicitação com as correções necessárias.</p>
      
      <p>Se tiver dúvidas, entre em contato conosco.</p>
    </div>
  </div>
</body>
</html>
```

## Performance Considerations

1. **Upload de Arquivos:**
   - Compressão de imagens antes do upload
   - Progress indicator durante upload
   - Retry automático em caso de falha

2. **Queries Otimizadas:**
   - Index no campo `userId` para busca rápida
   - Index no campo `status` para filtrar pendentes
   - Limit de resultados no painel admin

3. **Caching:**
   - Cache do status da solicitação do usuário
   - Cache da lista de solicitações pendentes (admin)

## Security Considerations

1. **Autenticação:**
   - Verificar usuário autenticado antes de qualquer operação
   - Validar permissões de admin

2. **Validação:**
   - Validar dados no frontend e backend
   - Sanitizar inputs de texto
   - Validar formato e tamanho de arquivos

3. **Privacy:**
   - Apenas o usuário pode ver sua própria solicitação
   - Apenas admins podem ver todas as solicitações
   - URLs de comprovantes protegidas

## Migration Strategy

1. **Fase 1: Preparação**
   - Criar novas collections no Firebase
   - Configurar Security Rules
   - Implementar serviços base

2. **Fase 2: Interface**
   - Modificar página de certificação existente
   - Adicionar componentes de status
   - Integrar upload de arquivos

3. **Fase 3: Admin**
   - Aprimorar painel admin existente
   - Adicionar funcionalidades de aprovação/rejeição
   - Implementar notificações por email

4. **Fase 4: Testes**
   - Testes unitários
   - Testes de integração
   - Testes com usuários reais

5. **Fase 5: Deploy**
   - Deploy gradual
   - Monitoramento de erros
   - Ajustes baseados em feedback
