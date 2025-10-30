# Design - Sistema de Certificação Espiritual com Verificação

## Overview

Sistema completo de certificação espiritual que permite usuários solicitarem o selo através de upload de comprovante, administradores aprovarem via email ou painel, e notificações automáticas para ambos os lados.

## Architecture

### Fluxo Geral

```
Usuário → Formulário → Firebase Storage (upload) → Firestore (solicitação)
                                                          ↓
                                                    Email para Admin
                                                          ↓
                                    Admin → Aprovar/Rejeitar (Email ou Painel)
                                                          ↓
                                            Atualiza Firestore + Notifica Usuário
                                                          ↓
                                                Selo aparece no perfil
```

### Estrutura de Dados Firebase

#### Collection: `spiritual_certifications`

```dart
{
  "id": "auto-generated",
  "userId": "user123",
  "userName": "João Silva",
  "userEmail": "joao@email.com",
  "purchaseEmail": "joao.compra@email.com",
  "proofFileUrl": "https://storage.../proof.pdf",
  "proofFileName": "comprovante.pdf",
  "status": "pending", // pending, approved, rejected
  "requestedAt": Timestamp,
  "reviewedAt": Timestamp?, // null se pending
  "reviewedBy": "admin@email.com"?, // null se pending
  "rejectionReason": String?, // opcional
}
```

#### Campo no `users` collection:

```dart
{
  "isSpiritualCertified": bool, // já existe
  "certificationApprovedAt": Timestamp?, // novo
}
```

## Components and Interfaces

### 1. Tela de Solicitação (`SpiritualCertificationRequestView`)

**Localização:** `lib/views/spiritual_certification_request_view.dart`

**Responsabilidades:**
- Exibir formulário com fundo âmbar/dourado
- Permitir upload de arquivo (PDF/imagem)
- Validar campos obrigatórios
- Enviar solicitação para Firebase
- Mostrar histórico de solicitações

**UI Components:**
- `CertificationRequestFormComponent` - Formulário principal
- `FileUploadComponent` - Upload de arquivo com preview
- `CertificationHistoryComponent` - Lista de solicitações anteriores

### 2. Componente de Upload (`FileUploadComponent`)

**Localização:** `lib/components/file_upload_component.dart`

**Responsabilidades:**
- Permitir seleção de arquivo (file_picker)
- Validar tipo (PDF, JPG, JPEG, PNG)
- Validar tamanho (máx 5MB)
- Mostrar preview do arquivo selecionado
- Indicar progresso do upload

### 3. Serviço de Certificação (`SpiritualCertificationService`)

**Localização:** `lib/services/spiritual_certification_service.dart`

**Métodos:**
```dart
class SpiritualCertificationService {
  // Criar nova solicitação
  Future<Result<String>> createCertificationRequest({
    required String userId,
    required String userName,
    required String userEmail,
    required String purchaseEmail,
    required File proofFile,
  });
  
  // Buscar solicitações do usuário
  Future<List<CertificationRequest>> getUserRequests(String userId);
  
  // Buscar solicitações pendentes (admin)
  Stream<List<CertificationRequest>> getPendingRequests();
  
  // Aprovar certificação
  Future<void> approveCertification(String requestId, String adminEmail);
  
  // Rejeitar certificação
  Future<void> rejectCertification(String requestId, String adminEmail, String? reason);
}
```

### 4. Serviço de Upload (`CertificationFileUploadService`)

**Localização:** `lib/services/certification_file_upload_service.dart`

**Métodos:**
```dart
class CertificationFileUploadService {
  // Upload de arquivo para Storage
  Future<Result<String>> uploadProofFile({
    required String userId,
    required File file,
    required Function(double) onProgress,
  });
  
  // Validar arquivo
  bool validateFile(File file);
  
  // Obter URL de download
  Future<String> getDownloadUrl(String storagePath);
}
```

### 5. Serviço de Email (`CertificationEmailService`)

**Localização:** `lib/services/certification_email_service.dart`

**Métodos:**
```dart
class CertificationEmailService {
  // Enviar email para admin quando há nova solicitação
  Future<void> sendNewRequestEmailToAdmin({
    required String requestId,
    required String userName,
    required String userEmail,
    required String purchaseEmail,
    required String proofFileUrl,
  });
  
  // Enviar notificação de aprovação para usuário
  Future<void> sendApprovalEmailToUser({
    required String userEmail,
    required String userName,
  });
  
  // Enviar notificação de rejeição para usuário
  Future<void> sendRejectionEmailToUser({
    required String userEmail,
    required String userName,
    String? reason,
  });
}
```

**Implementação:** Usar Firebase Functions ou serviço de email (SendGrid/Mailgun)

### 6. Painel Admin (`SpiritualCertificationAdminView`)

**Localização:** `lib/views/admin/spiritual_certification_admin_view.dart`

**Responsabilidades:**
- Listar todas as solicitações pendentes
- Exibir detalhes de cada solicitação
- Permitir visualização do comprovante
- Botões para aprovar/rejeitar
- Filtros por status

**UI Components:**
- `CertificationRequestCardComponent` - Card de cada solicitação
- `CertificationProofViewerComponent` - Visualizador de PDF/imagem
- `CertificationActionButtonsComponent` - Botões de ação

### 7. Modelo de Dados (`CertificationRequestModel`)

**Localização:** `lib/models/certification_request_model.dart`

```dart
class CertificationRequestModel {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String purchaseEmail;
  final String proofFileUrl;
  final String proofFileName;
  final CertificationStatus status;
  final DateTime requestedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;
  
  // Métodos de conversão
  factory CertificationRequestModel.fromFirestore(DocumentSnapshot doc);
  Map<String, dynamic> toFirestore();
}

enum CertificationStatus {
  pending,
  approved,
  rejected,
}
```

### 8. Repository (`SpiritualCertificationRepository`)

**Localização:** `lib/repositories/spiritual_certification_repository.dart`

**Métodos:**
```dart
class SpiritualCertificationRepository {
  // Criar solicitação
  Future<String> createRequest(CertificationRequestModel request);
  
  // Buscar por usuário
  Future<List<CertificationRequestModel>> getByUserId(String userId);
  
  // Buscar pendentes
  Stream<List<CertificationRequestModel>> getPendingRequests();
  
  // Atualizar status
  Future<void> updateStatus(String requestId, CertificationStatus status);
  
  // Atualizar campo isSpiritualCertified do usuário
  Future<void> updateUserCertificationStatus(String userId, bool certified);
}
```

## Data Models

### CertificationRequestModel

```dart
class CertificationRequestModel {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String purchaseEmail;
  final String proofFileUrl;
  final String proofFileName;
  final CertificationStatus status;
  final DateTime requestedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;
}
```

## Error Handling

### Erros de Upload

- **Arquivo muito grande:** "O arquivo deve ter no máximo 5MB"
- **Tipo inválido:** "Apenas PDF, JPG, JPEG ou PNG são permitidos"
- **Falha no upload:** "Erro ao enviar arquivo. Tente novamente"

### Erros de Solicitação

- **Campos vazios:** "Preencha todos os campos obrigatórios"
- **Email inválido:** "Digite um email válido"
- **Falha ao salvar:** "Erro ao enviar solicitação. Tente novamente"

### Erros Admin

- **Falha ao aprovar:** "Erro ao aprovar certificação"
- **Falha ao rejeitar:** "Erro ao rejeitar certificação"

## Testing Strategy

### Unit Tests

- `CertificationFileUploadService`: Validação de arquivos
- `SpiritualCertificationService`: Lógica de negócio
- `CertificationRequestModel`: Conversões Firestore

### Integration Tests

- Fluxo completo: Solicitação → Aprovação → Selo no perfil
- Upload de arquivo → Storage → URL no Firestore
- Email enviado quando solicitação é criada

### Widget Tests

- `FileUploadComponent`: Seleção e preview de arquivo
- `CertificationRequestFormComponent`: Validação de formulário
- `CertificationRequestCardComponent`: Exibição de dados

## Security Considerations

### Firebase Storage Rules

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /certifications/{userId}/{fileName} {
      // Apenas o próprio usuário pode fazer upload
      allow write: if request.auth != null && request.auth.uid == userId;
      // Admin e o próprio usuário podem ler
      allow read: if request.auth != null && 
                     (request.auth.uid == userId || 
                      request.auth.token.admin == true);
    }
  }
}
```

### Firestore Rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /spiritual_certifications/{requestId} {
      // Usuário pode criar sua própria solicitação
      allow create: if request.auth != null && 
                       request.resource.data.userId == request.auth.uid;
      
      // Usuário pode ler suas próprias solicitações
      allow read: if request.auth != null && 
                     (resource.data.userId == request.auth.uid ||
                      request.auth.token.admin == true);
      
      // Apenas admin pode atualizar
      allow update: if request.auth != null && 
                       request.auth.token.admin == true;
    }
  }
}
```

## Performance Considerations

- **Paginação:** Listar solicitações com limite de 20 por página
- **Cache:** Cachear solicitações do usuário por 5 minutos
- **Lazy Loading:** Carregar imagem de preview apenas quando visível
- **Compression:** Comprimir imagens antes do upload (opcional)

## UI/UX Design

### Cores

- **Fundo:** Gradiente âmbar/dourado (#FFA726 → #FFB74D)
- **Texto:** Branco para contraste
- **Botões:** Verde para aprovar (#4CAF50), Vermelho para rejeitar (#F44336)
- **Status:** Amarelo para pending, Verde para approved, Vermelho para rejected

### Ícones

- **Certificação:** 🏆 ou ícone de medalha
- **Upload:** 📎 ou ícone de clipe
- **Aprovado:** ✅
- **Rejeitado:** ❌
- **Pendente:** ⏱️

### Mensagens

- **Sucesso:** "Solicitação enviada com sucesso! Você receberá resposta em até 3 dias úteis."
- **Aprovação:** "Parabéns! Sua certificação espiritual foi aprovada ✅"
- **Rejeição:** "Sua solicitação precisa de revisão. Entre em contato conosco."
